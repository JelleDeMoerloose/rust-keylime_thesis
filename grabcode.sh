#!/usr/bin/env bash
#
# grabcode.sh
#
# A script to find and display file contents, while always skipping:
#   - The .git directory
#   - The node_modules directory
#   - Any file named .env
#   - Any file or directory whose path includes "test" (case-insensitive)
#   - Files with .png, .svg, .pdf extensions
#
# Usage:
#   # 1) If the first argument is a directory, we will search there.
#   #    Otherwise, we default to the current directory.
#
#   # Include any files whose name contains "deploy" and exclude .json
#   # from the "myfolder" directory:
#   ./grabcode.sh myfolder --include deploy --exclude-ext json
#
#   # Use the current directory, include .ts files only:
#   ./grabcode.sh --include-ext ts
#
#   # Combine includes and excludes, skip .md too:
#   ./grabcode.sh my_project --include service --include deploy --exclude-ext md
#
#   # Redirect to code.txt:
#   ./grabcode.sh --include deploy --exclude-ext json > code.txt
#

###############################################################################
# 1. Check if the first argument is a directory. If so, use it as TARGET_DIR;
#    otherwise, default to '.'.
###############################################################################

# Default
TARGET_DIR="."

# If the first argument exists and is a directory, use it
if [[ $# -gt 0 && -d "$1" ]]; then
  TARGET_DIR="$1"
  shift  # Remove the directory from the argument list so the rest can be parsed
fi

###############################################################################
# Default excludes
###############################################################################

# Directories to skip entirely
DEFAULT_EXCLUDED_DIRS=(
  ".git"
  "node_modules"
  "tmp_seed_main_api_server"
  "releases"
  "node_modules"
  # "modules"
  # "layout"
  # "mock-api"
)

# Files to skip by exact name
DEFAULT_EXCLUDED_FILES=(
  # ".env"
)

# File extensions to skip by default
DEFAULT_EXCLUDED_EXTENSIONS=(
  "png"
  "svg"
  "pdf"
  # "txt"
  # "json"
  "pyc"
  "mod"
  "sum"
  "pem"
  "gz"
  "box"
  "img"
  "qcow2"
  "iso"
  "o/"
  "controllers"
  "a"
  "lai"
  "md"
  "1"
  "libcrun"
  "json"
)

###############################################################################
# Arrays for user-specified filters
###############################################################################
declare -a INCLUDE_PATTERNS=()   # e.g., "deploy", "service"
declare -a INCLUDE_EXTENSIONS=() # e.g., "ts"
declare -a EXCLUDE_EXTENSIONS=() # e.g., "json", "txt"

###############################################################################
# 2. Parse CLI arguments (the rest after directory check)
###############################################################################
while [[ $# -gt 0 ]]; do
  case "$1" in
    --include|-i)
      INCLUDE_PATTERNS+=("$2")
      shift 2
      ;;
    --include-ext|-ie)
      INCLUDE_EXTENSIONS+=("$2")
      shift 2
      ;;
    --exclude-ext|-e)
      EXCLUDE_EXTENSIONS+=("$2")
      shift 2
      ;;
    -*)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

###############################################################################
# 3. Build the 'find' command
###############################################################################
FIND_CMD=( find "$TARGET_DIR" -type f )

###############################################################################
# 3a. Exclude default directories (.git, node_modules)
###############################################################################
for dir in "${DEFAULT_EXCLUDED_DIRS[@]}"; do
  FIND_CMD+=( -not -path "*/${dir}/*" )
done

###############################################################################
# 3b. Exclude files by exact name (e.g., .env)
###############################################################################
for fname in "${DEFAULT_EXCLUDED_FILES[@]}"; do
  FIND_CMD+=( -not -name "${fname}" )
done

###############################################################################
# 3c. Exclude paths that contain "test" (case-insensitive)
###############################################################################
# FIND_CMD+=( -not -ipath "*test*" )

###############################################################################
# 3d. Exclude default extensions (.png, .svg, .pdf)
###############################################################################
for default_ext in "${DEFAULT_EXCLUDED_EXTENSIONS[@]}"; do
  FIND_CMD+=( -not -iname "*.${default_ext}" )
done

###############################################################################
# 3e. Exclude user-specified extensions (e.g., .json, .txt)
#    That is: ! ( -iname "*.json" -o -iname "*.txt" )
###############################################################################
if [ ${#EXCLUDE_EXTENSIONS[@]} -gt 0 ]; then
  FIND_CMD+=( '!' '(' )
  for i in "${!EXCLUDE_EXTENSIONS[@]}"; do
    ext="${EXCLUDE_EXTENSIONS[$i]}"
    FIND_CMD+=( -iname "*.${ext}" )
    # If not the last extension, insert -o
    if [[ $i -lt $(( ${#EXCLUDE_EXTENSIONS[@]} - 1 )) ]]; then
      FIND_CMD+=( -o )
    fi
  done
  FIND_CMD+=( ')' )
fi

###############################################################################
# 3f. Include user-specified patterns (if any)
#    If no includes, everything (minus excludes) is shown.
#    If includes exist, we OR them together:
#      ( -iname "*deploy*" -o -iname "*service*" -o -iname "*.ts" ...)
###############################################################################
INCLUDE_ARGS=()

# a) filename substrings
if [ ${#INCLUDE_PATTERNS[@]} -gt 0 ]; then
  for pattern in "${INCLUDE_PATTERNS[@]}"; do
    INCLUDE_ARGS+=( -iname "*${pattern}*" -o )
  done
fi

# b) specific extensions
if [ ${#INCLUDE_EXTENSIONS[@]} -gt 0 ]; then
  for ext in "${INCLUDE_EXTENSIONS[@]}"; do
    INCLUDE_ARGS+=( -iname "*.${ext}" -o )
  done
fi

# Remove trailing -o if present
if [ ${#INCLUDE_ARGS[@]} -gt 0 ]; then
  unset 'INCLUDE_ARGS[${#INCLUDE_ARGS[@]}-1]'
fi

# Add parentheses around the OR sequence if needed
if [ ${#INCLUDE_ARGS[@]} -gt 0 ]; then
  FIND_CMD+=( '(' )
  FIND_CMD+=( "${INCLUDE_ARGS[@]}" )
  FIND_CMD+=( ')' )
fi

###############################################################################
# 4. Display each file's name, then its contents
###############################################################################
FIND_CMD+=( -exec echo "===== Contents of {} =====" \; -exec cat {} \; )

###############################################################################
# Debug: Show the constructed command
###############################################################################
echo "Below is the codebase, use it:"
# echo "  ${FIND_CMD[@]}"
# echo

# Execute
"${FIND_CMD[@]}"

echo "===================================================="
echo "Done."
