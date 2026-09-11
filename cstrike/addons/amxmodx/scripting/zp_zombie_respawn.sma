#include <amxmodx>
#include <amxmisc>
#include <fun>
#include <hamsandwich>
#include <zombieplague>

#define PLUGNAME		"[ZP] Zombie Respawn"
#define AUTHOR			"CHyC/PomanoB"
#define VERSION		        "4.0"

new bool:g_end

new g_respawn_count[33]

new cvar_maxspawn , cvar_spawndelay , cvar_color , cvar_colorspawn , cvar_amount , cvar_time;

public plugin_init()
{
        RegisterHam(Ham_Killed, "player", "PlayerKilled", 1);
	register_cvar("zp_respawn", VERSION, FCVAR_SERVER)

	cvar_maxspawn           = register_cvar("zp_max_spawn" , "2");
	cvar_spawndelay         = register_cvar("zp_spawn_time" , "5.0");
	cvar_color              = register_cvar("zp_color" , "0");
	cvar_colorspawn         = register_cvar("zp_color_spawn" , "0 255 255");
	cvar_amount             = register_cvar("zp_color_amount" , "30");
	cvar_time               = register_cvar("zp_color_time" , "10.0");
}
 
public PlayerKilled(Victim)

	if (zp_get_user_zombie(Victim) && !zp_get_user_nemesis(Victim))
                set_task((get_pcvar_float(cvar_spawndelay)), "PlayerRespawn", Victim);
 
public PlayerRespawn(id)
{
    if (g_respawn_count[id]++>=get_pcvar_num(cvar_maxspawn))
    return PLUGIN_CONTINUE;              

    if (!g_end && !is_user_alive(id) && zp_get_user_zombie(id) && !zp_get_user_nemesis(id))
    {
        remove_task(id);
        zp_respawn_user(id, ZP_TEAM_ZOMBIE)    
        

        if(get_pcvar_num(cvar_color))
        {
                new szColor[12], szRed[4], szGreen[4], szBlue[4]
                get_pcvar_string(cvar_colorspawn,szColor,11)
                parse(szColor,szRed,3,szGreen,3,szBlue,4)

                new iRed = clamp(str_to_num(szRed),0,255)
                new iGreen = clamp(str_to_num(szGreen),0,255)
                new iBlue = clamp(str_to_num(szBlue),0,255)

                set_user_rendering(id,kRenderFxGlowShell,iRed,iGreen,iBlue,kRenderNormal,get_pcvar_num(cvar_amount))
                set_task(get_pcvar_float(cvar_time),"event_time_color",id)
          
        }
    }
    return PLUGIN_CONTINUE;
}

public event_time_color(id)
{
    if(is_user_alive(id) || is_user_connected(id)) 
    return;

    set_user_rendering(id,kRenderFxNone,0,0,0,kRenderNormal,0)
    return;
}

public zp_round_ended(winteam)
{
	g_end = true
}

public zp_round_started(gamemode, player)
{
	g_end = false
        arrayset(g_respawn_count,0,33)
}
