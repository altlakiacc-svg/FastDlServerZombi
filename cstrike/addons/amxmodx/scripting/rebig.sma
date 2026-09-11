/*================================================================================
 * Please don't change plugin register information.
================================================================================*/

#include <amxmodx>
#include <fakemeta>
#include <engine>
#include <fun>
#include <zombieplague>
#include <hamsandwich>
#include <xs>

#define PLUGIN_NAME	"[ZP] Class: DaSu (2)"
#define PLUGIN_VERSION	"1.0"
#define PLUGIN_AUTHOR	"Jim"

#define SUPPORT_BOT_TO_USE

#define TASK_SET_TRAP		1234
#define TASK_REMOVE_TRAP 	4321

// Zombie Attributes
new const zclass_name[] = { "Big" }
new const zclass_info[] = { "[ HP + Trap + 2x(DMG) ]" }
new const zclass_model[] = { "rebig" }
new const zclass_clawmodel[] = { "re/v_re_big.mdl" }
new const g_vgrenade[] = "models/zombie_plague/re/v_zombibomb-big.mdl"
const zclass_health = 7500
const zclass_speed = 235
const Float:zclass_gravity = 0.80
const Float:zclass_knockback = 0.25

// Models
new const Trap_Model[] = { "models/zombie_plague/re/zombitrap.mdl"}	//Ловушка модели

// Sounds	
new const PlayerCatched_Sound[] = { "zombie_plague/re/big/td_zombitrapped.wav" } 		//Звук ловушка срабатывает
new const CantPlantTrap_Sound[] = { "common/wpn_denyselect.wav" } 	//Установка временных предупреждение беззакония
new const Trap_useura[] = { "zombie_plague/re/big/zombi_trapsetup.wav" }

// --- config ------------------------ //
new Float:g_revenge_cooldown = 30.0 //cooldown time
new g_chance_to_cast = 25 //chance in percent, where 10 = 1%, 235= 23.5% e t.c.
new const sound_sleep[] = "zombie_plague/re/big/SleepImpact.wav" //cast sound
// ----------------------------------- //

// Settings
const Max_Traps = 5	//Сколько игрок может ставить ловушки.

// Weapons Offsets (win32)
const OFFSET_flNextPrimaryAttack = 46
const OFFSET_flNextSecondaryAttack = 47
const OFFSET_flTimeWeaponIdle = 48

// Linux diff's
const OFFSET_LINUX_WEAPONS = 4 // weapon offsets are only 4 steps higher on Linux

// Zombie id
new g_zclass_DaSu
new g_chance[33]
new g_msgScreenFade
const FFADE_IN = 0x0000
const FFADE_STAYOUT = 0x0004
const UNIT_SECOND = (1<<12)

// Vars
new cvar_TrapSetTime, cvar_TrapAffectTime, cvar_dmgbig
new g_TrapPromptSpr, g_PlayerCatchedSpr
new g_msgScreenShake, g_msgBarTime
new g_maxplayers, g_msgSayText
new user_has_traps[33]
new user_traps_ent[33][Max_Traps]
new bool:user_set_trap[33], set_trap_ent[33], Float:set_trap_origin[33][3]
new bool:user_be_catched[33], catched_trap_ent[33], bool:g_bIsConnected[33]
new is_cooldown_time[33] = 0
new is_cooldown[33] = 0

#if defined SUPPORT_BOT_TO_USE
new Float:bot_next_check_time[33]
#endif

public plugin_init()
{
        register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)
	
	cvar_TrapSetTime = register_cvar("zp_dasu_trap_settime", "1.0")		    //Сколько будет сек зомби ставить ловушку
	cvar_TrapAffectTime = register_cvar("zp_dasu_trap_affecttime", "8.0")	//скоьлок будет держать человека в ловущке
	cvar_dmgbig = register_cvar("zp_dasu_dmg_big", "2.0")                   // урон
	
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	register_forward(FM_CmdStart, "fw_CmdStart")
	register_forward(FM_StartFrame, "fw_StartFrame")
	register_forward(FM_PlayerPreThink, "fw_PlayerPreThink")
	register_forward(FM_Touch, "fw_Touch")
	register_forward(FM_Think, "fw_Think")
	
	register_event("ResetHUD", "event_NewSpawn", "be")
	register_event("DeathMsg", "event_Death", "a")
	register_event("HLTV", "event_RoundStart", "a", "1=0", "2=0")
	register_event("CurWeapon", "Event_CurWeapon", "be", "1=1")
	register_logevent("roundStart", 2, "1=Round_Start")
	
	#if defined SUPPORT_BOT_TO_USE
	register_event("Damage", "event_Damage", "be", "2>0")
	#endif
	
	g_msgScreenShake = get_user_msgid("ScreenShake")
	g_msgScreenFade = get_user_msgid("ScreenFade")
	g_msgBarTime = get_user_msgid("BarTime")
	g_maxplayers = get_maxplayers()
	g_msgSayText = get_user_msgid("SayText")
	register_dictionary("class_zombie.txt")
}

