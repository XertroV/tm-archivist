void SetupPlayMapIntercepts() {
    Dev::InterceptProc("CGameManiaTitleControlScriptAPI", "PlayMap", _PlayMapIntercept);
    Dev::InterceptProc("CGameManiaTitleControlScriptAPI", "PlayMapList", _PlayMapListIntercept);
}

bool _PlayMapIntercept(CMwStack &in stack, CMwNod@ nod) {
    if (!S_InterceptPlayMap && !S_InterceptCampaign) return true;
    string xml = stack.CurrentString();
    auto rulesMode = stack.CurrentWString(1);
    auto mapUri = stack.CurrentWString(2);
    // only block this script exactly
    bool isPlayMap = S_InterceptPlayMap && (rulesMode.Length == 0 || rulesMode.EndsWith("TM_PlayMap_Local"));
    bool isCampaign = S_InterceptCampaign && rulesMode.EndsWith("TM_Campaign_Local");
    if (!isPlayMap && !isCampaign) {
        return true;
    }
    trace('Intercepting PlayMap/Campaign: ' + mapUri + ', ' + rulesMode + ', ' + xml);
    auto title = cast<CGameManiaTitleControlScriptAPI>(nod);
    if (title is null) {
        warn("Casting nod to CGameManiaTitleControlScriptAPI failed!");
        return true;
    } else {
        StartHttpServer();
        title.PlayMap(mapUri, "Trackmania/" + ArchivistModeScriptName, xml);
    }
    return false;
}

bool _PlayMapListIntercept(CMwStack &in stack, CMwNod@ nod) {
    if (!S_InterceptPlayMap && !S_InterceptCampaign) return true;
    string xml = stack.CurrentString();
    auto rulesMode = stack.CurrentWString(1);
    auto mapUris = stack.CurrentBufferWString(2);
    // only block this script exactly
    bool isPlayMap = S_InterceptPlayMap && (rulesMode.Length == 0 || rulesMode.EndsWith("TM_PlayMap_Local"));
    bool isCampaign = S_InterceptCampaign && rulesMode.EndsWith("TM_Campaign_Local");
    if (!isPlayMap && !isCampaign) {
        return true;
    }
    trace('Intercepting PlayMapList: ' + mapUris.Length + ' maps, ' + rulesMode + ', ' + xml);
    auto title = cast<CGameManiaTitleControlScriptAPI>(nod);
    if (title is null) {
        warn("Casting nod to CGameManiaTitleControlScriptAPI failed!");
        return true;
    } else {
        StartHttpServer();
        title.PlayMapList(mapUris, "Trackmania/" + ArchivistModeScriptName, xml);
    }
    return false;
}
