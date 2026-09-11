#include <amxmodx>
#include <cstrike>
#include <engine>
#include <fakemeta>
#include <fun>
#include <xs>
#include <hamsandwich>
#include <zombieplague>

#define Plugin "Jump Grenade"
#define Version "1.0"
#define Author "xz"

new const g_PlayerModel [ ] = "models/zombie_plague/re/p_zombibomb.mdl"
new const g_WorldModel [ ] = "models/zombie_plague/re/w_zombibomb.mdl"

new const g_SoundGrenadeBuy [ ] [ ] = { "items/gunpickup2.wav" }
new const g_SoundAmmoPurchase [ ] [ ] = { "items/9mmclip1.wav" }
new const g_SoundBombExplode [ ] [ ] = { "weapons/td_stun.wav" }

#define MAXCARRY    5
#define RADIUS        300.0

#define MAXPLAYERS        32
#define pev_nade_type        pev_flTimeStepSound
#define NADE_TYPE_JUMPING    26517
#define AMMOID_SM        13

new g_iExplo

new g_iNadeID

new g_iJumpingNadeCount [ MAXPLAYERS+1 ]
new g_iCurrentWeapon [ MAXPLAYERS+1 ]

new cvar_speed
new g_msgSayText
new iconstatus
new grenade_icons[33][32]
new bool:g_bIsConnected[33]

new g_MaxPlayers
new g_msgAmmoPickup

public plugin_precache ()
{
    precache_model ( g_PlayerModel )
    precache_model ( g_WorldModel )
   
    new i
    for ( i = 0; i < sizeof g_SoundGrenadeBuy; i++ )
        precache_sound ( g_SoundGrenadeBuy [ i ] )
    for ( i = 0; i < sizeof g_SoundAmmoPurchase; i++ )
        precache_sound ( g_SoundAmmoPurchase [ i ] )
    for ( i = 0; i < sizeof g_SoundBombExplode; i++ )
        precache_sound ( g_SoundBombExplode [ i ] )


    g_iExplo = precache_model ( "sprites/zombiebomb_exp.spr" )
    precache_sound("weapons/zbomb_bomb_idle_2.wav")
    precache_sound("weapons/zbomb_bomb_idle1.wav")
    precache_sound("weapons/zbomb_deplee.wav")
    precache_sound("weapons/zbomb_idl1234.wav")
    precache_sound("weapons/zbomb_pull1.wav")
    precache_sound("weapons/zid3.wav")
}

public plugin_init ( )
{
    register_plugin ( Plugin, Version, Author )
	
    register_dictionary("plugins.txt")

    g_iNadeID = zp_register_extra_item ("Knockback Bomb", 1, ZP_TEAM_ZOMBIE)
	
    g_msgSayText = get_user_msgid("SayText")
	
    register_event ( "CurWeapon", "EV_CurWeapon", "be", "1=1" )
    register_event ( "HLTV", "EV_NewRound", "a", "1=0", "2=0" )
    register_event ( "DeathMsg", "EV_DeathMsg", "a" )
    register_event ( "CurWeapon", "grenade_icon", "be", "1=1" )
    register_event ( "DeathMsg", "event_death", "a" )
    iconstatus = get_user_msgid("StatusIcon")
    
    register_forward ( FM_SetModel, "fw_SetModel" )
    RegisterHam ( Ham_Think, "grenade", "fw_ThinkGrenade" )
    
    cvar_speed = register_cvar ( "zp_zombiebomb_knockback", "600" )
    
    g_msgAmmoPickup = get_user_msgid ( "AmmoPickup" )
    
    g_MaxPlayers = get_maxplayers ( )
}

public client_connect(id)
{
    g_iJumpingNadeCount[id] = 0
}

public client_putinserver(id)
{
	g_bIsConnected[id] = true
}

