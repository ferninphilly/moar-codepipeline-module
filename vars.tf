
variable "client" {
  description="The stack that we're depoloying to"
  type=string
}

variable "account_id" {
  description="Obviously the different account ids"
  type=string
}
variable "environment" {
  description = "The environment we're deploying to. Possible values are dev, uat, prod"
  type = string
}

variable "region" {
  description = "Usually eu-west-1"
  type = string
}

variable "slack_channel" {
  type = string
}

variable "slack_gifs" {
    description = "A map of slack gifs with STARTED, SUCCEEDED, FAILED, CANCELLED as keys"
    type = map(string)
}

variable "repository_owner" {
    description = "The repo owner which is the name after github.com/<repository_owner>"
    type = string
}

variable "repository_name" {
    description = "The repository name"
    type = string
}

variable "sns_error_topic_arn" {
  description = "The error topic arn that we'll send errors to"
  type = string
}

