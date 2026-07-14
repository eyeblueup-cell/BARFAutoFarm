local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Global Settings (Managed by UI)
local Settings = {
	Enabled = false,
	BuyEggs = false,
	CheckInterval = 0.3,
	LeverCooldown = 60,
	TeleportHeight = 5
}

-- Performance Cache
local seedCache = {}
local eggCache = {}
local leverCache = {}

local SEED_NAMES  = { ["BuySeed"] = true, ["HarvestPrompt"] = true }
local EGG_NAMES   = { ["BuyEgg"] = true, ["HatchEgg"] = true, ["RollEgg"] = true, ["EggPrompt"] = true, ["Hatch"] = true, ["Egg"] = true }

-- Forces prompt properties to be usable anywhere
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

-- Universal prompt activator
local function firePrompt(prompt)
	if not Settings.Enabled then return false end
	if not prompt or not prompt.Parent then return false end
	
	local character = LocalPlayer.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	local targetCFrame = getPromptCFrame(prompt)
	
	if rootPart and targetCFrame then
		forceEnablePrompt(prompt)
		
		-- Teleport character directly to prompt
		rootPart.CFrame = targetCFrame * CFrame.new(0, Settings.TeleportHeight, 0)
		task.wait(0.08)
		
		if not Settings.Enabled then return false end

		-- Try all execution methods
		pcall(function()
			if fireproximityprompt then
				fireproximityprompt(prompt)
			end
			prompt:InputHoldBegin()
			task.wait(0.02)
			prompt:InputHoldEnd()
			
			-- Fallback signal fire
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
	if obj.Name == "RollSeeds" then
		return true
	end
	return false
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

-- Core Loop
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
				
				-- 2. Buy/Hatch Eggs (If Enabled)
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
					
					-- Responsive Wait Loop (Breaks immediately if disabled)
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
-- UI DESIGN
-- ==========================================

local oldGui = LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("FarmMenuGui")
if oldGui then oldGui:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FarmMenuGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 300, 0, 280)
MainFrame.Position = UDim2.new(0.05, 0, 0.4, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 35)
Title.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
Title.Text = "  🌾 AFK Farm Panel"
Title.TextColor3 = Color3.fromRGB(240, 240, 240)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 16
Title.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 8)
TitleCorner.Parent = Title

local ListLayout = Instance.new("UIListLayout")
ListLayout.Padding = UDim.new(0, 8)
ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
ListLayout.Parent = MainFrame

local Padding = Instance.new("UIPadding")
Padding.PaddingTop = UDim.new(0, 45)
Padding.Parent = MainFrame

-- Toggle Main Status
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0, 270, 0, 32)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
ToggleBtn.Text = "Farm Status: OFF"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.SourceSansBold
ToggleBtn.TextSize = 14
ToggleBtn.BorderSizePixel = 0
ToggleBtn.Parent = MainFrame

local BtnCorner = Instance.new("UICorner")
BtnCorner.CornerRadius = UDim.new(0, 6)
BtnCorner.Parent = ToggleBtn

ToggleBtn.MouseButton1Click:Connect(function()
	Settings.Enabled = not Settings.Enabled
	if Settings.Enabled then
		ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
		ToggleBtn.Text = "Farm Status: RUNNING"
	else
		ToggleBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
		ToggleBtn.Text = "Farm Status: OFF"
	end
end)

-- Toggle Egg Buying
local EggToggleBtn = Instance.new("TextButton")
EggToggleBtn.Size = UDim2.new(0, 270, 0, 32)
EggToggleBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
EggToggleBtn.Text = "Buy Eggs: OFF"
EggToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
EggToggleBtn.Font = Enum.Font.SourceSansBold
EggToggleBtn.TextSize = 14
EggToggleBtn.BorderSizePixel = 0
EggToggleBtn.Parent = MainFrame

local EggBtnCorner = Instance.new("UICorner")
EggBtnCorner.CornerRadius = UDim.new(0, 6)
EggBtnCorner.Parent = EggToggleBtn

EggToggleBtn.MouseButton1Click:Connect(function()
	Settings.BuyEggs = not Settings.BuyEggs
	if Settings.BuyEggs then
		EggToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 130, 180)
		EggToggleBtn.Text = "Buy Eggs: ON"
	else
		EggToggleBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
		EggToggleBtn.Text = "Buy Eggs: OFF"
	end
end)

local function createSliderRow(labelText, defaultVal, min, max, callback)
	local Row = Instance.new("Frame")
	Row.Size = UDim2.new(0, 270, 0, 30)
	Row.BackgroundTransparency = 1
	Row.Parent = MainFrame

	local Label = Instance.new("TextLabel")
	Label.Size = UDim2.new(0, 150, 1, 0)
	Label.Text = labelText .. ": " .. tostring(defaultVal)
	Label.TextColor3 = Color3.fromRGB(200, 200, 200)
	Label.Font = Enum.Font.SourceSans
	Label.TextSize = 13
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.BackgroundTransparency = 1
	Label.Parent = Row

	local TextBox = Instance.new("TextBox")
	TextBox.Size = UDim2.new(0, 60, 0, 22)
	TextBox.Position = UDim2.new(1, -60, 0.5, -11)
	TextBox.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
	TextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
	TextBox.Text = tostring(defaultVal)
	TextBox.Font = Enum.Font.SourceSans
	TextBox.TextSize = 13
	TextBox.BorderSizePixel = 0
	TextBox.Parent = Row
	
	local boxCorner = Instance.new("UICorner")
	boxCorner.CornerRadius = UDim.new(0, 4)
	boxCorner.Parent = TextBox

	TextBox.FocusLost:Connect(function()
		local val = tonumber(TextBox.Text)
		if val then
			val = math.clamp(val, min, max)
			TextBox.Text = tostring(val)
			Label.Text = labelText .. ": " .. tostring(val)
			callback(val)
		else
			TextBox.Text = tostring(defaultVal)
		end
	end)
end

createSliderRow("Scan Speed (sec)", Settings.CheckInterval, 0.05, 5, function(v) Settings.CheckInterval = v end)
createSliderRow("Lever Wait (sec)", Settings.LeverCooldown, 1, 300, function(v) Settings.LeverCooldown = v end)
createSliderRow("TP Flight Height", Settings.TeleportHeight, 1, 20, function(v) Settings.TeleportHeight = v end)
