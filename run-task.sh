#!/bin/bash

# Launch an instance based on the launch template. The template should have a tag with the key 'template' and value 'funds-allocation'.
aws ec2 run-instances --no-cli-pager --launch-template LaunchTemplateName=funds-allocation,Version=$Default

# Wait until the instance is available for ECS.
ECS_ARN=
while [ -z $ECS_ARN ]
do
    ECS_ARN=$(aws ecs list-container-instances --query containerInstanceArns[*] --output text)
    sleep 5
done

# Run the task based on the task definition. The task definitions should have a task role with the 'AmazonSSMFullAccess' policy for 'execute-command' to work.
aws ecs run-task --no-cli-pager --task-definition funds-allocation --count 1 --enable-execute-command

# Get the task arn.
ECS_TASK=
while [ -z $ECS_TASK ]
do
    ECS_TASK=$(aws ecs list-tasks --query taskArns[*] --output text)
    sleep 5
done

# Wait until the task stops.
until [ -z $ECS_TASK ]
do
    ECS_TASK=$(aws ecs list-tasks --query taskArns[*] --output text)
    sleep 60
done

# Terminate the instance.
INSTANCE_ID=$(aws ec2 describe-instances --filters Name=tag:template,Values=funds-allocation --query Reservations[*].Instances[*].[InstanceId] --output text)
aws ec2 terminate-instances --no-cli-pager --instance-ids $INSTANCE_ID
