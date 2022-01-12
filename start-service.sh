#!/bin/bash -xe

source /home/ec2-user/.bash_profile
cd /home/ec2-user/app/release

# Qeury the EC2 metadata service for this instances's region
REGION="`wget -qO- http://instance-data/latest/meta-data/placement/region

# Query the EC2 metadata service for this instance's instance-id
export INSTANCE_ID="`wget -q -O - http://169.254.169.254/latest/meta-data/instance-id`"

# Query EC2 describeTags method and pull out the CFN logical ID for this instance
export STACK_NAME=`aws --region $REGION ec2 describe-tags \
  --filters "Name=resource-id,Values=${INSTANCE_ID}" \
            "Name=key,Values=aws:cloudformation:stack-name" \
  | jq -r ".Tags[0].Value"`

npm run start
