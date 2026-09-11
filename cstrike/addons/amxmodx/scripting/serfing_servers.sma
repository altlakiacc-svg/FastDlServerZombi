#include <amxmodx>
#include <amxmisc>
#include <colorchat>

#define PLUGIN "Serfing servers"
#define VERSION "1.1"
#define AUTHOR "Svoloch"
new const Version[] ="1.1 info izlapzla.ru"

new Array:g_name
new Array:g_ip
new Array:g_port

new g_follow_ip[72]
new g_follow_port[72]

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_clcmd("say /server","menu_server")
	register_clcmd("say_team /server","menu_server")
	register_clcmd("say_team /follow","cmd_follow")
	register_clcmd("say /follow","cmd_follow")
	register_concmd("add_server", "cmd_server_add", ADMIN_RCON)

	g_name = ArrayCreate(32, 1)
	g_ip = ArrayCreate(32, 1)
	g_port = ArrayCreate(32, 1)
	register_cvar("Serfing servers", Version, FCVAR_SERVER|FCVAR_SPONLY)
}
public cmd_server_add(id, level, cid){
	
	if(!cmd_access(id, level, cid, 3))
		return PLUGIN_HANDLED
		
	new arg_name[32],arg_ip[32],arg_port[32]
	
	read_argv(1,arg_name,31)
	read_argv(2,arg_ip,31)
	read_argv(3,arg_port,31)
	
	ArrayPushString(g_name,arg_name)
	ArrayPushString(g_ip,arg_ip)
	ArrayPushString(g_port,arg_port)
	
	return PLUGIN_HANDLED
}
public menu_server(id) 
{   
	new menu=menu_create("\rSelect server:","menu_abort")   
	new size,name[32],i,server_name[32]
	size = ArraySize(g_name)
	
	for(i = 0; i < size ; i++){
		ArrayGetString(g_name, i, name, 31)
		format(server_name,72,"\w%s", name)
		menu_additem(menu, server_name)   
	}
	
	if(size == 0){
		client_print(id,print_chat,"Sorry, there are no servers")
	}
	
	menu_setprop(menu,MPROP_EXIT,1)  
	menu_display(id,menu,0)   
} 
public menu_abort(id,menu,item) 
{   
	if (item == MENU_EXIT){
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}
	new ip[32],name_server[32],name[32],port[32]
	get_user_name(id,name,31)
	
	ArrayGetString(g_ip, item, g_follow_ip, 31)
	ArrayGetString(g_port, item, g_follow_port, 31)
	
	ArrayGetString(g_port, item, port, 31)
	ArrayGetString(g_ip, item, ip, 31)
	ArrayGetString(g_name, item, name_server, 31)
		
	client_cmd(id, "Connect %s:%s", ip,port)
	ColorChat(0,RED,"%s ^4has left on the server ^3%s",name, name_server)
		
	menu_destroy(menu)
	return PLUGIN_HANDLED
}
public cmd_follow(id){
	
	client_cmd(id, "Connect %s:%s", g_follow_ip,g_follow_port)
		
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1049\\ f0\\ fs16 \n\\ par }
*/
