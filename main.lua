-- Vanzyxxx Modular Executor - Mobile Friendly
-- Core Loader by Alfreadrorw1 (Updated: Loading Screen)

-- SERVICES
local Services = {
    Players = game:GetService("Players"),
    Workspace = game:GetService("Workspace"),
    RunService = game:GetService("RunService"),
    UserInputService = game:GetService("UserInputService"),
    TweenService = game:GetService("TweenService"),
    CoreGui = game:GetService("CoreGui"),
    Lighting = game:GetService("Lighting"),
    HttpService = game:GetService("HttpService"),
    StarterGui = game:GetService("StarterGui"),
    TeleportService = game:GetService("TeleportService"),
    MarketplaceService = game:GetService("MarketplaceService")
}

-- GLOBALS
local LocalPlayer = Services.Players.LocalPlayer
local Camera = Services.Workspace.CurrentCamera

-- CONFIG GLOBAL
local Config = {
    FlySpeed = 50, Flying = false, Noclip = false, InfJump = false,
    SpeedHack = false, SpeedVal = 50, WallClimb = false,
    ESP_Box = false, ESP_Name = false, ESP_Health = false,
    MenuTitle = "Vanzyxxx", RainbowTheme = false,
    CustomColor = Color3.fromRGB(160, 32, 240),
    AutoPlaying = false, TapTP = false, LastSaveTime = 0,
    OnReset = Instance.new("BindableEvent"),
    OnFeatureLoaded = Instance.new("BindableEvent")
}

-- ASSETS
local LogoURL = "https://files.catbox.moe/io8o2d.png"
local LocalPath = "VanzyLogo.jpg"
pcall(function() if not isfile(LocalPath) then writefile(LocalPath, game:HttpGet(LogoURL)) end end)
local FinalLogo = (getcustomasset and isfile(LocalPath)) and getcustomasset(LocalPath) or LogoURL

-- UI LIBRARY
local UILibrary = {}
local UIRefs = { MainFrame = nil, Sidebar = nil, Content = nil, Title = nil }

local Theme = {
    Main = Color3.fromRGB(20, 10, 30),
    Sidebar = Color3.fromRGB(30, 15, 45),
    Accent = Config.CustomColor,
    Text = Color3.fromRGB(255, 255, 255),
    Button = Color3.fromRGB(45, 25, 60),
    ButtonDark = Color3.fromRGB(35, 20, 50),
    ButtonRed = Color3.fromRGB(100, 30, 30),
    Confirm = Color3.fromRGB(40, 100, 40)
}

-- THEME LOOP
spawn(function()
    while true do
        if Config.RainbowTheme then
            local hue = tick() % 5 / 5
            Theme.Accent = Color3.fromHSV(hue, 1, 1)
            Config.CustomColor = Theme.Accent
        else
            Theme.Accent = Config.CustomColor
        end
        if UIRefs.MainStroke then UIRefs.MainStroke.Color = Theme.Accent end
        if UIRefs.OpenBtnStroke then UIRefs.OpenBtnStroke.Color = Theme.Accent end
        if UIRefs.Title then UIRefs.Title.TextColor3 = Theme.Accent end
        task.wait(0.05)
    end
end)

