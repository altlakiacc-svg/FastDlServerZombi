#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <engine>
#include <fun>
#include <zombieplague>

#define PLUGIN "[ZP] Class - predator"
#define VERSION "1.0"
#define AUTHOR "HoRRoR"


// Zombie Attributes
new const zclass_name[] = "Hunter"
new const zclass_info[] = "[ Acceleration ]"
new const zclass_model[] = "rehanter"
new const zclass_clawmodel[] = "re/v_re_hanter.mdl"
new const g_vgrenade[] = "models/zombie_plague/re/v_zombibomb-hanter.mdl"
const zclass_health = 3200
const zclass_speed = 240
const Float:zclass_gravity = 0.91
const Float:zclass_knockback = 0.50

// --- config ------------------------ //
new Float:g_fastspeed = 500.0 // sprint speed
new Float:g_normspeed = 240.0 // norm speed. must be as zclass_speed
new Float:g_abilonecooldown = 20.0 // cooldown time
new Float:g_abilonelenght = 3.0 // time of sprint
new const sound_hunter_sprint[] = "zombie_plague/re/hanter/sprint.wav" //sprint sound
// ----------------------------------- //

new i_cooldown_time[33]
new bool:g_bIsConnected[33]
new g_zclass_hunter
new g_speeded[33] = 0
new g_abil_one_used[33] = 0
new g_maxplayers
new g_msgSayText

public plugin_precache()
{
	g_zclass_hunter = zp_register_zombie_class(zclass_name, zclass_info, zclass_model, zclass_clawmodel, zclass_health, zclass_speed, zclass_gravity, zclass_knockback)
	precache_sound(sound_hunter_sprint)
	precache_model(g_vgrenade)
}

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_event("CurWeapon", "Event_CurWeapon", "be", "1=1");
	RegisterHam(Ham_Spawn, "player", "Spawn", 1)
	register_clcmd("ability1", "use_ability_one")
	register_concmd("ability1", "use_ability_one")
	
	register_forward( FM_PlayerPreThink, "client_prethink" )
	register_logevent("roundStart", 2, "1=Round_Start")
	
	g_maxplayers = get_maxplayers()
	
	g_msgSayText = get_user_msgid("SayText") 
	register_dictionary("class_zombie.txt")
}


public client_prethink(id)
{
	if (zp_get_user_zombie_class(id) == g_zclass_hunter)
	{
		if(is_user_alive(id) && zp_get_user_zombie(id) && (zp_get_user_zombie_class(id) == g_zclass_hunter) && !zp_get_user_nemesis(id))
		Action(id);
	}
}

public Event_CurWeapon(id)    
{   
    new weaponID = read_data(2)    

    if(!zp_get_user_zombie(id) || !is_user_alive(id) || zp_get_user_zombie_class(id) != g_zclass_hunter)   
    return PLUGIN_CONTINUE   

    if(weaponID == CSW_HEGRENADE ) 
    { 
        set_pev(id, pev_viewmodel, engfunc(EngFunc_AllocString, g_vgrenade))    
    }  
    if(weaponID == CSW_FLASHBANG ) 
    { 
        set_pev(id, pev_viewmodel, engfunc(EngFunc_AllocString, g_vgrenade))     
    }  
    if(weaponID == CSW_SMOKEGRENADE ) 
    { 
        set_pev(id, pev_viewmodel, engfunc(EngFunc_AllocString, g_vgrenade))    
    }  
    return PLUGIN_CONTINUE    
}

public client_putinserver(id)
{
	g_bIsConnected[id] = true
}

public Action(id)
{
	if (g_speeded[id] == 1)
	{
		set_user_maxspeed(id , g_fastspeed); 
	}
	else
	{
		set_user_maxspeed(id , g_normspeed); 
	}
    	return PLUGIN_HANDLED;
} 

public roundStart()
{
	for (new i = 1; i <= g_maxplayers; i++)
	{
		i_cooldown_time[i] = floatround(g_abilonecooldown)
		g_abil_one_used[i] = 0
		g_speeded[i] = 0
		remove_task(i)
		client_cmd(i,"cl_forwardspeed 400")
		client_cmd(i,"cl_backspeed 400")
	}
}

