# GitLab Branch Management Script

This repository provides a script to **create** and **delete** branches in multiple GitLab projects using the GitLab API.

## Prerequisites

This script requires the following tools to be installed on your system:

- **Bash shell**
- **`curl`** command-line tool
- **`jq`** command-line JSON processor
- **`python3`** for URL encoding

You can install all the required dependencies using `apt-get`:

```sh
sudo apt-get update
sudo apt-get install -y bash curl jq python3
```

## Setup

1. **Clone the repository:**

   ```sh
   git clone https://github.com/luvittor/gitlab-api.git
   ```

2. **Navigate to the project directory:**

   ```sh
   cd gitlab-api
   ```

3. **Install dependencies (if not already installed):**

   Refer to the [Prerequisites](#prerequisites) section above.

4. **Create a `.env` file with your GitLab URL and Private Token:**

   Copy the example file:

   ```sh
   cp .env.example .env
   ```

   Edit the `.env` file and update the values:

   ```env
   # .env

   GITLAB_URL="https://gitlab.example.com"
   PRIVATE_TOKEN="YOUR_PRIVATE_TOKEN"
   ```

   - Replace `YOUR_PRIVATE_TOKEN` with your actual GitLab personal access token.
   - **Do not share this token or commit the `.env` file to version control.**

## Usage

### `batch_branches.sh`

`batch_branches.sh` is designed for **creating and deleting branches** based on a task file. Each line in this task file should specify either `NEW` or `DEL`, along with the required URLs.

1. **Make the script executable:**

   ```sh
   chmod +x batch_branches.sh
   ```

2. **Prepare a Tasks File** (e.g., `backup_master.txt.example` or `recreate_develop.txt.example`):  
   - **Format for creating a new branch**:
     ```
     NEW <SRC_URL> <DEST_URL>
     ```
     Where `<SRC_URL>` is the branch you want to copy from, and `<DEST_URL>` is the new branch you want to create.

   - **Format for deleting a branch**:
     ```
     DEL <URL>
     ```
     Where `<URL>` is the branch you want to delete.

   - **Special placeholder**:  
     - You can use `{DATE}` in a URL. The script will replace `{DATE}` with the current date in `YYYYMMDD` format.

   - **Example**:  
     ```txt
     NEW https://gitlab.example.com/group/project1/tree/master https://gitlab.example.com/group/project1/tree/master_bkp_{DATE}
     DEL https://gitlab.example.com/group/project1/tree/develop
     NEW https://gitlab.example.com/group/project1/tree/master https://gitlab.example.com/group/project1/tree/develop
     ```
   - **Blank lines** are ignored, and the script also handles the case where the file does not end with a newline (ensuring the last line is processed).

3. **Run the script with your tasks file**:

   ```sh
   ./batch_branches.sh backup_master.txt
   ```

   - This will read each line of `backup_master.txt`, create or delete the branches accordingly, and replace `{DATE}` with the current date if present.

## Notes

- Ensure your personal access token has the necessary permissions to create and delete branches (`api` scope).
- The tasks file (e.g., `backup_master.txt`) should be kept secure as it contains project URLs.
- Always verify the branch names and project URLs before running the script to avoid unintended changes.
- If your branches are protected, you may need additional steps or permissions to create/delete them.

## File Descriptions

- **`batch_branches.sh`**:  
  The script that automates branch creation and deletion in multiple projects using a tasks file.

- **`.env.example`**:  
  Example environment file containing variable definitions (`GITLAB_URL` and `PRIVATE_TOKEN`).

- **`backup_master.txt.example`**:  
  Example tasks file for `batch_branches.sh` to create backup of master branches.

- **`recreate_develop.txt.example`**:  
  Example tasks file for `batch_branches.sh` to backup and recreate develop branches based on master.

- **`.gitignore`**:  
  Git configuration to ignore the `.env` and `*.txt` files (keeping sensitive info out of version control).

- **`README.md`**:  
  This document, containing setup and usage instructions for the script.

## Support

If you have any questions or need assistance, feel free to open an issue or submit a pull request.