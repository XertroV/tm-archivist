const string GameMode_PageUID = "Archivist";


void UpdateModeSettingsViaMLHook() {
    // add all settings via MLHook
    auto data = Json::Object();
    // int
    data["S_NbPbGhosts"] = S_NbPbGhosts;
    data["S_SaveAfterRaceTimeMs"] = S_SaveAfterRaceTime * 1000;

    // bool
    data["S_KeepAllGhostsLoaded"] = S_KeepAllGhostsLoaded;
    data["S_UploadGhosts"] = S_UploadGhosts;
    data["S_SaveGhosts"] = S_SaveGhosts;
    data["S_SaveReplays"] = S_SaveReplays;
    data["S_SeparatePartialRuns"] = S_SeparatePartialRuns;

    // string
    data["S_ReplayNameTemplate"] = S_ReplayNameTemplate;
    data["S_ReplayFolderTemplate"] = S_ReplayFolderTemplate;

    MLHook::Queue_MessageManialinkPlaygroundServer(GameMode_PageUID, {'ArchivistSettings', Json::Write(data)});
}
