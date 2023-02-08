bool UserHasPermissions = false;

UI::Font@ g_BigFont = UI::LoadFont("DroidSans.ttf", 26);
UI::Font@ g_MidFont = UI::LoadFont("DroidSans.ttf", 20);
UI::Font@ g_StdBoldFont = UI::LoadFont("DroidSans-bold.ttf", 16);
UI::Font@ g_StdFont = UI::LoadFont("DroidSans.ttf", 16);

void Main() {
    startnew(ClearTaskCoro);
    UserHasPermissions = Permissions::PlayLocalMap()
        && Permissions::CreateLocalReplay();
    LocalStats::Load();
    if (!UserHasPermissions) {
        NotifyWarning("You don't appear to have the necessary permissions: PlayLocalMap and CreateLocalReplay");
        return;
    }
    startnew(MainCoro);
    UpdateArchivistGameModeScript();
    UpdateModeSettingsViaMLHook();
}

void OnDisabled() { _Unload(); }
void OnDestroyed() { _Unload(); }
void _Unload() {
    LocalStats::Save();
}

void UpdateArchivistGameModeScript() {
    if (!IO::FolderExists(IO::FromUserGameFolder("Scripts/Modes/Trackmania"))) {
        IO::CreateFolder(IO::FromUserGameFolder("Scripts/Modes/Trackmania"), true);
    }
    IO::File gmFile(IO::FromUserGameFolder("Scripts/Modes/Trackmania/TM_Archivist_Local.Script.txt"), IO::FileMode::Write);
    gmFile.Write(TM_ARCHIVIST_LOCAL_SCRIPT_TXT);
    gmFile.Close();
    trace('Updated Archivist game mode script');
}

void MainCoro() {
    while (true) {
        yield();
    }
}

void Notify(const string &in msg) {
    UI::ShowNotification(Meta::ExecutingPlugin().Name, msg);
    trace("Notified: " + msg);
}

void NotifyError(const string &in msg) {
    warn(msg);
    UI::ShowNotification(Meta::ExecutingPlugin().Name + ": Error", msg, vec4(.9, .3, .1, .3), 15000);
}

void NotifyWarning(const string &in msg) {
    warn(msg);
    UI::ShowNotification(Meta::ExecutingPlugin().Name + ": Warning", msg, vec4(.9, .6, .2, .3), 15000);
}

const string PluginIcon = Icons::Archive;
const string MenuTitle = "\\$eda" + PluginIcon + "\\$z " + Meta::ExecutingPlugin().Name;

// show the window immediately upon installation
[Setting hidden]
bool ShowWindow = true;

/** Render function called every frame intended only for menu items in `UI`. */
void RenderMenu() {
    if (UI::MenuItem(MenuTitle, "", ShowWindow)) {
        ShowWindow = !ShowWindow;
    }
}

string m_URL;
string m_TMX;
bool m_UseTmxMirror = false;

/** Render function called every frame.
*/
void Render() {
    if (!ShowWindow || CurrentlyInMap || GetApp().Editor !is null) return;
    vec2 size = vec2(900, 800);
    vec2 pos = (vec2(Draw::GetWidth(), Draw::GetHeight()) - size) / 2.;
    UI::SetNextWindowSize(int(size.x), int(size.y), UI::Cond::FirstUseEver);
    UI::SetNextWindowPos(int(pos.x), int(pos.y), UI::Cond::FirstUseEver);
    UI::PushStyleColor(UI::Col::FrameBg, vec4(.2, .2, .2, .5));
    auto flags = UI::WindowFlags::MenuBar | UI::WindowFlags::NoCollapse;
    if (UI::Begin(MenuTitle + "   \\$888By XertroV", ShowWindow, flags)) {
        if (UserHasPermissions) {
            DrawToolbar();
            DrawMain();
        } else {
            UI::TextWrapped("\\$fe1Sorry, you don't appear to have permissions to play local maps and/or create local replays.");
        }
    }
    UI::End();
    UI::PopStyleColor();
}


/** Called when a setting in the settings panel was changed.
*/
void OnSettingsChanged() {
    // todo: tell game mode of updated settings if active or prompt user to reload
}



void DrawToolbar() {
    UI::PushID("archivist menu");
    if (UI::BeginMenuBar()) {
        if (UI::BeginMenu("Load Map")) {
            if (UI::BeginMenu("Recent")) {
                // todo
                UI::EndMenu();
            }
            UI::EndMenu();
        }

        if (UI::BeginMenu("Help")) {
            if (UI::MenuItem("Show About Tab", "", S_AboutTabOpen)) S_AboutTabOpen = !S_AboutTabOpen;
            UI::EndMenu();
        }
        UI::EndMenuBar();
    }
    UI::PopID();
}




const string ArchivistMode = "TrackMania/TM_Archivist_Local";

Tab@[] mainTabs = {
    AboutTab(), HomeTab(), _LoadMaps
};

void DrawMain() {
    UI::BeginTabBar("main tabs");

    for (uint i = 0; i < mainTabs.Length; i++) {
        mainTabs[i].DrawTab();
    }

    // UI::PushStyleColor(UI::Col::TabActive)
    // if (S_AboutTabOpen && UI::BeginTabItem(Icons::QuestionCircle + " About", S_AboutTabOpen)) {
    //     UI::EndTabItem();
    // }

    if (UI::BeginTabItem(Icons::FolderOpen + " Load Map(s)")) {
        UI::EndTabItem();
    }

    if (UI::BeginTabItem(Icons::History + " My Runs")) {
        UI::EndTabItem();
    }

    UI::EndTabBar();
}

string tmxIdToUrl(const string &in id) {
    if (m_UseTmxMirror) {
        return "https://cgf.s3.nl-1.wasabisys.com/" + id + ".Map.Gbx";
    }
    return "https://trackmania.exchange/maps/download/" + id;
}



void Heading(const string &in str, float vpad = 12.) {
    VSpace(vpad);
    UI::PushFont(g_BigFont);
    UI::Text(str);
    UI::PopFont();
}
void SubHeading(const string &in str, float vpad = 10.) {
    VSpace(vpad);
    UI::PushFont(g_MidFont);
    UI::Text(str);
    UI::PopFont();
}
void SubSubHeading(const string &in str, float vpad = 8.) {
    VSpace(vpad);
    UI::PushFont(g_StdBoldFont);
    UI::Text(str);
    UI::PopFont();
}

void AddSimpleTooltip(const string &in msg) {
    if (UI::IsItemHovered()) {
        UI::SetNextWindowSize(250, -1, UI::Cond::Always);
        UI::BeginTooltip();
        UI::TextWrapped(msg);
        UI::EndTooltip();
    }
}

void VSpace(float height = 10.) {
    if (height == 0) return;
    UI::Dummy(vec2(0, height));
}

void HIndent(float width = 10.) {
    UI::Dummy(vec2(width, 0));
    UI::SameLine();
}


const string FmtTimestamp(int64 timestamp = -1) {
    // return Time::FormatString("%c", timestamp);
    return Time::FormatString("%Y-%m-%d %H-%M-%S", timestamp);
}

const string FmtTimestampDateOnly(int64 timestamp = -1) {
    return Time::FormatString("%Y-%m-%d", timestamp);
}




string _localUserName;
const string LocalUserName {
    get {
        if (_localUserName.Length == 0) {
            _localUserName = cast<CGameManiaPlanet>(GetApp()).Network.PlaygroundClientScriptAPI.LocalUser.Name;
        }
        return _localUserName;
    }
}
