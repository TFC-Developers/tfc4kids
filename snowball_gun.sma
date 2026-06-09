/* ===========================================================================
 *  TFC SNOWBALL GUN  -  "Snowball fight only" server plugin for Team Fortress Classic
 * ===========================================================================
 *
 *  WHAT THIS DOES (in plain words)
 *  -------------------------------
 *  This gives every Team Fortress Classic player a "Snowball Gun" as a BONUS weapon
 *  that they have alongside their normal class weapons. The moment a player spawns:
 *
 *     1. They keep their normal class weapons (Scout axe, Soldier launcher, etc).
 *     2. They are ALSO given a "Snowball Gun" as a virtual weapon.
 *     3. They have UNLIMITED snowballs with the gun, but it must RELOAD,
 *        just like the old 2003 version did.
 *
 *  How a player uses it:
 *     - Mouse 1 (primary attack) ............ throw a snowball
 *     - R key (reload) ...................... reload the snowball gun
 *     - It also reloads on its own when the clip is empty, so kids never get stuck.
 *
 *  This is a "virtual weapon": Team Fortress Classic does not let a plugin add a
 *  brand-new weapon into the weapon menu, so instead we remove every weapon and
 *  run the snowball gun completely from this plugin (throwing, the ammo counter
 *  and the reload are all handled in code, and the ammo is shown on the screen as
 *  text). For a snowball-only server this is the most reliable approach.
 *
 *  This file is a modern AMX Mod X rewrite of the 2003 SillyZone / SkillzWorld
 *  C++ snowball weapon (see the README for the project history).
 *
 *
 *  ===========================================================================
 *  CREDITS  -  where this code came from
 *  ===========================================================================
 *  The original snowball weapon idea and the C++ implementation it is based on
 *  come from the old GoldSrc community called "SillyZone" (SZ / SillyZone AVC,
 *  the Avatar Valve Conversion project). From there, the SkillzWorld community
 *  and Feckin-Mad picked the project up, ported it to Team Fortress Classic
 *  and other GoldSrc mods, and kept the snowball-fight servers alive across the
 *  late 1990s and the 2000s. This plugin is a modern AMX Mod X re-implementation
 *  of that lineage. All credit for the original gameplay design and effects
 *  timing belongs to those communities; this file just brings it forward to a
 *  current AMXX server.
 *
 *
 *  ===========================================================================
 *  FILES YOU NEED AND WHERE TO PUT THEM  (read this carefully!)
 *  ===========================================================================
 *
 *  Your TFC server lives in a folder usually called "tfc". Everything below is
 *  written relative to that "tfc" folder. On a typical Windows/Linux server the
 *  full path looks like:  .../<server>/tfc/...
 *
 *  1) THE PLUGIN ITSELF (this file, compiled)
 *  ------------------------------------------
 *     a) Compile this file (snowball_gun.sma) into snowball_gun.amxx
 *        (use the AMX Mod X web compiler, or amxxpc / studio compiler).
 *     b) Copy:   snowball_gun.amxx
 *        Into:    tfc/addons/amxmodx/plugins/snowball_gun.amxx
 *     c) Open:   tfc/addons/amxmodx/configs/plugins.ini
 *        Add a new line at the bottom:
 *                 snowball_gun.amxx
 *
 *  2) STANDARD FILES (already in every TFC install - nothing to download)
 *  ---------------------------------------------------------------------
 *     - sprites/laserbeam.spr      (used for the white snowball "trail")
 *     These already exist, so you do NOT have to copy anything for these.
 *
 *  3) CUSTOM FILES (the snowball look + sounds)  *** REQUIRED ***
 *  ------------------------------------------------------------
 *     IMPORTANT: GoldSrc (the game engine) CRASHES on startup if it is told to
 *     load a model or sound file that does not exist. So the files below MUST be
 *     present on the SERVER, exactly at these paths, or the server will not boot.
 *
 *       MODELS  ->  copy into the "tfc/models/snowball/" folder:
 *          tfc/models/snowball/snowball.mdl     (the flying snowball)
 *          tfc/models/snowball/snowgibs.mdl     (the little chunks when it breaks)
 *          tfc/models/snowball/v_snowball.mdl   (first-person VIEW model: your hand + the gun)
 *          tfc/models/snowball/p_snowball.mdl   (third-person model others see in your hands)
 *
 *       The two snowball-gun models came from the original Metamod files:
 *          v_snowball.mdl  <-  avatar-x/avadd39.avfil   (old pev->viewmodel)
 *          p_snowball.mdl  <-  avatar-x/avadd33.avfil   (old pev->weaponmodel)
 *       Keep their internal animation sequences (2..7) intact - this plugin plays
 *       the exact same sequence numbers the original weapon used.
 *
 *       SOUNDS  ->  copy into the "tfc/sound/snowball/" folder:
 *          tfc/sound/snowball/throw.wav         (played when you throw)
 *          tfc/sound/snowball/hit.wav           (played when it hits a wall)
 *          tfc/sound/snowball/hitplayer.wav     (played when it hits a person)
 *
 *     DON'T HAVE CUSTOM SNOWBALL MODELS YET?
 *     You can get the server running immediately by pointing these at files that
 *     already exist in TFC. Scroll down to the "RESOURCES" section and change the
 *     model/sound paths, for example use "models/grenade.mdl" as a stand-in
 *     snowball. Once you have nicer snowball art, just put the real files in the
 *     folders above and change the paths back.
 *
 *  4) PLAYERS DOWNLOADING THE CUSTOM FILES
 *  ---------------------------------------
 *     When the server "precaches" (pre-loads) a model or sound, GoldSrc
 *     automatically adds it to the list of files clients must download. So once
 *     the files are on the server, players joining will receive them
 *     automatically (this is fastest if you also set up a fast-download / sv_downloadurl,
 *     but it is not required for a small school LAN server).
 *
 *
 *  ===========================================================================
 *  SERVER SETTINGS (CVARs) - put these in tfc/server.cfg if you want to change them
 *  ===========================================================================
 *     sb_enabled        1        Turn the whole snowball mode on (1) or off (0).   [default 1]
 *     sb_clip           5        How many snowballs fit in the gun before reload.   [default 5]
 *     sb_cooldown       0.5      Seconds between throws.                            [default 0.5]
 *     sb_reload_time    1.5      Seconds a reload takes.                            [default 1.5]
 *     sb_speed          1000     How fast a thrown snowball flies.                  [default 1000]
 *     sb_snowfight      0        1 = snowballs hurt players, 0 = harmless fun.      [default 0]
 *     sb_damage         20       Damage per hit when sb_snowfight is 1.             [default 20]
 *
 *  Example tfc/server.cfg lines for a harmless 7-year-old snowball party:
 *     sb_enabled   1
 *     sb_snowfight 0
 *
 * ===========================================================================
 */

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <fun>
#include <file>

