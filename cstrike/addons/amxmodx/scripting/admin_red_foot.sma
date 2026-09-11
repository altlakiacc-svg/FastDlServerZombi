#include <amxmodx>
#include <amxmisc>
#include <cstrike>

public plugin_init() {
        register_plugin("AMX Admin Girl", "1.0", "whitemike & homorapian")
        register_event("ResetHUD", "resetModel", "b")
        return PLUGIN_CONTINUE
}

public plugin_precache() {
        precache_model("models/player/admin_red_foot/admin_red_foot.mdl")

        return PLUGIN_CONTINUE
}

public resetModel(id, level, cid) {
        if (get_user_flags(id) & ADMIN_USER) {
                new CsTeams:userTeam = cs_get_user_team(id)
                if (userTeam == CS_TEAM_CT) {
                        cs_set_user_model(id, "admin_red_foot")
                }
                else {
                        cs_reset_user_model(id)
                }
        }

        return PLUGIN_CONTINUE
}
