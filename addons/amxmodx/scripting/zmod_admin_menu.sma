#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>
#include <zombiemod>

// -------------------------
// Constants / Defines
// -------------------------
#define ADMIN_TRANSFORM_HUMAN 1
#define ADMIN_TRANSFORM_ZOMBIE 2
#define ADMIN_TRANSFORM_SUPERZOMBIE 3
#define ADMIN_MENU_HUMAN_SETTINGS 4
#define ADMIN_MENU_ZOMBIE_SETTINGS 5
#define ADMIN_MENU_GLOBAL_SETTINGS 6
#define ADMIN_MENU_WEAPON_RESTRICTIONS 7
#define ADMIN_MENU_NIGHTVISION_SETTINGS 8

const OFFSET_CSMENUCODE = 205;

// -------------------------
// Global player-related flags 
// -------------------------
new g_is_user_alive[33]; // True if player is alive
new g_is_user_connected[33]; // True if player is connected
new g_playername[33][32]; // Player names

// -------------------------
// Menu-related global data
// -------------------------
new g_menu_data[33][8]; // Store various menu pages per player

// Macros for menu pages 
#define MENU_PAGE_HUMAN g_menu_data[id][1]
#define MENU_PAGE_ZOMBIE g_menu_data[id][2]
#define MENU_PAGE_SUPERZOMBIE g_menu_data[id][3]
#define MENU_PAGE_ZOMBIE_SETTINGS g_menu_data[id][4]
#define MENU_PAGE_GLOBAL_SETTINGS g_menu_data[id][5]
#define MENU_PAGE_WEAPON_RESTRICTIONS g_menu_data[id][6]

// -------------------------
// General globals
// -------------------------
new g_maxplayers; // Max players on the server
new g_admin_transform_into; // Current transform action flag
new g_admin_menu_info; // Current menu info
new g_admin_menu[33]; // Store current menu id

// -------------------------
// Step values for menu adjustment
// -------------------------
new g_int_step_value = 1; // Step for integer attributes (health, clip cost, etc)
new Float:g_float_step_value = 0.01; // Step for float attributes (speed, gravity, etc)
new bool:g_step_increase[33]; // Direction flag per player for menu step (true = increase)

// -------------------------
// Cvars for mod configuration
// -------------------------
new cvar_human_health;
new cvar_human_speed;
new cvar_human_gravity;
new cvar_human_clipcost;
new cvar_human_unlimited_ammo;
new cvar_weapons_display;
new cvar_weapons_rifles;
new cvar_weapons_smgs;
new cvar_weapons_shotguns;
new cvar_weapons_snipers;
new cvar_weapons_autosnipers;
new cvar_superzombie_health;
new cvar_superzombie_speed;
new cvar_superzombie_gravity;
new cvar_superzombie_chance;
new cvar_superzombie_enabled;
new cvar_firstzombie_health;
new cvar_zombie_brainhealth;
new cvar_zombie_armor;
new cvar_zombie_health;
new cvar_zombie_speed;
new cvar_zombie_gravity;
new cvar_delay;
new cvar_thunderclap;
new cvar_lightning;
new cvar_nvgsize;
new cvar_nvgcustom;
new cvar_nvgcolor[3];
new cvar_custom_win_sounds;
new cvar_block_hud_messages;
new cvar_he_hitself;

// Structure for individual weapon menu items
enum _:WeaponItem
{
	WeaponName[32],   // language key, e.g. "MENU_WEAPON_M3"
	CvarSuffix[32]    // suffix for cvar name, e.g. "m3"
}

static const g_primary_weapons_list[][WeaponItem] =
{
	{"MENU_WEAPON_M3",        "m3"},
	{"MENU_WEAPON_XM1014",    "xm1014"},
	{"MENU_WEAPON_TMP",       "tmp"},
	{"MENU_WEAPON_MAC10",     "mac10"},
	{"MENU_WEAPON_MP5NAVY",   "mp5navy"},
	{"MENU_WEAPON_P90",       "p90"},
	{"MENU_WEAPON_UMP45",     "ump45"},
	{"MENU_WEAPON_FAMAS",     "famas"},
	{"MENU_WEAPON_GALIL",     "galil"},
	{"MENU_WEAPON_AK47",      "ak47"},
	{"MENU_WEAPON_M4A1",      "m4a1"},
	{"MENU_WEAPON_SG552",     "sg552"},
	{"MENU_WEAPON_AUG",       "aug"},
	{"MENU_WEAPON_SCOUT",     "scout"},
	{"MENU_WEAPON_AWP",       "awp"},
	{"MENU_WEAPON_SG550",     "sg550"},
	{"MENU_WEAPON_G3SG1",     "g3sg1"}
};

new g_weapon_cvar_ptrs[sizeof(g_primary_weapons_list)];

#define VERSION "1.0"

public plugin_init()
{
	// Register Plugin
	register_plugin("[ZM] Zombie Mod Infection Admin Menu", VERSION, "ProgramViewer");
	
	// Check if mod is active
	zmod_is_active() ? plugin_init2() : pause("ad");
}

public plugin_init2() 
{
	// Register Dictionary
	register_dictionary("zombie_mod_infection_admin_menu.txt");
	
	// HAM
	RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawnPost", 1);
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled");
	
	// Cmd
	register_clcmd("say /zmadminmenu", "clcmd_adminmenu");

	// Get Maxplayers
	g_maxplayers = get_maxplayers();
}

public plugin_cfg()
{
	set_task(0.5, "load_cvars");
}

