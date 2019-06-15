#pragma semicolon 1
#pragma newdecls required

//extention base
#include <kmessager>

//plugin base
#include <kcf_core>

// ...
#include <smutils>
#include <ins_supporter>

public Plugin myinfo = 
{
    name        = "Supporter",
    author      = "Kyle",
    description = "<- description ->",
    version     = "1.0",
    url         = "https://www.kxnrl.com"
};

enum struct data_t
{
    bool m_Loaded;
    vip_t m_VIP;
    int m_Expired;
    bool m_bWeight;
    int m_iWeight;
};

data_t g_Client[MAXPLAYERS+1];

int g_iServerMod = -1;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    RegPluginLibrary("Insurgency-Supporter");

    CreateNative("Ins_GetSupporter",            Native_IsSupporter);
    CreateNative("Ins_GetSupporterExpiredDate", Native_ExpiredDate);

    return APLRes_Success;
}

public any Native_IsSupporter(Handle plugin, int params)
{
    return g_Client[GetNativeCell(1)].m_VIP;
}

public any Native_ExpiredDate(Handle plugin, int params)
{
    return g_Client[GetNativeCell(1)].m_Expired;
}

public void OnPluginStart()
{
    SMUitls_InitUserMessage();
    SMUtils_SetChatPrefix("[{purple}魔法少女{white}]");
    SMUtils_SetChatSpaces("   ");

    g_iServerMod = KCF_Server_GetModId();

    HookEvent("player_spawn",   Event_Spawned, EventHookMode_Post);
    HookEvent("player_team",    Event_Team,    EventHookMode_Post);
    HookEvent("weapon_deploy",  Event_Deploy,  EventHookMode_Post);
}

public void KCF_OnServerLoaded(int sid, int mod)
{
    g_iServerMod = mod;
}

public void KCF_OnClientLoaded(int client, int pid)
{
    fetchClientData(pid);
}

public void OnClientConnected(int client)
{
    resetClient(client);
}

public void OnClientDisconnect_Post(int client)
{
    resetClient(client);
}

static void resetClient(int client)
{
    g_Client[client].m_Loaded  = false;
    g_Client[client].m_VIP     = vip_None;
    g_Client[client].m_Expired = 0;
}

