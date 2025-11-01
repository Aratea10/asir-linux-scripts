# 🐧 ASIR Linux Scripts
<div align="center">

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Bash](https://img.shields.io/badge/Bash-4.0%2B-green.svg)](https://www.gnu.org/software/bash/)

</div>

Collection of useful Bash scripts for Linux system administration, developed as part of ASIR (Administración de Sistemas Informáticos en Red) coursework.

## 📋 Table of Contents
- [Requirements](#requirements)
- [Installation](#installation)
- [Scripts Included](#scripts-included)
- [Usage Examples](#usage-examples)
- [Testing](#testing)
- [Contributing](#contributing)
- [License](#license)
- [Author](#author)

## 🔧 Requirements
- Bash 4.0 or higher
- Linux operating system (tested on Ubuntu 20.04+, Debian 11+)
- Root/sudo privileges for some scripts
- Basic utilities: `tar`, `rsync`, `md5sum`

## 📦 Installation
1. Clone the repository:
```bash
git clone https://github.com/Aratea10/asir-linux-scripts.git
cd asir-linux-scripts
```

2. Make scripts executable (if not already):
```bash
chmod +x scripts/*.sh
```

3. Run any script with the `-h` flag to see usage information:
```bash
./scripts/backup_rotativo.sh -h
```

## 📜 Scripts Included
### 1. backup_rotativo.sh
Performs rotational backups with automatic compression and cleanup.

**Features:**
- Tar.gz compression
- MD5 checksum generation
- Automatic old backup removal based on retention policy
- Configurable retention period
- Colored output for better readability

**Usage:**
```bash
sudo ./scripts/backup_rotativo.sh -s /var/www -d /backups -r 7
```

**Parameters:**
- `-s, --source DIR`: Source directory to backup (required)
- `-d, --dest DIR`: Destination directory for backups (required)
- `-r, --retention DAYS`: Number of days to keep backups (default: 7)
- `-h, --help`: Show help message

**Example output:**
```
[2025-10-23 18:30:45] Starting backup of /var/www
[2025-10-23 18:30:45] Destination: /backups/backup_20251023_183045.tar.gz
[2025-10-23 18:30:52] Backup created successfully
[2025-10-23 18:30:52] Generating MD5 checksum...
[2025-10-23 18:30:53] Backup size: 2.3G
[2025-10-23 18:30:53] Removing backups older than 7 days...
[2025-10-23 18:30:53] Removed 3 old backup(s)
[2025-10-23 18:30:53] Backup completed successfully!
```

---

### 2. crear_usuarios.sh
Creates multiple users from a CSV file with automatic group assignment and password generation.

**Features:**
- Bulk user creation from CSV
- Automatic home directory creation
- Group assignment (creates groups if needed)
- Random temporary password generation
- Forces password change on first login
- Dry-run mode for testing

**CSV Format:**
```csv
username,fullname,groups
jdoe,John Doe,developers,docker
asmith,Alice Smith,developers
bwilson,Bob Wilson,
```

**Usage:**
```bash
sudo ./scripts/crear_usuarios.sh -f users.csv
sudo ./scripts/crear_usuarios.sh -f users.csv --dry-run  # Preview only
```

**Parameters:**
- `-f, --file FILE`: CSV file with user data (required)
- `-n, --dry-run`: Preview actions without creating users
- `-h, --help`: Show help message

**Example:**
See [docs/users_example.csv](docs/users_example.csv) for a sample CSV file.

---

### 3. hardening_basico.sh
Applies basic security hardening measures to Linux systems.

**Features:**
- Disables unnecessary services (telnet, rsh, rlogin)
- Configures secure umask (027)
- Applies sysctl security parameters
- Configures password quality requirements
- Installs and configures fail2ban
- Generates detailed report

**Usage:**
```bash
sudo ./scripts/hardening_basico.sh
sudo ./scripts/hardening_basico.sh --dry-run  # Preview only
```

**Parameters:**
- `-n, --dry-run`: Preview actions without making changes
- `-h, --help`: Show help message

**Security measures applied:**
- IP forwarding disabled
- SYN flood protection
- ICMP redirect protection
- Source-routed packet protection
- Minimum password length: 12 characters
- Password must contain 3 character classes
- Maximum repeated characters: 3
- Fail2ban with 1-hour ban time

**Output:**
Creates a detailed report in `/tmp/hardening_report_YYYYMMDD_HHMMSS.txt`

---

### 4. rsync_exclusiones.sh
Synchronizes directories with smart exclusions for common development files.

**Features:**
- Preserves permissions, timestamps, and symlinks
- Default exclusions for common files (.git, node_modules, etc.)
- Custom exclusion file support
- Progress display
- Dry-run mode
- Delete option (removes files from dest that don't exist in source)

**Default Exclusions:**
- `.git`
- `node_modules`
- `__pycache__`
- `*.pyc`
- `.cache`
- `*.log`
- `.DS_Store`
- `Thumbs.db`
- `*.tmp`, `*.swp`

**Usage:**
```bash
./scripts/rsync_exclusiones.sh -s /home/user/project -d /backup/project
./scripts/rsync_exclusiones.sh -s /var/www -d /mnt/backup --dry-run
./scripts/rsync_exclusiones.sh -s /data -d /backup/data -e custom_exclude.txt
```

**Parameters:**
- `-s, --source DIR`: Source directory (required)
- `-d, --dest DIR`: Destination directory (required)
- `-e, --exclude FILE`: Additional exclude file
- `-n, --dry-run`: Preview actions without copying
- `-h, --help`: Show help message

## 🎯 Usage Examples
### Complete Backup Workflow
```bash
# Daily backup with 30-day retention
sudo ./scripts/backup_rotativo.sh \
  -s /var/www/html \
  -d /mnt/backup/www \
  -r 30

# Verify backup integrity
cd /mnt/backup/www
md5sum -c backup_*.tar.gz.md5
```

### Bulk User Creation
```bash
# 1. Create CSV file
cat > new_users.csv << 'EOF'
username,fullname,groups
dev1,Developer One,developers,docker
dev2,Developer Two,developers
tester1,Tester One,testers
EOF

# 2. Preview (dry-run)
sudo ./scripts/crear_usuarios.sh -f new_users.csv --dry-run

# 3. Create users
sudo ./scripts/crear_usuarios.sh -f new_users.csv

# 4. Save the temporary passwords shown!
```

### System Hardening
```bash
# 1. Preview changes
sudo ./scripts/hardening_basico.sh --dry-run

# 2. Apply hardening
sudo ./scripts/hardening_basico.sh

# 3. Review report
cat /tmp/hardening_report_*.txt

# 4. Test SSH access (don't close current session!)
# Open new terminal and try to connect

# 5. Reboot if needed
sudo reboot
```

### Smart Synchronization
```bash
# Sync web project to backup
./scripts/rsync_exclusiones.sh \
  -s /var/www/myproject \
  -d /backup/myproject

# Create custom exclusions
cat > my_excludes.txt << 'EOF'
*.bak
vendor/
.env
EOF

./scripts/rsync_exclusiones.sh \
  -s /home/user/data \
  -d /mnt/backup/data \
  -e my_excludes.txt
```

## 🧪 Testing
Run the test suite to verify script functionality:

```bash
cd tests
./test_backup.sh
./test_usuarios.sh
```

**Note:** Some tests require root privileges and may not perform actual changes (they use dry-run mode or temporary directories).

To run all tests:
```bash
cd tests
for test in test_*.sh; do
    echo "Running $test..."
    bash "$test"
    echo ""
done
```

## 🤝 Contributing
Contributions are welcome! Please feel free to submit issues, fork the repository, and create pull requests.

### How to contribute:
1. Fork the repository
2. Create a feature branch: `git checkout -b feature/mi-nueva-funcionalidad`
3. Commit your changes: `git commit -m "feat: Add new feature"`
4. Push to the branch: `git push origin feature/mi-nueva-funcionalidad`
5. Open a Pull Request

### Commit Convention
This project follows [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation changes
- `test:` Adding or updating tests
- `refactor:` Code refactoring
- `chore:` Maintenance tasks

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👤 Author

**Sara Gallego Méndez**

- GitHub: [@Aratea10](https://github.com/Aratea10)
- Project: [asir-linux-scripts](https://github.com/Aratea10/asir-linux-scripts)

---

### 📚 Additional Resources
- [Bash Scripting Guide](https://www.gnu.org/software/bash/manual/)
- [Linux System Administration](https://www.tldp.org/LDP/sag/html/)
- [Security Best Practices](https://www.cisecurity.org/cis-benchmarks)

---

⭐ If you find this project useful, please consider giving it a star on GitHub!