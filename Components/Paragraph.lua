local TweenService = game:GetService("TweenService")

local Paragraph = {}
Paragraph.__index = Paragraph

type t = {
	Title: string,
	Description: string,
	TitleFont: Font?,
	DescriptionFont: Font?
}

function Paragraph.new(section: any, data: t)
	local self = setmetatable({}, Paragraph)

	self.frame = section.Templates.Paragraph:Clone()
	self.titleLabel = self.frame.title :: TextLabel
	self.descLabel = self.frame.desc :: TextLabel

	if data.TitleFont then self.titleLabel.FontFace = data.TitleFont end
	if data.DescriptionFont then self.descLabel.FontFace = data.DescriptionFont end

	self.titleLabel.Text = data.Title
	self.descLabel.Text = data.Description

	self.frame.Parent = section.frame

	self:_updateSize()

	return self
end

function Paragraph:_updateSize()
	local newSize = self.titleLabel.AbsoluteSize.Y + self.descLabel.AbsoluteSize.Y + 20
	TweenService:Create(self.frame, TweenInfo.new(0.2), {
		Size = UDim2.new(1, -10, 0, newSize)
	}):Play()
end

function Paragraph:SetDescription(newDesc: string)
	self.descLabel.Text = newDesc
	self:_updateSize()
end

return Paragraph
