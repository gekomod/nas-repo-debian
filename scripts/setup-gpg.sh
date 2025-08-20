#!/bin/bash
# setup-gpg.sh - Konfiguracja GPG dla repozytorium

set -e

if [ -z "$GPG_PRIVATE_KEY" ] || [ -z "$GPG_PASSPHRASE" ]; then
    echo "❌ Brak klucza GPG lub passphrase"
    exit 1
fi

echo "🔐 Konfiguracja GPG..."

# Import klucza prywatnego
echo "$GPG_PRIVATE_KEY" | gpg --batch --import

# Konfiguracja gpg-agent dla passphrase
mkdir -p ~/.gnupg
cat > ~/.gnupg/gpg-agent.conf << EOF
allow-loopback-pinentry
default-cache-ttl 3600
max-cache-ttl 86400
EOF

echo "$GPG_PASSPHRASE" | gpg --batch --yes --passphrase-fd 0 --pinentry-mode loopback -ab

echo "✅ GPG skonfigurowany!"
