local function IsValidTile(pos)
    return TheWorld.Map:GetTileAtPoint(pos.x,pos.y,pos.z) > 1
end

local function IsValid(inst)
    return inst ~= nil and inst:IsValid() and not inst:HasTag("burnt")
end

local function IsOverWater(point)
    return not TheWorld.Map:IsVisualGroundAtPoint(point.x, point.y, point.z)
end

local AirplaneAviator = Class(function(self, inst)
    self.inst = inst
    self:ClearVariables()
    self.inst:DoTaskInTime(0.1, function(inst)
        if inst:GetPosition().y > 0.5 then
            inst:PushEvent("attacked",{attacker=inst})
            inst:PushEvent("knockback",{knocker=inst, radius=10})
            inst.components.airplaneaviator.isonfall=true
            inst:StartUpdatingComponent(inst.components.airplaneaviator)
        end
    end)
end)

function AirplaneAviator:ClearVariables()
    self.airplane=nil
    self.speed=0
    self.parspeed=0
    self.perspeed=0
    self.speed_damping=0.02
    self.throttle=0
    self.throttle_damping=0.025
    self.throttle_max=1
    self.angle=0
    self.angle_damping=0.01
    self.angle_max=10
    self.inclination=0
    self.inclination_damping=0.05
    self.inclination_max=2
    self.braking_factor=0.15
    self.is_throttleup=0
    self.is_throttledw=0
    self.is_yokeup=0
    self.is_yokedw=0
    self.is_rudderleft=0
    self.is_rudderright=0
    self.is_braking=0
    self.rotation=0
    self.max_speed=25
    self.max_ground_speed=15
    self.gravity=5.0
    self.max_delaydropoff=60
    self.delaydropoff=self.max_delaydropoff
    self.fall_threshold=7
    self.valsound=0
    self.max_valsound=1
    self.isonfall=false
    self.isflying=false
    self.safelanding=false
    self.hardlanding=false
    self.propeller=nil
end

function AirplaneAviator:ThrottleUp()
    self.is_throttleup=1
end

function AirplaneAviator:ThrottleDown()
    self.is_throttledw=1
end

function AirplaneAviator:RudderLeft()
    self.is_rudderleft=1
end

function AirplaneAviator:RudderRight()
    self.is_rudderright=1
end

function AirplaneAviator:YokeUp()
    self.is_yokeup=1
end

function AirplaneAviator:YokeDown()
    local pos=self.inst:GetPosition()
    if pos.y < 0.1 then
        self.is_braking=1
    else
        self.is_yokedw=1
    end 
    if self.speed*self.speed < 1*1 and self.delaydropoff <= 0 and math.abs(self.throttle) < 0.2 then
        self:DropOff()
    end
end

function AirplaneAviator:SetNetInfo()
    self.inst.player_classified.airplane_isflying:set(self.isflying)
    self.inst.player_classified.airplane_parspeed:set(self.parspeed)
    self.inst.player_classified.airplane_perspeed:set(self.perspeed)
    self.inst.player_classified.airplane_rotation:set(self.rotation)
    self.inst.player_classified.airplane_safelanding:set(self.safelanding)
    self.inst.player_classified.airplane_hardlanding:set(self.hardlanding)
    if IsValid(self.airplane) then
         self.inst.player_classified.airplane_fuel:set(self.airplane.components.airplane.fuel)
    end
end




function AirplaneAviator:SetAirplane(inst)
    if not IsValid(inst) then
        return
    end
    
    if inst.components.airplane == nil then
        return
    end 

    self:ClearVariables()
    self.airplane=inst
    self.airplane.components.airplane:SetAviator(self.inst)
    self.rotation=self.airplane.components.airplane.rotation
    
    self.inst.Physics:ClearCollidesWith(COLLISION.LIMITS)

	local fx=SpawnPrefab("collapse_small")
	fx.Transform:SetPosition(self.inst:GetPosition():Get())
	
    self.inst.sg:GoToState("onairplane")
    
    if not IsValid(self.propeller) then
        self.propeller=SpawnPrefab("airplane_moving_propeller")
        self.propeller.entity:SetParent(self.inst.entity)
        self.propeller.Transform:SetPosition(-0.05,0.0,0)
        self.propeller.AnimState:SetTime(50)
    end
    
	self.inst.player_classified.airplane_ison:set(true)
    self:SetNetInfo()
    self.inst:PushEvent("airplane_inout")
	self.inst:StartUpdatingComponent(self)
	
end

