/* =============================================================================
 *
 *   TFC No Grenades (Kids Server)
 *   -----------------------------
 *   Author : MrKoala
 *   Game   : Team Fortress Classic (stock tfc.so / GoldSrc)
 *
 *   PURPOSE
 *   -------
 *   Part of a "kids-friendly" TFC server set-up where players are stripped of
 *   weapons and grenades and given harmless gameplay (e.g. snowballs) instead.
 *   This plugin is the grenade half: it guarantees that no player can ever be
 *   handed a grenade by the map.
 *
 *   HOW IT WORKS
 *   ------------
 *   In TFC, the grenades a player receives come from map entities: the
 *   per-spawn resupply (info_player_teamspawn), resupply bags (info_tfgoal /
 *   item_tfgoal), etc. Each of those entities declares how many grenades it
 *   grants through KeyValues named "no_grenades_1" / "no_grenades_2" (plus a
 *   few abbreviated spellings used by older maps).
 *
 *   When a map loads, the engine parses every entity's KeyValues one-by-one and
 *   hands each pair to the game DLL. By hooking that parse step (FM_KeyValue)
 *   we can intercept those grenade-count keys *before* the game DLL stores them
 *   and rewrite the value to "0". The entity then spawns believing it should
 *   grant zero grenades, so players are never resupplied with any.
 *
 *   WHY THIS APPROACH (and not tfc_setbammo / pdata writes)
 *   -------------------------------------------------------
 *   The obvious alternative - zeroing a player's grenade ammo at spawn via
 *   tfc_setbammo / set_pdata_int - depends on hard-coded private-data offsets
 *   into the tfc.so binary. Those offsets break whenever the binary is
 *   recompiled, silently turning the strip into a no-op. The KeyValue approach
 *   touches no offsets at all: it only reads and rewrites text keys during map
 *   load, so it survives binary rebuilds unchanged. (This is the same
 *   offset-free technique used by KZ map-converter plugins to clamp negative
 *   "dmg" values.)
 *
 *   SCOPE / LIMITATION
 *   ------------------
 *   This kills every grenade a *map* would grant, which on virtually all maps
 *   is the entire source of grenades. If a particular class still spawns with a
 *   residual grenade on a bare map, that count is baked into the class
 *   definition inside the binary and cannot be reached by KeyValues - in that
 *   case pair this plugin with an impulse-blocking plugin as a backstop.
 *
 * ============================================================================= */

#include <amxmodx>
#include <fakemeta>
#include <messages>

// Handle returned by register_forward(), kept so we could unregister later if
// ever needed. Not strictly required, but good housekeeping.
new g_iForward
new g_reset

public plugin_precache()
{
    /*
     * We MUST register the KeyValue hook in plugin_precache(), not plugin_init().
     *
     * Reason: the engine parses and spawns the map's entities very early in the
     * load sequence - during precache, before plugin_init() runs. If we waited
     * until plugin_init() to hook FM_KeyValue, the grenade-granting entities
     * would already have been parsed and stored their original (non-zero)
     * values, and our override would arrive too late to have any effect.
     */
    g_iForward = register_forward(FM_KeyValue, "Forward_KeyValue")
    g_reset = CreateGrenadeStripGoal();
}

public plugin_init()
{
    register_plugin("TFC No Grenades (Kids)", "1.0", "MrKoala")
    set_msg_block(get_user_msgid("SecAmmoIcon"), BLOCK_SET);
    register_event("ResetHUD", "EventResetHUD", "be");
}

/*
 * Forward_KeyValue
 * ----------------
 * Called once for every KeyValue pair of every entity as the map is parsed.
 *
 *   iEnt - entity index the KeyValue belongs to
 *   Kvd  - handle to the KeyValue data block (key name + value, etc.)
 *
 * We inspect the key name; if it is one of TFC's grenade-count keys we
 * overwrite its value with "0" before the game DLL gets to read it.
 */
