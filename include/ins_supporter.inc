#if defined _Insurgency_Supporter_Include_
    #endinput
#endif

#define _Insurgency_Supporter_Include_

#define PERMANENT 2147483647

enum vip_t
{
    vip_None        = 0,
    vip_Monthly     = 1,
    vip_Quarterly   = 2,
    vip_Yearly      = 3,
    vip_Permanently = 4
};

native vip_t Ins_GetSupporter(int client);
native int   Ins_GetSupporterExpiredDate(int client);

public SharedPlugin __pl_Insurgency_Supporter =
{
    name = "Insurgency-Supporter",
    file = "supporter.smx",
#if defined REQUIRE_PLUGIN
    required = 1
#else
    required = 0
#endif
};