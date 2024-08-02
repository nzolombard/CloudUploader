#!/bin/bash

# clouduploader.sh
# Bash-based CLI tool to upload files to Azure Blob Storage

# Check if the required argument is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: clouduploader /path/to/file.txt"
    exit 1
fi

# Assign the file path from arguments
FILE_PATH=$1

# Check if the file exists
if [ ! -f "$FILE_PATH" ]; then
    echo "File not found: $FILE_PATH"
    exit 1
fi

# Check if required environment variables are set
if [ -z "$AZURE_STORAGE_ACCOUNT" ] || [ -z "$AZURE_STORAGE_KEY" ] || [ -z "$AZURE_CONTAINER_NAME" ]; then
    echo "Please set the AZURE_STORAGE_ACCOUNT, AZURE_STORAGE_KEY, and AZURE_CONTAINER_NAME environment variables."
    exit 1
fi

# Upload the file using Azure CLI
echo "Uploading $FILE_PATH to Azure Blob Storage..."

az storage blob upload \
    --account-name "$AZURE_STORAGE_ACCOUNT" \
    --account-key "$AZURE_STORAGE_KEY" \
    --container-name "$AZURE_CONTAINER_NAME" \
    --name "$(basename "$FILE_PATH")" \
    --file "$FILE_PATH"

if [ $? -eq 0 ]; then
    echo "File uploaded successfully!"
else
    echo "Failed to upload file."
    exit 1
fi