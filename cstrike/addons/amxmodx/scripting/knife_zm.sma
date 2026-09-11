#include <amxmodx>
#include <fun>
#include <fakemeta>
#include <hamsandwich>
#include <zombieplague>

#define PLUGIN    "[ZP] Addon: Knife"
#define VERSION    "1.0"
#define AUTHOR    "Zombie-Mod.ru :: CSO Knife Mod Generator"

#define VIP ADMIN_LEVEL_A

new KNIFE1_V_MODEL[] = "models/v_dragontail.mdl"
new KNIFE1_P_MODEL[] = "models/p_dragontail.mdl"

new KNIFE2_V_MODEL[] = "models/v_knifedragon.mdl"
new KNIFE2_P_MODEL[] = "models/p_knifedragon.mdl"

new KNIFE3_V_MODEL[] = "models/v_katana.mdl"
new KNIFE3_P_MODEL[] = "models/p_katana.mdl"

new KNIFE4_V_MODEL[] = "models/v_hammer_new.mdl"
new KNIFE4_P_MODEL[] = "models/p_hammer_new.mdl"

new bool:g_KNIFE1[33]
new bool:g_KNIFE2[33]
new bool:g_KNIFE3[33]
new bool:g_KNIFE4[33]
new bool:g_hasSpeed[33]

new g_knife_menu, cvar_knock, cvar_jump, cvar_knife_gore, cvar_dmgmult1, cvar_dmgmult2, cvar_dmgmult3, cvar_knife_spd
new cvar_jump_vip, cvar_dmgmult_vip, cvar_knife_spd_vip, cvar_knock_vip

new const g_sound_knife[] = { "items/gunpickup2.wav" }

new const a_sounds[][] =
{
        "KnifeMod/dragontail/deploy1.wav",
        "KnifeMod/dragontail/1.wav",
        "KnifeMod/dragontail/1.wav",
        "KnifeMod/dragontail/hwall.wav",
        "KnifeMod/dragontail/slash1.wav",
        "KnifeMod/dragontail/stab.wav"
}

new const b_sounds[][] =
{
        "KnifeMod/knifedragon/deploy1.wav",
        "KnifeMod/knifedragon/1.wav",
        "KnifeMod/knifedragon/1.wav",
        "KnifeMod/knifedragon/hwall.wav",
        "KnifeMod/knifedragon/slash1.wav",
        "KnifeMod/knifedragon/1.wav"
}

new const c_sounds[][] =
{
        "KnifeMod/katana/deploy1.wav",
        "KnifeMod/katana/1.wav",
        "KnifeMod/katana/1.wav",
        "KnifeMod/katana/hwall.wav",
        "KnifeMod/katana/1.wav",
        "KnifeMod/katana/stab.wav"
}

new const d_sounds[][] =
{
        "KnifeMod/skullaxe/deploy1.wav",
        "KnifeMod/skullaxe/1.wav",
        "KnifeMod/skullaxe/1.wav",
        "KnifeMod/skullaxe/hwall.wav",
        "KnifeMod/skullaxe/slash1.wav",
        "KnifeMod/skullaxe/1.wav"
}

new const oldknife_sounds[][] =
{
        "weapons/knife_deploy1.wav",
        "weapons/knife_hit1.wav",
        "weapons/knife_hit2.wav",
        "weapons/knife_hitwall1.wav",
        "weapons/knife_slash1.wav",
        "weapons/knife_stab.wav"
}

public plugin_init()
{
        register_plugin(PLUGIN , VERSION , AUTHOR);
        register_cvar("zp_addon_knife", VERSION, FCVAR_SERVER);

        g_knife_menu = menu_create("Knife","menu_handle")
        register_clcmd("/knife","knifemenu",ADMIN_ALL,"knife_menu")
        register_clcmd("/knife1", "buy_knife1")
        register_clcmd("/knife2", "buy_knife2")
        register_clcmd("/knife3", "buy_knife3")
        register_clcmd("/knife4", "buy_knife4")
        build_menu()

        register_event("CurWeapon","checkWeapon","be","1=1");
        register_forward(FM_EmitSound, "fw_EmitSound");
        register_forward(FM_PlayerPreThink, "fw_PlayerPreThink");
        RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage");

        register_message(get_user_msgid("DeathMsg"), "message_DeathMsg");

        cvar_knock              = register_cvar("zp_knife_power"                , "15");
        cvar_jump               = register_cvar("zp_knife_jump"                 , "350.0");
        cvar_knife_gore         = register_cvar("zp_knife_effect"               , "1");
        cvar_dmgmult1           = register_cvar("zp_knife_dmg_muiti1"           , "3");
        cvar_dmgmult2           = register_cvar("zp_knife_dmg_muiti2"           , "5");
        cvar_dmgmult3           = register_cvar("zp_knife_dmg_muiti3"           , "2");
        cvar_knife_spd          = register_cvar("zp_knife_spd"                  , "500.0");
        cvar_jump_vip           = register_cvar("zp_knife_jump_vip"             , "380.0");
        cvar_dmgmult_vip        = register_cvar("zp_knife_dmg_vip"              , "5");
        cvar_knife_spd_vip      = register_cvar("zp_knife_spd_vip"              , "500.0");
        cvar_knock_vip          = register_cvar("zp_knife_power_vip"            , "17");
}

