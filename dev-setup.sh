#!/usr/bin/env bash
set -euo pipefail

## Parse command line arguments
DOWNLOAD_DOC=false
DOWNLOAD_TESTER=false

if [ "$#" -eq 0 ]; then
  DOWNLOAD_DOC=true
  DOWNLOAD_TESTER=true
else
  for arg in "$@"; do
    case $arg in
      --doc)
        DOWNLOAD_DOC=true
        ;;
      --tester)
        DOWNLOAD_TESTER=true
        ;;
      *)
        echo "Unknown argument: $arg"
        exit 1
    esac
  done
fi

# Choose downloader
if command -v curl >/dev/null 2>&1; then
  download() { curl -L -o "$2" "$1"; }
elif command -v wget >/dev/null 2>&1; then
  download() { wget -O "$2" "$1"; }
else
  echo "Neither wget nor curl is installed. Please install one of them to proceed." >&2
  exit 1
fi

if [ "$DOWNLOAD_DOC" = true ]; then
  ## Download lua documentation
  download "https://gitlab.com/shosetsuorg/kotlin-lib/-/raw/main/_doc.lua" "_doc.lua"

  ## Download javascript documentation
  # download "https://gitlab.com/shosetsuorg/kotlin-lib/-/raw/main/doc.js" "doc.js"
fi

if [ "$DOWNLOAD_TESTER" = true ]; then
  ## Download extension tester
  mkdir -p bin
  download "https://gitlab.com/api/v4/groups/12585416/-/packages/maven/app/shosetsu/extension-tester/2.1.1/extension-tester-2.1.1-all.jar" "bin/extension-tester.jar"
fi
