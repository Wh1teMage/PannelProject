--local PannelUI = require('./pannelUIv2')
--local Config   = require('./pannelconfig')

local PannelUI   = loadstring(game:HttpGet("https://raw.githubusercontent.com/Wh1teMage/PannelProject/refs/heads/main/pannelUIv2.luau"))()
local Config     = loadstring(game:HttpGet("https://raw.githubusercontent.com/Wh1teMage/PannelProject/refs/heads/main/pannelconfig.luau"))()

local Players    = game:GetService("Players")
local Replicated = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local UserInput  = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
--local TPService  = game:GetService("TeleportService")
--local VUser      = game:GetService("VirtualUser")
--local Lighting   = game:GetService("Lighting")
--local TweenServ  = game:GetService("TweenService")
--local Debris     = game:GetService("Debris")
local CoreGui    = game:GetService('CoreGui')

local Pannel = PannelUI.new()

local DoClientMagic = Replicated['Remotes']['DoClientMagic'] :: RemoteEvent
local DoMagic       = Replicated['Remotes']['DoMagic'] :: RemoteFunction
local Combat        = Replicated['Remotes']['Combat'] :: RemoteEvent
--local KeyReserve    = Replicated['Remotes']['KeyReserve']
--local PlayerData    = Replicated['Remotes']['PlayerData'] :: RemoteEvent
local ClientData    = Replicated['Remotes']['ClientData'] :: RemoteEvent

repeat task.wait() until game:IsLoaded()

local PlayerMethods = {}

function PlayerMethods:Destroy()
    local name = self.Name

    for _, connection: RBXScriptConnection in pairs(self.Connections) do
        connection:Disconnect()
    end

    for _, team in pairs(Config.ClassPlayers) do

        for playerName, player in pairs(team) do
            if (playerName == name) then team[playerName] = nil; break; end
        end

    end

    table.clear(self)

    Config.AllPlayers[name] = nil
end

function PlayerMethods:AddConnection(connection: RBXScriptConnection)
    table.insert(self.Connections, connection)
end

function PlayerMethods:AddSpawnCallback(callback: () -> ())
    callback()
    table.insert(self.SpawnCallbacks, callback)
end

local PlayerFabric = {}

function PlayerFabric:GetPlayer(name: string)
    return Config.AllPlayers[name]
end

function PlayerFabric:GetPlayers()
    return Config.AllPlayers
end

function PlayerFabric.new(playerObj: Player)

    if (PlayerFabric:GetPlayer(playerObj.Name)) then return PlayerFabric:GetPlayer(playerObj.Name) end
    if not playerObj then return end

    local self = setmetatable({}, {__index = PlayerMethods})

    local name = playerObj.Name

    self.Name        = name
    self.Instance    = playerObj
    self.Character   = playerObj.Character or playerObj.CharacterAdded:Wait()
    self.PrimaryPart = self.Character:WaitForChild('HumanoidRootPart', 5)
    self.Humanoid    = self.Character:WaitForChild('Humanoid', 5)

    self.CFrame      = CFrame.new(0,0,0)
    self.ExtraCFrame = CFrame.new(0,0,0)
    self.Velocity    = Vector3.new(0,0,0)
    self.LastTick    = os.clock()

    self.Velocities    = {}
    self.MaxVelocities = 5
    self.VelocitySum   = Vector3.new(0,0,0)

    self.VelocitiesSlow    = {}
    self.MaxVelocitiesSlow = 60
    self.VelocitySumSlow   = Vector3.new(0,0,0)

    self.Accelerations   = {}
    self.AccelerationSum = Vector3.new(0,0,0)
    self.Acceleration    = Vector3.new(0,0,0)

    self.Positions    = {}
    self.MaxPositions = 5
    self.PositionsSum = Vector3.new(0,0,0)

    self.VelocityDerivative = Vector3.new(0,0,0)

    self.Connections    = {}
    self.SpawnCallbacks = {}

    self.MaxMana = 1000
    self.Mana    = 1000

    self.MaxStamina = 1000
    self.Stamina    = 1000

    self.Running  = false
    self.Blocking = false
    self.Safezone = false
    self.Stunned  = false

    self.Loadout = {}
    self.Stats   = {}

    self.CameraPosition = Vector3.new()
    self.MousePosition  = Vector3.new()

    self:AddConnection(
        playerObj.CharacterAdded:Connect(function()
            if (not PlayerFabric:GetPlayer(name)) then return end
            self.Character = playerObj.Character or playerObj.CharacterAdded:Wait()
    
            self.PrimaryPart = self.Character:WaitForChild('HumanoidRootPart', 5)
            self.Humanoid    = self.Character:WaitForChild('Humanoid', 5)

            for _, callback in pairs(self.SpawnCallbacks) do
                callback()
            end

        end)
    )

    Config.AllPlayers[name] = self

	return self
end

local EnemyMethods = setmetatable({}, {__index = PlayerMethods})

function EnemyMethods:Distance() 
    return (self.CFrame.Position - self.LocalPlayer.CFrame.Position).Magnitude 
end

function EnemyMethods:MouseDistance() 
    local position, inViewport = self.LocalPlayer.Camera:WorldToViewportPoint(self.CFrame.Position)
    if inViewport == false then return 9e9 end
    return (Vector2.new(self.LocalPlayer.Mouse.X, self.LocalPlayer.Mouse.Y + 35) - Vector2.new(position.X, position.Y)).Magnitude
