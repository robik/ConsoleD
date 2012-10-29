/**
 * ConsoleD
 * 
 * Provides simple API for coloring and formatting text in terminal.
 * On Windows OS it uses SetConsoleAttribute functions family,
 * On POSIX systems it uses ANSI codes.
 * 
 * Important notes:
 *  - Font styles have no effect on windows platform.
 *  - Light background colors are not supported. Non-light equivalents are used on Posix platforms.
 * 
 * Examples:
 * ------
 * import std.stdio, consoled;
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
module consoled;

import std.typecons;


/// Console output stream
enum ConsoleOutputStream
{
    stdout,
    stderr
}


/**
 * Console font output style
 * 
 * Does nothing on windows.
 */
enum FontStyle
{
    none          = 0, /// Default
    underline     = 1, /// Underline
    strikethrough = 2  /// Characters legible, but marked for deletion. Not widely supported.
}


/**
 * Represents close event.
 */
struct CloseEvent
{
    /// Close type
    CloseType type;
    
    /// Is close event blockable?
    bool      isBlockable;
}

/**
 * Close type.
 */
enum CloseType
{
    Interrupt, // User pressed Ctrl+C key combination.
    Stop,      // User pressed Ctrl+Break key combination. On posix it is Ctrl+Z.
    Quit,      // Posix only. User pressed Ctrl+\ key combination.
    Other      // Other close reasons. Probably unblockable.
}

/**
 * Represents point in console.
 */
alias Tuple!(int, "x", int, "y") ConsolePoint;


