name = "Airplane"
description = [[
Airplanes to Don't Starve Together!

-- How to Craft you Airplane: 
To craft your airplane, first you have to place the structure "Airplane Plans" on the ground.
You can craft the "Airplane Plans" in the Science Tab using an Alchemy Engine
 - Airplane Plans: 8 Twigs, 4 Ropes and 2 Boards.
 
After that, you have to full the Airplane Plans with the Airplane Parts. There are four parts that can be crafted on the Refine Tab using an Alchemy Engine:
 - Airplane Motor: 1 Garden Rigamajig, 2 Gears and 6 Gold Nuggets;
 - Airplane Propeller: 2 Boards, 3 Ropes, 1 Gears;
 - 3 Airplane Cables: 3 Cut Reeds, 1 Ash;
 - 4 Airplane Wax Silk: 4 Silks, 1 Beeswax
  
After building your airplane, you have to fill it with Airplane Fuel. You can craft it under the Refine Tab using an Alchemy Engine:
 - 10 Airplane Fuel: 1 Glommer's Goop, 1 Bone Shards, 1 Slurtle Slime.
 
Each fuel fills up to 10% of the Airplane Fuel Meter. If you completely fill your airplane fuel, it can fly to around 5 minutes.
 
-- Controls:
 - MOVE UP: Increase Throttle;
 - MOVE DOWN: Decrease Throttle/Rear;
 - MOVE LEFT: Turn Left;
 - MOVE RIGHT: Turn Right;
 - ATTACK BUTTON:  Pull Up;
 - ACTION BUTTON: Pull Down;
 
-- How to Fly:
If you are using a keyboard, we strongly recomend you to use one hand on the MOVE buttons and other in the ATTACK/ACTION button.
To fly, hold ATTACK BUTTON and MOVE UP at the same time until the airplane get fast enough.
Do not forget to fuel up your airplane first.

-- How to Land:
To land, you have to decrease your altitude while your forward speed is much higher than the downward speed. If not performed well, the airplane will hit the ground and dismantle, losing its fuel completely.
You can not land while turn left/right.

-- Helper Lights:
While in the airplane, you can see three lights in your panel and one marker circle on the ground.
If the green light is on, you can land safetly.
If orange light is on, you also can land, but a small mistake can make your landing fail.
If the red light is on, you can not land safetly.

-- Speed:
The maximum speed of the airplane on ground is 3.75 Tiles Per Second.
The maximum speed of the airplane in air is 6.25 Tiles Per Second.
The airplare requires around 3 Tiles Per Second to launch.
   
-- Options:
 - Airplane fuel rate: Modify the fuel consumption multiplier.
 - Easy landing: Always successful land.
 - Unbreakable airplane (on hit): The airplane will not dismantle when get hit.
 - Easy craft: Craft your airplane for free! (still requires the Alchemy Engine)
 
-- Changelog:

 - v1.01:
   Fixed a bug where characters with modified physics can not fly.

 - v1.00:
   Release

>>> This airplane model is inspired on the 14 Bis model. <<<
]]
author = "Gleenus and Catherine"
version = "1.01"
forumthread = ""
api_version = 10
dst_compatible = true

all_clients_require_mod = true
client_only_mod = false

server_filter_tags = {"gcmods", "airplane"}

icon_atlas = "images/modicon.xml"
icon = "modicon.tex"

----------------------------
-- Configuration settings --
----------------------------


configuration_options = 
{
	{
		name = "AIRPLANE_FUELRATE",
		label = "Airplane fuel rate",
		hover = "Modify the fuel consumption multiplier.",
		options =	
		{
		    {description = "0", data =  0},
		    {description = "0.2", data =  0.2},
		    {description = "0.4", data =  0.4},
		    {description = "0.6", data =  0.6},
            {description = "0.8", data =  0.8},
			{description = "1", data = 1},
			{description = "2", data = 2},
			{description = "3", data = 3},
			{description = "4", data = 4},
			{description = "5", data = 5},
		},
		default = 1,
	},
	
	{
		name = "AIRPLANE_EASYLANDING",
		label = "Easy landing",
		hover = "Always successful land.",
		options =	
		{
			{description = "No", data =  false},
			{description = "Yes", data = true},
		},
		default = false,
	},
	
	{
		name = "AIRPLANE_UNBREAKABLE",
		label = "Unbreakable airplane (on hit)",
		hover = "The airplane will not dismantle when get hit.",
		options =	
		{
			{description = "No", data =  false},
			{description = "Yes", data = true},
		},
		default = false,
	},
	
	{
		name = "AIRPLANE_EASYRECIPE",
		label = "Easy craft",
		hover = "Craft the airplane without items.",
		options =	
		{
			{description = "No", data =  false},
			{description = "Yes", data = true},
		},
		default = false,
	},
	

	
}

