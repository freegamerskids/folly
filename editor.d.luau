
type Color = {
    red: number,
    green: number,
    blue: number,
    alpha: number?
};

type Font = any;

declare renderer: {
    font: {
        load: (filepath: string) -> Font
    },
    begin_redraw: () -> (),
    draw_rect: (x: number, y: number, width: number, height: number, color: Color) -> (),
    draw_text: (font: Font, text: string, x: number, y: number, font_size: number, color: Color) -> ()
}

declare function require(target: string): any?