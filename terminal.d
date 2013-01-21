// parts of this were taken from Robik's ConsoleD
// https://github.com/robik/ConsoleD/blob/master/consoled.d

// Uncomment this line to get a main() to demonstrate this module's
// capabilities.
//version = Demo

version(Windows) {
	import core.sys.windows.windows;
	import std.string : toStringz;
	private {
		enum RED_BIT = 4;
		enum GREEN_BIT = 2;
		enum BLUE_BIT = 1;
	}
}

version(Posix) {
	import core.sys.posix.termios;
	import core.sys.posix.unistd;
	import core.sys.posix.sys.types;
	import core.sys.posix.sys.time;
	import core.stdc.stdio;
	private {
		enum RED_BIT = 1;
		enum GREEN_BIT = 2;
		enum BLUE_BIT = 4;
	}

	extern(C) int ioctl(int, int, ...);
	enum int TIOCGWINSZ = 0x5413;
	struct winsize {
		ushort ws_row;
		ushort ws_col;
		ushort ws_xpixel;
		ushort ws_ypixel;
	}

	// I'm taking this from the minimal termcap from my Slackware box (which I use as my /etc/termcap) and just taking the most commonly used ones (for me anyway).

	// this way we'll have some definitions for 99% of typical PC cases even without any help from the local operating system

	enum string builtinTermcap = `
# Generic VT entry.
vg|vt-generic|Generic VT entries:\
	:bs:mi:ms:pt:xn:xo:it#8:\
	:RA=\E[?7l:SA=\E?7h:\
	:bl=^G:cr=^M:ta=^I:\
	:cm=\E[%i%d;%dH:\
	:le=^H:up=\E[A:do=\E[B:nd=\E[C:\
	:LE=\E[%dD:RI=\E[%dC:UP=\E[%dA:DO=\E[%dB:\
	:ho=\E[H:cl=\E[H\E[2J:ce=\E[K:cb=\E[1K:cd=\E[J:sf=\ED:sr=\EM:\
	:ct=\E[3g:st=\EH:\
	:cs=\E[%i%d;%dr:sc=\E7:rc=\E8:\
	:ei=\E[4l:ic=\E[@:IC=\E[%d@:al=\E[L:AL=\E[%dL:\
	:dc=\E[P:DC=\E[%dP:dl=\E[M:DL=\E[%dM:\
	:so=\E[7m:se=\E[m:us=\E[4m:ue=\E[m:\
	:mb=\E[5m:mh=\E[2m:md=\E[1m:mr=\E[7m:me=\E[m:\
	:sc=\E7:rc=\E8:kb=\177:\
	:ku=\E[A:kd=\E[B:kr=\E[C:kl=\E[D:


# Slackware 3.1 linux termcap entry (Sat Apr 27 23:03:58 CDT 1996):
lx|linux|console|con80x25|LINUX System Console:\
        :do=^J:co#80:li#25:cl=\E[H\E[J:sf=\ED:sb=\EM:\
        :le=^H:bs:am:cm=\E[%i%d;%dH:nd=\E[C:up=\E[A:\
        :ce=\E[K:cd=\E[J:so=\E[7m:se=\E[27m:us=\E[36m:ue=\E[m:\
        :md=\E[1m:mr=\E[7m:mb=\E[5m:me=\E[m:is=\E[1;25r\E[25;1H:\
        :ll=\E[1;25r\E[25;1H:al=\E[L:dc=\E[P:dl=\E[M:\
        :it#8:ku=\E[A:kd=\E[B:kr=\E[C:kl=\E[D:kb=^H:ti=\E[r\E[H:\
        :ho=\E[H:kP=\E[5~:kN=\E[6~:kH=\E[4~:kh=\E[1~:kD=\E[3~:kI=\E[2~:\
        :k1=\E[[A:k2=\E[[B:k3=\E[[C:k4=\E[[D:k5=\E[[E:k6=\E[17~:\
        :k7=\E[18~:k8=\E[19~:k9=\E[20~:k0=\E[21~:K1=\E[1~:K2=\E[5~:\
        :K4=\E[4~:K5=\E[6~:\
        :pt:sr=\EM:vt#3:xn:km:bl=^G:vi=\E[?25l:ve=\E[?25h:vs=\E[?25h:\
        :sc=\E7:rc=\E8:cs=\E[%i%d;%dr:\
        :r1=\Ec:r2=\Ec:r3=\Ec:

# Some other, commonly used linux console entries.
lx|con80x28:co#80:li#28:tc=linux:
lx|con80x43:co#80:li#43:tc=linux:
lx|con80x50:co#80:li#50:tc=linux:
lx|con100x37:co#100:li#37:tc=linux:
lx|con100x40:co#100:li#40:tc=linux:
lx|con132x43:co#132:li#43:tc=linux:

# vt102 - vt100 + insert line etc. VT102 does not have insert character.
v2|vt102|DEC vt102 compatible:\
	:co#80:li#24:\
	:ic@:IC@:\
	:is=\E[m\E[?1l\E>:\
	:rs=\E[m\E[?1l\E>:\
	:eA=\E)0:as=^N:ae=^O:ac=aaffggjjkkllmmnnooqqssttuuvvwwxx:\
	:ks=:ke=:\
	:k1=\EOP:k2=\EOQ:k3=\EOR:k4=\EOS:\
	:tc=vt-generic:

# vt100 - really vt102 without insert line, insert char etc.
vt|vt100|DEC vt100 compatible:\
	:im@:mi@:al@:dl@:ic@:dc@:AL@:DL@:IC@:DC@:\
	:tc=vt102:


# Entry for an xterm. Insert mode has been disabled.
vs|xterm|xterm-color|vs100|xterm terminal emulator (X Window System):\
	:am:bs:mi@:km:co#80:li#55:\
	:im@:ei@:\
	:ct=\E[3k:ue=\E[m:\
	:is=\E[m\E[?1l\E>:\
	:rs=\E[m\E[?1l\E>:\
	:eA=\E)0:as=^N:ae=^O:ac=aaffggjjkkllmmnnooqqssttuuvvwwxx:\
	:kI=\E[2~:kD=\E[3~:kP=\E[5~:kN=\E[6~:\
	:k1=\EOP:k2=\EOQ:k3=\EOR:k4=\EOS:k5=\E[15~:\
	:k6=\E[17~:k7=\E[18~:k8=\E[19~:k9=\E[20~:k0=\E[21~:\
	:F1=\E[23~:F2=\E[24~:\
	:kh=\E[H:kH=\E[F:\
	:ks=:ke=:\
	:te=\E[2J\E[?47l\E8:ti=\E7\E[?47h:\
	:tc=vt-generic:


#rxvt, added by me
rxvt|rxvt-unicode:\
	:am:bs:mi@:km:co#80:li#55:\
	:im@:ei@:\
	:ct=\E[3k:ue=\E[m:\
	:is=\E[m\E[?1l\E>:\
	:rs=\E[m\E[?1l\E>:\
	:eA=\E)0:as=^N:ae=^O:ac=aaffggjjkkllmmnnooqqssttuuvvwwxx:\
	:kI=\E[2~:kD=\E[3~:kP=\E[5~:kN=\E[6~:\
	:k1=\E[11~:k2=\E[12~:k3=\E[13~:k4=\E[14~:k5=\E[15~:\
	:k6=\E[17~:k7=\E[18~:k8=\E[19~:k9=\E[20~:k0=\E[21~:\
	:F1=\E[23~:F2=\E[24~:\
	:kh=\E[7~:kH=\E[8~:\
	:ks=:ke=:\
	:te=\E[2J\E[?47l\E8:ti=\E7\E[?47h:\
	:tc=vt-generic:


# Some other entries for the same xterm.
v2|xterms|vs100s|xterm small window:\
	:co#80:li#24:tc=xterm:
vb|xterm-bold|xterm with bold instead of underline:\
	:us=\E[1m:tc=xterm:
vi|xterm-ins|xterm with insert mode:\
	:mi:im=\E[4h:ei=\E[4l:tc=xterm:

Eterm|Eterm Terminal Emulator (X11 Window System):\
        :am:bw:eo:km:mi:ms:xn:xo:\
        :co#80:it#8:li#24:lm#0:pa#64:Co#8:AF=\E[3%dm:AB=\E[4%dm:op=\E[39m\E[49m:\
        :AL=\E[%dL:DC=\E[%dP:DL=\E[%dM:DO=\E[%dB:IC=\E[%d@:\
        :K1=\E[7~:K2=\EOu:K3=\E[5~:K4=\E[8~:K5=\E[6~:LE=\E[%dD:\
        :RI=\E[%dC:UP=\E[%dA:ae=^O:al=\E[L:as=^N:bl=^G:cd=\E[J:\
        :ce=\E[K:cl=\E[H\E[2J:cm=\E[%i%d;%dH:cr=^M:\
        :cs=\E[%i%d;%dr:ct=\E[3g:dc=\E[P:dl=\E[M:do=\E[B:\
        :ec=\E[%dX:ei=\E[4l:ho=\E[H:i1=\E[?47l\E>\E[?1l:ic=\E[@:\
        :im=\E[4h:is=\E[r\E[m\E[2J\E[H\E[?7h\E[?1;3;4;6l\E[4l:\
        :k1=\E[11~:k2=\E[12~:k3=\E[13~:k4=\E[14~:k5=\E[15~:\
        :k6=\E[17~:k7=\E[18~:k8=\E[19~:k9=\E[20~:kD=\E[3~:\
        :kI=\E[2~:kN=\E[6~:kP=\E[5~:kb=^H:kd=\E[B:ke=:kh=\E[7~:\
        :kl=\E[D:kr=\E[C:ks=:ku=\E[A:le=^H:mb=\E[5m:md=\E[1m:\
        :me=\E[m\017:mr=\E[7m:nd=\E[C:rc=\E8:\
        :sc=\E7:se=\E[27m:sf=^J:so=\E[7m:sr=\EM:st=\EH:ta=^I:\
        :te=\E[2J\E[?47l\E8:ti=\E7\E[?47h:ue=\E[24m:up=\E[A:\
        :us=\E[4m:vb=\E[?5h\E[?5l:ve=\E[?25h:vi=\E[?25l:\
        :ac=``aaffggiijjkkllmmnnooppqqrrssttuuvvwwxxyyzz{{||}}~~:

# DOS terminal emulator such as Telix or TeleMate.
# This probably also works for the SCO console, though it's incomplete.
an|ansi|ansi-bbs|ANSI terminals (emulators):\
	:co#80:li#24:am:\
	:is=:rs=\Ec:kb=^H:\
	:as=\E[m:ae=:eA=:\
	:ac=0\333+\257,\256.\031-\030a\261f\370g\361j\331k\277l\332m\300n\305q\304t\264u\303v\301w\302x\263~\025:\
	:kD=\177:kH=\E[Y:kN=\E[U:kP=\E[V:kh=\E[H:\
	:k1=\EOP:k2=\EOQ:k3=\EOR:k4=\EOS:k5=\EOT:\
	:k6=\EOU:k7=\EOV:k8=\EOW:k9=\EOX:k0=\EOY:\
	:tc=vt-generic:

	`;
}

