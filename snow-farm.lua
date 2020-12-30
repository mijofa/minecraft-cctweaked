-- FIXME: This would probably be just as efficient with a single snowman and no turning.

function wait_for_block_change()
    -- If the block isn't already snow, then the players are probably too far away for the snowmen to do their thing.
    -- So it's ok that that this has some unnecessarily long sleeps, because they likely won't be back for a long while.
    first_status, first_details = turtle.inspect()
    while true do
        loop_status, loop_details = turtle.inspect()
        if loop_status == first_status and loop_details == first_details then
            sleep(5)
        else
            break
        end
    end
end

print("SNOWBALL COLLECTION TURTLE")
print("Digs around in circles while a positive redstone input comes from the bottom")
print()

while true do
    if redstone.getInput("bottom") then
        print("Redstone active, starting dig for snow")
    else
        print("Waiting for redstone activation")
        os.pullEvent("redstone")
    end

    while redstone.getInput("bottom") do
        block_status, block_details = turtle.inspect()
        if block_status and block_details['name'] == "minecraft:snow" then
            io.write('.')
            turtle.turnRight()
            turtle.dig()
        else
            print("#")
            -- When the players go offline, the snowman mobs stop being processed.
            -- When that happens they stop placing snow, and we end up creating a dirt path instead.
            -- So now we stop and wait for them to activate again instead.
            wait_for_block_change()
            -- NOTE: We don't know what the change is yet, but the next loop should check before digging anyway.
        end
    end
    io.write("\n")
end
