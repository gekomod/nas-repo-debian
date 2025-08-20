#!/bin/bash
# clean-duplicates.sh - Usuwa duplikaty pakietów, zostawia tylko najnowsze wersje

set -e

echo "🧹 Cleaning duplicate packages..."

find pool -type f -name "*.deb" | while read deb_file; do
    pkg_name=$(basename "$deb_file" | cut -d'_' -f1)
    pkg_dir=$(dirname "$deb_file")
    
    # Znajdź wszystkie wersje tego pakietu
    all_versions=$(find "$pkg_dir" -name "${pkg_name}_*.deb" -exec basename {} \; | sort -V)
    
    if [ $(echo "$all_versions" | wc -l) -gt 1 ]; then
        echo "📦 Package: $pkg_name"
        echo "   All versions: $all_versions"
        
        # Zostaw tylko najnowszą wersję
        latest_version=$(echo "$all_versions" | tail -n1)
        echo "   Keeping: $latest_version"
        
        # Usuń starsze wersje
        for version in $all_versions; do
            if [ "$version" != "$latest_version" ]; then
                echo "   🗑️ Removing: $version"
                rm "${pkg_dir}/${version}"
            fi
        done
        echo ""
    fi
done

echo "✅ Duplicate cleanup completed"
