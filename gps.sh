#!/bin/bash

# GPS - Git Profile Switcher (Auto-detecting)
# A tool to easily switch between different git user profiles
# Auto-detects profiles from SSH config and git configs - no config file needed!

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Auto-detection - no config directory needed
# Profiles are auto-detected from ~/.ssh/config and ~/.gitconfig* files

# Auto-detect profiles from SSH config and git configs
detect_profiles() {
    # Work profile from global config + default SSH host
    work_name=$(git config --global --get user.name 2>/dev/null || echo "")
    work_email=$(git config --global --get user.email 2>/dev/null || echo "")
    if [[ -n "$work_name" && -n "$work_email" ]]; then
        echo "work|$work_name|$work_email|github.com|Work profile (from global git config)"
    fi
    
    # Personal profile from SSH config + matching git config
    if grep -q "Host github.com-arvind3417" ~/.ssh/config 2>/dev/null; then
        if [[ -f "$HOME/.gitconfig-personal" ]]; then
            personal_name=$(git config --file="$HOME/.gitconfig-personal" --get user.name 2>/dev/null || echo "")
            personal_email=$(git config --file="$HOME/.gitconfig-personal" --get user.email 2>/dev/null || echo "")
            if [[ -n "$personal_name" && -n "$personal_email" ]]; then
                echo "personal|$personal_name|$personal_email|github.com-arvind3417|Personal profile (from ~/.gitconfig-personal)"
            fi
        fi
    fi
    
    # Scan for other SSH hosts that might be profiles
    while read -r line; do
        if [[ "$line" =~ ^Host[[:space:]]+(github\.com-[^[:space:]]+) ]]; then
            ssh_host="${BASH_REMATCH[1]}"
            profile_name="${ssh_host#github.com-}"
            
            # Skip if we already handled it above
            [[ "$profile_name" == "arvind3417" ]] && continue
            
            # Look for matching git config file
            config_file="$HOME/.gitconfig-$profile_name"
            if [[ -f "$config_file" ]]; then
                name=$(git config --file="$config_file" --get user.name 2>/dev/null || echo "Unknown")
                email=$(git config --file="$config_file" --get user.email 2>/dev/null || echo "Unknown")
                echo "$profile_name|$name|$email|$ssh_host|Auto-detected from $config_file"
            else
                echo "$profile_name|Unknown|Unknown|$ssh_host|SSH host found (no matching git config)"
            fi
        fi
    done < ~/.ssh/config
}

# Show usage information
show_usage() {
    echo -e "${CYAN}GPS - Auto-detecting Git Profile Switcher${NC}"
    echo "No config file needed - auto-detects from SSH config and git configs"
    echo ""
    echo -e "${YELLOW}Usage:${NC}"
    echo "  $0 list                    # Show auto-detected profiles"
    echo "  $0 current                 # Show current status"
    echo "  $0 switch <profile> [local] # Switch profile"
    echo ""
    echo -e "${YELLOW}Auto-detects from:${NC}"
    echo "  • ~/.ssh/config (GitHub hosts)"
    echo "  • ~/.gitconfig (global git config)"
    echo "  • ~/.gitconfig-* (profile-specific configs)"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo "  $0 switch work                    # Switch globally to work profile"
    echo "  $0 switch personal local          # Switch locally (current repo) to personal"
}

# List all auto-detected profiles
list_profiles() {
    echo -e "${CYAN}Auto-detected Git Profiles:${NC}"
    echo ""
    
    profiles=$(detect_profiles)
    if [[ -z "$profiles" ]]; then
        echo -e "${YELLOW}No profiles auto-detected.${NC}"
        echo "Make sure you have SSH hosts in ~/.ssh/config and git configs set up."
        return
    fi
    
    printf "%-15s %-25s %-30s %-20s %s\n" "PROFILE" "NAME" "EMAIL" "SSH HOST" "SOURCE"
    printf "%-15s %-25s %-30s %-20s %s\n" "-------" "----" "-----" "--------" "------"
    
    echo "$profiles" | while IFS='|' read -r profile name email ssh_host desc; do
        printf "%-15s %-25s %-30s %-20s %s\n" "$profile" "$name" "$email" "$ssh_host" "$desc"
    done
}

