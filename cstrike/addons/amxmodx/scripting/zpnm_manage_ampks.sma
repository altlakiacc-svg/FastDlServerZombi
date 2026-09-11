#include <amxmodx>
#include <chatcolor>
#include <zombieplague>

#define CMDTARGET_OBEY_IMMUNITY (1<<0)
#define CMDTARGET_ALLOW_SELF	(1<<1)
#define CMDTARGET_ONLY_ALIVE	(1<<2)
#define CMDTARGET_NO_BOTS		(1<<3)

new g_maxplayers, show_activity

public plugin_init()
{
	register_plugin("[ZPNM] Sub-Plugin: Manage Ammo Packs", "1.0", "9 3 () |2 9 ! /<")
	
	register_dictionary_colored("zpnm_manage_ampks.txt")
	
	register_concmd("zpnm_set_ampks", "CmdSetAmpks", ADMIN_RCON, "<*/@surv/@hm/@nem/@zm/name> <amount to set/+/-> <amount>")
	
	g_maxplayers = get_maxplayers()
}

public CmdSetAmpks(aid, level, cid)
{
	if (!cmd_access(aid, level , cid, 3))
		return;
	
	static arg1[32], arg2[32], arg3[32], id,
	idname[33], aname[33], i, arg2num, arg3num
	
	read_argv(1, arg1, 31)
	read_argv(2, arg2, 31)
	read_argv(3, arg3, 31)
	
	get_user_name(aid, aname, 32)
	
	arg2num = str_to_num(arg2)
	arg3num = str_to_num(arg3)
	
	show_activity = get_cvar_num("amx_show_activity")
	
	if (!equali(arg1, "*") && !equali(arg1, "@surv")
	&& !equali(arg1, "@hm") && !equali(arg1, "@nem")
	&& !equali(arg1, "@zm"))
	{
		id = cmd_target(aid, arg1, CMDTARGET_ALLOW_SELF)
		
		if (!id) return;
		
		get_user_name(id, idname, 32)
		
		if (equali(arg2, "+"))
		{
			zp_set_user_ammo_packs(id, zp_get_user_ammo_packs(id) + arg3num)
			
			if (show_activity == 1)
				client_print_color(0, Blue, "%L", LANG_PLAYER, "ZPNM_GIVE_PLAYER1", arg3num, idname) //, arg3 > 1 ? "s" : ""
			else if (show_activity == 2)
				client_print_color(0, Blue, "%L", LANG_PLAYER, "ZPNM_GIVE_PLAYER2", aname, arg3num, idname)
		}
		else if (equali(arg2, "-"))
		{
			zp_set_user_ammo_packs(id, zp_get_user_ammo_packs(id) - arg3num)
			
			if (show_activity == 1)
				client_print_color(0, Blue, "%L", LANG_PLAYER, "ZPNM_TAKE_PLAYER1", arg3num, idname)
			else if (show_activity == 2)
				client_print_color(0, Blue, "%L", LANG_PLAYER, "ZPNM_TAKE_PLAYER2", aname, arg3num, idname)
		}
		else
		{
			zp_set_user_ammo_packs(id, arg2num)
			
			if (show_activity == 1)
				client_print_color(0, Blue, "%L", LANG_PLAYER, "ZPNM_SET_PLAYER1", idname, arg2num)
			else if (show_activity == 2)
				client_print_color(0, Blue, "%L", LANG_PLAYER, "ZPNM_SET_PLAYER2", aname, idname, arg2num)
		}
		
		return;
	}
	
	for (i = 1; i <= g_maxplayers; i++)
	{
		if (equali(arg1, "*"))
		{
			if (equali(arg2, "+"))
			{
				zp_set_user_ammo_packs(i, zp_get_user_ammo_packs(i) + arg3num)
				
				if (show_activity == 1)
					client_print_color(i, Blue, "%L", i, "ZPNM_GIVE_PLAYERS1", arg3num)
				else if (show_activity == 2)
					client_print_color(i, Blue, "%L", i, "ZPNM_GIVE_PLAYERS2", aname, arg3num)
			}
			else if (equali(arg2, "-"))
			{
				zp_set_user_ammo_packs(i, zp_get_user_ammo_packs(i) - arg3num)
				
				if (show_activity == 1)
					client_print_color(i, Blue, "%L", i, "ZPNM_TAKE_PLAYERS1", arg3num)
				else if (show_activity == 2)
					client_print_color(i, Blue, "%L", i, "ZPNM_TAKE_PLAYERS2", aname, arg3num)
			}
			else
			{
				zp_set_user_ammo_packs(i, arg2num)
				
				if (show_activity == 1)
					client_print_color(i, Blue, "%L", i, "ZPNM_SET_PLAYERS1", arg2num)
				else if (show_activity == 2)
					client_print_color(i, Blue, "%L", i, "ZPNM_SET_PLAYERS2", aname, arg2num)
			}
		}
		else if (equali(arg1, "@surv"))
		{
			if (equali(arg2, "+"))
			{
				if (zp_get_user_survivor(i))
					zp_set_user_ammo_packs(i, zp_get_user_ammo_packs(i) + arg3num)
				
				if (show_activity == 1)
					client_print_color(i, Blue, "%L", i, "ZPNM_GIVE_SURVIVORS1", arg3num)
				else if (show_activity == 2)
					client_print_color(i, Blue, "%L", i, "ZPNM_GIVE_SURVIVORS2", aname, arg3num)
			}
			else if (equali(arg2, "-"))
			{
				if (zp_get_user_survivor(i))
					zp_set_user_ammo_packs(i, zp_get_user_ammo_packs(i) - arg3num)
				
				if (show_activity == 1)
					client_print_color(i, Blue, "%L", i, "ZPNM_TAKE_SURVIVORS1", arg3num)
				else if (show_activity == 2)
					client_print_color(i, Blue, "%L", i, "ZPNM_TAKE_SURVIVORS2", aname, arg3num)
			}
			else
			{
				if (zp_get_user_survivor(i))
					zp_set_user_ammo_packs(i, arg2num)
				
				if (show_activity == 1)
					client_print_color(i, Blue, "%L", i, "ZPNM_SET_SURVIVORS1", arg2num)
				else if (show_activity == 2)
					client_print_color(i, Blue, "%L", i, "ZPNM_SET_SURVIVORS2", aname, arg2num)
			}
		}
		else if (equali(arg1, "@hm"))
		{
			if (equali(arg2, "+"))
			{
				if (!zp_get_user_zombie(i) && !zp_get_user_survivor(i))
					zp_set_user_ammo_packs(i, zp_get_user_ammo_packs(i) + arg3num)
				
				if (show_activity == 1)
					client_print_color(i, Blue, "%L", i, "ZPNM_GIVE_HUMANS1", arg3num)
				else if (show_activity == 2)
					client_print_color(i, Blue, "%L", i, "ZPNM_GIVE_HUMANS2", aname, arg3num)
			}
			else if (equali(arg2, "-"))
			{
				if (!zp_get_user_zombie(i) && !zp_get_user_survivor(i))
					zp_set_user_ammo_packs(i, zp_get_user_ammo_packs(i) - arg3num)
				
				if (show_activity == 1)
					client_print_color(i, Blue, "%L", i, "ZPNM_TAKE_HUMANS1", arg3num)
				else if (show_activity == 2)
					client_print_color(i, Blue, "%L", i, "ZPNM_TAKE_HUMANS2", aname, arg3num)
			}
			else
			{
				if (!zp_get_user_zombie(i) && !zp_get_user_survivor(i))
					zp_set_user_ammo_packs(i, arg2num)
				
				if (show_activity == 1)
					client_print_color(i, Blue, "%L", i, "ZPNM_SET_HUMANS1", arg2num)
				else if (show_activity == 2)
					client_print_color(i, Blue, "%L", i, "ZPNM_SET_HUMANS2", aname, arg2num)
			}
		}
		else if (equali(arg1, "@nem"))
		{
			if (equali(arg2, "+"))
			{
				if (zp_get_user_nemesis(i))
					zp_set_user_ammo_packs(i, zp_get_user_ammo_packs(i) + arg3num)
				
				if (show_activity == 1)
					client_print_color(i, Blue, "%L", i, "ZPNM_GIVE_NEMESIS1", arg3num)
				else if (show_activity == 2)
					client_print_color(i, Blue, "%L", i, "ZPNM_GIVE_NEMESIS2", aname, arg3num)
			}
			else if (equali(arg2, "-"))
			{
				if (zp_get_user_nemesis(i))
					zp_set_user_ammo_packs(i, zp_get_user_ammo_packs(i) - arg3num)
				
				if (show_activity == 1)
					client_print_color(i, Blue, "%L", i, "ZPNM_TAKE_NEMESIS1", arg3num)
				else if (show_activity == 2)
					client_print_color(i, Blue, "%L", i, "ZPNM_TAKE_NEMESIS2", aname, arg3num)
			}
			else
			{
				if (zp_get_user_nemesis(i))
					zp_set_user_ammo_packs(i, arg2num)
				
				if (show_activity == 1)
					client_print_color(i, Blue, "%L", i, "ZPNM_SET_NEMESIS1", arg2num)
				else if (show_activity == 2)
					client_print_color(i, Blue, "%L", i, "ZPNM_SET_NEMESIS2", aname, arg2num)
			}
		}
		else if (equali(arg1, "@zm"))
		{
			if (equali(arg2, "+"))
			{
				if (zp_get_user_zombie(i) && !zp_get_user_nemesis(i))
					zp_set_user_ammo_packs(i, zp_get_user_ammo_packs(i) + arg3num)
				
				if (show_activity == 1)
					client_print_color(i, Blue, "%L", i, "ZPNM_GIVE_ZOMBIES1", arg3num)
				else if (show_activity == 2)
					client_print_color(i, Blue, "%L", i, "ZPNM_GIVE_ZOMBIES2", aname, arg3num)
			}
			else if (equali(arg2, "-"))
			{
				if (zp_get_user_zombie(i) && !zp_get_user_nemesis(i))
					zp_set_user_ammo_packs(i, zp_get_user_ammo_packs(i) - arg3num)
				
				if (show_activity == 1)
					client_print_color(i, Blue, "%L", i, "ZPNM_TAKE_ZOMBIES1", arg3num)
				else if (show_activity == 2)
					client_print_color(i, Blue, "%L", i, "ZPNM_TAKE_ZOMBIES2", aname, arg3num)
			}
			else
			{
				if (zp_get_user_zombie(i) && !zp_get_user_nemesis(i))
					zp_set_user_ammo_packs(i, arg2num)
				
				if (show_activity == 1)
					client_print_color(i, Blue, "%L", i, "ZPNM_SET_ZOMBIES1", arg2num)
				else if (show_activity == 2)
					client_print_color(i, Blue, "%L", i, "ZPNM_SET_ZOMBIES2", aname, arg2num)
			}
		}
	}
}

