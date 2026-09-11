//-----------
// [ZL] SpawnSystem
//
// NPC Forum
// http://zombielite.Ru/
//--
// By Alexander.3
// http://Alexander3.Ru/

#include < amxmodx >
#include < hamsandwich >
#include < fakemeta >

#define NAME 			"[ZL] SpawnSystem"
#define VERSION			"1.2"
#define AUTHOR			"Alexander.3"

#define RESPAWN

const human_hp =		300
static PrepareTime =		40
#if defined RESPAWN
const RespawnNum =		5
const RespawnTime =		20

static bool:buffResp[33]
static idRespTime[33]
#endif
static EntTimer
static bool:idRespawn[33]
native zl_boss_map()

public plugin_init() {
	register_plugin(NAME, VERSION, AUTHOR)
	
	if (!zl_boss_map()) {
		pause("ad")
		return
	}	
	RegisterHam(Ham_Spawn, "player", "Hook_Spawn", 1)
	#if defined RESPAWN
	RegisterHam(Ham_Killed, "player", "Hook_Killed", 1)
	#endif
	EntTimer = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	set_pev(EntTimer, pev_classname, "Timer")
	RegisterHamFromEntity(Ham_Think, EntTimer, "Ham_Timer")
	register_dictionary("zl_spawnsystem.txt")
}

public Hook_Spawn(id) {
	if (!is_user_connected(id) || is_user_bot(id))
		return HAM_IGNORED
		
	if (idRespawn[id] && !PrepareTime) {
		user_silentkill(id)
		return HAM_IGNORED
	}
	
	set_pev(id, pev_health, float(human_hp))
	idRespawn[id] = true
	return HAM_HANDLED
}

public Hook_Killed(victim, attacker, corpse) {
	if (!is_user_connected(victim))
		return HAM_IGNORED
	
	if (PrepareTime > 0) {
		ExecuteHamB(Ham_CS_RoundRespawn, victim)
		return HAM_IGNORED
	}
		
	#if defined RESPAWN		
	static Respawn[33], a[33]
	
	a[victim] = RespawnNum - Respawn[victim]
	
	if (!a[victim]) {
		client_print(victim, print_center, "%L", LANG_PLAYER, "RESP_END")
		return HAM_HANDLED
	}
	idRespTime[victim] = RespawnTime
	
	client_print(victim, print_chat, "%L", LANG_PLAYER, "RESP_NUM", a[victim] - 1)
	Respawn[victim]++
	buffResp[victim] = true
	#endif
	return HAM_HANDLED
}

public Ham_Timer(Ent) {
	if (!pev_valid(Ent))
		return HAM_IGNORED
		
	static ClassName[32]
	pev(Ent, pev_classname, ClassName, charsmax(ClassName))
	
	if (!equal(ClassName, "Timer"))
		return HAM_IGNORED
		
	if (GetAliveCount() < 1)
		return HAM_IGNORED
	
	#if defined RESPAWN
	for(new id = 1; id <= get_maxplayers(); id++) {
		if (is_user_alive(id) || is_user_bot(id))
			continue
		
		if (!idRespawn[id] || !buffResp[id])
			continue
		
		if (!idRespTime[id]) {
			idRespawn[id] = false
			buffResp[id] = false
			ExecuteHam(Ham_CS_RoundRespawn, id)
			continue
		}
		client_print(id, print_center, "%L", LANG_PLAYER, "RESP_ACTIVE", idRespTime[id])
		idRespTime[id]--
	}
	#endif
	if (PrepareTime) PrepareTime--
	set_pev(Ent, pev_nextthink, get_gametime() + 1.0)
	return HAM_HANDLED
}

public client_putinserver(id) {
	if (!is_user_connected(id) || PrepareTime > 0)
		return
		
	idRespawn[id] = true
}
	
GetAliveCount() {				// ^^
	new iAlive
	for (new id = 1; id <= get_maxplayers(); id++) if (is_user_alive(id)) iAlive++
	return iAlive
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1049\\ f0\\ fs16 \n\\ par }
*/
