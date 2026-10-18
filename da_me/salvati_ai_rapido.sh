#!/usr/bin/env bash
export PATH="$HOME/.opencode/bin:$HOME/.local/bin:$PATH"
echo "=== 1. Installo XERJ (binario statico rapido) ==="
if ! command -v xerj >/dev/null 2>&1; then
  curl -fsSL https://xerj.org/get | sh >/dev/null 2>&1 || true
fi
echo "XERJ: $(xerj --version 2>&1 | head -1 || echo in corso)"
