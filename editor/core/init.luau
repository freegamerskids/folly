local util = require("util/main")
local kc = require("util/keycodes")

local font = Renderer.Font.load("./resources/JetBrainsMono-Regular.ttf")

local buf = File.read("./editor/core/init.luau"):gsub("\r", "")

local renderedOnce = false

App.setMainLoop(function()
    local char = Input.Keyboard.pollChar()
    if char ~= 0 then
        buf ..= string.char(char)
    end

    local key = Input.Keyboard.pollKey()
    if key ~= 0 then
        if key == kc.backspace then
            buf = buf:sub(1,-2)
        elseif key == kc.enter then
            buf ..= "\n"
        elseif key == kc.tab then
            buf ..= string.rep(" ", 4)
        end
    end

    local width, height = App.getWindowSize()

    --for i,v in pairs(buf:split("\n")) do
   --     if v == "" then v = " " end
    --    Renderer.drawText(font, v, 20, 20*i, 20*20, util:MakeColor(255, 255, 255, 255))
    --end
    
    --Renderer.drawText(font, "fps: "..App.getFPS(), width - 200, 60, 20*20, util:MakeColor(255, 255, 255, 255))

    --local mouse_x, mouse_y = Input.Mouse.getPosition();
    --Renderer.drawText(font, "mouse_x: "..mouse_x.."\nmouse_y: "..mouse_y, 20, height - 80, 20*20, util:MakeColor(255,255,255,255))

    if not renderedOnce then
        Renderer.drawText(font, "Hello World, width: "..width.." height: "..height, 200, 200, 20, util:MakeColor(255, 255, 255, 255))
        renderedOnce = true
        return true
    end

    return false
end)