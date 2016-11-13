
obj/kern/kernel：     文件格式 elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4                   	.byte 0xe4

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 40 11 00       	mov    $0x114000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 40 11 f0       	mov    $0xf0114000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/pmap.h>
#include <kern/kclock.h>

void
i386_init(void)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	83 ec 0c             	sub    $0xc,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100046:	b8 50 69 11 f0       	mov    $0xf0116950,%eax
f010004b:	2d 00 63 11 f0       	sub    $0xf0116300,%eax
f0100050:	50                   	push   %eax
f0100051:	6a 00                	push   $0x0
f0100053:	68 00 63 11 f0       	push   $0xf0116300
f0100058:	e8 62 31 00 00       	call   f01031bf <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 96 04 00 00       	call   f01004f8 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 60 36 10 f0       	push   $0xf0103660
f010006f:	e8 92 26 00 00       	call   f0102706 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 e7 0f 00 00       	call   f0101060 <mem_init>
f0100079:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f010007c:	83 ec 0c             	sub    $0xc,%esp
f010007f:	6a 00                	push   $0x0
f0100081:	e8 07 07 00 00       	call   f010078d <monitor>
f0100086:	83 c4 10             	add    $0x10,%esp
f0100089:	eb f1                	jmp    f010007c <i386_init+0x3c>

f010008b <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f010008b:	55                   	push   %ebp
f010008c:	89 e5                	mov    %esp,%ebp
f010008e:	56                   	push   %esi
f010008f:	53                   	push   %ebx
f0100090:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100093:	83 3d 40 69 11 f0 00 	cmpl   $0x0,0xf0116940
f010009a:	75 37                	jne    f01000d3 <_panic+0x48>
		goto dead;
	panicstr = fmt;
f010009c:	89 35 40 69 11 f0    	mov    %esi,0xf0116940

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f01000a2:	fa                   	cli    
f01000a3:	fc                   	cld    

	va_start(ap, fmt);
f01000a4:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000a7:	83 ec 04             	sub    $0x4,%esp
f01000aa:	ff 75 0c             	pushl  0xc(%ebp)
f01000ad:	ff 75 08             	pushl  0x8(%ebp)
f01000b0:	68 7b 36 10 f0       	push   $0xf010367b
f01000b5:	e8 4c 26 00 00       	call   f0102706 <cprintf>
	vcprintf(fmt, ap);
f01000ba:	83 c4 08             	add    $0x8,%esp
f01000bd:	53                   	push   %ebx
f01000be:	56                   	push   %esi
f01000bf:	e8 1c 26 00 00       	call   f01026e0 <vcprintf>
	cprintf("\n");
f01000c4:	c7 04 24 9c 45 10 f0 	movl   $0xf010459c,(%esp)
f01000cb:	e8 36 26 00 00       	call   f0102706 <cprintf>
	va_end(ap);
f01000d0:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000d3:	83 ec 0c             	sub    $0xc,%esp
f01000d6:	6a 00                	push   $0x0
f01000d8:	e8 b0 06 00 00       	call   f010078d <monitor>
f01000dd:	83 c4 10             	add    $0x10,%esp
f01000e0:	eb f1                	jmp    f01000d3 <_panic+0x48>

f01000e2 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01000e2:	55                   	push   %ebp
f01000e3:	89 e5                	mov    %esp,%ebp
f01000e5:	53                   	push   %ebx
f01000e6:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f01000e9:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f01000ec:	ff 75 0c             	pushl  0xc(%ebp)
f01000ef:	ff 75 08             	pushl  0x8(%ebp)
f01000f2:	68 93 36 10 f0       	push   $0xf0103693
f01000f7:	e8 0a 26 00 00       	call   f0102706 <cprintf>
	vcprintf(fmt, ap);
f01000fc:	83 c4 08             	add    $0x8,%esp
f01000ff:	53                   	push   %ebx
f0100100:	ff 75 10             	pushl  0x10(%ebp)
f0100103:	e8 d8 25 00 00       	call   f01026e0 <vcprintf>
	cprintf("\n");
f0100108:	c7 04 24 9c 45 10 f0 	movl   $0xf010459c,(%esp)
f010010f:	e8 f2 25 00 00       	call   f0102706 <cprintf>
	va_end(ap);
}
f0100114:	83 c4 10             	add    $0x10,%esp
f0100117:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010011a:	c9                   	leave  
f010011b:	c3                   	ret    

f010011c <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f010011c:	55                   	push   %ebp
f010011d:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010011f:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100124:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100125:	a8 01                	test   $0x1,%al
f0100127:	74 0b                	je     f0100134 <serial_proc_data+0x18>
f0100129:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010012e:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f010012f:	0f b6 c0             	movzbl %al,%eax
f0100132:	eb 05                	jmp    f0100139 <serial_proc_data+0x1d>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100134:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f0100139:	5d                   	pop    %ebp
f010013a:	c3                   	ret    

f010013b <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010013b:	55                   	push   %ebp
f010013c:	89 e5                	mov    %esp,%ebp
f010013e:	53                   	push   %ebx
f010013f:	83 ec 04             	sub    $0x4,%esp
f0100142:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100144:	eb 2b                	jmp    f0100171 <cons_intr+0x36>
		if (c == 0)
f0100146:	85 c0                	test   %eax,%eax
f0100148:	74 27                	je     f0100171 <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f010014a:	8b 0d 24 65 11 f0    	mov    0xf0116524,%ecx
f0100150:	8d 51 01             	lea    0x1(%ecx),%edx
f0100153:	89 15 24 65 11 f0    	mov    %edx,0xf0116524
f0100159:	88 81 20 63 11 f0    	mov    %al,-0xfee9ce0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f010015f:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100165:	75 0a                	jne    f0100171 <cons_intr+0x36>
			cons.wpos = 0;
f0100167:	c7 05 24 65 11 f0 00 	movl   $0x0,0xf0116524
f010016e:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f0100171:	ff d3                	call   *%ebx
f0100173:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100176:	75 ce                	jne    f0100146 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f0100178:	83 c4 04             	add    $0x4,%esp
f010017b:	5b                   	pop    %ebx
f010017c:	5d                   	pop    %ebp
f010017d:	c3                   	ret    

f010017e <kbd_proc_data>:
f010017e:	ba 64 00 00 00       	mov    $0x64,%edx
f0100183:	ec                   	in     (%dx),%al
	int c;
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
f0100184:	a8 01                	test   $0x1,%al
f0100186:	0f 84 f8 00 00 00    	je     f0100284 <kbd_proc_data+0x106>
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
f010018c:	a8 20                	test   $0x20,%al
f010018e:	0f 85 f6 00 00 00    	jne    f010028a <kbd_proc_data+0x10c>
f0100194:	ba 60 00 00 00       	mov    $0x60,%edx
f0100199:	ec                   	in     (%dx),%al
f010019a:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f010019c:	3c e0                	cmp    $0xe0,%al
f010019e:	75 0d                	jne    f01001ad <kbd_proc_data+0x2f>
		// E0 escape character
		shift |= E0ESC;
f01001a0:	83 0d 00 63 11 f0 40 	orl    $0x40,0xf0116300
		return 0;
f01001a7:	b8 00 00 00 00       	mov    $0x0,%eax
f01001ac:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01001ad:	55                   	push   %ebp
f01001ae:	89 e5                	mov    %esp,%ebp
f01001b0:	53                   	push   %ebx
f01001b1:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f01001b4:	84 c0                	test   %al,%al
f01001b6:	79 36                	jns    f01001ee <kbd_proc_data+0x70>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01001b8:	8b 0d 00 63 11 f0    	mov    0xf0116300,%ecx
f01001be:	89 cb                	mov    %ecx,%ebx
f01001c0:	83 e3 40             	and    $0x40,%ebx
f01001c3:	83 e0 7f             	and    $0x7f,%eax
f01001c6:	85 db                	test   %ebx,%ebx
f01001c8:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01001cb:	0f b6 d2             	movzbl %dl,%edx
f01001ce:	0f b6 82 00 38 10 f0 	movzbl -0xfefc800(%edx),%eax
f01001d5:	83 c8 40             	or     $0x40,%eax
f01001d8:	0f b6 c0             	movzbl %al,%eax
f01001db:	f7 d0                	not    %eax
f01001dd:	21 c8                	and    %ecx,%eax
f01001df:	a3 00 63 11 f0       	mov    %eax,0xf0116300
		return 0;
f01001e4:	b8 00 00 00 00       	mov    $0x0,%eax
f01001e9:	e9 a4 00 00 00       	jmp    f0100292 <kbd_proc_data+0x114>
	} else if (shift & E0ESC) {
f01001ee:	8b 0d 00 63 11 f0    	mov    0xf0116300,%ecx
f01001f4:	f6 c1 40             	test   $0x40,%cl
f01001f7:	74 0e                	je     f0100207 <kbd_proc_data+0x89>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f01001f9:	83 c8 80             	or     $0xffffff80,%eax
f01001fc:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f01001fe:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100201:	89 0d 00 63 11 f0    	mov    %ecx,0xf0116300
	}

	shift |= shiftcode[data];
f0100207:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f010020a:	0f b6 82 00 38 10 f0 	movzbl -0xfefc800(%edx),%eax
f0100211:	0b 05 00 63 11 f0    	or     0xf0116300,%eax
f0100217:	0f b6 8a 00 37 10 f0 	movzbl -0xfefc900(%edx),%ecx
f010021e:	31 c8                	xor    %ecx,%eax
f0100220:	a3 00 63 11 f0       	mov    %eax,0xf0116300

	c = charcode[shift & (CTL | SHIFT)][data];
f0100225:	89 c1                	mov    %eax,%ecx
f0100227:	83 e1 03             	and    $0x3,%ecx
f010022a:	8b 0c 8d e0 36 10 f0 	mov    -0xfefc920(,%ecx,4),%ecx
f0100231:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0100235:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100238:	a8 08                	test   $0x8,%al
f010023a:	74 1b                	je     f0100257 <kbd_proc_data+0xd9>
		if ('a' <= c && c <= 'z')
f010023c:	89 da                	mov    %ebx,%edx
f010023e:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100241:	83 f9 19             	cmp    $0x19,%ecx
f0100244:	77 05                	ja     f010024b <kbd_proc_data+0xcd>
			c += 'A' - 'a';
f0100246:	83 eb 20             	sub    $0x20,%ebx
f0100249:	eb 0c                	jmp    f0100257 <kbd_proc_data+0xd9>
		else if ('A' <= c && c <= 'Z')
f010024b:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f010024e:	8d 4b 20             	lea    0x20(%ebx),%ecx
f0100251:	83 fa 19             	cmp    $0x19,%edx
f0100254:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100257:	f7 d0                	not    %eax
f0100259:	a8 06                	test   $0x6,%al
f010025b:	75 33                	jne    f0100290 <kbd_proc_data+0x112>
f010025d:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f0100263:	75 2b                	jne    f0100290 <kbd_proc_data+0x112>
		cprintf("Rebooting!\n");
f0100265:	83 ec 0c             	sub    $0xc,%esp
f0100268:	68 ad 36 10 f0       	push   $0xf01036ad
f010026d:	e8 94 24 00 00       	call   f0102706 <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100272:	ba 92 00 00 00       	mov    $0x92,%edx
f0100277:	b8 03 00 00 00       	mov    $0x3,%eax
f010027c:	ee                   	out    %al,(%dx)
f010027d:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100280:	89 d8                	mov    %ebx,%eax
f0100282:	eb 0e                	jmp    f0100292 <kbd_proc_data+0x114>
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
f0100284:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100289:	c3                   	ret    
	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
		return -1;
f010028a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010028f:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100290:	89 d8                	mov    %ebx,%eax
}
f0100292:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100295:	c9                   	leave  
f0100296:	c3                   	ret    

f0100297 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100297:	55                   	push   %ebp
f0100298:	89 e5                	mov    %esp,%ebp
f010029a:	57                   	push   %edi
f010029b:	56                   	push   %esi
f010029c:	53                   	push   %ebx
f010029d:	83 ec 1c             	sub    $0x1c,%esp
f01002a0:	89 c7                	mov    %eax,%edi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01002a2:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002a7:	be fd 03 00 00       	mov    $0x3fd,%esi
f01002ac:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002b1:	eb 09                	jmp    f01002bc <cons_putc+0x25>
f01002b3:	89 ca                	mov    %ecx,%edx
f01002b5:	ec                   	in     (%dx),%al
f01002b6:	ec                   	in     (%dx),%al
f01002b7:	ec                   	in     (%dx),%al
f01002b8:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f01002b9:	83 c3 01             	add    $0x1,%ebx
f01002bc:	89 f2                	mov    %esi,%edx
f01002be:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01002bf:	a8 20                	test   $0x20,%al
f01002c1:	75 08                	jne    f01002cb <cons_putc+0x34>
f01002c3:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01002c9:	7e e8                	jle    f01002b3 <cons_putc+0x1c>
f01002cb:	89 f8                	mov    %edi,%eax
f01002cd:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002d0:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01002d5:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01002d6:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002db:	be 79 03 00 00       	mov    $0x379,%esi
f01002e0:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002e5:	eb 09                	jmp    f01002f0 <cons_putc+0x59>
f01002e7:	89 ca                	mov    %ecx,%edx
f01002e9:	ec                   	in     (%dx),%al
f01002ea:	ec                   	in     (%dx),%al
f01002eb:	ec                   	in     (%dx),%al
f01002ec:	ec                   	in     (%dx),%al
f01002ed:	83 c3 01             	add    $0x1,%ebx
f01002f0:	89 f2                	mov    %esi,%edx
f01002f2:	ec                   	in     (%dx),%al
f01002f3:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01002f9:	7f 04                	jg     f01002ff <cons_putc+0x68>
f01002fb:	84 c0                	test   %al,%al
f01002fd:	79 e8                	jns    f01002e7 <cons_putc+0x50>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002ff:	ba 78 03 00 00       	mov    $0x378,%edx
f0100304:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f0100308:	ee                   	out    %al,(%dx)
f0100309:	ba 7a 03 00 00       	mov    $0x37a,%edx
f010030e:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100313:	ee                   	out    %al,(%dx)
f0100314:	b8 08 00 00 00       	mov    $0x8,%eax
f0100319:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f010031a:	89 fa                	mov    %edi,%edx
f010031c:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100322:	89 f8                	mov    %edi,%eax
f0100324:	80 cc 07             	or     $0x7,%ah
f0100327:	85 d2                	test   %edx,%edx
f0100329:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f010032c:	89 f8                	mov    %edi,%eax
f010032e:	0f b6 c0             	movzbl %al,%eax
f0100331:	83 f8 09             	cmp    $0x9,%eax
f0100334:	74 74                	je     f01003aa <cons_putc+0x113>
f0100336:	83 f8 09             	cmp    $0x9,%eax
f0100339:	7f 0a                	jg     f0100345 <cons_putc+0xae>
f010033b:	83 f8 08             	cmp    $0x8,%eax
f010033e:	74 14                	je     f0100354 <cons_putc+0xbd>
f0100340:	e9 99 00 00 00       	jmp    f01003de <cons_putc+0x147>
f0100345:	83 f8 0a             	cmp    $0xa,%eax
f0100348:	74 3a                	je     f0100384 <cons_putc+0xed>
f010034a:	83 f8 0d             	cmp    $0xd,%eax
f010034d:	74 3d                	je     f010038c <cons_putc+0xf5>
f010034f:	e9 8a 00 00 00       	jmp    f01003de <cons_putc+0x147>
	case '\b':
		if (crt_pos > 0) {
f0100354:	0f b7 05 28 65 11 f0 	movzwl 0xf0116528,%eax
f010035b:	66 85 c0             	test   %ax,%ax
f010035e:	0f 84 e6 00 00 00    	je     f010044a <cons_putc+0x1b3>
			crt_pos--;
f0100364:	83 e8 01             	sub    $0x1,%eax
f0100367:	66 a3 28 65 11 f0    	mov    %ax,0xf0116528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f010036d:	0f b7 c0             	movzwl %ax,%eax
f0100370:	66 81 e7 00 ff       	and    $0xff00,%di
f0100375:	83 cf 20             	or     $0x20,%edi
f0100378:	8b 15 2c 65 11 f0    	mov    0xf011652c,%edx
f010037e:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100382:	eb 78                	jmp    f01003fc <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100384:	66 83 05 28 65 11 f0 	addw   $0x50,0xf0116528
f010038b:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f010038c:	0f b7 05 28 65 11 f0 	movzwl 0xf0116528,%eax
f0100393:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100399:	c1 e8 16             	shr    $0x16,%eax
f010039c:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010039f:	c1 e0 04             	shl    $0x4,%eax
f01003a2:	66 a3 28 65 11 f0    	mov    %ax,0xf0116528
f01003a8:	eb 52                	jmp    f01003fc <cons_putc+0x165>
		break;
	case '\t':
		cons_putc(' ');
f01003aa:	b8 20 00 00 00       	mov    $0x20,%eax
f01003af:	e8 e3 fe ff ff       	call   f0100297 <cons_putc>
		cons_putc(' ');
f01003b4:	b8 20 00 00 00       	mov    $0x20,%eax
f01003b9:	e8 d9 fe ff ff       	call   f0100297 <cons_putc>
		cons_putc(' ');
f01003be:	b8 20 00 00 00       	mov    $0x20,%eax
f01003c3:	e8 cf fe ff ff       	call   f0100297 <cons_putc>
		cons_putc(' ');
f01003c8:	b8 20 00 00 00       	mov    $0x20,%eax
f01003cd:	e8 c5 fe ff ff       	call   f0100297 <cons_putc>
		cons_putc(' ');
f01003d2:	b8 20 00 00 00       	mov    $0x20,%eax
f01003d7:	e8 bb fe ff ff       	call   f0100297 <cons_putc>
f01003dc:	eb 1e                	jmp    f01003fc <cons_putc+0x165>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f01003de:	0f b7 05 28 65 11 f0 	movzwl 0xf0116528,%eax
f01003e5:	8d 50 01             	lea    0x1(%eax),%edx
f01003e8:	66 89 15 28 65 11 f0 	mov    %dx,0xf0116528
f01003ef:	0f b7 c0             	movzwl %ax,%eax
f01003f2:	8b 15 2c 65 11 f0    	mov    0xf011652c,%edx
f01003f8:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f01003fc:	66 81 3d 28 65 11 f0 	cmpw   $0x7cf,0xf0116528
f0100403:	cf 07 
f0100405:	76 43                	jbe    f010044a <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100407:	a1 2c 65 11 f0       	mov    0xf011652c,%eax
f010040c:	83 ec 04             	sub    $0x4,%esp
f010040f:	68 00 0f 00 00       	push   $0xf00
f0100414:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f010041a:	52                   	push   %edx
f010041b:	50                   	push   %eax
f010041c:	e8 eb 2d 00 00       	call   f010320c <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100421:	8b 15 2c 65 11 f0    	mov    0xf011652c,%edx
f0100427:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f010042d:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f0100433:	83 c4 10             	add    $0x10,%esp
f0100436:	66 c7 00 20 07       	movw   $0x720,(%eax)
f010043b:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010043e:	39 d0                	cmp    %edx,%eax
f0100440:	75 f4                	jne    f0100436 <cons_putc+0x19f>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100442:	66 83 2d 28 65 11 f0 	subw   $0x50,0xf0116528
f0100449:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f010044a:	8b 0d 30 65 11 f0    	mov    0xf0116530,%ecx
f0100450:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100455:	89 ca                	mov    %ecx,%edx
f0100457:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100458:	0f b7 1d 28 65 11 f0 	movzwl 0xf0116528,%ebx
f010045f:	8d 71 01             	lea    0x1(%ecx),%esi
f0100462:	89 d8                	mov    %ebx,%eax
f0100464:	66 c1 e8 08          	shr    $0x8,%ax
f0100468:	89 f2                	mov    %esi,%edx
f010046a:	ee                   	out    %al,(%dx)
f010046b:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100470:	89 ca                	mov    %ecx,%edx
f0100472:	ee                   	out    %al,(%dx)
f0100473:	89 d8                	mov    %ebx,%eax
f0100475:	89 f2                	mov    %esi,%edx
f0100477:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f0100478:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010047b:	5b                   	pop    %ebx
f010047c:	5e                   	pop    %esi
f010047d:	5f                   	pop    %edi
f010047e:	5d                   	pop    %ebp
f010047f:	c3                   	ret    

f0100480 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f0100480:	80 3d 34 65 11 f0 00 	cmpb   $0x0,0xf0116534
f0100487:	74 11                	je     f010049a <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f0100489:	55                   	push   %ebp
f010048a:	89 e5                	mov    %esp,%ebp
f010048c:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f010048f:	b8 1c 01 10 f0       	mov    $0xf010011c,%eax
f0100494:	e8 a2 fc ff ff       	call   f010013b <cons_intr>
}
f0100499:	c9                   	leave  
f010049a:	f3 c3                	repz ret 

f010049c <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f010049c:	55                   	push   %ebp
f010049d:	89 e5                	mov    %esp,%ebp
f010049f:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004a2:	b8 7e 01 10 f0       	mov    $0xf010017e,%eax
f01004a7:	e8 8f fc ff ff       	call   f010013b <cons_intr>
}
f01004ac:	c9                   	leave  
f01004ad:	c3                   	ret    

f01004ae <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004ae:	55                   	push   %ebp
f01004af:	89 e5                	mov    %esp,%ebp
f01004b1:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01004b4:	e8 c7 ff ff ff       	call   f0100480 <serial_intr>
	kbd_intr();
f01004b9:	e8 de ff ff ff       	call   f010049c <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004be:	a1 20 65 11 f0       	mov    0xf0116520,%eax
f01004c3:	3b 05 24 65 11 f0    	cmp    0xf0116524,%eax
f01004c9:	74 26                	je     f01004f1 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01004cb:	8d 50 01             	lea    0x1(%eax),%edx
f01004ce:	89 15 20 65 11 f0    	mov    %edx,0xf0116520
f01004d4:	0f b6 88 20 63 11 f0 	movzbl -0xfee9ce0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f01004db:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f01004dd:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01004e3:	75 11                	jne    f01004f6 <cons_getc+0x48>
			cons.rpos = 0;
f01004e5:	c7 05 20 65 11 f0 00 	movl   $0x0,0xf0116520
f01004ec:	00 00 00 
f01004ef:	eb 05                	jmp    f01004f6 <cons_getc+0x48>
		return c;
	}
	return 0;
f01004f1:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01004f6:	c9                   	leave  
f01004f7:	c3                   	ret    

f01004f8 <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f01004f8:	55                   	push   %ebp
f01004f9:	89 e5                	mov    %esp,%ebp
f01004fb:	57                   	push   %edi
f01004fc:	56                   	push   %esi
f01004fd:	53                   	push   %ebx
f01004fe:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100501:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f0100508:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f010050f:	5a a5 
	if (*cp != 0xA55A) {
f0100511:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f0100518:	66 3d 5a a5          	cmp    $0xa55a,%ax
f010051c:	74 11                	je     f010052f <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f010051e:	c7 05 30 65 11 f0 b4 	movl   $0x3b4,0xf0116530
f0100525:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100528:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f010052d:	eb 16                	jmp    f0100545 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f010052f:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100536:	c7 05 30 65 11 f0 d4 	movl   $0x3d4,0xf0116530
f010053d:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100540:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f0100545:	8b 3d 30 65 11 f0    	mov    0xf0116530,%edi
f010054b:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100550:	89 fa                	mov    %edi,%edx
f0100552:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100553:	8d 5f 01             	lea    0x1(%edi),%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100556:	89 da                	mov    %ebx,%edx
f0100558:	ec                   	in     (%dx),%al
f0100559:	0f b6 c8             	movzbl %al,%ecx
f010055c:	c1 e1 08             	shl    $0x8,%ecx
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010055f:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100564:	89 fa                	mov    %edi,%edx
f0100566:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100567:	89 da                	mov    %ebx,%edx
f0100569:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f010056a:	89 35 2c 65 11 f0    	mov    %esi,0xf011652c
	crt_pos = pos;
f0100570:	0f b6 c0             	movzbl %al,%eax
f0100573:	09 c8                	or     %ecx,%eax
f0100575:	66 a3 28 65 11 f0    	mov    %ax,0xf0116528
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010057b:	be fa 03 00 00       	mov    $0x3fa,%esi
f0100580:	b8 00 00 00 00       	mov    $0x0,%eax
f0100585:	89 f2                	mov    %esi,%edx
f0100587:	ee                   	out    %al,(%dx)
f0100588:	ba fb 03 00 00       	mov    $0x3fb,%edx
f010058d:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100592:	ee                   	out    %al,(%dx)
f0100593:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f0100598:	b8 0c 00 00 00       	mov    $0xc,%eax
f010059d:	89 da                	mov    %ebx,%edx
f010059f:	ee                   	out    %al,(%dx)
f01005a0:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005a5:	b8 00 00 00 00       	mov    $0x0,%eax
f01005aa:	ee                   	out    %al,(%dx)
f01005ab:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005b0:	b8 03 00 00 00       	mov    $0x3,%eax
f01005b5:	ee                   	out    %al,(%dx)
f01005b6:	ba fc 03 00 00       	mov    $0x3fc,%edx
f01005bb:	b8 00 00 00 00       	mov    $0x0,%eax
f01005c0:	ee                   	out    %al,(%dx)
f01005c1:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005c6:	b8 01 00 00 00       	mov    $0x1,%eax
f01005cb:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005cc:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01005d1:	ec                   	in     (%dx),%al
f01005d2:	89 c1                	mov    %eax,%ecx
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01005d4:	3c ff                	cmp    $0xff,%al
f01005d6:	0f 95 05 34 65 11 f0 	setne  0xf0116534
f01005dd:	89 f2                	mov    %esi,%edx
f01005df:	ec                   	in     (%dx),%al
f01005e0:	89 da                	mov    %ebx,%edx
f01005e2:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01005e3:	80 f9 ff             	cmp    $0xff,%cl
f01005e6:	75 10                	jne    f01005f8 <cons_init+0x100>
		cprintf("Serial port does not exist!\n");
f01005e8:	83 ec 0c             	sub    $0xc,%esp
f01005eb:	68 b9 36 10 f0       	push   $0xf01036b9
f01005f0:	e8 11 21 00 00       	call   f0102706 <cprintf>
f01005f5:	83 c4 10             	add    $0x10,%esp
}
f01005f8:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01005fb:	5b                   	pop    %ebx
f01005fc:	5e                   	pop    %esi
f01005fd:	5f                   	pop    %edi
f01005fe:	5d                   	pop    %ebp
f01005ff:	c3                   	ret    

f0100600 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100600:	55                   	push   %ebp
f0100601:	89 e5                	mov    %esp,%ebp
f0100603:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100606:	8b 45 08             	mov    0x8(%ebp),%eax
f0100609:	e8 89 fc ff ff       	call   f0100297 <cons_putc>
}
f010060e:	c9                   	leave  
f010060f:	c3                   	ret    

f0100610 <getchar>:

int
getchar(void)
{
f0100610:	55                   	push   %ebp
f0100611:	89 e5                	mov    %esp,%ebp
f0100613:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100616:	e8 93 fe ff ff       	call   f01004ae <cons_getc>
f010061b:	85 c0                	test   %eax,%eax
f010061d:	74 f7                	je     f0100616 <getchar+0x6>
		/* do nothing */;
	return c;
}
f010061f:	c9                   	leave  
f0100620:	c3                   	ret    

f0100621 <iscons>:

int
iscons(int fdnum)
{
f0100621:	55                   	push   %ebp
f0100622:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100624:	b8 01 00 00 00       	mov    $0x1,%eax
f0100629:	5d                   	pop    %ebp
f010062a:	c3                   	ret    

f010062b <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f010062b:	55                   	push   %ebp
f010062c:	89 e5                	mov    %esp,%ebp
f010062e:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100631:	68 00 39 10 f0       	push   $0xf0103900
f0100636:	68 1e 39 10 f0       	push   $0xf010391e
f010063b:	68 23 39 10 f0       	push   $0xf0103923
f0100640:	e8 c1 20 00 00       	call   f0102706 <cprintf>
f0100645:	83 c4 0c             	add    $0xc,%esp
f0100648:	68 ac 39 10 f0       	push   $0xf01039ac
f010064d:	68 2c 39 10 f0       	push   $0xf010392c
f0100652:	68 23 39 10 f0       	push   $0xf0103923
f0100657:	e8 aa 20 00 00       	call   f0102706 <cprintf>
	return 0;
}
f010065c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100661:	c9                   	leave  
f0100662:	c3                   	ret    

f0100663 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100663:	55                   	push   %ebp
f0100664:	89 e5                	mov    %esp,%ebp
f0100666:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100669:	68 35 39 10 f0       	push   $0xf0103935
f010066e:	e8 93 20 00 00       	call   f0102706 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100673:	83 c4 08             	add    $0x8,%esp
f0100676:	68 0c 00 10 00       	push   $0x10000c
f010067b:	68 d4 39 10 f0       	push   $0xf01039d4
f0100680:	e8 81 20 00 00       	call   f0102706 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100685:	83 c4 0c             	add    $0xc,%esp
f0100688:	68 0c 00 10 00       	push   $0x10000c
f010068d:	68 0c 00 10 f0       	push   $0xf010000c
f0100692:	68 fc 39 10 f0       	push   $0xf01039fc
f0100697:	e8 6a 20 00 00       	call   f0102706 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f010069c:	83 c4 0c             	add    $0xc,%esp
f010069f:	68 51 36 10 00       	push   $0x103651
f01006a4:	68 51 36 10 f0       	push   $0xf0103651
f01006a9:	68 20 3a 10 f0       	push   $0xf0103a20
f01006ae:	e8 53 20 00 00       	call   f0102706 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006b3:	83 c4 0c             	add    $0xc,%esp
f01006b6:	68 00 63 11 00       	push   $0x116300
f01006bb:	68 00 63 11 f0       	push   $0xf0116300
f01006c0:	68 44 3a 10 f0       	push   $0xf0103a44
f01006c5:	e8 3c 20 00 00       	call   f0102706 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006ca:	83 c4 0c             	add    $0xc,%esp
f01006cd:	68 50 69 11 00       	push   $0x116950
f01006d2:	68 50 69 11 f0       	push   $0xf0116950
f01006d7:	68 68 3a 10 f0       	push   $0xf0103a68
f01006dc:	e8 25 20 00 00       	call   f0102706 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f01006e1:	b8 4f 6d 11 f0       	mov    $0xf0116d4f,%eax
f01006e6:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f01006eb:	83 c4 08             	add    $0x8,%esp
f01006ee:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f01006f3:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f01006f9:	85 c0                	test   %eax,%eax
f01006fb:	0f 48 c2             	cmovs  %edx,%eax
f01006fe:	c1 f8 0a             	sar    $0xa,%eax
f0100701:	50                   	push   %eax
f0100702:	68 8c 3a 10 f0       	push   $0xf0103a8c
f0100707:	e8 fa 1f 00 00       	call   f0102706 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f010070c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100711:	c9                   	leave  
f0100712:	c3                   	ret    

f0100713 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100713:	55                   	push   %ebp
f0100714:	89 e5                	mov    %esp,%ebp
f0100716:	56                   	push   %esi
f0100717:	53                   	push   %ebx
f0100718:	83 ec 2c             	sub    $0x2c,%esp

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f010071b:	89 eb                	mov    %ebp,%ebx
	uintptr_t ebp = read_ebp();
	struct Eipdebuginfo info;
	cprintf("Stack backtrace:\n");
