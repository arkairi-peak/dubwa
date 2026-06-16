--[[
    Example.lua — TapherLib demo script
    Replace BASE_URL in Main.lua with your raw GitHub URL first.
]]

local Tapher = loadstring(game:HttpGet('https://raw.githubusercontent.com/arkairi-peak/taphergg/refs/heads/main/src/Main.lua'))()

local Players     = game:GetService("Players")
local RunService  = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

_G.SelectedPlayer  = nil
_G.OrbitConnection = nil

local Dropdown

-- ── Create window ─────────────────────────────────────────────────────────────
local Window = Tapher:CreateWindow({
    Title        = "Tapher Hub - [UPD!] Defend ur base with anime",
    Subtitle     = "v1.2.2 • by Arkairi ⭐ ",
    LogoImage    = "rbxassetid://97237638807192", -- top-left corner icon (rbxassetid or emoji)
    Keybind      = Enum.KeyCode.RightShift,
    Watermark    = true,
    SearchBar    = true,
    MinimiseMode = "Float",
    FloatImage   = "rbxassetid://97237638807192",
})

-- ── Home tab ──────────────────────────────────────────────────────────────────
Window:AddHomePage({
    TabIcon       = "rbxassetid://80609810613864",
    Badge         = "Free",
    ScriptName    = "Tapher Hub",
    ScriptVersion = "v1.2.2",
    ScriptIcon    = "rbxassetid://97237638807192", -- your logo, or use emoji like "◈"
})
-- tab main
local Feature = Window:AddTab({ Name = "Feature", Icon = "rbxassetid://105998503314801" })

Feature:AddSeparator("Instruction")

Feature:AddLabel("Get close to the roll button first before start rolling")
Feature:AddLabel("Which Plot location is yours at is below")
Feature:AddButton({
    Name        = "Plot Information",
    Description = "Click here to copy the link",
    Callback    = function()
        setclipboard("https://i.ibb.co/m58XTyrt/image.png")
        Tapher:NotifySuccess("Copied!", "Plot location link copied to clipboard.", "Bounce")
    end,
})

Feature:AddSeparator("Features")

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local GuiService = game:GetService("GuiService")

local player = Players.LocalPlayer
local selectedPlot = "Plot4" 
local autoRollActive = false

-- MULTI-DROPDOWN CONFIGURATION
_G.SelectedRarities = {} 
local HOLD_TIME = 0.3   
local SERVER_SYNC = 0.6 

-- 1. CLICK ENGINE
local function clickUiButton(button)
    if not button or not button.Visible then return false end
    if typeof(firesignal) == "function" then
        firesignal(button.MouseButton1Click)
        firesignal(button.Activated)
        return true
    end
    if button:IsA("GuiButton") then
        button:Activate()
    end
    local inset = GuiService:GetGuiInset()
    local x = button.AbsolutePosition.X + (button.AbsoluteSize.X / 2)
    local y = button.AbsolutePosition.Y + (button.AbsoluteSize.Y / 2) + inset.Y
    VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 0)
    task.wait(0.05)
    VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 0)
    return true
end

