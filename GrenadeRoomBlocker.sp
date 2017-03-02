#pragma semicolon 1

#define DEBUG

#define PLUGIN_VERSION "1.4"
#define URL "http://siqve.co"

#include <sourcemod>
#include <sdktools>

Handle cvar;
Handle cvar1;
public Plugin myinfo = 
{
	name = "XDream Grenade Room Blocker",
	author = "Siqve",
	description = "Strips and denies the teleport entity to grenade room!",
	version = PLUGIN_VERSION,
	url = URL
};


public void OnPluginStart() {
	RegConsoleCmd("rules", rulesCMD);
	RegConsoleCmd("rule", rulesCMD);
	
	char mapName[104];
	GetCurrentMap(mapName, 104);

	if (StrEqual(mapName, "surf_greatriver_xdre4m_mp", false)) {
		
		HookEvent("round_start", OnRoundStart);
	}
}


public OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast) {

	int index = -1;
	while ((index = FindEntityByClassname(index, "trigger_teleport")) != -1) {
		char buffer[6];
		GetEntPropString(index, Prop_Data, "m_target", buffer, 6);
		if (StrEqual(buffer, "end_t", false) || StrEqual(buffer, "end_c", false)) {
			RemoveEdict(index);
			index = -1;
		}
	}
}