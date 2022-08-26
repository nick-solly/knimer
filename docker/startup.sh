#!/usr/bin/env bash

set -e

S3_LOCATION="s3://${S3_BUCKET_NAME}/${KNIME_WORKFLOW_FILE}.zip"

aws s3 cp ${S3_LOCATION} /tmp/workflow.zip

wfvars=( $WORKFLOW_VARIABLES )
wfsecrets=( $WORKFLOW_SECRETS )

/opt/knime_4.6.0/knime -reset -nosave -consoleLog -nosplash -application org.knime.product.KNIME_BATCH_APPLICATION -workflowFile=/tmp/workflow.zip "${wfvars[@]}" "${wfsecrets[@]}"