//////////////////////////////////////////////////////////////////////////
version(Windows)
{ 
    private enum BG_MASK = 0xf0;
    private enum FG_MASK = 0x0f;
    
    import core.sys.windows.windows, std.algorithm, std.stdio, std.string;

    ///
    enum Color : ushort
    {        
        black        = 0, /// The black color.
        blue         = 1, /// The blue color.
        green        = 2, /// The green color.
        cyan         = 3, /// The cyan color. (blue-green)
        red          = 4, /// The red color.
        magenta      = 5, /// The magenta color. (dark pink like)
        yellow       = 6, /// The yellow color.
        lightGray    = 7, /// The light gray color. (silver)
        
        gray         = 8,  /// The gray color.
        lightBlue    = 9,  /// The light blue color.
        lightGreen   = 10, /// The light green color.
        lightCyan    = 11, /// The light cyan color.(light blue-green)
        lightRed     = 12, /// The light red color.
        lightMagenta = 13, /// The light magenta color. (pink)
        lightYellow  = 14, /// The light yellow color.
        white        = 15, /// The white color.
        
        bright       = 8,  /// Bright flag. Use with dark colors to make them light equivalents.
        initial      = 256 /// Default color.
    }
    
    
    private __gshared
    {
        CONSOLE_SCREEN_BUFFER_INFO info;
        HANDLE hConsole = null, hInput = null;
        ConsolePoint cursorPos;
        
        Color fg, bg, defFg, defBg;
        void function(CloseEvent)[] closeHandlers;
    }
    
    
    shared static this()
    {
        loadDefaultColors(ConsoleOutputStream.stdout);
        cursorPos = ConsolePoint(info.dwCursorPosition.X, info.dwCursorPosition.Y);
        SetConsoleCtrlHandler(cast(PHANDLER_ROUTINE)&defaultCloseHandler, true);
    }
    
    private void loadDefaultColors(ConsoleOutputStream cos)
    {
        uint handle;
        
        if(cos == ConsoleOutputStream.stdout) {
            handle = STD_OUTPUT_HANDLE;
        } else if(cos == ConsoleOutputStream.stderr) {
            handle = STD_ERROR_HANDLE;
        } else {
            assert(0, "Invalid consone output stream specified");
        }
        
        
        hConsole = GetStdHandle(handle);
        hInput   = GetStdHandle(STD_INPUT_HANDLE);
        
        // Get current colors
        GetConsoleScreenBufferInfo( hConsole, &info );
        
        // Background are first 4 bits
        defBg = cast(Color)((info.wAttributes & (BG_MASK)) >> 4);
                
        // Rest are foreground
        defFg = cast(Color) (info.wAttributes & (FG_MASK));
        
        fg = Color.initial;
        bg = Color.initial;
    }
    
    private ushort buildColor(Color fg, Color bg)
    {
        if(fg == Color.initial) {
            fg = defFg;
        }
        
        if(bg == Color.initial) {
            bg = defBg;
        }
            
        return cast(ushort)(fg | bg << 4);
    }
    
    private void updateColor()
    {
        stdout.flush();
        SetConsoleTextAttribute(hConsole, buildColor(fg, bg));
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
        fg = color;
        updateColor();
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
        bg = color;
        updateColor();
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
    
    /**
     * Sets console font style
     * 
     * Does nothing on windows.
     * 
     * Params:
     *  fs = Font style to set
     */
    void setFontStyle(FontStyle fs) {}
    
    
    /**
     * Console size
     * 
     * Returns:
     *  Tuple containing console rows and cols.
     */
    ConsolePoint getConsoleSize()
    {
        GetConsoleScreenBufferInfo( hConsole, &info );
        
        int cols, rows;
        
        cols = (info.srWindow.Right  - info.srWindow.Left + 1);
        rows = (info.srWindow.Bottom - info.srWindow.Top  + 1);

        return ConsolePoint(cols, rows);
    }
    
    /**
     * Sets console position
     * 
     * Params:
     *  x = X coordinate of cursor postion
     *  y = Y coordinate of cursor position
     */
    void setConsoleCursor(int x, int y)
    {
        COORD coord = {
            cast(short)min(getConsoleWidth(), max(0, x)), 
            cast(short)max(0, y)
        };
        
        SetConsoleCursorPosition(hConsole, coord);
    }
    
    /**
     * Gets cursor position
     * 
     * Returns:
     *  Cursor position
     */
    ConsolePoint getConsoleCursor()
    {
        GetConsoleScreenBufferInfo( hConsole, &info );
        return ConsolePoint(
            info.dwCursorPosition.X, 
            min(info.dwCursorPosition.Y, getConsoleHeight) // To keep same behaviour with posix
        );
    }
    
    /**
     * Moves cursor by specified offset
     * 
     * Params:
     *  x = X offset
     *  y = Y offset
     */
    void move(int x, int y)
    {
        stdout.flush();
        auto pos = getConsoleCursor();
        setConsoleCursor(max(pos.x + x, 0), max(0, pos.y + y));
    }
    
    /**
     * Sets console title
     * 
     * Params:
     *  title = Title to set
     */
    void setConsoleTitle(string title)
    {
        SetConsoleTitleA(toStringz(title));
    }
    
    /**
     * Reads character without line buffering
     * 
     * Params:
     *  echo = Print typed characters
     */
    int getCharacter(bool echo = false)
    {
        int c;
        DWORD state;
        
        GetConsoleMode(hInput, &state);
        SetConsoleMode(hInput, 0);        
        c = getchar();
        SetConsoleMode(hInput, state);
        
        return c;
    }
    
    /**
     * Adds handler for console close event.
     * 
     * Params:
     *  closeHandler = New close handler
     */
    void addConsoleCloseHandler(void function(CloseEvent) closeHandler)
    {
        closeHandlers ~= closeHandler;
    }
    
    private CloseEvent idToCloseEvent(ulong i)
    {
        CloseEvent ce;
        
        switch(i)
        {
            case 0:
                ce.type = CloseType.Interrupt;
            break;
                
            case 1:
                ce.type = CloseType.Stop;
            break;
                
            default:
                ce.type = CloseType.Other;
        }
        
        ce.isBlockable = (ce.type == CloseType.Other) ? false : true;
        
        return ce;
    }
    
    private bool defaultCloseHandler(ulong reason)
    {
        foreach(closeHandler; closeHandlers)
        {
            closeHandler(idToCloseEvent(reason));
        }
        
        return true;
    }
}
///////////////////////////////////////////////////////////////////////////////////////
else version(Posix)
{
    import std.stdio, 
            std.conv,
            std.string,
            core.sys.posix.unistd,
            core.sys.posix.sys.ioctl,
            core.sys.posix.termios;
    
    enum SIGINT  = 2;
    enum SIGTSTP = 20;
    enum SIGQUIT = 3;
    extern(C) void signal(int, void function(int) @system);
    
    enum
    {
        UNDERLINE_ENABLE  = 4,
        UNDERLINE_DISABLE = 24,
            
        STRIKE_ENABLE     = 9,
        STRIKE_DISABLE    = 29
    }
    
    ///
    enum Color : ushort
    {        
        black        = 30, /// The black color.
        red          = 31, /// The red color.
        green        = 32, /// The green color.
        yellow       = 33, /// The yellow color.
        blue         = 34, /// The blue color.
        magenta      = 35, /// The magenta color. (dark pink like)
        cyan         = 36, /// The cyan color. (blue-green)
        lightGray    = 37, /// The light gray color. (silver)
        
        gray         = 94,  /// The gray color.
        lightRed     = 95,  /// The light red color.
        lightGreen   = 96,  /// The light green color.
        lightYellow  = 97,  /// The light yellow color.
        lightBlue    = 98,  /// The light red color.
        lightMagenta = 99,  /// The light magenta color. (pink)
        lightCyan    = 100, /// The light cyan color.(light blue-green)
        white        = 101, /// The white color.
        
        bright       = 64,  /// Bright flag. Use with dark colors to make them light equivalents.
        initial      = 256  /// Default color
    }
    
    
    private __gshared
    {   
        Color fg = Color.initial;
        Color bg = Color.initial;
        File stream;
        FontStyle fontStyle;
        
        void function(CloseEvent)[] closeHandlers;
    }
    
    shared static this()
    {
        stream = stdout;
        signal(SIGINT,  &defaultCloseHandler);
        signal(SIGTSTP, &defaultCloseHandler);
        signal(SIGQUIT, &defaultCloseHandler);
    }
    
    
    private bool isRedirected()
    {
        return isatty( fileno(stream.getFP) ) != 1;
    }
    
    private void printAnsi()
    {
        stream.writef("\033[%d;%d;%d;%d;%dm",
            fg &  Color.bright ? 1 : 0,            
            fg & ~Color.bright,
            bg & ~Color.bright + 10, // Background colors are normal + 10
            
            fontStyle & FontStyle.underline     ? UNDERLINE_ENABLE : UNDERLINE_DISABLE,
            fontStyle & FontStyle.strikethrough ? STRIKE_ENABLE    : STRIKE_DISABLE
        );        
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
        printAnsi();
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
        printAnsi();
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
        if(cos == ConsoleOutputStream.stdout) {
            stream = stdout;
        } else if(cos == ConsoleOutputStream.stderr) {
            stream = stderr;
        } else {
            assert(0, "Invalid consone output stream specified");
        }
    }
    
    
    /**
     * Sets console font style
     * 
     * Params:
     *  fs = Font style to set
     */
    void setFontStyle(FontStyle fs)
    {
        fontStyle = fs;
        printAnsi();
    }
    
    /**
     * Console size
     * 
     * Returns:
     *  Tuple containing console rows and cols.
     */
    ConsolePoint getConsoleSize()
    {
        winsize w;
        ioctl(STDOUT_FILENO, TIOCGWINSZ, &w);

        return ConsolePoint(cast(int)w.ws_col, cast(int)w.ws_row);
    }
    
    /**
     * Sets console position
     * 
     * Params:
     *  x = X coordinate of cursor postion
     *  y = Y coordinate of cursor position
     */
    void setConsoleCursor(int x, int y)
    {
        writef("\033[%d;%df", y + 1, x + 1);
        stdout.flush();
    }
    
    /**
     * Gets cursor position
     * 
     * Returns:
     *  Cursor position
     */
    ConsolePoint getConsoleCursor()
    {
        termios told, tnew;
        char[] buf;
        
        tcgetattr(0, &told);
        tnew = told;
        tnew.c_lflag &= ~ECHO & ~CREAD & ~ICANON;
        tcsetattr(0, TCSANOW, &tnew);
        
        write("\033[6n");
        stdout.flush();
        foreach(i; 0..8)
        {
            char c;
            c = cast(char)getCharacter();
            buf ~= c;
            if(c == 'R')
                break;
        }
        tcsetattr(0, TCSANOW, &told);
        
        buf = buf[2..$-1];
        auto tmp = buf.split(";");
        
        return ConsolePoint(to!int(tmp[1]) - 1, to!int(tmp[0]) - 1);
    }
    
    /**
     * Moves cursor by specified offset
     * 
     * Params:
     *  x = X offset
     *  y = Y offset
     */
    void move(int x, int y)
    {
        writef("\033[%dD", y);
        writef("\033[%dB", x);
        stdout.flush();
    }
    
    /**
     * Sets console title
     * 
     * Params:
     *  title = Title to set
     */
    void setConsoleTitle(string title)
    {
        writef("\033]0;%s\007", title); // TODO: Check if supported
        stdout.flush();
    }
    
    /**
     * Reads character without line buffering
     * 
     * Params:
     *  echo = Print typed characters
     */
    int getCharacter(bool echo = false)
    {
        termios told, tnew;
        int c;
        
        tcgetattr(0, &told);
        tnew = told;
        tnew.c_lflag &= ~ECHO & ~ICANON;
        tcsetattr(0, TCSANOW, &tnew);
        
        c = getchar();
        tcsetattr(0, TCSANOW, &told);
        
        return c;
    }
    
    
    /**
     * Adds handler for console close event.
     * 
     * Params:
     *  closeHandler = New close handler
     */
    void addConsoleCloseHandler(void function(CloseEvent) closeHandler)
    {
        closeHandlers ~= closeHandler;
    }
    
    private CloseEvent idToCloseEvent(ulong i)
    {
        CloseEvent ce;
        
        switch(i)
        {
            case SIGINT:
                ce.type = CloseType.Interrupt;
            break;
            
            case SIGQUIT:
                ce.type = CloseType.Quit;
            break;
            
            case SIGTSTP:
                ce.type = CloseType.Stop;
            break;
            
            default:
                ce.type = CloseType.Other;
        }
        
        ce.isBlockable = (ce.type == CloseType.Other) ? false : true;
        
        return ce;
    }
    
    private extern(C) void defaultCloseHandler(int reason) @system
    {
        foreach(closeHandler; closeHandlers)
        {
            closeHandler(idToCloseEvent(reason));
        }
    }
}

/**
 * Console width
 * 
 * Returns:
 *  Console width as number of columns
 */
int getConsoleWidth()
{
    return getConsoleSize().x;
}

/**
 * Console height
 * 
 * Returns:
 *  Console height as number of rows
 */
int getConsoleHeight()
{
    return getConsoleSize().y;
}

/**
 * Moves cursor up by n rows
 * 
 * Params:
 *  n = Number of rows to move
 */
void moveUp(int n = 1)
{
    move(0, -n);
}

/**
 * Moves cursor down by n rows
 * 
 * Params:
 *  n = Number of rows to move
 */
void moveDown(int n = 1)
{
    move(0, n);
}

/**
 * Moves cursor left by n columns
 * 
 * Params:
 *  n = Number of columns to move
 */
void moveLeft(int n = 1)
{
    move(-n, 0);
}

/**
 * Moves cursor right by n columns
 * 
 * Params:
 *  n = Number of columns to move
 */
void moveRight(int n = 1)
{
    move(n, 0);
}

/**
 * Sets both foreground and background colors
 * 
 * Params:
 *  params = Colors to set
 */
void setConsoleColors(T...)(T params)
{
    foreach(param; params)
    {
        static if(is(typeof(param) == Fg)) {
            setConsoleForeground(param.val);
        } else static if(is(typeof(param) == Bg)) {
            setConsoleBackground(param.val);
        } else {
            static assert(0, "Invalid parameter specified to setConsoleColors");
        }
    }
}

/**
 * Clears console screen
 */
void fillArea(ConsolePoint p1, ConsolePoint p2, char fill)
{
    foreach(i; p1.y .. p2.y)
    {       
        setConsoleCursor(p1.x, i);
        write( std.array.replicate((&fill)[0..1], p2.x - p1.x));
                                // ^ Converting char to char[]
        stdout.flush();
    }
    stdout.flush();
}

/**
 * Writes at specified position
 * 
 * Params:
 *  point = Where to write
 *  data = Data to write
 */
void writeAt(T)(ConsolePoint point, T data)
{
    setConsoleCursor(point.x, point.y);
    write(data);
    stdout.flush();
}

/**
 * Clears console screen
 */
void clearConsoleScreen()
{
    auto size = getConsoleSize();
    short length = cast(short)(size.x * size.y); // Number of all characters to write
    setConsoleCursor(0, 0);
    
    write( std.array.replicate(" ", length));
    stdout.flush();
}


/**
 * Brings default colors back
 */
void resetConsoleColors()
{
    setConsoleColors(Fg.initial, Bg.initial);
}


/**
 * Brings font formatting to default
 */
void resetFontStyle()
{
    setFontStyle(FontStyle.none);
}


struct EnumTypedef(T, string _name) if(is(T == enum))
{
    public T val = T.init;
    
    this(T v) { val = v; }
    
    static EnumTypedef!(T, _name) opDispatch(string n)()
    {
        return EnumTypedef!(T, _name)(__traits(getMember, val, n));
    }
}

/// Alias for color enum
alias EnumTypedef!(Color, "fg") Fg;

/// ditto
alias EnumTypedef!(Color, "bg") Bg;


/**
 * Writes text to console and colorizes text
 * 
 * Params:
 *  params = Text to write
 */
void writec(T...)(T params)
{
    foreach(param; params)
    {
        static if(is(typeof(param) == Fg)) {
            setConsoleForeground(param.val);
        } else static if(is(typeof(param) == Bg)) {
            setConsoleBackground(param.val);
        } else {
            write(param);
        }
    }
}

/**
 * Writes line to console and goes to newline
 * 
 * Params:
 *  params = Text to write
 */
void writecln(T...)(T params)
{
    writec(params);
    writeln();
}
