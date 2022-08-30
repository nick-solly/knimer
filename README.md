# knimer

knimer provides an automation mechanism for running [KNIME](https://www.knime.com/) 
workflows and can be used an alternative to KNIME Server.

There are two parts to this project:
1. [Docker](https://www.docker.com/) configuration (Dockerfile) to create an image which:
   - Downloads a zipped KNIME workflow from an [AWS S3 Bucket](https://aws.amazon.com/s3/)
   - Runs that workflow in KNIME batch execution mode
   - Handles custom workflow variables
   - Handles custom workflow credentials
2. A set of [Terraform](https://www.terraform.io/) scripts which can be used as a module to create AWS
infrastructure which:
   - Creates an [ECS](https://aws.amazon.com/ecs/) Task Definition (incl. [Cloudwatch](https://aws.amazon.com/cloudwatch/)
logging) to run the Docker image
   - Optionally can use [AWS EventBridge](https://aws.amazon.com/eventbridge/) to schedule periodic running of the Task
   - Optionally can use an [AWS Lambda](https://aws.amazon.com/lambda/) to send Slack notifications to show progress of the Task

## Why this was created?

KNIME is a powerful application for automating the manipulation of data.
When workflows need to be run regularly though it's inconvenient to require
a human to open up the KNIME Desktop application and execute them by hand.

Even using something like Windows Task Scheduler to run the workflow in
batch mode still needs the computer to be on and is limited by the compute
resources available on the machine.

KNIME Server offers scheduling but comes at a hefty price tag for both
licenses and hosting fees. This project focuses on core needs of
scheduling and notification, rather than any team collaboration features.

## Instructions for Use

### Uploading the KNIME Workflow

Firstly create a workflow as usual in KNIME.

If you need dynamic data passed into the workflow you can use Workflow 
Variables by right-clicking on the workflow in the KNIME Explorer and 
selecting `Workflow Variables`.

If you need secret data passed into the workflow you can use
KNIME Credentials by adding a `Credentials Configuration` node.

Zip up the workflow folder (the one containing the `workflow.knime` file)
and upload it to an S3 bucket.

### Setting up Slack Notifications (optional)

Follow the instructions [here](https://api.slack.com/messaging/webhooks) to get
a Webhook URL which is consumed in the below Terraform configuration.

### Running the Workflow

#### Method A (preferred): AWS ECS Fargate configured via Terraform

Add the following module into your terraform configuration and customise
the variables:

```terraform
module "knimer" {
   
   # Uses the terraform scripts directly from this repo (can also pin version with knimer.git?ref=<BLAH>)
   source              = "github.com/nick-solly/knimer.git//terraform"
   
   aws_region          = "eu-west-2"
   
   # Used for naming AWS resources
   name_prefix         = "my-workflow"
   
   cpu                 = 2048
   memory              = 16384
   
   # In the S3 bucket, the file should be named `my_workflow.zip`
   knime_workflow_file = "my_workflow"
   s3_bucket_name      = "all_the_workflows"
   
   workflow_variables  = {
    variable1 = "ThisIsAValue,String",
    variable2 = "1234,int",
   }
   
   workflow_secrets = {
    database_creds = "username;password",
   }
   
   # Contains the Slack Webhook URL (optional)
   slack_webhook_url_secret_arn = "arn:aws:secretsmanager:us-west-2:111122223333:secret:aes128-1a2b3c"
   
   # Where the ECS Task should be run
   subnet_ids                   = ["subnet-0af169a6f98a3hg34", "subnet-042b69da4001512ca"]
   
   # When you want the workflow to be run
   schedule_expressions         = ["cron(0 4 * * ? *)"] 

}
```

For advice on `cpu` and `memory` values see [here](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#ContainerDefinition-taskcpu).

For advice on Schedule Expressions see [here](https://docs.aws.amazon.com/AmazonCloudWatch/latest/events/ScheduledEvents.html).

#### Method B: Running the Container Manually

This method does not include scheduling or Slack notifications 
as they are actioned via AWS services. 

On a Docker host run:

```
docker run \
   -e S3_BUCKET_NAME=my_workflow_bucket \
   -e KNIME_WORKFLOW_FILE=workflow_file \
   -e WORKFLOW_VARIABLES="-workflow.variable=variable_a,foo,String -workflow.variable=variable_b,6,int" \
   -e WORKFLOW_SECRETS="-credential=database_creds;username;password -credential=sharepoint_creds;username;password" \
   -e AWS_ACCESS_KEY_ID=ABCDALKNCLASASASC \
   -e AWS_SECRET_ACCESS_KEY=A2309F23J02 \
   ghcr.io/nick-solly/knimer/knimer:latest
```

Note:
- `KNIME_WORKFLOW_FILE` is without the `.zip` extension
- `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` are just for accessing the 
S3 bucket where the zipped workflow file is located

## Testing

You can locally build the image using the included `Makefile`.

## TODOs

- Allow customisable KNIME extensions to be installed
- Add a diagram of the AWS infrastructure this module creates
