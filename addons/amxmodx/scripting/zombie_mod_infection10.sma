/*=========================================================================================*/
/*-----------------------------------------------------------------------------------------*/
/*::::::::::::::::::::::::::::::[ Zombie Mod Infection ]:::::::::::::::::::::::::::::::::::*/
/*-----------------------------------------------------------------------------------------*/
/*------------------------------- [ by ProgramViewer ] ------------------------------------*/
/*=========================================================================================*/


/*
*|   [ Project Description ]
*|
*|   Zombie Mod Infection is a gameplay modification for Counter-Strike 1.6
*|   that transforms the classic team-based shooter into a zombies vs humans survival mode.
*|
*|   At the start of each round, one player becomes the first zombie,
*|   while the rest are humans. The zombie must infect the humans
*|   by attacking them, turning them into zombies as well.
*|
*|   Humans, with limited weapons and ammo must either eliminate all zombies 
*|   or survive until the end of the round to try again.
*/

/*
*|   [ License Info ]
*|
*|   This program is free software: you can redistribute it and/or modify it 
*|   under the terms of the GNU General Public License as published by the Free Software Foundation, 
*|   either version 3 of the License, or (at your option) any later version.
*|
*|   This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; 
*|   without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
*|   See the GNU General Public License for more details.
*|  
*|   You should have received a copy of the GNU General Public License along with this program. 
*|   If not, see <http://www.gnu.org/licenses/>.
*|  
*|   Additionally, as a special exception, the author grants permission to link 
*|   the code of this program with the Half-Life Game Engine ("HL Engine") and 
*|   Modified Game Libraries ("MODs") developed by Valve, L.L.C ("Valve"). 
*|   You must comply with the GNU General Public License in all respects for all 
*|   of the code used other than the HL Engine and MODs from Valve. If you modify this file, 
*|   you may extend this exception to your version of the file, but you are not obligated 
*|   to do so. If you do not wish to do so, delete this exception statement from your version.
*/

/*
*|   [ Changelog ]
*|
*|   May 2026 - v1.0 - First Release
*|
*/

/*========================================================*\
||::::::::::::::::::::::::::::::::::::::::::::::::::::::::||
||------------------[ Customization ]---------------------||
||::::::::::::::::::::::::::::::::::::::::::::::::::::::::||
\*========================================================*/

// You can change these to your preferred models and sounds! 
// Make sure you don't mistype anything including the file path
// For player models the path is already built for precache, so you just need to write the model name only
// For knife models the path is already built for precache, so you just need to write the model name only

// Zombie chant time delay
#define ZOMBIE_CHANT_DELAY 40.0

// Players count hud display delay
#define PLAYER_COUNT_DELAY 90.0

// Zombie custom win sounds
new zombie_win[][] = {"ambience/the_horror1.wav","ambience/the_horror3.wav","ambience/the_horror4.wav"};

// Human custom win sounds
new humans_win[][] = {"events/task_complete.wav"};

// Round draw sound
new rounddraw[][] = {"zombie_mod/draw.wav"}; 

// Zombie death sounds
new zombie_death[][] = {"zombie_mod/zombie_die1.wav", "zombie_mod/zombie_die2.wav", "zombie_mod/zombie_die3.wav","zombie_mod/zombie_die4.wav", "zombie_mod/zombie_die5.wav"}; 

// Zombie chant sounds
new zombie_chants[][] = {"zombie_mod/zombie_speech_1.wav", "zombie_mod/zombie_speech_2.wav", "zombie_mod/zombie_speech_3.wav","zombie_mod/zombie_speech_4.wav", "zombie_mod/zombie_speech_5.wav"}; 

// Zombie infection sounds
new zombie_infect[][] = {"zombie_mod/zombie_infec1.wav", "zombie_mod/zombie_infec2.wav", "zombie_mod/zombie_infec3.wav","zombie_mod/zombie_infec4.wav", "zombie_mod/zombie_infec5.wav", "scientist/c1a0_sci_catscream.wav","scientist/scream01.wav"}; 

// Zombie pain sounds
new zombie_pain[][] = {"zombie_mod/zombie_pain1.wav", "zombie_mod/zombie_pain2.wav", "zombie_mod/zombie_pain3.wav","zombie_mod/zombie_pain4.wav", "zombie_mod/zombie_pain5.wav", "zombie_mod/zombie_pain6.wav","zombie_mod/zombie_pain7.wav", "zombie_mod/zombie_pain8.wav", "zombie_mod/zombie_pain9.wav","zombie_mod/zombie_pain10.wav", "zombie_mod/zombie_pain11.wav"};

// Last human chant sound
new const lasthumanchant[] = "zombie_mod/zombie_speech_last_human.wav"; 

// Last zombie chant sound
new const lastzombiechant[] = "zombie_mod/zombie_speech_last_zombie.wav"; 

// Super zombie appearance sound
new const superappears[] = "ambience/the_horror2.wav"; 

// Zombie player models (selected randomly if multiple are added)
new const ZombieModel[][] = {"zm_inf_zombie"}; 

// Zombie knife model
new const ZombieKnife[] = "models/zombie_mod/v_zombie_knife.mdl"; 

// Super zombie player models 
new const SuperModel[][] = {"zm_inf_zombie"}; 

// Super zombie knife 
new const SuperKnife[] = "models/v_crowbar.mdl";

// Human player models (randomly selected on spawn)
new const HumanModel[][] = {"urban", "gign", "sas", "gsg9", "terror", "guerilla", "arctic", "leet"};

// Human knife model
new const HumanKnife[] = "models/zombie_mod/v_human_knife.mdl"; 

// ============================================================================
// === Customization ends here! ===
// === Anything below this line: modify at your own risk! ===
// ============================================================================

/*========================================================*\
||::::::::::::::::::::::::::::::::::::::::::::::::::::::::||
||---------------------[ Includes ]-----------------------||
||::::::::::::::::::::::::::::::::::::::::::::::::::::::::||
\*========================================================*/

#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <fun>
#include <cs_teams_api>
#include <cs_ham_bots_api>
#include <cs_weap_models_api>

/*========================================================*\
||::::::::::::::::::::::::::::::::::::::::::::::::::::::::||
||--------[ Constants and Definitions and Vars ]----------||
||::::::::::::::::::::::::::::::::::::::::::::::::::::::::||
\*========================================================*/

#define VERSION "1.0"

// Damage and effect flags
const DMG_HEGRENADE = (1<<24); // Damage caused by HE grenades
const OFFSET_CSMENUCODE = 205; // Offset for CS menu code
const KEYSMENU = MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4|MENU_KEY_5|MENU_KEY_6|MENU_KEY_7|MENU_KEY_8|MENU_KEY_9|MENU_KEY_0; // Menu key flags
const ADDITIONAL_AMMO = EV_INT_iuser1; // Additional ammo offset in player entity

// Macros for random numbers and task IDs
#define TASK_MAKEZOMBIE 1246 // Task ID for making a player a zombie
#define TASK_HEALTHHUD 3840 // Task ID for health hud

//new g_menu_data[33][8]; // Data for menus
//#define MENU_PAGE_MAIN g_menu_data[id][0] // Zombie mod infection menu pages

// Bit Helpers
#define BIT_SET(%1,%2) (%1 |= (1<<(%2 - 1)))
#define BIT_CLEAR(%1,%2) (%1 &= ~(1<<(%2 - 1)))
#define BIT_CHECK(%1,%2) (%1 & (1<<(%2 - 1)))
#define BIT_TOGGLE(%1,%2) (%1 ^= (1<<(%2 - 1)))

// Macro for null weapons
#define is_null_weapon(%1) (%1 == CSW_KNIFE || %1 == CSW_FLASHBANG || %1 == CSW_HEGRENADE || %1 == CSW_SMOKEGRENADE || %1 == CSW_C4)

// Defined structure for weapons
enum _:WeaponDataStruct {WeaponID, MaxBPAmmo, MaxClip, AmmoID, AmmoType[16], EntityName[32], WeaponName[32], AltName[32]}

// Ammo IDs for weapons
new const g_ammo_ids[] = { -1, 9, -1, 2, 12, 5, 14, 6, 4, 13, 10, 7, 6, 4, 4, 4, 6, 10, 1, 10, 3, 5, 4, 10, 2, 11, 8, 4, 2, -1, 7 }

// Primary weapon data
new const g_primary_weapons[][WeaponDataStruct] =
{
	{CSW_M3,/*-----------*/32,/*-----*/8,/*----*/5,/*-----*/"ammo_buckshot",/*-----*/"weapon_m3",/*---------*/"Leone 12 Gauge Super",/*-------------*/"Pump Shotgun"},  
	{CSW_XM1014,/*-------*/32,/*-----*/7,/*----*/5,/*-----*/"ammo_buckshot",/*-----*/"weapon_xm1014",/*-----*/"Leone YG1265 Auto Shotgun",/*--------*/"Auto Shotgun"},
	{CSW_TMP,/*----------*/120,/*----*/30,/*---*/10,/*----*/"ammo_9mm",/*----------*/"weapon_tmp",/*--------*/"Schmidt Machine Pistol",/*-----------*/"TMP"},
	{CSW_MAC10,/*--------*/100,/*----*/30,/*---*/6,/*-----*/"ammo_45acp",/*--------*/"weapon_mac10",/*------*/"Ingram MAC-10",/*--------------------*/"Mac-10"},
	{CSW_MP5NAVY,/*------*/120,/*----*/30,/*---*/10,/*----*/"ammo_9mm",/*----------*/"weapon_mp5navy",/*----*/"KM Sub-Machine Gun",/*---------------*/"MP5 Navy"},
	{CSW_P90,/*----------*/100,/*----*/50,/*---*/7,/*-----*/"ammo_57mm",/*---------*/"weapon_p90",/*--------*/"ES C90",/*---------------------------*/"P90"},
	{CSW_UMP45,/*--------*/100,/*----*/25,/*---*/6,/*-----*/"ammo_45acp",/*--------*/"weapon_ump45",/*------*/"KM UMP45",/*-------------------------*/"UMP45"}, 
	{CSW_FAMAS,/*--------*/90,/*-----*/25,/*---*/4,/*-----*/"ammo_556nato",/*------*/"weapon_famas",/*------*/"Clarion 5.56",/*---------------------*/"Famas"}, 
	{CSW_GALIL,/*--------*/90,/*-----*/35,/*---*/4,/*-----*/"ammo_556nato",/*------*/"weapon_galil",/*------*/"IDF Defender",/*---------------------*/"Galil"},
	{CSW_AK47,/*---------*/90,/*-----*/30,/*---*/2,/*-----*/"ammo_762nato",/*------*/"weapon_ak47",/*-------*/"CV-47",/*----------------------------*/"AK-47"}, 
	{CSW_M4A1,/*---------*/90,/*-----*/30,/*---*/4,/*-----*/"ammo_556nato",/*------*/"weapon_m4a1",/*-------*/"Maverick M4A1 Carbine",/*------------*/"M4A1"},  
	{CSW_SG552,/*--------*/90,/*-----*/30,/*---*/4,/*-----*/"ammo_556nato",/*------*/"weapon_sg552",/*------*/"Krieg 552",/*------------------------*/"SG552"},
	{CSW_AUG,/*----------*/90,/*-----*/30,/*---*/4,/*-----*/"ammo_556nato",/*------*/"weapon_aug",/*--------*/"Bullpup",/*--------------------------*/"Aug"}, 
	{CSW_SCOUT,/*--------*/90,/*-----*/10,/*---*/2,/*-----*/"ammo_762nato",/*------*/"weapon_scout",/*------*/"Schmidt Scout",/*--------------------*/"Scout"},
	{CSW_AWP,/*----------*/30,/*-----*/10,/*---*/1,/*-----*/"ammo_338magnum",/*----*/"weapon_awp",/*--------*/"Magnum Sniper Rifle",/*--------------*/"AWP"}, 
	{CSW_SG550,/*--------*/90,/*-----*/30,/*---*/4,/*-----*/"ammo_556nato",/*------*/"weapon_sg550",/*------*/"Krieg 550 Commando",/*---------------*/"SG550"}, 
	{CSW_G3SG1,/*--------*/90,/*-----*/20,/*---*/2,/*-----*/"ammo_762nato",/*------*/"weapon_g3sg1",/*------*/"D3AU1",/*----------------------------*/"G3SG1"}
};

new g_primary_cvar[sizeof(g_primary_weapons)];
new g_visible_weapons[33][32]; 

// Secondary weapon data
new const g_secondary_weapons[][WeaponDataStruct] =
{
	{CSW_GLOCK18,/*------*/120,/*----*/20,/*--*/10,/*---*/"ammo_9mm",/*------*/"weapon_glock18",/*--------*/"9x19mm Sidearm",/*-------*/"Glock-18"}, 
	{CSW_USP,/*----------*/100,/*----*/12,/*--*/6,/*----*/"ammo_45acp",/*----*/"weapon_usp",/*------------*/"KM .45 Tactical",/*------*/"USP"}, 
	{CSW_P228,/*---------*/52,/*-----*/13,/*--*/9,/*----*/"ammo_357sig",/*---*/"weapon_p228",/*-----------*/"228 Compact",/*----------*/"P228"},
	{CSW_DEAGLE,/*-------*/35,/*-----*/7,/*---*/8,/*----*/"ammo_50ae",/*-----*/"weapon_deagle",/*---------*/"Night Hawk .50C",/*------*/"Desert Eagle"}, 
	{CSW_FIVESEVEN,/*----*/100,/*----*/20,/*--*/7,/*----*/"ammo_57mm",/*-----*/"weapon_fiveseven",/*------*/"Five-Seven",/*-----------*/"Five-Seven"},
	{CSW_ELITE,/*--------*/120,/*----*/30,/*--*/10,/*---*/"ammo_9mm",/*------*/"weapon_elite",/*----------*/".40 Dual Elites",/*------*/"Dual Elites"}
};

// Enum to identify player count types
enum CountType {COUNT_ALIVE = 1, COUNT_ZOMBIES, COUNT_HUMANS, COUNT_NOMINEES}

new bool:g_selected_firstzombie; // Whether the first zombie has been selected
new bool:g_enough_players = true; // Whether there are enough players to start the game
new bool:g_infectionround = false; // Normal infection round
new bool:g_superround = false; // Super zombie round
new bool:g_multiround = false; // Multi infection round
new bool:g_freezetime;
new bool:g_restart_scheduled = false;
new bool:g_zmod_enabled;

new g_maxplayers; // Maximum number of players
new g_newround; // New round state
new g_endround; // End round state
new g_score_zombies; // Zombie team score
new g_score_humans; // Human team score
new g_gamecommencing; // Game commencing state
new g_msg_sync; // Message sync for HUD
new g_msg_winteam; // Winteam message sync for HUD
new g_msg_health; // Health message sync for HUD
new g_zombie_round_kills_count; // Zombie kills in the current round
new g_human_round_kills_count; // Human kills in the current round
new g_MsgScoreAttrib; // Score attribute message
new g_MsgScoreInfo; // Score info message
new g_MsgFlashlight; // Flashlight message
new g_MsgDeathMsg; // Death message

new g_bitConnected; // Whether the player is connected 
new g_bitAlive; // Whether the player is alive 
new g_bitAdmin; // Whether player is an admin
new g_bitBot; // Whether the player is a bot 
new g_bitFirstConnection; // Whether player has joined for first time 
new g_bitZombie; // Whether a player is a zombie (previously g_zombie[33]) 
new g_bitZombieNominee; // Whether a player is nominated to be the first zombie 
new g_bitHuman; // Whether a player is a human (previously g_human[33])
new g_bitFirstZombie; // Whether a player is the first zombie 
new g_bitSuperZombie; // Whether a player is a super zombie 
new g_bitHasGlow; // Whether player has glow (used for super zombie)
new g_bitAutoRepickWeps; // If true, auto repick last saved weapons on respawn 
new g_primary_weapon[33]; // Current equipped primary weapon 
new g_secondary_weapon[33]; // Current equipped secondary weapon 
new g_grenades[33]; // Current equipped grenades 
new g_primary_saved[33]; // Saved primary weapon for auto repick
new g_secondary_saved[33]; // Saved secondary weapon for auto repick
new g_grenades_saved[33]; // Saved grenades for auto repick
new g_menu_offset[33];
new g_menu_count[33];
new g_playername[33][32]; // Player names

