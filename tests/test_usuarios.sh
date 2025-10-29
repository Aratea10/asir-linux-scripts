#!/bin/bash
#
# Test crear_usuarios.sh
#

echo "=== Testing crear_usuarios.sh ==="
echo ""

# Test 1: Help option
echo "Test 1: Help option..."
if ../scripts/crear_usuarios.sh -h > /dev/null 2>&1; then
    echo "✓ Help option works"
else
    echo "✗ Help option failed"
fi

# Test 2: Missing CSV file
echo "Test 2: Missing CSV file..."
if ! ../scripts/crear_usuarios.sh 2>/dev/null; then
    echo "✓ Correctly rejects missing CSV file"
else
    echo "✗ Should reject missing CSV file"
fi

# Test 3: Dry-run mode
echo "Test 3: Dry-run mode..."
cat > /tmp/test_users.csv << 'EOF'
username,fullname,groups
testuser1,Test User 1,testgroup
testuser2,Test User 2,
EOF

if ../scripts/crear_usuarios.sh -f /tmp/test_users.csv --dry-run >/dev/null 2>&1; then
    echo "✓ Dry-run mode works"
else
    echo "✗ Dry-run mode failed"
fi

# Cleanup
rm -f /tmp/test_users.csv

echo ""
echo "=== Tests completed ==="
echo "Note: Full user creation tests require root privileges"