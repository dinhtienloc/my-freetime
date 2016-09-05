#include <amxmodx>
#include <amxmisc>
#include <fakemeta_util>
#include <hamsandwich>
#include <cstrike>
#include <OriginalGhost>

#define PLUGIN "[GF] Addon: Weapon"
#define VERSION "1.0"
#define AUTHOR "Dias Pendragon/dtloc"

#define LANG_FILE "OriginalGhost.txt"
#define GAME_LANG LANG_SERVER

#define VIP_FLAG ADMIN_LEVEL_H

#define MAX_WEAPON 100
#define MAX_EQUIP 50
#define MAX_TYPE 3
#define MAX_FORWARD 5
enum
{
WPN_BOUGHT = 0,
WPN_REMOVE,
WPN_ADDAMMO,
EQ_BOUGHT,
EQ_REMOVE
}

// MACROS
#define Get_BitVar(%1,%2) (%1 & (1 << (%2 & 31)))
#define Set_BitVar(%1,%2) %1 |= (1 << (%2 & 31))
#define UnSet_BitVar(%1,%2) %1 &= ~(1 << (%2 & 31))

// Const
const PRIMARY_WEAPONS_BIT_SUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)
const SECONDARY_WEAPONS_BIT_SUM = (1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_FIVESEVEN)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_DEAGLE)
const NADE_WEAPONS_BIT_SUM = ((1<<CSW_HEGRENADE)|(1<<CSW_SMOKEGRENADE)|(1<<CSW_FLASHBANG))

new g_Forwards[MAX_FORWARD], GameName[32], g_GotWeapon
new g_WeaponList[4][MAX_WEAPON], g_WeaponListCount[4]
new g_EquipList[3][MAX_EQUIP], g_EquipListCount[3], g_TotalEquipCount, g_EquipCount[3], g_isUseEquip[33][MAX_EQUIP]
new g_WeaponCount[4], g_PreWeapon[33][4], g_FirstWeapon[4], g_TotalWeaponCount, g_UnlockedWeapon[33][MAX_WEAPON]
new Array:ArWeaponName, Array:ArReqWeaponName, Array:ArWeaponType, Array:ArWeaponBasedOn, Array:ArWeaponCost, Array:ArWeaponPoint
new Array:ArEquipName, Array:ArEquipType, Array:ArEquipPoint, Array:ArEquipCost
new g_MaxPlayers, g_fwResult, g_MsgSayText

new testArray[MAX_WEAPON][32]
new bool:FuckingCheck = false;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_dictionary(LANG_FILE)
	
	g_Forwards[WPN_BOUGHT] = CreateMultiForward("og_weapon_bought", ET_IGNORE, FP_CELL, FP_CELL)
	g_Forwards[WPN_REMOVE] = CreateMultiForward("og_weapon_remove", ET_IGNORE, FP_CELL, FP_CELL)
	g_Forwards[WPN_ADDAMMO] = CreateMultiForward("og_weapon_addammo", ET_IGNORE, FP_CELL, FP_CELL)
	g_Forwards[EQ_BOUGHT] = CreateMultiForward("og_equip_bought", ET_IGNORE, FP_CELL, FP_CELL)
	g_Forwards[EQ_REMOVE] = CreateMultiForward("og_equip_remove", ET_IGNORE, FP_CELL, FP_CELL);
	
	g_MsgSayText = get_user_msgid("SayText")
	g_MaxPlayers = get_maxplayers()
	
	register_clcmd("say /menu", "Show_ExtraMenu");
	register_clcmd("chooseteam", "Show_ExtraMenu", 0);
	
	register_clcmd("og_equipment", "Show_MainEquipMenu")
	RegisterHam(  Ham_Spawn,  "player",  "Ham_PlayerSpawnPost",  true  );
}
		
public plugin_precache()
{
	// Weapons Arrays
	ArWeaponName = ArrayCreate(32, 1)
	ArReqWeaponName = ArrayCreate(32, 1)
	ArWeaponType = ArrayCreate(1, 1)
	ArWeaponBasedOn = ArrayCreate(1, 1)
	ArWeaponPoint = ArrayCreate(1, 1)
	ArWeaponCost = ArrayCreate(1, 1)
	
	// Equipments Arrays
	ArEquipName = ArrayCreate(32, 1)
	ArEquipType = ArrayCreate(1, 1)
	ArEquipPoint = ArrayCreate(1, 1)
	ArEquipCost = ArrayCreate(1, 1);
	
	// Initialize
	g_FirstWeapon[WPN_PRIMARY] = -1
	g_FirstWeapon[WPN_SECONDARY] = -1
	g_FirstWeapon[WPN_MELEE] = -1
}

