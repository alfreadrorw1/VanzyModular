-- Vanzyxxx Jump Button Customizer
-- Ultimate Control for Mobile Jump Button
-- Created by Alfreadrorw1

return function(UI, Services, Config, Theme)
    local Players = Services.Players
    local GuiService = game:GetService("GuiService")
    local LocalPlayer = Players.LocalPlayer
    local RunService = Services.RunService
    local UserInputService = Services.UserInputService

    -- Tab Setup
    local SettingsTab = UI:Tab("Settings")
    SettingsTab:Label("Mobile Jump Button Customizer")

    -- Config Variables
    Config.JumpBtn_Customizing = false
    Config.JumpBtn_Size = 1
    Config.JumpBtn_Transparency = 0.5
    
    -- Variables internal
    local TouchGui = nil
    local JumpButton = nil
    local DefaultPosition = nil
    local DefaultSize = nil
    local DragConnection = nil
    local DragFrame = nil -- Frame dummy untuk drag visual

    -- Fungsi Mencari Tombol Lompat
    local function FindJumpButton()
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        if not playerGui then return nil end
        
        -- Coba cari di path standar Roblox Mobile
        local touchGui = playerGui:FindFirstChild("TouchGui")
        if touchGui then
            -- Path 1: TouchControlFrame (Biasa)
            local controlFrame = touchGui:FindFirstChild("TouchControlFrame")
            if controlFrame then
                local btn = controlFrame:FindFirstChild("JumpButton")
                if btn then 
                    TouchGui = touchGui
                    return btn 
                end
            end
        end
        return nil
    end

    -- Inisialisasi Tombol
    JumpButton = FindJumpButton()
    
    -- Simpan default properties saat pertama kali ketemu
    if JumpButton then
        DefaultPosition = JumpButton.Position
        DefaultSize = JumpButton.Size
    else
        -- Notifikasi jika bukan di HP / tidak ketemu
        Services.StarterGui:SetCore("SendNotification", {
            Title = "Warning",
            Text = "Jump Button not found! (Are you on Mobile?)",
            Duration = 5
        })
    end

    -- Fungsi Update Properti
    local function UpdateButton()
        if not JumpButton then JumpButton = FindJumpButton() end
        if not JumpButton then return end

        -- Update Transparansi (ImageTransparency & BackgroundTransparency)
        if JumpButton:IsA("ImageButton") then
            JumpButton.ImageTransparency = 1 - Config.JumpBtn_Transparency
        end
        JumpButton.BackgroundTransparency = 1 
    end

    --------------------------------------------------------------------------------
    -- DRAG SYSTEM (Sekompleks Mungkin)
    --------------------------------------------------------------------------------
    
    local function StartDragMode(state)
        Config.JumpBtn_Customizing = state
        
        if not JumpButton then return end

        if state then
            -- Buat Frame Dummy untuk Visualisasi Drag
            if not DragFrame then
                local screen = UI:GetScreenGui()
                DragFrame = Instance.new("Frame", screen)
                DragFrame.Name = "JumpDragHelper"
                DragFrame.Size = UDim2.new(0, JumpButton.AbsoluteSize.X, 0, JumpButton.AbsoluteSize.Y)
                DragFrame.Position = UDim2.new(0, JumpButton.AbsolutePosition.X, 0, JumpButton.AbsolutePosition.Y + 36) -- Offset GuiInset
                DragFrame.BackgroundColor3 = Theme.Accent
                DragFrame.BackgroundTransparency = 0.5
                DragFrame.BorderSizePixel = 2
                DragFrame.BorderColor3 = Color3.new(1,1,1)
                
                local label = Instance.new("TextLabel", DragFrame)
                label.Size = UDim2.new(1,0,1,0)
                label.BackgroundTransparency = 1
                label.Text = "DRAG ME"
                label.Font = Enum.Font.GothamBlack
                label.TextColor3 = Color3.new(1,1,1)
                
                local corner = Instance.new("UICorner", DragFrame)
                corner.CornerRadius = UDim.new(1,0) -- Bulat
            end
            
            DragFrame.Visible = true
            
            -- Logic Dragging
            local dragging, dragInput, dragStart, startPos
            
            DragFrame.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                    dragStart = input.Position
                    startPos = DragFrame.Position
                    
                    input.Changed:Connect(function()
                        if input.UserInputState == Enum.UserInputState.End then
                            dragging = false
                        end
                    end)
                end
            end)
            
            DragFrame.InputChanged:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement then
                    if dragging then
                        local delta = input.Position - dragStart
                        local newPos = UDim2.new(
                            startPos.X.Scale, 
                            startPos.X.Offset + delta.X, 
                            startPos.Y.Scale, 
                            startPos.Y.Offset + delta.Y
                        )
                        DragFrame.Position = newPos
                        
                        -- Realtime update tombol asli (dikurangi GuiInset/TopBar)
                        if JumpButton then
                            -- Konversi posisi Absolute ke UDim2 parent
                            -- Untuk simpelnya, kita set posisi Absolute-nya mirip DragFrame
                            JumpButton.Position = UDim2.new(0, newPos.X.Offset, 0, newPos.Y.Offset - 36)
                        end
                    end
                end
            end)

        else
            -- Matikan Mode Drag
            if DragFrame then 
                DragFrame.Visible = false 
            end
        end
    end

    --------------------------------------------------------------------------------
    -- UI CONTROLS
    --------------------------------------------------------------------------------

    -- 1. Mode Edit Cepat (Drag)
    SettingsTab:Toggle("Edit Mode (Drag to Move)", function(state)
        StartDragMode(state)
    end)

    -- 2. Size Slider (Skala)
    SettingsTab:Slider("Button Size (Scale)", 50, 200, function(val)
        if not JumpButton then return end
        local scale = val / 100 -- 0.5x sampai 2.0x
        
        if DefaultSize then
            JumpButton.Size = UDim2.new(0, DefaultSize.X.Offset * scale, 0, DefaultSize.Y.Offset * scale)
        end
        
        -- Update ukuran DragFrame juga jika sedang aktif
        if DragFrame then
            DragFrame.Size = JumpButton.Size
        end
    end)

    -- 3. Opacity Slider
    SettingsTab:Slider("Visibility (Opacity)", 0, 100, function(val)
        Config.JumpBtn_Transparency = val / 100
        UpdateButton()
    end)

    -- 4. Manual Position X
    SettingsTab:Slider("Position X (Offset)", -500, 500, function(val)
        if not JumpButton then return end
        -- Ini hanya menambah offset dari posisi saat ini/awal, agak tricky.
        -- Lebih baik gunakan Drag Mode, tapi ini untuk fine tuning.
        local currentY = JumpButton.Position.Y
        JumpButton.Position = UDim2.new(1, val - 150, currentY.Scale, currentY.Offset) 
        -- (1, -150) adalah asumsi posisi pojok kanan bawah
    end)
    
    -- 5. Manual Position Y
    SettingsTab:Slider("Position Y (Offset)", -500, 500, function(val)
        if not JumpButton then return end
        local currentX = JumpButton.Position.X
        JumpButton.Position = UDim2.new(currentX.Scale, currentX.Offset, 1, val - 150)
    end)

    -- 6. RESET BUTTON
    SettingsTab:Button("Reset Position & Size", Theme.ButtonRed, function()
        if JumpButton and DefaultPosition and DefaultSize then
            JumpButton.Position = DefaultPosition
            JumpButton.Size = DefaultSize
            JumpButton.ImageTransparency = 0.5 -- Default roblox
            
            -- Matikan drag mode
            StartDragMode(false)
            
            Services.StarterGui:SetCore("SendNotification", {
                Title = "Reset",
                Text = "Jump button restored.",
                Duration = 2
            })
        end
    end)

    -- Loop check (jika player mati/reset, tombol baru muncul)
    Services.Players.LocalPlayer.CharacterAdded:Connect(function()
        task.wait(2) -- Tunggu loading gui
        JumpButton = FindJumpButton()
        if JumpButton then
            DefaultPosition = JumpButton.Position
            DefaultSize = JumpButton.Size
        end
    end)

    -- Cleanup
    Config.OnReset:Connect(function()
        if DragFrame then DragFrame:Destroy() end
        -- Kembalikan tombol ke asal agar tidak permanen rusak
        if JumpButton and DefaultPosition then
            JumpButton.Position = DefaultPosition
            JumpButton.Size = DefaultSize
        end
        print("[Vanzyxxx] Jump Customizer Unloaded")
    end)

    print("[Vanzyxxx] Jump Customizer Loaded!")
end