// Global arrays for valid models
new g_ValidZombieModels[32][32];
new g_ValidHumanModels[32][32];
new g_ValidSuperModels[32][32];
new g_iValidZombieCount;
new g_iValidHumanCount;
new g_iValidSuperCount; 

new g_fwd_user_cured; // Forward for when a player is cured
new g_fwd_user_infected; // Forward for when a player is infected
new g_fwd_result; // Forward for dummy result
new g_fwd_infection_begin; // Forward for infection round started

new cvar_lightning; // Lightning effect cvar
new cvar_zombie_brainhealth; // Zombie brain health cvar
new cvar_firstzombie_health; // First zombie health cvar
new cvar_zombie_armor; // Zombie armor cvar
new cvar_zombie_health; // Zombie health cvar
new cvar_zombie_speed; // Zombie speed cvar
new cvar_zombie_gravity; // Zombie gravity cvar
new cvar_superzombie_health; // Super zombie health cvar
new cvar_superzombie_speed; // Super zombie speed cvar
new cvar_superzombie_gravity; // Super zombie gravity cvar
new cvar_superzombie_chance; // Super zombie chance cvar
new cvar_superzombie_enabled; // Super zombie enabled cvar
new cvar_multi_min_players; // Multiple infection minimun players cvar
new cvar_multi_chance; // Multiple infection chance cvar
new cvar_human_health; // Human health cvar
new cvar_human_speed; // Human speed cvar
new cvar_human_gravity; // Human gravity cvar
new cvar_human_clipcost; // Human clip magazine cost
new cvar_he_hitself; // Self damage with he grenade
new cvar_delay; // Round start delay cvar
new cvar_gamedescription; // Game description cvar
new cvar_weapons_display; // Weapon display cvar
new cvar_weapons_rifles; // Allowed rifles cvar
new cvar_weapons_smgs; // Allowed SMGs cvar
new cvar_weapons_shotguns; // Allowed shotguns cvar
new cvar_weapons_snipers; // Allowed snipers cvar
new cvar_weapons_autosnipers; // Allowed auto snipers cvar
new cvar_weapon_alt_names; // Switch between normal game weapon names or alternative weapon names
new cvar_custom_win_sounds; // Enable/Disable custom win sounds
new cvar_block_hud_messages; // Enable/Disable round end messages
new cvar_min_players; // Minimum players required to start the infection
new cvar_enabled; // Whether the mod is enabled/disabled

// Cached general cvars
new g_cached_min_players;
new g_cached_delay;
new g_cached_custom_win_sounds;
new g_cached_block_hud_messages;
new g_cached_he_hitself;

// Cached weapon category cvars
new g_cached_weapons_display;
new g_cached_weapon_alt_names
new g_cached_weapons_shotguns;
new g_cached_weapons_smgs;
new g_cached_weapons_rifles;
new g_cached_weapons_snipers;
new g_cached_weapons_autosnipers;

// Cached zombie cvars (floats need special care)
new Float:g_cached_zombie_armor;
new g_cached_zombie_brainhealth;
new g_cached_firstzombie_health;
new g_cached_zombie_health;
new Float:g_cached_zombie_speed;
new Float:g_cached_zombie_gravity;
new g_cached_superzombie_health;
new Float:g_cached_superzombie_speed;
new Float:g_cached_superzombie_gravity;
new g_cached_superzombie_chance;
new g_cached_superzombie_enabled;
new g_cached_multi_chance;
new g_cached_multi_min_players;

// Cached human cvars
new g_cached_human_health;
new Float:g_cached_human_speed;
new Float:g_cached_human_gravity;

new const sound_armorhit[] = "player/bhit_helmet-1.wav"; // Armor hit sound
new const sound_weapon_restricted[] = "events/friend_died.wav"; // Restricted weapon sound
new const sound_default_terwin[] = "radio/terwin.wav"; // Default terrorists win sound
new const sound_default_ctwin[] = "radio/ctwin.wav"; // Default counter-terrorists win sound
new const sound_default_rounddraw[] = "radio/rounddraw.wav"; // Default round draw sound
new const announce_sound[] = "vox/bizwarn.wav";
new const disable_sound[]  = "ambience/3dmstart.wav";

/*========================================================*\
||::::::::::::::::::::::::::::::::::::::::::::::::::::::::||
||-------[ Plugin Init, Precache, Natives and CFG ]-------||
||::::::::::::::::::::::::::::::::::::::::::::::::::::::::||
\*========================================================*/

public plugin_natives()
{
	register_native("zmod_is_active", "native_zmod_is_active", 1);
	register_native("zmod_get_user_zombie", "native_zmod_get_user_zombie", 1);
	register_native("zmod_get_user_human", "native_zmod_get_user_human", 1);
	register_native("zmod_get_user_superzombie", "native_zmod_get_user_superzombie", 1);
	register_native("zmod_get_user_first_zombie", "native_zmod_get_user_first_zombie", 1);
	register_native("zmod_has_round_started", "native_zmod_has_round_started", 1); 
	register_native("zmod_get_human_count", "native_zmod_get_human_count", 1);
	register_native("zmod_get_zombie_count", "native_zmod_get_zombie_count", 1);
	register_native("zmod_is_round_infection", "native_zmod_is_round_infection", 1);
	register_native("zmod_is_round_super", "native_zmod_is_round_super", 1);
	register_native("zmod_is_round_multi", "native_zmod_is_round_multi", 1);
	register_native("zmod_force_transform_human", "native_zmod_force_transform_human", 1);
	register_native("zmod_force_transform_zombie", "native_zmod_force_transform_zombie", 1);
	register_native("zmod_force_transform_super_zombie", "native_zmod_force_transform_super_zombie", 1);
	register_native("zmod_is_weapon_allowed", "native_zmod_is_weapon_allowed", 1);
	register_native("zmod_assign_primary_weapon", "native_zmod_assign_primary_weapon", 1);
	register_native("zmod_assign_secondary_weapon", "native_zmod_assign_secondary_weapon", 1);
	register_native("zmod_assign_grenades", "native_zmod_assign_grenades", 1);
}

public plugin_precache()
{
	// Register Plugin
	register_plugin("[ZM] Zombie Mod Infection", VERSION, "ProgramViewer");
	
	// Register Dictionary
	register_dictionary("zombie_mod_infection.txt");
	
	// Cmd
	register_clcmd("say /zmodswitch", "clcmd_switch");
	
	// Cvar
	cvar_enabled = register_cvar("zmod_enabled", "1");
	
	// Precache sounds used for trigger
	precache_sound(announce_sound);
	precache_sound(disable_sound);
	precache_sound_array(zombie_win, sizeof(zombie_win));
	
	// Plugin disabled?
	if(!get_pcvar_num(cvar_enabled)) 
	{
		return;
	}
	
	// Mod is enabled
	g_zmod_enabled = true;
	
	// Cvars General
	cvar_min_players = register_cvar("zmod_min_players", "4");
	cvar_delay = register_cvar("zmod_delay", "18");
	cvar_gamedescription = register_cvar("zmod_description", "[ZM] Zombie Mod Infection");
	cvar_custom_win_sounds = register_cvar("zmod_custom_win_sounds", "0");
	cvar_block_hud_messages = register_cvar("zmod_block_hud_messages", "0");
	cvar_he_hitself = register_cvar("zmod_he_hitself", "1");
	
	// Cvars Weapons
	cvar_weapons_display = register_cvar("zmod_weapons_display", "1");
	cvar_weapon_alt_names = register_cvar("zmod_weapon_alt_names", "0");
	cvar_weapons_shotguns = register_cvar("zmod_weapons_shotguns", "1");
	cvar_weapons_smgs = register_cvar("zmod_weapons_smgs", "1");
	cvar_weapons_rifles = register_cvar("zmod_weapons_rifles", "0");
	cvar_weapons_snipers = register_cvar("zmod_weapons_snipers", "0");
	cvar_weapons_autosnipers = register_cvar("zmod_weapons_autosnipers", "0");
	
	new cvar_name[64];
	for(new i = 0; i < sizeof(g_primary_weapons); i++)
	{
		formatex(cvar_name, charsmax(cvar_name), "zmod_weapon_%s", g_primary_weapons[i][EntityName][7]);
		g_primary_cvar[i] = register_cvar(cvar_name, "1");
	}
	
	// Cvars Zombies
	cvar_zombie_armor = register_cvar("zmod_zombie_armor", "0.75");
	cvar_zombie_brainhealth = register_cvar("zmod_zombie_brainhealth", "100");
	cvar_firstzombie_health = register_cvar("zmod_firstzombie_health", "6000");
	cvar_zombie_health = register_cvar("zmod_zombie_health", "2250");
	cvar_zombie_speed = register_cvar("zmod_zombie_speed", "260.0");
	cvar_zombie_gravity = register_cvar("zmod_zombie_gravity", "0.9");
	cvar_superzombie_health = register_cvar("zmod_superzombie_health", "60000");
	cvar_superzombie_speed = register_cvar("zmod_superzombie_speed", "260.0");
	cvar_superzombie_gravity = register_cvar("zmod_superzombie_gravity", "0.6");
	cvar_superzombie_chance = register_cvar("zmod_superzombie_chance", "20");
	cvar_superzombie_enabled = register_cvar("zmod_superzombie_enabled", "0");
	cvar_multi_chance = register_cvar("zmod_multi_chance", "3");
	cvar_multi_min_players = register_cvar("zmod_multi_min_players", "12");
	
	// Cvars Humans
	cvar_human_health = register_cvar("zmod_human_health", "100");
	cvar_human_speed = register_cvar("zmod_human_speed", "240.0");
	cvar_human_gravity = register_cvar("zmod_human_gravity", "0.9");
	
	// Precache sounds
	precache_sound(lasthumanchant);
	precache_sound(lastzombiechant);
	precache_sound(superappears);
	precache_sound(sound_armorhit);
	precache_sound(sound_weapon_restricted);
	precache_sound(sound_default_terwin);
	precache_sound(sound_default_ctwin);
	precache_sound(sound_default_rounddraw);
	
	// Precache player models
	precache_player_models(ZombieModel, sizeof(ZombieModel), g_ValidZombieModels, charsmax(g_ValidZombieModels[]), "zombie", g_iValidZombieCount);
	precache_player_models(SuperModel, sizeof(SuperModel), g_ValidSuperModels, charsmax(g_ValidSuperModels[]), "zombie", g_iValidSuperCount);
	precache_player_models(HumanModel, sizeof(HumanModel), g_ValidHumanModels, charsmax(g_ValidHumanModels[]), "urban", g_iValidHumanCount);
	
	// Precache knife models
	precache_model(ZombieKnife);
	precache_model(SuperKnife);
	precache_model(HumanKnife);
	
	// Precache sound arrays
	precache_sound_array(humans_win, sizeof(humans_win));
	precache_sound_array(rounddraw, sizeof(rounddraw));
	precache_sound_array(zombie_chants, sizeof(zombie_chants));
	precache_sound_array(zombie_death, sizeof(zombie_death));
	precache_sound_array(zombie_infect, sizeof(zombie_infect));
	precache_sound_array(zombie_pain, sizeof(zombie_pain));
}

public plugin_init()
{
	// Zombie mod enabled?
	if(!g_zmod_enabled) 
	{
		return;
	}

	// Menus
	register_menu("Zombie Mod Help Menu", KEYSMENU, "menu_help_handler");
	register_menu("Zombie Mod Weapons Menu", KEYSMENU, "weapon_menu_handler");
	register_menu("Zombie Mod Primary Weapon Menu", KEYSMENU, "menu_primary_handler")
	register_menu("Zombie Mod Secondary Weapon Menu", KEYSMENU, "menu_secondary_handler")
	register_menu("Zombie Mod Grenades Menu", KEYSMENU, "menu_nade_handler");
	
	// Events
	register_logevent("logevent_round_start",2, "1=Round_Start");
	register_logevent("logevent_round_end", 2, "1=Round_End");
	register_event("HLTV", "event_new_round", "a", "1=0", "2=0");
	register_event("TextMsg", "event_game_restart", "a", "2=#Game_will_restart_in");
	register_event("TextMsg", "event_game_commencing", "a", "2=#Game_Commencing");
	
	// Forwards
	register_forward(FM_GetGameDescription, "fw_GetGameDescription");
	register_forward(FM_EmitSound, "fw_EmitSound");
	
	// Ham
	RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawnPost", 1);
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled");
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage");
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack");
	RegisterHam(Ham_AddPlayerItem, "player", "fw_AddPlayerItem");
	RegisterHamBots(Ham_Spawn, "fw_PlayerSpawnPost", 1);
	RegisterHamBots(Ham_Killed, "fw_PlayerKilled");
	RegisterHamBots(Ham_TakeDamage, "fw_TakeDamage");
	RegisterHamBots(Ham_TraceAttack, "fw_TraceAttack");
	
	// Message Ids
	g_MsgScoreAttrib = get_user_msgid("ScoreAttrib");
	g_MsgScoreInfo = get_user_msgid("ScoreInfo");
	g_MsgFlashlight = get_user_msgid("Flashlight"); 
	g_MsgDeathMsg = get_user_msgid("DeathMsg");
	
	// Message Hooks
	register_message(get_user_msgid("TextMsg"),"message_textmsg");
	register_message(get_user_msgid("TeamScore"), "message_teamscore");
	
	// Create hud sync objects
	g_msg_sync = CreateHudSyncObj();
	g_msg_winteam = CreateHudSyncObj();
	g_msg_health = CreateHudSyncObj();
	
	// Commands
	register_clcmd("chooseteam", "clcmd_changeteam");
	register_clcmd("jointeam",  "clcmd_changeteam");
	register_clcmd("say /humans", "clcmd_humans");
	register_clcmd("say /zombies", "clcmd_zombies");
	register_clcmd("say /first", "clcmd_nominee");
	register_clcmd("say /zmmenu", "zm_menu_main");
	register_clcmd("say /help", "zm_menu_help");
	
	// Tasks 
	set_task(ZOMBIE_CHANT_DELAY, "task_zombie_chant", _, _, _, "b");
	set_task(PLAYER_COUNT_DELAY, "task_player_infos", _, _, _, "b");

	// Custom Forwards
	g_fwd_user_cured = CreateMultiForward("zmod_user_cured", ET_IGNORE, FP_CELL);
	g_fwd_user_infected = CreateMultiForward("zmod_player_infection", ET_IGNORE, FP_CELL, FP_CELL);
	g_fwd_infection_begin = CreateMultiForward("zmod_infection_begin", ET_IGNORE);
	
	// Get Maxplayers
	g_maxplayers = get_maxplayers();
}

public plugin_cfg()
{
	if(!g_zmod_enabled)
	{
		return;
	}
	
	// Get configs directory path
	new configsdirectory[32];
	get_configsdir(configsdirectory, charsmax(configsdirectory));
	
	cvar_human_clipcost = get_cvar_pointer("zmod_human_clipcost");
	cvar_lightning = get_cvar_pointer("zmod_lights");
	
	// Execute config file (zombie_mod_infection10.cfg)
	server_cmd("exec %s/zombie_mod_infection10.cfg", configsdirectory);
	
	// Cache the cvars
	set_task(0.5, "cache_cvars");
}

/*========================================================*\
||::::::::::::::::::::::::::::::::::::::::::::::::::::::::||
||----------------[ Client Management ]-------------------||
||::::::::::::::::::::::::::::::::::::::::::::::::::::::::||
\*========================================================*/

// Player joins the server
public client_putinserver(id)
{
	// Player joined the server
	BIT_SET(g_bitConnected, id);
	BIT_CLEAR(g_bitAlive, id);
	
	// Cache player's name
	get_user_name(id, g_playername[id], charsmax(g_playername[]));
	
	// Reset vars
	reset_vars(id);
	
	// Check if is a bot
	if(is_user_bot(id))
	{
		// The player is a bot
		BIT_SET(g_bitBot, id);
	}
	else
	{
		// Check if user is an admin
		if(is_user_admin(id))
		{
			BIT_SET(g_bitAdmin, id);
		}
		
		// Show hud to the player
		set_task(1.0, "show_health_hud", id+TASK_HEALTHHUD, _, _, "b");
	}
	
	return PLUGIN_HANDLED;
}

