# OpenDock

Open-source project dock / launcher inspired by [Dockset](https://dockset.app/?v=0.2.2) — profiles and widgets scoped to OSS projects.

**License:** MIT (intended for this repository).

**Repository:** `JitseLambrichts/opendock`

---

## 1. Vision

### What Dockset is

[Dockset](https://dockset.app/?v=0.2.2) is a native **macOS** app for:

- **Native Dock profiles** — switch which apps/items sit in the system Dock
- **Custom Dock** — a separate dock surface with apps, folders, files, links, spacers, and widgets
- **Switch triggers** — menu bar, keyboard shortcut, trackpad swipe, Focus modes
- **Local-first** data with backup; distribution/licensing via Paddle (paid)

Dockset widgets lean personal and commercial: Stock, Calendar, Reminders, Now Playing, Weather, Focus Timer, Stripe, Sticky Note, Battery, Shortcut, Paddle, Watchlist, Shopify, Clock / World Clock, Stopwatch, Countdown, Alarm, Time Progress, Hydration, System Activity, AI Usage, Network Activity, AirDrop (Trash in 0.2.3).

### What we build

**OpenDock** reuses the *idea* (named profiles + pinned tiles + light status widgets), but aims it at **open-source projects**:

- Profiles are **per repo / project**, not per macOS Focus or lifestyle context
- Tiles are things OSS people live in: paths, GitHub issues/PRs, CI, docs, Discord/Matrix, scripts
- Status tiles track **engineering signals** (CI, PR, release), not Stripe/Shopify/stocks
- First-class goals: portable profiles, local storage, shareable “profile packs” for a project

We are **not** cloning the macOS Dock pixel-for-pixel.

---

## 2. Reference: Dockset feature inventory

Source: Dockset marketing / product surface around **v0.2.2** ([dockset.app](https://dockset.app/?v=0.2.2)). Use as a **toetslijst**, not a copy mandate.

| Area | Dockset has |
|------|-------------|
| Surfaces | Native Dock profiles; Custom Dock |
| Items | Apps, folders, files, links, spacers, widgets |
| Switching | Menu bar, shortcut, swipe, Focus |
| Data | Local-first + backup |
| Monetization | Paid (Paddle) |
| Widgets (examples) | Stock, Calendar, Reminders, Now Playing, Weather, Focus Timer, Stripe, Sticky Note, Battery, Shortcut, Paddle, Watchlist, Shopify, Clock, World Clock, Stopwatch, Countdown, Alarm, Time Progress, Hydration, System Activity, AI Usage, Network Activity, AirDrop (+ Trash in 0.2.3) |

---

## 3. Scope v1

### Must-have

- **Named profiles** (e.g. one profile per OSS repo or workstream)
- **Pinned items**: links, local paths, runnable commands/scripts
- **Profile switch** (UI + simple shortcut; exact OS later)
- **Local storage** + **export / import** of a profile
- **Minimal status tiles** (e.g. static or polled “CI / open PRs” placeholder) + **spacers**

### Nice-to-have

- Auto-switch (e.g. when a folder / git repo becomes active)
- Live CI / PR widgets (GitHub Actions, open PR count, failing checks)
- Themes / visual polish
- Gestures (where the host OS allows)
- **Shareable profile packs** (check into the project repo, or publish as a gist/pack)

### Out of scope (v1 and generally for this product direction)

- Pixel-perfect / Liquid Glass macOS Dock clone
- Business / commerce widgets (Stripe, Shopify, Paddle dashboard, stock tickers)
- Deep WidgetKit / Focus Mode integration as a product dependency
- Paid license server or account-gated cloud sync
- Replacing the IDE or the full GitHub web UI

---

## 4. Feature matrix: Dockset → OpenDock (OSS)

| Dockset | OpenDock (planned) |
|---------|------------------------|
| Native Dock profiles | Optional later; **not** v1 must-have |
| Custom Dock | Primary surface: **project dock** |
| Apps / folders / files | Paths into the checkout, docs, tools |
| Links | Repo, docs site, Discord, CI dashboard, RFCs |
| Spacers | Spacers |
| Switch via menu / shortcut / swipe / Focus | Switch via UI + shortcut; auto-switch = nice |
| Local-first + backup | Local storage + export/import (+ packs) |
| Paddle / paid | **MIT**, no license server |
| Stock / Stripe / Shopify / Paddle widgets | **No** — out of scope |
| Calendar / Reminders / Weather / Hydration / … | **No** as core; not the product focus |
| System / Network / Battery / Now Playing | Maybe later as host OS helpers; not v1 |
| Focus Timer / Clock / Stopwatch / … | Nice later; not v1 |
| AI Usage | Optional later if it maps to real OSS tooling |
| (gap in Dockset) | **CI status**, **open issues/PRs**, **release/tag**, **script runners** |

---

## 5. Non-goals

1. **No** pixel-perfect macOS Dock / Liquid Glass remake  
2. **No** Stripe, Shopify, Paddle, or other commerce dashboards as first-class widgets  
3. **No** paid license server, seat management, or required cloud account  
4. **No** claim that OpenDock replaces GitHub, your IDE, or your terminal  
5. **No** “download any random SaaS widget pack” product — profiles stay project-scoped and portable

---

## 6. Working assumptions (open decisions)

- Host platform for v1 is **native macOS 14+**, Swift + SwiftUI. `OpenDockCore` is **Foundation-only** (no AppKit/SwiftUI) so models and storage build and test on Linux CI as well as on a Mac.
- GitHub is the default forge for status tiles; other forges can follow the same tile model.
- The SwiftUI menu-bar app lives in `App/OpenDock.xcodeproj` and depends on the local `OpenDockCore` package. Script runners, live CI widgets, and global keyboard shortcuts are still later.

---

## 7. Definition of done for *this* bootstrap

- Public repo `JitseLambrichts/opendock` with this `PROJECT.MD`
- Vision, Dockset reference, v1 scope, feature matrix, and non-goals are written down
- Swift package with library target `OpenDockCore` and test target `OpenDockCoreTests`
- Unit tests cover Codable round-trip, seed-on-missing-file, profile/tile mutations, and atomic persist
- GitHub Actions runs `swift test` on Ubuntu (installing Swift) and on macOS, and `xcodebuild`s `App/OpenDock.xcodeproj` on macOS
- Menu-bar accessory app: switch profiles, floating dock panel, open link/path tiles, add/remove profiles and tiles without editing JSON by hand

---

*Inspired by Dockset; OpenDock is an independent open-source direction, not affiliated with Dockset.*
