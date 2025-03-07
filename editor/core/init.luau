local util = require("util/main")
local kc = require("util/keycodes")
local config = require("config")

local font = Renderer.Font.load("./resources/JetBrainsMono-Regular.ttf")
local font2 = Renderer.Font.load("./resources/Raveo-Regular.otf")

local buf = File.read("./editor/core/init.luau"):gsub("\r", "")

local font_size = 20

local lines = buf:split("\n")
local cursor = {
    y = 1, --line
    x = 3, --col
    clamp_x = (function(self, n)
        self.x = math.clamp(self.x, 1, n+1)
    end),
    clamp_y = (function(self)
        self.y = math.clamp(self.y, 1, table.maxn(lines))
    end)
}

local last_written = 0
local function write_char(char)
    last_written = os.clock()
    local line = lines[cursor.y]
    lines[cursor.y] = line:sub(1, cursor.x-1) .. string.char(char) .. line:sub(cursor.x, -1)
    cursor.x += 1
    cursor:clamp_x(string.len(lines[cursor.y]))
end

local function erase_char()
    if cursor.x == 1 then
        return false
    end
    local line = lines[cursor.y]
    lines[cursor.y] = line:sub(1, cursor.x-2) .. line:sub(cursor.x, -1)
    cursor.x -= 1
    cursor:clamp_x(string.len(lines[cursor.y]))
    return true
end

App.setMainLoop(function()
    local char = Input.Keyboard.pollChar()
    if char ~= 0 then
        write_char(char)
    end

    if config.user.cursor.style == "BLOCK" then
        if (os.time() % 2) == 0 then
            Renderer.drawRect(10+(cursor.x*10), (cursor.y-1)*20, 10, 20, util:MakeColor(255,255,255,255))
        else 
            Renderer.drawRectOutline(10+(cursor.x*10), (cursor.y-1)*20, 10, 20, 1, util:MakeColor(255,255,255,255))
        end
    else 
        Renderer.drawRect(9+(cursor.x*9), (cursor.y-1)*20, 2, 20, 
            if ((os.time() % 2) == 0) or ((os.clock() - last_written) <= 0.25) then util:MakeColor(255,255,255, 255) else util:MakeColor(255,255,255, 0)
        )
    end

    local key = Input.Keyboard.pollKey()
    if key ~= 0 then
        --cursors
        if key == kc.left then
            cursor.x -= 1
            cursor:clamp_x(string.len(lines[cursor.y]))
        elseif key == kc.right then
            cursor.x += 1
            cursor:clamp_x(string.len(lines[cursor.y]))
        elseif key == kc.up then
            cursor.y -= 1
            cursor:clamp_y()
        elseif key == kc.down then
            cursor.y += 1
            cursor:clamp_y()
        elseif key == kc.backspace then
            erase_char()
        elseif key == kc.enter then
            write_char("\n")
        elseif key == kc.tab then
            write_char(string.rep(" ", 4))
        end
    end

    local width, _height = App.getWindowSize()

    for i,v in pairs(lines) do
        if v == "" then continue end
        Renderer.drawText(font, i, 2.5, font_size * i, 15, util:MakeColor(200, 200, 200, 255))
        Renderer.drawText(font, v, 20, font_size * i, font_size, util:MakeColor(255, 255, 255, 255))
    end
    
    local fps_txt = "FPS: "..App.getFPS()
    Renderer.drawText(font, "FPS: "..App.getFPS(), width - (string.len(("FPS: "..App.getFPS())) * 13), 13, 13, util:MakeColor(200, 200, 200, 255))

    return true
end)