public plugin_cfg()
{
	static WpnType
	for(new i = 0; i < g_TotalWeaponCount; i++)
	{
		WpnType = ArrayGetCell(ArWeaponType, i)
		
		if(g_FirstWeapon[WpnType] == -1)
			g_FirstWeapon[WpnType] = i
		}
		
		// Initialize 2
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		g_PreWeapon[i][WPN_PRIMARY] = g_FirstWeapon[WPN_PRIMARY]
		g_PreWeapon[i][WPN_SECONDARY] = g_FirstWeapon[WPN_SECONDARY]
		g_PreWeapon[i][WPN_MELEE] = g_FirstWeapon[WPN_MELEE]
	}
		
	// Handle WeaponList
	g_WeaponListCount[WPN_PRIMARY] = 0
	g_WeaponListCount[WPN_SECONDARY] = 0
	g_WeaponListCount[WPN_MELEE] = 0
	
	// Handle EquipList
	g_EquipListCount[EQ_CT] = 0;
	g_EquipListCount[EQ_T] = 0;
		
	static Type
	
	// Weapons
	for(new i = 0; i < g_TotalWeaponCount; i++)
	{
		Type = ArrayGetCell(ArWeaponType, i)
			
		if(Type == WPN_PRIMARY)
		{
			g_WeaponList[WPN_PRIMARY][g_WeaponListCount[WPN_PRIMARY]] = i
			g_WeaponListCount[WPN_PRIMARY]++
		} else if(Type == WPN_SECONDARY) {
			g_WeaponList[WPN_SECONDARY][g_WeaponListCount[WPN_SECONDARY]] = i
			g_WeaponListCount[WPN_SECONDARY]++
		} else if(Type == WPN_MELEE) {
			g_WeaponList[WPN_MELEE][g_WeaponListCount[WPN_MELEE]] = i
			g_WeaponListCount[WPN_MELEE]++
		}
	}
		
	// Equipment
	for(new i = 0; i < g_TotalEquipCount; i++)
	{
		Type = ArrayGetCell(ArEquipType, i);
			
		if(Type == EQ_CT)
		{
			g_EquipList[EQ_CT][g_EquipListCount[EQ_CT]] = i;
			g_EquipListCount[EQ_CT]++;
		}
		else if(Type == EQ_T)
		{
			g_EquipList[EQ_T][g_EquipListCount[EQ_T]] = i;
			g_EquipListCount[EQ_T]++;
		}
	}
	// Get GameName
	formatex(GameName, sizeof(GameName), "%L", GAME_LANG, "GAME_NAME")
}

public plugin_natives()
{
	register_library("OriginalGhost");
	register_native("og_weapon_register", "Native_RegisterWeapon", 1)
	register_native("og_weapon_get_cswid", "Native_Get_CSWID", 1)
	register_native("og_equip_register", "Native_RegisterEquipment", 1);
}

public Native_RegisterWeapon(const Name[], const Req[], Type, BasedOn, Point, Cost)
{
	param_convert(1)
	param_convert(2);
	
	ArrayPushString(ArWeaponName, Name)
	ArrayPushString(ArReqWeaponName, Req);
	//formatex(testArray[g_TotalWeaponCount], charsmax(testArray[]), "%s", Req);
	ArrayPushCell(ArWeaponType, Type)
	ArrayPushCell(ArWeaponBasedOn, BasedOn)
	ArrayPushCell(ArWeaponPoint, Point)
	ArrayPushCell(ArWeaponCost, Cost)
	
	g_TotalWeaponCount++
	g_WeaponCount[Type]++
	
	return g_TotalWeaponCount - 1
}

public Native_Get_CSWID(id, ItemID)
{
	if(ItemID >= g_TotalWeaponCount)
		return 0
	
	return ArrayGetCell(ArWeaponBasedOn, ItemID)
}

public Native_RegisterEquipment(const Name[], Type, Point, Cost) {
	param_convert(1);
	
	ArrayPushString(ArEquipName, Name);
	ArrayPushCell(ArEquipType, Type)
	ArrayPushCell(ArEquipPoint, Point)
	ArrayPushCell(ArEquipCost, Cost)
	
	g_TotalEquipCount++;
	g_EquipCount[Type]++;
	
	return g_TotalEquipCount - 1;
}

public client_putinserver(id)
{
	Reset_PlayerWeapon(id, 1)
}

public client_disconnect(id)
{
	Reset_PlayerWeapon(id, 1)
}

public Ham_PlayerSpawnPost(id)
{
	Reset_PlayerWeapon(id, 0)
	Player_Equipment(id)
	
	if(get_user_team(id) == 1) {
		if(g_isUseEquip[id][FindEquipIdByName("Tang toc do")])
			g_isUseEquip[id][FindEquipIdByName("Tang toc do")] = 0;
		
		if(g_isUseEquip[id][FindEquipIdByName("Hoi mau")])
			g_isUseEquip[id][FindEquipIdByName("Hoi mau")] = 0;
			
		if(g_isUseEquip[id][FindEquipIdByName("Nhay cao")])
			g_isUseEquip[id][FindEquipIdByName("Nhay cao")] = 0;
	}
}

