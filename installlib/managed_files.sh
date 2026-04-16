ensure_block() {
  local file="$1"
  local marker="$2"
  local snippet="$3"

  mkdir -p "$(dirname "$file")"
  if [[ -r "$file" ]] && grep -Fq "$marker" "$file"; then
    return 0
  fi

  {
    echo ""
    echo "$marker"
    echo "$snippet"
  } >> "$file"
}

backup_file() {
  local file="$1"
  local backup_dir="$PREFIX/backup"
  local base ts

  [[ -e "$file" ]] || return 0

  mkdir -p "$backup_dir"
  chmod 700 "$backup_dir"
  base="$(basename "$file")"
  base="${base#.}"
  ts="$(date +%s)"
  mv "$file" "$backup_dir/${base}.${ts}"
}

link_dotfile() {
  local name="$1"
  local src="$PREFIX/$name"
  local dest="$HOME/.${name}"
  local current

  [[ -e "$src" ]] || return 0

  if [[ -L "$dest" ]]; then
    current="$(readlink "$dest" || true)"
    if [[ "$current" == "$src" ]]; then
      return 0
    fi
    backup_file "$dest"
  elif [[ -e "$dest" ]]; then
    backup_file "$dest"
  fi

  ln -s "$src" "$dest"
}

managed_manifest_path() {
  echo "$PREFIX/.get-bashed-manifest"
}

collect_managed_entries() {
  local -n entries_ref=$1
  local file

  entries_ref=(bashrc bash_profile bash_aliases inputrc vimrc gitconfig)

  shopt -s nullglob
  for file in "$REPO_DIR/bashrc.d"/*.sh; do
    entries_ref+=("bashrc.d/$(basename "$file")")
  done
  shopt -u nullglob
}

load_manifest_entries() {
  local manifest="$1"
  local -n entries_ref=$2
  entries_ref=()

  [[ -r "$manifest" ]] || return 0

  while IFS= read -r line; do
    [[ -n "$line" ]] && entries_ref+=("$line")
  done < "$manifest"
}

manifest_contains() {
  local needle="$1"
  shift
  local entry

  for entry in "$@"; do
    [[ "$entry" == "$needle" ]] && return 0
  done

  return 1
}

write_manifest_entries() {
  local manifest="$1"
  shift

  mkdir -p "$(dirname "$manifest")"
  printf '%s\n' "$@" > "$manifest"
}

sync_managed_entry() {
  local entry="$1"
  local src="$REPO_DIR/$entry"
  local dest="$PREFIX/$entry"

  mkdir -p "$(dirname "$dest")"
  cp -f "$src" "$dest"
}

remove_stale_managed_entries() {
  local -a current_entries=("$@")
  local -a previous_entries=()
  local manifest entry

  manifest="$(managed_manifest_path)"
  load_manifest_entries "$manifest" previous_entries

  for entry in "${previous_entries[@]}"; do
    if ! manifest_contains "$entry" "${current_entries[@]}"; then
      rm -f "$PREFIX/$entry"
    fi
  done
}

sync_managed_assets() {
  local -a current_entries=()
  local manifest entry

  collect_managed_entries current_entries
  manifest="$(managed_manifest_path)"

  mkdir -p "$PREFIX"
  [[ "$FORCE" -eq 1 ]] && remove_stale_managed_entries "${current_entries[@]}"

  for entry in "${current_entries[@]}"; do
    sync_managed_entry "$entry"
  done

  write_manifest_entries "$manifest" "${current_entries[@]}"
}

copy_legacy_file() {
  local src="$1"
  local dest_dir="$2"
  local base candidate suffix=1

  base="$(basename "$src")"
  candidate="$dest_dir/$base"

  while [[ -e "$candidate" ]]; do
    candidate="$dest_dir/migrated-${suffix}-${base}"
    suffix=$((suffix + 1))
  done

  cp -p "$src" "$candidate"
}

ensure_secrets_stub() {
  mkdir -p "$PREFIX/secrets.d"
  chmod 700 "$PREFIX/secrets.d"

  if [[ ! -e "$PREFIX/secrets.d/00-local.sh" ]]; then
    (
      umask 077
      cat <<'SECRETS' > "$PREFIX/secrets.d/00-local.sh"
# Place local secrets here. Example:
# export FOO="bar"
SECRETS
    )
  fi
}
