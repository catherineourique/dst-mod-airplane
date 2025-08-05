local Widget = require "widgets/widget"
local Image = require "widgets/image"
local ImageButton = require "widgets/imagebutton"
local UIAnim = require "widgets/uianim"

local function AirplaneHUDOnOff(self)
    if  self.owner ~= nil and
        self.owner.player_classified ~= nil and
        self.owner.player_classified.airplane_ison ~= nil and
        self.owner.player_classified.airplane_ison:value() then
        self:OpenAirPlaneHUD()
        self:Show()
        return true
    end
    --self:OnEquipSpeedometer(nil)
    self:CloseAirPlaneHUD()
    return false
end



local AirplaneHUD = Class(Widget, function(self, owner)
	self.owner = owner
    Widget._ctor(self, "AirplaneHUD")
    
    self.screensize_x, self.screensize_y=TheSim:GetScreenSize()
    self.ssx=self.screensize_x/1432.
    self.ssy=self.screensize_y/812.
    
    self.curr_pos=0
    self.closed_pos=-150
    self.open_pos=self.curr_pos
    self.delta_pos=10
    
    self.curr_pos_bg=0
    
    self.base_pos_fuel=625
    self.closed_pos_fuel=150
    self.curr_pos_fuel=self.closed_pos_fuel
    self.delta_pos_fuel=10
    self.open_pos_fuel=0
    
	

    self.bg = self:AddChild(UIAnim())
    self.bg:GetAnimState():SetBank("airplane_hud")
    self.bg:GetAnimState():SetBuild("airplane_hud")
    self.bg:GetAnimState():SetPercent("background", 0)

    --self.img = self:AddChild(Image())
    --self.img.inst.ImageWidget:SetBlendMode( BLENDMODE.Additive )

	--self:UpdateTexture()

	--self.img:SetSize(10,10,0)
--	self.bg:SetSize(500,500,0)

--	self.bg:SetTint(1,1,1,0.75)
--	self.bg:SetClickable(false)
	
    self.show_hud=false
    self.max_fuel=9000.
    self.max_sec=10

    self.fuelmeter = self.bg:AddChild(UIAnim())
    self.fuelmeter:SetScale(0.8,0.8)
    self.fuelmeter:GetAnimState():SetBank("airplane_hud")
    self.fuelmeter:GetAnimState():SetBuild("airplane_hud")
    self.fuelmeter:GetAnimState():PlayAnimation("fuelmeter",true)
    self.fuelmeter:GetAnimState():SetDeltaTimeMultiplier(0)
    self.fuelmeter:GetAnimState():SetTime(0)
    self.fuelmeter:SetPosition(265,55,0)
    
    self.fuelmeter_side = self:AddChild(UIAnim())
    self.fuelmeter_side:GetAnimState():SetBank("airplane_hud")
    self.fuelmeter_side:GetAnimState():SetBuild("airplane_hud")
    self.fuelmeter_side:GetAnimState():PlayAnimation("fuelmeter",true)
    self.fuelmeter_side:GetAnimState():SetDeltaTimeMultiplier(0)
    self.fuelmeter_side:GetAnimState():SetTime(0)
    self.fuelmeter_side:SetPosition(self.base_pos_fuel+self.curr_pos_fuel,150,0)
    
    self.controlup = self.bg:AddChild(UIAnim())
    self.controlup:SetScale(0.6,0.6)
    self.controlup:GetAnimState():SetBank("airplane_hud")
    self.controlup:GetAnimState():SetBuild("airplane_hud")
    self.controlup:GetAnimState():PlayAnimation("controlup",true)
    self.controlup:GetAnimState():SetDeltaTimeMultiplier(0)
    self.controlup:GetAnimState():SetTime(5)
    self.controlup:SetPosition(160,55,0)

    self.controlturn = self.bg:AddChild(UIAnim())
    self.controlturn:SetScale(0.55,0.55)
    self.controlturn:GetAnimState():SetBank("airplane_hud")
    self.controlturn:GetAnimState():SetBuild("airplane_hud")
    self.controlturn:GetAnimState():PlayAnimation("controlturn",true)
    self.controlturn:GetAnimState():SetDeltaTimeMultiplier(0)
    self.controlturn:GetAnimState():SetTime(5)
    self.controlturn:SetPosition(-130,-25,0)
    
    self.lamp_box = self.bg:AddChild(UIAnim())
    self.lamp_box:SetScale(0.4,0.4)
    self.lamp_box:GetAnimState():SetBank("airplane_hud")
    self.lamp_box:GetAnimState():SetBuild("airplane_hud")
    self.lamp_box:GetAnimState():PlayAnimation("lamp_box")
    self.lamp_box:SetRotation(340)
    self.lamp_box:SetPosition(-280,50,0)
    self.lamp_box_status={"lamp_green_off","lamp_orange_off","lamp_red_off"}
    self.lamp_box_default={"lamp_green_off","lamp_orange_off","lamp_red_off"}
    
    self.speedometer_bg = self.bg:AddChild(UIAnim())
    self.speedometer_bg:SetScale(0.21,0.21)
    self.speedometer_bg:GetAnimState():SetBank("airplane_hud")
    self.speedometer_bg:GetAnimState():SetBuild("airplane_hud")
    self.speedometer_bg:GetAnimState():PlayAnimation("speedometer_bg")
    self.speedometer_bg:SetPosition(40,25,0)
    
    self.speedometer_nail = self.bg:AddChild(UIAnim())
    self.speedometer_nail:SetScale(0.21,0.21)
    self.speedometer_nail:GetAnimState():SetBank("airplane_hud")
    self.speedometer_nail:GetAnimState():SetBuild("airplane_hud")
    self.speedometer_nail:GetAnimState():PlayAnimation("speedometer_nail")
    self.speedometer_nail:SetPosition(40,25,0)
    
    self.nail_rotation_rng=55
    self.nail_rotation=-self.nail_rotation_rng
    self.nail_deltarot=0
    self.nail_varrot=0
    self.speedometer_nail:SetRotation(self.nail_rotation)

    --self.fuelmeter:GetAnimState():SetPercent("fuelmeter", 0)
    
--    self.fuelmeter:SetScale(0.6,0.6,0.6)
    
    
    self.togglebutton = self:AddChild(ImageButton())
    self.togglebutton:SetScale(.7,.7,.7)
    self.togglebutton:SetText("Hide Panel")
    self.togglebutton:SetOnClick( function() self:ToggleHUD() end )
    self.togglebutton:SetPosition(-600,25,0)
    
    self.instructionsbutton = self:AddChild(ImageButton())
    self.instructionsbutton:SetScale(.7,.7,.7)
    self.instructionsbutton:SetText("Instructions")
    self.instructionsbutton:SetOnClick( function() self:ToggleInstructions() end )
    self.instructionsbutton:SetPosition(-600,70,0)
    self.ismoving_instructions=false
    self.isshown_instructions=false
    
    self.instructions = self:AddChild(UIAnim())
    self.instructions:SetScale(0.8,0.8)
    self.instructions:GetAnimState():SetBank("airplane_hud")
    self.instructions:GetAnimState():SetBuild("airplane_hud")
    self.instructions:GetAnimState():PlayAnimation("manual")
    self.instructions_closed_pos=1500
    self.instructions_open_pos=450
    self.instructions_move_delta=50
    self.instructions_curr_pos=self.instructions_closed_pos
    self.instructions:SetPosition(0,self.instructions_curr_pos,0)
    
    
    
    self.inst:ListenForEvent("airplane_ison", function(inst)
        AirplaneHUDOnOff(self)
    end, self.owner)
    
    AirplaneHUDOnOff(self)
    

end)

