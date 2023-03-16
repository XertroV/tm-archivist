// #if DEV
// [Setting category="[DEV] Debug" name="Local Dev Server"]
// bool S_LocalDev = true;
// #else
// const bool S_LocalDev = false;
// #endif

namespace API {
    namespace Archivist {
        // the server must validate the token in the first 5 min, but it's valid for 60 min (as long as it is registered)
        // void RegisterToken() {
        //     auto req = PluginGetRequest(PathToURL('/register/token/' + Meta::ExecutingPlugin().SiteID));
        //     CallMapMonitorApiPath(req);
        //     if (req.ResponseCode() >= 300) {
        //         warn("RegisterToken got response code " + req.ResponseCode() + " with body: " + req.String());
        //     }
        // }

        // const string MM_API_PROD_ROOT = "https://map-monitor.xk.io";
        // const string MM_API_DEV_ROOT = "http://localhost:8000";

        // const string API_ROOT {
        //     get {
        //         if (S_LocalDev) return MM_API_DEV_ROOT;
        //         else return MM_API_PROD_ROOT;
        //     }
        // }

        // const string PathToURL(const string &in path) {
        //     AssertGoodPath(path);
        //     return API::Archivist::API_ROOT + path;
        // }

        // Json::Value@ GetNbPlayersForMap(const string &in mapUid) {
        //     return CallMapMonitorApiPath(PluginGetRequest(PathToURL('/map/' + mapUid + '/nb_players/refresh')));
        // }
    }
}
