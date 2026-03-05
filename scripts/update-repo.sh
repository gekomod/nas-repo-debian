#!/bin/bash
# update-repo.sh - Aktualizacja metadanych repozytorium

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST="stable"
COMPONENT="main"
ARCH="amd64"

echo "🔄 Aktualizowanie repozytorium..."

cd "$REPO_DIR"

# Utwórz katalogi jeśli nie istnieją
mkdir -p "dists/${DIST}/${COMPONENT}/binary-${ARCH}"
mkdir -p "pool/${COMPONENT}"

# Generuj plik Packages jeśli apt-ftparchive jest dostępny
if command -v apt-ftparchive >/dev/null 2>&1; then
    echo "📦 Generowanie Packages.gz..."
    
    cd "dists/${DIST}"
    
    # Generuj Packages
    apt-ftparchive packages "../../pool/${COMPONENT}" > "${COMPONENT}/binary-${ARCH}/Packages"
    
    # Kompresuj do Packages.gz
    gzip -9c "${COMPONENT}/binary-${ARCH}/Packages" > "${COMPONENT}/binary-${ARCH}/Packages.gz"
    
    # Generuj Release file
    cat > Release << EOF
Origin: NAS Repository
Label: NAS Debian Repository
Suite: ${DIST}
Codename: ${DIST}
Architectures: ${ARCH}
Components: ${COMPONENT}
Description: Repository for NAS applications
Date: $(date -Ru)
EOF
    
    # Dodaj hashe do Release
    apt-ftparchive release . >> Release
    
    echo "✅ Metadane wygenerowane"
    
else
    echo "⚠️  apt-ftparchive nie jest dostępny"
    echo "ℹ️  Uruchom ten skrypt na systemie Debian/Ubuntu aby wygenerować pełne metadane"
fi

# Prosty plik Release dla podstawowej funkcjonalności
if [ ! -f "dists/${DIST}/Release" ] || [ ! command -v apt-ftparchive >/dev/null 2>&1 ]; then
    cd "dists/${DIST}"
    
    cat > Release << EOF
Origin: NAS Repository
Label: NAS Debian Repository
Suite: ${DIST}
Codename: ${DIST}
Architectures: ${ARCH}
Components: ${COMPONENT}
Description: Repository for NAS applications
Date: $(date -Ru)
EOF
fi

echo "✅ Repozytorium zaktualizowane!"
