# Active Context

- Focus: POSIX bootstrap + bash installer split, idempotent symlink wiring, CI autofix/verification.
- Recent changes:
  - split installer into POSIX `install.sh` bootstrap and `install.bash` full installer
  - dotfiles now symlink to `~/.get-bashed` (no root-level `~/.bashrc.d`/`~/.secrets.d`)
  - added symlink replacement + backup behavior
  - added CI autofix workflow and install verification script
  - hardened installers (brew detection, actionlint downloads, vimrc clone, pkg_install)
  - updated runtime modules (ssh-agent reuse, extractor error handling)
- Next steps:
  - resolve any failing CI workflows via `gh`
  - verify dogfood install on local machine stays green after new changes