end

local EnemyFabric = {}

function EnemyFabric:GetFirstEnemy()
    for _, enemy in pairs(Config.ClassPlayers['Enemies']) do return enemy end
    return
end

function EnemyFabric:GetClosest()
    local closest = EnemyFabric:GetFirstEnemy()

    for _, enemy in pairs(Config.ClassPlayers['Enemies']) do
        if enemy:Distance() > closest:Distance() or Config.ClassPlayers['Allies'][enemy.Name] or enemy.Safezone or enemy.Humanoid.Health <= 0 then continue end

        closest = enemy
    end

    return closest
end

function EnemyFabric:GetClosestToMouse()
    local closest = EnemyFabric:GetFirstEnemy()

    for _, enemy in pairs(Config.ClassPlayers['Enemies']) do
        if enemy:MouseDistance() > closest:MouseDistance() or enemy.Safezone or enemy.Humanoid.Health <= 0 then continue end

        closest = enemy
    end

    return closest
end


function EnemyFabric.new(playerObj, localComponent, spellsClass)
    
    if playerObj == localComponent.Instance then return end

    local self = setmetatable(PlayerFabric.new(playerObj), {__index = EnemyMethods})

    self.Type = 'Enemies'
    self.PredictedPosition = Vector3.new(0,0,0)
    self.LocalPlayer = localComponent

    Config.ClassPlayers['Enemies'][self.Name] = self

    return self

end

local AllyMethods = setmetatable({}, {__index = PlayerMethods})

function AllyMethods:Distance() 
    return (self.CFrame.Position - self.LocalPlayer.CFrame.Position).Magnitude 
end

local AllyFabric = {}

function AllyFabric:GetFirstEnemy()
    for _, ally in pairs(Config.ClassPlayers['Allies']) do return ally end
    return
end


function AllyFabric:GetClosest()
    local closest = AllyFabric:GetFirstEnemy()

    for _, ally in pairs(Config.ClassPlayers['Allies']) do
        if ally:Distance() > closest:Distance() then continue end

        closest = ally
    end

    return closest
end

function AllyFabric:GetLowestOnHealth()
    local lowest = AllyFabric:GetFirstEnemy()

    for _, ally in pairs(Config.ClassPlayers['Allies']) do
        if ally.Humanoid.Health/ally.Humanoid.MaxHealth > lowest.Humanoid.Health/lowest.Humanoid.MaxHealth or ally.Humanoid.Health <= 0 then continue end

        lowest = ally
    end

    return lowest
end

function AllyFabric.new(playerObj, localComponent)

    local self = setmetatable(PlayerFabric.new(playerObj), {__index = AllyMethods})

    self.Type = 'Allies'
    self.LocalPlayer = localComponent

    Config.ClassPlayers['Enemies'][self.Name] = nil
    Config.ClassPlayers['Allies'][self.Name] = self

    return self

end

local LocalMethods = setmetatable({}, {__index = AllyMethods})

function LocalMethods:ChangeAmplifiers(key, event, num)
    if not self['Controls'][key] or event then return end
    self['Controls'][key] = num
end

function LocalMethods:BecomeInvisible()
    self.PreviousCF = self.CFrame
    self.PrimaryPart.CFrame = CFrame.new(math.random(10000000, 50000000), math.random(10000000, 50000000), math.random(10000000, 50000000))

    task.wait(.2)
    local humcl = self.PrimaryPart:Clone()
    humcl.Parent = self.PrimaryPart.Parent

    self.PrimaryPart.Name = "humrpclone"
    humcl.Name = "HumanoidRootPart"
    task.wait(.2)

    humcl.CFrame = self.PreviousCF
    task.wait(.2)
end


function LocalMethods:FlyFunction(value)
    self.Fly = value
    if value == false then return end

    task.spawn(function()
        
        local keys = self['Controls']

        local bv
        local bg

        while self.Fly == true do
            task.wait()
        
            if self.Invisibility == true then self.Character:WaitForChild('humrpclone', 10) end

            self.Humanoid.PlatformStand = true

            bv = self.PrimaryPart:FindFirstChild('bv')
            bg = self.PrimaryPart:FindFirstChild('bg')

            if bv == nil then self['bodyVelocity']:Clone().Parent = self.PrimaryPart; continue end
            if bg == nil then self['bodyGyro']:Clone().Parent = self.PrimaryPart; continue end 

            bg.CFrame = self.Camera.CFrame
            bv.Velocity = 
                self.Camera.CFrame.lookVector * self.FlySpeed * (keys[Enum.KeyCode.W] - keys[Enum.KeyCode.S]) + 
                self.Camera.CFrame.rightVector * self.FlySpeed * (keys[Enum.KeyCode.D] - keys[Enum.KeyCode.A])

            local speedMulti = math.abs(keys[Enum.KeyCode.W] - keys[Enum.KeyCode.S]) + math.abs(keys[Enum.KeyCode.D] - keys[Enum.KeyCode.A])
            if speedMulti == 0 then speedMulti = -1 end
            
            self.FlySpeed += self.MaxFlySpeed/30 * speedMulti
            self.FlySpeed = math.clamp(self.FlySpeed, 0 , self.MaxFlySpeed)
        end

        bv:Destroy()
        bg:Destroy()

        self.Humanoid.PlatformStand = false
        self.Fly = false

    end)

end

