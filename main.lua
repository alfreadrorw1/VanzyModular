-- Vanzyxxx Modular Executor - Core Loader (FINAL STABLE VERSION)
-- Fix: Tabs Disappearing & Loop Crash Prevention

-- [1] CLEANUP OLD UI
local CoreGui = game:GetService("CoreGui")
if CoreGui:FindFirstChild("Vanzyxxx") then CoreGui.Vanzyxxx:Destroy() end
if CoreGui:FindFirstChild("VanzyxxxLoading") then CoreGui.VanzyxxxLoading:Destroy() end

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

-- CONFIG
local Config = {
    MenuTitle = "Vanzyxxx",
    RainbowTheme = false,
    CustomColor = Color3.fromRGB(160, 32, 240),
    OnReset = Instance.new("BindableEvent")
}

-- ASSETS
local LogoURL = "https://files.catbox.moe/io8o2d.png"
local LocalPath = "VanzyLogo.jpg"
pcall(function() if not isfile(LocalPath) then writefile(LocalPath, game:HttpGet(LogoURL)) end end)
local FinalLogo = (getcustomasset and isfile(LocalPath)) and getcustomasset(LocalPath) or LogoURL

-- THEME
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

-- GUI PARENT
local function GetGuiParent()
    if gethui then return gethui() end
    if syn and syn.protect_gui then 
        local sg = Instance.new("ScreenGui"); syn.protect_gui(sg); sg.Parent = Services.CoreGui; return sg 
    end
    return Services.CoreGui
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Vanzyxxx"
ScreenGui.Parent = GetGuiParent()
ScreenGui.ResetOnSpawn = false

-- RAINBOW LOOP
spawn(function()
    while true do
        if Config.RainbowTheme then
            Theme.Accent = Color3.fromHSV(tick() % 5 / 5, 1, 1)
            Config.CustomColor = Theme.Accent
        end
        task.wait(0.05)
    end
end)

-- >>> 1. LOADING SCREEN SYSTEM <<<
local LoaderUI = {}
function LoaderUI.Create()
    local Frame = Instance.new("Frame", ScreenGui)
    Frame.Name = "LoadingFrame"
    Frame.Size = UDim2.new(0, 300, 0, 120)
    Frame.Position = UDim2.new(0.5, -150, 0.5, -60)
    Frame.BackgroundColor3 = Theme.Main
    Frame.ZIndex = 100
    Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 10)
    
    local Stroke = Instance.new("UIStroke", Frame); Stroke.Color = Theme.Accent; Stroke.Thickness = 2
    
    local Title = Instance.new("TextLabel", Frame)
    Title.Size = UDim2.new(1, 0, 0, 30); Title.Position = UDim2.new(0, 0, 0.1, 0)
    Title.BackgroundTransparency = 1; Title.Text = "Vanzyxxx Modular"; Title.TextColor3 = Theme.Accent
    Title.Font = Enum.Font.GothamBlack; Title.TextSize = 18; Title.ZIndex = 101
    
    local Status = Instance.new("TextLabel", Frame)
    Status.Size = UDim2.new(1, 0, 0, 20); Status.Position = UDim2.new(0, 0, 0.45, 0)
    Status.BackgroundTransparency = 1; Status.Text = "Initializing..."; Status.TextColor3 = Theme.Text
    Status.Font = Enum.Font.Gotham; Status.TextSize = 12; Status.ZIndex = 101
    
    local BarBG = Instance.new("Frame", Frame)
    BarBG.Size = UDim2.new(0.8, 0, 0, 6); BarBG.Position = UDim2.new(0.1, 0, 0.75, 0)
    BarBG.BackgroundColor3 = Color3.fromRGB(40,40,40); BarBG.ZIndex = 101; Instance.new("UICorner", BarBG)
    
    local BarFill = Instance.new("Frame", BarBG)
    BarFill.Size = UDim2.new(0, 0, 1, 0); BarFill.BackgroundColor3 = Theme.Accent; BarFill.ZIndex = 102; Instance.new("UICorner", BarFill)
    
    spawn(function()
        while Frame.Parent do
            Stroke.Color = Theme.Accent; BarFill.BackgroundColor3 = Theme.Accent; Title.TextColor3 = Theme.Accent
            task.wait(0.1)
        end
    end)
    
    return {
        Update = function(pct, txt)
            Status.Text = txt
            Services.TweenService:Create(BarFill, TweenInfo.new(0.1), {Size = UDim2.new(pct, 0, 1, 0)}):Play()
        end,
        Destroy = function()
            Services.TweenService:Create(Frame, TweenInfo.new(0.5), {Position = UDim2.new(0.5, -150, 1.5, 0)}):Play()
            task.wait(0.5)
            Frame:Destroy()
        end
    }
