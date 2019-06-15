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

static ArrayList histories = null;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    RegPluginLibrary("Insurgency-NoMapVote");

    return APLRes_Success;
}

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
    
    histories = new ArrayList(ByteCountToCells(128));
}

public void OnMapStart()
{
    char map[128];
    GetCurrentMap(map, 128);
    histories.PushString(map);
    
    if (histories.Length > 3)
        histories.Erase(0);
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
            char map[128];

            for (int index = 0; index < histories.Length; ++index)
            {
                histories.GetString(index, map, 128);

                if (StrContains(map, "_night", false) != -1)
                {
                    Chat(client, "{red}最近3张地图以内已经玩过夜战图了.");
                    return Plugin_Handled;
                }
            }
        }

        return Plugin_Continue;
    }

    return Plugin_Continue;
}