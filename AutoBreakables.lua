-- ModuleScript: GOATHub.AutoBreakables
-- O servidor recebe Breakables_PlayerDealDamage com o UID do breakable.

local AutoBreakables = {}
AutoBreakables.__index = AutoBreakables

-- Além do dano direto no alvo principal, os pets são distribuídos pelos
-- breakables próximos. Isso reproduz o fluxo PlayerPet -> CQ_Route ->
-- Breakables_JoinPetBulk e permite quebrar vários em paralelo.
local HIT_INTERVAL = 0.06
local TARGET_LIMIT = 12

function AutoBreakables.new(damageRemote, onStatus)
    local playerPet
    pcall(function()
        playerPet = require(game:GetService("ReplicatedStorage").Library.Client.PlayerPet)
    end)
    return setmetatable({
        remote = damageRemote,
        onStatus = onStatus or function() end,
        running = false,
        playerPet = playerPet,
        petTargets = {},
    }, AutoBreakables)
end

function AutoBreakables:_getTargets()
    local things = workspace:FindFirstChild("__THINGS")
    local folder = things and things:FindFirstChild("Breakables")
    local character = game:GetService("Players").LocalPlayer.Character
    local root = character and character.PrimaryPart
    if not (folder and root) then return {} end

    local targets = {}
    for _, breakable in ipairs(folder:GetChildren()) do
        local ok, pivot = pcall(function() return breakable:GetPivot() end)
        if ok then
            local distance = (pivot.Position - root.Position).Magnitude
            if distance <= 240 and not breakable:GetAttribute("DisableDamage") then
                table.insert(targets, {
                    id = breakable.Name,
                    model = breakable,
                    distance = distance,
                })
            end
        end
    end
    table.sort(targets, function(left, right) return left.distance < right.distance end)
    while #targets > TARGET_LIMIT do table.remove(targets) end
    return targets
end

function AutoBreakables:_assignPets(targets)
    if not self.playerPet or #targets == 0 then return 0 end
    local assigned, index = 0, 1
    for _, pet in pairs(self.playerPet.GetByPlayer(game:GetService("Players").LocalPlayer)) do
        local target = targets[index]
        if not target then break end
        if self.petTargets[pet.euid] ~= target.id then
            pcall(function() pet:SetTarget(target.model) end)
            self.petTargets[pet.euid] = target.id
        end
        assigned += 1
        index = index % #targets + 1
    end
    return assigned
end

function AutoBreakables:start()
    if self.running then return end
    self.running = true
    task.spawn(function()
        while self.running do
            local targets = self:_getTargets()
            if #targets == 0 then
                self.onStatus("Nenhum item quebrável nesta área")
                task.wait(0.5)
            else
                local pets = self:_assignPets(targets)
                -- Dano rápido no alvo mais próximo enquanto os pets trabalham
                -- nos demais alvos em paralelo.
                self.remote:FireServer(targets[1].id)
                self.onStatus("Quebrando " .. #targets .. " itens" .. (pets > 0 and " com " .. pets .. " pets" or ""))
                task.wait(HIT_INTERVAL)
            end
        end
    end)
end

function AutoBreakables:stop()
    self.running = false
    if self.playerPet then
        for _, pet in pairs(self.playerPet.GetByPlayer(game:GetService("Players").LocalPlayer)) do
            if self.petTargets[pet.euid] then
                pcall(function() pet:ClearTarget() end)
            end
        end
    end
    table.clear(self.petTargets)
    self.onStatus("Auto Quebrar desligado")
end

return AutoBreakables
