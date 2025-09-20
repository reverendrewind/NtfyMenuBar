#!/bin/bash

# Generate icons from SVG for macOS app
# Requires ImageMagick or rsvg-convert

SVG_FILE="ntfy-svgrepo-com.svg"
ICONSET_DIR="NtfyMenuBar/Assets.xcassets/AppIcon.appiconset"

# Check if SVG file exists
if [ ! -f "$SVG_FILE" ]; then
    echo "Error: $SVG_FILE not found"
    exit 1
fi

# Create iconset directory if it doesn't exist
mkdir -p "$ICONSET_DIR"

echo "Generating app icons from $SVG_FILE..."

# Generate all required sizes for macOS
# Using rsvg-convert (more reliable for SVG)
if command -v rsvg-convert &> /dev/null; then
    echo "Using rsvg-convert..."
    
    # Generate each required size
    rsvg-convert -w 16 -h 16 "$SVG_FILE" -o "$ICONSET_DIR/icon_16x16.png"
    rsvg-convert -w 32 -h 32 "$SVG_FILE" -o "$ICONSET_DIR/icon_16x16@2x.png"
    rsvg-convert -w 32 -h 32 "$SVG_FILE" -o "$ICONSET_DIR/icon_32x32.png"
    rsvg-convert -w 64 -h 64 "$SVG_FILE" -o "$ICONSET_DIR/icon_32x32@2x.png"
    rsvg-convert -w 128 -h 128 "$SVG_FILE" -o "$ICONSET_DIR/icon_128x128.png"
    rsvg-convert -w 256 -h 256 "$SVG_FILE" -o "$ICONSET_DIR/icon_128x128@2x.png"
    rsvg-convert -w 256 -h 256 "$SVG_FILE" -o "$ICONSET_DIR/icon_256x256.png"
    rsvg-convert -w 512 -h 512 "$SVG_FILE" -o "$ICONSET_DIR/icon_256x256@2x.png"
    rsvg-convert -w 512 -h 512 "$SVG_FILE" -o "$ICONSET_DIR/icon_512x512.png"
    rsvg-convert -w 1024 -h 1024 "$SVG_FILE" -o "$ICONSET_DIR/icon_512x512@2x.png"
    
# Using ImageMagick convert
elif command -v convert &> /dev/null; then
    echo "Using ImageMagick..."
    
    # Generate each required size
    convert -background none "$SVG_FILE" -resize 16x16 "$ICONSET_DIR/icon_16x16.png"
    convert -background none "$SVG_FILE" -resize 32x32 "$ICONSET_DIR/icon_16x16@2x.png"
    convert -background none "$SVG_FILE" -resize 32x32 "$ICONSET_DIR/icon_32x32.png"
    convert -background none "$SVG_FILE" -resize 64x64 "$ICONSET_DIR/icon_32x32@2x.png"
    convert -background none "$SVG_FILE" -resize 128x128 "$ICONSET_DIR/icon_128x128.png"
    convert -background none "$SVG_FILE" -resize 256x256 "$ICONSET_DIR/icon_128x128@2x.png"
    convert -background none "$SVG_FILE" -resize 256x256 "$ICONSET_DIR/icon_256x256.png"
    convert -background none "$SVG_FILE" -resize 512x512 "$ICONSET_DIR/icon_256x256@2x.png"
    convert -background none "$SVG_FILE" -resize 512x512 "$ICONSET_DIR/icon_512x512.png"
    convert -background none "$SVG_FILE" -resize 1024x1024 "$ICONSET_DIR/icon_512x512@2x.png"
    
# Using sips (built-in macOS, but doesn't handle SVG directly)
else
    echo "Error: Please install rsvg-convert or ImageMagick"
    echo "  brew install librsvg"
    echo "  or"
    echo "  brew install imagemagick"
    exit 1
fi

# Generate menu bar template icons (for light/dark mode support)
TEMPLATE_DIR="NtfyMenuBar/Assets.xcassets/MenuBarIcon.imageset"
mkdir -p "$TEMPLATE_DIR"

if command -v rsvg-convert &> /dev/null; then
    # Menu bar icons should be 22pt (22px and 44px for @2x)
    rsvg-convert -w 22 -h 22 "$SVG_FILE" -o "$TEMPLATE_DIR/menubar-icon.png"
    rsvg-convert -w 44 -h 44 "$SVG_FILE" -o "$TEMPLATE_DIR/menubar-icon@2x.png"
    rsvg-convert -w 66 -h 66 "$SVG_FILE" -o "$TEMPLATE_DIR/menubar-icon@3x.png"
elif command -v convert &> /dev/null; then
    convert -background none "$SVG_FILE" -resize 22x22 "$TEMPLATE_DIR/menubar-icon.png"
    convert -background none "$SVG_FILE" -resize 44x44 "$TEMPLATE_DIR/menubar-icon@2x.png"
    convert -background none "$SVG_FILE" -resize 66x66 "$TEMPLATE_DIR/menubar-icon@3x.png"
fi

echo "Icon generation complete!"
echo "Generated icons in:"
echo "  - $ICONSET_DIR (App icons)"
echo "  - $TEMPLATE_DIR (Menu bar icons)"