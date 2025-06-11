#!/bin/bash

# =====================================
# INSTALL XRDP + XFCE
# Supports:
# Ubuntu 20.04 - 24.10
# Debian 10 - 12
# =====================================

set -e

# Detect OS from /etc/os-release
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    VERSION=$VERSION_ID
else
    echo "Unable to detect OS. Exiting."
    exit 1
fi

echo "Detected OS: $OS $VERSION"

# Update system
# Periksa apakah sudo terinstal
if ! command -v sudo &> /dev/null; then
    echo "sudo tidak ditemukan. Menginstal sudo..."
    # Jika tidak ada sudo, instal sudo
    apt update && apt install -y sudo
else
    echo "sudo sudah terinstal."
fi

# Coba jalankan perintah update dengan sudo jika sudo terinstal
echo "[1/7] Updating system..."
sudo apt update && sudo apt upgrade -y

# Install desktop environment and xrdp
echo "[2/7] Installing XFCE desktop and xRDP..."
sudo apt install -y xrdp xfce4 xfce4-goodies

# Extra packages for Debian (especially for clean installs)
if [[ "$OS" == "debian" ]]; then
    echo "[2a] Installing Debian extras..."
    sudo apt install -y task-xfce-desktop dbus-x11 policykit-1
fi

# Configure session
echo "[3/7] Configuring session..."
echo "startxfce4" > ~/.xsession
echo "startxfce4" > ~/.xinitrc
sudo cp ~/.xsession /etc/skel/

# Special fix for Debian: xrdp startwm.sh modification
if [[ "$OS" == "debian" ]]; then
    echo "[3a] Patching /etc/xrdp/startwm.sh for Debian..."
    sudo sed -i.bak '/^test -x \/etc\/X11\/Xsession/ a startxfce4' /etc/xrdp/startwm.sh
fi

# Add xrdp user to ssl-cert group
echo "[4/7] Adding xrdp user to ssl-cert group..."
sudo adduser xrdp ssl-cert

# Enable and restart xrdp
echo "[5/7] Enabling and restarting XRDP..."
sudo systemctl enable xrdp
sudo systemctl restart xrdp

# Allow RDP port through firewall if UFW is active
echo "[6/7] Checking and allowing port 3389 (RDP)..."
if command -v ufw &> /dev/null && sudo ufw status | grep -q "Status: active"; then
    sudo ufw allow 3389
    echo "Firewall updated (UFW): Port 3389 allowed."
else
    echo "UFW not active or not installed. Skipping firewall rule."
fi

# Show service status
echo "[7/7] Verifying XRDP service status..."
sudo systemctl status xrdp --no-pager

echo ""
echo "✅ XRDP + XFCE successfully installed and configured on $OS $VERSION"
echo "➡️ Connect via RDP to this machine using its IP address (port 3389)"

# Mengatur username XRDP, misalnya root
username="root"

# Menampilkan username yang digunakan untuk XRDP
read -sp "Username untuk XRDP adalah : " username
echo

# Meminta input password baru untuk user XRDP
read -sp "Masukkan password baru untuk : " new_password
echo

# Mengubah password user XRDP
echo "$username:$new_password" | sudo chpasswd

# Memastikan password telah diperbarui
if [ $? -eq 0 ]; then
    echo "Password untuk $username telah berhasil diperbarui."
else
    echo "Terjadi kesalahan saat memperbarui password."
    exit 1
fi
# Mendapatkan IP publik VPS
IP="$(curl -s ifconfig.me)"

# Informasi koneksi RDP
echo -e "\nUntuk mengakses RDP:"
echo "1. Gunakan Login RDP : $IP:3389"
echo "2. Gunakan Username : $username"
echo "3. Gunakan Password : $new_password"
