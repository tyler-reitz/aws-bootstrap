#!/bin/bash

STACK_NAME=awsbootstrap
REGION=us-west-1
CLI_PROFILE=awsbootstrap
EC2_INSTANCE_TYPE=t2.micro

GH_ACCESS_TOKEN=$(cat .github/aws-bootstrap-access-token)
GH_OWNER=$(cat .github/aws-bootstrap-owner)
GH_REPO=$(cat .github/aws-bootstrap-repo)
GH_BRANCH=master

AWS_ACCOUNT_ID=`aws sts get-caller-identity --profile awsbootstrap --query "Account" --output text`
CODEPIPELINE_BUCKET="$STACK_NAME-$REGION-codepipeline-$AWS_ACCOUNT_ID"

echo $CODEPIPELINE_BUCKET

# Deploy static resources
echo -e "\n\n=========== Deploying setup.yaml ============"
aws cloudformation deploy \
  --region $REGION \
  --profile $CLI_PROFILE \
  --stack-name $STACK_NAME-setup \
  --template-file setup.yaml \
  --no-fail-on-empty-changeset \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides CodePipelineBucket=$CODEPIPELINE_BUCKET

# Deploy the CloudFormation template
echo -e "\n\n=========== Deploying main.yml =============="
aws cloudformation create-stack \
  --region $REGION \
  --profile $CLI_PROFILE \
  --stack-name $STACK_NAME \
  --template-body file://$(pwd)/main.yml \
  # --no-fail-on-empty-changeset \
  --disable-rollbak \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameters \
    ParameterKey=EC2InstanceType,ParameterValue=$EC2_INSTANCE_TYPE \
    ParameterKey=GitHubOwner,ParameterValue=$GH_OWNER \
    ParameterKey=GitHubRepo,ParameterValue=$GH_REPO \
    ParameterKey=GitHubBranch,ParameterValue=$GH_BRANCH \
    ParameterKey=GitHubPersonalAccessToken,ParameterValue=$GH_ACCESS_TOKEN \
    ParameterKey=CodePipelineBucket,ParameterValue=$CODEPIPELINE_BUCKET

if [ $? -eq 0 ]; then
  aws cloudformation list-exports \
    --profile awsbootstrap
    --query "Exports[?Name=='InstanceEndpoint'].Value"
fi
