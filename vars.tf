
variable "client" {
  description = "The stack that we're depoloying to."
  type        = string
}

variable "account_id" {
  description = "Obviously the different account ids"
  type        = string
}

variable "environment" {
  description = "The environment we're deploying to. Possible values are sandbox, dev, uat, prod"
  type        = string
}

variable "gitenv" {
  description = "The Git branch that we're deploying. Typically varies per environment. Optional - defaults to environment if not supplied."
  type        = string
  default     = ""
}

variable "region" {
  description = "Usually eu-west-1"
  type        = string
}

variable "slack_gifs" {
  description = "A map of slack gifs with STARTED, SUCCEEDED, FAILED, CANCELLED as keys"
  type        = map(string)
}

variable "repository_owner" {
  description = "The repo owner which is the name after github.com/<repository_owner>"
  type        = string
}

variable "repository_name" {
  description = "The repository name"
  type        = string
}

variable "sns_error_topic_arn" {
  description = "The error topic arn that we'll send errors to. Defaults to moar-<environment>-sns-error-topic."
  type        = string
  default     = ""
}

variable "has_autogen_types" {
  description = "Autogenerated types are created from the root of this repo. If set, there must be a 'types:validate' action available in the root package. Defaults to false."
  type        = bool
  default     = false
}

variable "has_typescript" {
  description = "Typescript is contained in this repo. If set, there must be 'lint' and 'build' actions available in the root package. Defaults to false."
  type        = bool
  default     = false
}

variable "has_infrastructure" {
  description = "Terraformed infrastructure is defined in this repo. There must be an infrastructure/<environment> directory available with the terraform in it. Defaults to false."
  type        = bool
  default     = false
}

variable "has_predeploy_tests" {
  description = "Has tests to run before deployment, that can execute prior to build. If set, there must be a 'test' action available in the root package. Defaults to false."
  type        = bool
  default     = false
}

variable "should_publish" {
  description = "Should publish to NPM. Defaults to false."
  type        = bool
  default     = false
}

variable "has_postdeploy_tests" {
  description = "Has tests to run after deployment. If set, there must be a 'test:deployed' action available in the root package. Defaults to false."
  type        = bool
  default     = false
}
