#pragma semicolon 1
#pragma newdecls required

//extention base
#include <kmessager>

//plugin base
#include <kcf_core>

// ...
#include <smutils>


public Plugin myinfo = 
{
    name        = "Insurgency PVP analytics",
    author      = "Kyle",
    description = "<- description ->",
    version     = "1.0",
    url         = "https://www.kxnrl.com"
};

enum struct arrays_t
{
    ArrayList m_Index;
    ArrayList m_Score;
    int       m_Total;
}

enum struct client_t
{
    int   m_CPId;
    int   m_CRank;
    float m_CScore;
}

static arrays_t g_Arrays;
static client_t g_Client[MAXPLAYERS+1];

static int g_iServerMod = -1;

static Handle g_tTimeout;

static float g_fSessionScore[MAXPLAYERS+1];

#define CheckMod() if (g_iServerMod != 1001 && g_iServerMod != 1002) return

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    RegPluginLibrary("Insurgency-Statistics");

    return APLRes_Success;
}

public void OnPluginStart()
{
    SMUitls_InitUserMessage();
    SMUtils_SetChatPrefix("[{purple}魔法少女{white}]");
    SMUtils_SetChatSpaces("   ");

    g_Arrays.m_Index = new ArrayList(1);
    g_Arrays.m_Score = new ArrayList(9);
    
    g_iServerMod = KCF_Server_GetModId();
    
    CreateTimer(1800.0, Timer_RefreshData, _, TIMER_REPEAT);
}

public void KCF_OnServerLoaded(int sid, int mod)
{
    g_iServerMod = mod;
    
    fetchFromDB();
}

public Action Timer_RefreshData(Handle tiemr)
{
    fetchFromDB();
    return Plugin_Continue;
}

static void fetchFromDB()
{
    //CheckMod();

    kMessager_InitBuffer();
    kMessager_WriteShort("mid", g_iServerMod);
    kMessager_SendBuffer(Stats_IS_LoadAll);
    
    g_tTimeout = CreateTimer(30.0, Timer_Timeout);
}

public Action Timer_Timeout(Handle timer)
{
    g_tTimeout = null;
    fetchFromDB();
    LogError("fetchFromDB -> timeout");
    return Plugin_Stop;
}

public void KCF_OnClientLoaded(int client, int pid)
{
    fetchClientData(pid);
}

static void fetchClientData(int pid)
{
    int client = KCF_Client_FindByPId(pid);
    if (client == -1)
        return;

    kMessager_InitBuffer();
    kMessager_WriteInt32("pid", pid);
    kMessager_SendBuffer(Stats_IS_LoadUser);

    int _i = g_Arrays.m_Index.FindValue(pid);
    if (_i > 0)
    {
        g_Client[client].m_CPId   = pid;
        g_Client[client].m_CRank  = _i;
        g_Client[client].m_CScore = g_Arrays.m_Score.Get(_i);
    }
}

public void kMessager_OnRecv(Message_Type type)
{
    switch (type)
    {
        case Stats_IS_LoadUser: LoadClientData();
        case Stats_IS_LoadAll : LoadAllData();
    }
}

static void LoadClientData()
{
    int pid = kMessager_ReadInt32("pid");

    int client = KCF_Client_FindByPId(pid);
    if (client == -1)
        return;

    // to do
    // ......

    // printMessage
    CreateTimer(5.0, Timer_Welcome, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

static void LoadAllData()
{
    if (!kMessager_ReadArray())
    {
        LogError("array data is not an array?");
        return;
    }
    
    StopTimer(g_tTimeout);
    
    g_Arrays.m_Index.Clear();
    g_Arrays.m_Score.Clear();
    
    g_Arrays.m_Index.Push(0);
    g_Arrays.m_Score.Push(0);
    
    g_Arrays.m_Total = 0;

    int _p;
    float _s;
    do
    {
        _p = kMessager_ReadInt32("pid");
        _s = kMessager_ReadFloat("score");

        g_Arrays.m_Index.Push(_p);
        g_Arrays.m_Score.Push(_s);

        g_Arrays.m_Total++;
    }
    while (kMessager_NextArray());
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
    g_Client[client].m_CPId   = -1;
    g_Client[client].m_CRank  = -1;
    g_Client[client].m_CScore = 0.0;

    g_fSessionScore[client] = 0.0;
}

public Action Timer_Welcome(Handle timer, int userid)
{
    printMessage(GetClientOfUserId(userid));
    return Plugin_Stop;
}

static void printMessage(int client)
{
    if (client == 0) return;

    char hostname[128];
    FindConVar("hostname").GetString(hostname, 128);

    Chat(client, "{green}欢迎来到 {white}[{lime}%s{white}] {green}服务器", hostname);
    Chat(client, "{green}本服务器已启用技巧分/数据统计.");

    int onlines = KCF_Client_GetOnlinetimes(client);

    int h =  onlines /  3600;
    int m = (onlines - (3600 * h)) / 60;

    if (g_Client[client].m_CRank > 0)
    {
        if (g_Client[client].m_CRank < 100)
        {
            SMUtils_SkipNextPrefix();
            ChatAll(" {purple} -> {green}欢迎dalao {orange}%N {green} 进入游戏, 排名 {blue} %d {silver}/{green} %d", client, g_Client[client].m_CRank, g_Arrays.m_Total);
            Chat(client, "{green}您的技巧分为{silver}: {blue}%.2f {green}分{silver}, {green}在线时长{silver}: {blue}%d{green}小时{blue}%d{green}分钟{silver}.", g_Client[client].m_CScore, h, m);
        }
        else
        {
            Chat(client, "{green}您的技巧分为{silver}: {blue}%.2f {green}分{silver}, {green}在线时长{silver}: {blue}%d{green}小时{blue}%d{green}分钟{silver}.", g_Client[client].m_CScore, h, m);
            Chat(client, "{green}您的总排名为{silver}: {blue} %d {silver}/{green} %d", g_Client[client].m_CRank, g_Arrays.m_Total);
        }
    }
    else
    {
        Chat(client, "{green}您的游戏时长不足或总场数不足, 无法计算技巧分");
    }
}
