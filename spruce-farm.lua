-- NOTE: While this will accept almost any sapling/logs,
--       it will only actually work for ones that grow *only* vertically.
--       This is because it doesn't have the logic to follow a tree that isn't vertical when cutting it down.
--       This means spruce & birch only
--
-- Actual number at last calculation = 80 -- 2021-05-17
-- 240 = 2 blaze rods = 16 dark oak logs
-- NOTE: This depends heavily on the sapling placement coords, if any of that changes, reassess this number
fuel_per_run = 80
required_saplings = 16

-- The usual movement functions are a little lacking, these are just some helper wrappers
function forward_and_maybe_dig()
    status, reason = turtle.forward()
    if not status and reason == "Movement obstructed" then
        io.write("Movement obstructed, ")
        inspect_status, block_detail = turtle.inspect()
        assert(inspect_status)
        if block_detail.tags and ( block_detail.tags['minecraft:leaves'] or block_detail.tags['minecraft:logs'] ) then
            print("digging")
            turtle.dig()
            status, reason = turtle.forward()
        else
            print("stopping")
        end
    end
    assert(status, "Movement still obstructed")
    return status, reason
end

-- Unlike above, these only digs leaves, and has less debugging
function up_and_maybe_dig()
    status, reason = turtle.up()
    if not status and reason == "Movement obstructed" then
        inspect_status, block_detail = turtle.inspectUp()
        assert(inspect_status)
        if block_detail.tags and block_detail.tags['minecraft:leaves'] then
            turtle.digUp()
            status, reason = turtle.up()
        end
    end
    return status, reason
end
function down_and_maybe_dig()
    status, reason = turtle.down()
    if not status and reason == "Movement obstructed" then
        inspect_status, block_detail = turtle.inspectDown()
        assert(inspect_status)
        if block_detail.tags and block_detail.tags['minecraft:leaves'] then
            turtle.digDown()
            status, reason = turtle.down()
        end
    end
    return status, reason
end

function go_N_forward(n)
    io.write("Moving", n, "forward. ")
    for n=n,1,-1 do
        assert(forward_and_maybe_dig())
    end
end
function go_N_up(n)
    print("Moving", n, "upward")
    for n=n,1,-1 do
        assert(up_and_maybe_dig())
    end
end
function go_N_down(n)
    print("Moving", n, "downward")
    for n=n,1,-1 do
        assert(down_and_maybe_dig())
    end
end


function placeDown_sapling()
    found = false
    item_detail = turtle.getItemDetail()
    -- Check the currently selected item before looping, because chances are we have just done this already anyway
    if item_detail and item_detail.name:match("_sapling$") then
        -- I hate having to do string matching here, but there's no tags on the inventory item
        found = true
    else
        for i = 16, 1, -1 do
            turtle.select(i)
            item_detail = turtle.getItemDetail()
            if item_detail and item_detail.name:match("_sapling$") then
                found = true
                break
            end
        end
    end

    inspect_status, block_detail = turtle.inspectDown()
    if inspect_status and block_detail.tags and block_detail.tags['minecraft:logs'] then
        turtle.digDown()
    end
    assert(found, "No saplings found")
    return turtle.placeDown()
end

function clear_inv()
    inspect_status, block_detail = turtle.inspectDown()
    -- This tag probably needs updating when RS gets involved.
    assert(inspect_status and block_detail.tags and ( block_detail.tags['forge:chests'] or block_detail.tags['forge:barrels'] ), "Not looking above a chest or barrel")

    found_saplings = 0
    for i = 1, 16, 1 do
        turtle.select(i)
        item_detail = turtle.getItemDetail()

        if item_detail and item_detail.name:match("_sapling$") then
            if found_saplings >= required_saplings then
                turtle.dropDown()
            else
                found_saplings = found_saplings + item_detail.count
            end
        elseif item_detail and ( item_detail.name:match("_log$") or item_detail.name == "minecraft:stick" ) then
            turtle.refuel()
            turtle.dropDown()
        else
            turtle.dropDown()
        end
    end
end


function do_refuel()
    for i = 1, 16, 1 do
        turtle.select(i)
        item_detail = turtle.getItemDetail()
        if item_detail and item_detail.name:match("_log$") then
            turtle.refuel()
        end
    end
    assert(turtle.getFuelLevel() >= fuel_per_run, "Not enough fuel")
end


function fell_whole_tree()
    count = 0
    while turtle.inspectUp() do
        turtle.digUp()
        turtle.up()
        count = count + 1
    end
    go_N_down(count)
end


function main()
    -- Only run if we've been given all required inventory
    found_saplings = 0
    for i = 1, 16, 1 do
        turtle.select(i)
        item_detail = turtle.getItemDetail()
        if item_detail then print(item_detail.name, item_detail.count) end  -- DEBUGGING

        if item_detail and item_detail.name:match("_sapling$") then
            found_saplings = found_saplings + item_detail.count
        end
    end
    if found_saplings < required_saplings then
        print("not enough resources provided, storage system probably isn't ready")
        return false
    end

    if turtle.getFuelLevel() < fuel_per_run then
        print("Low on fuel, trying to refuel")
        do_refuel()
    end

    go_N_up(1)
    go_N_forward(1)
    go_N_up(4)
    go_N_forward(2)
    turtle.turnLeft()
    go_N_forward(1)

    for column=1, 4, 1 do
        for row=1, 4, 1 do
            go_N_forward(1)  -- Should dig into the trunk
            inspect_status, block_detail = turtle.inspectDown()
            if inspect_status then
                if block_detail.tags and block_detail.tags['minecraft:saplings'] then
                    -- There's already a sapling here, ignore it and move on.
                    -- pass
                elseif block_detail.tags and block_detail.tags['minecraft:logs'] then
                    -- This tree has grown, fell the whole thing
                    fell_whole_tree()
                    assert(placeDown_sapling(), "Couldn't place sapling")
                else
                    -- I don't know how to properly raise exceptions in Lua, so yes, I'm asserting false
                    assert(false, "Something is in the way, and it isn't a log or sapling")
                end
            else
                assert(placeDown_sapling(), "Couldn't place sapling")
            end

            if row ~= 4 then
                go_N_forward(2)
            end
        end
        if column == 4 then
            -- pass
        elseif column % 2 == 0 then
            go_N_forward(1)
            turtle.turnLeft()
            go_N_forward(3)
            turtle.turnLeft()
        else
            go_N_forward(1)
            turtle.turnRight()
            go_N_forward(3)
            turtle.turnRight()
        end
    end
    go_N_forward(2)
    turtle.turnRight()
    go_N_down(3)
    go_N_forward(11)
    go_N_down(1)
    go_N_forward(1)
    go_N_down(1)

    clear_inv()
    turtle.turnRight()
    turtle.turnRight()

    return true
end

function main_loop()
    while true do
        assert(not fs.exists("died-mid-run.lock"), "Lockfile exists, can't continue")

        -- Wait for midday
        print("Waiting for mid-day...")
        os.setAlarm(12)
        alarm = os.pullEvent("alarm")

        -- But only run once every 2 days
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
