#include <amxmodx>
#include <engine>
#include <xs>
#include <fakemeta>
#include <fakemeta_util>
#include <fun>
#include <hamsandwich>
#include <cstrike>
#include <zombieplague>

#define weapon_newgrenade	"weapon_hegrenade"
#define CSW_NEWGRENADE		CSW_HEGRENADE

#define NAME			"FireGrenade"
#define COST			0

#define DAMAGE			250.0

#define V_MDL			"models/v_firegrenade.mdl"
#define P_MDL			"models/p_firegrenade.mdl"
#define W_MDL			"models/w_firegrenade.mdl"

#define EXP_SND			"weapons/firegrenade-1.wav"

#define NADE_TYPE_FIREBOMB	7878

// Last HitGroup
#define m_LastHitGroup 75
// CS Player CBase Offsets (win32)
#define OFFSET_ACTIVE_ITEM 373
// CS Player PData Offsets (win32)
#define PDATA_SAFE 2
// Linux diff's
#define OFFSET_LINUX 5 // offsets 5 higher in Linux builds
// HACK: pev_ field used to store custom nade types and their values
#define PEV_NADE_TYPE pev_flTimeStepSound

#define TASK_BURN 5465
#define ID_BURN (taskid - TASK_BURN)
new g_burning_duration[33] // burning task duration 
new cvar_fireslowdown, cvar_firedamage, cvar_fireduration
new g_itemid_firegrenade, g_has_firegrenade[33], g_trailSpr, g_flameSpr, g_index_smoke, g_index_explosion, g_newgrenade_variables[10]

public plugin_init()
{
	g_itemid_firegrenade = zp_register_extra_item(NAME, COST, ZP_TEAM_HUMAN)
	
	register_message(get_user_msgid("WeapPickup"), "message_weappickup")
	
	RegisterHam(Ham_Item_Deploy, weapon_newgrenade, "ham_item_deploy_post", 1)
	RegisterHam(Ham_Item_AddToPlayer, weapon_newgrenade, "ham_item_addtoplayer")
	RegisterHam(Ham_Spawn, "player", "ham_spawn_post", 1)
	
	register_forward(FM_SetModel, "fw_SetModel")
	RegisterHam(Ham_Think, "grenade", "fw_ThinkGrenade")
	
	cvar_fireduration = register_cvar("zp_fire_duration", "5")
	cvar_firedamage = register_cvar("zp_fire_damage", "20")
	cvar_fireslowdown = register_cvar("zp_fire_slowdown", "0.5")
}

public plugin_precache()
{
	precache_model(V_MDL)
	precache_model(P_MDL)
	precache_model(W_MDL)
	
	precache_sound(EXP_SND)
	
	precache_generic("sprites/weapon_firegrenade_xx.txt")
	precache_generic("sprites/640hud36.spr")
	precache_generic("sprites/640hud7.spr")
	
	register_clcmd("weapon_firegrenade_xx", "hook")
	
	g_index_smoke = precache_model("sprites/black_smoke3.spr")
	g_index_explosion = precache_model("sprites/eexplo.spr")
	
	g_trailSpr = engfunc(EngFunc_PrecacheModel, "sprites/laserbeam.spr")
	g_flameSpr = engfunc(EngFunc_PrecacheModel, "sprites/flame.spr")
	
	register_message(78, "message_weaponlist")
}

public hook(id)
{ 
	if(!is_user_connected(id))
		return PLUGIN_CONTINUE
		
	engclient_cmd(id, "weapon_hegrenade")
	
	return PLUGIN_HANDLED
}

public message_weappickup(msg_id, msg_dest, id)
{
	if(!is_user_connected(id) || get_msg_arg_int(1) != CSW_NEWGRENADE || !g_has_firegrenade[id])
		return PLUGIN_CONTINUE

	set_weaplist(id, "weapon_firegrenade_xx")
	
	return PLUGIN_CONTINUE
}

public message_weaponlist(msg_id, msg_dest, id)
{
	if(get_msg_arg_int(8) != CSW_NEWGRENADE)
		return PLUGIN_CONTINUE;
	
	g_newgrenade_variables[2] = get_msg_arg_int(2)
	g_newgrenade_variables[3] = get_msg_arg_int(3)
	g_newgrenade_variables[4] = get_msg_arg_int(4)
	g_newgrenade_variables[5] = get_msg_arg_int(5)
	g_newgrenade_variables[6] = get_msg_arg_int(6)
	g_newgrenade_variables[7] = get_msg_arg_int(7)
	g_newgrenade_variables[8] = get_msg_arg_int(8)
	g_newgrenade_variables[9] = get_msg_arg_int(9)
	
	return PLUGIN_CONTINUE;
}

