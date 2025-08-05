
local _G = GLOBAL


Assets = {
    Asset( "ANIM", "anim/airplane_anim.zip" ),
    Asset( "ANIM", "anim/airplane_base.zip" ),
    Asset( "ANIM", "anim/airplane_background.zip" ),
    Asset( "ANIM", "anim/airplane_hud.zip" ),
    Asset( "ANIM", "anim/airplane_parts.zip" ),
    Asset("ANIM", "anim/winona_battery_placement.zip"),
    Asset("ATLAS", "images/inventoryimages/airplane_parts.xml"),
    Asset("IMAGE", "images/inventoryimages/airplane_parts.tex"),
    Asset("ATLAS", "images/inventoryimages/airplane_plans.xml"),
    Asset("IMAGE", "images/inventoryimages/airplane_plans.tex"),
}

PrefabFiles =
{
	"airplane",
	"airplane_plans",
	"airplane_parts",
}

---------------------------------------------------------------------------



AddModRPCHandler("airplane", "ThrottleUp", function(player)
    if not _G.TheWorld.ismastersim or player.components.airplaneaviator == nil then
		return
	end
	player.components.airplaneaviator:ThrottleUp()
end)

AddModRPCHandler("airplane", "ThrottleDown", function(player)
    if not _G.TheWorld.ismastersim or player.components.airplaneaviator == nil then
		return
	end
	player.components.airplaneaviator:ThrottleDown()
end)

AddModRPCHandler("airplane", "RudderLeft", function(player)
    if not _G.TheWorld.ismastersim or player.components.airplaneaviator == nil then
		return
	end
	player.components.airplaneaviator:RudderLeft()
end)

AddModRPCHandler("airplane", "RudderRight", function(player)
    if not _G.TheWorld.ismastersim or player.components.airplaneaviator == nil then
		return
	end
	player.components.airplaneaviator:RudderRight()
end)

AddModRPCHandler("airplane", "YokeUp", function(player)
    if not _G.TheWorld.ismastersim or player.components.airplaneaviator == nil then
		return
	end
	player.components.airplaneaviator:YokeUp()
end)

AddModRPCHandler("airplane", "YokeDown", function(player)
    if not _G.TheWorld.ismastersim or player.components.airplaneaviator == nil then
		return
	end
	player.components.airplaneaviator:YokeDown()
end)

---------------------------------------------------------------------------

AddPrefabPostInit("player_classified",function(inst)
	inst.airplane_ison=_G.net_bool(inst.GUID, "airplane_ison", "airplane_ison")
    inst.airplane_isflying=_G.net_bool(inst.GUID, "airplane_isflying")
	inst.airplane_rotation=_G.net_float(inst.GUID, "airplane_rotation")
	inst.airplane_parspeed=_G.net_float(inst.GUID, "airplane_parspeed")
	inst.airplane_perspeed=_G.net_float(inst.GUID, "airplane_perspeed")
	inst.airplane_fuel=_G.net_float(inst.GUID, "airplane_fuel")
	inst.airplane_safelanding=_G.net_bool(inst.GUID, "airplane_safelanding")
	inst.airplane_hardlanding=_G.net_bool(inst.GUID, "airplane_hardlanding")
	if _G.TheWorld.ismastersim then
    	inst.airplane_ison:set(false)
    	inst.airplane_parspeed:set(0)
    	inst.airplane_perspeed:set(0)
    	inst.airplane_rotation:set(0)
    	inst.airplane_fuel:set(0)
    	inst.airplane_safelanding:set(false)
    	inst.airplane_hardlanding:set(false)
    end
end)

AddPlayerPostInit(function(inst)
    if _G.TheWorld.ismastersim then
    	inst:AddComponent("airplaneaviator")
    end
	inst:AddComponent("airplanecontroller")
	inst:DoTaskInTime(0, function(inst)
	    -- Event Listeners post load
	    -- On cart
        inst:ListenForEvent("airplane_ison",function()
            if inst ~= nil and inst.components.airplanecontroller ~= nil then
                if inst.player_classified.airplane_ison:value() == true then
                    inst.components.airplanecontroller:TurnOn()
                else
                    inst.components.airplanecontroller:TurnOff()
                end
            end
        end,inst.player_classified)
        -- On tool
    end)
    inst.AnimState:AddOverrideBuild("airplane_base")
end)

---------------------------------------------------------------------------

