#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>

#pragma semicolon 1

#define PLUGIN_VERSION	 "2.0"
#define URL "http://siqve.co"

new g_CollisionGroup;
new bool:g_IsRedie[MAXPLAYERS+1];
new commandEnabled;

public Plugin:myinfo =
{
	name = "Redie With AutoJump",
	author = "Siqve",
	description = "Once you die, you may respawn as ghost.",
	version = PLUGIN_VERSION,
	url = URL
};

public OnPluginStart() {
	HookEvent("round_start", Round_Start, EventHookMode_Pre);	
	HookEvent("round_end", Round_End, EventHookMode_Pre);
	HookEvent("player_spawn", Player_Spawn);
	HookEvent("player_death", Player_Death);


	g_CollisionGroup = FindSendPropInfo("CBaseEntity", "m_CollisionGroup");
	
	CreateConVar("sm_redie_version", PLUGIN_VERSION, "Redie Version");
	
	RegConsoleCmd("sm_redie", Command_Redie);
	AddCommandListener(OnSay, "say");
	AddCommandListener(OnSay, "say_team");
}

public OnClientPostAdminCheck(client) {
	g_IsRedie[client] = false;
}


public OnClientPutInServer(client) {
	SDKHook(client, SDKHook_WeaponCanUse, RedieWeaponBlock);
}


public Action:Round_Start(Handle:event, const String:name[], bool:dontBroadcast) {
	commandEnabled = true;
	new ent = MaxClients + 1;
	while((ent = FindEntityByClassname(ent, "trigger_multiple")) != -1) {
		SDKHookEx(ent, SDKHook_EndTouch, triggerCollide);
		SDKHookEx(ent, SDKHook_StartTouch, triggerCollide);
		SDKHookEx(ent, SDKHook_Touch, triggerCollide);
	}
	for(new i = 1; i < MaxClients; i++) {
		if(IsClientInGame(i)) {
			SetEntData(i, g_CollisionGroup, 2, 4, true);
			SDKHook(i, SDKHook_TraceAttack, RedieDamageBlock);
			SDKHook(i, SDKHook_WeaponCanUse, RedieWeaponBlock);
		}
	}
}

public Action:Round_End(Handle:event, const String:name[], bool:dontBroadcast) {
	commandEnabled = false;
}


//NoBlock Redie
public Action:triggerCollide(entity, other) {
	if (0 < other && other <= MaxClients && g_IsRedie[other] && IsClientInGame(other)) {
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:RedieDamageBlock(victim, &attacker, &inflictor, &Float:damage, &damagetype, &ammotype, hitbox, hitgroup) {
	if(IsValidEntity(victim)) {
		if(g_IsRedie[victim]) {
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}


public Action:Player_Spawn(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	SDKHook(client, SDKHook_SetTransmit, Hook_SetTransmit);
	
	
	if(g_IsRedie[client]) {
		SetEntProp(client, Prop_Send, "m_CollisionGroup", 2);
		g_IsRedie[client] = false;
	} else {
		SetEntProp(client, Prop_Send, "m_nHitboxSet", 0);
	}
}

public Action:Hook_SetTransmit(entity, client)
{
	if(g_IsRedie[entity] && entity != client) {
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:Player_Death(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	PrintToChat(client, "\x01[\x03Redie\x01] \x04Type !redie to respawn as a ghost!");

	if(GetClientTeam(client) == 3) {
		new ent = -1;
		while((ent = FindEntityByClassname(ent, "item_defuser")) != -1) {
			if(IsValidEntity(ent)) {
				AcceptEntityInput(ent, "kill");
			}
		}
	}
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon) {
	if(g_IsRedie[client]) {
		buttons &= ~IN_USE;

		//AutoJump
		new index = GetEntProp(client, Prop_Data, "m_nWaterLevel");

		if (buttons & IN_JUMP) {
			if (!(Client_GetWaterLevel(client) > 1)) {
				if (!(GetEntityMoveType(client) & MOVETYPE_LADDER)) {
					SetEntPropFloat(client, Prop_Send, "m_flStamina", 0.0);
					if (!(GetEntityFlags(client) & FL_ONGROUND)) {
						buttons &= ~IN_JUMP;
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

stock Client_GetWaterLevel(client){
  return GetEntProp(client, Prop_Send, "m_nWaterLevel");
}

public Action:Command_Redie(client, args) {
	if(commandEnabled) 
		if (!IsPlayerAlive(client)) {
			if(GetClientTeam(client) > 1) {
				
				CS_RespawnPlayer(client);
				
				g_IsRedie[client] = true;
				
				new weaponId;
				for (new i = 0; i <= 3; i++) {
					if ((weaponId = GetPlayerWeaponSlot(client, i)) != -1) {  
						RemovePlayerItem(client, weaponId);
						RemoveEdict(weaponId);
					}
				}
				SetEntProp(client, Prop_Data, "m_ArmorValue", 0);
				SetEntProp(client, Prop_Send, "m_bHasDefuser", 0);
				SetEntProp(client, Prop_Send, "m_lifeState", 1);
				SetEntData(client, g_CollisionGroup, 2, 4, true);
				PrintToChat(client, "\x01[\x03Redie\x01] \x04You are now a ghost!");
			} else {
				PrintToChat(client, "\x01[\x03Redie\x01] \x04You may only use redie while on a team.");
			}
		} else {
			PrintToChat(client, "\x01[\x03Redie\x01] \x04You may only use redie while dead.");
		}
	} else 
		PrintToChat(client, "\x01[\x03Redie\x01] \x04You may not redie until the next round.");
	}
	return Plugin_Handled;
}

public Action:RedieWeaponBlock(client, weapon) {
	if(g_IsRedie[client])
		return Plugin_Handled;
	
	return Plugin_Continue;
}

public Action:OnSay(client, const String:command[], args)
{
	decl String:messageText[200];
	GetCmdArgString(messageText, sizeof(messageText));
	
	if(strcmp(messageText, "\"!redie\"", false) == 0)
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}