public set_weaplist(id, const string_msg[])
{
	message_begin(MSG_ONE, get_user_msgid("WeaponList"), {0,0,0}, id)
	{
		write_string(string_msg) 
		write_byte(g_newgrenade_variables[2])
		write_byte(g_newgrenade_variables[3])
		write_byte(g_newgrenade_variables[4])
		write_byte(g_newgrenade_variables[5])
		write_byte(g_newgrenade_variables[6])
		write_byte(g_newgrenade_variables[7])
		write_byte(g_newgrenade_variables[8])
		write_byte(g_newgrenade_variables[9])
	}
	message_end()
}

public ham_item_addtoplayer(entity, id)
{
	if(!is_user_connected(id))
		return
		
	if(!g_has_firegrenade[id])
		set_weaplist(id, "weapon_hegrenade")
}

public ham_spawn_post(id) 
{
	if(!get_hegrenade(id)) 
		g_has_firegrenade[id] = 0
		
	remove_task(id+TASK_BURN)
}

public zp_extra_item_selected(id, itemid)
{
	if(itemid == g_itemid_firegrenade)
	{
		if(get_hegrenade(id)){
			client_print(id, print_center, "You already have this weapon!")
			return ZP_PLUGIN_HANDLED;
		}
	
		g_has_firegrenade[id] = 1
		give_item(id, weapon_newgrenade)
		
		// Replace weapon models (bugfix)
		static weapon_ent
		weapon_ent = fm_cs_get_current_weapon_ent(id)
	
		if (pev_valid(weapon_ent))
			ExecuteHamB(Ham_Item_Deploy, weapon_ent)
	}
	return PLUGIN_CONTINUE;
}

public zp_user_infected_post(id){
	g_has_firegrenade[id] = 0
}

public client_putinserver(id){
	g_has_firegrenade[id] = 0
}

public client_disconnect(id){
	remove_task(id+TASK_BURN)
}

public ham_item_deploy_post(weapon_ent)
{
	new id = get_pdata_cbase(weapon_ent, 41, 4)
	
	if(!is_user_connected(id) || !g_has_firegrenade[id])
		return
	
	set_pev(id, pev_viewmodel2, V_MDL)
	set_pev(id, pev_weaponmodel2, P_MDL)
}

// Forward Set Model
public fw_SetModel(entity, const model[])
{
	// Invalid entity
	if (!pev_valid(entity)) 
		return HAM_IGNORED;
		
	new id; id = pev(entity, pev_owner)
	
	// We don't care
	if (strlen(model) < 8)
		return  HAM_IGNORED;
		
	// Narrow down our matches a bit
	if (model[7] != 'w' || model[8] != '_')
		return  HAM_IGNORED;
		
	// Get damage time of grenade
	static Float:dmgtime
	pev(entity, pev_dmgtime, dmgtime)
	
	// Grenade not yet thrown
	if (dmgtime == 0.0)
		return FMRES_IGNORED;

	if ((model[9] == 'h' && model[10] == 'e') && (is_user_connected(id) && g_has_firegrenade[id]))
	{
		g_has_firegrenade[id] = false
		
		// Set grenade type on the thrown grenade entity
		set_pev(entity, PEV_NADE_TYPE, NADE_TYPE_FIREBOMB)
		
		fm_set_rendering(entity, kRenderFxNone, 0, 0, 0, kRenderNormal, 0);
		
		// And a colored trail
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_BEAMFOLLOW) // TE id
		write_short(entity) // entity
		write_short(g_trailSpr) // sprite
		write_byte(10) // life
		write_byte(10) // width
		write_byte(200) // r
		write_byte(0) // g
		write_byte(0) // b
		write_byte(200) // brightness
		message_end()
		
		entity_set_model(entity, W_MDL)
	
		return HAM_SUPERCEDE;
	}
	return HAM_IGNORED;
}

// Ham Grenade Think Forward
public fw_ThinkGrenade(entity)
{
	// Invalid entity
	if (!pev_valid(entity)) 
		return HAM_IGNORED;
	
	// Get damage time of grenade
	static Float:dmgtime, Float:current_time
	pev(entity, pev_dmgtime, dmgtime)
	current_time = get_gametime()
	
	// Check if it's time to go off
	if (dmgtime > current_time)
		return HAM_IGNORED;
	
	// Check if it's one of our custom nades
	switch (pev(entity, PEV_NADE_TYPE))
	{
		case NADE_TYPE_FIREBOMB: // Napalm Grenade
		{
			firegrenade_explode(entity)
			return HAM_SUPERCEDE;
		}
	}
	return HAM_IGNORED;
}

