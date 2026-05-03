#include <amxmodx>
#include <cstrike>
#include <hamsandwich>
#include <cs_ham_bots_api>
#include <zombiemod>

#define TASK_NIGHTVISION 100
#define ID_NIGHTVISION (taskid - TASK_NIGHTVISION)

#define BIT_SET(%1,%2) (%1 |= (1<<(%2 - 1)))
#define BIT_CLEAR(%1,%2) (%1 &= ~(1<<(%2 - 1)))
#define BIT_CHECK(%1,%2) (%1 & (1<<(%2 - 1)))
#define BIT_TOGGLE(%1,%2) (%1 ^= (1<<(%2 - 1)))

#define is_valid_player_connected(%1) (1 <= %1 && %1 <= 32 && is_user_connected(%1))
#define is_valid_player_alive(%1) (1 <= %1 && %1 <= 32 && is_user_alive(%1))

new g_bitNVisionActive;   // si tiene NVG disponible
new g_bitNVisionEnabled;  // si está encendida en este momento
new g_MsgNVGToggle;

new cvar_nvgcustom;
new cvar_nvgsize;
new cvar_nvgcolor[3];

new g_cached_nvgcustom;
new g_cached_nvgsize;
new g_cached_nvgcolor[3];

public plugin_init()
{
	// Register Plugin
	register_plugin("[ZM] Nightvision", "1.0", "ProgramViewer");
	
	// Check if mod is active
	zmod_is_active() ? plugin_init2() : pause("ad");
}

public plugin_init2()
{
	// Events
	register_event("HLTV", "event_new_round", "a", "1=0", "2=0");
	register_event("ResetHUD", "event_reset_hud", "b");

	// Ham
	RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawnPost", 1);
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled");
	RegisterHamBots(Ham_Killed, "fw_PlayerKilled");

	// Message Id
	g_MsgNVGToggle = get_user_msgid("NVGToggle");
	
	// Message Hook
	register_message(g_MsgNVGToggle, "message_NVGToggle");
	
	// Cmd
	register_clcmd("nightvision", "clcmd_nightvision");

	// Cvars
	cvar_nvgcustom = register_cvar("zmod_nvg_custom", "0");
	cvar_nvgsize = register_cvar("zmod_nvg_size", "140");
	cvar_nvgcolor[0] = register_cvar("zmod_nvg_color_r", "0");
	cvar_nvgcolor[1] = register_cvar("zmod_nvg_color_g", "255");
	cvar_nvgcolor[2] = register_cvar("zmod_nvg_color_b", "0");
}

public plugin_cfg()
{
	set_task(0.1, "cache_cvars");
}

public client_putinserver(id)
{
	if(!zmod_is_active())
	{
		return;
	}
	
	BIT_CLEAR(g_bitNVisionActive, id);
	BIT_CLEAR(g_bitNVisionEnabled, id);
	set_task(0.2, "spec_nvision", id);
}

public client_disconnected(id)
{
	BIT_CLEAR(g_bitNVisionActive, id);
	BIT_CLEAR(g_bitNVisionEnabled, id);
	remove_task(id+TASK_NIGHTVISION);
}

public event_new_round()
{
	set_task(0.1, "cache_cvars");
}

// ResetHUD Removes CS Nightvision (bugfix)
public event_reset_hud(id)
{
	if(!g_cached_nvgcustom)
	{
		set_user_gnvision(id, BIT_CHECK(g_bitNVisionEnabled, id) ? 1 : 0); 
	}
}

// Prevent spectators' nightvision from being turned off when switching targets, etc.
public message_NVGToggle(msg_id, msg_dest, msg_entity)
{
	return PLUGIN_HANDLED;
}

