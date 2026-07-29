-- ModuleScript: GOATHubBuild.AutoRequests
-- Fluxos reproduzidos de RequestRecievedScript.localscript.lua.

local AutoRequests = {}
AutoRequests.__index = AutoRequests

function AutoRequests.new(teamRequestRemote, approvePlayerRemote, shareRemote, onStatus)
    return setmetatable({
        teamRequestRemote = teamRequestRemote,
        approvePlayerRemote = approvePlayerRemote,
        shareRemote = shareRemote,
        onStatus = onStatus or function() end,
        teamEnabled = false,
        shareEnabled = false,
        teamConnection = nil,
        originalShareCallback = nil,
        shareCallback = nil,
    }, AutoRequests)
end

function AutoRequests:setTeamEnabled(enabled)
    if self.teamEnabled == enabled then
        return
    end
    self.teamEnabled = enabled

    if enabled then
        self.teamConnection = self.teamRequestRemote.OnClientEvent:Connect(function(player)
            if not self.teamEnabled then return end
            local ok = pcall(function()
                self.approvePlayerRemote:FireServer(player)
            end)
            self.onStatus(ok and ("Pedido de equipe aceito: " .. player.DisplayName)
                or "Falha ao aceitar pedido de equipe")
        end)
        self.onStatus("Auto aceitar pedidos de equipe ligado")
    else
        if self.teamConnection then
            self.teamConnection:Disconnect()
            self.teamConnection = nil
        end
        self.onStatus("Auto aceitar pedidos de equipe desligado")
    end
end

function AutoRequests:setShareEnabled(enabled)
    if self.shareEnabled == enabled then
        return
    end
    self.shareEnabled = enabled

    if enabled then
        self.originalShareCallback = self.shareRemote.OnClientInvoke
        self.shareCallback = function(player)
            self.onStatus("Edição de blocos aceita: " .. player.DisplayName)
            return true
        end
        self.shareRemote.OnClientInvoke = self.shareCallback
        self.onStatus("Auto aceitar edição de blocos ligado")
    else
        if self.shareRemote.OnClientInvoke == self.shareCallback then
            self.shareRemote.OnClientInvoke = self.originalShareCallback
        end
        self.originalShareCallback = nil
        self.shareCallback = nil
        self.onStatus("Auto aceitar edição de blocos desligado")
    end
end

function AutoRequests:stop()
    if self.teamEnabled then
        self:setTeamEnabled(false)
    end
    if self.shareEnabled then
        self:setShareEnabled(false)
    end
end

return AutoRequests
