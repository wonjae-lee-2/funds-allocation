#!/bin/bash

# Get the task arn.
ECS_TASK=
while [ -z $ECS_TASK ]
do
    ECS_TASK=$(aws ecs list-tasks --query taskArns[*] --output text)
    sleep 5
done

# Wait until the task is running.
aws ecs wait tasks-running --tasks $ECS_TASK

# Get a shell to the container. This won't work if the Session Manager plugin is not installed.
aws ecs execute-command --task $ECS_TASK --interactive --command /bin/bash