function AirplaneAviator:DropOff(force_break)
    --self.inst:StopUpdatingComponent(self)
    if not self.inst.player_classified.airplane_ison:value() then
        return
    end

    
	local fx=SpawnPrefab("collapse_small")
	fx.Transform:SetPosition(self.inst:GetPosition():Get())
    
    local isoverwater=self.inst.components.drownable and self.inst.components.drownable:IsOverWater()

    self.inst.player_classified.airplane_ison:set(false)

    self.inst.Physics:Stop()
    
    if  IsValid(self.propeller) then
        self.propeller:Remove()
        self.propeller=nil
    end
    
    if self.inst.sg.currentstate.name ~="death" then
        self.inst.sg:GoToState("idle")
        if self.inst.components.drownable ~= nil and self.inst.components.drownable:ShouldDrown() then
                self.inst.sg:GoToState("sink_fast")
                self.inst:StopUpdatingComponent(self)
                self.inst.Physics:CollidesWith(COLLISION.LIMITS)
                return
        end
        if IsValid(self.inst) and ((self.speed > self.fall_threshold or force_break) and not isoverwater) then
            self.inst:PushEvent("attacked",{attacker=self.inst})
            self.inst:PushEvent("knockback",{knocker=self.inst, radius=10})
            self.airplane:DoTaskInTime(0,function(inst)
                if inst ~= nil and inst.components.workable then
                    if inst.components.airplane and not inst.components.airplane.unbreakable then
                        inst.components.workable.onfinish(inst,inst)
                    end
                end
            end)
        end
    end
    
    if IsValid(self.airplane) then
        self.airplane.components.airplane:SavePosition()
        self.airplane.components.airplane:SetAviator(nil)
        self.airplane=nil
    end    
    
    self:ClearVariables()
    self.inst.Physics:CollidesWith(COLLISION.LIMITS)
    self.inst:PushEvent("airplane_inout")

    self.inst.Physics:Stop()
    
    if self.inst:GetPosition().y >= 0.1 then
        self.isonfall=true
    else
        self.inst:StopUpdatingComponent(self)
    end
    
end


function AirplaneAviator:ChooseAnim()
    if self.isflying then
        local incpos=self.inclination*2.25+5-self.inst.AnimState:GetCurrentAnimationTime()
        self.inst.AnimState:SetDeltaTimeMultiplier(5*incpos)
    else
        self.inst.AnimState:SetTime(5)
        self.inst.AnimState:SetDeltaTimeMultiplier(0)
    end
    if IsValid(self.propeller) then
        self.propeller.Transform:SetRotation(self.rotation)
        self.propeller.AnimState:SetDeltaTimeMultiplier(50*self.throttle)
    end
end



function AirplaneAviator:MoveAirplane()
    self.inst.Transform:SetRotation(self.rotation)
	self.inst.Physics:SetMotorVel(self.parspeed, self.perspeed, 0)
end

