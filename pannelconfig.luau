
local GeneralInfo = 
{

	['Types'] = {
    	['rbxassetid://523596305'] = "Bullets",
    	['rbxassetid://523612283'] = "Beam",
    	['rbxassetid://523697411'] = "AOE",
    	['rbxassetid://531829466'] = "Dash",
    	['rbxassetid://523612444'] = "Grab",
    	['rbxassetid://561899135'] = "Heal",
    	['rbxassetid://523612211'] = "Shield",
    	['rbxassetid://523612158'] = "Aura",
    	['rbxassetid://523612387'] = "Ult",
	},

	['ElementsTypes'] = {
		['Fire']       = Color3.fromRGB(255, 89, 92),
		['Water']      = Color3.fromRGB(35, 114, 232),
		['Grass']      = Color3.fromRGB(140, 255, 140),
		['Earth']      = Color3.fromRGB(153, 76, 51),
		['Wind']       = Color3.fromRGB(255, 255, 178),
		['Storm']      = Color3.fromRGB(0, 255, 255),
		['Lava']       = Color3.fromRGB(255, 165, 0),
		['Ice']        = Color3.fromRGB(191, 255, 249),
		['Nature']     = Color3.fromRGB(0, 165, 0),
		['Plasma']     = Color3.fromRGB(255, 0, 191),
		['Crystal']    = Color3.fromRGB(212, 144, 189),
		['Spirit']     = Color3.fromRGB(188, 186, 183),
		['Gravity']    = Color3.fromRGB(89, 34, 89),
		['Light']      = Color3.fromRGB(255, 255, 12),
		['Darkness']   = Color3.fromRGB(73, 109, 73),
        ['Spectrum']   = Color3.fromRGB(255, 255, 255),
		['Void']       = Color3.fromRGB(100, 0, 200),
		['Nightmare']  = Color3.fromRGB(170, 0, 170),
		['Time']       = Color3.fromRGB(102, 153, 76),
		['Space']      = Color3.fromRGB(30, 68, 165),
		['Phoenix']    = Color3.fromRGB(80, 128, 158),
		['Reaper']     = Color3.fromRGB(226, 178, 32),
		['Aurora']     = Color3.fromRGB(88, 220, 6),
		['Sound']      = Color3.fromRGB(200, 110, 160),
		['Explosion']  = Color3.fromRGB(255, 119, 29),
		['Chaos']      = Color3.fromRGB(220, 20, 60),
		['Illusion']   = Color3.fromRGB(170, 45, 45),
		['Dragon']     = Color3.fromRGB(34, 83, 27),
		['Acid']       = Color3.fromRGB(190, 255, 45),
		['Angel']      = Color3.fromRGB(255, 241, 142),
		['Slime']      = Color3.fromRGB(178, 207, 255),
		['Technology'] = Color3.fromRGB(60, 182, 0),
		['Creation']   = Color3.fromRGB(143, 105, 255),
		['Solar']      = Color3.fromRGB(198, 65, 32),
	}
}

local Enums = {
    ['Target'] = {
        ['Target']  = 0,
        ['Closest'] = 1,
        ['Mouse']   = 2,
        ['Ally']    = 3
    },

    ['TPType'] = {
        ['Swap']  = 0,
        ['Float'] = 1,
        ['Void']  = 2
    }
}

local spells = 
{
    ['Modified'] = {},
}

local ClassPlayers = 
{
    ['Enemies'] = {},
    ['Allies']  = {}
    
}

local spellsLibrary = {}
local AllPlayers = {}

_G.Offsets = { -- easier to debug
    ['ProjectileSpeed'] = {
        ['Default'] = 300,
        ['Poison Needles'] = 700,
    },

    ['Distance'] = 50,

    ['Plasma Missiles Hold'] = 1.8,
    ['Plasma Missiles'] = 2.4,
    ['Blaze Column'] = .4,

    ['Poison Needles Hold'] = 1.8,
    ['Poison Needles'] = 1.3,

    ['Great Tree of Abolition'] = 5,
}

return {
    ['GeneralInfo'] = GeneralInfo,
    ['Enums']       = Enums,
    ['Spells']      = spells,

    ['SpellsLibrary'] = spellsLibrary,
    ['ClassPlayers']  = ClassPlayers,
    ['AllPlayers']    = AllPlayers,

    ['Offsets'] = _G.Offsets
}