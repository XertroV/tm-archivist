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
            data['time_spent'] = "0";
            data['nbRespawns'] = 0;
            data['nbCheckpoints'] = 0;
            Save();
        }
    }

    void Save() {
        if (IO::FileExists(DbFilePath))
            CopyFile(DbFilePath, DbFilePath + ".back");
        Json::ToFile(DbFilePath, data);
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
