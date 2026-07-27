-- ModuleScript: GOATHub.AutoBreakables
-- O servidor recebe Breakables_PlayerDealDamage com o UID do breakable.

local AutoBreakables = {}
AutoBreakables.__index = AutoBreakables

local INTERVAL = 0.12

function AutoBreakables.new(damageRemote, onStatus)
    return setmetatable({
        remote = damageRemote,
        onStatus = onStatus or function() end,
        running = false,
    }, AutoBreakables)
end

function AutoBreakables:_getBreakableIds()
    local things = workspace:FindFirstChild("__THINGS")
    local folder = things and things:FindFirstChild("Breakables")
    if not folder then return {} end

    local ids = {}
    for _, breakable in ipairs(folder:GetChildren()) do
        -- O dump usa o UID como nome da instância e como argumento da rede.
        table.insert(ids, breakable.Name)
    end
    return ids
end

function AutoBreakables:start()
    if self.running then return end
    self.running = true
    task.spawn(function()
        while self.running do
            local ids = self:_getBreakableIds()
            if #ids == 0 then
                self.onStatus("Nenhum item quebrável nesta área")
                task.wait(0.5)
            else
                for _, id in ipairs(ids) do
                    if not self.running then break end
                    self.remote:FireServer(id)
                    task.wait(INTERVAL)
                end
                self.onStatus("Auto Quebrar: " .. #ids .. " itens")
            end
        end
    end)
end

function AutoBreakables:stop()
    self.running = false
    self.onStatus("Auto Quebrar desligado")
end

return AutoBreakables
