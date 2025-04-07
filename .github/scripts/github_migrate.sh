#!/bin/bash

# Configuration
SOURCE_GITHUB="https://$GITHUB_SOURCE_TOKEN@github.com/$SOURCE_ORG"
DEST_GITHUB="https://$GITHUB_DEST_TOKEN@github.com/$TARGET_ORG"
DEST_REPO_NAME="test-3"
MIRROR_DIR="/tmp/$REPO_NAME"

# Logging
echo "🔄 Starting sync for $REPO_NAME at $(date)"

# Clone or update the mirror repository
if [ -d "$MIRROR_DIR" ]; then
    echo "📁 Repository mirror exists. Fetching latest updates..."
    cd "$MIRROR_DIR" || exit
    git fetch --all
else
    echo "🆕 Cloning repository from $SOURCE_GITHUB..."
    git clone --mirror "$SOURCE_GITHUB/$REPO_NAME.git" "$MIRROR_DIR"
    cd "$MIRROR_DIR" || exit
fi

# Fetch latest changes from destination repo
echo "🔍 Fetching latest changes from destination..."
git remote add dest "$DEST_GITHUB/$DEST_REPO_NAME.git" 2>/dev/null || true
git fetch dest --prune

CHANGED_FILES=$(git diff --name-only HEAD..dest/main)

if [ -z "$CHANGED_FILES" ]; then
    echo "✅ No changes detected."
    echo "✅ No changes detected." >> "$GITHUB_STEP_SUMMARY"
else
    FILE_COUNT=$(echo "$CHANGED_FILES" | wc -l)
    SUMMARY="🔄 **$FILE_COUNT files changed:**\n\n$(echo "$CHANGED_FILES" | head -10 | sed 's/^/- /')"
    
    if [ "$FILE_COUNT" -gt 10 ]; then
        SUMMARY+="\n\n... and $((FILE_COUNT - 10)) more files."
    fi

    echo -e "$SUMMARY" >> "$GITHUB_STEP_SUMMARY"
fi

# Push changes to the new GitHub instance
echo "🚀 Pushing updates to $DEST_GITHUB..."
git push --mirror "$DEST_GITHUB/$DEST_REPO_NAME.git"

echo "✅ Sync completed at $(date)"
