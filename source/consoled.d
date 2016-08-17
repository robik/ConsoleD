/**
 * Provides simple API for coloring and formatting text in terminal.
 * On Windows OS it uses WinAPI functions, on POSIX systems it uses mainly ANSI codes.
 *
 * Using terminal.d is recommended as it is more mature and stable.
 *
 * $(B Important notes):
 * $(UL
 *  $(LI Font styles have no effect on windows platform.)
 *  $(LI Light background colors are not supported. Non-light equivalents are used on Posix platforms.)
 * )
 *
 * License:
 *  <a href="http://www.boost.org/LICENSE_1_0.txt">Boost License</a>
 * Authors:
 *  <a href="http://github.com/robik">Robert 'Robik' Pasiński</a>
 */
module consoled;

import std.typecons, std.algorithm;
import std.array : replicate;


/// Console output stream
enum ConsoleOutputStream
{
    /// Standard output
    stdout,

    /// Standard error output
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

alias void delegate(CloseEvent) @system CloseHandler;

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
 * Console input mode
 */
struct ConsoleInputMode
{
    /// Echo printed characters?
    bool echo = true;

    /// Enable line buffering?
    bool line = true;

    /**
     * Creates new ConsoleInputMode instance
     *
     * Params:
     *  echo = Echo printed characters?
     *  line = Use Line buffering?
     */
    this(bool echo, bool line)
    {
        this.echo = echo;
        this.line = line;
    }

    /**
     * Console input mode with no feature enabled
     */
    static ConsoleInputMode None = ConsoleInputMode(false, false);
}

/**
 * Represents point in console.
 */
alias Tuple!(int, "x", int, "y") ConsolePoint;

/// Special keys
enum SpecialKey
{
    home = 512, /// Home key
    pageUp,     /// Page Up key
    pageDown,   /// Page Down key
    end,        /// End key
    delete_,    /// Delete key
    insert,     /// Insert key
    up,         /// Arrow up key
    down,       /// Arrow down key
    left,       /// Arrow left key
    right,      /// Arrow right key

    escape = 27,/// Escape key
    tab = 9,    /// Tab key
}

////////////////////////////////////////////////////////////////////////
version(Windows)
{
    private enum BG_MASK = 0xf0;
    private enum FG_MASK = 0x0f;

    import core.sys.windows.windows, std.stdio, std.string;

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
        lightCyan    = 11, /// The light cyan color. (light blue-green)
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
        HANDLE hOutput = null, hInput = null;

        Color fg, bg, defFg, defBg;
        CloseHandler[] closeHandlers;
    }


    shared static this()
    {
        loadDefaultColors(ConsoleOutputStream.stdout);
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
            assert(0, "Invalid console output stream specified");
        }


        hOutput  = GetStdHandle(handle);
        hInput   = GetStdHandle(STD_INPUT_HANDLE);

