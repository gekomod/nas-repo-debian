#!/bin/bash
# create-simple-repo.sh - Tworzenie repozytorium z podpisem GPG i KEY.gpg

set -e

echo "🏗️ Creating signed repository structure..."

# Utwórz podstawową strukturę
mkdir -p dists/stable/main/binary-amd64

# Skopiuj wszystkie pakiety
echo "📦 Copying packages..."
find pool -name "*.deb" -exec cp {} dists/stable/main/binary-amd64/ \;

# Wejdź do katalogu z pakietami
cd dists/stable/main/binary-amd64

# Usuń duplikaty - zostaw tylko najnowsze wersje
echo "🔍 Removing duplicate packages..."
for pkg in $(ls *.deb 2>/dev/null | cut -d'_' -f1 | sort -u); do
    latest=$(ls ${pkg}_*.deb 2>/dev/null | sort -V | tail -n1)
    if [ -n "$latest" ]; then
        echo "✅ Keeping latest: $latest"
        for file in ${pkg}_*.deb; do
            if [ "$file" != "$latest" ]; then
                echo "🗑️ Removing old: $file"
                rm "$file"
            fi
        done
    fi
done

# Utwórz plik override
echo "📋 Creating override file..."
cat > /tmp/override << EOF
nas-panel optional main
nas-web optional main
EOF

# Utwórz Packages
echo "📦 Creating Packages file..."
if command -v dpkg-scanpackages >/dev/null 2>&1; then
    dpkg-scanpackages . /tmp/override > Packages 2>/dev/null || true
    gzip -9c Packages > Packages.gz
else
    echo "⚠️ dpkg-scanpackages not available, creating basic Packages file"
    for deb in *.deb; do
        echo "Package: $(echo $deb | cut -d'_' -f1)" >> Packages
        echo "Filename: ./$deb" >> Packages
        echo "Size: $(stat -c%s "$deb")" >> Packages
        echo "" >> Packages
    done
    gzip -9c Packages > Packages.gz
fi

# Wróć do roota repozytorium
cd ../../../../

# GENERUJ KLUCZ GPG JEŚLI NIE ISTNIEJE
echo "🔐 Setting up GPG signing..."
if [ ! -f "KEY.gpg" ]; then
    echo "🔑 Generating new GPG key..."
    cat > /tmp/gpg-gen << EOF
Key-Type: RSA
Key-Length: 4096
Name-Real: NAS Repository
Name-Email: nas-repo@users.noreply.github.com
Expire-Date: 0
%no-protection
%commit
EOF
    gpg --batch --generate-key /tmp/gpg-gen
    rm /tmp/gpg-gen
    
    # Eksportuj klucz publiczny
    KEY_ID=$(gpg --list-keys --with-colons | grep '^fpr:' | head -1 | cut -d':' -f10)
    gpg --armor --export "$KEY_ID" > KEY.gpg
    echo "✅ Generated GPG key: $KEY_ID"
else
    echo "✅ Using existing GPG key"
    gpg --import KEY.gpg
    KEY_ID=$(gpg --list-keys --with-colons | grep '^fpr:' | head -1 | cut -d':' -f10)
fi

# Trust the key
echo "$KEY_ID:6:" | gpg --import-ownertrust

# Utwórz plik Release
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
    apt-ftparchive release dists/stable/ >> dists/stable/Release 2>/dev/null || \
    echo "⚠️ apt-ftparchive failed, using basic Release"
else
    echo "⚠️ apt-ftparchive not available, using basic Release"
fi

# PODPISZ REPOZYTORIUM
echo "🔏 Signing repository..."
cd dists/stable
gpg --default-key "$KEY_ID" -abs -o Release.gpg Release
gpg --default-key "$KEY_ID" --clearsign -o InRelease Release
cd ../..

# ✅ DODAJ KEY.GPG DO GŁÓWNEGO KATALOGU REPOZYTORIUM
echo "📁 Adding KEY.gpg to repository root..."
cp KEY.gpg ./

# ✅ DODAJ INSTRUKCJĘ INSTALACJI
echo "📝 Adding installation instructions..."
cat > INSTALL.md << EOF
# 📦 NAS Repository Installation

## 🔐 Add GPG Key
\`\`\`bash
wget -qO - https://$(git config --get remote.origin.url | cut -d'/' -f4-5 | cut -d'.' -f1)/raw/main/KEY.gpg | sudo apt-key add -
\`\`\`

## 📁 Add Repository
\`\`\`bash
echo "deb [arch=amd64] https://$(git config --get remote.origin.url | cut -d'/' -f4-5 | cut -d'.' -f1)/raw/main/ stable main" | sudo tee /etc/apt/sources.list.d/nas-repo.list
\`\`\`

## 🔄 Update & Install
\`\`\`bash
sudo apt update
sudo apt install nas-panel nas-web
\`\`\`
EOF

echo "✅ Signed repository created successfully!"
echo "🔑 GPG Key ID: $KEY_ID"
echo "📁 KEY.gpg added to repository root"
