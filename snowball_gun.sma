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
 *          tfc/models/snowball/snowball.mdl      (the normal flying snowball)
 *          tfc/models/snowball/largesnowball.mdl (Mag/Firerate buff projectile)
 *          tfc/models/snowball/massivesnowball.mdl (Big Snow rolling projectile)
 *          tfc/models/snowball/snowgibs.mdl      (the little chunks when it breaks)
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
 *          tfc/sound/snowball/demo_explosion.wav (played when Demo snowballs explode)
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
 *     sb_clip           6        How many snowballs fit in the gun before reload.   [default 6]
 *     sb_cooldown       0.5      Seconds between throws.                            [default 0.5]
 *     sb_reload_time    1.5      Seconds a reload takes.                            [default 1.5]
 *     sb_speed          1000     How fast a thrown snowball flies.                  [default 1000]
 *     sb_snowfight      1        1 = snowballs hurt players, 0 = harmless fun.      [default 1]
 *     sb_damage         20       Damage per hit when sb_snowfight is 1.             [default 20]
 *     sb_buff_jumpheight      420.0   Jump buff upward launch velocity.           [default 420.0]
 *     sb_buff_mag_bonus       4       Extra snowballs Big/Mag adds to clip.       [default 4]
 *     sb_buff_fire_rate       1.8     Big/Mag fire-rate multiplier.               [default 1.8]
 *     sb_buff_mag_damage      35.0    Damage per Mag/Firerate direct hit.         [default 35.0]
 *     sb_wall_durability      360.0   Snow wall health before it breaks.          [default 360.0]
 *     sb_wall_push_margin     20.0    Extra soft-collision thickness for walls.   [default 20.0]
 *     sb_bigsnow_speed_mult   0.55    Big Snowball ground-roll speed multiplier.  [default 0.55]
 *     sb_demo_explosion_radius 180.0  Demo snowball blast damage radius.          [default 180.0]
 *     sb_demo_damage           35.0   Demo explosion damage.                      [default 35.0]
 *     sb_demo_max_snowballs    5      Max sticky demo snowballs per player.       [default 5]
 *     sb_demo_sprite_scale     14     Demo explosion sprite scale.                [default 14]
 *     sb_trail_enabled       1       1 = snowball trails on, 0 = trails off.       [default 1]
 *     sb_trail_width         3       Width/size of snowball trail beam.            [default 3]
 *     sb_freeze_patch_duration 15.0    Freeze patch lifetime in seconds.           [default 15.0]
 *     sb_freeze_slow_factor     0.45   Velocity multiplier while slowed by freeze. [default 0.45]
 *     sb_freeze_patch_charges  5       Freeze patches per Freeze buff.             [default 5]
 *     sb_freeze_patch_radius   75.0   Freeze patch gameplay radius.               [default 75.0]
 *     sb_freeze_patch_scale    1.0    Visual scale hint for freeze patch model.   [default 1.0]
 *
 *  Example tfc/server.cfg lines for a harmless 7-year-old snowball party:
 *     sb_enabled   1
 *     sb_snowfight 0
 *
 * ===========================================================================
 */

#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <fun>
#include <file>

#define PLUGIN  "TFC Snowball Gun"
#define VERSION "1.1-buffs-v67"
#define AUTHOR  "MrKoala"

/* ---------------------------------------------------------------------------
 *  CONTROLS  -  which keys do what
 *  IN_ATTACK  = mouse button 1 (throw)
 *  IN_RELOAD  = the reload key, normally "R" (reload)
 *  You normally do not need to change these.
 * ------------------------------------------------------------------------- */
#define THROW_BUTTON    IN_ATTACK
#define RELOAD_BUTTON   IN_RELOAD
#define DETONATE_BUTTON IN_ATTACK2

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

#if !defined DMG_BLAST
    #define DMG_BLAST      (1 << 6)
#endif

#if !defined TE_EXPLFLAG_NOSOUND
    #define TE_EXPLFLAG_NOSOUND 4
#endif

// Spawnflag used by the original HL/TFC weapon code: when a weapon entity has
// this flag set, it disappears after the first pickup instead of re-spawning
// on the world. We need it so the axe we create just to give to the player
// does not leave a permanent floating pickup behind.
#if !defined SF_NORESPAWN
    #define SF_NORESPAWN     (1 << 30)
#endif

#if !defined kRenderTransAdd
    #define kRenderTransAdd 5
#endif

#if !defined kRenderFxGlowShell
    #define kRenderFxGlowShell 3
#endif

/* ---------------------------------------------------------------------------
 *  RESOURCES  -  the model and sound files (see the big FILES list above).
 *  If you do not have custom snowball art yet, change MODEL_SNOWBALL and
 *  MODEL_SNOWGIBS to a model that already exists, e.g. "models/grenade.mdl".
 * ------------------------------------------------------------------------- */
new const MODEL_SNOWBALL[]      = "models/snowball/snowball.mdl";         // the flying snowball
new const MODEL_SNOWGIBS[]      = "models/snowball/snowgibs.mdl";         // chunks when it breaks
new const MODEL_LARGE_SNOWBALL[] = "models/snowball/largesnowball.mdl";    // Mag/Firerate larger thrown snowball
new const MODEL_BIG_SNOWBALL[]  = "models/snowball/massivesnowball.mdl";   // Big Snow rolling massive snowball
new const MODEL_EXPLOSIVE_BALL[] = "models/snowball/explosiveball.mdl";   // demo/explosive thrown snowball
new const MODEL_ICE_BALL[]       = "models/snowball/iceball.mdl";         // freeze thrown snowball
new const MODEL_FREEZE_PATCH[]  = "models/snowball/groundfrost1.mdl";     // ice/freeze patch
new const MODEL_SNOW_WALL[]     = "models/snowball/snowwall.mdl";         // snow wall
// Frozen player overlay model is currently unused. Keep this commented until the overlay feature is re-enabled.
// new const MODEL_FROZEN_PLAYER[] = "models/snowball/frozenman.mdl";
new const MODEL_VIEW[]          = "models/snowball/v_snowball.mdl";       // first-person normal snowball view model
new const MODEL_WEAPON[]        = "models/snowball/p_snowball.mdl";       // third-person normal snowball held model
new const MODEL_VIEW_LARGE[]    = "models/snowball/v_largesnowball.mdl";  // first-person Mag/Firerate snowball view model
new const MODEL_WEAPON_LARGE[]  = "models/snowball/p_largesnowball.mdl";  // third-person Mag/Firerate snowball held model
new const MODEL_VIEW_EXPLOSIVE[] = "models/snowball/v_explosiveball.mdl"; // first-person Demo snowball view model
new const MODEL_WEAPON_EXPLOSIVE[] = "models/snowball/p_explosiveball.mdl"; // third-person Demo snowball held model
new const MODEL_VIEW_ICE[]      = "models/snowball/v_iceball.mdl";        // first-person Freeze snowball view model
new const MODEL_WEAPON_ICE[]    = "models/snowball/p_iceball.mdl";        // third-person Freeze snowball held model
new const SPRITE_TRAIL[]        = "sprites/laserbeam.spr";                // standard TFC file
new const SPRITE_BIGPUFF[]      = "sprites/snowball/bigpuff.spr";         // explosion puff

new const SND_THROW[]       = "snowball/throw.wav";             // thrown
new const SND_HIT_WORLD[]   = "snowball/hit.wav";               // hit a wall/floor
new const SND_HIT_PLAYER[]  = "snowball/hitplayer.wav";         // hit a player
new const SND_DEMO_EXPLOSION[] = "snowball/demo_explosion.wav"; // demo snowball explosion
new const SND_DEMO_EXPLOSION_FILE[] = "sound/snowball/demo_explosion.wav";
new const SND_WALL_DEPLOY[] = "snowball/snowwall_deploy.wav";   // snow wall deploy sound
new const SND_WALL_COLLAPSE[] = "snowball/snowwall_collapse.wav"; // snow wall collapse sound
new const SND_INVIS[] = "snowball/invisibility.wav";        // optional invisibility activation sound
new const SND_INVIS_FILE[] = "sound/snowball/invisibility.wav";

new const SNOWBALL_CLASS[]     = "snowball";        // internal name we give our thrown entity
new const FREEZE_PATCH_CLASS[] = "snow_freeze_patch";
new const SNOW_WALL_CLASS[]    = "snow_wall";
new const SNOW_WALL_PREVIEW_CLASS[] = "snow_wall_preview";

/* ---------------------------------------------------------------------------
 *  GLOBAL VARIABLES  -  the plugin's memory while the server runs
 * ------------------------------------------------------------------------- */
new g_idxSnowGibs;          // precached id of the "break into chunks" model
new g_idxSnowball;          // precached id of the flying snowball model
new g_idxTrail;             // precached id of the trail sprite
new g_idxBigPuff;           // precached id of the explosion puff sprite
new bool:g_haveBigSnowballModel;
new bool:g_haveLargeSnowballModel;
new bool:g_haveExplosiveBallModel;
new bool:g_haveIceBallModel;
new bool:g_haveFreezePatchModel;
new bool:g_haveSnowWallModel;
new bool:g_haveInvisSound;
new bool:g_haveDemoExplosionSound;
new g_maxPlayers;           // how many player slots the server has
new bool:g_haveLargeViewModel;   // are the Mag/Firerate v_/p_ model files present?
new bool:g_haveExplosiveViewModel; // are the Demo v_/p_ model files present?
new bool:g_haveIceViewModel;     // are the Freeze v_/p_ model files present?
new g_iszViewModel;              // allocated engine string for MODEL_VIEW
new g_iszWeaponModel;            // allocated engine string for MODEL_WEAPON
new g_iszViewModelLarge;         // allocated engine string for MODEL_VIEW_LARGE
new g_iszWeaponModelLarge;       // allocated engine string for MODEL_WEAPON_LARGE
new g_iszViewModelExplosive;     // allocated engine string for MODEL_VIEW_EXPLOSIVE
new g_iszWeaponModelExplosive;   // allocated engine string for MODEL_WEAPON_EXPLOSIVE
new g_iszViewModelIce;           // allocated engine string for MODEL_VIEW_ICE
new g_iszWeaponModelIce;         // allocated engine string for MODEL_WEAPON_ICE

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
new bool:g_mustReleaseThrow[33];// used to block the respawn left click from throwing a snowball on spawn


// Snowball buff state. Buffs are per-player flags, not global CVARs.
#define BUFF_NONE       0

// Defense pool
#define BUFF_FREEZE     1   // freeze path / direct slow
#define BUFF_WALL       2   // temporary destructible snow wall
#define BUFF_EXPLOSIVE  3   // demoman snowballs: stick + right-click detonate
#define BUFF_MAG        4   // magazine upgrade + fire-rate boost
#define BUFF_BIGMAG     BUFF_MAG // backwards-compatible alias for older code/comments

// Attack pool
#define BUFF_BIGSNOW    5   // big snowball that can break snow walls
#define BUFF_INVIS      6   // short invisibility
#define BUFF_JUMP       7   // higher/faster jumps
#define BUFF_ARMOR      8   // temporary health/armor boost

// Legacy/manual-only buff kept for sb_givebuff link; not used in random backpack rotation.
#define BUFF_LINK       9   // hit player -> teleport to their position

#define BUFF_TASK_BASE  22000
#define INVIS_TASK_BASE 26000
#define BUFF_DURATION   20.0
#define BUFF_PICKUP_COOLDOWN 0.75
#define DEFAULT_BIGMAG_CLIP_BONUS 4
#define BIGSNOW_SPEED_MULT 1.35       // (thrown arc variant only) multiplier for a directly-thrown big snowball
// NOTE: BIGSNOW_ROLL_SPEED_MULT below is the ORIGINAL hard-coded roll multiplier.
// It has been superseded by the live-tunable cvar "sb_bigsnow_speed_mult" (see
// g_pBigSnowSpeedMult). It is kept only as documentation of the historical value.
#define BIGSNOW_ROLL_SPEED_MULT 0.35
#define BIGSNOW_ROLL_RADIUS 28.0      // collision/half-size radius of the rolling ball, in units
#define BIGSNOW_LAUNCH_FORWARD 56.0   // how far in front of the player the ball is placed on spawn
#define BIGSNOW_FLOOR_TRACE_UP 48.0   // how high above the player we start the "find the floor" trace
#define BIGSNOW_FLOOR_TRACE_DOWN 256.0// how far down that trace searches for a floor
#define BIGSNOW_FLOOR_CLEARANCE 4.0   // small gap kept between the ball and the floor so it never clips in
#define BIGSNOW_ANIM_ROLLFORWARD 1   // model sequence index for the rollforward animation
#define SPECIAL_SNOWBALL_ROLL_SEQUENCE 1 // roll1 sequence for small/special snowball models
#define SPECIAL_SNOWBALL_ROLL_FRAMERATE 1.0
#define BIGSNOW_ROLL_Z_OFFSET 6.0     // height the ball rides above the floor while rolling
#define BIGSNOW_MAX_BOUNCES 2         // wall bounces before the ball breaks
#define BIGSNOW_CHARGES 2             // how many rolling big snowballs one Big Snow buff grants
#define BIGSNOW_ROLL_LIFETIME 12.0    // seconds a rolling ball lives before it auto-removes
// How often (seconds) the rolling ball recalculates its own position. Lower = smoother.
// This used to be 0.05 (20 Hz) which looked choppy; 0.02 (50 Hz) is far smoother.
#define BIGSNOW_ROLL_THINK 0.02
#define BIGSNOW_ROLL_MAX_STEP_DOWN 30.0 // biggest downward step the ball will follow before it "falls"
#define BIGSNOW_ROLL_FALL_SPEED -360.0  // downward speed while airborne (off a ledge), units/sec
#define DEFAULT_BIGMAG_FIRE_RATE 1.8 // higher value = faster fire rate while Mag is active
#define DEFAULT_JUMP_BOOST_Z 420.0   // strong upward impulse; applied after normal jump starts
#define JUMP_BOOST_XY_MULT 1.12
#define JUMP_BOOST_COOLDOWN 0.25
#define DEFAULT_FREEZE_PATCH_RADIUS 75.0
#define DEFAULT_FREEZE_PATCH_CHARGES 5
#define DEFAULT_FREEZE_PATCH_LIFETIME 15.0
#define FREEZE_SLOW_MULT 0.45
#define WALL_LIFETIME 15.0
#define DEFAULT_WALL_HEALTH 360.0
#define DEFAULT_WALL_HALF_THICKNESS 14.0
#define DEFAULT_WALL_HALF_LENGTH 152.0
#define DEFAULT_WALL_HEIGHT 88.0
#define WALL_MARKER_Z_OFFSET 24.0
#define LINK_GHOST_MAX_TIME 1.5
#define LINK_GHOST_SEPARATE_DIST 42.0
#define LINK_GHOST_SEPARATE_Z 82.0
#define INVIS_RENDER_AMOUNT 0
#define INVIS_FROZEN_RENDER_AMOUNT 5

// snow_wall.mdl sequences, in the order described:
// 0 deployed (idle out), 1 deploy, 2 undeploy, 3 collapsed (idle in ground)
#define WALL_ANIM_DEPLOYED     0
#define WALL_ANIM_DEPLOY       1
#define WALL_ANIM_UNDEPLOY     2
#define WALL_ANIM_COLLAPSED    3
#define WALL_DEPLOY_TIME       1.0
#define WALL_UNDEPLOY_TIME     1.0
#define WALL_STATE_DEPLOYING   1
#define WALL_STATE_DEPLOYED    2
#define WALL_STATE_UNDEPLOYING 3

new g_activeBuff[33];              // BUFF_* currently active for this player
new Float:g_lastBuffPickup[33];    // pickup debounce so one touch does not fire many times
new g_lastBuffEnt[33];             // last touched goal/backpack entity
new Float:g_flNextDetonate[33];    // right-click detonation cooldown for explosive buff
new Float:g_freezeSlowUntil[33];   // temporary slow from freeze direct hit / patch
new g_freezeCharges[33];          // remaining Freeze patch charges for the active Freeze buff
new g_bigSnowCharges[33];         // remaining Big Snowball shots for the active Big Snow buff
new Float:g_buffEndTime[33];       // game-time when the current buff expires, for HUD countdown
new Float:g_flNextJumpBoost[33];   // prevents jump boost from stacking many times in one jump
new g_wallPreviewEnt[33];           // translucent preview entity for placing Snow Wall buff
new bool:g_linkGhost[33];              // link buff: temporarily invisible/non-solid after teleporting inside target
new g_linkGhostTarget[33];             // target player currently overlapped by link teleport
new Float:g_linkGhostUntil[33];        // safety timeout for temporary link ghost state
new g_lastRandomBuff[33];          // legacy anti-repeat value for debug/HUD only
new g_offenseBuffMask;                // team-wide no-repeat rotation for attack buffs
new g_defenseBuffMask;                // team-wide no-repeat rotation for defense buffs
new bool:g_invisActive[33];          // right-click activated invisibility state
new Float:g_invisEndTime[33];           // time when active invisibility ends, for HUD timer
new bool:g_armorBuffActive[33];       // armor buff restore tracking
new bool:g_freezeAuraActive[33];       // light-blue glow while frozen/slowed
new Float:g_armorStartHealth[33];
new Float:g_armorStartArmor[33];
new Float:g_armorStartMaxHealth[33];

new const g_BuffIcons[10][] =
{
    "",
    "dmg_bio",        // freeze / defense
    "dmg_cold",       // wall / defense
    "dmg_bio",        // explosive / defense
    "item_battery",   // mag/fire-rate / defense
    "dmg_cold",       // big snowball / attack
    "dmg_shock",      // invisibility / attack
    "item_longjump",  // jump / attack
    "item_battery",   // armor / attack
    "item_longjump"   // legacy link / manual
};

