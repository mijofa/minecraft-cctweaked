function main_action()
    redstone.setOutput("front", true)
    sleep(1)
    redstone.setOutput("front", false)
end
function drop_any_one_item()
    for i = 16, 1, -1 do
        turtle.select(i)
        item_detail = turtle.getItemDetail()
        if item_detail then
            -- Item found!
            turtle.dropDown(1)
            return item_detail
        end
    end
end
function inv_is_empty()
    for i = 16, 1, -1 do
        turtle.select(i)
        item_detail = turtle.getItemDetail()
        if item_detail then
            -- Item found!
            return false
        end
    end
    return true
end

while true do
    -- NOTE: This doesn't care *what* item it recieves, just that one was recieved.
    --       The crafting pattern I use is "1 Redstone Dust -> 7 Cobblestone"
    os.pullEvent("turtle_inventory")
    redstone.setOutput("left", true)
    repeat
        main_action()
        drop_any_one_item()
    until inv_is_empty()

    redstone.setOutput("left", false)
end
