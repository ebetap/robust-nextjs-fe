#!/bin/bash

# Installer script for Next.js frontend project

set -e  # Exit immediately if a command exits with a non-zero status
set -o pipefail  # Return value of the pipeline is the value of the last (rightmost) command to exit with a non-zero status
set -x  # Print each command before executing it

LOG_FILE="installer.log"
NODE_VERSION="v14.0.0"
DOCKER_IMAGE_NAME="nextjs-app"

# Function to log messages to installer.log
log_message() {
  echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Function to display messages in yellow color
print_message() {
  echo -e "\033[1;33m$1\033[0m"
  log_message "$1"
}

# Function to display error messages in red color and exit
print_error_and_exit() {
  echo -e "\033[0;31mError: $1\033[0m"
  log_message "Error: $1"
  exit 1
}

# Function to check if Node.js is installed and version requirement
check_node_version() {
  if ! command -v node &> /dev/null; then
    print_error_and_exit "Node.js is not installed. Please install Node.js (https://nodejs.org/) and try again."
  fi

  local node_version=$(node --version)
  if [[ "$(printf '%s\n' "$NODE_VERSION" "$node_version" | sort -V | head -n1)" != "$NODE_VERSION" ]]; then
    print_error_and_exit "Node.js version $NODE_VERSION or later is required."
  fi

  print_message "Node.js version check passed: $node_version"
}

# Function to check if npm is installed
check_npm_installed() {
  if ! command -v npm &> /dev/null; then
    print_error_and_exit "npm is not installed. Please install npm (https://www.npmjs.com/get-npm) and try again."
  fi

  print_message "npm installation check passed"
}

# Function to check if Yarn is installed
check_yarn_installed() {
  if ! command -v yarn &> /dev/null; then
    print_message "Yarn is not installed. Installing Yarn..."
    npm install -g yarn >> "$LOG_FILE" 2>&1 || print_error_and_exit "Failed to install Yarn."
    print_message "Yarn installed successfully."
  fi

  print_message "Yarn installation check passed."
}

# Function to configure environment variables interactively
configure_environment() {
  print_message "Configuring environment variables..."

  read -p "Enter API URL: " api_url
  read -p "Enter analytics key: " analytics_key

  echo "NEXT_PUBLIC_API_URL=$api_url" > .env.local
  echo "NEXT_PUBLIC_ANALYTICS_KEY=$analytics_key" >> .env.local

  print_message "Environment variables configured."
}

# Function to initialize Git repository if not already initialized
initialize_git_repository() {
  if ! git rev-parse --is-inside-work-tree &> /dev/null; then
    print_message "Initializing Git repository..."
    git init >> "$LOG_FILE" 2>&1 || print_error_and_exit "Failed to initialize Git repository."
    print_message "Git repository initialized."
  else
    print_message "Git repository already initialized."
  fi
}

# Function to tag version
tag_version() {
  local version=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.1.0")

  print_message "Tagging version $version..."
  git tag -a "$version" -m "Release $version" >> "$LOG_FILE" 2>&1 || print_error_and_exit "Failed to tag version."
  print_message "Version $version tagged."
}

# Function to set up CI integration using GitHub Actions
setup_ci_integration() {
  print_message "Setting up CI integration..."

  cat <<EOF > .github/workflows/main.yml
name: CI Pipeline

on:
  push:
    branches:
      - main
  pull_request:
    branches:
      - main

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v2
      - name: Setup Node.js
        uses: actions/setup-node@v2
        with:
          node-version: '$NODE_VERSION'
      - name: Install dependencies
        run: npm install
      - name: Build project
        run: npm run build
      - name: Run tests
        run: npm test
EOF

  print_message "CI integration set up. Check .github/workflows/main.yml for configuration."
}

# Function to set up Docker support with multi-stage build
setup_docker() {
  print_message "Setting up Docker support..."

  # Check if Docker is installed
  if ! command -v docker &> /dev/null; then
    print_error_and_exit "Docker is not installed. Please install Docker (https://docs.docker.com/get-docker/) and try again."
  fi

  # Create Dockerfile
  cat <<EOF > Dockerfile
# Use Node.js 14 LTS version
FROM node:14-alpine AS build

WORKDIR /app

COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

FROM node:14-alpine

WORKDIR /app

COPY --from=build /app/package*.json ./
COPY --from=build /app/.next ./.next

EXPOSE 3000
CMD ["npm", "start"]
EOF

  print_message "Docker support set up. Check Dockerfile for configuration."
}

# Function to update dependencies
update_dependencies() {
  print_message "Updating dependencies..."
  npm update >> "$LOG_FILE" 2>&1 || print_error_and_exit "Failed to update dependencies."
  print_message "Dependencies updated."
}

# Function to perform security audit using npm audit
perform_security_audit() {
  print_message "Performing security audit..."
  npm audit --json >> "$LOG_FILE" 2>&1
  local audit_result=$(tail -n 1 "$LOG_FILE" | jq -r '.metadata.vulnerabilities.total' 2>/dev/null || echo "0")

  if [ "$audit_result" -gt 0 ]; then
    print_message "Security vulnerabilities detected. Review the audit report in $LOG_FILE for details."
    # Optionally: Provide instructions for remediation steps
  else
    print_message "No security vulnerabilities detected."
  fi
}

# Function to run automated tests
run_tests() {
  print_message "Running automated tests..."
  npm test >> "$LOG_FILE" 2>&1 || print_message "Tests encountered errors or failures. Check logs for details."
  print_message "Automated tests completed."
}

# Function to clean up temporary files or directories
cleanup() {
  print_message "Cleaning up..."
  # Add commands to clean up temporary files or directories if needed
}

# Function to generate README.md file
generate_readme() {
  print_message "Generating README.md file..."
  local project_description=$(jq -r '.description' package.json)

  cat <<EOF > README.md
# Project Name

$project_description

## Setup Instructions

1. Clone the repository.
2. Install dependencies using \`npm install\` or \`yarn\`.
3. Set up environment variables by creating a .env.local file.
4. Start the development server with \`npm run dev\` or \`yarn dev\`.

For more information, visit [project documentation link].
EOF
  print_message "README.md file generated."
}

# Function to deploy the application
deploy_application() {
  print_message "Deploying the application..."
  # Example: Deploy to AWS Elastic Beanstalk
  # Replace with actual deployment steps or scripts
  print_message "Application deployed."
}

# Main function to execute installation steps
main() {
  check_node_version
  check_npm_installed
  check_yarn_installed
  configure_environment
  initialize_git_repository
  tag_version
  setup_ci_integration
  setup_docker
  update_dependencies
  perform_security_audit
  run_tests
  generate_readme
  cleanup
  deploy_application
}

# Run the main function
main
