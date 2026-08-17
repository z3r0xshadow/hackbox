# 🔐 Hackbox Setup Toolkit

> A menu-driven bash script that transforms a freshly provisioned VPS into a bug bounty and cybersecurity-ready workstation — one command at a time.

---

## What It Does

Spin up a VPS, SSH in as root, and run this script. It handles everything from system hardening to tool installation so you can start recon within minutes.

You can run each step individually from a menu, or hit **A** for full setup or **B** for a minimal essentials-only setup.

---

## Features

| # | Menu Option | What It Does |
|---|-------------|-------------|
| 1 | System Update | Full `apt update`, `upgrade`, `dist-upgrade`, and cache cleanup |
| 2 | Create User | Creates `z3r0` user, adds to `sudo` group, copies SSH keys |
| 3 | SSH Hardening | Disables root login, disables password auth (key-only) |
| 4 | Basic Essentials | **Fast, minimal** — curl, wget, git, python3, pip, htop, tmux, zsh, ripgrep, fd, bat, net-tools, socat, nc |
| 5 | CyberSec Tools | **Medium** — nmap, masscan, sqlmap, nikto, gobuster, dirb, httpie, whatweb, dnsutils, whois, traceroute |
| 6 | Extras | **Heavy** — Go toolchain + pip/go-based tools + binary drops (nuclei, ffuf, subfinder, httpx, amass, assetfinder, waybackurls, meg, etc.) |
| 7 | Workspace | Creates a structured `~/workspace/` directory layout |
| 8 | Summary | Shows VPS specs (CPU, RAM, disk, IP) and install status |
| **A** | Full Setup | Runs steps 1–2, 4–7 (essentials + cyber + extras + workspace) |
| **B** | Minimal Setup | Runs steps 1–2, 4, 7 (essentials + workspace only) |

---

## Tools Installed

### Basic Essentials (Option 4 — fast, minimal)
`curl` · `wget` · `git` · `build-essential` · `python3` · `python3-pip` · `python3-venv` · `unzip` · `jq` · `htop` · `tmux` · `zsh` · `tree` · `net-tools` · `lsof` · `socat` · `netcat-openbsd` · `ripgrep` · `fd-find` · `bat`

### CyberSec Tools (Option 5 — medium)
`nmap` · `masscan` · `whatweb` · `sqlmap` · `nikto` · `gobuster` · `dirb` · `httpie` · `dnsutils` · `whois` · `traceroute`

### Extras (Option 6 — heavy, Go/pip/binaries)
`subfinder` · `httpx` · `nuclei` · `amass` · `dirsearch` · `wpscan` · `sslyze` · `impacket` · `pwntools` · `ffuf` · `assetfinder` · `waybackurls` · `meg`

---

## Quick Start

```bash
# SSH into your fresh VPS as root
ssh root@<your-vps-ip>

# Download and run
curl -sLO https://raw.githubusercontent.com/<you>/<repo>/main/setup.sh
chmod +x setup.sh
sudo bash setup.sh
```

Or clone the repo:

```bash
git clone https://github.com/<you>/<repo>.git
cd <repo>
sudo bash setup.sh
```

---

## Recommended Flows

### Minimal — just a usable VPS (2 minutes)
```
1. SSH in as root
2. Run option 2  →  create user z3r0
3. Open a NEW terminal tab
4. SSH in as z3r0 to verify it works
5. Come back and run option 3  →  harden SSH (optional)
6. Run option B  →  minimal setup (essentials + workspace)
7. Done — you have a clean dev box
```

### Full Bug Bounty Workstation (15-20 minutes)
```
1. SSH in as root
2. Run option 2  →  create user z3r0
3. Open a NEW terminal tab
4. SSH in as z3r0 to verify it works
5. Come back and run option 3  →  harden SSH
6. Run option A  →  full setup (everything)
7. Done — start bug bounty 🎯
```

### Menu — install what you need, when you need it
```
Run option 4  →  basic essentials (always fast)
Run option 5  →  cybersec tools (when you need recon)
Run option 6  →  extras (when you have bandwidth/time)
```

> ⚠️ **Do NOT run SSH hardening (option 3) until you've verified you can SSH in as `z3r0`.** Once root login is disabled, there's no going back.

---

## Workspace Layout

The script creates this structure under `/home/z3r0/workspace/`:

```
workspace/
├── targets/      # One folder per program
├── scripts/      # Your custom recon & exploit scripts
├── wordlists/    # SecLists, custom lists
├── notes/        # Findings and documentation
└── loot/         # Captured data, screenshots
```

---

## Requirements

- Fresh Debian/Ubuntu VPS (tested on 22.04+)
- Root SSH access
- Internet connection

---

## License

Apache-2.0 — use it, fork it, make it your own.