// Cached pointers to the CVARs (faster than looking them up by name every frame)
new g_pEnabled, g_pClip, g_pCooldown, g_pReloadTime, g_pSpeed, g_pSnowfight, g_pDamage;
new g_pBuffJumpHeight, g_pBuffMagBonus, g_pBuffFireRate, g_pBuffMagDamage, g_pWallDurability, g_pWallPushMargin, g_pWallLifetime, g_pWallHalfThickness, g_pWallHalfLength, g_pWallHeight, g_pDemoExplosionRadius, g_pDemoDamage, g_pDemoMaxSnowballs, g_pDemoSpriteScale, g_pTrailEnabled, g_pTrailWidth, g_pFreezePatchDuration, g_pFreezePatchRadius, g_pFreezePatchScale, g_pFreezePatchCharges, g_pFreezeSlowFactor, g_pBigSnowSpeedMult, g_pBigSnowRollSequence, g_pBuffPickupWhitelist, g_pInvisDuration, g_pArmorDuration, g_pArmorHealthBonus, g_pArmorArmorBonus;

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
    g_idxBigPuff  = precache_model(SPRITE_BIGPUFF);

    if (file_exists(MODEL_LARGE_SNOWBALL))
    {
        precache_model(MODEL_LARGE_SNOWBALL);
        g_haveLargeSnowballModel = true;
    }
    else
    {
        g_haveLargeSnowballModel = false;
        server_print("[Snowball Gun] Optional model missing: %s -- Mag/Firerate snowballs use normal snowball model.", MODEL_LARGE_SNOWBALL);
    }

    if (file_exists(MODEL_BIG_SNOWBALL))
    {
        precache_model(MODEL_BIG_SNOWBALL);
        g_haveBigSnowballModel = true;
    }
    else
    {
        g_haveBigSnowballModel = false;
        server_print("[Snowball Gun] Optional model missing: %s -- Big Snow buff uses normal snowball model.", MODEL_BIG_SNOWBALL);
    }

    if (file_exists(MODEL_EXPLOSIVE_BALL))
    {
        precache_model(MODEL_EXPLOSIVE_BALL);
        g_haveExplosiveBallModel = true;
    }
    else
    {
        g_haveExplosiveBallModel = false;
        server_print("[Snowball Gun] Optional model missing: %s -- Demo snowballs use normal snowball model.", MODEL_EXPLOSIVE_BALL);
    }

    if (file_exists(MODEL_ICE_BALL))
    {
        precache_model(MODEL_ICE_BALL);
        g_haveIceBallModel = true;
    }
    else
    {
        g_haveIceBallModel = false;
        server_print("[Snowball Gun] Optional model missing: %s -- Freeze snowballs use normal snowball model.", MODEL_ICE_BALL);
    }

    if (file_exists(MODEL_FREEZE_PATCH))
    {
        precache_model(MODEL_FREEZE_PATCH);
        g_haveFreezePatchModel = true;
    }
    else
    {
        g_haveFreezePatchModel = false;
        server_print("[Snowball Gun] Optional model missing: %s -- Freeze patch uses snow chunks as placeholder.", MODEL_FREEZE_PATCH);
    }

    if (file_exists(MODEL_SNOW_WALL))
    {
        precache_model(MODEL_SNOW_WALL);
        g_haveSnowWallModel = true;
    }
    else
    {
        g_haveSnowWallModel = false;
        server_print("[Snowball Gun] Optional model missing: %s -- Snow wall uses snowball model as placeholder.", MODEL_SNOW_WALL);
    }

    // First-person view models and third-person held models.
    // Each special projectile can have a matching v_/p_ pair. Massive Big Snow
    // intentionally falls back to the normal pair because it has no matching hand models.
    if (file_exists(MODEL_VIEW) && file_exists(MODEL_WEAPON))
    {
        precache_model(MODEL_VIEW);
        precache_model(MODEL_WEAPON);
        g_iszViewModel = engfunc(EngFunc_AllocString, MODEL_VIEW);
        g_iszWeaponModel = engfunc(EngFunc_AllocString, MODEL_WEAPON);
    }
    else
    {
        g_iszViewModel = 0;
        g_iszWeaponModel = 0;
        if (!file_exists(MODEL_VIEW))
            server_print("[Snowball Gun] Optional default/normal view model missing: %s -- hand models disabled/fallback when needed.", MODEL_VIEW);
        if (!file_exists(MODEL_WEAPON))
            server_print("[Snowball Gun] Optional default/normal weapon model missing: %s -- hand models disabled/fallback when needed.", MODEL_WEAPON);
    }

    if (file_exists(MODEL_VIEW_LARGE) && file_exists(MODEL_WEAPON_LARGE))
    {
        precache_model(MODEL_VIEW_LARGE);
        precache_model(MODEL_WEAPON_LARGE);
        g_haveLargeViewModel = true;
        g_iszViewModelLarge = engfunc(EngFunc_AllocString, MODEL_VIEW_LARGE);
        g_iszWeaponModelLarge = engfunc(EngFunc_AllocString, MODEL_WEAPON_LARGE);
    }
    else
    {
        g_haveLargeViewModel = false;
        g_iszViewModelLarge = 0;
        g_iszWeaponModelLarge = 0;
        if (!file_exists(MODEL_VIEW_LARGE))
            server_print("[Snowball Gun] Optional Mag/Firerate view model missing: %s -- falling back when needed.", MODEL_VIEW_LARGE);
        if (!file_exists(MODEL_WEAPON_LARGE))
            server_print("[Snowball Gun] Optional Mag/Firerate weapon model missing: %s -- falling back when needed.", MODEL_WEAPON_LARGE);
    }

    if (file_exists(MODEL_VIEW_EXPLOSIVE) && file_exists(MODEL_WEAPON_EXPLOSIVE))
    {
        precache_model(MODEL_VIEW_EXPLOSIVE);
        precache_model(MODEL_WEAPON_EXPLOSIVE);
        g_haveExplosiveViewModel = true;
        g_iszViewModelExplosive = engfunc(EngFunc_AllocString, MODEL_VIEW_EXPLOSIVE);
        g_iszWeaponModelExplosive = engfunc(EngFunc_AllocString, MODEL_WEAPON_EXPLOSIVE);
    }
    else
    {
        g_haveExplosiveViewModel = false;
        g_iszViewModelExplosive = 0;
        g_iszWeaponModelExplosive = 0;
        if (!file_exists(MODEL_VIEW_EXPLOSIVE))
            server_print("[Snowball Gun] Optional Demo/Explosive view model missing: %s -- falling back when needed.", MODEL_VIEW_EXPLOSIVE);
        if (!file_exists(MODEL_WEAPON_EXPLOSIVE))
            server_print("[Snowball Gun] Optional Demo/Explosive weapon model missing: %s -- falling back when needed.", MODEL_WEAPON_EXPLOSIVE);
    }

    if (file_exists(MODEL_VIEW_ICE) && file_exists(MODEL_WEAPON_ICE))
    {
        precache_model(MODEL_VIEW_ICE);
        precache_model(MODEL_WEAPON_ICE);
        g_haveIceViewModel = true;
        g_iszViewModelIce = engfunc(EngFunc_AllocString, MODEL_VIEW_ICE);
        g_iszWeaponModelIce = engfunc(EngFunc_AllocString, MODEL_WEAPON_ICE);
    }
    else
    {
        g_haveIceViewModel = false;
        g_iszViewModelIce = 0;
        g_iszWeaponModelIce = 0;
        if (!file_exists(MODEL_VIEW_ICE))
            server_print("[Snowball Gun] Optional Freeze view model missing: %s -- falling back when needed.", MODEL_VIEW_ICE);
        if (!file_exists(MODEL_WEAPON_ICE))
            server_print("[Snowball Gun] Optional Freeze weapon model missing: %s -- falling back when needed.", MODEL_WEAPON_ICE);
    }

    precache_sound(SND_THROW);
    precache_sound(SND_HIT_WORLD);
    precache_sound(SND_HIT_PLAYER);

    if (file_exists(SND_DEMO_EXPLOSION_FILE))
    {
        precache_sound(SND_DEMO_EXPLOSION);
        g_haveDemoExplosionSound = true;
    }
    else
    {
        g_haveDemoExplosionSound = false;
        server_print("[Snowball Gun] Optional sound missing: %s -- demo explosions use normal hit sound.", SND_DEMO_EXPLOSION_FILE);
    }

    precache_sound(SND_WALL_DEPLOY);
    precache_sound(SND_WALL_COLLAPSE);

    if (file_exists(SND_INVIS_FILE))
    {
        precache_sound(SND_INVIS);
        g_haveInvisSound = true;
    }
    else
    {
        g_haveInvisSound = false;
        server_print("[Snowball Gun] Optional sound missing: %s -- invisibility activation is silent.", SND_INVIS_FILE);
    }
}



public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR);

    // Load the language file (addons/amxmodx/data/lang/snowball_gun.txt) so all
    // player messages can be shown in English, French or German. AMX Mod X picks
    // the language per player when amx_client_languages is 1, otherwise it uses
    // the server language. If a French/German line is missing, AMX Mod X falls
    // back to English automatically, so the [en] section is the safety net. If
    // the file itself is missing the plugin still runs; messages just show their
    // key names instead of text.
    register_dictionary("snowball_gun.txt");

    // Create the server settings (CVARs) with their default values.
    g_pEnabled    = register_cvar("sb_enabled",     "1");
    g_pClip       = register_cvar("sb_clip",        "6");
    g_pCooldown   = register_cvar("sb_cooldown",    "0.5");
    g_pReloadTime = register_cvar("sb_reload_time", "1.5");
    g_pSpeed      = register_cvar("sb_speed",       "1000");
    g_pSnowfight  = register_cvar("sb_snowfight",   "1");
    g_pDamage     = register_cvar("sb_damage",      "20");

    // Buff tuning CVARs. Put these in server.cfg if you want to override them.
    g_pBuffJumpHeight      = register_cvar("sb_buff_jumpheight",      "420.0"); // Jump buff upward velocity
    g_pBuffMagBonus        = register_cvar("sb_buff_mag_bonus",       "4");     // Extra snowballs in Big/Mag clip
    g_pBuffFireRate        = register_cvar("sb_buff_fire_rate",       "1.8");   // Big/Mag fire-rate multiplier
    g_pBuffMagDamage       = register_cvar("sb_buff_mag_damage",      "35.0");  // Mag/Firerate direct hit damage when snowfight is enabled
    g_pWallDurability      = register_cvar("sb_wall_durability",      "360.0"); // Snow wall health
    g_pWallPushMargin      = register_cvar("sb_wall_push_margin",     "20.0");  // Extra soft-collision thickness
    g_pWallLifetime        = register_cvar("sb_wall_lifetime",        "15.0");   // Snow wall lifetime in seconds
    g_pWallHalfThickness   = register_cvar("sb_wall_half_thickness",  "14.0");  // Half-depth of soft wall blocker, live-tunable
    g_pWallHalfLength      = register_cvar("sb_wall_half_length",     "152.0"); // Half-length of soft wall blocker, live-tunable
    g_pWallHeight          = register_cvar("sb_wall_height",          "88.0");  // Height of soft wall blocker, live-tunable
    g_pDemoExplosionRadius = register_cvar("sb_demo_explosion_radius", "180.0"); // Demo blast radius / visual size helper
    g_pDemoDamage          = register_cvar("sb_demo_damage",           "35.0");  // Demo explosion damage, defaults to Mag/Firerate damage
    g_pDemoMaxSnowballs    = register_cvar("sb_demo_max_snowballs",    "5");     // Max sticky demo snowballs per player
    g_pDemoSpriteScale     = register_cvar("sb_demo_sprite_scale",     "14");    // TE_EXPLOSION sprite scale; lower = smaller
    g_pTrailEnabled        = register_cvar("sb_trail_enabled",          "1");     // 1 = snowball trails on, 0 = off
    g_pTrailWidth          = register_cvar("sb_trail_width",            "3");     // Width/size of snowball trail beams
    g_pFreezePatchDuration = register_cvar("sb_freeze_patch_duration", "15.0");   // Freeze patch seconds
    g_pFreezePatchRadius   = register_cvar("sb_freeze_patch_radius",   "75.0");  // Gameplay slow radius around patch
    g_pFreezePatchScale    = register_cvar("sb_freeze_patch_scale",    "1.0");   // Visual model scale hint; some GoldSrc models ignore pev_scale
    g_pFreezePatchCharges  = register_cvar("sb_freeze_patch_charges",  "5");     // Freeze patches per Freeze buff
    g_pFreezeSlowFactor    = register_cvar("sb_freeze_slow_factor",    "0.45");  // Velocity multiplier while slowed by freeze patches
    g_pBigSnowSpeedMult    = register_cvar("sb_bigsnow_speed_mult",   "0.55");  // Big Snowball ground-roll speed multiplier (was 0.35, bumped so it no longer feels sluggish)
    g_pBigSnowRollSequence = register_cvar("sb_bigsnow_roll_sequence", "1");     // Model sequence index for rollforward animation
    g_pBuffPickupWhitelist = register_cvar("sb_buff_models", "backpack,pack,ammo,health,powerup"); // Comma-separated model keywords that grant buffs; flags are always rejected
    g_pInvisDuration        = register_cvar("sb_invis_duration",       "8.0");   // Attack invisibility duration
    g_pArmorDuration        = register_cvar("sb_armor_duration",       "20.0");  // Attack armor/health buff duration
    g_pArmorHealthBonus     = register_cvar("sb_armor_health",         "150.0"); // Target health while Armor buff is active
    g_pArmorArmorBonus      = register_cvar("sb_armor_armor",          "150.0"); // Target armor while Armor buff is active

    // Console help commands. Type these in the server console or a client console.
    register_concmd("sb_help",  "CmdSnowballHelp",  0, "- Shows all Snowball Gun CVARs and what they do");
    register_concmd("sb_cvars", "CmdSnowballCvars", 0, "- Shows current live Snowball Gun CVAR values");
    register_concmd("sb_givebuff", "CmdSnowballGiveBuff", 0, "<buff|clear> [player] - gives/replaces a specific buff");

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
    register_forward(FM_AddToFullPack, "fw_AddToFullPack", 1); // client-side non-solid for Link ghost

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

    // Allow snow walls to be damaged by anything that can damage info_target entities.
    RegisterHam(Ham_TakeDamage, "info_target", "fw_InfoTargetTakeDamage");

    // No Ham_Killed hook in TFC gamedata; respawn/death transitions are handled in PlayerPreThink.

    // Team changes/spawn HUD resets should clear temporary buffs.
    register_event("ResetHUD", "Event_ResetHUD", "be");
    register_event("TeamInfo", "Event_TeamInfo", "a");

    g_maxPlayers = get_maxplayers();
    ResetBuffRotation(true);
    ResetBuffRotation(false);

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
    g_freezeSlowUntil[id] = 0.0;
    g_freezeCharges[id] = 0;
    g_bigSnowCharges[id] = 0;
    g_buffEndTime[id] = 0.0;
    g_flNextJumpBoost[id] = 0.0;
    g_wallPreviewEnt[id] = 0;
    g_linkGhost[id] = false;
    g_linkGhostTarget[id] = 0;
    g_linkGhostUntil[id] = 0.0;
    g_lastRandomBuff[id] = BUFF_NONE;
    g_invisActive[id] = false;
    g_invisEndTime[id] = 0.0;
    g_armorBuffActive[id] = false;
    g_freezeAuraActive[id] = false;
    g_armorStartHealth[id] = 0.0;
    g_armorStartArmor[id] = 0.0;
    ClearPlayerBuff(id, false);
}

public client_disconnected(id)
{
    g_equipped[id]    = false;
    g_aliveInWorld[id]= false;
    g_snowMode[id]    = 0;
    g_snowSelected[id]= false;
    g_prevButtons[id] = 0;
    g_rawButtons[id]  = 0;
    g_freezeSlowUntil[id] = 0.0;
    g_freezeCharges[id] = 0;
    g_bigSnowCharges[id] = 0;
    g_buffEndTime[id] = 0.0;
    g_flNextJumpBoost[id] = 0.0;
    RestoreLinkGhost(id);
    RestoreInvisibility(id);
    RestoreFreezeAura(id);
    remove_task(INVIS_TASK_BASE + id);
    g_linkGhostTarget[id] = 0;
    g_linkGhostUntil[id] = 0.0;
    g_invisActive[id] = false;
    g_invisEndTime[id] = 0.0;
    DestroyWallPreview(id);
    ClearPlayerBuff(id, false);
    g_armorBuffActive[id] = false;
    g_freezeAuraActive[id] = false;
    g_armorStartHealth[id] = 0.0;
    g_armorStartArmor[id] = 0.0;
}

public fw_CmdStart(id, uc_handle, seed)
{
    if (!get_pcvar_num(g_pEnabled) || !is_user_connected(id))
        return FMRES_IGNORED;

    new buttons = get_uc(uc_handle, UC_Buttons);
    g_rawButtons[id] = buttons;

    // Right-click is only consumed when explosive buff uses it for remote detonation.
    if (is_user_alive(id) && g_equipped[id]
     && HasBuff(id, BUFF_EXPLOSIVE)
     && (buttons & DETONATE_BUTTON)
     && !(g_prevButtons[id] & DETONATE_BUTTON)
     && get_gametime() >= g_flNextDetonate[id])
    {
        if (HasNearbySnowballs(id))
        {
            DetonateNearbySnowballs(id);
            g_flNextDetonate[id] = get_gametime() + 0.4;
            buttons &= ~DETONATE_BUTTON;
        }
    }

    // Right-click activates the Invisibility buff. Picking it up only arms it.
    if (is_user_alive(id) && g_equipped[id]
     && HasBuff(id, BUFF_INVIS)
     && !g_invisActive[id]
     && (buttons & DETONATE_BUTTON)
     && !(g_prevButtons[id] & DETONATE_BUTTON))
    {
        ActivateInvisibility(id);
        buttons &= ~DETONATE_BUTTON;
    }

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
    new victim = get_msg_arg_int(2);

    // Reset dying player's snowball count/state
    if (victim >= 1 && victim <= g_maxPlayers)
    {
        ClearPlayerBuff(victim, false);
        g_clip[victim] = GetPlayerMaxClip(victim);
        g_mustReleaseThrow[victim] = true;
    }

    // Kill-feed rewrite only for valid snowball killer
    if (killer < 1 || killer > g_maxPlayers)
        return PLUGIN_CONTINUE;

    if (!g_equipped[killer])
        return PLUGIN_CONTINUE;

    set_msg_arg_string(3, "snowball");
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
    g_clip[id]        = GetPlayerMaxClip(id);
    g_reloading[id]   = false;
    g_flNextThrow[id] = 0.0;
    g_flReloadEnd[id] = 0.0;
    g_idlePending[id] = false;
    g_flIdleAt[id]    = 0.0;
    g_snowMode[id]    = 3;   // state: equipping
    g_equipTime[id]   = get_gametime() + 0.5;  // complete after 0.5 seconds
    g_equipped[id]    = true;
    g_snowSelected[id]= true;
    g_mustReleaseThrow[id] = true;

    // Force our snowball models so the player actually sees the snowball gun.
    ApplySnowballModels(id);
}