function LocalMethods:NoclipFunction(value)
    self.Noclip = value
    if value == false then return end

    local connection;
    connection = RunService.Stepped:Connect(function()
        if self.Noclip == false then connection:Disconnect() end

        for _, child in ipairs(self.Character:GetChildren()) do
            if not (child.Name == 'Head' or child.Name == 'Torso') then continue end
            child.CanCollide = false
        end

    end)
end

function LocalMethods:InfJumpFunction(value)
    self.InfJump = value
    if value == false then return end

    local connection;
    connection = UserInput.InputBegan:Connect(function(input, event)

        if self.InfJump == false then connection:Disconnect(); return end
        if event or input.KeyCode ~= Enum.KeyCode.Space then return end

        self.Humanoid:ChangeState(Enum.HumanoidStateType.Seated)
        task.wait(.1)
        self.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)

    end)
end

function LocalMethods:ChangeTarget(name)
    for playerName, player in pairs(PlayerFabric:GetPlayers()) do
        if (string.find(playerName, name)) then self.SelectedTarget = player; break end
    end
end

function LocalMethods:FollowFunction(value)
    self.Follow = value
    if value == false then return end

    while self.Follow == true do
        self.Character.HumanoidRootPart.CFrame = self.SelectedTarget.CFrame
        self.Character.HumanoidRootPart.Velocity = Vector3.new(0,0,0)
        task.wait()
    end
end

function LocalMethods:SpectateFunction(value)
    self.Spectate = value
    if value == false then return end

    task.spawn(function()
        while self.Spectate == true do
            self.Camera.CameraSubject = self.SelectedTarget.Humanoid
            task.wait(.1)
        end

        self.Camera.CameraSubject = self.Humanoid
    end)
end


function LocalMethods:TeleportFunction()
    self.Character.HumanoidRootPart.CFrame = self.SelectedTarget.PrimaryPart.CFrame
    self.Character.HumanoidRootPart.Velocity = Vector3.new(0,0,0)
end

function LocalMethods:ClickTPFunction()
    self.Character.HumanoidRootPart.CFrame = CFrame.new(self.Mouse.Hit.Position + Vector3.new(0, 5, 0))
end

function LocalMethods:SpawnpointFunction(value)
    if value == false then self.Spawnpoint = CFrame.new(0,0,0); return end
    self.Spawnpoint = CFrame.new(0,1,0)
end

function LocalMethods:InvisibleFunction(value)
    self.Invisibility = value

    if value == false then

        local humrp = self.Character['HumanoidRootPart']
        self.Character["humrpclone"].CFrame = humrp.CFrame
        self.Character["humrpclone"].Name = "HumanoidRootPart"

        humrp:Destroy()

        return 
    end


    self:BecomeInvisible()
end

local LocalFabric = {}

function LocalFabric.new(playerObj)

    local component = {}
    local self = setmetatable(PlayerFabric.new(playerObj), {__index = LocalMethods})

    self.Camera    = workspace.CurrentCamera
    self.PlayerGui = playerObj.PlayerGui
    self.Mouse     = playerObj:GetMouse()

    self.SelectedTarget = self

    self['Ping'] = 100

    self['WalkSpeed']   = 32
    self['JumpPower']   = 50
    self['MaxFlySpeed'] = 100
    self['FlySpeed']    = 0
    self['MinMana']     = 100
    self['Spawnpoint']  = CFrame.new(0,0,0)
    self['PreviousCF']  = CFrame.new(0,0,0)

    self['Fly']      = false
    self['InfJump']  = false
    self['Noclip']   = false
    self['Spectate'] = false
    self['Follow']   = false

    self['SprintSwitch'] = false
    self['InfStamina']   = false
    self['Invisibility'] = false
    self['AntiBlind']    = false
    self['AntiStun']     = false
    self['Tracers']      = false
    self['ResetOnMana']  = false
    self['Aimbot']       = false
    self['NoBulletsCD']  = false

    self['HasFinishedRespawning'] = true

    self['Controls'] = 
    {
        [Enum.KeyCode.W] = 0,
        [Enum.KeyCode.S] = 0,
        [Enum.KeyCode.A] = 0,
        [Enum.KeyCode.D] = 0,
    }

    self['Binds'] = 
    {
        ['UseSpell'] = Enum.KeyCode.E,
        ['SkipCD']   = Enum.KeyCode.F,
        ['ClickTP']  = Enum.KeyCode.T,
    }

    self['bodyVelocity'] = Instance.new("BodyVelocity")
    self['bodyGyro']     = Instance.new("BodyGyro")

    self['bodyVelocity'].MaxForce = Vector3.new(9e9, 9e9, 9e9)
    self['bodyGyro'].MaxTorque    = Vector3.new(9e9, 9e9, 9e9)
    self['bodyVelocity'].Name     = 'bv'
    self['bodyGyro'].Name         = 'bg'

    self['bodyVelocity'].Parent = self.Instance
    self['bodyGyro'].Parent     = self.Instance

    self:AddSpawnCallback(function()
        local connection;
        connection = self.Humanoid:GetPropertyChangedSignal'WalkSpeed':Connect(function()
            
            if self.WalkSpeed >= 64 then
                self.Humanoid.WalkSpeed = self.WalkSpeed
            end

        end)

        self.Humanoid.Died:Connect(function() connection:Disconnect() end)
    end)

    self:AddSpawnCallback(function()
        local connection;
        connection = self.Character.DescendantAdded:Connect(function(child)
            if (not self.AntiStun) then return end
            if (child.Name == 'bv') or (child.Name == 'bp') then return end
            if ((child:IsA('BodyPosition')) or (child:IsA('BodyVelocity') and child.Parent.Name ~= 'FlipsHolder')) then task.wait(.05); child:Destroy() end
        end)

        self.Humanoid.Died:Connect(function() connection:Disconnect() end)
    end)

    self:AddSpawnCallback(function()
        local connection;
        connection = self.Humanoid.Died:Connect(function()
            if self.Spawnpoint ~= CFrame.new(0,0,0) then self.Spawnpoint = self.CFrame end
            connection:Disconnect()
        end)
    end)

    self:AddSpawnCallback(function()
        
        self.Humanoid.WalkSpeed = self.WalkSpeed
        self.Humanoid.JumpPower = self.JumpPower

        if self.Invisibility == true then self:BecomeInvisible() end
        if self.Spawnpoint ~= CFrame.new(0,0,0) then self.Character.HumanoidRootPart.CFrame = self.Spawnpoint end

        while self.Safezone do task.wait() end

        self.HasFinishedRespawning = true

        local connection;
        connection = self.Humanoid.Died:Connect(function()
            self.HasFinishedRespawning = false
            connection:Disconnect()
        end)

    end)

    UserInput.InputBegan:Connect(function(input, event) self:ChangeAmplifiers(input.KeyCode, event, 1) end)
    UserInput.InputEnded:Connect(function(input, event) self:ChangeAmplifiers(input.KeyCode, event, 0) end)

    UserInput.InputBegan:Connect(function(input, event)
        if (event) then return end

        if (input.KeyCode == self['Binds']['ClickTP']) then
            self:ClickTPFunction()
        end
    end)

    return self :: typeof(self) & typeof(LocalMethods) & typeof(component)
