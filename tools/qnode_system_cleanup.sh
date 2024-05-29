#!/bin/bash

# Step 0: Welcome
echo "✨ Welcome! This script will clean up your system from temporary files and old log entries ✨"
echo "Made with 🔥 by LaMat - https://quilibrium.one"
echo "====================================================================================="
echo ""
echo "Processing... ⏳"
sleep 7  # Add a 7-second delay

#!/bin/bash

# Function to print a separator line
print_separator() {
    echo "======================================================================"
}

# Function to capture disk space
capture_disk_space() {
    df -h / | grep '/' | awk '{print $4}'
}

# Function to vacuum journal logs
vacuum_journal_logs() {
    echo "Vacuuming journalctl logs..."
    sudo journalctl --vacuum-size=500M
    print_separator
}

# Function to clean system caches and temporary files
clean_system() {
    echo "Cleaning system caches and temporary files..."
    sudo apt-get clean
    sudo apt-get autoclean  # Remove obsolete deb-packages
    sudo rm -rf /var/cache/apt/archives
    sudo rm -rf /tmp/*
    sudo rm -rf /var/tmp/*
    sudo rm -rf ~/.cache/*
    echo "System cleanup complete."
    print_separator
}

# Main function
main() {
    echo "Starting system cleanup..."

    # Capture initial disk space
    echo "Initial free disk space: $(capture_disk_space)"

    # Vacuum journal logs
    vacuum_journal_logs

    # Clean system caches and temporary files
    clean_system

    # Capture final disk space
    echo "Final free disk space: $(capture_disk_space)"

    echo "🌟 Cleanup process completed successfully."
}

# Call the main function
main
