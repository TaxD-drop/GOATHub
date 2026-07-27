-- ModuleScript: GOATHub.AutoBreakables
-- O servidor recebe Breakables_PlayerDealDamage com o UID do breakable.

local AutoBreakables = {}
AutoBreakables.__index = AutoBreakables

-- O frontend padrão limita o clique manual a ~8 golpes/s. Aqui o alvo fica
-- travado até ser destruído, evitando a varredura lenta por todos os itens.
local HIT_INTERVAL = 0.06
local HITS_PER_TARGET = 12

function AutoBreakables.new(damageRemote, onStatus)
    return setmetatable({
        remote = damageRemote,
        onStatus = onStatus or function() end,
        running = false,
    }, AutoBreakables)
end

function AutoBreakables:_getNearestBreakable()
    local things = workspace:FindFirstChild("__THINGS")
    local folder = things and things:FindFirstChild("Breakables")
    local character = game:GetService("Players").LocalPlayer.Character
    local root = character and character.PrimaryPart
    if not (folder and root) then return nil end

    local nearestId, nearestDistance
    for _, breakable in ipairs(folder:GetChildren()) do
        local ok, pivot = pcall(function() return breakable:GetPivot() end)
        if ok then
            local distance = (pivot.Position - root.Position).Magnitude
            if not nearestDistance or distance < nearestDistance then
                nearestId, nearestDistance = breakable.Name, distance
            end
        end
    end
    return nearestId, nearestDistance
end

function AutoBreakables:start()
    if self.running then return end
    self.running = true
    task.spawn(function()
        while self.running do
            local id, distance = self:_getNearestBreakable()
            if not id then
                self.onStatus("Nenhum item quebrável nesta área")
                task.wait(0.5)
            else
                self.onStatus("Quebrando item a " .. math.floor(distance) .. " studs")
                for _ = 1, HITS_PER_TARGET do
                    if not self.running then break end
                    self.remote:FireServer(id)
                    task.wait(HIT_INTERVAL)
                end
            end
        end
    end)
end

function AutoBreakables:stop()
    self.running = false
    self.onStatus("Auto Quebrar desligado")
end

return AutoBreakables
