#!/bin/bash
#
# backup_rotativo.sh - Rotational backup script with compression
# Author: Sara Gallego Méndez
# Description: Performs rotational backups with automatic cleanup and MD5 checksums
#

set -euo pipefail

# Default values
RETENTION_DAYS=7
SOURCE_DIR=""
DEST_DIR=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to display help
show_help() {
    cat << EOF
Usage: ./backup_rotativo.sh [OPTIONS]

Perform rotational backups with automatic compression and cleanup.

OPTIONS:
    -s, --source DIR       Source directory to backup (required)
    -d, --dest DIR         Destination directory for backups (required)
    -r, --retention DAYS   Number of days to keep backups (default: 7)
    -h, --help             Show this help message

EXAMPLES:
    ./backup_rotativo.sh -s /var/www -d /backups -r 7
    ./backup_rotativo.sh --source /home/user/data --dest /mnt/backup

NOTES:
    - Backups are compressed using tar.gz
    - MD5 checksums are generated for each backup
    - Old backups are automatically removed based on retention policy
    - Requires write permissions in destination directory

EOF
    exit 0
}

# Function to log messages
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--source)
            SOURCE_DIR="$2"
            shift 2
            ;;
        -d|--dest)
            DEST_DIR="$2"
            shift 2
            ;;
        -r|--retention)
            RETENTION_DAYS="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            ;;
        *)
            log_error "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

# Validate required parameters
if [[ -z "$SOURCE_DIR" ]]; then
    log_error "Source directory is required"
    echo "Use -h or --help for usage information"
    exit 1
fi

if [[ -z "$DEST_DIR" ]]; then
    log_error "Destination directory is required"
    echo "Use -h or --help for usage information"
    exit 1
fi

# Validate source directory exists
if [[ ! -d "$SOURCE_DIR" ]]; then
    log_error "Source directory does not exist: $SOURCE_DIR"
    exit 1
fi

# Create destination directory if it doesn't exist
if [[ ! -d "$DEST_DIR" ]]; then
    log "Creating destination directory: $DEST_DIR"
    mkdir -p "$DEST_DIR"
fi

# Generate backup filename with timestamp
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="backup_${TIMESTAMP}.tar.gz"
BACKUP_PATH="${DEST_DIR}/${BACKUP_NAME}"
CHECKSUM_PATH="${BACKUP_PATH}.md5"

# Perform backup
log "Starting backup of $SOURCE_DIR"
log "Destination: $BACKUP_PATH"

if tar -czf "$BACKUP_PATH" -C "$(dirname "$SOURCE_DIR")" "$(basename "$SOURCE_DIR")"; then
    log "Backup created successfully"
    
    # Generate MD5 checksum
    log "Generating MD5 checksum..."
    md5sum "$BACKUP_PATH" > "$CHECKSUM_PATH"
    log "Checksum saved to $CHECKSUM_PATH"
    
    # Display backup size
    BACKUP_SIZE=$(du -h "$BACKUP_PATH" | cut -f1)
    log "Backup size: $BACKUP_SIZE"
else
    log_error "Backup failed"
    exit 1
fi

# Remove old backups
log "Removing backups older than $RETENTION_DAYS days..."
DELETED_COUNT=0

while IFS= read -r -d '' old_backup; do
    log_warning "Deleting old backup: $(basename "$old_backup")"
    rm -f "$old_backup" "${old_backup}.md5"
    ((DELETED_COUNT++))
done < <(find "$DEST_DIR" -name "backup_*.tar.gz" -type f -mtime +"$RETENTION_DAYS" -print0)

if [[ $DELETED_COUNT -eq 0 ]]; then
    log "No old backups to remove"
else
    log "Removed $DELETED_COUNT old backup(s)"
fi

# Display current backups
CURRENT_BACKUPS=$(find "$DEST_DIR" -name "backup_*.tar.gz" -type f | wc -l)
log "Current number of backups: $CURRENT_BACKUPS"

log "Backup completed successfully!"
exit 0