#include <amxmodx>
#include <zombiemod>

#define VERSION "1.0"

#define MAX_SKY_NAME 64
#define MAX_SUFFIX 6

new const g_suffix[MAX_SUFFIX][3] = { "up", "dn", "ft", "bk", "lf", "rt" };

// Cvars
new cvar_enabled;
new cvar_sky_name;

// Global to store the selected sky name (without forced underscore)
new g_selected_sky[MAX_SKY_NAME];

public plugin_precache()
{
	register_plugin("[ZM] Custom Sky", VERSION, "ProgramViewer");
	
	if(!zmod_is_active())
	{
		return;
	}
	
	cvar_enabled = register_cvar("zmod_custom_sky_enabled", "1");
	cvar_sky_name = register_cvar("zmod_sky_name", "blood_");
	
	if(!get_pcvar_num(cvar_enabled))
	{
		return;
	}
	
	// Get the original sky name from the cvar
	get_pcvar_string(cvar_sky_name, g_selected_sky, charsmax(g_selected_sky));
	
	if(strlen(g_selected_sky) == 0)
	{
		copy(g_selected_sky, charsmax(g_selected_sky), "space");
	}
	
	// Normalize name for file lookup: add trailing underscore if missing
	new normalized[MAX_SKY_NAME];
	copy(normalized, charsmax(normalized), g_selected_sky);
	
	new path[128];
	new bool:all_exist = true;
	
	for(new i = 0; i < MAX_SUFFIX; i++)
	{
		formatex(path, charsmax(path), "gfx/env/%s%s.tga", normalized, g_suffix[i]);
		if(file_exists(path))
		{
			precache_generic(path);
		}
		else
		{
			log_amx("[ZM] Missing file: %s", path);
			all_exist = false;
		}
	}
	
	if(!all_exist)
	{
		log_amx("[ZM] Some TGA files missing, will NOT apply custom sky.");
		g_selected_sky[0] = EOS;   // Clear the name to avoid applying it later
	}
}

public plugin_cfg()
{
	if(strlen(g_selected_sky) > 0)
	{
		set_cvar_string("sv_skyname", g_selected_sky);
		log_amx("[ZM] Applied sky: %s", g_selected_sky);
	}
}
