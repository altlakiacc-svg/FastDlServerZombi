#include <amxmodx>
#include <cstrike>
#include <zombieplague>

#define PLUGIN 		"[ZP: Respapawn Ammo]"
#define VERSION 		"0.1"
#define AUTHOR 		"4e/l"

new cvar_respawn_humans_cost, cvar_respawn_zombies_cost 

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)

	register_clcmd("res", "respawn", ADMIN_ALL, "respawn")
	register_clcmd("say /res", "respawn", ADMIN_ALL, "respawn")

	cvar_respawn_humans_cost = register_cvar("zp_respawn_humans_cost", "2")
	cvar_respawn_zombies_cost = register_cvar("zp_respawn_zombies_cost", "1")

	register_dictionary("zp_wpn_menu.txt")	
}

/*================================================================================================================
|						[ZP: RESPAWN]																			  |
==================================================================================================================*/

public respawn(id)
{
	new menu = menu_create("\rChoose Team", "menu_handler");

	menu_additem(menu, "\wHumans [Cost: 5 Ammo]", "1", 0);
	menu_additem(menu, "\wZombies [Cost: 3 Ammo]", "2", 0);
    
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
    
	menu_display(id, menu, 0); 
		
	return PLUGIN_HANDLED
}

public menu_handler(id, menu, item)
{
    	if( item == MENU_EXIT )
   	{
        	menu_destroy(menu);
        	return PLUGIN_HANDLED;    
    	}
    
    	new data[6], iName[64];
    	new access, callback;
    
    	menu_item_getinfo(menu, item, access, data,5, iName, 63, callback);
    
    	new key = str_to_num(data);
    
    	switch(key)
	{
        	case 1:
       		{	
			//if(cs_get_user_money(id) < get_pcvar_num(cvar_respawn_humans_cost))
			if(zp_get_user_ammo_packs(id)< get_pcvar_num(cvar_respawn_humans_cost))
			{
				client_print(id, print_center,"[ZP] You dont have enough ammo packs.")
				return PLUGIN_HANDLED			
			}

 			if(is_user_alive(id))
			{
				client_print(id, print_chat, "[ZP] Only Dead people can purchase respawn ability")
				return PLUGIN_HANDLED
			}

			if(zp_is_survivor_round() && !is_user_alive(id))
			{
				client_print(id, print_chat, "[ZP] Only zombie can respawn")
				return PLUGIN_HANDLED
			}
	
			if(!is_user_alive(id))
			{
				zp_respawn_user(id, ZP_TEAM_HUMAN)
     				//cs_set_user_money(id, cs_get_user_money(id) - get_pcvar_num(cvar_respawn_humans_cost)) 
				zp_set_user_ammo_packs(id, zp_get_user_ammo_packs(id) - get_pcvar_num(cvar_respawn_humans_cost))
			}


           	 	menu_destroy(menu);
            		return PLUGIN_HANDLED
    		}

        	case 2:
        	{
			//if(cs_get_user_money(id) < get_pcvar_num(cvar_respawn_zombies_cost))
			if(zp_get_user_ammo_packs(id)< get_pcvar_num(cvar_respawn_zombies_cost))
			{
				client_print(id, print_center,"%L", LANG_PLAYER, "NO_MONEY")
				return PLUGIN_HANDLED			
			}

 			if(is_user_alive(id))
			{
				client_print(id, print_chat, "[ZP] Only Dead people can purchase respawn ability")
				return PLUGIN_HANDLED
			}

			if(zp_is_nemesis_round() && !is_user_alive(id))
			{
				client_print(id, print_chat, "[ZP] Only humans can respawn")
				return PLUGIN_HANDLED
			}
	
			if(!is_user_alive(id))
			{
				zp_respawn_user(id, ZP_TEAM_ZOMBIE)
     				//cs_set_user_money(id, cs_get_user_money(id) - get_pcvar_num(cvar_respawn_zombies_cost)) 
				zp_set_user_ammo_packs(id, zp_get_user_ammo_packs(id) - get_pcvar_num(cvar_respawn_zombies_cost))
			}
				

			menu_destroy(menu);
			return PLUGIN_HANDLED
		}

	}
    	menu_destroy(menu);
    	return PLUGIN_HANDLED
}