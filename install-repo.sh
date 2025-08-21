#!/bin/bash
# install-repo.sh - Skrypt instalacji repozytorium dla użytkowników

set -e

REPO_URL="https://repo.naspanel.site"
TEMP_DIR=$(mktemp -d)

echo "📦 Instalacja repozytorium NAS..."

# Pobierz klucz GPG
wget -q "${REPO_URL}/KEY.gpg" -O "${TEMP_DIR}/nas-repo.gpg"
sudo apt-key add "${TEMP_DIR}/nas-repo.gpg"

# Dodaj źródło
echo "deb [arch=amd64] ${REPO_URL} stable main" | \
sudo tee /etc/apt/sources.list.d/nas-repo.list

# Aktualizuj listę pakietów
sudo apt-get update

echo "✅ Repozytorium dodane!"
echo "📦 Dostępne pakiety:"
apt-cache search nas- | grep ^nas-

rm -rf "${TEMP_DIR}"