public client_connect(id)
{
        g_KNIFE1[id] = false
        g_KNIFE2[id] = false
        g_KNIFE3[id] = false
        g_KNIFE4[id] = false
        g_hasSpeed[id] = false
}

public client_disconnect(id)
{
        g_KNIFE1[id] = false
        g_KNIFE2[id] = false
        g_KNIFE3[id] = false
        g_KNIFE4[id] = false
        g_hasSpeed[id] = false
}

public plugin_precache()
{
        precache_model(KNIFE1_V_MODEL)
        precache_model(KNIFE1_P_MODEL)
        precache_model(KNIFE2_V_MODEL)
        precache_model(KNIFE2_P_MODEL)
        precache_model(KNIFE3_V_MODEL)
        precache_model(KNIFE3_P_MODEL)
        precache_model(KNIFE4_V_MODEL)
        precache_model(KNIFE4_P_MODEL)

        precache_sound(g_sound_knife)

        for(new i = 0; i < sizeof a_sounds; i++)
                precache_sound(a_sounds[i])

        for(new i = 0; i < sizeof b_sounds; i++)
                precache_sound(b_sounds[i])

        for(new i = 0; i < sizeof c_sounds; i++)
                precache_sound(c_sounds[i])

        for(new i = 0; i < sizeof d_sounds; i++)
                precache_sound(d_sounds[i])
}

build_menu()
{

        menu_additem(g_knife_menu, "Когти Смерти", "1")
        menu_additem(g_knife_menu, "Нож Дракона", "2")
        menu_additem(g_knife_menu, "Катана Самурая", "3")
        menu_additem(g_knife_menu, "\rТОПОР ВИПА", "4")
        menu_setprop(g_knife_menu, MPROP_PERPAGE, 0)
}

public knifemenu(id)
{
        if (zp_has_round_started())
                return PLUGIN_HANDLED

        if (!zp_has_round_started())
        {
                menu_display(id, g_knife_menu, 0)
        }
        return PLUGIN_HANDLED
}

public menu_handle(id, menu, item)
{
        if(item < 0) return PLUGIN_CONTINUE
        new cmd[2];
        new access, callback;
        menu_item_getinfo(menu, item, access, cmd,2,_,_, callback);
        new choice = str_to_num(cmd)
        switch (choice)
        {
                case 1: buy_knife1(id)
                case 2: buy_knife2(id)
                case 3: buy_knife3(id)
                case 4: buy_knife4(id)
        }
        return PLUGIN_HANDLED;
} 

public buy_knife1(id)
{
        g_KNIFE1[id] = true     
        g_KNIFE2[id] = false    
        g_KNIFE3[id] = false
        g_KNIFE4[id] = false
        g_hasSpeed[id] = true

        engfunc(EngFunc_EmitSound, id, CHAN_BODY, g_sound_knife, 1.0, ATTN_NORM, 0, PITCH_NORM)
}

public buy_knife2(id)
{
        g_KNIFE1[id] = false    
        g_KNIFE2[id] = true     
        g_KNIFE3[id] = false
        g_KNIFE4[id] = false
        g_hasSpeed[id] = false

        engfunc(EngFunc_EmitSound, id, CHAN_BODY, g_sound_knife, 1.0, ATTN_NORM, 0, PITCH_NORM)
}

public buy_knife3(id)
{
        g_KNIFE1[id] = false    
        g_KNIFE2[id] = false    
        g_KNIFE3[id] = true
        g_KNIFE4[id] = false
        g_hasSpeed[id] = false

        engfunc(EngFunc_EmitSound, id, CHAN_BODY, g_sound_knife, 1.0, ATTN_NORM, 0, PITCH_NORM)
}

