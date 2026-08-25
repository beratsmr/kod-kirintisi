# Kod Kırıntısı

[![CI](https://github.com/KULLANICI_ADIN/kod-kirintisi/actions/workflows/ci.yml/badge.svg)](https://github.com/KULLANICI_ADIN/kod-kirintisi/actions/workflows/ci.yml)
![Swift 6](https://img.shields.io/badge/Swift-6.0-orange)
![iOS 18+](https://img.shields.io/badge/iOS-18%2B-blue)

**One Swift puzzle a day, on your Home Screen — no app launch required.**

Kod Kırıntısı puts a small Swift/algorithm question on your Home Screen every morning. You answer it with interactive widget buttons in about four seconds. Open the app only when you want the full explanation.

<!-- TODO: widget etkileşiminin ekran kaydını (GIF) buraya ekle — README'nin en etkili parçası bu olacak -->

## Why

Daily practice apps fail because opening them is the hard part. This one removes that step: the content lives where you already look. Fully offline, no account, no tracking, no ads — the app contains no networking code at all, and [`docs/PRIVACY.md`](docs/PRIVACY.md) lists exactly what is stored and where.

## Architecture

```
┌──────────────────────────────────────────────┐
│ App (SwiftUI)        Widget (WidgetKit)      │
│ Today · Archive      Interactive AppIntents  │
│ Stats · Settings     Control Center widget   │
└─────────────────┬────────────────────────────┘
                  │ Shared/ (App Group, Intents, DS)
┌─────────────────▼────────────────────────────┐
│ KodKirintisiCore — pure Swift, Foundation    │
│ only. Builds and tests on Linux.             │
│ Models · PuzzleBank · DailyPuzzleSelector    │
│ StreakCalculator · ProgressStore (actor)     │
└──────────────────────────────────────────────┘
```

All business logic lives in a platform-independent SPM package, so the test suite runs on Linux CI in seconds and the UI layer stays thin. Details in [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).

**Notable decisions**

- The daily puzzle is chosen by a **pure, deterministic function** (seeded SplitMix64 permutation over the day index) — the app and the widget compute the same answer independently, with no shared scheduler and no backend.
- The Xcode project is **generated from `project.yml`** with XcodeGen and is not committed, so there are no `.pbxproj` merge conflicts and the project layout is reviewable.
- **Zero third-party dependencies.** Apple frameworks only.
- Swift 6 language mode with `strict concurrency = complete`.

## Getting started

```bash
brew install xcodegen swiftlint swiftformat

swift test --package-path Core   # core logic — no Xcode needed
xcodegen generate                # produces KodKirintisi.xcodeproj
open KodKirintisi.xcodeproj
```

Full environment notes (including how to develop this without Xcode installed): [`docs/SETUP.md`](docs/SETUP.md)

## Documentation

| Doc | Contents |
|---|---|
| [`docs/SPEC.md`](docs/SPEC.md) | Product spec, MVP scope, content model |
| [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) | Layers, data flow, key components, test strategy |
| [`docs/SETUP.md`](docs/SETUP.md) | Toolchain, editor, CI, troubleshooting |
| [`docs/puzzles.schema.json`](docs/puzzles.schema.json) | JSON Schema for the puzzle bank |
| [`docs/PRIVACY.md`](docs/PRIVACY.md) | Privacy policy (EN/TR) and the filed App Store Connect answers |
| [`CLAUDE.md`](CLAUDE.md) | Engineering rules and build milestones |

## Contributing puzzles

Puzzles live in `Core/Sources/KodKirintisiCore/Resources/puzzles.json` and are validated by `PuzzleBankIntegrityTests` in CI. Append only — never reorder or delete, since the daily selection is derived from index positions.

## License

MIT
