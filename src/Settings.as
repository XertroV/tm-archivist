[Setting hidden]
bool S_AboutTabOpen_1 = true;

[Setting]
LogLevel S_LogLevel = LogLevel::Warning;

[Setting hidden]
uint S_NbPbGhosts = 5;

[Setting hidden]
uint S_NbRecentGhosts = 5;

[Setting hidden]
bool S_KeepAllGhostsLoaded = false;

[Setting hidden]
int S_SaveAfterRaceTime = 5;

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
