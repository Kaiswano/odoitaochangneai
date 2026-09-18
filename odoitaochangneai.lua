local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local localPlayerGui = player:WaitForChild("PlayerGui")

local espEnabled = false
local flyEnabled = false
local aimEnabled = false
local hitThroughWallsEnabled = false
local aimTrackSpeed = 0.18

local movement = Vector3.new()
local verticalMovement = 0
local flyVelocity, flyGyro
local espButton, flyButton, aimButton, hitButton

local function getClosestTarget()
    local camera = workspace.CurrentCamera
    local bestTarget, bestDistance = nil, math.huge

    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= player and otherPlayer.Character and otherPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local humanoid = otherPlayer.Character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then
                local root = otherPlayer.Character.HumanoidRootPart
                local screenPos, onScreen = camera:WorldToViewportPoint(root.Position)
                if onScreen then
                    local center = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
                    local pos2d = Vector2.new(screenPos.X, screenPos.Y)
                    local dist = (pos2d - center).Magnitude
                    if dist < bestDistance and dist < 200 then
                        bestDistance = dist
                        bestTarget = root
                    end
                end
            end
        end
    end

    return bestTarget
end

local function createCuteGui()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "CuteFlyEspAimbotGui"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = localPlayerGui

    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 280, 0, 300)
    mainFrame.Position = UDim2.new(0, 20, 0, 80)
    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 0, 80)
    mainFrame.BorderSizePixel = 0
    mainFrame.AnchorPoint = Vector2.new(0, 0)
    mainFrame.Parent = screenGui

    local mainRound = Instance.new("UICorner")
    mainRound.CornerRadius = UDim.new(0, 24)
    mainRound.Parent = mainFrame

    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color = Color3.fromRGB(110, 255, 230)
    mainStroke.Thickness = 2
    mainStroke.Transparency = 0
    mainStroke.Parent = mainFrame

    local mainGradient = Instance.new("UIGradient")
    mainGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 0, 120)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 30, 220))
    }
    mainGradient.Rotation = 90
    mainGradient.Parent = mainFrame

    local titleBar = Instance.new("TextButton")
    titleBar.Size = UDim2.new(1, 0, 0, 36)
    titleBar.Position = UDim2.new(0, 0, 0, 0)
    titleBar.BackgroundTransparency = 1
    titleBar.AutoButtonColor = false
    titleBar.Text = ""
    titleBar.Parent = mainFrame

    local dragging = false
    local dragStart = Vector2.new()
    local frameStartPos = UDim2.new()

    titleBar.InputBegan:Connect(function(input, gameProcessed)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = player:GetMouse().Position
            frameStartPos = mainFrame.Position
        end
    end)

    titleBar.InputEnded:Connect(function(input, gameProcessed)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local mousePos = player:GetMouse().Position
            local delta = mousePos - dragStart
            mainFrame.Position = UDim2.new(frameStartPos.X.Scale, frameStartPos.X.Offset + delta.X, frameStartPos.Y.Scale, frameStartPos.Y.Offset + delta.Y)
        end
    end)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(0.85, 0, 0, 36)
    title.Position = UDim2.new(0, 8, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "ESP + Fly + Aim"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 22
    title.TextColor3 = Color3.fromRGB(175, 255, 245)
    title.TextStrokeTransparency = 0.5
    title.Parent = titleBar

    local contentFrame = Instance.new("Frame")
    contentFrame.Size = UDim2.new(1, 0, 1, -36)
    contentFrame.Position = UDim2.new(0, 0, 0, 36)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Parent = mainFrame

    local minimizeBtn = Instance.new("TextButton")
    minimizeBtn.Name = "MinimizeBtn"
    minimizeBtn.Size = UDim2.new(0, 32, 0, 32)
    minimizeBtn.Position = UDim2.new(0.92, 0, 0, 2)
    minimizeBtn.BackgroundColor3 = Color3.fromRGB(70, 10, 140)
    minimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    minimizeBtn.Font = Enum.Font.GothamBold
    minimizeBtn.TextSize = 18
    minimizeBtn.Text = "−"
    minimizeBtn.AutoButtonColor = false
    minimizeBtn.Parent = titleBar

    local minimizeBtnRound = Instance.new("UICorner")
    minimizeBtnRound.CornerRadius = UDim.new(0, 8)
    minimizeBtnRound.Parent = minimizeBtn

    local minimizeBtnStroke = Instance.new("UIStroke")
    minimizeBtnStroke.Color = Color3.fromRGB(145, 255, 220)
    minimizeBtnStroke.Thickness = 1.5
    minimizeBtnStroke.Parent = minimizeBtn

    local isMinimized = false

    minimizeBtn.MouseButton1Click:Connect(function()
        isMinimized = not isMinimized
        if isMinimized then
            contentFrame.Visible = false
            mainFrame.Size = UDim2.new(0, 280, 0, 36)
            minimizeBtn.Text = "□"
        else
            contentFrame.Visible = true
            mainFrame.Size = UDim2.new(0, 280, 0, 300)
            minimizeBtn.Text = "−"
        end
    end)

    local function makeToggle(text, y)
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0.58, 0, 0, 30)
        label.Position = UDim2.new(0, 12, 0, y)
        label.BackgroundTransparency = 1
        label.Text = text
        label.Font = Enum.Font.Gotham
        label.TextSize = 18
        label.TextColor3 = Color3.fromRGB(190, 240, 255)
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = contentFrame

        local button = Instance.new("TextButton")
        button.Size = UDim2.new(0.32, 0, 0, 30)
        button.Position = UDim2.new(0.62, 0, 0, y)
        button.BackgroundColor3 = Color3.fromRGB(70, 10, 140)
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.Font = Enum.Font.GothamBold
        button.TextSize = 16
        button.Text = "OFF"
        button.AutoButtonColor = false
        button.Parent = contentFrame

        local btnRound = Instance.new("UICorner")
        btnRound.CornerRadius = UDim.new(0, 14)
        btnRound.Parent = button

        local btnStroke = Instance.new("UIStroke")
        btnStroke.Color = Color3.fromRGB(145, 255, 220)
        btnStroke.Thickness = 1.5
        btnStroke.Parent = button

        return button
    end

    espButton = makeToggle("ESP", 14)
    flyButton = makeToggle("Fly", 62)
    aimButton = makeToggle("Aimbot", 110)
    hitButton = makeToggle("Hit Walls", 158)

    local function updateToggle(button, enabled)
        button.Text = enabled and "ON" or "OFF"
        button.BackgroundColor3 = enabled and Color3.fromRGB(0, 220, 200) or Color3.fromRGB(70, 10, 140)
    end

    espButton.MouseButton1Click:Connect(function()
        espEnabled = not espEnabled
        updateToggle(espButton, espEnabled)
    end)

    flyButton.MouseButton1Click:Connect(function()
        flyEnabled = not flyEnabled
        updateToggle(flyButton, flyEnabled)
    end)

    aimButton.MouseButton1Click:Connect(function()
        aimEnabled = not aimEnabled
        updateToggle(aimButton, aimEnabled)
    end)

    hitButton.MouseButton1Click:Connect(function()
        hitThroughWallsEnabled = not hitThroughWallsEnabled
        updateToggle(hitButton, hitThroughWallsEnabled)
    end)

    local speedLabel = Instance.new("TextLabel")
    speedLabel.Size = UDim2.new(0.7, 0, 0, 26)
    speedLabel.Position = UDim2.new(0, 18, 0, 200)
    speedLabel.BackgroundTransparency = 1
    speedLabel.Text = "Track Speed: " .. string.format("%.2f", aimTrackSpeed)
    speedLabel.Font = Enum.Font.Gotham
    speedLabel.TextSize = 16
    speedLabel.TextColor3 = Color3.fromRGB(170, 245, 255)
    speedLabel.TextXAlignment = Enum.TextXAlignment.Left
    speedLabel.Parent = contentFrame

    local decrease = Instance.new("TextButton")
    decrease.Size = UDim2.new(0, 34, 0, 26)
    decrease.Position = UDim2.new(0.72, 0, 0, 200)
    decrease.BackgroundColor3 = Color3.fromRGB(100, 20, 180)
    decrease.Text = "-"
    decrease.Font = Enum.Font.GothamBold
    decrease.TextSize = 20
    decrease.TextColor3 = Color3.fromRGB(255, 255, 255)
    decrease.Parent = contentFrame

    local increase = Instance.new("TextButton")
    increase.Size = UDim2.new(0, 34, 0, 26)
    increase.Position = UDim2.new(0.86, 0, 0, 200)
    increase.BackgroundColor3 = Color3.fromRGB(100, 20, 180)
    increase.Text = "+"
    increase.Font = Enum.Font.GothamBold
    increase.TextSize = 20
    increase.TextColor3 = Color3.fromRGB(255, 255, 255)
    increase.Parent = contentFrame

    local decreaseStroke = Instance.new("UIStroke")
    decreaseStroke.Color = Color3.fromRGB(145, 255, 220)
    decreaseStroke.Thickness = 1.5
    decreaseStroke.Parent = decrease

    local increaseStroke = Instance.new("UIStroke")
    increaseStroke.Color = Color3.fromRGB(145, 255, 220)
    increaseStroke.Thickness = 1.5
    increaseStroke.Parent = increase

    local function updateSpeedLabel()
        speedLabel.Text = "Track Speed: " .. string.format("%.2f", aimTrackSpeed)
    end

    decrease.MouseButton1Click:Connect(function()
        aimTrackSpeed = math.clamp(aimTrackSpeed - 0.02, 0.02, 0.5)
        updateSpeedLabel()
    end)

    increase.MouseButton1Click:Connect(function()
        aimTrackSpeed = math.clamp(aimTrackSpeed + 0.02, 0.02, 0.5)
        updateSpeedLabel()
    end)

    local creditLabel = Instance.new("TextLabel")
    creditLabel.Size = UDim2.new(1, -4, 0, 22)
    creditLabel.Position = UDim2.new(0, 2, 0, 228)
    creditLabel.BackgroundTransparency = 0.1
    creditLabel.BackgroundColor3 = Color3.fromRGB(0, 255, 200)
    creditLabel.Text = "by Phuong Quan"
    creditLabel.Font = Enum.Font.GothamBold
    creditLabel.TextSize = 14
    creditLabel.TextColor3 = Color3.fromRGB(0, 50, 50)
    creditLabel.Parent = contentFrame

    local creditCorner = Instance.new("UICorner")
    creditCorner.CornerRadius = UDim.new(0, 8)
    creditCorner.Parent = creditLabel
