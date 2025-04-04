#!/bin/bash

# Configuration
SOURCE_GITHUB="https://$GITHUB_SOURCE_TOKEN@github.com/$SOURCE_ORG"
DEST_GITHUB="https://$GITHUB_DEST_TOKEN@github.com/$TARGET_ORG"
# REPO_NAME="$REPO_NAME"
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

# Push changes to the new GitHub instance
echo "🚀 Pushing updates to $DEST_GITHUB..."
git push --mirror "$DEST_GITHUB/$REPO_NAME.git"

echo "✅ Sync completed at $(date)"
