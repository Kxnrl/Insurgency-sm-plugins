#pragma semicolon 1
#pragma newdecls required

#include <smutils>
#include <sdkhooks>

public Plugin myinfo = 
{
    name        = "Noob Protector",
    author      = "Kyle",
    description = "<- description ->",
    version     = "1.0",
    url         = "https://www.kxnrl.com"
};

static float g_fSpawnTime[MAXPLAYERS+1];

public void OnPluginStart()
{
    SMUitls_InitUserMessage();
    SMUtils_SetChatPrefix("[{purple}魔法少女{white}]");
    SMUtils_SetChatSpaces("   ");

    HookEvent("player_spawn", Event_Spawn, EventHookMode_Post);

    for(int client = MinClients; client <= MaxClients; ++client)
        if(IsClientInGame(client))
            OnClientPutInServer(client);
}

public void OnClientPutInServer(int client)
{
    SDKHook(client, SDKHook_OnTakeDamage, Event_TraceAlive);
}

public void Event_Spawn(Event e, const char[] name, bool db)
{
    int client = GetClientOfUserId(e.GetInt("userid"));
    g_fSpawnTime[client] = GetGameTime();
    
    //if(IsPlayerAlive(client))
    //Chat(client, "{pink}你现在有8秒的出生点爆炸物保护时间.");
}

public Action Event_TraceAlive(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
    if(attacker > MaxClients || attacker < MinClients) return Plugin_Continue;

    if(damagetype == DMG_BLAST) // explosion
    {
        if(GetGameTime() - g_fSpawnTime[victim] <= 8.0)
        {
            if(IsClientInGame(attacker))
            {
                Chat(victim,   "{blue}已免疫来自{green} %N {blue}的爆炸物伤害", attacker);
                Chat(attacker, "{green} %N {blue}处于出生爆炸物保护时间内",     victim);
            }
            return Plugin_Handled;
        }
    }

    return Plugin_Continue;
}