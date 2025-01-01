
type Color = {
    red: number,
    green: number,
    blue: number,
    alpha: number?
};

type FontId = number;

declare Renderer: {
    Font: {
        load: (filepath: string) -> FontId
    },
    beginRedraw: () -> (),
    drawRect: (x: number, y: number, width: number, height: number, color: Color) -> (),
    drawText: (font: FontId, text: string, x: number, y: number, font_size: number, color: Color) -> ()
}

declare Keyboard: {
    pollKey: () -> number,
    pollChar: () -> number
}

declare function require(target: string): any?