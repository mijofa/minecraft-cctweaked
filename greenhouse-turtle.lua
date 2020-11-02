-- rm farming
-- wget https://abrahall.id.au/~mike/turtle.lua farming
-- farming

-- FIXME: Autodetect mirroring based on where the tool is equipped
--        FIXME: There's no getEquipped function, must unequip, getItemDetail, then equip
-- I tried to do a whole primary/secondary direction thing rather than left/right, but it made the code impossible to follow.
-- Diretly mirroring left/right is much easier to work with, if a little less sensible
mirrored = true

-- Actual number at last calculation = 462 -- 2020-11-02
-- 480 = 4 blaze rods
fuel_per_run = 480

harvest_ages = {
    -- Use 'true' for always
    ["minecraft:carrots"] = 7,
    ["minecraft:potatoes"] = 7,
    ["minecraft:wheat"] = 7,
    ["minecraft:beetroots"] = 3,
    ["minecraft:nether_wart"] = 3,
    ["minecraft:cocoa"] = 2,

    ["minecraft:sugar_cane"] = 0,
    ["minecraft:cactus"] = 0,
    ["minecraft:melon"] = true,
    ["minecraft:pumpkin"] = true,

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


function maybe_harvest(downwards)
    -- Normally we harvest forwards, but sugarcane & cactus require special treatment, hence downwards
    -- FIXME: Ignoring place(). because we never have to do that downwards
    if downwards then
        inspect = turtle.inspectDown
        dig = turtle.digDown
        suck = turtle.suckDown
    else
        inspect = turtle.inspect
        dig = turtle.dig
        suck = turtle.suck
    end

    any_block, block_info = inspect()
    if (any_block and harvest_ages[block_info.name]) and (
        ( block_info.state and block_info.state.age and block_info.state.age >= harvest_ages[block_info.name] ) or
        ( harvest_ages[block_info.name] == true ) ) then
            -- Avoid filling inv by selecting seeds before collecting seeds
            if seeds_harvested[block_info.name] then find_inv_slot(seeds_harvested[block_info.name]) end
            dig()
            if seeds_harvested[block_info.name] then
                -- Select seeds "again" in case we didn't actually have any before
                find_inv_slot(seeds_harvested[block_info.name])
                turtle.place()
            end
    end
    suck()
end

function take_position()
    turtle.forward()
    turtle.turnLeft()
    turtle.forward()
    turtle.turnRight()
    turtle.forward()
    turtle.forward()
    turtle.forward()
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
    turtle.forward()
    turtle.turnRight()

    -- Second side
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

function farm_4_3x3s()
    for square = 1, 4, 1 do
        -- starts at end of previous square
        if square ~= 1 then
            turtle.forward()
            turtle.forward()
        end
        farm_3x3() -- ends where it starts
        turtle.forward()
        turtle.forward()
        turtle.forward()
        turtle.forward()
        -- end of the square, so next loop can take it from here
    end
end

function farm_6x1()
    for i = 1, 6, 1 do
        maybe_harvest()
        turtle.turnLeft()
        turtle.forward()
        turtle.turnRight()
    end
end

function farm_sugarcane_or_cacti()
    -- We can be sneaky with this one and just not harvest the bottom piece
    for i = 1, 13, 1 do
        -- We have to go top-down, because we don't catch the parts that drop
        -- We have to approach from above as well, because cactus falls apart as we approach
        maybe_harvest(true)
        turtle.down()
        maybe_harvest(true)
        turtle.up()
        turtle.forward()
        if i ~= 13 then
            turtle.forward()
        else
            turtle.turnLeft()
            turtle.down()
            turtle.forward()
            turtle.down()
        end
    end
end

function farm_melon_or_pumpkin()
    for i = 1, 5, 1 do
        if (i % 2 == 0) then
            maybe_harvest()
            turtle.turnLeft()
            maybe_harvest()
            turtle.forward()
            turtle.forward()
            turtle.turnRight()
            maybe_harvest()
            turtle.forward()
            turtle.forward()
            turtle.turnRight()
            maybe_harvest()
            turtle.turnLeft()
        else
            maybe_harvest()
            turtle.turnRight()
            maybe_harvest()
            turtle.forward()
            turtle.forward()
            turtle.turnLeft()
            maybe_harvest()
            turtle.forward()
            turtle.forward()
            turtle.turnLeft()
            maybe_harvest()
            turtle.turnRight()
        end

        if i ~= 5 then
            turtle.forward()
            turtle.forward()
            turtle.forward()
        end
    end
end

function farm_cocoa()
    for i = 1, 4, 1 do
        if (i % 2 == 0) then
            maybe_harvest()
            turtle.up()
            maybe_harvest()
        else
            maybe_harvest()
            turtle.down()
            maybe_harvest()
        end
        turtle.turnRight()
        turtle.forward()
        turtle.turnLeft()
    end
end

function return_home()
    turtle.turnLeft()
    turtle.forward()
    turtle.forward()
    turtle.forward()
    for i = 1, 9, 1 do
        turtle.down()
    end
    for i = 1, 11, 1 do
        turtle.forward()
    end
    turtle.turnLeft()
    for i = 1, 22, 1 do
        turtle.forward()
    end

    turtle.forward()
    turtle.forward()
    turtle.forward()
    turtle.turnLeft()
    turtle.forward()
    turtle.turnRight()
    turtle.forward()
    turtle.turnRight()
    turtle.turnRight()
end

function main()
    print(turtle.getFuelLevel())
    if turtle.getFuelLevel() < 100 then
        return "No can do, not enough fuel"
    end
    take_position()

    farm_4_3x3s()
    turtle.turnRight()
    turtle.forward()
    turtle.forward()
    turtle.forward()
    turtle.forward()
    -- Next corner

    turtle.forward()
    turtle.forward()
    turtle.forward()

    -- Start of next line
    turtle.forward()
    turtle.forward()
    turtle.forward()
    turtle.forward()
    turtle.turnRight()
    farm_4_3x3s()


    -- Finished lines, go to Nether wart
    turtle.forward()
    turtle.forward()
    turtle.forward()
    turtle.turnRight()
    turtle.forward()
    turtle.forward()
    turtle.turnLeft()

    farm_6x1()

    -- Go to sugarcane
    turtle.turnLeft()
    turtle.up()
    turtle.up()
    turtle.forward()
    turtle.forward()
    turtle.forward()
    turtle.turnLeft()

    farm_sugarcane_or_cacti()

    -- Finished sugarcane, next up, watermelon
    turtle.forward()
    turtle.down()
    turtle.turnLeft()
    farm_melon_or_pumpkin()

    -- Go to upper level
    turtle.turnRight()
    turtle.up()
    turtle.forward()
    turtle.forward()
    turtle.forward()
    turtle.turnLeft() turtle.turnLeft() -- Turn around
    for i = 1, 9, 1 do
        turtle.up()
    end
    -- Go to cocoa beans
    for i = 1, 8, 1 do
        turtle.forward()
    end
    turtle.turnRight()
    turtle.forward()
    turtle.forward()

    farm_cocoa()

    -- Go to 3x3s
    turtle.turnRight()
    turtle.forward()
    turtle.turnRight()
    turtle.forward()
    turtle.forward()

    farm_4_3x3s()

    return_home()

    print(turtle.getFuelLevel())
end

main()
