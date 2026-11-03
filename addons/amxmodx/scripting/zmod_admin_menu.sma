#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <fakemeta>
#include <zombiemod>

#define VERSION "1.0"

new g_playername[33][32];
new g_maxplayers; 

#define ADMIN_TRANSFORM_HUMAN 1
#define ADMIN_TRANSFORM_ZOMBIE 2
#define ADMIN_TRANSFORM_SUPERZOMBIE 3
#define ADMIN_MENU_HUMAN_SETTINGS 4
#define ADMIN_MENU_ZOMBIE_SETTINGS 5
#define ADMIN_MENU_GLOBAL_SETTINGS 6
#define ADMIN_MENU_WEAPON_RESTRICTIONS 7
#define ADMIN_MENU_NIGHTVISION_SETTINGS 8
#define MENU_PAGE_HUMAN g_menu_data[id][1]
#define MENU_PAGE_ZOMBIE g_menu_data[id][2]
#define MENU_PAGE_SUPERZOMBIE g_menu_data[id][3]
#define MENU_PAGE_HUMAN_SETTINGS g_menu_data[id][7]
#define MENU_PAGE_ZOMBIE_SETTINGS g_menu_data[id][4]
#define MENU_PAGE_GLOBAL_SETTINGS g_menu_data[id][5]
#define MENU_PAGE_WEAPON_RESTRICTIONS g_menu_data[id][6]

const OFFSET_CSMENUCODE = 205;
new g_menu_data[33][9];
new g_int_step_value = 1;
new Float:g_float_step_value = 0.01;
new bool:g_step_increase[33];
new g_admin_transform_into[33];
new g_admin_menu_info[33];
new g_admin_menu[33];

new cvar_human_health, cvar_human_speed, cvar_human_gravity,  cvar_human_clipcost,  cvar_human_unlimited_ammo;
new cvar_weapons_display, cvar_weapon_alt_names, cvar_weapons_rifles, cvar_weapons_smgs, cvar_weapons_shotguns, cvar_weapons_snipers, cvar_weapons_autosnipers;
new cvar_superzombie_health, cvar_superzombie_speed, cvar_superzombie_gravity, cvar_superzombie_chance, cvar_superzombie_enabled, cvar_superzombie_infect, cvar_firstzombie_health, cvar_silent_firstzombie, cvar_zombie_brainhealth, cvar_zombie_armor, cvar_zombie_health, cvar_zombie_speed, cvar_zombie_gravity;
new cvar_min_players, cvar_delay, cvar_thunderclap, cvar_lights, cvar_custom_win_sounds, cvar_block_hud_messages, cvar_he_hitself, cvar_multi_enabled, cvar_multi_min_players, cvar_multi_chance;
new cvar_nvgsize, cvar_nvgcustom, cvar_nvgcolor[3];

enum _:WeaponItem {WeaponName[32], CvarSuffix[32] }
static const g_primary_weapons_list[][WeaponItem] = {{"MENU_WEAPON_M3", "m3"}, {"MENU_WEAPON_XM1014", "xm1014"}, {"MENU_WEAPON_TMP", "tmp"}, {"MENU_WEAPON_MAC10", "mac10"}, {"MENU_WEAPON_MP5NAVY", "mp5navy"}, {"MENU_WEAPON_P90", "p90"}, {"MENU_WEAPON_UMP45", "ump45"}, {"MENU_WEAPON_FAMAS", "famas"}, {"MENU_WEAPON_GALIL", "galil"}, {"MENU_WEAPON_AK47", "ak47"}, {"MENU_WEAPON_M4A1", "m4a1"}, {"MENU_WEAPON_SG552", "sg552"}, {"MENU_WEAPON_AUG", "aug"}, {"MENU_WEAPON_SCOUT", "scout"}, {"MENU_WEAPON_AWP", "awp"}, {"MENU_WEAPON_SG550", "sg550"}, {"MENU_WEAPON_G3SG1", "g3sg1"}};
new g_weapon_cvar_ptrs[sizeof(g_primary_weapons_list)];

new const g_transform_actions[] = {0, ADMIN_TRANSFORM_HUMAN, ADMIN_TRANSFORM_ZOMBIE, ADMIN_TRANSFORM_SUPERZOMBIE};
new const g_settings_actions[] = {0, 0, 0, 0, ADMIN_MENU_HUMAN_SETTINGS, ADMIN_MENU_ZOMBIE_SETTINGS, ADMIN_MENU_GLOBAL_SETTINGS, ADMIN_MENU_WEAPON_RESTRICTIONS, ADMIN_MENU_NIGHTVISION_SETTINGS};

public plugin_init()
{
	// Register Plugin
	register_plugin("[ZM] Zombie Mod Infection Admin Menu", VERSION, "ProgramViewer");
	
	// Check if Zombie Mod Infection is active
	zmod_is_active() ? plugin_init2() : pause("ad");
}

