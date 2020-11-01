-- ASSUMPTIONS:
-- Using Blaze Rod as fuel
-- Farming Dark Oak trees
-- We're already in the starting position
-- We'll never get reset in the middle of an operation
-- For each "run" we'll always recieve 1 blaze rod, 16 bone meal, & 4 saplings

function wait_for_inv_topup()
    -- There are more efficient solutions here, but this one seemed the cleanest to read
    -- source: http://www.computercraft.info/forums2/index.php?/topic/27969-how-to-give-an-ospullevent-a-timeout-and-return-nil/
    local timeout_timer = os.startTimer(2)
    -- We can only fit enough for 32 "runs" at a time,
    -- so stop once we've accepted 30 sets of items, just in case.
    -- Start the counter at 1 because we've already accepted 1 set when this function starts
    local inv_count = 1
    while true do
        event, event_info = os.pullEvent()
        if event == "timer" and event_info == timeout_timer then
            io.write(inv_count)
            io.write(" done\n")
            break
        elseif event == "turtle_inventory" then
            -- Inventory updated again, restart the timer
            io.write(".")
            timeout_timer = os.startTimer(2)
            inv_count = inv_count + 1
            if inv_count >= 30 then
                break
            end
        end
    end
end

function find_and_select_item(name, min_count)
    for i = 16, 1, -1 do
        turtle.select(i)
        item_detail = turtle.getItemDetail()
        if item_detail and item_detail.name == name then
            -- Item found!
            if min_count then
                -- But do we have enough of it?
                if item_detail.count >= min_count then
                    return i
                end
            else
                return i
            end
        end
    end
    error("Can't find item")
end

function prepare_inv(drop_down)
    local refuel_needed = turtle.getFuelLevel() < 15  -- FIXME: magic number
    local blazerods_found = 0
    local saplings_found = 0
    local bonemeal_found = 0
    print("Finding required inventory")
    for i = 1, 16, 1 do
        -- for every slot in the inventory, do...
        turtle.select(i)
        item_detail = turtle.getItemDetail()
        if not item_detail then
        else
            print(item_detail.count, "x", item_detail.name)
            if item_detail.name == "minecraft:blaze_rod" then
                blazerods_found = blazerods_found + item_detail.count
                if refuel_needed then
                    print("  refueling")
                    turtle.refuel(1)
                    refuel_needed = false
                else
                    print("  dropping")
                    if drop_down then
                        turtle.dropDown(1)
                    else
                        turtle.drop(1)
                    end
                end
            elseif item_detail.name == "minecraft:dark_oak_sapling" and item_detail.count >= 4 then
                print("  saplings")
                saplings_found = saplings_found + item_detail.count
            elseif item_detail.name == "minecraft:bone_meal" and item_detail.count >= 16 then
                print("  bone meal")
                bonemeal_found = bonemeal_found + item_detail.count
            else
                print("  dropping")
                -- NOTE: Places item in hopper in front, not just drop it
                if drop_down then
                    turtle.dropDown()
                else
                    turtle.drop()
                end
            end
        end
    end
    runs_requested = blazerods_found
    saplings_needed = 4 * runs_requested
    bonemeal_wanted = 16 * runs_requested
    if saplings_found < saplings_needed then
        -- Not an error until we actually try to plant them
        print("WARNING: Not enough saplings found")
    end
    if bonemeal_found < bonemeal_wanted then
        -- This is only a warning, as we don't always need all the bone meal.
        print("WARNING: Not enough bone meal found")
    end

    return runs_requested
end

function take_position()
    turtle.forward()
    turtle.forward()
    turtle.forward()
end

function plant_tree()
    find_and_select_item("minecraft:dark_oak_sapling", 4)
    turtle.forward()
    turtle.forward()
    turtle.turnRight()
    turtle.place()
    turtle.turnLeft()

    turtle.back()
    turtle.place()

    turtle.turnRight()
    turtle.place()
    turtle.turnLeft()

    turtle.back()
    turtle.place()
end

function apply_fertilizer()
    local unused_fertilizer = 16
    find_and_select_item("minecraft:bone_meal", 16)
    -- FIXME: These braces are ugly
    while ({turtle.inspect()})[2].name == "minecraft:dark_oak_sapling" do
        turtle.place()
        unused_fertilizer = unused_fertilizer - 1
    end
    turtle.dropDown(unused_fertilizer)
end

function suck_loop()
    -- turtle.suck() only collects one type of item at a time,
    -- This will continue sucking until it stops recieving items
    while turtle.suck() do
        -- pass
    end

end

function cut_tree_and_collect_loot()
    turtle.dig()
    suck_loop()

    turtle.forward()
    suck_loop()

    turtle.forward()
    suck_loop()

    turtle.turnRight()
    suck_loop()

    turtle.turnLeft()
    suck_loop()

    turtle.back()
    suck_loop()

    turtle.turnRight()
    suck_loop()

    turtle.turnLeft()
    suck_loop()

    turtle.back()
    suck_loop()
end

-- Main loo
while true do
    -- We need to ensure that any hoppers we drive over don't suck items out of the turtle itself.
    redstone.setOutput("bottom", true)

    print("Enabling crafter, waiting for items")
    -- Enable the crafter when we're ready to accept more items
    redstone.setOutput("back", true)
    -- This is triggered by a number of items being inserted,
    -- so wait for one inventory update, then wait until they've finished being inserted
    os.pullEvent("turtle_inventory")
    print("Recieving items")
    wait_for_inv_topup()

    -- Disable the crafter
    redstone.setOutput("back", false)
    -- Pull away from the crafter for good measure
    turtle.up()

    print("Sorting inventory")
    runs_requested = prepare_inv()
    print("Taking position")
    take_position()
    for run=1,runs_requested,1 do
        io.write("Run #")
        print(run)
        print("======")

        print("Planting saplings")
        plant_tree()
        print("Applying fertilizer")
        apply_fertilizer()
        print("Chopping tree")
        cut_tree_and_collect_loot()

        print("Sorting inventory again")
        prepare_inv(true)
    end
    print("Cleaning up")
    turtle.back()
    turtle.back()

    print("Dumping leftovers")
    redstone.setOutput("bottom", false)
    for i = 1, 16, 1 do
        turtle.select(i)
        while turtle.getItemDetail() do turtle.dropDown() end
    end
    redstone.setOutput("bottom", true)
    turtle.back()

    while turtle.suckDown() do end
    turtle.down()

    print()
end
