#!/bin/bash

# Load variables from the .env file
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
else
  echo "Error: .env file not found!"
  exit 1
fi

# Check if the private token is set
if [ -z "$PRIVATE_TOKEN" ]; then
  echo "Error: PRIVATE_TOKEN is not set in the .env file"
  exit 1
fi

# Check if the GitLab URL is set
if [ -z "$GITLAB_URL" ]; then
  echo "Error: GITLAB_URL is not set in the .env file"
  exit 1
fi

# Remove trailing slash from GITLAB_URL if present
GITLAB_URL=${GITLAB_URL%/}

# File containing the list of branches
BRANCHES_FILE="branches.txt"

# Check if the branches file exists
if [ ! -f "$BRANCHES_FILE" ]; then
  echo "Error: File $BRANCHES_FILE not found!"
  exit 1
fi

# Function for URL encoding using jq
url_encode() {
    echo -n "$1" | jq -sRr @uri
}

# Loop through each line of the file
while IFS= read -r line; do
  # Read and clean the line (remove carriage returns)
  line=$(echo "$line" | tr -d '\r')

  # Extract the project URL and destination branch name
  PROJECT_URL=$(echo "$line" | awk -F'/tree/' '{print $1}')
  DEST_BRANCH=$(echo "$line" | awk -F'/tree/' '{print $2}' | xargs)

  # Remove protocol from URLs
  GITLAB_URL_NO_PROTO=${GITLAB_URL#*://}
  PROJECT_URL_NO_PROTO=${PROJECT_URL#*://}

  # Remove carriage returns and trim
  GITLAB_URL_NO_PROTO=$(echo "$GITLAB_URL_NO_PROTO" | tr -d '\r' | xargs)
  PROJECT_URL_NO_PROTO=$(echo "$PROJECT_URL_NO_PROTO" | tr -d '\r' | xargs)

  # Remove the base URL to get the project path
  PROJECT_PATH=${PROJECT_URL_NO_PROTO#"$GITLAB_URL_NO_PROTO/"}

  # Debugging statements
  #echo "Line: '$line'"
  #echo "PROJECT_URL: '$PROJECT_URL'"
  #echo "DEST_BRANCH: '$DEST_BRANCH'"
  #echo "PROJECT_URL_NO_PROTO: '$PROJECT_URL_NO_PROTO'"
  #echo "GITLAB_URL_NO_PROTO: '$GITLAB_URL_NO_PROTO'"
  #echo "PROJECT_PATH: '$PROJECT_PATH'"

  # URL encode the project path
  PROJECT_PATH_ENCODED=$(url_encode "$PROJECT_PATH")

  # Debugging: Output the encoded project path
  #echo "PROJECT_PATH_ENCODED: '$PROJECT_PATH_ENCODED'"

  # Endpoint to get the project ID
  PROJECT_API_URL="$GITLAB_URL/api/v4/projects/$PROJECT_PATH_ENCODED"

  # Debugging: Output the project API URL
  #echo "Fetching project ID from API URL: $PROJECT_API_URL"

  # Make the API call and capture the response
  PROJECT_API_RESPONSE=$(curl --silent --header "PRIVATE-TOKEN: $PRIVATE_TOKEN" "$PROJECT_API_URL")

  # Debugging: Output the API response
  #echo "API Response: $PROJECT_API_RESPONSE"

  # Extract the project ID
  PROJECT_ID=$(echo "$PROJECT_API_RESPONSE" | jq '.id')

  if [ "$PROJECT_ID" = "null" ] || [ -z "$PROJECT_ID" ]; then
    echo "Error: Failed to get project ID for $PROJECT_URL"
    continue
  fi

  echo "Project: $PROJECT_PATH (ID: $PROJECT_ID)"
  echo "Creating branch '$DEST_BRANCH' from 'master'..."

  # API endpoint to create the branch
  CREATE_BRANCH_API_URL="$GITLAB_URL/api/v4/projects/$PROJECT_ID/repository/branches"

  # Make the request to create the branch
  RESPONSE=$(curl --silent --write-out "HTTPSTATUS:%{http_code}" --request POST \
    --header "PRIVATE-TOKEN: $PRIVATE_TOKEN" \
    --data "branch=$DEST_BRANCH&ref=master" \
    "$CREATE_BRANCH_API_URL")

  # Extract the HTTP status code
  HTTP_STATUS=$(echo "$RESPONSE" | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')

  # Extract the response body
  BODY=$(echo "$RESPONSE" | sed -e 's/HTTPSTATUS\:.*//g')

  if [ "$HTTP_STATUS" -eq 201 ]; then
    echo "Branch '$DEST_BRANCH' successfully created in project '$PROJECT_PATH'."
  elif [ "$HTTP_STATUS" -eq 400 ] && echo "$BODY" | grep -q "Branch already exists"; then
    echo "Branch '$DEST_BRANCH' already exists in project '$PROJECT_PATH'."
  else
    echo "Error: Failed to create branch '$DEST_BRANCH' in project '$PROJECT_PATH'."
    echo "API response: $BODY"
  fi

  echo "----------------------------------------"

done < "$BRANCHES_FILE"
