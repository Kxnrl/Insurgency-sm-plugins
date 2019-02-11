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

public void OnPluginStart()
{
    SMUitls_InitUserMessage();
    SMUtils_SetChatPrefix("[{purple}魔法少女{white}]");
    SMUtils_SetChatSpaces("   ");

    HookEvent("player_first_spawn", Event_PlayerSpawn, EventHookMode_Post);
}

public void OnMapStart()
{
    CreateTimer(150.0, Timer_ServerAds, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public void Event_PlayerSpawn(Event e, const char[] name, bool dontBroadcast)
{
    int userid = e.GetInt("userid");
    int client = GetClientOfUserId(userid);

    if (IsFakeClient(client))
        return;

    CreateTimer(1.0, Timer_Welcome, userid, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
}

public Action Timer_Welcome(Handle timer, int userid)
{
    int client = GetClientOfUserId(userid);
    if (client)
    {
        if (!IsPlayerAlive(client))
            return Plugin_Continue;

        EasyMissionHint(client, 10.0, Icon_bulb , 0, 233, 0, "祝您游戏愉快");
        EasyMissionHint(client, 10.0, Icon_bulb, 0, 233, 0, "欢迎来到魔法少女服务器");
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

    if (++index > 2)
        index = 0;

    return Plugin_Continue;
}