-- FIXME: Autodetect this based on where the tool is equipped
--        FIXME: There's no getEquipped function, must unequip, getItemDetail, then equip
-- If on the left, mirror all movements
-- rm farming
-- wget https://abrahall.id.au/~mike/turtle.lua farming
-- farming
mirrored = false
harvest_ages = {
    ["minecraft:carrots"] = 7,
    ["minecraft:potatoes"] = 7,
    ["minecraft:wheat"] = 7,
    ["minecraft:beetroots"] = 3,
    ["minecraft:nether_wart"] = 3,
    ["minecraft:cocoa"] = 2,

    ["silentgems:fluffy_puff_plant"] = 7,
}
seeds_harvested = {
    ["minecraft:carrots"] = "minecraft:carrot",
    ["minecraft:potatoes"] = "minecraft:potato",
    ["minecraft:wheat"] = "minecraft:wheat_seeds",
    ["minecraft:beetroots"] = "minecraft:beetroot_seeds",
    ["minecraft:nether_wart"] = "minecraft:nether_wart",
    ["minecraft:cocoa"] = "minecraft:cocoa_beans",

    ["silentgems:fluffy_puff_plant"] = "silentgems:fluffy_puff_seeds",
}

turtle.turnRight_real = turtle.turnRight
turtle.turnLeft_real = turtle.turnLeft
if mirrored then
    -- FIXME: tool usage too?
    turtle.turnRight = turtle.turnLeft_real
    turtle.turnLeft = turtle.turnRight_real
end

function find_inv_slot(requested_name)
    -- Have we already found it?
    item_detail = turtle.getItemDetail()
    if item_detail and item_detail.name == requested_name then
        return i
    end

    for i = 1, 16, 1 do
        turtle.select(i)
        item_detail = turtle.getItemDetail()
        if item_detail and item_detail.name == requested_name then
            return i
        end
    end
    -- Do it again looking for an empty slot
    for i = 1, 16, 1 do
        turtle.select(i)
        item_detail = turtle.getItemDetail()
        if not item_detail then
            return i
        end
    end
    error("Can't find item or empty slot")
end


function maybe_harvest()
    any_block, block_info = turtle.inspect()
    if any_block and block_info.state and block_info.state.age and
        block_info.state.age >= harvest_ages[block_info.name] then
            print("Harvesting")
            find_inv_slot(seeds_harvested[block_info.name])
            turtle.dig()
            find_inv_slot(seeds_harvested[block_info.name])  -- In case we didn't already have one
            turtle.place()
    else
        print("Not ready for harvest")
    end
end

function farm_3x3()
    -- NOTE: Assumes we're already at a corner

    -- First side
    turtle.forward()
    turtle.turnRight()
    maybe_harvest()
    turtle.turnLeft()
    turtle.forward()
    turtle.turnRight()
    maybe_harvest()
    turtle.turnLeft()
    turtle.forward()
    turtle.turnRight()
    maybe_harvest()
    turtle.turnLeft()

    -- Corner
    print("Turning corner")
    turtle.forward()
    turtle.turnRight()

    -- Second side
    turtle.forward()
    print("Skipping corner piece")
    -- Already harvested the corner piece
    turtle.forward()
    turtle.turnRight()
    maybe_harvest()
    turtle.turnLeft()
    turtle.forward()
    turtle.turnRight()
    maybe_harvest()
    turtle.turnLeft()

    -- Corner
    turtle.forward()
    turtle.turnRight()

    -- Third side
    turtle.forward()
    -- Already harvested the corner piece
    turtle.forward()
    turtle.turnRight()
    maybe_harvest()
    turtle.turnLeft()
    turtle.forward()
    turtle.turnRight()
    maybe_harvest()
    turtle.turnLeft()

    -- Corner
    turtle.forward()
    turtle.turnRight()

    -- Fourth side
    turtle.forward()
    -- Already harvested the corner piece
    turtle.forward()
    turtle.turnRight()
    maybe_harvest()
    turtle.turnLeft()
    turtle.forward()
    -- We're back at the start, so this corner piece is also done
    turtle.forward()
    turtle.turnRight()
end

function main()
    for square = 1, 4, 1 do
        -- Start at end of previous square
        turtle.forward()
        turtle.forward()

        farm_3x3()
        -- Back at the beginning of the square
        turtle.forward()
        turtle.forward()
        turtle.forward()
        turtle.forward()
        -- End of the square, so next loop can take it from here
    end
end

main()
