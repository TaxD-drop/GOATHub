-- ModuleScript: GOATHubBuild.AutoDupe
-- Teste experimental do único argumento sem custo observado no log.
-- Não dispara o BindableEvent visual: só considera sucesso quando um Value de
-- LocalPlayer.Data aumenta sem redução de Gold.

local AutoDupe = {}
AutoDupe.__index = AutoDupe

local function snapshot(dataFolder)
    local result = {}
    for _, instance in ipairs(dataFolder:GetChildren()) do
        if instance:IsA("ValueBase") and typeof(instance.Value) == "number" then
            result[instance.Name] = instance.Value
        end
    end
    return result
end

local function findPositiveGains(before, after)
    local gains = {}
    for name, value in pairs(after) do
        if name ~= "Gold" then
            local delta = value - (before[name] or 0)
            if delta > 0 then
                table.insert(gains, name .. " +" .. tostring(delta))
            end
        end
    end
    table.sort(gains)
    return gains
end

function AutoDupe.new(remote, dataFolder, settings, onStatus, onStateChanged)
    return setmetatable({
        remote = remote,
        data = dataFolder,
        settings = settings,
        onStatus = onStatus or function() end,
        onStateChanged = onStateChanged or function() end,
        enabled = false,
        attempts = 0,
    }, AutoDupe)
end

function AutoDupe:_finish(message)
    self.enabled = false
    self.onStatus(message)
    self.onStateChanged(false)
end

function AutoDupe:_attempt()
    local before = snapshot(self.data)
    local ok, packedOrError = pcall(function()
        return table.pack(self.remote:InvokeServer(
            self.settings.CHEST_NAME,
            self.settings.PROBE_QUANTITY
        ))
    end)

    task.wait(self.settings.SETTLE_TIME)
    local after = snapshot(self.data)
    local goldBefore = before.Gold
    local goldAfter = after.Gold
    local goldDelta = if goldBefore ~= nil and goldAfter ~= nil then goldAfter - goldBefore else nil
    local gains = findPositiveGains(before, after)
    local accepted = ok and packedOrError.n > 0 and packedOrError[1] == true

    return {
        ok = ok,
        errorMessage = ok and nil or tostring(packedOrError),
        accepted = accepted,
        goldDelta = goldDelta,
        gains = gains,
    }
end

function AutoDupe:_loop()
    for attempt = 1, self.settings.MAX_ATTEMPTS do
        if not self.enabled then
            return
        end

        self.attempts = attempt
        self.onStatus(string.format("AutoDupe: teste %d/%d...", attempt, self.settings.MAX_ATTEMPTS))
        local outcome = self:_attempt()

        if not self.enabled then
            return
        end
        if outcome.goldDelta and outcome.goldDelta < 0 then
            self:_finish("SEGURANÇA: Gold diminuiu " .. tostring(outcome.goldDelta) .. "; AutoDupe parado")
            return
        end
        if #outcome.gains > 0 then
            local prefix = outcome.accepted and "Possível dupe confirmado em Data: " or "Mudança concorrente em Data: "
            self:_finish(prefix .. table.concat(outcome.gains, ", "))
            return
        end
        if not outcome.ok then
            self.onStatus("AutoDupe: erro no remote; tentando novamente")
        elseif outcome.accepted then
            self.onStatus("Servidor respondeu true, mas nenhum item aumentou")
        else
            self.onStatus("Servidor rejeitou 0.1; nenhum item real foi ganho")
        end

        local elapsed = 0
        while self.enabled and elapsed < self.settings.INTERVAL do
            task.wait(0.1)
            elapsed += 0.1
        end
    end

    if self.enabled then
        self:_finish(string.format("AutoDupe sem efeito: %d/%d tentativas não alteraram Data",
            self.settings.MAX_ATTEMPTS, self.settings.MAX_ATTEMPTS))
    end
end

function AutoDupe:setEnabled(enabled)
    if self.enabled == enabled then
        return
    end

    self.enabled = enabled
    self.onStateChanged(enabled)
    if enabled then
        self.attempts = 0
        self.onStatus("AutoDupe experimental iniciado; monitorando Data e Gold")
        task.spawn(function()
            self:_loop()
        end)
    else
        self.onStatus("AutoDupe experimental interrompido")
    end
end

function AutoDupe:stop()
    if self.enabled then
        self.enabled = false
        self.onStateChanged(false)
    end
end

return AutoDupe