-- 2. TARGET-LOCKED BUY EXECUTIONER
local function findAndClickCorrectBuyButton(detectedChar)
    local character = player.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    local charPart = detectedChar:FindFirstChildOfClass("BasePart") or detectedChar.PrimaryPart
    
    if hrp and charPart then
        hrp.CFrame = charPart.CFrame * CFrame.new(0, 3, 0)
        task.wait(0.15) 
    end

    if typeof(fireproximityprompt) == "function" then
        for _, prompt in ipairs(detectedChar:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") then
                fireproximityprompt(prompt)
                return true
            end
        end
        if detectedChar.Parent then
            for _, prompt in ipairs(detectedChar.Parent.Parent:GetDescendants()) do
                if prompt:IsA("ProximityPrompt") and prompt.Enabled then
                    fireproximityprompt(prompt)
                    return true
                end
            end
        end
    end

    local playerGui = player:FindFirstChild("PlayerGui")
    if not playerGui then return false end

    local bestButton = nil
    local minDistance = math.huge
    local charNameLower = string.lower(detectedChar.Name)

    for _, obj in ipairs(playerGui:GetDescendants()) do
        if obj:IsA("GuiButton") and obj.Visible and obj.AbsoluteSize.X > 0 then
            local buttonName = string.lower(obj.Name)
            local buttonText = obj:IsA("TextButton") and string.lower(obj.Text) or ""
            
            local isBuyButton = string.find(buttonName, "buy") or string.find(buttonName, "claim") or string.find(buttonName, "purchase") or
                                string.find(buttonText, "buy") or string.find(buttonText, "claim") or string.find(buttonText, "purchase")
                                
            if isBuyButton then
                local billboard = obj:FindFirstAncestorOfClass("BillboardGui")
                if billboard and billboard.Adornee and billboard.Adornee:IsA("BasePart") then
                    if charPart then
                        local dist = (billboard.Adornee.Position - charPart.Position).Magnitude
                        if dist < minDistance then
                            minDistance = dist
                            bestButton = obj
                        end
                    end
                else
                    local container = obj.Parent
                    if container then
                        local textMatchesCharacter = false
                        for _, child in ipairs(container:GetDescendants()) do
                            if child:IsA("TextLabel") and child.Text ~= "" then
                                local labelText = string.lower(string.gsub(child.Text, "<[^>]+>", ""))
                                if string.find(charNameLower, labelText) or string.find(labelText, charNameLower) then
                                    textMatchesCharacter = true
                                    break
                                end
                            end
                        end
                        if textMatchesCharacter then
                            bestButton = obj
                            break
                        end
                    end
                end
            end
        end
    end

    if bestButton then return clickUiButton(bestButton) end
    return false
end

-- FIXED MATCH FUNCTION
local function checkRarityMatch(inputString)
    if not _G.SelectedRarities then return false end
    local cleanedInput = string.lower(tostring(inputString))
    
    for _, checkedRarity in ipairs(_G.SelectedRarities) do
        if string.find(cleanedInput, string.lower(tostring(checkedRarity))) then
            return true 
        end
    end
    return false
end

-- 3. MULTI-TARGET PAD SCANNER
local function getAllSpawnedTargetCharacters()
    local plotsFolder = Workspace:FindFirstChild("Plots")
    if not plotsFolder then return {} end

    local myPlot = plotsFolder:FindFirstChild(selectedPlot)
    if not myPlot then return {} end

    local charactersFolder = myPlot:FindFirstChild("Characters")
    if not charactersFolder then return {} end

    local targetsFound = {}

    for _, charInstance in ipairs(charactersFolder:GetChildren()) do
        local isMatch = false
        
        if checkRarityMatch(charInstance.Name) then isMatch = true end
        
        if not isMatch then
            local commonAttributes = {"Rarity", "Tier", "RarityName", "Type", "Quality"}
            for _, attrName in ipairs(commonAttributes) do
                local attrVal = charInstance:GetAttribute(attrName)
                if attrVal and checkRarityMatch(attrVal) then 
                    isMatch = true
                    break
                end
            end
        end
        if not isMatch then
            for _, child in ipairs(charInstance:GetChildren()) do
                if (child:IsA("StringValue") or child:IsA("ObjectValue")) and checkRarityMatch(child.Value) then 
                    isMatch = true
                    break
                end
            end
        end
        if not isMatch then
            for _, desc in ipairs(charInstance:GetDescendants()) do
                if desc:IsA("TextLabel") and desc.Visible and desc.Text ~= "" then
                    local cleanText = string.gsub(desc.Text, "<[^>]+>", "")
                    if checkRarityMatch(cleanText) then 
                        isMatch = true
                        break
                    end
                end
            end
        end
        if isMatch then table.insert(targetsFound, charInstance) end
    end
    return targetsFound
end

-- ====================================================================
-- DROPDOWNS & TOGGLES
-- ====================================================================

Feature:AddDropdown({
    Name     = "Select Your Plot Location",
    Options  = { "Plot1", "Plot2", "Plot3", "Plot4", "Plot5", "Plot6" },
    Default  = "Plot4",
    Callback = function(val)
        selectedPlot = val
        print("[Auto-Roll] Target set to Plots." .. selectedPlot)
    end
})

Feature:AddMultiDropdown({
    Name     = "Select Rarities to Auto-Buy",
    Options  = { 
        "Common", "Rare", "Epic", "Legendary", "Mythic",  
        "God", "Secret",  "Limited", 
        "Anomali", 
    },
    Default  = {},
    Flag     = "SelectedRarities",
    Callback = function(selected) 
        _G.SelectedRarities = selected
        print("[Auto-Roll] Tracking: " .. table.concat(selected, ", "))
    end,
})

Feature:AddToggle({
    Name     = "Infinite Roll & Multi-Buy",
    Default  = false,
    Callback = function(state)
        autoRollActive = state
        
        if autoRollActive then
            print("[Auto-System] Continuous multi-rarity macro engaged.")
            task.spawn(function()
                local rollCFrame = nil
                local character = player.Character
                local hrp = character and character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    rollCFrame = hrp.CFrame
                    print("[Auto-System] Anchored home base location.")
                end

                while autoRollActive do
                    -- Clean state execution: Roll input sequence
                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
                    task.wait(0.05)
                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                    task.wait(HOLD_TIME) 
                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
                    
                    task.wait(SERVER_SYNC)
                    
                    local targetUnits = getAllSpawnedTargetCharacters()
                    if #targetUnits > 0 then
                        print("[Auto-System] Matches discovered: " .. tostring(#targetUnits))
                        
                        for _, unit in ipairs(targetUnits) do
                            if not autoRollActive then break end
                            print("[Auto-System] Teleporting and buying: " .. unit.Name)
                            
                            local bought = findAndClickCorrectBuyButton(unit)
                            if bought then
                                task.wait(0.4)
                            end
                        end
                        
                        -- Teleport Home sequence executed cleanly after the queue clears
                        character = player.Character
                        hrp = character and character:FindFirstChild("HumanoidRootPart")
                        if hrp and rollCFrame then
                            print("[Auto-System] Returning home to roll platform...")
                            hrp.CFrame = rollCFrame
                            task.wait(0.3)
                        end
                    end
                    
                    -- FIXED: This pacing wait and loop continue block now correctly sits 
                    -- outside the item verification statement, allowing continuous execution.
                    print("[Auto-System] Cycle clean. Prepared to re-roll.")
                    task.wait(0.09)
                end
                print("[Auto-System] Loop safely stopped.")
            end)
        end
    end
}) -- FIXED: Added the missing closing parenthesis here

Feature:AddSeparator("Farm")

Feature:AddDropdown({
    Name     = "Fast Forward Speed (x3 work)",
    Options  = { "1", "2", "3", "4" },
    Default  = "1",
    Callback = function(val) 
        -- val comes back as a string, so tonumber() converts it back to a regular number
        local speedNumber = tonumber(val) 
        
        local args = {
            speedNumber
        }
        game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Start"):WaitForChild("FastForward"):FireServer(unpack(args))
    end,
})

Feature:AddToggle({
    Name = "Auto Start",
    Default = false,
    Flag = "AutoStartWave",
    Callback = function(val)
        local args = {
            val -- true when enabled, false when disabled
        }

        game:GetService("ReplicatedStorage")
            :WaitForChild("Remotes")
            :WaitForChild("Start")
            :WaitForChild("AutoSkip")
            :FireServer(unpack(args))
    end,
})

Feature:AddSeparator("Traits")

-- ==========================================
-- 1. SETTINGS & SCHEMATICS
-- ==========================================
local AutoRollSettings = {
    Enabled = false,
    TargetRarity = "Legendary",
    DelayBetweenRolls = 0.09,
    SelectedCharacterId = nil
}

-- Dictionary matching what you see in the dropdown to the long UUID string
local CharacterCache = {}

local RarityHierarchy = {
    ["Common"]    = 1,
    ["Rare"]      = 2,
    ["Epic"]      = 3,
    ["Legendary"] = 4,
    ["Mythic"]    = 5,
    ["God"]       = 6
}

local TraitModule = {
    Traits = {
        ["Far Sight I"] = "Common", ["Quick Step I"] = "Common", ["Battle Spirit I"] = "Common",
        ["Far Sight II"] = "Rare", ["Quick Step II"] = "Rare", ["Battle Spirit II"] = "Rare",
        ["Far Sight III"] = "Epic", ["Quick Step III"] = "Epic", ["Battle Spirit III"] = "Epic",
        ["Sixth Eye"] = "Legendary", ["Golden Aura"] = "Legendary", ["War Giant"] = "Legendary", 
        ["Beast Fang"] = "Legendary", ["Star Bloom"] = "Legendary",
        ["Divine Eye"] = "Mythic", ["King's Fortune"] = "Mythic", ["Soul Reaper"] = "Mythic", 
        ["Void Emperor"] = "Mythic", ["Celestial"] = "Mythic",
        ["Corrupted"] = "God"
    }
}

-- ==========================================
-- 2. DYNAMIC BACKPACK DETECTOR
-- ==========================================
local function getOwnedCharactersList()
    local names = {}
    CharacterCache = {} -- Erase past scan results
    
    local player = game:GetService("Players").LocalPlayer
    local backpack = player:FindFirstChild("Backpack")
    
    if backpack then
        for _, item in pairs(backpack:GetChildren()) do
            -- Checks standard property paths where developers stick object IDs
            local charId = item:GetAttribute("CharacterId") 
                or item:GetAttribute("UUID")
                or item:GetAttribute("Id")
                or (item:FindFirstChild("CharacterId") and item.CharacterId.Value)
                or (item:FindFirstChild("UUID") and item.UUID.Value)
            
            -- If we found an active ID string on the object, capture it!
            if charId then
                CharacterCache[item.Name] = tostring(charId)
                table.insert(names, item.Name)
            else
                -- Failsafe: if the tool exists but the ID isn't directly matching an attribute,
                -- we can display it so you can see if it falls back.
                CharacterCache[item.Name] = item.Name
                table.insert(names, item.Name)
            end
        end
    end
    
    -- Active fallback: Injecting Jinwoo explicitly if your backpack happens to be completely empty
    if #names == 0 then
        print("[Inventory Sync]: Backpack empty or locked. Injecting your Jinwoo default.")
        CharacterCache["Jinwoo (Manual Key)"] = "b7e40790-be0e-4c04-b7a9-04552b4e9ae2"
        table.insert(names, "Jinwoo (Manual Key)")
    end
    
    return names
end

-- ==========================================
-- 3. REMOTE TRANSMISSION MAIN ENGINE
-- ==========================================
local function startAutoRollLoop()
    task.spawn(function()
        local remotesFolder = game:GetService("ReplicatedStorage"):WaitForChild("Remotes", 5)
        if not remotesFolder then return warn("Could not locate Remotes directory frame!") end
        
        local traitRequest = remotesFolder:WaitForChild("Trait", 5):WaitForChild("Request", 5)
        local player = game:GetService("Players").LocalPlayer
        local playerGui = player:WaitForChild("PlayerGui")
        
        while AutoRollSettings.Enabled do
            if not AutoRollSettings.SelectedCharacterId then
                warn("[Auto-Roll Cancelled]: Ensure you select a unit from your dropdown layout first.")
                AutoRollSettings.Enabled = false
                break
            end

            -- Read current traits directly from active interface text strings
            local currentTraitName = "Unknown"
            local currentRarity = "Common"
            
            -- Dynamic screen scraper lookups
            for _, label in pairs(playerGui:GetDescendants()) do
                if label:IsA("TextLabel") and TraitModule.Traits[label.Text] then
                    currentTraitName = label.Text
                    currentRarity = TraitModule.Traits[label.Text]
                    break
                end
            end

            local targetTier = RarityHierarchy[AutoRollSettings.TargetRarity] or 4
            local currentTier = RarityHierarchy[currentRarity] or 1

            -- Jackpot exit condition match check
            if currentTier >= targetTier then
                print(string.format("[Engine Complete]: Target threshold satisfied. Rolled: %s (%s)", currentTraitName, currentRarity))
                AutoRollSettings.Enabled = false
                break
            end

            -- Operational routing string settings configuration
            local actionType = "Roll"
            if currentRarity == "Legendary" or currentRarity == "Mythic" then
                actionType = "ConfirmedRoll"
                print(string.format("[Popup Cleared]: Using ConfirmedRoll payload structure to skip %s", currentTraitName))
            end

            -- Fire structured arguments down the pipe matching your verification signature block
            local payload = {
                actionType,
                {
                    CharacterId = AutoRollSettings.SelectedCharacterId
                }
            }

            traitRequest:FireServer(unpack(payload))
            task.wait(AutoRollSettings.DelayBetweenRolls)
        end
    end)
end

-- ==========================================
-- 4. GUI ASSEMBLY & COMPONENT LINKS
-- ==========================================

-- Dropdown Component: Backpack Character Profile Selector
local CharacterDropdown = Feature:AddDropdown({
    Name     = "Choose Character",
    Options  = getOwnedCharactersList(),
    Default  = "Uchiha Arka",
    Callback = function(val)
        AutoRollSettings.SelectedCharacterId = CharacterCache[val]
        print("Now targeting Character ID profile: " .. tostring(AutoRollSettings.SelectedCharacterId))
    end,
})

-- Button Component: Re-scan dynamic targets frame
Feature:AddButton({
    Name = "Refresh Inventory",
    Callback = function()
        local updatedList = getOwnedCharactersList()
        if CharacterDropdown then
            if typeof(CharacterDropdown.Refresh) == "function" then
                CharacterDropdown:Refresh(updatedList, true)
            elseif typeof(CharacterDropdown.UpdateDropdown) == "function" then
                CharacterDropdown:UpdateDropdown(updatedList)
            end
        end
        print("Backpack scan sync cycle completed.")
    end
})

-- Dropdown Component: Quality target cap filters
Feature:AddDropdown({
    Name     = "Rarity Stop Target",
    Options  = { "Rare", "Epic", "Legendary", "Mythic", "God" },
    Default  = "Legendary",
    Callback = function(val)
        AutoRollSettings.TargetRarity = val
    end,
})

-- Toggle Component: Global system state trigger
Feature:AddToggle({
    Name    = "Enable Auto Roll Engine",
    Default = false,
    Flag    = "auto_roll_traits_flag",
    Callback = function(val)
        AutoRollSettings.Enabled = val
        if val then
            startAutoRollLoop()
			
            print("Auto Roll Pipeline Active.")
        else
            print("Auto Roll Pipeline Terminated.")
        end
    end,
})

Feature:AddSeparator("DUPE / DUPLICATE")

Feature:AddButton({
	Name = "DUPE Character (CLICK)",
	Description = "Hold the character you want to dupe",
	Callback = function(val)
		print("bro thought ts work")
		Tapher:NotifyInfo("Character is duped!", "Bro kira tombol ini work.😹", "Hologram")
	end,
})


-- tab misc / players
local Misc = Window:AddTab({ Name = "Misc", Icon = "rbxassetid://130498102822965" })

Misc:AddSeparator("Player")

Misc:AddToggle({
    Name    = "Infinite Jump",
    Default = false,
    Flag    = "InfJump",
    Callback = function(val)
        if val then
            local UIS = game:GetService("UserInputService")
            _G.InfJumpConnection = UIS.JumpRequest:Connect(function()
                local char = Players.LocalPlayer.Character
                if char then
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
                end
            end)
        else
            if _G.InfJumpConnection then
                _G.InfJumpConnection:Disconnect()
                _G.InfJumpConnection = nil
            end
        end
    end,
})

Misc:AddSlider({
    Name    = "Walk Speed",
    Min     = 16,
    Max     = 500,
    Step    = 2,
    Default = 16,
    Flag    = "WalkSpeed",
    Callback = function(val)
        local char = Players.LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.WalkSpeed = val
        end
    end,
})

Misc:AddSlider({
    Name    = "Jump Power",
    Min     = 50,
    Max     = 500,
    Step    = 10,
    Default = 50,
    Flag    = "JumpPower",
    Callback = function(val)
        local char = Players.LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.JumpPower = val
        end
    end,
})

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local OriginalMaxZoom = LocalPlayer.CameraMaxZoomDistance

Misc:AddToggle({
    Name = "Infinite Zoom",
    Default = false,
    Flag = "InfiniteZoom",

    Callback = function(val)
        if val then
            LocalPlayer.CameraMaxZoomDistance = math.huge
            print("Infinite Zoom Enabled")
        else
            LocalPlayer.CameraMaxZoomDistance = OriginalMaxZoom
            print("Infinite Zoom Disabled")
        end
    end,
})

Misc:AddSeparator("Misc")

Misc:AddToggle({
    Name    = "Noclip",
    Default = false,
    Flag    = "Noclip",
    Callback = function(val)
        _G.Noclip = val
        if val then
            _G.NoclipConnection = RunService.Stepped:Connect(function()
                local char = Players.LocalPlayer.Character
                if char then
                    for _, part in pairs(char:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                        end
                    end
                end
            end)
        else
            if _G.NoclipConnection then
                _G.NoclipConnection:Disconnect()
                _G.NoclipConnection = nil
            end
        end
    end,
})

Misc:AddToggle({ 
    Name    = "Fly",
    Default = false,
    Flag    = "Fly",
    Callback = function(enabled)
        local UIS = game:GetService("UserInputService")
        local player    = Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local humanoid  = character:WaitForChild("Humanoid")
        local root      = character:WaitForChild("HumanoidRootPart")

        if enabled then
            local bv = Instance.new("BodyVelocity")
            bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            bv.Velocity = Vector3.zero
            bv.Parent   = root

            local bg = Instance.new("BodyGyro")
            bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
            bg.P = 1000
            bg.D = 50
            bg.CFrame = root.CFrame
            bg.Parent  = root

            _G.FlyBV = bv
            _G.FlyBG = bg

            _G.FlyConnection = RunService.RenderStepped:Connect(function()
                local cam = workspace.CurrentCamera
                local dir = Vector3.zero

                if UIS:IsKeyDown(Enum.KeyCode.W) then dir += cam.CFrame.LookVector  end
                if UIS:IsKeyDown(Enum.KeyCode.S) then dir -= cam.CFrame.LookVector  end
                if UIS:IsKeyDown(Enum.KeyCode.A) then dir -= cam.CFrame.RightVector end
                if UIS:IsKeyDown(Enum.KeyCode.D) then dir += cam.CFrame.RightVector end
                if UIS:IsKeyDown(Enum.KeyCode.Space)       then dir += Vector3.new(0,1,0) end
                if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.new(0,1,0) end

                if dir.Magnitude > 0 then dir = dir.Unit end
                bv.Velocity = dir * (_G.FlySpeed or 60)
                bg.CFrame   = cam.CFrame
            end)

            humanoid.PlatformStand = true
        else
            humanoid.PlatformStand = false
            if _G.FlyConnection then _G.FlyConnection:Disconnect(); _G.FlyConnection = nil end
            if _G.FlyBV then _G.FlyBV:Destroy(); _G.FlyBV = nil end
            if _G.FlyBG then _G.FlyBG:Destroy(); _G.FlyBG = nil end
        end
    end,
})

_G.FlySpeed = 160
Misc:AddSlider({
    Name    = "Flying Speed",
    Min     = 1,
    Max     = 2000,
    Step    = 2,
    Default = 60,
    Flag    = "FlySpeed",
    Callback = function(val) _G.FlySpeed = val end,
})

Misc:AddSeparator("ESP")

_G.ESPDistance = 500
Misc:AddSlider({
    Name    = "ESP Distance",
    Min     = 10,
    Max     = 3000,
    Step    = 10,
    Default = 500,
    Flag    = "ESPDistance",
    Callback = function(val) _G.ESPDistance = val end,
})

_G.ESPColor = Color3.fromRGB(234, 0, 255)
Misc:AddColorPicker({
    Name    = "ESP Color",
    Default = _G.ESPColor,
    Flag    = "ESPColor",
    Callback = function(color) _G.ESPColor = color end,
})

Misc:AddToggle({
    Name    = "ESP (Highlight + Line)",
    Default = false,
    Flag    = "ESP",
    Callback = function(val)
        if val then
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then
                    local function applyESP(char)
                        local hrp    = char:FindFirstChild("HumanoidRootPart")
                        local myChar = LocalPlayer.Character
                        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
                        if not hrp or not myRoot then return end

                        local dist = (hrp.Position - myRoot.Position).Magnitude
                        if dist > (_G.ESPDistance or 500) then return end

                        for _, v in ipairs(hrp:GetChildren()) do
                            if v.Name == "ESP_Highlight" or v.Name == "ESP_Att0" or v.Name == "ESP_Beam" then
                                v:Destroy()
                            end
                        end

                        local hl = Instance.new("Highlight")
                        hl.Name               = "ESP_Highlight"
                        hl.Adornee            = char
                        hl.FillTransparency   = 1
                        hl.OutlineTransparency= 0
                        hl.OutlineColor       = _G.ESPColor
                        hl.Parent             = hrp

                        local att0 = Instance.new("Attachment")
                        att0.Name   = "ESP_Att0"
                        att0.Parent = hrp

                        local att1 = Instance.new("Attachment")
                        att1.Name   = "ESP_Att1"
                        att1.Parent = myRoot

                        local beam = Instance.new("Beam")
                        beam.Name        = "ESP_Beam"
                        beam.Attachment0 = att0
                        beam.Attachment1 = att1
                        beam.Width0      = 0.1
                        beam.Width1      = 0.1
                        beam.FaceCamera  = true
                        beam.Color       = ColorSequence.new(_G.ESPColor)
                        beam.Parent      = hrp
                    end

                    if player.Character then applyESP(player.Character) end
                    player.CharacterAdded:Connect(function(char)
                        if _G.ESP then task.wait(0.5); applyESP(char) end
                    end)
                end
            end
        else
            for _, player in ipairs(Players:GetPlayers()) do
                if player.Character then
                    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        for _, v in ipairs(hrp:GetChildren()) do
                            if v.Name == "ESP_Highlight" or v.Name == "ESP_Att0" or v.Name == "ESP_Beam" then
                                v:Destroy()
                            end
                        end
                    end
                end
            end
        end
    end,
})

Misc:AddSeparator("Spin")

local function GetPlayerList()
    local list = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then table.insert(list, plr.Name) end
    end
    return list
end

Dropdown = Misc:AddDropdown({
    Name     = "Select Player",
    Options  = GetPlayerList(),
    Default  = nil,
    Callback = function(val)
	 _G.SelectedPlayer = val end,
})

Misc:AddButton({
    Name = "Refresh Player List",
    Callback = function()
        Dropdown:Refresh(GetPlayerList())
    end,
})

Misc:AddToggle({
    Name    = "Orbit Player",
    Default = false,
    Flag    = "OrbitPlayer",
    Callback = function(val)
        if val then
            _G.OrbitConnection = RunService.RenderStepped:Connect(function()
                local target = Players:FindFirstChild(_G.SelectedPlayer)
                if not target then return end

                local char   = target.Character
                local myChar = LocalPlayer.Character
                if not char or not myChar then return end

                local targetRoot = char:FindFirstChild("HumanoidRootPart")
                local myRoot     = myChar:FindFirstChild("HumanoidRootPart")
                if not targetRoot or not myRoot then return end

                local att0 = myRoot:FindFirstChild("OrbitAttachment") or Instance.new("Attachment")
                att0.Name   = "OrbitAttachment"
                att0.Parent = myRoot

                local att1 = targetRoot:FindFirstChild("OrbitTargetAttachment") or Instance.new("Attachment")
                att1.Name   = "OrbitTargetAttachment"
                att1.Parent = targetRoot

                local align = myRoot:FindFirstChild("OrbitAlign") or Instance.new("AlignPosition")
                align.Name           = "OrbitAlign"
                align.Attachment0    = att0
                align.Attachment1    = att1
                align.MaxForce       = 50000
                align.Responsiveness = 25
                align.RigidityEnabled= false
                align.Parent         = myRoot

                local radius = 6
                local speed  = 14
                local angle  = tick() * speed
                att1.Position = Vector3.new(
                    math.cos(angle) * radius,
                    2,
                    math.sin(angle) * radius
                )
            end)
        else
            if _G.OrbitConnection then
                _G.OrbitConnection:Disconnect()
                _G.OrbitConnection = nil
            end
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                local root = char.HumanoidRootPart
                if root:FindFirstChild("OrbitAlign")      then root.OrbitAlign:Destroy()      end
                if root:FindFirstChild("OrbitAttachment") then root.OrbitAttachment:Destroy() end
            end
        end
    end,
})

-- ── Tab: Settings ─────────────────────────────────────────────────────────────
local Settings = Window:AddTab({ Name = "Settings", Icon = "rbxassetid://109766113740047" })

Settings:AddLabel("Accent Theme")

Settings:AddDropdown({
    Name     = "Accent Color",
    Options  = { "Purple", "Blue", "Cyan", "Pink", "Green", "Red", "Orange", "Gold" },
    Default  = "Purple",
    Callback = function(val) Tapher:SetAccent(val) end,
})

Settings:AddSeparator("Config")

Settings:AddButton({
    Name        = "Save Config",
    Description = "Saves current settings to file",
    Callback    = function()
        local ok = Tapher:SaveConfig("default")
        if ok then
            Tapher:NotifySuccess("Saved!", "Config saved to TapherLib/default.json", "Bounce")
        else
            Tapher:NotifyError("Failed", "Could not save config (writefile unavailable)", "Glitch")
        end
    end,
})

Settings:AddButton({
    Name        = "Load Config",
    Description = "Loads settings from file",
    Callback    = function()
        local ok = Tapher:LoadConfig("default")
        if ok then
            Tapher:NotifyInfo("Loaded", "Config restored successfully", "Hologram")
        else
            Tapher:NotifyWarning("Not found", "No saved config found", "Slide")
        end
    end,
})

local VirtualUser = game:GetService("VirtualUser")
local Players = game:GetService("Players")

local AntiAFKConnection

Settings:AddToggle({
    Name    = "Anti AFK",
    Default = true,
    Flag    = "Anti-afkers",

    Callback = function(val)

        if val then
            AntiAFKConnection = Players.LocalPlayer.Idled:Connect(function()
                VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                task.wait(1)
                VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            end)

            print("✔ Anti AFK Enabled")

        else
            if AntiAFKConnection then
                AntiAFKConnection:Disconnect()
                AntiAFKConnection = nil
            end

            print("✘ Anti AFK Disabled")
        end

    end,
})


local AntiTeleportLoaded = false
Settings:AddButton({
    Name = "Block Server Teleports",
    Description = "Prevents teleports to other servers",
    Callback = function()

if AntiTeleportLoaded then
    return
						Tapher:NotifyInfo("Tapher Information", "Anti Teleport was already activated.", "Hologram")	
end

AntiTeleportLoaded = true

        if not hookmetamethod then
            warn("Your executor does not support hookmetamethod.")
            return
        end

        local TeleportService = game:GetService("TeleportService")

        local oldIndex
        local oldNamecall

        oldIndex = hookmetamethod(game, "__index", function(self, method)
            if self == TeleportService then
                method = tostring(method)

                if method == "Teleport"
                or method == "TeleportAsync"
                or method == "TeleportPartyAsync"
                or method == "TeleportToPlaceInstance"
                or method == "TeleportToPrivateServer" then
                    error("Tapher Teleport blocked.", 2)
                end
            end

            return oldIndex(self, method)
        end)

        oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            if self == TeleportService then
                local method = tostring(getnamecallmethod())

                if method == "Teleport"
                or method == "TeleportAsync"
                or method == "TeleportPartyAsync"
                or method == "TeleportToPlaceInstance"
                or method == "TeleportToPrivateServer" then
                    warn("[Tapher Anti-Teleport] Blocked:", method)
                    return nil
                end
            end

            return oldNamecall(self, ...)
        end)

        print("[Tapher Anti-Teleport] Activated.")
			Tapher:NotifyInfo("Tapher Information", "Anti Teleport is successfully activated, Only press this button once.", "Hologram")
    end
})

Settings:AddSeparator("Notifications TEST")

Settings:AddButton({
    Name = "Test Hologram Notification",
    Callback = function()
        Tapher:NotifyInfo("Hologram Notification", "Hallo, yang baca ini orang ganteg.", "Hologram")
    end,
})

-- ── Tab: About ────────────────────────────────────────────────────────────────
local About = Window:AddTab({ Name = "About", Icon = "rbxassetid://110553639595926" })

About:AddSeparator("Info")
About:AddLabel("TapherLib v1.2.2")
About:AddLabel("A modern Roblox UI library.")
About:AddLabel("Made with hardwork and creativity by Arkairi.")
About:AddSeparator("Links")

About:AddButton({
    Name        = "Discord",
    Description = "Join the community",
    Callback    = function()
        setclipboard("YOUR_DISCORD_LINK")
        Tapher:NotifySuccess("Copied!", "Discord link copied to clipboard.", "Bounce")
    end,
})

About:AddButton({
    Name        = "Youtube",
    Description = "Subscribe the channel",
    Callback    = function()
        setclipboard("YOUR_YOUTUBE_LINK")
        Tapher:NotifySuccess("Copied!", "Youtube channel link copied to clipboard.", "Bounce")
    end,
})

-- ── Startup notifications ─────────────────────────────────────────────────────
task.wait(2)
Tapher:Notify({
    Title       = "Tapher Hub",
    Description = "Loaded successfully! Press RightShift to toggle.",
    Type        = "success",
    Style       = "Hologram",
    Duration    = 10,
})
-- Tapher:Notify({
--     Title       = "Tapher Hub",
--    Description = "Thanks for using Tapher Library Hub! For more info visit arkairi-peak on GitHub.",
--    Type        = "success",
--    Style       = "Hologram",
--    Duration    = 5,
--})

loadstring(game:HttpGet('https://raw.githubusercontent.com/arkairi-peak/taphergg/refs/heads/main/src/AsciiArtTapher.lua'))()
