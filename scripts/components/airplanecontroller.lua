local function CreateHelper()
    local inst = CreateEntity()

    if TheWorld.ismastersim then -- This is not supposed to be executed on the server
        --inst:Remove() 
        --return
    end

    --[[Non-networked entity]]
    inst.entity:SetCanSleep(false)
    inst.persists = false

    inst.entity:AddTransform()
    inst.entity:AddAnimState()

    inst:AddTag("CLASSIFIED")
    inst:AddTag("NOCLICK")
    inst:AddTag("placer")

    inst.AnimState:SetBank("winona_battery_placement")
    inst.AnimState:SetBuild("winona_battery_placement")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:SetLightOverride(1)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(1)
    inst.AnimState:SetScale(1, 1)

    return inst
end

local function CreateCloud()
    local inst = CreateEntity()

    if TheWorld.ismastersim then -- This is not supposed to be executed on the server
        --inst:Remove() 
        --return
    end

    --[[Non-networked entity]]
    inst.entity:SetCanSleep(false)
    inst.persists = false

    inst.entity:AddTransform()
    inst.entity:AddAnimState()

    inst:AddTag("CLASSIFIED")
    inst:AddTag("NOCLICK")
    inst:AddTag("placer")

    inst.AnimState:SetBank("airplane_background")
    inst.AnimState:SetBuild("airplane_background")
    inst.AnimState:PlayAnimation("idle")
--    inst.AnimState:SetLightOverride(1)
    inst.AnimState:SetMultColour(1, 1, 1, 1)
--    inst.AnimState:SetAddColour(0.2,0.2,0.2,1)
--    inst.AnimState:SetSortOrder(3)
    inst.AnimState:SetScale(50, 50)

    return inst
end

local function IsValid(inst)
    return inst ~= nil and inst:IsValid() and not inst:HasTag("burnt")
end

local AirplaneController = Class(function(self, inst)
    self.inst = inst
    self.speed=0
    self.inst:StopUpdatingComponent(self)
    self.camera_last=TheCamera:GetHeadingTarget()
    self:SaveCamera()
    self.ground_helper=nil
    self.nclouds=50
end)

function AirplaneController:TurnOn()
    self:SaveCamera()
    
    self.inst:PushEvent("airplane_ison")
    self.inst:StartUpdatingComponent(self)
    TheCamera.controllable=false
    TheCamera.headinggain=5
    TheCamera.fov=20
    TheCamera.distancetarget=30
    TheCamera.mindistpitch=1
    TheCamera.maxdistpitch=50
    TheCamera.newpitch=TheCamera.pitch
    TheCamera.perspeed=0
    TheCamera.onupdatefn = function(self, dt) self.newpitch=self.newpitch+0.1*((25-5*self.perspeed)-self.newpitch) self.pitch=self.newpitch end
    TheCamera.targetoffset=Vector3(0,3,0)
    if not IsValid(self.ground_helper) then
        self.ground_helper=CreateHelper()
        self.ground_helper.entity:SetParent(self.inst.entity)
    end
    
    self.clouds={}
    
    self.inst:DoTaskInTime(0.3,function(inst)
        for i=1,inst.components.airplanecontroller.nclouds do
            local cloud
            if not IsValid(inst.components.airplanecontroller.clouds[i]) then
                cloud=CreateCloud()
                cloud.entity:SetParent(self.inst.entity)
                table.insert(inst.components.airplanecontroller.clouds,cloud)
            end
        end
    end)
end

function AirplaneController:TurnOff()
    self:LoadCamera()
    TheCamera.controllable=true
    self.inst:PushEvent("airplane_ison")
    self.inst:StopUpdatingComponent(self)
    self.inst.Physics:SetMotorVel(0,0,0)
    self.inst.Physics:Stop()
    if IsValid(self.ground_helper) then
        self.ground_helper:Remove()
        self.ground_helper=nil
    end
    
    for i=1,self.nclouds do
        if IsValid(self.clouds[i]) then
            self.clouds[i]:Remove()
            self.clouds[i]=nil
        end
    end

end

