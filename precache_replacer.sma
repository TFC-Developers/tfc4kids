#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>

#define PLUGIN_NAME    "RES_REPLACEMENT"
#define PLUGIN_VERSION "13.06.2026-fixed2"
#define PLUGIN_AUTHOR  "DarthMan & Vancold.at"

#define CONFIG_DIR      "res_replacement"
#define GLOBAL_CFG_FILE "res_replace.ini"

new Trie:g_tResources;
new Trie:g_tResReturn;

stock BuildConfigPath(const szFile[], szOut[], iOutLen)
{
    new szConfigDir[128];
    get_localinfo("amxx_configsdir", szConfigDir, charsmax(szConfigDir));
    formatex(szOut, iOutLen, "%s/%s/%s", szConfigDir, CONFIG_DIR, szFile);
}

public plugin_precache()
{
    g_tResources = TrieCreate();
    g_tResReturn = TrieCreate();

    LoadGlobalResources();

    // Must be registered during plugin_precache so later game/plugin precaches
    // can be replaced by returning the already-precached replacement index.
    register_forward(FM_PrecacheModel, "OnPrecacheModel_Pre", false);
    register_forward(FM_PrecacheSound, "OnPrecacheSound_Pre", false);

    // Precache all replacements and store their return indexes, like the old
    // Orpheu script did with g_tResReturn + OrpheuSetReturn().
    PrecacheReplacementResources();
}

public plugin_init()
{
    register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);

    register_forward(FM_SetModel, "OnSetModel_Pre", false);
    register_forward(FM_EmitSound, "OnEmitSound_Pre", false);
    register_forward(FM_EmitAmbientSound, "OnEmitAmbientSound_Pre", false);

    RegisterWeaponDeploys();
}

public plugin_cfg()
{
    if (!g_tResources)
    {
        log_amx("[RES] Unable to replace resources.");
        return;
    }

    log_amx("[RES] %d resources loaded for replacement.", TrieGetSize(g_tResources));
}

public plugin_end()
{
    if (g_tResources)
    {
        TrieDestroy(g_tResources);
        g_tResources = Invalid_Trie;
    }

    if (g_tResReturn)
    {
        TrieDestroy(g_tResReturn);
        g_tResReturn = Invalid_Trie;
    }
}

RegisterWeaponDeploys()
{
    // TFC weapon classes. Failed class names are harmless on unsupported mods,
    // but these are the common TFC names used by Ham deploy hooks.
    RegisterHam(Ham_Item_Deploy, "tf_weapon_axe", "OnWeaponDeploy_Post", true);
    RegisterHam(Ham_Item_Deploy, "tf_weapon_shotgun", "OnWeaponDeploy_Post", true);
    RegisterHam(Ham_Item_Deploy, "tf_weapon_supershotgun", "OnWeaponDeploy_Post", true);
    RegisterHam(Ham_Item_Deploy, "tf_weapon_ng", "OnWeaponDeploy_Post", true);
    RegisterHam(Ham_Item_Deploy, "tf_weapon_superng", "OnWeaponDeploy_Post", true);
    RegisterHam(Ham_Item_Deploy, "tf_weapon_gl", "OnWeaponDeploy_Post", true);
    RegisterHam(Ham_Item_Deploy, "tf_weapon_rpg", "OnWeaponDeploy_Post", true);
    RegisterHam(Ham_Item_Deploy, "tf_weapon_flamethrower", "OnWeaponDeploy_Post", true);
    RegisterHam(Ham_Item_Deploy, "tf_weapon_railgun", "OnWeaponDeploy_Post", true);
    RegisterHam(Ham_Item_Deploy, "tf_weapon_ac", "OnWeaponDeploy_Post", true);
    RegisterHam(Ham_Item_Deploy, "tf_weapon_medikit", "OnWeaponDeploy_Post", true);
    RegisterHam(Ham_Item_Deploy, "tf_weapon_spanner", "OnWeaponDeploy_Post", true);
}

LoadGlobalResources()
{
    new szConfigDir[256];
    new szFile[256];

    get_localinfo("amxx_configsdir", szConfigDir, charsmax(szConfigDir));
    formatex(szConfigDir, charsmax(szConfigDir), "%s/%s", szConfigDir, CONFIG_DIR);

    if (!dir_exists(szConfigDir))
        mkdir(szConfigDir);

    formatex(szFile, charsmax(szFile), "%s/%s", szConfigDir, GLOBAL_CFG_FILE);
    LoadResourceFile(szFile);
}

