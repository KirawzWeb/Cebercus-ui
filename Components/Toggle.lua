local TweenService = game:GetService("TweenService")

local Toggle = {}
Toggle.__index = Toggle

type t = {
	Name: string,
	Callback: (boolean) -> nil,
	Default: boolean,
	Debounce: number?,
	Flag: string,
}

function Toggle.new(section: any, data: t)
	local self = setmetatable({
		section = section
	}, Toggle)

	self.frame = section.Templates.Toggle:Clone()
	self.round = self.frame.round
	self.circle = self.round.circle
	self.title = self.frame.title
	self.button = self.frame.button

	self.callback = data.Callback or function() end
	self.enabled = false
	self.canClick = true
	self.debounce = data.Debounce or 0.3
	self.Flag = data.Flag

	self.title.Text = data.Name or "NO NAME PROVIDED"

	self:_init()
	self.frame.Parent = section.frame

	local savedValue = section:GetSavedValue(data.Flag)
	self:SetValue(savedValue ~= nil and savedValue or data.Default, savedValue ~= nil)

	return self
end

function Toggle:_init()
	self.button.MouseButton1Click:Connect(function()
		if not self.canClick then return end
		self.canClick = false

		self:SetValue(not self.enabled)

		task.wait(self.debounce)
		self.canClick = true
	end)
end

function Toggle:SetValue(value: boolean, loadSavedValue: boolean)
	if self.enabled == value then
		return
	end

	self.enabled = value

	local tweenInfo = TweenInfo.new(0.2)

	TweenService:Create(self.round, tweenInfo, {
		ImageColor3 = self.enabled and Color3.fromRGB(248, 72, 3) or Color3.fromRGB(18, 18, 18)
	}):Play()

	TweenService:Create(self.circle, tweenInfo, {
		Position = self.enabled and UDim2.new(0, 22, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
	}):Play()

	if not loadSavedValue then
		self.section:Save(self.Flag, self.enabled)
	end

	task.spawn(function()
		local success, error = pcall(self.callback, self.enabled)
		if not success then
			warn("Toggle callback error:", error)
		end
	end)
end

return Toggle