#pragma semicolon 1
#pragma newdecls required

//extention base
#include <kmessager>

//plugin base
#include <kcf_core>
#include <kcf_bans>

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
    int m_VIP;
    int m_Expired;
    bool m_bWeight;
    int m_iWeight;
    int m_iKicker;
};

data_t g_Client[MAXPLAYERS+1];

int g_iServerMod = -1;

enum struct Cooldown_t
{
    StringMap Kick;
    StringMap Bans;
    StringMap Maps;
}
Cooldown_t g_smCooldown;

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

    g_smCooldown.Kick = new StringMap();
    g_smCooldown.Bans = new StringMap();

    HookEvent("player_spawn",   Event_Spawned, EventHookMode_Post);
    HookEvent("player_team",    Event_Team,    EventHookMode_Post);
    HookEvent("weapon_deploy",  Event_Deploy,  EventHookMode_Post);

    RegConsoleCmd("spt", CmdHandler);
    RegConsoleCmd("vip", CmdHandler);
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
    g_Client[client].m_VIP     = 0;
    g_Client[client].m_Expired = 0;
    g_Client[client].m_iKicker = 0;
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
    g_Client[client].m_VIP = l;

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
        case 0: Chat(client, "{green}您还不是我们的支持者, 加入支持者计划可以享受相应的福利待遇, 详情请加QQ群[{red}385224955{green}].");
        default:
        {
            Chat(client, "{green}欢迎回来, 您的支持者计划到期时间为: {orange}%s {green}, Level: {orange} %d", GetExpiredTime(client), g_Client[client].m_VIP);
            EarnSupplyPoint(client);
        }
    }

    return Plugin_Stop;
}

public void Event_Spawned(Event e, const char[] name, bool dB)
{
    int userid = e.GetInt("userid");
    int client = GetClientOfUserId(userid);
    g_Client[client].m_bWeight = false;
    g_Client[client].m_iWeight = GetEntProp(client, Prop_Send, "m_iCarryWeight");
    RequestFrame(FrameFilter, e.GetInt("userid"));
}

static void FrameFilter(int userid)
{
    int client = GetClientOfUserId(userid);

    if (!client)
        return;

    char buffer[32];
    GetClientName(client, buffer, 32);

    if (StrContains(buffer, "[Supporter]", false) != -1)
    {
        if (g_Client[client].m_VIP == 0)
        {
            if (++g_Client[client].m_iKicker >= 3)
            {
                if (!KCF_Ban_BanClient(0, client, 0, 10086, "你以为改了个名就是Supporter了吗"))
                {
                    // error
                    LogError("Failed to ban \"%L\".");
                }
                return;
            }
            // do this shit...
            ReplaceString(buffer, 32, "[Supporter]", "[FuckMe]", false);
        }
        else
        {
            // ignored
            return;
        }
    }
    else if (g_Client[client].m_VIP > 0)
    {
        // re-format
        Format(buffer, 32, "[Supporter] %s", buffer);
    }

    SetClientName(client, buffer);
}

public void Event_Deploy(Event e, const char[] name, bool dB)
{
    RequestFrame(FrameWeight, e.GetInt("userid"));
}

static void FrameWeight(int userid)
{
    int client = GetClientOfUserId(userid);

    if (!client || g_Client[client].m_VIP == 0 || !IsPlayerAlive(client))
        return;

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

    if (m_nCarryWeight == m_iCarryWeight)
        return;

    SetEntProp(client, Prop_Send, "m_iCarryWeight", m_iCarryWeight);
    Chat(client, "{red}>{green}>{blue}> {yellow}支持者计划: {lime}负重已减轻{green}%d%%{lime}[{green}%.1fkg{lime}({yellow}%.1f{lime})]", RoundToCeil(ReduceWeight * 100), m_iCarryWeight * 0.1, m_nCarryWeight * 0.1);

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
    int tokens = GetEntProp(client, Prop_Send, "m_nRecievedTokens");
    int counts = IncreasePoint(client);
    SetEntProp(client, Prop_Send, "m_nRecievedTokens", tokens + counts);
    Chat(client, "{red}>{green}>{blue}> {yellow}支持者计划: {lime}您可以获得额外的 {purple}%d{lime} 补给点.", counts);
}

static int IncreasePoint(int client)
{
    int levels = g_Client[client].m_VIP;
    int counts = 0;
    switch (g_iServerMod)
    {
        case 1002: counts = RoundToFloor(levels * 1.5);
        case 1050: counts = RoundToFloor(levels * 2.1);
        case 1051: counts = RoundToFloor(levels * 2.8);
        case 1052: counts = RoundToFloor(levels * 3.5);
        default  : counts = levels;
    }
    return counts;
}

