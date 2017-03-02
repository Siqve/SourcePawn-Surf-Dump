#include <sourcemod>
#include <sdktools>
#include <sdktools_sound>
#include <emitsoundany>
#include <clientprefs>

#pragma semicolon 1
#define MAX_FILE_LEN 80

char g_pJoinSound[80] = "siqvesounds/joinsound.mp3";
char g_pEndSounds[80] = "siqvesounds";

char g_sounds[256][64];
int g_iSounds;

char sCookieValue[11];

Handle g_soundCookie;
Handle g_cvarVolume;
Handle g_cvarJoinVolume;
Handle g_cvarJoinSound;


#define PLUGIN_VERSION "2.2"
#define URL "http://siqve.co"

public Plugin myinfo = 
{
	name = "Master Sound",
	author = "Siqve",
	description = "Handles join and round end sounds",
	version = PLUGIN_VERSION,
	url = URL
};

public OnPluginStart() {
	HookEvent("round_end", RoundEnd);
	g_soundCookie = RegClientCookie("Master Sound", "", CookieAccess_Private);
	g_cvarVolume = CreateConVar("sm_music_volume", "0.7", "Volume for every round end sound.",_,true,0.0,true,1.0);
	g_cvarJoinVolume = CreateConVar("sm_join_volume", "0.3", "Volume for join sound.",_,true,0.0,true,1.0);
	g_cvarJoinSound = CreateConVar("sm_join_sound", g_pJoinSound, "Sound for players joining.");
	RegConsoleCmd("endsounds", soundmenu);
	
}

public OnMapStart() {
	LoadSounds();

}

public OnConfigsExecuted() {
	GetConVarString(g_cvarJoinSound, g_pJoinSound, sizeof(g_pJoinSound));
	char buffer[MAX_FILE_LEN];
	Format(buffer, sizeof(buffer), "sound/%s", g_pJoinSound);
	AddFileToDownloadsTable(buffer);
}


public OnClientPostAdminCheck(client) {
	EmitSoundToClientAny(client, g_pJoinSound,
				 SOUND_FROM_PLAYER,
				 SNDCHAN_AUTO,
				 SNDLEVEL_NORMAL,
				 SND_NOFLAGS,
				 GetConVarFloat(g_cvarJoinVolume));
}

public Action RoundEnd(Handle event, const char[] name, bool dontBroadcast) {
	StopWinSound();
	int winner = GetEventInt(event, "winner");

	if(winner >= 1) {
		PlayEndSound();
	}
}

public Action soundmenu(client, args) {
	GetClientCookie(client, g_soundCookie, sCookieValue, sizeof(sCookieValue));
	int cookievalue = StringToInt(sCookieValue);
	if (!cookievalue) {
		SetClientCookie(client, g_soundCookie, "1");
		PrintToChat(client, "|\x0BEnd sounds disabled!");

	} else {
		SetClientCookie(client, g_soundCookie, "0");
		PrintToChat(client, "|\x0BEnd sounds enabled!");
	}
	return Plugin_Handled;
}

PlayEndSound() {
	int randomSong = GetRandomInt(0, g_iSounds);
	
	for (int i = 1; i <= MaxClients; i++) {
		GetClientCookie(i, g_soundCookie, sCookieValue, sizeof(sCookieValue));
		int cookievalue = StringToInt(sCookieValue);
		if (IsValidClient(i) && cookievalue == 0) {
			EmitSoundToClientAny(i, g_sounds[randomSong],
				 SOUND_FROM_PLAYER,
				 SNDCHAN_AUTO,
				 SNDLEVEL_NORMAL,
				 SND_NOFLAGS,
				 GetConVarFloat(g_cvarVolume));
		}
	}
}

LoadSounds() {
	char soundpath[32];
	char soundpath2[32];
	char name[64];
	char songname[64];
	char songname2[64];
	
	int namelen;
	int sounds;
	strcopy(soundpath, 32, g_pEndSounds);
	Format(soundpath2, 32, "sound/%s/", soundpath);
	Handle soundsdir = OpenDirectory(soundpath2);
	PrecacheSoundAny(g_pJoinSound);
	if (soundsdir != INVALID_HANDLE) {
		while (ReadDirEntry(soundsdir, name, 64)) {
			namelen = strlen(name) - 4;
			if(StrContains(name, ".mp3", false) == namelen) {
				Format(songname, sizeof(songname), "sound/%s/%s", soundpath, name);
				AddFileToDownloadsTable(songname);
				Format(songname2, sizeof(songname2), "%s/%s", soundpath, name);
				PrecacheSoundAny(songname2);
				g_sounds[sounds] = songname2;
				sounds++;
			}
		}
	}
	g_iSounds = sounds - 1;
}


	
StopWinSound() {
	for (new i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i)) {
			StopSound(i, SNDCHAN_STATIC, "radio/terwin.wav");
			StopSound(i, SNDCHAN_STATIC, "radio/ctwin.wav");
		}
	}
}


stock bool IsValidClient(client) {
	return client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client);
}