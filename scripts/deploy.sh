#!/bin/bash

set -e  # Exit on any error
set -x  # Debug mode: prints each command before executing

# Check if a Stage is passed
if [ -z "$1" ]; then
  echo "Usage: $0 <Stage>"
  echo "Example: $0 Dev"
  exit 1
fi

STAGE=$1
CONFIG_FILE=""

# Normalize to lowercase for file naming
stage_lower=$(echo "$STAGE" | tr '[:upper:]' '[:lower:]')

# Construct config filename
CONFIG_FILE="${stage_lower}_config"

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
  echo "Error: Configuration file '$CONFIG_FILE' not found!"
  exit 1
fi

# Source the config file
source "$CONFIG_FILE"

# Example usage of config variables (assuming the config defines APP_PORT and ENV_NAME)
echo "Deploying to stage: $STAGE"
echo "App will run on port: $APP_PORT"
echo "Environment: $ENV_NAME"

# Insert your deployment logic here
# e.g. terraform apply with variables
terraform apply -auto-approve -var="env=$ENV_NAME" -var="port=$APP_PORT"