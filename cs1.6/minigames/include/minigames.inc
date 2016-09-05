#if defined _minigames_included
  #endinput
#endif
#define _minigames_included

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib minigames
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib minigames
	#endif
#else
	#pragma library minigames
#endif

/*
	NORMAL = 0,               //0
	SCOUT_NOZOOM_MODE,	//1
	KNIFE_HP_MODE,		//2
	INVISIBLE_MODE,		//3
	TPV_MODE,		//4 // 3rd Person View mode
	CHANGEMODEL_MODE,	//5
	RUN_MODE,		//6
	BOMB_MODE,		//7
	CHICKEN_MODE,		//8
	ZEUS_MODE,		//9
	RAMBO_MODE,		//10
	REVERSE_MODE,		//11
	ONEBUTTON_MODE,		//12
	UPSIDE_DOWN_MODE,	//13
	AWP_JUMP_MODE,		//14
	NIGHTMARE_MODE,		//15
	DEATHLYNADE_MODE,	//16
	FLY_MODE		//17
*/

/**
 * Return the mode is being played
 */
native mm_get_current_mode()

/**
 * Return the last mode was being played
 */
native mm_get_last_mode()

/**
 * Return the next mode will be played
 */
native mm_get_next_mode()
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
