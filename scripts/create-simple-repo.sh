#!/bin/bash
# create-simple-repo.sh - Tworzenie repozytorium z inteligentnym zarządzaniem kluczami GPG

set -e

echo "🏗️ Creating properly structured repository..."

# Utwórz poprawną strukturę repozytorium Debian
mkdir -p dists/stable/main/binary-amd64
mkdir -p pool/main

# Przenieś pakiety do pool/ (zgodnie ze standardem Debian)
echo "📦 Moving packages to pool/..."
find pool -name "*.deb" -exec cp {} pool/main/ \;

# Wejdź do katalogu i utwórz Packages z POPRAWNYMI ścieżkami
echo "📦 Creating Packages file with CORRECT paths..."
if command -v dpkg-scanpackages >/dev/null 2>&1; then
    # Użyj dpkg-scanpackages z właściwym katalogiem bazowym
    cd pool/main
    dpkg-scanpackages . /dev/null > ../../../../dists/stable/main/binary-amd64/Packages 2>/dev/null
    cd ../../../../dists/stable/main/binary-amd64
    gzip -9c Packages > Packages.gz
    cd ../../../../
else
    # Ręczne tworzenie Packages z ABSOLUTNIE POPRAWNYMI ścieżkami
    cd dists/stable/main/binary-amd64
    for deb in ../../../../pool/main/*.deb; do
        filename=$(basename "$deb")
        pkg_name=$(echo "$filename" | cut -d'_' -f1)
        pkg_version=$(echo "$filename" | cut -d'_' -f2)
        pkg_arch=$(echo "$filename" | cut -d'_' -f3 | cut -d'.' -f1)
        
        echo "Package: $pkg_name" >> Packages
        echo "Version: $pkg_version" >> Packages
        echo "Architecture: $pkg_arch" >> Packages
        echo "Filename: pool/main/$filename" >> Packages  # PRAWIDŁOWA ŚCIEŻKA!
        echo "Size: $(stat -c%s "../../../../pool/main/$filename")" >> Packages
        echo "SHA256: $(sha256sum "../../../../pool/main/$filename" | cut -d' ' -f1)" >> Packages
        echo "" >> Packages
    done
    gzip -9c Packages > Packages.gz
    cd ../../../
fi

# SPRAWDŹ CZY KLUCZ GPG JUŻ ISTNIEJE I GO UŻYJ LUB UTWÓRZ NOWY
echo "🔐 Setting up GPG signing..."

if [ -f "KEY.gpg" ]; then
    echo "✅ Using existing GPG key: KEY.gpg"
    # Importuj istniejący klucz
    gpg --import KEY.gpg >/dev/null 2>&1
    KEY_ID=$(gpg --list-keys --with-colons | grep '^fpr:' | head -1 | cut -d':' -f10)
    echo "🔑 Using existing key ID: $KEY_ID"
else
    echo "🔑 Generating new GPG key..."
    # Generuj nowy klucz
    cat > /tmp/gpg-gen.conf << EOF
Key-Type: RSA
Key-Length: 4096
Name-Real: NAS Repository
Name-Email: nas-repo@example.com
Expire-Date: 0
%no-protection
%commit
EOF
    
    gpg --batch --generate-key /tmp/gpg-gen.conf
    rm /tmp/gpg-gen.conf
    
    # Eksportuj klucz publiczny
    KEY_ID=$(gpg --list-keys --with-colons | grep '^fpr:' | head -1 | cut -d':' -f10)
    gpg --armor --export "$KEY_ID" > KEY.gpg
    echo "✅ Generated new GPG key: $KEY_ID"
fi

# Trust the key
echo "$KEY_ID:6:" | gpg --import-ownertrust

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
cd dists/stable
echo "MD5Sum:" >> Release
echo " $(md5sum main/binary-amd64/Packages.gz | cut -d' ' -f1) $(stat -c%s main/binary-amd64/Packages.gz) main/binary-amd64/Packages.gz" >> Release
echo "SHA256:" >> Release
echo " $(sha256sum main/binary-amd64/Packages.gz | cut -d' ' -f1) $(stat -c%s main/binary-amd64/Packages.gz) main/binary-amd64/Packages.gz" >> Release
cd ../..

# Podpisz repozytorium
echo "🔏 Signing repository..."
cd dists/stable
gpg --default-key "$KEY_ID" -abs -o Release.gpg Release
gpg --default-key "$KEY_ID" --clearsign -o InRelease Release
cd ../..

# Utwórz instrukcję instalacji
echo "📝 Creating installation instructions..."
cat > INSTALL.md << EOF
# 📦 NAS Repository Installation

## 🔐 Add GPG Key
\`\`\`bash
wget -qO - https://DOMAIN/KEY.gpg | sudo apt-key add -
\`\`\`

## 📁 Add Repository
\`\`\`bash
echo "deb [arch=amd64] https://DOMAIN/ stable main" | sudo tee /etc/apt/sources.list.d/nas-repo.list
\`\`\`

## 🔄 Update & Install
\`\`\`bash
sudo apt update
sudo apt install nas-panel nas-web
\`\`\`

## 🔑 GPG Key ID: $KEY_ID
EOF

echo "✅ Repository created successfully!"
echo "📁 KEY.gpg: $(ls -la KEY.gpg)"
echo "🔑 Key ID: $KEY_ID"