#define PLUGIN  "TFC Snowball Gun"
#define VERSION "1.0"
#define AUTHOR  "MrKoala"

/* ---------------------------------------------------------------------------
 *  CONTROLS  -  which keys do what
 *  IN_ATTACK  = mouse button 1 (throw)
 *  IN_RELOAD  = the reload key, normally "R" (reload)
 *  You normally do not need to change these.
 * ------------------------------------------------------------------------- */
#define THROW_BUTTON    IN_ATTACK
#define RELOAD_BUTTON   IN_RELOAD

/* ---------------------------------------------------------------------------
 *  WEAPON ANIMATION SEQUENCES  -  these match the ORIGINAL snowball viewmodel.
 *  (Taken straight from the 2003 code's SVC_WEAPONANIM calls.)
 *      2 = charge / wind-up      3 = throw
 *      4 = reload (had ammo)     6 = reload (was empty)
 *      5 = idle (loaded)         7 = idle (empty)
 *  Do not change these unless your v_snowball.mdl uses different sequence numbers.
 * ------------------------------------------------------------------------- */
#define ANIM_CHARGE          2
#define ANIM_THROW           3
#define ANIM_RELOAD_LOADED   4
#define ANIM_IDLE_LOADED     5
#define ANIM_RELOAD_EMPTY    6
#define ANIM_IDLE_EMPTY      7

// GoldSrc engine message that plays a weapon animation on a client.
// (Not pre-defined in the AMXX includes, so we define it ourselves.)
#if !defined SVC_WEAPONANIM
    #define SVC_WEAPONANIM   35
#endif

// Spawnflag used by the original HL/TFC weapon code: when a weapon entity has
// this flag set, it disappears after the first pickup instead of re-spawning
// on the world. We need it so the axe we create just to give to the player
// does not leave a permanent floating pickup behind.
#if !defined SF_NORESPAWN
    #define SF_NORESPAWN     (1 << 30)
#endif

/* ---------------------------------------------------------------------------
 *  RESOURCES  -  the model and sound files (see the big FILES list above).
 *  If you do not have custom snowball art yet, change MODEL_SNOWBALL and
 *  MODEL_SNOWGIBS to a model that already exists, e.g. "models/grenade.mdl".
 * ------------------------------------------------------------------------- */
new const MODEL_SNOWBALL[]  = "models/snowball/snowball.mdl";   // the flying snowball
new const MODEL_SNOWGIBS[]  = "models/snowball/snowgibs.mdl";   // chunks when it breaks
new const MODEL_VIEW[]      = "models/snowball/v_snowball.mdl"; // first-person view model (your hands)
new const MODEL_WEAPON[]    = "models/snowball/p_snowball.mdl"; // third-person held model (others see)
new const SPRITE_TRAIL[]    = "sprites/laserbeam.spr";          // standard TFC file

new const SND_THROW[]       = "snowball/throw.wav";             // thrown
new const SND_HIT_WORLD[]   = "snowball/hit.wav";               // hit a wall/floor
new const SND_HIT_PLAYER[]  = "snowball/hitplayer.wav";         // hit a player

new const SNOWBALL_CLASS[]  = "snowball";   // internal name we give our thrown entity

/* ---------------------------------------------------------------------------
 *  GLOBAL VARIABLES  -  the plugin's memory while the server runs
 * ------------------------------------------------------------------------- */
new g_idxSnowGibs;          // precached id of the "break into chunks" model
new g_idxSnowball;          // precached id of the flying snowball model
new g_idxTrail;             // precached id of the trail sprite
new g_maxPlayers;           // how many player slots the server has
new bool:g_haveViewModel;   // are the v_/p_ snowball gun model files present?
new g_iszViewModel;         // allocated engine string for MODEL_VIEW
new g_iszWeaponModel;       // allocated engine string for MODEL_WEAPON

// Per-player state. Index 0 is unused; 1..32 are the players.
new g_clip[33];                 // how many snowballs are loaded right now
new bool:g_reloading[33];       // is this player currently reloading?
new Float:g_flNextThrow[33];    // earliest game-time this player may throw again
new Float:g_flReloadEnd[33];    // game-time the current reload finishes
new bool:g_idlePending[33];     // should we return the gun to its idle pose soon?
new Float:g_flIdleAt[33];       // game-time to play that idle pose
new g_snowMode[33];             // state machine like the original (0=idle, 3=equipping, 4=reloading)
new Float:g_equipTime[33];      // when to finish the current equip/reload state
new bool:g_equipped[33];        // have we equipped the weapon in this player's current life?
new bool:g_aliveInWorld[33];    // transition tracker: is player currently alive and spawned in world?
new bool:g_snowSelected[33];    // true when the player has selected the snowball gun overlay
new g_prevButtons[33];          // last frame RAW buttons for press/release edge detection
new g_rawButtons[33];           // raw per-frame buttons captured before we strip engine input

// Cached pointers to the CVARs (faster than looking them up by name every frame)
new g_pEnabled, g_pClip, g_pCooldown, g_pReloadTime, g_pSpeed, g_pSnowfight, g_pDamage;

// HUD: a coloured text channel to draw the snowball counter on screen
new g_hudSync;

