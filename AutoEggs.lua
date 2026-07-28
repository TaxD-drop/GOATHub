-- ModuleScript: GOATHub.AutoEggs
-- Compra ovos normais pelo mesmo fluxo Eggs_RequestPurchase usado pelo jogo.

local AutoEggs = {}
AutoEggs.__index = AutoEggs

local FALLBACK_AMOUNT = 3
local FALLBACK_DEBOUNCE = 2.6

local function safeRequire(instance)
    local ok, value = pcall(require, instance)
    return ok and value or nil
end

function AutoEggs.new(purchaseRemote, animationRemote, onStatus)
    local library = game:GetService("ReplicatedStorage"):WaitForChild("Library")
    local client = library:WaitForChild("Client")
    local balancing = library:WaitForChild("Balancing")
    local directory = safeRequire(library:WaitForChild("Directory")) or {}
    local eggs = {}
    for name in pairs(directory.Eggs or {}) do table.insert(eggs, name) end
    table.sort(eggs)

    return setmetatable({
        remote = purchaseRemote,
        animationRemote = animationRemote,
        directory = directory,
        eggCmds = safeRequire(client:WaitForChild("EggCmds")),
        currencyCmds = safeRequire(client:WaitForChild("CurrencyCmds")),
        calcPrice = safeRequire(balancing:WaitForChild("CalcEggPricePlayer")),
        eggs = eggs,
        selectedEggs = {},
        onStatus = onStatus or function() end,
        running = false,
        disabledConnections = {},
    }, AutoEggs)
end

function AutoEggs:_selectedNames()
    local names = {}
    for _, name in ipairs(self.eggs) do
        if self.selectedEggs[name] then table.insert(names, name) end
    end
    return names
end

function AutoEggs:_getAmount(name)
    local egg = self.directory.Eggs and self.directory.Eggs[name]
    local amount = FALLBACK_AMOUNT
    if self.eggCmds and egg then
        local ok, value = pcall(self.eggCmds.GetMaxHatch, egg)
        if ok and type(value) == "number" then amount = value end
    end
    if self.currencyCmds and self.calcPrice and egg and egg.currency then
        -- Currency pode ser número comum ou BigNum; o próprio jogo usa a
        -- divisão entre esses valores. Mantemos a conta dentro de pcall.
        local ok, affordable = pcall(function()
            return math.floor(self.currencyCmds.Get(egg.currency) / self.calcPrice(egg))
        end)
        if ok and type(affordable) == "number" then
            amount = math.min(amount, affordable)
        end
    end
    return math.max(0, math.floor(amount))
end

function AutoEggs:_getDebounce()
    if self.eggCmds then
        local ok, value = pcall(self.eggCmds.ComputeDebounce)
        if ok and type(value) == "number" then return value + 0.1 end
    end
    return FALLBACK_DEBOUNCE
end

function AutoEggs:_setAnimationHidden(hidden)
    if type(getconnections) ~= "function" then return false end
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

function AutoEggs:start()
    if self.running then return true end
    if #self:_selectedNames() == 0 then
        self.onStatus("Selecione ao menos um egg")
        return false
    end
    self.running = true
    local hidden = self:_setAnimationHidden(true)
    self.onStatus(hidden and "Auto Eggs ligado (animação oculta)" or "Auto Eggs ligado")
    task.spawn(function()
        while self.running do
            for _, name in ipairs(self:_selectedNames()) do
                if not self.running then break end
                local amount = self:_getAmount(name)
                if amount > 0 then
                    local ok, accepted, reason = pcall(function()
                        return self.remote:InvokeServer(name, amount)
                    end)
                    if ok and accepted then
                        self.onStatus("Abrindo " .. amount .. "x " .. name)
                    elseif reason then
                        self.onStatus(tostring(reason))
                    end
                    task.wait(self:_getDebounce())
                else
                    self.onStatus("Sem moeda para " .. name)
                    task.wait(0.5)
                end
            end
        end
        self:_setAnimationHidden(false)
    end)
    return true
end

function AutoEggs:stop()
    self.running = false
    self:_setAnimationHidden(false)
    self.onStatus("Auto Eggs desligado")
end

return AutoEggs
