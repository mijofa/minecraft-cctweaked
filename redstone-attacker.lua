function attack_for60s()
    print("Running attack loop for 1 minute to kill the leftover mobs")
    start_time = os.clock()
    repeat
        turtle.attack()
        sleep(0)  -- To ensure any parallel functions get a bit of a turn
    until os.clock() >= (start_time + 60)
    print("Finished 1 minute loop")
end

function main()
    if redstone.getInput("back") then
        print("Mob farm is off, waiting for it to turn on")
        -- We'll just restart the loop as soon as there's *any* redstone update
        -- This if statement will run again and we'll see what happens.
        os.pullEvent("redstone")
    else
        print("Starting attack loop")
        repeat
            turtle.attack()
            sleep(0)  -- To ensure any parallel functions get a bit of a turn
        until redstone.getInput("back")

        print("Redstone switch activated")
        attack_for60s()
    end
end

while true do
    main()
end
