#pragma semicolon 1

#define DEBUG

#define PLUGIN_VERSION "1.1.0"
#define URL "http://siqve.co"

#include <sourcemod>
#include <sdktools>

int bet[MAXPLAYERS + 1][MAXPLAYERS + 1];

int startHP[MAXPLAYERS + 1];
bool bettingEnabled = true;


public Plugin myinfo = 
{
	name = "HP Gambler",
	author = "Siqve",
	description = "Gamble your health for a chance to win more back!",
	version = PLUGIN_VERSION,
	url = URL
};

char prefix[] = "[\x05HP\x03Bet\x01] ";


public void OnPluginStart() {
	HookEvent("round_end", OnRoundEnd, EventHookMode_Pre);
	HookEvent("round_start", OnRoundStart, EventHookMode_Pre);	
	
	
	RegConsoleCmd("bet", betCommand);
}

public void OnMapStart() {
}

public void OnClientDisconnect(int client) {
	ClearPendingBet(client);
}


public Action betCommand(client, args) {
	if (IsPlayerAlive(client)){
		PrintToChat(client, "%s\x0FThis command may only be used when you're dead.", prefix);
		return Plugin_Handled;
	}
	int pending = 0;
	char name[MAX_NAME_LENGTH];
	if ((pending = GetPendingBet(client)) > 0) {
		GetClientName(pending, name, sizeof(name));
		PrintToChat(client, "%s\x0BYou've bet \x03%ihp \x0Bon \x03%s\x0B.", prefix, bet[client][pending], name);
		return Plugin_Handled;
	}
	
	if (!CanBet(client)) {
		return Plugin_Handled;
	}
	OpenBetMenu(client);
	
	/*
	if (args < 2) {
		PrintToChat(client, "%s \x0FCorrect command usage is: !bet <HP> <Player>", prefix);
		return Plugin_Handled;
	}
	
	char arg1[32];
	char arg2[32];
	
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	
	int hp = StringToInt(arg1);
	
	if (hp == 0) {
		PrintToChat(client, "%s \x0FCorrect command usage is: !bet <HP> <Player>", prefix);
		return Plugin_Handled;
	}
	int target = FindTarget(client, arg2, true, false);
	if (target == -1) {
		PrintToChat(client, "%s \x0FUnable to find player %s.", prefix, arg2);
		return Plugin_Handled;	
	}
	if (!IsPlayerAlive(target)){
		PrintToChat(client, "%s \x0FPlayer %s is not alive.", prefix, arg2);
		return Plugin_Handled;	
	}
	*/
	
	return Plugin_Handled;
}



