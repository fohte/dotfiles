# dotfiles

![CI](https://github.com/fohte/dotfiles/actions/workflows/ci.yml/badge.svg)

[@fohte](https://github.com/fohte)'s personal dotfiles for macOS and Linux environments.

![Terminal Screenshot](https://github.com/user-attachments/assets/1d966208-a3cd-4c22-97d7-738fb5df0b2e)

## 🛠️ Tools & Configuration

- ✏️ **Editor**
    - **[Neovim](https://neovim.io)** - My beloved editor of choice ([config/nvim](./config/nvim))
- 💻 **Shell & Terminal**
    - **[Zsh](https://www.zsh.org)** - Feature-rich shell ([config/zsh](./config/zsh))
    - **[tmux](https://github.com/tmux/tmux)** - Terminal multiplexer ([config/tmux](./config/tmux))
    - **[Ghostty](https://ghostty.org)** - GPU-accelerated terminal ([config/ghostty](./config/ghostty))
- 🔧 **Development Tools**
    - **[Git](https://git-scm.com)** - Git configuration and ignore patterns ([config/git](./config/git))
    - **[tig](https://jonas.github.io/tig/)** - Text-based Git interface ([config/tig](./config/tig))
    - **[EditorConfig](https://editorconfig.org)** - Editor settings standardization ([config/editorconfig](./config/editorconfig))
    - **[Prettier](https://prettier.io)** - Code formatter ([config/prettier](./config/prettier))
    - **[RuboCop](https://rubocop.org)** - Ruby static code analyzer ([config/rubocop](./config/rubocop))
    - **[Claude Code](https://github.com/anthropics/claude-code)** - AI coding assistant configuration ([config/claude](./config/claude))
- ⚙️ **System Tools**
    - **[mise](https://mise.jdx.dev)** - Runtime and tool version manager ([config/mise](./config/mise))
    - **[ripgrep](https://github.com/BurntSushi/ripgrep)** - Fast text search tool ([config/rg](./config/rg))
    - **[GnuPG](https://gnupg.org)** - Encryption and signing tool ([config/gnupg](./config/gnupg))
- 🖥️ **Desktop Apps**
    - **[yabai](https://github.com/koekeishiya/yabai)** - Tiling window manager for macOS ([config/yabai](./config/yabai))
    - **[Karabiner-Elements](https://karabiner-elements.pqrs.org)** - Keyboard remapping for macOS ([config/karabiner](./config/karabiner))
    - **[Hammerspoon](https://www.hammerspoon.org)** - Automation tool for macOS ([config/hammerspoon](./config/hammerspoon))
    - **[BetterTouchTool](https://folivora.ai)** - Advanced input customization for macOS ([config/bettertouchtool](./config/bettertouchtool))
    - **[Raycast](https://www.raycast.com)** - Productivity launcher for macOS ([config/raycast](./config/raycast))
    - **[AquaSKK](https://github.com/codefirst/aquaskk)** - Japanese input method for macOS ([config/aquaskk](./config/aquaskk))
    - **[Espanso](https://espanso.org)** - Cross-platform text expander ([config/espanso](./config/espanso))
- 📁 **Custom Scripts**
    - **[bin](./config/bin)** - Utility shell scripts

## 🚀 Installation

Clone the repository and run `scripts/deploy`:

```bash
git clone https://github.com/fohte/dotfiles ~/ghq/github.com/fohte/dotfiles && cd ~/ghq/github.com/fohte/dotfiles && git submodule update --init && scripts/deploy
```

### ✨ Updating

Run the `refresh` command to update the dotfiles and upgrade packages:

```bash
refresh
```

This command automatically updates the SKK dictionary, Neovim plugins, mise tools, and more.

## 🔧 How Deployment Works

### Symlink Configuration

The deployment system uses the [`symlinks`](./symlinks) bash script to define how configuration files are linked to your system. This script contains conditional blocks that:

- Check for specific tags using the `match_tag` function
- Use the `sym` function to create symbolic links from source to destination
- Handle platform-specific paths with `is_macos`, `is_linux`, `is_wsl` functions

For example:

```bash
if match_tag nvim; then
  sym config/nvim ~/.config/nvim
fi
```

### Deploy Script Options

The [`scripts/deploy`](./scripts/deploy) script reads the [`symlinks`](./symlinks) file and supports various options to customize the deployment process:

- Deploy only specified configs:
    ```bash
    scripts/deploy -t nvim,zsh
    ```
- Force deployment:
    ```bash
    scripts/deploy -f
    ```
- Dry run:
    ```bash
    scripts/deploy -f -t nvim -n
    ```
- Enable debug mode:
    ```bash
    scripts/deploy --debug
    ```