end

local function createEspGui(character)
    local root = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not root or not humanoid then return end

    local existing = root:FindFirstChild("CuteESP")
    if existing then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "CuteESP"
    billboard.Adornee = root
    billboard.Size = UDim2.new(0, 140, 0, 48)
    billboard.AlwaysOnTop = true
    billboard.StudsOffset = Vector3.new(0, 2.8, 0)
    billboard.Parent = root

    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 1, 0)
    container.BackgroundTransparency = 0.4
    container.BackgroundColor3 = Color3.fromRGB(55, 8, 82)
    container.BorderSizePixel = 0
    container.Parent = billboard

    local rounded = Instance.new("UICorner")
    rounded.CornerRadius = UDim.new(0, 14)
    rounded.Parent = container

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(1, -8, 0, 20)
    nameLabel.Position = UDim2.new(0, 4, 0, 4)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = character.Name
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 14
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextStrokeTransparency = 0.5
    nameLabel.Parent = container

    local hpBar = Instance.new("Frame")
    hpBar.Name = "HpBar"
    hpBar.Size = UDim2.new(0.92, 0, 0, 10)
    hpBar.Position = UDim2.new(0.04, 0, 0, 28)
    hpBar.BackgroundColor3 = Color3.fromRGB(170, 170, 170)
    hpBar.BorderSizePixel = 0
    hpBar.Parent = container

    local hpFill = Instance.new("Frame")
    hpFill.Name = "HpFill"
    hpFill.Size = UDim2.new(1, 0, 1, 0)
    hpFill.BackgroundColor3 = Color3.fromRGB(255, 102, 102)
    hpFill.BorderSizePixel = 0
    hpFill.Parent = hpBar

    local hpText = Instance.new("TextLabel")
    hpText.Name = "HpText"
    hpText.Size = UDim2.new(1, 0, 0, 18)
    hpText.Position = UDim2.new(0, 0, 0, 18)
    hpText.BackgroundTransparency = 1
    hpText.Text = string.format("%d / %d", humanoid.Health, humanoid.MaxHealth)
    hpText.Font = Enum.Font.Gotham
    hpText.TextSize = 13
    hpText.TextColor3 = Color3.fromRGB(255, 255, 255)
    hpText.TextStrokeTransparency = 0.7
    hpText.Parent = container
