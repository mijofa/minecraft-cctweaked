-- The main reason this is a separate script is because this one needs to invert the state compared to the other devices.
-- Lights on = spawners off

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

function set_side(side, state)
    if side == "all" then
        for _, side in ipairs(redstone.getSides()) do
            redstone.setOutput(side, state)
        end
    else
        redstone.setOutput(side, state)
    end
end

function command_handler(message)
    -- FIXME: Use cc.expect
    --        https://tweaked.cc/module/cc.expect.html
    side, cmd, arg = string.match(string.lower(message), "^([a-z]+) ([a-z0-9]+) ([a-z0-9]+)$")
    if cmd == "set" then
        -- NOTE: Does not support analog (yet?)
        arg = tonumber(arg)
        assert(arg == 0 or arg == 1, "Arg for 'set' command must be 0 or 1, not: " .. arg)
        -- NOTE: Intentionally inverts arg here
        set_side(side, arg == 0)
        return "Set " .. side .. " output(s) to " .. tostring(arg == 0)
    elseif cmd == "clock" then
        -- Doesn't need or support clock mode, simply turns off the floodlights instead
        set_side(side, false)
    else
        return "Unknown command: " .. message
    end
end

function main_loop()
    rednet.open(find_modem())
    rednet.host("wireless-switch", hostname)
    print("Hosting wireless-switch as", hostname)
    repeat
        sender, message, protocol = rednet.receive("wireless-switch")
        print(command_handler(message))
    until message == "quit"
    rednet.unhost("wireless-switch")
end

main_loop()
