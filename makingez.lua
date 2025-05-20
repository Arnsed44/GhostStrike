local DarkraiX = loadstring(game:HttpGet("https://raw.githubusercontent.com/GamingScripter/Kavo-Ui/main/Darkrai%20Ui", true))()
local Library = DarkraiX:Window("GhostStrike", "", "", Enum.KeyCode.RightControl)

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local hrp = character:WaitForChild("HumanoidRootPart")

-- Settings
local settings = {
    hitboxSize = 12,
    isExpanded = false,
    isInfiniteJumpActive = false,
    teleportToAllEnabled = false,
    isFullbrightEnabled = false,
    isSafeZoneActive = false,
    tweenSpeed = 1,
    tagAuraEnabled = false,
    tagAuraRadius = 10,
    espEnabled = false,
    noclipEnabled = false,
    walkSpeedEnabled = false,
    walkSpeedValue = 50,
    jumpPowerEnabled = false,
    jumpPowerValue = 100,
    antiLagEnabled = false,
    antiKickEnabled = false,
    autoCollectEnabled = false
}

-- Original Settings Cache
local originalSettings = {
    walkSpeed = humanoid.WalkSpeed,
    jumpPower = humanoid.JumpPower,
    ambient = Lighting.Ambient,
    brightness = Lighting.Brightness,
    clockTime = Lighting.ClockTime,
    fogEnd = Lighting.FogEnd,
    globalShadows = Lighting.GlobalShadows
}

-- Position cache for teleport to spawn feature
local positionCache = {
    lastPosition = nil,
    safeZoneActivated = false
}

-- Tween Safe Zone Settings
local safeZonePart = Instance.new("Part")
safeZonePart.Size = Vector3.new(50, 1, 50)
safeZonePart.Position = Vector3.new(-1000, 1000, 0)
safeZonePart.Anchored = true
safeZonePart.Transparency = 1
safeZonePart.CanCollide = false
safeZonePart.Parent = Workspace

-- Connections Management
local connections = {
    hitboxExpansion = nil,
    infiniteJump = nil,
    safeZone = nil,
    noclip = nil,
    espUpdate = nil,
    autoTag = nil,
    walkSpeed = nil,
    jumpPower = nil,
    autoCollect = nil
}

-- Helper Functions

-- Hitbox Functions
local function expandHitboxes(enabled)
    if connections.hitboxExpansion then
        connections.hitboxExpansion:Disconnect()
        connections.hitboxExpansion = nil
    end
    
    if enabled then
        connections.hitboxExpansion = RunService.RenderStepped:Connect(function()
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    local part = p.Character.HumanoidRootPart
                    part.Size = Vector3.new(settings.hitboxSize, settings.hitboxSize, settings.hitboxSize)
                    part.Transparency = 0.5
                    part.CanCollide = false
                end
            end
        end)
    else
        -- Reset hitboxes
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local part = p.Character.HumanoidRootPart
                part.Size = Vector3.new(2, 2, 1)
                part.Transparency = 1
            end
        end
    end
end

-- Infinite Jump Function
local function infiniteJump(enabled)
    if connections.infiniteJump then
        connections.infiniteJump:Disconnect()
        connections.infiniteJump = nil
    end
    
    if enabled then
        connections.infiniteJump = UserInputService.JumpRequest:Connect(function()
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end)
    end
end

