-- LocalScript: GOATHub.Main
-- A verificação é feita antes de carregar módulos ou criar a interface.

local EXPECTED_GAME_ID = 3317771874
if game.GameId ~= EXPECTED_GAME_ID then
    return
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HUB_URL = "https://raw.githubusercontent.com/TaxD-drop/GOATHub/refs/heads/main/"

-- Os módulos do hub são carregados do GitHub porque o Main é executado via
-- loadstring. Os require abaixo para ReplicatedStorage continuam sendo apenas
-- módulos internos do próprio jogo.
local function loadHubModule(fileName)
    return loadstring(game:HttpGet(HUB_URL .. fileName))()
end

local Config = loadHubModule("Config.lua")
local UI = loadHubModule("UI.lua")
local AutoGift = loadHubModule("AutoGift.lua")

local player = game:GetService("Players").LocalPlayer
local placeId = game.PlaceId
local network = ReplicatedStorage:WaitForChild("Network")

local window = UI.new("GOAT Hub")
local content = window.content
local layoutOrder = 0
local controllers = {}

local function contentItem(instance)
    layoutOrder += 1
    instance.LayoutOrder = layoutOrder
    return instance
end

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, 0, 0, 18)
status.BackgroundTransparency = 1
status.Text = "Place ID: " .. placeId
status.TextColor3 = window.colors.muted
status.Font = Enum.Font.Gotham
status.TextSize = 11
status.TextXAlignment = Enum.TextXAlignment.Left
status.Parent = content
contentItem(status)

local function setStatus(text)
    status.Text = text
end

local function addGiftControls()
    local redeemGift = network:WaitForChild("Redeem Free Gift")
    local giftClaimed = network:WaitForChild("Free Gift: Claimed")

    local autoGift = AutoGift.new(redeemGift, giftClaimed, setStatus)
    table.insert(controllers, autoGift)
    contentItem(UI.section(content, "AUTOMAÇÃO GLOBAL"))
    contentItem(UI.checkbox(content, "Auto Collect Gift", false, function(enabled)
        autoGift:setEnabled(enabled)
    end))
end

local function addAutoBuyControls()
    local AutoBuy = loadHubModule("AutoBuy.lua")
    local plotsInvoke = network:WaitForChild("Plots_Invoke")
    local ClientPlot = require(ReplicatedStorage.Library.Client.PlotCmds.ClientPlot)
    local autoBuy = AutoBuy.new(plotsInvoke, setStatus)
    table.insert(controllers, autoBuy)

    local function getLocalPlotId()
        local ok, plot = pcall(ClientPlot.GetLocal)
        return ok and plot and plot:GetId() or nil
    end

    contentItem(UI.section(content, "AUTO-BUY — PLACE ATUAL"))
    local idRow = Instance.new("Frame")
    idRow.Size = UDim2.new(1, 0, 0, 36)
    idRow.BackgroundTransparency = 1
    idRow.Parent = content
    contentItem(idRow)

    local idBox = Instance.new("TextBox")
    idBox.Size = UDim2.new(0.65, -4, 1, 0)
    idBox.BackgroundColor3 = window.colors.card
    idBox.PlaceholderText = "ID do seu plot"
    idBox.Text = ""
    idBox.TextColor3 = window.colors.text
    idBox.PlaceholderColor3 = window.colors.muted
    idBox.Font = Enum.Font.GothamBold
    idBox.TextSize = 13
    idBox.ClearTextOnFocus = false
    idBox.Parent = idRow
    Instance.new("UICorner", idBox).CornerRadius = UDim.new(0, 6)
    idBox:GetPropertyChangedSignal("Text"):Connect(function()
        idBox.Text = idBox.Text:gsub("%D", "")
    end)

    local detect = UI.button(idRow, "Detectar", window.colors.accent, 36)
    detect.Size = UDim2.new(0.35, -4, 1, 0)
    detect.Position = UDim2.new(0.65, 4, 0, 0)
    detect.MouseButton1Click:Connect(function()
        local id = getLocalPlotId()
        if id then idBox.Text = tostring(id); setStatus("Plot detectado") else setStatus("Plot não encontrado") end
    end)

    contentItem(UI.dropdown(content, "Eggs", AutoBuy.EGGS, autoBuy.selectedEggs))
    contentItem(UI.dropdown(content, "Suprimentos", AutoBuy.SUPPLIES, autoBuy.selectedSupplies))
    contentItem(UI.dropdown(content, "Traveling Merchant", { 1, 2, 3, 4 }, autoBuy.selectedSlots))

    local buyButton = UI.button(content, "Auto-Buy: OFF", window.colors.red, 42)
    contentItem(buyButton)
    buyButton.MouseButton1Click:Connect(function()
        if autoBuy.running then
            autoBuy:stop()
            buyButton.Text, buyButton.BackgroundColor3, idBox.TextEditable = "Auto-Buy: OFF", window.colors.red, true
            return
        end
        local plotId = tonumber(idBox.Text)
        if not plotId then setStatus("Digite ou detecte o Plot ID"); return end
        autoBuy:start(plotId)
        buyButton.Text, buyButton.BackgroundColor3, idBox.TextEditable = "Auto-Buy: ON", window.colors.green, false
    end)

    local localPlotId = getLocalPlotId()
    if localPlotId then idBox.Text = tostring(localPlotId) end
end

local function addFarmingControls()
    local AutoOrbs = loadHubModule("AutoOrbs.lua")
    local AutoBreakables = loadHubModule("AutoBreakables.lua")
    local autoOrbs = AutoOrbs.new(network:WaitForChild("Orbs: Collect"), setStatus)
    local autoBreakables = AutoBreakables.new(network:WaitForChild("Breakables_PlayerDealDamage"), setStatus)
    table.insert(controllers, autoOrbs)
    table.insert(controllers, autoBreakables)

    contentItem(UI.section(content, "FARMING — PLACE ATUAL"))
    contentItem(UI.checkbox(content, "Auto coletar Orbs / Moedas", false, function(enabled)
        if enabled then autoOrbs:start() else autoOrbs:stop() end
    end))
    contentItem(UI.checkbox(content, "Auto Quebrar Items", false, function(enabled)
        if enabled then autoBreakables:start() else autoBreakables:stop() end
    end))

end

-- Gift aparece em qualquer place deste jogo. Os demais recursos só existem
-- nos places em que os respectivos remotes e sistemas foram identificados.
addGiftControls()
if placeId == Config.PLACES.AUTO_BUY then
    addAutoBuyControls()
elseif placeId == Config.PLACES.FARMING then
    addFarmingControls()
else
    contentItem(UI.section(content, "Este place possui somente recursos globais."))
end

local closeButton = UI.button(content, "Fechar GOAT Hub", window.colors.card, 34)
contentItem(closeButton)
closeButton.MouseButton1Click:Connect(function()
    for _, controller in ipairs(controllers) do
        if controller.stop then controller:stop() end
    end
    window.gui:Destroy()
end)