function AirplaneHUD:ToggleHUD()
    self.ismoving_bg=true
    self.isshown_bg= not self.isshown_bg
    if self.isshown_bg then
        self.togglebutton:SetText("Hide Panel")
    else
        self.togglebutton:SetText("Show Panel")
    end
end

function AirplaneHUD:ToggleInstructions()
    self.ismoving_instructions=true
    self.isshown_instructions= not self.isshown_instructions
end

function AirplaneHUD:GetFuel()
    self.fuel = self.owner.player_classified.airplane_fuel ~= nil
                and self.owner.player_classified.airplane_fuel:value()/self.max_fuel --*self.max_sec 
                or 0
end


function AirplaneHUD:OpenAirPlaneHUD()
    self:GetFuel()
    --self.fuelmeter:GetAnimState():SetTime(self.fuel)
    self.fuelmeter:GetAnimState():SetPercent("fuelmeter", self.fuel)
    self.show_hud=true
    self.ismoving=true
    self.ismoving_bg=false
    self.isshown_bg=true
    self.bg:SetPosition(0,self.open_pos)
    self.fuelmeter_side:SetPosition(self.base_pos_fuel+self.closed_pos_fuel,150)
    self.curr_pos_bg=0
    self.curr_pos_fuel=150
    self.fuelmeter:GetAnimState():SetTime(0)
    self.fuelmeter_side:GetAnimState():SetTime(0)
    self.controlup:GetAnimState():SetTime(5)
    self.controlturn:GetAnimState():SetTime(5)
    self:Show()
    self:StartUpdating()
