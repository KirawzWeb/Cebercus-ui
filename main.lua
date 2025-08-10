local cloneref = cloneref or function(x) return x end :: Instance
local getgenv = getgenv or function() return _G end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CoreGui = cloneref(game:GetService("CoreGui"))

local player   = Players.LocalPlayer
local mouse    = player:GetMouse()

local PlayerGui = player.PlayerGui

local protectUi = gethui or get_hidden_gui

local IS_STUDIO = RunService:IsStudio()
local CAN_SAVE_CONFIG = writefile ~= nil and readfile ~= nil and isfile ~= nil

if getgenv().CerberusLibrary then
    getgenv().CerberusLibrary:Destroy()
end

if not getgenv().CerberusImportPath then
	getgenv().CerberusImportPath = DEV_MODE and "http://127.0.0.1:5746/UI/"
    or "https://raw.githubusercontent.com/KirawzWeb/Cebercus-ui/refs/heads/main/"
end

local Section = IS_STUDIO and require(script.Section) or
				loadstring(game:HttpGet(`{CerberusImportPath}/Section.lua`))()

local Library = {}

type t = {
	Title:string,
	ToggleKey: Enum.KeyCode,
	ConfigName: string
}

function Library.new(libSettings: t)
	local assets = IS_STUDIO and ReplicatedStorage.Library or game:GetObjects("rbxassetid://134867744650646")[1]
	local self = setmetatable(Library, {})

	self.TabButtons = {}
	self.Toggles = {}
	self.connections = {}

    local gui	  = assets.ScreenGui
	local Window  = gui.Window

	self.gui 	   = assets.ScreenGui :: ScreenGui
	self.Templates = assets.Templates :: Folder

	local leftFrame = Window.Left

	self.libTitle = leftFrame.title

	self.tabButtonList	= leftFrame.list
	self.tabCanvas		= Window.Tabs.list
	self.tabPageLayout  = self.tabCanvas.UIPageLayout :: UIPageLayout

	self.Window = gui.Window
	self.ToggleKey = libSettings.ToggleKey

	self.libTitle.Text = libSettings.Title

	self:_initWindowHandler()

	if protectUi then
		protectUi(gui)
	end

	self.ConfigFileName = `{libSettings.ConfigName}.json`
	self:LoadConfig()

	gui.Name = HttpService:GenerateGUID(true)
	gui.Parent = IS_STUDIO and PlayerGui or CoreGui

	getgenv().CerberusLibrary = self

	return self
end

function Library:_ChangeTab(tabName: string, tabButton: Frame, tabCanvas: ScrollingFrame)
	self.tabPageLayout:JumpTo(tabCanvas)

	local tweenInfo = TweenInfo.new(.3)

	for _, buttonFrame:Frame in self.TabButtons do
		local selected  = buttonFrame == tabButton

		local indicator = buttonFrame.indicator

		TweenService:Create(
			buttonFrame, tweenInfo, {
				BackgroundTransparency = selected and 0.25 or 1
			}
		):Play()

		TweenService:Create(
			indicator, tweenInfo, {
				Size = UDim2.new(0, 2, selected and 1 or 0, 0)
			}
		):Play()
	end
end

function Library:CreateTab(TabName:string)
	local tabCanvas = self.Templates.TabCanvas:Clone() :: ScrollingFrame
	local tabButton = self.Templates.TabButton:Clone() :: Frame

	local _tabButton = tabButton.button :: TextButton

	tabButton.TextLabel.Text = TabName

	tabCanvas.Name = TabName
	tabButton.Name = TabName

	tabButton.Parent = self.tabButtonList
	tabCanvas.Parent = self.tabCanvas

	table.insert(self.TabButtons, tabButton)

	if #self.TabButtons == 1 then
		tabButton.BackgroundTransparency = 0.25
		tabButton.indicator.Size =  UDim2.new(0, 2, 1, 0)
	end

	_tabButton.MouseButton1Click:Connect(function()
		self:_ChangeTab(TabName, tabButton, tabCanvas)
	end)

	return {
		CreateSection = function(_, SectionName: string, SectionFlag: string)
			return Section.new(self, SectionName, SectionFlag, tabCanvas)
		end,
	}