public buy_knife4(id)
{
        if (get_user_flags(id) & VIP)
        {
                g_KNIFE1[id] = false    
                g_KNIFE2[id] = false    
                g_KNIFE3[id] = false
                g_KNIFE4[id] = true
                g_hasSpeed[id] = true

                engfunc(EngFunc_EmitSound, id, CHAN_BODY, g_sound_knife, 1.0, ATTN_NORM, 0, PITCH_NORM)
        }
        else 
        {
                client_cmd(id, "/knife")
        }

}

public checkWeapon(id)
{
        new plrWeapId
    
        plrWeapId = get_user_weapon(id)
    
        if (plrWeapId == CSW_KNIFE && (g_KNIFE1[id] || g_KNIFE2[id] || g_KNIFE3[id] || g_KNIFE4[id]))
        {
                checkModel(id)
        }
}

public checkModel(id)
{
        if (zp_get_user_zombie(id))
                return PLUGIN_HANDLED
    
        if (g_KNIFE1[id])
        {
                set_pev(id, pev_viewmodel2, KNIFE1_V_MODEL)
                set_pev(id, pev_weaponmodel2, KNIFE1_P_MODEL)
        }

        if (g_KNIFE2[id])
        {
                set_pev(id, pev_viewmodel2, KNIFE2_V_MODEL)
                set_pev(id, pev_weaponmodel2, KNIFE2_P_MODEL)
        }

        if (g_KNIFE3[id])
        {
                set_pev(id, pev_viewmodel2, KNIFE3_V_MODEL)
                set_pev(id, pev_weaponmodel2, KNIFE3_P_MODEL)
        }

        if (g_KNIFE4[id])
        {
                set_pev(id, pev_viewmodel2, KNIFE4_V_MODEL)
                set_pev(id, pev_weaponmodel2, KNIFE4_P_MODEL)
        }
        return PLUGIN_HANDLED
}

public fw_EmitSound(id, channel, const sound[])
{
        if(!is_user_alive(id) || zp_get_user_zombie(id))
                return FMRES_IGNORED
        
        for(new i = 0; i < sizeof a_sounds; i++)
        for(new i = 0; i < sizeof b_sounds; i++)
        for(new i = 0; i < sizeof c_sounds; i++)
        for(new i = 0; i < sizeof d_sounds; i++)
        {
                if(equal(sound, oldknife_sounds[i]))
                {
                        if (g_KNIFE1[id])
                        {
                                emit_sound(id, channel, a_sounds[i], 1.0, ATTN_NORM, 0, PITCH_NORM)
                                return FMRES_SUPERCEDE
                        }
                        if (g_KNIFE2[id])
                        {
                                emit_sound(id, channel, b_sounds[i], 1.0, ATTN_NORM, 0, PITCH_NORM)
                                return FMRES_SUPERCEDE
                        }
                        if (g_KNIFE3[id])
                        {
                                emit_sound(id, channel, c_sounds[i], 1.0, ATTN_NORM, 0, PITCH_NORM)
                                return FMRES_SUPERCEDE
                        }
                        if (g_KNIFE4[id])
                        {
                                emit_sound(id, channel, d_sounds[i], 1.0, ATTN_NORM, 0, PITCH_NORM)
                                return FMRES_SUPERCEDE
                        }
                        if (!g_KNIFE1[id] || !g_KNIFE2[id] || !g_KNIFE3[id] || !g_KNIFE4[id])
                        {
                                emit_sound(id, channel, oldknife_sounds[i], 1.0, ATTN_NORM, 0, PITCH_NORM)
                                return FMRES_SUPERCEDE
                        }
                }
        }
        return FMRES_IGNORED
}

