num_of_lines = 34
num_of_rows = 34
-- FIXME: Configurable height?
-- FIXME: Assumes it has enough fuel
-- FIXME: Doesn't care if inv is full


io.write("Need ")
io.write(num_of_lines*num_of_rows)
io.write(" items to place. That's ")
io.write((num_of_lines*num_of_rows)/64)
print("stacks")
print("I'm just assuming I have enough and running off now")

function get_next_item()
    if turtle.getItemCount() >= 1 then
        return turtle.getSelectedSlot()
    else
        for i = 1, 16, 1 do
            turtle.select(i)
            if turtle.getItemCount() >= 1 then
                return i
            end
        end
    end
    error("Ran out of items")
end

function place_next_item()
    get_next_item()
    turtle.place()
end

turtle.forward()
turtle.turnRight()
turtle.turnRight()
for line=1,num_of_lines,1 do
    io.write("Starting line #")
    print(line)
    for row=2,num_of_rows,1 do
        turtle.back()
        place_next_item()
    end
    -- Turn right on even lines, left on odd ones
    if (line ~= num_of_lines) then
        if (line % 2 == 0) then
            turtle.turnRight()
        else
            turtle.turnLeft()
        end
        turtle.back()
        place_next_item()
        if (line % 2 == 0) then
            turtle.turnRight()
        else
            turtle.turnLeft()
        end
    end
end