function AirplaneAviator:OnUpdate(dt)
    self.inst.Transform:SetScale(1,1,1)
    ----- Store the player position and physics velocity
    local pos=self.inst:GetPosition()
    local velx, vely, velz=self.inst.Physics:GetVelocity()
    
    ----------------------------------------------------
    
    ----- Force-fall the player if it is stuck above the ground -----
    
    if self.isonfall then
        self.inst.Transform:SetPosition(pos.x,pos.y-2*self.gravity*dt,pos.z)
        if pos.y < 0.1 then
            self.inst:StopUpdatingComponent(self)
            self.inst.Transform:SetPosition(pos.x,0,pos.z)
            self:ClearVariables()
        end
        return
    end

    -----------------------------------------------------------------

    ----- Verify of the player had died while piloting
    ----- Verify if the airplane is valid
    ----- Verify if the player is inside the map edges
    
    if self.inst.sg.currentstate.name =="death" or self.inst:HasTag("playerghost") or
        not IsValid(self.airplane) or self.airplane.components.airplane.aviator ~= self.inst or
        not IsValidTile(pos) then
        self:DropOff()
        return
    end
    --------------------------------------------------
    
    ----- Check for tree collision, since the trees are taller than its hitbox -----
    
    if pos.y < 5 and self.isflying then
        local ent=TheSim:FindEntities(pos.x,0,pos.z,2,{"tree"})
        if #ent > 0 then
            self:DropOff()
            return
        end
    end
    --------------------------------------------------------------------------------
    
    ----- Airplane physics
    
    self.throttle=(1-self.throttle_damping)*self.throttle
    
    if (self.airplane.components.airplane.fuel > 0 or self.airplane.components.airplane.fuel_rate==0) and (self.is_throttleup > 0 or self.is_throttledw > 0) then
        self.airplane.components.airplane:FuelDoDelta()
        self.throttle=self.throttle+self.throttle_damping*self.throttle_max*(self.is_throttleup-self.is_throttledw)-self.throttle*self.is_braking*self.braking_factor
    end
    
    if self.throttle  > self.throttle_max then
        self.throttle=self.throttle_max
    end
    if self.throttle  < -self.throttle_max then
        self.throttle=-self.throttle_max
    end
    

    self.speed=(1-self.speed_damping)*self.speed+self.max_speed*self.speed_damping*self.throttle-self.speed*self.is_braking*self.braking_factor
    
    if self.speed  > self.max_ground_speed and pos.y < 0.1 then
        self.speed=self.max_ground_speed
    end
    if self.speed  > self.max_speed then
        self.speed=self.max_speed
    end
    if self.speed  < -self.max_speed/5 then
        self.speed=-self.max_speed/5
    end
    
    self.angle=(1-self.angle_damping)*self.angle+self.angle_damping*self.angle_max*(self.is_yokeup-self.is_yokedw)*self.speed
    
    if self.angle  > self.angle_max then
        self.angle=self.angle_max
    end
    if self.angle  < -self.angle_max then
        self.angle=-self.angle_max
    end
    
       
    self.parspeed=self.speed*math.cos((self.angle+10)/180*math.pi)
    self.perspeed=self.speed*math.sin((self.angle+10)/180*math.pi) 
    self.perspeed=self.perspeed-self.gravity+1 -- The "+1" is to avoid the natural game gravity

    if pos.y > 7 and self.perspeed > 0 then
        self.perspeed=self.perspeed-(pos.y-7)*3
    end
    
    local velvar=math.sqrt(velx*velx+velz*velz+1E-5)
    self.safelanding = not self.isflying or not (vely/velvar < -0.15 or velvar < 3 or math.abs(self.inclination) > 0.5) 
    self.hardlanding = self.isflying and (vely/velvar < -0.05 or velvar < 8 or math.abs(self.inclination) > 1)
    
    if self.airplane.components.airplane.easy_landing then
        self.safelanding=true
        self.hardlanding=false
    end
    
    ---------------------------------------------
    if pos.y < 0.1 and self.perspeed < 0 then

        if self.inst.components.drownable and self.inst.components.drownable:IsOverWater() then
            self:DropOff()
            return
        end
        self.perspeed=0
        
        if self.isflying and not self.safelanding then
            self:DropOff(true)
            return
        end

        self.isflying=false
    end
    ---------------------------------------------
    
    ---------------------------------------------
    if not self.isflying then
        self.rotation=self.rotation-self.speed*(self.is_rudderleft-self.is_rudderright)/20
    else
        self.inclination = (1-self.inclination_damping)*self.inclination-self.inclination_damping*self.inclination_max*(self.is_rudderleft-self.is_rudderright)
        if self.inclination  > self.inclination_max then
            self.inclination=self.inclination_max
        end
        if self.inclination  < -self.inclination_max then
            self.inclination=-self.inclination_max
        end
        self.rotation=self.rotation+self.inclination
    end
    ---------------------------------------------
  
    self.airplane.components.airplane.rotation=self.rotation

    self.is_throttleup=0
    self.is_throttledw=0
    self.is_rudderleft=0
    self.is_rudderright=0
    self.is_yokeup=0
    self.is_yokedw=0
    self.is_braking=0
    
    if self.delaydropoff > 0 then
        self.delaydropoff=self.delaydropoff-1
    end
    
    if math.abs(self.parspeed*self.parspeed - (velx*velx+velz*velz)) > 25 and self.isflying then
        self:DropOff()
        return
    end
    
    self:SetNetInfo()
    self:MoveAirplane()
    
    self.isflying=pos.y > 0.1
    
    self:ChooseAnim()
    
    ----- Sound -----
    
    self.valsound=self.valsound+self.throttle*self.throttle
    if self.valsound > self.max_valsound then
        self.valsound=0
        --self.inst.SoundEmitter:PlaySound("dontstarve/movement/bodyfall_dirt")
        --self.inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/mossling/flap")
        --self.inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/lightninggoat/jump")
        --self.inst.SoundEmitter:PlaySound("dontstarve/creatures/leif/footstep")
        self.inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/buzzard/flap")
        
    end
    
    -----------------
        
end

return AirplaneAviator
