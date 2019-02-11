#pragma semicolon 1
#pragma newdecls required

#include <smutils>

public Plugin myinfo = 
{
    name        = "No Accessory",
    author      = "Kyle",
    description = "<- description ->",
    version     = "1.0",
    url         = "https://www.kxnrl.com"
};

static int g_iTotalUsed[MAXPLAYERS+1];

public void OnPluginStart()
{
    SMUitls_InitUserMessage();
    SMUtils_SetChatPrefix("[{purple}魔法少女{white}]");
    SMUtils_SetChatSpaces("   ");

    HookEvent("player_spawn", Event_Spawn, EventHookMode_Post);

    for (int client = MinClients; client <= MaxClients; ++client)
        if (IsClientConnected(client))
            OnClientConnected(client);
}

public void OnClientConnected(int client)
{
    g_iTotalUsed[client] = 0;
}

public void Event_Spawn(Event e, const char[] name, bool db)
{
    int client = GetClientOfUserId(e.GetInt("userid"));
    g_iTotalUsed[client] = 0;
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
    if (IsPlayerAlive(client))
    {
        if (buttons & IN_ACCESSORY)
        {
            static int nextPrint[MAXPLAYERS+1];
            
            buttons &= ~IN_ACCESSORY;
            
            int time = GetTime();

            if (time > nextPrint[client])
            {
                EasyMissionHint(client, 10.0, Icon_alert_red, 233, 0, 0, "本服务器禁止使用夜视仪");
                nextPrint[client] = time + 15;
            }

            if (++g_iTotalUsed[client] > 3)
            {
                EasyMissionHint(client, 10.0, Icon_alert_red, 233, 0, 0, "您因为试图卡BUG被处死");
                ForcePlayerSuicide(client);
            }
        }
    }

    return Plugin_Continue;
}