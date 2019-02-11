#pragma semicolon 1
#pragma newdecls required

#include <kcf_core>
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

enum CINSGearType
{
    m_Gear_Armor  = 0, // 2 4
    m_Gear_Helmet = 1, // ?
    m_Gear_Pack   = 2, // 6 8
    m_Gear_Glass  = 3, // 10
    m_Gear_Recon  = 4, // ?
    //m_Gear_Unknow = 5,
    //m_Gear_Unknow = 6,
}

enum CINSArmorType
{
    Armor_None  = -1,
    Armor_Light = 2,
    Armor_Heavy = 4
}

static float g_fSpawnTime[MAXPLAYERS+1];

static int   g_iServerId = -1;

static int   g_iOffset   = -1;

public void OnPluginStart()
{
    SMUitls_InitUserMessage();
    SMUtils_SetChatPrefix("[{purple}魔法少女{white}]");
    SMUtils_SetChatSpaces("   ");

    HookEvent("player_spawn", Event_Spawn, EventHookMode_Post);

    for(int client = MinClients; client <= MaxClients; ++client)
        if (IsClientInGame(client))
            OnClientPutInServer(client);
        
    g_iServerId = KCF_Server_GetSrvId();

    g_iOffset = FindSendPropInfo("CINSPlayer", "m_EquippedGear");
}

public void KCF_OnServerLoaded(int sid, int mod)
{
    g_iServerId = sid;
}

public void OnClientPutInServer(int client)
{
    if (IsFakeClient(client))
        return;
    
    SDKHook(client, SDKHook_OnTakeDamage, Event_TraceAlive);
}

public void Event_Spawn(Event e, const char[] name, bool db)
{
    int client = GetClientOfUserId(e.GetInt("userid"));
    g_fSpawnTime[client] = GetGameTime();
}

public Action Event_TraceAlive(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
    if (attacker > MaxClients || attacker < MinClients) return Plugin_Continue;

    if (damagetype == DMG_BLAST)
    {
        if (g_iServerId == 12 || g_iServerId == 13)
        {
            switch (GetPlayerArmorType(victim))
            {
                case Armor_Light:
                {
                    damage *= 0.8;
                    return Plugin_Changed;
                }
                case Armor_Heavy:
                {
                    damage *= 0.6;
                    return Plugin_Changed;
                }
                case Armor_None : return Plugin_Continue;
                default:          return Plugin_Continue;
            }
        }
        
        if (attacker == victim)
            return Plugin_Continue;

        if (GetGameTime() - g_fSpawnTime[victim] <= 8.0)
        {
            if (IsClientInGame(attacker))
            {
                Chat(victim,   "{blue}已免疫来自{green} %N {blue}的爆炸物伤害", attacker);
                Chat(attacker, "{green} %N {blue}处于出生爆炸物保护时间内",     victim);
            }
            return Plugin_Handled;
        }
    }

    return Plugin_Continue;
}

stock CINSArmorType GetPlayerArmorType(int client)
{
    return view_as<CINSArmorType>(GetEntData(client, g_iOffset + (4 * view_as<int>(m_Gear_Armor))));
}