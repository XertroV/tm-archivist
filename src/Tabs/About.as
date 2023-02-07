class AboutTab : Tab {
    AboutTab() {
        super(Icons::QuestionCircle + " About", false);
        canCloseTab = true;
    }

    void OnCloseTab() override {
        S_AboutTabOpen = false;
    }

    bool BeginTabItem() override {
        if (!S_AboutTabOpen) return false;
        return Tab::BeginTabItem();
    }

    void DrawInner() override {
        UI::Markdown("""
 # Welcome

 Here is some important info before you get started:

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
 **Saving ghosts is not available if the 'Upload Ghosts' setting is disabled.**

 ### Your Data

 In order to access the actual ghost file and write it to disk, we need to upload it to a server, first.
 Ghosts uploaded to the Archivist server are not deleted, and will remain publicly accessible along with some metadata (similar to Nadeo leaderboards).

 ### Your Preferences
        """);
        VSpace();
        DrawUploadGhostsCheckbox();
        DrawSaveGhostsAndOrReplaysCheckbox();
        VSpace();
        UI::Markdown("""

 ## Run History

 When 'Upload Ghosts' is enabled, data about your runs will be saved on the server and will be accessible to you.

 This includes data like: your run history and overall stats.

 ## Public Stats

 Public overview stats are also available for uploaded ghosts.

        """);
    }
}