public Reset_PlayerWeapon(id, NewPlayer)
{
	if(NewPlayer)
	{
		g_PreWeapon[id][WPN_PRIMARY] = -1
		g_PreWeapon[id][WPN_SECONDARY] = -1
		g_PreWeapon[id][WPN_MELEE] = -1
		
		for(new i = 0; i < MAX_WEAPON; i++)
			g_UnlockedWeapon[id][i] = 0
		
		for(new i = 0; i < MAX_EQUIP; i++)
			g_isUseEquip[id][i] = 0
	}
	
	UnSet_BitVar(g_GotWeapon, id)
}

public Player_Equipment(id)
{
	if(!is_user_bot(id)) Show_MainEquipMenu(id)
	else set_task(random_float(0.25, 1.0), "Bot_RandomWeapon", id)
}

public Show_MainEquipMenu(id)
{
	if(Get_BitVar(g_GotWeapon, id))
		return
	
	static LangText[64]; formatex(LangText, sizeof(LangText), "%L", GAME_LANG, "WPN_MENU_NAME")
	static Menu; Menu = menu_create(LangText, "MenuHandle_MainEquip")
	
	static WeaponName[32]
	if(is_user_alive(id) && cs_get_user_team(id) == CS_TEAM_CT) {
		if(g_PreWeapon[id][WPN_PRIMARY] != -1)
		{
			ArrayGetString(ArWeaponName, g_PreWeapon[id][WPN_PRIMARY], WeaponName, sizeof(WeaponName))
			formatex(LangText, sizeof(LangText), "%L [\y%s\w]", GAME_LANG, "WPN_MENU_PRIMARY", WeaponName)
			} else {
			formatex(LangText, sizeof(LangText), "%L \d[ ]\w", GAME_LANG, "WPN_MENU_PRIMARY")
		}
		menu_additem(Menu, LangText, "wpn_pri")
		
		if(g_PreWeapon[id][WPN_SECONDARY] != -1)
		{
			ArrayGetString(ArWeaponName, g_PreWeapon[id][WPN_SECONDARY], WeaponName, sizeof(WeaponName))
			formatex(LangText, sizeof(LangText), "%L [\y%s\w]^n", GAME_LANG, "WPN_MENU_SECONDARY", WeaponName)
			} else {
			formatex(LangText, sizeof(LangText), "%L \d[ ]\w^n", GAME_LANG, "WPN_MENU_SECONDARY")
		}
		menu_additem(Menu, LangText, "wpn_sec")
		
		formatex(LangText, sizeof(LangText), "\r%L", GAME_LANG, "WPN_MENU_TAKEWPN")
		menu_additem(Menu, LangText, "get_wpn")
		
		menu_setprop(Menu, MPROP_EXIT, MEXIT_ALL)
		menu_display(id, Menu, 0)
	}
	
	if(is_user_alive(id) && cs_get_user_team(id) == CS_TEAM_T) {
		if(g_PreWeapon[id][WPN_MELEE] != -1)
		{
			ArrayGetString(ArWeaponName, g_PreWeapon[id][WPN_MELEE], WeaponName, sizeof(WeaponName))
			formatex(LangText, sizeof(LangText), "%L [\y%s\w]^n", GAME_LANG, "WPN_MENU_MELEE", WeaponName)
			} else {
			formatex(LangText, sizeof(LangText), "%L \d[ ]\w^n", GAME_LANG, "WPN_MENU_MELEE")
		}
		menu_additem(Menu, LangText, "wpn_melee")
		
		formatex(LangText, sizeof(LangText), "\r%L", GAME_LANG, "WPN_MENU_TAKEWPN")
		menu_additem(Menu, LangText, "get_wpn")
		
		menu_setprop(Menu, MPROP_EXIT, MEXIT_ALL)
		menu_display(id, Menu, 0)
	}
}

public Show_ExtraMenu(id) {
	new Text[32]
	new ExtraMenu
	
	if (cs_get_user_team(id) == CS_TEAM_UNASSIGNED || cs_get_user_team(id) == CS_TEAM_SPECTATOR || FuckingCheck){
		FuckingCheck = false;
		return PLUGIN_CONTINUE
	}
	else {
		if(!Get_BitVar(g_GotWeapon, id)) {
			Show_MainEquipMenu(id)
			return PLUGIN_HANDLED
		}
			
		formatex(Text, charsmax(Text), "%L", GAME_LANG, "EQ_MENU");
		ExtraMenu = menu_create(Text, "MenuHandle_Extra");
		
		formatex(Text, charsmax(Text), "%L", GAME_LANG, "EQ_UNLOCK_MENU");
		menu_additem(ExtraMenu, Text, "eq_unlock");
		
		menu_additem(ExtraMenu, "Doi ben", "change_team");
		
		menu_setprop(ExtraMenu, MPROP_EXIT, MEXIT_ALL)
		menu_display(id, ExtraMenu, 0)
	}
	
	return PLUGIN_HANDLED
}

