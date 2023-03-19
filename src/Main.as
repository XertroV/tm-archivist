bool UserHasPermissions = false;

UI::Font@ g_BigFont = UI::LoadFont("DroidSans.ttf", 26);
UI::Font@ g_MidFont = UI::LoadFont("DroidSans.ttf", 20);
UI::Font@ g_StdBoldFont = UI::LoadFont("DroidSans-bold.ttf", 16);
UI::Font@ g_StdFont = UI::LoadFont("DroidSans.ttf", 16);

void Main() {
    startnew(ClearTaskCoro);
    UserHasPermissions = Permissions::PlayLocalMap()
        && Permissions::CreateLocalReplay();
    if (!UserHasPermissions) {
        NotifyWarning("You don't appear to have the necessary permissions: PlayLocalMap and CreateLocalReplay");
        return;
    }
    LocalStats::Load();
    startnew(AuthLoop);
    startnew(WatchForMapChange);
    UpdateArchivistGameModeScript();
    UpdateModeSettingsViaMLHook();
    CheckCurrentGameModeForArchivist();
}

void OnDisabled() { _Unload(); }
void OnDestroyed() { _Unload(); }
void _Unload() {
    LocalStats::Save();
    if (server !is null) server.Shutdown();
}

const string ArchivistModeScriptName = "TM_Archivist_" + Time::Now + "_Local";

void UpdateArchivistGameModeScript() {
    string scriptsModeTmFolder = IO::FromUserGameFolder("Scripts/Modes/Trackmania");
    if (!IO::FolderExists(scriptsModeTmFolder)) {
        IO::CreateFolder(scriptsModeTmFolder, true);
    }
    auto scriptFiles = IO::IndexFolder(scriptsModeTmFolder, false);
    string[]@ parts;
    for (uint i = 0; i < scriptFiles.Length; i++) {
        if (scriptFiles[i].EndsWith("_Local.Script.txt")) {
            @parts = scriptFiles[i].Split("/");
            if (parts.Length > 0 && parts[parts.Length - 1].StartsWith("TM_Archivist_")) {
                trace('Removing old archivist script file: ' + scriptFiles[i]);
                IO::Delete(scriptFiles[i]);
            }
        }
    }

    string debugShim = IO::FromUserGameFolder("Scripts/Modes/Trackmania/TM_Archivist_Base.Script.txt");
    if (!IO::FileExists(debugShim)) {
        IO::File debugFile(debugShim, IO::FileMode::Write);
        debugFile.Write('#Extends "Libs/Nadeo/TMNext/TrackMania/Modes/TMNextBase.Script.txt"\n#Const C_IsDebug True\n');
        debugFile.Close();
    }

    IO::File gmFile(IO::FromUserGameFolder("Scripts/Modes/Trackmania/" + ArchivistModeScriptName + ".Script.txt"), IO::FileMode::Write);
    gmFile.Write(TM_ARCHIVIST_LOCAL_SCRIPT_TXT);
    gmFile.Close();
    trace('Updated Archivist game mode script');
}

string g_MapUid;
void WatchForMapChange() {
    auto app = GetApp();
    while (true) {
        yield();
        if (app.RootMap is null) {
            if (g_MapUid != "") {
                g_MapUid = "";
                startnew(OnMapLeft);
            }
        } else if (app.RootMap.EdChallengeId != g_MapUid) {
            g_MapUid = app.RootMap.EdChallengeId;
            startnew(OnMapChanged);
        }
    }
}

void OnMapLeft() {
    // nothing to do
}

void OnMapChanged() {
    auto net = cast<CTrackManiaNetwork>(GetApp().Network);
    auto si = cast<CTrackManiaNetworkServerInfo>(net.ServerInfo);
    if (si.CurGameModeStr == "") {
        log_debug("empty game mode string");
    } else {
        log_debug("curr game mode: " + si.CurGameModeStr);
        if (si.CurGameModeStr.StartsWith("TM_Archivist_")) {
            log_trace("detected map in archivist game mode");
            startnew(LocalStats::RegisterCurrentMapAsRecent);
        }
    }
}

