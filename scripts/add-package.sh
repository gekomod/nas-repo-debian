#!/bin/bash
# add-package.sh - Dodawanie pakietu do repozytorium (poprawione ścieżki)

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST="stable"
COMPONENT="main"
ARCH="amd64"

if [ $# -eq 0 ]; then
    echo "Usage: $0 <package.deb> [package2.deb ...]"
    exit 1
fi

echo "📦 Dodawanie pakietów do repozytorium..."

for DEB_FILE in "$@"; do
    if [ ! -f "$DEB_FILE" ]; then
        echo "❌ Plik nie istnieje: $DEB_FILE"
        continue
    fi
    
    # Sprawdź czy to poprawny pakiet Debian
    if ! dpkg-deb -I "$DEB_FILE" >/dev/null 2>&1; then
        echo "❌ Nieprawidłowy pakiet Debian: $DEB_FILE"
        continue
    fi
    
    # Pobierz nazwę pakietu i wersję
    PACKAGE_NAME=$(basename "$DEB_FILE")
    PACKAGE_BASENAME="${PACKAGE_NAME%.*}"
    
    # Utwórz strukturę katalogów w pool
    FIRST_LETTER="${PACKAGE_NAME:0:1}"
    POOL_DIR="${REPO_DIR}/pool/${COMPONENT}/${FIRST_LETTER}/${PACKAGE_BASENAME}"
    mkdir -p "$POOL_DIR"
    
    # Skopiuj pakiet do pool
    cp "$DEB_FILE" "$POOL_DIR/"
    echo "✅ Dodano do pool: $PACKAGE_NAME"
    
    # Utwórz strukturę w dists
    DIST_DIR="${REPO_DIR}/dists/${DIST}/${COMPONENT}/binary-${ARCH}"
    mkdir -p "$DIST_DIR"
    
    # Skopiuj pakiet również do dists (dla prostoty)
    cp "$DEB_FILE" "$DIST_DIR/"
    echo "✅ Dodano do dists: $PACKAGE_NAME"
done

# Aktualizuj metadane repozytorium
echo "🔄 Aktualizowanie metadanych repozytorium..."
cd "$REPO_DIR"

# Generuj Packages.gz jeśli apt-ftparchive jest dostępny
if command -v apt-ftparchive >/dev/null 2>&1; then
    echo "📦 Generowanie Packages.gz..."
    
    # Utwórz katalogi jeśli nie istnieją
    mkdir -p "dists/${DIST}/${COMPONENT}/binary-${ARCH}"
    
    # Generuj Packages
    cd "pool"
    apt-ftparchive packages ${COMPONENT} > "../dists/${DIST}/${COMPONENT}/binary-${ARCH}/Packages"
    
    # Kompresuj do Packages.gz
    cd "../dists/${DIST}/${COMPONENT}/binary-${ARCH}"
    gzip -9c "Packages" > "Packages.gz"
    
    echo "✅ Wygenerowano Packages.gz"
else
    echo "⚠️  apt-ftparchive nie jest dostępny, pomijam generowanie Packages.gz"
fi

# Utwórz podstawowy plik Release
cd "${REPO_DIR}/dists/${DIST}"
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

echo "✅ Wszystkie pakiety dodane do repozytorium!"
