#!/bin/bash
# Double-click me after installing. Opens the official launcher the right way
# (right folder, Play wired to Wine). Log in, Install/Update, Play.
cd "$(dirname "$0")" && exec bin/mam launcher "$@"
