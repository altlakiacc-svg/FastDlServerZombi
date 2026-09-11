#include <amxmodx>
#include <zombieplague>
#include <fun>

#define COST 2
#define MAX 10000

new const item_name[] = "Health Kit"
new g_msgSayText

new g_itemid_buyhp, hpamount_z, nemesis, survivor
new bool:g_bIsConnected[33]
new const zombie_buy[] = "weapons/vox/buy_hppp.wav"
 
public plugin_precache()
{
    precache_sound(zombie_buy)
}

public plugin_init() 
{
    register_plugin("[ZP] Buy Health", "1.3", "Dcrkan / CHyc / Shidla / Doomsday")

    register_dictionary("plugins.txt")
	
    register_clcmd("say /buy_hp", "BuyHealth")
    register_clcmd("say_team /buy_hp", "BuyHealth")

    hpamount_z   =  register_cvar("zp_buyhp_zombie", "1000")
    nemesis      =  register_cvar("zp_allow_buy_to_nemesis", "0")
    survivor     =  register_cvar("zp_allow_but_to_survivor", "0")

    g_itemid_buyhp = zp_register_extra_item(item_name, COST, ZP_TEAM_ZOMBIE)
    g_msgSayText = get_user_msgid("SayText")
}

public zp_extra_item_selected(id,itemid)
{ 
    	if (itemid==g_itemid_buyhp)
    	{
                if(get_user_health(id) > MAX)
                {
                        zp_set_user_ammo_packs(id, zp_get_user_ammo_packs(id) + COST)
                        client_printcolor(id, "/g[ZP]/y %L", id, "addhp2")
                        return PLUGIN_HANDLED;
                }

                Health(id)
    	}
    	return PLUGIN_CONTINUE;
}  

public BuyHealth(id)
{
        if(!is_user_alive(id))
    	    	return PLUGIN_HANDLED;

    	if(zp_get_user_ammo_packs(id) < COST)
        {
                client_printcolor(id, "/g[ZP]/y %L", id, "addhp1", COST - zp_get_user_ammo_packs(id), item_name)
    	    	return PLUGIN_HANDLED;
        }

        if(get_user_health(id) > MAX)
        {
                client_printcolor(id, "/g[ZP]/y %L", id, "addhp2")
                return PLUGIN_HANDLED;
        }

    	if(zp_get_user_nemesis(id) && !get_pcvar_num(nemesis))
    	    	return PLUGIN_HANDLED;

    	if(zp_get_user_survivor(id) && !get_pcvar_num(survivor))
    	    	return PLUGIN_HANDLED;

    	Health(id)
        zp_set_user_ammo_packs(id, zp_get_user_ammo_packs(id) - COST)
    	return PLUGIN_CONTINUE;
}

public client_putinserver(id)
{
	g_bIsConnected[id] = true
}

public Health(id)
{
    	if (zp_get_user_zombie(id))
        {
            	set_user_health(id,get_user_health(id)+get_pcvar_num(hpamount_z));
            	client_printcolor(id, "/g[ZP]/y %L", id, "addhp", item_name, get_pcvar_num(hpamount_z));
                emit_sound(id, CHAN_STREAM, zombie_buy, 1.0, ATTN_NORM, 0, PITCH_NORM)
		}
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