end

local GUIMethods = {}

function GUIMethods:TracePerson(Person)

    local billboardGui = Instance.new("BillboardGui")
    local textbox1     = Instance.new("TextBox")

    billboardGui.Size = UDim2.new(0, 200, 0, 40)
    billboardGui.Name = "billboardGui"
    billboardGui.MaxDistance = 5000
    billboardGui.StudsOffset = Vector3.new(0, 12, 0)
    billboardGui.AlwaysOnTop = true
    billboardGui.Enabled     = false

    textbox1.BackgroundTransparency = 1
    textbox1.TextColor3 = Color3.fromRGB(0, 0, 0)
    textbox1.Name = "textbox1"
    textbox1.Size = UDim2.new(1, 0, 0.5, 0)
    textbox1.TextSize = 7
    textbox1.Text = Person.Instance.Name..' [Health : 1000]'
    textbox1.TextScaled = false

    local textbox2 = textbox1:Clone()

    textbox2.Position = UDim2.new(0, 0, 0.3, 0)
    textbox2.Name     = "textbox2"

    textbox2.Parent = billboardGui
    textbox1.Parent     = billboardGui
    billboardGui.Parent = Person.Instance

    local connection

    connection = RunService.RenderStepped:Connect(function()
        
        if Person.PrimaryPart == nil then return end

        local billgui = Person.PrimaryPart:FindFirstChild('billboardGui')
        if billgui == nil then Person.Instance.billboardGui:Clone().Parent = Person.PrimaryPart; return end

        if Players:FindFirstChild(Person.Instance.Name) == nil then connection:Disconnect(); return end
        if self.LocalComponent.Tracers == false then billgui.Enabled = false; return end

        billgui.Enabled = true
        Person.PrimaryPart.Transparency = .5
        Person.PrimaryPart.Size = Vector3.new(3, 5, 2)
        
        billgui.textbox1.TextColor3 = Color3.fromRGB(0, 0, 0)

        local name  = Person.Instance.Name
        if Config.ClassPlayers['Allies'][Person.Instance.Name] ~= nil then billgui.textbox1.TextColor3 = Color3.fromHSV(0.53, 1.0, 1) end

        local color = 1-(Person.Humanoid.Health/Person.Humanoid.MaxHealth)

        billgui.textbox1.Text = name..' [Health : '..tostring(Person.Humanoid.Health*10-(Person.Humanoid.Health*10)%1)..']'

        local stamina = Person.Stamina
        local mana    = Person.Mana

        billgui.textbox2.Text  = '[Mana : '..tostring(mana*10-(mana*10)%1)..']'..' [Stamina : '..tostring(stamina*10-(stamina*10)%1)..']'
        billgui.textbox2.TextColor3 = Color3.fromHSV(0.53, 1, color)

    end)

end

function GUIMethods:GetSelectedMove()
    local available    = self.Inventory:GetChildren()
    local selectedSlot = self.SelectSlot

    local selectedObj  = available[2]

    for _, obj in ipairs(available) do

        if not obj:IsA('ImageButton') then continue end

        local distance = (selectedSlot.AbsolutePosition - Vector2.new(42, 42) - obj.AbsolutePosition).Magnitude
        if distance < (selectedSlot.AbsolutePosition - Vector2.new(42, 42) - selectedObj.AbsolutePosition).Magnitude then selectedObj = obj end
    end

    return selectedObj
end


