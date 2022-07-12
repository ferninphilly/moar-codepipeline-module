# moar-codepipeline-module

This is a Terraform module for building the Moar's code pipelines. It is a generic codepipeline that
is adapted for all the different pipelines that Moar requires.

To use, take a look at vars.tf where you'll find a description of all the different options that you can
provide to configure the pipeline.

As the pipeline is parameterised, some stages will not be required for some builds. Terraform does not
yet allow the parameterisation of stages to actually remove them, so instead these stages are set to
simply invoke a null lambda function.

## ECR image for CodeBuild stages

The CodeBuild stages use a custom ECR image that is built to work for all the different stages that
we require here. It is allowed to vary only per environment.

To provision the ECR repository for the image, go to `ecr-repo/[environment]` (for example `ecr-repo/sandbox`),
do `terragunt init` and `terragrunt apply`.

To build and push the image, run `ecr-repo/create-image.sh` with the parameter of the environment you
would like to push the image for.