/* ===========================================================================
 *  PLUGIN STARTUP
 * ========================================================================= */

// plugin_precache runs very early, before the map loads. This is the ONLY safe
// place to pre-load (precache) models and sounds.
public plugin_precache()
{
    // Assign the models exactly the way the working snowballs.sma does: a plain
    // precache_model for each one. precache_model only registers the NAME (it does
    // not read the file), so this never crashes here even if a file is the wrong
    // format - it would only matter later when the model is actually displayed.
    g_idxSnowball = precache_model(MODEL_SNOWBALL);
    g_idxSnowGibs = precache_model(MODEL_SNOWGIBS);
    g_idxTrail    = precache_model(SPRITE_TRAIL);

    // The first-person view model and the third-person held model. We only enable
    // them if both files exist, so a server without the art still runs (empty hands).
    if (file_exists(MODEL_VIEW) && file_exists(MODEL_WEAPON))
    {
        precache_model(MODEL_VIEW);
        precache_model(MODEL_WEAPON);
        g_haveViewModel = true;
        g_iszViewModel = engfunc(EngFunc_AllocString, MODEL_VIEW);
        g_iszWeaponModel = engfunc(EngFunc_AllocString, MODEL_WEAPON);
    }
    else
    {
        g_haveViewModel = false;
        g_iszViewModel = 0;
        g_iszWeaponModel = 0;
        if (!file_exists(MODEL_VIEW))
            server_print("[Snowball Gun] MISSING model: %s -- view model disabled.", MODEL_VIEW);
        if (!file_exists(MODEL_WEAPON))
            server_print("[Snowball Gun] MISSING model: %s -- view model disabled.", MODEL_WEAPON);
    }

    precache_sound(SND_THROW);
    precache_sound(SND_HIT_WORLD);
    precache_sound(SND_HIT_PLAYER);
}

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR);

    // Create the server settings (CVARs) with their default values.
    g_pEnabled    = register_cvar("sb_enabled",     "1");
    g_pClip       = register_cvar("sb_clip",        "5");
    g_pCooldown   = register_cvar("sb_cooldown",    "0.5");
    g_pReloadTime = register_cvar("sb_reload_time", "1.5");
    g_pSpeed      = register_cvar("sb_speed",       "1000");
    g_pSnowfight  = register_cvar("sb_snowfight",   "0");
    g_pDamage     = register_cvar("sb_damage",      "20");

    // Every game frame, for every player, we check their buttons (throw/reload).
    register_forward(FM_PlayerPreThink, "fw_PlayerPreThink");
    // Strip IN_ATTACK/IN_RELOAD right before TFC's PostThink runs ItemPostFrame.
    // This mirrors the original cpp: pEntity->v.button &= ~IN_ATTACK; at the end
    // of their PostThink_pre. Without this, TFC's class weapon will still fire.
    register_forward(FM_PlayerPostThink, "fw_PlayerPostThink");
    // Capture and strip attack/reload before weapon code sees them.
    register_forward(FM_CmdStart, "fw_CmdStart");
    // Override the client's idea of "current weapon" every frame so TFC can't
    // make the HUD/model flicker back to the class weapon. This is the AMXX
    // equivalent of the original cpp's WepPlayerThink2 (cd->m_iId override).
    register_forward(FM_UpdateClientData, "fw_UpdateClientData", 1); // post hook

    // Rewrite the weapon name in the kill feed to "snowball" so every kill
    // shows as a snowball kill regardless of which TFC class weapon the killer
    // technically still has equipped under the hood.
    register_message(get_user_msgid("DeathMsg"), "fw_DeathMsg");

    // Whenever any entity touches another, we check if it was a snowball hitting something.
    register_forward(FM_Touch, "fw_Touch");
    // Snowball lifetime cap: catches snowballs that fly into the void or out of
    // the map without ever touching anything. They get a pev_nextthink set at
    // throw time, and this forward fires when the engine ticks their think.
    register_forward(FM_Think, "fw_Think");

    // No Ham_Killed hook in TFC gamedata; respawn/death transitions are handled in PlayerPreThink.

    g_maxPlayers = get_maxplayers();

    // Create one HUD text channel we will reuse to draw the snowball counter.
    g_hudSync = CreateHudSyncObj();

    // Refresh the on-screen snowball counter and weapon state a few times a second.
    // The "b" flag means this task repeats forever.
    set_task(0.1, "RefreshAllHud", 0, "", 0, "b");
}

// Reset a player's snowball gun when they join.
public client_putinserver(id)
{
    g_clip[id]        = 0;
    g_reloading[id]   = false;
    g_flNextThrow[id] = 0.0;
    g_flReloadEnd[id] = 0.0;
    g_idlePending[id] = false;
    g_flIdleAt[id]    = 0.0;
    g_snowMode[id]    = 0;
    g_equipTime[id]   = 0.0;
    g_equipped[id]    = false;
    g_aliveInWorld[id]= false;
    g_snowSelected[id]= false;
    g_prevButtons[id] = 0;
    g_rawButtons[id]  = 0;
}

public client_disconnected(id)
{
    g_equipped[id]    = false;
    g_aliveInWorld[id]= false;
    g_snowMode[id]    = 0;
    g_snowSelected[id]= false;
    g_prevButtons[id] = 0;
    g_rawButtons[id]  = 0;
}

public fw_CmdStart(id, uc_handle, seed)
{
    if (!get_pcvar_num(g_pEnabled) || !is_user_connected(id))
        return FMRES_IGNORED;

    new buttons = get_uc(uc_handle, UC_Buttons);
    g_rawButtons[id] = buttons;

    // In snow-only mode, consume attack/reload before engine weapon code executes.
    if (is_user_alive(id) && g_equipped[id])
    {
        buttons &= ~(THROW_BUTTON | RELOAD_BUTTON);
        set_uc(uc_handle, UC_Buttons, buttons);
    }

    return FMRES_IGNORED;
}

