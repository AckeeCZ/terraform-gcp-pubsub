#!/bin/bash

export GOOGLE_PROJECT=terraform-test-hejda
export TF_VAR_project=${GOOGLE_PROJECT}

terraform init
