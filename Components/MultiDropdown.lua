local TweenService = game:GetService("TweenService")

local MultiDropdown = {}
MultiDropdown.__index = MultiDropdown

type t = {
	Name: string,
	Options: {[string]: boolean},
	Callback: ((table) -> nil)
}

function MultiDropdown.new(section: any, data: t)
	local self = setmetatable({}, MultiDropdown)
	
	self.Templates = section.Templates
	self.frame = section.Templates.Dropdown:Clone()
	self.title = self.frame.title
	self.canvas = self.frame.canvas
	self.choiceLabel = self.canvas.title
	self.openButton = self.choiceLabel.button
	self.dropdownIcon = self.choiceLabel.icon
	self.list = self.canvas.list

	self.callback = data.Callback or function() end
	self.optionFrames = {}
	self.selectedOptions = {}
	self.canOpen = true
	self.opened = false
	self.listYOffset = 5

	self.title.Text = data.Name or "NO NAME PROVIDED"

	self:_init()
	self:SetOptions(data.Options)
	self.frame.Parent = section.frame

	return self
end

function MultiDropdown:_init()
	self.openButton.MouseButton1Click:Connect(function()
		if not self.canOpen then return end
		self.canOpen = false

		self:SetState(not self.opened)

		task.wait(0.3)
		self.canOpen = true
	end)
end

function MultiDropdown:_createOption(index: string, optionName: string, optionCurrentValue: boolean)
	local frame = self.Templates.dropdownElement:Clone()

	local function MouseButtonClicked1()
		local tweenInfo = TweenInfo.new(0.2)

		self.selectedOptions[optionName] = not self.selectedOptions[optionName]

		local choiceStr = "NONE"
		local selectedOptions = {}

		for _optionName, optionFrame in self.optionFrames do
			local selected = self.selectedOptions[_optionName]

			TweenService:Create(optionFrame.UIStroke, tweenInfo, {
				Transparency = selected and 0.36 or 1
			}):Play()

			TweenService:Create(optionFrame.text, tweenInfo, {
				TextColor3 = selected and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(149, 149, 149)
			}):Play()

			if selected then
				table.insert(selectedOptions, _optionName)
			end
		end

		choiceStr = #selectedOptions > 0 and table.concat(selectedOptions, ", ") or "NONE"

		frame.text.Text = optionName
		self.choiceLabel.Text = choiceStr

		task.wait(0.2)

		task.spawn(function()
			local success, error = pcall(self.callback, self.selectedOptions)
			if not success then
				warn("MultiDropdown callback error:", error)
			end
		end)
	end

	frame.MouseButton1Click:Connect(MouseButtonClicked1)

	if optionCurrentValue then
		task.spawn(MouseButtonClicked1)
	end

	frame.text.Text = optionName
	self.optionFrames[optionName] = frame

	frame.Name = index
	frame.Parent = self.list
end

function MultiDropdown:SetOptions(newOptions: {[string]: boolean})
	for _, frame in self.optionFrames do
		frame:Destroy()
	end

	self.selectedOptions = {}
	self.listYOffset = 5

	for index, option in pairs(newOptions) do
		local optionName = type(index) == "number" and tostring(option) or index
		local optionValue = type(index) == "number" and true or option

		self.listYOffset += 24 + 5

		local optionName, value = option[1], option[2]
		self:_createOption(tostring(index), optionName, optionValue)
	end

	if self.opened then
		TweenService:Create(self.list, TweenInfo.new(0.2), {
			Size = UDim2.new(1, 0, 0, self.listYOffset)
		}):Play()
	end
end

function MultiDropdown:SetState(isOpened: boolean)
	self.opened = isOpened

	local tweenInfo = TweenInfo.new(0.2)
	local newListY = self.opened and self.listYOffset or -10

	if not self.opened then
		self:_setOptionVisibility(false)
	end

	local tween = TweenService:Create(self.list, tweenInfo, {
		Size = UDim2.new(1, 0, 0, newListY)
	})

	TweenService:Create(self.dropdownIcon, tweenInfo, {
		Rotation = self.opened and 0 or 90
	}):Play()

	tween.Completed:Once(function()
		self.list.Visible = self.opened

		if self.opened then
			self:_setOptionVisibility(true)
		end
	end)

	self.list.Visible = true
	tween:Play()
end

function MultiDropdown:_setOptionVisibility(visible: boolean)
	local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Linear)

	for optionName, frame in self.optionFrames do
		TweenService:Create(frame, tweenInfo, { 
			BackgroundTransparency = visible and 0 or 1 
		}):Play()
		TweenService:Create(frame.text, tweenInfo, { 
			TextTransparency = visible and 0 or 1 
		}):Play()
		TweenService:Create(frame.UIStroke, tweenInfo, { 
			Transparency = visible and (self.selectedOptions[optionName] and 0.36 or 1) or 1 
		}):Play()
	end

	task.wait(0.3)
end

return MultiDropdown