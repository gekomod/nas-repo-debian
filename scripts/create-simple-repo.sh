#!/bin/bash
# create-simple-repo.sh - Ręczne tworzenie POPRAWNEGO pliku Packages

set -e

echo "🏗️ Creating properly structured repository..."

# Utwórz poprawną strukturę repozytorium Debian
mkdir -p dists/stable/main/binary-amd64
mkdir -p pool/main

# Skopiuj pakiety do pool/
echo "📦 Copying packages to pool/..."
find pool -name "*.deb" -exec cp {} pool/main/ \;

# UTWÓRZ POPRAWNY PLIK PACKAGES Z WSZYSTKIMI POLAMI
echo "📦 Creating CORRECT Packages file..."
cd dists/stable/main/binary-amd64

# Wyczyść stary plik Packages
> Packages

# Ręcznie utwórz POPRAWNY plik Packages dla WSZYSTKICH pakietów
for deb in ../../../../pool/main/*.deb; do
    if [ -f "$deb" ]; then
        filename=$(basename "$deb")
        
        # Ekstrahuj informacje z pakietu deb
        pkg_info=$(dpkg-deb -I "$deb")
        control_info=$(dpkg-deb -f "$deb")
        
        pkg_name=$(echo "$control_info" | grep "^Package:" | cut -d' ' -f2)
        pkg_version=$(echo "$control_info" | grep "^Version:" | cut -d' ' -f2)
        pkg_arch=$(echo "$control_info" | grep "^Architecture:" | cut -d' ' -f2)
        pkg_depends=$(echo "$control_info" | grep "^Depends:" | cut -d' ' -f2- || echo "")
        pkg_maintainer=$(echo "$control_info" | grep "^Maintainer:" | cut -d' ' -f2- || echo "Gekomod <zaba141@o2.pl>")
        pkg_description=$(echo "$control_info" | grep "^Description:" | cut -d' ' -f2- || echo "NAS Application")
        pkg_installed_size=$(echo "$control_info" | grep "^Installed-Size:" | cut -d' ' -f2 || echo "0")
        pkg_section=$(echo "$control_info" | grep "^Section:" | cut -d' ' -f2 || echo "web")
        pkg_priority=$(echo "$control_info" | grep "^Priority:" | cut -d' ' -f2 || echo "optional")
        pkg_homepage=$(echo "$control_info" | grep "^Homepage:" | cut -d' ' -f2- || echo "https://naspanel.site")
        
        # Zapisz wszystkie wymagane pola
        echo "Package: $pkg_name" >> Packages
        echo "Version: $pkg_version" >> Packages
        echo "Architecture: $pkg_arch" >> Packages
        echo "Maintainer: $pkg_maintainer" >> Packages
        echo "Installed-Size: $pkg_installed_size" >> Packages
        echo "Depends: $pkg_depends" >> Packages
        echo "Section: $pkg_section" >> Packages
        echo "Priority: $pkg_priority" >> Packages
        echo "Homepage: $pkg_homepage" >> Packages
        echo "Filename: pool/main/$filename" >> Packages
        echo "Size: $(stat -c%s "$deb")" >> Packages
        echo "SHA256: $(sha256sum "$deb" | cut -d' ' -f1)" >> Packages
        echo "MD5sum: $(md5sum "$deb" | cut -d' ' -f1)" >> Packages
        echo "Description: $pkg_description" >> Packages
        echo "" >> Packages
        
        echo "✅ Added to Packages: $filename"
    fi
done

# Kompresuj
gzip -9c Packages > Packages.gz
cd ../../../../

echo "✅ Packages file created with $(grep -c "^Package:" dists/stable/main/binary-amd64/Packages) packages"