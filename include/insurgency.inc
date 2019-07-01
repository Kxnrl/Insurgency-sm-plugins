#define CLASS_CINSPlayerResource        "ins_player_manager"
#define CLASS_CINSObjectiveResource     "ins_objective_resource"
#define CLASS_CINSRulesProxy            "ins_rulesproxy"

#define CLASS_CP                        "trigger_capture_zone"

enum CINSPlayerResource
{
    m_iPing,
    m_iKills,
    m_iAssists,
    m_iDeaths,
    m_bConnected,
    m_iTeam,
    m_iPendingTeam,
    m_bAlive,
    m_iHealth,
    m_iPlayerScore,
    m_iPlayerRank,
    m_iControlCaptures,
    m_iRegroups,
    m_iControlNeutralized,
    m_iActiveControlPoint,
    m_iLives,
    m_bDeveloper, 
    m_bEarlyAccess,
    m_iSquad,
    m_iSquadSlot,
    m_iPlayerClass
}

enum CINSObjectiveResource
{
    m_iNumControlPoints,
    m_nActivePushPointIndex,
    m_nActiveRegroupPointIndex,
    m_nReinforcementWavesRemaining,
    m_nVipPlayer,
    m_bDiscovered,
    m_flCaptureTime,
    m_flDeteriorateTime,
    m_flLazyCapPerc,
    m_iCappingTeam,
    m_iOwningTeam,
    m_nTeamWithMostPlayers,
    m_nTeamBlocking,
    m_nInsurgentCount,
    m_nSecurityCount,
    m_vCPPositions,
    m_bSecurityLocked,
    m_bInsurgentsLocked, 
    m_nRequiredPointIndex,
    m_iObjectType,
    m_iszObjectiveName,
    m_hFlagEntity,
}

enum CINSRulesProxy
{
    m_iWinningTeam,
    m_flRoundStartTime,
    m_flGameStartTime,
    m_flLastPauseTime,
    m_bTimerPaused,
    m_flRoundLength,
    m_flRoundMaxTime,
    m_iGameState,
    m_iRoundPlayedCount,
    m_flNextReinforcementWave,
    m_flLastReinforcementWave,
    m_nMaxLives,
    m_nAttackingTeam,
    m_iLevel,
    m_iTheaterTeamOne,
    m_iTheaterTeamTwo,
    m_bCounterAttack,
    m_bPlaylistEnabled,
    m_iRequiredMaxplayersMax,
}

enum CINSTeam
{
    m_iTeamNum,
    m_iScore,
    m_iRoundsWon,
    m_szTeamname,
}

enum CINSGearType
{
    m_Gear_Armor   = 0, // 2 4
    m_Gear_Helmet  = 1, // ?
    m_Gear_Pack    = 2, // 6 8
    m_Gear_Glass   = 3, // 10
    m_Gear_Recon   = 4, // ?
    m_Gear_Unknow1 = 5,
    m_Gear_Unknow2 = 6,
}

enum CINSGearGlass
{
    m_Glass_None = -1,
    m_Glass_Nvgs = 10,
}

enum CINSArmorType
{
    Armor_None  = -1,
    Armor_Light = 2,
    Armor_Heavy = 4,
}

enum CINSGamemode
{
    // PVE
    GM_Conquer,
    GM_CheckPoint,
    GM_Hunt,
    GM_Outpost,
    GM_Survival,

    //PVP
    GM_Push,
    GM_Skirmish,
    GM_Occupy,
    GM_Firefight,
    GM_Ambush,
    GM_Elimination,

    // Err
    GM_Unknown
}

stock CINSGamemode Ins_GetGameMode()
{
    static ConVar mp_gamemode = null;
    if (mp_gamemode == null)
        mp_gamemode = FindConVar("mp_gamemode");

    static char mode[32];
    mp_gamemode.GetString(mode, 32);

    if (strcmp(mode, "conquer")     == 0)
        return GM_Conquer;

    if (strcmp(mode, "checkpoint")  == 0)
        return GM_CheckPoint;

    if (strcmp(mode, "hunt")        == 0)
        return GM_Hunt;

    if (strcmp(mode, "outpost")     == 0)
        return GM_Outpost;

    if (strcmp(mode, "survival")    == 0)
        return GM_Survival;

    if (strcmp(mode, "push")    == 0)
        return GM_Push;

    if (strcmp(mode, "skirmish")    == 0)
        return GM_Skirmish;

    if (strcmp(mode, "occupy")    == 0)
        return GM_Occupy;

    if (strcmp(mode, "firefight")    == 0)
        return GM_Firefight;

    if (strcmp(mode, "ambush")    == 0)
        return GM_Ambush;

    return GM_Unknown;
}