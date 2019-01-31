#pragma semicolon 1
#pragma newdecls required

#include <smutils>

public Plugin myinfo = 
{
    name        = "Server Advertisement",
    author      = "Kyle",
    description = "<- description ->",
    version     = "1.0",
    url         = "https://www.kxnrl.com"
};

static bool bPrinted[MAXPLAYERS+1];

public void OnPluginStart()
{
    SMUitls_InitUserMessage();
    SMUtils_SetChatPrefix("[{purple}魔法少女{white}]");
    SMUtils_SetChatSpaces("   ");

    HookEvent("player_spawn",  Event_PlayerSpawn, EventHookMode_Post);
}

public void OnMapStart()
{
    CreateTimer(120.0, Timer_ServerAds, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public void OnClientPutInServer(int client)
{
    bPrinted[client] = false;
}

public void Event_PlayerSpawn(Event e, const char[] name, bool dontBroadcast)
{
    int userid = e.GetInt("userid");
    int client = GetClientOfUserId(userid);
    if(!bPrinted[client] && IsPlayerAlive(client))
        CreateTimer(5.0, Timer_Welcome, userid, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_Welcome(Handle timer, int client)
{
    client = GetClientOfUserId(client);
    if(client)
    {
        bPrinted[client] = true;
        Hint(client, "欢迎来到魔法少女服务器\n祝您游戏愉快");
    }
    return Plugin_Stop;
}

public Action Timer_ServerAds(Handle timer)
{
    static int index = 0;
    
    switch(index)
    {
        case 0: ChatAll("QQ群: {green}385224955");
        case 1: ChatAll("官方网站: {green}https://magicgirl.net");
        case 2: ChatAll("按Y输入{green}!sign{white}即可进行签到");
    }

    if(++index > 2)
        index = 0;

    return Plugin_Continue;
}