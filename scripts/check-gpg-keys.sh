#!/bin/bash
# check-gpg-keys.sh - Sprawdza i zarządza kluczami GPG

set -e

echo "🔍 Checking GPG keys..."

# Sprawdź czy KEY.gpg istnieje
if [ -f "KEY.gpg" ]; then
    echo "✅ KEY.gpg file exists"
    # Sprawdź czy klucz jest zaimportowany
    if gpg --list-keys | grep -q "NAS Repository"; then
        echo "✅ GPG key already imported"
        KEY_ID=$(gpg --list-keys --with-colons | grep '^fpr:' | head -1 | cut -d':' -f10)
        echo "🔑 Using existing key: $KEY_ID"
    else
        echo "📥 Importing existing KEY.gpg"
        gpg --import KEY.gpg
        KEY_ID=$(gpg --list-keys --with-colons | grep '^fpr:' | head -1 | cut -d':' -f10)
        echo "🔑 Imported key: $KEY_ID"
    fi
else
    echo "🔑 Generating new GPG key..."
    # Generuj nowy klucz
    gpg --batch --generate-key <<EOF
Key-Type: RSA
Key-Length: 4096
Name-Real: NAS Repository
Name-Email: nas-repo@example.com
Expire-Date: 0
%no-protection
%commit
EOF
    
    KEY_ID=$(gpg --list-keys --with-colons | grep '^fpr:' | head -1 | cut -d':' -f10)
    gpg --armor --export "$KEY_ID" > KEY.gpg
    echo "✅ Generated new key: $KEY_ID"
    echo "📁 Saved as KEY.gpg"
fi

# Trust the key
echo "$KEY_ID:6:" | gpg --import-ownertrust

echo "✅ GPG setup completed"
echo "🔑 Key ID: $KEY_ID"
