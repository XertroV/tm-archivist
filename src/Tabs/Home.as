class HomeTab : Tab {
    HomeTab() {
        super(Icons::Home + " Home", false);
    }

    void DrawInner() override {
        DrawLocalStatsBar();
        Heading("Mode Settings", .1);
        UI::Separator();
        UI::Text("\\$d84Note: You must re-load a map for settings to take effect.");
        SubHeading("In-game Ghosts");
        UI::BeginDisabled(S_KeepAllGhostsLoaded);
        S_NbPbGhosts = Math::Max(0, UI::SliderInt("# PB Ghosts", S_NbPbGhosts, 0, 10));
        AddSimpleTooltip("The number of PB ghosts to keep loaded.");
        S_NbRecentGhosts = Math::Max(0, UI::SliderInt("# Recent Ghosts", S_NbRecentGhosts, 0, 20));
        AddSimpleTooltip("The number of most recent ghosts to keep loaded. Includes partial ghosts.");
        UI::EndDisabled();

        S_SaveAfterRaceTime = Math::Max(0, UI::InputInt("Save ghosts only after X seconds", S_SaveAfterRaceTime, 1));
        AddSimpleTooltip("If you reset before X seconds have passed, a partial replay will not be saved.");
        S_KeepAllGhostsLoaded = UI::Checkbox("Keep *All* Ghosts Loaded (including Partial completions)", S_KeepAllGhostsLoaded);
        S_RefreshRecordsRegularly = UI::Checkbox("Refresh Records Regularly (when you finish/restart, no more than once per 30s)", S_RefreshRecordsRegularly);
        AddSimpleTooltip("Note: any leaderboards ghosts you load will be unloaded when the LB refreshes.");

        // SubHeading("Online");
        // DrawUploadGhostsCheckbox();

        SubHeading("Files");
        UI::AlignTextToFramePadding();
        UI::Text("Save Location:\\$ccc Trackmania/Replays/Archivist/");
        DrawSaveGhostsAndOrReplaysCheckbox();
        DrawSeparatePartialRunsCheckbox();
        DrawSegmentedRunsCheckbox();

        SubHeading("Name Templates");
        if (UI::CollapsingHeader("Available Variables")) {
            HIndent();
            if (UI::BeginTable("template var table", 3, UI::TableFlags::SizingStretchProp)) {
                UI::TableSetupColumn("var", UI::TableColumnFlags::WidthFixed);
                UI::TableSetupColumn("btn", UI::TableColumnFlags::WidthFixed);
                DrawTemplateVar("{date}", "The date & time in the format YYYY-MM-DD HH-MM-SS");
                DrawTemplateVar("{date_time}", "The date in the format YYYY-MM-DD");
                DrawTemplateVar("{timestamp}", "The timestamp in Unix format");
                DrawTemplateVar("{duration}", "The run duration in miliseconds");
                DrawTemplateVar("{username}", "Your in-game Name");
                DrawTemplateVar("{map_name}", "The Map's Name");
                UI::EndTable();
            }
        }
        if (UI::CollapsingHeader("Presets")) {
            HIndent();
            if (UI::Button("Folder: Map Name, File: DateTime-Duration-Username")) SetTmlpPreset("{map_name}", "{date_time}-{duration}ms-{username}");
            HIndent();
            if (UI::Button("Folder: Date, File: Map-Duration-Timestamp-Username")) SetTmlpPreset("{date}", "{map_name}-{duration}ms-{timestamp}-{username}");
            HIndent();
            if (UI::Button("Folder: Date/Map Name, File: Duration-Timestamp-Username")) SetTmlpPreset("{date}/{map_name}", "{duration}ms-{timestamp}-{username}");
        }
        S_ReplayFolderTemplate = UI::InputText("\\$fa4Folder Name Template", S_ReplayFolderTemplate);
        string replayFolderName = RenderTemplateExample(S_ReplayFolderTemplate);
        // includes trailing slash
        string subFolderName = S_SeparatePartialRuns ? "Partial/" : "";
        UI::AlignTextToFramePadding();

        S_ReplayNameTemplate = UI::InputText("\\$4afFile Name Template", S_ReplayNameTemplate);
        UI::AlignTextToFramePadding();
        UI::Text("Example: Archivist/\\$fa4" + replayFolderName + "\\$z/" + subFolderName + "\\$4af" + RenderTemplateExample(S_ReplayNameTemplate) + "\\$z.Replay.gbx");

        if (!FileNameTemplatesOkay()) {
            UI::TextWrapped("\\$d81 Warning:\\$aaa missing 1+ suggested template vars: {map_name}, {duration}, and one of {date}, {date_time}, {timestamp}.");
        }
    }
}


void DrawTemplateVar(const string &in var, const string &in desc) {
    UI::PushID(var);

    UI::TableNextRow();
    UI::TableNextColumn();
    UI::AlignTextToFramePadding();
    UI::Text(var);

    UI::TableNextColumn();
    if (UI::Button(Icons::Clone)) IO::SetClipboard(var);

    UI::TableNextColumn();
    UI::Text(desc);

    UI::PopID();
}

void DrawLocalStatsBar() {
    if (UI::BeginTable("local stats bar", 6, UI::TableFlags::SizingStretchProp)) {
        UI::TableNextColumn();
        UI::AlignTextToFramePadding();
        SubSubHeading("STATS", 0);
        UI::TableNextColumn();
        UI::Text("Runs (Total / Partial / Full): " + LocalStats::GetTotalRuns() + " / " + LocalStats::GetPartialRuns() + " / " + LocalStats::GetCompleteRuns());
        UI::TableNextColumn();
        UI::Text("Respanws / CPs: " + LocalStats::GetNbRespawns() + " / " + LocalStats::GetNbCheckpoints());
        UI::TableNextColumn();
        UI::Text("Time Spent (HH:MM:SS): " + Time::Format(uint64(LocalStats::GetTotalTimeSpent()) * 1000, false, true, true));
        UI::TableNextColumn();
        UI::Text("# Maps: " + LocalStats::GetNbMaps());

        UI::EndTable();
    }
}
