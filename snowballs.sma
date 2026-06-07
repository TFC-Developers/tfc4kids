/*
 * TFC Snowballs - AMX Mod X port of the old SkillzWorld Metamod/C++ snowball feature.
 *
 * Press E (+use) to throw a snowball. Snowballs arc, leave a beam trail, shatter into
 * snow on impact, shove the victim a little and flash a "cold" status icon. In snowfight
 * mode they also deal damage.
 *
 * CVARs:
 *   sw_snowballs        0/1    master toggle (the "toggle snowballs" switch)        [def 0]
 *   sw_snowfight        0/1    snowballs deal damage when 1                          [def 0]
 *   sw_snowball_dmg     float  damage in snowfight mode (original used 1000=instakill) [def 20]
 *   sw_snowball_speed   float  launch speed                                          [def 1000]
 *   sw_snowball_cooldown float base seconds between throws (+ small random jitter)   [def 0.5]
 *
 * To use right-click instead of E, change SNOWBALL_BUTTON to IN_ATTACK2 below.
 *
 * Requires the SkillzWorld models/sounds to be present on the server & downloaded by clients:
 *   models/skillzworld/snowball.mdl, models/skillzworld/snow.mdl, sprites/laserbeam.spr
 *   skillzworld/snow.wav, skillzworld/snow1.wav, skillzworld/snow3.wav
 */

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>

#define PLUGIN  "TFC Snowballs"
#define VERSION "1.0"
#define AUTHOR  "Ioannis"

// ---- Which button throws. E = +use. Use IN_ATTACK2 for right-click (the original's normal-map key). ----
//#define SNOWBALL_BUTTON     IN_USE
#define SNOWBALL_BUTTON     IN_ATTACK2

// ---- Task offset so our status-icon timers don't collide with player ids of other plugins ----
#define TASK_COLD           20000

// ---- Resources ----
new const MODEL_SNOWBALL[]  = "models/skillzworld/snowball.mdl";
new const MODEL_SNOWGIBS[]  = "models/skillzworld/snow.mdl";
new const SPRITE_TRAIL[]    = "sprites/laserbeam.spr";

new const SND_THROW[]       = "skillzworld/snow3.wav";
new const SND_HIT_WORLD[]   = "skillzworld/snow1.wav";
new const SND_HIT_PLAYER[]  = "skillzworld/snow.wav";

new const SNOWBALL_CLASS[]  = "snowball";

// ---- Globals ----
new g_idxSnowGibs;
new g_idxTrail;
new g_msgStatusIcon;

new Float:g_flNextThrow[33];

// ---- Cached cvars ----
new g_pEnabled, g_pSnowfight, g_pDamage, g_pSpeed, g_pCooldown;

public plugin_precache()
{
    precache_model(MODEL_SNOWBALL);
    g_idxSnowGibs = precache_model(MODEL_SNOWGIBS);
    g_idxTrail    = precache_model(SPRITE_TRAIL);

    precache_sound(SND_THROW);
    precache_sound(SND_HIT_WORLD);
    precache_sound(SND_HIT_PLAYER);
}

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR);

    g_pEnabled   = register_cvar("sw_snowballs",        "0");
    g_pSnowfight = register_cvar("sw_snowfight",        "0");
    g_pDamage    = register_cvar("sw_snowball_dmg",     "20");
    g_pSpeed     = register_cvar("sw_snowball_speed",   "1000");
    g_pCooldown  = register_cvar("sw_snowball_cooldown","0.5");

    register_forward(FM_PlayerPreThink, "fw_PlayerPreThink");
    register_forward(FM_Touch,          "fw_Touch");

    g_msgStatusIcon = get_user_msgid("StatusIcon");
}

public client_putinserver(id)
{
    g_flNextThrow[id] = 0.0;
}

// ---------------------------------------------------------------------------
//  Input: throw on button press, throttled per player
// ---------------------------------------------------------------------------
public fw_PlayerPreThink(id)
{
    if (!get_pcvar_num(g_pEnabled) || !is_user_alive(id))
        return FMRES_IGNORED;

    if (!(pev(id, pev_button) & SNOWBALL_BUTTON))
        return FMRES_IGNORED;

    new Float:flNow = get_gametime();
    if (g_flNextThrow[id] > flNow)
        return FMRES_IGNORED;

    // Faithful to the original feel: base cooldown plus a little randomness.
    g_flNextThrow[id] = flNow + get_pcvar_float(g_pCooldown) + random_float(0.0, 0.3);

    ThrowSnowball(id);
    return FMRES_IGNORED;
}

