
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
    endRedraw: () -> (),
    drawRect: (x: number, y: number, width: number, height: number, color: Color) -> (),
    drawText: (font: FontId, text: string, x: number, y: number, font_size: number, color: Color) -> (),
    getFPS: () -> number,
    setFPS: (fps: number) -> ()
}

declare Keyboard: {
    pollKey: () -> number,
    pollChar: () -> number
}

declare App: {
    --- returns true if redraw
    setMainLoop: (func: () -> boolean) -> ()
}

declare function require(target: string): any?