        // Get current colors
        GetConsoleScreenBufferInfo( hOutput, &info );

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
        SetConsoleTextAttribute(hOutput, buildColor(fg, bg));
    }


    /**
     * Current console font color
     *
     * Returns:
     *  Current foreground color set
     */
    Color foreground() @property
    {
        return fg;
    }

    /**
     * Current console background color
     *
     * Returns:
     *  Current background color set
     */
    Color background() @property
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
    void foreground(Color color) @property
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
    void background(Color color) @property
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
    void outputStream(ConsoleOutputStream cos) @property
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
    void fontStyle(FontStyle fs) @property {}

    /**
     * Returns console font style
     *
     * Returns:
     *  Font style, always none on windows.
     */
    FontStyle fontStyle() @property
    {
        return FontStyle.none;
    }


    /**
     * Console size
     *
     * Returns:
     *  Tuple containing console rows and cols.
     */
    ConsolePoint size() @property
    {
        GetConsoleScreenBufferInfo( hOutput, &info );

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
    void setCursorPos(int x, int y)
    {
        COORD coord = {
            cast(short)min(width, max(0, x)),
            cast(short)max(0, y)
        };
        stdout.flush();
        SetConsoleCursorPosition(hOutput, coord);
    }

    /**
     * Gets cursor position
     *
     * Returns:
     *  Cursor position
     */
    ConsolePoint cursorPos() @property
    {
        GetConsoleScreenBufferInfo( hOutput, &info );
        return ConsolePoint(
            info.dwCursorPosition.X,
            min(info.dwCursorPosition.Y, height) // To keep same behaviour with posix
        );
    }



    /**
     * Sets console title
     *
     * Params:
     *  title = Title to set
     */
    void title(string title) @property
    {
        SetConsoleTitleA(toStringz(title));
    }


    /**
     * Adds handler for console close event.
     *
     * Params:
     *  closeHandler = New close handler
     */
    void addCloseHandler(CloseHandler closeHandler)
    {
        closeHandlers ~= closeHandler;
    }

    /**
     * Moves cursor by specified offset
     *
     * Params:
     *  x = X offset
     *  y = Y offset
     */
    private void moveCursor(int x, int y)
    {
        stdout.flush();
        auto pos = cursorPos();
        setCursorPos(max(pos.x + x, 0), max(0, pos.y + y));
    }

    /**
     * Moves cursor up by n rows
     *
     * Params:
     *  n = Number of rows to move
     */
    void moveCursorUp(int n = 1)
    {
        moveCursor(0, -n);
    }

    /**
     * Moves cursor down by n rows
     *
     * Params:
     *  n = Number of rows to move
     */
    void moveCursorDown(int n = 1)
    {
        moveCursor(0, n);
    }

    /**
     * Moves cursor left by n columns
     *
     * Params:
     *  n = Number of columns to move
     */
    void moveCursorLeft(int n = 1)
    {
        moveCursor(-n, 0);
    }

    /**
     * Moves cursor right by n columns
     *
     * Params:
     *  n = Number of columns to move
     */
    void moveCursorRight(int n = 1)
    {
        moveCursor(n, 0);
    }

    /**
     * Gets console mode
     *
     * Returns:
     *  Current console mode
     */
    ConsoleInputMode mode() @property
    {
        ConsoleInputMode cim;
        DWORD m;
        GetConsoleMode(hInput, &m);

        cim.echo  = !!(m & ENABLE_ECHO_INPUT);
        cim.line  = !!(m & ENABLE_LINE_INPUT);

        return cim;
    }

    /**
     * Sets console mode
     *
     * Params:
     *  New console mode
     */
    void mode(ConsoleInputMode cim) @property
    {
        DWORD m;

        (cim.echo) ? (m |= ENABLE_ECHO_INPUT) : (m &= ~ENABLE_ECHO_INPUT);
        (cim.line) ? (m |= ENABLE_LINE_INPUT) : (m &= ~ENABLE_LINE_INPUT);

        SetConsoleMode(hInput, m);
    }

    /**
     * Reads character without line buffering
     *
     * Params:
     *  echo = Print typed characters
     */
    int getch(bool echo = false)
    {
        INPUT_RECORD ir;
        DWORD count;
        auto m = mode;

        mode = ConsoleInputMode.None;

        do {
            ReadConsoleInputA(hInput, &ir, 1, &count);
        } while((ir.EventType != KEY_EVENT || !ir.KeyEvent.bKeyDown) && kbhit());
	// the extra kbhit is to filter out events AFTER the keydown
	// to ensure next time we call this, we're back on a fresh keydown
	// event. Without that, the key up event will trigger kbhit, then
	// you call getch(), and it blocks because it read keyup then looped
	// and is waiting for another keydown.

        mode = m;

        return ir.KeyEvent.wVirtualKeyCode;
    }

    /**
     * Checks if any key is pressed.
     *
     * Shift, Ctrl and Alt keys are not detected.
     *
     * Returns:
     *  True if any key is pressed, false otherwise.
     */
    bool kbhit()
    {
        return WaitForSingleObject(hInput, 0) == WAIT_OBJECT_0;
    }

    /**
     * Sets cursor visibility
     *
     * Params:
     *  visible = Cursor visibility
     */
    void cursorVisible(bool visible) @property
    {
        CONSOLE_CURSOR_INFO cci;
        GetConsoleCursorInfo(hOutput, &cci);
        cci.bVisible = visible;
        SetConsoleCursorInfo(hOutput, &cci);
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

        ce.isBlockable = (ce.type != CloseType.Other);

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
////////////////////////////////////////////////////////////////////////
else version(Posix)
{
    static import terminal;
    import std.stdio,
            std.conv,
            std.string,
            core.sys.posix.unistd,
            core.sys.posix.sys.ioctl,
            core.sys.posix.termios,
            core.sys.posix.fcntl,
            core.sys.posix.sys.time;
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
        int stdinFd;
        FontStyle currentFontStyle;

        CloseHandler[] closeHandlers;
        SpecialKey[string] specialKeys;
    }

    shared static this()
    {
        stream = stdout;
        signal(SIGINT,  &defaultCloseHandler);
        signal(SIGTSTP, &defaultCloseHandler);
        signal(SIGQUIT, &defaultCloseHandler);
        stdinFd = fileno(stdin.getFP);

        specialKeys = [
            "[A" : SpecialKey.up,
            "[B" : SpecialKey.down,
            "[C" : SpecialKey.right,
            "[D" : SpecialKey.left,

            "OH" : SpecialKey.home,
            "[5~": SpecialKey.pageUp,
            "[6~": SpecialKey.pageDown,
            "OF" : SpecialKey.end,
            "[3~": SpecialKey.delete_,
            "[2~": SpecialKey.insert,

            "\033":SpecialKey.escape
        ];
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
            (bg & ~Color.bright) + 10, // Background colors are normal + 10

            currentFontStyle & FontStyle.underline     ? UNDERLINE_ENABLE : UNDERLINE_DISABLE,
            currentFontStyle & FontStyle.strikethrough ? STRIKE_ENABLE    : STRIKE_DISABLE
        );
    }

    /**
     * Sets console foreground color
     *
     * Params:
     *  color = Foreground color to set
     */
    void foreground(Color color) @property
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
    void background(Color color) @property
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
    Color foreground() @property
    {
        return fg;
    }

    /**
     * Current console font color
     *
     * Returns:
     *  Current background color set
     */
    Color background() @property
    {
        return bg;
    }

    /**
     * Sets new console output stream
     *
     * Params:
     *  cos = New console output stream
     */
    void outputStream(ConsoleOutputStream cos) @property
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
    void fontStyle(FontStyle fs) @property
    {
        currentFontStyle = fs;
        printAnsi();
    }

    /**
     * Console size
     *
     * Returns:
     *  Tuple containing console rows and cols.
     */
    ConsolePoint size() @property
    {
        winsize w;
        terminal.ioctl(STDOUT_FILENO, terminal.TIOCGWINSZ, &w);

        return ConsolePoint(cast(int)w.ws_col, cast(int)w.ws_row);
    }

    /**
     * Sets console position
     *
     * Params:
     *  x = X coordinate of cursor postion
     *  y = Y coordinate of cursor position
     */
    void setCursorPos(int x, int y)
    {
        stdout.flush();
        writef("\033[%d;%df", y + 1, x + 1);
    }

    /**
     * Gets cursor position
     *
     * Returns:
     *  Cursor position
     */
    ConsolePoint cursorPos() @property
    {
        termios told, tnew;
        char[] buf;

        tcgetattr(0, &told);
        tnew = told;
        tnew.c_lflag &= ~ECHO & ~ICANON;
        tcsetattr(0, TCSANOW, &tnew);

        write("\033[6n");
        stdout.flush();
        foreach(i; 0..8)
        {
            char c;
            c = cast(char)getch();
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
     * Sets console title
     *
     * Params:
     *  title = Title to set
     */
    void title(string title) @property
    {
        stdout.flush();
        writef("\033]0;%s\007", title); // TODO: Check if supported
    }

    /**
     * Adds handler for console close event.
     *
     * Params:
     *  closeHandler = New close handler
     */
    void addCloseHandler(CloseHandler closeHandler)
    {
        closeHandlers ~= closeHandler;
    }

    /**
     * Moves cursor up by n rows
     *
     * Params:
     *  n = Number of rows to move
     */
    void moveCursorUp(int n = 1)
    {
        writef("\033[%dA", n);
    }

    /**
     * Moves cursor down by n rows
     *
     * Params:
     *  n = Number of rows to move
     */
    void moveCursorDown(int n = 1)
    {
        writef("\033[%dB", n);
    }

    /**
     * Moves cursor left by n columns
     *
     * Params:
     *  n = Number of columns to move
     */
    void moveCursorLeft(int n = 1)
    {
        writef("\033[%dD", n);
    }

    /**
     * Moves cursor right by n columns
     *
     * Params:
     *  n = Number of columns to move
     */
    void moveCursorRight(int n = 1)
    {
        writef("\033[%dC", n);
    }

    /**
     * Gets console mode
     *
     * Returns:
     *  Current console mode
     */
    ConsoleInputMode mode() @property
    {
        ConsoleInputMode cim;
        termios tio;
	ubyte[100] hack;

        tcgetattr(stdinFd, &tio);
        cim.echo = !!(tio.c_lflag & ECHO);
        cim.line = !!(tio.c_lflag & ICANON);

        return cim;
    }

    /**
     * Sets console mode
     *
     * Params:
     *  New console mode
     */
    void mode(ConsoleInputMode cim) @property
    {
        termios tio;
	ubyte[100] hack;

        tcgetattr(stdinFd, &tio);

        (cim.echo) ? (tio.c_lflag |= ECHO) : (tio.c_lflag &= ~ECHO);
        (cim.line) ? (tio.c_lflag |= ICANON) : (tio.c_lflag &= ~ICANON);
        tcsetattr(stdinFd, TCSANOW, &tio);
    }

    /**
     * Reads character without line buffering
     *
     * Params:
     *  echo = Print typed characters
     */
    int getch(bool echo = false)
    {
        import std.ascii : toUpper;

        int c;
        string buf;
        ConsoleInputMode m;

        m = mode;
        mode = ConsoleInputMode(echo, false);
        c = getchar();

        if(c == SpecialKey.escape)
        {
            while(kbhit())
            {
                buf ~= getchar();
            }
            writeln(buf);
            if(buf in specialKeys) {
                c = specialKeys[buf];
            } else {
                c = -1;
            }
        }

        mode = m;

        return c.toUpper();
    }

    /**
     * Checks if anykey is pressed.
     *
     * Shift, Ctrl and Alt keys are not detected.
     *
     * Returns:
     *  True if anykey is pressed, false otherwise.
     */
    bool kbhit()
    {
        ConsoleInputMode m;
        int c;
        int old;

        m = mode;
        mode = ConsoleInputMode.None;

        old = fcntl(STDIN_FILENO, F_GETFL, 0);
        fcntl(STDIN_FILENO, F_SETFL, old | O_NONBLOCK);

        c = getchar();

        fcntl(STDIN_FILENO, F_SETFL, old);
        mode = m;

        if(c != EOF)
        {
            ungetc(c, stdin.getFP);
            return true;
        }

        return false;
    }

    /**
     * Sets cursor visibility
     *
     * Params:
     *  visible = Cursor visibility
     */
    void cursorVisible(bool visible) @property
    {
        char c;
        if(visible)
            c = 'h';
        else
            c = 'l';

        writef("\033[?25%c", c);
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

        ce.isBlockable = (ce.type != CloseType.Other);

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
@property int width()
{
    return size.x;
}

/**
 * Console height
 *
 * Returns:
 *  Console height as number of rows
 */
@property int height()
{
    return size.y;
}


/**
 * Reads password from user
 *
 * Params:
 *  mask = Typed character mask
 *
 * Returns:
 *  Password
 */
string readPassword(char mask = '*')
{
    string pass;
    int c;

    version(Windows)
    {
        int backspace = 8;
        int enter = 13;
    }
    version(Posix)
    {
        int backspace = 127;
        int enter = 10;
    }

    while((c = getch()) != enter)
    {
        if(c == backspace) {
            if(pass.length > 0) {
                pass = pass[0..$-1];
                write("\b \b");
                stdout.flush();
            }
        } else {
            pass ~= cast(char)c;
            write(mask);
        }
    }

    return pass;
}


/**
 * Fills area with specified character
 *
 * Params:
 *  p1 = Top-Left corner coordinates of area
 *  p2 = Bottom-Right corner coordinates of area
 *  fill = Character to fill area
 */
void fillArea(ConsolePoint p1, ConsolePoint p2, char fill)
{
    foreach(i; p1.y .. p2.y + 1)
    {
        setCursorPos(p1.x, i);
        write( replicate((&fill)[0..1], p2.x - p1.x));
                                // ^ Converting char to char[]
        stdout.flush();
    }
}

/**
 * Draws box with specified border character
 *
 * Params:
 *  p1 = Top-Left corner coordinates of box
 *  p2 = Bottom-Right corner coordinates of box
 *  fill = Border character
 */
void drawBox(ConsolePoint p1, ConsolePoint p2, char border)
{
    drawHorizontalLine(p1, p2.x - p1.x, border);
    foreach(i; p1.y + 1 .. p2.y)
    {
        setCursorPos(p1.x, i);
        write(border);
        setCursorPos(p2.x - 1, i);
        write(border);
    }
    drawHorizontalLine(ConsolePoint(p1.x, p2.y), p2.x - p1.x, border);
}

/**
 * Draws horizontal line with specified fill character
 *
 * Params:
 *  pos = Start coordinates
 *  length = Line width
 *  border = Border character
 */
void drawHorizontalLine(ConsolePoint pos, int length, char border)
{
    setCursorPos(pos.x, pos.y);
    write(replicate((&border)[0..1], length));
}

/**
 * Draws horizontal line with specified fill character
 *
 * Params:
 *  pos = Start coordinates
 *  length = Line height
 *  border = Border character
 */
void drawVerticalLine(ConsolePoint pos, int length, char border)
{
    foreach(i; pos.y .. length)
    {
        setCursorPos(pos.x, i);
        write(border);
    }
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
    setCursorPos(point.x, point.y);
    write(data);
    stdout.flush();
}

/**
 * Clears console screen
 */
void clearScreen()
{
    auto size = size;
    short length = cast(short)(size.x * size.y); // Number of all characters to write
    setCursorPos(0, 0);

    write( std.array.replicate(" ", length));
    stdout.flush();
}

/**
 * Brings default colors back
 */
void resetColors()
{
    foreground = Color.initial;
    background = Color.initial;
}


/**
 * Brings font formatting to default
 */
void resetFontStyle()
{
    fontStyle = FontStyle.none;
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
 * Represents color theme.
 *
 * Examples:
 * ----
 * alias ThError = ColorTheme(Color.red, Color.black);
 * writeln(ThError("string to write using Error theme(red foreground on black background)"));
 * ----
 */
struct ColorTheme(Color fg, Color bg)
{
    string s;
    this(string s)
    {
        this.s = s;
    }

    void toString(scope void delegate(const(char)[]) sink) const
    {
        auto _fg = foreground;
        auto _bg = background;
        foreground = fg;
        background = bg;
        sink(s.dup);
        foreground = _fg;
        background = _bg;
    }
}


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
            foreground = param.val;
        } else static if(is(typeof(param) == Bg)) {
            background = param.val;
        } else static if(is(typeof(param) == FontStyle)) {
            fontStyle = param;
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