public zp_extra_item_selected(id, Item)
{

    if ( Item == g_iNadeID )
    {
        if ( g_iJumpingNadeCount [ id ] >= MAXCARRY )
        {
            client_print ( id, print_chat, "[ZP] Cannot hold mode grenades!" )
            return ZP_PLUGIN_HANDLED
        }
        
        new iBpAmmo = cs_get_user_bpammo ( id, CSW_SMOKEGRENADE )
        
        if ( g_iJumpingNadeCount [ id ] >= 1 )
        {
            cs_set_user_bpammo ( id, CSW_SMOKEGRENADE, iBpAmmo+1 )
            
            emit_sound ( id, CHAN_ITEM, g_SoundAmmoPurchase[random_num(0, sizeof g_SoundAmmoPurchase-1)], VOL_NORM, ATTN_NORM, 0, PITCH_NORM )
            
            AmmoPickup ( id, AMMOID_SM, 1 )
            
            g_iJumpingNadeCount [ id ]++
        }
        else
        {
            give_item ( id, "weapon_smokegrenade" )
			
            emit_sound ( id, CHAN_ITEM, g_SoundGrenadeBuy[random_num(0, sizeof g_SoundGrenadeBuy-1)], VOL_NORM, ATTN_NORM, 0, PITCH_NORM )
		    
            client_printcolor(id, "/g[ZP]/y %L", id, "knoc_bom")			
		    
            AmmoPickup ( id, AMMOID_SM, 1 )
            
            g_iJumpingNadeCount [ id ] = 1
        }
    }
    return PLUGIN_CONTINUE
}


public zp_user_infected_post ( Player, Infector, Nemesis )
{
	if(zp_is_survivor_round() || zp_is_nemesis_round())

        g_iJumpingNadeCount [ Player ] = 0
		
        else
    {
        g_iJumpingNadeCount [ Player ] = 0
	   
        if(!zp_get_user_nemesis(Player))
		   
        give_item ( Player, "weapon_smokegrenade" )
		
        engclient_cmd(Player, "weapon_knife")
            
        emit_sound ( Player, CHAN_ITEM, g_SoundGrenadeBuy[random_num(0, sizeof g_SoundGrenadeBuy-1)], VOL_NORM, ATTN_NORM, 0, PITCH_NORM )
            
        AmmoPickup ( Player, AMMOID_SM, 1 )
            
        g_iJumpingNadeCount [ Player ] = 1
		          
    }

}

public zp_user_humanized_post ( Player, Survivor )
{
    if ( Survivor )
    {
        g_iJumpingNadeCount [ Survivor ] = 0
    }
	else
	{
	    g_iJumpingNadeCount [ Player ] = 0
	}
}

public EV_CurWeapon ( Player )
{
        if ( !is_user_alive ( Player ) || !zp_get_user_zombie ( Player ) )
            return PLUGIN_CONTINUE

        g_iCurrentWeapon [ Player ] = read_data ( 2 )

        if ( g_iJumpingNadeCount [ Player ] > 0 && g_iCurrentWeapon [ Player ] == CSW_SMOKEGRENADE )
        { 		
		    set_pev ( Player, pev_weaponmodel2, g_PlayerModel )
        }

        return PLUGIN_CONTINUE
}

public EV_NewRound ( )
{
    arrayset ( g_iJumpingNadeCount, 0, 33 )
}

public EV_DeathMsg ( )
{
    new iVictim = read_data ( 2 )
    
    if ( !is_user_connected ( iVictim ) )
        return
    
    g_iJumpingNadeCount [ iVictim ] = 0
}

public fw_SetModel ( Entity, const Model[] )
{
    if ( Entity < 0 )
        return FMRES_IGNORED
    
    if ( pev ( Entity, pev_dmgtime ) == 0.0 )
        return FMRES_IGNORED
    
    new iOwner = entity_get_edict ( Entity, EV_ENT_owner )    
    
    if ( g_iJumpingNadeCount [ iOwner ] >= 1 && equal ( Model [ 7 ], "w_sm", 4 ) )
    {
        set_pev ( Entity, pev_nade_type, 0 )
        
        set_pev ( Entity, pev_nade_type, NADE_TYPE_JUMPING )
        
        g_iJumpingNadeCount [ iOwner ]--
        
        fm_set_rendering(Entity, kRenderFxGlowShell, 250, 215, 0, kRenderNormal, 16)
        entity_set_model ( Entity, g_WorldModel )
        return FMRES_SUPERCEDE
    }
    return FMRES_IGNORED
}

public fw_ThinkGrenade ( Entity )
{
    if ( !pev_valid ( Entity ) )
        return HAM_IGNORED
    
    static Float:dmg_time
    pev ( Entity, pev_dmgtime, dmg_time )
    
    if ( dmg_time > get_gametime ( ) )
        return HAM_IGNORED
    
    if ( pev ( Entity, pev_nade_type ) == NADE_TYPE_JUMPING )
    {
        jumping_explode ( Entity )
        return HAM_SUPERCEDE
    }
    return HAM_IGNORED
}

