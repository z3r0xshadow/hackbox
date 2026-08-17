#!/usr/bin/env bash
#
# vps-setup.sh — Menu-driven VPS hardening & tool installer
# Target audience: Bug bounty / Cybersecurity practitioners
# Run as: sudo bash setup.sh  (from a fresh root SSH session)
#
set -euo pipefail

# ─── Colors & Formatting ──────────────────────────────────────────────
RED='\033[1;31m'; GRN='\033[1;32m'; YLW='\033[1;33m'; CYN='\033[1;36m'
BLD='\033[1m';    DIM='\033[2m';   RST='\033[0m'
BANNER="${RED}"

banner() {
    echo ""
    echo -e "${CYN}╔══════════════════════════════════════════════════╗${RST}"
    echo -e "${CYN}║${RST}  ${BLD}${RED}VPS SETUP TOOLKIT${RST}  —  Bug Bounty / CyberSec  ${CYN}║${RST}"
    echo -e "${CYN}╚══════════════════════════════════════════════════╝${RST}"
    echo ""
}

ok()   { echo -e "  ${GRN}[✔]${RST} $*"; }
warn() { echo -e "  ${YLW}[!]${RST} $*"; }
fail() { echo -e "  ${RED}[✘]${RST} $*"; }
info() { echo -e "  ${CYN}[i]${RST} $*"; }

divider() {
    echo -e "${DIM}$(printf '─%.0s' {1..52})${RST}"
}

# ─── State tracking ───────────────────────────────────────────────────
UPDATED=false
USER_CREATED=false
HARDENED=false
ESSENTIALS_INSTALLED=false
CYBER_TOOLS_INSTALLED=false
EXTRAS_INSTALLED=false

# ─── 1. System Update & Upgrade ───────────────────────────────────────
do_update() {
    banner
    echo -e "  ${BLD}Step 1:${RST} Updating & upgrading system packages..."
    divider
    apt-get update -y && apt-get upgrade -y && apt-get dist-upgrade -y
    apt-get autoremove -y && apt-get autoclean -y
    UPDATED=true
    divider
    ok "System is up to date."
}

# ─── 2. Create User z3r0 ─────────────────────────────────────────────
do_create_user() {
    banner
    echo -e "  ${BLD}Step 2:${RST} Creating user ${BLD}z3r0${RST} with sudo access..."
    divider
    if id "z3r0" &>/dev/null; then
        warn "User 'z3r0' already exists — skipping creation."
    else
        adduser --disabled-password --gecos "" z3r0
        usermod -aG sudo z3r0
        ok "User 'z3r0' created and added to sudo group."
    fi

    # Copy root's authorized_keys so z3r0 can SSH in with the same key
    if [ -d /root/.ssh ] && [ -f /root/.ssh/authorized_keys ]; then
        mkdir -p /home/z3r0/.ssh
        cp /root/.ssh/authorized_keys /home/z3r0/.ssh/
        chown -R z3r0:z3r0 /home/z3r0/.ssh
        chmod 700 /home/z3r0/.ssh
        chmod 600 /home/z3r0/.ssh/authorized_keys
        ok "SSH keys copied — you can SSH as z3r0 now."
    else
        warn "No root SSH keys found. Set up keys for z3r0 manually."
    fi
    USER_CREATED=true
    divider
}

