bool _AuthLoopStartEarly = false;

uint lastAuthTime = 0;
string g_opAuthToken;

void AuthLoop() {
    while (Time::Now < 120000 && !_AuthLoopStartEarly) yield();
    while (true) {
        yield();

    }
}
