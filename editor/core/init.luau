
local font = Renderer.Font.load("./resources/JetBrainsMonoNerdFont.ttf")

function makeColor(r: number, g: number, b: number, a: number)
    return {
        red = r,
        green = g,
        blue = b,
        alpha = a
    }
end

Renderer.drawRect(50,50,100,100,makeColor(0, 0, 0, 255))
Renderer.drawText(font, "Hello from Luau!", 200, 220, 32, makeColor(0, 0, 0, 255))
Renderer.endRedraw()

print(os.clock())

local buf = ""

App.setMainLoop(function()
    local char = Keyboard.pollChar()
    if char ~= 0 then
        buf ..= string.char(char)
    end

    Renderer.drawText(font, buf, 200, 200, 32, makeColor(0, 0, 0, 255))
    Renderer.drawText(font, "fps: "..Renderer.getFPS(), 300, 100, 32, makeColor(0, 0, 0, 255))

    return true
end);