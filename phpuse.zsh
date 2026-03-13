# ---- PHP バージョン自動切り替え ----

_phpuse_current_ver() {
  php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;" 2>/dev/null
}

_phpuse_brew_latest_ver() {
  if command -v jq &>/dev/null; then
    brew info --json=v2 php 2>/dev/null | jq -r '.formulae[0].versions.stable // empty' | grep -oE '^[0-9]+\.[0-9]+'
  else
    brew info php 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+' | head -1
  fi
}

_phpuse_brew_pkg() {
  local ver=$1
  local installed=$2
  local latest_ver=$3

  if [ -z "$installed" ]; then
    installed=$(brew list --formula 2>/dev/null | grep -E '^php(@[0-9]+\.[0-9]+)?$')
  fi

  if echo "$installed" | grep -xqF "php@${ver}"; then
    echo "php@${ver}"
  elif echo "$installed" | grep -xqF "php"; then
    [ -z "$latest_ver" ] && latest_ver=$(_phpuse_brew_latest_ver)
    [ "$latest_ver" = "$ver" ] && echo "php"
  fi
}

_phpuse_read_composer_ver() {
  local file="${1:-composer.json}"
  if command -v jq &>/dev/null; then
    jq -r '.require.php // empty' "$file" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+' | head -1
  else
    grep '"php"[[:space:]]*:' "$file" 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+' | head -1
  fi
}

_phpuse_do_switch() {
  local ver=$1

  local installed
  installed=$(brew list --formula 2>/dev/null | grep -E '^php(@[0-9]+\.[0-9]+)?$')
  local latest_ver
  latest_ver=$(_phpuse_brew_latest_ver)

  local pkg
  pkg=$(_phpuse_brew_pkg "$ver" "$installed" "$latest_ver")

  if [ -z "$pkg" ]; then
    echo "PHP $ver が見つかりません。インストールを試みます..." >&2
    if brew search --formula "php@${ver}" 2>/dev/null | grep -xqF "php@${ver}"; then
      brew install "php@${ver}" || return 1
      pkg="php@${ver}"
    elif [ "$latest_ver" = "$ver" ]; then
      brew install php || return 1
      pkg="php"
    else
      echo "brew に PHP $ver が見つかりません" >&2
      return 1
    fi
  fi

  [ -n "$installed" ] && echo "$installed" | xargs -I{} brew unlink {} >/dev/null 2>&1

  if ! brew link "$pkg" --force --overwrite >/dev/null; then
    echo "brew link 失敗: $pkg" >&2
    return 1
  fi

  echo "✓ PHP $(php -r 'echo PHP_VERSION;')"
}

phpuse() {
  local ver=$1

  if [ -z "$ver" ]; then
    echo "使い方: phpuse <version>  例: phpuse 8.1" >&2
    return 1
  fi

  if [[ ! "$ver" =~ ^[0-9]+\.[0-9]+$ ]]; then
    echo "無効なバージョン形式: $ver（正しい形式: 8.1）" >&2
    return 1
  fi

  if [ "$(_phpuse_current_ver)" = "$ver" ]; then
    return 0
  fi

  _phpuse_do_switch "$ver"
}

phpuse-composer() {
  local file="${1:-}"

  if [ -z "$file" ]; then
    if [ -f "composer.json" ]; then
      file="$PWD/composer.json"
    else
      local git_root
      git_root=$(git rev-parse --show-toplevel 2>/dev/null)
      if [ -n "$git_root" ] && [ -f "$git_root/composer.json" ]; then
        file="$git_root/composer.json"
      fi
    fi
  fi

  if [ -z "$file" ] || [ ! -f "$file" ]; then
    echo "composer.json が見つかりません" >&2
    return 1
  fi

  local ver
  ver=$(_phpuse_read_composer_ver "$file")

  if [ -z "$ver" ]; then
    echo "composer.json に PHP バージョンが見つかりません" >&2
    return 1
  fi

  if [ "$(_phpuse_current_ver)" = "$ver" ]; then
    return 0
  fi

  echo "→ PHP $ver に切り替えます (composer.json)"
  _phpuse_do_switch "$ver"
}

_phpuse_last_git_root=""
_phpuse_last_branch=""
_phpuse_last_dir=""

_auto_phpuse() {
  local git_root=""
  local current_branch=""

  if [ -d ".git" ]; then
    git_root="$PWD"
  elif git_root=$(git rev-parse --show-toplevel 2>/dev/null); then
    :
  fi

  if [ -n "$git_root" ]; then
    current_branch=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
  fi

  local need_check=""

  if [ -n "$git_root" ]; then
    if [ "$git_root" != "$_phpuse_last_git_root" ] || [ "$current_branch" != "$_phpuse_last_branch" ]; then
      need_check=1
      _phpuse_last_git_root="$git_root"
      _phpuse_last_branch="$current_branch"
      _phpuse_last_dir=""
    fi
  else
    if [ "$PWD" != "$_phpuse_last_dir" ]; then
      need_check=1
      _phpuse_last_dir="$PWD"
      _phpuse_last_git_root=""
      _phpuse_last_branch=""
    fi
  fi

  if [ -n "$need_check" ]; then
    local composer_file=""
    if [ -n "$git_root" ] && [ -f "$git_root/composer.json" ]; then
      composer_file="$git_root/composer.json"
    elif [ -f "composer.json" ]; then
      composer_file="$PWD/composer.json"
    fi

    [ -n "$composer_file" ] && phpuse-composer "$composer_file" 2>/dev/null
  fi
}

autoload -Uz add-zsh-hook
add-zsh-hook precmd _auto_phpuse
