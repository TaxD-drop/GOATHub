-- ModuleScript: GOATHub.AutoRanks
-- O cliente oficial chama Ranks_ClaimReward com o índice da recompensa.

local AutoRanks = {}
AutoRanks.__index = AutoRanks

AutoRanks.CHECK_INTERVAL = 10

function AutoRanks.new(claimRemote, onStatus)
    local self = setmetatable({
        remote = claimRemote,
        onStatus = onStatus or function() end,
        enabled = false,
    }, AutoRanks)

    local library = game:GetService("ReplicatedStorage"):WaitForChild("Library")
    self.directory = require(library.Directory)
    self.save = require(library.Client.Save)
    self.ranksUtil = require(library.Util.RanksUtil)
    return self
end

function AutoRanks:_claimReady()
    local data = self.save.Get()
    if not data or not data.Rank or not data.RankStars then return 0 end

    local rankId = self.ranksUtil.RankIDFromNumber(data.Rank)
    local rank = rankId and self.directory.Ranks[rankId]
    if not rank then return 0 end

    local claimed = 0
    local starsRequired = 0
    local redeemed = data.RedeemedRankRewards or {}
    for rewardIndex, reward in ipairs(rank.Rewards) do
        if not self.enabled then break end
        starsRequired += reward.StarsRequired
        if data.RankStars >= starsRequired and not redeemed[tostring(rewardIndex)] then
            local ok = pcall(function()
                self.remote:FireServer(rewardIndex)
            end)
            if ok then claimed += 1 end
            task.wait(0.3)
        end
    end
    return claimed
end

function AutoRanks:_loop()
    while self.enabled do
        local claimed = self:_claimReady()
        if self.enabled and claimed > 0 then
            self.onStatus("Recompensas de rank solicitadas: " .. claimed)
        end

        local elapsed = 0
        while self.enabled and elapsed < AutoRanks.CHECK_INTERVAL do
            task.wait(1)
            elapsed += 1
        end
    end
end

function AutoRanks:setEnabled(enabled)
    if self.enabled == enabled then return end
    self.enabled = enabled
    if enabled then
        self.onStatus("Auto Collect Ranks ligado")
        task.spawn(function() self:_loop() end)
    else
        self.onStatus("Auto Collect Ranks desligado")
    end
end

function AutoRanks:stop()
    self.enabled = false
end

return AutoRanks