public fw_PlayerPreThink(id)
{
        if(!is_user_alive(id) || zp_get_user_zombie(id))
                return FMRES_IGNORED

        new temp[2], weapon = get_user_weapon(id, temp[0], temp[1])

        if (weapon == CSW_KNIFE && g_KNIFE1[id])
        {
                g_hasSpeed[id] = true
                set_user_maxspeed(id,get_pcvar_float(cvar_knife_spd))
        }

        if(weapon == CSW_KNIFE && g_KNIFE3[id])        
                if ((pev(id, pev_button) & IN_JUMP) && !(pev(id, pev_oldbuttons) & IN_JUMP))
                {
                        new flags = pev(id, pev_flags)
                        new waterlvl = pev(id, pev_waterlevel)
                        
                        if (!(flags & FL_ONGROUND))
                                return FMRES_IGNORED

                        if (flags & FL_WATERJUMP)
                                return FMRES_IGNORED

                        if (waterlvl > 1)
                                return FMRES_IGNORED
                        
                        new Float:fVelocity[3]
                        pev(id, pev_velocity, fVelocity)
                        
                        fVelocity[2] += get_pcvar_num(cvar_jump)
                        
                        set_pev(id, pev_velocity, fVelocity)
                        set_pev(id, pev_gaitsequence, 6)
                }
        if (weapon == CSW_KNIFE && g_KNIFE4[id])
        {
                g_hasSpeed[id] = true
                set_user_maxspeed(id, get_pcvar_float(cvar_knife_spd_vip))

                if ((pev(id, pev_button) & IN_JUMP) && !(pev(id, pev_oldbuttons) & IN_JUMP))
                {
                        new flags = pev(id, pev_flags)
                        new waterlvl = pev(id, pev_waterlevel)
                        
                        if (!(flags & FL_ONGROUND))
                                return FMRES_IGNORED

                        if (flags & FL_WATERJUMP)
                                return FMRES_IGNORED

                        if (waterlvl > 1)
                                return FMRES_IGNORED
                        
                        new Float:fVelocity[3]
                        pev(id, pev_velocity, fVelocity)
                        
                        fVelocity[2] += get_pcvar_num(cvar_jump_vip)
                        
                        set_pev(id, pev_velocity, fVelocity)
                        set_pev(id, pev_gaitsequence, 6)
                }
        }
        return FMRES_IGNORED
}  

public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type)
{
        if(!is_user_connected(attacker))
                return HAM_IGNORED
        
        if(zp_get_user_zombie(attacker))
                return HAM_IGNORED

        new weapon = get_user_weapon(attacker)
        if (weapon == CSW_KNIFE && g_KNIFE1[attacker])
        {
                SetHamParamFloat(4, damage * get_pcvar_float(cvar_dmgmult1))    
        }
        if (weapon == CSW_KNIFE && g_KNIFE2[attacker])
        {       
                SetHamParamFloat(4, damage * get_pcvar_float(cvar_dmgmult2))

                new Float:vec[3];
                new Float:oldvelo[3];
                pev(victim, pev_velocity, oldvelo);
                create_velocity_vector(victim , attacker , vec);
                vec[0] += oldvelo[0];
                vec[1] += oldvelo[1];
                set_pev(victim, pev_velocity, vec);     
        }
        if (weapon == CSW_KNIFE && g_KNIFE3[attacker])
        {       
                SetHamParamFloat(4, damage * get_pcvar_float(cvar_dmgmult3))    
        }
        if (weapon == CSW_KNIFE && g_KNIFE4[attacker])
        {       
                SetHamParamFloat(4, damage * get_pcvar_float(cvar_dmgmult_vip)) 

                new Float:vec[3];
                new Float:oldvelo[3];
                pev(victim, pev_velocity, oldvelo);
                create_velocity_vector(victim , attacker , vec);
                vec[0] += oldvelo[0];
                vec[1] += oldvelo[1];
                set_pev(victim, pev_velocity, vec);
        }

        if(get_pcvar_num(cvar_knife_gore))
                more_blood(victim)

        return HAM_IGNORED
}

