#include <sourcemod>
#include <sdktools>
#include <zombiereloaded>

#define CS_TEAM_SPECTATOR 1
#define CS_TEAM_T 2 
#define CS_TEAM_CT 3

#pragma semicolon 1

#define PLUGIN_VERSION "1.0"

bool isMotherZm[MAXPLAYERS + 1];
ConVar g_Enabled;
ConVar g_MotherZM;

public Plugin myinfo =
{
	name = "[ZR] Spectate",
	author = "Nobody333",
	description = "Spectate a player",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=2749439"
}

public void OnPluginStart()
{
	g_MotherZM = CreateConVar("sm_spec_blockmotherzm", "1", "0 = Don't block motherzombies from using !spec / 1 = block");
	g_Enabled = CreateConVar("sm_spec_enabled", "1", "Enable / Disable Plugin.");
	
	RegConsoleCmd("sm_afk", Command_Spec);
	RegConsoleCmd("sm_spec", Command_Spec);
	RegConsoleCmd("sm_spectate", Command_Spec);
	RegConsoleCmd("sm_observe", Command_Spec);
	
	LoadTranslations("common.phrases");
	
	HookEvent("round_start", OnRoundStart);
}

public Action OnRoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		isMotherZm[i] = false;
	}
}

public Action Command_Spec(int client, int args)
{
	if(!IsClientInGame(client) || !IsClientConnected(client))
	{
		return Plugin_Handled;
	}
	
	if(g_Enabled.IntValue == 0)
	{
		return Plugin_Handled;
	}
	
	if(ZR_isMotherZombie(client) && g_MotherZM.IntValue == 1)
	{
		PrintToChat(client, " \x04[SPEC]\x01 Mother zombies can't become spectator.");
		return Plugin_Handled;
	}

	if(GetAliveTeamCount(client) == 1)
	{
		PrintToChat(client, " \x04[SPEC]\x01 Last player can't become spectator.");
		return Plugin_Handled;
	}
	
	if(args == 0 && IsPlayerAlive(client))
	{
		PrintToChat(client, " \x04[SPEC]\x01 Now you are a spectator.");
		Spec(client);
		return Plugin_Handled;
	}
	
	if(args == 1)
	{
		char arg1[32];
		GetCmdArg(1, arg1, sizeof(arg1));
		
		int target = FindTarget(client, arg1);
		
		if(!IsClientInGame(target) || !IsClientConnected(target))
		{
			return Plugin_Handled;
		}	

		if(target == client)
		{
			PrintToChat(client, " \x04[SPEC]\x01 You can't watch yourself.");
			return Plugin_Handled;
		}		

		if(!IsPlayerAlive(target))
		{
			PrintToChat(client, " \x04[SPEC]\x01 You can only watch players who are alive.");
			return Plugin_Handled;
		}
		
		char name[MAX_NAME_LENGTH];
		GetClientName(target, name, sizeof(name));
		
		if(!IsPlayerAlive(client))
		{
			PrintToChat(client, " \x04[SPEC]\x01 Now you are spectating \x07%s\x01.", name);
			ChangeClientTeam(client, CS_TEAM_SPECTATOR);
			Watch(client, target);
			return Plugin_Handled;
		}
		
		if(IsPlayerAlive(client))
		{
			PrintToChat(client, " \x04[SPEC]\x01 Now you are spectating \x07%s\x01.", name);
			Spec(client);
			Watch(client, target);
			return Plugin_Handled;
		}
		return Plugin_Handled;
	}
	
	if(args > 1)
	{
		PrintHintText(client, "[SPEC] usage: sm_spec <name|#userid>");
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

void Spec(int client)
{
	ChangeClientTeam(client, CS_TEAM_SPECTATOR);
	ForcePlayerSuicide(client);
}

void Watch(int client, int target)
{
	FakeClientCommand(client, "spec_player %i", target);
}

public int ZR_OnClientInfected(int client, int attacker, bool motherInfect, bool respawnOverride, bool respawn)
{
	if(motherInfect)
	{
		isMotherZm[client] = true;
	}
}

stock bool ZR_isMotherZombie(int client)
{
	if(isMotherZm[client] == true)
	{
		return true;
	}
	return false;
}

stock int GetAliveTeamCount(int client)
{
	int number = 0;
	int team = GetClientTeam(client);
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsClientConnected(i) && IsPlayerAlive(i) && GetClientTeam(i) == team)
		{
			number++;
		}
	}
	return number;
}