static float DecreaseWeight(int client)
{
    int level = g_Client[client].m_VIP;
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

static float GetProtectTime(int client)
{
    int level = g_Client[client].m_VIP;
    return 8.0 + level * 1.5;
}

public Action CmdHandler(int client, int args)
{
    if (g_Client[client].m_VIP == 0)
    {
        Chat(client, "{green}您还不是我们的支持者, 加入支持者计划可以享受相应的福利待遇, 详情请加QQ群[{red}385224955{green}].");
        return Plugin_Handled;
    }

    SupporterMenu(client);

    return Plugin_Handled;
}

static void SupporterMenu(int client)
{
    char buffer[128];

    Panel panel = new Panel();

    FormatEx(buffer, 128, "[Supporter]  支持者计划");
    panel.SetTitle(buffer);
    panel.DrawText("    ");

    FormatEx(buffer, 128, "等级: %d", g_Client[client].m_VIP);
    panel.DrawText(buffer);
    FormatEx(buffer, 128, "到期: %d", GetExpiredTime(client));
    panel.DrawText(buffer);
    panel.DrawText("    ");

    FormatEx(buffer, 128, "额外点数: %dp",  IncreasePoint(client));
    panel.DrawText(buffer);

    FormatEx(buffer, 128, "出生保护: %ds", RoundToCeil(GetProtectTime(client)));
    panel.DrawText(buffer);

    FormatEx(buffer, 128, "负重减轻: %d%%", RoundToCeil(DecreaseWeight(client) * 100));
    panel.DrawText(buffer);
    panel.DrawText("    ");

    panel.DrawItem("踢出玩家");
    panel.DrawItem("封禁玩家");
    panel.DrawItem("更换地图");
    panel.DrawText("       ");

    panel.DrawItem("Exit");

    panel.Send(client, PanelHandler, 15);
}

public int PanelHandler(Menu menu, MenuAction action, int client, int slot)
{
    if (action == MenuAction_End)
        delete menu;
    else if (action == MenuAction_Select)
    {
        switch (slot)
        {
            case 0: KickMenu(client);
            case 1: BansMenu(client);
            case 2: Chat(client, "功能已被禁用...");
        }
    }
}

static void KickMenu(int client)
{
    if (g_Client[client].m_VIP < 3)
    {
        Chat(client, "{silve}您的等级不够{red}3{silve}级,不能使用本功能...");
        return;
    }

    int cd = Cooldown(client, 0);
    if (cd > 0)
    {
        Chat(client, "该功能正在冷却中...  剩余{green}%d秒", cd);
        return;
    }

    Menu menu = new Menu(KickHandler);

    char buffer[2][128];

    for (int target = 1; target <= MaxClients; ++target)
    {
        if (!IsClientInGame(target) || KCF_Admin_IsClientAdmin(target) || g_Client[target].m_VIP > 0)
            continue;

        FormatEx(buffer[0], 128, "%d", GetClientUserId(target));
        FormatEx(buffer[1], 128, "[%02d] %N", target, target);

        menu.AddItem(buffer[0], buffer[1]);
    }

    menu.Display(client, 0);
}

public int KickHandler(Menu menu, MenuAction action, int client, int slot)
{
    if (action == MenuAction_End)
        delete menu;
    else if (action == MenuAction_Select)
    {
        char buffer[32];
        menu.GetItem(slot, buffer, 32);
        KickTarget(client, GetClientOfUserId(StringToInt(buffer)));
    }
}

static void KickTarget(int client, int target)
{
    if (!IsClientInGame(target))
    {
        Chat(client, "目标当前不在服务器");
        return;
    }

    KickClient(target, "您已被支持者用户踢出服务器.\n操作人: %N", client);
    ChatAll("{blue}%N{silver}使用支持者权限踢出玩家{red}%N{silver}.", client, target);
    SetCooldown(client, 0);
}

static void BansMenu(int client)
{
    if (g_Client[client].m_VIP < 4)
    {
        Chat(client, "{silve}您的等级不够{red}4{silve}级,不能使用本功能...");
        return;
    }

    int cd = Cooldown(client, 1);
    if (cd > 0)
    {
        Chat(client, "该功能正在冷却中...  剩余{green}%d秒", cd);
        return;
    }

    Menu menu = new Menu(BansHandler);

    char buffer[2][128];

    for (int target = 1; target <= MaxClients; ++target)
    {
        if (!IsClientInGame(target) || KCF_Admin_IsClientAdmin(target) || g_Client[target].m_VIP > 0)
            continue;

        FormatEx(buffer[0], 128, "%d", GetClientUserId(target));
        FormatEx(buffer[1], 128, "[%02d] %N", target, target);

        menu.AddItem(buffer[0], buffer[1]);
    }

    menu.Display(client, 0);
}

public int BansHandler(Menu menu, MenuAction action, int client, int slot)
{
    if (action == MenuAction_End)
        delete menu;
    else if (action == MenuAction_Select)
    {
        char buffer[32];
        menu.GetItem(slot, buffer, 32);
        BanTarget(client, GetClientOfUserId(StringToInt(buffer)));
    }
}

static void BanTarget(int client, int target)
{
    if (!IsClientInGame(target))
    {
        Chat(client, "目标当前不在服务器");
        return;
    }

    char reason[128];
    FormatEx(reason, 128, "您已被[%N]封禁于当前服务器60分钟.", client);
    KCF_Ban_BanClient(0, target, 3, 60, reason);
    ChatAll("{blue}%N{silver}使用支持者权限封禁玩家{red}%N{silver}60分钟.", client, target);
    SetCooldown(client, 1);
}

static int Cooldown(int client, int type)
{
    char steamid[32];
    GetClientAuthId(client, AuthId_SteamID64, steamid, 32, false);
    int value = -1;
    switch (type)
    {
        case 0: if (!g_smCooldown.Kick.GetValue(steamid, value)) return -1;
        case 1: if (!g_smCooldown.Bans.GetValue(steamid, value)) return -1;
    }
    return value - GetTime();
}

static void SetCooldown(int client, int type)
{
    char steamid[32];
    GetClientAuthId(client, AuthId_SteamID64, steamid, 32, false);
    switch (type)
    {
        case 0: g_smCooldown.Kick.SetValue(steamid, GetTime() + 3600 * 3, true);
        case 1: g_smCooldown.Bans.SetValue(steamid, GetTime() + 3600 * 3, true);
    }
}