# Handheld Lock

Unlock an Omarchy handheld or tablet without attaching a keyboard. **Handheld Lock** adds a password keyboard directly to the secure lock screen and lets you start a fingerprint scan with a tap. It does not launch a desktop keyboard over the lock or leave the fingerprint reader continuously scanning.

This is an independent community plugin (`handheld.lock`) for the **session lock**. It does not change the login screen, disk-encryption prompt, idle timeout, or authentication for `sudo`. Omarchy Game Mode is not required.

## Requirements

| Feature | What you need |
| --- | --- |
| Session lock and touch-password entry | Omarchy Quattro with the Quickshell Wayland locker and its working `omarchy-lock-password` PAM service. Tested on Omarchy **4.0.6**. |
| Fingerprint unlock (optional) | A reader supported by `fprintd`/`libfprint`, a fingerprint enrolled for your account, and Omarchy's `omarchy-lock-fingerprint` PAM service. |
| Build a release archive (optional) | `make`, `jq`, GNU `tar`, `sha256sum`, and the Omarchy plugin validator. No build step is required to install. |

The plugin does not install drivers, edit PAM policies, export fingerprint templates, or enroll fingers. You can use the touch password keyboard without fingerprint hardware or an external on-screen keyboard.

## Install

**Install and switch lockers only while unlocked.** Before the first test, confirm you know your account password and keep a physical keyboard available. Like other Omarchy plugins, this code runs unsandboxed inside the shell as your user. Because it handles password input, review the code before enabling it.

1. Add the public repository. Accept the clone prompt and answer **No** to enabling it immediately:

   ```sh
   omarchy plugin add https://github.com/brianbaldock/omarchy-handheld-lock.git
   ```

2. If another third-party replacement is active, first run `omarchy plugin enable omarchy.lock` to restore the stock locker. Then enable Handheld Lock and check the service:

   ```sh
   omarchy plugin enable handheld.lock
   omarchy shell lock status
   ```

3. Before locking, check that the status reports `passwordPam: true`. If it does not, **do not test a lock**; restore the stock locker below. Otherwise use your normal lock action and try touch-password entry first. Test fingerprint unlock on a subsequent lock if configured.

## Using the lock screen

| Control | Behavior |
| --- | --- |
| **Show keyboard** | Opens the keyboard inside the lock surface. **Shift** capitalizes the next letter, **#+=** opens punctuation, **ABC** returns to letters, and **Enter** submits. **Hide keyboard** closes it. A physical keyboard still works. |
| **Use fingerprint** or the fingerprint icon | Arms the reader for up to **15 seconds**. Touch the **physical sensor** when prompted. A match unlocks the session; tapping the icon alone never authenticates. |
| **Cancel scan** or password entry | Cancels the scan and leaves password authentication available. A missed or expired scan does not rearm itself; tap **Try again** for another attempt. |
| **Reader unavailable / cooling down** | Device errors pause fingerprint attempts for **30 seconds**. You can type the password immediately instead of waiting. |

The embedded keyboard supports US letters, digits, spaces, and printable ASCII punctuation. If your password contains other characters, keep a keyboard with the appropriate layout available.

## Update and remove

While **unlocked**, run `omarchy plugin update handheld.lock` and review the diff before accepting. To roll back, restore the stock locker first:

```sh
omarchy plugin enable omarchy.lock
omarchy shell lock status
```

After confirming that the stock service responds and `passwordPam` is `true`, run `omarchy plugin remove handheld.lock` if you also want to uninstall it. No PAM or driver changes need to be undone.

## Troubleshooting

- **No fingerprint button:** Check `omarchy shell lock status`. The `fingerprint` flag indicates that the fingerprint PAM configuration file is available, **not** that the sensor is healthy or that enrollment was verified. Complete Omarchy's fingerprint setup separately if you want to use it.
- **A scan fails or times out:** Use the password, then check `fprintd-list "$USER"` in your unlocked graphical session. For reader errors, inspect `journalctl -b -u fprintd.service`. A generic error may not distinguish an unplugged reader from a driver cooldown.
- **No Show keyboard button:** Run `omarchy plugin list` while unlocked and confirm `handheld.lock` is enabled. The desktop bar's keyboard toggle is not used. If you are at the boot or login prompt, this session plugin is not running there.
- **Reporting an issue:** Include the Omarchy and plugin versions, which control you tapped, and any relevant error text. Do not post passwords, fingerprint data, or unredacted authentication logs.

## Build and verify a release

The repository is the installable plugin: `manifest.json` and the QML files live at its root. For development or offline inspection:

```sh
git clone https://github.com/brianbaldock/omarchy-handheld-lock.git
cd omarchy-handheld-lock
make dist
(cd dist && sha256sum -c omarchy-handheld-lock-*.tar.gz.sha256)
```

`make dist` runs `omarchy plugin validate .` and writes a versioned source archive and checksum to `dist/`. To inspect a specific published version, see [GitHub Releases](https://github.com/brianbaldock/omarchy-handheld-lock/releases). There is no executable install hook and installation needs no sudo.

For maintainers, the [marketplace submission guide](https://github.com/omacom/omarchy-plugin-marketplace/blob/HEAD/SUBMISSION.md) describes listing and re-verifying releases. Marketplace approval is not a security audit.

## Credits and license

Maintained by **brianbaldock**. The lock service and password view are derived from [Omarchy's built-in locker](https://github.com/omacom/omarchy/tree/quattro/shell/plugins/lock). The embedded touch keyboard and opt-in fingerprint controls are community additions. Distributed under the [MIT license](LICENSE).
