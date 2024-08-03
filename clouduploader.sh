#!/bin/bash

# clouduploader.sh
# Bash-based CLI tool to upload files to Azure Blob Storage

# Function to show usage instructions
usage() {
    echo "Usage: $0 [--link] /path/to/file.txt"
    echo "  --link   Generate and display a shareable link with SAS token after upload."
    exit 1
}

# Function to check if the file exists locally
check_file_exists() {
    if [ ! -f "$1" ]; then
        echo "File not found: $1"
        exit 1
    fi
}

# Function to check if required environment variables are set, if not prompt user for input
check_env_vars() {
    if [ -z "$AZURE_CLIENT_ID" ]; then
        read -r -p "Enter your Azure Client ID: " AZURE_CLIENT_ID
    fi

    if [ -z "$AZURE_CLIENT_SECRET" ]; then
        read -r -sp "Enter your Azure Client Secret: " AZURE_CLIENT_SECRET
        echo
    fi

    if [ -z "$AZURE_TENANT_ID" ]; then
        read -r -p "Enter your Azure Tenant ID: " AZURE_TENANT_ID
    fi

    if [ -z "$AZURE_STORAGE_ACCOUNT" ]; then
        read -r -p "Enter your Azure Storage Account Name: " AZURE_STORAGE_ACCOUNT
    fi

    if [ -z "$AZURE_CONTAINER_NAME" ]; then
        read -r -p "Enter your Azure Container Name: " AZURE_CONTAINER_NAME
    fi
}

# Function to authenticate using the Service Principal
azure_login() {
    az login --service-principal \
        --username "$AZURE_CLIENT_ID" \
        --password "$AZURE_CLIENT_SECRET" \
        --tenant "$AZURE_TENANT_ID" \
        --output none

    if [ $? -ne 0 ]; then
        echo "Azure login failed."
        exit 1
    fi
}

# Function to check if the blob already exists and handle user input
handle_blob_exists() {
    BLOB_EXISTS=$(az storage blob list \
        --account-name "$AZURE_STORAGE_ACCOUNT" \
        --account-key "$AZURE_STORAGE_KEY" \
        --container-name "$AZURE_CONTAINER_NAME" \
        --query "[?name=='$1']" \
        --output tsv)

    if [ -n "$BLOB_EXISTS" ]; then
        echo "The file already exists in Azure Blob Storage."
        echo "What would you like to do?"
        echo "  [O]verwrite the existing file"
        echo "  [S]kip uploading"
        echo "  [R]ename the file and upload"
        read -r -p "Enter your choice (O/S/R): " choice

        case "$choice" in
            [Oo])
                OVERWRITE_OPTION="--overwrite"
                ;;
            [Ss])
                echo "Skipping upload."
                exit 0
                ;;
            [Rr])
                read -r -p "Enter the new name for the file: " new_name
                FILE_PATH_RENAMED="/tmp/$new_name"
                cp "$FILE_PATH" "$FILE_PATH_RENAMED"
                FILE_PATH="$FILE_PATH_RENAMED"
                FILE_NAME="$new_name"
                ;;
            *)
                echo "Invalid choice. Exiting."
                exit 1
                ;;
        esac
    else
        OVERWRITE_OPTION=""
    fi
}

# Function to upload the file using Azure CLI
upload_file() {
    echo "Uploading $FILE_PATH to Azure Blob Storage..."

    UPLOAD_RESULT=$(az storage blob upload \
        --account-name "$AZURE_STORAGE_ACCOUNT" \
        --container-name "$AZURE_CONTAINER_NAME" \
        --name "$FILE_NAME" \
        --file "$FILE_PATH" \
        $OVERWRITE_OPTION 2>&1)

    if [ $? -eq 0 ]; then
        echo "File uploaded successfully!"
    else
        echo "Failed to upload file."
        echo "Error details: $UPLOAD_RESULT"
        exit 1
    fi
}


# Function to generate and display shareable link
generate_link() {
    # Generate SAS token
    EXPIRY_DATE=$(date -u -v+1H +"%Y-%m-%dT%H:%MZ")
    
    SAS_TOKEN=$(az storage blob generate-sas \
        --account-name "$AZURE_STORAGE_ACCOUNT" \
        --account-key "$AZURE_STORAGE_KEY" \
        --container-name "$AZURE_CONTAINER_NAME" \
        --name "$FILE_NAME" \
        --permissions r \
        --expiry "$EXPIRY_DATE" \
        --output tsv)
    
    # Generate shareable link with SAS token
    SHAREABLE_LINK="https://$AZURE_STORAGE_ACCOUNT.blob.core.windows.net/$AZURE_CONTAINER_NAME/$FILE_NAME?$SAS_TOKEN"
    
    echo "Shareable link: $SHAREABLE_LINK"
}

# Main Script Execution

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
FILE_NAME=$(basename "$FILE_PATH")

# Run functions
check_file_exists "$FILE_PATH"
check_env_vars
azure_login
handle_blob_exists "$FILE_NAME"
upload_file

if [ "$GENERATE_LINK" = true ]; then
    generate_link
fi

# Clean up renamed file if it was used
if [ -n "$FILE_PATH_RENAMED" ]; then
    rm "$FILE_PATH_RENAMED"
fi
