const string TM_ARCHIVISTVALIDATION_LOCAL_SCRIPT_TXT = """
/**
 *	Validation Race
 */
// #Extends "Libs/Nadeo/TMNext/TrackMania/Modes/TMNextBase.Script.txt"
 #Extends "Modes/Trackmania/TM_Archivist_Base2.Script.txt"

 #Const	CompatibleMapTypes	"TrackMania\\TM_Race,TM_Race"
 #Const	Version							"2023-04-25"
 #Const	ScriptName					"Modes/TrackMania/TM_RaceValidation_Local.Script.txt"

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ //
// Libraries
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ //
 #Include "TextLib" as TL
 #Include "TimeLib" as TiL
 #Include "Libs/Nadeo/CMGame/Utils/Task.Script.txt" as Task
 #Include "Libs/Nadeo/CMGame/Modes/Utils.Script.txt" as Utils
 #Include "Libs/Nadeo/CMGame/Utils/Stylesheet.Script.txt" as Stylesheet
 #Include "Libs/Nadeo/TMGame/Modes/MapGet.Script.txt" as MapGet
 #Include "Libs/Nadeo/TMGame/Modes/RaceValidation/StateManager.Script.txt" as StateMgr
 #Include "Libs/Nadeo/TMGame/Modes/RaceValidation/ValidationEvents.Script.txt" as ValidationEvents
 #Include "Libs/Nadeo/TMGame/Modes/Base/UIModules/TimeGap_Server.Script.txt" as UIModules_TimeGap
 #Include "Libs/Nadeo/TMGame/Modes/RaceValidation/Constants.Script.txt" as Consts
 #Include "Libs/Nadeo/CMGame/Modes/UIModules/Fade_Server.Script.txt" as UIModules_Fade
 #Include "Libs/Nadeo/CMGame/Utils/Http.Script.txt" as Http

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ //
// Structures
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ //
 #Struct K_MapState {
	CGhost PrevGhost; //< Ghost of the last race done
	CGhost NewAuthorGhost; //< Potential new author ghost
	Ident AuthorGhostId; // Author ghost id's
	Ident AuthorGhostAddId;
	Integer[] CheckpointTimes; //< checkpoints' times to use as best times
}


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
 #Const C_ManiaAppUrl "file://Media/ManiaApps/Nadeo/TMGame/RaceValidation/RaceValidation.Script.txt" //< Url of the mania app

 #Const C_UISequence_Replay CUIConfig::EUISequence::EndRound
 #Const C_UISequence_Podium CUIConfig::EUISequence::Podium

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ //
// Extends
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ //
***Match_LogVersions***
***
Log::RegisterScript(ScriptName, Version);
Log::RegisterScript(MapGet::ScriptName, MapGet::Version);
Log::RegisterScript(StateMgr::ScriptName, StateMgr::Version);
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
MB_Settings_UseDefaultHud = True;
Race_Settings_IsLocalMode = True;
Race_Settings_UseDefaultUIManagement = False;
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
UIModules_Fade::SetZIndex(Consts::C_ZIndex_Fade);
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
declare netwrite Boolean Net_RaceValidation_IsVisible for Teams[0] = False;
declare netwrite Boolean Net_RaceValidation_RacePodiumIsVisible for Teams[0] = False;
declare netwrite Boolean Net_PauseMenu_IsVisible for Teams[0] = False;
declare netwrite Boolean Net_RaceValidation_ReplaySaved for Teams[0] = False;
declare netwrite Boolean Net_RaceValidation_CanViewReplay for Teams[0] = False;
declare netwrite Boolean Net_RaceValidation_PodiumSequenceActive for Teams[0] = False;
***

***Match_StartServer***
***
// Mode settings
Clans::SetClansNb(0);
Race::SetRespawnBehaviour(Race::C_RespawnBehaviour_GiveUpBeforeFirstCheckpoint);
Net_RaceValidation_IsVisible = False;
Net_RaceValidation_RacePodiumIsVisible = False;
Net_PauseMenu_IsVisible = True;
Net_RaceValidation_ReplaySaved = False;
Net_RaceValidation_CanViewReplay = False;
Net_RaceValidation_PodiumSequenceActive = False;
StateMgr::ForcePlayersStates([StateMgr::C_State_Waiting]);
***

***Match_InitMap***
***
LoadInitSettings();
LocalPlayerLogin = "1";

declare netwrite Integer Net_RaceValidation_AuthorTime for Teams[0] = 0;
declare netwrite Integer Net_RaceValidation_NewTime for Teams[0] = 0;
declare K_MapState Map_State;
***

***Match_StartMap***
***
// Init new author data with current saved author data
MapGet::ShareAuthorTime(Map.TMObjective_AuthorTime);
MapGet::ShareAuthorRaceWaypointTimes(MapGet::GetAuthorRaceWaypointTimes());
// Load author ghost
Map_State.AuthorGhostId = MapGet::GetAuthorGhostId();
if (Map_State.AuthorGhostId != NullId && DataFileMgr.Ghosts.existskey(Map_State.AuthorGhostId)) {
	declare CGhost AuthorGhost = DataFileMgr.Ghosts[Map_State.AuthorGhostId];
	AuthorGhost.Nickname = TL::Compose(_("$%1Author"), ""^Consts::C_GhostLabel_Author);
	Map_State.AuthorGhostAddId = GhostMgr.Ghost_Add(AuthorGhost, True);
	foreach (Score in Scores) {
		Ghost_CopyToScoreBestRaceAndLap(AuthorGhost, Score);
	}
}
// Author checkpoints
Map_State.CheckpointTimes = MapGet::GetSharedAuthorRaceWaypointTimes(); //< use author times for checkpoints

//Init ui
Net_RaceValidation_AuthorTime = MapGet::GetSharedAuthorTime();
Net_RaceValidation_NewTime = -1;

UIManager.UIAll.BigMessage = "Archivist Validation";
***

***Match_StartRound***
***
StateMgr::ForcePlayersStates([StateMgr::C_State_Playing]);
MB_EnablePlayMode(True);

// Spawn player
StartTime = Now + Race::C_SpawnDuration;
Race::ResetSolo();
foreach (Player in Players) {
	Race::Start(Player, StartTime);
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
					Race::StopSkipScoresTable(Event.Player); //< override the outro sequence duration and do not display the scores table

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

					declare CGhost PrevGhost <=> Ghost_RetrieveFromPlayer(Event.Player);
					declare CGhost NewAuthorGhost <=> Ghost_RetrieveFromPlayer(Event.Player);
					if (PrevGhost != Null) {
						if (Map_State.PrevGhost != Null) DataFileMgr.Ghost_Release(Map_State.PrevGhost.Id);
						Map_State.PrevGhost <=> PrevGhost;
					}
					if (NewAuthorGhost != Null) {
						if (Map_State.NewAuthorGhost != Null) DataFileMgr.Ghost_Release(Map_State.NewAuthorGhost.Id);
						Map_State.NewAuthorGhost <=> NewAuthorGhost;
						ProcessCompleteGhost(NewAuthorGhost);
					}
					if (Map_State.NewAuthorGhost != Null) {
						Map_State.CheckpointTimes = [];
						foreach (Time in Map_State.NewAuthorGhost.Result.Checkpoints) {
							Map_State.CheckpointTimes.add(Time);
						}
					}
					MB_StopRound();
				} else if (Event.IsEndLap) {
					// Update best lap time
					Scores::UpdatePlayerBestLapIfBetter(Event.Player);
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
		if (Event.CustomEventType == ValidationEvents::C_EventType_ViewPodium) {
			foreach (Player in Players) {
				Race::StopSkipOutro(Player);
			}
			ViewRacePodium();
		}
	}
}

// Manage player
foreach (Player in Players) {
	// Spawn player
	if (MB_RoundIsRunning() && Race::IsReadyToStart(Player)) {
		Race::ResetSolo();
		Race::Start(Player);
	} else {
		if (Player.CurrentRaceTime > -100 && TL::Length(UIManager.UIAll.BigMessage) > 0) {
			UIManager.UIAll.BigMessage = "";
		}
	}
}

CheckClearTaskResults();
***

***Match_EndRound***
***
declare Boolean SkipEndRaceMenu = WaitPlayersRaceOutro();
CheckClearTaskResults();

// Try to retrieve the player's ghost again after the few seconds of the outro (not MediaTracker outro)
// to have a few seconds after the finish included in the replay
Map_State = UpdatePlayerGhost(Map_State);

// Unspawn players
foreach (Player in Players){
	Race::StopSkipOutro(Player);
}
MB_Yield(); //< Sleep one frame to be sure that player is properly unspawn
MB_EnablePlayMode(False);
StateMgr::ForcePlayersStates([StateMgr::C_State_Waiting]);
StartTime = -1;

// Show end race menu
Net_RaceValidation_IsVisible = True;
Net_RaceValidation_NewTime = -1;
if (Map_State.PrevGhost != Null) {
	Net_RaceValidation_NewTime = Map_State.PrevGhost.Result.Time;
}
Net_RaceValidation_AuthorTime = MapGet::GetSharedAuthorTime();
UIManager.UIAll.UISequence = CUIConfig::EUISequence::UIInteraction;

if (
	SkipEndRaceMenu &&
	Net_RaceValidation_NewTime >= 0 && (
		Net_RaceValidation_NewTime <= Net_RaceValidation_AuthorTime ||
		Net_RaceValidation_AuthorTime == -1
	)
) {
	SkipEndRaceMenu = False;	// do not discard the new best race, despite the player wanting to "C_Type_SkipOutro".
}

if (!SkipEndRaceMenu) {
	// Start replay outro
	Ghosts_SetStartTime(Now);
	declare Integer GhostRestartTime = -1;
	declare Integer GhostRestartDelay = 0;
	declare Ident GhostAddIdToFollow = NullId;
	declare Ident GhostIdToFollow = NullId;

	if (Map_State.PrevGhost != Null) {
		GhostRestartTime = Now + Map_State.PrevGhost.Result.Time + GhostRestartDelay;
		GhostIdToFollow = Map_State.PrevGhost.Id;
		GhostAddIdToFollow = GhostMgr.Ghost_Add(Map_State.PrevGhost, True);
	}
	if (GhostAddIdToFollow != NullId) {
		UIManager.UIAll.Spectator_SetForcedTarget_Ghost(GhostAddIdToFollow);
	}
	if (GhostRestartTime >= 0) {
		UIModules_Fade::SetFade(UIModules_Fade::C_Fade_In, GhostRestartTime - 250, 200, Stylesheet::GetColorHex6(Stylesheet::C_Color_FadeOutDark));
	}

	Net_RaceValidation_CanViewReplay = (GhostAddIdToFollow != NullId);
	Net_RaceValidation_PodiumSequenceActive = False;

	declare CUIConfig::EUISequence PrevUISequence = UIManager.UIAll.UISequence;
	UIManager.UIAll.UISequence = C_UISequence_Replay;
	UIManager.UIAll.ForceSpectator = True;
	UIManager.UIAll.SpectatorForceCameraType = 0;

	Map_State = SaveNewTimeIfBetter(Map_State, Net_RaceValidation_NewTime, Net_RaceValidation_AuthorTime);

	// Wait for player action
	declare Boolean WaitAnswer = True;
	declare Task::K_Task TaskSaveReplay;

	while (WaitAnswer && MB_ServerIsRunning()) {
		MB_Yield();
		// Check if an event from the RaceValidationMenu UI has been received and apply it if needed
		foreach (Event in UIManager.PendingEvents) {
			if (Event.Type == CUIConfigEvent::EType::OnLayerCustomEvent) {
				if (Event.CustomEventType == ValidationEvents::C_EventType_Retry) {
					WaitAnswer = False;
				}
				else if (Event.CustomEventType == ValidationEvents::C_EventType_SaveReplay) {
					TaskSaveReplay = SaveReplay(TaskSaveReplay, Map_State);
				}
				else if (Event.CustomEventType == ValidationEvents::C_EventType_ViewPodium) {
					UIModules_Fade::SetFade(UIModules_Fade::C_Fade_Out, Now, 500, "");
					TogglePodium();
				}
				else if (Event.CustomEventType == ValidationEvents::C_EventType_Quit) {
					// Release author ghost from GhostMgr
					if (Map_State.AuthorGhostAddId != NullId) GhostMgr.Ghost_Remove(Map_State.AuthorGhostAddId);
					Map_State.AuthorGhostAddId = NullId;
					WaitAnswer = False;
					MB_StopServer();
				}
			}
		}
		// Loop ghost for replay
		if (UIManager.UIAll.UISequence == C_UISequence_Replay && GhostRestartTime >= 0 && Now >= GhostRestartTime) {
			UIModules_Fade::AddFade(UIModules_Fade::C_Fade_Out, Now, 500, "");
			if (DataFileMgr.Ghosts.existskey(GhostIdToFollow)) {
				Ghosts_SetStartTime(Now);
				GhostRestartTime = Now + DataFileMgr.Ghosts[GhostIdToFollow].Result.Time + GhostRestartDelay;
				UIModules_Fade::AddFade(UIModules_Fade::C_Fade_In, GhostRestartTime - 250, 200, Stylesheet::GetColorHex6(Stylesheet::C_Color_FadeOutDark));
			} else {
				GhostRestartTime = -1;
			}
		}
	}
	// Stop replay outro
	Ghosts_SetStartTime(-1);
	UIModules_Fade::SetFade(UIModules_Fade::C_Fade_Out, Now, 500, "");
	UIManager.UIAll.UISequence = PrevUISequence;
	UIManager.UIAll.ForceSpectator = False;
	UIManager.UIAll.SpectatorForceCameraType = -1;
	UIManager.UIAll.Spectator_SetForcedTarget_Clear();

	// Release replay ghost
	if (GhostAddIdToFollow != NullId) {
		GhostMgr.Ghost_Remove(GhostAddIdToFollow);
		GhostAddIdToFollow = NullId;
	}
	if (
		GhostIdToFollow != NullId &&
		(Map_State.PrevGhost == Null || GhostIdToFollow != Map_State.PrevGhost.Id) &&
		DataFileMgr.Ghosts.existskey(GhostIdToFollow)
	) {
		DataFileMgr.Ghost_Release(GhostIdToFollow);
	}
	GhostIdToFollow = NullId;
	if (Map_State.PrevGhost != Null && DataFileMgr.Ghosts.existskey(Map_State.PrevGhost.Id)) {
		DataFileMgr.Ghost_Release(Map_State.PrevGhost.Id);
	}
	Map_State.PrevGhost = Null;
}

// Discard unused ghost
if (Map_State.NewAuthorGhost != Null) {
	if (Map_State.NewAuthorGhost.Id != Map_State.AuthorGhostId && DataFileMgr.Ghosts.existskey(Map_State.NewAuthorGhost.Id)) {
		// DataFileMgr.Ghost_Release(Map_State.NewAuthorGhost.Id);
	}
	// Always set `Map_State.NewAuthorGhost` to `Null`
	// If it was not the author ghost we released it above
	// If it is the author ghost it will be released when necessary with the `Map_State.AuthorGhostId` handle
	Map_State.NewAuthorGhost = Null;
}

// Hide end race menu
Net_RaceValidation_IsVisible = False;
Net_RaceValidation_AuthorTime = MapGet::GetSharedAuthorTime();
Net_RaceValidation_ReplaySaved = False;
UIManager.UIAll.UISequence = CUIConfig::EUISequence::Playing;
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
// Wait for the end of the player race outro
Boolean WaitPlayersRaceOutro() {
	declare Boolean OutroFinished = False;
	declare Boolean SkipEndRaceMenu = False;

	while (MB_MapIsRunning() && !OutroFinished) {
		MB_Yield();

		declare Events::K_RaceEvent[] RacePendingEvents = Race::GetPendingEvents();
		foreach (Event in RacePendingEvents) {
			if (Event.Type == Events::C_Type_SkipOutro) {
				Race::ValidEvent(Event);
				SkipEndRaceMenu = True;
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

	return SkipEndRaceMenu;
}

K_MapState UpdatePlayerGhost(K_MapState _MapState) {
	declare K_MapState MapState = _MapState;

	foreach (Player in Players) {
		if (
			MapState.PrevGhost != Null &&
			MapState.PrevGhost.Result.Time != -1
		) {
			/* In TM_PlayMap_Local, using Ghost_RetrieveFromPlayer after SetRecord results in a -1 Result.Time.
			* Over there, I prefered transferring the .Result.Time from the old ghost. Just in case, I prefer doing it here as well. See TM_PlayMap_Local for more info.
			*/
			declare Integer LastRaceTime = MapState.PrevGhost.Result.Time;
			declare CGhost Ghost = Ghost_RetrieveFromPlayer(Player);
			if (
				Ghost != Null &&
				Ghost.Result.Checkpoints.count > 0 &&
				Ghost.Result.Checkpoints[Ghost.Result.Checkpoints.count - 1] == LastRaceTime
			) {
				Ghost.Result.Time = LastRaceTime;
				DataFileMgr.Ghost_Release(MapState.PrevGhost.Id);
				MapState.PrevGhost <=> Ghost;
			} else if (Ghost != Null) {
				DataFileMgr.Ghost_Release(Ghost.Id);
			}
		}
	}

	return MapState;
}

Void ReportValidationResult(CGhost Ghost) {
	declare result = K_ValidationResult {
		GhostId = "" ^ Ghost.Id
	};
	AddDebugLog("Reporting: " ^ result);
	declare Req = Http::Update(Http::CreatePost("http://localhost:29806/report_validation", result.tojson(), ["Asdf" => "Blah"]));
	AddDebugLog("Got request: " ^ Req);
	A_PendingHttpTasks.add(Req);
	if (Req.IsWaitingSlot) {
		AddDebugLog("http request delayed due to saturated...");
	}
}

// Save new time if better
K_MapState SaveNewTimeIfBetter(K_MapState _MapState, Integer _NewTime, Integer _AuthorTime) {
	declare K_MapState MapState = _MapState;

	if (
		_NewTime >= 0 && (
			_NewTime <= _AuthorTime ||
			_AuthorTime == -1
		)
	) {
		if (Players.count > 0 && Players[0] != Null && Players[0].User != Null) {
				if (MapState.NewAuthorGhost != Null) {
					// Release old author ghost
					if (MapState.AuthorGhostAddId != NullId) GhostMgr.Ghost_Remove(MapState.AuthorGhostAddId);
					MapState.AuthorGhostAddId = NullId;
					if (MapState.AuthorGhostId != NullId && DataFileMgr.Ghosts.existskey(MapState.AuthorGhostId)) DataFileMgr.Ghost_Release(MapState.AuthorGhostId);
					// Store new author ghost id & time
					MapState.AuthorGhostId = MapState.NewAuthorGhost.Id;
					DataFileMgr.Replay_Author_Save(Map, MapState.NewAuthorGhost);
					MapGet::ShareAuthorGhostId(MapState.AuthorGhostId);
					MapGet::ShareAuthorTime(MapState.NewAuthorGhost.Result.Time);
					MapGet::ShareAuthorRaceWaypointTimes(MapState.CheckpointTimes);
					MapState.AuthorGhostAddId = GhostMgr.Ghost_Add(MapState.NewAuthorGhost, True);
					Ghost_CopyToScoreBestRaceAndLap(MapState.NewAuthorGhost, Players[0].Score);
					// Report to archivist
					ReportValidationResult(MapState.NewAuthorGhost);
				}
		}
	}

	return MapState;
}

Task::K_Task SaveReplay(Task::K_Task _TaskSaveReplay, K_MapState _MapState) {
	declare Task::K_Task TaskSaveReplay = _TaskSaveReplay;

	if (
		!Task::IsInitialized(TaskSaveReplay) &&
		_MapState.PrevGhost != Null &&
		DataFileMgr.Ghosts.existskey(_MapState.PrevGhost.Id) &&
		Players.count > 0 &&
		Players[0] != Null &&
		Players[0].User != Null
	) {
		declare CGhost LastGhost = DataFileMgr.Ghosts[_MapState.PrevGhost.Id];
		if (LastGhost != Null) {
			declare Text OldName = LastGhost.Nickname;
			// Rename the ghost before saving it
			LastGhost.Nickname = Players[0].User.Name;

			declare Text Time = TiL::FormatDate(TiL::GetCurrent(), TiL::EDateFormats::Time);
			declare Text Date = TiL::FormatDate(TiL::GetCurrent(), TiL::EDateFormats::DateShort);
			declare Text FullDate = Date^"_"^Time;
			FullDate = TL::RegexReplace("\\W", FullDate, "g", "-");
			declare Text RaceTime = TL::TimeToText(LastGhost.Result.Time, True, True);
			RaceTime = TL::Replace(RaceTime, ":", "'");
			RaceTime = TL::Replace(RaceTime, ".", "''");
			declare Text ReplayFileName = Map.MapInfo.Name^"_"^Players[0].User.Name^"_"^FullDate^"("^RaceTime^")";
			ReplayFileName = TL::Replace(ReplayFileName, ".", "");
			TaskSaveReplay = Task::DestroyAndCreate(TaskSaveReplay, DataFileMgr, DataFileMgr.Replay_Save("My Replays/"^ReplayFileName^".Replay.Gbx", Map, LastGhost));
			LastGhost.Nickname = OldName;
		}
	}

	if (Task::IsInitialized(TaskSaveReplay)) {
		TaskSaveReplay = Task::Update(TaskSaveReplay);
		if (!Task::IsRunning(TaskSaveReplay) && Task::IsSuccess(TaskSaveReplay)) {
			declare netwrite Boolean Net_RaceValidation_ReplaySaved for Teams[0] = False;
			Net_RaceValidation_ReplaySaved = True;
		}
		TaskSaveReplay = Task::Destroy(TaskSaveReplay);
	}

	return TaskSaveReplay;
}

Void TogglePodium() {
	declare netwrite Boolean Net_RaceValidation_PodiumSequenceActive for Teams[0] = False;
	if (UIManager.UIAll.UISequence == C_UISequence_Replay) {
		UIManager.UIAll.UISequence = C_UISequence_Podium;
		Net_RaceValidation_PodiumSequenceActive = True;
		UIManager.UIAll.UISequence_PodiumPlayersWin = LocalPlayerLogin ^ ",2,3";
		UIManager.UIAll.UISequence_PodiumPlayersLose = "4,5,6";
	} else if (UIManager.UIAll.UISequence == C_UISequence_Podium) {
		UIManager.UIAll.UISequence = C_UISequence_Replay;
		Net_RaceValidation_PodiumSequenceActive = False;
	} else {
		Net_RaceValidation_PodiumSequenceActive = False;
	}
}

Void ViewRacePodium() {
	declare netwrite Boolean Net_RaceValidation_RacePodiumIsVisible for Teams[0] = False;
	Net_RaceValidation_RacePodiumIsVisible = True;
	Utils::PushAndApplyUISequence(UIManager.UIAll, CUIConfig::EUISequence::Podium);

	UIManager.UIAll.UISequence_PodiumPlayersWin = LocalPlayerLogin ^ ",2,3";
	UIManager.UIAll.UISequence_PodiumPlayersLose = "4,5,6";

	declare Boolean PodiumIsActive = True;
	while (PodiumIsActive) {
		MB_Yield();

		foreach (Event in UIManager.PendingEvents) {
			if (Event.Type == CUIConfigEvent::EType::OnLayerCustomEvent) {
				if (Event.CustomEventType == ValidationEvents::C_EventType_ExitPodium) {
					PodiumIsActive = False;
				}
			}
		}
	}

	Utils::PopAndApplyUISequence(UIManager.UIAll);
	Net_RaceValidation_RacePodiumIsVisible = False;
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