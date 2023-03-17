const string TM_ARCHIVIST_LOCAL_SCRIPT_TXT = """
/**
 *	PlayMap mode
 */
//  #Extends "Libs/Nadeo/TMNext/TrackMania/Modes/TMNextBase.Script.txt"
 #Extends "Modes/Trackmania/TM_Archivist_Base.Script.txt"

 #Const CompatibleMapTypes "TrackMania\\TM_Race,TM_Race"
 #Const Version "2022-10-24"
 #Const ScriptName "Modes/TrackMania/TM_Archivist_Local.Script.txt"

 // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ //
 // Libraries
 // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ //
 #Include "TextLib" as TL
 #Include "TimeLib" as TiL
 #Include "MathLib" as Math
 #Include "Libs/Nadeo/CommonLibs/Common/Task.Script.txt" as Task
 #Include "Libs/Nadeo/CommonLibs/Common/MainUser.Script.txt" as MainUser
 #Include "Libs/Nadeo/TMNext/TrackMania/Modes/PlayMap/StateManager.Script.txt" as StateMgr
 #Include "Libs/Nadeo/TMNext/TrackMania/ColorPalette.Script.txt" as ColorPalette
 #Include "Libs/Nadeo/TMNext/TrackMania/Menu/Constants.Script.txt" as MenuConsts
 #Include "Libs/Nadeo/TMNext/TrackMania/Modes/PlayMap/Constants.Script.txt" as Const
 #Include "ManiaApps/Nadeo/TMxSM/Race/UIModules/TimeGap_Server.Script.txt" as UIModules_TimeGap
 #Include "ManiaApps/Nadeo/TMNext/TrackMania/PlayMap/UIModules/PauseMenu_Server.Script.txt" as UIModules_PauseMenu
 #Include "ManiaApps/Nadeo/TMNext/TrackMania/PlayMap/UIModules/EndRaceMenu_Server.Script.txt" as UIModules_EndRaceMenu
 #Include "ManiaApps/Nadeo/ModeLibs/Common/UIModules/Fade_Server.Script.txt" as UIModules_Fade
 #Include "ManiaApps/Nadeo/TMNext/TrackMania/UIModules/NetShare_Server.Script.txt" as NetShare
 #Include "Libs/Nadeo/TMNext/TrackMania/Stores/UserStore_MA.Script.txt" as UserStore
 #Include "Libs/Nadeo/TMNext/TrackMania/Structures/CampaignStruct.Script.txt" as CampaignStruct
 #Include "Libs/Nadeo/TMNext/TrackMania/Modes/Constants.Script.txt" as ModeConst
 #Include "Libs/Nadeo/MenuLibs/Common/Components/Tools.Script.txt" as Tools

 // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ //
 // Settings
 // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ //
 #Setting S_AgainstReplay "" as "<hidden>" //< Path to the replay file to load
 #Setting S_AdditionalReplays "" as "<hidden>" //< Paths to additional replays to load

 // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ //
 // Structures
 // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ //
 #Struct K_LoadRecordTask {
     Boolean IsLoading;
     Text MapUid;
     Text ScopeType;
     Text ScopeId;
     Text ModeName;
     Text ModeCustomData;
     Ident TaskId_LoadScore;
     Ident TaskId_GetRecordGhost;
     Ident RecordGhostId;
 }

 #Struct K_RecordGhost {
     CGhost Ghost;
     Text AccountId;
     Ident GhostInstanceId;
     Task::K_Task Task_RetrieveGhost;
     Task::K_Task Task_RetrieveRecords;
 }

 #Struct K_PluginSettings {
    Integer S_NbPbGhosts;
    Integer S_NbRecentGhosts;
    Integer S_SaveAfterRaceTimeMs;
    Boolean S_KeepAllGhostsLoaded;
    // Boolean S_UploadGhosts;
    Boolean S_SaveGhosts;
    Boolean S_SaveReplays;
    Boolean S_SeparatePartialRuns;
    Boolean S_SaveTruncatedRuns;
    Text S_ReplayNameTemplate;
    Text S_ReplayFolderTemplate;
 }

 #Struct K_LoadedGhost {
    Ident Id;
    Ident InstId;
    Integer Time;
 }

 // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ //
 // Constants
 // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ //
 #Const C_ModeName "Play Map"
 //L16N [PlayMap] Description of the mode rules
 #Const Description _("Play a track locally")

 #Const C_HudModulePath "" //< Path to the hud module
 #Const C_ManiaAppUrl "file://Media/ManiaApps/Nadeo/TMNext/TrackMania/PlayMap/PlayMap.Script.txt" //< Url of the mania app
 #Const C_FakeUsersNb 0
 #Const C_MaximumAdditionalReplaysNb 100

 #Const C_UploadRecord True
 #Const C_DisplayRecordGhost False
 #Const C_DisplayRecordMedal True
 #Const C_CelebrateRecordGhost True
 #Const C_CelebrateRecordMedal True
 #Const C_DisplayWorldTop True

 // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ //
 // Extends
 // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ //
 ***Match_LogVersions***
 ***
 Log::RegisterScript(ScriptName, Version);
 Log::RegisterScript(StateMgr::ScriptName, StateMgr::Version);
 Log::RegisterScript(UIModules_TimeGap::ScriptName, UIModules_TimeGap::Version);
 Log::RegisterScript(UIModules_PauseMenu::ScriptName, UIModules_PauseMenu::Version);
 Log::RegisterScript(UIModules_EndRaceMenu::ScriptName, UIModules_EndRaceMenu::Version);
 Log::RegisterScript(NetShare::ScriptName, NetShare::Version);
 ***

 ***Match_LoadLibraries***
 ***
 StateMgr::Load();
 ***

 ***Match_UnloadLibraries***
 ***
 StateMgr::Unload();
 ***

 ***Match_Settings***
 ***
 MB_Settings_UseDefaultHud = (C_HudModulePath == "");
 MB_Settings_UseDefaultTimer = False;
 MB_Settings_UseDefaultUIManagement = False;
 MB_Settings_UseDefaultPodiumSequence = False;
 Race_Settings_UseDefaultUIManagement = False;
 Race_Settings_IsLocalMode = True;
 ***

 ***Match_Rules***
 ***
 ModeInfo::SetName(C_ModeName);
 ModeInfo::SetType(ModeInfo::C_Type_FreeForAll);
 ModeInfo::SetRules(Description);
 ModeInfo::SetStatusMessage("");
 ***

 ***Match_LoadHud***
 ***
 if (C_HudModulePath != "") Hud_Load(C_HudModulePath);
 ***

 ***Match_AfterLoadHud***
 ***
 ClientManiaAppUrl = C_ManiaAppUrl;
 Race::SortScores(Race::C_Sort_BestRaceTime);
 UIModules_TimeGap::SetTimeGapMode(UIModules_TimeGap::C_TimeGapMode_Hidden);
 UIModules_Fade::SetZIndex(0);
 UIManager.HoldLoadingScreen = True;
 ***

 ***Match_Yield***
 ***
 foreach (Event in PendingEvents) {
     switch (Event.Type) {
         // Initialize players when they join the server
         case CSmModeEvent::EType::OnPlayerAdded: {
             StateMgr::InitializePlayer(Event.Player);
         }
     }
 }

 StateMgr::Yield();

 // Check pause menu restart request
 if (UIModules_PauseMenu::IsRestartRequested()) {
     Race::StopSkipOutroAll();
 }
 ***

 ***Match_InitServer***
 ***
 declare Boolean Server_IsAgainstReplay;
 declare Ident[] Server_ReplayGhostIds for This;
 declare Ident[] Server_ReplayGhostInstanceIds for This;
 ***

 ***Match_StartServer***
 ***
 // Initialize mode
 Clans::SetClansNb(0);
 Race::SetRespawnBehaviour(Race::C_RespawnBehaviour_GiveUpBeforeFirstCheckpoint);
 StateMgr::ForcePlayersStates([StateMgr::C_State_Waiting]);
 WarmUp::SetAvailability(True);
 Race::SetupRecord(
     MenuConsts::C_ScopeType_Season,
     MenuConsts::C_ScopeType_PersonalBest,
     MenuConsts::C_GameMode_PlayMap,
     "",
     C_UploadRecord,
     C_DisplayRecordGhost,
     C_DisplayRecordMedal,
     C_CelebrateRecordGhost,
     C_CelebrateRecordMedal,
     C_DisplayWorldTop
 );
 Ghost::EnableBestGhosts(True);

 Server_IsAgainstReplay = False;
 ***

 ***Match_AfterLoadMap***
 ***
 // Players are available only once the map is loaded
 // We must enforce their initialization there to avoid
 // being stuck in the end race menu when restarting the script
 foreach (Player in AllPlayers) {
     StateMgr::InitializePlayer(Player);
 }

 declare netread Text[][] MLHook_NetQueue_Archivist for Teams[0];

 // Unload previous ghosts
 ResetRecord();
 ResetReplay();
 foreach (GhostInstanceId in Server_ReplayGhostInstanceIds) {
     GhostMgr.Ghost_Remove(GhostInstanceId);
 }
 Server_ReplayGhostInstanceIds = [];
 foreach (GhostId in Server_ReplayGhostIds) {
     if (DataFileMgr.Ghosts.existskey(GhostId)) {
         DataFileMgr.Ghost_Release(GhostId);
     }
 }
 Server_ReplayGhostIds = [];

 // Load replay
 if (S_AgainstReplay != "") {
     Server_IsAgainstReplay = True;
     declare Task::K_Task LoadReplayTask = Task::Create(DataFileMgr, DataFileMgr.Replay_Load(S_AgainstReplay));
     if (Task::IsInitialized(LoadReplayTask)) {
         while (Task::IsRunning(LoadReplayTask)) {
             MB_Yield();
             LoadReplayTask = Task::Update(LoadReplayTask);
         }

         declare Ident[] GhostIdsToRelease;
         declare CTaskResult_GhostList SourceTask = Task::GetSourceTask_GhostList(LoadReplayTask);
         if (Task::IsSuccess(LoadReplayTask) && SourceTask != Null) {
             foreach (Key => Ghost in SourceTask.Ghosts) {
                 if (Key == 0) {
                     SetReplay(DataFileMgr.Ghosts[Ghost.Id], Server_IsAgainstReplay);
                 } else {
                     GhostIdsToRelease.add(Ghost.Id);
                 }
             }
         }

         LoadReplayTask = Task::Destroy(LoadReplayTask);
         foreach (GhostId in GhostIdsToRelease) {
             DataFileMgr.Ghost_Release(GhostId);
         }
     }
 }

 // Load additionnal replays
 if (S_AdditionalReplays != "") {
     declare Text[] AdditionalReplays;
     AdditionalReplays.fromjson(S_AdditionalReplays);
     declare Task::K_Task[] LoadReplayTasks;
     foreach (ReplayPath in AdditionalReplays) {
         LoadReplayTasks.add(Task::Create(DataFileMgr, DataFileMgr.Replay_Load(ReplayPath)));
         if (LoadReplayTasks.count >= C_MaximumAdditionalReplaysNb) break;
     }
     while (LoadReplayTasks.count > 0) {
         declare Task::K_Task LoadReplayTask = LoadReplayTasks[0];
         if (Task::IsInitialized(LoadReplayTask)) {
             LoadReplayTask = Task::Update(LoadReplayTask);
             if (!Task::IsRunning(LoadReplayTask)) {
                 declare Ident[] GhostIdsToRelease;
                 declare CTaskResult_GhostList SourceTask = Task::GetSourceTask_GhostList(LoadReplayTask);

                 if (Task::IsSuccess(LoadReplayTask) && SourceTask != Null) {
                     foreach (Key => Ghost in SourceTask.Ghosts) {
                         if (Key == 0) {
                             if (Ghost.Id != NullId) {
                                 Server_ReplayGhostIds.add(Ghost.Id);
                                 declare Ident GhostInstanceId = GhostMgr.Ghost_Add(Ghost, True);
                                 if (GhostInstanceId != NullId) {
                                     Server_ReplayGhostInstanceIds.add(GhostInstanceId);
                                 }
                             }
                         } else {
                             GhostIdsToRelease.add(Ghost.Id);
                         }
                     }
                 }

                 foreach (GhostId in GhostIdsToRelease) {
                     DataFileMgr.Ghost_Release(GhostId);
                 }

                 Task::Destroy(LoadReplayTask);
                 LoadReplayTasks.removekey(0);
             } else {
                 LoadReplayTasks[0] = LoadReplayTask;
                 MB_Sleep(100);
             }
         } else {
             LoadReplayTasks.removekey(0);
         }
     }
 }

 UIModules_PauseMenu::SetIsAgainstReplay(Server_IsAgainstReplay);
 UIModules_EndRaceMenu::SetIsAgainstReplay(Server_IsAgainstReplay);

 // Load player's record ghost
 declare K_LoadRecordTask Task = LoadRecord(Map.MapInfo.MapUid, MenuConsts::C_ScopeType_PersonalBest, "", MenuConsts::C_GameMode_PlayMap, "");
 while (Task.IsLoading) {
     MB_Yield();
     Task = UpdateLoadRecord(Task);
 }
 declare CGhost RecordGhost = RetrieveRecordGhost(Task);
 if (RecordGhost != Null) {
     SetRecord(RecordGhost, !Server_IsAgainstReplay);
 }

//  GhostRecorder_SetEnabled(Players[0], True);

 UIManager.HoldLoadingScreen = False;
 ***

 ***Match_InitMap***
 ***
 declare CampaignStruct::LibCampaignStruct_K_Map Map_Map for This;
 declare K_RecordGhost Map_LoadingRecordGhost;
 declare K_RecordGhost Map_LoadedRecordGhost;
 declare Integer Map_RecordGhostLoopTimer;
 declare Integer Map_RecordGhostLoopDelay;
 ***

 ***Match_StartMap***
 ***
 // Add bot when necessary
 Users_SetNbFakeUsers(C_FakeUsersNb, 0);

 // Remove records ghosts
 Map_LoadingRecordGhost = ReleaseRecordGhost(Map_LoadingRecordGhost);
 Map_LoadedRecordGhost = ReleaseRecordGhost(Map_LoadedRecordGhost);
 UIModules_Record::SetSpectatorTargetAccountId("");

 Map_Map = UpdateCurrentMapInfo();
 NetShare::SetMap(Map_Map);
 ***

 ***Match_InitRound***
 ***
 declare Ident Round_LastRaceGhostId;
 declare Boolean Round_ImprovedTime;
 declare Boolean Round_NewRecord;
 declare Integer Last_Q_Incoming;

 declare Boolean Round_HasMoved;
 declare Boolean Round_SetInitPos;
 declare Vec3 Round_InitPos;
 ***

 ***Match_StartRound***
 ***
 // Initialize race
 Round_ImprovedTime = False;
 Round_NewRecord = False;
 Round_HasMoved = False;
 Round_SetInitPos = False;
 StartTime = Now + Race::C_SpawnDuration;
 MB_EnablePlayMode(True);
 UIModules_EndRaceMenu::SetTimeDiff(False, 0);

 // Update PB ghost visibility
 declare Boolean PBGhostIsVisible = True;
 if (AllPlayers.count > 0) {
     PBGhostIsVisible = UIModules_Record::PBGhostIsVisible(AllPlayers[0]);
 }
 DisplayRecordGhost(PBGhostIsVisible);

 // Spawn players for the race
 foreach (Player in Players) {
     Race::Start(Player, StartTime);
 }

 StateMgr::ForcePlayersStates([StateMgr::C_State_Playing]);
 RaceStateMgr::ForcePlayersStates([StateMgr::C_State_Playing]);
 ***

 ***Match_PlayLoop***
 ***
 declare CSmPlayer MainPlayer <=> Players[0];
 declare CUIConfig MainPlayerUI = UIManager.GetUI(MainPlayer);
 declare netread Text[][] MLHook_NetQueue_Archivist for MainPlayerUI;
 declare netread Integer MLHook_NetQueue_Archivist_Last for MainPlayerUI;
 if (MLHook_NetQueue_Archivist_Last > Last_Q_Incoming) {
    Last_Q_Incoming = MLHook_NetQueue_Archivist_Last;
    foreach (Msgs in MLHook_NetQueue_Archivist) {
       ProcessIncomingFromMLHook(Msgs);
    }
 }

 // Manage race events
 declare RacePendingEvents = Race::GetPendingEvents();
 foreach (Event in RacePendingEvents) {
     Race::ValidEvent(Event);

     // Waypoint
     if (Event.Type == Events::C_Type_Waypoint) {
         if (Event.Player != Null) {
             if (Event.IsEndRace) {
                 Race::StopSkipScoresTable(Event.Player);

                 Round_ImprovedTime = (
                     Event.Player.Score.BestRaceTimes.count <= 0 ||
                     Event.Player.RaceWaypointTimes.count > Event.Player.Score.BestRaceTimes.count || (
                         Event.Player.RaceWaypointTimes.count == Event.Player.Score.BestRaceTimes.count &&
                         Event.Player.RaceWaypointTimes[Event.Player.RaceWaypointTimes.count - 1] < Event.Player.Score.BestRaceTimes[Event.Player.RaceWaypointTimes.count - 1]
                     )
                 );

                 if (
                     Event.Player.Score.BestRaceTimes.count > 0 &&
                     Event.Player.RaceWaypointTimes.count == Event.Player.Score.BestRaceTimes.count
                 ) {
                     UIModules_EndRaceMenu::SetTimeDiff(True, Event.Player.RaceWaypointTimes[Event.Player.RaceWaypointTimes.count - 1] - Event.Player.Score.BestRaceTimes[Event.Player.RaceWaypointTimes.count - 1]);
                 }

                 if (!Server_IsAgainstReplay) {
                     Scores::UpdatePlayerBestRaceIfBetter(Event.Player);
                     Scores::UpdatePlayerBestLapIfBetter(Event.Player);
                 }
                 Scores::UpdatePlayerPrevRace(Event.Player);

                 if (ArchivistSettings.S_SaveTruncatedRuns) {
                     // It appears that the only time we can get a segmented ghost is as the first request to get a ghost, possibly only on the frame we finish?
                     declare CGhost GhostTrunc = Ghost_RetrieveFromPlayerWithValues(Event.Player, True);
                     // only keep a segmented ghost around if there were respawns
                     if (GhostTrunc.Result.NbRespawns > 0) {
                         ProcessCompleteTruncGhost(GhostTrunc);
                     } else {
                        DataFileMgr.Ghost_Release(GhostTrunc.Id);
                     }
                 }

                 // we need to get the full ghost now so that we don't upload a truncated ghost to the leaderboards.
                 declare CGhost Ghost = Ghost_RetrieveFromPlayerWithValues(Event.Player);
                 ProcessCompleteGhost(Ghost);
                //  SaveReplay(Ghost, False, False);
                 if (Ghost != Null) {
                     if (Round_LastRaceGhostId != NullId && DataFileMgr.Ghosts.existskey(Round_LastRaceGhostId)) {
                         DataFileMgr.Ghost_Release(Round_LastRaceGhostId);
                     }
                     Round_LastRaceGhostId = Ghost.Id;
                 }

                 declare Integer RecordTime = GetRecordTime();
                 if (RecordTime < 0 || Event.RaceTime < GetRecordTime()) {
                    // get a new ghost -- the ghost is processed as the 'personal best' ghost (so the name is changed, etc).
                     SetRecord(Ghost_RetrieveFromPlayerWithValues(Event.Player, False), !Server_IsAgainstReplay);
                     Map_Map = SetMapNewRecord(Event.Player, Map_Map);
                     NetShare::SetMap(Map_Map);
                     Round_ImprovedTime = True;
                     Round_NewRecord = True;
                 }

                 MB_StopRound();
             }
             if (Event.IsEndLap) {
                 if (!Server_IsAgainstReplay) {
                     Scores::UpdatePlayerBestLapIfBetter(Event.Player);
                 }
             }
         }
     } else if (Event.Type == Events::C_Type_GiveUp) {
        if (Event.Player != Null && Round_HasMoved && Event.Player.CurrentRaceTime > ArchivistSettings.S_SaveAfterRaceTimeMs && IsPlaying()) {
            // truncation never works with partial ghosts
            declare CGhost _Ghost = Ghost_RetrieveFromPlayerWithValues(Event.Player, False);
            _Ghost.Result.Time = Event.Player.CurrentRaceTime;
            if (_Ghost != Null) {
                ProcessPartialGhost(_Ghost);
            }
        }
     } else if (Event.Type == Events::C_Type_StartLine) {
        Round_SetInitPos = True;
        Round_HasMoved = False;
        Round_InitPos = MainPlayer.Position;
        AddDebugLog("Reset player position");
     }
 }


 // keep track of the players init pos and how far they moved to avoid saving replays on the start line
 // ! do this after processing race events b/c players pos gets set to 0 otherwise
 if (!Round_SetInitPos) {
    if (MainPlayer.Position.X != 0. && MainPlayer.Position.Z != 0.) {
        Round_InitPos = MainPlayer.Position;
        Round_SetInitPos = True;
    }
 } else if (!Round_HasMoved) {
     declare Vec3 dist = Round_InitPos - MainPlayer.Position;
     if (Math::Length(dist) > 5.) {
        Round_HasMoved = True;
        AddDebugLog("Set Round_HasMoved to True. Distance: "^dist);
     }
 }


 // Manage mode events
 foreach (Event in PendingEvents) {
     if (Event.HasBeenPassed || Event.HasBeenDiscarded) continue;
     Events::Invalid(Event);
 }

 // Spawn players
 foreach (Player in Players) {
     if (MB_RoundIsRunning() && Race::IsReadyToStart(Player)) {
         Race::Start(Player);
     }
 }

 // Manage UI events
 foreach (Event in UIManager.PendingEvents) {
     if (Event.Type == CUIConfigEvent::EType::OnLayerCustomEvent) {
         switch (Event.CustomEventType) {
             case UIModules_Record::C_Event_UpdatePBGhostVisibility: {
                 DisplayRecordGhost(UIModules_Record::PBGhostIsVisible(Event));
             }
             case UIModules_Record::C_Event_Spectate: {
                 if (Event.CustomEventData.count >= 1) {
                     declare Text AccountId = Event.CustomEventData[0];
                     if (Map_LoadedRecordGhost.AccountId == AccountId) {
                         Map_LoadingRecordGhost = ReleaseRecordGhost(Map_LoadingRecordGhost);
                         Map_LoadedRecordGhost = ReleaseRecordGhost(Map_LoadedRecordGhost);
                         UIModules_Fade::SetFade(UIModules_Fade::C_Fade_Out, Now, 500, "");
                         RespawnLocalPlayer();
                     } else if (Map_LoadingRecordGhost.AccountId != AccountId) {
                         Map_LoadingRecordGhost = ReleaseRecordGhost(Map_LoadingRecordGhost);
                         Map_LoadingRecordGhost = K_RecordGhost {
                             AccountId = AccountId,
                             Task_RetrieveRecords = Task::Create(
                                 ScoreMgr,
                                 ScoreMgr.Map_GetPlayerListRecordList(MainUser::GetMainUserId(), [AccountId], Map_Map.Uid, MenuConsts::C_ScopeType_PersonalBest, "", C_ModeName, "")
                             )
                         };
                     }
                 }
             }
         }
     }
 }

 // Load records selected by the player
 if (Map_LoadingRecordGhost.AccountId != "") {
     if (Task::IsInitialized(Map_LoadingRecordGhost.Task_RetrieveRecords)) {
         Map_LoadingRecordGhost.Task_RetrieveRecords = Task::Update(Map_LoadingRecordGhost.Task_RetrieveRecords);
         if (!Task::IsRunning(Map_LoadingRecordGhost.Task_RetrieveRecords)) {
             declare CTaskResult_MapRecordList SourceTask = Task::GetSourceTask_MapRecordList(Map_LoadingRecordGhost.Task_RetrieveRecords);
             if (Task::IsSuccess(Map_LoadingRecordGhost.Task_RetrieveRecords) && SourceTask != Null && SourceTask.MapRecordList.count >= 1) {
                 declare CMapRecord MapRecord <=> SourceTask.MapRecordList[0];
                 Map_LoadingRecordGhost.Task_RetrieveGhost = Task::DestroyAndCreate(
                     Map_LoadingRecordGhost.Task_RetrieveGhost,
                     DataFileMgr,
                     DataFileMgr.Ghost_Download(MapRecord.FileName, MapRecord.ReplayUrl)
                 );
             } else { //< Respawn the player if the record ghost cannot be retrieved
                 Map_LoadedRecordGhost = ReleaseRecordGhost(Map_LoadedRecordGhost);
                 Map_LoadingRecordGhost.AccountId = "";
                 RespawnLocalPlayer();
             }
             Map_LoadingRecordGhost.Task_RetrieveRecords = Task::Destroy(Map_LoadingRecordGhost.Task_RetrieveRecords);
         }
     } else if (Task::IsInitialized(Map_LoadingRecordGhost.Task_RetrieveGhost)) {
         Map_LoadingRecordGhost.Task_RetrieveGhost = Task::Update(Map_LoadingRecordGhost.Task_RetrieveGhost);
         if (!Task::IsRunning(Map_LoadingRecordGhost.Task_RetrieveGhost)) {
             declare CTaskResult_Ghost SourceTask = Task::GetSourceTask_Ghost(Map_LoadingRecordGhost.Task_RetrieveGhost);
             if (Task::IsSuccess(Map_LoadingRecordGhost.Task_RetrieveGhost) && SourceTask != Null && SourceTask.Ghost != Null) {
                 declare Text DisplayName = UserStore::GetUserMgrPlayerName(Map_LoadingRecordGhost.AccountId);

                 if (DisplayName != "") {
                     SourceTask.Ghost.Nickname = DisplayName;
                 }

                 Map_RecordGhostLoopDelay = Now + 250;
                 Map_LoadingRecordGhost.Ghost = SourceTask.Ghost;
                 UIModules_Fade::SetFade(UIModules_Fade::C_Fade_In, Now, 200, ColorPalette::C_Color_Black);
             } else { //< Respawn the player if the record ghost cannot be retrieved
                 Map_LoadedRecordGhost = ReleaseRecordGhost(Map_LoadedRecordGhost);
                 Map_LoadingRecordGhost.AccountId = "";
                 RespawnLocalPlayer();
             }
             Map_LoadingRecordGhost.Task_RetrieveGhost = Task::Destroy(Map_LoadingRecordGhost.Task_RetrieveGhost);
         }
     } else if (Map_RecordGhostLoopDelay >= 0 && Now >= Map_RecordGhostLoopDelay) { //< Wait to release previous ghosts to avoid visible camera change
         Map_RecordGhostLoopDelay = -1;
         Map_LoadedRecordGhost = ReleaseRecordGhost(Map_LoadedRecordGhost);
         if (Map_LoadingRecordGhost.Ghost != Null) {
             Map_LoadingRecordGhost.GhostInstanceId = GhostMgr.Ghost_Add(Map_LoadingRecordGhost.Ghost, True);
             if (Map_LoadingRecordGhost.GhostInstanceId != NullId) {
                 UIModules_Record::SetSpectatorTargetAccountId(Map_LoadingRecordGhost.AccountId);
                 Map_LoadedRecordGhost = Map_LoadingRecordGhost;
                 Map_LoadingRecordGhost = K_RecordGhost {};
                 Map_RecordGhostLoopTimer = Now + 50;
             } else {
                 UIModules_Record::SetSpectatorTargetAccountId("");
                 Map_LoadingRecordGhost = ReleaseRecordGhost(Map_LoadingRecordGhost);
             }
         }
     }
 }

 // Loop ghost for replay
 if (Map_RecordGhostLoopTimer >= 0 && Now >= Map_RecordGhostLoopTimer) {
     UIModules_Fade::AddFade(UIModules_Fade::C_Fade_Out, Now, 500, "");
     if (Map_LoadedRecordGhost.Ghost != Null && DataFileMgr.Ghosts.existskey(Map_LoadedRecordGhost.Ghost.Id) && Players.count > 0 && Players[0] != Null) {
         Ghosts_SetStartTime(Now);
         UnspawnPlayer(Players[0]);
         UIManager.UIAll.ForceSpectator = True;
         UIManager.UIAll.SpectatorForceCameraType = 1;
         UIManager.UIAll.Spectator_SetForcedTarget_Ghost(Map_LoadedRecordGhost.GhostInstanceId);
         UIManager.UIAll.UISequence = CUIConfig::EUISequence::EndRound;
         Map_RecordGhostLoopTimer = Now + DataFileMgr.Ghosts[Map_LoadedRecordGhost.Ghost.Id].Result.Time;
         UIModules_Fade::AddFade(UIModules_Fade::C_Fade_In, Map_RecordGhostLoopTimer - 250, 200, ColorPalette::C_Color_Black);
     } else {
         Map_RecordGhostLoopTimer = -1;
     }
 }
 ***

 ***Match_EndRound***
 ***
 //Wait for the end of the player race outro
 declare Boolean OutroFinished = False;
 declare Boolean SkipEndRaceMenu = False;
 while (MB_MapIsRunning() && !OutroFinished) {
     MB_Yield();

     declare RacePendingEvents = Race::GetPendingEvents();
     foreach (Event in RacePendingEvents) {
         if (Event.Type == Events::C_Type_SkipOutro) {
             Race::ValidEvent(Event);
             if (!Round_ImprovedTime) SkipEndRaceMenu = True;
         } else {
             Race::InvalidEvent(Event);
         }
     }
     foreach (Event in PendingEvents) {
         if (Event.HasBeenPassed || Event.HasBeenDiscarded) continue;
         Events::Invalid(Event);
     }

     OutroFinished = True;
     foreach (Player in Players) {
         if (Race::IsWatchingOutro(Player)) {
             OutroFinished = False;
             break;
         }
     }
 }

 // Try to retrieve the player's ghost again after the few seconds of the outro (not MediaTracker outro) to have a few seconds after the finish included in the replay
 foreach (Player in Players) {
     if (
         Round_LastRaceGhostId != NullId &&
         DataFileMgr.Ghosts.existskey(Round_LastRaceGhostId) &&
         DataFileMgr.Ghosts[Round_LastRaceGhostId].Result.Time != -1
     ) {
         /* Using Ghost_RetrieveFromPlayer after SetRecord results in a -1 Result.Time, see RacePendingEvents loop.
          * Note: *.Result.Checkpoints still seems to be fine, due to Player_AddWaypointTime being added at the end of the race
          * Maybe there's a missing Player_SetFinishTime somewhere, which I believe should set the Result.Time correctly...
          * but I'm not too sure, so just using this kinda hacky way to transfer the time onto the new ghost
          */
         declare Integer LastRaceTime = DataFileMgr.Ghosts[Round_LastRaceGhostId].Result.Time;
         declare CGhost Ghost = Ghost_RetrieveFromPlayerWithValues(Player);
         if (
             Ghost != Null &&
             Ghost.Result.Checkpoints.count > 0 &&
             Ghost.Result.Checkpoints[Ghost.Result.Checkpoints.count - 1] == LastRaceTime
         ) {
             Ghost.Result.Time = LastRaceTime;
             DataFileMgr.Ghost_Release(Round_LastRaceGhostId);
             Round_LastRaceGhostId = Ghost.Id;
         } else if (Ghost != Null) {
             DataFileMgr.Ghost_Release(Ghost.Id);
         }
     }
    //  GhostRecorder_Ghosts_Select(Player);
 }

 // Unspawn players
 Race::StopSkipOutroAll();
 MB_Yield(); //< Sleep one frame to be sure that player is properly unspawn
 MB_EnablePlayMode(False);
 RaceStateMgr::ForcePlayersStates([StateMgr::C_State_Waiting]);
 StateMgr::ForcePlayersStates([StateMgr::C_State_Waiting]);
 StartTime = -1;

 // Update PB ghost visibility
 DisplayRecordGhost(True);

 if (!SkipEndRaceMenu) {
     // Start replay outro
     Ghosts_SetStartTime(Now);
     declare Integer GhostRestartTime = -1;
     declare Integer GhostRestartDelay = 0;
     declare Ident GhostAddIdToFollow = NullId;
     declare Ident GhostIdToFollow = NullId;

     declare Ident PlayMap_RecordGhostId for This;
     declare Ident PlayMap_RecordGhostAddId for This;
     declare Boolean UsePBGhost = Round_NewRecord && PlayMap_RecordGhostId != NullId && PlayMap_RecordGhostAddId != NullId;

     if (UsePBGhost) {
         if (DataFileMgr.Ghosts.existskey(PlayMap_RecordGhostId)) {
             GhostRestartTime = Now + DataFileMgr.Ghosts[PlayMap_RecordGhostId].Result.Time + GhostRestartDelay;
             GhostIdToFollow = PlayMap_RecordGhostId;
             GhostAddIdToFollow = PlayMap_RecordGhostAddId;
         }
     } else {
         if (DataFileMgr.Ghosts.existskey(Round_LastRaceGhostId)) {
             GhostRestartTime = Now + DataFileMgr.Ghosts[Round_LastRaceGhostId].Result.Time + GhostRestartDelay;
             GhostIdToFollow = Round_LastRaceGhostId;
             GhostAddIdToFollow = GhostMgr.Ghost_Add(DataFileMgr.Ghosts[Round_LastRaceGhostId], False);
         }
     }
     if (GhostAddIdToFollow != NullId) {
         UIManager.UIAll.Spectator_SetForcedTarget_Ghost(GhostAddIdToFollow);
     }
     if (GhostRestartTime >= 0) {
         UIModules_Fade::SetFade(UIModules_Fade::C_Fade_In, GhostRestartTime - 250, 200, ColorPalette::C_Color_Black);
     }

     declare CUIConfig::EUISequence PrevUISequence = UIManager.UIAll.UISequence;
     UIManager.UIAll.UISequence = CUIConfig::EUISequence::EndRound;
     UIManager.UIAll.ForceSpectator = True;
     UIManager.UIAll.SpectatorForceCameraType = 0;

     // Open end race menu
     StateMgr::ForcePlayersStates([StateMgr::C_State_EndRaceMenu]);
     UIModules_EndRaceMenu::SetCanViewReplay(GhostAddIdToFollow != NullId);
     UIModules_EndRaceMenu::SetReplaySaveStatus(UIModules_EndRaceMenu::C_ReplaySaveStatus_Null);
     declare Ident TaskId_SaveReplay;
     declare Boolean WaitMenu = True;
     while ((MB_MapIsRunning() && WaitMenu) || TaskId_SaveReplay != NullId) {
         MB_Yield();

         // Process end race menu events
         foreach (Event in UIManager.PendingEvents) {
             if (Event.Type == CUIConfigEvent::EType::OnLayerCustomEvent) {
                 switch (Event.CustomEventType) {
                     case Const::C_Event_Improve: {
                         WaitMenu = False;
                     }
                     case Const::C_Event_Quit: {
                         MB_StopServer();
                         WaitMenu = False;
                     }
                     case Const::C_Event_SaveReplay: {
                         if (TaskId_SaveReplay == NullId && Round_LastRaceGhostId != NullId && DataFileMgr.Ghosts.existskey(Round_LastRaceGhostId)) {
                             declare CGhost Ghost = DataFileMgr.Ghosts[Round_LastRaceGhostId];
                             declare Text Time = TiL::FormatDate(TiL::GetCurrent(), TiL::EDateFormats::Time);
                             declare Text Date = TiL::FormatDate(TiL::GetCurrent(), TiL::EDateFormats::DateShort);
                             declare Text FullDate = TL::RegexReplace("\\W", Date^"_"^Time, "g", "-");
                             declare Text RaceTime = TL::TimeToText(Ghost.Result.Time, True, True);
                             RaceTime = TL::Replace(RaceTime, ":", "'");
                             RaceTime = TL::Replace(RaceTime, ".", "''");
                             declare Text ReplayFileName = Map.MapInfo.Name^"_"^AllPlayers[0].User.Name^"_"^FullDate^"("^RaceTime^")";
                             ReplayFileName = TL::Replace(ReplayFileName, ".", "");
                             declare CTaskResult Task = DataFileMgr.Replay_Save("My Replays/"^ReplayFileName^".Replay.Gbx", Map, Ghost);
                             if (Task != Null) {
                                 TaskId_SaveReplay = Task.Id;
                             }
                             // ! cannot get segmented ghost later -- bust be before getting the normal replay
                            //  Ghost_Remove(Round_LastRaceGhostId);
                            //  GhostRecorder_Clear(Players[0]);
                            //  declare Ghost2 = Ghost_RetrieveFromPlayerWithValues(Players[0], True);
                            //  DataFileMgr.Replay_Save("My Replays/"^ReplayFileName^"-SEGMENTED.Replay.Gbx", Map, Ghost2);
                            //  Round_LastRaceGhostId = Ghost2.Id;
                         }
                     }
                 }
             }
         }

         // Save replay
         if (TaskId_SaveReplay != NullId) {
             if (DataFileMgr.TaskResults.existskey(TaskId_SaveReplay)) {
                 declare CTaskResult Task = DataFileMgr.TaskResults[TaskId_SaveReplay];
                 if (!Task.IsProcessing) {
                     if (Task.HasSucceeded) {
                         UIModules_EndRaceMenu::SetReplaySaveStatus(UIModules_EndRaceMenu::C_ReplaySaveStatus_Success);
                     } else {
                         UIModules_EndRaceMenu::SetReplaySaveStatus(UIModules_EndRaceMenu::C_ReplaySaveStatus_Fail);
                     }
                     DataFileMgr.TaskResult_Release(Task.Id);
                     TaskId_SaveReplay = NullId;
                 }
             } else {
                 TaskId_SaveReplay = NullId;
             }
         }

         // Loop ghost for replay
         if (GhostRestartTime >= 0 && Now >= GhostRestartTime) {
             UIModules_Fade::AddFade(UIModules_Fade::C_Fade_Out, Now, 500, "");
             if (DataFileMgr.Ghosts.existskey(GhostIdToFollow)) {
                 Ghosts_SetStartTime(Now);
                 GhostRestartTime = Now + DataFileMgr.Ghosts[GhostIdToFollow].Result.Time + GhostRestartDelay;
                 UIModules_Fade::AddFade(UIModules_Fade::C_Fade_In, GhostRestartTime - 250, 200, ColorPalette::C_Color_Black);
             } else {
                 GhostRestartTime = -1;
             }
         }
     }

     // Close end race menu
     StateMgr::ForcePlayersStates([StateMgr::C_State_Waiting]);

     // Stop replay outro
     Ghosts_SetStartTime(-1);
     UIModules_Fade::SetFade(UIModules_Fade::C_Fade_Out, Now, 500, "");
     UIManager.UIAll.UISequence = PrevUISequence;
     UIManager.UIAll.ForceSpectator = False;
     UIManager.UIAll.SpectatorForceCameraType = -1;
     UIManager.UIAll.Spectator_SetForcedTarget_Clear();
     if (!UsePBGhost && GhostAddIdToFollow != NullId) {
         GhostMgr.Ghost_Remove(GhostAddIdToFollow);
     }
     GhostAddIdToFollow = NullId;
     GhostIdToFollow = NullId;
 }

 // Release last race ghost
 if (Round_LastRaceGhostId != NullId) {
     if (DataFileMgr.Ghosts.existskey(Round_LastRaceGhostId)) {
        // GhostMgr.Ghost_Add(DataFileMgr.Ghosts[Round_LastRaceGhostId], True);
        // GhostMgr.Ghost_AddWaypointSynced(DataFileMgr.Ghosts[Round_LastRaceGhostId], True);
        DataFileMgr.Ghost_Release(Round_LastRaceGhostId);
     }
     Round_LastRaceGhostId = NullId;
 }

 StateMgr::ForcePlayersStates([StateMgr::C_State_Waiting]);
 ***

 ***Match_EndServer***
 ***
 foreach (GhostInstanceId in Server_ReplayGhostInstanceIds) {
     GhostMgr.Ghost_Remove(GhostInstanceId);
 }
 Server_ReplayGhostInstanceIds = [];
 foreach (GhostId in Server_ReplayGhostIds) {
     if (DataFileMgr.Ghosts.existskey(GhostId)) {
         DataFileMgr.Ghost_Release(GhostId);
     }
 }
 Server_ReplayGhostIds = [];
 ***

 // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ //
 //
 // ######## ##     ## ##    ##  ######   ######
 // ##       ##     ## ###   ## ##    ## ##    ##
 // ##       ##     ## ####  ## ##       ##
 // ######   ##     ## ## ## ## ##        ######
 // ##       ##     ## ##  #### ##             ##
 // ##       ##     ## ##   ### ##    ## ##    ##
 // ##        #######  ##    ##  ######   ######
 //
 // Functions
 // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ //

 declare K_LoadedGhost[] Archivist_PbGhosts;
 declare K_LoadedGhost[] Archivist_RecentGhosts;
//  declare K_LoadedGhost[] Archivist_PartialGhosts;

 Void AddDebugLog(Text msg) {
    if (!C_IsDebug) return;
    declare netwrite Text Net_DebugMode_Logs for Teams[0];
    declare netwrite Integer Net_DebugMode_Logs_Serial for Teams[0];
    Net_DebugMode_Logs = msg ^ "\n" ^ Net_DebugMode_Logs;
    Net_DebugMode_Logs_Serial += 1;
}

Void MsgToMLHook(Text[] msg) {
    declare netwrite Text[][] Archivist_MsgToAngelscript for Teams[0];
    declare netwrite Integer Archivist_MsgToAngelscript_Serial for Teams[0];
    Archivist_MsgToAngelscript.add(msg);
    Archivist_MsgToAngelscript_Serial = Archivist_MsgToAngelscript.count;
}


CGhost Ghost_RetrieveFromPlayerWithValues(CSmPlayer Player, Boolean Truncate) {
    declare Ghost = Ghost_RetrieveFromPlayer(Player, Truncate);
    if (Ghost == Null || Ghost.Result == Null) return Ghost;
    Ghost.Result.NbRespawns = Player.Score.NbRespawnsRequested;
    if (Truncate) {
        Ghost.Nickname = Ghost.Nickname ^ " (Segmented)";
        // 1399154541 is 0x5365676d which is the bytes "Segm" as an int
        Ghost.Result.Score = 1399154541;
    }
    return Ghost;
}
CGhost Ghost_RetrieveFromPlayerWithValues(CSmPlayer Player) {
    return Ghost_RetrieveFromPlayerWithValues(Player, False);
}


// Archivist stuff
declare K_PluginSettings ArchivistSettings;
declare Text Archivist_Openplanet_Token;
declare Ident[] Server_PbGhosts;



Text OpAuthHeaders() {
    return "Authorization: openplanet " ^ Archivist_Openplanet_Token;
}


Boolean IsFinish() {
    return UIManager.UIAll.UISequence == CUIConfig::EUISequence::Finish;
}

Boolean IsPlaying() {
    return UIManager.UIAll.UISequence == CUIConfig::EUISequence::Playing;
}


 // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ //
 /// Start a task to get the player's record
 K_LoadRecordTask LoadRecord(Text _MapUid, Text _ScopeType, Text _ScopeId, Text _ModeName, Text _ModeCustomData) {
     declare K_LoadRecordTask LoadRecordTask = K_LoadRecordTask {
         IsLoading = True,
         MapUid = _MapUid,
         ScopeType = _ScopeType,
         ScopeId = _ScopeId,
         ModeName = _ModeName,
         ModeCustomData = _ModeCustomData,
         TaskId_LoadScore = NullId,
         TaskId_GetRecordGhost = NullId,
         RecordGhostId = NullId
     };

     // Preload season's records in the cache
     if (LoadRecordTask.ScopeType == MenuConsts::C_ScopeType_Season && LoadRecordTask.ScopeId != "") {
         declare CTaskResult Task_LoadScore = ScoreMgr.Season_LoadScore(MainUser::GetMainUserId(), LoadRecordTask.ScopeId);
         if (Task_LoadScore != Null) {
             LoadRecordTask.TaskId_LoadScore = Task_LoadScore.Id;
         }
     }

     // Load the record immediatly if we're not in a season
     if (LoadRecordTask.TaskId_LoadScore == NullId) {
         declare CTaskResult_Ghost Task_GetRecordGhost = ScoreMgr.Map_GetRecordGhost_v2(
             MainUser::GetMainUserId(),
             LoadRecordTask.MapUid,
             LoadRecordTask.ScopeType,
             LoadRecordTask.ScopeId,
             LoadRecordTask.ModeName,
             LoadRecordTask.ModeCustomData
         );
         if (Task_GetRecordGhost != Null) {
             LoadRecordTask.TaskId_GetRecordGhost = Task_GetRecordGhost.Id;
         }
     }

     return LoadRecordTask;
 }

 // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ //
 /// Check if the task is still ongoing
 K_LoadRecordTask UpdateLoadRecord(K_LoadRecordTask _Task) {
     declare K_LoadRecordTask Task = _Task;

     if (Task.TaskId_LoadScore != NullId) {
         if (ScoreMgr.TaskResults.existskey(Task.TaskId_LoadScore)) {
             if (!ScoreMgr.TaskResults[Task.TaskId_LoadScore].IsProcessing) {
                 ScoreMgr.TaskResult_Release(Task.TaskId_LoadScore);
                 Task.TaskId_LoadScore = NullId;

                 if (Task.TaskId_GetRecordGhost != NullId) {
                     ScoreMgr.TaskResult_Release(Task.TaskId_GetRecordGhost);
                     Task.TaskId_GetRecordGhost = NullId;
                 }
                 declare CTaskResult_Ghost Task_GetRecordGhost = ScoreMgr.Map_GetRecordGhost_v2(
                     MainUser::GetMainUserId(),
                     Task.MapUid,
                     Task.ScopeType,
                     Task.ScopeId,
                     Task.ModeName,
                     Task.ModeCustomData
                 );
                 if (Task_GetRecordGhost != Null) {
                     Task.TaskId_GetRecordGhost = Task_GetRecordGhost.Id;
                 }
             }
         } else {
             Task.TaskId_LoadScore = NullId;
         }
     }

     if (Task.TaskId_GetRecordGhost != NullId) {
         if (ScoreMgr.TaskResults.existskey(Task.TaskId_GetRecordGhost)) {
             declare CTaskResult_Ghost Task_GetRecordGhost = (ScoreMgr.TaskResults[Task.TaskId_GetRecordGhost] as CTaskResult_Ghost);
             if (!Task_GetRecordGhost.IsProcessing) {
                 if (Task_GetRecordGhost.HasSucceeded && Task_GetRecordGhost.Ghost != Null) {
                     Task.RecordGhostId = Task_GetRecordGhost.Ghost.Id;
                 }
                 ScoreMgr.TaskResult_Release(Task_GetRecordGhost.Id);
                 Task.TaskId_GetRecordGhost = NullId;
             }
         } else {
             Task.TaskId_GetRecordGhost = NullId;
         }
     }

     Task.IsLoading = Task.TaskId_LoadScore != NullId || Task.TaskId_GetRecordGhost != NullId;

     return Task;
 }

 // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ //
 /// Retrieve the player's record ghost from the task
 CGhost RetrieveRecordGhost(K_LoadRecordTask _Task) {
     declare CGhost Ghost;
     if (_Task.RecordGhostId != NullId && DataFileMgr.Ghosts.existskey(_Task.RecordGhostId)) {
         return DataFileMgr.Ghosts[_Task.RecordGhostId];
     }
     return Null;
 }

 // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ //
 /// Show/hide the record ghost
 Void DisplayRecordGhost(Boolean _IsVisible) {
     declare Ident PlayMap_RecordGhostId for This;
     declare Ident PlayMap_RecordGhostAddId for This;
     declare Ident PlayMap_RecordGhostAddId_CpSynced for This;

     // Remove previous ghost
     if (PlayMap_RecordGhostAddId != NullId) {
         GhostMgr.Ghost_Remove(PlayMap_RecordGhostAddId);
         PlayMap_RecordGhostAddId = NullId;
     }
     if (PlayMap_RecordGhostAddId_CpSynced != NullId) {
         GhostMgr.Ghost_Remove(PlayMap_RecordGhostAddId_CpSynced);
         PlayMap_RecordGhostAddId_CpSynced = NullId;
     }

     // Add new ghost
     if (_IsVisible && PlayMap_RecordGhostId != NullId && DataFileMgr.Ghosts.existskey(PlayMap_RecordGhostId)) {
         declare CGhost Ghost = DataFileMgr.Ghosts[PlayMap_RecordGhostId];
         PlayMap_RecordGhostAddId = GhostMgr.Ghost_Add(Ghost, True);
         if (ModeConst::C_EnableCPSyncedGhost) {
             PlayMap_RecordGhostAddId_CpSynced = GhostMgr.Ghost_AddWaypointSynced(Ghost, True);
         }
     }
 }

 // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ //
 /// Reset the currently loaded record ghost
 Void ResetRecord() {
     declare Ident PlayMap_RecordGhostAddId for This;
     declare Ident PlayMap_RecordGhostAddId_CpSynced for This;
     if (PlayMap_RecordGhostAddId != NullId) {
         GhostMgr.Ghost_Remove(PlayMap_RecordGhostAddId);
     }
     if (PlayMap_RecordGhostAddId_CpSynced != NullId) {
         GhostMgr.Ghost_Remove(PlayMap_RecordGhostAddId_CpSynced);
     }
     PlayMap_RecordGhostAddId = NullId;
     PlayMap_RecordGhostAddId_CpSynced = NullId;

     declare Ident PlayMap_RecordGhostId for This;
     if (PlayMap_RecordGhostId != NullId && DataFileMgr.Ghosts.existskey(PlayMap_RecordGhostId)) {
         DataFileMgr.Ghost_Release(PlayMap_RecordGhostId);
         Ghost::AvoidDuplicate_Remove(PlayMap_RecordGhostId);
     }
     PlayMap_RecordGhostId = NullId;
 }

 // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ //
 /// Set the a new record ghost
 Void SetRecord(CGhost _Ghost, Boolean _UseAsBestRace) {
     ResetRecord();

     if (_Ghost != Null) {
         declare Ident PlayMap_RecordGhostId for This;
         PlayMap_RecordGhostId = _Ghost.Id;
         Ghost::AvoidDuplicate_Add(PlayMap_RecordGhostId);

         declare Ident PlayMap_RecordGhostAddId for This;
         declare Ident PlayMap_RecordGhostAddId_CpSynced for This;
         declare CGhost RenamedGhost = _Ghost;
         //L16N [Campaign] Name displayed above the ghost of the player's best time.
         RenamedGhost.Nickname = _("Personal best");
         //L16N [Record] Best time done by the player. PB stands for Personnal Best. The translation must be 3 or less letters because it's displayed on the back of the car (as the trigram).
         RenamedGhost.Trigram = _("|Personal best|PB");

         declare Boolean PBGhostIsVisible = True;
         if (AllPlayers.count > 0) {
             PBGhostIsVisible = UIModules_Record::PBGhostIsVisible(AllPlayers[0]);
         }
         DisplayRecordGhost(PBGhostIsVisible);

         if (_UseAsBestRace && _Ghost.Result.Checkpoints.count > 0) {
             foreach (Score in Scores) {
                 Ghost_CopyToScoreBestRaceAndLap(_Ghost, Score);
             }
         }
     }
 }

 // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ //
 /// Get the time of the player's record
 Integer GetRecordTime() {
     declare Ident PlayMap_RecordGhostId for This;
     if (PlayMap_RecordGhostId != NullId && DataFileMgr.Ghosts.existskey(PlayMap_RecordGhostId)) {
         declare CGhost Ghost = DataFileMgr.Ghosts[PlayMap_RecordGhostId];
         if (Ghost.Result.Checkpoints.count > 0) {
             return Ghost.Result.Checkpoints[Ghost.Result.Checkpoints.count - 1];
         }
     }

     return -1;
 }

 // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ //
 /// Reset the currently loaded replay ghost
 Void ResetReplay() {
     declare Ident PlayMap_ReplayGhostAddId for This;
     if (PlayMap_ReplayGhostAddId != NullId) {
         GhostMgr.Ghost_Remove(PlayMap_ReplayGhostAddId);
     }
     PlayMap_ReplayGhostAddId = NullId;

     declare Ident PlayMap_ReplayGhostId for This;
     if (PlayMap_ReplayGhostId != NullId && DataFileMgr.Ghosts.existskey(PlayMap_ReplayGhostId)) {
         DataFileMgr.Ghost_Release(PlayMap_ReplayGhostId);
         Ghost::AvoidDuplicate_Remove(PlayMap_ReplayGhostId);
     }
     PlayMap_ReplayGhostId = NullId;
 }

 // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ //
 /// Set the replay ghost
 Void SetReplay(CGhost _Ghost, Boolean _UseAsBestRace) {
     ResetReplay();

     if (_Ghost != Null) {
         declare Ident PlayMap_ReplayGhostId for This;
         PlayMap_ReplayGhostId = _Ghost.Id;
         Ghost::AvoidDuplicate_Add(PlayMap_ReplayGhostId);

         declare Ident PlayMap_ReplayGhostAddId for This;
         PlayMap_ReplayGhostAddId = GhostMgr.Ghost_Add(_Ghost, True);

         if (_UseAsBestRace && _Ghost.Result.Checkpoints.count > 0) {
             foreach (Score in Scores) {
                 Ghost_CopyToScoreBestRaceAndLap(_Ghost, Score);
             }
         }
     }
 }

 Text RenderPathTemplate(Text Template, CGhost Ghost) {
    declare Text CLDT = System.CurrentLocalDateText;
    declare Integer Timestamp = System.CurrentLocalDate;
    declare CLDTParts = TL::Split(" ", CLDT);
    declare Date = TL::Replace(CLDTParts[0], "/", "-");
    declare Time = TL::Replace(CLDTParts[1], ":", "-");
    declare MapName = TL::Replace(Map.MapInfo.Name, "#", "");
    declare Ret = TL::Replace(Template, "{map_uid}", Map.MapInfo.MapUid);
    Ret = TL::Replace(Ret, "{date_time}", Date^" "^Time);
    Ret = TL::Replace(Ret, "{date}", Date);
    Ret = TL::Replace(Ret, "{duration}", ""^Ghost.Result.Time);
    Ret = TL::Replace(Ret, "{username}", AllPlayers[0].User.Name);
    Ret = TL::Replace(Ret, "{map_name}", TL::StripFormatting(MapName));
    Ret = TL::Replace(Ret, "{timestamp}", ""^Timestamp);
    return Ret;
 }

 Text GhostTemplateFileNameNoSuffix(CGhost Ghost, Boolean IsPartial, Boolean IsSegmented) {
    declare Text ReplayFolderName = RenderPathTemplate(ArchivistSettings.S_ReplayFolderTemplate, Ghost);
    if (ArchivistSettings.S_SeparatePartialRuns) {
        if (IsPartial) {
            ReplayFolderName = ReplayFolderName ^ "/Partial";
        } else {
            ReplayFolderName = ReplayFolderName ^ "/Complete";
        }
        if (IsSegmented) {
            ReplayFolderName = ReplayFolderName ^ "/Segmented";
        }
    }
    declare Text ReplayFileName = RenderPathTemplate(ArchivistSettings.S_ReplayNameTemplate, Ghost);
    ReplayFileName = TL::Replace(ReplayFileName, ".", "");
    ReplayFileName = "Archivist/"^ReplayFolderName^"/"^ReplayFileName;
    return ReplayFileName;
 }

 Void SaveReplay(CGhost Ghost, Boolean IsPartial, Boolean IsSegmented) {
    declare Text ReplayFileName = GhostTemplateFileNameNoSuffix(Ghost, IsPartial, IsSegmented)^".Replay.Gbx";
    AddDebugLog("Saving Replay. Partial: "^IsPartial^", Segmented: "^IsSegmented^", File: "^ReplayFileName);
    declare CTaskResult Task = DataFileMgr.Replay_Save(ReplayFileName, Map, Ghost);
 }

 // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ //
 /** Get the medal and score from the ScoreMgr and update the map with them
  *
  *	@param	_Map map that we want to update the medal and score of
  *
  *	@return						The updated map with the new medal
  */
 CampaignStruct::LibCampaignStruct_K_Map UpdateCurrentMapMedalAndScore(CampaignStruct::LibCampaignStruct_K_Map _Map) {
     declare CampaignStruct::LibCampaignStruct_K_Map CurrentMap = _Map;

     declare Medal = ScoreMgr.Map_GetMedal(
         MainUser::GetMainUserId(),
         _Map.Uid,
         MenuConsts::C_ScopeType_PersonalBest,
         "",
         MenuConsts::C_GameMode_PlayMap,
         ""
     );

     declare Integer MapScore = ScoreMgr.Map_GetRecord_v2(
         MainUser::GetMainUserId(),
         _Map.Uid,
         MenuConsts::C_ScopeType_PersonalBest,
         "",
         MenuConsts::C_GameMode_PlayMap,
         ""
     );

     CurrentMap.Medal = Medal;
     CurrentMap.Score = MapScore;
     return CurrentMap;
 }

 CampaignStruct::LibCampaignStruct_K_Map UpdateCurrentMapInfo() {
     declare CampaignStruct::LibCampaignStruct_K_Map CurrentMap;

     CurrentMap = CampaignStruct::LibCampaignStruct_K_Map {
         Uid = Map.MapInfo.MapUid,
         Name = Map.MapInfo.Name,
         AuthorLogin = Map.MapInfo.AuthorLogin,
         AuthorDisplayName = Map.MapInfo.AuthorNickName,
         AuthorTime = Map.MapInfo.TMObjective_AuthorTime,
         GoldTime = Map.MapInfo.TMObjective_GoldTime,
         SilverTime = Map.MapInfo.TMObjective_SilverTime,
         BronzeTime = Map.MapInfo.TMObjective_BronzeTime
     };

     CurrentMap = UpdateCurrentMapMedalAndScore(CurrentMap);

     return CurrentMap;
 }

 CampaignStruct::LibCampaignStruct_K_Map SetMapNewRecord(CSmPlayer _Player, CampaignStruct::LibCampaignStruct_K_Map _Map) {
     declare CGhost Ghost = Ghost_RetrieveFromPlayerWithValues(_Player);
     declare CampaignStruct::LibCampaignStruct_K_Map UpdatedMap = _Map;
     declare Task::K_Task TaskResult_NewRecord = Task::Create(ScoreMgr, ScoreMgr.Map_SetNewRecord_v2(
         MainUser::GetMainUserId(),
         _Map.Uid,
         MenuConsts::C_GameMode_PlayMap,
         "",
         Ghost
     ));

     if (Task::IsInitialized(TaskResult_NewRecord)) {
         while (Task::IsRunning(TaskResult_NewRecord)) {
             MB_Yield();
             TaskResult_NewRecord = Task::Update(TaskResult_NewRecord);
         }

         if (Task::IsSuccess(TaskResult_NewRecord)) {
             UpdatedMap = UpdateCurrentMapMedalAndScore(UpdatedMap);
         }

         TaskResult_NewRecord = Task::Destroy(TaskResult_NewRecord);
     }

     if (Ghost != Null) DataFileMgr.Ghost_Release(Ghost.Id);

     return UpdatedMap;
 }

 // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ //
 /// Release record ghost data
 K_RecordGhost ReleaseRecordGhost(K_RecordGhost _RecordGhost) {
     Task::Destroy(_RecordGhost.Task_RetrieveRecords);
     Task::Destroy(_RecordGhost.Task_RetrieveGhost);
     if (_RecordGhost.GhostInstanceId != NullId) {
         GhostMgr.Ghost_Remove(_RecordGhost.GhostInstanceId);
     }
     if (_RecordGhost.Ghost != Null && _RecordGhost.Ghost.Id != NullId && DataFileMgr.Ghosts.existskey(_RecordGhost.Ghost.Id)) {
         DataFileMgr.Ghost_Release(_RecordGhost.Ghost.Id);
     }

     return K_RecordGhost {};
 }

 // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ //
 /// Respawn the local player
 Void RespawnLocalPlayer() {
     Ghosts_SetStartTime(Now);
     UIManager.UIAll.ForceSpectator = False;
     UIManager.UIAll.SpectatorForceCameraType = -1;
     UIManager.UIAll.Spectator_SetForcedTarget_Clear();
     UIManager.UIAll.UISequence = CUIConfig::EUISequence::Playing;
     UIModules_Record::SetSpectatorTargetAccountId("");
     if (Players.count > 0 && Players[0] != Null) {
         Race::Start(Players[0]);
     }
 }

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ //
/// Check loaded ghosts against settings to
Void CheckForGhostsToRemove() {
    if (ArchivistSettings.S_KeepAllGhostsLoaded) return;
    declare K_LoadedGhost[Ident] toRemove;
    if (ArchivistSettings.S_NbPbGhosts < Archivist_PbGhosts.count) {
        declare gi = Archivist_PbGhosts[Archivist_PbGhosts.count - 1];
        toRemove[gi.Id] = gi;
        Archivist_PbGhosts.removekey(Archivist_PbGhosts.count - 1);
    }
    if (ArchivistSettings.S_NbRecentGhosts < Archivist_RecentGhosts.count) {
        declare gi = Archivist_RecentGhosts[Archivist_RecentGhosts.count - 1];
        toRemove[gi.Id] = gi;
        Archivist_RecentGhosts.removekey(Archivist_RecentGhosts.count - 1);
    }
    foreach (gi in toRemove) {
        declare Boolean KeepLoaded = False;
        foreach (gi2 in Archivist_PbGhosts) {
            if (gi.InstId == gi2.InstId) {
                KeepLoaded = True;
                break;
            }
        }
        foreach (gi2 in Archivist_RecentGhosts) {
            if (gi.InstId == gi2.InstId) {
                KeepLoaded = True;
                break;
            }
        }

        if (!KeepLoaded) {
            // safe to remove if it isn't in either list anymore
            GhostMgr.Ghost_Remove(gi.InstId);
            if (DataFileMgr.Ghosts.existskey(gi.Id)) {
                DataFileMgr.Ghost_Release(gi.Id);
            }
        }
    }
}

Void AddPbGhost(K_LoadedGhost _GhostInfo) {
    declare Integer insertAt = -1;
    for (I, 0, Archivist_PbGhosts.count - 1) {
        if (_GhostInfo.Time < Archivist_PbGhosts[I].Time) {
            insertAt = I;
            break;
        }
    }
    if (insertAt == -1) {
        Archivist_PbGhosts.add(_GhostInfo);
    } else {
        declare lastIx = Archivist_PbGhosts.count - 1;
        Archivist_PbGhosts.add(Archivist_PbGhosts[lastIx]);
        while (lastIx > insertAt) {
            Archivist_PbGhosts[lastIx] = Archivist_PbGhosts[lastIx - 1];
            lastIx -= 1;
        }
        Archivist_PbGhosts[insertAt] = _GhostInfo;
    }
}
Void AddRecentGhost(K_LoadedGhost _GhostInfo) {
    Archivist_RecentGhosts.addfirst(_GhostInfo);
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ //
/// Add a ghost to the playground based on settings
Void MB_AddGhost(CGhost Ghost, Boolean IsPartial, Boolean IsSegmented) {
    if (!ArchivistSettings.S_KeepAllGhostsLoaded && ArchivistSettings.S_NbPbGhosts == 0) return;
    // todo: add ghost based on settings, mb remove past ghosts
    declare GhostInstanceId = GhostMgr.Ghost_Add(Ghost, True);
    // ghost is now added
    declare _GhostInfo = K_LoadedGhost {
        Id = Ghost.Id,
        InstId = GhostInstanceId,
        Time = Ghost.Result.Time
    };
    if (!IsPartial && !IsSegmented) {
        AddPbGhost(_GhostInfo);
    }
    AddRecentGhost(_GhostInfo);
    CheckForGhostsToRemove();
}


Void MB_SaveReplay(CGhost Ghost, Boolean IsPartial, Boolean IsSegmented) {
    if (ArchivistSettings.S_SaveReplays) {
        SaveReplay(Ghost, IsPartial, IsSegmented);
    }
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ //
/// save a partial replay based on user settings
Void MB_SavePartialReplay(CGhost Ghost) {
    MB_SaveReplay(Ghost, True, False);
}


// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ //
/// Upload a ghost based on user settings
Void MB_UploadGhost(CGhost Ghost, Boolean IsPartial, Boolean IsSegmented) {
    if (ArchivistSettings.S_SaveGhosts) {
        declare Text ReplayFileName = GhostTemplateFileNameNoSuffix(Ghost, IsPartial, IsSegmented)^".Ghost.Gbx";
        AddDebugLog("Upload: Ghost.Id: " ^ Ghost.Id ^ " to file: " ^ ReplayFileName);
        DataFileMgr.Ghost_Upload("http://localhost:29806/" ^ ReplayFileName, Ghost, OpAuthHeaders());
    }
}
Void MB_UploadGhost(CGhost Ghost, Boolean Partial) {
    MB_UploadGhost(Ghost, Partial, False);
}

declare Integer _CountNbGhostsTotal;

Void PostProcessGhost(CGhost Ghost, Boolean Partial, Boolean Trunc) {
    _CountNbGhostsTotal += 1;
    Ghost.Nickname ^= " #" ^ _CountNbGhostsTotal;
    if (Partial) {
        Ghost.Nickname ^= " (Partial)";
    }
}


Void ProcessCompleteTruncGhost(CGhost Ghost) {
    // if the ghost has no respawns, or respawns aren't set, don't save a segmented run b/c the normal replay will be enough.
    if (Ghost.Result.NbRespawns <= 0) return;
    // todo setting for adding truncated ghosts
    MB_UploadGhost(Ghost, False, True);
    MB_SaveReplay(Ghost, False, True);
    MB_AddGhost(Ghost, False, True);
    PostProcessGhost(Ghost, False, True);
}

Void ProcessCompleteGhost(CGhost Ghost) {
    MB_UploadGhost(Ghost, False, False);
    MB_SaveReplay(Ghost, False, False);
    MB_AddGhost(Ghost, False, False);
    PostProcessGhost(Ghost, False, False);
}

Void ProcessPartialGhost(CGhost Ghost) {
    MB_UploadGhost(Ghost, True, False);
    MB_SavePartialReplay(Ghost);
    MB_AddGhost(Ghost, True, False);
    PostProcessGhost(Ghost, True, False);
}



Void ProcessArchivistSetting(Text[] Msgs) {
    ArchivistSettings.fromjson(Msgs[1]);
}


Void ProcessIncoming(Text[] Msgs) {
    if (Msgs.count < 1) return;
    declare Text msgType = Msgs[0];
    // if we have single thing msgs, process here
    if (Msgs.count < 2) return;
    if (msgType == "ArchivistSettings") {
        ProcessArchivistSetting(Msgs);
        return;
    } else if (msgType == "UpdateToken") {
        AddDebugLog("Got Updated Token.");
        Archivist_Openplanet_Token = Msgs[1];
    } else {
        AddDebugLog("Unhandled incoming netread msg: " ^ Msgs);
    }
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ //
/// Process an incoming msg from MLHook. Used to update settings and the like.
/// Note: an individual message is an array of text. usually the first entry is a key that identifies the msg type.
Void ProcessIncomingFromMLHook(Text[] Msgs) {
    if (Msgs.count == 0) return;
    // AddDebugLog("Got MLHook msg (v2): " ^ Msgs);
    ProcessIncoming(Msgs);
}
""".Replace('_"_"_"_', '"""');