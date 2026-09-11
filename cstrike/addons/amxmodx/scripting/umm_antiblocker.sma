/*	AMX Mod X
*
*	UFPS Anti Blocker
*
*	 Этот плагин является аддоном для UFPS Map Manager
*	и осуществляет возможность проходимости игроков друг сквозь друга в начале раунда.
*
*	Плагин выполнен на основе:
*		- csdm_protection.sma by BAILOPAN
*		- kz_noblock.sma by teame06
*
*	Переменные:
*		umm_antiblock			(default - 1)	- Включает/отключает использование плагина
*		umm_antiblock_time		(default - 5)	- Время в секундах в течении которого игроки могут проходить друг сквозь друга
*
*	This file is part of UFPS.Team Plugins
*/

#include <amxmodx>
#include <fakemeta>

#define PLUGIN_NAME			"UFPS Anti Blocker"
#define PLUGIN_VERSION		"2.0"
#define PLUGIN_AUTHOR		"UFPS.Team"

#define SC_TASKID			38800

new bool:g_antiblock = false
new pcv_antiblock
new pcv_antiblock_time
new g_duration[33]

public plugin_init ( )
{
	register_plugin ( PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR )
	register_forward ( FM_StartFrame, "fm_startframe" )
	register_logevent ( "event_round_start", 2, "0=World triggered", "1=Round_Start" )

	pcv_antiblock = register_cvar ( "umm_antiblock", "1" )
	pcv_antiblock_time = register_cvar ( "umm_antiblock_time", "10" )
}

public fm_startframe ( )
{
	if ( !g_antiblock ) return FMRES_IGNORED

	static players[32], num, i, player

	get_players ( players, num, "ach" )

	for ( i = 0; i < num; i++ )
	{
		player = players[i]

		if ( is_semiclip ( player ) )
		{
			if ( is_solid ( player ) )
				set_notsolid ( player )
		}
		else
		{
			if ( !is_solid ( player ) )
				set_solid ( player )
		}
	}

	return FMRES_IGNORED
}

bool:is_semiclip ( id )
{
	static players[32], num, i, target, team
/*
	switch ( get_user_team ( id ) )
	{
		case 1:
			get_players ( players, num, "ach", "T" )

		case 2:
			get_players ( players, num, "ach", "CT" )

		default:
			return false
	}
*/
	static Float:player_origin[3], Float:player_origin_z[3]
	static Float:target_origin[3], Float:target_origin_z[3]

	pev ( id, pev_origin, player_origin )

	player_origin_z[2] = player_origin[2]
	player_origin[2] = 0.0

	get_players ( players, num, "ach" )
	team = get_user_team ( id )

	for ( i = 0; i < num; i++ )
	{
		target = players[i]

		if ( id == target || team != get_user_team ( target ) ) continue

		pev ( target, pev_origin, target_origin )

		target_origin_z[2] = target_origin[2]
		target_origin[2] = 0.0

		if ( ( vector_distance ( player_origin, target_origin ) < 60 && vector_distance ( player_origin_z, target_origin_z ) < 90 ) )
			return true
	}

	return false
}

bool:is_solid ( id )
{
	if ( pev ( id, pev_solid ) == SOLID_BBOX )
		return true

	return false
}

set_solid ( id )
{
	if ( is_user_alive ( id ) )
	{
		use_rendering ( id )
		set_pev ( id, pev_solid, SOLID_BBOX )
	}
}

set_notsolid ( id )
{
	if ( is_user_alive ( id ) )
	{
		use_rendering ( id, kRenderFxPulseSlow, 0, 0, 0, kRenderTransTexture, 200 )
		set_pev ( id, pev_solid, SOLID_NOT )
	}
}

stock use_rendering ( index, fx = kRenderFxNone, r = 255, g = 255, b = 255, render = kRenderNormal, amount = 16 )
{
	set_pev ( index, pev_renderfx, fx )

	new Float:RenderColor[3]

	RenderColor[0] = float ( r )
	RenderColor[1] = float ( g )
	RenderColor[2] = float ( b )

	set_pev ( index, pev_rendercolor, RenderColor )
	set_pev ( index, pev_rendermode, render )
	set_pev ( index, pev_renderamt, float ( amount ) )
}

public event_round_start ( )
{
	if ( task_exists ( SC_TASKID ) )
		remove_task ( SC_TASKID )

	if ( get_pcvar_num ( pcv_antiblock ) )
		g_antiblock = true

	set_task ( get_pcvar_float ( pcv_antiblock_time ), "task_sc_end", SC_TASKID )

	return PLUGIN_CONTINUE
}

public task_sc_end ( )
{
	g_antiblock = false

	static players[32], num, i, player

	get_players ( players, num, "ach" )

	for ( i = 0; i < num; i++ )
	{
		player = players[i]

		if ( !is_solid ( player ) )
		{
			g_duration[player] = 0
			set_task ( 0.2, "task_sc_wait", player )
		}
	}

	return PLUGIN_CONTINUE
}

public task_sc_wait ( id )
{
	if ( task_exists ( id ) )
		remove_task ( id )

	if ( is_semiclip ( id ) )
	{
		if ( ++g_duration[id] > 20 )
			user_slap ( id, 0 )

		set_task ( 0.2, "task_sc_wait", id )
	}

	else
		set_solid ( id )

	return PLUGIN_CONTINUE
}

public plugin_end ( )
{
	if ( task_exists ( SC_TASKID ) )
		remove_task ( SC_TASKID )

	g_antiblock = false

	for ( new i = 1; i < 33; i++ )
		if ( task_exists ( i ) )
			remove_task ( i )

	return PLUGIN_CONTINUE
}
