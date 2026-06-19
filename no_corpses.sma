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
 *  ACTIVE DEATH ANIMATION SUPPRESSION:
 *  ---------------------------------------------------------
 *  The bodyque filter removes the copied corpse entity. Separately, the
 *  actual player edict can briefly show a death animation while the player
 *  is dead / in deathcam / waiting to respawn.
 *
 *  This plugin hides the dying player's own edict by applying EF_NODRAW
 *  when DeathMsg is sent. It does NOT remove the player from AddToFullPack,
 *  because removing the actual player entity from the packet stream can
 *  cause deathcam/camera jitter.
 *
 *  The player can remain dead for any length of time, so this is NOT timer
 *  based. EF_NODRAW is cleared only when the player actually spawns again.
 *
 *  cvar:  nocorpses  1 = hide corpses/death animation (default), 0 = normal
 * =================================================================== */

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <engine>
#include <messages>

new g_pCvarEnabled;

// True while this player is dead and their active death animation should stay hidden.
// Cleared only on real player spawn or disconnect.
new bool:g_bHiddenDeadPlayer[33];

public plugin_init()
{
    register_plugin("TFC No Corpses", "1.2", "MrKoala & Vancold");

    // Suppresses the backpack/weaponbox that TFC spawns when a player dies.
    RegisterHam(Ham_Spawn, "weaponbox", "Die");

    // TFC hamdata does not configure Ham_Killed for player on your setup,
    // so DeathMsg is used as the safe death notification.
    register_message(get_user_msgid("DeathMsg"), "Message_DeathMsg");

    // Restore player visibility only when the player truly respawns.
    RegisterHam(Ham_Spawn, "player", "PlayerSpawn_Post", 1);

    g_pCvarEnabled = register_cvar("nocorpses", "1");

    // Pre-hook so we can supercede the engine's per-entity pack decision.
    register_forward(FM_AddToFullPack, "fw_AddToFullPack", 0);
}

/* Message_DeathMsg(msgid, dest, receiver)
 *
 * Called when TFC broadcasts a player death.
 *
 * We use this instead of Ham_Killed because TFC's hamdata may not expose
 * the killed virtual function for "player".
 *
 * This hides the real player edict with EF_NODRAW while the player is dead.
 * We do NOT remove the player edict from AddToFullPack, because the deathcam
 * may still rely on that entity existing in the client packet stream.
 */
public Message_DeathMsg(msgid, dest, receiver)
{
    if (!get_pcvar_num(g_pCvarEnabled))
        return PLUGIN_CONTINUE;

    new victim = get_msg_arg_int(2);

    if (victim < 1 || victim > 32 || !pev_valid(victim))
        return PLUGIN_CONTINUE;

    g_bHiddenDeadPlayer[victim] = true;

    // Hide the active dying/dead player model.
    set_pev(victim, pev_effects, pev(victim, pev_effects) | EF_NODRAW);

    // Optional safety: stop the death animation from advancing while hidden.
    set_pev(victim, pev_framerate, 0.0);
    set_pev(victim, pev_animtime, get_gametime());

    return PLUGIN_CONTINUE;
}

/* PlayerSpawn_Post(id)
 *
 * Called once the player has respawned.
 *
 * This is the only normal place where EF_NODRAW should be removed, because
 * a player can stay dead/deathcammed for minutes before choosing to respawn.
 */
public PlayerSpawn_Post(id)
{
    if (!pev_valid(id))
        return HAM_IGNORED;

    g_bHiddenDeadPlayer[id] = false;

    // Restore visibility after respawn.
    set_pev(id, pev_effects, pev(id, pev_effects) & ~EF_NODRAW);

    // Restore normal animation playback.
    set_pev(id, pev_framerate, 1.0);

    return HAM_IGNORED;
}

public client_disconnected(id)
{
    g_bHiddenDeadPlayer[id] = false;
}

/* AddToFullPack(es, e, ent, host, hostflags, player, pSet)
 *   ent    : the entity being considered for this host's packet
 *   player : 1 when 'ent' is a player slot
 *
 * Return 0 + SUPERCEDE -> entity excluded from this host's full pack.
 *
 * IMPORTANT:
 *   Only bodyque is removed from AddToFullPack.
 *   The real dead player edict is NOT removed here; it is only hidden via
 *   EF_NODRAW. This avoids deathcam jitter caused by removing the player
 *   entity from the client's entity stream.
 */
public fw_AddToFullPack(es, e, ent, host, hostflags, player, pSet)
{
    if (!get_pcvar_num(g_pCvarEnabled))
        return FMRES_IGNORED;

    // Do not suppress real player slots here.
    if (player || !pev_valid(ent))
        return FMRES_IGNORED;

    new classname[16];
    pev(ent, pev_classname, classname, charsmax(classname));

    // TFC body-queue corpse (CCorpse). This is the copied corpse entity.
    if (equal(classname, "bodyque"))
    {
        forward_return(FMV_CELL, 0);
        return FMRES_SUPERCEDE;
    }

    return FMRES_IGNORED;
}

/* Die(ent)
 * ent: the backpack that is spawned when a player dies
 *
 * Removes the backpack spawned due to player death by calling think on it,
 * instantly clearing it.
 */
public Die(ent)
{
    call_think(ent);
    return HAM_SUPERCEDE;
}