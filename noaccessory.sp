#pragma semicolon 1
#pragma newdecls required

#include <smutils>
#include <sdkhooks>

#include <insurgency>

public Plugin myinfo = 
{
    name        = "No Accessory",
    author      = "Kyle",
    description = "<- description ->",
    version     = "1.0",
    url         = "https://www.kxnrl.com"
};


static int g_iOffset = -1;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    RegPluginLibrary("Insurgency-NoAccessory");

    return APLRes_Success;
}

public void OnPluginStart()
{
    SMUitls_InitUserMessage();
    SMUtils_SetChatPrefix("[{purple}魔法少女{white}]");
    SMUtils_SetChatSpaces("   ");

    g_iOffset = FindSendPropInfo("CINSPlayer", "m_EquippedGear");
}

public void OnEntityCreated(int entity, const char[] classname)
{
    if (strcmp(classname, "sec_nightvision") == 0 || strcmp(classname, "ins_nightvision") == 0)
    {
        // 1 frame
        RequestFrame(Frame_Created, EntIndexToEntRef(entity));
    }
}

void Frame_Created(int ref)
{
    int entity = EntRefToEntIndex(ref);

    if (!IsValidEntity(entity))
        return;

    int owner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");

    if (ClientIsValid(owner))
    {
        if (HasPlayerAccessory(owner))
        {
            Chat(owner, "{red}本服务器已禁用夜视仪");
            EasyMissionHint(owner, 20.0, Icon_alert_red, 233, 0, 0, "本服务器禁止使用夜视仪");

            SetEntData(owner, g_iOffset + (4 * view_as<int>(m_Gear_Glass)), -1, 4, true);
        }
        else
            LogError("Found nvgs but wrong ent data on owner class base.");
    }

    AcceptEntityInput(entity, "KillHierarchy");
}

stock bool HasPlayerAccessory(int client)
{
    return view_as<CINSGearGlass>(GetEntData(client, g_iOffset + (4 * view_as<int>(m_Gear_Glass)))) == m_Glass_Nvgs;
}