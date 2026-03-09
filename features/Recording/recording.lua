-- Vanzyxxx Recording System V1
-- Records all character activity: walk, run, idle, jump, fly
-- Mini Widget: Play / Stop / Replay | Save per CP Segment (CP1 → CP2 → FINISH)
-- by Vanzyxxx (Alfreadrorw1)

return function(UI, Services, Config, Theme)
    local LocalPlayer  = Services.Players.LocalPlayer
    local RunService   = Services.RunService
    local UserInputService = Services.UserInputService
    local HttpService  = Services.HttpService

    -- ══════════════════════════════════════════
    --  CONSTANTS & STATE
    -- ══════════════════════════════════════════
    local RECORD_INTERVAL = 0.05          -- snapshot every 50ms  (~20fps)
    local MAX_FRAMES      = 36000         -- safety cap  (~30 min at 20fps)
    local REPLAY_SPEED    = 1             -- multiplier (1 = realtime)
    local SAVE_FILE       = "VanzyRecord.json"

    -- State
    local RecState = {
        IsRecording  = false,
        IsReplaying  = false,
        IsPaused     = false,

        -- Current live recording buffer
        ActiveFrames = {},
        ActiveMeta   = { StartCP = nil, EndCP = nil, MapId = nil, MapName = nil, Duration = 0, RecordedAt = 0 },

        -- All saved recordings  { [1]={ meta, frames }, ... }
        SavedRecs    = {},

        -- Replay runtime
        ReplayIndex  = 1,
        ReplayConn   = nil,
        ReplayGhost  = nil,   -- ghost model (clone of character)

        -- Connections
        RecordConn   = nil,
    }

    -- ══════════════════════════════════════════
    --  TAB
    -- ══════════════════════════════════════════
    local RecTab = UI:Tab("Recording")
    RecTab:Label("🎬 Character Recording System")

    -- ══════════════════════════════════════════
    --  UTILITY
    -- ══════════════════════════════════════════
    local function GetMapId()   return tostring(game.PlaceId) end
    local function GetMapName()
        local ok, info = pcall(function()
            return Services.MarketplaceService and Services.MarketplaceService:GetProductInfo(game.PlaceId)
        end)
        return (ok and info) and info.Name or ("Map_"..GetMapId())
    end
    local function Timestamp() return math.floor(tick()) end

    -- Detect humanoid state tag
    local function GetMoveTag(hum, rootVel)
        if not hum then return "IDLE" end
        local state = hum:GetState()
        if state == Enum.HumanoidStateType.Jumping  then return "JUMP"    end
        if state == Enum.HumanoidStateType.Freefall  then return "FALL"    end
        if state == Enum.HumanoidStateType.Landed    then return "LAND"    end
        if Config.Flying                              then return "FLY"     end
        local speed = Vector3.new(rootVel.X, 0, rootVel.Z).Magnitude
        if speed > 18 then return "RUN"
        elseif speed > 1 then return "WALK"
        else return "IDLE" end
    end

    -- ══════════════════════════════════════════
    --  PERSISTENCE
    -- ══════════════════════════════════════════
    local function LoadSaved()
        if isfile and isfile(SAVE_FILE) then
            local ok, data = pcall(function()
                return HttpService:JSONDecode(readfile(SAVE_FILE))
            end)
            if ok and type(data) == "table" then return data end
        end
        return {}
    end

    local function PersistSaved(data)
        if writefile then
            pcall(function()
                writefile(SAVE_FILE, HttpService:JSONEncode(data))
            end)
        end
    end

    -- Load existing saves on startup
    RecState.SavedRecs = LoadSaved()

    -- ══════════════════════════════════════════
    --  GHOST MODEL (replay visual)
    -- ══════════════════════════════════════════
    local function BuildGhost()
        -- Destroy old ghost
        if RecState.ReplayGhost then
            RecState.ReplayGhost:Destroy()
            RecState.ReplayGhost = nil
        end

        local char = LocalPlayer.Character
        if not char then return end

        -- Deep clone character
        local ghost = char:Clone()
        ghost.Name = "VanzyGhost"

        -- Strip scripts & humanoid AI so it doesn't move on its own
        for _, v in ipairs(ghost:GetDescendants()) do
            if v:IsA("Script") or v:IsA("LocalScript") or v:IsA("Animator") then
                v:Destroy()
            end
        end

        -- Make ghost translucent purple
        for _, part in ipairs(ghost:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Anchored       = true
                part.CanCollide     = false
                part.Transparency   = 0.55
                part.Color          = Color3.fromRGB(160, 80, 255)
                part.CastShadow     = false
            end
            if part:IsA("Decal") or part:IsA("Texture") or part:IsA("SpecialMesh") then
                -- keep mesh, remove decals
                if part:IsA("Decal") or part:IsA("Texture") then part:Destroy() end
            end
        end

        -- Add name tag above ghost
        local tag = Instance.new("BillboardGui", ghost:FindFirstChild("Head") or ghost.PrimaryPart or ghost)
        tag.Size = UDim2.new(0, 100, 0, 20)
        tag.StudsOffset = Vector3.new(0, 2.5, 0)
        tag.AlwaysOnTop = true
        local lbl = Instance.new("TextLabel", tag)
        lbl.Size = UDim2.new(1, 0, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = "▶ REPLAY"
        lbl.TextColor3 = Color3.fromRGB(200, 150, 255)
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 12

        ghost.Parent = Services.Workspace
        RecState.ReplayGhost = ghost
        return ghost
    end

    local function DestroyGhost()
        if RecState.ReplayGhost then
            RecState.ReplayGhost:Destroy()
            RecState.ReplayGhost = nil
        end
    end

    -- Apply a single frame to ghost
    local function ApplyFrameToGhost(ghost, frame)
        if not ghost or not ghost.Parent then return end

        -- Move PrimaryPart / HumanoidRootPart
        local root = ghost:FindFirstChild("HumanoidRootPart")
        if root then
            local cf = CFrame.new(
                frame.px, frame.py, frame.pz,
                frame.rx, frame.ry, frame.rz,
                frame.ux, frame.uy, frame.uz,
                frame.lx, frame.ly, frame.lz
            )
            root.CFrame = cf
        end

        -- Update humanoid state label
        local hum = ghost:FindFirstChildOfClass("Humanoid")
        if hum then
            -- visual only: change hip height or walkspeed to simulate animation
            -- (no animator = no actual animation, but at least state is set)
            local stateMap = {
                JUMP  = Enum.HumanoidStateType.Jumping,
                FALL  = Enum.HumanoidStateType.Freefall,
                LAND  = Enum.HumanoidStateType.Landed,
                RUN   = Enum.HumanoidStateType.Running,
                WALK  = Enum.HumanoidStateType.Running,
                IDLE  = Enum.HumanoidStateType.Running,
                FLY   = Enum.HumanoidStateType.Physics,
            }
            pcall(function()
                hum:ChangeState(stateMap[frame.tag] or Enum.HumanoidStateType.Running)
            end)
        end
    end

    -- ══════════════════════════════════════════
    --  RECORD LOGIC
    -- ══════════════════════════════════════════
    local function StartRecord(startCPName)
        if RecState.IsRecording then return end
        if RecState.IsReplaying then return end

        RecState.IsRecording  = true
        RecState.ActiveFrames = {}
        RecState.ActiveMeta   = {
            StartCP    = startCPName or "CP_START",
            EndCP      = nil,
            MapId      = GetMapId(),
            MapName    = GetMapName(),
            Duration   = 0,
            RecordedAt = Timestamp(),
        }

        local startTime = tick()
        local lastSnap  = 0

        RecState.RecordConn = RunService.Heartbeat:Connect(function(dt)
            if not RecState.IsRecording then return end
            local now = tick()
            if (now - lastSnap) < RECORD_INTERVAL then return end
            lastSnap = now

            local char = LocalPlayer.Character
            if not char then return end
            local root = char:FindFirstChild("HumanoidRootPart")
            local hum  = char:FindFirstChildOfClass("Humanoid")
            if not root then return end

            local cf  = root.CFrame
            local vel = root.AssemblyLinearVelocity

            -- Store compact frame
            local frame = {
                t  = now - startTime,           -- relative timestamp
                -- CFrame components (avoid JSONing CFrame directly)
                px = cf.X,  py = cf.Y,  pz = cf.Z,
                rx = cf.RightVector.X,  ry = cf.RightVector.Y,  rz = cf.RightVector.Z,
                ux = cf.UpVector.X,     uy = cf.UpVector.Y,     uz = cf.UpVector.Z,
                lx = cf.LookVector.X,   ly = cf.LookVector.Y,   lz = cf.LookVector.Z,
                -- movement tag
                tag = GetMoveTag(hum, vel),
                -- extra
                vx = vel.X, vy = vel.Y, vz = vel.Z,
            }

            table.insert(RecState.ActiveFrames, frame)

            -- Safety cap
            if #RecState.ActiveFrames >= MAX_FRAMES then
                -- auto-stop
                RecState.IsRecording = false
                if RecState.RecordConn then RecState.RecordConn:Disconnect(); RecState.RecordConn = nil end
                Services.StarterGui:SetCore("SendNotification", {Title="⚠ Recording", Text="Max length reached! Auto-stopped.", Duration=4})
            end

            -- Update duration
            RecState.ActiveMeta.Duration = now - startTime
        end)

        Services.StarterGui:SetCore("SendNotification", {
            Title = "🔴 Recording",
            Text  = "Started from " .. (startCPName or "START"),
            Duration = 3
        })
    end

    local function StopRecord(endCPName)
        if not RecState.IsRecording then return end
        RecState.IsRecording = false

        if RecState.RecordConn then
            RecState.RecordConn:Disconnect()
            RecState.RecordConn = nil
        end

        RecState.ActiveMeta.EndCP    = endCPName or "CP_END"
        RecState.ActiveMeta.Duration = RecState.ActiveMeta.Duration or 0

        local frameCount = #RecState.ActiveFrames

        if frameCount < 2 then
            Services.StarterGui:SetCore("SendNotification", {Title="Recording", Text="Too short, not saved.", Duration=3})
            return
        end

        -- Package the recording
        local rec = {
            meta   = {
                id         = "rec_" .. Timestamp(),
                StartCP    = RecState.ActiveMeta.StartCP,
                EndCP      = RecState.ActiveMeta.EndCP,
                MapId      = RecState.ActiveMeta.MapId,
                MapName    = RecState.ActiveMeta.MapName,
                Duration   = math.floor(RecState.ActiveMeta.Duration * 10) / 10,
                RecordedAt = RecState.ActiveMeta.RecordedAt,
                Frames     = frameCount,
            },
            frames = RecState.ActiveFrames,
        }

        table.insert(RecState.SavedRecs, rec)
        PersistSaved(RecState.SavedRecs)

        Services.StarterGui:SetCore("SendNotification", {
            Title = "💾 Saved!",
            Text  = rec.meta.StartCP .. " → " .. rec.meta.EndCP ..
                    " | " .. frameCount .. " frames | " .. math.floor(rec.meta.Duration) .. "s",
            Duration = 5
        })

        -- Reset buffer
        RecState.ActiveFrames = {}
        return rec
    end

    -- ══════════════════════════════════════════
    --  REPLAY LOGIC
    -- ══════════════════════════════════════════
    local function StopReplay()
        RecState.IsReplaying = false
        RecState.IsPaused    = false

        if RecState.ReplayConn then
            RecState.ReplayConn:Disconnect()
            RecState.ReplayConn = nil
        end

        DestroyGhost()
    end

    local function StartReplay(recEntry, onFinish)
        if RecState.IsRecording then
            Services.StarterGui:SetCore("SendNotification", {Title="⚠", Text="Stop recording first!", Duration=2})
            return
        end

        StopReplay()  -- clean up any previous

        local frames = recEntry.frames
        if not frames or #frames < 2 then
            Services.StarterGui:SetCore("SendNotification", {Title="⚠", Text="No frames to replay!", Duration=2})
            return
        end

        RecState.IsReplaying = true
        RecState.IsPaused    = false
        RecState.ReplayIndex = 1

        local ghost = BuildGhost()
        if not ghost then
            RecState.IsReplaying = false
            return
        end

        -- time-based playback
        local replayStart   = tick()
        local recordStart   = frames[1].t

        RecState.ReplayConn = RunService.Heartbeat:Connect(function()
            if not RecState.IsReplaying then return end
            if RecState.IsPaused then return end

            local elapsed = (tick() - replayStart) * REPLAY_SPEED + recordStart

            -- advance index to current time
            while RecState.ReplayIndex < #frames and frames[RecState.ReplayIndex + 1].t <= elapsed do
                RecState.ReplayIndex = RecState.ReplayIndex + 1
            end

            local frame = frames[RecState.ReplayIndex]
            if frame then
                ApplyFrameToGhost(ghost, frame)
            end

            -- finished
            if RecState.ReplayIndex >= #frames then
                StopReplay()
                if onFinish then onFinish() end
                Services.StarterGui:SetCore("SendNotification", {Title="✅ Replay", Text="Finished!", Duration=3})
            end
        end)

        Services.StarterGui:SetCore("SendNotification", {
            Title = "▶ Replay",
            Text  = recEntry.meta.StartCP .. " → " .. recEntry.meta.EndCP ..
                    " (" .. math.floor(recEntry.meta.Duration) .. "s)",
            Duration = 3
        })
    end

    -- ══════════════════════════════════════════
    --  WIDGET UI  (draggable mini panel)
    -- ══════════════════════════════════════════
    local RecWidget     = nil
    local RecStatusLbl  = nil
    local RecTimerLbl   = nil
    local BtnRecord     = nil
    local BtnStop       = nil
    local BtnReplay     = nil
    local BtnManager    = nil
    local RecManagerFrame = nil

    -- Timer display updater
    local TimerConn = nil
    local function StartTimerDisplay()
        if TimerConn then TimerConn:Disconnect() end
        TimerConn = RunService.Heartbeat:Connect(function()
            if not RecWidget or not RecWidget.Parent then return end
            if RecState.IsRecording then
                local elapsed = math.floor(RecState.ActiveMeta.Duration or 0)
                local frames  = #RecState.ActiveFrames
                if RecTimerLbl then
                    RecTimerLbl.Text = string.format("⏺ %02d:%02d  %d fr", math.floor(elapsed/60), elapsed%60, frames)
                    RecTimerLbl.TextColor3 = Color3.fromRGB(255, 80, 80)
                end
            elseif RecState.IsReplaying then
                local idx     = RecState.ReplayIndex
                if RecTimerLbl then
                    RecTimerLbl.Text = string.format("▶ frame %d", idx)
                    RecTimerLbl.TextColor3 = Color3.fromRGB(100, 200, 255)
                end
            else
                if RecTimerLbl then
                    RecTimerLbl.Text = "⬛ Idle"
                    RecTimerLbl.TextColor3 = Color3.fromRGB(180, 180, 180)
                end
            end
        end)
    end

    -- ─── Manager Window ─────────────────────────
    local ManagerListFrame = nil

    local function RefreshManagerList()
        if not ManagerListFrame then return end

        -- Clear existing
        for _, c in ipairs(ManagerListFrame:GetChildren()) do
            if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then c:Destroy() end
        end

        if #RecState.SavedRecs == 0 then
            local empty = Instance.new("TextLabel", ManagerListFrame)
            empty.Size = UDim2.new(1, 0, 0, 30)
            empty.BackgroundTransparency = 1
            empty.Text = "No recordings saved yet."
            empty.TextColor3 = Color3.fromRGB(160, 160, 160)
            empty.Font = Enum.Font.Gotham
            empty.TextSize = 11
            ManagerListFrame.CanvasSize = UDim2.new(0, 0, 0, 40)
            return
        end

        for i = #RecState.SavedRecs, 1, -1 do      -- newest first
            local rec  = RecState.SavedRecs[i]
            local meta = rec.meta

            local row = Instance.new("Frame", ManagerListFrame)
            row.Size             = UDim2.new(1, 0, 0, 52)
            row.BackgroundColor3 = Theme.Button
            row.ZIndex           = 62
            Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

            -- Label
            local info = Instance.new("TextLabel", row)
            info.Size               = UDim2.new(1, -10, 0, 18)
            info.Position           = UDim2.new(0, 8, 0, 4)
            info.BackgroundTransparency = 1
            info.Text               = string.format("🔖 %s → %s", meta.StartCP, meta.EndCP)
            info.TextColor3         = Theme.Accent
            info.Font               = Enum.Font.GothamBold
            info.TextSize           = 11
            info.TextXAlignment     = Enum.TextXAlignment.Left
            info.ZIndex             = 63

            local detail = Instance.new("TextLabel", row)
            detail.Size               = UDim2.new(1, -10, 0, 14)
            detail.Position           = UDim2.new(0, 8, 0, 22)
            detail.BackgroundTransparency = 1
            detail.Text               = string.format(
                "🗺 %s  |  ⏱ %ds  |  🎞 %d fr",
                (meta.MapName or "?"):sub(1, 18), math.floor(meta.Duration or 0), meta.Frames or 0
            )
            detail.TextColor3         = Color3.fromRGB(180, 180, 180)
            detail.Font               = Enum.Font.Gotham
            detail.TextSize           = 10
            detail.TextXAlignment     = Enum.TextXAlignment.Left
            detail.ZIndex             = 63

            -- Buttons row
            local btnY = 0.62

            -- Play
            local playBtn = Instance.new("TextButton", row)
            playBtn.Size             = UDim2.new(0.28, 0, 0.35, 0)
            playBtn.Position         = UDim2.new(0.01, 0, btnY, 0)
            playBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 100)
            playBtn.Text             = "▶ Play"
            playBtn.TextColor3       = Theme.Text
            playBtn.Font             = Enum.Font.GothamBold
            playBtn.TextSize         = 10
            playBtn.ZIndex           = 63
            Instance.new("UICorner", playBtn).CornerRadius = UDim.new(0, 4)

            -- Replay (loop once more from start)
            local replayBtn = Instance.new("TextButton", row)
            replayBtn.Size             = UDim2.new(0.28, 0, 0.35, 0)
            replayBtn.Position         = UDim2.new(0.36, 0, btnY, 0)
            replayBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 220)
            replayBtn.Text             = "🔁 Replay"
            replayBtn.TextColor3       = Theme.Text
            replayBtn.Font             = Enum.Font.GothamBold
            replayBtn.TextSize         = 10
            replayBtn.ZIndex           = 63
            Instance.new("UICorner", replayBtn).CornerRadius = UDim.new(0, 4)

            -- Delete
            local delBtn = Instance.new("TextButton", row)
            delBtn.Size             = UDim2.new(0.28, 0, 0.35, 0)
            delBtn.Position         = UDim2.new(0.70, 0, btnY, 0)
            delBtn.BackgroundColor3 = Theme.ButtonRed
            delBtn.Text             = "🗑 Del"
            delBtn.TextColor3       = Theme.Text
            delBtn.Font             = Enum.Font.GothamBold
            delBtn.TextSize         = 10
            delBtn.ZIndex           = 63
            Instance.new("UICorner", delBtn).CornerRadius = UDim.new(0, 4)

            local capturedRec = rec
            local capturedIdx = i

            playBtn.MouseButton1Click:Connect(function()
                StartReplay(capturedRec, function()
                    -- onFinish callback: could trigger auto next segment
                end)
            end)

            replayBtn.MouseButton1Click:Connect(function()
                StopReplay()
                task.wait(0.1)
                StartReplay(capturedRec)
            end)

            delBtn.MouseButton1Click:Connect(function()
                UI:Confirm("Delete recording " .. meta.StartCP .. "→" .. meta.EndCP .. "?", function()
                    table.remove(RecState.SavedRecs, capturedIdx)
                    PersistSaved(RecState.SavedRecs)
                    RefreshManagerList()
                end)
            end)
        end

        -- Update canvas height
        local layout = ManagerListFrame:FindFirstChildOfClass("UIListLayout")
        if layout then
            ManagerListFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
        end
    end

    local function CreateManagerWindow()
        if RecManagerFrame then RecManagerFrame:Destroy(); RecManagerFrame = nil end

        local screenGui = UI:GetScreenGui()
        if not screenGui then return end

        local MF = Instance.new("Frame", screenGui)
        MF.Name             = "RecManager"
        MF.Size             = UDim2.new(0, 340, 0, 400)
        MF.Position         = UDim2.new(0.5, -170, 0.5, -200)
        MF.BackgroundColor3 = Theme.Main
        MF.Visible          = false
        MF.ZIndex           = 60
        Instance.new("UICorner", MF).CornerRadius = UDim.new(0, 10)
        local mfStroke = Instance.new("UIStroke", MF)
        mfStroke.Color     = Theme.Accent
        mfStroke.Thickness = 2

        -- Header
        local header = Instance.new("TextLabel", MF)
        header.Size               = UDim2.new(1, -50, 0, 32)
        header.Position           = UDim2.new(0, 10, 0, 0)
        header.BackgroundTransparency = 1
        header.Text               = "🎬 RECORDING MANAGER"
        header.TextColor3         = Theme.Accent
        header.Font               = Enum.Font.GothamBlack
        header.TextSize           = 13
        header.TextXAlignment     = Enum.TextXAlignment.Left
        header.ZIndex             = 61

        -- Close
        local closeBtn = Instance.new("TextButton", MF)
        closeBtn.Size               = UDim2.new(0, 32, 0, 32)
        closeBtn.Position           = UDim2.new(1, -36, 0, 0)
        closeBtn.BackgroundTransparency = 1
        closeBtn.Text               = "✕"
        closeBtn.TextColor3         = Color3.fromRGB(255, 60, 60)
        closeBtn.Font               = Enum.Font.GothamBlack
        closeBtn.TextSize           = 18
        closeBtn.ZIndex             = 61
        closeBtn.MouseButton1Click:Connect(function() MF.Visible = false end)

        -- Divider
        local div = Instance.new("Frame", MF)
        div.Size             = UDim2.new(1, -20, 0, 1)
        div.Position         = UDim2.new(0, 10, 0, 33)
        div.BackgroundColor3 = Theme.Accent
        div.BorderSizePixel  = 0
        div.ZIndex           = 61

        -- Top bar: New Record / Stop Replay
        local topBar = Instance.new("Frame", MF)
        topBar.Size             = UDim2.new(1, -20, 0, 38)
        topBar.Position         = UDim2.new(0, 10, 0, 38)
        topBar.BackgroundTransparency = 1
        topBar.ZIndex           = 61

        -- CP selector label
        local cpLabel = Instance.new("TextLabel", topBar)
        cpLabel.Size               = UDim2.new(0.35, 0, 1, 0)
        cpLabel.BackgroundTransparency = 1
        cpLabel.Text               = "Start CP:"
        cpLabel.TextColor3         = Theme.Text
        cpLabel.Font               = Enum.Font.Gotham
        cpLabel.TextSize           = 11
        cpLabel.TextXAlignment     = Enum.TextXAlignment.Left
        cpLabel.ZIndex             = 62

        -- CP Name input (TextBox)
        local cpInput = Instance.new("TextBox", topBar)
        cpInput.Size               = UDim2.new(0.32, 0, 0.85, 0)
        cpInput.Position           = UDim2.new(0.33, 0, 0.07, 0)
        cpInput.BackgroundColor3   = Theme.ButtonDark or Theme.Button
        cpInput.Text               = "CP1"
        cpInput.TextColor3         = Theme.Text
        cpInput.Font               = Enum.Font.GothamBold
        cpInput.TextSize           = 12
        cpInput.ClearTextOnFocus   = false
        cpInput.ZIndex             = 62
        Instance.new("UICorner", cpInput).CornerRadius = UDim.new(0, 4)

        -- Record / Stop Rec Button (top right)
        local recBtn = Instance.new("TextButton", topBar)
        recBtn.Size             = UDim2.new(0.28, 0, 0.85, 0)
        recBtn.Position         = UDim2.new(0.70, 0, 0.07, 0)
        recBtn.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
        recBtn.Text             = "⏺ REC"
        recBtn.TextColor3       = Theme.Text
        recBtn.Font             = Enum.Font.GothamBlack
        recBtn.TextSize         = 12
        recBtn.ZIndex           = 62
        Instance.new("UICorner", recBtn).CornerRadius = UDim.new(0, 4)

        -- Second row: Stop + End CP
        local row2 = Instance.new("Frame", MF)
        row2.Size             = UDim2.new(1, -20, 0, 34)
        row2.Position         = UDim2.new(0, 10, 0, 80)
        row2.BackgroundTransparency = 1
        row2.ZIndex           = 61

        local endCpLabel = Instance.new("TextLabel", row2)
        endCpLabel.Size               = UDim2.new(0.35, 0, 1, 0)
        endCpLabel.BackgroundTransparency = 1
        endCpLabel.Text               = "End CP:"
        endCpLabel.TextColor3         = Theme.Text
        endCpLabel.Font               = Enum.Font.Gotham
        endCpLabel.TextSize           = 11
        endCpLabel.TextXAlignment     = Enum.TextXAlignment.Left
        endCpLabel.ZIndex             = 62

        local endCpInput = Instance.new("TextBox", row2)
        endCpInput.Size               = UDim2.new(0.32, 0, 0.85, 0)
        endCpInput.Position           = UDim2.new(0.33, 0, 0.07, 0)
        endCpInput.BackgroundColor3   = Theme.ButtonDark or Theme.Button
        endCpInput.Text               = "CP2"
        endCpInput.TextColor3         = Theme.Text
        endCpInput.Font               = Enum.Font.GothamBold
        endCpInput.TextSize           = 12
        endCpInput.ClearTextOnFocus   = false
        endCpInput.ZIndex             = 62
        Instance.new("UICorner", endCpInput).CornerRadius = UDim.new(0, 4)

        local stopRecBtn = Instance.new("TextButton", row2)
        stopRecBtn.Size             = UDim2.new(0.28, 0, 0.85, 0)
        stopRecBtn.Position         = UDim2.new(0.70, 0, 0.07, 0)
        stopRecBtn.BackgroundColor3 = Color3.fromRGB(150, 100, 0)
        stopRecBtn.Text             = "⏹ STOP"
        stopRecBtn.TextColor3       = Theme.Text
        stopRecBtn.Font             = Enum.Font.GothamBlack
        stopRecBtn.TextSize         = 12
        stopRecBtn.ZIndex           = 62
        Instance.new("UICorner", stopRecBtn).CornerRadius = UDim.new(0, 4)

        -- Status bar
        local statusBar = Instance.new("Frame", MF)
        statusBar.Size             = UDim2.new(1, -20, 0, 22)
        statusBar.Position         = UDim2.new(0, 10, 0, 118)
        statusBar.BackgroundColor3 = Theme.ButtonDark or Theme.Sidebar
        statusBar.ZIndex           = 61
        Instance.new("UICorner", statusBar).CornerRadius = UDim.new(0, 4)

        local statusLbl = Instance.new("TextLabel", statusBar)
        statusLbl.Size               = UDim2.new(1, -8, 1, 0)
        statusLbl.Position           = UDim2.new(0, 4, 0, 0)
        statusLbl.BackgroundTransparency = 1
        statusLbl.Text               = "⬛ Idle — ready to record"
        statusLbl.TextColor3         = Color3.fromRGB(180, 180, 180)
        statusLbl.Font               = Enum.Font.Gotham
        statusLbl.TextSize           = 10
        statusLbl.TextXAlignment     = Enum.TextXAlignment.Left
        statusLbl.ZIndex             = 62
        RecTimerLbl = statusLbl

        -- Replay controls bar
        local replayBar = Instance.new("Frame", MF)
        replayBar.Size             = UDim2.new(1, -20, 0, 30)
        replayBar.Position         = UDim2.new(0, 10, 0, 144)
        replayBar.BackgroundTransparency = 1
        replayBar.ZIndex           = 61

        local stopReplayBtn = Instance.new("TextButton", replayBar)
        stopReplayBtn.Size             = UDim2.new(0.48, 0, 1, 0)
        stopReplayBtn.BackgroundColor3 = Theme.ButtonRed
        stopReplayBtn.Text             = "⏹ Stop Replay"
        stopReplayBtn.TextColor3       = Theme.Text
        stopReplayBtn.Font             = Enum.Font.GothamBold
        stopReplayBtn.TextSize         = 11
        stopReplayBtn.ZIndex           = 62
        Instance.new("UICorner", stopReplayBtn).CornerRadius = UDim.new(0, 4)

        local pauseReplayBtn = Instance.new("TextButton", replayBar)
        pauseReplayBtn.Size             = UDim2.new(0.48, 0, 1, 0)
        pauseReplayBtn.Position         = UDim2.new(0.52, 0, 0, 0)
        pauseReplayBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 160)
        pauseReplayBtn.Text             = "⏸ Pause"
        pauseReplayBtn.TextColor3       = Theme.Text
        pauseReplayBtn.Font             = Enum.Font.GothamBold
        pauseReplayBtn.TextSize         = 11
        pauseReplayBtn.ZIndex           = 62
        Instance.new("UICorner", pauseReplayBtn).CornerRadius = UDim.new(0, 4)

        -- Divider 2
        local div2 = Instance.new("Frame", MF)
        div2.Size             = UDim2.new(1, -20, 0, 1)
        div2.Position         = UDim2.new(0, 10, 0, 178)
        div2.BackgroundColor3 = Theme.Accent
        div2.BorderSizePixel  = 0
        div2.ZIndex           = 61

        -- Saved recordings label
        local savedHdr = Instance.new("TextLabel", MF)
        savedHdr.Size               = UDim2.new(1, -10, 0, 18)
        savedHdr.Position           = UDim2.new(0, 10, 0, 182)
        savedHdr.BackgroundTransparency = 1
        savedHdr.Text               = "💾 SAVED RECORDINGS"
        savedHdr.TextColor3         = Theme.Accent
        savedHdr.Font               = Enum.Font.GothamBlack
        savedHdr.TextSize           = 11
        savedHdr.TextXAlignment     = Enum.TextXAlignment.Left
        savedHdr.ZIndex             = 61

        -- Scrollable list
        local listScroll = Instance.new("ScrollingFrame", MF)
        listScroll.Size             = UDim2.new(1, -20, 0, 196)
        listScroll.Position         = UDim2.new(0, 10, 0, 200)
        listScroll.BackgroundTransparency = 1
        listScroll.ScrollBarThickness = 3
        listScroll.ZIndex           = 61
        listScroll.AutomaticCanvasSize = Enum.AutomaticSize.None

        local listLayout = Instance.new("UIListLayout", listScroll)
        listLayout.Padding          = UDim.new(0, 5)
        local listPad = Instance.new("UIPadding", listScroll)
        listPad.PaddingTop = UDim.new(0, 4)

        ManagerListFrame = listScroll

        -- ─── Button events ───────────────────────
        recBtn.MouseButton1Click:Connect(function()
            if RecState.IsRecording then
                Services.StarterGui:SetCore("SendNotification", {Title="⚠", Text="Already recording!", Duration=2})
            elseif RecState.IsReplaying then
                Services.StarterGui:SetCore("SendNotification", {Title="⚠", Text="Stop replay first!", Duration=2})
            else
                local startName = cpInput.Text ~= "" and cpInput.Text or "CP_START"
                StartRecord(startName)
                recBtn.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
                recBtn.Text = "🔴 REC..."
            end
        end)

        stopRecBtn.MouseButton1Click:Connect(function()
            if RecState.IsRecording then
                local endName = endCpInput.Text ~= "" and endCpInput.Text or "CP_END"
                StopRecord(endName)
                recBtn.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
                recBtn.Text = "⏺ REC"
                RefreshManagerList()
            else
                Services.StarterGui:SetCore("SendNotification", {Title="⚠", Text="Not recording!", Duration=2})
            end
        end)

        stopReplayBtn.MouseButton1Click:Connect(function()
            StopReplay()
            Services.StarterGui:SetCore("SendNotification", {Title="⏹", Text="Replay stopped.", Duration=2})
        end)

        pauseReplayBtn.MouseButton1Click:Connect(function()
            if RecState.IsReplaying then
                RecState.IsPaused = not RecState.IsPaused
                pauseReplayBtn.Text = RecState.IsPaused and "▶ Resume" or "⏸ Pause"
                pauseReplayBtn.BackgroundColor3 = RecState.IsPaused and Color3.fromRGB(0, 140, 80) or Color3.fromRGB(60, 60, 160)
            end
        end)

        RecManagerFrame = MF
        return MF
    end

    -- ─── Mini Widget ────────────────────────────
    local function CreateRecWidget()
        if RecWidget then RecWidget:Destroy(); RecWidget = nil end

        local screenGui = UI:GetScreenGui()
        if not screenGui then return end

        local W = Instance.new("Frame", screenGui)
        W.Name             = "RecWidget"
        W.Size             = UDim2.new(0, 180, 0, 62)
        W.Position         = UDim2.new(0.5, -90, 0.85, 0)
        W.BackgroundColor3 = Theme.Sidebar
        W.Visible          = false
        W.ZIndex           = 45
        Instance.new("UICorner", W).CornerRadius = UDim.new(0, 10)
        local wStroke = Instance.new("UIStroke", W)
        wStroke.Color     = Theme.Accent
        wStroke.Thickness = 2

        -- Drag
        local dragHandle = Instance.new("Frame", W)
        dragHandle.Size             = UDim2.new(1, 0, 0, 18)
        dragHandle.BackgroundColor3 = Theme.Accent
        dragHandle.ZIndex           = 46
        Instance.new("UICorner", dragHandle).CornerRadius = UDim.new(0, 8)

        local dragTitle = Instance.new("TextLabel", dragHandle)
        dragTitle.Size               = UDim2.new(1, 0, 1, 0)
        dragTitle.BackgroundTransparency = 1
        dragTitle.Text               = "🎬 REC SYSTEM"
        dragTitle.TextColor3         = Color3.fromRGB(255, 255, 255)
        dragTitle.Font               = Enum.Font.GothamBold
        dragTitle.TextSize           = 10
        dragTitle.ZIndex             = 47

        -- Drag logic
        local dragging, dragStart, startPos
        dragHandle.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true; dragStart = i.Position; startPos = W.Position
                i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then dragging = false end end)
            end
        end)
        UserInputService.InputChanged:Connect(function(i)
            if (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) and dragging then
                local d = i.Position - dragStart
                W.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
            end
        end)

        -- Timer label
        local timerLbl = Instance.new("TextLabel", W)
        timerLbl.Size               = UDim2.new(1, -8, 0, 14)
        timerLbl.Position           = UDim2.new(0, 4, 0, 20)
        timerLbl.BackgroundTransparency = 1
        timerLbl.Text               = "⬛ Idle"
        timerLbl.TextColor3         = Color3.fromRGB(180, 180, 180)
        timerLbl.Font               = Enum.Font.Gotham
        timerLbl.TextSize           = 10
        timerLbl.ZIndex             = 46
        RecTimerLbl = timerLbl

        -- Buttons row
        local function MakeBtn(parent, text, col, xPos, width)
            local b = Instance.new("TextButton", parent)
            b.Size             = UDim2.new(width, 0, 0, 20)
            b.Position         = UDim2.new(xPos, 2, 0, 38)
            b.BackgroundColor3 = col
            b.Text             = text
            b.TextColor3       = Theme.Text
            b.Font             = Enum.Font.GothamBold
            b.TextSize         = 9
            b.ZIndex           = 46
            Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
            return b
        end

        local bRec  = MakeBtn(W, "⏺ REC",  Color3.fromRGB(200,30,30),    0.01,  0.22)
        local bStop = MakeBtn(W, "⏹ STOP", Color3.fromRGB(150,100,0),    0.25,  0.22)
        local bPlay = MakeBtn(W, "▶ PLAY", Color3.fromRGB(0,170,100),    0.49,  0.22)
        local bMgr  = MakeBtn(W, "📋 MGR",  Theme.Button,               0.73,  0.25)

        BtnRecord = bRec; BtnStop = bStop; BtnReplay = bPlay; BtnManager = bMgr

        -- Widget button logic
        bRec.MouseButton1Click:Connect(function()
            if RecState.IsRecording then
                Services.StarterGui:SetCore("SendNotification", {Title="⚠", Text="Already recording!", Duration=2})
            else
                -- prompt start CP name via a quick confirm (reuse UI:Confirm if available, else default)
                StartRecord("CP" .. (#RecState.SavedRecs + 1))
                bRec.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
                bRec.Text = "🔴..."
            end
        end)

        bStop.MouseButton1Click:Connect(function()
            if RecState.IsRecording then
                local endNum = #RecState.SavedRecs + 2
                StopRecord("CP" .. endNum)
                bRec.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
                bRec.Text = "⏺ REC"
                RefreshManagerList()
            elseif RecState.IsReplaying then
                StopReplay()
            else
                Services.StarterGui:SetCore("SendNotification", {Title="⚠", Text="Nothing to stop!", Duration=2})
            end
        end)

        bPlay.MouseButton1Click:Connect(function()
            if #RecState.SavedRecs == 0 then
                Services.StarterGui:SetCore("SendNotification", {Title="⚠", Text="No recordings saved!", Duration=2})
                return
            end
            -- Play latest recording
            local latest = RecState.SavedRecs[#RecState.SavedRecs]
            StartReplay(latest)
            bPlay.Text = "▶..."
        end)

        bMgr.MouseButton1Click:Connect(function()
            if not RecManagerFrame then CreateManagerWindow() end
            RecManagerFrame.Visible = not RecManagerFrame.Visible
            if RecManagerFrame.Visible then RefreshManagerList() end
        end)

        RecWidget = W
        return W
    end

    -- ══════════════════════════════════════════
    --  MENU TAB ELEMENTS
    -- ══════════════════════════════════════════
    RecTab:Toggle("Show Widget", function(state)
        if state then
            if not RecWidget then CreateRecWidget() end
            RecWidget.Visible = true
            StartTimerDisplay()
        else
            if RecWidget then RecWidget.Visible = false end
        end
    end)

    RecTab:Button("Open Recording Manager", Theme.ButtonDark, function()
        if not RecManagerFrame then CreateManagerWindow() end
        RecManagerFrame.Visible = true
        RefreshManagerList()
    end)

    RecTab:Button("⏺ Start Recording", Theme.Button, function()
        local startNum = #RecState.SavedRecs + 1
        StartRecord("CP" .. startNum)
    end)

    RecTab:Button("⏹ Stop Recording", Theme.ButtonRed, function()
        if RecState.IsRecording then
            local endNum = #RecState.SavedRecs + 2
            StopRecord("CP" .. endNum)
            RefreshManagerList()
        end
    end)

    RecTab:Button("▶ Replay Latest", Theme.Confirm, function()
        if #RecState.SavedRecs == 0 then
            Services.StarterGui:SetCore("SendNotification", {Title="⚠", Text="No recordings!", Duration=2})
            return
        end
        StartReplay(RecState.SavedRecs[#RecState.SavedRecs])
    end)

    RecTab:Button("🔁 Stop Replay", Theme.ButtonRed, function()
        StopReplay()
    end)

    RecTab:Slider("Replay Speed", 1, 5, function(v)
        REPLAY_SPEED = v
    end)

    -- ══════════════════════════════════════════
    --  INIT
    -- ══════════════════════════════════════════
    spawn(function()
        task.wait(1.2)
        CreateRecWidget()
        CreateManagerWindow()
        StartTimerDisplay()
        RecState.SavedRecs = LoadSaved()
        print("[Vanzyxxx] Recording System V1 loaded! Saved recs: " .. #RecState.SavedRecs)
    end)

    Config.OnReset:Connect(function()
        RecState.IsRecording = false
        RecState.IsReplaying = false
        if RecState.RecordConn then RecState.RecordConn:Disconnect() end
        if RecState.ReplayConn then RecState.ReplayConn:Disconnect() end
        if TimerConn then TimerConn:Disconnect() end
        DestroyGhost()
        if RecWidget then RecWidget:Destroy(); RecWidget = nil end
        if RecManagerFrame then RecManagerFrame:Destroy(); RecManagerFrame = nil end
    end)

    print("[Vanzyxxx] Recording System V1 initialized")
end
