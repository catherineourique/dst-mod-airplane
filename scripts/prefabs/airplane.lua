local MAXBOOSTSPEED=38

require "prefabutil"

local assets =
{
    Asset("ANIM", "anim/airplane_base.zip"),
}

local propeller_assets =
{
    Asset("ANIM", "anim/airplane_propeller.zip"),
}


local prefabs =
{
}


local num_loots={["airplane_motor"]=1, ["airplane_cable"]=9, ["airplane_propeller"]=1,["airplane_waxsilk"]=8}
local loots={}
for k,v in pairs(num_loots) do
    for i=1,v do
        table.insert(loots,k)     
    end
end


local function OnBurnt(inst)
    if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then
        inst.components.burnable:Extinguish()
    end
    inst.SoundEmitter:KillSound("firesuppressor_idle")
    inst.components.lootdropper:DropLoot()
    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetScale(2,2,2)
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("wood")
    local airplane_plans=SpawnPrefab("airplane_plans")
    airplane_plans.components.burnable:Ignite()
    airplane_plans.Transform:SetPosition(inst.Transform:GetWorldPosition())
    inst:Remove()
end

----------------------

local function OnHammered(inst, worker)
    if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then
        inst.components.burnable:Extinguish()
    end
    inst.SoundEmitter:KillSound("firesuppressor_idle")
    inst.components.lootdropper:DropLoot()
    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetScale(2,2,2)
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("wood")
    local airplane_plans=SpawnPrefab("airplane_plans")
    airplane_plans.Transform:SetPosition(inst.Transform:GetWorldPosition())
    inst:Remove()
end

local function OnHit(inst, worker)
    if not inst:HasTag("burnt") then
        inst.AnimState:PlayAnimation("hit")
        -- TODO: A hit animation for it when its closed and when its open, but not now
    end
end


local function OnBuilt(inst)
    inst.SoundEmitter:PlaySound("dontstarve_DLC001/common/firesupressor_craft")
    inst.AnimState:PlayAnimation("place")
    inst.AnimState:PushAnimation("idle", true)
end

local function ItemTradeTest(inst, item)
    if item ~= nil and item.prefab=="airplane_fuel" then
        return true
    end
    return false
end

local function OnGivenItem(inst, giver, item)
    inst.components.airplane:FuelDoDelta(900)
    --giver.components.talker:Say()
end

local function OnActivate(inst,doer)
    if TheWorld:HasTag("cave") then
        if doer.components.talker ~= nil then
            doer.components.talker:Say("It is not a good idea.")
        end
        inst.components.activatable.inactive = true
        return
    end
    if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then
        if doer.components.burnable ~= nil then
            doer.components.burnable:Ignite()
        end
        inst.components.activatable.inactive = true
        return
    end
    inst:RemoveComponent("activatable")
    --inst.components.activatable.inactive=true
    if doer.components.airplaneaviator == nil then
        doer:AddComponent("airplaneaviator")
    end
    doer.components.airplaneaviator:SetAirplane(inst)
end

local function fn()
    local inst = CreateEntity()

    local minimap = inst.entity:AddMiniMapEntity()
        
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()
    inst.entity:AddPhysics()

    inst:AddTag("airplane")
    
    inst.AnimState:SetBuild("airplane_base")
    inst.AnimState:SetBank("airplane_base")
    inst.Transform:SetFourFaced()
    inst.AnimState:PlayAnimation("airplane_base")


    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:ListenForEvent("onbuilt", OnBuilt)
    
    inst:AddComponent("inspectable")
    
    inst:AddComponent("airplane")
    
    inst:AddComponent("trader")
    inst.components.trader:SetAbleToAcceptTest(ItemTradeTest)
    inst.components.trader.onaccept = OnGivenItem

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetLoot(loots)
    
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(1)
    inst.components.workable:SetOnFinishCallback(OnHammered)
    inst.components.workable:SetOnWorkCallback(OnHit)
    
    
    inst:AddComponent("activatable")
    
    inst._onactivate=OnActivate
    inst.components.activatable.OnActivate=inst._onactivate
    inst.components.activatable.quickaction=false

    inst._onburnt=OnBurnt
    MakeLargeBurnable(inst, nil, nil, true)
    MakeLargePropagator(inst)
    inst.components.burnable.burntime=6
    inst.components.burnable:SetOnBurntFn(inst._onburnt)
    
    return inst
end

local function propeller_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst:AddTag("NOCLICK")
    inst:AddTag("DECOR")
    
    inst.AnimState:SetBuild("airplane_propeller")
    inst.AnimState:SetBank("airplane_propeller")
    inst.Transform:SetFourFaced()
    inst.AnimState:PlayAnimation("propeller",true)
    inst.AnimState:SetDeltaTimeMultiplier(0)


    inst.entity:SetPristine()
    
    return inst
end

return Prefab("airplane",fn, assets,prefabs),
        Prefab("airplane_moving_propeller",propeller_fn, propeller_assets,prefabs)