local OnAirplane = _G.State({
	name = "onairplane",
    tags = { "pinned", "nopredict" },

    onenter = function(inst)

        inst.components.locomotor:Stop()
        inst:ClearBufferedAction()

        if inst.components.playercontroller ~= nil then
            inst.components.playercontroller:EnableMapControls(false)
            inst.components.playercontroller:Enable(false)
        end
        inst.components.inventory:Hide()
        inst.Transform:SetFourFaced()
        inst.AnimState:PlayAnimation("airplane")
        inst.AnimState:SetDeltaTimeMultiplier(0)
        inst.AnimState:SetTime(5)
    end,

    onexit = function(inst)
        if inst.components.airplaneaviator ~= nil then
            inst.components.airplaneaviator:DropOff()
        end
        inst.components.inventory:Show()
        inst.AnimState:SetDeltaTimeMultiplier(1)
        if inst.components.playercontroller ~= nil then
            inst:DoTaskInTime(0.55, function(inst)
                inst.components.playercontroller:EnableMapControls(true)
                inst.components.playercontroller:Enable(true)
            end)
        end
    end,
    
    events =
    {
        _G.EventHandler("attacked", function(inst)
            if inst.components.airplaneaviator ~= nil then
                inst.components.airplaneaviator:DropOff()
            end
            if inst.components.playercontroller ~= nil then
                inst:DoTaskInTime(0.5, function(inst)
                    inst.components.playercontroller:EnableMapControls(true)
                    inst.components.playercontroller:Enable(true)
                end)
            end
        end),
        _G.EventHandler("death", function(inst, data)
            if inst.components.airplaneaviator ~= nil then
                inst.components.airplaneaviator:DropOff()
            end
            if inst.components.playercontroller ~= nil then
                inst:DoTaskInTime(0.5, function(inst)
                    inst.components.playercontroller:EnableMapControls(true)
                    inst.components.playercontroller:Enable(true)
                end)
            end
        end),
    },
    
    })

AddStategraphState("wilson",OnAirplane)

---------------------------------------------------------------------------

-- Based on Minimap HUD (squeek)
-- Link: https://steamcommunity.com/sharedfiles/filedetails/?id=345692228



local function AddAirPlaneHud(self)

	self.inst:DoTaskInTime( 0, function()

        local AirplaneHud = require "widgets/airplane_hud"
		self.airplane_hud = self.bottom_root:AddChild( AirplaneHud(self.owner) )
		self.airplane_hud.curr_pos=self.airplane_hud.closed_pos
		self.airplane_hud:SetPosition(0,self.airplane_hud.closed_pos)
		local hud_scale = self.bottom_root:GetScale()
	    local screensize_x, screensize_y
	    screensize_x, screensize_y=_G.TheSim:GetScreenSize()
        local ssx=screensize_x/1432./hud_scale.x
        local ssy=screensize_y/812./hud_scale.y
        self.airplane_hud:SetScale(ssx,ssy)
		self.airplane_hud:Hide()
	end)

end

AddClassPostConstruct( "widgets/controls", AddAirPlaneHud )


---------------------------------------------------------------------------

local pfbs={"airplane_cable", "airplane_motor", "airplane_propeller", "airplane_waxsilk", "airplane_fuel"}

local easyrecipe=GetModConfigData("AIRPLANE_EASYRECIPE")

local ingredients={
    ["airplane_cable"]={},
    ["airplane_motor"]={},
    ["airplane_propeller"]={},
    ["airplane_waxsilk"]={},
    ["airplane_fuel"]= {},
}

if not easyrecipe then
    ingredients={
        ["airplane_cable"]={_G.Ingredient("cutreeds", 3), _G.Ingredient("ash", 1)},
        ["airplane_motor"]={_G.Ingredient("farm_plow_item", 1), _G.Ingredient("gears", 2), _G.Ingredient("goldnugget", 6)},
        ["airplane_propeller"]={_G.Ingredient("boards", 2), _G.Ingredient("rope", 3), _G.Ingredient("gears",1)},
        ["airplane_waxsilk"]={_G.Ingredient("silk", 4), _G.Ingredient("beeswax", 1)},
        ["airplane_fuel"]= {_G.Ingredient("glommerfuel", 1), _G.Ingredient("boneshard", 1), _G.Ingredient("slurtleslime",1)},
    }
end

local numtogive={
    ["airplane_cable"]=3,
    ["airplane_motor"]=1,
    ["airplane_propeller"]=1,
    ["airplane_waxsilk"]=4,
    ["airplane_fuel"]=10,
}


