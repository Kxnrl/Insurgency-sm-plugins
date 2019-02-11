#pragma semicolon 1
#pragma newdecls required

#include <smutils>

public Plugin myinfo = 
{
    name        = "No map vote",
    author      = "Kyle",
    description = "<- description ->",
    version     = "1.0",
    url         = "https://www.kxnrl.com"
};

static char logFile[128];

static ConVar mp_gamemode = null;

public void OnPluginStart()
{
    SMUitls_InitUserMessage();
    SMUtils_SetChatPrefix("[{purple}魔法少女{white}]");
    SMUtils_SetChatSpaces("   ");
    SMUtils_SetChatConSnd(true);

    if (!AddCommandListener(Command_CallVote, "callvote"))
        SetFailState("Failed to Hook command \"callvote\".");
    
    BuildPath(Path_SM, logFile, 128, "logs/callvote.log");
    
    mp_gamemode = FindConVar("mp_gamemode");
    if (mp_gamemode == null)
        SetFailState("Failed to FindConVar \"mp_gamemode\".");
}

/* Syntax 
callvote Kick <userID>
callvote RestartGame
callvote ChangeLevel <mapname>
callvote ScrambleTeams
callvote SwapTeams
*/
public Action Command_CallVote(int client, const char[] cmd, int args)
{
    if (!client || args < 1) return Plugin_Continue;
    
    char command[2][32];
    GetCmdArg(1, command[0], 32);
    GetCmdArg(2, command[1], 32);
    LogToFileEx(logFile, "CommandListener -> \"%L\" -> \"%s %s\"", client, command[0], command[1]);

    char mode[32];
    mp_gamemode.GetString(mode, 32);
    if (
        strcmp(mode, "conquer")     == 0 ||
        strcmp(mode, "checkpoint")  == 0 ||
        strcmp(mode, "hunt")        == 0 ||
        strcmp(mode, "outpost")     == 0 ||
        strcmp(mode, "survival")    == 0
       )
    {
        // PVE
        return Plugin_Continue;
    }

    if (strncmp(command[0], "ChangeLevel", strlen(command[0]), false) == 0)
    {
        if (StrContains(command[1], "_night", false) != -1)
        {
            Chat(client, "{red}你这种P民还想投票换夜战图?");
            return Plugin_Handled;
        }
        return Plugin_Continue;
    }

    return Plugin_Continue;
}