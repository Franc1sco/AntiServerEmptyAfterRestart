/*  Retry On Restart
 *
 *  Copyright (C) 2017-2018 Francisco 'Franc1sco' García
 * 
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation, either version 3 of the License, or (at your option) 
 * any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT 
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with 
 * this program. If not, see http://www.gnu.org/licenses/.
 */

#pragma semicolon 1 
#include <sourcemod>
#define PLUGIN_VERSION "2.0"

#pragma newdecls required

bool listening;
float delay;
ConVar cvar_enabled;
ConVar cvar_delay;
ConVar cvar_version;

public Plugin myinfo =
{
	name = "Retry On Restart",
	author = "Franc1sco franug",
	version = PLUGIN_VERSION,
	description = "Force retry on restart",
	url = "https://forums.alliedmods.net/showthread.php?t=202625"
};

public void OnPluginStart() 
{
	cvar_version = CreateConVar("sm_retryonrestart", PLUGIN_VERSION, "Plugin version", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	cvar_enabled = CreateConVar("sm_retryonrestart_enabled", "1", "Enable or disable plugin", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	cvar_delay = CreateConVar("sm_retryonrestart_delay", "5.0", "Time in seconds to apply restart when you use the admin command");
	
   	RegServerCmd("quit", OnDown);
	RegServerCmd("_restart", OnDown);
	RegAdminCmd("sm_retryandrestart", RestartServerCmd, ADMFLAG_RCON, "Forces all players to RETRY connection, and restarts the server.");
	
	listening = GetConVarBool(cvar_enabled);
	delay = GetConVarFloat(cvar_delay);
	
	HookConVarChange(cvar_enabled, cvarChange);
	HookConVarChange(cvar_delay, cvarChange);
	HookConVarChange(cvar_version, versionCvarChange);
}

public void OnConfigsExecuted() {
	listening = GetConVarBool(cvar_enabled);
	delay = GetConVarFloat(cvar_delay);
	SetConVarString(cvar_version, PLUGIN_VERSION);
}
 
public Action OnDown(int args) {
	if (listening) {
		LogAction(-1, -1, "The server was restarted, attempted to reconnect all players.");
		for(int i = 1; i <= MaxClients; i++) {
			if (IsClientInGame(i) && !IsFakeClient(i)) {
					ClientCommand(i, "retry"); // force retry
			}
		}
	}
}

public Action RestartServerCmd(int client,int args) {
	listening = false;
	int numargs = GetCmdArgs();
	char arg1[2];
	if (numargs > 0) {
		GetCmdArg(1, arg1, sizeof(arg1));
		if (StrEqual(arg1, "0")) {
			LogAction(client, -1, "\"%L\" restarted the server, and did not try to auto-reconnect all players.", client);
			ServerCommand("_restart");
		} else {
			RetryAndRestart(client);
		}
	} else {
		RetryAndRestart(client);
	}
	return Plugin_Handled;
}

void RetryAndRestart(int client) {
	LogAction(client, -1, "\"%L\" restarted the server, attempting to reconnect all players.", client);
	for(int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && !IsFakeClient(i)) {
            	ClientCommand(i, "retry"); // force retry
		}
	}
	if (delay == 0.0) {
		ServerCommand("_restart");
	} else {
		PrintToChatAll("server restarting in %d seconds, you will be automatically reconnected! Please do not leave!", view_as<int>(delay));
			
		PrintCenterTextAll("server restarting in %d seconds, you will be automatically reconnected! Please do not leave!", view_as<int>(delay));
		
		ServerCommand("sm_msay server restarting in %d seconds, you will be automatically reconnected! Please do not leave!", view_as<int>(delay));
		
		CreateTimer(delay, DoRestart);
	}
}

public Action DoRestart(Handle timer) {
	ServerCommand("_restart");
}

public void cvarChange(Handle hHandle, const char[] strOldValue, const char[] strNewValue) {
	listening = GetConVarBool(cvar_enabled);
	delay = GetConVarFloat(cvar_delay);
}

public void versionCvarChange(Handle hHandle, const char[] strOldValue, const char[] strNewValue) {
	SetConVarString(hHandle, PLUGIN_VERSION);
}