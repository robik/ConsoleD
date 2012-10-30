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
 
### Featues

 - Setting and Getting console colors
 - Clearing screen
 - Setting console title
 - Getting console size
 - Moving the console cursor around as well as getting its position
 - Handling the close event
 - Getting input with not echo and without line buffering.
 
### Todo

 - Better input handling
 - Mouse input?

### Examples

#### Adding colors

```D
import std.stdio, consoled;

void main()
{
    foreground(Color.red);
    writeln("foo"); // Fg: Red | Bg: Default
    
    background(Color.blue);
    writeln("foo"); // Fg: Red | Bg: Blue
    
    resetColors(); // Bring back initial state
}
```

or:

```D
import std.stdio, consoled;

void main()
{
    setColors(Fg.red, Bg.blue); /// Order does not matter as long parameters are Fg or Bg.
    writeln("foo"); // Color: Red | Bg: Blue
    
    resetColors(); // Bring back initial state
}
```


#### Current Foreground/Background

To get current foreground and background colors, simply use `foreground` or `background` properties

```D
import std.stdio, consoled;

void main()
{
    auto currentFg = foreground;
    auto currentBg = background;
}
```


#### Font Styles

You can change font styles, like `strikethrough` and `underline`. This feature is Posix only, when called on windows, nothing happens.

```D
import std.stdio, consoled;

void main()
{
    fontStyle = FontStyle.underline | FontStyle.strikethrough;
    writeln("foo");
    resetFontStyle(); // Or just fontStyle = FontStyle.none;
}
```

#### Easy colored messages

You can use helper function `writec` or `writecln` to easily  colored messages.

```D
import std.stdio, consoled;

void main()
{
    writecln("Hello ", Fg.blue, "World", Bg.red, "!");
    resetColors();
}
```

#### Console Size

You can get console size using `size` property which return tuple containg width and height of the console.

```D
import std.stdio, consoled;

void main()
{
    writeln(size);
}
```

#### Cursor manipulation

You can set cursor position using `setCursorPos()`:

```D
import std.stdio, consoled;

void main()
{
    // 6 is half of "insert coin" length.
    setConsoleCursor(size.x / 2 - 6, size.y / 2);
    writeln("Insert coin");
}
```

#### Clearing the screen

You can clear console screen using `clearScreen()` function:

```D
import std.stdio, consoled, core.thread;

void main()
{
	// Fill whole screen with hashes
    fillArea(ConsolePoint(0, 0), size, '#');
	
	// Wait 3 seconds
	Thread.sleep(dur!"seconds"(3));
	
	// Clear the screen
	clearScreen();
}
```


#### Setting the title

To set console title, use `title` property:


```D
import std.stdio, consoled;

void main()
{
	title = "My new title";
}
```


#### Setting exit handler

It is possible to handle some close events, such as Ctrl+C key combination using `addCloseHandler()`:

```D
import std.stdio, consoled;
void main()
{   
    setCloseHandler((i){
        switch(i.type)
        {
            case CloseType.Other:
                writeln("Other");
            break;
            
            case CloseType.Interrupt:
                writeln("Ctrl+C");
            break;
            
            // Ctrl+Break for windows, Ctrl+Z for posix
            case CloseType.Stop:
                writeln("Ctrl+Break or Ctrl+Z");
            break;
            
            
            // Posix only
            case CloseType.Quit:
				writeln("Ctrl+\");
            break;
            
            default:
        }
        
        writeln(i.isBlockable);
    });
    
    while(true){}
}

```
