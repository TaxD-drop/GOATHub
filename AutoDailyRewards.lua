-- ModuleScript: GOATHub.AutoDailyRewards
-- Tenta resgatar todas as recompensas temporizadas. O servidor valida cooldown,
-- disponibilidade e a recompensa aceita; assim o cliente não depende de um
-- timer local que pode estar desatualizado.

local AutoDailyRewards = {}
AutoDailyRewards.__index = AutoDailyRewards

AutoDailyRewards.CHECK_INTERVAL = 8

function AutoDailyRewards.new(redeemRemote, approachedRemote, onStatus)
    local self = setmetatable({
        remote = redeemRemote,
        approachedRemote = approachedRemote,
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

function AutoDailyRewards:_collectAll()
    local collected = 0
    local attempted = 0

    -- O código oficial itera Directory.TimedRewards diretamente. Mantemos o
    -- mesmo iterador porque essas tabelas de diretório podem ter __iter.
    for rewardName, reward in self.directory.TimedRewards do
        if not self.enabled then break end

        attempted += 1
        -- A ordem é a mesma registrada no cliente oficial ao entrar no pad:
        -- resgate primeiro, seguido do registro de aproximação da máquina.
        local ok, accepted = pcall(function()
            return self.remote:InvokeServer(rewardName)
        end)
        pcall(function()
            self.approachedRemote:FireServer(reward.MachineName or rewardName)
        end)
        if ok and accepted then
            collected += 1
        end
        task.wait(0.12)
    end
    return collected, attempted
end

function AutoDailyRewards:_loop()
    while self.enabled do
        local collected, attempted = self:_collectAll()
        if self.enabled and collected > 0 then
            self.onStatus("Recompensas diárias coletadas: " .. collected)
        elseif self.enabled and attempted == 0 then
            self.onStatus("Daily Rewards não carregadas neste servidor")
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
