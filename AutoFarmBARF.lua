local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- ==========================================
-- SETTINGS & CACHE
-- ==========================================
local Settings = {
	Enabled = false,
	BuyEggs = false,
	CheckInterval = 0.3,
	LeverCooldown = 60,
	TeleportHeight = 5
}

local seedCache = {}
local eggCache = {}
local leverCache = {}

local SEED_NAMES = { ["BuySeed"] = true, ["HarvestPrompt"] = true }
local EGG_NAMES  = { ["BuyEgg"] = true, ["HatchEgg"] = true, ["RollEgg"] = true, ["EggPrompt"] = true, ["Hatch"] = true, ["Egg"] = true }

-- ==========================================
-- LOGIC FUNCTIONS
-- ==========================================
local function forceEnablePrompt(prompt)
	pcall(function()
		prompt.Enabled = true
		prompt.MaxActivationDistance = 1e9
		prompt.RequiresLineOfSight = false
		prompt.HoldDuration = 0
	end)
end

local function getPromptCFrame(prompt)
	local parent = prompt.Parent
	if not parent then return nil end

	if parent:IsA("BasePart") then
		return parent.CFrame
	elseif parent:IsA("Model") then
		return parent:GetPivot()
	elseif parent.Parent and parent.Parent:IsA("Model") then
		return parent.Parent:GetPivot()
	end
	return nil
end

local function firePrompt(prompt)
	if not Settings.Enabled then return false end
	if not prompt or not prompt.Parent then return false end
	
	local character = LocalPlayer.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	local targetCFrame = getPromptCFrame(prompt)
	
	if rootPart and targetCFrame then
		forceEnablePrompt(prompt)
		
		rootPart.CFrame = targetCFrame * CFrame.new(0, Settings.TeleportHeight, 0)
		task.wait(0.08)
		
		if not Settings.Enabled then return false end

		pcall(function()
			if fireproximityprompt then
				fireproximityprompt(prompt)
			end
			prompt:InputHoldBegin()
			task.wait(0.02)
			prompt:InputHoldEnd()
			
			if prompt.Triggered then
				for _, connection in ipairs(getconnections(prompt.Triggered)) do
					connection:Fire(LocalPlayer)
				end
			end
		end)
		
		task.wait(0.05)
		return true
	end
	return false
end

local function isBlacklisted(obj)
	local name = obj.Name:lower()
	local parentName = obj.Parent and obj.Parent.Name:lower() or ""
	local actionText = obj.ActionText and obj.ActionText:lower() or ""
	local objectText = obj.ObjectText and obj.ObjectText:lower() or ""

	return name:find("robux") or parentName:find("robux") or actionText:find("robux") or objectText:find("robux")
		or name:find("pass") or parentName:find("pass") or actionText:find("pass") or objectText:find("pass")
		or name:find("product") or parentName:find("product") or actionText:find("product") or objectText:find("product")
		or name:find("r$") or parentName:find("r$") or actionText:find("r$") or objectText:find("r$")
		or name:find("discard") or parentName:find("discard") or actionText:find("discard") or objectText:find("discard")
		or name:find("trash") or parentName:find("trash") or actionText:find("trash") or objectText:find("trash")
end

local function isSeedPrompt(obj)
	if isBlacklisted(obj) then return false end
	local name = obj.Name:lower()
	local parentName = obj.Parent and obj.Parent.Name:lower() or ""
	local grandParentName = (obj.Parent and obj.Parent.Parent) and obj.Parent.Parent.Name:lower() or ""

	if SEED_NAMES[obj.Name] or SEED_NAMES[obj.Parent.Name] then return true end
	return name:find("buyseed") or parentName:find("buyseed") or grandParentName:find("buyseed") or name:find("harvest")
end

