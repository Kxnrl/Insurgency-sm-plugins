#pragma semicolon 1
#pragma newdecls required

#include <smutils>
#include <sdkhooks>

public Plugin myinfo = 
{
    name        = "More inventory weight",
    author      = "Kyle",
    description = "<- description ->",
    version     = "1.0",
    url         = "https://www.kxnrl.com"
};

static bool g_bSpawnZone[MAXPLAYERS+1];

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    RegPluginLibrary("Insurgency-MoreInvWeight");

    return APLRes_Success;
}

public void OnPluginStart()
{
    // weight
    HookEvent("player_spawn",    Event_Enter,  EventHookMode_Post);
    HookEvent("enter_spawnzone", Event_Enter,  EventHookMode_Post);
    HookEvent("exit_spawnzone",  Event_Exited, EventHookMode_Post);
    
    // timer
    CreateTimer(0.1, Timer_ResetCache, _, TIMER_REPEAT);
}

public Action Timer_ResetCache(Handle timer)
{
    for(int client = MinClients; client <= MaxClients; ++client)
        if (ClientIsAlive(client) && g_bSpawnZone[client])
            SetEntProp(client, Prop_Send, "m_nWeightCache", 0);
    return Plugin_Continue;
}

public void Event_Enter(Event e, const char[] name, bool dB)
{
    g_bSpawnZone[GetClientOfUserId(e.GetInt("userid"))] = true;
}

public void Event_Exited(Event e, const char[] name, bool dB)
{
    g_bSpawnZone[GetClientOfUserId(e.GetInt("userid"))] = false;
} 