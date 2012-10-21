## ColorD

### License

 This library is licensed under Boost License.

### About

ColorD is open-source, small library written in [D Programming Language](http://dlang.org) that 
helps you add color to your console output. Work on both Windows and Posix operating systems.

#### Important notes:

 * Font styles(underline, strikethrough) have no effect on Windows OS.
 * Light background colors are not supported. Non-light equivalents are used on Posix platforms.
 * On Linux, getting current colors(Foreground, Background) without using any of `setConsole*` always results in Color.initial, on Windows it returns current used color.

### Examples

#### Adding colors

```D
import std.stdio, colord;

void main()
{
    setConsoleForeground(Color.red);
    writeln("foo"); // Color: Red | Bg: Default
    
    setConsoleBackground(Color.blue);
    writeln("foo"); // Color: Red | Bg: Blue
    
    // Above code can be replaced with
	// Fg and Bg are typedefs for Color
    setConsoleColors(Fg.red, Bg.blue);
    
    resetConsoleColors(); // Bring back initial state
}
```


#### Current Foreground/Background

```D
import std.stdio, colord;

void main()
{
    auto currentFg = getConsoleForeground();
    auto currentBg = getConsoleBackground();
}
```


#### Font Styles

```D
import std.stdio, colord;

void main()
{
    setFontStyle(FontStyle.underline | FontStyle.strikethrough);
    writeln("foo");
    resetFontStyle(); // Or just setFontStyle(FontStyle.none);
}
```

#### Easy colored messages

```D
import std.stdio, colord;

void main()
{
    writecln("Hello ", Fg.blue, "World", Bg.red, "!");
    resetConsoleColors();
}
```
