--[[ 
	2dev - Blade Ball - Version 1.4.2
	Author: morwan
	Discord: https://discord.gg/HKrSg8vR
	Status: Undetected until 10/04/25
	Release: 07/04/25
]]

-- CONFIG
local ReactionTime = 0.20 -- tempo inicial padrão

-- SERVIÇOS
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local AutoParryEnabled, AutoParryHackEnabled, AntiCurvesEnabled, AntiSlowEnabled = false, false, false, false
local Parried, Cooldown, Connection, Open = false, 0, nil, true

-- FUNÇÕES
local function GetBall()
	for _, Ball in ipairs(Workspace.Balls:GetChildren()) do
		if Ball:GetAttribute("realBall") then return Ball end
	end
end

local function ResetConnection()
	if Connection then Connection:Disconnect() Connection = nil end
end

Workspace.Balls.ChildAdded:Connect(function()
	local Ball = GetBall()
	if not Ball then return end
	ResetConnection()
	Connection = Ball:GetAttributeChangedSignal("target"):Connect(function()
		Parried = false
	end)
end)

-- IA de previsão
local function PredictImpactTime(Ball, HRP)
	local Velocity = Ball.zoomies.VectorVelocity
	local Direction = Velocity.Unit
	local Distance = (HRP.Position - Ball.Position).Magnitude
	local RelativeSpeed = Velocity.Magnitude
	if RelativeSpeed == 0 then return math.huge end
	return Distance / RelativeSpeed
end

-- AUTO PARRY LEGIT COM IA
RunService.PreSimulation:Connect(function()
	if not AutoParryEnabled then return end
	local Ball = GetBall()
	local HRP = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
	if not Ball or not HRP then return end

	local Speed = Ball.zoomies.VectorVelocity.Magnitude
	local Distance = (HRP.Position - Ball.Position).Magnitude
	local Frozen = Ball:GetAttribute("frozen") or false
	local Target = Ball:GetAttribute("target")
	local Ignore = AntiSlowEnabled and (Frozen or Ball:GetAttribute("slow") or Ball:GetAttribute("slowed"))
	local IsFrozen = not AntiSlowEnabled and Frozen

	if Target == Player.Name and not Parried and not IsFrozen then
		local impactTime = PredictImpactTime(Ball, HRP)
		if impactTime <= ReactionTime or Ignore or (Distance < 10 and Speed > 120) then
			VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
			Parried = true
			Cooldown = tick()
		end
	end

	if tick() - Cooldown >= 1 then
		Parried = false
	end
end)

-- AUTO PARRY HACK
RunService.Heartbeat:Connect(function()
	if not AutoParryHackEnabled then return end
	local Ball = GetBall()
	local HRP = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
	if not Ball or not HRP then return end

	local Target = Ball:GetAttribute("target")
	local Speed = Ball.zoomies.VectorVelocity.Magnitude
	local Distance = (HRP.Position - Ball.Position).Magnitude
	local Ignore = AntiSlowEnabled and (Ball:GetAttribute("frozen") or Ball:GetAttribute("slow") or Ball:GetAttribute("slowed"))
	local IsFrozen = not AntiSlowEnabled and Ball:GetAttribute("frozen")

	if Target == Player.Name and not IsFrozen and Distance < 60 and Speed >= 100 then
		VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
	end
end)

-- ANTI CURVES
RunService.Heartbeat:Connect(function()
	if not (AutoParryHackEnabled or AutoParryEnabled) or not AntiCurvesEnabled then return end
	local Ball = GetBall()
	if Ball and Ball:FindFirstChild("Curve") then Ball:Destroy() end
end)