end

-- >>> 2. UI LIBRARY SYSTEM <<<
local UILibrary = {}
local UIRefs = { MainFrame = nil, Sidebar = nil, Content = nil }

function UILibrary:Create()
    -- Open Button
    local OpenBtn = Instance.new("ImageButton", ScreenGui); OpenBtn.Name="Open"; OpenBtn.Size=UDim2.new(0,50,0,50); OpenBtn.Position=UDim2.new(0.05,0,0.2,0); OpenBtn.BackgroundColor3=Theme.Main; OpenBtn.Image=FinalLogo; OpenBtn.Visible=false; Instance.new("UICorner",OpenBtn).CornerRadius=UDim.new(1,0); local OS=Instance.new("UIStroke",OpenBtn); OS.Color=Theme.Accent; OS.Thickness=2
    UILibrary.OpenBtn = OpenBtn 

    -- Main Frame
    local MainFrame = Instance.new("Frame", ScreenGui); MainFrame.Name="Main"; MainFrame.Size=UDim2.new(0,400,0,220); MainFrame.Position=UDim2.new(0.5,-200,0.5,-110); MainFrame.BackgroundColor3=Theme.Main; MainFrame.ClipsDescendants=true; MainFrame.Visible=false; Instance.new("UICorner",MainFrame).CornerRadius=UDim.new(0,12); local MS=Instance.new("UIStroke",MainFrame); MS.Color=Theme.Accent; MS.Thickness=2
    UIRefs.MainFrame = MainFrame
    
    -- Drag
    local function Drag(f)
        local d, ds, sp
        f.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then d=true; ds=i.Position; sp=f.Position; i.Changed:Connect(function() if i.UserInputState==Enum.UserInputState.End then d=false end end) end end)
        Services.UserInputService.InputChanged:Connect(function(i) if (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) and d then local dt=i.Position-ds; f.Position=UDim2.new(sp.X.Scale,sp.X.Offset+dt.X,sp.Y.Scale,sp.Y.Offset+dt.Y) end end)
    end
    Drag(MainFrame); Drag(OpenBtn)
    
    -- Elements
    local Title = Instance.new("TextLabel", MainFrame); Title.Size=UDim2.new(1,-100,0,30); Title.Position=UDim2.new(0,10,0,0); Title.BackgroundTransparency=1; Title.Text=Config.MenuTitle; Title.Font=Enum.Font.GothamBlack; Title.TextSize=16; Title.TextColor3=Theme.Accent; Title.TextXAlignment=Enum.TextXAlignment.Left
    
    local BtnContainer = Instance.new("Frame", MainFrame); BtnContainer.Size=UDim2.new(0,120,0,30); BtnContainer.Position=UDim2.new(1,-125,0,0); BtnContainer.BackgroundTransparency=1
    local CloseX = Instance.new("TextButton", BtnContainer); CloseX.Size=UDim2.new(0,30,0,30); CloseX.Position=UDim2.new(1,-30,0,0); CloseX.BackgroundTransparency=1; CloseX.Text="X"; CloseX.TextColor3=Color3.fromRGB(255,50,50); CloseX.Font=Enum.Font.GothamBlack; CloseX.TextSize=18
    local LayoutBtn = Instance.new("TextButton", BtnContainer); LayoutBtn.Size=UDim2.new(0,30,0,30); LayoutBtn.Position=UDim2.new(1,-60,0,0); LayoutBtn.BackgroundTransparency=1; LayoutBtn.Text="+"; LayoutBtn.TextColor3=Color3.fromRGB(255,200,50); LayoutBtn.Font=Enum.Font.GothamBlack; LayoutBtn.TextSize=20
    local MinBtn = Instance.new("TextButton", BtnContainer); MinBtn.Size=UDim2.new(0,30,0,30); MinBtn.Position=UDim2.new(1,-90,0,0); MinBtn.BackgroundTransparency=1; MinBtn.Text="_"; MinBtn.TextColor3=Theme.Accent; MinBtn.Font=Enum.Font.GothamBlack; MinBtn.TextSize=18
    
    local Sidebar = Instance.new("ScrollingFrame", MainFrame); Sidebar.Size=UDim2.new(0,110,1,-35); Sidebar.Position=UDim2.new(0,0,0,35); Sidebar.BackgroundColor3=Theme.Sidebar; Sidebar.ScrollBarThickness=0; Sidebar.BorderSizePixel=0; UIRefs.Sidebar=Sidebar
    local SideLayout = Instance.new("UIListLayout", Sidebar); SideLayout.HorizontalAlignment=Enum.HorizontalAlignment.Center; SideLayout.Padding=UDim.new(0,6); Instance.new("UIPadding", Sidebar).PaddingTop=UDim.new(0,10)
    
    local Content = Instance.new("Frame", MainFrame); Content.Size=UDim2.new(1,-110,1,-35); Content.Position=UDim2.new(0,110,0,35); Content.BackgroundTransparency=1; UIRefs.Content=Content
    
    -- Toggle Logic
    local isVertical = false
    OpenBtn.MouseButton1Click:Connect(function() MainFrame.Visible=true; OpenBtn.Visible=false end)
    MinBtn.MouseButton1Click:Connect(function() MainFrame.Visible=false; OpenBtn.Visible=true end)
    LayoutBtn.MouseButton1Click:Connect(function() isVertical=not isVertical; if isVertical then MainFrame.Size=UDim2.new(0,220,0,400); Sidebar.Size=UDim2.new(0,60,1,-35); Content.Size=UDim2.new(1,-60,1,-35); Content.Position=UDim2.new(0,60,0,35); LayoutBtn.Text="-" else MainFrame.Size=UDim2.new(0,400,0,220); Sidebar.Size=UDim2.new(0,110,1,-35); Content.Size=UDim2.new(1,-110,1,-35); Content.Position=UDim2.new(0,110,0,35); LayoutBtn.Text="+" end end)
    
    -- Confirmation Popup
    local GP = Instance.new("Frame", ScreenGui); GP.Size=UDim2.new(0,240,0,130); GP.Position=UDim2.new(0.5,-120,0.5,-65); GP.BackgroundColor3=Theme.Main; GP.Visible=false; GP.ZIndex=200; Instance.new("UICorner",GP).CornerRadius=UDim.new(0,12); local GPS=Instance.new("UIStroke",GP); GPS.Color=Theme.Accent; GPS.Thickness=2
    local GPT=Instance.new("TextLabel",GP); GPT.Size=UDim2.new(1,0,0,30); GPT.BackgroundTransparency=1; GPT.Text="CONFIRM"; GPT.TextColor3=Theme.Accent; GPT.Font=Enum.Font.GothamBlack; GPT.TextSize=14; GPT.ZIndex=201
    local GPD=Instance.new("TextLabel",GP); GPD.Size=UDim2.new(0.9,0,0.4,0); GPD.Position=UDim2.new(0.05,0,0.25,0); GPD.BackgroundTransparency=1; GPD.Text=""; GPD.TextColor3=Theme.Text; GPD.Font=Enum.Font.Gotham; GPD.TextSize=12; GPD.TextWrapped=true; GPD.ZIndex=201
    local GPY=Instance.new("TextButton",GP); GPY.Size=UDim2.new(0.4,0,0.25,0); GPY.Position=UDim2.new(0.05,0,0.7,0); GPY.BackgroundColor3=Theme.Confirm; GPY.Text="YES"; GPY.TextColor3=Theme.Text; GPY.ZIndex=201; Instance.new("UICorner",GPY)
    local GPN=Instance.new("TextButton",GP); GPN.Size=UDim2.new(0.4,0,0.25,0); GPN.Position=UDim2.new(0.55,0,0.7,0); GPN.BackgroundColor3=Theme.ButtonRed; GPN.Text="NO"; GPN.TextColor3=Theme.Text; GPN.ZIndex=201; Instance.new("UICorner",GPN)
    
    local Act=nil
    GPN.MouseButton1Click:Connect(function() GP.Visible=false; Act=nil end)
    GPY.MouseButton1Click:Connect(function() if Act then Act() end; GP.Visible=false end)
    function UILibrary:Confirm(t,c) GPD.Text=t; Act=c; GP.Visible=true end
    
    CloseX.MouseButton1Click:Connect(function() UILibrary:Confirm("Exit Script?", function() Config.OnReset:Fire(); ScreenGui:Destroy() end) end)
    
    -- TABS SYSTEM
    local TabsDict = {}
    
    function UILibrary:Tab(name)
        if TabsDict[name] then return TabsDict[name] end
        
        local B = Instance.new("TextButton", Sidebar); B.Size=UDim2.new(0.85,0,0,28); B.BackgroundColor3=Theme.Button; B.Text=name; B.TextColor3=Color3.fromRGB(200,200,200); B.Font=Enum.Font.GothamBold; B.TextSize=10; Instance.new("UICorner",B).CornerRadius=UDim.new(0,6)
        local P = Instance.new("ScrollingFrame", Content); P.Size=UDim2.new(1,-5,1,0); P.BackgroundTransparency=1; P.ScrollBarThickness=2; P.Visible=false; P.AutomaticCanvasSize=Enum.AutomaticSize.Y; Instance.new("UIListLayout",P).Padding=UDim.new(0,5); Instance.new("UIPadding",P).PaddingTop=UDim.new(0,5)
        
        B.MouseButton1Click:Connect(function()
            for _,v in pairs(TabsDict) do v.P.Visible=false; v.B.BackgroundColor3=Theme.Button; v.B.TextColor3=Color3.fromRGB(200,200,200) end
            P.Visible=true; B.BackgroundColor3=Theme.Accent; B.TextColor3=Color3.new(1,1,1)
        end)
        
        local El = {P=P, B=B}
        function El:Button(t,c,f) local b=Instance.new("TextButton",P); b.Size=UDim2.new(1,0,0,26); b.BackgroundColor3=c or Theme.Button; b.Text=t; b.TextColor3=Color3.new(1,1,1); b.Font=Enum.Font.Gotham; b.TextSize=11; Instance.new("UICorner",b).CornerRadius=UDim.new(0,6); b.MouseButton1Click:Connect(function() pcall(f) end) end
        function El:Toggle(t,f) local fr=Instance.new("Frame",P); fr.Size=UDim2.new(1,0,0,26); fr.BackgroundColor3=Theme.Button; Instance.new("UICorner",fr).CornerRadius=UDim.new(0,6); local l=Instance.new("TextLabel",fr); l.Size=UDim2.new(0.65,0,1,0); l.Position=UDim2.new(0.05,0,0,0); l.BackgroundTransparency=1; l.Text=t; l.TextColor3=Color3.new(1,1,1); l.TextXAlignment=Enum.TextXAlignment.Left; l.Font=Enum.Font.Gotham; l.TextSize=11; local b=Instance.new("TextButton",fr); b.Size=UDim2.new(0,30,0,18); b.Position=UDim2.new(0.75,0,0.15,0); b.BackgroundColor3=Color3.fromRGB(60,60,60); b.Text=""; Instance.new("UICorner",b).CornerRadius=UDim.new(1,0); local s=false; b.MouseButton1Click:Connect(function() s=not s; b.BackgroundColor3=s and Theme.Accent or Color3.fromRGB(60,60,60); if f then pcall(f,s) end end) end
        function El:Label(t) local l=Instance.new("TextLabel",P); l.Size=UDim2.new(1,0,0,20); l.BackgroundTransparency=1; l.Text=t; l.TextColor3=Theme.Accent; l.Font=Enum.Font.GothamBold; l.TextSize=10; l.TextXAlignment=Enum.TextXAlignment.Left end
        function El:Input(p,f) local fr=Instance.new("Frame",P); fr.Size=UDim2.new(1,0,0,26); fr.BackgroundColor3=Color3.fromRGB(35,35,35); Instance.new("UICorner",fr).CornerRadius=UDim.new(0,6); local b=Instance.new("TextBox",fr); b.Size=UDim2.new(0.9,0,1,0); b.Position=UDim2.new(0.05,0,0,0); b.BackgroundTransparency=1; b.Text=""; b.PlaceholderText=p; b.TextColor3=Color3.new(1,1,1); b.Font=Enum.Font.Gotham; b.TextSize=11; b:GetPropertyChangedSignal("Text"):Connect(function() if f then pcall(f,b.Text) end end) end
        function El:Slider(t,min,max,f) local fr=Instance.new("Frame",P);fr.Size=UDim2.new(1,0,0,32);fr.BackgroundColor3=Theme.Button;Instance.new("UICorner",fr).CornerRadius=UDim.new(0,6);local l=Instance.new("TextLabel",fr);l.Size=UDim2.new(1,0,0.5,0);l.Position=UDim2.new(0.05,0,0,0);l.BackgroundTransparency=1;l.Text=t;l.TextColor3=Color3.new(1,1,1);l.TextSize=10;l.TextXAlignment=Enum.TextXAlignment.Left;local b=Instance.new("TextButton",fr);b.Size=UDim2.new(0.9,0,0.3,0);b.Position=UDim2.new(0.05,0,0.6,0);b.BackgroundColor3=Color3.fromRGB(30,30,30);b.Text="";local fil=Instance.new("Frame",b);fil.Size=UDim2.new(0,0,1,0);fil.BackgroundColor3=Theme.Accent;b.MouseButton1Down:Connect(function() local m;m=Services.RunService.RenderStepped:Connect(function() local s=math.clamp((Services.UserInputService:GetMouseLocation().X-b.AbsolutePosition.X)/b.AbsoluteSize.X,0,1);fil.Size=UDim2.new(s,0,1,0);if f then pcall(f,min+(max-min)*s) end;if not Services.UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then m:Disconnect() end end) end) end
        function El:Container(h) local c=Instance.new("ScrollingFrame",P); c.Size=UDim2.new(1,0,0,h); c.BackgroundColor3=Color3.fromRGB(25,25,25); c.ScrollBarThickness=2; Instance.new("UICorner",c).CornerRadius=UDim.new(0,6); Instance.new("UIListLayout",c).Padding=UDim.new(0,2); c.AutomaticCanvasSize=Enum.AutomaticSize.Y; return c end
        
        TabsDict[name] = El
        return El
    end
    return UILibrary
