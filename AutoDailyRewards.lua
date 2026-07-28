-- ModuleScript: GOATHub.AutoDailyRewards
-- Coleta apenas recompensas temporizadas que o save local informa estarem prontas.

local AutoDailyRewards = {}
AutoDailyRewards.__index = AutoDailyRewards

AutoDailyRewards.CHECK_INTERVAL = 15

function AutoDailyRewards.new(redeemRemote, onStatus)
    local self = setmetatable({
        remote = redeemRemote,
        onStatus = onStatus or function() end,
        enabled = false,
        directory = nil,
        save = nil,
    }, AutoDailyRewards)

    local replicatedStorage = game:GetService("ReplicatedStorage")
    local library = replicatedStorage:WaitForChild("Library")
    self.directory = require(library.Directory)
    self.save = require(library.Client.Save)
    return self
end

function AutoDailyRewards:_isReady(rewardName, reward)
    local data = self.save.Get()
    if not data or not reward then return false end

    local timestamp = data.TimedRewardTimestamps and data.TimedRewardTimestamps[rewardName]
    return not timestamp or workspace:GetServerTimeNow() - timestamp > reward.Cooldown
end

function AutoDailyRewards:_collectReady()
    local collected = 0
    for rewardName, reward in pairs(self.directory.TimedRewards) do
        if not self.enabled then break end
        if self:_isReady(rewardName, reward) then
            local ok, accepted = pcall(function()
                return self.remote:InvokeServer(rewardName)
            end)
            if ok and accepted then
                collected += 1
            end
            task.wait(0.25)
        end
    end
    return collected
end

function AutoDailyRewards:_loop()
    while self.enabled do
        local collected = self:_collectReady()
        if self.enabled and collected > 0 then
            self.onStatus("Recompensas diárias coletadas: " .. collected)
        end

        local elapsed = 0
        while self.enabled and elapsed < AutoDailyRewards.CHECK_INTERVAL do
            task.wait(1)
            elapsed += 1
        end
    end
end

function AutoDailyRewards:setEnabled(enabled)
    if self.enabled == enabled then return end
    self.enabled = enabled
    if enabled then
        self.onStatus("Auto Collect Daily Rewards ligado")
        task.spawn(function() self:_loop() end)
    else
        self.onStatus("Auto Collect Daily Rewards desligado")
    end
end

function AutoDailyRewards:stop()
    self.enabled = false
end

return AutoDailyRewards
