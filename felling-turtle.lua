-- Config options
-- FIXME: Implement some form of file locking so that when the chunk unloads we know whether we're at home or not
local confirm_start = false
-- FIXME: Scalability is completely untested
local distance_to_first_darkoak = 2
local distance_between_darkoak = 6
local digs_before_turn = 1
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
    for i = 1, 16 do
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
    local clear_saplings = false
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
                if clear_saplings then
                    turtle.dropUp()
                elseif item_detail.count >= 64 then
                    -- Don't dump this stack, but ensure later found stacks get dumped
                    clear_saplings = true
                end
            else
                io.write("Dropping up\n")
                turtle.dropUp()
            end
        end
    end
end

-- Setup

if confirm_start then
    io.write("\n\nNOTE: You should start me with at least 16 darl oak saplings, and a reasonable amount of fuel (or a stack of wood and I'll fuel myself)\n")
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
    if not redstone.getInput("right") then
        io.write("Waiting for redstone update")
        repeat
            os.pullEvent("redstone")
            io.write(".")
        until redstone.getInput("right")
    end

    io.write("\nClearing inventory before taking off")
    clean_inv()

    io.write("Releasing minecart\n")
    redstone.setOutput("left", true)
    os.sleep(1)
    redstone.setOutput("left", false)

    io.write("Off we go!\n")
    main_action_single()

    io.write("Releasing minecart again, maybe\n")
    redstone.setOutput("left", true)
    os.sleep(5)
    redstone.setOutput("left", false)

    io.write("Clearning personally collected inventory, so we have space for the minecart collected inventory\n")
    clean_inv()
end
