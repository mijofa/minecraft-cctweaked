-- Actual number at last calculation = 156 -- 2020-11-15
-- 240 = 2 blaze rods = 16 dark oak logs
-- NOTE: This depends heavily on the sapling placement coords, if any of that changes, reassess this number
fuel_per_run = 240

blocks_to_dig = {
    ["minecraft:dark_oak_log"] = true,
}

-- FIXME: Get all these coords from a text file
home_coords = {5495,64,-1129}
home_direction = "north"

sapling_placement_coords = {
    {5495,64,-1140},
    {5495,64,-1141},
    {5496,64,-1141},
    {5496,64,-1140},

    {5501,64,-1140},
    {5501,64,-1141},
    {5502,64,-1141},
    {5502,64,-1140},

    {5507,64,-1140},
    {5507,64,-1141},
    {5508,64,-1141},
    {5508,64,-1140},

    {5508,64,-1135},
    {5507,64,-1135},
    {5507,64,-1134},
    {5508,64,-1134},

    {5508,64,-1129},
    {5507,64,-1129},
    {5507,64,-1128},
    {5508,64,-1128},

    {5508,64,-1123},
    {5507,64,-1123},
    {5507,64,-1122},
    {5508,64,-1122},

    {5508,64,-1117},
    {5508,64,-1116},
    {5507,64,-1116},
    {5507,64,-1117},

    {5502,64,-1117},
    {5502,64,-1116},
    {5501,64,-1116},
    {5501,64,-1117},

    {5496,64,-1117},
    {5496,64,-1116},
    {5495,64,-1116},
    {5495,64,-1117},

    {5490,64,-1117},
    {5490,64,-1116},
    {5489,64,-1116},
    {5489,64,-1117},

    {5484,64,-1117},
    {5484,64,-1116},
    {5483,64,-1116},
    {5483,64,-1117},

    {5483,64,-1122},
    {5484,64,-1122},
    {5484,64,-1123},
    {5483,64,-1123},

    {5483,64,-1128},
    {5484,64,-1128},
    {5484,64,-1129},
    {5483,64,-1129},

    {5483,64,-1134},
    {5484,64,-1134},
    {5484,64,-1135},
    {5483,64,-1135},

    {5483,64,-1140},
    {5483,64,-1141},
    {5484,64,-1141},
    {5484,64,-1140},

    {5489,64,-1140},
    {5489,64,-1141},
    {5490,64,-1141},
    {5490,64,-1140},

    -- This is the first one again.
    -- The code doesn't uproot an ungrown sapling, so the worst this does is waste a bit of fuel
    {5495,64,-1140},
    {5495,64,-1141},
    {5496,64,-1141},
    {5496,64,-1140},
}


directions_enum = {
    [0] = "-x",
    [1] = "-z",
    [2] = "+x",
    [3] = "+z",
    ["-x"] = 0,
    ["-z"] = 1,
    ["+x"] = 2,
    ["+z"] = 3,
    ["north"] = 1,
    ["south"] = 3,
    ["east"] = 2,
    ["west"] = 0,
}

function get_heading()
    prev_x, prev_y, prev_z = gps.locate()
    -- FIXME: This is ugly
    -- If we can't go forward, turn once and try again until we've tried all 4 possible directions
    -- Don't bother returning heading to what it was, because I'm lazy and it shouldn't matter
    if not turtle.forward() then
        turtle.turnRight()
        if not turtle.forward() then
            turtle.turnRight()
            if not turtle.forward() then
                turtle.turnRight()
                if not turtle.forward() then
                    turtle.turnRight()
                end
            end
        end
    end
    new_x, new_y, new_z = gps.locate()
    if new_x ~= prev_x then
        if new_x > prev_x then
            facing_direction = directions_enum["+x"]
        else
            facing_direction = directions_enum["-x"]
        end
    elseif new_z ~= prev_z then
        if new_z > prev_z then
            facing_direction = directions_enum["+z"]
        else
            facing_direction = directions_enum["-z"]
        end
    end
    assert(turtle.back())  -- Return to where we started

    return facing_direction
