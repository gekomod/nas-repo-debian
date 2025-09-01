#!/bin/bash

set -e

REPO_URL="https://repo.naspanel.site"
TEMP_DIR=$(mktemp -d)

echo "📦 Instalacja repozytorium NAS..."

# Pobierz klucz GPG
sudo wget -qO - "${REPO_URL}/KEY.gpg" | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/nas-repo.gpg

# Dodaj źródło
echo "deb [arch=amd64 signed-by=/etc/apt/trusted.gpg.d/nas-repo.gpg] ${REPO_URL} stable main" | sudo tee /etc/apt/sources.list.d/nas-repo.list

# Aktualizuj listę pakietów
sudo apt-get update

echo "✅ Repozytorium dodane!"
echo "📦 Dostępne pakiety:"
apt-cache search nas- | grep ^nas-

rm -rf "${TEMP_DIR}"