ThrowSnowball(id)
{
    new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"));
    if (!pev_valid(ent))
        return;

    set_pev(ent, pev_classname, SNOWBALL_CLASS);
    set_pev(ent, pev_owner, id);
    set_pev(ent, pev_movetype, MOVETYPE_TOSS);
    set_pev(ent, pev_solid, SOLID_BBOX);
    engfunc(EngFunc_SetModel, ent, MODEL_SNOWBALL);

    // Tiny bbox: original used a point, but a small box makes touches fire reliably.
    static const Float:mins[3] = {-2.0, -2.0, -2.0};
    static const Float:maxs[3] = { 2.0,  2.0,  2.0};
    engfunc(EngFunc_SetSize, ent, mins, maxs);

    new Float:vOrigin[3], Float:vView[3], Float:vAngles[3];
    new Float:vForward[3], Float:vRight[3], Float:vUp[3];

    pev(id, pev_origin,   vOrigin);
    pev(id, pev_view_ofs, vView);
    pev(id, pev_v_angle,  vAngles);

    angle_vector(vAngles, ANGLEVECTOR_FORWARD, vForward);
    angle_vector(vAngles, ANGLEVECTOR_RIGHT,   vRight);
    angle_vector(vAngles, ANGLEVECTOR_UP,      vUp);

    // Spawn from the eyes, nudged up+right like the original (GunPos + up*1 + right*3).
    new Float:vSrc[3];
    for (new i = 0; i < 3; i++)
        vSrc[i] = vOrigin[i] + vView[i] + vUp[i] * 1.0 + vRight[i] * 3.0;

    new Float:speed = get_pcvar_float(g_pSpeed);
    new Float:vVel[3];
    vVel[0] = vForward[0] * speed;
    vVel[1] = vForward[1] * speed;
    vVel[2] = vForward[2] * speed;

    set_pev(ent, pev_origin, vSrc);
    engfunc(EngFunc_SetOrigin, ent, vSrc);     // links the ent so collision/touch works
    set_pev(ent, pev_angles, vAngles);
    set_pev(ent, pev_velocity, vVel);

    // Beam trail (TE_BEAMFOLLOW), matching the original white/100-brightness laser.
    message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
    write_byte(TE_BEAMFOLLOW);
    write_short(ent);
    write_short(g_idxTrail);
    write_byte(5);      // life * 0.1s
    write_byte(3);      // width
    write_byte(255);
    write_byte(255);
    write_byte(255);
    write_byte(100);    // brightness
    message_end();

    emit_sound(ent, CHAN_VOICE, SND_THROW, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

    // Cleanup safety net: the original never removed snowballs that flew off into the void.
    new params[1];
    params[0] = ent;
    set_task(8.0, "RemoveStraySnowball", ent, params, sizeof params);
}

// ---------------------------------------------------------------------------
//  Impact
// ---------------------------------------------------------------------------
public fw_Touch(ent, other)
{
    if (!pev_valid(ent))
        return FMRES_IGNORED;

    new cls[16];
    pev(ent, pev_classname, cls, charsmax(cls));
    if (!equal(cls, SNOWBALL_CLASS))
        return FMRES_IGNORED;

    new owner = pev(ent, pev_owner);
    if (other == owner)                 // don't let the thrower hit themselves
        return FMRES_IGNORED;

    new Float:vOrigin[3];
    pev(ent, pev_origin, vOrigin);

    if (other >= 1 && other <= get_maxplayers() && is_user_alive(other))
    {
        emit_sound(other, CHAN_VOICE, SND_HIT_PLAYER, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

        // Little shove, like the original velocity bump.
        new Float:vVel[3];
        pev(other, pev_velocity, vVel);
        vVel[0] += 10.0;
        vVel[1] += 10.0;
        vVel[2] -= 10.0;
        set_pev(other, pev_velocity, vVel);

        // Cold status icon for 2.5s.
        ShowColdIcon(other, true);
        remove_task(other + TASK_COLD);
        set_task(2.5, "ClearColdIcon", other + TASK_COLD);

        // Snowfight damage.
        // IMPORTANT: pass the THROWER as the inflictor, NOT the snowball entity.
        // TFC's damage/death code inspects the inflictor to pick a death icon/weapon and
        // crashes on a synthetic entity ("snowball") it doesn't recognise. Attributing the
        // hit to the player avoids the segfault and credits the frag correctly.
        if (get_pcvar_num(g_pSnowfight) && owner >= 1 && owner <= get_maxplayers() && is_user_alive(owner))
            ExecuteHamB(Ham_TakeDamage, other, owner, owner, get_pcvar_float(g_pDamage), DMG_FREEZE);
    }
    else
    {
        emit_sound(ent, CHAN_VOICE, SND_HIT_WORLD, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
    }

    SnowBurst(vOrigin);

    // Mark for removal (safer than removing mid-touch) and stop further touch processing.
    set_pev(ent, pev_flags, pev(ent, pev_flags) | FL_KILLME);
    return FMRES_SUPERCEDE;
}

SnowBurst(const Float:origin[3])
{
    new iOrigin[3];
    iOrigin[0] = floatround(origin[0]);
    iOrigin[1] = floatround(origin[1]);
    iOrigin[2] = floatround(origin[2]);

    message_begin(MSG_PVS, SVC_TEMPENTITY, iOrigin);
    write_byte(TE_BREAKMODEL);
    write_coord(iOrigin[0]);
    write_coord(iOrigin[1]);
    write_coord(iOrigin[2]);
    write_coord(20);            // spawn box size
    write_coord(20);
    write_coord(20);
    write_coord(0);             // base velocity
    write_coord(0);
    write_coord(25);
    write_byte(15);             // random velocity
    write_short(g_idxSnowGibs); // snow chunks
    write_byte(8);              // count
    write_byte(25);             // life * 0.1s
    write_byte(0);              // flags
    message_end();
}

// ---------------------------------------------------------------------------
//  Helpers / tasks
// ---------------------------------------------------------------------------
ShowColdIcon(id, bool:on)
{
    if (!g_msgStatusIcon)
        return;

    message_begin(MSG_ONE, g_msgStatusIcon, _, id);
    write_byte(on ? 2 : 0);     // 2 = solid on, 0 = off
    write_string("dmg_cold");
    write_byte(0);              // r,g,b (cold blue)
    write_byte(170);
    write_byte(255);
    message_end();
}

public ClearColdIcon(taskid)
{
    new id = taskid - TASK_COLD;
    if (is_user_connected(id))
        ShowColdIcon(id, false);
}

public RemoveStraySnowball(params[])
{
    new ent = params[0];
    if (!pev_valid(ent))
        return;

    new cls[16];
    pev(ent, pev_classname, cls, charsmax(cls));
    if (equal(cls, SNOWBALL_CLASS))     // still a live snowball -> clean it up
        engfunc(EngFunc_RemoveEntity, ent);
}
