# TFC4KIDS — Player & Server Tutorial

A friendly guide to the **Snowball Gun** mod for Team Fortress Classic. This
covers how to play, how classes and player models are handled, the power-up
"buffs", and every server setting you can change.

> This mod turns TFC into a giant snowball fight. Every weapon and grenade is
> taken away and replaced with a single snowball gun, everyone is forced to the
> same class and player model, so it is safe and simple for young kids — but the
> buffs also make it fun for everyone.

---

## Part 1 — How to play

### Getting in

1. Open Team Fortress Classic and join the server.
2. Pick a **team** (the game asks you when you join).
3. **You don't pick a class** — the mod chooses one for you automatically (see
   Part 2). The class menu is skipped.
4. You spawn holding a snowball gun. That's it — you're ready.

### Controls

| Key | Action |
|-----|--------|
| **Mouse 1** (fire) | Throw a snowball. Hold it down to keep throwing. |
| **R** (reload) | Reload the snowball gun. It also auto-reloads when empty. |
| **Mouse 2** (secondary) | Used by some buffs (detonate demo snowballs, go invisible). |
| **Jump** | Normal jump — or a big leap while the Jump buff is active. |

The snowball gun is your **only** weapon — there is no melee, no grenades and no
other class weapons. You have **unlimited snowballs**, but the gun holds a small
clip (6 by default) and must reload between clips — just like a real snowball
fight where you stop to pack more snow.

---

## Part 2 — Classes and player models

**You cannot choose a class in this mod.** When you would normally see the class
menu, the `class_selector` plugin skips it and **forces every player to spawn as
a Medic**. On top of that, the `model_replacer` plugin swaps everyone's player
model for a single kid-friendly model (`modelforkids`).

The result: **every player is identical.** Same class, same speed, same health,
same look, same weapon (the snowball gun). Nobody has an advantage from their
class choice, which keeps things simple and fair for young players.

What this means in practice:

- No nailguns, rocket launchers, syringe guns, or any other class weapon.
- No grenades (a separate plugin blocks every grenade the map would give).
- No melee weapon you can swing — snowballs are all you throw.
- Everyone runs at the same (Medic) speed and has the same health.

> Your movement speed is still added to the snowball, so throwing while running
> makes a slightly faster snowball than throwing while standing still — but since
> everyone is the same class, no one is naturally faster than anyone else.

---

## Part 3 — Buffs (the power-ups)

Scattered around some maps are **pickups** (backpacks, ammo boxes, health kits,
powerups). Walk over one and you get a **random buff** for about **20 seconds**.

Rules of buffs:

- You can only have **one buff at a time**. Walking over another pickup while a
  buff is active does nothing until the first one ends.
- Which buffs you can roll depends on your **team**: one team draws from the
  **Attack** pool, the other from the **Defense** pool.
- The same buff won't be handed out twice in a row, so games stay varied.
- A little icon and a chat message tell you what you got and how to use it.

### Defense buffs

| Buff | What it does | How to use |
|------|--------------|------------|
| **Freeze** | Icy snowballs that slow enemies and can drop freeze patches on the ground. | Just throw snowballs. Patches only slow the *enemy* team. |
| **Snow Wall** | Your next throw plants a temporary, destructible snow wall. | Aim where you want the wall, then throw once. |
| **Demoman** | Snowballs stick where they land, then explode. | Throw a few, then press **Mouse 2** to detonate them all. |
| **Mag / Firerate** | Bigger snowballs, bigger clip, faster throwing, more damage. | Just throw — everything is buffed automatically. |

### Attack buffs

| Buff | What it does | How to use |
|------|--------------|------------|
| **Big Snowball** | A giant snowball you roll along the ground. It bounces off walls twice and flattens anyone it touches. | Throw it — it drops in front of you and rolls forward. You get 2 of them. |
| **Invisibility** | Go invisible for a short time. | Press **Mouse 2** to activate it after you pick it up. |
| **Jump Boost** | Jump much higher and farther. | Just press jump. |
| **Armor** | A big temporary health + armor boost. | Automatic — you're tougher for the duration. |

> The **Big Snowball** is the show-stopper: it rolls across the floor, follows
> ramps and stairs, bounces off walls, smashes enemy snow walls in one hit, and
> squashes players. It recently got a smoothness/speed fix so it rolls cleanly.

---

## Part 4 — In-game console commands

Type these in the console (press `~`). Anyone can run the help commands; giving
buffs is meant for admins.

| Command | What it does |
|---------|--------------|
| `sb_help` | Prints every Snowball Gun setting and what it does. |
| `sb_cvars` | Prints the current live values of all Snowball Gun settings. |
| `sb_givebuff <buff> [player]` | Give a specific buff. Buffs: `freeze`, `wall`, `demo`, `mag`, `big`, `invis`, `jump`, `armor`, `link`, or `clear` to remove. |

Examples:

```
sb_givebuff big            // give yourself the Big Snowball buff
sb_givebuff freeze Timmy   // give the freeze buff to the player "Timmy"
sb_givebuff clear          // remove your current buff
```

---

## Part 5 — Server settings (for admins)

All settings are **cvars**. Put them in `tfc/server.cfg` (one per line) and they
apply on the next map. Format is always `cvarname "value"`.

### Core snowball settings

| CVar | Default | What it does |
|------|---------|--------------|
| `sb_enabled` | `1` | Turn the whole snowball mode on (`1`) or off (`0`). |
| `sb_clip` | `6` | How many snowballs fit in the gun before a reload. |
| `sb_cooldown` | `0.5` | Seconds between throws. |
| `sb_reload_time` | `1.5` | Seconds a reload takes. |
| `sb_speed` | `1000` | How fast a thrown snowball flies. |
| `sb_snowfight` | `1` | `1` = snowballs hurt players, `0` = completely harmless fun. |
| `sb_damage` | `20` | Damage per hit when `sb_snowfight` is `1`. |

