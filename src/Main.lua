local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "KeySystem"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

-- Main Frame
local frame = Instance.new("Frame")
frame.Parent = gui
frame.Size = UDim2.fromOffset(420, 240)
frame.Position = UDim2.fromScale(0.5, 0.5)
frame.AnchorPoint = Vector2.new(0.5, 0.5)
frame.BackgroundColor3 = Color3.fromRGB(15, 25, 45)
frame.BackgroundTransparency = 0.15

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 20)
frameCorner.Parent = frame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(80, 140, 255)
stroke.Transparency = 0.5
stroke.Parent = frame

-- Title
local title = Instance.new("TextLabel")
title.Parent = frame
title.BackgroundTransparency = 1
title.Size = UDim2.new(1, 0, 0, 40)
title.Text = "🔑 : Tapher Key System"
title.Font = Enum.Font.GothamBold
title.TextSize = 22
title.TextColor3 = Color3.new(1,1,1)

-- Subtitle
local subtitle = Instance.new("TextLabel")
subtitle.Parent = frame
subtitle.BackgroundTransparency = 1
subtitle.Position = UDim2.fromOffset(0, 35)
subtitle.Size = UDim2.new(1, 0, 0, 25)
subtitle.Text = "An easy Aunthentication to get key"
subtitle.Font = Enum.Font.Gotham
subtitle.TextSize = 13
subtitle.TextColor3 = Color3.fromRGB(180,180,180)

-- Key Box
local keyBox = Instance.new("TextBox")
keyBox.Parent = frame
keyBox.Position = UDim2.fromOffset(20, 80)
keyBox.Size = UDim2.new(1, -40, 0, 45)
keyBox.PlaceholderText = "Enter your key..."
keyBox.Text = ""
keyBox.Font = Enum.Font.Gotham
keyBox.TextSize = 16
keyBox.TextColor3 = Color3.new(1,1,1)
keyBox.BackgroundColor3 = Color3.fromRGB(25, 35, 60)

local keyCorner = Instance.new("UICorner")
keyCorner.CornerRadius = UDim.new(0, 14)
keyCorner.Parent = keyBox

-- Status
local status = Instance.new("TextLabel")
status.Parent = frame
status.BackgroundTransparency = 1
status.Position = UDim2.fromOffset(20, 130)
status.Size = UDim2.new(1, -40, 0, 20)
status.Text = "Waiting for key..."
status.Font = Enum.Font.Gotham
status.TextSize = 14
status.TextColor3 = Color3.fromRGB(200,200,200)

-- Submit Button
local submit = Instance.new("TextButton")
submit.Parent = frame
submit.Position = UDim2.fromOffset(20, 165)
submit.Size = UDim2.new(0.48, -5, 0, 45)
submit.Text = "Submit"
submit.Font = Enum.Font.GothamBold
submit.TextSize = 16
submit.TextColor3 = Color3.new(1,1,1)
submit.BackgroundColor3 = Color3.fromRGB(50, 120, 255)

local submitCorner = Instance.new("UICorner")
submitCorner.CornerRadius = UDim.new(0, 14)
submitCorner.Parent = submit

-- Get Key Button
local getKey = Instance.new("TextButton")
getKey.Parent = frame
getKey.Position = UDim2.new(0.52, 5, 0, 165)
getKey.Size = UDim2.new(0.48, -25, 0, 45)
getKey.Text = "Get Key"
getKey.Font = Enum.Font.GothamBold
getKey.TextSize = 16
getKey.TextColor3 = Color3.new(1,1,1)
getKey.BackgroundColor3 = Color3.fromRGB(35, 50, 90)

local getCorner = Instance.new("UICorner")
getCorner.CornerRadius = UDim.new(0, 14)
getCorner.Parent = getKey

-- Dragging
local dragging = false
local dragStart
local startPos

frame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startPos = frame.Position
	end
end)

frame.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = false
	end
end)

game:GetService("UserInputService").InputChanged:Connect(function(input)
	if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = input.Position - dragStart
		frame.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end
end)

-- Get Key
getKey.MouseButton1Click:Connect(function()
	setclipboard("https://keysite-13z.pages.dev/")
	status.Text = "Key link copied to clipboard."
end)

-- Validate
submit.MouseButton1Click:Connect(function()

	local key = keyBox.Text

	if key == "" then
		status.Text = "Please enter a key."
		return
	end

	status.Text = "Checking key..."

	local HttpService = game:GetService("HttpService")
	local RbxAnalyticsService = game:GetService("RbxAnalyticsService")

	local hwid = RbxAnalyticsService:GetClientId()

	local success, result = pcall(function()

		local url =
			"https://key-api.dzaxtheonly1.workers.dev/validate?key="
			.. HttpService:UrlEncode(key)
			.. "&hwid="
			.. HttpService:UrlEncode(hwid)

		return game:HttpGet(url)

	end)

	if not success then
		warn(result)
		status.Text = "Connection error."
		return
	end

	if result == "valid" then

		status.Text = "Key Valid ✓"

		task.wait(0.5)

local Games = {
    [105031185134358] = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/arkairi-peak/dubwa/refs/heads/main/src/loader 1.2.1.lua"))()
    end,

    [112490729816320] = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/arkairi-peak/dubwa/refs/heads/main/src/spinSoccerCard.lua"))()
    end,

    [12345] = function()
        loadstring(game:HttpGet("https://your-game3-script-url"))()
    end,
}

local Script = Games[game.PlaceId]

if Script then
    Script()
else
    warn("Unsupported game:", game.PlaceId)
	loadstring(game:HttpGet("https://raw.githubusercontent.com/arkairi-peak/taphergg/refs/heads/main/src/Example.lua"))()
end

		gui:Destroy()

	elseif result == "expired" then

		status.Text = "Key Expired."

	elseif result == "banned" then

		status.Text = "Key Banned."

	elseif result == "hwid mismatch" then

		status.Text = "HWID Locked."

	elseif result == "missing data" then

		status.Text = "HWID Error."

	else

		status.Text = "Wrong Key."

	end

end)
