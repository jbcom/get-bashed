# Active Context

- Focus: stabilize installer registry, idempotent dotfile linking, and CI.
- Recent changes:
  - centralized tool registry in `installers/tools.sh`
  - unified install handlers in `installers/_helpers.sh`
  - optional dependencies keyed off config (e.g. git_signing -> gnupg)
  - added dotfile linking (`--link-dotfiles`) with backups
  - added default dotfiles (inputrc, vimrc, gitconfig, bash_aliases)
  - added `--name/--email` prompts + config wiring
  - added tests for dotfile linking and config output
- Next steps:
  - finish CI green (bashate/shellcheck)
  - expand BATS coverage beyond smoke tests
  - refresh README to document registry + optional deps
