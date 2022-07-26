# moar-codepipeline-module

This is a Terraform module for building the Moar's code pipelines. It is a generic codepipeline that
is adapted for all the different pipelines that Moar requires.

To use, take a look at vars.tf where you'll find a description of all the different options that you can
provide to configure the pipeline.

As the pipeline is parameterised, some stages will not be required for some builds. Terraform does not
yet allow the parameterisation of stages to actually remove them, so instead these stages are set to
simply invoke a null lambda function.

## To use this repo in another

To use this module to set up a pipeline for new repo:

1. In the target repo, create a "deployment" directory with a "deploy_config.yml" file in it. Set up the config as required.
1. Add the submodule "moar-deployment-env" at the path "deployment/env"
1. Destroy any existing CodePipeline infrastructure from wherever it is (this avoids later name-clashes).
1. In "deployment/env/sandbox" run terragrunt init and terragrunt apply

## ECR images for CodeBuild stages

The CodeBuild stages use a couple of custom ECR images that are built to work for all the different stages that
we require here. All stages share the same image, except the test stages that add extra tools such as Playwright
and FFMPEG. Both the images are defined in common-infrastructure/Dockerfile.

To provision the ECR repositories for the images, go to `common-infrastructure/[environment]` (for example `common-infrastructure/sandbox`),
do `terragunt init` and `terragrunt apply`.

To build and push the images, go to `common-infrastructure` and run `./create-image.sh` with the parameter being the environment you
would like to push the images for.
