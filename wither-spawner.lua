fuel_per_run = 1024  -- FIXME: Guessed
wither_suffocation_seconds = 333  -- NOTE: Is actually 310, but a little extra to be sure doesn't hurt

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
        if item_detail and ( item_detail.name == "minecraft:blaze_rod" ) then
            turtle.refuel()
        end
    end
    assert(turtle.getFuelLevel() >= fuel_per_run, "Not enough fuel")
end

function find_and_place_item(name)
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
        turtle.place()
    end
    return found
end

function confirm_home_pos()
    above, above_detail = turtle.inspectUp()
    below, below_detail = turtle.inspectDown()

    return above and below and above_detail.name == "minecraft:crying_obsidian" and below_detail.name == "refinedstorage:interface"
end

function go_to_home_pos()
    -- note: this only works from the start_pos as it does not use gps at all.
    turtle.back()
    turtle.back()
    turtle.turnLeft()
    turtle.back()
    turtle.back()
end

function clear_inv(all)
    -- All argument is for when we know we're finished and don't even want to keep the extra fuel around.
    assert(confirm_home_pos)
    
    items_to_keep = {
        ["minecraft:wither_skeleton_skull"] = true,
        ["minecraft:soul_sand"] = true,
        ["minecraft:soul_soil"] = true,
        ["minecraft:blaze_rod"] = true,
    }

    for i = 16, 1, -1 do
        turtle.select(i)
        item_detail = turtle.getItemDetail()
        if item_detail and (all or not items_to_keep[item_detail.name]) then
            turtle.dropDown()
        end
    end
end

function confirm_start_pos()
    above, above_detail = turtle.inspectUp()
    below, below_detail = turtle.inspectDown()

    return above and below == false and above_detail.name == "minecraft:bedrock" and above_detail.tags["minecraft:wither_immune"]
end

function go_to_start_pos()
    -- NOTE: This only works from the home_pos as it does not use GPS at all.
    turtle.forward()
    turtle.forward()
    turtle.turnRight()
    turtle.forward()
    turtle.forward()
end

function have_needed_items()
    -- Only run if we've been given all required inventory
    required_skulls = 3
    required_soul = 4
    found_skulls = 0
    found_soul = 0
    for i = 1, 16, 1 do
        turtle.select(i)
        item_detail = turtle.getItemDetail()
        if item_detail then print(item_detail.name, item_detail.count) end
        if item_detail and item_detail.name == "minecraft:wither_skeleton_skull" then
            found_skulls = found_skulls + item_detail.count
        elseif item_detail and item_detail.name == "minecraft:soul_sand" then
            -- FIXME: Soul Soil is also suitable
            found_soul = found_soul + item_detail.count
        end
    end
    
    return found_skulls >= required_skulls and found_soul >= required_soul
end

function spawn_wither()
    -- This is vitally important, as if we start in the wrong position the wither will run off and destroy everything
    if not confirm_start_pos() then
        print("Starting position is all wrong. Can't conitnue")
        return false
    end

    if need_refuel() then
        print("Not enough fuel. Can't continue")
        return false
    end

    turtle.back()
    find_and_place_item("minecraft:soul_sand")
    -- 
    -- 
    --  #
    turtle.turnLeft()
    find_and_place_item("minecraft:soul_sand")
    -- 
    --   #
    --  #
    turtle.turnRight()
    turtle.turnRight()
    find_and_place_item("minecraft:soul_sand")
    -- 
    -- # #
    --  #
    turtle.turnLeft()
    turtle.back()
    find_and_place_item("minecraft:soul_sand")
    -- 
    -- ###
    --  #
    
    -- NOTE: Technically these heads are actually facing the wrong direction,
    --       but Minecraft doesn't care what direction they're pointing.
    turtle.turnLeft()
    find_and_place_item("minecraft:wither_skeleton_skull")
    --   *
    -- ###
    --  #
    turtle.back()
    find_and_place_item("minecraft:wither_skeleton_skull")
    --  **
    -- ###
    --  #
    turtle.back()
    find_and_place_item("minecraft:wither_skeleton_skull")
    -- ***
    -- ###
    --  #

    return true
end

function wait_with_countdown(seconds_to_wait)
    seconds_waited = 0

    _, linenum = term.getCursorPos()
    term.write("Waiting ")  -- 8 characters [1]

    while seconds_waited < seconds_to_wait do
        term.setCursorPos(9, linenum)  -- [1], +1 because they're 1-based not 0-based
        term.write(seconds_to_wait - seconds_waited)
        term.write(" seconds  ")  -- Whitespace on the end ensures the previous line is cleared even if it was longer

        sleep(1)
        seconds_waited = seconds_waited + 1
    end
    term.clearLine()
    term.setCursorPos(1, linenum)
    print("Timer done, continuing")
end

function main_loop()
    while true do
        if have_needed_items() then
            if need_refuel() then
                print("Low on fuel, refueling")
                do_refuel()
            end
    
            if confirm_home_pos() then
                -- We're only at home for the first spawn of any particular run
                go_to_start_pos()
            elseif not confirm_start_pos() then
                print("I'm lost. Can't continue")
                break
            end

            if not spawn_wither() then
                print("Spawn function crashed, not continuing")
                break
            end
    
            -- We're at home position, might as well clean up while we're here.
            clear_inv(false)

            wait_with_countdown(wither_suffocation_seconds)
    
            go_to_start_pos()
    
            turtle.suckDown()
    
            if not have_needed_items() then
                -- If we don't have the items to spawn another one, go home and clean up.
                go_to_home_pos()
                clear_inv(true)
            end
        else
            print("Got nothing to do, waiting to receive some items")
            os.pullEvent("turtle_inventory")
            print("Inventory updated, waiting a couple seconds just in case")
            sleep(2)
        end
    end
end

-- FIXME: Add some rednet status updates via the ender modem
-- NOTE: The sword is just for looks.
--       The wither destroys any turtle that's too close when taking damage
main_loop()
