#!/usr/bin/env bash
# shellcheck disable=SC2034
# @file tools
# @brief Tool registry for get-bashed installers.
# @description
#     Defines tool metadata, dependencies, and installation methods.

TOOL_IDS=()
declare -A TOOL_DESC
declare -A TOOL_DEPS
declare -A TOOL_PLATFORMS
declare -A TOOL_METHODS
declare -A TOOL_BREW
declare -A TOOL_APT
declare -A TOOL_DNF
declare -A TOOL_YUM
declare -A TOOL_PACMAN
declare -A TOOL_GIT_URL
declare -A TOOL_CURL_URL
declare -A TOOL_CURL_CMD
declare -A TOOL_HANDLER
declare -A TOOL_OPT_DEPS
declare -A TOOL_BIN
declare -A TOOL_TARGET_DIR

tool_register() {
  local id="$1" desc="$2" deps="$3" platforms="$4" methods="$5"
  TOOL_IDS+=("$id")
  TOOL_DESC["$id"]="$desc"
  TOOL_DEPS["$id"]="$deps"
  TOOL_PLATFORMS["$id"]="$platforms"
  TOOL_METHODS["$id"]="$methods"
}

tool_pkgs() {
  local id="$1" brew="$2" apt="$3" dnf="$4" yum="$5" pacman="$6"
  TOOL_BREW["$id"]="$brew"
  TOOL_APT["$id"]="$apt"
  TOOL_DNF["$id"]="$dnf"
  TOOL_YUM["$id"]="$yum"
  TOOL_PACMAN["$id"]="$pacman"
}

tool_git() {
  local id="$1" url="$2"
  TOOL_GIT_URL["$id"]="$url"
}

tool_curl() {
  local id="$1" url="$2" cmd="$3"
  TOOL_CURL_URL["$id"]="$url"
  TOOL_CURL_CMD["$id"]="$cmd"
}

tool_handler() {
  local id="$1" handler="$2"
  TOOL_HANDLER["$id"]="$handler"
}

tool_opt_deps() {
  local id="$1" spec="$2"
  TOOL_OPT_DEPS["$id"]="$spec"
}

tool_bin() {
  local id="$1" bin="$2"
  TOOL_BIN["$id"]="$bin"
}

tool_target_dir() {
  local id="$1" target="$2"
  TOOL_TARGET_DIR["$id"]="$target"
}

# @internal
load_installers() {
  INSTALLERS=""
  for id in "${TOOL_IDS[@]}"; do
    INSTALLERS="${INSTALLERS}${id} "
    local desc="${TOOL_DESC[$id]:-$id}"
    printf -v "INSTALL_DESC_${id}" "%s" "$desc"
  done
}
# Core tools
tool_register brew "Homebrew/Linuxbrew installer" "" "macos,linux,wsl" "curl"
tool_curl brew "${GET_BASHED_CURL_SOURCES["brew"]}" "${GET_BASHED_CURL_CMD["brew"]}"
tool_bin brew "brew"

tool_register asdf "asdf version manager" "" "macos,linux,wsl" "handler"
tool_handler asdf "install_asdf"

tool_register bash "Latest GNU Bash" "" "macos,linux,wsl" "brew,apt,dnf,yum,pacman"
tool_pkgs bash "bash" "bash" "bash" "bash" "bash"

tool_register bash_it "bash-it framework" "git" "macos,linux,wsl" "git"
tool_git bash_it "${GET_BASHED_GIT_SOURCES["bash_it"]}"
tool_target_dir bash_it "bash-it"

tool_register vimrc "amix/vimrc (awesome/basic)" "git" "macos,linux,wsl" "git"
tool_git vimrc "${GET_BASHED_GIT_SOURCES["vimrc"]}"
tool_handler vimrc "install_vimrc"

tool_register shdoc "shdoc (shell script doc generator)" "" "macos,linux,wsl" "handler"
tool_handler shdoc "install_shdoc"

tool_register uv "uv" "" "macos,linux,wsl" "brew,pip"
tool_pkgs uv "uv" "" "" "" ""
tool_bin uv "uvx"

tool_register dialog "curses dialog UI" "" "macos,linux,wsl" "brew,apt,dnf,yum"
tool_pkgs dialog "dialog" "dialog" "dialog" "dialog" ""

tool_register pipx "pipx" "" "macos,linux,wsl" "brew,apt,dnf,yum,pacman,pip"
tool_pkgs pipx "pipx" "pipx" "pipx" "pipx" "python-pipx"

tool_register pre_commit "pre-commit" "pipx" "macos,linux,wsl" "pipx"
tool_bin pre_commit "pre-commit"
tool_register bashate "bashate" "pipx" "macos,linux,wsl" "pipx"
tool_bin bashate "bashate"

tool_register shellcheck "shellcheck" "" "macos,linux,wsl" "brew,apt,dnf,yum,pacman"
tool_pkgs shellcheck "shellcheck" "shellcheck" "ShellCheck" "ShellCheck" "shellcheck"

