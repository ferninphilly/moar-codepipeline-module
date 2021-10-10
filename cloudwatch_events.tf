resource "aws_cloudwatch_event_rule" "codepipeline-notification" {
  name = "moar-${var.client}-${var.environment}-pipeline-event-rule"
  description = "Cloudwatch event to notify us on Codepipeline state changes"
event_pattern = <<PATTERN
{
  "source": [
    "aws.codepipeline"
  ],
  "detail-type": [
    "CodePipeline Pipeline Execution State Change"
  ],
  "resources": [
    "${aws_codepipeline.static_web_pipeline.arn}"
  ],
  "detail": {
    "pipeline": [
      "${aws_codepipeline.static_web_pipeline.name}"
    ],
    "state": [
      "RESUMED",
      "FAILED",
      "CANCELED",
      "SUCCEEDED",
      "SUPERSEDED",
      "STARTED"
    ]
  }
}
PATTERN
}

//Set up target lambda
resource "aws_cloudwatch_event_target" "codepipeline-event-target" {
  rule      = aws_cloudwatch_event_rule.codepipeline-notification.name
  target_id = "SendToLambda"
  arn       = module.slack_notify.function_arn
  input_transformer {
    input_template = <<DOC
{
  "pipeline": <pipeline>,
  "state": <state>
}
  DOC
    input_paths = {
      pipeline: "$.detail.pipeline",
      state: "$.detail.state"
    }
  }
}
