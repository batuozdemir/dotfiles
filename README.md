# dotfiles — the chezmoi source tree

This repo is a **chezmoi source tree**: the *source* versions of the shell and tmux
config that chezmoi lays down into a user's home directory. It is the single source
for every managed machine (`general-lxc`, `phora-lxc`, and each box the bootstrap
pipeline builds). Nothing here is security-sensitive; **no secret ever enters this
repo** (see "zsh-ai API key" below).

History: split out of `script-server-bootstrap/dotfiles/` on 2026-09-02 with its
commits intact (`projects/bootstrap/PLAN.md`, decision 5 and §8.10). The copy left behind in
that repo is frozen; edit here.

## chezmoi in one minute

chezmoi maps funny source names to real dotfile paths in `$HOME`:

| source name here              | becomes in `$HOME`            |
|-------------------------------|-------------------------------|
| `dot_zshenv`                  | `~/.zshenv`                   |
| `dot_config/zsh/dot_zshrc.tmpl` | `~/.config/zsh/.zshrc` *(templated)* |
| `dot_config/zsh/aliases.zsh`  | `~/.config/zsh/aliases.zsh`   |
| `dot_config/zsh/dot_p10k.zsh` | `~/.config/zsh/.p10k.zsh` (managed since 2026-09-02) |
| `dot_config/tmux/tmux.conf.tmpl` | `~/.config/tmux/tmux.conf` *(templated)* |
| `dot_config/zsh/mac.zsh`      | `~/.config/zsh/mac.zsh` (macOS only, loaded last) |
| `dot_config/zsh/dot_zprofile` | `~/.config/zsh/.zprofile` (macOS only: Homebrew's PATH) |

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
  lightweight Alpine LXC path. Skips `uv` (no Python toolchain by default) and
  reuses a distro-provided `fzf`.
- **standard / full** — adds Oh My Zsh + p10k + plugins + tmux/TPM/catppuccin.

(`full` shell == `standard` shell; the server extras that `full` adds — Docker,
Netdata — live in Ansible roles, not here.)

Oh My Zsh lives at `~/.local/share/omz` (the XDG path) on every machine.

## Rules

- **Managed files are never edited on a host.** Machine-specific lines go in
  `~/.config/zsh/local.zsh` (not yet sourced; sourcing it fleet-wide waits until after
  the Mac move, first checking whether any host already has one) or, for
  the zsh-ai key, `~/.config/zsh/zsh-ai.local.zsh`. Anything wanted on more than one
  machine goes into this repo and arrives by `chezmoi update`.
- **Linux-only lines go behind `{{ if eq .chezmoi.os "linux" }}` or a `command -v`
  guard.** Mac-only lines go in `mac.zsh`, or a darwin block where they must load early.
  The new Mac (from 2026-11-12) uses the servers' XDG layout; the old Mac is never applied
  to (its data and caches live under `~/.config`).
- `chezmoi diff` before `chezmoi apply`, always.

## Proving the fleet is unchanged

Render the source before and after a change as Linux, for every scope, and compare.
Copy both trees, replace `.chezmoi.os` with `"linux"` and `lookPath "zsh"` with a fixed
path (it would resolve to the Mac's zsh), then per scope:

```bash
printf '[data]\n    scope = "standard"\n' > "$TMPDIR/c.toml"
chezmoi archive --source <copy> --config "$TMPDIR/c.toml" --persistent-state "$TMPDIR/st" \
  --format tar --destination /home/u > out.tar     # includes the run_onchange scripts
tar -tvf out.tar   # names and modes; extract both and `diff -r` the contents
```

Any changed byte in a rendered `run_onchange_` script re-runs it on every host at the next
apply. The Mac side is tested by `chezmoi apply --destination <empty dir> --exclude=scripts`
and `env -i HOME=<dir> zsh -lic ...` (without `env -i` the session's `ZDOTDIR` loads the
real config instead).

## Apply it

```bash
# by hand, prompting for scope:
chezmoi init --apply <git-url>          # or: --source /path/to/this/checkout
chezmoi diff                            # preview what would change next time

# non-interactively (this is what the Ansible `dotfiles` role does):
DOTFILES_SCOPE=standard chezmoi init --apply <git-url>
```

`DOTFILES_SCOPE` is checked *first* by `.chezmoi.toml.tmpl`; the interactive prompt
only appears when it is unset and stdin is a TTY. The git URL is the private remote
Batu creates; the pipeline's `dotfiles` role passes it as `dotfiles_repo`.

## ★ The load-bearing bit

`dot_config/zsh/dot_zshrc.tmpl` preserves an exact ordering (tmux above p10k
instant-prompt; `exports.zsh` before Oh My Zsh; zoxide after exports;
syntax-highlighting dead last). The comment block at the top of that file explains
why — don't reorder.

## Open work

- **Groq API key rotation (Batu's timing).** Three Groq keys are due for rotation. Batu's
  directive of 2026-09-02, kept verbatim: "Batu'nun zamanlaması; asistan bir daha
  hatırlatmayacak (2026-09-02 direktifi)". So never remind him and never turn it into a
  reminder or an agenda item. Where the keys live, by name only: `zsh_ai_openai_api_key`,
  in plaintext, in
  `archive/script-server-bootstrap-2026-09-03/ansible/inventory/group_vars/all.yml`; on the
  Mac, `GROQ_API_KEY` and `ZSH_AI_OPENAI_API_KEY` were in `~/.config/zsh/exports.zsh` on
  2026-09-02, but measured 2026-11-12 (variable names only) that file holds neither and
  `local.zsh` / `zsh-ai.local.zsh` do not exist; where the Mac's keys live now is not
  measured. All three landed in a transcript on 2026-09-02. After the rotation: on the
  Mac, the new key goes to `zsh-ai.local.zsh` (mode 0600); on the
  fleet, move it into Ansible Vault following the `projects/bootstrap/ansible/VAULT.md`
  recipe and delete it from the archived group vars file named above. Measured 2026-10-10: this repo's `dot_config/zsh/exports.zsh` contains none
  of these variable names (`grep -c` = 0), so nothing here needs a change. Never open,
  print or grep the values of any key file.
- **Someday:** decide whether `tools/` gets a dotfiles manager (chezmoi or stow) of its
  own, once the manual deploy-script juggling starts to hurt.
- **Stale text:** the intro points to a "zsh-ai API key" section that no longer exists
  (zsh-ai was removed from the fleet in commit `00afdc0`). Left as is; fix when the
  README is next edited for another reason.


<!-- path-lint-exempt: script-server-bootstrap/dotfiles/ ~/.config/zsh/mac.zsh ~/.local/share/omz ~/.config/zsh/local.zsh ~/.config/zsh/zsh-ai.local.zsh -->
<!-- Exempt: the retired repo's old folder (history); paths on the new Mac or the fleet hosts, absent on this Mac by design. -->