enum Bright = 0x08;

enum Color : ushort {
	black = 0,
	red = RED_BIT,
	green = GREEN_BIT,
	yellow = red | green,
	blue = BLUE_BIT,
	magenta = red | blue,
	cyan = blue | green,
	white = red | green | blue
}

enum ConsoleInputFlags {
	raw = 0,
	echo = 1,
	mouse = 2,
	paste = 4,
}

enum ConsoleOutputType {
	linear = 0,
	cellular = 1,
}

// we could do it with termcap too, getenv("TERMCAP") then split on : and replace \E with \033 and get the pieces

struct Terminal {
	@disable this();
	@disable this(this);
	private ConsoleOutputType type;

	version(Posix) {
		bool terminalInFamily(string[] terms...) {
			import std.process;
			import std.string;
			auto term = getenv("TERM");
			foreach(t; terms)
				if(indexOf(term, t) != -1)
					return true;

			return false;
		}

		static string[string] termcapDatabase;
		static void readTermcapFile(bool useBuiltinTermcap = false) {
			import std.file;
			import std.stdio;
			import std.string;

			if(!exists("/etc/termcap"))
				useBuiltinTermcap = true;

			string current;

			void commitCurrentEntry() {
				if(current is null)
					return;

				string names = current;
				auto idx = indexOf(names, ":");
				if(idx != -1)
					names = names[0 .. idx];

				foreach(name; split(names, "|"))
					termcapDatabase[name] = current;

				current = null;
			}

			void handleTermcapLine(in char[] line) {
				if(line.length == 0) { // blank
					commitCurrentEntry();
					return; // continue
				}
				if(line[0] == '#') // comment
					return; // continue
				size_t termination = line.length;
				if(line[$-1] == '\\')
					termination--; // cut off the \\
				current ~= strip(line[0 .. termination]);
				// termcap entries must be on one logical line, so if it isn't continued, we know we're done
				if(line[$-1] != '\\')
					commitCurrentEntry();
			}

			if(useBuiltinTermcap) {
				foreach(line; splitLines(builtinTermcap)) {
					handleTermcapLine(line);
				}
			} else {
				foreach(line; File("/etc/termcap").byLine) {
					handleTermcapLine(line);
				}
			}
		}

		static string getTermcapDatabase(string terminal) {
			import std.string;

			if(termcapDatabase is null)
				readTermcapFile();

			auto data = terminal in termcapDatabase;
			if(data is null)
				return null;

			auto tc = *data;
			auto more = indexOf(tc, ":tc=");
			if(more != -1) {
				auto tcKey = tc[more + ":tc=".length .. $];
				auto end = indexOf(tcKey, ":");
				if(end != -1)
					tcKey = tcKey[0 .. end];
				tc = getTermcapDatabase(tcKey) ~ tc;
			}

			return tc;
		}

		string[string] termcap;
		void readTermcap() {
			import std.process;
			import std.string;
			import std.array;

			string termcapData = getenv("TERMCAP");
			if(termcapData.length == 0) {
				termcapData = getTermcapDatabase(getenv("TERM"));
			}

			auto e = replace(termcapData, "\\\n", "\n");
			termcap = null;

			foreach(part; split(e, ":")) {
				// FIXME: handle numeric things too

				auto things = split(part, "=");
				if(things.length)
					termcap[things[0]] =
						things.length > 1 ? things[1] : null;
			}
		}

		string findSequenceInTermcap(in char[] sequenceIn) {
			char[10] sequenceBuffer;
			char[] sequence;
			if(sequenceIn.length > 0 && sequenceIn[0] == '\033') {
				assert(sequenceIn.length < sequenceBuffer.length - 1);
				sequenceBuffer[1 .. sequenceIn.length + 1] = sequenceIn[];
				sequenceBuffer[0] = '\\';
				sequenceBuffer[1] = 'E';
				sequence = sequenceBuffer[0 .. sequenceIn.length + 1];
			} else {
				sequence = sequenceBuffer[1 .. sequenceIn.length + 1];
			}

			import std.array;
			foreach(k, v; termcap)
				if(v == sequence)
					return k;
			return null;
		}

		string getTermcap(string key) {
			auto k = key in termcap;
			if(k !is null) return *k;
			return null;
		}

		// Looks up a termcap item and tries to execute it. Returns false on failure
		bool doTermcap(T...)(string key, T t) {
			import std.conv;
			auto fs = getTermcap(key);
			if(fs is null)
				return false;

			int swapNextTwo = 0;

			R getArg(R)(int idx) {
				if(swapNextTwo == 2) {
					idx ++;
					swapNextTwo--;
				} else if(swapNextTwo == 1) {
					idx --;
					swapNextTwo--;
				}

				foreach(i, arg; t) {
					if(i == idx)
						return to!R(arg);
				}
				assert(0, to!string(idx) ~ " is out of bounds working " ~ fs);
			}

			char[256] buffer;
			int bufferPos = 0;

			void addChar(char c) {
				import std.exception;
				enforce(bufferPos < buffer.length);
				buffer[bufferPos++] = c;
			}

			void addString(in char[] c) {
				import std.exception;
				enforce(bufferPos + c.length < buffer.length);
				buffer[bufferPos .. bufferPos + c.length] = c[];
				bufferPos += c.length;
			}

			void addInt(int c, int minSize) {
				import std.string;
				auto str = format("%0"~(minSize ? to!string(minSize) : "")~"d", c);
				addString(str);
			}

			bool inPercent;
			int argPosition = 0;
			int incrementParams = 0;
			bool skipNext;
			bool nextIsChar;
			bool inBackslash;

			foreach(char c; fs) {
				if(inBackslash) {
					if(c == 'E')
						addChar('\033');
					else
						addChar(c);
					inBackslash = false;
				} else if(nextIsChar) {
					if(skipNext)
						skipNext = false;
					else
						addChar(cast(char) (c + getArg!int(argPosition) + (incrementParams ? 1 : 0)));
					if(incrementParams) incrementParams--;
					argPosition++;
					inPercent = false;
				} else if(inPercent) {
					switch(c) {
						case '%':
							addChar('%');
							inPercent = false;
						break;
						case '2':
						case '3':
						case 'd':
							if(skipNext)
								skipNext = false;
							else
								addInt(getArg!int(argPosition) + (incrementParams ? 1 : 0),
									c == 'd' ? 0 : (c - '0')
								);
							if(incrementParams) incrementParams--;
							argPosition++;
							inPercent = false;
						break;
						case '.':
							if(skipNext)
								skipNext = false;
							else
								addChar(cast(char) (getArg!int(argPosition) + (incrementParams ? 1 : 0)));
							if(incrementParams) incrementParams--;
							argPosition++;
						break;
						case '+':
							nextIsChar = true;
							inPercent = false;
						break;
						case 'i':
							incrementParams = 2;
							inPercent = false;
						break;
						case 's':
							skipNext = true;
							inPercent = false;
						break;
						case 'b':
							argPosition--;
							inPercent = false;
						break;
						case 'r':
							swapNextTwo = 2;
							inPercent = false;
						break;
						// FIXME: there's more
						// http://www.gnu.org/software/termutils/manual/termcap-1.3/html_mono/termcap.html

						default:
							assert(0, "not supported " ~ c);
					}
				} else {
					if(c == '%')
						inPercent = true;
					else if(c == '\\')
						inBackslash = true;
					else
						addChar(c);
				}
			}

			writeString(buffer[0 .. bufferPos]);
			return true;
		}
	}

