require("json-circular-stringify");
const { CodePipelineClient, PutJobSuccessResultCommand  } = require("@aws-sdk/client-codepipeline");

exports.handler = async function (event, context) {
    const client = new CodePipelineClient({});
    var jobId = event["CodePipeline.job"].id;
    await client.send(new PutJobSuccessResultCommand ({ jobId: jobId }));
    context.succeed("done");
}