public Bot_RandomWeapon(id)
{
	g_PreWeapon[id][WPN_PRIMARY] = g_WeaponList[WPN_PRIMARY][random(g_WeaponListCount[WPN_PRIMARY])]
	g_PreWeapon[id][WPN_SECONDARY] = g_WeaponList[WPN_SECONDARY][random(g_WeaponListCount[WPN_SECONDARY])]
	g_PreWeapon[id][WPN_MELEE] = g_WeaponList[WPN_MELEE][random(g_WeaponListCount[WPN_MELEE])]
	
	Equip_Weapon(id)
}

public MenuHandle_MainEquip(id, Menu, Item)
{
	if(Item == MENU_EXIT)
	{
		menu_destroy(Menu)
		return PLUGIN_HANDLED
	}
	if(!is_user_alive(id))
	{
		menu_destroy(Menu)
		return PLUGIN_HANDLED
	}
	
	new Name[64], Data[16], ItemAccess, ItemCallback
	menu_item_getinfo(Menu, Item, ItemAccess, Data, charsmax(Data), Name, charsmax(Name), ItemCallback)
	
	if(equal(Data, "wpn_pri"))
	{
		if(g_WeaponCount[WPN_PRIMARY]) Show_WpnSubMenu(id, WPN_PRIMARY, 0)
		else Show_MainEquipMenu(id)
		} else if(equal(Data, "wpn_sec")) {
		if(g_WeaponCount[WPN_SECONDARY]) Show_WpnSubMenu(id, WPN_SECONDARY, 0)
		else Show_MainEquipMenu(id)
		} else if(equal(Data, "wpn_melee")) {
		if(g_WeaponCount[WPN_MELEE]) Show_WpnSubMenu(id, WPN_MELEE, 0)
		else Show_MainEquipMenu(id)
		} else if(equal(Data, "get_wpn")) {
		Equip_Weapon(id)
	}
	
	menu_destroy(Menu)
	return PLUGIN_CONTINUE
}

public MenuHandle_Extra(id, Menu, Item) {
	if(Item == MENU_EXIT)
	{
		menu_destroy(Menu)
		return PLUGIN_HANDLED
	}
	if(!is_user_alive(id))
	{
		menu_destroy(Menu)
		return PLUGIN_HANDLED
	}
	
	new Name[64], Data[16], ItemAccess, ItemCallback
	menu_item_getinfo(Menu, Item, ItemAccess, Data, charsmax(Data), Name, charsmax(Name), ItemCallback)
	
	if(equal(Data, "eq_unlock")){
		if(cs_get_user_team(id) == CS_TEAM_CT)
			Show_EquipMenu(id, EQ_CT, 0)
		else if(cs_get_user_team(id) == CS_TEAM_T)
			Show_EquipMenu(id, EQ_T, 0)
	}
	else if(equal(Data, "change_team")) {
		FuckingCheck = true;
		client_cmd(id, "chooseteam");
	}
	
	menu_destroy(Menu)
	return PLUGIN_CONTINUE
}

public Show_WpnSubMenu(id, WpnType, Page)
{
	static WeaponTypeN[16], MenuName[32]
	
	if(WpnType == WPN_PRIMARY) formatex(WeaponTypeN, sizeof(WeaponTypeN), "%L", GAME_LANG, "WPN_MENU_PRIMARY")
	else if(WpnType == WPN_SECONDARY) formatex(WeaponTypeN, sizeof(WeaponTypeN), "%L", GAME_LANG, "WPN_MENU_SECONDARY")
		else if(WpnType == WPN_MELEE) formatex(WeaponTypeN, sizeof(WeaponTypeN), "%L", GAME_LANG, "WPN_MENU_MELEE")
		
	formatex(MenuName, sizeof(MenuName), "%L [%s]", GAME_LANG, "WPN_MENU_SELECT", WeaponTypeN)
	new Menu = menu_create(MenuName, "MenuHandle_WpnSubMenu")
	
	static WeaponType, WeaponName[32], MenuItem[64], ItemID[4]
	static WeaponPrice, Money; Money = cs_get_user_money(id)
	static PointCost
	new PlayerPoint = (cs_get_user_team(id) == CS_TEAM_CT) ? og_get_user_HP(id) : og_get_user_GP(id);
	
	for(new i = 0; i < g_TotalWeaponCount; i++)
	{
		WeaponType = ArrayGetCell(ArWeaponType, i)
		if(WpnType != WeaponType)
			continue
		
		ArrayGetString(ArWeaponName, i, WeaponName, sizeof(WeaponName))
		WeaponPrice = ArrayGetCell(ArWeaponCost, i)
		PointCost = ArrayGetCell(ArWeaponPoint, i)
		
		if(WeaponPrice > 0 || PointCost > 0)
		{	
			if(g_UnlockedWeapon[id][i])
			{
				formatex(MenuItem, sizeof(MenuItem), "%s",WeaponName)
			}
			else {
				if(WpnType == WPN_MELEE) {
					if(Money >= WeaponPrice && PlayerPoint >= PointCost) formatex(MenuItem, sizeof(MenuItem), "%s \r[\y%i GP + \r$\y%i\r]\w", WeaponName, PointCost, WeaponPrice)
					else formatex(MenuItem, sizeof(MenuItem), "\d%s \r[\y%i GP + \r$\y%i\r]\w", WeaponName, PointCost, WeaponPrice)
				}
				else {
					if(Money >= WeaponPrice && PlayerPoint >= PointCost) formatex(MenuItem, sizeof(MenuItem), "%s \r[\y%i HP + \r$\y%i\r]\w", WeaponName, PointCost, WeaponPrice)
					else formatex(MenuItem, sizeof(MenuItem), "\d%s \r[\y%i HP + \r$\y%i\r]\w", WeaponName, PointCost, WeaponPrice)
				}
			}	
		} 
		else {
			formatex(MenuItem, sizeof(MenuItem), "%s", WeaponName)
		}
		
		num_to_str(i, ItemID, sizeof(ItemID))
		menu_additem(Menu, MenuItem, ItemID)
	}
	
	menu_setprop(Menu, MPROP_EXIT, MEXIT_ALL)
	menu_display(id, Menu, Page)
}

