#include <sourcemod>

new String:Logfile[PLATFORM_MAX_PATH];

public Plugin:myinfo =
{
	name = "Retry On Restart",
	author = "Franc1sco steam: franug",
	version = "1.0",
	description = "Force retry on restart",
	url = "www.uea-clan.com"
};


public OnPluginStart()
{
	CreateConVar("sm_retryonrestart", "v1.0", _, FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);

    	RegServerCmd("quit", OnDown);
    	RegServerCmd("_restart", OnDown);
    	BuildPath(Path_SM, Logfile, sizeof(Logfile), "logs/restarts.log");	
}
 
public Action:OnDown(args)
{
for(new i = 1; i <= MaxClients; i++)
	if (IsClientInGame(i) && !IsFakeClient(i))
            	ClientCommand(i, "retry"); // force retry

LogToFile(Logfile,"Server restarted");
}


// simple and clean