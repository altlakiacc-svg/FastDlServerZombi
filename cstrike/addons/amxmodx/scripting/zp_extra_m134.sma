#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fun>
#include <hamsandwich>
#include <xs>
#include <cstrike>
#include <zombieplague>
#include <dhudmessage>

#define ENG_NULLENT		-1
#define EV_INT_WEAPONKEY	EV_INT_impulse
#define M134_WEAPONKEY	722
#define MAX_PLAYERS  			  32
#define IsValidUser(%1) (1 <= %1 <= g_MaxPlayers)

const USE_STOPPED = 0
const OFFSET_ACTIVE_ITEM = 373
const OFFSET_WEAPONOWNER = 41
const OFFSET_LINUX = 4
const OFFSET_LINUX_WEAPONS = 4

#define WEAP_LINUX_XTRA_OFF			4
#define m_fKnown				44
#define m_flNextPrimaryAttack 			46
#define m_flTimeWeaponIdle			48
#define m_iClip					51
#define m_fInReload				54
#define PLAYER_LINUX_XTRA_OFF			5
#define m_flNextAttack				83
#define write_coord_f(%1)	engfunc(EngFunc_WriteCoord,%1)

#define M134_RELOAD_TIME 5.0
#define M134_DRAW_TIME 1.1

const PRIMARY_WEAPONS_BIT_SUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)
new const WEAPONENTNAMES[][] = { "", "weapon_p228", "", "weapon_scout", "weapon_hegrenade", "weapon_xm1014", "weapon_c4", "weapon_mac10",
			"weapon_aug", "weapon_smokegrenade", "weapon_elite", "weapon_fiveseven", "weapon_ump45", "weapon_sg550",
			"weapon_galil", "weapon_famas", "weapon_usp", "weapon_glock18", "weapon_awp", "weapon_mp5navy", "weapon_m249",
			"weapon_m3", "weapon_m4a1", "weapon_tmp", "weapon_g3sg1", "weapon_flashbang", "weapon_deagle", "weapon_sg552",
			"weapon_ak47", "weapon_knife", "weapon_p90" }

new const Fire_Sounds[][] = { "weapons/m134-1.wav" }
new const g_shellent [ ] = "m134_shell"

new const GUNSHOT_DECALS[] = { 41, 42, 43, 44, 45 }
new M134_V_MODEL[64] = "models/re/v_m134_max.mdl"
new M134_P_MODEL[64] = "models/re/p_m134.mdl"
new M134_W_MODEL[64] = "models/re/w_m134.mdl"

new cvar_dmghum_m134, cvar_dmgsurv_m134, cvar_recoil_m134, g_itemid_m134, cvar_clip_m134, cvar_m134_ammo 
new g_has_m134[33]
new g_MaxPlayers, g_orig_event_m134, g_clip_ammo[33] , g_can[33]
new Float:cl_pushangle[MAX_PLAYERS + 1][3], m_iBlood[2]
new g_m134_TmpClip[33] , oldweap[33] , SayText , cvar_shells_m134 , cvar_shellshealth_m134 ,
cvar_speedrun_m134 , cvar_speedrunfire_m134 , cvar_surv_m134 , g_afterreload[33]