# Show current active profile with enhanced SSH status
show_current() {
    echo -e "${CYAN}Auto-detected Git Profile Status:${NC}"
    echo ""
    
    # Global configuration
    echo -e "${YELLOW}Global Configuration:${NC}"
    global_name=$(git config --global --get user.name 2>/dev/null || echo "Not set")
    global_email=$(git config --global --get user.email 2>/dev/null || echo "Not set")
    echo "  Name:  $global_name"
    echo "  Email: $global_email"
    
    # Local configuration (if in a git repo)
    if git rev-parse --git-dir >/dev/null 2>&1; then
        echo ""
        echo -e "${YELLOW}Local Configuration (current repository):${NC}"
        local_name=$(git config --local --get user.name 2>/dev/null || echo "Using global")
        local_email=$(git config --local --get user.email 2>/dev/null || echo "Using global")
        echo "  Name:  $local_name"
        echo "  Email: $local_email"
        
        # Show repository path
        repo_path=$(git rev-parse --show-toplevel 2>/dev/null)
        echo "  Repo:  $repo_path"
        
        echo ""
        echo -e "${YELLOW}Remote URLs and SSH Hosts:${NC}"
        
        # Check each remote
        while read -r remote_name; do
            url=$(git remote get-url "$remote_name" 2>/dev/null || continue)
            echo "  $remote_name: $url"
            
            if [[ "$url" =~ git@(github\.com[^:]*):.*\.git$ ]]; then
                ssh_host="${BASH_REMATCH[1]}"
                echo -e "    SSH Host: ${CYAN}$ssh_host${NC}"
                echo -e "    💡 Test: ${BLUE}ssh -T git@$ssh_host${NC}"
            fi
        done < <(git remote 2>/dev/null)
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
    
    # Find profile in auto-detected list
    profiles=$(detect_profiles)
    profile_line=$(echo "$profiles" | grep "^$profile_name|" || true)
    
    if [[ -z "$profile_line" ]]; then
        echo -e "${RED}Error: Profile '$profile_name' not found${NC}"
        echo "Available profiles:"
        list_profiles
        exit 1
    fi
    
    # Parse profile data
    IFS='|' read -r name git_name git_email ssh_host desc <<< "$profile_line"
    
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
    
    echo -e "${CYAN}🔄 Auto-detected Profile Switch: $profile_name $scope_text${NC}"
    echo ""
    
    # Step 1: Set git configuration
    echo -e "${YELLOW}Step 1: Setting git user configuration...${NC}"
    git config $scope_flag user.name "$git_name"
    git config $scope_flag user.email "$git_email"
    echo -e "${GREEN}✓ Git config updated${NC}"
    echo "  Name:  $git_name"
    echo "  Email: $git_email"
    echo ""
    
    # Step 2: Update remote URLs (only for local switches in git repos)
    if [ "$is_local" = "local" ] && git rev-parse --git-dir >/dev/null 2>&1; then
        echo -e "${YELLOW}Step 2: Updating remote URLs for SSH authentication...${NC}"
        
        # Get current remotes
        updated_any=false
        while read -r remote_name; do
            current_url=$(git remote get-url "$remote_name" 2>/dev/null || continue)
            
            # Check if it's a GitHub SSH URL
            if [[ "$current_url" =~ git@github\.com.*:.*\.git$ ]] || [[ "$current_url" =~ git@github\.com-.*:.*\.git$ ]]; then
                # Extract the repo part (user/repo.git)
                repo_part=$(echo "$current_url" | sed -E 's/git@[^:]+://')
                
                # Construct new URL with correct SSH host
                new_url="git@$ssh_host:$repo_part"
                
                if [ "$current_url" != "$new_url" ]; then
                    git remote set-url "$remote_name" "$new_url"
                    echo -e "${GREEN}✓ Updated $remote_name remote${NC}"
                    echo "  From: $current_url"
                    echo "  To:   $new_url"
                    updated_any=true
                fi
            fi
        done < <(git remote 2>/dev/null)
        
        if [ "$updated_any" = false ]; then
            echo -e "${BLUE}ℹ Remote URLs already correct${NC}"
        fi
        echo ""
    fi
    
    # Step 3: Verify SSH authentication (quick test)
    echo -e "${YELLOW}Step 3: SSH authentication configured for $ssh_host${NC}"
    echo -e "${BLUE}💡 Tip: Test with 'ssh -T git@$ssh_host' if needed${NC}"
    
    echo ""
    echo -e "${GREEN}🎉 Auto-detected profile switch complete!${NC}"
    echo "Source: $desc"
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
    "help"|"--help"|"-h"|"")
        show_usage
        ;;
    *)
        echo -e "${RED}Error: Unknown command '$1'${NC}"
        echo "Use '$0 help' for usage information"
        exit 1
        ;;
esac