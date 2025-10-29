#!/bin/bash
#
# crear_usuarios.sh - Bulk user creation script from CSV
# Author: Sara Gallego Méndez
# Description: Creates multiple users from a CSV file with groups and temporary passwords
#

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

CSV_FILE=""
DRY_RUN=false

show_help() {
    cat << EOF
Usage: ./crear_usuarios.sh [OPTIONS]

Create multiple users from a CSV file.

OPTIONS:
    -f, --file FILE        CSV file with user data (required)
    -n, --dry-run          Preview actions without creating users
    -h, --help             Show this help message

CSV FORMAT:
    username,fullname,groups
    
    - username: Login name (alphanumeric, lowercase recommended)
    - fullname: Full name of the user
    - groups: Comma-separated list of groups (optional)

EXAMPLE CSV:
    jdoe,John Doe,developers,docker
    asmith,Alice Smith,developers
    bwilson,Bob Wilson,

EXAMPLES:
    ./crear_usuarios.sh -f users.csv
    ./crear_usuarios.sh --file users.csv --dry-run

NOTES:
    - Requires root/sudo privileges
    - Creates home directories automatically
    - Generates random temporary passwords
    - Forces password change on first login
    - Passwords are displayed once and should be noted

EOF
    exit 0
}

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

generate_password() {
    tr -dc 'A-Za-z0-9!@#$%^&*' < /dev/urandom | head -c 16
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--file)
            CSV_FILE="$2"
            shift 2
            ;;
        -n|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            show_help
            ;;
        *)
            log_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

if [[ -z "$CSV_FILE" ]]; then
    log_error "CSV file is required"
    exit 1
fi

if [[ ! -f "$CSV_FILE" ]]; then
    log_error "CSV file not found: $CSV_FILE"
    exit 1
fi

if [[ $EUID -ne 0 ]] && [[ "$DRY_RUN" == false ]]; then
    log_error "This script must be run as root (use sudo)"
    exit 1
fi

if [[ "$DRY_RUN" == true ]]; then
    log_warning "DRY RUN MODE - No changes will be made"
fi

log "Reading users from: $CSV_FILE"
CREATED_COUNT=0
SKIPPED_COUNT=0

while IFS=, read -r username fullname groups; do
    # Skip header line
    if [[ "$username" == "username" ]]; then
        continue
    fi
    
    # Skip empty lines
    if [[ -z "$username" ]]; then
        continue
    fi
    
    # Check if user already exists
    if id "$username" &>/dev/null; then
        log_warning "User already exists: $username (skipping)"
        ((SKIPPED_COUNT++))
        continue
    fi
    
    log "Processing user: $username ($fullname)"
    
    if [[ "$DRY_RUN" == false ]]; then
        # Generate temporary password
        TEMP_PASSWORD=$(generate_password)
        
        # Create user
        useradd -m -c "$fullname" -s /bin/bash "$username"
        
        # Set temporary password
        echo "$username:$TEMP_PASSWORD" | chpasswd
        
        # Force password change on first login
        chage -d 0 "$username"
        
        # Add to groups if specified
        if [[ -n "$groups" ]]; then
            IFS=',' read -ra GROUP_ARRAY <<< "$groups"
            for group in "${GROUP_ARRAY[@]}"; do
                # Trim whitespace
                group=$(echo "$group" | xargs)
                if [[ -n "$group" ]]; then
                    # Create group if it doesn't exist
                    if ! getent group "$group" > /dev/null; then
                        groupadd "$group"
                        log "Created group: $group"
                    fi
                    usermod -aG "$group" "$username"
                    log "Added $username to group: $group"
                fi
            done
        fi
        
        log "✓ User created: $username"
        echo -e "${YELLOW}  Temporary password: $TEMP_PASSWORD${NC}"
        echo -e "${YELLOW}  (User will be prompted to change on first login)${NC}"
        
        ((CREATED_COUNT++))
    else
        log "Would create user: $username"
        if [[ -n "$groups" ]]; then
            log "  Would add to groups: $groups"
        fi
    fi
    
done < "$CSV_FILE"

log "Summary:"
log "  Created: $CREATED_COUNT"
log "  Skipped: $SKIPPED_COUNT"

if [[ "$DRY_RUN" == false ]] && [[ $CREATED_COUNT -gt 0 ]]; then
    log_warning "IMPORTANT: Save the temporary passwords shown above!"
fi

log "Done!"
exit 0