static void fetchClientData(int pid)
{
    int client = KCF_Client_FindByPId(pid);
    if (client == -1)
        return;

    kMessager_InitBuffer();
    kMessager_WriteInt32("pid", pid);
    kMessager_SendBuffer(Vip_LoadUser);

    CreateTimer(10.0, LoadUserTimeout, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

public void kMessager_OnRecv(Message_Type type)
{
    switch (type)
    {
        case Vip_LoadUser: LoadClientData();
    }
}

static void LoadClientData()
{
    int pid = kMessager_ReadInt32("pid");

    int client = KCF_Client_FindByPId(pid);
    if (client == -1)
        return;

    int e = kMessager_ReadInt32("end");
    int l = kMessager_ReadInt32("lvl");

    g_Client[client].m_Expired = e;
    g_Client[client].m_Loaded = true;
    g_Client[client].m_VIP = view_as<vip_t>(l);

    // printMessage
    CreateTimer(8.0, WelcomeMessage, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

public Action LoadUserTimeout(Handle timer, int userid)
{
    int client = GetClientOfUserId(userid);
    if (!client || g_Client[client].m_Loaded) return Plugin_Stop;

    LoadClientData();

    return Plugin_Stop;
}

public Action WelcomeMessage(Handle timer, int userid)
{
    int client = GetClientOfUserId(userid);
    if (!client) return Plugin_Stop;

    switch (g_Client[client].m_VIP)
    {
        case vip_None: Chat(client, "{green}您还不是我们的支持者, 加入支持者计划可以享受相应的福利待遇, 详情请加QQ群[{red}385224955{green}].");
        default:
        {
            Chat(client, "{green}欢迎回来, 您的支持者计划到期时间为: {orange}%s {green}, Level: {orange} %d", GetExpiredTime(client), view_as<int>(g_Client[client].m_VIP));
            EarnSupplyPoint(client);
        }
    }

    return Plugin_Stop;
}

public void Event_Spawned(Event e, const char[] name, bool dB)
{
    int client = GetClientOfUserId(e.GetInt("userid"));
    g_Client[client].m_bWeight = false;
    g_Client[client].m_iWeight = GetEntProp(client, Prop_Send, "m_iCarryWeight");
}

public void Event_Deploy(Event e, const char[] name, bool dB)
{
    RequestFrame(FrameWeight, e.GetInt("userid"));
}

static void FrameWeight(int userid)
{
    static nextPrint[MAXPLAYERS+1];

    int client = GetClientOfUserId(userid);

    float ReduceWeight = DecreaseWeight(client);
    int m_iCarryWeight = GetEntProp(client, Prop_Send, "m_iCarryWeight");
    int m_nWeightCache = GetEntProp(client, Prop_Send, "m_nWeightCache");
    int m_nCarryWeight = m_iCarryWeight;
    
    if (m_iCarryWeight == m_nWeightCache)
    {
        m_iCarryWeight = RoundToCeil(m_nWeightCache * (1.0 - ReduceWeight));
    }
    else if (g_Client[client].m_bWeight)
    {
        int diff = g_Client[client].m_iWeight - m_iCarryWeight;
        int curl = RoundToCeil(diff * (1.0 - ReduceWeight));
        m_iCarryWeight = g_Client[client].m_iWeight - curl;
    }
    else
    {
        m_iCarryWeight = RoundToCeil(m_iCarryWeight * (1.0 - ReduceWeight)); 
    }

    int timestamp = GetTime();

    if (nextPrint[client] <= timestamp)
    {
        nextPrint[client] += 5;
        SetEntProp(client, Prop_Send, "m_iCarryWeight", m_iCarryWeight);
        Chat(client, "{red}>{green}>{blue}> {yellow}支持者计划: {lime}负重已减轻{green}%d%%{lime}[{green}%.1fkg{lime}({yellow}%.1f{lime})]", RoundToCeil(ReduceWeight * 100), m_iCarryWeight * 0.1, m_nCarryWeight * 0.1);
    }

    g_Client[client].m_bWeight = true;
    g_Client[client].m_iWeight = GetEntProp(client, Prop_Send, "m_iCarryWeight");
}

public void Event_Team(Event e, const char[] name, bool dB)
{
    if (e.GetBool("disconnect") || e.GetInt("oldteam") == e.GetInt("team"))
        return;

    EarnSupplyPoint(GetClientOfUserId(e.GetInt("userid")));
}

static void EarnSupplyPoint(int client)
{
    int levels = view_as<int>(g_Client[client].m_VIP);
    int tokens = GetEntProp(client, Prop_Send, "m_nRecievedTokens");
    int counts = 0;
    switch (g_iServerMod)
    {
        case 1002: counts = RoundToFloor(levels * 1.5);
        case 1050: counts = RoundToFloor(levels * 2.1);
        case 1051: counts = RoundToFloor(levels * 2.8);
        case 1052: counts = RoundToFloor(levels * 3.5);
        default  : counts = levels;
    }
    SetEntProp(client, Prop_Send, "m_nRecievedTokens", tokens + counts);
    Chat(client, "{red}>{green}>{blue}> {yellow}支持者计划: {lime}您可以获得额外的 {purple}%d{lime} 补给点.", counts);
}

static float DecreaseWeight(int client)
{
    int level = view_as<int>(g_Client[client].m_VIP);
    return level * 0.08;
}

static char[] GetExpiredTime(int client)
{
    char buffer[64];

    if (g_Client[client].m_Expired == PERMANENT)
        buffer = "永久";
    else
        FormatTime(buffer, 64, "%Y-%m-%d", g_Client[client].m_Expired);

    return buffer;
}