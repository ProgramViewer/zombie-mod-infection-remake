#include <amxmodx>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>
#include <zombiemod>

#define VERSION "1.0"

// CS Player CBase Offsets (win32)
const PDATA_SAFE = 2
const OFFSET_ACTIVE_ITEM = 373

#define is_null_weapon(%1) (%1 == CSW_KNIFE || %1 == CSW_FLASHBANG || %1 == CSW_HEGRENADE || %1 == CSW_SMOKEGRENADE || %1 == CSW_C4)

enum _:WeaponData
{
	WeaponID,
	AmmoID,
	MaxClip,
	MaxBPAmmo
}

new const g_weapon_data[][WeaponData] =
{
	{0,             -1,   0,   0},   // NONE
	{CSW_P228,       9,  13,  52},   // P228
	{0,             -1,   0,   0},   // GLOCK
	{CSW_SCOUT,      2,  10,  90},   // SCOUT
	{0,             -1,   0,   0},   // HE GRENADE
	{CSW_XM1014,     5,   7,  32},   // XM1014
	{0,             -1,   0,   0},   // C4
	{CSW_MAC10,      6,  30, 100},   // MAC10
	{CSW_AUG,        4,  30,  90},   // AUG
	{0,             -1,   0,   0},   // SMOKE GRENADE
	{CSW_ELITE,     10,  30, 120},   // ELITE
	{CSW_FIVESEVEN,  7,  20, 100},   // FIVESEVEN
	{CSW_UMP45,      6,  25, 100},   // UMP45
	{CSW_SG550,      4,  30,  90},   // SG550
	{CSW_GALIL,      4,  35,  90},   // GALIL
	{CSW_FAMAS,      4,  25,  90},   // FAMAS
	{CSW_USP,        6,  12, 100},   // USP
	{CSW_GLOCK18,   10,  20, 120},   // GLOCK18
	{CSW_AWP,        1,  10,  30},   // AWP
	{CSW_MP5NAVY,   10,  30, 120},   // MP5
	{CSW_M249,       3, 100, 200},   // M249
	{CSW_M3,         5,   8,  32},   // M3
	{CSW_M4A1,       4,  30,  90},   // M4A1
	{CSW_TMP,       10,  30, 120},   // TMP
	{CSW_G3SG1,      2,  20,  90},   // G3SG1
	{0,             -1,   0,   0},   // FLASHBANG
	{CSW_DEAGLE,     8,   7,  35},   // DEAGLE
	{CSW_SG552,      4,  30,  90},   // SG552
	{CSW_AK47,       2,  30,  90},   // AK47
	{0,             -1,   0,   0},   // KNIFE
	{CSW_P90,        7,  50, 100}    // P90
}

new cvar_human_unlimited_ammo;
new g_cached_human_unlimited_ammo;

public plugin_init()
{
	// Register Plugin
	register_plugin("[ZM] Human Unlimited Ammo", VERSION, "ProgramViewer");
	
	// Check if mod is active
	zmod_is_active() ? plugin_init2() : pause("ad");
}

public plugin_init2() 
{
	// Events
	register_event("HLTV", "event_new_round", "a", "1=0", "2=0");
	register_event("AmmoX", "event_AmmoX", "be");
	
	// Message Hook
	register_message(get_user_msgid("CurWeapon"), "message_cur_weapon");
	
	// Cvar 
	cvar_human_unlimited_ammo = register_cvar("zmod_human_unlimited_ammo", "0");
}

public event_new_round()
{
	g_cached_human_unlimited_ammo = get_pcvar_num(cvar_human_unlimited_ammo);
}

public event_AmmoX(id)
{
	// Not alive or not human
	if(!is_user_alive(id) || zmod_get_user_zombie(id))
	{
		return;
	}
	
	// Unlimited BP ammo enabled for humans?
	if(g_cached_human_unlimited_ammo != 1)
	{
		return;
	}
	
	// Get current weapon
	static weapon;
	weapon = get_user_weapon(id);

	// Invalid weapon??
	if(is_null_weapon(weapon))
	{
		return;
	}
	
	// Primary and secondary only
	if(g_weapon_data[weapon][MaxBPAmmo] <= 2)
	{
		return;
	}
	
	// Get ammo amount
	static amount;
	amount = read_data(2);
	
	// Unlimited BP Ammo
	if(amount < g_weapon_data[weapon][MaxBPAmmo])
	{
		cs_set_user_bpammo(id, weapon, g_weapon_data[weapon][MaxBPAmmo]);
	}
}

// Current Weapon info
public message_cur_weapon(msg_id, msg_dest, msg_entity)
{
	// Not alive or not human
	if(!is_user_alive(msg_entity) || zmod_get_user_zombie(msg_entity))
	{
		return;
	}

	// Unlimited Clip ammo enabled for humans?
	if(g_cached_human_unlimited_ammo != 2)
	{
		return;
	}
	
	// Not an active weapon
	if(get_msg_arg_int(1) != 1)
	{
		return;
	}
	
	// Get weapon's id
	static weapon;
	weapon = get_msg_arg_int(2);
	
	// Primary and secondary only
	if(g_weapon_data[weapon][MaxBPAmmo] <= 2)
	{
		return;
	}
	
	// Max out clip ammo
	static weapon_ent;
	weapon_ent = fm_cs_get_current_weapon_ent(msg_entity);
	
	if(pev_valid(weapon_ent))
	{
		cs_set_weapon_ammo(weapon_ent, g_weapon_data[weapon][MaxClip]);
	}
	
	// HUD should show full clip all the time
	set_msg_arg_int(3, get_msg_argtype(3), g_weapon_data[weapon][MaxClip]);
}

// Get User Current Weapon Entity
stock fm_cs_get_current_weapon_ent(id)
{
	return (pev_valid(id) == PDATA_SAFE) ? get_pdata_cbase(id, OFFSET_ACTIVE_ITEM) : -1;
}