-- Fullbright Function
local function setFullbright(enabled)
    if enabled then
        -- Save original lighting settings if not already saved
        originalSettings.ambient = Lighting.Ambient
        originalSettings.brightness = Lighting.Brightness
        originalSettings.clockTime = Lighting.ClockTime
        originalSettings.fogEnd = Lighting.FogEnd
        originalSettings.globalShadows = Lighting.GlobalShadows
        
        -- Apply fullbright settings
        Lighting.Ambient = Color3.new(1, 1, 1)
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
        
        -- Remove all post processing effects
        for _, v in pairs(Lighting:GetChildren()) do
            if v:IsA("BlurEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("BloomEffect") then
                v.Enabled = false
            end
        end
    else
        -- Restore original lighting settings
        Lighting.Ambient = originalSettings.ambient
        Lighting.Brightness = originalSettings.brightness
        Lighting.ClockTime = originalSettings.clockTime
        Lighting.FogEnd = originalSettings.fogEnd
        Lighting.GlobalShadows = originalSettings.globalShadows
        
        -- Re-enable post processing effects
        for _, v in pairs(Lighting:GetChildren()) do
            if v:IsA("BlurEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("BloomEffect") then
                v.Enabled = true
            end
        end
    end
end

-- Auto Safe Zone Function
local function autoSafeZone(enabled)
    if connections.safeZone then
        connections.safeZone:Disconnect()
        connections.safeZone = nil
    end
    
    if enabled then
        connections.safeZone = RunService.Heartbeat:Connect(function()
            local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                for _, p in pairs(Players:GetPlayers()) do
                    if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                        local dist = (p.Character.HumanoidRootPart.Position - hrp.Position).Magnitude
                        if dist <= 10 then
                            -- Save current position before teleporting
                            if not positionCache.safeZoneActivated then
                                positionCache.lastPosition = hrp.CFrame
                                positionCache.safeZoneActivated = true
                            end
                            
                            local tweenInfo = TweenInfo.new(settings.tweenSpeed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                            local tween = TweenService:Create(hrp, tweenInfo, {CFrame = safeZonePart.CFrame + Vector3.new(0, 10, 0)})
                            tween:Play()
                        end
                    end
                end
            end
        end)
    else
        positionCache.safeZoneActivated = false
    end
end

-- Manual teleport to safe zone function with position caching
local function teleportToSafeZone()
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        -- Save current position before teleporting
        positionCache.lastPosition = hrp.CFrame
        positionCache.safeZoneActivated = true
        
        local tweenInfo = TweenInfo.new(settings.tweenSpeed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local tween = TweenService:Create(hrp, tweenInfo, {CFrame = safeZonePart.CFrame + Vector3.new(0, 10, 0)})
        tween:Play()
    end
end

-- Teleport to spawn (previous position) function
local function teleportToSpawn()
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if hrp and positionCache.lastPosition then
        local tweenInfo = TweenInfo.new(settings.tweenSpeed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local tween = TweenService:Create(hrp, tweenInfo, {CFrame = positionCache.lastPosition})
        tween:Play()
        positionCache.safeZoneActivated = false
    end
end

-- Create and teleport to safe zone platform
local function createSafeZonePlatform()
    -- Make sure the safe zone part is configured correctly
    safeZonePart.Size = Vector3.new(50, 1, 50)
    safeZonePart.Position = Vector3.new(-1000, 1000, 0)
    safeZonePart.Anchored = true
    safeZonePart.CanCollide = true
    safeZonePart.Transparency = 0.5
    safeZonePart.Material = Enum.Material.SmoothPlastic
    safeZonePart.BrickColor = BrickColor.new("Bright blue")
    safeZonePart.Parent = Workspace
    
    -- Save current position before teleporting
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        positionCache.lastPosition = hrp.CFrame
        positionCache.safeZoneActivated = true
        
        -- Teleport on top of the platform
        local tweenInfo = TweenInfo.new(settings.tweenSpeed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local tween = TweenService:Create(hrp, tweenInfo, {CFrame = CFrame.new(-1000, 1010, 0)}) -- Position above the platform
        tween:Play()
    end
end

-- Noclip Function
local function noclipToggle(enabled)
    if connections.noclip then
        connections.noclip:Disconnect()
        connections.noclip = nil
    end
    
    if enabled then
        connections.noclip = RunService.Stepped:Connect(function()
            for _, part in pairs(character:GetChildren()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end)
    end
end

-- ESP Functions
local highlights = {}

local function addHighlightToPlayer(p, color)
    if highlights[p] then return end
    local character = p.Character
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local highlight = Instance.new("Highlight")
    highlight.Adornee = character
    highlight.FillColor = color or Color3.new(1, 0, 0)
    highlight.OutlineColor = Color3.new(1, 1, 1)
    highlight.Parent = hrp
    highlights[p] = highlight
end

local function removeHighlightFromPlayer(p)
    if highlights[p] then
        highlights[p]:Destroy()
        highlights[p] = nil
    end
end

local function updateESP(enabled, color)
    if connections.espUpdate then
        connections.espUpdate:Disconnect()
        connections.espUpdate = nil
    end
    
    if enabled then
        connections.espUpdate = RunService.RenderStepped:Connect(function()
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    addHighlightToPlayer(p, color)
                else
                    removeHighlightFromPlayer(p)
                end
            end
        end)
    else
        for p, highlight in pairs(highlights) do
            highlight:Destroy()
        end
        highlights = {}
    end
end

-- Auto Tag/Attack Function
local function autoTagOrAttack(enabled)
    if connections.autoTag then
        connections.autoTag:Disconnect()
        connections.autoTag = nil
    end
    
    if enabled then
        connections.autoTag = coroutine.wrap(function()
            while settings.teleportToAllEnabled do
                for _, p in pairs(Players:GetPlayers()) do
                    if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                        local targetHRP = p.Character.HumanoidRootPart
                        player.Character:SetPrimaryPartCFrame(targetHRP.CFrame)
                        wait(0.1)

                        -- Simulate LMB press & release
                        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)

                        wait(0.5)
                    end
                end
                wait(2)
                
                -- Break out of the loop if setting was disabled
                if not settings.teleportToAllEnabled then break end
            end
        end)()
    end
end

-- Tag Aura Function
local function tagAura(enabled)
    if enabled then
        coroutine.wrap(function()
            while settings.tagAuraEnabled do
                local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    for _, p in pairs(Players:GetPlayers()) do
                        if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                            local dist = (p.Character.HumanoidRootPart.Position - hrp.Position).Magnitude
                            if dist <= settings.tagAuraRadius then
                                -- Simulate LMB to tag
                                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
                                break
                            end
                        end
                    end
                end
                wait(0.1)
                
                -- Break out of the loop if setting was disabled
                if not settings.tagAuraEnabled then break end
            end
        end)()
    end
end

-- Walk Speed Function
local function toggleWalkSpeed(enabled)
    if connections.walkSpeed then
        connections.walkSpeed:Disconnect()
        connections.walkSpeed = nil
    end
    
    if enabled then
        connections.walkSpeed = RunService.Heartbeat:Connect(function()
            humanoid.WalkSpeed = settings.walkSpeedValue
        end)
    else
        humanoid.WalkSpeed = originalSettings.walkSpeed
    end
end

-- Jump Power Function
local function toggleJumpPower(enabled)
    if connections.jumpPower then
        connections.jumpPower:Disconnect()
        connections.jumpPower = nil
    end
    
    if enabled then
        connections.jumpPower = RunService.Heartbeat:Connect(function()
            humanoid.JumpPower = settings.jumpPowerValue
        end)
    else
        humanoid.JumpPower = originalSettings.jumpPower
    end
end

-- Anti-Kick Function
local function toggleAntiKick(enabled)
    if enabled and not settings.antiKickEnabled then
        settings.antiKickEnabled = true
        
        local mt = getrawmetatable(game)
        local old = mt.__namecall
        setreadonly(mt, false)
        
        mt.__namecall = newcclosure(function(self, ...)
            local args = {...}
            local method = getnamecallmethod()
            
            if method == "Kick" or method == "kick" then
                return wait(9e9)
            end
            
            return old(self, ...)
        end)
        
        setreadonly(mt, true)
    end
end

-- Anti-Lag Function - Graphics Quality Reducer
local function toggleAntiLag(enabled)
    if enabled then
        -- Reduce graphics quality
        settings.RenderDistance = UserSettings().GameSettings.SavedQualityLevel
        settings.Terrain = workspace.Terrain.WaterWaveSize
        
        UserSettings().GameSettings.SavedQualityLevel = 1
        workspace.Terrain.WaterWaveSize = 0
        workspace.Terrain.WaterWaveSpeed = 0
        workspace.Terrain.WaterReflectance = 0
        workspace.Terrain.WaterTransparency = 0
        
        -- Disable unnecessary rendering
        settings()["Rendering"].QualityLevel = 1
        settings()["Rendering"].EditQualityLevel = 1
        
        -- Disable shadows and other effects
        game:GetService("Lighting").GlobalShadows = false
        game:GetService("Lighting").FogEnd = 9e9
        game:GetService("Lighting").Brightness = 0
        
        -- Disable particles
        for _, v in pairs(game:GetDescendants()) do
            if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles") then
                v.Enabled = false
            end
        end
    else
        -- Restore graphics settings
        UserSettings().GameSettings.SavedQualityLevel = settings.RenderDistance or 7
        workspace.Terrain.WaterWaveSize = settings.Terrain or 0.3
        workspace.Terrain.WaterWaveSpeed = 10
        workspace.Terrain.WaterReflectance = 1
        workspace.Terrain.WaterTransparency = 1
        
        -- Restore lighting
        game:GetService("Lighting").GlobalShadows = true
        game:GetService("Lighting").FogEnd = 100000
        game:GetService("Lighting").Brightness = 1
    end
end

-- Auto Collect Coins Function
local function toggleAutoCollect(enabled)
    if connections.autoCollect then
        connections.autoCollect:Disconnect()
        connections.autoCollect = nil
    end
    
    if enabled then
        local autoCollectCoinsCode = [[
            loadstring(game:HttpGet("https://pastebin.com/raw/YpezQL0B", true))()
        ]]
        loadstring(autoCollectCoinsCode)()
    end
end

-- UI Setup

local MainTab = Library:Tab("Combat")
local UtilitiesTab = Library:Tab("Utilities")
local VisualTab = Library:Tab("Visuals")
local MovementTab = Library:Tab("Movement")
local ConfigTab = Library:Tab("Config")

-- Combat Tab
MainTab:Toggle("Expand Hitboxes", false, function(state)
    settings.isExpanded = state
    expandHitboxes(state)
end)

MainTab:Slider("Hitbox Size", 1, 100, settings.hitboxSize, function(value)
    settings.hitboxSize = value
    if settings.isExpanded then
        expandHitboxes(true)
    end
end)

MainTab:Toggle("Teleport & Attack All Players", false, function(state)
    settings.teleportToAllEnabled = state
    autoTagOrAttack(state)
end)

MainTab:Toggle("Tag Aura", false, function(state)
    settings.tagAuraEnabled = state
    tagAura(state)
end)

MainTab:Slider("Tag Aura Radius", 5, 30, settings.tagAuraRadius, function(value)
    settings.tagAuraRadius = value
end)

MainTab:Toggle("Anti-Kick", false, function(state)
    toggleAntiKick(state)
end)

-- Utilities Tab
UtilitiesTab:Toggle("Spawn Platform", false, function(state)
    if state then
        createSafeZonePlatform()
    end
end)

UtilitiesTab:Toggle("Anti-Lag", false, function(state)
    settings.antiLagEnabled = state
    toggleAntiLag(state)
end)

UtilitiesTab:Toggle("Auto Safe Zone", false, function(state)
    settings.isSafeZoneActive = state
    autoSafeZone(state)
end)

UtilitiesTab:Button("Teleport to Safe Area", function()
    teleportToSafeZone()
end)

-- New button for teleporting back to previous position
UtilitiesTab:Button("Teleport to Spawn", function()
    teleportToSpawn()
end)

UtilitiesTab:Slider("Tween Speed", 0.1, 5, settings.tweenSpeed, function(value)
    settings.tweenSpeed = value
end)

UtilitiesTab:Toggle("Noclip", false, function(state)
    settings.noclipEnabled = state
    noclipToggle(state)
end)

UtilitiesTab:Toggle("Auto Collect Coins", false, function(state)
    settings.autoCollectEnabled = state
    toggleAutoCollect(state)
end)

-- Visuals Tab
VisualTab:Toggle("ESP", false, function(state)
    settings.espEnabled = state
    updateESP(state)
end)

VisualTab:Toggle("Fullbright", false, function(state)
    settings.isFullbrightEnabled = state
    setFullbright(state)
end)

VisualTab:Dropdown("ESP Color", {"Red", "Green", "Blue", "Purple", "Yellow"}, function(color)
    local colorMap = {
        Red = Color3.new(1, 0, 0),
        Green = Color3.new(0, 1, 0),
        Blue = Color3.new(0, 0, 1),
        Purple = Color3.new(0.5, 0, 1),
        Yellow = Color3.new(1, 1, 0)
    }
    
    if settings.espEnabled then
        updateESP(true, colorMap[color])
    end
end)

-- Movement Tab
MovementTab:Toggle("Infinite Jump", false, function(state)
    settings.isInfiniteJumpActive = state
    infiniteJump(state)
end)

MovementTab:Toggle("Walk Speed", false, function(state)
    settings.walkSpeedEnabled = state
    toggleWalkSpeed(state)
end)

MovementTab:Slider("Walk Speed Value", 16, 200, settings.walkSpeedValue, function(value)
    settings.walkSpeedValue = value
    if settings.walkSpeedEnabled then
        toggleWalkSpeed(true)
    end
end)

MovementTab:Toggle("Jump Power", false, function(state)
    settings.jumpPowerEnabled = state
    toggleJumpPower(state)
end)

MovementTab:Slider("Jump Power Value", 50, 200, settings.jumpPowerValue, function(value)
    settings.jumpPowerValue = value
    if settings.jumpPowerEnabled then
        toggleJumpPower(true)
    end
end)

-- Config Tab
ConfigTab:Label("GhostStrike Pro V1 Settings")

ConfigTab:Button("Save Configuration", function()
    local data = settings
    writefile("GhostStrikeProConfig.json", game:GetService("HttpService"):JSONEncode(data))
end)

ConfigTab:Button("Load Configuration", function()
    if isfile("GhostStrikeProConfig.json") then
        local data = game:GetService("HttpService"):JSONDecode(readfile("GhostStrikeProConfig.json"))
        
        -- Update settings with loaded values
        for key, value in pairs(data) do
            settings[key] = value
        end
        
        -- Re-apply all active toggles
        if settings.isExpanded then expandHitboxes(true) end
        if settings.isInfiniteJumpActive then infiniteJump(true) end
        if settings.teleportToAllEnabled then autoTagOrAttack(true) end
        if settings.isFullbrightEnabled then setFullbright(true) end
        if settings.isSafeZoneActive then autoSafeZone(true) end
        if settings.noclipEnabled then noclipToggle(true) end
        if settings.espEnabled then updateESP(true) end
        if settings.tagAuraEnabled then tagAura(true) end
        if settings.walkSpeedEnabled then toggleWalkSpeed(true) end
        if settings.jumpPowerEnabled then toggleJumpPower(true) end
        if settings.antiLagEnabled then toggleAntiLag(true) end
        if settings.antiKickEnabled then toggleAntiKick(true) end
        if settings.autoCollectEnabled then toggleAutoCollect(true) end
    end
end)

ConfigTab:Toggle("Reset All Settings", false, function(state)
    if state then
        -- Disconnect all connections
        for _, connection in pairs(connections) do
            if connection then connection:Disconnect() end
        end
        connections = {}
        
        -- Reset all settings
        settings = {
            hitboxSize = 12,
            isExpanded = false,
            isInfiniteJumpActive = false,
            teleportToAllEnabled = false,
            isFullbrightEnabled = false,
            isSafeZoneActive = false,
            tweenSpeed = 1,
            tagAuraEnabled = false,
            tagAuraRadius = 10,
            espEnabled = false,
            noclipEnabled = false,
            walkSpeedEnabled = false,
            walkSpeedValue = 50,
            jumpPowerEnabled = false,
            jumpPowerValue = 100,
            antiLagEnabled = false,
            antiKickEnabled = false,
            autoCollectEnabled = false
        }
        
        -- Reset all visuals
        expandHitboxes(false)
        setFullbright(false)
        autoSafeZone(false)
        updateESP(false)
        humanoid.WalkSpeed = originalSettings.walkSpeed
        humanoid.JumpPower = originalSettings.jumpPower
        toggleAntiLag(false)
        
        -- Reset position cache
        positionCache = {
            lastPosition = nil,
            safeZoneActivated = false
        }
    end
end)

-- Additional Features
ConfigTab:Toggle("Auto-Rejoin on Kick", false, function(state)
    if state then
        game:GetService("Players").PlayerRemoving:Connect(function(plr)
            if plr == player then
                wait(5)
                game:GetService("TeleportService"):Teleport(game.PlaceId, player)
            end
        end)
    end
end)

ConfigTab:Toggle("Hide Username", false, function(state)
    if state then
        if player.Character and player.Character:FindFirstChild("Head") and player.Character.Head:FindFirstChild("PlayerNameplate") then
            player.Character.Head.PlayerNameplate.Enabled = false
        end
    else
        if player.Character and player.Character:FindFirstChild("Head") and player.Character.Head:FindFirstChild("PlayerNameplate") then
            player.Character.Head.PlayerNameplate.Enabled = true
        end
    end
end)

-- Credits Section
ConfigTab:Label("Created by GhostScript")
ConfigTab:Label("Version 1.0.1")
ConfigTab:Label("Enhanced by Claude - All Toggles Edition")

-- Character respawn handling
player.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
    humanoid = character:WaitForChild("Humanoid")
    hrp = character:WaitForChild("HumanoidRootPart")
    
    -- Store original settings
    originalSettings.walkSpeed = humanoid.WalkSpeed
    originalSettings.jumpPower = humanoid.JumpPower
    
    -- Reapply active settings after respawn
    if settings.isExpanded then expandHitboxes(true) end
    if settings.isInfiniteJumpActive then infiniteJump(true) end
    if settings.noclipEnabled then noclipToggle(true) end
    if settings.walkSpeedEnabled then toggleWalkSpeed(true) end
    if settings.jumpPowerEnabled then toggleJumpPower(true) end
    if settings.isFullbrightEnabled then setFullbright(true) end
    if settings.isSafeZoneActive then autoSafeZone(true) end
end)

DarkraiX:Init()
