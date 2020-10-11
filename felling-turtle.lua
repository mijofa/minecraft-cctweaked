-- Config options
-- FIXME: Implement some form of file locking so that when the chunk unloads we know whether we're at home or not
local confirm_start = false
-- FIXME: Scalability is completely untested
local distance_to_first_darkoak = 2
local distance_between_darkoak = 6
local digs_before_turn = 2
local turns_before_home = 3

-- Helpful wiki functions
-- ref: https://wiki.computercraft.cc/Turtle_API
function checkIfFuel()
  return turtle.refuel(0)
end

-- Custom functions
function go_N_forward(n)
    -- PROBLEM: turtle.forward() always goes *1* block forward
    -- SOLUTION: for-loops! \o/
    -- PROBLEM 2: Turtles don't automatically collect items
    -- SOLUTION: Explicitly suck() everytime we move
    for n=n,1,-1 do
        turtle.suck()
        turtle.forward()
        turtle.suck()
        turtle.suckDown()  -- I'm hoping this catches the block we're currently on
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

function replant_darkoak()
    find_and_select_item("minecraft:dark_oak_sapling", 4)
    turtle.turnRight()
    turtle.suck()
    turtle.place()
    turtle.turnLeft()
    turtle.suck()
    turtle.forward()
    turtle.suck()
    turtle.turnRight()
    turtle.suck()
    turtle.place()
    turtle.turnRight()
    turtle.suck()
    turtle.place()
    turtle.back()
    turtle.suck()
    turtle.place()
    turtle.turnRight()
    turtle.suck()
    turtle.turnRight()
    turtle.suck()
end

function cut_and_replant_darkoak()
    turtle.dig()

    -- Often the hopper minecart fails to collect from under a repeater.
    -- We're right next to most repeaters at this point right here, so collect ourselves
    turtle.turnRight()
    turtle.suck()
    turtle.turnLeft()

    go_N_forward(1)
    replant_darkoak()
end

function main_action_single()
    go_N_forward(distance_to_first_darkoak)
    cut_and_replant_darkoak()
    for x=turns_before_home, 1, -1 do
        for z=digs_before_turn, 1, -1 do
            go_N_forward(distance_between_darkoak)
            cut_and_replant_darkoak()
        end
        turtle.turnRight()
        go_N_forward(2)
        turtle.turnRight()
        go_N_forward(1)
        turtle.turnLeft()
    end
    for z=digs_before_turn, 2, -1 do
        -- Last run has 1 less tree before returning home.
        go_N_forward(distance_between_darkoak)
        cut_and_replant_darkoak()
    end
    -- Returning to home base
    go_N_forward(distance_between_darkoak)
    turtle.turnRight()
    turtle.suck()
    turtle.turnLeft()

    turtle.turnLeft()
    go_N_forward(1)
    turtle.turnRight()
    go_N_forward(2)
    turtle.turnLeft()
    go_N_forward(2)
    turtle.turnRight()
    turtle.turnRight()
end

local fuelLimit = turtle.getFuelLimit()
function clean_inv()
    -- Is actually a slightly modified version of the loop that was in the wiki
    local refuel_needed = turtle.getFuelLevel() < fuelLimit / 4
    local sapling_stacks_found = 0
    for i = 1, 16 do
        -- for every slot in the inventory, do...
        turtle.select(i)
        -- FIXME: does this efficiently avoid running checkIfFuel() if refuel_needed == false?
        if refuel_needed and checkIfFuel() then
            -- Consume the entire stack as fuel
            turtle.refuel()
        end
        item_detail = turtle.getItemDetail()

        io.write(i)
        io.write(': ')
        if not item_detail then
            io.write('\n')
        else
            io.write(item_detail.count)
            io.write('x ')
            io.write(item_detail.name)
            io.write('\n')

            if item_detail.name == "minecraft:dark_oak_log" then
                io.write("dropping down then up\n")
                turtle.dropDown()
                turtle.dropUp() -- If there's anything left in this stack, then the smelter is full
            elseif item_detail.name == "minecraft:dark_oak_sapling" then
                io.write("Dropping up if already found\n")
                if sapling_stacks_found >= 2 then
                    turtle.dropUp()
                elseif item_detail.count >= 64 then
                    -- Don't dump this stack, but ensure later found stacks get dumped
                    sapling_stacks_found = sapling_stacks_found + 1
                end
                -- NOTE: This won't dump stacks that are not full, so there might end up being a bunch of half stacks
            else
                io.write("Dropping up\n")
                turtle.dropUp()
            end
        end
    end
end

function wait_for_inv_topup()
    -- There are more efficient solutions here, but this one seemed the cleanest to read
    -- source: http://www.computercraft.info/forums2/index.php?/topic/27969-how-to-give-an-ospullevent-a-timeout-and-return-nil/
    local timeout_timer = os.startTimer(10)
    while true do
        event, event_info = os.pullEvent()
        if event == "timer" and event_info == timeout_timer then
            io.write(" Done\n")
            break
        elseif event == "turtle_inventory" then
            -- Inventory updated again, restart the timer
            io.write(".")
            timeout_timer = os.startTimer(10)
        end
    end
end

-- Setup

if confirm_start or not find_and_select_item("minecraft:dark_oak_sapling", 32) then
    io.write("\n\nNOTE: You should start me with at least 32 dark oak saplings, and a reasonable amount of fuel (or a stack of wood and I'll fuel myself)\n")
    io.write("Am I at home position facing the trees to be felled? [y/n] ")
    io.flush()
    resp = io.read()
    io.write("\n")
    if resp ~= 'y' then
        io.write("\nThen I can't continue. Go fix\n")
        return false
    end
else
    io.write("Starting without confirmation.\nI hope this is a good idea\n")
end

io.write("Continuing...\n")
clean_inv()


-- Start
while true do
    -- We need to ensure that any hoppers we drive over don't suck saplings out of the turtle itself.
    -- FIXME: Move all saplings to the last inventory slot just in case this fails?
    redstone.setOutput("bottom", true)

    if not redstone.getInput("right") then
        io.write("Waiting for redstone update")
        repeat
            os.pullEvent("redstone")
            io.write(".")
        until redstone.getInput("right")
    end

    io.write("Releasing minecart\n")
    redstone.setOutput("left", true)
    os.sleep(1)
    redstone.setOutput("left", false)

    io.write("\nClearing inventory before taking off")
    clean_inv()

    if redstone.getInput("right") then
        io.write("Off we go!\n")
        main_action_single()

        io.write("Clearing personally collected inventory, so we have space for the minecart collected inventory\n")
        clean_inv()

        io.write("Waiting for hopper/minecart to empty before releasing it\n")
        wait_for_inv_topup()

        -- NOTE: This heavily depends on the fact the minecart gets back at most 10 seconds after the turtle
        io.write("Releasing minecart again\n")
        redstone.setOutput("left", true)
        os.sleep(1)
        redstone.setOutput("left", false)

        io.write("Clearing minecart collected inventory\n")
        clean_inv()
    else
        io.write("The tree detector is not detecting anymore. Resetting\n  Perhaps someone fired an arrow at the target block.\n")
    end
end