public plugin_precache()
{
	precache_model(Trap_Model)
	precache_sound(sound_sleep)	
	precache_sound(PlayerCatched_Sound)
	precache_sound(CantPlantTrap_Sound)
	precache_sound(Trap_useura)
	precache_model(g_vgrenade)
	
	g_TrapPromptSpr = precache_model("sprites/trap_prompt.spr")
	g_PlayerCatchedSpr = precache_model("sprites/trap3.spr")
	
	g_zclass_DaSu = zp_register_zombie_class(zclass_name, zclass_info, zclass_model, zclass_clawmodel, zclass_health, zclass_speed, zclass_gravity, zclass_knockback)
}

public fw_TakeDamage(victim, inflictor, attacker, Float: damage, damage_bits)
{
    if (victim != attacker && is_user_connected(attacker))
    {
        if (is_user_alive(attacker) && get_user_weapon(attacker) == CSW_KNIFE && zp_get_user_zombie_class(attacker) == g_zclass_DaSu && zp_get_user_zombie(attacker) && zp_get_user_zombie(attacker) && !zp_get_user_nemesis(attacker))
        {
            SetHamParamFloat(4, damage * get_pcvar_num(cvar_dmgbig))
	    }			
    }
}

public Event_CurWeapon(id)    
{   
    new weaponID = read_data(2)    

    if(!zp_get_user_zombie(id) || !is_user_alive(id) || zp_get_user_zombie_class(id) != g_zclass_DaSu)   
    return PLUGIN_CONTINUE   

    if(weaponID == CSW_HEGRENADE ) 
    { 
        set_pev(id, pev_viewmodel, engfunc(EngFunc_AllocString, g_vgrenade))    
    }  
    if(weaponID == CSW_FLASHBANG ) 
    { 
        set_pev(id, pev_viewmodel, engfunc(EngFunc_AllocString, g_vgrenade))     
    }  
    if(weaponID == CSW_SMOKEGRENADE ) 
    { 
        set_pev(id, pev_viewmodel, engfunc(EngFunc_AllocString, g_vgrenade))    
    }  
    return PLUGIN_CONTINUE    
}

public client_damage(attacker,victim)
{
	if ((zp_get_user_zombie_class(victim) == g_zclass_DaSu) && zp_get_user_zombie(victim) && !zp_get_user_nemesis(victim) && (is_cooldown[victim] == 0))
	{
		g_chance[victim] = random_num(0,999)
		if (g_chance[victim] < g_chance_to_cast)
		{
			message_begin(MSG_ONE, g_msgScreenFade, _, attacker)
			write_short(4) // duration
			write_short(4) // hold time
			write_short(FFADE_STAYOUT) // fade type
			write_byte(0) // red
			write_byte(0) // green
			write_byte(0) // blue
			write_byte(255) // alpha
			message_end()
			
			set_user_health(victim, get_user_health(victim) + ( get_user_health(victim) / 10 ) )
			
			set_task(4.0,"wake_up",attacker)
			set_task(1.0, "ShowHUD", victim, _, _, "a",is_cooldown_time[victim])
			set_task(g_revenge_cooldown,"reset_cooldown",victim)
			
			emit_sound(attacker, CHAN_STREAM, sound_sleep, 1.0, ATTN_NORM, 0, PITCH_NORM);
			
			is_cooldown[victim] = 1
		}
	}
}

public reset_cooldown(id)
{
	if ((zp_get_user_zombie_class(id) == g_zclass_DaSu) && zp_get_user_zombie(id) && !zp_get_user_nemesis(id))
	{
		is_cooldown[id] = 0
		is_cooldown_time[id] = floatround(g_revenge_cooldown)
		client_printcolor(id, "/g[ZP] /y %L", id, "BIG_GOTOVO")
	}
}

public ShowHUD(id)
{
	if(is_user_alive(id))
	{
		is_cooldown_time[id] = is_cooldown_time[id] - 1;
		set_hudmessage(200, 100, 0, 0.75, 0.92, 0, 1.0, 1.1, 0.0, 0.0, -1)
		show_hudmessage(id, "%L: %d", id, "BIG_TIME", is_cooldown_time[id])
	}
	else
	{
		remove_task(id)
	}
}

public wake_up(id)
{
	message_begin(MSG_ONE, g_msgScreenFade, _, id)
	write_short(UNIT_SECOND) // duration
	write_short(0) // hold time
	write_short(FFADE_IN) // fade type
	write_byte(0) // red
	write_byte(0) // green
	write_byte(0) // blue
	write_byte(255) // alpha
	message_end()
}