// Final strip: runs right before the original PlayerPostThink, which is where
// TFC's ItemPostFrame (weapon firing) actually happens. Matches the original
// cpp's WepPlayerThink1 tail (pEntity->v.button &= ~IN_ATTACK;).
public fw_PlayerPostThink(id)
{
    if (!get_pcvar_num(g_pEnabled) || !is_user_connected(id))
        return FMRES_IGNORED;
    if (!g_equipped[id] || !is_user_alive(id))
        return FMRES_IGNORED;

    new pevButton = pev(id, pev_button);
    if (pevButton & (THROW_BUTTON | RELOAD_BUTTON))
        set_pev(id, pev_button, pevButton & ~(THROW_BUTTON | RELOAD_BUTTON));

    // Re-apply snowball viewmodel / weaponmodel AT THE END OF THE FRAME so the
    // engine snapshot that goes to every other client always carries the snowball
    // p_model. Without this, when a player rapidly switches weapons (lastinv,
    // slot1-5, weapon_*), TFC may set pev_weaponmodel to the class weapon after
    // our PreThink ran, and the next delta-update sends that wrong model to
    // every spectator and teammate.
    ApplySnowballModels(id);

    return FMRES_IGNORED;
}

// Override the client's "current weapon" every frame the engine sends client data.
// This is what the original cpp does in WepPlayerThink2 with cd->m_iId. Without
// this, TFC's HUD and viewmodel flicker back to the player's normal class weapon.
public fw_UpdateClientData(id, sendweapons, cd_handle)
{
    if (!get_pcvar_num(g_pEnabled) || !is_user_alive(id))
        return FMRES_IGNORED;
    if (!g_equipped[id])
        return FMRES_IGNORED;
    // Skip during the brief equip window (mode 3): WeapPickup hasn't been sent
    // yet, so the client doesn't know weapon 26 exists. RefreshAllHud's mode-3
    // handler sends WeapPickup, then mode flips to 0 and we start overriding.
    if (g_snowMode[id] == 3)
        return FMRES_IGNORED;

    // Force weapon id to snowball (26).
    set_cd(cd_handle, CD_ID, 26);

    return FMRES_HANDLED;
}

// Kill-feed rewrite: TFC's DeathMsg carries the killer's currently-equipped
// weapon name as the 3rd argument. Since we never actually let the class weapon
// fire, every kill in this mode is really a snowball kill - force the label.
public fw_DeathMsg(msgid, dest, receiver)
{
    new killer = get_msg_arg_int(1);
    if (killer < 1 || killer > g_maxPlayers)
        return PLUGIN_CONTINUE;
    if (!g_equipped[killer])
        return PLUGIN_CONTINUE;

    // TFC DeathMsg layout: byte killer, byte victim, string weapon.
    // The weapon name is arg 3 (1-based). Writing to arg 4 corrupts the
    // tail of arg 3 - e.g. "nailgun" came out as "ng" in the kill feed.
    set_msg_arg_string(3, "snowball");


    // Resetting the dying players clip
    new victim = get_msg_art_int(2);
    if (victim < 1 || victim > g_maxPlayers)
        return PLUGIN_CONTINUE;
    if (!g_equipped[victim])
        return PLUGIN_CONTINUE;

    g_clip[victim] = get_pcvar_num(g_pClip);

    return PLUGIN_CONTINUE;
}

/* ===========================================================================
 *  SPAWNING  -  give the snowball gun when the player is truly alive in-world
 * ========================================================================= */

/* ---------------------------------------------------------------------------
 *  GIVE THE PLAYER THE AXE
 *
 *  The maps shipped in this repo are altered so the player spawns with NO
 *  weapons at all. This function gives the player exactly one real TFC weapon:
 *  the crowbar/axe (tf_weapon_axe). It mirrors the classic GoldSrc helper
 *
 *      void UTIL_GiveWeapon( int code, edict_t *pEntity );
 *
 *  ...specialised here for the axe (code 18 in that original switch). The
 *  recipe is the same:
 *    1) create a named weapon entity at the player's feet,
 *    2) flag it SF_NORESPAWN so it does not leave a floating pickup behind,
 *    3) dispatch its Spawn (so the weapon initialises itself),
 *    4) dispatch its Touch against the player (so the pickup actually happens).
 * ------------------------------------------------------------------------- */
GiveAxe(id)
{
    // Build the entity name string the engine expects.
    new iszClass = engfunc(EngFunc_AllocString, "tf_weapon_axe");
    new ent = engfunc(EngFunc_CreateNamedEntity, iszClass);
    if (!pev_valid(ent))
        return;

    // Place the weapon at the player's origin (same as VARS(pent)->origin = pEntity->v.origin).
    new Float:vOrigin[3];
    pev(id, pev_origin, vOrigin);
    set_pev(ent, pev_origin, vOrigin);

    // Don't leave a respawning weapon pickup in the world.
    set_pev(ent, pev_spawnflags, pev(ent, pev_spawnflags) | SF_NORESPAWN);

    // Spawn the weapon, then immediately "touch" the player with it so the
    // standard pickup code runs and the axe ends up in the player's inventory.
    dllfunc(DLLFunc_Spawn, ent);
    dllfunc(DLLFunc_Touch, ent, id);
}

EquipSnowballGun(id)
{
    // Initialize the snowball gun state, matching the original C++ code.
    // We set a state machine mode (3 = equipping) and a time when it should complete.
    // The actual weapon giving (messages) happens in RefreshAllHud when the time elapses.
    g_clip[id]        = get_pcvar_num(g_pClip);
    g_reloading[id]   = false;
    g_flNextThrow[id] = 0.0;
    g_flReloadEnd[id] = 0.0;
    g_idlePending[id] = false;
    g_flIdleAt[id]    = 0.0;
    g_snowMode[id]    = 3;   // state: equipping
    g_equipTime[id]   = get_gametime() + 0.5;  // complete after 0.5 seconds
    g_equipped[id]    = true;
    g_snowSelected[id]= true;

    // Force our snowball models so the player actually sees the snowball gun.
    ApplySnowballModels(id);
}