> For the youngest players, set `sb_snowfight 0` — snowballs then knock players
> around a little but never actually hurt them.

### Buff tuning

| CVar | Default | What it does |
|------|---------|--------------|
| `sb_buff_jumpheight` | `420.0` | Jump buff launch strength. |
| `sb_buff_mag_bonus` | `4` | Extra snowballs the Mag buff adds to the clip. |
| `sb_buff_fire_rate` | `1.8` | Mag buff fire-rate multiplier (higher = faster). |
| `sb_buff_mag_damage` | `35.0` | Damage of a Mag snowball direct hit. |
| `sb_bigsnow_speed_mult` | `0.55` | How fast the rolling Big Snowball moves (fraction of `sb_speed`). |
| `sb_invis_duration` | `8.0` | How long Invisibility lasts once activated. |
| `sb_armor_duration` | `20.0` | How long the Armor buff lasts. |
| `sb_armor_health` | `150.0` | Health while the Armor buff is active. |
| `sb_armor_armor` | `150.0` | Armor while the Armor buff is active. |

### Snow wall settings

| CVar | Default | What it does |
|------|---------|--------------|
| `sb_wall_durability` | `360.0` | Wall health before it breaks. |
| `sb_wall_lifetime` | `15.0` | Seconds a wall lasts. |
| `sb_wall_half_thickness` | `14.0` | How thick the wall's blocking area is. |
| `sb_wall_half_length` | `152.0` | How wide the wall is. |
| `sb_wall_height` | `88.0` | How tall the wall is. |
| `sb_wall_push_margin` | `20.0` | Extra soft-collision so players don't clip through. |

### Demoman (explosive) settings

| CVar | Default | What it does |
|------|---------|--------------|
| `sb_demo_explosion_radius` | `180.0` | Blast damage radius. |
| `sb_demo_damage` | `35.0` | Explosion damage. |
| `sb_demo_max_snowballs` | `5` | Max sticky snowballs a player can place at once. |
| `sb_demo_sprite_scale` | `14` | Size of the explosion effect. |

### Freeze settings

| CVar | Default | What it does |
|------|---------|--------------|
| `sb_freeze_patch_duration` | `15.0` | How long a freeze patch stays on the ground. |
| `sb_freeze_patch_charges` | `5` | How many freeze patches one Freeze buff gives. |
| `sb_freeze_patch_radius` | `75.0` | Slow radius around a patch. |
| `sb_freeze_slow_factor` | `0.45` | How much slower a frozen player moves. |
| `sb_freeze_patch_scale` | `1.0` | Visual size of the patch model. |

### Visual settings

| CVar | Default | What it does |
|------|---------|--------------|
| `sb_trail_enabled` | `1` | Snowball trails on (`1`) or off (`0`). |
| `sb_trail_width` | `3` | Thickness of the trail. |

### Languages (English / French / German)

All on-screen messages come from a language file at
`tfc/addons/amxmodx/data/lang/snowball_gun.txt` and are available in **English**,
**French** and **German**. Which language each player sees is controlled by the
standard AMX Mod X cvar:

| CVar | Value | What it does |
|------|-------|--------------|
| `amx_client_languages` | `1` | Each player sees messages in their own game language (recommended). |
| `amx_client_languages` | `0` | Everyone sees the server language set by `amx_language` (e.g. `amx_language "fr"`). |

If a French or German line is ever missing, the mod automatically falls back to
English, so English is always the safety net. If the whole language file is
missing the mod still runs — players just see the raw message names instead of
text. No plugin change is needed to add or edit translations; just edit that
text file.

---

## Part 6 — A ready-to-use `server.cfg` example

A gentle setup for very young players — snowballs push but don't hurt:

```
// --- Snowball Gun: harmless kids' party ---
sb_enabled   1
sb_snowfight 0        // snowballs are harmless
sb_clip      6
sb_cooldown  0.5

// --- General kid-friendly server safety (see CVARS.md) ---
mp_teamplay   1301    // no friendly-fire damage at all
mp_falldamage 0       // no fall damage
violence_hblood 0     // no blood
violence_hgibs  0     // no gibs
```

For a more competitive snowball war between older players, turn fighting on:

```
sb_enabled   1
sb_snowfight 1        // snowballs deal damage
sb_damage    20
```

---

## Part 7 — Frequently asked questions

**Q: Why can't I pick my class, and why do we all look the same?**
That's intended. The mod forces everyone to spawn as a Medic and gives every
player the same kid-friendly model, so all players are identical and fair. See
Part 2.

**Q: I only have snowballs — where's my axe / gun / grenades?**
There are none. The snowball gun is your only weapon; every class weapon,
grenade and melee weapon is removed on purpose. See Part 2.

**Q: I walked over a backpack but nothing happened.**
You probably already have a buff active (only one at a time), or you picked it up
less than a second ago. Wait for your current buff to end.

**Q: The Big Snowball rolled off and disappeared.**
Rolling snowballs live for a limited time and break after bouncing off walls
twice or falling off ledges. You get 2 per buff.

**Q: A cvar says "Unknown command" in the console.**
Only the snowball cvars (starting with `sb_`) come from this mod. Other cvars
depend on your TFC build — if one is unknown, just remove that line. See
[CVARS.md](CVARS.md) for the general server cvars.

**Q: Can players see the messages in French or German?**
Yes. The mod ships English, French and German text. With
`amx_client_languages 1`, each player automatically sees messages in their own
game language; anything not translated falls back to English. See the
"Languages" part above.

---

*For the project background and install steps, see the [README](README.md).*
