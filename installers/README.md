# installers

Each installer is a Bash script that declares:

- `INSTALL_ID`: unique id
- `INSTALL_DEPS`: space-delimited list of other installers
- `INSTALL_DESC`: short description
- `INSTALL_PLATFORMS`: supported platforms
- `install_<id>()`: function that performs installation

The main installer resolves dependencies and executes installers idempotently.
