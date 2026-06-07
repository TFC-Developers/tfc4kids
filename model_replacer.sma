#include <amxmodx>
#include <tfcx>

public plugin_init()
{
	register_plugin("Model Replacer", "1.0", "Vancold.at")
	register_event("ResetHUD", "EventResetHUD", "be")
}

public plugin_precache()
{
	precache_model("models/player/modelforkids/scout.mdl")
}

public EventResetHUD(id)
{
	if(!is_user_alive(id))
		return PLUGIN_HANDLED

	tfc_setmodel(id, "scout", "")

	return PLUGIN_CONTINUE
}