ApplySnowballModels(id)
{
    new wantedView = g_iszViewModel;
    new wantedWeapon = g_iszWeaponModel;

    // Select matching hand/held models for the active thrown snowball type.
    // Big Snow / massive snowball has no v_/p_ pair, so it deliberately keeps
    // the normal snowball gun models.
    switch (GetActiveBuff(id))
    {
        case BUFF_MAG:
        {
            if (g_haveLargeViewModel && g_iszViewModelLarge && g_iszWeaponModelLarge)
            {
                wantedView = g_iszViewModelLarge;
                wantedWeapon = g_iszWeaponModelLarge;
            }
        }
        case BUFF_EXPLOSIVE:
        {
            if (g_haveExplosiveViewModel && g_iszViewModelExplosive && g_iszWeaponModelExplosive)
            {
                wantedView = g_iszViewModelExplosive;
                wantedWeapon = g_iszWeaponModelExplosive;
            }
        }
        case BUFF_FREEZE:
        {
            if (g_haveIceViewModel && g_iszViewModelIce && g_iszWeaponModelIce)
            {
                wantedView = g_iszViewModelIce;
                wantedWeapon = g_iszWeaponModelIce;
            }
        }
    }

    if (!wantedView || !wantedWeapon)
        return;

    // TFC uses viewmodel/weaponmodel fields directly (same as the original C++ code).
    // IMPORTANT: only write the field if it's currently something else. The engine
    // resets a studio model's animation state every time pev_weaponmodel is
    // assigned, even when assigned the same string - so writing it every frame
    // freezes the p_model on frame 0 of its idle sequence and other players see
    // a completely static snowball gun in the player's hands. By comparing first
    // we only re-apply when TFC has actually switched the model to a class weapon
    // or when the active buff changes the snowball hand model.
    new curView = pev(id, pev_viewmodel);
    if (curView != wantedView)
        set_pev(id, pev_viewmodel, wantedView);

    new curWeap = pev(id, pev_weaponmodel);
    if (curWeap != wantedWeapon)
        set_pev(id, pev_weaponmodel, wantedWeapon);
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
        RestoreLinkGhost(id);
        RestoreFreezeAura(id);
        ClearPlayerBuff(id, false);
        g_clip[id] = GetPlayerMaxClip(id);
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

    ApplyFreezeSlow(id, flNow);

    // GoldSrc/TFC does not reliably block players with custom info_target BBOX
    // entities, so snow walls also run a small player push-out check every frame.
    BlockPlayerWithSnowWalls(id);
    UpdateLinkGhost(id);

    if (HasBuff(id, BUFF_WALL))
        UpdateWallPreview(id);
    else
        DestroyWallPreview(id);

    // Offensive Jump buff: apply once per ground jump.  This uses the raw button state
    // and a small cooldown so it still fires reliably if TFC consumes/rewrites jump edges.
    if (HasBuff(id, BUFF_JUMP)
     && (button & IN_JUMP)
     && (pev(id, pev_flags) & FL_ONGROUND)
     && flNow >= g_flNextJumpBoost[id])
    {
        ApplyJumpBoost(id);
        g_flNextJumpBoost[id] = flNow + JUMP_BOOST_COOLDOWN;
    }

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
    if ((buttonPressed & RELOAD_BUTTON) && g_clip[id] < GetPlayerMaxClip(id))
    {
        StartReload(id);
        g_prevButtons[id] = buttons;
        return FMRES_IGNORED;
    }

    // If the player held Mouse1 to respawn, require release before throwing.
    if (g_mustReleaseThrow[id])
    {
        if (button & THROW_BUTTON)
        {
            g_prevButtons[id] = buttons;
            return FMRES_IGNORED;
        }

        g_mustReleaseThrow[id] = false;
    }

    // ---- Throw a snowball (Mouse 1) ----
    // CONTINUOUS fire on hold: as long as the button is down, fire whenever the
    // cooldown allows. Kids can just hold LMB to keep throwing.
    if ((button & THROW_BUTTON) && g_clip[id] > 0 && flNow >= g_flNextThrow[id])
    {
        if (HasBuff(id, BUFF_WALL))
        {
            PlacePreviewSnowWall(id);
            ClearPlayerBuff(id, false);
            SendWeaponAnim(id, ANIM_THROW);
        }
        else
        {
            ThrowSnowball(id);
        }

        g_clip[id]--;                                               // use one snowball / wall placement
        g_flNextThrow[id] = flNow + GetPlayerThrowCooldown(id);      // start the cooldown

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
stock GetTrailWidth()
{
    new width = get_pcvar_num(g_pTrailWidth);
    if (width < 1)
        width = 1;
    if (width > 255)
        width = 255;
    return width;
}

stock AddSnowballTrail(ent, life, brightness)
{
    if (!pev_valid(ent) || !get_pcvar_num(g_pTrailEnabled))
        return;

    if (life < 1)
        life = 1;
    if (life > 255)
        life = 255;

    if (brightness < 0)
        brightness = 0;
    if (brightness > 255)
        brightness = 255;

    message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
    write_byte(TE_BEAMFOLLOW);
    write_short(ent);
    write_short(g_idxTrail);
    write_byte(life);
    write_byte(GetTrailWidth());
    write_byte(255);
    write_byte(255);
    write_byte(255);
    write_byte(brightness);
    message_end();
}

stock ApplySpecialSnowballRollAnimation(ent)
{
    if (!pev_valid(ent))
        return;

    // Thrown snowball models use sequence 1 named "roll1".
    // The MDL has 30 frames; the engine advances them while pev_framerate is active.
    set_pev(ent, pev_sequence, SPECIAL_SNOWBALL_ROLL_SEQUENCE);
    set_pev(ent, pev_frame, 0.0);
    set_pev(ent, pev_animtime, get_gametime());
    set_pev(ent, pev_framerate, SPECIAL_SNOWBALL_ROLL_FRAMERATE);
}

stock StopSnowballRollAnimation(ent)
{
    if (!pev_valid(ent))
        return;

    // Keep the model on its current roll frame, but stop advancing animation.
    // Used for deployed/stuck Demo snowballs so they no longer look like they roll.
    set_pev(ent, pev_framerate, 0.0);
    set_pev(ent, pev_animtime, get_gametime());
}

ThrowRollingBigSnowball(id)
{
    if (!is_user_alive(id))
        return;

    // Green Shell-style launch, but placed directly on the floor in front of the
    // player instead of thrown from the hand.  The model uses its rollforward
    // animation, so we do NOT apply weird manual angular velocity anymore.
    new Float:playerOrigin[3], Float:angles[3], Float:vForward[3];
    pev(id, pev_origin, playerOrigin);
    entity_get_vector(id, EV_VEC_v_angle, angles);

    angles[0] = 0.0;
    angles[2] = 0.0;
    angle_vector(angles, ANGLEVECTOR_FORWARD, vForward);
    vForward[2] = 0.0;

    new Float:dist2d = floatsqroot(vForward[0] * vForward[0] + vForward[1] * vForward[1]);
    if (dist2d <= 0.01)
    {
        vForward[0] = 1.0;
        vForward[1] = 0.0;
        dist2d = 1.0;
    }
    vForward[0] /= dist2d;
    vForward[1] /= dist2d;

    // Find the floor in front of the player and place the snowball exactly on it.
    new Float:start[3], Float:end[3], Float:floor[3], Float:spawn[3];
    start[0] = playerOrigin[0] + vForward[0] * BIGSNOW_LAUNCH_FORWARD;
    start[1] = playerOrigin[1] + vForward[1] * BIGSNOW_LAUNCH_FORWARD;
    start[2] = playerOrigin[2] + BIGSNOW_FLOOR_TRACE_UP;

    end[0] = start[0];
    end[1] = start[1];
    end[2] = start[2] - BIGSNOW_FLOOR_TRACE_DOWN;

    engfunc(EngFunc_TraceLine, start, end, IGNORE_MONSTERS, id, 0);
    new Float:frac;
    get_tr2(0, TR_flFraction, frac);
    if (frac < 1.0)
    {
        get_tr2(0, TR_vecEndPos, floor);
        spawn[0] = floor[0];
        spawn[1] = floor[1];
        spawn[2] = floor[2] + BIGSNOW_ROLL_RADIUS + BIGSNOW_FLOOR_CLEARANCE;
    }
    else
    {
        // Fallback for weird ledges/no floor trace: still launch from in front,
        // but do not give it an upward throw arc.
        spawn[0] = start[0];
        spawn[1] = start[1];
        spawn[2] = playerOrigin[2] + BIGSNOW_ROLL_RADIUS + BIGSNOW_FLOOR_CLEARANCE;
    }

    new Float:rollSpeed = get_pcvar_float(g_pSpeed) * GetBigSnowSpeedMult();
    new Float:velocity[3];
    velocity[0] = vForward[0] * rollSpeed;
    velocity[1] = vForward[1] * rollSpeed;
    velocity[2] = 0.0;

    new ent = create_entity("info_target");
    if (ent > 0)
    {
        entity_set_string(ent, EV_SZ_classname, SNOWBALL_CLASS);
        if (g_haveBigSnowballModel)
            entity_set_model(ent, MODEL_BIG_SNOWBALL);
        else
            entity_set_model(ent, MODEL_SNOWBALL);

        new Float:r = BIGSNOW_ROLL_RADIUS;
        new Float:mins[3], Float:maxs[3];
        mins[0] = -r; mins[1] = -r; mins[2] = -r;
        maxs[0] =  r; maxs[1] =  r; maxs[2] =  r;
        entity_set_size(ent, mins, maxs);

        entity_set_origin(ent, spawn);
        entity_set_vector(ent, EV_VEC_angles, angles);
        entity_set_int(ent, EV_INT_solid, SOLID_TRIGGER);
        // Use MOVETYPE_NOCLIP so the engine moves the ball purely by its velocity
        // with no collision response of its own (the think does all the world
        // tracing, floor-following and bounce maths by hand). Every think we set
        // the velocity to the exact distance the ball should travel that tick, and
        // the engine slides it there while the client interpolates the motion
        // smoothly on every rendered frame. We deliberately do NOT SetOrigin every
        // tick: teleporting the ball each think gave the client nothing to
        // interpolate, which is why the rolling looked like it ran at a very low
        // frame-rate. NOCLIP + a real velocity fixes that. (MOVETYPE_FLY would add
        // its own collision handling and fight our manual tracing, so we avoid it.)
        entity_set_int(ent, EV_INT_movetype, MOVETYPE_NOCLIP);
        entity_set_vector(ent, EV_VEC_velocity, velocity);
        entity_set_float(ent, EV_FL_friction, 0.1);

        set_pev(ent, pev_owner, id);
        set_pev(ent, pev_iuser1, BUFF_BIGSNOW);
        set_pev(ent, pev_iuser3, 1); // flat/manual rolling Big Snowball marker
        set_pev(ent, pev_iuser4, 0); // wall bounce counter
        set_pev(ent, pev_dmgtime, get_gametime());
        set_pev(ent, pev_fuser1, get_gametime() + BIGSNOW_ROLL_LIFETIME);
        set_pev(ent, pev_fuser2, vForward[0]);
        set_pev(ent, pev_fuser3, vForward[1]);
        set_pev(ent, pev_nextthink, get_gametime() + BIGSNOW_ROLL_THINK);

        // Massive snowball always uses the model's rollforward animation.
        ApplyBigSnowRollAnimation(ent, true);
        StopEntityAngularVelocity(ent);

        AddSnowballTrail(ent, 5, 120);
    }

    emit_sound(id, CHAN_VOICE, SND_THROW, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
    SendWeaponAnim(id, ANIM_THROW);
}

ThrowSnowball(id)
{
    if (HasBuff(id, BUFF_BIGSNOW))
    {
        ThrowRollingBigSnowball(id);

        if (g_bigSnowCharges[id] > 0)
            g_bigSnowCharges[id]--;

        if (g_bigSnowCharges[id] <= 0)
            ClearPlayerBuff(id, false);

        return;
    }

    // Make a new, empty entity that will be our snowball.
    new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"));
    if (!pev_valid(ent))
        return;

    set_pev(ent, pev_classname, SNOWBALL_CLASS);
    set_pev(ent, pev_owner, id);                 // remember who threw it
    set_pev(ent, pev_iuser1, GetActiveBuff(id)); // remember the buff this snowball had at throw time

    set_pev(ent, pev_movetype, MOVETYPE_TOSS);   // arcs and falls like a real throw
    set_pev(ent, pev_solid, SOLID_BBOX);         // can collide with things

    // Choose projectile model based on the active buff.
    // Every thrown snowball model uses its roll1 animation while flying.
    switch (GetActiveBuff(id))
    {
        case BUFF_MAG:
        {
            if (g_haveLargeSnowballModel)
            {
                engfunc(EngFunc_SetModel, ent, MODEL_LARGE_SNOWBALL);
            }
            else
                engfunc(EngFunc_SetModel, ent, MODEL_SNOWBALL);
        }
        case BUFF_EXPLOSIVE:
        {
            if (g_haveExplosiveBallModel)
            {
                engfunc(EngFunc_SetModel, ent, MODEL_EXPLOSIVE_BALL);
            }
            else
                engfunc(EngFunc_SetModel, ent, MODEL_SNOWBALL);
        }
        case BUFF_FREEZE:
        {
            if (g_haveIceBallModel)
            {
                engfunc(EngFunc_SetModel, ent, MODEL_ICE_BALL);
            }
            else
                engfunc(EngFunc_SetModel, ent, MODEL_SNOWBALL);
        }
        case BUFF_BIGSNOW:
        {
            if (g_haveBigSnowballModel)
                engfunc(EngFunc_SetModel, ent, MODEL_BIG_SNOWBALL);
            else
                engfunc(EngFunc_SetModel, ent, MODEL_SNOWBALL);
        }
        default:
        {
            engfunc(EngFunc_SetModel, ent, MODEL_SNOWBALL);
        }
    }

    ApplySpecialSnowballRollAnimation(ent);

    // Give it a small collision box so it reliably "touches" walls and players.
    if (HasBuff(id, BUFF_BIGSNOW) || HasBuff(id, BUFF_MAG))
    {
        static const Float:bigmins[3] = {-4.0, -4.0, -4.0};
        static const Float:bigmaxs[3] = { 4.0,  4.0,  4.0};
        engfunc(EngFunc_SetSize, ent, bigmins, bigmaxs);
    }
    else
    {
        static const Float:mins[3] = {-1.0, -1.0, -1.0};
        static const Float:maxs[3] = { 1.0,  1.0,  1.0};
        engfunc(EngFunc_SetSize, ent, mins, maxs);
    }

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

    // Aim it forward at the chosen speed. Mag/Firerate makes snowballs faster.
    new Float:speed = get_pcvar_float(g_pSpeed);
    if (HasBuff(id, BUFF_BIGSNOW))
        speed *= BIGSNOW_SPEED_MULT;
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

    // Draw a short white trail behind the snowball when enabled.
    AddSnowballTrail(ent, 5, 100);

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

    new cls[32];
    pev(ent, pev_classname, cls, charsmax(cls));

    // Deployed walls are soft player blockers (SOLID_TRIGGER), so the engine may
    // report the touch as wall -> snowball instead of snowball -> wall. Handle
    // that direction here so walls are still breakable.
    if (equal(cls, SNOW_WALL_CLASS) && pev_valid(other))
    {
        new otherCls[32];
        pev(other, pev_classname, otherCls, charsmax(otherCls));
        if (equal(otherCls, SNOWBALL_CLASS))
        {
            new snowOwner = pev(other, pev_owner);
            new wallOwner = pev(ent, pev_iuser2);
            if (snowOwner != wallOwner)
            {
                new snowBuff = pev(other, pev_iuser1);
                DamageSnowWall(ent, snowBuff == BUFF_BIGSNOW ? GetSnowWallDurability() : 50.0);
            }

            new Float:o[3];
            pev(other, pev_origin, o);
            SnowBurst(o);

            set_pev(other, pev_flags, pev(other, pev_flags) | FL_KILLME);
            return FMRES_SUPERCEDE;
        }
    }

    // One touch forward handles both: pickups set per-player buff flags, and
    // snowball impact reads those flags and calls the active effect function.
    if (TryPickupBuff(ent, other))
        return FMRES_IGNORED;

    // Only react if the thing that touched is actually one of our snowballs.
    if (!equal(cls, SNOWBALL_CLASS))
        return FMRES_IGNORED;

    new owner = pev(ent, pev_owner);

    // Self-touch handling: a snowball spawns near the thrower's bbox and will
    // touch the owner on the first frame. Skip those early frames.
    if (other == owner)
    {
        new Float:flThrowTime;
        pev(ent, pev_dmgtime, flThrowTime);
        if (get_gametime() - flThrowTime < 0.4)
            return FMRES_IGNORED;
    }

    new Float:vOrigin[3];
    pev(ent, pev_origin, vOrigin);

    new Float:vVelDir[3];
    pev(ent, pev_velocity, vVelDir);
    new Float:vSpeed = vector_length(vVelDir);
    new Float:vEnd[3];
    if (vSpeed > 0.0)
    {
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

    new Float:vTraceEnd[3];
    engfunc(EngFunc_TraceLine, vOrigin, vEnd, IGNORE_MONSTERS, ent, 0);
    new Float:flFraction;
    get_tr2(0, TR_flFraction, flFraction);
    if (flFraction < 1.0)
        get_tr2(0, TR_vecEndPos, vTraceEnd);
    else
    {
        vTraceEnd[0] = vEnd[0];
        vTraceEnd[1] = vEnd[1];
        vTraceEnd[2] = vEnd[2];
    }

    vOrigin[0] = vTraceEnd[0];
    vOrigin[1] = vTraceEnd[1];
    vOrigin[2] = vTraceEnd[2];

    new buff = BUFF_NONE;
    if (pev_valid(ent))
        buff = pev(ent, pev_iuser1);
    if (buff == BUFF_NONE)
        buff = GetActiveBuff(owner);

    // Big Snowball uses Green Shell-style engine movement. Do not destroy it
    // on floor/ramp touches. Count only vertical-ish world hits as bounces,
    // and let MOVETYPE_BOUNCE perform the actual reflection.
    if (buff == BUFF_BIGSNOW && pev(ent, pev_iuser3) >= 1
     && !(other >= 1 && other <= g_maxPlayers && is_user_alive(other)))
    {
        if (pev_valid(other) && other > g_maxPlayers)
        {
            new rollWallCls[32];
            pev(other, pev_classname, rollWallCls, charsmax(rollWallCls));
            if (equal(rollWallCls, SNOW_WALL_CLASS))
            {
                new wallOwner = pev(other, pev_iuser2);
                if (owner != wallOwner)
                    DamageSnowWall(other, GetSnowWallDurability());

                SnowBurst(vOrigin);
                set_pev(ent, pev_flags, pev(ent, pev_flags) | FL_KILLME);
                return FMRES_SUPERCEDE;
            }
        }

        // Manual flat rollers handle world bounces in ThinkRollingBigSnowball().
        // Ignore any floor/world trigger touches so they cannot consume bounce charges.
        if (pev(ent, pev_iuser3) == 1)
            return FMRES_IGNORED;

        new Float:normal[3];
        get_tr2(0, TR_vecPlaneNormal, normal);

        // Floors and ramps have a strong upward normal; keep rolling.
        if (normal[2] >= 0.45)
            return FMRES_IGNORED;

        new bounces = pev(ent, pev_iuser4);
        if (bounces >= BIGSNOW_MAX_BOUNCES)
        {
            SnowBurst(vOrigin);
            set_pev(ent, pev_flags, pev(ent, pev_flags) | FL_KILLME);
            return FMRES_SUPERCEDE;
        }

        set_pev(ent, pev_iuser4, bounces + 1);

        // After MOVETYPE_BOUNCE reflects the velocity, keep using the model's
        // rollforward sequence.  The engine handles the bounce; we only keep the
        // animation stable instead of applying manual spin.
        set_pev(ent, pev_sequence, BIGSNOW_ANIM_ROLLFORWARD);
        set_pev(ent, pev_framerate, 1.0);
        new Float:zeroAvel[3];
        zeroAvel[0] = 0.0;
        zeroAvel[1] = 0.0;
        zeroAvel[2] = 0.0;
        set_pev(ent, pev_avelocity, zeroAvel);
        return FMRES_IGNORED;
    }

    // Did it hit a player?
    if (other >= 1 && other <= g_maxPlayers && is_user_alive(other))
    {
        emit_sound(other, CHAN_VOICE, SND_HIT_PLAYER, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

        new Float:vVel[3];
        pev(other, pev_velocity, vVel);
        vVel[0] += 10.0;
        vVel[1] += 10.0;
        vVel[2] -= 10.0;
        set_pev(other, pev_velocity, vVel);

        if (get_pcvar_num(g_pSnowfight) && owner >= 1 && owner <= g_maxPlayers && is_user_alive(owner))
        {
            new Float:hitDamage = get_pcvar_float(g_pDamage);
            if (buff == BUFF_MAG)
                hitDamage = GetBigMagDamage();

            ExecuteHamB(Ham_TakeDamage, other, owner, owner, hitDamage, DMG_FREEZE);
        }

        if (buff != BUFF_NONE && ApplySnowballBuffEffect(owner, other, ent, vOrigin, true, buff))
            return FMRES_SUPERCEDE;
    }
    else
    {
        emit_sound(ent, CHAN_VOICE, SND_HIT_WORLD, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

        if (pev_valid(other) && other > g_maxPlayers)
        {
            new wall_cls[32];
            pev(other, pev_classname, wall_cls, charsmax(wall_cls));
            if (equal(wall_cls, SNOW_WALL_CLASS))
            {
                new wallOwner = pev(other, pev_iuser2);
                if (owner != wallOwner)
                {
                    new snowBuff = pev(ent, pev_iuser1);
                    DamageSnowWall(other, snowBuff == BUFF_BIGSNOW ? GetSnowWallDurability() : 50.0);
                }
            }
        }

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

        if (buff != BUFF_NONE && ApplySnowballBuffEffect(owner, other, ent, vOrigin, false, buff))
            return FMRES_SUPERCEDE;
    }

    SnowImpactDecal(vOrigin, other);
    SnowBurst(vOrigin);

    set_pev(ent, pev_flags, pev(ent, pev_flags) | FL_KILLME);
    return FMRES_SUPERCEDE;
}


/* ===========================================================================
 *  BUFFS  -  pickups set flags, snowball behavior calls effect functions
 * ========================================================================= */
stock bool:IsBuffPickupModel(const model[])
{
    // Never treat map flags/objectives as snowball powerups.
    if (containi(model, "flag") != -1)
        return false;

    new whitelist[256], work[256], token[64], rest[256];
    get_pcvar_string(g_pBuffPickupWhitelist, whitelist, charsmax(whitelist));
    copy(work, charsmax(work), whitelist);

    while (work[0])
    {
        strtok(work, token, charsmax(token), rest, charsmax(rest), ',');
        trim(token);

        if (token[0] && containi(model, token) != -1)
            return true;

        copy(work, charsmax(work), rest);
    }

    return false;
}

stock bool:TryPickupBuff(ent, id)
{
    if (id < 1 || id > g_maxPlayers || !is_user_alive(id))
        return false;

    new classname[32], model[64];
    pev(ent, pev_classname, classname, charsmax(classname));
    pev(ent, pev_model, model, charsmax(model));

    // Buff pickups are selected by model keyword, not by classname.
    // This supports custom backpacks/powerups while preventing info_tfgoal flags
    // from granting buffs. Configure keywords with sb_buff_models.
    if (IsBuffPickupModel(model))
    {
        if (get_gametime() - g_lastBuffPickup[id] < BUFF_PICKUP_COOLDOWN)
            return true;
        if (ent == g_lastBuffEnt[id])
            return true;

        g_lastBuffPickup[id] = get_gametime();
        g_lastBuffEnt[id] = ent;

        // Stop repeat pickups: only one active buff. Do NOT reset or reroll while active.
        if (g_activeBuff[id] != BUFF_NONE)
        {
            client_print(id, print_center, "%L", id, "SB_BUFF_ACTIVE");
            return true;
        }

        SetPlayerBuff(id, GetRandomBuffForPlayer(id));
        return true;
    }

    return false;
}

stock bool:IsOffenseTeam(id)
{
    new team[32];
    new teamid = get_user_team(id, team, charsmax(team));

    if (equali(team, "blue") || equali(team, "attackers") || equali(team, "attack")
     || equali(team, "offense") || equali(team, "attacker"))
        return true;

    // Common TFC attacker/blue fallback.
    return (teamid == 1);
}

stock Float:GetBuffDuration(buff)
{
    switch (buff)
    {
        case BUFF_INVIS:
        {
            // Pickup grants an armed invisibility charge. Right-click starts the
            // actual short invisibility timer from sb_invis_duration.
            return BUFF_DURATION;
        }
        case BUFF_ARMOR:
        {
            new Float:seconds = get_pcvar_float(g_pArmorDuration);
            if (seconds < 0.1)
                seconds = 0.1;
            return seconds;
        }
    }

    return BUFF_DURATION;
}

stock SetPlayerBuff(id, buff)
{
    if (id < 1 || id > g_maxPlayers || !is_user_connected(id))
        return;

    if (g_activeBuff[id] != BUFF_NONE)
    {
        client_print(id, print_center, "%L", id, "SB_BUFF_ACTIVE");
        return;
    }

    if (buff == BUFF_NONE)
        return;

    new Float:duration = GetBuffDuration(buff);

    g_activeBuff[id] = buff;
    g_buffEndTime[id] = get_gametime() + duration;
    g_lastRandomBuff[id] = buff;
    remove_task(BUFF_TASK_BASE + id);

    switch (buff)
    {
        case BUFF_FREEZE:
        {
            g_freezeCharges[id] = GetFreezePatchCharges();
            ShowBuffIcon(id, g_BuffIcons[BUFF_FREEZE], 80, 180, 255);
            client_print(id, print_chat, "%L", id, "SB_FREEZE_TITLE", duration);
            client_print(id, print_chat, "%L", id, "SB_FREEZE_INFO", g_freezeCharges[id]);
        }
        case BUFF_WALL:
        {
            ShowBuffIcon(id, g_BuffIcons[BUFF_WALL], 180, 220, 255);
            client_print(id, print_chat, "%L", id, "SB_WALL_TITLE", duration);
            client_print(id, print_chat, "%L", id, "SB_WALL_INFO");
        }
        case BUFF_EXPLOSIVE:
        {
            ShowBuffIcon(id, g_BuffIcons[BUFF_EXPLOSIVE], 255, 60, 60);
            client_print(id, print_chat, "%L", id, "SB_DEMO_TITLE", duration);
            client_print(id, print_chat, "%L", id, "SB_DEMO_INFO");
        }
        case BUFF_MAG:
        {
            ShowBuffIcon(id, g_BuffIcons[BUFF_MAG], 255, 230, 80);
            client_print(id, print_chat, "%L", id, "SB_MAG_TITLE", duration);
            client_print(id, print_chat, "%L", id, "SB_MAG_INFO");
            g_clip[id] = GetPlayerMaxClip(id);
        }
        case BUFF_BIGSNOW:
        {
            g_bigSnowCharges[id] = BIGSNOW_CHARGES;
            ShowBuffIcon(id, g_BuffIcons[BUFF_BIGSNOW], 255, 255, 255);
            client_print(id, print_chat, "%L", id, "SB_BIG_TITLE", duration);
            client_print(id, print_chat, "%L", id, "SB_BIG_INFO", g_bigSnowCharges[id]);
        }
        case BUFF_INVIS:
        {
            ShowBuffIcon(id, g_BuffIcons[BUFF_INVIS], 160, 160, 255);
            client_print(id, print_chat, "%L", id, "SB_INVIS_TITLE", duration);
            client_print(id, print_chat, "%L", id, "SB_INVIS_INFO", GetInvisDuration());
        }
        case BUFF_JUMP:
        {
            ShowBuffIcon(id, g_BuffIcons[BUFF_JUMP], 0, 255, 180);
            client_print(id, print_chat, "%L", id, "SB_JUMP_TITLE", duration);
            client_print(id, print_chat, "%L", id, "SB_JUMP_INFO");
        }
        case BUFF_ARMOR:
        {
            ShowBuffIcon(id, g_BuffIcons[BUFF_ARMOR], 255, 210, 80);
            client_print(id, print_chat, "%L", id, "SB_ARMOR_TITLE", duration);
            ApplyArmorBuff(id);
        }
        case BUFF_LINK:
        {
            ShowBuffIcon(id, g_BuffIcons[BUFF_LINK], 0, 255, 120);
            client_print(id, print_chat, "%L", id, "SB_LINK_TITLE", duration);
            client_print(id, print_chat, "%L", id, "SB_LINK_INFO");
        }
    }

    client_cmd(id, "spk items/suitchargeok1.wav");
    UpdateHud(id);
    set_task(duration, "Task_ClearBuff", BUFF_TASK_BASE + id);
}

public Task_ClearBuff(taskid)
{
    ClearPlayerBuff(taskid - BUFF_TASK_BASE, true);
}

stock ClearPlayerBuff(id, bool:announce)
{
    if (id < 1 || id > g_maxPlayers)
        return;

    if (g_activeBuff[id] == BUFF_NONE)
        return;

    new oldBuff = g_activeBuff[id];

    if (oldBuff == BUFF_WALL)
        DestroyWallPreview(id);

    // Demo buff cleanup: when the powerup expires/is cleared, remove all
    // stuck demo snowballs silently. Do NOT detonate them.
    if (oldBuff == BUFF_EXPLOSIVE)
        RemoveAllDemoSnowballs(id);

    g_activeBuff[id] = BUFF_NONE;
    if (oldBuff == BUFF_FREEZE)
        g_freezeCharges[id] = 0;

    if (oldBuff == BUFF_BIGSNOW)
        g_bigSnowCharges[id] = 0;
    g_buffEndTime[id] = 0.0;
    g_lastBuffEnt[id] = 0;
    g_flNextDetonate[id] = 0.0;
    remove_task(BUFF_TASK_BASE + id);

    // If Mag expires while the player still has bonus snowballs loaded,
    // clamp the clip back to the normal magazine size immediately.
    if (oldBuff == BUFF_MAG)
    {
        new normalClip = get_pcvar_num(g_pClip);
        if (g_clip[id] > normalClip)
            g_clip[id] = normalClip;
    }

    if (oldBuff == BUFF_INVIS)
        RestoreInvisibility(id);

    if (oldBuff == BUFF_ARMOR)
        RestoreArmorBuff(id);

    if (is_user_connected(id))
    {
        HideBuffIcon(id, g_BuffIcons[oldBuff]);
        if (announce)
        {
            switch (oldBuff)
            {
                case BUFF_FREEZE:    client_print(id, print_chat, "%L", id, "SB_END_FREEZE");
                case BUFF_WALL:      client_print(id, print_chat, "%L", id, "SB_END_WALL");
                case BUFF_EXPLOSIVE: client_print(id, print_chat, "%L", id, "SB_END_DEMO");
                case BUFF_MAG:       client_print(id, print_chat, "%L", id, "SB_END_MAG");
                case BUFF_BIGSNOW:   client_print(id, print_chat, "%L", id, "SB_END_BIG");
                case BUFF_INVIS:     client_print(id, print_chat, "%L", id, "SB_END_INVIS");
                case BUFF_ARMOR:     client_print(id, print_chat, "%L", id, "SB_END_ARMOR");
                case BUFF_LINK:      client_print(id, print_chat, "%L", id, "SB_END_LINK");
                case BUFF_JUMP:      client_print(id, print_chat, "%L", id, "SB_END_JUMP");
            }
        }
        UpdateHud(id);
    }
}

stock bool:HasBuff(id, buff)
{
    return (id >= 1 && id <= g_maxPlayers && g_activeBuff[id] == buff);
}

stock GetActiveBuff(id)
{
    if (id < 1 || id > g_maxPlayers)
        return BUFF_NONE;
    return g_activeBuff[id];
}

// Returns true when the effect has fully handled/removes/sticks the snowball.
stock bool:ApplySnowballBuffEffect(owner, other, ent, const Float:origin[3], bool:hitPlayer, buff)
{
    switch (buff)
    {
        case BUFF_FREEZE:
        {
            if (hitPlayer && other >= 1 && other <= g_maxPlayers && IsEnemyOfPatchOwner(owner, other))
                FreezePlayer(other, 3.0);

            CreateFreezePatch(owner, origin, ent);

            // Freeze has multiple charges. Consume one patch placement and only
            // clear the buff when the last charge is used.
            if (owner >= 1 && owner <= g_maxPlayers && HasBuff(owner, BUFF_FREEZE))
            {
                g_freezeCharges[owner]--;
                if (g_freezeCharges[owner] <= 0)
                    ClearPlayerBuff(owner, false);
                else
                    UpdateHud(owner);
            }

            set_pev(ent, pev_flags, pev(ent, pev_flags) | FL_KILLME);
            return true;
        }
        case BUFF_WALL:
        {
            CreateSnowWall(owner, origin);

            // Snow Wall is a one-shot powerup: after the wall snowball lands,
            // consume the buff so holding fire cannot place several walls.
            if (owner >= 1 && owner <= g_maxPlayers)
                ClearPlayerBuff(owner, false);

            set_pev(ent, pev_flags, pev(ent, pev_flags) | FL_KILLME);
            return true;
        }
        case BUFF_LINK:
        {
            if (hitPlayer && owner >= 1 && owner <= g_maxPlayers && is_user_alive(owner)
             && other >= 1 && other <= g_maxPlayers && is_user_alive(other))
            {
                LinkSnowballEffect(owner, other);
                ClearPlayerBuff(owner, false); // consumed on successful link teleport
            }
            return false; // link still allows normal burst/removal
        }
        case BUFF_EXPLOSIVE:
        {
            if (hitPlayer)
            {
                BigSnowExplosion(origin, owner);
                set_pev(ent, pev_flags, pev(ent, pev_flags) | FL_KILLME);
            }
            else
            {
                StickExplosiveSnowball(ent, origin, owner);
            }
            return true;
        }
        case BUFF_MAG:
        {
            // Mag/Firerate changes clip size and cooldown.
            return false;
        }
        case BUFF_BIGSNOW:
        {
            // Rolling Big Snowball instantly kills enemy players on contact.
            if (hitPlayer && owner >= 1 && owner <= g_maxPlayers
             && other >= 1 && other <= g_maxPlayers && is_user_alive(other)
             && IsEnemyOfPatchOwner(owner, other))
            {
                ExecuteHamB(Ham_TakeDamage, other, owner, owner, 9999.0, DMG_BLAST);
                SnowBurst(origin);
                set_pev(ent, pev_flags, pev(ent, pev_flags) | FL_KILLME);
                return true;
            }
            return false;
        }
        case BUFF_INVIS:
        {
            // Invisibility is activated by right-click in CmdStart.
            return false;
        }
        case BUFF_ARMOR:
        {
            // Armor is handled on pickup/clear.
            return false;
        }
        case BUFF_JUMP:
        {
            // Jump buff is handled in PlayerPreThink.
            return false;
        }
    }

    return false;
}


stock ResetBuffRotation(bool:offense)
{
    if (offense)
    {
        g_offenseBuffMask = (1 << BUFF_BIGSNOW) | (1 << BUFF_INVIS) | (1 << BUFF_JUMP) | (1 << BUFF_ARMOR);
    }
    else
    {
        g_defenseBuffMask = (1 << BUFF_FREEZE) | (1 << BUFF_WALL) | (1 << BUFF_EXPLOSIVE) | (1 << BUFF_MAG);
    }
}

stock CountBuffBits(mask)
{
    new count = 0;
    for (new buff = 1; buff <= BUFF_ARMOR; buff++)
    {
        if (mask & (1 << buff))
            count++;
    }
    return count;
}

stock PickBuffFromMask(mask)
{
    new count = CountBuffBits(mask);
    if (count <= 0)
        return BUFF_NONE;

    new pick = random_num(1, count);
    for (new buff = 1; buff <= BUFF_ARMOR; buff++)
    {
        if (!(mask & (1 << buff)))
            continue;

        pick--;
        if (pick <= 0)
            return buff;
    }

    return BUFF_NONE;
}

stock GetRandomBuffForPlayer(id)
{
    new bool:offense = IsOffenseTeam(id);

    if (offense && !g_offenseBuffMask)
        ResetBuffRotation(true);
    else if (!offense && !g_defenseBuffMask)
        ResetBuffRotation(false);

    new buff = offense ? PickBuffFromMask(g_offenseBuffMask) : PickBuffFromMask(g_defenseBuffMask);
    if (buff == BUFF_NONE)
        return BUFF_NONE;

    if (offense)
        g_offenseBuffMask &= ~(1 << buff);
    else
        g_defenseBuffMask &= ~(1 << buff);

    g_lastRandomBuff[id] = buff;
    return buff;
}



stock Float:GetInvisDuration()
{
    new Float:seconds = get_pcvar_float(g_pInvisDuration);
    if (seconds < 0.1)
        seconds = 0.1;
    return seconds;
}

stock ActivateInvisibility(id)
{
    if (id < 1 || id > g_maxPlayers || !is_user_alive(id))
        return;
    if (!HasBuff(id, BUFF_INVIS) || g_invisActive[id])
        return;

    new Float:duration = GetInvisDuration();

    // Consume the armed buff immediately on activation.  The invisibility effect
    // then runs on its own short timer and is restored by Task_RestoreInvisibility.
    g_activeBuff[id] = BUFF_NONE;
    g_freezeCharges[id] = 0;
    g_bigSnowCharges[id] = 0;
    g_buffEndTime[id] = 0.0;
    remove_task(BUFF_TASK_BASE + id);
    HideBuffIcon(id, g_BuffIcons[BUFF_INVIS]);

    g_invisActive[id] = true;
    g_invisEndTime[id] = get_gametime() + duration;
    ApplyInvisibility(id);

    if (g_haveInvisSound)
        emit_sound(id, CHAN_ITEM, SND_INVIS, 1.0, ATTN_STATIC, 0, PITCH_NORM);

    remove_task(INVIS_TASK_BASE + id);
    set_task(duration, "Task_RestoreInvisibility", INVIS_TASK_BASE + id);

    client_print(id, print_chat, "%L", id, "SB_INVIS_ON", duration);
    UpdateHud(id);
}

public Task_RestoreInvisibility(taskid)
{
    RestoreInvisibility(taskid - INVIS_TASK_BASE);
}

stock ApplyInvisibility(id)
{
    if (id < 1 || id > g_maxPlayers || !is_user_alive(id))
        return;

    // If the invisible player is also frozen, keep the body nearly invisible
    // while still drawing the light-blue glow shell so other players can see
    // that they are slowed.
    if (g_freezeSlowUntil[id] > get_gametime() || g_freezeAuraActive[id])
        set_user_rendering(id, kRenderFxGlowShell, 80, 200, 255, kRenderTransAlpha, INVIS_FROZEN_RENDER_AMOUNT);
    else
        set_user_rendering(id, kRenderFxNone, 0, 0, 0, kRenderTransAlpha, INVIS_RENDER_AMOUNT);
}

stock RestoreInvisibility(id)
{
    if (id < 1 || id > g_maxPlayers || !is_user_connected(id))
        return;

    g_invisActive[id] = false;
    g_invisEndTime[id] = 0.0;

    // Do not fight Link ghost rendering while it is still active.
    if (g_linkGhost[id])
        return;

    if (g_freezeSlowUntil[id] > get_gametime())
        ApplyFreezeAura(id);
    else
        set_user_rendering(id, kRenderFxNone, 255, 255, 255, kRenderNormal, 16);
}

stock Float:GetArmorTargetHealth()
{
    new Float:value = get_pcvar_float(g_pArmorHealthBonus);
    if (value < 1.0)
        value = 1.0;
    return value;
}

stock Float:GetArmorTargetArmor()
{
    new Float:value = get_pcvar_float(g_pArmorArmorBonus);
    if (value < 0.0)
        value = 0.0;
    return value;
}

stock ApplyArmorBuff(id)
{
    if (id < 1 || id > g_maxPlayers || !is_user_alive(id))
        return;

    new Float:hp, Float:armor, Float:maxHp;
    pev(id, pev_health, hp);
    pev(id, pev_armorvalue, armor);
    pev(id, pev_max_health, maxHp);

    g_armorStartHealth[id] = hp;
    g_armorStartArmor[id] = armor;
    g_armorStartMaxHealth[id] = maxHp;
    g_armorBuffActive[id] = true;

    new Float:targetHp = GetArmorTargetHealth();
    new Float:targetArmor = GetArmorTargetArmor();

    // TFC can clamp normal healing to class max health. Raise max_health first,
    // then force the current values with both fakemeta and fun natives.
    if (maxHp < targetHp)
        set_pev(id, pev_max_health, targetHp);

    if (hp < targetHp)
    {
        set_pev(id, pev_health, targetHp);
        set_user_health(id, floatround(targetHp));
    }

    if (armor < targetArmor)
    {
        set_pev(id, pev_armorvalue, targetArmor);
        set_pev(id, pev_armortype, targetArmor);
        set_user_armor(id, floatround(targetArmor));
    }
}

stock RestoreArmorBuff(id)
{
    if (id < 1 || id > g_maxPlayers || !is_user_connected(id))
        return;

    if (!g_armorBuffActive[id])
        return;

    if (is_user_alive(id))
    {
        new Float:hp, Float:armor;
        pev(id, pev_health, hp);
        pev(id, pev_armorvalue, armor);

        // Only remove the temporary buff if the player is still above the
        // pre-buff values. If they took damage below those values, keep current.
        if (hp > g_armorStartHealth[id])
        {
            set_pev(id, pev_health, g_armorStartHealth[id]);
            set_user_health(id, floatround(g_armorStartHealth[id]));
        }

        if (armor > g_armorStartArmor[id])
        {
            set_pev(id, pev_armorvalue, g_armorStartArmor[id]);
            set_pev(id, pev_armortype, g_armorStartArmor[id]);
            set_user_armor(id, floatround(g_armorStartArmor[id]));
        }

        if (g_armorStartMaxHealth[id] > 0.0)
            set_pev(id, pev_max_health, g_armorStartMaxHealth[id]);
    }

    g_armorBuffActive[id] = false;
    g_freezeAuraActive[id] = false;
    g_armorStartHealth[id] = 0.0;
    g_armorStartArmor[id] = 0.0;
    g_armorStartMaxHealth[id] = 0.0;
}

stock GetBigMagClipBonus()
{
    new bonus = get_pcvar_num(g_pBuffMagBonus);
    if (bonus < 0)
        bonus = 0;
    return bonus;
}

stock Float:GetBigMagFireRate()
{
    new Float:rate = get_pcvar_float(g_pBuffFireRate);
    if (rate < 0.1)
        rate = 0.1;
    return rate;
}

stock Float:GetBigMagDamage()
{
    new Float:damage = get_pcvar_float(g_pBuffMagDamage);
    if (damage < 0.0)
        damage = 0.0;
    return damage;
}

stock Float:GetJumpBoostHeight()
{
    new Float:height = get_pcvar_float(g_pBuffJumpHeight);
    if (height < 0.0)
        height = 0.0;
    return height;
}

stock Float:GetSnowWallDurability()
{
    new Float:hp = get_pcvar_float(g_pWallDurability);
    if (hp < 1.0)
        hp = 1.0;
    return hp;
}

stock Float:GetSnowWallLifetime()
{
    new Float:seconds = get_pcvar_float(g_pWallLifetime);
    if (seconds < 0.1)
        seconds = 0.1;
    return seconds;
}

stock Float:GetSnowWallHalfThickness()
{
    new Float:value = get_pcvar_float(g_pWallHalfThickness);
    if (value < 2.0)
        value = 2.0;
    return value;
}

stock Float:GetSnowWallHalfLength()
{
    new Float:value = get_pcvar_float(g_pWallHalfLength);
    if (value < 16.0)
        value = 16.0;
    return value;
}

stock Float:GetSnowWallHeight()
{
    new Float:value = get_pcvar_float(g_pWallHeight);
    if (value < 16.0)
        value = 16.0;
    return value;
}

stock Float:GetSnowWallPushMargin()
{
    new Float:margin = get_pcvar_float(g_pWallPushMargin);
    if (margin < 0.0)
        margin = 0.0;
    if (margin > 64.0)
        margin = 64.0;
    return margin;
}

stock Float:GetFreezePatchDuration()
{
    new Float:seconds = get_pcvar_float(g_pFreezePatchDuration);
    if (seconds < 0.1)
        seconds = 0.1;
    return seconds;
}

stock Float:GetFreezePatchRadius()
{
    new Float:radius = get_pcvar_float(g_pFreezePatchRadius);
    if (radius < 16.0)
        radius = 16.0;
    if (radius > 256.0)
        radius = 256.0;
    return radius;
}

stock Float:GetFreezePatchScale()
{
    new Float:scale = get_pcvar_float(g_pFreezePatchScale);
    if (scale < 0.1)
        scale = 0.1;
    return scale;
}

stock GetFreezePatchCharges()
{
    new charges = get_pcvar_num(g_pFreezePatchCharges);
    if (charges < 1)
        charges = 1;
    if (charges > 5)
        charges = 5;
    return charges;
}

stock Float:GetBigSnowSpeedMult()
{
    new Float:mult = get_pcvar_float(g_pBigSnowSpeedMult);
    if (mult < 0.05)
        mult = 0.05;
    if (mult > 3.0)
        mult = 3.0;
    return mult;
}

stock StopEntityAngularVelocity(ent)
{
    if (!pev_valid(ent))
        return;

    new Float:avel[3];
    avel[0] = 0.0;
    avel[1] = 0.0;
    avel[2] = 0.0;
    set_pev(ent, pev_avelocity, avel);
}

stock ApplyBigSnowRollAnimation(ent, bool:resetFrame)
{
    if (!pev_valid(ent))
        return;

    new seq = get_pcvar_num(g_pBigSnowRollSequence);
    if (seq < 0)
        seq = 0;

    new curSeq = pev(ent, pev_sequence);

    // Important: only reset frame/animtime when the ball is spawned or the
    // sequence actually changes. Resetting animtime every Think freezes many
    // GoldSrc studio models on frame 0.
    if (curSeq != seq || resetFrame)
    {
        set_pev(ent, pev_sequence, seq);
        set_pev(ent, pev_frame, 0.0);
        set_pev(ent, pev_animtime, get_gametime());
    }

    // Let the engine advance the model animation at the MDL's normal speed.
    set_pev(ent, pev_framerate, 1.0);
}

stock bool:IsEnemyOfPatchOwner(owner, id)
{
    if (id < 1 || id > g_maxPlayers || !is_user_alive(id))
        return false;

    if (owner < 1 || owner > g_maxPlayers || !is_user_connected(owner))
        return false;

    new ownerTeam = get_user_team(owner);
    new playerTeam = get_user_team(id);

    if (ownerTeam <= 0 || playerTeam <= 0)
        return false;

    return ownerTeam != playerTeam;
}

stock bool:IsEnemyTeamId(ownerTeam, id)
{
    if (id < 1 || id > g_maxPlayers || !is_user_alive(id))
        return false;

    new playerTeam = get_user_team(id);
    if (ownerTeam <= 0 || playerTeam <= 0)
        return false;

    return ownerTeam != playerTeam;
}

stock Float:GetDemoExplosionRadius()
{
    new Float:radius = get_pcvar_float(g_pDemoExplosionRadius);
    if (radius < 16.0)
        radius = 16.0;
    return radius;
}

stock GetDemoMaxSnowballs()
{
    new maxBalls = get_pcvar_num(g_pDemoMaxSnowballs);
    if (maxBalls < 1)
        maxBalls = 1;
    return maxBalls;
}

stock GetDemoSpriteScale()
{
    new scale = get_pcvar_num(g_pDemoSpriteScale);
    if (scale < 1)
        scale = 1;
    if (scale > 255)
        scale = 255;
    return scale;
}


stock Float:GetFreezeSlowFactor()
{
    new Float:factor = get_pcvar_float(g_pFreezeSlowFactor);
    if (factor < 0.0)
        factor = 0.0;
    if (factor > 1.0)
        factor = 1.0;
    return factor;
}

stock GetPlayerMaxClip(id)
{
    new maxClip = get_pcvar_num(g_pClip);
    if (id >= 1 && id <= g_maxPlayers && g_activeBuff[id] == BUFF_MAG)
        maxClip += GetBigMagClipBonus();
    return maxClip;
}

stock Float:GetPlayerThrowCooldown(id)
{
    new Float:cooldown = get_pcvar_float(g_pCooldown);
    if (id >= 1 && id <= g_maxPlayers && g_activeBuff[id] == BUFF_MAG)
        cooldown /= GetBigMagFireRate();
    return cooldown;
}

stock ApplyJumpBoost(id)
{
    new Float:vVel[3];
    pev(id, pev_velocity, vVel);

    // Make the buff obvious and reliable: set a minimum upward launch instead
    // of adding a tiny value that can be hidden by the game's normal jump code.
    vVel[0] *= JUMP_BOOST_XY_MULT;
    vVel[1] *= JUMP_BOOST_XY_MULT;
    new Float:jumpHeight = GetJumpBoostHeight();
    if (vVel[2] < jumpHeight)
        vVel[2] = jumpHeight;

    set_pev(id, pev_velocity, vVel);
}

stock FreezePlayer(id, Float:seconds)
{
    if (id < 1 || id > g_maxPlayers || !is_user_alive(id))
        return;

    new Float:until = get_gametime() + seconds;
    if (until > g_freezeSlowUntil[id])
        g_freezeSlowUntil[id] = until;

    ApplyFreezeAura(id);
    client_print(id, print_center, "%L", id, "SB_FROZEN");
}

stock ApplyFreezeAura(id)
{
    if (id < 1 || id > g_maxPlayers || !is_user_alive(id))
        return;

    g_freezeAuraActive[id] = true;

    // Link ghost must stay fully hidden/non-solid while inside another player.
    if (g_linkGhost[id])
        return;

    // Invisibility and freeze aura are separate gameplay effects.  GoldSrc only
    // gives us one render state, so combine them by using a glow shell with
    // alpha transparency: the player body stays almost invisible, but the
    // light-blue frozen aura is still visible.
    if (g_invisActive[id])
    {
        set_user_rendering(id, kRenderFxGlowShell, 80, 200, 255, kRenderTransAlpha, INVIS_FROZEN_RENDER_AMOUNT);
        return;
    }

    set_user_rendering(id, kRenderFxGlowShell, 80, 200, 255, kRenderNormal, 24);
}

stock RestoreFreezeAura(id)
{
    if (id < 1 || id > g_maxPlayers)
        return;

    g_freezeAuraActive[id] = false;

    if (!is_user_connected(id) || g_linkGhost[id])
        return;

    // If invisibility is still active, remove only the blue aura and keep the
    // player invisible instead of restoring normal rendering.
    if (g_invisActive[id])
    {
        ApplyInvisibility(id);
        return;
    }

    set_user_rendering(id, kRenderFxNone, 255, 255, 255, kRenderNormal, 16);
}

stock ApplyFreezeSlow(id, Float:flNow)
{
    if (g_freezeSlowUntil[id] <= flNow)
    {
        if (g_freezeAuraActive[id])
            RestoreFreezeAura(id);
        return;
    }

    ApplyFreezeAura(id);

    new Float:vVel[3];
    pev(id, pev_velocity, vVel);
    new Float:slowFactor = GetFreezeSlowFactor();
    vVel[0] *= slowFactor;
    vVel[1] *= slowFactor;
    set_pev(id, pev_velocity, vVel);
}

stock ApplyFreezePatchTeamGlow(ent, owner)
{
    if (!pev_valid(ent))
        return;

    new team = 0;
    if (owner >= 1 && owner <= g_maxPlayers && is_user_connected(owner))
        team = get_user_team(owner);

    new Float:color[3];
    if (team == 1)
    {
        // Blue / attackers.
        color[0] = 80.0;
        color[1] = 160.0;
        color[2] = 255.0;
    }
    else
    {
        // Red / defenders and fallback.
        color[0] = 255.0;
        color[1] = 80.0;
        color[2] = 80.0;
    }

    set_pev(ent, pev_renderfx, kRenderFxGlowShell);
    set_pev(ent, pev_rendercolor, color);
    set_pev(ent, pev_rendermode, kRenderNormal);
    set_pev(ent, pev_renderamt, 24.0);
}

stock SnapFreezePatchToFloor(const Float:impact[3], Float:outOrigin[3], ignoreEnt)
{
    // Freeze patches are only useful on walkable ground. If the iceball hits a
    // wall, trace downward from the impact X/Y and place the patch on the floor
    // below instead of leaving it floating at wall height.
    new Float:start[3], Float:end[3], Float:floor[3];

    start[0] = impact[0];
    start[1] = impact[1];
    start[2] = impact[2] + 32.0;

    end[0] = start[0];
    end[1] = start[1];
    end[2] = start[2] - 768.0;

    engfunc(EngFunc_TraceLine, start, end, IGNORE_MONSTERS, ignoreEnt, 0);

    new Float:fraction;
    get_tr2(0, TR_flFraction, fraction);

    if (fraction < 1.0)
    {
        get_tr2(0, TR_vecEndPos, floor);
        outOrigin[0] = floor[0];
        outOrigin[1] = floor[1];
        outOrigin[2] = floor[2] + 2.0;
    }
    else
    {
        // Fallback: old behavior, but still lowered slightly.
        outOrigin[0] = impact[0];
        outOrigin[1] = impact[1];
        outOrigin[2] = impact[2] - 2.0;
    }
}

stock CreateFreezePatch(owner, const Float:origin[3], ignoreEnt = 0)
{
    new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"));
    if (!pev_valid(ent))
        return;

    set_pev(ent, pev_classname, FREEZE_PATCH_CLASS);
    set_pev(ent, pev_owner, owner);
    if (owner >= 1 && owner <= g_maxPlayers && is_user_connected(owner))
        set_pev(ent, pev_iuser2, get_user_team(owner));
    set_pev(ent, pev_movetype, MOVETYPE_NONE);
    set_pev(ent, pev_solid, SOLID_TRIGGER);

    if (g_haveFreezePatchModel)
        engfunc(EngFunc_SetModel, ent, MODEL_FREEZE_PATCH);
    else
        engfunc(EngFunc_SetModel, ent, MODEL_SNOWGIBS);

    // Some GoldSrc models ignore pev_scale; gameplay radius is controlled separately
    // by sb_freeze_patch_radius so the slow area can be matched to the visible model.
    set_pev(ent, pev_scale, GetFreezePatchScale());

    ApplyFreezePatchTeamGlow(ent, owner);

    new Float:radius = GetFreezePatchRadius();
    new Float:mins[3], Float:maxs[3];
    mins[0] = -radius; mins[1] = -radius; mins[2] = -4.0;
    maxs[0] =  radius; maxs[1] =  radius; maxs[2] =  8.0;
    engfunc(EngFunc_SetSize, ent, mins, maxs);

    new Float:o[3];
    SnapFreezePatchToFloor(origin, o, ignoreEnt);
    engfunc(EngFunc_SetOrigin, ent, o);

    set_pev(ent, pev_dmgtime, get_gametime() + GetFreezePatchDuration());
    set_pev(ent, pev_nextthink, get_gametime() + 0.1);

    SnowBurst(o);
}

stock ThinkFreezePatch(ent)
{
    new Float:flNow = get_gametime();
    new Float:dieAt;
    pev(ent, pev_dmgtime, dieAt);

    if (flNow >= dieAt)
    {
        set_pev(ent, pev_flags, pev(ent, pev_flags) | FL_KILLME);
        return;
    }

    new Float:o[3], Float:p[3];
    pev(ent, pev_origin, o);

    new ownerTeam = pev(ent, pev_iuser2);
    new Float:radius = GetFreezePatchRadius();

    for (new id = 1; id <= g_maxPlayers; id++)
    {
        if (!is_user_alive(id))
            continue;

        if (!IsEnemyTeamId(ownerTeam, id))
            continue;

        pev(id, pev_origin, p);
        if (get_distance_f(o, p) <= radius && floatabs(p[2] - o[2]) <= 80.0)
            FreezePlayer(id, 0.35);
    }

    set_pev(ent, pev_nextthink, flNow + 0.2);
}

stock PlaySnowWallAnim(ent, anim, Float:rate = 1.0)
{
    if (!pev_valid(ent))
        return;

    set_pev(ent, pev_sequence, anim);
    set_pev(ent, pev_frame, 0.0);
    set_pev(ent, pev_framerate, rate);
    set_pev(ent, pev_animtime, get_gametime());
}


stock bool:TrySafePlayerMove(id, const Float:newOrigin[3])
{
    if (id < 1 || id > g_maxPlayers || !is_user_alive(id))
        return false;

    new Float:oldOrigin[3];
    pev(id, pev_origin, oldOrigin);

    // Do not push players through world geometry. If the straight path is blocked,
    // leave them where they are and only cancel the velocity into the wall.
    engfunc(EngFunc_TraceLine, oldOrigin, newOrigin, IGNORE_MONSTERS, id, 0);

    new Float:fraction;
    get_tr2(0, TR_flFraction, fraction);
    if (fraction < 1.0)
        return false;

    engfunc(EngFunc_SetOrigin, id, newOrigin);
    return true;
}

stock PushPlayersOutOfSnowWall(ent, Float:extraThick = 10.0, Float:extraLen = 18.0)
{
    if (!pev_valid(ent))
        return;

    new wallState = pev(ent, pev_iuser1);
    if (wallState != WALL_STATE_DEPLOYED && wallState != WALL_STATE_DEPLOYING && wallState != WALL_STATE_UNDEPLOYING)
        return;

    new Float:o[3], Float:ang[3];
    pev(ent, pev_origin, o);
    pev(ent, pev_angles, ang);

    new Float:fwd[3], Float:right[3];
    angle_vector(ang, ANGLEVECTOR_FORWARD, fwd);
    angle_vector(ang, ANGLEVECTOR_RIGHT, right);

    new Float:halfThick = GetSnowWallHalfThickness() + extraThick;
    new Float:halfLen   = GetSnowWallHalfLength() + extraLen;

    for (new id = 1; id <= g_maxPlayers; id++)
    {
        if (!is_user_alive(id))
            continue;

        new Float:p[3];
        pev(id, pev_origin, p);

        if (p[2] < o[2] - 40.0 || p[2] > o[2] + GetSnowWallHeight() + 72.0)
            continue;

        new Float:dx = p[0] - o[0];
        new Float:dy = p[1] - o[1];
        new Float:localForward = dx * fwd[0] + dy * fwd[1];
        new Float:localRight   = dx * right[0] + dy * right[1];

        if (floatabs(localForward) > halfThick || floatabs(localRight) > halfLen)
            continue;

        // Important: only push through the broad face of the wall, never out of
        // the short end caps. End-cap pushes are what caused corner traps between
        // the wall and nearby map geometry.
        new Float:sign = (localForward >= 0.0) ? 1.0 : -1.0;
        new Float:push = (halfThick - floatabs(localForward)) + 6.0;

        new Float:newOrigin[3];
        newOrigin[0] = p[0] + fwd[0] * sign * push;
        newOrigin[1] = p[1] + fwd[1] * sign * push;
        newOrigin[2] = p[2];

        new Float:vVel[3];
        pev(id, pev_velocity, vVel);

        new Float:velIntoWall = vVel[0] * fwd[0] + vVel[1] * fwd[1];
        if (velIntoWall * sign < 0.0)
        {
            vVel[0] -= fwd[0] * velIntoWall;
            vVel[1] -= fwd[1] * velIntoWall;
        }

        // If the safe push would go into world geometry, do not teleport the
        // player. The wall itself is non-solid for player movement, so cancelling
        // the wall-facing velocity lets them slide/walk out instead of getting
        // wedged in a map corner.
        TrySafePlayerMove(id, newOrigin);
        set_pev(id, pev_velocity, vVel);
    }
}


#define SNOW_WALL_SOUND_VOLUME 1.0
#define SNOW_WALL_SOUND_ATTN   ATTN_STATIC


stock PlaySnowWallSound(ent, const sound[])
{
    if (!pev_valid(ent))
        return;

    emit_sound(ent, CHAN_STATIC, sound, SNOW_WALL_SOUND_VOLUME, SNOW_WALL_SOUND_ATTN, 0, PITCH_NORM);
}

public Task_PlaySnowWallDeploySound(ent)
{
    if (!pev_valid(ent))
        return;

    PlaySnowWallSound(ent, SND_WALL_DEPLOY);
}

stock DisableSnowWallCollision(ent)
{
    if (!pev_valid(ent))
        return;

    set_pev(ent, pev_solid, SOLID_NOT);
    set_pev(ent, pev_takedamage, DAMAGE_NO);

    static const Float:zeroMins[3] = {0.0, 0.0, 0.0};
    static const Float:zeroMaxs[3] = {0.0, 0.0, 0.0};
    engfunc(EngFunc_SetSize, ent, zeroMins, zeroMaxs);

    new Float:o[3];
    pev(ent, pev_origin, o);
    engfunc(EngFunc_SetOrigin, ent, o); // relink after changing solidity/size
}

stock StartSnowWallUndeploy(ent)
{
    if (!pev_valid(ent))
        return;

    if (pev(ent, pev_iuser1) == WALL_STATE_UNDEPLOYING)
        return;

    PlaySnowWallSound(ent, SND_WALL_COLLAPSE);

    // Before removing the wall, push any touching player to the nearest free side.
    // Then disable/relink the hull so GoldSrc does not leave a stale blocking hull behind.
    PushPlayersOutOfSnowWall(ent, GetSnowWallPushMargin() + 2.0, 20.0);
    DisableSnowWallCollision(ent);

    set_pev(ent, pev_iuser1, WALL_STATE_UNDEPLOYING);
    PlaySnowWallAnim(ent, WALL_ANIM_UNDEPLOY);
    set_pev(ent, pev_nextthink, get_gametime() + WALL_UNDEPLOY_TIME);
}

stock DamageSnowWall(ent, Float:damage)
{
    if (!pev_valid(ent))
        return;

    new wallState = pev(ent, pev_iuser1);
    if (wallState == WALL_STATE_UNDEPLOYING)
        return;

    new Float:hp;
    pev(ent, pev_health, hp);
    hp -= damage;

    if (hp <= 0.0)
    {
        new Float:o[3];
        pev(ent, pev_origin, o);
        SnowBurst(o);

        // Show the retreat/break animation instead of deleting instantly.
        StartSnowWallUndeploy(ent);
    }
    else
    {
        set_pev(ent, pev_health, hp);
    }
}

public fw_InfoTargetTakeDamage(ent, inflictor, attacker, Float:damage, damagebits)
{
    if (!pev_valid(ent))
        return HAM_IGNORED;

    new cls[32];
    pev(ent, pev_classname, cls, charsmax(cls));
    if (!equal(cls, SNOW_WALL_CLASS))
        return HAM_IGNORED;

    new wallOwner = pev(ent, pev_iuser2);
    if (attacker == wallOwner)
        return HAM_SUPERCEDE;

    DamageSnowWall(ent, damage);
    return HAM_SUPERCEDE;
}

// Trace straight down from a candidate wall point so the marker/wall snaps to
// the actual floor instead of using an angled aim-hit point that may be inside
// a ramp, step, or wall edge.  The returned origin is the floor point plus the
// requested z offset.
stock bool:SnapWallPointToFloor(id, const Float:inPoint[3], Float:outPoint[3], Float:zOffset)
{
    new Float:start[3], Float:end[3];

    start[0] = inPoint[0];
    start[1] = inPoint[1];
    start[2] = inPoint[2] + 96.0;

    end[0] = inPoint[0];
    end[1] = inPoint[1];
    end[2] = inPoint[2] - 256.0;

    engfunc(EngFunc_TraceLine, start, end, IGNORE_MONSTERS, id, 0);

    new Float:fraction;
    get_tr2(0, TR_flFraction, fraction);

    // If the down trace somehow misses, still use the input point rather than
    // failing placement completely.
    if (fraction >= 1.0)
    {
        outPoint[0] = inPoint[0];
        outPoint[1] = inPoint[1];
        outPoint[2] = inPoint[2] + zOffset;
        return false;
    }

    get_tr2(0, TR_vecEndPos, outPoint);
    outPoint[2] += zOffset;
    return true;
}

stock bool:GetWallPlacement(id, Float:origin[3], Float:angles[3])
{
    if (id < 1 || id > g_maxPlayers || !is_user_alive(id))
        return false;

    new Float:pOrigin[3], Float:viewOfs[3], Float:viewAngles[3], Float:fwd[3];
    pev(id, pev_origin, pOrigin);
    pev(id, pev_view_ofs, viewOfs);
    pev(id, pev_v_angle, viewAngles);

    angle_vector(viewAngles, ANGLEVECTOR_FORWARD, fwd);

    new Float:start[3], Float:end[3];
    start[0] = pOrigin[0] + viewOfs[0];
    start[1] = pOrigin[1] + viewOfs[1];
    start[2] = pOrigin[2] + viewOfs[2];

    end[0] = start[0] + fwd[0] * 320.0;
    end[1] = start[1] + fwd[1] * 320.0;
    end[2] = start[2] + fwd[2] * 320.0;

    engfunc(EngFunc_TraceLine, start, end, IGNORE_MONSTERS, id, 0);

    new Float:hit[3];
    get_tr2(0, TR_vecEndPos, hit);

    // Keep the wall upright and rotate it to match the player's horizontal aim.
    angles[0] = 0.0;
    angles[1] = SnapSnowWallYaw(viewAngles[1]);
    angles[2] = 0.0;

    // Snap to the real floor below the aim point, then raise the marker clearly
    // above the floor. WALL_MARKER_Z_OFFSET is later subtracted again when
    // the full wall deploys, so only the marker/preview is lifted.
    SnapWallPointToFloor(id, hit, origin, WALL_MARKER_Z_OFFSET);

    return true;
}

stock UpdateWallPreview(id)
{
    new Float:o[3], Float:ang[3];
    if (!GetWallPlacement(id, o, ang))
        return;

    new ent = g_wallPreviewEnt[id];
    if (!pev_valid(ent))
    {
        ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"));
        if (!pev_valid(ent))
            return;

        g_wallPreviewEnt[id] = ent;
        set_pev(ent, pev_classname, SNOW_WALL_PREVIEW_CLASS);
        set_pev(ent, pev_owner, id);
        set_pev(ent, pev_movetype, MOVETYPE_NONE);
        set_pev(ent, pev_solid, SOLID_NOT);

        if (g_haveSnowWallModel)
            engfunc(EngFunc_SetModel, ent, MODEL_SNOW_WALL);
        else
            engfunc(EngFunc_SetModel, ent, MODEL_SNOWBALL);

        set_pev(ent, pev_rendermode, kRenderTransAdd);
        set_pev(ent, pev_renderamt, 90.0);

        // Preview is only a low floor marker, not the full wall, so players can still see.
        if (g_haveSnowWallModel)
            PlaySnowWallAnim(ent, WALL_ANIM_COLLAPSED, 0.0);
    }

    set_pev(ent, pev_angles, ang);
    SetSnowWallBoundingBox(ent, ang[1]);
    engfunc(EngFunc_SetOrigin, ent, o);
}

stock DestroyWallPreview(id)
{
    if (id < 1 || id > g_maxPlayers)
        return;

    new ent = g_wallPreviewEnt[id];
    if (pev_valid(ent))
        set_pev(ent, pev_flags, pev(ent, pev_flags) | FL_KILLME);

    g_wallPreviewEnt[id] = 0;
}

stock PlacePreviewSnowWall(id)
{
    new Float:o[3], Float:ang[3];
    if (!GetWallPlacement(id, o, ang))
        return;

    DestroyWallPreview(id);
    CreateSnowWallWithAngles(id, o, ang);
}

stock Float:SnapSnowWallYaw(Float:yaw)
{
    // Snap to the closest cardinal direction while preserving the wall's center.
    // This keeps the axis-aligned GoldSrc BBOX and the visual model using the
    // same orientation.
    while (yaw < 0.0)
        yaw += 360.0;
    while (yaw >= 360.0)
        yaw -= 360.0;

    if (yaw < 45.0 || yaw >= 315.0)
        return 0.0;
    if (yaw < 135.0)
        return 90.0;
    if (yaw < 225.0)
        return 180.0;
    return 270.0;
}

stock SetSnowWallBoundingBox(ent, Float:yaw)
{
    new Float:halfThick = GetSnowWallHalfThickness();
    new Float:halfLen   = GetSnowWallHalfLength();
    new Float:height    = GetSnowWallHeight();

    new Float:mins[3], Float:maxs[3];
    yaw = SnapSnowWallYaw(yaw);

    // The snowwall model's local FORWARD axis is the wall thickness,
    // and its local RIGHT axis is the wall length. Keep that same mapping
    // for the collision box. Do not move the origin here; only size changes.
    if (yaw == 90.0 || yaw == 270.0)
    {
        // forward is world Y, right/length is world X
        mins[0] = -halfLen;
        mins[1] = -halfThick;
        mins[2] = 0.0;
        maxs[0] =  halfLen;
        maxs[1] =  halfThick;
        maxs[2] =  height;
    }
    else
    {
        // forward is world X, right/length is world Y
        mins[0] = -halfThick;
        mins[1] = -halfLen;
        mins[2] = 0.0;
        maxs[0] =  halfThick;
        maxs[1] =  halfLen;
        maxs[2] =  height;
    }

    entity_set_size(ent, mins, maxs);
}

stock CreateSnowWall(owner, const Float:origin[3])
{
    new Float:wallAngles[3], Float:ownerAngles[3];

    if (owner >= 1 && owner <= g_maxPlayers && is_user_connected(owner))
        pev(owner, pev_v_angle, ownerAngles);
    else
        ownerAngles[1] = 0.0;

    wallAngles[0] = 0.0;
    wallAngles[1] = SnapSnowWallYaw(ownerAngles[1]);
    wallAngles[2] = 0.0;

    new Float:o[3];
    if (owner >= 1 && owner <= g_maxPlayers && is_user_connected(owner))
    {
        SnapWallPointToFloor(owner, origin, o, WALL_MARKER_Z_OFFSET);
    }
    else
    {
        o[0] = origin[0];
        o[1] = origin[1];
        o[2] = origin[2] + WALL_MARKER_Z_OFFSET;
    }

    CreateSnowWallWithAngles(owner, o, wallAngles);
}

stock CreateSnowWallWithAngles(owner, const Float:origin[3], const Float:wallAngles[3])
{
    // Recreated from the working BlockMaker pattern:
    // create_entity(info_target) -> classname -> SOLID_BBOX -> MOVETYPE_NONE
    // -> model -> angles -> size -> origin LAST.
    // The input origin is the visible floor marker origin (floor + WALL_MARKER_Z_OFFSET).
    new ent = create_entity("info_target");
    if (!is_valid_ent(ent))
        return;

    entity_set_string(ent, EV_SZ_classname, SNOW_WALL_CLASS);
    entity_set_int(ent, EV_INT_solid, SOLID_NOT);          // no hard block during deploy marker
    entity_set_int(ent, EV_INT_movetype, MOVETYPE_NONE);
    entity_set_float(ent, EV_FL_takedamage, DAMAGE_NO);
    entity_set_float(ent, EV_FL_health, GetSnowWallDurability());
    entity_set_int(ent, EV_INT_iuser1, WALL_STATE_DEPLOYING);
    entity_set_vector(ent, EV_VEC_angles, wallAngles);

    // Do NOT set EV_ENT_owner. Player movement can ignore owned entities.
    // Store owner only for bookkeeping/credit if needed.
    entity_set_int(ent, EV_INT_iuser2, owner);

    if (g_haveSnowWallModel)
        entity_set_model(ent, MODEL_SNOW_WALL);
    else
        entity_set_model(ent, MODEL_SNOWBALL);

    // Initial deploy marker: tiny/non-solid, placed exactly where preview was.
    new Float:zeroMins[3] = {0.0, 0.0, 0.0};
    new Float:zeroMaxs[3] = {0.0, 0.0, 0.0};
    entity_set_size(ent, zeroMins, zeroMaxs);
    entity_set_origin(ent, origin);

    // Lifetime is stored separately from nextthink so the wall can think during states.
    entity_set_float(ent, EV_FL_dmgtime, get_gametime() + GetSnowWallLifetime());

    if (g_haveSnowWallModel)
        PlaySnowWallAnim(ent, WALL_ANIM_COLLAPSED, 0.0);

    entity_set_float(ent, EV_FL_nextthink, get_gametime() + WALL_DEPLOY_TIME);
    set_task(0.5, "Task_PlaySnowWallDeploySound", ent);
    SnowBurst(origin);
}

stock ThinkSnowWall(ent)
{
    if (!pev_valid(ent))
        return;

    new Float:flNow = get_gametime();
    new wallState = pev(ent, pev_iuser1);

    if (wallState == WALL_STATE_DEPLOYING)
    {
        // Final hard wall: keep the visible model attached to the floor.
        // The preview marker was at floor + WALL_MARKER_Z_OFFSET; subtract it
        // so the deployed snowwall origin is exactly on the traced floor.
        entity_set_int(ent, EV_INT_iuser1, WALL_STATE_DEPLOYED);

        new Float:o[3], Float:a[3];
        entity_get_vector(ent, EV_VEC_origin, o);
        entity_get_vector(ent, EV_VEC_angles, a);

        o[2] = o[2] - WALL_MARKER_Z_OFFSET;
        a[0] = 0.0;
        a[1] = SnapSnowWallYaw(a[1]);
        a[2] = 0.0;

        // Match BlockMaker creation order: solid/movetype/model/angles/size/origin.
        entity_set_int(ent, EV_INT_solid, SOLID_BBOX);
        entity_set_int(ent, EV_INT_movetype, MOVETYPE_NONE);
        entity_set_float(ent, EV_FL_takedamage, DAMAGE_YES);
        entity_set_vector(ent, EV_VEC_angles, a);
        SetSnowWallBoundingBox(ent, a[1]);
        entity_set_origin(ent, o);

        if (g_haveSnowWallModel)
            PlaySnowWallAnim(ent, WALL_ANIM_DEPLOYED, 1.0);

        entity_set_float(ent, EV_FL_nextthink, flNow + 0.2);
        return;
    }

    if (wallState == WALL_STATE_UNDEPLOYING)
    {
        if (g_haveSnowWallModel)
            PlaySnowWallAnim(ent, WALL_ANIM_COLLAPSED, 0.0);
        set_pev(ent, pev_flags, pev(ent, pev_flags) | FL_KILLME);
        return;
    }

    new Float:dieAt;
    pev(ent, pev_dmgtime, dieAt);
    if (flNow >= dieAt)
    {
        StartSnowWallUndeploy(ent);
        return;
    }

    set_pev(ent, pev_nextthink, flNow + 0.2);
}


stock BlockPlayerWithSnowWalls(id)
{
    #pragma unused id
    // No pushout fallback. The wall is a real SOLID_BBOX BlockMaker-style entity.
    return;
}


public fw_AddToFullPack(es_handle, e, ent, host, hostflags, player, pSet)
{
    if (player && ent >= 1 && ent <= g_maxPlayers && g_linkGhost[ent])
    {
        // Other clients should also treat the linked player as non-solid while ghosted.
        set_es(es_handle, ES_Solid, SOLID_NOT);
        set_es(es_handle, ES_RenderMode, kRenderTransAlpha);
        set_es(es_handle, ES_RenderAmt, 0);
    }

    return FMRES_IGNORED;
}

stock LinkSnowballEffect(owner, target)
{
    if (owner < 1 || owner > g_maxPlayers || target < 1 || target > g_maxPlayers)
        return;
    if (!is_user_alive(owner) || !is_user_alive(target))
        return;

    // Teleport directly into the target's hull.  The linker then becomes a
    // temporary ghost so the two players do not collide until they separate.
    new Float:pOrigin[3];
    pev(target, pev_origin, pOrigin);
    set_pev(owner, pev_origin, pOrigin);
    engfunc(EngFunc_SetOrigin, owner, pOrigin);

    StartLinkGhost(owner, target);
    client_print(owner, print_center, "%L", owner, "SB_LINK_ACTIVATED");
}

stock StartLinkGhost(id, target)
{
    if (id < 1 || id > g_maxPlayers || !is_user_alive(id))
        return;

    g_linkGhost[id] = true;
    g_linkGhostTarget[id] = target;
    g_linkGhostUntil[id] = 0.0;

    // Invisible and non-solid while overlapping other players.
    set_user_rendering(id, kRenderFxNone, 0, 0, 0, kRenderTransAlpha, 0);
    set_pev(id, pev_solid, SOLID_NOT);

    new Float:o[3];
    pev(id, pev_origin, o);
    engfunc(EngFunc_SetOrigin, id, o); // relink after changing solidity
}

stock RestoreLinkGhost(id)
{
    if (id < 1 || id > g_maxPlayers)
        return;

    if (is_user_connected(id))
    {
        if (g_freezeSlowUntil[id] > get_gametime())
            ApplyFreezeAura(id);
        else
            set_user_rendering(id);
        if (is_user_alive(id))
        {
            set_pev(id, pev_solid, SOLID_SLIDEBOX);
            new Float:o[3];
            pev(id, pev_origin, o);
            engfunc(EngFunc_SetOrigin, id, o); // relink after changing solidity
        }
    }

    g_linkGhost[id] = false;
    g_linkGhostTarget[id] = 0;
    g_linkGhostUntil[id] = 0.0;
}

stock bool:IsLinkGhostTouchingAnyPlayer(id)
{
    if (!is_user_alive(id))
        return false;

    new Float:a[3], Float:b[3];
    pev(id, pev_origin, a);

    for (new other = 1; other <= g_maxPlayers; other++)
    {
        if (other == id || !is_user_alive(other))
            continue;

        pev(other, pev_origin, b);

        new Float:dx = a[0] - b[0];
        new Float:dy = a[1] - b[1];
        new Float:horizontal = floatsqroot(dx * dx + dy * dy);
        new Float:vertical = floatabs(a[2] - b[2]);

        if (horizontal < LINK_GHOST_SEPARATE_DIST && vertical < LINK_GHOST_SEPARATE_Z)
            return true;
    }

    return false;
}

stock UpdateLinkGhost(id)
{
    if (id < 1 || id > g_maxPlayers || !g_linkGhost[id])
        return;

    if (!is_user_alive(id))
    {
        RestoreLinkGhost(id);
        return;
    }

    // Keep real entity collision disabled while still overlapping any player.
    set_pev(id, pev_solid, SOLID_NOT);

    new Float:o[3];
    pev(id, pev_origin, o);
    engfunc(EngFunc_SetOrigin, id, o);

    if (!IsLinkGhostTouchingAnyPlayer(id))
        RestoreLinkGhost(id);
}

stock StickExplosiveSnowball(ent, const Float:origin[3], owner)
{
    new Float:stickOrigin[3];
    stickOrigin[0] = origin[0];
    stickOrigin[1] = origin[1];
    stickOrigin[2] = origin[2] - 2.0;

    set_pev(ent, pev_velocity, Float:{0.0, 0.0, 0.0});
    set_pev(ent, pev_movetype, MOVETYPE_NONE);
    set_pev(ent, pev_solid, SOLID_NOT);
    set_pev(ent, pev_iuser2, 1); // marks this explosive snowball as deployed/stuck
    StopSnowballRollAnimation(ent);
    engfunc(EngFunc_SetOrigin, ent, stickOrigin);

    EnforceDemoSnowballLimit(owner);
}

stock bool:IsPlayersStickyDemoSnowball(ent, owner)
{
    if (!pev_valid(ent))
        return false;

    new cls[16];
    pev(ent, pev_classname, cls, charsmax(cls));
    if (!equal(cls, SNOWBALL_CLASS))
        return false;

    if (pev(ent, pev_owner) != owner)
        return false;

    if (pev(ent, pev_iuser1) != BUFF_EXPLOSIVE)
        return false;

    return (pev(ent, pev_iuser2) == 1);
}

stock RemoveStickyDemoSnowball(ent)
{
    if (!pev_valid(ent))
        return;

    // Make it stop matching immediately, then remove it now.  Using only
    // FL_KILLME can leave it findable until the next engine cleanup pass,
    // which caused the old limit loop to keep finding the same snowball.
    set_pev(ent, pev_iuser2, 0);
    set_pev(ent, pev_solid, SOLID_NOT);
    set_pev(ent, pev_movetype, MOVETYPE_NONE);
    engfunc(EngFunc_RemoveEntity, ent);
}

stock RemoveOldestDemoSnowball(owner)
{
    new oldest = 0;
    new Float:oldestTime = 99999999.0;

    new ent = -1;
    while ((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", SNOWBALL_CLASS)) != 0)
    {
        if (!IsPlayersStickyDemoSnowball(ent, owner))
            continue;

        new Float:t;
        pev(ent, pev_dmgtime, t);
        if (t < oldestTime)
        {
            oldestTime = t;
            oldest = ent;
        }
    }

    if (oldest)
        RemoveStickyDemoSnowball(oldest);
}

stock CountDemoSnowballs(owner)
{
    new count = 0;

    new ent = -1;
    while ((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", SNOWBALL_CLASS)) != 0)
    {
        if (IsPlayersStickyDemoSnowball(ent, owner))
            count++;
    }

    return count;
}

stock EnforceDemoSnowballLimit(owner)
{
    if (owner < 1 || owner > g_maxPlayers)
        return;

    new maxBalls = GetDemoMaxSnowballs();

    // Keep at most maxBalls active. If the player throws one more, delete the
    // oldest sticky silently, exactly like replacing the first pipe/sticky.
    while (CountDemoSnowballs(owner) > maxBalls)
        RemoveOldestDemoSnowball(owner);
}

stock RemoveAllDemoSnowballs(owner)
{
    if (owner < 1 || owner > g_maxPlayers)
        return;

    new ent = -1;
    while ((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", SNOWBALL_CLASS)) != 0)
    {
        if (!IsPlayersStickyDemoSnowball(ent, owner))
            continue;

        RemoveStickyDemoSnowball(ent);

        // Restart scan after direct removal so FindEntityByString never receives
        // a removed entity as its previous search handle.
        ent = -1;
    }
}

stock bool:HasNearbySnowballs(id)
{
    // Right-click should detonate every sticky Demo snowball owned by this player,
    // no matter how far away it is. This function only checks whether at least
    // one valid sticky Demo snowball exists.
    new ent = -1;
    while ((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", SNOWBALL_CLASS)) != 0)
    {
        if (IsPlayersStickyDemoSnowball(ent, id))
            return true;
    }

    return false;
}

stock DetonateNearbySnowballs(id)
{
    // Detonate all sticky Demo snowballs owned by this player globally.
    // There is intentionally no distance/radius limit here.
    new ent = -1;
    while ((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", SNOWBALL_CLASS)) != 0)
    {
        if (!IsPlayersStickyDemoSnowball(ent, id))
            continue;

        new Float:sOrigin[3];
        pev(ent, pev_origin, sOrigin);

        BigSnowExplosion(sOrigin, id);
        set_pev(ent, pev_iuser2, 0);
        set_pev(ent, pev_flags, pev(ent, pev_flags) | FL_KILLME);
    }

    client_print(id, print_center, "%L", id, "SB_DETONATED");
}

stock BigSnowExplosion(const Float:origin[3], attacker)
{
    new iOrigin[3];
    iOrigin[0] = floatround(origin[0]);
    iOrigin[1] = floatround(origin[1]);
    iOrigin[2] = floatround(origin[2]);

    new spriteScale = GetDemoSpriteScale();
    new Float:radius = GetDemoExplosionRadius();

    message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
    write_byte(TE_EXPLOSION);
    write_coord(iOrigin[0]);
    write_coord(iOrigin[1]);
    write_coord(iOrigin[2]);
    write_short(g_idxBigPuff);
    write_byte(spriteScale);  // smaller/larger explosion sprite
    write_byte(15);           // framerate
    write_byte(TE_EXPLFLAG_NOSOUND); // suppress built-in TE_EXPLOSION sound; custom sound plays below
    message_end();

    message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
    write_byte(TE_BREAKMODEL);
    write_coord(iOrigin[0]);
    write_coord(iOrigin[1]);
    write_coord(iOrigin[2]);
    write_coord(floatround(radius * 0.25));
    write_coord(floatround(radius * 0.25));
    write_coord(floatround(radius * 0.25));
    write_coord(0);
    write_coord(0);
    write_coord(45);
    write_byte(25);
    write_short(g_idxSnowGibs);
    write_byte(18);
    write_byte(25);
    write_byte(0);
    message_end();

    if (g_haveDemoExplosionSound)
        emit_sound(0, CHAN_STATIC, SND_DEMO_EXPLOSION,  1.0, ATTN_STATIC, 0, PITCH_NORM);

    DemoExplosionDamage(origin, attacker, radius);
}

stock DemoExplosionDamage(const Float:origin[3], attacker, Float:radius)
{
    new validAttacker = (attacker >= 1 && attacker <= g_maxPlayers && is_user_connected(attacker));
    new inflictor = validAttacker ? attacker : 0;
    new damageOwner = validAttacker ? attacker : 0;

    new Float:maxDamage = get_pcvar_float(g_pDemoDamage);
    if (maxDamage < 1.0)
        maxDamage = 1.0;

    new Float:pOrigin[3];
    for (new id = 1; id <= g_maxPlayers; id++)
    {
        if (!is_user_alive(id))
            continue;

        pev(id, pev_origin, pOrigin);
        new Float:dist = get_distance_f(origin, pOrigin);
        if (dist > radius)
            continue;

        // Simple line-of-sight check so explosions around corners are less unfair.
        engfunc(EngFunc_TraceLine, origin, pOrigin, IGNORE_MONSTERS, 0, 0);
        new Float:flFraction;
        get_tr2(0, TR_flFraction, flFraction);
        if (flFraction < 0.95)
            continue;

        new Float:scale = 1.0 - (dist / radius);
        if (scale < 0.20)
            scale = 0.20;

        ExecuteHamB(Ham_TakeDamage, id, inflictor, damageOwner, maxDamage * scale, DMG_BLAST);
    }
}

stock SnowImpactDecal(const Float:origin[3], other)
{
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
    iOrigin[0] = floatround(origin[0]);
    iOrigin[1] = floatround(origin[1]);
    iOrigin[2] = floatround(origin[2]);

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
}

stock bool:ShouldShowBuffIcon(const sprite[], r, g, b)
{
    // Icons are back only for Jump, Mag/Firerate, and Armor.
    // Mag + Armor both use item_battery, Jump uses item_longjump.
    if (equal(sprite, "item_battery"))
        return true;

    if (equal(sprite, "item_longjump") && r == 0 && g == 255 && b == 180)
        return true;

    if (equal(sprite, "dmg_shock")) {
        return true;
    }

    return false;
}

stock ShowBuffIcon(id, const sprite[], r, g, b)
{
    if (!is_user_connected(id) || !sprite[0])
        return;

    if (!ShouldShowBuffIcon(sprite, r, g, b))
        return;

    new msg = get_user_msgid("StatusIcon");
    if (!msg)
        return;

    message_begin(MSG_ONE_UNRELIABLE, msg, _, id);
    write_byte(1);
    write_string(sprite);
    write_byte(r);
    write_byte(g);
    write_byte(b);
    message_end();
}

stock HideBuffIcon(id, const sprite[])
{
    if (!is_user_connected(id) || !sprite[0])
        return;

    new msg = get_user_msgid("StatusIcon");
    if (!msg)
        return;

    message_begin(MSG_ONE_UNRELIABLE, msg, _, id);
    write_byte(0);
    write_string(sprite);
    write_byte(0);
    write_byte(0);
    write_byte(0);
    message_end();
}

public Event_ResetHUD(id)
{
    // Do not clear active buffs here. In TFC, goal/backpack interactions can fire ResetHUD,
    // which made powerups disappear immediately after pickup.
    if (is_user_connected(id))
        UpdateHud(id);
}

public Event_TeamInfo()
{
    new id = read_data(1);
    if (is_user_connected(id))
        ClearPlayerBuff(id, false);
}


stock bool:RollingBigSnowballHitPlayers(ent, owner, const Float:origin[3])
{
    if (owner < 1 || owner > g_maxPlayers || !is_user_connected(owner))
        return false;

    new Float:p[3];
    new Float:hitRadius = BIGSNOW_ROLL_RADIUS + 24.0;

    for (new id = 1; id <= g_maxPlayers; id++)
    {
        if (!is_user_alive(id) || id == owner)
            continue;
        if (!IsEnemyOfPatchOwner(owner, id))
            continue;

        pev(id, pev_origin, p);
        if (get_distance_f(origin, p) <= hitRadius && floatabs(p[2] - origin[2]) <= 72.0)
        {
            emit_sound(id, CHAN_VOICE, SND_HIT_PLAYER, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
            ExecuteHamB(Ham_TakeDamage, id, ent, owner, 9999.0, DMG_BLAST);
            SnowBurst(origin);
            set_pev(ent, pev_flags, pev(ent, pev_flags) | FL_KILLME);
            return true;
        }
    }

    return false;
}

stock bool:PointInsideSnowWallForBigSnow(wall, const Float:point[3])
{
    if (!pev_valid(wall))
        return false;

    new wallState = pev(wall, pev_iuser1);
    if (wallState == WALL_STATE_UNDEPLOYING)
        return false;

    new Float:o[3], Float:a[3];
    pev(wall, pev_origin, o);
    pev(wall, pev_angles, a);

    if (point[2] < o[2] - BIGSNOW_ROLL_RADIUS || point[2] > o[2] + GetSnowWallHeight() + BIGSNOW_ROLL_RADIUS)
        return false;

    new Float:dx = point[0] - o[0];
    new Float:dy = point[1] - o[1];
    new Float:yaw = SnapSnowWallYaw(a[1]);
    new Float:halfThick = GetSnowWallHalfThickness() + BIGSNOW_ROLL_RADIUS;
    new Float:halfLen = GetSnowWallHalfLength() + BIGSNOW_ROLL_RADIUS;

    if (yaw == 90.0 || yaw == 270.0)
        return (floatabs(dx) <= halfLen && floatabs(dy) <= halfThick);

    return (floatabs(dx) <= halfThick && floatabs(dy) <= halfLen);
}

stock bool:RollingBigSnowballHitWalls(ent, owner, const Float:origin[3])
{
    new wall = -1;
    while ((wall = engfunc(EngFunc_FindEntityByString, wall, "classname", SNOW_WALL_CLASS)) != 0)
    {
        if (!pev_valid(wall))
            continue;

        new wallOwner = pev(wall, pev_iuser2);
        if (wallOwner == owner)
            continue;

        if (PointInsideSnowWallForBigSnow(wall, origin))
        {
            // Big Snowball always destroys enemy snow walls in one hit.
            DamageSnowWall(wall, GetSnowWallDurability() + 1.0);
            SnowBurst(origin);
            set_pev(ent, pev_flags, pev(ent, pev_flags) | FL_KILLME);
            return true;
        }
    }

    return false;
}

/* ---------------------------------------------------------------------------
 *  THE ROLLING BIG SNOWBALL "BRAIN"
 *
 *  This runs every BIGSNOW_ROLL_THINK seconds for one rolling big snowball. It
 *  does NOT teleport the ball. Instead it works out where the ball SHOULD be one
 *  think from now (tracing forward for walls, tracing down to follow the floor),
 *  and then sets the entity's VELOCITY so the engine slides it there on its own.
 *
 *  Why velocity instead of SetOrigin every tick? A GoldSrc client only receives
 *  entity updates a few times a second, but it smoothly INTERPOLATES an entity's
 *  position between updates using its velocity. If we teleported the ball with
 *  SetOrigin and zeroed its velocity, the client had nothing to interpolate and
 *  the ball looked like it was moving at a very low frame-rate. By handing the
 *  movement to the engine via velocity, every rendered frame is smooth. The
 *  think is now only a "steering" brain: it changes direction on bounces and
 *  keeps the ball glued to the ground, but the engine does the actual moving.
 *
 *  Each tick it:
 *     1. checks its lifetime and self-destructs when it is used up,
 *     2. checks if it rolled into an enemy player or enemy snow wall,
 *     3. traces forward to see if it hit a wall (and reflects its direction),
 *     4. traces down to follow the floor / ramps, or falls if it ran off a ledge,
 *     5. sets velocity = (target - current) / think so the engine glides it there.
 * ------------------------------------------------------------------------- */
stock ThinkRollingBigSnowball(ent)
{
    if (!pev_valid(ent))
        return;

    new Float:flNow = get_gametime();
    new Float:dieAt;
    pev(ent, pev_fuser1, dieAt);
    if (flNow >= dieAt)
    {
        set_pev(ent, pev_flags, pev(ent, pev_flags) | FL_KILLME);
        return;
    }

    new owner = pev(ent, pev_owner);
    new Float:origin[3];
    pev(ent, pev_origin, origin);

    // Remember where the ball is RIGHT NOW. Everything below rewrites `origin`
    // into the target position; at the end we turn the difference into a velocity.
    new Float:startOrigin[3];
    startOrigin[0] = origin[0];
    startOrigin[1] = origin[1];
    startOrigin[2] = origin[2];

    if (RollingBigSnowballHitPlayers(ent, owner, origin))
        return;
    if (RollingBigSnowballHitWalls(ent, owner, origin))
        return;

    // Use the locked roll direction rather than engine velocity.
    new Float:dir[3];
    pev(ent, pev_fuser2, dir[0]);
    pev(ent, pev_fuser3, dir[1]);
    dir[2] = 0.0;

    new Float:len = floatsqroot(dir[0] * dir[0] + dir[1] * dir[1]);
    if (len <= 0.01)
    {
        dir[0] = 1.0;
        dir[1] = 0.0;
    }
    else
    {
        dir[0] /= len;
        dir[1] /= len;
    }

    new Float:speed = get_pcvar_float(g_pSpeed) * GetBigSnowSpeedMult();
    new Float:moveDist = speed * BIGSNOW_ROLL_THINK;

    new Float:traceStart[3], Float:traceEnd[3];
    traceStart[0] = origin[0];
    traceStart[1] = origin[1];
    traceStart[2] = origin[2];
    traceEnd[0] = origin[0] + dir[0] * (moveDist + BIGSNOW_ROLL_RADIUS + 2.0);
    traceEnd[1] = origin[1] + dir[1] * (moveDist + BIGSNOW_ROLL_RADIUS + 2.0);
    traceEnd[2] = origin[2];

    engfunc(EngFunc_TraceLine, traceStart, traceEnd, IGNORE_MONSTERS, ent, 0);
    new Float:wallFrac;
    get_tr2(0, TR_flFraction, wallFrac);

    if (wallFrac < 1.0)
    {
        new Float:normal[3], Float:hit[3];
        get_tr2(0, TR_vecPlaneNormal, normal);
        get_tr2(0, TR_vecEndPos, hit);

        // Only vertical-ish surfaces are wall bounces. Floors/ramps are handled below.
        if (normal[2] < 0.45)
        {
            new bounces = pev(ent, pev_iuser4);
            if (bounces >= BIGSNOW_MAX_BOUNCES)
            {
                SnowBurst(hit);
                set_pev(ent, pev_flags, pev(ent, pev_flags) | FL_KILLME);
                return;
            }

            new Float:dot = dir[0] * normal[0] + dir[1] * normal[1];
            dir[0] = dir[0] - 2.0 * dot * normal[0];
            dir[1] = dir[1] - 2.0 * dot * normal[1];

            new Float:dirLen = floatsqroot(dir[0] * dir[0] + dir[1] * dir[1]);
            if (dirLen <= 0.01)
            {
                dir[0] = -normal[0];
                dir[1] = -normal[1];
                dirLen = floatsqroot(dir[0] * dir[0] + dir[1] * dir[1]);
            }
            if (dirLen > 0.01)
            {
                dir[0] /= dirLen;
                dir[1] /= dirLen;
            }

            set_pev(ent, pev_fuser2, dir[0]);
            set_pev(ent, pev_fuser3, dir[1]);
            set_pev(ent, pev_iuser4, bounces + 1);

            origin[0] = hit[0] + dir[0] * (BIGSNOW_ROLL_RADIUS + 3.0);
            origin[1] = hit[1] + dir[1] * (BIGSNOW_ROLL_RADIUS + 3.0);
        }
        else
        {
            origin[0] += dir[0] * moveDist;
            origin[1] += dir[1] * moveDist;
        }
    }
    else
    {
        origin[0] += dir[0] * moveDist;
        origin[1] += dir[1] * moveDist;
    }

    // Floor follow with limited step-down: follows ramps/stairs but falls off ledges.
    new Float:start[3], Float:end[3], Float:floor[3];
    start[0] = origin[0];
    start[1] = origin[1];
    start[2] = origin[2] + 36.0;
    end[0] = origin[0];
    end[1] = origin[1];
    end[2] = origin[2] - 180.0;

    new bool:hasFloor = false;
    new Float:targetZ = origin[2];

    engfunc(EngFunc_TraceLine, start, end, IGNORE_MONSTERS, ent, 0);
    new Float:frac;
    get_tr2(0, TR_flFraction, frac);
    if (frac < 1.0)
    {
        get_tr2(0, TR_vecEndPos, floor);
        targetZ = floor[2] + BIGSNOW_ROLL_RADIUS + BIGSNOW_ROLL_Z_OFFSET;

        new Float:drop = origin[2] - targetZ;
        if (drop <= BIGSNOW_ROLL_MAX_STEP_DOWN)
        {
            hasFloor = true;
            origin[2] = targetZ;
        }
    }

    if (!hasFloor)
        origin[2] += BIGSNOW_ROLL_FALL_SPEED * BIGSNOW_ROLL_THINK;

    // Hand the movement to the engine. Instead of teleporting the ball with
    // SetOrigin (which the client cannot interpolate, so it looks like it moves
    // at a very low frame-rate), we set the velocity to exactly the distance we
    // want it to travel this tick divided by the think interval. The engine then
    // slides the MOVETYPE_NOCLIP entity from where it is now to our target over
    // the next BIGSNOW_ROLL_THINK seconds, and the client interpolates that
    // motion smoothly on every rendered frame. Next tick we read the ball's new
    // origin and steer again, so any tiny timing drift is corrected automatically.
    new Float:vel[3];
    vel[0] = (origin[0] - startOrigin[0]) / BIGSNOW_ROLL_THINK;
    vel[1] = (origin[1] - startOrigin[1]) / BIGSNOW_ROLL_THINK;
    vel[2] = (origin[2] - startOrigin[2]) / BIGSNOW_ROLL_THINK;
    set_pev(ent, pev_velocity, vel);

    // Make the model face/travel in the current roll direction.
    new Float:face[3], Float:ang[3];
    face[0] = dir[0];
    face[1] = dir[1];
    face[2] = 0.0;
    engfunc(EngFunc_VecToAngles, face, ang);
    // Keep yaw aligned and let the massive snowball model's rollforward sequence animate it.
    ang[0] = 0.0;
    ang[2] = 0.0;
    set_pev(ent, pev_angles, ang);
    ApplyBigSnowRollAnimation(ent, false);
    StopEntityAngularVelocity(ent);

    set_pev(ent, pev_nextthink, flNow + BIGSNOW_ROLL_THINK);
}

// Engine think handler. Fires once for any entity whose pev_nextthink elapsed.
// We only care about our own snowballs - everything else is left untouched so
// other plugins / the game itself keep working normally.
public fw_Think(ent)
{
    if (!pev_valid(ent))
        return FMRES_IGNORED;

    new cls[32];
    pev(ent, pev_classname, cls, charsmax(cls));

    if (equal(cls, FREEZE_PATCH_CLASS))
    {
        ThinkFreezePatch(ent);
        return FMRES_SUPERCEDE;
    }

    if (equal(cls, SNOW_WALL_CLASS))
    {
        ThinkSnowWall(ent);
        return FMRES_SUPERCEDE;
    }

    if (!equal(cls, SNOWBALL_CLASS))
        return FMRES_IGNORED;

    if (pev(ent, pev_iuser3) == 1)
    {
        ThinkRollingBigSnowball(ent);
        return FMRES_SUPERCEDE;
    }

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

    new maxClip = GetPlayerMaxClip(id);

    // Light-blue text, bottom-centre. Hold time MUST exceed our refresh interval
    // (0.1s) and there must be no fade-out, otherwise the message fades between
    // refreshes and looks like it is flickering.
    //   x=-1.0, y=0.85, effect=0 (fade in/out), r,g,b,
    //   fxtime=0.0, holdtime=0.5, fadein=0.0, fadeout=0.0, channel=-1
    set_hudmessage(120, 200, 255, -1.0, 0.85, 0, 0.0, 2.0, 0.0, 0.0, 2);

    // Check if in reloading state (mode 4), and show active buff time left.
    // The short buff name is looked up from the language file so the HUD is
    // translated too (falls back to English if a translation is missing).
    new buffName[16];
    switch (g_activeBuff[id])
    {
        case BUFF_FREEZE:    formatex(buffName, charsmax(buffName), "%L", id, "SB_HN_FREEZE");
        case BUFF_WALL:      formatex(buffName, charsmax(buffName), "%L", id, "SB_HN_WALL");
        case BUFF_EXPLOSIVE: formatex(buffName, charsmax(buffName), "%L", id, "SB_HN_DEMO");
        case BUFF_MAG:       formatex(buffName, charsmax(buffName), "%L", id, "SB_HN_MAG");
        case BUFF_BIGSNOW:   formatex(buffName, charsmax(buffName), "%L", id, "SB_HN_BIG");
        case BUFF_INVIS:     formatex(buffName, charsmax(buffName), "%L", id, "SB_HN_INVIS");
        case BUFF_JUMP:      formatex(buffName, charsmax(buffName), "%L", id, "SB_HN_JUMP");
        case BUFF_ARMOR:     formatex(buffName, charsmax(buffName), "%L", id, "SB_HN_ARMOR");
        case BUFF_LINK:      formatex(buffName, charsmax(buffName), "%L", id, "SB_HN_LINK");
        default:             buffName[0] = 0;
    }

    new buffText[64];
    if (buffName[0])
    {
        new secondsLeft = floatround(g_buffEndTime[id] - get_gametime(), floatround_ceil);
        if (secondsLeft < 0) secondsLeft = 0;
        // "^n" is a newline; the "Power" label is translated via %L.
        if (g_activeBuff[id] == BUFF_FREEZE && g_freezeCharges[id] > 0)
            formatex(buffText, charsmax(buffText), "^n%L: %s x%d  %ds", id, "SB_HUD_BUFF_LABEL", buffName, g_freezeCharges[id], secondsLeft);
        else if (g_activeBuff[id] == BUFF_BIGSNOW && g_bigSnowCharges[id] > 0)
            formatex(buffText, charsmax(buffText), "^n%L: %s x%d  %ds", id, "SB_HUD_BUFF_LABEL", buffName, g_bigSnowCharges[id], secondsLeft);
        else
            formatex(buffText, charsmax(buffText), "^n%L: %s  %ds", id, "SB_HUD_BUFF_LABEL", buffName, secondsLeft);
    }
    else
    {
        buffText[0] = 0;
    }


    new invisText[32];
    if (g_invisActive[id])
    {
        new invisLeft = floatround(g_invisEndTime[id] - get_gametime(), floatround_ceil);
        if (invisLeft < 0) invisLeft = 0;
        formatex(invisText, charsmax(invisText), "^n%L: %ds", id, "SB_HUD_INVIS_LABEL", invisLeft);
    }
    else
    {
        invisText[0] = 0;
    }

    if (g_snowMode[id] == 4)
        ShowSyncHudMsg(id, g_hudSync, "%L%s%s", id, "SB_HUD_RELOAD", buffText, invisText);
    else
        ShowSyncHudMsg(id, g_hudSync, "%L%s%s", id, "SB_HUD_AMMO", g_clip[id], maxClip, buffText, invisText);
}


/* ===========================================================================
 *  CONSOLE HELP COMMANDS
 * ========================================================================== */
public CmdSnowballHelp(id)
{
    console_print(id, "========================================");
    console_print(id, " Snowball Gun CVAR Reference");
    console_print(id, "========================================");

    console_print(id, "sb_enabled (default 1)");
    console_print(id, "  Master enable switch. 1 = snowball mode on, 0 = off.");

    console_print(id, "sb_clip (default 5)");
    console_print(id, "  Base magazine capacity before reload.");

    console_print(id, "sb_cooldown (default 0.5)");
    console_print(id, "  Base seconds between throws. Lower = faster normal fire rate.");

    console_print(id, "sb_reload_time (default 1.5)");
    console_print(id, "  Seconds a reload takes.");

    console_print(id, "sb_speed (default 1000)");
    console_print(id, "  Base snowball flight speed.");

    console_print(id, "sb_snowfight (default 0)");
    console_print(id, "  0 = harmless snowballs, 1 = snowballs damage players.");

    console_print(id, "sb_damage (default 20)");
    console_print(id, "  Damage per direct snowball hit when sb_snowfight is 1.");

    console_print(id, "----------------------------------------");
    console_print(id, "BUFF SETTINGS");
    console_print(id, "----------------------------------------");

    console_print(id, "sb_buff_jumpheight (default 420.0)");
    console_print(id, "  Upward velocity used by Jump Buff. Higher = bigger jump.");

    console_print(id, "sb_buff_mag_bonus (default 5)");
    console_print(id, "  Extra magazine capacity added by Mag/Firerate Buff.");

    console_print(id, "sb_buff_fire_rate (default 1.8)");
    console_print(id, "  Mag/Firerate fire-rate multiplier. 1.0 = normal, 2.0 = twice as fast.");

    console_print(id, "sb_buff_mag_damage (default 35.0)");
    console_print(id, "  Direct-hit damage for Mag/Firerate snowballs when sb_snowfight is 1.");

    console_print(id, "sb_wall_durability (default 200.0)");
    console_print(id, "  Snow wall health/durability before it breaks.");

    console_print(id, "sb_wall_push_margin (default 20.0)");
    console_print(id, "  Extra soft-collision thickness for player pushback near snow walls.");

    console_print(id, "sb_wall_half_thickness (default 14.0)");
    console_print(id, "  Half-depth of the snow wall soft bounding box. Change live to tune thickness.");

    console_print(id, "sb_wall_half_length (default 152.0)");
    console_print(id, "  Half-length of the snow wall soft bounding box. Change live to tune end coverage.");

    console_print(id, "sb_wall_height (default 88.0)");
    console_print(id, "  Height of the snow wall soft bounding box. Change live to tune vertical coverage.");

    console_print(id, "sb_demo_explosion_radius (default 180.0)");
    console_print(id, "  Demo snowball blast radius. Bigger = larger damage area.");

    console_print(id, "sb_demo_max_snowballs (default 5)");
    console_print(id, "  Maximum sticky demo snowballs per player before oldest is removed.");

    console_print(id, "sb_demo_sprite_scale (default 14)");
    console_print(id, "  Demo explosion sprite scale. Lower = smaller visual puff.");

    console_print(id, "sb_trail_enabled (default 1)");
    console_print(id, "  Toggles the white snowball beam trail. 1 = on, 0 = off.");

    console_print(id, "sb_trail_width (default 3)");
    console_print(id, "  Width/size of the snowball beam trail. Applies live to new snowballs.");

    console_print(id, "sb_freeze_patch_duration (default 8.0)");
    console_print(id, "  Seconds a freeze patch stays active.");

    console_print(id, "sb_freeze_patch_radius (default 75.0)");
    console_print(id, "  Gameplay slow radius for freeze patches. Lower = smaller active zone.");

    console_print(id, "sb_freeze_patch_scale (default 1.0)");
    console_print(id, "  Visual model scale hint. Some GoldSrc models ignore this; radius controls gameplay.");

    console_print(id, "sb_freeze_patch_charges (default 2)");
    console_print(id, "  Number of freeze patches granted by one Freeze buff.");

    console_print(id, "sb_freeze_slow_factor (default 0.45)");
    console_print(id, "  Velocity multiplier while slowed by freeze patches. 1.0 = normal, 0.0 = stopped.");

    console_print(id, "sb_bigsnow_speed_mult (default 0.35)");
    console_print(id, "  Big Snowball ground-roll speed multiplier. Lower = slower.");

    console_print(id, "  1 = use massive snowball rollforward MDL animation, 0 = use manual spin code.");
    console_print(id, "  Playback speed for the massive snowball MDL animation. 0.25 slow, 1.0 original speed.");

    console_print(id, "  Manual spin angular velocity when animation is off. Flip the sign to reverse roll direction.");

    console_print(id, "sb_bigsnow_roll_sequence (default 1)");
    console_print(id, "  Model sequence index used for the Big Snowball rollforward/roll1 animation.");

    console_print(id, "----------------------------------------");
    console_print(id, "COMMANDS");
    console_print(id, "----------------------------------------");
    console_print(id, "sb_help  - show this help text");
    console_print(id, "sb_cvars - show current live CVAR values");
    console_print(id, "sb_givebuff <buff|clear> [player] - give/clear a specific buff");
    console_print(id, "  Buff names: freeze, wall, demo, bigmag, link, jump");
    console_print(id, "========================================");

    return PLUGIN_HANDLED;
}

public CmdSnowballCvars(id)
{
    console_print(id, "========================================");
    console_print(id, " Current Snowball Gun CVAR Values");
    console_print(id, "========================================");

    console_print(id, "sb_enabled = %d", get_pcvar_num(g_pEnabled));
    console_print(id, "sb_clip = %d", get_pcvar_num(g_pClip));
    console_print(id, "sb_cooldown = %.2f", get_pcvar_float(g_pCooldown));
    console_print(id, "sb_reload_time = %.2f", get_pcvar_float(g_pReloadTime));
    console_print(id, "sb_speed = %.0f", get_pcvar_float(g_pSpeed));
    console_print(id, "sb_snowfight = %d", get_pcvar_num(g_pSnowfight));
    console_print(id, "sb_damage = %.0f", get_pcvar_float(g_pDamage));

    console_print(id, "sb_buff_jumpheight = %.1f", get_pcvar_float(g_pBuffJumpHeight));
    console_print(id, "sb_buff_mag_bonus = %d", get_pcvar_num(g_pBuffMagBonus));
    console_print(id, "sb_buff_fire_rate = %.2f", get_pcvar_float(g_pBuffFireRate));
    console_print(id, "sb_buff_mag_damage = %.1f", get_pcvar_float(g_pBuffMagDamage));
    console_print(id, "sb_wall_durability = %.1f", get_pcvar_float(g_pWallDurability));
    console_print(id, "sb_wall_lifetime = %.1f", get_pcvar_float(g_pWallLifetime));
    console_print(id, "sb_wall_push_margin = %.1f", get_pcvar_float(g_pWallPushMargin));
    console_print(id, "sb_wall_half_thickness = %.1f", get_pcvar_float(g_pWallHalfThickness));
    console_print(id, "sb_wall_half_length = %.1f", get_pcvar_float(g_pWallHalfLength));
    console_print(id, "sb_wall_height = %.1f", get_pcvar_float(g_pWallHeight));
    console_print(id, "sb_demo_explosion_radius = %.1f", get_pcvar_float(g_pDemoExplosionRadius));
    console_print(id, "sb_demo_max_snowballs = %d", get_pcvar_num(g_pDemoMaxSnowballs));
    console_print(id, "sb_demo_sprite_scale = %d", get_pcvar_num(g_pDemoSpriteScale));
    console_print(id, "sb_trail_enabled = %d", get_pcvar_num(g_pTrailEnabled));
    console_print(id, "sb_trail_width = %d", get_pcvar_num(g_pTrailWidth));
    console_print(id, "sb_freeze_patch_duration = %.1f", get_pcvar_float(g_pFreezePatchDuration));
    console_print(id, "sb_freeze_patch_radius = %.1f", get_pcvar_float(g_pFreezePatchRadius));
    console_print(id, "sb_freeze_patch_scale = %.2f", get_pcvar_float(g_pFreezePatchScale));
    console_print(id, "sb_freeze_patch_charges = %d", get_pcvar_num(g_pFreezePatchCharges));
    console_print(id, "sb_freeze_slow_factor = %.2f", get_pcvar_float(g_pFreezeSlowFactor));
    console_print(id, "sb_bigsnow_speed_mult = %.2f", get_pcvar_float(g_pBigSnowSpeedMult));
    console_print(id, "sb_bigsnow_roll_sequence = %d", get_pcvar_num(g_pBigSnowRollSequence));

    console_print(id, "========================================");

    return PLUGIN_HANDLED;
}

stock ParseBuffName(const arg[])
{
    if (equali(arg, "freeze") || equali(arg, "freezing") || equali(arg, "ice"))
        return BUFF_FREEZE;

    if (equali(arg, "wall") || equali(arg, "snowwall") || equali(arg, "icewall"))
        return BUFF_WALL;

    if (equali(arg, "demo") || equali(arg, "demoman") || equali(arg, "explosive") || equali(arg, "explode"))
        return BUFF_EXPLOSIVE;

    if (equali(arg, "mag") || equali(arg, "bigmag") || equali(arg, "firerate") || equali(arg, "fire"))
        return BUFF_MAG;

    if (equali(arg, "big") || equali(arg, "bigsnow") || equali(arg, "bigsnowball"))
        return BUFF_BIGSNOW;

    if (equali(arg, "invis") || equali(arg, "invisible") || equali(arg, "invisibility"))
        return BUFF_INVIS;

    if (equali(arg, "armor") || equali(arg, "armour") || equali(arg, "tank"))
        return BUFF_ARMOR;

    if (equali(arg, "link") || equali(arg, "teleport"))
        return BUFF_LINK;

    if (equali(arg, "jump") || equali(arg, "jumpboost") || equali(arg, "leap"))
        return BUFF_JUMP;

    return BUFF_NONE;
}

stock GetBuffCommandName(buff, name[], len)
{
    switch (buff)
    {
        case BUFF_FREEZE:    copy(name, len, "Freeze");
        case BUFF_WALL:      copy(name, len, "Wall");
        case BUFF_EXPLOSIVE: copy(name, len, "Demo");
        case BUFF_MAG:       copy(name, len, "Mag/Firerate");
        case BUFF_BIGSNOW:   copy(name, len, "Big Snowball");
        case BUFF_INVIS:     copy(name, len, "Invisibility");
        case BUFF_JUMP:      copy(name, len, "Jump");
        case BUFF_ARMOR:     copy(name, len, "Armor");
        case BUFF_LINK:      copy(name, len, "Link");
        default:             copy(name, len, "None");
    }
}

public CmdSnowballGiveBuff(id, level, cid)
{
    if (read_argc() < 2)
    {
        console_print(id, "[Snowball Gun] Usage: sb_givebuff <freeze|wall|demo|mag|big|invis|jump|armor|link|clear> [player]");
        return PLUGIN_HANDLED;
    }

    new argBuff[32];
    read_argv(1, argBuff, charsmax(argBuff));

    new target = id;
    if (read_argc() >= 3)
    {
        new argTarget[64];
        read_argv(2, argTarget, charsmax(argTarget));
        target = cmd_target(id, argTarget, CMDTARGET_ALLOW_SELF);
        if (!target)
            return PLUGIN_HANDLED;
    }

    if (target < 1 || target > g_maxPlayers || !is_user_connected(target))
    {
        console_print(id, "[Snowball Gun] Target is not connected.");
        return PLUGIN_HANDLED;
    }

    new targetName[32];
    get_user_name(target, targetName, charsmax(targetName));

    if (equali(argBuff, "clear") || equali(argBuff, "none") || equali(argBuff, "off") || equali(argBuff, "remove"))
    {
        ClearPlayerBuff(target, false);
        console_print(id, "[Snowball Gun] Cleared buff from %s.", targetName);
        if (id != target)
            client_print(target, print_chat, "%L", target, "SB_BUFF_CLEARED");
        return PLUGIN_HANDLED;
    }

    new buff = ParseBuffName(argBuff);
    if (buff == BUFF_NONE)
    {
        console_print(id, "[Snowball Gun] Unknown buff: %s", argBuff);
        console_print(id, "[Snowball Gun] Valid buffs: freeze, wall, demo, bigmag, link, jump, clear");
        return PLUGIN_HANDLED;
    }

    // Givebuff command replaces the current buff, unlike normal pickups.
    ClearPlayerBuff(target, false);
    SetPlayerBuff(target, buff);

    new buffName[24];
    GetBuffCommandName(buff, buffName, charsmax(buffName));
    console_print(id, "[Snowball Gun] Gave %s buff to %s.", buffName, targetName);
    if (id != target)
    {
        new giverName[32];
        if (id >= 1 && id <= g_maxPlayers && is_user_connected(id))
            get_user_name(id, giverName, charsmax(giverName));
        else
            copy(giverName, charsmax(giverName), "Console");
        client_print(target, print_chat, "%L", target, "SB_BUFF_GIVEN", giverName, buffName);
    }

    return PLUGIN_HANDLED;
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
            g_clip[id] = GetPlayerMaxClip(id);

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