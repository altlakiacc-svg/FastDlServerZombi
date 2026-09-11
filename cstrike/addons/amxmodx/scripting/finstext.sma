#include <amxmodx>
#include <amxmisc>

#define PLUGIN "finstext"
#define VERSION "1.4"
#define AUTHOR "shad0wgg"


enum ChatColor
{
	CHATCOLOR_YELLOW = 1, 	
	CHATCOLOR_GREEN, 	
	CHATCOLOR_TEAM_COLOR, 	
	CHATCOLOR_GREY, 	
	CHATCOLOR_RED, 		
	CHATCOLOR_BLUE, 	
}

new g_TeamName[][] = 
{
	"",
	"TERRORIST",
	"CT",
	"SPECTATOR"
}

new g_msgSayText
new g_msgTeamInfo
 

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_cvar("text_chat", "1")
	register_cvar("text_chat_interval", "60")
	
	register_cvar("text_chat_1", "Чтобы поставить мину. Пропишите в консоли:")
	register_cvar("text_chat_2", "bind * +setlaser  Вместо * любую кнопку.")
	register_cvar("text_chat_3", "Чтобы снять. Пропишите:")
	register_cvar("text_chat_4", "bind * +dellaser  Вместо * любую кнопку.")
	register_cvar("text_chat_5", "Контакты гл.админа Skype kolchin.vitaliy ICQ 761095")
	
	g_msgSayText = get_user_msgid("SayText")
	g_msgTeamInfo = get_user_msgid("TeamInfo")
}

public plugin_cfg()
{
  set_task(get_cvar_float("text_chat_interval"), "showMsg", 12345, "", _, "b")
}

public showMsg()
{
  if(get_cvar_num("text_chat") == 1)
  {
    static 
            msg1[128],
            msg2[128],
            msg3[128],
            msg4[128],
            msg5[128]
    
    get_cvar_string("text_chat_1", msg1, 127)
    get_cvar_string("text_chat_2", msg2, 127)
    get_cvar_string("text_chat_3", msg3, 127)
    get_cvar_string("text_chat_4", msg4, 127)
    get_cvar_string("text_chat_5", msg5, 127)
    
    colorChat(0, CHATCOLOR_YELLOW, "%s", msg1)
    colorChat(0, CHATCOLOR_RED, "%s", msg2)
    colorChat(0, CHATCOLOR_GREEN, "%s", msg3)
    colorChat(0, CHATCOLOR_GREY, "%s", msg4)
    colorChat(0, CHATCOLOR_BLUE, "%s", msg5)
  }
}

colorChat(id, ChatColor:color, const msg[], {Float,Sql,Result,_}:...)
{
	new team, index, MSG_Type
	new bool:teamChanged = false
	new message[192]
	
	switch(color)
	{
		case CHATCOLOR_YELLOW:
		{
			message[0] = 0x01;
		}
		case CHATCOLOR_GREEN:
		{
			message[0] = 0x04;
		}
		default:
		{
			message[0] = 0x03;
		}
	}
	
	vformat(message[1], 190, msg, 4);
	
	if (id == 0)
	{
		index = findAnyPlayer();
		MSG_Type = MSG_ALL;
	}
	else
	{
		index = id;
		MSG_Type = MSG_ONE;
	}
	if (index != 0)
	{
		team = get_user_team(index);	
		if (color == CHATCOLOR_RED && team != 1)
		{
			messageTeamInfo(index, MSG_Type, g_TeamName[1])
			teamChanged = true
		}
		else
		if (color == CHATCOLOR_BLUE && team != 2)
		{
			messageTeamInfo(index, MSG_Type, g_TeamName[2])
			teamChanged = true
		}
		else
		if (color == CHATCOLOR_GREY && team != 0)
		{
			messageTeamInfo(index, MSG_Type, g_TeamName[0])
			teamChanged = true
		}
		messageSayText(index, MSG_Type, message);
		if (teamChanged)
		{
			messageTeamInfo(index, MSG_Type, g_TeamName[team]);
		}
	}
}

messageSayText(id, type, message[])
{
	message_begin(type, g_msgSayText, _, id)
	write_byte(id)		
	write_string(message)
	message_end()
}
	
messageTeamInfo(id, type, team[])
{
	message_begin(type, g_msgTeamInfo, _, id)
	write_byte(id)
	write_string(team)
	message_end()
}
	
findAnyPlayer()
{
	new players[32], inum
	
	get_players(players, inum)
	
	for (new a = 0; a < inum; ++a)
	{
		if(is_user_connected(players[a]))
		{
			return players[a]
		}
	}
	return 0
}
