FROM alpine/terragrunt as build

ARG ACCESS_KEY_ID
ARG SECRET_ACCESS_KEY
ARG REGION
ARG ACCOUNT_ID
ARG GIT_TOKEN

RUN apk --no-cache update upgrade
RUN apk add --no-cache --update nodejs npm yarn bash curl git wget aws-cli jq
RUN yarn global add typescript

RUN git config --global url."https://oauth2:$GIT_TOKEN@github.com".insteadOf https://github.com

WORKDIR /usr/src/moar-meta-infrastructure

RUN wget https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 && \
    mv jq-linux64 /usr/local/bin/jq && \
    chmod +x /usr/local/bin/jq 

ENV AWS_ACCESS_KEY_ID=$ACCESS_KEY_ID
ENV AWS_SECRET_ACCESS_KEY=$SECRET_ACCESS_KEY
ENV AWS_REGION=$REGION
ENV AWS_ACCOUNT_ID=$ACCOUNT_ID

ENV TERRAGRUNT_DISABLE_PROFILE=true

# now add the tools we need for testing
FROM build as test

RUN apk add --no-cache --update ffmpeg
RUN npx playwright install