public plugin_init()
{
	register_plugin("[ZP] Weapon: M134", "1.0", "Crock / =)")
	register_message(get_user_msgid("DeathMsg"), "message_DeathMsg")
	register_event("CurWeapon","CurrentWeapon","be","1=1")
	register_think(g_shellent,"think_shell")
	register_forward(FM_SetModel, "fw_SetModel")
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)
	register_forward(FM_PlaybackEvent, "fwPlaybackEvent")
	register_forward(FM_CmdStart, "fw_CmdStart")
	register_forward(FM_PlayerPreThink, "fw_PlayerPreThink")

	RegisterHam(Ham_Item_AddToPlayer, "weapon_m249", "fw_M134_AddToPlayer")
	RegisterHam(Ham_Use, "func_tank", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tankmortar", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tankrocket", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tanklaser", "fw_UseStationary_Post", 1)
	for (new i = 1; i < sizeof WEAPONENTNAMES; i++)
		if (WEAPONENTNAMES[i][0]) RegisterHam(Ham_Item_Deploy, WEAPONENTNAMES[i], "fw_Item_Deploy_Post", 1)
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_m249", "fw_M134_PrimaryAttack")
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_m249", "fw_M134_PrimaryAttack_Post", 1)
	RegisterHam(Ham_Item_PostFrame, "weapon_m249", "M134__ItemPostFrame");
	RegisterHam(Ham_Weapon_Reload, "weapon_m249", "M134__Reload");
	RegisterHam(Ham_Weapon_Reload, "weapon_m249", "M134__Reload_Post", 1);
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")

	RegisterHam(Ham_TraceAttack, "worldspawn", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_breakable", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_wall", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_door", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_door_rotating", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_plat", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_rotating", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack_Player", 1)

	cvar_dmghum_m134 = register_cvar("zp_dmghum_m134", "1.2")
	cvar_dmgsurv_m134 = register_cvar("zp_dmgsurv_m134", "1.5")
	cvar_recoil_m134 = register_cvar("zp_m134_recoil", "300")
	cvar_clip_m134 = register_cvar("zp_m134_clip", "1600")
	cvar_m134_ammo = register_cvar("zp_m134_ammo", "7000")
	cvar_shells_m134 = register_cvar("zp_m134_shells", "0")
	cvar_shellshealth_m134 = register_cvar("zp_m134_shellslife", "1500.0")
	cvar_speedrunfire_m134 = register_cvar("zp_m134_speedrunfire", "230.0")
	cvar_speedrun_m134 = register_cvar("zp_m134_speedrun", "230.0")
	cvar_surv_m134 = register_cvar("zp_m134_givesurvivor", "1")

	g_itemid_m134 = zp_register_extra_item("M134 \r[Minigun]", 29, ZP_TEAM_HUMAN)

	g_MaxPlayers = get_maxplayers()
	SayText = get_user_msgid("SayText")
}

public plugin_precache()
{
	precache_model(M134_V_MODEL)
	precache_model(M134_P_MODEL)
	precache_model(M134_W_MODEL)
	precache_model("models/re/shell762_m134_01.mdl")
	precache_model("models/re/wnatpoh.mdl")
	precache_sound(Fire_Sounds[0])
	precache_sound("weapons/m134_spinup.wav")
	precache_sound("weapons/m134_spindown.wav")
	precache_sound("weapons/m134_pinpull.wav")
	precache_sound("weapons/m134_coverup.wav")
	precache_sound("weapons/m134_coverdown.wav")
	precache_sound("weapons/m134_clipon.wav")
	precache_sound("weapons/m134_clipoff.wav")
	precache_sound("weapons/m134_chain.wav")
	precache_sound("weapons/m134_boxout.wav")
	precache_sound("weapons/m134_boxin.wav")
	m_iBlood[0] = precache_model("sprites/blood.spr")
	m_iBlood[1] = precache_model("sprites/bloodspray.spr")
	precache_model("sprites/640hud5.spr")
	register_forward(FM_PrecacheEvent, "fwPrecacheEvent_Post", 1)
}

public fwPrecacheEvent_Post(type, const name[])
{
	if (equal("events/m249.sc", name))
	{
		g_orig_event_m134 = get_orig_retval()
		return FMRES_HANDLED
	}
	
	return FMRES_IGNORED
}

public fw_TraceAttack(iEnt, iAttacker, Float:flDamage, Float:fDir[3], ptr, iDamageType)
{
	if(!is_user_alive(iAttacker))
		return;

	new g_currentweapon = get_user_weapon(iAttacker)
	if(g_currentweapon != CSW_M249) return
	
	if(!g_has_m134[iAttacker]) return

	static Float:flEnd[3]
	get_tr2(ptr, TR_vecEndPos, flEnd)
	
	if(iEnt)
	{
		// Put decal on an entity
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_DECAL)
		write_coord_f(flEnd[0])
		write_coord_f(flEnd[1])
		write_coord_f(flEnd[2])
		write_byte(GUNSHOT_DECALS[random_num ( 0, sizeof GUNSHOT_DECALS -1 ) ] )
		write_short(iEnt)
		message_end()
	}
	else
	{
		// Put decal on "world" (a wall)
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_WORLDDECAL)
		write_coord_f(flEnd[0])
		write_coord_f(flEnd[1])
		write_coord_f(flEnd[2])
		write_byte(GUNSHOT_DECALS[random_num ( 0, sizeof GUNSHOT_DECALS -1 ) ] )
		message_end()
	}
	
	// Show sparcles
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_GUNSHOTDECAL)
	write_coord_f(flEnd[0])
	write_coord_f(flEnd[1])
	write_coord_f(flEnd[2])
	write_short(iAttacker)
	write_byte(GUNSHOT_DECALS[random_num ( 0, sizeof GUNSHOT_DECALS -1 ) ] )
	message_end()
}