public zp_user_infected_post(id, infector)
{
	if (user_be_catched[id])
	{
		clear_user_sprite(id)
		set_pev(id, pev_flags, (pev(id, pev_flags) & ~FL_FROZEN))
	}
	
	reset_vars(id)
	
	if (zp_get_user_zombie_class(id) == g_zclass_DaSu && !zp_get_user_nemesis(id))
	{
		user_has_traps[id] = Max_Traps
		client_printcolor(id, "/g[ZP][1]/y %L", id, "BIG_INFO", Max_Traps)
		
		is_cooldown[id] = 0
		is_cooldown_time[id] = floatround(g_revenge_cooldown)
		
		new note_cooldown = floatround(g_revenge_cooldown)		
		client_printcolor(id, "/g[ZP][2]/y %L", id, "BIG_INFO2", note_cooldown)
	}
}

public fw_CmdStart(id, uc_handle, seed)
{
	if (!is_user_alive(id))
		return FMRES_IGNORED;
	
	if (!zp_get_user_zombie(id) || zp_get_user_zombie_class(id) != g_zclass_DaSu || zp_get_user_nemesis(id))
		return FMRES_IGNORED;
	
	#if defined SUPPORT_BOT_TO_USE
	if (is_user_bot(id))
	{
		bot_use_traps(id)
		return FMRES_IGNORED;
	}
	#endif
	
	static button, oldbutton
	button = get_uc(uc_handle, UC_Buttons)
	oldbutton = pev(id, pev_oldbuttons)
	
	if (!user_set_trap[id])
	{
		if ((button & IN_RELOAD) && !(oldbutton & IN_RELOAD))
		{
			do_set_trap(id)
		}
	}
	else
	{
		static user_flags, Float:user_origin[3], Float:fdistance
		user_flags = pev(id, pev_flags)
		pev(id, pev_origin, user_origin)
		user_origin[2] -= (user_flags & FL_DUCKING) ? 18.0 : 36.0
		fdistance = get_distance_f(user_origin, set_trap_origin[id])
		
		if (!(button & IN_RELOAD) || fdistance > 18.0)
		{
			stop_set_trap(id)
		}
	}
	
	return FMRES_HANDLED;
}

public fw_StartFrame()
{
	static Float:time, Float:next_check_time, id, i, classname[32], Float:origin1[3], Float:origin2[3]
	
	time = get_gametime()
	
	if (time >= next_check_time)
	{
		for (id = 1; id <= g_maxplayers; id++)
		{
			if (!is_user_connected(id) || !is_user_alive(id))
				continue;
			
			if (!zp_get_user_zombie(id) || zp_get_user_zombie_class(id) != g_zclass_DaSu || zp_get_user_nemesis(id))
				continue;
			
			for (i = 0; i < Max_Traps; i++)
			{
				if (user_traps_ent[id][i] <= 0)
					continue;
				
				if (!pev_valid(user_traps_ent[id][i]))
				{
					user_traps_ent[id][i] = 0
					continue;
				}
				
				pev(user_traps_ent[id][i], pev_classname, classname, charsmax(classname))
				if (!equal(classname, "ZOMBIE_TRAP_ENT"))
				{
					user_traps_ent[id][i] = 0
					continue;
				}
				
				if (pev(user_traps_ent[id][i], pev_iuser3) == 1) //判斷陷阱物件是否已經是在補捉到人類的狀態
					continue;
				
				pev(user_traps_ent[id][i], pev_origin, origin1)
				xs_vec_copy(origin1, origin2)
				origin2[2] += 30.0
				if (fm_is_point_visible(id, origin1, 1) || fm_is_point_visible(id, origin2, 1))
				{
					origin1[2] += 30.0
					create_user_sprite(id, origin1, g_TrapPromptSpr, 15)
				}
			}
		}
		
		next_check_time = time + 0.1
	}
	
	return FMRES_IGNORED;
}

public fw_PlayerPreThink(id)
{
	if (!is_user_alive(id))
		return FMRES_IGNORED;
	
	if (zp_get_user_zombie(id))
	{
		if (zp_get_user_zombie_class(id) != g_zclass_DaSu || zp_get_user_nemesis(id))
			return FMRES_IGNORED;
		
		if (user_set_trap[id])
		{
			freeze_user_attack(id)
		}
	}
	else
	{
		if (user_be_catched[id] && pev_valid(catched_trap_ent[id]))
		{
			static classname[32]
			pev(catched_trap_ent[id], pev_classname, classname, charsmax(classname))
			if (!equal(classname, "ZOMBIE_TRAP_ENT"))
				return FMRES_IGNORED;
			
			set_pev(id, pev_velocity, Float:{ 0.0, 0.0, -200.0 })
			set_pev(id, pev_maxspeed, 1.0)
			
			static Float:user_origin[3], Float:ent_origin[3], Float:temp_origin[3]
			pev(id, pev_origin, user_origin)
			pev(catched_trap_ent[id], pev_origin, ent_origin)
			xs_vec_copy(ent_origin, temp_origin)
			temp_origin[2] += 18.0
			if (get_distance_f(user_origin, temp_origin) > 18.0)
			{
				temp_origin[2] += ((pev(id, pev_flags) & FL_DUCKING) ? 0.0 : 18.0)
				set_pev(id, pev_origin, temp_origin)
			}
		}
	}
	
	return FMRES_IGNORED;
}

