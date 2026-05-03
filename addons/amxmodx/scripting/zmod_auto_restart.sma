#include <amxmodx>
#include <amxmisc>
#include <zombiemod>

#define VERSION "1.0"
#define TASK_AUTORESTART 1337

new cvar_auto_restart_enabled; // Enable/disable auto-restart
new cvar_auto_restart_seconds; // Number of seconds to wait before starting the game
new auto_restart_seconds; // Countdown in seconds for auto-restart
new bool:g_restart_done = false; // Prevent multiple restarts
new g_MsgSyncHudAutoRestart;

public plugin_init()
{
	// Register Plugin
	register_plugin("[ZM] Auto Restart", VERSION, "ProgramViewer");
	
	// Check if mod is active
	zmod_is_active() ? plugin_init2() : pause("ad");
}

public plugin_init2() 
{
	// Cvars
	cvar_auto_restart_enabled = register_cvar("zmod_auto_restart_enabled", "1");
	cvar_auto_restart_seconds = register_cvar("zmod_auto_restart_seconds", "60");
	
	// Create hud sync obj
	g_MsgSyncHudAutoRestart = CreateHudSyncObj();
	
	// Start sequence after small delay (let server initialize)
	set_task(5.0, "start_autorestart");
}

public start_autorestart()
{
	if(!get_pcvar_num(cvar_auto_restart_enabled))
	{
		return;
	}

	if(g_restart_done)
	{
		return;
	}

	// Initialize countdown
	auto_restart_seconds = get_pcvar_num(cvar_auto_restart_seconds);

	// Start repeating task every second
	set_task(1.0, "task_autorestart", TASK_AUTORESTART, _, _, "b");
}

public task_autorestart()
{
	// Safety check
	if(g_restart_done)
	{
		remove_task(TASK_AUTORESTART);
		return;
	}

	// Show HUD countdown
	set_hudmessage(255, 255, 255, -1.0, 0.4, 0, 6.0, 1.0, 0.1, 0.2, 4);
	ShowSyncHudMsg(0, g_MsgSyncHudAutoRestart, "%L", LANG_PLAYER, "HUD_AUTORESTART", auto_restart_seconds);
		
	// When countdown ends
	if(auto_restart_seconds <= 1)
	{
		server_cmd("sv_restart 5");

		g_restart_done = true;
		remove_task(TASK_AUTORESTART);
		return;
	}

	auto_restart_seconds--;
}