f010071d:	68 4e 39 10 f0       	push   $0xf010394e
f0100722:	e8 df 1f 00 00       	call   f0102706 <cprintf>
	while(ebp != 0){
f0100727:	83 c4 10             	add    $0x10,%esp
		cprintf("  ebp %08x  eip %08x  args %08x %08x %08x %08x %08x\n", ebp , 
				*((uintptr_t *)ebp + 1), *((uintptr_t *)ebp + 2), *((uintptr_t *)ebp + 3), 
			    *((uintptr_t *)ebp + 4), *((uintptr_t *)ebp + 5), *((uintptr_t *)ebp + 6));
		debuginfo_eip(*((uintptr_t *)ebp + 1), &info);
f010072a:	8d 75 e0             	lea    -0x20(%ebp),%esi
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	uintptr_t ebp = read_ebp();
	struct Eipdebuginfo info;
	cprintf("Stack backtrace:\n");
	while(ebp != 0){
f010072d:	eb 4e                	jmp    f010077d <mon_backtrace+0x6a>
		cprintf("  ebp %08x  eip %08x  args %08x %08x %08x %08x %08x\n", ebp , 
f010072f:	ff 73 18             	pushl  0x18(%ebx)
f0100732:	ff 73 14             	pushl  0x14(%ebx)
f0100735:	ff 73 10             	pushl  0x10(%ebx)
f0100738:	ff 73 0c             	pushl  0xc(%ebx)
f010073b:	ff 73 08             	pushl  0x8(%ebx)
f010073e:	ff 73 04             	pushl  0x4(%ebx)
f0100741:	53                   	push   %ebx
f0100742:	68 b8 3a 10 f0       	push   $0xf0103ab8
f0100747:	e8 ba 1f 00 00       	call   f0102706 <cprintf>
				*((uintptr_t *)ebp + 1), *((uintptr_t *)ebp + 2), *((uintptr_t *)ebp + 3), 
			    *((uintptr_t *)ebp + 4), *((uintptr_t *)ebp + 5), *((uintptr_t *)ebp + 6));
		debuginfo_eip(*((uintptr_t *)ebp + 1), &info);
f010074c:	83 c4 18             	add    $0x18,%esp
f010074f:	56                   	push   %esi
f0100750:	ff 73 04             	pushl  0x4(%ebx)
f0100753:	e8 b8 20 00 00       	call   f0102810 <debuginfo_eip>
		cprintf("%s:%d: %.*s+%d\n", info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, 
f0100758:	83 c4 08             	add    $0x8,%esp
f010075b:	8b 43 04             	mov    0x4(%ebx),%eax
f010075e:	2b 45 f0             	sub    -0x10(%ebp),%eax
f0100761:	50                   	push   %eax
f0100762:	ff 75 e8             	pushl  -0x18(%ebp)
f0100765:	ff 75 ec             	pushl  -0x14(%ebp)
f0100768:	ff 75 e4             	pushl  -0x1c(%ebp)
f010076b:	ff 75 e0             	pushl  -0x20(%ebp)
f010076e:	68 60 39 10 f0       	push   $0xf0103960
f0100773:	e8 8e 1f 00 00       	call   f0102706 <cprintf>
				*((uintptr_t *)ebp + 1) - info.eip_fn_addr);
		ebp = *(uintptr_t *)ebp;
f0100778:	8b 1b                	mov    (%ebx),%ebx
f010077a:	83 c4 20             	add    $0x20,%esp
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	uintptr_t ebp = read_ebp();
	struct Eipdebuginfo info;
	cprintf("Stack backtrace:\n");
	while(ebp != 0){
f010077d:	85 db                	test   %ebx,%ebx
f010077f:	75 ae                	jne    f010072f <mon_backtrace+0x1c>
		cprintf("%s:%d: %.*s+%d\n", info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, 
				*((uintptr_t *)ebp + 1) - info.eip_fn_addr);
		ebp = *(uintptr_t *)ebp;
	}
	return 0;
}
f0100781:	b8 00 00 00 00       	mov    $0x0,%eax
f0100786:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100789:	5b                   	pop    %ebx
f010078a:	5e                   	pop    %esi
f010078b:	5d                   	pop    %ebp
f010078c:	c3                   	ret    

f010078d <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f010078d:	55                   	push   %ebp
f010078e:	89 e5                	mov    %esp,%ebp
f0100790:	57                   	push   %edi
f0100791:	56                   	push   %esi
f0100792:	53                   	push   %ebx
f0100793:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100796:	68 f0 3a 10 f0       	push   $0xf0103af0
f010079b:	e8 66 1f 00 00       	call   f0102706 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01007a0:	c7 04 24 14 3b 10 f0 	movl   $0xf0103b14,(%esp)
f01007a7:	e8 5a 1f 00 00       	call   f0102706 <cprintf>
f01007ac:	83 c4 10             	add    $0x10,%esp

	while (1) {
		buf = readline("K> ");
f01007af:	83 ec 0c             	sub    $0xc,%esp
f01007b2:	68 70 39 10 f0       	push   $0xf0103970
f01007b7:	e8 ac 27 00 00       	call   f0102f68 <readline>
f01007bc:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f01007be:	83 c4 10             	add    $0x10,%esp
f01007c1:	85 c0                	test   %eax,%eax
f01007c3:	74 ea                	je     f01007af <monitor+0x22>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f01007c5:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f01007cc:	be 00 00 00 00       	mov    $0x0,%esi
f01007d1:	eb 0a                	jmp    f01007dd <monitor+0x50>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f01007d3:	c6 03 00             	movb   $0x0,(%ebx)
f01007d6:	89 f7                	mov    %esi,%edi
f01007d8:	8d 5b 01             	lea    0x1(%ebx),%ebx
f01007db:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f01007dd:	0f b6 03             	movzbl (%ebx),%eax
f01007e0:	84 c0                	test   %al,%al
f01007e2:	74 63                	je     f0100847 <monitor+0xba>
f01007e4:	83 ec 08             	sub    $0x8,%esp
f01007e7:	0f be c0             	movsbl %al,%eax
f01007ea:	50                   	push   %eax
f01007eb:	68 74 39 10 f0       	push   $0xf0103974
f01007f0:	e8 8d 29 00 00       	call   f0103182 <strchr>
f01007f5:	83 c4 10             	add    $0x10,%esp
f01007f8:	85 c0                	test   %eax,%eax
f01007fa:	75 d7                	jne    f01007d3 <monitor+0x46>
			*buf++ = 0;
		if (*buf == 0)
f01007fc:	80 3b 00             	cmpb   $0x0,(%ebx)
f01007ff:	74 46                	je     f0100847 <monitor+0xba>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100801:	83 fe 0f             	cmp    $0xf,%esi
f0100804:	75 14                	jne    f010081a <monitor+0x8d>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100806:	83 ec 08             	sub    $0x8,%esp
f0100809:	6a 10                	push   $0x10
f010080b:	68 79 39 10 f0       	push   $0xf0103979
f0100810:	e8 f1 1e 00 00       	call   f0102706 <cprintf>
f0100815:	83 c4 10             	add    $0x10,%esp
f0100818:	eb 95                	jmp    f01007af <monitor+0x22>
			return 0;
		}
		argv[argc++] = buf;
f010081a:	8d 7e 01             	lea    0x1(%esi),%edi
f010081d:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100821:	eb 03                	jmp    f0100826 <monitor+0x99>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f0100823:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100826:	0f b6 03             	movzbl (%ebx),%eax
f0100829:	84 c0                	test   %al,%al
f010082b:	74 ae                	je     f01007db <monitor+0x4e>
f010082d:	83 ec 08             	sub    $0x8,%esp
f0100830:	0f be c0             	movsbl %al,%eax
f0100833:	50                   	push   %eax
f0100834:	68 74 39 10 f0       	push   $0xf0103974
f0100839:	e8 44 29 00 00       	call   f0103182 <strchr>
f010083e:	83 c4 10             	add    $0x10,%esp
f0100841:	85 c0                	test   %eax,%eax
f0100843:	74 de                	je     f0100823 <monitor+0x96>
f0100845:	eb 94                	jmp    f01007db <monitor+0x4e>
			buf++;
	}
	argv[argc] = 0;
f0100847:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f010084e:	00 

	// Lookup and invoke the command
	if (argc == 0)
f010084f:	85 f6                	test   %esi,%esi
f0100851:	0f 84 58 ff ff ff    	je     f01007af <monitor+0x22>
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100857:	83 ec 08             	sub    $0x8,%esp
f010085a:	68 1e 39 10 f0       	push   $0xf010391e
f010085f:	ff 75 a8             	pushl  -0x58(%ebp)
f0100862:	e8 bd 28 00 00       	call   f0103124 <strcmp>
f0100867:	83 c4 10             	add    $0x10,%esp
f010086a:	85 c0                	test   %eax,%eax
f010086c:	74 1e                	je     f010088c <monitor+0xff>
f010086e:	83 ec 08             	sub    $0x8,%esp
f0100871:	68 2c 39 10 f0       	push   $0xf010392c
f0100876:	ff 75 a8             	pushl  -0x58(%ebp)
f0100879:	e8 a6 28 00 00       	call   f0103124 <strcmp>
f010087e:	83 c4 10             	add    $0x10,%esp
f0100881:	85 c0                	test   %eax,%eax
f0100883:	75 2f                	jne    f01008b4 <monitor+0x127>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100885:	b8 01 00 00 00       	mov    $0x1,%eax
f010088a:	eb 05                	jmp    f0100891 <monitor+0x104>
		if (strcmp(argv[0], commands[i].name) == 0)
f010088c:	b8 00 00 00 00       	mov    $0x0,%eax
			return commands[i].func(argc, argv, tf);
f0100891:	83 ec 04             	sub    $0x4,%esp
f0100894:	8d 14 00             	lea    (%eax,%eax,1),%edx
f0100897:	01 d0                	add    %edx,%eax
f0100899:	ff 75 08             	pushl  0x8(%ebp)
f010089c:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f010089f:	51                   	push   %ecx
f01008a0:	56                   	push   %esi
f01008a1:	ff 14 85 44 3b 10 f0 	call   *-0xfefc4bc(,%eax,4)
	cprintf("Type 'help' for a list of commands.\n");

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f01008a8:	83 c4 10             	add    $0x10,%esp
f01008ab:	85 c0                	test   %eax,%eax
f01008ad:	78 1d                	js     f01008cc <monitor+0x13f>
f01008af:	e9 fb fe ff ff       	jmp    f01007af <monitor+0x22>
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f01008b4:	83 ec 08             	sub    $0x8,%esp
f01008b7:	ff 75 a8             	pushl  -0x58(%ebp)
f01008ba:	68 96 39 10 f0       	push   $0xf0103996
f01008bf:	e8 42 1e 00 00       	call   f0102706 <cprintf>
f01008c4:	83 c4 10             	add    $0x10,%esp
f01008c7:	e9 e3 fe ff ff       	jmp    f01007af <monitor+0x22>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f01008cc:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01008cf:	5b                   	pop    %ebx
f01008d0:	5e                   	pop    %esi
f01008d1:	5f                   	pop    %edi
f01008d2:	5d                   	pop    %ebp
f01008d3:	c3                   	ret    

f01008d4 <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f01008d4:	55                   	push   %ebp
f01008d5:	89 e5                	mov    %esp,%ebp
f01008d7:	56                   	push   %esi
f01008d8:	53                   	push   %ebx
f01008d9:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f01008db:	83 ec 0c             	sub    $0xc,%esp
f01008de:	50                   	push   %eax
f01008df:	e8 bb 1d 00 00       	call   f010269f <mc146818_read>
f01008e4:	89 c6                	mov    %eax,%esi
f01008e6:	83 c3 01             	add    $0x1,%ebx
f01008e9:	89 1c 24             	mov    %ebx,(%esp)
f01008ec:	e8 ae 1d 00 00       	call   f010269f <mc146818_read>
f01008f1:	c1 e0 08             	shl    $0x8,%eax
f01008f4:	09 f0                	or     %esi,%eax
}
f01008f6:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01008f9:	5b                   	pop    %ebx
f01008fa:	5e                   	pop    %esi
f01008fb:	5d                   	pop    %ebp
f01008fc:	c3                   	ret    

f01008fd <check_va2pa>:
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f01008fd:	89 d1                	mov    %edx,%ecx
f01008ff:	c1 e9 16             	shr    $0x16,%ecx
f0100902:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0100905:	a8 01                	test   $0x1,%al
f0100907:	74 52                	je     f010095b <check_va2pa+0x5e>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100909:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010090e:	89 c1                	mov    %eax,%ecx
f0100910:	c1 e9 0c             	shr    $0xc,%ecx
f0100913:	3b 0d 44 69 11 f0    	cmp    0xf0116944,%ecx
f0100919:	72 1b                	jb     f0100936 <check_va2pa+0x39>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f010091b:	55                   	push   %ebp
f010091c:	89 e5                	mov    %esp,%ebp
f010091e:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100921:	50                   	push   %eax
f0100922:	68 54 3b 10 f0       	push   $0xf0103b54
f0100927:	68 d4 02 00 00       	push   $0x2d4
f010092c:	68 dc 42 10 f0       	push   $0xf01042dc
f0100931:	e8 55 f7 ff ff       	call   f010008b <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f0100936:	c1 ea 0c             	shr    $0xc,%edx
f0100939:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f010093f:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100946:	89 c2                	mov    %eax,%edx
f0100948:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f010094b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100950:	85 d2                	test   %edx,%edx
f0100952:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100957:	0f 44 c2             	cmove  %edx,%eax
f010095a:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f010095b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f0100960:	c3                   	ret    

f0100961 <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100961:	89 c2                	mov    %eax,%edx
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100963:	83 3d 38 65 11 f0 00 	cmpl   $0x0,0xf0116538
f010096a:	75 0f                	jne    f010097b <boot_alloc+0x1a>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f010096c:	b8 4f 79 11 f0       	mov    $0xf011794f,%eax
f0100971:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100976:	a3 38 65 11 f0       	mov    %eax,0xf0116538
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	result = nextfree;
f010097b:	a1 38 65 11 f0       	mov    0xf0116538,%eax
	if(n > 0){
f0100980:	85 d2                	test   %edx,%edx
f0100982:	74 62                	je     f01009e6 <boot_alloc+0x85>
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100984:	55                   	push   %ebp
f0100985:	89 e5                	mov    %esp,%ebp
f0100987:	53                   	push   %ebx
f0100988:	83 ec 04             	sub    $0x4,%esp
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010098b:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100990:	77 12                	ja     f01009a4 <boot_alloc+0x43>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100992:	50                   	push   %eax
f0100993:	68 78 3b 10 f0       	push   $0xf0103b78
f0100998:	6a 6b                	push   $0x6b
f010099a:	68 dc 42 10 f0       	push   $0xf01042dc
f010099f:	e8 e7 f6 ff ff       	call   f010008b <_panic>
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	result = nextfree;
	if(n > 0){
		if (PADDR(nextfree) + n > (npages + 1) * PGSIZE) {
f01009a4:	8d 9c 10 00 00 00 10 	lea    0x10000000(%eax,%edx,1),%ebx
f01009ab:	8b 0d 44 69 11 f0    	mov    0xf0116944,%ecx
f01009b1:	83 c1 01             	add    $0x1,%ecx
f01009b4:	c1 e1 0c             	shl    $0xc,%ecx
f01009b7:	39 cb                	cmp    %ecx,%ebx
f01009b9:	76 14                	jbe    f01009cf <boot_alloc+0x6e>
			panic("out of memory\n");
f01009bb:	83 ec 04             	sub    $0x4,%esp
f01009be:	68 e8 42 10 f0       	push   $0xf01042e8
f01009c3:	6a 6c                	push   $0x6c
f01009c5:	68 dc 42 10 f0       	push   $0xf01042dc
f01009ca:	e8 bc f6 ff ff       	call   f010008b <_panic>
		}
		nextfree = ROUNDUP((char *)nextfree + n, PGSIZE);
f01009cf:	8d 94 10 ff 0f 00 00 	lea    0xfff(%eax,%edx,1),%edx
f01009d6:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01009dc:	89 15 38 65 11 f0    	mov    %edx,0xf0116538
	}
	return result;
}
f01009e2:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01009e5:	c9                   	leave  
f01009e6:	f3 c3                	repz ret 

f01009e8 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f01009e8:	55                   	push   %ebp
f01009e9:	89 e5                	mov    %esp,%ebp
f01009eb:	57                   	push   %edi
f01009ec:	56                   	push   %esi
f01009ed:	53                   	push   %ebx
f01009ee:	83 ec 2c             	sub    $0x2c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f01009f1:	84 c0                	test   %al,%al
f01009f3:	0f 85 72 02 00 00    	jne    f0100c6b <check_page_free_list+0x283>
f01009f9:	e9 7f 02 00 00       	jmp    f0100c7d <check_page_free_list+0x295>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f01009fe:	83 ec 04             	sub    $0x4,%esp
f0100a01:	68 9c 3b 10 f0       	push   $0xf0103b9c
f0100a06:	68 17 02 00 00       	push   $0x217
f0100a0b:	68 dc 42 10 f0       	push   $0xf01042dc
f0100a10:	e8 76 f6 ff ff       	call   f010008b <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100a15:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100a18:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100a1b:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100a1e:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100a21:	89 c2                	mov    %eax,%edx
f0100a23:	2b 15 4c 69 11 f0    	sub    0xf011694c,%edx
f0100a29:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100a2f:	0f 95 c2             	setne  %dl
f0100a32:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100a35:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100a39:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100a3b:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100a3f:	8b 00                	mov    (%eax),%eax
f0100a41:	85 c0                	test   %eax,%eax
f0100a43:	75 dc                	jne    f0100a21 <check_page_free_list+0x39>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100a45:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a48:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100a4e:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100a51:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100a54:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100a56:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100a59:	a3 3c 65 11 f0       	mov    %eax,0xf011653c
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100a5e:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100a63:	8b 1d 3c 65 11 f0    	mov    0xf011653c,%ebx
f0100a69:	eb 53                	jmp    f0100abe <check_page_free_list+0xd6>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100a6b:	89 d8                	mov    %ebx,%eax
f0100a6d:	2b 05 4c 69 11 f0    	sub    0xf011694c,%eax
f0100a73:	c1 f8 03             	sar    $0x3,%eax
f0100a76:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100a79:	89 c2                	mov    %eax,%edx
f0100a7b:	c1 ea 16             	shr    $0x16,%edx
f0100a7e:	39 f2                	cmp    %esi,%edx
f0100a80:	73 3a                	jae    f0100abc <check_page_free_list+0xd4>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100a82:	89 c2                	mov    %eax,%edx
f0100a84:	c1 ea 0c             	shr    $0xc,%edx
f0100a87:	3b 15 44 69 11 f0    	cmp    0xf0116944,%edx
f0100a8d:	72 12                	jb     f0100aa1 <check_page_free_list+0xb9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100a8f:	50                   	push   %eax
f0100a90:	68 54 3b 10 f0       	push   $0xf0103b54
f0100a95:	6a 52                	push   $0x52
f0100a97:	68 f7 42 10 f0       	push   $0xf01042f7
f0100a9c:	e8 ea f5 ff ff       	call   f010008b <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100aa1:	83 ec 04             	sub    $0x4,%esp
f0100aa4:	68 80 00 00 00       	push   $0x80
f0100aa9:	68 97 00 00 00       	push   $0x97
f0100aae:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100ab3:	50                   	push   %eax
f0100ab4:	e8 06 27 00 00       	call   f01031bf <memset>
f0100ab9:	83 c4 10             	add    $0x10,%esp
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100abc:	8b 1b                	mov    (%ebx),%ebx
f0100abe:	85 db                	test   %ebx,%ebx
f0100ac0:	75 a9                	jne    f0100a6b <check_page_free_list+0x83>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100ac2:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ac7:	e8 95 fe ff ff       	call   f0100961 <boot_alloc>
f0100acc:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100acf:	8b 15 3c 65 11 f0    	mov    0xf011653c,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100ad5:	8b 0d 4c 69 11 f0    	mov    0xf011694c,%ecx
		assert(pp < pages + npages);
f0100adb:	a1 44 69 11 f0       	mov    0xf0116944,%eax
f0100ae0:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0100ae3:	8d 3c c1             	lea    (%ecx,%eax,8),%edi
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100ae6:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100ae9:	be 00 00 00 00       	mov    $0x0,%esi
f0100aee:	89 5d d0             	mov    %ebx,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100af1:	e9 30 01 00 00       	jmp    f0100c26 <check_page_free_list+0x23e>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100af6:	39 ca                	cmp    %ecx,%edx
f0100af8:	73 19                	jae    f0100b13 <check_page_free_list+0x12b>
f0100afa:	68 05 43 10 f0       	push   $0xf0104305
f0100aff:	68 11 43 10 f0       	push   $0xf0104311
f0100b04:	68 31 02 00 00       	push   $0x231
f0100b09:	68 dc 42 10 f0       	push   $0xf01042dc
f0100b0e:	e8 78 f5 ff ff       	call   f010008b <_panic>
		assert(pp < pages + npages);
f0100b13:	39 fa                	cmp    %edi,%edx
f0100b15:	72 19                	jb     f0100b30 <check_page_free_list+0x148>
f0100b17:	68 26 43 10 f0       	push   $0xf0104326
f0100b1c:	68 11 43 10 f0       	push   $0xf0104311
f0100b21:	68 32 02 00 00       	push   $0x232
f0100b26:	68 dc 42 10 f0       	push   $0xf01042dc
f0100b2b:	e8 5b f5 ff ff       	call   f010008b <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100b30:	89 d0                	mov    %edx,%eax
f0100b32:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100b35:	a8 07                	test   $0x7,%al
f0100b37:	74 19                	je     f0100b52 <check_page_free_list+0x16a>
f0100b39:	68 c0 3b 10 f0       	push   $0xf0103bc0
f0100b3e:	68 11 43 10 f0       	push   $0xf0104311
f0100b43:	68 33 02 00 00       	push   $0x233
f0100b48:	68 dc 42 10 f0       	push   $0xf01042dc
f0100b4d:	e8 39 f5 ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100b52:	c1 f8 03             	sar    $0x3,%eax
f0100b55:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100b58:	85 c0                	test   %eax,%eax
f0100b5a:	75 19                	jne    f0100b75 <check_page_free_list+0x18d>
f0100b5c:	68 3a 43 10 f0       	push   $0xf010433a
f0100b61:	68 11 43 10 f0       	push   $0xf0104311
f0100b66:	68 36 02 00 00       	push   $0x236
f0100b6b:	68 dc 42 10 f0       	push   $0xf01042dc
f0100b70:	e8 16 f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100b75:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100b7a:	75 19                	jne    f0100b95 <check_page_free_list+0x1ad>
f0100b7c:	68 4b 43 10 f0       	push   $0xf010434b
f0100b81:	68 11 43 10 f0       	push   $0xf0104311
f0100b86:	68 37 02 00 00       	push   $0x237
f0100b8b:	68 dc 42 10 f0       	push   $0xf01042dc
f0100b90:	e8 f6 f4 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100b95:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100b9a:	75 19                	jne    f0100bb5 <check_page_free_list+0x1cd>
f0100b9c:	68 f4 3b 10 f0       	push   $0xf0103bf4
f0100ba1:	68 11 43 10 f0       	push   $0xf0104311
f0100ba6:	68 38 02 00 00       	push   $0x238
f0100bab:	68 dc 42 10 f0       	push   $0xf01042dc
f0100bb0:	e8 d6 f4 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100bb5:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100bba:	75 19                	jne    f0100bd5 <check_page_free_list+0x1ed>
f0100bbc:	68 64 43 10 f0       	push   $0xf0104364
f0100bc1:	68 11 43 10 f0       	push   $0xf0104311
f0100bc6:	68 39 02 00 00       	push   $0x239
f0100bcb:	68 dc 42 10 f0       	push   $0xf01042dc
f0100bd0:	e8 b6 f4 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100bd5:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100bda:	76 3f                	jbe    f0100c1b <check_page_free_list+0x233>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100bdc:	89 c3                	mov    %eax,%ebx
f0100bde:	c1 eb 0c             	shr    $0xc,%ebx
f0100be1:	39 5d c8             	cmp    %ebx,-0x38(%ebp)
f0100be4:	77 12                	ja     f0100bf8 <check_page_free_list+0x210>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100be6:	50                   	push   %eax
f0100be7:	68 54 3b 10 f0       	push   $0xf0103b54
f0100bec:	6a 52                	push   $0x52
f0100bee:	68 f7 42 10 f0       	push   $0xf01042f7
f0100bf3:	e8 93 f4 ff ff       	call   f010008b <_panic>
f0100bf8:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100bfd:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100c00:	76 1e                	jbe    f0100c20 <check_page_free_list+0x238>
f0100c02:	68 18 3c 10 f0       	push   $0xf0103c18
f0100c07:	68 11 43 10 f0       	push   $0xf0104311
f0100c0c:	68 3a 02 00 00       	push   $0x23a
f0100c11:	68 dc 42 10 f0       	push   $0xf01042dc
f0100c16:	e8 70 f4 ff ff       	call   f010008b <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100c1b:	83 c6 01             	add    $0x1,%esi
f0100c1e:	eb 04                	jmp    f0100c24 <check_page_free_list+0x23c>
		else
			++nfree_extmem;
f0100c20:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c24:	8b 12                	mov    (%edx),%edx
f0100c26:	85 d2                	test   %edx,%edx
f0100c28:	0f 85 c8 fe ff ff    	jne    f0100af6 <check_page_free_list+0x10e>
f0100c2e:	8b 5d d0             	mov    -0x30(%ebp),%ebx
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100c31:	85 f6                	test   %esi,%esi
f0100c33:	7f 19                	jg     f0100c4e <check_page_free_list+0x266>
f0100c35:	68 7e 43 10 f0       	push   $0xf010437e
f0100c3a:	68 11 43 10 f0       	push   $0xf0104311
f0100c3f:	68 42 02 00 00       	push   $0x242
f0100c44:	68 dc 42 10 f0       	push   $0xf01042dc
f0100c49:	e8 3d f4 ff ff       	call   f010008b <_panic>
	assert(nfree_extmem > 0);
f0100c4e:	85 db                	test   %ebx,%ebx
f0100c50:	7f 42                	jg     f0100c94 <check_page_free_list+0x2ac>
f0100c52:	68 90 43 10 f0       	push   $0xf0104390
f0100c57:	68 11 43 10 f0       	push   $0xf0104311
f0100c5c:	68 43 02 00 00       	push   $0x243
f0100c61:	68 dc 42 10 f0       	push   $0xf01042dc
f0100c66:	e8 20 f4 ff ff       	call   f010008b <_panic>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100c6b:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f0100c70:	85 c0                	test   %eax,%eax
f0100c72:	0f 85 9d fd ff ff    	jne    f0100a15 <check_page_free_list+0x2d>
f0100c78:	e9 81 fd ff ff       	jmp    f01009fe <check_page_free_list+0x16>
f0100c7d:	83 3d 3c 65 11 f0 00 	cmpl   $0x0,0xf011653c
f0100c84:	0f 84 74 fd ff ff    	je     f01009fe <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100c8a:	be 00 04 00 00       	mov    $0x400,%esi
f0100c8f:	e9 cf fd ff ff       	jmp    f0100a63 <check_page_free_list+0x7b>
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
}
f0100c94:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100c97:	5b                   	pop    %ebx
f0100c98:	5e                   	pop    %esi
f0100c99:	5f                   	pop    %edi
f0100c9a:	5d                   	pop    %ebp
f0100c9b:	c3                   	ret    

f0100c9c <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100c9c:	55                   	push   %ebp
f0100c9d:	89 e5                	mov    %esp,%ebp
f0100c9f:	53                   	push   %ebx
f0100ca0:	83 ec 04             	sub    $0x4,%esp
f0100ca3:	8b 1d 3c 65 11 f0    	mov    0xf011653c,%ebx
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	
	size_t i, io_page_i, ext_page_i, free_top;
	for (i = 0; i < npages; i++) {
f0100ca9:	ba 00 00 00 00       	mov    $0x0,%edx
f0100cae:	b8 00 00 00 00       	mov    $0x0,%eax
f0100cb3:	eb 27                	jmp    f0100cdc <page_init+0x40>
f0100cb5:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
		pages[i].pp_ref = 0;
f0100cbc:	89 d1                	mov    %edx,%ecx
f0100cbe:	03 0d 4c 69 11 f0    	add    0xf011694c,%ecx
f0100cc4:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = page_free_list;
f0100cca:	89 19                	mov    %ebx,(%ecx)
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	
	size_t i, io_page_i, ext_page_i, free_top;
	for (i = 0; i < npages; i++) {
f0100ccc:	83 c0 01             	add    $0x1,%eax
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
f0100ccf:	89 d3                	mov    %edx,%ebx
f0100cd1:	03 1d 4c 69 11 f0    	add    0xf011694c,%ebx
f0100cd7:	ba 01 00 00 00       	mov    $0x1,%edx
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	
	size_t i, io_page_i, ext_page_i, free_top;
	for (i = 0; i < npages; i++) {
f0100cdc:	3b 05 44 69 11 f0    	cmp    0xf0116944,%eax
f0100ce2:	72 d1                	jb     f0100cb5 <page_init+0x19>
f0100ce4:	84 d2                	test   %dl,%dl
f0100ce6:	74 06                	je     f0100cee <page_init+0x52>
f0100ce8:	89 1d 3c 65 11 f0    	mov    %ebx,0xf011653c
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
  
	pages[0].pp_link = NULL;
f0100cee:	a1 4c 69 11 f0       	mov    0xf011694c,%eax
f0100cf3:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pages[1].pp_link = NULL;
f0100cf9:	a1 4c 69 11 f0       	mov    0xf011694c,%eax
f0100cfe:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)

	io_page_i = PGNUM(IOPHYSMEM);
	ext_page_i = PGNUM(EXTPHYSMEM);
	free_top = PGNUM(PADDR(boot_alloc(0)));
f0100d05:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d0a:	e8 52 fc ff ff       	call   f0100961 <boot_alloc>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100d0f:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100d14:	77 15                	ja     f0100d2b <page_init+0x8f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100d16:	50                   	push   %eax
f0100d17:	68 78 3b 10 f0       	push   $0xf0103b78
f0100d1c:	68 15 01 00 00       	push   $0x115
f0100d21:	68 dc 42 10 f0       	push   $0xf01042dc
f0100d26:	e8 60 f3 ff ff       	call   f010008b <_panic>
f0100d2b:	8d 88 00 00 00 10    	lea    0x10000000(%eax),%ecx
f0100d31:	c1 e9 0c             	shr    $0xc,%ecx

	pages[ext_page_i].pp_link = pages[io_page_i].pp_link;
f0100d34:	a1 4c 69 11 f0       	mov    0xf011694c,%eax
f0100d39:	8b 90 00 05 00 00    	mov    0x500(%eax),%edx
f0100d3f:	89 90 00 08 00 00    	mov    %edx,0x800(%eax)
f0100d45:	b8 00 05 00 00       	mov    $0x500,%eax
	for(i = io_page_i;i < ext_page_i;i++)
		pages[i].pp_link = NULL;
f0100d4a:	8b 15 4c 69 11 f0    	mov    0xf011694c,%edx
f0100d50:	c7 04 02 00 00 00 00 	movl   $0x0,(%edx,%eax,1)
f0100d57:	83 c0 08             	add    $0x8,%eax
	io_page_i = PGNUM(IOPHYSMEM);
	ext_page_i = PGNUM(EXTPHYSMEM);
	free_top = PGNUM(PADDR(boot_alloc(0)));

	pages[ext_page_i].pp_link = pages[io_page_i].pp_link;
	for(i = io_page_i;i < ext_page_i;i++)
f0100d5a:	3d 00 08 00 00       	cmp    $0x800,%eax
f0100d5f:	75 e9                	jne    f0100d4a <page_init+0xae>
		pages[i].pp_link = NULL;

	pages[free_top].pp_link = pages[ext_page_i].pp_link;
f0100d61:	a1 4c 69 11 f0       	mov    0xf011694c,%eax
f0100d66:	8b 90 00 08 00 00    	mov    0x800(%eax),%edx
f0100d6c:	89 14 c8             	mov    %edx,(%eax,%ecx,8)
	for (i = ext_page_i; i < free_top; i++)
f0100d6f:	b8 00 01 00 00       	mov    $0x100,%eax
f0100d74:	eb 10                	jmp    f0100d86 <page_init+0xea>
		pages[i].pp_link = NULL;
f0100d76:	8b 15 4c 69 11 f0    	mov    0xf011694c,%edx
f0100d7c:	c7 04 c2 00 00 00 00 	movl   $0x0,(%edx,%eax,8)
	pages[ext_page_i].pp_link = pages[io_page_i].pp_link;
	for(i = io_page_i;i < ext_page_i;i++)
		pages[i].pp_link = NULL;

	pages[free_top].pp_link = pages[ext_page_i].pp_link;
	for (i = ext_page_i; i < free_top; i++)
f0100d83:	83 c0 01             	add    $0x1,%eax
f0100d86:	39 c8                	cmp    %ecx,%eax
f0100d88:	72 ec                	jb     f0100d76 <page_init+0xda>
		pages[i].pp_link = NULL;

}
f0100d8a:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100d8d:	c9                   	leave  
f0100d8e:	c3                   	ret    

f0100d8f <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100d8f:	55                   	push   %ebp
f0100d90:	89 e5                	mov    %esp,%ebp
f0100d92:	53                   	push   %ebx
f0100d93:	83 ec 04             	sub    $0x4,%esp
	//Fill this function in
	struct PageInfo *p = page_free_list;
f0100d96:	8b 1d 3c 65 11 f0    	mov    0xf011653c,%ebx
	if(p){
f0100d9c:	85 db                	test   %ebx,%ebx
f0100d9e:	74 5c                	je     f0100dfc <page_alloc+0x6d>
		page_free_list = p->pp_link;
f0100da0:	8b 03                	mov    (%ebx),%eax
f0100da2:	a3 3c 65 11 f0       	mov    %eax,0xf011653c
		p->pp_link = NULL;
f0100da7:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
		if(alloc_flags & ALLOC_ZERO){
			memset(page2kva(p), 0, PGSIZE);
		}
	}
	else return NULL;
	return p;
f0100dad:	89 d8                	mov    %ebx,%eax
	//Fill this function in
	struct PageInfo *p = page_free_list;
	if(p){
		page_free_list = p->pp_link;
		p->pp_link = NULL;
		if(alloc_flags & ALLOC_ZERO){
f0100daf:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100db3:	74 4c                	je     f0100e01 <page_alloc+0x72>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100db5:	2b 05 4c 69 11 f0    	sub    0xf011694c,%eax
f0100dbb:	c1 f8 03             	sar    $0x3,%eax
f0100dbe:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100dc1:	89 c2                	mov    %eax,%edx
f0100dc3:	c1 ea 0c             	shr    $0xc,%edx
f0100dc6:	3b 15 44 69 11 f0    	cmp    0xf0116944,%edx
f0100dcc:	72 12                	jb     f0100de0 <page_alloc+0x51>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100dce:	50                   	push   %eax
f0100dcf:	68 54 3b 10 f0       	push   $0xf0103b54
f0100dd4:	6a 52                	push   $0x52
f0100dd6:	68 f7 42 10 f0       	push   $0xf01042f7
f0100ddb:	e8 ab f2 ff ff       	call   f010008b <_panic>
			memset(page2kva(p), 0, PGSIZE);
f0100de0:	83 ec 04             	sub    $0x4,%esp
f0100de3:	68 00 10 00 00       	push   $0x1000
f0100de8:	6a 00                	push   $0x0
f0100dea:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100def:	50                   	push   %eax
f0100df0:	e8 ca 23 00 00       	call   f01031bf <memset>
f0100df5:	83 c4 10             	add    $0x10,%esp
		}
	}
	else return NULL;
	return p;
f0100df8:	89 d8                	mov    %ebx,%eax
f0100dfa:	eb 05                	jmp    f0100e01 <page_alloc+0x72>
		p->pp_link = NULL;
		if(alloc_flags & ALLOC_ZERO){
			memset(page2kva(p), 0, PGSIZE);
		}
	}
	else return NULL;
