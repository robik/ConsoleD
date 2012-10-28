## ConsoleD

### License

 This library is licensed under Boost License.

### About

ConsoleD is open-source, small library written in [D Programming Language](http://dlang.org) that 
helps you add colors and formatting to your console output. Work on both Windows and Posix operating systems.

#### Important notes:

 * Font styles(underline, strikethrough) have no effect on Windows OS.
 * Light background colors are not supported on Posix, Non-light equivalents are used.
 * _Temponary_: Because `core.sys.posix.sys.ioctl` module was added recently, you must compile project with this [file](https://github.com/D-Programming-Language/druntime/blob/master/src/core/sys/posix/sys/ioctl.d).

### Examples

#### Adding colors

```D
import std.stdio, consoled;

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
import std.stdio, consoled;

void main()
{
    auto currentFg = getConsoleForeground();
    auto currentBg = getConsoleBackground();
}
```


#### Font Styles

```D
import std.stdio, consoled;

void main()
{
    setFontStyle(FontStyle.underline | FontStyle.strikethrough);
    writeln("foo");
    resetFontStyle(); // Or just setFontStyle(FontStyle.none);
}
```

#### Easy colored messages

```D
import std.stdio, consoled;

void main()
{
    writecln("Hello ", Fg.blue, "World", Bg.red, "!");
    resetConsoleColors();
}
```