public Show_EquipMenu(id, EqType, Page) {
	static MenuName[32]
	
	formatex(MenuName, sizeof(MenuName), "%L", GAME_LANG, "EQ_UNLOCK_MENU")
	
	new Menu = menu_create(MenuName, "MenuHandle_Equip")
	
	static EquipType, EquipName[32], MenuItem[64], ItemID[4]
	static EquipPrice, EquipPoint, Money; Money = cs_get_user_money(id)
	static MultiCost;
	
	
	for(new i = 0; i < g_TotalEquipCount; i++)
	{
		EquipType = ArrayGetCell(ArEquipType, i)
		if(EqType != EquipType)
			continue
		
		ArrayGetString(ArEquipName, i, EquipName, sizeof(EquipName))
		EquipPrice = ArrayGetCell(ArEquipCost, i)
		EquipPoint = ArrayGetCell(ArEquipPoint, i)
		
		if(EquipPrice > 0 || EquipPoint > 0)
		{
			
			//* --------------- 25Hp Extra Modified -------------- *//
			if(equal(EquipName, "Tang 25HP")) {
				new UsedChance = og_get_sphealth_chance(id);
				
				if(UsedChance == 0)
					formatex(MenuItem, sizeof(MenuItem), "\d%s \r(%L)", EquipName, GAME_LANG, "EQ_UPDATED")
				else if(UsedChance == 2) {
					//client_print(0, print_chat, "asdasd");
					MultiCost = EquipPrice;
					if(Money >= MultiCost)
						formatex(MenuItem, sizeof(MenuItem), "%s (%i/2)\r[$\y%i\r]\w", EquipName, UsedChance, MultiCost)
					else formatex(MenuItem, sizeof(MenuItem), "\d%s \r[$\y%i\r]\w", EquipName, MultiCost)
				}
				else {
					//client_print(0, print_chat, "a343434sd");
					if(Money >= MultiCost * 2) {
						MultiCost *= 2;
						formatex(MenuItem, sizeof(MenuItem), "%s (%i/5)\r[$\y%i\r]\w", EquipName, UsedChance, MultiCost)
					}
					else formatex(MenuItem, sizeof(MenuItem), "\d%s (%i/5)\r[$\y%i\r]\w", EquipName, UsedChance, MultiCost * 2)
				}
			}
			//* ---------------   End of 25Hp Extra Modified   --------------- *//
	
			//* --------------- MultiJump Extra Modified -------------- *//
			else if(equal(EquipName, "Multi Jump")) {
				if(og_have_Ujump(id)) {
					formatex(MenuItem, sizeof(MenuItem), "\d%s \r(%L)", EquipName, GAME_LANG, "EQ_UPDATED")
				}
				else {
					if(!og_have_Njump(id)) {
						if(Money >= EquipPrice) formatex(MenuItem, sizeof(MenuItem), "%s \r[$\y%i\r]\w", EquipName, EquipPrice)
						else formatex(MenuItem, sizeof(MenuItem), "\d%s \r[$\y%i\r]\w", EquipName, EquipPrice)
					}
					else {
						if(Money >= EquipPrice) formatex(MenuItem, sizeof(MenuItem), "%s \y- Them mot lan nhay(1 round) \r[$\y%i\r]\w", EquipName, EquipPrice)
						else formatex(MenuItem, sizeof(MenuItem), "\d%s \y- Them mot lan nhay(1 round) \r[$\y%i\r]\w", EquipName, EquipPrice)
					}
						
				}
			}
			//* -----------------   End of MultiJump Extra Modified   ----------------- *//
			else {
				
				if(g_isUseEquip[id][i]) {
					formatex(MenuItem, sizeof(MenuItem), "\d%s \r(%L)", EquipName, GAME_LANG, "EQ_UPDATED")
				}
				else {
					if(Money >= EquipPrice) formatex(MenuItem, sizeof(MenuItem), "%s \r[$\y%i\r]\w", EquipName, EquipPrice)
					else formatex(MenuItem, sizeof(MenuItem), "\d%s \r[$\y%i\r]\w", EquipName, EquipPrice)
				}
			}
		}
		else {
			formatex(MenuItem, sizeof(MenuItem), "%s", EquipName)
		}
		
		num_to_str(i, ItemID, sizeof(ItemID))
		menu_additem(Menu, MenuItem, ItemID)
	}
	
	menu_setprop(Menu, MPROP_EXIT, MEXIT_ALL)
	menu_display(id, Menu, Page)
}

