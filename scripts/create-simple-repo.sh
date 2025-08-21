#!/bin/bash
# create-simple-repo.sh - Poprawione generowanie pliku Packages bez duplikatów

set -e

echo "🏗️ Creating properly structured repository..."

# Utwórz poprawną strukturę repozytorium Debian
mkdir -p dists/stable/main/binary-amd64
mkdir -p pool/main

# Wyczyść pool/main przed kopiowaniem
echo "🧹 Cleaning pool/main/..."
rm -f pool/main/*.deb

# Skopiuj pakiety do pool/ BEZ DUPLIKATÓW
echo "📦 Copying packages to pool/..."
# Znajdź wszystkie pakiety .deb i skopiuj UNIKALNE do pool/main/
find . -name "*.deb" -type f | while read deb_file; do
    filename=$(basename "$deb_file")
    # Sprawdź czy pakiet już nie istnieje w pool/main/
    if [ ! -f "pool/main/$filename" ]; then
        cp "$deb_file" "pool/main/"
        echo "✅ Copied: $filename"
    else
        echo "⚠️  Skipped (already exists): $filename"
    fi
done

# UŻYJ dpkg-scanpackages ZAMIAST RĘCZNEGO TWORZENIA!
echo "📦 Creating CORRECT Packages file using dpkg-scanpackages..."

# Zainstaluj required tools
sudo apt-get update
sudo apt-get install -y dpkg-dev

# Utwórz poprawny plik Packages z wszystkimi polami
cd dists/stable/main/binary-amd64

# Wyczyść stary plik Packages
rm -fr Packages

# Użyj dpkg-scanpackages aby poprawnie wygenerować plik Packages
# Użyj --multiversion i przekieruj output do pliku
dpkg-scanpackages --multiversion ../../../../pool/main > Packages 2>/dev/null



# Kompresuj
gzip -9c Packages > Packages.gz
cd ../../../../

echo "✅ Packages file created with $(grep -c "^Package:" dists/stable/main/binary-amd64/Packages) unique packages"

# Pobierz KEY_ID ze zmiennej środowiskowej (ustawionej w workflow)
KEY_ID=${KEY_ID:-}
if [ -z "$KEY_ID" ]; then
    KEY_ID=$(gpg --list-keys --with-colons | grep '^fpr:' | head -1 | cut -d':' -f10)
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

# Dodaj hashe do Release
echo "MD5Sum:" >> Release
echo " $(md5sum main/binary-amd64/Packages.gz | cut -d' ' -f1) $(stat -c%s main/binary-amd64/Packages.gz) main/binary-amd64/Packages.gz" >> Release

echo "SHA256:" >> Release
echo " $(sha256sum main/binary-amd64/Packages.gz | cut -d' ' -f1) $(stat -c%s main/binary-amd64/Packages.gz) main/binary-amd64/Packages.gz" >> Release

# Podpisz repozytorium
echo "🔏 Signing repository..."
gpg --default-key "$KEY_ID" -abs -o Release.gpg Release
gpg --default-key "$KEY_ID" --clearsign -o InRelease Release

cd ../../

echo "✅ Repository created and signed successfully!"