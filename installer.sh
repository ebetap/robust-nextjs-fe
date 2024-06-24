#!/bin/bash

# Installer script for Next.js frontend project

# Function to display messages in yellow color
print_message() {
  echo -e "\033[1;33m$1\033[0m"
}

# Function to display error messages in red color
print_error() {
  echo -e "\033[0;31mError: $1\033[0m"
}

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
  print_error "Node.js is not installed. Please install Node.js (https://nodejs.org/) and try again."
  exit 1
fi

# Check if npm is installed
if ! command -v npm &> /dev/null; then
  print_error "npm is not installed. Please install npm (https://www.npmjs.com/get-npm) and try again."
  exit 1
fi

# Function to install dependencies using npm
install_dependencies() {
  print_message "Installing dependencies..."
  npm install
}

# Function to build the Next.js project
build_project() {
  print_message "Building the Next.js project..."
  npm run build
}

# Function to start the Next.js development server
start_server() {
  print_message "Starting the development server..."
  npm run dev
}

# Main function to execute installation steps
main() {
  install_dependencies
  build_project
  start_server
}

# Run the main function
main
