#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fun>
#include <hamsandwich>
#include <xs>
#include <cstrike>
#include <zombieplague>

enum
{
	anim_idle,
	anim_reload,
	anim_draw,
	anim_shoot1,
	anim_shoot2,
	anim_shoot3
}

#define ENG_NULLENT		-1
#define EV_INT_WEAPONKEY	EV_INT_impulse
#define AKLONG_WEAPONKEY	901
#define XM8_WEAPONKEY		902
#define GUITAR_WEAPONKEY	904
#define BENZO_WEAPONKEY	905
#define DMP7A1_WEAPONKEY	906
#define KRISS_WEAPONKEY	907
#define MAX_PLAYERS  			  32
#define IsValidUser(%1) (1 <= %1 <= g_MaxPlayers)

const USE_STOPPED = 0
const OFFSET_ACTIVE_ITEM = 373
const OFFSET_WEAPONOWNER = 41
const OFFSET_LINUX = 5
const OFFSET_LINUX_WEAPONS = 4

#define WEAP_LINUX_XTRA_OFF			4
#define m_fKnown				44
#define m_flNextPrimaryAttack 			46
#define m_flTimeWeaponIdle			48
#define m_iClip					51
#define m_fInReload				54
#define PLAYER_LINUX_XTRA_OFF			5
#define m_flNextAttack				83

#define BENZO_RELOAD_TIME 3.5
#define DMP7A1_RELOAD_TIME 3.5
#define AKLONG_RELOAD_TIME 2.5

const PRIMARY_WEAPONS_BIT_SUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)
new const WEAPONENTNAMES[][] = { "", "weapon_p228", "", "weapon_scout", "weapon_hegrenade", "weapon_xm1014", "weapon_c4", "weapon_mac10",
			"weapon_aug", "weapon_smokegrenade", "weapon_elite", "weapon_fiveseven", "weapon_ump45", "weapon_sg550",
			"weapon_galil", "weapon_famas", "weapon_usp", "weapon_glock18", "weapon_awp", "weapon_mp5navy", "weapon_m249",
			"weapon_m3", "weapon_m4a1", "weapon_tmp", "weapon_g3sg1", "weapon_flashbang", "weapon_deagle", "weapon_sg552",
			"weapon_ak47", "weapon_knife", "weapon_p90" }
