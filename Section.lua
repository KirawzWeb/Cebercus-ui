local Section = {}
Section.__index = Section

local function import(componentName: string)
    return loadstring(game:HttpGet(`{CerberusImportPath}/Components/{componentName}.lua`))()
end

local Button = import("Button")
local Toggle = import("Toggle")
local Checkbox = import("Checkbox")
local Slider = import("Slider")
local Dropdown = import("Dropdown")
local MultiDropdown = import("MultiDropdown")
local Paragraph = import("Paragraph")


function Section.new(Library, name: string, SectionFlag: string?, tabCanvas: ScrollingFrame)
	local self = setmetatable({
		Flag = SectionFlag or name,
		Templates = Library.Templates,
		Toggles = Library.Toggles,
		Library = Library
	}, Section)

	self.frame = self.Templates.Section:Clone()
	self.frame.BackgroundTransparency = 1
	self.nameLabel = self.frame.title
	self.nameLabel.Text = name
	self.frame.Name = name

	self.frame.Parent = tabCanvas

	if not getgenv().Config[self.Flag] then
		getgenv().Config[self.Flag] = {}
	end

	return self
end

-- function Section:UpdateSize(frameSize: {[Frame]: number})
-- 	if typeof(frameSize) ~= "table" then frameSize = {} end

-- 	local newY = -20

-- 	for _, element in self.frame:GetChildren() do
-- 		if element.ClassName ~= "Frame" then continue end
-- 		newY += (frameSize[element] or element.AbsoluteSize.Y) + 3
-- 	end

-- 	newY -= 3

-- 	TweenService:Create(
-- 		self.frame, 
-- 		TweenInfo.new(0.2), 
-- 		{Size = UDim2.fromOffset(480, newY)}
-- 	):Play()

-- 	return newY
-- end

function Section:CreateButton(ButtonConfig)
	local element = Button.new(self, ButtonConfig)
	return element
end

function Section:CreateToggle(ToggleConfig)
	local element = Toggle.new(self, ToggleConfig)

	table.insert(self.Toggles, element)

	return element
end

function Section:CreateCheckbox(ToggleConfig)
	local element = Checkbox.new(self, ToggleConfig)
	return element
end

function Section:CreateSlider(ToggleConfig)
	local element = Slider.new(self, ToggleConfig)
	return element
end

function Section:CreateDropdown(ToggleConfig)
	local element = Dropdown.new(self, ToggleConfig)
	return element
end

function Section:CreateMultiDropdown(ToggleConfig)
	local element = MultiDropdown.new(self, ToggleConfig)
	return element
end

function Section:CreateParagraph(ToggleConfig)
	local button = Paragraph.new(self, ToggleConfig)
	return button
end

function Section:Save(flag, value)
	getgenv().Config[self.Flag][flag] = value
	self.Library:SaveConfig()
end

function Section:GetSavedValue(value: string)
	return getgenv().Config[self.Flag][value]
end

return Section