function GUIMethods:GetPartyMembers()
    local members = {}

    if self.Members:GetChildren() == nil then return members end

    for _, name in ipairs(self.Members:GetChildren()) do
        if name.Text == self.LocalComponent.Instance.Name or Players:FindFirstChild(name.Text) == nil then continue end
        members[name.Text] = Players[name.Text]
    end

    return members
end

local GUIFabric = {}

function GUIFabric.new(localPlayer)
    
    local self = setmetatable({}, {__index = GUIMethods})

    self.SelectSlot = localPlayer.PlayerGui.Main.SelectSlot
    self.Inventory  = localPlayer.PlayerGui.Main.Character.Available.ScrollingFrame.Frame
    self.Members    = localPlayer.PlayerGui.Main.MembersFrame.Frame
    self.ManaLabel  = localPlayer.PlayerGui.Main.SkillsBar.Energy.TextLabel

    self.LocalComponent = localPlayer

    self.Chat     = localPlayer.PlayerGui:WaitForChild('Chat')
    self.Scroller = self.Chat.DestroyGuardFrame.Frame.ChatChannelParentFrame["Frame_MessageLogDisplay"].Scroller

    self.IsLoaded   = false

    localPlayer.PlayerGui.ChildAdded:Connect(function(child)
        if (child:IsAncestorOf(Pannel.ScreenGui)) then return end
        if (not localPlayer.AntiBlind) then return end
        if (not (child.Name == "ScreenGui" or child.Name == "ef" or child.Name == "efult")) then return end

        child.Enabled = false
        localPlayer.PlayerGui.Chat.Enabled = true
    end)

    local perfomanceStats = CoreGui.RobloxGui.PerformanceStats :: Frame

    for _, object in pairs(perfomanceStats:GetChildren()) do
        if (not object:IsA('TextButton')) then continue end
        local textStats = object.StatsMiniTextPanelClass

        if (textStats.TitleLabel.Text ~= 'Ping') then continue end
        local rawping = textStats.ValueLabel.Text
        localPlayer.Ping = tonumber(string.sub(rawping, 1, #rawping - 3))
    end


    return self

end

local SpellFabric = {}
local SpellMethods = {}

function SpellMethods:AutoPunchFunction(value)
    self.AutoPunch = value
    if value == false then return end

    task.spawn(function()
        while self.AutoPunch == true do
            Combat:FireServer(self.SpellsTarget.Character)
            task.wait(.1)
        end
    end)

end

function SpellMethods:GetSpellsTargetByType()

    self.SpellsTarget = self.LocalComponent.SelectedTarget

    if self.SelectedType == Config.Enums.Target.Closest then
        self.SpellsTarget = EnemyFabric:GetClosest()

    elseif self.SelectedType == Config.Enums.Target.Mouse then
        self.SpellsTarget = EnemyFabric:GetClosestToMouse()

    elseif self.SelectedType == Config.Enums.Target.Ally then
        self.SpellsTarget = AllyFabric:GetLowestOnHealth()
    end

    if (not self.SpellsTarget) then self.SpellsTarget = self.LocalComponent end
    --self.LocalComponent.SelectedTarget = self.SpellsTarget
end

function SpellMethods:TPCharacterBySpellType(oldCFrame)

    if oldCFrame ~= nil and self.SpellsType == Config.Enums.TPType.Swap then
        self.LocalComponent.PrimaryPart.CFrame = oldCFrame
        return
    end

    if self.SpellsType == Config.Enums.TPType.Void then 
        self.LocalComponent.PrimaryPart.CFrame = CFrame.new(10000, -1000, 100000)
    elseif self.SpellsType == Config.Enums.TPType.Float then
        self.LocalComponent.PrimaryPart.CFrame = CFrame.new(10000, 10000000, 100000)
    end
end

function SpellMethods:GetElement(spellColor)
    local newSpellColor = Color3.new(math.round(spellColor.R*100)/100, math.round(spellColor.G*100)/100, math.round(spellColor.B*100)/100)

    for element, color in pairs(Config.GeneralInfo.ElementsTypes) do
        local newColor = Color3.new(math.round(color.R*100)/100, math.round(color.G*100)/100, math.round(color.B*100)/100)
        if newColor == newSpellColor then return element end
    end

    return
end

function SpellMethods:GetSpellNameByImageAndColor(image, color)
    local frame = self.LocalComponent.Instance.PlayerGui.Main.Character.Available.ScrollingFrame.Frame

    for _, obj: ImageButton in pairs(frame:GetChildren()) do
        if (not obj:IsA('ImageButton')) then continue end
        if ((obj.Image == image) and (obj.BackgroundColor3 == color)) then return obj.Name end
    end

    return
end

function SpellMethods:GetEquippedSpell()
    local selectedSpell;

    for _, object in pairs(self.LocalComponent.Instance.PlayerGui.Main.SkillsBar:GetChildren()) do
        if (not object:IsA('ImageButton')) then continue end
        if (object.BorderSizePixel > 0) then selectedSpell = object; break end
    end

    return selectedSpell
end

function SpellMethods:SkipUltCD()
    for i = 1, 2 do
        DoClientMagic:FireServer('Lava', 'Magma Drop')
        DoMagic:InvokeServer('Lava', 'Magma Drop')
        task.wait(.1)
    end
end

type spellCallback = (elementName: string, abilityName: string, self: any) -> ()

function SpellMethods:AddSpell(elementName: string, abilityName: string, eventCallback: (spellCallback)?, invokeCallback: (spellCallback)?)
    if (not eventCallback) then
        eventCallback = function(elementName, abilityName)
            print('event', elementName, abilityName)
            DoClientMagic:FireServer(elementName, abilityName)
        end
    end

    if (not invokeCallback) then
        invokeCallback = function(elementName, abilityName)
            print('function', elementName, abilityName)
            DoMagic:InvokeServer(elementName, abilityName)
        end
    end

    
    if (not Config.SpellsLibrary[elementName]) then Config.SpellsLibrary[elementName] = {} end

    Config.SpellsLibrary[elementName][abilityName] = {
        ['Event'] = eventCallback,
        ['Function'] = invokeCallback
    }
end

function SpellMethods:CloneSpell(elementName: string, abilityName: string, originElementName: string, originAbilityName: string)

    if (not Config.SpellsLibrary[originElementName]) then return end
    if (not Config.SpellsLibrary[originElementName][originAbilityName]) then return end

    if (not Config.SpellsLibrary[elementName]) then Config.SpellsLibrary[elementName] = {} end

    Config.SpellsLibrary[elementName][abilityName] = {
        ['Event'] = Config.SpellsLibrary[originElementName][originAbilityName]['Event'],
        ['Function'] = Config.SpellsLibrary[originElementName][originAbilityName]['Function']
    }
end

function SpellMethods:UseSpell(elementName: string, abilityName: string)
    if (not Config.SpellsLibrary[elementName]) then return end

    local ability = Config.SpellsLibrary[elementName][abilityName]
    if (not ability) then return end

    ClientData:FireServer({['Cooldowns'] = "{}", ['Mouse'] = self.PredictedPosition, ['Holding'] = true, ['Camera'] = self.LocalComponent.PrimaryPart.Position})
    ability['Event'](elementName, abilityName, self)
    task.wait(1/60*3)
    ClientData:FireServer({['Cooldowns'] = "{}", ['Mouse'] = self.PredictedPosition, ['Holding'] = true, ['Camera'] = self.LocalComponent.PrimaryPart.Position})
    ability['Function'](elementName, abilityName, self)
end

function SpellMethods:IsSpellInLibrary(abilityName: string)
    local found = false

    for name, element in pairs(Config.SpellsLibrary) do
        if (element[abilityName]) then found = true; break end
    end

    return found
end

function SpellMethods:ModifySpell(abilityName: string)
    if (not self:IsSpellInLibrary(abilityName)) then return end
    Config.Spells.Modified[abilityName] = true

    Pannel:CreateNotification('Modified Successfully!', abilityName..' was correctly modified', 5)
end

function SpellMethods:RevertSpell(abilityName: string)
    if (not self:IsSpellInLibrary(abilityName)) then return end
    Config.Spells.Modified[abilityName] = false

    Pannel:CreateNotification('Revertedd Successfully!', abilityName..' was correctly reverted', 5)
end

function SpellMethods:DisableSpellAimbot(abilityName: string)
    if (not table.find(Config.ExistingSpells, abilityName)) then return end
    Config.Spells['Disabled'][abilityName] = true
end

function SpellMethods:ChainSpell(abilityName: string)
    if (not table.find(Config.ExistingSpells, abilityName)) then return end
    Config.Spells['Chained'][abilityName] = true
end

function SpellMethods:EnableSpellAimbot(abilityName: string)
    Config.Spells['Disabled'][abilityName] = nil
end

function SpellMethods:UnchainSpell(abilityName: string)
    Config.Spells['Chained'][abilityName] = nil
end

function SpellMethods:ClearChain()
    table.clear(Config.Spells['Chained'])
end

function SpellMethods:ClearSpellAimbot()
    table.clear(Config.Spells['Disabled'])
end

function SpellMethods:GetAvaliableSpells()
    local spells = {}

    for _, element in pairs(Config.SpellsLibrary) do
        for name, _ in pairs(element) do
            table.insert(spells, name)
        end
    end

    return spells
end

local folder = Instance.new('Folder')
folder.Parent = workspace

local part = Instance.new('Part')
part.Anchored = true
part.CanCollide = false
part.Material = Enum.Material.Neon
part.Parent = folder

local part2 = Instance.new('Part')
part2.Anchored = true
part2.CanCollide = false
part2.Color = Color3.fromRGB(255, 0, 0)
part2.Material = Enum.Material.Neon
part2.Parent = folder

local velpart = Instance.new('Part')
velpart.Anchored = true
velpart.CanCollide = false
velpart.CanQuery = false
velpart.Parent = folder

local bodyv = Instance.new('BodyVelocity')
bodyv.MaxForce = Vector3.one * 10000000
bodyv.Parent = velpart

local overlap = OverlapParams.new()
overlap.FilterType = Enum.RaycastFilterType.Include
overlap.FilterDescendantsInstances = {workspace:FindFirstChild('.Ignore')}

local gravity = Vector3.new(0, -1, 0) * 200
--local step = 0
local locked = os.clock()

function SpellMethods:PredictPosition()

	--step += 1
	--self.SpellsTarget.PrimaryPart.AssemblyLinearVelocity --
	local enemyVelocity = self.SpellsTarget.Velocity --+ self.SpellsTarget.Acceleration * Vector3.new(1, 0, 1)
	--local includeGravity = 1

	local enemyAcceleration = self.SpellsTarget.Acceleration * Vector3.new(1, 0, 1)

	--if (enemyAcceleration.Magnitude < 120) then enemyAcceleration = Vector3.zero end
	--enemyVelocity = self.SpellsTarget.VelocitySlow

	if ((enemyAcceleration * Vector3.new(1, 0, 1)).Magnitude > .5) then
		enemyVelocity = self.SpellsTarget.VelocitySlow
        enemyAcceleration = Vector3.zero 
	end

	local applyGravity = 0
    local pingOffset = self.LocalComponent.Ping/1000 * 2 * self.ApplyPing

	if (self.SpellsTarget.Humanoid.FloorMaterial == Enum.Material.Air) then
		applyGravity = 1
        pingOffset /= 2
		--enemyVelocity *= Vector3.new(1, 0, 1)
	end
	--[[
	if (enemyVelocity.Y > 0) then
		applyGravity = 0
	end
	]]

	local params = RaycastParams.new()
	params.FilterDescendantsInstances = {self.SpellsTarget.Character, part}
	params.FilterType = Enum.RaycastFilterType.Exclude

	enemyAcceleration += applyGravity * gravity
	local oldPosition = self.PredictedPosition --+ primaryPart.AssemblyLinearVelocity.Unit * 3

	local enemyPosition = self.SpellsTarget.PrimaryPart.Position --+ Vector3.new(_G.Offsets['Distance'], 0, 0) --+ enemyVelocity * .2
		--+ enemyVelocity * _G.Offsets['Ping']*10
	
	--print(self.SpellsTarget.Instance:GetNetworkPing()*2)

    if (enemyVelocity.Magnitude < 2) then
        enemyAcceleration = Vector3.zero
    end
	
	local shootPosition = self.LocalComponent.PrimaryPart.Position + (self.PredictedPosition - self.LocalComponent.PrimaryPart.Position).Unit * 10 +
        self.LocalComponent.PrimaryPart.Velocity * pingOffset

     --self.LocalComponent.PrimaryPart.Position 
    --self.LocalComponent.ExtraCFrame.Position -- self.LocalComponent.PrimaryPart.Position 
    --self.SpellsTarget.PrimaryPart.Position + Vector3.new(_G.Offsets['Distance'], 0, 0) --

    if ((shootPosition - enemyPosition).Magnitude < 20) then
        pingOffset = 0
    end

	local predictedPosition = Vector3.new(0,0,0)
	local predtime = 0

    --local shootDistance = (enemyPosition - shootPosition).Magnitude
    --local offset = 0.15658 * 0.977^shootDistance --.16 * .975^shootDistance --0.001 * shootDistance^2 - 0.2425 * shootDistance + 15

	for i = 1, 50 do
		predictedPosition = enemyPosition + enemyAcceleration/2 * predtime^2 
			+ enemyVelocity * predtime

		predtime = (predictedPosition - shootPosition).Magnitude/self.Velocity
			--* (1 + offset*_G.Offsets['Ping']*10)

		if (predtime ~= predtime) then predtime = 1 end
	end

    predtime += pingOffset + .1 --pingOffset

    predictedPosition = enemyPosition + enemyAcceleration/2 * (predtime)^2 
    + enemyVelocity * (predtime)

	if (predtime ~= predtime or predtime > 10) then predtime = 1 end


	local ray2 = game.Workspace:Raycast(enemyPosition, enemyAcceleration/2 * predtime^2 
		+ enemyVelocity * predtime, params)
	if (ray2) then 

		local pos = ray2.Position + Vector3.new(0, 2, 0)

        --[[
		if (ray2.Position.Y > predictedPosition.Y) then
			pos = (enemyPosition - (enemyPosition - pos).Unit * (enemyPosition - predictedPosition).Magnitude)
                * Vector3.new(1, 0, 1) + ray2.Position * Vector3.new(0, 1, 0)
		end
        ]]

		predictedPosition = pos

	end

	self.PredictedPosition = predictedPosition + Vector3.new(0, 1.7, 0)
	local willHit = false

	if ((enemyAcceleration * Vector3.new(1, 0, 1)).Magnitude < 1) then
		willHit = true
	end

    local difference = ((oldPosition - enemyPosition).Unit -  (predictedPosition - enemyPosition).Unit).Unit * Vector3.new(1, 0, 1)

    if (difference.Magnitude > .5) then
        locked = os.clock() - 1
    end

	if (os.clock() - locked < 0) then  
		self.PredictedPosition = oldPosition
	end

	if (self.AimFilter and willHit and os.clock() - locked > 0) then
		locked = os.clock() + predtime * 1.2

        --predtime -= pingOffset

        --predictedPosition = enemyPosition + enemyAcceleration/2 * (predtime)^2 
        --+ enemyVelocity * (predtime)

        --oldPosition = predictedPosition

        oldPosition += enemyAcceleration/2 * predtime^2 + enemyVelocity * predtime
	end

	--print(self.SpellsTarget.PrimaryPart.AssemblyLinearVelocity.Magnitude)
	
	part.CFrame = CFrame.new(self.PredictedPosition) --CFrame.new(enemyPosition)
--[[
    part2.CFrame = CFrame.new(enemyPosition)

    local clonned = velpart:Clone()
    clonned.CFrame = CFrame.new(shootPosition, self.PredictedPosition)
    clonned.BodyVelocity.Velocity = clonned.CFrame.LookVector * self.Velocity
    clonned.Parent = workspace

    task.wait(self.LocalComponent.Ping/1000 * 2 + .1)

    clonned.Anchored = false

    task.delay(predtime + 1, function()
        clonned:Destroy()
    end)
    ]]
end

function SpellMethods:GetElementBySpellName(abilityName: string)
    local selectedUI;

    for _, v in ipairs(StarterGui.Main.Character.Available.ScrollingFrame.Frame:GetChildren()) do 
        if (v.Name == abilityName) then selectedUI = abilityName; break; end
    end

    local element = self:GetElement(selectedUI.BackgroundColor3)
    print(element)
    if (not element) then return end

    return element
end

function SpellMethods:GetSpellInfo() -- do later
    local selectedUI = self:GetEquippedSpell() :: ImageButton
    print(selectedUI)
    if (not selectedUI) then return end

    local spellName = self:GetSpellNameByImageAndColor(selectedUI.Image, selectedUI.BackgroundColor3)
    print(spellName)
    if (not spellName) then return end

    local element = self:GetElement(selectedUI.BackgroundColor3)
    print(element)
    if (not element) then return end

    return element, spellName
end

function SpellFabric.new(localPlayer)

    local self = setmetatable({}, {__index = SpellMethods})

    self.LocalComponent = localPlayer
    self.SelectedType   = Config.Enums.Target.Target
    self.TPType         = Config.Enums.TPType.Swap
    self.SpellsTarget   = localPlayer
    self.Velocity       = 700

    self.PredictedPosition = Vector3.new(0,0,0)
    self.PredictedVelocity = Vector3.new(0,0,0)

    self.SkipCD       = false
    self.IgnoreAimbot = false
    self.AutoPunch    = false

    self.AimFilter = false
    self.ApplyPing = 1

    self.SkipUltCDOnSpawn = true

    RunService.Heartbeat:Connect(function()
        self:GetSpellsTargetByType()

        if (not self.SpellsTarget.PrimaryPart) then return end

        self:PredictPosition()

        if (self.SkipCD) then 
            ClientData:FireServer(nil)
            return
        end

        if (self.LocalComponent.Aimbot and not self.IgnoreAimbot) then 
            ClientData:FireServer({['Cooldowns'] = "{}", ['Mouse'] = self.PredictedPosition, ['Holding'] = true, ['Camera'] = self.LocalComponent.PrimaryPart.Position})
            return
        end
        
    end)

    UserInput.InputBegan:Connect(function(input, event)
        --print(input.KeyCode, event)
        --if event then return end
        if (input.KeyCode == self.LocalComponent.Binds['UseSpell']) then
            self.AimFilter = false
            self.Velocity  = Config.Offsets.ProjectileSpeed['Default']

            local element, spellName = self:GetSpellInfo()
            if (not element) then return end

            self.AimFilter = Config.Offsets.LockFilter[spellName]
            self.Velocity  = Config.Offsets.ProjectileSpeed[spellName] or Config.Offsets.ProjectileSpeed['Default']

            if (Config.Spells.Disabled[spellName]) then
                self.IgnoreAimbot = true
            end

            print(Config.Spells.Modified[spellName])
            if (not Config.Spells.Modified[spellName]) then return end
            self:UseSpell(element, spellName)
        end

        if (input.UserInputType == Enum.UserInputType.MouseButton1) then
            self.AimFilter = false
            self.Velocity  = Config.Offsets.ProjectileSpeed['Default']

            local element, spellName = self:GetSpellInfo()
            if (not element) then return end

            self.AimFilter = Config.Offsets.LockFilter[spellName]
            self.Velocity  = Config.Offsets.ProjectileSpeed[spellName] or Config.Offsets.ProjectileSpeed['Default']

            if (Config.Spells.Disabled[spellName]) then
                self.IgnoreAimbot = true
            end
        end

        if (input.KeyCode == self.LocalComponent.Binds['SkipCD']) then
            self.SkipCD = true
            task.wait(.1)
            self.SkipCD = false
        end
    end)

    UserInput.InputEnded:Connect(function(input, event)
        if (input.KeyCode == self.LocalComponent.Binds['UseSpell'] or input.UserInputType == Enum.UserInputType.MouseButton1) then
            local element, spellName = self:GetSpellInfo()
            if (not element) then return end

            if (not Config.Spells.Disabled[spellName]) then return end
            task.delay(1, function()
                self.IgnoreAimbot = false
            end)
        end
    end)

    self.LocalComponent.Instance.CharacterAdded:Connect(function()
        if (not self.SkipUltCDOnSpawn) then return end
        task.wait(1)
        self:SkipUltCD()
    end)

    while task.wait(1/10) do

        if (self.LocalComponent.ResetOnMana and self.LocalComponent.Mana < self.LocalComponent.MinMana) then
            self.LocalComponent.Health = 0
        end

        for _, spellName in ipairs(Config.Spells.Chained) do                     --*please use cache here
            local element = self:GetElementBySpellName(spellName)
            if (not element) then continue end

            if (not Config.Spells.Modified[spellName]) then return end
            self:UseSpell(element, spellName)
        end
    end

    return self
end

local Player = LocalFabric.new(Players.LocalPlayer)

return {
    ['Pannel'] = Pannel,
    ['Spells'] = SpellFabric.new(Player),
    ['Player'] = Player,

    ['PlayerFabric'] = PlayerFabric,
    ['EnemyFabric']  = EnemyFabric,
    ['AllyFabric']   = AllyFabric,

    ['Config'] = Config,
}