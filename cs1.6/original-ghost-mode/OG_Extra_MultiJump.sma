#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <OriginalGhost>

new isEnabled[33]
new g_isUpdate[33]
new bool:doMultiJump[33]
new Float:jumpVeloc[33][3]
new newButton[33]
new numMultiJumps[33]
new wallteam
new g_MaxPlayers
new g_Equip_MultiJump

#define multijumpN_num 1
#define multijumpU_num 2

#define walljump_str 300.0
//====================================================================================================
static const TITLE[] = "Wall Jump"
static const VERSION[] = "0.6"
static const AUTHOR[] = "OneEyed"
//====================================================================================================

public plugin_init()
{
	register_plugin(TITLE,VERSION,AUTHOR)
	
	register_event("HLTV", "Event_NewRound", "a", "1=0", "2=0")
	
	register_cvar("walljump_str","300.0")
	register_cvar("walljump_team", "1")
	register_cvar("multijumpN_num", "1");
	register_cvar("multijumpU_num", "2");
	
	register_touch("player", "worldspawn", "Touch_World")
	register_touch("player", "func_wall", "Touch_World")
	register_touch("player", "func_breakable", "Touch_World")
	
	g_MaxPlayers = get_maxplayers();
	
	g_Equip_MultiJump = og_equip_register("Multi Jump", EQ_T, 0, 15000)
} 

public plugin_natives() {
	register_native("og_have_Njump", "_og_have_Njump", 1);
	register_native("og_have_Ujump", "_og_have_Ujump", 1);
}

public bool:_og_have_Njump(id) {
	return isEnabled[id] ? true : false;
}

public bool:_og_have_Ujump(id) {
	if(!isEnabled[id]) return false;
	else {
		return g_isUpdate[id] ? true : false;
	}
	return false;
}

public og_equip_bought(id, ItemID) {
	if(ItemID == g_Equip_MultiJump)
		if(isEnabled[id]) g_isUpdate[id] = true;
		else isEnabled[id] = true;	
}

public Event_NewRound() {
	for(new id = 1; id <= g_MaxPlayers; id++) {
		if(g_isUpdate[id]) g_isUpdate[id] = false;
	}
}
public client_PreThink(id)
{
	if(isEnabled[id]) {
		wallteam = get_cvar_num("walljump_team")
		new team = get_user_team(id)
			
		if(!is_user_alive(id) || (wallteam && wallteam != team)) return PLUGIN_HANDLED;
			
		newButton[id] = get_user_button(id)
		new oldButton = get_user_oldbutton(id)
		new flags = get_entity_flags(id)
		new MaxCountJump = g_isUpdate[id] ? multijumpU_num : multijumpN_num;
		if((newButton[id] & IN_JUMP) && !(flags & FL_ONGROUND) && !(oldButton & IN_JUMP)) {
			if(numMultiJumps[id] < MaxCountJump) 
			{
				doMultiJump[id] = true
				numMultiJumps[id]++
				return PLUGIN_CONTINUE
			}
		}
		if((newButton[id] & IN_JUMP) && (flags & FL_ONGROUND)) 
		{
			numMultiJumps[id] = 0
			return PLUGIN_CONTINUE
		}
	}
	
	return PLUGIN_CONTINUE;
}

public client_putinserver(id) {
	isEnabled[id] = false;
	g_isUpdate[id] = false;
}

public client_disconnect(id) {
	isEnabled[id] = false;
	g_isUpdate[id] = false;
}

public client_PostThink(id) 
{
	if(isEnabled[id]) {
		if(is_user_alive(id)) {
			if(doMultiJump[id]) {
				entity_get_vector(id,EV_VEC_velocity,jumpVeloc[id])
				jumpVeloc[id][2] = random_float(265.0,285.0)
				entity_set_vector(id,EV_VEC_velocity,jumpVeloc[id])
				doMultiJump[id] = false;	
			}
		}
	}
	return PLUGIN_CONTINUE
}

public Touch_World(id, world) 
{
	if(!is_user_alive(id) || isEnabled[id]) return PLUGIN_HANDLED
	
	if( ~get_entity_flags(id) & FL_ONGROUND) {
		numMultiJumps[id] = 0
	}
	
	return PLUGIN_CONTINUE;
}

/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