# ─── 3. SSH Hardening ────────────────────────────────────────────────
do_ssh_harden() {
    banner
    echo -e "  ${BLD}Step 3:${RST} Hardening SSH configuration..."
    divider
    SSHD_CFG="/etc/ssh/sshd_config"

    # Backup
    cp "$SSHD_CFG" "${SSHD_CFG}.bak.$(date +%s)"
    ok "Backed up original sshd_config."

    # Apply hardening (idempotent sed replacements)
    sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/'              "$SSHD_CFG"
    sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' "$SSHD_CFG"
    sed -i 's/^#\?PubkeyAuthentication.*/PubkeyAuthentication yes/'     "$SSHD_CFG"
    sed -i 's/^#\?X11Forwarding.*/X11Forwarding no/'                  "$SSHD_CFG"
    sed -i 's/^#\?MaxAuthTries.*/MaxAuthTries 3/'                     "$SSHD_CFG"

    # Ensure PermitRootLogin is set even if the line was missing
    grep -q '^PermitRootLogin' "$SSHD_CFG"     || echo 'PermitRootLogin no'       >> "$SSHD_CFG"
    grep -q '^PasswordAuthentication' "$SSHD_CFG" || echo 'PasswordAuthentication no' >> "$SSHD_CFG"

    systemctl restart sshd
    HARDENED=true
    ok "SSH hardened: root login disabled, password auth off, key-only."
    divider
    warn "IMPORTANT: Make sure z3r0 can SSH in BEFORE closing this session!"
}

# ─── 4. Basic Essentials (minimal, fast) ─────────────────────────────
do_install_essentials() {
    banner
    echo -e "  ${BLD}Step 4a:${RST} Installing basic essential tools (fast, minimal)..."
    divider

    apt-get install -y \
        curl wget git build-essential libssl-dev libffi-dev \
        python3 python3-pip python3-venv unzip jq \
        htop tmux zsh tree \
        net-tools lsof socat netcat-openbsd \
        ripgrep fd-find bat

    # symlinks so fzf can find fd/bat by canonical names
    ln -sf "$(which fdfind 2>/dev/null || true)" /usr/local/bin/fd 2>/dev/null || true
    ln -sf "$(which batcat 2>/dev/null || true)" /usr/local/bin/bat 2>/dev/null || true

    ESSENTIALS_INSTALLED=true
    ok "Basic essentials installed: curl, wget, git, python3, pip, htop, tmux, zsh, ripgrep, fd, bat, net-tools, socat, nc"
    divider
}

# ─── 5. CyberSec Tools (optional, heavier) ───────────────────────────
do_install_cyber_tools() {
    banner
    echo -e "  ${BLD}Step 4b:${RST} Installing cybersecurity / bug bounty tools..."
    divider

    # ── Recon & Scanning ──
    echo -e "\n  ${BLD}▸ Recon & Scanning${RST}"
    apt-get install -y nmap masscan whatweb dnsutils whois traceroute
    ok "nmap, masscan, whatweb, dnsutils, whois, traceroute"

    # ── Web Exploitation ──
    echo -e "\n  ${BLD}▸ Web Exploitation${RST}"
    apt-get install -y httpie sqlmap nikto dirb gobuster
    ok "sqlmap, nikto, dirb, gobuster, httpie"

    # Extra network tools
    apt-get install -y dnsutils whois traceroute

    CYBER_TOOLS_INSTALLED=true
    divider
}

