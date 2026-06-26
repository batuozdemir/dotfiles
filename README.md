# dotfiles/ — the chezmoi source tree (Phases 6–7)

This folder is a **chezmoi source tree**: it holds the *source* versions of the
shell/tmux config that get laid down into a user's home directory. It replaces
Phases 6–7 of `bootstrap.sh` (the zsh + Oh My Zsh + tmux part). Nothing here is
security-sensitive.

## chezmoi in one minute

chezmoi maps funny source names to real dotfile paths in `$HOME`:

| source name here              | becomes in `$HOME`            |
|-------------------------------|-------------------------------|
| `dot_zshenv`                  | `~/.zshenv`                   |
| `dot_config/zsh/dot_zshrc.tmpl` | `~/.config/zsh/.zshrc` *(templated)* |
| `dot_config/zsh/aliases.zsh`  | `~/.config/zsh/aliases.zsh`   |
| `dot_config/tmux/tmux.conf`   | `~/.config/tmux/tmux.conf`    |

- `dot_` → a leading `.`  ·  `.tmpl` → the file is a Go template (gets rendered).
- `run_onchange_*.sh.tmpl` → a script chezmoi runs, but **only when its rendered
  contents change** (so installing tools/plugins happens once, not every apply).
  `before_`/`after_` control whether it runs before or after files are written;
  the `NN-` number just sets the order among scripts.

## The one variable: `scope`

`scope` = `minimal | standard | full`, the same knob as bootstrap's
`--minimal/--standard/--full`. It's chosen at `chezmoi init` time (see
`.chezmoi.toml.tmpl`) and gates:

- **minimal** — zsh + modern CLI tools (zoxide/fzf/uv/bat/fd) only. No Oh My Zsh,
  no powerlevel10k, no tmux. The `.zshrc` is rendered lean (no OMZ block).
- **standard / full** — adds Oh My Zsh + p10k + plugins + tmux/TPM/catppuccin.

(`full` shell == `standard` shell; the server extras that `--full` adds — Docker,
Netdata — live in Ansible roles, not in dotfiles.)

## Try it by hand (interactive)

```bash
# point chezmoi at THIS folder and apply to your home, prompting for scope:
chezmoi init --apply --source /path/to/script-server-bootstrap/dotfiles
chezmoi diff       # preview what would change next time
```

## How it's applied in the pipeline

The Ansible `dotfiles` role (`ansible/roles/dotfiles/`) does it non-interactively:
installs chezmoi, copies this tree to the target user's
`~/.local/share/chezmoi`, runs `chezmoi init` with `DOTFILES_SCOPE={{ scope }}`,
then `chezmoi apply`, then sets zsh as the login shell.

## ★ The load-bearing bit

`dot_config/zsh/dot_zshrc.tmpl` preserves the exact ordering bootstrap.sh fought
for (tmux above p10k instant-prompt; zoxide after exports; syntax-highlighting
dead last). The comment block at the top of that file explains why — don't reorder.
