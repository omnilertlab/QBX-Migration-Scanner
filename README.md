# QBX Pre-Flight Breakage Scanner

![FiveM](https://img.shields.io/badge/FiveM-gta5-1b2a4a)
![QBox](https://img.shields.io/badge/QBox-qbx__core_1.24.1-7c5cff)
![ox_lib 3.42.2](https://img.shields.io/badge/ox__lib-3.42.2-3ddc84)
![lua54](https://img.shields.io/badge/lua-5.4-000080)
![License: MIT](https://img.shields.io/badge/License-MIT-green)

**Find out exactly what will break before you migrate from QBCore to QBox.**

QBCore is dead — Cfx.re removed it from txAdmin on 29 Oct 2026 and the project rebranded to Mantle (an Unreal Engine 5 platform). QBox's bridge runs *most* QBCore scripts unchanged, so the danger isn't a clean break — it's the quiet rot: scripts that silently stop working, and player data that simply doesn't carry over. `qbx_scanner` reads every resource on your server and flags the QBCore patterns QBox does not support, with file + line numbers and a plain-English fix hint for every issue.

This is the **free** scanner. It tells you what is broken — it does not fix anything. The fix is the Full Migration Toolkit (below).

## What it scans — 26 patterns

- **Core:** `exports['qb-core']`, `QBCore.Functions`, `QBCore.Shared`, `GetCoreObject`, `QBCore:Server:` / `qb-core:server:` events
- **Inventory / interaction:** `qb-inventory`, `qb-target`, `qb-menu`, `qb-input`, `progressbar` — the exact classes QBox docs say need a QBox version or an update
- **Data loss:** `qb-phone`, `qb-houses`, `qb-apartments`, `qb-clothing` (saved outfits), `weapon_attachments`, `qb-weapons`
- **Database:** direct SQL against `player_vehicles`, `players`, `apartments`, `houses`
- **Jobs / money:** `qb-garages`, `qb-banking`, `qb-management`, `qb-bossmenu`
- **Versions:** resources pinning `ox_lib` below **3.39.0** (ox_lib 3.37.2 prop validation broke progress bars on qbx_core 1.23.0)

## Requirements

- FiveM server (any recent artifact)
- `ox_lib` **v3.42.2** (dependency, loaded via `@ox_lib/init.lua`)
- No database, no client scripts, no escrow — **0.00ms idle** resmon (the scanner runs once on start and on demand; it never polls)

## Install

1. Drop this folder into your `resources/` directory as `qbx_scanner`.
2. Add `ensure qbx_scanner` to your `server.cfg` (after `ox_lib`).
3. Start the server. The scanner runs automatically ~5 seconds after start.

## Usage

| Command | What it does |
|---|---|
| `qbxscan` | Run a fresh scan of all resources (server console only) |
| `qbxscan report` | Re-print the last scan summary |

The compact summary goes to the server console (max 5 matches per resource); the full report is written to `resources/qbx_scanner/report.json`.

## Severities

| Severity | Meaning |
|---|---|
| **BREAK** | The resource will fail or lose data on QBox as written. Fix before migrating. |
| **MAYBE** | The resource touches data or behaviour that does not carry over cleanly (outfits, attachments, bank history, garages). Verify by hand. |
| **OK** | No QBCore breakage patterns found. |

## Known limits (honest)

- The scanner reads the scripts listed in each resource's `fxmanifest.lua` plus conventional entry points (`server.lua`, `client.lua`, `server/main.lua`, `client/main.lua`, `config.lua`, ...). A resource that loads code through glob patterns (`server/*.lua`) or dynamic loading may have files the scanner cannot enumerate — those files are not scanned.
- It pattern-matches source text; it does not execute code. A false positive (e.g. a comment mentioning `qb-menu`) is possible — check the file + line in `report.json` before acting.
- The QBox / ox stack itself (`qbx_core`, `ox_lib`, `ox_inventory`, `ox_target`, `oxmysql`, `ox_doorlock`) is excluded: those resources legitimately mention `qb-*` identifiers in bridge/migration code.
- The scanner cannot verify whether `qbx_core` v1.24.1's `convertqbinventory` works on your data — that command is brand new (30 Oct 2026) with no field reports yet. Test it on a staging server first.
- **Not yet verified on a live FiveM server** — the matcher and report logic are covered by fixture tests (below); the FiveM-native glue (`LoadResourceFile`, `GetNumResources`, `SaveResourceFile`, `qbxscan` command registration) is untested live.

## Upgrade: QBX Migration Toolkit — $19–25

The scanner tells you what is broken. The Full Toolkit fixes it:

- **Inventory converter** — `qb-inventory` items → ox_inventory `data/items.lua`, dry-run first
- **ox_lib shims** — drop-in `qb-menu` → context menu, `qb-input` → input dialog, `progressbar` → ox_lib progress bar compatibility layer, so legacy scripts keep working with zero edits
- **Data rescuers** — houses + stashes into `qbx_properties`, phone contacts/messages into NPWD, outfits and weapon attachments (the data QBox docs say "does not carry over"), all dry-run by default with idempotent SQL

**Tebex:** https://qbx-migrate.tebex.io *(URL goes live with the paid listing)*

## Development / testing

```sh
luacheck .                  # strict static checks — must be clean
stylua --check .            # formatting — must be clean
lua5.4 test/run_tests.lua   # fixture tests (no FiveM server needed)
```

Verified: `luacheck` 0 warnings / 0 errors, `stylua --check` clean, fixture suite **37 passed, 0 failed** (clean-ox → OK, heavy-qb → 11 matches / BREAK, mixed → MAYBE only). Fixtures live in `test/fixtures/` (clean ox resource, heavy qb resource, mixed resource) with the expected severity for each.

## Version

- **1.0.0** — first release. Built against `ox_lib` v3.42.2, `qbx_core` v1.24.1.

## AI disclosure

This resource was developed with AI assistance (code and documentation). All code is original to this studio; no unlicensed assets or copyrighted code are bundled.

## License

MIT — see [LICENSE](LICENSE).