# ─── 6. Extra Tools (pip / go / cargo based) ────────────────────────
do_install_extras() {
    banner
    echo -e "  ${BLD}Step 5:${RST} Installing extras via pip / go / manual..."
    divider

    # ── Python tools ──
    echo -e "\n  ${BLD}▸ Python tools${RST}"
    pip3 install --break-system-packages 2>/dev/null \
        subfinder httpx nuclei amass \
        dirsearch wpscan sslyze \
        impacket pwntools \
        flask 2>/dev/null || \
    pip3 install subfinder httpx nuclei amass \
        dirsearch wpscan sslyze \
        impacket pwntools \
        flask 2>/dev/null || warn "Some pip packages may need manual install."
    ok "subfinder, httpx, nuclei, amass, dirsearch, wpscan, sslyze, impacket, pwntools"

    # ── Go-based tools ──
    echo -e "\n  ${BLD}▸ Go-based tools${RST}"
    if ! command -v go &>/dev/null; then
        GO_VER="1.22.5"
        curl -sLO "https://go.dev/dl/go${GO_VER}.linux-amd64.tar.gz"
        rm -rf /usr/local/go && tar -C /usr/local -xzf "go${GO_VER}.linux-amd64.tar.gz"
        rm -f "go${GO_VER}.linux-amd64.tar.gz"
        echo 'export PATH=$PATH:/usr/local/go/bin:/root/go/bin' >> /etc/profile.d/golang.sh
        export PATH=$PATH:/usr/local/go/bin:/root/go/bin
        ok "Go ${GO_VER} installed."
    else
        ok "Go already present — skipping."
    fi

    # ffuf — fast web fuzzer
    if ! command -v ffuf &>/dev/null; then
        go install github.com/ffuf/ffuf/v2@latest 2>/dev/null && ok "ffuf installed." || warn "ffuf — install manually."
    else
        ok "ffuf already present."
    fi

    # ── Binary drops ──
    echo -e "\n  ${BLD}▸ Binary drops${RST}"
    BIN_DIR="/usr/local/bin"

    # Assetfinder
    if ! command -v assetfinder &>/dev/null; then
        curl -sL "https://github.com/tomnomnom/assetfinder/releases/download/v0.4.1/assetfinder-linux-amd64.gz" \
            | gunzip > "$BIN_DIR/assetfinder" && chmod +x "$BIN_DIR/assetfinder"
        ok "assetfinder installed."
    else
        ok "assetfinder already present."
    fi

    # Meg (bulk fetcher)
    if ! command -v meg &>/dev/null; then
        go install github.com/tomnomnom/meg@latest 2>/dev/null && ok "meg installed." || warn "meg — install manually."
    else
        ok "meg already present."
    fi

    # waybackurls
    if ! command -v waybackurls &>/dev/null; then
        go install github.com/tomnomnom/waybackurls@latest 2>/dev/null && ok "waybackurls installed." || warn "waybackurls — install manually."
    else
        ok "waybackurls already present."
    fi

    EXTRAS_INSTALLED=true
    divider
}

# ─── 7. Workspace Setup ──────────────────────────────────────────────
do_workspace() {
    banner
    echo -e "  ${BLD}Step 6:${RST} Creating project workspace..."
    divider

    TARGET_USER="${1:-z3r0}"
    HOME_DIR=$(eval echo "~${TARGET_USER}")
    WORKSPACE="${HOME_DIR}/workspace"

    mkdir -p "$WORKSPACE"/{targets,scripts,wordlists,notes,loot}
    chown -R "${TARGET_USER}:${TARGET_USER}" "$WORKSPACE"
    ok "Workspace created at $WORKSPACE"
    info "  targets/   — one folder per bug bounty program"
    info "  scripts/   — your custom recon / exploit scripts"
    info "  wordlists/ — SecLists, custom wordlists"
    info "  notes/     — findings, notes"
    info "  loot/      — captured data, screenshots"
    divider
}

# ─── 8. System Summary ──────────────────────────────────────────────
do_summary() {
    banner
    echo -e "  ${BLD}VPS Summary${RST}"
    divider

    # ── OS ──
    OS=$(cat /etc/os-release 2>/dev/null | grep PRETTY_NAME | cut -d'"' -f2)
    echo -e "  ${CYN}OS:${RST}       ${OS:-Unknown}"
    echo -e "  ${CYN}Kernel:${RST}   $(uname -r)"
    echo -e "  ${CYN}Hostname:${RST} $(hostname)"
    echo ""

    # ── CPU ──
    CORES=$(nproc 2>/dev/null || echo "?")
    MODEL=$(grep -m1 'model name' /proc/cpuinfo 2>/dev/null | cut -d: -f2 | xargs)
    echo -e "  ${CYN}CPU:${RST}      ${MODEL:-Unknown}  (${CORES} cores)"

    # ── RAM ──
    MEM_TOTAL=$(awk '/MemTotal/ {printf "%.1f GB", $2/1048576}' /proc/meminfo 2>/dev/null)
    MEM_USED=$(awk '/MemAvailable/ {printf "%.1f GB", $2/1048576}' /proc/meminfo 2>/dev/null)
    echo -e "  ${CYN}RAM:${RST}      ${MEM_TOTAL:-?} total  (~${MEM_USED:-?} available)"

    # ── Disk ──
    DISK_INFO=$(df -h / | awk 'NR==2{print $2 " total, " $3 " used, " $4 " free (" $5 " used)"}')
    echo -e "  ${CYN}Disk:${RST}     ${DISK_INFO:-?}"

    # ── IP ──
    PUB_IP=$(curl -s --max-time 5 ifconfig.me 2>/dev/null || echo "?")
    echo -e "  ${CYN}Public IP:${RST} ${PUB_IP}"
    echo ""

    # ── Status ──
    divider
    echo -e "  ${BLD}Setup Status${RST}"
    divider
    $UPDATED             && ok "System updated"               || warn "System update skipped"
    $USER_CREATED        && ok "User z3r0 created"             || warn "User creation skipped"
    $HARDENED            && ok "SSH hardened"                  || warn "SSH hardening skipped"
    $ESSENTIALS_INSTALLED  && ok "Basic essentials installed"  || warn "Basic essentials skipped"
    $CYBER_TOOLS_INSTALLED && ok "CyberSec tools installed"    || warn "CyberSec tools skipped"
    $EXTRAS_INSTALLED    && ok "Extras installed"              || warn "Extras skipped"
    divider
    echo ""
    echo -e "  ${GRN}${BLD}All done!${RST} SSH in as:  ${CYN}ssh z3r0@${PUB_IP}${RST}"
    echo ""
}