end

facing_direction = get_heading()

-- The gps libraries give no indication of what direction we're facing, so hijack the turning functions to keep track of that
function turnLeft()
    turtle.turnLeft()
    facing_direction = ( facing_direction - 1 ) % 4
end
function turnRight()
    turtle.turnRight()
    facing_direction = ( facing_direction + 1 ) % 4
end
function turnToDirection(direction)
    if type(direction) == "string" then
        -- Also accepts the "+x" style identifiers
        direction = directions_enum[direction]
    end
    assert(direction == ( direction % 4 ))

    if direction == facing_direction then
        return
    elseif direction > facing_direction then
        turns = direction - facing_direction
        if turns == 3 then
            -- Just avoids the thing looking broken when it's turning 3 times
            turnLeft()
        else
            for i=1,turns,1 do
                turnRight()
            end
        end
    elseif direction < facing_direction then
        turns = facing_direction - direction
        if turns == 3 then
            -- Just avoids the thing looking broken when it's turning 3 times
            turnRight()
        else
            for i=1,turns,1 do
                turnLeft()
            end
        end
    end
    assert(facing_direction == direction)
end

-- The usual movement functions are a little lacking, these are just some helper wrappers
function forward_and_maybe_dig()
    status, reason = turtle.forward()
    if status then
        return status, reason
    elseif reason == "Movement obstructed" then
        io.write("Movement obstructed, ")
        inspect_status, block_detail = turtle.inspect()
        assert(inspect_status)
        if blocks_to_dig[block_detail.name] then
            print("digging")
            turtle.dig()
            sleep(2) -- take a moment to let the tree fall
            status, reason = turtle.forward()
        else
            print("stopping")
        end
    end
    return status, reason
end

function go_N_forward(n)
    print("Moving", n, "forward")
    for n=n,1,-1 do
        assert(forward_and_maybe_dig())
    end
end
function go_N_up(n)
    print("Moving", n, "upward")
    for n=n,1,-1 do
        assert(turtle.up())
    end
end
function go_N_down(n)
    print("Moving", n, "downward")
    for n=n,1,-1 do
        assert(turtle.down())
    end
end


-- Quick-and-dirty pathfinding that just assumes the path is clear
function goto_coords(x, y, z)
    -- NOTE: Minecraft is fucking stupid about it's x/y/z coords, and swaps Y & Z from what would be logical
    --       I *could* swap my variable names, but I feel that consistently stupid is likely to be less confusing than sometimes intelligent
    start_x, start_y, start_z = gps.locate()
    print("Going to:", x, y, z)
    print("    From:", start_x, start_y, start_z)

    if start_x ~= x then
        dist_x = x - start_x
        if dist_x < 0 then
            turnToDirection("-x")
            dist_x = dist_x * -1
        elseif dist_x > 0 then
            turnToDirection("+x")
        end
        go_N_forward(dist_x)
    end

    if start_z ~= z then
        dist_z = z - start_z
        if dist_z < 0 then
            turnToDirection("-z")
            dist_z = dist_z * -1
        elseif dist_z > 0 then
            turnToDirection("+z")
        end
        go_N_forward(dist_z)
    end

    if start_y ~= y then
        dist_y = y - start_y
        if dist_y < 0 then
            go_N_down(dist_y * -1)
        elseif dist_y > 0 then
            go_N_up(dist_y)
        end
    end

    end_x, end_y, end_z = gps.locate()
    assert(end_x == x)
    assert(end_y == y)
    assert(end_z == z)
    return true
end


function find_and_placedown_item(name)
    found = false
    item_detail = turtle.getItemDetail()
    if item_detail and item_detail.name == name then
        found = true
    else
        for i = 16, 1, -1 do
            turtle.select(i)
            item_detail = turtle.getItemDetail()
            if item_detail and item_detail.name == name then
                found = true
                break
            end
        end
    end
    if found then
        turtle.placeDown()
    end
    return found
end

function suckDown_all()
    -- turtle.suck() only collects one type of item at a time,
    -- This will continue sucking until it stops recieving items
    while turtle.suckDown() do
        -- pass
    end