	version(Posix)
	this(ConsoleOutputType type) {
		readTermcap();

		this.type = type;
		if(type == ConsoleOutputType.cellular) {
			doTermcap("ti");
		}
	}

	version(Windows)
		HANDLE hConsole;

	version(Windows)
	this(ConsoleOutputType type) {
		hConsole = GetStdHandle(STD_OUTPUT_HANDLE);
	}

	version(Posix)
	~this() {
		if(type == ConsoleOutputType.cellular) {
			doTermcap("te");
		}
		reset();
	}

	void color(int foreground, int background) {
		version(Windows) {
			// assuming a dark background on windows, so LowContrast == dark which means the bit is NOT set on hardware
			/*
			foreground ^= LowContrast;
			background ^= LowContrast;
			*/
			SetConsoleTextAttribute(
				GetStdHandle(STD_OUTPUT_HANDLE),
				cast(ushort)((background << 4) | foreground));
		} else {
			import std.process;
			// I started using this envvar for my text editor, but now use it elsewhere too
			// if we aren't set to dark, assume light
			/*
			if(getenv("ELVISBG") == "dark") {
				// LowContrast on dark bg menas
			} else {
				foreground ^= LowContrast;
				background ^= LowContrast;
			}
			*/

			writef("\033[%dm\033[3%dm\033[4%dm",
				(foreground & Bright) ? 1 : 0,
				cast(int) foreground & ~Bright,
				cast(int) background & ~Bright);
		}
	}

