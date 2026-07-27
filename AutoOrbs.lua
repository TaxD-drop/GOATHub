-- ModuleScript: GOATHub.AutoOrbs
-- O log mostrou: Network["Orbs: Collect"]:FireServer({ orbId, ... })

local AutoOrbs = {}
AutoOrbs.__index = AutoOrbs

local BATCH_SIZE = 100
local INTERVAL = 0.20

function AutoOrbs.new(collectRemote, onStatus)
    return setmetatable({
        remote = collectRemote,
        onStatus = onStatus or function() end,
        running = false,
    }, AutoOrbs)
end

function AutoOrbs:_collectVisibleOrbs()
    local things = workspace:FindFirstChild("__THINGS")
    local folder = things and things:FindFirstChild("Orbs")
    if not folder then return 0 end

    local ids = {}
    for _, orb in ipairs(folder:GetChildren()) do
        local id = tonumber(orb.Name)
        if id then
            table.insert(ids, id)
        end
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
    task.spawn(function()
        while self.running do
            local count = self:_collectVisibleOrbs()
            self.onStatus(count > 0 and ("Coletando " .. count .. " orbs") or "Auto Orbs ligado")
            task.wait(INTERVAL)
        end
    end)
end

function AutoOrbs:stop()
    self.running = false
    self.onStatus("Auto Orbs desligado")
end

return AutoOrbs