LoadResourceFile(const szFile[])
{
    new hFile = fopen(szFile, "rt");
    if (!hFile)
    {
        log_amx("[RES] Missing config: %s", szFile);
        return;
    }

    new szBuffer[512];
    new szOriginal[256];
    new szReplacement[256];

    while (!feof(hFile) && fgets(hFile, szBuffer, charsmax(szBuffer)))
    {
        trim(szBuffer);

        if (!szBuffer[0] || szBuffer[0] == ';' || szBuffer[0] == '#' || (szBuffer[0] == '/' && szBuffer[1] == '/'))
            continue;

        ParseConfigLine(szBuffer, szOriginal, charsmax(szOriginal), szReplacement, charsmax(szReplacement));
        NormalizeResource(szOriginal, charsmax(szOriginal));
        NormalizeResource(szReplacement, charsmax(szReplacement));

        if (!szOriginal[0] || !szReplacement[0])
            continue;

        TrieSetString(g_tResources, szOriginal, szReplacement);
        server_print("[RES] loaded: %s -> %s", szOriginal, szReplacement);
    }

    fclose(hFile);
}

ParseConfigLine(const szLine[], szOriginal[], iOriginalLen, szReplacement[], iReplacementLen)
{
    new iPos = contain(szLine, ";");

    if (iPos == -1)
        iPos = contain(szLine, "=");

    if (iPos != -1)
    {
        copy(szOriginal, iOriginalLen, szLine);
        szOriginal[iPos] = 0;
        copy(szReplacement, iReplacementLen, szLine[iPos + 1]);
    }
    else
    {
        strtok(szLine, szOriginal, iOriginalLen, szReplacement, iReplacementLen, ' ');
    }

    trim(szOriginal);
    trim(szReplacement);
    remove_quotes(szOriginal);
    remove_quotes(szReplacement);
}

NormalizeResource(szResource[], iLen)
{
    trim(szResource);
    remove_quotes(szResource);
    replace_all(szResource, iLen, "\\", "/");

    // EmitSound/PrecacheSound paths are usually relative to sound/.
    // Allow configs that accidentally include sound/ anyway.
    if (containi(szResource, "sound/") == 0)
        copy(szResource, iLen, szResource[6]);
}

PrecacheReplacementResources()
{
    if (!g_tResources || !TrieGetSize(g_tResources))
        return;

    new TrieIter:hIter = TrieIterCreate(g_tResources);
    new szOriginal[256];
    new szReplacement[256];
    new iReturn;

    while (!TrieIterEnded(hIter))
    {
        TrieIterGetKey(hIter, szOriginal, charsmax(szOriginal));
        TrieIterGetString(hIter, szReplacement, charsmax(szReplacement));

        iReturn = 0;

        if (!IsNullReplacement(szReplacement))
        {
            if (IsModelOrSprite(szReplacement))
                iReturn = engfunc(EngFunc_PrecacheModel, szReplacement);
            else if (IsSound(szReplacement))
                iReturn = engfunc(EngFunc_PrecacheSound, szReplacement);
        }

        // Store the replacement's precache return value under the ORIGINAL name.
        // This is the important old-Orpheu behavior.
        TrieSetCell(g_tResReturn, szOriginal, iReturn);

        TrieIterNext(hIter);
    }

    TrieIterDestroy(hIter);
}

public OnPrecacheSound_Pre(const szSample[])
{
    if (!g_tResources || !g_tResReturn)
        return FMRES_IGNORED;

    static szKey[256];
    static iReturn;

    copy(szKey, charsmax(szKey), szSample);
    NormalizeResource(szKey, charsmax(szKey));

    if (!TrieGetCell(g_tResReturn, szKey, iReturn))
        return FMRES_IGNORED;

    // Optional debug:
    // server_print("[RES] PrecacheSound replaced: %s -> return %d", szKey, iReturn);

    forward_return(FMV_CELL, iReturn);
    return FMRES_SUPERCEDE;
}

public OnPrecacheModel_Pre(const szModel[])
{
    if (!g_tResources || !g_tResReturn)
        return FMRES_IGNORED;

    static szKey[256];
    static iReturn;

    copy(szKey, charsmax(szKey), szModel);
    NormalizeResource(szKey, charsmax(szKey));

    if (!TrieGetCell(g_tResReturn, szKey, iReturn))
        return FMRES_IGNORED;

    // Optional debug:
    // server_print("[RES] PrecacheModel replaced: %s -> return %d", szKey, iReturn);

    forward_return(FMV_CELL, iReturn);
    return FMRES_SUPERCEDE;
}

