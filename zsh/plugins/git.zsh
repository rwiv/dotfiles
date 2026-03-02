# Check for develop and similarly named branches
function git_develop_branch() {
  command git rev-parse --git-dir &>/dev/null || return
  local branch
  for branch in dev devel develop development; do
    if command git show-ref -q --verify refs/heads/$branch; then
      echo $branch
      return 0
    fi
  done

  echo develop
  return 1
}

# Get the default branch name from common branch names or fallback to remote HEAD
function git_main_branch() {
  command git rev-parse --git-dir &>/dev/null || return
  
  local remote ref
  
  for ref in refs/{heads,remotes/{origin,upstream}}/{main,trunk,mainline,default,stable,master}; do
    if command git show-ref -q --verify $ref; then
      echo ${ref:t}
      return 0
    fi
  done
  
  # Fallback: try to get the default branch from remote HEAD symbolic refs
  for remote in origin upstream; do
    ref=$(command git rev-parse --abbrev-ref $remote/HEAD 2>/dev/null)
    if [[ $ref == $remote/* ]]; then
      echo ${ref#"$remote/"}; return 0
    fi
  done

  # If no main branch was found, fall back to master but return error
  echo master
  return 1
}

alias g='git'

alias ga='git add'
alias gaa='git add --all'

alias gbl='git blame -w'

alias gb='git branch'
alias gba='git branch --all'
alias gbd='git branch --delete'
alias gbD='git branch --delete --force'

function gbda() {
  git branch --no-color --merged | command grep -vE "^([+*]|\s*($(git_main_branch)|$(git_develop_branch))\s*$)" | command xargs git branch --delete 2>/dev/null
}

# Copied and modified from James Roeder (jmaroeder) under MIT License
# https://github.com/jmaroeder/plugin-git/blob/216723ef4f9e8dde399661c39c80bdf73f4076c4/functions/gbda.fish
function gbds() {
  local default_branch=$(git_main_branch)
  (( ! $? )) || default_branch=$(git_develop_branch)

  git for-each-ref refs/heads/ "--format=%(refname:short)" | \
    while read branch; do
      local merge_base=$(git merge-base $default_branch $branch)
      if [[ $(git cherry $default_branch $(git commit-tree $(git rev-parse $branch\^{tree}) -p $merge_base -m _)) = -* ]]; then
        # 로컬 브랜치 삭제
        git branch -D "$branch"
        # 원격 브랜치 삭제 (원격에 브랜치가 없을 경우의 에러 무시)
        git push origin --delete "$branch" 2>/dev/null || true
      fi
    done
}

function gbdsa() {
  local default_branch=$(git_main_branch)
  (( ! $? )) || default_branch=$(git_develop_branch)

  local branches_to_delete=()

  # 1. 삭제할 브랜치 목록 수집
  while read branch; do
    local merge_base=$(git merge-base $default_branch $branch)
    if [[ $(git cherry $default_branch $(git commit-tree $(git rev-parse $branch\^{tree}) -p $merge_base -m _)) = -* ]]; then
      branches_to_delete+=("$branch")
    fi
  done < <(git for-each-ref refs/heads/ "--format=%(refname:short)")

  # 2. 삭제할 브랜치가 없는 경우 스크립트 종료
  if [[ ${#branches_to_delete[@]} -eq 0 ]]; then
    echo "삭제할 병합된 브랜치가 없습니다."
    return 0
  fi

  # 3. 삭제 대상 브랜치 목록 출력
  echo "🔥 다음 브랜치들이 로컬 및 원격(origin)에서 삭제됩니다:"
  for branch in "${branches_to_delete[@]}"; do
    echo "  - $branch"
  done
  echo ""

  # 4. 사용자 확인 (Zsh 및 Bash 호환을 위해 echo -n 사용)
  echo -n "정말 삭제하시겠습니까? (y/n): "
  read confirm

  # 5. y 또는 Y 입력 시 삭제 진행
  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    for branch in "${branches_to_delete[@]}"; do
      echo "🗑️ 삭제 중: $branch"
      git branch -D "$branch"
      git push origin --delete "$branch" 2>/dev/null || true
    done
    echo "✅ 삭제 완료!"
  else
    echo "🚫 취소되었습니다. 브랜치를 삭제하지 않습니다."
  fi
}

alias gf='git fetch'
alias gfo='git fetch origin'

alias glgg='git log --graph'
alias glgga='git log --graph --decorate --all'
alias glgm='git log --graph --max-count=10'
alias glods='git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ad) %C(bold blue)<%an>%Creset" --date=short'
alias glod='git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ad) %C(bold blue)<%an>%Creset"'
alias glola='git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset" --all'
alias glols='git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset" --stat'
alias glol='git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset"'
alias glo='git log --oneline --decorate'
alias glog='git log --oneline --decorate --graph'
alias gloga='git log --oneline --decorate --graph --all'

# Pretty log messages
function _git_log_prettily(){
  if ! [ -z $1 ]; then
    git log --pretty=$1
  fi
}
compdef _git _git_log_prettily=git-log

alias glp='_git_log_prettily'
alias glg='git log --stat'
alias glgp='git log --stat --patch'

alias gm='git merge'
alias gma='git merge --abort'
alias gmc='git merge --continue'
alias gms="git merge --squash"
alias gmff="git merge --ff-only"
alias gmom='git merge origin/$(git_main_branch)'
alias gmum='git merge upstream/$(git_main_branch)'

alias gl='git pull'
# alias ggpull='git pull origin "$(git_current_branch)"'
#
# function ggl() {
#   if [[ $# != 0 ]] && [[ $# != 1 ]]; then
#     git pull origin "${*}"
#   else
#     local b
#     [[ $# == 0 ]] && b="$(git_current_branch)"
#     git pull origin "${b:-$1}"
#   fi
# }
# compdef _git ggl=git-pull
#
# alias gluc='git pull upstream $(git_current_branch)'
# alias glum='git pull upstream $(git_main_branch)'
# alias gp='git push'
# alias gpd='git push --dry-run'
#
# function ggf() {
#   local b
#   [[ $# != 1 ]] && b="$(git_current_branch)"
#   git push --force origin "${b:-$1}"
# }
# compdef _git ggf=git-push
#
# alias gpf!='git push --force'
# is-at-least 2.30 "$git_version" \
#   && alias gpf='git push --force-with-lease --force-if-includes' \
#   || alias gpf='git push --force-with-lease'
#
# function ggfl() {
#   local b
#   [[ $# != 1 ]] && b="$(git_current_branch)"
#   git push --force-with-lease origin "${b:-$1}"
# }
# compdef _git ggfl=git-push
#
#
# alias gpsup='git push --set-upstream origin $(git_current_branch)'
# is-at-least 2.30 "$git_version" \
#   && alias gpsupf='git push --set-upstream origin $(git_current_branch) --force-with-lease --force-if-includes' \
#   || alias gpsupf='git push --set-upstream origin $(git_current_branch) --force-with-lease'
# alias gpv='git push --verbose'
# alias gpoat='git push origin --all && git push origin --tags'
# alias gpod='git push origin --delete'
# alias ggpush='git push origin "$(git_current_branch)"'
#
# function ggp() {
#   if [[ $# != 0 ]] && [[ $# != 1 ]]; then
#     git push origin "${*}"
#   else
#     local b
#     [[ $# == 0 ]] && b="$(git_current_branch)"
#     git push origin "${b:-$1}"
#   fi
# }
# compdef _git ggp=git-push
#
# alias gpu='git push upstream'

alias grf='git reflog'

alias gr='git remote'
alias grv='git remote --verbose'
alias gra='git remote add'
alias grrm='git remote remove'
alias grmv='git remote rename'
alias grset='git remote set-url'
alias grup='git remote update'

alias grh='git reset'
alias gru='git reset --'
alias grhh='git reset --hard'
alias grhk='git reset --keep'
alias grhs='git reset --soft'

alias grs='git restore'
alias grss='git restore --source'
alias grst='git restore --staged'

alias grev='git revert'
alias greva='git revert --abort'
alias grevc='git revert --continue'

alias gsh='git show'
alias gsps='git show --pretty=short --show-signature'

alias gstall='git stash --all'
alias gstaa='git stash apply'
alias gstc='git stash clear'
alias gstd='git stash drop'
alias gstl='git stash list'
alias gstp='git stash pop'
# use the default stash push on git 2.13 and newer
is-at-least 2.13 "$git_version" \
  && alias gsta='git stash push' \
  || alias gsta='git stash save'
alias gsts='git stash show --patch'

alias gst='git status'
alias gss='git status --short'
alias gsb='git status --short --branch'

alias gsw='git switch'
alias gswc='git switch --create'
alias gswd='git switch $(git_develop_branch)'
alias gswm='git switch $(git_main_branch)'

alias gta='git tag --annotate'
alias gts='git tag --sign'
alias gtv='git tag | sort -V'

alias gw='git worktree'
alias gwa='git worktree add'
alias gwl='git worktree list'
alias gwd='git worktree remove'
alias gwmv='git worktree move'

