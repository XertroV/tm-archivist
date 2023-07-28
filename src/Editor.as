void SetupEditorIntercepts() {
    Dev::InterceptProc("CGameEditorPluginMap", "TestMapWithMode2", _ButtonValidateOnClick);
}

bool _ButtonValidateOnClick(CMwStack &in stack, CMwNod@ nod) {
    if (!S_UseArchivistValidation) return true;
    string xml = stack.CurrentString();
    auto rulesMode = stack.CurrentWString(1);
    // only block this script exactly
    if (!rulesMode.EndsWith("TM_RaceValidation_Local")) {
        return true;
    }
    print(rulesMode);
    print(xml);
    auto pmt = cast<CGameEditorPluginMap>(nod);
    if (pmt is null) {
        warn("Casting nod to PMT failed!");
        return true;
    } else {
        StartHttpServer();
        pmt.TestMapWithMode2("Trackmania/" + ArchivistValidationModeScriptName, xml);
    }
    return false;
}

void OnNewValidationGhost(const string &in id) {
    // ! this crashes the game if you try and save the replay or the map :(
    // try {
    //     uint IdValue = Text::ParseUInt(id.SubStr(1));
    //     auto ps = cast<CSmArenaRulesMode>(GetApp().PlaygroundScript);
    //     if (ps is null) return;
    //     for (uint i = 0; i < ps.DataFileMgr.Ghosts.Length; i++) {
    //         auto g = ps.DataFileMgr.Ghosts[i];
    //         if (g.Id.Value == IdValue) {
    //             // found our ghost
    //             print("Found ghost " + g.IdName);
    //             g.MwAddRef();
    //             auto ctnGhost = cast<CGameCtnGhost>(Dev::GetOffsetNod(g, 0x20));
    //             ctnGhost.MwAddRef();
    //             print("got ctn ghost, null: " + tostring(ctnGhost is null));
    //             print("ctn ghost: " + ctnGhost.GhostNickname);
    //             if (ctnGhost !is null) {
    //                 // @cast<CGameCtnEditorFree>(GetApp().Editor).Challenge.ChallengeParameters.RaceValidateGhost = ctnGhost;
    //                 // print("set race validate ghost");
    //             }
    //             break;
    //         }
    //     }
    // } catch {
    //     warn("Exception in OnNewValidationGhost: " + getExceptionInfo());
    // }
}
