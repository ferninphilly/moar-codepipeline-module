ARG AWS_ACCESS_KEY_ID
ARG AWS_SECRET_ACCESS_KEY
ARG AWS_REGION
ARG AWS_ACCOUNT_ID

FROM alpine/terragrunt

RUN apk update upgrade
RUN apk add --update nodejs npm yarn bash curl git wget
RUN yarn global add typescript 

WORKDIR /usr/src/moar-meta-infrastructure

RUN wget https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 && \
    mv jq-linux64 /usr/local/bin/jq && \
    chmod +x /usr/local/bin/jq 

ENV AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
ENV AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
ENV AWS_REGION=$AWS_REGION
ENV AWS_ACCOUNT_ID=$AWS_ACCOUNT_ID
