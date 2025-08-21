#!/bin/bash
# create-simple-repo.sh - Prosta wersja bez duplikatów

set -e

echo "🏗️ Creating properly structured repository..."

# Utwórz poprawną strukturę repozytorium Debian
mkdir -p dists/stable/main/binary-amd64
mkdir -p pool/main

# Wyczyść i wypełnij pool/main tylko unikalnymi pakietami
echo "📦 Preparing pool/main/ with unique packages..."
rm -f pool/main/*.deb

# Skopiuj tylko unikalne pakiety
declare -A unique_packages
find . -name "*.deb" -type f | while read deb_file; do
    filename=$(basename "$deb_file")
    pkg_name=$(echo "$filename" | cut -d'_' -f1)
    pkg_version=$(echo "$filename" | cut -d'_' -f2)
    
    # Klucz: nazwa+wersja
    key="${pkg_name}_${pkg_version}"
    
    if [ -z "${unique_packages[$key]}" ]; then
        cp "$deb_file" "pool/main/"
        unique_packages[$key]=$filename
        echo "✅ Added: $filename"
    else
        echo "⚠️  Skipped duplicate: $filename (already have: ${unique_packages[$key]})"
    fi
done

# Użyj dpkg-scanpackages
echo "📦 Creating Packages file..."
cd dists/stable/main/binary-amd64
> Packages
dpkg-scanpackages --multiversion ../../../../pool/main > Packages 2>/dev/null
gzip -9c Packages > Packages.gz
cd ../../../../

echo "✅ Repository created with $(ls -la pool/main/*.deb 2>/dev/null | wc -l) unique packages"