end

local UI = UILibrary:Create()

-- >>> 3. FEATURE LOADER (CRASH PREVENTER) <<<
local GitHubBaseURL = "https://raw.githubusercontent.com/alfreadrorw1/VanzyModular/main/"
local FeatureList = {
    {cat="Movement", name="fly", url=GitHubBaseURL.."features/Movement/fly.lua"},
    {cat="Movement", name="speed", url=GitHubBaseURL.."features/Movement/speed.lua"},
    {cat="Movement", name="infinityJump", url=GitHubBaseURL.."features/Movement/infinityJump.lua"},
    {cat="Movement", name="noclip", url=GitHubBaseURL.."features/Movement/noclip.lua"},
    {cat="Movement", name="wallClimb", url=GitHubBaseURL.."features/Movement/wallClimb.lua"},
    {cat="Visual", name="esp", url=GitHubBaseURL.."features/Visual/esp.lua"},
    {cat="Visual", name="fullbright", url=GitHubBaseURL.."features/Visual/fullbright.lua"},
    {cat="Aura", name="aura", url=GitHubBaseURL.."features/Aura/aura.lua"},
    {cat="Sky", name="sky", url=GitHubBaseURL.."features/Sky/sky.lua"},
    {cat="Checkpoint", name="saveLoadCP", url=GitHubBaseURL.."features/Checkpoint/saveLoadCP.lua"},
    {cat="Settings", name="theme", url=GitHubBaseURL.."features/Settings/theme.lua"},
    {cat="Settings", name="fpsBoost", url=GitHubBaseURL.."features/Settings/fpsBoost.lua"}
}

