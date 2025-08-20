#!/bin/bash
# create-simple-repo.sh - Poprawione repozytorium z właściwymi ścieżkami

set -e

echo "🏗️ Creating properly structured repository..."

# Utwórz poprawną strukturę repozytorium Debian
mkdir -p dists/stable/main/binary-amd64
mkdir -p pool/main

# Przenieś pakiety do pool/ (zgodnie ze standardem Debian)
echo "📦 Moving packages to pool/..."
find pool -name "*.deb" -exec cp {} pool/main/ \;

# Wejdź do katalogu i utwórz Packages z poprawnymi ścieżkami
cd dists/stable/main/binary-amd64

echo "📦 Creating Packages file with correct paths..."
if command -v dpkg-scanpackages >/dev/null 2>&1; then
    # Użyj poprawnej ścieżki do pool
    dpkg-scanpackages ../../../../pool/main /dev/null > Packages 2>/dev/null || true
    gzip -9c Packages > Packages.gz
else
    # Ręczne tworzenie Packages z POPRAWNYMI ścieżkami
    for deb in ../../../../pool/main/*.deb; do
        filename=$(basename "$deb")
        pkg_name=$(echo "$filename" | cut -d'_' -f1)
        pkg_version=$(echo "$filename" | cut -d'_' -f2)
        pkg_arch=$(echo "$filename" | cut -d'_' -f3 | cut -d'.' -f1)
        
        echo "Package: $pkg_name" >> Packages
        echo "Version: $pkg_version" >> Packages
        echo "Architecture: $pkg_arch" >> Packages
        echo "Filename: pool/main/$filename" >> Packages  # POPRAWNA ŚCIEŻKA!
        echo "Size: $(stat -c%s "$deb")" >> Packages
        echo "SHA256: $(sha256sum "$deb" | cut -d' ' -f1)" >> Packages
        echo "" >> Packages
    done
    gzip -9c Packages > Packages.gz
fi

# Wróć do roota
cd ../../../../

# Generuj klucz GPG jeśli nie istnieje
if [ ! -f "KEY.gpg" ]; then
    echo "🔑 Generating GPG key..."
    cat > /tmp/gpg-gen << EOF
Key-Type: RSA
Key-Length: 4096
Name-Real: NAS Repository
Name-Email: nas-repo@example.com
Expire-Date: 0
%no-protection
%commit
EOF
    gpg --batch --generate-key /tmp/gpg-gen
    rm /tmp/gpg-gen
    gpg --armor --export > KEY.gpg
fi

# Utwórz Release z poprawnymi hashami
echo "📄 Creating Release file..."
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

# Dodaj hashe do Release
if command -v apt-ftparchive >/dev/null 2>&1; then
    apt-ftparchive release dists/stable/ >> dists/stable/Release
else
    # Ręczne dodanie hashów
    cd dists/stable
    echo "MD5Sum:" >> Release
    echo " $(md5sum Packages.gz | cut -d' ' -f1) $(stat -c%s Packages.gz) main/binary-amd64/Packages.gz" >> Release
    echo " $(md5sum Packages | cut -d' ' -f1) $(stat -c%s Packages) main/binary-amd64/Packages" >> Release
    echo "SHA256:" >> Release
    echo " $(sha256sum Packages.gz | cut -d' ' -f1) $(stat -c%s Packages.gz) main/binary-amd64/Packages.gz" >> Release
    echo " $(sha256sum Packages | cut -d' ' -f1) $(stat -c%s Packages) main/binary-amd64/Packages" >> Release
    cd ../..
fi

# Podpisz repozytorium
echo "🔏 Signing repository..."
cd dists/stable
gpg --default-key "$(gpg --list-keys --with-colons | grep '^fpr:' | head -1 | cut -d':' -f10)" -abs -o Release.gpg Release
gpg --clearsign -o InRelease Release
cd ../..


# ✅ DODAJ INSTRUKCJĘ INSTALACJI (KEY.gpg już jest w root)
echo "📝 Adding installation instructions..."
cat > INSTALL.md << EOF
# 📦 NAS Repository Installation

## 🔐 Add GPG Key
\`\`\`bash
wget -qO - https://repo.naspanel.site/KEY.gpg | sudo apt-key add -
\`\`\`

## 📁 Add Repository
\`\`\`bash
echo "deb [arch=amd64] https://repo.naspanel.site/ stable main" | sudo tee /etc/apt/sources.list.d/nas-repo.list
\`\`\`

## 🔄 Update & Install
\`\`\`bash
sudo apt update
sudo apt install nas-panel nas-web
\`\`\`

## 🔑 GPG Key ID: $KEY_ID
EOF

echo "✅ Signed repository created successfully!"
echo "🔑 GPG Key ID: $KEY_ID"
echo "📁 KEY.gpg is in repository root"
