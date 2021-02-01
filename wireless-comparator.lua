hostname = fs.open("/etc/hostname", 'r').readLine()

COMPARATOR_SIDE = "front"

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

function server_loop()
    -- Send data every minute, unless ping is received before then
    while true do
        sender, message, protocol = nil
        sender, message, protocol = rednet.receive("wireless-comparator", 60)
        if message then
            print(message, "received from", sender)
            assert(tonumber(message) or message == "Ping!")
        end
        print("Sending update")
        rednet.broadcast(redstone.getAnalogInput(COMPARATOR_SIDE), "wireless-comparator")
    end
end
function server_main()
    rednet.broadcast(redstone.getAnalogInput(COMPARATOR_SIDE), "wireless-comparator")
    server_loop()
end




function client_wait_for_touch()
    -- Updates the info when a monitor is touched
    os.pullEvent("monitor_touch")
    print("Sending ping")
    rednet.broadcast("Ping!", "wireless-comparator")
    sleep(1)  -- To ensure the response is received before this function ends
end

function client_wait_for_message()
    sender, message, protocol = nil
    sender, message, protocol = rednet.receive("wireless-comparator")
    return sender, message, protocol
end

function client_update_bat(bat_win, message)
    bat_win.clear()
    inv_message = 15 - message
    for line=15,14,-1 do
        if line > inv_message then
            bat_win.setCursorPos(1, line)
            bat_win.setBackgroundColour(colors.red)
            bat_win.clearLine()
        end
    end
    for line=13,11,-1 do
        if line > inv_message then
            bat_win.setCursorPos(1, line)
            bat_win.setBackgroundColour(colors.orange)
            bat_win.clearLine()
        end
    end
    for line=10,1,-1 do
        if line > inv_message then
            bat_win.setCursorPos(1, line)
            bat_win.setBackgroundColour(colors.green)
            bat_win.clearLine()
        end
    end
    bat_win.setBackgroundColour(colors.black)
end

function client_loop(perc_win, bat_win)
    rednet.broadcast("Ping!", "wireless-comparator")
    while true do
        parallel.waitForAny(client_wait_for_message, client_wait_for_touch)
        print("Received", message, ", updating display")
        if message ~= nil and message ~= "Ping!" then
            perc_win.setCursorPos(1,1)
            perc_win.clear()
            perc_win.write(string.format("%.0f%% ", message / 0.15))

            client_update_bat(bat_win, message)

            if message <= 2 then
                redstone.setOutput("top", true)
            else
                redstone.setOutput("top", false)
            end
        else
            perc_win.setCursorPos(1,1)
            perc_win.clear()
            perc_win.write("??% ")

            bat_win.clear()
        end
    end
end

function client_main()
    monitor = peripheral.find("monitor")
    monitor.setTextScale(1)  -- NOTE: May be changed later, but we just want to confirm size/etc during initialisation
    x_max, y_max = monitor.getSize()
    -- 3 monitors attached vertically
    assert(x_max == 7)
    assert(y_max == 19)

    monitor.setCursorBlink(false)

    -- Draw the outline of the battery
    monitor.setBackgroundColour(colors.white)
    monitor.clear()
    monitor.setBackgroundColour(colors.black)

    -- Clear the inside of the battery
    bat_win = window.create(monitor, 2, 4, 5, 15)
    bat_win.clear()

    -- Clean up the detail of the battery outline
    monitor.setCursorPos(1, 2)
    monitor.write(" ")
    monitor.setCursorPos(7, 2)
    monitor.write(" ")

    monitor.setCursorPos(3, 3)
    monitor.write("   ")

    -- Draw the percentage number
    monitor.setCursorPos(1, 1)
    monitor.write("       ")
    perc_win = window.create(monitor, 3, 1, 4, 1)
    perc_win.setCursorPos(1, 1)
    monitor.write("???")

    client_loop(perc_win, bat_win)

--    print(os.pullEvent("monitor_touch"))
end




rednet.open(find_modem())
rednet.host("wireless-comparator", hostname)

if peripheral.find("monitor") then
    -- Server does not have a monitor attached
    client_main()
else
    server_main()
end

rednet.unhost("wireless-comparator")
