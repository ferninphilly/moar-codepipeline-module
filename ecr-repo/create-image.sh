#!/usr/bin/bash

# Create a Docker image and push to the repo

if [ -z "$1" ] 
then
    echo Usage: $0 environment [region]
    echo e.g. $0 sandbox
    exit -1
fi

ENV=$1
export AWS_PROFILE=moar-$1
REGION=($0:-eu-west-1)


REPO_DNS=$(aws ecr describe-repositories --repository-names "moar-codebuild-${ENV}-image" | jq -r .repositories[0].repositoryUri | sed -e "s/\\/.*//")

echo Logging into $REPO_DNS
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $REPO_DNS

