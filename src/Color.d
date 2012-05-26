module colord;

version(Windows)
{ 
    import std.c.windows.windows;
    
    ///
    enum Color : ushort
    {
        Black       = 0,
        DarkBlue    = 1,
        DarkGreen   = 2,
        DarkAzure   = 3,
        DarkRed     = 4,
        Purple      = 5,
        DarkYellow  = 6,
        Silver      = 7,
        Gray        = 8,
        
        Blue        = 9,
        Green       = 10,
        Aqua        = 11,
        Red         = 12,
        Yellow      = 13,
        White       = 14,
        
        Default     = 256
    }
    
    static this()
    {
        hConsole = GetStdHandle(STD_OUTPUT_HANDLE);
        
        // Get current colors
        CONSOLE_SCREEN_BUFFER_INFO info;
        GetConsoleScreenBufferInfo( hConsole, &info );
        bg = cast(Color)(info.wAttributes & (0b11110000));
        fg = cast(Color)(info.wAttributes & (0b00001111));
        
        import std.stdio;
        writeln(fg, bg);
    }
    
    package static
    {
        extern(C) HANDLE hConsole = null;
        
        Color fg;
        Color bg;
    }
    
    
    private ushort buildColor(Color fg, Color bg)
    {
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
        if(color != Color.Default)
        {
            SetConsoleTextAttribute(hConsole, buildColor(cast(Color)16, bg));
        }
        
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
        if(color != Color.Default)
        {
            SetConsoleTextAttribute(hConsole, buildColor(fg, color));
        }
        
        bg = color;
    }
    
}
else version(Posix)
{
    import std.stdio;
    
    /// 
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
    
    
    /**
     * Sets console foreground color
     *
     * Params:
     *  color = Color to set
     */
    void setConsoleForeground(Color color)
    {
        if(color == Color.Default)
        {
            writef("\033[0m");
            fg = Color.Default;
            setConsoleBackgroundColor(bg);
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
        if(color == Color.Default)
        {
            writef("\033[0m");
            bg = Color.Default;
            setConsoleFontColor(fg);
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