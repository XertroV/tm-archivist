namespace LocalStats {
    Json::Value@ data = null;
    const string DbFilePath = IO::FromStorageFolder("local-stats_v1.json");

    void Load() {
        @data = Json::FromFile(DbFilePath);
        if (data is null || data.GetType() != Json::Type::Object) {
            @data = Json::Object();
            data['runs'] = 0;
            data['complete_runs'] = 0;
            data['partial_runs'] = 0;
            data['maps'] = Json::Object();
            data['init_ts'] = tostring(Time::Stamp);
            data['recent_maps'] = Json::Array();
            data['map_infos'] = Json::Object();
            data['time_spent'] = "0";
            data['nbRespawns'] = 0;
            data['nbCheckpoints'] = 0;
            Save();
        }
    }

    void Save() {
        auto start = Time::Now;
        if (IO::FileExists(DbFilePath))
            CopyFile(DbFilePath, DbFilePath + ".back");
        Json::ToFile(DbFilePath, data);
        auto duration = Time::Now - start;
        log_info("\\$ccfSaved LocalStats JSON db in " + duration + "ms.");
    }

    uint lastSaveSoonReq = 0;
    void SaveSoon() {
        uint thisReq = ++lastSaveSoonReq;
        // a little breathing room
        sleep(500);
        if (thisReq == lastSaveSoonReq) {
            Save();
        }
    }

    Json::Value@ GetMapInfosData() {
        if (data is null) return Json::Object();
        if (!data.HasKey('map_infos')) return Json::Object();
        return data.Get('map_infos');
    }

    Json::Value@ GetRecentMaps() {
        if (data is null) return Json::Array();
        if (!data.HasKey('recent_maps')) return Json::Array();
        return data.Get('recent_maps');
    }

    Json::Value@ GetMapInfoData(const string &in uid) {
        auto mapInfos = GetMapInfosData();
        if (!mapInfos.HasKey(uid)) {
            mapInfos[uid] = Json::Object();
            mapInfos[uid]['load_method'] = GenLoadMethodUid(uid);
            mapInfos[uid]['name'] = '';
            mapInfos[uid]['author'] = '';
            mapInfos[uid]['tmx'] = '0';
            mapInfos[uid]['nb_loaded'] = 0;
        }
        return mapInfos.Get(uid);
    }

    void AddRecentMapUid(const string &in uid) {
        auto recents = GetRecentMaps();
        int ix = FindStrInJsonArray(recents, uid);
        if (ix >= 0) {
            recents.Remove(ix);
        } else {
            ix = recents.Length;
        }
        data['recent_maps'] = InsertAtJA(recents, 0, uid);
        SaveSoon();
    }

    int GetTotalTimeSpent() {
        if (data is null) return -1;
        return Text::ParseInt(data.Get('time_spent', "0"));
    }

    int GetTotalRuns() {
        if (data is null) return -1;
        return int(data.Get('runs', 0));
    }

    int GetCompleteRuns() {
        if (data is null) return -1;
        return int(data.Get('complete_runs', 0));
    }

    int GetPartialRuns() {
        if (data is null) return -1;
        return int(data.Get('partial_runs', 0));
    }

    int GetNbRespawns() {
        if (data is null) return -1;
        return int(data.Get('nbRespawns', 0));
    }

    int GetNbCheckpoints() {
        if (data is null) return -1;
        return int(data.Get('nbCheckpoints', 0));
    }

    void IncrRuns(const string &in uid, bool complete, uint duration_seconds, int nbRespawns, int nbCheckpoints) {
        if (data is null) return;
        data['runs'] = GetTotalRuns() + 1;
        data['time_spent'] = tostring(GetTotalTimeSpent() + duration_seconds);
        data['nbRespawns'] = GetNbRespawns() + nbRespawns;
        data['nbCheckpoints'] = GetNbCheckpoints() + nbCheckpoints;
        auto map_data = GetMapStats(uid);
        map_data['runs'] = map_data.Get('runs', 0) + 1;
        map_data['time_spent'] = JsonIntAdd(map_data.Get('time_spent', "0"), duration_seconds);
        map_data['nbRespawns'] = map_data.Get('nbRespawns', 0) + nbRespawns;
        map_data['nbCheckpoints'] = map_data.Get('nbCheckpoints', 0) + nbCheckpoints;
        if (complete) {
            data['complete_runs'] = GetCompleteRuns() + 1;
            map_data['complete_runs'] = map_data.Get('complete_runs', 0) + 1;
        } else {
            data['partial_runs'] = GetPartialRuns() + 1;
            map_data['partial_runs'] = map_data.Get('partial_runs', 0) + 1;
        }
        SaveSoon();
    }

    Json::Value@ GetMaps() {
        if (!data.HasKey('maps')) {
            data['maps'] = Json::Object();
        }
        return data['maps'];
    }

    int GetNbMaps() {
        if (data is null) return -1;
        return GetMaps().Length;
    }

    Json::Value@ GetMapStats(const string &in uid) {
        if (data is null) return null;
        auto mr = GetMaps();
        if (!mr.HasKey(uid)) {
            mr[uid] = Json::Object();
            mr[uid]['complete_runs'] = 0;
            mr[uid]['partial_runs'] = 0;
            mr[uid]['runs'] = 0;
            mr[uid]['time_spent'] = "0";
            mr[uid]['nbRespawns'] = 0;
            mr[uid]['nbCheckpoints'] = 0;
        }
        return mr[uid];
    }


    Json::Value@ nextLoadMethod;
    void SetNextMapLoadMethod(Json::Value@ lm) {
        @nextLoadMethod = lm;
    }


    void RegisterCurrentMapAsRecent() {
        auto map = GetApp().RootMap;
        if (map is null) {
            log_warn("Tried to add current map but map is null");
            return;
        }
        auto mi = map.MapInfo;
        if (mi is null) {
            log_warn("Tried to add current map but .MapInfo is null");
            return;
        }
        log_warn("Add map to recent: " + ColoredString(mi.Name));
        // auto dataMapInfos = GetMapInfosData();
        // data['map_infos'] = dataMapInfos;
        auto miData = GetMapInfoData(mi.MapUid);
        if (nextLoadMethod !is null)
            miData['load_method'] = nextLoadMethod;
        miData['name'] = ColoredString(mi.Name);
        miData['author'] = string(mi.AuthorNickName);
        if (miData['load_method'].HasKey('tmx'))
            miData['tmx'] = miData['load_method']['tmx'];
        miData['nb_loaded'] = 1 + miData['nb_loaded'];
        miData['last_played'] = tostring(Time::Stamp);
        AddRecentMapUid(mi.MapUid);
        SaveSoon();
    }

    Json::Value@ GenLoadMethodUid(const string &in uid) {
        auto j = Json::Object();
        j['method'] = 'uid';
        j['payload'] = uid;
        return j;
    }

    Json::Value@ GenLoadMethodUrl(const string &in url) {
        auto j = Json::Object();
        j['method'] = 'url';
        j['payload'] = url;
        return j;
    }

    Json::Value@ GenLoadMethodTmx(const string &in url, const string &in tmx) {
        auto j = Json::Object();
        j['method'] = 'url';
        j['payload'] = url;
        j['tmx'] = tmx;
        return j;
    }
}