public OnSetModel_Pre(iEnt, const szModel[])
{
    if (!g_tResources)
        return FMRES_IGNORED;

    static szKey[256];
    static szNewModel[256];

    copy(szKey, charsmax(szKey), szModel);
    NormalizeResource(szKey, charsmax(szKey));

    if (!TrieGetString(g_tResources, szKey, szNewModel, charsmax(szNewModel)))
        return FMRES_IGNORED;

    if (IsNullReplacement(szNewModel))
        return FMRES_SUPERCEDE;

    engfunc(EngFunc_SetModel, iEnt, szNewModel);
    return FMRES_SUPERCEDE;
}

public OnWeaponDeploy_Post(iWeapon)
{
    if (pev_valid(iWeapon) != 2 || !g_tResources)
        return HAM_IGNORED;

    new iPlayer = pev(iWeapon, pev_owner);
    if (!is_user_connected(iPlayer))
        return HAM_IGNORED;

    static szModel[256];
    static szKey[256];
    static szNewModel[256];

    pev(iPlayer, pev_viewmodel2, szModel, charsmax(szModel));
    copy(szKey, charsmax(szKey), szModel);
    NormalizeResource(szKey, charsmax(szKey));

    if (szKey[0] && TrieGetString(g_tResources, szKey, szNewModel, charsmax(szNewModel)) && !IsNullReplacement(szNewModel))
        set_pev(iPlayer, pev_viewmodel2, szNewModel);

    pev(iPlayer, pev_weaponmodel2, szModel, charsmax(szModel));
    copy(szKey, charsmax(szKey), szModel);
    NormalizeResource(szKey, charsmax(szKey));

    if (szKey[0] && TrieGetString(g_tResources, szKey, szNewModel, charsmax(szNewModel)) && !IsNullReplacement(szNewModel))
        set_pev(iPlayer, pev_weaponmodel2, szNewModel);

    return HAM_IGNORED;
}

public OnEmitSound_Pre(iEnt, iChannel, const szSample[], Float:fVolume, Float:fAttenuation, iFlags, iPitch)
{
    if (!g_tResources)
        return FMRES_IGNORED;

    static szKey[256];
    static szNewSound[256];

    copy(szKey, charsmax(szKey), szSample);
    NormalizeResource(szKey, charsmax(szKey));

    if (!TrieGetString(g_tResources, szKey, szNewSound, charsmax(szNewSound)))
        return FMRES_IGNORED;

    if (IsNullReplacement(szNewSound))
        return FMRES_SUPERCEDE;

    engfunc(EngFunc_EmitSound, iEnt, iChannel, szNewSound, fVolume, fAttenuation, iFlags, iPitch);
    return FMRES_SUPERCEDE;
}

public OnEmitAmbientSound_Pre(iEnt, Float:fVecPos[3], const szSample[], Float:fVolume, Float:fAttenuation, iFlags, iPitch)
{
    if (!g_tResources)
        return FMRES_IGNORED;

    static szKey[256];
    static szNewSound[256];

    copy(szKey, charsmax(szKey), szSample);
    NormalizeResource(szKey, charsmax(szKey));

    if (!TrieGetString(g_tResources, szKey, szNewSound, charsmax(szNewSound)))
        return FMRES_IGNORED;

    if (IsNullReplacement(szNewSound))
        return FMRES_SUPERCEDE;

    engfunc(EngFunc_EmitAmbientSound, iEnt, fVecPos, szNewSound, fVolume, fAttenuation, iFlags, iPitch);
    return FMRES_SUPERCEDE;
}

stock bool:IsNullReplacement(const szResource[])
{
    return equali(szResource, "null")
        || equali(szResource, "none")
        || equali(szResource, "silent")
        || equali(szResource, "0");
}

stock bool:IsModelOrSprite(const szResource[])
{
    new iLen = strlen(szResource);
    return iLen >= 4 && (equali(szResource[iLen - 4], ".mdl") || equali(szResource[iLen - 4], ".spr"));
}

stock bool:IsSound(const szResource[])
{
    new iLen = strlen(szResource);
    return iLen >= 4 && equali(szResource[iLen - 4], ".wav");
}