-- ModuleScript: GOATHubBuild.Config
-- Preencha os dois IDs antes de publicar/executar o hub.

return table.freeze({
    GAME_ID = 210851291,
    PLACES = table.freeze({
        MAIN = 537413528,
    }),

    DATA_FOLDER = "Data",
    SAVE_FLAG = "Save",

    REMOTES = table.freeze({
        ITEM_BOUGHT_FROM_SHOP = "ItemBoughtFromShop",
        CHANGE_TEAM = "ChangeTeam",
        CHANGE_TEAM_REQUEST = "ChangeTeamRequest",
        APPROVE_PLAYER = "ApprovePlayer",
        SHARE_REQUEST = "ShareRemote",
    }),

    -- Estes valores vieram literalmente do log 2026-07-29T21_15_53Z.log.
    -- Quantidade 0.1 não gastou Gold, mas também não concedeu item no log.
    AUTODUPE = table.freeze({
        CHEST_NAME = "Common Chest",
        PROBE_QUANTITY = 0.1,
        MAX_ATTEMPTS = 6,
        INTERVAL = 1.5,
        SETTLE_TIME = 0.85,
    }),
})
