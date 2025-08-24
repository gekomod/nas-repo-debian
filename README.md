# 🏗️ NAS Debian Repository

Repozytorium Debian dla pakietów NAS: `nas-panel`, `nas-web`, i innych.

## 📦 Dostępne pakiety

- `nas-panel` - Panel zarządzania NAS
- `nas-web` - Serwer WWW dla NAS

## 🚀 Szybka instalacja

```bash
# Dodaj repozytorium
curl -sSL https://repo.naspanel.site/install-repo.sh | sudo bash

# Zainstaluj pakiety
sudo apt-get update
sudo apt-get install nas-panel nas-web
```

## 🔧 Ręczna instalacja repozytorium

```bash
# Dodaj klucz GPG
sudo wget -qO - https://repo.naspanel.site/KEY.gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/nas-repo.gpg

# Dodaj źródło
echo "deb [arch=amd64 signed-by=/etc/apt/trusted.gpg.d/nas-repo.gpg] https://repo.naspanel.site/ stable main" | sudo tee /etc/apt/sources.list.d/nas-repo.list

# Aktualizuj i instaluj
sudo apt-get update
sudo apt-get install nas-panel
```

## 🔒 Bezpieczeństwo

Repozytorium jest podpisane kluczem GPG. Klucz publiczny znajduje się w `KEY.gpg`.