public plugin_init2()
{
	// Register Dictionary
	register_dictionary("zombie_mod_infection_admin_menu.txt");
	
	// Command
	register_clcmd("say /zmadminmenu", "clcmd_adminmenu");
	
	// Get Max Players
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
	// Cvars Global
	// -------------------------
	cvar_min_players = get_cvar_pointer("zmod_min_players");
	check_cvar(cvar_min_players, "zmod_min_players", loaded, total);
	cvar_delay = get_cvar_pointer("zmod_delay");
	check_cvar(cvar_delay, "zmod_delay", loaded, total);
	cvar_lights = get_cvar_pointer("zmod_lights");
	check_cvar(cvar_lights, "zmod_lights", loaded, total);
	cvar_thunderclap = get_cvar_pointer("zmod_thunderclap");
	check_cvar(cvar_thunderclap, "zmod_thunderclap", loaded, total);
	cvar_custom_win_sounds = get_cvar_pointer("zmod_custom_win_sounds");
	check_cvar(cvar_custom_win_sounds, "zmod_custom_win_sounds", loaded, total);
	cvar_block_hud_messages = get_cvar_pointer("zmod_block_hud_messages");
	check_cvar(cvar_block_hud_messages, "zmod_block_hud_messages", loaded, total);
	cvar_he_hitself = get_cvar_pointer("zmod_he_hitself");
	check_cvar(cvar_he_hitself, "zmod_he_hitself", loaded, total);
	
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
	cvar_silent_firstzombie = get_cvar_pointer("zmod_silent_firstzombie");
	check_cvar(cvar_silent_firstzombie, "zmod_silent_firstzombie", loaded, total);
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
	cvar_superzombie_infect = get_cvar_pointer("zmod_superzombie_infect");
	check_cvar(cvar_superzombie_infect, "zmod_superzombie_infect", loaded, total);
	cvar_multi_enabled = get_cvar_pointer("zmod_multi_enabled");
	check_cvar(cvar_multi_enabled, "zmod_multi_enabled", loaded, total);
	cvar_multi_min_players = get_cvar_pointer("zmod_multi_min_players");
	check_cvar(cvar_multi_min_players, "zmod_multi_min_players", loaded, total);
	cvar_multi_chance = get_cvar_pointer("zmod_multi_chance");
	check_cvar(cvar_multi_chance, "zmod_multi_chance", loaded, total);
    
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
	// Cvars Weapons
	// -------------------------
	cvar_weapons_display = get_cvar_pointer("zmod_weapons_display");
	check_cvar(cvar_weapons_display, "zmod_weapons_display", loaded, total);
	cvar_weapon_alt_names = get_cvar_pointer("zmod_weapon_alt_names");
	check_cvar(cvar_weapon_alt_names, "zmod_weapon_alt_names", loaded, total);
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
	server_print("[ZM Admin Menu] Loaded CVAR pointers: %d / %d", loaded, total);
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
		server_print("[ZM Admin Menu] CVAR %s NOT FOUND", name);
	}	
}

public client_putinserver(id)
{
	g_admin_transform_into[id] = 0;
	g_admin_menu_info[id] = 0;
	g_admin_menu[id] = 0;
	get_user_name(id, g_playername[id], charsmax(g_playername[]));
}

public client_disconnected(id)
{
	g_admin_transform_into[id] = 0;
	g_admin_menu_info[id] = 0;
	g_admin_menu[id] = 0;
	remove_task(id);
}

public client_infochanged(id)
{
	get_user_name(id, g_playername[id], charsmax(g_playername[]));
}

public clcmd_adminmenu(id)
{
	if(!(get_user_flags(id) & ADMIN_RCON))
	{
		client_print_color(id, print_team_default, "^4[ZM] ^1%L", LANG_PLAYER, "TXT_NO_ACCESS");
		return PLUGIN_HANDLED;
	}
	
	zm_admin_menu(id);
	return PLUGIN_HANDLED;
}

public zm_admin_menu(id)
{
	if(!is_user_connected(id))
	{
		return;
	}
	
	new data[2], menuid = menu_create(fmt("%L\r", id, "MENU_ADMIN_TITLE"), "menu_admin_handler");
	static const ADMIN_MENU_ITEMS[][] = {{1, "MENU_ADMIN_TRANSFORM_HUMAN"}, {2, "MENU_ADMIN_TRANSFORM_ZOMBIE"}, {3, "MENU_ADMIN_TRANSFORM_SUPERZOMBIE"}, {4, "MENU_ADMIN_SETTINGS_HUMAN"}, {5, "MENU_ADMIN_SETTINGS_ZOMBIE"}, {6, "MENU_ADMIN_SETTINGS_GLOBAL"}, {7, "MENU_ADMIN_WEAPON_RESTRICTIONS"}, {8, "MENU_ADMIN_SETTINGS_NIGHTVISION"}};
	
	for(new i = 0; i < sizeof(ADMIN_MENU_ITEMS); i++)
	{
		data[0] = ADMIN_MENU_ITEMS[i][0];
		menu_additem(menuid, fmt("%L", id, ADMIN_MENU_ITEMS[i][1]), data);
	}
	
	set_menu_nav(menuid, id);
	g_admin_menu[id] = menuid;
	menu_display(id, menuid, 0);
}

