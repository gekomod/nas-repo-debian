#!/bin/bash
# create-simple-repo.sh - Poprawione generowanie pliku Packages

set -e

echo "🏗️ Creating properly structured repository..."

# Utwórz poprawną strukturę repozytorium Debian
mkdir -p dists/stable/main/binary-amd64
mkdir -p pool/main

# Skopiuj pakiety do pool/
echo "📦 Copying packages to pool/..."
find pool -name "*.deb" -exec cp {} pool/main/ \;

# UTWÓRZ POPRAWNY PLIK PACKAGES BEZ UŻYCIA dpkg-scanpackages
echo "📦 Creating CORRECT Packages file..."
cd dists/stable/main/binary-amd64

# Wyczyść stary plik Packages
> Packages

# Ręcznie utwórz poprawny plik Packages
for deb in ../../../../pool/main/*.deb; do
    if [ -f "$deb" ]; then
        filename=$(basename "$deb")
        pkg_name=$(echo "$filename" | cut -d'_' -f1)
        pkg_version=$(echo "$filename" | cut -d'_' -f2)
        pkg_arch=$(echo "$filename" | cut -d'_' -f3 | cut -d'.' -f1)
        
        echo "Package: $pkg_name" >> Packages
        echo "Version: $pkg_version" >> Packages
        echo "Architecture: $pkg_arch" >> Packages
        echo "Filename: pool/main/$filename" >> Packages
        echo "Size: $(stat -c%s "$deb")" >> Packages
        echo "SHA256: $(sha256sum "$deb" | cut -d' ' -f1)" >> Packages
        echo "MD5sum: $(md5sum "$deb" | cut -d' ' -f1)" >> Packages
        echo "Description: NAS Application" >> Packages
        echo "" >> Packages
        
        echo "✅ Added to Packages: $filename"
    fi
done

# Kompresuj
gzip -9c Packages > Packages.gz
cd ../../../../

echo "✅ Packages file created with correct paths"

# SPRAWDŹ CZY KLUCZ GPG JUŻ ISTNIEJE I GO UŻYJ LUB UTWÓRZ NOWY
echo "🔐 Setting up GPG signing..."

if [ -f "KEY.gpg" ] && [ -f "private.key" ]; then
    echo "✅ Using existing GPG key..."
    # Importuj istniejący klucz prywatny
    gpg --import private.key >/dev/null 2>&1
    KEY_ID=$(gpg --list-keys --with-colons | grep '^fpr:' | head -1 | cut -d':' -f10)
    echo "🔑 Using existing key ID: $KEY_ID"
else
    echo "🔑 Generating new GPG key..."
    gpg --batch --passphrase '' --quick-gen-key "NAS Repository <nas-repo@example.com>" rsa4096 default never
    
    # Eksportuj klucze
    KEY_ID=$(gpg --list-keys --with-colons | grep '^fpr:' | head -1 | cut -d':' -f10)
    gpg --armor --export "$KEY_ID" > KEY.gpg
    gpg --export-secret-keys --armor "$KEY_ID" > private.key
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

echo "✅ Repository created successfully!"
echo "📁 KEY.gpg: $(ls -la KEY.gpg)"
echo "🔑 Key ID: $KEY_ID"
