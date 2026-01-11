#!/bin/bash
# Setup script for Mechanic - Unix (Linux/macOS)
# Usage: ./scripts/setup-mechanic.sh [MECHANIC_DIR] [MECHANIC_REPO]

set -e

MECHANIC_DIR="${1:-../../_dev_/Mechanic}"
MECHANIC_REPO="${2:-https://github.com/Falkicon/Mechanic.git}"

echo "Setting up Mechanic..."
echo ""

# Determine dev folder and addon folder
DEV_FOLDER=$(cd "$(dirname "$MECHANIC_DIR")" && pwd)
ADDON_FOLDER=$(pwd)

echo "Dev folder: $DEV_FOLDER"
echo "Addon folder: $ADDON_FOLDER"
echo ""

# Create symlink from _dev_/BookArchivist to actual addon folder
LINK_PATH="$DEV_FOLDER/BookArchivist"
if [ -L "$LINK_PATH" ]; then
    echo "✓ BookArchivist symlink already exists in dev folder"
elif [ -e "$LINK_PATH" ]; then
    echo "⚠ BookArchivist exists but is not a symlink"
else
    echo "Creating symlink: $LINK_PATH -> $ADDON_FOLDER"
    ln -s "$ADDON_FOLDER" "$LINK_PATH"
    if [ $? -eq 0 ]; then
        echo "✓ Created BookArchivist symlink in dev folder"
    else
        echo "✗ Failed to create symlink"
        exit 1
    fi
fi

echo ""

# Clone Mechanic if not present
if [ ! -d "$MECHANIC_DIR" ]; then
    echo "Cloning Mechanic from $MECHANIC_REPO..."
    git clone "$MECHANIC_REPO" "$MECHANIC_DIR"
else
    echo "✓ Mechanic directory already exists at: $MECHANIC_DIR"
fi

echo ""
echo "Installing Mechanic Desktop (editable mode)..."

# Install Mechanic in editable mode
cd "$MECHANIC_DIR/desktop"
python3 -m pip install --upgrade pip
python3 -m pip install -e .

echo ""
echo "✓ Mechanic setup complete!"
echo ""

# Sync Mechanic addons to WoW clients
echo "Syncing Mechanic addons to WoW clients..."
sync_success=true

for addon in "!Mechanic" "Mechanic"; do
    echo "  Syncing $addon..."
    if mech call addon.sync "{\"addon\": \"$addon\"}" > /dev/null 2>&1; then
        echo "  ✓ Synced $addon"
    else
        echo "  ✗ Failed to sync $addon"
        sync_success=false
    fi
done

if [ "$sync_success" = true ]; then
    echo ""
    echo "✓ All Mechanic addons synced to WoW clients!"
fi

echo ""
echo "Next steps:"
echo "  • Start dashboard: mech"
echo "  • Check installation: mech --version"
echo "  • View help: mech --help"
echo "  • Reload WoW to load Mechanic addons"
