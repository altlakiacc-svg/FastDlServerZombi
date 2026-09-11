/* [ZP] AmmoChange v1.0 */
/* Руссифицировано */

#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <zombieplague>

new ammo[3][33],string[21],cvarShowType,ammopacks

public plugin_init() {
	register_plugin("[ZP] AmmoChange", "1.0", "ZETA [M|E|N]")
	register_logevent("round_start", 2, "1=Round_Start")
	cvarShowType = register_cvar("ac_show_type", "1")
	
	register_clcmd("say /change","func_change",ADMIN_ALL,"")
}

public round_start() {
	for(new id=1;id<get_maxplayers();id++) {
		ammo[0][id] = zp_get_user_ammo_packs(id)
	}
}

public client_putinserver(id) {
	set_task(3.0,"func_ammo",id)
}

public func_ammo(id) {
	ammopacks = zp_get_user_ammo_packs(id)
	
	ammo[0][id] = ammopacks
	ammo[1][id] = ammopacks
	ammo[2][id] = ammopacks
	
	set_task(1.0,"change_ammo",id,_,_,"b")
}

public change_ammo(id) {
	if(cs_get_user_team(id) == CS_TEAM_SPECTATOR)
		return PLUGIN_HANDLED
		
	ammo[1][id] = zp_get_user_ammo_packs(id)
		
	if(ammo[1][id] != ammo[2][id]) {
		if(ammo[1][id] > ammo[2][id]) {
			ammopacks = ammo[1][id] - ammo[2][id]
			format(string,charsmax(string),"[ +%d пак. ]", ammopacks)
		}
		else {
			ammopacks = ammo[2][id] - ammo[1][id]
			format(string,charsmax(string),"[ -%d пак. ]", ammopacks)
		}
		
		ammo[2][id] = ammo[1][id]
		
		if(get_pcvar_num(cvarShowType)) {
			set_hudmessage(0, 250, 100, 0.47, 0.90, 0, 6.0, 3.0,_,_,3)
			show_hudmessage(id, "%s", string)
		}
		else
			client_print(id, print_center, "%s", string)
	}
	
	return PLUGIN_HANDLED
}

public client_disconnect(id) {
	ammo[0][id] = 0
	ammo[1][id] = 0
	ammo[2][id] = 0
	
	remove_task(id)
}

public func_change(id) {
	if(ammo[0][id] != ammo[2][id]) {
		if(ammo[0][id] > ammo[2][id]) {
			ammopacks = ammo[0][id] - ammo[2][id]
			client_print(id,print_chat,"[ZP] Ваше аммо уменьшилось на %d.", ammopacks)
		}
		else {
			ammopacks = ammo[2][id] - ammo[0][id]
			client_print(id,print_chat,"[ZP] Ваше аммо увеличилось на %d.", ammopacks)
		}
	}
	else 
		client_print(id,print_chat,"[ZP] Ваше аммо не изменилось.")
	return PLUGIN_HANDLED
}
