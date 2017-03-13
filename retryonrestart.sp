/*  Retry On Restart
 *
 *  Copyright (C) 2017 Francisco 'Franc1sco' García
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

#include <sourcemod>
#define PLUGIN_VERSION "1.2"
#define COMMAND_NAME "sm_retryandrestart"
new bool:listening = true;
new Float:delay = 0.0;
new Handle:cvar_enabled = INVALID_HANDLE;
new Handle:cvar_delay = INVALID_HANDLE;
new Handle:cvar_version = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "Retry On Restart",
	author = "Franc1sco franug & Derek D. Howard",
	version = PLUGIN_VERSION,
	description = "Force retry on restart",
	url = "https://forums.alliedmods.net/showthread.php?t=202625"
};

public OnPluginStart() {
	cvar_version = CreateConVar("sm_retryonrestart", PLUGIN_VERSION, _, FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	cvar_enabled = CreateConVar("sm_retryonrestart_enabled", "1", _, FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	cvar_delay = CreateConVar("sm_retryonrestart_delay", "0.1", _, FCVAR_PLUGIN);
   	RegServerCmd("quit", OnDown);
	RegServerCmd("_restart", OnDown);
	RegAdminCmd(COMMAND_NAME, RestartServerCmd, ADMFLAG_RCON, "Forces all players to RETRY connection, and restarts the server.");
	HookConVarChange(cvar_enabled, cvarChange);
	HookConVarChange(cvar_delay, cvarChange);
	HookConVarChange(cvar_version, versionCvarChange);
}

public OnConfigsExecuted() {
	listening = GetConVarBool(cvar_enabled);
	delay = GetConVarFloat(cvar_delay);
	SetConVarString(cvar_version, PLUGIN_VERSION)
}
 
public Action:OnDown(args) {
	if (listening) {
		LogAction(-1, -1, "The server was restarted, attempted to reconnect all players.");
		for(new i = 1; i <= MaxClients; i++) {
			if (IsClientInGame(i) && !IsFakeClient(i)) {
					ClientCommand(i, "retry"); // force retry
			}
		}
	}
}

public Action:RestartServerCmd(client, args) {
	listening = false;
	new numargs = GetCmdArgs();
	new String:arg1[2]
	if (numargs > 0) {
		GetCmdArg(1, arg1, sizeof(arg1))
		if (StrEqual(arg1, "0")) {
			LogAction(client, -1, "\"%L\" restarted the server, and did not try to auto-reconnect all players.", client);
			ServerCommand("_restart");
		} else {
			RetryAndRestart(client);
		}
	} else {
		RetryAndRestart(client);
	}
	return Plugin_Handled
}

RetryAndRestart(client) {
	LogAction(client, -1, "\"%L\" restarted the server, attempting to reconnect all players.", client);
	for(new i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && !IsFakeClient(i)) {
            	ClientCommand(i, "retry"); // force retry
		}
	}
	if (delay == 0.0) {
		ServerCommand("_restart");
	} else {
		CreateTimer(delay, DoRestart);
	}
}

public Action:DoRestart(Handle:timer) {
	ServerCommand("_restart");
}

public cvarChange(Handle:hHandle, const String:strOldValue[], const String:strNewValue[]) {
	listening = GetConVarBool(cvar_enabled);
	delay = GetConVarFloat(cvar_delay);
}

public versionCvarChange(Handle:hHandle, const String:strOldValue[], const String:strNewValue[]) {
	SetConVarString(hHandle, PLUGIN_VERSION)
}