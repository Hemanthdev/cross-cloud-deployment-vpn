#!/bin/bash

################################################################################
# Multi-Cloud SSH Key Generator with Visualization
# Generates SSH keys for AWS, Azure, GCP, OCI with ASCII graphs
# Compatible with: bash, sh, zsh
################################################################################

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Default values
KEY_DIR="${HOME}/.ssh"
KEY_TYPE="ed25519"  # or rsa (4096)
CLOUDS=("aws" "azure" "gcp" "oci")

################################################################################
# Functions
################################################################################

# Print header with graph
print_header() {
    clear
    cat << "EOF"
╔════════════════════════════════════════════════════════════════════════════╗
║       Multi-Cloud SSH Key Generator v1.0                                  ║
║       AWS | Azure | GCP | OCI                                             ║
╚════════════════════════════════════════════════════════════════════════════╝
EOF
    echo ""
}

# Print ASCII art graph
print_graph() {
    cat << 'EOF'
    ┌─────────────┐
    │    AWS      │
    │  Key Gen    │
    └────┬────────┘
         │
    ┌────▼────────┐
    │   Azure     │
    │  Key Gen    │
    └────┬────────┘
         │
    ┌────▼────────┐
    │     GCP     │
    │  Key Gen    │
    └────┬────────┘
         │
    ┌────▼────────┐
    │     OCI     │
    │  Key Gen    │
    └─────────────┘
EOF
}

# Progress bar
progress_bar() {
    local duration=${1}
    local increment=$(( 100 / duration ))
    local percent=0
    
    while [ $percent -le 100 ]; do
        printf "\rProgress: ["
        local filled=$(( percent / 5 ))
        local empty=$(( 20 - filled ))
        printf "%${filled}s" | tr ' ' '='
        printf "%${empty}s" | tr ' ' '-'
        printf "] %d%%" "$percent"
        percent=$(( percent + increment ))
        sleep 0.1
    done
    echo ""
}

# Generate SSH key pair
generate_key() {
    local cloud=$1
    local key_path="${KEY_DIR}/${cloud}_id_${KEY_TYPE}"
    
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}Generating SSH key for ${cloud^^}${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # Check if key already exists
    if [ -f "$key_path" ]; then
        echo -e "${YELLOW}⚠ Key already exists: $key_path${NC}"
        read -p "Overwrite? (y/n): " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${YELLOW}Skipped.${NC}"
            return
        fi
    fi
    
    # Generate key
    ssh-keygen -t "$KEY_TYPE" -f "$key_path" -N "" -C "multi-cloud-${cloud}@$(date +%Y-%m-%d)" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        chmod 600 "$key_path"
        chmod 644 "${key_path}.pub"
        echo -e "${GREEN}✓ Key generated successfully${NC}"
        
        # Display key info
        echo ""
        echo -e "${MAGENTA}Key Details:${NC}"
        echo -e "  Private: ${GREEN}$key_path${NC}"
        echo -e "  Public:  ${GREEN}${key_path}.pub${NC}"
        echo ""
        
        # Show key fingerprint
        echo -e "${MAGENTA}Fingerprint (SHA256):${NC}"
        ssh-keygen -l -f "$key_path" 2>/dev/null | awk '{print "  " $2}'
        echo ""
        
        # Show public key (first 50 chars)
        echo -e "${MAGENTA}Public Key (first 50 chars):${NC}"
        head -c 50 "${key_path}.pub" | sed 's/^/  /'
        echo "..."
        echo ""
        
        progress_bar 3
    else
        echo -e "${RED}✗ Failed to generate key${NC}"
    fi
}

# Display key statistics
show_statistics() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}Key Statistics${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    local total_keys=0
    local rsa_count=0
    local ed25519_count=0
    
    for cloud in "${CLOUDS[@]}"; do
        local key_path="${KEY_DIR}/${cloud}_id_*"
        for key in $key_path; do
            if [ -f "$key" ]; then
                total_keys=$((total_keys + 1))
                if [[ "$key" == *"rsa"* ]]; then
                    rsa_count=$((rsa_count + 1))
                elif [[ "$key" == *"ed25519"* ]]; then
                    ed25519_count=$((ed25519_count + 1))
                fi
            fi
        done
    done
    
    cat << EOF

┌─────────────────────────────────┐
│  Total Keys Generated: ${total_keys}        │
│  ED25519 Keys: ${ed25519_count}              │
│  RSA Keys: ${rsa_count}                 │
└─────────────────────────────────┘

EOF

    # Display bar chart of keys by cloud
    echo -e "${MAGENTA}Keys by Cloud Provider:${NC}"
    echo ""
    
    for cloud in "${CLOUDS[@]}"; do
        local count=0
        if [ -f "${KEY_DIR}/${cloud}_id_${KEY_TYPE}" ]; then
            count=1
        fi
        
        printf "%-8s │ " "${cloud^^}"
        for i in $(seq 1 $((count * 10))); do
            printf "█"
        done
        printf " %d\n" "$count"
    done
    echo ""
}

