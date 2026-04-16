"""Sphinx configuration for get-bashed docs."""

from __future__ import annotations

import os
import subprocess
from datetime import datetime
from pathlib import Path

project = "get-bashed"
copyright = f"{datetime.now().year}, Jon Bogaty"
author = "Jon Bogaty"
html_title = project
html_baseurl = "https://jbcom.github.io/get-bashed/"
repo_root = Path(__file__).resolve().parent.parent


def _release() -> str:
    if env := os.environ.get("DOCS_VERSION"):
        return env
    try:
        result = subprocess.run(
            ["git", "describe", "--tags", "--always", "--dirty"],
            cwd=repo_root,
            check=True,
            capture_output=True,
            text=True,
        )
    except (FileNotFoundError, subprocess.CalledProcessError):
        return "dev"
    return result.stdout.strip() or "dev"


release = version = _release()

extensions = [
    "myst_parser",
    "sphinx.ext.githubpages",
    "sphinxcontrib.mermaid",
]

# Suppress warnings from shdoc generated brackets
suppress_warnings = ["myst.xref_missing"]
exclude_patterns = ["_build", "Thumbs.db", ".DS_Store"]

# Shibuya theme options
html_theme = "shibuya"
html_logo = "../assets/logo.png"
html_favicon = "../assets/logo.png"
html_static_path = ["_static"]
html_css_files = ["custom.css"]
html_extra_path = ["public"]

html_theme_options = {
    "accent_color": "blue",
    "nav_links": [
        {"name": "Get Started", "url": "https://jbcom.github.io/get-bashed/getting-started/"},
        {"name": "Reference", "url": "https://jbcom.github.io/get-bashed/reference/index/"},
        {"name": "API", "url": "https://jbcom.github.io/get-bashed/api/"},
        {"name": "Releases", "url": "https://github.com/jbcom/get-bashed/releases"},
        {"name": "GitHub", "url": "https://github.com/jbcom/get-bashed"},
    ],
    "announcement": "Release bundles now drive docs-site install.sh plus Homebrew, Scoop, and Chocolatey manifests.",
}

# MyST settings
myst_enable_extensions = [
    "colon_fence",
    "deflist",
    "html_image",
]
myst_heading_anchors = 3

# Tell Sphinx where the source files are
source_suffix = {
    ".md": "markdown",
}

linkcheck_anchors = False
linkcheck_timeout = 10
linkcheck_retries = 2
linkcheck_ignore = [
    r"https://jbcom\.github\.io/get-bashed/.*",
]
