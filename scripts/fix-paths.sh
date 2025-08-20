#!/bin/bash
# fix-paths.sh - Naprawia ścieżki w pliku Packages

set -e

echo "🔧 Fixing paths in Packages file..."

cd dists/stable/main/binary-amd64

if [ -f "Packages" ]; then
    echo "📝 Correcting paths in Packages..."
    # Napraw wszystkie złe ścieżki
    sed -i 's|Filename: \.\./\.\./\.\./\.\./pool/main/|Filename: pool/main/|g' Packages
    sed -i 's|Filename: \./|Filename: pool/main/|g' Packages
    sed -i 's|Filename: [^/]*/|Filename: pool/main/|g' Packages
    
    # Przekompresuj
    gzip -9c Packages > Packages.gz
    
    echo "✅ Packages file fixed"
    
    # Pokaż poprawione ścieżki
    echo "🔍 Correct paths:"
    grep "Filename:" Packages | head -5
else
    echo "❌ Packages file not found"
    exit 1
fi

cd ../../../../

# Odśwież hashe w Release
echo "🔄 Updating Release file hashes..."
cd dists/stable
> Release  # Wyczyść stary plik

cat >> Release << EOF
Origin: NAS Repository
Label: NAS Debian Repository
Suite: stable
Codename: stable
Architectures: amd64
Components: main
Description: Repository for NAS applications
Date: $(date -Ru)
EOF

# Dodaj poprawne hashe
echo "MD5Sum:" >> Release
echo " $(md5sum main/binary-amd64/Packages.gz | cut -d' ' -f1) $(stat -c%s main/binary-amd64/Packages.gz) main/binary-amd64/Packages.gz" >> Release
echo "SHA256:" >> Release
echo " $(sha256sum main/binary-amd64/Packages.gz | cut -d' ' -f1) $(stat -c%s main/binary-amd64/Packages.gz) main/binary-amd64/Packages.gz" >> Release

# Podpisz ponownie
gpg --clearsign -o InRelease Release
gpg -abs -o Release.gpg Release

cd ../..
echo "✅ Repository paths fixed successfully!"
