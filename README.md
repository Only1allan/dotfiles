# dotfiles

Portable Omarchy-style terminal environment for **Ubuntu on WSL**: bash, tmux, Neovim/LazyVim, starship, and the **Matte Black** colour scheme.

This repo is private and contains no secrets. It is meant to be cloned on each machine, with the repo itself acting as the source of truth.

## What you get

- **bash** with Omarchy-style history, aliases, `eza` listings, `zoxide` (`cd`/`zd`), `fzf` bindings, and a `t` helper for tmux.
- **tmux** with prefix `C-Space` (and `C-b` as prefix2), vi copy mode, pane/window/session bindings, mouse support, true colour, and TPM + resurrect + continuum.
- **Neovim** with the full LazyVim setup, pinned plugins (`lazy-lock.json`), the Matte Black-friendly transparency tweak, and a WSL-aware clipboard provider.
- **starship** prompt using the Matte Black palette.
- **Matte Black** colour files for Windows Terminal, Alacritty, Ghostty, kitty, foot, and Neovim.
- **mise** config with the host tool set. Only Node is installed by default; run `mise install` for the rest.
- Windows Terminal scheme and settings snippet, plus a PowerShell font installer.

## Requirements

- Windows 10 or 11 with WSL2.
- Ubuntu 24.04 is recommended (22.04 works, but some newer tmux options are ignored).
- Windows Terminal is recommended. Alacritty is supported as an alternative.
- A Nerd Font: **JetBrainsMono Nerd Font**.

## Install on WSL

```bash
git clone https://github.com/Only1allan/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

The installer:

1. Installs Ubuntu packages (`tmux`, `git`, `ripgrep`, `fd-find`, `fzf`, `bat`, `ncurses-term`, `bsdmainutils`, plus `zoxide`, `wslu`, and `eza` when available).
2. Installs the latest Neovim release into `~/.local/opt` and links it to `~/.local/bin/nvim` (skipped if Neovim 0.10+ is already present).
3. Installs starship and mise, then installs Node 26.8.1.
4. Symlinks the repo configs into `$HOME`. Existing files are moved to `~/.dotfiles-backup-<timestamp>/`.
5. Installs TPM and the tmux plugins.
6. Runs `nvim --headless "+Lazy! sync" +qa` to install the pinned plugins.

Useful flags:

```bash
./install.sh --dry-run      # show what would happen
./install.sh --skip-nvim    # do not install Neovim or sync plugins
./install.sh --skip-mise    # do not install mise or Node
```

After it finishes:

```bash
exec bash -l
t
```

## Windows setup

### 1. Install the font

From Windows PowerShell, in the repo:

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\scripts\install-font.ps1
```

Or directly:

```powershell
winget install --id DEVCOM.JetBrainsMonoNerdFont --exact
```

Verify inside WSL:

```bash
fc-list | grep -i "JetBrainsMono Nerd"
```

### 2. Windows Terminal

Open `settings.json`:

- Store version: `%LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json`
- Unpackaged version: `%LOCALAPPDATA%\Microsoft\Windows Terminal\settings.json`

Add the contents of `windows-terminal/matte-black-scheme.json` to the `"schemes"` array, then merge `windows-terminal/settings-snippet.json` into `"profiles"`.

The snippet sets the font to `JetBrainsMono Nerd Font` at size 9, the Matte Black scheme, 14px padding, and a filled cursor.

### 3. Alacritty (optional)

Copy `alacritty/alacritty.toml` to:

```text
%APPDATA%\alacritty\alacritty.toml
```

It launches `wsl.exe -d Ubuntu --cd ~`. If your distro is not named `Ubuntu`, check `wsl.exe -l -v` and change the value.

## Key bindings

### tmux

| Binding | Action |
| --- | --- |
| `C-Space` | prefix |
| `C-Space h` / `v` | split vertically / horizontally |
| `C-Space x` | kill pane |
| `C-Space c` | new window |
| `C-Space r` | rename window |
| `C-Space k` | kill window |
| `C-Space C` | new session |
| `C-Space R` | rename session |
| `C-Space P` / `N` | previous / next session |
| `C-Space ?` | list all keybindings |
| `C-Space q` | reload config |

`M-Enter` and `M-S-Enter` also split panes. `M-1`…`M-9` switch windows. Arrow-key bindings use `Ctrl+Alt` for pane focus and `Ctrl+Alt+Shift` for resizing.

### Neovim

LazyVim defaults apply. Useful commands:

```vim
:Lazy          " plugin manager
:Lazy sync     " install/update pinned plugins
:Mason         " LSP/tool installer
:checkhealth   " diagnose
```

The leader key is `Space`.

## Clipboard

- **Inside tmux:** Neovim uses tmux as the clipboard provider. `set-clipboard on` makes tmux send OSC 52 to Windows Terminal, so yanks reach the Windows clipboard.
- **Outside tmux on WSL:** Neovim uses `clip.exe` and `powershell.exe Get-Clipboard`.
- **SSH:** copy uses OSC 52; paste falls back to Neovim's own register because most terminals do not support OSC 52 reads.

Windows Terminal supports OSC 52 writes by default. If copy does not work, check `compatibility.allowOSC52` in Windows Terminal settings.

## Updating

```bash
cd ~/dotfiles
git pull
./install.sh --skip-mise
```

After Neovim plugin updates:

```bash
nvim --headless "+Lazy! sync" +qa
git add home/.config/nvim/lazy-lock.json
git commit -m "Update LazyVim plugins"
git push
```

## Layout

```text
home/                    # files symlinked into $HOME
  .bashrc
  .bash_profile
  .profile
  .inputrc
  .config/
    nvim/
    tmux/tmux.conf
    starship.toml
    mise/config.toml
themes/matte-black/       # reference colour files
windows-terminal/         # Windows Terminal scheme + settings snippet
alacritty/                # Windows Alacritty config
scripts/install-font.ps1  # font installer
install.sh                # WSL installer
```

## Omarchy differences

This is a portable adaptation, not a copy of Omarchy itself:

- `omarchy-*` commands, the Omarchy menu, Wayland `wl-copy`/`wl-paste`, and theme hot-reload are not available on WSL.
- `tmux` help uses `tmux list-keys | less -R` instead of `omarchy-menu-tmux-keybindings`.
- `open` uses `wslview` to open the Windows default browser.
- `vim` and `vi` are aliases for `nvim`; plain Vim is not installed.
- `bat` and `fd` are symlinked from Ubuntu's `batcat` and `fdfind`.
- If `eza` is unavailable, `ls` falls back to GNU `ls --color=auto`.

## Uninstall / restore

The installer never deletes your previous configs. They are in the newest `~/.dotfiles-backup-*` directory. To restore:

```bash
ls -dt ~/.dotfiles-backup-* | head -n1
```

Remove the symlinks and move the backed-up files back into place. Then remove `~/.local/opt/nvim` and the TPM directory if you want a clean slate.

## Troubleshooting

```bash
nvim --version
tmux -V
starship --version
mise --version
fc-list | grep -i "JetBrainsMono Nerd"
wsl.exe -l -v
```

- **Prompt is plain:** reopen the shell; confirm `starship` is on `PATH` and `~/.bashrc` is the symlink.
- **Icons are boxes:** install the Nerd Font and select it in the terminal profile.
- **tmux says unknown option:** you are on an older tmux; upgrade Ubuntu or ignore the warning.
- **Lazy sync fails:** open `nvim`, run `:Lazy sync`, and check `:checkhealth`.
- **Node missing:** run `mise install` (the config includes more tools than the installer enables).