local function isEggPrompt(obj)
	if isBlacklisted(obj) then return false end
	local name = obj.Name:lower()
	local parentName = obj.Parent and obj.Parent.Name:lower() or ""
	local grandParentName = (obj.Parent and obj.Parent.Parent) and obj.Parent.Parent.Name:lower() or ""

	if EGG_NAMES[obj.Name] or EGG_NAMES[obj.Parent.Name] then return true end
	return name:find("buyegg") or parentName:find("buyegg") or grandParentName:find("buyegg") or name:find("hatchegg") or name:find("egg") or parentName:find("egg")
end

local function isRollSeedLeverPrompt(obj)
	return obj.Name == "RollSeeds"
end

local function trackObject(obj)
	if not obj:IsA("ProximityPrompt") then return end
	
	forceEnablePrompt(obj)

	if isRollSeedLeverPrompt(obj) then
		leverCache[obj] = true
		obj.AncestryChanged:Connect(function(_, parent) if not parent then leverCache[obj] = nil end end)
	elseif isSeedPrompt(obj) then
		seedCache[obj] = true
		obj.AncestryChanged:Connect(function(_, parent) if not parent then seedCache[obj] = nil end end)
	elseif isEggPrompt(obj) then
		eggCache[obj] = true
		obj.AncestryChanged:Connect(function(_, parent) if not parent then eggCache[obj] = nil end end)
	end
end

for _, obj in ipairs(Workspace:GetDescendants()) do trackObject(obj) end
Workspace.DescendantAdded:Connect(trackObject)

-- ==========================================
-- CORE LOOP
-- ==========================================
task.spawn(function()
	while true do
		if Settings.Enabled then
			pcall(function()
				local processedItem = false
				
				-- 1. Buy/Harvest Seeds
				for prompt in pairs(seedCache) do
					if not Settings.Enabled then break end
					if prompt and prompt.Parent then
						if firePrompt(prompt) then
							processedItem = true
							task.wait(0.1)
						end
					end
				end
				
				-- 2. Buy/Hatch Eggs
				if Settings.BuyEggs and Settings.Enabled then
					for prompt in pairs(eggCache) do
						if not Settings.Enabled then break end
						if prompt and prompt.Parent then
							if firePrompt(prompt) then
								processedItem = true
								task.wait(0.1)
							end
						end
					end
				end
				
				-- 3. Pull Lever
				if not processedItem and Settings.Enabled then
					local pulledLever = false
					for prompt in pairs(leverCache) do
						if not Settings.Enabled then break end
						if prompt and prompt.Parent then
							if firePrompt(prompt) then
								pulledLever = true
								break 
							end
						end
					end
					
					if pulledLever then
						for i = 1, Settings.LeverCooldown * 10 do
							if not Settings.Enabled then break end
							task.wait(0.1)
						end
					end
				end
			end)
		end
		task.wait(Settings.CheckInterval)
	end
end)

-- ==========================================
-- INTEGRATED UI CONSTRUCTION
-- ==========================================
local oldGui = LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("BarfAFKGui")
if oldGui then oldGui:Destroy() end

local ScreenGui_1 = Instance.new("ScreenGui")
ScreenGui_1.Name = "BarfAFKGui"
ScreenGui_1.ResetOnSpawn = false
ScreenGui_1.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local TopBar_2 = Instance.new("Frame")
TopBar_2.Name = "TopBar"
TopBar_2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
TopBar_2.BorderSizePixel = 0
TopBar_2.Position = UDim2.new(0.35, 0, 0.3, 0)
TopBar_2.Size = UDim2.new(0, 418, 0, 44)
TopBar_2.Parent = ScreenGui_1

local UICorner_3 = Instance.new("UICorner")
UICorner_3.CornerRadius = UDim.new(0, 12)
UICorner_3.Parent = TopBar_2

local UIGradient_5 = Instance.new("UIGradient")
UIGradient_5.Rotation = 90
UIGradient_5.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(111, 0, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(101, 0, 225))
})
UIGradient_5.Parent = TopBar_2

local UIStroke_6 = Instance.new("UIStroke")
UIStroke_6.Color = Color3.fromRGB(20, 13, 29)
UIStroke_6.Thickness = 3
UIStroke_6.Parent = TopBar_2

