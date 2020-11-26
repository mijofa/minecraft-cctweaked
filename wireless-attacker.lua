-- FIXME: The rednet protocol being used was written for the wireless redstone clocks on the spawner pistons
--        I'm abusing that protocol here because I want them on at the same time,
--        but I really should redesign it to be more generic

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

function attack_and_suck_forever()
    print("Starting attack and suck loop")
    repeat
        turtle.attack()
        turtle.suck()
        sleep(0)  -- To ensure any parallel functions get a bit of a turn
    until false
end

-- Set the global variables with the command recieved so it can be handled by a parallel function
sender, message, protocol = nil
function wait_for_next_command()
    sender, message, protocol = rednet.receive("wireless-switch")
    return sender, message, protocol
end

function handle_command(message)
    -- FIXME: Use cc.expect
    --        https://tweaked.cc/module/cc.expect.html
    side, cmd, arg = string.match(string.lower(message), "^([a-z]+) ([a-z0-9]+) ([a-z0-9]+)$")
    if cmd == "clock" or (cmd == "set" and arg ~= "0") then
        return(attack_and_suck_forever)
    elseif cmd == "set" and arg == "0" then
        print("Not running anything")
    else
        print("Unknown command: " .. message)
    end
end

function main_loop()
    rednet.open(find_modem())
    rednet.host("wireless-switch", hostname)
    print("Hosting wireless-switch as", hostname)
    repeat
        if message == nil then
            print("Waiting for next command")
            wait_for_next_command()
        else
            print("Running '" .. message .. "' and waiting for next command")
            parallel.waitForAny(wait_for_next_command, handle_command(message))
        end
    until message == "quit"
    rednet.unhost("wireless-switch")
end

main_loop()
