module colord;

version(Windows)
{ 
    import std.c.windows.windows;
    
    ///
    enum Color : ushort
    {
        DarkBlue    = 1,
        DarkGreen   = 2,
        DarkAzure   = 3,
        DarkRed     = 4,
        Purple      = 5,
        DarkYellow  = 6,
        Silver      = 7,
        Gray        = 8,
     
        Black       = 0,   
        Blue        = 9,
        Green       = 10,
        Aqua        = 11,
        Red         = 12,
        Pink        = 13,
        Yellow      = 14,
        White       = 15,
        
        Default     = 256
    }
    
    static this()
    {
        hConsole = GetStdHandle(STD_OUTPUT_HANDLE);
        
        // Get current colors
        CONSOLE_SCREEN_BUFFER_INFO info;
        GetConsoleScreenBufferInfo( hConsole, &info );
        defBg = cast(Color)(info.wAttributes & (0b11110000));
        defFg = cast(Color)(info.wAttributes & (0b00001111));
        
        fg = Color.Default;
        bg = Color.Default;
    }
    
    package static
    {
        extern(C) HANDLE hConsole = null;
        
        Color fg, bg, defFg, defBg;
    }
    
    
    private ushort buildColor(Color fg, Color bg)
    {
        if(fg == Color.Default)
        {
            fg = defFg;
        }
        
        if(bg == Color.Default)
        {
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
     * Params:
     *  color = Color to set
     */
    void setConsoleForeground(Color color)
    {
        SetConsoleTextAttribute(hConsole, buildColor(color, bg));
            
        fg = color;
    }
    
    
    /**
     * Sets console background color
     *
     * Params:
     *  color = Color to set
     */
    void setConsoleBackground(Color color)
    {   
        SetConsoleTextAttribute(hConsole, buildColor(fg, color));
        bg = color;
    }
    
}
else version(Posix)
{
    import std.stdio;
    
    extern(C) int isatty(int);
    
    enum Color : ushort
    {
        Black   = 30,
        Red     = 31,
        Green   = 32,
        Orange  = 33,
        Blue    = 34,
        Pink    = 35,
        Aqua    = 36,
        White   = 37,
        
        Default = 0
    }
    
    static
    {   
        Color fg = Color.Default;
        Color bg = Color.Default;
    }
    
    private bool isRedirected()
    {
        return isatty( fileno(stdout.getFP) ) == 1;
    }
    
    /**
     * Sets console foreground color
     *
     * Params:
     *  color = Color to set
     */
    void setConsoleForeground(Color color)
    {
        if(!isRedirected()) {
            return;
        }
        
        if(color == Color.Default)
        {
            writef("\033[0m");
            fg = Color.Default;
            
            // Because all colors were reseted, bring back BG color
            if(bg != Color.Default)
            {
                setConsoleBackground(bg);
            }
        }
        else
        {
            writef("\033[0;%dm", cast(int)color);
            fg = color;
        }
    }
    
    /**
     * Sets console background color
     *
     * Params:
     *  color = Color to set
     */
    void setConsoleBackground(Color color)
    {
        if(!isRedirected()) {
            return;
        }
        
        if(color == Color.Default)
        {
            writef("\033[0m");
            bg = Color.Default;

            // Because all colors were reseted, bring back FG color
            if(fg != Color.Default)
            {
                setConsoleForeground(fg);
            }
        }
        else
        {
            writef("\033[0;%dm", cast(int)color + 10);
            bg = color;
        }
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
