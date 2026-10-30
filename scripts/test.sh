#!/usr/bin/env bash
# Runs the tests. Pass a folder made by make-test-library.sh to include the end-to-end test:
#   scripts/test.sh [/path/to/test-library-dir]
# The plugin path works around the Command Line Tools sometimes losing the Swift Testing macros.
# With full Xcode selected (as on CI) that folder doesn't exist and isn't needed.
set -euo pipefail
cd "$(dirname "$0")/.."
[ -n "${1:-}" ] && export AM2RB_TEST_LIBRARY="$1"
PLUGINS=/Library/Developer/CommandLineTools/usr/lib/swift/host/plugins/testing
if [ -d "$PLUGINS" ]; then
  swift test -Xswiftc -plugin-path -Xswiftc "$PLUGINS"
else
  swift test
fi