OpenBetMenu(client, type=0)
{
	Handle menu = CreateMenu(BetHandler);
	if (type == 0) {
		for(int i=1; i < MAXPLAYERS+1; i++) {
			char name[MAX_NAME_LENGTH];
			char id[10];
			if (IsValidClient(i) && IsPlayerAlive(i) && (i != client)) {
				GetClientName(i, name, MAX_NAME_LENGTH);
				IntToString(i, id, sizeof(id));
				AddMenuItem(menu, id, name);
			}
		}
	} else{
		SetMenuTitle(menu, "Select HP To Bet:");
		AddMenuItem(menu, "10hp", "10");
		AddMenuItem(menu, "30hp", "30");
		AddMenuItem(menu, "50hp", "50");
		AddMenuItem(menu, "60hp", "60");
		AddMenuItem(menu, "70hp", "70");
		AddMenuItem(menu, "80hp", "80");

		/*for (int i = 1; i < 10; i++) {
			char custom[10];
			IntToString(i * 10, custom, 10);
			AddMenuItem(menu, custom, custom);
			
			
		}*/
		//AddMenuItem(menu, "blank", "", ITEMDRAW_SPACER);
	}
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public BetHandler(Handle menu, MenuAction action, client, param2)
{
	/* If an option was selected, tell the client about the item. */
	if (action == MenuAction_Select)
	{
		char info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		char name[MAX_NAME_LENGTH];
		char name2[MAX_NAME_LENGTH];
		
		int target;
		if ((target = StringToInt(info)) > 0) {
			if (StrContains(info, "hp", true) != -1) {
				int pending = GetPendingBet(client);
				if (pending == 0 || !CanBet(client)) {
					ClearPendingBet(client);
					return 0;
				} 
				if (!IsValidClient(pending) || !IsPlayerAlive(pending)) {
					PrintToChat(client, "%s\x0FSelected player is no longer valid.", prefix);
					ClearPendingBet(client);
					return 0;
				}
				
				bet[client][pending] = target;
				GetClientName(client, name, sizeof(name));
				GetClientName(pending, name2, sizeof(name2));
				PrintToChatAll("%s\x0BPlayer \x03%s \x0Bbet \x05%s \x0Bon \x05%s\x0B.", prefix, name, info, name2);
			} else {
				if (GetPendingBet(client) > 0) {
					PrintToChat(client, "%s\x0FYou may only bet once.", prefix);
					return 0;
				}
				if (!CanBet(client)) 
					return 0;
				
				if (!IsValidClient(target) || !IsPlayerAlive(target)) {
					PrintToChat(client, "%s\x0FSelected player is no longer valid.", prefix);
					ClearPendingBet(client);
					return 0;
				}
				bet[client][target] = 1;
				OpenBetMenu(client, 1);
			}
		}
	}
	else if (action == MenuAction_Cancel)
	{
		ClearPendingBet(client);
	}
	else if (action == MenuAction_End)
	{
		ClearPendingBet(client);
		CloseHandle(menu);
	}
	return 0;
}


public Action OnRoundStart(Handle event, char[] name, bool dontBroadcast) {
	bettingEnabled = true;
	for(int i=1; i < MAXPLAYERS+1; i++) {
		ClearPendingBet(i);
	}
	
	for(int i=1; i < MAXPLAYERS+1; i++) {
		if (startHP[i] != 0) {
			SetEntityHealth(i, 100 + startHP[i]);
		}
	}
	
	
}

public Action OnRoundEnd(Handle event, char[] name, bool dontBroadcast) {
	bettingEnabled = false;
	int winner = GetWinner();
	int pending = 0;
	for(int i=1; i < MAXPLAYERS+1; i++) {
		if ((pending = GetPendingBet(i)) > 0) {
			if (winner == 0) {
				PrintToChat(i, "%s\x0BThere was no winner, and your HP has been restored.");
				continue;
			}
			if (pending == winner) {
				startHP[i] = bet[i][pending];
				ClearPendingBet(i);
				PrintToChat(i, "%s\x05Congratulations\x0B, you won your bet! You start the next round with \x03%ihp\x0B!", prefix, (100 + startHP[i]));
				continue;
			} else {
				startHP[i] = bet[i][pending] * -1;
				ClearPendingBet(i);
				PrintToChat(i, "%s\x0BYou \x07lost \x0Byour bet! You start the next round with \x03%ihp\x0B!", prefix, (100 + startHP[i]));
			}
		}
	}
}

int GetWinner() {
	int alive = 0;
	int idalive = 0;
	for(int i=1; i < MAXPLAYERS+1; i++) {
		if (IsValidClient(i)) {
			if (IsPlayerAlive(i)) {
				alive++;
				idalive = i;
			}
		}
	}
	if (alive != 1)
		return 0;
	
	return idalive;
}

int GetPendingBet(client) {
	for(int i=1; i < MAXPLAYERS+1; i++) {
		if (bet[client][i] > 0)
			return i;
	}	
	return 0;
}

void ClearPendingBet(client) {
	for(int i=1; i < MAXPLAYERS+1; i++) {
		bet[client][i] = 0;
	}	
}


stock bool CanBet(client) {
	if (!bettingEnabled) {
		PrintToChat(client, "%s\x0FYou may not bet right now.", prefix);
		return false;
	}
	int alive = 0;
	bool health = false;
	for(int i=1; i < MAXPLAYERS+1; i++) {
		if (IsValidClient(i)) {
			if (IsPlayerAlive(i)) {
				alive++;
				if (GetClientHealth(i) < 20) {
					health = true;
				}
			}
		}
	}
	if (alive != 2) {
		PrintToChat(client, "%s\x0FYou may only bet when there's 2 players left.", prefix);
		return false;
	} else {
		if (health) {
			PrintToChat(client, "%s\x0FOne or more players are beneath 20 health.", prefix);
			return false;
		} else{
			return true;
		}
	}
}

stock bool IsValidClient(client) {
    if (client <= 0 || client > MaxClients)
        return false;

    if (!IsClientInGame(client)/* || IsFakeClient(client)*/)
        return false;

    return true;
}