function UILibrary:Create()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "Vanzyxxx"
    ScreenGui.ResetOnSpawn = false
    
    local function GetGuiParent()
        if gethui then return gethui() end
        if syn and syn.protect_gui then local sg = Instance.new("ScreenGui"); syn.protect_gui(sg); sg.Parent = Services.CoreGui; return sg end
        return Services.CoreGui
    end
    ScreenGui.Parent = GetGuiParent()
    
    -- OPEN BUTTON
    local OpenBtn = Instance.new("ImageButton", ScreenGui); OpenBtn.Name="Open"; OpenBtn.Size=UDim2.new(0,50,0,50); OpenBtn.Position=UDim2.new(0.05,0,0.2,0); OpenBtn.BackgroundColor3=Theme.Main; OpenBtn.Image=FinalLogo; Instance.new("UICorner",OpenBtn).CornerRadius=UDim.new(1,0); local OS=Instance.new("UIStroke",OpenBtn); OS.Color=Theme.Accent; OS.Thickness=2; UIRefs.OpenBtnStroke=OS

    -- MAIN FRAME
    local MainFrame = Instance.new("Frame", ScreenGui); MainFrame.Name="Main"; MainFrame.Size=UDim2.new(0,400,0,220); MainFrame.Position=UDim2.new(0.5,-200,0.5,-110); MainFrame.BackgroundColor3=Theme.Main; MainFrame.ClipsDescendants=true; MainFrame.Visible=false; Instance.new("UICorner",MainFrame).CornerRadius=UDim.new(0,12); local MS=Instance.new("UIStroke",MainFrame); MS.Color=Theme.Accent; MS.Thickness=2; UIRefs.MainFrame=MainFrame; UIRefs.MainStroke=MS; local UIScale=Instance.new("UIScale",MainFrame); UIScale.Scale=0

    -- TITLE
    local Title = Instance.new("TextLabel", MainFrame); Title.Size=UDim2.new(1,-100,0,30); Title.Position=UDim2.new(0,10,0,0); Title.BackgroundTransparency=1; Title.Text=Config.MenuTitle; Title.Font=Enum.Font.GothamBlack; Title.TextSize=16; Title.TextColor3=Theme.Accent; Title.TextXAlignment=Enum.TextXAlignment.Left; UIRefs.Title=Title

    -- CONTROLS
    local BtnContainer = Instance.new("Frame", MainFrame); BtnContainer.Size=UDim2.new(0,120,0,30); BtnContainer.Position=UDim2.new(1,-125,0,0); BtnContainer.BackgroundTransparency=1
    local CloseX = Instance.new("TextButton", BtnContainer); CloseX.Size=UDim2.new(0,30,0,30); CloseX.Position=UDim2.new(1,-30,0,0); CloseX.BackgroundTransparency=1; CloseX.Text="X"; CloseX.TextColor3=Color3.fromRGB(255,50,50); CloseX.Font=Enum.Font.GothamBlack; CloseX.TextSize=18
    local LayoutBtn = Instance.new("TextButton", BtnContainer); LayoutBtn.Size=UDim2.new(0,30,0,30); LayoutBtn.Position=UDim2.new(1,-60,0,0); LayoutBtn.BackgroundTransparency=1; LayoutBtn.Text="+"; LayoutBtn.TextColor3=Color3.fromRGB(255,200,50); LayoutBtn.Font=Enum.Font.GothamBlack; LayoutBtn.TextSize=20
    local MinBtn = Instance.new("TextButton", BtnContainer); MinBtn.Size=UDim2.new(0,30,0,30); MinBtn.Position=UDim2.new(1,-90,0,0); MinBtn.BackgroundTransparency=1; MinBtn.Text="_"; MinBtn.TextColor3=Theme.Accent; MinBtn.Font=Enum.Font.GothamBlack; MinBtn.TextSize=18

    -- LAYOUT
    local Sidebar = Instance.new("ScrollingFrame", MainFrame); Sidebar.Size=UDim2.new(0,110,1,-35); Sidebar.Position=UDim2.new(0,0,0,35); Sidebar.BackgroundColor3=Theme.Sidebar; Sidebar.ScrollBarThickness=0; Sidebar.BorderSizePixel=0; UIRefs.Sidebar=Sidebar
    local SideLayout = Instance.new("UIListLayout", Sidebar); SideLayout.HorizontalAlignment=Enum.HorizontalAlignment.Center; SideLayout.Padding=UDim.new(0,6); Instance.new("UIPadding", Sidebar).PaddingTop=UDim.new(0,10)
    local Content = Instance.new("Frame", MainFrame); Content.Size=UDim2.new(1,-110,1,-35); Content.Position=UDim2.new(0,110,0,35); Content.BackgroundTransparency=1; UIRefs.Content=Content

    -- DRAG & TOGGLE
    local function Drag(f, h) h=h or f; local d,ds,sp; h.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then d=true; ds=i.Position; sp=f.Position; i.Changed:Connect(function() if i.UserInputState==Enum.UserInputState.End then d=false end end) end end); Services.UserInputService.InputChanged:Connect(function(i) if (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) and d then local dt=i.Position-ds; f.Position=UDim2.new(sp.X.Scale,sp.X.Offset+dt.X,sp.Y.Scale,sp.Y.Offset+dt.Y) end end) end
    Drag(MainFrame); Drag(OpenBtn)

    local function ToggleMenu(state) if state then MainFrame.Visible=true; OpenBtn.Visible=false; Services.TweenService:Create(UIScale, TweenInfo.new(0.4, Enum.EasingStyle.Back), {Scale=1}):Play() else local tw=Services.TweenService:Create(UIScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Scale=0}); tw:Play(); tw.Completed:Connect(function() MainFrame.Visible=false; OpenBtn.Visible=true end) end end
    local isVertical = false
    local function ToggleLayout() isVertical = not isVertical; if isVertical then LayoutBtn.Text="-"; Services.TweenService:Create(MainFrame, TweenInfo.new(0.3), {Size=UDim2.new(0,220,0,400)}):Play(); Sidebar.Size=UDim2.new(0,60,1,-35); Content.Size=UDim2.new(1,-60,1,-35); Content.Position=UDim2.new(0,60,0,35); MainFrame.Position=UDim2.new(0.5,-110,0.5,-200) else LayoutBtn.Text="+"; Services.TweenService:Create(MainFrame, TweenInfo.new(0.3), {Size=UDim2.new(0,400,0,220)}):Play(); Sidebar.Size=UDim2.new(0,110,1,-35); Content.Size=UDim2.new(1,-110,1,-35); Content.Position=UDim2.new(0,110,0,35); MainFrame.Position=UDim2.new(0.5,-200,0.5,-110) end end

    OpenBtn.MouseButton1Click:Connect(function() ToggleMenu(true) end); MinBtn.MouseButton1Click:Connect(function() ToggleMenu(false) end); LayoutBtn.MouseButton1Click:Connect(ToggleLayout)

    -- TAB SYSTEM
    local Tabs = {}
    function UILibrary:Tab(name)
        local TabBtn = Instance.new("TextButton", Sidebar); TabBtn.Size=UDim2.new(0.85,0,0,28); TabBtn.BackgroundColor3=Theme.Button; TabBtn.Text=name; TabBtn.TextColor3=Color3.fromRGB(200,200,200); TabBtn.Font=Enum.Font.GothamBold; TabBtn.TextSize=10; Instance.new("UICorner",TabBtn).CornerRadius=UDim.new(0,6)
        local TabContent = Instance.new("ScrollingFrame", Content); TabContent.Size=UDim2.new(1,-5,1,0); TabContent.BackgroundTransparency=1; TabContent.ScrollBarThickness=2; TabContent.Visible=false; TabContent.AutomaticCanvasSize=Enum.AutomaticSize.Y; Instance.new("UIListLayout", TabContent).Padding=UDim.new(0,5); Instance.new("UIPadding", TabContent).PaddingTop=UDim.new(0,5)
        
        TabBtn.MouseButton1Click:Connect(function() for _,t in pairs(Tabs) do t.Content.Visible=false; t.Button.BackgroundColor3=Theme.Button; t.Button.TextColor3=Color3.fromRGB(200,200,200) end; TabContent.Visible=true; TabBtn.BackgroundColor3=Theme.Accent; TabBtn.TextColor3=Color3.new(1,1,1) end)
        table.insert(Tabs, {Button=TabBtn, Content=TabContent})
        
        local El = {}
        function El:Button(t,c,f) local b=Instance.new("TextButton",TabContent); b.Size=UDim2.new(1,0,0,26); b.BackgroundColor3=c or Theme.Button; b.Text=t; b.TextColor3=Color3.new(1,1,1); b.Font=Enum.Font.Gotham; b.TextSize=11; Instance.new("UICorner",b).CornerRadius=UDim.new(0,6); b.MouseButton1Click:Connect(function() pcall(f) end) end
        function El:Toggle(t,f) local fr=Instance.new("Frame",TabContent); fr.Size=UDim2.new(1,0,0,26); fr.BackgroundColor3=Theme.Button; Instance.new("UICorner",fr).CornerRadius=UDim.new(0,6); local l=Instance.new("TextLabel",fr); l.Size=UDim2.new(0.65,0,1,0); l.Position=UDim2.new(0.05,0,0,0); l.BackgroundTransparency=1; l.Text=t; l.TextColor3=Color3.new(1,1,1); l.TextXAlignment=Enum.TextXAlignment.Left; l.Font=Enum.Font.Gotham; l.TextSize=11; local b=Instance.new("TextButton",fr); b.Size=UDim2.new(0,30,0,18); b.Position=UDim2.new(0.75,0,0.15,0); b.BackgroundColor3=Color3.fromRGB(60,60,60); b.Text=""; Instance.new("UICorner",b).CornerRadius=UDim.new(1,0); local s=false; b.MouseButton1Click:Connect(function() s=not s; b.BackgroundColor3=s and Theme.Accent or Color3.fromRGB(60,60,60); if f then pcall(f,s) end end) end
        function El:Label(t) local l=Instance.new("TextLabel",TabContent); l.Size=UDim2.new(1,0,0,20); l.BackgroundTransparency=1; l.Text=t; l.TextColor3=Theme.Accent; l.Font=Enum.Font.GothamBold; l.TextSize=10; l.TextXAlignment=Enum.TextXAlignment.Left end
        function El:Input(p,f) local fr=Instance.new("Frame",TabContent); fr.Size=UDim2.new(1,0,0,26); fr.BackgroundColor3=Color3.fromRGB(35,35,35); Instance.new("UICorner",fr).CornerRadius=UDim.new(0,6); local b=Instance.new("TextBox",fr); b.Size=UDim2.new(0.9,0,1,0); b.Position=UDim2.new(0.05,0,0,0); b.BackgroundTransparency=1; b.Text=""; b.PlaceholderText=p; b.TextColor3=Color3.new(1,1,1); b.Font=Enum.Font.Gotham; b.TextSize=11; b:GetPropertyChangedSignal("Text"):Connect(function() if f then pcall(f,b.Text) end end) end
        function El:Slider(t,min,max,f) local fr=Instance.new("Frame",TabContent);fr.Size=UDim2.new(1,0,0,32);fr.BackgroundColor3=Theme.Button;Instance.new("UICorner",fr).CornerRadius=UDim.new(0,6);local l=Instance.new("TextLabel",fr);l.Size=UDim2.new(1,0,0.5,0);l.Position=UDim2.new(0.05,0,0,0);l.BackgroundTransparency=1;l.Text=t;l.TextColor3=Color3.new(1,1,1);l.TextSize=10;l.TextXAlignment=Enum.TextXAlignment.Left;local b=Instance.new("TextButton",fr);b.Size=UDim2.new(0.9,0,0.3,0);b.Position=UDim2.new(0.05,0,0.6,0);b.BackgroundColor3=Color3.fromRGB(30,30,30);b.Text="";local fil=Instance.new("Frame",b);fil.Size=UDim2.new(0,0,1,0);fil.BackgroundColor3=Theme.Accent;b.MouseButton1Down:Connect(function() local m;m=Services.RunService.RenderStepped:Connect(function() local s=math.clamp((Services.UserInputService:GetMouseLocation().X-b.AbsolutePosition.X)/b.AbsoluteSize.X,0,1);fil.Size=UDim2.new(s,0,1,0);if f then pcall(f,min+(max-min)*s) end;if not Services.UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then m:Disconnect() end end) end) end
        function El:Container(h) local c=Instance.new("ScrollingFrame",TabContent); c.Size=UDim2.new(1,0,0,h); c.BackgroundColor3=Color3.fromRGB(25,25,25); c.ScrollBarThickness=2; Instance.new("UICorner",c).CornerRadius=UDim.new(0,6); Instance.new("UIListLayout",c).Padding=UDim.new(0,2); c.AutomaticCanvasSize=Enum.AutomaticSize.Y; return c end
        return El
    end
    
    CloseX.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)
    spawn(function() task.wait(0.5); if #Tabs>0 then Tabs[1].Button:Fire() end end)
    return UILibrary, ScreenGui
end

-- Create UI
local UI, ScreenGui = UILibrary:Create()

-- >>> LOADING SCREEN SYSTEM <<<
local function CreateLoadingScreen()
    local LoaderFrame = Instance.new("Frame", ScreenGui)
    LoaderFrame.Name = "Loader"
    LoaderFrame.Size = UDim2.new(0, 300, 0, 150)
    LoaderFrame.Position = UDim2.new(0.5, -150, 0.5, -75)
    LoaderFrame.BackgroundColor3 = Theme.Main
    LoaderFrame.ZIndex = 100
    
    Instance.new("UICorner", LoaderFrame).CornerRadius = UDim.new(0, 10)
    local LS = Instance.new("UIStroke", LoaderFrame)
    LS.Color = Theme.Accent
    LS.Thickness = 2
    
    -- Logo / Title
    local LTitle = Instance.new("TextLabel", LoaderFrame)
    LTitle.Size = UDim2.new(1, 0, 0, 40)
    LTitle.Position = UDim2.new(0, 0, 0.1, 0)
    LTitle.BackgroundTransparency = 1
    LTitle.Text = "Vanzyxxx Modular"
    LTitle.Font = Enum.Font.GothamBlack
    LTitle.TextSize = 20
    LTitle.TextColor3 = Theme.Accent
    LTitle.ZIndex = 101
    
    -- Status Text
    local LStatus = Instance.new("TextLabel", LoaderFrame)
    LStatus.Size = UDim2.new(1, 0, 0, 20)
    LStatus.Position = UDim2.new(0, 0, 0.45, 0)
    LStatus.BackgroundTransparency = 1
    LStatus.Text = "Initializing..."
    LStatus.Font = Enum.Font.Gotham
    LStatus.TextSize = 14
    LStatus.TextColor3 = Theme.Text
    LStatus.ZIndex = 101
    
    -- Progress Bar BG
    local BarBG = Instance.new("Frame", LoaderFrame)
    BarBG.Size = UDim2.new(0.8, 0, 0, 10)
    BarBG.Position = UDim2.new(0.1, 0, 0.7, 0)
    BarBG.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    BarBG.ZIndex = 101
    Instance.new("UICorner", BarBG).CornerRadius = UDim.new(1, 0)
    
    -- Progress Fill
    local BarFill = Instance.new("Frame", BarBG)
    BarFill.Size = UDim2.new(0, 0, 1, 0)
    BarFill.BackgroundColor3 = Theme.Accent
    BarFill.ZIndex = 102
    Instance.new("UICorner", BarFill).CornerRadius = UDim.new(1, 0)
    
    return LoaderFrame, LStatus, BarFill
end

-- FEATURE LOADER
local FeatureLoader = {}
local GitHubBaseURL = "https://raw.githubusercontent.com/alfreadrorw1/VanzyModular/main/"

local FeatureList = {
    -- Movement
    {category = "Movement", name = "fly", url = GitHubBaseURL.."features/Movement/fly.lua"},
    {category = "Movement", name = "speed", url = GitHubBaseURL.."features/Movement/speed.lua"},
    {category = "Movement", name = "infinityJump", url = GitHubBaseURL.."features/Movement/infinityJump.lua"},
    {category = "Movement", name = "noclip", url = GitHubBaseURL.."features/Movement/noclip.lua"},
    {category = "Movement", name = "wallClimb", url = GitHubBaseURL.."features/Movement/wallClimb.lua"},
    -- Visual
    {category = "Visual", name = "esp", url = GitHubBaseURL.."features/Visual/esp.lua"},
    {category = "Visual", name = "fullbright", url = GitHubBaseURL.."features/Visual/fullbright.lua"},
    -- Auras & World
    {category = "Aura", name = "aura", url = GitHubBaseURL.."features/Aura/aura.lua"},
    {category = "Sky", name = "sky", url = GitHubBaseURL.."features/Sky/sky.lua"},
    -- Checkpoint
    {category = "Checkpoint", name = "saveLoadCP", url = GitHubBaseURL.."features/Checkpoint/saveLoadCP.lua"},
    -- Settings
    {category = "Settings", name = "theme", url = GitHubBaseURL.."features/Settings/theme.lua"},
    {category = "Settings", name = "fpsBoost", url = GitHubBaseURL.."features/Settings/fpsBoost.lua"}
}

function FeatureLoader:LoadAllFeatures()
    local Loader, StatusLbl, Bar = CreateLoadingScreen()
    local total = #FeatureList
    
    -- Create tabs first
    local categories = {}
    for _, feature in ipairs(FeatureList) do
        if not categories[feature.category] then
            categories[feature.category] = UI:Tab(feature.category)
        end
    end
    
    -- Load loop
    for i, feature in ipairs(FeatureList) do
        StatusLbl.Text = "Loading: " .. feature.name
        Services.TweenService:Create(Bar, TweenInfo.new(0.2), {Size = UDim2.new(i/total, 0, 1, 0)}):Play()
        
        local success, result = pcall(function()
            local code = game:HttpGet(feature.url, true)
            if not code then return nil end
            local func = loadstring(code)
            if not func then return nil end
            return func()
        end)
        
        if success and type(result) == "function" then
            pcall(result, UI, Services, Config, Theme)
        else
            warn("Failed to load: " .. feature.name)
        end
        
        task.wait(0.1) -- Small delay for effect
    end
    
    StatusLbl.Text = "Done! Opening Menu..."
    task.wait(0.5)
    
    -- Remove Loader
    Services.TweenService:Create(Loader, TweenInfo.new(0.5), {Position = UDim2.new(0.5, -150, 1.2, 0)}):Play()
    task.wait(0.5)
    Loader:Destroy()
    
    -- Show Notification once
    Services.StarterGui:SetCore("SendNotification", {Title = "Vanzyxxx", Text = "All Systems Ready!", Duration = 5})
end

-- ANTI AFK
local vu = game:GetService("VirtualUser")
LocalPlayer.Idled:Connect(function() vu:Button2Down(Vector2.new(0,0), Services.Workspace.CurrentCamera.CFrame); task.wait(1); vu:Button2Up(Vector2.new(0,0), Services.Workspace.CurrentCamera.CFrame) end)

-- START
spawn(function()
    task.wait(0.5)
    FeatureLoader:LoadAllFeatures()
end)

return {UI = UI, Services = Services, Config = Config}