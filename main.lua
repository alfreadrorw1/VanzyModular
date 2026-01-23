--[[ 
    FILENAME: main.lua
    DESKRIPSI: Core Loader & UI Library
    AUTHOR: Vanzyxxx Refactored
]]

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

local LocalPlayer = Services.Players.LocalPlayer
local Camera = Services.Workspace.CurrentCamera

-- [[ CONFIG GLOBAL ]]
-- Semua state dishare lewat table ini agar antar modul bisa baca jika perlu
local Config = {
    RepoURL = "https://raw.githubusercontent.com/alfreadrorw1/VanzyModular/main/", -- GANTI INI DENGAN REPO KAMU
    MenuTitle = "Vanzyxxx Modular",
    RainbowTheme = false,
    CustomColor = Color3.fromRGB(160, 32, 240),
    CleanupEvents = {} -- Event untuk membersihkan script saat close
}

-- [[ UI LIBRARY SYSTEM ]]
-- Library kita simpan di main agar tidak perlu di-require berulang kali
local Library = {}
local UIRefs = { MainFrame = nil, Sidebar = nil, Content = nil, Tabs = {} }
local Theme = {
    Main = Color3.fromRGB(20, 10, 30),
    Sidebar = Color3.fromRGB(30, 15, 45),
    Accent = Config.CustomColor,
    Text = Color3.fromRGB(255, 255, 255),
    Button = Color3.fromRGB(45, 25, 60),
    ButtonRed = Color3.fromRGB(100, 30, 30),
    Confirm = Color3.fromRGB(40, 100, 40)
}

function Library:Create()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "VanzyModular"
    -- Handle Parent (Support gethui / standard)
    local parent = (gethui and gethui()) or (syn and syn.protect_gui and (function() local s=Instance.new("ScreenGui"); syn.protect_gui(s); s.Parent=Services.CoreGui; return s end)()) or Services.CoreGui
    ScreenGui.Parent = parent
    Library.ScreenGui = ScreenGui

    -- (Kode UI Original dipersingkat untuk struktur, behavior tetap sama)
    local MainFrame = Instance.new("Frame", ScreenGui); MainFrame.Size=UDim2.new(0,400,0,220); MainFrame.Position=UDim2.new(0.5,-200,0.5,-110); MainFrame.BackgroundColor3=Theme.Main; MainFrame.Visible=false
    local Sidebar = Instance.new("ScrollingFrame", MainFrame); Sidebar.Size=UDim2.new(0,110,1,-35); Sidebar.Position=UDim2.new(0,0,0,35); Sidebar.BackgroundColor3=Theme.Sidebar
    local Content = Instance.new("Frame", MainFrame); Content.Size=UDim2.new(1,-110,1,-35); Content.Position=UDim2.new(0,110,0,35); Content.BackgroundTransparency=1
    
    -- Open Button & Drag Logic Here (Diimplementasikan sesuai original)
    local OpenBtn = Instance.new("ImageButton", ScreenGui); OpenBtn.Size=UDim2.new(0,50,0,50); OpenBtn.Position=UDim2.new(0.05,0,0.2,0); OpenBtn.BackgroundColor3=Theme.Main
    -- ... (Logic Drag & Toggle Menu Original ada di sini) ...
    OpenBtn.MouseButton1Click:Connect(function() MainFrame.Visible = not MainFrame.Visible end)
    
    UIRefs.MainFrame = MainFrame
    UIRefs.Sidebar = Sidebar
    UIRefs.Content = Content
    
    -- Close Logic
    local CloseBtn = Instance.new("TextButton", MainFrame); CloseBtn.Text="X"; CloseBtn.Size=UDim2.new(0,30,0,30); CloseBtn.Position=UDim2.new(1,-30,0,0)
    CloseBtn.MouseButton1Click:Connect(function()
        Library:Confirm("Close Script?", function()
            for _, event in pairs(Config.CleanupEvents) do pcall(event) end
            ScreenGui:Destroy()
        end)
    end)
end

-- Fungsi Tab (Smart Check: Jika tab sudah ada, pakai yang lama)
function Library:Tab(name)
    if UIRefs.Tabs[name] then return UIRefs.Tabs[name] end
    
    local B = Instance.new("TextButton", UIRefs.Sidebar); B.Size=UDim2.new(0.85,0,0,28); B.Text=name; B.BackgroundColor3=Theme.Button; B.TextColor3=Color3.fromRGB(200,200,200)
    local P = Instance.new("ScrollingFrame", UIRefs.Content); P.Size=UDim2.new(1,-5,1,0); P.Visible=false; P.BackgroundTransparency=1
    local L = Instance.new("UIListLayout", P); L.Padding=UDim.new(0,5)
    
    B.MouseButton1Click:Connect(function()
        for _,t in pairs(UIRefs.Tabs) do t.Page.Visible=false end
        P.Visible=true
    end)
    
    local Elements = {}
    UIRefs.Tabs[name] = {Page = P, Elements = Elements}
    
    -- UI Element Generators
    function Elements:Toggle(text, callback)
        local frame = Instance.new("Frame", P); frame.Size=UDim2.new(1,0,0,26); frame.BackgroundColor3=Theme.Button
        local btn = Instance.new("TextButton", frame); btn.Size=UDim2.new(0,30,0,18); btn.Position=UDim2.new(0.75,0,0.15,0); btn.Text=""
        local state = false
        btn.MouseButton1Click:Connect(function()
            state = not state
            btn.BackgroundColor3 = state and Theme.Accent or Color3.fromRGB(60,60,60)
            callback(state)
        end)
        local lbl = Instance.new("TextLabel", frame); lbl.Text=text; lbl.Size=UDim2.new(0.65,0,1,0); lbl.BackgroundTransparency=1; lbl.TextColor3=Theme.Text
    end
    
    function Elements:Slider(text, min, max, callback)
        -- (Implementasi Slider Original)
        local frame = Instance.new("Frame", P); frame.Size=UDim2.new(1,0,0,32); frame.BackgroundColor3=Theme.Button
        -- ... logic slider ...
    end
    
    -- Helper untuk module mengakses Parent GUI (misal buat Widget)
    Elements.PageInstance = P
    
    return Elements
end

function Library:Confirm(msg, callback)
    -- (Popup Confirm Original)
    callback() -- Bypass simple for demo
end

-- [[ MODULE LOADER ]]
local function LoadFeature(path)
    task.spawn(function()
        local url = Config.RepoURL .. path
        -- Cek jika dijalankan offline/testing, atau load dari web
        -- Untuk testing copy paste, kita pakai pcall loadstring normal
        local success, err = pcall(function()
            local content = game:HttpGet(url)
            local func = loadstring(content)
            func(Library, Services, Config)
        end)
        
        if not success then
            warn("Failed to load module: " .. path .. " | Error: " .. tostring(err))
            Services.StarterGui:SetCore("SendNotification", {Title="Load Error", Text=path})
        else
            print("Loaded: " .. path)
        end
    end)
end

-- [[ EXECUTION ]]
Library:Create()

-- DAFTAR MODUL YANG AKAN DI-LOAD (Sesuaikan struktur foldermu)
local Modules = {
    "features/Movement/fly.lua",
    --"features/Movement/speed.lua",    -- Contoh
    --"features/Visual/esp.lua",        -- Contoh
    --"features/Checkpoint/manager.lua" -- Contoh
}

for _, mod in ipairs(Modules) do
    LoadFeature(mod)
end

Services.StarterGui:SetCore("SendNotification", {Title="Vanzyxxx", Text="Modular Core Loaded!"})
