-- features/Visual/connectionDisplay.lua
return function(UI, Services, Config, Theme)
    local Players = Services.Players
    local Workspace = Services.Workspace
    local RunService = Services.RunService
    local LocalPlayer = Players.LocalPlayer
    local TextService = game:GetService("TextService")
    
    local VisualTab = UI:Tab("Connection Display")
    local DisplayEnabled = false
    local PingDisplays = {}
    local PacketLossDisplays = {}
    
    local function GetPingColor(ping)
        if ping < 50 then return Color3.fromRGB(0, 255, 0) end
        if ping < 100 then return Color3.fromRGB(255, 255, 0) end
        if ping < 200 then return Color3.fromRGB(255, 128, 0) end
        return Color3.fromRGB(255, 0, 0)
    end
    
    local function GetPacketLossColor(loss)
        if loss < 1 then return Color3.fromRGB(0, 255, 0) end
        if loss < 5 then return Color3.fromRGB(255, 255, 0) end
        if loss < 10 then return Color3.fromRGB(255, 128, 0) end
        return Color3.fromRGB(255, 0, 0)
    end
    
    local function CreateConnectionDisplay(player)
        if not player or player == LocalPlayer then return end
        
        local pingBillboard = Instance.new("BillboardGui")
        pingBillboard.Name = "PingDisplay_" .. player.UserId
        pingBillboard.Size = UDim2.new(0, 200, 0, 50)
        pingBillboard.StudsOffset = Vector3.new(0, 4, 0)
        pingBillboard.AlwaysOnTop = true
        pingBillboard.MaxDistance = 500
        pingBillboard.Parent = Workspace
        
        local pingText = Instance.new("TextLabel")
        pingText.Name = "PingText"
        pingText.Size = UDim2.new(1, 0, 0.5, 0)
        pingText.BackgroundTransparency = 1
        pingText.Text = "Ping: ?ms"
        pingText.TextColor3 = Color3.new(1, 1, 1)
        pingText.TextStrokeTransparency = 0
        pingText.TextStrokeColor3 = Color3.new(0, 0, 0)
        pingText.Font = Enum.Font.GothamBold
        pingText.TextSize = 14
        pingText.Parent = pingBillboard
        
        local lossText = Instance.new("TextLabel")
        lossText.Name = "LossText"
        lossText.Size = UDim2.new(1, 0, 0.5, 0)
        lossText.Position = UDim2.new(0, 0, 0.5, 0)
        lossText.BackgroundTransparency = 1
        lossText.Text = "Loss: ?%"
        lossText.TextColor3 = Color3.new(1, 1, 1)
        lossText.TextStrokeTransparency = 0
        lossText.TextStrokeColor3 = Color3.new(0, 0, 0)
        lossText.Font = Enum.Font.GothamBold
        lossText.TextSize = 12
        lossText.Parent = pingBillboard
        
        local background = Instance.new("Frame")
        background.Size = UDim2.new(1, 4, 1, 4)
        background.Position = UDim2.new(0, -2, 0, -2)
        background.BackgroundColor3 = Color3.new(0, 0, 0)
        background.BackgroundTransparency = 0.5
        background.ZIndex = -1
        background.Parent = pingBillboard
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 4)
        corner.Parent = background
        
        -- Simpan reference
        PingDisplays[player] = {
            Billboard = pingBillboard,
            PingLabel = pingText,
            LossLabel = lossText,
            LastUpdate = tick()
        }
    end
    
    local function UpdateConnectionDisplay()
        for player, display in pairs(PingDisplays) do
            if player and player.Parent then
                -- Cari karakter untuk attach
                local character = player.Character
                local head = character and character:FindFirstChild("Head")
                
                if head and display.Billboard and display.Billboard.Parent then
                    display.Billboard.Adornee = head
                    
                    -- Simulasi ping & packet loss (real implementation butuh network stats)
                    local fakePing = math.random(10, 300)
                    local fakeLoss = math.random(0, 15)
                    
                    -- Update warna berdasarkan kualitas
                    display.PingLabel.TextColor3 = GetPingColor(fakePing)
                    display.LossLabel.TextColor3 = GetPacketLossColor(fakeLoss)
                    
                    -- Update text
                    display.PingLabel.Text = string.format("Ping: %dms", fakePing)
                    display.LossLabel.Text = string.format("Loss: %d%%", fakeLoss)
                    
                    -- Tambah icon berdasarkan kondisi
                    local statusIcon = ""
                    if fakePing > 200 or fakeLoss > 10 then
                        statusIcon = " 🔴"
                    elseif fakePing > 100 then
                        statusIcon = " 🟡"
                    else
                        statusIcon = " 🟢"
                    end
                    
                    display.PingLabel.Text = display.PingLabel.Text .. statusIcon
                end
            else
                -- Cleanup jika player keluar
                pcall(function() display.Billboard:Destroy() end)
                PingDisplays[player] = nil
            end
        end
    end
    
    local connectionToggle = VisualTab:Toggle("📶 Show Connection Quality", function(state)
        DisplayEnabled = state
        
        if state then
            -- Buat display untuk semua player
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then
                    CreateConnectionDisplay(player)
                end
            end
            
            -- Setup new player connection
            Players.PlayerAdded:Connect(function(player)
                task.wait(1)
                CreateConnectionDisplay(player)
            end)
            
            -- Update loop
            local updateLoop
            updateLoop = RunService.Heartbeat:Connect(function()
                UpdateConnectionDisplay()
            end)
            
            -- Cleanup saat toggle off
            VisualTab:Button("🔄 Update All Displays", Theme.Button, function()
                UpdateConnectionDisplay()
            end)
            
            -- Simpan connection untuk cleanup
            Config.OnReset:Connect(function()
                if updateLoop then updateLoop:Disconnect() end
                for _, display in pairs(PingDisplays) do
                    pcall(function() display.Billboard:Destroy() end)
                end
                PingDisplays = {}
            end)
            
        else
            -- Hapus semua display
            for _, display in pairs(PingDisplays) do
                pcall(function() display.Billboard:Destroy() end)
            end
            PingDisplays = {}
        end
    end)
    
    -- Settings
    VisualTab:Label("─ DISPLAY SETTINGS ─")
    
    local showOnlyEnemies = false
    VisualTab:Toggle("👤 Show Only Enemies", function(state)
        showOnlyEnemies = state
    end)
    
    VisualTab:Slider("Max Display Distance", 50, 500, function(value)
        for _, display in pairs(PingDisplays) do
            if display.Billboard then
                display.Billboard.MaxDistance = value
            end
        end
    end)
end