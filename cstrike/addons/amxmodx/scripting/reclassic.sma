#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <engine>
#include <fun>
#include <zombieplague>

// Zombie Attributes
new const zclass_name[] = "Classic"
new const zclass_info[] = "[ Balanse ]"
new const zclass_model[] = "reclassic"
new const zclass_clawmodel[] = "re/v_re_classic.mdl"
new const g_vgrenade[] = "models/zombie_plague/re/v_zombibomb-classic.mdl"
const zclass_health = 4000
const zclass_speed = 240
const Float:zclass_gravity = 0.80
const Float:zclass_knockback = 0.60

public plugin_init()
{
	register_event("CurWeapon", "Event_CurWeapon", "be", "1=1");
}

// Class IDs
new g_classic

// Zombie Classes MUST be registered on plugin_precache
public plugin_precache()
{
	register_plugin("[ZP] Classic", "1.0", "dias")
	precache_model(g_vgrenade)
	
	// Register the new class and store ID for reference
	g_classic = zp_register_zombie_class(zclass_name, zclass_info, zclass_model, zclass_clawmodel, zclass_health, zclass_speed, zclass_gravity, zclass_knockback)	
}

public Event_CurWeapon(id)    
{   
    new weaponID = read_data(2)    

    if(!zp_get_user_zombie(id) || !is_user_alive(id) || zp_get_user_zombie_class(id) != g_classic)   
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