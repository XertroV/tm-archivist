class AboutTab : Tab {
    AboutTab() {
        super(Icons::QuestionCircle + " About", false);
        canCloseTab = true;
    }

    void OnCloseTab() override {
        S_AboutTabOpen_1 = false;
    }

    bool BeginTabItem() override {
        if (!S_AboutTabOpen_1) return false;
        return Tab::BeginTabItem();
    }

    void DrawInner() override {
        UI::Markdown("""
 # Welcome

 ## Updates!

 The rest of this tab has updated, so read it too.

 - No online component anymore
 - Uploading ghosts works and is entirely local. note that there have been some bugs with maps with funky names, so test out ghost saving etc.
 - ghost management sliders work now (pb / recent ghosts)
 - segmented runs behind a setting (compatible with saving ghosts)
 - load maps from TMX or campaign
 - recent maps and local stats

 ## Usage

 Archivist will load any map you like in a custom game mode.
 This is how Archivist can record every partial and complete run.
 There are a number of settings you should configure under the "Home" tab.

 ## Ghost Uploads, and Ghosts vs Replays

 The primary difference between ghosts and replays is that replays contain both a ghost and the map file.
 Ghosts take up about 70KB of space per minute.
 Depending on the map, saving ghosts instead of replays can save you many GB of disk space.
 For very short maps (<10s), ghosts use about 100x less space than replays.

 Ghosts and replays are saved separately, so you can save both and delete the replays later if you like.
 Ghosts can be imported into the replay editor, but cannot be used in 'Local > Against Replay'.
 (You will need help from a plugin like 'Ghost to Replay' if you want this.)
 In order to access the actual ghost file and write it to disk, we need to upload it to a server.
 Archivist does this by running a simple local HTTP server on port 29805.

 ### 'Segmented' Ghosts/Replays

 Archivist supports the creation of 'segmented' ghosts and/or replays for completed runs where you respawned more than once.
 These ghosts have respawns cut out (excluding standing respawns) and the ghost's name ends with " (Segmented)".
 The result is a ghost that (sort of) appears to complete the map without respawning.
 These ghosts maintain their original checkpoint times and completion time, and have other data indicating that they are segmented.
 They also still contain all inputs, even for the parts between respawns.

 These ghosts contain visual glitches that occur at the splice points.
 They're approximately as good as manually cutting out respawns in mediatracker, but are obviously much easier to generate.

 There are two main purposes: helping content creators demo long/difficult maps, and for personal use so that you have a respawn-less ghost to race against on a hard map.

 Segmented ghosts are never uploaded to leaderboards.
        """);
        // VSpace();
        // // DrawUploadGhostsCheckbox();
        // DrawSaveGhostsAndOrReplaysCheckbox();
        // VSpace();
        // UI::Markdown("""


        // """);
    }
}
