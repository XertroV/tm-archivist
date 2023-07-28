const string TM_ARCHIVISTVALIDATION_LOCAL_SCRIPT_TXT = """
/**
 *	Validation Race
 */
 #Extends "Libs/Nadeo/TMNext/TrackMania/Modes/TMNextBase.Script.txt"

 #Const	CompatibleMapTypes	"TrackMania\\TM_Race,TM_Race"
 #Const	Version							"2023-04-25"
 #Const	ScriptName					"Modes/TrackMania/TM_RaceValidation_Local.Script.txt"

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ //
// Libraries
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ //
 #Include "TextLib" as TL
 #Include "TimeLib" as TiL
 #Include "Libs/Nadeo/CommonLibs/Common/Task.Script.txt" as Task
 #Include "Libs/Nadeo/ModeLibs/Common/Utils.Script.txt" as Utils
 #Include "Libs/Nadeo/TMxSM/Race/MapGet.Script.txt" as MapGet
 #Include "Libs/Nadeo/TMxSM/RaceValidation/StateManager.Script.txt" as StateMgr
 #Include "Libs/Nadeo/TMxSM/Race/ValidationEvents.Script.txt" as ValidationEvents
 #Include "ManiaApps/Nadeo/TMxSM/Race/UIModules/TimeGap_Server.Script.txt" as UIModules_TimeGap
 #Include "Libs/Nadeo/TMNext/TrackMania/Modes/RaceValidation/Constants.Script.txt" as Consts
 #Include "ManiaApps/Nadeo/ModeLibs/Common/UIModules/Fade_Server.Script.txt" as UIModules_Fade
 #Include "Libs/Nadeo/TMNext/TrackMania/ColorPalette.Script.txt" as ColorPalette

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

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ //
// Constants
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ //
 #Const C_ManiaAppUrl "file://Media/ManiaApps/Nadeo/TMxSM/RaceValidation/RaceValidation.Script.txt" //< Url of the mania app

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
MB_Settings_UseDefaultHud = (Consts::C_HudModulePath == "");
Race_Settings_IsLocalMode = True;
Race_Settings_UseDefaultUIManagement = False;
***

***Match_LoadHud***
***
if (Consts::C_HudModulePath != "") Hud_Load(Consts::C_HudModulePath);
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
					declare CGhost PrevGhost <=> Ghost_RetrieveFromPlayer(Event.Player);
					declare CGhost NewAuthorGhost <=> Ghost_RetrieveFromPlayer(Event.Player);
					if (PrevGhost != Null) {
						if (Map_State.PrevGhost != Null) DataFileMgr.Ghost_Release(Map_State.PrevGhost.Id);
						Map_State.PrevGhost <=> PrevGhost;
					}
					if (NewAuthorGhost != Null) {
						if (Map_State.NewAuthorGhost != Null) DataFileMgr.Ghost_Release(Map_State.NewAuthorGhost.Id);
						Map_State.NewAuthorGhost <=> NewAuthorGhost;
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
	}
}
***

***Match_EndRound***
***
declare Boolean SkipEndRaceMenu = WaitPlayersRaceOutro();

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
		UIModules_Fade::SetFade(UIModules_Fade::C_Fade_In, GhostRestartTime - 250, 200, ColorPalette::C_Color_Black);
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
				UIModules_Fade::AddFade(UIModules_Fade::C_Fade_In, GhostRestartTime - 250, 200, ColorPalette::C_Color_Black);
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
		DataFileMgr.Ghost_Release(Map_State.NewAuthorGhost.Id);
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
""".Replace('_"_"_"_', '"""');