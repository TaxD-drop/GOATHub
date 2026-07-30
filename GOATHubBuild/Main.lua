-- LocalScript: GOATHubBuild.Main
-- Hub separado para o jogo BuildBoat analisado. Config e place são validados
-- antes de criar interface, carregar features ou acessar remotes do jogo.

local HUB_URL = "https://raw.githubusercontent.com/TaxD-drop/GOATHub/refs/heads/main/"

local function loadFile(path)
    return loadstring(game:HttpGet(HUB_URL .. path))()
end

local Config = loadFile("GOATHubBuild/Config.lua")

local function validConfiguredId(value)
    return typeof(value) == "number" and value > 0 and value % 1 == 0
end

if not validConfiguredId(Config.GAME_ID) then
    warn("[GOATHubBuild] Preencha GAME_ID em GOATHubBuild/Config.lua")
    return
end
if game.GameId ~= Config.GAME_ID then
    return
end
if not validConfiguredId(Config.PLACES.MAIN) then
    warn("[GOATHubBuild] Preencha PLACES.MAIN em GOATHubBuild/Config.lua")
    return
end
if game.PlaceId ~= Config.PLACES.MAIN then
    return
end

local UI = loadFile("GOATHubGUI/UI.lua")
local AutoDupe = loadFile("GOATHubBuild/AutoDupe.lua")
local InventoryMonitor = loadFile("GOATHubBuild/InventoryMonitor.lua")
local AutoRequests = loadFile("GOATHubBuild/AutoRequests.lua")

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local controllers = {}
local window = UI.new("GOAT Hub — BuildBoat")
local content = window.content
local layoutOrder = 0

local function contentItem(instance)
    layoutOrder += 1
    instance.LayoutOrder = layoutOrder
    return instance
end

local status = contentItem(UI.section(content, "Carregando dados do servidor..."))
status.TextColor3 = window.colors.text
status.TextWrapped = true
status.Size = UDim2.new(1, 0, 0, 34)

local function setStatus(text)
    status.Text = tostring(text)
end

local data = player:WaitForChild(Config.DATA_FOLDER, 15)
if not data then
    setStatus("Pasta LocalPlayer." .. Config.DATA_FOLDER .. " não encontrada")
end

local saveFlag = player:FindFirstChild(Config.SAVE_FLAG)
if saveFlag and not saveFlag.Value then
    local deadline = os.clock() + 15
    while not saveFlag.Value and os.clock() < deadline do
        task.wait(0.25)
    end
end

contentItem(UI.section(content, "INVENTÁRIO AUTORITATIVO"))
local inventoryLabel = contentItem(UI.section(content, "Aguardando LocalPlayer.Data"))
inventoryLabel.TextWrapped = true
inventoryLabel.Size = UDim2.new(1, 0, 0, 38)

local inventoryMonitor
if data then
    inventoryMonitor = InventoryMonitor.new(data, setStatus, function(name, delta, current)
        local sign = delta > 0 and "+" or ""
        setStatus(string.format("Data mudou: %s %s%s (total %s)", name, sign, delta, current))
        inventoryLabel.Text = inventoryMonitor:getSummary(6)
    end)
    table.insert(controllers, inventoryMonitor)
    inventoryMonitor:start()
    inventoryLabel.Text = inventoryMonitor:getSummary(6)
end

local refreshInventory = contentItem(UI.button(content, "Atualizar inventário", window.colors.card, 34))
refreshInventory.MouseButton1Click:Connect(function()
    if inventoryMonitor then
        inventoryLabel.Text = inventoryMonitor:getSummary(6)
        setStatus("Inventário lido de LocalPlayer.Data")
    else
        setStatus("Inventário do servidor indisponível")
    end
end)

contentItem(UI.section(content, "AUTODUPE — TESTE EXPERIMENTAL"))
local dupeInfo = contentItem(UI.section(content,
    "Common Chest × 0.1; máximo 6 tentativas. Só Data conta como ganho."))
dupeInfo.TextWrapped = true
dupeInfo.Size = UDim2.new(1, 0, 0, 36)

local itemBoughtRemote = workspace:WaitForChild(Config.REMOTES.ITEM_BOUGHT_FROM_SHOP, 10)
local autoDupe
local dupeButton

local function renderDupeButton(enabled)
    if not dupeButton then return end
    dupeButton.Text = enabled and "Parar AutoDupe" or "Testar AutoDupe 0.1"
    dupeButton.BackgroundColor3 = enabled and window.colors.green or window.colors.red
end

if data and itemBoughtRemote and itemBoughtRemote:IsA("RemoteFunction") then
    autoDupe = AutoDupe.new(itemBoughtRemote, data, Config.AUTODUPE, setStatus, renderDupeButton)
    table.insert(controllers, autoDupe)
    dupeButton = contentItem(UI.button(content, "Testar AutoDupe 0.1", window.colors.red, 42))
    dupeButton.MouseButton1Click:Connect(function()
        autoDupe:setEnabled(not autoDupe.enabled)
    end)
else
    dupeButton = contentItem(UI.button(content, "AutoDupe indisponível", window.colors.card, 42))
    dupeButton.AutoButtonColor = false
    dupeButton.MouseButton1Click:Connect(function()
        setStatus("ItemBoughtFromShop ou LocalPlayer.Data não encontrado")
    end)
end

local changeTeam = workspace:FindFirstChild(Config.REMOTES.CHANGE_TEAM)
local shareRemote = workspace:FindFirstChild(Config.REMOTES.SHARE_REQUEST)
if changeTeam and shareRemote and shareRemote:IsA("RemoteFunction") then
    local teamRequest = changeTeam:FindFirstChild(Config.REMOTES.CHANGE_TEAM_REQUEST)
    local approvePlayer = changeTeam:FindFirstChild(Config.REMOTES.APPROVE_PLAYER)
    if teamRequest and approvePlayer then
        local autoRequests = AutoRequests.new(teamRequest, approvePlayer, shareRemote, setStatus)
        table.insert(controllers, autoRequests)

        contentItem(UI.section(content, "PEDIDOS"))
        contentItem(UI.checkbox(content, "Auto aceitar entrada na equipe", false, function(enabled)
            autoRequests:setTeamEnabled(enabled)
        end))
        contentItem(UI.checkbox(content, "Auto permitir edição de blocos", false, function(enabled)
            autoRequests:setShareEnabled(enabled)
        end))
    end
end

local closeButton = contentItem(UI.button(content, "Fechar GOAT Hub Build", window.colors.card, 34))
closeButton.MouseButton1Click:Connect(function()
    for _, controller in ipairs(controllers) do
        if controller.stop then
            controller:stop()
        end
    end
    window.gui:Destroy()
end)

setStatus("GOAT Hub Build carregado — Place ID: " .. game.PlaceId)
