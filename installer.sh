#!/data/data/com.termux/files/usr/bin/bash

# Warna untuk output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
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

# Periksa dependensi Termux:API
msg "Memeriksa Termux:API..."
if ! pkg_install_termux_api=$(pkg install termux-api -y 2>&1); then
    error "Gagal menginstall Termux:API. Pastikan aplikasi Termux:API terinstall dari Play Store/F-Droid."
    exit 1
fi

# Update dan upgrade Termux
msg "Mengupdate dan mengupgrade Termux..."
pkg update -y && pkg upgrade -y

# Install paket dasar
msg "Menginstall paket dasar..."
pkg install git wget curl nano zsh termux-api neofetch toilet lsd bat cowsay -y

# Install Oh My Zsh
msg "Menginstall Oh My Zsh..."
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Install Powerlevel10k
msg "Menginstall Powerlevel10k..."
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/powerlevel10k

# Install Hack Nerd Font
msg "Menginstall Hack Nerd Font..."
mkdir -p ~/.termux/fonts
cd ~/.termux/fonts
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/Hack.zip
pkg install unzip -y
unzip Hack.zip
mv HackNerdFont-Regular.ttf ~/.termux/font.ttf
rm -rf Hack.zip
termux-reload-settings

# Backup dan hapus .zshrc lama
msg "Membackup dan menghapus .zshrc lama..."
[ -f ~/.zshrc ] && mv ~/.zshrc ~/.zshrc.bak
touch ~/.zshrc

# Konfigurasi Zsh dengan Powerlevel10k
msg "Mengkonfigurasi Zsh..."
cat > ~/.zshrc << 'EOL'
# Path ke Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"

# Tema Powerlevel10k
ZSH_THEME="powerlevel10k/powerlevel10k"

# Fungsi untuk status baterai
battery_status() {
    if command -v termux-battery-status >/dev/null 2>&1; then
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

# Fungsi untuk status jaringan
network_status() {
    if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        echo "🌐 Terhubung"
    else
        echo "📴 Tidak Terhubung"
    fi
}

# Fungsi untuk penggunaan RAM
ram_usage() {
    if command -v free >/dev/null 2>&1; then
        free -m | awk '/Mem:/ {print $3 "/" $2 " MB"}'
    else
        echo "N/A"
    fi
}

# Fungsi untuk waktu sistem
system_time() {
    date +"%H:%M:%S %d-%m-%Y"
}

# Fungsi untuk memperbarui motd
update_motd() {
    BATTERY_STATUS=$(battery_status)
    NETWORK_STATUS=$(network_status)
    RAM_STATUS=$(ram_usage)
    SYSTEM_TIME=$(system_time)
    toilet -f term -F border --gay "Termux" > /data/data/com.termux/files/usr/etc/motd
    cat >> /data/data/com.termux/files/usr/etc/motd << EOF
$(printf "\033[1;36mSelamat Datang di Termux Kustom!\033[0m")
- \033[1;32mWaktu Sistem:\033[0m \$SYSTEM_TIME
- \033[1;32mStatus Baterai:\033[0m \$BATTERY_STATUS
- \033[1;32mStatus Jaringan:\033[0m \$NETWORK_STATUS
- \033[1;32mPenggunaan RAM:\033[0m \$RAM_STATUS
- \033[1;34mDokumentasi:\033[0m https://doc.termux.com
- \033[1;34mKomunitas:\033[0m https://community.termux.com
- \033[1;33mPerintah:\033[0m
  * Cari paket: \033[1;37mpkg search <query>\033[0m
  * Install paket: \033[1;37mpkg install <package>\033[0m
  * Update sistem: \033[1;37mpkg upgrade\033[0m
  * Info sistem: \033[1;37msysinfo\033[0m
\033[1;31mLaporkan bug di:\033[0m https://bugs.termux.com
EOF
}

# Jalankan update_motd saat startup
update_motd

# Plugin
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)

# Alias
alias ll='lsd -lah --icon always'
alias ls='lsd --icon always'
alias cat='bat'
alias c='clear'
alias ..='cd ..'
alias sysinfo='neofetch'
alias gs='git status'
alias gc='git commit -m'
alias gp='git push'
alias npmi='npm install'
alias pipi='pip install'

# Load Oh My Zsh
source $ZSH/oh-my-zsh.sh

# Konfigurasi Powerlevel10k
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Animasi startup dengan cowsay
cowsay -f dragon "Selamat datang, coder!"

# Tampilkan neofetch saat startup
neofetch
EOL

# Konfigurasi Powerlevel10k
msg "Mengkonfigurasi Powerlevel10k..."
cat > ~/.p10k.zsh << 'EOL'
# Enable Powerlevel10k instant prompt
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Konfigurasi Powerlevel10k (Lean style)
typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(
  dir
  vcs
  newline
  user
  host
  time
  battery
  ram
  node_version
  python_version
)
typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(
  status
  command_execution_time
  background_jobs
  context
  virtualenv
)
typeset -g POWERLEVEL9K_MODE='nerdfont-complete'
typeset -g POWERLEVEL9K_TIME_FORMAT='%D{%H:%M:%S}'
typeset -g POWERLEVEL9K_BATTERY_STAGES='🔋🪫⚠️'
typeset -g POWERLEVEL9K_RAM_VISUAL_IDENTIFIER='💾'
typeset -g POWERLEVEL9K_NODE_VERSION_VISUAL_IDENTIFIER='⬢'
typeset -g POWERLEVEL9K_PYTHON_VERSION_VISUAL_IDENTIFIER='🐍'
typeset -g POWERLEVEL9K_PROMPT_ADD_NEWLINE=true
typeset -g POWERLEVEL9K_LEAN_STYLE=true
EOL

# Install plugin Zsh
msg "Menginstall plugin Zsh..."
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# Ubah shell default ke Zsh
msg "Mengubah shell default ke Zsh..."
chsh -s "$(command -v zsh)"
echo '[[ -n $PS1 && -z $ZSH_VERSION ]] && exec zsh' >> ~/.bashrc
mkdir -p ~/.termux/termux.properties.d
echo 'exec zsh' > ~/.termux/termux.properties.d/startup.sh

# Konfigurasi Termux properties
msg "Mengkonfigurasi Termux properties..."
mkdir -p ~/.termux
cat > ~/.termux/termux.properties << EOL
# Mengaktifkan tombol volume sebagai shortcut
extra-keys=[ ['ESC','~','|','/','HOME','UP','END','PGUP'], ['TAB','CTRL','ALT','LEFT','DOWN','RIGHT','PGDN','BKSP'] ]
# Mengatur tema
bell-character=ignore
use-black-ui=true
font-size=16
EOL

# Install tema Nord
msg "Menginstall tema Nord..."
wget https://raw.githubusercontent.com/Mayccoll/Gogh/master/themes/nord.sh
bash nord.sh
rm nord.sh

# Reload pengaturan Termux
termux-reload-settings

# Membersihkan cache
msg "Membersihkan cache..."
pkg autoclean

msg "Instalasi selesai! Silakan restart Termux untuk melihat perubahan."
msg "Zsh akan berjalan otomatis dengan tampilan baru, animasi, dan info sistem."