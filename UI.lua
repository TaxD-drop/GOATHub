-- ModuleScript: GOATHubGUI.UI
-- Componentes reutilizáveis: janela, botão, checkbox e seletor múltiplo.

local UserInputService = game:GetService("UserInputService")
local UI = {}

local COLORS = {
    panel = Color3.fromRGB(25, 25, 29),
    card = Color3.fromRGB(42, 42, 48),
    option = Color3.fromRGB(35, 35, 40),
    text = Color3.fromRGB(235, 235, 238),
    muted = Color3.fromRGB(175, 175, 182),
    accent = Color3.fromRGB(72, 135, 235),
    green = Color3.fromRGB(43, 145, 78),
    red = Color3.fromRGB(185, 61, 61),
}

local function corner(instance, radius)
    local value = Instance.new("UICorner")
    value.CornerRadius = UDim.new(0, radius or 6)
    value.Parent = instance
end

local function stroke(instance, color, thickness)
    local value = Instance.new("UIStroke")
    value.Color = color
    value.Thickness = thickness or 1
    value.Parent = instance
end

local function label(parent, text, height)
    local value = Instance.new("TextLabel")
    value.Size = UDim2.new(1, 0, 0, height or 20)
    value.BackgroundTransparency = 1
    value.Text = text
    value.TextColor3 = COLORS.muted
    value.Font = Enum.Font.GothamBold
    value.TextSize = 12
    value.TextXAlignment = Enum.TextXAlignment.Left
    value.Parent = parent
    return value
end

function UI.new(title)
    local player = game:GetService("Players").LocalPlayer
    local old = player.PlayerGui:FindFirstChild("GOATHub")
    if old then old:Destroy() end

    local gui = Instance.new("ScreenGui")
    gui.Name = "GOATHub"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = player:WaitForChild("PlayerGui")

    local frame = Instance.new("Frame")
    frame.Name = "Window"
    frame.Size = UDim2.new(0, 300, 0, 490)
    frame.Position = UDim2.new(0, 24, 0.5, -245)
    frame.BackgroundColor3 = COLORS.panel
    frame.Parent = gui
    corner(frame, 9)
    stroke(frame, Color3.fromRGB(100, 100, 110), 2)

    local topBar = Instance.new("TextButton")
    topBar.Name = "DragHandle"
    topBar.Size = UDim2.new(1, 0, 0, 38)
    topBar.BackgroundColor3 = Color3.fromRGB(50, 50, 58)
    topBar.Text = "  " .. (title or "GOAT Hub")
    topBar.TextColor3 = COLORS.text
    topBar.Font = Enum.Font.GothamBold
    topBar.TextSize = 15
    topBar.TextXAlignment = Enum.TextXAlignment.Left
    topBar.Parent = frame
    corner(topBar, 9)

    local content = Instance.new("ScrollingFrame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -14, 1, -52)
    content.Position = UDim2.new(0, 7, 0, 45)
    content.BackgroundTransparency = 1
    content.BorderSizePixel = 0
    content.ScrollBarThickness = 4
    content.ScrollBarImageColor3 = COLORS.accent
    content.CanvasSize = UDim2.new()
    content.AutomaticCanvasSize = Enum.AutomaticSize.Y
    content.Parent = frame

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 7)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = content

    local dragging, dragStart, startPosition, dragInput
    topBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging, dragStart, startPosition = true, input.Position, frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    topBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X,
                startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
        end
    end)

    return { gui = gui, frame = frame, content = content, colors = COLORS }
end

function UI.section(parent, text)
    return label(parent, text, 18)
end

function UI.button(parent, text, color, height)
    local value = Instance.new("TextButton")
    value.Size = UDim2.new(1, 0, 0, height or 36)
    value.BackgroundColor3 = color or COLORS.card
    value.Text = text
    value.TextColor3 = COLORS.text
    value.Font = Enum.Font.GothamBold
    value.TextSize = 13
    value.Parent = parent
    corner(value, 6)
    return value
end

function UI.checkbox(parent, text, initial, callback)
    local row = UI.button(parent, "", COLORS.card, 34)
    local box = Instance.new("TextLabel")
    box.Size = UDim2.new(0, 18, 0, 18)
    box.Position = UDim2.new(0, 10, 0.5, -9)
    box.BackgroundColor3 = COLORS.panel
    box.TextColor3 = COLORS.text
    box.Font = Enum.Font.GothamBold
    box.TextSize = 15
    box.Parent = row
    corner(box, 3)
    stroke(box, Color3.fromRGB(190, 190, 198), 2)

    local textLabel = label(row, text, 34)
    textLabel.Position = UDim2.new(0, 38, 0, 0)
    textLabel.Size = UDim2.new(1, -46, 1, 0)
    textLabel.TextColor3 = COLORS.text

    local checked = initial == true
    local function render()
        box.Text = checked and "✓" or ""
        box.BackgroundColor3 = checked and COLORS.green or COLORS.panel
    end
    render()
    row.MouseButton1Click:Connect(function()
        checked = not checked
        render()
        callback(checked)
    end)
    return row
end

function UI.dropdown(parent, name, options, selected)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1, 0, 0, 36)
    holder.BackgroundTransparency = 1
    holder.ClipsDescendants = true
    holder.Parent = parent

    local trigger = UI.button(holder, "", COLORS.card, 34)
    trigger.TextXAlignment = Enum.TextXAlignment.Left
    local optionsFrame = Instance.new("ScrollingFrame")
    optionsFrame.Position = UDim2.new(0, 0, 0, 39)
    optionsFrame.Size = UDim2.new(1, 0, 0, 0)
    optionsFrame.BackgroundColor3 = COLORS.option
    optionsFrame.BorderSizePixel = 0
    optionsFrame.CanvasSize = UDim2.new()
    optionsFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    optionsFrame.ScrollBarThickness = 4
    optionsFrame.ScrollBarImageColor3 = COLORS.accent
    optionsFrame.Visible = false
    optionsFrame.Parent = holder
    corner(optionsFrame, 6)
    stroke(optionsFrame, Color3.fromRGB(80, 80, 88), 1)

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 4)
    padding.PaddingBottom = UDim.new(0, 4)
    padding.PaddingLeft = UDim.new(0, 4)
    padding.PaddingRight = UDim.new(0, 4)
    padding.Parent = optionsFrame
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 3)
    layout.Parent = optionsFrame

    local open = false
    local function countSelected()
        local count = 0
        for _, item in ipairs(options) do if selected[item] then count += 1 end end
        return count
    end
    local function refreshTitle()
        local count = countSelected()
        trigger.Text = string.format("  %s%s  %s", name, count > 0 and " (" .. count .. ")" or "", open and "▲" or "▼")
    end
    local function setOpen(value)
        open = value
        local listHeight = math.min(#options * 33 + 8, 173)
        holder.Size = UDim2.new(1, 0, 0, open and (39 + listHeight) or 36)
        optionsFrame.Size = UDim2.new(1, 0, 0, listHeight)
        optionsFrame.Visible = open
        refreshTitle()
    end

    for index, item in ipairs(options) do
        local option = UI.checkbox(optionsFrame, tostring(item), selected[item] == true, function(checked)
            selected[item] = checked or nil
            refreshTitle()
        end)
        option.Size = UDim2.new(1, 0, 0, 30)
        option.LayoutOrder = index
    end
    trigger.MouseButton1Click:Connect(function() setOpen(not open) end)
    refreshTitle()
    return holder
end

return UI