public load_cvars()
{
	new loaded, total;

	// -------------------------
	// Cvars Zombies
	// -------------------------
	cvar_zombie_health = get_cvar_pointer("zmod_zombie_health");
	check_cvar(cvar_zombie_health, "zmod_zombie_health", loaded, total);

	cvar_zombie_speed = get_cvar_pointer("zmod_zombie_speed");
	check_cvar(cvar_zombie_speed, "zmod_zombie_speed", loaded, total);

	cvar_zombie_gravity = get_cvar_pointer("zmod_zombie_gravity");
	check_cvar(cvar_zombie_gravity, "zmod_zombie_gravity", loaded, total);

	cvar_zombie_armor = get_cvar_pointer("zmod_zombie_armor");
	check_cvar(cvar_zombie_armor, "zmod_zombie_armor", loaded, total);

	cvar_zombie_brainhealth = get_cvar_pointer("zmod_zombie_brainhealth");
	check_cvar(cvar_zombie_brainhealth, "zmod_zombie_brainhealth", loaded, total);

	cvar_firstzombie_health = get_cvar_pointer("zmod_firstzombie_health");
	check_cvar(cvar_firstzombie_health, "zmod_firstzombie_health", loaded, total);

	cvar_superzombie_health = get_cvar_pointer("zmod_superzombie_health");
	check_cvar(cvar_superzombie_health, "zmod_superzombie_health", loaded, total);

	cvar_superzombie_speed = get_cvar_pointer("zmod_superzombie_speed");
	check_cvar(cvar_superzombie_speed, "zmod_superzombie_speed", loaded, total);

	cvar_superzombie_gravity = get_cvar_pointer("zmod_superzombie_gravity");
	check_cvar(cvar_superzombie_gravity, "zmod_superzombie_gravity", loaded, total);

	cvar_superzombie_chance = get_cvar_pointer("zmod_superzombie_chance");
	check_cvar(cvar_superzombie_chance, "zmod_superzombie_chance", loaded, total);

	cvar_superzombie_enabled = get_cvar_pointer("zmod_superzombie_enabled");
	check_cvar(cvar_superzombie_enabled, "zmod_superzombie_enabled", loaded, total);

	// -------------------------
	// Cvars Weapons
	// -------------------------
	cvar_weapons_display = get_cvar_pointer("zmod_weapons_display");
	check_cvar(cvar_weapons_display, "zmod_weapons_display", loaded, total);

	cvar_weapons_shotguns = get_cvar_pointer("zmod_weapons_shotguns");
	check_cvar(cvar_weapons_shotguns, "zmod_weapons_shotguns", loaded, total);

	cvar_weapons_smgs = get_cvar_pointer("zmod_weapons_smgs");
	check_cvar(cvar_weapons_smgs, "zmod_weapons_smgs", loaded, total);

	cvar_weapons_rifles = get_cvar_pointer("zmod_weapons_rifles");
	check_cvar(cvar_weapons_rifles, "zmod_weapons_rifles", loaded, total);

	cvar_weapons_snipers = get_cvar_pointer("zmod_weapons_snipers");
	check_cvar(cvar_weapons_snipers, "zmod_weapons_snipers", loaded, total);

	cvar_weapons_autosnipers = get_cvar_pointer("zmod_weapons_autosnipers");
	check_cvar(cvar_weapons_autosnipers, "zmod_weapons_autosnipers", loaded, total);
	
	new cvar_name[64];
	for(new i = 0; i < sizeof(g_primary_weapons_list); i++)
	{
		formatex(cvar_name, charsmax(cvar_name), "zmod_weapon_%s", g_primary_weapons_list[i][CvarSuffix]);
		g_weapon_cvar_ptrs[i] = get_cvar_pointer(cvar_name);
		check_cvar(g_weapon_cvar_ptrs[i], cvar_name, loaded, total);
	}

	// -------------------------
	// Cvars Global
	// -------------------------
	cvar_delay = get_cvar_pointer("zmod_delay");
	check_cvar(cvar_delay, "zmod_delay", loaded, total);

	cvar_lightning = get_cvar_pointer("zmod_lights");
	check_cvar(cvar_lightning, "zmod_lights", loaded, total);

	cvar_thunderclap = get_cvar_pointer("zmod_thunderclap");
	check_cvar(cvar_thunderclap, "zmod_thunderclap", loaded, total);
	
	cvar_custom_win_sounds = get_cvar_pointer("zmod_custom_win_sounds");
	check_cvar(cvar_custom_win_sounds, "zmod_custom_win_sounds", loaded, total);

	cvar_block_hud_messages = get_cvar_pointer("zmod_block_hud_messages");
	check_cvar(cvar_block_hud_messages, "zmod_block_hud_messages", loaded, total);

	cvar_he_hitself = get_cvar_pointer("zmod_he_hitself");
	check_cvar(cvar_he_hitself, "zmod_he_hitself", loaded, total);

	// -------------------------
	// Cvars Humans
	// -------------------------
	cvar_human_health = get_cvar_pointer("zmod_human_health");
	check_cvar(cvar_human_health, "zmod_human_health", loaded, total);

	cvar_human_speed = get_cvar_pointer("zmod_human_speed");
	check_cvar(cvar_human_speed, "zmod_human_speed", loaded, total);

	cvar_human_gravity = get_cvar_pointer("zmod_human_gravity");
	check_cvar(cvar_human_gravity, "zmod_human_gravity", loaded, total);

	cvar_human_clipcost = get_cvar_pointer("zmod_human_clipcost");
	check_cvar(cvar_human_clipcost, "zmod_human_clipcost", loaded, total);

	cvar_human_unlimited_ammo = get_cvar_pointer("zmod_human_unlimited_ammo");
	check_cvar(cvar_human_unlimited_ammo, "zmod_human_unlimited_ammo", loaded, total);

	// -------------------------
	// Cvars NVG
	// -------------------------
	cvar_nvgcustom = get_cvar_pointer("zmod_nvg_custom");
	check_cvar(cvar_nvgcustom, "zmod_nvg_custom", loaded, total);

	cvar_nvgsize = get_cvar_pointer("zmod_nvg_size");
	check_cvar(cvar_nvgsize, "zmod_nvg_size", loaded, total);

	cvar_nvgcolor[0] = get_cvar_pointer("zmod_nvg_color_r");
	check_cvar(cvar_nvgcolor[0], "zmod_nvg_color_r", loaded, total);

	cvar_nvgcolor[1] = get_cvar_pointer("zmod_nvg_color_g");
	check_cvar(cvar_nvgcolor[1], "zmod_nvg_color_g", loaded, total);

	cvar_nvgcolor[2] = get_cvar_pointer("zmod_nvg_color_b");
	check_cvar(cvar_nvgcolor[2], "zmod_nvg_color_b", loaded, total);

	// -------------------------
	// Final Result
	// -------------------------
	server_print("[ZM DEBUG] Loaded CVAR pointers: %d / %d", loaded, total);
}

stock check_cvar(pcvar, const name[], &loaded, &total)
{
	total++;

	if(pcvar)
	{
		loaded++;
	}
	else
	{
		server_print("[ZM DEBUG] CVAR %s NOT FOUND", name);
	}
}

// Called when a player joins the server
public client_putinserver(id)
{
	// Mark the player as connected
	g_is_user_connected[id] = true;
	g_is_user_alive[id] = false;
	g_admin_menu[id] = 0;
	
	// Cache the player's name for later use
	get_user_name(id, g_playername[id], charsmax(g_playername[]));
}

// Called when a player leaves the server
public client_disconnected(id)
{
	// Clear flags
	g_is_user_connected[id] = false;
	g_is_user_alive[id] = false;
	g_admin_menu[id] = 0;
	
	// Remove any tasks associated with the player
	remove_task(id);
}

// Command handler for opening the admin menu
public clcmd_adminmenu(id)
{
	// Check if the player has the required admin flag (ADMIN_BAN)
	if(!is_user_admin(id))
	{
		// Inform the player they do not have access
		client_print_color(id, print_team_default, "^4[ZM] ^1%L", LANG_PLAYER, "TXT_NO_ACCESS");
		return PLUGIN_HANDLED;
	}
	
	// Display the admin menu
	zm_admin_menu(id);
	return PLUGIN_HANDLED;
}

// Called after a player spawns (post hook)
public fw_PlayerSpawnPost(id)
{
	// Mark the player as alive
	g_is_user_alive[id] = true;
}

// Called when a player dies
public fw_PlayerKilled(id)
{
	// Mark the player as dead
	g_is_user_alive[id] = false;
}



// Displays the Admin Menu 
public zm_admin_menu(id)
{
	if(!g_is_user_connected[id])
	{
		return;
	}
	
	static menuid, menu[128], data[2];
	
	formatex(menu, charsmax(menu), "%L\r", id, "MENU_ADMIN_TITLE");
	menuid = menu_create(menu, "menu_admin_handler");
	
	// Define admin menu items
	static const ADMIN_MENU_ITEMS[][] =  {{1, "MENU_ADMIN_TRANSFORM_HUMAN"},{2, "MENU_ADMIN_TRANSFORM_ZOMBIE"},{3, "MENU_ADMIN_TRANSFORM_SUPERZOMBIE"},{4, "MENU_ADMIN_SETTINGS_HUMAN"},{5, "MENU_ADMIN_SETTINGS_ZOMBIE"},{6, "MENU_ADMIN_SETTINGS_GLOBAL"},{7, "MENU_ADMIN_WEAPON_RESTRICTIONS"},{8, "MENU_ADMIN_SETTINGS_NIGHTVISION"}};
	
	// Add items
	for(new i = 0; i < sizeof(ADMIN_MENU_ITEMS); i++)
	{
		formatex(menu, charsmax(menu), "%L", id, ADMIN_MENU_ITEMS[i][1]);
		data[0] = ADMIN_MENU_ITEMS[i][0];
		menu_additem(menuid, menu, data);
	}
	
	// Configure next, back and exit buttons
	set_menu_nav(menuid, id);
	
	g_admin_menu[id] = menuid;
	menu_display(id, menuid, 0);
}

