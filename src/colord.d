/**
 * ColorD
 * 
 * Provides simple API for coloring text in terminal.
 * On Windows OS it uses SetConsoleAttribute function family,
 * On POSIX systems it uses ANSI codes.
 * 
 * Examples:
 * ------
 * import std.stdio, colord;
 * void main()
 * {
 *     setConsoleForeground(Color.Red);
 *     setConsoleBackground(Color.Blue);
 *     writeln("Red text with blue background");
 *     resetConsoleColors();
 * }
 * ------
 * 
 * License: <a href="http://www.boost.org/LICENSE_1_0.txt">Boost License</a>
 * Authors: <a href="http://github.com/robik">Robert 'Robik' Pasiński</a>
 */
module colord;


/// Console output stream
enum ConsoleOutputStream
{
    Stdout,
    Stderr
};

version(Windows)
{ 
    import core.sys.windows.windows, std.algorithm, std.stdio;
    
    ///
    enum Color : ushort
    {        
        Black        = 0, /// The black color.
        Blue         = 1, /// The blue color.
        Green        = 2, /// The green color.
        Cyan         = 3, /// The cyan color. (blue-green)
        Red          = 4, /// The red color.
        Magenta      = 5, /// The magenta color. (dark pink like)
        Yellow       = 6, /// The yellow color.
        LightGray    = 7, /// The light gray color. (silver)
        
        Gray         = 8,  /// The gray color.
        LightBlue    = 9,  /// The light blue color.
        LightGreen   = 10, /// The light green color.
        LightCyan    = 11, /// The light cyan color.(light blue-green)
        LightRed     = 12, /// The light red color.
        LightMagenta = 13, /// The light magenta color. (pink)
        LightYellow  = 14, /// The light yellow color.
        White        = 15, /// The white color.
        
        Bright       = 8,  /// Bright flag. Use with dark colors to make them light equivalents.
        Default      = 256 /// Default color.
    }
    
    shared static this()
    {
        loadDefaultColors(ConsoleOutputStream.Stdout);
    }
    
    private void loadDefaultColors(ConsoleOutputStream cos)
    {
        uint handle;
        
        if(cos == ConsoleOutputStream.Stdout) {
            handle = STD_OUTPUT_HANDLE;
        } else if(cos == ConsoleOutputStream.Stderr) {
            handle = STD_ERROR_HANDLE;
        } else {
            assert(0, "Invalid consone output stream specified");
        }
        
        hConsole = GetStdHandle(handle);
        
        // Get current colors
        CONSOLE_SCREEN_BUFFER_INFO info;
        GetConsoleScreenBufferInfo( hConsole, &info );
        defBg = cast(Color)((info.wAttributes & (0b11110000)) >> 4);
        defFg = cast(Color)(info.wAttributes & (0b00001111));
        
        fg = Color.Default;
        bg = Color.Default;
    }
    
    private __gshared
    {
        HANDLE hConsole = null;
        
        Color fg, bg, defFg, defBg;
    }
    
    
    private ushort buildColor(Color fg, Color bg)
    {
        if(fg == Color.Default) {
            fg = defFg;
        }
        
        if(bg == Color.Default) {
            bg = defBg;
        }
            
        return cast(ushort)(fg | bg << 4);
    }
    
    
    /**
     * Current console font color
     * 
     * Returns:
     *  Current foreground color set
     */
    Color getConsoleForeground()
    {
        return fg;
    }
    
    /**
     * Current console background color
     * 
     * Returns:
     *  Current background color set
     */
    Color getConsoleBackground()
    {
        return bg;
    }
    
    /**
     * Sets console foreground color
     *
     * Flushes stdout.
     *
     * Params:
     *  color = Foreground color to set
     */
    void setConsoleForeground(Color color)
    {
        stdout.flush();
        SetConsoleTextAttribute(hConsole, buildColor(color, bg));
        fg = color;
    }
    
    
    /**
     * Sets console background color
     *
     * Flushes stdout.
     *
     * Params:
     *  color = Background color to set
     */
    void setConsoleBackground(Color color)
    {   
        stdout.flush();
        SetConsoleTextAttribute(hConsole, buildColor(fg, color));
        bg = color;
    }
    
    /**
     * Sets new console output stream
     * 
     * This function sets default colors 
     * that are used when function is called.
     * 
     * Params:
     *  cos = New console output stream
     */
    void setConsoleStream(ConsoleOutputStream cos)
    {
        loadDefaultColors(cos);
    }
}
else version(Posix)
{
    import std.stdio, core.sys.posix.unistd;
    
    ///
    enum Color : ushort
    {        
        Black        = 30, /// The black color.
        Red          = 31, /// The red color.
        Green        = 32, /// The green color.
        Yellow       = 33, /// The yellow color.
        Blue         = 34, /// The blue color.
        Magenta      = 35, /// The magenta color. (dark pink like)
        Cyan         = 36, /// The cyan color. (blue-green)
        LightGray    = 37, /// The light gray color. (silver)
        
        Gray         = 94,  /// The gray color.
        LightRed     = 95,  /// The light red color.
        LightGreen   = 96,  /// The light green color.
        LightYellow  = 97,  /// The light yellow color.
        LightBlue    = 98,  /// The light red color.
        LightMagenta = 99,  /// The light magenta color. (pink)
        LightCyan    = 100, /// The light cyan color.(light blue-green)
        White        = 101, /// The white color.
        
        Bright       = 64,  /// Bright flag. Use with dark colors to make them light equivalents.
        Default      = 256  /// Default color
    }
    
    shared static this()
    {
        stream = stdout;
    }
    
    
    private __gshared
    {   
        Color fg = Color.Default;
        Color bg = Color.Default;
        File stream;
    }
    
    private bool isRedirected()
    {
        return isatty( fileno(stream.getFP) ) != 1;
    }
    
    /**
     * Sets console foreground color
     *
     * Params:
     *  color = Foreground color to set
     */
    void setConsoleForeground(Color color)
    {
        if(isRedirected()) {
            return;
        }
        
        fg = color;        
        stream.writef("\033[%d;%d;%dm", 
            color & Color.Bright ? 1 : 0, 
            cast(int)(fg & ~Color.Bright),
            cast(int)(bg & ~Color.Bright) + 10
        );
    }
    
    /**
     * Sets console background color
     *
     * Params:
     *  color = Background color to set
     */
    void setConsoleBackground(Color color)
    {
        if(isRedirected()) {
            return;
        }
        
        bg = color;
        stream.writef("\033[%d;%d;%dm", 
            color & Color.Bright ? 1 : 0, 
            cast(int)(fg & ~Color.Bright),
            cast(int)(bg & ~Color.Bright) + 10
        );        
    }   
    
    /**
     * Current console background color
     * 
     * Returns:
     *  Current foreground color set
     */
    Color getConsoleForeground()
    {
        return fg;
    }
    
    /**
     * Current console font color
     * 
     * Returns:
     *  Current background color set
     */
    Color getConsoleBackground()
    {
        return bg;
    }
    
    /**
     * Sets new console output stream
     * 
     * Params:
     *  cos = New console output stream
     */
    void setConsoleStream(ConsoleOutputStream cos)
    {
        if(cos == ConsoleOutputStream.Stdout) {
            stream = stdout;
        } else if(cos == ConsoleOutputStream.Stderr) {
            stream = stderr;
        } else {
            assert(0, "Invalid consone output stream specified");
        }
    }
}


/**
 * Sets both foreground and background colors
 * 
 * Params:
 *  fg = Foreground color
 *  bg = Background color
 */
void setConsoleColors(Color fg, Color bg)
{
    setConsoleForeground(fg);
    setConsoleBackground(bg);
}


/**
 * Brings default colors back
 */
void resetConsoleColors()
{
    setConsoleColors(Color.Default, Color.Default);
}