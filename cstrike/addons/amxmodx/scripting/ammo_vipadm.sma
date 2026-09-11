#include <amxmodx> 
#include <zombieplague> 

#define PLUGIN_NAME "Simple AmmoPacks Giver" 
#define PLUGIN_VERSION "0.2" 
#define PLUGIN_AUTHOR "Arseny aka Without Soul" 

new AdminAP, VipAP, UserAP, given[33]

public plugin_init() 
{ 
    register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR); 
     
    AdminAP = register_cvar("apg_admin", "200"); 
    VipAP = register_cvar("apg_vip", "100"); 
} 

public client_putinserver(id) 
{ 
    set_task(3.0, "GiveAP", id); 
} 

public GiveAP(id) 
{ 
    if(given[id])
        return PLUGIN_HANDLED;
        
    if(get_user_flags(id) & ADMIN_BAN) 
    { 
        UserAP = zp_get_user_ammo_packs(id);     
        zp_set_user_ammo_packs(id, UserAP + get_pcvar_num(AdminAP)); 
        given[id] = true

        return PLUGIN_HANDLED; 
    } 
    if(get_user_flags(id) & ADMIN_LEVEL_H) 
    { 
        UserAP = zp_get_user_ammo_packs(id);         
        zp_set_user_ammo_packs(id, UserAP + get_pcvar_num(VipAP)); 
        given[id] = true

        return PLUGIN_HANDLED; 
    } 

    return PLUGIN_HANDLED; 
} 