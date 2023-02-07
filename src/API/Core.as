
const string LocalAccountId {
    get {
        return cast<CGameManiaPlanet>(GetApp()).MenuManager.MenuCustom_CurrentManiaApp.LocalUser.WebServicesUserId;
    }
}


const string CurrentMapUid {
    get {
        auto m = GetApp().RootMap;
        if (m is null) return "";
        return m.EdChallengeId;
    }
}


// todo: necessary?


// Do not keep handles to these objects around
CNadeoServicesMap@ GetMapFromUid(const string &in mapUid) {
    auto app = cast<CGameManiaPlanet>(GetApp());
    auto userId = app.MenuManager.MenuCustom_CurrentManiaApp.UserMgr.Users[0].Id;
    auto resp = app.MenuManager.MenuCustom_CurrentManiaApp.DataFileMgr.Map_NadeoServices_GetFromUid(userId, mapUid);
    WaitAndClearTaskLater(resp, app.MenuManager.MenuCustom_CurrentManiaApp.DataFileMgr);
    if (resp.HasFailed || !resp.HasSucceeded) {
        throw('GetMapFromUid failed: ' + resp.ErrorCode + ", " + resp.ErrorType + ", " + resp.ErrorDescription);
    }
    return resp.Map;
}


/***
 *
 * Do not keep handles to this object around! use immediately.
 *
 * Scopes:
 *  #Const C_BrowserFilter_GameData 1
    #Const C_BrowserFilter_TitleData 2
    #Const C_BrowserFilter_GameAndTitleData 3
    #Const C_BrowserFilter_UserData 4
    #Const C_BrowserFilter_AllData 7
 */
CWebServicesTaskResult_MapListScript@ Map_GetFilteredGameList(uint scope, const string &in path, bool flatten, bool sortByNameElseDate, bool sortOrderAsc) {
    auto app = cast<CGameManiaPlanet>(GetApp());
    auto resp = app.MenuManager.MenuCustom_CurrentManiaApp.DataFileMgr.Map_GetFilteredGameList(scope, path, flatten, sortByNameElseDate, sortOrderAsc);
    WaitAndClearTaskLater(resp, app.MenuManager.MenuCustom_CurrentManiaApp.DataFileMgr);
    return resp;
}

void Map_RefreshFromDisk() {
    // crashes in a server
    ReturnToMenu();
    auto app = cast<CGameManiaPlanet>(GetApp());
    app.MenuManager.MenuCustom_CurrentManiaApp.DataFileMgr.Map_RefreshFromDisk();
}