bool checkedGameModeAtStartup = false;
void CheckCurrentGameModeForArchivist() {
    if (checkedGameModeAtStartup) return;
    checkedGameModeAtStartup = true;
    try {
        auto si = cast<CTrackManiaNetworkServerInfo>(GetApp().Network.ServerInfo);
        if (si.CurGameModeStr.StartsWith("TM_Archivist_")) {
            // if we load the plugin while in an archivist map (i.e., plugin reload) then start the http server.
            StartHttpServer();
        }
    } catch {}
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

#if DEV && SIG_DEVELOPER
/** Render function called every frame intended only for menu items in the main menu of the `UI`.
*/
void RenderMenuMain() {
    if (UI::BeginMenu("Archivist Debug")) {
        if (UI::MenuItem("Explore PgScript")) ExploreNod(GetApp().PlaygroundScript);
        if (UI::MenuItem("Explore PgScript.DataFileMgr")) ExploreNod(GetApp().PlaygroundScript.DataFileMgr);
        if (UI::MenuItem("Explore N.CMAPG.DataFileMgr")) ExploreNod(GetApp().Network.ClientManiaAppPlayground.DataFileMgr);
        if (UI::MenuItem("Auth Token Len: " + g_opAuthToken.Length)) {
            log_trace("Auth token: " + g_opAuthToken);
        }
        UI::EndMenu();
    }
}
#endif

string m_URL;
string m_UID;
string m_TMX;
bool m_UseTmxMirror = false;

/** Render function called every frame.
*/
void Render() {
    if (!ShowWindow || !UI::IsOverlayShown() || GetApp().Editor !is null) return;
    _AuthLoopStartEarly = true;
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
                auto uids = LocalStats::GetRecentMaps();
                for (int i = 0; i < Math::Min(10, uids.Length); i++) {
                    DrawMapMenuItem(uids[i]);
                }
                UI::EndMenu();
            }
            UI::EndMenu();
        }

        if (UI::BeginMenu("Help")) {
            if (UI::MenuItem("Show About Tab", "", S_AboutTabOpen_1)) S_AboutTabOpen_1 = !S_AboutTabOpen_1;
            UI::EndMenu();
        }
        UI::EndMenuBar();
    }
    UI::PopID();
}

void DrawMapMenuItem(const string &in uid) {
    if (uid.Length < 23) {
        UI::Text("\\$aa2Bad map UID: " + uid);
        return;
    }
    auto mi = LocalStats::GetMapInfoData(uid);
    UI::PushID(uid);
    if (UI::MenuItem(string(mi['name']) + "\\$888  by " + string(mi['author']))) {
        startnew(LoadMapViaLoadMethod, mi['load_method']);
    }
    UI::PopID();
}

void LoadMapViaLoadMethod(ref@ _lm) {
    Json::Value@ lm = cast<Json::Value>(_lm);
    if (lm is null) {
        log_warn('null load method');
        return;
    }
    if (lm.GetType() != Json::Type::Object
        || !lm.HasKey('method') || !lm.HasKey('payload')
    ) {
        log_warn('bad load method: ' + Json::Write(lm));
        return;
    }
    string method = lm['method'];
    string pl = lm['payload'];

    LocalStats::SetNextMapLoadMethod(null);
    ReturnToMenu(true);
    if (method == 'uid') {
        // todo: handle not found case
        auto _mi = GetMapFromUid(pl);
        if (_mi is null) {
            return;
        }
        pl = _mi.FileUrl;
    } else if (method == 'url') {
        // nothing more to prep for url method
    }
    LoadMapNowInArchivist(pl);
    yield();
    InitializeGameMode();
}



// const string ArchivistMode = "TrackMania/TM_Archivist_Local";

bool InArchivistGameMode {
    get {
        try {
            auto si = cast<CTrackManiaNetworkServerInfo>(GetApp().Network.ServerInfo);
            return si.ModeName == ArchivistModeScriptName;
        } catch {}
        return false;
    }
}


Tab@[] mainTabs = {
    AboutTab(), HomeTab(), _LoadMaps
};

void DrawMain() {
    UI::BeginTabBar("main tabs");

    for (uint i = 0; i < mainTabs.Length; i++) {
        mainTabs[i].DrawTab();
    }

    // UI::PushStyleColor(UI::Col::TabActive)
    // if (S_AboutTabOpen_1 && UI::BeginTabItem(Icons::QuestionCircle + " About", S_AboutTabOpen_1)) {
    //     UI::EndTabItem();
    // }

    // if (UI::BeginTabItem(Icons::FolderOpen + " Load Map")) {
    //     UI::EndTabItem();
    // }

    // if (UI::BeginTabItem(Icons::History + " My Runs")) {
    //     UI::EndTabItem();
    // }

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


const string GetHumanTimePeriod(int nSecs) {
    auto absNSecs = Math::Abs(nSecs);
    string units;
    float divBy;
    if (absNSecs < 60) {units = " s"; divBy = 1;}
    else if (absNSecs < 3600) {units = " min"; divBy = 60;}
    else if (absNSecs < 86400*2) {units = " hrs"; divBy = 3600;}
    else {units = " days"; divBy = 86400;}
    return Text::Format(absNSecs >= 86400*2 ? "%.1f" : "%.0f", float(nSecs) / divBy) + units;
}

const string GetHumanTimeSince(uint stamp) {
    auto nSecs = Time::Stamp - stamp;
    return GetHumanTimePeriod(nSecs);
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
