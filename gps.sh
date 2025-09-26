#!/bin/bash

# Git Profile Switcher
# A tool to easily switch between different git user profiles

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration directory
PROFILES_DIR="$HOME/.git-profiles"
PROFILES_CONFIG="$PROFILES_DIR/profiles.conf"

# Create profiles directory if it doesn't exist
create_profiles_dir() {
    if [ ! -d "$PROFILES_DIR" ]; then
        mkdir -p "$PROFILES_DIR"
        echo -e "${GREEN}Created profiles directory at $PROFILES_DIR${NC}"
    fi
}

# Initialize profiles config if it doesn't exist
init_profiles_config() {
    create_profiles_dir
    if [ ! -f "$PROFILES_CONFIG" ]; then
        cat > "$PROFILES_CONFIG" << 'EOF'
# Git Profile Switcher Configuration
# Format: profile_name|git_name|git_email|description

# Example profiles:
# work|John Doe|john.doe@company.com|Work profile for Company Inc
# personal|John Doe|john.personal@gmail.com|Personal projects
EOF
        echo -e "${GREEN}Created profiles configuration at $PROFILES_CONFIG${NC}"
    fi
}

# Show usage information
show_usage() {
    echo -e "${CYAN}Git Profile Switcher${NC}"
    echo -e "${YELLOW}Usage:${NC}"
    echo "  $0 list                           # List all available profiles"
    echo "  $0 current                        # Show current active profile"
    echo "  $0 switch <profile_name> [local]  # Switch to profile (global or local)"
    echo "  $0 add <name> <email> [desc]      # Add new profile"
    echo "  $0 remove <profile_name>          # Remove a profile"
    echo "  $0 edit                           # Edit profiles configuration"
    echo "  $0 setup                          # Auto-setup profiles from current git configs"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo "  $0 switch work                    # Switch globally to work profile"
    echo "  $0 switch personal local          # Switch locally (current repo) to personal"
    echo "  $0 add work 'John Doe' john@company.com 'Work profile'"
}