void CopyFile(const string &in f1, const string &in f2) {
    IO::File file1(f1, IO::FileMode::Read);
    IO::File file2(f2, IO::FileMode::Write);
    file2.Write(file1.Read(file1.Size()));
    file1.Close();
    file2.Close();
}

const string JsonIntAdd(const string &in jsonInt, int amt) {
    try {
        return tostring(Text::ParseInt(jsonInt) + amt);
    } catch {
        warn("JsonIntAdd Failed: " + getExceptionInfo());
        return "0";
    }
}

Json::Value@ SliceJA(Json::Value@ arr, uint ix, uint num) {
    auto ret = Json::Array();
    for (int c = 0; c < Math::Min(num, arr.Length); c++) {
        ret.Add(arr[ix + c]);
    }
    return ret;
}

Json::Value@ InsertAtJA(Json::Value@ arr, uint ix, Json::Value@ value) {
    auto ret = Json::Array();
    for (uint i = 0; i < uint(Math::Min(ix, arr.Length)); i++) {
        ret.Add(arr[i]);
    }
    ret.Add(value);
    for (uint i = ix; i < arr.Length; i++) {
        ret.Add(arr[i]);
    }
    return ret;
}

int FindStrInJsonArray(Json::Value@ arr, const string &in value) {
    for (uint i = 0; i < arr.Length; i++) {
        if (value == arr[i]) {
            return i;
        }
    }
    return -1;
}
