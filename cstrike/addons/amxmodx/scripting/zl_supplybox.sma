//-----------
// SupplyBox
//
// NPC Forum
// http://zombielite.Ru/
// By Alexander.3
// http://Alexander3.Ru/

#include < amxmodx >
#include < fakemeta >
#include < hamsandwich >
#include < xs >

#define NAME 			"SupplyBox"
#define VERSION			"1.2"
#define AUTHOR			"Alexander.3"
	
#define GBox			"models/zl/supplybox.mdl"
const GiftNum =			10
const min_rewards =		100
const max_rewards =		500
//Color HudMessage
const h_red =			255
const h_green = 			0
const h_blue =			0
//Glow Eff.
const g_true =			1
const g_red =			0
const g_green =			255
const g_blue =			0
const g_amount =		50

#define GLOW_EFF
#define ONEBOX

native zl_give_reward(index, num)
native zl_boss_map()
native zl_boss_valid(index)

public plugin_init() {
	register_plugin(NAME, VERSION, AUTHOR)
	
	if (!zl_boss_map()) {
		pause("ad")
		return
	}
	
	RegisterHam(Ham_Touch, "info_target", "Touch_Box")
	RegisterHam(Ham_Killed, "info_target", "Hook_Killed")
	register_dictionary("zl_supplybox.txt")
}

public SpawnBox( Ent ) {	
	for (new i; i < GiftNum; ++i) {
		new Float:Vector[3]
		pev(Ent, pev_origin, Vector)
		
		new Gift = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))	
		set_pev(Gift, pev_classname, "sBox")
		engfunc(EngFunc_SetSize, Gift, { -5.0, -5.0, -5.0 }, { 5.0, 5.0, 5.0 }) 
		engfunc(EngFunc_SetModel, Gift, GBox)
		engfunc(EngFunc_SetOrigin, Gift, Vector)
		set_pev(Gift, pev_solid, SOLID_TRIGGER)
		set_pev(Gift, pev_movetype, MOVETYPE_TOSS)
		
		#if defined GLOW_EFF
		new Float:red = random_float(0.0, 255.0)
		new Float:green = random_float(0.0, 255.0)
		new Float:blue = random_float(0.0, 255.0)
		set_pev(Gift, pev_renderfx, kRenderFxGlowShell)
		switch(g_true) {
			case 0:set_pev(Gift, pev_rendercolor, g_red, g_green, g_blue)
			case 1:set_pev(Gift, pev_rendercolor, red, green, blue)
		}
		set_pev(Gift, pev_rendermode, kRenderNormal)
		set_pev(Gift, pev_renderamt, float(g_amount))
		#endif
		
		get_position(Ent, random(2) ? (random_float(-400.0, -100.0)) : (random_float(100.0, 400.0)), random_float(-500.0, 500.0), random_float(-1000.0, 1000.0), Vector)
		xs_vec_normalize(Vector, Vector)
		xs_vec_mul_scalar(Vector, 600.0, Vector)
		set_pev(Gift, pev_velocity, Vector)
	}
}

public Touch_Box(Ent, Player) {
	#if defined ONEBOX
	static bool:TouchPlayer[33]
	#endif
	if (!pev_valid(Ent) || !is_user_alive(Player))
		return HAM_IGNORED
	
	new ClassName[32]
	pev(Ent, pev_classname, ClassName, charsmax(ClassName))
	
	#if defined ONEBOX
	if (!equal(ClassName, "sBox") || TouchPlayer[Player])
		return HAM_IGNORED
	#else
	if (!equal(ClassName, "sBox"))
		return HAM_IGNORED
	#endif
		
	new Reward = random_num(min_rewards, max_rewards)
		
	zl_give_reward(Player, Reward)
	
	set_hudmessage(h_red, h_green, h_blue, 0.29, 0.59, 0, 6.0, 12.0)
	show_hudmessage(Player, "%L", LANG_PLAYER, "SUPPLY_SPAWN", Reward)
	
	TouchPlayer[Player] = true
	
	engfunc(EngFunc_RemoveEntity, Ent)
	return HAM_HANDLED
}

public Hook_Killed(victim, attacker, corpse) {
	if (!pev_valid(victim) || !is_user_alive(attacker))
		return HAM_IGNORED
	
	if (!zl_boss_valid(victim))
		return HAM_IGNORED
	
	SpawnBox(victim)
	return HAM_HANDLED
}

public plugin_precache()
	precache_model(GBox)
	
stock get_position(id, Float:forw, Float:right, Float:up, Float:vStart[]) {
	new Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
    
	pev(id, pev_origin, vOrigin)
	pev(id, pev_view_ofs,vUp) //for player
	xs_vec_add(vOrigin,vUp,vOrigin)
	pev(id, pev_angles, vAngle) // if normal entity ,use pev_angles
    
	engfunc(EngFunc_AngleVectors, ANGLEVECTOR_FORWARD, vForward)
	angle_vector(vAngle,ANGLEVECTOR_RIGHT,vRight)
	angle_vector(vAngle,ANGLEVECTOR_UP,vUp)
    
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1049\\ f0\\ fs16 \n\\ par }
*/