ApplySnowballModels(id)
{
    if (!g_haveViewModel || !g_iszViewModel || !g_iszWeaponModel)
        return;

    // TFC uses viewmodel/weaponmodel fields directly (same as the original C++ code).
    // IMPORTANT: only write the field if it's currently something else. The engine
    // resets a studio model's animation state every time pev_weaponmodel is
    // assigned, even when assigned the same string - so writing it every frame
    // freezes the p_model on frame 0 of its idle sequence and other players see
    // a completely static snowball gun in the player's hands. By comparing first
    // we only re-apply when TFC has actually switched the model to a class weapon
    // (which is exactly the case we wanted to protect against).
    new curView = pev(id, pev_viewmodel);
    if (curView != g_iszViewModel)
        set_pev(id, pev_viewmodel, g_iszViewModel);

    new curWeap = pev(id, pev_weaponmodel);
    if (curWeap != g_iszWeaponModel)
        set_pev(id, pev_weaponmodel, g_iszWeaponModel);
}

/* ===========================================================================
 *  EVERY FRAME  -  read the player's buttons and act on them
 * ========================================================================= */
public fw_PlayerPreThink(id)
{
    if (!get_pcvar_num(g_pEnabled) || !is_user_connected(id))
        return FMRES_IGNORED;

    new deadflag = pev(id, pev_deadflag);
    new Float:health;
    pev(id, pev_health, health);
    new team = pev(id, pev_team);
    new buttons = g_rawButtons[id];

    // Mirror the C++ metamod "alive in world" check as closely as possible.
    new bool:aliveInWorld = (
        is_user_alive(id)
        && deadflag == DEAD_NO
        && health > 1.0
        && team >= 1 && team <= 5
    );

    // Transition: just entered alive-in-world state (spawned and controllable).
    if (aliveInWorld && !g_aliveInWorld[id])
    {
        g_aliveInWorld[id] = true;
        g_equipped[id] = false;
    }

    // Transition: left alive-in-world state (died/spectating/changing team).
    if (!aliveInWorld && g_aliveInWorld[id])
    {
        g_aliveInWorld[id] = false;
        g_equipped[id] = false;
        g_snowSelected[id] = false;
        g_snowMode[id] = 0;
        g_idlePending[id] = false;
    }

    if (!aliveInWorld)
    {
        g_prevButtons[id] = buttons;
        return FMRES_IGNORED;
    }

    // On the first frame the player is alive (after respawning), give the axe
    // (the one real TFC weapon the kid-mode maps allow) and then equip the
    // snowball gun overlay. This waits until the player is truly in the game
    // world, not just spawning.
    if (!g_equipped[id])
    {
        strip_user_weapons(id); // remove any weapons the map might have given (e.g. grenades)
        GiveAxe(id);
        EquipSnowballGun(id);
    }

    // Always keep snowball models visible for this simplified school mode.
    ApplySnowballModels(id);

    // Belt-and-suspenders: also strip attack/reload from pev_button so TFC's weapon
    // think (ItemPostFrame) cannot see them either, even if CmdStart was bypassed.
    new pevButton = pev(id, pev_button);
    if (pevButton & (THROW_BUTTON | RELOAD_BUTTON))
        set_pev(id, pev_button, pevButton & ~(THROW_BUTTON | RELOAD_BUTTON));

    new Float:flNow = get_gametime();
    new button = buttons;
    new buttonsChanged = (g_prevButtons[id] ^ button);
    new buttonPressed = buttonsChanged & button;

    // ---- Are we in the middle of a reload? ----
    // (state machine mode 4 means reloading; the actual ammo increment happens in RefreshAllHud)
    if (g_snowMode[id] == 4)
    {
        // While reloading you cannot throw, so skip to end.
        g_prevButtons[id] = buttons;
        return FMRES_IGNORED;
    }

    // ---- Manual reload (press R) - only if the clip is not already full ----
    // Reload is press-edge: one tap = one reload (not continuous).
    if ((buttonPressed & RELOAD_BUTTON) && g_clip[id] < get_pcvar_num(g_pClip))
    {
        StartReload(id);
        g_prevButtons[id] = buttons;
        return FMRES_IGNORED;
    }

    // ---- Throw a snowball (Mouse 1) ----
    // CONTINUOUS fire on hold: as long as the button is down, fire whenever the
    // cooldown allows. Kids can just hold LMB to keep throwing.
    if ((button & THROW_BUTTON) && g_clip[id] > 0 && flNow >= g_flNextThrow[id])
    {
        ThrowSnowball(id);

        g_clip[id]--;                                               // use one snowball
        g_flNextThrow[id] = flNow + get_pcvar_float(g_pCooldown);   // start the cooldown

        // If that was the last one, reload automatically so kids never get stuck.
        if (g_clip[id] <= 0)
        {
            StartReload(id);
        }
        else
        {
            // Otherwise, return the gun to its idle pose once the cooldown is over
            // (the original re-sent the idle animation after each throw).
            g_idlePending[id] = true;
            g_flIdleAt[id]    = g_flNextThrow[id];
        }

        // Update ammo display
        new msgAmmoX = get_user_msgid("AmmoX");
        message_begin(MSG_ONE, msgAmmoX, _, id);
        write_byte(16);
        write_byte(g_clip[id]);
        message_end();

        UpdateHud(id);

    }

    // ---- Return to idle pose after a throw (matches the original behaviour) ----
    if (g_idlePending[id] && flNow >= g_flIdleAt[id])
    {
        SendWeaponAnim(id, g_clip[id] > 0 ? ANIM_IDLE_LOADED : ANIM_IDLE_EMPTY);
        g_idlePending[id] = false;
    }

    g_prevButtons[id] = buttons;

    return FMRES_IGNORED;
}

