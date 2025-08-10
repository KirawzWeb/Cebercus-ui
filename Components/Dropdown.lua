local TweenService = game:GetService("TweenService")

local Dropdown = {}
Dropdown.__index = Dropdown

type t = {
	Name: string,
	Options: {string},
	Default: string,
	Callback: (string) -> nil,
	Flag: string,
}

function Dropdown.new(section: any, data: t)
	local self = setmetatable({
		section = section
	}, Dropdown)

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
	self.canOpen = true
	self.opened = false
	self.selectedOption = nil
	self.listYOffset = 5
	self.Flag = data.Flag

	self.title.Text = data.Name or "NO NAME PROVIDED"

	self:_init()

	local savedValue = section:GetSavedValue(data.Flag)
	self:SetOptions(data.Options, savedValue ~= nil and savedValue or data.Default)

	self.frame.Parent = section.frame

	return self
end

function Dropdown:_init()
	self.openButton.MouseButton1Click:Connect(function()
		if not self.canOpen then return end
		self.canOpen = false

		self:SetState(not self.opened)

		task.wait(0.3)
		self.canOpen = true
	end)
end

function Dropdown:_createOption(indexName: string, displayName: string, option: any, isSelected: boolean)
	local frame = self.Templates.dropdownElement:Clone()

	local function OnMouseButtonClick1()
		local tweenInfo = TweenInfo.new(0.2)

		for _, optionFrame in self.optionFrames do
			local selected = optionFrame == frame

			TweenService:Create(optionFrame.UIStroke, tweenInfo, {
				Transparency = selected and 0.36 or 1
			}):Play()

			TweenService:Create(optionFrame.text, tweenInfo, {
				TextColor3 = selected and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(149, 149, 149)
			}):Play()
		end

		self.selectedOption = option
		frame.text.Text = displayName
		self.choiceLabel.Text = displayName

		task.delay(0.2, self.SetState, self, false)
		self.section:Save(self.Flag, option)

		task.spawn(function()
			local success, error = pcall(self.callback, option)
			if not success then
				warn("Dropdown callback error:", error)
			end
		end)
	end

	frame.MouseButton1Click:Connect(OnMouseButtonClick1)

	if isSelected then
		self.selectedOption = option
		task.delay(0.1, function()
			OnMouseButtonClick1()
		end)
	end

	frame.text.Text = displayName
	self.optionFrames[option] = frame

	frame.Name = indexName
	frame.Parent = self.list
end

function Dropdown:SetOptions(newOptions: {string}, selectedOption: string)
	for _, frame in self.optionFrames do
		frame:Destroy()
	end

	self.listYOffset = 5

	for index, option in newOptions do
		self.listYOffset += 24 + 5
		self:_createOption(tostring(index), tostring(option), option, option == selectedOption)
	end

	if self.opened then
		TweenService:Create(self.list, TweenInfo.new(0.2), {
			Size = UDim2.new(1, 0, 0, self.listYOffset)
		}):Play()
	end
end

function Dropdown:SetState(isOpened: boolean)
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

function Dropdown:_setOptionVisibility(visible: boolean)
	local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Linear)

	for option, frame in self.optionFrames do
		TweenService:Create(frame, tweenInfo, { 
			BackgroundTransparency = visible and 0 or 1 
		}):Play()
		TweenService:Create(frame.text, tweenInfo, { 
			TextTransparency = visible and 0 or 1 
		}):Play()
		TweenService:Create(frame.UIStroke, tweenInfo, { 
			Transparency = visible and (self.selectedOption == option and 0.36 or 1) or 1 
		}):Play()
	end

	task.wait(0.3)
end

return Dropdown