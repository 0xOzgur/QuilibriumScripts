#!/bin/bash

# Step 0: Welcome
echo "✨ Welcome! This script will update your Quilibrium node when running it as a service. ✨"
echo ""
echo "Made with 🔥 by LaMat - https://quilibrium.one"
echo "Helped by 0xOzgur.eth - https://quilibrium.space"
echo "====================================================================================="
echo ""
echo "Processing... ⏳"
sleep 7  # Add a 7-second delay


# Step 1: Stop the ceremonyclient service if it exists
echo "⏳ Stopping the ceremonyclient service if it exists..."
if systemctl is-active --quiet ceremonyclient && service ceremonyclient stop; then
    echo "🔴 Service stopped successfully."
else
    echo "❌ Ceremonyclient service either does not exist or could not be stopped." >&2
fi
sleep 1

# Step 2: Move to the ceremonyclient directory
echo "Step 2: Moving to the ceremonyclient directory..."
cd ~/ceremonyclient || { echo "❌ Error: Directory ~/ceremonyclient does not exist."; exit 1; }

# Step 3: Discard local changes in release_autorun.sh
echo "✅ Discarding local changes in release_autorun.sh..."
git checkout -- node/release_autorun.sh

# Step 2: Download Binary
echo "⏳ Downloading New Release..."

# Change to the ceremonyclient directory
cd ~/ceremonyclient || { echo "❌ Error: Directory ~/ceremonyclient does not exist."; exit 1; }

# Set the remote URL
if git remote set-url origin https://source.quilibrium.com/quilibrium/ceremonyclient.git; then
    echo "✅ Remote URL set to https://source.quilibrium.com/quilibrium/ceremonyclient.git"
elif git remote set-url origin https://git.quilibrium-mirror.ch/agostbiro/ceremonyclient.git; then
    echo "✅ Remote URL set to https://git.quilibrium-mirror.ch/agostbiro/ceremonyclient.git"
elif git remote set-url origin https://github.com/QuilibriumNetwork/ceremonyclient.git; then
    echo "✅ Remote URL set to https://github.com/QuilibriumNetwork/ceremonyclient.git"
else
    echo "❌ Error: Failed to set remote URL." >&2
    exit 1
fi

# Pull the latest changes
git pull || { echo "❌ Error: Failed to download the latest changes." >&2; exit 1; }
git checkout release || { echo "❌ Error: Failed to checkout release." >&2; exit 1; }

echo "✅ Downloaded the latest changes successfully."

# Step 7: Set the version number
VERSION=$(cat config/version.go | grep -A 1 "func GetVersion() \[\]byte {" | grep -Eo '0x[0-9a-fA-F]+' | xargs printf "%d.%d.%d")

# Step 8: Get the system architecture
ARCH=$(uname -m)

# Step 9: Determine the ExecStart line based on the architecture
HOME=$(eval echo ~$USER)
NODE_PATH="$HOME/ceremonyclient/node"

if [ "$ARCH" = "x86_64" ]; then
    EXEC_START="$NODE_PATH/node-$VERSION-linux-amd64"
elif [ "$ARCH" = "aarch64" ]; then
    EXEC_START="$NODE_PATH/node-$VERSION-linux-arm64"
elif [ "$ARCH" = "arm64" ]; then
    EXEC_START="$NODE_PATH/node-$VERSION-darwin-arm64"
else
    echo "Unsupported architecture: $ARCH"
    exit 1
fi

# Step 3: Re-Create or Update Ceremonyclient Service
echo "🔧 Rebuilding Ceremonyclient Service..."
sleep 2  # Add a 2-second delay
SERVICE_FILE="/lib/systemd/system/ceremonyclient.service"
if [ ! -f "$SERVICE_FILE" ]; then
    echo "📝 Creating new ceremonyclient service file..."
    if ! sudo tee "$SERVICE_FILE" > /dev/null <<EOF
[Unit]
Description=Ceremony Client Go App Service

[Service]
Type=simple
Restart=always
RestartSec=5s
WorkingDirectory="$NODE_PATH"
ExecStart="$EXEC_START"

[Install]
WantedBy=multi-user.target
EOF
    then
        echo "❌ Error: Failed to create ceremonyclient service file." >&2
        exit 1
    fi
else
    echo "🔍 Checking existing ceremonyclient service file..."

    # Check if the required lines exist or are different
    if ! grep -q "WorkingDirectory=$NODE_PATH" "$SERVICE_FILE" || ! grep -q "ExecStart=$EXEC_START" "$SERVICE_FILE"; then
        echo "🔄 Updating existing ceremonyclient service file..."
        # Replace the existing lines with new values
        if ! sudo sed -i "s|WorkingDirectory=.*|WorkingDirectory=$NODE_PATH|" "$SERVICE_FILE"; then
            echo "❌ Error: Failed to update WorkingDirectory in ceremonyclient service file." >&2
            exit 1
        fi
        if ! sudo sed -i "s|ExecStart=.*|ExecStart=$EXEC_START|" "$SERVICE_FILE"; then
            echo "❌ Error: Failed to update ExecStart in ceremonyclient service file." >&2
            exit 1
        fi
    else
        echo "✅ No changes needed."
    fi
fi

# Step 5: Start the ceremonyclient service
echo "✅ Starting Ceremonyclient Service"
sleep 2  # Add a 2-second delay
systemctl daemon-reload
systemctl enable ceremonyclient
service ceremonyclient start

# Showing the node logs
echo "🌟Your Qnode is now updated to $VERSION!"
echo "⏳ Showing the node log... (CTRL+C to exit)"
echo ""
echo ""
sleep 3  # Add a 5-second delay
sudo journalctl -u ceremonyclient.service -f --no-hostname -o cat
