/*
	Created by DJ_WEST
	
	Web: http://amx-x.ru
	Русское сообщество по AMX Mod X и SourceMod
	
	Присоединяйтесь к нам. Здесь рождаются новые идеи.
*/

#include <amxmodx>

#define PLUGIN "Loading Game Banner"
#define VERSION "1.3"
#define AUTHOR "DJ_WEST"

#define MAX_SIZE 1012
#define BANNER_FILE "resource/images/amx-x.tga"
#define TASKID 6892

new const g_Files[][64] =
{
	"resource/LoadingDialog.res",
	"resource/LoadingDialogNoBanner.res",
	"resource/LoadingDialogVAC.res"
}

new g_Text[MAX_SIZE], g_CvarEnabled, g_ChangeDelay[33], bool:g_PlayerConnected[33]

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_clcmd("change", "Change_LoadingGame")
    
	g_CvarEnabled    = register_cvar("amx_banner", "1")
    
	if (get_pcvar_num(g_CvarEnabled))
		set_task(0.1, "Read_LoadingGame")
}

public client_connect(id)
	client_cmd(id, "cl_allowdownload 1")

public plugin_precache()
{
	precache_generic(BANNER_FILE)
}

public Read_LoadingGame()
{
	new i_File, s_File[128], s_Banner[32], i_Len

	i_Len = strlen(BANNER_FILE)
	get_configsdir(s_File, charsmax(s_File))
	format(s_File, charsmax(s_File), "%s/loading_banner.ini", s_File)
	formatex(s_Banner, i_Len - 4, "%s", BANNER_FILE)
	i_File = fopen(s_File, "r")
	fgets(i_File, g_Text, MAX_SIZE)
	replace(g_Text, charsmax(g_Text), "banner_file", s_Banner)
	fclose(i_File)
}

public client_putinserver(id)
{	
	if (get_pcvar_num(g_CvarEnabled))
	{
		if (is_user_hltv(id) || is_user_bot(id))
			return PLUGIN_HANDLED
			
		g_ChangeDelay[id] = 0
		g_PlayerConnected[id] = true
		set_task(3.0, "Change_LoadingGame", id)
	}
	
	return PLUGIN_HANDLED
}

public Change_LoadingGame(id)
{
	set_task(1.0, "Change_LoadingGame_Delay", id + TASKID, "", 0, "a", 4)
}
    
public Change_LoadingGame_Delay(taskid)
{
	new id, i

	id = taskid - TASKID
	
	if (!g_PlayerConnected[id])
		return PLUGIN_HANDLED
		
	i = g_ChangeDelay[id]
  
	if (i == 3)
	{
		client_cmd(id, "motdfile motd.txt")
		g_ChangeDelay[id] = 0
	}
	else
	{
		client_cmd(id, "motdfile %s", g_Files[i])
		client_cmd(id, "motd_write %s", g_Text)
        
		g_ChangeDelay[id]++
	}
	
	return PLUGIN_HANDLED
}

public client_disconnect(id)
{
	g_PlayerConnected[id] = false
	remove_task(id + TASKID)
}
 
stock get_configsdir(s_Name[], i_Len)
	return get_localinfo("amxx_configsdir", s_Name, i_Len)
