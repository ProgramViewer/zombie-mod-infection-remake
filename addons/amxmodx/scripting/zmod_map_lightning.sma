/*================================================================================
    ------------------------------
    -*- [ZM] Map Lightning -*-
    ------------------------------
================================================================================*/

#include <amxmodx>
#include <engine>
#include <zombiemod>

#define VERSION "1.0"

// Default thunder sounds (you can add more)
new const sound_thunder[][] = {"ambience/thunder_clap.wav"};

// Lightning cycles
new const thunder_lights[][] = {"ijklmnonnmlkjihgfedcb", "klmlkjihgfedcbaabcdedcb" , "bcdefedcijklmlkjihgfedcb"};

// Task IDs
#define TASK_THUNDER 100
#define TASK_THUNDER_LIGHTS 200

// Global variables
new g_ThunderLightIndex;
new g_ThunderLightMaxLen;
new g_ThunderLight[64];

// Cvars
new cvar_lightning;
new cvar_thunderclap;

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
	
	// Check if plugin is active
	zmod_is_active() ? plugin_init2() : pause("ad");
}

public plugin_init2()
{
	// Commands
	set_cvar_num("sv_skycolor_r", 0);
	set_cvar_num("sv_skycolor_g", 0);
	set_cvar_num("sv_skycolor_b", 0);
	set_cvar_string("sv_skyname", "space");
	
	// Cvars
	cvar_lightning = register_cvar("zmod_lights", "a");
	cvar_thunderclap = register_cvar("zmod_thunderclap", "60");
}

public plugin_cfg()
{
	if(!zmod_is_active())
	{
		return;
	}
	
	// Prevents seeing enemies in the dark exploit
	server_cmd("mp_playerid 1");
	
	// lightning task
	set_task(1.0, "lightning_task", _, _, _, "b");
}

// lightning Task
public lightning_task()
{
	// Get lightning style from cvar
	new lightning[2];
	get_pcvar_string(cvar_lightning, lightning, charsmax(lightning));
	
	// lightning disabled? (cvar value "0")
	if(lightning[0] == '0')
	{
		return;
	}
	
	// Schedule thunder if thunderclap interval > 0 and no thunder task is running
	new Float:thunder_time = get_pcvar_float(cvar_thunderclap);
	if(thunder_time > 0.0 && !task_exists(TASK_THUNDER) && !task_exists(TASK_THUNDER_LIGHTS))
	{
		// Pick a random lightning pattern
		copy(g_ThunderLight, charsmax(g_ThunderLight), thunder_lights[random_num(0, sizeof(thunder_lights) - 1)]);
		g_ThunderLightMaxLen = strlen(g_ThunderLight);
		g_ThunderLightIndex = 0;
		
		set_task(thunder_time, "thunder_start", TASK_THUNDER);
	}
	
	// Apply base lightning only when no thunder cycle is active
	if(!task_exists(TASK_THUNDER_LIGHTS))
	{
		set_lights(lightning);
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
	if(g_ThunderLightIndex >= g_ThunderLightMaxLen)
	{
		// Cycle finished: stop and restore base lightning
		remove_task(TASK_THUNDER_LIGHTS);
		lightning_task();
		return;
	}
	
	new light[2];
	light[0] = g_ThunderLight[g_ThunderLightIndex];
	set_lights(light);
	g_ThunderLightIndex++;
}

// Plays a sound on clients
stock PlaySound(const sound[])
{
	(equal(sound[strlen(sound)-4], ".mp3")) ? client_cmd(0, "mp3 play ^"sound/%s^"", sound) : client_cmd(0, "spk ^"%s^"", sound);
}
