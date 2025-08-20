#!/bin/bash

set -e

echo "🏗️ Creating simple repository structure..."

# Utwórz podstawową strukturę
mkdir -p dists/stable/main/binary-amd64

# Skopiuj wszystkie pakiety
find pool -name "*.deb" -exec cp {} dists/stable/main/binary-amd64/ \;

# Wejdź do katalogu i utwórz Packages
cd dists/stable/main/binary-amd64

# Sprawdź czy dpkg-scanpackages jest dostępny
if command -v dpkg-scanpackages >/dev/null 2>&1; then
    dpkg-scanpackages . /dev/null > Packages
    gzip -9c Packages > Packages.gz
else
    echo "⚠️ dpkg-scanpackages not available, creating basic Packages file"
    for deb in *.deb; do
        echo "Package: $(echo $deb | cut -d'_' -f1)" >> Packages
        echo "Version: $(echo $deb | cut -d'_' -f2)" >> Packages
        echo "Architecture: $(echo $deb | cut -d'_' -f3 | cut -d'.' -f1)" >> Packages
        echo "Filename: ./$deb" >> Packages
        echo "" >> Packages
    done
    gzip -9c Packages > Packages.gz
fi

cd ../../..

# Utwórz plik Release
cat > dists/stable/Release << EOF
Origin: NAS Repository
Label: NAS Debian Repository
Suite: stable
Codename: stable
Architectures: amd64
Components: main
Description: Repository for NAS applications
Date: $(date -Ru)
EOF

# Dodaj hashe jeśli apt-ftparchive jest dostępny
if command -v apt-ftparchive >/dev/null 2>&1; then
    apt-ftparchive release dists/stable/ >> dists/stable/Release
fi

echo "✅ Simple repository created successfully"
