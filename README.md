# dotfiles

![CI](https://github.com/fohte/dotfiles/actions/workflows/ci.yml/badge.svg)

[@fohte](https://github.com/fohte)'s personal dotfiles for macOS and Linux environments.

| Category | Tool | Description | Configuration |
| --- | --- | --- | --- |
| **Editor** | [Neovim](https://neovim.io) | Modern Vim-based editor with LSP support | [config/nvim](./config/nvim) |
| **Terminal (CLI)** | [Zsh](https://www.zsh.org) | Advanced shell with custom prompt and plugins | [config/zsh](./config/zsh) |
| **Terminal (CLI)** | [tmux](https://github.com/tmux/tmux) | Terminal session management | [config/tmux](./config/tmux) |
| **Terminal (CLI)** | [WezTerm](https://wezfurlong.org/wezterm/) | GPU-accelerated terminal emulator | [config/wezterm](./config/wezterm) |
| **Terminal (CLI)** | [Git](https://git-scm.com) | Git configuration and ignore patterns | [config/git](./config/git) |
| **Terminal (CLI)** | [Aqua](https://aquaproj.github.io) | Declarative CLI version manager | [config/aqua](./config/aqua) |
| **Terminal (CLI)** | [ripgrep](https://github.com/BurntSushi/ripgrep) | Fast text search tool | [config/rg](./config/rg) |
| **Terminal (CLI)** | [Prettier](https://prettier.io) | Code formatter | [config/prettier](./config/prettier) |
| **Terminal (CLI)** | [RuboCop](https://rubocop.org) | Ruby static code analyzer | [config/rubocop](./config/rubocop) |
| **Terminal (CLI)** | [GnuPG](https://gnupg.org) | Encryption and signing tool | [config/gnupg](./config/gnupg) |
| **GUI Apps** | [yabai](https://github.com/koekeishiya/yabai) | Tiling window manager for macOS | [config/yabai](./config/yabai) |
| **GUI Apps** | [Karabiner-Elements](https://karabiner-elements.pqrs.org) | Keyboard remapping for macOS | [config/karabiner](./config/karabiner) |
| **GUI Apps** | [Hammerspoon](https://www.hammerspoon.org) | Automation tool for macOS | [config/hammerspoon](./config/hammerspoon) |
| **GUI Apps** | [Espanso](https://espanso.org) | Cross-platform text expander | [config/espanso](./config/espanso) |
| **Others** | [Claude Code](https://github.com/anthropics/claude-code) | AI coding assistant configuration | [config/claude](./config/claude) |

## 🚀 Installation

Clone repository and run `scripts/deploy`:

```bash
git clone https://github.com/fohte/dotfiles ~/ghq/github.com/fohte/dotfiles && cd ~/ghq/github.com/fohte/dotfiles && scripts/deploy
```

You can deploy specified configs with `--tags` (`-t`) option:

```bash
scripts/deploy -t nvim,zsh
```

If you want to force deploy, you can use `--force` (`-f`) option:

```bash
scripts/deploy -f
```

If you want to dry run, you can use `--dry-run` (`-n`) option:

```bash
scripts/deploy -f -t nvim -n
```

### Upgrade

Run `refresh` command to upgrade packages, update dotfiles, and re-deploy configurations:

```bash
refresh
```

This will automatically:
- Update SKK dictionary
- Pull latest dotfiles changes (with git stash if needed)
- Restore Neovim plugins
- Install/update Aqua packages
- Run pre-commit hooks
- Upgrade Homebrew packages

You can also deploy updated configurations manually:

```bash
scripts/deploy
```