public MenuHandle_Equip(id, Menu, Item) {
	if(Item == MENU_EXIT)
	{
		menu_destroy(Menu)
		return PLUGIN_HANDLED
	}
	if(!is_user_alive(id))
	{
		menu_destroy(Menu)
		return PLUGIN_HANDLED
	}
	
	new Name[64], Data[16], ItemAccess, ItemCallback
	menu_item_getinfo(Menu, Item, ItemAccess, Data, charsmax(Data), Name, charsmax(Name), ItemCallback)
	
	new ItemId = str_to_num(Data)
	new EquipPrice = ArrayGetCell(ArEquipCost, ItemId)
	new EquipPoint = ArrayGetCell(ArEquipPoint, ItemId)
	//client_print(0, print_chat, "%i", ItemId);
	new Money = cs_get_user_money(id)
	new EquipName[32]; ArrayGetString(ArEquipName, ItemId, EquipName, sizeof(EquipName))
	//client_print(0, print_chat, "%s", WeaponName)
	new OutputInfo[80]
	static MultiCost
	
	if(g_isUseEquip[id][ItemId]) {
		client_print(id, print_center, "%s da duoc mua. Khong the mua them.", EquipName);
	}
	else {
		//--------------- Choose 25 HP -----------------//
		if(equal(EquipName, "Tang 25HP")) {
			new UsedChance = og_get_sphealth_chance(id);
				
			if(UsedChance == 0) {
				g_isUseEquip[id][ItemId] = 1;
				return PLUGIN_HANDLED
			}
			else if(UsedChance == 2)
				MultiCost = EquipPrice / 2;
				
			if(Money >= MultiCost * 2) {// Unlock now
				MultiCost *= 2;
				ExecuteForward(g_Forwards[EQ_BOUGHT], g_fwResult, id, ItemId);
				formatex(OutputInfo, sizeof(OutputInfo), "!g[%s]!n %L", GameName, GAME_LANG, "EQ_NOTICE_BOUGHT", EquipName, EquipPoint, MultiCost)
				client_printc(id, OutputInfo)
					
				cs_set_user_money(id, Money - MultiCost);
			}
			else {
				formatex(OutputInfo, sizeof(OutputInfo), "!g[%s]!n %L", GameName, GAME_LANG, "EQ_NOTICE_NEEDMONEY", EquipPoint, MultiCost * 2, EquipName)
				client_printc(id, OutputInfo)
			}
		}
		//----------------- Done ----------------//
		
		//--------------- Choose MultiJump -----------------//
		else if(equal(EquipName, "Multi Jump")) {
			if(!og_have_Njump(id)) {
				if(Money >= EquipPrice) {
					ExecuteForward(g_Forwards[EQ_BOUGHT], g_fwResult, id, ItemId);
					formatex(OutputInfo, sizeof(OutputInfo), "!g[%s]!n %L", GameName, GAME_LANG, "EQ_NOTICE_BOUGHT", EquipName, EquipPoint, EquipPrice)
					client_printc(id, OutputInfo)
					
					cs_set_user_money(id, Money - EquipPrice);
				}
			}
			else {
				if(!og_have_Ujump(id)) {
					if(Money >= EquipPrice) {
						ExecuteForward(g_Forwards[EQ_BOUGHT], g_fwResult, id, ItemId);
						formatex(OutputInfo, sizeof(OutputInfo), "!g[%s]!n %L", GameName, GAME_LANG, "EQ_NOTICE_BOUGHT", EquipName, EquipPoint, EquipPrice)
						client_printc(id, OutputInfo)
						
						cs_set_user_money(id, Money - EquipPrice);
					}
				}
				else {
					formatex(OutputInfo, sizeof(OutputInfo), "!g[%s]!n %L", GameName, GAME_LANG, "EQ_NOTICE_NEEDMONEY", EquipPoint, MultiCost * 2, EquipName)
					client_printc(id, OutputInfo)
				}
			}
		}
		else if(equal(EquipName, "Flashbang")) {
			if(og_flash_count(id) >= 2 || og_flash_count(id) < 0) {
				client_print(id, print_center, "Khong the mua them Flashbang duoc nua.");
			}
			else {
				ExecuteForward(g_Forwards[EQ_BOUGHT], g_fwResult, id, ItemId)
				formatex(OutputInfo, sizeof(OutputInfo), "!g[%s]!n %L", GameName, GAME_LANG, "EQ_NOTICE_BOUGHT", EquipName, EquipPoint, EquipPrice)
				client_printc(id, OutputInfo)
				
				cs_set_user_money(id, Money - EquipPrice)
			}
		}
		else if(equal(EquipName, "Hegrenade")) {
			if(og_he_count(id) >= 1 || og_he_count(id) < 0) {
				client_print(id, print_center, "Khong the mua them Hegrenade duoc nua.");
			}
			else {
				ExecuteForward(g_Forwards[EQ_BOUGHT], g_fwResult, id, ItemId)
				formatex(OutputInfo, sizeof(OutputInfo), "!g[%s]!n %L", GameName, GAME_LANG, "EQ_NOTICE_BOUGHT", EquipName, EquipPoint, EquipPrice)
				client_printc(id, OutputInfo)
				
				cs_set_user_money(id, Money - EquipPrice)
			}
		}
				
		//----------------- Done ----------------//
		else {
			if(Money >= EquipPrice) {
				g_isUseEquip[id][ItemId] = 1;
				
				ExecuteForward(g_Forwards[EQ_BOUGHT], g_fwResult, id, ItemId)
				//g_PreWeapon[id][WeaponType] = ItemId
				//Show_MainEquipMenu(id)
				
				formatex(OutputInfo, sizeof(OutputInfo), "!g[%s]!n %L", GameName, GAME_LANG, "EQ_NOTICE_BOUGHT", EquipName, EquipPoint, EquipPrice)
				client_printc(id, OutputInfo)
				
				cs_set_user_money(id, Money - EquipPrice)
			}
			else { // Not Enough $
				formatex(OutputInfo, sizeof(OutputInfo), "!g[%s]!n %L", GameName, GAME_LANG, "EQ_NOTICE_NEEDMONEY", EquipPrice, EquipPoint, EquipName)
				client_printc(id, OutputInfo)
				
				//Show_WpnSubMenu(id, WeaponType, 0)
			}
		}
	}
	
	menu_destroy(Menu)
	return PLUGIN_CONTINUE
}