local TextLabel_4 = Instance.new("TextLabel")
TextLabel_4.Size = UDim2.new(1, 0, 1, 0)
TextLabel_4.BackgroundTransparency = 1
TextLabel_4.Font = Enum.Font.FredokaOne
TextLabel_4.Text = "barf AFK script"
TextLabel_4.TextColor3 = Color3.fromRGB(235, 225, 255)
TextLabel_4.TextSize = 22
TextLabel_4.Parent = TopBar_2

local Main_7 = Instance.new("Frame")
Main_7.Name = "Main"
Main_7.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Main_7.BorderSizePixel = 0
Main_7.Position = UDim2.new(0, 0, 1, 6)
Main_7.Size = UDim2.new(0, 418, 0, 227)
Main_7.Parent = TopBar_2

local UICorner_8 = Instance.new("UICorner")
UICorner_8.CornerRadius = UDim.new(0, 12)
UICorner_8.Parent = Main_7

local UIGradient_9 = Instance.new("UIGradient")
UIGradient_9.Rotation = 90
UIGradient_9.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(101, 0, 225)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(35, 10, 60))
})
UIGradient_9.Parent = Main_7

local UIStroke_10 = Instance.new("UIStroke")
UIStroke_10.Color = Color3.fromRGB(20, 13, 29)
UIStroke_10.Thickness = 3
UIStroke_10.Parent = Main_7

local Seperator_11 = Instance.new("Frame")
Seperator_11.Name = "Seperator"
Seperator_11.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Seperator_11.Position = UDim2.new(0.5, 0, 0.05, 0)
Seperator_11.Size = UDim2.new(0, 2, 0.9, 0)
Seperator_11.Parent = Main_7

local UIStroke_12 = Instance.new("UIStroke")
UIStroke_12.Color = Color3.fromRGB(20, 13, 29)
UIStroke_12.Thickness = 1
UIStroke_12.Parent = Seperator_11

-- Smooth Dragging Mechanism
local dragging, dragInput, dragStart, startPos
TopBar_2.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startPos = TopBar_2.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then dragging = false end
		end)
	end
end)
TopBar_2.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
end)
UserInputService.InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		local delta = input.Position - dragStart
		TopBar_2.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

-- Main Toggle Button
local FarmToggle = Instance.new("TextButton")
FarmToggle.Name = "FarmToggle"
FarmToggle.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
FarmToggle.Position = UDim2.new(0.04, 0, 0.08, 0)
FarmToggle.Size = UDim2.new(0, 180, 0, 130)
FarmToggle.Font = Enum.Font.FredokaOne
FarmToggle.Text = "FARM STATUS\n\nOFF"
FarmToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
FarmToggle.TextSize = 20
FarmToggle.Parent = Main_7

local FarmCorner = Instance.new("UICorner")
FarmCorner.CornerRadius = UDim.new(0, 10)
FarmCorner.Parent = FarmToggle

local FarmStroke = Instance.new("UIStroke")
FarmStroke.Color = Color3.fromRGB(20, 13, 29)
FarmStroke.Thickness = 2
FarmStroke.Parent = FarmToggle

FarmToggle.MouseButton1Click:Connect(function()
	Settings.Enabled = not Settings.Enabled
	if Settings.Enabled then
		FarmToggle.BackgroundColor3 = Color3.fromRGB(40, 180, 80)
		FarmToggle.Text = "FARM STATUS\n\nRUNNING"
	else
		FarmToggle.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
		FarmToggle.Text = "FARM STATUS\n\nOFF"
	end
end)

-- Egg Toggle Button
local EggToggle = Instance.new("TextButton")
EggToggle.Name = "EggToggle"
EggToggle.BackgroundColor3 = Color3.fromRGB(60, 40, 80)
EggToggle.Position = UDim2.new(0.04, 0, 0.72, 0)
EggToggle.Size = UDim2.new(0, 180, 0, 45)
EggToggle.Font = Enum.Font.FredokaOne
EggToggle.Text = "BUY EGGS: OFF"
EggToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
EggToggle.TextSize = 15
EggToggle.Parent = Main_7