end

function Library:CreateTabIndicator(indicator: string)
	local indicatorFrame = self.Templates.TabIndicator:Clone()

	indicatorFrame.Text = indicator or "NO NAME PRIVIDED"

	indicatorFrame.Parent = self.tabButtonList
end

function Library:_initWindowHandler()
	mouse = player:GetMouse()

	local window 	    :Frame 		= self.Window
	local windowPattern :ImageLabel = window.WindowPattern

	local dragFrame1 :Frame = windowPattern.drag1
	local dragFrame2 :Frame = windowPattern.drag2

	local dragging: boolean

	local dragStart: boolean
	local startPos: UDim2

	local conn:RBXScriptConnection
	local stopDragging

	local function startDragging()
		stopDragging()

		dragging = true

		local tweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

		conn = mouse.Move:Connect(function()
			local delta		  = Vector2.new(mouse.X - dragStart.X, mouse.Y - dragStart.Y)
			local newPosition = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)

			TweenService:Create(
				window, tweenInfo, {
					Position = newPosition
				}
			):Play()
		end)
	end

	function stopDragging()
		dragging = false

		if conn and conn.Connected then
			conn:Disconnect()
		end
	end

	local function inputStarted(input: InputObject)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end

		dragStart = input.Position
		startPos  = window.Position;

		(dragging and stopDragging or startDragging)()
	end

	local function inputBegan(input: InputObject, gameProcessedEvent: boolean)
		if input.KeyCode ~= self.ToggleKey then return end

		local value = not window.Visible

		window.Visible = value

		if not value and dragging then
			stopDragging()
		end
	end

	self:Connect(dragFrame1.InputBegan, inputStarted)
	self:Connect(dragFrame1.InputEnded, inputStarted)

	self:Connect(dragFrame2.InputBegan, inputStarted)
	self:Connect(dragFrame2.InputEnded, inputStarted)

	self:Connect(UserInputService.InputBegan, inputBegan)
end

function Library:LoadConfig()
    if not CAN_SAVE_CONFIG then
        warn("Your executor does not support Loading or Saving Configs.")
        return
    end

	if not isfolder("CerberusConfigs") then
		makefolder("CerberusConfigs")
	end

    if not isfile(`CerberusConfigs/{self.ConfigFileName}`) then
        writefile(`CerberusConfigs/{self.ConfigFileName}`, "{}") -- Ensure the file exists and is valid JSON
    end

    local jsonConfig = readfile(`CerberusConfigs/{self.ConfigFileName}`)

    local success, config = pcall(function()
		return HttpService:JSONDecode(jsonConfig)
	end)

    if not success then
        warn("Error while loading Cerberus Config. The file may be corrupted: " .. config)
        config = {} -- Fallback to an empty config
    end

	if getgenv().CerberusLibrary then
		for _, toggle in CerberusLibrary.Toggles do
			toggle:SetValue(false, true)
		end
	end

    getgenv().Config = config
    -- print("Config loaded successfully.")
end

function Library:SaveConfig()
    if not CAN_SAVE_CONFIG then return end

    local success, jsonConfig = pcall(function()
		return HttpService:JSONEncode(getgenv().Config)
	end)

    if not success then
        warn("An error occurred while encoding config: " .. tostring(jsonConfig))
        return
    end

    writefile(`CerberusConfigs/{self.ConfigFileName}`, jsonConfig)
    -- print("Config saved successfully.")
end

function Library:Connect(signal: RBXScriptSignal, fn: (any) -> nil)
	-- print(self.connections, signal, fn)
	local connection = typeof(signal) == "RBXScriptConnection" and signal or signal:Connect(fn)
	table.insert(self.connections, connection)
	return connection
end

function Library:Destroy()
	self.Templates:Destroy()
	self.gui:Destroy()

	for _, con in self.connections do
		con:Disconnect()
	end
end


return Library