public menu_admin_handler(id, menu, item)
{
	if(!is_user_connected(id))
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}

	if(item == MENU_EXIT)
	{
		client_print_color(id, print_team_default, "^4[ZM]^1 %L", LANG_PLAYER, "TXT_CHANGES_NEXT_ROUND");
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}

	new data[2];
	menu_item_getinfo(menu, item, _, data, charsmax(data));
	new action = data[0];
	
	if(action >= 1 && action <= 3)
	{
		g_admin_transform_into[id] = g_transform_actions[action];
		zm_player_list(id);
	}
	else if(action >= 4 && action <= 8)
	{
		g_admin_menu_info[id] = g_settings_actions[action];
		switch(action)
		{
			case 4: zm_human_settings_menu(id);
			case 5: zm_zombie_settings_menu(id);
			case 6: zm_global_settings_menu(id);
			case 7: zm_weapon_restrictions_menu(id);
			case 8: zm_nvg_settings_menu(id);
		}
	}
	
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

public zm_player_list(id)
{
	if(!is_user_connected(id))
	{
		return;
	}
	
	static const transform_titles[][] = {"", "MENU_TRANSFORM_HUMAN", "MENU_TRANSFORM_ZOMBIE", "MENU_TRANSFORM_SUPERZOMBIE"};
	new menu_title[64];
	formatex(menu_title, charsmax(menu_title), "%L\r", id, transform_titles[g_admin_transform_into[id]]);
	new menuid = menu_create(menu_title, "menu_player_list_handler");
	static player_name[64], player_id[2], status[32], name_fixed[32], CsTeams:team;
	
	for(new i = 1; i <= g_maxplayers; i++)
	{
		if(!is_user_connected(i) || !is_user_alive(i))
		{
			continue;
		}
		
		team = cs_get_user_team(i);
		if(team == CS_TEAM_SPECTATOR || team == CS_TEAM_UNASSIGNED)
		{
			continue;
		}
		
		formatex(status, charsmax(status), "%s", zmod_get_user_superzombie(i) ? "\r[Super Zombie]" : (zmod_get_user_zombie(i) ? "\r[Zombie]" : "\y[Human]"));
		formatex(name_fixed, charsmax(name_fixed), "%-28s", g_playername[i]);
		formatex(player_name, charsmax(player_name), "%s %s", name_fixed, status);
		
		player_id[0] = i;
		player_id[1] = 0;
		menu_additem(menuid, player_name, player_id);
	}
	
	new page;
	switch(g_admin_transform_into[id])
	{
		case ADMIN_TRANSFORM_HUMAN: page = MENU_PAGE_HUMAN;
		case ADMIN_TRANSFORM_ZOMBIE: page = MENU_PAGE_ZOMBIE;
		case ADMIN_TRANSFORM_SUPERZOMBIE: page = MENU_PAGE_SUPERZOMBIE;
	}
	
	set_menu_nav(menuid, id);
	page = min(page, menu_pages(menuid) - 1);
	set_pdata_int(id, OFFSET_CSMENUCODE, 0);
	
	g_admin_menu[id] = menuid;
	menu_display(id, menuid, page);
}

