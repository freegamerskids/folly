local util = require("util/main")
local kc = require("util/keycodes")
local config = require("config")

local font = Renderer.Font.load("./resources/JetBrainsMono-Regular.ttf")
local font2 = Renderer.Font.load("./resources/Raveo-Regular.otf")

local buf = File.read("./editor/core/init.luau"):gsub("\r", "")

local font_size = 20

local lines = buf:split("\n")
local cursor = {
    touch_time = 0,
    touched = (function(self) 
        return ((os.clock() - self.touch_time) <= 0.25) 
    end),

    y = 1, --line
    x = 3, --col
    go_to = (function(self, x, y) 
        if x ~= nil then
            self.x = x
            self:clamp_x(x)
        end
        if y ~= nil then
            self.y = y
            self:clamp_y()
        end
    end),
    clamp_x = (function(self, n)
        self.x = math.clamp(self.x, 1, n+1)
    end),
    clamp_y = (function(self)
        self.y = math.clamp(self.y, 1, table.maxn(lines))
    end),
    touch = (function(self) 
        self.touch_time = os.clock()
    end),

    write = (function(self, char)
        self:touch()
        local line = lines[self.y]
        lines[self.y] = line:sub(1, self.x-1) .. string.char(char) .. line:sub(self.x, -1)
        self.x += 1
        self:clamp_x(string.len(lines[self.y]))
    end),
    erase = (function(self)
        self:touch()
        if self.x == 1 then
            return false
        end
        local line = lines[self.y]
        lines[self.y] = line:sub(1, self.x-2) .. line:sub(self.x, -1)
        self.x -= 1
        self:clamp_x(string.len(lines[self.y]))
        return true
    end)
}

local res = fetch("http://echo.free.beeceptor.com/", {
    method = "POST",
    headers = {
        ["Content-Type"] = "application/json",
        ["Accept"] = "application/json",
        ["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    },
    body = JSON.stringify({
        name = "John",
        age = 30,
        city = "New York",
        is_admin = true,
    })
})

for k,v in pairs(res) do
    if k == "headers" then
        for k2,v2 in pairs(v) do
            print("header:", k2, v2)
        end
    else
        print(k, v)
    end
end

local last_cursor_pos_time = os.clock()

App.setMainLoop(function()
    local char = Input.Keyboard.pollChar()
    while char ~= 0 do
        cursor:touch()
        cursor:write(char)
        char = Input.Keyboard.pollChar()
    end

    if config.user.cursor.style == "BLOCK" then
        if (os.time() % 2) == 0 then
            Renderer.drawRect(10+(cursor.x*10), (cursor.y-1)*20, 10, 20, util:MakeColor(255,255,255,255))
        else 
            Renderer.drawRectOutline(10+(cursor.x*10), (cursor.y-1)*20, 10, 20, 1, util:MakeColor(255,255,255,255))
        end
    else 
        Renderer.drawRect((cursor.x+2)*9-3, (cursor.y-1)*20+5, 2, 20, 
            if ((os.time() % 2) == 0) or cursor:touched() then util:MakeColor(255,255,255, 255) else util:MakeColor(255,255,255, 0)
        )
    end

    -- TODO: add a pause before enabling rapid fire
    if os.clock() - last_cursor_pos_time > 1/30 then
        last_cursor_pos_time = os.clock()

        if Input.Keyboard.isKeyDown(kc.left) then
            cursor:touch()
            cursor:go_to(cursor.x-1, nil)
        elseif Input.Keyboard.isKeyDown(kc.right) then
            cursor:touch()
            cursor:go_to(cursor.x+1, nil)

        elseif Input.Keyboard.isKeyDown(kc.up) then
            cursor:touch()
            cursor:go_to(nil, cursor.y-1)
        elseif Input.Keyboard.isKeyDown(kc.down) then
            cursor:touch()
            cursor:go_to(nil, cursor.y+1)

        elseif Input.Keyboard.isKeyDown(kc.backspace) then
            cursor:erase()
        elseif Input.Keyboard.isKeyDown(kc.enter) then
            cursor:write("\n")
        elseif Input.Keyboard.isKeyDown(kc.tab) then
            cursor:write(string.rep(" ", 4))
        end
    end

    local width, _height = App.getWindowSize()

    for i,v in pairs(lines) do
        if v == "" then 
            Renderer.drawText(font, i, 5, (font_size * i) - ((font_size - 15)/4), 15, util:MakeColor(110, 110, 110, 255))
            continue 
        end
        Renderer.drawText(font, i, 5, (font_size * i) - ((font_size - 15)/4), 15, util:MakeColor(200, 200, 200, 255))
        Renderer.drawText(font, v, 25, font_size * i, font_size, util:MakeColor(255, 255, 255, 255))
    end
    
    local fps_size = 13
    local fps_txt = "FPS: "..App.getFPS()
    local fps_w, fps_h = Renderer.measureText(font2, fps_txt, 13)

    local fps_pos_x = width - 5 - fps_w

    Renderer.drawText(font2, "FPS: "..App.getFPS(), fps_pos_x - 5, fps_size + 5, fps_size, util:MakeColor(200, 200, 200, 255))
    Renderer.drawRectOutline(fps_pos_x - 10, 5, fps_w + 10, fps_h + 5, 1, util:MakeColor(255, 0, 0, 255))

    return true
end)