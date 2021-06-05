fuel_options = {
    ["minecraft:coal"] = true,
    ["minecraft:charcoal"] = true
}

function wait_for_inv_topup()
    -- There are more efficient solutions here, but this one seemed the cleanest to read
    -- source: http://www.computercraft.info/forums2/index.php?/topic/27969-how-to-give-an-ospullevent-a-timeout-and-return-nil/
    local timeout_timer = os.startTimer(2)
    -- Just to ensure our inventory doesn't over fill, we'll stop at 64, which should be a single full stack of coal
    local inv_count = 1
    while true do
        event, event_info = os.pullEvent()
        if event == "timer" and event_info == timeout_timer then
            io.write(inv_count)
            io.write(" finished\n")
            break
        elseif event == "turtle_inventory" then
            -- Inventory updated again, restart the timer
            io.write(".")
            timeout_timer = os.startTimer(2)
            inv_count = inv_count + 1
            if inv_count >= 64 then
                io.write(" max runs of 64 reached\n")
                break
            end
        end
    end
end

function eat_1_coal()
    for i = 16, 1, -1 do
        turtle.select(i)
        item_detail = turtle.getItemDetail()
        if item_detail and fuel_options[item_detail.name] then
            -- NOTE: Since this happens at the start of *every* run, it should always succeed.
            --       Might waste some coal efficiency though as it doesn't need a full piece of coal to refuel to max.
            --       This is fine, we've got infinite charcoal anyway
            turtle.refuel(1)
            return true
        end
    end
    return false, "No more fuel to eat"
end

function next_movement()
    -- This always moves in a square, turning right every time it hits glass.
    -- So don't get fancy, the rest of the code doesn't care how we move, just that we've gone to the next spot
    status, reason = turtle.forward()
    if not status and reason == "Movement obstructed" then
        io.write("Movement obstructed, ")
        inspect_status, block_detail = turtle.inspect()
        assert(inspect_status)
        if block_detail.name == "refinedstorage:crafter" then
            print("by crafter. Job done")
            return status, "Job finished"
        else
            io.write("by ", block_detail.name, ". Turning right and trying again")
            turtle.turnRight()
            status, reason = turtle.forward()
        end
    end
    assert(status, "Movement still obstructed")
    return status, reason
end

function place_next_block()
    for i = 16, 1, -1 do
        turtle.select(i)
        item_detail = turtle.getItemDetail()
        if item_detail and not fuel_options[item_detail.name] then
            -- Anything that is not fuel should be a block to place
            return turtle.placeUp()
        end
    end
    return false, "Ran out of items to place"
end

function is_inventory_empty()
    for i = 16, 1, -1 do
        turtle.select(i)
        item_count = turtle.getItemCount()
        if item_count > 0 then
            -- We're just checking for non-zero, no point counting everything
            return false
        end
    end
    return true
end

function main()
    while eat_1_coal() do
        turtle.turnRight()  -- Turn away from the crafter

        move_status = true
        while move_status do
            move_status, move_reason = next_movement()
            if move_status then
                assert(place_next_block(), "Placing failed, I don't know what to do about this")
            end
        end
        assert(move_reason == "Job finished")

        print("Waiting 61s for Pure Daisy to do its thing, and destructors to collect the blocks")
        sleep(61)  -- The Pure Daisy takes 60s, I've added 1s to account for the destructors
        while turtle.inspectUp() do
            -- Just in case it takes longer
            io.write(".")
        end
        -- Finished a single run
    end
    assert(is_inventory_empty(), "Inventory should be empty now, it isn't")
end

function main_loop()
    inspect_status, block_detail = turtle.inspect()
    if not inspect_status and block_detail.name == "refinedstorage:crafter" then
        print("Not in correct starting position, can't continue")
        return false, "lost"
    end

    while true do
        io.write("Enabling crafter, and waiting for items.")
        redstone.setOutput("front", true)
        os.pullEvent("turtle_inventory")
        wait_for_inv_topup()

        print("Finished receiving items, disabling crafter.")
        redstone.setOutput("front", false)

        print("Starting job")
        main()
    end
end

assert(main_loop())
