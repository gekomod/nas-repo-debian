#!/bin/bash
# setup-repo.sh - Konfiguracja repozytorium Debian

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST="stable"
COMPONENT="main"
ARCH="amd64"

echo "🔧 Konfigurowanie repozytorium Debian..."

# Tworzenie struktury katalogów
mkdir -p "${REPO_DIR}/dists/${DIST}/${COMPONENT}/binary-${ARCH}"
mkdir -p "${REPO_DIR}/pool/${COMPONENT}"
mkdir -p "${REPO_DIR}/conf"

# Prosty plik konfiguracyjny
cat > "${REPO_DIR}/conf/distributions" << EOF
Origin: NAS Repository
Label: NAS Debian Repository
Codename: ${DIST}
Architectures: ${ARCH}
Components: ${COMPONENT}
Description: Repository for NAS applications
EOF

echo "✅ Repozytorium skonfigurowane!"
echo "📁 Ścieżka: ${REPO_DIR}"
echo ""
echo "Aby dodać pakiety, użyj: ./scripts/add-package.sh <package.deb>"
