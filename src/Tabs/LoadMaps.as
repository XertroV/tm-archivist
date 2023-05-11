// call this after a map is loaded to populate settings and send the token to the game mode script
void InitializeGameMode() {
    trace("Initializing game mode.");
    startnew(UpdateModeSettingsViaMLHook);
    startnew(UpdateApiTokenViaMLHook);
    // only need the http server if ghosts are enabled.
    if (S_SaveGhosts)
        StartHttpServer();
}

class LoadMapsTab : Tab {
    LoadMapsTab() {
        super(Icons::FolderOpen + " Load Map", false);
    }

    bool initialized = false;
    void InitializeSync() {
        if (initialized) return;
        initialized = true;
        startnew(CoroutineFunc(LoadCurrentFolder));
    }

    void DrawInner() override {
        if (!initialized) InitializeSync();
        // UI::AlignTextToFramePadding();
        Heading("Load Map", 0);

        UI::BeginTabBar("load maps method");
        if (LocalStats::GetRecentMaps().Length > 0) {
            if (UI::BeginTabItem("Recent Maps")) {
                DrawLoadRecentMaps();
                UI::EndTabItem();
            }
        }
        if (UI::BeginTabItem("Local Maps")) {
            DrawLocalMapsBrowser();
            UI::EndTabItem();
        }
        if (UI::BeginTabItem("From TMX / URL / UID")) {
            DrawTMXLoadMaps();
            UI::Separator();
            DrawURLLoadMap();
            UI::Separator();
            DrawUIDLoadMap();
            UI::EndTabItem();
        }
        if (UI::BeginTabItem("Campaign")) {
            DrawCampaignLoadMaps();
            UI::EndTabItem();
        }
        if (UI::BeginTabItem("Current Map")) {
            DrawLoadCurrentMap();
            UI::EndTabItem();
        }
        UI::EndTabBar();
    }

    void OnLoadLocalMap() {
        auto toLoad = CurrentFolder.OnClickAddSelectedMaps();
        LocalStats::SetNextMapLoadMethod(LocalStats::GenLoadMethodUrl(toLoad[0]));
        ReturnToMenu(true);
        // LoadMapNowInArchivist(tmxIdToUrl('90000'));
        LoadMapNowInArchivist(toLoad[0]);
        // cast<CGameManiaPlanet>(GetApp()).ManiaPlanetScriptAPI.Dialog_CleanCache();
        yield();
        InitializeGameMode();
    }

    void DrawLocalMapsBrowser() {
        if (CurrentFolder is null) {
            UI::Text("Loading Maps...");
        } else {
            if (UI::Button("Resync with game")) {
                @CurrentFolder = null;
                startnew(CoroutineFunc(LoadCurrentFolder));
                return;
            }
            AddSimpleTooltip("Refresh known maps based on the game's cached index.");
            UI::SameLine();
            if (UI::Button("Rescan disk for maps")) {
                startnew(CoroutineFunc(RescanForNewMaps));
            }
            AddSimpleTooltip("Note: will kick you back to the main menu and can cause a noticeable freeze if you have lots of maps.");
            CurrentFolder.DrawTree();
        }
    }

    void RescanForNewMaps() {
        ReturnToMenu(true);
        yield();
        cast<CTrackMania>(GetApp()).ScanDiskForChallenges();
    }

    void DrawTMXLoadMaps() {
        UI::AlignTextToFramePadding();
        UI::Text("Track ID:");
        UI::SameLine();
        bool pressedEnter = false;
        UI::SetNextItemWidth(100);
        m_TMX = UI::InputText("##tmx-id", m_TMX, pressedEnter, UI::InputTextFlags::EnterReturnsTrue);
        UI::SameLine();
        if (UI::Button("Play Map##tmx-btn") || pressedEnter) {
            m_URL = tmxIdToUrl(m_TMX);
            if (m_TMX.StartsWith("http")) {
                m_URL = m_TMX;
            }
            startnew(CoroutineFunc(OnLoadTmxMapNow));
        }
        UI::SameLine();
        m_UseTmxMirror = UI::Checkbox("Use Mirror?", m_UseTmxMirror);
        AddSimpleTooltip("Instead of downloading maps from TMX, download them from the CGF mirror.");
    }

