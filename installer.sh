#!/data/data/com.termux/files/usr/bin/bash

# Warna untuk output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Fungsi untuk menampilkan pesan
msg() {
    echo -e "${GREEN}[*] $1${NC}"
}

error() {
    echo -e "${RED}[!] $1${NC}"
}

# Periksa akses root
if [ "$(id -u)" = "0" ]; then
    error "Jangan jalankan script ini sebagai root!"
    exit 1
fi

# Update dan upgrade Termux
msg "Mengupdate dan mengupgrade Termux..."
pkg update -y && pkg upgrade -y

# Install paket dasar
msg "Menginstall paket dasar..."
pkg install git wget curl nano zsh termux-api -y

# Install Oh My Zsh
msg "Menginstall Oh My Zsh..."
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Install Nerd Fonts (FiraCode)
msg "Menginstall FiraCode Nerd Font..."
mkdir -p ~/.termux/fonts
cd ~/.termux/fonts
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/FiraCode.zip
pkg install unzip -y
unzip FiraCode.zip
mv FiraCodeNerdFont-Regular.ttf ~/.termux/font.ttf
rm -rf FiraCode.zip
termux-reload-settings

# Konfigurasi Zsh dengan custom prompt
msg "Mengkonfigurasi Zsh..."
cat > ~/.zshrc << 'EOL'
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="agnoster"

# Fungsi untuk menampilkan status baterai
battery_status() {
    if command -v termux-battery-status >/dev/null; then
        battery=$(termux-battery-status | grep percentage | awk '{print $2}' | tr -d ',')
        if [ "$battery" -ge 80 ]; then
            echo "🔋 $battery%"
        elif [ "$battery" -ge 50 ]; then
            echo "🪫 $battery%"
        else
            echo "⚠️ $battery%"
        fi
    else
        echo "🔋 N/A"
    fi
}

# Custom prompt dengan jam, tanggal, dan baterai
PROMPT='%{$fg[cyan]%}%n@%m %{$fg[yellow]%}[%D{%Y-%m-%d} %T] %{$fg[green]%}$(battery_status)%{$reset_color%} %{$fg[blue]%}%~%{$reset_color%} $ '

plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
source $ZSH/oh-my-zsh.sh
EOL

# Install plugin Zsh
msg "Menginstall plugin Zsh..."
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# Ubah shell default ke Zsh
msg "Mengubah shell default ke Zsh..."
chsh -s "$(command -v zsh)"
echo '[[ -n $PS1 && -z $ZSH_VERSION ]] && exec zsh' >> ~/.bashrc
echo 'exec zsh' > ~/.termux/termux.properties.d/startup.sh

# Konfigurasi Termux properties
msg "Mengkonfigurasi Termux properties..."
mkdir -p ~/.termux
cat > ~/.termux/termux.properties << EOL
# Mengaktifkan tombol volume sebagai shortcut
extra-keys=[ ['ESC','~','|','/','HOME','UP','END','PGUP'], ['TAB','CTRL','ALT','LEFT','DOWN','RIGHT','PGDN'] ]
# Mengatur tema
bell-character=ignore
use-black-ui=true
EOL

# Reload pengaturan Termux
termux-reload-settings

# Install color scheme
msg "Menginstall color scheme..."
wget https://raw.githubusercontent.com/Mayccoll/Gogh/master/themes/dracula.sh
bash dracula.sh
rm dracula.sh

# Membersihkan cache
msg "Membersihkan cache..."
pkg autoclean

msg "Instalasi selesai! Silakan restart Termux untuk melihat perubahan."
msg "Zsh akan berjalan otomatis saat Termux dibuka."