new const Fire_Sounds[][] = { "weapons/ak_long-1.wav", "weapons/xm8_carbinee.wav", "weapons/guitar_shoot1.wav", "weapons/watergun_shoot1.wav", "weapons/dmp7-1.wav", "weapons/kriss_shoot2.wav", "weapons/kriss_shoot1.wav" }
new const Sound_Zoom[] = { "weapons/zoom.wav" }
new const GUNSHOT_DECALS[] = { 41, 42, 43, 44, 45 }
new AKLONG_V_MODEL[64] = "models/re/v_ak47_long.mdl"
new AKLONG_P_MODEL[64] = "models/re/p_ak47_long.mdl"
new AKLONG_W_MODEL[64] = "models/re/w_ak47_long.mdl"
new XM8_V_MODEL[64] = "models/re/v_xm8.mdl"
new XM8_P_MODEL[64] = "models/re/p_xm8.mdl"
new XM8_W_MODEL[64] = "models/re/w_xm8.mdl"
new GUITAR_V_MODEL[64] = "models/re/v_guitar.mdl"
new GUITAR_P_MODEL[64] = "models/re/p_guitar.mdl"
new GUITAR_W_MODEL[64] = "models/re/w_guitar.mdl"
new BENZO_V_MODEL[64] = "models/re/v_watergun.mdl"
new BENZO_P_MODEL[64] = "models/re/p_watergun.mdl"
new BENZO_W_MODEL[64] = "models/re/w_watergun.mdl"
new DMP7A1_V_MODEL[64] = "models/re/v_dmp7a1.mdl"
new DMP7A1_P_MODEL[64] = "models/re/p_dmp7a1.mdl"
new DMP7A1_W_MODEL[64] = "models/re/w_dmp7a1.mdl"
new KRISS_V_MODEL[64] = "models/re/v_kriss.mdl"
new KRISS_P_MODEL[64] = "models/re/p_kriss.mdl"
new KRISS_W_MODEL[64] = "models/re/w_kriss.mdl"
new cvar_dmg_aklong, cvar_recoil_aklong, cvar_clip_aklong, cvar_aklong_ammo, g_itemid_aklong
new cvar_dmg_xm8, cvar_recoil_xm8, cvar_clip_xm8, cvar_xm8_ammo, g_itemid_xm8
new cvar_dmg_guitar, cvar_recoil_guitar, cvar_clip_guitar, cvar_guitar_ammo, g_itemid_guitar
new cvar_dmg_dmp7a1, cvar_recoil_dmp7a1, cvar_clip_dmp7a1, cvar_dmp7a1_ammo, g_itemid_dmp7a1
new cvar_dmg_kriss, cvar_recoil_kriss, cvar_clip_kriss, cvar_kriss_ammo, g_itemid_kriss
new cvar_recoil_benzo, cvar_clip_benzo, cvar_benzo_ammo, g_itemid_benzo
new g_has_aklong[33], g_has_xm8[33], g_has_guitar[33], g_has_benzo[33], g_has_dmp7a1[33], g_has_kriss[33], g_hasZoom[33]
new g_MaxPlayers, g_orig_event_aklong, g_orig_event_xm8, g_orig_event_guitar, g_orig_event_benzo, g_orig_event_dmp7a1, g_orig_event_kriss, g_IsInPrimaryAttack, g_clip_ammo[33]
new Float:cl_pushangle[MAX_PLAYERS + 1][3], m_iBlood[2]
new g_benzo_TmpClip[33], g_dmp7a1_TmpClip[33], g_aklong_TmpClip[33], g_kriss_TmpClip[33]
public plugin_init()
{
	register_plugin("[ZP] Extra: Automate", "1.0", "Crock")
	register_message(get_user_msgid("DeathMsg"), "message_DeathMsg")
	register_event("CurWeapon","CurrentWeapon","be","1=1")
	RegisterHam(Ham_Item_AddToPlayer, "weapon_ak47", "fw_AKLONG_AddToPlayer")
	RegisterHam(Ham_Item_AddToPlayer, "weapon_aug", "fw_XM8_AddToPlayer")
	RegisterHam(Ham_Item_AddToPlayer, "weapon_galil", "fw_GUITAR_AddToPlayer")
	RegisterHam(Ham_Item_AddToPlayer, "weapon_ump45", "fw_BENZO_AddToPlayer")
	RegisterHam(Ham_Item_AddToPlayer, "weapon_mac10", "fw_DMP7A1_AddToPlayer")
	RegisterHam(Ham_Item_AddToPlayer, "weapon_m4a1", "fw_KRISS_AddToPlayer")
	RegisterHam(Ham_Use, "func_tank", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tankmortar", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tankrocket", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tanklaser", "fw_UseStationary_Post", 1)
	for (new i = 1; i < sizeof WEAPONENTNAMES; i++)
		if (WEAPONENTNAMES[i][0]) RegisterHam(Ham_Item_Deploy, WEAPONENTNAMES[i], "fw_Item_Deploy_Post", 1)
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_ak47", "fw_AKLONG_PrimaryAttack")
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_ak47", "fw_AKLONG_PrimaryAttack_Post", 1)
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_aug", "fw_XM8_PrimaryAttack")
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_aug", "fw_XM8_PrimaryAttack_Post", 1)
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_galil", "fw_GUITAR_PrimaryAttack")
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_galil", "fw_GUITAR_PrimaryAttack_Post", 1)
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_ump45", "fw_BENZO_PrimaryAttack")
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_ump45", "fw_BENZO_PrimaryAttack_Post", 1)
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_mac10", "fw_DMP7A1_PrimaryAttack")
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_mac10", "fw_DMP7A1_PrimaryAttack_Post", 1)
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_m4a1", "fw_KRISS_PrimaryAttack")
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_m4a1", "fw_KRISS_PrimaryAttack_Post", 1)
	RegisterHam(Ham_Item_PostFrame, "weapon_ump45", "BENZO__ItemPostFrame");
	RegisterHam(Ham_Weapon_Reload, "weapon_ump45", "BENZO__Reload");
	RegisterHam(Ham_Weapon_Reload, "weapon_ump45", "BENZO__Reload_Post", 1);
	RegisterHam(Ham_Item_PostFrame, "weapon_mac10", "DMP7A1__ItemPostFrame");
	RegisterHam(Ham_Weapon_Reload, "weapon_mac10", "DMP7A1__Reload");
	RegisterHam(Ham_Weapon_Reload, "weapon_mac10", "DMP7A1__Reload_Post", 1);
	RegisterHam(Ham_Item_PostFrame, "weapon_m4a1", "KRISS__ItemPostFrame");
	RegisterHam(Ham_Weapon_Reload, "weapon_m4a1", "KRISS__Reload");
	RegisterHam(Ham_Item_PostFrame, "weapon_ak47", "AKLONG__ItemPostFrame");
	RegisterHam(Ham_Weapon_Reload, "weapon_ak47", "AKLONG__Reload");
	RegisterHam(Ham_Weapon_Reload, "weapon_ak47", "AKLONG__Reload_Post", 1);
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	register_forward(FM_SetModel, "fw_SetModel")
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)
	register_forward(FM_PlaybackEvent, "fwPlaybackEvent")
	register_forward(FM_CmdStart, "fw_CmdStart")

	cvar_dmg_aklong = register_cvar("zp_aklong_dmg", "4.5")
	cvar_recoil_aklong = register_cvar("zp_aklong_recoil", "0.6")
	cvar_clip_aklong = register_cvar("zp_aklong_clip", "60")
        cvar_aklong_ammo = register_cvar("zp_aklong_ammo", "400")

	cvar_dmg_xm8 = register_cvar("zp_xm8_dmg", "4.75")
	cvar_recoil_xm8 = register_cvar("zp_xm8_recoil", "0.6")
	cvar_clip_xm8 = register_cvar("zp_xm8_clip", "40")
        cvar_xm8_ammo = register_cvar("zp_xm8_ammo", "400")

	cvar_dmg_guitar = register_cvar("zp_guitar_dmg", "5.0")
	cvar_recoil_guitar = register_cvar("zp_guitar_recoil", "0.6")
	cvar_clip_guitar = register_cvar("zp_guitar_clip", "35")
        cvar_guitar_ammo = register_cvar("zp_guitar_ammo", "400")

	cvar_recoil_benzo = register_cvar("zp_benzo_recoil", "0.6")
	cvar_clip_benzo = register_cvar("zp_benzo_clip", "200")
        cvar_benzo_ammo = register_cvar("zp_benzo_ammo", "400")

	cvar_dmg_dmp7a1 = register_cvar("zp_dmp7a1_dmg", "4.0")
	cvar_recoil_dmp7a1 = register_cvar("zp_dmp7a1_recoil", "0.6")
	cvar_clip_dmp7a1 = register_cvar("zp_dmp7a1_clip", "80")
        cvar_dmp7a1_ammo = register_cvar("zp_dmp7a1_ammo", "500")
		
	cvar_dmg_kriss = register_cvar("zp_kriss_dmg", "4.0")
	cvar_recoil_kriss = register_cvar("zp_kriss_recoil", "0.6")
	cvar_clip_kriss = register_cvar("zp_kriss_clip", "50")
        cvar_kriss_ammo = register_cvar("zp_kriss_ammo", "400")		

	g_itemid_aklong = zp_register_extra_item("[AKLONG]", 5, ZP_TEAM_HUMAN)		
	g_itemid_xm8 = zp_register_extra_item("[XM8]", 3, ZP_TEAM_HUMAN)
	g_itemid_guitar = zp_register_extra_item("[GUITAR]", 2, ZP_TEAM_HUMAN)
	g_itemid_benzo = zp_register_extra_item("[WATERGUN]", 4, ZP_TEAM_HUMAN)
	g_itemid_dmp7a1 = zp_register_extra_item("[DMP7A1]", 3, ZP_TEAM_HUMAN)
	g_itemid_kriss = zp_register_extra_item("[KRISS]", 5, ZP_TEAM_HUMAN)
	g_MaxPlayers = get_maxplayers()
}

public plugin_precache()
{
	precache_model(AKLONG_V_MODEL)
	precache_model(AKLONG_P_MODEL)
	precache_model(AKLONG_W_MODEL)
	precache_model(XM8_V_MODEL)
	precache_model(XM8_P_MODEL)
	precache_model(XM8_W_MODEL)
	precache_model(GUITAR_V_MODEL)
	precache_model(GUITAR_P_MODEL)
	precache_model(GUITAR_W_MODEL)
	precache_model(BENZO_V_MODEL)
	precache_model(BENZO_P_MODEL)
	precache_model(BENZO_W_MODEL)
	precache_model(DMP7A1_V_MODEL)
	precache_model(DMP7A1_P_MODEL)
	precache_model(DMP7A1_W_MODEL)
	precache_model(KRISS_V_MODEL)
	precache_model(KRISS_P_MODEL)
	precache_model(KRISS_W_MODEL)	
	precache_sound(Sound_Zoom)
	for(new i = 0; i < sizeof Fire_Sounds; i++)
		precache_sound(Fire_Sounds[i])
	m_iBlood[0] = precache_model("sprites/blood.spr")
	m_iBlood[1] = precache_model("sprites/bloodspray.spr")
	register_forward(FM_PrecacheEvent, "fwPrecacheEvent_Post", 1)
}

