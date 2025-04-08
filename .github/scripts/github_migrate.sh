#!/bin/bash

# Configuration
SOURCE_GITHUB="https://$GITHUB_SOURCE_TOKEN@github.com/$SOURCE_ORG"
DEST_GITHUB="https://$GITHUB_DEST_TOKEN@github.com/$TARGET_ORG"
DEST_REPO_NAME="test-3"
MIRROR_DIR="/tmp/$REPO_NAME"
ZIP_FILE="/tmp/${REPO_NAME}_mirror.zip"
LOG_FILE="/tmp/${REPO_NAME}_sync.log"

# Logging
echo "🔄 Starting sync for $REPO_NAME at $(date)" | tee "$LOG_FILE"

# Clone or update the mirror repository
if [ -d "$MIRROR_DIR" ]; then
    cho "📁 Repository mirror exists. Fetching latest updates..." | tee -a "$LOG_FILE"
    cd "$MIRROR_DIR" || exit
    git fetch --all
else
    echo "🆕 Cloning repository from $SOURCE_GITHUB..." | tee -a "$LOG_FILE"
    git clone --mirror "$SOURCE_GITHUB/$REPO_NAME.git" "$MIRROR_DIR"
    cd "$MIRROR_DIR" || exit
fi

# Fetch latest changes from destination repo
echo "🔍 Fetching latest changes from destination..." | tee -a "$LOG_FILE"
git remote add dest "$DEST_GITHUB/$DEST_REPO_NAME.git" 2>/dev/null || true
git fetch dest --prune

# Loop over all branches and find changes
BRANCHES=$(git branch -r | grep -v '\->' | sed 's/origin\///')

SUMMARY=""
for branch in $BRANCHES; do
    echo "🔄 Checking changes for branch: $branch" | tee -a "$LOG_FILE"
    
    CHANGED_FILES=$(git diff --name-only HEAD..$branch)
    
    if [ -z "$CHANGED_FILES" ]; then
        echo "✅ No changes detected in branch $branch." | tee -a "$LOG_FILE"
    else
        FILE_COUNT=$(echo "$CHANGED_FILES" | wc -l)
        SUMMARY+="\n🔄 **$branch** - $FILE_COUNT files changed:\n\n$(echo "$CHANGED_FILES" | head -10 | sed 's/^/- /')"
        
        if [ "$FILE_COUNT" -gt 10 ]; then
            SUMMARY+="\n\n... and $((FILE_COUNT - 10)) more files."
        fi

        echo -e "$SUMMARY" | tee -a "$LOG_FILE"
    fi
done

# Create a ZIP archive of the mirrored repo
echo "📦 Creating ZIP archive of the mirrored repository..."
cd /tmp || exit
zip -r "$ZIP_FILE" "$REPO_NAME"

# Upload ZIP as GitHub artifact
echo "📤 Uploading ZIP file as an artifact..."
echo "::set-output name=zip_path::$ZIP_FILE"

# Upload LOG file as GitHub artifact
echo "📤 Uploading log file as an artifact..." | tee -a "$LOG_FILE"
echo "log_path=$LOG_FILE" >> "$GITHUB_ENV"

# Provide a download link in the GitHub summary
if [ -z "$SUMMARY" ]; then
    echo "✅ No changes detected in any branch." | tee -a "$LOG_FILE"
    echo "✅ No changes detected in any branch." >> "$GITHUB_STEP_SUMMARY"
else
    echo -e "$SUMMARY" >> "$GITHUB_STEP_SUMMARY"
fi

echo -e "\n📥 **Download Sync Log**: [Go to Actions → Run Summary → Artifacts](https://github.com/${{ github.repository }}/actions/runs/${{ github.run_id }})" >> "$GITHUB_STEP_SUMMARY"

# Push changes to the new GitHub instance
echo "🚀 Pushing updates to $DEST_GITHUB..." | tee -a "$LOG_FILE"
git push --mirror dest

echo "✅ Sync completed at $(date)" | tee -a "$LOG_FILE"
