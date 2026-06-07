# tfc4kids

AMX Mod X scripts that turn [Team Fortress Classic](https://en.wikipedia.org/wiki/Team_Fortress_Classic) into a friendly first video game for small kids: every weapon and grenade is replaced, and players just throw snowballs at each other.

Originally built for a small school server so a group of seven-year-olds could have a snowball fight without ever seeing a nailgun, a rocket launcher or a syringe gun.

![demo](#) <!-- drop a gif or screenshot here later -->

## What's in this repo

| Plugin                | What it does                                                                                |
| --------------------- | ------------------------------------------------------------------------------------------- |
| `snowball_gun.sma`    | The main plugin. Suppresses every class weapon and gives every player a snowball gun instead. |

More kid-friendly plugins (no-fall-damage, no-team-damage tweaks, etc.) may land here over time.

## Features (snowball gun)

- **All class weapons are suppressed**; every player throws snowballs instead, regardless of class.
- **First-person view model + third-person held model** (`v_snowball.mdl` / `p_snowball.mdl`).
- **Throw on Mouse 1, reload on R**, automatic reload when the clip is empty.
- **Snowball physics** — gravity arc, white trail sprite, breaks into snow chunks on impact, decal stays on the wall.
- **Inherits player velocity** — a sprinting scout throws a faster snowball than someone standing still.
- **Triggers map buttons** (`func_button`, `func_rot_button`, `momentary_rot_button`) on world impact, so elevators and doors still work.
- **Kill feed rewritten** so every kill shows up as a `snowball` kill.
- **Configurable** via cvars (clip size, cooldown, reload time, speed, damage).
- **Self-cleaning** snowballs (30-second engine-level lifetime cap; nothing leaks into the void).

## Project history

The original snowball weapon was a C++ Metamod plugin from the late-1990s / early-2000s GoldSrc community:

- **[SillyZone (SZ)](https://en.wikipedia.org/wiki/Half-Life_(video_game)#Mods) / SillyZone AVC** — the Avatar Valve Conversion project — designed the gameplay and shipped the first snowball weapon.
- **SkillzWorld** and **Feckin-Mad** then ported it to Team Fortress Classic and other GoldSrc mods, and kept snowball-fight servers running for years.

This repo is a modern AMX Mod X re-implementation of that lineage. All credit for the original gameplay design and effects timing belongs to those communities; this plugin just brings it forward to a current AMXX server.

## Requirements

- A Team Fortress Classic dedicated server
- [AMX Mod X](https://www.amxmodx.org/) 1.8.2+ with the `fakemeta`, `hamsandwich`, `fun` and `file` modules

## Installation

### 1. Compile the plugin

Compile `snowball_gun.sma` with `amxxpc` (or the [AMXX Web Compiler](https://www.amxmodx.org/webcompiler.php)) to produce `snowball_gun.amxx`.

### 2. Drop the plugin in place

```
tfc/addons/amxmodx/plugins/snowball_gun.amxx
```

Add this line to `tfc/addons/amxmodx/configs/plugins.ini`:

```
snowball_gun.amxx
```

### 3. Copy the custom assets

The `assets/` folder in this repo mirrors the layout the plugin expects. Copy its contents into your `tfc/` folder so you end up with:

```
tfc/models/snowball/snowball.mdl
tfc/models/snowball/snowgibs.mdl
tfc/models/snowball/v_snowball.mdl
tfc/models/snowball/p_snowball.mdl
tfc/sound/snowball/throw.wav
tfc/sound/snowball/hit.wav
tfc/sound/snowball/hitplayer.wav
```

> **Important:** GoldSrc crashes at startup if it is told to precache a model or sound that does not exist on disk. All seven files above must be present on the server before you load the plugin.

Clients will download these files automatically the first time they join (a fast-download / `sv_downloadurl` mirror makes that faster but is not required for a small LAN).

## Configuration

Set these in `tfc/server.cfg`:

| CVar             | Default | Description                                            |
| ---------------- | ------- | ------------------------------------------------------ |
| `sb_enabled`     | `1`     | Master on/off switch                                   |
| `sb_clip`        | `5`     | Snowballs per clip                                     |
| `sb_cooldown`    | `0.5`   | Seconds between throws                                 |
| `sb_reload_time` | `1.5`   | Seconds a reload takes                                 |
| `sb_speed`       | `1000`  | Snowball launch speed (player velocity is added on top)|
| `sb_damage`      | `20`    | Damage per snowball hit                                |
| `sb_snowfight`   | `0`     | Legacy cvar — kept for backwards compatibility, not used to gate damage anymore |

## Controls

| Input    | Action            |
| -------- | ----------------- |
| Mouse 1  | Throw a snowball  |
| R        | Reload            |

The gun also auto-reloads when the clip hits zero.

## How the model assets line up

The third-person and first-person snowball gun models came from the original SillyZone AVC pack:

- `v_snowball.mdl` ← `avatar-x/avadd39.avfil` (the original `pev->viewmodel`)
- `p_snowball.mdl` ← `avatar-x/avadd33.avfil` (the original `pev->weaponmodel`)

The plugin plays animation sequences 2–7 on the view model — these are the same sequence numbers the 2003 weapon used (charge, throw, reload-loaded, idle-loaded, reload-empty, idle-empty). If you swap in a different `v_snowball.mdl`, keep the sequence indices aligned or edit the `ANIM_*` defines at the top of `snowball_gun.sma`.

## License

The plugin code in this repository is released under the [MIT License](LICENSE).

The model and sound assets under `assets/` originate from the SillyZone / SkillzWorld TFC community and are redistributed here for compatibility with the plugin; original authorship belongs to those communities.
