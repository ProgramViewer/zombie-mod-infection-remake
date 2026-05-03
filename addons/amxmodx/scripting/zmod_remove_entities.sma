#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <zombiemod>

#define VERSION "1.0" 

new g_fake_hostage; // Placeholder entity used to force round ending
new g_fwd_SpawnEntity; // Forward hook for entity spawn events
new g_fwd_PrecacheSound; // Forward hook for sound precache events
new const g_remove_entities[][] = {"func_bomb_target", "info_bomb_target", "hostage_entity", "monster_scientist","func_hostage_rescue", "info_hostage_rescue", "info_vip_start", "func_vip_safetyzone","func_escapezone", "func_buyzone"}; // Entities to remove from the map  

public plugin_precache()
{
	// Register Plugin
	register_plugin("[ZM] Remove Entities", VERSION, "ProgramViewer");
	
	if(!zmod_is_active())
	{
		return;
	}
	
	// Register a forward hook for entity spawn events
	g_fwd_SpawnEntity = register_forward(FM_Spawn, "fw_Spawn");
	
	// Register a forward hook for sound precache events
	g_fwd_PrecacheSound = register_forward(FM_PrecacheSound, "fw_PrecacheSound");
	
	// Create a fake hostage entity to force the round to end
	g_fake_hostage = create_entity("hostage_entity");
	if(pev_valid(g_fake_hostage))
	{
		// Move the fake hostage to an out-of-bounds location
		entity_set_origin(g_fake_hostage, Float:{8192.0,8192.0,8192.0});
		
		// Spawn the entity 
		dllfunc(DLLFunc_Spawn, g_fake_hostage);
	}
}

public plugin_init()
{
	// Check if plugin is active
	zmod_is_active() ? plugin_init2() : pause("ad");
}

public plugin_init2() 
{
	// Forwards
	register_forward(FM_EmitSound, "fw_EmitSound");
	unregister_forward(FM_Spawn, g_fwd_SpawnEntity);
	unregister_forward(FM_PrecacheSound, g_fwd_PrecacheSound);
	
	// Message Hooks
	register_message(get_user_msgid("TextMsg"),"message_textmsg");
	register_message(get_user_msgid("StatusIcon"), "message_statusicon");
	register_message(get_user_msgid("Scenario"), "message_scenario");
	register_message(get_user_msgid("HostagePos"), "message_hostagepos");
}

// Entity spawn forward
public fw_Spawn(ent)
{
	// Check if the entity is valid
	if(!pev_valid(ent)) 
	{
		return FMRES_IGNORED;
	}
	
	// Get ent classname
	static classname[32];
	entity_get_string(ent, EV_SZ_classname, classname, charsmax(classname));

	// Loop through the list of entities to remove
	static i;
	for(i = 0; i < sizeof g_remove_entities; ++i)
	{
		// Check if the entity's classname matches any in the removal list
		if(equal(classname, g_remove_entities[i]))
		{
			// Remove the entity
			remove_entity(ent);
			return FMRES_SUPERCEDE;
		}
	}
	
	return FMRES_IGNORED;
}

// Sound Precache Forward
public fw_PrecacheSound(const sound[])
{
	// Block all those unneeeded hostage sounds
	return (equal(sound, "hostage", 7)) ? FMRES_SUPERCEDE : FMRES_IGNORED;
}

// Emit sound forward
public fw_EmitSound(id, channel, const sample[], Float:volume, Float:attn, flags, pitch)
{
	// Block all those unneeeded hostage sounds
	return (sample[0] == 'h' && sample[1] == 'o' && sample[2] == 's' && sample[3] == 't' && sample[4] == 'a' && sample[5] == 'g' && sample[6] == 'e') ? FMRES_SUPERCEDE : FMRES_IGNORED;
}

// Handle and optionally block or modify round end HUD messages
public message_textmsg()
{
	// Only process central HUD messages 
	if(get_msg_arg_int(1) != 4)
	{
		return PLUGIN_CONTINUE; // Let other types of messages through
	}
	
	// Get the message string
	static textmsg[25];
	get_msg_arg_string(2, textmsg, charsmax(textmsg));
	
	// Block specific messages that are not needed
	if(equal(textmsg, "#Target_Saved") || equal(textmsg, "#Round_Draw") || equal(textmsg,"#Game_bomb_drop"))
	{
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE; // Allow all other messages
}

// Block hostage HUD display
public message_scenario()
{
	if(get_msg_args() > 1)
	{
		static sprite[8];
		get_msg_arg_string(2, sprite, charsmax(sprite));
		
		if(equal(sprite, "hostage"))
		{
			return PLUGIN_HANDLED;
		}
	}
	
	return PLUGIN_CONTINUE;
}

// Block hostages from appearing on radar
public message_hostagepos()
{
	return PLUGIN_HANDLED;
}

// Block buyzone icon
public message_statusicon(msgid, msgdest, id)
{
	static szIcon[8];
	get_msg_arg_string(2, szIcon, charsmax(szIcon));
	
	if(equal(szIcon, "buyzone") && get_msg_arg_int(1))
	{
		set_pdata_int(id, 235, get_pdata_int(id, 235) & ~(1<<0));
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}