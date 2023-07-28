void SetupEditorIntercepts() {
    Dev::InterceptProc("CGameEditorPluginMap", "TestMapWithMode2", _ButtonValidateOnClick);
}

bool _ButtonValidateOnClick(CMwStack &in stack, CMwNod@ nod) {
    string xml = stack.CurrentString();
    auto rulesMode = stack.CurrentWString(1);
    print(rulesMode);
    print(xml);
    // only block this script exactly
    if (!rulesMode.EndsWith("TM_RaceValidation_Local")) {
        return true;
    }
    auto pmt = cast<CGameEditorPluginMap>(nod);
    if (pmt is null) {
        warn("Casting nod to PMT failed!");
    } else {
        // pmt.TestMapWithMode2("Track")
    }
    return true;
}