public message_DeathMsg(msg_id, msg_dest, id)
{
        static szTruncatedWeapon[33], iattacker, ivictim
        
        get_msg_arg_string(4, szTruncatedWeapon, charsmax(szTruncatedWeapon))
        
        iattacker = get_msg_arg_int(1)
        ivictim = get_msg_arg_int(2)
        
        if(!is_user_connected(iattacker) || iattacker == ivictim)
                return PLUGIN_CONTINUE

        if (!zp_get_user_zombie(iattacker))
        {
                if(equal(szTruncatedWeapon, "knife") && get_user_weapon(iattacker) == CSW_KNIFE)
                {
                        if(g_KNIFE1[iattacker])
                                set_msg_arg_string(4, "dragontail")
                }
        
                if(equal(szTruncatedWeapon, "knife") && get_user_weapon(iattacker) == CSW_KNIFE)
                {
                        if(g_KNIFE2[iattacker])
                                set_msg_arg_string(4, "knifedragon")
                }
        
                if(equal(szTruncatedWeapon, "knife") && get_user_weapon(iattacker) == CSW_KNIFE)
                {
                        if(g_KNIFE3[iattacker])
                                set_msg_arg_string(4, "katana")
                }
        
                if(equal(szTruncatedWeapon, "knife") && get_user_weapon(iattacker) == CSW_KNIFE)
                {
                        if(g_KNIFE4[iattacker])
                                set_msg_arg_string(4, "skullaxe")
                }
        
                if(equal(szTruncatedWeapon, "knife") && get_user_weapon(iattacker) == CSW_KNIFE)
                {
                        if(!g_KNIFE1[iattacker] && !g_KNIFE2[iattacker] && !g_KNIFE3[iattacker] && !g_KNIFE4[iattacker] && !zp_get_user_zombie(iattacker))
                                set_msg_arg_string(4, "knife")
                }
        }
        if (zp_get_user_zombie(iattacker))
        {
                if(equal(szTruncatedWeapon, "knife") && get_user_weapon(iattacker) == CSW_KNIFE)
                {
                        if(g_KNIFE1[iattacker] || g_KNIFE2[iattacker] || g_KNIFE3[iattacker] || g_KNIFE4[iattacker])
                                set_msg_arg_string(4, "Claws")
                }
        }
        return PLUGIN_CONTINUE
}

stock create_velocity_vector(victim,attacker,Float:velocity[3])
{
        if(!zp_get_user_zombie(victim) || !is_user_alive(attacker))
                return 0;

        new Float:vicorigin[3];
        new Float:attorigin[3];
        pev(victim, pev_origin , vicorigin);
        pev(attacker, pev_origin , attorigin);

        new Float:origin2[3]
        origin2[0] = vicorigin[0] - attorigin[0];
        origin2[1] = vicorigin[1] - attorigin[1];

        new Float:largestnum = 0.0;

        if(floatabs(origin2[0])>largestnum) largestnum = floatabs(origin2[0]);
        if(floatabs(origin2[1])>largestnum) largestnum = floatabs(origin2[1]);

        origin2[0] /= largestnum;
        origin2[1] /= largestnum;

        if (g_KNIFE2[attacker])
        {
                velocity[0] = ( origin2[0] * (get_pcvar_float(cvar_knock) * 3000) ) / floatround(get_distance_f(vicorigin, attorigin));
                velocity[1] = ( origin2[1] * (get_pcvar_float(cvar_knock) * 3000) ) / floatround(get_distance_f(vicorigin, attorigin));
        }
        if (g_KNIFE4[attacker])
        {
                velocity[0] = ( origin2[0] * (get_pcvar_float(cvar_knock_vip) * 3000) ) / floatround(get_distance_f(vicorigin, attorigin));
                velocity[1] = ( origin2[1] * (get_pcvar_float(cvar_knock_vip) * 3000) ) / floatround(get_distance_f(vicorigin, attorigin));
        }

        if(velocity[0] <= 20.0 || velocity[1] <= 20.0)
        velocity[2] = random_float(200.0 , 275.0);

        return 1;
}

stock fm_set_user_maxspeed(index, Float:speed = -1.0) 
{
        engfunc(EngFunc_SetClientMaxspeed, index, speed);
        set_pev(index, pev_maxspeed, speed);

        return 1;
}       

more_blood(id)
{
        static iOrigin[3]
        get_user_origin(id, iOrigin)
        
        // Blood spray
        message_begin(MSG_PVS, SVC_TEMPENTITY, iOrigin)
        write_byte(TE_BLOODSTREAM)
        write_coord(iOrigin[0])
        write_coord(iOrigin[1])
        write_coord(iOrigin[2]+10)
        write_coord(random_num(-360, 360)) // x
        write_coord(random_num(-360, 360)) // y
        write_coord(-10) // z
        write_byte(70) // color
        write_byte(random_num(50, 100)) // speed
        message_end()

        for (new j = 0; j < 4; j++) 
        {
                message_begin(MSG_PVS, SVC_TEMPENTITY, iOrigin)
                write_byte(TE_WORLDDECAL)
                write_coord(iOrigin[0]+random_num(-100, 100))
                write_coord(iOrigin[1]+random_num(-100, 100))
                write_coord(iOrigin[2]-36)
                write_byte(random_num(190, 197)) // index
                message_end()
        }
}
 