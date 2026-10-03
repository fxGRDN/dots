.pragma library

// Colours taken from the pixelhole wallpaper (see hypr/scheme/current.lua).
var bg = "#0c0808";
var surface = "#160c0c";
var raised = "#221210";
var line = "#3a1a14";
var text = "#ffe8c4";
var subtext = "#c45a38";
var dim = "#6a4040";
var orange = "#ff6a10";
var red = "#b00800";
var brightRed = "#e01800";
var gold = "#ffcc44";
var magenta = "#c44dff";
var purple = "#a040c0";

var textFont = "Pixelon";
var iconFont = "FiraCode Nerd Font Propo";

var height = 28;
var fontSize = 14;
var iconSize = 15;

function icon(codepoint) {
    return String.fromCodePoint(codepoint);
}

var icons = {
    bell: icon(0xF009A),
    bellRing: icon(0xF009E),
    bellSleep: icon(0xF009C),
    close: icon(0xF0156),
    keyboard: icon(0xF030C),
    coffee: icon(0xF0176),
    coffeeOff: icon(0xF06CA),
    updates: icon(0xF0162),
    chevronLeft: icon(0xF0141),
    chevronRight: icon(0xF0142),
    cpu: icon(0xF0EE0),
    memory: icon(0xF035B),
    thermometer: icon(0xF050F),
    eyedropper: icon(0xF020A),
    bluetooth: icon(0xF00AF),
    bluetoothConnected: icon(0xF00B1),
    bluetoothOff: icon(0xF00B2),
    volumeHigh: icon(0xF057E),
    volumeMedium: icon(0xF0580),
    volumeLow: icon(0xF057F),
    volumeMuted: icon(0xF0581),
    wifi: [icon(0xF092F), icon(0xF091F), icon(0xF0922), icon(0xF0925), icon(0xF0928)],
    wifiOff: icon(0xF092E),
    ethernet: icon(0xF0200),
    battery: [icon(0xF007A), icon(0xF007B), icon(0xF007C), icon(0xF007D), icon(0xF007E),
              icon(0xF007F), icon(0xF0080), icon(0xF0081), icon(0xF0082), icon(0xF0079)],
    batteryCharging: icon(0xF0084),
    play: icon(0xF040A),
    pause: icon(0xF03E4),
    skipNext: icon(0xF04AD),
    skipPrevious: icon(0xF04AE)
};