public zp_extra_item_selected(id, itemid)
{
	if(itemid == g_itemid_aklong)
	{	
	    drop_weapons(id, 1);
	    new iWep2 = give_item(id,"weapon_ak47")
	    if( iWep2 > 0 )
	    {
	        cs_set_weapon_ammo(iWep2, get_pcvar_num(cvar_clip_aklong))
                cs_set_user_bpammo (id, CSW_AK47, get_pcvar_num(cvar_aklong_ammo))
	    }
	    g_has_aklong[id] = true;
	}
	else if(itemid == g_itemid_xm8)
	{	
	    drop_weapons(id, 1);
	    new iWep3 = give_item(id,"weapon_aug")
	    if( iWep3 > 0 )
	    {
	        cs_set_weapon_ammo(iWep3, get_pcvar_num(cvar_clip_xm8))
                cs_set_user_bpammo (id, CSW_AUG, get_pcvar_num(cvar_xm8_ammo))
	    }
	    g_has_xm8[id] = true;
	}
	else if(itemid == g_itemid_guitar)
	{
		drop_weapons(id, 1);
		new iWep5 = give_item(id,"weapon_galil")
		if( iWep5 > 0 )
		{
			cs_set_weapon_ammo(iWep5, get_pcvar_num(cvar_clip_guitar))
                        cs_set_user_bpammo (id, CSW_GALIL, get_pcvar_num(cvar_guitar_ammo))
		}
		g_has_guitar[id] = true;
	}
	else if(itemid == g_itemid_benzo)
	{
		drop_weapons(id, 1);
		new iWep6 = give_item(id,"weapon_ump45")
		if( iWep6 > 0 )
		{
			cs_set_weapon_ammo(iWep6, get_pcvar_num(cvar_clip_benzo))
                        cs_set_user_bpammo (id, CSW_UMP45, get_pcvar_num(cvar_benzo_ammo))
		}
		g_has_benzo[id] = true;
	}
	else if(itemid == g_itemid_dmp7a1)
	{	
		drop_weapons(id, 1);
		new iWep7 = give_item(id,"weapon_mac10")
		if( iWep7 > 0 )
		{
			cs_set_weapon_ammo(iWep7, get_pcvar_num(cvar_clip_dmp7a1))
                        cs_set_user_bpammo (id, CSW_MAC10, get_pcvar_num(cvar_dmp7a1_ammo))
		}
		g_has_dmp7a1[id] = true;
	}	
	else if(itemid == g_itemid_kriss)
	{	
		drop_weapons(id, 1);
		new iWep8 = give_item(id,"weapon_m4a1")
		if( iWep8 > 0 )
		{
			cs_set_weapon_ammo(iWep8, get_pcvar_num(cvar_clip_kriss))
                        cs_set_user_bpammo (id, CSW_M4A1, get_pcvar_num(cvar_kriss_ammo))
		}
		g_has_kriss[id] = true;
	}
}

public fwPrecacheEvent_Post(type, const name[])
{
	if (equal("events/ak47.sc", name))
	{
		g_orig_event_aklong = get_orig_retval()
		return FMRES_HANDLED
	}
	else if (equal("events/aug.sc", name))
	{
		g_orig_event_xm8 = get_orig_retval()
		return FMRES_HANDLED
	}
	else if (equal("events/galil.sc", name))
	{
		g_orig_event_guitar = get_orig_retval()
		return FMRES_HANDLED
	}
	else if (equal("events/ump45.sc", name))
	{
		g_orig_event_benzo = get_orig_retval()
		return FMRES_HANDLED
	}
	else if (equal("events/mac10.sc", name))
	{
		g_orig_event_dmp7a1 = get_orig_retval()
		return FMRES_HANDLED
	}
	else if (equal("events/m4a1.sc", name))
	{
		g_orig_event_kriss = get_orig_retval()
		return FMRES_HANDLED
	}
	return FMRES_IGNORED
}

public client_connect(id)
{
	g_has_aklong[id] = false
	g_has_xm8[id] = false
	g_has_guitar[id] = false
	g_has_benzo[id] = false
	g_has_dmp7a1[id] = false
	g_has_kriss[id] = false
}

public client_disconnect(id)
{
	g_has_aklong[id] = false
	g_has_xm8[id] = false
	g_has_guitar[id] = false
	g_has_benzo[id] = false
	g_has_dmp7a1[id] = false
	g_has_kriss[id] = false
}

public zp_user_infected_post(id)
{
	if (zp_get_user_zombie(id) || zp_get_user_survivor(id))
	{
		g_has_aklong[id] = false
		g_has_xm8[id] = false
		g_has_guitar[id] = false
		g_has_benzo[id] = false
		g_has_dmp7a1[id] = false
		g_has_kriss[id] = false
	}
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
	
	if(equal(model, "models/w_ak47.mdl"))
	{
		static iStoredSVDID
		
		iStoredSVDID = find_ent_by_owner(ENG_NULLENT, "weapon_ak47", entity)
	
		if(!is_valid_ent(iStoredSVDID))
			return FMRES_IGNORED;
	
		if(g_has_aklong[iOwner])
		{
			entity_set_int(iStoredSVDID, EV_INT_WEAPONKEY, AKLONG_WEAPONKEY)
			
			g_has_aklong[iOwner] = false
			
			entity_set_model(entity, AKLONG_W_MODEL)
			
			return FMRES_SUPERCEDE;
		}
	}
	else if(equal(model, "models/w_aug.mdl"))
	{
		static iStoredSG550ID
		
		iStoredSG550ID = find_ent_by_owner(ENG_NULLENT, "weapon_aug", entity)
		
		if(!is_valid_ent(iStoredSG550ID))
			return FMRES_IGNORED;
		
		if(g_has_xm8[iOwner])
		{
			entity_set_int(iStoredSG550ID, EV_INT_WEAPONKEY, XM8_WEAPONKEY)
			
			g_has_xm8[iOwner] = false
			
			entity_set_model(entity, XM8_W_MODEL)
			
			return FMRES_SUPERCEDE;
		}
	}
	else if(equal(model, "models/w_galil.mdl"))
	{
		static iStoredAWPID
		
		iStoredAWPID = find_ent_by_owner(ENG_NULLENT, "weapon_galil", entity)
		
		if(!is_valid_ent(iStoredAWPID))
			return FMRES_IGNORED;
		
		if(g_has_guitar[iOwner])
		{
			entity_set_int(iStoredAWPID, EV_INT_WEAPONKEY, GUITAR_WEAPONKEY)
			
			g_has_guitar[iOwner] = false
			
			entity_set_model(entity, GUITAR_W_MODEL)
			
			return FMRES_SUPERCEDE;
		}
	}
	else if(equal(model, "models/w_ump45.mdl"))
	{
		static iStoredBENZID
		
		iStoredBENZID = find_ent_by_owner(ENG_NULLENT, "weapon_ump45", entity)
		
		if(!is_valid_ent(iStoredBENZID))
			return FMRES_IGNORED;
		
		if(g_has_benzo[iOwner])
		{
			entity_set_int(iStoredBENZID, EV_INT_WEAPONKEY, BENZO_WEAPONKEY)
			
			g_has_benzo[iOwner] = false
			
			entity_set_model(entity, BENZO_W_MODEL)
			
			return FMRES_SUPERCEDE;
		}
	}
	else if(equal(model, "models/w_mac10.mdl"))
	{
		static iStoredBENZID
		
		iStoredBENZID = find_ent_by_owner(ENG_NULLENT, "weapon_mac10", entity)
		
		if(!is_valid_ent(iStoredBENZID))
			return FMRES_IGNORED;
		
		if(g_has_dmp7a1[iOwner])
		{
			entity_set_int(iStoredBENZID, EV_INT_WEAPONKEY, DMP7A1_WEAPONKEY)
			
			g_has_dmp7a1[iOwner] = false
			
			entity_set_model(entity, DMP7A1_W_MODEL)
			
			return FMRES_SUPERCEDE;
		}
	}
	else if(equal(model, "models/w_m4a1.mdl"))
	{
		static iStoredBENZID
		
		iStoredBENZID = find_ent_by_owner(ENG_NULLENT, "weapon_m4a1", entity)
		
		if(!is_valid_ent(iStoredBENZID))
			return FMRES_IGNORED;
		
		if(g_has_kriss[iOwner])
		{
			entity_set_int(iStoredBENZID, EV_INT_WEAPONKEY, KRISS_WEAPONKEY)
			
			g_has_kriss[iOwner] = false
			
			entity_set_model(entity, KRISS_W_MODEL)
			
			return FMRES_SUPERCEDE;
		}
	}	
	
	return FMRES_IGNORED;
}

