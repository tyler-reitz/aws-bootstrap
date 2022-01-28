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
CFN_BUCKET="$STACK_NAME-cfn-$AWS_ACCOUNT_ID"

DOMAIN=the-good-parts.com
CERT=`aws acm list-certificates --region $REGION --profile awsbootstrap --output text \
  --query "CertificateSummaryList[?DomainName=='$DOMAIN'].CertificateArn | [0]"`

echo $DOMAIN
echo $CERT
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
  --parameter-overrides \
    CodePipelineBucket=$CODEPIPELINE_BUCKET \
    CloudFormationBucket=$CFN_BUCKET

# Package up CloudFormation templates into an S3 bucket
echo -e "\n\n=========== Packaging main.yaml ============"
mkdir -p ./cfn_output

PACKAGE_ERR="$(aws cloudformation package \
  --region $REGION \
  --profile $CLI_PROFILE \
  --template main.yml \
  --s3-bucket $CFN_BUCKET \
  --output-template-file ./cfn_output/main.yml 2>&1)"

if ! [[ $PACKAGE_ERR =~ "Successfully packaged artifacts" ]]; then
  echo "ERROR while running 'aws cloudformation package' command:"
  echo $PACKAGE_ERR
fi

# Deploy the CloudFormation template
echo -e "\n\n=========== Deploying main.yml =============="
aws cloudformation deploy \
  --region $REGION \
  --profile $CLI_PROFILE \
  --stack-name $STACK_NAME \
  --template-file ./cfn_output/main.yml \
  --no-fail-on-empty-changeset \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    EC2InstanceType=$EC2_INSTANCE_TYPE \
    GitHubOwner=$GH_OWNER \
    GitHubRepo=$GH_REPO \
    GitHubBranch=$GH_BRANCH \
    GitHubPersonalAccessToken=$GH_ACCESS_TOKEN \
    CodePipelineBucket=$CODEPIPELINE_BUCKET \
    Domain=$DOMAIN \
    Certificate=$CERT

# aws cloudformation create-stack \
#   --region $REGION \
#   --profile $CLI_PROFILE \
#   --stack-name $STACK_NAME \
#   --template-body file://$(pwd)/main.yml \
#   --disable-rollback \
#   --capabilities CAPABILITY_NAMED_IAM \
#   --parameters \
#     ParameterKey=EC2InstanceType,ParameterValue=$EC2_INSTANCE_TYPE \
#     ParameterKey=GitHubOwner,ParameterValue=$GH_OWNER \
#     ParameterKey=GitHubRepo,ParameterValue=$GH_REPO \
#     ParameterKey=GitHubBranch,ParameterValue=$GH_BRANCH \
#     ParameterKey=GitHubPersonalAccessToken,ParameterValue=$GH_ACCESS_TOKEN \
#     ParameterKey=CodePipelineBucket,ParameterValue=$CODEPIPELINE_BUCKET

# If the deploy succeeded, show the DNS name of the endpoints
if [ $? -eq 0 ]; then
  aws cloudformation list-exports \
    --profile awsbootstrap
    --query "Exports[?ends_with(Name,'LBEndpoint')].Value"
fi

