# dotfiles

![CI](https://github.com/fohte/dotfiles/actions/workflows/ci.yml/badge.svg)

[@fohte](https://github.com/fohte)'s personal dotfiles for macOS, Linux environments.

| Category | Tool | Configurations |
| --- | --- | --- |
| Editor | [Neovim](https://neovim.io) | [config/nvim](./config/nvim) |
...

## 🚀 Installation

clone repository and run `scripts/deploy`

```bash
git clone https://github.com/fohte/dotfiles ~/ghq/github.com/fohte/dotfiles && cd ~/ghq/github.com/fohte/dotfiles && scripts/deploy
```

you can deploy specified configs with `--tags` (`-t`) option:

```bash
scripts/deploy -t nvim,zsh
```

if you want to force deploy, you can use `--force` (`-f`) option:

```bash
scripts/deploy -f
```

if you want to dry run, you can use `--dry-run` (`-n`) option:

```bash
scripts/deploy -f -t nvim -n
```

### Upgrade

Run `refresh` command to upgrade blah, blah, blah...

```bash
refresh
```

and can deploy not symlinked files

```bash
scripts/deploy
```
