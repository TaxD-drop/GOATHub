-- ModuleScript: GOATHub.AutoVendingMachines
-- Compra o máximo permitido pelo cliente oficial em cada vending machine com estoque.

local AutoVendingMachines = {}
AutoVendingMachines.__index = AutoVendingMachines

AutoVendingMachines.CHECK_INTERVAL = 12

function AutoVendingMachines.new(purchaseRemote, onStatus)
    local self = setmetatable({
        remote = purchaseRemote,
        onStatus = onStatus or function() end,
        enabled = false,
    }, AutoVendingMachines)

    local library = game:GetService("ReplicatedStorage"):WaitForChild("Library")
    self.directory = require(library.Directory)
    self.save = require(library.Client.Save)
    self.currency = require(library.Client.CurrencyCmds)
    self.mastery = require(library.Client.MasteryCmds)
    return self
end

function AutoVendingMachines:_price(machine)
    local price = machine.CurrencyCost
    local ok, hasPerk = pcall(function()
        return self.mastery.HasPerk("Economy", "FreeVending")
    end)
    if ok and hasPerk and self.directory.Currency[machine.CurrencyType].IsWorldCurrency then
        return 0
    end

    local cheaper = false
    ok, cheaper = pcall(function()
        return self.mastery.HasPerk("Economy", "CheaperVending")
    end)
    if ok and cheaper then
        local power = self.mastery.GetPerkPower("Economy", "CheaperVending")
        price = math.ceil(price * (1 - power / 100))
    end
    return price
end

function AutoVendingMachines:_maxAmount(machine, stock)
    -- Sem o perk, o próprio menu do jogo limita a compra em três unidades.
    local amount = math.min(stock, 3)
    local ok, fullStock = pcall(function()
        return self.mastery.HasPerk("Economy", "BuyFullVendingStock")
    end)
    if ok and fullStock then amount = stock end

    local price = self:_price(machine)
    if price > 0 then
        local balance = self.currency.Get(machine.CurrencyType)
        amount = math.min(amount, math.floor(balance / price))
    end
    return math.max(0, amount)
end

function AutoVendingMachines:_buyAvailable()
    local data = self.save.Get()
    if not data or not data.VendingStocks then return 0 end

    local bought = 0
    for machineId, machine in pairs(self.directory.VendingMachines) do
        if not self.enabled then break end
        local stock = data.VendingStocks[machine._id or machineId] or 0
        local amount = self:_maxAmount(machine, stock)
        if amount > 0 then
            local ok, accepted = pcall(function()
                return self.remote:InvokeServer(machine._id or machineId, amount)
            end)
            if ok and accepted then bought += amount end
            task.wait(0.35)
            data = self.save.Get() or data
        end
    end
    return bought
end

function AutoVendingMachines:_loop()
    while self.enabled do
        local bought = self:_buyAvailable()
        if self.enabled and bought > 0 then
            self.onStatus("Vending Machines: " .. bought .. " itens comprados")
        end

        local elapsed = 0
        while self.enabled and elapsed < AutoVendingMachines.CHECK_INTERVAL do
            task.wait(1)
            elapsed += 1
        end
    end
end

function AutoVendingMachines:setEnabled(enabled)
    if self.enabled == enabled then return end
    self.enabled = enabled
    if enabled then
        self.onStatus("Auto Buy Vending Machines ligado")
        task.spawn(function() self:_loop() end)
    else
        self.onStatus("Auto Buy Vending Machines desligado")
    end
end

function AutoVendingMachines:stop()
    self.enabled = false
end

return AutoVendingMachines
