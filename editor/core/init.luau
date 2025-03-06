local util = require("util/main")
local kc = require("util/keycodes")

local font = Renderer.Font.load("./resources/JetBrainsMono-Regular.ttf")
local font2 = Renderer.Font.load("./resources/Raveo-Regular.otf")

local buf = File.read("./editor/core/init.luau"):gsub("\r", "")

local font_size = 20

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

    local width, _height = App.getWindowSize()

    for i,v in pairs(buf:split("\n")) do
        if v == "" then continue end
        Renderer.drawText(font, v, 20, font_size * i, font_size, util:MakeColor(255, 255, 255, 255))
    end
    
    Renderer.drawText(font2, "fps: "..App.getFPS(), width - 200, 60, 20, util:MakeColor(255, 255, 255, 255))

    return true
end)