f0100dfc:	b8 00 00 00 00       	mov    $0x0,%eax
	return p;
}
f0100e01:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100e04:	c9                   	leave  
f0100e05:	c3                   	ret    

f0100e06 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100e06:	55                   	push   %ebp
f0100e07:	89 e5                	mov    %esp,%ebp
f0100e09:	83 ec 08             	sub    $0x8,%esp
f0100e0c:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
	if(pp->pp_ref != 0 || pp->pp_link!=NULL){
f0100e0f:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100e14:	75 05                	jne    f0100e1b <page_free+0x15>
f0100e16:	83 38 00             	cmpl   $0x0,(%eax)
f0100e19:	74 17                	je     f0100e32 <page_free+0x2c>
		panic("pp->pp_ref is nonzero or pp->pp_link is not NULL\n");
f0100e1b:	83 ec 04             	sub    $0x4,%esp
f0100e1e:	68 60 3c 10 f0       	push   $0xf0103c60
f0100e23:	68 48 01 00 00       	push   $0x148
f0100e28:	68 dc 42 10 f0       	push   $0xf01042dc
f0100e2d:	e8 59 f2 ff ff       	call   f010008b <_panic>
	}
	pp->pp_link = page_free_list;
f0100e32:	8b 15 3c 65 11 f0    	mov    0xf011653c,%edx
f0100e38:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f0100e3a:	a3 3c 65 11 f0       	mov    %eax,0xf011653c


}
f0100e3f:	c9                   	leave  
f0100e40:	c3                   	ret    

f0100e41 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0100e41:	55                   	push   %ebp
f0100e42:	89 e5                	mov    %esp,%ebp
f0100e44:	83 ec 08             	sub    $0x8,%esp
f0100e47:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0100e4a:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0100e4e:	83 e8 01             	sub    $0x1,%eax
f0100e51:	66 89 42 04          	mov    %ax,0x4(%edx)
f0100e55:	66 85 c0             	test   %ax,%ax
f0100e58:	75 0c                	jne    f0100e66 <page_decref+0x25>
		page_free(pp);
f0100e5a:	83 ec 0c             	sub    $0xc,%esp
f0100e5d:	52                   	push   %edx
f0100e5e:	e8 a3 ff ff ff       	call   f0100e06 <page_free>
f0100e63:	83 c4 10             	add    $0x10,%esp
}
f0100e66:	c9                   	leave  
f0100e67:	c3                   	ret    

f0100e68 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100e68:	55                   	push   %ebp
f0100e69:	89 e5                	mov    %esp,%ebp
f0100e6b:	56                   	push   %esi
f0100e6c:	53                   	push   %ebx
f0100e6d:	8b 75 0c             	mov    0xc(%ebp),%esi
	int pdr_i = PDX(va);
	pde_t *pde = &pgdir[pdr_i];
f0100e70:	89 f3                	mov    %esi,%ebx
f0100e72:	c1 eb 16             	shr    $0x16,%ebx
f0100e75:	c1 e3 02             	shl    $0x2,%ebx
f0100e78:	03 5d 08             	add    0x8(%ebp),%ebx
	pte_t *pgt;
	if(!(*pde & PTE_P)){
f0100e7b:	f6 03 01             	testb  $0x1,(%ebx)
f0100e7e:	75 2f                	jne    f0100eaf <pgdir_walk+0x47>
		if(!create)	
f0100e80:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100e84:	74 64                	je     f0100eea <pgdir_walk+0x82>
			return NULL;
		struct PageInfo *page = page_alloc(ALLOC_ZERO);
f0100e86:	83 ec 0c             	sub    $0xc,%esp
f0100e89:	6a 01                	push   $0x1
f0100e8b:	e8 ff fe ff ff       	call   f0100d8f <page_alloc>
		if(page == NULL) return NULL;
f0100e90:	83 c4 10             	add    $0x10,%esp
f0100e93:	85 c0                	test   %eax,%eax
f0100e95:	74 5a                	je     f0100ef1 <pgdir_walk+0x89>
		*pde = page2pa(page) | PTE_P | PTE_U | PTE_W;
f0100e97:	89 c2                	mov    %eax,%edx
f0100e99:	2b 15 4c 69 11 f0    	sub    0xf011694c,%edx
f0100e9f:	c1 fa 03             	sar    $0x3,%edx
f0100ea2:	c1 e2 0c             	shl    $0xc,%edx
f0100ea5:	83 ca 07             	or     $0x7,%edx
f0100ea8:	89 13                	mov    %edx,(%ebx)
		page->pp_ref ++;
f0100eaa:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
	}
	pgt = KADDR(PTE_ADDR(*pde));
f0100eaf:	8b 03                	mov    (%ebx),%eax
f0100eb1:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100eb6:	89 c2                	mov    %eax,%edx
f0100eb8:	c1 ea 0c             	shr    $0xc,%edx
f0100ebb:	3b 15 44 69 11 f0    	cmp    0xf0116944,%edx
f0100ec1:	72 15                	jb     f0100ed8 <pgdir_walk+0x70>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ec3:	50                   	push   %eax
f0100ec4:	68 54 3b 10 f0       	push   $0xf0103b54
f0100ec9:	68 7f 01 00 00       	push   $0x17f
f0100ece:	68 dc 42 10 f0       	push   $0xf01042dc
f0100ed3:	e8 b3 f1 ff ff       	call   f010008b <_panic>
	
	return &pgt[PTX(va)];
f0100ed8:	c1 ee 0a             	shr    $0xa,%esi
f0100edb:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f0100ee1:	8d 84 30 00 00 00 f0 	lea    -0x10000000(%eax,%esi,1),%eax
f0100ee8:	eb 0c                	jmp    f0100ef6 <pgdir_walk+0x8e>
	int pdr_i = PDX(va);
	pde_t *pde = &pgdir[pdr_i];
	pte_t *pgt;
	if(!(*pde & PTE_P)){
		if(!create)	
			return NULL;
f0100eea:	b8 00 00 00 00       	mov    $0x0,%eax
f0100eef:	eb 05                	jmp    f0100ef6 <pgdir_walk+0x8e>
		struct PageInfo *page = page_alloc(ALLOC_ZERO);
		if(page == NULL) return NULL;
f0100ef1:	b8 00 00 00 00       	mov    $0x0,%eax
		page->pp_ref ++;
	}
	pgt = KADDR(PTE_ADDR(*pde));
	
	return &pgt[PTX(va)];
}
f0100ef6:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100ef9:	5b                   	pop    %ebx
f0100efa:	5e                   	pop    %esi
f0100efb:	5d                   	pop    %ebp
f0100efc:	c3                   	ret    

f0100efd <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f0100efd:	55                   	push   %ebp
f0100efe:	89 e5                	mov    %esp,%ebp
f0100f00:	57                   	push   %edi
f0100f01:	56                   	push   %esi
f0100f02:	53                   	push   %ebx
f0100f03:	83 ec 1c             	sub    $0x1c,%esp
f0100f06:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0100f09:	c1 e9 0c             	shr    $0xc,%ecx
f0100f0c:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	int i;
	for(i = 0; i < (size / PGSIZE); i++, va += PGSIZE, pa+=PGSIZE){
f0100f0f:	89 d3                	mov    %edx,%ebx
f0100f11:	bf 00 00 00 00       	mov    $0x0,%edi
f0100f16:	8b 45 08             	mov    0x8(%ebp),%eax
f0100f19:	29 d0                	sub    %edx,%eax
f0100f1b:	89 45 e0             	mov    %eax,-0x20(%ebp)
		pte_t* pte = pgdir_walk(pgdir,(const void *) va, 1);	
		if(pte!=NULL){
			*pte = pa|perm|PTE_P;
f0100f1e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100f21:	83 c8 01             	or     $0x1,%eax
f0100f24:	89 45 d8             	mov    %eax,-0x28(%ebp)
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	int i;
	for(i = 0; i < (size / PGSIZE); i++, va += PGSIZE, pa+=PGSIZE){
f0100f27:	eb 23                	jmp    f0100f4c <boot_map_region+0x4f>
		pte_t* pte = pgdir_walk(pgdir,(const void *) va, 1);	
f0100f29:	83 ec 04             	sub    $0x4,%esp
f0100f2c:	6a 01                	push   $0x1
f0100f2e:	53                   	push   %ebx
f0100f2f:	ff 75 dc             	pushl  -0x24(%ebp)
f0100f32:	e8 31 ff ff ff       	call   f0100e68 <pgdir_walk>
		if(pte!=NULL){
f0100f37:	83 c4 10             	add    $0x10,%esp
f0100f3a:	85 c0                	test   %eax,%eax
f0100f3c:	74 05                	je     f0100f43 <boot_map_region+0x46>
			*pte = pa|perm|PTE_P;
f0100f3e:	0b 75 d8             	or     -0x28(%ebp),%esi
f0100f41:	89 30                	mov    %esi,(%eax)
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	int i;
	for(i = 0; i < (size / PGSIZE); i++, va += PGSIZE, pa+=PGSIZE){
f0100f43:	83 c7 01             	add    $0x1,%edi
f0100f46:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0100f4c:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100f4f:	8d 34 18             	lea    (%eax,%ebx,1),%esi
f0100f52:	3b 7d e4             	cmp    -0x1c(%ebp),%edi
f0100f55:	75 d2                	jne    f0100f29 <boot_map_region+0x2c>
		pte_t* pte = pgdir_walk(pgdir,(const void *) va, 1);	
		if(pte!=NULL){
			*pte = pa|perm|PTE_P;
		}
	}
}
f0100f57:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100f5a:	5b                   	pop    %ebx
f0100f5b:	5e                   	pop    %esi
f0100f5c:	5f                   	pop    %edi
f0100f5d:	5d                   	pop    %ebp
f0100f5e:	c3                   	ret    

f0100f5f <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0100f5f:	55                   	push   %ebp
f0100f60:	89 e5                	mov    %esp,%ebp
f0100f62:	53                   	push   %ebx
f0100f63:	83 ec 08             	sub    $0x8,%esp
f0100f66:	8b 5d 10             	mov    0x10(%ebp),%ebx
	pte_t *pte = pgdir_walk(pgdir, va, 0);
f0100f69:	6a 00                	push   $0x0
f0100f6b:	ff 75 0c             	pushl  0xc(%ebp)
f0100f6e:	ff 75 08             	pushl  0x8(%ebp)
f0100f71:	e8 f2 fe ff ff       	call   f0100e68 <pgdir_walk>
	if(pte == NULL)
f0100f76:	83 c4 10             	add    $0x10,%esp
f0100f79:	85 c0                	test   %eax,%eax
f0100f7b:	74 32                	je     f0100faf <page_lookup+0x50>
		return NULL;
	else{
		if(pte_store!=NULL)		
f0100f7d:	85 db                	test   %ebx,%ebx
f0100f7f:	74 02                	je     f0100f83 <page_lookup+0x24>
			*pte_store = pte;
f0100f81:	89 03                	mov    %eax,(%ebx)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100f83:	8b 00                	mov    (%eax),%eax
f0100f85:	c1 e8 0c             	shr    $0xc,%eax
f0100f88:	3b 05 44 69 11 f0    	cmp    0xf0116944,%eax
f0100f8e:	72 14                	jb     f0100fa4 <page_lookup+0x45>
		panic("pa2page called with invalid pa");
f0100f90:	83 ec 04             	sub    $0x4,%esp
f0100f93:	68 94 3c 10 f0       	push   $0xf0103c94
f0100f98:	6a 4b                	push   $0x4b
f0100f9a:	68 f7 42 10 f0       	push   $0xf01042f7
f0100f9f:	e8 e7 f0 ff ff       	call   f010008b <_panic>
	return &pages[PGNUM(pa)];
f0100fa4:	8b 15 4c 69 11 f0    	mov    0xf011694c,%edx
f0100faa:	8d 04 c2             	lea    (%edx,%eax,8),%eax
		
		return pa2page(PTE_ADDR(*pte));
f0100fad:	eb 05                	jmp    f0100fb4 <page_lookup+0x55>
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
	pte_t *pte = pgdir_walk(pgdir, va, 0);
	if(pte == NULL)
		return NULL;
f0100faf:	b8 00 00 00 00       	mov    $0x0,%eax
			*pte_store = pte;
		
		return pa2page(PTE_ADDR(*pte));
	}

}
f0100fb4:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100fb7:	c9                   	leave  
f0100fb8:	c3                   	ret    

f0100fb9 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0100fb9:	55                   	push   %ebp
f0100fba:	89 e5                	mov    %esp,%ebp
f0100fbc:	53                   	push   %ebx
f0100fbd:	83 ec 18             	sub    $0x18,%esp
f0100fc0:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
	pte_t *pte;
	struct PageInfo *pp = page_lookup(pgdir, va, &pte);
f0100fc3:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100fc6:	50                   	push   %eax
f0100fc7:	53                   	push   %ebx
f0100fc8:	ff 75 08             	pushl  0x8(%ebp)
f0100fcb:	e8 8f ff ff ff       	call   f0100f5f <page_lookup>
	if(pp!=NULL){
f0100fd0:	83 c4 10             	add    $0x10,%esp
f0100fd3:	85 c0                	test   %eax,%eax
f0100fd5:	74 18                	je     f0100fef <page_remove+0x36>
		page_decref(pp);
f0100fd7:	83 ec 0c             	sub    $0xc,%esp
f0100fda:	50                   	push   %eax
f0100fdb:	e8 61 fe ff ff       	call   f0100e41 <page_decref>
		*pte = 0;
f0100fe0:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100fe3:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0100fe9:	0f 01 3b             	invlpg (%ebx)
f0100fec:	83 c4 10             	add    $0x10,%esp
		tlb_invalidate(pgdir, va);
	}
}
f0100fef:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100ff2:	c9                   	leave  
f0100ff3:	c3                   	ret    

f0100ff4 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f0100ff4:	55                   	push   %ebp
f0100ff5:	89 e5                	mov    %esp,%ebp
f0100ff7:	57                   	push   %edi
f0100ff8:	56                   	push   %esi
f0100ff9:	53                   	push   %ebx
f0100ffa:	83 ec 10             	sub    $0x10,%esp
f0100ffd:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101000:	8b 7d 10             	mov    0x10(%ebp),%edi
	pte_t *pte = pgdir_walk(pgdir, va, 1); 
f0101003:	6a 01                	push   $0x1
f0101005:	57                   	push   %edi
f0101006:	ff 75 08             	pushl  0x8(%ebp)
f0101009:	e8 5a fe ff ff       	call   f0100e68 <pgdir_walk>
	if(pte){
f010100e:	83 c4 10             	add    $0x10,%esp
f0101011:	85 c0                	test   %eax,%eax
f0101013:	74 3e                	je     f0101053 <page_insert+0x5f>
f0101015:	89 c6                	mov    %eax,%esi
		pp->pp_ref ++;
f0101017:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
		if(PTE_ADDR(*pte))
f010101c:	f7 00 00 f0 ff ff    	testl  $0xfffff000,(%eax)
f0101022:	74 0f                	je     f0101033 <page_insert+0x3f>
			page_remove(pgdir, va);
f0101024:	83 ec 08             	sub    $0x8,%esp
f0101027:	57                   	push   %edi
f0101028:	ff 75 08             	pushl  0x8(%ebp)
f010102b:	e8 89 ff ff ff       	call   f0100fb9 <page_remove>
f0101030:	83 c4 10             	add    $0x10,%esp
		*pte = page2pa(pp) | perm |PTE_P;
f0101033:	2b 1d 4c 69 11 f0    	sub    0xf011694c,%ebx
f0101039:	c1 fb 03             	sar    $0x3,%ebx
f010103c:	c1 e3 0c             	shl    $0xc,%ebx
f010103f:	8b 45 14             	mov    0x14(%ebp),%eax
f0101042:	83 c8 01             	or     $0x1,%eax
f0101045:	09 c3                	or     %eax,%ebx
f0101047:	89 1e                	mov    %ebx,(%esi)
f0101049:	0f 01 3f             	invlpg (%edi)
		tlb_invalidate(pgdir, va);
		return 0;
f010104c:	b8 00 00 00 00       	mov    $0x0,%eax
f0101051:	eb 05                	jmp    f0101058 <page_insert+0x64>
	}
	return -E_NO_MEM;
f0101053:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	
}
f0101058:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010105b:	5b                   	pop    %ebx
f010105c:	5e                   	pop    %esi
f010105d:	5f                   	pop    %edi
f010105e:	5d                   	pop    %ebp
f010105f:	c3                   	ret    