	void reset() {
		version(Windows)
			SetConsoleTextAttribute(
				GetStdHandle(STD_OUTPUT_HANDLE),
				cast(ushort)((Color.black << 4) | Color.white));
		else
			writef("\033[0m");
	}

	// FIXME: add moveRelative

	version(Posix)
	void moveTo(int x, int y) {
		doTermcap("cm", y, x);
	}

	version(Windows)
	void moveTo(int x, int y) {
		COORD coord = {cast(short) x, cast(short) y};
		SetConsoleCursorPosition(hConsole, coord);
	}

	RealTimeConsoleInput captureInput(ConsoleInputFlags flags) {
		return RealTimeConsoleInput(&this, flags);
	}

	void setTitle(string t) {
		version(Windows) {
			SetConsoleTitleA(toStringz(t));
		} else {
			if(terminalInFamily("xterm", "rxvt", "screen"))
				writef("\033]0;%s\007", t);
		}
	}

	void flush() {
		version(Posix)
			fflush(stdout);
	}

	int[] getSize() {
		version(Windows) {
			CONSOLE_SCREEN_BUFFER_INFO info;
			GetConsoleScreenBufferInfo( hConsole, &info );
        
			int cols, rows;
        
			cols = (info.srWindow.Right - info.srWindow.Left + 1);
			rows = (info.srWindow.Bottom - info.srWindow.Top + 1);

			return [cols, rows];
		} else {
			winsize w;
			ioctl(0, TIOCGWINSZ, &w);
			return [w.ws_col, w.ws_row];
		}
	}

	int width() {
		return getSize()[0];
	}

	int height() {
		return getSize()[1];
	}

	/*
	void write(T...)(T t) {
		import std.conv;
		foreach(arg; t) {
			writeString(to!string(arg));
		}
	}
	*/

	void writef(T...)(string f, T t) {
		import std.string;
		writeString(xformat(f, t));
	}

