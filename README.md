# Fablia Desktop

Desktop app for [Fablia](https://fablia.fr), the AI-enhanced interactive story platform.
It is a thin Electron shell around fablia.fr: same account, same stories, plus a native window,
single-instance handling, an offline screen and automatic updates.

## Install

| Platform | Command |
|----------|---------|
| Windows (winget) | `winget install Volko61.Fablia` |
| Windows (Store) | search "Fablia" in the Microsoft Store |
| Linux (curl) | `curl -fsSL https://raw.githubusercontent.com/Volko61/Fablia-Desktop/main/install.sh \| sh` |
| Linux (wget) | `wget -qO- https://raw.githubusercontent.com/Volko61/Fablia-Desktop/main/install.sh \| sh` |

x64 and arm64 are supported on both systems. Installers and checksums are on the
[releases page](https://github.com/Volko61/Fablia-Desktop/releases).

## Updates

* **Windows installer / Linux AppImage**: the app checks GitHub releases at startup and offers to restart once the update is downloaded.
* **winget**: `winget upgrade Volko61.Fablia`
* **Microsoft Store**: updated by the Store.
* **Linux script**: re-run the install command (it exits immediately if you are up to date).
  Remove with `... | sh -s -- --uninstall`. Pin a version with `FABLIA_VERSION=0.1.0`.

## Development

```bash
npm install
npm start          # run the app
npm run icons      # regenerate Store tile images from build/icon.png
npm run dist       # build packages for the current OS into dist/
```

Releasing: bump `version` in `package.json`, then `git tag vX.Y.Z && git push --tags`.
The workflow builds everything, publishes the GitHub release and updates winget.

### Microsoft Store setup

Set three repository variables (Settings > Secrets and variables > Actions > Variables) with the values
from Partner Center > Product management > Product identity: `APPX_IDENTITY_NAME`, `APPX_PUBLISHER`
(the `CN=...` string) and `APPX_PUBLISHER_DISPLAY_NAME`. Then upload the `Fablia-*.appx` files from the
release to your Store submission. The Store signs the package itself.

## License

MIT

Store listing: https://apps.microsoft.com/detail/9NKCGS852X4D
