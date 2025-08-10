local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local Slider = {}
Slider.__index = Slider

type t = {
	Name: string,
	Range: {number},
	Default: number,
	Callback: (number) -> nil,
	MaxDecimals: number?,
	Flag: string?
}

function Slider.new(section: any, data: t)
	local self = setmetatable({
		section = section
	}, Slider)

	self.frame = section.Templates.Slider:Clone()
	self.title = self.frame.title
	self.bar = self.frame.bar
	self.filler = self.bar.fill
	self.barButton = self.bar.button
	self.fillPointStroke = self.filler.point.UIStroke
	self.textbox = self.frame.valueFrame.Textbox

	self.maxDecimals = data.MaxDecimals or 0
	self.range = data.Range
	self.minValue = self.range[1] or 0
	self.maxValue = self.range[2] or 100
	self.value = data.Default or self.maxValue / 2
	self.callback = data.Callback or function() end
	self.Flag = data.Flag

	self.title.Text = data.Name
	self.frame.Name = `{data.Name}_Slider`

	self:_init()
	self.frame.Parent = section.frame

	local savedValue = section:GetSavedValue(data.Flag)
	self:SetValue(savedValue ~= nil and savedValue or self.value, savedValue ~= nil)

	return self
end

function Slider:_init()
	local mouse = game:GetService("Players").LocalPlayer:GetMouse()
	local dragging = false
	local conn

	local function updateValue(input)
		if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end

		local mousePos = input.Position
		local framePos = self.bar.AbsolutePosition
		local frameSize = self.bar.AbsoluteSize.X

		local percent = math.clamp((mousePos.X - framePos.X) / frameSize, 0, 1)
		self:SetValue(self.minValue + (percent * (self.maxValue - self.minValue)))
	end

	self.barButton.MouseButton1Down:Connect(function()
		if dragging then return end
		dragging = true

		TweenService:Create(self.fillPointStroke, TweenInfo.new(0.1), { Thickness = 6 }):Play()

		conn = UserInputService.InputChanged:Connect(updateValue)
		updateValue({
			UserInputType = Enum.UserInputType.MouseMovement,
			Position = Vector2.new(mouse.X, mouse.Y)
		})
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
		if not dragging then return end

		dragging = false
		if conn then conn:Disconnect() end

		TweenService:Create(self.fillPointStroke, TweenInfo.new(0.1), { Thickness = 0 }):Play()
	end)

	self.textbox.FocusLost:Connect(function()
		local newValue = tonumber(self.textbox.Text) or self.value
		self:SetValue(newValue)
	end)
end

function Slider:SetValue(newValue: number, loadSavedValue: boolean)
	local factor = 10 ^ self.maxDecimals
	newValue = math.clamp(
		math.floor(newValue * factor) / factor,
		self.minValue,
		self.maxValue
	)

	if self.value == newValue then return end
	self.value = newValue

	self:_updateVisuals()

	task.spawn(function()
		local success, error = pcall(self.callback, self.value)
		if not success then
			warn("Slider callback error:", error)
		end
	end)


	if loadSavedValue then return end
	self.section:Save(self.Flag, self.value)
end

function Slider:_updateVisuals()
	local percent = ((self.value - self.minValue) / (self.maxValue - self.minValue))
	local fillSize = UDim2.new(math.max(percent, 0.03), 0, 1, 0)

	self.textbox.Text = tostring(self.value)
	TweenService:Create(self.filler, TweenInfo.new(0.2), {
		Size = fillSize
	}):Play()
end

function Slider:SetName(newName: string)
	self.title.Text = newName
end

function Slider:SetCallback(newCallback: (number) -> nil)
	self.callback = newCallback
end

return Slider