	void writeString(in char[] s) {
		// FIXME: make sure all the data is sent, check for errors
		version(Posix) {
			write(0, s.ptr, s.length);
		}

		version(Windows) {
			DWORD written;
			/* FIXME: WriteConsoleW */
			WriteConsoleA(hConsole, s.ptr, s.length, &written, null);
		}
	}

	/// Clears the screen.
	void clear() {
		version(Posix) {
			doTermcap("cl");
		} else version(Windows) {
			// TBD: copy the code from here and test it:
			// http://support.microsoft.com/kb/99261
			assert(0, "clear not yet implemented");
		}
	}
}

struct RealTimeConsoleInput {
	@disable this();
	@disable this(this);

	version(Posix) {
		private int fd;
		private termios old;
	}

	version(Windows) {
		private DWORD oldInput;
		private DWORD oldOutput;
		HANDLE inputHandle;
	}

	private ConsoleInputFlags flags;
	private Terminal* terminal;
	private void delegate()[] destructor;

	private this(Terminal* terminal, ConsoleInputFlags flags) {
		this.flags = flags;
		this.terminal = terminal;

		version(Windows) {
			inputHandle = GetStdHandle(STD_INPUT_HANDLE);

			GetConsoleMode(inputHandle, &oldInput);

			DWORD mode = 0;
			mode |= ENABLE_PROCESSED_INPUT /* 0x01 */; // this gives Ctrl+C which we probably want to be similar to linux
			mode |= ENABLE_WINDOW_INPUT /* 0208 */; // gives size etc
			if(flags & ConsoleInputFlags.echo)
				mode |= ENABLE_ECHO_INPUT; // 0x4
			if(flags & ConsoleInputFlags.mouse)
				mode |= ENABLE_MOUSE_INPUT; // 0x10
			// if(flags & ConsoleInputFlags.raw) // FIXME: maybe that should be a separate flag for ENABLE_LINE_INPUT

			SetConsoleMode(inputHandle, mode);
			destructor ~= { SetConsoleMode(inputHandle, oldInput); };


			GetConsoleMode(terminal.hConsole, &oldOutput);
			mode = 0;
			// we want this to match linux too
			mode |= ENABLE_PROCESSED_OUTPUT; /* 0x01 */
			mode |= ENABLE_WRAP_AT_EOL_OUTPUT; /* 0x02 */
			SetConsoleMode(terminal.hConsole, mode);
			destructor ~= { SetConsoleMode(terminal.hConsole, oldOutput); };

			// FIXME: change to UTF8 as well
		}

		version(Posix) {
			this.fd = 0; // stdin
			tcgetattr(fd, &old);
			auto n = old;

			auto f = ICANON;
			if(!(flags & ConsoleInputFlags.echo))
				f |= ECHO;

			n.c_lflag &= ~f;
			tcsetattr(fd, TCSANOW, &n);

			// some weird bug breaks this, https://github.com/robik/ConsoleD/issues/3
			//destructor ~= { tcsetattr(fd, TCSANOW, &old); };

			if(flags & ConsoleInputFlags.mouse) {
				if(terminal.terminalInFamily("xterm", "rxvt", "screen", "linux")) {
					terminal.writeString("\033[?1000h"); // this is vt200 mouse, supported by xterm and linux + gpm
					destructor ~= { terminal.writeString("\033[?1000l"); };
				}
			}
			if(flags & ConsoleInputFlags.paste) {
				if(terminal.terminalInFamily("xterm", "rxvt", "screen")) {
					terminal.writeString("\033[?2004h"); // bracketed paste mode
					destructor ~= { terminal.writeString("\033[?2004l"); };
				}
			}

			// try to ensure the terminal is in UTF-8 mode
			if(terminal.terminalInFamily("xterm", "screen", "linux")) {
				terminal.writeString("\033%G");
			}

			terminal.flush();
		}


		version(with_eventloop) {
			import arsd.eventloop;
			version(Windows)
				auto listenTo = inputHandle;
			else version(Posix)
				auto listenTo = this.fd;
			else static assert(0, "idk about this OS");

			addFileEventListeners(listenTo, (OsFileHandle fd) {
				auto queue = readNextEvents();
				foreach(event; queue)
					send(event);
			}, null, null);

			destructor ~= { removeFileEventListeners(listenTo); };
		}
	}

	~this() {
		// the delegate thing doesn't actually work for this... for some reason
		version(Posix)
			tcsetattr(fd, TCSANOW, &old);
		// we're just undoing everything the constructor did, in reverse order, same criteria
		foreach_reverse(d; destructor)
			d();
	}

	bool kbhit() {
		return timedCheckForInput(0);
	}

	version(Windows)
	bool timedCheckForInput(int milliseconds) {
		auto response = WaitForSingleObject(terminal.hConsole, milliseconds);
		if(response  == 0)
			return true; // the object is ready
		return false;
	}

	version(Posix)
	bool timedCheckForInput(int milliseconds) {
		timeval tv;
		tv.tv_sec = 0;
		tv.tv_usec = milliseconds * 1000;

		fd_set fs;
		FD_ZERO(&fs);

		FD_SET(fd, &fs);
		select(fd + 1, &fs, null, null, &tv);

		return FD_ISSET(fd, &fs);
	}

	char getch() {
		import core.stdc.stdio;
		return cast(char) fgetc(stdin);
	}

	//char[128] inputBuffer;
	//int inputBufferPosition;
	version(Posix)
	int nextRaw() {
		char[1] buf;
		auto ret = read(fd, buf.ptr, buf.length);
		if(ret == 0)
			return 0; // input closed
		if(ret == -1)
			throw new Exception("read failed");

		//terminal.writef("RAW READ: %d\n", buf[0]);

		if(ret == 1)
			return buf[0];
		else
			assert(0); // read too much, should be impossible
	}

