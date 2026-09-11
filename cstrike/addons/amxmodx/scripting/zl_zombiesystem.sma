//-----------
// [API] ZombieSystem
//
// NPC Forum
// http://zombielite.Ru/
//--
// By Alexander.3
// http://Alexander3.Ru/

#include < amxmodx >
#include < engine >
#include < hamsandwich >
#include < fakemeta >
#include < xs >

#define NAME 			"[API] ZombieSystem"
#define VERSION			"1.3"
#define AUTHOR			"Alexander.3"

#define BLOOD

new const ZombieMdl[] = 		"models/zl/npc/zombie/classic.mdl"
#if defined BLOOD
const zombie_blood = 		83
#endif
const zombie_limit =		30
const Float:time_attack = 	0.5
const Float:time_delete =	10.0

native zl_player_random()
native zl_boss_map()

new const SoundList[][] = {
	"zl/npc/zombie/die1.wav",
	"zl/npc/zombie/die2.wav",
	"zl/npc/zombie/pain1.wav",
	"zl/npc/zombie/pain2.wav",
	"zl/npc/zombie/pain3.wav"
}

static Float:Speed
static Float:Damage
static ZombieNpc[zombie_limit]
static ZombieNum, ZombieCount

public plugin_init() {
	register_plugin(NAME, VERSION, AUTHOR)
	
	if (!zl_boss_map())
		return
	
	#if defined BLOOD
	RegisterHam(Ham_BloodColor, "info_target", "Hook_BloodColor")
	#endif
	RegisterHam(Ham_Think, "info_target", "Hook_Think")
	RegisterHam(Ham_Touch, "info_target", "Hook_Touch")
	RegisterHam(Ham_Killed, "info_target", "Hook_Killed")
}

public native_zl_zombie_create(Float:Origin[3], Health, speed, damage) {
	if ( ZombieCount >= zombie_limit )
		return 
		
	for (new i; i < zombie_limit; ++i) {
		if (pev_valid(ZombieNpc[i]))
			continue
	
		ZombieNum = i
	}
	
	param_convert(1)
	
	ZombieNpc[ZombieNum] = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
		
	engfunc(EngFunc_SetModel, ZombieNpc[ZombieNum], ZombieMdl)
	engfunc(EngFunc_SetSize, ZombieNpc[ZombieNum], Float:{-15.0, -15.0, -36.0}, Float:{15.0, 15.0, 96.0})
	engfunc(EngFunc_SetOrigin, ZombieNpc[ZombieNum], Origin)
	
	new ClassName[32]
	formatex(ClassName, charsmax(ClassName), "NpcZombie_%d", ZombieCount)
	
	set_pev(ZombieNpc[ZombieNum], pev_classname, ClassName)
	set_pev(ZombieNpc[ZombieNum], pev_solid, SOLID_BBOX)
	set_pev(ZombieNpc[ZombieNum], pev_movetype, MOVETYPE_PUSHSTEP)
	set_pev(ZombieNpc[ZombieNum], pev_takedamage, DAMAGE_YES)
	set_pev(ZombieNpc[ZombieNum], pev_health, float(Health))
	set_pev(ZombieNpc[ZombieNum], pev_deadflag, DEAD_NO)
	set_pev(ZombieNpc[ZombieNum], pev_nextthink, get_gametime() + 0.1)
	
	Speed = float(speed)
	Damage = float(damage)
	
	drop_to_floor(ZombieNpc[ZombieNum])
	Anim(ZombieNpc[ZombieNum], 2, 1.0)
	
	ZombieCount++
}

