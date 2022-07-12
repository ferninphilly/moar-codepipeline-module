FROM alpine/terragrunt

ARG ACCESS_KEY_ID
ARG SECRET_ACCESS_KEY
ARG REGION
ARG ACCOUNT_ID

RUN apk --no-cache update upgrade
RUN apk add --no-cache --update nodejs npm yarn bash curl git wget aws-cli
RUN yarn global add typescript

WORKDIR /usr/src/moar-meta-infrastructure

RUN wget https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 && \
    mv jq-linux64 /usr/local/bin/jq && \
    chmod +x /usr/local/bin/jq 

ENV AWS_ACCESS_KEY_ID=$ACCESS_KEY_ID
ENV AWS_SECRET_ACCESS_KEY="$SECRET_ACCESS_KEY"
ENV AWS_REGION="$REGION"
ENV AWS_ACCOUNT_ID="$ACCOUNT_ID"

