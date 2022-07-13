require("json-circular-stringify");
const { CodePipelineClient, PutJobSuccessCommand } = require("@aws-sdk/client-codepipeline");

exports.handler = async function (event, context) {
    const client = new CodePipelineClient({});
    var jobId = event["CodePipeline.job"].id;
    try {
        await client.send(new PutJobSuccessCommand({ jobId: jobId }));
        context.succeed("done");
    } catch (err) {
        context.fail("failure: " + JSON.stringify(err));
    }
}