#!/bin/bash
# generate-gpg-key.sh - Generowanie klucza GPG dla repozytorium

set -e

echo "🔐 Generating GPG key for repository..."

# Sprawdź czy klucz już istnieje
if [ -f "KEY.gpg" ] && [ -f "private.key" ]; then
    echo "✅ GPG key already exists"
    exit 0
fi

# Generuj nowy klucz
gpg --batch --generate-key <<EOF
Key-Type: RSA
Key-Length: 4096
Subkey-Type: RSA
Subkey-Length: 4096
Name-Real: NAS Repository
Name-Email: nas-repo@users.noreply.github.com
Expire-Date: 0
Passphrase: $1
%no-protection
%commit
EOF

# Eksportuj klucz publiczny
KEY_ID=$(gpg --list-secret-keys --with-colons | grep '^fpr:' | head -1 | cut -d':' -f10)
gpg --armor --export "$KEY_ID" > KEY.gpg

# Eksportuj klucz prywatny (dla backupu)
gpg --armor --export-secret-keys "$KEY_ID" > private.key

echo "✅ GPG key generated: $KEY_ID"
echo "📁 Public key: KEY.gpg"
echo "🔒 Private key: private.key (keep secure!)"