f0101060 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0101060:	55                   	push   %ebp
f0101061:	89 e5                	mov    %esp,%ebp
f0101063:	57                   	push   %edi
f0101064:	56                   	push   %esi
f0101065:	53                   	push   %ebx
f0101066:	83 ec 2c             	sub    $0x2c,%esp
{
	size_t basemem, extmem, ext16mem, totalmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	basemem = nvram_read(NVRAM_BASELO);
f0101069:	b8 15 00 00 00       	mov    $0x15,%eax
f010106e:	e8 61 f8 ff ff       	call   f01008d4 <nvram_read>
f0101073:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f0101075:	b8 17 00 00 00       	mov    $0x17,%eax
f010107a:	e8 55 f8 ff ff       	call   f01008d4 <nvram_read>
f010107f:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f0101081:	b8 34 00 00 00       	mov    $0x34,%eax
f0101086:	e8 49 f8 ff ff       	call   f01008d4 <nvram_read>
f010108b:	c1 e0 06             	shl    $0x6,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (ext16mem)
f010108e:	85 c0                	test   %eax,%eax
f0101090:	74 07                	je     f0101099 <mem_init+0x39>
		totalmem = 16 * 1024 + ext16mem;
f0101092:	05 00 40 00 00       	add    $0x4000,%eax
f0101097:	eb 0b                	jmp    f01010a4 <mem_init+0x44>
	else if (extmem)
		totalmem = 1 * 1024 + extmem;
f0101099:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f010109f:	85 f6                	test   %esi,%esi
f01010a1:	0f 44 c3             	cmove  %ebx,%eax
	else
		totalmem = basemem;

	npages = totalmem / (PGSIZE / 1024);
f01010a4:	89 c2                	mov    %eax,%edx
f01010a6:	c1 ea 02             	shr    $0x2,%edx
f01010a9:	89 15 44 69 11 f0    	mov    %edx,0xf0116944
	npages_basemem = basemem / (PGSIZE / 1024);

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01010af:	89 c2                	mov    %eax,%edx
f01010b1:	29 da                	sub    %ebx,%edx
f01010b3:	52                   	push   %edx
f01010b4:	53                   	push   %ebx
f01010b5:	50                   	push   %eax
f01010b6:	68 b4 3c 10 f0       	push   $0xf0103cb4
f01010bb:	e8 46 16 00 00       	call   f0102706 <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f01010c0:	b8 00 10 00 00       	mov    $0x1000,%eax
f01010c5:	e8 97 f8 ff ff       	call   f0100961 <boot_alloc>
f01010ca:	a3 48 69 11 f0       	mov    %eax,0xf0116948
	memset(kern_pgdir, 0, PGSIZE);
f01010cf:	83 c4 0c             	add    $0xc,%esp
f01010d2:	68 00 10 00 00       	push   $0x1000
f01010d7:	6a 00                	push   $0x0
f01010d9:	50                   	push   %eax
f01010da:	e8 e0 20 00 00       	call   f01031bf <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f01010df:	a1 48 69 11 f0       	mov    0xf0116948,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01010e4:	83 c4 10             	add    $0x10,%esp
f01010e7:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01010ec:	77 15                	ja     f0101103 <mem_init+0xa3>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01010ee:	50                   	push   %eax
f01010ef:	68 78 3b 10 f0       	push   $0xf0103b78
f01010f4:	68 93 00 00 00       	push   $0x93
f01010f9:	68 dc 42 10 f0       	push   $0xf01042dc
f01010fe:	e8 88 ef ff ff       	call   f010008b <_panic>
f0101103:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0101109:	83 ca 05             	or     $0x5,%edx
f010110c:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	pages = (struct PageInfo *) boot_alloc(npages * sizeof(struct PageInfo));
f0101112:	a1 44 69 11 f0       	mov    0xf0116944,%eax
f0101117:	c1 e0 03             	shl    $0x3,%eax
f010111a:	e8 42 f8 ff ff       	call   f0100961 <boot_alloc>
f010111f:	a3 4c 69 11 f0       	mov    %eax,0xf011694c
	memset(pages, 0, npages * sizeof(struct PageInfo));
f0101124:	83 ec 04             	sub    $0x4,%esp
f0101127:	8b 0d 44 69 11 f0    	mov    0xf0116944,%ecx
f010112d:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f0101134:	52                   	push   %edx
f0101135:	6a 00                	push   $0x0
f0101137:	50                   	push   %eax
f0101138:	e8 82 20 00 00       	call   f01031bf <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f010113d:	e8 5a fb ff ff       	call   f0100c9c <page_init>

	check_page_free_list(1);
f0101142:	b8 01 00 00 00       	mov    $0x1,%eax
f0101147:	e8 9c f8 ff ff       	call   f01009e8 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f010114c:	83 c4 10             	add    $0x10,%esp
f010114f:	83 3d 4c 69 11 f0 00 	cmpl   $0x0,0xf011694c
f0101156:	75 17                	jne    f010116f <mem_init+0x10f>
		panic("'pages' is a null pointer!");
f0101158:	83 ec 04             	sub    $0x4,%esp
f010115b:	68 a1 43 10 f0       	push   $0xf01043a1
f0101160:	68 54 02 00 00       	push   $0x254
f0101165:	68 dc 42 10 f0       	push   $0xf01042dc
f010116a:	e8 1c ef ff ff       	call   f010008b <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010116f:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f0101174:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101179:	eb 05                	jmp    f0101180 <mem_init+0x120>
		++nfree;
f010117b:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010117e:	8b 00                	mov    (%eax),%eax
f0101180:	85 c0                	test   %eax,%eax
f0101182:	75 f7                	jne    f010117b <mem_init+0x11b>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101184:	83 ec 0c             	sub    $0xc,%esp
f0101187:	6a 00                	push   $0x0
f0101189:	e8 01 fc ff ff       	call   f0100d8f <page_alloc>
f010118e:	89 c7                	mov    %eax,%edi
f0101190:	83 c4 10             	add    $0x10,%esp
f0101193:	85 c0                	test   %eax,%eax
f0101195:	75 19                	jne    f01011b0 <mem_init+0x150>
f0101197:	68 bc 43 10 f0       	push   $0xf01043bc
f010119c:	68 11 43 10 f0       	push   $0xf0104311
f01011a1:	68 5c 02 00 00       	push   $0x25c
f01011a6:	68 dc 42 10 f0       	push   $0xf01042dc
f01011ab:	e8 db ee ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f01011b0:	83 ec 0c             	sub    $0xc,%esp
f01011b3:	6a 00                	push   $0x0
f01011b5:	e8 d5 fb ff ff       	call   f0100d8f <page_alloc>
f01011ba:	89 c6                	mov    %eax,%esi
f01011bc:	83 c4 10             	add    $0x10,%esp
f01011bf:	85 c0                	test   %eax,%eax
f01011c1:	75 19                	jne    f01011dc <mem_init+0x17c>
f01011c3:	68 d2 43 10 f0       	push   $0xf01043d2
f01011c8:	68 11 43 10 f0       	push   $0xf0104311
f01011cd:	68 5d 02 00 00       	push   $0x25d
f01011d2:	68 dc 42 10 f0       	push   $0xf01042dc
f01011d7:	e8 af ee ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f01011dc:	83 ec 0c             	sub    $0xc,%esp
f01011df:	6a 00                	push   $0x0
f01011e1:	e8 a9 fb ff ff       	call   f0100d8f <page_alloc>
f01011e6:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01011e9:	83 c4 10             	add    $0x10,%esp
f01011ec:	85 c0                	test   %eax,%eax
f01011ee:	75 19                	jne    f0101209 <mem_init+0x1a9>
f01011f0:	68 e8 43 10 f0       	push   $0xf01043e8
f01011f5:	68 11 43 10 f0       	push   $0xf0104311
f01011fa:	68 5e 02 00 00       	push   $0x25e
f01011ff:	68 dc 42 10 f0       	push   $0xf01042dc
f0101204:	e8 82 ee ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101209:	39 f7                	cmp    %esi,%edi
f010120b:	75 19                	jne    f0101226 <mem_init+0x1c6>
f010120d:	68 fe 43 10 f0       	push   $0xf01043fe
f0101212:	68 11 43 10 f0       	push   $0xf0104311
f0101217:	68 61 02 00 00       	push   $0x261
f010121c:	68 dc 42 10 f0       	push   $0xf01042dc
f0101221:	e8 65 ee ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101226:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101229:	39 c6                	cmp    %eax,%esi
f010122b:	74 04                	je     f0101231 <mem_init+0x1d1>
f010122d:	39 c7                	cmp    %eax,%edi
f010122f:	75 19                	jne    f010124a <mem_init+0x1ea>
f0101231:	68 f0 3c 10 f0       	push   $0xf0103cf0
f0101236:	68 11 43 10 f0       	push   $0xf0104311
f010123b:	68 62 02 00 00       	push   $0x262
f0101240:	68 dc 42 10 f0       	push   $0xf01042dc
f0101245:	e8 41 ee ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010124a:	8b 0d 4c 69 11 f0    	mov    0xf011694c,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101250:	8b 15 44 69 11 f0    	mov    0xf0116944,%edx
f0101256:	c1 e2 0c             	shl    $0xc,%edx
f0101259:	89 f8                	mov    %edi,%eax
f010125b:	29 c8                	sub    %ecx,%eax
f010125d:	c1 f8 03             	sar    $0x3,%eax
f0101260:	c1 e0 0c             	shl    $0xc,%eax
f0101263:	39 d0                	cmp    %edx,%eax
f0101265:	72 19                	jb     f0101280 <mem_init+0x220>
f0101267:	68 10 44 10 f0       	push   $0xf0104410
f010126c:	68 11 43 10 f0       	push   $0xf0104311
f0101271:	68 63 02 00 00       	push   $0x263
f0101276:	68 dc 42 10 f0       	push   $0xf01042dc
f010127b:	e8 0b ee ff ff       	call   f010008b <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f0101280:	89 f0                	mov    %esi,%eax
f0101282:	29 c8                	sub    %ecx,%eax
f0101284:	c1 f8 03             	sar    $0x3,%eax
f0101287:	c1 e0 0c             	shl    $0xc,%eax
f010128a:	39 c2                	cmp    %eax,%edx
f010128c:	77 19                	ja     f01012a7 <mem_init+0x247>
f010128e:	68 2d 44 10 f0       	push   $0xf010442d
f0101293:	68 11 43 10 f0       	push   $0xf0104311
f0101298:	68 64 02 00 00       	push   $0x264
f010129d:	68 dc 42 10 f0       	push   $0xf01042dc
f01012a2:	e8 e4 ed ff ff       	call   f010008b <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f01012a7:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01012aa:	29 c8                	sub    %ecx,%eax
f01012ac:	c1 f8 03             	sar    $0x3,%eax
f01012af:	c1 e0 0c             	shl    $0xc,%eax
f01012b2:	39 c2                	cmp    %eax,%edx
f01012b4:	77 19                	ja     f01012cf <mem_init+0x26f>
f01012b6:	68 4a 44 10 f0       	push   $0xf010444a
f01012bb:	68 11 43 10 f0       	push   $0xf0104311
f01012c0:	68 65 02 00 00       	push   $0x265
f01012c5:	68 dc 42 10 f0       	push   $0xf01042dc
f01012ca:	e8 bc ed ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01012cf:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f01012d4:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01012d7:	c7 05 3c 65 11 f0 00 	movl   $0x0,0xf011653c
f01012de:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01012e1:	83 ec 0c             	sub    $0xc,%esp
f01012e4:	6a 00                	push   $0x0
f01012e6:	e8 a4 fa ff ff       	call   f0100d8f <page_alloc>
f01012eb:	83 c4 10             	add    $0x10,%esp
f01012ee:	85 c0                	test   %eax,%eax
f01012f0:	74 19                	je     f010130b <mem_init+0x2ab>
f01012f2:	68 67 44 10 f0       	push   $0xf0104467
f01012f7:	68 11 43 10 f0       	push   $0xf0104311
f01012fc:	68 6c 02 00 00       	push   $0x26c
f0101301:	68 dc 42 10 f0       	push   $0xf01042dc
f0101306:	e8 80 ed ff ff       	call   f010008b <_panic>

	// free and re-allocate?
	page_free(pp0);
f010130b:	83 ec 0c             	sub    $0xc,%esp
f010130e:	57                   	push   %edi
f010130f:	e8 f2 fa ff ff       	call   f0100e06 <page_free>
	page_free(pp1);
f0101314:	89 34 24             	mov    %esi,(%esp)
f0101317:	e8 ea fa ff ff       	call   f0100e06 <page_free>
	page_free(pp2);
f010131c:	83 c4 04             	add    $0x4,%esp
f010131f:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101322:	e8 df fa ff ff       	call   f0100e06 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101327:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010132e:	e8 5c fa ff ff       	call   f0100d8f <page_alloc>
f0101333:	89 c6                	mov    %eax,%esi
f0101335:	83 c4 10             	add    $0x10,%esp
f0101338:	85 c0                	test   %eax,%eax
f010133a:	75 19                	jne    f0101355 <mem_init+0x2f5>
f010133c:	68 bc 43 10 f0       	push   $0xf01043bc
f0101341:	68 11 43 10 f0       	push   $0xf0104311
f0101346:	68 73 02 00 00       	push   $0x273
f010134b:	68 dc 42 10 f0       	push   $0xf01042dc
f0101350:	e8 36 ed ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f0101355:	83 ec 0c             	sub    $0xc,%esp
f0101358:	6a 00                	push   $0x0
f010135a:	e8 30 fa ff ff       	call   f0100d8f <page_alloc>
f010135f:	89 c7                	mov    %eax,%edi
f0101361:	83 c4 10             	add    $0x10,%esp
f0101364:	85 c0                	test   %eax,%eax
f0101366:	75 19                	jne    f0101381 <mem_init+0x321>
f0101368:	68 d2 43 10 f0       	push   $0xf01043d2
f010136d:	68 11 43 10 f0       	push   $0xf0104311
f0101372:	68 74 02 00 00       	push   $0x274
f0101377:	68 dc 42 10 f0       	push   $0xf01042dc
f010137c:	e8 0a ed ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0101381:	83 ec 0c             	sub    $0xc,%esp
f0101384:	6a 00                	push   $0x0
f0101386:	e8 04 fa ff ff       	call   f0100d8f <page_alloc>
f010138b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010138e:	83 c4 10             	add    $0x10,%esp
f0101391:	85 c0                	test   %eax,%eax
f0101393:	75 19                	jne    f01013ae <mem_init+0x34e>
f0101395:	68 e8 43 10 f0       	push   $0xf01043e8
f010139a:	68 11 43 10 f0       	push   $0xf0104311
f010139f:	68 75 02 00 00       	push   $0x275
f01013a4:	68 dc 42 10 f0       	push   $0xf01042dc
f01013a9:	e8 dd ec ff ff       	call   f010008b <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01013ae:	39 fe                	cmp    %edi,%esi
f01013b0:	75 19                	jne    f01013cb <mem_init+0x36b>
f01013b2:	68 fe 43 10 f0       	push   $0xf01043fe
f01013b7:	68 11 43 10 f0       	push   $0xf0104311
f01013bc:	68 77 02 00 00       	push   $0x277
f01013c1:	68 dc 42 10 f0       	push   $0xf01042dc
f01013c6:	e8 c0 ec ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01013cb:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01013ce:	39 c6                	cmp    %eax,%esi
f01013d0:	74 04                	je     f01013d6 <mem_init+0x376>
f01013d2:	39 c7                	cmp    %eax,%edi
f01013d4:	75 19                	jne    f01013ef <mem_init+0x38f>
f01013d6:	68 f0 3c 10 f0       	push   $0xf0103cf0
f01013db:	68 11 43 10 f0       	push   $0xf0104311
f01013e0:	68 78 02 00 00       	push   $0x278
f01013e5:	68 dc 42 10 f0       	push   $0xf01042dc
f01013ea:	e8 9c ec ff ff       	call   f010008b <_panic>
	assert(!page_alloc(0));
f01013ef:	83 ec 0c             	sub    $0xc,%esp
f01013f2:	6a 00                	push   $0x0
f01013f4:	e8 96 f9 ff ff       	call   f0100d8f <page_alloc>
f01013f9:	83 c4 10             	add    $0x10,%esp
f01013fc:	85 c0                	test   %eax,%eax
f01013fe:	74 19                	je     f0101419 <mem_init+0x3b9>
f0101400:	68 67 44 10 f0       	push   $0xf0104467
f0101405:	68 11 43 10 f0       	push   $0xf0104311
f010140a:	68 79 02 00 00       	push   $0x279
f010140f:	68 dc 42 10 f0       	push   $0xf01042dc
f0101414:	e8 72 ec ff ff       	call   f010008b <_panic>
f0101419:	89 f0                	mov    %esi,%eax
f010141b:	2b 05 4c 69 11 f0    	sub    0xf011694c,%eax
f0101421:	c1 f8 03             	sar    $0x3,%eax
f0101424:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101427:	89 c2                	mov    %eax,%edx
f0101429:	c1 ea 0c             	shr    $0xc,%edx
f010142c:	3b 15 44 69 11 f0    	cmp    0xf0116944,%edx
f0101432:	72 12                	jb     f0101446 <mem_init+0x3e6>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101434:	50                   	push   %eax
f0101435:	68 54 3b 10 f0       	push   $0xf0103b54
f010143a:	6a 52                	push   $0x52
f010143c:	68 f7 42 10 f0       	push   $0xf01042f7
f0101441:	e8 45 ec ff ff       	call   f010008b <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f0101446:	83 ec 04             	sub    $0x4,%esp
f0101449:	68 00 10 00 00       	push   $0x1000
f010144e:	6a 01                	push   $0x1
f0101450:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101455:	50                   	push   %eax
f0101456:	e8 64 1d 00 00       	call   f01031bf <memset>
	page_free(pp0);
f010145b:	89 34 24             	mov    %esi,(%esp)
f010145e:	e8 a3 f9 ff ff       	call   f0100e06 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101463:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f010146a:	e8 20 f9 ff ff       	call   f0100d8f <page_alloc>
f010146f:	83 c4 10             	add    $0x10,%esp
f0101472:	85 c0                	test   %eax,%eax
f0101474:	75 19                	jne    f010148f <mem_init+0x42f>
f0101476:	68 76 44 10 f0       	push   $0xf0104476
f010147b:	68 11 43 10 f0       	push   $0xf0104311
f0101480:	68 7e 02 00 00       	push   $0x27e
f0101485:	68 dc 42 10 f0       	push   $0xf01042dc
f010148a:	e8 fc eb ff ff       	call   f010008b <_panic>
	assert(pp && pp0 == pp);
f010148f:	39 c6                	cmp    %eax,%esi
f0101491:	74 19                	je     f01014ac <mem_init+0x44c>
f0101493:	68 94 44 10 f0       	push   $0xf0104494
f0101498:	68 11 43 10 f0       	push   $0xf0104311
f010149d:	68 7f 02 00 00       	push   $0x27f
f01014a2:	68 dc 42 10 f0       	push   $0xf01042dc
f01014a7:	e8 df eb ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01014ac:	89 f0                	mov    %esi,%eax
f01014ae:	2b 05 4c 69 11 f0    	sub    0xf011694c,%eax
f01014b4:	c1 f8 03             	sar    $0x3,%eax
f01014b7:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01014ba:	89 c2                	mov    %eax,%edx
f01014bc:	c1 ea 0c             	shr    $0xc,%edx
f01014bf:	3b 15 44 69 11 f0    	cmp    0xf0116944,%edx
f01014c5:	72 12                	jb     f01014d9 <mem_init+0x479>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01014c7:	50                   	push   %eax
f01014c8:	68 54 3b 10 f0       	push   $0xf0103b54
f01014cd:	6a 52                	push   $0x52
f01014cf:	68 f7 42 10 f0       	push   $0xf01042f7
f01014d4:	e8 b2 eb ff ff       	call   f010008b <_panic>
f01014d9:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f01014df:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f01014e5:	80 38 00             	cmpb   $0x0,(%eax)
f01014e8:	74 19                	je     f0101503 <mem_init+0x4a3>
f01014ea:	68 a4 44 10 f0       	push   $0xf01044a4
f01014ef:	68 11 43 10 f0       	push   $0xf0104311
f01014f4:	68 82 02 00 00       	push   $0x282
f01014f9:	68 dc 42 10 f0       	push   $0xf01042dc
f01014fe:	e8 88 eb ff ff       	call   f010008b <_panic>
f0101503:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f0101506:	39 d0                	cmp    %edx,%eax
f0101508:	75 db                	jne    f01014e5 <mem_init+0x485>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f010150a:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010150d:	a3 3c 65 11 f0       	mov    %eax,0xf011653c

	// free the pages we took
	page_free(pp0);
f0101512:	83 ec 0c             	sub    $0xc,%esp
f0101515:	56                   	push   %esi
f0101516:	e8 eb f8 ff ff       	call   f0100e06 <page_free>
	page_free(pp1);
f010151b:	89 3c 24             	mov    %edi,(%esp)
f010151e:	e8 e3 f8 ff ff       	call   f0100e06 <page_free>
	page_free(pp2);
f0101523:	83 c4 04             	add    $0x4,%esp
f0101526:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101529:	e8 d8 f8 ff ff       	call   f0100e06 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010152e:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f0101533:	83 c4 10             	add    $0x10,%esp
f0101536:	eb 05                	jmp    f010153d <mem_init+0x4dd>
		--nfree;
f0101538:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010153b:	8b 00                	mov    (%eax),%eax
f010153d:	85 c0                	test   %eax,%eax
f010153f:	75 f7                	jne    f0101538 <mem_init+0x4d8>
		--nfree;
	assert(nfree == 0);
f0101541:	85 db                	test   %ebx,%ebx
f0101543:	74 19                	je     f010155e <mem_init+0x4fe>
f0101545:	68 ae 44 10 f0       	push   $0xf01044ae
f010154a:	68 11 43 10 f0       	push   $0xf0104311
f010154f:	68 8f 02 00 00       	push   $0x28f
f0101554:	68 dc 42 10 f0       	push   $0xf01042dc
f0101559:	e8 2d eb ff ff       	call   f010008b <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f010155e:	83 ec 0c             	sub    $0xc,%esp
f0101561:	68 10 3d 10 f0       	push   $0xf0103d10
f0101566:	e8 9b 11 00 00       	call   f0102706 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010156b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101572:	e8 18 f8 ff ff       	call   f0100d8f <page_alloc>
f0101577:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010157a:	83 c4 10             	add    $0x10,%esp
f010157d:	85 c0                	test   %eax,%eax
f010157f:	75 19                	jne    f010159a <mem_init+0x53a>
f0101581:	68 bc 43 10 f0       	push   $0xf01043bc
f0101586:	68 11 43 10 f0       	push   $0xf0104311
f010158b:	68 e8 02 00 00       	push   $0x2e8
f0101590:	68 dc 42 10 f0       	push   $0xf01042dc
f0101595:	e8 f1 ea ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f010159a:	83 ec 0c             	sub    $0xc,%esp
f010159d:	6a 00                	push   $0x0
f010159f:	e8 eb f7 ff ff       	call   f0100d8f <page_alloc>
f01015a4:	89 c3                	mov    %eax,%ebx
f01015a6:	83 c4 10             	add    $0x10,%esp
f01015a9:	85 c0                	test   %eax,%eax
f01015ab:	75 19                	jne    f01015c6 <mem_init+0x566>
f01015ad:	68 d2 43 10 f0       	push   $0xf01043d2
f01015b2:	68 11 43 10 f0       	push   $0xf0104311
f01015b7:	68 e9 02 00 00       	push   $0x2e9
f01015bc:	68 dc 42 10 f0       	push   $0xf01042dc
f01015c1:	e8 c5 ea ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f01015c6:	83 ec 0c             	sub    $0xc,%esp
f01015c9:	6a 00                	push   $0x0
f01015cb:	e8 bf f7 ff ff       	call   f0100d8f <page_alloc>
f01015d0:	89 c6                	mov    %eax,%esi
f01015d2:	83 c4 10             	add    $0x10,%esp
f01015d5:	85 c0                	test   %eax,%eax
f01015d7:	75 19                	jne    f01015f2 <mem_init+0x592>
f01015d9:	68 e8 43 10 f0       	push   $0xf01043e8
f01015de:	68 11 43 10 f0       	push   $0xf0104311
f01015e3:	68 ea 02 00 00       	push   $0x2ea
f01015e8:	68 dc 42 10 f0       	push   $0xf01042dc
f01015ed:	e8 99 ea ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01015f2:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f01015f5:	75 19                	jne    f0101610 <mem_init+0x5b0>
f01015f7:	68 fe 43 10 f0       	push   $0xf01043fe
f01015fc:	68 11 43 10 f0       	push   $0xf0104311
f0101601:	68 ed 02 00 00       	push   $0x2ed
f0101606:	68 dc 42 10 f0       	push   $0xf01042dc
f010160b:	e8 7b ea ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101610:	39 c3                	cmp    %eax,%ebx
f0101612:	74 05                	je     f0101619 <mem_init+0x5b9>
f0101614:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101617:	75 19                	jne    f0101632 <mem_init+0x5d2>
f0101619:	68 f0 3c 10 f0       	push   $0xf0103cf0
f010161e:	68 11 43 10 f0       	push   $0xf0104311
f0101623:	68 ee 02 00 00       	push   $0x2ee
f0101628:	68 dc 42 10 f0       	push   $0xf01042dc
f010162d:	e8 59 ea ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101632:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f0101637:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f010163a:	c7 05 3c 65 11 f0 00 	movl   $0x0,0xf011653c
f0101641:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101644:	83 ec 0c             	sub    $0xc,%esp
f0101647:	6a 00                	push   $0x0
f0101649:	e8 41 f7 ff ff       	call   f0100d8f <page_alloc>
f010164e:	83 c4 10             	add    $0x10,%esp
f0101651:	85 c0                	test   %eax,%eax
f0101653:	74 19                	je     f010166e <mem_init+0x60e>
f0101655:	68 67 44 10 f0       	push   $0xf0104467
f010165a:	68 11 43 10 f0       	push   $0xf0104311
f010165f:	68 f5 02 00 00       	push   $0x2f5
f0101664:	68 dc 42 10 f0       	push   $0xf01042dc
f0101669:	e8 1d ea ff ff       	call   f010008b <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f010166e:	83 ec 04             	sub    $0x4,%esp
f0101671:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101674:	50                   	push   %eax
f0101675:	6a 00                	push   $0x0
f0101677:	ff 35 48 69 11 f0    	pushl  0xf0116948
f010167d:	e8 dd f8 ff ff       	call   f0100f5f <page_lookup>
f0101682:	83 c4 10             	add    $0x10,%esp
f0101685:	85 c0                	test   %eax,%eax
f0101687:	74 19                	je     f01016a2 <mem_init+0x642>
f0101689:	68 30 3d 10 f0       	push   $0xf0103d30
f010168e:	68 11 43 10 f0       	push   $0xf0104311
f0101693:	68 f8 02 00 00       	push   $0x2f8
f0101698:	68 dc 42 10 f0       	push   $0xf01042dc
f010169d:	e8 e9 e9 ff ff       	call   f010008b <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f01016a2:	6a 02                	push   $0x2
f01016a4:	6a 00                	push   $0x0
f01016a6:	53                   	push   %ebx
f01016a7:	ff 35 48 69 11 f0    	pushl  0xf0116948
f01016ad:	e8 42 f9 ff ff       	call   f0100ff4 <page_insert>
f01016b2:	83 c4 10             	add    $0x10,%esp
f01016b5:	85 c0                	test   %eax,%eax
f01016b7:	78 19                	js     f01016d2 <mem_init+0x672>
f01016b9:	68 68 3d 10 f0       	push   $0xf0103d68
f01016be:	68 11 43 10 f0       	push   $0xf0104311
f01016c3:	68 fb 02 00 00       	push   $0x2fb
f01016c8:	68 dc 42 10 f0       	push   $0xf01042dc
f01016cd:	e8 b9 e9 ff ff       	call   f010008b <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f01016d2:	83 ec 0c             	sub    $0xc,%esp
f01016d5:	ff 75 d4             	pushl  -0x2c(%ebp)
f01016d8:	e8 29 f7 ff ff       	call   f0100e06 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f01016dd:	6a 02                	push   $0x2
f01016df:	6a 00                	push   $0x0
f01016e1:	53                   	push   %ebx
f01016e2:	ff 35 48 69 11 f0    	pushl  0xf0116948
f01016e8:	e8 07 f9 ff ff       	call   f0100ff4 <page_insert>
f01016ed:	83 c4 20             	add    $0x20,%esp
f01016f0:	85 c0                	test   %eax,%eax
f01016f2:	74 19                	je     f010170d <mem_init+0x6ad>
f01016f4:	68 98 3d 10 f0       	push   $0xf0103d98
f01016f9:	68 11 43 10 f0       	push   $0xf0104311
f01016fe:	68 ff 02 00 00       	push   $0x2ff
f0101703:	68 dc 42 10 f0       	push   $0xf01042dc
f0101708:	e8 7e e9 ff ff       	call   f010008b <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010170d:	8b 3d 48 69 11 f0    	mov    0xf0116948,%edi
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101713:	a1 4c 69 11 f0       	mov    0xf011694c,%eax
f0101718:	89 c1                	mov    %eax,%ecx
f010171a:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010171d:	8b 17                	mov    (%edi),%edx
f010171f:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101725:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101728:	29 c8                	sub    %ecx,%eax
f010172a:	c1 f8 03             	sar    $0x3,%eax
f010172d:	c1 e0 0c             	shl    $0xc,%eax
f0101730:	39 c2                	cmp    %eax,%edx
f0101732:	74 19                	je     f010174d <mem_init+0x6ed>
f0101734:	68 c8 3d 10 f0       	push   $0xf0103dc8
f0101739:	68 11 43 10 f0       	push   $0xf0104311
f010173e:	68 00 03 00 00       	push   $0x300
f0101743:	68 dc 42 10 f0       	push   $0xf01042dc
f0101748:	e8 3e e9 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f010174d:	ba 00 00 00 00       	mov    $0x0,%edx
f0101752:	89 f8                	mov    %edi,%eax
f0101754:	e8 a4 f1 ff ff       	call   f01008fd <check_va2pa>
f0101759:	89 da                	mov    %ebx,%edx
f010175b:	2b 55 cc             	sub    -0x34(%ebp),%edx
f010175e:	c1 fa 03             	sar    $0x3,%edx
f0101761:	c1 e2 0c             	shl    $0xc,%edx
f0101764:	39 d0                	cmp    %edx,%eax
f0101766:	74 19                	je     f0101781 <mem_init+0x721>
f0101768:	68 f0 3d 10 f0       	push   $0xf0103df0
f010176d:	68 11 43 10 f0       	push   $0xf0104311
f0101772:	68 01 03 00 00       	push   $0x301
f0101777:	68 dc 42 10 f0       	push   $0xf01042dc
f010177c:	e8 0a e9 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 1);
f0101781:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101786:	74 19                	je     f01017a1 <mem_init+0x741>
f0101788:	68 b9 44 10 f0       	push   $0xf01044b9
f010178d:	68 11 43 10 f0       	push   $0xf0104311
f0101792:	68 02 03 00 00       	push   $0x302
f0101797:	68 dc 42 10 f0       	push   $0xf01042dc
f010179c:	e8 ea e8 ff ff       	call   f010008b <_panic>
	assert(pp0->pp_ref == 1);
