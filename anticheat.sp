#pragma semicolon 1
#pragma newdecls required

//sourcemod base
#include <sourcemod>

//plugin base
#include <kcf_core>
#include <kcf_bans>

// ...
#include <smutils>
#include <ins_supporter>

public Plugin myinfo = 
{
    name        = "Anti Cheat",
    author      = "Kyle",
    description = "<- description ->",
    version     = "1.0",
    url         = "https://www.kxnrl.com"
};

enum struct Data {
    int m_Kills;
    int m_Death;
    int m_NadeKillStreak;
    int m_NadeKillsTrack;
    int m_TeamKillStreak;
    int m_TeamKillsTrack;
    int m_NoobSpawnTrack;
}

Data g_Client[MAXPLAYERS+1];
StringMap g_Queue;

public void OnPluginStart()
{
    SMUitls_InitUserMessage();
    SMUtils_SetChatPrefix("[{purple}魔法少女{white}]");
    SMUtils_SetChatSpaces("   ");

    HookEvent("player_spawn", Event_OnSpawn, EventHookMode_Post);
    HookEvent("player_death", Event_OnDeath, EventHookMode_Post);

    g_Queue = new StringMap();
}

public void OnClientConnected(int client)
{
    g_Client[client].m_Kills = 0;
    g_Client[client].m_Death = 0;

    resetClient(client);
}

static void resetClient(int client)
{
    g_Client[client].m_NadeKillStreak = 0;
    g_Client[client].m_NadeKillsTrack = 0;
    g_Client[client].m_TeamKillStreak = 0;
    g_Client[client].m_TeamKillsTrack = 0;
    g_Client[client].m_NoobSpawnTrack = GetTime();
}

public void Event_OnSpawn(Event e, const char[] name, bool db)
{
    resetClient(GetClientOfUserId(e.GetInt("userid")));
}

public void Event_OnDeath(Event e, const char[] name, bool db)
{
    int killer = GetClientOfUserId(e.GetInt("attacker"));
    int victim = GetClientOfUserId(e.GetInt("userid"));

    if (IsClientInQueue(killer))
        return;

    if (killer == victim)
        return;
    
    int currentTime = GetTime();

    if (GetClientTeam(killer) == GetClientTeam(victim))
    {
        if (++g_Client[killer].m_TeamKillStreak < 2)
        {
            // ignore
            g_Client[killer].m_TeamKillsTrack = currentTime;
            return;
        }

        int diff = currentTime - g_Client[killer].m_TeamKillsTrack;

        if (diff < 30)
        {
            //ForcePlayerSuicide(killer);
            ChatAll("{red}%N{silver}因为恶意TK被放风筝并减少1点补给点...", killer);
            SetEntProp(killer, Prop_Send, "m_nRecievedTokens", GetEntProp(killer, Prop_Send, "m_nRecievedTokens")-1);
            CreateTimer(0.5, Timer_Kite, e.GetInt("attacker"), TIMER_REPEAT);
        }
        else if (diff < 15)
        {
            ChatAll("{red}%N{silver}因为恶意TK已被封禁...", killer);
            KCF_Ban_BanClient(0, killer, 0, 120, "恶意TK队友");
        }

        // done;
        g_Client[killer].m_TeamKillsTrack = currentTime;
        return;
    }

    g_Client[victim].m_Death++;

    char weapon[32];
    e.GetString("weapon", weapon, 32);

    // explosion
    if (StrContains(weapon, "grenade", false) != -1 || StrContains(weapon, "rocket", false) != -1)
    {
        int diff = currentTime - g_Client[killer].m_NadeKillsTrack;

        if (diff > 10)
        {
            // ignore
            g_Client[killer].m_NadeKillsTrack = currentTime;
            g_Client[killer].m_NadeKillStreak = 0;
            return;
        }

        int time = currentTime - g_Client[victim].m_NoobSpawnTrack;

        if (time > 15)
        {
            // ignore
            g_Client[killer].m_NadeKillsTrack = currentTime;
            return;
        }

        g_Client[killer].m_NadeKillStreak++;

        if (g_Client[killer].m_NadeKillStreak >= 6)
        {
            ChatAll("{red}%N{silver}因为数据异常已被制裁60分钟...", killer);
            KCF_Ban_BanClient(0, killer, 2, 60, "侦测到数据异常[0x0D]");
            ClientEnqueue(killer, 60);
        }
        else if (g_Client[killer].m_NadeKillStreak >= 3)
        {
            ChatAll("{red}%N{silver}因为数据异常已被处死...", killer);
            ForcePlayerSuicide(killer);
        }

        // done;
        return;
    }

    g_Client[killer].m_Kills++;

    if (g_Client[killer].m_Kills < 30)
        return;

    float kd = g_Client[killer].m_Kills / float(g_Client[killer].m_Death == 0 ? 1 : g_Client[killer].m_Death);

    if (kd >= 10.0)
    {
        ChatAll("{red}%N{silver}因为数据异常已被制裁10080分钟...", killer);
        KCF_Ban_BanClient(0, killer, 2, 10080, "侦测到数据异常[0x0A]");
        ClientEnqueue(killer, 10080);
    }
    else if (kd >= 8.0)
    {
        ChatAll("{red}%N{silver}因为数据异常已被制裁1440分钟...", killer);
        KCF_Ban_BanClient(0, killer, 2, 1440, "侦测到数据异常[0x0B]");
        ClientEnqueue(killer, 1440);
    }
    else if (kd >= 6.0)
    {
        ChatAll("{red}%N{silver}因为数据异常已被制裁60分钟...", killer);
        KCF_Ban_BanClient(0, killer, 2, 60, "侦测到数据异常[0x0C]");
        ClientEnqueue(killer, 60);
    }
}

public Action Timer_Kite(Handle timer, int userid)
{
    int client = GetClientOfUserId(userid);
    if (!client || !IsClientInGame(client) || !IsPlayerAlive(client))
        return Plugin_Stop;

    if (GetClientHealth(client) <= 2)
        ForcePlayerSuicide(client);
    else
        SlapPlayer(client, 2, true);

    return Plugin_Continue;
}

static bool IsClientInQueue(int client)
{
    char authid[32];
    GetClientAuthId(client, AuthId_SteamID64, authid, 32);

    int value = -1;
    if (!g_Queue.GetValue(authid, value))
        return false;

    return GetTime() <= value;
}

static bool ClientEnqueue(int client, int minutes)
{
    char authid[32];
    GetClientAuthId(client, AuthId_SteamID64, authid, 32);
    return g_Queue.SetValue(authid, GetTime() + minutes * 60, true);
}