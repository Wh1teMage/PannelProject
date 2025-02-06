local Core   = require('./pannelcore')
local Config = require('./pannelconfig')

local Players    = game:GetService("Players")
local Replicated = game:GetService("ReplicatedStorage")
local UserInput  = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TPService  = game:GetService("TeleportService")
local VUser      = game:GetService("VirtualUser")
local Lighting   = game:GetService("Lighting")
local TweenServ  = game:GetService("TweenService")
local Debris     = game:GetService("Debris")
local CoreGui    = game:GetService('CoreGui')

local DoClientMagic = Replicated['Remotes']['DoClientMagic'] :: RemoteEvent
local DoMagic       = Replicated['Remotes']['DoMagic'] :: RemoteFunction
local Combat        = Replicated['Remotes']['Combat'] :: RemoteEvent
local KeyReserve    = Replicated['Remotes']['KeyReserve']
local PlayerData    = Replicated['Remotes']['PlayerData'] :: RemoteEvent
local ClientData    = Replicated['Remotes']['ClientData'] :: RemoteEvent

local Ignore       = workspace:WaitForChild('.Ignore') :: Folder
local Attacks      = Ignore:WaitForChild('.Attacks') :: Folder
local LocalEffects = Ignore:WaitForChild('.LocalEffects') :: Folder

local function toboolean(msg)
    if (string.lower(msg) == 'true') then return true end
    return false
end

local function getPlayerNames()
    local names = {}

    for _, player in pairs(Players:GetPlayers()) do
        table.insert(names, player.Name)
    end

    return names
end

Core.Spells:AddSpell('Plasma', 'Plasma Missiles', 
    function(elementName, abilityName, self)
        local previousState = Core.Player.Aimbot

        DoClientMagic:FireServer(elementName, abilityName)

        task.wait(_G.Offsets['Plasma Missiles Hold'])
        Core.Player.Aimbot = false

        task.delay(_G.Offsets['Plasma Missiles']*.4, function()
            Core.Player.Aimbot = previousState
            task.wait(_G.Offsets['Plasma Missiles']*.6)
            self.SkipCD = true
            task.wait(1/60*2)
            self.SkipCD = false
        end)
    end
)

Core.Spells:AddSpell('Grass', 'Poison Needles', 
    function(elementName, abilityName, self)

        DoClientMagic:FireServer(elementName, abilityName)

        task.wait(_G.Offsets[abilityName..' Hold'])

        task.delay(_G.Offsets[abilityName], function()
            self.SkipCD = true
            task.wait(1/60*2)
            self.SkipCD = false
        end)
    end
)

Core.Spells:AddSpell('Nature', 'Great Tree of Abolition', 
    function(elementName, abilityName, self)

        DoClientMagic:FireServer(elementName, abilityName)

        task.wait(.5)

        task.delay(_G.Offsets['Great Tree of Abolition'], function()
            self.SkipCD = true
            task.wait(1/60*5)
            self.SkipCD = false
        end)
    end
)

Core.Spells:AddSpell('Fire', 'Blaze Column',
    function(elementName, abilityName, self)
        local p1 = self.SpellsTarget.PrimaryPart.Position
        local v1 = self.SpellsTarget.Velocity

        DoClientMagic:FireServer(elementName, abilityName, p1 + v1*.15 + Vector3.new(0, -2, 0))
    end,

    function(elementName, abilityName, self)
        local distance  = self.SpellsTarget:Distance()
        local oldCFrame = Core.Player.PrimaryPart.CFrame
        
        if distance > 200 then
            Core.Player.PrimaryPart.CFrame = self.SpellsTarget.CFrame + Vector3.new(0,40,0)
        end

        task.wait(_G.Offsets['Blaze Column'])

        local p1 = self.SpellsTarget.PrimaryPart.Position
        local v1 = self.SpellsTarget.Velocity

        DoMagic:InvokeServer(elementName, abilityName, CFrame.new(p1 + v1*.15, p1 + v1*.15 + Vector3.new(0, -2, 0)))
        if distance > 200 then Core.Player.PrimaryPart.CFrame = oldCFrame end
    end
)

Core.Pannel:CreateCommand('ModifySpell', 'SpellName', Core.Spells:GetAvaliableSpells(), 'modifies a certain spell', function(...)
    Core.Spells:ModifySpell(table.concat({...}, ' '))
end)

Core.Pannel:CreateCommand('RevertSpell', 'SpellName', Core.Spells:GetAvaliableSpells(), 'reverts modification from a certain spell', function(...)
    Core.Spells:RevertSpell(table.concat({...}, ' '))
end)

