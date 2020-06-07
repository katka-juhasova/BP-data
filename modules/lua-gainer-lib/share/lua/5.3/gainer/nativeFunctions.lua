local ffi = require("ffi")

--TODO: Support other Systems than GNU/Linux with glibc
ffi.cdef[[
static const int  B1200 =	    0000011;
static const int  B1800 =	    0000012;
static const int  B2400 =	    0000013;
static const int  B4800 =	    0000014;
static const int  B9600 =	    0000015;
static const int  B19200 =	  0000016;
static const int  B38400 =	  0000017;
static const int  B57600 =    0010001;
static const int  B115200 =   0010002;
static const int  B230400 =   0010003;
static const int  B460800 =   0010004;
static const int  B500000 =   0010005;
static const int  B576000 =   0010006;
static const int  B921600 =   0010007;
static const int  B1000000 =  0010010;
static const int  B1152000 =  0010011;
static const int  B1500000 =  0010012;
static const int  B2000000 =  0010013;
static const int  B2500000 =  0010014;
static const int  B3000000 =  0010015;
static const int  B3500000 =  0010016;
static const int  B4000000 =  0010017;
static const int __MAX_BAUD = B4000000;

static const int CSIZE =	0000060;
static const int   CS5 =	0000000;
static const int   CS6 =	0000020;
static const int   CS7 =	0000040;
static const int   CS8 =	0000060;
static const int CSTOPB =	0000100;
static const int CREAD =	0000200;
static const int PARENB =	0000400;
static const int PARODD =	0001000;
static const int HUPCL =	0002000;
static const int CLOCAL =	0004000;

typedef struct termios {
	unsigned int c_iflag;
	unsigned int c_oflag;
	unsigned int c_cflag;
	unsigned int c_lflag;
	unsigned char c_line;
	unsigned char c_cc[32];
	unsigned int c_ispeed;
	unsigned int c_ospeed;
}termios_t;

static const int	TCOOFF = 0;
static const int	TCOON =	 1;
static const int	TCIOFF = 2;
static const int	TCION =  3;

static const int	TCIFLUSH =	0;
static const int	TCOFLUSH =	1;
static const int	TCIOFLUSH =	2;

static const int	TCSANOW =		0;
static const int	TCSADRAIN =	1;
static const int	TCSAFLUSH =	2;

static const int O_RDONLY =	  00000000;
static const int O_WRONLY =	  00000001;
static const int O_RDWR =		  00000002;
static const int O_APPEND =   00002000;
static const int O_NONBLOCK = 00004000;


int open(const char *pathname, int flags);
int tcsetattr(int fd, int optional_actions, const struct termios *termios_p);
int tcgetattr (int fd, struct termios *termios_p);
int write(int fd, const void *buf, int count);
int read(int fd, void *buf, int count);


void Sleep(int ms);
int poll(struct pollfd *fds, unsigned long nfds, int timeout);
]]

local C=ffi.C

local nativeFunctions = {}
nativeFunctions.serial = {}

if ffi.os == "Windows" then
  function nativeFunctions.sleep(s)
    ffi.C.Sleep(s*1000)
  end
else
  function nativeFunctions.sleep(s)
    ffi.C.poll(nil, 0, s*1000)
  end
end

function nativeFunctions.serial.open(path, baud)
	nativeFunctions.serial.fileDescriptor = ffi.C.open(path, bit.bor(C.O_RDWR, C.O_NONBLOCK))
	if (nativeFunctions.serial.fileDescriptor < 0) then
		print("Error: opening "..path.." failed")
	end
  if (nativeFunctions.serial.fileDescriptor < 0) then
    return false
  end

  local termios = ffi.new("termios_t")
  if C.tcgetattr(nativeFunctions.serial.fileDescriptor, termios) < 0 then
   print("Error: tcgetattr failed")
   return false
  end
  termios.c_cflag = bit.bor(baud, C.CS8, C.CLOCAL, C.CREAD)
  termios.c_iflag = 0 --Turn off any data processing
  termios.c_oflag = 0
  termios.c_lflag = 0
  if (C.tcsetattr(nativeFunctions.serial.fileDescriptor, C.TCSANOW, termios) ~= 0) then
    print("Error: setting termios failed")
    return  false
  else
    return true
  end
end

function nativeFunctions.serial.write(data)
	if (nativeFunctions.serial.fileDescriptor < 0) then
		return false
	end
	return C.write(nativeFunctions.serial.fileDescriptor, data, #data)
end

function nativeFunctions.serial.read()
	local result = ""
	local bufferSize = 256
	local buffer = ffi.new("uint8_t[?]", bufferSize)
	local chunk
	while true do
		chunk = C.read(nativeFunctions.serial.fileDescriptor, buffer, bufferSize)
		if chunk <= 0 then
			break
		end
		result = result .. ffi.string(buffer, chunk)
	end
	return result
end

-- add C constants and functions
setmetatable(nativeFunctions.serial, { __index = C })

return nativeFunctions