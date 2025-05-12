#!/bin/bash

# Script untuk mempercantik tampilan terminal VPS dengan otomatisasi
# Mendukung Ubuntu/Debian dan CentOS, berjalan otomatis tanpa perintah manual

# Fungsi untuk menangani error
handle_error() {
    echo "Error: $1"
    exit 1
}

# Cek apakah script dijalankan sebagai root
if [[ $EUID -ne 0 ]]; then
    echo "Script ini harus dijalankan sebagai root atau dengan sudo."
    exit 1
fi

# Deteksi distribusi
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
else
    handle_error "Tidak dapat mendeteksi distribusi."
fi

# Fungsi untuk install paket berdasarkan distro
install_packages() {
    case $DISTRO in
        ubuntu|debian)
            apt update || handle_error "Gagal mengupdate paket."
            apt install -y "$@" || handle_error "Gagal menginstall paket: $@"
            ;;
        centos|rhel)
            yum update -y || handle_error "Gagal mengupdate paket."
            yum install -y "$@" || handle_error "Gagal menginstall paket: $@"
            ;;
        *)
            handle_error "Distribusi $DISTRO tidak didukung."
            ;;
    esac
}

# Install dependensi dasar
echo "Menginstall dependensi dasar..."
install_packages curl git zsh neofetch tmux ruby ruby-dev fonts-powerline build-essential unzip htop

# Install Oh My Zsh
echo "Menginstall Oh My Zsh..."
if ! sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended; then
    handle_error "Gagal menginstall Oh My Zsh."
fi

# Ganti shell default ke zsh
echo "Mengganti shell default ke ZSH..."
chsh -s $(which zsh) || handle_error "Gagal mengganti shell ke ZSH."

# Install plugin Oh My Zsh
echo "Menginstall plugin Oh My Zsh..."
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions || handle_error "Gagal menginstall zsh-autosuggestions."
git clone https://github.com/zsh-users/zsh-syntax-highlighting ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting || handle_error "Gagal menginstall zsh-syntax-highlighting."
git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-completions || handle_error "Gagal menginstall zsh-completions."

# Install tema Powerlevel10k
echo "Menginstall tema Powerlevel10k..."
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/powerlevel10k || handle_error "Gagal menginstall Powerlevel10k."

# Install starship (prompt alternatif)
echo "Menginstall starship..."
curl -sS https://starship.rs/install.sh | sh -s -- -y || handle_error "Gagal menginstall starship."

# Install zoxide (navigasi direktori cerdas)
echo "Menginstall zoxide..."
curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash || handle_error "Gagal menginstall zoxide."

# Install colorls
echo "Menginstall colorls..."
gem install colorls || handle_error "Gagal menginstall colorls."

# Install exa (alternatif ls)
echo "Menginstall exa..."
case $DISTRO in
    ubuntu|debian)
        curl -Lo /tmp/exa.zip https://github.com/ogham/exa/releases/latest/download/exa-linux-x86_64-musl.zip || handle_error "Gagal mengunduh exa."
        unzip /tmp/exa.zip -d /usr/local/bin/ || handle_error "Gagal menginstall exa."
        mv /usr/local/bin/exa-linux-x86_64 /usr/local/bin/exa
        chmod +x /usr/local/bin/exa
        ;;
    centos|rhel)
        yum install -y exa || handle_error "Gagal menginstall exa."
        ;;
esac

# Install bat (alternatif cat)
echo "Menginstall bat..."
case $DISTRO in
    ubuntu|debian)
        curl -Lo /tmp/bat.deb https://github.com/sharkdp/bat/releases/latest/download/bat_0.24.0_amd64.deb || handle_error "Gagal mengunduh bat."
        dpkg -i /tmp/bat.deb || handle_error "Gagal menginstall bat."
        ;;
    centos|rhel)
        yum install -y bat || handle_error "Gagal menginstall bat."
        ;;
esac

# Install fzf (pencarian interaktif)
echo "Menginstall fzf..."
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf || handle_error "Gagal mengunduh fzf."
~/.fzf/install --all || handle_error "Gagal menginstall fzf."

