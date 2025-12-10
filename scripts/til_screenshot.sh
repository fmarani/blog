#!/usr/bin/env bash
#
# Helper script to make it easy to capture a screenshot
#
# Usage:
#
#   $ ./til_screenshot System preferences
#
# Linux dependencies:
#   - Screenshot: gnome-screenshot, scrot, flameshot, spectacle, or maim
#   - Resize: imagemagick (mogrify/convert)
#   - Optimize: optipng or pngcrush
#   - Clipboard: xclip or xsel

set -eu -o pipefail

PROJECT_ROOT=$(dirname $(dirname "$0"))

# Source functions
. $PROJECT_ROOT/scripts/til_utils.sh

function detect_screenshot_tool() {
    if command -v gnome-screenshot &> /dev/null; then
        echo "gnome-screenshot"
    elif command -v scrot &> /dev/null; then
        echo "scrot"
    elif command -v flameshot &> /dev/null; then
        echo "flameshot"
    elif command -v spectacle &> /dev/null; then
        echo "spectacle"
    elif command -v maim &> /dev/null; then
        echo "maim"
    elif command -v screencapture &> /dev/null; then
        echo "screencapture"
    else
        echo "none"
    fi
}

function capture_screenshot() {
    local filepath="$1"
    local tool=$(detect_screenshot_tool)

    case "$tool" in
        gnome-screenshot)
            gnome-screenshot -a -f "$filepath"
            ;;
        scrot)
            scrot -s "$filepath"
            ;;
        flameshot)
            flameshot gui -p "$filepath"
            ;;
        spectacle)
            spectacle -r -b -n -o "$filepath"
            ;;
        maim)
            maim -s "$filepath"
            ;;
        screencapture)
            screencapture -i "$filepath"
            ;;
        none)
            echo "Error: No screenshot tool found." >&2
            echo "Please install one of: gnome-screenshot, scrot, flameshot, spectacle, or maim" >&2
            exit 1
            ;;
    esac
}

function resize_image() {
    local filepath="$1"

    if command -v mogrify &> /dev/null; then
        mogrify -resize 700x700\> "$filepath"
    elif command -v convert &> /dev/null; then
        convert "$filepath" -resize 700x700\> "$filepath"
    else
        echo "Warning: ImageMagick not found, skipping resize" >&2
        echo "Install imagemagick for automatic resizing" >&2
    fi
}

function optimize_image() {
    local filepath="$1"

    if command -v optipng &> /dev/null; then
        optipng -o2 "$filepath" 2> /dev/null || true
    elif command -v pngcrush &> /dev/null; then
        pngcrush -ow "$filepath" 2> /dev/null || true
    else
        echo "Warning: No PNG optimizer found, skipping compression" >&2
        echo "Install optipng or pngcrush for automatic compression" >&2
    fi
}

function copy_to_clipboard() {
    local text="$1"

    if command -v xclip &> /dev/null; then
        echo "$text" | xclip -selection clipboard
    elif command -v xsel &> /dev/null; then
        echo "$text" | xsel --clipboard
    elif command -v pbcopy &> /dev/null; then
        echo "$text" | pbcopy
    else
        echo "Warning: No clipboard tool found" >&2
        echo "Install xclip or xsel to copy markdown to clipboard" >&2
        echo "Markdown snippet: $text"
        return 1
    fi
}

function main() {
    cd "$PROJECT_ROOT"

    # Generate appropriate filename
    local description="$1"
    filepath=$(generate_image_filepath "$description")

    # Check filepath doesn't already exist
    if [ -f "$filepath" ]
    then
        echo "An image already exists with the description - please choose another" >&2
        exit 1
    fi

    # Capture image
    echo "Select portion of screen to copy"
    capture_screenshot "$filepath"

    # Shrink image so it's no larger than 700x700px box.
    resize_image "$filepath"

    # Compress image
    optimize_image "$filepath"

    # Store image markdown in system clipboard
    filename=$(basename "$filepath")
    markdown_snippet="{{< figure src=\"/images/$filename\" title=\"\" caption=\"\" alt=\"$description\" >}}"

    if copy_to_clipboard "$markdown_snippet"; then
        echo "Image markdown snippet added to clipboard"
    fi

    echo "Screenshot saved to: $filepath"
}

function generate_image_filepath() {
    echo static/images/$(slugify "$1").png
}

if [[ $_ != $0 ]]
then
    if [ $# -eq 0 ]
    then
        echo "Please enter an image description" >&2
        exit 1
    else
        main "$*"
    fi
fi
