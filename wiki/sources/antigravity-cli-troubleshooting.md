---
type: source
title: "Antigravity CLI — Troubleshooting"
source: https://antigravity.google/docs/cli-troubleshooting
slug: antigravity-cli-troubleshooting
section: Antigravity CLI
fetched: 2026-06-08
confidence: high
raw: .raw/antigravity-cli/cli-troubleshooting.md
---

# Troubleshooting

Diagnose and resolve installation PATH issues, self-updater locks, keyring permissions, and SSH clipboard forwarding.

## Quick reference

| Error | Likely cause | Resolution |
|---|---|---|
| `agy: command not found` | Binary dir not in shell `$PATH` | [Configure shell PATH](#configure-your-shell-path) |
| `keyring: secure lock out` | Daemon locked or headless | [Authorize keyring](#authorize-keyring-permissions) |
| `SSH Clipboard paste failures` | Protocol streams blocked | [Enable clipboard forwarding](#enable-emulator-clipboard-forwarding) |
| `Advisory lock / update failures` | Stuck self-updater, read-only path | [Resolve updater locks](#resolve-self-updater-locks-and-failures) |

---

## Configure your shell PATH

**Symptom**: `bash: agy: command not found`

**Cause**: binary installed to `~/.local/bin` (or `C:\Users\<Username>\AppData\Local\agy\bin`) but shell `$PATH` doesn't index it.

**macOS/Linux** — append to `~/.bashrc` or `~/.zshrc`:
```bash
export PATH="~/.local/bin:$PATH"
source ~/.zshrc
```

**Windows (PowerShell, Admin)**:
```powershell
[System.Environment]::SetEnvironmentVariable("Path", [System.Environment]::GetEnvironmentVariable("Path", "User") + ";C:\Program Files\Google\antigravity-cli", "User")
```

---

## Authorize keyring permissions

**Symptom**: CLI hangs, DBUS warnings, `Error: failed to retrieve token: secret keyring is locked`.

**Cause**: Antigravity uses Apple Keychain / Linux secret-service (dbus) / Windows Credential Manager. If daemon is locked or headless, tokens can't be read.

**macOS**:
1. Open **Keychain Access**, search for `Antigravity CLI`.
2. Get Info → Access Control tab → verify `agy` is allowed.
3. Headless SSH unlock:
   ```bash
   security unlock-keychain -p "your_keychain_password" login.keychain
   ```

**Linux**:
- Ensure GNOME Keyring / KWallet is unlocked and accessible.
- Headless/SSH: initialize D-Bus:
  ```bash
  export $(dbus-launch)
  ```

---

## Enable emulator clipboard forwarding

**Symptom**: `Ctrl+V` over SSH returns `local pasteboard is empty or unreachable over SSH connection`.

**Cause**: standard SSH doesn't forward graphical clipboards.

**Resolution**:
1. Use **iTerm2** or **Ghostty** (advanced clip channels).
2. **iTerm2 forwarding**: Preferences (`Cmd+,`) → General → Selection → check "Applications in terminal may access clipboard" (OSC 52 write).
3. **tmux bypass**:
   ```text
   set -s set-clipboard on
   ```

---

## Resolve self-updater locks and failures

**Symptom**: `agy` hangs, fails to upgrade, or returns `Warning: another background updater process is already active (update.lock)`.

**Cause**: native self-updater uses 15-min TTL debounce (`last_check.timestamp`) + advisory lock (`update.lock`) in `~/.gemini/antigravity-cli/updater/`. Crashed/hung updater blocks subsequent updates.

**Resolution**:
- **Release lock**:
  ```bash
  rm -f ~/.gemini/antigravity-cli/updater/update.lock
  ```
- **Disable auto-updates** (in `~/.bashrc` or `~/.zshrc`):
  ```bash
  export AGY_CLI_DISABLE_AUTO_UPDATE=true
  ```
- **Verify write permissions** on `~/.local/bin/` (Unix) or `%LOCALAPPDATA%\agy\bin` (Windows).

---

## See also

- [CLI Reference](./antigravity-cli-reference.md)
- [Permissions](./antigravity-cli-permissions.md)
- [Sandbox](./antigravity-cli-sandbox.md)
- [Plugins & Skills](./antigravity-cli-plugins.md)
