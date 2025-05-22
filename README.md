# dotfiles

[@fohte](https://github.com/fohte)'s personal dotfiles for macOS, Linux environments.

## Quick Install

### One-liner Installation

```bash
curl -sL bit.ly/fohte-dots | sh
```

or

```bash
wget -O - bit.ly/fohte-dots | sh
```

### Manual Installation

```bash
git clone https://github.com/Fohte/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./scripts/deploy
```

## What's Included

- **Shell**: Zsh with custom configuration and Starship prompt
- **Editor**: Neovim with comprehensive plugin setup
- **Terminal**: WezTerm, Tmux configuration
- **Git**: Git configuration and utilities
- **Tools**: Hammerspoon, Karabiner, Yabai (macOS), and various CLI tools

## Deployment System

The dotfiles use a tag-based deployment system via `scripts/deploy`:

### Deploy Everything

```bash
./scripts/deploy
```

### Deploy Specific Tools

```bash
./scripts/deploy --tags nvim,git,zsh
```

### Available Options

- `--help, -h`: Show help
- `--dry-run, -n`: Preview what will be deployed
- `--force, -f`: Overwrite existing files
- `--tags, -t`: Deploy only specified tags (comma-separated)

### Available Tags

- `nvim` - Neovim configuration
- `git` - Git configuration
- `zsh` - Zsh shell configuration
- `tmux` - Terminal multiplexer
- `wezterm` - Terminal emulator
- `hammerspoon` - macOS automation (macOS only)
- `karabiner` - Key remapping (macOS only)
- `yabai` - Window manager (macOS only)
- `espanso` - Text expander
- `aqua` - Package manager configuration
- `claude` - Claude AI configuration
- And more...

## Platform Support

- **macOS**: Full support with native tools (Hammerspoon, Karabiner, Yabai)
- **Linux**: Core tools and configurations
- **WSL**: Windows Subsystem for Linux support with platform-specific adaptations

## Directory Structure

```
config/
├── nvim/          # Neovim configuration with Lua
├── zsh/           # Zsh configuration and plugins
├── tmux/          # Tmux configuration
├── git/           # Git configuration and ignore patterns
├── wezterm/       # WezTerm terminal configuration
├── hammerspoon/   # macOS automation scripts
├── karabiner/     # Keyboard customization (macOS)
├── yabai/         # Window manager (macOS)
└── ...
```

## Key Features

### Neovim Configuration
- Modern Lua-based configuration
- LSP support with automated installation
- Treesitter for syntax highlighting
- Telescope for fuzzy finding
- Git integration with Fugitive and Gitsigns

### Shell Configuration
- Zsh with Zinit plugin manager
- Starship prompt with Git integration
- Custom aliases and functions
- Cross-platform compatibility

### Terminal Setup
- WezTerm with custom themes
- Tmux with vim-like keybindings
- Platform-specific optimizations

## Customization

The configuration uses environment detection to automatically adapt to your platform. Most tools have sensible defaults but can be customized by editing files in the `config/` directory.

For Neovim specifically, see the `config/nvim/` directory for the complete Lua configuration.

## Requirements

- Git (for cloning)
- Curl or Wget (for one-liner installation)
- Platform-specific package managers will be detected automatically

## License

MIT License - feel free to use and modify as needed.