// Player leaves the server
public client_disconnected(id)
{
	// Reset vars
	reset_vars(id);
	
	// Check if the player left was the last zombie/human
	if(BIT_CHECK(g_bitAlive,id))
	{
		task_check_round(id);
	}
	
	// Player left the server, clear flags
	BIT_CLEAR(g_bitConnected, id);
	BIT_CLEAR(g_bitAlive, id);
	BIT_CLEAR(g_bitBot, id);
    
	// Remove any tasks associated with the player
	remove_task(id+TASK_HEALTHHUD);
	remove_task(id);
}

// Client user info changed forward
public client_infochanged(id)
{
	// Cache player's name again if player changed it
	get_user_name(id, g_playername[id], charsmax(g_playername[]));
}

/*========================================================*\
||::::::::::::::::::::::::::::::::::::::::::::::::::::::::||
||--------------------[ Commands ]------------------------||
||::::::::::::::::::::::::::::::::::::::::::::::::::::::::||
\*========================================================*/

// Prevents players from changing teams during the game
public clcmd_changeteam(id)
{
	// Check if the player is connected
	if(!BIT_CHECK(g_bitConnected, id))
	{
		return PLUGIN_HANDLED;
	}
	
	// Get user team
	static CsTeams:team;
	team = cs_get_user_team(id);
	
	// Allow team change only for spectators or unassigned players
	if(team == CS_TEAM_SPECTATOR || team == CS_TEAM_UNASSIGNED)
	{
		return PLUGIN_CONTINUE;
	}
	
	return PLUGIN_HANDLED;
}

// Handles nomination to be first zombie
public clcmd_nominee(id)
{
	// Case 1: First zombie already selected
	if(g_selected_firstzombie)
	{
		client_print_color(id, print_team_default, "^4[ZM] ^1%L", LANG_PLAYER, "TXT_FIRST_ZOMBIE_ALREADY_SELECTED");
		return PLUGIN_HANDLED;
	}
	
	// Case 2: Player is dead
	if(!BIT_CHECK(g_bitAlive, id))
	{
		client_print_color(id, print_team_default, "^4[ZM] ^1%L", LANG_PLAYER, "TXT_DEAD_CANT_NOMINATE");
		return PLUGIN_HANDLED;
	}
	
	// Case 3: Player already nominated
	if(BIT_CHECK(g_bitZombieNominee, id))
	{
		client_print_color(id, print_team_default, "^4[ZM] ^1%L", LANG_PLAYER, "TXT_ALREADY_NOMINATED");
		return PLUGIN_HANDLED;
	}
	
	// Case 4: All good, nominate
	BIT_SET(g_bitZombieNominee, id);
	client_print_color(0, print_team_default, "^4[ZM] ^1%L", LANG_PLAYER, "TXT_NOMINATED", g_playername[id]);
	
	return PLUGIN_HANDLED;
}

// Watch how many humans are currently alive
public clcmd_humans(id)
{
	client_print_color(id, print_team_default, "^4[ZM] ^1%L", LANG_PLAYER, "INFO_ALIVEHUMANS", HumansCount());
	return PLUGIN_HANDLED;
}

// Watch how many zombies are currently alive
public clcmd_zombies(id)
{
	client_print_color(id, print_team_default, "^4[ZM] ^1%L", LANG_PLAYER, "INFO_ALIVEZOMBIES", ZombiesCount());
	return PLUGIN_HANDLED;
}

/*========================================================*\
||::::::::::::::::::::::::::::::::::::::::::::::::::::::::||
||--------------------[ Events ]--------------------------||
||::::::::::::::::::::::::::::::::::::::::::::::::::::::::||
\*========================================================*/

// Called when the game is about to restart. Resets the scores.
public event_game_restart() 
{
	// Trigger round end event
	logevent_round_end();
	
	// Check if we didn't have enough players before
	if(check_players())
	{
		// Set the flag to true
		g_enough_players = true;
			
		// Send Message
		set_hudmessage(0, 255, 0, -1.0, 0.4, 1, 0.0, 3.0, 2.0, 1.0); 
		ShowSyncHudMsg(0, g_msg_sync, "%L", LANG_PLAYER, "HUD_ENOUGH_PLAYERS");
	}
	
	// Reset scores 
	g_score_humans = 0;
	g_score_zombies = 0;
}

// Called when the game is commencing. Resets the scores, and checks if there are enough players.
public event_game_commencing() 
{
	// Check if we didn't have enough players before
	if(check_players())
	{
		// Set the flag to true
		g_enough_players = true;
			
		// Send Message
		set_hudmessage(0, 255, 0, -1.0, 0.4, 1, 0.0, 3.0, 2.0, 1.0); 
		ShowSyncHudMsg(0, g_msg_sync, "%L", LANG_PLAYER, "HUD_ENOUGH_PLAYERS");
	}
	
	// Set game commencing flag
	g_gamecommencing = true;
	
	// Reset scores
	g_score_humans = 0;
	g_score_zombies = 0;
}

// Round start event
public logevent_round_start()
{
	// Freeze time ends unfreeze players
	g_freezetime = false;
	set_task(0.1, "freeze_players");
	
	// Schedule the selection of the first zombie
	set_task(2.0 + g_cached_delay, "task_select_a_zombie", TASK_MAKEZOMBIE);
}

// New round event
public event_new_round()
{
	// Set round state flags
	g_endround = false;
	g_newround = true;
	g_selected_firstzombie = false;
	
	// Freeze players
	g_freezetime = true;
	set_task(0.1, "freeze_players");
	
	// Reset kill counters
	g_zombie_round_kills_count = 0;
	g_human_round_kills_count = 0;
	
	// Force bots to nominate themselves
	set_task(1.1, "force_bot_nominate", _, _, _, "a", random_num(8, 12));
	
	// Show scores
	set_task(2.0, "task_display_score");
	
	// Cache all cvars
	cache_cvars();
}

// Round end event
public logevent_round_end()
{
	// Get team counts
	new humans = HumansCount();
	new zombies = ZombiesCount();
		
	// Check if there are no zombies left (Humans win)
	if(!zombies) 
	{
		// Update human score if the game is not in the commencing phase
		if(!g_gamecommencing)
		{
			g_score_humans++;
		}
		
		// Play humans win sound whether is custom sound or not
		g_cached_custom_win_sounds ? PlaySound(0, humans_win[random_num(0, sizeof(humans_win) - 1)]) : PlaySound(0, sound_default_ctwin); 
		
		// Display messages
		set_hudmessage(0, 0, 255, -1.0, 0.22, 0, 1.0, 5.0, 0.1, 0.2, -1);
		ShowSyncHudMsg(0, g_msg_winteam, "%L", LANG_PLAYER, "HUD_WINHUMAN");
		client_print_color(0, print_team_default, "^4[ZM] ^1%L", LANG_PLAYER, "TXT_WINHUMAN");
	}
	// Check if there are no humans left (Zombies win)
	else if(!humans) 
	{
		// Update zombie score if the game is not in the commencing phase
		if(!g_gamecommencing)
		{
			g_score_zombies++;
		}
		
		// Play zombies win sound whether is custom sound or not
		g_cached_custom_win_sounds ? PlaySound(0, zombie_win[random_num(0, sizeof(zombie_win) - 1)]) : PlaySound(0, sound_default_terwin); 
		
		// Display messages
		set_hudmessage(255, 0, 0, -1.0, 0.22, 0, 1.0, 5.0, 0.1, 0.2, -1);
		ShowSyncHudMsg(0, g_msg_winteam, "%L", LANG_PLAYER, "HUD_WINZOMBIE");
		client_print_color(0, print_team_default, "^4[ZM] ^1%L", LANG_PLAYER, "TXT_WINZOMBIE");
	}
	// Check if both teams have players left (No one wins)
	else if(humans && zombies) 
	{
		// Play draw sound whether is custom sound or not
		g_cached_custom_win_sounds ? PlaySound(0, rounddraw[random_num(0, sizeof(rounddraw) - 1)]) : PlaySound(0, sound_default_rounddraw); 
		
		// Display messages
		set_hudmessage(255, 255, 255, -1.0, 0.22, 0, 1.0, 5.0, 0.1, 0.2, -1);
		ShowSyncHudMsg(0, g_msg_winteam, "%L", LANG_PLAYER, "HUD_NOONE");
		client_print_color(0, print_team_default, "^4[ZM] ^1%L", LANG_PLAYER, "TXT_NOONE");
	}
			
	// Set round flags
	g_endround = true;
	g_superround = false;
	g_infectionround = false;
	g_multiround = false;
	
	// Set game commencing flag 
	g_gamecommencing = false;

	// Remove existing task
	remove_task(TASK_MAKEZOMBIE);
	
	// Balance the teams
	set_task(1.0, "task_balance_teams");
}

/*========================================================*\
||::::::::::::::::::::::::::::::::::::::::::::::::::::::::||
||--------------------[ Messages ]------------------------||
||::::::::::::::::::::::::::::::::::::::::::::::::::::::::||
\*========================================================*/

// Handle and optionally block or modify round end HUD messages
public message_textmsg()
{
	// Only process central HUD messages 
	if(get_msg_arg_int(1) != 4)
	{
		return PLUGIN_CONTINUE; // Let other types of messages through
	}
	
	// If cvar is enabled, block all central HUD messages
	if(g_cached_block_hud_messages)
	{
		return PLUGIN_HANDLED; // Block message completely
	}
	
	// Get the message string
	static textmsg[25];
	get_msg_arg_string(2, textmsg, charsmax(textmsg));
	
	// Replace the "Hostages Not Rescued" message with "Round Draw!"
	if(equal(textmsg, "#Hostages_Not_Rescued"))
	{
		set_msg_arg_string(2, "#Cstrike_TitlesTXT_Round_Draw");
	}
	
	return PLUGIN_CONTINUE; // Allow all other messages
}

// Send actual team scores 
public message_teamscore()
{
	static team[2];
	get_msg_arg_string(1, team, charsmax(team));
	
	switch(team[0])
	{
		case 'C': set_msg_arg_int(2, get_msg_argtype(2), g_score_humans); // CT
		case 'T': set_msg_arg_int(2, get_msg_argtype(2), g_score_zombies); // T
	}
}

// Handle full infection process: frags, deaths, messages, and scoreboard update
public ProcessInfection(attacker, victim)
{
	// Update frags and deaths
	set_user_frags(attacker, get_user_frags(attacker) + 1);
	cs_set_user_deaths(victim, cs_get_user_deaths(victim) + 1);
	
	// Send death message
	message_begin(MSG_ALL, g_MsgDeathMsg);
	write_byte(attacker);      // Killer
	write_byte(victim);        // Victim
	write_byte(1);             // Headshot flag 
	write_string("Infection"); // Weapon name
	message_end();
	
	// Fix fake dead attribute on scoreboard
	message_begin(MSG_ALL, g_MsgScoreAttrib);
	write_byte(victim); // Player ID
	write_byte(0);      // Reset attribute
	message_end();
	
	// Update scoreboard for attacker
	message_begin(MSG_ALL, g_MsgScoreInfo);
	write_byte(attacker);                 // Player ID
	write_short(get_user_frags(attacker));    // Frags
	write_short(cs_get_user_deaths(attacker)); // Deaths
	write_short(0);                       
	write_short(1);                        
	message_end();
}

/*========================================================*\
||::::::::::::::::::::::::::::::::::::::::::::::::::::::::||
||--------------------[ Forwards ]------------------------||
||::::::::::::::::::::::::::::::::::::::::::::::::::::::::||
\*========================================================*/

// Emit sound for zombies
public fw_EmitSound(id, channel, const sample[], Float:volume, Float:attn, flags, pitch)
{
	// Player disconnected or not a zombie
	if(!is_valid_player_connected(id) || !BIT_CHECK(g_bitZombie, id))
	{
		return FMRES_IGNORED;
	}
	
	// Block unnecesary pickup sound for zombies
	if(equal(sample, "items/gunpickup2.wav"))
	{
		return FMRES_SUPERCEDE;
	}
	
	// Zombie being hit
	if(sample[7] == 'b' && sample[8] == 'h' && sample[9] == 'i' && sample[10] == 't' || sample[7] == 'h' && sample[8] == 'e' && sample[9] == 'a' && sample[10] == 'd')
	{
		emit_sound(id, channel, zombie_pain[random_num(0, sizeof(zombie_pain) - 1)], volume, attn, flags, pitch);	
		return FMRES_SUPERCEDE;
	}
	
	// Zombie dies
	if(sample[7] == 'd' && (sample[8] == 'i' && sample[9] == 'e' || sample[12] == '6'))
	{
		emit_sound(id, channel, zombie_death[random_num(0, sizeof(zombie_death) - 1)], volume, attn, flags, pitch);
		return FMRES_SUPERCEDE;
	}
	
	return FMRES_IGNORED;
}

// Forward Get Game Description
public fw_GetGameDescription()
{
	// Return the mod name so it can be easily identified
	static gamename[64];
	get_pcvar_string(cvar_gamedescription, gamename, charsmax(gamename));
	forward_return(FMV_STRING, gamename);
	return FMRES_SUPERCEDE;
}

/*========================================================*\
||::::::::::::::::::::::::::::::::::::::::::::::::::::::::||
||-----------------------[ HAM ]--------------------------||
||::::::::::::::::::::::::::::::::::::::::::::::::::::::::||
\*========================================================*/

// Ham player spawn post forward
public fw_PlayerSpawnPost(id) 
{
	// Check if the player is alive and on a team
	if(!is_user_alive(id) || !cs_get_user_team(id)) 
	{ 
		return;
	}
	
	// The player has spawned
	BIT_SET(g_bitAlive, id);
	
	// Turn player into human
	set_task(0.1, "task_make_human", id);
} 

// Event when a player is killed
public fw_PlayerKilled(victim, attacker, shouldgib)
{
	// The player died
	BIT_CLEAR(g_bitAlive, victim);

	// Check if the victim was a zombie
	if(BIT_CHECK(g_bitZombie, victim)) 
	{	
		// Increment the zombie kill count
		g_zombie_round_kills_count++;
		
		// If is only one zombie remaining play the chant
		task_last_team_chant(1);
	}
	// Human was killed
	else 
	{
		// Increment the human kill count
		g_human_round_kills_count++;
		
		// If is only one human remaining play the chant
		task_last_team_chant(2);
	}
}

// Ham take damage forward
public fw_TakeDamage(victim, inflictor, attacker, Float:damage, dmgbits)
{
	// Player Disconnected??
	if(!is_valid_player_connected(attacker) || !is_valid_player_connected(victim))
	{
		return HAM_IGNORED;
	}
	
	// Fall damage, we keep it normal
	if(dmgbits & DMG_FALL)
	{
		return HAM_IGNORED;
	}
	
	// Block self damage with HE grenade (only if disabled by cvar)
	if((victim == attacker) && (dmgbits & DMG_HEGRENADE))
	{
		return (!g_cached_he_hitself) ? HAM_SUPERCEDE : HAM_IGNORED;
	}

	// New round starting or round ended
	if(g_newround || g_endround)
	{
		return HAM_SUPERCEDE;
	}
	
	// Attacker is human
	if(BIT_CHECK(g_bitZombie, victim) && BIT_CHECK(g_bitHuman, attacker))
	{
		// Super zombie ignores armor multiplier
		if(!BIT_CHECK(g_bitSuperZombie, victim))
		{
			damage *= g_cached_zombie_armor;
			SetHamParamFloat(4, damage);
		}
		return HAM_IGNORED;
	}
	
	// Attacker is zombie
	if(BIT_CHECK(g_bitZombie, attacker) && BIT_CHECK(g_bitHuman, victim))
	{
		// If there's only 1 human, no infection allowed
		if(HumansCount() <= 1)
		{
			return HAM_IGNORED;
		}
		// Check if infection is allowed
		else if(allow_infection(attacker, victim))
		{
			// Update score and death message
			ProcessInfection(attacker, victim);
			
			// Infect victim
			task_infect_user(victim, attacker, 0);
			
			// Infection HUD notice
			new Float:yPos = 0.37 + (0.02 * random_num(0, 4));
			set_hudmessage(255, 0, 0, 0.05, yPos, 0, 0.0, 5.0, 1.0, 1.0, -1);
			show_hudmessage(0, "%L", LANG_PLAYER, "NOTICE_INFECT", g_playername[victim], g_playername[attacker]);
			
			// Play last human sound if needed
			task_last_team_chant(2);
			return HAM_SUPERCEDE;
		}
		// If infection fails but there are still more than 1 human
		else 
		{
			// Get victim armor
			new Float:armor = entity_get_float(victim, EV_FL_armorvalue);
			
			// Prevent infection and reduce armor instead
			if(armor > 0.0)
			{
				// Play armorhit sound
				emit_sound(victim, CHAN_BODY, sound_armorhit, 1.0, ATTN_NORM, 0, PITCH_NORM);
				
				// Subtract damage from armor; if it drops below zero, set armor to 0
				(armor - damage > 0.0) ? entity_set_float(victim, EV_FL_armorvalue, armor - damage) : cs_set_user_armor(victim, 0, CS_ARMOR_NONE);
				return HAM_SUPERCEDE;
			}
		}
	}
	
	return HAM_IGNORED;
}