stock is_user_admin(id)
{
	new __flags=get_user_flags(id);
	return (__flags>0 && !(__flags&ADMIN_USER));
}

stock cmd_access(id, level, cid, num, bool:accesssilent = false) 
{
	new has_access = 0;
	if ( id==(is_dedicated_server()?0:1) ) 
	{
		has_access = 1;
	}
	else if ( level==ADMIN_ADMIN )
	{
		if ( is_user_admin(id) )
		{
			has_access = 1;
		}
	}
	else if ( get_user_flags(id) & level )
	{
		has_access = 1;
	}
	else if (level == ADMIN_ALL) 
	{
		has_access = 1;
	}

	if ( has_access==0 ) 
	{
		if (!accesssilent)
		{
#if defined AMXMOD_BCOMPAT
			console_print(id, SIMPLE_T("You have no access to that command."));
#else
			console_print(id,"%L",id,"NO_ACC_COM");
#endif
		}
		return 0;
	}
	if (read_argc() < num) 
	{
		new hcmd[32], hinfo[128], hflag;
		get_concmd(cid,hcmd,31,hflag,hinfo,127,level);
#if defined AMXMOD_BCOMPAT
		console_print(id, SIMPLE_T("Usage:  %s %s"), hcmd, SIMPLE_T(hinfo));
#else
		console_print(id,"%L:  %s %s",id,"USAGE",hcmd,hinfo);
#endif
		return 0;
	}
	
	return 1;
}

