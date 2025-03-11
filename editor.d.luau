
type Color = {
    red: number,
    green: number,
    blue: number,
    alpha: number?
};

type FontId = number;

type FetchOptions = {
    method: "GET" | "POST" | "PUT" | "PATCH" | "DELETE" | "OPTIONS" | "HEAD" | "TRACE" | "CONNECT",
    headers: { [string]: string },
    body: string?
}

type FetchResponse = {
    status: number,
    body: string,
    headers: { [string]: string }
}

declare Renderer: {
    Font: {
        load: (filepath: string) -> FontId
    },

    drawRect: (x: number, y: number, width: number, height: number, color: Color) -> (),
    drawRectOutline: (x: number, y: number, width: number, height: number, line_width: number, color: Color) -> (),
    drawRectRound: (x: number, y: number, width: number, height: number, roundness: number, color: Color) -> (),
    drawRectRoundOutline: (x: number, y: number, width: number, height: number, roundness: number, line_width: number, color: Color) -> (),
    
    drawCircle: (x: number, y: number, radius: number, color: Color) -> (),
    drawCircleOutline: (x: number, y: number, radius: number, color: Color) -> (),

    drawText: (font: FontId, text: string, x: number, y: number, size: number, color: Color) -> (),
    measureText: (font: FontId, text: string, size: number) -> (number, number)
}

declare Input: {
    Keyboard: {
        pollKey: () -> number,
        pollChar: () -> number
    },
    Mouse: {
        getPosition: () -> (number, number),
        getWheelMove: () -> (number, number)
    }
}

declare App: {
    --- returns true if redraw
    setMainLoop: (func: () -> boolean) -> (),
    getFPS: () -> number,
    setFPS: (fps: number) -> (),
    getWindowSize: () -> (number, number),
}

declare File: {
    read: (path: string) -> string,
    write: (path: string, contents: string) -> ()
}

declare JSON: {
    parse: (json: string) -> any,
    stringify: (any: any) -> string
}

declare function require(target: string): any;

declare function fetch(url: string, options: FetchOptions): FetchResponse;