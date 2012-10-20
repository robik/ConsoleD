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
 * ------
 * 
 * License: <a href="http://opensource.org/licenses/mit-license.php">MIT License</a>
 * Autor: <a href="http://github.com/robik">Robert 'Robik' Pasiński</a>
 */
module colord;

version(Windows)
{ 
    import core.sys.windows.windows, std.algorithm, std.stdio;
    
    ///
    enum Color : ushort
    {
        Black        = 0,
        Blue         = 1,
        Green        = 2,
        Cyan         = 3,
        Red          = 4,
        Magenta      = 5,
        Yellow       = 6,
        LightGray    = 7,
        
        Gray         = 8,   
        LightBlue    = 9,
        LightGreen   = 10,
        LightCyan    = 11,
        LightRed     = 12,
        LightMagenta = 13,
        LightYellow  = 14,
        White        = 15,
        
        Bright       = 8,
        Default     = 256
    }
    
    shared static this()
    {
        hConsole = GetStdHandle(STD_OUTPUT_HANDLE);
        
        // Get current colors
        CONSOLE_SCREEN_BUFFER_INFO info;
        GetConsoleScreenBufferInfo( hConsole, &info );
        defBg = cast(Color)((info.wAttributes & (0b11110000)) >> 4);
        defFg = cast(Color)(info.wAttributes & (0b00001111));
        
        fg = Color.Default;
        bg = Color.Default;
    }
    
    package __gshared
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
     */
    Color getConsoleForeground()
    {
        return fg;
    }
    
    /**
     * Current console background color
     */
    Color getConsoleBackground()
    {
        return bg;
    }
    
    /**
     * Sets console foreground color
     *
     * Flushes stdout 
     *
     * Params:
     *  color = Color to set
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
     * Flushes stdout 
     *
     * Params:
     *  color = Color to set
     */
    void setConsoleBackground(Color color)
    {   
        stdout.flush();
        SetConsoleTextAttribute(hConsole, buildColor(fg, color));
        bg = color;
    }
}
else version(Posix)
{
    import std.stdio, core.sys.posix.unistd;
    
    enum Color
    {
        Black        = 30,
        Red          = 31,
        Green        = 32,
        Yellow       = 33,
        Blue         = 34,
        Magenta      = 35,
        Cyan         = 36,
        LightGray    = 37,
        
        Gray         = 94,
        LightRed     = 95,
        LightGreen   = 96,
        LightYellow  = 97,
        LightBlue    = 98,
        LightMagenta = 99,
        LightCyan    = 100,
        White        = 101,
        
        Bright       = 64,
        
        Default      = 39
    }
    
    __gshared
    {   
        Color fg = Color.Default;
        Color bg = Color.Default;
    }
    
    private bool isRedirected()
    {
        return isatty( fileno(stdout.getFP) ) != 1;
    }
    
    /**
     * Sets console foreground color
     *
     * Params:
     *  color = Color to set
     */
    void setConsoleForeground(Color color)
    {
        if(isRedirected()) {
            return;
        }
        
        fg = color;
        writef("\033[%d;%d;%dm", 
            color & Color.Bright ? 1 : 0, 
            cast(int)(fg & ~Color.Bright),
            cast(int)(bg & ~Color.Bright) + 10
        );        
    }
    
    /**
     * Sets console background color
     *
     * Params:
     *  color = Color to set
     */
    void setConsoleBackground(Color color)
    {
        if(isRedirected()) {
            return;
        }
        
        bg = color;
        writef("\033[%d;%d;%dm", 
            color & Color.Bright ? 1 : 0, 
            cast(int)(fg & ~Color.Bright),
            cast(int)(bg & ~Color.Bright) + 10
        );        
    }   
    
    /**
     * Current console background color
     */
    Color getConsoleForeground()
    {
        return fg;
    }
    
    /**
     * Current console font color
     */
    Color getConsoleBackground()
    {
        return bg;
    }
}

