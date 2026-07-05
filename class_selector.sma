/* =============================================================================
 *
 *   TFC Force Medic (Kids Server)  -  class_selector.sma
 *   ----------------------------------------------------
 *   Author : Vancold.at
 *   Game   : Team Fortress Classic (stock tfc.so / GoldSrc)
 *
 *   PURPOSE
 *   -------
 *   Part of the "kids-friendly" TFC set-up. In normal TFC every player must
 *   pick a class (Scout, Soldier, Medic, ...) from a menu, and each class has
 *   different weapons, speed and health. For a simple, fair snowball game we do
 *   NOT want any of that: every player should be the exact same class so nobody
 *   has an advantage. This plugin removes the class choice entirely and forces
 *   everyone to spawn as a Medic.
 *
 *   WHY MEDIC?
 *   ----------
 *   The Medic is a good "neutral" default: medium speed, medium health, and no
 *   special ability that matters once weapons are replaced by snowballs. The
 *   companion plugins then take over: model_replacer gives every Medic the same
 *   kid model, and snowball_gun replaces the Medic's weapons with the snowball
 *   gun. The player never notices they are "a Medic" at all.
 *
 *   HOW IT WORKS
 *   ------------
 *   When TFC wants a player to choose a class it sends them a VGUIMenu message
 *   with menu id 3 (the class menu). We hook that message, and whenever the
 *   class menu is about to open we BLOCK it (PLUGIN_HANDLED so the menu never
 *   shows) and instead queue a forced Medic respawn. Forcing the class means:
 *   set the player's class to Medic, then re-run the spawn so TFC arms them as a
 *   Medic. If they were still alive we kill them first so the spawn is clean.
 *
 *   WHY THE SMALL TIMERS / DEBOUNCE
 *   -------------------------------
 *   The class menu can be (re)sent several times in a row while a player joins
 *   or changes team, and killing + respawning is not instant. The 0.5s debounce
 *   (g_flNextForce) stops us from queueing the force many times per second, and
 *   the short 0.2s task delays let the kill/respawn settle before we try again,
 *   avoiding a fight with TFC's own spawn logic.
 *
 * ============================================================================= */

#include <amxmodx>
#include <fakemeta>
#include <fun>

#define PLUGIN  "TFC Force Medic No Class Menu"
#define VERSION "1.0"
#define AUTHOR  "Vancold.at"

// TFC VGUI menu id for the "choose your class" menu, and the internal class
// number for the Medic. These are fixed values baked into TFC.
#define TFC_MENU_CLASS  3
#define CLASS_MEDIC     5

// Per-player debounce: earliest game-time we are allowed to force this player
// again. Stops repeated class-menu messages from queueing many forced respawns.
new Float:g_flNextForce[33];

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR);

    // Spectator mode would let a player sit outside a team with no class, which
    // breaks the "everyone is an identical Medic" rule. Disable it by default.
    server_cmd("allow_spectators 0");
    server_exec();

    // Hook the class-selection menu so we can suppress it and force Medic instead.
    new msgVGUI = get_user_msgid("VGUIMenu");
    if (msgVGUI)
        register_message(msgVGUI, "Message_VGUIMenu");
}

public client_disconnected(id)
{
    // Clear this slot's state so a future player on the same slot starts fresh.
    g_flNextForce[id] = 0.0;
    remove_task(id);
}

/* Message_VGUIMenu(msgid, dest, id)
 *
 * Fires whenever TFC sends a VGUI menu to a player. We only care about the
 * class menu (id 3). When it appears we BLOCK it (so the kid never sees a class
 * chooser) and queue a forced Medic spawn instead.
 */
public Message_VGUIMenu(msgid, dest, id)
{
    if (!is_user_connected(id))
        return PLUGIN_CONTINUE;

    if (get_msg_arg_int(1) == TFC_MENU_CLASS)
    {
        QueueMedicSpawn(id);
        return PLUGIN_HANDLED; // swallow the class menu; it never reaches the client
    }

    return PLUGIN_CONTINUE;
}

/* QueueMedicSpawn(id)
 *
 * Schedules the actual force-to-Medic on a tiny delay. The debounce prevents us
 * from stacking many forces when TFC re-sends the class menu several times in a
 * row during join / team change.
 */
QueueMedicSpawn(id)
{
    new Float:now = get_gametime();

    if (g_flNextForce[id] > now)
        return;

    g_flNextForce[id] = now + 0.5;

    remove_task(id);
    set_task(0.2, "TaskMedicSpawn", id);
}

/* TaskMedicSpawn(id)
 *
 * Does the real work: make sure the player is a dead-but-on-a-team slot, set
 * their class to Medic, then respawn them. If they are still alive we kill them
 * first and re-queue, because you cannot cleanly re-spawn a live player.
 */
public TaskMedicSpawn(id)
{
    if (!is_user_connected(id))
        return;

    new team = pev(id, pev_team);

    // Only act on players who are actually on a real TFC team (blue/red/yellow/
    // green = 1..4). Team 0 means "not chosen yet" - nothing to force.
    if (team < 1 || team > 4)
        return;

    if (is_user_alive(id))
    {
        // Can't respawn a living player cleanly: kill them, then try again in a
        // moment once TFC has processed the death.
        user_kill(id, 1);

        remove_task(id);
        set_task(0.2, "TaskMedicSpawn", id);
        return;
    }

    // Player is dead and on a team: stamp them as a Medic and spawn them.
    set_pev(id, pev_team, team);
    set_pev(id, pev_playerclass, CLASS_MEDIC);

    dllfunc(DLLFunc_Spawn, id);
}