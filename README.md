# GitLab Branch Creation Script

This script automates the creation of branches in multiple GitLab projects using the GitLab API.

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

5. **Set Up the `branches.txt` File**

   The script uses a `branches.txt` file to know which projects and branches to work with.

   1. **Copy the example file:**

      ```sh
      cp branches.txt.example branches.txt
      ```

   2. **Edit the `branches.txt` file:**

      Open `branches.txt` in a text editor and update it with the actual project URLs and destination branches you wish to create.

      - Each line in the file should follow this format:

        ```
        https://gitlab.example.com/group/project/tree/destination-branch
        ```

      - Replace `https://gitlab.example.com/group/project` with the actual URL of your GitLab project.
      - Replace `destination-branch` with the name of the branch you want to create.

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

1. **Make the script executable:**

   ```sh
   chmod +x create_branches.sh
   ```

2. **Run the script:**

   ```sh
   ./create_branches.sh
   ```

   - The script will read the `.env` and `branches.txt` files and process each entry, creating the specified branches in your GitLab projects.

## Notes

- Ensure your personal access token has the necessary permissions to create branches (`api` scope).
- The script assumes that the source branch is `master`. Modify the script if you need a different source branch.
- The `branches.txt` file should be kept secure as it contains project URLs.
- Always verify the branch names and project URLs before running the script to avoid unintended changes.

## File Descriptions

- `create_branches.sh`: The main script that automates branch creation.
- `.env.example`: Example environment file containing variable definitions.
- `branches.txt.example`: Example branches file showing the required format.
- `.gitignore`: Git configuration to ignore the `.env` and `branches.txt` files.
- `README.md`: Instructions and information about the script.

## Support

If you have any questions or need assistance, feel free to open an issue or submit a pull request.