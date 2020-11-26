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

function clock_handler(side, arg)
    print("Starting " .. arg .. "s interval clock on " .. side)

    interval = tonumber(arg)

    repeat
        set_side(side, true)
        sleep(0.10)  -- 2 Minecraft ticks. FIXME: Game tick or redstone tick?
        set_side(side, false)

        -- FIXME: Repeat clock commands will cause recursive instances of this function
        sender, message, protocol = rednet.receive("wireless-switch", interval)
    until message ~= nil
    return command_handler(message)
end

function command_handler(message)
    -- FIXME: Use cc.expect
    --        https://tweaked.cc/module/cc.expect.html
    side, cmd, arg = string.match(string.lower(message), "^([a-z]+) ([a-z0-9]+) ([a-z0-9]+)$")
    if cmd == "set" then
        -- NOTE: Does not support analog (yet?)
        arg = tonumber(arg)
        assert(arg == 0 or arg == 1, "Arg for 'set' command must be 0 or 1, not: " .. arg)
        set_side(side, arg == 1)
        return "Set " .. side .. " output(s) to " .. tostring(arg == 1)
    elseif cmd == "clock" then
        return(clock_handler(side, arg))
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