Core.Pannel:CreateCommand('Fly', 'Bool', {'true', 'false'}, 'enable / disable fly', function(bool)
    Core.Player:FlyFunction(toboolean(bool))
end)

Core.Pannel:CreateCommand('SetFlySpeed', 'Integer', {}, 'adjust fly speed', function(num)
    Core.Player.MaxFlySpeed = math.round(tonumber(num) or 100)
    Core.Pannel:CreateNotification('Changed Fly speed', 'Fly speed is '..tostring(Core.Player.MaxFlySpeed), 5)
end)

Core.Pannel:CreateCommand('SetVelocity', 'Integer', {}, 'adjust bullet speed', function(num)
    Core.Spells.Velocity = math.round(tonumber(num) or 350)
end)

Core.Pannel:CreateCommand('Noclip', 'Bool', {'true', 'false'}, 'enable / disable noclip', function(bool)
    Core.Player:NoclipFunction(toboolean(bool))
end)

Core.Pannel:CreateCommand('SetWalkSpeed', 'Bool', {}, 'adjust walkspeed', function(num)
    Core.Player.WalkSpeed = math.round(tonumber(num) or 32)
    Core.Player.Humanoid.WalkSpeed = Core.Player.WalkSpeed
    Core.Pannel:CreateNotification('Changed Walkspeed', 'Walkspeed is '..tostring(Core.Player.WalkSpeed), 5)
end)

Core.Pannel:CreateCommand('SetJumpPower', 'Bool', {}, 'adjust jumppower', function(num)
    Core.Player.JumpPower = math.round(tonumber(num) or 50)
    Core.Player.Humanoid.JumpPower = Core.Player.JumpPower
    Core.Pannel:CreateNotification('Changed Jumppower', 'Jumppower is '..tostring(Core.Player.JumpPower), 5)
end)

Core.Pannel:CreateCommand('ChangeTarget', 'Nickname', getPlayerNames(), 'select a target to fire', function(name)
    local component = Core.PlayerFabric:GetPlayer(name)
    if (not component) then return end

    Core.Player.SelectedTarget = component
end)

Core.Pannel:CreateCommand('TargetType', 'Type', {'Target', 'Closest', 'Mouse', 'Ally'}, 'change targetting type', function(msg)
    if (not Config.Enums.Target[msg]) then return end
    Core.Spells.SelectedType = Config.Enums.Target[msg]
end)

Core.Pannel:CreateCommand('Aimbot', 'Bool', {'true', 'false'}, 'enable / disable aimbot', function(bool)
    Core.Player.Aimbot = toboolean(bool)
end)

Core.Pannel:CreateCommand('AntiBlind', 'Bool', {'true', 'false'}, 'enable / disable antiblind', function(bool)
    Core.Player.AntiBlind = toboolean(bool)
end)

Core.Pannel:CreateCommand('Invisible', 'Bool', {'true', 'false'}, 'enable / disable invisibility', function(bool)
    Core.Player:InvisibleFunction(toboolean(bool))
end)

Core.Pannel:CreateCommand('AutoPunch', 'Bool', {'true', 'false'}, 'enable / disable autopunch', function(bool)
    Core.Player:AutoPunchFunction(toboolean(bool))
end)

Core.Pannel:CreateCommand('Spawnpoint', 'Bool', {'true', 'false'}, 'enable / disable spawnpoint', function(bool)
    Core.Player:SpawnpointFunction(toboolean(bool))
end)

Core.Pannel:CreateCommand('Spectate', 'Bool', {'true', 'false'}, 'enable / disable spectate', function(bool)
    Core.Player:SpectateFunction(toboolean(bool))
end)

Core.Pannel:CreateCommand('Follow', 'Bool', {'true', 'false'}, 'enable / disable follow', function(bool)
    Core.Player:FollowFunction(toboolean(bool))
end)

Core.Pannel:CreateCommand('Teleport', '', {}, 'teleport to selected target', function()
    Core.Player:TeleportFunction()
end)

--** Initialization

