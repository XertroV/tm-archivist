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
        if (UI::BeginTabItem("Local Maps")) {
            DrawLocalMapsBrowser();
            UI::EndTabItem();
        }
        if (UI::BeginTabItem("From TMX")) {
            DrawTMXLoadMaps();
            UI::EndTabItem();
        }
        if (UI::BeginTabItem("Campaign")) {
            DrawCampaignLoadMaps();
            UI::EndTabItem();
        }
        UI::EndTabBar();
    }

    void OnLoadMap() {
        ReturnToMenu(true);
        UpdateModeSettingsViaMLHook();
        // LoadMapNow(tmxIdToUrl('90000'), "Trackmania/" + ArchivistModeScriptName);
        LoadMapsNow(CurrentFolder.OnClickAddSelectedMaps(), "Trackmania/" + ArchivistModeScriptName);
        // cast<CGameManiaPlanet>(GetApp()).ManiaPlanetScriptAPI.Dialog_CleanCache();
    }


    void DrawLocalMapsBrowser() {
        if (CurrentFolder is null) {
            UI::Text("Loading Maps...");
        } else {
            CurrentFolder.DrawTree();
        }
    }

    void DrawTMXLoadMaps() {

    }

    void DrawCampaignLoadMaps() {

    }

    Folder@ CurrentFolder = null;

    void LoadCurrentFolder() {
        @CurrentFolder = Folder("Maps", Map_GetFilteredGameList(4, "", false, false, false));
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
            startnew(CoroutineFunc(_LoadMaps.OnLoadMap));
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
