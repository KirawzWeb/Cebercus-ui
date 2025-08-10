local TweenService = game:GetService("TweenService")

local Checkbox = {}
Checkbox.__index = Checkbox

type t = {
	Name: string,
	Callback: (boolean) -> nil,
	Default: boolean?,
	Debounce: number?,
	Flag: string,
}

function Checkbox.new(section: any, data: t)
	local self = setmetatable({}, Checkbox)
	self.section = section

	self.frame = section.Templates.Checkbox:Clone()
	self.activator = self.frame.activator
	self.checkBoxImage = self.activator.icon
	self.label = self.frame.title
	self.button = self.frame.button

	self.callback = data.Callback or function() end
	self.enabled = false
	self.canClick = true
	self.debounce = data.Debounce or 0.3
	self.Flag = data.Flag

	self.label.Text = data.Name or "NO NAME PROVIDED"

	self:_init()
	self.frame.Parent = section.frame

	local savedValue = section:GetSavedValue(data.Flag)
	self:SetValue(savedValue ~= nil and savedValue or data.Default, savedValue ~= nil)

	return self
end

function Checkbox:_init()
	self.button.MouseButton1Click:Connect(function()
		if not self.canClick then return end
		self.canClick = false

		self:SetValue(not self.enabled)

		task.wait(self.debounce)
		self.canClick = true
	end)
end

function Checkbox:SetValue(value: boolean, loadSavedValue: boolean)
	self.enabled = value

	local tweenInfo = TweenInfo.new(0.2)

	TweenService:Create(self.activator, tweenInfo, {
		BackgroundColor3 = self.enabled and Color3.fromRGB(248, 72, 4) or Color3.fromRGB(22, 22, 22)
	}):Play()

	TweenService:Create(self.checkBoxImage, tweenInfo, {
		ImageTransparency = self.enabled and 0 or 1
	}):Play()

	if not loadSavedValue then
		self.section:Save(self.Flag, self.enabled)
	end

	task.spawn(function()
		local success, error = pcall(self.callback, self.enabled)
		if not success then
			warn("Checkbox callback error:", error)
		end
	end)
end

function Checkbox:SetName(newName: string)
	self.label.Text = newName
end

function Checkbox:SetCallback(newCallback: (boolean) -> nil)
	self.callback = newCallback
end

return Checkbox