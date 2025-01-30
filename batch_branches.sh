#!/bin/bash

###############################################################################
# batch_branches.sh
#
# Usage:
#   ./batch_branches.sh tasks.txt
#
# Description:
#   Reads tasks from the specified text file (e.g., backup_master.txt or
#   recreate_develop.txt), ignoring blank lines. Each task may be:
#     - NEW <SRC_URL> <DEST_URL>  (Create a new branch)
#     - DEL <URL>                (Delete a branch)
#
#   The script replaces {DATE} with the current date in all URLs.
#
# Requirements:
#   - bash, curl, jq, python3, etc. (similar to your existing environment)
#   - A valid GitLab personal access token (PRIVATE_TOKEN) with 'api' scope
#
# Notes:
#   - Adjust the GitLab URL, token handling, and project path extraction
#     to match your environment and best practices.
#   - This script assumes your .env variables are already exported or
#     defined in the environment (e.g., GITLAB_URL, PRIVATE_TOKEN).
#   - You can expand error handling and logging as necessary.
###############################################################################

# -----------------------------------------------------------------------------
# 1. Basic checks
# -----------------------------------------------------------------------------

if [ $# -lt 1 ]; then
  echo "Usage: $0 <tasks_file>"
  exit 1
fi

TASKS_FILE="$1"

if [ ! -f "$TASKS_FILE" ]; then
  echo "Error: File '$TASKS_FILE' not found!"
  exit 1
fi

# load .env variables
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
fi

if [ -z "$GITLAB_URL" ] || [ -z "$PRIVATE_TOKEN" ]; then
  echo "Error: GITLAB_URL or PRIVATE_TOKEN is not set in the environment."
  echo "Please export them or load from a .env file."
  exit 1
fi

# Remove trailing slash from GITLAB_URL if present
GITLAB_URL=${GITLAB_URL%/}

# -----------------------------------------------------------------------------
# 2. Helper functions
# -----------------------------------------------------------------------------

# URL-encode function (using jq)
url_encode() {
  echo -n "$1" | jq -sRr @uri
}

# Extract "group/project" and "branch" from a URL
#   https://gitlab.example.com/group/project/tree/branch
# Returns:
#   PROJECT_PATH (group/project)
#   BRANCH_NAME  (branch)
extract_project_and_branch() {
  local url_no_proto="${1#*://}"        # remove http:// or https://
  local base_no_proto="${GITLAB_URL#*://}"  # remove protocol from base
  local stripped="${url_no_proto#"$base_no_proto/"}"  # remove server domain

  # Now 'stripped' should look like: group/project/tree/branch
  local project_part=$(echo "$stripped" | awk -F'/tree/' '{print $1}')
  local branch_part=$(echo "$stripped" | awk -F'/tree/' '{print $2}')

  echo "$project_part"  # PROJECT_PATH
  echo "$branch_part"   # BRANCH_NAME
}

# Create branch in GitLab
# Args:
#   1) Source URL
#   2) Destination URL
create_branch() {
  local SRC_URL="$1"
  local DEST_URL="$2"

  # Extract project/branch from SRC_URL
  local src_project src_branch
  src_project="$(extract_project_and_branch "$SRC_URL" | sed -n 1p)"
  src_branch="$(extract_project_and_branch "$SRC_URL" | sed -n 2p)"

  # Extract project/branch from DEST_URL
  local dest_project dest_branch
  dest_project="$(extract_project_and_branch "$DEST_URL" | sed -n 1p)"
  dest_branch="$(extract_project_and_branch "$DEST_URL" | sed -n 2p)"

  # URL-encode project paths
  local src_project_enc dest_project_enc
  src_project_enc="$(url_encode "$src_project")"
  dest_project_enc="$(url_encode "$dest_project")"

  # 1) Get project ID for destination project
  local PROJECT_API_URL="$GITLAB_URL/api/v4/projects/$dest_project_enc"
  local PROJECT_API_RESPONSE
  PROJECT_API_RESPONSE=$(curl --silent --header "PRIVATE-TOKEN: $PRIVATE_TOKEN" "$PROJECT_API_URL")
  local PROJECT_ID
  PROJECT_ID=$(echo "$PROJECT_API_RESPONSE" | jq '.id')

  if [ "$PROJECT_ID" = "null" ] || [ -z "$PROJECT_ID" ]; then
    echo "Error: Failed to get project ID for $DEST_URL (Project: $dest_project)"
    exit 1
    # return
  fi

  # 2) Create the branch
  local CREATE_BRANCH_API_URL="$GITLAB_URL/api/v4/projects/$PROJECT_ID/repository/branches"
  local RESPONSE
  RESPONSE=$(curl --silent --write-out "HTTPSTATUS:%{http_code}" --request POST \
    --header "PRIVATE-TOKEN: $PRIVATE_TOKEN" \
    --data "branch=$dest_branch&ref=$src_branch" \
    "$CREATE_BRANCH_API_URL")

  local HTTP_STATUS
  HTTP_STATUS=$(echo "$RESPONSE" | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
  local BODY
  BODY=$(echo "$RESPONSE" | sed -e 's/HTTPSTATUS\:.*//g')

  if [ "$HTTP_STATUS" -eq 201 ]; then
    echo "NEW: Created branch '$dest_branch' in project '$dest_project' (from '$src_branch')."
  elif [ "$HTTP_STATUS" -eq 400 ] && echo "$BODY" | grep -q "Branch already exists"; then
    echo "NEW: Branch '$dest_branch' already exists in project '$dest_project'."
  else
    echo "Error: Failed to create branch '$dest_branch' in project '$dest_project'."
    echo "API response: $BODY"
    exit 1
  fi
}

# Delete branch in GitLab
# Args:
#   1) URL to branch to delete
delete_branch() {
  local BRANCH_URL="$1"

  # Extract project/branch
  local project branch
  project="$(extract_project_and_branch "$BRANCH_URL" | sed -n 1p)"
  branch="$(extract_project_and_branch "$BRANCH_URL" | sed -n 2p)"

  # URL-encode project
  local project_enc
  project_enc="$(url_encode "$project")"

  # 1) Get project ID
  local PROJECT_API_URL="$GITLAB_URL/api/v4/projects/$project_enc"
  local PROJECT_API_RESPONSE
  PROJECT_API_RESPONSE=$(curl --silent --header "PRIVATE-TOKEN: $PRIVATE_TOKEN" "$PROJECT_API_URL")
  local PROJECT_ID
  PROJECT_ID=$(echo "$PROJECT_API_RESPONSE" | jq '.id')

  if [ "$PROJECT_ID" = "null" ] || [ -z "$PROJECT_ID" ]; then
    echo "Error: Failed to get project ID for $BRANCH_URL (Project: $project)"
    exit 1
    # return
  fi

  # 2) Delete the branch
  local BRANCH_ENC
  BRANCH_ENC="$(url_encode "$branch")"
  local DELETE_BRANCH_API_URL="$GITLAB_URL/api/v4/projects/$PROJECT_ID/repository/branches/$BRANCH_ENC"

  local RESPONSE
  RESPONSE=$(curl --silent --write-out "HTTPSTATUS:%{http_code}" --request DELETE \
    --header "PRIVATE-TOKEN: $PRIVATE_TOKEN" \
    "$DELETE_BRANCH_API_URL")

  local HTTP_STATUS
  HTTP_STATUS=$(echo "$RESPONSE" | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
  local BODY
  BODY=$(echo "$RESPONSE" | sed -e 's/HTTPSTATUS\:.*//g')

  if [ "$HTTP_STATUS" -eq 204 ]; then
    echo "DEL: Deleted branch '$branch' in project '$project'."
  elif [ "$HTTP_STATUS" -eq 404 ]; then
    echo "DEL: Branch '$branch' not found in project '$project'."
  else
    echo "Error: Failed to delete branch '$branch' in project '$project'."
    echo "API response: $BODY"
    exit 1
  fi
}

# -----------------------------------------------------------------------------
# 3. Main loop
# -----------------------------------------------------------------------------

CURRENT_DATE=$(date +'%Y%m%d')

# The '|| [ -n \"$raw_line\" ]' ensures the last line is processed even if
# there's no newline at the end of the file.
while IFS= read -r raw_line || [ -n "$raw_line" ]; do
  # 1) Trim the line
  line="$(echo "$raw_line" | sed 's/^\s*//;s/\s*$//')"

  # 2) Ignore blank lines
  [ -z "$line" ] && continue

  # 3) Replace {DATE} with current date
  line="${line//\{DATE\}/$CURRENT_DATE}"

  # 4) Parse operation
  op=$(echo "$line" | awk '{print $1}')

  case "$op" in
    NEW)
      # Format: NEW SRC_URL DEST_URL
      src_url=$(echo "$line" | awk '{print $2}')
      dest_url=$(echo "$line" | awk '{print $3}')
      create_branch "$src_url" "$dest_url"
      ;;
    DEL)
      # Format: DEL URL
      url_to_delete=$(echo "$line" | awk '{print $2}')
      delete_branch "$url_to_delete"
      ;;
    *)
      echo "Warning: Unknown operation '$op' in line: $line"
      ;;
  esac

done < "$TASKS_FILE"

echo "Done!"