// Handles admin menu selections
public menu_admin_handler(id, menu, item)
{
	// Check if user is connected
	if(!g_is_user_connected[id] || item == MENU_EXIT)
	{
		// Notify that changes will take effect next round
		client_print_color(id, print_team_default, "^4[ZM]^1 %L", LANG_PLAYER, "TXT_CHANGES_NEXT_ROUND");
		
		// Destroy the current menu 
		menu_destroy(menu);
		
		// Return that the plugin handled the menu selection
		return PLUGIN_HANDLED;
	}
	
	// Static variables to store info about the selected menu item
	static data[2];
	new iAccess, callback;
	
	// Retrieve information from the selected menu item
	menu_item_getinfo(menu, item, iAccess, data, charsmax(data), _, _, callback);
	
	// Switch based on the current admin menu context 
	switch(data[0])
	{
		case 1: // Transform into Human
		{
			g_admin_transform_into = ADMIN_TRANSFORM_HUMAN;
			zm_player_list(id); 
		}
		case 2: // Transform into Zombie
		{
			g_admin_transform_into = ADMIN_TRANSFORM_ZOMBIE;
			zm_player_list(id);
		}
		case 3: // Transform into Super Zombie
		{
			g_admin_transform_into = ADMIN_TRANSFORM_SUPERZOMBIE;
			zm_player_list(id);
		}
		case 4: // Human Settings
		{
			g_admin_menu_info = ADMIN_MENU_HUMAN_SETTINGS;
			zm_human_settings_menu(id);
		}
		case 5: // Zombie Settings
		{
			g_admin_menu_info = ADMIN_MENU_ZOMBIE_SETTINGS;
			zm_zombie_settings_menu(id);
		}
		case 6: // Global Settings
		{
			g_admin_menu_info = ADMIN_MENU_GLOBAL_SETTINGS;
			zm_global_settings_menu(id); 
		}
		case 7: // Weapon Restrictions
		{
			g_admin_menu_info = ADMIN_MENU_WEAPON_RESTRICTIONS;
			zm_weapon_restrictions_menu(id); 
		}
		case 8: // Nightvision Settings
		{
			g_admin_menu_info = ADMIN_MENU_NIGHTVISION_SETTINGS;
			zm_nvg_settings_menu(id);
		}
	}
	
	// Destroy the current menu 
	menu_destroy(menu);
	
	// Return that the plugin handled the menu selection
	return PLUGIN_HANDLED;
}

// Displays the player list menu for admin transformation actions
public zm_player_list(id)
{
	// Check if the admin is connected before displaying the player list
	if(!g_is_user_connected[id])
	{
		return;
	}
	
	static menu[256];
	new len = 0;
	
	// Add a dynamic title based on the desired admin action
	switch(g_admin_transform_into)
	{
		case ADMIN_TRANSFORM_HUMAN: len += formatex(menu[len], charsmax(menu) - len, "%L", id, "MENU_TRANSFORM_HUMAN");
		case ADMIN_TRANSFORM_ZOMBIE: len += formatex(menu[len], charsmax(menu) - len, "%L", id, "MENU_TRANSFORM_ZOMBIE");
		case ADMIN_TRANSFORM_SUPERZOMBIE: len += formatex(menu[len], charsmax(menu) - len, "%L", id, "MENU_TRANSFORM_SUPERZOMBIE");
	}
	
	// Create the menu with the assembled title
	new menuid = menu_create(menu, "menu_player_list_handler");
	
	static player_name[64], player_id[2], status[32], name_fixed[32];
	
	// Loop through all possible players
	for(new i = 1; i <= g_maxplayers; i++)
	{
		// Skip if the player is not connected or not alive
		if(!is_user_connected(i) || !is_user_alive(i))
		{
			continue;
		}
		
		// Skip if player is spectator or unnasigned
		if(cs_get_user_team(i) == CS_TEAM_SPECTATOR || cs_get_user_team(i) == CS_TEAM_UNASSIGNED)
		{
			continue;
		}
		
		if(zmod_get_user_superzombie(i))
		{
			formatex(status, charsmax(status), "\r[Super Zombie]");
		}
		else if(zmod_get_user_zombie(i))
		{
			formatex(status, charsmax(status), "\r[Zombie]");
		}
		else
		{
			formatex(status, charsmax(status), "\y[Human]");
		}
		
		// Get the player's name
		formatex(name_fixed, charsmax(name_fixed), "%-28s", g_playername[i]);
		formatex(player_name, charsmax(player_name), "%s %s", name_fixed, status);
		
		// Store the player's ID as menu item info
		player_id[0] = i;
		player_id[1] = 0;
		
		// Add the player to the menu
		menu_additem(menuid, player_name, player_id);
	}
	
	// Determine the page to show based on transformation type
	new page = 0;
	switch(g_admin_transform_into)
	{
		case ADMIN_TRANSFORM_HUMAN: page = MENU_PAGE_HUMAN;
		case ADMIN_TRANSFORM_ZOMBIE: page = MENU_PAGE_ZOMBIE;
		case ADMIN_TRANSFORM_SUPERZOMBIE: page = MENU_PAGE_SUPERZOMBIE;
	}
	
	// Back, Next, Exit
	formatex(menu, charsmax(menu), "%L", id, "MENU_BACK");
	menu_setprop(menuid, MPROP_BACKNAME, menu);
	formatex(menu, charsmax(menu), "%L", id, "MENU_NEXT");
	menu_setprop(menuid, MPROP_NEXTNAME, menu);
	formatex(menu, charsmax(menu), "%L", id, "MENU_EXIT");
	menu_setprop(menuid, MPROP_EXITNAME, menu);
	
	// Clamp remembered page if it exceeds the max page count
	page = min(page, menu_pages(menuid) - 1);
	
	// Fix for AMXX custom menus
	set_pdata_int(id, OFFSET_CSMENUCODE, 0);
	
	// Stores the current menu ID for this player to allow proper destruction or tracking later
	g_admin_menu[id] = menuid;
	
	// Display the menu to the admin
	menu_display(id, menuid, page);
}

