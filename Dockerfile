# NOTE: At the time of writing, this Dockerfile is used to generate the build
# image that projects derived from this module should use to build their
# respective client. Since other dependencies (e.g. Webpack) are installed in
# the container at build time, all we really need to prepare at this point is
# curl, which is trivially depended on to send notifications (e.g. "You want
# MOAR!! We're starting a build!") to our moar-X-build slack channels, and Git,
# which is depended on to install NPM dependencies directly from Github.
FROM node:15.10-alpine3.13

ENV ENVIRONMENT=develop

RUN apk add curl git