	version(Posix)
	dchar nextChar(int starting) {
		if(starting <= 127)
			return cast(dchar) starting;
		char[6] buffer;
		int pos = 0;
		buffer[pos++] = cast(char) starting;

		// see the utf-8 encoding for details
		int remaining = 0;
		ubyte magic = starting & 0xff;
		while(magic & 0b1000_000) {
			remaining++;
			magic <<= 1;
		}

		while(remaining && pos < buffer.length) {
			buffer[pos++] = cast(char) nextRaw();
			remaining--;
		}

		import std.utf;
		size_t throwAway; // it insists on the index but we don't care
		return decode(buffer, throwAway);
	}

	// character event
	// non-character key event
	// paste event
	// mouse event
	// size event maybe, and if appropriate focus events
	InputEvent nextEvent() {
		if(inputQueue.length) {
			auto e = inputQueue[0];
			inputQueue = inputQueue[1 .. $];
			return e;
		}

		auto more = readNextEvents();
		while(!more.length)
			more = readNextEvents();
		assert(more.length);

		auto e = more[0];
		inputQueue = more[1 .. $];
		return e;
	}

	InputEvent* peekNextEvent() {
		if(inputQueue.length)
			return &(inputQueue[0]);
		return null;
	}

	enum InjectionPosition { head, tail }
	void injectEvent(InputEvent ev, InjectionPosition where) {
		final switch(where) {
			case InjectionPosition.head:
				inputQueue = ev ~ inputQueue;
			break;
			case InjectionPosition.tail:
				inputQueue ~= ev;
			break;
		}
	}

	InputEvent[] inputQueue;

	version(Windows)
	InputEvent[] readNextEvents() {
		INPUT_RECORD[32] buffer;
		DWORD actuallyRead;
			// FIXME: ReadConsoleInputW
		auto success = ReadConsoleInputA(inputHandle, buffer.ptr, buffer.length, &actuallyRead);
		if(success == 0)
			throw new Exception("ReadConsoleInput");

		InputEvent[] newEvents;
		foreach(record; buffer[0 .. actuallyRead]) {
			switch(record.EventType) {
				case KEY_EVENT:
					auto ev = record.KeyEvent;
					CharacterEvent e;
					NonCharacterKeyEvent ne;

					e.eventType = ev.bKeyDown ? CharacterEvent.Type.Pressed : CharacterEvent.Type.Released;
					ne.eventType = ev.bKeyDown ? NonCharacterKeyEvent.Type.Pressed : NonCharacterKeyEvent.Type.Released;

					// FIXME standardize
					e.modifierState = ev.dwControlKeyState;
					ne.modifierState = ev.dwControlKeyState;

					if(ev.UnicodeChar) {
						e.character = cast(dchar) cast(wchar) ev.UnicodeChar;
						newEvents ~= InputEvent(e);
					} else {
						// FIXME actually translate
						ne.key = cast(NonCharacterKeyEvent.Key) ev.wVirtualKeyCode;
						newEvents ~= InputEvent(ne);
					}
				break;
				case MOUSE_EVENT:
					auto ev = record.MouseEvent;
					MouseEvent e;

					e.modifierState = ev.dwControlKeyState;
					e.x = ev.dwMousePosition.X;
					e.y = ev.dwMousePosition.Y;

					switch(ev.dwEventFlags) {
						case 0:
							//press
							e.eventType = MouseEvent.Type.Pressed;
							e.buttons = ev.dwButtonState;
						break;
						case MOUSE_MOVED:
							e.eventType = MouseEvent.Type.Moved;
							e.buttons = ev.dwButtonState;
						break;
						case 0x0004/*MOUSE_WHEELED*/:
							e.eventType = MouseEvent.Type.Pressed;
							if(ev.dwButtonState > 0)
								e.buttons = MouseEvent.Button.ScrollDown;
							else
								e.buttons = MouseEvent.Button.ScrollUp;
						break;
					}

					newEvents ~= InputEvent(e);
				break;
				case WINDOW_BUFFER_SIZE_EVENT:
					auto ev = record.WindowBufferSizeEvent;
					// FIXME
				break;
				default:
					// ignore
			}
		}

		return newEvents;
	}

