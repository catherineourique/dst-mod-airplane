local assets =
{
    Asset("ANIM", "anim/airplane_parts.zip"),
    Asset("ATLAS", "images/inventoryimages/airplane_parts.xml"),
    Asset("IMAGE", "images/inventoryimages/airplane_parts.tex"),
}

local function MakeAirplanePart(name, anim, image, sink, stackable, tradable)
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)

        inst.AnimState:SetBank("airplane_parts")
        inst.AnimState:SetBuild("airplane_parts")
        inst.AnimState:PlayAnimation(anim)

        MakeInventoryFloatable(inst, "med", 0.1, 0.75)
        
        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        MakeSmallBurnable(inst, TUNING.MED_BURNTIME)
        MakeSmallPropagator(inst)

        MakeHauntableLaunchAndIgnite(inst)

        ---------------------

        inst:AddComponent("inspectable")

        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem:SetSinks(sink)
        inst.components.inventoryitem.atlasname = "images/inventoryimages/airplane_parts.xml"
        inst.components.inventoryitem.imagename = image
        
        if stackable then
            inst:AddComponent("stackable")
        end
        
        if tradable then
            inst:AddComponent("tradable")
        end

        return inst
    end

    return Prefab(name, fn, assets)
end

local parts={
    MakeAirplanePart("airplane_cable", "cable", "airplane_cable", false, true, false),
    MakeAirplanePart("airplane_fuel", "fuel", "airplane_fuel", false, true, true),
    MakeAirplanePart("airplane_motor", "motor", "airplane_motor", true, false, false),
    MakeAirplanePart("airplane_propeller", "propeller", "airplane_propeller", true, false, false),
    MakeAirplanePart("airplane_waxsilk", "waxsilk", "airplane_waxsilk", false, true, false),
    }
    
return unpack(parts)
