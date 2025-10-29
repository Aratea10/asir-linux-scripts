#!/bin/bash
#
# hardening_basico.sh - Basic system hardening script
# Author: Sara Gallego Méndez
# Description: Applies basic security hardening measures to Linux systems
#

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

REPORT_FILE="/tmp/hardening_report_$(date +%Y%m%d_%H%M%S).txt"
DRY_RUN=false

show_help() {
    cat << EOF
Usage: ./hardening_basico.sh [OPTIONS]

Apply basic security hardening to the system.

OPTIONS:
    -n, --dry-run          Preview actions without making changes
    -h, --help             Show this help message

ACTIONS PERFORMED:
    - Disable unnecessary services (telnet, rsh, rlogin)
    - Configure secure umask (027)
    - Adjust sysctl security parameters
    - Configure password policies (PAM)
    - Install and configure fail2ban
    - Generate detailed report

EXAMPLES:
    sudo ./hardening_basico.sh
    sudo ./hardening_basico.sh --dry-run

NOTES:
    - Requires root/sudo privileges
    - Creates a report in /tmp/
    - Backup configs before applying changes

EOF
    exit 0
}

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" >> "$REPORT_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
    echo "[ERROR] $1" >> "$REPORT_FILE"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
    echo "[WARNING] $1" >> "$REPORT_FILE"
}

while [[ $# -gt 0 ]]; do
    case $1 in
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

if [[ $EUID -ne 0 ]] && [[ "$DRY_RUN" == false ]]; then
    log_error "This script must be run as root"
    exit 1
fi

log "=== System Hardening Script ==="
log "Report will be saved to: $REPORT_FILE"

if [[ "$DRY_RUN" == true ]]; then
    log_warning "DRY RUN MODE - No changes will be made"
fi

# 1. Disable unnecessary services
log ""
log "Step 1: Disabling unnecessary services..."

SERVICES_TO_DISABLE=("telnet" "rsh" "rlogin" "rexec")

for service in "${SERVICES_TO_DISABLE[@]}"; do
    if systemctl list-unit-files | grep -q "^${service}.service"; then
        if [[ "$DRY_RUN" == false ]]; then
            systemctl stop "$service" 2>/dev/null || true
            systemctl disable "$service" 2>/dev/null || true
            log "✓ Disabled service: $service"
        else
            log "Would disable service: $service"
        fi
    else
        log "Service not found (OK): $service"
    fi
done

# 2. Configure umask
log ""
log "Step 2: Configuring secure umask..."

if [[ "$DRY_RUN" == false ]]; then
    if ! grep -q "umask 027" /etc/profile; then
        echo "umask 027" >> /etc/profile
        log "✓ Added umask 027 to /etc/profile"
    else
        log "umask already configured in /etc/profile"
    fi
    
    if ! grep -q "umask 027" /etc/bash.bashrc 2>/dev/null; then
        echo "umask 027" >> /etc/bash.bashrc 2>/dev/null || true
        log "✓ Added umask 027 to /etc/bash.bashrc"
    fi
else
    log "Would configure umask 027"
fi

# 3. Configure sysctl parameters
log ""
log "Step 3: Configuring sysctl security parameters..."

SYSCTL_CONFIG="/etc/sysctl.d/99-hardening.conf"

if [[ "$DRY_RUN" == false ]]; then
    cat > "$SYSCTL_CONFIG" << 'EOF'
# IP forwarding (disable if not a router)
net.ipv4.ip_forward = 0

# Protect against SYN flood attacks
net.ipv4.tcp_syncookies = 1

# Ignore ICMP redirects
net.ipv4.conf.all.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0

# Ignore source-routed packets
net.ipv4.conf.all.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0

# Log martian packets
net.ipv4.conf.all.log_martians = 1

# Ignore ICMP ping requests (optional)
# net.ipv4.icmp_echo_ignore_all = 1
EOF
    sysctl -p "$SYSCTL_CONFIG" >/dev/null 2>&1
    log "✓ Applied sysctl security parameters"
else
    log "Would configure sysctl parameters"
fi

# 4. Configure password policies
log ""
log "Step 4: Configuring password policies..."

if [[ "$DRY_RUN" == false ]]; then
    # Install libpam-pwquality if not present
    if ! dpkg -l | grep -q libpam-pwquality; then
        apt-get update -qq
        apt-get install -y libpam-pwquality >/dev/null 2>&1
        log "✓ Installed libpam-pwquality"
    fi
    
    # Configure password quality
    PAM_PWQUALITY="/etc/security/pwquality.conf"
    if [[ -f "$PAM_PWQUALITY" ]]; then
        cp "$PAM_PWQUALITY" "${PAM_PWQUALITY}.backup.$(date +%Y%m%d)"
        
        sed -i 's/^# minlen =.*/minlen = 12/' "$PAM_PWQUALITY"
        sed -i 's/^# minclass =.*/minclass = 3/' "$PAM_PWQUALITY"
        sed -i 's/^# maxrepeat =.*/maxrepeat = 3/' "$PAM_PWQUALITY"
        
        log "✓ Configured password quality requirements"
    fi
else
    log "Would configure password policies"
fi

# 5. Install and configure fail2ban
log ""
log "Step 5: Installing and configuring fail2ban..."

if [[ "$DRY_RUN" == false ]]; then
    if ! command -v fail2ban-client &> /dev/null; then
        apt-get update -qq
        apt-get install -y fail2ban >/dev/null 2>&1
        log "✓ Installed fail2ban"
    else
        log "fail2ban already installed"
    fi
    
    # Create basic configuration
    FAIL2BAN_LOCAL="/etc/fail2ban/jail.local"
    cat > "$FAIL2BAN_LOCAL" << 'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[sshd]
enabled = true
port = ssh
logpath = /var/log/auth.log
EOF
    
    systemctl enable fail2ban
    systemctl restart fail2ban
    log "✓ Configured and started fail2ban"
else
    log "Would install and configure fail2ban"
fi

# Generate summary
log ""
log "=== Hardening Complete ==="
log "Report saved to: $REPORT_FILE"
log ""
log "NEXT STEPS:"
log "1. Review the report: cat $REPORT_FILE"
log "2. Test SSH access before closing current session"
log "3. Configure firewall (ufw/iptables) if not done"
log "4. Review user accounts and remove unnecessary ones"
log "5. Keep system updated: apt update && apt upgrade"

if [[ "$DRY_RUN" == false ]]; then
    log_warning "Some changes may require reboot to take full effect"
fi

exit 0