module colord;

version(Windows)
{ 
    import core.sys.windows.windows, std.algorithm, std.stdio;
    
    ///
    enum Color : ushort
    {
        Black   = 0,
        Blue    = 1,
        Green   = 2,
        Azure   = 3,
        Red     = 4,
        Purple  = 5,
        Yellow  = 6,
        White   = 7,
        
        /*Gray      = 8,   
        Blue        = 9,
        Green       = 10,
        Aqua        = 11,
        Red         = 12,
        Pink        = 13,
        Yellow      = 14,
        White       = 15,*/
        
        Default     = 256
    }
    
    shared static this()
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
    
    package static __gshared
    {
        HANDLE hConsole = null;
        
        Color fg, bg, defFg, defBg;
        bool isHighlighted;
    }
    
    
    private ushort buildColor(Color fg, Color bg)
    {
        if(fg == Color.Default) {
            fg = defFg;
        }
        
        if(bg == Color.Default) {
            bg = defBg;
        }
        
        if(isHighlighted)
        {
            if(fg != Color.Default) {
                fg = cast(Color)( min(fg + 8, 15) );
            } else {
                fg = cast(Color)( min(defFg + 8, 15) );
            }
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
     * Enables/disables console font highlight
     */
    void setFontHighlight(bool enable)
    {
        isHighlighted = enable;
        setConsoleForeground(fg);
        setConsoleBackground(bg);
    }
    
    /**
     * Returns: Is font highlighted?
     */
    bool isFontHighlighted()
    {
        return isHighlighted;
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
        
        bool isHighlighted;
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
            writef("\033[%dm", isHighlighted ? 1 : 0);
            fg = Color.Default;
            
            // Because all colors were reseted, bring back BG color
            if(bg != Color.Default)
            {
                setConsoleBackground(bg);
            }
        }
        else
        {
            writef("\033[%d;%dm", isHighlighted ? 1 : 0, cast(int)color);
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
            writef("\033[%dm", isHighlighted ? 1 : 0);
            bg = Color.Default;

            // Because all colors were reseted, bring back FG color
            if(fg != Color.Default)
            {
                setConsoleForeground(fg);
            }
        }
        else
        {
            writef("\033[%d;%dm", isHighlighted ? 1 : 0, cast(int)color + 10);
            bg = color;
        }
    }
    
    /**
     * Enables/disables console font highlight
     */
    void setFontHighlight(bool enable)
    {
        isHighlighted = enable;
        setConsoleForeground(fg);
        setConsoleBackground(bg);
    }
    
    /**
     * Returns: Is font highlighted?
     */
    bool isFontHighlighted()
    {
        return isHighlighted;
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