function AirplaneController:SaveCamera()
    self.camera_last=TheCamera:GetHeadingTarget()
    self.camera_headinggain=TheCamera.headinggain
    self.camera_mindistpitch=TheCamera.mindistpitch
    self.camera_maxdistpitch=TheCamera.maxdistpitch
    self.camera_distancetarget=TheCamera.distancetarget
    self.camera_fov=TheCamera.fov
    self.camera_onupdatefn=TheCamera.onupdatefn
    self.camera_targetoffset=TheCamera.targetoffset
end

function AirplaneController:LoadCamera()
    TheCamera:SetHeadingTarget(self.camera_last)
    TheCamera.headinggain=self.camera_headinggain
    TheCamera.mindistpitch=self.camera_mindistpitch
    TheCamera.maxdistpitch=self.camera_maxdistpitch
    TheCamera.distancetarget=self.camera_distancetarget
    TheCamera.fov=self.camera_fov
    TheCamera.onupdatefn=self.camera_onupdatefn
    TheCamera.targetoffset=self.camera_targetoffset
end

function AirplaneController:OnUpdate(dt)
    if self.inst.player_classified == nil then
        return
    end
    
    local pos=self.inst:GetPosition()

	local screen = TheFrontEnd:GetActiveScreen() and TheFrontEnd:GetActiveScreen().name or ""
    if screen:find("HUD") ~= nil then -- Do not use controls when chat is open
        if TheInput:IsControlPressed(CONTROL_MOVE_UP) then
            SendModRPCToServer(MOD_RPC.airplane.ThrottleUp)
            self.inst.Physics:SetMotorVel(self.parspeed,self.perspeed,0)
        end
        if TheInput:IsControlPressed(CONTROL_MOVE_DOWN) then
            SendModRPCToServer(MOD_RPC.airplane.ThrottleDown)
        end
        if TheInput:IsControlPressed(CONTROL_MOVE_LEFT) then
            SendModRPCToServer(MOD_RPC.airplane.RudderLeft)
        end
        if TheInput:IsControlPressed(CONTROL_MOVE_RIGHT) then
            SendModRPCToServer(MOD_RPC.airplane.RudderRight)
        end
        
        if  TheInput:IsControlPressed(CONTROL_ATTACK) or
            TheInput:IsControlPressed(CONTROL_CONTROLLER_ATTACK) then
            SendModRPCToServer(MOD_RPC.airplane.YokeUp)
        end


        if  TheInput:IsControlPressed(CONTROL_ACTION) or
            TheInput:IsControlPressed(CONTROL_CONTROLLER_ACTION) then
            SendModRPCToServer(MOD_RPC.airplane.YokeDown)
        end
    end
    
    self.parspeed=self.inst.player_classified.airplane_parspeed:value()
    self.perspeed=self.inst.player_classified.airplane_perspeed:value()
    self.rotation=self.inst.player_classified.airplane_rotation:value()
    
    self.inst.Physics:SetMotorVel(self.parspeed,self.perspeed,0)
    self.inst.Transform:SetRotation(self.rotation)
    TheCamera:SetHeadingTarget(-self.rotation+180)
    TheCamera.perspeed=self.perspeed
    
    
    if IsValid(self.ground_helper) then
        self.ground_helper.Transform:SetPosition(0,-pos.y,0)
        if self.inst.player_classified.airplane_isflying:value() then
            if self.inst.player_classified.airplane_safelanding:value() then
                if self.inst.player_classified.airplane_hardlanding:value() then
                    self.ground_helper.AnimState:SetAddColour(1,0.7,0,0)
                else
                    self.ground_helper.AnimState:SetAddColour(0.0,0.5,0,0)
                end
            else
                self.ground_helper.AnimState:SetAddColour(0.5,0.0,0,0)
            end
        else
            self.ground_helper.AnimState:SetAddColour(0.3,0.3,0.3,1)
        end
    end
    
    for i=1,self.nclouds do
        if IsValid(self.clouds[i]) then
            self.clouds[i].Transform:SetPosition(math.sqrt(60+200*i),-pos.y,0)
        end
    end
end

return AirplaneController
