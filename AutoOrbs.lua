-- ModuleScript: GOATHub.AutoOrbs
-- O log mostrou: Network["Orbs: Collect"]:FireServer({ orbId, ... })

local AutoOrbs = {}
AutoOrbs.__index = AutoOrbs

local BATCH_SIZE = 250
local INTERVAL = 0.06

function AutoOrbs.new(collectRemote, onStatus)
    local enchantCmds
    pcall(function()
        enchantCmds = require(game:GetService("ReplicatedStorage").Library.Client.EnchantCmds)
    end)
    return setmetatable({
        remote = collectRemote,
        onStatus = onStatus or function() end,
        running = false,
        enchantCmds = enchantCmds,
        originalGetPower = nil,
        forcedGetPower = nil,
    }, AutoOrbs)
end

function AutoOrbs:_setSuperMagnet(enabled)
    if not self.enchantCmds then return false end
    if enabled then
        if self.forcedGetPower then return true end
        self.originalGetPower = self.enchantCmds.GetPower
        local original = self.originalGetPower
        local forced = function(enchantName, player)
            if enchantName == "Super Magnet" then return 1 end
            return original(enchantName, player)
        end
        local ok = pcall(function() self.enchantCmds.GetPower = forced end)
        if ok then self.forcedGetPower = forced end
        return ok
    end
    if self.forcedGetPower and self.enchantCmds.GetPower == self.forcedGetPower then
        pcall(function() self.enchantCmds.GetPower = self.originalGetPower end)
    end
    self.originalGetPower, self.forcedGetPower = nil, nil
    return true
end

function AutoOrbs:_collectVisibleOrbs()
    local things = workspace:FindFirstChild("__THINGS")
    local folder = things and things:FindFirstChild("Orbs")
    if not folder then return 0 end

    local ids = {}
    for _, orb in ipairs(folder:GetChildren()) do
        -- Orbs normais costumam ter ID numérico; lootbags podem usar um UID
        -- textual. Os dois tipos são coletados pelo mesmo remote.
        table.insert(ids, tonumber(orb.Name) or orb.Name)
    end

    for first = 1, #ids, BATCH_SIZE do
        if not self.running then break end
        local batch = {}
        for index = first, math.min(first + BATCH_SIZE - 1, #ids) do
            table.insert(batch, ids[index])
        end
        if #batch > 0 then self.remote:FireServer(batch) end
    end
    return #ids
end

function AutoOrbs:start()
    if self.running then return end
    self.running = true
    local magnetEnabled = self:_setSuperMagnet(true)
    task.spawn(function()
        while self.running do
            local count = self:_collectVisibleOrbs()
            local message = count > 0 and ("Coletando " .. count .. " drops") or "Auto Orbs ligado"
            self.onStatus(magnetEnabled and (message .. " (Super Magnet)") or message)
            task.wait(INTERVAL)
        end
        self:_setSuperMagnet(false)
    end)
end

function AutoOrbs:stop()
    self.running = false
    self:_setSuperMagnet(false)
    self.onStatus("Auto Orbs desligado")
end

return AutoOrbs
