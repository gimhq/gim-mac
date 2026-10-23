# gim-mac

Native macOS client for gim: Swift 6, SwiftUI, macOS 15, bundle id `im.g.mac`. The client logic comes from `GIMKit`
(`GIMClientKit`, `GIMFeatures`), shared with gim-ios by path.

## Layout

- `GIM/Sources/App` app entry, `AppModel`, scenes and menu commands
- `GIM/Sources/Platform` platform hooks (Keychain, data directory, reachability) and client factory selection
- `GIM/Sources/Sidebar`, `GIM/Sources/Shared` chat list and shared UI (later workstreams)
- `GIM/Sources/Onboarding`, `GIM/Sources/Chat`, `GIM/Sources/Settings` one directory per feature
- `GIM/Resources` asset catalog and one String Catalog per feature, used as tables (`App`, `Onboarding`, `Chat`,
  `Settings`)
- `GIM/Tests` unit tests (`GIMTests`)
- `scripts/` the Mac gate
- `docs/` plans and tasks
- `docs/glossary.md` — the user-facing words and writing rules every string table follows.

## Build

```sh
xcodegen generate
open GIM.xcodeproj
```

`project.yml` references `GIMKit` at `../gim-ios/Packages/GIMKit`, so gim-ios must be checked out next to gim-mac.

## Demo mode

The fake client (`FakeGimClient`) is the only mode today: the app starts without a session and onboarding signs in
as a demo user with sample chats. GIMCore follows contract C5 behind the same `GimClientFactory` seam.

## Default server

The app uses the last used server, else the `-GIMDefaultServerURL <url>` launch argument, else the
`GIM_DEFAULT_SERVER_URL` build setting (Debug: `http://localhost:8080`, Release: `https://hub.g.im`), else the built-in
`https://hub.g.im`.

## Refreshing gim-core

`Vendor/GIMCore` is the `GIMCore` Swift package built by gim-client-sdk CI (Package.swift, `GIMCore.xcframework.zip`
with its `.sha256`, generated `Sources/GIMCore/GIMCore.swift`). Pick a green `CI` run on gim-client-sdk `main`
(`gh run list -R gimhq/gim-client-sdk --branch main --workflow CI`), then:

```sh
scripts/sync-gim-core.sh <gim-client-sdk CI run id>
scripts/sync-gim-core.sh --from-dir <dir> --core-sha <gim-client-sdk sha>
```

The first form downloads the `gim-core-ios-<sha>` artifact with `gh`; the second takes a directory with the same
layout. The script verifies the zip against its `.sha256`, replaces `Vendor/GIMCore` with the artifact as is and
writes `Vendor/GIMCore/GIM_CORE_VERSION` (`<core version>+<short sha>`). The zip is committed; commit the whole
directory.

## Mac gate

```sh
scripts/mac-gate.sh build-test [--sha <commit>] [--keep]
```

Runs from station against the shared Mac build host (`GIM_MAC_HOST`, default `a@100.99.1.8`): ships `git archive` of
the commit (default `HEAD`, clean tree required) to `~/gim-ci/<id>-<short sha>/gim-mac/` (`GIM_GATE_ID`, default the
branch name's last component) and `Packages/GIMKit` of gim-ios (`GIM_IOS_REPO`, default `/srv/gimhq/gim-ios`;
`GIM_IOS_REF`, default `HEAD`) to `~/gim-ci/<id>-<short sha>/gim-ios/`, takes the `~/gim-ci/.lock-xcode` lock, then
runs `xcodegen generate`, `xcodebuild build`, `xcodebuild test` (GIMTests) and `swift test` of GIMKit. Logs and zipped
xcresult bundles land in `.tmp/mac/<short sha>/`; the last line is the
`[mac-gate] mode=build-test sha=<short> ios=<gim-ios short> build=ok|fail app-tests=ok|fail kit=ok|fail` summary. The
Mac work dir is kept on failure or with `--keep`.
