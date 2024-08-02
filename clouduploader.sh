#!/bin/bash

# clouduploader.sh
# Bash-based CLI tool to upload files to Azure Blob Storage

# Function to show usage instructions
usage() {
    echo "Usage: $0 [--link] /path/to/file.txt"
    echo "  --link   Generate and display a shareable link with SAS token after upload."
    exit 1
}

# Parse command-line arguments
GENERATE_LINK=false
while [[ "$1" == -* ]]; do
    case "$1" in
        --link)
            GENERATE_LINK=true
            shift
            ;;
        *)
            usage
            ;;
    esac
done

# Check if the required argument is provided
if [ "$#" -ne 1 ]; then
    usage
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

UPLOAD_RESULT=$(az storage blob upload \
    --account-name "$AZURE_STORAGE_ACCOUNT" \
    --account-key "$AZURE_STORAGE_KEY" \
    --container-name "$AZURE_CONTAINER_NAME" \
    --name "$(basename "$FILE_PATH")" \
    --file "$FILE_PATH" 2>&1)


# Check if the upload was successful
if [ $? -eq 0 ]; then
    echo "File uploaded successfully!"
    
    if [ "$GENERATE_LINK" = true ]; then
        # Generate SAS token
        EXPIRY_DATE=$(date -u -v+1H +"%Y-%m-%dT%H:%MZ")
        
        SAS_TOKEN=$(az storage blob generate-sas \
            --account-name "$AZURE_STORAGE_ACCOUNT" \
            --account-key "$AZURE_STORAGE_KEY" \
            --container-name "$AZURE_CONTAINER_NAME" \
            --name "$(basename "$FILE_PATH")" \
            --permissions r \
            --expiry "$EXPIRY_DATE" \
            --output tsv)
        
        # Generate shareable link with SAS token
        SHAREABLE_LINK="https://$AZURE_STORAGE_ACCOUNT.blob.core.windows.net/$AZURE_CONTAINER_NAME/$(basename "$FILE_PATH")?$SAS_TOKEN"
        
        echo "Shareable link: $SHAREABLE_LINK"
    fi
else
    echo "Failed to upload file."
    echo "Error details: $UPLOAD_RESULT"
    exit 1
fi