# TFC4KIDS — Server CVar Reference

A reference of console variables (cvars) you can add to `server.cfg`
for a Team Fortress Classic dedicated server.

> ⚠️ **AI-generated document.** This reference was compiled with the help
> of an AI assistant from public TFC/GoldSrc documentation. CVars vary
> between TFC builds, Metamod/AMX Mod X setups, and custom mods. **Test
> on your own server before relying on any value here.** If a cvar prints
> `Unknown command` in the console on startup, it simply isn't present in
> your build — that's harmless, just remove the line.

---

## How cvars work

A cvar is a setting you can change from the server console or in a `.cfg`
file. The format is always:

```
cvarname "value"
```

Lines beginning with `//` are comments and are ignored by the game.
`server.cfg` (in your `tfc/` mod folder) runs automatically on startup.

---

## Confirmed server-side cvars

These are the cvars used in this project's `server.cfg`, plus common
extras. All are server-side unless noted.

### Violence / content

| CVar | Example | What it does |
|------|---------|--------------|
| `violence_ablood` | `0` | Alien/robot blood. `0` = off. |
| `violence_agibs` | `0` | Alien/robot body parts. `0` = off. |
| `violence_hblood` | `0` | Human blood. `0` = off. |
| `violence_hgibs` | `0` | Human body parts. `0` = off. |

### Comfort / accessibility

| CVar | Example | What it does |
|------|---------|--------------|
| `sv_rollangle` | `0` | Screen lean/roll when strafing. `0` keeps the view level. |
| `sv_rollspeed` | `0` | How fast that roll happens. Pair with `sv_rollangle 0`. |

> The up/down walking **bob** (`cl_bob`, `cl_bobup`, `cl_bobcycle`) is a
> **client** setting and cannot be forced from the server on stock
> GoldSrc. Players set those themselves. See "Client-side" below.

### Aiming / fairness

| CVar | Example | What it does |
|------|---------|--------------|
| `sv_aim` | `0` | Auto-aim assist. `0` = off (everyone aims themselves). |
| `sv_cheats` | `0` | Enables cheat commands. Keep at `0` on a public server. |

### Gameplay / match flow

| CVar | Example | What it does |
|------|---------|--------------|
| `mp_teamplay` | `1301` | Teamplay + friendly-fire bitfield (see below). |
| `mp_timelimit` | `40` | Minutes per map before it changes. |
| `mp_footsteps` | `1` | Footstep sounds. `1` = on. |
| `mp_falldamage` | `0` | Damage from falling. `0` = off (gentler). |
| `mp_flashlight` | `1` | Lets players use the flashlight. |
| `tfc_autoteam` | `0` | Auto-shuffle players into teams. `0` = let them pick. |
| `sv_maxspeed` | `500` | Top movement speed for all players. |

### Server identity / access

| CVar | Example | What it does |
|------|---------|--------------|
| `hostname` | `"..."` | Name shown in the server browser. |
| `sv_password` | `""` | Join password. Empty = open server. |
| `rcon_password` | `"..."` | Remote-admin password. **Never commit a real one.** |
| `pausable` | `0` | Whether players can pause the server. |
| `sv_clienttrace` | `3.5` | Player collision-box size for hit detection. |
| `sv_contact` | `"..."` | Admin contact email shown to clients. |

### Network / bandwidth

| CVar | Example | What it does |
|------|---------|--------------|
| `sv_minrate` | `5000` | Minimum bandwidth per client (bytes/sec). |
| `sv_maxrate` | `25000` | Maximum bandwidth per client (bytes/sec). |
| `sys_ticrate` | `100` | Server simulation frames per second. |

> `sv_minupdaterate` / `sv_maxupdaterate` exist on some GoldSrc builds but
> not all — test before depending on them.

### Voice / chat

| CVar | Example | What it does |
|------|---------|--------------|
| `sv_voiceenable` | `1` | Allow in-game voice chat. `0` = disable entirely. |
| `sv_alltalk` | `0` | `0` = teammates only; `1` = everyone hears everyone. Default `0`. |

### Downloads / custom content

| CVar | Example | What it does |
|------|---------|--------------|
| `mp_consistency` | `0` | Enforce file consistency between client and server. |
| `sv_allowdownload` | `1` | Let clients download maps/decals from the server. |
| `sv_allowupload` | `1` | Let clients upload custom decals to the server. |
| `sv_downloadurl` | `""` | Fast-download (HTTP) host for custom content. Unset in this project. |

---

## `mp_teamplay` — friendly-fire bitfield

`mp_teamplay` is a single number made by **adding together** option
values. The project uses **`1301`**, which is:

```
   1   Teamplay ON (must always be set)
   4   Teammates take NO damage from direct weaponfire
  16   Teammates take NO damage from explosive weaponfire
 256   Teammates' armor takes NO damage from direct weaponfire
1024   Teammates' armor takes NO damage from explosive weaponfire
-----
1301   (1 + 4 + 16 + 256 + 1024)
```

So **`1301` = teamplay on, with no friendly-fire damage to health or
armor from weapons or grenades** — a good fit for a kids' server.

Full list of option values:

| Value | Meaning |
|------:|---------|
| 1 | Teamplay on (always set this) |
| 2 | Teammates take HALF damage from direct weaponfire |
| 4 | Teammates take NO damage from direct weaponfire |
| 8 | Teammates take HALF damage from explosive weaponfire |
| 16 | Teammates take NO damage from explosive weaponfire |
| 128 | Teammates' armor takes HALF damage from direct weaponfire |
| 256 | Teammates' armor takes NO damage from direct weaponfire |
| 512 | Teammates' armor takes HALF damage from explosive weaponfire |
| 1024 | Teammates' armor takes NO damage from explosive weaponfire |
| 2048 | YOU take HALF damage when hitting a teammate (direct) |
| 4096 | YOU take NO damage when hitting a teammate (direct) |
| 8192 | YOU take HALF damage when hitting a teammate (explosive) |
| 16384 | YOU take NO damage when hitting a teammate (explosive) |
| 32768 | YOUR armor takes HALF damage when hitting a teammate (direct) |

Common presets you may see elsewhere:

- `1` — teamplay on, friendly fire fully enabled (armor still strips)
- `21` — standard: no FF health stripping, but armor stripping on
- `1301` — no FF health or armor stripping (this project)

---

## Client-side settings (players set these themselves)

These cannot be forced from `server.cfg` on stock GoldSrc. Players can
put them in their own `tfc/userconfig.cfg` or autoexec, or type them in
the console:

| CVar | Example | What it does |
|------|---------|--------------|
| `cl_bob` | `0` | Up/down view bob while walking. `0` = off. |
| `cl_bobup` | `0` | Bob amount on the up-step. |
| `cl_bobcycle` | `0.8` | How fast the bob cycles. |
| `default_fov` | `90` | Field of view (how wide the view is). |
| `fov` | `90` | Same as above on some clients. |

---

## Notes & caveats

- This list mixes **stock GoldSrc/TFC** cvars with a few that exist only
  on certain builds. Always check your own console output.
- `sw_snowballs` is **not** a stock cvar — it belongs to this project's
  snowball plugin/mod and only works with that loaded.
- Never store a real `rcon_password` in a file you push to a public repo.
- When in doubt, run `cvarlist` in the server console to dump every cvar
  your specific build actually supports.

---

*Compiled from public TFC server documentation. AI-assisted — verify
against your own server build.*