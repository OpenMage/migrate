#!/bin/bash

if ! aws --version | grep -q "aws-cli/2";
then 
    echo "AWS CLI v2 was not found. Please install AWS CLI version 2"
    exit 1
fi

exit 0
