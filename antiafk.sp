#include <smutils>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = 
{
    name        = "Anti-AFK",
    author      = "Kyle",
    description = "<- description ->",
    version     = "1.0",
    url         = "https://www.kxnrl.com"
};

enum struct client_info_t
{
    bool  m_IsAFK;
    int   m_Count;
    float m_Angle;
}

static client_info_t g_Client[MAXPLAYERS+1];

public void OnPluginStart()
{
    SMUitls_InitUserMessage();
    SMUtils_SetChatPrefix("[{purple}魔法少女{white}]");
    SMUtils_SetChatSpaces("   ");
}

public void OnMapStart()
{
    CreateTimer(30.0, Timer_CheckPlayers, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
}

public void OnClientConnected(int client)
{
    resetPlayer(client);
}

public Action Timer_CheckPlayers(Handle timer, any unused)
{
    if(GetClientCount(false) <= 26)
        return Plugin_Continue;

    for(int client = MinClients; client <= MaxClients; ++client)
    {
        if(!ClientIsValid(client))
            continue;
        
        if(g_Client[client].m_IsAFK)
        {
            if(++g_Client[client].m_Count > 3)
            {
                KickClient(client, "[AFK] 挂机时间过长被踢出");
                continue;
            }
            Chat(client, "{red}警告{silver}:  {green}长时间无操作将会被踢出游戏{silver}.");
        }
        g_Client[client].m_IsAFK = true;
    }

    return Plugin_Continue;
}

public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2])
{
    if(IsFakeClient(client))
        return;

    if(mouse[0] || mouse[1] || g_Client[client].m_Angle != angles[0])
    {
        // reset
        resetPlayer(client);
    }

    g_Client[client].m_Angle = angles[0];
}

static void resetPlayer(int client)
{
    g_Client[client].m_IsAFK = false;
    g_Client[client].m_Count = 0;
}