// Ham Trace Attack Forward
public fw_TraceAttack(victim, attacker, Float:damage, Float:direction[3], tracehandle, damage_type)
{
	// Player disconnected??
	if(!is_valid_player_connected(attacker))
	{
		return HAM_IGNORED;
	}
	
	// New round starting or round ended
	if(g_newround || g_endround)
	{
		return HAM_SUPERCEDE;
	}
	
	// Victim isn't a zombie or not bullet damage, nothing else to do here
	if(!BIT_CHECK(g_bitZombie, victim) || !(damage_type & DMG_BULLET))
	{
		return HAM_IGNORED;
	}
	
	return HAM_IGNORED;
}

// Ham Weapon Pickup Forward
public fw_AddPlayerItem(id, weapon_ent)
{
	// Retrieve our custom extra ammo from the weapon
	static extra_ammo;
	extra_ammo = entity_get_int(weapon_ent, ADDITIONAL_AMMO); 
	
	// If present
	if(extra_ammo)
	{
		// Get weapon's id
		static weaponid;
		weaponid = cs_get_weapon_id(weapon_ent);

		// Add to player's bpammo
		cs_set_user_bpammo(id, weaponid, extra_ammo);
		entity_set_int(weapon_ent, ADDITIONAL_AMMO, 0);
	}
}

/*========================================================*\
||::::::::::::::::::::::::::::::::::::::::::::::::::::::::||
||------------------[ Zombie Speech ]---------------------||
||::::::::::::::::::::::::::::::::::::::::::::::::::::::::||
\*========================================================*/

