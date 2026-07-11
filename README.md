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

`scope` = `minimal | lean | standard | full`. It's chosen at `chezmoi init` time
(see `.chezmoi.toml.tmpl`) and gates:

- **minimal** — zsh + modern CLI tools (zoxide/fzf/uv/bat/fd) only. No Oh My Zsh,
  no powerlevel10k, no tmux. The `.zshrc` is rendered lean (no OMZ block).
- **lean** — minimal **plus** four small plugins sourced *directly* (no Oh My Zsh):
  `zsh-autosuggestions`, `fzf-tab`, `zsh-interactive-cd`, `zsh-syntax-highlighting`
  (cloned by `run_onchange_after_25-install-lean-plugins.sh.tmpl` into
  `$XDG_DATA_HOME/zsh/plugins`). Still no p10k/tmux. This is the default for the
  lightweight Alpine LXC path (`create-lxc.sh distro=alpine` → `ansible/alpine.yml`).
  Skips `uv` (no Python toolchain by default) and reuses a distro-provided `fzf`.
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

## zsh-ai API key

`dot_config/zsh/exports.zsh` sets the zsh-ai defaults for Groq's
OpenAI-compatible endpoint. The API key lives in
`~/.config/zsh/zsh-ai.local.zsh`, which `exports.zsh` sources if present.

For a one-off local Mac setup, create that file by hand:

```bash
mkdir -p ~/.config/zsh
printf 'export ZSH_AI_OPENAI_API_KEY=%q\n' 'paste-your-key-here' > ~/.config/zsh/zsh-ai.local.zsh
chmod 600 ~/.config/zsh/zsh-ai.local.zsh
```

For managed hosts, put the key in Ansible inventory so future deployments get
the file automatically. If you are okay storing this low-value key in your
private git repo, put it in the fleet defaults:

```bash
cd ansible
$EDITOR inventory/group_vars/all.yml
```

Set this variable:

```yaml
zsh_ai_openai_api_key: "paste-your-key-here"
```

Then run playbooks normally; no `--ask-vault-pass` is needed. The Debian
`dotfiles` role and Alpine `alpine_base` role will write
`~/.config/zsh/zsh-ai.local.zsh` with mode `0600`. Leave the variable undefined
on hosts that should not receive the key.

If you later decide the key should be protected, move the same variable into an
Ansible Vault file instead and run playbooks with `--ask-vault-pass`.

## ★ The load-bearing bit

`dot_config/zsh/dot_zshrc.tmpl` preserves the exact ordering bootstrap.sh fought
for (tmux above p10k instant-prompt; zoxide after exports; syntax-highlighting
dead last). The comment block at the top of that file explains why — don't reorder.
