#pragma semicolon 1
#pragma newdecls required

#include <sdktools>
#include <tf2_stocks>

Handle gH_RestartTimer = null;
int gI_RestartTimerIteration = 0;
int g_iRoundCount = 0;

public Plugin myinfo =
{
	name = "TF2 Door Animation Overlay",
	author = "rtldg",
	description = "Play the door animation overlay thing with sm_dooranimation.",
	version = "1.0.1",
	url = "https://github.com/rtldg/tf2-dooranimation"
}

public void OnPluginStart()
{
	RegAdminCmd("sm_dooranimation", Command_DoorAnimation, ADMFLAG_RCON, "Shows you the door animation");
	HookEvent("teamplay_round_start", Event_RoundStart);
	HookEvent("teamplay_round_win", Event_RoundWin);
}

public void OnMapStart()
{
	g_iRoundCount = 0;
}

public Action Timer_RestartTime(Handle timer)
{
	Event event = CreateEvent("restart_timer_time");
	event.SetInt("time", gI_RestartTimerIteration);
	event.Fire();

	PrintToChatAll("Runda rozpocznie się za %d sekund", gI_RestartTimerIteration);

	if (gI_RestartTimerIteration-- == 10)
	{
		gH_RestartTimer = CreateTimer(1.0, Timer_RestartTime, 0, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		return Plugin_Continue;
	}

	if (gI_RestartTimerIteration > 0)
	{
		return Plugin_Continue;
	}

	gH_RestartTimer = null;
	return Plugin_Stop;
}

void Frame_RestartTime()
{
	gI_RestartTimerIteration = 10;
	delete gH_RestartTimer;
	Timer_RestartTime(null);
}

public Action Command_DoorAnimation(int client, int args)
{
	if (GameRules_GetProp("m_bInWaitingForPlayers") == 1)
	{
		PrintToChat(client, "Skrypt nie może zostać uruchomiony, ponieważ trwa wyszukiwanie graczy.");
		return Plugin_Handled;
	}

	if (g_iRoundCount >= 3)
	{
		PrintToChat(client, "Skrypt nie może zostać uruchomiony po 3 rundzie.");
		return Plugin_Handled;
	}

	GameRules_SetProp("m_nRoundsPlayed", 0);
	GameRules_SetProp("m_nMatchGroupType", 7);
	RequestFrame(Frame_RestartTime);
	PlayDoorAnimation(client);
	
	CreateTimer(11.0, Timer_ActivateControlPoint, _, TIMER_FLAG_NO_MAPCHANGE);
	
	return Plugin_Handled;
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if (g_iRoundCount < 3)
	{
		Command_DoorAnimation(0, 0);
	}
	return Plugin_Handled;
}

public Action Event_RoundWin(Event event, const char[] name, bool dontBroadcast)
{
	g_iRoundCount++;
	return Plugin_Continue;
}

void PlayDoorAnimation(int client)
{
	if (client > 0 && IsClientInGame(client))
	{
		PrintToChat(client, "Animacja drzwi została uruchomiona.");
	}
	else
	{
		PrintToServer("Animacja drzwi została uruchomiona.");
	}
	DoorAnimationFunction();
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i))
		{
			SetEntityMoveType(i, MOVETYPE_NONE);
		}
	}
	
	CreateTimer(10.0, Timer_UnblockPlayers, _, TIMER_FLAG_NO_MAPCHANGE);
}

void DoorAnimationFunction()
{
	// Implementacja funkcji animacji drzwi
}

public Action Timer_UnblockPlayers(Handle timer)
{
	UnblockPlayers();
	return Plugin_Stop;
}

void UnblockPlayers()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i))
		{
			SetEntityMoveType(i, MOVETYPE_WALK);
		}
	}
}

public Action Timer_ActivateControlPoint(Handle timer)
{
	int controlPoint = FindEntityByClassname(-1, "team_control_point");
	if (controlPoint != -1)
	{
		AcceptEntityInput(controlPoint, "ShowModel");
		AcceptEntityInput(controlPoint, "Enable");
		SetVariantInt(0);
		AcceptEntityInput(controlPoint, "SetLocked");
		SetVariantInt(0);
		AcceptEntityInput(controlPoint, "SetTeam");
		
		PrintToChatAll("Punkt kontrolny został aktywowany i można go teraz przejąć!");
	}
	else
	{
		PrintToServer("Gra została rozpoczęta!");
	}
	return Plugin_Stop;
}