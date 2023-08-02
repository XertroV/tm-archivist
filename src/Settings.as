[Setting hidden]
bool S_AboutTabOpen_1 = true;

[Setting category="Editor" name="Use Archivist Validation" description="Use Archivist's validation mode instead of the normal validation mode. Full, partial, and segmented ghosts will be saved for every run."]
bool S_UseArchivistValidation = true;

[Setting category="UI" name="Show Notifications" description="Show a notification when a ghost is saved."]
bool S_ShowSaveNotifications = true;

[Setting name="Log Level" category="General"]
LogLevel S_LogLevel = LogLevel::Info;

[Setting hidden]
uint S_NbPbGhosts = 3;

[Setting hidden]
uint S_NbRecentGhosts = 5;

[Setting hidden]
bool S_KeepAllGhostsLoaded = false;

[Setting hidden]
bool S_RefreshRecordsRegularly = true;

[Setting hidden]
int S_SaveAfterRaceTime = 4;

[Setting hidden]
bool S_NoSaveIfNoMove = true;

[Setting hidden]
string S_ReplayNameTemplate = "{date_time} {duration}ms {username}";

[Setting hidden]
string S_ReplayFolderTemplate = "{map_name}";

string RenderTemplateExample(const string &in template) {
    return template.Replace("{date_time}", FmtTimestamp())
        .Replace("{date}", FmtTimestampDateOnly())
        .Replace("{duration}", tostring(Time::Now % 30000 + 20000))
        .Replace("{username}", LocalUserName)
        .Replace("{map_name}", "Winter 2023 - 17")
        .Replace("{timestamp}", tostring(Time::Stamp))
        ;
}

void SetTmlpPreset(const string &in folder, const string &in file) {
    S_ReplayFolderTemplate = folder;
    S_ReplayNameTemplate = file;
}

bool FileNameTemplatesOkay() {
    string combo = S_ReplayFolderTemplate + "/" + S_ReplayNameTemplate;
    return combo.Contains("{map_name}")
        && (combo.Contains("{date_time}") || combo.Contains("{date}") || combo.Contains("{timestamp}"))
        && combo.Contains("{duration}")
        ;
}

// deprecated
// [Setting hidden]
// bool S_UploadGhosts = true;

// only available with UploadGhosts enabled
[Setting hidden]
bool S_SaveGhosts = true;

[Setting hidden]
bool S_SaveReplays = true;

[Setting hidden]
bool S_SeparatePartialRuns = true;

[Setting hidden]
bool S_SaveTruncatedRuns = false;




void DrawSaveGhostsAndOrReplaysCheckbox() {
    // UI::BeginDisabled(!S_UploadGhosts);
    S_SaveGhosts = UI::Checkbox("Save Ghosts", S_SaveGhosts);
    // UI::EndDisabled();
    // if (!S_UploadGhosts) {
    //     UI::SameLine();
    //     UI::Text("\\$aaa Upload Ghosts required for use.");
    // }
    S_SaveReplays = UI::Checkbox("Save Replays", S_SaveReplays);
    AddSimpleTooltip("Note: will generate a noticeable pause when resetting or finishing a map. Ghosts-only doesn't have this problem.");
}

// void DrawUploadGhostsCheckbox() {
//     bool orig = S_UploadGhosts;
//     S_UploadGhosts = UI::Checkbox("Upload Ghosts", S_UploadGhosts);
//     AddSimpleTooltip("Required for: saving Ghosts and the '" + Icons::History + " My Runs' tab.");
//     UI::SameLine();
//     if (S_UploadGhosts) {
//         UI::Text("\\$aaa Run History will be\\$1d8 available\\$aaa for new runs");
//     } else {
//         UI::Text("\\$aaa Run History will be\\$d81 unavailable\\$aaa for new runs");
//     }
//     if (orig != S_UploadGhosts) {
//         // auto enable save ghosts when we tick this box
//         if (S_UploadGhosts) S_SaveGhosts = true;
//         OnSettingsChanged();
//     }
// }

void DrawSeparatePartialRunsCheckbox() {
    S_SeparatePartialRuns = UI::Checkbox("Separate Partial Runs?", S_SeparatePartialRuns);
    UI::SameLine();
    if (S_SeparatePartialRuns) {
        UI::Text("\\$aaa Runs will be separated into `Partial` and `Complete` subfolders.");
    } else {
        UI::Text("\\$aaa Runs will be saved into the main folder.");
    }
}

