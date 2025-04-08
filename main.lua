--[[
	2dev - Blade Ball v1.5
	Autor: morwan | Discord: https://discord.gg/HKrSg8vR
	Lançamento: 07/04/25 | Indetectável até: 10/04/25
]]

local RS, VIM, Plrs, WS, Lgt, Tween, UIS = game:GetService("RunService"), game:GetService("VirtualInputManager"), game:GetService("Players"), game:GetService("Workspace"), game:GetService("Lighting"), game:GetService("TweenService"), game:GetService("UserInputService")
local LP, AutoParry, HackParry, AntiCurves, AntiSlow, Parried, CD, Conn, Open, ReactionTime = Plrs.LocalPlayer, false, false, false, false, false, 0, nil, true, 0.35

local function GetBall()
	for _, b in ipairs(WS.Balls:GetChildren()) do if b:GetAttribute("realBall") then return b end end
end

local function ResetConn()
	if Conn then Conn:Disconnect(); Conn = nil end
end

WS.Balls.ChildAdded:Connect(function()
	local b = GetBall()
	if not b then return end
	ResetConn()
	Conn = b:GetAttributeChangedSignal("target"):Connect(function() Parried = false end)
end)

RS.PreSimulation:Connect(function()
	if not AutoParry then return end
	local b, HRP = GetBall(), LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
	if not b or not HRP then return end

	local speed, dist = b.zoomies.VectorVelocity.Magnitude, (HRP.Position - b.Position).Magnitude
	local target, frozen = b:GetAttribute("target"), b:GetAttribute("frozen") or false
	local ignoreFreeze = AntiSlow and (frozen or b:GetAttribute("slow") or b:GetAttribute("slowed"))
	if target == LP.Name and not Parried and (not frozen or ignoreFreeze) then
		if dist / speed <= ReactionTime or (dist < 8 and speed >= 150) then
			VIM:SendMouseButtonEvent(0, 0, 0, true, game, 0)
			wait(dist < 8 and 0.05 or 0)
			VIM:SendMouseButtonEvent(0, 0, 0, true, game, 0)
			Parried, CD = true, tick()
		end
	end
	if tick() - CD >= 1 then Parried = false end
end)

RS.Heartbeat:Connect(function()
	if not HackParry then return end
	local b, HRP = GetBall(), LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
	if not b or not HRP then return end

	local speed, dist, target = b.zoomies.VectorVelocity.Magnitude, (HRP.Position - b.Position).Magnitude, b:GetAttribute("target")
	local frozen, ignoreFreeze = b:GetAttribute("frozen") or false, AntiSlow and (b:GetAttribute("frozen") or b:GetAttribute("slow") or b:GetAttribute("slowed"))
	if target == LP.Name and (not frozen or ignoreFreeze) and dist < 60 and speed >= 100 then
		VIM:SendMouseButtonEvent(0, 0, 0, true, game, 0)
	end
end)

RS.Heartbeat:Connect(function()
	if (AutoParry or HackParry) and AntiCurves then
		local b = GetBall()
		if b and b:FindFirstChild("Curve") then b:Destroy() end
	end
end)

local function Optimize()
	for _, v in ipairs(WS:GetDescendants()) do
		if v:IsA("BasePart") and v.Name:lower():find("tree") then v:Destroy()
		elseif v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") then v:Destroy()
		elseif v:IsA("Model") and v.Name:lower():find("effect") then v:Destroy() end
	end
	Lgt.GlobalShadows = false
end

local function CreateUI()
	local Gui = Instance.new("ScreenGui", game.CoreGui)
	Gui.Name, Gui.ResetOnSpawn = "TwoDevUI", false
	local Frame = Instance.new("Frame", Gui)
	Frame.Size, Frame.Position = UDim2.new(0, 400, 0, 300), UDim2.new(0.5, -200, 0.5, -150)
	Frame.BackgroundColor3, Frame.BackgroundTransparency = Color3.fromRGB(0, 0, 0), 0.4
	Frame.Draggable, Frame.Active = true, true

	local function AddBtn(txt, y, cb)
		local Btn = Instance.new("TextButton", Frame)
		Btn.Size, Btn.Position = UDim2.new(0, 180, 0, 30), UDim2.new(0, 10, 0, y)
		Btn.Text, Btn.Font, Btn.TextSize, Btn.BackgroundColor3 = txt, Enum.Font.GothamBold, 14, Color3.fromRGB(20, 150, 255)
		Btn.TextColor3 = Color3.new(1, 1, 1)
		Btn.MouseButton1Click:Connect(cb)
		return Btn
	end

	local Legit = AddBtn("🟢 Auto Parry Legit", 10, function()
		AutoParry = not AutoParry
		Legit.Text = AutoParry and "🟢 Auto Parry Legit" or "🔴 Auto Parry Legit"
	end)

	local Hack = AddBtn("🔴 Hack Parry", 50, function()
		HackParry = not HackParry
		Hack.Text = HackParry and "🟢 Hack Parry" or "🔴 Hack Parry"
	end)

	local Anti = AddBtn("🔴 Anti Curves", 90, function()
		AntiCurves = not AntiCurves
		Anti.Text = AntiCurves and "🟢 Anti Curves" or "🔴 Anti Curves"
	end)

	local Slow = AddBtn("🔴 Anti Slow", 130, function()
		AntiSlow = not AntiSlow
		Slow.Text = AntiSlow and "🟢 Anti Slow" or "🔴 Anti Slow"
	end)

	local sliderLbl = Instance.new("TextLabel", Frame)
	sliderLbl.Position, sliderLbl.Size = UDim2.new(0, 10, 0, 170), UDim2.new(0, 200, 0, 20)
	sliderLbl.Text, sliderLbl.TextColor3, sliderLbl.BackgroundTransparency = "⏱️ Reação: " .. ReactionTime, Color3.new(1, 1, 1), 1
	sliderLbl.Font, sliderLbl.TextSize = Enum.Font.Gotham, 14

	local slider = Instance.new("TextBox", Frame)
	slider.Position, slider.Size = UDim2.new(0, 10, 0, 190), UDim2.new(0, 50, 0, 20)
	slider.Text, slider.TextSize, slider.BackgroundColor3 = tostring(ReactionTime), 12, Color3.fromRGB(30, 30, 30)
	slider.FocusLost:Connect(function()
		local val = tonumber(slider.Text)
		if val then ReactionTime = math.clamp(val, 0.1, 1) sliderLbl.Text = "⏱️ Reação: " .. ReactionTime end
	end)
end

UIS.InputBegan:Connect(function(i)
	if i.KeyCode == Enum.KeyCode.PageUp then
		Open = not Open
		local UI = game.CoreGui:FindFirstChild("TwoDevUI")
		if UI and UI:FindFirstChildOfClass("Frame") then
			UI.Enabled = Open
		end
	end
end)

Optimize()
CreateUI()
