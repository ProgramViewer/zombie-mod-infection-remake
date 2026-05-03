#include <amxmodx>
#include <engine>
#include <fun>
#include <hamsandwich>
#include <zombiemod>

#define VERSION "1.0"

#define FLASHLIGHT_IMPULSE 100 // Flashlight impulse ID
const USE_USING = 2; // Entity usage state

public plugin_init()
{
	// Register Plugin
	register_plugin("[ZM] Restrictions", VERSION, "ProgramViewer");
	
	// Check if plugin is active
	zmod_is_active() ? plugin_init2() : pause("ad");
}

public plugin_init2()
{
	// Event
	register_event("CurWeapon", "event_current_weapon", "be", "1=1");
	
	// HAM
	RegisterHam(Ham_Touch, "weaponbox", "fw_TouchWeapon");
	RegisterHam(Ham_Touch, "armoury_entity", "fw_TouchWeapon");
	RegisterHam(Ham_Touch, "weapon_shield", "fw_TouchWeapon");
	RegisterHam(Ham_Use, "func_pushable" ,"fw_UseStationary");
	RegisterHam(Ham_Use, "func_tank" ,"fw_UseStationary");
	RegisterHam(Ham_Use, "func_tankmortar" ,"fw_UseStationary");
	RegisterHam(Ham_Use, "func_tanklaser" ,"fw_UseStationary");
	RegisterHam(Ham_Use, "func_tankrocket" ,"fw_UseStationary");
	RegisterHam(Ham_Use, "func_pushable", "fw_UsePushable");
	
	// Message Hooks
	register_message(get_user_msgid("SendAudio"), "message_sendaudio");
	register_message(get_user_msgid("WeapPickup"), "message_weappickup");
	register_message(get_user_msgid("AmmoPickup"), "message_ammopickup");
}

// Block flashlight for zombies
public client_impulse(id, impulse)
{
	return (impulse == FLASHLIGHT_IMPULSE && zmod_get_user_zombie(id)) ? PLUGIN_HANDLED : PLUGIN_CONTINUE;
}

public event_current_weapon(id)
{
	// Check if player is alive and round isn't active
	if(!is_user_alive(id) || zmod_has_round_started() != 1)
	{
		return;
	}
	
	// Get current weapon
	new weapon = get_user_weapon(id);
	
	// Ensure zombies only use knife
	if(zmod_get_user_zombie(id))
	{
		if(weapon != CSW_KNIFE)
		{
			strip_user_weapons(id);
			give_item(id, "weapon_knife");
		}
		return;
	}
	
	// Check if weapon is allowed for humans
	if(!zmod_is_weapon_allowed(weapon))
	{
		strip_user_weapons(id);
		give_item(id, "weapon_knife");
		zmod_assign_primary_weapon(id);
		zmod_assign_secondary_weapon(id);
		emit_sound(id, CHAN_ITEM, "events/friend_died.wav", 1.0, ATTN_NORM, 0, PITCH_NORM);
		client_print_color(id, print_team_default, "^4[ZM] ^1%L", LANG_PLAYER, "TXT_WEAPON_NOT_ALLOWED");
		return;
	}
}

// Prevent zombies from grabbing weapons
public fw_TouchWeapon(weapon, id)
{
	return (is_user_connected(id) && zmod_get_user_zombie(id)) ? HAM_SUPERCEDE : HAM_IGNORED;
}

// Prevent zombies from using stationaries 
public fw_UseStationary(entity, caller, activator, use_type)
{
	return (use_type == USE_USING && is_user_connected(caller) && zmod_get_user_zombie(caller)) ? HAM_SUPERCEDE : HAM_IGNORED;
}

// Ham use pushble forward
public fw_UsePushable()
{
	// Block speed bug with pushables
	return HAM_SUPERCEDE;
}

// Prevent zombies from seeing any weapon pickup icon
public message_weappickup(msgid, msgdest, id)
{
	return zmod_get_user_zombie(id) ? PLUGIN_HANDLED : PLUGIN_CONTINUE;
}

// Prevent zombies from seeing any ammo pickup icon
public message_ammopickup(msgid, dest, id)
{
	return zmod_get_user_zombie(id) ? PLUGIN_HANDLED : PLUGIN_CONTINUE;
}

// Block sounds to play our own
public message_sendaudio(msgid, msgdest, id)
{
	static audio[17];
	get_msg_arg_string(2, audio, charsmax(audio));
	return (equal(audio[7], "terwin") || equal(audio[7], "ctwin") || equal(audio[7], "rounddraw")) ? PLUGIN_HANDLED : PLUGIN_CONTINUE;
}
