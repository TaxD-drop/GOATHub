-- ModuleScript: GOATHubBuild.InventoryMonitor
-- Observa os Values replicados em LocalPlayer.Data, que são a fonte usada pelo
-- cliente oficial para detectar itens/Gold realmente alterados.

local InventoryMonitor = {}
InventoryMonitor.__index = InventoryMonitor

local function numericValue(instance)
    if not instance:IsA("ValueBase") then
        return nil
    end

    local value = instance.Value
    if typeof(value) == "number" then
        return value
    end
    return nil
end

function InventoryMonitor.new(dataFolder, onStatus, onChanged)
    return setmetatable({
        data = dataFolder,
        onStatus = onStatus or function() end,
        onChanged = onChanged or function() end,
        enabled = false,
        values = {},
        connections = {},
    }, InventoryMonitor)
end

function InventoryMonitor:_watch(instance)
    local initial = numericValue(instance)
    if initial == nil then
        return
    end

    self.values[instance.Name] = initial
    table.insert(self.connections, instance:GetPropertyChangedSignal("Value"):Connect(function()
        if not self.enabled then
            return
        end

        local current = numericValue(instance)
        if current == nil then
            return
        end

        local previous = self.values[instance.Name] or current
        self.values[instance.Name] = current
        local delta = current - previous
        if delta ~= 0 then
            self.onChanged(instance.Name, delta, current)
        end
    end))
end

function InventoryMonitor:start()
    if self.enabled then
        return
    end

    self.enabled = true
    table.clear(self.values)
    for _, instance in ipairs(self.data:GetChildren()) do
        self:_watch(instance)
    end
    table.insert(self.connections, self.data.ChildAdded:Connect(function(instance)
        if self.enabled then
            self:_watch(instance)
        end
    end))
    self.onStatus("Monitor do inventário do servidor ligado")
end

function InventoryMonitor:getValue(name)
    local instance = self.data:FindFirstChild(name)
    return instance and numericValue(instance) or nil
end

function InventoryMonitor:getSummary(limit)
    local entries = {}
    for name, value in pairs(self.values) do
        if value ~= 0 then
            table.insert(entries, { name = name, value = value })
        end
    end
    table.sort(entries, function(a, b)
        if a.name == "Gold" then return true end
        if b.name == "Gold" then return false end
        return a.name < b.name
    end)

    local parts = {}
    for index = 1, math.min(limit or 5, #entries) do
        local entry = entries[index]
        table.insert(parts, entry.name .. ": " .. tostring(entry.value))
    end
    return #parts > 0 and table.concat(parts, " | ") or "Inventário ainda não replicado"
end

function InventoryMonitor:stop()
    self.enabled = false
    for _, connection in ipairs(self.connections) do
        connection:Disconnect()
    end
    table.clear(self.connections)
end

return InventoryMonitor
