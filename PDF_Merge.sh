#!/bin/bash
# pdf_merge.sh - Merge all PDF files in a directory into a single PDF.
#
# This script:
#  1. Accepts an optional directory path as an argument (default: current directory).
#  2. Searches for all PDF files (*.pdf) in that directory (sorted alphabetically).
#  3. Prompts the user for an output file name, validating that it is not empty
#     and asking whether to overwrite if a file with that name already exists.
#  4. Checks for a PDF merging utility (pdfunite or pdftk) and uses it to merge the PDFs.
#  5. Provides helpful error messages and a usage (help) option.
#
# Usage:
#   ./pdf_merge.sh [directory]
#   ./pdf_merge.sh -h | --help
#
# Dependencies: pdfunite (from poppler) is preferred. Alternatively, pdftk can be used.

###########################
# Function: usage
# Display script usage and help.
###########################
usage() {
    echo "Usage: $(basename "$0") [directory]"
    echo
    echo "Merge all PDF files found in the specified directory (or the current directory"
    echo "if no directory is provided) into one merged PDF file."
    echo
    echo "Options:"
    echo "  -h, --help    Display this help message and exit"
    echo
    echo "Dependencies: pdfunite (preferred) or pdftk must be installed."
}

###########################
# Process help option.
###########################
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    usage
    exit 0
fi

###########################
# Directory Selection.
# Use the provided directory or default to the current directory.
###########################
TARGET_DIR="${1:-.}"

if [[ ! -d "$TARGET_DIR" ]]; then
    echo "Error: '$TARGET_DIR' is not a valid directory."
    exit 1
fi

###########################
# Dependency Check.
# Verify that a PDF merging utility is installed.
###########################
if command -v pdfunite >/dev/null 2>&1; then
    MERGE_TOOL="pdfunite"
elif command -v pdftk >/dev/null 2>&1; then
    MERGE_TOOL="pdftk"
else
    echo "Error: Neither 'pdfunite' nor 'pdftk' is installed."
    echo "Please install one of these tools and try again."
    exit 1
fi

###########################
# PDF File Discovery.
# Find PDF files (case-insensitive) in the directory.
# We use 'find' with -maxdepth 1 to only look at files in the given directory.
# The results are sorted alphabetically.
###########################
# Using mapfile with null-separated entries for filenames that may contain spaces.
mapfile -d '' pdf_files < <(find "$TARGET_DIR" -maxdepth 1 -type f -iname "*.pdf" -print0 | sort -z)

if [[ ${#pdf_files[@]} -eq 0 ]]; then
    echo "Error: No PDF files found in directory '$TARGET_DIR'."
    exit 1
fi

# Optionally, list the found PDF files:
echo "Found the following PDF files:"
for pdf in "${pdf_files[@]}"; do
    echo "  $(basename "$pdf")"
done
echo

###########################
# User Input for Output Filename.
###########################
while true; do
    read -rp "Enter a name for the output merged PDF file (without extension): " output_name

    # Validate non-empty input.
    if [[ -z "$output_name" ]]; then
        echo "Output file name cannot be empty. Please try again."
        continue
    fi

    output_file="${output_name}.pdf"

    # Check for conflict with an existing file.
    if [[ -e "$output_file" ]]; then
        read -rp "File '$output_file' already exists. Overwrite? (y/n): " response
        case "$response" in
            [Yy]* ) break ;;
            [Nn]* ) echo "Please enter a different file name." ;;
            * ) echo "Please answer with y (yes) or n (no)." ;;
        esac
    else
        break
    fi
done

###########################
# PDF Merging.
# Use the selected merging tool to combine the PDFs.
###########################
echo "Merging PDF files using '$MERGE_TOOL'..."
if [[ "$MERGE_TOOL" == "pdfunite" ]]; then
    pdfunite "${pdf_files[@]}" "$output_file"
    status=$?
elif [[ "$MERGE_TOOL" == "pdftk" ]]; then
    pdftk "${pdf_files[@]}" cat output "$output_file"
    status=$?
fi

if [[ $status -ne 0 ]]; then
    echo "Error: M