    void DrawURLLoadMap() {
        UI::AlignTextToFramePadding();
        UI::Text("URL:");
        UI::SameLine();
        bool pressedEnter = false;
        UI::SetNextItemWidth(250);
        m_URL = UI::InputText("##url-id", m_URL, pressedEnter, UI::InputTextFlags::EnterReturnsTrue);
        UI::SameLine();
        if (UI::Button("Play Map##url-btn") || pressedEnter) {
            startnew(CoroutineFunc(OnLoadUrlMapNow));
        }
    }

    void DrawUIDLoadMap() {
        UI::BeginDisabled(currMapDeetsLoading);
        UI::AlignTextToFramePadding();
        UI::Text("UID:");
        UI::SameLine();
        bool pressedEnter = false;
        UI::SetNextItemWidth(250);
        m_UID = UI::InputText("##uid-input", m_UID, pressedEnter, UI::InputTextFlags::EnterReturnsTrue);
        UI::SameLine();
        if (UI::Button("Play Map##uid-btn") || pressedEnter) {
            loadCurrentUid = m_UID;
            startnew(CoroutineFunc(OnLoadUidMapNow));
        }
        UI::EndDisabled();
    }

    void OnLoadTmxMapNow() {
        LocalStats::SetNextMapLoadMethod(LocalStats::GenLoadMethodTmx(m_URL, m_TMX));
        ReturnToMenu(true);
        LoadMapNowInArchivist(m_URL);
        yield();
        InitializeGameMode();
    }

    void OnLoadUrlMapNow() {
        LocalStats::SetNextMapLoadMethod(LocalStats::GenLoadMethodUrl(m_URL));
        ReturnToMenu(true);
        LoadMapNowInArchivist(m_URL);
        yield();
        InitializeGameMode();
    }

    void OnLoadUidMapNow() {
        LocalStats::SetNextMapLoadMethod(LocalStats::GenLoadMethodUid(m_UID));
        loadCurrentUid = m_UID;
        ReturnToMenu(false);
        GetMapDetailsFromUid();
        LoadCurrentMap();
    }

    string campaignMapFilePath;
    string campaignMapUid;
    void DrawCampaignLoadMaps() {
        auto app = GetApp();
        if (app.OfficialCampaigns.Length < 1) {
            UI::Text("Campaign not found :(. Try loading via TMX.");
            return;
        }
        auto campaign = app.OfficialCampaigns[0];
        auto maps = campaign.MapGroups[0].MapInfos;
        auto rows = maps.Length / 5;
        UI::Columns(5);
        for (uint i = 0; i < rows; i++) {
            for (uint c = 0; c < 5; c++) {
                auto ix = c * 5 + i;
                if (ix >= maps.Length) continue;
                if (ix > 0) UI::NextColumn();
                auto item = maps[ix];
                UI::PushID(item);
                if (UI::Button("Play")) {
                    campaignMapFilePath = item.FileName;
                    campaignMapUid = item.MapUid;
                    startnew(CoroutineFunc(LoadCampaignMap));
                }
                UI::SameLine();
                UI::Text(item.Name);
                UI::PopID();
            }
        }
        UI::Columns(1);
    }

    void LoadCampaignMap() {
        LocalStats::SetNextMapLoadMethod(LocalStats::GenLoadMethodUid(campaignMapUid));
        ReturnToMenu(true);
        LoadMapNowInArchivist(campaignMapFilePath);
        yield();
        InitializeGameMode();
    }

    string loadCurrentFileName;
    bool currMapDeetsLoading = false;
    string loadCurrentUid;