end

local function updateEspForPlayer(otherPlayer)
    if not otherPlayer.Character then return end
    local humanoid = otherPlayer.Character:FindFirstChildOfClass("Humanoid")
    local root = otherPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not root then return end

    if espEnabled then
        createEspGui(otherPlayer.Character)
        local billboard = root:FindFirstChild("CuteESP")
        if billboard then
            local hpBar = billboard.Frame:FindFirstChild("HpBar")
            local hpFill = hpBar and hpBar:FindFirstChild("HpFill")
            local hpText = billboard.Frame:FindFirstChild("HpText")
            if hpFill then
                local ratio = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
                hpFill.Size = UDim2.new(ratio, 0, 1, 0)
                hpFill.BackgroundColor3 = Color3.fromRGB(255 - ratio * 120, ratio * 180 + 75, 90)
            end
            if hpText then
                hpText.Text = string.format("%d / %d", math.max(0, math.floor(humanoid.Health)), math.max(1, math.floor(humanoid.MaxHealth)))
            end
        end
    else
        if root:FindFirstChild("CuteESP") then
            root.CuteESP:Destroy()
        end
    end
end

local function removeEspForPlayer(otherPlayer)
    if otherPlayer.Character then
        local root = otherPlayer.Character:FindFirstChild("HumanoidRootPart")
        if root and root:FindFirstChild("CuteESP") then
            root.CuteESP:Destroy()
        end
    end
