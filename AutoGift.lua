-- ModuleScript: GOATHub.AutoGift
-- O log mostra que o jogo resgata um gift por:
-- ReplicatedStorage.Network["Redeem Free Gift"]:InvokeServer(indice)

local AutoGift = {}
AutoGift.__index = AutoGift

-- Altere este número apenas se o jogo passar a ter mais presentes gratuitos.
AutoGift.GIFT_COUNT = 12
AutoGift.CHECK_INTERVAL = 15

function AutoGift.new(redeemRemote, claimedRemote, onStatus)
    local self = setmetatable({
        remote = redeemRemote,
        onStatus = onStatus or function() end,
        enabled = false,
        checking = false,
        claimedCount = 0,
    }, AutoGift)

    -- A confirmação presente no log é emitida somente depois que o servidor
    -- aceita a coleta. Ela é a confirmação de que havia um gift pronto.
    claimedRemote.OnClientEvent:Connect(function()
        if self.enabled then
            self.claimedCount += 1
            self.onStatus("Gift pronto coletado (" .. self.claimedCount .. ")")
        end
    end)
    return self
end

function AutoGift:_tryRedeem(giftIndex)
    -- O próprio servidor só aceita o índice cujo tempo já terminou. Assim não
    -- dependemos de timer local nem resgatamos um gift antes da hora.
    return pcall(function()
        self.remote:InvokeServer(giftIndex)
    end)
end

function AutoGift:_loop()
    while self.enabled do
        self.checking = true
        self.onStatus("Verificando gifts prontos...")

        for giftIndex = 1, AutoGift.GIFT_COUNT do
            if not self.enabled then break end
            self:_tryRedeem(giftIndex)
            task.wait(0.25)
        end

        self.checking = false
        if self.enabled then
            self.onStatus("Auto Collect Gift ligado")
        end

        local waited = 0
        while self.enabled and waited < AutoGift.CHECK_INTERVAL do
            task.wait(1)
            waited += 1
        end
    end
    self.checking = false
end

function AutoGift:setEnabled(enabled)
    if enabled == self.enabled then return end
    self.enabled = enabled
    if enabled then
        self.onStatus("Auto Collect Gift ligado")
        task.spawn(function()
            self:_loop()
        end)
    else
        self.onStatus("Auto Collect Gift desligado")
    end
end

function AutoGift:stop()
    self.enabled = false
end

return AutoGift