void DrawSegmentedRunsCheckbox() {
    S_SaveTruncatedRuns = UI::Checkbox("Save 'Segmented' Replays?", S_SaveTruncatedRuns);
    AddSimpleTooltip("These are replays with respawns cut out. The result is a run that appears to have no respawns. This is mostly useful for content creators demonstrating a 'clean' run on a hard track. They can also be played against, so you could create a nearly perfect ghost to play against. Note that these replays are flawed -- where respawns a cut out a noticeable artifact in the cars position occurs.");
    UI::SameLine();
    if (S_SaveTruncatedRuns) {
        UI::Text("\\$aaa Runs will be saved under the `Complete/Segmented` subfolder.");
    } else {
        UI::Text("\\$aaa Segmented runs will not be saved.");
    }
}




/*
 * HOTKEYS
 */


[Setting hidden]
bool S_SH_HotkeyEnabled = false;

[Setting hidden]
VirtualKey S_ShowHideHotkey = VirtualKey::F2;

[SettingsTab name="Hotkeys" icon="Th" order="1"]
void S_MainTab() {
    if (UI::BeginTable("bindings", 4, UI::TableFlags::SizingStretchSame)) {
        UI::TableSetupColumn("Key", UI::TableColumnFlags::WidthStretch, 1.1);
        UI::TableSetupColumn("Binding", UI::TableColumnFlags::WidthStretch, .3f);
        UI::TableSetupColumn("", UI::TableColumnFlags::WidthFixed, 70);
        UI::TableSetupColumn("", UI::TableColumnFlags::WidthFixed, 100);
        UI::TableHeadersRow();

        S_ShowHideHotkey = DrawKeyBinding("Show/Hide Toggle", S_ShowHideHotkey);
        S_SH_HotkeyEnabled = DrawKeyBindSwitch("show-hide", S_SH_HotkeyEnabled);
        // S_FrontView = DrawKeyBinding("Front View (Blender: Numpad 1)", S_FrontView);
        // S_SideView = DrawKeyBinding("Side View (Blender: Numpad 3)", S_SideView);
        // S_TopDownView = DrawKeyBinding("Top Down View (Blender: Numpad 7)", S_TopDownView);
        // S_FlipAxis = DrawKeyBinding("Rotate 180 around Y (Blender: Numpad 9)", S_FlipAxis);

        UI::EndTable();
    }
    UI::Separator();
    if (rebindInProgress) {
        UI::Text("Press a key to bind, or Esc to cancel.");
    }
}

string activeKeyName;
VirtualKey tmpKey;
bool gotNextKey = false;
bool rebindInProgress = false;
bool rebindAborted = false;
VirtualKey DrawKeyBinding(const string &in name, VirtualKey &in valIn) {
    bool amActive = rebindInProgress && activeKeyName == name;
    bool amDone = (rebindAborted || gotNextKey) && !rebindInProgress && activeKeyName == name;
    UI::PushID(name);

    UI::TableNextRow();
    UI::TableNextColumn();
    UI::AlignTextToFramePadding();
    UI::Text(name);

    UI::TableNextColumn();
    UI::Text(tostring(valIn));

    UI::TableNextColumn();
    UI::BeginDisabled(rebindInProgress);
    if (UI::Button("Rebind")) StartRebind(name);
    UI::EndDisabled();

    UI::PopID();
    // if (amActive) {
        // UI::SameLine();
        // UI::Text("Press a key to bind, or Esc to cancel.");
    // }
    if (amDone) {
        if (gotNextKey) {
            ResetBindingState();
            return tmpKey;
        } else {
            UI::SameLine();
            UI::Text("\\$888Rebind aborted.");
        }
    }
    return valIn;
}

bool DrawKeyBindSwitch(const string &in id, bool val) {
    UI::TableNextColumn();
    return UI::Checkbox("Enabled##" + id, val);
}

void ResetBindingState() {
    rebindInProgress = false;
    activeKeyName = "";
    gotNextKey = false;
    rebindAborted = false;
}

void StartRebind(const string &in name) {
    if (rebindInProgress) return;
    rebindInProgress = true;
    activeKeyName = name;
    gotNextKey = false;
    rebindAborted = false;
}

void ReportRebindKey(VirtualKey key) {
    if (!rebindInProgress) return;
    if (key == VirtualKey::Escape) {
        rebindInProgress = false;
        rebindAborted = true;
    } else {
        rebindInProgress = false;
        gotNextKey = true;
        tmpKey = key;
    }
}
