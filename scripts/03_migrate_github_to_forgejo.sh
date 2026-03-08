#!/bin/bash
# =============================================================================
#  Xinle 欣乐 — GitHub to Forgejo Migration Script
# =============================================================================
#  Version: 6.0
#
#  This script migrates all repositories from a specified GitHub user account
#  to your self-hosted Forgejo instance.
# =============================================================================

set -e

# --- Configuration ---
readonly GITHUB_REPO="XinleSA/rmm"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# --- Helper Functions ---
print_header() { echo -e "\n\e[1;35m--- $1 ---\e[0m"; }
print_info()   { echo -e "\e[1;36m  $1\e[0m"; }

# --- 1. Self-Update from GitHub ---
print_header "Checking for Script Updates from GitHub"

if [ -d "$PROJECT_ROOT/.git" ]; then
    cd "$PROJECT_ROOT"
    git pull origin main --rebase
    print_info "Update check complete."
    cd "$SCRIPT_DIR"
else
    print_info "Not a git repository. Skipping self-update."
fi

# --- 2. Gather User Input ---
print_header "Gathering Migration Details"

read -p "Enter your GitHub username: " GITHUB_USER
read -p "Enter your Forgejo instance URL (e.g., https://rmmx.xinle.biz/git): " FORGEJO_URL
read -s -p "Enter your Forgejo Access Token: " FORGEJO_TOKEN
echo

# --- 3. Run Migration ---
print_header "Starting Repository Migration"

# Fetch all repos from GitHub API
REPOS=$(curl -s "https://api.github.com/users/$GITHUB_USER/repos?per_page=100" | grep -o '"clone_url": "[^"]*' | awk -F'"' '{print $4}')

for REPO_URL in $REPOS; do
    REPO_NAME=$(basename "$REPO_URL" .git)
    print_info "Migrating $REPO_NAME..."

    # Use Forgejo's migration API
    curl -X POST "$FORGEJO_URL/api/v1/repos/migrate" \
      -H "Authorization: token $FORGEJO_TOKEN" \
      -H "Content-Type: application/json" \
      -d '{
        "clone_addr": "'$REPO_URL'",
        "repo_name": "'$REPO_NAME'",
        "mirror": false,
        "private": false
      }'
    echo ""
done

print_header "Migration Complete"