local function updatePlayerVelocity(self, dt)
	if not self.PrimaryPart then return end
	--if (os.clock() - self.LastTick < 1/60*1) then return end

	if (#self.VelocitiesSlow > self.MaxVelocitiesSlow) then
		local lost = table.remove(self.VelocitiesSlow, 1)
		self.VelocitySumSlow -= lost
	end

	if (#self.Velocities > self.MaxVelocities) then
		local lost = table.remove(self.Velocities, 1)
		local lostAccel = table.remove(self.Accelerations, 1)

		self.VelocitySum -= lost
		self.AccelerationSum -= lostAccel
	end

	if (#self.Positions > self.MaxPositions) then
		local lost = table.remove(self.Positions, 1)

        self.ExtraCFrame = lost
		self.PositionsSum -= lost.Position
	end

	local delta = (self.PrimaryPart.Position - self.CFrame.Position)
	--if (delta.Magnitude < 1/100) then delta = Vector3.new(0,0,0) end

	local velocity = self.PrimaryPart.AssemblyLinearVelocity --delta/dt -- --

	if ((velocity - delta/dt).Magnitude > 32) then
		velocity = delta/dt
		--velocity = self.PrimaryPart.AssemblyLinearVelocity
	end

	local acceleration = (self.Velocity - velocity)

	table.insert(self.VelocitiesSlow, velocity)
	table.insert(self.Velocities, velocity)
	table.insert(self.Accelerations, acceleration)
	table.insert(self.Positions, self.PrimaryPart.CFrame)

	self.VelocitySum  += velocity
	self.PositionsSum += self.PrimaryPart.CFrame.Position
	self.AccelerationSum  += acceleration
	self.VelocitySumSlow  += velocity

	self.Velocity     = self.PrimaryPart.AssemblyLinearVelocity --self.VelocitySum/(self.MaxVelocities+1)
	self.Acceleration = self.AccelerationSum/(self.MaxVelocities+1)
	self.VelocitySlow = self.VelocitySumSlow/(self.MaxVelocitiesSlow+1)

	if (delta.Magnitude / dt < 5) then
		self.Velocity = Vector3.zero
		self.Acceleration = Vector3.zero
	end

	--if (self.Acceleration ~= self.Acceleration) then self.Acceleration = Vector3.zero end

	--local avgPosition = self.PositionsSum/(self.MaxPositions+1)

    --[[
    if ((self.PrimaryPart.Position - avgPosition).Magnitude < 1.8) then
        self.Velocity = Vector3.new(0,0,0)
    end
    ]]

	self.CFrame   = self.PrimaryPart.CFrame
	self.LastTick = os.clock()
end

local function updatePlayerData(self, data)
    self.MaxMana = math.round(self.MaxMana*10)
    self.Mana    = math.round(self.Mana*10)

    self.MaxStamina = math.round(self.MaxStamina*10)
    self.Stamina    = math.round(self.Stamina*10)

    self.Running  = data.Running
    self.Blocking = data.Blocking
    self.Safezone = data.Safezone
    self.Stunned  = data.Stunned

    self.Loadout = data.Data.Loadout
    self.Stats   = data.Data.Stats
end

local function updatePlayerRaycast(self, mousePosition, cameraPosition)

    self.MousePosition  = mousePosition
    self.CameraPosition = cameraPosition

end

RunService.Heartbeat:Connect(function(dt)

    for _, player in pairs(Core.PlayerFabric:GetPlayers()) do
        if (not getmetatable(player)) then continue end
        updatePlayerVelocity(player, dt)
    end

end)   

Players.PlayerAdded:Connect(function(player)
    Core.EnemyFabric.new(player, Core.Player)
    Core.Pannel:UpdateCommand('ChangeTarget', getPlayerNames())
end)

Players.PlayerRemoving:Connect(function(player)
    local component = Core.PlayerFabric:GetPlayer(player.Name)
    if (not component) then return end
    component:Destroy()
    Core.Pannel:UpdateCommand('ChangeTarget', getPlayerNames())
end)

PlayerData.OnClientEvent:Connect(function(player, data)
    local component = Core.PlayerFabric:GetPlayer(player.Name)
    if (not component) then return end
    updatePlayerData(component, data)
end)

ClientData.OnClientEvent:Connect(function(player, cooldowns, mousePosition, isHolding, cameraPosition)
    local component = Core.PlayerFabric:GetPlayer(player.Name)
    if (not component) then return end
    updatePlayerRaycast(component, mousePosition, cameraPosition)
end)

for _, player in pairs(Players:GetPlayers()) do
    Core.EnemyFabric.new(player, Core.Player)
end

LocalEffects.ChildAdded:Connect(function(child)
    if child.Name == 'LightDisc' or child.Name == 'BoltPart' or string.match(child.Name, 'Sound') ~= nil then Debris:AddItem(child, 5) end
end)

Attacks.ChildAdded:Connect(function(child)
    if child.Name == 'HowlingVisage' then Debris:AddItem(child, 5) end
end)