// Handles the player selection from the admin transformation menu
public menu_player_list_handler(id, menu, item)
{
	// Check if user is connected
	if(!g_is_user_connected[id])
	{
		// Destroy the current menu 
		menu_destroy(menu);
		
		// Return that the plugin handled the menu selection
		return PLUGIN_HANDLED;
	}
	
	// Close the menu if the player presses exit
	if(item == MENU_EXIT)
	{
		// Go back to the admin menu if user wants to do another action
		zm_admin_menu(id);
		
		// Destroy the menu
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	
	// Retrieve player ID stored in the menu item
	static player_id[2], dummy, menudummy, page;
	menu_item_getinfo(menu, item, dummy, player_id, charsmax(player_id), _, _, dummy);
	player_menu_info(id, menudummy, menudummy, page);
	
	switch(g_admin_transform_into)
	{
		case ADMIN_TRANSFORM_HUMAN: page = MENU_PAGE_HUMAN;
		case ADMIN_TRANSFORM_ZOMBIE: page = MENU_PAGE_ZOMBIE;
		case ADMIN_TRANSFORM_SUPERZOMBIE: page = MENU_PAGE_SUPERZOMBIE;
	}

	new target = player_id[0];
	
	// Check if the target is still connected
	if(!g_is_user_connected[target])
	{
		client_print_color(id, print_team_default, "^4[ZM] ^1%L", LANG_PLAYER, "TXT_TARGET_NO_CONNECTED");
		zm_player_list(id);
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	
	// Check if the target is alive to apply transformations
	if(!g_is_user_alive[target])
	{
		client_print_color(id, print_team_default, "^4[ZM] ^1%L", LANG_PLAYER, "TXT_TARGET_DEAD");
		zm_player_list(id);
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	
	// Check if the first zombie has been selected
	if(zmod_has_round_started() == 0)
	{
		client_print_color(id, print_team_default, "^4[ZM] ^1%L", LANG_PLAYER, "TXT_SELECTION_IN_PROGRESS");
		zm_player_list(id);
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	
	// Perform the action based on the current admin action
	switch(g_admin_transform_into)
	{
		case ADMIN_TRANSFORM_HUMAN: // Transform the player into a human
		{
			// Check if the target isn't a human
			if(!zmod_get_user_human(target) && zmod_get_zombie_count() > 1)
			{
				zmod_force_transform_human(target);
				client_print_color(id, print_team_default, "^4[ZM] ^1%L", LANG_PLAYER, "TXT_TRANSFORMED_HUMAN", g_playername[target]);
				client_print_color(0, print_team_default, "^4[ZM] ^1%L", LANG_PLAYER, "TXT_ADMIN_TRANSFORM_HUMAN", g_playername[id], g_playername[target]);
				zm_player_list(id);
			}
			else if(zmod_get_zombie_count() == 1)
			{
				client_print_color(id, print_team_default, "^4[ZM] ^1%L", LANG_PLAYER, "TXT_CANT_FORCE_HUMAN");
				zm_player_list(id);
			}
			else
			{
				client_print_color(id, print_team_default, "^4[ZM] ^1%L", LANG_PLAYER, "TXT_ALREADY_HUMAN");
				zm_player_list(id);
			}
		}
		case ADMIN_TRANSFORM_ZOMBIE: // Transform the player into a normal zombie
		{
			// Check if the target isn't a zombie
			if(!zmod_get_user_zombie(target) && zmod_get_human_count() > 1)
			{
				zmod_force_transform_zombie(target);
				client_print_color(id, print_team_default, "^4[ZM] ^1%L", LANG_PLAYER, "TXT_TRANSFORMED_ZOMBIE", g_playername[target]);
				client_print_color(0, print_team_default, "^4[ZM] ^1%L", LANG_PLAYER, "TXT_ADMIN_TRANSFORM_ZOMBIE", g_playername[id], g_playername[target]);
				zm_player_list(id);	
			}
			else if(zmod_get_human_count() == 1)
			{
				client_print_color(id, print_team_default, "^4[ZM] ^1%L", LANG_PLAYER, "TXT_CANT_FORCE_ZOMBIE"); 
				zm_player_list(id);
			}
			else
			{
				client_print_color(id, print_team_default, "^4[ZM] ^1%L", LANG_PLAYER, "TXT_ALREADY_ZOMBIE");
				zm_player_list(id);
			}
		}
		case ADMIN_TRANSFORM_SUPERZOMBIE: // Transform the player into a super zombie
		{
			// Check if the target isn't a super zombie
			if(!zmod_get_user_superzombie(target) && zmod_get_human_count() > 1)
			{
				zmod_force_transform_super_zombie(target);
				client_print_color(id, print_team_default, "^4[ZM] ^1%L", LANG_PLAYER, "TXT_TRANSFORMED_SUPERZOMBIE", g_playername[target]);
				client_print_color(0, print_team_default, "^4[ZM] ^1%L", LANG_PLAYER, "TXT_ADMIN_TRANSFORM_SUPERZOMBIE", g_playername[id], g_playername[target]);
				zm_player_list(id);
			}
			else if(zmod_get_human_count() == 1)
			{
				client_print_color(id, print_team_default, "^4[ZM] ^1%L", LANG_PLAYER, "TXT_CANT_FORCE_SUPERZOMBIE");
				zm_player_list(id);
			}
			else
			{
				client_print_color(id, print_team_default, "^4[ZM] ^1%L", LANG_PLAYER, "TXT_ALREADY_SUPERZOMBIE");
				zm_player_list(id);
			}
		}
	}
	
	// Destroy the menu after handling the selection
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

// Displays the human settings menu 
public zm_human_settings_menu(id)
{
	if(!g_is_user_connected[id])
	{
		return;
	}
	
	new menuid = menu_create(fmt("%L\r", id, "MENU_HUMAN_SETTINGS_TITLE"), "menu_admin_settings_handler");
	new data[2];
	
	// 1. Health (int)
	data[0] = 1;
	menu_additem(menuid, fmt("%L: \y%d", id, "MENU_HUMAN_HEALTH", get_pcvar_num(cvar_human_health)), data);
	
	// 2. Speed (float)
	data[0] = 2;
	menu_additem(menuid, fmt("%L: \y%.1f", id, "MENU_HUMAN_SPEED", get_pcvar_float(cvar_human_speed)), data);
	
	// 3. Gravity (float)
	data[0] = 3;
	menu_additem(menuid, fmt("%L: \y%.1f", id, "MENU_HUMAN_GRAVITY", get_pcvar_float(cvar_human_gravity)), data);
	
	// 4. Clip Cost (int, with $)
	data[0] = 4;
	menu_additem(menuid, fmt("%L: \y$%d", id, "MENU_HUMAN_CLIPCOST", get_pcvar_num(cvar_human_clipcost)), data);
	
	// 5. Unlimited Ammo (3-state)
	new status[32];
	switch(get_pcvar_num(cvar_human_unlimited_ammo))
	{
		case 0: formatex(status, charsmax(status), "%L", id, "MENU_UNLIMITED_AMMO_OFF");
		case 1: formatex(status, charsmax(status), "%L", id, "MENU_UNLIMITED_AMMO_AMMO");
		case 2: formatex(status, charsmax(status), "%L", id, "MENU_UNLIMITED_AMMO_CLIP");
	}
	data[0] = 5;
	menu_additem(menuid, fmt("%L: %s", id, "MENU_HUMAN_UNLIMITED_AMMO", status), data);
	
	// 6. Change int step
	data[0] = 6;
	menu_additem(menuid, fmt("%L: \y%d", id, "MENU_CHANGE_INT", g_int_step_value), data);
	
	// 7. Change float step
	data[0] = 7;
	menu_additem(menuid, fmt("%L: \y%.2f", id, "MENU_CHANGE_FLOAT", g_float_step_value), data);
	
	// 8. Switch increase/decrease mode
	formatex(status, charsmax(status), "%L", id, g_step_increase[id] ? "MODE_INCREASE" : "MODE_DECREASE");
	data[0] = 8;
	menu_additem(menuid, fmt("%L: \y%s", id, "MENU_SWITCH_MODE", status), data);
	
	set_menu_nav(menuid, id);
	g_admin_menu[id] = menuid;
	menu_display(id, menuid, 0);
}

// Displays the zombie settings menu 
public zm_zombie_settings_menu(id)
{
	if(!g_is_user_connected[id])
	{
		return;
	}
	
	new menuid = menu_create(fmt("%L\r", id, "MENU_ZOMBIE_SETTINGS_TITLE"), "menu_admin_settings_handler");
	new status[32], data[2];
	
	// 1. Zombie Health
	data[0] = 1;
	menu_additem(menuid, fmt("%L: \y%d", id, "MENU_ZOMBIE_HEALTH", get_pcvar_num(cvar_zombie_health)), data);
	
	// 2. Zombie Speed
	data[0] = 2;
	menu_additem(menuid, fmt("%L: \y%.1f", id, "MENU_ZOMBIE_SPEED", get_pcvar_float(cvar_zombie_speed)), data);
	
	// 3. Zombie Gravity
	data[0] = 3;
	menu_additem(menuid, fmt("%L: \y%.1f", id, "MENU_ZOMBIE_GRAVITY", get_pcvar_float(cvar_zombie_gravity)), data);
	
	// 4. Super Zombie Health
	data[0] = 4;
	menu_additem(menuid, fmt("%L: \y%d", id, "MENU_SUPERZOMBIE_HEALTH", get_pcvar_num(cvar_superzombie_health)), data);
	
	// 5. Super Zombie Speed
	data[0] = 5;
	menu_additem(menuid, fmt("%L: \y%.1f", id, "MENU_SUPERZOMBIE_SPEED", get_pcvar_float(cvar_superzombie_speed)), data);
	
	// 6. Super Zombie Gravity
	data[0] = 6;
	menu_additem(menuid, fmt("%L: \y%.1f", id, "MENU_SUPERZOMBIE_GRAVITY", get_pcvar_float(cvar_superzombie_gravity)), data);
	
	// 7. First Zombie Health
	data[0] = 7;
	menu_additem(menuid, fmt("%L: \y%d", id, "MENU_FIRSTZOMBIE_HEALTH", get_pcvar_num(cvar_firstzombie_health)), data);
	
	// 8. Zombie Brain Health
	data[0] = 8;
	menu_additem(menuid, fmt("%L: \y%d", id, "MENU_ZOMBIE_BRAINHEALTH", get_pcvar_num(cvar_zombie_brainhealth)), data);
	
	// 9. Super Zombie Chance
	data[0] = 9;
	menu_additem(menuid, fmt("%L: \y%d", id, "MENU_SUPERZOMBIE_CHANCE", get_pcvar_num(cvar_superzombie_chance)), data);
	
	// 10. Super Zombie Switch (toggle)
	formatex(status, charsmax(status), "%L", id, get_pcvar_num(cvar_superzombie_enabled) ? "TOGGLE_ENABLED" : "TOGGLE_DISABLED");
	data[0] = 10;
	menu_additem(menuid, fmt("%L: %s", id, "MENU_SUPERZOMBIE_SWITCH", status), data);
	
	// 11. Zombie Armor
	data[0] = 11;
	menu_additem(menuid, fmt("%L: \y%.1f", id, "MENU_ZOMBIE_ARMOR", get_pcvar_float(cvar_zombie_armor)), data);
	
	// 12. Change int step
	data[0] = 12;
	menu_additem(menuid, fmt("%L: \y%d", id, "MENU_CHANGE_INT", g_int_step_value), data);
	
	// 13. Change float step
	data[0] = 13;
	menu_additem(menuid, fmt("%L: \y%.2f", id, "MENU_CHANGE_FLOAT", g_float_step_value), data);
	
	// 14. Switch increase/decrease
	data[0] = 14;
	formatex(status, charsmax(status), "%L", id, g_step_increase[id] ? "MODE_INCREASE" : "MODE_DECREASE");
	menu_additem(menuid, fmt("%L: \y%s", id, "MENU_SWITCH_MODE", status), data);
	
	// Configure next, back and exit buttons
	set_menu_nav(menuid, id);
	
	// Clamp remembered page if it exceeds the max page count
	MENU_PAGE_ZOMBIE_SETTINGS = min(MENU_PAGE_ZOMBIE_SETTINGS, menu_pages(menuid) - 1);
	
	g_admin_menu[id] = menuid;
	menu_display(id, menuid, MENU_PAGE_ZOMBIE_SETTINGS);
}

// Displays the global settings menu
public zm_global_settings_menu(id)
{
	if(!g_is_user_connected[id])
	{
		return;
	}
	
	new menuid = menu_create(fmt("%L\r", id, "MENU_GLOBAL_SETTINGS_TITLE"), "menu_admin_settings_handler");
	new status[32], data[2];
	
	// 1. Delay before infection
	data[0] = 1;
	menu_additem(menuid, fmt("%L: \y%d", id, "MENU_GLOBAL_DELAY", get_pcvar_num(cvar_delay)), data);
	
	// 2. Thunderclap interval
	data[0] = 2;
	menu_additem(menuid, fmt("%L: \y%d", id, "MENU_GLOBAL_THUNDERCLAP", get_pcvar_num(cvar_thunderclap)), data);
	
	// 3. Lightning effect state
	new lightning[2];
	get_pcvar_string(cvar_lightning, lightning, charsmax(lightning));
	(!lightning[0] || lightning[0] == '0') ? formatex(status, charsmax(status), "%L", id, "TOGGLE_DISABLED") : formatex(status, charsmax(status), "\y%c", lightning[0]);
	data[0] = 3;
	menu_additem(menuid, fmt("%L: %s", id, "MENU_GLOBAL_LIGHTNING", status), data);
	
	// 4. Custom Win Sounds
	formatex(status, charsmax(status), "%L", id, get_pcvar_num(cvar_custom_win_sounds) ? "TOGGLE_ENABLED" : "TOGGLE_DISABLED");
	data[0] = 4;
	menu_additem(menuid, fmt("%L: %s", id, "MENU_GLOBAL_CUSTOM_WIN_SOUNDS", status), data);
	
	// 5. Block Hud Messages
	formatex(status, charsmax(status), "%L", id, get_pcvar_num(cvar_block_hud_messages) ? "TOGGLE_ENABLED" : "TOGGLE_DISABLED");
	data[0] = 5;
	menu_additem(menuid, fmt("%L: %s", id, "MENU_GLOBAL_BLOCK_HUD_MESSAGES", status), data);
	
	// 6. He Grenade Hitself
	formatex(status, charsmax(status), "%L", id, get_pcvar_num(cvar_he_hitself) ? "TOGGLE_ENABLED" : "TOGGLE_DISABLED");
	data[0] = 6;
	menu_additem(menuid, fmt("%L: %s", id, "MENU_GLOBAL_HE_HITSELF", status), data);
	
	// 7. Change int values by
	data[0] = 7;
	menu_additem(menuid, fmt("%L: \y%d", id, "MENU_CHANGE_INT", g_int_step_value), data);
	
	// 8. Switch increase/decrease
	formatex(status, charsmax(status), "%L", id, g_step_increase[id] ? "MODE_INCREASE" : "MODE_DECREASE");
	data[0] = 8;
	menu_additem(menuid, fmt("%L: \y%s", id, "MENU_SWITCH_MODE", status), data);
	
	set_menu_nav(menuid, id);
	
	MENU_PAGE_GLOBAL_SETTINGS = min(MENU_PAGE_GLOBAL_SETTINGS, menu_pages(menuid) - 1);
	g_admin_menu[id] = menuid;
	menu_display(id, menuid, MENU_PAGE_GLOBAL_SETTINGS);
}

// Displays the weapon restrictions menu
public zm_weapon_restrictions_menu(id)
{
	if(!g_is_user_connected[id])
	{
		return;
	}
	
	new menuid = menu_create(fmt("%L\r", id, "MENU_WEAPON_RESTRICTIONS_TITLE"), "menu_admin_settings_handler");
	new status[32], data[2];
	
	// 1. Weapon Menu Enabled
	formatex(status, charsmax(status), "%L", id, get_pcvar_num(cvar_weapons_display) ? "TOGGLE_ENABLED" : "TOGGLE_DISABLED");
	data[0] = 1;
	menu_additem(menuid, fmt("%L: %s", id, "MENU_WEAPON_DISPLAY", status), data);
	
	// 2. Shotguns Category
	formatex(status, charsmax(status), "%L", id, get_pcvar_num(cvar_weapons_shotguns) ? "TOGGLE_ENABLED" : "TOGGLE_DISABLED");
	data[0] = 2;
	menu_additem(menuid, fmt("%L: %s", id, "MENU_WEAPON_SHOTGUNS", status), data);
	
	// 3. SMGs Category
	formatex(status, charsmax(status), "%L", id, get_pcvar_num(cvar_weapons_smgs) ? "TOGGLE_ENABLED" : "TOGGLE_DISABLED");
	data[0] = 3;
	menu_additem(menuid, fmt("%L: %s", id, "MENU_WEAPON_SMGS", status), data);
	
	// 4. Rifles Category
	formatex(status, charsmax(status), "%L", id, get_pcvar_num(cvar_weapons_rifles) ? "TOGGLE_ENABLED" : "TOGGLE_DISABLED");
	data[0] = 4;
	menu_additem(menuid, fmt("%L: %s", id, "MENU_WEAPON_RIFLES", status), data);
	
	// 5. Snipers Category
	formatex(status, charsmax(status), "%L", id, get_pcvar_num(cvar_weapons_snipers) ? "TOGGLE_ENABLED" : "TOGGLE_DISABLED");
	data[0] = 5;
	menu_additem(menuid, fmt("%L: %s", id, "MENU_WEAPON_SNIPERS", status), data);
	
	// 6. Auto Snipers Category
	formatex(status, charsmax(status), "%L", id, get_pcvar_num(cvar_weapons_autosnipers) ? "TOGGLE_ENABLED" : "TOGGLE_DISABLED");
	data[0] = 6;
	menu_additem(menuid, fmt("%L: %s", id, "MENU_WEAPON_AUTOSNIPERS", status), data);
	
	// -------- Individual Weapons (items 7+) --------
	new total_weapons = sizeof(g_primary_weapons_list);
	for(new i = 0; i < total_weapons; i++)
	{
		data[0] = 100 + i;   // unique ID > 6 to distinguish from categories
		new value = get_pcvar_num(g_weapon_cvar_ptrs[i]);
		formatex(status, charsmax(status), "%L", id, value ? "TOGGLE_ENABLED" : "TOGGLE_DISABLED");
		menu_additem(menuid, fmt("%L: %s", id, g_primary_weapons_list[i][WeaponName], status), data);
	}
	
	// Navigation (Back, Next, Exit)
	set_menu_nav(menuid, id);
	
	MENU_PAGE_WEAPON_RESTRICTIONS = min(MENU_PAGE_WEAPON_RESTRICTIONS, menu_pages(menuid) - 1);
	g_admin_menu[id] = menuid;
	menu_display(id, menuid, MENU_PAGE_WEAPON_RESTRICTIONS);
}

// Displays the nightvision settings menu 
public zm_nvg_settings_menu(id)
{
	if(!g_is_user_connected[id])
	{
		return;
	}
	
	new menuid = menu_create(fmt("%L\r", id, "MENU_NIGHTVISION_SETTINGS_TITLE"), "menu_admin_settings_handler");
	new status[32], data[2];
	
	// 1. Custom Nightvision (toggle)
	formatex(status, charsmax(status), "%L", id, get_pcvar_num(cvar_nvgcustom) ? "TOGGLE_ENABLED" : "TOGGLE_DISABLED");
	data[0] = 1;
	menu_additem(menuid, fmt("%L: %s", id, "MENU_NIGHTVISION_CUSTOM", status), data);
	
	// 2. Nightvision Size
	data[0] = 2;
	menu_additem(menuid, fmt("%L: \y%d", id, "MENU_NIGHTVISION_SIZE", get_pcvar_num(cvar_nvgsize)), data);
	
	// 3. Nightvision Color Red
	data[0] = 3;
	menu_additem(menuid, fmt("%L: \y%d", id, "MENU_NIGHTVISION_COLOR_R", get_pcvar_num(cvar_nvgcolor[0])), data);
	
	// 4. Nightvision Color Green
	data[0] = 4;
	menu_additem(menuid, fmt("%L: \y%d", id, "MENU_NIGHTVISION_COLOR_G", get_pcvar_num(cvar_nvgcolor[1])), data);
	
	// 5. Nightvision Color Blue
	data[0] = 5;
	menu_additem(menuid, fmt("%L: \y%d", id, "MENU_NIGHTVISION_COLOR_B", get_pcvar_num(cvar_nvgcolor[2])), data);
	
	// 6. Change int step
	data[0] = 6;
	menu_additem(menuid, fmt("%L: \y%d", id, "MENU_CHANGE_INT", g_int_step_value), data);
	
	// 7. Switch increase/decrease
	formatex(status, charsmax(status), "%L", id, g_step_increase[id] ? "MODE_INCREASE" : "MODE_DECREASE");
	data[0] = 7;
	menu_additem(menuid, fmt("%L: \y%s", id, "MENU_SWITCH_MODE", status), data);
	
	// Only Exit button
	menu_setprop(menuid, MPROP_EXITNAME, fmt("%L", id, "MENU_EXIT"));
	set_pdata_int(id, OFFSET_CSMENUCODE, 0);
	
	g_admin_menu[id] = menuid;
	menu_display(id, menuid, 0);
}

public menu_admin_settings_handler(id, menu, item)
{
	// Check if user is connected
	if(!g_is_user_connected[id])
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	
	// Check if the player is exiting some of the menus
	if(item == MENU_EXIT)
	{
		zm_admin_menu(id);
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	
	new data[2];
	menu_item_getinfo(menu, item, _, data, charsmax(data));
	new key = data[0];   // Direct integer, no conversion needed
	
	// Switch based on the current admin menu context 
	switch(g_admin_menu_info)
	{
		case ADMIN_MENU_HUMAN_SETTINGS: handle_human_settings(id, key);
		case ADMIN_MENU_ZOMBIE_SETTINGS: handle_zombie_settings(id, key);
		case ADMIN_MENU_GLOBAL_SETTINGS: handle_global_settings(id, key);
		case ADMIN_MENU_WEAPON_RESTRICTIONS: handle_weapon_restrictions(id, key);
		case ADMIN_MENU_NIGHTVISION_SETTINGS: handle_nvg_settings(id, key);
	}
	
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

handle_human_settings(id, key)
{
	new current, Float:current_f;
	
	switch(key)
	{
		case 1:
		{
			current = update_pcvar_int(id, cvar_human_health, 1);
			print_int_setting(id, "MENU_HUMAN_HEALTH_SET", current);
		}
		case 2:
		{
			current_f = update_pcvar_float(id, cvar_human_speed, 0.1);
			print_float_setting(id, "MENU_HUMAN_SPEED_SET", current_f);
		}
		case 3:
		{
			current_f = update_pcvar_float(id, cvar_human_gravity, 0.1);
			print_float_setting(id, "MENU_HUMAN_GRAVITY_SET", current_f);
		}
		case 4:
		{
			current = update_pcvar_int(id, cvar_human_clipcost, 0);
			print_money_setting(id, "MENU_HUMAN_CLIPCOST_SET", current);
		}
		case 5: cycle_unlimited_ammo(id);
		case 6:
		{
			update_step_value_int(id);
			print_int_setting(id, "MENU_CHANGE_INT", g_int_step_value);
		}
		case 7:
		{
			update_step_value_float(id);
			print_float_setting(id, "MENU_CHANGE_FLOAT", g_float_step_value);
		}
		case 8: toggle_step_mode(id);
		default:
		{
			log_amx("[ZM] Invalid key %d in human settings", key);
			return;
		}
	}
	
	zm_human_settings_menu(id);
}

handle_zombie_settings(id, key)
{
	// Store page info for pagination (if needed)
	static dummy;
	player_menu_info(id, dummy, dummy, MENU_PAGE_ZOMBIE_SETTINGS);
	
	new current, Float:current_f;
	
	switch(key)
	{
		case 1:
		{
			current = update_pcvar_int(id, cvar_zombie_health, 1);
			print_int_setting(id, "MENU_ZOMBIE_HEALTH_SET", current);
		}
		case 2:
		{
			current_f = update_pcvar_float(id, cvar_zombie_speed, 0.1);
			print_float_setting(id, "MENU_ZOMBIE_SPEED_SET", current_f);
		}
		case 3:
		{
			current_f = update_pcvar_float(id, cvar_zombie_gravity, 0.1);
			print_float_setting(id, "MENU_ZOMBIE_GRAVITY_SET", current_f);
		}
		case 4:
		{
			current = update_pcvar_int(id, cvar_superzombie_health, 1);
			print_int_setting(id, "MENU_SUPERZOMBIE_HEALTH_SET", current);
		}
		case 5:
		{
			current_f = update_pcvar_float(id, cvar_superzombie_speed, 0.1);
			print_float_setting(id, "MENU_SUPERZOMBIE_SPEED_SET", current_f);
		}
		case 6:
		{
			current_f = update_pcvar_float(id, cvar_superzombie_gravity, 0.1);
			print_float_setting(id, "MENU_SUPERZOMBIE_GRAVITY_SET", current_f);
		}
		case 7:
		{
			current = update_pcvar_int(id, cvar_firstzombie_health, 1);
			print_int_setting(id, "MENU_FIRSTZOMBIE_HEALTH_SET", current);
		}
		case 8:
		{
			current = update_pcvar_int(id, cvar_zombie_brainhealth, 0);
			print_int_setting(id, "MENU_ZOMBIE_BRAINHEALTH_SET", current);
		}
		case 9:
		{
			current = get_pcvar_num(cvar_superzombie_chance);
			current += (g_step_increase[id] ? 1 : -1);
			current = clamp(current, 1, 100);
			set_pcvar_num(cvar_superzombie_chance, current);
			new percent = 101 - current;
			client_print_color(id, print_team_default, "^4[ZM]^1 %L: ^3%d%%", LANG_PLAYER, "MENU_SUPERZOMBIE_CHANCE_SET", percent);
		}
		case 10: toggle_item(cvar_superzombie_enabled, "MENU_SUPERZOMBIE_ENABLED_SET", id);
		case 11:
		{
			current_f = update_pcvar_float(id, cvar_zombie_armor, 0.1);
			print_float_setting(id, "MENU_ZOMBIE_ARMOR_SET", current_f);
		}
		case 12:
		{
			update_step_value_int(id);
			print_int_setting(id, "MENU_INT_STEP_CHANGED", g_int_step_value);
		}
		case 13:
		{
			update_step_value_float(id);
			print_float_setting(id, "MENU_FLOAT_STEP_CHANGED", g_float_step_value);
		}
		case 14: toggle_step_mode(id);
		default:
		{
			log_amx("[ZM] Invalid key %d in zombie settings", key);
			return;
		}
	}
	
	zm_zombie_settings_menu(id);
}

handle_global_settings(id, key)
{
	static dummy;
	player_menu_info(id, dummy, dummy, MENU_PAGE_GLOBAL_SETTINGS);
	
	new current;
	
	switch(key)
	{
	 	case 1:
		{
			current = update_pcvar_int(id, cvar_delay, 1);
			print_int_setting(id, "MENU_GLOBAL_DELAY_SET", current);
		}
		case 2:
		{
			current = update_pcvar_int(id, cvar_thunderclap, 1);
			print_int_setting(id, "MENU_GLOBAL_THUNDERCLAP_SET", current);
		}
		case 3: cycle_lightning(id);
		case 4: toggle_item(cvar_custom_win_sounds, "MENU_GLOBAL_CUSTOM_WIN_SOUNDS_SET", id);
		case 5: toggle_item(cvar_block_hud_messages, "MENU_GLOBAL_BLOCK_HUD_MESSAGES_SET", id);
		case 6: toggle_item(cvar_he_hitself, "MENU_GLOBAL_HE_HITSELF_SET", id);
		case 7:
		{
			update_step_value_int(id);
			print_int_setting(id, "MENU_INT_STEP_CHANGED", g_int_step_value);
		}
		case 8: toggle_step_mode(id);
		default:
		{
			log_amx("[ZM] Invalid key %d in global settings", key);
			return;
		}
	}
	
	zm_global_settings_menu(id);
}

handle_weapon_restrictions(id, key)
{
	// Store page info for pagination (if needed)
	static dummy;
	player_menu_info(id, dummy, dummy, MENU_PAGE_WEAPON_RESTRICTIONS);
	
	if(key >= 1 && key <= 6)
	{
		// Category toggles
		switch(key)
		{
			case 1: toggle_item(cvar_weapons_display, "MENU_WEAPON_DISPLAY_CHANGE", id);
			case 2: toggle_item(cvar_weapons_shotguns, "MENU_WEAPON_SHOTGUNS_CHANGE", id);
			case 3: toggle_item(cvar_weapons_smgs, "MENU_WEAPON_SMGS_CHANGE", id);
			case 4: toggle_item(cvar_weapons_rifles, "MENU_WEAPON_RIFLES_CHANGE", id);
			case 5: toggle_item(cvar_weapons_snipers, "MENU_WEAPON_SNIPERS_CHANGE", id);
			case 6: toggle_item(cvar_weapons_autosnipers, "MENU_WEAPON_AUTOSNIPERS_CHANGE", id);
		}
	}
	else if(key >= 100 && key < 100 + sizeof(g_primary_weapons_list))
	{
		new index = key - 100;
		new current = get_pcvar_num(g_weapon_cvar_ptrs[index]);
		set_pcvar_num(g_weapon_cvar_ptrs[index], current ? 0 : 1);
		
		new status[32], weapon_name[32];
		formatex(status, charsmax(status), "%L", id, current ? "TXT_DISABLED" : "TXT_ENABLED");
		formatex(weapon_name, charsmax(weapon_name), "%L", id, g_primary_weapons_list[index][WeaponName]);
		client_print_color(id, print_team_default, "^4[ZM]^1 %L", id, "MENU_WEAPON_INDIVIDUAL_CHANGED", weapon_name, status);
	}
	else
	{
		log_amx("[ZM] Invalid key %d in weapon restrictions", key);
		return;
	}
	
	zm_weapon_restrictions_menu(id);
}

handle_nvg_settings(id, key)
{
	new current;
	switch(key)
	{
		case 1: toggle_item(cvar_nvgcustom, "MENU_NIGHTVISION_CUSTOM_SET", id);
		case 2:
		{
			current = update_pcvar_int(id, cvar_nvgsize, 1);
			print_int_setting(id, "MENU_NIGHTVISION_SIZE_CHANGE", current);
		}
		case 3:
		{
			current = update_pcvar_int(id, cvar_nvgcolor[0], 0);
			print_int_setting(id, "MENU_NIGHTVISION_COLOR_R_CHANGE", current);
		}
		case 4:
		{
			current = update_pcvar_int(id, cvar_nvgcolor[1], 0);
			print_int_setting(id, "MENU_NIGHTVISION_COLOR_G_CHANGE", current);
		}
		case 5:
		{
			current = update_pcvar_int(id, cvar_nvgcolor[2], 0);
			print_int_setting(id, "MENU_NIGHTVISION_COLOR_B_CHANGE", current);
		}
		case 6:
		{
			update_step_value_int(id);
			print_int_setting(id, "MENU_INT_STEP_CHANGED", g_int_step_value);
		}
		case 7: toggle_step_mode(id);
		default:
		{
			log_amx("[ZM] Invalid key %d in nightvision settings", key);
			return;
		}
	}
	
	zm_nvg_settings_menu(id);
}

// ============================================================
//  Print helpers
// ============================================================

print_int_setting(id, const key[], value)
{
	client_print_color(id, print_team_default, "^4[ZM]^1 %L: ^3%d", LANG_PLAYER, key, value);
}

print_float_setting(id, const key[], Float:value)
{
	client_print_color(id, print_team_default, "^4[ZM]^1 %L: ^3%.2f", LANG_PLAYER, key, value);
}

print_money_setting(id, const key[], value)
{
	client_print_color(id, print_team_default, "^4[ZM]^1 %L: ^3$%d", LANG_PLAYER, key, value);
}

// ============================================================
//  Unlimited ammo cycling
// ============================================================

cycle_unlimited_ammo(id)
{
	new mode = get_pcvar_num(cvar_human_unlimited_ammo);
	mode = (mode + 1) % 3;
	set_pcvar_num(cvar_human_unlimited_ammo, mode);
	
	static status[32];
	switch(mode)
	{
		case 0: formatex(status, charsmax(status), "%L", id, "TXT_UNLIMITED_AMMO_OFF");
		case 1: formatex(status, charsmax(status), "%L", id, "TXT_UNLIMITED_AMMO_AMMO");
		case 2: formatex(status, charsmax(status), "%L", id, "TXT_UNLIMITED_AMMO_CLIP");
	}
	client_print_color(id, print_team_default, "^4[ZM]^1 %L: ^3%s", LANG_PLAYER, "MENU_HUMAN_UNLIMITED_AMMO_SET", status);
}

// ============================================================
//  Lightning cycle function 
// ============================================================

cycle_lightning(id)
{
	static const lightning_flags[] = "abcdefghijklmnopqrstuvwxyz";
	static const num_flags = sizeof lightning_flags - 1;
	
	new szCurrent[2], iNext;
	get_pcvar_string(cvar_lightning, szCurrent, charsmax(szCurrent));

	if(equal(szCurrent, "0"))
	{
		iNext = 0;
	}
	else
	{
		for(iNext = 0; iNext < num_flags; iNext++)
		{
			if(szCurrent[0] == lightning_flags[iNext])
			{
				iNext++;
				break;
			}
		}
	}
	
	if(iNext >= num_flags)
	{
		set_pcvar_string(cvar_lightning, "0");
		client_print_color(id, print_team_default, "^4[ZM]^1 %L", id, "MENU_GLOBAL_LIGHTNING_SET_DISABLED");
	}
	else
	{
		new szNew[2];
		szNew[0] = lightning_flags[iNext];
		szNew[1] = EOS;
		set_pcvar_string(cvar_lightning, szNew);
		client_print_color(id, print_team_default, "^4[ZM]^1 %L ^3'%s'", id, "MENU_GLOBAL_LIGHTNING_SET", szNew);
	}
	
	zm_global_settings_menu(id);
}

// ============================================================
//  Update integer PCVAR
// ============================================================

update_pcvar_int(id, pcvar, min_val = 1)
{
	new current = get_pcvar_num(pcvar);
	current += (g_step_increase[id] ? g_int_step_value : -g_int_step_value);
	
	if(current < min_val) 
	{
		current = min_val;
	}
	
	set_pcvar_num(pcvar, current);
	return current;
}

// ============================================================
//  Update float PCVAR
// ============================================================

Float:update_pcvar_float(id, pcvar, Float:min_val = 0.1)
{
	new Float:current = get_pcvar_float(pcvar);
	current += (g_step_increase[id] ? g_float_step_value : -g_float_step_value);
	
	if(current < min_val)
	{
		current = min_val;
	}
	
	set_pcvar_float(pcvar, current);
	return current;
}

// ============================================================
//  Update integer step value
// ============================================================

update_step_value_int(id)
{
	g_int_step_value += (g_step_increase[id] ? 1 : -1);
	
	if(g_int_step_value < 1)
	{
		g_int_step_value = 1;
	}
	
	return g_int_step_value;
}

// ============================================================
//  Update float step value
// ============================================================

Float:update_step_value_float(id)
{
	g_float_step_value += (g_step_increase[id] ? 0.01 : -0.01);
	
	if(g_float_step_value < 0.01) 
	{
		g_float_step_value = 0.01;
	}
	
	return g_float_step_value;
}

// ============================================================
//  Toggle step mode (increase/decrease)
// ============================================================

toggle_step_mode(id)
{
	g_step_increase[id] = !g_step_increase[id];
	
	new mode[32];
	formatex(mode, charsmax(mode), "%L", id, g_step_increase[id] ? "MODE_INCREASE" : "MODE_DECREASE");
	client_print_color(id, print_team_default, "^4[ZM]^1 %L: ^3%s", LANG_PLAYER, "MENU_STEP_MODE", mode);
}

// ============================================================
//  Toggle a cvar (enable/disable)
// ============================================================

toggle_item(pcvar, const langkey[], id)
{
	new val = get_pcvar_num(pcvar) ? 0 : 1;
	set_pcvar_num(pcvar, val);
	
	new status[32];
	formatex(status, charsmax(status), "%L", id, val ? "TXT_ENABLED" : "TXT_DISABLED");
	client_print_color(id, print_team_default, "^4[ZM]^1 %L: ^3%s", LANG_PLAYER, langkey, status);
}

// ============================================================
//  Set menu properties
// ============================================================

stock set_menu_nav(menuid, id)
{
	menu_setprop(menuid, MPROP_BACKNAME, fmt("%L", id, "MENU_BACK"));
	menu_setprop(menuid, MPROP_NEXTNAME, fmt("%L", id, "MENU_NEXT"));
	menu_setprop(menuid, MPROP_EXITNAME, fmt("%L", id, "MENU_EXIT"));
	set_pdata_int(id, OFFSET_CSMENUCODE, 0);
}