	version(Posix)
	InputEvent[] readNextEvents() {
		InputEvent[] charPressAndRelease(dchar character) {
			return [
				InputEvent(CharacterEvent(CharacterEvent.Type.Pressed, character, 0)),
				InputEvent(CharacterEvent(CharacterEvent.Type.Released, character, 0)),
			];
		}
		InputEvent[] keyPressAndRelease(NonCharacterKeyEvent.Key key) {
			return [
				InputEvent(NonCharacterKeyEvent(NonCharacterKeyEvent.Type.Pressed, key, 0)),
				InputEvent(NonCharacterKeyEvent(NonCharacterKeyEvent.Type.Released, key, 0)),
			];
		}

		// this assumes you just read "\033["
		char[] readEscapeSequence() {
			char[30] sequence;
			int sequenceLength = 2;
			sequence[0] = '\033';
			sequence[1] = '[';

			while(sequenceLength < sequence.length) {
				auto n = nextRaw();
				sequence[sequenceLength++] = cast(char) n;
				if(n >= 0x40)
					break;
			}

			return sequence[0 .. sequenceLength];
		}

		InputEvent[] translateTermcapName(string cap) {
			switch(cap) {
				//case "k0":
					//return keyPressAndRelease(NonCharacterKeyEvent.Key.F1);
				case "k1":
					return keyPressAndRelease(NonCharacterKeyEvent.Key.F1);
				case "k2":
					return keyPressAndRelease(NonCharacterKeyEvent.Key.F2);
				case "k3":
					return keyPressAndRelease(NonCharacterKeyEvent.Key.F3);
				case "k4":
					return keyPressAndRelease(NonCharacterKeyEvent.Key.F4);
				case "k5":
					return keyPressAndRelease(NonCharacterKeyEvent.Key.F5);
				case "k6":
					return keyPressAndRelease(NonCharacterKeyEvent.Key.F6);
				case "k7":
					return keyPressAndRelease(NonCharacterKeyEvent.Key.F7);
				case "k8":
					return keyPressAndRelease(NonCharacterKeyEvent.Key.F8);
				case "k9":
					return keyPressAndRelease(NonCharacterKeyEvent.Key.F9);
				case "k;":
				case "k0":
					return keyPressAndRelease(NonCharacterKeyEvent.Key.F10);
				case "F1":
					return keyPressAndRelease(NonCharacterKeyEvent.Key.F11);
				case "F2":
					return keyPressAndRelease(NonCharacterKeyEvent.Key.F12);


				case "kb":
					return charPressAndRelease('\b');
				case "kD":
					return keyPressAndRelease(NonCharacterKeyEvent.Key.Delete);

				case "kd":
				case "do":
					return keyPressAndRelease(NonCharacterKeyEvent.Key.DownArrow);
				case "ku":
				case "up":
					return keyPressAndRelease(NonCharacterKeyEvent.Key.UpArrow);
				case "kl":
					return keyPressAndRelease(NonCharacterKeyEvent.Key.LeftArrow);
				case "kr":
				case "nd":
					return keyPressAndRelease(NonCharacterKeyEvent.Key.RightArrow);

				case "kN":
					return keyPressAndRelease(NonCharacterKeyEvent.Key.PageDown);
				case "kP":
					return keyPressAndRelease(NonCharacterKeyEvent.Key.PageUp);

				case "kh":
					return keyPressAndRelease(NonCharacterKeyEvent.Key.Home);
				case "kH":
					return keyPressAndRelease(NonCharacterKeyEvent.Key.End);
				case "kI":
					return keyPressAndRelease(NonCharacterKeyEvent.Key.Insert);
				default:
					// don't know it, just ignore
					//import std.stdio;
					//writeln(cap);
			}

			return null;
		}


		InputEvent[] doEscapeSequence(in char[] sequence) {
			switch(sequence) {
				case "\033[200~":
					// bracketed paste begin
					// we want to keep reading until
					// "\033[201~":
					// and build a paste event out of it


					string data;
					for(;;) {
						auto n = nextRaw();
						if(n == '\033') {
							n = nextRaw();
							if(n == '[') {
								auto esc = readEscapeSequence();
								if(esc == "\033[201~") {
									// complete!
									break;
								} else {
									// was something else apparently, but it is pasted, so keep it
									data ~= esc;
								}
							} else {
								data ~= '\033';
								data ~= cast(char) n;
							}
						} else {
							data ~= cast(char) n;
						}
					}
					return [InputEvent(PasteEvent(data))];
				break;
				case "\033[M":
					// mouse event
					auto buttonCode = nextRaw();
						// nextChar is commented because i'm not using UTF-8 mouse mode
						// cuz i don't think it is as widely supported
					auto x = cast(int) (/*nextChar*/(nextRaw())) - 33; /* they encode value + 32, but make upper left 1,1. I want it to be 0,0 */
					auto y = cast(int) (/*nextChar*/(nextRaw())) - 33; /* ditto */


					bool isRelease = (buttonCode & 0b11) == 3;
					int buttonNumber;
					if(!isRelease) {
						buttonNumber = (buttonCode & 0b11);
						if(buttonCode & 64)
							buttonNumber += 3; // button 4 and 5 are sent as like button 1 and 2, but code | 64
							// so button 1 == button 4 here

						// note: buttonNumber == 0 means button 1 at this point
						buttonNumber++; // hence this
					}

					auto modifiers = buttonCode & (0b0001_1100);
						// 4 == shift
						// 8 == meta
						// 16 == control

					MouseEvent m;
					m.eventType = isRelease ? MouseEvent.Type.Released : MouseEvent.Type.Pressed;
					if(buttonNumber == 0)
						m.buttons = 0; // we don't actually know
					else
						m.buttons = 1 << (buttonNumber - 1); // I prefer flags so that's how we do it
					m.x = x;
					m.y = y;
					m.modifierState = modifiers; // FIXME, standardize

					return [InputEvent(m)];
				break;
				default:
					// look it up in the termcap key database
					auto cap = terminal.findSequenceInTermcap(sequence);
					if(cap !is null)
						return translateTermcapName(cap);
			}

			return null;
		}

		auto c = nextRaw();
		if(c == '\033') {
			if(timedCheckForInput(50)) {
				// escape sequence
				c = nextRaw();
				if(c == '[') { // CSI, ends on anything >= 'A'
					return doEscapeSequence(readEscapeSequence());
				} else if(c == 'O') {
					// could be xterm function key
					auto n = nextRaw();

					char[3] thing;
					thing[0] = '\033';
					thing[1] = 'O';
					thing[2] = cast(char) n;

					auto cap = terminal.findSequenceInTermcap(thing);
					if(cap is null) {
						return charPressAndRelease('\033') ~
							charPressAndRelease('O') ~
							charPressAndRelease(thing[2]);
					} else {
						return translateTermcapName(cap);
					}
				} else {
					// I don't know, probably unsupported terminal or just quick user input or something
					return charPressAndRelease('\033') ~ charPressAndRelease(nextChar(c));
				}
			} else {
				// user hit escape (or super slow escape sequence, but meh)
				return keyPressAndRelease(NonCharacterKeyEvent.Key.escape);
			}
		} else {
			// FIXME: what if it is neither? we should check the termcap
			return charPressAndRelease(nextChar(c));
		}
	}
}

