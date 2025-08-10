local TweenService = game:GetService("TweenService")

local Button = {}
Button.__index = Button

type t = {
	Name: string,
	Callback: () -> nil,
	Debounce: number?
}

function Button.new(section: any, data: t)
	local self = setmetatable({}, Button)

	self.frame = section.Templates.Button:Clone()
	self.activator = self.frame.activator
	self.label = self.activator.title
	self.button = self.activator.button

	self.label.Text = data.Name or "NO NAME PROVIDED"
	self.callback = data.Callback or function() end
	self.debounce = data.Debounce or 0.3
	self.canClick = true

	self:_init()
	self.frame.Parent = section.frame

	return self
end

function Button:_init()
	self.button.MouseButton1Click:Connect(function()
		if not self.canClick then return end
		self.canClick = false

		self:_playClickAnimation()

		task.spawn(function()
			local success, error = pcall(self.callback)
			if not success then
				warn("Button callback error:", error)
			end
		end)

		task.wait(self.debounce)
		self.canClick = true
	end)
end

function Button:_playClickAnimation()
	local tweenInfo = TweenInfo.new(0.1)

	local tween = TweenService:Create(self.activator, tweenInfo, {
		BackgroundColor3 = Color3.fromRGB(27, 27, 27)
	})

	tween.Completed:Once(function()
		TweenService:Create(self.activator, tweenInfo, {
			BackgroundColor3 = Color3.fromRGB(18, 18, 18)
		}):Play()
	end)

	tween:Play()
end

function Button:SetName(newName: string)
	self.label.Text = newName
end

function Button:SetCallback(newCallback: () -> nil)
	self.callback = newCallback
end

return Button