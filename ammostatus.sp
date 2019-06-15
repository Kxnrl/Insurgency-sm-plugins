#pragma semicolon 1
#pragma newdecls required

#include <sdktools>
#include <sdkhooks>
#include <smutils>

public Plugin myinfo = 
{
    name        = "Ammo status",
    author      = "Kyle",
    description = "<- description ->",
    version     = "1.0",
    url         = "https://www.kxnrl.com"
};

/* OFFSETS
LIN WIN      Function
324	323	CINSWeapon::GetMaxClip1() const
325	324	CINSWeapon::GetMaxClip2() const
332	331	CINSWeapon::GetSlot() const
*/

#define GetMaxClip1 323


static int g_iAmmoOffset;
static Handle g_SDKGetClip;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    RegPluginLibrary("Insurgency-AmmoStatus");

    return APLRes_Success;
}

public void OnPluginStart()
{
    if (GetEngineVersion() != Engine_Insurgency)
        SetFailState("This plugin only work for Insurgency:Source.");
    
    SMUitls_InitUserMessage();
    
    HookEvent("weapon_reload",  Event_Weapon, EventHookMode_Post);
    HookEvent("weapon_fire",    Event_Weapon, EventHookMode_Post);
    HookEvent("weapon_pickup",  Event_Weapon, EventHookMode_Post);
    HookEvent("weapon_deploy",  Event_Weapon, EventHookMode_Post);    

    CreateTimer(0.5, Timer_Weapon, _, TIMER_REPEAT);

    g_iAmmoOffset = FindSendPropInfo("CINSWeaponBallistic", "m_bChamberedRound");

    StartPrepSDKCall(SDKCall_Entity);
    PrepSDKCall_SetVirtual(GetMaxClip1);
    PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_ByValue);
    g_SDKGetClip = EndPrepSDKCall();

    for(int client = MinClients; client <= MaxClients; ++client)
        if (IsClientInGame(client))
            OnClientPutInServer(client);
}

public void OnClientPutInServer(int client)
{
    SDKHook(client, SDKHook_WeaponEquipPost,  Event_WeaponPost);
    SDKHook(client, SDKHook_WeaponSwitchPost, Event_WeaponPost);
}

public void Event_Weapon(Event e, const char[] name, bool db)
{
    RequestFrame(CheckUserId, e.GetInt("userid"));
}

public void Event_WeaponPost(int client, int weapon)
{
    //RequestFrame(CheckUserId, GetClientUserId(client));
    CheckWeapon(client, weapon);
}

public Action Timer_Weapon(Handle timer)
{
    for(int client = MinClients; client <= MaxClients; ++client)
        if (ClientIsAlive(client))
            CheckWeapon(client);
    return Plugin_Continue;
}

static void CheckUserId(int client)
{
    client = GetClientOfUserId(client);
    if (ClientIsAlive(client))
        CheckWeapon(client);
}

static void CheckWeapon(int client, int m_hActiveWeapon = -1)
{
    if (m_hActiveWeapon == -1)
        m_hActiveWeapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");

    if (!IsValidEdict(m_hActiveWeapon))
        return;
    
    // Guns
    if (GetPlayerWeaponSlot(client, 0) == m_hActiveWeapon || GetPlayerWeaponSlot(client, 1) == m_hActiveWeapon)
    {
        int m_iClip1 = GetEntProp(m_hActiveWeapon, Prop_Send, "m_iClip1", 1);

        if (GetEntData(m_hActiveWeapon, g_iAmmoOffset, 1))
            m_iClip1++;

        Hint(client, " %d / %d ", m_iClip1, GetMaxClip(m_hActiveWeapon));
        return;
    }

    // Knife
    if (GetPlayerWeaponSlot(client, 2) == m_hActiveWeapon)
    {
        Hint(client, " 1 / 1 ");
        return;
    }

    // Items / Nades & more
    Hint(client, " 1 / %d ", GetMaxItem(client, m_hActiveWeapon));
}

static int GetMaxClip(int weapon)
{
    return SDKCall(g_SDKGetClip, weapon);
}

static int GetMaxItem(int client, int item)
{
    int m_iPrimaryAmmoType = GetEntProp(item, Prop_Send, "m_iPrimaryAmmoType");
    if (m_iPrimaryAmmoType == -1)
        return -1;

    return GetEntProp(client, Prop_Send, "m_iAmmo", _, m_iPrimaryAmmoType);
}