f01017a1:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01017a4:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f01017a9:	74 19                	je     f01017c4 <mem_init+0x764>
f01017ab:	68 ca 44 10 f0       	push   $0xf01044ca
f01017b0:	68 11 43 10 f0       	push   $0xf0104311
f01017b5:	68 03 03 00 00       	push   $0x303
f01017ba:	68 dc 42 10 f0       	push   $0xf01042dc
f01017bf:	e8 c7 e8 ff ff       	call   f010008b <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01017c4:	6a 02                	push   $0x2
f01017c6:	68 00 10 00 00       	push   $0x1000
f01017cb:	56                   	push   %esi
f01017cc:	57                   	push   %edi
f01017cd:	e8 22 f8 ff ff       	call   f0100ff4 <page_insert>
f01017d2:	83 c4 10             	add    $0x10,%esp
f01017d5:	85 c0                	test   %eax,%eax
f01017d7:	74 19                	je     f01017f2 <mem_init+0x792>
f01017d9:	68 20 3e 10 f0       	push   $0xf0103e20
f01017de:	68 11 43 10 f0       	push   $0xf0104311
f01017e3:	68 06 03 00 00       	push   $0x306
f01017e8:	68 dc 42 10 f0       	push   $0xf01042dc
f01017ed:	e8 99 e8 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01017f2:	ba 00 10 00 00       	mov    $0x1000,%edx
f01017f7:	a1 48 69 11 f0       	mov    0xf0116948,%eax
f01017fc:	e8 fc f0 ff ff       	call   f01008fd <check_va2pa>
f0101801:	89 f2                	mov    %esi,%edx
f0101803:	2b 15 4c 69 11 f0    	sub    0xf011694c,%edx
f0101809:	c1 fa 03             	sar    $0x3,%edx
f010180c:	c1 e2 0c             	shl    $0xc,%edx
f010180f:	39 d0                	cmp    %edx,%eax
f0101811:	74 19                	je     f010182c <mem_init+0x7cc>
f0101813:	68 5c 3e 10 f0       	push   $0xf0103e5c
f0101818:	68 11 43 10 f0       	push   $0xf0104311
f010181d:	68 07 03 00 00       	push   $0x307
f0101822:	68 dc 42 10 f0       	push   $0xf01042dc
f0101827:	e8 5f e8 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f010182c:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101831:	74 19                	je     f010184c <mem_init+0x7ec>
f0101833:	68 db 44 10 f0       	push   $0xf01044db
f0101838:	68 11 43 10 f0       	push   $0xf0104311
f010183d:	68 08 03 00 00       	push   $0x308
f0101842:	68 dc 42 10 f0       	push   $0xf01042dc
f0101847:	e8 3f e8 ff ff       	call   f010008b <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f010184c:	83 ec 0c             	sub    $0xc,%esp
f010184f:	6a 00                	push   $0x0
f0101851:	e8 39 f5 ff ff       	call   f0100d8f <page_alloc>
f0101856:	83 c4 10             	add    $0x10,%esp
f0101859:	85 c0                	test   %eax,%eax
f010185b:	74 19                	je     f0101876 <mem_init+0x816>
f010185d:	68 67 44 10 f0       	push   $0xf0104467
f0101862:	68 11 43 10 f0       	push   $0xf0104311
f0101867:	68 0b 03 00 00       	push   $0x30b
f010186c:	68 dc 42 10 f0       	push   $0xf01042dc
f0101871:	e8 15 e8 ff ff       	call   f010008b <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101876:	6a 02                	push   $0x2
f0101878:	68 00 10 00 00       	push   $0x1000
f010187d:	56                   	push   %esi
f010187e:	ff 35 48 69 11 f0    	pushl  0xf0116948
f0101884:	e8 6b f7 ff ff       	call   f0100ff4 <page_insert>
f0101889:	83 c4 10             	add    $0x10,%esp
f010188c:	85 c0                	test   %eax,%eax
f010188e:	74 19                	je     f01018a9 <mem_init+0x849>
f0101890:	68 20 3e 10 f0       	push   $0xf0103e20
f0101895:	68 11 43 10 f0       	push   $0xf0104311
f010189a:	68 0e 03 00 00       	push   $0x30e
f010189f:	68 dc 42 10 f0       	push   $0xf01042dc
f01018a4:	e8 e2 e7 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01018a9:	ba 00 10 00 00       	mov    $0x1000,%edx
f01018ae:	a1 48 69 11 f0       	mov    0xf0116948,%eax
f01018b3:	e8 45 f0 ff ff       	call   f01008fd <check_va2pa>
f01018b8:	89 f2                	mov    %esi,%edx
f01018ba:	2b 15 4c 69 11 f0    	sub    0xf011694c,%edx
f01018c0:	c1 fa 03             	sar    $0x3,%edx
f01018c3:	c1 e2 0c             	shl    $0xc,%edx
f01018c6:	39 d0                	cmp    %edx,%eax
f01018c8:	74 19                	je     f01018e3 <mem_init+0x883>
f01018ca:	68 5c 3e 10 f0       	push   $0xf0103e5c
f01018cf:	68 11 43 10 f0       	push   $0xf0104311
f01018d4:	68 0f 03 00 00       	push   $0x30f
f01018d9:	68 dc 42 10 f0       	push   $0xf01042dc
f01018de:	e8 a8 e7 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f01018e3:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01018e8:	74 19                	je     f0101903 <mem_init+0x8a3>
f01018ea:	68 db 44 10 f0       	push   $0xf01044db
f01018ef:	68 11 43 10 f0       	push   $0xf0104311
f01018f4:	68 10 03 00 00       	push   $0x310
f01018f9:	68 dc 42 10 f0       	push   $0xf01042dc
f01018fe:	e8 88 e7 ff ff       	call   f010008b <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101903:	83 ec 0c             	sub    $0xc,%esp
f0101906:	6a 00                	push   $0x0
f0101908:	e8 82 f4 ff ff       	call   f0100d8f <page_alloc>
f010190d:	83 c4 10             	add    $0x10,%esp
f0101910:	85 c0                	test   %eax,%eax
f0101912:	74 19                	je     f010192d <mem_init+0x8cd>
f0101914:	68 67 44 10 f0       	push   $0xf0104467
f0101919:	68 11 43 10 f0       	push   $0xf0104311
f010191e:	68 14 03 00 00       	push   $0x314
f0101923:	68 dc 42 10 f0       	push   $0xf01042dc
f0101928:	e8 5e e7 ff ff       	call   f010008b <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f010192d:	8b 15 48 69 11 f0    	mov    0xf0116948,%edx
f0101933:	8b 02                	mov    (%edx),%eax
f0101935:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010193a:	89 c1                	mov    %eax,%ecx
f010193c:	c1 e9 0c             	shr    $0xc,%ecx
f010193f:	3b 0d 44 69 11 f0    	cmp    0xf0116944,%ecx
f0101945:	72 15                	jb     f010195c <mem_init+0x8fc>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101947:	50                   	push   %eax
f0101948:	68 54 3b 10 f0       	push   $0xf0103b54
f010194d:	68 17 03 00 00       	push   $0x317
f0101952:	68 dc 42 10 f0       	push   $0xf01042dc
f0101957:	e8 2f e7 ff ff       	call   f010008b <_panic>
f010195c:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101961:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101964:	83 ec 04             	sub    $0x4,%esp
f0101967:	6a 00                	push   $0x0
f0101969:	68 00 10 00 00       	push   $0x1000
f010196e:	52                   	push   %edx
f010196f:	e8 f4 f4 ff ff       	call   f0100e68 <pgdir_walk>
f0101974:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101977:	8d 51 04             	lea    0x4(%ecx),%edx
f010197a:	83 c4 10             	add    $0x10,%esp
f010197d:	39 d0                	cmp    %edx,%eax
f010197f:	74 19                	je     f010199a <mem_init+0x93a>
f0101981:	68 8c 3e 10 f0       	push   $0xf0103e8c
f0101986:	68 11 43 10 f0       	push   $0xf0104311
f010198b:	68 18 03 00 00       	push   $0x318
f0101990:	68 dc 42 10 f0       	push   $0xf01042dc
f0101995:	e8 f1 e6 ff ff       	call   f010008b <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f010199a:	6a 06                	push   $0x6
f010199c:	68 00 10 00 00       	push   $0x1000
f01019a1:	56                   	push   %esi
f01019a2:	ff 35 48 69 11 f0    	pushl  0xf0116948
f01019a8:	e8 47 f6 ff ff       	call   f0100ff4 <page_insert>
f01019ad:	83 c4 10             	add    $0x10,%esp
f01019b0:	85 c0                	test   %eax,%eax
f01019b2:	74 19                	je     f01019cd <mem_init+0x96d>
f01019b4:	68 cc 3e 10 f0       	push   $0xf0103ecc
f01019b9:	68 11 43 10 f0       	push   $0xf0104311
f01019be:	68 1b 03 00 00       	push   $0x31b
f01019c3:	68 dc 42 10 f0       	push   $0xf01042dc
f01019c8:	e8 be e6 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01019cd:	8b 3d 48 69 11 f0    	mov    0xf0116948,%edi
f01019d3:	ba 00 10 00 00       	mov    $0x1000,%edx
f01019d8:	89 f8                	mov    %edi,%eax
f01019da:	e8 1e ef ff ff       	call   f01008fd <check_va2pa>
f01019df:	89 f2                	mov    %esi,%edx
f01019e1:	2b 15 4c 69 11 f0    	sub    0xf011694c,%edx
f01019e7:	c1 fa 03             	sar    $0x3,%edx
f01019ea:	c1 e2 0c             	shl    $0xc,%edx
f01019ed:	39 d0                	cmp    %edx,%eax
f01019ef:	74 19                	je     f0101a0a <mem_init+0x9aa>
f01019f1:	68 5c 3e 10 f0       	push   $0xf0103e5c
f01019f6:	68 11 43 10 f0       	push   $0xf0104311
f01019fb:	68 1c 03 00 00       	push   $0x31c
f0101a00:	68 dc 42 10 f0       	push   $0xf01042dc
f0101a05:	e8 81 e6 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f0101a0a:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101a0f:	74 19                	je     f0101a2a <mem_init+0x9ca>
f0101a11:	68 db 44 10 f0       	push   $0xf01044db
f0101a16:	68 11 43 10 f0       	push   $0xf0104311
f0101a1b:	68 1d 03 00 00       	push   $0x31d
f0101a20:	68 dc 42 10 f0       	push   $0xf01042dc
f0101a25:	e8 61 e6 ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101a2a:	83 ec 04             	sub    $0x4,%esp
f0101a2d:	6a 00                	push   $0x0
f0101a2f:	68 00 10 00 00       	push   $0x1000
f0101a34:	57                   	push   %edi
f0101a35:	e8 2e f4 ff ff       	call   f0100e68 <pgdir_walk>
f0101a3a:	83 c4 10             	add    $0x10,%esp
f0101a3d:	f6 00 04             	testb  $0x4,(%eax)
f0101a40:	75 19                	jne    f0101a5b <mem_init+0x9fb>
f0101a42:	68 0c 3f 10 f0       	push   $0xf0103f0c
f0101a47:	68 11 43 10 f0       	push   $0xf0104311
f0101a4c:	68 1e 03 00 00       	push   $0x31e
f0101a51:	68 dc 42 10 f0       	push   $0xf01042dc
f0101a56:	e8 30 e6 ff ff       	call   f010008b <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101a5b:	a1 48 69 11 f0       	mov    0xf0116948,%eax
f0101a60:	f6 00 04             	testb  $0x4,(%eax)
f0101a63:	75 19                	jne    f0101a7e <mem_init+0xa1e>
f0101a65:	68 ec 44 10 f0       	push   $0xf01044ec
f0101a6a:	68 11 43 10 f0       	push   $0xf0104311
f0101a6f:	68 1f 03 00 00       	push   $0x31f
f0101a74:	68 dc 42 10 f0       	push   $0xf01042dc
f0101a79:	e8 0d e6 ff ff       	call   f010008b <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101a7e:	6a 02                	push   $0x2
f0101a80:	68 00 10 00 00       	push   $0x1000
f0101a85:	56                   	push   %esi
f0101a86:	50                   	push   %eax
f0101a87:	e8 68 f5 ff ff       	call   f0100ff4 <page_insert>
f0101a8c:	83 c4 10             	add    $0x10,%esp
f0101a8f:	85 c0                	test   %eax,%eax
f0101a91:	74 19                	je     f0101aac <mem_init+0xa4c>
f0101a93:	68 20 3e 10 f0       	push   $0xf0103e20
f0101a98:	68 11 43 10 f0       	push   $0xf0104311
f0101a9d:	68 22 03 00 00       	push   $0x322
f0101aa2:	68 dc 42 10 f0       	push   $0xf01042dc
f0101aa7:	e8 df e5 ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101aac:	83 ec 04             	sub    $0x4,%esp
f0101aaf:	6a 00                	push   $0x0
f0101ab1:	68 00 10 00 00       	push   $0x1000
f0101ab6:	ff 35 48 69 11 f0    	pushl  0xf0116948
f0101abc:	e8 a7 f3 ff ff       	call   f0100e68 <pgdir_walk>
f0101ac1:	83 c4 10             	add    $0x10,%esp
f0101ac4:	f6 00 02             	testb  $0x2,(%eax)
f0101ac7:	75 19                	jne    f0101ae2 <mem_init+0xa82>
f0101ac9:	68 40 3f 10 f0       	push   $0xf0103f40
f0101ace:	68 11 43 10 f0       	push   $0xf0104311
f0101ad3:	68 23 03 00 00       	push   $0x323
f0101ad8:	68 dc 42 10 f0       	push   $0xf01042dc
f0101add:	e8 a9 e5 ff ff       	call   f010008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101ae2:	83 ec 04             	sub    $0x4,%esp
f0101ae5:	6a 00                	push   $0x0
f0101ae7:	68 00 10 00 00       	push   $0x1000
f0101aec:	ff 35 48 69 11 f0    	pushl  0xf0116948
f0101af2:	e8 71 f3 ff ff       	call   f0100e68 <pgdir_walk>
f0101af7:	83 c4 10             	add    $0x10,%esp
f0101afa:	f6 00 04             	testb  $0x4,(%eax)
f0101afd:	74 19                	je     f0101b18 <mem_init+0xab8>
f0101aff:	68 74 3f 10 f0       	push   $0xf0103f74
f0101b04:	68 11 43 10 f0       	push   $0xf0104311
f0101b09:	68 24 03 00 00       	push   $0x324
f0101b0e:	68 dc 42 10 f0       	push   $0xf01042dc
f0101b13:	e8 73 e5 ff ff       	call   f010008b <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101b18:	6a 02                	push   $0x2
f0101b1a:	68 00 00 40 00       	push   $0x400000
f0101b1f:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101b22:	ff 35 48 69 11 f0    	pushl  0xf0116948
f0101b28:	e8 c7 f4 ff ff       	call   f0100ff4 <page_insert>
f0101b2d:	83 c4 10             	add    $0x10,%esp
f0101b30:	85 c0                	test   %eax,%eax
f0101b32:	78 19                	js     f0101b4d <mem_init+0xaed>
f0101b34:	68 ac 3f 10 f0       	push   $0xf0103fac
f0101b39:	68 11 43 10 f0       	push   $0xf0104311
f0101b3e:	68 27 03 00 00       	push   $0x327
f0101b43:	68 dc 42 10 f0       	push   $0xf01042dc
f0101b48:	e8 3e e5 ff ff       	call   f010008b <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101b4d:	6a 02                	push   $0x2
f0101b4f:	68 00 10 00 00       	push   $0x1000
f0101b54:	53                   	push   %ebx
f0101b55:	ff 35 48 69 11 f0    	pushl  0xf0116948
f0101b5b:	e8 94 f4 ff ff       	call   f0100ff4 <page_insert>
f0101b60:	83 c4 10             	add    $0x10,%esp
f0101b63:	85 c0                	test   %eax,%eax
f0101b65:	74 19                	je     f0101b80 <mem_init+0xb20>
f0101b67:	68 e4 3f 10 f0       	push   $0xf0103fe4
f0101b6c:	68 11 43 10 f0       	push   $0xf0104311
f0101b71:	68 2a 03 00 00       	push   $0x32a
f0101b76:	68 dc 42 10 f0       	push   $0xf01042dc
f0101b7b:	e8 0b e5 ff ff       	call   f010008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101b80:	83 ec 04             	sub    $0x4,%esp
f0101b83:	6a 00                	push   $0x0
f0101b85:	68 00 10 00 00       	push   $0x1000
f0101b8a:	ff 35 48 69 11 f0    	pushl  0xf0116948
f0101b90:	e8 d3 f2 ff ff       	call   f0100e68 <pgdir_walk>
f0101b95:	83 c4 10             	add    $0x10,%esp
f0101b98:	f6 00 04             	testb  $0x4,(%eax)
f0101b9b:	74 19                	je     f0101bb6 <mem_init+0xb56>
f0101b9d:	68 74 3f 10 f0       	push   $0xf0103f74
f0101ba2:	68 11 43 10 f0       	push   $0xf0104311
f0101ba7:	68 2b 03 00 00       	push   $0x32b
f0101bac:	68 dc 42 10 f0       	push   $0xf01042dc
f0101bb1:	e8 d5 e4 ff ff       	call   f010008b <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101bb6:	8b 3d 48 69 11 f0    	mov    0xf0116948,%edi
f0101bbc:	ba 00 00 00 00       	mov    $0x0,%edx
f0101bc1:	89 f8                	mov    %edi,%eax
f0101bc3:	e8 35 ed ff ff       	call   f01008fd <check_va2pa>
f0101bc8:	89 c1                	mov    %eax,%ecx
f0101bca:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101bcd:	89 d8                	mov    %ebx,%eax
f0101bcf:	2b 05 4c 69 11 f0    	sub    0xf011694c,%eax
f0101bd5:	c1 f8 03             	sar    $0x3,%eax
f0101bd8:	c1 e0 0c             	shl    $0xc,%eax
f0101bdb:	39 c1                	cmp    %eax,%ecx
f0101bdd:	74 19                	je     f0101bf8 <mem_init+0xb98>
f0101bdf:	68 20 40 10 f0       	push   $0xf0104020
f0101be4:	68 11 43 10 f0       	push   $0xf0104311
f0101be9:	68 2e 03 00 00       	push   $0x32e
f0101bee:	68 dc 42 10 f0       	push   $0xf01042dc
f0101bf3:	e8 93 e4 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101bf8:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101bfd:	89 f8                	mov    %edi,%eax
f0101bff:	e8 f9 ec ff ff       	call   f01008fd <check_va2pa>
f0101c04:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101c07:	74 19                	je     f0101c22 <mem_init+0xbc2>
f0101c09:	68 4c 40 10 f0       	push   $0xf010404c
f0101c0e:	68 11 43 10 f0       	push   $0xf0104311
f0101c13:	68 2f 03 00 00       	push   $0x32f
f0101c18:	68 dc 42 10 f0       	push   $0xf01042dc
f0101c1d:	e8 69 e4 ff ff       	call   f010008b <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101c22:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101c27:	74 19                	je     f0101c42 <mem_init+0xbe2>
f0101c29:	68 02 45 10 f0       	push   $0xf0104502
f0101c2e:	68 11 43 10 f0       	push   $0xf0104311
f0101c33:	68 31 03 00 00       	push   $0x331
f0101c38:	68 dc 42 10 f0       	push   $0xf01042dc
f0101c3d:	e8 49 e4 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101c42:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101c47:	74 19                	je     f0101c62 <mem_init+0xc02>
f0101c49:	68 13 45 10 f0       	push   $0xf0104513
f0101c4e:	68 11 43 10 f0       	push   $0xf0104311
f0101c53:	68 32 03 00 00       	push   $0x332
f0101c58:	68 dc 42 10 f0       	push   $0xf01042dc
f0101c5d:	e8 29 e4 ff ff       	call   f010008b <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101c62:	83 ec 0c             	sub    $0xc,%esp
f0101c65:	6a 00                	push   $0x0
f0101c67:	e8 23 f1 ff ff       	call   f0100d8f <page_alloc>
f0101c6c:	83 c4 10             	add    $0x10,%esp
f0101c6f:	39 c6                	cmp    %eax,%esi
f0101c71:	75 04                	jne    f0101c77 <mem_init+0xc17>
f0101c73:	85 c0                	test   %eax,%eax
f0101c75:	75 19                	jne    f0101c90 <mem_init+0xc30>
f0101c77:	68 7c 40 10 f0       	push   $0xf010407c
f0101c7c:	68 11 43 10 f0       	push   $0xf0104311
f0101c81:	68 35 03 00 00       	push   $0x335
f0101c86:	68 dc 42 10 f0       	push   $0xf01042dc
f0101c8b:	e8 fb e3 ff ff       	call   f010008b <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101c90:	83 ec 08             	sub    $0x8,%esp
f0101c93:	6a 00                	push   $0x0
f0101c95:	ff 35 48 69 11 f0    	pushl  0xf0116948
f0101c9b:	e8 19 f3 ff ff       	call   f0100fb9 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101ca0:	8b 3d 48 69 11 f0    	mov    0xf0116948,%edi
f0101ca6:	ba 00 00 00 00       	mov    $0x0,%edx
f0101cab:	89 f8                	mov    %edi,%eax
f0101cad:	e8 4b ec ff ff       	call   f01008fd <check_va2pa>
f0101cb2:	83 c4 10             	add    $0x10,%esp
f0101cb5:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101cb8:	74 19                	je     f0101cd3 <mem_init+0xc73>
f0101cba:	68 a0 40 10 f0       	push   $0xf01040a0
f0101cbf:	68 11 43 10 f0       	push   $0xf0104311
f0101cc4:	68 39 03 00 00       	push   $0x339
f0101cc9:	68 dc 42 10 f0       	push   $0xf01042dc
f0101cce:	e8 b8 e3 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101cd3:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101cd8:	89 f8                	mov    %edi,%eax
f0101cda:	e8 1e ec ff ff       	call   f01008fd <check_va2pa>
f0101cdf:	89 da                	mov    %ebx,%edx
f0101ce1:	2b 15 4c 69 11 f0    	sub    0xf011694c,%edx
f0101ce7:	c1 fa 03             	sar    $0x3,%edx
f0101cea:	c1 e2 0c             	shl    $0xc,%edx
f0101ced:	39 d0                	cmp    %edx,%eax
f0101cef:	74 19                	je     f0101d0a <mem_init+0xcaa>
f0101cf1:	68 4c 40 10 f0       	push   $0xf010404c
f0101cf6:	68 11 43 10 f0       	push   $0xf0104311
f0101cfb:	68 3a 03 00 00       	push   $0x33a
f0101d00:	68 dc 42 10 f0       	push   $0xf01042dc
f0101d05:	e8 81 e3 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 1);
f0101d0a:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101d0f:	74 19                	je     f0101d2a <mem_init+0xcca>
f0101d11:	68 b9 44 10 f0       	push   $0xf01044b9
f0101d16:	68 11 43 10 f0       	push   $0xf0104311
f0101d1b:	68 3b 03 00 00       	push   $0x33b
f0101d20:	68 dc 42 10 f0       	push   $0xf01042dc
f0101d25:	e8 61 e3 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101d2a:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101d2f:	74 19                	je     f0101d4a <mem_init+0xcea>
f0101d31:	68 13 45 10 f0       	push   $0xf0104513
f0101d36:	68 11 43 10 f0       	push   $0xf0104311
f0101d3b:	68 3c 03 00 00       	push   $0x33c
f0101d40:	68 dc 42 10 f0       	push   $0xf01042dc
f0101d45:	e8 41 e3 ff ff       	call   f010008b <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101d4a:	6a 00                	push   $0x0
f0101d4c:	68 00 10 00 00       	push   $0x1000
f0101d51:	53                   	push   %ebx
f0101d52:	57                   	push   %edi
f0101d53:	e8 9c f2 ff ff       	call   f0100ff4 <page_insert>
f0101d58:	83 c4 10             	add    $0x10,%esp
f0101d5b:	85 c0                	test   %eax,%eax
f0101d5d:	74 19                	je     f0101d78 <mem_init+0xd18>
f0101d5f:	68 c4 40 10 f0       	push   $0xf01040c4
f0101d64:	68 11 43 10 f0       	push   $0xf0104311
f0101d69:	68 3f 03 00 00       	push   $0x33f
f0101d6e:	68 dc 42 10 f0       	push   $0xf01042dc
f0101d73:	e8 13 e3 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref);
f0101d78:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101d7d:	75 19                	jne    f0101d98 <mem_init+0xd38>
f0101d7f:	68 24 45 10 f0       	push   $0xf0104524
f0101d84:	68 11 43 10 f0       	push   $0xf0104311
f0101d89:	68 40 03 00 00       	push   $0x340
f0101d8e:	68 dc 42 10 f0       	push   $0xf01042dc
f0101d93:	e8 f3 e2 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_link == NULL);
f0101d98:	83 3b 00             	cmpl   $0x0,(%ebx)
f0101d9b:	74 19                	je     f0101db6 <mem_init+0xd56>
f0101d9d:	68 30 45 10 f0       	push   $0xf0104530
f0101da2:	68 11 43 10 f0       	push   $0xf0104311
f0101da7:	68 41 03 00 00       	push   $0x341
f0101dac:	68 dc 42 10 f0       	push   $0xf01042dc
f0101db1:	e8 d5 e2 ff ff       	call   f010008b <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101db6:	83 ec 08             	sub    $0x8,%esp
f0101db9:	68 00 10 00 00       	push   $0x1000
f0101dbe:	ff 35 48 69 11 f0    	pushl  0xf0116948
f0101dc4:	e8 f0 f1 ff ff       	call   f0100fb9 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101dc9:	8b 3d 48 69 11 f0    	mov    0xf0116948,%edi
f0101dcf:	ba 00 00 00 00       	mov    $0x0,%edx
f0101dd4:	89 f8                	mov    %edi,%eax
f0101dd6:	e8 22 eb ff ff       	call   f01008fd <check_va2pa>
f0101ddb:	83 c4 10             	add    $0x10,%esp
f0101dde:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101de1:	74 19                	je     f0101dfc <mem_init+0xd9c>
f0101de3:	68 a0 40 10 f0       	push   $0xf01040a0
f0101de8:	68 11 43 10 f0       	push   $0xf0104311
f0101ded:	68 45 03 00 00       	push   $0x345
f0101df2:	68 dc 42 10 f0       	push   $0xf01042dc
f0101df7:	e8 8f e2 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101dfc:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e01:	89 f8                	mov    %edi,%eax
f0101e03:	e8 f5 ea ff ff       	call   f01008fd <check_va2pa>
f0101e08:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e0b:	74 19                	je     f0101e26 <mem_init+0xdc6>
f0101e0d:	68 fc 40 10 f0       	push   $0xf01040fc
f0101e12:	68 11 43 10 f0       	push   $0xf0104311
f0101e17:	68 46 03 00 00       	push   $0x346
f0101e1c:	68 dc 42 10 f0       	push   $0xf01042dc
f0101e21:	e8 65 e2 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 0);
f0101e26:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101e2b:	74 19                	je     f0101e46 <mem_init+0xde6>
f0101e2d:	68 45 45 10 f0       	push   $0xf0104545
f0101e32:	68 11 43 10 f0       	push   $0xf0104311
f0101e37:	68 47 03 00 00       	push   $0x347
f0101e3c:	68 dc 42 10 f0       	push   $0xf01042dc
f0101e41:	e8 45 e2 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101e46:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101e4b:	74 19                	je     f0101e66 <mem_init+0xe06>
f0101e4d:	68 13 45 10 f0       	push   $0xf0104513
f0101e52:	68 11 43 10 f0       	push   $0xf0104311
f0101e57:	68 48 03 00 00       	push   $0x348
f0101e5c:	68 dc 42 10 f0       	push   $0xf01042dc
f0101e61:	e8 25 e2 ff ff       	call   f010008b <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101e66:	83 ec 0c             	sub    $0xc,%esp
f0101e69:	6a 00                	push   $0x0
f0101e6b:	e8 1f ef ff ff       	call   f0100d8f <page_alloc>
f0101e70:	83 c4 10             	add    $0x10,%esp
f0101e73:	85 c0                	test   %eax,%eax
f0101e75:	74 04                	je     f0101e7b <mem_init+0xe1b>
f0101e77:	39 c3                	cmp    %eax,%ebx
f0101e79:	74 19                	je     f0101e94 <mem_init+0xe34>
f0101e7b:	68 24 41 10 f0       	push   $0xf0104124
f0101e80:	68 11 43 10 f0       	push   $0xf0104311
f0101e85:	68 4b 03 00 00       	push   $0x34b
f0101e8a:	68 dc 42 10 f0       	push   $0xf01042dc
f0101e8f:	e8 f7 e1 ff ff       	call   f010008b <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101e94:	83 ec 0c             	sub    $0xc,%esp
f0101e97:	6a 00                	push   $0x0
f0101e99:	e8 f1 ee ff ff       	call   f0100d8f <page_alloc>
f0101e9e:	83 c4 10             	add    $0x10,%esp
f0101ea1:	85 c0                	test   %eax,%eax
f0101ea3:	74 19                	je     f0101ebe <mem_init+0xe5e>
f0101ea5:	68 67 44 10 f0       	push   $0xf0104467
f0101eaa:	68 11 43 10 f0       	push   $0xf0104311
f0101eaf:	68 4e 03 00 00       	push   $0x34e
f0101eb4:	68 dc 42 10 f0       	push   $0xf01042dc
f0101eb9:	e8 cd e1 ff ff       	call   f010008b <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101ebe:	8b 0d 48 69 11 f0    	mov    0xf0116948,%ecx
f0101ec4:	8b 11                	mov    (%ecx),%edx
f0101ec6:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101ecc:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ecf:	2b 05 4c 69 11 f0    	sub    0xf011694c,%eax
f0101ed5:	c1 f8 03             	sar    $0x3,%eax
f0101ed8:	c1 e0 0c             	shl    $0xc,%eax
f0101edb:	39 c2                	cmp    %eax,%edx
f0101edd:	74 19                	je     f0101ef8 <mem_init+0xe98>
f0101edf:	68 c8 3d 10 f0       	push   $0xf0103dc8
f0101ee4:	68 11 43 10 f0       	push   $0xf0104311
f0101ee9:	68 51 03 00 00       	push   $0x351
f0101eee:	68 dc 42 10 f0       	push   $0xf01042dc
f0101ef3:	e8 93 e1 ff ff       	call   f010008b <_panic>
	kern_pgdir[0] = 0;
f0101ef8:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0101efe:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f01:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101f06:	74 19                	je     f0101f21 <mem_init+0xec1>
f0101f08:	68 ca 44 10 f0       	push   $0xf01044ca
f0101f0d:	68 11 43 10 f0       	push   $0xf0104311
f0101f12:	68 53 03 00 00       	push   $0x353
f0101f17:	68 dc 42 10 f0       	push   $0xf01042dc
f0101f1c:	e8 6a e1 ff ff       	call   f010008b <_panic>
	pp0->pp_ref = 0;
f0101f21:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f24:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0101f2a:	83 ec 0c             	sub    $0xc,%esp
f0101f2d:	50                   	push   %eax
f0101f2e:	e8 d3 ee ff ff       	call   f0100e06 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0101f33:	83 c4 0c             	add    $0xc,%esp
f0101f36:	6a 01                	push   $0x1
f0101f38:	68 00 10 40 00       	push   $0x401000
f0101f3d:	ff 35 48 69 11 f0    	pushl  0xf0116948
f0101f43:	e8 20 ef ff ff       	call   f0100e68 <pgdir_walk>
f0101f48:	89 c7                	mov    %eax,%edi
f0101f4a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0101f4d:	a1 48 69 11 f0       	mov    0xf0116948,%eax
f0101f52:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101f55:	8b 40 04             	mov    0x4(%eax),%eax
f0101f58:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101f5d:	8b 0d 44 69 11 f0    	mov    0xf0116944,%ecx
f0101f63:	89 c2                	mov    %eax,%edx
f0101f65:	c1 ea 0c             	shr    $0xc,%edx
f0101f68:	83 c4 10             	add    $0x10,%esp
f0101f6b:	39 ca                	cmp    %ecx,%edx
f0101f6d:	72 15                	jb     f0101f84 <mem_init+0xf24>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101f6f:	50                   	push   %eax
f0101f70:	68 54 3b 10 f0       	push   $0xf0103b54
f0101f75:	68 5a 03 00 00       	push   $0x35a
f0101f7a:	68 dc 42 10 f0       	push   $0xf01042dc
f0101f7f:	e8 07 e1 ff ff       	call   f010008b <_panic>
	assert(ptep == ptep1 + PTX(va));
f0101f84:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f0101f89:	39 c7                	cmp    %eax,%edi
f0101f8b:	74 19                	je     f0101fa6 <mem_init+0xf46>
f0101f8d:	68 56 45 10 f0       	push   $0xf0104556
f0101f92:	68 11 43 10 f0       	push   $0xf0104311
f0101f97:	68 5b 03 00 00       	push   $0x35b
f0101f9c:	68 dc 42 10 f0       	push   $0xf01042dc
f0101fa1:	e8 e5 e0 ff ff       	call   f010008b <_panic>
	kern_pgdir[PDX(va)] = 0;
f0101fa6:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101fa9:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f0101fb0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101fb3:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101fb9:	2b 05 4c 69 11 f0    	sub    0xf011694c,%eax
f0101fbf:	c1 f8 03             	sar    $0x3,%eax
f0101fc2:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101fc5:	89 c2                	mov    %eax,%edx
f0101fc7:	c1 ea 0c             	shr    $0xc,%edx
f0101fca:	39 d1                	cmp    %edx,%ecx
f0101fcc:	77 12                	ja     f0101fe0 <mem_init+0xf80>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101fce:	50                   	push   %eax
f0101fcf:	68 54 3b 10 f0       	push   $0xf0103b54
f0101fd4:	6a 52                	push   $0x52
f0101fd6:	68 f7 42 10 f0       	push   $0xf01042f7
f0101fdb:	e8 ab e0 ff ff       	call   f010008b <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0101fe0:	83 ec 04             	sub    $0x4,%esp
f0101fe3:	68 00 10 00 00       	push   $0x1000
f0101fe8:	68 ff 00 00 00       	push   $0xff
f0101fed:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101ff2:	50                   	push   %eax
f0101ff3:	e8 c7 11 00 00       	call   f01031bf <memset>
	page_free(pp0);
f0101ff8:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0101ffb:	89 3c 24             	mov    %edi,(%esp)
f0101ffe:	e8 03 ee ff ff       	call   f0100e06 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0102003:	83 c4 0c             	add    $0xc,%esp
f0102006:	6a 01                	push   $0x1
f0102008:	6a 00                	push   $0x0
f010200a:	ff 35 48 69 11 f0    	pushl  0xf0116948
f0102010:	e8 53 ee ff ff       	call   f0100e68 <pgdir_walk>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102015:	89 fa                	mov    %edi,%edx
f0102017:	2b 15 4c 69 11 f0    	sub    0xf011694c,%edx
f010201d:	c1 fa 03             	sar    $0x3,%edx
f0102020:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102023:	89 d0                	mov    %edx,%eax
f0102025:	c1 e8 0c             	shr    $0xc,%eax
f0102028:	83 c4 10             	add    $0x10,%esp
f010202b:	3b 05 44 69 11 f0    	cmp    0xf0116944,%eax
f0102031:	72 12                	jb     f0102045 <mem_init+0xfe5>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102033:	52                   	push   %edx
f0102034:	68 54 3b 10 f0       	push   $0xf0103b54
f0102039:	6a 52                	push   $0x52
f010203b:	68 f7 42 10 f0       	push   $0xf01042f7
f0102040:	e8 46 e0 ff ff       	call   f010008b <_panic>
	return (void *)(pa + KERNBASE);
f0102045:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f010204b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010204e:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102054:	f6 00 01             	testb  $0x1,(%eax)
f0102057:	74 19                	je     f0102072 <mem_init+0x1012>
f0102059:	68 6e 45 10 f0       	push   $0xf010456e
f010205e:	68 11 43 10 f0       	push   $0xf0104311
f0102063:	68 65 03 00 00       	push   $0x365
f0102068:	68 dc 42 10 f0       	push   $0xf01042dc
f010206d:	e8 19 e0 ff ff       	call   f010008b <_panic>
f0102072:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f0102075:	39 d0                	cmp    %edx,%eax
f0102077:	75 db                	jne    f0102054 <mem_init+0xff4>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f0102079:	a1 48 69 11 f0       	mov    0xf0116948,%eax
f010207e:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102084:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102087:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f010208d:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0102090:	89 0d 3c 65 11 f0    	mov    %ecx,0xf011653c

	// free the pages we took
	page_free(pp0);
f0102096:	83 ec 0c             	sub    $0xc,%esp
f0102099:	50                   	push   %eax
f010209a:	e8 67 ed ff ff       	call   f0100e06 <page_free>
	page_free(pp1);
f010209f:	89 1c 24             	mov    %ebx,(%esp)
f01020a2:	e8 5f ed ff ff       	call   f0100e06 <page_free>
	page_free(pp2);
f01020a7:	89 34 24             	mov    %esi,(%esp)
f01020aa:	e8 57 ed ff ff       	call   f0100e06 <page_free>

	cprintf("check_page() succeeded!\n");
f01020af:	c7 04 24 85 45 10 f0 	movl   $0xf0104585,(%esp)
f01020b6:	e8 4b 06 00 00       	call   f0102706 <cprintf>
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	
	boot_map_region(kern_pgdir, UPAGES, PTSIZE, PADDR(pages), PTE_U);
f01020bb:	a1 4c 69 11 f0       	mov    0xf011694c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01020c0:	83 c4 10             	add    $0x10,%esp
f01020c3:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01020c8:	77 15                	ja     f01020df <mem_init+0x107f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01020ca:	50                   	push   %eax
f01020cb:	68 78 3b 10 f0       	push   $0xf0103b78
f01020d0:	68 b6 00 00 00       	push   $0xb6
f01020d5:	68 dc 42 10 f0       	push   $0xf01042dc
f01020da:	e8 ac df ff ff       	call   f010008b <_panic>
f01020df:	83 ec 08             	sub    $0x8,%esp
f01020e2:	6a 04                	push   $0x4
f01020e4:	05 00 00 00 10       	add    $0x10000000,%eax
f01020e9:	50                   	push   %eax
f01020ea:	b9 00 00 40 00       	mov    $0x400000,%ecx
f01020ef:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f01020f4:	a1 48 69 11 f0       	mov    0xf0116948,%eax
f01020f9:	e8 ff ed ff ff       	call   f0100efd <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01020fe:	83 c4 10             	add    $0x10,%esp
f0102101:	b8 00 c0 10 f0       	mov    $0xf010c000,%eax
f0102106:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010210b:	77 15                	ja     f0102122 <mem_init+0x10c2>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010210d:	50                   	push   %eax
f010210e:	68 78 3b 10 f0       	push   $0xf0103b78
f0102113:	68 c3 00 00 00       	push   $0xc3
f0102118:	68 dc 42 10 f0       	push   $0xf01042dc
f010211d:	e8 69 df ff ff       	call   f010008b <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KSTACKTOP-KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W);
f0102122:	83 ec 08             	sub    $0x8,%esp
f0102125:	6a 02                	push   $0x2
f0102127:	68 00 c0 10 00       	push   $0x10c000
f010212c:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102131:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f0102136:	a1 48 69 11 f0       	mov    0xf0116948,%eax
f010213b:	e8 bd ed ff ff       	call   f0100efd <boot_map_region>
	//      the PA range [0, 2^32 - KERNBASE)
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KERNBASE, 0xffffffff - KERNBASE, 0, PTE_W);
f0102140:	83 c4 08             	add    $0x8,%esp
f0102143:	6a 02                	push   $0x2
f0102145:	6a 00                	push   $0x0
f0102147:	b9 ff ff ff 0f       	mov    $0xfffffff,%ecx
f010214c:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0102151:	a1 48 69 11 f0       	mov    0xf0116948,%eax
f0102156:	e8 a2 ed ff ff       	call   f0100efd <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f010215b:	8b 35 48 69 11 f0    	mov    0xf0116948,%esi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0102161:	a1 44 69 11 f0       	mov    0xf0116944,%eax
f0102166:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102169:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0102170:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102175:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102178:	8b 3d 4c 69 11 f0    	mov    0xf011694c,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010217e:	89 7d d0             	mov    %edi,-0x30(%ebp)
f0102181:	83 c4 10             	add    $0x10,%esp

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102184:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102189:	eb 55                	jmp    f01021e0 <mem_init+0x1180>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f010218b:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
f0102191:	89 f0                	mov    %esi,%eax
f0102193:	e8 65 e7 ff ff       	call   f01008fd <check_va2pa>
f0102198:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f010219f:	77 15                	ja     f01021b6 <mem_init+0x1156>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01021a1:	57                   	push   %edi
f01021a2:	68 78 3b 10 f0       	push   $0xf0103b78
f01021a7:	68 a7 02 00 00       	push   $0x2a7
f01021ac:	68 dc 42 10 f0       	push   $0xf01042dc
f01021b1:	e8 d5 de ff ff       	call   f010008b <_panic>
f01021b6:	8d 94 1f 00 00 00 10 	lea    0x10000000(%edi,%ebx,1),%edx
f01021bd:	39 c2                	cmp    %eax,%edx
f01021bf:	74 19                	je     f01021da <mem_init+0x117a>
f01021c1:	68 48 41 10 f0       	push   $0xf0104148
f01021c6:	68 11 43 10 f0       	push   $0xf0104311
f01021cb:	68 a7 02 00 00       	push   $0x2a7
f01021d0:	68 dc 42 10 f0       	push   $0xf01042dc
f01021d5:	e8 b1 de ff ff       	call   f010008b <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01021da:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01021e0:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f01021e3:	77 a6                	ja     f010218b <mem_init+0x112b>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01021e5:	8b 7d cc             	mov    -0x34(%ebp),%edi
f01021e8:	c1 e7 0c             	shl    $0xc,%edi
f01021eb:	bb 00 00 00 00       	mov    $0x0,%ebx
f01021f0:	eb 30                	jmp    f0102222 <mem_init+0x11c2>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f01021f2:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
f01021f8:	89 f0                	mov    %esi,%eax
f01021fa:	e8 fe e6 ff ff       	call   f01008fd <check_va2pa>
f01021ff:	39 c3                	cmp    %eax,%ebx
f0102201:	74 19                	je     f010221c <mem_init+0x11bc>
f0102203:	68 7c 41 10 f0       	push   $0xf010417c
f0102208:	68 11 43 10 f0       	push   $0xf0104311
f010220d:	68 ac 02 00 00       	push   $0x2ac
f0102212:	68 dc 42 10 f0       	push   $0xf01042dc
f0102217:	e8 6f de ff ff       	call   f010008b <_panic>
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f010221c:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102222:	39 fb                	cmp    %edi,%ebx
f0102224:	72 cc                	jb     f01021f2 <mem_init+0x1192>
f0102226:	bb 00 80 ff ef       	mov    $0xefff8000,%ebx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f010222b:	89 da                	mov    %ebx,%edx
f010222d:	89 f0                	mov    %esi,%eax
f010222f:	e8 c9 e6 ff ff       	call   f01008fd <check_va2pa>
f0102234:	8d 93 00 40 11 10    	lea    0x10114000(%ebx),%edx
f010223a:	39 c2                	cmp    %eax,%edx
f010223c:	74 19                	je     f0102257 <mem_init+0x11f7>
f010223e:	68 a4 41 10 f0       	push   $0xf01041a4
f0102243:	68 11 43 10 f0       	push   $0xf0104311
f0102248:	68 b0 02 00 00       	push   $0x2b0
f010224d:	68 dc 42 10 f0       	push   $0xf01042dc
f0102252:	e8 34 de ff ff       	call   f010008b <_panic>
f0102257:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f010225d:	81 fb 00 00 00 f0    	cmp    $0xf0000000,%ebx
f0102263:	75 c6                	jne    f010222b <mem_init+0x11cb>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102265:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f010226a:	89 f0                	mov    %esi,%eax
f010226c:	e8 8c e6 ff ff       	call   f01008fd <check_va2pa>
f0102271:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102274:	74 51                	je     f01022c7 <mem_init+0x1267>
f0102276:	68 ec 41 10 f0       	push   $0xf01041ec
f010227b:	68 11 43 10 f0       	push   $0xf0104311
f0102280:	68 b1 02 00 00       	push   $0x2b1
f0102285:	68 dc 42 10 f0       	push   $0xf01042dc
f010228a:	e8 fc dd ff ff       	call   f010008b <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f010228f:	3d bc 03 00 00       	cmp    $0x3bc,%eax
f0102294:	72 36                	jb     f01022cc <mem_init+0x126c>
f0102296:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f010229b:	76 07                	jbe    f01022a4 <mem_init+0x1244>
f010229d:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f01022a2:	75 28                	jne    f01022cc <mem_init+0x126c>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
f01022a4:	f6 04 86 01          	testb  $0x1,(%esi,%eax,4)
f01022a8:	0f 85 83 00 00 00    	jne    f0102331 <mem_init+0x12d1>
f01022ae:	68 9e 45 10 f0       	push   $0xf010459e
f01022b3:	68 11 43 10 f0       	push   $0xf0104311
f01022b8:	68 b9 02 00 00       	push   $0x2b9
f01022bd:	68 dc 42 10 f0       	push   $0xf01042dc
f01022c2:	e8 c4 dd ff ff       	call   f010008b <_panic>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f01022c7:	b8 00 00 00 00       	mov    $0x0,%eax
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f01022cc:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f01022d1:	76 3f                	jbe    f0102312 <mem_init+0x12b2>
				assert(pgdir[i] & PTE_P);
f01022d3:	8b 14 86             	mov    (%esi,%eax,4),%edx
f01022d6:	f6 c2 01             	test   $0x1,%dl
f01022d9:	75 19                	jne    f01022f4 <mem_init+0x1294>
f01022db:	68 9e 45 10 f0       	push   $0xf010459e
f01022e0:	68 11 43 10 f0       	push   $0xf0104311
f01022e5:	68 bd 02 00 00       	push   $0x2bd
f01022ea:	68 dc 42 10 f0       	push   $0xf01042dc
f01022ef:	e8 97 dd ff ff       	call   f010008b <_panic>
				assert(pgdir[i] & PTE_W);
