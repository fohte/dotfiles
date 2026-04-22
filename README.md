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

Clone the repository, set the machine role, and run the `dot` command:

```bash
git clone https://github.com/fohte/dotfiles ~/ghq/github.com/fohte/dotfiles
cd ~/ghq/github.com/fohte/dotfiles
git submodule update --init
config/bin/dot role set private   # or: dot role set work repo=<owner>/<name>
config/bin/dot deploy
```

After the initial deployment, `dot` will be available on your `PATH` (via the `bin` symlink to `~/bin`).

### 🎭 Machine Roles

`dot deploy` requires a machine role to be set so that overlay files (e.g. extra MCP
servers, role-specific zsh tweaks) are merged into the right configs. The role is stored
in the gitignored `.role` file at the repository root.

| Role      | Overlay source                                                                  |
| --------- | ------------------------------------------------------------------------------- |
| `private` | `config/<tool>/<file>.private.<ext>` (in this repo, git-tracked)                |
| `work`    | `~/ghq/github.com/<owner>/<name>/config-overlays/<tool>/<file>` (external repo) |

```bash
dot role set private
dot role set work repo=<owner>/<name>

dot role get          # print the current role
dot role get repo     # print the repo (work only)
dot role overlay config/zsh/.zshrc   # print the overlay path for a given file
```

Tools that consume the role:

- `config/zsh/.zshenv` and `.zshrc` source role overlays via symlinks at
  `~/.config/zsh/.zshenv.overlay` / `~/.config/zsh/.zshrc.overlay`. The
  symlinks are created by `dot deploy`, so re-run it after changing the role.
- `config/claude/Makefile` merges role overlays into `settings.json` / `mcp-servers.json`.

### ✨ Updating

Run `dot refresh` to update the dotfiles and upgrade packages:

```bash
dot refresh
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

The `dot deploy` command reads the [`symlinks`](./symlinks) file and supports various options to customize the deployment process:

- Deploy only specified configs:
    ```bash
    dot deploy -t nvim,zsh
    ```
- Force deployment:
    ```bash
    dot deploy -f
    ```
- Dry run:
    ```bash
    dot deploy -f -t nvim -n
    ```
- Enable debug mode:
    ```bash
    dot deploy --debug
    ```
