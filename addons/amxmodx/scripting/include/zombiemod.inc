/*==============================================================================================================*/

                                  /*========================================================*\
                              ||::::::::::::::::::::::::::::::::::::::::::::::::::::::::||
                              ||---------[ Zombie Mod Infection Includes File ]---------||
                              ||::::::::::::::::::::::::::::::::::::::::::::::::::::::::||
                              \*========================================================*/  
			      
/*==============================================================================================================*/

#if defined _zombiemod_included
  #endinput
#endif
#define _zombiemod_included

// Return whether the mod is active
native zmod_is_active();

// Returns whether the player is a zombie
// Params: id - Player index
// Returns: True if zombie, false otherwise
native zmod_get_user_zombie(id)

// Returns whether the player is a human
// Params: id - Player index
// Returns: True if human, false otherwise
native zmod_get_user_human(id)

// Returns whether a player is a super zombie.
// Params: id - Player index
// Returns: True if super zombie, false otherwise
native zmod_get_user_superzombie(id)

// Returns whether a player is the first zombie.
// Params: id - Player index
// Returns: True if first zombie, false otherwis
native zmod_get_user_first_zombie(id)

// Forces a player to turn into a human
// Params: id - Target index
// Returns: 1 - if successful, 0 - if failed
native zmod_force_transform_human(id)

// Forces a player to turn into a zombie
// Params: id - Target index
// Returns: 1 - if successful, 0 - if failed
native zmod_force_transform_zombie(id)

// Forces a player to turn into a super zombie
// Params: id - Target index
// Returns: 1 - if successful, 0 - if failed
native zmod_force_transform_super_zombie(id)

// Check if the first zombie selection has started or is in progress
// Returns: 0 - Round not started, 1 - Round started, 2 - Round starting
native zmod_has_round_started()

// Get the count of alive zombies
// Returns: Number of zombies alive
native zmod_get_zombie_count()

// Get the count of alive humans
// Returns: Number of humans alive
native zmod_get_human_count()

// Check if the current round is an infection round
// Returns: True if infection round, false otherwise
native zmod_is_round_infection()

// Check if the current round is a super zombie round
// Returns: True if super zombie round, false otherwise
native zmod_is_round_super()

// Check if the weapon is allowed
// Returns: true if allowed, false otherwise
native zmod_is_weapon_allowed(weaponid);

// Assign a random allowed primary weapon to the player
// Returns: 1 on success, 0 on failure
native zmod_assign_primary_weapon(id);

// Assign a random secondary weapon (pistol) to the player
// Returns: 1 on success, 0 on failure
native zmod_assign_secondary_weapon(id);

// Assigns nades to the player
// Returns: 1 on success, 0 on failure
native zmod_assign_grenades(id);

// Called when a player gets infected
// Params: victim - Player index who was infected, attacker - Player index who infected them
forward zmod_player_infection(victim, attacker)

// Called when a player is cured and turns back to human
// Params: id - Player index who was cured
forward zmod_user_cured(id)

// Called when the first zombie was selected
forward zmod_infection_begin()