-- UI
local function CreateUI()
	local Gui = Instance.new("ScreenGui", game.CoreGui)
	Gui.Name = "TwoDevUI"
	Gui.ResetOnSpawn = false

	local Frame = Instance.new("Frame", Gui)
	Frame.Size = UDim2.new(0, 300, 0, 250)
	Frame.Position = UDim2.new(0.5, -150, 0.5, -125)
	Frame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
	Frame.BackgroundTransparency = 0.4
	Frame.BorderSizePixel = 0
	Frame.Visible = true
	Frame.Active = true
	Frame.Draggable = true

	local Title = Instance.new("TextLabel", Frame)
	Title.Size = UDim2.new(1, 0, 0, 30)
	Title.Text = "2dev - Blade Ball"
	Title.TextColor3 = Color3.new(1, 1, 1)
	Title.BackgroundTransparency = 1
	Title.Font = Enum.Font.GothamBold
	Title.TextSize = 18

	local Status = Instance.new("TextLabel", Frame)
	Status.Size = UDim2.new(1, -10, 0, 20)
	Status.Position = UDim2.new(0, 5, 1, -20)
	Status.Text = "Release: 07/04/25 | ✅ Safe until 10/04/25"
	Status.TextColor3 = Color3.fromRGB(0, 255, 0)
	Status.BackgroundTransparency = 1
	Status.Font = Enum.Font.Gotham
	Status.TextSize = 12
	Status.TextXAlignment = Enum.TextXAlignment.Left

	local function AddToggle(text, posY, getState, setState)
		local Btn = Instance.new("TextButton", Frame)
		Btn.Size = UDim2.new(1, -20, 0, 30)
		Btn.Position = UDim2.new(0, 10, 0, posY)
		Btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		Btn.TextColor3 = Color3.new(1, 1, 1)
		Btn.Font = Enum.Font.Gotham
		Btn.TextSize = 14

		local function Update()
			Btn.Text = (getState() and "✅ " or "❌ ") .. text
		end

		Btn.MouseButton1Click:Connect(function()
			setState(not getState())
			Update()
		end)

		Update()
	end

	AddToggle("Auto Parry Legit", 40, function() return AutoParryEnabled end, function(v) AutoParryEnabled = v end)
	AddToggle("Auto Parry Hack", 80, function() return AutoParryHackEnabled end, function(v) AutoParryHackEnabled = v end)
	AddToggle("Anti Curves", 120, function() return AntiCurvesEnabled end, function(v) AntiCurvesEnabled = v end)
	AddToggle("Anti Slow", 160, function() return AntiSlowEnabled end, function(v) AntiSlowEnabled = v end)

	-- Slider Reaction Time
	local Slider = Instance.new("TextLabel", Frame)
	Slider.Position = UDim2.new(0, 10, 0, 200)
	Slider.Size = UDim2.new(1, -20, 0, 20)
	Slider.Text = "Reaction Time: " .. ReactionTime
	Slider.TextColor3 = Color3.new(1, 1, 1)
	Slider.BackgroundTransparency = 1
	Slider.TextSize = 14

	local Increase, Decrease = Instance.new("TextButton", Frame), Instance.new("TextButton", Frame)
	Increase.Size, Decrease.Size = UDim2.new(0, 30, 0, 20), UDim2.new(0, 30, 0, 20)
	Increase.Position = UDim2.new(1, -35, 0, 200)
	Decrease.Position = UDim2.new(0, 5, 0, 200)
	Increase.Text, Decrease.Text = "+", "-"
	Increase.Font, Decrease.Font = Enum.Font.GothamBold, Enum.Font.GothamBold
	Increase.BackgroundColor3, Decrease.BackgroundColor3 = Color3.fromRGB(30,30,30), Color3.fromRGB(30,30,30)
	Increase.TextColor3, Decrease.TextColor3 = Color3.new(1,1,1), Color3.new(1,1,1)

	Increase.MouseButton1Click:Connect(function()
		ReactionTime = math.min(1, ReactionTime + 0.05)
		Slider.Text = "Reaction Time: " .. string.format("%.2f", ReactionTime)
	end)
	Decrease.MouseButton1Click:Connect(function()
		ReactionTime = math.max(0.05, ReactionTime - 0.05)
		Slider.Text = "Reaction Time: " .. string.format("%.2f", ReactionTime)
	end)

	return Frame
end

local MainUI = CreateUI()

-- TOGGLE UI
UIS.InputBegan:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.PageUp then
		Open = not Open
		MainUI.Visible = Open
	end
end)

-- OTIMIZAÇÃO
local function OptimizeGame()
	for _, v in ipairs(Workspace:GetDescendants()) do
		if v:IsA("BasePart") and v.Name:lower():match("tree") then v:Destroy()
		elseif v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") then v:Destroy()
		elseif v:IsA("Model") and v.Name:lower():match("effect") then v:Destroy() end
	end
	Lighting.GlobalShadows = false
end

OptimizeGame()
