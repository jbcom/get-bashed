---
title: STATE.md — get-bashed
updated: 2026-04-10
status: current
---

# State

Current state of the get-bashed project.

## What is done

### Installer

- POSIX `install.sh` bootstrap that locates or installs bash, then re-execs `install.bash`.
- `install.bash` with full profile/feature/installer resolution, config generation, and dotfile wiring.
- `--link-dotfiles` with backup and idempotent symlink replacement.
- `--name` / `--email` git identity flags written to installed `gitconfig`.
- `--with-ui` curses dialog mode, falling back to plain prompts.
- `--auto`, `--yes`, `--dry-run`, `--list*` flags.
- Circular dependency detection in the tool installer.
- Optional dependency gating by feature flags (`tool_opt_deps`).

### Tool Registry

- Centralized registry in `installers/tools.sh`.
- Custom handlers in `installers/_helpers.sh` for asdf, vimrc, shdoc, actionlint, gnu_tools, nodejs, python, java.
- `component_install` resolver: bash-it -> asdf -> brew -> system -> git/curl.
- `pkg_install` cross-platform package manager wrapper.
- `pipx_install` with pip fallback.
- `asdf_install_plugin` with repo override support.

### Runtime Modules

- `00-options.sh`: shell options, HISTIGNORE, EDITOR, fd limit.
- `10-helpers.sh`: shared helpers (`_maybe_source`, `_path_add_front`).
- `20-path.sh`: PATH construction (Homebrew, `~/.get-bashed/bin`, asdf shims).
- `30-buildflags.sh`: Homebrew build flags (conditional).
- `40-completions.sh`: bash completion sourcing.
- `50-tool-init.sh`: Cargo env, starship, direnv init.
- `60-asdf.sh`: asdf activation.
- `65-tools.sh`: optional CLI tool auto-install.
- `66-doppler.sh`: Doppler env init (conditional).
- `70-bash-it.sh`: bash-it activation (conditional).
- `70-env.sh`: general env vars.
- `80-aliases.sh`: alias definitions.
- `90-functions.sh`: utility functions (`ex` extractor, `doppler_shell`, `get_bashed_component`).
- `95-ssh-agent.sh`: SSH agent reuse (conditional).
- `99-secrets.sh`: secrets sourcing.

### CI/CD

- `ci.yml`: lint (pre-commit) + test (BATS + verify-install).
- `docs.yml`: GitHub Pages publish from `docs/`.
- `pr-title.yml`: Conventional Commits enforcement.
- `release-please.yml`: automated release PRs and CHANGELOG.
- `release.yml`: release artifact builds on version tags.
- `autofix.yml`: auto-apply fixable lint issues on PRs.
- `dependabot-automerge.yml`: auto-merge Dependabot minor/patch updates.

### Documentation

- `README.md`: user-facing install guide with all flags.
- `CONTRIBUTING.md`: style, design principles, adding modules/installers.
- `TOOLS.md`: tool management, profiles, features, listing/dry-run docs.
- `SECURITY.md`: threat model and vulnerability reporting.
- `docs/CONFIG.md`: config keys, profiles, override prefix, branch protection.
- `docs/SHDOC.md`: shdoc install and usage.
- `docs/README.md`: docs pipeline description.
- Generated: `docs/INSTALLER.md`, `docs/INSTALLERS_HELPERS.md`, `docs/INSTALLERS.md`, `docs/MODULES.md`, `docs/INDEX.md`.

## What is in progress

- Confirm CI green after latest installer refactors (split POSIX bootstrap + bash installer).
- Verify local dogfood install on macOS stays green after recent changes.

## What is next

- Expand BATS coverage to runtime module behavior (currently only installer is covered).
- Add coverage for optional deps gating edge cases.
- Add test for `--profiles dev` end-to-end to assert correct `get-bashedrc.sh` output.
- Consider integration test that sources `bashrc` in a subshell and checks key functions are available.

## Known issues

- `shdoc` is not available via Homebrew on macOS. CI installs it locally to `GET_BASHED_HOME/bin` using the `install_shdoc` handler (git clone + make).
- Doc generation in CI must ensure `GET_BASHED_HOME/bin` is on PATH when calling `shdoc`.
- `docs/MODULES.md` content is sparse because most `bashrc.d/` modules have minimal shdoc annotations. Adding annotations would improve generated docs.

## Active decisions

- Profile files (`profiles/*.env`) take precedence over built-in profile defaults. If a `profiles/dev.env` file exists, it is sourced and used instead of the hardcoded `apply_profile dev` case. This allows profile customization without modifying `install.bash`.
- `--features` CLI flags always win over profile settings, regardless of order.
- Dotfile symlinking (`--link-dotfiles`) backs up existing files to `~/.get-bashed/backup/` with a timestamp suffix before replacing them.
- The installer does not auto-source bash-it or Doppler at shell startup. Both require explicit feature enabling.
