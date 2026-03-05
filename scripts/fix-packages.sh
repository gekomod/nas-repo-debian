#!/bin/bash
# fix-packages.sh - Naprawia błędne ścieżki w pliku Packages

set -e

echo "🔧 Fixing Packages file..."

cd dists/stable/main/binary-amd64

if [ -f "Packages" ]; then
    echo "📝 Correcting paths in Packages..."
    
    # Napraw WSZYSTKIE błędne ścieżki
    sed -i 's|Filename: \.\./\.\./\.\./\.\./pool/main/|Filename: pool/main/|g' Packages
    sed -i 's|Filename: \.\./\.\./\.\./pool/main/|Filename: pool/main/|g' Packages
    sed -i 's|Filename: \.\./\.\./pool/main/|Filename: pool/main/|g' Packages
    sed -i 's|Filename: \.\./pool/main/|Filename: pool/main/|g' Packages
    sed -i 's|Filename: \./pool/main/|Filename: pool/main/|g' Packages
    sed -i 's|Filename: [^/]*/\.\./|Filename: pool/main/|g' Packages
    
    # Usuń wszystkie ścieżki względne
    sed -i 's|Filename: \.\.*/|Filename: pool/main/|g' Packages
    
    # Upewnij się że wszystkie ścieżki zaczynają się od pool/main/
    sed -i '/^Filename:/ s| [^ ]*/| pool/main/|' Packages
    
    # Przekompresuj
    gzip -9c Packages > Packages.gz
    
    echo "✅ Packages file fixed"
    
    # Pokaż poprawione ścieżki
    echo "🔍 Correct paths in Packages:"
    grep "^Filename:" Packages | head -10
else
    echo "❌ Packages file not found"
    # Utwórz nowy plik Packages
    create-correct-packages
fi

cd ../../../
