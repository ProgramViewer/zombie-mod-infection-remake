#include <amxmodx>
#include <fun>
#include <cstrike>
#include <zombiemod>

#define VERSION "1.0"

#define is_null_weapon(%1) (%1 == CSW_KNIFE || %1 == CSW_FLASHBANG || %1 == CSW_HEGRENADE || %1 == CSW_SMOKEGRENADE || %1 == CSW_C4)

enum _:WeaponAmmoData
{
	WeaponID,
	AmmoID,
	MaxBPAmmo,
	BuyAmmo,
	AmmoType[16]
}

new const g_weapon_ammo[][WeaponAmmoData] =
{
	{0,           -1,   0,  -1, ""},               // NONE
	{CSW_P228,     9,  52,  13, "ammo_357sig"},   // P228
	{0,           -1,   0,  -1, ""},               // GLOCK (unused)
	{CSW_SCOUT,    2,  90,  30, "ammo_762nato"},  // SCOUT
	{0,           -1,   0,  -1, ""},               // HE
	{CSW_XM1014,   5,  32,   8, "ammo_buckshot"}, // XM1014
	{0,           -1,   0,  -1, ""},               // C4
	{CSW_MAC10,    6, 100,  12, "ammo_45acp"},    // MAC10
	{CSW_AUG,      4,  90,  30, "ammo_556nato"},  // AUG
	{0,           -1,   0,  -1, ""},               // SMOKE
	{CSW_ELITE,   10, 120,  30, "ammo_9mm"},      // ELITE
	{CSW_FIVESEVEN,7, 100,  50, "ammo_57mm"},     // FIVESEVEN
	{CSW_UMP45,    6, 100,  12, "ammo_45acp"},    // UMP45
	{CSW_SG550,    4,  90,  30, "ammo_556nato"},  // SG550
	{CSW_GALIL,    4,  90,  30, "ammo_556nato"},  // GALIL
	{CSW_FAMAS,    4,  90,  30, "ammo_556nato"},  // FAMAS
	{CSW_USP,      6, 100,  12, "ammo_45acp"},    // USP
	{CSW_GLOCK18, 10, 120,  30, "ammo_9mm"},      // GLOCK18
	{CSW_AWP,      1,  30,  10, "ammo_338magnum"},// AWP
	{CSW_MP5NAVY, 10, 120,  30, "ammo_9mm"},      // MP5
	{CSW_M249,     3, 200,  30, "ammo_556natobox"},// M249
	{CSW_M3,       5,  32,   8, "ammo_buckshot"}, // M3
	{CSW_M4A1,     4,  90,  30, "ammo_556nato"},  // M4A1
	{CSW_TMP,     10, 120,  30, "ammo_9mm"},      // TMP
	{CSW_G3SG1,    2,  90,  30, "ammo_762nato"},  // G3SG1
	{0,           -1,   0,  -1, ""},               // FLASH
	{CSW_DEAGLE,   8,  35,   7, "ammo_50ae"},     // DEAGLE
	{CSW_SG552,    4,  90,  30, "ammo_556nato"},  // SG552
	{CSW_AK47,     2,  90,  30, "ammo_762nato"},  // AK47
	{0,           -1,   0,  -1, ""},               // KNIFE
	{CSW_P90,      7, 100,  50, "ammo_57mm"}      // P90
};

new const sound_buyammo[] = "items/9mmclip1.wav"; // Ammo purchase sound
new cvar_human_clipcost;
new g_cached_human_clipcost;
new g_cached_human_unlimited_ammo;

public plugin_precache()
{
	precache_sound(sound_buyammo);
}

public plugin_init()
{
	// Register Plugin
	register_plugin("[ZM] Buy Ammo", VERSION, "ProgramViewer");
	
	// Check if mod is active
	zmod_is_active() ? plugin_init2() : pause("ad");
}

public plugin_init2() 
{
	// Events
	register_event("HLTV", "event_new_round", "a", "1=0", "2=0");
	register_event("AmmoX", "event_AmmoX", "be");
	
	// Cmd
	register_clcmd("buyammo1", "clcmd_buyammo");
	register_clcmd("buyammo2", "clcmd_buyammo");
	
	// Cvar
	cvar_human_clipcost = register_cvar("zmod_human_clipcost", "200");
}

public event_new_round()
{
	g_cached_human_clipcost = get_pcvar_num(cvar_human_clipcost);
	g_cached_human_unlimited_ammo = get_cvar_num("zmod_human_unlimited_ammo");
}

