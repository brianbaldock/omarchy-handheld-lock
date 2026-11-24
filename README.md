# Handheld Lock

A touch-friendly replacement for the Omarchy lock screen. Tap **Show keyboard** to type your password on the secure lock surface, or tap **Use fingerprint** to arm the reader for a single attempt. The reader stays idle until you ask for it. A miss or a 15-second timeout returns you to password entry; a device error pauses fingerprint attempts for 30 seconds. A physical keyboard continues to work.

## Requirements

Tested with Omarchy 4.0.6, its Quickshell Wayland locker, and the existing `omarchy-lock-password` PAM service. Fingerprint unlock is optional and uses Omarchy's `omarchy-lock-fingerprint` PAM service, `fprintd`, a supported reader, and an enrolled fingerprint. The plugin does not configure PAM, enroll fingerprints, or require sudo. Neither Game Mode nor a separate desktop keyboard is required. The touch keyboard provides US letters, digits, spaces, and ASCII punctuation; use a physical keyboard for other characters.

## Install

Plugins run inside the desktop shell as your user. Review the code before enabling it, especially because this one handles password input. **Switch lock plugins only while unlocked**, with a physical keyboard available for your first test.

From a committed local checkout, install without enabling:

```sh
omarchy plugin validate .
omarchy plugin add "$PWD" --yes
```

For a published copy, use `omarchy plugin add` with the public Git repository URL instead. Choose **No** if asked whether to enable it immediately. If another third-party lock replacement is active, first switch back to the stock locker with `omarchy plugin enable omarchy.lock`. Then:

```sh
omarchy plugin enable handheld.lock
omarchy shell lock status
```

Check that `passwordPam` is `true` before trying a lock. This replaces the built-in lock service; it does not change your idle timeout, login screen, or disk-encryption prompt.

## Update and remove

For a Git-managed installation, run `omarchy plugin update handheld.lock` while unlocked and review the diff. To restore the stock locker and then remove the plugin:

```sh
omarchy plugin enable omarchy.lock
omarchy shell lock status
omarchy plugin remove handheld.lock
```

## Build and publish

QML is loaded directly: installation needs no compilation or install hook. `make dist` validates the plugin and produces a versioned source archive and SHA-256 checksum in `dist/`.

For a [marketplace listing](https://plugins.omarchy.org/publish.html), publish **one plugin per public GitHub repository**, with `manifest.json`, `README.md`, and `LICENSE` at its root. The plugin ID `handheld.lock` is intended to be permanent. Submit the repository root URL through the [official issue form](https://github.com/omacom/omarchy-plugin-marketplace/issues/new?template=submit-plugin.yml). Suggested category: **System**; tags: **Quickshell**, **Security**. A preview is optional. The marketplace checks the submitted commit and a maintainer approves the listing; this is not a security audit.

## Credits and license

Maintained by **brianbaldock**. The lock service and password view are derived from [Omarchy's built-in locker](https://github.com/omacom/omarchy/tree/quattro/shell/plugins/lock). The embedded touch keyboard and opt-in fingerprint controls are community additions. Distributed under the [MIT license](LICENSE).