    void DrawLoadCurrentMap() {
        auto app = GetApp();
        if (app.RootMap is null) {
            UI::Text("This only works if you're in a map.");
            return;
        }
        auto pgcsapi = app.Network.PlaygroundClientScriptAPI;
        if (pgcsapi is null) {
            UI::Text("Unexpected: app.Network.PlaygroundClientScriptAPI is null");
            return;
        }
        auto si = cast<CGameCtnNetServerInfo>(app.Network.ServerInfo);
        if (si is null) {
            UI::Text("Unexpected: app.Network.ServerInfo is null");
            return;
        }
        auto map = app.RootMap;
        auto mi = map.MapInfo;
        string mapFileName = "Archivist/" + StripFormatCodes(mi.Name) + '.Map.gbx';

        UI::Text(ColoredString(mi.Name));
        if (si.IsMapDownloadAllowed) {
            if (UI::Button("Load in Archivist##via-dl")) {
                if (pgcsapi.SaveMap(mapFileName)) {
                    lastSavedMapPath = mapFileName;
                    startnew(CoroutineFunc(LoadLastSavedMap));
                    log_info("Loading via saved map: " + ColoredString(mi.Name));
                } else {
                    NotifyWarning("map failed to save");
                }
            }
            UI::Text("\\$888 Will be saved to Maps/"+mapFileName);
        } else {
            if (loadCurrentUid != mi.MapUid) {
                loadCurrentUid = mi.MapUid;
                currMapDeetsLoading = true;
                loadCurrentFileName = "";
                startnew(CoroutineFunc(GetMapDetailsFromUid));
            }
            if (currMapDeetsLoading) {
                UI::Text("Loading map info...");
            } else {
                if (UI::Button("Load in Archivist##via-uid")) {
                    startnew(CoroutineFunc(LoadCurrentMap));
                }
                UI::Text("\\$888 Map Path: " + loadCurrentFileName);
            }
        }
    }

    string lastSavedMapPath;
    void LoadLastSavedMap() {
        LocalStats::SetNextMapLoadMethod(LocalStats::GenLoadMethodUrl(lastSavedMapPath));
        ReturnToMenu(true);
        LoadMapNowInArchivist(lastSavedMapPath);
        yield();
        InitializeGameMode();
    }

    void GetMapDetailsFromUid() {
        // todo: handle not found case
        currMapDeetsLoading = true;
        loadCurrentFileName = "";
        auto _mi = GetMapFromUid(loadCurrentUid);
        if (_mi !is null)
            loadCurrentFileName = _mi.FileUrl;
        currMapDeetsLoading = false;
    }

    void LoadCurrentMap() {
        LocalStats::SetNextMapLoadMethod(LocalStats::GenLoadMethodUid(loadCurrentUid));
        ReturnToMenu(true);
        LoadMapNowInArchivist(loadCurrentFileName);
        yield();
        InitializeGameMode();
    }

    Folder@ CurrentFolder = null;

    void LoadCurrentFolder() {
        @CurrentFolder = Folder("Maps", Map_GetFilteredGameList(4, "", false, false, false));
    }

    void DrawLoadRecentMaps() {
        int nbStyCol = 1;
        UI::PushStyleColor(UI::Col::TableRowBgAlt, vec4(vec3(.25), .4));
        auto recents = LocalStats::GetRecentMaps();
        int nCols = 11;
        if (UI::BeginTable("recent maps", nCols, UI::TableFlags::SizingStretchProp | UI::TableFlags::RowBg)) {
            UI::TableSetupColumn("");
            UI::TableSetupColumn("Name");
            UI::TableSetupColumn("Author");
            UI::TableSetupColumn("Last Played");
            UI::TableSetupColumn("# Loads");
            UI::TableSetupColumn("Runs");
            UI::TableSetupColumn("Fins");
            UI::TableSetupColumn("Resets");
            UI::TableSetupColumn("CPs");
            UI::TableSetupColumn("Respawns");
            UI::TableSetupColumn("Σ Time");
            UI::TableHeadersRow();

            UI::ListClipper clip(recents.Length);
            while (clip.Step()) {
                for (int i = clip.DisplayStart; i < clip.DisplayEnd; i++) {
                    if (i % 2 == 1) {
                    }
                    DrawLoadRecentMapItem(recents[i]);
                }
            }
            UI::EndTable();
        }
        UI::PopStyleColor(nbStyCol);
    }