public jumping_explode ( Entity )
{
    if ( Entity < 0 )
        return
    
    static Float:flOrigin [ 3 ]
    pev ( Entity, pev_origin, flOrigin )
    
    engfunc ( EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, flOrigin, 0 )
    write_byte ( TE_SPRITE ) 
    engfunc ( EngFunc_WriteCoord, flOrigin [ 0 ] )
    engfunc ( EngFunc_WriteCoord, flOrigin [ 1 ] )
    engfunc ( EngFunc_WriteCoord, flOrigin [ 2 ] + 45.0 )
    write_short ( g_iExplo )
    write_byte ( 35 )
    write_byte ( 186 )
    message_end ( )
    
    
    emit_sound ( Entity, CHAN_WEAPON, g_SoundBombExplode[random_num(0, sizeof g_SoundBombExplode-1)], VOL_NORM, ATTN_NORM, 0, PITCH_NORM )
    
    for ( new i = 1; i < g_MaxPlayers; i++ )
    {
        if ( !is_user_alive  ( i ) )
            continue
   
        new Float:flVictimOrigin [ 3 ]
        pev ( i, pev_origin, flVictimOrigin )
        
        new Float:flDistance = get_distance_f ( flOrigin, flVictimOrigin )    
        
        if ( flDistance <= RADIUS )
        {
            static Float:flSpeed
            flSpeed = get_pcvar_float ( cvar_speed )
            
            static Float:flNewSpeed
            flNewSpeed = flSpeed * ( 1.0 - ( flDistance / RADIUS ) )
            
            static Float:flVelocity [ 3 ]
            get_speed_vector ( flOrigin, flVictimOrigin, flNewSpeed, flVelocity )
            
            set_pev ( i, pev_velocity,flVelocity )
        }
    }
    
    engfunc ( EngFunc_RemoveEntity, Entity )
}        

public AmmoPickup ( Player, AmmoID, AmmoAmount )
{
    message_begin ( MSG_ONE, g_msgAmmoPickup, _, Player )
    write_byte ( AmmoID )
    write_byte ( AmmoAmount )
    message_end ( )
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
	public grenade_icon(id) 
{
	remove_grenade_icon(id)
		
	if(is_user_bot(id))
		return
		
	static igrenade, grenade_sprite[16], grenade_color[3]
	igrenade = get_user_weapon(id)
	
	switch(igrenade) 
	{
		case CSW_SMOKEGRENADE:
		{
			if(!is_user_alive(id) || zp_get_user_zombie(id)) {
				grenade_sprite = "dmg_gas"
				grenade_color = {255, 165, 0} 
			}
			else
			{
				grenade_sprite = ""
				grenade_color = {0, 0, 0} 
			}
		}
		default: 
		return
	}
	grenade_icons[id] = grenade_sprite
	
	// show grenade icons
	message_begin(MSG_ONE,iconstatus,{0,0,0},id)
	write_byte(1) // status (0=hide, 1=show, 2=flash)
	write_string(grenade_icons[id]) // sprite name
	write_byte(grenade_color[0]) // red
	write_byte(grenade_color[1]) // green
	write_byte(grenade_color[2]) // blue
	message_end()
	
	return
}

public remove_grenade_icon(id) 
{
	// remove grenade icons
	message_begin(MSG_ONE,iconstatus,{0,0,0},id)
	write_byte(0) // status (0=hide, 1=show, 2=flash)
	write_string(grenade_icons[id]) // sprite name
	message_end()
}

public event_death() 
{
	new id = read_data(2)
	
	if(!is_user_bot(id))
	remove_grenade_icon(id)
}

stock fm_set_rendering(entity, fx = kRenderFxNone, r = 255, g = 255, b = 255, render = kRenderNormal, amount = 16)
{
	static Float:color[3]
	color[0] = float(r)
	color[1] = float(g)
	color[2] = float(b)
	
	set_pev(entity, pev_renderfx, fx)
	set_pev(entity, pev_rendercolor, color)
	set_pev(entity, pev_rendermode, render)
	set_pev(entity, pev_renderamt, float(amount))
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