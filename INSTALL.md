# 📦 NAS Repository Installation

## 🔐 Add GPG Key
```bash
wget -qO - https://RAW_URL_HERE/KEY.gpg | sudo apt-key add -
```

## 📁 Add Repository
```bash
echo "deb [arch=amd64] https://REPO_URL_HERE/ stable main" | sudo tee /etc/apt/sources.list.d/nas-repo.list
```

## 🔄 Update & Install
```bash
sudo apt update
sudo apt install nas-panel nas-web
```

## 🔑 GPG Key ID: CF10B1853C65878D76C198C5B3213B55C9286B62