public Hook_Think(Ent) {

	if (!pev_valid(Ent))
		return HAM_IGNORED
		
	if (!native_zl_zombie_valid(Ent))
		return HAM_IGNORED
		
	if (pev(Ent, pev_deadflag) == DEAD_DYING)
		return HAM_IGNORED
		
	static id
	if (!is_user_alive(id)) {
		id = zl_player_random()
		set_pev(Ent, pev_nextthink, get_gametime() + 0.2)
		return HAM_HANDLED
	}
	if(pev(Ent, pev_fuser1) == 500.0) {
		set_pev(Ent, pev_fuser1, 0.0)
		Anim(Ent, 2, 1.0)
	}
	
	static Float:Origin[3], Float:eOrigin[3], Float:Angle[3], Float:Vector[3]
	pev(id, pev_origin, Origin)
	pev(Ent, pev_origin, eOrigin)
	xs_vec_sub(Origin, eOrigin, Vector)
	vector_to_angle(Vector, Angle)
	Angle[0] = 0.0
	Angle[2] = 0.0
	xs_vec_normalize(Vector, Vector)
	xs_vec_mul_scalar(Vector, Speed, Vector)
	if(Vector[2] > 0.0)
		Vector[2] = 0.0
	else
		Vector[2] -= 500.0 
	set_pev(Ent, pev_velocity, Vector)
	set_pev(Ent, pev_angles, Angle)
	set_pev(Ent, pev_nextthink, get_gametime() + 0.2)
	return HAM_HANDLED
}

public Hook_Killed(victim, attacker, corpse) {
	if (!native_zl_zombie_valid(victim))
		return HAM_IGNORED
	
	if (pev(victim, pev_deadflag) == DEAD_DYING)
		return HAM_IGNORED
	
	set_pev(victim, pev_velocity, {0.0, 0.0, 0.0})
	set_pev(victim, pev_solid, SOLID_NOT)
	set_pev(victim, pev_deadflag, DEAD_DYING)
	Anim(victim, random_num(5, 6), 1.1)
	set_task(time_delete, "Zombie_Delete", victim)
	
	engfunc(EngFunc_EmitSound, victim, CHAN_VOICE, SoundList[_:random(2)], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	return HAM_SUPERCEDE
}

public Zombie_Delete(id) {
	engfunc(EngFunc_RemoveEntity, id)
	ZombieCount--
}

public Hook_Touch(Ent, id) {
	if (!native_zl_zombie_valid(Ent) || !is_user_alive(id))
		return HAM_IGNORED	
		
	if (pev(Ent, pev_deadflag) == DEAD_DYING)
		return HAM_IGNORED

	ExecuteHamB(Ham_TakeDamage, id, 0, id, Damage, DMG_GENERIC)
	set_pev(Ent, pev_nextthink, get_gametime() + time_attack)
	set_pev(Ent, pev_fuser1, 500.0)
	Anim(Ent, 3, 1.0)	
	
	return HAM_HANDLED
}

#if defined BLOOD
public Hook_BloodColor(Ent) {
	if (!native_zl_zombie_valid(Ent))
		return HAM_IGNORED
	
	engfunc(EngFunc_EmitSound, Ent, CHAN_VOICE, SoundList[_:random_num(2, 4)], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	SetHamReturnInteger(zombie_blood)
	
	return HAM_SUPERCEDE
}
#endif

public plugin_natives() {
	register_native("zl_zombie_valid", "native_zl_zombie_valid", 1)
	register_native("zl_zombie_count", "native_zl_zombie_count", 1)
	register_native("zl_zombie_create", "native_zl_zombie_create", 1)
}

public native_zl_zombie_valid(index) {
	if (!pev_valid(index))
		return 0
		
	static ClassName[63]
	pev(index, pev_classname, ClassName, charsmax(ClassName))
	
	if (contain(ClassName, "NpcZombie_" ) != -1) return 1
	return 0
}

public native_zl_zombie_count() {
	return ZombieCount
}

public plugin_precache() {
	precache_model(ZombieMdl)
	
	for (new i; i < sizeof SoundList; ++i)
		precache_sound(SoundList[i])
}

stock Anim(ent, sequence, Float:speed) {		
	set_pev(ent, pev_sequence, sequence)
	set_pev(ent, pev_animtime, halflife_time())
	set_pev(ent, pev_framerate, speed)
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1049\\ f0\\ fs16 \n\\ par }
*/
