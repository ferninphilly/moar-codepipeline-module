FROM alpine/terragrunt as build

ARG ACCESS_KEY_ID
ARG SECRET_ACCESS_KEY
ARG REGION
ARG ACCOUNT_ID
ARG GIT_TOKEN

RUN apk --no-cache update upgrade
RUN apk add --no-cache --update nodejs npm yarn bash curl git wget aws-cli jq
RUN yarn global add typescript

RUN git config --global url."https://ferninphilly:${GIT_TOKEN}@github.com/".insteadOf "https://github.com/"
WORKDIR /usr/src/moar-meta-infrastructure

ENV AWS_ACCESS_KEY_ID=$ACCESS_KEY_ID
ENV AWS_SECRET_ACCESS_KEY=$SECRET_ACCESS_KEY
ENV AWS_REGION=$REGION
ENV AWS_ACCOUNT_ID=$ACCOUNT_ID

ENV TERRAGRUNT_DISABLE_PROFILE=true

# now build the testing image - we have to work non-Alpine for Playwright to work
FROM mcr.microsoft.com/playwright:v1.24.0-jammy as test

# ------- COPIED (and tweaked) FROM ABOVE - to adapt to ubuntu, and coping with Docker's lack of "include" --------------
ARG ACCESS_KEY_ID
ARG SECRET_ACCESS_KEY
ARG REGION
ARG ACCOUNT_ID
ARG GIT_TOKEN

RUN apt -y update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends bash curl git wget awscli jq
RUN npm install --global yarn typescript

RUN git config --global url."https://oauth2:$GIT_TOKEN@github.com".insteadOf https://github.com

WORKDIR /usr/src/moar-meta-infrastructure

ENV AWS_ACCESS_KEY_ID=$ACCESS_KEY_ID
ENV AWS_SECRET_ACCESS_KEY=$SECRET_ACCESS_KEY
ENV AWS_REGION=$REGION
ENV AWS_ACCOUNT_ID=$ACCOUNT_ID

ENV TERRAGRUNT_DISABLE_PROFILE=true

# ------- END OF COPY --------------

RUN apt-get -y install ffmpeg

# clean out cache
RUN apt-get clean
RUN npm cache clean --force