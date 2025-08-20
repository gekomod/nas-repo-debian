# 🏗️ NAS Debian Repository

Repozytorium Debian dla pakietów NAS: `nas-panel`, `nas-webserver`, i innych.

## 📦 Dostępne pakiety

- `nas-panel` - Panel zarządzania NAS
- `nas-webserver` - Serwer WWW dla NAS
- `nas-tools` - Narzędzia systemowe

## 🚀 Szybka instalacja

```bash
# Dodaj repozytorium
curl -sSL https://raw.githubusercontent.com/twojusername/nas-repo-debian/main/install-repo.sh | sudo bash

# Zainstaluj pakiety
sudo apt-get update
sudo apt-get install nas-panel nas-webserver
```

## 🔧 Ręczna instalacja repozytorium

```bash
# Dodaj klucz GPG
wget -qO - https://github.com/twojusername/nas-repo-debian/raw/main/KEY.gpg | sudo apt-key add -

# Dodaj źródło
echo "deb [arch=amd64] https://github.com/twojusername/nas-repo-debian/raw/main/ stable main" | \
sudo tee /etc/apt/sources.list.d/nas-repo.list

# Aktualizuj i instaluj
sudo apt-get update
sudo apt-get install nas-panel
```

## 🛠️ Dla developerów

### Dodawanie nowego pakietu

1. Zbuduj pakiet `.deb`
2. Użyj skryptu: `./scripts/add-package.sh package.deb`
3. Zaktualizuj repozytorium: `./scripts/update-repo.sh`

### Lokalne testowanie

```bash
# Skonfiguruj repozytorium
./scripts/setup-repo.sh

# Dodaj pakiety testowe
./scripts/add-package.sh test-package.deb

# Przetestuj
echo "deb [trusted=yes] file:$(pwd) stable main" | sudo tee /etc/apt/sources.list.d/nas-test.list
sudo apt-get update
sudo apt-get install test-package
```

## 📁 Struktura repozytorium

```
dists/stable/main/binary-amd64/  # Metadane
pool/main/                       # Pakiety .deb
scripts/                         # Narzędzia
.github/workflows/               # Automatyzacja
```

## 🔒 Bezpieczeństwo

Repozytorium jest podpisane kluczem GPG. Klucz publiczny znajduje się w `KEY.gpg`.