firegrenade_explode(ent)
{
	new owner=pev(ent, pev_owner)
	
	new Float:Origin[3], victim
	
	pev(ent, pev_origin, Origin)
	
	while((victim=fm_find_ent_in_sphere(victim, Origin, 240.0))!=0)
	{	
		if(pev(victim, pev_takedamage)!=DAMAGE_NO && pev(victim, pev_solid) != SOLID_NOT)
		{
			if(is_user_alive(victim))
			{
				if(zp_get_user_zombie(victim))
				{
					ExecuteHamB(Ham_TakeDamage, victim , ent ,owner, DAMAGE, DMG_BURN)
					
					set_pdata_int(victim, m_LastHitGroup, HIT_GENERIC)
					
					g_burning_duration[victim] += get_pcvar_num(cvar_fireduration) * 5
		
					// Set burning task on victim if not present
					if (!task_exists(victim+TASK_BURN))
						set_task(0.2, "burning_flame", victim+TASK_BURN, _, _, "b")
				}
			}
			else
				ExecuteHamB(Ham_TakeDamage, victim , ent ,owner, DAMAGE, DMG_BURN)
		}
	}
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION) // Temporary entity ID
	engfunc(EngFunc_WriteCoord, Origin[0]) // engfunc because float
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2] + 40)
	write_short(g_index_explosion) // Sprite index
	write_byte(41) // Scale
	write_byte(15) // Framerate
	write_byte(0) // Flags
	message_end()
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_SMOKE) // Temporary entity IF
	engfunc(EngFunc_WriteCoord, Origin[0]) // Pos X
	engfunc(EngFunc_WriteCoord, Origin[1]) // Pos Y
	engfunc(EngFunc_WriteCoord, Origin[2]) // Pos Z
	write_short(g_index_smoke) // Sprite index
	write_byte(25) // Scale
	write_byte(17) // Framerate
	message_end()
			
	engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, Origin, 0)
	write_byte(TE_WORLDDECAL)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2])
	write_byte(engfunc(EngFunc_DecalIndex, "{scorch3"))
	message_end()
	
	emit_sound(ent, CHAN_WEAPON, EXP_SND, VOL_NORM, ATTN_NORM, 0, PITCH_NORM) 
	
	engfunc(EngFunc_RemoveEntity, ent)
}

// Get User Current Weapon Entity
stock fm_cs_get_current_weapon_ent(id)
{
	// Prevent server crash if entity's private data not initalized
	if (pev_valid(id) != PDATA_SAFE)
		return -1;
	
	return get_pdata_cbase(id, OFFSET_ACTIVE_ITEM, OFFSET_LINUX);
}


public get_hegrenade(id)
{
	static weapons[32], num, i, weaponid
	num = 0
	get_user_weapons(id, weapons, num)

	for (i = 0; i < num; i++)
	{
		weaponid = weapons[i]

		if ((1<<weaponid) & (1<<CSW_NEWGRENADE))
			return 1;
	}
	return 0;
}

// Burning Flames
public burning_flame(taskid)
{
	// Get player origin and flags
	static origin[3], flags
	get_user_origin(ID_BURN, origin)
	flags = pev(ID_BURN, pev_flags)
	
	// Madness mode - in water - burning stopped
	if ((flags & FL_INWATER) || g_burning_duration[ID_BURN] < 1 || !is_user_alive(ID_BURN))
	{
		// Smoke sprite
		message_begin(MSG_PVS, SVC_TEMPENTITY, origin)
		write_byte(TE_SMOKE) // TE id
		write_coord(origin[0]) // x
		write_coord(origin[1]) // y
		write_coord(origin[2]-50) // z
		write_short(g_index_smoke) // sprite
		write_byte(random_num(15, 20)) // scale
		write_byte(random_num(10, 20)) // framerate
		message_end()
		
		// Task not needed anymore
		remove_task(taskid);
		return;
	}
	
	// Fire slow down, unless nemesis
	if (!zp_get_user_nemesis(ID_BURN) && (flags & FL_ONGROUND) && get_pcvar_float(cvar_fireslowdown) > 0.0)
	{
		static Float:velocity[3]
		pev(ID_BURN, pev_velocity, velocity)
		xs_vec_mul_scalar(velocity, get_pcvar_float(cvar_fireslowdown), velocity)
		set_pev(ID_BURN, pev_velocity, velocity)
	}
	
	// Get player's health
	static health
	health = pev(ID_BURN, pev_health)
	
	// Take damage from the fire
	if (health - floatround(get_pcvar_float(cvar_firedamage), floatround_ceil) > 0)
		fm_set_user_health(ID_BURN, health - floatround(get_pcvar_float(cvar_firedamage), floatround_ceil))
	
	// Flame sprite
	message_begin(MSG_PVS, SVC_TEMPENTITY, origin)
	write_byte(TE_SPRITE) // TE id
	write_coord(origin[0]+random_num(-5, 5)) // x
	write_coord(origin[1]+random_num(-5, 5)) // y
	write_coord(origin[2]+random_num(-10, 10)) // z
	write_short(g_flameSpr) // sprite
	write_byte(random_num(5, 10)) // scale
	write_byte(200) // brightness
	message_end()
	
	// Decrease burning duration counter
	g_burning_duration[ID_BURN]--
}