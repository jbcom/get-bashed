# profiles

Profiles define default `FEATURES` and `INSTALLS` for the installer.

Each profile is an `.env` file with variables:

- `FEATURES` (comma list)
- `INSTALLS` (comma list)

Example:
```
FEATURES=gnu_over_bsd,build_flags,auto_tools
INSTALLS=brew,asdf,gnu_tools,rg,fd,bat,fzf,jq,yq,tree
```