// Zombie speech task: Manages different zombie-related sounds depending on the round status
public task_zombie_chant()
{
	if(g_endround || g_newround)
	{
		return;
	}
	
	new humans = HumansCount();
	new zombies = ZombiesCount();
	new status = (humans == 1 && zombies == 1) ? 3 : (humans == 1) ? 1 : (zombies == 1) ? 2 : 0;
	
	for(new id = 1; id <= g_maxplayers; id++)
	{
		if(!is_valid_player_alive(id) || !BIT_CHECK(g_bitZombie, id))
		{
			continue;
		}
		
		switch(status)
		{
			case 0: emit_sound(id, CHAN_VOICE, zombie_chants[random_num(0, sizeof(zombie_chants)-1)], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
			case 1: emit_sound(id, CHAN_VOICE, lasthumanchant, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
			case 2: emit_sound(id, CHAN_VOICE, lastzombiechant, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
			case 3: emit_sound(id, CHAN_VOICE, (random_num(1,8) % 2) ? lasthumanchant : lastzombiechant, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		}
	}
}

// Zombie speech task: Manages different zombie-related sounds depending on the round status
public task_last_team_chant(team)
{
	if(team != 1 && team != 2) 
	{
		return;
	}

	new count = (team == 1) ? ZombiesCount() : HumansCount();
	
	if(count != 1)
	{
		return;
	}
	
	for(new id = 1; id <= g_maxplayers; id++)
	{
		if(!is_valid_player_alive(id) || !BIT_CHECK(g_bitZombie, id))
		{
			continue;
		}
		
		emit_sound(id, CHAN_VOICE, (team == 1) ? lastzombiechant : lasthumanchant, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	}
}

/*========================================================*\
||::::::::::::::::::::::::::::::::::::::::::::::::::::::::||
||------------------[ Player Counts ]---------------------||
||::::::::::::::::::::::::::::::::::::::::::::::::::::::::||
\*========================================================*/

// Begin task to show player information periodically
public task_player_infos()
{
	// Schedule the task to run every 5 seconds, 6 times
	set_task(5.0, "task_show_infos", _, _, _, "a", 6);
}

// Task to show player count information
public task_show_infos()
{
	// Set HUD message style (position, size, duration, etc.)
	set_hudmessage(255, 255, 255, 0.80, 0.37, 0, 6.0, 5.0, 0.1, 0.1, 4);
	
	// Initialize counters for different player states
	new humans = 0, zombies = 0, deadplayers = 0, spectators = 0;
	
	// Loop through all possible player slots
	for(new id = 1; id <= g_maxplayers; id++)
	{
		// Skip if player is not connected
		if(!BIT_CHECK(g_bitConnected, id))
		{
			continue;
		}
		
		// Get the player's team
		static CsTeams:team;
		team = cs_get_user_team(id);
		
		// Check if the player is alive
		// If alive, check if the player is human and increment humans counter
		// If not human but zombie, increment zombies counter
		// If neither human nor zombie, do nothing
		// If the player is dead, check if they are not a spectator or unassigned
		// If so, increment deadplayers counter
		// Otherwise, increment spectators counter
		BIT_CHECK(g_bitAlive, id) ? (BIT_CHECK(g_bitHuman, id) ? humans++ : BIT_CHECK(g_bitZombie, id) ? zombies++ : 0) : (team != CS_TEAM_SPECTATOR && team != CS_TEAM_UNASSIGNED ? deadplayers++ : spectators++);
	}
	
	// Display the HUD message with all counts
	ShowSyncHudMsg(0, g_msg_sync, "%L", LANG_PLAYER, "HUD_PLAYERCOUNT", humans, zombies, g_human_round_kills_count, g_zombie_round_kills_count, deadplayers, spectators, get_playersnum());
}

// Global player count function
public CountPlayers(CountType:count_type)
{
	static count, id;
	count = 0;
	
	for(id = 1; id <= g_maxplayers; id++)
	{
		if(!BIT_CHECK(g_bitAlive, id))
		{
			continue;
		}
		
		if(count_type == COUNT_ALIVE)
		{
			count++;
		}
		else if(count_type == COUNT_ZOMBIES && BIT_CHECK(g_bitZombie, id))
		{
			 count++;
		}
		else if(count_type == COUNT_HUMANS && BIT_CHECK(g_bitHuman, id)) 
		{
			count++;
		}
		else if(count_type == COUNT_NOMINEES && BIT_CHECK(g_bitZombieNominee, id))
		{
			count++;
		}
	}
	
	return count;
}

// Get current alive players count
public GetAliveCount()
{
	return CountPlayers(COUNT_ALIVE);
}

// Get zombies count
public ZombiesCount() 
{
	return CountPlayers(COUNT_ZOMBIES);
}

// Get humans count
public HumansCount() 
{
	return CountPlayers(COUNT_HUMANS);
}

// Get nominees count
public ZombiesNomineeCount() 
{
	return CountPlayers(COUNT_NOMINEES);
}

// Get Dead -returns number of dead users-
public GetDeadCount()
{
	static dead, id, CsTeams:team;
	dead = 0;
	
	for(id = 1; id <= g_maxplayers; id++)
	{
		if(!BIT_CHECK(g_bitConnected, id))
		{
			continue;
		}
		
		// Skip spectators and unassigned
		team = cs_get_user_team(id);
		if(team == CS_TEAM_SPECTATOR || team == CS_TEAM_UNASSIGNED)
		{
			continue;
		}
		
		if(BIT_CHECK(g_bitAlive, id))
		{
			continue;
		}
		
		dead++;
	}
	
	return dead;
}

public GetRandomAliveCount(n, nominee)
{
	static count, id;
	count = 0;
	
	for(id = 1; id <= g_maxplayers; id++)
	{
		if(!BIT_CHECK(g_bitAlive, id))
		{
			continue;
		}
		
		if(nominee && !BIT_CHECK(g_bitZombieNominee, id))
		{
			continue;
		}
		
		count++;
		
		if(count == n)
		{
			return id;
		}
	}
	
	return -1;
}

/*========================================================*\
||::::::::::::::::::::::::::::::::::::::::::::::::::::::::||
||--------------[ Stocks and Some Tasks ]-----------------||
||::::::::::::::::::::::::::::::::::::::::::::::::::::::::||
\*========================================================*/

// Display scores task
public task_display_score()
{
	set_hudmessage(255, 165, 0, -1.0, 0.17, 1, 0.0, 3.0, 2.0, 1.0, -1);
	ShowSyncHudMsg(0, g_msg_sync, "%L", LANG_PLAYER, "HUD_SCORE", g_score_zombies, g_score_humans);
}

public freeze_players()
{
	static id;
	for(id = 1; id <= g_maxplayers; id++)
	{
		if(!BIT_CHECK(g_bitAlive,id))
		{
			continue;
		}
		
		(g_freezetime) ? entity_set_int(id, EV_INT_flags, entity_get_int(id, EV_INT_flags) | FL_FROZEN) : entity_set_int(id, EV_INT_flags, entity_get_int(id, EV_INT_flags) & ~FL_FROZEN);
	}
}

stock bool:is_valid_player(id)
{
	return (1 <= id && id <= g_maxplayers);
}

stock bool:is_valid_player_connected(id)
{
	return is_valid_player(id) && BIT_CHECK(g_bitConnected, id);
}

stock bool:is_valid_player_alive(id)
{
	return is_valid_player(id) && BIT_CHECK(g_bitAlive, id);
}

// Check if infection is allowed based on multiple conditions
stock bool:allow_infection(attacker, victim) 
{
	// Quick checks first
	if(!BIT_CHECK(g_bitZombie, attacker) || !BIT_CHECK(g_bitHuman, victim))
	{
		return false;
	}

	// Cache user button state
	new buttons = get_user_button(attacker);

	// Must be primary attack and not secondary
	if(!(buttons & IN_ATTACK) || (buttons & IN_ATTACK2))
	{
		return false;
	}

	// Victim must have no armor
	if(cs_get_user_armor(victim) > 0)
	{
		return false;
	}
	
	return true;
}

// Health HUD display 
public show_health_hud(taskid)
{
	static id, spec;
	id = taskid - TASK_HEALTHHUD;
	
	if(!is_valid_player_connected(id))
	{
		return;
	}
	
	if(BIT_CHECK(g_bitAlive, id))
	{
		// Alive: show health & armor
		set_hudmessage(255, 255, 255, 0.02, 0.00, 0, 0.0, 3.0, 0.0, 0.0, 1);
		ShowSyncHudMsg(id, g_msg_health, "%L: %d^n^n^n^n^n^n%L: %d", id, "HUD_HEALTH", get_user_health(id), id, "HUD_ARMOR", get_user_armor(id));
	}
	else
	{
		// Spectating: get target
		spec = entity_get_int(id, EV_INT_iuser2);
		if(!is_valid_player_connected(spec) || !BIT_CHECK(g_bitAlive, spec) || cs_get_user_team(id) == CS_TEAM_UNASSIGNED)
		{
			return;
		}
		
		// Get weapon info
		new clip, ammo, weapon = get_user_weapon(spec, clip, ammo), weap_name[32];
		(weapon > 0) ? get_weaponname(weapon, weap_name, charsmax(weap_name)) : copy(weap_name, charsmax(weap_name), "N/A");
		replace(weap_name, charsmax(weap_name), "weapon_", "");
		
		// Show HUD
		set_hudmessage(255, 10, 255, -1.0, 0.76, 1, 0.0, 3.0, 0.0, 0.0, 1);
		if(weapon != CSW_KNIFE && weapon > 0)
		{
			ShowSyncHudMsg(id, g_msg_health, "%L: %s^n[ %L: %d | %L: %d | %L: %d ]^n[%L: %s | %L: %d/%d]", id, "HUD_SPECTATING", g_playername[spec], id, "HUD_HEALTH", get_user_health(spec), id, "HUD_ARMOR", get_user_armor(spec), id, "HUD_MONEY", cs_get_user_money(spec), id, "HUD_WEAPON", weap_name, id, "HUD_AMMO", clip, ammo);
		}
		else
		{
			// Knife has no ammo
			ShowSyncHudMsg(id, g_msg_health, "%L: %s^n[ %L: %d | %L: %d | %L: %d ]^n[%L: %s]", id, "HUD_SPECTATING", g_playername[spec], id, "HUD_HEALTH", get_user_health(spec), id, "HUD_ARMOR", get_user_armor(spec), id, "HUD_MONEY", cs_get_user_money(spec),id, "HUD_WEAPON", weap_name);
		}
	}
}

// Schedule a restart 
schedule_restart_once()
{
	if(g_restart_scheduled)
	{
		return;
	}
	
	g_restart_scheduled = true;
	set_task(0.5, "execute_restart");
}

public execute_restart()
{
	server_cmd("sv_restart 3");
	g_restart_scheduled = false;
}

public bool:check_players()
{
	new alive = GetAliveCount();
	new dead = GetDeadCount();
	new sum = alive + dead;
	new bool:restart_needed = (!g_enough_players && sum >= g_cached_min_players);
	
	log_amx("[ZM] +--------------------------------------------------+");
	log_amx("[ZM] |              CHECK PLAYERS STATUS               |");
	log_amx("[ZM] +--------------------------------------------------+");
	log_amx("[ZM] | Alive players: %-33d |", alive);
	log_amx("[ZM] | Dead players: %-33d |", dead);
	log_amx("[ZM] | Total players: %-33d |", sum);
	log_amx("[ZM] | Min required: %-33d |", g_cached_min_players);
	log_amx("[ZM] | Restart needed : %-33s |", restart_needed ? "YES" : "NO");
	log_amx("[ZM] +--------------------------------------------------+");
	
	return restart_needed;
}


// Check if the player who left was the last human or zombie and recover the round if needed
public task_check_round(player_left)
{
	// Get current team counts
	new zombies = ZombiesCount();
	new humans = HumansCount();

	// Round recovery is needed only if one team is empty
	if(zombies == 0 || humans == 0)
	{
		// If only one player remains on the other team, ignore
		if((zombies == 1 && humans == 0) || (humans == 1 && zombies == 0))
		{
			return;
		}

		// Prevent false triggers from bots on round change
		if(g_newround || g_endround)
		{
			return;
		}

		// Gather valid alive players (excluding the one who left)
		new candidates[32], count;
		for(new i = 1; i <= g_maxplayers; i++)
		{
			if(i != player_left && BIT_CHECK(g_bitAlive, i))
			{
				candidates[count++] = i;
			}
		}

		// No valid players left
		if(count == 0)
		{
			return;
		}

		// Select a random valid player
		new new_id = candidates[random(count)];

		// Determine if we're recovering a human or a zombie
		new bool:make_human = (humans == 0);

		if(make_human)
		{
			// Turn player into a human
			task_make_human(new_id);
		}
		else
		{
			// Turn player into a zombie
			task_infect_user(new_id, 0, 0);
		}

		// Prepare the message key
		new message[32];
		formatex(message, charsmax(message), make_human ? "LAST_HUMAN_LEFT" : "LAST_ZOMBIE_LEFT");

		// Print message to all players
		client_print_color(0, print_team_default, "^4[ZM] ^1%L", LANG_PLAYER, message, g_playername[new_id]);
	}
}

// Balance teams task
public task_balance_teams()
{
	new ActivePlayers[32];
	new PlayerCount = 0;
	new MaxTerrors;
	
	// Build a list of active players (not spectators or unassigned)
	for(new id = 1; id <= g_maxplayers; id++)
	{
		// Check if the player is connected
		if(is_valid_player_connected(id))
		{
			// Get user team
			static CsTeams:team;
			team = cs_get_user_team(id);
			
			// Count only Counter-Terrorists and Terrorists
			if(team != CS_TEAM_SPECTATOR && team != CS_TEAM_UNASSIGNED)
			{
				ActivePlayers[PlayerCount++] = id;
			}
		}
	}
	
	// If there's 1 or fewer players, no point in balancing
	if(PlayerCount <= 1) 
	{
		return;
	}
	
	// Shuffle the player list randomly using Fisher-Yates algorithm
	for(new i = PlayerCount - 1; i > 0; i--)
	{
		new j = random_num(0, i);
		new temp = ActivePlayers[i];
		ActivePlayers[i] = ActivePlayers[j];
		ActivePlayers[j] = temp;
	}
	
	// Calculate how many players should be on the Terrorist team
	MaxTerrors = PlayerCount / 2;
	
	// Assign the first half to Terrorists, rest to Counter-Terrorists
	for(new i = 0; i < PlayerCount; i++)
	{
		if(i < MaxTerrors)
		{
			cs_set_player_team(ActivePlayers[i], CS_TEAM_T);
		}
		else
		{
			cs_set_player_team(ActivePlayers[i], CS_TEAM_CT);
		}
	}
	
	// Reset player statuses 
	for(new k = 1; k <= g_maxplayers; k++)
	{
		BIT_CLEAR(g_bitHuman, k);
		BIT_CLEAR(g_bitZombie, k);
		BIT_CLEAR(g_bitFirstZombie, k);
		BIT_CLEAR(g_bitSuperZombie, k);
		BIT_CLEAR(g_bitZombieNominee, k);
		
		if(is_valid_player_alive(k))
		{
			(g_iValidHumanCount > 0) ? cs_set_user_model(k, g_ValidHumanModels[random(g_iValidHumanCount)]) : cs_set_user_model(k, "urban"); 
		}
	}
}

public cache_cvars()
{
	// Cvars General
	g_cached_min_players = get_pcvar_num(cvar_min_players);
	g_cached_delay = get_pcvar_num(cvar_delay);
	g_cached_custom_win_sounds = get_pcvar_num(cvar_custom_win_sounds);
	g_cached_block_hud_messages = get_pcvar_num(cvar_block_hud_messages);
	g_cached_he_hitself = get_pcvar_num(cvar_he_hitself);
	
	// Cvars Weapons
	g_cached_weapons_display = get_pcvar_num(cvar_weapons_display);
	g_cached_weapon_alt_names = get_pcvar_num(cvar_weapon_alt_names);
	g_cached_weapons_shotguns = get_pcvar_num(cvar_weapons_shotguns);
	g_cached_weapons_smgs = get_pcvar_num(cvar_weapons_smgs);
	g_cached_weapons_rifles = get_pcvar_num(cvar_weapons_rifles);
	g_cached_weapons_snipers = get_pcvar_num(cvar_weapons_snipers);
	g_cached_weapons_autosnipers = get_pcvar_num(cvar_weapons_autosnipers);
	
	// Cvars Zombies
	g_cached_zombie_armor = get_pcvar_float(cvar_zombie_armor);
	g_cached_zombie_brainhealth = get_pcvar_num(cvar_zombie_brainhealth);
	g_cached_firstzombie_health = get_pcvar_num(cvar_firstzombie_health);
	g_cached_zombie_health = get_pcvar_num(cvar_zombie_health);
	g_cached_zombie_speed = get_pcvar_float(cvar_zombie_speed);
	g_cached_zombie_gravity = get_pcvar_float(cvar_zombie_gravity);
	g_cached_superzombie_health = get_pcvar_num(cvar_superzombie_health);
	g_cached_superzombie_speed = get_pcvar_float(cvar_superzombie_speed);
	g_cached_superzombie_gravity = get_pcvar_float(cvar_superzombie_gravity);
	g_cached_superzombie_chance = get_pcvar_num(cvar_superzombie_chance);
	g_cached_superzombie_enabled = get_pcvar_num(cvar_superzombie_enabled);
	g_cached_multi_chance = get_pcvar_num(cvar_multi_chance);
	g_cached_multi_min_players = get_pcvar_num(cvar_multi_min_players);

	// Cvars Humans
	g_cached_human_health = get_pcvar_num(cvar_human_health);
	g_cached_human_speed = get_pcvar_float(cvar_human_speed);
	g_cached_human_gravity = get_pcvar_float(cvar_human_gravity);
}

// Returns true if the primary weapon at the given index is allowed by its individual cvar.
// Assumes index is valid (0 <= index < sizeof(g_primary_weapons)).
bool:is_primary_weapon_allowed(index)
{
	// Safety: prevent out of bounds (though caller should ensure it)
	if(index < 0 || index >= sizeof(g_primary_cvar))
	{
		return false;
	}
	
	// If the cvar exists and is non-zero, the weapon is allowed.
	// (g_primary_cvar[index] is a pointer; get_pcvar_num returns 0 or 1)
	return (g_primary_cvar[index] && get_pcvar_num(g_primary_cvar[index]) != 0);
}

bool:is_weapon_allowed_by_cvars(weaponid)
{
	// If the weapon is a null weapon (knife, grenades, C4, flashbang), allow it always
	if(is_null_weapon(weaponid))
	{
		return true;
	}
	
	// Check if it's a primary weapon with an individual cvar
	for(new i = 0; i < sizeof(g_primary_weapons); i++)
	{
		if(g_primary_weapons[i][WeaponID] == weaponid)
		{
			return is_primary_weapon_allowed(i);
		}
	}
	
	// For pistols or other weapons (like shield), allow by default
	return true;
}

// Resets all player-specific variables to their default values.
stock reset_vars(id)
{
	// Reset weapons
	g_primary_weapon[id] = 0;
	g_secondary_weapon[id] = 0;
	g_grenades[id] = 0;
	g_primary_saved[id] = 0;
	g_secondary_saved[id] = 0;
	g_grenades_saved[id] = 0;
	BIT_CLEAR(g_bitAutoRepickWeps, id);
	g_menu_offset[id] = 0;
	g_menu_count[id] = 0;
	
	// Reset player type flags
	BIT_CLEAR(g_bitZombie, id);
	BIT_CLEAR(g_bitHuman, id);
	BIT_CLEAR(g_bitFirstZombie, id);
	BIT_CLEAR(g_bitSuperZombie, id);
	BIT_CLEAR(g_bitZombieNominee, id);
	BIT_CLEAR(g_bitHasGlow, id);
	
	// Reset connection and first-time flags
	BIT_CLEAR(g_bitFirstConnection, id);
}

// Drop primary/secondary weapons
stock drop_weapons(id, dropwhat)
{
	// Get user weapons
	new weapons[32], num_weapons, index, index2, weaponid, weaponid2, dropammo = true;
	get_user_weapons(id, weapons, num_weapons);
	
	// Weapon bitsums
	const PRIMARY_WEAPONS_BIT_SUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)
	const SECONDARY_WEAPONS_BIT_SUM = (1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_FIVESEVEN)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_DEAGLE)	
	
	// Loop through them and drop primaries or secondaries
	for(index = 0; index < num_weapons; index++)
	{
		// Prevent re-indexing the array
		weaponid = weapons[index];
		
		if((dropwhat == 1 && ((1<<weaponid) & PRIMARY_WEAPONS_BIT_SUM)) || (dropwhat == 2 && ((1<<weaponid) & SECONDARY_WEAPONS_BIT_SUM)))
		{
			// Get weapon entity
			new wname[32], weapon_ent;
			get_weaponname(weaponid, wname, charsmax(wname));
			weapon_ent = find_ent_by_owner(-1, wname, id);
			
			// Check if another weapon uses same type of ammo first
			for(index2 = 0; index2 < num_weapons; index2++)
			{
				// Prevent re-indexing the array
				weaponid2 = weapons[index2];
				
				// Only check weapons that we are not going to drop
				if((dropwhat == 1 && ((1<<weaponid2) & SECONDARY_WEAPONS_BIT_SUM)) || (dropwhat == 2 && ((1<<weaponid2) & PRIMARY_WEAPONS_BIT_SUM)))
				{
					if(g_ammo_ids[weaponid2] == g_ammo_ids[weaponid])
					{
						dropammo = false;
					}
				}
			}
			
			// Drop weapon's BP Ammo too?
			if(dropammo)
			{
				// Hack: store weapon bpammo on PEV_ADDITIONAL_AMMO
				entity_set_int(weapon_ent, ADDITIONAL_AMMO, cs_get_user_bpammo(id, weaponid));
				cs_set_user_bpammo(id, weaponid, 0)
			}
			
			// Player drops the weapon
			engclient_cmd(id, "drop", wname);
		}
	}
}

// Helper function to precache an array of sounds
stock precache_sound_array(const soundArray[][], size)
{
	for(new i = 0; i < size; i++)
	{
		precache_sound(soundArray[i]);
	}
}

// Helper: precache an array of models, store valid ones, apply fallback if none.
// Usage: precache_player_models(ZombieModelArray, sizeof(ZombieModelArray), g_ValidZombieModels, "zombie", g_iValidZombieCount);
stock precache_player_models(const models[][], count, dest[][], max_name_len, const fallback[], &valid_count)
{
	valid_count = 0;
	
	for(new i = 0; i < count; i++)
	{
		new szPath[100];
		formatex(szPath, charsmax(szPath), "models/player/%s/%s.mdl", models[i], models[i]);
		
		if(file_exists(szPath, true))
		{
			precache_model(szPath);
			
			new szTPath[100];
			formatex(szTPath, charsmax(szTPath), "models/player/%s/%sT.mdl", models[i], models[i]);
			if(file_exists(szTPath))
			{
				precache_model(szTPath);
			}
			
			copy(dest[valid_count], max_name_len, models[i]);
			valid_count++;
		}
		else
		{
			log_amx("[ZM] Model not found: %s", szPath);
		}
	}
	
	if(valid_count == 0)
	{
		new szFallbackPath[100];
		formatex(szFallbackPath, charsmax(szFallbackPath), "models/player/%s/%s.mdl", fallback, fallback);
		precache_model(szFallbackPath);
		copy(dest[0], max_name_len, fallback);
		valid_count = 1;
		log_amx("[ZM] No valid custom models. Using fallback: %s", fallback);
	}
}

stock PlaySound(id, const sound[])
{
	(equal(sound[strlen(sound)-4], ".mp3")) ? client_cmd(id == 0 ? 0 : id, "mp3 play ^"sound/%s^"", sound) : client_cmd(id == 0 ? 0 : id, "spk ^"sound/%s^"", sound);
}

/*========================================================*\
||::::::::::::::::::::::::::::::::::::::::::::::::::::::::||
||-----------[ Zombies and Humans Management ]------------||
||::::::::::::::::::::::::::::::::::::::::::::::::::::::::||
\*========================================================*/

// Zombie selection task
public task_select_a_zombie()
{
	// Check minimum players
	new alive_count = GetAliveCount();
	new min_players = g_cached_min_players;
	
	if(alive_count < min_players)
	{
		// We don't have enough players
		g_enough_players = false;
		
		// Show message
		set_hudmessage(255, 100, 0, -1.0, 0.4, 1, 6.0, 1.0, 0.1, 0.2, -1);
		ShowSyncHudMsg(0, g_msg_sync, "%L", LANG_PLAYER, "HUD_NOT_ENOUGH_PLAYERS", min_players);
		
		// Check if the sum reaches the minimum to schedule a restart
		new deadcount = GetDeadCount();
		if((alive_count + deadcount) >= min_players)
		{
			// There's no need to keep trying because the restart is going to happen
			schedule_restart_once();
			remove_task(TASK_MAKEZOMBIE);
			return;
		}
   		
		// Schedule task 
		remove_task(TASK_MAKEZOMBIE);
		set_task(1.0, "task_select_a_zombie", TASK_MAKEZOMBIE);
		return;
	}
	
	// We have enough players
	g_enough_players = true;
	
	// Define gamemodes
	const MODE_NORMAL = 0;
	const MODE_MULTI = 1;
	const MODE_SUPER = 2;
	
	// Default mode
	new mode = MODE_NORMAL;

	// Check if Super Zombie is enabled
	if(g_cached_superzombie_enabled)
	{
		// Rolls for Super Zombie using its chance
		new roll = random_num(1, g_cached_superzombie_chance);
		
		if(roll == 1)
		{
			mode = MODE_SUPER; // Super Zombie
		}
		else
		{
			// Roll for Multiple Infection
			if(random_num(1, g_cached_multi_chance) == 1 && alive_count >= g_cached_multi_min_players)
			{
				mode = MODE_MULTI;
			}
		}
	}
	else
	{
		// Super Zombie disabled, only Normal or Multiple Infection
		if(random_num(1, g_cached_multi_chance) == 1 && alive_count >= g_cached_multi_min_players)
		{
			mode = MODE_MULTI;
		}
	}
	
	switch(mode)
	{
		case MODE_NORMAL: start_infection_mode();
		case MODE_SUPER:  start_super_zombie_mode();
		case MODE_MULTI:  start_multi_infection_mode();
		default: start_infection_mode(); // Fallback
	}
	
	// Notify round start
	g_newround = false;
	ExecuteForward(g_fwd_infection_begin, g_fwd_result);
}

// Normal Mode: first zombie selection
public start_infection_mode()
{
	new first_zombie = -1;
	new nominee_count = ZombiesNomineeCount();
	new nominee_chance = random_num(1,3);
	
	// Use nominee if possible
	if(nominee_count > 0 && nominee_chance == 1)
	{
		first_zombie = GetRandomAliveCount(random_num(1, nominee_count), 1);
	}
	
	// Pick random alive player
	if(first_zombie == -1)
	{
		first_zombie = GetRandomAliveCount(random_num(1, GetAliveCount()), 0);
	}
	
	// Safeguard
	if(first_zombie == -1)
	{
		log_amx("Zombie selection failed: no valid player found.");
		set_task(1.0, "task_select_a_zombie", TASK_MAKEZOMBIE);
		return;
	}
	
	BIT_SET(g_bitFirstZombie, first_zombie);
	g_selected_firstzombie = true;
	
	set_hudmessage(255, 0, 0, -1.0, 0.17, 0, 6.0, 5.0);
	show_hudmessage(0, "%L", LANG_PLAYER, "HUD_FIRSTZOMBIE", g_playername[first_zombie]);
	
	task_infect_user(first_zombie, 0, 0);
	
	client_print(0, print_center, "%L", LANG_PLAYER, "ZOMBIES_COMING");
	
	// Force all alive non-zombie players to CT
	for(new i = 1; i <= g_maxplayers; i++)
	{
		if(!BIT_CHECK(g_bitAlive, i) || BIT_CHECK(g_bitZombie, i))
		{
			continue;
		}
		
		if(cs_get_user_team(i) != CS_TEAM_CT)
		{
			cs_set_player_team(i, CS_TEAM_CT);
		}
	}
	
	g_infectionround = true;
}

// Super Zombie Mode
public start_super_zombie_mode()
{
	new first_zombie = -1;
	new nominee_count = ZombiesNomineeCount();
	new nominee_chance = random_num(1,3);
	
	// Use nominee if possible
	if(nominee_count > 0 && nominee_chance == 1)
	{
		first_zombie = GetRandomAliveCount(random_num(1, nominee_count), 1);
	}
	
	// Pick random alive player
	if(first_zombie == -1)
	{
		first_zombie = GetRandomAliveCount(random_num(1, GetAliveCount()), 0);
	}
	
	// Fallback: safeguard
	if(first_zombie == -1)
	{
		log_amx("Super Zombie selection failed: no valid player found.");
		set_task(1.0, "task_select_a_zombie", TASK_MAKEZOMBIE);
		return;
	}
	
	BIT_SET(g_bitFirstZombie, first_zombie);
	g_selected_firstzombie = true;
	
	set_hudmessage(100, 255, 0, -1.0, 0.17, 1, 6.0, 8.0);
	show_hudmessage(0, "%L", LANG_PLAYER, "HUD_SUPERZOMBIE", g_playername[first_zombie]);
	
	task_infect_user(first_zombie, 0, 1);
	
	PlaySound(0, superappears);
	client_print(0, print_center, "%L", LANG_PLAYER, "SUPERZOMBIE_COMING");
	
	for(new i = 1; i <= g_maxplayers; i++)
	{
		if(!BIT_CHECK(g_bitAlive, i) || BIT_CHECK(g_bitZombie, i))
		{
			continue;
		}
		
		if(cs_get_user_team(i) != CS_TEAM_CT)
		{
			cs_set_player_team(i, CS_TEAM_CT);
		}
	}
	
	g_superround = true;
}

// Multiple Infection Mode
public start_multi_infection_mode()
{
	g_selected_firstzombie = true;
	
	// Count alive players and calculate number of zombies
	new alive_count = GetAliveCount();
	new max_zombies = floatround(alive_count / 6.0, floatround_ceil);
	new assigned = 0;
	new id;
	
	// Show HUD notification for multiple infection
	set_hudmessage(255, 255, 0, -1.0, 0.17, 1, 6.0, 8.0); 
	show_hudmessage(0, "%L", LANG_PLAYER, "HUD_MULTIINFECTION");
	
	// Display center-screen message to all players
	client_print(0, print_center, "%L", LANG_PLAYER, "ZOMBIES_COMING");
	
	// Play entry sound for all
	PlaySound(0, superappears);
	
	// Randomly select max_zombies players and turn them into zombiES
	while(assigned < max_zombies)
	{
		// Pick random alive player
		id = GetRandomAliveCount(random_num(1, alive_count), 0);
		
		// Skip if dead or already a zombie
		if(!BIT_CHECK(g_bitAlive, id) || BIT_CHECK(g_bitZombie, id))
		{
			continue;
		}
		
		// Transform player into zombie
		task_infect_user(id, 0, 0);
		assigned++;
	}
	
	// Loop through all alive non-zombie players and force them to be CTs
	for(id = 1; id <= g_maxplayers; id++)
	{
		if(!BIT_CHECK(g_bitAlive, id)|| BIT_CHECK(g_bitZombie, id))
		{
			continue;
		}
		cs_set_player_team(id, CS_TEAM_CT);
	}
	
	g_multiround = true;
}

// Manages the infection process between players
public task_infect_user(victim, attacker, superzombie)
{
	// Only adjust attacker's health if attacker is valid
	if(is_valid_player_alive(attacker))
	{
		new BrainHealth = g_cached_zombie_brainhealth + get_user_health(attacker);
		set_user_health(attacker, BrainHealth);
	}
	
	// Transform victim to zombie or superzombie based on param
	task_make_zombie(victim, superzombie);
	
	// Execute night vision command on client
	client_cmd(victim, "nightvision");
	
	// Execute custom forward for additional logic/plugins
	ExecuteForward(g_fwd_user_infected, g_fwd_result, victim, attacker);
}

// Task to convert a player into a human
public task_make_human(id)
{
	// Check if player is valid
	if(!is_valid_player_alive(id))
	{
		return;
	}
	
	// Set the player as a human
	BIT_SET(g_bitHuman, id);
	BIT_CLEAR(g_bitZombie, id);
	BIT_CLEAR(g_bitSuperZombie, id);
	BIT_CLEAR(g_bitFirstZombie, id);
	BIT_CLEAR(g_bitZombieNominee, id);
	
	// Assign a random player model
	(g_iValidHumanCount > 0) ? cs_set_user_model(id, g_ValidHumanModels[random(g_iValidHumanCount)]) : cs_set_user_model(id, "urban"); 
	cs_set_player_view_model(id, CSW_KNIFE, HumanKnife);
	cs_reset_player_weap_model(id, CSW_KNIFE);
	
	// Set the human's health, gravity, speed
	set_user_health(id, g_cached_human_health);
	set_user_gravity(id, g_cached_human_gravity);
	set_user_maxspeed(id, g_cached_human_speed);
		
	// Remove glow if player was super zombie before
	if(BIT_CHECK(g_bitHasGlow, id))
	{
		set_user_rendering(id);
		BIT_CLEAR(g_bitHasGlow, id);
	}
	
	// Open menu or assign bot weapons
	if(g_newround)
	{
		BIT_CHECK(g_bitBot, id) ? set_task(0.5, "bot_weapons", id) : set_task(0.1, "task_menuweapons", id);
	}
	else // In case admin transforms someone into human if zombie or player left and its chosen as new human 
	{
		cs_set_player_team(id, CS_TEAM_CT);
		BIT_CHECK(g_bitBot, id) ? set_task(0.1, "bot_weapons", id) : set_task(0.1, "task_menuweapons", id);
	}
	
	// Notify the player
	client_print_color(id, print_team_default, "^4[ZM] ^1%L", LANG_PLAYER, "INFO_HUMAN");

	// Exec custom forward
	ExecuteForward(g_fwd_user_cured, g_fwd_result, id);
}

// Combined function: make a player into a zombie (normal or super)
public task_make_zombie(id, superzombie)
{
	// Safety check
	if(!is_valid_player_alive(id))
	{
		return;
	}
	
	// Mark player as zombie (clear human flag)
	BIT_CLEAR(g_bitHuman, id);
	BIT_SET(g_bitZombie, id);
	
	// Set super zombie flag if needed
	superzombie ? BIT_SET(g_bitSuperZombie, id) : BIT_CLEAR(g_bitSuperZombie, id);
	
	// --- Set team and model ---
	cs_set_player_team(id, CS_TEAM_T);
	superzombie ? (g_iValidSuperCount > 0) ? cs_set_user_model(id, g_ValidSuperModels[random(g_iValidSuperCount)]) : cs_set_user_model(id, "zombie") : (g_iValidZombieCount > 0) ? cs_set_user_model(id, g_ValidZombieModels[random(g_iValidZombieCount)]) : cs_set_user_model(id, "zombie");
	
	// --- Strip weapons and give knife ---
	drop_weapons(id, 1);
	drop_weapons(id, 2);
	strip_user_weapons(id);
	give_item(id, "weapon_knife");
	cs_set_player_weap_model(id, CSW_KNIFE, "");
	cs_set_player_view_model(id, CSW_KNIFE, superzombie ? SuperKnife : ZombieKnife);
	
	// --- Remove flashlight if active ---
	new effects = entity_get_int(id, EV_INT_effects);
	if(effects & EF_DIMLIGHT)
	{
		entity_set_int(id, EV_INT_effects, effects & ~EF_DIMLIGHT);
		message_begin(MSG_ONE, g_MsgFlashlight, _, id);
		write_byte(0);
		write_byte(100);
		message_end();
	}
	
	// --- Set stats (health, gravity, speed) ---
	new health, Float:gravity, Float:speed;
	
	if(superzombie)
	{
		health = g_cached_superzombie_health;
		gravity = g_cached_superzombie_gravity;
		speed = g_cached_superzombie_speed;
		
		// Super zombie glow effect
		set_user_rendering(id, kRenderFxGlowShell, 0, 255, 0, kRenderNormal, 5);
		BIT_SET(g_bitHasGlow, id);
	}
	else
	{
		// Normal zombie: first zombie gets extra health
		health = BIT_CHECK(g_bitFirstZombie, id) ? g_cached_firstzombie_health : g_cached_zombie_health;
		gravity = g_cached_zombie_gravity;
		speed = g_cached_zombie_speed;
		
		// Infection sound for non-first zombies
		if(!BIT_CHECK(g_bitFirstZombie, id))
		{
			emit_sound(id, CHAN_AUTO, zombie_infect[random_num(0, sizeof(zombie_infect) - 1)], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		}
	}
	
	set_user_gravity(id, gravity);
	set_user_maxspeed(id, speed);
	set_user_health(id, health);
	cs_set_user_armor(id, 0, CS_ARMOR_NONE);
	
	// --- Final messages and night vision ---
	client_print_color(id, print_team_default, "^4[ZM] ^1%L", LANG_PLAYER, superzombie ? "INFO_SUPERZOMBIE" : "INFO_ZOMBIE");
	client_cmd(id, "nightvision");
}

/*========================================================*\
||::::::::::::::::::::::::::::::::::::::::::::::::::::::::||
||-------------------[ Bot Handling ]---------------------||
||::::::::::::::::::::::::::::::::::::::::::::::::::::::::||
\*========================================================*/

public force_bot_nominate()
{
	new start = random_num(1, g_maxplayers);
	new id;
	
	// Allow Nominate??
	if(random_num(1, 4) == 1)
	{
		for(new i = 0; i < g_maxplayers; i++)
		{
			id = start + i;
			
			if(id > g_maxplayers)
			{
				id -= g_maxplayers;
			}
			
			if(!BIT_CHECK(g_bitAlive, id))
			{
				continue;
			}
			
			if(!BIT_CHECK(g_bitBot, id))
			{
				continue;
			}
			
			if(BIT_CHECK(g_bitZombieNominee, id))
			{
				continue;
			}
			
			BIT_SET(g_bitZombieNominee, id);
			client_print_color(0, print_team_default, "^4[ZM] ^1%L", LANG_PLAYER, "TXT_NOMINATED", g_playername[id]);
			return;
		}
	}
}

// Main Function to assign weapons to bots
public bot_weapons(id)
{	
	if(!BIT_CHECK(g_bitBot, id))
	{
		return;
	}
	
	// Remove previous weapons and give the user a knife
	strip_user_weapons(id);
	give_item(id, "weapon_knife");
	
	set_task(0.2, "assign_primary_weapon", id);
	set_task(0.3, "assign_secondary_weapon", id);
	set_task(0.4, "grant_nades", id);
}

// Assign primary weapon safely
public assign_primary_weapon(id)
{
	if(!is_valid_player_alive(id))
	{
		return;
	}
	
	new validPrimaries[32], count = 0, weaponid;
	
	for(new i = 0; i < sizeof(g_primary_weapons); i++)
	{
		weaponid = g_primary_weapons[i][WeaponID];
		
		// Skip invalid weapon categories based on cvars
		if(((weaponid == CSW_M3 || weaponid == CSW_XM1014) && !g_cached_weapons_shotguns) ||((weaponid == CSW_TMP || weaponid == CSW_MP5NAVY || weaponid == CSW_MAC10  ||weaponid == CSW_P90 || weaponid == CSW_UMP45) && !g_cached_weapons_smgs) ||((weaponid == CSW_FAMAS || weaponid == CSW_GALIL || weaponid == CSW_AK47 || weaponid == CSW_M4A1 || weaponid == CSW_SG552 || weaponid == CSW_AUG) && !g_cached_weapons_rifles) ||((weaponid == CSW_SCOUT || weaponid == CSW_AWP) && !g_cached_weapons_snipers) ||((weaponid == CSW_SG550 || weaponid == CSW_G3SG1) && !g_cached_weapons_autosnipers))
		{
			continue;
		}
		
		// Skip invalid weapons based on cvars
		if(!is_primary_weapon_allowed(i))
		{
			continue;
		}
		
		validPrimaries[count++] = i;
	}
	
	if(count > 0)
	{
		new index = validPrimaries[random(count)]; 
		give_item(id, g_primary_weapons[index][EntityName]);
		cs_set_user_bpammo(id, g_primary_weapons[index][WeaponID], g_primary_weapons[index][MaxBPAmmo]);	
	}
	else
	{
		give_item(id, "weapon_m249");
		cs_set_user_bpammo(id, CSW_M249, 200);
	}
}

// Assign secondary weapon with delay
public assign_secondary_weapon(id)
{
	if(!is_valid_player_alive(id))
	{
		return;
	}
	
	new index = random(sizeof(g_secondary_weapons));
	give_item(id, g_secondary_weapons[index][EntityName]);
	cs_set_user_bpammo(id, g_secondary_weapons[index][WeaponID], g_secondary_weapons[index][MaxBPAmmo]);
}

// Grant nades with delay
public grant_nades(id)
{
	give_item(id, "weapon_hegrenade");
	give_item(id, "weapon_smokegrenade");
}

/*========================================================*\
||::::::::::::::::::::::::::::::::::::::::::::::::::::::::||
||---------------------[ Natives ]------------------------||
||::::::::::::::::::::::::::::::::::::::::::::::::::::::::||
\*========================================================*/

// Native: zmod_is_active
public native_zmod_is_active()
{
	return get_pcvar_num(cvar_enabled);
}

// Native: zmod_is_weapon_allowed
public native_zmod_is_weapon_allowed(weaponid)
{
	if(weaponid < 1 || weaponid > 31)
	{
		log_error(AMX_ERR_NATIVE, "[ZM] Invalid weapon id %d", weaponid);
		return -1;
	}
	
	return is_weapon_allowed_by_cvars(weaponid);
}

// Native: zmod_assign_primary_weapon
public native_zmod_assign_primary_weapon(id)
{
	if(!is_valid_player_alive(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZM] Invalid player %d", id);
		return -1;
	}
	
	set_task(0.1, "assign_primary_weapon", id);
	return 1;
}

// Native: zmod_assign_secondary_weapon
public native_zmod_assign_secondary_weapon(id)
{
	if(!is_valid_player_alive(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZM] Invalid player %d", id);
		return -1;
	}
	
	set_task(0.1, "assign_secondary_weapon", id);
	return 1;
}

// Native: zmod_assign_grenades
public native_zmod_assign_grenades(id)
{
	if(!is_valid_player_alive(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZM] Invalid player %d", id);
		return -1;
	}
	
	set_task(0.1, "grant_nades", id);
	return 1;
}

// Native: zmod_get_user_zombie
public native_zmod_get_user_zombie(id)
{
	if(!is_valid_player(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZM] Invalid Player (%d)", id)
		return -1;
	}
	
	return BIT_CHECK(g_bitZombie, id);
}

// Native: zmod_get_user_first_zombie
public native_zmod_get_user_first_zombie(id)
{
	if(!is_valid_player(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZM] Invalid Player (%d)", id)
		return -1;
	}
	
	return BIT_CHECK(g_bitFirstZombie, id);
}

// Native: zmod_get_user_superzombie
public native_zmod_get_user_superzombie(id)
{
	if(!is_valid_player(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZM] Invalid Player (%d)", id)
		return -1;
	}
	
	return BIT_CHECK(g_bitSuperZombie, id);
}

// Native: zmod_get_user_human
public native_zmod_get_user_human(id)
{
	if(!is_valid_player(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZM] Invalid Player (%d)", id)
		return -1;
	}
	
	return BIT_CHECK(g_bitHuman, id);
}

// Native: zmod_has_round_started
public native_zmod_has_round_started()
{
	if(g_newround)
	{
		return 0; // not started
	}
	
	if(g_selected_firstzombie)
	{
		return 1; // started
	}
	
	return 2; // starting
}

// Native: zmod_get_human_count
public native_zmod_get_human_count()
{
	return HumansCount();
}

// Native: zmod_get_zombie_count
public native_zmod_get_zombie_count()
{
	return ZombiesCount();
}

// Native: zmod_is_round_infection
public native_zmod_is_round_infection()
{
	return g_infectionround;
}

// Native: zmod_is_round_super
public native_zmod_is_round_super()
{
	return g_superround;
}

// Native: zmod_is_round_multi
public native_zmod_is_round_multi()
{
	return g_multiround;
}

// Native: zmod_force_transform_human
public native_zmod_force_transform_human(id)
{
	if(!is_valid_player_alive(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZM] Invalid Player (%d)", id)
		return -1;
	}
	
	// First check if the player isn't a human and have more than 1 zombie remaining
	if(!BIT_CHECK(g_bitHuman, id) && ZombiesCount() > 1)
	{
		task_make_human(id);
		return 1; // Transformation succsesful
	}
	else 
	{
		return 0; // Transformation failed
	}
}

// Native: zmod_force_transform_zombie
public native_zmod_force_transform_zombie(id)
{
	if(!is_valid_player_alive(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZM] Invalid Player (%d)", id)
		return -1;
	}
	
	// First check if the player isn't a zombie and have more than 1 human remaining
	if(!BIT_CHECK(g_bitZombie, id) && HumansCount() > 1)
	{
		task_infect_user(id, 0, 0);
		return 1; // Transformation succsesful
	}
	else 
	{
		return 0; // Transformation failed
	}
}

// Native: zmod_force_transform_super_zombie
public native_zmod_force_transform_super_zombie(id)
{
	if(!is_valid_player_alive(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZM] Invalid Player (%d)", id)
		return -1;
	}
	
	// First check if the player isn't a super zombie and have more than 1 human remaining
	if(!BIT_CHECK(g_bitSuperZombie, id) && HumansCount() > 1)
	{
		task_infect_user(id, 0, 1);
		return 1; // Transformation succsesful
	}
	else 
	{
		return 0; // Transformation failed
	}
}

/*========================================================*\
||::::::::::::::::::::::::::::::::::::::::::::::::::::::::||
||------------------[ Player Menus ]----------------------||
||::::::::::::::::::::::::::::::::::::::::::::::::::::::::||
\*========================================================*/

// Determines whether to restore saved weapons or open the weapon menu
public is_autorepick_active(id)
{
	if(BIT_CHECK(g_bitAutoRepickWeps, id))
	{
		// Auto repick is enabled, restore saved weapons to current
		g_primary_weapon[id] = g_primary_saved[id];
		g_secondary_weapon[id] = g_secondary_saved[id];
		g_grenades[id] = g_grenades_saved[id];
		return true;
	}
	else
	{
		// Auto repick disabled, clear current weapon selections
		g_primary_weapon[id] = 0;
		g_secondary_weapon[id] = 0;
		g_grenades[id] = 0;
		return false;
	}
}

// Handles the task of opening the weapon menu or restoring the player's saved loadout
public task_menuweapons(id)
{
	// First we check if weapon menu is enabled
	if(!g_cached_weapons_display) 
	{
		// Inform player
		client_print_color(id, print_team_default, "^4[ZM] ^1%L", LANG_PLAYER, "MENU_WEPS_DISABLED");
		
		// Remove previous weapons and give the user a knife
		strip_user_weapons(id);
		give_item(id, "weapon_knife");
		
		// Assign weapons
		set_task(0.1, "assign_primary_weapon", id);
		set_task(0.2, "assign_secondary_weapon", id);
		set_task(0.3, "grant_nades", id);
		
		// Exit
		return;
	}
	// Check if we need to restore loadout or open weapon menu
	else
	{
		is_autorepick_active(id) ? set_task(0.1, "weapon_loadout_restore", id) : set_task(0.1, "weapon_menu_main", id);
	}
}

// Displays the primary weapon selection menu
public weapon_menu_main(id)
{
	// Menu buffer
	static szMenu[512];
	
	// Length of the string, key mask, and enabled options count
	new iLen, keys, count;
	
	// Title
	iLen += formatex(szMenu[iLen], charsmax(szMenu)-iLen, "\y%L^n^n", LANG_PLAYER, "MENU_WEPS_TITLE");

	// Store cvar values to determine which categories are enabled
	new cvars[5];
	cvars[0] = g_cached_weapons_shotguns;
	cvars[1] = g_cached_weapons_smgs;
	cvars[2] = g_cached_weapons_rifles;
	cvars[3] = g_cached_weapons_snipers;
	cvars[4] = g_cached_weapons_autosnipers;
	
	// Language keys for each weapon category
	new const lang_keys[][] = {"MENU_WEPS_SHOTGUNS", "MENU_WEPS_SMGS", "MENU_WEPS_RIFLES", "MENU_WEPS_SNIPERS", "MENU_WEPS_AUTOSNIPERS"};

	// Loop through categories
	for(new i = 0; i < 5; i++)
	{
		// If this category is enabled via cvar
		if(cvars[i])
		{
			// Add menu option with index and localized text
			iLen += formatex(szMenu[iLen], charsmax(szMenu)-iLen, "\r%d. \w%L^n", i+1, LANG_PLAYER, lang_keys[i]);
			
			// Enable corresponding key
			keys |= (1<<i);
			
			// Increase count of visible options
			count++;
		}
	}

	// Add empty lines to keep menu visually aligned
	for(new i = count; i < 5; i++)
	{
		iLen += formatex(szMenu[iLen], charsmax(szMenu)-iLen, "^n");
	}

	// Auto Repick toggle option (localized ON/OFF state)
	iLen += formatex(szMenu[iLen], charsmax(szMenu)-iLen, "^n\r6. \y%L^n", LANG_PLAYER, BIT_CHECK(g_bitAutoRepickWeps, id) ? "MENU_AUTO_SAVE_ON" : "MENU_AUTO_SAVE_OFF");
	keys |= MENU_KEY_6;

	// Fix for AMXX custom menus
	set_pdata_int(id, OFFSET_CSMENUCODE, 0);
	
	// Show the menu to the player
	show_menu(id, keys, szMenu, -1, "Zombie Mod Weapons Menu");
}

// Handles the main weapon menu selection
public weapon_menu_handler(id, key)
{
	// Check if the player is disconnected, dead, or a zombie 
	if(!BIT_CHECK(g_bitConnected, id) || !BIT_CHECK(g_bitAlive, id) || BIT_CHECK(g_bitZombie, id))
	{
		return PLUGIN_HANDLED;
	}
	
	switch(key)
	{
		case 0: show_primary_menu(id, 0, 2, "MENU_SHOTGUN_TITLE"); // Shotguns
		case 1: show_primary_menu(id, 2, 5, "MENU_SMG_TITLE"); // SMGs
		case 2: show_primary_menu(id, 7, 6, "MENU_RIFLE_TITLE"); // Rifles
		case 3: show_primary_menu(id, 13, 2, "MENU_SNIPERS_TITLE"); // Snipers
		case 4: show_primary_menu(id, 15, 2, "MENU_AUTOSNIPERS_TITLE"); // Auto Snipers
		case 5:
		{
			// If auto-repick is enabled, disable it
			if(BIT_CHECK(g_bitAutoRepickWeps, id))
			{
				BIT_CLEAR(g_bitAutoRepickWeps, id);
				g_primary_weapon[id] = 0;
				g_secondary_weapon[id] = 0;
				g_grenades[id] = 0;
			}
			// If auto-repick is disabled, enable it and save last selections
			else
			{
				BIT_SET(g_bitAutoRepickWeps, id);
				g_primary_weapon[id] = g_primary_saved[id];
				g_secondary_weapon[id] = g_secondary_saved[id];
				g_grenades[id] = g_grenades_saved[id];
			}	
			// Reopen the main weapon menu
			weapon_menu_main(id)
		}
	}
	
	return PLUGIN_HANDLED;
}

public show_primary_menu(id, start, count, const title[])
{
	static menu[512], name[32];
	new len, keys;
	new visible_count = 0;
	new visible_indices[32];  
	
	// Títle
	len += formatex(menu[len], charsmax(menu)-len, "\y%L^n^n", LANG_PLAYER, title);
	
	// Loop through the range of weapons in this category
	for(new i = 0; i < count; i++)
	{
		new index = start + i;
		
		// Filter by individual cvar (the category was already validated earlier)
		if(!is_primary_weapon_allowed(index))
		{
			continue;
		}
		
		// Save the real index
		visible_indices[visible_count] = index;
		
		// Weapon name
		g_cached_weapon_alt_names ? copy(name, charsmax(name), g_primary_weapons[index][AltName]) : copy(name, charsmax(name), g_primary_weapons[index][WeaponName]);
		
		// Add to menu (numbering starts at 1)
		len += formatex(menu[len], charsmax(menu)-len, "\r%d. \w%s^n", visible_count+1, name);
		keys |= (1<<visible_count);
		visible_count++;
	}
	
	// If no weapons available in this category
	if(visible_count == 0)
	{
		client_print_color(id, print_team_default, "^4[ZM] ^1%L", LANG_PLAYER, "TXT_WEAPONS_NOT_AVAILABLE");
		weapon_menu_main(id);
		return;
	}
	
	// Save the real indices in the global array for the handler
	for(new i = 0; i < visible_count; i++)
	{
		g_visible_weapons[id][i] = visible_indices[i];
	}
	
	 // Store how many visible items there are (for validation in the handler)
	g_menu_count[id] = visible_count;
	
	// Add empty lines to keep menu size consistent
	new padding;
	switch(visible_count)
	{
		case 2: padding = 7;
		case 4,5: padding = 6;
		case 6: padding = 5;
		default: padding = 5;
	}
	
	for(new i = 0; i < padding; i++)
	{
		len += formatex(menu[len], charsmax(menu)-len, "^n");
	}
	
	// "Back" button
	len += formatex(menu[len], charsmax(menu)-len, "\r0. \w%L", id, "MENU_BACK");
	keys |= MENU_KEY_0;
	
	set_pdata_int(id, OFFSET_CSMENUCODE, 0);
	show_menu(id, keys, menu, -1, "Zombie Mod Primary Weapon Menu");
}

public menu_primary_handler(id, key)
{
	// Basic validations
	if(!BIT_CHECK(g_bitConnected, id) || !BIT_CHECK(g_bitAlive, id) || BIT_CHECK(g_bitZombie, id))
	{
		return PLUGIN_HANDLED;
	}
	
	// Key 9 = "Back" (in AMXX menus, key 0 corresponds to key == 9)
	if(key == 9)
	{
		weapon_menu_main(id);
		return PLUGIN_HANDLED;
	}
	
	// Verify that the key is within the range of visible weapons
	if(key < 0 || key >= g_menu_count[id])
	{
		return PLUGIN_HANDLED;
	}
	
	// Get the REAL index of the selected weapon
	new real_index = g_visible_weapons[id][key];
	
	// Save selection
	g_primary_saved[id] = real_index;
	
	// Equip the weapon
	drop_weapons(id, 1);
	give_item(id, g_primary_weapons[real_index][EntityName]);
	cs_set_user_bpammo(id, g_primary_weapons[real_index][WeaponID], g_primary_weapons[real_index][MaxBPAmmo]);
	
	// Next menu (secondary weapons)
	weapon_menu_pistols(id);
	return PLUGIN_HANDLED;
}

public weapon_menu_pistols(id)
{
	// Menu buffer and temporary weapon name
	static menu[512], name[32];
	
	// Current menu length and key mask
	new len, keys;

	// Title
	len += formatex(menu[len], charsmax(menu)-len, "\y%L^n^n", id, "MENU_PISTOL_TITLE");

	for(new i; i < sizeof(g_secondary_weapons); i++)
	{
		// Choose between alternate name or default name
		(get_pcvar_num(cvar_weapon_alt_names)) ? copy(name, charsmax(name), g_secondary_weapons[i][AltName]) : copy(name, charsmax(name), g_secondary_weapons[i][WeaponName]);

		// Add weapon entry to menu
		len += formatex(menu[len], charsmax(menu)-len, "\r%d. \w%s^n", i+1, name);
		
		// Enable corresponding key
		keys |= (1<<i);
	}

	// Fix for AMXX custom menus
	set_pdata_int(id, OFFSET_CSMENUCODE, 0);
	
	// Display menu to player
	show_menu(id, keys, menu, -1, "Zombie Mod Secondary Weapon Menu");
}

public menu_secondary_handler(id, key)
{
	// Ensure player is connected, alive, and not a zombie
	if(!BIT_CHECK(g_bitConnected, id) || !BIT_CHECK(g_bitAlive, id) || BIT_CHECK(g_bitZombie, id))
	{
		return PLUGIN_HANDLED;
	}
	
	// Ignore invalid selections (outside available weapon range)
	if(key >= sizeof(g_secondary_weapons))
	{
		return PLUGIN_HANDLED;
	}

	// Save selected secondary weapon index
	g_secondary_saved[id] = key;   

	// Drop current secondary weapon
	drop_weapons(id, 2);

	// Give selected secondary weapon to player and set correct backpack ammo for the weapon
	give_item(id, g_secondary_weapons[key][EntityName]);
	cs_set_user_bpammo(id, g_secondary_weapons[key][WeaponID], g_secondary_weapons[key][MaxBPAmmo]);

	// Open grenades menu
	weapon_menu_grenades(id);
	return PLUGIN_HANDLED;
}

// Displays the grenade selection menu
public weapon_menu_grenades(id)
{
	static szMenu[256];
	new iLen, keys = 0;
	
	// Title
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y%L^n^n", id, "MENU_NADE_TITLE");
	
	// 1. He Grenade
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r1. \w%L^n", id, "MENU_NADE_HE");
	keys |= MENU_KEY_1;
	
	// 2. Smoke Grenade
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r2. \w%L^n", id, "MENU_NADE_SMOKE");
	keys |= MENU_KEY_2;
	
	// 3. Both Grenades
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r3. \w%L^n", id, "MENU_NADE_BOTH");
	keys |= MENU_KEY_3;

	// 0. None
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n^n^n^n^n^n\r0. \w%L", id, "MENU_NONE");
	keys |= MENU_KEY_0;

	// Fix for AMXX custom menus
	set_pdata_int(id, OFFSET_CSMENUCODE, 0);
	show_menu(id, keys, szMenu, -1, "Zombie Mod Grenades Menu");
}

// Handles the grenade selection menu
public menu_nade_handler(id, key)
{
	// Check if the player is disconnected, dead, or a zombie 
	if(!BIT_CHECK(g_bitConnected, id) || !BIT_CHECK(g_bitAlive, id) || BIT_CHECK(g_bitZombie, id))
	{
		return PLUGIN_HANDLED;
	}
	
	// Give the selected grenade(s) to the player
	switch(key)
	{
		case 0: // He Grenade
		{
			// Give the selected grenade
			give_item(id, "weapon_hegrenade");
			
			// Store selection
			g_grenades_saved[id] = 1;
		}
		case 1: // Smoke Grenade
		{
			// Give the selected grenade
			give_item(id, "weapon_smokegrenade");
			
			// Store selection
			g_grenades_saved[id] = 2;
		}
		case 2: // Both Grenades
		{
			// Give the selected grenades
			give_item(id, "weapon_hegrenade");
			give_item(id, "weapon_smokegrenade");
			
			// Store selection
			g_grenades_saved[id] = 3;
		}
	}
	
	// If the player has saved weapons, remind them about their saved loadout
	if(BIT_CHECK(g_bitAutoRepickWeps, id))
	{
		client_print_color(id, print_team_default, "^4[ZM] ^1%L", LANG_PLAYER, "TXT_SAVEDREMINDER");
	}
	
	// Check if player joined the server for the first time
	if(!BIT_CHECK(g_bitFirstConnection, id))
	{
		// Player has joined for the first time
		BIT_SET(g_bitFirstConnection, id);
		
		// Show the menu
		set_task(0.1, "zm_menu_main", id);
	}
	
	return PLUGIN_HANDLED;
}

// Restores the player's saved loadout once per round
public weapon_loadout_restore(id)
{
	// Validate player state early exit
	if(!BIT_CHECK(g_bitConnected, id) || !BIT_CHECK(g_bitAlive, id))
	{
		return;
	}
	
	// Reset weapons - give knife first (clears old weapons)
	strip_user_weapons(id);
	give_item(id, "weapon_knife");
	
	// PRIMARY
	new prim = g_primary_saved[id];
	if(prim >= 0 && prim < sizeof(g_primary_weapons) && is_primary_weapon_allowed(prim))
	{
		give_item(id, g_primary_weapons[prim][EntityName]);
		cs_set_user_bpammo(id, g_primary_weapons[prim][WeaponID], g_primary_weapons[prim][MaxBPAmmo]);
	}
	else
	{
		assign_primary_weapon(id);
		client_print_color(id, print_team_default, "^4[ZM] ^1%L", LANG_PLAYER, "TXT_WEAPON_NOT_ALLOWED");
	}

	// SECONDARY
	if(g_secondary_saved[id] >= 0 && g_secondary_saved[id] < sizeof(g_secondary_weapons))
	{
		give_item(id, g_secondary_weapons[g_secondary_saved[id]][EntityName])
		cs_set_user_bpammo(id, g_secondary_weapons[g_secondary_saved[id]][WeaponID], g_secondary_weapons[g_secondary_saved[id]][MaxBPAmmo])
	}
	
	// Restore grenades saved 
	switch(g_grenades_saved[id])
	{
		case 1: give_item(id, "weapon_hegrenade");
		case 2: give_item(id, "weapon_smokegrenade");
		case 3:
		{
			give_item(id, "weapon_hegrenade");
			give_item(id, "weapon_smokegrenade");
		}
	}
}

// Displays the main menu of zombie mod 
public zm_menu_main(id)
{
	if(!BIT_CHECK(g_bitConnected, id))
	{
		return;
	}
	
	new menuid = menu_create(fmt("%L\r", id, "MENU_TITLE"), "menu_main_handler");
	
	menu_additem(menuid, fmt("%L", id, "MENU_HELP"), "1");
	menu_additem(menuid, fmt("%L", id, "MENU_ABOUT"), "2");
	
	menu_addblank2(menuid);
	
	menu_additem(menuid, fmt("%L", id, "MENU_REPICK_WEAPONS"), "3");
	
	menu_addblank2(menuid);
	
	menu_additem(menuid, fmt("%L", id, "MENU_CONTACT"), "4");
	menu_additem(menuid, fmt("%L", id, "MENU_JOIN_SPECS"), "5");
	
	//menu_setprop(menuid, MPROP_BACKNAME, fmt("%L", id, "MENU_BACK"));
	//menu_setprop(menuid, MPROP_NEXTNAME, fmt("%L", id, "MENU_NEXT"));
	menu_setprop(menuid, MPROP_EXITNAME, fmt("%L", id, "MENU_EXIT"));
	
	// Clamp remembered page if it exceeds the max page count
	//MENU_PAGE_MAIN = min(MENU_PAGE_MAIN, menu_pages(menuid) - 1);
	
	// Fix for AMXX custom menus
	set_pdata_int(id, OFFSET_CSMENUCODE, 0);
	menu_display(id, menuid, /*MENU_PAGE_MAIN*/0);
}

// Handles the main menu of zombie mod
public menu_main_handler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		client_print_color(id, print_team_default, "^4[ZM] ^1%L", LANG_PLAYER, "TXT_MENUEXIT");
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	
	new data[2], iName[64], iAccess, callback;
	menu_item_getinfo(menu, item, iAccess, data, charsmax(data), iName, charsmax(iName), callback);
	
	// Remember player's menu page
	//static menudummy;
	//player_menu_info(id, menudummy, menudummy, MENU_PAGE_MAIN);
	
	switch(data[0])
	{
		case '1': zm_menu_help(id); // Zombie Mod Help
		case '2': zm_show_motd(id, 5); // About Zombie Mod
		case '3': // Repick Weapons
		{
			if(BIT_CHECK(g_bitAutoRepickWeps, id))
			{
				g_primary_weapon[id] = 0;
				g_secondary_weapon[id] = 0;
				g_grenades[id] = 0;
				BIT_CLEAR(g_bitAutoRepickWeps, id);
				client_print_color(id, print_team_default, "^4[ZM] ^1%L", LANG_PLAYER, "TXT_SAVEDWEPSRESET");
			}
			else
			{
				client_print_color(id, print_team_default, "^4[ZM] ^1%L", LANG_PLAYER, "TXT_SAVEDWEPSRESETERROR");
				zm_menu_main(id);
			}
		}
		case '4': zm_show_motd(id, 6); // Contact Info
		case '5': // Join Spectators
		{
			if(!BIT_CHECK(g_bitAlive, id))
			{
				cs_set_player_team(id, CS_TEAM_SPECTATOR);
			}
			else
			{
				client_print_color(id, print_team_default, "^4[ZM] ^1%L", LANG_PLAYER, "TXT_NO_ACCESS");
			}
		}
	}
	
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

// Displays the zombie mod help menu
public zm_menu_help(id)
{
	static szMenu[512];
	new iLen, keys = 0;

	// Title
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y%L^n^n", id, "MENU_HELP_TITLE");
	
	// 1. Information
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r1. \w%L^n", id, "MENU_HELP_INFORMATION");
	keys |= MENU_KEY_1;
	
	// 2. Commands
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r2. \w%L^n", id, "MENU_HELP_COMMANDS");
	keys |= MENU_KEY_2;
	
	// 3. Humans
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r3. \w%L^n", id, "MENU_HELP_HUMANS");
	keys |= MENU_KEY_3;
	
	// 4. Zombies
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r4. \w%L^n", id, "MENU_HELP_ZOMBIES");
	keys |= MENU_KEY_4;
	
	// 9. Zombie Mod Menu
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n^n^n^n^n\r9. \w%L^n", id, "MENU_HELP_EXIT");
	keys |= MENU_KEY_9;
	
	// 0. Exit
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r0. \w%L", id, "MENU_EXIT");
	keys |= MENU_KEY_0;
	
	// Fix for AMXX custom menus
	set_pdata_int(id, OFFSET_CSMENUCODE, 0);
	show_menu(id, keys, szMenu, -1, "Zombie Mod Help Menu");
}

// Displays the help page of the zombie mod via MOTD, covering gameplay, roles, and commands
public menu_help_handler(id, key)
{
	// Check if the player is connected
	if(!BIT_CHECK(g_bitConnected, id))
	{
		return PLUGIN_HANDLED;
	}
	
	switch(key)
	{
		case 0: zm_show_motd(id, 1); // Information
		case 1: zm_show_motd(id, 2); // Commands
		case 2: zm_show_motd(id, 3); // Humans
		case 3: zm_show_motd(id, 4); // Zombies
		case 8: set_task(0.1, "zm_menu_main", id); // Zombie Mod Menu
		default: return PLUGIN_HANDLED; // Help Menu Exited
	}
	
	// Show help menu again if user wishes to read another topic
	zm_menu_help(id);
	return PLUGIN_HANDLED;
}

// Displays the MOTD for the zombie mod sections
public zm_show_motd(id, section)
{
	// Player disconnected??
	if(!BIT_CHECK(g_bitConnected, id))
	{
		return PLUGIN_HANDLED;
	}
	
	static msg[2047], title[64];
	msg[0] = '^0'; // Clear buffer
	
	// HTML Header
	add(msg, charsmax(msg), "<body bgcolor=#f5f5f5><font color=#000000><br>");
	add(msg, charsmax(msg), "<center><table><tr><td><p><b><font color=#000000>");
	
	switch(section)
	{
		case 1: // Help - Information
		{
			formatex(title, charsmax(title), "%L", id, "HELP_HEADER");
			formatex(msg, charsmax(msg), "%s<h2>%L</h2>", msg, id, "HELP_INFO");
			formatex(msg, charsmax(msg), "%s%L<br>", msg, id, "HELP_INFO2");
			formatex(msg, charsmax(msg), "%s%L<br>", msg, id, "HELP_INFO3");
			formatex(msg, charsmax(msg), "%s%L<br>", msg, id, "HELP_INFO4");
			formatex(msg, charsmax(msg), "%s%L<br>", msg, id, "HELP_INFO5");
			formatex(msg, charsmax(msg), "%s%L<br>", msg, id, "HELP_INFO6");
			formatex(msg, charsmax(msg), "%s%L<br>", msg, id, "HELP_INFO7");
			formatex(msg, charsmax(msg), "%s%L<br>", msg, id, "HELP_INFO8");
			formatex(msg, charsmax(msg), "%s%L<br>", msg, id, "HELP_INFO9");
			formatex(msg, charsmax(msg), "%s%L<br>", msg, id, "HELP_ENJOY");
		}
		case 2: // Help - Commands
		{
			formatex(title, charsmax(title), "%L", id, "HELP_HEADER");
			formatex(msg, charsmax(msg), "%s<h2>%L</h2>", msg, id, "HELP_COMMANDS");
			formatex(msg, charsmax(msg), "%s%L<br>", msg, id, "HELP_COMMANDS2");
			formatex(msg, charsmax(msg), "%s%L<br>", msg, id, "HELP_COMMANDS3");
			formatex(msg, charsmax(msg), "%s%L<br>", msg, id, "HELP_COMMANDS4");
			formatex(msg, charsmax(msg), "%s%L<br>", msg, id, "HELP_COMMANDS5");
			formatex(msg, charsmax(msg), "%s%L<br>", msg, id, "HELP_COMMANDS6", get_pcvar_num(cvar_human_clipcost));
			formatex(msg, charsmax(msg), "%s%L<br>", msg, id, "HELP_COMMANDS7", get_pcvar_num(cvar_human_clipcost));
			formatex(msg, charsmax(msg), "%s%L<br>", msg, id, "HELP_COMMANDS8");
			formatex(msg, charsmax(msg), "%s%L<br>", msg, id, "HELP_COMMANDS9");
			formatex(msg, charsmax(msg), "%s%L<br>", msg, id, "HELP_ENJOY");
		}
		case 3: // Help - Humans
		{
			formatex(title, charsmax(title), "%L", id, "HELP_HEADER");
			formatex(msg, charsmax(msg), "%s<h2>%L</h2>", msg, id, "HELP_HUMAN");
			formatex(msg, charsmax(msg), "%s%L<br>", msg, id, "HELP_HUMAN2");
			formatex(msg, charsmax(msg), "%s%L<br>", msg, id, "HELP_HUMAN3");
			formatex(msg, charsmax(msg), "%s%L<br>", msg, id, "HELP_HUMAN4");
			formatex(msg, charsmax(msg), "%s%L<br>", msg, id, "HELP_HUMAN5");
			formatex(msg, charsmax(msg), "%s%L<br>", msg, id, "HELP_HUMAN6", get_pcvar_num(cvar_human_clipcost));
			formatex(msg, charsmax(msg), "%s%L<br>", msg, id, "HELP_HUMAN7");
			formatex(msg, charsmax(msg), "%s%L<br>", msg, id, "HELP_HUMAN8", get_pcvar_num(cvar_human_health), get_pcvar_float(cvar_human_speed));
			formatex(msg, charsmax(msg), "%s%L<br>", msg, id, "HELP_HUMAN9");
			formatex(msg, charsmax(msg), "%s%L<br>", msg, id, "HELP_ENJOY");
		}
		case 4: // Help - Zombies
		{
			formatex(title, charsmax(title), "%L", id, "HELP_HEADER");
			formatex(msg, charsmax(msg), "%s%L<br>", msg, id, "HELP_ZOMBIE");
			formatex(msg, charsmax(msg), "%s%L<br>", msg, id, "HELP_ZOMBIE2");
			formatex(msg, charsmax(msg), "%s%L<br>", msg, id, "HELP_ZOMBIE3");
			formatex(msg, charsmax(msg), "%s%L<br>", msg, id, "HELP_ZOMBIE4", get_pcvar_num(cvar_zombie_brainhealth));
			formatex(msg, charsmax(msg), "%s%L<br>", msg, id, "HELP_ZOMBIE5", get_pcvar_num(cvar_zombie_health), get_pcvar_float(cvar_zombie_speed));
			formatex(msg, charsmax(msg), "%s%L<br>", msg, id, "HELP_ZOMBIE6");
			formatex(msg, charsmax(msg), "%s%L<br>", msg, id, "HELP_ZOMBIE7");
			formatex(msg, charsmax(msg), "%s%L<br>", msg, id, "HELP_ZOMBIE8", get_pcvar_num(cvar_firstzombie_health) - get_pcvar_num(cvar_zombie_health));
			formatex(msg, charsmax(msg), "%s%L<br>", msg, id, "HELP_ZOMBIE9");
			formatex(msg, charsmax(msg), "%s%L<br>", msg, id, "HELP_ZOMBIE10");
			formatex(msg, charsmax(msg), "%s%L<br>", msg, id, "HELP_ZOMBIE11", get_pcvar_num(cvar_superzombie_health), get_pcvar_float(cvar_superzombie_speed));
			formatex(msg, charsmax(msg), "%s%L<br>", msg, id, "HELP_ENJOY");
		}
		case 5: // About Section
		{
			// Get lighting style
			new lightning_status[16];
			static lightning[2];
			get_pcvar_string(cvar_lightning, lightning, charsmax(lightning));
			formatex(lightning_status, charsmax(lightning_status), "%s", (lightning[0] == '0') ? "OFF" : "ON");
			
			formatex(title, charsmax(title), "%L", id, "ABOUT_HEADER");
			formatex(msg, charsmax(msg), "%s<h2>%L</h2>", msg, id, "ABOUT_TITLE");
			formatex(msg, charsmax(msg), "%s%L<br>", msg, id, "ABOUT_INFO", VERSION);
			formatex(msg, charsmax(msg), "%s%L<br>", msg, id, "ABOUT_INFO2");
			formatex(msg, charsmax(msg), "%s%L<br>", msg, id, "ABOUT_INFO3", lightning_status);
			formatex(msg, charsmax(msg), "%s%L<br>", msg, id, "ABOUT_INFO4");
			formatex(msg, charsmax(msg), "%s%L<br>", msg, id, "ABOUT_INFO5");
			formatex(msg, charsmax(msg), "%s%L<br>", msg, id, "ABOUT_INFO6");
			formatex(msg, charsmax(msg), "%s%L<br>", msg, id, "ABOUT_INFO7");
		}
		case 6: // Contact Section
		{
			formatex(title, charsmax(title), "%L", id, "CONTACT_HEADER");
			formatex(msg, charsmax(msg), "%s<h2>%L</h2>", msg, id, "CONTACT_TITLE");
			formatex(msg, charsmax(msg), "%s%L<br>", msg, id, "CONTACT_INFO");
			formatex(msg, charsmax(msg), "%s%L<br>", msg, id, "CONTACT_INFO2");
			formatex(msg, charsmax(msg), "%s%L<br>", msg, id, "CONTACT_INFO3");
			formatex(msg, charsmax(msg), "%s%L<br>", msg, id, "CONTACT_INFO4");
			formatex(msg, charsmax(msg), "%s%L<br>", msg, id, "CONTACT_INFO5");
			formatex(msg, charsmax(msg), "%s%L<br>", msg, id, "CONTACT_INFO6");
			formatex(msg, charsmax(msg), "%s%L<br>", msg, id, "CONTACT_INFO7");
			formatex(msg, charsmax(msg), "%s%L<br>", msg, id, "CONTACT_INFO8");
			formatex(msg, charsmax(msg), "%s%L<br>", msg, id, "CONTACT_INFO9");
		}
	}
	
	show_motd(id, msg, title);
	return PLUGIN_HANDLED;
}

/*========================================================*\
||::::::::::::::::::::::::::::::::::::::::::::::::::::::::||
||------------------[ Plugin Switch ]---------------------||
||::::::::::::::::::::::::::::::::::::::::::::::::::::::::||
\*========================================================*/

public clcmd_switch(id)
{
	if(!(get_user_flags(id) & ADMIN_RCON))
	{
		client_print_color(id, print_team_default, "^4[ZM] ^1%L", LANG_PLAYER, "TXT_NO_ADMIN");
		return PLUGIN_HANDLED;
	}
	zm_menu_switch(id);
	return PLUGIN_HANDLED;
}

public zm_menu_switch(id)
{
	if(!is_user_connected(id)) 
	{
		return;
	}
	
	new menu = menu_create(fmt("%L\r", id, "MENU_SWITCH_TITLE"), "menu_switch_handler");
	
	menu_additem(menu, fmt("%L", id, "MENU_SWITCH_TURN_ON"),  "1");
	menu_additem(menu, fmt("%L", id, "MENU_SWITCH_TURN_OFF"), "2");
	menu_setprop(menu, MPROP_EXITNAME, fmt("%L", id, "MENU_EXIT"));
	
	set_pdata_int(id, OFFSET_CSMENUCODE, 0);
	menu_display(id, menu, 0);
}

public menu_switch_handler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	
	new data[2], iAccess, callback;
	menu_item_getinfo(menu, item, iAccess, data, charsmax(data), _, _, callback);
	
	new bool:enable = (data[0] == '1');  // '1' = ON, '2' = OFF
	new bool:is_enabled = bool:get_pcvar_num(cvar_enabled);
	
	if((enable && is_enabled) || (!enable && !is_enabled))
	{
		client_print_color(id, print_team_default, "^4[ZM] ^1%L", LANG_PLAYER, enable ? "TXT_ALREADY_ENABLED" : "TXT_ALREADY_DISABLED");
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	
	// Set cvar status
	set_pcvar_num(cvar_enabled, enable ? 1 : 0);
	
	// Log and show message to everyone
	log_amx("[ZM Switch] Zombie Mod Infection %s.", enable ? "ACTIVATED" : "DEACTIVATED");
	client_print_color(0, print_team_default, "^4[ZM] ^1%L", LANG_PLAYER, enable ? "TXT_SWITCH_ON" : "TXT_SWITCH_OFF");
	
	// Activation/Deactivation HUD
	set_dhudmessage(enable ? 0 : 255, enable ? 255 : 0, 0, -1.0, 0.25, 1, 6.0, 28.0);
	show_dhudmessage(0, "%L", LANG_PLAYER, enable ? "HUD_ACTIVATING" : "HUD_DEACTIVATING");
	
	// Announce sound every 1 sec
	remove_task(983); // if for certain causes the sound was still playing before destroy the task
	set_task(1.0, "play_announce_sound", 983, _, _, "b");
	
	// Play enable/disable sound
	set_task(17.0, enable ? "play_enable_sound" : "play_disable_sound");
	
	// Schedule restart task to make changes take effect
	set_task(29.0, "task_restart_map");
	
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

public play_announce_sound()
{
	PlaySound(0, announce_sound);
}

public play_enable_sound()
{
	remove_task(983);
	PlaySound(0, zombie_win[random_num(0, sizeof zombie_win - 1)]);
}

public play_disable_sound()
{
	remove_task(983);
	PlaySound(0, disable_sound);
}

public task_restart_map()
{
	new mapname[32];
	get_mapname(mapname, charsmax(mapname));
	server_cmd("changelevel %s", mapname);
}
