#!/bin/bash
# create-simple-repo.sh - Poprawione generowanie pliku Packages z wszystkimi polami

set -e

echo "🏗️ Creating properly structured repository..."

# Utwórz poprawną strukturę repozytorium Debian
mkdir -p dists/stable/main/binary-amd64
mkdir -p pool/main

# Skopiuj pakiety do pool/
echo "📦 Copying packages to pool/..."
find pool -name "*.deb" -exec cp {} pool/main/ \;
find . -name "*.deb" -exec cp {} pool/main/ 2>/dev/null \; || true

# UŻYJ dpkg-scanpackages ZAMIAST RĘCZNEGO TWORZENIA!
echo "📦 Creating CORRECT Packages file using dpkg-scanpackages..."

# Zainstaluj required tools
sudo apt-get update
sudo apt-get install -y dpkg-dev

# Utwórz poprawny plik Packages z wszystkimi polami
cd dists/stable/main/binary-amd64

# Wyczyść stary plik Packages
> Packages

# Użyj dpkg-scanpackages aby poprawnie wygenerować plik Packages
dpkg-scanpackages --multiversion ../../../../pool/main > Packages

# Kompresuj
gzip -9c Packages > Packages.gz
cd ../../../../

echo "✅ Packages file created with $(grep -c "^Package:" dists/stable/main/binary-amd64/Packages) packages"

# Pobierz KEY_ID ze zmiennej środowiskowej (ustawionej w workflow)
KEY_ID=${KEY_ID:-}
if [ -z "$KEY_ID" ]; then
    KEY_ID=$(gpg --list-keys --with-colons | grep '^fpr:' | head -1 | cut -d':' -f10);
fi

echo "🔐 Using GPG key ID: $KEY_ID"

# Utwórz Release z poprawnymi hashami
echo "📄 Creating Release file..."
cd dists/stable

cat > Release << EOF
Origin: NAS Repository
Label: NAS Debian Repository
Suite: stable
Codename: stable
Architectures: amd64
Components: main
Description: Repository for NAS applications
Date: $(date -Ru)
EOF


echo "MD5Sum:" >> Release

find . -type f -name Packages* -o -name Release* | while read file; do
    size=$(stat -c%s "$file")
    echo " $(md5sum "$file" | cut -d' ' -f1) $size $(echo "$file" | sed 's|^\./||')" >> Release
done

echo "SHA256:" >> Release
find . -type f -name Packages* -o -name Release* | while read file; do
    size=$(stat -c%s "$file")
    echo " $(sha256sum "$file" | cut -d' ' -f1) $size $(echo "$file" | sed 's|^\./||')" >> Release
done

# Podpisz repozytorium
echo "🔏 Signing repository..."

gpg --default-key "$KEY_ID" -abs -o Release.gpg Release
gpg --default-key "$KEY_ID" --clearsign -o InRelease Release

cd ../../

echo "✅ Repository created and signed successfully!"