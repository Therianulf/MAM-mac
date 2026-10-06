#!/bin/bash
# Double-click me. Installs the Wine runtime and the official launcher into
# one folder under your home; nothing system-wide. See docs/plan.md.
cd "$(dirname "$0")" && exec bin/mam install "$@"
