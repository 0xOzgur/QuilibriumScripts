#!/bin/bash

# Function to check for updates on GitHub and download the new version if available
check_for_updates() {
    echo "⚙️ Checking for updates..."
    latest_version=$(curl -s https://raw.githubusercontent.com/lamat1111/QuilibriumScripts/main/testing/qone.sh | md5sum | awk '{print $1}')
    current_version=$(md5sum $0 | awk '{print $1}')

    if [ "$latest_version" != "$current_version" ]; then
        echo "⚙️ A new version is available. Updating..."
        wget -O "$0.tmp" https://github.com/lamat1111/QuilibriumScripts/raw/main/testing/qone.sh
        chmod +x "$0.tmp"
        mv -f "$0.tmp" "$0"
        echo "✅ Update complete. Restarting..."
        exec "$0"
    else
        echo "✅ You already have the latest version."
    fi
}

# Service file path
SERVICE_FILE="/lib/systemd/system/ceremonyclient.service"
# User working folder
USER_HOME=$(eval echo ~$USER)
# Node path
NODE_PATH="$USER_HOME/ceremonyclient/node" 

VERSION=$(cat $NODE_PATH/config/version.go | grep -A 1 "func GetVersion() \[\]byte {" | grep -Eo '0x[0-9a-fA-F]+' | xargs printf "%d.%d.%d")

# Get the system architecture
ARCH=$(uname -m)

if [ "$ARCH" = "x86_64" ]; then
    EXEC_START="$NODE_PATH/node-$VERSION-linux-amd64"
elif [ "$ARCH" = "aarch64" ]; then
    EXEC_START="$NODE_PATH/node-$VERSION-linux-arm64"
elif [ "$ARCH" = "arm64" ]; then
    EXEC_START="$NODE_PATH/node-$VERSION-darwin-arm64"
else
    echo "❌ Unsupported architecture: $ARCH"
    exit 1
fi

#=====================
# Function Definitions
#=====================

# Function to ask for confirmation with an EOF message
confirm_action() {
    cat << EOF

$1

Do you want to proceed with "$2"? Type Y or N:
EOF
    read -p "> " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        $3
        return 0
    else
        echo "❌ Action \"$2\" canceled."
        return 1
    fi
}

# Function to wrap and indent text
wrap_text() {
    local text="$1"
    local indent="$2"
    echo "$text" | fold -s -w 80 | awk -v indent="$indent" '{printf "%s%s\n", indent, $0}'
}

#=====================
# Message Definitions
#=====================

# Define messages
prepare_server_message='
This action will install the necessary prerequisites for your server. 
If this is the first time you install a Quilibrium node I suggest you 
to follow the online guide instead at: https://docs.quilibrium.one/
'

install_node_message='
This action will install the node on your server. 
If this is the first time you install a Quilibrium node I suggest you 
to follow the online guide instead at: https://docs.quilibrium.one/ 
Ensure that your server meets all the requirements and that you have 
already prepared you server via Step 1.
'

update_node_message='
This action will update your node. 
Only use this if you have installed the node via the guide at 
https://docs.quilibrium.one/
'

setup_grpcurl_message='
This action will make some edit to your config.yml to enable communication with the network. 
If this a fresh node installation, let the node run for 30 minutes before doing this.
'

peer_manifest_message='
This action will check the peer manifest to provide information about the difficulty metric score of your node. 
It only works after 15-30 minutes that the node has been running.
'

#=====================
# Main Menu Function
#=====================

display_menu() {
    clear
    cat << EOF

                  QQQQQQQQQ       1111111   
                QQ:::::::::QQ    1::::::1   
              QQ:::::::::::::QQ 1:::::::1   
             Q:::::::QQQ:::::::Q111:::::1   
             Q::::::O   Q::::::Q   1::::1   
             Q:::::O     Q:::::Q   1::::1   
             Q:::::O     Q:::::Q   1::::1   
             Q:::::O     Q:::::Q   1::::l   
             Q:::::O     Q:::::Q   1::::l   
             Q:::::O     Q:::::Q   1::::l   
             Q:::::O  QQQQ:::::Q   1::::l   
             Q::::::O Q::::::::Q   1::::l   
             Q:::::::QQ::::::::Q111::::::111
              QQ::::::::::::::Q 1::::::::::1
                QQ:::::::::::Q  1::::::::::1
                  QQQQQQQQ::::QQ111111111111
                          Q:::::Q           
                           QQQQQQ  QUILIBRIUM.ONE                                                                                                                                  


===================================================================
                      ✨ QNODE QUICKSTART ✨
===================================================================
         Follow the guide at https://docs.quilibrium.one

                      Made with 🔥 by LaMat
====================================================================

EOF

    echo -e "Choose an option:\n"
    echo "If you want to install a new node, choose option 1, and then 2"
    echo ""
    echo "1) Prepare your server"
    echo "2) Install Node"
    echo "------------------------"
    echo "3) Update Node"
    echo "4) Set up gRPCurl"
    echo "5) Check Visibility"
    echo "6) Node Info"
    echo "7) Node Logs (CTRL+C to detach)"
    echo "8) Restart Node"
    echo "9) Stop Node"
    echo "10) Peer manifest (Difficulty metric)"
    echo "11) Node Version"
    echo "e) Exit"
}

#=====================
# Main Menu Loop
#=====================

while true; do
    display_menu
    
    read -rp "Enter your choice: " choice
    action_performed=0

    case $choice in
        1) confirm_action "$(wrap_text "$prepare_server_message" "")" "Prepare your server" install_prerequisites ;;
        2) confirm_action "$(wrap_text "$install_node_message" "")" "Install node" install_node ;;
        3) confirm_action "$(wrap_text "$update_node_message" "")" "Update node" update_node ;;
        4) confirm_action "$(wrap_text "$setup_grpcurl_message" "")" "Set up gRPCurl" configure_grpcurl ;;
        5) check_visibility action_performed=1 ;;
        6) node_info action_performed=1 ;;
        7) node_logs action_performed=1 ;;
        8) restart_node action_performed=1 ;;
        9) stop_node action_performed=1 ;;
        10) confirm_action "$(wrap_text "$peer_manifest_message" "")" "Peer manifest" peer_manifest ;;
        11) node_version action_performed=1 ;;
        e) exit ;;
        *) echo "Invalid option, please try again." ;;
    esac
    
    if [ $action_performed -eq 1 ]; then
        read -n 1 -s -r -p "Press any key to continue..."
    fi
done
    while true; do
        clear
        display_menu
    
        read -rp "Enter your choice: " choice
        action_performed=0
    
        case $choice in
            e) exit ;;
            *) echo "Invalid option, please try again." ;;
        esac
    
        if [ $action_performed -eq 1 ]; then
            read -n 1 -s -r -p "Press any key to continue..."
        fi
    done
done

# Check for updates
check_for_updates
