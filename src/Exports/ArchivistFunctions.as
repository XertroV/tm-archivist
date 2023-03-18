namespace Archivist {
    // The local stats DB as a json object (read only).
    import const Json::Value@ GetLocalStats() from 'Archivist';
    // Returns immediately.
    import void LoadMapFromUrlNow(const string &in url) from 'Archivist';
    // Returns immediately.
    import void LoadMapFromUidNow(const string &in uid) from 'Archivist';
    // The archivist game mode name (it is dynamic).
    import const string GameModeName() from 'Archivist';
    // Whether currently in an archivist game mode.
    import bool IsInArchivistGameMode() from 'Archivist';
}
