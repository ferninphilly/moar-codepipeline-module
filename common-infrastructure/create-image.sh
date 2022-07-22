#!/usr/bin/bash

# Create a Docker image and push to the repo
set -e

if [ -z "$1" ] 
then
    echo Usage: $0 environment [region]
    echo e.g. $0 sandbox
    exit -1
fi

echo Getting environment

ENV=$1
export AWS_PROFILE=moar-$1
REGION=${2:-eu-west-1}
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
CREDS=$(aws secretsmanager get-secret-value --secret-id codebuild/accesskeys | jq -r .SecretString)
AWS_ACCESS_KEY_ID=$(jq -r .key_id <<< $CREDS)
AWS_SECRET_ACCESS_KEY=$(jq -r .secret_key <<< $CREDS)
GIT_TOKEN=$(jq -r .git_token <<< $CREDS)

REPO_DNS=$(aws ecr describe-repositories --repository-names "moar-codebuild-${ENV}-image" | jq -r .repositories[0].repositoryUri | sed -e "s/\\/.*//")

echo Logging into $REPO_DNS

aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $REPO_DNS

echo Building

BUILD_ARGS="--build-arg ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
  --build-arg SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY \
  --build-arg REGION=$REGION \
  --build-arg ACCOUNT_ID=$ACCOUNT_ID \
  --build-arg GIT_TOKEN=$GIT_TOKEN"

docker build --target build -t moar-codebuild-$ENV-image $BUILD_ARGS .
docker build --target test -t moar-codebuild-test-$ENV-image $BUILD_ARGS .

echo Tagging and Pushing

docker tag moar-codebuild-$ENV-image:latest $REPO_DNS/moar-codebuild-$ENV-image:latest
docker tag moar-codebuild-test-$ENV-image:latest $REPO_DNS/moar-codebuild-test-$ENV-image:latest

docker push $REPO_DNS/moar-codebuild-$ENV-image:latest
docker push $REPO_DNS/moar-codebuild-test-$ENV-image:latest
