#!/bin/bash
# create-simple-repo.sh - Tworzenie prostego repozytorium bez reprepro

set -e

echo "🏗️ Creating simple repository structure..."

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
    # Znajdź najnowszą wersję pakietu
    latest=$(ls ${pkg}_*.deb 2>/dev/null | sort -V | tail -n1)
    if [ -n "$latest" ]; then
        echo "✅ Keeping latest: $latest"
        
        # Usuń starsze wersje
        for file in ${pkg}_*.deb; do
            if [ "$file" != "$latest" ]; then
                echo "🗑️ Removing old: $file"
                rm "$file"
            fi
        done
    fi
done

# Utwórz plik override dla dpkg-scanpackages
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
        pkg_name=$(echo $deb | cut -d'_' -f1)
        pkg_version=$(echo $deb | cut -d'_' -f2)
        pkg_arch=$(echo $deb | cut -d'_' -f3 | cut -d'.' -f1)
        
        echo "Package: $pkg_name" >> Packages
        echo "Version: $pkg_version" >> Packages
        echo "Architecture: $pkg_arch" >> Packages
        echo "Filename: ./$deb" >> Packages
        echo "" >> Packages
    done
    gzip -9c Packages > Packages.gz
fi

# Wróć do roota repozytorium
cd ../../../../

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

# Dodaj hashe do Release jeśli apt-ftparchive jest dostępny
if command -v apt-ftparchive >/dev/null 2>&1; then
    apt-ftparchive release dists/stable/ >> dists/stable/Release 2>/dev/null || \
    echo "⚠️ apt-ftparchive failed, using basic Release file"
else
    echo "⚠️ apt-ftparchive not available, using basic Release file"
fi

echo "✅ Simple repository created successfully"
