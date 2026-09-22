# Heaper desktop app

This repository tracks Heaper desktop release artifacts and the bundled self-hosting compose setup. Use only the download sources and connection options that are actually published here:

- Official download page: [docs.heaper.de/download](https://docs.heaper.de/download)
- Upstream release artifacts: [github.com/JanLunge/heaper-releases/releases](https://github.com/JanLunge/heaper-releases/releases)

## Choose the right download

Prefer a stable release unless you intentionally want a nightly build for testing.

| Platform | Verified release artifacts | Notes |
| --- | --- | --- |
| Linux x64 | `Heaper-<version>-x86_64.AppImage` | Best choice for most Intel/AMD Linux desktops |
| Linux ARM64 | `Heaper-<version>-arm64.AppImage` | For ARM64 Linux systems |
| Windows x64 | `Heaper-<version>-x64-setup.exe`, `Heaper-<version>-x64-portable.exe` | Use the setup build for a normal install, or the portable build if you do not want an installed app |
| macOS Intel | `Heaper-<version>-x64.dmg`, `Heaper-<version>-x64.zip` | Choose the DMG first; keep the ZIP as a fallback archive |
| macOS Apple Silicon | `Heaper-<version>-arm64.dmg`, `Heaper-<version>-arm64.zip` | Choose the DMG first; keep the ZIP as a fallback archive |

## Linux AppImage setup

1. Download the AppImage that matches your CPU architecture.
2. Move it to a permanent location such as `~/Applications/`.
3. Make it executable and launch it.

### Linux x64

```bash
mkdir -p ~/Applications
mv ~/Downloads/Heaper-*-x86_64.AppImage ~/Applications/
chmod +x ~/Applications/Heaper-*-x86_64.AppImage
~/Applications/Heaper-*-x86_64.AppImage
```

### Linux ARM64

```bash
mkdir -p ~/Applications
mv ~/Downloads/Heaper-*-arm64.AppImage ~/Applications/
chmod +x ~/Applications/Heaper-*-arm64.AppImage
~/Applications/Heaper-*-arm64.AppImage
```

### FUSE prerequisite

AppImage usually needs FUSE support. Check for `fusermount` or `fusermount3` first:

```bash
command -v fusermount || command -v fusermount3 || echo "Install your distro's FUSE package before launching the AppImage."
```

Example for Debian/Ubuntu; install `fuse` plus the libfuse2 package name used by your release:

```bash
sudo apt update
sudo apt install -y fuse libfuse2
# On newer Ubuntu releases, replace libfuse2 with libfuse2t64 instead of installing both packages.
```

### If FUSE is unavailable

Run the AppImage without mounting it:

```bash
~/Applications/Heaper-*-x86_64.AppImage --appimage-extract-and-run
~/Applications/Heaper-*-arm64.AppImage --appimage-extract-and-run
```

### Common Linux troubleshooting

- **`Permission denied`**: run `chmod +x` again and make sure the file is not on a filesystem mounted with `noexec`.
- **FUSE error**: install the FUSE package for your distro or use `--appimage-extract-and-run`.
- **Sandbox error**: some restricted environments need:

  ```bash
  ~/Applications/Heaper-*-x86_64.AppImage --no-sandbox
  ```

- **Nothing opens from `Downloads`**: move the AppImage into a normal user-owned directory such as `~/Applications/` and launch it from there.

### Optional desktop integration

If your desktop environment does not offer to add the app automatically, you can create a launcher yourself:

```bash
mkdir -p ~/.local/share/applications
cat > ~/.local/share/applications/heaper.desktop <<'DESKTOP'
[Desktop Entry]
Type=Application
Name=Heaper
Exec=/home/YOUR_USER/Applications/Heaper-16.20.2-x86_64.AppImage
Terminal=false
Categories=Office;Utility;
DESKTOP
```

Replace the `Exec=` path with the actual location and filename you installed.

## Windows

Verified Windows release artifacts are x64 installer and portable EXE builds.

- `Heaper-<version>-x64-setup.exe`: normal installation flow
- `Heaper-<version>-x64-portable.exe`: unpack-and-run style portable build

Download from the release page, then:

1. Run the setup EXE if you want a standard install.
2. Or keep the portable EXE in a permanent folder and launch it directly.
3. If Windows SmartScreen warns, verify that the file came from the official release page before continuing.

## macOS

Verified macOS release artifacts are DMG and ZIP builds for both Intel and Apple Silicon.

- Use the DMG that matches your Mac first.
- Keep the ZIP build as a fallback archive if you need a manual extraction path.

Typical flow:

1. Download the matching `*.dmg`.
2. Open the DMG in Finder, then drag the Heaper app into `Applications` if the mounted window shows the usual app-and-Applications layout.
3. If macOS blocks first launch, use Finder's **Open** action on the app after verifying it came from the official release page.

## First launch and login

1. Start Heaper.
2. Sign in with your Heaper account.
3. If you want to use a self-hosted server, open **Settings → Heaps → Pull Heap** after login.

## Connect the desktop app to a self-hosted server

The bundled compose setup in this repository publishes Heaper on host port `3010`:

- Direct LAN/test access: `http://YOUR-SERVER:3010`
- Reverse-proxied access with TLS: `https://heaper.example.com`

Use the server hostname or IP address that the desktop machine can actually reach.

### What to enter in the desktop app

Under **Settings → Heaps → Pull Heap**:

- Use `http://hostname:3010` when you are connecting directly to the checked-in compose setup.
- Use your public HTTPS URL when a reverse proxy terminates TLS in front of Heaper.
- Do **not** append `:3010` when your reverse proxy already serves Heaper on `443`.

### TLS and reverse proxy expectations

- For local testing on a trusted network, direct HTTP on port `3010` is simplest.
- For internet-facing access, put Heaper behind a reverse proxy and use a valid TLS certificate.
- The desktop app should connect to the same hostname users see in the browser, not an internal Docker hostname.

### Practical connectivity checks

Run these from the desktop machine or another client on the same network:

```bash
curl http://YOUR-SERVER:3010/api
curl http://YOUR-SERVER:3010/sync/health

# If you use a reverse proxy with TLS instead:
curl https://heaper.example.com/api
curl https://heaper.example.com/sync/health
```

Expected results:

- `/api` should return an HTTP response from Heaper.
- `/sync/health` should report a healthy sync endpoint.

If those checks fail, fix routing/firewall/TLS first, then retry the desktop connection.

## Supported integration boundary

This repository only documents the desktop app downloads and the desktop-to-self-hosted-server connection that is supported by the checked-in compose file. For broader product integrations, use the authoritative upstream docs linked above.
