/*================================================================================
    ------------------------------
    -*- [ZM] Map Lightning -*-
    ------------------------------

	Changelog:
	v1.0
	- First Release
    v1.3:
    - Cached cvars (zmod_lights, zmod_thunderclap) on round start via HLTV event
    - Replaced task_exists checks with boolean flag (O(1) performance)
    - Eliminated redundant set_lights spam every 1.0 second
    - Removed recursive call in thunder_cycle for safer state management
    - Added fallback to "z" when lighting is disabled or empty
    - Forced sv_skycolor to 0 and mp_playerid to 1 to prevent dark exploit
    - Consolidated plugin_init2 into plugin_init
================================================================================*/

#include <amxmodx>
#include <engine>
#include <zombiemod>

#define VERSION "1.3"

// Default thunder sounds (you can add more)
new const sound_thunder[][] = {"ambience/thunder_clap.wav"};

// Lightning cycles
new const thunder_lights[][] = {"ijklmnonnmlkjihgfedcb", "klmlkjihgfedcbaabcdedcb", "bcdefedcijklmlkjihgfedcb"};

// Task IDs
#define TASK_THUNDER 100
#define TASK_THUNDER_LIGHTS 200

// Global variables
new g_ThunderLightIndex;
new g_ThunderLightMaxLen;
new g_ThunderLight[64];
new bool:g_ThunderActive;

// Cvars
new cvar_lightning;
new cvar_thunderclap;
new g_cached_lightning[2];     
new g_cached_thunderclap;   

public plugin_precache()
{
	// Precache thunder sounds
	for(new i = 0; i < sizeof(sound_thunder); i++)
	{
		precache_sound(sound_thunder[i]);
	}
}

public plugin_init()
{
	// Register Plugin
	register_plugin("[ZM] Map Lightning", VERSION, "ProgramViewer");
	
	// Check if Zombie Mod Infection is active
	if(!zmod_is_active())
	{
		pause("ad");
		return;
	}
	
	// Event
	register_event("HLTV", "event_new_round", "a", "1=0", "2=0");
	
	// Commands
	set_cvar_num("sv_skycolor_r", 0);
	set_cvar_num("sv_skycolor_g", 0);
	set_cvar_num("sv_skycolor_b", 0);
	set_cvar_num("mp_playerid", 1); // Prevents seeing enemies in the dark exploit
	
	// Cvars
	cvar_lightning = register_cvar("zmod_lights", "a");
	cvar_thunderclap = register_cvar("zmod_thunderclap", "60");
}

public plugin_cfg()
{
	// Check if Zombie Mod Infection is active
	if(!zmod_is_active())
	{
		return;
	}
	
	// Cache the cvars
	cache_cvars();
	
	// Apply base lighting immediately on startup
	ApplyBaseLighting();
	
	// Lightning task
	set_task(1.0, "lightning_task", _, _, _, "b");
}

public event_new_round()
{
	// Cache cvar values on round start
	cache_cvars();
}

// Lightning task
public lightning_task()
{
	// Skip if thunder is already active
	if(g_ThunderActive)
	{
		return;
	}
    
	// Skip if lighting is disabled
	if(g_cached_lightning[0] == '0' || g_cached_lightning[0] == EOS)
	{
		return;
	}
	
	// Schedule thunder if interval > 0
	if(g_cached_thunderclap > 0.0)
	{
		// Lock state to prevent overlapping cycles
		g_ThunderActive = true;
		
		// Pick a random lightning pattern
		copy(g_ThunderLight, charsmax(g_ThunderLight), thunder_lights[random_num(0, sizeof(thunder_lights) - 1)]);
		g_ThunderLightMaxLen = strlen(g_ThunderLight);
		g_ThunderLightIndex = 0;
		
		// Schedule thunder start
		set_task(float(g_cached_thunderclap), "thunder_start", TASK_THUNDER);
	}
}

// Start thunder event (plays sound and begins light cycle)
public thunder_start()
{
	// Play a random thunder sound
	PlaySound(sound_thunder[random_num(0, sizeof(sound_thunder) - 1)]);
	
	// Start the lightning cycle (each step every 0.1 seconds)
	set_task(0.1, "thunder_cycle", TASK_THUNDER_LIGHTS, _, _, "b");
}

// Cycle through the light pattern
public thunder_cycle()
{
	// Check if pattern is complete
	if(g_ThunderLightIndex >= g_ThunderLightMaxLen)
	{
		remove_task(TASK_THUNDER_LIGHTS); // Stop visual cycle
		g_ThunderActive = false;          // Unlock scheduling
		ApplyBaseLighting();              // Restore base lighting
		return;
	}
    
	// Apply current frame of the pattern
	new light[2];
	light[0] = g_ThunderLight[g_ThunderLightIndex];
	set_lights(light);
	g_ThunderLightIndex++; // Advance to next frame
}

// Plays a sound on clients
stock PlaySound(const sound[])
{
	(equal(sound[strlen(sound) - 4], ".mp3")) ? client_cmd(0, "mp3 play ^"sound/%s^"", sound) : client_cmd(0, "spk ^"%s^"", sound);
}

stock cache_cvars()
{
	get_pcvar_string(cvar_lightning, g_cached_lightning, charsmax(g_cached_lightning));
	g_cached_thunderclap = get_pcvar_num(cvar_thunderclap);
}

stock ApplyBaseLighting()
{
	// Apply cached lighting or fallback to "z" if disabled
	(g_cached_lightning[0] == '0' || g_cached_lightning[0] == EOS) ? set_lights("z") : set_lights(g_cached_lightning);
}
