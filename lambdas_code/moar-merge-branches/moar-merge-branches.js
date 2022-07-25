const { Octokit } = require("@octokit/core");
const { SecretsManagerClient, GetSecretValueCommand } = require("@aws-sdk/client-secrets-manager");
const { CodePipelineClient, PutJobSuccessResultCommand, PutJobFailureResultCommand, FailureType  } = require("@aws-sdk/client-codepipeline");

module.exports.handler = async (event, context, callback) => {

    console.log("Event: " + JSON.stringify(event));
    const params = event["CodePipeline.job"].data.actionConfiguration.configuration.UserParameters;
    console.log("Parameters: " + JSON.stringify(params));

    const client = new CodePipelineClient({});
    var jobId = event["CodePipeline.job"].id;    
    
    try {
        const secretValueResponse = await new SecretsManagerClient({}).send(new GetSecretValueCommand({ SecretId: "deployment/config" }));
        const gitToken = JSON.parse(secretValueResponse.SecretString).git_token

        console.log("First three characters of git token: " + gitToken.substring(3));

        const octokit = new Octokit({
            auth: gitToken
        })

        result = await octokit.request('POST /repos/{owner}/{repo}/merges', {
            owner: params.repository_owner,
            repo: params.repository_name,
            base: params.target_branch,
            head: params.source_sha,
            commit_message: `Merged by CodePipeline from ${params.source_branch}`
        })

        console.log("Merge request result: " + JSON.stringify(result));

        await client.send(new PutJobSuccessResultCommand({ jobId: jobId }));
    } catch (err) {
        console.error("Failed: " + err);
        await client.send(new PutJobFailureResultCommand({ jobId: jobId, failureDetails: {message: err, type: FailureType.JobFailed} }));
    }
}