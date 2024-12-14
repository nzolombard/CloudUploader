# CloudUploader

`CloudUploader.sh` is a Bash-based command-line tool for uploading files to Azure Blob Storage. It simplifies the process of uploading files, handling authentication, and generating shareable links using SAS tokens.

## Features

- **Upload files to Azure Blob Storage**
- **Generate a shareable link with a SAS token**
- **Handle existing blobs with options to overwrite, skip, or rename**
- **Prompt for missing Azure environment variables**

## Prerequisites

Before using this tool, ensure the following are installed and configured:

- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) (logged in or ready to log in via service principal)
- Bash shell

You must also have the following environment variables set, or the script will prompt you to input them:

- `AZURE_CLIENT_ID`: Azure Service Principal Client ID
- `AZURE_CLIENT_SECRET`: Azure Service Principal Client Secret
- `AZURE_TENANT_ID`: Azure Tenant ID
- `AZURE_STORAGE_ACCOUNT`: Azure Storage Account Name
- `AZURE_CONTAINER_NAME`: Azure Blob Storage Container Name

## Usage

Run the script with the following syntax:

```bash
./clouduploader.sh [--link] /path/to/file.txt
```

### Arguments

- `--link`: (Optional) Generate and display a shareable link with a SAS token after upload.
- `/path/to/file.txt`: (Required) The path to the file you want to upload.

## Example Usage

### 1. Upload a File

```bash
./clouduploader.sh /path/to/file.txt
```

### 2. Upload a File and Generate a Shareable Link

```bash
./clouduploader.sh --link /path/to/file.txt
```

### 3. Handle Existing Blob Options

If a blob with the same name already exists in the container, you will be prompted with the following options:

- `[O]verwrite`: Replace the existing file in Azure Blob Storage.
- `[S]kip`: Skip uploading the file.
- `[R]ename`: Specify a new name for the file and upload.

## Script Behavior

1. **Environment Variable Check**: If any required environment variable is missing, the script will prompt you to enter it.
2. **File Existence Check**: Ensures the specified file exists locally before proceeding.
3. **Authentication**: Logs into Azure using the service principal credentials provided.
4. **Blob Upload**: Uploads the file to the specified Azure Blob Storage container.
5. **SAS Token Generation** (if `--link` is used): Creates a shareable link with read permissions valid for 1 hour.

## Error Handling

- If the specified file does not exist, the script exits with an error message.
- If Azure authentication fails, the script exits with an error message.
- If the upload fails, the error details are displayed, and the script exits.

## Clean-Up

If a file is renamed for upload, the temporary file created in `/tmp/` will be deleted automatically after the upload completes.

## Notes

- Ensure your Azure account has sufficient permissions for the specified storage account and container.
- The SAS token generated is valid for 1 hour. Adjust the script as needed to modify this duration.

## License

This project is licensed under the MIT License. Feel free to use and modify the script as needed.

---

### Author

This tool was created as a showcase project to demonstrate skills in scripting, cloud integration, and automation. For feedback or suggestions, feel free to reach out!