# Backup file .zshrc
echo "Membackup .zshrc..."
cp ~/.zshrc ~/.zshrc.bak 2>/dev/null || true

# Konfigurasi .zshrc
echo "Mengatur konfigurasi .zshrc..."
cat <<EOL > ~/.zshrc
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k" # Tema default: Powerlevel10k
# Untuk menggunakan starship, uncomment baris berikut dan comment Powerlevel10k
# eval "\$(starship init zsh)"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-completions)
source \$ZSH/oh-my-zsh.sh

# Tampilkan info sistem dengan neofetch
neofetch

# Inisialisasi zoxide
eval "\$(zoxide init zsh)"

# Alias untuk produktivitas
alias cls='clear'
alias update='sudo apt update && sudo apt upgrade -y || sudo yum update -y'
alias ll='exa -l --group-directories-first --icons'
alias la='exa -la --group-directories-first --icons'
alias cat='bat'
alias gs='git status'
alias gd='git diff'
alias dockerps='docker ps -a'
alias tmuxattach='tmux attach -t mysession'
alias top='htop'
alias cd='z' # Gunakan zoxide untuk navigasi direktori

# Konfigurasi fzf
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Konfigurasi Powerlevel10k
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
EOL

# Backup file .tmux.conf
echo "Membackup .tmux.conf..."
[ -f ~/.tmux.conf ] && cp ~/.tmux.conf ~/.tmux.conf.bak 2>/dev/null || true

# Konfigurasi tmux
echo "Mengatur konfigurasi tmux..."
cat <<EOL > ~/.tmux.conf
# Aktifkan mouse
set -g mouse on

# Ubah prefix default dari Ctrl+b ke Ctrl+a
unbind C-b
set-option -g prefix C-a
bind-key C-a send-prefix

# Split window
bind | split-window -h
bind - split-window -v

# Tema sederhana
set -g status-bg colour235
set -g status-fg white
set -g status-left "#[fg=green]#H "
set -g status-right "#[fg=yellow]%Y-%m-%d %H:%M"
EOL

# Konfigurasi tmux otomatis saat login
echo "Mengatur tmux otomatis..."
cat <<EOL >> ~/.zshrc
# Jalankan tmux otomatis saat login, kecuali sudah di dalam tmux
if [ -z "\$TMUX" ] && [ -n "\$(command -v tmux)" ]; then
    tmux new-session -s mysession || tmux attach -t mysession
fi
EOL

# Konfigurasi MOTD dengan ASCII art
echo "Mengatur MOTD..."
cat <<EOL > /etc/motd
   ____        _ _       
  |  _ \      (_) |      
  | |_) | __ _ _| |_ ___ 
  |  _ < / _\` | | __/ __|
  | |_) | (_| | | |_\__ \\
  |____/ \__,_|_|\__|___/

Welcome to your enhanced VPS terminal!
Powered by Oh My Zsh, Powerlevel10k, tmux, and more.
- Use 'll' for colorful file lists
- Use 'cat' for syntax-highlighted files
- Use 'z' for smart directory navigation
- Use 'fzf' for interactive search
- Tmux is running automatically (Ctrl+a for commands)
EOL

# Konfigurasi prompt bash cadangan
echo "Mengatur prompt bash (cadangan)..."
echo 'PS1="\[\e[32m\]\u@\h \[\e[33m\]\w\[\e[0m\] \$ "' >> ~/.bashrc

# Bersihkan file sementara
rm -f /tmp/exa.zip /tmp/bat.deb 2>/dev/null

# Selesai
echo "Konfigurasi selesai! Silakan keluar dan masuk kembali ke terminal untuk melihat perubahan."
echo "Tmux akan berjalan otomatis. Gunakan Ctrl+a untuk perintah tmux."
echo "Powerlevel10k akan memandu konfigurasi tema saat pertama kali login."
echo "Coba 'll', 'cat', 'z', atau 'fzf' untuk fitur baru!"