tool_register actionlint "actionlint" "" "macos,linux,wsl" "handler"
tool_handler actionlint "install_actionlint"

tool_register bats "bats" "" "macos,linux,wsl" "brew,apt,dnf,yum,pacman"
tool_pkgs bats "bats-core" "bats" "bats" "bats" "bats"

tool_register curl "curl" "" "macos,linux,wsl" "brew,apt,dnf,yum,pacman"
tool_pkgs curl "curl" "curl" "curl" "curl" "curl"

tool_register wget "wget" "" "macos,linux,wsl" "brew,apt,dnf,yum,pacman"
tool_pkgs wget "wget" "wget" "wget" "wget" "wget"

tool_register gnupg "gnupg" "" "macos,linux,wsl" "brew,apt,dnf,yum,pacman"
tool_pkgs gnupg "gnupg" "gnupg" "gnupg2" "gnupg2" "gnupg"

tool_register gnu_tools "GNU coreutils/findutils/sed/tar" "brew" "macos" "handler"
tool_handler gnu_tools "install_gnu_tools"

tool_register git "git" "" "macos,linux,wsl" "brew,apt,dnf,yum,pacman"
tool_pkgs git "git" "git" "git" "git" "git"
tool_opt_deps git "GET_BASHED_GIT_SIGNING:gnupg"

tool_register git_lfs "git-lfs" "" "macos,linux,wsl" "brew,apt,dnf,yum"
tool_pkgs git_lfs "git-lfs" "git-lfs" "git-lfs" "git-lfs" ""
tool_bin git_lfs "git-lfs"

tool_register gh "GitHub CLI" "" "macos,linux,wsl" "brew,apt"
tool_pkgs gh "gh" "gh" "" "" ""

tool_register direnv "direnv" "" "macos,linux,wsl" "brew,apt"
tool_pkgs direnv "direnv" "direnv" "" "" ""

tool_register starship "starship" "" "macos,linux,wsl" "brew"
tool_pkgs starship "starship" "" "" "" ""
tool_bin starship "starship"

tool_register eza "eza (modern ls)" "" "macos,linux,wsl" "brew,apt,dnf,yum,pacman"
tool_pkgs eza "eza" "eza" "eza" "eza" "eza"

tool_register rg "ripgrep" "" "macos,linux,wsl" "brew,apt,dnf,yum,pacman"
tool_pkgs rg "ripgrep" "ripgrep" "ripgrep" "ripgrep" "ripgrep"

tool_register fd "fd" "" "macos,linux,wsl" "brew,apt,dnf,yum,pacman"
tool_pkgs fd "fd" "fd-find" "fd-find" "fd-find" "fd"

tool_register bat "bat" "" "macos,linux,wsl" "brew,apt,dnf,yum,pacman"
tool_pkgs bat "bat" "bat" "bat" "bat" "bat"

tool_register fzf "fzf" "" "macos,linux,wsl" "brew,apt,dnf,yum,pacman"
tool_pkgs fzf "fzf" "fzf" "fzf" "fzf" "fzf"

tool_register jq "jq" "" "macos,linux,wsl" "brew,apt,dnf,yum,pacman"
tool_pkgs jq "jq" "jq" "jq" "jq" "jq"

tool_register yq "yq" "" "macos,linux,wsl" "brew,apt,dnf,yum,pacman"
tool_pkgs yq "yq" "yq" "yq" "yq" "yq"

tool_register tree "tree" "" "macos,linux,wsl" "brew,apt,dnf,yum,pacman"
tool_pkgs tree "tree" "tree" "tree" "tree" "tree"

tool_register nodejs "Node.js (asdf preferred)" "asdf" "macos,linux,wsl" "handler"
tool_handler nodejs "install_nodejs"

tool_register python "Python (asdf preferred)" "asdf" "macos,linux,wsl" "handler"
tool_handler python "install_python"

tool_register java "Java (asdf preferred)" "asdf" "macos,linux,wsl" "handler"
tool_handler java "install_java"

tool_register terraform "terraform" "" "macos,linux,wsl" "brew"
tool_pkgs terraform "terraform" "" "" "" ""

tool_register awscli "AWS CLI" "" "macos,linux,wsl" "brew,apt"
tool_pkgs awscli "awscli" "awscli" "" "" ""
tool_bin awscli "aws"

tool_register kubectl "kubectl" "" "macos,linux,wsl" "brew"
tool_pkgs kubectl "kubectl" "" "" "" ""

tool_register helm "helm" "" "macos,linux,wsl" "brew"
tool_pkgs helm "helm" "" "" "" ""

tool_register stern "stern" "" "macos,linux,wsl" "brew"
tool_pkgs stern "stern" "" "" "" ""

tool_register doppler "Doppler CLI" "brew" "macos,linux,wsl" "brew"
tool_pkgs doppler "doppler" "" "" "" ""
