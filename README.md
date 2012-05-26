## ColorD

*Because colors are awesome.*

### Navigation
 - [About](#about)
 - [Example](#example)
 - [Quick Guide](#quickguide)


### About

ColorD is open-source, small library written in [D Programming Language](http://dlang.org) that 
helps you add color to your console output. Work on both Windows and Linux operating systems.


### Example

```D
import std.stdio, colord;

void main()
{
    setConsoleForeground(Color.Red);
    writeln("foo"); // Color: Red | Bg: Default
    
    setConsoleBackground(Color.Blue);
    writeln("foo"); // Color: Red | Bg: Blue
    
    setConsoleForeground(Color.Default);
    writeln("foo"); // Color: Default | Bg: Blue
    
    setConsoleBackground(Color.Default);
    writeln("foo"); // Color: Default | Bg: Default
}
```

### Quick Guide

#### Resetting foreground color

```D
import std.stdio, colord;

void main()
{
    setConsoleForeground(Color.Default);
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
