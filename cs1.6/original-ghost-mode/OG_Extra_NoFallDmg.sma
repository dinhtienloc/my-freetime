#include <amxmodx>
#include <engine>
#include <OriginalGhost>

#define FALL_VELOCITY 350.0

new g_FallBool[33]
new g_Extra_NoFall
public plugin_init() {
	register_plugin("[OG]Extra: No Fall Dmg", "0.2", "v3x");
	g_Extra_NoFall = og_equip_register("Roi khong mat mau", EQ_T, 0, 5000)
}

public og_equip_bought(id, itemid) {
	if(itemid == g_Extra_NoFall) g_FallBool[id] = true;
}

public client_putinserver(id) {
	g_FallBool[id] = false;
}

public client_disconnect(id) {
	g_FallBool[id] = false;
}

public plugin_natives() {
	register_native("og_get_extra_falldmg", "Get_Extra_FallDmg", 1);
}

public Get_Extra_FallDmg(id) {
	return g_FallBool[id]
}

public client_PostThink(id) {
	if(g_FallBool[id] && is_user_alive(id) && is_user_connected(id)) 
		entity_set_int(id, EV_INT_watertype, -3);
}