public fw_TraceAttack_Player(iVictim, iAttacker, Float:flDamage, Float:fDir[3], ptr, iDamageType)
{
	if(!is_user_alive(iAttacker) || zp_get_user_zombie(iAttacker) || !g_has_m134[iAttacker] || get_user_weapon(iAttacker) != CSW_M249 || !zp_get_user_zombie(iVictim))
		return;

	new Float: end[3] 
	get_tr2(ptr, TR_vecEndPos, end); 

	message_begin(MSG_BROADCAST,SVC_TEMPENTITY) 
	write_byte(TE_BLOODSPRITE) 
	engfunc(EngFunc_WriteCoord, end[0]) 
	engfunc(EngFunc_WriteCoord, end[1]) 
	engfunc(EngFunc_WriteCoord, end[2]) 
	write_short(m_iBlood[0]) 
	write_short(m_iBlood[1]) 
	write_byte(249) // color index 
	write_byte(random_num(1, 3)) // size 
	message_end() 

}
public fw_SetModel(entity, model[])
{
	if(!is_valid_ent(entity))
		return FMRES_IGNORED;
	
	static szClassName[33]
	entity_get_string(entity, EV_SZ_classname, szClassName, charsmax(szClassName))
		
	if(!equal(szClassName, "weaponbox"))
		return FMRES_IGNORED;
	
	static iOwner
	
	iOwner = entity_get_edict(entity, EV_ENT_owner)
	
	if(equal(model, "models/w_m249.mdl"))
	{
		static iStoredSVDID
		
		iStoredSVDID = find_ent_by_owner(ENG_NULLENT, "weapon_m249", entity)
	
		if(!is_valid_ent(iStoredSVDID))
			return FMRES_IGNORED;
	
		if(g_has_m134[iOwner])
		{
			entity_set_int(iStoredSVDID, EV_INT_WEAPONKEY, M134_WEAPONKEY)
			g_has_m134[iOwner] = false
			
			entity_set_model(entity, M134_W_MODEL)
			
			return FMRES_SUPERCEDE;
		}
	}
		
	return FMRES_IGNORED;
}
public give_m134(id)
{
	drop_weapons(id, 1);
	new iWep2 = give_item(id,"weapon_m249")
	if( iWep2 > 0 )
	{
		cs_set_weapon_ammo(iWep2, get_pcvar_num(cvar_clip_m134))
		cs_set_user_bpammo (id, CSW_M249, get_pcvar_num(cvar_m134_ammo))
	}
	if(get_user_weapon(id) == CSW_M249)
	{
		replace_weapon_models(id,CSW_M249)
		UTIL_PlayWeaponAnimation(id, 4)
		set_pdata_float(id, m_flNextAttack, M134_DRAW_TIME, PLAYER_LINUX_XTRA_OFF)
	}
	g_has_m134[id] = true;
}
public zp_extra_item_selected(id, itemid)
{
	if(itemid != g_itemid_m134)
		return;
	
	give_m134(id)
}

public fw_M134_AddToPlayer(M134, id)
{
	if(!is_valid_ent(M134) || !is_user_connected(id))
		return HAM_IGNORED;
	
	if(entity_get_int(M134, EV_INT_WEAPONKEY) == M134_WEAPONKEY)
	{
		g_has_m134[id] = true
		
		entity_set_int(M134, EV_INT_WEAPONKEY, 0)
		
		return HAM_HANDLED;
	}
	
	return HAM_IGNORED;
}

public fw_UseStationary_Post(entity, caller, activator, use_type)
{
	if (use_type == USE_STOPPED && is_user_connected(caller))
		replace_weapon_models(caller, get_user_weapon(caller))
}

public fw_Item_Deploy_Post(weapon_ent)
{
	static owner
	owner = fm_cs_get_weapon_ent_owner(weapon_ent)
	
	static weaponid
	weaponid = cs_get_weapon_id(weapon_ent)
	
	replace_weapon_models(owner, weaponid)
}

replace_weapon_models(id, weaponid)
{
	switch (weaponid)
	{
		case CSW_M249:
		{
			if (zp_get_user_zombie(id))
				return;
			
			if(g_has_m134[id])
			{
				set_pev(id, pev_viewmodel2, M134_V_MODEL)
				set_pev(id, pev_weaponmodel2, M134_P_MODEL)

				message_begin(MSG_ONE, get_user_msgid("CurWeapon"), {0,0,0}, id) 
				write_byte(1) 
				write_byte(CSW_KNIFE) 
				write_byte(0) 
				message_end()

				if(oldweap[id] != CSW_M249)
				{
					UTIL_PlayWeaponAnimation(id, 4)
					set_pdata_float(id, m_flNextAttack, M134_DRAW_TIME, PLAYER_LINUX_XTRA_OFF)
				}
			}
		}
	}
	if(weaponid != CSW_M249)
	{
		remove_task(id)
		g_can[id] = 0
		g_afterreload[id] = 0
		if(oldweap[id] == CSW_M249 && g_has_m134[id]) 
		{
			set_dhudmessage(255, 255, 0, 1.0, 0.98, 0, 0.1, 0.1,0.0,0.0)
			show_dhudmessage(id, "")
		}
	}
	oldweap[id] = weaponid
}