end

function AirplaneHUD:CloseAirPlaneHUD()
    self.show_hud=false
    self.ismoving=true
    self.ismoving_instructions=true
    self.isshown_instructions=false
    if not self.isshown_bg then
        self.ismoving_bg=true
        self.isshown_bg=true
    end
end

function AirplaneHUD:OnUpdate(dt)
    if self.ismoving or self.ismoving_instructions then
        if self.show_hud then
            if self.curr_pos < self.open_pos then
                self.curr_pos=self.curr_pos+self.delta_pos
            end
            if self.curr_pos >= self.open_pos then
                self.curr_pos=self.open_pos
                self.ismoving=false
            end
            self:SetPosition(0,self.curr_pos)
        else
            if self.curr_pos > self.closed_pos then
                self.curr_pos=self.curr_pos-self.delta_pos
            end
            if self.curr_pos <= self.closed_pos then
                self.curr_pos=self.closed_pos
                self.ismoving=false
                self:StopUpdating()
                self:Hide()
            end
            self:SetPosition(0,self.curr_pos)
        end
    end
    
    if self.ismoving_bg then
        if self.isshown_bg then
            if self.curr_pos_bg < self.open_pos then
                self.curr_pos_bg=self.curr_pos_bg+self.delta_pos
            end
            if self.curr_pos_fuel < self.closed_pos_fuel then
                self.curr_pos_fuel=self.curr_pos_fuel+self.delta_pos_fuel
            end
            if self.curr_pos_bg >= self.open_pos then
                self.curr_pos_bg=self.open_pos
            end
            if self.curr_pos_fuel >= self.closed_pos_fuel then
                self.curr_pos_fuel=self.closed_pos_fuel
            end
            if self.curr_pos_bg==self.open_pos and self.curr_pos_fuel==self.closed_pos_fuel then
                self.ismoving_bg=false
            end
            self.bg:SetPosition(0,self.curr_pos_bg)
            self.fuelmeter_side:SetPosition(self.base_pos_fuel+self.curr_pos_fuel, 150)
            
        else
            if self.curr_pos_bg > self.closed_pos then
                self.curr_pos_bg=self.curr_pos_bg-self.delta_pos
            end
            if self.curr_pos_fuel > self.open_pos_fuel then
                self.curr_pos_fuel=self.curr_pos_fuel-self.delta_pos_fuel
            end
            if self.curr_pos_bg <= self.closed_pos then
                self.curr_pos_bg=self.closed_pos
            end
            if self.curr_pos_fuel <= self.open_pos_fuel then
                self.curr_pos_fuel=self.open_pos_fuel
            end
            if self.curr_pos_bg==self.closed_pos and self.curr_pos_fuel==self.open_pos_fuel then
                self.ismoving_bg=false
            end
            self.bg:SetPosition(0,self.curr_pos_bg)
            self.fuelmeter_side:SetPosition(self.base_pos_fuel+self.curr_pos_fuel, 150)
        end
    end
    
    if self.ismoving_instructions then
        if self.isshown_instructions then
            if self.instructions_curr_pos > self.instructions_open_pos then
                self.instructions_curr_pos=self.instructions_curr_pos-self.instructions_move_delta
            end
            if self.instructions_curr_pos <= self.instructions_open_pos then
                self.instructions_curr_pos=self.instructions_open_pos
                self.ismoving_instructions=false
            end
            self.instructions:SetPosition(0,self.instructions_curr_pos)
        else
            if self.instructions_curr_pos < self.instructions_closed_pos then
                self.instructions_curr_pos=self.instructions_curr_pos+self.instructions_move_delta
            end
            if self.instructions_curr_pos >= self.instructions_closed_pos then
                self.instructions_curr_pos=self.instructions_closed_pos
                self.ismoving_instructions=false
            end
            self.instructions:SetPosition(0,self.instructions_curr_pos)
        end
    end
    
    
    self:GetFuel()
    if self.isshown_bg then
        self.fuelmeter:GetAnimState():SetPercent("fuelmeter", self.fuel)
    else
        self.fuelmeter_side:GetAnimState():SetPercent("fuelmeter", self.fuel)
    end
    
    if TheInput ~= nil then
        local screen = TheFrontEnd:GetActiveScreen() and TheFrontEnd:GetActiveScreen().name or ""
        if screen:find("HUD") ~= nil then -- Do not use controls when chat is open
        local controlup_pos=5-self.controlup:GetAnimState():GetCurrentAnimationTime()
            if TheInput:IsControlPressed(CONTROL_ATTACK) or
               TheInput:IsControlPressed(CONTROL_CONTROLLER_ATTACK) then
                controlup_pos=controlup_pos-4.5
            end
            if TheInput:IsControlPressed(CONTROL_ACTION) or
               TheInput:IsControlPressed(CONTROL_CONTROLLER_ACTION) then
                if self.owner:GetPosition().y > 0.1 then
                    controlup_pos=controlup_pos+4.5
                end
            end
            self.controlup:GetAnimState():SetDeltaTimeMultiplier(3*controlup_pos)
            
            local controlturn_pos=5-self.controlturn:GetAnimState():GetCurrentAnimationTime()
            if TheInput:IsControlPressed(CONTROL_MOVE_RIGHT) then
                controlturn_pos=controlturn_pos+4
            end
            if TheInput:IsControlPressed(CONTROL_MOVE_LEFT) then
                controlturn_pos=controlturn_pos-4
            end
            self.controlturn:GetAnimState():SetDeltaTimeMultiplier(1.5*controlturn_pos)
        end
    end
    
    local old_lamp_box_status=self.lamp_box_status
    
    if self.owner.player_classified ~= nil then
        if self.owner.player_classified.airplane_isflying:value() then
            if self.owner.player_classified.airplane_safelanding:value() then
                if self.owner.player_classified.airplane_hardlanding:value() then
                    self.lamp_box_status={"lamp_green_off","lamp_orange_on","lamp_red_off"}
                else
                    self.lamp_box_status={"lamp_green_on","lamp_orange_off","lamp_red_off"}
                end
            else
                self.lamp_box_status={"lamp_green_off","lamp_orange_off","lamp_red_on"}
            end
        else
            self.lamp_box_status={"lamp_green_off","lamp_orange_off","lamp_red_off"}
        end
        local parspeed=self.owner.player_classified.airplane_parspeed:value()
        local perspeed=self.owner.player_classified.airplane_perspeed:value()
        local speed=math.sqrt(perspeed*perspeed+parspeed*parspeed)
        self.nail_varrot=(-self.nail_rotation_rng+2*self.nail_rotation_rng*speed/25.)-self.nail_rotation+0.2*(0.5-math.random())*speed
        self.nail_deltarot=0.95*self.nail_deltarot+0.1*self.nail_varrot
        if 0.9*self.nail_rotation+self.nail_deltarot > self.nail_rotation_rng then
            self.nail_deltarot=-0.5*self.nail_deltarot 
        end
        self.nail_rotation=0.9*self.nail_rotation+self.nail_deltarot
        self.speedometer_nail:SetRotation(self.nail_rotation)
    end
    
    for i=1,3 do
        if self.lamp_box_status[i] ~= old_lamp_box_status[i] then
            self.lamp_box:GetAnimState():OverrideSymbol(self.lamp_box_default[i],"airplane_hud",self.lamp_box_status[i])
        end
    end
end

return AirplaneHUD
