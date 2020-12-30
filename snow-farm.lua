while true do
    if redstone.getInput("bottom") then
        print("Redstone active")
    else
        print("Waiting for redstone activation")
        os.pullEvent("redstone")
    end

    while redstone.getInput("bottom") do
        io.write('.')
        turtle.turnRight()
        turtle.dig()
    end
    io.write("\n")
end
