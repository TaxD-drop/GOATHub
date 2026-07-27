-- LocalScript: coloque este script e os três ModuleScripts na pasta GOATHub.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/TaxD-drop/GOATHub/refs/heads/main/UI.lua"))()
local AutoBuy = loadstring(game:HttpGet("https://raw.githubusercontent.com/TaxD-drop/GOATHub/refs/heads/main/AutoBuy.lua"))()
local AutoGift = loadstring(game:HttpGet("https://raw.githubusercontent.com/TaxD-drop/GOATHub/refs/heads/main/AutoGift.lua"))()

local player = game:GetService("Players").LocalPlayer
local network = ReplicatedStorage:WaitForChild("Network")
local plotsInvoke = network:WaitForChild("Plots_Invoke")
local redeemGift = network:WaitForChild("Redeem Free Gift")
local giftClaimed = network:WaitForChild("Free Gift: Claimed")
local ClientPlot = require(ReplicatedStorage.Library.Client.PlotCmds.ClientPlot)

local function getLocalPlotId()
    local ok, plot = pcall(ClientPlot.GetLocal)
    return ok and plot and plot:GetId() or nil
end

local window = UI.new("GOAT Hub")
local content = window.content
local layoutOrder = 0
local function contentItem(instance)
    layoutOrder += 1
    instance.LayoutOrder = layoutOrder
    return instance
end

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, 0, 0, 18)
status.BackgroundTransparency = 1
status.Text = "Pronto"
status.TextColor3 = window.colors.muted
status.Font = Enum.Font.Gotham
status.TextSize = 11
status.TextXAlignment = Enum.TextXAlignment.Left
status.Parent = content
contentItem(status)

local function setStatus(text)
    status.Text = text
end

local autoBuy = AutoBuy.new(plotsInvoke, setStatus)
local autoGift = AutoGift.new(redeemGift, giftClaimed, setStatus)

contentItem(UI.section(content, "AUTOMAÇÃO"))
contentItem(UI.checkbox(content, "Auto Collect Gift", false, function(enabled)
    autoGift:setEnabled(enabled)
end))

contentItem(UI.section(content, "PLOT ID"))
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
    if id then
        idBox.Text = tostring(id)
        setStatus("Plot detectado")
    else
        setStatus("Não foi possível detectar o plot")
    end
end)

contentItem(UI.section(content, "SELETORES"))
contentItem(UI.dropdown(content, "Eggs", AutoBuy.EGGS, autoBuy.selectedEggs))
contentItem(UI.dropdown(content, "Suprimentos", AutoBuy.SUPPLIES, autoBuy.selectedSupplies))
contentItem(UI.dropdown(content, "Traveling Merchant", { 1, 2, 3, 4 }, autoBuy.selectedSlots))

local buyButton = UI.button(content, "Auto-Buy: OFF", window.colors.red, 42)
contentItem(buyButton)
buyButton.MouseButton1Click:Connect(function()
    if autoBuy.running then
        autoBuy:stop()
        buyButton.Text = "Auto-Buy: OFF"
        buyButton.BackgroundColor3 = window.colors.red
        idBox.TextEditable = true
        return
    end

    local plotId = tonumber(idBox.Text)
    if not plotId then
        setStatus("Digite ou detecte o Plot ID")
        return
    end
    autoBuy:start(plotId)
    buyButton.Text = "Auto-Buy: ON"
    buyButton.BackgroundColor3 = window.colors.green
    idBox.TextEditable = false
end)

local closeButton = UI.button(content, "Fechar GOAT Hub", window.colors.card, 34)
contentItem(closeButton)
closeButton.MouseButton1Click:Connect(function()
    autoBuy:stop()
    autoGift:stop()
    window.gui:Destroy()
end)

local localPlotId = getLocalPlotId()
if localPlotId then idBox.Text = tostring(localPlotId) end
