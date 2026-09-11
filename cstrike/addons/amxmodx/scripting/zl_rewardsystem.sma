//-----------
// RewardSystem
//
// NPC Forum
// http://zombielite.Ru/
// By Alexander.3
// http://Alexander3.Ru/
//
// Native:
// zl_give_reward(index, num)
// - index ( Player )
// - num ( Money )

#include < amxmodx >
#include < hamsandwich >
#include < fakemeta >

#define NAME		"[ZL] RewardSystem"
#define VERSION		"1.3.1"
#define AUTHOR		"Alexander.3"

#define DMG
#define FRAG
#define KILL

//#define CLASSIC
//#define BUYMENU
#define ZP43
//#define ZP50
//#define WAR3FT

const spawn_money =  0

// DamageFunc
const dmg_max = 		1000
const dmg_reward =	2

// FragDamage
const frag_dmg =	1000
const frag_add =	1

// KilledFunc
const kReward =		500
const k_red =		255
const k_green =		0
const k_blue =		0

#if defined ZP43
#include < zombieplague >
#endif
#if defined ZP50
#include < zp50_ammopacks >
#endif
#if defined BUYMENU
native zp_cs_get_user_money(id)
native zp_cs_set_user_money(id, money)
#endif

native zl_boss_map()
native zl_boss_valid(ent)

public plugin_init() {
	register_plugin(NAME, VERSION, AUTHOR)
	
	if (!zl_boss_map()) {
		pause("ad")
		return
	}
	
	RegisterHam(Ham_TakeDamage, "info_target", "TakeDamage_Boss")
	RegisterHam(Ham_Spawn, "player", "Hook_Spawn", 1)
	register_dictionary("zl_rewardsystem.txt")
}

public Hook_Spawn(id) {
	if (!is_user_connected(id))
		return HAM_IGNORED
		
	GiveMoney(id, spawn_money)
	return HAM_HANDLED
}

public TakeDamage_Boss(victim, wpn, attacker, Float:damage, damagebyte) {
	if (!pev_valid(victim) || !is_user_alive(attacker))
		return HAM_IGNORED
		
	if (zl_boss_valid(victim)) {
		static Float:BossHealth
		pev(victim, pev_health, BossHealth)
		
		if (damage < BossHealth) {
			#if defined DMG
			static Float:PlayerDamage[33]
			PlayerDamage[attacker] += damage
			#endif
			
			#if defined FRAG
			static Float:PlayerDamage2[33]
			PlayerDamage2[attacker] += damage
			#endif
			
			#if defined DMG
			if (PlayerDamage[attacker] > dmg_max) {
				GiveMoney(attacker, dmg_reward)
				
				PlayerDamage[attacker] = 0.0
				return HAM_HANDLED
			}
			#endif
			
			#if defined FRAG
			if (PlayerDamage2[attacker] > frag_dmg) {
				set_pev(attacker, pev_frags, pev(attacker, pev_frags) + float(frag_add))
				
				message_begin(MSG_BROADCAST, get_user_msgid("ScoreInfo"))
				write_byte(attacker)
				write_short(pev(attacker, pev_frags))
				write_short(get_user_deaths(attacker))
				write_short(0)
				write_short(get_user_team(attacker))
				message_end()
				
				PlayerDamage2[attacker] = 0.0
				return HAM_HANDLED
			}
			#endif
			
		} else {
			#if defined KILL
			MessageKilled(attacker)
			GiveMoney(attacker, kReward)
			#endif
			return HAM_IGNORED
		}
	}
	return HAM_HANDLED
}

MessageKilled(attacker) {
	new kName[32]
	get_user_name(attacker, kName, charsmax(kName))
	
	set_hudmessage(k_red, k_green, k_blue, 0.29, 0.49, 0, 6.0, 12.0)
	show_hudmessage(0, "%L", LANG_SERVER, "REWARD_KILL", kName, kReward)
}

public plugin_natives()
	register_native("zl_give_reward", "GiveMoney", 1)

public GiveMoney(index, num) {
	if (!is_user_connected(index))
		return
		
	#if defined CLASSIC
	set_pdata_int(index, 115, floatround(get_pdata_int(index, 115) + float(num), floatround_round))
	
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("Money"), _, index)
	write_long(floatround(get_pdata_int(index, 115) + float(num), floatround_round))
	write_byte(1)
	message_end()
	#endif
	
	#if defined BUYMENU
	zp_cs_set_user_money(index, zp_cs_get_user_money(index) + num)
	#endif
	
	#if defined ZP43
	zp_set_user_ammo_packs(index, zp_get_user_ammo_packs(index) + num)
	#endif
				
	#if defined ZP50
	zp_ammopacks_set(index, zp_ammopacks_get(index) + num)
	#endif
	
	#if defined WAR3FT
	new kName[32]
	get_user_name(index, kName, charsmax(kName))
	server_cmd( "wc3_givexp ^"%s^" ^"%d^"", kName, num)
	#endif
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1049\\ f0\\ fs16 \n\\ par }
*/
