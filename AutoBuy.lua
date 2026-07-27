-- ModuleScript: GOATHub.AutoBuy
-- Compra somente os itens/slots marcados pela interface.

local AutoBuy = {}
AutoBuy.__index = AutoBuy

AutoBuy.EGGS = {
    "Pixel Chick", "Pixel Cat", "Pixel Piggy", "Pixel Corgi", "Pixel Bunny",
    "Pixel Goblin", "Pixel Bee", "Pixel Monkey", "Pixel Wolf", "Pixel Tiger",
    "Pixel Griffin", "Pixel Yeti", "Pixel Demon", "Pixel Agony", "Pixel Angelus",
    "Pixel Dominus Astra",
}

AutoBuy.SUPPLIES = {
    "Pixel Carrot", "Pixel Potato", "Pixel Corn", "Pixel Cookie", "Pixel Burger",
    "Farming Sprinkler 1", "Farming Sprinkler 2", "Farming Sprinkler 3",
}

function AutoBuy.new(plotsInvoke, onStatus)
    return setmetatable({
        remote = plotsInvoke,
        onStatus = onStatus or function() end,
        running = false,
        selectedEggs = {},
        selectedSupplies = {},
        selectedSlots = {},
    }, AutoBuy)
end

function AutoBuy:_invoke(plotId, action, value)
    return pcall(function()
        self.remote:InvokeServer(plotId, action, value)
    end)
end

function AutoBuy:_loop(plotId)
    while self.running do
        for _, egg in ipairs(AutoBuy.EGGS) do
            if not self.running then break end
            if self.selectedEggs[egg] then
                self:_invoke(plotId, "BuyEgg", egg)
                task.wait(0.20)
            end
        end

        for _, supply in ipairs(AutoBuy.SUPPLIES) do
            if not self.running then break end
            if self.selectedSupplies[supply] then
                self:_invoke(plotId, "BuySupply", supply)
                task.wait(0.20)
            end
        end

        for slot = 1, 4 do
            if not self.running then break end
            if self.selectedSlots[slot] then
                self:_invoke(plotId, "BuyTraveling", slot)
                task.wait(0.20)
            end
        end

        task.wait(5)
    end
end

function AutoBuy:start(plotId)
    if self.running then return end
    self.running = true
    self.onStatus("Auto-Buy ligado")
    task.spawn(function()
        self:_loop(plotId)
        if not self.running then
            self.onStatus("Auto-Buy desligado")
        end
    end)
end

function AutoBuy:stop()
    self.running = false
end

return AutoBuy