// Toggles night vision for the player.
public clcmd_nightvision(id)
{
	// Nightvision available to player?
	if(BIT_CHECK(g_bitNVisionActive, id) || (is_user_alive(id) && cs_get_user_nvg(id)))
	{
		// Enable-disable
		BIT_TOGGLE(g_bitNVisionEnabled, id);
		
		// Custom nvg?
		if(g_cached_nvgcustom)
		{
			remove_task(id+TASK_NIGHTVISION);
			if(BIT_CHECK(g_bitNVisionEnabled, id))
			{
				set_task(0.1, "set_user_nvision", id+TASK_NIGHTVISION, _, _, "b");
			}
		}
		else
		{
			set_user_gnvision(id, BIT_CHECK(g_bitNVisionEnabled, id) ? 1 : 0);
		}
	}

	return PLUGIN_HANDLED;
}

public zmod_player_infection(victim, attacker)
{
	if(!is_valid_player_alive(victim))
	{
		return;
	}

	if(!is_user_bot(victim))
	{
		toggle_nvg(victim, true);
	}
	else
	{
		cs_set_user_nvg(victim, 1);
	}
}

public zmod_user_cured(id)
{
	if(!is_valid_player_alive(id))
	{
		return;
	}

	toggle_nvg(id, false);
}

public fw_PlayerSpawnPost(id)
{
	if(g_cached_nvgcustom)
	{
		remove_task(id+TASK_NIGHTVISION);
	}
}

// Ham Player Killed Forward
public fw_PlayerKilled(victim, attacker, shouldgib)
{
	// Enable spectators nightvision?
	set_task(0.2, "spec_nvision", victim);
}

// Enable night vision for spectators
public spec_nvision(id)
{
	// Check if the player is not connected or is alive or a bot 
	if(!is_valid_player_connected(id) || is_user_alive(id) || is_user_bot(id))
	{
		return;
	}
	
	toggle_nvg(id, true);
}

// Custom Night Vision Task
public set_user_nvision(taskid)
{
	// Get player's origin
	static origin[3];
	get_user_origin(ID_NIGHTVISION, origin);
	
	// Nightvision message
	message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, _, ID_NIGHTVISION);
	write_byte(TE_DLIGHT); // TE id
	write_coord(origin[0]); // x
	write_coord(origin[1]); // y
	write_coord(origin[2]); // z
	write_byte(g_cached_nvgsize); // radius
	write_byte(g_cached_nvgcolor[0]); // r
	write_byte(g_cached_nvgcolor[1]); // g
	write_byte(g_cached_nvgcolor[2]); // b
	write_byte(2); // life
	write_byte(0); // decay rate
	message_end();
}

stock set_user_gnvision(id, active)
{
	// Toggle NVG message
	message_begin(MSG_ONE, g_MsgNVGToggle, _, id);
	write_byte(active); // toggle
	message_end();
}

public cache_cvars()
{
	g_cached_nvgcustom = get_pcvar_num(cvar_nvgcustom);
	g_cached_nvgsize = get_pcvar_num(cvar_nvgsize);
	g_cached_nvgcolor[0] = get_pcvar_num(cvar_nvgcolor[0]);
	g_cached_nvgcolor[1] = get_pcvar_num(cvar_nvgcolor[1]);
	g_cached_nvgcolor[2] = get_pcvar_num(cvar_nvgcolor[2]);
}

public toggle_nvg(id, bool:enable)
{
	// Remove CS nightvision if player owns one 
	if(cs_get_user_nvg(id))
	{
		cs_set_user_nvg(id, 0);
		if(g_cached_nvgcustom) 
		{
			remove_task(id+TASK_NIGHTVISION);
		}
		else if(BIT_CHECK(g_bitNVisionEnabled, id))
		{
			set_user_gnvision(id, 0);
		}
	}
	
	if(!is_user_bot(id))
	{
		// Bits
		enable ? BIT_SET(g_bitNVisionActive, id) : BIT_CLEAR(g_bitNVisionActive, id);
		enable ? BIT_SET(g_bitNVisionEnabled, id) : BIT_CLEAR(g_bitNVisionEnabled, id);
		
		if(g_cached_nvgcustom)
		{
			remove_task(id+TASK_NIGHTVISION);
			if(enable)
			{
				set_task(0.1, "set_user_nvision", id+TASK_NIGHTVISION, _, _, "b");
			}
		}
		else
		{
			set_user_gnvision(id, enable ? 1 : 0);
		}
	}
}