// Buy ammo command 
public clcmd_buyammo(id)
{
	// Check if the player is alive
	if(!is_user_alive(id))
	{
		client_print_color(id, print_team_default, "^4[ZM] ^1%L", LANG_PLAYER, "TXT_CANT_BUYDEAD");
		return PLUGIN_HANDLED;
	}

	// Check if the player is a zombie
	if(zmod_get_user_zombie(id))
	{
		client_print_color(id, print_team_default, "^4[ZM] ^1%L", LANG_PLAYER, "TXT_ZOMBIECANTBUY");
		return PLUGIN_HANDLED;
	}

	// Check if unlimited ammo is enabled
	if(g_cached_human_unlimited_ammo)
	{
		client_print_color(id, print_team_default, "^4[ZM] ^1%L", LANG_PLAYER, "TXT_UNLIMITED_AMMO_ENABLED");
		return PLUGIN_HANDLED;
	}

	// Get the ammo clip cost and player's current money
	new clipcost = g_cached_human_clipcost;
	new money = cs_get_user_money(id);

	// Check if player has enough money
	if(money < clipcost)
	{
		client_print_color(id, print_team_default, "^4[ZM] ^1%L", LANG_PLAYER, "TXT_NOFUNDS", clipcost);
		return PLUGIN_HANDLED;
	}

	// Get the list of weapons the player owns
	new weapons[32], numweps;
	get_user_weapons(id, weapons, numweps);

	// Initialize arrays for ammo checks and flags
	new bool:ammo_checked[32]; // Prevent giving ammo twice for the same type
	new bool:gave_ammo;         // Tracks if any ammo was actually given
	new bool:has_weapon;       // Tracks if player has at least one weapon

	 // Loop through all weapons the player owns
	for(new i; i < numweps; i++)
	{
		// Prevent re-indexing the array
		new wpn = weapons[i];

		// Skip empty or invalid weapon slots
		if(is_null_weapon(wpn))
		{
			continue;
		}

		// Get the ammo ID for this weapon
		new ammo_id = g_weapon_ammo[wpn][AmmoID];

		// Skip weapons that don't use ammo
		if(ammo_id <= 0)
		{
			continue;
		}

		// Player has at least one valid weapon
		has_weapon = true;

		// Skip if ammo type was already processed
		new idx = ammo_id - 1;
		if(ammo_checked[idx])
		{
			continue;
		}

		// Mark ammo type as processed
		ammo_checked[idx] = true;

		// Get the maximum ammo allowed for this weapon
		new maxammo = g_weapon_ammo[wpn][MaxBPAmmo];

		// Skip if player already has max ammo
		if(cs_get_user_bpammo(id, wpn) >= maxammo)
		{
			continue;
		}

		// Give ammo to the player and mark that ammo was given
		give_item(id, g_weapon_ammo[wpn][AmmoType]);
		gave_ammo = true;
	}

	// Cannot buy ammo without weapons
	if(!has_weapon)
	{
		client_print_color(id, print_team_default, "^4[ZM] ^1%L", LANG_PLAYER, "TXT_NOWEPS");
		return PLUGIN_HANDLED;
	}

	// Player already has full ammo
	if(!gave_ammo)
	{
		client_print_color(id, print_team_default, "^4[ZM] ^1%L", LANG_PLAYER, "TXT_FULLAMMO");
		return PLUGIN_HANDLED;
	}

	// Deduct the clip cost from player's money
	cs_set_user_money(id, money - clipcost, 1);
	
	 // Play the purchase sound
	emit_sound(id, CHAN_ITEM, sound_buyammo, 1.0, ATTN_NORM, 0, PITCH_NORM);
	
	// Notify the player of successful purchase
	client_print_color(id, print_team_default, "^4[ZM] ^1%L", LANG_PLAYER, "TXT_BOUGHTAMMO");

	return PLUGIN_HANDLED;
}

// BP Ammo update
public event_AmmoX(id)
{
	// Humans only
	if(zmod_get_user_zombie(id))
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
	if(g_weapon_ammo[weapon][MaxBPAmmo] <= 2)
	{
		return;
	}
	
	// Get ammo amount
	static amount;
	amount = read_data(2);
	
	// Avoid bots from buying ammo during zombie selection
	if(zmod_has_round_started() != 1)
	{
		return;
	}
	
	// Bots automatically buy ammo when needed
	if(is_user_bot(id) && amount <= g_weapon_ammo[weapon][BuyAmmo])
	{
		// Schedule task 
		set_task(0.1, "clcmd_buyammo", id);
	}
}