    void DrawLoadRecentMapItem(const string &in uid) {
        UI::PushID(uid);
        UI::TableNextRow();
        UI::TableNextColumn();
        UI::AlignTextToFramePadding();
        if (uid.Length < 23) {
            UI::Text("\\$aa2Bad map UID: " + uid);
            return;
        }
        auto mi = LocalStats::GetMapInfoData(uid);

        if (UI::Button(Icons::Play)) {
            startnew(LoadMapViaLoadMethod, mi['load_method']);
        }
        AddSimpleTooltip("Play map now.");
        UI::SameLine();
        UI::Button(Icons::StarO);
        AddSimpleTooltip("Favorite this Map. \\$f8aNote: this isn't yet implemented. LMK if you want this feature. There would be a 'favorite maps' tab.");

        UI::TableNextColumn();
        UI::AlignTextToFramePadding();
        UI::Text(string(mi['name']));

        UI::TableNextColumn();
        UI::Text(string(mi['author']));

        // last played
        string last_played = mi.Get('last_played', "?");
        if (last_played.Length > 1) {
            last_played = GetHumanTimePeriod(Time::Stamp - Text::ParseInt64(last_played));
        }
        UI::TableNextColumn();
        UI::Text(last_played);

        UI::TableNextColumn();
        UI::Text(tostring(int(mi['nb_loaded'])));

        auto mapStats = LocalStats::GetMapStats(uid);

        // # Runs
        UI::TableNextColumn();
        UI::Text(tostring(int(mapStats.Get('runs', 0))));
        // # Fins
        UI::TableNextColumn();
        UI::Text(tostring(int(mapStats.Get('complete_runs', 0))));
        // # Resets
        UI::TableNextColumn();
        UI::Text(tostring(int(mapStats.Get('partial_runs', 0))));
        // # CPs
        UI::TableNextColumn();
        UI::Text(tostring(int(mapStats.Get('nbCheckpoints', 0))));
        // # Respawns
        UI::TableNextColumn();
        UI::Text(tostring(int(mapStats.Get('nbRespawns', 0))));
        // # Time Spent
        UI::TableNextColumn();
        UI::Text(Time::Format(Text::ParseInt64(string(mapStats.Get('time_spent', '0'))) * 1000, false, true, true));


        UI::PopID();
    }

}

LoadMapsTab@ _LoadMaps = LoadMapsTab();

class Folder {
    string[] SubFolders;
    CGameCtnChallengeInfo@[] MapInfos;
    Folder@ Parent = null;
    string Name;
    bool[] selected;
    int singleSelected = 0;
    string[] MapNames;
    int nbSelected = 0;

    Folder(const string &in name, CWebServicesTaskResult_MapListScript@ resp, Folder@ parent = null) {
        Name = name;
        @Parent = parent;
        for (uint i = 0; i < resp.SubFolders.Length; i++) {
            SubFolders.InsertLast(resp.SubFolders[i]);
        }
        for (uint i = 0; i < resp.MapInfos.Length; i++) {
            if (!resp.MapInfos[i].IsPlayable) continue;
            auto @mapInfo = resp.MapInfos[i];
            MapInfos.InsertLast(mapInfo);
            selected.InsertLast(true);
            MapNames.InsertLast(ColoredString(mapInfo.NameForUi));
        }
        nbSelected = selected.Length;
    }

    void DrawTree() {
        DrawOpenTreeNode(DrawTreeInnerF(DrawTreeInner));
    }

    void DrawTreeInner() {
        for (uint i = 0; i < SubFolders.Length; i++) {
            UI::SetNextItemOpen(false, UI::Cond::Always);
            UI::AlignTextToFramePadding();
            auto clicked = UI::TreeNode(SubFolders[i]);
            if (clicked) {
                UI::TreePop();
                startnew(CoroutineFuncUserdata(OnChooseSubfolder), array<string> = {SubFolders[i]});
            }
        }
        for (uint i = 0; i < MapInfos.Length; i++) {
            DrawMapInfo(i);
        }
    }