f01022f4:	f6 c2 02             	test   $0x2,%dl
f01022f7:	75 38                	jne    f0102331 <mem_init+0x12d1>
f01022f9:	68 af 45 10 f0       	push   $0xf01045af
f01022fe:	68 11 43 10 f0       	push   $0xf0104311
f0102303:	68 be 02 00 00       	push   $0x2be
f0102308:	68 dc 42 10 f0       	push   $0xf01042dc
f010230d:	e8 79 dd ff ff       	call   f010008b <_panic>
			} else
				assert(pgdir[i] == 0);
f0102312:	83 3c 86 00          	cmpl   $0x0,(%esi,%eax,4)
f0102316:	74 19                	je     f0102331 <mem_init+0x12d1>
f0102318:	68 c0 45 10 f0       	push   $0xf01045c0
f010231d:	68 11 43 10 f0       	push   $0xf0104311
f0102322:	68 c0 02 00 00       	push   $0x2c0
f0102327:	68 dc 42 10 f0       	push   $0xf01042dc
f010232c:	e8 5a dd ff ff       	call   f010008b <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0102331:	83 c0 01             	add    $0x1,%eax
f0102334:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f0102339:	0f 86 50 ff ff ff    	jbe    f010228f <mem_init+0x122f>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f010233f:	83 ec 0c             	sub    $0xc,%esp
f0102342:	68 1c 42 10 f0       	push   $0xf010421c
f0102347:	e8 ba 03 00 00       	call   f0102706 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f010234c:	a1 48 69 11 f0       	mov    0xf0116948,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102351:	83 c4 10             	add    $0x10,%esp
f0102354:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102359:	77 15                	ja     f0102370 <mem_init+0x1310>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010235b:	50                   	push   %eax
f010235c:	68 78 3b 10 f0       	push   $0xf0103b78
f0102361:	68 d9 00 00 00       	push   $0xd9
f0102366:	68 dc 42 10 f0       	push   $0xf01042dc
f010236b:	e8 1b dd ff ff       	call   f010008b <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0102370:	05 00 00 00 10       	add    $0x10000000,%eax
f0102375:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f0102378:	b8 00 00 00 00       	mov    $0x0,%eax
f010237d:	e8 66 e6 ff ff       	call   f01009e8 <check_page_free_list>

static inline uint32_t
rcr0(void)
{
	uint32_t val;
	asm volatile("movl %%cr0,%0" : "=r" (val));
f0102382:	0f 20 c0             	mov    %cr0,%eax
f0102385:	83 e0 f3             	and    $0xfffffff3,%eax
}

static inline void
lcr0(uint32_t val)
{
	asm volatile("movl %0,%%cr0" : : "r" (val));
f0102388:	0d 23 00 05 80       	or     $0x80050023,%eax
f010238d:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102390:	83 ec 0c             	sub    $0xc,%esp
f0102393:	6a 00                	push   $0x0
f0102395:	e8 f5 e9 ff ff       	call   f0100d8f <page_alloc>
f010239a:	89 c3                	mov    %eax,%ebx
f010239c:	83 c4 10             	add    $0x10,%esp
f010239f:	85 c0                	test   %eax,%eax
f01023a1:	75 19                	jne    f01023bc <mem_init+0x135c>
f01023a3:	68 bc 43 10 f0       	push   $0xf01043bc
f01023a8:	68 11 43 10 f0       	push   $0xf0104311
f01023ad:	68 80 03 00 00       	push   $0x380
f01023b2:	68 dc 42 10 f0       	push   $0xf01042dc
f01023b7:	e8 cf dc ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f01023bc:	83 ec 0c             	sub    $0xc,%esp
f01023bf:	6a 00                	push   $0x0
f01023c1:	e8 c9 e9 ff ff       	call   f0100d8f <page_alloc>
f01023c6:	89 c7                	mov    %eax,%edi
f01023c8:	83 c4 10             	add    $0x10,%esp
f01023cb:	85 c0                	test   %eax,%eax
f01023cd:	75 19                	jne    f01023e8 <mem_init+0x1388>
f01023cf:	68 d2 43 10 f0       	push   $0xf01043d2
f01023d4:	68 11 43 10 f0       	push   $0xf0104311
f01023d9:	68 81 03 00 00       	push   $0x381
f01023de:	68 dc 42 10 f0       	push   $0xf01042dc
f01023e3:	e8 a3 dc ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f01023e8:	83 ec 0c             	sub    $0xc,%esp
f01023eb:	6a 00                	push   $0x0
f01023ed:	e8 9d e9 ff ff       	call   f0100d8f <page_alloc>
f01023f2:	89 c6                	mov    %eax,%esi
f01023f4:	83 c4 10             	add    $0x10,%esp
f01023f7:	85 c0                	test   %eax,%eax
f01023f9:	75 19                	jne    f0102414 <mem_init+0x13b4>
f01023fb:	68 e8 43 10 f0       	push   $0xf01043e8
f0102400:	68 11 43 10 f0       	push   $0xf0104311
f0102405:	68 82 03 00 00       	push   $0x382
f010240a:	68 dc 42 10 f0       	push   $0xf01042dc
f010240f:	e8 77 dc ff ff       	call   f010008b <_panic>
	page_free(pp0);
f0102414:	83 ec 0c             	sub    $0xc,%esp
f0102417:	53                   	push   %ebx
f0102418:	e8 e9 e9 ff ff       	call   f0100e06 <page_free>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010241d:	89 f8                	mov    %edi,%eax
f010241f:	2b 05 4c 69 11 f0    	sub    0xf011694c,%eax
f0102425:	c1 f8 03             	sar    $0x3,%eax
f0102428:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010242b:	89 c2                	mov    %eax,%edx
f010242d:	c1 ea 0c             	shr    $0xc,%edx
f0102430:	83 c4 10             	add    $0x10,%esp
f0102433:	3b 15 44 69 11 f0    	cmp    0xf0116944,%edx
f0102439:	72 12                	jb     f010244d <mem_init+0x13ed>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010243b:	50                   	push   %eax
f010243c:	68 54 3b 10 f0       	push   $0xf0103b54
f0102441:	6a 52                	push   $0x52
f0102443:	68 f7 42 10 f0       	push   $0xf01042f7
f0102448:	e8 3e dc ff ff       	call   f010008b <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f010244d:	83 ec 04             	sub    $0x4,%esp
f0102450:	68 00 10 00 00       	push   $0x1000
f0102455:	6a 01                	push   $0x1
f0102457:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010245c:	50                   	push   %eax
f010245d:	e8 5d 0d 00 00       	call   f01031bf <memset>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102462:	89 f0                	mov    %esi,%eax
f0102464:	2b 05 4c 69 11 f0    	sub    0xf011694c,%eax
f010246a:	c1 f8 03             	sar    $0x3,%eax
f010246d:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102470:	89 c2                	mov    %eax,%edx
f0102472:	c1 ea 0c             	shr    $0xc,%edx
f0102475:	83 c4 10             	add    $0x10,%esp
f0102478:	3b 15 44 69 11 f0    	cmp    0xf0116944,%edx
f010247e:	72 12                	jb     f0102492 <mem_init+0x1432>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102480:	50                   	push   %eax
f0102481:	68 54 3b 10 f0       	push   $0xf0103b54
f0102486:	6a 52                	push   $0x52
f0102488:	68 f7 42 10 f0       	push   $0xf01042f7
f010248d:	e8 f9 db ff ff       	call   f010008b <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f0102492:	83 ec 04             	sub    $0x4,%esp
f0102495:	68 00 10 00 00       	push   $0x1000
f010249a:	6a 02                	push   $0x2
f010249c:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01024a1:	50                   	push   %eax
f01024a2:	e8 18 0d 00 00       	call   f01031bf <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f01024a7:	6a 02                	push   $0x2
f01024a9:	68 00 10 00 00       	push   $0x1000
f01024ae:	57                   	push   %edi
f01024af:	ff 35 48 69 11 f0    	pushl  0xf0116948
f01024b5:	e8 3a eb ff ff       	call   f0100ff4 <page_insert>
	assert(pp1->pp_ref == 1);
f01024ba:	83 c4 20             	add    $0x20,%esp
f01024bd:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f01024c2:	74 19                	je     f01024dd <mem_init+0x147d>
f01024c4:	68 b9 44 10 f0       	push   $0xf01044b9
f01024c9:	68 11 43 10 f0       	push   $0xf0104311
f01024ce:	68 87 03 00 00       	push   $0x387
f01024d3:	68 dc 42 10 f0       	push   $0xf01042dc
f01024d8:	e8 ae db ff ff       	call   f010008b <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f01024dd:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f01024e4:	01 01 01 
f01024e7:	74 19                	je     f0102502 <mem_init+0x14a2>
f01024e9:	68 3c 42 10 f0       	push   $0xf010423c
f01024ee:	68 11 43 10 f0       	push   $0xf0104311
f01024f3:	68 88 03 00 00       	push   $0x388
f01024f8:	68 dc 42 10 f0       	push   $0xf01042dc
f01024fd:	e8 89 db ff ff       	call   f010008b <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102502:	6a 02                	push   $0x2
f0102504:	68 00 10 00 00       	push   $0x1000
f0102509:	56                   	push   %esi
f010250a:	ff 35 48 69 11 f0    	pushl  0xf0116948
f0102510:	e8 df ea ff ff       	call   f0100ff4 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102515:	83 c4 10             	add    $0x10,%esp
f0102518:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f010251f:	02 02 02 
f0102522:	74 19                	je     f010253d <mem_init+0x14dd>
f0102524:	68 60 42 10 f0       	push   $0xf0104260
f0102529:	68 11 43 10 f0       	push   $0xf0104311
f010252e:	68 8a 03 00 00       	push   $0x38a
f0102533:	68 dc 42 10 f0       	push   $0xf01042dc
f0102538:	e8 4e db ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f010253d:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102542:	74 19                	je     f010255d <mem_init+0x14fd>
f0102544:	68 db 44 10 f0       	push   $0xf01044db
f0102549:	68 11 43 10 f0       	push   $0xf0104311
f010254e:	68 8b 03 00 00       	push   $0x38b
f0102553:	68 dc 42 10 f0       	push   $0xf01042dc
f0102558:	e8 2e db ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 0);
f010255d:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102562:	74 19                	je     f010257d <mem_init+0x151d>
f0102564:	68 45 45 10 f0       	push   $0xf0104545
f0102569:	68 11 43 10 f0       	push   $0xf0104311
f010256e:	68 8c 03 00 00       	push   $0x38c
f0102573:	68 dc 42 10 f0       	push   $0xf01042dc
f0102578:	e8 0e db ff ff       	call   f010008b <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f010257d:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102584:	03 03 03 
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102587:	89 f0                	mov    %esi,%eax
f0102589:	2b 05 4c 69 11 f0    	sub    0xf011694c,%eax
f010258f:	c1 f8 03             	sar    $0x3,%eax
f0102592:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102595:	89 c2                	mov    %eax,%edx
f0102597:	c1 ea 0c             	shr    $0xc,%edx
f010259a:	3b 15 44 69 11 f0    	cmp    0xf0116944,%edx
f01025a0:	72 12                	jb     f01025b4 <mem_init+0x1554>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01025a2:	50                   	push   %eax
f01025a3:	68 54 3b 10 f0       	push   $0xf0103b54
f01025a8:	6a 52                	push   $0x52
f01025aa:	68 f7 42 10 f0       	push   $0xf01042f7
f01025af:	e8 d7 da ff ff       	call   f010008b <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f01025b4:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f01025bb:	03 03 03 
f01025be:	74 19                	je     f01025d9 <mem_init+0x1579>
f01025c0:	68 84 42 10 f0       	push   $0xf0104284
f01025c5:	68 11 43 10 f0       	push   $0xf0104311
f01025ca:	68 8e 03 00 00       	push   $0x38e
f01025cf:	68 dc 42 10 f0       	push   $0xf01042dc
f01025d4:	e8 b2 da ff ff       	call   f010008b <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f01025d9:	83 ec 08             	sub    $0x8,%esp
f01025dc:	68 00 10 00 00       	push   $0x1000
f01025e1:	ff 35 48 69 11 f0    	pushl  0xf0116948
f01025e7:	e8 cd e9 ff ff       	call   f0100fb9 <page_remove>
	assert(pp2->pp_ref == 0);
f01025ec:	83 c4 10             	add    $0x10,%esp
f01025ef:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01025f4:	74 19                	je     f010260f <mem_init+0x15af>
f01025f6:	68 13 45 10 f0       	push   $0xf0104513
f01025fb:	68 11 43 10 f0       	push   $0xf0104311
f0102600:	68 90 03 00 00       	push   $0x390
f0102605:	68 dc 42 10 f0       	push   $0xf01042dc
f010260a:	e8 7c da ff ff       	call   f010008b <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010260f:	8b 0d 48 69 11 f0    	mov    0xf0116948,%ecx
f0102615:	8b 11                	mov    (%ecx),%edx
f0102617:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010261d:	89 d8                	mov    %ebx,%eax
f010261f:	2b 05 4c 69 11 f0    	sub    0xf011694c,%eax
f0102625:	c1 f8 03             	sar    $0x3,%eax
f0102628:	c1 e0 0c             	shl    $0xc,%eax
f010262b:	39 c2                	cmp    %eax,%edx
f010262d:	74 19                	je     f0102648 <mem_init+0x15e8>
f010262f:	68 c8 3d 10 f0       	push   $0xf0103dc8
f0102634:	68 11 43 10 f0       	push   $0xf0104311
f0102639:	68 93 03 00 00       	push   $0x393
f010263e:	68 dc 42 10 f0       	push   $0xf01042dc
f0102643:	e8 43 da ff ff       	call   f010008b <_panic>
	kern_pgdir[0] = 0;
f0102648:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f010264e:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102653:	74 19                	je     f010266e <mem_init+0x160e>
f0102655:	68 ca 44 10 f0       	push   $0xf01044ca
f010265a:	68 11 43 10 f0       	push   $0xf0104311
f010265f:	68 95 03 00 00       	push   $0x395
f0102664:	68 dc 42 10 f0       	push   $0xf01042dc
f0102669:	e8 1d da ff ff       	call   f010008b <_panic>
	pp0->pp_ref = 0;
f010266e:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f0102674:	83 ec 0c             	sub    $0xc,%esp
f0102677:	53                   	push   %ebx
f0102678:	e8 89 e7 ff ff       	call   f0100e06 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f010267d:	c7 04 24 b0 42 10 f0 	movl   $0xf01042b0,(%esp)
f0102684:	e8 7d 00 00 00       	call   f0102706 <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f0102689:	83 c4 10             	add    $0x10,%esp
f010268c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010268f:	5b                   	pop    %ebx
f0102690:	5e                   	pop    %esi
f0102691:	5f                   	pop    %edi
f0102692:	5d                   	pop    %ebp
f0102693:	c3                   	ret    

f0102694 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0102694:	55                   	push   %ebp
f0102695:	89 e5                	mov    %esp,%ebp
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0102697:	8b 45 0c             	mov    0xc(%ebp),%eax
f010269a:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f010269d:	5d                   	pop    %ebp
f010269e:	c3                   	ret    

f010269f <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f010269f:	55                   	push   %ebp
f01026a0:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01026a2:	ba 70 00 00 00       	mov    $0x70,%edx
f01026a7:	8b 45 08             	mov    0x8(%ebp),%eax
f01026aa:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01026ab:	ba 71 00 00 00       	mov    $0x71,%edx
f01026b0:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f01026b1:	0f b6 c0             	movzbl %al,%eax
}
f01026b4:	5d                   	pop    %ebp
f01026b5:	c3                   	ret    

f01026b6 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f01026b6:	55                   	push   %ebp
f01026b7:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01026b9:	ba 70 00 00 00       	mov    $0x70,%edx
f01026be:	8b 45 08             	mov    0x8(%ebp),%eax
f01026c1:	ee                   	out    %al,(%dx)
f01026c2:	ba 71 00 00 00       	mov    $0x71,%edx
f01026c7:	8b 45 0c             	mov    0xc(%ebp),%eax
f01026ca:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f01026cb:	5d                   	pop    %ebp
f01026cc:	c3                   	ret    

f01026cd <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01026cd:	55                   	push   %ebp
f01026ce:	89 e5                	mov    %esp,%ebp
f01026d0:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f01026d3:	ff 75 08             	pushl  0x8(%ebp)
f01026d6:	e8 25 df ff ff       	call   f0100600 <cputchar>
	*cnt++;
}
f01026db:	83 c4 10             	add    $0x10,%esp
f01026de:	c9                   	leave  
f01026df:	c3                   	ret    

f01026e0 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01026e0:	55                   	push   %ebp
f01026e1:	89 e5                	mov    %esp,%ebp
f01026e3:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f01026e6:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01026ed:	ff 75 0c             	pushl  0xc(%ebp)
f01026f0:	ff 75 08             	pushl  0x8(%ebp)
f01026f3:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01026f6:	50                   	push   %eax
f01026f7:	68 cd 26 10 f0       	push   $0xf01026cd
f01026fc:	e8 52 04 00 00       	call   f0102b53 <vprintfmt>
	return cnt;
}
f0102701:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102704:	c9                   	leave  
f0102705:	c3                   	ret    

f0102706 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0102706:	55                   	push   %ebp
f0102707:	89 e5                	mov    %esp,%ebp
f0102709:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f010270c:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f010270f:	50                   	push   %eax
f0102710:	ff 75 08             	pushl  0x8(%ebp)
f0102713:	e8 c8 ff ff ff       	call   f01026e0 <vcprintf>
	va_end(ap);

	return cnt;
}
f0102718:	c9                   	leave  
f0102719:	c3                   	ret    

f010271a <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f010271a:	55                   	push   %ebp
f010271b:	89 e5                	mov    %esp,%ebp
f010271d:	57                   	push   %edi
f010271e:	56                   	push   %esi
f010271f:	53                   	push   %ebx
f0102720:	83 ec 14             	sub    $0x14,%esp
f0102723:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0102726:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0102729:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f010272c:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f010272f:	8b 1a                	mov    (%edx),%ebx
f0102731:	8b 01                	mov    (%ecx),%eax
f0102733:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0102736:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f010273d:	eb 7f                	jmp    f01027be <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f010273f:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102742:	01 d8                	add    %ebx,%eax
f0102744:	89 c6                	mov    %eax,%esi
f0102746:	c1 ee 1f             	shr    $0x1f,%esi
f0102749:	01 c6                	add    %eax,%esi
f010274b:	d1 fe                	sar    %esi
f010274d:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0102750:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0102753:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f0102756:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102758:	eb 03                	jmp    f010275d <stab_binsearch+0x43>
			m--;
f010275a:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f010275d:	39 c3                	cmp    %eax,%ebx
f010275f:	7f 0d                	jg     f010276e <stab_binsearch+0x54>
f0102761:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0102765:	83 ea 0c             	sub    $0xc,%edx
f0102768:	39 f9                	cmp    %edi,%ecx
f010276a:	75 ee                	jne    f010275a <stab_binsearch+0x40>
f010276c:	eb 05                	jmp    f0102773 <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f010276e:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f0102771:	eb 4b                	jmp    f01027be <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0102773:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0102776:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0102779:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f010277d:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0102780:	76 11                	jbe    f0102793 <stab_binsearch+0x79>
			*region_left = m;
f0102782:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0102785:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0102787:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010278a:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0102791:	eb 2b                	jmp    f01027be <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0102793:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0102796:	73 14                	jae    f01027ac <stab_binsearch+0x92>
			*region_right = m - 1;
f0102798:	83 e8 01             	sub    $0x1,%eax
f010279b:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010279e:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01027a1:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01027a3:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01027aa:	eb 12                	jmp    f01027be <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01027ac:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01027af:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f01027b1:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f01027b5:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01027b7:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f01027be:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f01027c1:	0f 8e 78 ff ff ff    	jle    f010273f <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f01027c7:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f01027cb:	75 0f                	jne    f01027dc <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f01027cd:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01027d0:	8b 00                	mov    (%eax),%eax
f01027d2:	83 e8 01             	sub    $0x1,%eax
f01027d5:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01027d8:	89 06                	mov    %eax,(%esi)
f01027da:	eb 2c                	jmp    f0102808 <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01027dc:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01027df:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f01027e1:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01027e4:	8b 0e                	mov    (%esi),%ecx
f01027e6:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01027e9:	8b 75 ec             	mov    -0x14(%ebp),%esi
f01027ec:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01027ef:	eb 03                	jmp    f01027f4 <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f01027f1:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01027f4:	39 c8                	cmp    %ecx,%eax
f01027f6:	7e 0b                	jle    f0102803 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f01027f8:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f01027fc:	83 ea 0c             	sub    $0xc,%edx
f01027ff:	39 df                	cmp    %ebx,%edi
f0102801:	75 ee                	jne    f01027f1 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f0102803:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0102806:	89 06                	mov    %eax,(%esi)
	}
}
f0102808:	83 c4 14             	add    $0x14,%esp
f010280b:	5b                   	pop    %ebx
f010280c:	5e                   	pop    %esi
f010280d:	5f                   	pop    %edi
f010280e:	5d                   	pop    %ebp
f010280f:	c3                   	ret    

f0102810 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0102810:	55                   	push   %ebp
f0102811:	89 e5                	mov    %esp,%ebp
f0102813:	57                   	push   %edi
f0102814:	56                   	push   %esi
f0102815:	53                   	push   %ebx
f0102816:	83 ec 3c             	sub    $0x3c,%esp
f0102819:	8b 75 08             	mov    0x8(%ebp),%esi
f010281c:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f010281f:	c7 03 ce 45 10 f0    	movl   $0xf01045ce,(%ebx)
	info->eip_line = 0;
f0102825:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f010282c:	c7 43 08 ce 45 10 f0 	movl   $0xf01045ce,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0102833:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f010283a:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f010283d:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0102844:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f010284a:	76 11                	jbe    f010285d <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f010284c:	b8 70 bf 10 f0       	mov    $0xf010bf70,%eax
f0102851:	3d b1 a1 10 f0       	cmp    $0xf010a1b1,%eax
f0102856:	77 19                	ja     f0102871 <debuginfo_eip+0x61>
f0102858:	e9 aa 01 00 00       	jmp    f0102a07 <debuginfo_eip+0x1f7>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f010285d:	83 ec 04             	sub    $0x4,%esp
f0102860:	68 d8 45 10 f0       	push   $0xf01045d8
f0102865:	6a 7f                	push   $0x7f
f0102867:	68 e5 45 10 f0       	push   $0xf01045e5
f010286c:	e8 1a d8 ff ff       	call   f010008b <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102871:	80 3d 6f bf 10 f0 00 	cmpb   $0x0,0xf010bf6f
f0102878:	0f 85 90 01 00 00    	jne    f0102a0e <debuginfo_eip+0x1fe>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f010287e:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0102885:	b8 b0 a1 10 f0       	mov    $0xf010a1b0,%eax
f010288a:	2d 04 48 10 f0       	sub    $0xf0104804,%eax
f010288f:	c1 f8 02             	sar    $0x2,%eax
f0102892:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0102898:	83 e8 01             	sub    $0x1,%eax
f010289b:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f010289e:	83 ec 08             	sub    $0x8,%esp
f01028a1:	56                   	push   %esi
f01028a2:	6a 64                	push   $0x64
f01028a4:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f01028a7:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01028aa:	b8 04 48 10 f0       	mov    $0xf0104804,%eax
f01028af:	e8 66 fe ff ff       	call   f010271a <stab_binsearch>
	if (lfile == 0)
f01028b4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01028b7:	83 c4 10             	add    $0x10,%esp
f01028ba:	85 c0                	test   %eax,%eax
f01028bc:	0f 84 53 01 00 00    	je     f0102a15 <debuginfo_eip+0x205>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f01028c2:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f01028c5:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01028c8:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f01028cb:	83 ec 08             	sub    $0x8,%esp
f01028ce:	56                   	push   %esi
f01028cf:	6a 24                	push   $0x24
f01028d1:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f01028d4:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01028d7:	b8 04 48 10 f0       	mov    $0xf0104804,%eax
f01028dc:	e8 39 fe ff ff       	call   f010271a <stab_binsearch>

	if (lfun <= rfun) {
f01028e1:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01028e4:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01028e7:	83 c4 10             	add    $0x10,%esp
f01028ea:	39 d0                	cmp    %edx,%eax
f01028ec:	7f 40                	jg     f010292e <debuginfo_eip+0x11e>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f01028ee:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f01028f1:	c1 e1 02             	shl    $0x2,%ecx
f01028f4:	8d b9 04 48 10 f0    	lea    -0xfefb7fc(%ecx),%edi
f01028fa:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f01028fd:	8b b9 04 48 10 f0    	mov    -0xfefb7fc(%ecx),%edi
f0102903:	b9 70 bf 10 f0       	mov    $0xf010bf70,%ecx
f0102908:	81 e9 b1 a1 10 f0    	sub    $0xf010a1b1,%ecx
f010290e:	39 cf                	cmp    %ecx,%edi
f0102910:	73 09                	jae    f010291b <debuginfo_eip+0x10b>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0102912:	81 c7 b1 a1 10 f0    	add    $0xf010a1b1,%edi
f0102918:	89 7b 08             	mov    %edi,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f010291b:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f010291e:	8b 4f 08             	mov    0x8(%edi),%ecx
f0102921:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0102924:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0102926:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0102929:	89 55 d0             	mov    %edx,-0x30(%ebp)
f010292c:	eb 0f                	jmp    f010293d <debuginfo_eip+0x12d>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f010292e:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0102931:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102934:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0102937:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010293a:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f010293d:	83 ec 08             	sub    $0x8,%esp
f0102940:	6a 3a                	push   $0x3a
f0102942:	ff 73 08             	pushl  0x8(%ebx)
f0102945:	e8 59 08 00 00       	call   f01031a3 <strfind>
f010294a:	2b 43 08             	sub    0x8(%ebx),%eax
f010294d:	89 43 0c             	mov    %eax,0xc(%ebx)
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.

	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);	
f0102950:	83 c4 08             	add    $0x8,%esp
f0102953:	56                   	push   %esi
f0102954:	6a 44                	push   $0x44
f0102956:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0102959:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f010295c:	b8 04 48 10 f0       	mov    $0xf0104804,%eax
f0102961:	e8 b4 fd ff ff       	call   f010271a <stab_binsearch>
	if (lline > rline)
f0102966:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0102969:	83 c4 10             	add    $0x10,%esp
f010296c:	3b 55 d0             	cmp    -0x30(%ebp),%edx
f010296f:	0f 8f a7 00 00 00    	jg     f0102a1c <debuginfo_eip+0x20c>
		    return -1;
	info->eip_line = stabs[lline].n_desc;
f0102975:	8d 04 52             	lea    (%edx,%edx,2),%eax
f0102978:	8d 04 85 04 48 10 f0 	lea    -0xfefb7fc(,%eax,4),%eax
f010297f:	0f b7 48 06          	movzwl 0x6(%eax),%ecx
f0102983:	89 4b 04             	mov    %ecx,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0102986:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0102989:	eb 06                	jmp    f0102991 <debuginfo_eip+0x181>
f010298b:	83 ea 01             	sub    $0x1,%edx
f010298e:	83 e8 0c             	sub    $0xc,%eax
f0102991:	39 d6                	cmp    %edx,%esi
f0102993:	7f 34                	jg     f01029c9 <debuginfo_eip+0x1b9>
	       && stabs[lline].n_type != N_SOL
f0102995:	0f b6 48 04          	movzbl 0x4(%eax),%ecx
f0102999:	80 f9 84             	cmp    $0x84,%cl
f010299c:	74 0b                	je     f01029a9 <debuginfo_eip+0x199>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f010299e:	80 f9 64             	cmp    $0x64,%cl
f01029a1:	75 e8                	jne    f010298b <debuginfo_eip+0x17b>
f01029a3:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f01029a7:	74 e2                	je     f010298b <debuginfo_eip+0x17b>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f01029a9:	8d 04 52             	lea    (%edx,%edx,2),%eax
f01029ac:	8b 14 85 04 48 10 f0 	mov    -0xfefb7fc(,%eax,4),%edx
f01029b3:	b8 70 bf 10 f0       	mov    $0xf010bf70,%eax
f01029b8:	2d b1 a1 10 f0       	sub    $0xf010a1b1,%eax
f01029bd:	39 c2                	cmp    %eax,%edx
f01029bf:	73 08                	jae    f01029c9 <debuginfo_eip+0x1b9>
		info->eip_file = stabstr + stabs[lline].n_strx;
f01029c1:	81 c2 b1 a1 10 f0    	add    $0xf010a1b1,%edx
f01029c7:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01029c9:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01029cc:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01029cf:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01029d4:	39 f2                	cmp    %esi,%edx
f01029d6:	7d 50                	jge    f0102a28 <debuginfo_eip+0x218>
		for (lline = lfun + 1;
f01029d8:	83 c2 01             	add    $0x1,%edx
f01029db:	89 d0                	mov    %edx,%eax
f01029dd:	8d 14 52             	lea    (%edx,%edx,2),%edx
f01029e0:	8d 14 95 04 48 10 f0 	lea    -0xfefb7fc(,%edx,4),%edx
f01029e7:	eb 04                	jmp    f01029ed <debuginfo_eip+0x1dd>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f01029e9:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f01029ed:	39 c6                	cmp    %eax,%esi
f01029ef:	7e 32                	jle    f0102a23 <debuginfo_eip+0x213>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f01029f1:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01029f5:	83 c0 01             	add    $0x1,%eax
f01029f8:	83 c2 0c             	add    $0xc,%edx
f01029fb:	80 f9 a0             	cmp    $0xa0,%cl
f01029fe:	74 e9                	je     f01029e9 <debuginfo_eip+0x1d9>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102a00:	b8 00 00 00 00       	mov    $0x0,%eax
f0102a05:	eb 21                	jmp    f0102a28 <debuginfo_eip+0x218>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0102a07:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102a0c:	eb 1a                	jmp    f0102a28 <debuginfo_eip+0x218>
f0102a0e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102a13:	eb 13                	jmp    f0102a28 <debuginfo_eip+0x218>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0102a15:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102a1a:	eb 0c                	jmp    f0102a28 <debuginfo_eip+0x218>
	//	which one.
	// Your code here.

	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);	
	if (lline > rline)
		    return -1;
f0102a1c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102a21:	eb 05                	jmp    f0102a28 <debuginfo_eip+0x218>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102a23:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102a28:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102a2b:	5b                   	pop    %ebx
f0102a2c:	5e                   	pop    %esi
f0102a2d:	5f                   	pop    %edi
f0102a2e:	5d                   	pop    %ebp
f0102a2f:	c3                   	ret    

f0102a30 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0102a30:	55                   	push   %ebp
f0102a31:	89 e5                	mov    %esp,%ebp
f0102a33:	57                   	push   %edi
f0102a34:	56                   	push   %esi
f0102a35:	53                   	push   %ebx
f0102a36:	83 ec 1c             	sub    $0x1c,%esp
f0102a39:	89 c7                	mov    %eax,%edi
f0102a3b:	89 d6                	mov    %edx,%esi
f0102a3d:	8b 45 08             	mov    0x8(%ebp),%eax
f0102a40:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102a43:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102a46:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0102a49:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0102a4c:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102a51:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0102a54:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0102a57:	39 d3                	cmp    %edx,%ebx
f0102a59:	72 05                	jb     f0102a60 <printnum+0x30>
f0102a5b:	39 45 10             	cmp    %eax,0x10(%ebp)
f0102a5e:	77 45                	ja     f0102aa5 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0102a60:	83 ec 0c             	sub    $0xc,%esp
f0102a63:	ff 75 18             	pushl  0x18(%ebp)
f0102a66:	8b 45 14             	mov    0x14(%ebp),%eax
f0102a69:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0102a6c:	53                   	push   %ebx
f0102a6d:	ff 75 10             	pushl  0x10(%ebp)
f0102a70:	83 ec 08             	sub    $0x8,%esp
f0102a73:	ff 75 e4             	pushl  -0x1c(%ebp)
f0102a76:	ff 75 e0             	pushl  -0x20(%ebp)
f0102a79:	ff 75 dc             	pushl  -0x24(%ebp)
f0102a7c:	ff 75 d8             	pushl  -0x28(%ebp)
f0102a7f:	e8 4c 09 00 00       	call   f01033d0 <__udivdi3>
f0102a84:	83 c4 18             	add    $0x18,%esp
f0102a87:	52                   	push   %edx
f0102a88:	50                   	push   %eax
f0102a89:	89 f2                	mov    %esi,%edx
f0102a8b:	89 f8                	mov    %edi,%eax
f0102a8d:	e8 9e ff ff ff       	call   f0102a30 <printnum>
f0102a92:	83 c4 20             	add    $0x20,%esp
f0102a95:	eb 18                	jmp    f0102aaf <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0102a97:	83 ec 08             	sub    $0x8,%esp
f0102a9a:	56                   	push   %esi
f0102a9b:	ff 75 18             	pushl  0x18(%ebp)
f0102a9e:	ff d7                	call   *%edi
f0102aa0:	83 c4 10             	add    $0x10,%esp
f0102aa3:	eb 03                	jmp    f0102aa8 <printnum+0x78>
f0102aa5:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0102aa8:	83 eb 01             	sub    $0x1,%ebx
f0102aab:	85 db                	test   %ebx,%ebx
f0102aad:	7f e8                	jg     f0102a97 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0102aaf:	83 ec 08             	sub    $0x8,%esp
f0102ab2:	56                   	push   %esi
f0102ab3:	83 ec 04             	sub    $0x4,%esp
f0102ab6:	ff 75 e4             	pushl  -0x1c(%ebp)
f0102ab9:	ff 75 e0             	pushl  -0x20(%ebp)
f0102abc:	ff 75 dc             	pushl  -0x24(%ebp)
f0102abf:	ff 75 d8             	pushl  -0x28(%ebp)
f0102ac2:	e8 39 0a 00 00       	call   f0103500 <__umoddi3>
f0102ac7:	83 c4 14             	add    $0x14,%esp
f0102aca:	0f be 80 f3 45 10 f0 	movsbl -0xfefba0d(%eax),%eax
f0102ad1:	50                   	push   %eax
f0102ad2:	ff d7                	call   *%edi
}
f0102ad4:	83 c4 10             	add    $0x10,%esp
f0102ad7:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102ada:	5b                   	pop    %ebx
f0102adb:	5e                   	pop    %esi
f0102adc:	5f                   	pop    %edi
f0102add:	5d                   	pop    %ebp
f0102ade:	c3                   	ret    

