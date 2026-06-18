#include <amxmodx>
#include <fakemeta>
#include <fun>

#define PLUGIN  "TFC Force Medic No Class Menu"
#define VERSION "1.0"
#define AUTHOR  "Vancold.at"

#define TFC_MENU_CLASS  3
#define CLASS_MEDIC     5

new Float:g_flNextForce[33];

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR);

    // Disable spectator mode by default
    server_cmd("allow_spectators 0");
    server_exec();

    new msgVGUI = get_user_msgid("VGUIMenu");
    if (msgVGUI)
        register_message(msgVGUI, "Message_VGUIMenu");
}

public client_disconnected(id)
{
    g_flNextForce[id] = 0.0;
    remove_task(id);
}

public Message_VGUIMenu(msgid, dest, id)
{
    if (!is_user_connected(id))
        return PLUGIN_CONTINUE;

    if (get_msg_arg_int(1) == TFC_MENU_CLASS)
    {
        QueueMedicSpawn(id);
        return PLUGIN_HANDLED;
    }

    return PLUGIN_CONTINUE;
}

QueueMedicSpawn(id)
{
    new Float:now = get_gametime();

    if (g_flNextForce[id] > now)
        return;

    g_flNextForce[id] = now + 0.5;

    remove_task(id);
    set_task(0.2, "TaskMedicSpawn", id);
}

public TaskMedicSpawn(id)
{
    if (!is_user_connected(id))
        return;

    new team = pev(id, pev_team);

    // Only real TFC teams: blue/red/yellow/green
    if (team < 1 || team > 4)
        return;

    if (is_user_alive(id))
    {
        user_kill(id, 1);

        remove_task(id);
        set_task(0.2, "TaskMedicSpawn", id);
        return;
    }

    set_pev(id, pev_team, team);
    set_pev(id, pev_playerclass, CLASS_MEDIC);

    dllfunc(DLLFunc_Spawn, id);
}