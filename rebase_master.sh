#!/bin/zsh
#alias sgrb="/Users/adi/tools/sh/rebaseMaster.sh" 已經修正成rebmaster.sh
# 自動reset --soft 到master後一條commit
# Compare with master, and commit to --squash to 1 commit..

source /Users/adi/tools/sh/lib/color.zsh

for file in /Users/adi/tools/sh/lib/*.zsh; do source $file; done

# 自定義fzf
customfzf() {
    local prompt=$1
    fzf --prompt="$prompt " --height=20 --reverse --border --ansi --no-mouse --inline-info --cycle
}

##########################

echo "Checking differences with master branch..."

echo "請先選擇要rebase -i 目標branch, 例如main or master"

masterOptions=("master" "main" "dev" "pre" "develop" "release")

master=$(
    printf "%s\n" "${masterOptions[@]}" |
        customfzf "請選擇要git rebase -i的目標branch(master): "
)

if [ -z "$master" ]; then
  red "沒有選擇目標branch(master)!"
  exit 1
fi

revert=$(git cherry -v origin/$master)
commits=$(echo "$revert" | grep ^+ | wc -l)

if [ $commits -lt 2 ]; then
  red "Warning: There are commits not merged with master branch."
  red "This branch cherry -v origin $master, commits = $commits."
  red "Please Check again."
  exit 1
else
  green "Checking Done."
  green "Cherry -v commit number: $commits."
fi
echo

red "WARNING: This script will squash all commits after $master branch./此腳本會rebase -i $master（合併coomit）請確認是否要執行,  "
read -q "continue? $(red 'Are you sure? (y/n)')"
echo
if [[ $continue == "y" || $continue == "Y" ]]; then

else
  exit 1 
fi


green " ---- Start rebase master... -----"
echo

current_branch=$(git rev-parse --abbrev-ref HEAD)
origin_master_commit_sha1=$(git rev-parse origin/$master)
after_master_commit_sha1=$(git rev-list $origin_master_commit_sha1..HEAD | tail -n 1)
commit_msg=$(git log $after_master_commit_sha1 -1 --format=%B)

git fetch origin $master
git checkout $master
git pull origin $master
git checkout $current_branch
git reset --soft $after_master_commit_sha1

# Amend the first commit message
green "目前的Commit Msg是 $commit_msg"
echo

read -q "update_msg? $(green '需要變更嗎? (y/n)')"
echo
if [[ $update_msg == "n" || $update_msg == "N" ]]; then
  commit_msg=$commit_msg
  red "決定使用的Commit Msg $commit_msg"
  echo
else
  read "commit_msg? $(yellow '輸入新的Commit Msg:')"
fi

git commit --amend -m "$commit_msg"
echo

green ' ---- Success! ---- '

purple "合併後的commit Msg: $(git log --name-status --pretty=format:'%h %s' -n 1 )"
echo
