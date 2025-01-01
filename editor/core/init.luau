
local font = Renderer.Font.load("./resources/JetBrainsMonoNerdFont.ttf")

function makeColor(r: number, g: number, b: number, a: number)
    return {
        red = r,
        green = g,
        blue = b,
        alpha = a
    }
end

Renderer.beginRedraw()
Renderer.drawRect(50,50,100,100,makeColor(0, 0, 0, 255))
Renderer.drawText(font, "Hello from Luau!", 200, 220, 32, makeColor(0, 0, 0, 255))

print(os.clock())

local t = coroutine.create(function()
    while true do
        local char = Keyboard.pollChar()
        if char ~= 0 then
            print(char)
            Renderer.beginRedraw()
            Renderer.drawText(font, string.char(char), 200, 200, 32, makeColor(0, 0, 0, 255))
        end

        wait()
    end
end)

coroutine.resume(t)