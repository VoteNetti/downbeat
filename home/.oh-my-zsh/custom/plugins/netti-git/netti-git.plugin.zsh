# Clean up merged and deleted remote branches
git-cleanup() {
    echo "Fetching and pruning remote branches..."
    git fetch --prune

    echo "Removing local branches merged into main..."
    git branch --merged=main | grep -v main | xargs -n 1 git branch -d

    echo "Removing branches with deleted remotes..."
    git branch -vv | grep ': gone]' | awk '{print $1}' | xargs -n 1 git branch -D

    echo "✓ Cleanup complete"
}

# Convert remote URL from HTTPS to SSH
git-bbtossh() {
    local current_url=$(git remote get-url origin)

    if [[ $current_url == git@* ]]; then
        echo "Already using SSH: $current_url"
        return 0
    fi

    local ssh_url=$(echo $current_url | sed 's|https://[^/]*bitbucket.org/|git@bitbucket.org:|')
    git remote set-url origin "$ssh_url"

    echo "✓ Changed remote URL:"
    git remote -v
}
