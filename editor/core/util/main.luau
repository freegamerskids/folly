local t = {}

function t:MakeColor(r: number, g: number, b: number, a: number)
    return {
        red = r,
        green = g,
        blue = b,
        alpha = a
    }
end

return t