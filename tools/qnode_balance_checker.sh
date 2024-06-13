#!/bin/bash

# Script version
SCRIPT_VERSION="1.0"

# Define the node binary filename
NODE_BINARY="node-1.4.19-linux-amd64"

# Function to get the unclaimed balance
get_unclaimed_balance() {
    local node_directory="$HOME/ceremonyclient/node"
    local node_command="./$NODE_BINARY -node-info"
    
    # Run node command and capture output
    local output
    output=$(cd "$node_directory" && $node_command 2>&1)
    
    # Parse output to find unclaimed balance
    local balance
    balance=$(echo "$output" | grep "Unclaimed balance" | awk '{print $3}')
    
    # Check if balance is a valid number
    if [[ "$balance" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        echo "$balance"
    else
        echo "Error: Failed to retrieve balance"
        exit 1
    fi
}

# Function to write data to CSV file
write_to_csv() {
    local filename="$HOME/scripts/balance_log.csv"
    local data="$1"

    # Check if file exists to determine if headers need to be written
    if [ ! -f "$filename" ]; then
        echo "time,balance,increase" > "$filename"
    fi

    # Append data to CSV
    echo "$data" >> "$filename"
}

# Main function
main() {
    local current_time
    current_time=$(date +'%d/%m/%Y %H:%M')
    
    local balance
    balance=$(get_unclaimed_balance)
    
    if [ -n "$balance" ]; then
        local previous_balance="$balance"  # For now, assume it's the same balance

        # Calculate increase in balance over one hour
        local increase
        increase=$(echo "$balance - $previous_balance" | bc)

        # Format increase and balance to required precision
        local formatted_balance
        formatted_balance=$(printf "%.2f" "$balance")
        
        local formatted_increase
        formatted_increase=$(printf "%.5f" "$increase")
        
        # Print data
        local data_to_write="$current_time,$formatted_balance,$formatted_increase"
        echo "$data_to_write"
        
        # Write to CSV file
        write_to_csv "$data_to_write"
    fi
}

# Run main function
main
