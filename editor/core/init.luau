local util = require("util/main")
if util then
    util()
end

local main = require("@core/main")
if main then 
    main()
end

local font = renderer.font.load("./resources/JetBrainsMonoNerdFont.ttf")
renderer.begin_redraw()
renderer.draw_rect(50,50,100,100,{
    red = 0,
    green = 0,
    blue = 0,
    alpha = 255
})
renderer.draw_text(font, "Hello from Luau!", 200, 220, 32, {
    red = 0,
    green = 0,
    blue = 0,
    alpha = 255
})