end

function drop_all_inv()
    -- FIXME: Makes bad assumptions about the current location
    go_N_forward(1)
    turtle.down()  -- Doesn't crash if fails, this is intentional as it might be carpet

    inspect_status, block_detail = turtle.inspectDown()
    assert(inspect_status and (block_detail.name == "minecraft:hopper" or block_detail.name == "minecraft:green_carpet"))
    for i = 1, 16, 1 do
        -- Drops *everything*
        turtle.select(i)
        while turtle.getItemDetail() do turtle.dropDown() end
    end
end


function need_refuel()
    if turtle.getFuelLevel() < fuel_per_run then
        return true
    else
        return false
    end
end
function do_refuel()
    -- FIXME: Assumes blaze rods or dark oak logs
    for i = 1, 16, 1 do
        turtle.select(i)
        item_detail = turtle.getItemDetail()
        if item_detail and ( item_detail.name == "minecraft:blaze_rod" or item_detail.name == "minecraft:dark_oak_log" ) then
            turtle.refuel()
        end
    end
    assert(turtle.getFuelLevel() >= fuel_per_run, "Not enough fuel")
end


function main()
    -- Only run if we've been given all required inventory
    required_saplings = 96
    required_logs = 64
    found_saplings = 0
    found_logs = 0
    for i = 1, 16, 1 do
        turtle.select(i)
        item_detail = turtle.getItemDetail()
        if item_detail then print(item_detail.name, item_detail.count) end
        if item_detail and item_detail.name == "minecraft:dark_oak_log" then
            found_logs = found_logs + item_detail.count
        elseif item_detail and item_detail.name == "minecraft:dark_oak_sapling" then
            found_saplings = found_saplings + item_detail.count
        end
    end
    if found_logs < required_logs or found_saplings < required_saplings then
        print("not enough resources provided, storage system probably isn't ready")
        return false
    end

    if need_refuel() then
        print("Low on fuel, refueling")
        do_refuel()
    end

    -- FIXME: Confirm we have enough saplings?
    turtle.up()  -- Leave the starting bay vertically so we don't run into any redstone or storage contraptions
    for index, sapling_coords in ipairs(sapling_placement_coords) do
        -- WTF are arrays not 0-based?!?!
        x, y, z = sapling_coords[1], sapling_coords[2], sapling_coords[3]
        y = y+1  -- We want to be 1 above where the sapling is being placed
        goto_coords(x, y, z)

        suckDown_all()

        inspect_status, block_detail = turtle.inspectDown()
        if not inspect_status then
            assert(find_and_placedown_item("minecraft:dark_oak_sapling"), "Couldn't place sapling")
        else
            assert(block_detail.name == "minecraft:dark_oak_sapling", "Something is in the way of placing sapling")
        end
    end

    drop_all_inv()
    goto_coords(home_coords[1], home_coords[2], home_coords[3])
    turnToDirection(home_direction)

    return true
end

function main_loop()
    while true do
        if fs.exists("died-mid-run.lock") then
            print("WARNING: Lockfile exists, returning home")
            assert(goto_coords(home_coords[1], home_coords[2], home_coords[3]), "Couldn't get home")
            turnToDirection(home_direction)
        end

        -- Wait for midday-ish
        print("Waiting for redstone signal of 15: ")
        io.write("  ")
        repeat
            io.write(redstone.getAnalogInput("right"))
            io.write(", ")
            os.pullEvent("redstone")
        until redstone.getAnalogInput("right") == 15
        io.write("\n")

        -- Only run once every 2 days
        day_of_last_run = tonumber(fs.open("day-of-last-run", 'r').readAll())
        if os.day() >= day_of_last_run + 2 then
            fs.open("died-mid-run.lock", 'w')
            ran = main()
            fs.delete("died-mid-run.lock", 'w')

            if ran then
                f = fs.open("day-of-last-run", 'w')
                f.write(os.day())
                f.flush()
                f.close()
            end
        else
            print("Waiting another day or 2")
        end
    end
end


main_loop()
