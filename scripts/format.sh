#!/usr/bin/env bash
# Formats the Swift sources with swift-format (bundled with the Swift toolchain), using .swift-format.
# Usage: scripts/format.sh [--check]   (--check lints instead and fails on any difference, as CI does)
set -euo pipefail
cd "$(dirname "$0")/.."

PATHS=(Package.swift Sources Tests scripts/make-icon.swift)
if [ "${1:-}" = "--check" ]; then
  swift format lint --strict --recursive --parallel "${PATHS[@]}"
else
  swift format format --in-place --recursive --parallel "${PATHS[@]}"
fi
