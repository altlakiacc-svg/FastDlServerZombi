#include <amxmodx>
#include <hamsandwich>
#include <zombieplague>

#define PLUGIN "[ZP] Survivor or Nemesis Win Round or Loose"
#define AUTHOR "Kiske"
#define VERSION "1.0"

// Cvars
new CVAR[4]

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR)
	
	// Language files
    register_dictionary("SurvOrNem_WinRoundOrLoose.txt")
	
    CVAR[0] = register_cvar("zp_ammos_surv_winround", "50") // Ammos for Survivor
    CVAR[1] = register_cvar("zp_ammos_nem_winround", "50") // Ammos for Nemesis
    CVAR[2] = register_cvar("zp_ammos_survkill", "20") // Ammos for the killing Survivor
    CVAR[3] = register_cvar("zp_ammos_nemkill", "20") // Ammos for the killing Nemesis
	
    RegisterHam(Ham_Killed, "player", "Ham_PlayerKilled")
}

// Ham Player Killed Forward
public Ham_PlayerKilled(victim, attacker, shouldgib)
{
    if (victim == attacker || !is_user_connected(attacker))
    return HAM_IGNORED   
   
    static name[32]
    get_user_name(attacker, name, charsmax(name))
	
	// Survivor or Nemesis Round ?
    if (zp_is_survivor_round() || zp_is_nemesis_round())
	{
		// Survivor 
		if (zp_get_user_survivor(attacker) && zp_get_user_last_zombie(victim)) // Survivor's win
		{
			ChatColor(0, "!g[ZP]!y %L", LANG_PLAYER, "SURV_WINROUND", name, get_pcvar_num(CVAR[0]), (get_pcvar_num(CVAR[0]) == 1) ? "" : "s")
			zp_set_user_ammo_packs(attacker, zp_get_user_ammo_packs(attacker) + get_pcvar_num(CVAR[0]))
		}
		else if (zp_get_user_zombie(attacker) && zp_get_user_survivor(victim)) // Survivor's loose
		{
			ChatColor(0, "!g[ZP]!y %L", LANG_PLAYER, "SURV_LOOSEROUND", name, get_pcvar_num(CVAR[2]), (get_pcvar_num(CVAR[2]) == 1) ? "" : "s")
			zp_set_user_ammo_packs(attacker, zp_get_user_ammo_packs(attacker) + get_pcvar_num(CVAR[2]))
		}
		
		// Nemesis
		if (zp_get_user_nemesis(attacker) && zp_get_user_last_human(victim)) // Nemesis win
		{
			ChatColor(0, "!g[ZP]!y %L", LANG_PLAYER, "NEM_WINROUND", name, get_pcvar_num(CVAR[1]), (get_pcvar_num(CVAR[1]) == 1) ? "" : "s")
			zp_set_user_ammo_packs(attacker, zp_get_user_ammo_packs(attacker) + get_pcvar_num(CVAR[1]))
		}
		else if (!zp_get_user_zombie(attacker) && zp_get_user_nemesis(victim)) // Nemesis loose
        {
			ChatColor(0, "!g[ZP]!y %L", LANG_PLAYER, "NEM_LOOSEROUND", name, get_pcvar_num(CVAR[3]), (get_pcvar_num(CVAR[3]) == 1) ? "" : "s")
			zp_set_user_ammo_packs(attacker, zp_get_user_ammo_packs(attacker) + get_pcvar_num(CVAR[3]))
        }
    }
	
    return HAM_IGNORED
}

// Stock: ChatColor!
stock ChatColor(const id, const input[], any:...)
{
	new count = 1, players[32]
	static msg[191]
	vformat(msg, 190, input, 3)
	
	replace_all(msg, 190, "!g", "^4") // Green Color
	replace_all(msg, 190, "!y", "^1") // Default Color
	replace_all(msg, 190, "!team", "^3") // Team Color
	replace_all(msg, 190, "!team2", "^0") // Team2 Color
	
	if (id) players[0] = id; else get_players(players, count, "ch")
	{
		for (new i = 0; i < count; i++)
		{
			if (is_user_connected(players[i]))
			{
				message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, players[i])
				write_byte(players[i]);
				write_string(msg);
				message_end();
			}
		}
	}
}