-- ModuleScript: GOATHub.AutoEggs
-- Usa o mesmo RemoteFunction de EggCmds.RequestPurchase encontrado no dump.

local AutoEggs = {}
AutoEggs.__index = AutoEggs

local HATCH_AMOUNT = 3 -- quantidade confirmada no log
local REQUEST_INTERVAL = 2.6 -- respeita o debounce normal de abertura

function AutoEggs.new(purchaseRemote, animationRemote, directory, onStatus)
    local eggs = {}
    for name in pairs(directory.Eggs or {}) do
        table.insert(eggs, name)
    end
    table.sort(eggs)

    return setmetatable({
        remote = purchaseRemote,
        animationRemote = animationRemote,
        eggs = eggs,
        selectedEggs = {},
        onStatus = onStatus or function() end,
        running = false,
        disabledConnections = {},
    }, AutoEggs)
end

function AutoEggs:_setAnimationHidden(hidden)
    -- Em executores compatíveis, desliga apenas os listeners visuais durante
    -- o Auto Open. Em Roblox normal essa API não existe e o hatch continua
    -- funcionando, apenas com a animação padrão.
    if type(getconnections) ~= "function" then
        return false
    end

    if hidden then
        for _, connection in ipairs(getconnections(self.animationRemote.OnClientEvent)) do
            if connection.Disable then
                connection:Disable()
                table.insert(self.disabledConnections, connection)
            end
        end
        return #self.disabledConnections > 0
    end

    for _, connection in ipairs(self.disabledConnections) do
        if connection.Enable then connection:Enable() end
    end
    table.clear(self.disabledConnections)
    return true
end

function AutoEggs:_selectedNames()
    local names = {}
    for _, egg in ipairs(self.eggs) do
        if self.selectedEggs[egg] then table.insert(names, egg) end
    end
    return names
end

function AutoEggs:start()
    if self.running then return true end
    if #self:_selectedNames() == 0 then
        self.onStatus("Selecione pelo menos um egg")
        return false
    end

    self.running = true
    local animationHidden = self:_setAnimationHidden(true)
    self.onStatus(animationHidden and "Auto Open ligado (animação oculta)" or "Auto Open ligado")
    task.spawn(function()
        while self.running do
            for _, eggName in ipairs(self:_selectedNames()) do
                if not self.running then break end
                pcall(function()
                    self.remote:InvokeServer(eggName, HATCH_AMOUNT)
                end)
                task.wait(REQUEST_INTERVAL)
            end
            task.wait(0.1)
        end
        self:_setAnimationHidden(false)
    end)
    return true
end

function AutoEggs:stop()
    self.running = false
    self.onStatus("Auto Open Eggs desligado")
end

return AutoEggs
