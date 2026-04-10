"""Sphinx configuration for get-bashed docs.

Uses shibuya theme and myst_parser.
"""

from datetime import datetime

project = "get-bashed"
copyright = f"{datetime.now().year}, Jon Bogaty"
author = "Jon Bogaty"

extensions = [
    "myst_parser",
    "sphinxcontrib.mermaid",
]

# Suppress warnings from shdoc generated brackets
suppress_warnings = ["myst.xref_missing"]

# Shibuya theme options
html_theme = "shibuya"
html_logo = "../assets/logo.png"
html_favicon = "../assets/logo.png"
html_static_path = ["_static"]
html_css_files = ["custom.css"]

html_theme_options = {
    "accent_color": "blue",
    "nav_links": [
        {"name": "GitHub", "url": "https://github.com/jbcom/get-bashed"},
    ],
    "announcement": "Terminal supremacy achieved. 💻",
}

# MyST settings
myst_enable_extensions = [
    "colon_fence",
    "deflist",
    "html_image",
]

# Tell Sphinx where the source files are
source_suffix = {
    ".md": "markdown",
}