public menu_player_list_handler(id, menu, item)
{
	if(!is_user_connected(id))
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	
	if(item == MENU_EXIT)
	{
		zm_admin_menu(id);
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	
	static player_id[2], dummy, menudummy, page;
	menu_item_getinfo(menu, item, dummy, player_id, charsmax(player_id), _, _, dummy);
	player_menu_info(id, menudummy, menudummy, page);
	
	switch(g_admin_transform_into[id])
	{
		case ADMIN_TRANSFORM_HUMAN: MENU_PAGE_HUMAN = page;
		case ADMIN_TRANSFORM_ZOMBIE: MENU_PAGE_ZOMBIE = page;
		case ADMIN_TRANSFORM_SUPERZOMBIE: MENU_PAGE_SUPERZOMBIE = page;
	}
	
	new target = player_id[0];
	
	if(!check_transform_condition(id, menu, is_user_connected(target), "TXT_TARGET_NO_CONNECTED"))
	{
		return PLUGIN_HANDLED;
	}
	if(!check_transform_condition(id, menu, is_user_alive(target), "TXT_TARGET_DEAD"))
	{
		return PLUGIN_HANDLED;
	}
	if(!check_transform_condition(id, menu, zmod_has_round_started() == 1, "TXT_SELECTION_IN_PROGRESS"))
	{
		return PLUGIN_HANDLED;
	}
	
	process_transformation(id, target, g_admin_transform_into[id]);
	zm_player_list(id);
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

public zm_human_settings_menu(id)
{
	if(!is_user_connected(id))
	{
		return;
	}
    
	new data[2], menuid = menu_create(fmt("%L\r", id, "MENU_HUMAN_SETTINGS_TITLE"), "menu_admin_settings_handler");
	data[0] = 0; 
    
	menu_add_int(menuid, id, "MENU_HUMAN_HEALTH", cvar_human_health, data);
	menu_add_float(menuid, id, "MENU_HUMAN_SPEED", cvar_human_speed, data);
	menu_add_float(menuid, id, "MENU_HUMAN_GRAVITY", cvar_human_gravity, data);
	menu_add_int(menuid, id, "MENU_HUMAN_CLIPCOST", cvar_human_clipcost, data);
	menu_add_cycle_3(menuid, id, "MENU_HUMAN_UNLIMITED_AMMO", cvar_human_unlimited_ammo, data, "MENU_UNLIMITED_AMMO_OFF", "MENU_UNLIMITED_AMMO_AMMO", "MENU_UNLIMITED_AMMO_CLIP");
	menu_add_step_controls(menuid, id, data, 1, 1);
    
	set_menu_nav(menuid, id);
	MENU_PAGE_HUMAN_SETTINGS = min(MENU_PAGE_HUMAN_SETTINGS, menu_pages(menuid) - 1);
	g_admin_menu[id] = menuid;
	menu_display(id, menuid, MENU_PAGE_HUMAN_SETTINGS);
}

public zm_zombie_settings_menu(id)
{
	if(!is_user_connected(id))
	{
		return;
	}
	
	new data[2], menuid = menu_create(fmt("%L\r", id, "MENU_ZOMBIE_SETTINGS_TITLE"), "menu_admin_settings_handler");
	data[0] = 0; 
	
	menu_add_int(menuid, id, "MENU_ZOMBIE_HEALTH", cvar_zombie_health, data);
	menu_add_float(menuid, id, "MENU_ZOMBIE_SPEED", cvar_zombie_speed, data);
	menu_add_float(menuid, id, "MENU_ZOMBIE_GRAVITY", cvar_zombie_gravity, data);
	menu_add_int(menuid, id, "MENU_SUPERZOMBIE_HEALTH", cvar_superzombie_health, data);
	menu_add_float(menuid, id, "MENU_SUPERZOMBIE_SPEED", cvar_superzombie_speed, data);
	menu_add_float(menuid, id, "MENU_SUPERZOMBIE_GRAVITY", cvar_superzombie_gravity, data);
	menu_add_int(menuid, id, "MENU_FIRSTZOMBIE_HEALTH", cvar_firstzombie_health, data);
	menu_add_int(menuid, id, "MENU_ZOMBIE_BRAINHEALTH", cvar_zombie_brainhealth, data);
	menu_add_int(menuid, id, "MENU_SUPERZOMBIE_CHANCE", cvar_superzombie_chance, data)
	menu_add_toggle(menuid, id, "MENU_SUPERZOMBIE_SWITCH", cvar_superzombie_enabled, data);
	menu_add_toggle(menuid, id, "MENU_SUPERZOMBIE_INFECT", cvar_superzombie_infect, data);
	menu_add_float(menuid, id, "MENU_ZOMBIE_ARMOR", cvar_zombie_armor, data);
	menu_add_toggle(menuid, id, "MENU_MULTI_SWITCH", cvar_multi_enabled, data);
	menu_add_int(menuid, id, "MENU_MULTI_MIN_PLAYERS", cvar_multi_min_players, data);
	menu_add_int(menuid, id, "MENU_MULTI_CHANCE", cvar_multi_chance, data);
	menu_add_step_controls(menuid, id, data, 1, 1);
	
	set_menu_nav(menuid, id);
	MENU_PAGE_ZOMBIE_SETTINGS = min(MENU_PAGE_ZOMBIE_SETTINGS, menu_pages(menuid) - 1);
	g_admin_menu[id] = menuid;
	menu_display(id, menuid, MENU_PAGE_ZOMBIE_SETTINGS);
}

public zm_global_settings_menu(id)
{
	if(!is_user_connected(id))
	{
		return;
	}
	
	new data[2], menuid = menu_create(fmt("%L\r", id, "MENU_GLOBAL_SETTINGS_TITLE"), "menu_admin_settings_handler");
	data[0] = 0; 
	
	menu_add_int(menuid, id, "MENU_GLOBAL_DELAY", cvar_delay, data);
	menu_add_int(menuid, id, "MENU_GLOBAL_THUNDERCLAP", cvar_thunderclap, data);
	menu_add_lightning(menuid, id, "MENU_GLOBAL_LIGHTNING", cvar_lights, data);
	menu_add_toggle(menuid, id, "MENU_GLOBAL_CUSTOM_WIN_SOUNDS", cvar_custom_win_sounds, data);
	menu_add_toggle(menuid, id, "MENU_GLOBAL_BLOCK_HUD_MESSAGES", cvar_block_hud_messages, data);
	menu_add_toggle(menuid, id, "MENU_GLOBAL_HE_HITSELF", cvar_he_hitself, data);
	menu_add_step_controls(menuid, id, data, 1, 0);
	
	set_menu_nav(menuid, id);
	MENU_PAGE_GLOBAL_SETTINGS = min(MENU_PAGE_GLOBAL_SETTINGS, menu_pages(menuid) - 1);
	g_admin_menu[id] = menuid;
	menu_display(id, menuid, MENU_PAGE_GLOBAL_SETTINGS);
}

public zm_weapon_restrictions_menu(id)
{
	if(!is_user_connected(id))
	{
		return;
	}
	
	new data[2], menuid = menu_create(fmt("%L\r", id, "MENU_WEAPON_RESTRICTIONS_TITLE"), "menu_admin_settings_handler");
	data[0] = 0; 
	
	menu_add_toggle(menuid, id, "MENU_WEAPON_DISPLAY", cvar_weapons_display, data);
	menu_add_toggle(menuid, id, "MENU_WEAPON_SHOTGUNS", cvar_weapons_shotguns, data);
	menu_add_toggle(menuid, id, "MENU_WEAPON_SMGS", cvar_weapons_smgs, data);
	menu_add_toggle(menuid, id, "MENU_WEAPON_RIFLES", cvar_weapons_rifles, data);
	menu_add_toggle(menuid, id, "MENU_WEAPON_SNIPERS", cvar_weapons_snipers, data);
	menu_add_toggle(menuid, id, "MENU_WEAPON_AUTOSNIPERS", cvar_weapons_autosnipers, data);
	
	for(new i = 0; i < sizeof(g_primary_weapons_list); i++)
	{
		menu_add_toggle(menuid, id, g_primary_weapons_list[i][WeaponName], g_weapon_cvar_ptrs[i], data);
	}
	
	set_menu_nav(menuid, id);
	MENU_PAGE_WEAPON_RESTRICTIONS = min(MENU_PAGE_WEAPON_RESTRICTIONS, menu_pages(menuid) - 1);
	g_admin_menu[id] = menuid;
	menu_display(id, menuid, MENU_PAGE_WEAPON_RESTRICTIONS);
}

public zm_nvg_settings_menu(id)
{
	if(!is_user_connected(id))
	{
		return;
	}
	
	new data[2], menuid = menu_create(fmt("%L\r", id, "MENU_NIGHTVISION_SETTINGS_TITLE"), "menu_admin_settings_handler");
	data[0] = 0; 
	
	menu_add_toggle(menuid, id, "MENU_NIGHTVISION_CUSTOM", cvar_nvgcustom, data); 
	menu_add_int(menuid, id, "MENU_NIGHTVISION_SIZE", cvar_nvgsize, data);         
	menu_add_int(menuid, id, "MENU_NIGHTVISION_COLOR_R", cvar_nvgcolor[0], data); 
	menu_add_int(menuid, id, "MENU_NIGHTVISION_COLOR_G", cvar_nvgcolor[1], data); 
	menu_add_int(menuid, id, "MENU_NIGHTVISION_COLOR_B", cvar_nvgcolor[2], data); 
	menu_add_step_controls(menuid, id, data, 1, 0); 
	
	menu_setprop(menuid, MPROP_EXITNAME, fmt("%L", id, "MENU_EXIT"));
	set_pdata_int(id, OFFSET_CSMENUCODE, 0);
	g_admin_menu[id] = menuid;
	menu_display(id, menuid, 0);
}

public menu_admin_settings_handler(id, menu, item)
{
	if(!is_user_connected(id) || item == MENU_EXIT)
	{
		zm_admin_menu(id);
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	
	new data[2];
	menu_item_getinfo(menu, item, _, data, charsmax(data));
	new key = data[0];
	
	switch(g_admin_menu_info[id])
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
	static dummy;
	player_menu_info(id, dummy, dummy, MENU_PAGE_HUMAN_SETTINGS);
	
	switch(key)
	{
		case 1: process_int(id, cvar_human_health, "MENU_HUMAN_HEALTH_SET", 1);
		case 2: process_float(id, cvar_human_speed, "MENU_HUMAN_SPEED_SET", 0.1);
		case 3: process_float(id, cvar_human_gravity, "MENU_HUMAN_GRAVITY_SET", 0.1);
		case 4: process_money(id, cvar_human_clipcost, "MENU_HUMAN_CLIPCOST_SET", 0);
		case 5: cycle_unlimited_ammo(id);
		case 6: process_step_int(id);
		case 7: process_step_float(id);
		case 8: toggle_step_mode(id);
	}
	
	zm_human_settings_menu(id);
}

handle_zombie_settings(id, key)
{
	static dummy;
	player_menu_info(id, dummy, dummy, MENU_PAGE_ZOMBIE_SETTINGS);
	
	switch(key)
	{
		case 1: process_int(id, cvar_zombie_health, "MENU_ZOMBIE_HEALTH_SET", 1);
		case 2: process_float(id, cvar_zombie_speed, "MENU_ZOMBIE_SPEED_SET", 0.1);
		case 3: process_float(id, cvar_zombie_gravity, "MENU_ZOMBIE_GRAVITY_SET", 0.1);
		case 4: process_int(id, cvar_superzombie_health, "MENU_SUPERZOMBIE_HEALTH_SET", 1);
		case 5: process_float(id, cvar_superzombie_speed, "MENU_SUPERZOMBIE_SPEED_SET", 0.1);
		case 6: process_float(id, cvar_superzombie_gravity, "MENU_SUPERZOMBIE_GRAVITY_SET", 0.1);
		case 7: process_int(id, cvar_firstzombie_health, "MENU_FIRSTZOMBIE_HEALTH_SET", 1);
		case 8: process_int(id, cvar_zombie_brainhealth, "MENU_ZOMBIE_BRAINHEALTH_SET", 0);
		case 9: process_chance(id, cvar_superzombie_chance, "MENU_SUPERZOMBIE_CHANCE_SET");
		case 10: toggle_item(cvar_superzombie_enabled, "MENU_SUPERZOMBIE_ENABLED_SET", id);
		case 11: toggle_item(cvar_superzombie_infect, "MENU_SUPERZOMBIE_INFECT_SET", id);
		case 12: process_float(id, cvar_zombie_armor, "MENU_ZOMBIE_ARMOR_SET", 0.1);
		case 13: toggle_item(cvar_multi_enabled, "MENU_MULTI_SWITCH_SET", id);
		case 14: process_int(id, cvar_multi_min_players, "MENU_MULTI_MIN_PLAYERS_SET", 1);
		case 15: process_chance(id, cvar_multi_chance, "MENU_MULTI_CHANCE_SET");
		case 16: process_step_int(id);
		case 17: process_step_float(id);
		case 18: toggle_step_mode(id);
	}
	zm_zombie_settings_menu(id);
}

handle_global_settings(id, key)
{
	static dummy;
	player_menu_info(id, dummy, dummy, MENU_PAGE_GLOBAL_SETTINGS);
	
	switch(key)
	{
		case 1: process_int(id, cvar_delay, "MENU_GLOBAL_DELAY_SET", 1);
		case 2: process_int(id, cvar_thunderclap, "MENU_GLOBAL_THUNDERCLAP_SET", 1);
		case 3: cycle_lightning(id);
		case 4: toggle_item(cvar_custom_win_sounds, "MENU_GLOBAL_CUSTOM_WIN_SOUNDS_SET", id);
		case 5: toggle_item(cvar_block_hud_messages, "MENU_GLOBAL_BLOCK_HUD_MESSAGES_SET", id);
		case 6: toggle_item(cvar_he_hitself, "MENU_GLOBAL_HE_HITSELF_SET", id);
		case 7: process_step_int(id);
		case 8: toggle_step_mode(id);
	}
	
	zm_global_settings_menu(id);
}

handle_weapon_restrictions(id, key)
{
	static dummy;
	player_menu_info(id, dummy, dummy, MENU_PAGE_WEAPON_RESTRICTIONS);
	new total_categories = 6, total_weapons = sizeof(g_primary_weapons_list);
	
	if(key >= 1 && key <= total_categories)
	{
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
	else if(key > total_categories && key <= total_categories + total_weapons)
	{
		new index = key - total_categories - 1; 
		new current = get_pcvar_num(g_weapon_cvar_ptrs[index]);
		set_pcvar_num(g_weapon_cvar_ptrs[index], current ? 0 : 1);
		
		new status[32], weapon_name[32];
		formatex(status, charsmax(status), "%L", id, current ? "TXT_DISABLED" : "TXT_ENABLED");
		formatex(weapon_name, charsmax(weapon_name), "%L", id, g_primary_weapons_list[index][WeaponName]);
		client_print_color(id, print_team_default, "^4[ZM]^1 %L", id, "MENU_WEAPON_INDIVIDUAL_CHANGED", weapon_name, status);
	}
	zm_weapon_restrictions_menu(id);
}

handle_nvg_settings(id, key)
{
	switch(key)
	{
		case 1: toggle_item(cvar_nvgcustom, "MENU_NIGHTVISION_CUSTOM_SET", id);
		case 2: process_int(id, cvar_nvgsize, "MENU_NIGHTVISION_SIZE_CHANGE", 1);
		case 3: process_int(id, cvar_nvgcolor[0], "MENU_NIGHTVISION_COLOR_R_CHANGE", 0);
		case 4: process_int(id, cvar_nvgcolor[1], "MENU_NIGHTVISION_COLOR_G_CHANGE", 0);
		case 5: process_int(id, cvar_nvgcolor[2], "MENU_NIGHTVISION_COLOR_B_CHANGE", 0);
		case 6: process_step_int(id);
		case 7: toggle_step_mode(id);
	}
	zm_nvg_settings_menu(id);
}

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

cycle_lightning(id)
{
	static const lightning_flags[] = "abcdefghijklmnopqrstuvwxyz";
	static const num_flags = sizeof lightning_flags - 1;
	new szCurrent[2], iNext;
	get_pcvar_string(cvar_lights, szCurrent, charsmax(szCurrent));
	
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
		set_pcvar_string(cvar_lights, "0");
		client_print_color(id, print_team_default, "^4[ZM]^1 %L", id, "MENU_GLOBAL_LIGHTNING_SET_DISABLED");
	}
	else
	{
		new szNew[2];
		szNew[0] = lightning_flags[iNext];
		szNew[1] = EOS;
		set_pcvar_string(cvar_lights, szNew);
		client_print_color(id, print_team_default, "^4[ZM]^1 %L ^3'%s'", id, "MENU_GLOBAL_LIGHTNING_SET", szNew);
	}
}

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

update_step_value_int(id)
{
	g_int_step_value += (g_step_increase[id] ? 1 : -1);
	
	if(g_int_step_value < 1)
	{
		g_int_step_value = 1;
	}
	
	return g_int_step_value;
}

Float:update_step_value_float(id)
{
	g_float_step_value += (g_step_increase[id] ? 0.01 : -0.01);
	
	if(g_float_step_value < 0.01)
	{
		g_float_step_value = 0.01;
	}
	
	return g_float_step_value;
}

toggle_step_mode(id)
{
	g_step_increase[id] = !g_step_increase[id];
	new mode[32];
	formatex(mode, charsmax(mode), "%L", id, g_step_increase[id] ? "MODE_INCREASE" : "MODE_DECREASE");
	client_print_color(id, print_team_default, "^4[ZM]^1 %L: ^3%s", LANG_PLAYER, "MENU_STEP_MODE", mode);
}

toggle_item(pcvar, const langkey[], id)
{
	new status[32], val = get_pcvar_num(pcvar) ? 0 : 1;
	set_pcvar_num(pcvar, val);
	formatex(status, charsmax(status), "%L", id, val ? "TXT_ENABLED" : "TXT_DISABLED");
	client_print_color(id, print_team_default, "^4[ZM]^1 %L: ^3%s", LANG_PLAYER, langkey, status);
}

stock set_menu_nav(menuid, id)
{
	menu_setprop(menuid, MPROP_BACKNAME, fmt("%L", id, "MENU_BACK"));
	menu_setprop(menuid, MPROP_NEXTNAME, fmt("%L", id, "MENU_NEXT"));
	menu_setprop(menuid, MPROP_EXITNAME, fmt("%L", id, "MENU_EXIT"));
	set_pdata_int(id, OFFSET_CSMENUCODE, 0);
}

stock bool:check_transform_condition(id, menu, condition, const langkey[])
{
	if(!condition)
	{
		client_print_color(id, print_team_default, "^4[ZM] ^1%L", LANG_PLAYER, langkey);
		zm_player_list(id);
		menu_destroy(menu);
		return false;
	}
	return true;
}

stock menu_add_int(menuid, id, const langkey[], pcvar, data[])
{
	data[0]++;
	menu_additem(menuid, fmt("%L: \y%d", id, langkey, get_pcvar_num(pcvar)), data);
}

stock menu_add_float(menuid, id, const langkey[], pcvar, data[])
{
	data[0]++;
	menu_additem(menuid, fmt("%L: \y%.2f", id, langkey, get_pcvar_float(pcvar)), data);
}

stock menu_add_toggle(menuid, id, const langkey[], pcvar, data[])
{
	data[0]++;
	new status[32];
	formatex(status, charsmax(status), "%L", id, get_pcvar_num(pcvar) ? "TOGGLE_ENABLED" : "TOGGLE_DISABLED");
	menu_additem(menuid, fmt("%L: %s", id, langkey, status), data);
}

stock menu_add_cycle_3(menuid, id, const langkey[], pcvar, data[], const lang_off[], const lang_on1[], const lang_on2[])
{
	data[0]++;
	new status[32];
	
	switch(get_pcvar_num(pcvar))
	{
		case 0: formatex(status, charsmax(status), "%L", id, lang_off);
		case 1: formatex(status, charsmax(status), "%L", id, lang_on1);
		case 2: formatex(status, charsmax(status), "%L", id, lang_on2);
	}
	
	menu_additem(menuid, fmt("%L: %s", id, langkey, status), data);
}

stock menu_add_lightning(menuid, id, const langkey[], pcvar, data[])
{
	data[0]++;
	new status[32], lightning[2];
	
	get_pcvar_string(pcvar, lightning, charsmax(lightning));
	
	if(!lightning[0] || lightning[0] == '0')
	{
		formatex(status, charsmax(status), "%L", id, "TOGGLE_DISABLED");
	}
	else
	{
		formatex(status, charsmax(status), "\y%c", lightning[0]);
	}
	
	menu_additem(menuid, fmt("%L: %s", id, langkey, status), data);
}

stock menu_add_step_controls(menuid, id, data[], should_int, should_float)
{
	new status[32];
	
	if(should_int)
	{
		data[0]++;
		menu_additem(menuid, fmt("%L: \y%d", id, "MENU_CHANGE_INT", g_int_step_value), data);
	}
	
	if(should_float)
	{
		data[0]++;
		menu_additem(menuid, fmt("%L: \y%.2f", id, "MENU_CHANGE_FLOAT", g_float_step_value), data);
	}
	
	data[0]++;
	formatex(status, charsmax(status), "%L", id, g_step_increase[id] ? "MODE_INCREASE" : "MODE_DECREASE");
	menu_additem(menuid, fmt("%L: \y%s", id, "MENU_SWITCH_MODE", status), data);
}

stock process_int(id, pcvar, const langkey[], min_val = 1)
{
	new current = update_pcvar_int(id, pcvar, min_val);
	print_int_setting(id, langkey, current);
}

stock process_money(id, pcvar, const langkey[], min_val = 1)
{
	new current = update_pcvar_int(id, pcvar, min_val);
	print_money_setting(id, langkey, current);
}

stock process_float(id, pcvar, const langkey[], Float:min_val = 0.1)
{
	new Float:current = update_pcvar_float(id, pcvar, min_val);
	print_float_setting(id, langkey, current);
}

stock process_step_int(id)
{
	update_step_value_int(id);
	print_int_setting(id, "MENU_CHANGE_INT", g_int_step_value);
}

stock process_step_float(id)
{
	update_step_value_float(id);
	print_float_setting(id, "MENU_CHANGE_FLOAT", g_float_step_value);
}

stock process_chance(id, pcvar, const langkey[])
{
	new current = get_pcvar_num(pcvar);
	current += (g_step_increase[id] ? 1 : -1);
	current = clamp(current, 1, 100);
	set_pcvar_num(pcvar, current);
	new display_chance = 101 - current;
	client_print_color(id, print_team_default, "^4[ZM]^1 %L: ^3%d%%", LANG_PLAYER, langkey, display_chance);
}

stock process_transformation(id, target, transform_type)
{
	new is_already, count_check, already_key[32], cant_force_key[32], success_key[32], admin_success_key[32], bool:success = false;
	
	switch(transform_type)
	{
		case ADMIN_TRANSFORM_HUMAN:
		{
			is_already = zmod_get_user_human(target);
			count_check = zmod_get_zombie_count();
			already_key = "TXT_ALREADY_HUMAN";
			cant_force_key = "TXT_CANT_FORCE_HUMAN";
			success_key = "TXT_TRANSFORMED_HUMAN";
			admin_success_key = "TXT_ADMIN_TRANSFORM_HUMAN";
			if(!is_already && count_check > 1)
			{
				success = (zmod_force_transform_human(target) == 1);
			}
		}
		case ADMIN_TRANSFORM_ZOMBIE:
		{
			is_already = zmod_get_user_zombie(target);
			count_check = zmod_get_human_count();
			already_key = "TXT_ALREADY_ZOMBIE";
			cant_force_key = "TXT_CANT_FORCE_ZOMBIE";
			success_key = "TXT_TRANSFORMED_ZOMBIE";
			admin_success_key = "TXT_ADMIN_TRANSFORM_ZOMBIE";
			if(!is_already && count_check > 1)
			{
				success = (zmod_force_transform_zombie(target) == 1);
			}
		}
		case ADMIN_TRANSFORM_SUPERZOMBIE:
		{
			is_already = zmod_get_user_superzombie(target);
			count_check = zmod_get_human_count();
			already_key = "TXT_ALREADY_SUPERZOMBIE";
			cant_force_key = "TXT_CANT_FORCE_SUPERZOMBIE";
			success_key = "TXT_TRANSFORMED_SUPERZOMBIE";
			admin_success_key = "TXT_ADMIN_TRANSFORM_SUPERZOMBIE";
			if(!is_already && count_check > 1)
			{
				success = (zmod_force_transform_super_zombie(target) == 1);
			}
		}
	}

	if(is_already)
	{
		client_print_color(id, print_team_default, "^4[ZM] ^1%L", LANG_PLAYER, already_key);
	}
	else if(count_check <= 1)
	{
		client_print_color(id, print_team_default, "^4[ZM] ^1%L", LANG_PLAYER, cant_force_key);
	}
	else if(success)
	{
		client_print_color(id, print_team_default, "^4[ZM] ^1%L", LANG_PLAYER, success_key, g_playername[target]);
		client_print_color(0, print_team_default, "^4[ZM] ^1%L", LANG_PLAYER, admin_success_key, g_playername[id], g_playername[target]);
	}
	else
	{
		client_print_color(id, print_team_default, "^4[ZM] ^1%L", LANG_PLAYER, "TXT_INVALID_ARGUMENT");
	}
}