public fw_Touch(ptr, ptd)
{
	if (!pev_valid(ptr) || !pev_valid(ptd))
		return FMRES_IGNORED;
	
	static classname[32]
	pev(ptr, pev_classname, classname, charsmax(classname))
	if (!equal(classname, "ZOMBIE_TRAP_ENT"))
		return FMRES_IGNORED;
	
	if (!(1 <= ptd <= g_maxplayers) || !is_user_alive(ptd) || zp_get_user_zombie(ptd))
		return FMRES_IGNORED;
	
	if (pev(ptr, pev_iuser2) == 0) //判斷陷阱物件是否是在可碰觸的狀態
		return FMRES_IGNORED;
	
	// 判斷陷阱物件是否已經是在補捉到人類的狀態,或是碰到陷阱的人類已經是處於被陷阱捉住的狀態了,
	// 二者情況如其中一項成立的話,則不設定讓陷阱觸發作用.
	if (pev(ptr, pev_iuser3) == 0 && !user_be_catched[ptd])
	{
		engfunc(EngFunc_EmitSound, ptd, CHAN_VOICE, PlayerCatched_Sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
		user_screen_shake(ptd, 4, 2, 5)
		show_user_sprite(ptd, g_PlayerCatchedSpr)
		
		static Float:origin[3]
		pev(ptr, pev_origin, origin)
		origin[2] += ((pev(ptd, pev_flags) & FL_DUCKING) ? 18.0 : 36.0)
		set_pev(ptd, pev_origin, origin)
		set_pev(ptd, pev_velocity, Float:{ 0.0, 0.0, 0.0 })
		client_print(ptd, print_center, "*** %L ***", LANG_PLAYER, "BIG_TRAP")
		
		set_pev(ptr, pev_iuser3, 1) 	//設定陷阱物件為已補捉到人類的flag數值
		set_pev(ptr, pev_iuser4, ptd)	//記錄陷阱物件補捉到的人類的ID
		user_be_catched[ptd] = true	//設定碰到陷阱的人類為被補捉到的狀態
		catched_trap_ent[ptd] = ptr	//記錄所碰到陷阱物件的ID
		fm_set_rendering(ptr, kRenderFxNone, 0,0,0, kRenderNormal, 255)
		set_pev(ptr, pev_nextthink, get_gametime() + 0.05) //設定陷阱物件的 next think time
		
		static owner
		owner = pev(ptr, pev_iuser1)
		if (1 <= owner <= g_maxplayers) //判斷放置陷阱的玩家是否還存在(如玩家已變成人類或死亡,會把放置的玩家ID記錄設回成0)
			client_print(owner, print_center, "")
		
		static Float:trap_affect_time
		trap_affect_time = get_pcvar_float(cvar_TrapAffectTime)
		if (trap_affect_time > 0.0)
		{
			static args[1]
			args[0] = ptr
			set_task(trap_affect_time, "remove_trap", TASK_REMOVE_TRAP, args, 1)
		}
	}
	
	return FMRES_IGNORED;
}

public fw_Think(ent)
{
	if (pev_valid(ent))
	{
		static classname[32]
		pev(ent, pev_classname, classname, charsmax(classname))
		if (equal(classname, "ZOMBIE_TRAP_ENT"))
		{
			if (pev(ent, pev_sequence) != 1)
			{
				set_pev(ent, pev_sequence, 1)
				set_pev(ent, pev_frame, 0.0)
			}
			else
			{
				if (pev(ent, pev_frame) > 241.0)
					set_pev(ent, pev_frame, 20.0)
				else
					set_pev(ent, pev_frame, pev(ent, pev_frame) + 1.0)
			}
			
			static catched_player
			catched_player = pev(ent, pev_iuser4)
			if (!user_be_catched[catched_player] || catched_trap_ent[catched_player] != ent)
			{
				engfunc(EngFunc_RemoveEntity, ent)
				return FMRES_IGNORED;
			}
			
			set_pev(ent, pev_nextthink, get_gametime() + 0.05) //設定陷阱物件的 next think time
		}
	}
	
	return FMRES_IGNORED;
}

freeze_user_attack(id)
{
	new weapon, weapon_name[32], weapon_ent
	weapon = get_user_weapon(id)
	get_weaponname(weapon, weapon_name, charsmax(weapon_name))
	weapon_ent = fm_find_ent_by_owner(-1, weapon_name, id)
	
	if (get_weapon_next_pri_attack(weapon_ent) <= 0.1)
		set_weapon_next_pri_attack(weapon_ent, 0.5)
	
	if (get_weapon_next_sec_attack(weapon_ent) <= 0.1)
		set_weapon_next_sec_attack(weapon_ent, 0.5)
	
	if (weapon == CSW_XM1014 || weapon == CSW_M3)
	{
		if (get_weapon_idle_time(weapon_ent) <= 0.1)
			set_weapon_idle_time(weapon_ent, 0.5)
	}
}

do_set_trap(id)
{
	if (!user_set_trap[id])
	{
		if (set_a_trap(id, set_trap_ent[id], set_trap_origin[id]) == 1)
		{
			user_set_trap[id] = true
			
			new Float:velocity[3]
			pev(id, pev_velocity, velocity)
			velocity[0] = velocity[1] = 0.0
			set_pev(id, pev_velocity, velocity)
			
			new Float:set_trap_time, task_time
			set_trap_time = get_pcvar_float(cvar_TrapSetTime)
			task_time = floatround(set_trap_time, floatround_floor) + (floatfract(set_trap_time) >= 0.5 ? 1 : 0)
			set_task(set_trap_time, "trap_complete", (id + TASK_SET_TRAP))
			show_user_taskbar(id, task_time)
			
			client_print(id, print_center, "%L", id, "BIG_TRAPUSE")			
			
			return 1;
		}
	}
	
	return 0;
}

stop_set_trap(id)
{
	if (user_set_trap[id])
	{
		client_print(id, print_center, "")
		
		if (pev_valid(set_trap_ent[id]))
			engfunc(EngFunc_RemoveEntity, set_trap_ent[id])
		
		user_set_trap[id] = false
		set_trap_ent[id] = 0
		remove_task(id + TASK_SET_TRAP)
		show_user_taskbar(id, 0)
	}
}

set_a_trap(id, &trap_entity, Float:trap_origin[3])
{
	if (user_has_traps[id] <= 0)
	{
		engfunc(EngFunc_EmitSound, id, CHAN_ITEM, CantPlantTrap_Sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
		client_printcolor(id, "/g[ZP]/y %L", id, "BIG_TRAPNET")
		return 0;
	}
	
	new user_flags = pev(id, pev_flags)
	if (!(user_flags & FL_ONGROUND))
	{
		engfunc(EngFunc_EmitSound, id, CHAN_ITEM, CantPlantTrap_Sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
		client_print(id, print_center, "*** %L ***", id, "BIG_TRAPUSE2")
		return 0;
	}
	
	new Float:origin[3]
	pev(id, pev_origin, origin)
	origin[2] -= (user_flags & FL_DUCKING) ? 18.0 : 36.0
	
	if (get_too_close_traps(origin)) //檢查是否所在位置地點,是否有太靠近其它己放置好的陷阱存在
	{
		engfunc(EngFunc_EmitSound, id, CHAN_ITEM, CantPlantTrap_Sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
		client_print(id, print_center, "*** %L ***", id, "BIG_TRAPNET2")
		return 0;
	}
	
	client_print(id, print_center, "")
	
	new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	if (!ent) return -1;
	
	// Set trap data
	set_pev(ent, pev_classname, "ZOMBIE_TRAP_ENT")
	set_pev(ent, pev_solid, SOLID_TRIGGER)
	set_pev(ent, pev_movetype, MOVETYPE_FLY)
	set_pev(ent, pev_sequence, 0)
	set_pev(ent, pev_frame, 0.0)
	set_pev(ent, pev_iuser1, id) 	//記錄設置陷阱的玩家ID
	set_pev(ent, pev_iuser2, 0)	//記錄陷阱物件是否是可碰觸的狀態的flag數值 [1=可碰觸,0=不可碰觸]
	set_pev(ent, pev_iuser3, 0)	//記錄陷阱物件是否已補捉到人類的flag數值 [1=是,0=不是]
	set_pev(ent, pev_iuser4, 0)	//記錄陷阱物件補捉到的人類的ID (預設ID為0,代表未捕捉到目標)
	
	// Set trap size
	new Float:mins[3] = { -20.0, -20.0, 0.0 }
	new Float:maxs[3] = { 20.0, 20.0, 30.0 }
	engfunc(EngFunc_SetSize, ent, mins, maxs)
	
	// Set trap model
	engfunc(EngFunc_SetModel, ent, Trap_Model)
	
	// Make trap invisible
	fm_set_rendering(ent, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 0)
	
	// Set trap position
	set_pev(ent, pev_origin, origin)
	
	// Return trap entity id
	trap_entity = ent
	
	// Return trap position
	xs_vec_copy(origin, trap_origin)
	
	return 1;
}

public trap_complete(taskid)
{
	new id = taskid - TASK_SET_TRAP
	
	show_user_taskbar(id, 0)
	
	if (pev_valid(set_trap_ent[id]))
	{
		set_pev(set_trap_ent[id], pev_iuser2, 1) //記錄陷阱物件是否是可碰觸的狀態的flag數值 [1=可碰觸,0=不可碰觸]
		user_has_traps[id]--
		set_user_traps_data(id, set_trap_ent[id])
		
		client_print(id, print_center, "*** %L ***", id, "BIG_TRAPYRA")
		client_printcolor(id, "/g[ZP]/y %L", id, "BIG_TRAP2", user_has_traps[id])
				
		engfunc(EngFunc_EmitSound, id, CHAN_ITEM, Trap_useura, 1.0, ATTN_NORM, 0, PITCH_NORM)
		
	}
	
	#if defined SUPPORT_BOT_TO_USE
	if (is_user_bot(id))
	{
		set_pev(id, pev_flags, (pev(id, pev_flags) & ~FL_FROZEN))
		bot_next_check_time[id] = get_gametime() + 10.0	//設定BOT經過多少時間才會再檢查是否進行設置陷阱(單位:秒)
	}
	#endif
	
	user_set_trap[id] = false
	set_trap_ent[id] = 0
}

public remove_trap(args[1])
{
	new ent = args[0]
	
	if (pev_valid(ent))
	{
		new classname[32]
		pev(ent, pev_classname, classname, charsmax(classname))
		if (!equal(classname, "ZOMBIE_TRAP_ENT"))
			return;
		
		new catched_player = pev(ent, pev_iuser4)
		if (user_be_catched[catched_player] && catched_trap_ent[catched_player] == ent)
		{
			clear_user_sprite(catched_player)
			set_pev(catched_player, pev_flags, (pev(catched_player, pev_flags) & ~FL_FROZEN))
			user_be_catched[catched_player] = false
			catched_trap_ent[catched_player] = 0
		}
		
		engfunc(EngFunc_RemoveEntity, ent)
	}
}

public zp_user_humanized_post(id)
{
	if (user_set_trap[id])
	{
		stop_set_trap(id)
		
		#if defined SUPPORT_BOT_TO_USE
		if (pev(id, pev_flags) & FL_FROZEN)
			set_pev(id, pev_flags, (pev(id, pev_flags) & ~FL_FROZEN))
		#endif
	}
	
	reset_traps_owner(id)
	reset_vars(id)
	remove_task(id)
	is_cooldown[id] = 0
}

public client_connect(id)
{
	reset_vars(id)
}

public client_putinserver(id)
{
	g_bIsConnected[id] = true
}

public client_disconnect(id)
{
	if (user_set_trap[id])
	{
		stop_set_trap(id)
		
		#if defined SUPPORT_BOT_TO_USE
		if (pev(id, pev_flags) & FL_FROZEN)
			set_pev(id, pev_flags, (pev(id, pev_flags) & ~FL_FROZEN))
		#endif
	}
	
	if (user_be_catched[id])
	{
		clear_user_sprite(id)
		set_pev(id, pev_flags, (pev(id, pev_flags) & ~FL_FROZEN))
	}
	
	reset_vars(id)
}

public event_NewSpawn(id)
{
	if (user_set_trap[id])
	{
		stop_set_trap(id)
		
		#if defined SUPPORT_BOT_TO_USE
		if (pev(id, pev_flags) & FL_FROZEN)
			set_pev(id, pev_flags, (pev(id, pev_flags) & ~FL_FROZEN))
		#endif
	}
	
	if (user_be_catched[id])
	{
		clear_user_sprite(id)
		set_pev(id, pev_flags, (pev(id, pev_flags) & ~FL_FROZEN))
	}
	
	reset_vars(id)
}

public event_Death()
{
	new id = read_data(2)
	if (!(1 <= id <= g_maxplayers))
		return;
	
	if (user_set_trap[id])
	{
		stop_set_trap(id)
		
		#if defined SUPPORT_BOT_TO_USE
		if (pev(id, pev_flags) & FL_FROZEN)
			set_pev(id, pev_flags, (pev(id, pev_flags) & ~FL_FROZEN))
		#endif
	}
	
	if (user_be_catched[id])
	{
		clear_user_sprite(id)
		set_pev(id, pev_flags, (pev(id, pev_flags) & ~FL_FROZEN))
	}
	
	reset_traps_owner(id)
	reset_vars(id)
}

public event_RoundStart()
{
	remove_task(TASK_REMOVE_TRAP)
	remove_all_traps()
}

public roundStart()
{
	for (new i = 1; i <= g_maxplayers; i++)
	{
		is_cooldown[i] = 0
		is_cooldown_time[i] = floatround(g_revenge_cooldown)
		remove_task(i)
	}
}

get_too_close_traps(const Float:origin[3])
{
	new bool:find, ent, Float:ent_origin[3]
	find = false
	ent = -1
	while ((ent = fm_find_ent_by_class(ent, "ZOMBIE_TRAP_ENT")))
	{
		if (pev(ent, pev_iuser2) == 1)
		{
			pev(ent, pev_origin, ent_origin)
			if (get_distance_f(origin, ent_origin) <= 50.0) //預設每個陷阱彼此間的間隔距離必需大於50.0
				find = true
		}
	}
	
	if (!find) return 0;
	
	return 1;
}

set_user_traps_data(id, trap_ent)
{
	new bool:find = false
	
	for (new i = 0; i < Max_Traps; i++)
	{
		if (user_traps_ent[id][i] == 0)
		{
			user_traps_ent[id][i] = trap_ent
			find = true
			break;
		}
	}
	
	if (!find) return 0;
	
	return 1;
}

reset_traps_owner(id)
{
	new classname[32], owner
	for (new i = 0; i < Max_Traps; i++)
	{
		if (user_traps_ent[id][i] > 0 && pev_valid(user_traps_ent[id][i]))
		{
			pev(user_traps_ent[id][i], pev_classname, classname, charsmax(classname))
			owner = pev(user_traps_ent[id][i], pev_iuser1)
			
			if (equal(classname, "ZOMBIE_TRAP_ENT") && owner == id)
				set_pev(user_traps_ent[id][i], pev_iuser1, 0)
		}
	}
}

remove_all_traps()
{
	new ent = -1
	while ((ent = fm_find_ent_by_class(ent, "ZOMBIE_TRAP_ENT")))
	{
		engfunc(EngFunc_RemoveEntity, ent)
	}
}

reset_vars(id)
{
	user_has_traps[id] = 0
	user_set_trap[id] = false
	set_trap_ent[id] = 0
	user_be_catched[id] = false
	catched_trap_ent[id] = 0
	
	for (new i = 0; i < Max_Traps; i++)
		user_traps_ent[id][i] = 0
}

stock fm_set_rendering(entity, fx = kRenderFxNone, r = 255, g = 255, b = 255, render = kRenderNormal, amount = 16)
{
	new Float:RenderColor[3];
	RenderColor[0] = float(r);
	RenderColor[1] = float(g);
	RenderColor[2] = float(b);
	
	set_pev(entity, pev_renderfx, fx);
	set_pev(entity, pev_rendercolor, RenderColor);
	set_pev(entity, pev_rendermode, render);
	set_pev(entity, pev_renderamt, float(amount));
	
	return 1;
}

stock fm_find_ent_by_class(index, const classname[])
{
	return engfunc(EngFunc_FindEntityByString, index, "classname", classname) 
}

stock PlaySound(id, const sound[])
{
	if (equal(sound[strlen(sound)-4], ".mp3"))
		client_cmd(id, "mp3 play ^"sound/%s^"", sound)
	else
		client_cmd(id, "spk ^"%s^"", sound)
}

stock user_screen_shake(id, amplitude = 4, duration = 2, frequency = 10)
{
	message_begin(MSG_ONE_UNRELIABLE, g_msgScreenShake, _, id)
	write_short((1<<12)*amplitude) // 振幅
	write_short((1<<12)*duration) // 時間
	write_short((1<<12)*frequency) // 頻率
	message_end()
}

stock show_user_taskbar(id, time)
{
	message_begin(MSG_ONE_UNRELIABLE, g_msgBarTime, _, id)
	write_short(time) // time (second) [0=clear]
	message_end()
}

stock show_user_sprite(id, const sprite_index)
{
	message_begin(MSG_ALL, SVC_TEMPENTITY)
	write_byte(TE_PLAYERATTACHMENT) // TE_PLAYERATTACHMENT (124)
	write_byte(id) // player id
	write_coord(45) // vertical offset (attachment origin.z = player origin.z + vertical offset)
	write_short(sprite_index) // sprite entity index
	write_short(32767) // life (scale in 0.1's)
	message_end()
}

stock clear_user_sprite(id)
{
	message_begin(MSG_ALL, SVC_TEMPENTITY)
	write_byte(TE_KILLPLAYERATTACHMENTS) // TE_KILLPLAYERATTACHMENTS (125)
	write_byte(id) // player id
	message_end()
}

stock bool:fm_is_point_visible(index, const Float:point[3], ignoremonsters = 1)
{
	new Float:start[3], Float:dest[3];
	pev(index, pev_origin, start);
	pev(index, pev_view_ofs, dest);
	xs_vec_add(start, dest, start);
	
	engfunc(EngFunc_TraceLine, start, point, ignoremonsters, index, 0);
	
	new Float:fraction;
	get_tr2(0, TR_flFraction, fraction);
	if (fraction == 1.0)
		return true;
	
	get_tr2(0, TR_vecEndPos, dest);
	if ((dest[0] == point[0]) && (dest[1] == point[1]) && (dest[2] == point[2]))
		return true;
	
	return false;
}

stock create_user_sprite(id, const Float:originF[3], sprite_index, scale)
{
	// 在設定座標點產生一個 Sprite 物件
	message_begin(MSG_ONE, SVC_TEMPENTITY, _, id)
	write_byte(TE_SPRITE) // TE id (Additive sprite, plays 1 cycle)
	engfunc(EngFunc_WriteCoord, originF[0]) // x
	engfunc(EngFunc_WriteCoord, originF[1]) // y
	engfunc(EngFunc_WriteCoord, originF[2]) // z
	write_short(sprite_index) // sprite index
	write_byte(scale) // scale in 0.1's
	write_byte(200) // brightness
	message_end()
}

stock fm_find_ent_by_owner(entity, const classname[], owner)
{
	while ((entity = engfunc(EngFunc_FindEntityByString, entity, "classname", classname)) && (pev(entity, pev_owner) != owner)) {}
	
	return entity;
}

stock Float:get_weapon_next_pri_attack(entity)
{
	return get_pdata_float(entity, OFFSET_flNextPrimaryAttack, OFFSET_LINUX_WEAPONS)
}

stock set_weapon_next_pri_attack(entity, Float:time)
{
	set_pdata_float(entity, OFFSET_flNextPrimaryAttack, time, OFFSET_LINUX_WEAPONS)
}

stock Float:get_weapon_next_sec_attack(entity)
{
	return get_pdata_float(entity, OFFSET_flNextSecondaryAttack, OFFSET_LINUX_WEAPONS)
}

stock set_weapon_next_sec_attack(entity, Float:time)
{
	set_pdata_float(entity, OFFSET_flNextSecondaryAttack, time, OFFSET_LINUX_WEAPONS)
}

stock Float:get_weapon_idle_time(entity)
{
	return get_pdata_float(entity, OFFSET_flTimeWeaponIdle, OFFSET_LINUX_WEAPONS)
}

stock set_weapon_idle_time(entity, Float:time)
{
	set_pdata_float(entity, OFFSET_flTimeWeaponIdle, time, OFFSET_LINUX_WEAPONS)
}

#if defined SUPPORT_BOT_TO_USE
public bot_use_traps(id)
{
	//if (!is_user_alive(id))
	//	return;
	
	//if (!zp_get_user_zombie(id) || zp_get_user_zombie_class(id) != g_zclass_BrutalDaSu || zp_get_user_nemesis(id))
	//	return;
	
	static target, hitzone, distance
	target = get_valid_aim_target(id, hitzone, distance)
	
	if (!user_set_trap[id])
	{
		static Float:time
		time = get_gametime()
		
		// 設定當BOT若正瞄準某個有效目標,且目標在有效距離內,則檢查是否進行設置陷阱
		if (target > 0 && (500 <= distance <= 1000) && time >= bot_next_check_time[id])
		{
			if (random_num(1, 100) > 85) //設定BOT有15%機率會進行設置陷阱
			{
				if (do_set_trap(id)) //檢查設置陷阱物件是否是成功完成
					set_pev(id, pev_flags, (pev(id, pev_flags) | FL_FROZEN))
			}
			
			bot_next_check_time[id] = time + 1.0	//設定BOT每隔多少時間檢查一次是否進行設置陷阱(單位:秒)
		}
	}
	else
	{
		static Float:user_origin[3], Float:fdistance
		pev(id, pev_origin, user_origin)
		user_origin[2] = set_trap_origin[id][2]
		fdistance = get_distance_f(user_origin, set_trap_origin[id])
		
		// 設定當BOT若正瞄準某個有效目標,且目標在距離200的範圍內時,或是本身超出了設置陷阱的有效範圍,
		// 則讓BOT中斷設置陷阱
		if ((target > 0 && distance <= 200) || fdistance > 18.0)
		{
			stop_set_trap(id)
			set_pev(id, pev_flags, (pev(id, pev_flags) & ~FL_FROZEN))
		}
	}
}

public event_Damage(id)
{
	new attacker, weapon, hitzone
	attacker = get_user_attacker(id, weapon, hitzone)
	
	if (!(1 <= attacker <= g_maxplayers) || !is_user_connected(attacker) || !is_user_alive(attacker) 
	|| attacker == id)
		return;
	
	new damage = read_data(2)
	
	if (is_user_bot(id) && damage > 0)
	{
		new Float:origin1[3], Float:origin2[3], distance
		pev(id, pev_origin, origin1)
		pev(attacker, pev_origin, origin2)
		distance = floatround(get_distance_f(origin1, origin2))
		
		if (distance < 500 || damage > 100)
		{
			if (user_set_trap[id])
			{
				stop_set_trap(id)
				set_pev(id, pev_flags, (pev(id, pev_flags) & ~FL_FROZEN))
			}
		}
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

get_valid_aim_target(id, &hitzone, &distance)
{
	new target, aim_hitzone
	get_user_aiming(id, target, aim_hitzone)
	if (!(1 <= target <= g_maxplayers) || !is_user_alive(target) || zp_get_user_zombie(target))
		return 0;
	
	hitzone = aim_hitzone
	new Float:origin1[3], Float:origin2[3]
	pev(id, pev_origin, origin1)
	pev(target, pev_origin, origin2)
	distance = floatround(get_distance_f(origin1, origin2), floatround_round)
	
	return target;
}
#endif