public fw_UpdateClientData_Post(Player, SendWeapons, CD_Handle)
{
        if(!is_user_alive(Player) || (get_user_weapon(Player) != CSW_M249) || !g_has_m134[Player])
        return FMRES_IGNORED
	
	set_cd(CD_Handle, CD_flNextAttack, halflife_time () + 0.001)
	return FMRES_HANDLED
}

public fw_M134_PrimaryAttack(Weapon)
{
	new Player = get_pdata_cbase(Weapon, 41, 4)
	
	if (!g_has_m134[Player])
		return HAM_IGNORED;

	if(g_afterreload[Player])
	{
		g_afterreload[Player] = 0
		return HAM_SUPERCEDE;
	}

	new Float:flNextAttack = get_pdata_float(Player, m_flNextAttack, PLAYER_LINUX_XTRA_OFF)

	if(flNextAttack > 0.0)
		return HAM_IGNORED;	

	new szClip, szAmmo
	get_user_weapon(Player, szClip, szAmmo)

	if(!g_can[Player] || g_can[Player] == 3)
	{
		if(szClip <= 0) 
		{
			UTIL_PlayWeaponAnimation(Player,7)
			return HAM_IGNORED;
		}

		set_task(1.0,"user_can",Player)
		g_can[Player] = 1
		set_pdata_float(Player, m_flNextAttack, 1.1, PLAYER_LINUX_XTRA_OFF)
		UTIL_PlayWeaponAnimation(Player,7)
		emit_sound(Player, CHAN_WEAPON, "weapons/m134_spinup.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		return HAM_SUPERCEDE;
	}

	pev(Player,pev_punchangle,cl_pushangle[Player])
	
	g_clip_ammo[Player] = cs_get_weapon_ammo(Weapon)

	return HAM_IGNORED;	
}

public fwPlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if ((eventid != g_orig_event_m134))
		return FMRES_IGNORED
	if (!(1 <= invoker <= g_MaxPlayers))
		return FMRES_IGNORED

	playback_event(flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
	return FMRES_SUPERCEDE
}

public fw_M134_PrimaryAttack_Post(Weapon)
{
	new Player = get_pdata_cbase(Weapon, 41, 4)

	if(!is_user_alive(Player))
		return;

	new szClip, szAmmo
	get_user_weapon(Player, szClip, szAmmo)

	if(g_has_m134[Player])
	{
		if(g_can[Player] != 2)
			return

		if(szClip <= 0)
			UTIL_PlayWeaponAnimation(Player,7)

		if (!g_clip_ammo[Player])
			return

		new Float:push[3]
		pev(Player,pev_punchangle,push)
		xs_vec_sub(push,cl_pushangle[Player],push)
		xs_vec_mul_scalar(push,0.0,push)
		xs_vec_add(push,cl_pushangle[Player],push)
		set_pev(Player,pev_punchangle,push)


		static Float:punchAngle[3];
		punchAngle[0] = float(random_num(-1 * get_pcvar_num(cvar_recoil_m134) - 100, get_pcvar_num(cvar_recoil_m134) - 100)) / 100.0;
		punchAngle[1] = float(random_num(-1 * get_pcvar_num(cvar_recoil_m134), get_pcvar_num(cvar_recoil_m134))) / 100.0;
		punchAngle[2] = 0.0;
		set_pev(Player, pev_punchangle, punchAngle);
		
		emit_sound(Player, CHAN_WEAPON, Fire_Sounds[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		set_pev(Player,pev_effects,pev(Player,pev_effects) | EF_MUZZLEFLASH)
		UTIL_PlayWeaponAnimation(Player,1)
	
		if(get_pcvar_num(cvar_shells_m134)) make_shell(Player)
	}
	if(!g_has_m134[Player])
	{
		if(szClip > 0) emit_sound(Player, CHAN_WEAPON, "weapons/m249-1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	}
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage)
{
    if (victim != attacker && is_user_connected(attacker))
	{

        if(!g_has_m134[attacker])
			return;
	
        if(get_user_weapon(attacker) == CSW_M249)
		{
            if(zp_get_user_survivor(attacker))
		    {
                damage = damage*get_pcvar_float(cvar_dmgsurv_m134)
		    }
            else
		    {
                damage = damage*get_pcvar_float(cvar_dmghum_m134)
		    }		    		             
            SetHamParamFloat(4, damage)
		}
	}
}

public message_DeathMsg(msg_id, msg_dest, id)
{
	static szTruncatedWeapon[33], iAttacker, iVictim
	
	get_msg_arg_string(4, szTruncatedWeapon, charsmax(szTruncatedWeapon))
	
	iAttacker = get_msg_arg_int(1)
	iVictim = get_msg_arg_int(2)
	
	if(!is_user_connected(iAttacker) || iAttacker == iVictim)
		return PLUGIN_CONTINUE

	set_task(1.0,"zero_have",iVictim)
	
	if(equal(szTruncatedWeapon, "m249") && get_user_weapon(iAttacker) == CSW_M249)
	{
		if(g_has_m134[iAttacker])
			set_msg_arg_string(4, "m249")
	}
		
	return PLUGIN_CONTINUE
}

stock fm_cs_get_current_weapon_ent(id)
{
	return get_pdata_cbase(id, OFFSET_ACTIVE_ITEM, OFFSET_LINUX);
}

stock fm_cs_get_weapon_ent_owner(ent)
{
	return get_pdata_cbase(ent, OFFSET_WEAPONOWNER, OFFSET_LINUX_WEAPONS);
}

stock UTIL_PlayWeaponAnimation(const Player, const Sequence)
{
	set_pev(Player, pev_weaponanim, Sequence)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, .player = Player)
	write_byte(Sequence)
	write_byte(pev(Player, pev_body))
	message_end()
}

public fw_CmdStart(id, uc_handle, seed)
{
	if(!is_user_alive(id) || zp_get_user_zombie(id) || get_user_weapon(id) != CSW_M249 || !g_has_m134[id]) 
		return PLUGIN_HANDLED

	new Float:flNextAttack = get_pdata_float(id, m_flNextAttack, PLAYER_LINUX_XTRA_OFF)

	if(flNextAttack > 0.0)
		return PLUGIN_HANDLED;

	new szClip, szAmmo
	get_user_weapon(id, szClip, szAmmo)

	if(szClip <= 0)
		return PLUGIN_HANDLED;	

	if(!(pev(id, pev_oldbuttons) & IN_ATTACK))
	{
		remove_task(id)
		set_pdata_float(id, m_flNextAttack, 0.0, PLAYER_LINUX_XTRA_OFF)
		g_can[id] = 0
	}

	if((pev(id, pev_oldbuttons) & IN_ATTACK) && !(get_uc(uc_handle, UC_Buttons) & IN_ATTACK))
	{
		remove_task(id)
		set_task(1.0,"user_can2",id)
		g_can[id] = 3
		set_pdata_float(id, m_flNextAttack, 1.0, PLAYER_LINUX_XTRA_OFF)
		UTIL_PlayWeaponAnimation(id,5)
		emit_sound(id, CHAN_WEAPON, "weapons/m134_spindown.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		g_can[id] = 0
	}
	
	return PLUGIN_HANDLED
}
public M134__ItemPostFrame(weapon_entity) {
	new id = pev(weapon_entity, pev_owner)
	if (!is_user_connected(id))
		return HAM_IGNORED;

	if (!g_has_m134[id])
		return HAM_IGNORED;

	new Float:flNextAttack = get_pdata_float(id, m_flNextAttack, PLAYER_LINUX_XTRA_OFF)

	new iBpAmmo = cs_get_user_bpammo(id, CSW_M249);
	new iClip = get_pdata_int(weapon_entity, m_iClip, WEAP_LINUX_XTRA_OFF)

	new fInReload = get_pdata_int(weapon_entity, m_fInReload, WEAP_LINUX_XTRA_OFF) 

	if( fInReload && flNextAttack <= 0.0 )
	{
		new j = min(get_pcvar_num(cvar_clip_m134) - iClip, iBpAmmo)
	
		set_pdata_int(weapon_entity, m_iClip, iClip + j, WEAP_LINUX_XTRA_OFF)
		cs_set_user_bpammo(id, CSW_M249, iBpAmmo-j);
		
		set_pdata_int(weapon_entity, m_fInReload, 0, WEAP_LINUX_XTRA_OFF)

		remove_task(id)
		g_can[id] = 0

		fInReload = 0
	}

	return HAM_IGNORED;
}

public M134__Reload(weapon_entity) {
	new id = pev(weapon_entity, pev_owner)
	if (!is_user_connected(id))
		return HAM_IGNORED;

	if (!g_has_m134[id])
		return HAM_IGNORED;

	g_m134_TmpClip[id] = -1;

	new iBpAmmo = cs_get_user_bpammo(id, CSW_M249);
	new iClip = get_pdata_int(weapon_entity, m_iClip, WEAP_LINUX_XTRA_OFF)

	if (iBpAmmo <= 0)
		return HAM_SUPERCEDE;

	if (iClip >= get_pcvar_num(cvar_clip_m134))
		return HAM_SUPERCEDE;


	g_m134_TmpClip[id] = iClip;

	return HAM_IGNORED;
}

public M134__Reload_Post(weapon_entity) {
	new id = pev(weapon_entity, pev_owner)
	if (!is_user_connected(id))
		return HAM_IGNORED;

	if (!g_has_m134[id])
		return HAM_IGNORED;

	if(zp_get_user_survivor(id) && get_pcvar_num(cvar_surv_m134))
		return HAM_SUPERCEDE;

	new szClip, szAmmo
	get_user_weapon(id, szClip, szAmmo)

	if (szClip == get_pcvar_num(cvar_clip_m134))
		return HAM_IGNORED;

	if (szAmmo <= 0)
		return HAM_IGNORED;

	if (g_m134_TmpClip[id] == -1)
		return HAM_IGNORED;

	set_pdata_int(weapon_entity, m_iClip, g_m134_TmpClip[id], WEAP_LINUX_XTRA_OFF)

	set_pdata_float(weapon_entity, m_flTimeWeaponIdle, M134_RELOAD_TIME, WEAP_LINUX_XTRA_OFF)

	set_pdata_float(id, m_flNextAttack, M134_RELOAD_TIME, PLAYER_LINUX_XTRA_OFF)

	set_pdata_int(weapon_entity, m_fInReload, 1, WEAP_LINUX_XTRA_OFF)

	UTIL_PlayWeaponAnimation(id, 3)

	remove_task(id)
	g_can[id] = 0
	g_afterreload[id] = 1

	return HAM_IGNORED;
}

public make_shell(id)
{
	static Float:origin[3], Float:origin2[3],  Float:vSrc[3], Float:angles[3], Float:v_forward[3], Float:v_right[3], Float:v_up[3], Float:gun_position[3], Float:player_origin[3], Float:player_view_offset[3];
	static Float:OriginX[3]
	pev(id, pev_v_angle, angles);
	pev(id, pev_origin, OriginX);
	engfunc(EngFunc_MakeVectors, angles);

	static Float:v_forward2[3] , Float:v_right2[3],  Float:v_up2[3] , Float:vSrc2[3]

	global_get(glb_v_forward, v_forward);
	global_get(glb_v_right, v_right);
	global_get(glb_v_up, v_up);

	global_get(glb_v_forward, v_forward2);
	global_get(glb_v_right, v_right2);
	global_get(glb_v_up, v_up2);


	//m_pPlayer->GetGunPosition( ) = pev->origin + pev->view_ofs
	pev(id, pev_origin, player_origin);
	pev(id, pev_view_ofs, player_view_offset);
	xs_vec_add(player_origin, player_view_offset, gun_position);

	xs_vec_mul_scalar(v_forward, 13.0, v_forward);
	xs_vec_mul_scalar(v_right, 3.0, v_right);
	xs_vec_mul_scalar(v_up, -5.0, v_up);

	xs_vec_mul_scalar(v_forward2, 13.0, v_forward2);
	xs_vec_mul_scalar(v_right2, random_float(0.0,2.5), v_right2);
	xs_vec_mul_scalar(v_up2, -6.0, v_up2);

	xs_vec_add(gun_position, v_forward, origin);
	xs_vec_add(origin, v_right, origin);
	xs_vec_add(origin, v_up, origin);

	xs_vec_add(gun_position, v_forward2, origin2);
	xs_vec_add(origin2, v_right2, origin2);
	xs_vec_add(origin2, v_up2, origin2);

	vSrc[0] = origin[0];
	vSrc[1] = origin[1];
	vSrc[2] = origin[2];

	vSrc2[0] = origin2[0];
	vSrc2[1] = origin2[1];
	vSrc2[2] = origin2[2];

	new ent = create_entity("info_target")
	set_pev(ent, pev_classname, g_shellent)

	engfunc(EngFunc_SetModel,ent, "models/re/wnatpoh.mdl")

	set_pev(ent,pev_mins,Float:{-1.0,-1.0,0.0})
	set_pev(ent,pev_maxs,Float:{1.0,1.0,1.0})
	set_pev(ent,pev_size,Float:{-1.0,-1.0,0.0,1.0,1.0,1.0})
	engfunc(EngFunc_SetSize,ent,Float:{-1.0,-1.0,0.0},Float:{1.0,1.0,1.0})

	set_pev(ent,pev_solid,SOLID_NOT)
	set_pev(ent,pev_movetype,MOVETYPE_TOSS)

	set_pev(ent, pev_origin, vSrc)

	static Float:newangles[3]
	pev(id,pev_angles,newangles)
	set_pev(ent,pev_angles, newangles)

	static Float:flVelocity [ 3 ]
	get_speed_vector ( vSrc2, vSrc, random_float(100.0,150.0), flVelocity )
	set_pev(ent,pev_velocity,flVelocity)

	entity_set_float(ent, EV_FL_health, get_pcvar_float(cvar_shellshealth_m134))

	entity_set_float(ent, EV_FL_nextthink, get_gametime() + 0.01) 

	make_shell2(id)
}

public make_shell2(id)
{
	static Float:origin[3], Float:origin2[3],  Float:vSrc[3], Float:angles[3], Float:v_forward[3], Float:v_right[3], Float:v_up[3], Float:gun_position[3], Float:player_origin[3], Float:player_view_offset[3];
	static Float:OriginX[3]
	pev(id, pev_v_angle, angles);
	pev(id, pev_origin, OriginX);
	engfunc(EngFunc_MakeVectors, angles);

	static Float:v_forward2[3] , Float:v_right2[3],  Float:v_up2[3] , Float:vSrc2[3]

	global_get(glb_v_forward, v_forward);
	global_get(glb_v_right, v_right);
	global_get(glb_v_up, v_up);

	global_get(glb_v_forward, v_forward2);
	global_get(glb_v_right, v_right2);
	global_get(glb_v_up, v_up2);


	//m_pPlayer->GetGunPosition( ) = pev->origin + pev->view_ofs
	pev(id, pev_origin, player_origin);
	pev(id, pev_view_ofs, player_view_offset);
	xs_vec_add(player_origin, player_view_offset, gun_position);

	xs_vec_mul_scalar(v_forward, 13.0, v_forward);
	xs_vec_mul_scalar(v_right, random_float(-4.5,-6.0), v_right);
	xs_vec_mul_scalar(v_up, -3.0, v_up);

	xs_vec_mul_scalar(v_forward2, 0.0, v_forward2);
	xs_vec_mul_scalar(v_right2, 0.0, v_right2);
	xs_vec_mul_scalar(v_up2, 0.0, v_up2);

	xs_vec_add(gun_position, v_forward, origin);
	xs_vec_add(origin, v_right, origin);
	xs_vec_add(origin, v_up, origin);

	xs_vec_add(gun_position, v_forward2, origin2);
	xs_vec_add(origin2, v_right2, origin2);
	xs_vec_add(origin2, v_up2, origin2);

	vSrc[0] = origin[0];
	vSrc[1] = origin[1];
	vSrc[2] = origin[2];

	vSrc2[0] = origin2[0];
	vSrc2[1] = origin2[1];
	vSrc2[2] = origin2[2];

	new ent = create_entity("info_target")
	set_pev(ent, pev_classname, g_shellent)

	engfunc(EngFunc_SetModel,ent, "models/re/shell762_m134_01.mdl")

	set_pev(ent,pev_mins,Float:{-1.0,-1.0,0.0})
	set_pev(ent,pev_maxs,Float:{1.0,1.0,1.0})
	set_pev(ent,pev_size,Float:{-1.0,-1.0,0.0,1.0,1.0,1.0})
	engfunc(EngFunc_SetSize,ent,Float:{-1.0,-1.0,0.0},Float:{1.0,1.0,1.0})

	set_pev(ent,pev_solid,SOLID_NOT)
	set_pev(ent,pev_movetype,MOVETYPE_TOSS)

	set_pev(ent, pev_origin, vSrc)

	static Float:newangles[3]
	pev(id,pev_angles,newangles)
	set_pev(ent,pev_angles, newangles)

	static Float:flVelocity [ 3 ]
	get_speed_vector ( vSrc2, vSrc, random_float(100.0,400.0), flVelocity )
	set_pev(ent,pev_velocity,flVelocity)

	entity_set_float(ent, EV_FL_health, get_pcvar_float(cvar_shellshealth_m134))

	entity_set_float(ent, EV_FL_nextthink, get_gametime() + 0.01) 
}

public think_shell(ent) 
{
	if(!pev_valid(ent))
		return;
	if(!(pev(ent,pev_flags) & FL_ONGROUND))
	{
		new Float:oldangles[3],Float:angles[3]
		pev(ent,pev_angles,oldangles)
		angles[0] = oldangles[0] + random_float(20.0,100.0)
		angles[1] = oldangles[1] + random_float(10.0,40.0)
		angles[2] = oldangles[2] + random_float(10.0,40.0)
		set_pev(ent,pev_angles,angles)
	}
	entity_set_float(ent, EV_FL_health, entity_get_float(ent,EV_FL_health) - 10.0) 
	entity_set_float(ent, EV_FL_nextthink, get_gametime() + 0.01) 
	if(entity_get_float(ent,EV_FL_health) <= 0) remove_entity(ent)
}

public client_PreThink(id)
{
	if(!is_user_alive(id) || zp_get_user_zombie(id) || !g_has_m134[id] || get_user_weapon(id) != CSW_M249)
		return;

	new szClip, szAmmo
	get_user_weapon(id, szClip, szAmmo)

	if(szClip <= 0 && szAmmo <= 0)
		g_can[id] = 0

	set_dhudmessage(255, 255, 0, 1.0, 0.98, 0, 0.1, 0.1,0.0,0.0)

	show_dhudmessage(id, "Ammo: %d / %d",szClip,szAmmo)
}

public fw_PlayerPreThink(id)
{
	if(!is_user_alive(id) || zp_get_user_zombie(id) || !g_has_m134[id] || get_user_weapon(id) != CSW_M249)
		return;

	new szClip
	get_user_weapon(id, szClip)

	if(g_can[id]) set_pev(id, pev_maxspeed, get_pcvar_float(cvar_speedrunfire_m134 ))
	if(!g_can[id] || szClip <= 0) set_pev(id, pev_maxspeed, get_pcvar_float(cvar_speedrun_m134))

}

public zero_have(id) 
{
	g_has_m134[id] = false
	g_can[id] = 0
	g_afterreload[id] = 0
}

public plugin_natives () register_native("give_weapon_m134", "native_give_weapon_add", 1)
public native_give_weapon_add(id) give_m134(id)
public zp_user_infected_post(id) zero_have(id) 
public client_connect(id) zero_have(id) 
public client_disconnect(id) zero_have(id) 
public CurrentWeapon(id) replace_weapon_models(id, read_data(2))
public zp_user_humanized_post(id,surv) if(surv && get_pcvar_num(cvar_surv_m134)) give_m134(id)
public user_can(id) g_can[id] = 2
public user_can2(id) g_can[id] = 0

stock drop_weapons(id, dropwhat)
{
     static weapons[32], num, i, weaponid
     num = 0
     get_user_weapons(id, weapons, num)
     
     for (i = 0; i < num; i++)
     {
          weaponid = weapons[i]
          
          if (dropwhat == 1 && ((1<<weaponid) & PRIMARY_WEAPONS_BIT_SUM))
          {
               static wname[32]
               get_weaponname(weaponid, wname, sizeof wname - 1)
               engclient_cmd(id, "drop", wname)
          }
     }
}

stock get_speed_vector(const Float:origin1[3],const Float:origin2[3],Float:speed, Float:new_velocity[3])
{
	new_velocity[0] = origin2[0] - origin1[0]
	new_velocity[1] = origin2[1] - origin1[1]
	new_velocity[2] = origin2[2] - origin1[2]
	new Float:num = floatsqroot(speed*speed / (new_velocity[0]*new_velocity[0] + new_velocity[1]*new_velocity[1] + new_velocity[2]*new_velocity[2]))
	new_velocity[0] *= num
	new_velocity[1] *= num
	new_velocity[2] *= num
       
	return 1;
} 

stock print_col_chat(const id, const input[], any:...)  
{  
	new count = 1, players[32];  
	static msg[191];  
	vformat(msg, 190, input, 3);  
	replace_all(msg, 190, "!g", "^4"); // Green Color  
	replace_all(msg, 190, "!y", "^1"); // Default Color (󩮠湫)  
	replace_all(msg, 190, "!t", "^3"); // Team Color  
	if (id) players[0] = id; else get_players(players, count, "ch");  
	{  
		for ( new i = 0; i < count; i++ )  
		{  
			if ( is_user_connected(players[i]) )  
			{  
				message_begin(MSG_ONE_UNRELIABLE, SayText, _, players[i]);  
				write_byte(players[i]);  
				write_string(msg);  
				message_end();  
			}  
		}  
	}  
} 