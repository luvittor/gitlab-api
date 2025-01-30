# GitLab Branch Creation Script

This repository contains scripts to automate the creation (and optional deletion) of branches in multiple GitLab projects using the GitLab API.

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

5. **(Optional) Prepare a `branches.txt` File**  
   The `create_branches.sh` script uses a `branches.txt` file to know which branches to create.

   1. **Copy the example file:**

      ```sh
      cp branches.txt.example branches.txt
      ```

   2. **Edit the `branches.txt` file:**  
      Each line should follow this format:

      ```
      https://gitlab.example.com/group/project/tree/destination-branch
      ```

      Replace `group/project` and `destination-branch` with your actual GitLab path and branch name.

      **Example `branches.txt` content:**

      ```txt
      https://gitlab.example.com/mygroup/project1/tree/feature/new-feature
      https://gitlab.example.com/mygroup/project2/tree/release/v1.0.0
      https://gitlab.example.com/mygroup/project3/tree/bugfix/issue-123
      ```

      - In this example:
        - The script will create a branch named `feature/new-feature` in `project1`.
        - The script will create a branch named `release/v1.0.0` in `project2`.
        - The script will create a branch named `bugfix/issue-123` in `project3`.

      **Note:** Ensure that the `branches.txt` file uses Unix-style line endings (`LF`) to prevent issues when running the script.

## Usage

### `create_branches.sh`

1. **Make the script executable:**

   ```sh
   chmod +x create_branches.sh
   ```

2. **Run the script:**

   ```sh
   ./create_branches.sh
   ```

   - The script will read the `.env` and `branches.txt` files, then create the specified branches in your GitLab projects.
   - It assumes the source branch is `master`. If you need a different source branch, adjust the script accordingly.

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
- The `branches.txt` or tasks file should be kept secure, as it contains project URLs.
- Always verify the branch names and project URLs before running the scripts to avoid unintended changes.
- If your branches are protected, you may need additional steps or permissions to create/delete them.

## File Descriptions

- **`create_branches.sh`**:  
  The main script that automates **simple branch creation** based on `branches.txt.example`.

- **`batch_branches.sh`**:  
  A more advanced script that **creates and deletes** branches in multiple projects using a tasks file.  
  - Accepts instructions in the form of `NEW <SRC_URL> <DEST_URL>` and `DEL <URL>`.

- **`.env.example`**:  
  Example environment file containing variable definitions (`GITLAB_URL` and `PRIVATE_TOKEN`).

- **`branches.txt.example`**:  
  Example file for `create_branches.sh` usage, showing how to list branches to create.

- **`backup_master.txt.example`**:  
  Example tasks file for `batch_branches.sh` to create backup of master branches.

- **`recreate_develop.txt.example`**:  
  Example tasks file for `batch_branches.sh` to backup and recreate develop branches based on master.

- **`.gitignore`**:  
  Git configuration to ignore the `.env` and `*.txt` files (keeping sensitive info out of version control).

- **`README.md`**:  
  This document, containing setup and usage instructions for the scripts.

## Support

If you have any questions or need assistance, feel free to open an issue or submit a pull request.