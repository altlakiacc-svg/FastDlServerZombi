#include <amxmisc>
#include <amxmodx> 
#include <fakemeta>
#include <hamsandwich> 
#include <engine>
#include <fun>
#include <zombieplague>

enum
{
	WATERLEVEL_NOT,
};

#define DMG_DROWN (1<<14)

#define PLUGIN	"Fast"
#define VERSION	"1.0"
#define AUTHOR	"Fast"

new cvar_enabled;
new g_zclass_drowned;
new drowned_speed;
new Float:g_cvar_speed;
new bool:g_alive[33];
new bool:g_counter_strike;

new const zclass_name[] = "Fast"
new const zclass_info[] = "[ Speed ]"
new const zclass_model[] = "refast"
new const zclass_clawmodel[] = "re/v_re_fast.mdl"
new const g_vgrenade[] = "models/zombie_plague/re/v_zombibomb-fast.mdl"
const zclass_health = 2000
const zclass_speed = 265
const Float:zclass_gravity = 0.70
const Float:zclass_knockback = 0.60

public plugin_init()
{
    register_plugin(PLUGIN , VERSION , AUTHOR);
    register_event("CurWeapon", "Event_CurWeapon", "be", "1=1");	 
    cvar_enabled = register_cvar("zp_drowned", "1"); 
    RegisterHam(Ham_TakeDamage, "player", "FwdTakeDamage");
    register_forward(FM_PlayerPreThink, "FwdPlayerPreThink");
    RegisterHam(Ham_Spawn, "player", "FwdPlayerSpawn", 1);
    drowned_speed = register_cvar("zp_drowned_speed", "220.0");
    g_counter_strike = bool:is_running("cstrike");
}

public plugin_precache()
{
    g_zclass_drowned = zp_register_zombie_class(zclass_name, zclass_info, zclass_model, zclass_clawmodel, zclass_health, zclass_speed, zclass_gravity, zclass_knockback)
    precache_model(g_vgrenade)
}

public Event_CurWeapon(id)    
{   
    new weaponID = read_data(2)    

    if(!zp_get_user_zombie(id) || !is_user_alive(id) || zp_get_user_zombie_class(id) != g_zclass_drowned)   
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

public FwdTakeDamage(id, inflictor, attacker, Float:damage, damagebits)
{
	if(get_pcvar_num(cvar_enabled) != 1)
		return HAM_IGNORED;

	if(!is_user_alive(id) || !zp_get_user_zombie(id)) 
		return HAM_IGNORED;

	if(zp_get_user_zombie_class(id) != g_zclass_drowned) 
		return HAM_IGNORED;
	
	if(damagebits & DMG_DROWN)
	{
		return HAM_SUPERCEDE;
	}
	return HAM_IGNORED;
}

public FwdPlayerPreThink(client)
{
	static old_waterlevel[33];
	
	if( !g_alive[client] || !get_pcvar_float(drowned_speed) || !zp_get_user_zombie(client) || zp_get_user_zombie_class(client) != g_zclass_drowned || pev(client, pev_movetype) == MOVETYPE_NOCLIP )
	{
		old_waterlevel[client] = WATERLEVEL_NOT;
		return;
	}
	
	new waterlevel = pev(client, pev_waterlevel);
	if( waterlevel != WATERLEVEL_NOT )
	{
		SetMaxspeed(client, g_cvar_speed);
	}
	else if( old_waterlevel[client] != WATERLEVEL_NOT )
	{
		ResetMaxspeed(client);
	}
	
	old_waterlevel[client] = waterlevel;
}

public FwdPlayerSpawn(client)
{
	if( is_user_alive(client) )
	{
		g_alive[client] = true;
	}
}

ResetMaxspeed(client)
{
	if( g_counter_strike )
	{
		static Float:maxspeed;
		switch ( get_user_weapon(client) )
		{
			case CSW_SG550, CSW_AWP, CSW_G3SG1:		 maxspeed = 210.0;
			case CSW_M249:					 maxspeed = 220.0;
			case CSW_AK47:					 maxspeed = 221.0;
			case CSW_M3, CSW_M4A1:				 maxspeed = 230.0;
			case CSW_SG552:					 maxspeed = 235.0;
			case CSW_XM1014, CSW_AUG, CSW_GALIL, CSW_FAMAS:	 maxspeed = 240.0;
			case CSW_P90:					 maxspeed = 245.0;
			case CSW_SCOUT:					 maxspeed = 260.0;
			default:					 maxspeed = 250.0;
		}
		
		SetMaxspeed(client, maxspeed);
	}
	else
	{
		SetMaxspeed(client, 250.0);
	}
}

SetMaxspeed(client, Float:maxspeed)
{
	engfunc(EngFunc_SetClientMaxspeed, client, maxspeed);
	set_pev(client, pev_maxspeed, maxspeed);
}