public fw_AKLONG_AddToPlayer(AKLONG, id)
{
	if(!is_valid_ent(AKLONG) || !is_user_connected(id))
		return HAM_IGNORED;
	
	if(entity_get_int(AKLONG, EV_INT_WEAPONKEY) == AKLONG_WEAPONKEY)
	{
		g_has_aklong[id] = true
		
		entity_set_int(AKLONG, EV_INT_WEAPONKEY, 0)
		
		return HAM_HANDLED;
	}
	
	return HAM_IGNORED;
}

public fw_XM8_AddToPlayer(XM8, id)
{
	if(!is_valid_ent(XM8) || !is_user_connected(id))
		return HAM_IGNORED;
	
	if(entity_get_int(XM8, EV_INT_WEAPONKEY) == XM8_WEAPONKEY)
	{
		g_has_xm8[id] = true
		
		entity_set_int(XM8, EV_INT_WEAPONKEY, 0)
		
		return HAM_HANDLED;
	}
	
	return HAM_IGNORED;
}

public fw_GUITAR_AddToPlayer(GUITAR, id)
{
	if(!is_valid_ent(GUITAR) || !is_user_connected(id))
		return HAM_IGNORED;
	
	if(entity_get_int(GUITAR, EV_INT_WEAPONKEY) == GUITAR_WEAPONKEY)
	{
		g_has_guitar[id] = true
		
		entity_set_int(GUITAR, EV_INT_WEAPONKEY, 0)
		
		return HAM_HANDLED;
	}
	
	return HAM_IGNORED;
}

public fw_BENZO_AddToPlayer(BENZO, id)
{
	if(!is_valid_ent(BENZO) || !is_user_connected(id))
		return HAM_IGNORED;
	
	if(entity_get_int(BENZO, EV_INT_WEAPONKEY) == BENZO_WEAPONKEY)
	{
		g_has_benzo[id] = true
		
		entity_set_int(BENZO, EV_INT_WEAPONKEY, 0)
		
		return HAM_HANDLED;
	}
	
	return HAM_IGNORED;
}

public fw_DMP7A1_AddToPlayer(dmp7a1, id)
{
	if(!is_valid_ent(dmp7a1) || !is_user_connected(id))
		return HAM_IGNORED;
	
	if(entity_get_int(dmp7a1, EV_INT_WEAPONKEY) == DMP7A1_WEAPONKEY)
	{
		g_has_dmp7a1[id] = true
		
		entity_set_int(dmp7a1, EV_INT_WEAPONKEY, 0)
		
		return HAM_HANDLED;
	}
	
	return HAM_IGNORED;
}

