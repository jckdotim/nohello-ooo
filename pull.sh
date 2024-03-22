#!/bin/bash

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "jq could not be found. Please install jq to continue."
    exit 1
fi

# Extract the pull request URL from the argument
PR_URL="$1"

# Basic validation of the input URL
if [[ ! "$PR_URL" =~ ^https://github.com/.+/pull/[0-9]+$ ]]; then
    echo "Invalid pull request URL: $PR_URL"
    echo "URL should be in the format: https://github.com/owner/repo/pull/number"
    exit 1
fi

# Extract the pull request number
PR_NUMBER=$(echo "$PR_URL" | grep -o '[0-9]\+$')

# Use GitHub API to get information about the pull request, including the source repo clone URL
API_URL=$(echo "$PR_URL" | sed -r "s|https://github.com/(.+)/pull/([0-9]+)|https://api.github.com/repos/\1/pulls/\2|")
PR_INFO=$(curl -s "$API_URL")

# Extract the source branch name, source repository clone URL, and source repo owner name
BRANCH_NAME=$(echo "$PR_INFO" | jq -r '.head.ref')
SRC_REPO_CLONE_URL=$(echo "$PR_INFO" | jq -r '.head.repo.clone_url')
SRC_REPO_OWNER=$(echo "$PR_INFO" | jq -r '.head.repo.owner.login')

# Check if the branch name and clone URL were retrieved successfully
if [[ "$BRANCH_NAME" == "null" || "$SRC_REPO_CLONE_URL" == "null" ]]; then
    echo "Failed to retrieve necessary information for the pull request."
    exit 1
fi

# Check if a remote for the source repository already exists, add if not
if ! git remote | grep -q "$SRC_REPO_OWNER"; then
    git remote add "$SRC_REPO_OWNER" "$SRC_REPO_CLONE_URL"
fi

# Fetch the branch from the source repository
git fetch "$SRC_REPO_OWNER" "$BRANCH_NAME"

# Merge the fetched branch into the current branch
# Note: This assumes you are already on the branch you want to merge into
git pull "$SRC_REPO_OWNER" "$BRANCH_NAME"

echo "Successfully pulled changes from $BRANCH_NAME into the current branch."
