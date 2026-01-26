-- features/Utility/Jump&analog.lua
-- Vanzyxxx Modular - Mobile Custom Controls
-- Developed by Alfreadrorw1
-- Type: Utility / Mobile Control Replacement

return function(UI, Services, Config, GlobalTheme)
    --// SERVICES //--
    local Players = Services.Players
    local UserInputService = Services.UserInputService
    local RunService = Services.RunService
    local TweenService = Services.TweenService
    local Workspace = Services.Workspace
    
    --// LOCALS //--
    local LocalPlayer = Players.LocalPlayer
    local Camera = Workspace.CurrentCamera
    local Mouse = LocalPlayer:GetMouse()
    
    --// CONFIGURATION //--
    local ControlConfig = {
        -- Analog Settings
        AnalogSize = 140, -- Diameter of the outer circle
        ThumbSize = 60,   -- Diameter of the inner circle
        Radius = 60,      -- Max distance thumb can travel
        Deadzone = 0.1,   -- Minimum movement to register
        Sensitivity = 1.0,
        
        -- Jump Button Settings
        JumpButtonSize = 90,
        
        -- Positions (UDim2)
        AnalogPosition = UDim2.new(0, 120, 1, -120), -- Bottom Left
        JumpPosition = UDim2.new(1, -120, 1, -140),  -- Bottom Right
        
        -- Visuals
        TransparencyIdle = 0.5,
        TransparencyActive = 0.9,
        TweenSpeed = 0.2
    }

    --// STATE //--
    local State = {
        MoveVector = Vector2.new(0, 0),
        IsJumping = false,
        AnalogTouch = nil, -- Stores the InputObject controlling the analog
        JumpTouch = nil    -- Stores the InputObject controlling the jump
    }
    
    --// THEME SYSTEM //--
    local Themes = {
        Default = {
            BaseColor = Color3.fromRGB(30, 30, 30),
            ThumbColor = Color3.fromRGB(200, 200, 200),
            JumpColor = Color3.fromRGB(200, 200, 200),
            GlowColor = Color3.fromRGB(255, 255, 255),
            StrokeColor = Color3.fromRGB(100, 100, 100)
        },
        Dark = {
            BaseColor = Color3.fromRGB(10, 10, 10),
            ThumbColor = Color3.fromRGB(60, 60, 60),
            JumpColor = Color3.fromRGB(60, 60, 60),
            GlowColor = Color3.fromRGB(100, 100, 100),
            StrokeColor = Color3.fromRGB(40, 40, 40)
        },
        Neon = {
            BaseColor = Color3.fromRGB(20, 10, 30),
            ThumbColor = Color3.fromRGB(160, 32, 240), -- Purple Neon
            JumpColor = Color3.fromRGB(160, 32, 240),
            GlowColor = Color3.fromRGB(200, 100, 255),
            StrokeColor = Color3.fromRGB(160, 32, 240)
        },
        Glass = {
            BaseColor = Color3.fromRGB(255, 255, 255),
            ThumbColor = Color3.fromRGB(240, 240, 240),
            JumpColor = Color3.fromRGB(240, 240, 240),
            GlowColor = Color3.fromRGB(255, 255, 255),
            StrokeColor = Color3.fromRGB(255, 255, 255)
        }
    }
    
    local CurrentTheme = Themes.Neon -- Default to Neon/Purple to match Vanzyxxx style

    --// UI CONSTRUCTION //--
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "VanzyMobileControls"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.DisplayOrder = 10 -- Above most generic UIs
    
    -- Parent to CoreGui or PlayerGui
    if syn and syn.protect_gui then
        syn.protect_gui(ScreenGui)
        ScreenGui.Parent = Services.CoreGui
    elseif gethui then
        ScreenGui.Parent = gethui()
    else
        ScreenGui.Parent = Services.CoreGui
    end

    -- 1. Analog Base
    local AnalogBase = Instance.new("Frame", ScreenGui)
    AnalogBase.Name = "AnalogBase"
    AnalogBase.Size = UDim2.new(0, ControlConfig.AnalogSize, 0, ControlConfig.AnalogSize)
    AnalogBase.AnchorPoint = Vector2.new(0.5, 0.5)
    AnalogBase.Position = ControlConfig.AnalogPosition
    AnalogBase.BackgroundColor3 = CurrentTheme.BaseColor
    AnalogBase.BackgroundTransparency = ControlConfig.TransparencyIdle
    
    local BaseCorner = Instance.new("UICorner", AnalogBase)
    BaseCorner.CornerRadius = UDim.new(1, 0)
    
    local BaseStroke = Instance.new("UIStroke", AnalogBase)
    BaseStroke.Color = CurrentTheme.StrokeColor
    BaseStroke.Thickness = 2
    BaseStroke.Transparency = 0.5

    -- 2. Analog Thumb
    local AnalogThumb = Instance.new("Frame", AnalogBase)
    AnalogThumb.Name = "Thumb"
    AnalogThumb.Size = UDim2.new(0, ControlConfig.ThumbSize, 0, ControlConfig.ThumbSize)
    AnalogThumb.AnchorPoint = Vector2.new(0.5, 0.5)
    AnalogThumb.Position = UDim2.new(0.5, 0, 0.5, 0)
    AnalogThumb.BackgroundColor3 = CurrentTheme.ThumbColor
    AnalogThumb.BackgroundTransparency = 0.2
    
    local ThumbCorner = Instance.new("UICorner", AnalogThumb)
    ThumbCorner.CornerRadius = UDim.new(1, 0)
    
    local ThumbGlow = Instance.new("UIStroke", AnalogThumb)
    ThumbGlow.Color = CurrentTheme.GlowColor
    ThumbGlow.Thickness = 1
    ThumbGlow.Transparency = 0.5

    -- 3. Jump Button
    local JumpButton = Instance.new("ImageButton", ScreenGui)
    JumpButton.Name = "JumpButton"
    JumpButton.Size = UDim2.new(0, ControlConfig.JumpButtonSize, 0, ControlConfig.JumpButtonSize)
    JumpButton.AnchorPoint = Vector2.new(0.5, 0.5)
    JumpButton.Position = ControlConfig.JumpPosition
    JumpButton.BackgroundColor3 = CurrentTheme.JumpColor
    JumpButton.BackgroundTransparency = ControlConfig.TransparencyIdle
    JumpButton.Image = "" -- Can add an arrow asset here if needed
    JumpButton.AutoButtonColor = false
    
    local JumpCorner = Instance.new("UICorner", JumpButton)
    JumpCorner.CornerRadius = UDim.new(1, 0)
    
    local JumpStroke = Instance.new("UIStroke", JumpButton)
    JumpStroke.Color = CurrentTheme.StrokeColor
    JumpStroke.Thickness = 2
    JumpStroke.Transparency = 0.5

    -- Jump Icon (Text for now, can be image)
    local JumpIcon = Instance.new("TextLabel", JumpButton)
    JumpIcon.Size = UDim2.new(1, 0, 1, 0)
    JumpIcon.BackgroundTransparency = 1
    JumpIcon.Text = "⬆"
    JumpIcon.TextColor3 = CurrentTheme.GlowColor
    JumpIcon.TextSize = 40
    JumpIcon.Font = Enum.Font.GothamBlack

    --// FUNCTIONS //--

    -- Helper: Disable default controls
    local function DisableDefaultControls()
        if LocalPlayer.PlayerGui:FindFirstChild("TouchGui") then
            LocalPlayer.PlayerGui.TouchGui.Enabled = false
        end
    end

    -- Helper: Tween Wrapper
    local function Tween(instance, properties, duration)
        duration = duration or ControlConfig.TweenSpeed
        TweenService:Create(instance, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), properties):Play()
    end

    -- API: Set Theme
    local function SetTheme(themeName)
        if Themes[themeName] then
            CurrentTheme = Themes[themeName]
            
            -- Apply
            Tween(AnalogBase, {BackgroundColor3 = CurrentTheme.BaseColor})
            Tween(BaseStroke, {Color = CurrentTheme.StrokeColor})
            
            Tween(AnalogThumb, {BackgroundColor3 = CurrentTheme.ThumbColor})
            Tween(ThumbGlow, {Color = CurrentTheme.GlowColor})
            
            Tween(JumpButton, {BackgroundColor3 = CurrentTheme.JumpColor})
            Tween(JumpStroke, {Color = CurrentTheme.StrokeColor})
            JumpIcon.TextColor3 = CurrentTheme.GlowColor
        end
    end

    -- Logic: Update Character Movement
    local function UpdateCharacterMovement()
        if not LocalPlayer.Character then return end
        local Humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
        if not Humanoid then return end

        if State.MoveVector.Magnitude > ControlConfig.Deadzone then
            -- Calculate Camera Relative Direction
            local CamLook = Camera.CFrame.LookVector
            local CamRight = Camera.CFrame.RightVector
            
            -- Flatten Y to keep movement horizontal
            local Look = Vector3.new(CamLook.X, 0, CamLook.Z).Unit
            local Right = Vector3.new(CamRight.X, 0, CamRight.Z).Unit
            
            -- Combine inputs
            local MoveDir = (Right * State.MoveVector.X) + (Look * -State.MoveVector.Y)
            
            Humanoid:Move(MoveDir, false)
        else
            Humanoid:Move(Vector3.new(0, 0, 0), false)
        end
    end

    -- Logic: Jump
    local function DoJump(state)
        if not LocalPlayer.Character then return end
        local Humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
        if not Humanoid then return end
        
        Humanoid.Jump = state
    end

    --// EVENT HANDLERS //--

    -- Input Began
    UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            local inputPos = Vector2.new(input.Position.X, input.Position.Y)
            
            -- Check Jump Button
            local jumpCenter = JumpButton.AbsolutePosition + (JumpButton.AbsoluteSize / 2)
            local distJump = (inputPos - jumpCenter).Magnitude
            
            if distJump <= (ControlConfig.JumpButtonSize / 2) * 1.5 then
                State.JumpTouch = input
                DoJump(true)
                
                -- Visual Feedback
                Tween(JumpButton, {
                    Size = UDim2.new(0, ControlConfig.JumpButtonSize * 0.9, 0, ControlConfig.JumpButtonSize * 0.9),
                    BackgroundTransparency = 0.2
                }, 0.1)
                return
            end

            -- Check Analog Area (Dynamic check: Is it in the bottom left quadrant?)
            local analogCenter = AnalogBase.AbsolutePosition + (AnalogBase.AbsoluteSize / 2)
            local distAnalog = (inputPos - analogCenter).Magnitude
            
            -- Allow touch slightly outside the visual circle for better UX
            if distAnalog <= ControlConfig.AnalogSize * 1.2 and State.AnalogTouch == nil then
                State.AnalogTouch = input
                
                -- Activate Visuals
                Tween(AnalogBase, {BackgroundTransparency = 0.3})
                Tween(AnalogThumb, {Size = UDim2.new(0, ControlConfig.ThumbSize * 1.2, 0, ControlConfig.ThumbSize * 1.2)}, 0.1)
            end
        end
    end)

    -- Input Changed (Movement)
    UserInputService.InputChanged:Connect(function(input)
        if input == State.AnalogTouch then
            local inputPos = Vector2.new(input.Position.X, input.Position.Y)
            local center = AnalogBase.AbsolutePosition + (AnalogBase.AbsoluteSize / 2)
            local vector = inputPos - center
            
            -- Clamp vector to radius
            if vector.Magnitude > ControlConfig.Radius then
                vector = vector.Unit * ControlConfig.Radius
            end
            
            -- Move Thumb
            AnalogThumb.Position = UDim2.new(0.5, vector.X, 0.5, vector.Y)
            
            -- Update State (Normalize -1 to 1)
            State.MoveVector = Vector2.new(
                vector.X / ControlConfig.Radius * ControlConfig.Sensitivity,
                vector.Y / ControlConfig.Radius * ControlConfig.Sensitivity
            )
        end
    end)

    -- Input Ended
    UserInputService.InputEnded:Connect(function(input)
        if input == State.AnalogTouch then
            State.AnalogTouch = nil
            State.MoveVector = Vector2.new(0, 0)
            
            -- Reset Visuals
            Tween(AnalogThumb, {
                Position = UDim2.new(0.5, 0, 0.5, 0),
                Size = UDim2.new(0, ControlConfig.ThumbSize, 0, ControlConfig.ThumbSize)
            }, 0.2)
            Tween(AnalogBase, {BackgroundTransparency = ControlConfig.TransparencyIdle})
            
        elseif input == State.JumpTouch then
            State.JumpTouch = nil
            DoJump(false)
            
            -- Reset Visuals
            Tween(JumpButton, {
                Size = UDim2.new(0, ControlConfig.JumpButtonSize, 0, ControlConfig.JumpButtonSize),
                BackgroundTransparency = ControlConfig.TransparencyIdle
            }, 0.2)
        end
    end)

    -- Game Loop
    local connection = RunService.RenderStepped:Connect(function()
        DisableDefaultControls() -- Keep enforcing
        UpdateCharacterMovement()
    end)
    
    -- Cleanup on Destroy
    local function Destroy()
        if connection then connection:Disconnect() end
        if ScreenGui then ScreenGui:Destroy() end
        
        -- Restore default controls if needed
        if LocalPlayer.PlayerGui:FindFirstChild("TouchGui") then
            LocalPlayer.PlayerGui.TouchGui.Enabled = true
        end
    end

    -- Handle Script Termination from Main
    if Config.OnReset then
        Config.OnReset.Event:Connect(Destroy)
    end

    --// INIT //--
    DisableDefaultControls()
    
    -- Set Initial Theme based on Config if available, else Neon
    if GlobalTheme and GlobalTheme.Accent then
        Themes.Custom = {
            BaseColor = Color3.fromRGB(20, 20, 30),
            ThumbColor = GlobalTheme.Accent,
            JumpColor = GlobalTheme.Accent,
            GlowColor = GlobalTheme.Accent,
            StrokeColor = Color3.fromRGB(255, 255, 255)
        }
        SetTheme("Custom")
    else
        SetTheme("Neon")
    end

    -- Notification
    Services.StarterGui:SetCore("SendNotification", {
        Title = "Controls Loaded",
        Text = "Custom Analog & Jump Active",
        Duration = 3
    })
    
    -- Return API
    return {
        SetTheme = SetTheme,
        GetVector = function() return State.MoveVector end,
        Destroy = Destroy
    }
end