public MenuHandle_WpnSubMenu(id, Menu, Item)
{
	if(Item == MENU_EXIT)
	{
		menu_destroy(Menu)
		Show_MainEquipMenu(id)
		
		return PLUGIN_HANDLED
	}
	if(!is_user_alive(id))
	{
		menu_destroy(Menu)
		return PLUGIN_HANDLED
	}
	
	new Name[64], Data[16], ItemAccess, ItemCallback
	menu_item_getinfo(Menu, Item, ItemAccess, Data, charsmax(Data), Name, charsmax(Name), ItemCallback)
	
	new ItemId = str_to_num(Data)
	new WeaponPrice = ArrayGetCell(ArWeaponCost, ItemId)
	new PointCost = ArrayGetCell(ArWeaponPoint, ItemId)
	new Money = cs_get_user_money(id)
	new WeaponName[32]; ArrayGetString(ArWeaponName, ItemId, WeaponName, sizeof(WeaponName))
	new ReqWeaponName[32]; ArrayGetString(ArReqWeaponName, ItemId, ReqWeaponName, sizeof(ReqWeaponName))
	client_print(0, print_chat, "Req: %s", ReqWeaponName)
	new OutputInfo[80], WeaponType; WeaponType = ArrayGetCell(ArWeaponType, ItemId)
	new PlayerPoint = (cs_get_user_team(id) == CS_TEAM_CT) ? og_get_user_HP(id) : og_get_user_GP(id);
	
	if(WeaponPrice > 0 || PointCost > 0)
	{
		if(g_UnlockedWeapon[id][ItemId]) 
		{
			//cs_set_user_money(id, Money - WeaponPrice / 2)
			g_PreWeapon[id][WeaponType] = ItemId
			Show_MainEquipMenu(id)
		}
		else {
			// Need to unlock Required Weapon first
			if (equal(ReqWeaponName, "")) {
				//do nothing;
			}
			else {		
				if(!CheckWeaponRequired(id, WeaponName, ReqWeaponName)) {
					formatex(OutputInfo, sizeof(OutputInfo), "!g[%s]!n %L", GameName, GAME_LANG, "WPN_NOTICE_REQUIRED", ReqWeaponName);
					client_printc(id, OutputInfo)
					
					Show_WpnSubMenu(id, WeaponType, 0)
					return PLUGIN_HANDLED
				}
			}
			
			if(Money >= WeaponPrice && PlayerPoint >= PointCost) // Unlock now
			{
				g_UnlockedWeapon[id][ItemId] = 1
				
				g_PreWeapon[id][WeaponType] = ItemId
				Show_MainEquipMenu(id)
				
				formatex(OutputInfo, sizeof(OutputInfo), "!g[%s]!n %L", GameName, GAME_LANG, "WPN_NOTICE_UNLOCKED", WeaponName, PointCost, WeaponPrice)
				client_printc(id, OutputInfo)
				
				cs_set_user_money(id, Money - WeaponPrice)
				PlayerPoint -= PointCost;
				
				if(cs_get_user_team(id) == CS_TEAM_CT)
					og_set_user_HP(id, PointCost);
				else if(cs_get_user_team(id) == CS_TEAM_T)
					og_set_user_GP(id, PointCost);
					
			} else { // Not Enough $
				formatex(OutputInfo, sizeof(OutputInfo), "!g[%s]!n %L", GameName, GAME_LANG, "WPN_NOTICE_NEEDMONEY",PointCost, WeaponPrice, WeaponName)
				client_printc(id, OutputInfo)
				
				Show_WpnSubMenu(id, WeaponType, 0)
			}
		}
	}
	else {
		if(!g_UnlockedWeapon[id][ItemId]) 
			g_UnlockedWeapon[id][ItemId] = 1
		
		g_PreWeapon[id][WeaponType] = ItemId
		Show_MainEquipMenu(id)
	}
	
	menu_destroy(Menu)
	return PLUGIN_CONTINUE
}

