#!/bin/bash

#----------------------------------------------------------------------------
# Replay commit ( cherry-pick ) from current branch to other repo branches
# with pattern name "origin/feature/*".
#----------------------------------------------------------------------------

# Commit hash informed as parameter or last commit
ORIGINAL_COMMIT=${1:-$(git log -n1 | head -n1 | cut -c8-)}

CURRENT_BRANCH=$( git branch | grep \* | cut -c2- )

# Feature branches select by some common name without "origin/"
FEATURE_BRANCHES=(
  $( git branch -r | grep "custom" | cut -d'/' -f2- )
)

# Remove current branch
unset 'FEATURE_BRANCHES[0]'

git stash;

# do cherry-pick in all branches
for BRANCH in "${FEATURE_BRANCHES[@]}";
do
  echo "Applying changes to branch $BRANCH."
  git checkout $BRANCH;
  git cherry-pick $ORIGINAL_COMMIT --strategy=recursive --strategy-option=theirs;

  if [ $? -ne 0 ]; then
    echo "[$(basename $0)] an error has occurred during 'cherry-pick'." >&2
    exit 1
  fi
done;

git checkout $CURRENT_BRANCH;
git stash pop;

git for-each-ref --sort=committerdate refs/heads/ --format="%(HEAD) %(color:yellow)%(refname:short)%(color:reset) - %(color:red)%(objectname:short)%(color:reset) - %(contents:subject) - %(authorname) (%(color:green)%(committerdate:relative)%(color:reset))"

echo "[$(basename $0)] script has been successfully executed."
exit 0