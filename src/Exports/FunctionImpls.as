namespace Archivist {
    const Json::Value@ GetLocalStats(){
        return LocalStats::data;
    }

    void LoadMapFromUrlNow(const string &in url){
        startnew(_LoadMapFromUidOrUrlForExport, array<string> = {url});
    }

    void LoadMapFromUidNow(const string &in uid){
        startnew(_LoadMapFromUidOrUrlForExport, array<string> = {uid});
    }

    const string GameModeName(){
        return ArchivistModeScriptName;
    }

    bool IsInArchivistGameMode() {
        try {
            return cast<CTrackManiaNetworkServerInfo>(GetApp().Network.ServerInfo).CurGameModeStr.Contains("TM_Archivist_");
        } catch {}
        return false;
    }
}

void _LoadMapFromUidOrUrlForExport(ref@ uidArrRef) {
    string[]@ uidArr = cast<string[]>(uidArrRef);
    if (uidArr is null) {
        log_error("_LoadMapFromUidOrUrlForExport didn't get a string[] argument.");
        return;
    }
    string url = uidArr[0];
    // check if this is a UID
    if (!url.Contains("://") && !url.Contains("/") && !url.Contains("\\") && !url.ToLower().Contains(".gbx") && url.Length > 24 && url.Length < 30) {
        auto mi = GetMapFromUid(uidArr[0]);
        if (mi is null) {
            log_warn("Tried to load map with UID=" + uidArr[0] + " but couldn't find it via Nadeo services.");
            return;
        }
        url = mi.FileUrl;
    }
    log_info(Meta::ExecutingPlugin().Name + " is loading a map in Archivist: " + url);
    LocalStats::SetNextMapLoadMethod(LocalStats::GenLoadMethodUrl(url));
    LoadMapNowInArchivist(url);
    yield();
    InitializeGameMode();
}