# Display key locations
show_key_locations() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}SSH Key Locations${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    for cloud in "${CLOUDS[@]}"; do
        local key_path="${KEY_DIR}/${cloud}_id_${KEY_TYPE}"
        if [ -f "$key_path" ]; then
            local size=$(du -h "$key_path" | cut -f1)
            echo -e "${GREEN}✓${NC} ${cloud^^:0:1}${cloud:1} Private:  ${GREEN}$key_path${NC} (${size})"
            echo -e "  ${cloud^^:0:1}${cloud:1} Public:   ${GREEN}${key_path}.pub${NC}"
        else
            echo -e "${YELLOW}○${NC} ${cloud^^:0:1}${cloud:1}: Not generated yet"
        fi
        echo ""
    done
}

# Main menu
show_menu() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}Select Option:${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "  ${CYAN}1)${NC} Generate All Keys (AWS, Azure, GCP, OCI)"
    echo -e "  ${CYAN}2)${NC} Generate AWS Key"
    echo -e "  ${CYAN}3)${NC} Generate Azure Key"
    echo -e "  ${CYAN}4)${NC} Generate GCP Key"
    echo -e "  ${CYAN}5)${NC} Generate OCI Key"
    echo -e "  ${CYAN}6)${NC} View Key Locations"
    echo -e "  ${CYAN}7)${NC} Show Statistics"
    echo -e "  ${CYAN}8)${NC} Change Key Type (ED25519/RSA)"
    echo -e "  ${CYAN}9)${NC} Add Keys to SSH Agent"
    echo -e "  ${CYAN}10)${NC} Exit"
    echo ""
}

# Add keys to SSH agent
add_to_agent() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}Adding Keys to SSH Agent${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    # Start SSH agent if not running
    eval "$(ssh-agent -s)" 2>/dev/null
    
    for cloud in "${CLOUDS[@]}"; do
        local key_path="${KEY_DIR}/${cloud}_id_${KEY_TYPE}"
        if [ -f "$key_path" ]; then
            ssh-add "$key_path" 2>/dev/null
            echo -e "${GREEN}✓ Added ${cloud^^} key to agent${NC}"
        fi
    done
    
    echo ""
    echo -e "${MAGENTA}SSH Agent Keys:${NC}"
    ssh-add -l 2>/dev/null | sed 's/^/  /'
    echo ""
}

# Change key type
change_key_type() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}Current Key Type: ${KEY_TYPE^^}${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "  ${CYAN}1)${NC} ED25519 (Recommended, smaller, faster)"
    echo -e "  ${CYAN}2)${NC} RSA-4096 (Traditional, widely supported)"
    echo ""
    read -p "Select: " choice
    
    case $choice in
        1)
            KEY_TYPE="ed25519"
            echo -e "${GREEN}✓ Key type set to ED25519${NC}"
            ;;
        2)
            KEY_TYPE="rsa"
            echo -e "${GREEN}✓ Key type set to RSA-4096${NC}"
            ;;
        *)
            echo -e "${YELLOW}Invalid choice${NC}"
            ;;
    esac
    echo ""
}

################################################################################
# Main Script
################################################################################

main() {
    # Check if SSH directory exists
    if [ ! -d "$KEY_DIR" ]; then
        echo -e "${YELLOW}Creating SSH directory: $KEY_DIR${NC}"
        mkdir -p "$KEY_DIR"
        chmod 700 "$KEY_DIR"
    fi
    
    # Main loop
    while true; do
        print_header
        print_graph
        show_menu
        
        read -p "Enter choice: " choice
        
        case $choice in
            1)
                for cloud in "${CLOUDS[@]}"; do
                    generate_key "$cloud"
                done
                ;;
            2)
                generate_key "aws"
                ;;
            3)
                generate_key "azure"
                ;;
            4)
                generate_key "gcp"
                ;;
            5)
                generate_key "oci"
                ;;
            6)
                print_header
                show_key_locations
                ;;
            7)
                print_header
                show_statistics
                ;;
            8)
                change_key_type
                ;;
            9)
                print_header
                add_to_agent
                ;;
            10)
                echo ""
                echo -e "${GREEN}Thank you for using SSH Key Generator!${NC}"
                echo ""
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid choice. Please try again.${NC}"
                ;;
        esac
        
        read -p "Press Enter to continue..." -t 3
    done
}

# Run main function
main
