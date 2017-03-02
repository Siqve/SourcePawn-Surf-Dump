#include <sourcemod>
#include <sdktools>
#pragma semicolon 1

#define PLUGIN_VERSION "1.5"
#define URL "http://siqve.co"

public Plugin:myinfo =
{
	name = "Auto BHop",
	author = "Siqve",
	description = "Auto BHop when holding jump button.",
	version = PLUGIN_VERSION,
	url = URL
}

stock Client_GetWaterLevel(client){
  return GetEntProp(client, Prop_Send, "m_nWaterLevel");
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (IsPlayerAlive(client) && Client_GetWaterLevel(client) <= 0 && buttons & IN_JUMP 
		&& !(GetEntityMoveType(client) & MOVETYPE_LADDER)) {
		if (!(GetEntityFlags(client) & FL_ONGROUND)) {
			buttons &= ~IN_JUMP;
		}
		SetEntPropFloat(client, Prop_Send, "m_flStamina", 0.0);
	}
	return Plugin_Continue;
}





