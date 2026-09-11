#include <amxmodx>

#include <zombieplague>
#include <fun>

#define PLUGIN   "[EI] Stealth"
#define VERSION  "1.0"
#define AUTHOR   "Weltgericht"

#define STEALTH  20.0 /* Time to be invinsivible */
#define COST 8  /* Stealth cost ( In AmmoPacks ) */

new g_item_stealth

new const start_stealth[]  = { "zombie_plague/stealth/start.wav" }
new const finish_stealth[] = { "zombie_plague/stealth/finish.wav" }

public plugin_init()
{
      register_plugin(PLUGIN,VERSION,AUTHOR)

      g_item_stealth = zp_register_extra_item("Stealth \r[20 sec.]", COST, ZP_TEAM_ZOMBIE)
    
}

public plugin_precache()
{
	precache_sound(start_stealth)
	precache_sound(finish_stealth)
}

public zp_extra_item_selected(Player, itemid)
{
	if  (itemid == g_item_stealth)
	{
		/* Make Invisible */
		set_user_rendering ( Player, kRenderFxNone, 0, 0, 0, kRenderTransAlpha, 0 ) 

		/* Inform Player */
		print(Player, "^x04[ZP]^x01 You are invinsivible now!")

		/* Play sound start */
                emit_sound(Player, CHAN_AUTO, start_stealth, 1.0, ATTN_NORM, 0, PITCH_NORM)

		/* TASK to remove in %d sec. */
		set_task(STEALTH , "remove_stealth", Player)

		/* ScreenFade ON */
		message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("ScreenFade"), _, Player)
		write_short(1<<12)
		write_short(1<<12)
		write_short(0x0004) /* "4" - ForEver (No Panic! We will remove it) */
		write_byte(190)
		write_byte(190)
		write_byte(190)
		write_byte(50)
		message_end()
	}
}

public remove_stealth(Player)
{
	/* Remove Invisiblity */
	set_user_rendering(Player)

	/* Inform Player */
	print(Player, "^x04[ZP]^x01 You are not invinsivible any more!")

	/* Play Sound Finish */
	emit_sound(Player, CHAN_AUTO, finish_stealth, 1.0, ATTN_NORM, 0, PITCH_NORM)

	/* OFF ScreenFade */
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("ScreenFade"), _, Player)
	write_short(1<<12)
	write_short(1<<12)
	write_short(0x0000)
	write_byte(190)
	write_byte(190)
	write_byte(190)
	write_byte(0)
	message_end()
}

stock print(const id, const input[], any:...)
{
	
	new iCount = 1, iPlayers[32]
	
	static szMsg[191]
	vformat(szMsg, charsmax(szMsg), input, 3)
	
	replace_all(szMsg, 190, "^x04", "^4") // green txt
	replace_all(szMsg, 190, "^x01", "^1") // orange txt
	replace_all(szMsg, 190, "^x03", "^3") // team txt
	replace_all(szMsg, 190, "^x00", "^0") // team txt
	
	if(id) iPlayers[0] = id
	else get_players(iPlayers, iCount, "ch")
		
	for (new i = 0; i < iCount; i++)
	{
		if (is_user_connected(iPlayers[i]))
		{
			message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, iPlayers[i])
			write_byte(iPlayers[i])
			write_string(szMsg)
			message_end()
		}
	}
}