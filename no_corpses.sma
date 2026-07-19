/* ===================================================================
 *  no_corpses.sma
 *
 *  Features:
 *    - Suppresses TFC player corpse entities ("bodyque").
 *    - Hides the real player model while dead.
 *    - Removes death backpacks/weaponboxes.
 *    - Always removes map turrets and miniturrets.
 *
 *  cvar:
 *    nocorpses 1 = hide corpses and death animations
 *    nocorpses 0 = normal corpse behavior
 * =================================================================== */

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <engine>
#include <messages>

new g_pCvarEnabled;

// True while the player is dead and their player model is hidden.
new bool:g_bHiddenDeadPlayer[33];

/*
 * plugin_precache()
 *
 * FM_Spawn is registered here so map entities can be removed before
 * their normal spawn initialization runs.
 */
public plugin_precache()
{
    register_forward(FM_Spawn, "fw_EntitySpawn_Pre", 0);
}

public plugin_init()
{
    register_plugin(
        "TFC No Corpses and Turrets",
        "1.3",
        "MrKoala & Vancold"
    );

    // Removes backpacks/weaponboxes spawned when a player dies.
    RegisterHam(Ham_Spawn, "weaponbox", "Die");

    // Used as the death notification because TFC Ham_Killed support
    // may not be configured correctly for the player class.
    register_message(
        get_user_msgid("DeathMsg"),
        "Message_DeathMsg"
    );

    // Restore player visibility after a real respawn.
    RegisterHam(
        Ham_Spawn,
        "player",
        "PlayerSpawn_Post",
        1
    );

    g_pCvarEnabled = register_cvar("nocorpses", "1");

    // Filters bodyque entities from client entity packets.
    register_forward(
        FM_AddToFullPack,
        "fw_AddToFullPack",
        0
    );
}

/*
 * fw_EntitySpawn_Pre(ent)
 *
 * Always removes turret entities as they spawn.
 *
 * monster_turret:
 *   Standard large ceiling/floor turret.
 *
 * monster_miniturret:
 *   Smaller turret variant.
 *
 * monster_sentry:
 *   Included for maps or mods that use the standard GoldSrc sentry
 *   classname.
 */
public fw_EntitySpawn_Pre(ent)
{
    if (!pev_valid(ent))
        return FMRES_IGNORED;

    new classname[32];
    pev(
        ent,
        pev_classname,
        classname,
        charsmax(classname)
    );

    if (
        equal(classname, "monster_turret") ||
        equal(classname, "monster_miniturret") ||
        equal(classname, "monster_sentry")
    )
    {
        engfunc(EngFunc_RemoveEntity, ent);
        return FMRES_SUPERCEDE;
    }

    return FMRES_IGNORED;
}

/*
 * Message_DeathMsg(msgid, dest, receiver)
 *
 * Hides the actual player edict while the player is dead.
 *
 * The player is not removed from AddToFullPack because doing so can
 * interfere with deathcam behavior.
 */
public Message_DeathMsg(msgid, dest, receiver)
{
    if (!get_pcvar_num(g_pCvarEnabled))
        return PLUGIN_CONTINUE;

    new victim = get_msg_arg_int(2);

    if (
        victim < 1 ||
        victim > 32 ||
        !pev_valid(victim)
    )
    {
        return PLUGIN_CONTINUE;
    }

    g_bHiddenDeadPlayer[victim] = true;

    // Hide the active dying/dead player model.
    set_pev(
        victim,
        pev_effects,
        pev(victim, pev_effects) | EF_NODRAW
    );

    // Stop the hidden death animation from advancing.
    set_pev(victim, pev_framerate, 0.0);
    set_pev(victim, pev_animtime, get_gametime());

    return PLUGIN_CONTINUE;
}

/*
 * PlayerSpawn_Post(id)
 *
 * Restores the player model after a real respawn.
 */
public PlayerSpawn_Post(id)
{
    if (!pev_valid(id))
        return HAM_IGNORED;

    g_bHiddenDeadPlayer[id] = false;

    // Restore player visibility.
    set_pev(
        id,
        pev_effects,
        pev(id, pev_effects) & ~EF_NODRAW
    );

    // Restore normal animation playback.
    set_pev(id, pev_framerate, 1.0);

    return HAM_IGNORED;
}

public client_disconnected(id)
{
    g_bHiddenDeadPlayer[id] = false;
}

/*
 * fw_AddToFullPack(es, e, ent, host, hostflags, player, pSet)
 *
 * Removes bodyque corpse entities from client entity packets.
 *
 * The real player entity is not filtered here.
 */
public fw_AddToFullPack(
    es,
    e,
    ent,
    host,
    hostflags,
    player,
    pSet
)
{
    if (!get_pcvar_num(g_pCvarEnabled))
        return FMRES_IGNORED;

    // Never suppress actual player slots here.
    if (player || !pev_valid(ent))
        return FMRES_IGNORED;

    new classname[16];
    pev(
        ent,
        pev_classname,
        classname,
        charsmax(classname)
    );

    if (equal(classname, "bodyque"))
    {
        forward_return(FMV_CELL, 0);
        return FMRES_SUPERCEDE;
    }

    return FMRES_IGNORED;
}

/*
 * Die(ent)
 *
 * Immediately clears a spawned death backpack/weaponbox.
 */
public Die(ent)
{
    call_think(ent);
    return HAM_SUPERCEDE;
}