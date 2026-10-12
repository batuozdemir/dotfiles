# dotfiles

The chezmoi source tree for the shell and tmux config of the managed Linux fleet
(`general-lxc`, `phora-lxc`, the VPSes and every box the bootstrap pipeline builds). It is
its own git repo (remote: a private GitHub repo named dotfiles) and the single source
for those files. Split out of `script-server-bootstrap` on 2026-09-02; the copy left there
is frozen.

status: stable; last fleet change 4aa7f74 (global git ignore `~/.config/git/ignore`, applied to phora-lxc only on 2026-10-12; other hosts get it with their next apply), before it 6a1b715 (tmux global env drops cmux's `CMUX_TUI_*` vars, applied to the fleet 2026-10-09); cleanup of host drift is infra backlog #120; only open item is Batu's own Groq key rotation, which the assistant never chases; see README "Open work"

## Rules that cause harm if unknown

- No secret ever enters this repo: not API keys, not tokens, not machine-local values.
  Machine-specific lines go to a `local.zsh` file in the host's zsh config directory, the
  zsh-ai key to a `zsh-ai.local.zsh` file there (mode 0600), on the host, never here.
- Managed files are never edited on a host. A change wanted on more than one machine goes
  into this repo and arrives with `chezmoi update`. Run `chezmoi diff` before every
  `chezmoi apply`, and prefer applying a single target (`chezmoi apply <path>`) when other
  drift is pending: the 2026-10-09 tmux change was applied only to the tmux config file
  for that reason.
- Linux-only lines go behind `{{ if eq .chezmoi.os "linux" }}` or a `command -v` guard.
- `dot_config/zsh/dot_zshrc.tmpl` has a load-bearing order (tmux above the p10k instant
  prompt, `exports.zsh` before Oh My Zsh, zoxide after exports, syntax-highlighting last).
  Do not reorder; the comment block at the top of that file says why.
- Test key files for presence, never print values (bootstrap PLAN.md §4: the rail holds
  only if the assistant tests for presence instead of printing; the Mac's
  `~/.config/zsh/exports.zsh` is the last place with inline keys). The Groq key rotation is Batu's to time: the standing
  directive (2026-09-02) is that the assistant does not remind him again, so it never
  becomes a reminder or an agenda item.
- Traps (2026-10-09, cmux 0.65 switch): the scraper and flicker hosts carry a copied
  chezmoi source with an empty `.git` and no remote, so `chezmoi git pull` fails there and
  an apply would revert hand-added lines. Do not apply to them until their sources are
  adopted as real clones. pve is not chezmoi-managed.
- Traps (2026-10-12, global git ignore): edit and push from this Mac clone only; the hosts'
  sources are pull-only (no GitHub write credentials there: `Permission denied (publickey)`),
  and a commit made on a host forks this clone from GitHub. `chezmoi apply <file>` fails with
  `stat ...: no such file or directory` when the parent directory is missing on the host:
  apply the parent (`chezmoi apply ~/.config/git`). The sandbox denies writes under this
  repo's `.git`, so fetch, commit and push need a one-off sandbox escape.
- Scope (`minimal | lean | standard | full`) is chosen at `chezmoi init` and gates Oh My
  Zsh, p10k and tmux. Do not assume tmux exists on a `minimal` or `lean` box.

## Before doing X, read Y

- Changing or applying anything: `README.md` (what chezmoi source names map to, the scope
  variable, how to apply non-interactively).
- Rotating or touching any Groq or zsh-ai key, or the fleet Vault recipe: `README.md`
  "Open work", and `projects/bootstrap/ansible/VAULT.md`. Names only, never values.
- Anything about how cmux and tmux interact on the fleet: `tools/cmux/README.md` section 14
  "Decision and switch".
- A dotfiles manager for `tools/` itself (someday, not decided): `README.md` "Open work".
