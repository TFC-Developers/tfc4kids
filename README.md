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

## How a GoldSrc / TFC dedicated server works

Understanding the engine and server layout helps a lot when you are installing this project, so here is a full walkthrough.

### The GoldSrc engine

Team Fortress Classic runs on Valve's **GoldSrc engine** — the same engine as Half-Life 1, Counter-Strike 1.6 and Day of Defeat. GoldSrc dates from 1998 and is a heavily modified version of Quake's engine. It is a 32-bit Windows or Linux binary, still officially distributed by Valve through Steam, and it still works perfectly today.

The dedicated server binary is called **HLDS** — the **Half-Life Dedicated Server**. You can download it via `steamcmd`:

```
steamcmd +login anonymous +app_update 90 validate +quit
```

App ID `90` is the HLDS base. After that runs you will have a folder that looks roughly like:

```
hlds/
  hlds.exe          ← Windows server binary
  hlds_run          ← Linux wrapper script
  tfc/              ← the Team Fortress Classic game folder
    liblist.gam     ← tells HLDS this is a mod and what DLL to load
    maps/           ← .bsp map files live here
    models/         ← model files (.mdl)
    sound/          ← sound files (.wav)
    sprites/        ← sprite files (.spr)
    addons/         ← AMX Mod X and other plugins live here
    server.cfg      ← server settings loaded at startup
    mapcycle.txt    ← map rotation list
```

Everything the server and clients need — maps, models, sounds, sprites — lives inside the `tfc/` folder. GoldSrc never looks outside it.

### How maps work (.bsp, .res, the resource file)

A GoldSrc map is a single `.bsp` (**Binary Space Partition**) file. BSP is the compiled, final form of a map — it encodes the world geometry, lighting, visibility data and embedded textures all in one file. You cannot easily edit a `.bsp` directly; maps are authored in a separate tool (like Hammer / Worldcraft) and compiled down to `.bsp`.

Every `.bsp` goes in:

```
tfc/maps/yourmap.bsp
```

Alongside the `.bsp` you will often find a `.res` file with the same name (`yourmap.res`). This is a plain-text **resource list** — it tells the server exactly which extra files (custom models, sounds, sprites) clients need to download before they can play the map. Without a `.res` file clients still join, but they may be missing custom content and see missing model errors or hear silence instead of custom sounds.

### How clients download files (fast download / sv_downloadurl)

When a client connects to a server and is missing a file listed in the `.res`, GoldSrc tries to download it from the server directly over the game's own protocol. This works but is very slow — often just a few KB/s.

The fast solution is `sv_downloadurl`. You point this cvar at a plain HTTP server (or any CDN / web host) that mirrors your `tfc/` folder:

```
// server.cfg
sv_downloadurl "https://yourhost.example.com/tfc/"
```

GoldSrc will then download missing files over HTTP at full speed. The HTTP layout must exactly mirror the `tfc/` folder structure — so a map at `tfc/maps/solstice_b.bsp` on the server must be at `https://yourhost.example.com/tfc/maps/solstice_b.bsp` on the web server.

For a small LAN server (which is the original use-case of this project) `sv_downloadurl` is not required — clients are on the same network and the slow download is fast enough.

### How AMX Mod X fits in

**AMX Mod X (AMXX)** is a plugin system that sits on top of GoldSrc via the **Metamod** hook layer. Metamod intercepts calls between the engine and the game DLL; AMX Mod X then loads `.amxx` plugin binaries and exposes a scripting API to them.

The plugin source files (`.sma`) are written in **Pawn**, a C-like scripting language. You compile them to `.amxx` with the `amxxpc` compiler. The compiled `.amxx` file is what the server actually loads.

Install layout:

```
tfc/addons/metamod/plugins.ini   ← tells Metamod to load AMXX
tfc/addons/amxmodx/
  configs/plugins.ini            ← lists which .amxx plugins to load
  plugins/snowball_gun.amxx      ← compiled plugin
```

Metamod and AMX Mod X must both be installed before any plugin will work. See the [AMXX installation guide](https://wiki.alliedmods.net/Installing_AMX_Mod_X) for the full setup.

---

## Assets

The `assets/` folder in this repo mirrors the `tfc/` folder layout exactly. Copy its contents into your `tfc/` folder and the paths will land in the right place automatically.

### Folder structure

```
assets/
  maps/
    kandahar.bsp
    kandahar.res
    letgo_3-ost.bsp
    letgo_3-ost.res
    solstice_b.bsp
    solstice_b.res
    thecove.bsp
    thecove.res
  models/
    snowball/
      snowball.mdl
      snowgibs.mdl
      v_snowball.mdl
      p_snowball.mdl
  sound/
    snowball/
      throw.wav
      hit.wav
      hitplayer.wav
  mapcycle.txt
```

### What each part is

**`maps/`** — The BSP map files for the tfc4kids rotation. Each map ships with its `.res` file so the server knows which extra assets clients need to download. Copy these to `tfc/maps/`.

**`models/`** — The snowball gun models. `v_snowball.mdl` is the first-person view model (what the player holding it sees); `p_snowball.mdl` is the third-person world model (what other players see). Copy to `tfc/models/snowball/`.

**`sound/`** — The three snowball sounds: throw, world impact, and player impact. Copy to `tfc/sound/snowball/`.

**`mapcycle.txt`** — The map rotation file. Lists the maps in the order the server will cycle through them. Copy to `tfc/mapcycle.txt`. Open it in any text editor — it is fully commented and explains how to add or remove maps.

> **Important:** GoldSrc crashes at startup if it is told to precache a model or sound that does not exist on disk. All files in `models/snowball/` and `sound/snowball/` must be present on the server before you load the plugin.

---

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

Copy the contents of `assets/` into your `tfc/` folder so you end up with:

```
tfc/maps/kandahar.bsp
tfc/maps/kandahar.res
tfc/maps/letgo_3-ost.bsp
tfc/maps/letgo_3-ost.res
tfc/maps/solstice_b.bsp
tfc/maps/solstice_b.res
tfc/maps/thecove.bsp
tfc/maps/thecove.res
tfc/models/snowball/snowball.mdl
tfc/models/snowball/snowgibs.mdl
tfc/models/snowball/v_snowball.mdl
tfc/models/snowball/p_snowball.mdl
tfc/sound/snowball/throw.wav
tfc/sound/snowball/hit.wav
tfc/sound/snowball/hitplayer.wav
tfc/mapcycle.txt
```

> **Important:** GoldSrc crashes at startup if it is told to precache a model or sound that does not exist on disk. All seven model and sound files above must be present on the server before you load the plugin.

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