end

local function updateAimbot()
    if not aimEnabled then
        return
    end
    local camera = workspace.CurrentCamera
    local targetRoot = getClosestTarget()
    if not targetRoot then
        return
    end

    local targetPos = targetRoot.Position
    local currentPos = camera.CFrame.Position
    local desired = CFrame.new(currentPos, targetPos)
    camera.CFrame = camera.CFrame:Lerp(desired, aimTrackSpeed)
end

local function updateHitThroughWalls()
    if not hitThroughWallsEnabled then return end
    local character = player.Character
    if not character then return end
    
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end
end

local function enableFly()
    local character = player.Character
    if not character then return end
    local root = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not root or not humanoid then return end

    humanoid.PlatformStand = true

    flyVelocity = Instance.new("BodyVelocity")
    flyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    flyVelocity.Velocity = Vector3.new(0, 0, 0)
    flyVelocity.Parent = root

    flyGyro = Instance.new("BodyGyro")
    flyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    flyGyro.P = 5000
    flyGyro.CFrame = root.CFrame
    flyGyro.Parent = root
end

local function disableFly()
    if flyVelocity then
        flyVelocity:Destroy()
        flyVelocity = nil
    end
    if flyGyro then
        flyGyro:Destroy()
        flyGyro = nil
    end
    local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.PlatformStand = false
    end
end

