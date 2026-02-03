# Repository Guidelines

This repository contains the **get-bashed** modular Bash setup. It is intended to be portable, auditable, and safe to install on macOS, Linux, and WSL.

## Project Structure & Module Organization

- `bashrc` / `bash_profile`: entrypoints sourced by the installer.
- `bashrc.d/`: ordered modules (`00-` to `99-`) loaded in sequence.
- `bin/`: curated helper scripts meant to be portable and non-sensitive.
- `install.sh`: idempotent installer that wires user dotfiles.
- `installers/`: dependency-aware installers with metadata.
- `tests/`: BATS test suite.
- `.github/workflows/`: CI and release automation.

## Build, Test, and Development Commands

- `./install.sh --prefix ~/.get-bashed`: install locally for testing.
- `bats tests`: run installer tests.
- `./scripts/package.sh dist <version>`: build a release tarball.
- `./scripts/gen-docs.sh`: generate shdoc-based docs.

## Coding Style & Naming Conventions

- Shell: POSIX-ish Bash with strict mode in scripts (`set -euo pipefail`).
- Modules: two-digit prefix and hyphenated names (e.g., `20-path.sh`).
- Keep config portable; avoid hardcoding user-specific paths.

## Testing Guidelines

- Tests use BATS and should only validate install behavior and module wiring.
- Keep tests deterministic and side-effect free (use temp `HOME`).

## Commit & Pull Request Guidelines

- Commits should be small, focused, and explain intent.
- PRs should include:
  - Summary of changes
  - Install impact (if any)
  - Updated docs when behavior changes

## Security & Secrets

- Secrets live in `~/.get-bashed/secrets.d/` (ignored by git).
- `bashrc.d/99-secrets.sh` sources everything in `secrets.d/`.

# Project Memory Bank

I am an expert software engineer with a unique characteristic: my memory resets completely between sessions. This isn't a limitation - it's what drives me to maintain precise documentation. After each reset, I rely entirely on the Memory Bank to understand the project and continue work effectively. I must read ALL memory bank files at the start of every task - this is not optional.

## Memory Bank Structure

The Memory Bank consists of core files and optional context files, all in Markdown format. Files build upon each other in a clear hierarchy:

```
flowchart TD
    PB[projectbrief.md] --> PC[productContext.md]
    PB --> SP[systemPatterns.md]
    PB --> TC[techContext.md]

    PC --> AC[activeContext.md]
    SP --> AC
    TC --> AC

    AC --> P[progress.md]
```

### Core Files (Required)
1. `projectbrief.md`
   - Foundation document that shapes all other files
   - Created at project start if it doesn't exist
   - Defines core requirements and goals
   - Source of truth for project scope

2. `productContext.md`
   - Why this project exists
   - Problems it solves
   - How it should work
   - User experience goals

3. `activeContext.md`
   - Current work focus
   - Recent changes
   - Next steps
   - Active decisions and considerations
   - Important patterns and preferences
   - Learnings and project insights

4. `systemPatterns.md`
   - System architecture
   - Key technical decisions
   - Design patterns in use
   - Component relationships
   - Critical implementation paths

5. `techContext.md`
   - Technologies used
   - Development setup
   - Technical constraints
   - Dependencies
   - Tool usage patterns

6. `progress.md`
   - What works
   - What's left to build
   - Current status
   - Known issues
   - Evolution of project decisions

### Additional Context
Create additional files/folders within `memory-bank/` when they help organize:
- Complex feature documentation
- Integration specifications
- API documentation
- Testing strategies
- Deployment procedures

## Core Workflows

### Plan Mode
```
flowchart TD
    Start[Start] --> ReadFiles[Read Memory Bank]
    ReadFiles --> CheckFiles{Files Complete?}

    CheckFiles -->|No| Plan[Create Plan]
    Plan --> Document[Document in Chat]

    CheckFiles -->|Yes| Verify[Verify Context]
    Verify --> Strategy[Develop Strategy]
    Strategy --> Present[Present Approach]
```

### Act Mode
```
flowchart TD
    Start[Start] --> Context[Check Memory Bank]
    Context --> Update[Update Documentation]
    Update --> Execute[Execute Task]
    Execute --> Document[Document Changes]
```

## Documentation Updates

Memory Bank updates occur when:
1. Discovering new project patterns
2. After implementing significant changes
3. When user requests **update memory bank** (must review ALL files)
4. When context needs clarification

```
flowchart TD
    Start[Update Process]

    subgraph Process
        P1[Review ALL Files]
        P2[Document Current State]
        P3[Clarify Next Steps]
        P4[Document Insights & Patterns]

        P1 --> P2 --> P3 --> P4
    end

    Start --> Process
```

Note: When triggered by **update memory bank**, I must review every memory bank file, even if some don't require updates. Focus particularly on `activeContext.md` and `progress.md` as they track current state.

Remember: After every memory reset, I begin completely fresh. The Memory Bank is my only link to previous work. It must be maintained with precision and clarity, as my effectiveness depends entirely on its accuracy.
