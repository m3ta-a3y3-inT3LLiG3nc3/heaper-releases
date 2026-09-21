# Heaper desktop app

Download builds from [docs.heaper.de/download](https://docs.heaper.de/download) or [github.com/JanLunge/heaper-releases](https://github.com/JanLunge/heaper-releases). This project uses the Linux AppImage from the releases page.

## Linux

1. Get the AppImage that matches your CPU:
   - x64: `Heaper-<version>-x86_64.AppImage`
   - ARM64: `Heaper-<version>-arm64.AppImage`
2. Make it executable and launch:

```bash
chmod +x Heaper-*-x86_64.AppImage
./Heaper-*-x86_64.AppImage
```

AppImage needs FUSE (`fuse` package on Debian/Ubuntu, which provides `fusermount`). If FUSE is unavailable, run with `--appimage-extract-and-run` instead. On some sandboxed environments you may also need `--no-sandbox`.

## Other platforms

Windows installers/portable builds and macOS DMGs are on the same [releases](https://github.com/JanLunge/heaper-releases/releases) page. Android and iOS are listed on the [download page](https://docs.heaper.de/download).

## Self-hosted server

After you log in to a cloud account, add a self-hosted instance under **Settings → Heaps → Pull Heap** and enter the server IP or hostname. See [self-hosting](self-hosting.md).