public Forward_KeyValue(iEnt, Kvd)
{
    // Defensive guard: skip anything that isn't a valid entity. Malformed or
    // partially-constructed entities can otherwise cause trouble downstream.
    if (!pev_valid(iEnt))
        return FMRES_IGNORED

    // Pull the key NAME out of the KeyValue block into a small buffer.
    // 'static' avoids re-allocating this buffer on every single call (this
    // forward fires hundreds of times per map load).
    static sKey[32]; sKey[0] = 0
    get_kvd(Kvd, KV_KeyName, sKey, charsmax(sKey))

    /*
     * Match every spelling of the two grenade-count keys that TFC entities use:
     *   no_grenades_1 / no_grenades_2  - full names (modern FGD / most maps)
     *   no_gr1 / no_gr2                - abbreviated form
     *   ng1 / ng2                      - shortest abbreviation (older maps)
     *
     * "_1" is the primary grenade slot, "_2" is the secondary grenade slot.
     * Covering all variants means we catch grenade grants regardless of how the
     * map author wrote them.
     */
    if (equal(sKey, "no_grenades_1")
     || equal(sKey, "no_grenades_2")
     || equal(sKey, "no_gr1")
     || equal(sKey, "no_gr2")
     || equal(sKey, "ng1")
     || equal(sKey, "ng2"))
    {
        // Force the granted amount to zero. The entity will spawn thinking it
        // should hand out no grenades, so players never get resupplied.
        set_kvd(Kvd, KV_Value, "0")
    }

    // FMRES_IGNORED = "we didn't supersede the engine"; the (now possibly
    // modified) KeyValue continues on to the game DLL as normal.
    return FMRES_IGNORED
}

public EventResetHUD(id)
{
    if (!is_user_alive(id))
        return PLUGIN_CONTINUE;

    set_pev(id, pev_speed, 1500.0);
    set_pev(id, pev_maxspeed, 1500.0);

    remove_task(id);
    set_task(0.2, "TouchGrenadeStripGoalTask", id);

    return PLUGIN_CONTINUE;
}

public TouchGrenadeStripGoalTask(id)
{

    if (!pev_valid(g_reset))
        return;
	
	if (!is_user_alive(id))
        return;

    // Entity stays parked off-map. We only manually fire its touch code.
    dllfunc(DLLFunc_Touch, g_reset, id);
}

CreateGrenadeStripGoal()
{
    new ent = engfunc(
        EngFunc_CreateNamedEntity,
        engfunc(EngFunc_AllocString, "info_tfgoal")
    );

    if (!pev_valid(ent))
        return 0;

    SetGoalKV(ent, "angles", "0 0 0");
    SetGoalKV(ent, "no_grenades_1", "-4");
    SetGoalKV(ent, "no_grenades_2", "-4");
    SetGoalKV(ent, "wait", "0");
    SetGoalKV(ent, "g_e", "1");
    SetGoalKV(ent, "g_a", "1");
    SetGoalKV(ent, "goal_state", "2");

    new Float:origin[3] = { 0.0, 0.0, -8192.0 };
    set_pev(ent, pev_origin, origin);
    engfunc(EngFunc_SetOrigin, ent, origin);

    dllfunc(DLLFunc_Spawn, ent);

    set_pev(ent, pev_solid, SOLID_TRIGGER);
    set_pev(ent, pev_movetype, MOVETYPE_NONE);

    engfunc(
        EngFunc_SetSize,
        ent,
        Float:{-16.0, -16.0, -16.0},
        Float:{16.0, 16.0, 16.0}
    );

    return ent;
}

SetGoalKV(ent, const key[], const value[])
{
    set_kvd(0, KV_ClassName, "info_tfgoal");
    set_kvd(0, KV_KeyName, key);
    set_kvd(0, KV_Value, value);
    set_kvd(0, KV_fHandled, 0);

    dllfunc(DLLFunc_KeyValue, ent, 0);
}