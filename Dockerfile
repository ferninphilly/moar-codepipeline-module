FROM node:18.4-alpine3.15

RUN apk update upgrade

RUN apk add bash curl git wget


RUN wget https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 && \
    mv jq-linux64 /usr/local/bin/jq && \
    chmod +x /usr/local/bin/jq 