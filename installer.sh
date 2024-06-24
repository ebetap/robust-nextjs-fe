#!/bin/bash

# Installer script for Next.js frontend project

LOG_FILE="installer.log"

# Function to log messages to installer.log
log_message() {
  echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Function to display messages in yellow color
print_message() {
  echo -e "\033[1;33m$1\033[0m"
  log_message "$1"
}

# Function to display error messages in red color
print_error() {
  echo -e "\033[0;31mError: $1\033[0m"
  log_message "Error: $1"
}

# Check if Node.js is installed and version requirement
check_node_version() {
  local node_version=$(node --version)
  local required_version="v14.0.0"  # Example: Minimum required Node.js version
  
  if [[ "$(printf '%s\n' "$required_version" "$node_version" | sort -V | head -n1)" != "$required_version" ]]; then
    print_error "Node.js version $required_version or later is required."
    print_message "Please upgrade Node.js (https://nodejs.org/) and try again."
    exit 1
  fi
}

# Check if npm is installed
check_npm_installed() {
  if ! command -v npm &> /dev/null; then
    print_error "npm is not installed. Please install npm (https://www.npmjs.com/get-npm) and try again."
    exit 1
  fi
}

# Function to configure environment variables
configure_environment() {
  print_message "Configuring environment variables..."
  echo "NEXT_PUBLIC_API_URL=http://api.example.com" > .env.local  # Example: Configure API URL
  echo "NEXT_PUBLIC_ANALYTICS_KEY=your-analytics-key" >> .env.local
  print_message "Environment variables configured."
}

# Function to initialize Git repository
initialize_git_repository() {
  print_message "Initializing Git repository..."
  git init >> "$LOG_FILE" 2>&1
  print_message "Git repository initialized."
}

# Function to tag version
tag_version() {
  local version=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.1.0")
  print_message "Tagging version $version..."
  git tag -a "$version" -m "Release $version" >> "$LOG_FILE" 2>&1
  print_message "Version $version tagged."
}

# Function to set up CI integration
setup_ci_integration() {
  print_message "Setting up CI integration..."
  # Example: Generate GitHub Actions workflow file
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
    - uses: actions/checkout@v2
    - name: Install dependencies
      run: npm install
    - name: Build project
      run: npm run build
    - name: Run tests
      run: npm test
EOF
  print_message "CI integration set up. Check .github/workflows/main.yml for configuration."
}

# Function to set up Docker support
setup_docker() {
  print_message "Setting up Docker support..."
  # Example: Create Dockerfile
  cat <<EOF > Dockerfile
# Use Node.js 14 LTS version
FROM node:14-alpine

# Set working directory
WORKDIR /app

# Copy package.json and package-lock.json
COPY package*.json ./

# Install dependencies
RUN npm install --production

# Copy source code
COPY . .

# Expose port 3000
EXPOSE 3000

# Command to run the application
CMD ["npm", "run", "start"]
EOF

  print_message "Docker support set up. Check Dockerfile for configuration."
}

# Function to update dependencies
update_dependencies() {
  print_message "Checking for outdated dependencies..."
  npm outdated >> "$LOG_FILE" 2>&1
  print_message "Updating dependencies..."
  npm update >> "$LOG_FILE" 2>&1
  print_message "Dependencies updated."
}

# Function to perform security audit using npm audit
perform_security_audit() {
  print_message "Performing security audit..."
  npm audit --json >> "$LOG_FILE" 2>&1
  local audit_result=$(tail -n 1 "$LOG_FILE" | jq -r '.metadata.vulnerabilities.total')
  
  if [ "$audit_result" -gt 0 ]; then
    print_error "Security vulnerabilities detected. Review the audit report in $LOG_FILE for details."
    # Optionally: Provide instructions for remediation steps
  else
    print_message "No security vulnerabilities detected."
  fi
}

# Function to run automated tests
run_tests() {
  print_message "Running automated tests..."
  npm test >> "$LOG_FILE" 2>&1
  print_message "Automated tests completed."
}

# Function to clean up temporary files or directories
cleanup() {
  print_message "Cleaning up..."
  # Add commands to clean up temporary files or directories if needed
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
  configure_environment
  initialize_git_repository
  tag_version
  setup_ci_integration
  setup_docker
  update_dependencies
  perform_security_audit
  run_tests
  cleanup
  deploy_application
}

# Run the main function
main