public ShowHUD(id)
{
	if(is_user_alive(id))
	{
		i_cooldown_time[id] = i_cooldown_time[id] - 1;
		set_hudmessage(200, 100, 0, 0.75, 0.92, 0, 1.0, 1.1, 0.0, 0.0, -1)
		show_hudmessage(id, "%L: %d", id, "CLASS_SPEED", i_cooldown_time[id])
	}else{
		remove_task(id)
	}
}

public Spawn(id){
    if(!is_user_alive(id) || !is_user_connected(id)) 
        return PLUGIN_HANDLED

    for (new i = 1; i <= g_maxplayers; i++)
	(			
	    set_user_rendering(id)
	)
    return PLUGIN_HANDLED
}

public use_ability_one(id)
{
    if(!is_user_alive(id) || !is_user_connected(id)) 
        return PLUGIN_HANDLED

    if ((zp_get_user_zombie_class(id) == g_zclass_hunter) && zp_get_user_zombie(id) && !zp_get_user_nemesis(id))
	{
		
		if(g_abil_one_used[id] == 0)
		{				
			client_cmd(id,"cl_forwardspeed 1600")
			client_cmd(id,"cl_backspeed 1600")
	
			g_speeded[id] = 1
			emit_sound(id, CHAN_STREAM, sound_hunter_sprint, 1.0, ATTN_NORM, 0, PITCH_NORM)
			g_abil_one_used[id] = 1
			set_task(g_abilonelenght,"set_normal_speed",id)
						
			i_cooldown_time[id] = floatround(g_abilonecooldown)
			set_user_rendering(id, kRenderFxGlowShell,255,0,0,kRenderNormal,25)
			set_task(1.0, "ShowHUD", id, _, _, "a",i_cooldown_time[id])
//			client_print(id,print_chat,"[dev] - use ability")           
		}		
	}
    return PLUGIN_HANDLED	
}

public set_normal_speed(id)
{
	if(!is_user_alive(id) || !is_user_connected(id))
		return PLUGIN_HANDLED

	if ((zp_get_user_zombie_class(id) == g_zclass_hunter) && zp_get_user_zombie(id) && !zp_get_user_nemesis(id))
	{
		g_speeded[id] = 0
		client_cmd(id,"cl_forwardspeed 400")
		client_cmd(id,"cl_backspeed 400")
		set_user_rendering(id)
		set_task(g_abilonecooldown,"set_ability_one_cooldown",id)
//		client_print(id,print_chat,"[dev] - executed 'set normal speed' task")
	}
	return PLUGIN_HANDLED
}

public set_ability_one_cooldown(id)
{
	if ((zp_get_user_zombie_class(id) == g_zclass_hunter) && zp_get_user_zombie(id) && !zp_get_user_nemesis(id))
	{
		g_abil_one_used[id] = 0
		client_printcolor(id, "/g[ZP] /y %L", id, "CLASS_INFO")
	}
}

public zp_user_infected_post(id, infector)
{
	if ((zp_get_user_zombie_class(id) == g_zclass_hunter) && !zp_get_user_nemesis(id))
	{
		new note_cooldown = floatround(g_abilonecooldown)
		client_printcolor(id, "/g[ZP] /y %L", id, "CLASS_INFO2", note_cooldown)
		
		i_cooldown_time[id] = floatround(g_abilonecooldown)
		remove_task(id)
		g_speeded[id] = 0
		g_abil_one_used[id] = 0
		client_cmd(id,"bind alt ability1")
	}
}

public zp_user_humanized_post(id)
{
	remove_task(id)
	client_cmd(id,"cl_forwardspeed 400")
	client_cmd(id,"cl_backspeed 400")
}

stock client_printcolor(id, const input[], any:...)
{
	static iPlayersNum[32], iCount; iCount = 1
	static szMsg[191]
	
	vformat(szMsg, charsmax(szMsg), input, 3)
	
	replace_all(szMsg, 190, "/g", "^4")
	replace_all(szMsg, 190, "/y", "^1")
	replace_all(szMsg, 190, "/ctr", "^3")
	replace_all(szMsg, 190, "/w", "^0")
	
	if(id) iPlayersNum[0] = id
	else get_players(iPlayersNum, iCount, "ch")
		
	for (new i = 0; i < iCount; i++)
	{
		if (g_bIsConnected[iPlayersNum[i]])
		{
			message_begin(MSG_ONE_UNRELIABLE, g_msgSayText, _, iPlayersNum[i])
			write_byte(iPlayersNum[i])
			write_string(szMsg)
			message_end()
		}
	}
}