f0102adf <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0102adf:	55                   	push   %ebp
f0102ae0:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0102ae2:	83 fa 01             	cmp    $0x1,%edx
f0102ae5:	7e 0e                	jle    f0102af5 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0102ae7:	8b 10                	mov    (%eax),%edx
f0102ae9:	8d 4a 08             	lea    0x8(%edx),%ecx
f0102aec:	89 08                	mov    %ecx,(%eax)
f0102aee:	8b 02                	mov    (%edx),%eax
f0102af0:	8b 52 04             	mov    0x4(%edx),%edx
f0102af3:	eb 22                	jmp    f0102b17 <getuint+0x38>
	else if (lflag)
f0102af5:	85 d2                	test   %edx,%edx
f0102af7:	74 10                	je     f0102b09 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0102af9:	8b 10                	mov    (%eax),%edx
f0102afb:	8d 4a 04             	lea    0x4(%edx),%ecx
f0102afe:	89 08                	mov    %ecx,(%eax)
f0102b00:	8b 02                	mov    (%edx),%eax
f0102b02:	ba 00 00 00 00       	mov    $0x0,%edx
f0102b07:	eb 0e                	jmp    f0102b17 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0102b09:	8b 10                	mov    (%eax),%edx
f0102b0b:	8d 4a 04             	lea    0x4(%edx),%ecx
f0102b0e:	89 08                	mov    %ecx,(%eax)
f0102b10:	8b 02                	mov    (%edx),%eax
f0102b12:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0102b17:	5d                   	pop    %ebp
f0102b18:	c3                   	ret    

f0102b19 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0102b19:	55                   	push   %ebp
f0102b1a:	89 e5                	mov    %esp,%ebp
f0102b1c:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0102b1f:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0102b23:	8b 10                	mov    (%eax),%edx
f0102b25:	3b 50 04             	cmp    0x4(%eax),%edx
f0102b28:	73 0a                	jae    f0102b34 <sprintputch+0x1b>
		*b->buf++ = ch;
f0102b2a:	8d 4a 01             	lea    0x1(%edx),%ecx
f0102b2d:	89 08                	mov    %ecx,(%eax)
f0102b2f:	8b 45 08             	mov    0x8(%ebp),%eax
f0102b32:	88 02                	mov    %al,(%edx)
}
f0102b34:	5d                   	pop    %ebp
f0102b35:	c3                   	ret    

f0102b36 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0102b36:	55                   	push   %ebp
f0102b37:	89 e5                	mov    %esp,%ebp
f0102b39:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0102b3c:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0102b3f:	50                   	push   %eax
f0102b40:	ff 75 10             	pushl  0x10(%ebp)
f0102b43:	ff 75 0c             	pushl  0xc(%ebp)
f0102b46:	ff 75 08             	pushl  0x8(%ebp)
f0102b49:	e8 05 00 00 00       	call   f0102b53 <vprintfmt>
	va_end(ap);
}
f0102b4e:	83 c4 10             	add    $0x10,%esp
f0102b51:	c9                   	leave  
f0102b52:	c3                   	ret    

f0102b53 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0102b53:	55                   	push   %ebp
f0102b54:	89 e5                	mov    %esp,%ebp
f0102b56:	57                   	push   %edi
f0102b57:	56                   	push   %esi
f0102b58:	53                   	push   %ebx
f0102b59:	83 ec 2c             	sub    $0x2c,%esp
f0102b5c:	8b 75 08             	mov    0x8(%ebp),%esi
f0102b5f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102b62:	8b 7d 10             	mov    0x10(%ebp),%edi
f0102b65:	eb 12                	jmp    f0102b79 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0102b67:	85 c0                	test   %eax,%eax
f0102b69:	0f 84 89 03 00 00    	je     f0102ef8 <vprintfmt+0x3a5>
				return;
			putch(ch, putdat);
f0102b6f:	83 ec 08             	sub    $0x8,%esp
f0102b72:	53                   	push   %ebx
f0102b73:	50                   	push   %eax
f0102b74:	ff d6                	call   *%esi
f0102b76:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0102b79:	83 c7 01             	add    $0x1,%edi
f0102b7c:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0102b80:	83 f8 25             	cmp    $0x25,%eax
f0102b83:	75 e2                	jne    f0102b67 <vprintfmt+0x14>
f0102b85:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0102b89:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0102b90:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102b97:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0102b9e:	ba 00 00 00 00       	mov    $0x0,%edx
f0102ba3:	eb 07                	jmp    f0102bac <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102ba5:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0102ba8:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102bac:	8d 47 01             	lea    0x1(%edi),%eax
f0102baf:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102bb2:	0f b6 07             	movzbl (%edi),%eax
f0102bb5:	0f b6 c8             	movzbl %al,%ecx
f0102bb8:	83 e8 23             	sub    $0x23,%eax
f0102bbb:	3c 55                	cmp    $0x55,%al
f0102bbd:	0f 87 1a 03 00 00    	ja     f0102edd <vprintfmt+0x38a>
f0102bc3:	0f b6 c0             	movzbl %al,%eax
f0102bc6:	ff 24 85 80 46 10 f0 	jmp    *-0xfefb980(,%eax,4)
f0102bcd:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0102bd0:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0102bd4:	eb d6                	jmp    f0102bac <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102bd6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102bd9:	b8 00 00 00 00       	mov    $0x0,%eax
f0102bde:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0102be1:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0102be4:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f0102be8:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0102beb:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0102bee:	83 fa 09             	cmp    $0x9,%edx
f0102bf1:	77 39                	ja     f0102c2c <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0102bf3:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0102bf6:	eb e9                	jmp    f0102be1 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0102bf8:	8b 45 14             	mov    0x14(%ebp),%eax
f0102bfb:	8d 48 04             	lea    0x4(%eax),%ecx
f0102bfe:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0102c01:	8b 00                	mov    (%eax),%eax
f0102c03:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c06:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0102c09:	eb 27                	jmp    f0102c32 <vprintfmt+0xdf>
f0102c0b:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102c0e:	85 c0                	test   %eax,%eax
f0102c10:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102c15:	0f 49 c8             	cmovns %eax,%ecx
f0102c18:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c1b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102c1e:	eb 8c                	jmp    f0102bac <vprintfmt+0x59>
f0102c20:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0102c23:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0102c2a:	eb 80                	jmp    f0102bac <vprintfmt+0x59>
f0102c2c:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0102c2f:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0102c32:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102c36:	0f 89 70 ff ff ff    	jns    f0102bac <vprintfmt+0x59>
				width = precision, precision = -1;
f0102c3c:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102c3f:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102c42:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102c49:	e9 5e ff ff ff       	jmp    f0102bac <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0102c4e:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c51:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0102c54:	e9 53 ff ff ff       	jmp    f0102bac <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0102c59:	8b 45 14             	mov    0x14(%ebp),%eax
f0102c5c:	8d 50 04             	lea    0x4(%eax),%edx
f0102c5f:	89 55 14             	mov    %edx,0x14(%ebp)
f0102c62:	83 ec 08             	sub    $0x8,%esp
f0102c65:	53                   	push   %ebx
f0102c66:	ff 30                	pushl  (%eax)
f0102c68:	ff d6                	call   *%esi
			break;
f0102c6a:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c6d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0102c70:	e9 04 ff ff ff       	jmp    f0102b79 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0102c75:	8b 45 14             	mov    0x14(%ebp),%eax
f0102c78:	8d 50 04             	lea    0x4(%eax),%edx
f0102c7b:	89 55 14             	mov    %edx,0x14(%ebp)
f0102c7e:	8b 00                	mov    (%eax),%eax
f0102c80:	99                   	cltd   
f0102c81:	31 d0                	xor    %edx,%eax
f0102c83:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0102c85:	83 f8 06             	cmp    $0x6,%eax
f0102c88:	7f 0b                	jg     f0102c95 <vprintfmt+0x142>
f0102c8a:	8b 14 85 d8 47 10 f0 	mov    -0xfefb828(,%eax,4),%edx
f0102c91:	85 d2                	test   %edx,%edx
f0102c93:	75 18                	jne    f0102cad <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f0102c95:	50                   	push   %eax
f0102c96:	68 0b 46 10 f0       	push   $0xf010460b
f0102c9b:	53                   	push   %ebx
f0102c9c:	56                   	push   %esi
f0102c9d:	e8 94 fe ff ff       	call   f0102b36 <printfmt>
f0102ca2:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102ca5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0102ca8:	e9 cc fe ff ff       	jmp    f0102b79 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0102cad:	52                   	push   %edx
f0102cae:	68 23 43 10 f0       	push   $0xf0104323
f0102cb3:	53                   	push   %ebx
f0102cb4:	56                   	push   %esi
f0102cb5:	e8 7c fe ff ff       	call   f0102b36 <printfmt>
f0102cba:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102cbd:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102cc0:	e9 b4 fe ff ff       	jmp    f0102b79 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0102cc5:	8b 45 14             	mov    0x14(%ebp),%eax
f0102cc8:	8d 50 04             	lea    0x4(%eax),%edx
f0102ccb:	89 55 14             	mov    %edx,0x14(%ebp)
f0102cce:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0102cd0:	85 ff                	test   %edi,%edi
f0102cd2:	b8 04 46 10 f0       	mov    $0xf0104604,%eax
f0102cd7:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0102cda:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102cde:	0f 8e 94 00 00 00    	jle    f0102d78 <vprintfmt+0x225>
f0102ce4:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0102ce8:	0f 84 98 00 00 00    	je     f0102d86 <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
f0102cee:	83 ec 08             	sub    $0x8,%esp
f0102cf1:	ff 75 d0             	pushl  -0x30(%ebp)
f0102cf4:	57                   	push   %edi
f0102cf5:	e8 5f 03 00 00       	call   f0103059 <strnlen>
f0102cfa:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0102cfd:	29 c1                	sub    %eax,%ecx
f0102cff:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0102d02:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0102d05:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0102d09:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102d0c:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0102d0f:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102d11:	eb 0f                	jmp    f0102d22 <vprintfmt+0x1cf>
					putch(padc, putdat);
f0102d13:	83 ec 08             	sub    $0x8,%esp
f0102d16:	53                   	push   %ebx
f0102d17:	ff 75 e0             	pushl  -0x20(%ebp)
f0102d1a:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102d1c:	83 ef 01             	sub    $0x1,%edi
f0102d1f:	83 c4 10             	add    $0x10,%esp
f0102d22:	85 ff                	test   %edi,%edi
f0102d24:	7f ed                	jg     f0102d13 <vprintfmt+0x1c0>
f0102d26:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102d29:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0102d2c:	85 c9                	test   %ecx,%ecx
f0102d2e:	b8 00 00 00 00       	mov    $0x0,%eax
f0102d33:	0f 49 c1             	cmovns %ecx,%eax
f0102d36:	29 c1                	sub    %eax,%ecx
f0102d38:	89 75 08             	mov    %esi,0x8(%ebp)
f0102d3b:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102d3e:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102d41:	89 cb                	mov    %ecx,%ebx
f0102d43:	eb 4d                	jmp    f0102d92 <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0102d45:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0102d49:	74 1b                	je     f0102d66 <vprintfmt+0x213>
f0102d4b:	0f be c0             	movsbl %al,%eax
f0102d4e:	83 e8 20             	sub    $0x20,%eax
f0102d51:	83 f8 5e             	cmp    $0x5e,%eax
f0102d54:	76 10                	jbe    f0102d66 <vprintfmt+0x213>
					putch('?', putdat);
f0102d56:	83 ec 08             	sub    $0x8,%esp
f0102d59:	ff 75 0c             	pushl  0xc(%ebp)
f0102d5c:	6a 3f                	push   $0x3f
f0102d5e:	ff 55 08             	call   *0x8(%ebp)
f0102d61:	83 c4 10             	add    $0x10,%esp
f0102d64:	eb 0d                	jmp    f0102d73 <vprintfmt+0x220>
				else
					putch(ch, putdat);
f0102d66:	83 ec 08             	sub    $0x8,%esp
f0102d69:	ff 75 0c             	pushl  0xc(%ebp)
f0102d6c:	52                   	push   %edx
f0102d6d:	ff 55 08             	call   *0x8(%ebp)
f0102d70:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0102d73:	83 eb 01             	sub    $0x1,%ebx
f0102d76:	eb 1a                	jmp    f0102d92 <vprintfmt+0x23f>
f0102d78:	89 75 08             	mov    %esi,0x8(%ebp)
f0102d7b:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102d7e:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102d81:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0102d84:	eb 0c                	jmp    f0102d92 <vprintfmt+0x23f>
f0102d86:	89 75 08             	mov    %esi,0x8(%ebp)
f0102d89:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102d8c:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102d8f:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0102d92:	83 c7 01             	add    $0x1,%edi
f0102d95:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0102d99:	0f be d0             	movsbl %al,%edx
f0102d9c:	85 d2                	test   %edx,%edx
f0102d9e:	74 23                	je     f0102dc3 <vprintfmt+0x270>
f0102da0:	85 f6                	test   %esi,%esi
f0102da2:	78 a1                	js     f0102d45 <vprintfmt+0x1f2>
f0102da4:	83 ee 01             	sub    $0x1,%esi
f0102da7:	79 9c                	jns    f0102d45 <vprintfmt+0x1f2>
f0102da9:	89 df                	mov    %ebx,%edi
f0102dab:	8b 75 08             	mov    0x8(%ebp),%esi
f0102dae:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102db1:	eb 18                	jmp    f0102dcb <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0102db3:	83 ec 08             	sub    $0x8,%esp
f0102db6:	53                   	push   %ebx
f0102db7:	6a 20                	push   $0x20
f0102db9:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0102dbb:	83 ef 01             	sub    $0x1,%edi
f0102dbe:	83 c4 10             	add    $0x10,%esp
f0102dc1:	eb 08                	jmp    f0102dcb <vprintfmt+0x278>
f0102dc3:	89 df                	mov    %ebx,%edi
f0102dc5:	8b 75 08             	mov    0x8(%ebp),%esi
f0102dc8:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102dcb:	85 ff                	test   %edi,%edi
f0102dcd:	7f e4                	jg     f0102db3 <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102dcf:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102dd2:	e9 a2 fd ff ff       	jmp    f0102b79 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0102dd7:	83 fa 01             	cmp    $0x1,%edx
f0102dda:	7e 16                	jle    f0102df2 <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f0102ddc:	8b 45 14             	mov    0x14(%ebp),%eax
f0102ddf:	8d 50 08             	lea    0x8(%eax),%edx
f0102de2:	89 55 14             	mov    %edx,0x14(%ebp)
f0102de5:	8b 50 04             	mov    0x4(%eax),%edx
f0102de8:	8b 00                	mov    (%eax),%eax
f0102dea:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102ded:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0102df0:	eb 32                	jmp    f0102e24 <vprintfmt+0x2d1>
	else if (lflag)
f0102df2:	85 d2                	test   %edx,%edx
f0102df4:	74 18                	je     f0102e0e <vprintfmt+0x2bb>
		return va_arg(*ap, long);
f0102df6:	8b 45 14             	mov    0x14(%ebp),%eax
f0102df9:	8d 50 04             	lea    0x4(%eax),%edx
f0102dfc:	89 55 14             	mov    %edx,0x14(%ebp)
f0102dff:	8b 00                	mov    (%eax),%eax
f0102e01:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102e04:	89 c1                	mov    %eax,%ecx
f0102e06:	c1 f9 1f             	sar    $0x1f,%ecx
f0102e09:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0102e0c:	eb 16                	jmp    f0102e24 <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
f0102e0e:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e11:	8d 50 04             	lea    0x4(%eax),%edx
f0102e14:	89 55 14             	mov    %edx,0x14(%ebp)
f0102e17:	8b 00                	mov    (%eax),%eax
f0102e19:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102e1c:	89 c1                	mov    %eax,%ecx
f0102e1e:	c1 f9 1f             	sar    $0x1f,%ecx
f0102e21:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0102e24:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102e27:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0102e2a:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0102e2f:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0102e33:	79 74                	jns    f0102ea9 <vprintfmt+0x356>
				putch('-', putdat);
f0102e35:	83 ec 08             	sub    $0x8,%esp
f0102e38:	53                   	push   %ebx
f0102e39:	6a 2d                	push   $0x2d
f0102e3b:	ff d6                	call   *%esi
				num = -(long long) num;
f0102e3d:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102e40:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102e43:	f7 d8                	neg    %eax
f0102e45:	83 d2 00             	adc    $0x0,%edx
f0102e48:	f7 da                	neg    %edx
f0102e4a:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0102e4d:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0102e52:	eb 55                	jmp    f0102ea9 <vprintfmt+0x356>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0102e54:	8d 45 14             	lea    0x14(%ebp),%eax
f0102e57:	e8 83 fc ff ff       	call   f0102adf <getuint>
			base = 10;
f0102e5c:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0102e61:	eb 46                	jmp    f0102ea9 <vprintfmt+0x356>
		// (unsigned) octal
		case 'o':
			//putch('X', putdat);
			//putch('X', putdat);
			//putch('X', putdat);
			num = getuint(&ap, lflag);
f0102e63:	8d 45 14             	lea    0x14(%ebp),%eax
f0102e66:	e8 74 fc ff ff       	call   f0102adf <getuint>
			base = 8;
f0102e6b:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0102e70:	eb 37                	jmp    f0102ea9 <vprintfmt+0x356>

		// pointer
		case 'p':
			putch('0', putdat);
f0102e72:	83 ec 08             	sub    $0x8,%esp
f0102e75:	53                   	push   %ebx
f0102e76:	6a 30                	push   $0x30
f0102e78:	ff d6                	call   *%esi
			putch('x', putdat);
f0102e7a:	83 c4 08             	add    $0x8,%esp
f0102e7d:	53                   	push   %ebx
f0102e7e:	6a 78                	push   $0x78
f0102e80:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0102e82:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e85:	8d 50 04             	lea    0x4(%eax),%edx
f0102e88:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0102e8b:	8b 00                	mov    (%eax),%eax
f0102e8d:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0102e92:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0102e95:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0102e9a:	eb 0d                	jmp    f0102ea9 <vprintfmt+0x356>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0102e9c:	8d 45 14             	lea    0x14(%ebp),%eax
f0102e9f:	e8 3b fc ff ff       	call   f0102adf <getuint>
			base = 16;
f0102ea4:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0102ea9:	83 ec 0c             	sub    $0xc,%esp
f0102eac:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0102eb0:	57                   	push   %edi
f0102eb1:	ff 75 e0             	pushl  -0x20(%ebp)
f0102eb4:	51                   	push   %ecx
f0102eb5:	52                   	push   %edx
f0102eb6:	50                   	push   %eax
f0102eb7:	89 da                	mov    %ebx,%edx
f0102eb9:	89 f0                	mov    %esi,%eax
f0102ebb:	e8 70 fb ff ff       	call   f0102a30 <printnum>
			break;
f0102ec0:	83 c4 20             	add    $0x20,%esp
f0102ec3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102ec6:	e9 ae fc ff ff       	jmp    f0102b79 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0102ecb:	83 ec 08             	sub    $0x8,%esp
f0102ece:	53                   	push   %ebx
f0102ecf:	51                   	push   %ecx
f0102ed0:	ff d6                	call   *%esi
			break;
f0102ed2:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102ed5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0102ed8:	e9 9c fc ff ff       	jmp    f0102b79 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0102edd:	83 ec 08             	sub    $0x8,%esp
f0102ee0:	53                   	push   %ebx
f0102ee1:	6a 25                	push   $0x25
f0102ee3:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0102ee5:	83 c4 10             	add    $0x10,%esp
f0102ee8:	eb 03                	jmp    f0102eed <vprintfmt+0x39a>
f0102eea:	83 ef 01             	sub    $0x1,%edi
f0102eed:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0102ef1:	75 f7                	jne    f0102eea <vprintfmt+0x397>
f0102ef3:	e9 81 fc ff ff       	jmp    f0102b79 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0102ef8:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102efb:	5b                   	pop    %ebx
f0102efc:	5e                   	pop    %esi
f0102efd:	5f                   	pop    %edi
f0102efe:	5d                   	pop    %ebp
f0102eff:	c3                   	ret    

f0102f00 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0102f00:	55                   	push   %ebp
f0102f01:	89 e5                	mov    %esp,%ebp
f0102f03:	83 ec 18             	sub    $0x18,%esp
f0102f06:	8b 45 08             	mov    0x8(%ebp),%eax
f0102f09:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0102f0c:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0102f0f:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0102f13:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0102f16:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0102f1d:	85 c0                	test   %eax,%eax
f0102f1f:	74 26                	je     f0102f47 <vsnprintf+0x47>
f0102f21:	85 d2                	test   %edx,%edx
f0102f23:	7e 22                	jle    f0102f47 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0102f25:	ff 75 14             	pushl  0x14(%ebp)
f0102f28:	ff 75 10             	pushl  0x10(%ebp)
f0102f2b:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0102f2e:	50                   	push   %eax
f0102f2f:	68 19 2b 10 f0       	push   $0xf0102b19
f0102f34:	e8 1a fc ff ff       	call   f0102b53 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0102f39:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0102f3c:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0102f3f:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102f42:	83 c4 10             	add    $0x10,%esp
f0102f45:	eb 05                	jmp    f0102f4c <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0102f47:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0102f4c:	c9                   	leave  
f0102f4d:	c3                   	ret    

f0102f4e <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0102f4e:	55                   	push   %ebp
f0102f4f:	89 e5                	mov    %esp,%ebp
f0102f51:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0102f54:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0102f57:	50                   	push   %eax
f0102f58:	ff 75 10             	pushl  0x10(%ebp)
f0102f5b:	ff 75 0c             	pushl  0xc(%ebp)
f0102f5e:	ff 75 08             	pushl  0x8(%ebp)
f0102f61:	e8 9a ff ff ff       	call   f0102f00 <vsnprintf>
	va_end(ap);

	return rc;
}
f0102f66:	c9                   	leave  
f0102f67:	c3                   	ret    

f0102f68 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0102f68:	55                   	push   %ebp
f0102f69:	89 e5                	mov    %esp,%ebp
f0102f6b:	57                   	push   %edi
f0102f6c:	56                   	push   %esi
f0102f6d:	53                   	push   %ebx
f0102f6e:	83 ec 0c             	sub    $0xc,%esp
f0102f71:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0102f74:	85 c0                	test   %eax,%eax
f0102f76:	74 11                	je     f0102f89 <readline+0x21>
		cprintf("%s", prompt);
f0102f78:	83 ec 08             	sub    $0x8,%esp
f0102f7b:	50                   	push   %eax
f0102f7c:	68 23 43 10 f0       	push   $0xf0104323
f0102f81:	e8 80 f7 ff ff       	call   f0102706 <cprintf>
f0102f86:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0102f89:	83 ec 0c             	sub    $0xc,%esp
f0102f8c:	6a 00                	push   $0x0
f0102f8e:	e8 8e d6 ff ff       	call   f0100621 <iscons>
f0102f93:	89 c7                	mov    %eax,%edi
f0102f95:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0102f98:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0102f9d:	e8 6e d6 ff ff       	call   f0100610 <getchar>
f0102fa2:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0102fa4:	85 c0                	test   %eax,%eax
f0102fa6:	79 18                	jns    f0102fc0 <readline+0x58>
			cprintf("read error: %e\n", c);
f0102fa8:	83 ec 08             	sub    $0x8,%esp
f0102fab:	50                   	push   %eax
f0102fac:	68 f4 47 10 f0       	push   $0xf01047f4
f0102fb1:	e8 50 f7 ff ff       	call   f0102706 <cprintf>
			return NULL;
f0102fb6:	83 c4 10             	add    $0x10,%esp
f0102fb9:	b8 00 00 00 00       	mov    $0x0,%eax
f0102fbe:	eb 79                	jmp    f0103039 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0102fc0:	83 f8 08             	cmp    $0x8,%eax
f0102fc3:	0f 94 c2             	sete   %dl
f0102fc6:	83 f8 7f             	cmp    $0x7f,%eax
f0102fc9:	0f 94 c0             	sete   %al
f0102fcc:	08 c2                	or     %al,%dl
f0102fce:	74 1a                	je     f0102fea <readline+0x82>
f0102fd0:	85 f6                	test   %esi,%esi
f0102fd2:	7e 16                	jle    f0102fea <readline+0x82>
			if (echoing)
f0102fd4:	85 ff                	test   %edi,%edi
f0102fd6:	74 0d                	je     f0102fe5 <readline+0x7d>
				cputchar('\b');
f0102fd8:	83 ec 0c             	sub    $0xc,%esp
f0102fdb:	6a 08                	push   $0x8
f0102fdd:	e8 1e d6 ff ff       	call   f0100600 <cputchar>
f0102fe2:	83 c4 10             	add    $0x10,%esp
			i--;
f0102fe5:	83 ee 01             	sub    $0x1,%esi
f0102fe8:	eb b3                	jmp    f0102f9d <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0102fea:	83 fb 1f             	cmp    $0x1f,%ebx
f0102fed:	7e 23                	jle    f0103012 <readline+0xaa>
f0102fef:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0102ff5:	7f 1b                	jg     f0103012 <readline+0xaa>
			if (echoing)
f0102ff7:	85 ff                	test   %edi,%edi
f0102ff9:	74 0c                	je     f0103007 <readline+0x9f>
				cputchar(c);
f0102ffb:	83 ec 0c             	sub    $0xc,%esp
f0102ffe:	53                   	push   %ebx
f0102fff:	e8 fc d5 ff ff       	call   f0100600 <cputchar>
f0103004:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0103007:	88 9e 40 65 11 f0    	mov    %bl,-0xfee9ac0(%esi)
f010300d:	8d 76 01             	lea    0x1(%esi),%esi
f0103010:	eb 8b                	jmp    f0102f9d <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0103012:	83 fb 0a             	cmp    $0xa,%ebx
f0103015:	74 05                	je     f010301c <readline+0xb4>
f0103017:	83 fb 0d             	cmp    $0xd,%ebx
f010301a:	75 81                	jne    f0102f9d <readline+0x35>
			if (echoing)
f010301c:	85 ff                	test   %edi,%edi
f010301e:	74 0d                	je     f010302d <readline+0xc5>
				cputchar('\n');
f0103020:	83 ec 0c             	sub    $0xc,%esp
f0103023:	6a 0a                	push   $0xa
f0103025:	e8 d6 d5 ff ff       	call   f0100600 <cputchar>
f010302a:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f010302d:	c6 86 40 65 11 f0 00 	movb   $0x0,-0xfee9ac0(%esi)
			return buf;
f0103034:	b8 40 65 11 f0       	mov    $0xf0116540,%eax
		}
	}
}
f0103039:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010303c:	5b                   	pop    %ebx
f010303d:	5e                   	pop    %esi
f010303e:	5f                   	pop    %edi
f010303f:	5d                   	pop    %ebp
f0103040:	c3                   	ret    

f0103041 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0103041:	55                   	push   %ebp
f0103042:	89 e5                	mov    %esp,%ebp
f0103044:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0103047:	b8 00 00 00 00       	mov    $0x0,%eax
f010304c:	eb 03                	jmp    f0103051 <strlen+0x10>
		n++;
f010304e:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0103051:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0103055:	75 f7                	jne    f010304e <strlen+0xd>
		n++;
	return n;
}
f0103057:	5d                   	pop    %ebp
f0103058:	c3                   	ret    

f0103059 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0103059:	55                   	push   %ebp
f010305a:	89 e5                	mov    %esp,%ebp
f010305c:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010305f:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103062:	ba 00 00 00 00       	mov    $0x0,%edx
f0103067:	eb 03                	jmp    f010306c <strnlen+0x13>
		n++;
f0103069:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010306c:	39 c2                	cmp    %eax,%edx
f010306e:	74 08                	je     f0103078 <strnlen+0x1f>
f0103070:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f0103074:	75 f3                	jne    f0103069 <strnlen+0x10>
f0103076:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0103078:	5d                   	pop    %ebp
f0103079:	c3                   	ret    

f010307a <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f010307a:	55                   	push   %ebp
f010307b:	89 e5                	mov    %esp,%ebp
f010307d:	53                   	push   %ebx
f010307e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103081:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0103084:	89 c2                	mov    %eax,%edx
f0103086:	83 c2 01             	add    $0x1,%edx
f0103089:	83 c1 01             	add    $0x1,%ecx
f010308c:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0103090:	88 5a ff             	mov    %bl,-0x1(%edx)
f0103093:	84 db                	test   %bl,%bl
f0103095:	75 ef                	jne    f0103086 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0103097:	5b                   	pop    %ebx
f0103098:	5d                   	pop    %ebp
f0103099:	c3                   	ret    

f010309a <strcat>:

char *
strcat(char *dst, const char *src)
{
f010309a:	55                   	push   %ebp
f010309b:	89 e5                	mov    %esp,%ebp
f010309d:	53                   	push   %ebx
f010309e:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01030a1:	53                   	push   %ebx
f01030a2:	e8 9a ff ff ff       	call   f0103041 <strlen>
f01030a7:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f01030aa:	ff 75 0c             	pushl  0xc(%ebp)
f01030ad:	01 d8                	add    %ebx,%eax
f01030af:	50                   	push   %eax
f01030b0:	e8 c5 ff ff ff       	call   f010307a <strcpy>
	return dst;
}
f01030b5:	89 d8                	mov    %ebx,%eax
f01030b7:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01030ba:	c9                   	leave  
f01030bb:	c3                   	ret    

f01030bc <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01030bc:	55                   	push   %ebp
f01030bd:	89 e5                	mov    %esp,%ebp
f01030bf:	56                   	push   %esi
f01030c0:	53                   	push   %ebx
f01030c1:	8b 75 08             	mov    0x8(%ebp),%esi
f01030c4:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01030c7:	89 f3                	mov    %esi,%ebx
f01030c9:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01030cc:	89 f2                	mov    %esi,%edx
f01030ce:	eb 0f                	jmp    f01030df <strncpy+0x23>
		*dst++ = *src;
f01030d0:	83 c2 01             	add    $0x1,%edx
f01030d3:	0f b6 01             	movzbl (%ecx),%eax
f01030d6:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01030d9:	80 39 01             	cmpb   $0x1,(%ecx)
f01030dc:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01030df:	39 da                	cmp    %ebx,%edx
f01030e1:	75 ed                	jne    f01030d0 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01030e3:	89 f0                	mov    %esi,%eax
f01030e5:	5b                   	pop    %ebx
f01030e6:	5e                   	pop    %esi
f01030e7:	5d                   	pop    %ebp
f01030e8:	c3                   	ret    

