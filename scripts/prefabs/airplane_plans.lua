require "prefabutil"

local assets =
{
    Asset("ANIM", "anim/airplane_plans.zip"),
    Asset("ATLAS", "images/inventoryimages/airplane_parts.xml"),
    Asset("IMAGE", "images/inventoryimages/airplane_parts.tex"),
}

local prefabs =
{
    "collapse_small",
    "construction_container",
}

local function onhammered(inst, worker)
    if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then
        inst.components.burnable:Extinguish()
    end
    inst.components.lootdropper:DropLoot()
    
    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetScale(2,2,2)
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("wood")
    inst:Remove()
end

local function onhit(inst)
    if not inst:HasTag("burnt") then
        inst.AnimState:PlayAnimation("hit")
    end
end

local function onturnoff(inst)
    if not inst:HasTag("burnt") then
        inst.AnimState:PushAnimation("idle", false)
    end
end

local function onsave(inst, data)
    if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() or inst:HasTag("burnt") then
        data.burnt = true
    end
end

local function onload(inst, data)
    if data ~= nil and data.burnt then
        inst.components.burnable.onburnt(inst)
    end
end

local function onbuilt(inst)
    inst.AnimState:PlayAnimation("place")
    inst.AnimState:PushAnimation("airplane_plans")
    inst.SoundEmitter:PlaySound("dontstarve/common/winter_meter_craft")
end

local function OnConstructed(inst, doer)
    -- From Hermit Crabby house
    local concluded = true
    for i, v in ipairs(CONSTRUCTION_PLANS[inst.prefab] or {}) do
        if inst.components.constructionsite:GetMaterialCount(v.type) < v.amount then
            concluded = false
            break
        end
    end
    
    if concluded then
        local fx = SpawnPrefab("collapse_small")
        fx.Transform:SetScale(2,2,2)
        fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
        fx:SetMaterial("wood")
        local airplane=SpawnPrefab("airplane")
        airplane.Transform:SetPosition(inst.Transform:GetWorldPosition())
        inst:Remove()
    end
end

local function MoveFall(inst) -- Fake fall and sink
    local pos=inst:GetPosition()
    if pos.y < 0.1 then
        if not TheWorld.Map:IsVisualGroundAtPoint(pos.x, pos.y, pos.z) or
            TheWorld.Map:GetTileAtPoint(pos.x, pos.y, pos.z) < 1 then
                onhammered(inst,inst)
        else
            inst.Transform:SetPosition(pos.x,0,pos.z)
            inst.task:Cancel()
            return
        end
    end
    
    inst.Transform:SetPosition(pos.x,pos.y-0.66,pos.z)
--    if not TheWorld.Map:IsVisualGroundAtPoint(pos.x, pos.y, pos.z) or
--            TheWorld.Map:GetTileAtPoint(pos.x, pos.y, pos.z) < 1 then
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeHeavyObstaclePhysics(inst, .4)
    
    --pos=TheInput.overridepos v=c_spawn("airplane_plans") v.Transform:SetPosition(pos.x,pos.y+5,pos.z)

    inst.AnimState:SetBank("airplane_plans")
    inst.AnimState:SetBuild("airplane_plans")
    inst.AnimState:PlayAnimation("airplane_plans")

    inst:AddTag("structure")
    
    inst.entity:SetPristine()
    
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:ListenForEvent("onbuilt", onbuilt)

    inst:AddComponent("lootdropper")
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(1)
    inst.components.workable:SetOnFinishCallback(onhammered)
    inst.components.workable:SetOnWorkCallback(onhit)
    
    inst:AddComponent("constructionsite")
	inst.components.constructionsite:SetConstructionPrefab("construction_container")
	inst.components.constructionsite:SetOnConstructedFn(OnConstructed)

    MakeLargeBurnable(inst, nil, nil, true)
    MakeLargePropagator(inst)
    inst.components.burnable.burntime=6

    inst.OnSave = onsave 
    inst.OnLoad = onload
    
    inst.task=nil
    
    inst:DoTaskInTime(0.01, function(inst)
        local pos=inst:GetPosition()
        if inst:GetPosition().y > 0 or not TheWorld.Map:IsVisualGroundAtPoint(pos.x, pos.y, pos.z) or
            TheWorld.Map:GetTileAtPoint(pos.x, pos.y, pos.z) < 1 then
            inst.task=inst:DoPeriodicTask(FRAMES, MoveFall)
        end
    end)


    return inst
end

return Prefab("airplane_plans", fn, assets, prefabs),
    MakePlacer("airplane_plans_placer", "airplane_plans", "airplane_plans", "airplane_plans")