stock cmd_target(id,const arg[],flags = CMDTARGET_OBEY_IMMUNITY) 
{
	new player = find_player("bl",arg);
	if (player) 
	{
		if ( player != find_player("blj",arg) ) 
		{
#if defined AMXMOD_BCOMPAT
			console_print(id, SIMPLE_T("There are more clients matching to your argument"));
#else
			console_print(id,"%L",id,"MORE_CL_MATCHT");
#endif
			return 0;
		}
	}
	else if ( ( player = find_player("c",arg) )==0 && arg[0]=='#' && arg[1] )
	{
		player = find_player("k",str_to_num(arg[1]));
	}
	if (!player) 
	{
#if defined AMXMOD_BCOMPAT
		console_print(id, SIMPLE_T("Client with that name or userid not found"));
#else
		console_print(id,"%L",id,"CL_NOT_FOUND");
#endif
		return 0;
	}
	if (flags & CMDTARGET_OBEY_IMMUNITY) 
	{
		if ((get_user_flags(player) & ADMIN_IMMUNITY) && 
			((flags & CMDTARGET_ALLOW_SELF) ? (id != player) : true) ) 
		{
			new imname[32];
			get_user_name(player,imname,31);
#if defined AMXMOD_BCOMPAT
			console_print(id, SIMPLE_T("Client ^"%s^" has immunity"), imname);
#else
			console_print(id,"%L",id,"CLIENT_IMM",imname);
#endif
			return 0;
		}
	}
	if (flags & CMDTARGET_ONLY_ALIVE) 
	{
		if (!is_user_alive(player)) 
		{
			new imname[32];
			get_user_name(player,imname,31);
#if defined AMXMOD_BCOMPAT
			console_print(id, SIMPLE_T("That action can't be performed on dead client ^"%s^""), imname);
#else
			console_print(id,"%L",id,"CANT_PERF_DEAD",imname);
#endif
			return 0;
		}
	}
	if (flags & CMDTARGET_NO_BOTS) 
	{
		if (is_user_bot(player)) 
		{
			new imname[32];
			get_user_name(player,imname,31);
#if defined AMXMOD_BCOMPAT
			console_print(id, SIMPLE_T("That action can't be performed on bot ^"%s^""), imname);
#else
			console_print(id,"%L",id,"CANT_PERF_BOT",imname);
#endif
			return 0;
		}
	}
	return player;
}