public fw_KRISS_AddToPlayer(kriss, id)
{
	if(!is_valid_ent(kriss) || !is_user_connected(id))
		return HAM_IGNORED;
	
	if(entity_get_int(kriss, EV_INT_WEAPONKEY) == KRISS_WEAPONKEY)
	{
		g_has_kriss[id] = true
		
		entity_set_int(kriss, EV_INT_WEAPONKEY, 0)
		
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

public CurrentWeapon(id)
{
	replace_weapon_models(id, read_data(2))
}

replace_weapon_models(id, weaponid)
{
	switch (weaponid)
	{
		case CSW_AK47:
		{
			if (zp_get_user_zombie(id) || zp_get_user_survivor(id))
				return;
			
			if(g_has_aklong[id])
			{
				set_pev(id, pev_viewmodel2, AKLONG_V_MODEL)
				set_pev(id, pev_weaponmodel2, AKLONG_P_MODEL)
			}
		}
		case CSW_AUG:
		{
			if (zp_get_user_zombie(id) || zp_get_user_survivor(id))
				return;
			
			if(g_has_xm8[id])
			{
				set_pev(id, pev_viewmodel2, XM8_V_MODEL)
				set_pev(id, pev_weaponmodel2, XM8_P_MODEL)
			}
		}
		case CSW_GALIL:
		{
			if (zp_get_user_zombie(id) || zp_get_user_survivor(id))
				return;
			
			if(g_has_guitar[id])
			{
				set_pev(id, pev_viewmodel2, GUITAR_V_MODEL)
				set_pev(id, pev_weaponmodel2, GUITAR_P_MODEL)
			}
		}
		case CSW_UMP45:
		{
			if (zp_get_user_zombie(id) || zp_get_user_survivor(id))
				return;
			
			if(g_has_benzo[id])
			{
				set_pev(id, pev_viewmodel2, BENZO_V_MODEL)
				set_pev(id, pev_weaponmodel2, BENZO_P_MODEL)
			}
		}
		case CSW_MAC10:
		{
			if (zp_get_user_zombie(id) || zp_get_user_survivor(id))
				return;
			
			if(g_has_dmp7a1[id])
			{
				set_pev(id, pev_viewmodel2, DMP7A1_V_MODEL)
				set_pev(id, pev_weaponmodel2, DMP7A1_P_MODEL)
			}
		}
		case CSW_M4A1:
		{
			if (zp_get_user_zombie(id) || zp_get_user_survivor(id))
				return;
			
			if(g_has_kriss[id])
			{
				set_pev(id, pev_viewmodel2, KRISS_V_MODEL)
				set_pev(id, pev_weaponmodel2, KRISS_P_MODEL)
			}
		}		
	}
}

public fw_UpdateClientData_Post(Player, SendWeapons, CD_Handle)
{
	if(!is_user_alive(Player) || (get_user_weapon(Player) != CSW_AK47 && get_user_weapon(Player) != CSW_AUG && get_user_weapon(Player) != CSW_GALIL && get_user_weapon(Player) != CSW_UMP45 && get_user_weapon(Player) != CSW_MAC10 && get_user_weapon(Player) != CSW_M4A1) || 
        (get_user_weapon(Player) == CSW_AK47 && !g_has_aklong[Player]) || (get_user_weapon(Player) == CSW_AUG && !g_has_xm8[Player]) || (get_user_weapon(Player) == CSW_GALIL && !g_has_guitar[Player]) || (get_user_weapon(Player) == CSW_UMP45 && !g_has_benzo[Player]) || (get_user_weapon(Player) == CSW_MAC10 && !g_has_dmp7a1[Player]) || (get_user_weapon(Player) == CSW_M4A1 && !g_has_kriss[Player]))
        return FMRES_IGNORED
	
	set_cd(CD_Handle, CD_flNextAttack, halflife_time () + 0.001)
	return FMRES_HANDLED
}

public fw_AKLONG_PrimaryAttack(Weapon)
{
	new Player = get_pdata_cbase(Weapon, 41, 4)
	
	if (!g_has_aklong[Player])
		return;
	
	g_IsInPrimaryAttack = 1
	pev(Player,pev_punchangle,cl_pushangle[Player])
	
	g_clip_ammo[Player] = cs_get_weapon_ammo(Weapon)
}

public fw_XM8_PrimaryAttack(Weapon)
{
	new Player = get_pdata_cbase(Weapon, 41, 4)
	
	if (!g_has_xm8[Player])
		return;
	
	g_IsInPrimaryAttack = 1
	pev(Player,pev_punchangle,cl_pushangle[Player])
	
	g_clip_ammo[Player] = cs_get_weapon_ammo(Weapon)
}

public fw_GUITAR_PrimaryAttack(Weapon)
{
	new Player = get_pdata_cbase(Weapon, 41, 4)
	
	if (!g_has_guitar[Player])
		return;
	
	g_IsInPrimaryAttack = 1
	pev(Player,pev_punchangle,cl_pushangle[Player])
	
	g_clip_ammo[Player] = cs_get_weapon_ammo(Weapon)
}

public fw_BENZO_PrimaryAttack(Weapon)
{
	new Player = get_pdata_cbase(Weapon, 41, 4)
	
	if (!g_has_benzo[Player])
		return;
	
	g_IsInPrimaryAttack = 1
	pev(Player,pev_punchangle,cl_pushangle[Player])
	
	g_clip_ammo[Player] = cs_get_weapon_ammo(Weapon)
}

public fw_DMP7A1_PrimaryAttack(Weapon)
{
	new Player = get_pdata_cbase(Weapon, 41, 4)
	
	if (!g_has_dmp7a1[Player])
		return;
	
	g_IsInPrimaryAttack = 1
	pev(Player,pev_punchangle,cl_pushangle[Player])
	
	g_clip_ammo[Player] = cs_get_weapon_ammo(Weapon)
}

public fw_KRISS_PrimaryAttack(Weapon)
{
	new Player = get_pdata_cbase(Weapon, 41, 4)
	
	if (!g_has_kriss[Player])
		return;
	
	g_IsInPrimaryAttack = 1
	pev(Player,pev_punchangle,cl_pushangle[Player])
	
	g_clip_ammo[Player] = cs_get_weapon_ammo(Weapon)
}

public fwPlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if ((eventid != g_orig_event_aklong && eventid != g_orig_event_xm8 && eventid != g_orig_event_guitar && eventid != g_orig_event_benzo && eventid != g_orig_event_dmp7a1 && eventid != g_orig_event_kriss) || !g_IsInPrimaryAttack)
		return FMRES_IGNORED
	if (!(1 <= invoker <= g_MaxPlayers))
		return FMRES_IGNORED

	playback_event(flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
	return FMRES_SUPERCEDE
}

public fw_AKLONG_PrimaryAttack_Post(Weapon)
{
	g_IsInPrimaryAttack = 0
	new Player = get_pdata_cbase(Weapon, 41, 4)
	
	if(g_has_aklong[Player])
	{
		new Float:push[3]
		pev(Player,pev_punchangle,push)
		xs_vec_sub(push,cl_pushangle[Player],push)
		
		xs_vec_mul_scalar(push,get_pcvar_float(cvar_recoil_aklong),push)
		xs_vec_add(push,cl_pushangle[Player],push)
		set_pev(Player,pev_punchangle,push)
		
		if (!g_clip_ammo[Player])
			return
		
		emit_sound(Player, CHAN_WEAPON, Fire_Sounds[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		UTIL_PlayWeaponAnimation(Player, anim_shoot1)
	
		make_blood_and_bulletholes(Player)
	}
}

public fw_XM8_PrimaryAttack_Post(Weapon)
{
	g_IsInPrimaryAttack = 0
	new Player = get_pdata_cbase(Weapon, 41, 4)
	
	if(g_has_xm8[Player])
	{
		new Float:push[3]
		pev(Player,pev_punchangle,push)
		xs_vec_sub(push,cl_pushangle[Player],push)
		
		xs_vec_mul_scalar(push,get_pcvar_float(cvar_recoil_xm8),push)
		xs_vec_add(push,cl_pushangle[Player],push)
		set_pev(Player,pev_punchangle,push)
		
		if (!g_clip_ammo[Player])
			return
		
		emit_sound(Player, CHAN_WEAPON, Fire_Sounds[1], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		UTIL_PlayWeaponAnimation(Player, anim_shoot1)
	
		make_blood_and_bulletholes(Player)
	}
}

public fw_GUITAR_PrimaryAttack_Post(Weapon)
{
	g_IsInPrimaryAttack = 0
	new Player = get_pdata_cbase(Weapon, 41, 4)
	
	if(g_has_guitar[Player])
	{
		new Float:push[3]
		pev(Player,pev_punchangle,push)
		xs_vec_sub(push,cl_pushangle[Player],push)
		
		xs_vec_mul_scalar(push,get_pcvar_float(cvar_recoil_guitar),push)
		xs_vec_add(push,cl_pushangle[Player],push)
		set_pev(Player,pev_punchangle,push)
		
		if (!g_clip_ammo[Player])
			return
		
		emit_sound(Player, CHAN_WEAPON, Fire_Sounds[2], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		UTIL_PlayWeaponAnimation(Player, anim_shoot1)
	
		make_blood_and_bulletholes(Player)
	}
}

public fw_BENZO_PrimaryAttack_Post(Weapon)
{
	g_IsInPrimaryAttack = 0
	new Player = get_pdata_cbase(Weapon, 41, 4)
	
	if(g_has_benzo[Player])
	{
		new Float:push[3]
		pev(Player,pev_punchangle,push)
		xs_vec_sub(push,cl_pushangle[Player],push)
		
		xs_vec_mul_scalar(push,get_pcvar_float(cvar_recoil_benzo),push)
		xs_vec_add(push,cl_pushangle[Player],push)
		set_pev(Player,pev_punchangle,push)
		
		if (!g_clip_ammo[Player])
			return
		
		emit_sound(Player, CHAN_WEAPON, Fire_Sounds[3], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		UTIL_PlayWeaponAnimation(Player, anim_shoot1)
	
		make_blood_and_bulletholes(Player)
	}
}

public fw_DMP7A1_PrimaryAttack_Post(Weapon)
{
	g_IsInPrimaryAttack = 0
	new Player = get_pdata_cbase(Weapon, 41, 4)
	
	if(g_has_dmp7a1[Player])
	{
		new Float:push[3]
		pev(Player,pev_punchangle,push)
		xs_vec_sub(push,cl_pushangle[Player],push)
		
		xs_vec_mul_scalar(push,get_pcvar_float(cvar_recoil_dmp7a1),push)
		xs_vec_add(push,cl_pushangle[Player],push)
		set_pev(Player,pev_punchangle,push)
		
		if (!g_clip_ammo[Player])
			return
		
		emit_sound(Player, CHAN_WEAPON, Fire_Sounds[4], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)

		switch(random_num(0,1))
		{
		case 0:
  		UTIL_PlayWeaponAnimation(Player, anim_shoot1)
 		case 1:
  		UTIL_PlayWeaponAnimation(Player, anim_shoot2)
		}
	
		make_blood_and_bulletholes(Player)
	}
}

public fw_KRISS_PrimaryAttack_Post(Weapon)
{
	g_IsInPrimaryAttack = 0
	new Player = get_pdata_cbase(Weapon, 41, 4)
	
	if(g_has_kriss[Player])
	{
		new Float:push[3]
		pev(Player,pev_punchangle,push)
		xs_vec_sub(push,cl_pushangle[Player],push)
		
		xs_vec_mul_scalar(push,get_pcvar_float(cvar_recoil_kriss),push)
		xs_vec_add(push,cl_pushangle[Player],push)
		set_pev(Player,pev_punchangle,push)
		
		if (!g_clip_ammo[Player])
			return
		
		if (cs_get_weapon_silen(Weapon)) {
			emit_sound(Player, CHAN_WEAPON, Fire_Sounds[5], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
			UTIL_PlayWeaponAnimation(Player, 1)
		} else {
			emit_sound(Player, CHAN_WEAPON, Fire_Sounds[6], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
			UTIL_PlayWeaponAnimation(Player, 8)
		}
	
		make_blood_and_bulletholes(Player)
	}
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage)
{
	if (victim != attacker && is_user_connected(attacker))
	{
		if(get_user_weapon(attacker) == CSW_AK47)
		{
			if(g_has_aklong[attacker])
				SetHamParamFloat(4, damage * get_pcvar_float(cvar_dmg_aklong))
		}
		else if(get_user_weapon(attacker) == CSW_AUG)
		{
			if(g_has_xm8[attacker])
				SetHamParamFloat(4, damage * get_pcvar_float(cvar_dmg_xm8))
		}
		else if(get_user_weapon(attacker) == CSW_MAC10)
		{
			if(g_has_dmp7a1[attacker])
				SetHamParamFloat(4, damage * get_pcvar_float(cvar_dmg_dmp7a1))
		}
		else if(get_user_weapon(attacker) == CSW_GALIL)
		{
			if(g_has_guitar[attacker])
				SetHamParamFloat(4, damage * get_pcvar_float(cvar_dmg_guitar))
		}
		else if(get_user_weapon(attacker) == CSW_M4A1)
		{
			if(g_has_kriss[attacker])
				SetHamParamFloat(4, damage * get_pcvar_float(cvar_dmg_kriss))
		}		
	}
	if(IsValidUser( attacker ) && victim != attacker && zp_get_user_zombie( victim )
	&& get_user_weapon( attacker ) == CSW_UMP45)
	{

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
	
	if(equal(szTruncatedWeapon, "ak47") && get_user_weapon(iAttacker) == CSW_AK47)
	{
		if(g_has_aklong[iAttacker])
			set_msg_arg_string(4, "aklong")
	}
	else if(equal(szTruncatedWeapon, "aug") && get_user_weapon(iAttacker) == CSW_AUG)
	{
		if(g_has_xm8[iAttacker])
			set_msg_arg_string(4, "xm8")
	}
	else if(equal(szTruncatedWeapon, "galil") && get_user_weapon(iAttacker) == CSW_GALIL)
	{
		if(g_has_guitar[iAttacker])
			set_msg_arg_string(4, "guitar")
	}
	else if(equal(szTruncatedWeapon, "ump45") && get_user_weapon(iAttacker) == CSW_UMP45)
	{
		if(g_has_benzo[iAttacker])
			set_msg_arg_string(4, "watergun")
	}
	else if(equal(szTruncatedWeapon, "mac10") && get_user_weapon(iAttacker) == CSW_MAC10)
	{
		if(g_has_dmp7a1[iAttacker])
			set_msg_arg_string(4, "dmp7a1")
	}
	else if(equal(szTruncatedWeapon, "m4a1") && get_user_weapon(iAttacker) == CSW_M4A1)
	{
		if(g_has_kriss[iAttacker])
			set_msg_arg_string(4, "kriss")
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

stock make_blood_and_bulletholes(id)
{
	new aimOrigin[3], target, body
	get_user_origin(id, aimOrigin, 3)
	get_user_aiming(id, target, body)
	
	if(target > 0 && target <= g_MaxPlayers && zp_get_user_zombie(target))
	{
		new Float:fStart[3], Float:fEnd[3], Float:fRes[3], Float:fVel[3]
		pev(id, pev_origin, fStart)
		
		velocity_by_aim(id, 64, fVel)
		
		fStart[0] = float(aimOrigin[0])
		fStart[1] = float(aimOrigin[1])
		fStart[2] = float(aimOrigin[2])
		fEnd[0] = fStart[0]+fVel[0]
		fEnd[1] = fStart[1]+fVel[1]
		fEnd[2] = fStart[2]+fVel[2]
		
		new res
		engfunc(EngFunc_TraceLine, fStart, fEnd, 0, target, res)
		get_tr2(res, TR_vecEndPos, fRes)
		
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY) 
		write_byte(TE_BLOODSPRITE)
		write_coord(floatround(fStart[0])) 
		write_coord(floatround(fStart[1])) 
		write_coord(floatround(fStart[2])) 
		write_short( m_iBlood [ 1 ])
		write_short( m_iBlood [ 0 ] )
		write_byte(70)
		write_byte(random_num(1,2))
		message_end()
		
		
	} 
	else if(!is_user_connected(target))
	{
		if(target)
		{
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
			write_byte(TE_DECAL)
			write_coord(aimOrigin[0])
			write_coord(aimOrigin[1])
			write_coord(aimOrigin[2])
			write_byte(GUNSHOT_DECALS[random_num ( 0, sizeof GUNSHOT_DECALS -1 ) ] )
			write_short(target)
			message_end()
		} 
		else 
		{
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
			write_byte(TE_WORLDDECAL)
			write_coord(aimOrigin[0])
			write_coord(aimOrigin[1])
			write_coord(aimOrigin[2])
			write_byte(GUNSHOT_DECALS[random_num ( 0, sizeof GUNSHOT_DECALS -1 ) ] )
			message_end()
		}
		
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_GUNSHOTDECAL)
		write_coord(aimOrigin[0])
		write_coord(aimOrigin[1])
		write_coord(aimOrigin[2])
		write_short(id)
		write_byte(GUNSHOT_DECALS[random_num ( 0, sizeof GUNSHOT_DECALS -1 ) ] )
		message_end()
	}
}

public fw_CmdStart(id, uc_handle, seed)
{
	if(!is_user_alive(id)) 
		return PLUGIN_HANDLED
	
	if((get_uc(uc_handle, UC_Buttons) & IN_ATTACK2) && !(pev(id, pev_oldbuttons) & IN_ATTACK2))
	{
		new szClip, szAmmo
		new szWeapID = get_user_weapon(id, szClip, szAmmo)
		
		if(szWeapID == CSW_AK47 && g_has_aklong[id] && !g_hasZoom[id] == true)
		{
			g_hasZoom[id] = true
			cs_set_user_zoom(id, CS_SET_AUGSG552_ZOOM, 1)
			emit_sound(id, CHAN_ITEM, Sound_Zoom, 0.20, 2.40, 0, 100)
		}
		
		else if(szWeapID == CSW_AK47 && g_has_aklong[id] && g_hasZoom[id])
		{
			g_hasZoom[id] = false
			cs_set_user_zoom(id, CS_RESET_ZOOM, 0)
			
		}
		
	}

	if (g_hasZoom[ id ] && (pev(id, pev_button) & IN_RELOAD))
	{
		g_hasZoom[ id ] = false
		cs_set_user_zoom( id, CS_RESET_ZOOM, 0 )
	}
	return PLUGIN_HANDLED
}

public BENZO__ItemPostFrame(weapon_entity) {
	new id = pev(weapon_entity, pev_owner)
	if (!is_user_connected(id))
		return HAM_IGNORED;

	if (!g_has_benzo[id])
		return HAM_IGNORED;

	new Float:flNextAttack = get_pdata_float(id, m_flNextAttack, PLAYER_LINUX_XTRA_OFF)

	new iBpAmmo = cs_get_user_bpammo(id, CSW_UMP45);
	new iClip = get_pdata_int(weapon_entity, m_iClip, WEAP_LINUX_XTRA_OFF)

	new fInReload = get_pdata_int(weapon_entity, m_fInReload, WEAP_LINUX_XTRA_OFF) 

	if( fInReload && flNextAttack <= 0.0 )
	{
		new j = min(get_pcvar_num(cvar_clip_benzo) - iClip, iBpAmmo)
	
		set_pdata_int(weapon_entity, m_iClip, iClip + j, WEAP_LINUX_XTRA_OFF)
		cs_set_user_bpammo(id, CSW_UMP45, iBpAmmo-j);
		
		set_pdata_int(weapon_entity, m_fInReload, 0, WEAP_LINUX_XTRA_OFF)
		fInReload = 0
	}

	return HAM_IGNORED;
}

public BENZO__Reload(weapon_entity) {
	new id = pev(weapon_entity, pev_owner)
	if (!is_user_connected(id))
		return HAM_IGNORED;

	if (!g_has_benzo[id])
		return HAM_IGNORED;

	g_benzo_TmpClip[id] = -1;

	new iBpAmmo = cs_get_user_bpammo(id, CSW_UMP45);
	new iClip = get_pdata_int(weapon_entity, m_iClip, WEAP_LINUX_XTRA_OFF)

	if (iBpAmmo <= 0)
		return HAM_SUPERCEDE;

	if (iClip >= get_pcvar_num(cvar_clip_benzo))
		return HAM_SUPERCEDE;


	g_benzo_TmpClip[id] = iClip;

	return HAM_IGNORED;
}

public BENZO__Reload_Post(weapon_entity) {
	new id = pev(weapon_entity, pev_owner)
	if (!is_user_connected(id))
		return HAM_IGNORED;

	if (!g_has_benzo[id])
		return HAM_IGNORED;

	if (g_benzo_TmpClip[id] == -1)
		return HAM_IGNORED;

	set_pdata_int(weapon_entity, m_iClip, g_benzo_TmpClip[id], WEAP_LINUX_XTRA_OFF)

	set_pdata_float(weapon_entity, m_flTimeWeaponIdle, BENZO_RELOAD_TIME, WEAP_LINUX_XTRA_OFF)

	set_pdata_float(id, m_flNextAttack, BENZO_RELOAD_TIME, PLAYER_LINUX_XTRA_OFF)

	set_pdata_int(weapon_entity, m_fInReload, 1, WEAP_LINUX_XTRA_OFF)

	// relaod animation
	UTIL_PlayWeaponAnimation(id, 1)

	return HAM_IGNORED;
}

public DMP7A1__ItemPostFrame(weapon_entity) {
	new id = pev(weapon_entity, pev_owner)
	if (!is_user_connected(id))
		return HAM_IGNORED;

	if (!g_has_dmp7a1[id])
		return HAM_IGNORED;

	new Float:flNextAttack = get_pdata_float(id, m_flNextAttack, PLAYER_LINUX_XTRA_OFF)

	new iBpAmmo = cs_get_user_bpammo(id, CSW_MAC10);
	new iClip = get_pdata_int(weapon_entity, m_iClip, WEAP_LINUX_XTRA_OFF)

	new fInReload = get_pdata_int(weapon_entity, m_fInReload, WEAP_LINUX_XTRA_OFF) 

	if( fInReload && flNextAttack <= 0.0 )
	{
		new j = min(get_pcvar_num(cvar_clip_dmp7a1) - iClip, iBpAmmo)
	
		set_pdata_int(weapon_entity, m_iClip, iClip + j, WEAP_LINUX_XTRA_OFF)
		cs_set_user_bpammo(id, CSW_MAC10, iBpAmmo-j);
		
		set_pdata_int(weapon_entity, m_fInReload, 0, WEAP_LINUX_XTRA_OFF)
		fInReload = 0
	}

	return HAM_IGNORED;
}

public DMP7A1__Reload(weapon_entity) {
	new id = pev(weapon_entity, pev_owner)
	if (!is_user_connected(id))
		return HAM_IGNORED;

	if (!g_has_dmp7a1[id])
		return HAM_IGNORED;

	g_dmp7a1_TmpClip[id] = -1;

	new iBpAmmo = cs_get_user_bpammo(id, CSW_MAC10);
	new iClip = get_pdata_int(weapon_entity, m_iClip, WEAP_LINUX_XTRA_OFF)

	if (iBpAmmo <= 0)
		return HAM_SUPERCEDE;

	if (iClip >= get_pcvar_num(cvar_clip_dmp7a1))
		return HAM_SUPERCEDE;


	g_dmp7a1_TmpClip[id] = iClip;

	return HAM_IGNORED;
}

public DMP7A1__Reload_Post(weapon_entity) {
	new id = pev(weapon_entity, pev_owner)
	if (!is_user_connected(id))
		return HAM_IGNORED;

	if (!g_has_dmp7a1[id])
		return HAM_IGNORED;

	if (g_dmp7a1_TmpClip[id] == -1)
		return HAM_IGNORED;

	set_pdata_int(weapon_entity, m_iClip, g_dmp7a1_TmpClip[id], WEAP_LINUX_XTRA_OFF)

	set_pdata_float(weapon_entity, m_flTimeWeaponIdle, DMP7A1_RELOAD_TIME, WEAP_LINUX_XTRA_OFF)

	set_pdata_float(id, m_flNextAttack, DMP7A1_RELOAD_TIME, PLAYER_LINUX_XTRA_OFF)

	set_pdata_int(weapon_entity, m_fInReload, 1, WEAP_LINUX_XTRA_OFF)

	// relaod animation
	UTIL_PlayWeaponAnimation(id, 1)

	return HAM_IGNORED;
}

public AKLONG__ItemPostFrame(weapon_entity) {
	new id = pev(weapon_entity, pev_owner)
	if (!is_user_connected(id))
		return HAM_IGNORED;

	if (!g_has_aklong[id])
		return HAM_IGNORED;

	new Float:flNextAttack = get_pdata_float(id, m_flNextAttack, PLAYER_LINUX_XTRA_OFF)

	new iBpAmmo = cs_get_user_bpammo(id, CSW_AK47);
	new iClip = get_pdata_int(weapon_entity, m_iClip, WEAP_LINUX_XTRA_OFF)

	new fInReload = get_pdata_int(weapon_entity, m_fInReload, WEAP_LINUX_XTRA_OFF) 

	if( fInReload && flNextAttack <= 0.0 )
	{
		new j = min(get_pcvar_num(cvar_clip_aklong) - iClip, iBpAmmo)
	
		set_pdata_int(weapon_entity, m_iClip, iClip + j, WEAP_LINUX_XTRA_OFF)
		cs_set_user_bpammo(id, CSW_AK47, iBpAmmo-j);
		
		set_pdata_int(weapon_entity, m_fInReload, 0, WEAP_LINUX_XTRA_OFF)
		fInReload = 0
	}

	return HAM_IGNORED;
}

public AKLONG__Reload(weapon_entity) {
	new id = pev(weapon_entity, pev_owner)
	if (!is_user_connected(id))
		return HAM_IGNORED;

	if (!g_has_aklong[id])
		return HAM_IGNORED;

	g_aklong_TmpClip[id] = -1;

	new iBpAmmo = cs_get_user_bpammo(id, CSW_AK47);
	new iClip = get_pdata_int(weapon_entity, m_iClip, WEAP_LINUX_XTRA_OFF)

	if (iBpAmmo <= 0)
		return HAM_SUPERCEDE;

	if (iClip >= get_pcvar_num(cvar_clip_aklong))
		return HAM_SUPERCEDE;


	g_aklong_TmpClip[id] = iClip;

	return HAM_IGNORED;
}

public AKLONG__Reload_Post(weapon_entity) {
	new id = pev(weapon_entity, pev_owner)
	if (!is_user_connected(id))
		return HAM_IGNORED;

	if (!g_has_aklong[id])
		return HAM_IGNORED;

	if (g_aklong_TmpClip[id] == -1)
		return HAM_IGNORED;

	set_pdata_int(weapon_entity, m_iClip, g_aklong_TmpClip[id], WEAP_LINUX_XTRA_OFF)

	set_pdata_float(weapon_entity, m_flTimeWeaponIdle, AKLONG_RELOAD_TIME, WEAP_LINUX_XTRA_OFF)

	set_pdata_float(id, m_flNextAttack, AKLONG_RELOAD_TIME, PLAYER_LINUX_XTRA_OFF)

	set_pdata_int(weapon_entity, m_fInReload, 1, WEAP_LINUX_XTRA_OFF)

	// relaod animation
	UTIL_PlayWeaponAnimation(id, 1)

	return HAM_IGNORED;
}

public KRISS__ItemPostFrame(weapon_entity) {
	new id = pev(weapon_entity, pev_owner)
	if (!is_user_connected(id))
		return HAM_IGNORED;

	if (!g_has_kriss[id])
		return HAM_IGNORED;

	new Float:flNextAttack = get_pdata_float(id, m_flNextAttack, PLAYER_LINUX_XTRA_OFF)

	new iBpAmmo = cs_get_user_bpammo(id, CSW_M4A1);
	new iClip = get_pdata_int(weapon_entity, m_iClip, WEAP_LINUX_XTRA_OFF)

	new fInReload = get_pdata_int(weapon_entity, m_fInReload, WEAP_LINUX_XTRA_OFF) 

	if( fInReload && flNextAttack <= 0.0 )
	{
		new j = min(get_pcvar_num(cvar_clip_kriss) - iClip, iBpAmmo)
	
		set_pdata_int(weapon_entity, m_iClip, iClip + j, WEAP_LINUX_XTRA_OFF)
		cs_set_user_bpammo(id, CSW_M4A1, iBpAmmo-j);
		
		set_pdata_int(weapon_entity, m_fInReload, 0, WEAP_LINUX_XTRA_OFF)
		fInReload = 0
	}

	return HAM_IGNORED;
}

public KRISS__Reload(weapon_entity) {
	new id = pev(weapon_entity, pev_owner)
	if (!is_user_connected(id))
		return HAM_IGNORED;

	if (!g_has_kriss[id])
		return HAM_IGNORED;

	g_kriss_TmpClip[id] = -1;

	new iBpAmmo = cs_get_user_bpammo(id, CSW_M4A1);
	new iClip = get_pdata_int(weapon_entity, m_iClip, WEAP_LINUX_XTRA_OFF)

	if (iBpAmmo <= 0)
		return HAM_SUPERCEDE;

	if (iClip >= get_pcvar_num(cvar_clip_kriss))
		return HAM_SUPERCEDE;


	g_kriss_TmpClip[id] = iClip;

	return HAM_IGNORED;
}

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