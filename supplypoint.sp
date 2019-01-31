#pragma semicolon 1
#pragma newdecls required

#include <smutils>
#include <sdkhooks>

public Plugin myinfo = 
{
    name        = "More supply point",
    author      = "Kyle",
    description = "<- description ->",
    version     = "1.0",
    url         = "https://www.kxnrl.com"
};

#define SUPPLY 50

public void OnPluginStart()
{
    // Supply
    HookEvent("player_spawn", Event_Supply, EventHookMode_Post);
    HookEvent("player_death", Event_Supply, EventHookMode_Post);
    HookEvent("player_team",  Event_Supply, EventHookMode_Post);
}

public void Event_Supply(Event e, const char[] name, bool db)
{
    int client = GetClientOfUserId(e.GetInt("userid"));

    int Tokens = GetEntProp(client, Prop_Send, "m_nRecievedTokens");
    SetEntProp(client, Prop_Send, "m_nRecievedTokens", SUPPLY);

    PrintToConsole(client, "[More Supply Point]   Earned %d supply points. [O: %d]", SUPPLY, Tokens);
}