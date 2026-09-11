//-----------
// [ZL] NoRoundEnd
//
// NPC Forum
// http://zombielite.Ru/
//--
// By Alexander.3
// http://Alexander3.Ru/

#include < amxmodx >

#define NAME 			"[ZL] NoRoundEnd"
#define VERSION			"1.0"
#define AUTHOR			"Alexander.3"

native zl_boss_map()

public plugin_init() {
	register_plugin(NAME, VERSION, AUTHOR)
	
	if (zl_boss_map()) {
		set_cvar_num("sv_noroundend", 1)
	} else {
		set_cvar_num("sv_noroundend", 0)
		pause("ad")
	}
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1049\\ f0\\ fs16 \n\\ par }
*/