local function updateFly()
    if not flyEnabled or not flyVelocity or not flyGyro then
        return
    end

    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not root then
        return
    end

    local camera = workspace.CurrentCamera
    local direction = Vector3.new(movement.X, 0, movement.Y)
    local forward = camera.CFrame.LookVector
    local right = camera.CFrame.RightVector

    local horizontalMove = Vector3.new(0, 0, 0)
    if direction.Magnitude > 0 then
        horizontalMove = (forward * direction.Z + right * direction.X).Unit * 80
    end
    
    flyVelocity.Velocity = Vector3.new(horizontalMove.X, verticalMovement * 80, horizontalMove.Z)

    flyGyro.CFrame = CFrame.new(root.Position, root.Position + camera.CFrame.LookVector)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.W then
        movement = Vector3.new(movement.X, 1, 0)
    elseif input.KeyCode == Enum.KeyCode.S then
        movement = Vector3.new(movement.X, -1, 0)
    elseif input.KeyCode == Enum.KeyCode.A then
        movement = Vector3.new(-1, movement.Y, 0)
    elseif input.KeyCode == Enum.KeyCode.D then
        movement = Vector3.new(1, movement.Y, 0)
    elseif input.KeyCode == Enum.KeyCode.Space then
        verticalMovement = 1
    elseif input.KeyCode == Enum.KeyCode.LeftControl then
        verticalMovement = -1
    elseif input.KeyCode == Enum.KeyCode.E then
        flyEnabled = not flyEnabled
        if flyButton then
            flyButton.Text = flyEnabled and "ON" or "OFF"
            flyButton.BackgroundColor3 = flyEnabled and Color3.fromRGB(0, 220, 200) or Color3.fromRGB(70, 10, 140)
        end
    elseif input.KeyCode == Enum.KeyCode.Q then
        aimEnabled = not aimEnabled
        if aimButton then
            aimButton.Text = aimEnabled and "ON" or "OFF"
            aimButton.BackgroundColor3 = aimEnabled and Color3.fromRGB(0, 220, 200) or Color3.fromRGB(70, 10, 140)
        end
    elseif input.KeyCode == Enum.KeyCode.Z then
        hitThroughWallsEnabled = not hitThroughWallsEnabled
        if hitButton then
            hitButton.Text = hitThroughWallsEnabled and "ON" or "OFF"
            hitButton.BackgroundColor3 = hitThroughWallsEnabled and Color3.fromRGB(0, 220, 200) or Color3.fromRGB(70, 10, 140)
        end
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.W or input.KeyCode == Enum.KeyCode.S then
        movement = Vector3.new(movement.X, 0, 0)
    elseif input.KeyCode == Enum.KeyCode.A or input.KeyCode == Enum.KeyCode.D then
        movement = Vector3.new(0, movement.Y, 0)
    elseif input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.LeftControl then
        verticalMovement = 0
    end
end)

Players.PlayerAdded:Connect(function(otherPlayer)
    otherPlayer.CharacterAdded:Connect(function()
        if espEnabled then
            task.wait(0.5)
            updateEspForPlayer(otherPlayer)
        end
    end)
end)

Players.PlayerRemoving:Connect(removeEspForPlayer)

player.CharacterAdded:Connect(function()
    task.wait(0.5)
    if flyEnabled then
        enableFly()
    end
    if hitThroughWallsEnabled then
        updateHitThroughWalls()
    end
    if espEnabled then
        for _, otherPlayer in ipairs(Players:GetPlayers()) do
            if otherPlayer ~= player then
                updateEspForPlayer(otherPlayer)
            end
        end
    end
end)

RunService.RenderStepped:Connect(function()
    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= player then
            updateEspForPlayer(otherPlayer)
        end
    end

    if flyEnabled then
        if not flyVelocity or not flyGyro then
            enableFly()
        end
        updateFly()
    else
        if flyVelocity or flyGyro then
            disableFly()
        end
    end

    if aimEnabled then
        updateAimbot()
    end

    if hitThroughWallsEnabled then
        updateHitThroughWalls()
    end
end)

createCuteGui()