local EggCorner = Instance.new("UICorner")
EggCorner.CornerRadius = UDim.new(0, 8)
EggCorner.Parent = EggToggle

local EggStroke = Instance.new("UIStroke")
EggStroke.Color = Color3.fromRGB(20, 13, 29)
EggStroke.Thickness = 2
EggStroke.Parent = EggToggle

EggToggle.MouseButton1Click:Connect(function()
	Settings.BuyEggs = not Settings.BuyEggs
	if Settings.BuyEggs then
		EggToggle.BackgroundColor3 = Color3.fromRGB(0, 150, 200)
		EggToggle.Text = "BUY EGGS: ON"
	else
		EggToggle.BackgroundColor3 = Color3.fromRGB(60, 40, 80)
		EggToggle.Text = "BUY EGGS: OFF"
	end
end)

-- Controls Container
local PropertiesFrame = Instance.new("Frame")
PropertiesFrame.Name = "Properties"
PropertiesFrame.BackgroundTransparency = 1
PropertiesFrame.Position = UDim2.new(0.54, 0, 0.05, 0)
PropertiesFrame.Size = UDim2.new(0, 180, 0, 200)
PropertiesFrame.Parent = Main_7

local ListLayout = Instance.new("UIListLayout")
ListLayout.Padding = UDim.new(0, 10)
ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
ListLayout.Parent = PropertiesFrame

local function createModifierBox(labelText, defaultValue, minVal, maxVal, onChange)
	local Container = Instance.new("Frame")
	Container.Size = UDim2.new(1, 0, 0, 52)
	Container.BackgroundColor3 = Color3.fromRGB(30, 15, 45)
	Container.Parent = PropertiesFrame
	
	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 6)
	Corner.Parent = Container

	local Stroke = Instance.new("UIStroke")
	Stroke.Color = Color3.fromRGB(20, 13, 29)
	Stroke.Thickness = 1.5
	Stroke.Parent = Container

	local Label = Instance.new("TextLabel")
	Label.Size = UDim2.new(1, -10, 0, 22)
	Label.Position = UDim2.new(0, 5, 0, 2)
	Label.BackgroundTransparency = 1
	Label.Font = Enum.Font.FredokaOne
	Label.Text = labelText
	Label.TextColor3 = Color3.fromRGB(200, 190, 220)
	Label.TextSize = 13
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.Parent = Container

	local Input = Instance.new("TextBox")
	Input.Size = UDim2.new(1, -10, 0, 20)
	Input.Position = UDim2.new(0, 5, 0, 26)
	Input.BackgroundColor3 = Color3.fromRGB(15, 8, 25)
	Input.Font = Enum.Font.SourceSansBold
	Input.Text = tostring(defaultValue)
	Input.TextColor3 = Color3.fromRGB(255, 255, 255)
	Input.TextSize = 14
	Input.Parent = Container

	local InputCorner = Instance.new("UICorner")
	InputCorner.CornerRadius = UDim.new(0, 4)
	InputCorner.Parent = Input

	Input.FocusLost:Connect(function()
		local num = tonumber(Input.Text)
		if num then
			num = math.clamp(num, minVal, maxVal)
			Input.Text = tostring(num)
			onChange(num)
		else
			Input.Text = tostring(defaultValue)
		end
	end)
end

createModifierBox("Scan Interval (s)", Settings.CheckInterval, 0.05, 5, function(val)
	Settings.CheckInterval = val
end)

createModifierBox("Lever Delay (s)", Settings.LeverCooldown, 1, 300, function(val)
	Settings.LeverCooldown = val
end)

createModifierBox("Flight Height", Settings.TeleportHeight, 1, 30, function(val)
	Settings.TeleportHeight = val
end)

ScreenGui_1.Parent = LocalPlayer:WaitForChild("PlayerGui")