struct CharacterEvent {
	enum Type { Pressed, Released }

	Type eventType;
	dchar character;
	uint modifierState;
}

struct NonCharacterKeyEvent {
	enum Type { Pressed, Released}
	Type eventType;

	// these match Windows virtual key codes numerically for simplicity of translation there
	//http://msdn.microsoft.com/en-us/library/windows/desktop/dd375731%28v=vs.85%29.aspx
	enum Key : int {
		escape = 0x1b,
		F1 = 0x70,
		F2 = 0x71,
		F3 = 0x72,
		F4 = 0x73,
		F5 = 0x74,
		F6 = 0x75,
		F7 = 0x76,
		F8 = 0x77,
		F9 = 0x78,
		F10 = 0x79,
		F11 = 0x7A,
		F12 = 0x7B,
		LeftArrow = 0x25,
		RightArrow = 0x27,
		UpArrow = 0x26,
		DownArrow = 0x28,
		Insert = 0x2d,
		Delete = 0x2e,
		Home = 0x24,
		End = 0x23,
		PageUp = 0x21,
		PageDown = 0x22,
		}
	Key key;

	uint modifierState;

}

struct PasteEvent {
	string pastedText;
}

struct MouseEvent {
	enum Type { Pressed, Released, Clicked, Moved }
	Type eventType;

	enum Button : uint { None = 0, Left = 1, Middle = 4, Right = 2, ScrollUp = 8, ScrollDown = 16 }
	uint buttons;
	int x;
	int y;
	uint modifierState; // shift, ctrl, alt, meta, altgr
}

interface CustomEvent {}

struct InputEvent {
	enum Type { CharacterEvent, NonCharacterKeyEvent, PasteEvent, MouseEvent, CustomEvent }

	@property Type type() { return t; }

	auto get(Type T)() {
		if(type != T)
			throw new Exception("Wrong event type");
		static if(T == Type.CharacterEvent)
			return characterEvent;
		else static if(T == Type.NonCharacterKeyEvent)
			return nonCharacterKeyEvent;
		else static if(T == Type.PasteEvent)
			return pasteEvent;
		else static if(T == Type.MouseEvent)
			return mouseEvent;
		else static if(T == Type.CustomEvent)
			return customEvent;
		else static assert(0, "Type " ~ T.stringof ~ " not added to the get function");
	}

	private {
		this(CharacterEvent c) {
			t = Type.CharacterEvent;
			characterEvent = c;
		}
		this(NonCharacterKeyEvent c) {
			t = Type.NonCharacterKeyEvent;
			nonCharacterKeyEvent = c;
		}
		this(PasteEvent c) {
			t = Type.PasteEvent;
			pasteEvent = c;
		}
		this(MouseEvent c) {
			t = Type.MouseEvent;
			mouseEvent = c;
		}
		this(CustomEvent c) {
			t = Type.CustomEvent;
			customEvent = c;
		}

		Type t;

		union {
			CharacterEvent characterEvent;
			NonCharacterKeyEvent nonCharacterKeyEvent;
			PasteEvent pasteEvent;
			MouseEvent mouseEvent;
			CustomEvent customEvent;
		}
	}
}

version(Demo)
void main() {
	auto terminal = Terminal(ConsoleOutputType.cellular);

	terminal.setTitle("Basic I/O");
	auto input = terminal.captureInput(ConsoleInputFlags.raw | ConsoleInputFlags.mouse | ConsoleInputFlags.paste);

	terminal.color(Color.green | Bright, Color.black);

	int centerX = terminal.width / 2;
	int centerY = terminal.height / 2;

	bool timeToBreak = false;

	void handleEvent(InputEvent event) {
		terminal.writef("%s\n", event.type);
		final switch(event.type) {
			case InputEvent.Type.CharacterEvent:
				auto ev = event.get!(InputEvent.Type.CharacterEvent);
				terminal.writef("\t%s\n", ev);
				if(ev.character == 'Q') {
					timeToBreak = true;
					version(with_eventloop) {
						import arsd.eventloop;
						exit();
					}
				}
			break;
			case InputEvent.Type.NonCharacterKeyEvent:
				terminal.writef("\t%s\n", event.get!(InputEvent.Type.NonCharacterKeyEvent));
			break;
			case InputEvent.Type.PasteEvent:
				terminal.writef("\t%s\n", event.get!(InputEvent.Type.PasteEvent));
			break;
			case InputEvent.Type.MouseEvent:
				terminal.writef("\t%s\n", event.get!(InputEvent.Type.MouseEvent));
			break;
			case InputEvent.Type.CustomEvent:
			break;
		}

		/*
		if(input.kbhit()) {
			auto c = input.getch();
			if(c == 'q' || c == 'Q')
				break;
			terminal.moveTo(centerX, centerY);
			terminal.writef("%c", c);
			terminal.flush();
		}
		usleep(10000);
		*/
	}

	version(with_eventloop) {
		import arsd.eventloop;
		addListener(&handleEvent);
		loop();
	} else {
		loop: while(true) {
			auto event = input.nextEvent();
			handleEvent(event);
			if(timeToBreak)
				break loop;
		}
	}
}

