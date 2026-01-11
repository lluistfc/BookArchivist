#!/bin/bash
# Setup script for Mechanic - Unix (Linux/macOS)
# Usage: ./scripts/setup-mechanic.sh [MECHANIC_DIR] [MECHANIC_REPO]

set -e

MECHANIC_DIR="${1:-../../_dev_/Mechanic}"
MECHANIC_REPO="${2:-https://github.com/Falkicon/Mechanic.git}"

echo "Setting up Mechanic..."
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
echo "Next steps:"
echo "  • Start dashboard: mech"
echo "  • Check installation: mech --version"
echo "  • View help: mech --help"
