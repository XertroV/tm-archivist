## scoreMgr.Playground_GetPlayerGhost -- doesn't work

```angelscript
void TestGhostFromCMAP() {
    auto cmap = GetApp().Network.ClientManiaAppPlayground;
    auto cp = GetApp().CurrentPlayground;
    auto scoreMgr = cmap.ScoreMgr;
    for (uint i = 0; i < cp.Players.Length; i++) {
        auto player = cast<CSmPlayer>(cp.Players[i]);
        trace('player: ' + player.User.Name);
        auto ghost = scoreMgr.Playground_GetPlayerGhost(player.ScriptAPI);
        if (ghost is null) {
            trace('ghost null'); continue;
        }
        print('ghost.Nickname' + ghost.Nickname);
        print('ghost.Result.Time' + ghost.Result.Time);
    }
}
```

## TruncateLaunchedCheckpointsRespawns

does not work with partial ghosts

does indeed work -- segmented replay on leaderboards

https://trackmania.io/#/leaderboard/ARnJqXA5Ws90EGXulYwClxkQoV
