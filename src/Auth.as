bool _AuthLoopStartEarly = false;

uint lastAuthTime = 0;
string g_opAuthToken;

bool KeepAuthActive {
    get {
        return ShowWindow || InArchivistGameMode;
    }
}

void AuthLoop() {
    while (Time::Now < 120000 && !_AuthLoopStartEarly) yield();
    while (true) {
        sleep(500);
        CheckTokenUpdate();
    }
}

void CheckTokenUpdate() {
    if (!KeepAuthActive) return;
    if (g_opAuthToken == "" || lastAuthTime == 0 || (Time::Now - lastAuthTime) > (50 * 60 * 1000)) {
        try {
            auto task = Auth::GetToken();
            while (!task.Finished()) yield();
            g_opAuthToken = task.Token();
            lastAuthTime = Time::Now;
            OnGotNewToken();
        } catch {
            warn("Got exception refreshing auth token: " + getExceptionInfo());
            g_opAuthToken = "";
        }
    }
}


void OnGotNewToken() {
    log_info("Updated Openplanet Auth Token");
    startnew(UpdateApiTokenViaMLHook);
    API::Archivist::RegisterToken();
}

const string CurrentOpenplanetToken() {
    while (g_opAuthToken == "") yield();
    return g_opAuthToken;
}