    void OnChooseSubfolder(ref@ r) {
        auto sf = cast<string[]>(r)[0];
        @_LoadMaps.CurrentFolder = null;
        @_LoadMaps.CurrentFolder = Folder(sf, Map_GetFilteredGameList(4, sf, false, false, false), this);
    }

    void DrawMapInfo(int i) {
        UI::AlignTextToFramePadding();
        UI::SetCursorPos(UI::GetCursorPos() + vec2(UI::GetStyleVarVec2(UI::StyleVar::FramePadding).x, 0));
        DrawMapSelector(i);
    }

    // for use in folders
    void DrawMapSelector(int i) {
        UI::PushID("play-" + i);
        if (UI::Button("Play")) {
            singleSelected = i;
            startnew(CoroutineFunc(_LoadMaps.OnLoadLocalMap));
        }
        UI::SameLine();
        UI::AlignTextToFramePadding();
        UI::Text(MapNames[i]);

        // bool _curr = selected[i];
        // if (_curr != UI::Checkbox(MapNames[i], _curr)) {
        //     selected[i] = !_curr;
        //     nbSelected += _curr ? -1 : 1;
        // }
        UI::PopID();
    }

    DrawTreeInnerF@ treeCb;
    void DrawOpenTreeNode(DrawTreeInnerF@ inner) {
        @treeCb = inner;
        if (Parent is null) DrawOpenTreeNodeInner();
        else Parent.DrawOpenTreeNode(DrawTreeInnerF(DrawOpenTreeNodeInner));
    }

    void DrawOpenTreeNodeInner() {
        bool cannotBeClosed = Parent is null;
        UI::AlignTextToFramePadding();
        if (cannotBeClosed || UI::TreeNode(Name, UI::TreeNodeFlags::DefaultOpen)) {
            treeCb();
            if (!cannotBeClosed) UI::TreePop();
        } else if (!cannotBeClosed) {
            // if we were closed, open the parent folder.
            @_LoadMaps.CurrentFolder = Parent;
        } else {
        }
    }

    string[]@ OnClickAddSelectedMaps() {
        return {MapInfos[singleSelected].FileName};
        // string[] ret;
        // for (uint i = 0; i < MapInfos.Length; i++) {
        //     if (selected[i]) {
        //         ret.InsertLast(MapInfos[i].FileName); // MapInfos[i].FileName != "" ? MapInfos[i].FileName);
        //         print(MapInfos[i].FileName);
        //     }
        // }
        // return ret;
    }
}

funcdef void DrawTreeInnerF();
funcdef void DrawOpenTreeNodeInnerF();



/*

		"<root>",
			"<setting name=\"S_CampaignId\" value=\""^State.CampaignId^"\" type=\"integer\"/>",
			"<setting name=\"S_CampaignType\" value=\""^Campaign.Type^"\" type=\"integer\"/>",
			"<setting name=\"S_CampaignIsLive\" value=\""^CampaignIsLive^"\" type=\"boolean\"/>",
			"<setting name=\"S_ClubCampaignTrophiesAreEnabled\" value=\""^ClubCampaignTrophiesAreEnabled^"\" type=\"boolean\"/>",
			"<setting name=\"S_DecoImageUrl_Checkpoint\" value=\""^DecalUrl^"\" type=\"text\"/>",
			"<setting name=\"S_DecoImageUrl_DecalSponsor4x1\" value=\""^Campaign.Club.DecoImageUrl_DecalSponsor4x1^"\" type=\"text\"/>",
			"<setting name=\"S_DecoImageUrl_Screen16x9\" value=\""^Campaign.Club.DecoImageUrl_Screen16x9^"\" type=\"text\"/>",
			"<setting name=\"S_DecoImageUrl_Screen8x1\" value=\""^Campaign.Club.DecoImageUrl_Screen8x1^"\" type=\"text\"/>",
			"<setting name=\"S_DecoImageUrl_Screen16x1\" value=\""^Campaign.Club.DecoImageUrl_Screen16x1^"\" type=\"text\"/>",
		"</root>"
*/
