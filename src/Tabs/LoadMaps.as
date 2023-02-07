class LoadMapsTab : Tab {
    LoadMapsTab() {
        super(Icons::FolderOpen + " Load Map(s)", false);
    }

    void DrawInner() override {
        Heading("Load Map(s)");

    }
}

Folder@ CurrentFolder = null;

void LoadCurrentFolder() {
    @CurrentFolder = Folder("Maps", Map_GetFilteredGameList(4, "", false, false, false));
}

class Folder {
    string[] SubFolders;
    CGameCtnChallengeInfo@[] MapInfos;
    Folder@ Parent = null;
    string Name;
    bool[] selected;
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
        @CurrentFolder = null;
        @CurrentFolder = Folder(sf, Map_GetFilteredGameList(4, sf, false, false, false), this);
    }

    void DrawMapInfo(int i) {
        UI::AlignTextToFramePadding();
        UI::SetCursorPos(UI::GetCursorPos() + vec2(framePadding.x, 0));
        DrawMapSelector(i);
    }

    // for use in folders
    void DrawMapSelector(int i) {
        bool _curr = selected[i];
        if (_curr != UI::Checkbox(MapNames[i], _curr)) {
            selected[i] = !_curr;
            nbSelected += _curr ? -1 : 1;
        }
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
            @CurrentFolder = Parent;
        } else {
        }
    }

    string[]@ OnClickAddSelectedMaps() {
        string[] ret;
        for (uint i = 0; i < MapInfos.Length; i++) {
            if (selected[i]) ret.InsertLast(MapInfos[i].MapUid);
        }
        return ret;
    }
}

funcdef void DrawTreeInnerF();
funcdef void DrawOpenTreeNodeInnerF();
