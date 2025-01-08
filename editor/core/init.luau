local util = require("util/main")
local kc = require("util/keycodes")

local font = Renderer.Font.load("./resources/JetBrainsMono-Regular.ttf")

local buf = File.read("./editor/init.luau"):gsub("\r", "")

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

    Renderer.drawText(font, buf, 20, 20, 32, util:MakeColor(0, 0, 0, 255))
    Renderer.drawText(font, "fps: "..App.getFPS(), width - 108, 20, 12, util:MakeColor(0, 0, 0, 255))

    local mouse_x, mouse_y = Input.Mouse.getPosition();
    Renderer.drawText(font, "mouse_x: "..mouse_x.."\nmouse_y: "..mouse_y, 20, height - 80, 30, util:MakeColor(0,0,0,255))

    return true
end)