# ─── Main Menu ────────────────────────────────────────────────────────
main_menu() {
    banner
    while true; do
        echo -e "  ${BLD}Main Menu${RST}"
        divider
        echo -e "  ${CYN}1${RST}  Update & upgrade system"
        echo -e "  ${CYN}2${RST}  Create user z3r0 (sudo)"
        echo -e "  ${CYN}3${RST}  Harden SSH (disable root login)"
        echo -e "  ${CYN}4${RST}  Install basic essentials only  ${DIM}(fast, minimal)${RST}"
        echo -e "  ${CYN}5${RST}  Install cybersecurity tools   ${DIM}(recon, web, scanning)${RST}"
        echo -e "  ${CYN}6${RST}  Install extras (pip / go / binaries)  ${DIM}(heavy)${RST}"
        echo -e "  ${CYN}7${RST}  Create workspace for z3r0"
        echo -e "  ${CYN}8${RST}  View VPS summary"
        divider
        echo -e "  ${GRN}${BLD}A${RST}  Full setup (essentials + cyber + extras + workspace)"
        echo -e "  ${GRN}${BLD}B${RST}  Minimal setup (essentials + workspace only)"
        echo -e "  ${RED}${BLD}Q${RST}  Quit"
        divider
        echo ""
        read -rp "  Select an option: " choice
        echo ""

        case "${choice^^}" in
            1) do_update ;;
            2) do_create_user ;;
            3) do_ssh_harden ;;
            4) do_install_essentials ;;
            5) do_install_cyber_tools ;;
            6) do_install_extras ;;
            7) do_workspace z3r0 ;;
            8) do_summary ;;
            A)
                echo -e "  ${BLD}Running FULL setup...${RST}\n"
                do_update
                do_create_user
                do_install_essentials
                do_install_cyber_tools
                do_install_extras
                do_workspace z3r0
                do_summary
                echo -e "\n  ${YLW}Tip: Run option 3 (SSH harden) only after${RST}"
                echo -e "  ${YLW}you've verified you can SSH as z3r0!${RST}\n"
                ;;
            B)
                echo -e "  ${BLD}Running MINIMAL setup...${RST}\n"
                do_update
                do_create_user
                do_install_essentials
                do_workspace z3r0
                do_summary
                echo -e "\n  ${YLW}Tip: Run option 3 (SSH harden) only after${RST}"
                echo -e "  ${YLW}you've verified you can SSH as z3r0!${RST}\n"
                ;;
            Q|QUIT|EXIT)
                echo -e "  ${GRN}Goodbye.${RST}"
                exit 0
                ;;
            *)
                fail "Invalid option. Try again."
                ;;
        esac
        echo ""
    done
}

# ─── Entrypoint ───────────────────────────────────────────────────────
main_menu