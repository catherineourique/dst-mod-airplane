local function IsValid(inst)
    return inst ~= nil and inst:IsValid() and not inst:HasTag("burnt")
end

local function IsOverWater(point)
    return not TheWorld.Map:IsVisualGroundAtPoint(point.x, point.y, point.z)
end

local Airplane = Class(function(self, inst)
    self.inst = inst
    self.aviator=nil
    self.fuel=0
    self.maxfuel=9000
    self.rotation=0
    self.fuel_consume=1
    self.fuel_rate=1
    self.unbreakable=false
    self.easy_landing=false
    self.canflyoncave=false
    self.saved_position=Vector3(0,0,0)
    self:SavePosition()
    self.gravity=5
    self.delay=0
    self.should_break=false
    self.inst:DoTaskInTime(0.1 , function(inst)
        if inst:GetPosition().y > 0.1 then
            self.inst:StartUpdatingComponent(self)
        end
    end)
end)

function Airplane:SavePosition(inst)
    if IsValid(self.aviator) then
        self.saved_position=self.aviator:GetPosition()
    else
        self.saved_position=self.inst:GetPosition()
    end
end

function Airplane:FuelDoDelta(var)
    local aux
    if var ~= nil then
        aux=self.fuel+var
    else
        aux=self.fuel-self.fuel_consume*self.fuel_rate
    end
    self.fuel=(aux > self.maxfuel and self.maxfuel) or (aux < 0 and 0) or aux
end

function Airplane:SetAviator(inst)
    if IsValid(inst) and inst.components.airplaneaviator then
        self.aviator=inst -- I'm not using "SetParent" because it makes the airplane be erased if you logout in the plane
        self.inst:AddTag("NOCLICK")
        self.inst:DoTaskInTime(0.3 , function(inst)
            inst:Hide()
        end)
        self.delay=0
        inst.Transform:SetPosition(self.inst:GetPosition():Get())
        inst.components.airplaneaviator.rotation=self.rotation 
        self:SavePosition()
        self.inst:RemoveComponent("burnable")
        self.inst:RemoveComponent("propagator")
        self.inst:StartUpdatingComponent(self)
    else
        self.aviator=nil
        self.inst.Transform:SetPosition(self.saved_position:Get())
        self.inst.Transform:SetRotation(self.rotation)
        self.inst:RemoveTag("NOCLICK")
        self.inst:Show() 
        self.delay=0
        if self.inst.components.burnable == nil then
            MakeLargeBurnable(self.inst, nil, nil, true)
        end
        if self.inst.components.propagator == nil then
            MakeLargePropagator(self.inst)
        end
        self.inst.components.burnable.burntime=6
        self.inst.components.burnable:SetOnBurntFn(self.inst._onburnt)
    end
end

function Airplane:OnSave()
    local data =
    {
        fuel = self.fuel,
        rotation = self.rotation,
    }
    return next(data) ~= nil and data or nil
end


function Airplane:OnLoad(data)
    self.fuel = data.fuel or self.fuel
    self.rotation = data.rotation or self.rotation
end


function Airplane:OnUpdate(dt) 
    if not IsValid(self.aviator) then
        self.aviator=nil
        self.inst:RemoveTag("NOCLICK")
        self.inst:Show() 
        local pos=self.inst:GetPosition()
        if pos.y > 1 and not self.should_break and not self.unbreakable  then
            self.should_break=true
        end
        self.inst.Transform:SetPosition(pos.x,pos.y-2*self.gravity*dt,pos.z)
        if pos.y < 0.1 then
            self.inst:AddComponent("activatable")
            self.inst.components.activatable.OnActivate=self.inst._onactivate
            self.inst.components.activatable.quickaction=false
            self.inst:StopUpdatingComponent(self)
            self:SetAviator(nil)
            self.inst.Transform:SetPosition(pos.x,0,pos.z)
            if not TheWorld.Map:IsVisualGroundAtPoint(pos.x, 0, pos.z) or self.should_break then
                self.inst.components.workable.onfinish(self.inst,self.inst)
            end
        end
        return
    end
    self.delay=self.delay+1
    if self.delay > 30 then -- Do not need to save the position every dt
        self.delay=0
        self:SavePosition()
        self.inst.Transform:SetPosition(self.saved_position:Get())
        self.inst.Transform:SetRotation(self.rotation)
    end

end

return Airplane
