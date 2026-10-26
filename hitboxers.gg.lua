local Library, Window, Options, Toggles = (function()
return (function()

-- ===== AstraUI (hitboxers.gg UI library) =====
local AstraLib = (function()
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local TextService = game:GetService("TextService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

local Lucide
pcall(function()
	Lucide = loadstring(game:HttpGet("https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/icons.lua"))()
end)

local function ResolveIcon(Icon)
	if type(Icon) == "number" then return "rbxassetid://" .. Icon end
	if type(Icon) == "string" then
		if string.match(Icon, "^rbxassetid://") then return Icon end
		if string.match(Icon, "^%d+$") then return "rbxassetid://" .. Icon end
		local Name = string.lower(Icon)
		if type(Lucide) == "function" then
			local ok, Data = pcall(Lucide, Name)
			if ok and type(Data) == "table" then
				local Id = Data.id or Data.Id or Data[1]
				local Size = Data.imageRectSize or Data.ImageRectSize or Data[2]
				local Offset = Data.imageRectOffset or Data.imageRectPosition or Data.ImageRectOffset or Data[3]
				if Id then return "rbxassetid://" .. tostring(Id), Offset, Size end
			end
		elseif type(Lucide) == "table" then
			for _, Set in { Lucide["48px"], Lucide["256px"], Lucide } do
				if type(Set) == "table" then
					local Data = Set[Name]
					if type(Data) == "table" and Data[1] then
						return "rbxassetid://" .. tostring(Data[1]), Data[3], Data[2]
					end
				end
			end
		end
	end
	return "rbxassetid://0"
end

local function ToVector2(Value)
	if typeof(Value) == "Vector2" then return Value end
	if type(Value) == "table" then return Vector2.new(Value[1] or Value.X or 0, Value[2] or Value.Y or 0) end
	return Vector2.new(0, 0)
end

local function ApplyIcon(Object, Icon)
	if not Icon then return end
	local Image, Offset, Size = ResolveIcon(Icon)
	Object.Image = Image
	if Offset then Object.ImageRectOffset = ToVector2(Offset) end
	if Size then Object.ImageRectSize = ToVector2(Size) end
end

local FONT_REGULAR = Font.new("rbxasset://fonts/families/PlusJakartaSans.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
local FONT_MEDIUM  = Font.new("rbxasset://fonts/families/PlusJakartaSans.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal)
local FONT_BOLD    = Font.new("rbxasset://fonts/families/PlusJakartaSans.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)

local COLOR_BG           = Color3.fromRGB(12, 12, 14)
local COLOR_BORDER       = Color3.fromRGB(28, 28, 34)
local COLOR_TEXT_WHITE   = Color3.fromRGB(245, 245, 250)
local COLOR_TEXT_MUTED   = Color3.fromRGB(160, 160, 172)
local COLOR_TEXT_SUB     = Color3.fromRGB(90, 90, 102)
local COLOR_ACTIVE_BG    = Color3.fromRGB(22, 22, 28)
local COLOR_SEARCH_BG    = Color3.fromRGB(18, 18, 22)
local COLOR_CARD_BG      = Color3.fromRGB(16, 16, 20)
local COLOR_BOX_INACTIVE = Color3.fromRGB(22, 22, 28)
local COLOR_BOX_BORDER   = Color3.fromRGB(55, 55, 68)

local Library = {}
Library.__index = Library

local ConfigRegistry = {}
local AutoloadKey = "hitboxers_autoload"

local function EnsureFolder(folderName)
	if not isfolder(folderName) then
		makefolder(folderName)
	end
end

local function SaveConfig(folderName, configName, data)
	EnsureFolder(folderName)
	local path = folderName .. "/" .. configName .. ".json"
	local ok, encoded = pcall(HttpService.JSONEncode, HttpService, data)
	if ok then
		writefile(path, encoded)
		return true
	end
	return false
end

local function LoadConfig(folderName, configName)
	local path = folderName .. "/" .. configName .. ".json"
	if isfile(path) then
		local ok, decoded = pcall(HttpService.JSONDecode, HttpService, readfile(path))
		if ok then return decoded end
	end
	return nil
end

local function ListConfigs(folderName)
	EnsureFolder(folderName)
	local files = {}
	local ok, result = pcall(listfiles, folderName)
	if ok then
		for _, path in ipairs(result) do
			local name = string.match(path, "[/\\]([^/\\]+)%.json$")
			if name then
				table.insert(files, name)
			end
		end
	end
	return files
end

local function DeleteConfig(folderName, configName)
	local path = folderName .. "/" .. configName .. ".json"
	if isfile(path) then
		local ok = pcall(delfile, path)
		return ok
	end
	return false
end

local function GetAutoload(folderName)
	local path = folderName .. "/" .. AutoloadKey .. ".txt"
	if isfile(path) then
		return readfile(path)
	end
	return nil
end

local function SetAutoload(folderName, configName)
	EnsureFolder(folderName)
	local path = folderName .. "/" .. AutoloadKey .. ".txt"
	if configName then
		writefile(path, configName)
	else
		if isfile(path) then pcall(delfile, path) end
	end
end

local function CollectConfigData()
	local data = {}
	for key, entry in pairs(ConfigRegistry) do
		local ok, val = pcall(entry.Get)
		if ok then
			data[key] = val
		end
	end
	return data
end

local function ApplyConfigData(data)
	for key, val in pairs(data) do
		if ConfigRegistry[key] then
			local ok = pcall(ConfigRegistry[key].Set, val)
		end
	end
end

local ParentGui = LocalPlayer:WaitForChild("PlayerGui")
if gethui then
	ParentGui = gethui()
elseif syn and syn.protect_gui then
	local sg = Instance.new("ScreenGui")
	syn.protect_gui(sg)
	ParentGui = CoreGui
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "HitboxersGG"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = ParentGui

local NotificationContainer = Instance.new("Frame")
NotificationContainer.Name = "NotificationContainer"
NotificationContainer.Size = UDim2.new(0, 260, 1, -40)
NotificationContainer.Position = UDim2.new(1, -20, 1, -20)
NotificationContainer.AnchorPoint = Vector2.new(1, 1)
NotificationContainer.BackgroundTransparency = 1
NotificationContainer.Parent = ScreenGui

local NotifLayout = Instance.new("UIListLayout")
NotifLayout.SortOrder = Enum.SortOrder.LayoutOrder
NotifLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
NotifLayout.Padding = UDim.new(0, 8)
NotifLayout.Parent = NotificationContainer

local function Notify(config)
	config = config or {}
	local title = config.Title or "Notification"
	local text = config.Text or ""
	local icon = config.Icon or "bell"
	local duration = config.Duration or 3

	local NotifCard = Instance.new("Frame")
	NotifCard.Name = "Notification"
	NotifCard.Size = UDim2.new(1, 0, 0, 0)
	NotifCard.AutomaticSize = Enum.AutomaticSize.Y
	NotifCard.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	NotifCard.BorderSizePixel = 0
	NotifCard.ClipsDescendants = true
	NotifCard.BackgroundTransparency = 1

	local NotifCorner = Instance.new("UICorner")
	NotifCorner.CornerRadius = UDim.new(0, 6)
	NotifCorner.Parent = NotifCard

	local NotifGradient = Instance.new("UIGradient")
	NotifGradient.Rotation = 90
	NotifGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(28, 28, 35)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(16, 16, 20))
	})
	NotifGradient.Parent = NotifCard

	local NotifStroke = Instance.new("UIStroke")
	NotifStroke.Color = Color3.fromRGB(45, 45, 55)
	NotifStroke.Thickness = 1.2
	NotifStroke.Transparency = 1
	NotifStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	NotifStroke.Parent = NotifCard

	local Padding = Instance.new("UIPadding")
	Padding.PaddingTop = UDim.new(0, 10)
	Padding.PaddingBottom = UDim.new(0, 18)
	Padding.PaddingLeft = UDim.new(0, 12)
	Padding.PaddingRight = UDim.new(0, 12)
	Padding.Parent = NotifCard

	local HeaderFrame = Instance.new("Frame")
	HeaderFrame.Name = "Header"
	HeaderFrame.Size = UDim2.new(1, 0, 0, 16)
	HeaderFrame.BackgroundTransparency = 1
	HeaderFrame.Parent = NotifCard

	local HeaderLayout = Instance.new("UIListLayout")
	HeaderLayout.SortOrder = Enum.SortOrder.LayoutOrder
	HeaderLayout.FillDirection = Enum.FillDirection.Horizontal
	HeaderLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	HeaderLayout.Padding = UDim.new(0, 8)
	HeaderLayout.Parent = HeaderFrame

	local NotifIcon = Instance.new("ImageLabel")
	NotifIcon.Name = "Icon"
	NotifIcon.Size = UDim2.new(0, 14, 0, 14)
	NotifIcon.BackgroundTransparency = 1
	NotifIcon.ImageColor3 = COLOR_TEXT_WHITE
	NotifIcon.ImageTransparency = 1
	NotifIcon.LayoutOrder = 1
	ApplyIcon(NotifIcon, icon)
	NotifIcon.Parent = HeaderFrame

	local TitleLbl = Instance.new("TextLabel")
	TitleLbl.Name = "Title"
	TitleLbl.Size = UDim2.new(1, -22, 1, 0)
	TitleLbl.BackgroundTransparency = 1
	TitleLbl.FontFace = FONT_BOLD
	TitleLbl.Text = title
	TitleLbl.TextColor3 = COLOR_TEXT_WHITE
	TitleLbl.TextTransparency = 1
	TitleLbl.TextSize = 12
	TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
	TitleLbl.LayoutOrder = 2
	TitleLbl.Parent = HeaderFrame

	local DescriptionLbl = Instance.new("TextLabel")
	DescriptionLbl.Name = "Description"
	DescriptionLbl.Size = UDim2.new(1, 0, 0, 0)
	DescriptionLbl.Position = UDim2.new(0, 0, 0, 20)
	DescriptionLbl.AutomaticSize = Enum.AutomaticSize.Y
	DescriptionLbl.BackgroundTransparency = 1
	DescriptionLbl.FontFace = FONT_REGULAR
	DescriptionLbl.Text = text
	DescriptionLbl.TextColor3 = COLOR_TEXT_MUTED
	DescriptionLbl.TextTransparency = 1
	DescriptionLbl.TextSize = 11
	DescriptionLbl.TextXAlignment = Enum.TextXAlignment.Left
	DescriptionLbl.TextWrapped = true
	DescriptionLbl.Parent = NotifCard

	local ProgressBar = Instance.new("Frame")
	ProgressBar.Name = "Progress"
	ProgressBar.Size = UDim2.new(1, 0, 0, 2)
	ProgressBar.Position = UDim2.new(0, 0, 1, 12)
	ProgressBar.BackgroundColor3 = COLOR_TEXT_WHITE
	ProgressBar.BorderSizePixel = 0
	ProgressBar.BackgroundTransparency = 1
	ProgressBar.Parent = NotifCard

	local ProgressCorner = Instance.new("UICorner")
	ProgressCorner.CornerRadius = UDim.new(1, 0)
	ProgressCorner.Parent = ProgressBar

	NotifCard.Parent = NotificationContainer

	TweenService:Create(NotifCard, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0}):Play()
	TweenService:Create(NotifStroke, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 0}):Play()
	TweenService:Create(NotifIcon, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {ImageTransparency = 0}):Play()
	TweenService:Create(TitleLbl, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0}):Play()
	TweenService:Create(DescriptionLbl, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0}):Play()
	TweenService:Create(ProgressBar, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0.4}):Play()
	TweenService:Create(ProgressBar, TweenInfo.new(duration, Enum.EasingStyle.Linear), {Size = UDim2.new(0, 0, 0, 2)}):Play()

	task.delay(duration, function()
		local fadeOut = TweenService:Create(NotifCard, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {BackgroundTransparency = 1})
		TweenService:Create(NotifStroke, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Transparency = 1}):Play()
		TweenService:Create(NotifIcon, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {ImageTransparency = 1}):Play()
		TweenService:Create(TitleLbl, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {TextTransparency = 1}):Play()
		TweenService:Create(DescriptionLbl, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {TextTransparency = 1}):Play()
		TweenService:Create(ProgressBar, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {BackgroundTransparency = 1}):Play()
		fadeOut:Play()
		fadeOut.Completed:Connect(function()
			NotifCard:Destroy()
		end)
	end)
end

local function MakeDraggable(guiObject)
	local dragging = false
	local dragInput, dragStart, startPos

	guiObject.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = guiObject.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	guiObject.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - dragStart
			guiObject.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
end

function Library.CreateWindow(config)
	config = config or {}
	local windowTitle = config.Title or "Astra"
	local windowLogo = config.Logo
	local isAnonymous = config.Anonymous or false
	local configFolder = config.ConfigFolder or "AstraConfigs"

	EnsureFolder(configFolder)

	local Window = {}
	Window._configFolder = configFolder
	Window._tabs = {}
	Window._activeTabRef = nil
	Window._activeSubTabRef = nil

	local MainFrame = Instance.new("Frame")
	MainFrame.Name = "MainFrame"
	MainFrame.Size = UDim2.new(0.92, 0, 0.92, 0)
	MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	MainFrame.BackgroundColor3 = COLOR_BG
	MainFrame.BorderSizePixel = 0
	MainFrame.Parent = ScreenGui

	local MainCorner = Instance.new("UICorner")
	MainCorner.CornerRadius = UDim.new(0, 10)
	MainCorner.Parent = MainFrame

	local MainStroke = Instance.new("UIStroke")
	MainStroke.Color = COLOR_BORDER
	MainStroke.Thickness = 1.2
	MainStroke.Parent = MainFrame

	local AspectRatio = Instance.new("UIAspectRatioConstraint")
	AspectRatio.AspectRatio = 1.65
	AspectRatio.AspectType = Enum.AspectType.FitWithinMaxSize
	AspectRatio.DominantAxis = Enum.DominantAxis.Height
	AspectRatio.Parent = MainFrame

	local SizeConstraint = Instance.new("UISizeConstraint")
	SizeConstraint.MinSize = Vector2.new(620, 360)
	SizeConstraint.MaxSize = Vector2.new(1400, 900)
	SizeConstraint.Parent = MainFrame

	local MobileToggleBtn = Instance.new("TextButton")
	MobileToggleBtn.Name = "MobileToggleBtn"
	MobileToggleBtn.Size = UDim2.new(0, 65, 0, 28)
	MobileToggleBtn.Position = UDim2.new(0, 15, 0.5, -14)
	MobileToggleBtn.BackgroundColor3 = COLOR_CARD_BG
	MobileToggleBtn.BorderSizePixel = 0
	MobileToggleBtn.FontFace = FONT_BOLD
	MobileToggleBtn.Text = "Close"
	MobileToggleBtn.TextColor3 = COLOR_TEXT_WHITE
	MobileToggleBtn.TextSize = 12
	MobileToggleBtn.AutoButtonColor = false
	MobileToggleBtn.ZIndex = 100
	MobileToggleBtn.Parent = ScreenGui

	local ToggleCorner = Instance.new("UICorner")
	ToggleCorner.CornerRadius = UDim.new(0, 6)
	ToggleCorner.Parent = MobileToggleBtn

	local ToggleStroke = Instance.new("UIStroke")
	ToggleStroke.Color = COLOR_BORDER
	ToggleStroke.Thickness = 1.2
	ToggleStroke.Parent = MobileToggleBtn

	local function ToggleUI()
		MainFrame.Visible = not MainFrame.Visible
		MobileToggleBtn.Text = MainFrame.Visible and "Close" or "Open"
	end

	MobileToggleBtn.MouseButton1Click:Connect(ToggleUI)
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if not gameProcessed and input.KeyCode == Enum.KeyCode.RightShift then
			ToggleUI()
		end
	end)

	MakeDraggable(MainFrame)
	MakeDraggable(MobileToggleBtn)

	local Sidebar = Instance.new("Frame")
	Sidebar.Name = "Sidebar"
	Sidebar.Size = UDim2.new(0.24, 0, 1, 0)
	Sidebar.BackgroundTransparency = 1
	Sidebar.BorderSizePixel = 0
	Sidebar.Parent = MainFrame

	local SidebarDivider = Instance.new("Frame")
	SidebarDivider.Name = "SidebarDivider"
	SidebarDivider.Size = UDim2.new(0, 1, 1, 0)
	SidebarDivider.Position = UDim2.new(1, -1, 0, 0)
	SidebarDivider.BackgroundColor3 = COLOR_BORDER
	SidebarDivider.BorderSizePixel = 0
	SidebarDivider.Parent = Sidebar

	local TitleBarFrame = Instance.new("Frame")
	TitleBarFrame.Name = "TitleBar"
	TitleBarFrame.Size = UDim2.new(1, -20, 0, 38)
	TitleBarFrame.Position = UDim2.new(0, 10, 0, 6)
	TitleBarFrame.BackgroundTransparency = 1
	TitleBarFrame.Parent = Sidebar

	local TitleBarLayout = Instance.new("UIListLayout")
	TitleBarLayout.FillDirection = Enum.FillDirection.Horizontal
	TitleBarLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	TitleBarLayout.SortOrder = Enum.SortOrder.LayoutOrder
	TitleBarLayout.Padding = UDim.new(0, 6)
	TitleBarLayout.Parent = TitleBarFrame

	if windowLogo then
		local LogoImg = Instance.new("ImageLabel")
		LogoImg.Name = "Logo"
		LogoImg.Size = UDim2.new(0, 22, 0, 22)
		LogoImg.BackgroundTransparency = 1
		LogoImg.Image = "rbxassetid://" .. tostring(windowLogo)
		LogoImg.LayoutOrder = 1
		LogoImg.Parent = TitleBarFrame
	end

	local TitleLabel = Instance.new("TextLabel")
	TitleLabel.Name = "Title"
	TitleLabel.Size = UDim2.new(1, 0, 1, 0)
	TitleLabel.AutomaticSize = Enum.AutomaticSize.X
	TitleLabel.BackgroundTransparency = 1
	TitleLabel.FontFace = FONT_BOLD
	TitleLabel.Text = windowTitle
	TitleLabel.TextColor3 = COLOR_TEXT_WHITE
	TitleLabel.TextSize = 17
	TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
	TitleLabel.LayoutOrder = 2
	TitleLabel.Parent = TitleBarFrame

	local SearchContainer = Instance.new("Frame")
	SearchContainer.Name = "SearchContainer"
	SearchContainer.Size = UDim2.new(1, -20, 0, 30)
	SearchContainer.Position = UDim2.new(0, 10, 0, 46)
	SearchContainer.BackgroundColor3 = COLOR_SEARCH_BG
	SearchContainer.BorderSizePixel = 0
	SearchContainer.Parent = Sidebar

	local SearchCorner = Instance.new("UICorner")
	SearchCorner.CornerRadius = UDim.new(0, 6)
	SearchCorner.Parent = SearchContainer

	local SearchStroke = Instance.new("UIStroke")
	SearchStroke.Color = COLOR_BORDER
	SearchStroke.Thickness = 1
	SearchStroke.Parent = SearchContainer

	local SearchIcon = Instance.new("ImageLabel")
	SearchIcon.Name = "Icon"
	SearchIcon.Size = UDim2.new(0, 14, 0, 14)
	SearchIcon.Position = UDim2.new(0, 8, 0.5, -7)
	SearchIcon.BackgroundTransparency = 1
	SearchIcon.ImageColor3 = COLOR_TEXT_MUTED
	ApplyIcon(SearchIcon, "search")
	SearchIcon.Parent = SearchContainer

	local SearchInput = Instance.new("TextBox")
	SearchInput.Name = "Input"
	SearchInput.Size = UDim2.new(1, -28, 1, 0)
	SearchInput.Position = UDim2.new(0, 28, 0, 0)
	SearchInput.BackgroundTransparency = 1
	SearchInput.FontFace = FONT_REGULAR
	SearchInput.PlaceholderText = "Search"
	SearchInput.PlaceholderColor3 = COLOR_TEXT_SUB
	SearchInput.Text = ""
	SearchInput.TextColor3 = COLOR_TEXT_WHITE
	SearchInput.TextSize = 13
	SearchInput.TextXAlignment = Enum.TextXAlignment.Left
	SearchInput.Parent = SearchContainer

	local SearchDivider = Instance.new("Frame")
	SearchDivider.Name = "SearchDivider"
	SearchDivider.Size = UDim2.new(1, -20, 0, 1)
	SearchDivider.Position = UDim2.new(0, 10, 0, 82)
	SearchDivider.BackgroundColor3 = COLOR_BORDER
	SearchDivider.BorderSizePixel = 0
	SearchDivider.Parent = Sidebar

	local NavContainer = Instance.new("ScrollingFrame")
	NavContainer.Name = "NavContainer"
	NavContainer.Size = UDim2.new(1, -20, 1, -145)
	NavContainer.Position = UDim2.new(0, 10, 0, 90)
	NavContainer.BackgroundTransparency = 1
	NavContainer.BorderSizePixel = 0
	NavContainer.Active = true
	NavContainer.ScrollingEnabled = true
	NavContainer.ScrollBarThickness = 0
	NavContainer.ScrollingDirection = Enum.ScrollingDirection.Y
	NavContainer.ClipsDescendants = true
	NavContainer.Parent = Sidebar

	local NavLayout = Instance.new("UIListLayout")
	NavLayout.SortOrder = Enum.SortOrder.LayoutOrder
	NavLayout.Padding = UDim.new(0, 3)
	NavLayout.Parent = NavContainer

	NavLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		NavContainer.CanvasSize = UDim2.new(0, 0, 0, NavLayout.AbsoluteContentSize.Y + 10)
	end)

	local UserDivider = Instance.new("Frame")
	UserDivider.Name = "UserDivider"
	UserDivider.Size = UDim2.new(1, -20, 0, 1)
	UserDivider.Position = UDim2.new(0, 10, 1, -52)
	UserDivider.BackgroundColor3 = COLOR_BORDER
	UserDivider.BorderSizePixel = 0
	UserDivider.Parent = Sidebar

	local UserContainer = Instance.new("Frame")
	UserContainer.Name = "UserContainer"
	UserContainer.Size = UDim2.new(1, -20, 0, 42)
	UserContainer.Position = UDim2.new(0, 10, 1, -47)
	UserContainer.BackgroundTransparency = 1
	UserContainer.Parent = Sidebar

	local AvatarBox = Instance.new("Frame")
	AvatarBox.Name = "AvatarBox"
	AvatarBox.Size = UDim2.new(0, 30, 0, 30)
	AvatarBox.Position = UDim2.new(0, 0, 0.5, -15)
	AvatarBox.BackgroundColor3 = COLOR_SEARCH_BG
	AvatarBox.BorderSizePixel = 0
	AvatarBox.ClipsDescendants = true
	AvatarBox.Parent = UserContainer

	local AvatarCorner = Instance.new("UICorner")
	AvatarCorner.CornerRadius = UDim.new(0, 6)
	AvatarCorner.Parent = AvatarBox

	local AvatarStroke = Instance.new("UIStroke")
	AvatarStroke.Color = COLOR_BORDER
	AvatarStroke.Thickness = 1
	AvatarStroke.Parent = AvatarBox

	local AvatarImage = Instance.new("ImageLabel")
	AvatarImage.Name = "AvatarImage"
	AvatarImage.Size = UDim2.new(1, 0, 1, 0)
	AvatarImage.BackgroundTransparency = 1
	AvatarImage.Parent = AvatarBox

	local AvatarImgCorner = Instance.new("UICorner")
	AvatarImgCorner.CornerRadius = UDim.new(0, 6)
	AvatarImgCorner.Parent = AvatarImage

	if isAnonymous then
		AvatarImage.Image = "rbxassetid://0"
	else
		AvatarImage.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(LocalPlayer.UserId) .. "&w=150&h=150"
		task.spawn(function()
			local content, isReady = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
			if isReady and content then
				AvatarImage.Image = content
			end
		end)
	end

	local UserTitle = Instance.new("TextLabel")
	UserTitle.Name = "UserName"
	UserTitle.Size = UDim2.new(1, -38, 0, 15)
	UserTitle.Position = UDim2.new(0, 38, 0, 5)
	UserTitle.BackgroundTransparency = 1
	UserTitle.FontFace = FONT_BOLD
	UserTitle.Text = isAnonymous and "Anonymous" or LocalPlayer.DisplayName
	UserTitle.TextColor3 = COLOR_TEXT_WHITE
	UserTitle.TextSize = 13
	UserTitle.TextXAlignment = Enum.TextXAlignment.Left
	UserTitle.Parent = UserContainer

	local UserBadge = Instance.new("TextLabel")
	UserBadge.Name = "UserBadge"
	UserBadge.Size = UDim2.new(1, -38, 0, 13)
	UserBadge.Position = UDim2.new(0, 38, 0, 21)
	UserBadge.BackgroundTransparency = 1
	UserBadge.FontFace = FONT_MEDIUM
	UserBadge.Text = "BETA"
	UserBadge.TextColor3 = COLOR_TEXT_SUB
	UserBadge.TextSize = 11
	UserBadge.TextXAlignment = Enum.TextXAlignment.Left
	UserBadge.Parent = UserContainer

	local ContentFrame = Instance.new("Frame")
	ContentFrame.Name = "ContentFrame"
	ContentFrame.Size = UDim2.new(0.76, 0, 1, 0)
	ContentFrame.Position = UDim2.new(0.24, 0, 0, 0)
	ContentFrame.BackgroundTransparency = 1
	ContentFrame.Parent = MainFrame

	local ContentHeaderFrame = Instance.new("Frame")
	ContentHeaderFrame.Name = "HeaderFrame"
	ContentHeaderFrame.Size = UDim2.new(1, -24, 0, 44)
	ContentHeaderFrame.Position = UDim2.new(0, 14, 0, 4)
	ContentHeaderFrame.BackgroundTransparency = 1
	ContentHeaderFrame.Parent = ContentFrame

	local HeaderLayout = Instance.new("UIListLayout")
	HeaderLayout.SortOrder = Enum.SortOrder.LayoutOrder
	HeaderLayout.FillDirection = Enum.FillDirection.Horizontal
	HeaderLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	HeaderLayout.Padding = UDim.new(0, 8)
	HeaderLayout.Parent = ContentHeaderFrame

	local ContentHeaderIcon = Instance.new("ImageLabel")
	ContentHeaderIcon.Name = "HeaderIcon"
	ContentHeaderIcon.Size = UDim2.new(0, 18, 0, 18)
	ContentHeaderIcon.BackgroundTransparency = 1
	ContentHeaderIcon.ImageColor3 = COLOR_TEXT_WHITE
	ContentHeaderIcon.LayoutOrder = 1
	ApplyIcon(ContentHeaderIcon, "layout")
	ContentHeaderIcon.Parent = ContentHeaderFrame

	local ContentHeader = Instance.new("TextLabel")
	ContentHeader.Name = "HeaderTitle"
	ContentHeader.Size = UDim2.new(0, 0, 1, 0)
	ContentHeader.AutomaticSize = Enum.AutomaticSize.X
	ContentHeader.BackgroundTransparency = 1
	ContentHeader.FontFace = FONT_BOLD
	ContentHeader.Text = ""
	ContentHeader.TextColor3 = COLOR_TEXT_WHITE
	ContentHeader.TextSize = 17
	ContentHeader.TextXAlignment = Enum.TextXAlignment.Left
	ContentHeader.LayoutOrder = 2
	ContentHeader.Parent = ContentHeaderFrame

	local ContentHeaderDivider = Instance.new("Frame")
	ContentHeaderDivider.Name = "HeaderDivider"
	ContentHeaderDivider.Size = UDim2.new(1, 0, 0, 1)
	ContentHeaderDivider.Position = UDim2.new(0, 0, 0, 48)
	ContentHeaderDivider.BackgroundColor3 = COLOR_BORDER
	ContentHeaderDivider.BorderSizePixel = 0
	ContentHeaderDivider.Parent = ContentFrame

	local ContentArea = Instance.new("Frame")
	ContentArea.Name = "ContentArea"
	ContentArea.Size = UDim2.new(1, -28, 1, -62)
	ContentArea.Position = UDim2.new(0, 14, 0, 54)
	ContentArea.BackgroundTransparency = 1
	ContentArea.Parent = ContentFrame

	Window._navContainer = NavContainer
	Window._navLayout = NavLayout
	Window._contentArea = ContentArea
	Window._contentHeader = ContentHeader
	Window._contentHeaderIcon = ContentHeaderIcon
	Window._tabIndex = 0

	local function UpdateHeader(title, icon)
		ContentHeader.Text = title
		ApplyIcon(ContentHeaderIcon, icon)
	end

	local function SetTabActive(tabObj, isActive)
		tabObj.Btn.BackgroundColor3 = isActive and COLOR_ACTIVE_BG or Color3.fromRGB(0, 0, 0)
		tabObj.Btn.BackgroundTransparency = isActive and 0 or 1
		tabObj.Icon.ImageColor3 = isActive and COLOR_TEXT_WHITE or COLOR_TEXT_MUTED
		tabObj.Label.TextColor3 = isActive and COLOR_TEXT_WHITE or COLOR_TEXT_MUTED
		tabObj.Label.FontFace = isActive and FONT_BOLD or FONT_MEDIUM
		if tabObj.Indicator then tabObj.Indicator.Visible = isActive end
		if tabObj.ContentPage then tabObj.ContentPage.Visible = isActive end
	end

	local function SetSubTabActive(subObj, isActive)
		subObj.Btn.BackgroundColor3 = isActive and COLOR_ACTIVE_BG or Color3.fromRGB(0, 0, 0)
		subObj.Btn.BackgroundTransparency = isActive and 0 or 1
		subObj.Icon.ImageColor3 = isActive and COLOR_TEXT_WHITE or COLOR_TEXT_MUTED
		subObj.Label.TextColor3 = isActive and COLOR_TEXT_WHITE or COLOR_TEXT_MUTED
		subObj.Label.FontFace = isActive and FONT_BOLD or FONT_MEDIUM
		if subObj.Indicator then subObj.Indicator.Visible = isActive end
		if subObj.ContentPage then subObj.ContentPage.Visible = isActive end
	end

	Window._SetTabActive = SetTabActive
	Window._SetSubTabActive = SetSubTabActive
	Window._UpdateHeader = UpdateHeader

	function Window:CreateTab(tabConfig)
		tabConfig = tabConfig or {}
		local tabName = tabConfig.Name or "Tab"
		local tabIcon = tabConfig.Icon or "layout"
		local subTabsData = tabConfig.SubTabs

		self._tabIndex = self._tabIndex + 1
		local idx = self._tabIndex

		local tabObj = {}
		tabObj.Name = tabName
		tabObj.Icon = tabIcon
		tabObj.Expanded = false
		tabObj.SubObjects = {}

		local ContentPage = Instance.new("Frame")
		ContentPage.Name = "Page_" .. tabName
		ContentPage.Size = UDim2.new(1, 0, 1, 0)
		ContentPage.BackgroundTransparency = 1
		ContentPage.Visible = false
		ContentPage.Parent = ContentArea

		local PageLayout = Instance.new("UIListLayout")
		PageLayout.FillDirection = Enum.FillDirection.Horizontal
		PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
		PageLayout.Padding = UDim.new(0, 12)
		PageLayout.VerticalAlignment = Enum.VerticalAlignment.Top
		PageLayout.Parent = ContentPage

		local LeftColumn = Instance.new("Frame")
		LeftColumn.Name = "LeftColumn"
		LeftColumn.Size = UDim2.new(0.5, -6, 1, 0)
		LeftColumn.BackgroundTransparency = 1
		LeftColumn.LayoutOrder = 1
		LeftColumn.Parent = ContentPage

		local LeftColLayout = Instance.new("UIListLayout")
		LeftColLayout.SortOrder = Enum.SortOrder.LayoutOrder
		LeftColLayout.FillDirection = Enum.FillDirection.Vertical
		LeftColLayout.Padding = UDim.new(0, 10)
		LeftColLayout.Parent = LeftColumn

		local RightColumn = Instance.new("Frame")
		RightColumn.Name = "RightColumn"
		RightColumn.Size = UDim2.new(0.5, -6, 1, 0)
		RightColumn.BackgroundTransparency = 1
		RightColumn.LayoutOrder = 2
		RightColumn.Parent = ContentPage

		local RightColLayout = Instance.new("UIListLayout")
		RightColLayout.SortOrder = Enum.SortOrder.LayoutOrder
		RightColLayout.FillDirection = Enum.FillDirection.Vertical
		RightColLayout.Padding = UDim.new(0, 10)
		RightColLayout.Parent = RightColumn

		tabObj.ContentPage = ContentPage
		tabObj._pageLayout = PageLayout
		tabObj._leftColumn = LeftColumn
		tabObj._rightColumn = RightColumn
		tabObj._leftColLayout = LeftColLayout
		tabObj._rightColLayout = RightColLayout

		local TabBtn = Instance.new("TextButton")
		TabBtn.Name = "Tab_" .. tabName
		TabBtn.Size = UDim2.new(1, 0, 0, 30)
		TabBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		TabBtn.BackgroundTransparency = 1
		TabBtn.BorderSizePixel = 0
		TabBtn.AutoButtonColor = false
		TabBtn.Text = ""
		TabBtn.LayoutOrder = idx * 10
		TabBtn.Parent = NavContainer
		tabObj.Btn = TabBtn

		local TabCorner = Instance.new("UICorner")
		TabCorner.CornerRadius = UDim.new(0, 6)
		TabCorner.Parent = TabBtn

		local ActiveIndicator = Instance.new("Frame")
		ActiveIndicator.Name = "Indicator"
		ActiveIndicator.Size = UDim2.new(0, 3, 0, 16)
		ActiveIndicator.Position = UDim2.new(0, 0, 0.5, -8)
		ActiveIndicator.BackgroundColor3 = COLOR_TEXT_WHITE
		ActiveIndicator.BorderSizePixel = 0
		ActiveIndicator.Visible = false
		ActiveIndicator.Parent = TabBtn
		tabObj.Indicator = ActiveIndicator

		local IndCorner = Instance.new("UICorner")
		IndCorner.CornerRadius = UDim.new(0, 2)
		IndCorner.Parent = ActiveIndicator

		local TabIcon = Instance.new("ImageLabel")
		TabIcon.Name = "Icon"
		TabIcon.Size = UDim2.new(0, 15, 0, 15)
		TabIcon.Position = UDim2.new(0, 10, 0.5, -7.5)
		TabIcon.BackgroundTransparency = 1
		TabIcon.ImageColor3 = COLOR_TEXT_MUTED
		ApplyIcon(TabIcon, tabIcon)
		TabIcon.Parent = TabBtn
		tabObj.Icon = TabIcon

		local TabLabel = Instance.new("TextLabel")
		TabLabel.Name = "Label"
		TabLabel.Size = UDim2.new(1, -48, 1, 0)
		TabLabel.Position = UDim2.new(0, 32, 0, 0)
		TabLabel.BackgroundTransparency = 1
		TabLabel.FontFace = FONT_MEDIUM
		TabLabel.Text = tabName
		TabLabel.TextColor3 = COLOR_TEXT_MUTED
		TabLabel.TextSize = 13
		TabLabel.TextXAlignment = Enum.TextXAlignment.Left
		TabLabel.Parent = TabBtn
		tabObj.Label = TabLabel

		local Tab = {}
		Tab._tabObj = tabObj
		Tab._window = self
		Tab._sections = {}

		if subTabsData then
			local ChevronIcon = Instance.new("ImageLabel")
			ChevronIcon.Name = "Chevron"
			ChevronIcon.Size = UDim2.new(0, 12, 0, 12)
			ChevronIcon.Position = UDim2.new(1, -16, 0.5, -6)
			ChevronIcon.BackgroundTransparency = 1
			ChevronIcon.ImageColor3 = COLOR_TEXT_MUTED
			ApplyIcon(ChevronIcon, "chevron-down")
			ChevronIcon.Parent = TabBtn
			tabObj.Chevron = ChevronIcon

			local SubContainer = Instance.new("Frame")
			SubContainer.Name = "SubContainer_" .. tabName
			SubContainer.Size = UDim2.new(1, 0, 0, 0)
			SubContainer.AutomaticSize = Enum.AutomaticSize.Y
			SubContainer.BackgroundTransparency = 1
			SubContainer.LayoutOrder = (idx * 10) + 1
			SubContainer.Visible = false
			SubContainer.Parent = NavContainer
			tabObj.SubContainer = SubContainer

			local SubLayout = Instance.new("UIListLayout")
			SubLayout.SortOrder = Enum.SortOrder.LayoutOrder
			SubLayout.Padding = UDim.new(0, 2)
			SubLayout.Parent = SubContainer

			for j, subData in ipairs(subTabsData) do
				local subObj = {}
				subObj.Data = subData

				local SubPage = Instance.new("Frame")
				SubPage.Name = "SubPage_" .. subData.Name
				SubPage.Size = UDim2.new(1, 0, 1, 0)
				SubPage.BackgroundTransparency = 1
				SubPage.Visible = false
				SubPage.Parent = ContentArea

				local SubPageLayout = Instance.new("UIListLayout")
				SubPageLayout.FillDirection = Enum.FillDirection.Horizontal
				SubPageLayout.SortOrder = Enum.SortOrder.LayoutOrder
				SubPageLayout.Padding = UDim.new(0, 12)
				SubPageLayout.VerticalAlignment = Enum.VerticalAlignment.Top
				SubPageLayout.Parent = SubPage

				local SubLeftCol = Instance.new("Frame")
				SubLeftCol.Name = "LeftColumn"
				SubLeftCol.Size = UDim2.new(0.5, -6, 1, 0)
				SubLeftCol.BackgroundTransparency = 1
				SubLeftCol.LayoutOrder = 1
				SubLeftCol.Parent = SubPage

				local SubLeftColLayout = Instance.new("UIListLayout")
				SubLeftColLayout.SortOrder = Enum.SortOrder.LayoutOrder
				SubLeftColLayout.FillDirection = Enum.FillDirection.Vertical
				SubLeftColLayout.Padding = UDim.new(0, 10)
				SubLeftColLayout.Parent = SubLeftCol

				local SubRightCol = Instance.new("Frame")
				SubRightCol.Name = "RightColumn"
				SubRightCol.Size = UDim2.new(0.5, -6, 1, 0)
				SubRightCol.BackgroundTransparency = 1
				SubRightCol.LayoutOrder = 2
				SubRightCol.Parent = SubPage

				local SubRightColLayout = Instance.new("UIListLayout")
				SubRightColLayout.SortOrder = Enum.SortOrder.LayoutOrder
				SubRightColLayout.FillDirection = Enum.FillDirection.Vertical
				SubRightColLayout.Padding = UDim.new(0, 10)
				SubRightColLayout.Parent = SubRightCol

				subObj.ContentPage = SubPage
				subObj._pageLayout = SubPageLayout
				subObj._leftColumn = SubLeftCol
				subObj._rightColumn = SubRightCol

				local SubBtn = Instance.new("TextButton")
				SubBtn.Name = "SubTab_" .. subData.Name
				SubBtn.Size = UDim2.new(1, 0, 0, 28)
				SubBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
				SubBtn.BackgroundTransparency = 1
				SubBtn.BorderSizePixel = 0
				SubBtn.AutoButtonColor = false
				SubBtn.Text = ""
				SubBtn.LayoutOrder = j
				SubBtn.Parent = SubContainer
				subObj.Btn = SubBtn

				local SubCorner = Instance.new("UICorner")
				SubCorner.CornerRadius = UDim.new(0, 6)
				SubCorner.Parent = SubBtn

				local SubIndicator = Instance.new("Frame")
				SubIndicator.Name = "Indicator"
				SubIndicator.Size = UDim2.new(0, 3, 0, 14)
				SubIndicator.Position = UDim2.new(0, 12, 0.5, -7)
				SubIndicator.BackgroundColor3 = COLOR_TEXT_WHITE
				SubIndicator.BorderSizePixel = 0
				SubIndicator.Visible = false
				SubIndicator.Parent = SubBtn
				subObj.Indicator = SubIndicator

				local SubIndCorner = Instance.new("UICorner")
				SubIndCorner.CornerRadius = UDim.new(0, 2)
				SubIndCorner.Parent = SubIndicator

				local SubIcon = Instance.new("ImageLabel")
				SubIcon.Name = "Icon"
				SubIcon.Size = UDim2.new(0, 13, 0, 13)
				SubIcon.Position = UDim2.new(0, 22, 0.5, -6.5)
				SubIcon.BackgroundTransparency = 1
				SubIcon.ImageColor3 = COLOR_TEXT_MUTED
				ApplyIcon(SubIcon, subData.Icon)
				SubIcon.Parent = SubBtn
				subObj.Icon = SubIcon

				local SubLabel = Instance.new("TextLabel")
				SubLabel.Name = "Label"
				SubLabel.Size = UDim2.new(1, -44, 1, 0)
				SubLabel.Position = UDim2.new(0, 42, 0, 0)
				SubLabel.BackgroundTransparency = 1
				SubLabel.FontFace = FONT_MEDIUM
				SubLabel.Text = subData.Name
				SubLabel.TextColor3 = COLOR_TEXT_MUTED
				SubLabel.TextSize = 12
				SubLabel.TextXAlignment = Enum.TextXAlignment.Left
				SubLabel.Parent = SubBtn
				subObj.Label = SubLabel

				SubBtn.MouseButton1Click:Connect(function()
					if self._activeTabRef then SetTabActive(self._activeTabRef, false) end
					if self._activeSubTabRef then SetSubTabActive(self._activeSubTabRef, false) end
					self._activeTabRef = nil
					self._activeSubTabRef = subObj
					SetSubTabActive(subObj, true)
					UpdateHeader(tabName .. " / " .. subData.Name, subData.Icon)
				end)

				table.insert(tabObj.SubObjects, subObj)
			end

			TabBtn.MouseButton1Click:Connect(function()
				tabObj.Expanded = not tabObj.Expanded
				tabObj.SubContainer.Visible = tabObj.Expanded
				tabObj.Chevron.Rotation = tabObj.Expanded and 180 or 0

				if tabObj.Expanded and #tabObj.SubObjects > 0 then
					local isSubActive = false
					for _, sub in ipairs(tabObj.SubObjects) do
						if sub == self._activeSubTabRef then
							isSubActive = true
							break
						end
					end
					if not isSubActive then
						if self._activeTabRef then SetTabActive(self._activeTabRef, false) end
						if self._activeSubTabRef then SetSubTabActive(self._activeSubTabRef, false) end
						self._activeTabRef = nil
						self._activeSubTabRef = tabObj.SubObjects[1]
						SetSubTabActive(tabObj.SubObjects[1], true)
						UpdateHeader(tabName .. " / " .. tabObj.SubObjects[1].Data.Name, tabObj.SubObjects[1].Data.Icon)
					end
				end
			end)
		else
			TabBtn.MouseButton1Click:Connect(function()
				if self._activeTabRef then SetTabActive(self._activeTabRef, false) end
				if self._activeSubTabRef then SetSubTabActive(self._activeSubTabRef, false) end
				self._activeSubTabRef = nil
				self._activeTabRef = tabObj
				SetTabActive(tabObj, true)
				UpdateHeader(tabName, tabIcon)
			end)
		end

		function Tab:CreateSection(sectionConfig)
			sectionConfig = sectionConfig or {}
			local sectionName = sectionConfig.Name or "Section"
			local side = sectionConfig.Side or "Left"

			local column
			if side == "Left" then
				column = tabObj._leftColumn
			else
				column = tabObj._rightColumn
			end

			local existingInCol = 0
			for _, c in ipairs(column:GetChildren()) do
				if c:IsA("Frame") and c.Name:sub(1, 8) == "Section_" then
					existingInCol = existingInCol + 1
				end
			end

			local SectionFrame = Instance.new("Frame")
			SectionFrame.Name = "Section_" .. sectionName
			SectionFrame.BackgroundColor3 = COLOR_CARD_BG
			SectionFrame.BorderSizePixel = 0
			SectionFrame.ClipsDescendants = true
			SectionFrame.LayoutOrder = existingInCol + 1

			if existingInCol == 0 then
				SectionFrame.Size = UDim2.new(1, 0, 1, 0)
			else
				SectionFrame.Size = UDim2.new(1, 0, 0.5, -5)
			end

			for _, c in ipairs(column:GetChildren()) do
				if c:IsA("Frame") and c.Name:sub(1, 8) == "Section_" then
					c.Size = UDim2.new(1, 0, 0.5, -5)
				end
			end

			SectionFrame.Parent = column

			local SecCorner = Instance.new("UICorner")
			SecCorner.CornerRadius = UDim.new(0, 8)
			SecCorner.Parent = SectionFrame

			local SecStroke = Instance.new("UIStroke")
			SecStroke.Color = COLOR_BORDER
			SecStroke.Thickness = 1.2
			SecStroke.Parent = SectionFrame

			local SecTitle = Instance.new("TextLabel")
			SecTitle.Name = "Title"
			SecTitle.Size = UDim2.new(1, -40, 0, 34)
			SecTitle.Position = UDim2.new(0, 12, 0, 0)
			SecTitle.BackgroundTransparency = 1
			SecTitle.FontFace = FONT_BOLD
			SecTitle.Text = sectionName
			SecTitle.TextColor3 = COLOR_TEXT_WHITE
			SecTitle.TextSize = 14
			SecTitle.TextXAlignment = Enum.TextXAlignment.Left
			SecTitle.Parent = SectionFrame

			local SecDivider = Instance.new("Frame")
			SecDivider.Name = "Divider"
			SecDivider.Size = UDim2.new(1, 0, 0, 1)
			SecDivider.Position = UDim2.new(0, 0, 0, 34)
			SecDivider.BackgroundColor3 = COLOR_BORDER
			SecDivider.BorderSizePixel = 0
			SecDivider.Parent = SectionFrame

			local SecContent = Instance.new("ScrollingFrame")
			SecContent.Name = "Content"
			SecContent.Size = UDim2.new(1, 0, 1, -35)
			SecContent.Position = UDim2.new(0, 0, 0, 35)
			SecContent.BackgroundTransparency = 1
			SecContent.BorderSizePixel = 0
			SecContent.Active = true
			SecContent.ScrollingEnabled = true
			SecContent.ScrollBarThickness = 3
			SecContent.ScrollBarImageColor3 = COLOR_BORDER
			SecContent.ScrollingDirection = Enum.ScrollingDirection.Y
			SecContent.ClipsDescendants = true
			SecContent.Parent = SectionFrame

			local SecPadding = Instance.new("UIPadding")
			SecPadding.PaddingLeft = UDim.new(0, 12)
			SecPadding.PaddingRight = UDim.new(0, 14)
			SecPadding.PaddingTop = UDim.new(0, 8)
			SecPadding.PaddingBottom = UDim.new(0, 12)
			SecPadding.Parent = SecContent

			local SecLayout = Instance.new("UIListLayout")
			SecLayout.SortOrder = Enum.SortOrder.LayoutOrder
			SecLayout.Padding = UDim.new(0, 8)
			SecLayout.Parent = SecContent

			SecLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
				SecContent.CanvasSize = UDim2.new(0, 0, 0, SecLayout.AbsoluteContentSize.Y + 20)
			end)

			local ToggleBtn2 = Instance.new("ImageButton")
			ToggleBtn2.Name = "ToggleChevron"
			ToggleBtn2.Size = UDim2.new(0, 16, 0, 16)
			ToggleBtn2.Position = UDim2.new(1, -12, 0, 9)
			ToggleBtn2.AnchorPoint = Vector2.new(1, 0)
			ToggleBtn2.BackgroundTransparency = 1
			ToggleBtn2.ImageColor3 = COLOR_TEXT_MUTED
			ApplyIcon(ToggleBtn2, "chevron-down")
			ToggleBtn2.Parent = SectionFrame

			local isExpanded = true
			ToggleBtn2.MouseEnter:Connect(function() ToggleBtn2.ImageColor3 = COLOR_TEXT_WHITE end)
			ToggleBtn2.MouseLeave:Connect(function() ToggleBtn2.ImageColor3 = COLOR_TEXT_MUTED end)
			ToggleBtn2.MouseButton1Click:Connect(function()
				isExpanded = not isExpanded
				SecContent.Visible = isExpanded
				SecDivider.Visible = isExpanded
				if isExpanded then
					SectionFrame.Size = UDim2.new(1, 0, SectionFrame.Size.Y.Scale, SectionFrame.Size.Y.Offset)
					ToggleBtn2.Rotation = 0
				else
					SectionFrame.Size = UDim2.new(1, 0, 0, 35)
					ToggleBtn2.Rotation = 180
				end
			end)

			local Section = {}
			Section._content = SecContent
			Section._sectionFrame = SectionFrame
			Section._window = self._window

			function Section:AddLabel(text)
				local Container = Instance.new("Frame")
				Container.Size = UDim2.new(1, 0, 0, 18)
				Container.BackgroundTransparency = 1
				Container.Parent = SecContent

				local Label = Instance.new("TextLabel")
				Label.Size = UDim2.new(1, 0, 1, 0)
				Label.BackgroundTransparency = 1
				Label.FontFace = FONT_MEDIUM
				Label.Text = text
				Label.TextColor3 = COLOR_TEXT_MUTED
				Label.TextSize = 12
				Label.TextXAlignment = Enum.TextXAlignment.Left
				Label.Parent = Container

				return Container
			end

			function Section:AddToggle(toggleConfig)
				toggleConfig = toggleConfig or {}
				local labelText = toggleConfig.Name or "Toggle"
				local defaultState = toggleConfig.Default or false
				local callback = toggleConfig.Callback
				local configKey = toggleConfig.ConfigKey

				local state = defaultState

				local TogBtn = Instance.new("TextButton")
				TogBtn.Size = UDim2.new(1, 0, 0, 22)
				TogBtn.BackgroundTransparency = 1
				TogBtn.Text = ""
				TogBtn.AutoButtonColor = false
				TogBtn.Parent = SecContent

				local Lbl = Instance.new("TextLabel")
				Lbl.Size = UDim2.new(1, -24, 1, 0)
				Lbl.BackgroundTransparency = 1
				Lbl.FontFace = FONT_MEDIUM
				Lbl.Text = labelText
				Lbl.TextColor3 = state and COLOR_TEXT_WHITE or COLOR_TEXT_MUTED
				Lbl.TextSize = 12
				Lbl.TextXAlignment = Enum.TextXAlignment.Left
				Lbl.Parent = TogBtn

				local Box = Instance.new("Frame")
				Box.Size = UDim2.new(0, 16, 0, 16)
				Box.Position = UDim2.new(1, 0, 0.5, 0)
				Box.AnchorPoint = Vector2.new(1, 0.5)
				Box.BackgroundColor3 = state and COLOR_TEXT_WHITE or COLOR_BOX_INACTIVE
				Box.BorderSizePixel = 0
				Box.Parent = TogBtn

				local BoxCorner = Instance.new("UICorner")
				BoxCorner.CornerRadius = UDim.new(0, 4)
				BoxCorner.Parent = Box

				local BoxStroke = Instance.new("UIStroke")
				BoxStroke.Color = state and COLOR_TEXT_WHITE or COLOR_BOX_BORDER
				BoxStroke.Thickness = 1
				BoxStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				BoxStroke.Parent = Box

				local CheckIcon = Instance.new("ImageLabel")
				CheckIcon.Size = UDim2.new(0, 10, 0, 10)
				CheckIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
				CheckIcon.AnchorPoint = Vector2.new(0.5, 0.5)
				CheckIcon.BackgroundTransparency = 1
				CheckIcon.ImageColor3 = COLOR_BG
				CheckIcon.ImageTransparency = state and 0 or 1
				ApplyIcon(CheckIcon, "check")
				CheckIcon.Parent = Box

				local function Refresh()
					Box.BackgroundColor3 = state and COLOR_TEXT_WHITE or COLOR_BOX_INACTIVE
					BoxStroke.Color = state and COLOR_TEXT_WHITE or COLOR_BOX_BORDER
					CheckIcon.ImageTransparency = state and 0 or 1
					Lbl.TextColor3 = state and COLOR_TEXT_WHITE or COLOR_TEXT_MUTED
				end

				TogBtn.MouseButton1Click:Connect(function()
					state = not state
					Refresh()
					if callback then callback(state) end
				end)

				local Toggle = {}
				Toggle.Set = function(val)
					state = val
					Refresh()
					if callback then callback(state) end
				end
				Toggle.Get = function() return state end

				if configKey then
					ConfigRegistry[configKey] = { Get = Toggle.Get, Set = Toggle.Set }
				end

				return Toggle
			end

			function Section:AddSlider(sliderConfig)
				sliderConfig = sliderConfig or {}
				local labelText = sliderConfig.Name or "Slider"
				local min = sliderConfig.Min or 0
				local max = sliderConfig.Max or 100
				local default = sliderConfig.Default or min
				local callback = sliderConfig.Callback
				local configKey = sliderConfig.ConfigKey

				local value = math.clamp(default, min, max)
				local dragging = false

				local Container = Instance.new("Frame")
				Container.Size = UDim2.new(1, 0, 0, 34)
				Container.BackgroundTransparency = 1
				Container.Parent = SecContent

				local Lbl = Instance.new("TextLabel")
				Lbl.Size = UDim2.new(0.6, 0, 0, 16)
				Lbl.BackgroundTransparency = 1
				Lbl.FontFace = FONT_MEDIUM
				Lbl.Text = labelText
				Lbl.TextColor3 = COLOR_TEXT_WHITE
				Lbl.TextSize = 12
				Lbl.TextXAlignment = Enum.TextXAlignment.Left
				Lbl.Parent = Container

				local ValLbl = Instance.new("TextLabel")
				ValLbl.Size = UDim2.new(0.4, 0, 0, 16)
				ValLbl.Position = UDim2.new(1, 0, 0, 0)
				ValLbl.AnchorPoint = Vector2.new(1, 0)
				ValLbl.BackgroundTransparency = 1
				ValLbl.FontFace = FONT_REGULAR
				ValLbl.Text = tostring(value)
				ValLbl.TextColor3 = COLOR_TEXT_MUTED
				ValLbl.TextSize = 11
				ValLbl.TextXAlignment = Enum.TextXAlignment.Right
				ValLbl.Parent = Container

				local Track = Instance.new("Frame")
				Track.Size = UDim2.new(1, 0, 0, 4)
				Track.Position = UDim2.new(0, 0, 0, 22)
				Track.BackgroundColor3 = COLOR_BOX_INACTIVE
				Track.BorderSizePixel = 0
				Track.Parent = Container

				local TrackCorner = Instance.new("UICorner")
				TrackCorner.CornerRadius = UDim.new(1, 0)
				TrackCorner.Parent = Track

				local TrackStroke = Instance.new("UIStroke")
				TrackStroke.Color = COLOR_BORDER
				TrackStroke.Thickness = 1
				TrackStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				TrackStroke.Parent = Track

				local Fill = Instance.new("Frame")
				Fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
				Fill.BackgroundColor3 = COLOR_TEXT_WHITE
				Fill.BorderSizePixel = 0
				Fill.Parent = Track

				local FillCorner = Instance.new("UICorner")
				FillCorner.CornerRadius = UDim.new(1, 0)
				FillCorner.Parent = Fill

				local function UpdateSlider(input)
					local posX = math.clamp(input.Position.X - Track.AbsolutePosition.X, 0, Track.AbsoluteSize.X)
					local pct = math.clamp(posX / Track.AbsoluteSize.X, 0, 1)
					value = math.floor(min + (max - min) * pct + 0.5)
					Fill.Size = UDim2.new(pct, 0, 1, 0)
					ValLbl.Text = tostring(value)
					if callback then callback(value) end
				end

				Track.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						dragging = true
						UpdateSlider(input)
					end
				end)

				UserInputService.InputChanged:Connect(function(input)
					if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
						UpdateSlider(input)
					end
				end)

				UserInputService.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						dragging = false
					end
				end)

				local Slider = {}
				Slider.Set = function(val)
					value = math.clamp(val, min, max)
					local pct = (value - min) / (max - min)
					Fill.Size = UDim2.new(pct, 0, 1, 0)
					ValLbl.Text = tostring(value)
					if callback then callback(value) end
				end
				Slider.Get = function() return value end

				if configKey then
					ConfigRegistry[configKey] = { Get = Slider.Get, Set = Slider.Set }
				end

				return Slider
			end

			function Section:AddInput(inputConfig)
				inputConfig = inputConfig or {}
				local labelText = inputConfig.Name or "Input"
				local placeholder = inputConfig.Placeholder or "Type here..."
				local default = inputConfig.Default or ""
				local callback = inputConfig.Callback
				local configKey = inputConfig.ConfigKey

				local Container = Instance.new("Frame")
				Container.Size = UDim2.new(1, 0, 0, 48)
				Container.BackgroundTransparency = 1
				Container.Parent = SecContent

				local Lbl = Instance.new("TextLabel")
				Lbl.Size = UDim2.new(1, 0, 0, 16)
				Lbl.BackgroundTransparency = 1
				Lbl.FontFace = FONT_MEDIUM
				Lbl.Text = labelText
				Lbl.TextColor3 = COLOR_TEXT_WHITE
				Lbl.TextSize = 12
				Lbl.TextXAlignment = Enum.TextXAlignment.Left
				Lbl.Parent = Container

				local BoxContainer = Instance.new("Frame")
				BoxContainer.Size = UDim2.new(1, 0, 0, 24)
				BoxContainer.Position = UDim2.new(0, 0, 0, 18)
				BoxContainer.BackgroundColor3 = COLOR_BOX_INACTIVE
				BoxContainer.BorderSizePixel = 0
				BoxContainer.Parent = Container

				local BoxCorner = Instance.new("UICorner")
				BoxCorner.CornerRadius = UDim.new(0, 5)
				BoxCorner.Parent = BoxContainer

				local BoxStroke = Instance.new("UIStroke")
				BoxStroke.Color = COLOR_BOX_BORDER
				BoxStroke.Thickness = 1
				BoxStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				BoxStroke.Parent = BoxContainer

				local TextBox = Instance.new("TextBox")
				TextBox.Size = UDim2.new(1, -16, 1, 0)
				TextBox.Position = UDim2.new(0, 8, 0, 0)
				TextBox.BackgroundTransparency = 1
				TextBox.FontFace = FONT_REGULAR
				TextBox.PlaceholderText = placeholder
				TextBox.PlaceholderColor3 = COLOR_TEXT_SUB
				TextBox.Text = default
				TextBox.TextColor3 = COLOR_TEXT_WHITE
				TextBox.TextSize = 11
				TextBox.TextXAlignment = Enum.TextXAlignment.Left
				TextBox.ClearTextOnFocus = false
				TextBox.Parent = BoxContainer

				TextBox.Focused:Connect(function() BoxStroke.Color = COLOR_TEXT_WHITE end)
				TextBox.FocusLost:Connect(function(enterPressed)
					BoxStroke.Color = COLOR_BOX_BORDER
					if callback then callback(TextBox.Text, enterPressed) end
				end)

				local Input = {}
				Input.Set = function(val) TextBox.Text = val end
				Input.Get = function() return TextBox.Text end

				if configKey then
					ConfigRegistry[configKey] = { Get = Input.Get, Set = Input.Set }
				end

				return Input
			end

			function Section:AddDropdown(dropConfig)
				dropConfig = dropConfig or {}
				local labelText = dropConfig.Name or "Dropdown"
				local options = dropConfig.Options or {}
				local default = dropConfig.Default or (options and options[1]) or "None"
				local callback = dropConfig.Callback
				local configKey = dropConfig.ConfigKey

				local selected = default
				local isOpen = false

				local Container = Instance.new("Frame")
				Container.Size = UDim2.new(1, 0, 0, 48)
				Container.BackgroundTransparency = 1
				Container.Parent = SecContent

				local Lbl = Instance.new("TextLabel")
				Lbl.Size = UDim2.new(1, 0, 0, 16)
				Lbl.BackgroundTransparency = 1
				Lbl.FontFace = FONT_MEDIUM
				Lbl.Text = labelText
				Lbl.TextColor3 = COLOR_TEXT_MUTED
				Lbl.TextSize = 12
				Lbl.TextXAlignment = Enum.TextXAlignment.Left
				Lbl.Parent = Container

				local Header = Instance.new("TextButton")
				Header.Size = UDim2.new(1, 0, 0, 26)
				Header.Position = UDim2.new(0, 0, 0, 18)
				Header.BackgroundColor3 = COLOR_BOX_INACTIVE
				Header.BorderSizePixel = 0
				Header.AutoButtonColor = false
				Header.Text = ""
				Header.Parent = Container

				local HeaderCorner = Instance.new("UICorner")
				HeaderCorner.CornerRadius = UDim.new(0, 5)
				HeaderCorner.Parent = Header

				local HeaderStroke = Instance.new("UIStroke")
				HeaderStroke.Color = COLOR_BOX_BORDER
				HeaderStroke.Thickness = 1
				HeaderStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				HeaderStroke.Parent = Header

				local SelText = Instance.new("TextLabel")
				SelText.Size = UDim2.new(1, -28, 1, 0)
				SelText.Position = UDim2.new(0, 8, 0, 0)
				SelText.BackgroundTransparency = 1
				SelText.FontFace = FONT_MEDIUM
				SelText.Text = selected
				SelText.TextColor3 = COLOR_TEXT_WHITE
				SelText.TextSize = 12
				SelText.TextXAlignment = Enum.TextXAlignment.Left
				SelText.Parent = Header

				local Chevron = Instance.new("ImageLabel")
				Chevron.Size = UDim2.new(0, 12, 0, 12)
				Chevron.Position = UDim2.new(1, -8, 0.5, 0)
				Chevron.AnchorPoint = Vector2.new(1, 0.5)
				Chevron.BackgroundTransparency = 1
				Chevron.ImageColor3 = COLOR_TEXT_MUTED
				ApplyIcon(Chevron, "chevron-down")
				Chevron.Parent = Header

				local OptionHolder = Instance.new("Frame")
				OptionHolder.Size = UDim2.new(1, 0, 0, 0)
				OptionHolder.Position = UDim2.new(0, 0, 0, 48)
				OptionHolder.BackgroundColor3 = COLOR_BOX_INACTIVE
				OptionHolder.BorderSizePixel = 0
				OptionHolder.Visible = false
				OptionHolder.ClipsDescendants = true
				OptionHolder.ZIndex = 10
				OptionHolder.Parent = Container

				local HolderCorner = Instance.new("UICorner")
				HolderCorner.CornerRadius = UDim.new(0, 5)
				HolderCorner.Parent = OptionHolder

				local HolderStroke = Instance.new("UIStroke")
				HolderStroke.Color = COLOR_BOX_BORDER
				HolderStroke.Thickness = 1
				HolderStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				HolderStroke.Parent = OptionHolder

				local HolderLayout = Instance.new("UIListLayout")
				HolderLayout.SortOrder = Enum.SortOrder.LayoutOrder
				HolderLayout.Padding = UDim.new(0, 2)
				HolderLayout.Parent = OptionHolder

				local HolderPadding = Instance.new("UIPadding")
				HolderPadding.PaddingTop = UDim.new(0, 4)
				HolderPadding.PaddingBottom = UDim.new(0, 4)
				HolderPadding.PaddingLeft = UDim.new(0, 4)
				HolderPadding.PaddingRight = UDim.new(0, 4)
				HolderPadding.Parent = OptionHolder

				local function ToggleList()
					isOpen = not isOpen
					OptionHolder.Visible = isOpen
					Chevron.Rotation = isOpen and 180 or 0
					HeaderStroke.Color = isOpen and COLOR_TEXT_WHITE or COLOR_BOX_BORDER
					if isOpen then
						local totalHeight = (#options * 24) + 8
						OptionHolder.Size = UDim2.new(1, 0, 0, math.min(totalHeight, 120))
						Container.Size = UDim2.new(1, 0, 0, 48 + math.min(totalHeight, 120) + 4)
					else
						Container.Size = UDim2.new(1, 0, 0, 48)
					end
				end

				Header.MouseButton1Click:Connect(ToggleList)

				for _, opt in ipairs(options) do
					local OptBtn = Instance.new("TextButton")
					OptBtn.Size = UDim2.new(1, 0, 0, 22)
					OptBtn.BackgroundColor3 = COLOR_ACTIVE_BG
					OptBtn.BackgroundTransparency = (opt == selected) and 0 or 1
					OptBtn.BorderSizePixel = 0
					OptBtn.FontFace = FONT_REGULAR
					OptBtn.Text = opt
					OptBtn.TextColor3 = (opt == selected) and COLOR_TEXT_WHITE or COLOR_TEXT_MUTED
					OptBtn.TextSize = 11
					OptBtn.TextXAlignment = Enum.TextXAlignment.Left
					OptBtn.AutoButtonColor = false
					OptBtn.Parent = OptionHolder

					local OptPad = Instance.new("UIPadding")
					OptPad.PaddingLeft = UDim.new(0, 6)
					OptPad.Parent = OptBtn

					local OptCorner = Instance.new("UICorner")
					OptCorner.CornerRadius = UDim.new(0, 4)
					OptCorner.Parent = OptBtn

					OptBtn.MouseEnter:Connect(function()
						OptBtn.BackgroundTransparency = 0
						OptBtn.TextColor3 = COLOR_TEXT_WHITE
					end)
					OptBtn.MouseLeave:Connect(function()
						if opt ~= selected then
							OptBtn.BackgroundTransparency = 1
							OptBtn.TextColor3 = COLOR_TEXT_MUTED
						end
					end)
					OptBtn.MouseButton1Click:Connect(function()
						selected = opt
						SelText.Text = selected
						ToggleList()
						for _, child in ipairs(OptionHolder:GetChildren()) do
							if child:IsA("TextButton") then
								local isSel = (child.Text == selected)
								child.BackgroundTransparency = isSel and 0 or 1
								child.TextColor3 = isSel and COLOR_TEXT_WHITE or COLOR_TEXT_MUTED
							end
						end
						if callback then callback(selected) end
					end)
				end

				local Dropdown = {}
				Dropdown.Set = function(val)
					selected = val
					SelText.Text = val
					for _, child in ipairs(OptionHolder:GetChildren()) do
						if child:IsA("TextButton") then
							local isSel = (child.Text == selected)
							child.BackgroundTransparency = isSel and 0 or 1
							child.TextColor3 = isSel and COLOR_TEXT_WHITE or COLOR_TEXT_MUTED
						end
					end
					if callback then callback(selected) end
				end
				Dropdown.Get = function() return selected end

				if configKey then
					ConfigRegistry[configKey] = { Get = Dropdown.Get, Set = Dropdown.Set }
				end

				return Dropdown
			end

			function Section:AddMultiDropdown(dropConfig)
				dropConfig = dropConfig or {}
				local labelText = dropConfig.Name or "Multi Dropdown"
				local options = dropConfig.Options or {}
				local defaultSelected = dropConfig.Default or {}
				local callback = dropConfig.Callback
				local configKey = dropConfig.ConfigKey

				local selected = {}
				if type(defaultSelected) == "table" then
					for _, item in ipairs(defaultSelected) do
						selected[item] = true
					end
				end
				local isOpen = false

				local Container = Instance.new("Frame")
				Container.Size = UDim2.new(1, 0, 0, 48)
				Container.BackgroundTransparency = 1
				Container.Parent = SecContent

				local Lbl = Instance.new("TextLabel")
				Lbl.Size = UDim2.new(1, 0, 0, 16)
				Lbl.BackgroundTransparency = 1
				Lbl.FontFace = FONT_MEDIUM
				Lbl.Text = labelText
				Lbl.TextColor3 = COLOR_TEXT_MUTED
				Lbl.TextSize = 12
				Lbl.TextXAlignment = Enum.TextXAlignment.Left
				Lbl.Parent = Container

				local Header = Instance.new("TextButton")
				Header.Size = UDim2.new(1, 0, 0, 26)
				Header.Position = UDim2.new(0, 0, 0, 18)
				Header.BackgroundColor3 = COLOR_BOX_INACTIVE
				Header.BorderSizePixel = 0
				Header.AutoButtonColor = false
				Header.Text = ""
				Header.Parent = Container

				local HeaderCorner = Instance.new("UICorner")
				HeaderCorner.CornerRadius = UDim.new(0, 5)
				HeaderCorner.Parent = Header

				local HeaderStroke = Instance.new("UIStroke")
				HeaderStroke.Color = COLOR_BOX_BORDER
				HeaderStroke.Thickness = 1
				HeaderStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				HeaderStroke.Parent = Header

				local SelText = Instance.new("TextLabel")
				SelText.Size = UDim2.new(1, -28, 1, 0)
				SelText.Position = UDim2.new(0, 8, 0, 0)
				SelText.BackgroundTransparency = 1
				SelText.FontFace = FONT_MEDIUM
				SelText.TextColor3 = COLOR_TEXT_WHITE
				SelText.TextSize = 12
				SelText.TextXAlignment = Enum.TextXAlignment.Left
				SelText.TextTruncate = Enum.TextTruncate.AtEnd
				SelText.Parent = Header

				local function FormatSelected()
					local list = {}
					for _, opt in ipairs(options) do
						if selected[opt] then table.insert(list, opt) end
					end
					return #list == 0 and "None" or table.concat(list, ", ")
				end

				SelText.Text = FormatSelected()

				local Chevron = Instance.new("ImageLabel")
				Chevron.Size = UDim2.new(0, 12, 0, 12)
				Chevron.Position = UDim2.new(1, -8, 0.5, 0)
				Chevron.AnchorPoint = Vector2.new(1, 0.5)
				Chevron.BackgroundTransparency = 1
				Chevron.ImageColor3 = COLOR_TEXT_MUTED
				ApplyIcon(Chevron, "chevron-down")
				Chevron.Parent = Header

				local OptionHolder = Instance.new("Frame")
				OptionHolder.Size = UDim2.new(1, 0, 0, 0)
				OptionHolder.Position = UDim2.new(0, 0, 0, 48)
				OptionHolder.BackgroundColor3 = COLOR_BOX_INACTIVE
				OptionHolder.BorderSizePixel = 0
				OptionHolder.Visible = false
				OptionHolder.ClipsDescendants = true
				OptionHolder.ZIndex = 10
				OptionHolder.Parent = Container

				local HolderCorner = Instance.new("UICorner")
				HolderCorner.CornerRadius = UDim.new(0, 5)
				HolderCorner.Parent = OptionHolder

				local HolderStroke = Instance.new("UIStroke")
				HolderStroke.Color = COLOR_BOX_BORDER
				HolderStroke.Thickness = 1
				HolderStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				HolderStroke.Parent = OptionHolder

				local HolderLayout = Instance.new("UIListLayout")
				HolderLayout.SortOrder = Enum.SortOrder.LayoutOrder
				HolderLayout.Padding = UDim.new(0, 2)
				HolderLayout.Parent = OptionHolder

				local HolderPadding = Instance.new("UIPadding")
				HolderPadding.PaddingTop = UDim.new(0, 4)
				HolderPadding.PaddingBottom = UDim.new(0, 4)
				HolderPadding.PaddingLeft = UDim.new(0, 4)
				HolderPadding.PaddingRight = UDim.new(0, 4)
				HolderPadding.Parent = OptionHolder

				local function ToggleList()
					isOpen = not isOpen
					OptionHolder.Visible = isOpen
					Chevron.Rotation = isOpen and 180 or 0
					HeaderStroke.Color = isOpen and COLOR_TEXT_WHITE or COLOR_BOX_BORDER
					if isOpen then
						local totalHeight = (#options * 24) + 8
						OptionHolder.Size = UDim2.new(1, 0, 0, math.min(totalHeight, 120))
						Container.Size = UDim2.new(1, 0, 0, 48 + math.min(totalHeight, 120) + 4)
					else
						Container.Size = UDim2.new(1, 0, 0, 48)
					end
				end

				Header.MouseButton1Click:Connect(ToggleList)

				for _, opt in ipairs(options) do
					local OptBtn = Instance.new("TextButton")
					OptBtn.Size = UDim2.new(1, 0, 0, 22)
					OptBtn.BackgroundColor3 = COLOR_ACTIVE_BG
					OptBtn.BackgroundTransparency = selected[opt] and 0 or 1
					OptBtn.BorderSizePixel = 0
					OptBtn.FontFace = FONT_REGULAR
					OptBtn.Text = opt
					OptBtn.TextColor3 = selected[opt] and COLOR_TEXT_WHITE or COLOR_TEXT_MUTED
					OptBtn.TextSize = 11
					OptBtn.TextXAlignment = Enum.TextXAlignment.Left
					OptBtn.AutoButtonColor = false
					OptBtn.Parent = OptionHolder

					local OptPad = Instance.new("UIPadding")
					OptPad.PaddingLeft = UDim.new(0, 6)
					OptPad.Parent = OptBtn

					local OptCorner = Instance.new("UICorner")
					OptCorner.CornerRadius = UDim.new(0, 4)
					OptCorner.Parent = OptBtn

					OptBtn.MouseButton1Click:Connect(function()
						selected[opt] = not selected[opt]
						OptBtn.BackgroundTransparency = selected[opt] and 0 or 1
						OptBtn.TextColor3 = selected[opt] and COLOR_TEXT_WHITE or COLOR_TEXT_MUTED
						SelText.Text = FormatSelected()
						if callback then callback(selected) end
					end)
				end

				local MultiDropdown = {}
				MultiDropdown.Set = function(val)
					selected = {}
					if type(val) == "table" then
						for _, item in ipairs(val) do selected[item] = true end
					end
					SelText.Text = FormatSelected()
					for _, child in ipairs(OptionHolder:GetChildren()) do
						if child:IsA("TextButton") then
							local isSel = selected[child.Text] == true
							child.BackgroundTransparency = isSel and 0 or 1
							child.TextColor3 = isSel and COLOR_TEXT_WHITE or COLOR_TEXT_MUTED
						end
					end
					if callback then callback(selected) end
				end
				MultiDropdown.Get = function()
					local list = {}
					for k, v in pairs(selected) do if v then table.insert(list, k) end end
					return list
				end

				if configKey then
					ConfigRegistry[configKey] = { Get = MultiDropdown.Get, Set = MultiDropdown.Set }
				end

				return MultiDropdown
			end

			function Section:AddColorPicker(pickerConfig)
				pickerConfig = pickerConfig or {}
				local labelText = pickerConfig.Name or "Color Picker"
				local default = pickerConfig.Default or Color3.fromRGB(0, 230, 150)
				local callback = pickerConfig.Callback
				local configKey = pickerConfig.ConfigKey

				local color = default
				local h, s, v = color:ToHSV()
				local isOpen = false

				local Container = Instance.new("Frame")
				Container.Size = UDim2.new(1, 0, 0, 24)
				Container.BackgroundTransparency = 1
				Container.Parent = SecContent

				local TopHeader = Instance.new("Frame")
				TopHeader.Size = UDim2.new(1, 0, 0, 24)
				TopHeader.BackgroundTransparency = 1
				TopHeader.Parent = Container

				local Lbl = Instance.new("TextLabel")
				Lbl.Size = UDim2.new(1, -45, 1, 0)
				Lbl.BackgroundTransparency = 1
				Lbl.FontFace = FONT_MEDIUM
				Lbl.Text = labelText
				Lbl.TextColor3 = COLOR_TEXT_MUTED
				Lbl.TextSize = 12
				Lbl.TextXAlignment = Enum.TextXAlignment.Left
				Lbl.Parent = TopHeader

				local PreviewBtn = Instance.new("TextButton")
				PreviewBtn.Size = UDim2.new(0, 32, 0, 16)
				PreviewBtn.Position = UDim2.new(1, 0, 0.5, 0)
				PreviewBtn.AnchorPoint = Vector2.new(1, 0.5)
				PreviewBtn.BackgroundColor3 = color
				PreviewBtn.BorderSizePixel = 0
				PreviewBtn.Text = ""
				PreviewBtn.AutoButtonColor = false
				PreviewBtn.Parent = TopHeader

				local PreviewCorner = Instance.new("UICorner")
				PreviewCorner.CornerRadius = UDim.new(0, 4)
				PreviewCorner.Parent = PreviewBtn

				local PreviewStroke = Instance.new("UIStroke")
				PreviewStroke.Color = COLOR_BOX_BORDER
				PreviewStroke.Thickness = 1
				PreviewStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				PreviewStroke.Parent = PreviewBtn

				local PickerPanel = Instance.new("Frame")
				PickerPanel.Size = UDim2.new(1, 0, 0, 142)
				PickerPanel.Position = UDim2.new(0, 0, 0, 28)
				PickerPanel.BackgroundColor3 = COLOR_BOX_INACTIVE
				PickerPanel.BorderSizePixel = 0
				PickerPanel.Visible = false
				PickerPanel.ClipsDescendants = true
				PickerPanel.ZIndex = 12
				PickerPanel.Parent = Container

				local PanelCorner = Instance.new("UICorner")
				PanelCorner.CornerRadius = UDim.new(0, 6)
				PanelCorner.Parent = PickerPanel

				local PanelStroke = Instance.new("UIStroke")
				PanelStroke.Color = COLOR_BOX_BORDER
				PanelStroke.Thickness = 1
				PanelStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				PanelStroke.Parent = PickerPanel

				local SVBox = Instance.new("Frame")
				SVBox.Size = UDim2.new(1, -36, 0, 95)
				SVBox.Position = UDim2.new(0, 8, 0, 8)
				SVBox.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
				SVBox.BorderSizePixel = 0
				SVBox.Parent = PickerPanel

				local SVCorner = Instance.new("UICorner")
				SVCorner.CornerRadius = UDim.new(0, 4)
				SVCorner.Parent = SVBox

				local WhiteGradFrame = Instance.new("Frame")
				WhiteGradFrame.Size = UDim2.new(1, 0, 1, 0)
				WhiteGradFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				WhiteGradFrame.BorderSizePixel = 0
				WhiteGradFrame.Parent = SVBox

				local WhiteCorner = Instance.new("UICorner")
				WhiteCorner.CornerRadius = UDim.new(0, 4)
				WhiteCorner.Parent = WhiteGradFrame

				local WhiteGrad = Instance.new("UIGradient")
				WhiteGrad.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
				WhiteGrad.Parent = WhiteGradFrame

				local BlackGradFrame = Instance.new("Frame")
				BlackGradFrame.Size = UDim2.new(1, 0, 1, 0)
				BlackGradFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
				BlackGradFrame.BorderSizePixel = 0
				BlackGradFrame.Parent = SVBox

				local BlackCorner = Instance.new("UICorner")
				BlackCorner.CornerRadius = UDim.new(0, 4)
				BlackCorner.Parent = BlackGradFrame

				local BlackGrad = Instance.new("UIGradient")
				BlackGrad.Rotation = 90
				BlackGrad.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) })
				BlackGrad.Parent = BlackGradFrame

				local SVCursor = Instance.new("Frame")
				SVCursor.Size = UDim2.new(0, 10, 0, 10)
				SVCursor.AnchorPoint = Vector2.new(0.5, 0.5)
				SVCursor.Position = UDim2.new(s, 0, 1 - v, 0)
				SVCursor.BackgroundColor3 = color
				SVCursor.BorderSizePixel = 0
				SVCursor.ZIndex = 2
				SVCursor.Parent = SVBox

				local SVCursorCorner = Instance.new("UICorner")
				SVCursorCorner.CornerRadius = UDim.new(1, 0)
				SVCursorCorner.Parent = SVCursor

				local SVCursorStroke = Instance.new("UIStroke")
				SVCursorStroke.Color = Color3.fromRGB(255, 255, 255)
				SVCursorStroke.Thickness = 1.5
				SVCursorStroke.Parent = SVCursor

				local HueBar = Instance.new("Frame")
				HueBar.Size = UDim2.new(0, 12, 0, 95)
				HueBar.Position = UDim2.new(1, -18, 0, 8)
				HueBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				HueBar.BorderSizePixel = 0
				HueBar.Parent = PickerPanel

				local HueCorner = Instance.new("UICorner")
				HueCorner.CornerRadius = UDim.new(0, 4)
				HueCorner.Parent = HueBar

				local HueGrad = Instance.new("UIGradient")
				HueGrad.Rotation = 90
				HueGrad.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
					ColorSequenceKeypoint.new(0.167, Color3.fromRGB(255, 255, 0)),
					ColorSequenceKeypoint.new(0.333, Color3.fromRGB(0, 255, 0)),
					ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
					ColorSequenceKeypoint.new(0.667, Color3.fromRGB(0, 0, 255)),
					ColorSequenceKeypoint.new(0.833, Color3.fromRGB(255, 0, 255)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
				})
				HueGrad.Parent = HueBar

				local HueCursor = Instance.new("Frame")
				HueCursor.Size = UDim2.new(1, 4, 0, 4)
				HueCursor.AnchorPoint = Vector2.new(0.5, 0.5)
				HueCursor.Position = UDim2.new(0.5, 0, h, 0)
				HueCursor.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				HueCursor.BorderSizePixel = 0
				HueCursor.ZIndex = 2
				HueCursor.Parent = HueBar

				local HueCursorCorner = Instance.new("UICorner")
				HueCursorCorner.CornerRadius = UDim.new(1, 0)
				HueCursorCorner.Parent = HueCursor

				local HueCursorStroke = Instance.new("UIStroke")
				HueCursorStroke.Color = Color3.fromRGB(0, 0, 0)
				HueCursorStroke.Thickness = 1
				HueCursorStroke.Parent = HueCursor

				local ColorValBox = Instance.new("TextBox")
				ColorValBox.Size = UDim2.new(1, -16, 0, 22)
				ColorValBox.Position = UDim2.new(0, 8, 0, 110)
				ColorValBox.BackgroundColor3 = COLOR_SEARCH_BG
				ColorValBox.BorderSizePixel = 0
				ColorValBox.FontFace = FONT_MEDIUM
				ColorValBox.Text = string.format("rgb(%d, %d, %d)", math.floor(color.R * 255 + 0.5), math.floor(color.G * 255 + 0.5), math.floor(color.B * 255 + 0.5))
				ColorValBox.TextColor3 = COLOR_TEXT_WHITE
				ColorValBox.TextSize = 11
				ColorValBox.ClearTextOnFocus = false
				ColorValBox.Parent = PickerPanel

				local ValBoxCorner = Instance.new("UICorner")
				ValBoxCorner.CornerRadius = UDim.new(0, 4)
				ValBoxCorner.Parent = ColorValBox

				local ValBoxStroke = Instance.new("UIStroke")
				ValBoxStroke.Color = COLOR_BOX_BORDER
				ValBoxStroke.Thickness = 1
				ValBoxStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				ValBoxStroke.Parent = ColorValBox

				local function UpdateColor()
					color = Color3.fromHSV(h, s, v)
					SVBox.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
					SVCursor.Position = UDim2.new(s, 0, 1 - v, 0)
					SVCursor.BackgroundColor3 = color
					HueCursor.Position = UDim2.new(0.5, 0, h, 0)
					PreviewBtn.BackgroundColor3 = color
					ColorValBox.Text = string.format("rgb(%d, %d, %d)", math.floor(color.R * 255 + 0.5), math.floor(color.G * 255 + 0.5), math.floor(color.B * 255 + 0.5))
					if callback then callback(color) end
				end

				local draggingSV = false
				local draggingHue = false

				SVBox.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						draggingSV = true
						local posX = math.clamp(input.Position.X - SVBox.AbsolutePosition.X, 0, SVBox.AbsoluteSize.X)
						local posY = math.clamp(input.Position.Y - SVBox.AbsolutePosition.Y, 0, SVBox.AbsoluteSize.Y)
						s = posX / SVBox.AbsoluteSize.X
						v = 1 - (posY / SVBox.AbsoluteSize.Y)
						UpdateColor()
					end
				end)

				HueBar.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						draggingHue = true
						local posY = math.clamp(input.Position.Y - HueBar.AbsolutePosition.Y, 0, HueBar.AbsoluteSize.Y)
						h = posY / HueBar.AbsoluteSize.Y
						UpdateColor()
					end
				end)

				UserInputService.InputChanged:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
						if draggingSV then
							local posX = math.clamp(input.Position.X - SVBox.AbsolutePosition.X, 0, SVBox.AbsoluteSize.X)
							local posY = math.clamp(input.Position.Y - SVBox.AbsolutePosition.Y, 0, SVBox.AbsoluteSize.Y)
							s = posX / SVBox.AbsoluteSize.X
							v = 1 - (posY / SVBox.AbsoluteSize.Y)
							UpdateColor()
						end
						if draggingHue then
							local posY = math.clamp(input.Position.Y - HueBar.AbsolutePosition.Y, 0, HueBar.AbsoluteSize.Y)
							h = posY / HueBar.AbsoluteSize.Y
							UpdateColor()
						end
					end
				end)

				UserInputService.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						draggingSV = false
						draggingHue = false
					end
				end)

				ColorValBox.FocusLost:Connect(function()
					local r, g, b = ColorValBox.Text:match("rgb%s*%(%s*(%d+)%s*,%s*(%d+)%s*,%s*(%d+)%s*%)")
					if r and g and b then
						color = Color3.fromRGB(math.clamp(tonumber(r), 0, 255), math.clamp(tonumber(g), 0, 255), math.clamp(tonumber(b), 0, 255))
						h, s, v = color:ToHSV()
						UpdateColor()
					else
						local hex = ColorValBox.Text:gsub("#", "")
						if #hex == 6 then
							local hr, hg, hb = tonumber(hex:sub(1,2), 16), tonumber(hex:sub(3,4), 16), tonumber(hex:sub(5,6), 16)
							if hr and hg and hb then
								color = Color3.fromRGB(hr, hg, hb)
								h, s, v = color:ToHSV()
								UpdateColor()
							end
						end
					end
				end)

				PreviewBtn.MouseButton1Click:Connect(function()
					isOpen = not isOpen
					PickerPanel.Visible = isOpen
					Container.Size = isOpen and UDim2.new(1, 0, 0, 172) or UDim2.new(1, 0, 0, 24)
				end)

				local Picker = {}
				Picker.Set = function(val)
					color = val
					h, s, v = color:ToHSV()
					UpdateColor()
				end
				Picker.Get = function()
					return { r = math.floor(color.R * 255 + 0.5), g = math.floor(color.G * 255 + 0.5), b = math.floor(color.B * 255 + 0.5) }
				end

				if configKey then
					ConfigRegistry[configKey] = {
						Get = function()
							return { r = math.floor(color.R * 255 + 0.5), g = math.floor(color.G * 255 + 0.5), b = math.floor(color.B * 255 + 0.5) }
						end,
						Set = function(val)
							if type(val) == "table" and val.r then
								Picker.Set(Color3.fromRGB(val.r, val.g, val.b))
							end
						end
					}
				end

				return Picker
			end

			function Section:AddButton(btnConfig)
				btnConfig = btnConfig or {}
				local buttonText = btnConfig.Name or "Button"
				local callback = btnConfig.Callback

				local Container = Instance.new("Frame")
				Container.Size = UDim2.new(1, 0, 0, 24)
				Container.BackgroundTransparency = 1
				Container.Parent = SecContent

				local BtnBg = Instance.new("Frame")
				BtnBg.Size = UDim2.new(1, 0, 1, 0)
				BtnBg.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				BtnBg.BorderSizePixel = 0
				BtnBg.Parent = Container

				local BtnCorner = Instance.new("UICorner")
				BtnCorner.CornerRadius = UDim.new(0, 5)
				BtnCorner.Parent = BtnBg

				local BtnGradient = Instance.new("UIGradient")
				BtnGradient.Rotation = 90
				BtnGradient.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(28, 28, 35)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(16, 16, 20))
				})
				BtnGradient.Parent = BtnBg

				local BtnStroke = Instance.new("UIStroke")
				BtnStroke.Color = Color3.fromRGB(45, 45, 55)
				BtnStroke.Thickness = 1.2
				BtnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				BtnStroke.Parent = BtnBg

				local Button = Instance.new("TextButton")
				Button.Size = UDim2.new(1, 0, 1, 0)
				Button.BackgroundTransparency = 1
				Button.FontFace = FONT_MEDIUM
				Button.Text = string.lower(buttonText)
				Button.TextColor3 = COLOR_TEXT_WHITE
				Button.TextScaled = true
				Button.AutoButtonColor = false
				Button.Parent = Container

				local TextConstraint = Instance.new("UITextSizeConstraint")
				TextConstraint.MaxTextSize = 13
				TextConstraint.MinTextSize = 8
				TextConstraint.Parent = Button

				local BtnPadding = Instance.new("UIPadding")
				BtnPadding.PaddingTop = UDim.new(0, 4)
				BtnPadding.PaddingBottom = UDim.new(0, 4)
				BtnPadding.Parent = Button

				Button.MouseEnter:Connect(function()
					BtnGradient.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(38, 38, 48)), ColorSequenceKeypoint.new(1, Color3.fromRGB(24, 24, 30)) })
					BtnStroke.Color = Color3.fromRGB(65, 65, 80)
				end)
				Button.MouseLeave:Connect(function()
					BtnGradient.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(28, 28, 35)), ColorSequenceKeypoint.new(1, Color3.fromRGB(16, 16, 20)) })
					BtnStroke.Color = Color3.fromRGB(45, 45, 55)
				end)
				Button.MouseButton1Down:Connect(function()
					BtnGradient.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 20, 25)), ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 12, 16)) })
				end)
				Button.MouseButton1Up:Connect(function()
					BtnGradient.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(38, 38, 48)), ColorSequenceKeypoint.new(1, Color3.fromRGB(24, 24, 30)) })
				end)
				Button.MouseButton1Click:Connect(function()
					if callback then callback() end
				end)

				return Container
			end

			function Section:AddKeybind(keybindConfig)
				keybindConfig = keybindConfig or {}
				local labelText = keybindConfig.Name or "Keybind"
				local defaultKey = keybindConfig.Default or Enum.UserInputType.MouseButton3
				local callback = keybindConfig.Callback
				local configKey = keybindConfig.ConfigKey

				local boundKey = defaultKey
				local binding = false

				local Container = Instance.new("Frame")
				Container.Size = UDim2.new(1, 0, 0, 22)
				Container.BackgroundTransparency = 1
				Container.Parent = SecContent

				local Lbl = Instance.new("TextLabel")
				Lbl.Size = UDim2.new(1, -60, 1, 0)
				Lbl.BackgroundTransparency = 1
				Lbl.FontFace = FONT_MEDIUM
				Lbl.Text = labelText
				Lbl.TextColor3 = COLOR_TEXT_MUTED
				Lbl.TextSize = 12
				Lbl.TextXAlignment = Enum.TextXAlignment.Left
				Lbl.Parent = Container

				local KeyBtnHolder = Instance.new("Frame")
				KeyBtnHolder.Size = UDim2.new(0, 36, 0, 20)
				KeyBtnHolder.Position = UDim2.new(1, 0, 0.5, 0)
				KeyBtnHolder.AnchorPoint = Vector2.new(1, 0.5)
				KeyBtnHolder.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				KeyBtnHolder.BorderSizePixel = 0
				KeyBtnHolder.Parent = Container

				local KeyCorner = Instance.new("UICorner")
				KeyCorner.CornerRadius = UDim.new(0, 5)
				KeyCorner.Parent = KeyBtnHolder

				local KeyGradient = Instance.new("UIGradient")
				KeyGradient.Rotation = 90
				KeyGradient.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(28, 28, 35)), ColorSequenceKeypoint.new(1, Color3.fromRGB(16, 16, 20)) })
				KeyGradient.Parent = KeyBtnHolder

				local KeyStroke = Instance.new("UIStroke")
				KeyStroke.Color = Color3.fromRGB(45, 45, 55)
				KeyStroke.Thickness = 1.2
				KeyStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				KeyStroke.Parent = KeyBtnHolder

				local KeyBtn = Instance.new("TextButton")
				KeyBtn.Size = UDim2.new(1, 0, 1, 0)
				KeyBtn.BackgroundTransparency = 1
				KeyBtn.FontFace = FONT_BOLD
				KeyBtn.TextSize = 11
				KeyBtn.TextColor3 = COLOR_TEXT_WHITE
				KeyBtn.AutoButtonColor = false
				KeyBtn.Parent = KeyBtnHolder

				local function FormatKey(key)
					if not key then return "None" end
					if typeof(key) == "EnumItem" then
						if key.EnumType == Enum.KeyCode then
							if key == Enum.KeyCode.Unknown then return "None" end
							return key.Name
						elseif key.EnumType == Enum.UserInputType then
							if key == Enum.UserInputType.MouseButton1 then return "M1" end
							if key == Enum.UserInputType.MouseButton2 then return "M2" end
							if key == Enum.UserInputType.MouseButton3 then return "M3" end
							if key == Enum.UserInputType.MouseButton4 then return "M4" end
							if key == Enum.UserInputType.MouseButton5 then return "M5" end
						end
					end
					return tostring(key)
				end

				local function UpdateText()
					if binding then
						KeyBtn.Text = "..."
						KeyStroke.Color = COLOR_TEXT_WHITE
						KeyGradient.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(38, 38, 48)), ColorSequenceKeypoint.new(1, Color3.fromRGB(24, 24, 30)) })
						Lbl.TextColor3 = COLOR_TEXT_WHITE
					else
						KeyBtn.Text = FormatKey(boundKey)
						KeyStroke.Color = Color3.fromRGB(45, 45, 55)
						KeyGradient.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(28, 28, 35)), ColorSequenceKeypoint.new(1, Color3.fromRGB(16, 16, 20)) })
						Lbl.TextColor3 = COLOR_TEXT_MUTED
					end
					local textSize = TextService:GetTextSize(KeyBtn.Text, 11, Enum.Font.SourceSans, Vector2.new(120, 20))
					KeyBtnHolder.Size = UDim2.new(0, math.max(34, textSize.X + 14), 0, 20)
				end

				UpdateText()

				KeyBtn.MouseEnter:Connect(function()
					if not binding then
						KeyGradient.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(38, 38, 48)), ColorSequenceKeypoint.new(1, Color3.fromRGB(24, 24, 30)) })
						KeyStroke.Color = Color3.fromRGB(65, 65, 80)
					end
				end)
				KeyBtn.MouseLeave:Connect(function()
					if not binding then
						KeyGradient.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(28, 28, 35)), ColorSequenceKeypoint.new(1, Color3.fromRGB(16, 16, 20)) })
						KeyStroke.Color = Color3.fromRGB(45, 45, 55)
					end
				end)
				KeyBtn.MouseButton1Click:Connect(function()
					binding = true
					UpdateText()
				end)

				UserInputService.InputBegan:Connect(function(input, gameProcessed)
					if binding then
						if input.UserInputType == Enum.UserInputType.Keyboard then
							boundKey = input.KeyCode == Enum.KeyCode.Escape and nil or input.KeyCode
							binding = false
							UpdateText()
							if callback then callback(boundKey) end
						elseif string.find(input.UserInputType.Name, "MouseButton") then
							boundKey = input.UserInputType
							binding = false
							UpdateText()
							if callback then callback(boundKey) end
						end
					end
				end)

				local Keybind = {}
				Keybind.Get = function() return boundKey end
				Keybind.Set = function(val)
					boundKey = val
					UpdateText()
				end

				if configKey then
					ConfigRegistry[configKey] = {
						Get = function()
							if not boundKey then return nil end
							if typeof(boundKey) == "EnumItem" then return tostring(boundKey) end
							return nil
						end,
						Set = function(val)
							if type(val) == "string" then
								local ok, enumVal = pcall(function() return Enum.KeyCode[val] end)
								if ok and enumVal then
									Keybind.Set(enumVal)
								end
							end
						end
					}
				end

				return Keybind
			end

			function Section:AddSearchDropdown(dropConfig)
				dropConfig = dropConfig or {}
				local labelText = dropConfig.Name or "Search Dropdown"
				local callback = dropConfig.Callback
				local configKey = dropConfig.ConfigKey
				local playerMode = dropConfig.Player == true
				local teamMode = dropConfig.Team == true

				local selected = nil
				local isOpen = false
				local allOptions = {}

				local function BuildOptions()
					allOptions = {}
					if playerMode then
						for _, p in ipairs(Players:GetPlayers()) do
							table.insert(allOptions, { label = p.Name, type = "player", object = p })
						end
					end
					if teamMode then
						local teamsService = game:FindService("Teams")
						if teamsService then
							for _, t in ipairs(teamsService:GetTeams()) do
								table.insert(allOptions, { label = t.Name, type = "team", object = t })
							end
						end
					end
				end

				BuildOptions()

				local Container = Instance.new("Frame")
				Container.Size = UDim2.new(1, 0, 0, 48)
				Container.BackgroundTransparency = 1
				Container.Parent = SecContent

				local Lbl = Instance.new("TextLabel")
				Lbl.Size = UDim2.new(1, 0, 0, 16)
				Lbl.BackgroundTransparency = 1
				Lbl.FontFace = FONT_MEDIUM
				Lbl.Text = labelText
				Lbl.TextColor3 = COLOR_TEXT_MUTED
				Lbl.TextSize = 12
				Lbl.TextXAlignment = Enum.TextXAlignment.Left
				Lbl.Parent = Container

				local Header = Instance.new("Frame")
				Header.Size = UDim2.new(1, 0, 0, 26)
				Header.Position = UDim2.new(0, 0, 0, 18)
				Header.BackgroundColor3 = COLOR_BOX_INACTIVE
				Header.BorderSizePixel = 0
				Header.Parent = Container

				local HeaderCorner = Instance.new("UICorner")
				HeaderCorner.CornerRadius = UDim.new(0, 5)
				HeaderCorner.Parent = Header

				local HeaderStroke = Instance.new("UIStroke")
				HeaderStroke.Color = COLOR_BOX_BORDER
				HeaderStroke.Thickness = 1
				HeaderStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				HeaderStroke.Parent = Header

				local SearchBox = Instance.new("TextBox")
				SearchBox.Size = UDim2.new(1, -28, 1, 0)
				SearchBox.Position = UDim2.new(0, 8, 0, 0)
				SearchBox.BackgroundTransparency = 1
				SearchBox.FontFace = FONT_MEDIUM
				SearchBox.PlaceholderText = selected or "search..."
				SearchBox.PlaceholderColor3 = COLOR_TEXT_SUB
				SearchBox.Text = ""
				SearchBox.TextColor3 = COLOR_TEXT_WHITE
				SearchBox.TextSize = 12
				SearchBox.TextXAlignment = Enum.TextXAlignment.Left
				SearchBox.ClearTextOnFocus = false
				SearchBox.Parent = Header

				local Chevron = Instance.new("ImageLabel")
				Chevron.Size = UDim2.new(0, 12, 0, 12)
				Chevron.Position = UDim2.new(1, -8, 0.5, 0)
				Chevron.AnchorPoint = Vector2.new(1, 0.5)
				Chevron.BackgroundTransparency = 1
				Chevron.ImageColor3 = COLOR_TEXT_MUTED
				ApplyIcon(Chevron, "chevron-down")
				Chevron.Parent = Header

				local OptionHolder = Instance.new("Frame")
				OptionHolder.Size = UDim2.new(1, 0, 0, 0)
				OptionHolder.Position = UDim2.new(0, 0, 0, 48)
				OptionHolder.BackgroundColor3 = COLOR_BOX_INACTIVE
				OptionHolder.BorderSizePixel = 0
				OptionHolder.Visible = false
				OptionHolder.ClipsDescendants = true
				OptionHolder.ZIndex = 10
				OptionHolder.Parent = Container

				local HolderCorner = Instance.new("UICorner")
				HolderCorner.CornerRadius = UDim.new(0, 5)
				HolderCorner.Parent = OptionHolder

				local HolderStroke = Instance.new("UIStroke")
				HolderStroke.Color = COLOR_BOX_BORDER
				HolderStroke.Thickness = 1
				HolderStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				HolderStroke.Parent = OptionHolder

				local HolderScrollFrame = Instance.new("ScrollingFrame")
				HolderScrollFrame.Size = UDim2.new(1, 0, 1, 0)
				HolderScrollFrame.BackgroundTransparency = 1
				HolderScrollFrame.BorderSizePixel = 0
				HolderScrollFrame.ScrollBarThickness = 3
				HolderScrollFrame.ScrollBarImageColor3 = COLOR_BORDER
				HolderScrollFrame.ScrollingDirection = Enum.ScrollingDirection.Y
				HolderScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
				HolderScrollFrame.Parent = OptionHolder

				local HolderLayout = Instance.new("UIListLayout")
				HolderLayout.SortOrder = Enum.SortOrder.LayoutOrder
				HolderLayout.Padding = UDim.new(0, 2)
				HolderLayout.Parent = HolderScrollFrame

				local HolderPadding = Instance.new("UIPadding")
				HolderPadding.PaddingTop = UDim.new(0, 4)
				HolderPadding.PaddingBottom = UDim.new(0, 4)
				HolderPadding.PaddingLeft = UDim.new(0, 4)
				HolderPadding.PaddingRight = UDim.new(0, 4)
				HolderPadding.Parent = HolderScrollFrame

				local function RebuildList(query)
					for _, child in ipairs(HolderScrollFrame:GetChildren()) do
						if child:IsA("TextButton") or child:IsA("Frame") then child:Destroy() end
					end
					BuildOptions()
					local filtered = {}
					local lower = string.lower(query or "")
					for _, opt in ipairs(allOptions) do
						if lower == "" or string.find(string.lower(opt.label), lower, 1, true) then
							table.insert(filtered, opt)
						end
					end
					for _, opt in ipairs(filtered) do
						local RowFrame = Instance.new("Frame")
						RowFrame.Size = UDim2.new(1, 0, 0, 24)
						RowFrame.BackgroundTransparency = 1
						RowFrame.Parent = HolderScrollFrame

						local RowLayout = Instance.new("UIListLayout")
						RowLayout.FillDirection = Enum.FillDirection.Horizontal
						RowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
						RowLayout.Padding = UDim.new(0, 6)
						RowLayout.Parent = RowFrame

						local RowPad = Instance.new("UIPadding")
						RowPad.PaddingLeft = UDim.new(0, 4)
						RowPad.Parent = RowFrame

						if opt.type == "player" then
							local AvatarImg = Instance.new("ImageLabel")
							AvatarImg.Size = UDim2.new(0, 16, 0, 16)
							AvatarImg.BackgroundTransparency = 1
							AvatarImg.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(opt.object.UserId) .. "&w=48&h=48"
							AvatarImg.Parent = RowFrame

							local AvatarCorner = Instance.new("UICorner")
							AvatarCorner.CornerRadius = UDim.new(1, 0)
							AvatarCorner.Parent = AvatarImg
						elseif opt.type == "team" then
							local TeamDot = Instance.new("Frame")
							TeamDot.Size = UDim2.new(0, 10, 0, 10)
							TeamDot.BackgroundColor3 = opt.object.TeamColor.Color
							TeamDot.BorderSizePixel = 0
							TeamDot.Parent = RowFrame

							local DotCorner = Instance.new("UICorner")
							DotCorner.CornerRadius = UDim.new(1, 0)
							DotCorner.Parent = TeamDot
						end

						local OptBtn = Instance.new("TextButton")
						OptBtn.Size = UDim2.new(1, -30, 1, 0)
						OptBtn.BackgroundTransparency = 1
						OptBtn.FontFace = FONT_REGULAR
						OptBtn.Text = opt.label
						OptBtn.TextColor3 = (opt.label == selected) and COLOR_TEXT_WHITE or COLOR_TEXT_MUTED
						OptBtn.TextSize = 11
						OptBtn.TextXAlignment = Enum.TextXAlignment.Left
						OptBtn.AutoButtonColor = false
						OptBtn.Parent = RowFrame

						OptBtn.MouseEnter:Connect(function()
							OptBtn.TextColor3 = COLOR_TEXT_WHITE
						end)
						OptBtn.MouseLeave:Connect(function()
							if opt.label ~= selected then
								OptBtn.TextColor3 = COLOR_TEXT_MUTED
							end
						end)
						OptBtn.MouseButton1Click:Connect(function()
							selected = opt.label
							SearchBox.PlaceholderText = selected
							SearchBox.Text = ""
							isOpen = false
							OptionHolder.Visible = false
							Chevron.Rotation = 0
							HeaderStroke.Color = COLOR_BOX_BORDER
							Container.Size = UDim2.new(1, 0, 0, 48)
							if callback then callback(selected, opt.type, opt.object) end
						end)
					end
					HolderLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
						HolderScrollFrame.CanvasSize = UDim2.new(0, 0, 0, HolderLayout.AbsoluteContentSize.Y)
					end)
					local count = #filtered
					local listHeight = math.min(count * 26 + 8, 120)
					OptionHolder.Size = UDim2.new(1, 0, 0, listHeight)
					Container.Size = UDim2.new(1, 0, 0, 48 + listHeight + 4)
				end

				local function OpenList()
					isOpen = true
					OptionHolder.Visible = true
					Chevron.Rotation = 180
					HeaderStroke.Color = COLOR_TEXT_WHITE
					RebuildList(SearchBox.Text)
				end

				local function CloseList()
					isOpen = false
					OptionHolder.Visible = false
					Chevron.Rotation = 0
					HeaderStroke.Color = COLOR_BOX_BORDER
					Container.Size = UDim2.new(1, 0, 0, 48)
				end

				SearchBox.Focused:Connect(function()
					OpenList()
				end)
				SearchBox.FocusLost:Connect(function()
					task.delay(0.15, function()
						if not SearchBox:IsFocused() then
							CloseList()
						end
					end)
				end)
				SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
					if isOpen then
						RebuildList(SearchBox.Text)
					end
				end)

				local SearchDropdown = {}
				SearchDropdown.Get = function() return selected end
				SearchDropdown.Set = function(val)
					selected = val
					SearchBox.PlaceholderText = val or "search..."
					SearchBox.Text = ""
				end

				if configKey then
					ConfigRegistry[configKey] = { Get = SearchDropdown.Get, Set = SearchDropdown.Set }
				end

				return SearchDropdown
			end

			function Section:AddImage(imageConfig)
				imageConfig = imageConfig or {}
				local imageId = imageConfig.ImageId or 0
				local imageWidth = imageConfig.Width or 100
				local imageHeight = imageConfig.Height or 100
				local imageRotation = imageConfig.Rotation or 0
				local imageScaleType = imageConfig.ScaleType or Enum.ScaleType.Fit
				local imageColor = imageConfig.Color or Color3.fromRGB(255, 255, 255)
				local imageTransparency = imageConfig.Transparency or 0
				local labelText = imageConfig.Name

				local totalHeight = imageHeight + (labelText and 20 or 0) + 8

				local Container = Instance.new("Frame")
				Container.Size = UDim2.new(1, 0, 0, totalHeight)
				Container.BackgroundTransparency = 1
				Container.ClipsDescendants = false
				Container.Parent = SecContent

				if labelText then
					local Lbl = Instance.new("TextLabel")
					Lbl.Size = UDim2.new(1, 0, 0, 16)
					Lbl.BackgroundTransparency = 1
					Lbl.FontFace = FONT_MEDIUM
					Lbl.Text = labelText
					Lbl.TextColor3 = COLOR_TEXT_MUTED
					Lbl.TextSize = 12
					Lbl.TextXAlignment = Enum.TextXAlignment.Left
					Lbl.Parent = Container
				end

				local yOffset = labelText and 20 or 0

				local ImageFrame = Instance.new("Frame")
				ImageFrame.Size = UDim2.new(0, imageWidth, 0, imageHeight)
				ImageFrame.Position = UDim2.new(0, 0, 0, yOffset)
				ImageFrame.BackgroundTransparency = 1
				ImageFrame.Rotation = imageRotation
				ImageFrame.Parent = Container

				local ImageLabel = Instance.new("ImageLabel")
				ImageLabel.Size = UDim2.new(1, 0, 1, 0)
				ImageLabel.BackgroundTransparency = 1
				ImageLabel.Image = type(imageId) == "number" and ("rbxassetid://" .. imageId) or tostring(imageId)
				ImageLabel.ImageColor3 = imageColor
				ImageLabel.ImageTransparency = imageTransparency
				ImageLabel.ScaleType = imageScaleType
				ImageLabel.Parent = ImageFrame

				local Image = {}
				Image.SetImageId = function(id)
					ImageLabel.Image = type(id) == "number" and ("rbxassetid://" .. id) or tostring(id)
				end
				Image.SetRotation = function(r)
					ImageFrame.Rotation = r
				end
				Image.SetSize = function(w, h)
					ImageFrame.Size = UDim2.new(0, w, 0, h)
					Container.Size = UDim2.new(1, 0, 0, h + (labelText and 20 or 0) + 8)
				end
				Image.SetColor = function(c)
					ImageLabel.ImageColor3 = c
				end
				Image.SetTransparency = function(t)
					ImageLabel.ImageTransparency = t
				end
				Image.GetFrame = function()
					return ImageFrame
				end

				return Image
			end

			function Section:ApplyConfigManager(configManagerConfig)
				configManagerConfig = configManagerConfig or {}
				local folder = self._window._configFolder

				local currentConfigNameInput
				local configDropdown
				local autoloadLabel

				local function RefreshDropdown()
					local configs = ListConfigs(folder)
					local autoload = GetAutoload(folder)
					if autoloadLabel then
						autoloadLabel.Text = autoload and ("autoload: " .. autoload) or "autoload: none"
					end
					if configDropdown and configDropdown._optionHolder then
						for _, child in ipairs(configDropdown._optionHolder:GetChildren()) do
							if child:IsA("TextButton") then child:Destroy() end
						end
						for _, cfgName in ipairs(configs) do
							local OptBtn = Instance.new("TextButton")
							OptBtn.Size = UDim2.new(1, 0, 0, 22)
							OptBtn.BackgroundColor3 = COLOR_ACTIVE_BG
							OptBtn.BackgroundTransparency = (cfgName == configDropdown._selected) and 0 or 1
							OptBtn.BorderSizePixel = 0
							OptBtn.FontFace = FONT_REGULAR
							OptBtn.Text = cfgName
							OptBtn.TextColor3 = (cfgName == configDropdown._selected) and COLOR_TEXT_WHITE or COLOR_TEXT_MUTED
							OptBtn.TextSize = 11
							OptBtn.TextXAlignment = Enum.TextXAlignment.Left
							OptBtn.AutoButtonColor = false
							OptBtn.Parent = configDropdown._optionHolder

							local OptPad = Instance.new("UIPadding")
							OptPad.PaddingLeft = UDim.new(0, 6)
							OptPad.Parent = OptBtn

							local OptCorner = Instance.new("UICorner")
							OptCorner.CornerRadius = UDim.new(0, 4)
							OptCorner.Parent = OptBtn

							OptBtn.MouseEnter:Connect(function()
								OptBtn.BackgroundTransparency = 0
								OptBtn.TextColor3 = COLOR_TEXT_WHITE
							end)
							OptBtn.MouseLeave:Connect(function()
								if cfgName ~= configDropdown._selected then
									OptBtn.BackgroundTransparency = 1
									OptBtn.TextColor3 = COLOR_TEXT_MUTED
								end
							end)
							OptBtn.MouseButton1Click:Connect(function()
								configDropdown._selected = cfgName
								configDropdown._selText.Text = cfgName
								configDropdown._isOpen = false
								configDropdown._optionHolder.Visible = false
								configDropdown._chevron.Rotation = 0
								configDropdown._headerStroke.Color = COLOR_BOX_BORDER
								configDropdown._container.Size = UDim2.new(1, 0, 0, 48)
								for _, child2 in ipairs(configDropdown._optionHolder:GetChildren()) do
									if child2:IsA("TextButton") then
										local isSel = (child2.Text == configDropdown._selected)
										child2.BackgroundTransparency = isSel and 0 or 1
										child2.TextColor3 = isSel and COLOR_TEXT_WHITE or COLOR_TEXT_MUTED
									end
								end
							end)
						end
					end
				end

				local NameInputContainer = Instance.new("Frame")
				NameInputContainer.Size = UDim2.new(1, 0, 0, 48)
				NameInputContainer.BackgroundTransparency = 1
				NameInputContainer.Parent = SecContent

				local NameLbl = Instance.new("TextLabel")
				NameLbl.Size = UDim2.new(1, 0, 0, 16)
				NameLbl.BackgroundTransparency = 1
				NameLbl.FontFace = FONT_MEDIUM
				NameLbl.Text = "Config Name"
				NameLbl.TextColor3 = COLOR_TEXT_WHITE
				NameLbl.TextSize = 12
				NameLbl.TextXAlignment = Enum.TextXAlignment.Left
				NameLbl.Parent = NameInputContainer

				local NameBoxContainer = Instance.new("Frame")
				NameBoxContainer.Size = UDim2.new(1, 0, 0, 24)
				NameBoxContainer.Position = UDim2.new(0, 0, 0, 18)
				NameBoxContainer.BackgroundColor3 = COLOR_BOX_INACTIVE
				NameBoxContainer.BorderSizePixel = 0
				NameBoxContainer.Parent = NameInputContainer

				local NameBoxCorner = Instance.new("UICorner")
				NameBoxCorner.CornerRadius = UDim.new(0, 5)
				NameBoxCorner.Parent = NameBoxContainer

				local NameBoxStroke = Instance.new("UIStroke")
				NameBoxStroke.Color = COLOR_BOX_BORDER
				NameBoxStroke.Thickness = 1
				NameBoxStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				NameBoxStroke.Parent = NameBoxContainer

				local NameBox = Instance.new("TextBox")
				NameBox.Size = UDim2.new(1, -16, 1, 0)
				NameBox.Position = UDim2.new(0, 8, 0, 0)
				NameBox.BackgroundTransparency = 1
				NameBox.FontFace = FONT_REGULAR
				NameBox.PlaceholderText = "my config"
				NameBox.PlaceholderColor3 = COLOR_TEXT_SUB
				NameBox.Text = ""
				NameBox.TextColor3 = COLOR_TEXT_WHITE
				NameBox.TextSize = 11
				NameBox.TextXAlignment = Enum.TextXAlignment.Left
				NameBox.ClearTextOnFocus = false
				NameBox.Parent = NameBoxContainer

				NameBox.Focused:Connect(function() NameBoxStroke.Color = COLOR_TEXT_WHITE end)
				NameBox.FocusLost:Connect(function() NameBoxStroke.Color = COLOR_BOX_BORDER end)

				currentConfigNameInput = NameBox

				local DropLabelContainer = Instance.new("Frame")
				DropLabelContainer.Size = UDim2.new(1, 0, 0, 48)
				DropLabelContainer.BackgroundTransparency = 1
				DropLabelContainer.Parent = SecContent

				local DropLbl = Instance.new("TextLabel")
				DropLbl.Size = UDim2.new(1, 0, 0, 16)
				DropLbl.BackgroundTransparency = 1
				DropLbl.FontFace = FONT_MEDIUM
				DropLbl.Text = "Configs"
				DropLbl.TextColor3 = COLOR_TEXT_MUTED
				DropLbl.TextSize = 12
				DropLbl.TextXAlignment = Enum.TextXAlignment.Left
				DropLbl.Parent = DropLabelContainer

				local DropHeader = Instance.new("TextButton")
				DropHeader.Size = UDim2.new(1, 0, 0, 26)
				DropHeader.Position = UDim2.new(0, 0, 0, 18)
				DropHeader.BackgroundColor3 = COLOR_BOX_INACTIVE
				DropHeader.BorderSizePixel = 0
				DropHeader.AutoButtonColor = false
				DropHeader.Text = ""
				DropHeader.Parent = DropLabelContainer

				local DropHeaderCorner = Instance.new("UICorner")
				DropHeaderCorner.CornerRadius = UDim.new(0, 5)
				DropHeaderCorner.Parent = DropHeader

				local DropHeaderStroke = Instance.new("UIStroke")
				DropHeaderStroke.Color = COLOR_BOX_BORDER
				DropHeaderStroke.Thickness = 1
				DropHeaderStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				DropHeaderStroke.Parent = DropHeader

				local DropSelText = Instance.new("TextLabel")
				DropSelText.Size = UDim2.new(1, -28, 1, 0)
				DropSelText.Position = UDim2.new(0, 8, 0, 0)
				DropSelText.BackgroundTransparency = 1
				DropSelText.FontFace = FONT_MEDIUM
				DropSelText.Text = "none"
				DropSelText.TextColor3 = COLOR_TEXT_WHITE
				DropSelText.TextSize = 12
				DropSelText.TextXAlignment = Enum.TextXAlignment.Left
				DropSelText.Parent = DropHeader

				local DropChevron = Instance.new("ImageLabel")
				DropChevron.Size = UDim2.new(0, 12, 0, 12)
				DropChevron.Position = UDim2.new(1, -8, 0.5, 0)
				DropChevron.AnchorPoint = Vector2.new(1, 0.5)
				DropChevron.BackgroundTransparency = 1
				DropChevron.ImageColor3 = COLOR_TEXT_MUTED
				ApplyIcon(DropChevron, "chevron-down")
				DropChevron.Parent = DropHeader

				local DropOptionHolder = Instance.new("Frame")
				DropOptionHolder.Size = UDim2.new(1, 0, 0, 0)
				DropOptionHolder.Position = UDim2.new(0, 0, 0, 48)
				DropOptionHolder.BackgroundColor3 = COLOR_BOX_INACTIVE
				DropOptionHolder.BorderSizePixel = 0
				DropOptionHolder.Visible = false
				DropOptionHolder.ClipsDescendants = true
				DropOptionHolder.ZIndex = 10
				DropOptionHolder.Parent = DropLabelContainer

				local DropHolderCorner = Instance.new("UICorner")
				DropHolderCorner.CornerRadius = UDim.new(0, 5)
				DropHolderCorner.Parent = DropOptionHolder

				local DropHolderStroke = Instance.new("UIStroke")
				DropHolderStroke.Color = COLOR_BOX_BORDER
				DropHolderStroke.Thickness = 1
				DropHolderStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				DropHolderStroke.Parent = DropOptionHolder

				local DropHolderLayout = Instance.new("UIListLayout")
				DropHolderLayout.SortOrder = Enum.SortOrder.LayoutOrder
				DropHolderLayout.Padding = UDim.new(0, 2)
				DropHolderLayout.Parent = DropOptionHolder

				local DropHolderPadding = Instance.new("UIPadding")
				DropHolderPadding.PaddingTop = UDim.new(0, 4)
				DropHolderPadding.PaddingBottom = UDim.new(0, 4)
				DropHolderPadding.PaddingLeft = UDim.new(0, 4)
				DropHolderPadding.PaddingRight = UDim.new(0, 4)
				DropHolderPadding.Parent = DropOptionHolder

				configDropdown = {
					_container = DropLabelContainer,
					_optionHolder = DropOptionHolder,
					_selText = DropSelText,
					_chevron = DropChevron,
					_headerStroke = DropHeaderStroke,
					_isOpen = false,
					_selected = nil
				}

				local function ToggleDropList()
					configDropdown._isOpen = not configDropdown._isOpen
					DropOptionHolder.Visible = configDropdown._isOpen
					DropChevron.Rotation = configDropdown._isOpen and 180 or 0
					DropHeaderStroke.Color = configDropdown._isOpen and COLOR_TEXT_WHITE or COLOR_BOX_BORDER
					if configDropdown._isOpen then
						RefreshDropdown()
						local configs = ListConfigs(folder)
						local totalHeight = (#configs * 24) + 8
						DropOptionHolder.Size = UDim2.new(1, 0, 0, math.min(math.max(totalHeight, 30), 120))
						DropLabelContainer.Size = UDim2.new(1, 0, 0, 48 + math.min(math.max(totalHeight, 30), 120) + 4)
					else
						DropLabelContainer.Size = UDim2.new(1, 0, 0, 48)
					end
				end

				DropHeader.MouseButton1Click:Connect(ToggleDropList)

				local AutoloadLabelFrame = Instance.new("Frame")
				AutoloadLabelFrame.Size = UDim2.new(1, 0, 0, 18)
				AutoloadLabelFrame.BackgroundTransparency = 1
				AutoloadLabelFrame.Parent = SecContent

				local AutoloadLbl = Instance.new("TextLabel")
				AutoloadLbl.Size = UDim2.new(1, 0, 1, 0)
				AutoloadLbl.BackgroundTransparency = 1
				AutoloadLbl.FontFace = FONT_MEDIUM
				AutoloadLbl.Text = "autoload: none"
				AutoloadLbl.TextColor3 = COLOR_TEXT_SUB
				AutoloadLbl.TextSize = 11
				AutoloadLbl.TextXAlignment = Enum.TextXAlignment.Left
				AutoloadLbl.Parent = AutoloadLabelFrame

				autoloadLabel = AutoloadLbl

				local function MakeActionButton(text, onClick)
					local Container2 = Instance.new("Frame")
					Container2.Size = UDim2.new(1, 0, 0, 24)
					Container2.BackgroundTransparency = 1
					Container2.Parent = SecContent

					local BtnBg2 = Instance.new("Frame")
					BtnBg2.Size = UDim2.new(1, 0, 1, 0)
					BtnBg2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
					BtnBg2.BorderSizePixel = 0
					BtnBg2.Parent = Container2

					local BtnCorner2 = Instance.new("UICorner")
					BtnCorner2.CornerRadius = UDim.new(0, 5)
					BtnCorner2.Parent = BtnBg2

					local BtnGrad2 = Instance.new("UIGradient")
					BtnGrad2.Rotation = 90
					BtnGrad2.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(28, 28, 35)), ColorSequenceKeypoint.new(1, Color3.fromRGB(16, 16, 20)) })
					BtnGrad2.Parent = BtnBg2

					local BtnStroke2 = Instance.new("UIStroke")
					BtnStroke2.Color = Color3.fromRGB(45, 45, 55)
					BtnStroke2.Thickness = 1.2
					BtnStroke2.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
					BtnStroke2.Parent = BtnBg2

					local Btn2 = Instance.new("TextButton")
					Btn2.Size = UDim2.new(1, 0, 1, 0)
					Btn2.BackgroundTransparency = 1
					Btn2.FontFace = FONT_MEDIUM
					Btn2.Text = string.lower(text)
					Btn2.TextColor3 = COLOR_TEXT_WHITE
					Btn2.TextScaled = true
					Btn2.AutoButtonColor = false
					Btn2.Parent = Container2

					local TC2 = Instance.new("UITextSizeConstraint")
					TC2.MaxTextSize = 13
					TC2.MinTextSize = 8
					TC2.Parent = Btn2

					local BP2 = Instance.new("UIPadding")
					BP2.PaddingTop = UDim.new(0, 4)
					BP2.PaddingBottom = UDim.new(0, 4)
					BP2.Parent = Btn2

					Btn2.MouseEnter:Connect(function()
						BtnGrad2.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(38, 38, 48)), ColorSequenceKeypoint.new(1, Color3.fromRGB(24, 24, 30)) })
						BtnStroke2.Color = Color3.fromRGB(65, 65, 80)
					end)
					Btn2.MouseLeave:Connect(function()
						BtnGrad2.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(28, 28, 35)), ColorSequenceKeypoint.new(1, Color3.fromRGB(16, 16, 20)) })
						BtnStroke2.Color = Color3.fromRGB(45, 45, 55)
					end)
					Btn2.MouseButton1Down:Connect(function()
						BtnGrad2.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 20, 25)), ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 12, 16)) })
					end)
					Btn2.MouseButton1Up:Connect(function()
						BtnGrad2.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(38, 38, 48)), ColorSequenceKeypoint.new(1, Color3.fromRGB(24, 24, 30)) })
					end)
					Btn2.MouseButton1Click:Connect(onClick)

					return Container2
				end

				MakeActionButton("Save Config", function()
					local name = currentConfigNameInput.Text
					if name == "" then
						Notify({ Title = "Config", Text = "Enter a config name first.", Icon = "x", Duration = 3 })
						return
					end
					local data = CollectConfigData()
					local ok = SaveConfig(folder, name, data)
					if ok then
						Notify({ Title = "Config", Text = "Saved \"" .. name .. "\".", Icon = "check", Duration = 3 })
						RefreshDropdown()
					else
						Notify({ Title = "Config", Text = "Failed to save config.", Icon = "x", Duration = 3 })
					end
				end)

				MakeActionButton("Load Config", function()
					local name = configDropdown._selected
					if not name then
						Notify({ Title = "Config", Text = "Select a config first.", Icon = "x", Duration = 3 })
						return
					end
					local data = LoadConfig(folder, name)
					if data then
						ApplyConfigData(data)
						Notify({ Title = "Config", Text = "Loaded \"" .. name .. "\".", Icon = "check", Duration = 3 })
					else
						Notify({ Title = "Config", Text = "Config not found.", Icon = "x", Duration = 3 })
					end
				end)

				MakeActionButton("Overwrite Config", function()
					local name = configDropdown._selected
					if not name then
						Notify({ Title = "Config", Text = "Select a config to overwrite.", Icon = "x", Duration = 3 })
						return
					end
					local data = CollectConfigData()
					local ok = SaveConfig(folder, name, data)
					if ok then
						Notify({ Title = "Config", Text = "Overwritten \"" .. name .. "\".", Icon = "check", Duration = 3 })
					else
						Notify({ Title = "Config", Text = "Failed to overwrite.", Icon = "x", Duration = 3 })
					end
				end)

				MakeActionButton("Set as Autoload", function()
					local name = configDropdown._selected
					if not name then
						Notify({ Title = "Config", Text = "Select a config first.", Icon = "x", Duration = 3 })
						return
					end
					SetAutoload(folder, name)
					AutoloadLbl.Text = "autoload: " .. name
					Notify({ Title = "Config", Text = "\"" .. name .. "\" set as autoload.", Icon = "check", Duration = 3 })
				end)

				local autoload = GetAutoload(folder)
				AutoloadLbl.Text = autoload and ("autoload: " .. autoload) or "autoload: none"

				if autoload then
					local data = LoadConfig(folder, autoload)
					if data then
						ApplyConfigData(data)
					end
				end
			end

			return Section
		end

		if #self._tabs == 0 then
			tabObj.ContentPage.Visible = true
			self._activeTabRef = tabObj
			SetTabActive(tabObj, true)
			UpdateHeader(tabName, tabIcon)
		end

		table.insert(self._tabs, tabObj)
		return Tab
	end

	return Window
end

Library.Notify = Notify

return Library

end)()


-- ===== hitboxers.gg -> AstraUI adapter =====
local Options = getgenv().Options or {}
local Toggles = getgenv().Toggles or {}
getgenv().Options = Options
getgenv().Toggles = Toggles

local SCRIPT_NAME = "hitboxers.gg"

local TAB_ICONS = {
    Main      = "14456045412",
    Farm      = "103344771690872",
    Extra     = "7733920644",
    ["Gun Mods"] = "7733955511",
    Visuals   = "9752605466",
    Player    = "118232317792968",
    Safe      = "76224309982741",
    Settings  = "7734053491",
}

-- Adapter Library object
local Library = {
    Options = Options,
    Toggles = Toggles,
    Theme = {},
    _unloaded = false,
    _unloadCallbacks = {},
    ThemeNames = { "Default" },
    CurrentTheme = "Default",
    FontNames = { "Default" },
}

-- Create the AstraUI window
local AstraWin = AstraLib.CreateWindow({
    Title = SCRIPT_NAME,
    ConfigFolder = "hitboxers_configs",
})

-- Notify
function Library:Notify(first, second, third)
    if getgenv().MiamiSuppressNotifications or self._unloaded then return end
    local title, body, duration
    if type(first) == "table" then
        title    = tostring(first.Title or first.title or "")
        body     = tostring(first.Content or first.content or first.Description or first.description or first.Text or first.text or "")
        duration = first.Duration or first.duration or second
    elseif type(second) == "string" then
        title, body, duration = tostring(first or ""), second, third
    else
        local raw = tostring(first or SCRIPT_NAME)
        local head, rest = string.match(raw, "^([^\n]*)\n(.*)$")
        if head then title, body = head, rest else title, body = raw, "" end
        duration = second
    end
    local text = title
    if body ~= "" then text = (title ~= "" and (title .. ": ") or "") .. body end
    text = (text:gsub("%s*\n%s*", " | "))
    if #text > 90 then text = text:sub(1, 87) .. "..." end
    pcall(function()
        AstraLib.Notify({ Title = title, Text = body ~= "" and body or title, Icon = "bell", Duration = tonumber(duration) or 4 })
    end)
end

function Library:OnUnload(callback)
    if type(callback) == "function" then table.insert(self._unloadCallbacks, callback) end
end

function Library:Unload()
    if self._unloaded then return end
    self._unloaded = true
    for _, cb in ipairs(self._unloadCallbacks) do pcall(cb) end
    pcall(function()
        local sg = game:GetService("CoreGui"):FindFirstChild("HitboxersGG")
        if not sg then
            sg = game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("HitboxersGG")
        end
        if sg then sg:Destroy() end
    end)
    if getgenv().__TacoPreviewPort == self then getgenv().__TacoPreviewPort = nil end
end

function Library:GetUIScale() return 1 end
function Library:SetUIScale(_v) end
function Library:SetUIFont(_v) end
function Library:SetTheme(_name) end
function Library:ChangeTheme(_name, _color) end
function Library:SetDPIScale() end
function Library.Toggle() end
Library.FitText = function() end

-- ---------- helpers ----------
local function safe(callback, ...)
    if type(callback) ~= "function" then return end
    local ok, err = pcall(callback, ...)
    if not ok then warn(tostring(err)) end
end

local function toMap(list)
    local m = {}
    if type(list) == "table" then
        for k, v in pairs(list) do
            if type(k) == "number" then m[v] = true elseif v then m[k] = true end
        end
    end
    return m
end

local function toList(map)
    local l = {}
    if type(map) == "table" then
        for k, v in pairs(map) do
            if type(k) == "number" then l[#l+1] = v elseif v then l[#l+1] = k end
        end
        table.sort(l, function(a, b) return tostring(a) < tostring(b) end)
    end
    return l
end

local function newFlag(flag)
    if flag == nil or flag == "" then return "hbgg_" .. tostring(math.random(100000, 999999)) end
    return tostring(flag)
end

-- Control wrapper: exposes .Value, :SetValue(), :OnChanged(), :GetState()
-- AstraUI elements use plain functions (el.Set(v), el.Get()), not methods.
local function makeControl(flag, kind, multi)
    local c = { Flag = flag, Type = kind, Values = {}, _changed = {}, _building = true }
    setmetatable(c, {
        __index = function(t, k)
            if k == "Value" then
                local el = rawget(t, "_el")
                if not el then return nil end
                local v = el.Get()
                if kind == "Dropdown" and multi then
                    -- AstraUI MultiDropdown.Get() returns a list; convert to map
                    if type(v) == "table" then return toMap(v) end
                end
                return v
            end
        end,
        __newindex = function(t, k, v)
            if k == "Value" then t:SetValue(v) else rawset(t, k, v) end
        end,
    })
    function c:SetValue(v)
        local el = rawget(self, "_el")
        if not el then return self end
        if kind == "Dropdown" and multi then v = toList(v) end
        if kind == "Slider" then v = tonumber(v) or v end
        el.Set(v)
        return self
    end
    c.Set = c.SetValue
    function c:GetState() return self.Value end
    function c:OnChanged(fn)
        if type(fn) == "function" then table.insert(self._changed, fn) end
        return self
    end
    function c:SetValues(values)
        self.Values = values or {}
        return self
    end
    c.Refresh = c.SetValues
    function c:SetVisible(v)
        return self
    end
    function c:SetText(t) return self end
    c.Lock   = function(self) return self end
    c.Unlock = function(self) return self end
    c.SetDisabled = function(self) return self end
    return c
end

local function wrapCallback(c, userCb, convert)
    return function(...)
        if c._building then return end
        local args = table.pack(...)
        if convert then args[1] = convert(args[1]) end
        for _, fn in ipairs(c._changed) do safe(fn, table.unpack(args, 1, args.n)) end
        safe(userCb, table.unpack(args, 1, args.n))
    end
end

-- ---------- Group ----------
local Group = {}
Group.__index = Group

function Group:AddLabel(text, _wrap)
    local sec = self.Section
    local el = sec:AddLabel(tostring(text or ""))
    -- el is a Frame; find the TextLabel inside for SetText support
    local textLabel = el:FindFirstChildOfClass("TextLabel")

    local label = { _section = sec, _el = el, _textLabel = textLabel }

    function label:SetText(value)
        if self._textLabel then
            pcall(function() self._textLabel.Text = tostring(value or "") end)
        end
        return self
    end

    function label:SetVisible(v)
        pcall(function() self._el.Visible = v ~= false end)
        return self
    end

    function label:AddKeyPicker(flag, data)
        flag = newFlag(flag)
        data = data or {}
        local c = makeControl(flag, "KeyPicker", false)
        -- MenuKeybind: AstraUI uses RightShift internally; expose a stub control
        if flag == "MenuKeybind" then
            local boundKey = tostring(data.Default or "RightShift")
            c._building = false
            setmetatable(c, {
                __index = function(t, k)
                    if k == "Value" then return boundKey end
                    return rawget(t, k)
                end,
                __newindex = function(t, k, v)
                    if k == "Value" then boundKey = tostring(v) else rawset(t, k, v) end
                end,
            })
            function c:SetValue(v) boundKey = tostring(v) return self end
            c.Set = c.SetValue
            function c:GetState() return boundKey end
            Options[flag] = c
            return c
        end
        local ok, defaultCode = pcall(function() return Enum.KeyCode[tostring(data.Default or "E")] end)
        local el = sec:AddKeybind({
            Name = tostring(data.Text or flag),
            Default = ok and defaultCode or Enum.KeyCode.E,
            Callback = wrapCallback(c, data.Callback),
            ConfigKey = flag,
        })
        c._el = { Get = el.Get, Set = el.Set }
        c._building = false
        Options[flag] = c
        return c
    end

    function label:AddColorPicker(flag, data)
        data = data or {}
        flag = newFlag(flag)
        local c = makeControl(flag, "Color", false)
        local el = sec:AddColorPicker({
            Name = tostring(flag),
            Default = data.Default or Color3.new(1, 1, 1),
            Callback = wrapCallback(c, data.Callback),
            ConfigKey = flag,
        })
        c._el = { Get = el.Get, Set = el.Set }
        c._building = false
        Options[flag] = c
        return c
    end

    return label
end

function Group:AddDivider() return self end

function Group:AddButton(textOrData, callback)
    local data = type(textOrData) == "table" and textOrData or { Text = textOrData, Func = callback }
    local action = data.Func or data.Callback or callback
    self.Section:AddButton({
        Name = tostring(data.Text or data.Name or data.Title or "Button"),
        Callback = function() safe(action) end,
    })
    return self
end

function Group:AddToggle(flag, data)
    if type(flag) == "table" then data, flag = flag, nil end
    data = data or {}
    flag = newFlag(flag or data.Flag)
    local c = makeControl(flag, "Toggle", false)
    local el = self.Section:AddToggle({
        Name = tostring(data.Text or data.Name or flag),
        Default = (data.Default == true or data.Value == true),
        Callback = wrapCallback(c, data.Callback or data.callback),
        ConfigKey = flag,
    })
    c._el = el
    c._building = false
    Options[flag] = c
    Toggles[flag] = c
    return c
end

function Group:AddSlider(flag, data)
    if type(flag) == "table" then data, flag = flag, nil end
    data = data or {}
    flag = newFlag(flag or data.Flag)
    local min = tonumber(data.Min) or 0
    local max = tonumber(data.Max) or 100
    local default = tonumber(data.Default) or min
    local c = makeControl(flag, "Slider", false)
    local el = self.Section:AddSlider({
        Name = tostring(data.Text or data.Name or flag),
        Min = min, Max = max, Default = default,
        Callback = wrapCallback(c, data.Callback or data.callback),
        ConfigKey = flag,
    })
    c._el = el
    c._building = false
    Options[flag] = c
    return c
end

function Group:AddDropdown(flag, data)
    if type(flag) == "table" then data, flag = flag, nil end
    data = data or {}
    flag = newFlag(flag or data.Flag)
    local values = data.Values or data.Items or {}
    local multi  = data.Multi == true
    local default = data.Default ~= nil and data.Default or data.Value
    if multi then
        default = toList(default)
    elseif type(default) == "number" then
        default = values[default]
    end
    local c = makeControl(flag, "Dropdown", multi)
    c.Values = values
    local el
    if multi then
        el = self.Section:AddMultiDropdown({
            Name    = tostring(data.Text or data.Name or flag),
            Options = values,
            Default = default or {},
            Callback = wrapCallback(c, data.Callback or data.callback, toMap),
            ConfigKey = flag,
        })
    else
        el = self.Section:AddDropdown({
            Name    = tostring(data.Text or data.Name or flag),
            Options = values,
            Default = default,
            Callback = wrapCallback(c, data.Callback or data.callback),
            ConfigKey = flag,
        })
    end
    c._el = el
    c._building = false
    Options[flag] = c
    return c
end

function Group:AddInput(flag, data)
    if type(flag) == "table" then data, flag = flag, nil end
    data = data or {}
    flag = newFlag(flag or data.Flag)
    local c = makeControl(flag, "Input", false)
    local el = self.Section:AddInput({
        Name        = tostring(data.Text or data.Name or flag),
        Default     = tostring(data.Default or data.Value or ""),
        Placeholder = data.Placeholder or "",
        Numeric     = data.Numeric == true,
        Callback    = wrapCallback(c, data.Callback or data.callback, tostring),
        ConfigKey   = flag,
    })
    c._el = el
    c._building = false
    Options[flag] = c
    return c
end

local function newGroup(section)
    return setmetatable({ Section = section }, Group)
end

-- ---------- Tabs / Window ----------
local function newTab(astraTab)
    local tab = {}
    function tab:AddLeftGroupbox(name)
        return newGroup(astraTab:CreateSection({ Name = tostring(name or "Group"), Side = "Left" }))
    end
    function tab:AddRightGroupbox(name)
        return newGroup(astraTab:CreateSection({ Name = tostring(name or "Group"), Side = "Right" }))
    end
    function tab:AddLeftTabbox(name)
        local box = {}
        function box:AddTab(tabName)
            return newGroup(astraTab:CreateSection({ Name = tostring(tabName or name or "Group"), Side = "Left" }))
        end
        return box
    end
    function tab:AddRightTabbox(name)
        local box = {}
        function box:AddTab(tabName)
            return newGroup(astraTab:CreateSection({ Name = tostring(tabName or name or "Group"), Side = "Right" }))
        end
        return box
    end
    return tab
end

local Window = {}
setmetatable(Window, {
    __index = function(_, k) end,
})

function Window:AddTab(name)
    local icon = TAB_ICONS[tostring(name)] or "layout"
    local astraTab = AstraWin:CreateTab({ Name = tostring(name), Icon = icon })
    return newTab(astraTab)
end

function Window:SetOpen(_v) end
function Window:Destroy() Library:Unload() end
Library._activeWindow = Window

getgenv().__TacoPreviewPort = Library
getgenv().MiamiSuppressNotifications = true

return Library, Window, Options, Toggles

end)()
end)()


-- Novakline polish: local version badge (no external branding or links).
do
    local Players = game:GetService("Players")
    local parent
    pcall(function() parent = (gethui and gethui()) or game:GetService("CoreGui") end)
    if not parent then parent = Players.LocalPlayer:FindFirstChildOfClass("PlayerGui") end
    if parent then
        local gui = Instance.new("ScreenGui")
        gui.Name = "HitboxersGG_Brand"
        gui.ResetOnSpawn = false
        gui.DisplayOrder = 2147482000
        pcall(function() if syn and syn.protect_gui then syn.protect_gui(gui) end end)
        gui.Parent = parent
        local badge = Instance.new("TextLabel")
        badge.AnchorPoint = Vector2.new(1, 1)
        badge.Position = UDim2.new(1, -14, 1, -14)
        badge.Size = UDim2.fromOffset(184, 30)
        badge.BackgroundColor3 = Color3.fromRGB(14, 22, 32)
        badge.BackgroundTransparency = 0.08
        badge.BorderSizePixel = 0
        badge.Font = Enum.Font.GothamBold
        badge.Text = "HITBOXERS.GG"
        badge.TextColor3 = Color3.fromRGB(105, 195, 255)
        badge.TextSize = 11
        badge.Parent = gui
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 9)
        corner.Parent = badge
        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(105, 195, 255)
        stroke.Transparency = 0.35
        stroke.Parent = badge
        local gradient = Instance.new("UIGradient")
        gradient.Color = ColorSequence.new(Color3.fromRGB(105, 195, 255), Color3.fromRGB(45, 70, 100))
        gradient.Transparency = NumberSequence.new(0.25)
        gradient.Parent = badge
        Library:OnUnload(function() pcall(function() gui:Destroy() end) end)
    end
end
local Tabs

SenseESPInterface = loadstring(game:HttpGet("https://raw.githubusercontent.com/boshyxd/rayfield/refs/heads/main/SenseSource.luau"))()
if SenseESPInterface then
    Library:Notify("[hitboxers.gg] ESP Menu\nLoading ESP...\nESP Menu library loaded successfully!\nESP Menu Initialized!", 2)
    SenseESPInterface.Load()
else
    Library:Notify("Error\nFailed to load ESP Menu.", 3)
end


Tabs = {
    Player = Window:AddTab('Player'),
    Main = Window:AddTab('Main'),
    Autofarm = Window:AddTab('Farm'),
    Extra = Window:AddTab('Extra'),
    GunMods = Window:AddTab('Gun Mods'),
    Visuals = Window:AddTab('Visuals'),
    ["Safe/Dupe"] = Window:AddTab('Safe'),
    Settings = Window:AddTab('Settings'),
}

MiamiBrandGroup = Tabs.Settings:AddLeftGroupbox("hitboxers.gg ")
MiamiBrandGroup:AddLabel("Script: hitboxers.gg")
MiamiBrandGroup:AddLabel("Discord: discord.gg/hitboxers.gg")
MiamiBrandGroup:AddButton("Copy Discord", function()
    if setclipboard then setclipboard("https://discord.gg/hitboxers.gg") end
    Library:Notify("hitboxers.gg\nCopied discord.gg/hitboxers.gg", 4)
end)
MiamiBrandGroup:AddButton("Test Button", function()
    getgenv().MiamiSuppressNotifications = false
    Library:Notify("Sament buttons are responding", 4)
end)




Players          = game:GetService("Players")
ReplicatedStorage= game:GetService("ReplicatedStorage")
RunService       = game:GetService("RunService")
UserInputService = game:GetService("UserInputService")
StarterGui       = game:GetService("StarterGui")
LocalPlayer      = Players.LocalPlayer
ProximityPromptService = game:GetService("ProximityPromptService")
Lighting         = game:GetService("Lighting")
CoreGui          = game:GetService("CoreGui")
TweenService     = game:GetService("TweenService")
Debris           = game:GetService("Debris")

flags = {}

MimaiUI = {
    Executor = (identifyexecutor and identifyexecutor()) or "Unknown",
    WatermarkStatus = "Loaded ",
    WatermarkKey = "RightShift",
}

-- Watermark, notifications and the open/close button are now provided by the lds13 UI.
function setWatermarkState(status, keybind)
    if status then MimaiUI.WatermarkStatus = tostring(status) end
    if keybind then MimaiUI.WatermarkKey = tostring(keybind) end
end

function sendNotification(title, text, duration)
    if getgenv().MiamiSuppressNotifications then
        return
    end
    pcall(function()
        Library:Notify({
            Title = tostring(title or "hitboxers.gg"),
            Content = tostring(text or ""),
            Duration = duration or 5,
        })
    end)
end

function notifyToggle(name, enabled)
    sendNotification(name, name .. (enabled and " enabled" or " disabled"))
end

function normalizeDropdownValue(v)
    return tostring(v)
end





getgenv().SwimMethod = getgenv().SwimMethod or false
Config = {}
function Config:Teleport(targetCFrame)
    local lp = Players.LocalPlayer
    local char = lp.Character or lp.CharacterAdded:Wait()
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum or not hrp or not targetCFrame then return false end

    getgenv().SwimMethod = true
    hum:ChangeState(Enum.HumanoidStateType.FallingDown)

    local n = 1
    local waitStarted = os.clock()
    repeat
        task.wait()
        n = n + 1
    until (n >= 40 and not lp:GetAttribute("LastACPos"))
        or (os.clock() - waitStarted >= 2.5)

    
    
    
    for _ = 1, 3 do
        if not hrp.Parent then break end
        hrp.CFrame = targetCFrame
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
        task.wait()
    end

    hum:ChangeState(Enum.HumanoidStateType.GettingUp)
    getgenv().SwimMethod = false
    return true
end

task.spawn(function()
    while task.wait() do
        if getgenv().SwimMethod then
            local lp = Players.LocalPlayer
            local char = lp.Character
            if char and char:FindFirstChildWhichIsA("Humanoid") then
                char:FindFirstChildWhichIsA("Humanoid"):ChangeState(Enum.HumanoidStateType.FallingDown)
            end
        end
    end
end)




WeaponMods = {
    InfiniteAmmo=false, InfiniteClips=false, Bullets80k=false,
    ModifyRecoilValue=false, ModifySpreadValue=false, DisableJamming=false,
    InstantReload=false, InstantEquip=false, ModifyFireRate=false,
    Automatic=false, DamageAmplified=false, SpoofAccuracy=false,
    InfiniteDamage=false,
    ReloadSpeed=0.2, EquipSpeed=0.2,
    FireRateSpeed=50, SpreadPercentage=50, RecoilPercentage=50,
}
GunOriginalColors = {}
GunChams = false
RainbowGun = false
GunChamsColor = Color3.fromRGB(0,200,0)

function getEquippedGunSetting()
    local character = LocalPlayer.Character
    if not character then return nil, nil end
    local tool = character:FindFirstChildOfClass("Tool")
    if not tool or not tool:FindFirstChild("Setting") then return nil, nil end
    local ok, settings = pcall(require, tool.Setting)
    if ok and type(settings) == "table" then return tool, settings end
end

function applyAllWeaponMods()
    local tool, settings = getEquippedGunSetting()
    if not settings then return end
    pcall(function()
        if WeaponMods.InfiniteAmmo then settings.Ammo=99999; settings.AmmoPerMag=99999; settings.LimitedAmmoEnabled=false end
        if WeaponMods.InfiniteClips then settings.Ammo=80000; settings.AmmoPerMag=80000; settings.LimitedAmmoEnabled=false end
        if WeaponMods.Bullets80k then
            settings.Ammo=80000; settings.AmmoPerMag=80000; settings.LimitedAmmoEnabled=false
            local gunLocal = tool:FindFirstChild("GunScript_Local")
            if gunLocal and type(getsenv) == "function" then
                pcall(function()
                    local env = getsenv(gunLocal)
                    if env and type(env.Reload) == "function" and type(debug.setupvalue) == "function" then
                        debug.setupvalue(env.Reload, 1, 80000); debug.setupvalue(env.Reload, 3, 80000)
                    end
                end)
            end
        end
        if WeaponMods.ModifyRecoilValue then settings.Recoil=0; settings.CameraRecoilingEnabled=false end
        if WeaponMods.ModifySpreadValue then settings.Spread=0; settings.SpreadX=0; settings.SpreadY=0; settings.Accuracy=1 end
        if WeaponMods.DisableJamming then settings.JamChance=0 end
        if WeaponMods.InstantReload then settings.ReloadTime = WeaponMods.ReloadSpeed or 0.1 end
        if WeaponMods.InstantEquip then settings.EquipTime = WeaponMods.EquipSpeed or 0.1; settings.EquippingTime = WeaponMods.EquipSpeed or 0.1 end
        if WeaponMods.ModifyFireRate then settings.FireRate = 0 end
        if WeaponMods.Automatic then settings.Auto = true end
        if (WeaponMods.DamageAmplified or WeaponMods.InfiniteDamage) then settings.BaseDamage = 1e9 end
        if WeaponMods.SpoofAccuracy then settings.Accuracy = 1 end
    end)
end

LocalPlayer.CharacterAdded:Connect(function(character)
    character.ChildAdded:Connect(function(c) if c:IsA("Tool") then task.defer(applyAllWeaponMods) end end)
end)
if LocalPlayer.Character then
    LocalPlayer.Character.ChildAdded:Connect(function(c) if c:IsA("Tool") then task.defer(applyAllWeaponMods) end end)
end
task.spawn(function() while task.wait(0.25) do pcall(applyAllWeaponMods) end end)

function MianiForce80kBullets()
    local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
    if not tool then sendNotification("Gun Mods","Hold a gun first!") return end
    pcall(function()
        if tool:FindFirstChild("Setting") then
            local config = require(tool.Setting)
            if type(config) == "table" then
                config.Ammo=80000; config.AmmoPerMag=80000; config.LimitedAmmoEnabled=false
            end
        end
        local gunLocal = tool:FindFirstChild("GunScript_Local")
        if gunLocal and type(getsenv) == "function" then
            local env = getsenv(gunLocal)
            if env and type(env.Reload) == "function" and type(debug.setupvalue) == "function" then
                debug.setupvalue(env.Reload, 1, 80000); debug.setupvalue(env.Reload, 3, 80000)
            end
        end
    end)
    sendNotification("Gun Mods","Forced 80k bullets on current gun.")
end

function MianiUpdateGunColor()
    if not GunChams then return end
    local char = LocalPlayer.Character
    local tool = char and char:FindFirstChildOfClass("Tool")
    if not tool then return end
    for _, v in pairs(tool:GetDescendants()) do
        if v:IsA("BasePart") then
            if not GunOriginalColors[v] then GunOriginalColors[v] = v.Color end
            if RainbowGun then v.Color = Color3.fromHSV((tick() % 5) / 5, 1, 1)
            else v.Color = GunChamsColor or Color3.fromRGB(0,200,0) end
            v.Material = Enum.Material.Neon
        end
    end
end
function MianiRestoreGunColor()
    for part, color in pairs(GunOriginalColors) do
        if part and part.Parent then part.Color=color; part.Material=Enum.Material.Plastic end
    end
    GunOriginalColors = {}
end
RunService.RenderStepped:Connect(function() pcall(MianiUpdateGunColor) end)


MianiEmotes = {
    ["CSnoop"] = 86123328011397,
    ["Air Cycle"] = 94324173536622,
    ["Assumptions"] = 91294374426630,
    ["Basketball Headspin"] = 92854797386719,
    ["Beat Da Koto Nai"] = 93497729736287,
    ["Biblically Accurate"] = 109873544976020,
    ["Billy Bounce"] = 137501135905857,
    ["Bird"] = 85513310484654,
    ["Caramelldansen"] = 88315693621494,
    ["Chinese Dance"] = 131758838511368,
    ["Classic Walk"] = 107806791584829,
    ["Cute Stomach Lay"] = 80754582835479,
    ["Da Hood Dance"] = 108171959207138,
    ["Fake Death"] = 88130117312312,
    ["Fight Stance"] = 116763940575803,
    ["Float"] = 89523370947906,
    ["Lay Float"] = 77840765435893,
    ["Floppin Fish"] = 79075971527754,
    ["Flying"] = 138433137191760,
    ["Flying Legs"] = 130932988394284,
    ["Fropper"] = 116039975531632,
    ["Fumo Flush"] = 107217181254431,
    ["Shoulder Taps"] = 85422671683973,
    ["Helicopter"] = 95301257497525,
    ["Helicopter 2"] = 91257498644328,
    ["Jackhammer"] = 91423662648449,
    ["Jojo Pose"] = 120629563851640,
    ["Laced"] = 135611169366768,
    ["Buddha"] = 86872878957632,
    ["Monstermash"] = 137883764619555,
    ["Oh Who Is You"] = 81389876138766,
    ["Parrot"] = 101810746304426,
    ["Push Up"] = 115703320436202,
    ["Rizz Backup"] = 131205329995035,
    ["Shot"] = 102691551292124,
    ["Slickback"] = 74288964113793,
    ["Soda Pop"] = 105459130960429,
    ["Take The L"] = 78653596566468,
    ["The Worm"] = 90333292347820,
    ["Spider Man Hang"] = 128616254665784,
    ["Weird Boy"] = 87025086742503,
    ["Xavier"] = 90802740360125,
    ["Dougie"] = 126035888065434,
    ["BACKFLIP"] = 15693621070,
}
MianiEmoteNames = {}
for n in pairs(MianiEmotes) do table.insert(MianiEmoteNames, n) end
table.sort(MianiEmoteNames)
MianiSelectedEmoteName = "Take The L"
MianiCurrentEmoteTrack = nil
MianiEmoteAnimCache = {}
MianiEmoteSettings = { Loop = true }

function MianiGetEmoteAnimator()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return nil end
    local a = hum:FindFirstChildOfClass("Animator")
    if not a then a = Instance.new("Animator"); a.Parent = hum end
    return a
end
function MianiStopAllTracks()
    local a = MianiGetEmoteAnimator()
    if a then for _, t in ipairs(a:GetPlayingAnimationTracks()) do pcall(function() t:Stop(0.1) end) end end
    MianiCurrentEmoteTrack = nil
end
function MianiPlayEmoteById(id, name)
    id = tonumber(id); if not id then return end
    local animator = MianiGetEmoteAnimator(); if not animator then return end
    MianiStopAllTracks()
    local anim = MianiEmoteAnimCache[id]
    if not anim then
        anim = Instance.new("Animation"); anim.AnimationId = "rbxassetid://" .. tostring(id)
        MianiEmoteAnimCache[id] = anim
    end
    local ok, track = pcall(function()
        local t = animator:LoadAnimation(anim)
        t.Priority = Enum.AnimationPriority.Action
        t.Looped = MianiEmoteSettings.Loop
        t:Play(0.1)
        return t
    end)
    if ok and track then
        MianiCurrentEmoteTrack = track
        sendNotification("Emotes","Playing: "..tostring(name or id))
    end
end




TargetUtilities = {
    SelectedPlayer = nil,
    SpectatePlayer = false,
    BringingPlayer = false,
    BringingNearestPlayer = false,
    AutoRagdoll = false,
    AutoKill = false,
    AutoKillMaxDistance = 350,
}
TargetPlayerNames = {}

function getTargetPlayerList()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer then table.insert(list, p.Name) end end
    table.sort(list); return list
end

function getSelectedTargetPlayer()
    local sel = normalizeDropdownValue(TargetUtilities.SelectedPlayer or flags["MainTargetPlayer"])
    if typeof(sel) == "Instance" and sel:IsA("Player") then return sel end
    if type(sel) == "string" and sel ~= "" then return Players:FindFirstChild(sel) end
end

function isValidTargetPlayer(p)
    if not p or p == LocalPlayer then return false end
    local c = p.Character; if not c then return false end
    local h = c:FindFirstChildOfClass("Humanoid")
    local r = c:FindFirstChild("HumanoidRootPart")
    return h and h.Health > 0 and r ~= nil
end

function getNearestTargetPlayer()
    local lr = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not lr then return nil end
    local n, nd = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if isValidTargetPlayer(p) then
            local d = (p.Character.HumanoidRootPart.Position - lr.Position).Magnitude
            if d < nd then n, nd = p, d end
        end
    end
    return n
end

function getTargetDistance(player)
    local localRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local targetRoot = player and player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not localRoot or not targetRoot then return math.huge end
    return (localRoot.Position - targetRoot.Position).Magnitude
end

CarFlingRunning = false

function getCarFlingVehicle()
    local character = LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then return nil, nil end

    local nearestCar, nearestSeat, nearestDistance = nil, nil, math.huge
    for _, folderName in ipairs({"CivCars", "PoliceCars", "NPCCars", "Cars", "Vehicles"}) do
        local folder = workspace:FindFirstChild(folderName)
        if folder then
            for _, car in ipairs(folder:GetChildren()) do
                if car:IsA("Model") then
                    local seat = car:FindFirstChild("DriveSeat", true)
                        or car:FindFirstChildWhichIsA("VehicleSeat", true)
                    if seat and not seat.Occupant then
                        local mainPart = car.PrimaryPart
                            or (car:FindFirstChild("Body") and car.Body:FindFirstChild("#Weight", true))
                            or car:FindFirstChildWhichIsA("BasePart", true)
                        if mainPart then
                            local distance = (mainPart.Position - root.Position).Magnitude
                            if distance < nearestDistance then
                                nearestDistance = distance
                                nearestCar = car
                                nearestSeat = seat
                            end
                        end
                    end
                end
            end
        end
    end
    return nearestCar, nearestSeat
end

function setCarFlingVelocity(car, velocity)
    if not car then return end
    for _, part in ipairs(car:GetDescendants()) do
        if part:IsA("BasePart") then
            pcall(function()
                part.AssemblyLinearVelocity = velocity
                part.AssemblyAngularVelocity = Vector3.zero
            end)
        end
    end
end

function stopCarFlingMotion(car)
    setCarFlingVelocity(car, Vector3.zero)
end

function CarFlingSelectedPlayer()
    if CarFlingRunning then
        sendNotification("Car Fling", "A car fling is already running.")
        return
    end

    local target = getSelectedTargetPlayer()
    if not target or not isValidTargetPlayer(target) then
        sendNotification("Car Fling", "Select a valid player first.")
        return
    end

    CarFlingRunning = true
    task.spawn(function()
        local character = LocalPlayer.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local targetRoot = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
        local returnCF = root and root.CFrame
        local car, seat
        local oldSize, oldTransparency, oldCollide

        local function finish(message)
            if car then pcall(stopCarFlingMotion, car) end
            if targetRoot and targetRoot.Parent and oldSize then
                pcall(function()
                    targetRoot.Size = oldSize
                    targetRoot.Transparency = oldTransparency
                    targetRoot.CanCollide = oldCollide
                end)
            end
            if humanoid and humanoid.Parent then
                pcall(function()
                    humanoid.Sit = false
                    humanoid.Jump = true
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                end)
            end
            if root and root.Parent and returnCF then
                pcall(function()
                    root.AssemblyLinearVelocity = Vector3.zero
                    root.AssemblyAngularVelocity = Vector3.zero
                    Config:Teleport(returnCF)
                end)
            end
            getgenv().SwimMethod = false
            CarFlingRunning = false
            if message then sendNotification("Car Fling", message) end
        end

        local ok, err = pcall(function()
            if not root or not humanoid or not targetRoot then
                finish("Character or target is not ready.")
                return
            end

            oldSize = targetRoot.Size
            oldTransparency = targetRoot.Transparency
            oldCollide = targetRoot.CanCollide
            pcall(function()
                targetRoot.Size = Vector3.new(25, 25, 25)
                targetRoot.Transparency = 1
                targetRoot.CanCollide = false
            end)

            car, seat = getCarFlingVehicle()
            if not car or not seat then
                finish("No empty car was found.")
                return
            end

            if not car.PrimaryPart then
                car.PrimaryPart = (car:FindFirstChild("Body") and car.Body:FindFirstChild("#Weight", true))
                    or car:FindFirstChildWhichIsA("BasePart", true)
                    or seat
            end
            if not car.PrimaryPart then
                finish("The selected car has no usable main part.")
                return
            end

            sendNotification("Car Fling", "Claiming an empty car...")
            Config:Teleport(seat.CFrame * CFrame.new(0, 2, 0))
            task.wait(0.2)
            seat:Sit(humanoid)
            car:SetAttribute("Usable", true)
            task.wait(1)

            if humanoid.SeatPart ~= seat then
                finish("Failed to sit in the car. Try again.")
                return
            end

            sendNotification("Car Fling", "Flinging " .. target.Name .. "...")

            local seatPart = humanoid.SeatPart
            local unseatStart = os.clock()
            while os.clock() - unseatStart < 1.5 do
                pcall(function()
                    humanoid.Sit = false
                    humanoid.Jump = true
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                    if seatPart then
                        for _, weld in ipairs(seatPart:GetDescendants()) do
                            if weld:IsA("Weld") or weld:IsA("Motor6D") or weld.Name == "SeatWeld" then
                                weld:Destroy()
                            end
                        end
                    end
                end)
                if not humanoid.Sit and not humanoid.SeatPart then break end
                task.wait(0.02)
            end

            
            getgenv().SwimMethod = true
            task.wait(0.5)
            if root and root.Parent and returnCF then
                root.AssemblyLinearVelocity = Vector3.zero
                root.AssemblyAngularVelocity = Vector3.zero
                root.CFrame = returnCF
            end
            getgenv().SwimMethod = false

            local flingStart = os.clock()
            while os.clock() - flingStart < 4 do
                if not car.Parent or not targetRoot.Parent then break end
                pcall(function()
                    if car.PrimaryPart then
                        car:SetPrimaryPartCFrame(targetRoot.CFrame)
                    else
                        car:PivotTo(targetRoot.CFrame)
                    end
                end)
                setCarFlingVelocity(car, Vector3.new(0, 20000, 0))
                task.wait(0.01)
            end

            finish(target.Name .. " was car-flung.")
        end)

        if not ok then
            warn("[Car Fling] " .. tostring(err))
            finish("Error: " .. tostring(err))
        end
    end)
end

function targetGunRemote(targetName, hitPart, damage)
    hitPart = hitPart or "Head"; damage = damage or math.huge
    local target = Players:FindFirstChild(tostring(targetName))
    if not target or not target.Character or not target.Character:FindFirstChild(hitPart) then return end
    if not target.Character:FindFirstChildOfClass("Humanoid") then return end
    local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
    if not tool then sendNotification("Target","Hold a gun/tool first."); return end
    pcall(function() if tool:FindFirstChild("Setting") then require(tool.Setting).Range = 10000 end end)
    pcall(function()
        if ReplicatedStorage:FindFirstChild("InflictTarget") then
            ReplicatedStorage.InflictTarget:FireServer(
                tool, LocalPlayer, target.Character.Humanoid,
                target.Character[hitPart], damage,
                {0,0,false,false}, {false,5,3}, target.Character[hitPart],
                {false,{1930359546},1,1.5,1}, target.Character[hitPart].Position,
                Vector3.new(0,0,-1), true
            )
        end
    end)
end


targetSpectateReset = true
RunService:BindToRenderStep("MiamiTargetSpectate", Enum.RenderPriority.Camera.Value, function()
    local cam = workspace.CurrentCamera; if not cam then return end
    if TargetUtilities.SpectatePlayer then
        targetSpectateReset = false
        local t = getSelectedTargetPlayer()
        local s = t and t.Character and t.Character:FindFirstChildOfClass("Humanoid")
        if not s and LocalPlayer.Character then s = LocalPlayer.Character:FindFirstChildOfClass("Humanoid") end
        if s then cam.CameraSubject = s end
    elseif not targetSpectateReset and LocalPlayer.Character then
        targetSpectateReset = true
        local h = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if h then cam.CameraSubject = h end
    end
end)


task.spawn(function()
    while task.wait() do
        if TargetUtilities.BringingPlayer then
            local t = getSelectedTargetPlayer()
            if t and t.Character and t.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                t.Character.HumanoidRootPart.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame + Vector3.new(2,0,0)
            end
        end
        if TargetUtilities.BringingNearestPlayer then
            local t = getNearestTargetPlayer()
            if t and t.Character and t.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                t.Character.HumanoidRootPart.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame + Vector3.new(2,0,0)
            end
        end
    end
end)


task.spawn(function()
    while task.wait(2) do
        if TargetUtilities.AutoRagdoll then
            local t = getSelectedTargetPlayer()
            if t and isValidTargetPlayer(t) and t.Character.Humanoid:GetState() ~= Enum.HumanoidStateType.Physics then
                targetGunRemote(t.Name, "RightUpperLeg", 0.01)
            end
        end
    end
end)

task.spawn(function()
    while task.wait(1) do
        if TargetUtilities.AutoKill then
            local t = getSelectedTargetPlayer()
            if t and isValidTargetPlayer(t) and getTargetDistance(t) <= (TargetUtilities.AutoKillMaxDistance or 350) then
                local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
                if tool and tool:FindFirstChild("GunScript_Local") then
                    targetGunRemote(t.Name, "Head", math.huge)
                end
            end
        end
    end
end)


function applyOutfit(name, instructions)
    pcall(function() ReplicatedStorage.ClothShopRemote:FireServer("Reset Data") end)
    task.wait(0.2)
    for _, inst in ipairs(instructions) do
        local action, cat, item = inst[1], inst[2], inst[3]
        pcall(function() ReplicatedStorage.ClothShopRemote:FireServer(action, cat, item) end)
        task.wait(0.1)
    end
    sendNotification("Outfit", "Applied " .. name)
end




function StartTacoBasketballGameOverlay(opponentOverride)
    
    
    local TweenService = game:GetService("TweenService")
    local playerGui = LocalPlayer and LocalPlayer:FindFirstChildOfClass("PlayerGui")
    local parent = (gethui and gethui()) or CoreGui or playerGui

    local old = parent and parent:FindFirstChild("TacoBasketballMoneyGame")
    if old then old:Destroy() end

    local teams = {
        ["Random"] = {Short = "RIV", Color = Color3.fromRGB(83, 151, 255)},
        ["RIVALS"] = {Short = "RIV", Color = Color3.fromRGB(83, 151, 255)},
        ["KINGS"] = {Short = "KNG", Color = Color3.fromRGB(138, 79, 255)},
        ["FALCONS"] = {Short = "FAL", Color = Color3.fromRGB(235, 78, 78)},
        ["TITANS"] = {Short = "TTN", Color = Color3.fromRGB(38, 186, 133)},
        ["BLAZERS"] = {Short = "BLZ", Color = Color3.fromRGB(255, 135, 50)},
    }
    local chosen = tostring(opponentOverride or getgenv().TacoBasketballOpponent or "Random")
    local opponent = teams[chosen] or teams.Random

    local gui = Instance.new("ScreenGui")
    gui.Name = "TacoBasketballMoneyGame"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 99998
    gui.Parent = parent or playerGui
    if not gui.Parent then return function() end end

    local frame = Instance.new("Frame")
    frame.Name = "TacoBasketballScoreboard"
    frame.AnchorPoint = Vector2.new(0.5, 0)
    frame.Position = UDim2.new(0.5, 0, 0, -440)
    frame.Size = UDim2.fromOffset(560, 420)
    frame.BackgroundColor3 = Color3.fromRGB(12, 10, 5)
    frame.BackgroundTransparency = 0.04
    frame.BorderSizePixel = 0
    frame.ClipsDescendants = true
    frame.Parent = gui
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 14)

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 198, 48)
    stroke.Thickness = 2
    stroke.Transparency = 0.05
    stroke.Parent = frame

    local header = Instance.new("TextLabel")
    header.BackgroundTransparency = 1
    header.Size = UDim2.new(1, -28, 0, 30)
    header.Position = UDim2.fromOffset(14, 8)
    header.Font = Enum.Font.GothamBlack
    header.TextSize = 12
    header.TextColor3 = Color3.fromRGB(255, 222, 104)
    header.Text = "HITBOXERS.GG  •  LIVE BASKETBALL"
    header.Parent = frame

    local period = Instance.new("TextLabel")
    period.BackgroundTransparency = 1
    period.Size = UDim2.new(1, -28, 0, 22)
    period.Position = UDim2.fromOffset(14, 36)
    period.Font = Enum.Font.GothamBold
    period.TextSize = 10
    period.TextColor3 = Color3.fromRGB(235, 235, 235)
    period.Text = "Q1  12:00"
    period.Parent = frame

    local left = Instance.new("TextLabel")
    left.BackgroundTransparency = 1
    left.Size = UDim2.fromOffset(170, 58)
    left.Position = UDim2.fromOffset(22, 62)
    left.Font = Enum.Font.GothamBlack
    left.TextSize = 28
    left.TextXAlignment = Enum.TextXAlignment.Left
    left.TextColor3 = Color3.fromRGB(255, 207, 60)
    left.Text = "TRP  0"
    left.Parent = frame

    local right = Instance.new("TextLabel")
    right.BackgroundTransparency = 1
    right.Size = UDim2.fromOffset(170, 58)
    right.Position = UDim2.new(1, -192, 0, 62)
    right.Font = Enum.Font.GothamBlack
    right.TextSize = 28
    right.TextXAlignment = Enum.TextXAlignment.Right
    right.TextColor3 = opponent.Color
    right.Text = opponent.Short .. "  0"
    right.Parent = frame

    local versus = Instance.new("TextLabel")
    versus.BackgroundTransparency = 1
    versus.AnchorPoint = Vector2.new(0.5, 0)
    versus.Position = UDim2.new(0.5, 0, 0, 78)
    versus.Size = UDim2.fromOffset(60, 34)
    versus.Font = Enum.Font.GothamBold
    versus.TextSize = 11
    versus.TextColor3 = Color3.fromRGB(210, 210, 210)
    versus.Text = "VS"
    versus.Parent = frame

    local play = Instance.new("TextLabel")
    play.BackgroundTransparency = 1
    play.Position = UDim2.fromOffset(18, 125)
    play.Size = UDim2.new(1, -36, 0, 28)
    play.Font = Enum.Font.GothamSemibold
    play.TextSize = 10
    play.TextWrapped = true
    play.TextColor3 = Color3.fromRGB(240, 240, 240)
    play.Text = "Tip-off complete — generating maximum money."
    play.Parent = frame

    local progressBack = Instance.new("Frame")
    progressBack.BackgroundColor3 = Color3.fromRGB(56, 47, 22)
    progressBack.BorderSizePixel = 0
    progressBack.Position = UDim2.fromOffset(18, 394)
    progressBack.Size = UDim2.new(1, -36, 0, 7)
    progressBack.Parent = frame
    Instance.new("UICorner", progressBack).CornerRadius = UDim.new(1, 0)

    local progress = Instance.new("Frame")
    progress.BackgroundColor3 = Color3.fromRGB(255, 198, 48)
    progress.BorderSizePixel = 0
    progress.Size = UDim2.new(0.04, 0, 1, 0)
    progress.Parent = progressBack
    Instance.new("UICorner", progress).CornerRadius = UDim.new(1, 0)

    
    
    local court = Instance.new("Frame")
    court.Name = "AnimatedCourt"
    court.Position = UDim2.fromOffset(18, 182)
    court.Size = UDim2.fromOffset(524, 200)
    court.BackgroundColor3 = Color3.fromRGB(183, 126, 70)
    court.BorderSizePixel = 0
    court.ClipsDescendants = true
    court.Parent = frame
    local courtCorner = Instance.new("UICorner")
    courtCorner.CornerRadius = UDim.new(0, 10)
    courtCorner.Parent = court

    local grain = Instance.new("UIGradient")
    grain.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(210, 154, 89)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(160, 104, 57)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(210, 154, 89)),
    }
    grain.Rotation = 90
    grain.Parent = court

    local courtStroke = Instance.new("UIStroke")
    courtStroke.Color = Color3.fromRGB(255, 230, 180)
    courtStroke.Thickness = 1.3
    courtStroke.Transparency = 0.25
    courtStroke.Parent = court

    local function courtLine(size, position, anchorPoint)
        local line = Instance.new("Frame")
        line.BackgroundColor3 = Color3.fromRGB(255, 242, 214)
        line.BackgroundTransparency = 0.12
        line.BorderSizePixel = 0
        line.Size = size
        line.Position = position
        line.AnchorPoint = anchorPoint or Vector2.new(0, 0)
        line.ZIndex = 2
        line.Parent = court
        return line
    end

    
    courtLine(UDim2.new(0, 2, 1, -10), UDim2.new(0.5, 0, 0, 5), Vector2.new(0.5, 0))
    local centreCircle = Instance.new("Frame")
    centreCircle.Size = UDim2.fromOffset(72, 72)
    centreCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
    centreCircle.AnchorPoint = Vector2.new(0.5, 0.5)
    centreCircle.BackgroundTransparency = 1
    centreCircle.ZIndex = 2
    centreCircle.Parent = court
    local circleCorner = Instance.new("UICorner")
    circleCorner.CornerRadius = UDim.new(1, 0)
    circleCorner.Parent = centreCircle
    local circleStroke = Instance.new("UIStroke")
    circleStroke.Color = Color3.fromRGB(255, 242, 214)
    circleStroke.Thickness = 1.3
    circleStroke.Transparency = 0.12
    circleStroke.Parent = centreCircle

    local function makeKey(side)
        local key = Instance.new("Frame")
        key.Size = UDim2.fromOffset(62, 102)
        key.Position = UDim2.new(side == "Left" and 0 or 1, side == "Left" and 4 or -4, 0.5, 0)
        key.AnchorPoint = Vector2.new(side == "Left" and 0 or 1, 0.5)
        key.BackgroundTransparency = 1
        key.ZIndex = 2
        key.Parent = court
        local keyStroke = Instance.new("UIStroke")
        keyStroke.Color = Color3.fromRGB(255, 242, 214)
        keyStroke.Thickness = 1.2
        keyStroke.Transparency = 0.14
        keyStroke.Parent = key

        local rim = Instance.new("Frame")
        rim.Size = UDim2.fromOffset(10, 36)
        rim.Position = UDim2.new(side == "Left" and 0 or 1, side == "Left" and 11 or -11, 0.5, 0)
        rim.AnchorPoint = Vector2.new(0.5, 0.5)
        rim.BackgroundColor3 = Color3.fromRGB(239, 68, 55)
        rim.BorderSizePixel = 0
        rim.ZIndex = 4
        rim.Parent = court
        local rimCorner = Instance.new("UICorner")
        rimCorner.CornerRadius = UDim.new(1, 0)
        rimCorner.Parent = rim
    end
    makeKey("Left")
    makeKey("Right")

    local courtCaption = Instance.new("TextLabel")
    courtCaption.BackgroundTransparency = 1
    courtCaption.Size = UDim2.new(1, -20, 0, 18)
    courtCaption.Position = UDim2.new(0, 10, 1, -23)
    courtCaption.Font = Enum.Font.GothamBold
    courtCaption.TextSize = 9
    courtCaption.TextColor3 = Color3.fromRGB(255, 246, 224)
    courtCaption.TextTransparency = 0.18
    courtCaption.Text = "LIVE POSSESSION  •  PASSING  •  SHOT CLOCK 24"
    courtCaption.ZIndex = 5
    courtCaption.Parent = court

    local tacoColor = Color3.fromRGB(255, 207, 60)
    local function makeCourtPlayer(teamColor, number, point)
        local player = Instance.new("Frame")
        player.Name = "CourtPlayer_" .. tostring(number)
        player.AnchorPoint = Vector2.new(0.5, 0.5)
        player.Size = UDim2.fromOffset(28, 28)
        player.Position = UDim2.fromScale(point.X, point.Y)
        player.BackgroundColor3 = teamColor
        player.BorderSizePixel = 0
        player.ZIndex = 7
        player.Parent = court
        local playerCorner = Instance.new("UICorner")
        playerCorner.CornerRadius = UDim.new(1, 0)
        playerCorner.Parent = player
        local playerStroke = Instance.new("UIStroke")
        playerStroke.Color = Color3.fromRGB(255, 255, 255)
        playerStroke.Thickness = 1.3
        playerStroke.Transparency = 0.22
        playerStroke.Parent = player

        local jersey = Instance.new("TextLabel")
        jersey.BackgroundTransparency = 1
        jersey.Size = UDim2.fromScale(1, 1)
        jersey.Font = Enum.Font.GothamBlack
        jersey.TextSize = 9
        jersey.TextColor3 = Color3.fromRGB(18, 18, 18)
        jersey.Text = tostring(number)
        jersey.ZIndex = 8
        jersey.Parent = player
        return player
    end

    local tacoSpots = {
        Vector2.new(0.16, 0.26), Vector2.new(0.28, 0.70), Vector2.new(0.40, 0.42),
        Vector2.new(0.33, 0.18), Vector2.new(0.22, 0.52),
    }
    local opponentSpots = {
        Vector2.new(0.84, 0.74), Vector2.new(0.72, 0.30), Vector2.new(0.60, 0.58),
        Vector2.new(0.67, 0.82), Vector2.new(0.78, 0.47),
    }
    local tacoPlayers, opponentPlayers = {}, {}
    for i, point in ipairs(tacoSpots) do
        tacoPlayers[i] = makeCourtPlayer(tacoColor, i + 1, point)
    end
    for i, point in ipairs(opponentSpots) do
        opponentPlayers[i] = makeCourtPlayer(opponent.Color, i + 10, point)
    end

    local ball = Instance.new("Frame")
    ball.Name = "Basketball"
    ball.AnchorPoint = Vector2.new(0.5, 0.5)
    ball.Size = UDim2.fromOffset(14, 14)
    ball.Position = tacoPlayers[1].Position
    ball.BackgroundColor3 = Color3.fromRGB(235, 112, 38)
    ball.BorderSizePixel = 0
    ball.ZIndex = 12
    ball.Parent = court
    local ballCorner = Instance.new("UICorner")
    ballCorner.CornerRadius = UDim.new(1, 0)
    ballCorner.Parent = ball
    local ballStroke = Instance.new("UIStroke")
    ballStroke.Color = Color3.fromRGB(82, 42, 20)
    ballStroke.Thickness = 1.2
    ballStroke.Parent = ball
    local seamA = courtLine(UDim2.fromOffset(2, 14), UDim2.new(0, 0, 0, 0))
    seamA.AnchorPoint = Vector2.new(0.5, 0.5)
    seamA.BackgroundColor3 = Color3.fromRGB(82, 42, 20)
    seamA.BackgroundTransparency = 0.1
    seamA.ZIndex = 13
    seamA.Parent = ball
    seamA.Position = UDim2.new(0.5, 0, 0.5, 0)

    local function tweenPlayer(player, point, duration)
        if not player or not player.Parent then return end
        TweenService:Create(player, TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            Position = UDim2.fromScale(point.X, point.Y)
        }):Play()
    end

    local function passBall(fromPlayer, toPlayer, duration)
        if not (fromPlayer and toPlayer and ball.Parent) then return end
        ball.Position = fromPlayer.Position
        local apex = UDim2.new(
            (fromPlayer.Position.X.Scale + toPlayer.Position.X.Scale) / 2,
            (fromPlayer.Position.X.Offset + toPlayer.Position.X.Offset) / 2,
            math.clamp((fromPlayer.Position.Y.Scale + toPlayer.Position.Y.Scale) / 2 - 0.18, 0.08, 0.85),
            0
        )
        local first = TweenService:Create(ball, TweenInfo.new(duration * 0.48, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = apex})
        first:Play()
        first.Completed:Wait()
        if ball.Parent and toPlayer.Parent then
            local second = TweenService:Create(ball, TweenInfo.new(duration * 0.52, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Position = toPlayer.Position
            })
            second:Play()
            second.Completed:Wait()
        end
    end

    local function animatePossession(tacoHasBall, scored)
        local offense = tacoHasBall and tacoPlayers or opponentPlayers
        local defense = tacoHasBall and opponentPlayers or tacoPlayers
        local shootingSide = tacoHasBall and 0.965 or 0.035

        
        for i, player in ipairs(offense) do
            tweenPlayer(player, Vector2.new(
                math.clamp((tacoHasBall and 0.16 or 0.84) + (math.random(-12, 12) / 100), 0.09, 0.91),
                math.clamp(0.18 + ((i - 1) * 0.15) + (math.random(-7, 7) / 100), 0.12, 0.86)
            ), 0.45)
        end
        for i, player in ipairs(defense) do
            tweenPlayer(player, Vector2.new(
                math.clamp((tacoHasBall and 0.62 or 0.38) + (math.random(-14, 14) / 100), 0.10, 0.90),
                math.clamp(0.18 + ((i - 1) * 0.15) + (math.random(-8, 8) / 100), 0.12, 0.86)
            ), 0.45)
        end

        local passer = offense[math.random(1, #offense)]
        local receiver = offense[math.random(1, #offense)]
        while receiver == passer do receiver = offense[math.random(1, #offense)] end
        passBall(passer, receiver, 0.34)
        task.wait(0.08)
        local finalReceiver = offense[math.random(1, #offense)]
        while finalReceiver == receiver do finalReceiver = offense[math.random(1, #offense)] end
        passBall(receiver, finalReceiver, 0.32)

        if scored and ball.Parent then
            local shotApex = UDim2.new((finalReceiver.Position.X.Scale + shootingSide) / 2, 0, 0.18, 0)
            local shotRim = UDim2.new(shootingSide, 0, 0.5, 0)
            local first = TweenService:Create(ball, TweenInfo.new(0.30, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = shotApex})
            first:Play()
            first.Completed:Wait()
            if ball.Parent then
                local finish = TweenService:Create(ball, TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = shotRim})
                finish:Play()
                finish.Completed:Wait()
            end
        end
    end

    local tacoScore, opponentScore = 0, 0
    local quarter, seconds, running, finished = 1, 12 * 60, true, false

    
    task.spawn(function()
        while running and court.Parent do
            task.wait(1.15)
            for _, player in ipairs(tacoPlayers) do
                tweenPlayer(player, Vector2.new(
                    math.clamp(player.Position.X.Scale + math.random(-4, 4) / 100, 0.10, 0.48),
                    math.clamp(player.Position.Y.Scale + math.random(-5, 5) / 100, 0.13, 0.87)
                ), 0.55)
            end
            for _, player in ipairs(opponentPlayers) do
                tweenPlayer(player, Vector2.new(
                    math.clamp(player.Position.X.Scale + math.random(-4, 4) / 100, 0.52, 0.90),
                    math.clamp(player.Position.Y.Scale + math.random(-5, 5) / 100, 0.13, 0.87)
                ), 0.55)
            end
        end
    end)

    local plays = {
        "drains a three from the wing.",
        "finishes a fast-break layup.",
        "hits a clean mid-range jumper.",
        "throws down a highlight dunk.",
        "scores after a quick steal.",
    }

    local function refresh(lastPlay)
        local mins = math.max(0, math.floor(seconds / 60))
        local secs = math.max(0, seconds % 60)
        period.Text = string.format("Q%d  %02d:%02d", quarter, mins, secs)
        left.Text = "TRP  " .. tacoScore
        right.Text = opponent.Short .. "  " .. opponentScore
        if lastPlay then play.Text = lastPlay end
        local pct = math.clamp(((quarter - 1) + (1 - seconds / 720)) / 4, 0.04, 0.96)
        progress.Size = UDim2.new(pct, 0, 1, 0)
    end

    TweenService:Create(frame, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, 0, 0, 28)
    }):Play()

    task.spawn(function()
        while running and gui.Parent do
            task.wait(math.random(9, 15) / 10)
            if not running then break end
            seconds = seconds - math.random(18, 42)
            if seconds <= 0 then
                quarter = quarter < 4 and quarter + 1 or 4
                seconds = quarter < 4 and 12 * 60 or 0
            end
            local tacoScored = math.random(1, 100) <= 56
            local points = math.random(1, 100) <= 28 and 3 or 2
            animatePossession(tacoScored, true)
            if tacoScored then
                tacoScore = tacoScore + points
                refresh("TACO " .. tostring(points) .. " POINTS — " .. plays[math.random(1, #plays)])
            else
                opponentScore = opponentScore + points
                refresh(opponent.Short .. " " .. tostring(points) .. " POINTS — answers on the next possession.")
            end
        end
    end)

    return function(success)
        if finished then return end
        finished, running = true, false
        if success ~= false then
            tacoScore = math.max(tacoScore, opponentScore + math.random(2, 9))
            progress.Size = UDim2.new(1, 0, 1, 0)
            refresh("FINAL — TACO wins " .. tacoScore .. "–" .. opponentScore .. ". Maximum money generated.")
        else
            refresh("GAME PAUSED — money generation stopped before the final buzzer.")
        end
        task.wait(3.5)
        if gui.Parent then
            TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Position = UDim2.new(0.5, 0, 0, -440)
            }):Play()
            task.wait(0.35)
            gui:Destroy()
        end
    end
end

function GetGoodCleaner()
    if not workspace:FindFirstChild("1# Map") then return nil end
    local CounterInstance
    for _, V in pairs(workspace["1# Map"]:GetChildren()) do
        if V:FindFirstChild("CounterM") then CounterInstance = V; break end
    end
    if not CounterInstance then return nil end
    for _, v in pairs(CounterInstance:GetChildren()) do
        local cp = v:FindFirstChild("CashPrompt", true)
        local gp = v:FindFirstChild("GrabPrompt", true)
        if cp and cp.Enabled and cp.ObjectText == "Count Bread" and gp and not gp.Enabled then
            return v
        end
    end
end

function CleanAllFilthyMoney()
    local player = LocalPlayer
    local character = player.Character
    local humanoid = character and character:FindFirstChild("Humanoid")

    local stored = player:FindFirstChild("stored")
    local filthy = stored and stored:FindFirstChild("FilthyStack")
    if not filthy or filthy.Value == 0 then
        sendNotification("Money", "You Have No Filthy Money!", 3)
        return
    end

    if not character or not character:FindFirstChild("HumanoidRootPart") or not humanoid or humanoid.Health == 0 then
        return
    end

    local cleaner = GetGoodCleaner()
    if not cleaner then
        sendNotification("Money", "All Cleaners Have Been Used!", 3)
        return
    end

    local returnCFrame = character.HumanoidRootPart.CFrame
    Config:Teleport(cleaner.WorldPivot)
    task.wait(0.4)
    fireproximityprompt(cleaner:FindFirstChild("CashPrompt", true))

    repeat
        task.wait()
    until cleaner:FindFirstChild("On", true).Color == Color3.fromRGB(74, 156, 69)

    task.wait(0.5)
    fireproximityprompt(cleaner:FindFirstChild("CashPrompt", true))
    task.wait(0.25)
    Config:Teleport(cleaner.WorldPivot)
    task.wait(0.4)

    repeat
        task.wait()
    until player.Backpack:FindFirstChild("MoneyReady")

    humanoid:EquipTool(player.Backpack.MoneyReady)

    repeat
        fireproximityprompt(cleaner:FindFirstChild("GrabPrompt", true))
        task.wait(3)
    until not character:FindFirstChild("MoneyReady")

    repeat
        task.wait()
    until player.Backpack:FindFirstChild("BagOfMoney")

    Config:Teleport(CFrame.new(-1216.7276611328, 253.8797454834, -3636.1530761719))
    humanoid:EquipTool(player.Backpack.BagOfMoney)
    task.wait(1)
    fireproximityprompt(workspace.ATMMoney.Prompt)
    Config:Teleport(returnCFrame)
    sendNotification("Money", "Filthy Money Cleaned!", 3)
end

function InfMoneyHoldCupz()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")
    local origin = hrp.CFrame
    local sell = workspace:FindFirstChild("IceFruit Sell")
    if not sell then sendNotification("Inf Money","IceFruit Sell not found."); return end
    local prompt = sell:FindFirstChild("ProximityPrompt"); if not prompt then return end
    prompt.HoldDuration = 0
    prompt.MaxActivationDistance = math.huge
    Config:Teleport(sell.CFrame); task.wait(1)
    for _ = 1, 250 do task.spawn(function() pcall(function() fireproximityprompt(prompt, 1) end) end) end
    task.wait(5)
    Config:Teleport(origin); task.wait(0.25)
    getgenv().SwimMethod = false
end

function SetupInfiniteMoney()
    for _, item in ipairs({"Ice-Fruit Bag","Ice-Fruit Cupz","FijiWater","FreshWater"}) do
        task.spawn(function() pcall(function() ReplicatedStorage:WaitForChild("ExoticShopRemote"):InvokeServer(item) end) end)
    end
end

function GenerateMaxIllegalMoney()
    local Player = LocalPlayer
    local function GetFruitCup()
        for _, container in ipairs({Player.Backpack, Player.Character}) do
            if container then
                for _, tool in pairs(container:GetChildren()) do
                    if tool:IsA("Tool") and tool.Name == "Ice-Fruit Cupz" then
                        local cupPart = tool:FindFirstChild("IceFruit Cup")
                        if cupPart and cupPart:FindFirstChild("IceFruit PunchMedium")
                           and cupPart["IceFruit PunchMedium"].Transparency ~= 1 then
                            return true, tool
                        end
                    end
                end
            end
        end
        return false, nil
    end

    local Found, Cup = GetFruitCup()
    local oldCFrame = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") and Player.Character.HumanoidRootPart.CFrame
    if Cup and Found and oldCFrame and workspace:FindFirstChild("IceFruit Sell") then
        if Cup.Parent == Player.Backpack then Player.Character.Humanoid:EquipTool(Cup); task.wait(1) end
        Config:Teleport(workspace["IceFruit Sell"].CFrame); task.wait(0.5)
        for _ = 1, 4000 do task.spawn(function() pcall(function() fireproximityprompt(workspace["IceFruit Sell"].ProximityPrompt) end) end) end
        Config:Teleport(oldCFrame); task.wait(8)
        return
    end

    local items = {"FijiWater","FreshWater","Ice-Fruit Bag","Ice-Fruit Cupz"}
    local stove
    if workspace:FindFirstChild("CookingPots") then
        for _, value in pairs(workspace.CookingPots:GetChildren()) do
            if value:IsA("Model") then
                local prompt = value:FindFirstChildWhichIsA("ProximityPrompt", true)
                if prompt and prompt.ActionText == "Turn On" and prompt.Enabled then stove = value; break end
            end
        end
    end

    for _, item in ipairs(items) do
        if not Player.Backpack:FindFirstChild(item) then
            pcall(function() ReplicatedStorage:WaitForChild("ExoticShopRemote"):InvokeServer(item) end)
            task.wait(1)
        end
    end
    for _, item in ipairs(items) do
        if not Player.Backpack:FindFirstChild(item) then
            sendNotification("Money", "Need more cash / missing items."); return
        end
    end
    if not stove then sendNotification("Money", "Could not find a cooking stove."); return end

    Config:Teleport(stove.CookPart.CFrame); task.wait(1)
    pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false) end)
    Player.Character.HumanoidRootPart.Anchored = true; task.wait(1.5)
    pcall(function() fireproximityprompt(stove:FindFirstChildWhichIsA("ProximityPrompt", true)) end)
    task.wait(2)
    for _, item in ipairs({"FijiWater","FreshWater","Ice-Fruit Bag"}) do
        if Player.Backpack:FindFirstChild(item) then
            Player.Character.Humanoid:EquipTool(Player.Backpack[item]); task.wait(1)
            pcall(function() fireproximityprompt(stove:FindFirstChildWhichIsA("ProximityPrompt", true)) end)
            task.wait(3)
        end
    end
    pcall(function() repeat task.wait() until stove.CookPart.Steam.LoadUI.Enabled == false end)
    if not Player.Character:FindFirstChild("Ice-Fruit Cupz") and Player.Backpack:FindFirstChild("Ice-Fruit Cupz") then
        Player.Character.Humanoid:EquipTool(Player.Backpack["Ice-Fruit Cupz"]); task.wait(1)
    end
    task.wait(1)
    pcall(function() fireproximityprompt(stove:FindFirstChildWhichIsA("ProximityPrompt", true)) end)
    task.wait(3)
    Player.Character.HumanoidRootPart.Anchored = false
    if workspace:FindFirstChild("IceFruit Sell") then
        Config:Teleport(workspace["IceFruit Sell"].CFrame); task.wait(1)
        Player.Character.HumanoidRootPart.Anchored = true; task.wait(1.5)
        if not Player.Character:FindFirstChild("Ice-Fruit Cupz") and Player.Backpack:FindFirstChild("Ice-Fruit Cupz") then
            Player.Character.Humanoid:EquipTool(Player.Backpack["Ice-Fruit Cupz"]); task.wait(1)
        end
        workspace["IceFruit Sell"].ProximityPrompt.HoldDuration = 0
        for _ = 1, 4000 do task.spawn(function() pcall(function() fireproximityprompt(workspace["IceFruit Sell"].ProximityPrompt) end) end) end
    end
    Player.Character.HumanoidRootPart.Anchored = false
    pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true) end)
end


getgenv().MoneyDropEnabled = getgenv().MoneyDropEnabled or false
function DropMoneyAmount(amount)
    local BankRemote = ReplicatedStorage:FindFirstChild('BankProcessRemote', true)
    if not BankRemote then return false end
    local function send(...) if BankRemote.InvokeServer then return BankRemote:InvokeServer(...) elseif BankRemote.FireServer then return BankRemote:FireServer(...) end end
    for _, args in ipairs({{"Drop",tostring(amount)},{"Drop",tonumber(amount) or amount}}) do
        local ok, r = pcall(send, table.unpack(args))
        if ok and r ~= false then return true end
    end
end
task.spawn(function()
    while task.wait(0.3) do
        if getgenv().MoneyDropEnabled then pcall(function() DropMoneyAmount(10000) end) end
    end
end)










Config.TheBronx = Config.TheBronx or {}
Config.TheBronx.carfly = false
Config.TheBronx.carflyspeed = 120

CarFly = {Enabled = false, Speed = 120}
local LuhjayyCarHum, LuhjayyCarSeat, LuhjayyCar, LuhjayyCarRoot
local LuhjayyCarBV, LuhjayyCarBG
local LuhjayyLastCar

local function LuhjayyCarFlyCleanup()
    if LuhjayyCarBV then LuhjayyCarBV:Destroy() LuhjayyCarBV = nil end
    if LuhjayyCarBG then LuhjayyCarBG:Destroy() LuhjayyCarBG = nil end
end

local function LuhjayyCarFlySetup()
    LuhjayyCarFlyCleanup()
    if not Config.TheBronx.carfly then return end
    local char = LocalPlayer.Character
    if not char then return end
    LuhjayyCarHum = char:FindFirstChildWhichIsA("Humanoid")
    if not LuhjayyCarHum then return end
    LuhjayyCarSeat = LuhjayyCarHum.SeatPart
    if not LuhjayyCarSeat or not LuhjayyCarSeat:IsA("VehicleSeat") then return end
    LuhjayyCar = LuhjayyCarSeat.Parent
    if not LuhjayyCar then return end
    LuhjayyCarRoot = LuhjayyCar.PrimaryPart
    if not LuhjayyCarRoot then return end
    LuhjayyLastCar = LuhjayyCar
    for _, v in ipairs(LuhjayyCar:GetChildren()) do
        if v:IsA("BasePart") and not v.Name:lower():find("wheel") then
            v.CanCollide = false
        end
    end
    LuhjayyCarBV = Instance.new("BodyVelocity")
    LuhjayyCarBV.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    LuhjayyCarBV.Velocity = Vector3.zero
    LuhjayyCarBV.Parent = LuhjayyCarRoot
    LuhjayyCarBG = Instance.new("BodyGyro")
    LuhjayyCarBG.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
    LuhjayyCarBG.P = 25000
    LuhjayyCarBG.D = 1500
    LuhjayyCarBG.CFrame = LuhjayyCarRoot.CFrame
    LuhjayyCarBG.Parent = LuhjayyCarRoot
end

function StartCarFly()
    Config.TheBronx.carfly = true
    CarFly.Enabled = true
    LuhjayyCarFlySetup()
    sendNotification("Car Fly", "Luhjayy Car Fly enabled - get in a vehicle!")
end

function StopCarFly()
    Config.TheBronx.carfly = false
    CarFly.Enabled = false
    LuhjayyCarFlyCleanup()
    sendNotification("Car Fly", "Luhjayy Car Fly disabled")
end

task.spawn(function()
    while true do
        task.wait(0.2)
        local char = LocalPlayer.Character
        if not char then continue end
        local h = char:FindFirstChildWhichIsA("Humanoid")
        if not h then continue end
        local currentSeat = h.SeatPart
        if currentSeat and currentSeat:IsA("VehicleSeat") then
            if currentSeat.Parent ~= LuhjayyLastCar then
                LuhjayyCarFlySetup()
            end
        else
            if LuhjayyLastCar then
                LuhjayyCarFlyCleanup()
                LuhjayyLastCar = nil
            end
        end
    end
end)

RunService.RenderStepped:Connect(function()
    if not Config.TheBronx.carfly then
        LuhjayyCarFlyCleanup()
        return
    end
    if not LuhjayyCarHum or LuhjayyCarHum.SeatPart ~= LuhjayyCarSeat then return end
    if not LuhjayyCarRoot or not LuhjayyCarBV or not LuhjayyCarBG then LuhjayyCarFlySetup() return end
    local speed = Config.TheBronx.carflyspeed or 120
    local cam = workspace.CurrentCamera
    local camCF = cam.CFrame
    local camLook = camCF.LookVector
    local camRight = camCF.RightVector
    if not UserInputService.TouchEnabled then
        if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
            LuhjayyCarBG.CFrame = CFrame.lookAt(LuhjayyCarRoot.Position, LuhjayyCarRoot.Position + camLook)
        end
        local move = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += camLook end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= camLook end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= camRight end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += camRight end
        if move.Magnitude > 0 then
            LuhjayyCarBV.Velocity = move.Unit * speed
        else
            LuhjayyCarBV.Velocity = Vector3.zero
        end
    else
        LuhjayyCarBG.CFrame = CFrame.lookAt(LuhjayyCarRoot.Position, LuhjayyCarRoot.Position + camLook)
        local move = LuhjayyCarHum.MoveDirection
        local vertical = camLook.Y
        local velocity = (move * speed) + (Vector3.new(0, vertical, 0) * speed)
        if velocity.Magnitude > 0 then
            LuhjayyCarBV.Velocity = velocity
        else
            LuhjayyCarBV.Velocity = Vector3.zero
        end
    end
end)

function GetNearestCar(hrp)
    local CivCars = workspace:FindFirstChild("CivCars")
    if not CivCars then return nil end
    local nearestCar, nearestDist = nil, math.huge
    for _, car in ipairs(CivCars:GetChildren()) do
        if car:IsA("Model") then
            local seat = car:FindFirstChild("DriveSeat") or car:FindFirstChildWhichIsA("VehicleSeat")
            if seat and not seat.Occupant then
                if not car.PrimaryPart then
                    pcall(function() car.PrimaryPart = car:FindFirstChildWhichIsA("BasePart") end)
                end
                if car.PrimaryPart then
                    local d = (car.PrimaryPart.Position - hrp.Position).Magnitude
                    if d < nearestDist then nearestDist, nearestCar = d, car end
                end
            end
        end
    end
    return nearestCar
end

VehicleModifications = {
    SpeedEnabled = false, SpeedValue = 10/1000,
    BreakEnabled = false, BreakValue = 50/1000,
    InstantStop  = false,
}

task.spawn(function()
    while task.wait() do
        local char = LocalPlayer.Character
        local hum  = char and char:FindFirstChildWhichIsA("Humanoid")
        local seat = hum and hum.SeatPart
        if seat and seat:IsA("VehicleSeat") then
            if VehicleModifications.SpeedEnabled and UserInputService:IsKeyDown(Enum.KeyCode.W) then
                seat.AssemblyLinearVelocity = seat.AssemblyLinearVelocity *
                    Vector3.new(1+VehicleModifications.SpeedValue, 1, 1+VehicleModifications.SpeedValue)
            end
            if VehicleModifications.BreakEnabled and UserInputService:IsKeyDown(Enum.KeyCode.S) then
                seat.AssemblyLinearVelocity = seat.AssemblyLinearVelocity *
                    Vector3.new(1-VehicleModifications.BreakValue, 1, 1-VehicleModifications.BreakValue)
            end
            if VehicleModifications.InstantStop and UserInputService:IsKeyDown(Enum.KeyCode.V) then
                seat.AssemblyLinearVelocity  = Vector3.zero
                seat.AssemblyAngularVelocity = Vector3.zero
            end
        end
    end
end)




AutoGrabMoney       = false
AutoCleanMoney      = false
StudioMoneyNotifyEnabled = false
StudioMoneyNotifyConnections = {}
dumpsterIsRunning   = false
dumpsterTask        = nil
constructionRunning = false
constructionThread  = nil
AutoStealLootbags   = false
AutoPickupBags      = false
DisableBloodEffects = false
BypassLockedCars    = false
NoKnockback         = false
FasterRespawn       = false
RespawnWhereYouDied = false
RespawnDeathCFrame = nil
RespawnDeathConnections = {}
RespawnCharacterConnection = nil
KeepToolsOnDeath    = false
AutoFOnLowHealth    = false
NoCameraBob         = false
AntiJumpCooldownEnabled = false
AntiJumpDisabledScripts = {}

local function ClearRespawnDeathConnections()
    for _, connection in ipairs(RespawnDeathConnections) do
        pcall(function() connection:Disconnect() end)
    end
    RespawnDeathConnections = {}
end

local function CaptureRespawnDeathPosition(character)
    if not RespawnWhereYouDied or not character then return end
    local root = character:FindFirstChild("HumanoidRootPart")
    if root then
        RespawnDeathCFrame = root.CFrame
    end
end

local function BindRespawnWhereDiedCharacter(character)
    ClearRespawnDeathConnections()
    if not character then return end

    local humanoid = character:WaitForChild("Humanoid", 10)
    local root = character:WaitForChild("HumanoidRootPart", 10)
    if not humanoid or not root then return end

    local captured = false
    table.insert(RespawnDeathConnections, humanoid.HealthChanged:Connect(function(health)
        if health <= 0 and not captured then
            captured = true
            CaptureRespawnDeathPosition(character)
        end
    end))
    table.insert(RespawnDeathConnections, humanoid.Died:Connect(function()
        if not captured then
            captured = true
            CaptureRespawnDeathPosition(character)
        end
    end))
end

function SetRespawnWhereYouDied(state)
    RespawnWhereYouDied = state == true
    if not RespawnWhereYouDied then
        RespawnDeathCFrame = nil
    end
end

if LocalPlayer.Character then
    task.defer(BindRespawnWhereDiedCharacter, LocalPlayer.Character)
end
RespawnCharacterConnection = LocalPlayer.CharacterAdded:Connect(function(character)
    local returnCFrame = RespawnWhereYouDied and RespawnDeathCFrame or nil
    BindRespawnWhereDiedCharacter(character)
    if not returnCFrame then return end

    task.spawn(function()
        local root = character:WaitForChild("HumanoidRootPart", 10)
        local humanoid = character:WaitForChild("Humanoid", 10)
        if not root or not humanoid or not RespawnWhereYouDied then return end
        task.wait(0.8)

        local restored = pcall(function()
            Config:Teleport(returnCFrame)
        end)
        if not restored and root.Parent then
            root.CFrame = returnCFrame
        end
        if root.Parent then
            root.CFrame = returnCFrame
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end
        RespawnDeathCFrame = nil
        sendNotification("Respawn", "Returned to your death position.")
    end)
end)

Library:OnUnload(function()
    ClearRespawnDeathConnections()
    if RespawnCharacterConnection then
        RespawnCharacterConnection:Disconnect()
        RespawnCharacterConnection = nil
    end
end)

function SetAntiJumpCooldownEnabled(state)
    AntiJumpCooldownEnabled = state

    local function process(container)
        if not container then return end
        for _, object in ipairs(container:GetDescendants()) do
            if object:IsA("LocalScript") then
                local name = object.Name:lower()
                local path = object:GetFullName():lower()
                local isJumpCooldown = (name:find("jump") and (name:find("debounce") or name:find("cooldown")))
                    or path:find("jumpdebounce", 1, true)
                    or path:find("jumpcooldown", 1, true)
                if isJumpCooldown then
                    if state then
                        if AntiJumpDisabledScripts[object] == nil then
                            AntiJumpDisabledScripts[object] = object.Enabled
                        end
                        object.Enabled = false
                    elseif AntiJumpDisabledScripts[object] ~= nil then
                        object.Enabled = AntiJumpDisabledScripts[object]
                        AntiJumpDisabledScripts[object] = nil
                    end
                end
            end
        end
    end

    process(LocalPlayer:FindFirstChild("PlayerGui"))
    process(LocalPlayer.Character)

    if not state then
        for scriptObject, previousState in pairs(AntiJumpDisabledScripts) do
            pcall(function()
                if scriptObject and scriptObject.Parent then scriptObject.Enabled = previousState end
            end)
            AntiJumpDisabledScripts[scriptObject] = nil
        end
    end
end


LocalPlayer:WaitForChild("PlayerGui").DescendantAdded:Connect(function(object)
    if not AntiJumpCooldownEnabled or not object:IsA("LocalScript") then return end
    local name = object.Name:lower()
    local path = object:GetFullName():lower()
    local isJumpCooldown = (name:find("jump") and (name:find("debounce") or name:find("cooldown")))
        or path:find("jumpdebounce", 1, true)
        or path:find("jumpcooldown", 1, true)
    if isJumpCooldown then
        task.defer(function()
            if object.Parent then
                AntiJumpDisabledScripts[object] = object.Enabled
                object.Enabled = false
            end
        end)
    end
end)

LocalPlayer.CharacterAdded:Connect(function(character)
    if AntiJumpCooldownEnabled then
        task.delay(0.5, function() SetAntiJumpCooldownEnabled(true) end)
    end
end)



local LastForcedJump = 0
UserInputService.JumpRequest:Connect(function()
    if not AntiJumpCooldownEnabled or os.clock() - LastForcedJump < 0.08 then return end
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not root or humanoid.Health <= 0 then return end

    local grounded = humanoid.FloorMaterial ~= Enum.Material.Air
    if not grounded then
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = {character}
        grounded = workspace:Raycast(root.Position, Vector3.new(0, -4.5, 0), params) ~= nil
    end
    if not grounded then return end

    LastForcedJump = os.clock()
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
    humanoid.Jump = true
    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)

    local jumpVelocity = 50
    if humanoid.UseJumpPower then
        jumpVelocity = math.max(tonumber(humanoid.JumpPower) or 50, 50)
    else
        jumpVelocity = math.sqrt(2 * workspace.Gravity * math.max(tonumber(humanoid.JumpHeight) or 7.2, 7.2))
    end
    local velocity = root.AssemblyLinearVelocity
    root.AssemblyLinearVelocity = Vector3.new(velocity.X, math.max(velocity.Y, jumpVelocity), velocity.Z)
end)

AntiCarFlingEnabled = false
AntiCarFlingConnection = nil
AntiCarFlingSavedParts = {}
AntiCarFlingProtectedCars = {}

local function RestoreAntiCarFlingPart(part)
    local saved = AntiCarFlingSavedParts[part]
    if saved then
        pcall(function()
            if part and part.Parent then
                part.CanCollide = saved.CanCollide
                part.CanTouch = saved.CanTouch
            end
        end)
        AntiCarFlingSavedParts[part] = nil
    end
end

local function ProtectFromFlingCar(car)
    if not car then return end
    AntiCarFlingProtectedCars[car] = os.clock() + 1.25
    for _, part in ipairs(car:GetDescendants()) do
        if part:IsA("BasePart") then
            if not AntiCarFlingSavedParts[part] then
                AntiCarFlingSavedParts[part] = {
                    CanCollide = part.CanCollide,
                    CanTouch = part.CanTouch,
                }
            end
            part.CanCollide = false
            part.CanTouch = false
        end
    end
end

local function GetAntiFlingCars()
    local cars = {}
    for _, folderName in ipairs({"CivCars", "PoliceCars", "NPCCars", "Cars", "Vehicles"}) do
        local folder = workspace:FindFirstChild(folderName)
        if folder then
            for _, car in ipairs(folder:GetChildren()) do
                if car:IsA("Model") then table.insert(cars, car) end
            end
        end
    end
    return cars
end

function StopAntiCarFling()
    AntiCarFlingEnabled = false
    if AntiCarFlingConnection then
        AntiCarFlingConnection:Disconnect()
        AntiCarFlingConnection = nil
    end
    for part in pairs(AntiCarFlingSavedParts) do
        RestoreAntiCarFlingPart(part)
    end
    table.clear(AntiCarFlingProtectedCars)
end

function StartAntiCarFling()
    StopAntiCarFling()
    AntiCarFlingEnabled = true

    AntiCarFlingConnection = RunService.Heartbeat:Connect(function()
        if not AntiCarFlingEnabled then return end
        local character = LocalPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if not humanoid or not root or humanoid.Health <= 0 then return end

        local occupiedSeat = humanoid.SeatPart
        local occupiedCar = occupiedSeat and occupiedSeat:FindFirstAncestorWhichIsA("Model")
        local detectedFling = false

        for _, car in ipairs(GetAntiFlingCars()) do
            if car ~= occupiedCar then
                local mainPart = car.PrimaryPart
                    or car:FindFirstChild("DriveSeat", true)
                    or car:FindFirstChildWhichIsA("BasePart", true)
                if mainPart then
                    local distance = (mainPart.Position - root.Position).Magnitude
                    local linearSpeed = mainPart.AssemblyLinearVelocity.Magnitude
                    local spinSpeed = mainPart.AssemblyAngularVelocity.Magnitude

                    
                    
                    if distance <= 9 or (distance <= 28 and (linearSpeed >= 90 or spinSpeed >= 35)) then
                        ProtectFromFlingCar(car)
                        detectedFling = true
                    end
                end
            end
        end

        if detectedFling then
            if humanoid.Sit and not occupiedCar then
                humanoid.Sit = false
                humanoid.Jump = true
                humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
            if root.AssemblyLinearVelocity.Magnitude > 120 then
                root.AssemblyLinearVelocity = Vector3.zero
            end
            if root.AssemblyAngularVelocity.Magnitude > 30 then
                root.AssemblyAngularVelocity = Vector3.zero
            end
        end

        
        local now = os.clock()
        for car, expires in pairs(AntiCarFlingProtectedCars) do
            if not car.Parent or now >= expires then
                AntiCarFlingProtectedCars[car] = nil
                for part in pairs(AntiCarFlingSavedParts) do
                    if not part.Parent or part:IsDescendantOf(car) then
                        RestoreAntiCarFlingPart(part)
                    end
                end
            end
        end
    end)
end

PawnRemote          = ReplicatedStorage:FindFirstChild("PawnRemote")
Backpack            = LocalPlayer:WaitForChild("Backpack", 5) or LocalPlayer:FindFirstChild("Backpack")
BackpackRemote      = ReplicatedStorage:FindFirstChild("BackpackRemote")
InventoryRemote     = ReplicatedStorage:FindFirstChild("Inventory")

function fireRemoteForAllBackpackItems()
    if not Backpack then return end
    for _, item in pairs(Backpack:GetChildren()) do
        pcall(function() if PawnRemote then PawnRemote:FireServer(item.Name) end end)
    end
end
if Backpack then
    Backpack.ChildAdded:Connect(function(child)
        if dumpsterIsRunning then pcall(function() if PawnRemote then PawnRemote:FireServer(child.Name) end end) end
    end)
end

function startDumpsterAutofarm()
    if dumpsterTask then return end
    dumpsterIsRunning = true
    dumpsterTask = task.spawn(function()
        while dumpsterIsRunning do
            local dumpsters = {}
            for _, v in pairs(workspace:GetDescendants()) do
                if v:IsA("Part") and v.Name == "DumpsterPromt" then
                    local p = v:FindFirstChildWhichIsA("ProximityPrompt")
                    if p then table.insert(dumpsters, { part = v, prompt = p }) end
                end
            end
            for _, e in ipairs(dumpsters) do
                if not dumpsterIsRunning then break end
                if e.part and e.prompt and e.part:IsDescendantOf(workspace) then
                    Config:Teleport(CFrame.new(e.part.Position + Vector3.new(0,3,0)))
                    task.wait(0.6)
                    pcall(function() fireproximityprompt(e.prompt) end)
                    task.wait(1)
                end
            end
            task.wait(2)
        end
        dumpsterTask = nil
    end)
    fireRemoteForAllBackpackItems()
end
function stopDumpsterAutofarm() dumpsterIsRunning = false end

constructionPrevInstant = nil
constructionSpamThread = nil

function startConstructionAutofarm()
    if constructionThread then return end
    constructionRunning = true

    -- turn Instant Interaction on automatically (remember if it was already on)
    local instantToggle = Toggles and Toggles.InstantInteraction
    constructionPrevInstant = instantToggle and instantToggle.Value or false
    if not constructionPrevInstant then
        if instantToggle then
            pcall(function() instantToggle:SetValue(true) end)
        else
            pcall(refreshPrompts, true)
        end
    end

    -- spam E while the farm runs
    constructionSpamThread = task.spawn(function()
        local VIM = game:GetService("VirtualInputManager")
        while constructionRunning do
            pcall(function()
                VIM:SendKeyEvent(true, Enum.KeyCode.E, false, nil)
                task.wait(0.02)
                VIM:SendKeyEvent(false, Enum.KeyCode.E, false, nil)
            end)
            task.wait(0.05)
        end
        constructionSpamThread = nil
    end)
    constructionThread = task.spawn(function()
        while constructionRunning do
            task.wait(1)
            pcall(function()
                if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
                if not LocalPlayer.Character:FindFirstChild("Humanoid") or LocalPlayer.Character:FindFirstChild("Humanoid").Health == 0 then return end
                if not LocalPlayer:GetAttribute("WorkingJob") then
                    Config:Teleport(CFrame.new(-1729, 371, -1171))
                    task.wait(0.4)
                    fireproximityprompt(workspace.ConstructionStuff["Start Job"].Prompt)
                    repeat task.wait() until LocalPlayer:GetAttribute("WorkingJob") or not constructionRunning
                end
                if not LocalPlayer.Backpack:FindFirstChild("PlyWood") and not LocalPlayer.Character:FindFirstChild("PlyWood") then
                    Config:Teleport(CFrame.new(-1728, 371, -1178))
                    repeat task.wait() fireproximityprompt(workspace.ConstructionStuff["Grab Wood"].Prompt) until LocalPlayer.Backpack:FindFirstChild("PlyWood") or LocalPlayer.Character:FindFirstChild("PlyWood") or not constructionRunning
                end
                repeat task.wait() until LocalPlayer.Backpack:FindFirstChild("PlyWood") or LocalPlayer.Character:FindFirstChild("PlyWood") or not constructionRunning
                if LocalPlayer.Backpack:FindFirstChild("PlyWood") then
                    LocalPlayer.Character.Humanoid:EquipTool(LocalPlayer.Backpack:FindFirstChild("PlyWood"))
                end
                local targetWood
                for _, v in pairs(workspace.ConstructionStuff:GetDescendants()) do
                    if v:IsA("ProximityPrompt") and v.ActionText == "Wall" then targetWood = v; break end
                end
                if targetWood and targetWood.Parent then
                    Config:Teleport(targetWood.Parent.CFrame + Vector3.new(0,3,0)); task.wait(0.4)
                    fireproximityprompt(targetWood); task.wait(1)
                end
            end)
        end
        constructionThread = nil
    end)
end
function stopConstructionAutofarm()
    constructionRunning = false
    if constructionThread then task.cancel(constructionThread); constructionThread = nil end
    if constructionSpamThread then task.cancel(constructionSpamThread); constructionSpamThread = nil end

    -- put Instant Interaction back how it was before the farm started
    if constructionPrevInstant == false then
        local instantToggle = Toggles and Toggles.InstantInteraction
        if instantToggle then
            pcall(function() instantToggle:SetValue(false) end)
        else
            pcall(refreshPrompts, false)
        end
    end
    constructionPrevInstant = nil
end


promptConnections  = {}
promptAddedConnection = nil
function setupPrompt(p, enableInstant)
    if not p or not p:IsA("ProximityPrompt") then return end
    if enableInstant then
        p.HoldDuration        = 0
        p.RequiresLineOfSight = false
        promptConnections[p]  = true
    else
        p.HoldDuration        = 1
        p.RequiresLineOfSight = true
        promptConnections[p]  = nil
    end
end

function refreshPrompts(enableInstant)
    for prompt, conn in pairs(promptConnections) do
        if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end
        promptConnections[prompt] = nil
    end
    for _, p in ipairs(workspace:GetDescendants()) do
        if p:IsA("ProximityPrompt") then setupPrompt(p, enableInstant) end
    end
    if promptAddedConnection then promptAddedConnection:Disconnect(); promptAddedConnection = nil end
    if enableInstant then
        promptAddedConnection = workspace.DescendantAdded:Connect(function(d)
            if d:IsA("ProximityPrompt") then setupPrompt(d, true) end
        end)
    end
end

function watchStudioPayPrompt(studioPayName)
    local sp = workspace:FindFirstChild("StudioPay"); if not sp then return end
    local mf = sp:FindFirstChild("Money"); if not mf then return end
    local part = mf:FindFirstChild(studioPayName); if not part then return end
    local prompt = part:FindFirstChild("Prompt"); if not prompt or not prompt:IsA("ProximityPrompt") then return end
    local c = prompt:GetPropertyChangedSignal("Enabled"):Connect(function()
        if not StudioMoneyNotifyEnabled then return end
        sendNotification(prompt.Enabled and "Studio Money Restocked" or "Studio Money Stolen",
            prompt.Enabled and "Money in studio restocked." or "1 money in studio just got stolen!")
    end)
    table.insert(StudioMoneyNotifyConnections, c)
end
function cleanupStudioMoneyNotify()
    for _, c in ipairs(StudioMoneyNotifyConnections) do if c and c.Disconnect then c:Disconnect() end end
    StudioMoneyNotifyConnections = {}
end


ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt, selfPlayer)
    if not (prompt and selfPlayer == LocalPlayer and BypassLockedCars) then return end
    local check = prompt.Parent
    while check and check.Parent do
        local seat = check:FindFirstChild("DriveSeat")
        if seat and seat:IsA("VehicleSeat") and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            pcall(function() seat:Sit(LocalPlayer.Character.Humanoid) end); break
        end
        check = check.Parent
    end
end)

task.spawn(function()
    while task.wait(0.1) do
        if FasterRespawn and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") and LocalPlayer.Character.Humanoid:GetState() == Enum.HumanoidStateType.Dead then
            local lc = ReplicatedStorage:FindFirstChild("LoadCharacter")
            if lc and lc:IsA("RemoteEvent") then pcall(function() lc:FireServer() end) end
        end
    end
end)

RunService.RenderStepped:Connect(function()
    if NoCameraBob then
        local char = LocalPlayer.Character; local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum and hum.CameraOffset.Magnitude > 0 then hum.CameraOffset = Vector3.zero end
    end
end)

task.spawn(function()
    while task.wait(0.1) do
        if not AutoFOnLowHealth then break end
        local char = LocalPlayer.Character; local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health > 0 and hum.Health < 10 then
            pcall(function()
                local V = game:GetService("VirtualInputManager")
                V:SendKeyEvent(true, Enum.KeyCode.F, false, nil); task.wait(0.05)
                V:SendKeyEvent(false, Enum.KeyCode.F, false, nil)
            end)
        end
    end
end)


LuhjayyWalk = LuhjayyWalk or {
    Speed = 16,
    BoostMultiplier = 2,
    Enabled = false,
    Character = nil,
    Humanoid = nil,
    Root = nil,
    BodyGyro = nil,
    MovementConnection = nil,
    FreezeConnection = nil,
    AnimationTrack = nil,
}
LuhjayyWalk.Animation = LuhjayyWalk.Animation or Instance.new("Animation")
LuhjayyWalk.Animation.AnimationId = "rbxassetid://130336142547434"

function LuhjayyWalkUpdateCharacter()
    LuhjayyWalk.Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    LuhjayyWalk.Root = LuhjayyWalk.Character:WaitForChild("HumanoidRootPart")
    LuhjayyWalk.Humanoid = LuhjayyWalk.Character:WaitForChild("Humanoid")
end

function LuhjayyWalkCleanup()
    if LuhjayyWalk.MovementConnection then LuhjayyWalk.MovementConnection:Disconnect();LuhjayyWalk.MovementConnection=nil end
    if LuhjayyWalk.FreezeConnection then LuhjayyWalk.FreezeConnection:Disconnect();LuhjayyWalk.FreezeConnection=nil end
    if LuhjayyWalk.BodyGyro then LuhjayyWalk.BodyGyro:Destroy();LuhjayyWalk.BodyGyro=nil end
    if LuhjayyWalk.AnimationTrack then pcall(function()LuhjayyWalk.AnimationTrack:Stop()end);LuhjayyWalk.AnimationTrack=nil end
end

function LuhjayyWalkSetupMovement()
    local humanoid=LuhjayyWalk.Humanoid
    local root=LuhjayyWalk.Root
    if not humanoid or not root then return end
    local bodyGyro=Instance.new("BodyGyro")
    bodyGyro.MaxTorque=Vector3.new(math.huge,math.huge,math.huge)
    bodyGyro.P=50000
    bodyGyro.D=1000
    bodyGyro.CFrame=root.CFrame
    bodyGyro.Parent=root
    LuhjayyWalk.BodyGyro=bodyGyro

    LuhjayyWalk.MovementConnection=RunService.RenderStepped:Connect(function()
        if not LuhjayyWalk.Enabled or not root.Parent then return end
        local camera=workspace.CurrentCamera
        local dir=Vector3.zero
        local usingKeys=false
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir+=Vector3.new(camera.CFrame.LookVector.X,0,camera.CFrame.LookVector.Z);usingKeys=true end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir-=Vector3.new(camera.CFrame.LookVector.X,0,camera.CFrame.LookVector.Z);usingKeys=true end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir-=camera.CFrame.RightVector;usingKeys=true end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir+=camera.CFrame.RightVector;usingKeys=true end
        if not usingKeys then local md=humanoid.MoveDirection;dir=Vector3.new(md.X,0,md.Z) end
        local moveSpeed=LuhjayyWalk.Speed
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveSpeed*=LuhjayyWalk.BoostMultiplier end
        if dir.Magnitude>0 then dir=dir.Unit*moveSpeed end
        local currentY=root.AssemblyLinearVelocity.Y
        local groundedY=math.clamp(currentY,-100,-2)
        root.AssemblyLinearVelocity=Vector3.new(dir.X,groundedY,dir.Z)
        if dir.Magnitude>0 then
            local look=dir.Unit
            bodyGyro.CFrame=CFrame.new(root.Position,root.Position+Vector3.new(look.X,0,look.Z))
        end
        root.RotVelocity=Vector3.zero
        root.AssemblyAngularVelocity=Vector3.zero
        if LuhjayyWalk.AnimationTrack then
            if dir.Magnitude>0 then
                if not LuhjayyWalk.AnimationTrack.IsPlaying then LuhjayyWalk.AnimationTrack:Play() end
            elseif LuhjayyWalk.AnimationTrack.IsPlaying then
                LuhjayyWalk.AnimationTrack:Stop()
            end
        end
    end)
end

function LuhjayyWalkStart()
    LuhjayyWalk.Enabled=true
    LuhjayyWalkUpdateCharacter()
    LuhjayyWalkCleanup()
    local root,humanoid=LuhjayyWalk.Root,LuhjayyWalk.Humanoid
    root.AssemblyLinearVelocity=Vector3.zero
    getgenv().SwimMethod=true
    LuhjayyWalk.FreezeConnection=RunService.RenderStepped:Connect(function()
        if LuhjayyWalk.Enabled and root.Parent then
            if not getgenv().SwimMethod then getgenv().SwimMethod=true end
            root.AssemblyLinearVelocity=Vector3.zero
        end
    end)
    pcall(function()
        local animator=humanoid:FindFirstChildWhichIsA("Animator") or Instance.new("Animator",humanoid)
        LuhjayyWalk.AnimationTrack=animator:LoadAnimation(LuhjayyWalk.Animation)
        LuhjayyWalk.AnimationTrack.Looped=true
    end)
    task.delay(3,function()
        if LuhjayyWalk.FreezeConnection then LuhjayyWalk.FreezeConnection:Disconnect();LuhjayyWalk.FreezeConnection=nil end
        if LuhjayyWalk.Enabled then LuhjayyWalkSetupMovement() end
    end)
end

function LuhjayyWalkStop()
    LuhjayyWalk.Enabled=false
    LuhjayyWalkCleanup()
    getgenv().SwimMethod=false
end

function updateSpeedBoostState(state)
    if state then LuhjayyWalkStart() else LuhjayyWalkStop() end
end

task.spawn(function()
    while task.wait() do
        if LuhjayyWalk.Enabled then
            if not getgenv().SwimMethod then getgenv().SwimMethod=true end
            if LuhjayyWalk.Humanoid then LuhjayyWalk.Humanoid:ChangeState(Enum.HumanoidStateType.FallingDown) end
        end
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    LuhjayyWalkUpdateCharacter()
    if LuhjayyWalk.Enabled then LuhjayyWalkStart() end
end)

function updateJumpBoostState(s)
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hum = char:FindFirstChildOfClass("Humanoid"); if not hum then return end
    hum.JumpPower = s and ((hum.JumpPower or 50)+50) or 50
end

InfJumpEnabled = false
UserInputService.JumpRequest:Connect(function()
    if InfJumpEnabled then
        local char = LocalPlayer.Character; local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

noclipConnection = nil
function enableNoclip()
    if noclipConnection then return end
    noclipConnection = RunService.Stepped:Connect(function()
        if not NoclipEnabled then return end
        local ch = LocalPlayer.Character
        if ch then for _, p in pairs(ch:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end end
    end)
end
function disableNoclip()
    if noclipConnection then noclipConnection:Disconnect(); noclipConnection=nil end
    local ch = LocalPlayer.Character
    if ch then for _, p in pairs(ch:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = true end end end
end


teleportLocations = {
    ["🏦 Bank"] = CFrame.new(-1216, 254, -3640),
    ["💵 Money Wash"] = CFrame.new(-977.1771, 253.6838, -692.5855),
    ["💸 Money Wash 2"] = CFrame.new(-711.918701, 241.92627, -577.127869),
    ["📦 Safe Items"] = CFrame.new(99.992218, 286.523071, -915.044067),
    ["💰 Pawn Shop"] = CFrame.new(-1049.6431, 253.5367, -814.2697),
    ["🤑 Mr Money Man"] = CFrame.new(-1008.0662, 262.1141, 55.1336),
    ["🔫 GunShop 1"] = CFrame.new(92978, 122099, 17232),
    ["🔫 GunShop 1 Lobby"] = CFrame.new(-1002.4224, 253.6382, -803.9125),
    ["🔫 GunShop 2"] = CFrame.new(66195.4453125, 123615.7109375, 5750.2827148438),
    ["🔫 GunShop 2 Lobby"] = CFrame.new(-224.3818359375, 283.8034362793, -794.71740722656),
    ["🔫 GunShop 3"] = CFrame.new(60820.3086, 87609.1484, -351.4746),
    ["🔫 GunShop 4"] = CFrame.new(72421.9140625, 128855.8203125, -1080.6110839844),
    ["🔫 GunShop 5"] = CFrame.new(-956, 260, -4255),
    ["🏢 Pent House"] = CFrame.new(-1526, 463, -3691),
    ["🏠 Mini Mansion"] = CFrame.new(-791.51800537109, 256.79446411133, 1414.4248046875),
    ["🏢 Roof"] = CFrame.new(-381.65390014648, 463.69107055664, -706.35809326172),
    ["🎒 Backpack Shop"] = CFrame.new(-703.339355, 253.918518, -694.008057),
    ["📱 T-Mobile"] = CFrame.new(-682, 254, -708),
    ["💎 Frozen Shop"] = CFrame.new(-1206, 254, -3994),
    ["💧 Drip Store"] = CFrame.new(67462.6953, 10489.0352, 549.5895),
    ["🍗 Chicken Wings"] = CFrame.new(-957.9142, 253.5367, -815.9442),
    ["🍗 Dk's Chicken"] = CFrame.new(-608.566101, 253.932587, -466.396851),
    ["🥪 Deli"] = CFrame.new(-755.81140136719, 254.69274902344, -687.1181640625),
    ["🥪 Deli 2"] = CFrame.new(-1377, 254, -3900),
    ["🍪 Popeyeas"] = CFrame.new(-71.805892944336, 283.64181518555, -769.44488525391),
    ["🍕 Lil Caesars"] = CFrame.new(-611.523376, 254.308807, -800.337341),
    ["🌮 Taco Shop"] = CFrame.new(-672.696655, 253.827667, -807.83844),
    ["😋 Burger n Fries"] = CFrame.new(-750.633545, 253.76123, -784.572021),
    ["🍟 McDonald's"] = CFrame.new(-442.66629, 254.0047, -949.697327),
    ["🚗 Car Dealer"] = CFrame.new(-401.99371337891, 253.41410827637, -1248.8380126953),
    ["🚗 Car Dealer 2"] = CFrame.new(-1556, 254, -3842),
    ["🥤 Soda Warehouse"] = CFrame.new(-187.85504150391, 284.62521362305, -291.34191894531),
    ["🍾 Soda Supplies"] = CFrame.new(-403.09906005859, 254.20343017578, -580.04376220703),
    ["🍹 Soda Seller"] = CFrame.new(-1292.2200927734, 253.30044555664, -3003.0483398438),
    ["🐍 Exotic Dealer"] = CFrame.new(-1523.5654296875, 273.97299194336, -990.65753173828),
    ["⛽ Gas Station"] = CFrame.new(-1430, 255, -4271),
    ["🔀 Switch Seller"] = CFrame.new(-1446.2166748047, 256.05981445312, 2189.8762207031),
    ["🏢 Bank Tools"] = CFrame.new(-397.43087768555, 334.31423950195, -555.70233154297),
    ["🚧 Construction Site"] = CFrame.new(-1731.8307, 370.8123, -1176.8387),
    ["🚔 Prison"] = CFrame.new(-1135.0464, 254.716, -3330.9954),
    ["❄️ Ice Box"] = CFrame.new(-215.1407, 283.5154, -1258.691),
    ["🏥 Hospital"] = CFrame.new(-1589.5041503906, 254.27223205566, 17.655523300171),
    ["🛍️ MarGreens"] = CFrame.new(-381.20751953125, 254.4538269043, -385.66546630859),
    ["🚨 Feds Room"] = CFrame.new(-1441.7904052734, 255.03651428223, -3132.5974121094),
    ["🏧 ATM 1"] = CFrame.new(-1043.4736328125, 254.8318939209, -1127.0150146484),
    ["🏧 ATM 2"] = CFrame.new(-738.25616455078, 253.76121520996094, -787.85723876953),
    ["🏧 ATM 3"] = CFrame.new(-96.723564147949, 283.63293457031, -766.33093261719),
    ["🚪 House Rob"] = CFrame.new(-613.05187988281, 254.07281494141, -730.70892333984),
    ["💰 Studio Robbery"] = CFrame.new(93427.515625, 14484.905273438, 566.67010498047),
    ["🏕️ TrailerPark"] = CFrame.new(-1522.7690429688, 253.16094970703, 2344.95947265625),
    ["🏨 Woody's Hotel"] = CFrame.new(-1022.6196289062, 325.84005737305, -908.91571044922),
    ["🎤 Marleys Studio"] = CFrame.new(-1541.264282, 280.952393, -1023.484375),
}
QUICK_TP_KEYS = {
    "🚗 Car Dealer", "🔫 GunShop 1", "💰 Studio Robbery", "🐍 Exotic Dealer",
    "🎒 Backpack Shop", "🏢 Pent House", "🔫 GunShop 5", "🥪 Deli 2",
}
QUICK_TP_LOOKUP = {}
for _, k in ipairs(QUICK_TP_KEYS) do QUICK_TP_LOOKUP[k] = true end

teleportNames = {}
for n in pairs(teleportLocations) do
    if not QUICK_TP_LOOKUP[n] then table.insert(teleportNames, n) end
end
table.sort(teleportNames)

function TeleportToCookPot()
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local pos = hrp and hrp.Position or Vector3.zero
    local pot, best = nil, math.huge
    local function check(p) if p and p:IsA("BasePart") then local d=(p.Position-pos).Magnitude; if d<best then best,pot=d,p end end end
    if workspace:FindFirstChild("CookingPots") then
        for _, v in pairs(workspace.CookingPots:GetChildren()) do
            if v:IsA("Model") then check(v:FindFirstChild("CookPart") or v.PrimaryPart or v:FindFirstChildWhichIsA("BasePart")) end
        end
    end
    if pot then Config:Teleport(pot.CFrame + Vector3.new(0,1.5,0)); sendNotification("Teleport","Teleported to nearest Cook Pot!")
    else Config:Teleport(CFrame.new(-198.89, 283.85, -1170.45)); sendNotification("Teleport","Fallback CookPot location.") end
end


function valueToNumber(o) if not o then return nil end local ok,v=pcall(function() return o.Value end); if ok and tonumber(v) then return tonumber(v) end end
function findMoneyValue(c, names, recursive)
    if not c then return nil end
    local lk={}; for _, n in ipairs(names) do lk[string.lower(n)] = true end
    for _, ch in ipairs(c:GetChildren()) do if lk[string.lower(ch.Name)] then local v=valueToNumber(ch); if v~=nil then return v end end end
    if recursive then for _, ch in ipairs(c:GetDescendants()) do if lk[string.lower(ch.Name)] then local v=valueToNumber(ch); if v~=nil then return v end end end end
end
function getMyMoneyValues()
    local cN={"Money","Cash","Wallet","Bank","Coins"}
    local dN={"FilthyStack","FilthyMoney","DirtyMoney","DirtyCash","IllegalMoney","Dirty","Filthy"}
    local stored = LocalPlayer:FindFirstChild("stored") or LocalPlayer:FindFirstChild("Stored")
    local leader = LocalPlayer:FindFirstChild("leaderstats") or LocalPlayer:FindFirstChild("Leaderstats") or LocalPlayer:FindFirstChild("stats")
    local clean = findMoneyValue(stored,{"Money"},false) or findMoneyValue(leader,cN,false) or findMoneyValue(LocalPlayer,cN,false) or findMoneyValue(LocalPlayer,cN,true)
    local dirty = findMoneyValue(stored,{"FilthyStack"},false) or findMoneyValue(stored,dN,false) or findMoneyValue(LocalPlayer,dN,false) or findMoneyValue(LocalPlayer,dN,true)
    return clean, dirty
end
function getBankValue2()
    local stored = LocalPlayer:FindFirstChild("stored")
    local leader = LocalPlayer:FindFirstChild("leaderstats") or LocalPlayer:FindFirstChild("stats")
    return findMoneyValue(stored,{"Bank"},false) or findMoneyValue(leader,{"Bank"},false) or findMoneyValue(LocalPlayer,{"Bank"},true)
end

function formatMoney(amount)
    local formatted = tostring(math.floor(tonumber(amount) or 0))
    while true do
        local newFormatted, count = formatted:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
        formatted = newFormatted
        if count == 0 then break end
    end
    return "$" .. formatted
end


getgenv().MiamiFlyData = getgenv().MiamiFlyData or {
    Enabled = false,
    Connections = {},
    Velocity = nil,
    Gyro = nil,
    Seat = nil,
    Weld = nil,
    Speed = 80,
    Move = {W=false, A=false, S=false, D=false, Space=false, Shift=false}
}

function MiamiFlyCleanup()
    local data = getgenv().MiamiFlyData
    if not data then return end

    data.Enabled = false

    for _, connection in ipairs(data.Connections or {}) do
        pcall(function()
            if connection and connection.Disconnect then
                connection:Disconnect()
            end
        end)
    end
    data.Connections = {}

    for _, item in ipairs({data.Velocity, data.Gyro, data.Weld, data.Seat}) do
        pcall(function()
            if item and item.Parent then
                item:Destroy()
            end
        end)
    end

    data.Velocity = nil
    data.Gyro = nil
    data.Weld = nil
    data.Seat = nil
    data.Move = {W=false, A=false, S=false, D=false, Space=false, Shift=false}
    getgenv().SwimMethod = false

    local character = LocalPlayer and LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if humanoid then
        pcall(function()
            humanoid.Sit = false
            humanoid.PlatformStand = false
            humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        end)
    end
    if root then
        pcall(function()
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end)
    end
end

function MiamiFlySetup()
    local data = getgenv().MiamiFlyData
    if not data then return end

    MiamiFlyCleanup()

    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not root then
        sendNotification("Fly", "Character not ready.")
        return
    end

    data.Enabled = true
    getgenv().SwimMethod = true

    local seat = Instance.new("VehicleSeat")
    seat.Name = "MiamiFlySeat"
    seat.Anchored = false
    seat.CanCollide = false
    seat.Transparency = 1
    seat.Size = Vector3.new(2, 1, 2)
    seat.CFrame = root.CFrame * CFrame.new(0, -3, 0)
    seat.Parent = workspace
    data.Seat = seat

    local weld = Instance.new("Weld")
    weld.Name = "MiamiFlyWeld"
    weld.Part0 = seat
    weld.Part1 = root
    weld.C0 = CFrame.new(0, 3, 0)
    weld.Parent = seat
    data.Weld = weld

    pcall(function() seat:Sit(humanoid) end)

    local velocity = Instance.new("BodyVelocity")
    velocity.Name = "MiamiFlyVelocity"
    velocity.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    velocity.Velocity = Vector3.zero
    velocity.Parent = root
    data.Velocity = velocity

    local gyro = Instance.new("BodyGyro")
    gyro.Name = "MiamiFlyGyro"
    gyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
    gyro.P = 50000
    gyro.D = 1000
    gyro.CFrame = root.CFrame
    gyro.Parent = root
    data.Gyro = gyro

    table.insert(data.Connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.W then data.Move.W = true end
        if input.KeyCode == Enum.KeyCode.A then data.Move.A = true end
        if input.KeyCode == Enum.KeyCode.S then data.Move.S = true end
        if input.KeyCode == Enum.KeyCode.D then data.Move.D = true end
        if input.KeyCode == Enum.KeyCode.Space then data.Move.Space = true end
        if input.KeyCode == Enum.KeyCode.LeftShift then data.Move.Shift = true end
        if input.KeyCode == Enum.KeyCode.E then data.Speed = math.clamp((data.Speed or 80) + 10, 20, 300) end
        if input.KeyCode == Enum.KeyCode.Q then data.Speed = math.clamp((data.Speed or 80) - 10, 20, 300) end
    end))

    table.insert(data.Connections, UserInputService.InputEnded:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.W then data.Move.W = false end
        if input.KeyCode == Enum.KeyCode.A then data.Move.A = false end
        if input.KeyCode == Enum.KeyCode.S then data.Move.S = false end
        if input.KeyCode == Enum.KeyCode.D then data.Move.D = false end
        if input.KeyCode == Enum.KeyCode.Space then data.Move.Space = false end
        if input.KeyCode == Enum.KeyCode.LeftShift then data.Move.Shift = false end
    end))

    table.insert(data.Connections, RunService.RenderStepped:Connect(function()
        if not data.Enabled or not data.Velocity or not data.Gyro then return end
        if not root or not root.Parent then MiamiFlyCleanup() return end

        getgenv().SwimMethod = true

        local camera = workspace.CurrentCamera
        if not camera then return end

        data.Gyro.CFrame = camera.CFrame

        local direction = Vector3.zero
        if data.Move.W then direction += camera.CFrame.LookVector end
        if data.Move.S then direction -= camera.CFrame.LookVector end
        if data.Move.A then direction -= camera.CFrame.RightVector end
        if data.Move.D then direction += camera.CFrame.RightVector end
        if data.Move.Space then direction += Vector3.new(0, 1, 0) end
        if data.Move.Shift then direction -= Vector3.new(0, 1, 0) end

        if UserInputService.TouchEnabled and humanoid then
            direction += humanoid.MoveDirection
        end

        if direction.Magnitude > 0 then
            data.Velocity.Velocity = direction.Unit * (data.Speed or 80)
        else
            data.Velocity.Velocity = Vector3.zero
        end
    end))

    sendNotification("Fly", "Fly enabled. WASD + Space/Shift, Q/E changes speed.", 3)
end


function findHouseModels()
    local found = {}
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("Model") or v:IsA("Folder") then
            local n = v.Name:lower()
            if n:find("house") and not n:find("pent") and not n:find("ware") then
                if v:FindFirstChildWhichIsA("ProximityPrompt", true) then table.insert(found, v) end
            end
        end
    end
    table.sort(found, function(a,b) return a.Name:lower() < b.Name:lower() end)
    return found
end

function lootHouse(hf)
    if not hf then return end
    for _, item in pairs(hf:GetDescendants()) do
        if item:IsA("ProximityPrompt") and item.Enabled then
            local part = item.Parent
            if part and part:IsA("BasePart") then
                Config:Teleport(part.CFrame + Vector3.new(0,3,0)); task.wait(0.2)
                pcall(function() fireproximityprompt(item) end); task.wait(0.25)
            end
        end
    end
end

task.spawn(function()
    while task.wait(0.5) do
        if getgenv().AutoLootStudio then
            local sf = workspace:FindFirstChild("StudioPay") and workspace.StudioPay:FindFirstChild("Money")
            if sf then for _, m in pairs(sf:GetChildren()) do for _, part in pairs(m:GetChildren()) do
                if part:IsA("BasePart") then
                    local p = part:FindFirstChild("Prompt")
                    if p and p:IsA("ProximityPrompt") and p.Enabled then
                        Config:Teleport(part.CFrame+Vector3.new(0,3,0)); task.wait(0.2)
                        pcall(function() fireproximityprompt(p) end); task.wait(0.1)
                    end
                end
            end end end
        end
    end
end)

task.spawn(function()
    while task.wait(1) do
        if getgenv().AutoLootHouse1 or getgenv().AutoLootHouse2 then
            local h = findHouseModels()
            if getgenv().AutoLootHouse1 and h[1] then pcall(function() lootHouse(h[1]) end) end
            if getgenv().AutoLootHouse2 and h[2] then pcall(function() lootHouse(h[2]) end) end
        end
    end
end)

task.spawn(function()
    while task.wait(0.5) do
        if getgenv().AutoLootTrash then
            for _, v in pairs(workspace:GetDescendants()) do
                if v:IsA("Part") and (v.Name:lower():find("trash") or v.Name:lower():find("dumpster")) then
                    local p = v:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if p and p.Enabled then
                        Config:Teleport(v.CFrame+Vector3.new(0,3,0)); task.wait(0.3)
                        pcall(function() fireproximityprompt(p) end); task.wait(0.5)
                    end
                end
            end
        end
    end
end)

task.spawn(function()
    while task.wait(1) do
        if getgenv().AutoSellLoot then
            pcall(function()
                local pr = ReplicatedStorage:FindFirstChild("PawnRemote")
                if pr then for _, item in pairs(LocalPlayer.Backpack:GetChildren()) do pr:FireServer(item.Name) end end
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(0.5) do
        if getgenv().AutoRobBank then
            pcall(function()
                for _, v in pairs(workspace:GetDescendants()) do
                    if v:IsA("ProximityPrompt") and v.Enabled and (v.ActionText:lower():find("rob") or v.ActionText:lower():find("crack") or v.ActionText:lower():find("drill")) then
                        Config:Teleport(v.Parent.CFrame+Vector3.new(0,3,0)); task.wait(0.2)
                        fireproximityprompt(v); task.wait(0.3)
                    end
                end
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(0.5) do
        if getgenv().AutoRobStore then
            pcall(function()
                local sel = Toggles.TargetStoreSelect and Toggles.TargetStoreSelect.Value or "Store1"
                local sm = workspace:FindFirstChild(sel) or (workspace:FindFirstChild("Stores") and workspace.Stores:FindFirstChild(sel))
                if sm then
                    for _, v in pairs(sm:GetDescendants()) do
                        if v:IsA("ProximityPrompt") and v.Enabled and (v.ActionText:lower():find("rob") or v.ActionText:lower():find("steal") or v.ActionText:lower():find("register")) then
                            Config:Teleport(v.Parent.CFrame+Vector3.new(0,3,0)); task.wait(0.2)
                            fireproximityprompt(v); task.wait(0.3)
                        end
                    end
                end
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(1) do
        if AutoStealLootbags then
            local st = workspace:FindFirstChild("Storage")
            if st then
                for _, item in ipairs(st:GetChildren()) do
                    if not AutoStealLootbags then break end
                    local pr = item:FindFirstChild("stealprompt", true)
                    if pr and pr:IsA("ProximityPrompt") and pr.Enabled then
                        local ch = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                        local root = ch:FindFirstChild("HumanoidRootPart"); if not root then break end
                        local old = root.CFrame
                        getgenv().SwimMethod = true; task.wait(0.3)
                        local tp = pr.Parent:IsA("BasePart") and pr.Parent or item:FindFirstChildWhichIsA("BasePart", true)
                        if not tp then break end
                        Config:Teleport(tp.CFrame+Vector3.new(0,2,0)); task.wait(0.3)
                        fireproximityprompt(pr); task.wait(0.3)
                        Config:Teleport(old); task.wait(0.5)
                        getgenv().SwimMethod = false
                    end
                end
            end
        end
    end
end)

task.spawn(function()
    while task.wait(1) do
        if AutoGrabMoney then
            local d = workspace:FindFirstChild("Dollas")
            if d then for _, item in ipairs(d:GetChildren()) do
                if not AutoGrabMoney then break end
                if (item.Name=="DeadMoney" or item.Name=="Money") and item:IsA("BasePart") then
                    local pr = item:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if pr and pr.Enabled then
                        local ch = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                        local root = ch:FindFirstChild("HumanoidRootPart"); if not root then break end
                        local old = root.CFrame
                        getgenv().SwimMethod = true; task.wait(0.3)
                        Config:Teleport(item.CFrame+Vector3.new(0,2,0)); task.wait(0.3)
                        fireproximityprompt(pr); task.wait(0.3)
                        Config:Teleport(old); task.wait(0.5); getgenv().SwimMethod = false
                    end
                end
            end end
        end
        if AutoPickupBags and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local st = workspace:FindFirstChild("Storage")
            if st then
                for _, v in next, st:GetChildren() do
                    if v:IsA("MeshPart") then
                        if v:FindFirstChild("PlayerName") and v.PlayerName.Value == LocalPlayer.Name then break end
                        if (v.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude < 5 then
                            local p = v:FindFirstChild("stealprompt")
                            if p and p:IsA("ProximityPrompt") then pcall(function() fireproximityprompt(p) end) end
                        end
                    end
                end
            end
        end
        if DisableBloodEffects and LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("BloodGui") then
            LocalPlayer.PlayerGui.BloodGui.Enabled = false
        end
    end
end)

task.spawn(function()
    local VU = game:GetService("VirtualUser")
    while true do
        task.wait(1200)
        if getgenv().AntiAFKEnabled then pcall(function() VU:CaptureController(); VU:ClickButton2(Vector2.new()) end) end
    end
end)




dupeBlacklist = {
    ["Fists"]=true, ["Fist"]=true, ["Phone"]=true, ["Car Keys"]=true,
    ["Car keys"]=true, ["Bandage"]=true, ["762s"]=true, ["556s"]=true,
    ["Extended"]=true, ["T shirt"]=true, ["Combat"]=true, ["Weight"]=true,
    ["Shiesty"]=true, ["Lemonade"]=true,
}

function ShowBigAlert(msg)
    local coreGui = (gethui and gethui()) or game:GetService("CoreGui")
    local sg = Instance.new("ScreenGui")
    sg.Name = "MiamiBigAlert_" .. tostring(math.random(10000, 99999))
    sg.IgnoreGuiInset = true
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Global
    sg.DisplayOrder = 99999
    sg.Parent = coreGui
    local txt = Instance.new("TextLabel", sg)
    txt.Size = UDim2.new(1, 0, 0, 100)
    txt.Position = UDim2.new(0, 0, 0.2, 0)
    txt.BackgroundTransparency = 1
    txt.Text = msg
    txt.TextColor3 = Color3.fromRGB(255, 50, 50)
    txt.Font = Enum.Font.GothamBlack
    txt.TextSize = 32
    txt.TextStrokeTransparency = 0
    txt.TextStrokeColor3 = Color3.new(0,0,0)
    txt.TextTransparency = 1
    task.spawn(function()
        for i = 1, 10 do txt.TextTransparency = txt.TextTransparency - 0.1; task.wait(0.03) end
        task.wait(2)
        for i = 1, 10 do txt.TextTransparency = txt.TextTransparency + 0.1; txt.Position = txt.Position - UDim2.new(0, 0, 0.01, 0); task.wait(0.03) end
        sg:Destroy()
    end)
end

function SilentBypassTeleport(targetCFrame)
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root then return end
    if hum then hum:ChangeState(0) end
    local sWait = tick()
    repeat task.wait() until not LocalPlayer:GetAttribute("LastACPos") or (tick() - sWait > 1)
    root.CFrame = targetCFrame
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    task.wait(0.5)
    if hum then hum:ChangeState(Enum.HumanoidStateType.GettingUp) end
end

function GetActiveSafe()
    
    
    
    local function isMine(owner)
        if not owner then return false end
        if owner:IsA("ObjectValue") then
            return owner.Value == LocalPlayer
        end
        local value = tostring(owner.Value or "")
        return value == LocalPlayer.Name or value == LocalPlayer.DisplayName
    end

    local function findOwnedHouseAndSafe()
        for _, owner in ipairs(workspace:GetDescendants()) do
            if (owner.Name:lower() == "owner")
                and (owner:IsA("StringValue") or owner:IsA("ObjectValue"))
                and isMine(owner) then

                
                local ancestor = owner.Parent
                while ancestor and ancestor ~= workspace do
                    local safe = ancestor:FindFirstChild("Safe", true)
                    if safe then
                        return ancestor, safe
                    end
                    ancestor = ancestor.Parent
                end
            end
        end
        return nil, nil
    end

    local house, mySafe = findOwnedHouseAndSafe()
    if not mySafe then return nil, nil, nil end

    local safePart
    if mySafe:IsA("BasePart") then
        safePart = mySafe
    else
        safePart = mySafe:FindFirstChild("Union", true)
            or mySafe:FindFirstChildWhichIsA("BasePart", true)
    end
    local safeCF = safePart and safePart.CFrame or nil

    
    return mySafe, nil, safeCF
end

function GetSafeItems()
    local items = {}
    local invData = LocalPlayer:FindFirstChild("InvData")
    if invData then for _, c in ipairs(invData:GetChildren()) do table.insert(items, c.Name) end end
    table.sort(items); return items
end

function GetAllBackpackItems()
    local items = {}
    local char = LocalPlayer.Character
    local bp   = LocalPlayer:FindFirstChild("Backpack")
    if char then for _, t in pairs(char:GetChildren()) do
        if t:IsA("Tool") and not dupeBlacklist[t.Name] and not table.find(items, t.Name) then table.insert(items, t.Name) end
    end end
    if bp then for _, t in pairs(bp:GetChildren()) do
        if t:IsA("Tool") and not dupeBlacklist[t.Name] and not table.find(items, t.Name) then table.insert(items, t.Name) end
    end end
    table.sort(items); return items
end

function GetLockedTools()
    local tools = {}
    if LocalPlayer:FindFirstChild("Backpack") then
        for _, t in pairs(LocalPlayer.Backpack:GetChildren()) do
            if t:IsA("Tool") and not dupeBlacklist[t.Name] then table.insert(tools, t.Name) end
        end
    end
    return tools
end

function FirePromptsInArea(range, nameFilter)
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return 0 end
    local fired = 0
    local filter = nameFilter and tostring(nameFilter):lower() or nil

    for _, prompt in ipairs(workspace:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") and prompt.Enabled then
            local parent = prompt.Parent
            local part = parent and (parent:IsA("BasePart") and parent or parent:FindFirstChildWhichIsA("BasePart", true))
            local pPos = part and part.Position
            if pPos and (pPos - root.Position).Magnitude < range then
                
                
                
                local text = (tostring(prompt.Name) .. " " .. tostring(prompt.ActionText) .. " " .. tostring(prompt.ObjectText)):lower()
                local ancestor = parent
                for _ = 1, 5 do
                    if not ancestor then break end
                    text = text .. " " .. tostring(ancestor.Name):lower()
                    ancestor = ancestor.Parent
                end

                if not filter or text:find(filter, 1, true) then
                    local oldHold = prompt.HoldDuration
                    local oldLOS = prompt.RequiresLineOfSight
                    pcall(function()
                        prompt.HoldDuration = 0
                        prompt.RequiresLineOfSight = false
                        fireproximityprompt(prompt)
                    end)
                    pcall(function()
                        prompt.HoldDuration = oldHold
                        prompt.RequiresLineOfSight = oldLOS
                    end)
                    fired = fired + 1
                end
            end
        end
    end
    return fired
end

function OpenOwnedSafe(SafeFolder, safeCF)
    if not SafeFolder or not safeCF then return false, "Safe or safe position was not found" end
    SilentBypassTeleport(safeCF * CFrame.new(0, 2, 0))
    task.wait(0.45)

    local fired = 0
    for _, prompt in ipairs(SafeFolder:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") and prompt.Enabled then
            local oldHold = prompt.HoldDuration
            local oldLOS = prompt.RequiresLineOfSight
            local ok = pcall(function()
                prompt.HoldDuration = 0
                prompt.RequiresLineOfSight = false
                fireproximityprompt(prompt)
            end)
            pcall(function()
                prompt.HoldDuration = oldHold
                prompt.RequiresLineOfSight = oldLOS
            end)
            if ok then fired = fired + 1 end
        end
    end

    
    if fired == 0 then
        fired = FirePromptsInArea(18, "safe")
    end
    if fired == 0 then
        
        fired = FirePromptsInArea(7)
    end
    return fired > 0, fired > 0 and nil or "No enabled safe prompt was found"
end

function TakeFromSafe(itemName)
    InventoryRemote = InventoryRemote or ReplicatedStorage:FindFirstChild("Inventory")
    local SafeFolder, rentCF, safeCF = GetActiveSafe()
    if not SafeFolder or not safeCF then ShowBigAlert("You must own a house to dupe!"); return false end
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return false end
    local origLoc = root.CFrame
    local success = false
    pcall(function()
        SilentBypassTeleport(safeCF * CFrame.new(0, 2, 0))
        task.wait(0.3)
        InventoryRemote:FireServer("Change", itemName, "Inv", SafeFolder)
        task.wait(0.5)
        SilentBypassTeleport(origLoc)
        task.wait(0.5)
        success = true
    end)
    return success
end

function StoreHoldingItem()
    local char = LocalPlayer.Character; if not char then return end
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then sendNotification("Safe","Hold an item first!"); return end
    local SafeFolder, rentCF, safeCF = GetActiveSafe()
    if not SafeFolder or not safeCF then ShowBigAlert("You must own a house to dupe!"); return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local origLoc = root.CFrame
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then hum:UnequipTools() end
    task.wait(0.2)
    SilentBypassTeleport(safeCF * CFrame.new(0, 2, 0))
    task.wait(0.3)
    BackpackRemote:InvokeServer("Store", tool.Name)
    InventoryRemote:FireServer("Change", tool.Name, "Backpack", SafeFolder)
    task.wait(0.5)
    SilentBypassTeleport(origLoc)
    task.wait(0.5)
    sendNotification("Safe","Stored " .. tool.Name)
end

function SafeDupeOnce(itemName, returnCFrame)
    local SafeFolder, rentCF, safeCF = GetActiveSafe()
    if not SafeFolder or not safeCF then ShowBigAlert("You must own a house to dupe!"); return false end
    pcall(function()
        SilentBypassTeleport(safeCF * CFrame.new(0, 2, 0))
        task.wait(0.3)
        task.spawn(function() BackpackRemote:InvokeServer("Store", itemName) end)
        task.spawn(function() InventoryRemote:FireServer("Change", itemName, "Backpack", SafeFolder) end)
        task.wait(0.6)
        SilentBypassTeleport(returnCFrame)
        task.wait(1.2)
        BackpackRemote:InvokeServer("Grab", itemName)
        task.wait(0.5)
    end)
    return true
end

autoDupeActive = false
dupeSpeed      = 15
dupeCounter    = 0
selectedDupeItem = nil

function DoDupe(targetSpeed)
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then sendNotification("Dupe","No character!"); return end
    local origLoc = root.CFrame
    autoDupeActive = true
    sendNotification("Dupe","Starting safe dupe...")

    if not selectedDupeItem or selectedDupeItem == "None" or selectedDupeItem == "(All locked tools)" then
        local locked = GetLockedTools()
        if #locked == 0 then autoDupeActive = false; sendNotification("Dupe","No tools in backpack."); return end
        task.spawn(function()
            local SafeFolder, rentCF, safeCF = GetActiveSafe()
            if not SafeFolder then ShowBigAlert("You must own a house to dupe!"); autoDupeActive = false; return end
            if safeCF then sendNotification("Dupe","Opening Safe..."); SilentBypassTeleport(safeCF * CFrame.new(0,2,0)); task.wait(0.7); FirePromptsInArea(15, "Safe") end
            sendNotification("Dupe","Returning..."); SilentBypassTeleport(origLoc); task.wait(0.5)
            
            local i = 1
            while autoDupeActive and (targetSpeed == math.huge or i <= targetSpeed) do
                local idx = ((i-1) % #locked) + 1
                SafeDupeOnce(locked[idx], origLoc)
                dupeCounter = dupeCounter + 1
                task.wait(0.2)
                i = i + 1
            end
            autoDupeActive = false
            sendNotification("Dupe","Auto Dupe Stopped. Total: " .. dupeCounter)
        end)
    else
        task.spawn(function()
            sendNotification("Dupe","Grabbing " .. selectedDupeItem .. "...")
            local backpackRemoteSafe = ReplicatedStorage:FindFirstChild("BackpackRemote")
            if backpackRemoteSafe then backpackRemoteSafe:InvokeServer("Grab", selectedDupeItem) end
            task.wait(0.5)
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then hum:UnequipTools() end
            task.wait(0.3)
            local SafeFolder, rentCF, safeCF = GetActiveSafe()
            if not SafeFolder then ShowBigAlert("You must own a house to dupe!"); autoDupeActive = false; return end
            if safeCF then sendNotification("Dupe","Opening Safe..."); SilentBypassTeleport(safeCF * CFrame.new(0,2,0)); task.wait(0.7); FirePromptsInArea(15, "Safe") end
            sendNotification("Dupe","Returning..."); SilentBypassTeleport(origLoc); task.wait(0.5)
            
            local i = 1
            while autoDupeActive and (targetSpeed == math.huge or i <= targetSpeed) do
                SafeDupeOnce(selectedDupeItem, origLoc)
                dupeCounter = dupeCounter + 1
                task.wait(0.2)
                i = i + 1
            end
            autoDupeActive = false
            sendNotification("Dupe","Auto Dupe Stopped. Total: " .. dupeCounter)
        end)
    end
end

function SafeTP()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then sendNotification("Safe TP", "No character!"); return end
    sendNotification("Safe TP", "Finding your owned safe...")

    task.spawn(function()
        local ok, err = pcall(function()
            local SafeFolder, rentCF, safeCF = GetActiveSafe()
            if not SafeFolder or not safeCF then
                ShowBigAlert("Could not find your owned house safe!")
                sendNotification("Safe TP", "Owned safe not found. Check the Owner value.")
                return
            end

            
            
            local opened, reason = OpenOwnedSafe(SafeFolder, safeCF)
            if opened then
                sendNotification("Safe TP", "Safe prompt fired successfully.")
            else
                sendNotification("Safe TP", tostring(reason or "Failed to open safe"))
            end
        end)
        if not ok then
            warn("[Miami/Sament SafeTP Error] " .. tostring(err))
            sendNotification("Safe TP Error", tostring(err))
        end
    end)
end

autoDropEnabled = false
function ToggleAutoDrop(state)
    local dropRemote = ReplicatedStorage:FindFirstChild("DropItemRemote")
    autoDropEnabled = state
    sendNotification("Auto Drop", state and "Started" or "Stopped")
    if state then
        task.spawn(function()
            while autoDropEnabled do
                local bp = LocalPlayer:FindFirstChild("Backpack")
                local ch = LocalPlayer.Character
                if not bp or not ch then task.wait(0.5)
                else
                    local found = false
                    for _, item in ipairs(bp:GetChildren()) do
                        if not autoDropEnabled then break end
                        if item:IsA("Tool") and not dupeBlacklist[item.Name] then
                            found = true
                            local hum = ch:FindFirstChildOfClass("Humanoid")
                            if hum then
                                hum:EquipTool(item)
                                local dt = tick()
                                repeat
                                    if dropRemote then
                                        pcall(function() dropRemote:FireServer(item.Name) end)
                                        pcall(function() dropRemote:FireServer(item) end)
                                        pcall(function() dropRemote:FireServer() end)
                                    end
                                    task.wait(0.2)
                                until not item:IsDescendantOf(ch) or not autoDropEnabled or (tick() - dt > 3)
                                task.wait(0.1)
                            end
                        end
                    end
                    if not found then task.wait(1) end
                end
                task.wait(0.1)
            end
        end)
    end
end

DeathMarket = DeathMarket or {
    Running = false,
    ListedCharacter = nil,
    Snapshot = {},
    Price = 99999,
}

function IsDeathMarketGun(item)
    
    
    
    
    return item ~= nil
        and item:IsA("Tool")
        and not dupeBlacklist[item.Name]
end

function SnapshotDeathMarketGuns(character)
    local snapshot = {}
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    for _, container in ipairs({character, backpack}) do
        if container then
            for _, item in ipairs(container:GetChildren()) do
                if IsDeathMarketGun(item) then
                    table.insert(snapshot, item.Name)
                end
            end
        end
    end
    DeathMarket.Snapshot = snapshot
    return snapshot
end

function CountOwnedDeathMarketListings(gunName)
    local market = ReplicatedStorage:FindFirstChild("MarketItems")
    if not market then return 0 end
    local count = 0
    for _, item in ipairs(market:GetChildren()) do
        local owner = item:FindFirstChild("owner")
        if item.Name == gunName and owner and owner.Value == LocalPlayer.Name then
            count = count + 1
        end
    end
    return count
end

function FindDeathMarketTool(gunName)
    local character = LocalPlayer.Character
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    local tool = character and character:FindFirstChild(gunName)
    if tool and tool:IsA("Tool") then return tool end
    tool = backpack and backpack:FindFirstChild(gunName)
    if tool and tool:IsA("Tool") then return tool end
    return nil
end

function WaitForDeathMarketCharacter(timeout)
    local deadline = os.clock() + (timeout or 20)
    repeat
        local character = LocalPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if character and humanoid and root and humanoid.Health > 0 then
            return character, humanoid
        end
        task.wait(0.2)
    until os.clock() >= deadline
    return nil, nil
end

function PutGunsOnMarketWhenDead(character)
    if not KeepToolsOnDeath or DeathMarket.Running then return false end
    if not character or DeathMarket.ListedCharacter == character then return false end

    local listRemote = ReplicatedStorage:FindFirstChild("ListWeaponRemote")
    local backpackRemote = ReplicatedStorage:FindFirstChild("BackpackRemote")
    if not listRemote then
        sendNotification("Death Market", "ListWeaponRemote was not found.")
        return false
    end

    DeathMarket.Running = true
    DeathMarket.ListedCharacter = character

    local previousSnapshot = table.clone(DeathMarket.Snapshot or {})
    local gunNames = SnapshotDeathMarketGuns(character)
    if #gunNames == 0 then gunNames = previousSnapshot end

    
    
    local wanted, baseline = {}, {}
    for _, gunName in ipairs(gunNames) do
        wanted[gunName] = (wanted[gunName] or 0) + 1
    end
    for gunName in pairs(wanted) do
        baseline[gunName] = CountOwnedDeathMarketListings(gunName)
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then pcall(function() humanoid:UnequipTools() end) end

    
    if gunNames[1] then
        pcall(function() listRemote:FireServer(gunNames[1], DeathMarket.Price) end)
    end

    task.spawn(function()
        
        
        local _, liveHumanoid = WaitForDeathMarketCharacter(25)
        local listed = 0

        if liveHumanoid then
            for gunName, amount in pairs(wanted) do
                local targetCount = (baseline[gunName] or 0) + amount
                local attempts = 0

                while KeepToolsOnDeath
                    and CountOwnedDeathMarketListings(gunName) < targetCount
                    and attempts < (amount * 4 + 4) do

                    attempts = attempts + 1
                    local tool = FindDeathMarketTool(gunName)

                    if not tool and backpackRemote then
                        pcall(function() backpackRemote:InvokeServer("Grab", gunName) end)
                        task.wait(0.35)
                        tool = FindDeathMarketTool(gunName)
                    end

                    if tool then
                        local currentCharacter = LocalPlayer.Character
                        liveHumanoid = currentCharacter and currentCharacter:FindFirstChildOfClass("Humanoid")
                        if liveHumanoid and tool.Parent ~= currentCharacter then
                            pcall(function() liveHumanoid:EquipTool(tool) end)
                            task.wait(0.2)
                        end
                    end

                    local before = CountOwnedDeathMarketListings(gunName)
                    pcall(function() listRemote:FireServer(gunName, DeathMarket.Price) end)

                    local deadline = os.clock() + 2.5
                    repeat task.wait(0.1)
                    until CountOwnedDeathMarketListings(gunName) > before or os.clock() >= deadline

                    if CountOwnedDeathMarketListings(gunName) > before then
                        listed = listed + 1
                    end
                    task.wait(0.25)
                end
            end
        end

        local totalListed = 0
        for gunName, amount in pairs(wanted) do
            local gained = CountOwnedDeathMarketListings(gunName) - (baseline[gunName] or 0)
            totalListed = totalListed + math.clamp(gained, 0, amount)
        end

        DeathMarket.Running = false
        sendNotification(
            "Death Market",
            "Finished market queue: " .. tostring(totalListed) .. "/" .. tostring(#gunNames) .. " gun(s) listed."
        )
    end)

    sendNotification("Death Market", "Death detected — queued all " .. tostring(#gunNames) .. " guns.")
    return true
end

function BindDeathMarketCharacter(character)
    DeathMarket.Running = false
    DeathMarket.ListedCharacter = nil
    DeathMarket.Snapshot = {}

    local humanoid = character:WaitForChild("Humanoid", 10)
    local backpack = LocalPlayer:WaitForChild("Backpack", 10)
    if not humanoid or not backpack then return end

    local function refreshSnapshot()
        if character == LocalPlayer.Character then
            SnapshotDeathMarketGuns(character)
        end
    end

    character.ChildAdded:Connect(refreshSnapshot)
    character.ChildRemoved:Connect(refreshSnapshot)
    backpack.ChildAdded:Connect(refreshSnapshot)
    backpack.ChildRemoved:Connect(refreshSnapshot)
    refreshSnapshot()

    humanoid.Died:Connect(function()
        if KeepToolsOnDeath then
            PutGunsOnMarketWhenDead(character)
        end
    end)
end

if LocalPlayer.Character then task.defer(BindDeathMarketCharacter, LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(BindDeathMarketCharacter)

function loadSafeTabFunctions()
    
    local SafeSection = Tabs["Safe/Dupe"]:AddLeftGroupbox("Safe")

    local safeItems = GetSafeItems()
    if #safeItems == 0 then safeItems = { "(empty - press Refresh)" } end
    local selectedSafeItem = safeItems[1]

    local safeDropdown = SafeSection:AddDropdown("SafeSelectedItem", {
        Text = "Select Safe Item",
        Values = safeItems,
        Default = selectedSafeItem,
        Callback = function(v) selectedSafeItem = normalizeDropdownValue(v) end,
    })

    SafeSection:AddButton("Refresh Safe List", function()
        local items = GetSafeItems()
        if #items == 0 then items = { "(empty)" } end
        if safeDropdown then
            pcall(function() safeDropdown:SetValues(items) end)
        end
        selectedSafeItem = items[1]
        sendNotification("Safe", "Refreshed: " .. #items .. " items")
    end)

    -- take just the item picked in the dropdown out of the safe
    local safeTakeBusy = false
    SafeSection:AddButton("Take Selected Item", function()
        local item = selectedSafeItem
        if type(item) ~= "string" or item == "" or item:sub(1, 1) == "(" then
            sendNotification("Safe", "Pick an item in 'Select Safe Item' first.")
            return
        end
        if safeTakeBusy then
            sendNotification("Safe", "Already taking an item, please wait.")
            return
        end
        safeTakeBusy = true
        task.spawn(function()
            local ok = TakeFromSafe(item)
            safeTakeBusy = false
            sendNotification("Safe", ok and ("Took " .. item .. " out of the safe.") or ("Could not take " .. item .. "."))
        end)
    end)

    -- keep the dropdown in sync with your inventory (items added / removed)
    do
        local invData = LocalPlayer:FindFirstChild("InvData")
        local syncQueued = false
        local function syncSafeList()
            if syncQueued then return end
            syncQueued = true
            task.delay(0.25, function()
                syncQueued = false
                local items = GetSafeItems()
                if #items == 0 then items = { "(empty)" } end
                if safeDropdown then pcall(function() safeDropdown:SetValues(items) end) end
                if not table.find(items, selectedSafeItem) then selectedSafeItem = items[1] end
            end)
        end
        if invData then
            invData.ChildAdded:Connect(syncSafeList)
            invData.ChildRemoved:Connect(syncSafeList)
        end
    end

    local safeTakeAllActive = false
    SafeSection:AddButton("Take All", function()
        if safeTakeAllActive then
            sendNotification("Safe", "Take All is already running.")
            return
        end
        local items = GetSafeItems()
        if #items == 0 then sendNotification("Safe","Safe is empty."); return end
        safeTakeAllActive = true
        task.spawn(function()
            sendNotification("Safe","Taking all "..#items.." items...")
            local taken = 0
            for _, n in ipairs(items) do
                if not safeTakeAllActive then break end
                if TakeFromSafe(n) then taken = taken + 1 end
                task.wait(0.5)
            end
            local stopped = not safeTakeAllActive
            safeTakeAllActive = false
            if stopped then
                sendNotification("Safe", "Take All stopped after " .. taken .. " item(s).")
            else
                sendNotification("Safe", "Took " .. taken .. "/" .. #items .. " items.")
            end
        end)
    end)

    SafeSection:AddButton("⏹ Stop Take All", function()
        if safeTakeAllActive then
            safeTakeAllActive = false
            sendNotification("Safe", "Stop requested — finishing the current item.")
        else
            sendNotification("Safe", "Take All is not running.")
        end
    end)

    
    local DupeSection = Tabs["Safe/Dupe"]:AddLeftGroupbox("Safe Dupe")

    local dupeItems = GetLockedTools()
    table.insert(dupeItems, 1, "None")

    local dupeDropdown = DupeSection:AddDropdown("DupeSelectedItem", {
        Text = "Select Item",
        Values = dupeItems,
        Default = "None",
        Callback = function(v)
            local pick = normalizeDropdownValue(v)
            if pick == "None" or pick == "" then
                selectedDupeItem = nil
            else
                selectedDupeItem = pick
            end
        end,
    })

    DupeSection:AddButton("Refresh Items", function()
        local items = GetLockedTools()
        local list = {"None"}
        for _, t in ipairs(items) do table.insert(list, t) end
        if dupeDropdown then
            pcall(function() dupeDropdown:SetValues(list) end)
        end
        selectedDupeItem = nil
        sendNotification("Dupe","Refreshed item list: " .. (#list - 1) .. " tools")
    end)

    local customDupeAmount = 1
    DupeSection:AddSlider("CustomSafeDupeAmount", {
        Text = "Custom Dupe Amount",
        Min = 1,
        Max = 15,
        Default = 1,
        Rounding = 0,
        Callback = function(value)
            customDupeAmount = math.clamp(math.floor(tonumber(value) or 1), 1, 15)
        end,
    })

    DupeSection:AddButton("Run Custom Safe Dupe", function()
        if not autoDupeActive then
            DoDupe(customDupeAmount)
        else
            sendNotification("Dupe", "Dupe is currently running!")
        end
    end)

    DupeSection:AddButton("Safe Dupe 15 Times", function()
        if not autoDupeActive then
            DoDupe(15)
        else
            sendNotification("Dupe","Dupe is currently running!")
        end
    end)

    DupeSection:AddButton("⏹ Stop Safe Dupe", function()
        if autoDupeActive then
            autoDupeActive = false
            sendNotification("Dupe", "Stop requested — the current cycle will finish, then duping will stop.")
        else
            sendNotification("Dupe", "No dupe process is currently running.")
        end
    end)

    DupeSection:AddToggle("AutoSafeDupeToggle", {
        Text = "Auto Safe Dupe (Infinite)",
        Default = false,
        Callback = function(state)
            if state then
                if not autoDupeActive then
                    DoDupe(math.huge)
                end
            else
                if autoDupeActive then
                    autoDupeActive = false
                    sendNotification("Dupe","Stopped")
                end
            end
        end
    })

    DupeSection:AddButton("Safe TP", function() SafeTP() end)

    DupeSection:AddToggle("SafeAutoDrop", {
        Text = "Auto Drop Tools",
        Default = false,
        Callback = function(s) ToggleAutoDrop(s) end
    })

    
    local SafeInfo = Tabs["Safe/Dupe"]:AddRightGroupbox("Info / Status")
    local safeStatusLabel  = SafeInfo:AddLabel("Safe Status: Ready")
    local itemCountLabel   = SafeInfo:AddLabel("Items in Safe: ?")
    local dupeCounterLabel = SafeInfo:AddLabel("Total Duped: 0")
    local dupeActiveLabel  = SafeInfo:AddLabel("Dupe: IDLE")

    task.spawn(function()
        while task.wait(5) do
            local n = #GetSafeItems()
            pcall(function() itemCountLabel:SetText("Items in Safe: " .. n) end)
            local SafeFolder = GetActiveSafe()
            pcall(function() safeStatusLabel:SetText("Safe Status: " .. (SafeFolder and "Found " or "Not Found ")) end)
            pcall(function() dupeCounterLabel:SetText("Total Duped: " .. dupeCounter) end)
            pcall(function() dupeActiveLabel:SetText("Dupe: " .. (autoDupeActive and "RUNNING " or "IDLE")) end)
        end
    end)

end


loadMiamiUtilitySections = nil

do
    loadMiamiUtilitySections = function()
        local function qbFindPrompt(obj)
            if not obj then return nil end
            if obj:IsA("ProximityPrompt") then return obj end
            for _, child in ipairs(obj:GetChildren()) do
                local found = qbFindPrompt(child)
                if found then return found end
            end
            return nil
        end

        local function getObjectCFrame(obj)
            if not obj then return nil end
            if obj:IsA("BasePart") then return obj.CFrame end
            if obj:IsA("Model") then
                if obj.PrimaryPart then return obj.PrimaryPart.CFrame end
                local part = obj:FindFirstChildWhichIsA("BasePart", true)
                if part then return part.CFrame end
                local ok, pivot = pcall(function() return obj:GetPivot() end)
                if ok then return pivot end
            end
            local parent = obj.Parent
            if parent and parent:IsA("BasePart") then return parent.CFrame end
            if parent and parent:IsA("Model") then
                if parent.PrimaryPart then return parent.PrimaryPart.CFrame end
                local part = parent:FindFirstChildWhichIsA("BasePart", true)
                if part then return part.CFrame end
            end
            return nil
        end

        local function qbDoBuy(itemName, category)
            if not itemName or itemName == "(no matches)" then return false, "No item selected" end
            local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            local hrp = char:FindFirstChild("HumanoidRootPart") or char:WaitForChild("HumanoidRootPart", 5)
            if not hrp then return false, "No HumanoidRootPart" end

            if category == "OTHER" or category == "BAGS" then
                local itemObject = workspace:FindFirstChild("GUNS") and workspace.GUNS:FindFirstChild(itemName) or nil
                if not itemObject and category == "BAGS" then
                    
                    
                    itemObject = workspace:FindFirstChild(itemName, true)
                end
                if not itemObject then return false, "World item not found: " .. tostring(itemName) end

                local prompt = qbFindPrompt(itemObject)
                local targetCF = getObjectCFrame(prompt and prompt.Parent or itemObject)
                if not prompt or not targetCF then return false, "Prompt not found" end

                local originalCF = hrp.CFrame
                local holdDuration = prompt.HoldDuration
                pcall(function()
                    Config:Teleport(targetCF)
                    task.wait(0.35)
                    prompt.HoldDuration = 0
                    fireproximityprompt(prompt)
                    task.wait(0.2)
                    prompt.HoldDuration = holdDuration
                    Config:Teleport(originalCF)
                end)
                return true
            elseif category == "EXOTIC" then
                ReplicatedStorage:WaitForChild("ExoticShopRemote"):InvokeServer(itemName)
                return true
            elseif category == "MAIN SHOP" then
                ReplicatedStorage:WaitForChild("ShopRemote"):InvokeServer(itemName)
                return true
            end
            return false, "Unknown category"
        end

        local hiddenUiBlacklist = {
            ["Dead"] = true, ["Settings1"] = true, ["Controls"] = true, ["FirstShopGUI"] = true,
            ["Freecam"] = true, ["ThaShop2"] = true, ["WATCH GUI"] = true, ["NYPD Cars"] = true,
            ["CONSTRUCTION LEVEL"] = true, ["RobPlayerUI"] = true, ["Bronx LOCKER"] = true,
            ["MobileBeam"] = true, ["Settings"] = true, ["Flash"] = true, ["Enter"] = true,
            ["CopSirens"] = true,
        }

        local function getHiddenUiNames()
            local names = {"ATM GUI"}
            if LocalPlayer:FindFirstChild("PlayerGui") then
                for _, gui in ipairs(LocalPlayer.PlayerGui:GetChildren()) do
                    if gui:IsA("ScreenGui") and not gui.Enabled and not hiddenUiBlacklist[gui.Name] then
                        table.insert(names, gui.Name)
                    end
                end
            end
            table.sort(names, function(a, b)
                if a == "ATM GUI" then return true end
                if b == "ATM GUI" then return false end
                return tostring(a):lower() < tostring(b):lower()
            end)
            return names
        end

        local function toggleHiddenInterface(selectedUIName, state)
            if not selectedUIName or selectedUIName == "" then return end
            if selectedUIName == "ATM GUI" then
                local selectedUI = LocalPlayer.PlayerGui and LocalPlayer.PlayerGui:FindFirstChild("ATMGui")
                if state then
                    if not selectedUI then
                        local assets = Lighting:FindFirstChild("Assets")
                        local guiFolder = assets and assets:FindFirstChild("GUI")
                        local atmGui = guiFolder and guiFolder:FindFirstChild("ATMGui")
                        if atmGui then
                            local clone = atmGui:Clone()
                            clone.Parent = LocalPlayer.PlayerGui
                        else
                            sendNotification("UI", "ATM GUI asset not found")
                        end
                    end
                else
                    if selectedUI then selectedUI:Destroy() end
                end
            else
                local selectedUI = LocalPlayer.PlayerGui and LocalPlayer.PlayerGui:FindFirstChild(selectedUIName)
                if selectedUI and selectedUI:IsA("ScreenGui") then
                    selectedUI.Enabled = state
                end
            end
        end

        local QuickBuyGroup = Tabs.Player:AddRightGroupbox("Quick Buy")

        local function buyQuickItem(buttonName, itemName, category)
            task.spawn(function()
                local callOK, bought, problem = pcall(qbDoBuy, itemName, category)
                if callOK and bought then
                    sendNotification("Quick Buy", buttonName .. " purchased")
                else
                    local message = callOK and problem or bought
                    sendNotification("Quick Buy", "Failed to buy " .. buttonName .. ": " .. tostring(message or "unknown error"))
                end
            end)
        end

        QuickBuyGroup:AddButton("Buy BagElite", function()
            buyQuickItem("BagElite", "BagElite", "BAGS")
        end)

        QuickBuyGroup:AddButton("Buy Draco", function()
            buyQuickItem("Draco", "Draco", "OTHER")
        end)

        QuickBuyGroup:AddButton("Buy Shiesty", function()
            buyQuickItem("Shiesty", "Shiesty", "MAIN SHOP")
        end)

        QuickBuyGroup:AddButton("Buy Lemonade", function()
            buyQuickItem("Lemonade", "Lemonade", "EXOTIC")
        end)

        QuickBuyGroup:AddButton("Buy Bandage", function()
            buyQuickItem("Bandage", "Bandage", "EXOTIC")
        end)

        
        local UIUtilitiesGroup = Tabs.Player:AddRightGroupbox("User Interface Utilities")
        local hiddenUiNames = getHiddenUiNames()
        if #hiddenUiNames == 0 then hiddenUiNames = {"ATM GUI"} end

        local selectedUIName = hiddenUiNames[1] or "ATM GUI"
        local activeUIName = nil
        local interfaceToggle = nil

        local function setSelectedInterfaceEnabled(state)
            if state then
                if not selectedUIName or selectedUIName == "" then
                    sendNotification("Interface", "Select an interface first.")
                    return false
                end

                if activeUIName and activeUIName ~= selectedUIName then
                    toggleHiddenInterface(activeUIName, false)
                end

                toggleHiddenInterface(selectedUIName, true)
                activeUIName = selectedUIName
                sendNotification("Interface", "Enabled: " .. tostring(selectedUIName))
                return true
            end

            if activeUIName then
                toggleHiddenInterface(activeUIName, false)
                sendNotification("Interface", "Disabled: " .. tostring(activeUIName))
                activeUIName = nil
            elseif selectedUIName then
                toggleHiddenInterface(selectedUIName, false)
            end
            return true
        end

        local uiDropdown = UIUtilitiesGroup:AddDropdown("MiamiHiddenUISelect", {
            Text = "Select Interface",
            Values = hiddenUiNames,
            Default = selectedUIName,
            Callback = function(value)
                local newSelection = normalizeDropdownValue(value)
                if not newSelection or newSelection == "" then return end

                local wasEnabled = activeUIName ~= nil
                if activeUIName and activeUIName ~= newSelection then
                    toggleHiddenInterface(activeUIName, false)
                    activeUIName = nil
                end

                selectedUIName = newSelection

                
                
                if wasEnabled then
                    toggleHiddenInterface(selectedUIName, true)
                    activeUIName = selectedUIName
                end
            end,
        })

        interfaceToggle = UIUtilitiesGroup:AddToggle("MiamiToggleSelectedInterface", {
            Text = "Toggle Interface",
            Default = false,
            Callback = function(state)
                local success = setSelectedInterfaceEnabled(state)
                if state and not success and interfaceToggle then
                    interfaceToggle:SetValue(false)
                end
            end,
        })

        UIUtilitiesGroup:AddButton("Refresh Interface List", function()
            local wasEnabled = activeUIName ~= nil
            if activeUIName then
                toggleHiddenInterface(activeUIName, false)
                activeUIName = nil
            end

            hiddenUiNames = getHiddenUiNames()
            if #hiddenUiNames == 0 then hiddenUiNames = {"ATM GUI"} end
            selectedUIName = hiddenUiNames[1]
            pcall(function()
                uiDropdown:SetValues(hiddenUiNames)
                uiDropdown:SetValue(selectedUIName)
            end)

            if wasEnabled then
                toggleHiddenInterface(selectedUIName, true)
                activeUIName = selectedUIName
            end
            sendNotification("Interface", "Interface list refreshed.")
        end)

        UIUtilitiesGroup:AddLabel("Select an interface, then use Toggle Interface.")
    end
end






BlueGunModsSection = Tabs.GunMods:AddLeftGroupbox("Weapon Modifications")

function bindToggle(displayName, key, flag)
    BlueGunModsSection:AddToggle(flag, {
        Text = displayName,
        Default = false,
        Callback = function(s)
            WeaponMods[key] = s
            if key == "InfiniteDamage" then WeaponMods.DamageAmplified = s end
            pcall(applyAllWeaponMods)
        end
    })
end

bindToggle("Infinite Ammo",    "InfiniteAmmo",      "BlueWM_InfiniteAmmo")
bindToggle("Infinite Clips",   "InfiniteClips",     "BlueWM_InfiniteClips")
bindToggle("Infinite Damage",  "InfiniteDamage",    "BlueWM_InfiniteDamage")
bindToggle("Instant Reload",   "InstantReload",     "BlueWM_InstantReload")
bindToggle("Instant Equip",    "InstantEquip",      "BlueWM_InstantEquip")
bindToggle("80k Bullets",      "Bullets80k",        "BlueWM_80kBullets")
BlueGunModsSection:AddLabel("80k bullet guns cannot be passed to others")
bindToggle("Fully Automatic",  "Automatic",         "BlueWM_Automatic")
bindToggle("Disable Jamming",  "DisableJamming",    "BlueWM_DisableJamming")
bindToggle("Modify Recoil Value", "ModifyRecoilValue", "BlueWM_ModifyRecoil")
bindToggle("Modify Spread Value", "ModifySpreadValue", "BlueWM_ModifySpread")
bindToggle("Modify Fire Rate",  "ModifyFireRate",    "BlueWM_ModifyFireRate")
BlueGunModsSection:AddButton("Force 80k Bullets", MianiForce80kBullets)


MianiEmoteSection = Tabs.Extra:AddLeftGroupbox("Emotes")
MianiEmoteSection:AddDropdown("MianiSelectedEmote", {
    Text = "Select Emote",
    Values = MianiEmoteNames,
    Default = "Take The L",
    Callback = function(v) 
        if v and MianiEmotes[v] then MianiSelectedEmoteName = v end 
    end
})
MianiEmoteSection:AddButton("Play Selected Emote", function()
    local id = MianiEmotes[MianiSelectedEmoteName]
    if id then MianiPlayEmoteById(id, MianiSelectedEmoteName) end
end)
MianiEmoteSection:AddButton("Stop Emote", function() 
    MianiStopAllTracks()
    sendNotification("Emotes","Stopped emote") 
end)


MianiEmoteSettingsSection = Tabs.Extra:AddLeftGroupbox("Emote Settings")
MianiEmoteSettingsSection:AddToggle("MianiEmoteLoop", {
    Text = "Loop Emote",
    Default = true,
    Callback = function(s)
        MianiEmoteSettings.Loop = s
        if MianiCurrentEmoteTrack then pcall(function() MianiCurrentEmoteTrack.Looped = s end) end
    end
})


GonModsSection = BlueGunModsSection 
fireBallsEnabled = false
function setBulletVisuals(t)
    if typeof(t) ~= "table" or not rawget(t, "BulletSpeed") then return end
    rawset(t, "BulletSpeed", 150)
    rawset(t, "DropGravity", 0.3)
    rawset(t, "BulletParticleEnaled", true)
    rawset(t, "BulletParticleColor", Color3.new(1, 0, 0))
    rawset(t, "BulletParticleSize", NumberSequence.new({
        NumberSequenceKeypoint.new(0, 9e9),
        NumberSequenceKeypoint.new(1, 1)
    }))
end

GonModsSection:AddToggle("GonRainbowBullet", {
    Text = "Fire Bullets",
    Default = false,
    Callback = function(state)
        fireBallsEnabled = state
        if state then
            for _, v in getgc(true) do
                if typeof(v) == "table" then
                    pcall(function()
                        setBulletVisuals(v)
                        for _, k in ipairs({7, 8}) do
                            setBulletVisuals(rawget(v, k))
                        end
                    end)
                end
            end
            sendNotification("Weapon Mods", "Fire Bullets enabled!")
        else
            sendNotification("Weapon Mods", "Fire Bullets disabled (Re-equip gun to revert)!")
        end
    end
})


local FlashbangBulletsEnabled = false
local TornadoBulletsEnabled = false
local TornadoBulletSpeed = 250
local OrbFlashLastScan = 0
local OrbFlashConfigs = setmetatable({}, {__mode = "k"})
local OrbFlashOriginals = setmetatable({}, {__mode = "k"})
local OrbFlashKeys = {
    "BulletSpeed", "DropGravity", "BulletSize", "BulletMeshScale", "BulletTransparency",
    "BulletMeshEnabled", "BulletMeshID", "BulletTextureID", "BulletLightEnabled",
    "BulletLightBrightness", "BulletLightRange", "BulletLightColor", "MuzzleLightEnabled",
    "LightColor", "LightBrightness", "LightRange", "LightShadows", "MuzzleFlashEnabled", "DisappearTime"
}

local function saveOrbFlashOriginals(config)
    if OrbFlashOriginals[config] then return end
    local saved = {values = {}, exists = {}}
    for _, key in ipairs(OrbFlashKeys) do
        local value = rawget(config, key)
        saved.exists[key] = value ~= nil
        saved.values[key] = value
    end
    OrbFlashOriginals[config] = saved
end

local function restoreOrbFlashConfig(config)
    local saved = OrbFlashOriginals[config]
    if not saved then return end
    for _, key in ipairs(OrbFlashKeys) do
        rawset(config, key, saved.exists[key] and saved.values[key] or nil)
    end
end

local function collectOrbFlashConfigs()
    local ok, objects = pcall(getgc, true)
    if not ok or type(objects) ~= "table" then return end
    local function add(config)
        if typeof(config) == "table" and rawget(config, "BulletSpeed") then
            OrbFlashConfigs[config] = true
            saveOrbFlashOriginals(config)
        end
    end
    for _, object in ipairs(objects) do
        if typeof(object) == "table" then
            pcall(function()
                add(object)
                add(rawget(object, 7))
                add(rawget(object, 8))
            end)
        end
    end
    OrbFlashLastScan = os.clock()
end

local function applyOrbFlashConfig(config)
    restoreOrbFlashConfig(config)
    if FlashbangBulletsEnabled then
        rawset(config, "BulletLightEnabled", true)
        rawset(config, "BulletLightBrightness", 9e9)
        rawset(config, "BulletLightRange", 99999)
        if rawget(config, "BulletLightColor") ~= nil then rawset(config, "BulletLightColor", Color3.new(1, 1, 1)) end
        rawset(config, "MuzzleLightEnabled", true)
        rawset(config, "LightColor", Color3.new(1, 1, 1))
        rawset(config, "LightBrightness", 999)
        rawset(config, "LightRange", 999)
        rawset(config, "LightShadows", true)
        rawset(config, "MuzzleFlashEnabled", true)
        rawset(config, "DisappearTime", 8)
    end
    if TornadoBulletsEnabled then
        rawset(config, "BulletSpeed", TornadoBulletSpeed)
        rawset(config, "DropGravity", 0)
        rawset(config, "BulletSize", Vector3.new(1, 1, 1))
        rawset(config, "BulletMeshScale", Vector3.new(1, 1, 1))
        rawset(config, "BulletTransparency", 0)
        rawset(config, "BulletMeshEnabled", true)
        rawset(config, "BulletMeshID", "rbxassetid://15775612843")
        rawset(config, "BulletTextureID", "rbxassetid://15775612843")
    end
end

local function applyAllOrbFlashConfigs()
    if os.clock() - OrbFlashLastScan >= 5 then collectOrbFlashConfigs() end
    for config in pairs(OrbFlashConfigs) do pcall(applyOrbFlashConfig, config) end
end

local function restoreAllOrbFlashConfigs()
    for config in pairs(OrbFlashConfigs) do pcall(restoreOrbFlashConfig, config) end
end

local function refreshOrbFlashState()
    collectOrbFlashConfigs()
    if FlashbangBulletsEnabled or TornadoBulletsEnabled then
        applyAllOrbFlashConfigs()
    else
        restoreAllOrbFlashConfigs()
    end
end

GonModsSection:AddToggle("TacoFlashbangBullets", {
    Text = "Flashbang Bullets",
    Default = false,
    Callback = function(state)
        FlashbangBulletsEnabled = state
        refreshOrbFlashState()
        sendNotification("Weapon Mods", state and "Flashbang Bullets enabled!" or "Flashbang Bullets disabled!")
    end,
})

GonModsSection:AddToggle("TacoTornadoBullets", {
    Text = "Tornado Bullets",
    Default = false,
    Callback = function(state)
        TornadoBulletsEnabled = state
        refreshOrbFlashState()
        sendNotification("Weapon Mods", state and "Tornado Bullets enabled!" or "Tornado Bullets disabled!")
    end,
})

GonModsSection:AddSlider("TacoTornadoSpeed", {
    Text = "Tornado Speed",
    Min = 1,
    Max = 500,
    Default = TornadoBulletSpeed,
    Rounding = 0,
    Callback = function(value)
        TornadoBulletSpeed = value
        if TornadoBulletsEnabled then applyAllOrbFlashConfigs() end
    end,
})

task.spawn(function()
    while not Library._unloaded do
        if FlashbangBulletsEnabled or TornadoBulletsEnabled then applyAllOrbFlashConfigs() end
        task.wait(0.1)
    end
end)

Library:OnUnload(function()
    FlashbangBulletsEnabled = false
    TornadoBulletsEnabled = false
    restoreAllOrbFlashConfigs()
end)

BlueGunSettingsSection = Tabs.GunMods:AddRightGroupbox("Weapon Settings")
BlueGunSettingsSection:AddLabel("100% is default percentage.")
BlueGunSettingsSection:AddSlider("BlueWM_FireRatePercent", {
    Text = "Fire-Rate Percentage",
    Min = 1, Max = 100, Default = 50, Rounding = 0,
    Callback = function(v) WeaponMods.FireRateSpeed = v end
})
BlueGunSettingsSection:AddSlider("BlueWM_SpreadPercent", {
    Text = "Spread Percentage",
    Min = 1, Max = 100, Default = 50, Rounding = 0,
    Callback = function(v) WeaponMods.SpreadPercentage = v end
})
BlueGunSettingsSection:AddSlider("BlueWM_RecoilPercent", {
    Text = "Recoil Percentage",
    Min = 1, Max = 100, Default = 50, Rounding = 0,
    Callback = function(v) WeaponMods.RecoilPercentage = v end
})
BlueGunSettingsSection:AddSlider("BlueWM_ReloadSpeed", {
    Text = "Reload Speed",
    Min = 0.01, Max = 1, Default = 0.2, Rounding = 2,
    Callback = function(v) WeaponMods.ReloadSpeed = v; pcall(applyAllWeaponMods) end
})
BlueGunSettingsSection:AddSlider("BlueWM_EquipSpeed", {
    Text = "Equip Speed",
    Min = 0.01, Max = 1, Default = 0.2, Rounding = 2,
    Callback = function(v) WeaponMods.EquipSpeed = v; pcall(applyAllWeaponMods) end
})


BlueGunColorSection = Tabs.GunMods:AddRightGroupbox("Gun Color")
BlueGunColorSection:AddToggle("BlueWM_GunColor", {
    Text = "Enable Gun Color",
    Default = false,
    Callback = function(s)
        GunChams = s; if not s then MianiRestoreGunColor() end
    end
})
BlueGunColorSection:AddToggle("BlueWM_RainbowGun", {
    Text = "Rainbow Gun Color",
    Default = false,
    Callback = function(s) RainbowGun = s end
})
BlueGunColorSection:AddDropdown("BlueWM_GunColorSelect", {
    Text = "Gun Color",
    Values = {"Green","Purple","Red","Blue","Pink","Cyan","Yellow","White"},
    Default = "Green",
    Callback = function(v)
        local colors = {
            Green=Color3.fromRGB(0,200,0), Purple=Color3.fromRGB(143,0,255), Red=Color3.fromRGB(255,0,0),
            Blue=Color3.fromRGB(0,120,255), Pink=Color3.fromRGB(255,80,180), Cyan=Color3.fromRGB(0,255,255),
            Yellow=Color3.fromRGB(255,255,0), White=Color3.fromRGB(255,255,255),
        }
        GunChamsColor = colors[tostring(v)] or Color3.fromRGB(0,200,0)
    end
})







TargetGroup = Tabs.Main:AddLeftGroupbox("Target")

TargetPlayerNames = getTargetPlayerList()
TargetUtilities.SelectedPlayer = TargetPlayerNames[1] or ""

TargetDropdownObject = TargetGroup:AddDropdown("MainTargetPlayer", {
    Text = "Select Player",
    Values = TargetPlayerNames,
    Default = TargetUtilities.SelectedPlayer,
    Callback = function(v)
        TargetUtilities.SelectedPlayer = normalizeDropdownValue(v)
    end
})

TargetGroup:AddButton("Refresh Player List", function()
    TargetPlayerNames = getTargetPlayerList()
    if TargetDropdownObject then
        pcall(function() TargetDropdownObject:SetValues(TargetPlayerNames) end)
    end
    sendNotification("Target", "Player list refreshed: " .. #TargetPlayerNames)
end)

TargetGroup:AddButton("Pass to Nearest Player", function()
    pcall(function() ReplicatedStorage.DropRemote:FireServer("Drop"); sendNotification("Pass", "Passed to nearest player.") end)
end)

TargetGroup:AddToggle("BoxHubAutoPassTo", {
    Text = "Auto Pass to Nearest (loop)",
    Default = false,
    Callback = function(v)
        getgenv().BoxHubAutoPassTo = v; notifyToggle("Auto Pass to Nearest", v)
        if v and not getgenv()._BoxHubAutoPassToRunning then
            getgenv()._BoxHubAutoPassToRunning = true
            task.spawn(function()
                while getgenv().BoxHubAutoPassTo do
                    pcall(function() ReplicatedStorage.DropRemote:FireServer("Drop") end)
                    task.wait(0.1)
                end
                getgenv()._BoxHubAutoPassToRunning = false
            end)
        end
    end
})

TargetGroup:AddToggle("BoxHubAutoDropGuns", {
    Text = "Auto Drop Guns",
    Default = false,
    Callback = function(v)
        getgenv().BoxHubAutoDropGuns = v; notifyToggle("Auto Drop Guns", v)
        if v and not getgenv()._BoxHubAutoDropGunsRunning then
            getgenv()._BoxHubAutoDropGunsRunning = true
            task.spawn(function()
                while getgenv().BoxHubAutoDropGuns do
                    pcall(function()
                        local lp = LocalPlayer
                        local char = lp.Character
                        local bp = lp:FindFirstChild("Backpack")
                        if char and bp then
                            for _, Gun in ipairs(bp:GetChildren()) do
                                if Gun:IsA("Tool") and Gun:FindFirstChild("GunScript_Server") then
                                    local hum = char:FindFirstChildOfClass("Humanoid")
                                    if hum then hum:EquipTool(Gun) end
                                    local d = ReplicatedStorage:FindFirstChild("DropItemRemote")
                                    if d then d:FireServer(Gun) end
                                    break
                                end
                            end
                        end
                    end)
                    task.wait(math.random(10,13)/10)
                end
                getgenv()._BoxHubAutoDropGunsRunning = false
            end)
        end
    end
})

TargetGroup:AddToggle("TargetSpectatePlayer", {
    Text = "Spectate Player",
    Default = false,
    Callback = function(s) TargetUtilities.SpectatePlayer = s; notifyToggle("Spectate Player", s) end
})

TargetGroup:AddToggle("TargetBringNearest", {
    Text = "Bring Nearest Player",
    Default = false,
    Callback = function(s) TargetUtilities.BringingNearestPlayer = s; notifyToggle("Bring Nearest Player", s) end
})

TargetGroup:AddToggle("TargetBringPlayer", {
    Text = "Bring Player",
    Default = false,
    Callback = function(s) TargetUtilities.BringingPlayer = s; notifyToggle("Bring Player", s) end
})

TargetGroup:AddToggle("TargetAutoKillGun", {
    Text = "Auto Kill Player - Gun",
    Default = false,
    Callback = function(s) TargetUtilities.AutoKill = s; notifyToggle("Auto Kill Player", s) end
})

TargetGroup:AddLabel("Auto Kill: the person can't be too far for it to work.")

TargetGroup:AddButton("Car Fling Selected Player", function()
    CarFlingSelectedPlayer()
end)

TargetGroup:AddToggle("TargetAutoRagdollGun", {
    Text = "Auto Ragdoll Player - Gun",
    Default = false,
    Callback = function(s) TargetUtilities.AutoRagdoll = s; notifyToggle("Auto Ragdoll", s) end
})

TargetGroup:AddButton("Teleport To Player", function()
    local t = getSelectedTargetPlayer()
    if t and t.Character and t.Character:FindFirstChild("HumanoidRootPart") then
        Config:Teleport(t.Character.HumanoidRootPart.CFrame * CFrame.new(3,0,0))
    else
        sendNotification("Target", "No valid target selected.")
    end
end)

TargetGroup:AddButton("God Player - Hold Gun", function()
    local t = getSelectedTargetPlayer()
    if t then targetGunRemote(t.Name, "HumanoidRootPart", math.huge) else sendNotification("Target", "No valid target selected.") end
end)






MoneyGroup = Tabs.Player:AddLeftGroupbox("Money")
ExtraMoneyGroup = Tabs.Player:AddLeftGroupbox("Money Actions")

ExtraMoneyGroup:AddButton("Manual [Inf Money]", function()
    sendNotification("Inf Money", "Triggered.")
    local finishBasketballGame = StartTacoBasketballGameOverlay()
    task.spawn(function()
        local ok, err = pcall(InfMoneyHoldCupz)
        if finishBasketballGame then finishBasketballGame(ok) end
        if not ok then warn(err); sendNotification("Inf Money", "Stopped: " .. tostring(err)) end
    end)
end)

ExtraMoneyGroup:AddButton("Generate Max Illegal Money", function()
    sendNotification("Illegal Money", "Generating max...")
    task.spawn(function()
        local ok, err = pcall(GenerateMaxIllegalMoney)
        if not ok then warn(err); sendNotification("Illegal Money", "Stopped: " .. tostring(err)) end
    end)
end)

ExtraMoneyGroup:AddButton("Teleport [COOK POT]", function() TeleportToCookPot() end)
ExtraMoneyGroup:AddButton("Buy Ice-Fruit [ITEMS]", function() sendNotification("Buy Items", "Buying Ice-Fruit items..."); SetupInfiniteMoney() end)
MoneyGroup:AddButton("Instructions: Inf Money", function() sendNotification("WARNING", "Need ≥ $3,000 cash first. Cook Ice-Fruit, hold cup, then press Manual Inf Money.") end)
MoneyGroup:AddButton("Clean All Filthy Money", function() CleanAllFilthyMoney() end)
MoneyGroup:AddToggle("AutoDrop10k", {
    Text = "Auto Drop 10k",
    Default = false,
    Callback = function(s) getgenv().MoneyDropEnabled = s end
})



QuickOutfitGroup = Tabs.Extra:AddRightGroupbox("Quick Outfits")
QuickOutfitGroup:AddButton("Spiderman", function()
    applyOutfit("Spiderman", {{"Buy","Shirts","Spiderman"},{"Wear","Shirts","Spiderman"},{"Buy","Pants","Spiderman"},{"Wear","Pants","Spiderman"},{"Buy","Shiestys","RedShiesty"},{"Wear","Shiestys","RedShiesty"}})
end)
QuickOutfitGroup:AddButton("All Black", function()
    applyOutfit("All Black", {{"Buy","Shirts","Black"},{"Wear","Shirts","Black"},{"Buy","Pants","Black"},{"Wear","Pants","Black"},{"Buy","Shiestys","BlackShiesty"},{"Wear","Shiestys","BlackShiesty"}})
end)
QuickOutfitGroup:AddButton("Blu Moncler Drip", function()
    applyOutfit("Blu Moncler Drip", {{"Buy","Shirts","Blu Moncler"},{"Wear","Shirts","Blu Moncler"},{"Buy","Pants","Amiri Blue Jeans"},{"Wear","Pants","Amiri Blue Jeans"},{"Buy","Shiestys","Shiesty"},{"Wear","Shiestys","Shiesty"}})
end)
QuickOutfitGroup:AddButton("Amiri Star Drip", function()
    applyOutfit("Amiri Star Drip", {{"Buy","Shirts","Amiri Star Hoodie"},{"Wear","Shirts","Amiri Star Hoodie"},{"Buy","Pants","Black Amiri Jeans B22"},{"Wear","Pants","Black Amiri Jeans B22"},{"Buy","Shiestys","Shiesty"},{"Wear","Shiestys","Shiesty"}})
end)
QuickOutfitGroup:AddButton("Red Sp5der Drip", function()
    applyOutfit("Red Sp5der Drip", {{"Buy","Shirts","Red Sp5der Sweats"},{"Wear","Shirts","Red Sp5der Sweats"},{"Buy","Pants","Red Sp5der Sweats"},{"Wear","Pants","Red Sp5der Sweats"},{"Buy","Shiestys","RedShiesty"},{"Wear","Shiestys","RedShiesty"}})
end)
QuickOutfitGroup:AddButton("Green Sp5der Drip", function()
    applyOutfit("Green Sp5der Drip", {{"Buy","Shirts","Green Sp5der Sweats"},{"Wear","Shirts","Green Sp5der Hoodie"},{"Buy","Pants","Green Sp5der Sweats"},{"Wear","Pants","Green Sp5der Sweats"},{"Buy","Shiestys","Shiesty"},{"Wear","Shiestys","Shiesty"}})
end)
QuickOutfitGroup:AddButton("Blue Sp5der Drip", function()
    applyOutfit("Blue Sp5der Drip", {{"Buy","Shirts","Blue Sp5der Hoodie"},{"Wear","Shirts","Blue Sp5der Hoodie"},{"Buy","Pants","Blue Sp5der Sweats"},{"Wear","Pants","Blue Sp5der Sweats"},{"Buy","Shiestys","Shiesty"},{"Wear","Shiestys","Shiesty"}})
end)
QuickOutfitGroup:AddButton("Red Zipped Drip", function()
    applyOutfit("Red Zipped Drip", {{"Buy","Shirts","Red Zipped Jacket"},{"Wear","Shirts","Red Zipped Jacket"},{"Buy","Pants","White AF1 BJeans"},{"Wear","Pants","White AF1 BJeans"}})
end)

getgenv().outfitData = getgenv().outfitData or {
    ["Blue Spider"] = { Hats={"MRHoodieBRR"}, Shirts={"Blue Sp5der Hoodie"}, Pants={"Blue Sp5der Sweats"}, Shiestys={"Shiesty"} },
    ["Spider Man"]  = { Hats=nil,              Shirts={"Spiderman"},          Pants={"Spiderman"},          Shiestys={"RedShiesty"} },
    ["Red Spider"]  = { Hats={"MRHoodieBRR"}, Shirts={"Red Sp5der Sweats"},  Pants={"Red Sp5der Sweats"},  Shiestys={"Shiesty"} },
}
getgenv().selectedOutfit = getgenv().selectedOutfit or "Blue Spider"
QuickOutfitGroup:AddDropdown("BoxHubOutfitDropdown", {
    Text = "Outfit Preset",
    Values = {"Blue Spider", "Spider Man", "Red Spider"},
    Default = "Blue Spider",
    Multi = false,
    Callback = function(o) getgenv().selectedOutfit = o; sendNotification("Outfit", "Selected: " .. tostring(o)) end
})
QuickOutfitGroup:AddButton("Equip Selected Outfit", function()
    local outfit = getgenv().outfitData[getgenv().selectedOutfit]
    if not outfit then sendNotification("Outfit", "Outfit not found."); return end
    pcall(function() ReplicatedStorage.ClothShopRemote:FireServer("Reset Data") end)
    task.wait(0.2)
    for category, items in pairs(outfit) do
        if items then
            for _, item in ipairs(items) do
                pcall(function()
                    if LocalPlayer[category] and not LocalPlayer[category]:FindFirstChild(item) then
                        ReplicatedStorage.ClothShopRemote:FireServer("Buy", category, item); task.wait(0.1)
                    end
                    ReplicatedStorage.ClothShopRemote:FireServer("Wear", category, item); task.wait(0.2)
                end)
            end
        end
    end
    sendNotification("Outfit", "Equipped " .. getgenv().selectedOutfit .. "!")
end)

function ApplyDripstoreClothing(category, itemName)
    if not category or not itemName then return end
    if not LocalPlayer:FindFirstChild(category) then return end
    pcall(function()
        if not LocalPlayer[category]:FindFirstChild(itemName) then
            ReplicatedStorage.ClothShopRemote:FireServer("Buy", category, itemName)
            task.wait(0.05)
        end
        ReplicatedStorage.ClothShopRemote:FireServer("Wear", category, itemName)
    end)
end

RandomClothes = {
    Shirts = {
        "Black AMiri 22", "Blu C Amiri Hoodie", "TankTop Wit Blue B", "TankTop Wit RedFlag", "TankTok Wit Black", "Purple B Puffer", "Green Varsity", "ChromeHeart Blue", "PastalBlue Jacket", "Grey Hoodie Wit Red", "Balmain Hoodie", "White Balmain Hoodie", "Black PalmAngel Jacket", "Blu Moncler", "White Polo Vest", "White Tatted T shirt", "Red B Jacket", "Grey Amiri Hoodie", "Bzz Blue Hoodie", "Xunners Yankee W Tattoo", "Amiri Varsity Jacket", "Tan Mechanic X", "Black Tatted T Shirt", "Amiri Star Hoodie", "Tatted Tank To[", "Amiri Halloween Shirt", "Moncler Tatted Open Shirt", "Spiderman", "Brown Glo hartt Work", "Navy Blue & Red Sp5der Beluga Hoodie", "Black Sp5der Jeffery Hoodie", "Yellow Spider Supreme Zip Up Jacket", "Black Amiri Denim Love Jacket", "Black Bapestar sweater", "Zipped Moncler Black", "Black Chrome Heart Zip Up", "Polo Black Moncler + Tats", "White Tank Top W/ Shirt on shoulder", "Red Zipped Jacket", "Y2K Brown & Tan STARS Varsity", "Yellow & White Striped Lightning Track Suit", "Black & Blue LA Designer Hoodie White Shirt", "Pink Y2K", "Pink Bape", "Moose Grey Hoodie", "Purple and Yellow GHOP Hoodie", "Black & White Designer Baseball Jersey", "Blue and White Chicago OBLOCK Shirt W Tatts", "Bathing Ape Bape Camo", "White and Black Sniper Gang Superstar Shirt", "Red and White Designer Graphic Shirt W Tatts", "Tan Brown Graphic Y2K Pullover Hoodie", "Grey & Red Designer 99 Denim Jean Jacket", "black open jacket w/ purple", "Opened Black Zipper Jacket W Tats", "Amiri Jean Jacket", "BlueTech", "WhiteTankTop", "BluePalm Jacket", "Blue ChromeHeart Jersey", "Blue Chrome Hearts Hoodiey", "Blue Sp5der Hoodie", "Green Sp5der Hoodie", "Red Sp5der Sweats", "Bandi T Cardi", "Black Amiri Star", "Blue Hellstar"
    },
    Pants = {
        "Black Ripped Jeans", "Y2K Khaki pants", "Black amiri jeans w jeezy", "Hard Jeans LV", "Balmain Grey Jeans Wit/ PSD's Jordan 11s", "Amiri Jeans w Red Thunder", "Y2K Brown & Tan STARS Sweat Joggers", "Purple Brand Jeans x Lavins", "Black & Tan Y2K Designer Graphic Joggers", "Red And Black Checkered CheckMate Joggers", "Red Designer Denim Jeans Drip Designer", "Grey & Yellow Designer Denim Jeans W Belt", "Violet Valk Purple Designer Denim Jeanss", "Black and White Designer Denim Jeans", "Black PURPLE Brand Jeans w/ Balenciaga Runners", "Grey Jeans W/ Red Jz", "Ripped Black Jeans w White Thunder 4s", "BJeans w White Black Cat 4s", "Grey Jean W Dior Runners", "ReddyPants", "RedTech", "BlueTechPants", "GreenTechPants1", "WhiteTechPants", "BluePalmAngels", "BluePalm Jacket", "Blue Sp5der Sweats", "Green Sp5der Sweats", "Red Sp5der Sweats", "Blue Sp5der Sweats", "Sweats Wit Black AF1", "Shorts W Dunks", "Amiri Jeans x Grey b22", "Spiderman", "Saint Sinner Jeans", "Grey Purple Jeans", "Amiri Jean x Retro 13 x LV", "Tan Mechanic Pants Black AF1", "BabyBlue Nikes", "Black PalmAngels", "WhiteJeans", "White Jeans w AF1", "Grey Sweats W Red", "Amiri Blue Jeans", "Blue Offwhites wit GreyJeams", "Black Amiri Jeans B22", "Green Ripped Jeans", "BlackJeans W Purple LV Flags", "Black B Shorts", "Red B Shorts", "Blu B Shorts", "White AF1 BJeans", "Amiri Jeans x Grey b22", "Pink Bapesta Jeans"
    },
}

getgenv().OutfitSwapDelay = getgenv().OutfitSwapDelay or 0.2
getgenv().FlashOutfits = getgenv().FlashOutfits or false
FlashOutfitLoopRunning = false

QuickOutfitGroup:AddToggle("MiamiFlashOutfit", {
    Text = "Flash Outfit",
    Default = false,
    Callback = function(value)
        getgenv().FlashOutfits = value
        if value then
            sendNotification("Outfit", "Flash Outfit enabled")
            if FlashOutfitLoopRunning then return end
            FlashOutfitLoopRunning = true
            task.spawn(function()
                while getgenv().FlashOutfits do
                    task.wait(getgenv().OutfitSwapDelay or 0.2)
                    for category, list in pairs(RandomClothes) do
                        if not getgenv().FlashOutfits then break end
                        local randomItem = list[math.random(1, #list)]
                        ApplyDripstoreClothing(category, randomItem)
                    end
                end
                FlashOutfitLoopRunning = false
            end)
        else
            sendNotification("Outfit", "Flash Outfit disabled")
        end
    end
})

QuickOutfitGroup:AddSlider("MiamiOutfitSpeedSlider", {
    Text = "Flash Swap Delay",
    Default = 0.2,
    Min = 0.0005,
    Max = 2.5,
    Rounding = 4,
    Compact = false,
    Callback = function(value)
        getgenv().OutfitSwapDelay = value
    end
})


BankATMGroup = Tabs.Main:AddRightGroupbox("Bank / ATM")
function getBankValue()
    local ok, v = pcall(function() return LocalPlayer.stored.Bank.Value end)
    if ok then return v end; return 0
end
bankAmountLabel = BankATMGroup:AddLabel("Bank Amount: $" .. tostring(getBankValue()))
pcall(function()
    local stored = LocalPlayer:WaitForChild("stored", 5)
    if stored and stored:FindFirstChild("Bank") then
        stored.Bank:GetPropertyChangedSignal("Value"):Connect(function()
            pcall(function() bankAmountLabel:SetText("Bank Amount: $" .. tostring(stored.Bank.Value)) end)
        end)
    end
end)

BankATMGroup:AddInput("BoxHubBankWithdraw", {
    Text = "Withdraw Amount",
    Default = "",
    Placeholder = "Max 90,000",
    Numeric = true,
    Finished = true,
    Callback = function(v)
        local a = tonumber(v)
        if a and a > 0 and a <= 90000 then
            pcall(function() ReplicatedStorage.BankAction:FireServer("with", a) end)
            sendNotification("Withdraw", "Withdrew $" .. a)
        end
    end
})

BankATMGroup:AddInput("BoxHubBankDeposit", {
    Text = "Deposit Amount",
    Default = "",
    Placeholder = "Max 30,000",
    Numeric = true,
    Finished = true,
    Callback = function(v)
        local a = tonumber(v)
        if a and a > 0 and a <= 30000 then
            pcall(function() ReplicatedStorage.BankAction:FireServer("depo", a) end)
            sendNotification("Deposit", "Deposited $" .. a)
        end
    end
})

BankATMGroup:AddToggle("BoxHubDropMax", {
    Text = "Drop Max ($10k loop)",
    Default = false,
    Callback = function(v)
        getgenv().BoxHubDropMax = v
        if v then
            task.spawn(function()
                while getgenv().BoxHubDropMax do
                    pcall(function() ReplicatedStorage:WaitForChild("BankProcessRemote"):InvokeServer("Drop", 10000) end)
                    task.wait(0.5)
                end
            end)
        end
    end
})

BankATMGroup:AddToggle("BoxHubAutoDeposit", {
    Text = "Auto Deposit 30K",
    Default = false,
    Callback = function(v)
        getgenv().BoxHubAutoDeposit = v
        if v then
            task.spawn(function()
                local BA = ReplicatedStorage:WaitForChild("BankAction")
                while getgenv().BoxHubAutoDeposit do
                    pcall(function() BA:FireServer("depo", 30000) end)
                    task.wait(3)
                end
            end)
        end
    end
})

BankATMGroup:AddToggle("BoxHubAutoWithdraw", {
    Text = "Auto Withdraw 90K",
    Default = false,
    Callback = function(v)
        getgenv().BoxHubAutoWithdraw = v
        if v then
            task.spawn(function()
                local BA = ReplicatedStorage:WaitForChild("BankAction")
                while getgenv().BoxHubAutoWithdraw do
                    pcall(function() BA:FireServer("with", 90000) end)
                    task.wait(3)
                end
            end)
        end
    end
})


VehicleGroup = Tabs.Main:AddRightGroupbox("Vehicle Settings")
VehicleGroup:AddToggle("CarFlyEnabled", {
    Text = "Car Fly",
    Default = false,
    Callback = function(s) if s then StartCarFly() else StopCarFly() end end
})
VehicleGroup:AddSlider("CarFlySpeed", {
    Text = "Car Fly Speed",
    Min = 20, Max = 300, Default = 120, Rounding = 0,
    Callback = function(value)
        Config.TheBronx.carflyspeed = value
        CarFly.Speed = value
    end
})
VehicleGroup:AddToggle("VehSpeedEnabled", {
    Text = "Vehicle Speed Boost",
    Default = false,
    Callback = function(s) VehicleModifications.SpeedEnabled = s end
})
VehicleGroup:AddSlider("VehSpeedValue", {
    Text = "Speed Multiplier",
    Min = 1, Max = 25, Default = 5, Rounding = 0,
    Callback = function(v) VehicleModifications.SpeedValue = v / 1000 end
})
VehicleGroup:AddToggle("VehBreakEnabled", {
    Text = "Vehicle Brakes",
    Default = false,
    Callback = function(s) VehicleModifications.BreakEnabled = s end
})
VehicleGroup:AddSlider("VehBreakValue", {
    Text = "Brake Multiplier",
    Min = 10, Max = 300, Default = 50, Rounding = 0,
    Callback = function(v) VehicleModifications.BreakValue = v / 1000 end
})
VehicleGroup:AddToggle("VehInstantStop", {
    Text = "Instant Stop (V)",
    Default = false,
    Callback = function(s) VehicleModifications.InstantStop = s end
})
VehicleGroup:AddButton("Bring Nearest Car", function()
    local char = LocalPlayer.Character; if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart"); local hum = char:FindFirstChildWhichIsA("Humanoid")
    if not hrp or not hum then return end
    local car = GetNearestCar(hrp)
    if not car then sendNotification("Bring Car", "No empty cars found nearby!") return end
    local seat = car:FindFirstChild("DriveSeat") or car:FindFirstChildWhichIsA("VehicleSeat"); if not seat then return end
    if not car.PrimaryPart then pcall(function() car.PrimaryPart = car:FindFirstChildWhichIsA("BasePart") end) end
    if car.PrimaryPart then
        car:SetPrimaryPartCFrame(hrp.CFrame * CFrame.new(0,0,-6) * CFrame.Angles(0,math.rad(180),0))
    else
        seat.CFrame = hrp.CFrame * CFrame.new(0,0,-6) * CFrame.Angles(0,math.rad(180),0)
    end
    task.wait(0.2); seat:Sit(hum)
    sendNotification("Bring Car", "Car brought successfully!")
end)






NoRentPayEnabled = false
NoRentPaySavedScripts = {}
NoRentPaySavedGuis = {}
NoRentPayConnections = {}

local function IsRentObject(object)
    if not object then return false end
    local ok, fullName = pcall(function() return object:GetFullName():lower() end)
    local search = ok and fullName or tostring(object.Name):lower()
    return search:find("rent", 1, true) ~= nil
end

local function ApplyNoRentPayObject(object)
    if not NoRentPayEnabled or not object or not IsRentObject(object) then return end

    if object:IsA("LocalScript") or object:IsA("Script") then
        if NoRentPaySavedScripts[object] == nil then
            NoRentPaySavedScripts[object] = object.Enabled
        end
        object.Enabled = false
    elseif object:IsA("ScreenGui") then
        if NoRentPaySavedGuis[object] == nil then
            NoRentPaySavedGuis[object] = object.Enabled
        end
        object.Enabled = false
    end
end

local function ScanNoRentPayControllers()
    for _, container in ipairs({
        StarterGui,
        LocalPlayer:FindFirstChild("PlayerGui"),
        LocalPlayer:FindFirstChild("PlayerScripts"),
    }) do
        if container then
            ApplyNoRentPayObject(container)
            for _, object in ipairs(container:GetDescendants()) do
                ApplyNoRentPayObject(object)
            end
        end
    end
end

function SetNoRentPayEnabled(state)
    NoRentPayEnabled = state == true

    for _, connection in ipairs(NoRentPayConnections) do
        pcall(function() connection:Disconnect() end)
    end
    NoRentPayConnections = {}

    if NoRentPayEnabled then
        ScanNoRentPayControllers()

        for _, container in ipairs({
            StarterGui,
            LocalPlayer:FindFirstChild("PlayerGui"),
            LocalPlayer:FindFirstChild("PlayerScripts"),
        }) do
            if container then
                table.insert(NoRentPayConnections, container.DescendantAdded:Connect(function(object)
                    task.defer(ApplyNoRentPayObject, object)
                end))
            end
        end

        
        task.spawn(function()
            while NoRentPayEnabled do
                ScanNoRentPayControllers()
                task.wait(0.5)
            end
        end)
    else
        for scriptObject, previousState in pairs(NoRentPaySavedScripts) do
            pcall(function()
                if scriptObject and scriptObject.Parent then scriptObject.Enabled = previousState end
            end)
            NoRentPaySavedScripts[scriptObject] = nil
        end
        for guiObject, previousState in pairs(NoRentPaySavedGuis) do
            pcall(function()
                if guiObject and guiObject.Parent then guiObject.Enabled = previousState end
            end)
            NoRentPaySavedGuis[guiObject] = nil
        end
    end
end


TacoFPSBoostEnabled = false
TacoFPSBoostSaved = {}
TacoFPSBoostConnection = nil
TacoFPSBoostGlobalState = nil

local function SaveFPSProperty(object, property)
    TacoFPSBoostSaved[object] = TacoFPSBoostSaved[object] or {}
    if TacoFPSBoostSaved[object][property] == nil then
        local ok, value = pcall(function() return object[property] end)
        if ok then TacoFPSBoostSaved[object][property] = value end
    end
end

local function ApplyFPSBoostObject(object)
    if not TacoFPSBoostEnabled or not object then return end

    if object:IsA("BasePart") then
        SaveFPSProperty(object, "Material")
        SaveFPSProperty(object, "Reflectance")
        SaveFPSProperty(object, "CastShadow")
        pcall(function()
            object.Material = Enum.Material.Plastic
            object.Reflectance = 0
            object.CastShadow = false
        end)
    elseif object:IsA("Decal") or object:IsA("Texture") then
        SaveFPSProperty(object, "Transparency")
        pcall(function() object.Transparency = 1 end)
    elseif object:IsA("ParticleEmitter") or object:IsA("Trail") or object:IsA("Beam")
        or object:IsA("Smoke") or object:IsA("Fire") or object:IsA("Sparkles") then
        SaveFPSProperty(object, "Enabled")
        pcall(function() object.Enabled = false end)
    elseif object:IsA("PostEffect") then
        SaveFPSProperty(object, "Enabled")
        pcall(function() object.Enabled = false end)
    end
end

function SetTacoFPSBoost(state)
    TacoFPSBoostEnabled = state == true

    if TacoFPSBoostConnection then
        TacoFPSBoostConnection:Disconnect()
        TacoFPSBoostConnection = nil
    end

    if TacoFPSBoostEnabled then
        TacoFPSBoostGlobalState = {
            GlobalShadows = Lighting.GlobalShadows,
            FogEnd = Lighting.FogEnd,
            TerrainWaterWaveSize = workspace.Terrain.WaterWaveSize,
            TerrainWaterWaveSpeed = workspace.Terrain.WaterWaveSpeed,
            TerrainWaterReflectance = workspace.Terrain.WaterReflectance,
            TerrainWaterTransparency = workspace.Terrain.WaterTransparency,
        }
        pcall(function()
            TacoFPSBoostGlobalState.QualityLevel = settings().Rendering.QualityLevel
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        end)
        pcall(function()
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 100000
            workspace.Terrain.WaterWaveSize = 0
            workspace.Terrain.WaterWaveSpeed = 0
            workspace.Terrain.WaterReflectance = 0
            workspace.Terrain.WaterTransparency = 1
        end)

        for _, object in ipairs(workspace:GetDescendants()) do ApplyFPSBoostObject(object) end
        for _, object in ipairs(Lighting:GetDescendants()) do ApplyFPSBoostObject(object) end

        TacoFPSBoostConnection = workspace.DescendantAdded:Connect(function(object)
            task.defer(ApplyFPSBoostObject, object)
        end)
    else
        for object, properties in pairs(TacoFPSBoostSaved) do
            if object and object.Parent then
                for property, value in pairs(properties) do
                    pcall(function() object[property] = value end)
                end
            end
            TacoFPSBoostSaved[object] = nil
        end

        local saved = TacoFPSBoostGlobalState
        if saved then
            pcall(function()
                Lighting.GlobalShadows = saved.GlobalShadows
                Lighting.FogEnd = saved.FogEnd
                workspace.Terrain.WaterWaveSize = saved.TerrainWaterWaveSize
                workspace.Terrain.WaterWaveSpeed = saved.TerrainWaterWaveSpeed
                workspace.Terrain.WaterReflectance = saved.TerrainWaterReflectance
                workspace.Terrain.WaterTransparency = saved.TerrainWaterTransparency
                if saved.QualityLevel then settings().Rendering.QualityLevel = saved.QualityLevel end
            end)
        end
        TacoFPSBoostGlobalState = nil
    end
end

Library:OnUnload(function()
    SetTacoFPSBoost(false)
end)

function loadAutofarmTabElements()
    
    local FarmTpSection = Tabs.Extra:AddRightGroupbox("Quick TPs")
    local farmSelectedTp = teleportNames[1]
    FarmTpSection:AddDropdown("FarmTpLocation", {
        Text = "Location",
        Values = teleportNames,
        Default = farmSelectedTp,
        Callback = function(v) farmSelectedTp = normalizeDropdownValue(v) end
    })
    FarmTpSection:AddButton("Teleport", function()
        local cf = farmSelectedTp and teleportLocations[farmSelectedTp]
        if cf then Config:Teleport(cf); sendNotification("TP","Teleported to "..tostring(farmSelectedTp)) end
    end)
    FarmTpSection:AddButton("Dynamic Cook Pot", function() TeleportToCookPot() end)


    
    HouseLookup = {}
    selectedHouseTeleportName = nil

    local HouseTpSection = Tabs.Autofarm:AddRightGroupbox("House TPs")
    local houseDropdown = HouseTpSection:AddDropdown("MiamiHouseTeleportDropdown", {
        Text = "Select House",
        Values = {"No houses found"},
        Default = "No houses found",
        Callback = function(selectedLocation)
            selectedHouseTeleportName = normalizeDropdownValue(selectedLocation)
        end,
    })

    local function refreshHouseTeleportList(showNotification)
        table.clear(HouseLookup)
        local values = {}
        local homeFolder = workspace:FindFirstChild("HomeDoorSS")
        if homeFolder then
            for _, House in ipairs(homeFolder:GetChildren()) do
                local Owner = House:FindFirstChild("Owner")
                if Owner and tostring(Owner.Value) ~= "None" and tostring(Owner.Value) ~= "" then
                    local displayName = (tostring(Owner.Value) == LocalPlayer.Name) and "My House" or ("" .. tostring(Owner.Value) .. "'s House")
                    table.insert(values, displayName)
                    HouseLookup[displayName] = House
                end
            end
        end
        table.sort(values)
        if #values == 0 then values = {"No houses found"} end
        selectedHouseTeleportName = values[1]
        if houseDropdown and houseDropdown.SetValues then
            pcall(function() houseDropdown:SetValues(values) end)
        end
        if showNotification == true then
            sendNotification("House TPs", "House list refreshed: " .. tostring(#values))
        end
    end

    HouseTpSection:AddButton("Refresh Houses", function()
        refreshHouseTeleportList(true)
    end)

    HouseTpSection:AddButton("Teleport To House", function()
        if not selectedHouseTeleportName or selectedHouseTeleportName == "No houses found" then
            sendNotification("House TPs", "No house selected.")
            return
        end
        local house = HouseLookup[selectedHouseTeleportName]
        if not house then
            sendNotification("House TPs", "House not found. Refresh the list.")
            return
        end
        local targetPart = house:FindFirstChild("PrimaryPart") or house.PrimaryPart or house:FindFirstChildWhichIsA("BasePart", true)
        if not targetPart then
            sendNotification("House TPs", "No valid house part found.")
            return
        end
        Config:Teleport(targetPart.CFrame + Vector3.new(0, 5, 0))
        sendNotification("House TPs", "Teleported to " .. tostring(selectedHouseTeleportName), 2)
    end)

    
    
    refreshHouseTeleportList(false)
    pcall(function()
        local homeFolder = workspace:FindFirstChild("HomeDoorSS")
        if homeFolder then
            homeFolder.ChildAdded:Connect(function()
                refreshHouseTeleportList(false)
            end)
            homeFolder.ChildRemoved:Connect(function()
                refreshHouseTeleportList(false)
            end)
            for _, House in ipairs(homeFolder:GetChildren()) do
                local Owner = House:FindFirstChild("Owner")
                if Owner then
                    Owner:GetPropertyChangedSignal("Value"):Connect(function()
                        refreshHouseTeleportList(false)
                    end)
                end
            end
        end
    end)

    
    for _, key in ipairs(QUICK_TP_KEYS) do
        local cf = teleportLocations[key]
        FarmTpSection:AddButton(key, function()
            if cf then
                Config:Teleport(cf)
                sendNotification("TP", "Teleported to " .. key, 2)
            else
                sendNotification("TP", "Location not found: " .. key)
            end
        end)
    end


    
    local MyMoneySection = Tabs.Settings:AddLeftGroupbox("My Money")
    local myClean = MyMoneySection:AddLabel("Clean Money: None")
    local myBank  = MyMoneySection:AddLabel("Bank: None")
    local myDirty = MyMoneySection:AddLabel("Dirty Money: None")
    local myMade  = MyMoneySection:AddLabel("Money Made: $0")
    local myLost  = MyMoneySection:AddLabel("Money Lost: $0")

    getgenv().MoneyMadeTotal = getgenv().MoneyMadeTotal or 0
    getgenv().MoneyLostTotal = getgenv().MoneyLostTotal or 0
    local lastClean = nil

    task.spawn(function()
        while task.wait(0.3) do
            local c, d = getMyMoneyValues()
            local b = getBankValue2()
            if lastClean ~= nil and c ~= nil then
                local delta = c - lastClean
                if delta > 0 then getgenv().MoneyMadeTotal = getgenv().MoneyMadeTotal + delta
                elseif delta < 0 then getgenv().MoneyLostTotal = getgenv().MoneyLostTotal + (-delta) end
            end
            lastClean = c
            pcall(function()
                myClean:SetText("Clean Money: "..(c~=nil and formatMoney(c) or "None"))
                myBank:SetText("Bank: "..(b~=nil and formatMoney(b) or "None"))
                myDirty:SetText("Dirty Money: "..(d~=nil and formatMoney(d) or "None"))
                myMade:SetText("Money Made: "..formatMoney(getgenv().MoneyMadeTotal))
                myLost:SetText("Money Lost: "..formatMoney(getgenv().MoneyLostTotal))
            end)
        end
    end)


    
    local AutofarmsSection = Tabs.Autofarm:AddLeftGroupbox("Autofarms")
    local dumpsterFlag = false
    AutofarmsSection:AddButton("Dumpster Autofarm", function()
        if not dumpsterFlag then 
            dumpsterFlag=true
            startDumpsterAutofarm()
            sendNotification("Autofarm","Dumpster started.")
        else 
            dumpsterFlag=false
            stopDumpsterAutofarm()
            sendNotification("Autofarm","Dumpster stopped.") 
        end
    end)
    AutofarmsSection:AddButton("Studio Autofarm", function()
        getgenv().StudioPayFarm = not getgenv().StudioPayFarm
        sendNotification("Autofarm","Studio "..(getgenv().StudioPayFarm and "started." or "stopped."))
    end)
    local constFlag = false
    AutofarmsSection:AddButton("Construction Autofarm", function()
        if not constFlag then 
            constFlag=true
            startConstructionAutofarm()
            sendNotification("Autofarm","Construction started.")
        else 
            constFlag=false
            stopConstructionAutofarm()
            sendNotification("Autofarm","Construction stopped.") 
        end
    end)


    
    local PlayerLocalSection = Tabs.Player:AddLeftGroupbox("Local Player")
    PlayerLocalSection:AddToggle("TacoFPSBoost", {
        Text = "FPS Boost (Low Graphics)",
        Default = false,
        Callback = function(state)
            SetTacoFPSBoost(state)
            sendNotification("FPS Boost", state and "Low graphics enabled" or "Graphics restored")
        end,
    })
    PlayerLocalSection:AddLabel("Disables textures, shadows, particles, and post effects.")
    PlayerLocalSection:AddToggle("AF_AntiFallDamage", {
        Text = "Anti Fall Damage",
        Default = false,
        Callback = function(s)
            if s and LocalPlayer.Character then local f=LocalPlayer.Character:FindFirstChild("FallDamageRagdoll"); if f then f:Destroy() end end
        end
    })
    PlayerLocalSection:AddToggle("AF_AntiJumpCooldown", {
        Text = "Anti Jump Cooldown",
        Default = false,
        Callback = function(state)
            SetAntiJumpCooldownEnabled(state)
            sendNotification("Movement", state and "Jump cooldown bypass enabled." or "Jump cooldown bypass disabled.")
        end
    })
    PlayerLocalSection:AddToggle("AF_InfiniteSleep", {
        Text = "Infinite Sleep",
        Default = false,
        Callback = function(s)
            local sg = LocalPlayer.PlayerGui and LocalPlayer.PlayerGui:FindFirstChild("SleepGui")
            local ss = sg and sg:FindFirstChild("Frame") and sg.Frame:FindFirstChild("sleep") and sg.Frame.sleep:FindFirstChild("SleepBar") and sg.Frame.sleep.SleepBar:FindFirstChild("sleepScript")
            if ss then ss.Enabled = not s end
        end
    })
    PlayerLocalSection:AddToggle("AF_InfiniteHunger", {
        Text = "Infinite Hunger",
        Default = false,
        Callback = function(s)
            local hg = LocalPlayer.PlayerGui and LocalPlayer.PlayerGui:FindFirstChild("Hunger")
            local hs = hg and hg:FindFirstChild("Frame") and hg.Frame:FindFirstChild("Frame") and hg.Frame.Frame:FindFirstChild("Frame") and hg.Frame.Frame.Frame:FindFirstChild("HungerBarScript")
            if hs then hs.Enabled = not s end
        end
    })
    PlayerLocalSection:AddToggle("AF_InfiniteStamina", {
        Text = "Infinite Stamina",
        Default = false,
        Callback = function(s)
            local rg = LocalPlayer.PlayerGui and LocalPlayer.PlayerGui:FindFirstChild("Run")
            local ss = rg and rg:FindFirstChild("Frame") and rg.Frame:FindFirstChild("Frame") and rg.Frame.Frame:FindFirstChild("Frame") and rg.Frame.Frame.Frame:FindFirstChild("StaminaBarScript")
            if ss then ss.Enabled = not s end
        end
    })
    PlayerLocalSection:AddToggle("AF_NoRentPay", {
        Text = "No Rent Pay",
        Default = false,
        Callback = function(state)
            SetNoRentPayEnabled(state)
            sendNotification("Rent", state and "No Rent Pay enabled" or "No Rent Pay disabled")
        end
    })
    PlayerLocalSection:AddToggle("InstantInteraction", {
        Text = "Instant Interaction",
        Default = false,
        Callback = function(s) refreshPrompts(s) end
    })
    PlayerLocalSection:AddToggle("StudioMoneyNotify", {
        Text = "Studio Money Notify",
        Default = false,
        Callback = function(s)
            StudioMoneyNotifyEnabled = s; cleanupStudioMoneyNotify()
            if s then for _, n in ipairs({"StudioPay1","StudioPay2","StudioPay3"}) do watchStudioPayPrompt(n) end end
        end
    })
    PlayerLocalSection:AddToggle("AutoStealLootbags", {
        Text = "Auto Steal Lootbags",
        Default = false,
        Callback = function(s) AutoStealLootbags=s end
    })
    PlayerLocalSection:AddToggle("AutoPickupBags", {
        Text = "Auto Pickup Bags",
        Default = false,
        Callback = function(s) AutoPickupBags=s end
    })
    PlayerLocalSection:AddToggle("AF_DisableBloodEffects", {
        Text = "Disable Blood Effects",
        Default = false,
        Callback = function(s) DisableBloodEffects=s end
    })
    PlayerLocalSection:AddToggle("AF_BypassLockedCars", {
        Text = "Bypass Locked Cars",
        Default = false,
        Callback = function(s) BypassLockedCars=s end
    })
    PlayerLocalSection:AddToggle("AF_NoKnockback", {
        Text = "No Knockback",
        Default = false,
        Callback = function(s) NoKnockback=s end
    })
    PlayerLocalSection:AddToggle("AF_AntiCarFling", {
        Text = "Anti Car Fling",
        Default = false,
        Callback = function(state)
            if state then
                StartAntiCarFling()
                sendNotification("Protection", "Anti Car Fling enabled")
            else
                StopAntiCarFling()
                sendNotification("Protection", "Anti Car Fling disabled")
            end
        end
    })
    PlayerLocalSection:AddToggle("AutoDepositPickedCash", {
        Text = "Auto Deposit Picked Cash",
        Default = false,
        Callback = function(s) AutoCleanMoney=s end
    })
    PlayerLocalSection:AddToggle("AutoStealDroppedCash", {
        Text = "Auto Steal Dropped Cash",
        Default = false,
        Callback = function(s) AutoGrabMoney=s end
    })


    
    local MovementSection = Tabs.Player:AddRightGroupbox("Movement")
    MovementSection:AddToggle("AF_NoCameraBob", {
        Text = "Disable Camera Bobbing",
        Default = false,
        Callback = function(s) NoCameraBob=s end
    })
    MovementSection:AddToggle("AF_SpeedBoost", {
        Text = "WalkSpeed",
        Default = false,
        Callback = function(state) updateSpeedBoostState(state) end
    })
    MovementSection:AddSlider("LuhjayyWalkSpeed", {
        Text = "Change Walk Speed",
        Min = 16, Max = 500, Default = 16, Rounding = 0,
        Callback = function(value) LuhjayyWalk.Speed = value end
    })
    MovementSection:AddLabel("Hold Left Shift for 2× speed.")
    MovementSection:AddToggle("AF_JumpBoost", {
        Text = "Jump Boost",
        Default = false,
        Callback = function(s) updateJumpBoostState(s) end
    })
    MovementSection:AddToggle("AF_InfiniteJump", {
        Text = "Infinite Jump",
        Default = false,
        Callback = function(s) InfJumpEnabled=s end
    })
    MovementSection:AddToggle("AF_Noclip", {
        Text = "Noclip",
        Default = false,
        Callback = function(s) 
            NoclipEnabled=s; if s then enableNoclip() else disableNoclip() end 
        end
    })

    MovementSection:AddToggle("MiamiFlyToggle", {
        Text = "Fly",
        Default = false,
        Callback = function(s)
            if s then
                MiamiFlySetup()
            else
                MiamiFlyCleanup()
                sendNotification("Fly", "Fly disabled", 2)
            end
        end
    })

    MovementSection:AddSlider("MiamiFlySpeed", {
        Text = "Fly Speed",
        Min = 20,
        Max = 300,
        Default = getgenv().MiamiFlyData and getgenv().MiamiFlyData.Speed or 80,
        Rounding = 0,
        Callback = function(v)
            getgenv().MiamiFlyData.Speed = v
        end
    })

    MovementSection:AddLabel("Fly controls: WASD + Space/Shift • Q/E speed")

    
    local CursorEnabled = false
    local CursorGui = nil
    local CursorConnection = nil

    local function EnableCursor()
        UserInputService.MouseIconEnabled = false
        CursorGui = Instance.new("ScreenGui")
        CursorGui.Name = "MiamiCursor"; CursorGui.ResetOnSpawn = false; CursorGui.IgnoreGuiInset = true; CursorGui.DisplayOrder = 999999; CursorGui.Parent = game.CoreGui
        local Dot = Instance.new("Frame"); Dot.Size = UDim2.new(0, 12, 0, 12); Dot.BackgroundColor3 = Color3.fromRGB(0, 255, 100); Dot.BorderSizePixel = 0; Dot.AnchorPoint = Vector2.new(0.5, 0.5); Dot.ZIndex = 999999; Dot.Parent = CursorGui
        Instance.new("UICorner", Dot).CornerRadius = UDim.new(1, 0)
        local Stroke = Instance.new("UIStroke"); Stroke.Thickness = 2; Stroke.Color = Color3.fromRGB(0, 200, 80); Stroke.Parent = Dot
        local TopLine = Instance.new("Frame"); TopLine.Size = UDim2.new(0, 2, 0, 14); TopLine.BackgroundColor3 = Color3.fromRGB(0, 255, 100); TopLine.BorderSizePixel = 0; TopLine.AnchorPoint = Vector2.new(0.5, 1); TopLine.ZIndex = 999999; TopLine.Parent = CursorGui
        local BottomLine = Instance.new("Frame"); BottomLine.Size = UDim2.new(0, 2, 0, 14); BottomLine.BackgroundColor3 = Color3.fromRGB(0, 255, 100); BottomLine.BorderSizePixel = 0; BottomLine.AnchorPoint = Vector2.new(0.5, 0); BottomLine.ZIndex = 999999; BottomLine.Parent = CursorGui
        local LeftLine = Instance.new("Frame"); LeftLine.Size = UDim2.new(0, 14, 0, 2); LeftLine.BackgroundColor3 = Color3.fromRGB(0, 255, 100); LeftLine.BorderSizePixel = 0; LeftLine.AnchorPoint = Vector2.new(1, 0.5); LeftLine.ZIndex = 999999; LeftLine.Parent = CursorGui
        local RightLine = Instance.new("Frame"); RightLine.Size = UDim2.new(0, 14, 0, 2); RightLine.BackgroundColor3 = Color3.fromRGB(0, 255, 100); RightLine.BorderSizePixel = 0; RightLine.AnchorPoint = Vector2.new(0, 0.5); RightLine.ZIndex = 999999; RightLine.Parent = CursorGui
        CursorConnection = RunService.RenderStepped:Connect(function()
            if not CursorEnabled then return end
            local mousePos = UserInputService:GetMouseLocation()
            Dot.Position = UDim2.fromOffset(mousePos.X, mousePos.Y)
            TopLine.Position = UDim2.fromOffset(mousePos.X, mousePos.Y - 10)
            BottomLine.Position = UDim2.fromOffset(mousePos.X, mousePos.Y + 10)
            LeftLine.Position = UDim2.fromOffset(mousePos.X - 10, mousePos.Y)
            RightLine.Position = UDim2.fromOffset(mousePos.X + 10, mousePos.Y)
        end)
    end
    local function DisableCursor()
        UserInputService.MouseIconEnabled = true
        if CursorConnection then CursorConnection:Disconnect(); CursorConnection = nil end
        if CursorGui then CursorGui:Destroy(); CursorGui = nil end
    end

    MovementSection:AddToggle("AF_CustomCrosshair", {
        Text = "Custom Crosshair",
        Default = false,
        Callback = function(s)
            CursorEnabled = s
            if s then EnableCursor(); sendNotification("Crosshair", "Green crosshair enabled!")
            else DisableCursor(); sendNotification("Crosshair", "Crosshair disabled") end
        end
    })


    
    local MiscSection = Tabs.Player:AddLeftGroupbox("Miscellaneous")
    MiscSection:AddToggle("AF_FasterRespawn", {
        Text = "Faster Respawn",
        Default = false,
        Callback = function(s) FasterRespawn=s end
    })
    MiscSection:AddToggle("AF_RespawnWhereDied", {
        Text = "Respawn Where You Died",
        Default = false,
        Callback = function(state)
            SetRespawnWhereYouDied(state)
            sendNotification("Respawn", state and "Death-position respawn enabled." or "Death-position respawn disabled.")
        end
    })
    MiscSection:AddToggle("AF_KeepToolsOnDeath", {
        Text = "Put Guns On Market When I Die",
        Default = false,
        Callback = function(state)
            KeepToolsOnDeath = state
            if state and LocalPlayer.Character then
                SnapshotDeathMarketGuns(LocalPlayer.Character)
            end
        end
    })
    MiscSection:AddLabel("On death, lists every eligible gun for $99,999.")
    MiscSection:AddToggle("AF_InstantRevive", {
        Text = "Instant Revive (auto F on low HP)",
        Default = false,
        Callback = function(s) AutoFOnLowHealth=s end
    })
    MiscSection:AddButton("Get Help - $2000", function()
        if not workspace:FindFirstChild("HospitalPart") then
            sendNotification("Get Help", "HospitalPart not found.")
            return
        end
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CFrame = workspace.HospitalPart.CFrame
            task.wait(0.05)
            local tries = 0
            repeat
                task.wait(0.05)
                pcall(function() fireproximityprompt(workspace.HospitalPart.Prompt, 1) end)
                tries = tries + 1
            until LocalPlayer:GetAttribute("LastACPos") == nil or tries > 200
            sendNotification("Get Help", "Done!")
        end
    end)
    local autoGetHelpEnabled = false
    MiscSection:AddToggle("AutoGetHelp", {
        Text = "Auto Get Help",
        Default = false,
        Callback = function(s)
            autoGetHelpEnabled = s
        end
    })

    task.spawn(function()
        while true do
            task.wait(0.5)
            if autoGetHelpEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                local hum = LocalPlayer.Character.Humanoid
                if hum.Health > 0 and hum.Health < 15 and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    if workspace:FindFirstChild("HospitalPart") then
                        local hrp = LocalPlayer.Character.HumanoidRootPart
                        hrp.CFrame = workspace.HospitalPart.CFrame
                        task.wait(0.05)
                        local tries = 0
                        repeat
                            task.wait(0.05)
                            pcall(function() fireproximityprompt(workspace.HospitalPart.Prompt, 1) end)
                            tries = tries + 1
                        until LocalPlayer:GetAttribute("LastACPos") == nil or tries > 20 or not autoGetHelpEnabled
                    end
                end
            end
        end
    end)

    MiscSection:AddToggle("AF_AntiAFK", {
        Text = "Anti-AFK (20 min)",
        Default = false,
        Callback = function(s) getgenv().AntiAFKEnabled=s end
    })


end




VisualColorPresets = {
    ["White"]=Color3.fromRGB(255,255,255), ["Black"]=Color3.fromRGB(0,0,0),
    ["Red"]=Color3.fromRGB(255,0,0),       ["Green"]=Color3.fromRGB(0,255,0),
    ["Blue"]=Color3.fromRGB(0,120,255),    ["Purple"]=Color3.fromRGB(143,0,255),
    ["Pink"]=Color3.fromRGB(255,80,180),   ["Cyan"]=Color3.fromRGB(0,255,255),
    ["Yellow"]=Color3.fromRGB(255,255,0),  ["Orange"]=Color3.fromRGB(255,140,0),
    ["Lime"]=Color3.fromRGB(130,255,0),    ["Gray"]=Color3.fromRGB(120,120,120),
}
VisualColorNames = {}
for n in pairs(VisualColorPresets) do table.insert(VisualColorNames, n) end
table.sort(VisualColorNames)
function getVisualColor(name, fb) return VisualColorPresets[tostring(name or "")] or fb or Color3.fromRGB(255,255,255) end

WorldVisuals = {
    SaturationEnabled=false, SaturationValue=1,
    StretchEnabled=false,    StretchValue=0.7,
    FogColorEnabled=false,   FogColor=Color3.fromRGB(255,255,255),
    AmbientEnabled=false,    AmbientColor=Color3.fromRGB(255,255,255),
    FieldOfViewEnabled=false,FieldOfViewValue=70,
    Fullbright=false,
}

ESPFlags = {
    Enabled=false, RenderDistance=1400, TeamColor=true,
    Boxes=true, BoxType="Corner", BoxColor=Color3.fromRGB(255,140,0),
    BoxFill=false, BoxFillColor=Color3.fromRGB(255,255,255),
    Healthbar=true, HealthbarNumber=false, HealthbarThickness=3,
    Name=true, Distance=true, Weapon=false,
    FriendMarker=true, FriendColor=Color3.fromRGB(0,255,0),
    TextSize=14, TextColor=Color3.fromRGB(245,245,245),
    Snaplines=false, SnaplineColor=Color3.fromRGB(255,140,0),
    Chams=false, ChamsColor=Color3.fromRGB(255,140,0),
    Skeleton=false, SkeletonColor=Color3.fromRGB(255,255,255),
    LookTracers=false, LookTracerColor=Color3.fromRGB(0,255,255),
}

HitboxVisuals = nil

do
    HitboxVisuals = {
        Enabled = false,
        Part = "Head",
        Multiplier = 5,
        Transparency = 0.45,
        Material = "ForceField",
        Type = "Ball",
        CanCollide = false,
        Massless = true,
        TeamCheck = false,
        Color = Color3.fromRGB(55, 235, 120),
    }

    local CandidateParts = {
        "Head", "HumanoidRootPart", "UpperTorso", "LowerTorso",
        "LeftUpperArm", "LeftLowerArm", "RightUpperArm", "RightLowerArm",
        "LeftUpperLeg", "LeftLowerLeg", "RightUpperLeg", "RightLowerLeg",
        "LeftHand", "RightHand", "LeftFoot", "RightFoot",
    }

    local DefaultPlayerSettings = {}
    local HitboxWorkerBound = {}

    local function capturePartSettings(part)
        if not part or not part:IsA("BasePart") then return nil end
        local settings = {
            Size = part.Size,
            Transparency = part.Transparency,
            CanCollide = part.CanCollide,
            CanQuery = part.CanQuery,
            CanTouch = part.CanTouch,
            Massless = part.Massless,
            Material = part.Material,
            Color = part.Color,
        }
        pcall(function() settings.Shape = part.Shape end)
        local mesh = part:FindFirstChildOfClass("SpecialMesh")
        if mesh then
            settings.MeshId = mesh.MeshId
            settings.MeshScale = mesh.Scale
        end
        return settings
    end

    local function saveDefaultPlayerSettings(player)
        if not player or player == LocalPlayer or not player.Character then return end
        local character = player.Character
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end

        local current = DefaultPlayerSettings[player]
        if current and current.Character == character then return end

        local saved = {
            Character = character,
            Parts = {},
        }

        for _, partName in ipairs(CandidateParts) do
            local part = character:FindFirstChild(partName)
            if part and part:IsA("BasePart") then
                saved.Parts[partName] = capturePartSettings(part)
            end
        end

        DefaultPlayerSettings[player] = saved
    end

    local function restorePartSettings(part, settings)
        if not part or not settings then return end
        for index, value in pairs(settings) do
            if index ~= "MeshId" and index ~= "MeshScale" then
                pcall(function() part[index] = value end)
            end
        end
        local mesh = part:FindFirstChildOfClass("SpecialMesh")
        if mesh then
            if settings.MeshId ~= nil then pcall(function() mesh.MeshId = settings.MeshId end) end
            if settings.MeshScale ~= nil then pcall(function() mesh.Scale = settings.MeshScale end) end
        end
    end

    local function restorePlayerSettings(player)
        local saved = DefaultPlayerSettings[player]
        local character = player and player.Character
        if not saved or not character or saved.Character ~= character then return end
        for partName, settings in pairs(saved.Parts) do
            local part = character:FindFirstChild(partName)
            if part then
                restorePartSettings(part, settings)
            end
        end
    end

    local function applyHitboxToPart(part)
        if not part or not part:IsA("BasePart") then return end

        part.Size = Vector3.new(HitboxVisuals.Multiplier, HitboxVisuals.Multiplier, HitboxVisuals.Multiplier)
        part.Transparency = HitboxVisuals.Transparency
        part.Material = Enum.Material[HitboxVisuals.Material] or Enum.Material.ForceField
        part.Color = HitboxVisuals.Color
        part.CanCollide = HitboxVisuals.CanCollide
        part.CanQuery = true
        part.CanTouch = false
        part.Massless = HitboxVisuals.Massless

        pcall(function()
            if part:IsA("Part") and Enum.PartType[HitboxVisuals.Type] then
                part.Shape = Enum.PartType[HitboxVisuals.Type]
            end
        end)

        local mesh = part:FindFirstChildOfClass("SpecialMesh")
        if mesh then
            pcall(function()
                mesh.Scale = Vector3.new(HitboxVisuals.Multiplier, HitboxVisuals.Multiplier, HitboxVisuals.Multiplier)
            end)
        end
    end

    local function connectHitboxToPlayer(player)
        if not player or player == LocalPlayer or HitboxWorkerBound[player] then return end
        HitboxWorkerBound[player] = true

        task.spawn(function()
            while player and player.Parent do
                task.wait(0.25)

                local character = player.Character
                if not character then continue end

                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if not humanoid then continue end

                saveDefaultPlayerSettings(player)
                local saved = DefaultPlayerSettings[player]
                local sameTeam = HitboxVisuals.TeamCheck and LocalPlayer.Team ~= nil and player.Team == LocalPlayer.Team

                if not HitboxVisuals.Enabled or humanoid.Health <= 0 or humanoid.Sit or sameTeam or not saved or saved.Character ~= character then
                    restorePlayerSettings(player)
                    continue
                end

                restorePlayerSettings(player)

                local selectedPart = character:FindFirstChild(HitboxVisuals.Part)
                    or character:FindFirstChild("Head")
                    or character:FindFirstChild("HumanoidRootPart")

                if selectedPart and selectedPart:IsA("BasePart") then
                    applyHitboxToPart(selectedPart)
                end
            end

            HitboxWorkerBound[player] = nil
            DefaultPlayerSettings[player] = nil
        end)
    end

    for _, player in ipairs(Players:GetPlayers()) do
        connectHitboxToPlayer(player)
    end

    Players.PlayerAdded:Connect(connectHitboxToPlayer)
    Players.PlayerRemoving:Connect(function(player)
        HitboxWorkerBound[player] = nil
        DefaultPlayerSettings[player] = nil
    end)
end

VisualColorCorrection = Lighting:FindFirstChild("MiamiColorCorrection")
if not VisualColorCorrection then
    VisualColorCorrection = Instance.new("ColorCorrectionEffect")
    VisualColorCorrection.Name = "MiamiColorCorrection"
    VisualColorCorrection.Parent = Lighting
end
OriginalWorld = {
    Brightness=Lighting.Brightness, ClockTime=Lighting.ClockTime, FogEnd=Lighting.FogEnd,
    FogColor=Lighting.FogColor, GlobalShadows=Lighting.GlobalShadows,
    OutdoorAmbient=Lighting.OutdoorAmbient, Ambient=Lighting.Ambient,
    FieldOfView=workspace.CurrentCamera and workspace.CurrentCamera.FieldOfView or 70,
    Saturation=VisualColorCorrection.Saturation, TintColor=VisualColorCorrection.TintColor,
}
WorldReset = {Fog=false, Fov=false, Fullbright=false, Ambient=false, Saturation=false}

RunService:BindToRenderStep("MiamiWorldVisuals", Enum.RenderPriority.Camera.Value, function()
    if not (WorldVisuals.StretchEnabled or WorldVisuals.FieldOfViewEnabled
         or WorldVisuals.SaturationEnabled or WorldVisuals.AmbientEnabled
         or WorldVisuals.FogColorEnabled or WorldVisuals.Fullbright)
       and WorldReset.Fov and WorldReset.Saturation and WorldReset.Ambient
       and WorldReset.Fog and WorldReset.Fullbright then
        return
    end
    local cam = workspace.CurrentCamera; if not cam then return end
    if WorldVisuals.StretchEnabled then
        cam.CFrame = cam.CFrame * CFrame.new(0,0,0,1,0,0,0,WorldVisuals.StretchValue,0,0,0,1)
    end
    if WorldVisuals.FieldOfViewEnabled then WorldReset.Fov=false; cam.FieldOfView = WorldVisuals.FieldOfViewValue
    elseif not WorldReset.Fov then WorldReset.Fov=true; cam.FieldOfView = OriginalWorld.FieldOfView or 70 end

    if WorldVisuals.SaturationEnabled then WorldReset.Saturation=false; VisualColorCorrection.Saturation = WorldVisuals.SaturationValue
    elseif not WorldReset.Saturation then WorldReset.Saturation=true; VisualColorCorrection.Saturation = OriginalWorld.Saturation or 0 end

    if WorldVisuals.AmbientEnabled then
        WorldReset.Ambient=false
        VisualColorCorrection.TintColor = WorldVisuals.AmbientColor
        Lighting.Ambient = WorldVisuals.AmbientColor
        Lighting.OutdoorAmbient = WorldVisuals.AmbientColor
    elseif not WorldReset.Ambient then
        WorldReset.Ambient=true
        VisualColorCorrection.TintColor = OriginalWorld.TintColor or Color3.new(1,1,1)
        Lighting.Ambient = OriginalWorld.Ambient
        Lighting.OutdoorAmbient = OriginalWorld.OutdoorAmbient
    end

    if WorldVisuals.FogColorEnabled then WorldReset.Fog=false; Lighting.FogColor = WorldVisuals.FogColor
    elseif not WorldReset.Fog then WorldReset.Fog=true; Lighting.FogColor = OriginalWorld.FogColor end

    if WorldVisuals.Fullbright then
        WorldReset.Fullbright=false
        Lighting.Brightness=2; Lighting.ClockTime=14; Lighting.FogEnd=100000
        Lighting.GlobalShadows=false; Lighting.OutdoorAmbient=Color3.fromRGB(128,128,128)
    elseif not WorldReset.Fullbright then
        WorldReset.Fullbright=true
        Lighting.Brightness=OriginalWorld.Brightness; Lighting.ClockTime=OriginalWorld.ClockTime
        Lighting.FogEnd=OriginalWorld.FogEnd; Lighting.GlobalShadows=OriginalWorld.GlobalShadows
        Lighting.OutdoorAmbient=OriginalWorld.OutdoorAmbient
    end
end)


function createDrawing(className, props)
    if not Drawing or type(Drawing.new) ~= "function" then return {Visible=false, Remove=function() end} end
    local ok, obj = pcall(Drawing.new, className)
    if not ok or not obj then return {Visible=false, Remove=function() end} end
    for k, v in pairs(props or {}) do pcall(function() obj[k] = v end) end
    return obj
end
ESPObjects = {}
HighlightObjects = {}
ESPFriendCache = {}

function isESPUserFriend(target)
    if not target or target == LocalPlayer then return false end
    if ESPFriendCache[target] == nil then
        local ok, isFriend = pcall(function()
            return LocalPlayer:IsFriendsWith(target.UserId)
        end)
        ESPFriendCache[target] = ok and isFriend == true or false
    end
    return ESPFriendCache[target]
end

SkeletonPairs = {
    {"Head","UpperTorso"}, {"UpperTorso","LowerTorso"},
    {"UpperTorso","LeftUpperArm"}, {"LeftUpperArm","LeftLowerArm"}, {"LeftLowerArm","LeftHand"},
    {"UpperTorso","RightUpperArm"}, {"RightUpperArm","RightLowerArm"}, {"RightLowerArm","RightHand"},
    {"LowerTorso","LeftUpperLeg"}, {"LeftUpperLeg","LeftLowerLeg"}, {"LeftLowerLeg","LeftFoot"},
    {"LowerTorso","RightUpperLeg"}, {"RightUpperLeg","RightLowerLeg"}, {"RightLowerLeg","RightFoot"},
}
function createESPObject(player)
    if player == LocalPlayer or ESPObjects[player] then return end
    local box = {}
    for _, n in ipairs({"Top","Bottom","Left","Right","TopLeft","TopRight","BottomLeft","BottomRight"}) do
        box[n] = createDrawing("Line",{Visible=false, Thickness=1.6, Color=ESPFlags.BoxColor})
    end
    local skeleton = {}
    for i = 1, #SkeletonPairs do skeleton[i] = createDrawing("Line",{Visible=false, Thickness=1, Color=ESPFlags.SkeletonColor}) end
    ESPObjects[player] = {
        Box=box,
        Fill          = createDrawing("Square",{Visible=false, Filled=true, Transparency=0.85, Color=ESPFlags.BoxFillColor}),
        HealthOutline = createDrawing("Square",{Visible=false, Filled=false, Color=Color3.fromRGB(0,0,0), Thickness=1}),
        HealthFill    = createDrawing("Square",{Visible=false, Filled=true, Color=Color3.fromRGB(0,255,0)}),
        HealthText    = createDrawing("Text",{Visible=false, Center=true, Outline=true, Size=ESPFlags.TextSize, Color=Color3.fromRGB(255,255,255)}),
        Name          = createDrawing("Text",{Visible=false, Center=true, Outline=true, Size=ESPFlags.TextSize, Color=ESPFlags.TextColor}),
        FriendTag     = createDrawing("Text",{Visible=false, Center=true, Outline=true, Size=ESPFlags.TextSize, Color=ESPFlags.FriendColor, Text="(F)"}),
        Distance      = createDrawing("Text",{Visible=false, Center=true, Outline=true, Size=ESPFlags.TextSize, Color=ESPFlags.TextColor}),
        Weapon        = createDrawing("Text",{Visible=false, Center=true, Outline=true, Size=ESPFlags.TextSize, Color=ESPFlags.TextColor}),
        Snapline      = createDrawing("Line",{Visible=false, Thickness=1.2, Color=ESPFlags.SnaplineColor}),
        LookTracer    = createDrawing("Line",{Visible=false, Thickness=1, Color=ESPFlags.LookTracerColor}),
        Skeleton      = skeleton,
    }
end
function hideESPObject(obj)
    if not obj then return end
    if obj.Box then for _, l in pairs(obj.Box) do l.Visible=false end end
    if obj.Skeleton then for _, l in ipairs(obj.Skeleton) do l.Visible=false end end
    for _, k in ipairs({"Fill","HealthOutline","HealthFill","HealthText","Name","FriendTag","Distance","Weapon","Snapline","LookTracer"}) do
        if obj[k] then obj[k].Visible=false end
    end
end
function removeESPObject(player)
    local obj = ESPObjects[player]
    if obj then
        if obj.Box then for _, l in pairs(obj.Box) do pcall(function() l:Remove() end) end end
        if obj.Skeleton then for _, l in ipairs(obj.Skeleton) do pcall(function() l:Remove() end) end end
        for _, k in ipairs({"Fill","HealthOutline","HealthFill","HealthText","Name","FriendTag","Distance","Weapon","Snapline","LookTracer"}) do
            if obj[k] then pcall(function() obj[k]:Remove() end) end
        end
        ESPObjects[player] = nil
    end
    if HighlightObjects[player] then pcall(function() HighlightObjects[player]:Destroy() end); HighlightObjects[player]=nil end
    ESPFriendCache[player] = nil
end
function getESPColor(player, def)
    if ESPFlags.TeamColor and player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then
        return Color3.fromRGB(0,120,255)
    end
    return def
end
function updateLine(line, from, to, color)
    if not line then return end
    line.From=from; line.To=to; line.Color=color; line.Visible=true
end
for _, p in ipairs(Players:GetPlayers()) do createESPObject(p) end
Players.PlayerAdded:Connect(createESPObject)
Players.PlayerRemoving:Connect(removeESPObject)

_espHiddenOnce = false
function hideESPForPlayer(player)
    hideESPObject(ESPObjects[player])
    if HighlightObjects[player] then
        HighlightObjects[player].Enabled = false
    end
end

function updateESPForPlayer(player, cam)
    if player == LocalPlayer then
        hideESPForPlayer(player)
        return
    end

    createESPObject(player)
    local obj = ESPObjects[player]
    local char = player.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")

    if not (obj and char and hum and root and hum.Health > 0) then
        hideESPForPlayer(player)
        return
    end

    local localRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local distance = localRoot and (root.Position - localRoot.Position).Magnitude or (root.Position - cam.CFrame.Position).Magnitude
    if distance > ESPFlags.RenderDistance then
        hideESPForPlayer(player)
        return
    end

    local rootPos, onScreen = cam:WorldToViewportPoint(root.Position)
    if not onScreen or rootPos.Z <= 0 then
        hideESPForPlayer(player)
        return
    end

    local size = char:GetExtentsSize()
    local top = cam:WorldToViewportPoint((root.CFrame * CFrame.new(0, size.Y/2, 0)).Position)
    local bottom = cam:WorldToViewportPoint((root.CFrame * CFrame.new(0, -size.Y/2, 0)).Position)
    if top.Z <= 0 or bottom.Z <= 0 then
        hideESPForPlayer(player)
        return
    end

    local height = math.max(math.abs(bottom.Y - top.Y), 2)
    local width  = math.max(height * 0.58, 2)
    local x, y   = top.X - width/2, top.Y
    local boxColor = getESPColor(player, ESPFlags.BoxColor)
    local textColor = ESPFlags.TextColor

    if ESPFlags.BoxFill then
        obj.Fill.Position = Vector2.new(x, y)
        obj.Fill.Size = Vector2.new(width, height)
        obj.Fill.Color = ESPFlags.BoxFillColor
        obj.Fill.Transparency = 0.85
        obj.Fill.Visible = true
    else
        obj.Fill.Visible = false
    end

    if ESPFlags.Boxes then
        local tl, tr = Vector2.new(x, y), Vector2.new(x + width, y)
        local bl, br = Vector2.new(x, y + height), Vector2.new(x + width, y + height)
        local corner = math.min(width, height) * 0.28
        if ESPFlags.BoxType == "Full" then
            updateLine(obj.Box.Top, tl, tr, boxColor)
            updateLine(obj.Box.Bottom, bl, br, boxColor)
            updateLine(obj.Box.Left, tl, bl, boxColor)
            updateLine(obj.Box.Right, tr, br, boxColor)
            obj.Box.TopLeft.Visible = false
            obj.Box.TopRight.Visible = false
            obj.Box.BottomLeft.Visible = false
            obj.Box.BottomRight.Visible = false
        else
            obj.Box.Top.Visible = false
            obj.Box.Bottom.Visible = false
            obj.Box.Left.Visible = false
            obj.Box.Right.Visible = false
            updateLine(obj.Box.TopLeft, tl, tl + Vector2.new(corner, 0), boxColor)
            updateLine(obj.Box.Left, tl, tl + Vector2.new(0, corner), boxColor)
            updateLine(obj.Box.TopRight, tr, tr - Vector2.new(corner, 0), boxColor)
            updateLine(obj.Box.Right, tr, tr + Vector2.new(0, corner), boxColor)
            updateLine(obj.Box.BottomLeft, bl, bl + Vector2.new(corner, 0), boxColor)
            updateLine(obj.Box.Bottom, bl, bl - Vector2.new(0, corner), boxColor)
            updateLine(obj.Box.BottomRight, br, br - Vector2.new(corner, 0), boxColor)
            updateLine(obj.Box.Top, br, br - Vector2.new(0, corner), boxColor)
        end
    else
        for _, l in pairs(obj.Box) do
            l.Visible = false
        end
    end

    if ESPFlags.Healthbar then
        local pct = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
        local bh = height * pct
        obj.HealthOutline.Position = Vector2.new(x - 7, y)
        obj.HealthOutline.Size = Vector2.new(ESPFlags.HealthbarThickness + 2, height)
        obj.HealthOutline.Visible = true
        obj.HealthFill.Position = Vector2.new(x - 6, y + height - bh)
        obj.HealthFill.Size = Vector2.new(ESPFlags.HealthbarThickness, bh)
        obj.HealthFill.Color = Color3.fromRGB(255 - (255 * pct), 255 * pct, 0)
        obj.HealthFill.Visible = true
        if ESPFlags.HealthbarNumber then
            obj.HealthText.Text = tostring(math.floor(hum.Health))
            obj.HealthText.Position = Vector2.new(x - 12, y + height - bh)
            obj.HealthText.Size = ESPFlags.TextSize
            obj.HealthText.Visible = true
        else
            obj.HealthText.Visible = false
        end
    else
        obj.HealthOutline.Visible = false
        obj.HealthFill.Visible = false
        obj.HealthText.Visible = false
    end

    local bottomOffset = 2
    if ESPFlags.Name then
        obj.Name.Text = player.DisplayName ~= player.Name and (player.DisplayName .. " (@" .. player.Name .. ")") or player.Name
        obj.Name.Position = Vector2.new(x + width/2, y - ESPFlags.TextSize - 2)
        obj.Name.Size = ESPFlags.TextSize
        obj.Name.Color = textColor
        obj.Name.Visible = true

        if ESPFlags.FriendMarker and isESPUserFriend(player) then
            local nameWidth = (#tostring(obj.Name.Text) * ESPFlags.TextSize * 0.28)
            pcall(function()
                if obj.Name.TextBounds then nameWidth = obj.Name.TextBounds.X / 2 end
            end)
            obj.FriendTag.Text = "(F)"
            obj.FriendTag.Position = Vector2.new((x + width/2) - nameWidth - 10, y - ESPFlags.TextSize - 2)
            obj.FriendTag.Size = ESPFlags.TextSize
            obj.FriendTag.Color = ESPFlags.FriendColor
            obj.FriendTag.Visible = true
        else
            obj.FriendTag.Visible = false
        end
    else
        obj.Name.Visible = false
        obj.FriendTag.Visible = false
    end

    if ESPFlags.Distance then
        obj.Distance.Text = tostring(math.floor(distance)) .. "m"
        obj.Distance.Position = Vector2.new(x + width/2, y + height + bottomOffset)
        obj.Distance.Size = ESPFlags.TextSize
        obj.Distance.Color = textColor
        obj.Distance.Visible = true
        bottomOffset = bottomOffset + ESPFlags.TextSize + 1
    else
        obj.Distance.Visible = false
    end

    if ESPFlags.Weapon then
        local tool = char:FindFirstChildOfClass("Tool")
        obj.Weapon.Text = tool and ("[" .. tool.Name .. "]") or "[None]"
        obj.Weapon.Position = Vector2.new(x + width/2, y + height + bottomOffset)
        obj.Weapon.Size = ESPFlags.TextSize
        obj.Weapon.Color = textColor
        obj.Weapon.Visible = true
    else
        obj.Weapon.Visible = false
    end

    if ESPFlags.Snaplines then
        obj.Snapline.From = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y)
        obj.Snapline.To = Vector2.new(rootPos.X, rootPos.Y)
        obj.Snapline.Color = getESPColor(player, ESPFlags.SnaplineColor)
        obj.Snapline.Visible = true
    else
        obj.Snapline.Visible = false
    end

    if ESPFlags.LookTracers and char:FindFirstChild("Head") then
        local head = char.Head
        local p1, o1 = cam:WorldToViewportPoint(head.Position)
        local p2, o2 = cam:WorldToViewportPoint(head.Position + head.CFrame.LookVector * 10)
        if o1 and o2 and p1.Z > 0 and p2.Z > 0 then
            obj.LookTracer.From = Vector2.new(p1.X, p1.Y)
            obj.LookTracer.To = Vector2.new(p2.X, p2.Y)
            obj.LookTracer.Color = ESPFlags.LookTracerColor
            obj.LookTracer.Visible = true
        else
            obj.LookTracer.Visible = false
        end
    else
        obj.LookTracer.Visible = false
    end

    if ESPFlags.Skeleton then
        for i, pair in ipairs(SkeletonPairs) do
            local a, b = char:FindFirstChild(pair[1]), char:FindFirstChild(pair[2])
            if a and b and obj.Skeleton[i] then
                local pa, oa = cam:WorldToViewportPoint(a.Position)
                local pb, ob = cam:WorldToViewportPoint(b.Position)
                if oa and ob and pa.Z > 0 and pb.Z > 0 then
                    obj.Skeleton[i].From = Vector2.new(pa.X, pa.Y)
                    obj.Skeleton[i].To = Vector2.new(pb.X, pb.Y)
                    obj.Skeleton[i].Color = ESPFlags.SkeletonColor
                    obj.Skeleton[i].Visible = true
                else
                    obj.Skeleton[i].Visible = false
                end
            elseif obj.Skeleton[i] then
                obj.Skeleton[i].Visible = false
            end
        end
    else
        for _, l in ipairs(obj.Skeleton) do
            l.Visible = false
        end
    end

    if ESPFlags.Chams then
        local h = HighlightObjects[player]
        if not h or not h.Parent then
            h = Instance.new("Highlight")
            h.Name = "MiamiESPHighlight"
            h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            h.Parent = CoreGui
            HighlightObjects[player] = h
        end
        h.Adornee = char
        h.FillColor = getESPColor(player, ESPFlags.ChamsColor)
        h.OutlineColor = Color3.fromRGB(255, 255, 255)
        h.FillTransparency = 0.55
        h.OutlineTransparency = 0.1
        h.Enabled = true
    elseif HighlightObjects[player] then
        HighlightObjects[player].Enabled = false
    end
end

RunService.RenderStepped:Connect(function()
    if not ESPFlags.Enabled then
        if not _espHiddenOnce then
            _espHiddenOnce = true
            for _, p in ipairs(Players:GetPlayers()) do
                hideESPForPlayer(p)
            end
        end
        return
    end

    _espHiddenOnce = false
    local cam = workspace.CurrentCamera
    if not cam then return end

    for _, p in ipairs(Players:GetPlayers()) do
        local ok, err = pcall(updateESPForPlayer, p, cam)
        if not ok then
            warn("[Miami ESP] Failed to update player ESP for", p and p.Name or "unknown", err)
            hideESPForPlayer(p)
        end
    end
end)


function loadVisualsTabElements()
    
    local WorldSection = Tabs.Visuals:AddLeftGroupbox("World Visuals")
    WorldSection:AddToggle("WorldFullbright", {Text="Fullbright", Default=false, Callback=function(v) WorldVisuals.Fullbright=v end})
    WorldSection:AddToggle("LuhjayyRealisticGraphics", {
        Text = "Realistic Graphics",
        Default = false,
        Callback = function(state)
            RealisticGraphics = state
            if state then
                pcall(function() Lighting.Technology = Enum.Technology.Future end)
                Lighting.GlobalShadows = true
                Lighting.Brightness = 3
            else
                pcall(function() Lighting.Technology = Enum.Technology.Compatibility end)
                Lighting.GlobalShadows = false
                Lighting.Brightness = 1
            end
            sendNotification("Graphics", state and "Realistic Graphics enabled" or "Realistic Graphics disabled")
        end
    })
    WorldSection:AddToggle("WorldSaturation", {Text="Enable Saturation", Default=false, Callback=function(v) WorldVisuals.SaturationEnabled=v end})
    WorldSection:AddSlider("WorldSaturationValue", {Text="Saturation Value", Min=0, Max=200, Default=100, Rounding=0, Callback=function(v) WorldVisuals.SaturationValue=v/100 end})
    WorldSection:AddToggle("WorldFOV", {Text="Enable FOV", Default=false, Callback=function(v) WorldVisuals.FieldOfViewEnabled=v end})
    WorldSection:AddSlider("WorldFOVValue", {Text="FOV Value", Min=30, Max=120, Default=70, Rounding=0, Callback=function(v) WorldVisuals.FieldOfViewValue=v end})
    WorldSection:AddToggle("WorldStretch", {Text="Enable Stretch", Default=false, Callback=function(v) WorldVisuals.StretchEnabled=v end})
    WorldSection:AddSlider("WorldStretchValue", {Text="Stretch Value", Min=0.1, Max=2, Default=0.7, Rounding = 2, Callback=function(v) WorldVisuals.StretchValue=v end})
    WorldSection:AddToggle("WorldFog", {Text="Enable Fog Color", Default=false, Callback=function(v) WorldVisuals.FogColorEnabled=v end})
    WorldSection:AddDropdown("WorldFogColor", {
        Text="Fog Color", Values=VisualColorNames, Default="White",
        Callback=function(v) WorldVisuals.FogColor = getVisualColor(normalizeDropdownValue(v), Color3.fromRGB(255,255,255)) end
    })
    WorldSection:AddToggle("WorldAmbient", {Text="Enable Ambient Tint", Default=false, Callback=function(v) WorldVisuals.AmbientEnabled=v end})
    WorldSection:AddDropdown("WorldAmbientColor", {
        Text="Ambient Color", Values=VisualColorNames, Default="White",
        Callback=function(v) WorldVisuals.AmbientColor = getVisualColor(normalizeDropdownValue(v), Color3.fromRGB(255,255,255)) end
    })


    
    local ESPMainSection = Tabs.Visuals:AddRightGroupbox("Player ESP")
    ESPMainSection:AddToggle("ESPEnabled", {Text="ESP Enabled", Default=false, Callback=function(v) ESPFlags.Enabled=v end})
    ESPMainSection:AddSlider("ESPRenderDistance", {Text="Render Distance", Min=50, Max=5000, Default=1400, Rounding=0, Callback=function(v) ESPFlags.RenderDistance=v end})
    ESPMainSection:AddToggle("ESPTeamColor", {Text="Team Color", Default=true, Callback=function(v) ESPFlags.TeamColor=v end})
    ESPMainSection:AddToggle("ESPBoxes", {Text="Boxes", Default=true, Callback=function(v) ESPFlags.Boxes=v end})
    ESPMainSection:AddDropdown("ESPBoxType", {Text="Box Type", Values={"Corner","Full"}, Default="Corner", Callback=function(v) ESPFlags.BoxType = tostring(normalizeDropdownValue(v)) end})
    ESPMainSection:AddDropdown("ESPBoxColor", {Text="Box Color", Values=VisualColorNames, Default="Orange", Callback=function(v) ESPFlags.BoxColor = getVisualColor(normalizeDropdownValue(v), Color3.fromRGB(255,140,0)) end})
    ESPMainSection:AddToggle("ESPBoxFill", {Text="Box Fill", Default=false, Callback=function(v) ESPFlags.BoxFill=v end})
    ESPMainSection:AddDropdown("ESPBoxFillColor", {Text="Box Fill Color", Values=VisualColorNames, Default="White", Callback=function(v) ESPFlags.BoxFillColor = getVisualColor(normalizeDropdownValue(v), Color3.fromRGB(255,255,255)) end})
    ESPMainSection:AddToggle("ESPHealthbar", {Text="Healthbar", Default=true, Callback=function(v) ESPFlags.Healthbar=v end})
    ESPMainSection:AddToggle("ESPHealthbarNumber", {Text="Healthbar Number", Default=false, Callback=function(v) ESPFlags.HealthbarNumber=v end})
    ESPMainSection:AddSlider("ESPHealthbarThickness", {Text="Healthbar Thickness", Min=1, Max=10, Default=3, Rounding=0, Callback=function(v) ESPFlags.HealthbarThickness=v end})
    ESPMainSection:AddToggle("ESPChams", {Text="Chams", Default=false, Callback=function(v) ESPFlags.Chams=v end})
    ESPMainSection:AddDropdown("ESPChamsColor", {Text="Chams Color", Values=VisualColorNames, Default="Orange", Callback=function(v) ESPFlags.ChamsColor = getVisualColor(normalizeDropdownValue(v), Color3.fromRGB(255,140,0)) end})

    
    local HitboxSection = Tabs.Visuals:AddRightGroupbox("Hitbox")
    HitboxSection:AddToggle("VisualHitboxEnabled", {Text="Enable Hitbox", Default=false, Callback=function(v) HitboxVisuals.Enabled=v end})
    HitboxSection:AddDropdown("VisualHitboxPart", {Text="Part", Values={"Head","HumanoidRootPart","UpperTorso","LowerTorso","LeftUpperArm","LeftLowerArm","RightUpperArm","RightLowerArm","LeftUpperLeg","LeftLowerLeg","RightUpperLeg","RightLowerLeg"}, Default="Head", Callback=function(v) HitboxVisuals.Part=tostring(normalizeDropdownValue(v)) end})
    HitboxSection:AddSlider("VisualHitboxMultiplier", {Text="Multiplier", Min=1, Max=15, Default=5, Rounding=0, Callback=function(v) HitboxVisuals.Multiplier=v end})
    HitboxSection:AddSlider("VisualHitboxTransparency", {Text="Transparency", Min=0, Max=1, Default=0.45, Rounding=2, Callback=function(v) HitboxVisuals.Transparency=v end})
    HitboxSection:AddDropdown("VisualHitboxMaterial", {Text="Material", Values={"ForceField","Neon","Plastic","SmoothPlastic","Glass"}, Default="ForceField", Callback=function(v) HitboxVisuals.Material=tostring(normalizeDropdownValue(v)) end})
    HitboxSection:AddDropdown("VisualHitboxType", {Text="Type", Values={"Block","Ball","Cylinder"}, Default="Block", Callback=function(v) HitboxVisuals.Type=tostring(normalizeDropdownValue(v)) end})
    HitboxSection:AddToggle("VisualHitboxTeamCheck", {Text="Skip Teammates", Default=false, Callback=function(v) HitboxVisuals.TeamCheck=v end})

    
    local ESPTextSection = Tabs.Visuals:AddRightGroupbox("ESP Text / Lines")
    ESPTextSection:AddToggle("ESPName", {Text="Name", Default=true, Callback=function(v) ESPFlags.Name=v end})
    ESPTextSection:AddToggle("ESPFriendMarker", {Text="Friend Marker (F)", Default=true, Callback=function(v) ESPFlags.FriendMarker=v end})
    ESPTextSection:AddDropdown("ESPFriendColor", {Text="Friend Marker Color", Values=VisualColorNames, Default="Green", Callback=function(v) ESPFlags.FriendColor = getVisualColor(normalizeDropdownValue(v), Color3.fromRGB(0,255,0)) end})
    ESPTextSection:AddToggle("ESPDistance", {Text="Distance", Default=true, Callback=function(v) ESPFlags.Distance=v end})
    ESPTextSection:AddToggle("ESPWeapon", {Text="Weapon", Default=false, Callback=function(v) ESPFlags.Weapon=v end})
    ESPTextSection:AddSlider("ESPTextSize", {Text="Text Size", Min=8, Max=20, Default=14, Rounding=0, Callback=function(v) ESPFlags.TextSize=v end})
    ESPTextSection:AddDropdown("ESPTextColor", {Text="Text Color", Values=VisualColorNames, Default="White", Callback=function(v) ESPFlags.TextColor = getVisualColor(normalizeDropdownValue(v), Color3.fromRGB(255,255,255)) end})
    ESPTextSection:AddToggle("ESPSnaplines", {Text="Snaplines", Default=false, Callback=function(v) ESPFlags.Snaplines=v end})
    ESPTextSection:AddDropdown("ESPSnaplineColor", {Text="Snapline Color", Values=VisualColorNames, Default="Orange", Callback=function(v) ESPFlags.SnaplineColor = getVisualColor(normalizeDropdownValue(v), Color3.fromRGB(255,140,0)) end})
    ESPTextSection:AddToggle("ESPSkeleton", {Text="Skeleton", Default=false, Callback=function(v) ESPFlags.Skeleton=v end})
    ESPTextSection:AddDropdown("ESPSkeletonColor", {Text="Skeleton Color", Values=VisualColorNames, Default="White", Callback=function(v) ESPFlags.SkeletonColor = getVisualColor(normalizeDropdownValue(v), Color3.fromRGB(255,255,255)) end})
    ESPTextSection:AddToggle("ESPLookTracers", {Text="Look Tracers", Default=false, Callback=function(v) ESPFlags.LookTracers=v end})
    ESPTextSection:AddDropdown("ESPLookTracerColor", {Text="Look Tracer Color", Values=VisualColorNames, Default="Cyan", Callback=function(v) ESPFlags.LookTracerColor = getVisualColor(normalizeDropdownValue(v), Color3.fromRGB(0,255,255)) end})
end


LuhjayyAllowedMeleeTools = {
    Cleaver = true,
    Axe = true,
    Blade = true,
    Machete = true,
}

function GetLuhjayyAttackEvent(tool)
    if tool then
        local meleeSystem = tool:FindFirstChild("MeleeSystem")
        if meleeSystem and meleeSystem:FindFirstChild("AttackEvent") then
            return meleeSystem.AttackEvent
        end
    end
    return nil
end

function GetLuhjayyKnife(player, autoEquip)
    local character = player and player.Character
    local backpack = player and player:FindFirstChild("Backpack")
    if character then
        for _, tool in ipairs(character:GetChildren()) do
            if tool:IsA("Tool") and LuhjayyAllowedMeleeTools[tool.Name] then
                return tool
            end
        end
    end
    if backpack then
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") and LuhjayyAllowedMeleeTools[tool.Name] then
                if autoEquip and character then
                    local humanoid = character:FindFirstChildOfClass("Humanoid")
                    if humanoid then
                        pcall(function() humanoid:EquipTool(tool) end)
                        task.wait(0.15)
                    end
                end
                return tool
            end
        end
    end
    return nil
end

LuhjayyBladeKillEnabled = false
LuhjayyBladeKillWorkerRunning = false

local function FindExactBlade(player, autoEquip)
    local character = player and player.Character
    local backpack = player and player:FindFirstChild("Backpack")
    local blade = (character and character:FindFirstChild("Blade"))
        or (backpack and backpack:FindFirstChild("Blade"))
    if blade and blade:IsA("Tool") and autoEquip and blade.Parent == backpack and character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            pcall(function() humanoid:EquipTool(blade) end)
            task.wait(0.15)
        end
    end
    return blade
end

local function GetBladePurchaseCFrame(object)
    if not object then return nil end
    if object:IsA("BasePart") then return object.CFrame end
    if object:IsA("Model") then
        local part = object.PrimaryPart or object:FindFirstChildWhichIsA("BasePart", true)
        if part then return part.CFrame end
        local ok, pivot = pcall(function() return object:GetPivot() end)
        if ok then return pivot end
    end
    return GetBladePurchaseCFrame(object.Parent)
end

function AutoBuyBladeForKnifeKill()
    local existing = FindExactBlade(LocalPlayer, true)
    if existing then return existing end

    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return nil, "Character is not ready" end

    local bladeObject = (workspace:FindFirstChild("GUNS") and workspace.GUNS:FindFirstChild("Blade"))
        or workspace:FindFirstChild("Blade", true)
    local prompt = bladeObject and bladeObject:FindFirstChildWhichIsA("ProximityPrompt", true)
    local targetCF = GetBladePurchaseCFrame(prompt and prompt.Parent or bladeObject)
    local originalCF = root.CFrame

    if prompt and targetCF then
        local oldHold = prompt.HoldDuration
        local purchaseOK = pcall(function()
            Config:Teleport(targetCF)
            task.wait(0.35)
            prompt.HoldDuration = 0
            fireproximityprompt(prompt)
            task.wait(0.35)
            prompt.HoldDuration = oldHold
            Config:Teleport(originalCF)
        end)
        pcall(function() prompt.HoldDuration = oldHold end)
        pcall(function() if root.Parent then Config:Teleport(originalCF) end end)
        if not purchaseOK then return nil, "Blade purchase prompt failed" end
    else
        
        local shopRemote = ReplicatedStorage:FindFirstChild("ShopRemote")
        if not shopRemote then return nil, "Blade shop was not found" end
        local ok = pcall(function() shopRemote:InvokeServer("Blade") end)
        if not ok then return nil, "Blade purchase failed" end
    end

    local deadline = os.clock() + 5
    repeat
        task.wait(0.15)
        existing = FindExactBlade(LocalPlayer, true)
    until existing or os.clock() >= deadline or not LuhjayyBladeKillEnabled

    return existing, existing and nil or "Blade was not received"
end

function KillSelectedPlayerWithLuhjayyKnife()
    local target = getSelectedTargetPlayer()
    local targetCharacter = target and target.Character
    local targetRoot = targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart")
    local targetHumanoid = targetCharacter and targetCharacter:FindFirstChildOfClass("Humanoid")
    if not target or not targetRoot or not targetHumanoid or targetHumanoid.Health <= 0 then
        return false, "Select a valid living player"
    end

    local blade, buyError = AutoBuyBladeForKnifeKill()
    if not blade then return false, buyError or "Could not buy Blade" end

    local attackEvent = GetLuhjayyAttackEvent(blade)
    if not attackEvent then return false, "Blade has no MeleeSystem.AttackEvent" end

    local character = LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then return false, "Your character is not ready" end

    local oldPosition = root.CFrame
    local started = os.clock()
    while LuhjayyBladeKillEnabled
        and targetHumanoid.Parent and targetHumanoid.Health > 0
        and targetRoot.Parent and root.Parent
        and os.clock() - started < 30 do
        root.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 1.5)
        pcall(function() attackEvent:FireServer() end)
        task.wait(0.05)
    end

    if root.Parent then
        pcall(function() Config:Teleport(oldPosition) end)
    end
    return targetHumanoid.Health <= 0, targetHumanoid.Health <= 0 and nil or "Attack stopped"
end

function StartAutoBladeKill()
    if LuhjayyBladeKillWorkerRunning then return end
    LuhjayyBladeKillWorkerRunning = true
    task.spawn(function()
        local lastProblem = nil
        while LuhjayyBladeKillEnabled do
            local success, problem = KillSelectedPlayerWithLuhjayyKnife()
            if success then
                local target = getSelectedTargetPlayer()
                sendNotification("Blade Kill", (target and target.Name or "Target") .. " was eliminated.")
                lastProblem = nil
                task.wait(0.75)
            else
                if problem and problem ~= lastProblem and LuhjayyBladeKillEnabled then
                    sendNotification("Blade Kill", tostring(problem))
                    lastProblem = problem
                end
                task.wait(1)
            end
        end
        LuhjayyBladeKillWorkerRunning = false
    end)
end

function loadKnifeAuraElements()
    
    TargetGroup:AddDivider()
    TargetGroup:AddLabel("🔪 Auto Blade Kill")
    TargetGroup:AddToggle("LuhjayyAutoBladeKill", {
        Text = "Auto Buy Blade + Kill Player",
        Default = false,
        Callback = function(state)
            LuhjayyBladeKillEnabled = state
            if state then
                sendNotification("Blade Kill", "Enabled — Blade will be bought automatically.")
                StartAutoBladeKill()
            else
                sendNotification("Blade Kill", "Stopped.")
            end
        end,
    })
end


pcall(loadAutofarmTabElements)
pcall(loadVisualsTabElements)
pcall(loadKnifeAuraElements)
pcall(loadSafeTabFunctions)
pcall(loadMiamiUtilitySections)

do



MenuGroup = Tabs.Settings:AddLeftGroupbox("Menu Settings")
MenuGroup:AddDropdown("UITheme", {
    Text = "UI Theme",
    Values = Library.ThemeNames,
    Default = Library.CurrentTheme,
    Callback = function(v) Library:SetTheme(v) end,
})

MenuGroup:AddDropdown("UIFont", {
    Text = "UI Font",
    Values = Library.FontNames,
    Default = Library.FontNames[1],
    Callback = function(v) Library:SetUIFont(v) end,
})

MenuGroup:AddSlider("UIScale", {
    Text = "UI Scale",
    Min = 40, Max = 200,
    Default = math.floor(Library:GetUIScale() * 100 + 0.5),
    Rounding = 0,
    Suffix = "%",
    Callback = function(v) Library:SetUIScale(v / 100) end,
})

MenuGroup:AddLabel("Script: hitboxers.gg", true)
MenuGroup:AddLabel("Discord: discord.gg/hitboxers.gg", true)
MenuGroup:AddLabel("Game: THA BRONX 3", true)
MenuGroup:AddLabel("Developed By Zap", true)
MenuGroup:AddLabel("Status: Premium Visuals Loaded ", true)
MenuGroup:AddDivider()

MenuGroup:AddLabel("Menu bind")
    :AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })

MenuGroup:AddButton("Eject", function()
    Library:Unload()
end)

Library:OnUnload(function()
    if MimaiUI and MimaiUI.Gui then
        pcall(function() MimaiUI.Gui:Destroy() end)
    end
    pcall(function()
        local toggleGui = getgenv().MiamiMenuToggleGui
        if toggleGui then toggleGui:Destroy() end
        getgenv().MiamiMenuToggleGui = nil
    end)
    pcall(function()
        if getgenv().MiamiHeadTagControl then
            getgenv().MiamiHeadTagControl.Destroy()
        else
            local character = LocalPlayer.Character
            local head = character and character:FindFirstChild("Head")
            local tag = head and head:FindFirstChild("Miami_DiscordTag")
            if tag then tag:Destroy() end
        end
    end)
    print("Unloaded!")
end)

MenuGroup:AddButton('Rejoin Server', function()
	game:GetService('TeleportService'):TeleportToPlaceInstance(game.PlaceId, game.JobId)
	Library:Notify('Rejoining Server!', 10)
end)

MenuGroup:AddButton('Server Hop', function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/BENZZY420/SERVERHOP/refs/heads/main/SERVERHOP"))()
end)

MenuGroup:AddButton({
    Text = 'Copy Discord',
    Func = function()
       setclipboard("https://discord.gg/hitboxers.gg")
       Library:Notify("Copied Discord to clipboard", 10)
    end,
})

executorName = identifyexecutor and identifyexecutor() or "Unknown"
MenuGroup:AddLabel("Executor: "..executorName, true)

getgenv().MiamiHeadTagSettings = getgenv().MiamiHeadTagSettings or {}
local HeadTagSettings = getgenv().MiamiHeadTagSettings
if HeadTagSettings.StyleVersion ~= 4 then
    HeadTagSettings.Enabled = HeadTagSettings.Enabled ~= false
    HeadTagSettings.Text = HeadTagSettings.Text or "discord.gg/hitboxers.gg"
    HeadTagSettings.Size = 32
    HeadTagSettings.Height = 3.4
    HeadTagSettings.Style = "Taco Green"
    HeadTagSettings.Font = "GothamBlack"
    HeadTagSettings.Color = "Gold"
    HeadTagSettings.Rainbow = false
    HeadTagSettings.Pulse = true
    HeadTagSettings.Speed = 8
    HeadTagSettings.StyleVersion = 4
end

HeadTagGroup = Tabs.Settings:AddRightGroupbox("hitboxers.gg Head Text")
HeadTagGroup:AddToggle("MiamiHeadTagEnabled", {
    Text = "Enable Head Text", Default = HeadTagSettings.Enabled,
    Callback = function(value)
        HeadTagSettings.Enabled = value
        if getgenv().MiamiHeadTagControl then
            if value then getgenv().MiamiHeadTagControl.Refresh() else getgenv().MiamiHeadTagControl.Destroy() end
        end
    end
})
HeadTagGroup:AddInput("MiamiHeadTagText", {
    Text = "Text", Default = HeadTagSettings.Text, Placeholder = "Text above your head",
    Numeric = false, Finished = true,
    Callback = function(value)
        HeadTagSettings.Text = tostring(value or "") ~= "" and tostring(value) or "discord.gg/hitboxers.gg"
    end
})
HeadTagGroup:AddDropdown("MiamiHeadTagStyle", {
    Text = "Text Animation",
    Values = {"Taco Green", "Taco Wave", "Rainbow Wave", "Fire", "Ice", "Toxic", "Royal"},
    Default = HeadTagSettings.Style,
    Callback = function(value) HeadTagSettings.Style = normalizeDropdownValue(value) end
})
HeadTagGroup:AddDropdown("MiamiHeadTagFont", {
    Text = "Font Choice", Values = {"GothamBlack", "GothamBold", "Arcade", "SciFi", "Cartoon", "Code"},
    Default = HeadTagSettings.Font,
    Callback = function(value) HeadTagSettings.Font = normalizeDropdownValue(value) end
})
HeadTagGroup:AddDropdown("TacoHeadTagColor", {
    Text = "Text Color",
    Values = {"Gold", "White", "Orange", "Red", "Green", "Blue", "Purple", "Pink", "Cyan", "Use Animation"},
    Default = HeadTagSettings.Color,
    Callback = function(value)
        HeadTagSettings.Color = normalizeDropdownValue(value)
    end
})
HeadTagGroup:AddToggle("MiamiHeadTagRainbow", {
    Text = "Rainbow Override", Default = HeadTagSettings.Rainbow,
    Callback = function(value) HeadTagSettings.Rainbow = value end
})
HeadTagGroup:AddToggle("MiamiHeadTagPulse", {
    Text = "Text Pulse", Default = HeadTagSettings.Pulse,
    Callback = function(value) HeadTagSettings.Pulse = value end
})
HeadTagGroup:AddSlider("MiamiHeadTagSize", {
    Text = "Text Size", Min = 18, Max = 52, Default = HeadTagSettings.Size, Rounding = 0,
    Callback = function(value) HeadTagSettings.Size = value end
})
HeadTagGroup:AddSlider("MiamiHeadTagHeight", {
    Text = "Height", Min = 2, Max = 7, Default = HeadTagSettings.Height, Rounding = 1,
    Callback = function(value) HeadTagSettings.Height = value end
})
HeadTagGroup:AddSlider("MiamiHeadTagSpeed", {
    Text = "Movement Speed", Min = 1, Max = 20, Default = HeadTagSettings.Speed, Rounding = 0,
    Callback = function(value) HeadTagSettings.Speed = value end
})
HeadTagGroup:AddButton("Refresh Head Text", function()
    if getgenv().MiamiHeadTagControl then getgenv().MiamiHeadTagControl.Refresh() end
end)



Library.ToggleKeybind = Options.MenuKeybind


task.spawn(function()
    local Palettes = {
        ["Taco Wave"] = {Color3.fromRGB(255, 198, 48), Color3.fromRGB(255, 236, 143), Color3.fromRGB(255, 155, 40)},
        ["Taco Green"] = {Color3.fromRGB(255, 198, 48), Color3.fromRGB(255, 236, 143), Color3.fromRGB(255, 198, 48)},
        ["Fire"] = {Color3.fromRGB(255, 30, 0), Color3.fromRGB(255, 225, 0), Color3.fromRGB(255, 80, 0)},
        ["Ice"] = {Color3.fromRGB(0, 125, 255), Color3.fromRGB(245, 255, 255), Color3.fromRGB(0, 255, 235)},
        ["Toxic"] = {Color3.fromRGB(40, 255, 0), Color3.fromRGB(220, 255, 0), Color3.fromRGB(0, 145, 55)},
        ["Royal"] = {Color3.fromRGB(115, 0, 255), Color3.fromRGB(255, 210, 45), Color3.fromRGB(220, 0, 255)},
    }
    local Fonts = {
        GothamBlack=Enum.Font.GothamBlack, GothamBold=Enum.Font.GothamBold,
        Arcade=Enum.Font.Arcade, SciFi=Enum.Font.SciFi, Cartoon=Enum.Font.Cartoon, Code=Enum.Font.Code,
    }
    local HeadTagColors = {
        Gold = Color3.fromRGB(55, 235, 120),
        White = Color3.fromRGB(255, 255, 255),
        Orange = Color3.fromRGB(255, 138, 45),
        Red = Color3.fromRGB(255, 70, 76),
        Green = Color3.fromRGB(56, 232, 130),
        Blue = Color3.fromRGB(70, 151, 255),
        Purple = Color3.fromRGB(172, 100, 255),
        Pink = Color3.fromRGB(255, 105, 185),
        Cyan = Color3.fromRGB(54, 236, 255),
    }

    local function destroyHeadTag(character)
        local head = character and character:FindFirstChild("Head")
        local tag = head and head:FindFirstChild("Miami_DiscordTag")
        if tag then tag:Destroy() end
    end

    local function attachMiamiHeadTag(character)
        local settings = getgenv().MiamiHeadTagSettings or {}
        if not settings.Enabled then destroyHeadTag(character); return end
        pcall(function()
            local head = character and character:WaitForChild("Head", 5)
            if not head then return end
            destroyHeadTag(character)

            local billboard = Instance.new("BillboardGui")
            billboard.Name = "Miami_DiscordTag"
            billboard.Parent = head
            billboard.Adornee = head
            billboard.Size = UDim2.fromOffset(480, 70)
            billboard.StudsOffset = Vector3.new(0, settings.Height or 3.4, 0)
            billboard.AlwaysOnTop = true
            billboard.MaxDistance = 700
            billboard.LightInfluence = 0

            
            local label = Instance.new("TextLabel")
            label.Name = "AnimatedText"
            label.BackgroundTransparency = 1
            label.Size = UDim2.fromScale(1, 1)
            label.TextXAlignment = Enum.TextXAlignment.Center
            label.TextYAlignment = Enum.TextYAlignment.Center
            label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
            label.TextStrokeTransparency = 0.08
            label.Parent = billboard

            local gradient = Instance.new("UIGradient")
            gradient.Parent = label

            local timeValue = 0
            while label.Parent do
                local current = getgenv().MiamiHeadTagSettings or {}
                local text = tostring(current.Text or "discord.gg/hitboxers.gg")
                local size = tonumber(current.Size) or 32
                local speed = tonumber(current.Speed) or 8
                local style = current.Style or "Taco Green"
                timeValue = timeValue + 0.003 * speed

                local sequence
                local selectedColor = HeadTagColors[current.Color or "Gold"]
                if current.Rainbow or style == "Rainbow Wave" then
                    local hue = timeValue % 1
                    sequence = ColorSequence.new{
                        ColorSequenceKeypoint.new(0, Color3.fromHSV(hue, 1, 1)),
                        ColorSequenceKeypoint.new(0.5, Color3.fromHSV((hue + 0.25) % 1, 1, 1)),
                        ColorSequenceKeypoint.new(1, Color3.fromHSV((hue + 0.5) % 1, 1, 1)),
                    }
                elseif selectedColor and current.Color ~= "Use Animation" then
                    local highlight = selectedColor:Lerp(Color3.fromRGB(255, 255, 255), 0.30)
                    sequence = ColorSequence.new{
                        ColorSequenceKeypoint.new(0, selectedColor),
                        ColorSequenceKeypoint.new(0.5, highlight),
                        ColorSequenceKeypoint.new(1, selectedColor),
                    }
                else
                    local colors = Palettes[style] or Palettes["Taco Green"]
                    sequence = ColorSequence.new{
                        ColorSequenceKeypoint.new(0, colors[1]),
                        ColorSequenceKeypoint.new(0.5, colors[2]),
                        ColorSequenceKeypoint.new(1, colors[3]),
                    }
                end

                label.Text = text
                label.TextSize = size
                label.Font = Fonts[current.Font or "GothamBlack"] or Enum.Font.GothamBlack
                billboard.StudsOffset = Vector3.new(0, tonumber(current.Height) or 3.4, 0)
                billboard.Size = UDim2.fromOffset(math.clamp(#text * size * 0.66 + 50, 300, 700), size + 38)
                gradient.Color = sequence

                
                gradient.Offset = Vector2.new(math.sin(timeValue * math.pi * 2) * 0.48, 0)
                gradient.Rotation = math.sin(timeValue * math.pi) * 18

                if current.Pulse then
                    label.TextSize = size + math.sin(timeValue * math.pi * 2) * 1.5
                end
                task.wait(0.03)
            end
        end)
    end

    getgenv().MiamiHeadTagControl = {
        Refresh=function() if LocalPlayer.Character then task.defer(attachMiamiHeadTag, LocalPlayer.Character) end end,
        Destroy=function() if LocalPlayer.Character then destroyHeadTag(LocalPlayer.Character) end end,
    }
    if LocalPlayer.Character then task.defer(attachMiamiHeadTag, LocalPlayer.Character) end
    LocalPlayer.CharacterAdded:Connect(attachMiamiHeadTag)
end)

task.defer(function()
    local currentKey = "RightShift"
    pcall(function()
        if Options and Options.MenuKeybind and Options.MenuKeybind.Value then
            currentKey = tostring(Options.MenuKeybind.Value)
        end
    end)
    setWatermarkState("Loaded ", currentKey)
end)







task.delay(2, function()
    getgenv().MiamiSuppressNotifications = false
end)
end