spawn(function()
    local Loader = LoaderUI.Create()
    local total = #FeatureList
    
    -- [CRITICAL FIX] Create ALL Tabs First (Empty)
    -- Ini memastikan tab tetap ada meskipun scriptnya gagal di-load
    local categories = {}
    for _, f in ipairs(FeatureList) do
        if not categories[f.cat] then
            categories[f.cat] = true
            UI:Tab(f.cat)
        end
    end
    
    -- [SAFE LOADER]
    for i, feature in ipairs(FeatureList) do
        Loader.Update(i/total, "Loading: " .. feature.name)
        
        -- Bungkus dengan pcall agar loop TIDAK MATI jika ada error
        local success, err = pcall(function()
            local code = game:HttpGet(feature.url, true)
            if not code or code == "" or code:sub(1,3) == "404" then 
                error("404 Not Found") 
            end
            
            local func, syntaxErr = loadstring(code)
            if not func then 
                error("Syntax Error: " .. tostring(syntaxErr)) 
            end
            
            -- Eksekusi Script Fitur
            func(UI, Services, Config, Theme)
        end)
        
        -- Jika Gagal, Tampilkan Error di Tab yang sesuai
        if not success then
            local Tab = UI:Tab(feature.cat)
            Tab:Label("⚠️ Error loading " .. feature.name)
            warn("[Vanzyxxx] Failed " .. feature.name .. ": " .. tostring(err))
        end
        
        task.wait() -- Allow UI update
    end
    
    Loader.Update(1, "Ready!")
    task.wait(0.5)
    Loader.Destroy()
    
    -- Show Open Button
    if UILibrary.OpenBtn then UILibrary.OpenBtn.Visible = true end
    
    -- Auto Select First Tab
    if UI then UI:Tab("Movement") end
end)

-- ANTI AFK
local vu = game:GetService("VirtualUser")
Services.Players.LocalPlayer.Idled:Connect(function() vu:Button2Down(Vector2.new(0,0),workspace.CurrentCamera.CFrame); task.wait(1); vu:Button2Up(Vector2.new(0,0),workspace.CurrentCamera.CFrame) end)

return {UI = UI, Services = Services, Config = Config}