# List all available profiles
list_profiles() {
    init_profiles_config
    
    echo -e "${CYAN}Available Git Profiles:${NC}"
    echo ""
    
    if [ ! -s "$PROFILES_CONFIG" ] || ! grep -q '^[^#].*|.*|.*' "$PROFILES_CONFIG"; then
        echo -e "${YELLOW}No profiles configured yet.${NC}"
        echo "Run '$0 setup' to auto-detect from your git configs or '$0 add' to create new ones."
        return
    fi
    
    printf "%-15s %-25s %-30s %s\n" "PROFILE" "NAME" "EMAIL" "DESCRIPTION"
    printf "%-15s %-25s %-30s %s\n" "-------" "----" "-----" "-----------"
    
    while IFS='|' read -r profile name email desc; do
        # Skip comments and empty lines
        [[ "$profile" =~ ^#.*$ ]] || [[ -z "$profile" ]] && continue
        
        printf "%-15s %-25s %-30s %s\n" "$profile" "$name" "$email" "$desc"
    done < "$PROFILES_CONFIG"
}

# Show current active profile
show_current() {
    echo -e "${CYAN}Current Git Configuration:${NC}"
    echo ""
    
    # Global configuration
    echo -e "${YELLOW}Global:${NC}"
    global_name=$(git config --global --get user.name 2>/dev/null || echo "Not set")
    global_email=$(git config --global --get user.email 2>/dev/null || echo "Not set")
    echo "  Name:  $global_name"
    echo "  Email: $global_email"
    
    # Local configuration (if in a git repo)
    if git rev-parse --git-dir >/dev/null 2>&1; then
        echo ""
        echo -e "${YELLOW}Local (current repository):${NC}"
        local_name=$(git config --local --get user.name 2>/dev/null || echo "Using global")
        local_email=$(git config --local --get user.email 2>/dev/null || echo "Using global")
        echo "  Name:  $local_name"
        echo "  Email: $local_email"
        
        # Show repository path
        repo_path=$(git rev-parse --show-toplevel 2>/dev/null)
        echo "  Repo:  $repo_path"
    else
        echo ""
        echo -e "${YELLOW}Not in a git repository${NC}"
    fi
}

# Switch to a profile
switch_profile() {
    local profile_name="$1"
    local is_local="$2"
    
    if [ -z "$profile_name" ]; then
        echo -e "${RED}Error: Profile name is required${NC}"
        echo "Usage: $0 switch <profile_name> [local]"
        exit 1
    fi
    
    init_profiles_config
    
    # Find the profile
    local profile_line
    profile_line=$(grep "^$profile_name|" "$PROFILES_CONFIG" 2>/dev/null || true)
    
    if [ -z "$profile_line" ]; then
        echo -e "${RED}Error: Profile '$profile_name' not found${NC}"
        echo "Available profiles:"
        list_profiles
        exit 1
    fi
    
    # Parse profile data
    IFS='|' read -r name git_name git_email desc <<< "$profile_line"
    
    # Determine scope
    local scope_flag=""
    local scope_text="globally"
    
    if [ "$is_local" = "local" ]; then
        if ! git rev-parse --git-dir >/dev/null 2>&1; then
            echo -e "${RED}Error: Not in a git repository. Cannot set local configuration.${NC}"
            exit 1
        fi
        scope_flag="--local"
        scope_text="locally"
    else
        scope_flag="--global"
    fi
    
    # Set git configuration
    git config $scope_flag user.name "$git_name"
    git config $scope_flag user.email "$git_email"
    
    echo -e "${GREEN}✓ Switched $scope_text to profile '$profile_name'${NC}"
    echo "  Name:  $git_name"
    echo "  Email: $git_email"
    
    if [ -n "$desc" ] && [ "$desc" != "" ]; then
        echo "  Description: $desc"
    fi
}

# Add a new profile
add_profile() {
    local profile_name="$1"
    local git_name="$2"
    local git_email="$3"
    local description="$4"
    
    if [ -z "$profile_name" ] || [ -z "$git_name" ] || [ -z "$git_email" ]; then
        echo -e "${RED}Error: Profile name, git name, and email are required${NC}"
        echo "Usage: $0 add <profile_name> '<git_name>' <git_email> [description]"
        exit 1
    fi
    
    init_profiles_config
    
    # Check if profile already exists
    if grep -q "^$profile_name|" "$PROFILES_CONFIG" 2>/dev/null; then
        echo -e "${RED}Error: Profile '$profile_name' already exists${NC}"
        exit 1
    fi
    
    # Add the profile
    echo "$profile_name|$git_name|$git_email|$description" >> "$PROFILES_CONFIG"
    
    echo -e "${GREEN}✓ Added profile '$profile_name'${NC}"
    echo "  Name:  $git_name"
    echo "  Email: $git_email"
    if [ -n "$description" ]; then
        echo "  Description: $description"
    fi
}

# Remove a profile
remove_profile() {
    local profile_name="$1"
    
    if [ -z "$profile_name" ]; then
        echo -e "${RED}Error: Profile name is required${NC}"
        echo "Usage: $0 remove <profile_name>"
        exit 1
    fi
    
    init_profiles_config
    
    # Check if profile exists
    if ! grep -q "^$profile_name|" "$PROFILES_CONFIG" 2>/dev/null; then
        echo -e "${RED}Error: Profile '$profile_name' not found${NC}"
        exit 1
    fi
    
    # Remove the profile
    grep -v "^$profile_name|" "$PROFILES_CONFIG" > "$PROFILES_CONFIG.tmp"
    mv "$PROFILES_CONFIG.tmp" "$PROFILES_CONFIG"
    
    echo -e "${GREEN}✓ Removed profile '$profile_name'${NC}"
}

# Edit profiles configuration
edit_profiles() {
    init_profiles_config
    
    # Use the user's preferred editor
    local editor="${EDITOR:-nano}"
    
    echo -e "${YELLOW}Opening profiles configuration in $editor...${NC}"
    "$editor" "$PROFILES_CONFIG"
    
    echo -e "${GREEN}✓ Configuration updated${NC}"
}

# Auto-setup profiles from existing git configurations
setup_profiles() {
    init_profiles_config
    
    echo -e "${CYAN}Setting up profiles from existing git configurations...${NC}"
    echo ""
    
    # Get global config
    global_name=$(git config --global --get user.name 2>/dev/null || echo "")
    global_email=$(git config --global --get user.email 2>/dev/null || echo "")
    
    if [ -n "$global_name" ] && [ -n "$global_email" ]; then
        # Try to determine if this is work or personal based on email domain
        if [[ "$global_email" == *"@"*"."* ]]; then
            domain=$(echo "$global_email" | cut -d'@' -f2)
            if [[ "$domain" == *"gmail.com"* ]] || [[ "$domain" == *"yahoo.com"* ]] || [[ "$domain" == *"outlook.com"* ]]; then
                profile_name="personal"
                desc="Personal profile"
            else
                profile_name="work"
                desc="Work profile"
            fi
        else
            profile_name="default"
            desc="Default profile"
        fi
        
        # Check if profile already exists
        if ! grep -q "^$profile_name|" "$PROFILES_CONFIG" 2>/dev/null; then
            echo "$profile_name|$global_name|$global_email|$desc" >> "$PROFILES_CONFIG"
            echo -e "${GREEN}✓ Added '$profile_name' profile from global config${NC}"
        else
            echo -e "${YELLOW}Profile '$profile_name' already exists${NC}"
        fi
    fi
    
    # Check for additional config files (like .gitconfig-personal, .gitconfig-work, etc.)
    for config_file in "$HOME"/.gitconfig-*; do
        if [ -f "$config_file" ]; then
            config_name=$(basename "$config_file" | sed 's/\.gitconfig-//')
            
            # Extract name and email from the config file
            name=$(git config --file="$config_file" --get user.name 2>/dev/null || echo "")
            email=$(git config --file="$config_file" --get user.email 2>/dev/null || echo "")
            
            if [ -n "$name" ] && [ -n "$email" ]; then
                # Check if profile already exists
                if ! grep -q "^$config_name|" "$PROFILES_CONFIG" 2>/dev/null; then
                    echo "$config_name|$name|$email|Profile from $config_file" >> "$PROFILES_CONFIG"
                    echo -e "${GREEN}✓ Added '$config_name' profile from $config_file${NC}"
                else
                    echo -e "${YELLOW}Profile '$config_name' already exists${NC}"
                fi
            fi
        fi
    done
    
    echo ""
    echo -e "${GREEN}Setup complete! Use '$0 list' to see all profiles.${NC}"
}

# Main script logic
case "$1" in
    "list"|"ls")
        list_profiles
        ;;
    "current"|"show")
        show_current
        ;;
    "switch"|"use")
        switch_profile "$2" "$3"
        ;;
    "add"|"create")
        add_profile "$2" "$3" "$4" "$5"
        ;;
    "remove"|"rm"|"delete")
        remove_profile "$2"
        ;;
    "edit")
        edit_profiles
        ;;
    "setup"|"init")
        setup_profiles
        ;;
    "help"|"--help"|"-h"|"")
        show_usage
        ;;
    *)
        echo -e "${RED}Error: Unknown command '$1'${NC}"
        echo ""
        show_usage
        exit 1
        ;;
esac