public Equip_Weapon(id)
{
	if(cs_get_user_team(id) == CS_TEAM_T) {
		// Equip: Melee
		if(g_PreWeapon[id][WPN_MELEE] != -1) {
			ExecuteForward(g_Forwards[WPN_BOUGHT], g_fwResult, id, g_PreWeapon[id][WPN_MELEE])
		}
		
		g_PreWeapon[id][WPN_SECONDARY] = -1
		g_PreWeapon[id][WPN_PRIMARY] = -1
	}
	
	if(cs_get_user_team(id) == CS_TEAM_CT) {
		g_PreWeapon[id][WPN_MELEE] = -1
		// Equip: Secondary
		if(g_PreWeapon[id][WPN_SECONDARY] != -1)
		{
			drop_weapons(id, 2)
			ExecuteForward(g_Forwards[WPN_BOUGHT], g_fwResult, id, g_PreWeapon[id][WPN_SECONDARY])
		}
		
		// Equip: Primary
		if(g_PreWeapon[id][WPN_PRIMARY] != -1)
		{
			drop_weapons(id, 1)
			ExecuteForward(g_Forwards[WPN_BOUGHT], g_fwResult, id, g_PreWeapon[id][WPN_PRIMARY])
		}
	}
	
	Set_BitVar(g_GotWeapon, id)
}

// Drop primary/secondary weapons
stock drop_weapons(id, dropwhat)
{
	// Get user weapons
	static weapons[32], num, i, weaponid
	num = 0 // reset passed weapons count (bugfix)
	get_user_weapons(id, weapons, num)
	
	// Loop through them and drop primaries or secondaries
	for (i = 0; i < num; i++)
	{
		// Prevent re-indexing the array
		weaponid = weapons[i]
		
		if ((dropwhat == 1 && ((1<<weaponid) & PRIMARY_WEAPONS_BIT_SUM)) || (dropwhat == 2 && ((1<<weaponid) & SECONDARY_WEAPONS_BIT_SUM)))
		{
			// Get weapon entity
			static wname[32]; get_weaponname(weaponid, wname, charsmax(wname))
			engclient_cmd(id, "drop", wname)
		}
	}
}

FindWeaponIdByName(const WeaponName[]) {
	static TempName[32]
	
	for(new i = 0; i < g_TotalWeaponCount; i++) {
		ArrayGetString(ArWeaponName, i, TempName, charsmax(TempName));
		if(equal(TempName, WeaponName)) {
			return i;
		}
		else continue;
	}
	return -1;
}

FindEquipIdByName(const EquipName[]) {
	static TempName[32]
	
	for(new i = 0; i < g_TotalEquipCount; i++) {
		ArrayGetString(ArEquipName, i, TempName, charsmax(TempName));
		if(equal(TempName, EquipName))
			return i;
		else continue;
	}
	return -1;
}

bool:CheckWeaponRequired(id, const WeaponName_Check[], const WeaponName_Required[]) {
	static CheckId, RequiredId;
	
	CheckId = FindWeaponIdByName(WeaponName_Required);
	RequiredId = FindWeaponIdByName(WeaponName_Check);
	
	// If weapons aren't exist
	if(RequiredId == -1 || CheckId == -1) return false
	
	if(g_UnlockedWeapon[id][CheckId]) return true;
	else {
		if(g_UnlockedWeapon[id][RequiredId])
			return true;
		else
			return false;
	}
	return false;
}

stock client_printc(index, const text[], any:...)
{
	static szMsg[128]; vformat(szMsg, sizeof(szMsg) - 1, text, 3)
	
	replace_all(szMsg, sizeof(szMsg) - 1, "!g", "^x04")
	replace_all(szMsg, sizeof(szMsg) - 1, "!n", "^x01")
	replace_all(szMsg, sizeof(szMsg) - 1, "!t", "^x03")
	
	if(index)
	{
		message_begin(MSG_ONE_UNRELIABLE, g_MsgSayText, _, index);
		write_byte(index);
		write_string(szMsg);
		message_end();
	}
} 


		

	
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
