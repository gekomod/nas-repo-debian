#!/bin/bash
# setup-signed-repo.sh - Konfiguracja podpisanego repozytorium

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST="stable"
COMPONENT="main"
ARCH="amd64"

echo "🔧 Setting up signed Debian repository..."

# Sprawdź czy klucz GPG istnieje
if [ ! -f "KEY.gpg" ]; then
    echo "❌ GPG key not found. Run generate-gpg-key.sh first."
    exit 1
fi

# Importuj klucz
gpg --import KEY.gpg
KEY_ID=$(gpg --list-keys --with-colons | grep '^fpr:' | head -1 | cut -d':' -f10)

# Utwórz strukturę repozytorium
mkdir -p "${REPO_DIR}/conf"
mkdir -p "${REPO_DIR}/dists/${DIST}/${COMPONENT}/binary-${ARCH}"
mkdir -p "${REPO_DIR}/pool/${COMPONENT}"

# Plik konfiguracyjny reprepro
cat > "${REPO_DIR}/conf/distributions" << EOF
Origin: NAS Repository
Label: NAS Debian Repository
Codename: ${DIST}
Architectures: ${ARCH}
Components: ${COMPONENT}
Description: Repository for NAS applications
SignWith: ${KEY_ID}
EOF

cat > "${REPO_DIR}/conf/options" << EOF
basedir ${REPO_DIR}
EOF

echo "✅ Signed repository setup complete"
echo "🔑 Using GPG key: ${KEY_ID}"
