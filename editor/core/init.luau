local util = require("util/main")
local kc = require("util/keycodes")

local font = Renderer.Font.load("./resources/JetBrainsMono-Regular.ttf")

local buf = ""

App.setMainLoop(function()
    local char = Keyboard.pollChar()
    if char ~= 0 then
        buf ..= string.char(char)
    end

    local key = Keyboard.pollKey()
    if key ~= 0 then
        if key == kc.backspace then
            buf = buf:sub(1,-2)
        elseif key == kc.enter then
            buf ..= "\n"
        elseif key == kc.tab then
            buf ..= string.rep(" ", 4)
        end
    end

    Renderer.drawText(font, buf, 20, 20, 32, util:MakeColor(0, 0, 0, 255))
    Renderer.drawText(font, "fps: "..App.getFPS(), App.getScreenWidth() - 108, 20, 12, util:MakeColor(0, 0, 0, 255))

    return true
end)