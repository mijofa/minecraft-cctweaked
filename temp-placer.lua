num_of_lines = 34
num_of_rows = 34
-- FIXME: Configurable height?
-- FIXME: Assumes it has enough fuel
-- FIXME: Doesn't care if inv is full

turtle.dig()
turtle.forward()
for line=1,num_of_lines,1 do
    io.write("Starting line #")
    print(line)
    for row=2,num_of_rows,1 do
        turtle.dig()
        turtle.forward()
    end
    -- Turn right on even lines, left on odd ones
    if (line ~= num_of_lines) then
        if (line % 2 == 0) then
            turtle.turnRight()
        else
            turtle.turnLeft()
        end
        turtle.dig()
        turtle.forward()
        if (line % 2 == 0) then
            turtle.turnRight()
        else
            turtle.turnLeft()
        end
    end
end
