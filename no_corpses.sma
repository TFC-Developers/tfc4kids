/* ===================================================================
 *  no_corpses.sma  —  Suppress TFC player corpses (AMX Mod X / fakemeta)
 *
 *  HOW TFC CORPSES WORK:
 *  ---------------------------------------------------------
 *  This is the QuakeTF / QWTF "copy the body" mechanism ported to HL.
 *  The dead player's OWN edict does NOT stay on the ground -- it is
 *  teleported straight to a spawn point. Instead a separate, recycled
 *  "bodyque" entity is stamped with a snapshot of the dead player and
 *  left lying where they died. That recycled entity is what you see.
 *
 *  Relevant symbols (lib: tfc.so, i386):
 *    CopyToBodyQue(entvars_s*)   @ 0x14dc40   (_Z13CopyToBodyQueP9entvars_s)
 *    bodyque()  [CCorpse spawn]  @ 0x14dbd0   (LINK_ENTITY_TO_CLASS bodyque)
 *    class CCorpse   vtable      @ 0x188f80
 *    g_pBodyQueueHead (ring head)@ 0x1c8630   (BSS global)
 *
 *  CALL PATH (who triggers a corpse):
 *    respawn(entvars_s*, int)              @ 0xa6cb0  -> CopyToBodyQue
 *    CBasePlayer::StartDeathCam()          @ 0x101a70 -> CopyToBodyQue (x2)
 *  i.e. the body is spun off the instant the player respawns or the
 *  death-cam begins -- NOT inside CBasePlayer::Killed.
 *
 *  STARTUP: a fixed-size ring of CCorpse "bodyque" entities is
 *  pre-spawned once; g_pBodyQueueHead points at the next free slot.
 *  Because the ring is finite, old corpses are silently overwritten
 *  once enough players have died -- one reason a body "sometimes"
 *  appears to vanish on its own.
 *
 *  CopyToBodyQue(pev)  -- reconstructed from the disassembly
 *  (pev = the DYING player's entvars; cev = the corpse's entvars):
 *
 *      if (pev->flags & 0x80)        // body not eligible
 *          return;                   //   -> no corpse is made
 *
 *      CCorpse *corpse = g_pBodyQueueHead;   // classname stays "bodyque"
 *      entvars_t *cev  = corpse->pev;
 *
 *      cev->origin    = pev->origin;         // [0x50/54/58]
 *      cev->angles    = pev->angles;         // [0xb4/b8]
 *      cev->[0x130]   = pev->[0x130];
 *      cev->[0x1a8]   = pev->[0x1a8];
 *      cev->movetype  = MOVETYPE_TOSS (6);   // [0x108] -> falls & settles
 *      cev->velocity  = pev->velocity;       // [0x20/24/28]  (death ragdoll fling)
 *      cev->[0x1a4]   = 0;
 *      cev->sequence  = pev->sequence;       // [0x170] (death animation frame)
 *      cev->[0x15c]   = 0x11;                // fixed body-state tag
 *      cev->[0x14c]   = (float) engfn_0x11c(pev->pContainingEntity); // owner index
 *      cev->flags    |= 0x20;                // mark as a corpse
 *      cev->renderfx  = pev->renderfx;       // [0x128]
 *      cev->[0x134]   = pev->[0x134];
 *
 *      SET_MODEL(corpse, pev->model);        // copy the player model  (@0x14dd37)
 *      UTIL_SetSize (corpse, mins, maxs);    // copy hull              (@0x14dd53)
 *
 *      g_pBodyQueueHead = corpse->next;      // [+0x198] advance ring -> next slot
 *
 *  => The visible corpse is a SEPARATE entity (classname "bodyque"),
 *     NOT the player edict. Hiding the player just makes the LIVE
 *     player flicker/teleport around (it's being moved to spawn).
 *     We must hide the "bodyque" entity instead.
 *
 *  IT IS NOT A NETWORK MESSAGE / TEMP ENTITY. The corpse is a normal
 *  server entity transmitted through the per-client entity-state
 *  stream, which is exactly what AddToFullPack gates. So we hook
 *  AddToFullPack (pre) and SUPERCEDE with return 0 for any "bodyque"
 *  entity -- the engine then never packs it for that client. This is
 *  per-client, reversible, and needs no binary patching.
 *
 *  NOTE: gibs are a different system (CGib / "gib" entities) and are
 *  unaffected by this filter.
 *
 *  cvar:  nocorpses  1 = hide corpses (default), 0 = normal
 * =================================================================== */

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <engine>

new g_pCvarEnabled;

public plugin_init()
{
    register_plugin("TFC No Corpses", "1.0", "MrKoala & Vancold");
    RegisterHam(Ham_Spawn,"weaponbox","Die"); // supresses the backpack spawning when a player dies
    g_pCvarEnabled = register_cvar("nocorpses", "1");

    // Pre-hook so we can supercede the engine's per-entity pack decision.
    register_forward(FM_AddToFullPack, "fw_AddToFullPack", 0);
}

/* AddToFullPack(es, e, ent, host, hostflags, player, pSet)
 *   ent    : the entity being considered for this host's packet
 *   player : 1 when 'ent' is a player slot (the corpse is NOT a player)
 * Return 0 + SUPERCEDE -> entity excluded from this host's full pack.
 */
public fw_AddToFullPack(es, e, ent, host, hostflags, player, pSet)
{
    if (!get_pcvar_num(g_pCvarEnabled))
        return FMRES_IGNORED;

    // The corpse is a dedicated server entity, never a player slot.
    if (player || !pev_valid(ent))
        return FMRES_IGNORED;

    new classname[16];
    pev(ent, pev_classname, classname, charsmax(classname));

    // TFC body-queue corpse (CCorpse). This is the only thing we hide.
    if (equal(classname, "bodyque"))
    {
        forward_return(FMV_CELL, 0);
        return FMRES_SUPERCEDE;
    }

    return FMRES_IGNORED;
}

/* Die(ent)
 * ent: the backpack that is spawned when a player spawns
 *
 * Removes the backpack that is spawned due to a player dying by calling think on it, instantly clearling it
 */
public Die(ent) {
    call_think(ent);
    return HAM_SUPERCEDE;
}