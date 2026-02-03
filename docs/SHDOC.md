# shdoc

This repo uses `shdoc` to generate documentation from shell scripts.

## Install

Arch Linux (AUR):
```bash
yay -S shdoc-git
```

Using Git (requires gawk):
```bash
sudo apt-get install gawk

git clone --recursive https://github.com/reconquest/shdoc
cd shdoc
sudo make install
```

Local (no sudo) to get-bashed prefix:
```bash
GET_BASHED_HOME="$HOME/.get-bashed"
mkdir -p "$GET_BASHED_HOME/bin"

git clone --recursive https://github.com/reconquest/shdoc
cd shdoc
make install PREFIX="$GET_BASHED_HOME"
```

Note: shdoc requires Bash 4+ for `;;&` case labels. On macOS, install a newer
Bash via Homebrew and use that when building from source.

## Generate

```bash
./scripts/gen-docs.sh
```