f01030e9 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01030e9:	55                   	push   %ebp
f01030ea:	89 e5                	mov    %esp,%ebp
f01030ec:	56                   	push   %esi
f01030ed:	53                   	push   %ebx
f01030ee:	8b 75 08             	mov    0x8(%ebp),%esi
f01030f1:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01030f4:	8b 55 10             	mov    0x10(%ebp),%edx
f01030f7:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01030f9:	85 d2                	test   %edx,%edx
f01030fb:	74 21                	je     f010311e <strlcpy+0x35>
f01030fd:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0103101:	89 f2                	mov    %esi,%edx
f0103103:	eb 09                	jmp    f010310e <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0103105:	83 c2 01             	add    $0x1,%edx
f0103108:	83 c1 01             	add    $0x1,%ecx
f010310b:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f010310e:	39 c2                	cmp    %eax,%edx
f0103110:	74 09                	je     f010311b <strlcpy+0x32>
f0103112:	0f b6 19             	movzbl (%ecx),%ebx
f0103115:	84 db                	test   %bl,%bl
f0103117:	75 ec                	jne    f0103105 <strlcpy+0x1c>
f0103119:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f010311b:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f010311e:	29 f0                	sub    %esi,%eax
}
f0103120:	5b                   	pop    %ebx
f0103121:	5e                   	pop    %esi
f0103122:	5d                   	pop    %ebp
f0103123:	c3                   	ret    

f0103124 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0103124:	55                   	push   %ebp
f0103125:	89 e5                	mov    %esp,%ebp
f0103127:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010312a:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f010312d:	eb 06                	jmp    f0103135 <strcmp+0x11>
		p++, q++;
f010312f:	83 c1 01             	add    $0x1,%ecx
f0103132:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0103135:	0f b6 01             	movzbl (%ecx),%eax
f0103138:	84 c0                	test   %al,%al
f010313a:	74 04                	je     f0103140 <strcmp+0x1c>
f010313c:	3a 02                	cmp    (%edx),%al
f010313e:	74 ef                	je     f010312f <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0103140:	0f b6 c0             	movzbl %al,%eax
f0103143:	0f b6 12             	movzbl (%edx),%edx
f0103146:	29 d0                	sub    %edx,%eax
}
f0103148:	5d                   	pop    %ebp
f0103149:	c3                   	ret    

f010314a <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f010314a:	55                   	push   %ebp
f010314b:	89 e5                	mov    %esp,%ebp
f010314d:	53                   	push   %ebx
f010314e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103151:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103154:	89 c3                	mov    %eax,%ebx
f0103156:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0103159:	eb 06                	jmp    f0103161 <strncmp+0x17>
		n--, p++, q++;
f010315b:	83 c0 01             	add    $0x1,%eax
f010315e:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0103161:	39 d8                	cmp    %ebx,%eax
f0103163:	74 15                	je     f010317a <strncmp+0x30>
f0103165:	0f b6 08             	movzbl (%eax),%ecx
f0103168:	84 c9                	test   %cl,%cl
f010316a:	74 04                	je     f0103170 <strncmp+0x26>
f010316c:	3a 0a                	cmp    (%edx),%cl
f010316e:	74 eb                	je     f010315b <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0103170:	0f b6 00             	movzbl (%eax),%eax
f0103173:	0f b6 12             	movzbl (%edx),%edx
f0103176:	29 d0                	sub    %edx,%eax
f0103178:	eb 05                	jmp    f010317f <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f010317a:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f010317f:	5b                   	pop    %ebx
f0103180:	5d                   	pop    %ebp
f0103181:	c3                   	ret    

f0103182 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0103182:	55                   	push   %ebp
f0103183:	89 e5                	mov    %esp,%ebp
f0103185:	8b 45 08             	mov    0x8(%ebp),%eax
f0103188:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010318c:	eb 07                	jmp    f0103195 <strchr+0x13>
		if (*s == c)
f010318e:	38 ca                	cmp    %cl,%dl
f0103190:	74 0f                	je     f01031a1 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0103192:	83 c0 01             	add    $0x1,%eax
f0103195:	0f b6 10             	movzbl (%eax),%edx
f0103198:	84 d2                	test   %dl,%dl
f010319a:	75 f2                	jne    f010318e <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f010319c:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01031a1:	5d                   	pop    %ebp
f01031a2:	c3                   	ret    

f01031a3 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01031a3:	55                   	push   %ebp
f01031a4:	89 e5                	mov    %esp,%ebp
f01031a6:	8b 45 08             	mov    0x8(%ebp),%eax
f01031a9:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01031ad:	eb 03                	jmp    f01031b2 <strfind+0xf>
f01031af:	83 c0 01             	add    $0x1,%eax
f01031b2:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f01031b5:	38 ca                	cmp    %cl,%dl
f01031b7:	74 04                	je     f01031bd <strfind+0x1a>
f01031b9:	84 d2                	test   %dl,%dl
f01031bb:	75 f2                	jne    f01031af <strfind+0xc>
			break;
	return (char *) s;
}
f01031bd:	5d                   	pop    %ebp
f01031be:	c3                   	ret    

f01031bf <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01031bf:	55                   	push   %ebp
f01031c0:	89 e5                	mov    %esp,%ebp
f01031c2:	57                   	push   %edi
f01031c3:	56                   	push   %esi
f01031c4:	53                   	push   %ebx
f01031c5:	8b 7d 08             	mov    0x8(%ebp),%edi
f01031c8:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01031cb:	85 c9                	test   %ecx,%ecx
f01031cd:	74 36                	je     f0103205 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01031cf:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01031d5:	75 28                	jne    f01031ff <memset+0x40>
f01031d7:	f6 c1 03             	test   $0x3,%cl
f01031da:	75 23                	jne    f01031ff <memset+0x40>
		c &= 0xFF;
f01031dc:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01031e0:	89 d3                	mov    %edx,%ebx
f01031e2:	c1 e3 08             	shl    $0x8,%ebx
f01031e5:	89 d6                	mov    %edx,%esi
f01031e7:	c1 e6 18             	shl    $0x18,%esi
f01031ea:	89 d0                	mov    %edx,%eax
f01031ec:	c1 e0 10             	shl    $0x10,%eax
f01031ef:	09 f0                	or     %esi,%eax
f01031f1:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f01031f3:	89 d8                	mov    %ebx,%eax
f01031f5:	09 d0                	or     %edx,%eax
f01031f7:	c1 e9 02             	shr    $0x2,%ecx
f01031fa:	fc                   	cld    
f01031fb:	f3 ab                	rep stos %eax,%es:(%edi)
f01031fd:	eb 06                	jmp    f0103205 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01031ff:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103202:	fc                   	cld    
f0103203:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0103205:	89 f8                	mov    %edi,%eax
f0103207:	5b                   	pop    %ebx
f0103208:	5e                   	pop    %esi
f0103209:	5f                   	pop    %edi
f010320a:	5d                   	pop    %ebp
f010320b:	c3                   	ret    

f010320c <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f010320c:	55                   	push   %ebp
f010320d:	89 e5                	mov    %esp,%ebp
f010320f:	57                   	push   %edi
f0103210:	56                   	push   %esi
f0103211:	8b 45 08             	mov    0x8(%ebp),%eax
f0103214:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103217:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f010321a:	39 c6                	cmp    %eax,%esi
f010321c:	73 35                	jae    f0103253 <memmove+0x47>
f010321e:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0103221:	39 d0                	cmp    %edx,%eax
f0103223:	73 2e                	jae    f0103253 <memmove+0x47>
		s += n;
		d += n;
f0103225:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103228:	89 d6                	mov    %edx,%esi
f010322a:	09 fe                	or     %edi,%esi
f010322c:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0103232:	75 13                	jne    f0103247 <memmove+0x3b>
f0103234:	f6 c1 03             	test   $0x3,%cl
f0103237:	75 0e                	jne    f0103247 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f0103239:	83 ef 04             	sub    $0x4,%edi
f010323c:	8d 72 fc             	lea    -0x4(%edx),%esi
f010323f:	c1 e9 02             	shr    $0x2,%ecx
f0103242:	fd                   	std    
f0103243:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103245:	eb 09                	jmp    f0103250 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0103247:	83 ef 01             	sub    $0x1,%edi
f010324a:	8d 72 ff             	lea    -0x1(%edx),%esi
f010324d:	fd                   	std    
f010324e:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0103250:	fc                   	cld    
f0103251:	eb 1d                	jmp    f0103270 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103253:	89 f2                	mov    %esi,%edx
f0103255:	09 c2                	or     %eax,%edx
f0103257:	f6 c2 03             	test   $0x3,%dl
f010325a:	75 0f                	jne    f010326b <memmove+0x5f>
f010325c:	f6 c1 03             	test   $0x3,%cl
f010325f:	75 0a                	jne    f010326b <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f0103261:	c1 e9 02             	shr    $0x2,%ecx
f0103264:	89 c7                	mov    %eax,%edi
f0103266:	fc                   	cld    
f0103267:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103269:	eb 05                	jmp    f0103270 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f010326b:	89 c7                	mov    %eax,%edi
f010326d:	fc                   	cld    
f010326e:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0103270:	5e                   	pop    %esi
f0103271:	5f                   	pop    %edi
f0103272:	5d                   	pop    %ebp
f0103273:	c3                   	ret    

f0103274 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0103274:	55                   	push   %ebp
f0103275:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0103277:	ff 75 10             	pushl  0x10(%ebp)
f010327a:	ff 75 0c             	pushl  0xc(%ebp)
f010327d:	ff 75 08             	pushl  0x8(%ebp)
f0103280:	e8 87 ff ff ff       	call   f010320c <memmove>
}
f0103285:	c9                   	leave  
f0103286:	c3                   	ret    

f0103287 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0103287:	55                   	push   %ebp
f0103288:	89 e5                	mov    %esp,%ebp
f010328a:	56                   	push   %esi
f010328b:	53                   	push   %ebx
f010328c:	8b 45 08             	mov    0x8(%ebp),%eax
f010328f:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103292:	89 c6                	mov    %eax,%esi
f0103294:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103297:	eb 1a                	jmp    f01032b3 <memcmp+0x2c>
		if (*s1 != *s2)
f0103299:	0f b6 08             	movzbl (%eax),%ecx
f010329c:	0f b6 1a             	movzbl (%edx),%ebx
f010329f:	38 d9                	cmp    %bl,%cl
f01032a1:	74 0a                	je     f01032ad <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f01032a3:	0f b6 c1             	movzbl %cl,%eax
f01032a6:	0f b6 db             	movzbl %bl,%ebx
f01032a9:	29 d8                	sub    %ebx,%eax
f01032ab:	eb 0f                	jmp    f01032bc <memcmp+0x35>
		s1++, s2++;
f01032ad:	83 c0 01             	add    $0x1,%eax
f01032b0:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01032b3:	39 f0                	cmp    %esi,%eax
f01032b5:	75 e2                	jne    f0103299 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01032b7:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01032bc:	5b                   	pop    %ebx
f01032bd:	5e                   	pop    %esi
f01032be:	5d                   	pop    %ebp
f01032bf:	c3                   	ret    

f01032c0 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01032c0:	55                   	push   %ebp
f01032c1:	89 e5                	mov    %esp,%ebp
f01032c3:	53                   	push   %ebx
f01032c4:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f01032c7:	89 c1                	mov    %eax,%ecx
f01032c9:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f01032cc:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01032d0:	eb 0a                	jmp    f01032dc <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f01032d2:	0f b6 10             	movzbl (%eax),%edx
f01032d5:	39 da                	cmp    %ebx,%edx
f01032d7:	74 07                	je     f01032e0 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01032d9:	83 c0 01             	add    $0x1,%eax
f01032dc:	39 c8                	cmp    %ecx,%eax
f01032de:	72 f2                	jb     f01032d2 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01032e0:	5b                   	pop    %ebx
f01032e1:	5d                   	pop    %ebp
f01032e2:	c3                   	ret    

f01032e3 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01032e3:	55                   	push   %ebp
f01032e4:	89 e5                	mov    %esp,%ebp
f01032e6:	57                   	push   %edi
f01032e7:	56                   	push   %esi
f01032e8:	53                   	push   %ebx
f01032e9:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01032ec:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01032ef:	eb 03                	jmp    f01032f4 <strtol+0x11>
		s++;
f01032f1:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01032f4:	0f b6 01             	movzbl (%ecx),%eax
f01032f7:	3c 20                	cmp    $0x20,%al
f01032f9:	74 f6                	je     f01032f1 <strtol+0xe>
f01032fb:	3c 09                	cmp    $0x9,%al
f01032fd:	74 f2                	je     f01032f1 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f01032ff:	3c 2b                	cmp    $0x2b,%al
f0103301:	75 0a                	jne    f010330d <strtol+0x2a>
		s++;
f0103303:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0103306:	bf 00 00 00 00       	mov    $0x0,%edi
f010330b:	eb 11                	jmp    f010331e <strtol+0x3b>
f010330d:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0103312:	3c 2d                	cmp    $0x2d,%al
f0103314:	75 08                	jne    f010331e <strtol+0x3b>
		s++, neg = 1;
f0103316:	83 c1 01             	add    $0x1,%ecx
f0103319:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f010331e:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0103324:	75 15                	jne    f010333b <strtol+0x58>
f0103326:	80 39 30             	cmpb   $0x30,(%ecx)
f0103329:	75 10                	jne    f010333b <strtol+0x58>
f010332b:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f010332f:	75 7c                	jne    f01033ad <strtol+0xca>
		s += 2, base = 16;
f0103331:	83 c1 02             	add    $0x2,%ecx
f0103334:	bb 10 00 00 00       	mov    $0x10,%ebx
f0103339:	eb 16                	jmp    f0103351 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f010333b:	85 db                	test   %ebx,%ebx
f010333d:	75 12                	jne    f0103351 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f010333f:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0103344:	80 39 30             	cmpb   $0x30,(%ecx)
f0103347:	75 08                	jne    f0103351 <strtol+0x6e>
		s++, base = 8;
f0103349:	83 c1 01             	add    $0x1,%ecx
f010334c:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f0103351:	b8 00 00 00 00       	mov    $0x0,%eax
f0103356:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0103359:	0f b6 11             	movzbl (%ecx),%edx
f010335c:	8d 72 d0             	lea    -0x30(%edx),%esi
f010335f:	89 f3                	mov    %esi,%ebx
f0103361:	80 fb 09             	cmp    $0x9,%bl
f0103364:	77 08                	ja     f010336e <strtol+0x8b>
			dig = *s - '0';
f0103366:	0f be d2             	movsbl %dl,%edx
f0103369:	83 ea 30             	sub    $0x30,%edx
f010336c:	eb 22                	jmp    f0103390 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f010336e:	8d 72 9f             	lea    -0x61(%edx),%esi
f0103371:	89 f3                	mov    %esi,%ebx
f0103373:	80 fb 19             	cmp    $0x19,%bl
f0103376:	77 08                	ja     f0103380 <strtol+0x9d>
			dig = *s - 'a' + 10;
f0103378:	0f be d2             	movsbl %dl,%edx
f010337b:	83 ea 57             	sub    $0x57,%edx
f010337e:	eb 10                	jmp    f0103390 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f0103380:	8d 72 bf             	lea    -0x41(%edx),%esi
f0103383:	89 f3                	mov    %esi,%ebx
f0103385:	80 fb 19             	cmp    $0x19,%bl
f0103388:	77 16                	ja     f01033a0 <strtol+0xbd>
			dig = *s - 'A' + 10;
f010338a:	0f be d2             	movsbl %dl,%edx
f010338d:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f0103390:	3b 55 10             	cmp    0x10(%ebp),%edx
f0103393:	7d 0b                	jge    f01033a0 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f0103395:	83 c1 01             	add    $0x1,%ecx
f0103398:	0f af 45 10          	imul   0x10(%ebp),%eax
f010339c:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f010339e:	eb b9                	jmp    f0103359 <strtol+0x76>

	if (endptr)
f01033a0:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01033a4:	74 0d                	je     f01033b3 <strtol+0xd0>
		*endptr = (char *) s;
f01033a6:	8b 75 0c             	mov    0xc(%ebp),%esi
f01033a9:	89 0e                	mov    %ecx,(%esi)
f01033ab:	eb 06                	jmp    f01033b3 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01033ad:	85 db                	test   %ebx,%ebx
f01033af:	74 98                	je     f0103349 <strtol+0x66>
f01033b1:	eb 9e                	jmp    f0103351 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f01033b3:	89 c2                	mov    %eax,%edx
f01033b5:	f7 da                	neg    %edx
f01033b7:	85 ff                	test   %edi,%edi
f01033b9:	0f 45 c2             	cmovne %edx,%eax
}
f01033bc:	5b                   	pop    %ebx
f01033bd:	5e                   	pop    %esi
f01033be:	5f                   	pop    %edi
f01033bf:	5d                   	pop    %ebp
f01033c0:	c3                   	ret    
f01033c1:	66 90                	xchg   %ax,%ax
f01033c3:	66 90                	xchg   %ax,%ax
f01033c5:	66 90                	xchg   %ax,%ax
f01033c7:	66 90                	xchg   %ax,%ax
f01033c9:	66 90                	xchg   %ax,%ax
f01033cb:	66 90                	xchg   %ax,%ax
f01033cd:	66 90                	xchg   %ax,%ax
f01033cf:	90                   	nop

f01033d0 <__udivdi3>:
f01033d0:	55                   	push   %ebp
f01033d1:	57                   	push   %edi
f01033d2:	56                   	push   %esi
f01033d3:	53                   	push   %ebx
f01033d4:	83 ec 1c             	sub    $0x1c,%esp
f01033d7:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f01033db:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f01033df:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f01033e3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01033e7:	85 f6                	test   %esi,%esi
f01033e9:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01033ed:	89 ca                	mov    %ecx,%edx
f01033ef:	89 f8                	mov    %edi,%eax
f01033f1:	75 3d                	jne    f0103430 <__udivdi3+0x60>
f01033f3:	39 cf                	cmp    %ecx,%edi
f01033f5:	0f 87 c5 00 00 00    	ja     f01034c0 <__udivdi3+0xf0>
f01033fb:	85 ff                	test   %edi,%edi
f01033fd:	89 fd                	mov    %edi,%ebp
f01033ff:	75 0b                	jne    f010340c <__udivdi3+0x3c>
f0103401:	b8 01 00 00 00       	mov    $0x1,%eax
f0103406:	31 d2                	xor    %edx,%edx
f0103408:	f7 f7                	div    %edi
f010340a:	89 c5                	mov    %eax,%ebp
f010340c:	89 c8                	mov    %ecx,%eax
f010340e:	31 d2                	xor    %edx,%edx
f0103410:	f7 f5                	div    %ebp
f0103412:	89 c1                	mov    %eax,%ecx
f0103414:	89 d8                	mov    %ebx,%eax
f0103416:	89 cf                	mov    %ecx,%edi
f0103418:	f7 f5                	div    %ebp
f010341a:	89 c3                	mov    %eax,%ebx
f010341c:	89 d8                	mov    %ebx,%eax
f010341e:	89 fa                	mov    %edi,%edx
f0103420:	83 c4 1c             	add    $0x1c,%esp
f0103423:	5b                   	pop    %ebx
f0103424:	5e                   	pop    %esi
f0103425:	5f                   	pop    %edi
f0103426:	5d                   	pop    %ebp
f0103427:	c3                   	ret    
f0103428:	90                   	nop
f0103429:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103430:	39 ce                	cmp    %ecx,%esi
f0103432:	77 74                	ja     f01034a8 <__udivdi3+0xd8>
f0103434:	0f bd fe             	bsr    %esi,%edi
f0103437:	83 f7 1f             	xor    $0x1f,%edi
f010343a:	0f 84 98 00 00 00    	je     f01034d8 <__udivdi3+0x108>
f0103440:	bb 20 00 00 00       	mov    $0x20,%ebx
f0103445:	89 f9                	mov    %edi,%ecx
f0103447:	89 c5                	mov    %eax,%ebp
f0103449:	29 fb                	sub    %edi,%ebx
f010344b:	d3 e6                	shl    %cl,%esi
f010344d:	89 d9                	mov    %ebx,%ecx
f010344f:	d3 ed                	shr    %cl,%ebp
f0103451:	89 f9                	mov    %edi,%ecx
f0103453:	d3 e0                	shl    %cl,%eax
f0103455:	09 ee                	or     %ebp,%esi
f0103457:	89 d9                	mov    %ebx,%ecx
f0103459:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010345d:	89 d5                	mov    %edx,%ebp
f010345f:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103463:	d3 ed                	shr    %cl,%ebp
f0103465:	89 f9                	mov    %edi,%ecx
f0103467:	d3 e2                	shl    %cl,%edx
f0103469:	89 d9                	mov    %ebx,%ecx
f010346b:	d3 e8                	shr    %cl,%eax
f010346d:	09 c2                	or     %eax,%edx
f010346f:	89 d0                	mov    %edx,%eax
f0103471:	89 ea                	mov    %ebp,%edx
f0103473:	f7 f6                	div    %esi
f0103475:	89 d5                	mov    %edx,%ebp
f0103477:	89 c3                	mov    %eax,%ebx
f0103479:	f7 64 24 0c          	mull   0xc(%esp)
f010347d:	39 d5                	cmp    %edx,%ebp
f010347f:	72 10                	jb     f0103491 <__udivdi3+0xc1>
f0103481:	8b 74 24 08          	mov    0x8(%esp),%esi
f0103485:	89 f9                	mov    %edi,%ecx
f0103487:	d3 e6                	shl    %cl,%esi
f0103489:	39 c6                	cmp    %eax,%esi
f010348b:	73 07                	jae    f0103494 <__udivdi3+0xc4>
f010348d:	39 d5                	cmp    %edx,%ebp
f010348f:	75 03                	jne    f0103494 <__udivdi3+0xc4>
f0103491:	83 eb 01             	sub    $0x1,%ebx
f0103494:	31 ff                	xor    %edi,%edi
f0103496:	89 d8                	mov    %ebx,%eax
f0103498:	89 fa                	mov    %edi,%edx
f010349a:	83 c4 1c             	add    $0x1c,%esp
f010349d:	5b                   	pop    %ebx
f010349e:	5e                   	pop    %esi
f010349f:	5f                   	pop    %edi
f01034a0:	5d                   	pop    %ebp
f01034a1:	c3                   	ret    
f01034a2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01034a8:	31 ff                	xor    %edi,%edi
f01034aa:	31 db                	xor    %ebx,%ebx
f01034ac:	89 d8                	mov    %ebx,%eax
f01034ae:	89 fa                	mov    %edi,%edx
f01034b0:	83 c4 1c             	add    $0x1c,%esp
f01034b3:	5b                   	pop    %ebx
f01034b4:	5e                   	pop    %esi
f01034b5:	5f                   	pop    %edi
f01034b6:	5d                   	pop    %ebp
f01034b7:	c3                   	ret    
f01034b8:	90                   	nop
f01034b9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01034c0:	89 d8                	mov    %ebx,%eax
f01034c2:	f7 f7                	div    %edi
f01034c4:	31 ff                	xor    %edi,%edi
f01034c6:	89 c3                	mov    %eax,%ebx
f01034c8:	89 d8                	mov    %ebx,%eax
f01034ca:	89 fa                	mov    %edi,%edx
f01034cc:	83 c4 1c             	add    $0x1c,%esp
f01034cf:	5b                   	pop    %ebx
f01034d0:	5e                   	pop    %esi
f01034d1:	5f                   	pop    %edi
f01034d2:	5d                   	pop    %ebp
f01034d3:	c3                   	ret    
f01034d4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01034d8:	39 ce                	cmp    %ecx,%esi
f01034da:	72 0c                	jb     f01034e8 <__udivdi3+0x118>
f01034dc:	31 db                	xor    %ebx,%ebx
f01034de:	3b 44 24 08          	cmp    0x8(%esp),%eax
f01034e2:	0f 87 34 ff ff ff    	ja     f010341c <__udivdi3+0x4c>
f01034e8:	bb 01 00 00 00       	mov    $0x1,%ebx
f01034ed:	e9 2a ff ff ff       	jmp    f010341c <__udivdi3+0x4c>
f01034f2:	66 90                	xchg   %ax,%ax
f01034f4:	66 90                	xchg   %ax,%ax
f01034f6:	66 90                	xchg   %ax,%ax
f01034f8:	66 90                	xchg   %ax,%ax
f01034fa:	66 90                	xchg   %ax,%ax
f01034fc:	66 90                	xchg   %ax,%ax
f01034fe:	66 90                	xchg   %ax,%ax

f0103500 <__umoddi3>:
f0103500:	55                   	push   %ebp
f0103501:	57                   	push   %edi
f0103502:	56                   	push   %esi
f0103503:	53                   	push   %ebx
f0103504:	83 ec 1c             	sub    $0x1c,%esp
f0103507:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010350b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f010350f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0103513:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0103517:	85 d2                	test   %edx,%edx
f0103519:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010351d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103521:	89 f3                	mov    %esi,%ebx
f0103523:	89 3c 24             	mov    %edi,(%esp)
f0103526:	89 74 24 04          	mov    %esi,0x4(%esp)
f010352a:	75 1c                	jne    f0103548 <__umoddi3+0x48>
f010352c:	39 f7                	cmp    %esi,%edi
f010352e:	76 50                	jbe    f0103580 <__umoddi3+0x80>
f0103530:	89 c8                	mov    %ecx,%eax
f0103532:	89 f2                	mov    %esi,%edx
f0103534:	f7 f7                	div    %edi
f0103536:	89 d0                	mov    %edx,%eax
f0103538:	31 d2                	xor    %edx,%edx
f010353a:	83 c4 1c             	add    $0x1c,%esp
f010353d:	5b                   	pop    %ebx
f010353e:	5e                   	pop    %esi
f010353f:	5f                   	pop    %edi
f0103540:	5d                   	pop    %ebp
f0103541:	c3                   	ret    
f0103542:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103548:	39 f2                	cmp    %esi,%edx
f010354a:	89 d0                	mov    %edx,%eax
f010354c:	77 52                	ja     f01035a0 <__umoddi3+0xa0>
f010354e:	0f bd ea             	bsr    %edx,%ebp
f0103551:	83 f5 1f             	xor    $0x1f,%ebp
f0103554:	75 5a                	jne    f01035b0 <__umoddi3+0xb0>
f0103556:	3b 54 24 04          	cmp    0x4(%esp),%edx
f010355a:	0f 82 e0 00 00 00    	jb     f0103640 <__umoddi3+0x140>
f0103560:	39 0c 24             	cmp    %ecx,(%esp)
f0103563:	0f 86 d7 00 00 00    	jbe    f0103640 <__umoddi3+0x140>
f0103569:	8b 44 24 08          	mov    0x8(%esp),%eax
f010356d:	8b 54 24 04          	mov    0x4(%esp),%edx
f0103571:	83 c4 1c             	add    $0x1c,%esp
f0103574:	5b                   	pop    %ebx
f0103575:	5e                   	pop    %esi
f0103576:	5f                   	pop    %edi
f0103577:	5d                   	pop    %ebp
f0103578:	c3                   	ret    
f0103579:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103580:	85 ff                	test   %edi,%edi
f0103582:	89 fd                	mov    %edi,%ebp
f0103584:	75 0b                	jne    f0103591 <__umoddi3+0x91>
f0103586:	b8 01 00 00 00       	mov    $0x1,%eax
f010358b:	31 d2                	xor    %edx,%edx
f010358d:	f7 f7                	div    %edi
f010358f:	89 c5                	mov    %eax,%ebp
f0103591:	89 f0                	mov    %esi,%eax
f0103593:	31 d2                	xor    %edx,%edx
f0103595:	f7 f5                	div    %ebp
f0103597:	89 c8                	mov    %ecx,%eax
f0103599:	f7 f5                	div    %ebp
f010359b:	89 d0                	mov    %edx,%eax
f010359d:	eb 99                	jmp    f0103538 <__umoddi3+0x38>
f010359f:	90                   	nop
f01035a0:	89 c8                	mov    %ecx,%eax
f01035a2:	89 f2                	mov    %esi,%edx
f01035a4:	83 c4 1c             	add    $0x1c,%esp
f01035a7:	5b                   	pop    %ebx
f01035a8:	5e                   	pop    %esi
f01035a9:	5f                   	pop    %edi
f01035aa:	5d                   	pop    %ebp
f01035ab:	c3                   	ret    
f01035ac:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01035b0:	8b 34 24             	mov    (%esp),%esi
f01035b3:	bf 20 00 00 00       	mov    $0x20,%edi
f01035b8:	89 e9                	mov    %ebp,%ecx
f01035ba:	29 ef                	sub    %ebp,%edi
f01035bc:	d3 e0                	shl    %cl,%eax
f01035be:	89 f9                	mov    %edi,%ecx
f01035c0:	89 f2                	mov    %esi,%edx
f01035c2:	d3 ea                	shr    %cl,%edx
f01035c4:	89 e9                	mov    %ebp,%ecx
f01035c6:	09 c2                	or     %eax,%edx
f01035c8:	89 d8                	mov    %ebx,%eax
f01035ca:	89 14 24             	mov    %edx,(%esp)
f01035cd:	89 f2                	mov    %esi,%edx
f01035cf:	d3 e2                	shl    %cl,%edx
f01035d1:	89 f9                	mov    %edi,%ecx
f01035d3:	89 54 24 04          	mov    %edx,0x4(%esp)
f01035d7:	8b 54 24 0c          	mov    0xc(%esp),%edx
f01035db:	d3 e8                	shr    %cl,%eax
f01035dd:	89 e9                	mov    %ebp,%ecx
f01035df:	89 c6                	mov    %eax,%esi
f01035e1:	d3 e3                	shl    %cl,%ebx
f01035e3:	89 f9                	mov    %edi,%ecx
f01035e5:	89 d0                	mov    %edx,%eax
f01035e7:	d3 e8                	shr    %cl,%eax
f01035e9:	89 e9                	mov    %ebp,%ecx
f01035eb:	09 d8                	or     %ebx,%eax
f01035ed:	89 d3                	mov    %edx,%ebx
f01035ef:	89 f2                	mov    %esi,%edx
f01035f1:	f7 34 24             	divl   (%esp)
f01035f4:	89 d6                	mov    %edx,%esi
f01035f6:	d3 e3                	shl    %cl,%ebx
f01035f8:	f7 64 24 04          	mull   0x4(%esp)
f01035fc:	39 d6                	cmp    %edx,%esi
f01035fe:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0103602:	89 d1                	mov    %edx,%ecx
f0103604:	89 c3                	mov    %eax,%ebx
f0103606:	72 08                	jb     f0103610 <__umoddi3+0x110>
f0103608:	75 11                	jne    f010361b <__umoddi3+0x11b>
f010360a:	39 44 24 08          	cmp    %eax,0x8(%esp)
f010360e:	73 0b                	jae    f010361b <__umoddi3+0x11b>
f0103610:	2b 44 24 04          	sub    0x4(%esp),%eax
f0103614:	1b 14 24             	sbb    (%esp),%edx
f0103617:	89 d1                	mov    %edx,%ecx
f0103619:	89 c3                	mov    %eax,%ebx
f010361b:	8b 54 24 08          	mov    0x8(%esp),%edx
f010361f:	29 da                	sub    %ebx,%edx
f0103621:	19 ce                	sbb    %ecx,%esi
f0103623:	89 f9                	mov    %edi,%ecx
f0103625:	89 f0                	mov    %esi,%eax
f0103627:	d3 e0                	shl    %cl,%eax
f0103629:	89 e9                	mov    %ebp,%ecx
f010362b:	d3 ea                	shr    %cl,%edx
f010362d:	89 e9                	mov    %ebp,%ecx
f010362f:	d3 ee                	shr    %cl,%esi
f0103631:	09 d0                	or     %edx,%eax
f0103633:	89 f2                	mov    %esi,%edx
f0103635:	83 c4 1c             	add    $0x1c,%esp
f0103638:	5b                   	pop    %ebx
f0103639:	5e                   	pop    %esi
f010363a:	5f                   	pop    %edi
f010363b:	5d                   	pop    %ebp
f010363c:	c3                   	ret    
f010363d:	8d 76 00             	lea    0x0(%esi),%esi
f0103640:	29 f9                	sub    %edi,%ecx
f0103642:	19 d6                	sbb    %edx,%esi
f0103644:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103648:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010364c:	e9 18 ff ff ff       	jmp    f0103569 <__umoddi3+0x69>
