# dotfiles

![CI](https://github.com/fohte/dotfiles/actions/workflows/ci.yml/badge.svg)

[@fohte](https://github.com/fohte)'s personal dotfiles for macOS and Linux environments.

| Category | Tool | Description | Configuration |
| --- | --- | --- | --- |
| **✏️ Editor** | [Neovim](https://neovim.io) | Modern Vim-based editor with LSP support | [config/nvim](./config/nvim) |
| **💻 Shell & Terminal** | [Zsh](https://www.zsh.org) | Advanced shell with custom prompt and plugins | [config/zsh](./config/zsh) |
| **💻 Shell & Terminal** | [tmux](https://github.com/tmux/tmux) | Terminal session management | [config/tmux](./config/tmux) |
| **💻 Shell & Terminal** | [WezTerm](https://wezfurlong.org/wezterm/) | GPU-accelerated terminal emulator | [config/wezterm](./config/wezterm) |
| **🔧 Development Tools** | [Git](https://git-scm.com) | Git configuration and ignore patterns | [config/git](./config/git) |
| **🔧 Development Tools** | [tig](https://jonas.github.io/tig/) | Text-based Git interface | [config/tig](./config/tig) |
| **🔧 Development Tools** | [EditorConfig](https://editorconfig.org) | Editor configuration standardization | [config/editorconfig](./config/editorconfig) |
| **🔧 Development Tools** | [Prettier](https://prettier.io) | Code formatter | [config/prettier](./config/prettier) |
| **🔧 Development Tools** | [RuboCop](https://rubocop.org) | Ruby static code analyzer | [config/rubocop](./config/rubocop) |
| **🔧 Development Tools** | [Claude Code](https://github.com/anthropics/claude-code) | AI coding assistant configuration | [config/claude](./config/claude) |
| **⚙️ System Tools** | [Aqua](https://aquaproj.github.io) | Declarative CLI version manager | [config/aqua](./config/aqua) |
| **⚙️ System Tools** | [ripgrep](https://github.com/BurntSushi/ripgrep) | Fast text search tool | [config/rg](./config/rg) |
| **⚙️ System Tools** | [GnuPG](https://gnupg.org) | Encryption and signing tool | [config/gnupg](./config/gnupg) |
| **🖥️ Desktop Apps** | [yabai](https://github.com/koekeishiya/yabai) | Tiling window manager for macOS | [config/yabai](./config/yabai) |
| **🖥️ Desktop Apps** | [Karabiner-Elements](https://karabiner-elements.pqrs.org) | Keyboard remapping for macOS | [config/karabiner](./config/karabiner) |
| **🖥️ Desktop Apps** | [Hammerspoon](https://www.hammerspoon.org) | Automation tool for macOS | [config/hammerspoon](./config/hammerspoon) |
| **🖥️ Desktop Apps** | [BetterTouchTool](https://folivora.ai) | Advanced input customization for macOS | [config/bettertouchtool](./config/bettertouchtool) |
| **🖥️ Desktop Apps** | [Raycast](https://www.raycast.com) | Productivity launcher for macOS | [config/raycast](./config/raycast) |
| **🖥️ Desktop Apps** | [AquaSKK](https://github.com/codefirst/aquaskk) | Japanese input method for macOS | [config/aquaskk](./config/aquaskk) |
| **🖥️ Desktop Apps** | [Espanso](https://espanso.org) | Cross-platform text expander | [config/espanso](./config/espanso) |

### 📁 Custom Scripts

- **[bin](./config/bin)** - Custom utility scripts and commands

## 🚀 Installation

Clone repository and run `scripts/deploy`:

```bash
git clone https://github.com/fohte/dotfiles ~/ghq/github.com/fohte/dotfiles && cd ~/ghq/github.com/fohte/dotfiles && scripts/deploy
```

### ✨ Upgrade

Run `refresh` command to update dotfiles and upgrade packages:

```bash
refresh
```

This will automatically update SKK dictionary, Neovim plugins, aqua packages, and more.

## 📦 Deployment

The `scripts/deploy` script creates symbolic links from your home directory to the configuration files in this repository.

- Deploy specified configs:
  ```bash
  scripts/deploy -t nvim,zsh
  ```
- Force deploy:
  ```bash
  scripts/deploy -f
  ```
- Dry run:
  ```bash
  scripts/deploy -f -t nvim -n
  ```
- Debug mode:
  ```bash
  scripts/deploy --debug
  ```
