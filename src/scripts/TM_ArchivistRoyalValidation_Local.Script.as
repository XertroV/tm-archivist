const string TM_ARCHIVISTROYALVALIDATION_LOCAL_SCRIPT_TXT = """
/**
 *	Royal Validation mode
 */
 #Extends "Modes/Nadeo/Trackmania/Base/TrackmaniaBase.Script.txt"

 #Const CompatibleMapTypes	"TrackMania\\TM_Royal,TM_Royal"
 #Const Version						"1.0.0+2022-10-11"
 #Const ScriptName					"Modes/TrackMania/TM_RoyalValidation_Local.Script.txt"

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ //
// Libraries
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ //
 #Include "TextLib" as TL
 #Include "TimeLib" as TiL
 #Include "Libs/Nadeo/TMGame/Modes/MapGet.Script.txt" as MapGet
 #Include "Libs/Nadeo/CMGame/Modes/Utils.Script.txt" as Utils
 #Include "Libs/Nadeo/Trackmania/Modes/RoyalValidation/StateManager.Script.txt" as StateMgr
 #Include "Libs/Nadeo/Trackmania/Modes/RoyalValidation/Constants.Script.txt" as RoyalConst
 #Include "Libs/Nadeo/TMGame/Modes/Base/UIModules/TimeGap_Server.Script.txt" as UIModules_TimeGap
 #Include "Libs/Nadeo/CMGame/Utils/Http.Script.txt" as Http


 #Struct K_PluginSettings {
    Integer S_NbPbGhosts;
    Integer S_NbRecentGhosts;
    Integer S_SaveAfterRaceTimeMs;
    Boolean S_KeepAllGhostsLoaded;
    Boolean S_RefreshRecordsRegularly;
    Boolean S_NoSaveIfNoMove;
    // Boolean S_UploadGhosts;
    Boolean S_SaveGhosts;
    Boolean S_SaveReplays;
    Boolean S_SeparatePartialRuns;
    Boolean S_SaveTruncatedRuns;
    Text S_ReplayNameTemplate;
    Text S_ReplayFolderTemplate;
}

 #Struct K_ValidationResult {
    Text GhostId;
}


// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ //
// Constants
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ //
 #Const C_HudModulePath "" //< Path to the hud module
 #Const C_ManiaAppUrl "file://Media/ManiaApps/Nadeo/Trackmania/Modes/RoyalValidation.Script.txt" //< Url of the mania app
 #Const C_EnableAutomaticGiveUpAfterElimination True

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ //
// Extends
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ //
***Match_LogVersions***
***
Log::RegisterScript(ScriptName, Version);
Log::RegisterScript(MapGet::ScriptName, MapGet::Version);
Log::RegisterScript(StateMgr::ScriptName, StateMgr::Version);
Log::RegisterScript(RoyalConst::ScriptName, RoyalConst::Version);
Log::RegisterScript(UIModules_TimeGap::ScriptName, UIModules_TimeGap::Version);
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
MB_Settings_UseDefaultPodiumSequence = False;
MB_Settings_UseDefaultTimer = False;
MB_Settings_UseDefaultHud = (C_HudModulePath == "");
Race_Settings_IsLocalMode = True;
Race_Settings_UseDefaultUIManagement = False;
***

***Match_LoadHud***
***
if (C_HudModulePath != "") Hud_Load(C_HudModulePath);
***

***Match_AfterLoadHud***
***
ClientManiaAppUrl = C_ManiaAppUrl;
UIModules_TimeGap::SetTimeGapMode(UIModules_TimeGap::C_TimeGapMode_Hidden);
UIManager.UIAll.ScoreTableVisibility = CUIConfig::EVisibility::ForcedHidden;
UIManager.UIAll.AltMenuNoDefaultScores = True;
UIManager.UIAll.OverlayHideGauges = True;
UIManager.UIAll.CountdownCoord = <0., -200.>;
UIManager.UIAll.LabelsVisibility = CUIConfig::EHudVisibility::Nothing;
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
***

***Match_InitServer***
***
declare netwrite Boolean Net_RoyalEndRaceMenu_IsVisible for Teams[0] = False;
***

***Match_StartServer***
***
// Initialize mode
Net_RoyalEndRaceMenu_IsVisible = False;
Clans::SetClansNb(0);
Race::SetRespawnBehaviour(Race::C_RespawnBehaviour_Normal);
Race::EnableAutomaticGiveUpAfterElimination(C_EnableAutomaticGiveUpAfterElimination);
StateMgr::ForcePlayersStates([StateMgr::C_State_Waiting]);
***

***Match_InitMap***
***
LoadInitSettings();
LocalPlayerLogin = "1";

declare CMapLandmark[] Map_Starts;
declare Integer[] Map_StartOrders;
***

***Match_StartMap***
***
// Initialize author data with currently saved author data
MapGet::ShareAuthorTime(Map.TMObjective_AuthorTime);

// Initialize starts
declare CMapLandmark[] Starts = Map::GetStarts();
declare CMapLandmark[Integer] SortedStarts;
Map_Starts = [];
Map_StartOrders = [];
foreach (Start in Starts) {
    SortedStarts[Start.Order] = Start;
    if (!Map_StartOrders.exists(Start.Order)) {
        Map_StartOrders.add(Start.Order);
    }
}
SortedStarts = SortedStarts.sortkey();
foreach (Start in SortedStarts) {
    Map_Starts.add(Start);
}
if (Map_Starts.count <= 0) {
    //L16N [RoyalValidation] Message explaining to the player that a track has to contain at least one start line block.
    UIManager.UIAll.QueueMessage(3000, 1, CUIConfig::EMessageDisplay::Big, _("You must place at least one starting point."));
    MB_Sleep(3000);
    MB_StopServer();
} else {
    Map::SetDefaultStart(Map_Starts[0]);
}
***

***Match_InitRound***
***
declare Integer[] Round_ValidatedFinishes;
declare Integer Round_RaceTime;

UIManager.UIAll.BigMessage = "Archivist Validation";
***

***Match_StartRound***
***
StateMgr::ForcePlayersStates([StateMgr::C_State_Playing]);
MB_EnablePlayMode(True);

Round_ValidatedFinishes = [];
Round_RaceTime = -1;

// Spawn player
StartTime = Now + Race::C_SpawnDuration;
Race::ResetSolo();
foreach (Player in Players) {
    Start(Player, Map_Starts, Round_ValidatedFinishes.count, StartTime);
	LocalPlayerLogin = Player.User.Login;
}
***

***Match_PlayLoop***
***
// Manage race events
foreach (Event in Race::GetPendingEvents()) {
    Race::ValidEvent(Event);

    switch (Event.Type) {
        case Events::C_Type_Waypoint: {
            if (Event.Player != Null) {
                if (Event.IsEndRace) {

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

                    declare CGhost NewAuthorGhost <=> Ghost_RetrieveFromPlayer(Event.Player);
					if (NewAuthorGhost != Null) {
						// if (Map_State.NewAuthorGhost != Null) DataFileMgr.Ghost_Release(Map_State.NewAuthorGhost.Id);
						// Map_State.NewAuthorGhost <=> NewAuthorGhost;
						ProcessCompleteGhost(NewAuthorGhost);
					}

                    Race::StopSkipScoresTable(Event.Player); //< override the outro sequence duration and do not display the scores table
                    if (Event.Landmark != Null && !Round_ValidatedFinishes.exists(Event.Landmark.Order)) {
                        Round_ValidatedFinishes.add(Event.Landmark.Order);
                    }
                    if (Round_RaceTime < 0) {
                        Round_RaceTime = Event.RaceTime;
                    } else {
                        Round_RaceTime += Event.RaceTime;
                    }
                    if (Map_StartOrders.containsonly(Round_ValidatedFinishes)) {
                        MB_StopRound();
                    }
                }
            }
        }
        case Events::C_Type_GiveUp: {
        if (Event.Player != Null) {
            // get a partial ghost
            declare CGhost _Ghost = Ghost_RetrieveFromPlayerWithValues(Event.Player, False);
            _Ghost.Result.Time = Event.Player.CurrentRaceTime;
            if (_Ghost != Null) {
                ProcessPartialGhost(_Ghost);
            }
        }
            Round_ValidatedFinishes = [];
            Round_RaceTime = -1;
        }
    }
}

// Manage mode events
foreach (Event in PendingEvents) {
    if (Event.HasBeenPassed || Event.HasBeenDiscarded) continue;
    Events::Invalid(Event);
}

// Manage UI events
foreach (Event in UIManager.PendingEvents) {
    if (Event.Type == CUIConfigEvent::EType::OnLayerCustomEvent) {
        if (Event.CustomEventType == RoyalConst::C_EventType_ViewPodium) {
            foreach (Player in Players) {
                Race::StopSkipOutro(Player);
            }
            ViewRacePodium();
        }
    }
}

if (MB_RoundIsRunning()) {
    foreach (Player in Players) {
        // Spawn player
        if (Race::IsReadyToStart(Player)) {
            Race::ResetSolo();
            Start(Player, Map_Starts, Round_ValidatedFinishes.count);
        } else if (Player.CurrentRaceTime > -100 && TL::Length(UIManager.UIAll.BigMessage) > 0) {
            UIManager.UIAll.BigMessage = "";
        }
    }
}
***


***Match_EndRound***
***
// Wait for the end of the player race outro
declare Boolean OutroFinished = False;
while (MB_MapIsRunning() && !OutroFinished) {
    MB_Yield();

    declare Events::K_RaceEvent[] RacePendingEvents = Race::GetPendingEvents();
    foreach (Event in RacePendingEvents) {
        if (Event.Type == Events::C_Type_SkipOutro) {
            Race::ValidEvent(Event);
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
        }
    }
}

// Unspawn players
foreach (Player in Players) {
    Race::StopSkipOutro(Player);
}
MB_Yield(); //< Sleep one frame to be sure that player is properly unspawn
MB_EnablePlayMode(False);
StateMgr::ForcePlayersStates([StateMgr::C_State_Waiting]);
StartTime = -1;

// Save new time if better
if (Round_RaceTime >= 0 && (Round_RaceTime < MapGet::GetSharedAuthorTime() || MapGet::GetSharedAuthorTime() < 0)) {
    MapGet::ShareAuthorTime(Round_RaceTime);
}

// Show end race menu
Net_RoyalEndRaceMenu_IsVisible = True;
declare CUIConfig::EUISequence UISequenceToRestore = UIManager.UIAll.UISequence;
UIManager.UIAll.UISequence = CUIConfig::EUISequence::Podium;

// Wait for player action
declare Boolean WaitAnswer = True;
while (WaitAnswer && MB_ServerIsRunning()) {
    MB_Yield();
    // Check if an event from the RaceValidationMenu UI has been received and apply it if needed
    foreach (Event in UIManager.PendingEvents) {
        if (Event.Type == CUIConfigEvent::EType::OnLayerCustomEvent) {
            if (Event.CustomEventType == RoyalConst::C_EventType_Retry) {
                WaitAnswer = False;
            } else if (Event.CustomEventType == RoyalConst::C_EventType_Quit) {
                WaitAnswer = False;
                MB_StopServer();
            }
        }
    }
}

// Hide end race menu
UIManager.UIAll.UISequence = UISequenceToRestore;
Net_RoyalEndRaceMenu_IsVisible = False;
***

***Match_EndMap***
***
StateMgr::ForcePlayersStates([StateMgr::C_State_Waiting]);
***




declare K_PluginSettings ArchivistSettings;
declare CTaskResult[] A_PendingWebTasks;
declare Http::K_Request[] A_PendingHttpTasks;

declare Text LocalPlayerLogin;


 // for use with Beu's debug script
 Void AddDebugLog(Text msg) {
	// if (!C_IsDebug) return;
	declare netwrite Text Net_DebugMode_Logs for Teams[0];
	declare netwrite Integer Net_DebugMode_Logs_Serial for Teams[0];
	Net_DebugMode_Logs = msg ^ "\n" ^ Net_DebugMode_Logs;
	Net_DebugMode_Logs_Serial += 1;
}



// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ //
// Functions
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ //
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ //
/// Spawn the player at the right start line
Void Start(CSmPlayer _Player, CMapLandmark[] _Starts, Integer _ActiveSegment, Integer _SpawnTime) {
    if (!_Starts.existskey(_ActiveSegment)) return;
    _Player.LandmarkOrderSelector_Race = _Starts[_ActiveSegment].Order;
    Race::Start(_Player, _Starts[_ActiveSegment], _SpawnTime);
}
Void Start(CSmPlayer _Player, CMapLandmark[] _Starts, Integer _ActiveSegment) {
    Start(_Player, _Starts, _ActiveSegment, Now + Race::C_SpawnDuration);
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ //
/// Display the podium sequence
Void ViewRacePodium() {
    declare netwrite Boolean Net_RoyalValidation_RacePodiumIsVisible for Teams[0] = False;
    Net_RoyalValidation_RacePodiumIsVisible = True;
    Utils::PushAndApplyUISequence(UIManager.UIAll, CUIConfig::EUISequence::Podium);

    UIManager.UIAll.UISequence_PodiumPlayersWin = LocalPlayerLogin ^ ",2,3";
    UIManager.UIAll.UISequence_PodiumPlayersLose = "4,5,6";

    declare Boolean PodiumIsActive = True;
    while (PodiumIsActive) {
        MB_Yield();

        foreach (Event in UIManager.PendingEvents) {
            if (Event.Type == CUIConfigEvent::EType::OnLayerCustomEvent) {
                if (Event.CustomEventType == RoyalConst::C_EventType_ExitPodium) {
                    PodiumIsActive = False;
                }
            }
        }
    }

    Utils::PopAndApplyUISequence(UIManager.UIAll);
    Net_RoyalValidation_RacePodiumIsVisible = False;
}



/**
 *    db    88""Yb  dP""b8 88  88 88 Yb    dP 88 .dP"Y8 888888     888888 88   88 88b 88  dP""b8 .dP"Y8
 *   dPYb   88__dP dP   `" 88  88 88  Yb  dP  88 `Ybo."   88       88__   88   88 88Yb88 dP   `" `Ybo."
 *  dP__Yb  88"Yb  Yb      888888 88   YbdP   88 o.`Y8b   88       88""   Y8   8P 88 Y88 Yb      o.`Y8b
 * dP_"_"_"_"Yb 88  Yb  YboodP 88  88 88    YP    88 8bodP'   88       88     `YbodP' 88  Y8  YboodP 8bodP'
 */



Void MsgToMLHook(Text[] msg) {
	declare netwrite Text[][] Archivist_MsgToAngelscript for Teams[0];
	declare netwrite Integer Archivist_MsgToAngelscript_Serial for Teams[0];
	Archivist_MsgToAngelscript.add(msg);
	Archivist_MsgToAngelscript_Serial = Archivist_MsgToAngelscript.count;
}

Text OpAuthHeaders() {
	return "Authorization: none";
}

Boolean IsFinish() {
	return UIManager.UIAll.UISequence == CUIConfig::EUISequence::Finish;
}

Boolean IsPlaying() {
	return UIManager.UIAll.UISequence == CUIConfig::EUISequence::Playing;
}

Void LoadInitSettings() {
	ArchivistSettings = K_PluginSettings {
		S_NbPbGhosts = 0,
		S_NbRecentGhosts = 0,
		S_SaveAfterRaceTimeMs = 2000,
		S_KeepAllGhostsLoaded = False,
		S_RefreshRecordsRegularly = False,
		S_NoSaveIfNoMove = True,
		S_SaveGhosts = True,
		S_SaveReplays = False,
		S_SeparatePartialRuns = True,
		S_SaveTruncatedRuns = True,
		S_ReplayNameTemplate = "{date_time} {duration}ms {username}",
		S_ReplayFolderTemplate = "{map_name}-validation"
	};
	AddDebugLog("Setting initial settings: " ^ ArchivistSettings);
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


Text RenderPathTemplate(Text Template, CGhost Ghost) {
	declare Text CLDT = System.CurrentLocalDateText;
	declare Integer Timestamp = System.CurrentLocalDate;
	declare CLDTParts = TL::Split(" ", CLDT);
	declare Date = TL::Replace(CLDTParts[0], "/", "-");
	declare Time = TL::Replace(CLDTParts[1], ":", "-");
	declare CleanMapName = TL::Replace(Map.MapInfo.Name, "#", "");
	CleanMapName = TL::Replace(CleanMapName, "/", "-");
	CleanMapName = TL::Replace(CleanMapName, "\\", "-");
	CleanMapName = TL::Replace(CleanMapName, ":", "-");
	CleanMapName = TL::Replace(CleanMapName, "*", "");
	CleanMapName = TL::Replace(CleanMapName, "?", "");
	CleanMapName = TL::Replace(CleanMapName, "\"", "");
	CleanMapName = TL::Replace(CleanMapName, "<", "(");
	CleanMapName = TL::Replace(CleanMapName, ">", ")");
	CleanMapName = TL::Replace(CleanMapName, "|", "");
	declare Ret = TL::Replace(Template, "{map_uid}", Map.MapInfo.MapUid);
	Ret = TL::Replace(Ret, "{date_time}", Date^" "^Time);
	Ret = TL::Replace(Ret, "{date}", Date);
	Ret = TL::Replace(Ret, "{duration}", ""^Ghost.Result.Time);
	Ret = TL::Replace(Ret, "{username}", AllPlayers[0].User.Name);
	Ret = TL::Replace(Ret, "{map_name}", TL::StripFormatting(CleanMapName));
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




// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ //
/// Upload a ghost based on user settings
Void MB_UploadGhost(CGhost Ghost, Boolean IsPartial, Boolean IsSegmented) {
	if (ArchivistSettings.S_SaveGhosts) {
		declare Text ReplayFileName = GhostTemplateFileNameNoSuffix(Ghost, IsPartial, IsSegmented)^".Ghost.Gbx";
		AddDebugLog("Upload: Ghost.Id: " ^ Ghost.Id ^ " to file: " ^ ReplayFileName);
		declare UploadTask = DataFileMgr.Ghost_Upload("http://localhost:29806/" ^ ReplayFileName, Ghost, OpAuthHeaders());
		A_PendingWebTasks.add(UploadTask);
	} else {
		AddDebugLog("Skipping upload ghost b/c settings.");
	}
}
Void MB_UploadGhost(CGhost Ghost, Boolean Partial) {
	MB_UploadGhost(Ghost, Partial, False);
}

declare Integer _CountNbGhostsTotal;

Void PostProcessGhost(CGhost Ghost, Boolean Partial, Boolean Trunc) {
	// sometimes we get an error about a missing key when we try to use Ghost.Nickname
	if (!DataFileMgr.Ghosts.existskey(Ghost.Id)) return;
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
	PostProcessGhost(Ghost, False, True);
}

Void ProcessCompleteGhost(CGhost Ghost) {
	MB_UploadGhost(Ghost, False, False);
	PostProcessGhost(Ghost, False, False);
}

Void ProcessPartialGhost(CGhost Ghost) {
	MB_UploadGhost(Ghost, True, False);
	PostProcessGhost(Ghost, True, False);
}


Void CheckClearTaskResults() {
	declare CTaskResult[] ToRemove;
	foreach (Task in A_PendingWebTasks) {
		if (!Task.IsProcessing) {
			if (DataFileMgr.TaskResults.existskey(Task.Id)) {
				DataFileMgr.TaskResult_Release(Task.Id);
			}
			ToRemove.add(Task);
		}
	}
	foreach (Task in ToRemove) {
		A_PendingWebTasks.remove(Task);
		AddDebugLog("Cleared DFM pending task");
	}

	declare Integer[] HttpToRem;
	foreach (Ix => Req in A_PendingHttpTasks) {
		A_PendingHttpTasks[Ix] = Http::Update(Req);
		if (A_PendingHttpTasks[Ix].IsDestroyed) {
			// Ix is in reverse order (largest to smallest)
			HttpToRem.addfirst(Ix);
		}
	}
	// Ix is in reverse order (largest to smallest)
	foreach (Ix in HttpToRem) {
		A_PendingHttpTasks.removekey(Ix);
		AddDebugLog("Cleared Http Request with Ix: " ^ Ix);
	}
}
""".Replace('_"_"_"_', '"""');