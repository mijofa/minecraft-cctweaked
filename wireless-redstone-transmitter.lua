hostname = fs.open("/etc/hostname", 'r').readLine()

function find_modem()
    -- Peripheral.find() returns the actual peripheral object,
    -- rednet.open() needs the side the peripheral is on.
    -- The peripheral object does not contain that info,
    -- so we have to fuck around iterating over all the peripherals until we find the right side.
    for _, name in ipairs(peripheral.getNames()) do
        if peripheral.getType(name) == "modem" then
            -- This will stop on the first match, but that's good enough for us.
            return name
        end
    end
    error("Couldn't find modem")
end

function wait_for_lever_update()
    cur_state = redstone.getInput("right")
    
    -- No other sides should change, but might as well do this loop anyway
    repeat
        os.pullEvent("redstone")
    until redstone.getInput("right") ~= cur_state
end

function main_loop()
    rednet.open(find_modem())
    
    while true do
        if redstone.getInput("right") then
            print("Turning on")
            rednet.broadcast("all clock 10", "wireless-switch")
        else
            print("Turning off")
            rednet.broadcast("all set 0", "wireless-switch")
        end

        wait_for_lever_update()
    end
end

main_loop()
