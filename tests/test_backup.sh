#!/bin/bash
#
# Test backup_rotativo.sh
#

echo "=== Testing backup_rotativo.sh ==="
echo ""

# Test 1: Help option
echo "Test 1: Help option..."
if ../scripts/backup_rotativo.sh -h > /dev/null 2>&1; then
    echo "✓ Help option works"
else
    echo "✗ Help option failed"
fi

# Test 2: Missing parameters
echo "Test 2: Missing parameters..."
if ! ../scripts/backup_rotativo.sh 2>/dev/null; then
    echo "✓ Correctly rejects missing parameters"
else
    echo "✗ Should reject missing parameters"
fi

# Test 3: Create test backup
echo "Test 3: Create test backup..."
mkdir -p /tmp/test_source /tmp/test_dest
echo "test content" > /tmp/test_source/file.txt

if ../scripts/backup_rotativo.sh -s /tmp/test_source -d /tmp/test_dest -r 7 >/dev/null 2>&1; then
    if ls /tmp/test_dest/backup_*.tar.gz 1> /dev/null 2>&1; then
        echo "✓ Backup file created"
        
        # Test 4: Check MD5 checksum
        if ls /tmp/test_dest/backup_*.tar.gz.md5 1> /dev/null 2>&1; then
            echo "✓ MD5 checksum file created"
        else
            echo "✗ MD5 checksum file not created"
        fi
    else
        echo "✗ Backup file not created"
    fi
else
    echo "✗ Backup creation failed"
fi

# Cleanup
rm -rf /tmp/test_source /tmp/test_dest

echo ""
echo "=== Tests completed ==="