StartReload(id)
{
    // Start the reload state machine (mode 4), like the original C++ code.
    g_snowMode[id]   = 4;  // reloading state
    g_equipTime[id]  = get_gametime() + get_pcvar_float(g_pReloadTime);
    g_idlePending[id] = false;

    // Play the reload animation (different based on whether we had ammo before reload)
    SendWeaponAnim(id, g_clip[id] > 0 ? ANIM_RELOAD_LOADED : ANIM_RELOAD_EMPTY);

    UpdateHud(id);
}

// Plays a weapon animation sequence on the player's view model.
SendWeaponAnim(id, anim)
{
    ApplySnowballModels(id);

    set_pev(id, pev_weaponanim, anim);

    message_begin(MSG_ONE, SVC_WEAPONANIM, _, id);
    write_byte(anim);                   // which sequence to play
    write_byte(pev(id, pev_body));      // model bodygroup (keep current)
    message_end();
}

/* ===========================================================================
 *  THROWING  -  create the flying snowball entity
 * ========================================================================= */
ThrowSnowball(id)
{
    // Make a new, empty entity that will be our snowball.
    new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"));
    if (!pev_valid(ent))
        return;

    set_pev(ent, pev_classname, SNOWBALL_CLASS);
    set_pev(ent, pev_owner, id);                 // remember who threw it
    set_pev(ent, pev_movetype, MOVETYPE_TOSS);   // arcs and falls like a real throw
    set_pev(ent, pev_solid, SOLID_BBOX);         // can collide with things

    // Give the snowball its model the same way snowballs.sma does.
    engfunc(EngFunc_SetModel, ent, MODEL_SNOWBALL);

    // Give it a small collision box so it reliably "touches" walls and players.
    static const Float:mins[3] = {-1.0, -1.0, -1.0};
    static const Float:maxs[3] = { 1.0,  1.0,  1.0};
    engfunc(EngFunc_SetSize, ent, mins, maxs);

    // Work out where the player is looking, so the snowball flies that way.
    new Float:vOrigin[3], Float:vView[3], Float:vAngles[3];
    new Float:vForward[3], Float:vRight[3], Float:vUp[3];

    pev(id, pev_origin,   vOrigin);
    pev(id, pev_view_ofs, vView);    // eye height offset
    pev(id, pev_v_angle,  vAngles);  // where the eyes point

    angle_vector(vAngles, ANGLEVECTOR_FORWARD, vForward);
    angle_vector(vAngles, ANGLEVECTOR_RIGHT,   vRight);
    angle_vector(vAngles, ANGLEVECTOR_UP,      vUp);

    // Start the snowball at the eyes, nudged up and to the right (like the original).
    new Float:vSrc[3];
    for (new i = 0; i < 3; i++)
        vSrc[i] = vOrigin[i] + vView[i] + vUp[i] * 1.0 + vRight[i] * 3.0;

    // Aim it forward at the chosen speed.
    new Float:speed = get_pcvar_float(g_pSpeed);
    new Float:vVel[3];
    vVel[0] = vForward[0] * speed;
    vVel[1] = vForward[1] * speed;
    vVel[2] = vForward[2] * speed;

    // Add the thrower's own velocity so the snowball inherits the player's motion
    // - running forward makes the snowball faster, running backwards slower, and
    // a jumping player throws on an arc that matches their jump. Real-world-ish.
    new Float:vPlayerVel[3];
    pev(id, pev_velocity, vPlayerVel);
    vVel[0] += vPlayerVel[0];
    vVel[1] += vPlayerVel[1];
    vVel[2] += vPlayerVel[2];

    set_pev(ent, pev_origin, vSrc);
    engfunc(EngFunc_SetOrigin, ent, vSrc);   // "links" the entity so collisions work
    set_pev(ent, pev_angles, vAngles);
    set_pev(ent, pev_velocity, vVel);

    // Stamp throw time so the self-hit grace window in fw_Touch can ignore the
    // immediate collision with the thrower's own bbox right after spawn, while
    // still letting a sky-thrown snowball hit the owner when it comes back down.
    set_pev(ent, pev_dmgtime, get_gametime());

    // Lifetime cap: schedule a think 30 seconds from now. If the snowball is
    // still alive at that point (flew into the void, stuck in geometry, etc.)
    // the engine will call fw_Think which removes it. This is pure engine state
    // (pev_nextthink) - no set_task / timer in the plugin scheduler is needed.
    set_pev(ent, pev_nextthink, get_gametime() + 30.0);

    // Draw a short white trail behind the snowball (same as the 2003 version).
    message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
    write_byte(TE_BEAMFOLLOW);
    write_short(ent);
    write_short(g_idxTrail);
    write_byte(5);      // life of the trail (x 0.1 seconds)
    write_byte(3);      // width
    write_byte(255);    // red
    write_byte(255);    // green
    write_byte(255);    // blue
    write_byte(100);    // brightness
    message_end();

    emit_sound(ent, CHAN_VOICE, SND_THROW, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

    // Play the throw animation on the view model (original sequence 3).
    SendWeaponAnim(id, ANIM_THROW);
}

/* ===========================================================================
 *  IMPACT  -  what happens when a snowball touches something
 * ========================================================================= */
public fw_Touch(ent, other)
{
    if (!pev_valid(ent))
        return FMRES_IGNORED;

    // Only react if the thing that touched is actually one of our snowballs.
    new cls[16];
    pev(ent, pev_classname, cls, charsmax(cls));
    if (!equal(cls, SNOWBALL_CLASS))
        return FMRES_IGNORED;

    new owner = pev(ent, pev_owner);

    // Self-touch handling: a snowball spawns near the thrower's bbox and will
    // touch the owner on the first frame. Skip those early frames. After a short
    // grace window, allow self-hits so a snowball thrown straight up at the sky
    // comes back down and damages the player who threw it (self-inflicted).
    if (other == owner)
    {
        new Float:flThrowTime;
        pev(ent, pev_dmgtime, flThrowTime);
        if (get_gametime() - flThrowTime < 0.4)
            return FMRES_IGNORED;
        // fall through: treat as a normal player hit on the owner.
    }

    new Float:vOrigin[3];
    pev(ent, pev_origin, vOrigin);

    // The snowball has a tiny SOLID_BBOX (~1 unit) but its visible model is much
    // bigger, so a raw pev_origin sits a few units in front of the actual surface.
    // Traceline a short distance along the velocity to find the real impact point;
    // use that for the decal and the gib burst so they line up with the wall and
    // the snowball does not visually "vanish" a few units short of contact.
    new Float:vVelDir[3];
    pev(ent, pev_velocity, vVelDir);
    new Float:vSpeed = vector_length(vVelDir);
    new Float:vEnd[3];
    if (vSpeed > 0.0)
    {
        // Step ~6 units forward along the flight direction (enough to cover the
        // snowball model radius without overshooting through thin walls).
        new Float:invS = 6.0 / vSpeed;
        vEnd[0] = vOrigin[0] + vVelDir[0] * invS;
        vEnd[1] = vOrigin[1] + vVelDir[1] * invS;
        vEnd[2] = vOrigin[2] + vVelDir[2] * invS;
    }
    else
    {
        vEnd[0] = vOrigin[0];
        vEnd[1] = vOrigin[1];
        vEnd[2] = vOrigin[2];
    }

    // TraceLine ignore-monsters from origin to vEnd; take the hit point if any.
    new Float:vTraceEnd[3];
    engfunc(EngFunc_TraceLine, vOrigin, vEnd, IGNORE_MONSTERS, ent, 0);
    new Float:flFraction;
    get_tr2(0, TR_flFraction, flFraction);
    if (flFraction < 1.0)
        get_tr2(0, TR_vecEndPos, vTraceEnd);
    else
    {
        // No solid in the way (player touch, or first-frame collide): use vEnd.
        vTraceEnd[0] = vEnd[0];
        vTraceEnd[1] = vEnd[1];
        vTraceEnd[2] = vEnd[2];
    }

    // Use the trace endpoint for the visible effects so they snap to the wall.
    vOrigin[0] = vTraceEnd[0];
    vOrigin[1] = vTraceEnd[1];
    vOrigin[2] = vTraceEnd[2];

    // Did it hit a player?
    if (other >= 1 && other <= g_maxPlayers && is_user_alive(other))
    {
        emit_sound(other, CHAN_VOICE, SND_HIT_PLAYER, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

        // Give the victim a small playful shove.
        new Float:vVel[3];
        pev(other, pev_velocity, vVel);
        vVel[0] += 10.0;
        vVel[1] += 10.0;
        vVel[2] -= 10.0;
        set_pev(other, pev_velocity, vVel);

        // Always damage on a player hit (enemy OR self-inflicted from a sky bounce).
        // IMPORTANT: credit the THROWER (the player) as inflictor, NOT the snowball
        // entity - TFC's death code would crash on the made-up "snowball" entity.
        // The legacy sb_snowfight cvar is left registered for backwards compatibility
        // but no longer gates damage; damage is now always on.
        if (owner >= 1 && owner <= g_maxPlayers && is_user_alive(owner))
            ExecuteHamB(Ham_TakeDamage, other, owner, owner, get_pcvar_float(g_pDamage), DMG_FREEZE);
    }
    else
    {
        // Hit a wall, floor, or other object.
        emit_sound(ent, CHAN_VOICE, SND_HIT_WORLD, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

        // If the thing we hit is a button, trigger it (so snowballs can press
        // buttons in the map - elevators, doors, etc). USE_TOGGLE = 2 fires the
        // button once with the thrower credited as the user.
        if (pev_valid(other) && owner >= 1 && owner <= g_maxPlayers && is_user_connected(owner))
        {
            new other_cls[32];
            pev(other, pev_classname, other_cls, charsmax(other_cls));
            if (equal(other_cls, "func_button")
             || equal(other_cls, "func_rot_button")
             || equal(other_cls, "momentary_rot_button"))
            {
                ExecuteHamB(Ham_Use, other, owner, owner, 2, 1.0);
            }
        }
    }

    // World impact mark like the original code (TE_WORLDDECAL / TE_DECAL).
    new msgsend = TE_WORLDDECAL;
    new entityIndex = 0;
    if (pev_valid(other) && other > g_maxPlayers)
    {
        if (pev(other, pev_solid) == SOLID_BSP)
        {
            msgsend = TE_DECAL;
            entityIndex = other;
        }
    }

    new iOrigin[3];
    iOrigin[0] = floatround(vOrigin[0]);
    iOrigin[1] = floatround(vOrigin[1]);
    iOrigin[2] = floatround(vOrigin[2]);

    new decal = engfunc(EngFunc_DecalIndex, "{break3");
    if (decal > 0)
    {
        message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
        write_byte(msgsend);
        write_coord(iOrigin[0]);
        write_coord(iOrigin[1]);
        write_coord(iOrigin[2]);
        write_byte(decal);
        if (entityIndex)
            write_short(entityIndex);
        message_end();
    }

    // Make the snowball "shatter" into little snow chunks at the impact point.
    SnowBurst(vOrigin);

    // Flag the snowball to be deleted (safer than deleting it during a touch).
    set_pev(ent, pev_flags, pev(ent, pev_flags) | FL_KILLME);
    return FMRES_SUPERCEDE;
}

// Engine think handler. Fires once for any entity whose pev_nextthink elapsed.
// We only care about our own snowballs - everything else is left untouched so
// other plugins / the game itself keep working normally.
public fw_Think(ent)
{
    if (!pev_valid(ent))
        return FMRES_IGNORED;

    new cls[16];
    pev(ent, pev_classname, cls, charsmax(cls));
    if (!equal(cls, SNOWBALL_CLASS))
        return FMRES_IGNORED;

    // 30 seconds elapsed since throw and the snowball is still here (no touch
    // happened). Mark it for the engine to remove on the next frame.
    set_pev(ent, pev_flags, pev(ent, pev_flags) | FL_KILLME);
    return FMRES_SUPERCEDE;
}

// Spawn a little burst of "snow" model chunks at a point (visual only).
SnowBurst(const Float:origin[3])
{
    new iOrigin[3];
    iOrigin[0] = floatround(origin[0]);
    iOrigin[1] = floatround(origin[1]);
    iOrigin[2] = floatround(origin[2]);

    // NOTE: MSG_BROADCAST (not MSG_PVS). message_begin's origin parameter is a
    // Float[3], not an int[3] - passing iOrigin to MSG_PVS made PVS culling
    // reject the message for most clients, so gibs only "sometimes" appeared.
    // Broadcast is fine for a small temp-entity burst and guarantees visibility.
    message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
    write_byte(TE_BREAKMODEL);
    write_coord(iOrigin[0]);
    write_coord(iOrigin[1]);
    write_coord(iOrigin[2]);
    write_coord(20);            // size of the box the chunks spawn in
    write_coord(20);
    write_coord(20);
    write_coord(0);             // base movement
    write_coord(0);
    write_coord(25);            // a little upward push
    write_byte(15);             // random extra speed
    write_short(g_idxSnowGibs); // which model the chunks use
    write_byte(8);              // how many chunks
    write_byte(25);             // how long they last (x 0.1 seconds)
    write_byte(0);              // flags
    message_end();

    // Extra visible gib chunks, closer to the original TE_MODEL shatter effect.
    for (new i = 0; i < 3; i++)
    {
        message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
        write_byte(TE_MODEL);
        write_coord(iOrigin[0]);
        write_coord(iOrigin[1]);
        write_coord(iOrigin[2] + 4);
        write_coord(random_num(-90, 90));
        write_coord(random_num(-90, 90));
        write_coord(random_num(0, 120));
        write_angle(0);
        write_short(g_idxSnowball);
        write_byte(0);
        write_byte(20);
        message_end();
    }
}

/* ===========================================================================
 *  HUD  -  draw the "Snowballs: X / Y" counter on the player's screen
 * ========================================================================= */
UpdateHud(id)
{
    if (!is_user_alive(id) || !get_pcvar_num(g_pEnabled))
        return;

    new maxClip = get_pcvar_num(g_pClip);

    // Light-blue text, bottom-centre. Hold time MUST exceed our refresh interval
    // (0.1s) and there must be no fade-out, otherwise the message fades between
    // refreshes and looks like it is flickering.
    //   x=-1.0, y=0.85, effect=0 (fade in/out), r,g,b,
    //   fxtime=0.0, holdtime=0.5, fadein=0.0, fadeout=0.0, channel=-1
    set_hudmessage(120, 200, 255, -1.0, 0.85, 0, 0.0, 2.0, 0.0, 0.0, 2);

    // Check if in reloading state (mode 4)
    if (g_snowMode[id] == 4)
        ShowSyncHudMsg(id, g_hudSync, "Snowball Gun: reloading...");
    else
        ShowSyncHudMsg(id, g_hudSync, "Snowballs: %d / %d", g_clip[id], maxClip);
}

// Called frequently to manage weapon state and send necessary client messages,
// matching the original C++ SnowTick behavior.
public RefreshAllHud()
{
    if (!get_pcvar_num(g_pEnabled))
        return;

    new Float:flNow = get_gametime();
    new msgAmmoX = get_user_msgid("AmmoX");
    new msgWeapPickup = get_user_msgid("WeapPickup");
    new msgCurWeapon = get_user_msgid("CurWeapon");

    for (new id = 1; id <= g_maxPlayers; id++)
    {
        if (!is_user_alive(id))
            continue;

        // STATE 3: EQUIPPING (weapon pickup just happened, send equip messages after delay)
        if (g_snowMode[id] == 3 && flNow >= g_equipTime[id])
        {
            // Tell the client how many snowballs we have (two separate messages like original)
            message_begin(MSG_ONE, msgAmmoX, _, id);
            write_byte(16);                     // ammo slot 16
            write_byte(g_clip[id]);             // how many snowballs
            message_end();

            message_begin(MSG_ONE, msgAmmoX, _, id);
            write_byte(17);                     // ammo slot 17 (clip)
            write_byte(1);                      // 1 in the clip
            message_end();

            // Tell the client the weapon was picked up (weapon ID 26 = snowball)
            message_begin(MSG_ONE, msgWeapPickup, _, id);
            write_byte(26);                     // weapon ID
            message_end();

            // Equip the snowball gun as the active weapon.
            // gmsgCurWeapon: state (1=equipped), weapon_id (26), clip = -1 (255).
            // -1 means "no clip display" so the HUD shows ammo only and TFC does
            // not try to drive a clip refill animation. This matches the original
            // cpp's SnowShowWep (WRITE_BYTE(-1)).
            message_begin(MSG_ONE, msgCurWeapon, _, id);
            write_byte(1);                      // state: 1 = equipped
            write_byte(26);                     // weapon ID: 26 = snowball
            write_byte(255);                    // clip = -1 (no clip box)
            message_end();

            // Send initial weapon animation.
            SendWeaponAnim(id, g_clip[id] > 0 ? ANIM_IDLE_LOADED : ANIM_IDLE_EMPTY);

            g_snowMode[id] = 0;  // done equipping
        }

        // STATE 4: RELOADING (increment ammo when reload time elapses)
        if (g_snowMode[id] == 4 && flNow >= g_equipTime[id])
        {
            // Refill full clip when reload completes (school-friendly, predictable behavior).
            g_clip[id] = get_pcvar_num(g_pClip);

            // Update ammo display
            message_begin(MSG_ONE, msgAmmoX, _, id);
            write_byte(16);                     // ammo slot 16
            write_byte(g_clip[id]);             // new snowball count
            message_end();

            message_begin(MSG_ONE, msgAmmoX, _, id);
            write_byte(17);                     // ammo slot 17 (clip)
            write_byte(1);                      // 1 in the clip
            message_end();

            // Return to idle pose
            SendWeaponAnim(id, ANIM_IDLE_LOADED);

            g_snowMode[id] = 0;  // done reloading
        }

        // Always update the HUD text display
        UpdateHud(id);
    }
}