local image={
    ["airplane_cable"]="airplane_cable.tex",
    ["airplane_motor"]="airplane_motor.tex",
    ["airplane_propeller"]="airplane_propeller.tex",
    ["airplane_waxsilk"]="airplane_waxsilk.tex",
    ["airplane_fuel"]="airplane_fuel.tex",
}

for k,v in pairs(pfbs) do
    AddRecipe(v,
        ingredients[v],
        _G.RECIPETABS.REFINE,
        _G.TECH.SCIENCE_TWO,
        nil, -- placer
        nil, -- min_spacing
        nil, -- nounlock
        numtogive[v], -- numtogive
        nil, -- builder_tag
        "images/inventoryimages/airplane_parts.xml", -- atlas
        image[v])
end

local plans_recipe={}
if not easyrecipe then
    plans_recipe={_G.Ingredient("twigs", 8), _G.Ingredient("rope", 4), _G.Ingredient("boards", 2)}
end

AddRecipe("airplane_plans",
    plans_recipe,
    _G.RECIPETABS.SCIENCE,
    _G.TECH.SCIENCE_TWO,
    "airplane_plans_placer", -- placer
    4, -- min_spacing
    nil, -- nounlock
    nil, -- numtogive
    nil, -- builder_tag
    "images/inventoryimages/airplane_plans.xml", -- atlas
    "airplane_plans.tex")

---------------------------------------------------------------------------


_G.CONSTRUCTION_PLANS["airplane_plans"] = {
    _G.Ingredient("airplane_motor", 1,"images/inventoryimages/airplane_parts.xml", nil),
    _G.Ingredient("airplane_propeller", 1,"images/inventoryimages/airplane_parts.xml", nil),
    _G.Ingredient("airplane_cable", 9,"images/inventoryimages/airplane_parts.xml", nil),
    _G.Ingredient("airplane_waxsilk", 8,"images/inventoryimages/airplane_parts.xml", nil)
}

---------------------------------------------------------------------------

GLOBAL.STRINGS.NAMES.AIRPLANE = "Airplane"
GLOBAL.STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIRPLANE = "Should we call it 15 bis?"

GLOBAL.STRINGS.NAMES.AIRPLANE_PLANS = "Airplane Plans"
GLOBAL.STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIRPLANE_PLANS = "Maybe 13 more attempts?"
GLOBAL.STRINGS.RECIPE_DESC.AIRPLANE_PLANS = "Maybe 13 more attempts?"

GLOBAL.STRINGS.NAMES.AIRPLANE_FUEL = "Airplane Fuel"
GLOBAL.STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIRPLANE_FUEL = "Unexpectedly stable."
GLOBAL.STRINGS.RECIPE_DESC.AIRPLANE_FUEL = "Unexpectedly stable."

GLOBAL.STRINGS.NAMES.AIRPLANE_PROPELLER = "Airplane Propeller"
GLOBAL.STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIRPLANE_PROPELLER = "A proper propeller."
GLOBAL.STRINGS.RECIPE_DESC.AIRPLANE_PROPELLER = "A proper propeller."

GLOBAL.STRINGS.NAMES.AIRPLANE_MOTOR = "Airplane Motor"
GLOBAL.STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIRPLANE_MOTOR = "Make stable fluids unstable."
GLOBAL.STRINGS.RECIPE_DESC.AIRPLANE_MOTOR = "Make stable fluids unstable."

GLOBAL.STRINGS.NAMES.AIRPLANE_WAXSILK = "Airplane Wax Silk"
GLOBAL.STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIRPLANE_WAXSILK = "Not suitable for bathrooms."
GLOBAL.STRINGS.RECIPE_DESC.AIRPLANE_WAXSILK = "Not suitable for bathrooms."

GLOBAL.STRINGS.NAMES.AIRPLANE_CABLE = "Airplane Cable"
GLOBAL.STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIRPLANE_CABLE = "It is not made of steel."
GLOBAL.STRINGS.RECIPE_DESC.AIRPLANE_CABLE = " It is not made of steel ."


---------------------------------------------------------------------------

local fuel_rate=GetModConfigData("AIRPLANE_FUELRATE")
local unbreakable=GetModConfigData("AIRPLANE_UNBREAKABLE")
local easy_landing=GetModConfigData("AIRPLANE_EASYLANDING")

AddPrefabPostInit("airplane",function(inst)
    if inst.components.airplane then
        inst.components.airplane.fuel_rate=fuel_rate
        inst.components.airplane.unbreakable=unbreakable
        inst.components.airplane.easy_landing=easy_landing
    end
end)

---------------------------------------------------------------------------

