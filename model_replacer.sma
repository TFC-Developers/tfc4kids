/* =============================================================================
 *
 *   TFC Model Replacer (Kids Server)  -  model_replacer.sma
 *   ------------------------------------------------------
 *   Author : Vancold.at
 *   Game   : Team Fortress Classic (stock tfc.so / GoldSrc)
 *
 *   PURPOSE
 *   -------
 *   Part of the "kids-friendly" TFC set-up. We want every player to LOOK the
 *   same - a single friendly kid character - instead of the nine different TFC
 *   class models (Scout, Soldier, Medic, ...). This plugin forces every player's
 *   model to one custom model, "modelforkids", no matter which class TFC thinks
 *   they are. Together with class_selector (everyone is a Medic) this makes all
 *   players visually identical, which is simpler and fairer for young players.
 *
 *   HOW IT WORKS
 *   ------------
 *   In TFC a player's visible model is decided by their class and is (re)applied
 *   every time they spawn. The engine fires a "ResetHUD" event for a player each
 *   time they (re)spawn / their HUD resets, which is the perfect moment to stamp
 *   our own model on top. We hook ResetHUD and call tfc_setmodel() to swap the
 *   player to "modelforkids". Because we re-apply on every spawn, TFC never gets
 *   a chance to show the original class model.
 *
 *   WHY plugin_precache()
 *   ---------------------
 *   GoldSrc will crash on load if asked to use a model that was not precached
 *   during the precache phase, and clients only download files that the server
 *   precaches. So we MUST precache_model() the kid model in plugin_precache()
 *   (which runs early, before the map spawns players) - not later.
 *
 *   REQUIRED FILE
 *   -------------
 *   tfc/models/player/modelforkids/modelforkids.mdl must exist on the server, or
 *   the server will fail to start (see the precache note above).
 *
 *   DEPENDENCY
 *   ----------
 *   Uses tfc_setmodel() from the tfcx module, so the tfcx module must be loaded.
 *
 * ============================================================================= */

#include <amxmodx>
#include <tfcx>

public plugin_precache() {
	// Precache the kid model early so the engine can use it and clients auto-
	// download it. Skipping this would crash the server when we set the model.
	precache_model("models/player/modelforkids/modelforkids.mdl")
}

public plugin_init()
{
	register_plugin("Model Replacer", "1.0", "Vancold.at")

	// ResetHUD fires for a player every time they (re)spawn - our cue to
	// re-apply the kid model before TFC's class model can show.
	register_event("ResetHUD", "EventResetHUD", "be")
}

public EventResetHUD(id)
{
	// Only living, spawned-in players have a model worth replacing.
	if(!is_user_alive(id))
		return PLUGIN_HANDLED

	// Force this player's visible model to the single kid model. The empty
	// second argument keeps the default sub-model / skin.
	tfc_setmodel(id, "modelforkids", "")

	return PLUGIN_CONTINUE
}