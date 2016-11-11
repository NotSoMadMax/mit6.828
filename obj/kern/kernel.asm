
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
f0100058:	e8 86 30 00 00       	call   f01030e3 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 96 04 00 00       	call   f01004f8 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 80 35 10 f0       	push   $0xf0103580
f010006f:	e8 b6 25 00 00       	call   f010262a <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 85 0f 00 00       	call   f0100ffe <mem_init>
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
f01000b0:	68 9b 35 10 f0       	push   $0xf010359b
f01000b5:	e8 70 25 00 00       	call   f010262a <cprintf>
	vcprintf(fmt, ap);
f01000ba:	83 c4 08             	add    $0x8,%esp
f01000bd:	53                   	push   %ebx
f01000be:	56                   	push   %esi
f01000bf:	e8 40 25 00 00       	call   f0102604 <vcprintf>
	cprintf("\n");
f01000c4:	c7 04 24 bc 44 10 f0 	movl   $0xf01044bc,(%esp)
f01000cb:	e8 5a 25 00 00       	call   f010262a <cprintf>
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
f01000f2:	68 b3 35 10 f0       	push   $0xf01035b3
f01000f7:	e8 2e 25 00 00       	call   f010262a <cprintf>
	vcprintf(fmt, ap);
f01000fc:	83 c4 08             	add    $0x8,%esp
f01000ff:	53                   	push   %ebx
f0100100:	ff 75 10             	pushl  0x10(%ebp)
f0100103:	e8 fc 24 00 00       	call   f0102604 <vcprintf>
	cprintf("\n");
f0100108:	c7 04 24 bc 44 10 f0 	movl   $0xf01044bc,(%esp)
f010010f:	e8 16 25 00 00       	call   f010262a <cprintf>
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
f01001ce:	0f b6 82 20 37 10 f0 	movzbl -0xfefc8e0(%edx),%eax
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
f010020a:	0f b6 82 20 37 10 f0 	movzbl -0xfefc8e0(%edx),%eax
f0100211:	0b 05 00 63 11 f0    	or     0xf0116300,%eax
f0100217:	0f b6 8a 20 36 10 f0 	movzbl -0xfefc9e0(%edx),%ecx
f010021e:	31 c8                	xor    %ecx,%eax
f0100220:	a3 00 63 11 f0       	mov    %eax,0xf0116300

	c = charcode[shift & (CTL | SHIFT)][data];
f0100225:	89 c1                	mov    %eax,%ecx
f0100227:	83 e1 03             	and    $0x3,%ecx
f010022a:	8b 0c 8d 00 36 10 f0 	mov    -0xfefca00(,%ecx,4),%ecx
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
f0100268:	68 cd 35 10 f0       	push   $0xf01035cd
f010026d:	e8 b8 23 00 00       	call   f010262a <cprintf>
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
f010041c:	e8 0f 2d 00 00       	call   f0103130 <memmove>
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
f01005eb:	68 d9 35 10 f0       	push   $0xf01035d9
f01005f0:	e8 35 20 00 00       	call   f010262a <cprintf>
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
f0100631:	68 20 38 10 f0       	push   $0xf0103820
f0100636:	68 3e 38 10 f0       	push   $0xf010383e
f010063b:	68 43 38 10 f0       	push   $0xf0103843
f0100640:	e8 e5 1f 00 00       	call   f010262a <cprintf>
f0100645:	83 c4 0c             	add    $0xc,%esp
f0100648:	68 cc 38 10 f0       	push   $0xf01038cc
f010064d:	68 4c 38 10 f0       	push   $0xf010384c
f0100652:	68 43 38 10 f0       	push   $0xf0103843
f0100657:	e8 ce 1f 00 00       	call   f010262a <cprintf>
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
f0100669:	68 55 38 10 f0       	push   $0xf0103855
f010066e:	e8 b7 1f 00 00       	call   f010262a <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100673:	83 c4 08             	add    $0x8,%esp
f0100676:	68 0c 00 10 00       	push   $0x10000c
f010067b:	68 f4 38 10 f0       	push   $0xf01038f4
f0100680:	e8 a5 1f 00 00       	call   f010262a <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100685:	83 c4 0c             	add    $0xc,%esp
f0100688:	68 0c 00 10 00       	push   $0x10000c
f010068d:	68 0c 00 10 f0       	push   $0xf010000c
f0100692:	68 1c 39 10 f0       	push   $0xf010391c
f0100697:	e8 8e 1f 00 00       	call   f010262a <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f010069c:	83 c4 0c             	add    $0xc,%esp
f010069f:	68 71 35 10 00       	push   $0x103571
f01006a4:	68 71 35 10 f0       	push   $0xf0103571
f01006a9:	68 40 39 10 f0       	push   $0xf0103940
f01006ae:	e8 77 1f 00 00       	call   f010262a <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006b3:	83 c4 0c             	add    $0xc,%esp
f01006b6:	68 00 63 11 00       	push   $0x116300
f01006bb:	68 00 63 11 f0       	push   $0xf0116300
f01006c0:	68 64 39 10 f0       	push   $0xf0103964
f01006c5:	e8 60 1f 00 00       	call   f010262a <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006ca:	83 c4 0c             	add    $0xc,%esp
f01006cd:	68 50 69 11 00       	push   $0x116950
f01006d2:	68 50 69 11 f0       	push   $0xf0116950
f01006d7:	68 88 39 10 f0       	push   $0xf0103988
f01006dc:	e8 49 1f 00 00       	call   f010262a <cprintf>
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
f0100702:	68 ac 39 10 f0       	push   $0xf01039ac
f0100707:	e8 1e 1f 00 00       	call   f010262a <cprintf>
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
f010071d:	68 6e 38 10 f0       	push   $0xf010386e
f0100722:	e8 03 1f 00 00       	call   f010262a <cprintf>
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
f0100742:	68 d8 39 10 f0       	push   $0xf01039d8
f0100747:	e8 de 1e 00 00       	call   f010262a <cprintf>
				*((uintptr_t *)ebp + 1), *((uintptr_t *)ebp + 2), *((uintptr_t *)ebp + 3), 
			    *((uintptr_t *)ebp + 4), *((uintptr_t *)ebp + 5), *((uintptr_t *)ebp + 6));
		debuginfo_eip(*((uintptr_t *)ebp + 1), &info);
f010074c:	83 c4 18             	add    $0x18,%esp
f010074f:	56                   	push   %esi
f0100750:	ff 73 04             	pushl  0x4(%ebx)
f0100753:	e8 dc 1f 00 00       	call   f0102734 <debuginfo_eip>
		cprintf("%s:%d: %.*s+%d\n", info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, 
f0100758:	83 c4 08             	add    $0x8,%esp
f010075b:	8b 43 04             	mov    0x4(%ebx),%eax
f010075e:	2b 45 f0             	sub    -0x10(%ebp),%eax
f0100761:	50                   	push   %eax
f0100762:	ff 75 e8             	pushl  -0x18(%ebp)
f0100765:	ff 75 ec             	pushl  -0x14(%ebp)
f0100768:	ff 75 e4             	pushl  -0x1c(%ebp)
f010076b:	ff 75 e0             	pushl  -0x20(%ebp)
f010076e:	68 80 38 10 f0       	push   $0xf0103880
f0100773:	e8 b2 1e 00 00       	call   f010262a <cprintf>
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
f0100796:	68 10 3a 10 f0       	push   $0xf0103a10
f010079b:	e8 8a 1e 00 00       	call   f010262a <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01007a0:	c7 04 24 34 3a 10 f0 	movl   $0xf0103a34,(%esp)
f01007a7:	e8 7e 1e 00 00       	call   f010262a <cprintf>
f01007ac:	83 c4 10             	add    $0x10,%esp

	while (1) {
		buf = readline("K> ");
f01007af:	83 ec 0c             	sub    $0xc,%esp
f01007b2:	68 90 38 10 f0       	push   $0xf0103890
f01007b7:	e8 d0 26 00 00       	call   f0102e8c <readline>
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
f01007eb:	68 94 38 10 f0       	push   $0xf0103894
f01007f0:	e8 b1 28 00 00       	call   f01030a6 <strchr>
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
f010080b:	68 99 38 10 f0       	push   $0xf0103899
f0100810:	e8 15 1e 00 00       	call   f010262a <cprintf>
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
f0100834:	68 94 38 10 f0       	push   $0xf0103894
f0100839:	e8 68 28 00 00       	call   f01030a6 <strchr>
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
f010085a:	68 3e 38 10 f0       	push   $0xf010383e
f010085f:	ff 75 a8             	pushl  -0x58(%ebp)
f0100862:	e8 e1 27 00 00       	call   f0103048 <strcmp>
f0100867:	83 c4 10             	add    $0x10,%esp
f010086a:	85 c0                	test   %eax,%eax
f010086c:	74 1e                	je     f010088c <monitor+0xff>
f010086e:	83 ec 08             	sub    $0x8,%esp
f0100871:	68 4c 38 10 f0       	push   $0xf010384c
f0100876:	ff 75 a8             	pushl  -0x58(%ebp)
f0100879:	e8 ca 27 00 00       	call   f0103048 <strcmp>
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
f01008a1:	ff 14 85 64 3a 10 f0 	call   *-0xfefc59c(,%eax,4)
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
f01008ba:	68 b6 38 10 f0       	push   $0xf01038b6
f01008bf:	e8 66 1d 00 00       	call   f010262a <cprintf>
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
f01008df:	e8 df 1c 00 00       	call   f01025c3 <mc146818_read>
f01008e4:	89 c6                	mov    %eax,%esi
f01008e6:	83 c3 01             	add    $0x1,%ebx
f01008e9:	89 1c 24             	mov    %ebx,(%esp)
f01008ec:	e8 d2 1c 00 00       	call   f01025c3 <mc146818_read>
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
f0100922:	68 74 3a 10 f0       	push   $0xf0103a74
f0100927:	68 cf 02 00 00       	push   $0x2cf
f010092c:	68 fc 41 10 f0       	push   $0xf01041fc
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
f0100993:	68 98 3a 10 f0       	push   $0xf0103a98
f0100998:	6a 6b                	push   $0x6b
f010099a:	68 fc 41 10 f0       	push   $0xf01041fc
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
f01009be:	68 08 42 10 f0       	push   $0xf0104208
f01009c3:	6a 6c                	push   $0x6c
f01009c5:	68 fc 41 10 f0       	push   $0xf01041fc
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
f0100a01:	68 bc 3a 10 f0       	push   $0xf0103abc
f0100a06:	68 12 02 00 00       	push   $0x212
f0100a0b:	68 fc 41 10 f0       	push   $0xf01041fc
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
f0100a90:	68 74 3a 10 f0       	push   $0xf0103a74
f0100a95:	6a 52                	push   $0x52
f0100a97:	68 17 42 10 f0       	push   $0xf0104217
f0100a9c:	e8 ea f5 ff ff       	call   f010008b <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100aa1:	83 ec 04             	sub    $0x4,%esp
f0100aa4:	68 80 00 00 00       	push   $0x80
f0100aa9:	68 97 00 00 00       	push   $0x97
f0100aae:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100ab3:	50                   	push   %eax
f0100ab4:	e8 2a 26 00 00       	call   f01030e3 <memset>
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
f0100afa:	68 25 42 10 f0       	push   $0xf0104225
f0100aff:	68 31 42 10 f0       	push   $0xf0104231
f0100b04:	68 2c 02 00 00       	push   $0x22c
f0100b09:	68 fc 41 10 f0       	push   $0xf01041fc
f0100b0e:	e8 78 f5 ff ff       	call   f010008b <_panic>
		assert(pp < pages + npages);
f0100b13:	39 fa                	cmp    %edi,%edx
f0100b15:	72 19                	jb     f0100b30 <check_page_free_list+0x148>
f0100b17:	68 46 42 10 f0       	push   $0xf0104246
f0100b1c:	68 31 42 10 f0       	push   $0xf0104231
f0100b21:	68 2d 02 00 00       	push   $0x22d
f0100b26:	68 fc 41 10 f0       	push   $0xf01041fc
f0100b2b:	e8 5b f5 ff ff       	call   f010008b <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100b30:	89 d0                	mov    %edx,%eax
f0100b32:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100b35:	a8 07                	test   $0x7,%al
f0100b37:	74 19                	je     f0100b52 <check_page_free_list+0x16a>
f0100b39:	68 e0 3a 10 f0       	push   $0xf0103ae0
f0100b3e:	68 31 42 10 f0       	push   $0xf0104231
f0100b43:	68 2e 02 00 00       	push   $0x22e
f0100b48:	68 fc 41 10 f0       	push   $0xf01041fc
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
f0100b5c:	68 5a 42 10 f0       	push   $0xf010425a
f0100b61:	68 31 42 10 f0       	push   $0xf0104231
f0100b66:	68 31 02 00 00       	push   $0x231
f0100b6b:	68 fc 41 10 f0       	push   $0xf01041fc
f0100b70:	e8 16 f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100b75:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100b7a:	75 19                	jne    f0100b95 <check_page_free_list+0x1ad>
f0100b7c:	68 6b 42 10 f0       	push   $0xf010426b
f0100b81:	68 31 42 10 f0       	push   $0xf0104231
f0100b86:	68 32 02 00 00       	push   $0x232
f0100b8b:	68 fc 41 10 f0       	push   $0xf01041fc
f0100b90:	e8 f6 f4 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100b95:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100b9a:	75 19                	jne    f0100bb5 <check_page_free_list+0x1cd>
f0100b9c:	68 14 3b 10 f0       	push   $0xf0103b14
f0100ba1:	68 31 42 10 f0       	push   $0xf0104231
f0100ba6:	68 33 02 00 00       	push   $0x233
f0100bab:	68 fc 41 10 f0       	push   $0xf01041fc
f0100bb0:	e8 d6 f4 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100bb5:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100bba:	75 19                	jne    f0100bd5 <check_page_free_list+0x1ed>
f0100bbc:	68 84 42 10 f0       	push   $0xf0104284
f0100bc1:	68 31 42 10 f0       	push   $0xf0104231
f0100bc6:	68 34 02 00 00       	push   $0x234
f0100bcb:	68 fc 41 10 f0       	push   $0xf01041fc
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
f0100be7:	68 74 3a 10 f0       	push   $0xf0103a74
f0100bec:	6a 52                	push   $0x52
f0100bee:	68 17 42 10 f0       	push   $0xf0104217
f0100bf3:	e8 93 f4 ff ff       	call   f010008b <_panic>
f0100bf8:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100bfd:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100c00:	76 1e                	jbe    f0100c20 <check_page_free_list+0x238>
f0100c02:	68 38 3b 10 f0       	push   $0xf0103b38
f0100c07:	68 31 42 10 f0       	push   $0xf0104231
f0100c0c:	68 35 02 00 00       	push   $0x235
f0100c11:	68 fc 41 10 f0       	push   $0xf01041fc
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
f0100c35:	68 9e 42 10 f0       	push   $0xf010429e
f0100c3a:	68 31 42 10 f0       	push   $0xf0104231
f0100c3f:	68 3d 02 00 00       	push   $0x23d
f0100c44:	68 fc 41 10 f0       	push   $0xf01041fc
f0100c49:	e8 3d f4 ff ff       	call   f010008b <_panic>
	assert(nfree_extmem > 0);
f0100c4e:	85 db                	test   %ebx,%ebx
f0100c50:	7f 42                	jg     f0100c94 <check_page_free_list+0x2ac>
f0100c52:	68 b0 42 10 f0       	push   $0xf01042b0
f0100c57:	68 31 42 10 f0       	push   $0xf0104231
f0100c5c:	68 3e 02 00 00       	push   $0x23e
f0100c61:	68 fc 41 10 f0       	push   $0xf01041fc
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
f0100d17:	68 98 3a 10 f0       	push   $0xf0103a98
f0100d1c:	68 11 01 00 00       	push   $0x111
f0100d21:	68 fc 41 10 f0       	push   $0xf01041fc
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
f0100dcf:	68 74 3a 10 f0       	push   $0xf0103a74
f0100dd4:	6a 52                	push   $0x52
f0100dd6:	68 17 42 10 f0       	push   $0xf0104217
f0100ddb:	e8 ab f2 ff ff       	call   f010008b <_panic>
			memset(page2kva(p), 0, PGSIZE);
f0100de0:	83 ec 04             	sub    $0x4,%esp
f0100de3:	68 00 10 00 00       	push   $0x1000
f0100de8:	6a 00                	push   $0x0
f0100dea:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100def:	50                   	push   %eax
f0100df0:	e8 ee 22 00 00       	call   f01030e3 <memset>
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
f0100e1e:	68 80 3b 10 f0       	push   $0xf0103b80
f0100e23:	68 44 01 00 00       	push   $0x144
f0100e28:	68 fc 41 10 f0       	push   $0xf01041fc
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
f0100ec4:	68 74 3a 10 f0       	push   $0xf0103a74
f0100ec9:	68 7b 01 00 00       	push   $0x17b
f0100ece:	68 fc 41 10 f0       	push   $0xf01041fc
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

f0100efd <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0100efd:	55                   	push   %ebp
f0100efe:	89 e5                	mov    %esp,%ebp
f0100f00:	53                   	push   %ebx
f0100f01:	83 ec 08             	sub    $0x8,%esp
f0100f04:	8b 5d 10             	mov    0x10(%ebp),%ebx
	pte_t *pte = pgdir_walk(pgdir, va, 0);
f0100f07:	6a 00                	push   $0x0
f0100f09:	ff 75 0c             	pushl  0xc(%ebp)
f0100f0c:	ff 75 08             	pushl  0x8(%ebp)
f0100f0f:	e8 54 ff ff ff       	call   f0100e68 <pgdir_walk>
	if(pte == NULL)
f0100f14:	83 c4 10             	add    $0x10,%esp
f0100f17:	85 c0                	test   %eax,%eax
f0100f19:	74 32                	je     f0100f4d <page_lookup+0x50>
		return NULL;
	else{
		if(pte_store!=NULL)		
f0100f1b:	85 db                	test   %ebx,%ebx
f0100f1d:	74 02                	je     f0100f21 <page_lookup+0x24>
			*pte_store = pte;
f0100f1f:	89 03                	mov    %eax,(%ebx)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100f21:	8b 00                	mov    (%eax),%eax
f0100f23:	c1 e8 0c             	shr    $0xc,%eax
f0100f26:	3b 05 44 69 11 f0    	cmp    0xf0116944,%eax
f0100f2c:	72 14                	jb     f0100f42 <page_lookup+0x45>
		panic("pa2page called with invalid pa");
f0100f2e:	83 ec 04             	sub    $0x4,%esp
f0100f31:	68 b4 3b 10 f0       	push   $0xf0103bb4
f0100f36:	6a 4b                	push   $0x4b
f0100f38:	68 17 42 10 f0       	push   $0xf0104217
f0100f3d:	e8 49 f1 ff ff       	call   f010008b <_panic>
	return &pages[PGNUM(pa)];
f0100f42:	8b 15 4c 69 11 f0    	mov    0xf011694c,%edx
f0100f48:	8d 04 c2             	lea    (%edx,%eax,8),%eax
		
		return pa2page(PTE_ADDR(*pte));
f0100f4b:	eb 05                	jmp    f0100f52 <page_lookup+0x55>
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
	pte_t *pte = pgdir_walk(pgdir, va, 0);
	if(pte == NULL)
		return NULL;
f0100f4d:	b8 00 00 00 00       	mov    $0x0,%eax
			*pte_store = pte;
		
		return pa2page(PTE_ADDR(*pte));
	}

}
f0100f52:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100f55:	c9                   	leave  
f0100f56:	c3                   	ret    

f0100f57 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0100f57:	55                   	push   %ebp
f0100f58:	89 e5                	mov    %esp,%ebp
f0100f5a:	53                   	push   %ebx
f0100f5b:	83 ec 18             	sub    $0x18,%esp
f0100f5e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
	pte_t *pte;
	struct PageInfo *pp = page_lookup(pgdir, va, &pte);
f0100f61:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100f64:	50                   	push   %eax
f0100f65:	53                   	push   %ebx
f0100f66:	ff 75 08             	pushl  0x8(%ebp)
f0100f69:	e8 8f ff ff ff       	call   f0100efd <page_lookup>
	if(pp!=NULL){
f0100f6e:	83 c4 10             	add    $0x10,%esp
f0100f71:	85 c0                	test   %eax,%eax
f0100f73:	74 18                	je     f0100f8d <page_remove+0x36>
		page_decref(pp);
f0100f75:	83 ec 0c             	sub    $0xc,%esp
f0100f78:	50                   	push   %eax
f0100f79:	e8 c3 fe ff ff       	call   f0100e41 <page_decref>
		*pte = 0;
f0100f7e:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100f81:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0100f87:	0f 01 3b             	invlpg (%ebx)
f0100f8a:	83 c4 10             	add    $0x10,%esp
		tlb_invalidate(pgdir, va);
	}
}
f0100f8d:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100f90:	c9                   	leave  
f0100f91:	c3                   	ret    

f0100f92 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f0100f92:	55                   	push   %ebp
f0100f93:	89 e5                	mov    %esp,%ebp
f0100f95:	57                   	push   %edi
f0100f96:	56                   	push   %esi
f0100f97:	53                   	push   %ebx
f0100f98:	83 ec 10             	sub    $0x10,%esp
f0100f9b:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100f9e:	8b 7d 10             	mov    0x10(%ebp),%edi
	pte_t *pte = pgdir_walk(pgdir, va, 1); 
f0100fa1:	6a 01                	push   $0x1
f0100fa3:	57                   	push   %edi
f0100fa4:	ff 75 08             	pushl  0x8(%ebp)
f0100fa7:	e8 bc fe ff ff       	call   f0100e68 <pgdir_walk>
	if(pte){
f0100fac:	83 c4 10             	add    $0x10,%esp
f0100faf:	85 c0                	test   %eax,%eax
f0100fb1:	74 3e                	je     f0100ff1 <page_insert+0x5f>
f0100fb3:	89 c6                	mov    %eax,%esi
		pp->pp_ref ++;
f0100fb5:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
		if(PTE_ADDR(*pte))
f0100fba:	f7 00 00 f0 ff ff    	testl  $0xfffff000,(%eax)
f0100fc0:	74 0f                	je     f0100fd1 <page_insert+0x3f>
			page_remove(pgdir, va);
f0100fc2:	83 ec 08             	sub    $0x8,%esp
f0100fc5:	57                   	push   %edi
f0100fc6:	ff 75 08             	pushl  0x8(%ebp)
f0100fc9:	e8 89 ff ff ff       	call   f0100f57 <page_remove>
f0100fce:	83 c4 10             	add    $0x10,%esp
		*pte = page2pa(pp) | perm |PTE_P;
f0100fd1:	2b 1d 4c 69 11 f0    	sub    0xf011694c,%ebx
f0100fd7:	c1 fb 03             	sar    $0x3,%ebx
f0100fda:	c1 e3 0c             	shl    $0xc,%ebx
f0100fdd:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fe0:	83 c8 01             	or     $0x1,%eax
f0100fe3:	09 c3                	or     %eax,%ebx
f0100fe5:	89 1e                	mov    %ebx,(%esi)
f0100fe7:	0f 01 3f             	invlpg (%edi)
		tlb_invalidate(pgdir, va);
		return 0;
f0100fea:	b8 00 00 00 00       	mov    $0x0,%eax
f0100fef:	eb 05                	jmp    f0100ff6 <page_insert+0x64>
	}
	return -E_NO_MEM;
f0100ff1:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	
}
f0100ff6:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100ff9:	5b                   	pop    %ebx
f0100ffa:	5e                   	pop    %esi
f0100ffb:	5f                   	pop    %edi
f0100ffc:	5d                   	pop    %ebp
f0100ffd:	c3                   	ret    

f0100ffe <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0100ffe:	55                   	push   %ebp
f0100fff:	89 e5                	mov    %esp,%ebp
f0101001:	57                   	push   %edi
f0101002:	56                   	push   %esi
f0101003:	53                   	push   %ebx
f0101004:	83 ec 2c             	sub    $0x2c,%esp
{
	size_t basemem, extmem, ext16mem, totalmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	basemem = nvram_read(NVRAM_BASELO);
f0101007:	b8 15 00 00 00       	mov    $0x15,%eax
f010100c:	e8 c3 f8 ff ff       	call   f01008d4 <nvram_read>
f0101011:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f0101013:	b8 17 00 00 00       	mov    $0x17,%eax
f0101018:	e8 b7 f8 ff ff       	call   f01008d4 <nvram_read>
f010101d:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f010101f:	b8 34 00 00 00       	mov    $0x34,%eax
f0101024:	e8 ab f8 ff ff       	call   f01008d4 <nvram_read>
f0101029:	c1 e0 06             	shl    $0x6,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (ext16mem)
f010102c:	85 c0                	test   %eax,%eax
f010102e:	74 07                	je     f0101037 <mem_init+0x39>
		totalmem = 16 * 1024 + ext16mem;
f0101030:	05 00 40 00 00       	add    $0x4000,%eax
f0101035:	eb 0b                	jmp    f0101042 <mem_init+0x44>
	else if (extmem)
		totalmem = 1 * 1024 + extmem;
f0101037:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f010103d:	85 f6                	test   %esi,%esi
f010103f:	0f 44 c3             	cmove  %ebx,%eax
	else
		totalmem = basemem;

	npages = totalmem / (PGSIZE / 1024);
f0101042:	89 c2                	mov    %eax,%edx
f0101044:	c1 ea 02             	shr    $0x2,%edx
f0101047:	89 15 44 69 11 f0    	mov    %edx,0xf0116944
	npages_basemem = basemem / (PGSIZE / 1024);

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f010104d:	89 c2                	mov    %eax,%edx
f010104f:	29 da                	sub    %ebx,%edx
f0101051:	52                   	push   %edx
f0101052:	53                   	push   %ebx
f0101053:	50                   	push   %eax
f0101054:	68 d4 3b 10 f0       	push   $0xf0103bd4
f0101059:	e8 cc 15 00 00       	call   f010262a <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f010105e:	b8 00 10 00 00       	mov    $0x1000,%eax
f0101063:	e8 f9 f8 ff ff       	call   f0100961 <boot_alloc>
f0101068:	a3 48 69 11 f0       	mov    %eax,0xf0116948
	memset(kern_pgdir, 0, PGSIZE);
f010106d:	83 c4 0c             	add    $0xc,%esp
f0101070:	68 00 10 00 00       	push   $0x1000
f0101075:	6a 00                	push   $0x0
f0101077:	50                   	push   %eax
f0101078:	e8 66 20 00 00       	call   f01030e3 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f010107d:	a1 48 69 11 f0       	mov    0xf0116948,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0101082:	83 c4 10             	add    $0x10,%esp
f0101085:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010108a:	77 15                	ja     f01010a1 <mem_init+0xa3>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010108c:	50                   	push   %eax
f010108d:	68 98 3a 10 f0       	push   $0xf0103a98
f0101092:	68 93 00 00 00       	push   $0x93
f0101097:	68 fc 41 10 f0       	push   $0xf01041fc
f010109c:	e8 ea ef ff ff       	call   f010008b <_panic>
f01010a1:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01010a7:	83 ca 05             	or     $0x5,%edx
f01010aa:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	pages = (struct PageInfo *) boot_alloc(npages * sizeof(struct PageInfo));
f01010b0:	a1 44 69 11 f0       	mov    0xf0116944,%eax
f01010b5:	c1 e0 03             	shl    $0x3,%eax
f01010b8:	e8 a4 f8 ff ff       	call   f0100961 <boot_alloc>
f01010bd:	a3 4c 69 11 f0       	mov    %eax,0xf011694c
	memset(pages, 0, npages * sizeof(struct PageInfo));
f01010c2:	83 ec 04             	sub    $0x4,%esp
f01010c5:	8b 0d 44 69 11 f0    	mov    0xf0116944,%ecx
f01010cb:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f01010d2:	52                   	push   %edx
f01010d3:	6a 00                	push   $0x0
f01010d5:	50                   	push   %eax
f01010d6:	e8 08 20 00 00       	call   f01030e3 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f01010db:	e8 bc fb ff ff       	call   f0100c9c <page_init>

	check_page_free_list(1);
f01010e0:	b8 01 00 00 00       	mov    $0x1,%eax
f01010e5:	e8 fe f8 ff ff       	call   f01009e8 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f01010ea:	83 c4 10             	add    $0x10,%esp
f01010ed:	83 3d 4c 69 11 f0 00 	cmpl   $0x0,0xf011694c
f01010f4:	75 17                	jne    f010110d <mem_init+0x10f>
		panic("'pages' is a null pointer!");
f01010f6:	83 ec 04             	sub    $0x4,%esp
f01010f9:	68 c1 42 10 f0       	push   $0xf01042c1
f01010fe:	68 4f 02 00 00       	push   $0x24f
f0101103:	68 fc 41 10 f0       	push   $0xf01041fc
f0101108:	e8 7e ef ff ff       	call   f010008b <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010110d:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f0101112:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101117:	eb 05                	jmp    f010111e <mem_init+0x120>
		++nfree;
f0101119:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010111c:	8b 00                	mov    (%eax),%eax
f010111e:	85 c0                	test   %eax,%eax
f0101120:	75 f7                	jne    f0101119 <mem_init+0x11b>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101122:	83 ec 0c             	sub    $0xc,%esp
f0101125:	6a 00                	push   $0x0
f0101127:	e8 63 fc ff ff       	call   f0100d8f <page_alloc>
f010112c:	89 c7                	mov    %eax,%edi
f010112e:	83 c4 10             	add    $0x10,%esp
f0101131:	85 c0                	test   %eax,%eax
f0101133:	75 19                	jne    f010114e <mem_init+0x150>
f0101135:	68 dc 42 10 f0       	push   $0xf01042dc
f010113a:	68 31 42 10 f0       	push   $0xf0104231
f010113f:	68 57 02 00 00       	push   $0x257
f0101144:	68 fc 41 10 f0       	push   $0xf01041fc
f0101149:	e8 3d ef ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f010114e:	83 ec 0c             	sub    $0xc,%esp
f0101151:	6a 00                	push   $0x0
f0101153:	e8 37 fc ff ff       	call   f0100d8f <page_alloc>
f0101158:	89 c6                	mov    %eax,%esi
f010115a:	83 c4 10             	add    $0x10,%esp
f010115d:	85 c0                	test   %eax,%eax
f010115f:	75 19                	jne    f010117a <mem_init+0x17c>
f0101161:	68 f2 42 10 f0       	push   $0xf01042f2
f0101166:	68 31 42 10 f0       	push   $0xf0104231
f010116b:	68 58 02 00 00       	push   $0x258
f0101170:	68 fc 41 10 f0       	push   $0xf01041fc
f0101175:	e8 11 ef ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f010117a:	83 ec 0c             	sub    $0xc,%esp
f010117d:	6a 00                	push   $0x0
f010117f:	e8 0b fc ff ff       	call   f0100d8f <page_alloc>
f0101184:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101187:	83 c4 10             	add    $0x10,%esp
f010118a:	85 c0                	test   %eax,%eax
f010118c:	75 19                	jne    f01011a7 <mem_init+0x1a9>
f010118e:	68 08 43 10 f0       	push   $0xf0104308
f0101193:	68 31 42 10 f0       	push   $0xf0104231
f0101198:	68 59 02 00 00       	push   $0x259
f010119d:	68 fc 41 10 f0       	push   $0xf01041fc
f01011a2:	e8 e4 ee ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01011a7:	39 f7                	cmp    %esi,%edi
f01011a9:	75 19                	jne    f01011c4 <mem_init+0x1c6>
f01011ab:	68 1e 43 10 f0       	push   $0xf010431e
f01011b0:	68 31 42 10 f0       	push   $0xf0104231
f01011b5:	68 5c 02 00 00       	push   $0x25c
f01011ba:	68 fc 41 10 f0       	push   $0xf01041fc
f01011bf:	e8 c7 ee ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01011c4:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01011c7:	39 c6                	cmp    %eax,%esi
f01011c9:	74 04                	je     f01011cf <mem_init+0x1d1>
f01011cb:	39 c7                	cmp    %eax,%edi
f01011cd:	75 19                	jne    f01011e8 <mem_init+0x1ea>
f01011cf:	68 10 3c 10 f0       	push   $0xf0103c10
f01011d4:	68 31 42 10 f0       	push   $0xf0104231
f01011d9:	68 5d 02 00 00       	push   $0x25d
f01011de:	68 fc 41 10 f0       	push   $0xf01041fc
f01011e3:	e8 a3 ee ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01011e8:	8b 0d 4c 69 11 f0    	mov    0xf011694c,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f01011ee:	8b 15 44 69 11 f0    	mov    0xf0116944,%edx
f01011f4:	c1 e2 0c             	shl    $0xc,%edx
f01011f7:	89 f8                	mov    %edi,%eax
f01011f9:	29 c8                	sub    %ecx,%eax
f01011fb:	c1 f8 03             	sar    $0x3,%eax
f01011fe:	c1 e0 0c             	shl    $0xc,%eax
f0101201:	39 d0                	cmp    %edx,%eax
f0101203:	72 19                	jb     f010121e <mem_init+0x220>
f0101205:	68 30 43 10 f0       	push   $0xf0104330
f010120a:	68 31 42 10 f0       	push   $0xf0104231
f010120f:	68 5e 02 00 00       	push   $0x25e
f0101214:	68 fc 41 10 f0       	push   $0xf01041fc
f0101219:	e8 6d ee ff ff       	call   f010008b <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f010121e:	89 f0                	mov    %esi,%eax
f0101220:	29 c8                	sub    %ecx,%eax
f0101222:	c1 f8 03             	sar    $0x3,%eax
f0101225:	c1 e0 0c             	shl    $0xc,%eax
f0101228:	39 c2                	cmp    %eax,%edx
f010122a:	77 19                	ja     f0101245 <mem_init+0x247>
f010122c:	68 4d 43 10 f0       	push   $0xf010434d
f0101231:	68 31 42 10 f0       	push   $0xf0104231
f0101236:	68 5f 02 00 00       	push   $0x25f
f010123b:	68 fc 41 10 f0       	push   $0xf01041fc
f0101240:	e8 46 ee ff ff       	call   f010008b <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f0101245:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101248:	29 c8                	sub    %ecx,%eax
f010124a:	c1 f8 03             	sar    $0x3,%eax
f010124d:	c1 e0 0c             	shl    $0xc,%eax
f0101250:	39 c2                	cmp    %eax,%edx
f0101252:	77 19                	ja     f010126d <mem_init+0x26f>
f0101254:	68 6a 43 10 f0       	push   $0xf010436a
f0101259:	68 31 42 10 f0       	push   $0xf0104231
f010125e:	68 60 02 00 00       	push   $0x260
f0101263:	68 fc 41 10 f0       	push   $0xf01041fc
f0101268:	e8 1e ee ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f010126d:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f0101272:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101275:	c7 05 3c 65 11 f0 00 	movl   $0x0,0xf011653c
f010127c:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f010127f:	83 ec 0c             	sub    $0xc,%esp
f0101282:	6a 00                	push   $0x0
f0101284:	e8 06 fb ff ff       	call   f0100d8f <page_alloc>
f0101289:	83 c4 10             	add    $0x10,%esp
f010128c:	85 c0                	test   %eax,%eax
f010128e:	74 19                	je     f01012a9 <mem_init+0x2ab>
f0101290:	68 87 43 10 f0       	push   $0xf0104387
f0101295:	68 31 42 10 f0       	push   $0xf0104231
f010129a:	68 67 02 00 00       	push   $0x267
f010129f:	68 fc 41 10 f0       	push   $0xf01041fc
f01012a4:	e8 e2 ed ff ff       	call   f010008b <_panic>

	// free and re-allocate?
	page_free(pp0);
f01012a9:	83 ec 0c             	sub    $0xc,%esp
f01012ac:	57                   	push   %edi
f01012ad:	e8 54 fb ff ff       	call   f0100e06 <page_free>
	page_free(pp1);
f01012b2:	89 34 24             	mov    %esi,(%esp)
f01012b5:	e8 4c fb ff ff       	call   f0100e06 <page_free>
	page_free(pp2);
f01012ba:	83 c4 04             	add    $0x4,%esp
f01012bd:	ff 75 d4             	pushl  -0x2c(%ebp)
f01012c0:	e8 41 fb ff ff       	call   f0100e06 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01012c5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01012cc:	e8 be fa ff ff       	call   f0100d8f <page_alloc>
f01012d1:	89 c6                	mov    %eax,%esi
f01012d3:	83 c4 10             	add    $0x10,%esp
f01012d6:	85 c0                	test   %eax,%eax
f01012d8:	75 19                	jne    f01012f3 <mem_init+0x2f5>
f01012da:	68 dc 42 10 f0       	push   $0xf01042dc
f01012df:	68 31 42 10 f0       	push   $0xf0104231
f01012e4:	68 6e 02 00 00       	push   $0x26e
f01012e9:	68 fc 41 10 f0       	push   $0xf01041fc
f01012ee:	e8 98 ed ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f01012f3:	83 ec 0c             	sub    $0xc,%esp
f01012f6:	6a 00                	push   $0x0
f01012f8:	e8 92 fa ff ff       	call   f0100d8f <page_alloc>
f01012fd:	89 c7                	mov    %eax,%edi
f01012ff:	83 c4 10             	add    $0x10,%esp
f0101302:	85 c0                	test   %eax,%eax
f0101304:	75 19                	jne    f010131f <mem_init+0x321>
f0101306:	68 f2 42 10 f0       	push   $0xf01042f2
f010130b:	68 31 42 10 f0       	push   $0xf0104231
f0101310:	68 6f 02 00 00       	push   $0x26f
f0101315:	68 fc 41 10 f0       	push   $0xf01041fc
f010131a:	e8 6c ed ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f010131f:	83 ec 0c             	sub    $0xc,%esp
f0101322:	6a 00                	push   $0x0
f0101324:	e8 66 fa ff ff       	call   f0100d8f <page_alloc>
f0101329:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010132c:	83 c4 10             	add    $0x10,%esp
f010132f:	85 c0                	test   %eax,%eax
f0101331:	75 19                	jne    f010134c <mem_init+0x34e>
f0101333:	68 08 43 10 f0       	push   $0xf0104308
f0101338:	68 31 42 10 f0       	push   $0xf0104231
f010133d:	68 70 02 00 00       	push   $0x270
f0101342:	68 fc 41 10 f0       	push   $0xf01041fc
f0101347:	e8 3f ed ff ff       	call   f010008b <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010134c:	39 fe                	cmp    %edi,%esi
f010134e:	75 19                	jne    f0101369 <mem_init+0x36b>
f0101350:	68 1e 43 10 f0       	push   $0xf010431e
f0101355:	68 31 42 10 f0       	push   $0xf0104231
f010135a:	68 72 02 00 00       	push   $0x272
f010135f:	68 fc 41 10 f0       	push   $0xf01041fc
f0101364:	e8 22 ed ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101369:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010136c:	39 c6                	cmp    %eax,%esi
f010136e:	74 04                	je     f0101374 <mem_init+0x376>
f0101370:	39 c7                	cmp    %eax,%edi
f0101372:	75 19                	jne    f010138d <mem_init+0x38f>
f0101374:	68 10 3c 10 f0       	push   $0xf0103c10
f0101379:	68 31 42 10 f0       	push   $0xf0104231
f010137e:	68 73 02 00 00       	push   $0x273
f0101383:	68 fc 41 10 f0       	push   $0xf01041fc
f0101388:	e8 fe ec ff ff       	call   f010008b <_panic>
	assert(!page_alloc(0));
f010138d:	83 ec 0c             	sub    $0xc,%esp
f0101390:	6a 00                	push   $0x0
f0101392:	e8 f8 f9 ff ff       	call   f0100d8f <page_alloc>
f0101397:	83 c4 10             	add    $0x10,%esp
f010139a:	85 c0                	test   %eax,%eax
f010139c:	74 19                	je     f01013b7 <mem_init+0x3b9>
f010139e:	68 87 43 10 f0       	push   $0xf0104387
f01013a3:	68 31 42 10 f0       	push   $0xf0104231
f01013a8:	68 74 02 00 00       	push   $0x274
f01013ad:	68 fc 41 10 f0       	push   $0xf01041fc
f01013b2:	e8 d4 ec ff ff       	call   f010008b <_panic>
f01013b7:	89 f0                	mov    %esi,%eax
f01013b9:	2b 05 4c 69 11 f0    	sub    0xf011694c,%eax
f01013bf:	c1 f8 03             	sar    $0x3,%eax
f01013c2:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01013c5:	89 c2                	mov    %eax,%edx
f01013c7:	c1 ea 0c             	shr    $0xc,%edx
f01013ca:	3b 15 44 69 11 f0    	cmp    0xf0116944,%edx
f01013d0:	72 12                	jb     f01013e4 <mem_init+0x3e6>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01013d2:	50                   	push   %eax
f01013d3:	68 74 3a 10 f0       	push   $0xf0103a74
f01013d8:	6a 52                	push   $0x52
f01013da:	68 17 42 10 f0       	push   $0xf0104217
f01013df:	e8 a7 ec ff ff       	call   f010008b <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f01013e4:	83 ec 04             	sub    $0x4,%esp
f01013e7:	68 00 10 00 00       	push   $0x1000
f01013ec:	6a 01                	push   $0x1
f01013ee:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01013f3:	50                   	push   %eax
f01013f4:	e8 ea 1c 00 00       	call   f01030e3 <memset>
	page_free(pp0);
f01013f9:	89 34 24             	mov    %esi,(%esp)
f01013fc:	e8 05 fa ff ff       	call   f0100e06 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101401:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101408:	e8 82 f9 ff ff       	call   f0100d8f <page_alloc>
f010140d:	83 c4 10             	add    $0x10,%esp
f0101410:	85 c0                	test   %eax,%eax
f0101412:	75 19                	jne    f010142d <mem_init+0x42f>
f0101414:	68 96 43 10 f0       	push   $0xf0104396
f0101419:	68 31 42 10 f0       	push   $0xf0104231
f010141e:	68 79 02 00 00       	push   $0x279
f0101423:	68 fc 41 10 f0       	push   $0xf01041fc
f0101428:	e8 5e ec ff ff       	call   f010008b <_panic>
	assert(pp && pp0 == pp);
f010142d:	39 c6                	cmp    %eax,%esi
f010142f:	74 19                	je     f010144a <mem_init+0x44c>
f0101431:	68 b4 43 10 f0       	push   $0xf01043b4
f0101436:	68 31 42 10 f0       	push   $0xf0104231
f010143b:	68 7a 02 00 00       	push   $0x27a
f0101440:	68 fc 41 10 f0       	push   $0xf01041fc
f0101445:	e8 41 ec ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010144a:	89 f0                	mov    %esi,%eax
f010144c:	2b 05 4c 69 11 f0    	sub    0xf011694c,%eax
f0101452:	c1 f8 03             	sar    $0x3,%eax
f0101455:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101458:	89 c2                	mov    %eax,%edx
f010145a:	c1 ea 0c             	shr    $0xc,%edx
f010145d:	3b 15 44 69 11 f0    	cmp    0xf0116944,%edx
f0101463:	72 12                	jb     f0101477 <mem_init+0x479>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101465:	50                   	push   %eax
f0101466:	68 74 3a 10 f0       	push   $0xf0103a74
f010146b:	6a 52                	push   $0x52
f010146d:	68 17 42 10 f0       	push   $0xf0104217
f0101472:	e8 14 ec ff ff       	call   f010008b <_panic>
f0101477:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f010147d:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f0101483:	80 38 00             	cmpb   $0x0,(%eax)
f0101486:	74 19                	je     f01014a1 <mem_init+0x4a3>
f0101488:	68 c4 43 10 f0       	push   $0xf01043c4
f010148d:	68 31 42 10 f0       	push   $0xf0104231
f0101492:	68 7d 02 00 00       	push   $0x27d
f0101497:	68 fc 41 10 f0       	push   $0xf01041fc
f010149c:	e8 ea eb ff ff       	call   f010008b <_panic>
f01014a1:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f01014a4:	39 d0                	cmp    %edx,%eax
f01014a6:	75 db                	jne    f0101483 <mem_init+0x485>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f01014a8:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01014ab:	a3 3c 65 11 f0       	mov    %eax,0xf011653c

	// free the pages we took
	page_free(pp0);
f01014b0:	83 ec 0c             	sub    $0xc,%esp
f01014b3:	56                   	push   %esi
f01014b4:	e8 4d f9 ff ff       	call   f0100e06 <page_free>
	page_free(pp1);
f01014b9:	89 3c 24             	mov    %edi,(%esp)
f01014bc:	e8 45 f9 ff ff       	call   f0100e06 <page_free>
	page_free(pp2);
f01014c1:	83 c4 04             	add    $0x4,%esp
f01014c4:	ff 75 d4             	pushl  -0x2c(%ebp)
f01014c7:	e8 3a f9 ff ff       	call   f0100e06 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01014cc:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f01014d1:	83 c4 10             	add    $0x10,%esp
f01014d4:	eb 05                	jmp    f01014db <mem_init+0x4dd>
		--nfree;
f01014d6:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01014d9:	8b 00                	mov    (%eax),%eax
f01014db:	85 c0                	test   %eax,%eax
f01014dd:	75 f7                	jne    f01014d6 <mem_init+0x4d8>
		--nfree;
	assert(nfree == 0);
f01014df:	85 db                	test   %ebx,%ebx
f01014e1:	74 19                	je     f01014fc <mem_init+0x4fe>
f01014e3:	68 ce 43 10 f0       	push   $0xf01043ce
f01014e8:	68 31 42 10 f0       	push   $0xf0104231
f01014ed:	68 8a 02 00 00       	push   $0x28a
f01014f2:	68 fc 41 10 f0       	push   $0xf01041fc
f01014f7:	e8 8f eb ff ff       	call   f010008b <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f01014fc:	83 ec 0c             	sub    $0xc,%esp
f01014ff:	68 30 3c 10 f0       	push   $0xf0103c30
f0101504:	e8 21 11 00 00       	call   f010262a <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101509:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101510:	e8 7a f8 ff ff       	call   f0100d8f <page_alloc>
f0101515:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101518:	83 c4 10             	add    $0x10,%esp
f010151b:	85 c0                	test   %eax,%eax
f010151d:	75 19                	jne    f0101538 <mem_init+0x53a>
f010151f:	68 dc 42 10 f0       	push   $0xf01042dc
f0101524:	68 31 42 10 f0       	push   $0xf0104231
f0101529:	68 e3 02 00 00       	push   $0x2e3
f010152e:	68 fc 41 10 f0       	push   $0xf01041fc
f0101533:	e8 53 eb ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f0101538:	83 ec 0c             	sub    $0xc,%esp
f010153b:	6a 00                	push   $0x0
f010153d:	e8 4d f8 ff ff       	call   f0100d8f <page_alloc>
f0101542:	89 c3                	mov    %eax,%ebx
f0101544:	83 c4 10             	add    $0x10,%esp
f0101547:	85 c0                	test   %eax,%eax
f0101549:	75 19                	jne    f0101564 <mem_init+0x566>
f010154b:	68 f2 42 10 f0       	push   $0xf01042f2
f0101550:	68 31 42 10 f0       	push   $0xf0104231
f0101555:	68 e4 02 00 00       	push   $0x2e4
f010155a:	68 fc 41 10 f0       	push   $0xf01041fc
f010155f:	e8 27 eb ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0101564:	83 ec 0c             	sub    $0xc,%esp
f0101567:	6a 00                	push   $0x0
f0101569:	e8 21 f8 ff ff       	call   f0100d8f <page_alloc>
f010156e:	89 c6                	mov    %eax,%esi
f0101570:	83 c4 10             	add    $0x10,%esp
f0101573:	85 c0                	test   %eax,%eax
f0101575:	75 19                	jne    f0101590 <mem_init+0x592>
f0101577:	68 08 43 10 f0       	push   $0xf0104308
f010157c:	68 31 42 10 f0       	push   $0xf0104231
f0101581:	68 e5 02 00 00       	push   $0x2e5
f0101586:	68 fc 41 10 f0       	push   $0xf01041fc
f010158b:	e8 fb ea ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101590:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0101593:	75 19                	jne    f01015ae <mem_init+0x5b0>
f0101595:	68 1e 43 10 f0       	push   $0xf010431e
f010159a:	68 31 42 10 f0       	push   $0xf0104231
f010159f:	68 e8 02 00 00       	push   $0x2e8
f01015a4:	68 fc 41 10 f0       	push   $0xf01041fc
f01015a9:	e8 dd ea ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01015ae:	39 c3                	cmp    %eax,%ebx
f01015b0:	74 05                	je     f01015b7 <mem_init+0x5b9>
f01015b2:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f01015b5:	75 19                	jne    f01015d0 <mem_init+0x5d2>
f01015b7:	68 10 3c 10 f0       	push   $0xf0103c10
f01015bc:	68 31 42 10 f0       	push   $0xf0104231
f01015c1:	68 e9 02 00 00       	push   $0x2e9
f01015c6:	68 fc 41 10 f0       	push   $0xf01041fc
f01015cb:	e8 bb ea ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01015d0:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f01015d5:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01015d8:	c7 05 3c 65 11 f0 00 	movl   $0x0,0xf011653c
f01015df:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01015e2:	83 ec 0c             	sub    $0xc,%esp
f01015e5:	6a 00                	push   $0x0
f01015e7:	e8 a3 f7 ff ff       	call   f0100d8f <page_alloc>
f01015ec:	83 c4 10             	add    $0x10,%esp
f01015ef:	85 c0                	test   %eax,%eax
f01015f1:	74 19                	je     f010160c <mem_init+0x60e>
f01015f3:	68 87 43 10 f0       	push   $0xf0104387
f01015f8:	68 31 42 10 f0       	push   $0xf0104231
f01015fd:	68 f0 02 00 00       	push   $0x2f0
f0101602:	68 fc 41 10 f0       	push   $0xf01041fc
f0101607:	e8 7f ea ff ff       	call   f010008b <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f010160c:	83 ec 04             	sub    $0x4,%esp
f010160f:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101612:	50                   	push   %eax
f0101613:	6a 00                	push   $0x0
f0101615:	ff 35 48 69 11 f0    	pushl  0xf0116948
f010161b:	e8 dd f8 ff ff       	call   f0100efd <page_lookup>
f0101620:	83 c4 10             	add    $0x10,%esp
f0101623:	85 c0                	test   %eax,%eax
f0101625:	74 19                	je     f0101640 <mem_init+0x642>
f0101627:	68 50 3c 10 f0       	push   $0xf0103c50
f010162c:	68 31 42 10 f0       	push   $0xf0104231
f0101631:	68 f3 02 00 00       	push   $0x2f3
f0101636:	68 fc 41 10 f0       	push   $0xf01041fc
f010163b:	e8 4b ea ff ff       	call   f010008b <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101640:	6a 02                	push   $0x2
f0101642:	6a 00                	push   $0x0
f0101644:	53                   	push   %ebx
f0101645:	ff 35 48 69 11 f0    	pushl  0xf0116948
f010164b:	e8 42 f9 ff ff       	call   f0100f92 <page_insert>
f0101650:	83 c4 10             	add    $0x10,%esp
f0101653:	85 c0                	test   %eax,%eax
f0101655:	78 19                	js     f0101670 <mem_init+0x672>
f0101657:	68 88 3c 10 f0       	push   $0xf0103c88
f010165c:	68 31 42 10 f0       	push   $0xf0104231
f0101661:	68 f6 02 00 00       	push   $0x2f6
f0101666:	68 fc 41 10 f0       	push   $0xf01041fc
f010166b:	e8 1b ea ff ff       	call   f010008b <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101670:	83 ec 0c             	sub    $0xc,%esp
f0101673:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101676:	e8 8b f7 ff ff       	call   f0100e06 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f010167b:	6a 02                	push   $0x2
f010167d:	6a 00                	push   $0x0
f010167f:	53                   	push   %ebx
f0101680:	ff 35 48 69 11 f0    	pushl  0xf0116948
f0101686:	e8 07 f9 ff ff       	call   f0100f92 <page_insert>
f010168b:	83 c4 20             	add    $0x20,%esp
f010168e:	85 c0                	test   %eax,%eax
f0101690:	74 19                	je     f01016ab <mem_init+0x6ad>
f0101692:	68 b8 3c 10 f0       	push   $0xf0103cb8
f0101697:	68 31 42 10 f0       	push   $0xf0104231
f010169c:	68 fa 02 00 00       	push   $0x2fa
f01016a1:	68 fc 41 10 f0       	push   $0xf01041fc
f01016a6:	e8 e0 e9 ff ff       	call   f010008b <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01016ab:	8b 3d 48 69 11 f0    	mov    0xf0116948,%edi
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01016b1:	a1 4c 69 11 f0       	mov    0xf011694c,%eax
f01016b6:	89 c1                	mov    %eax,%ecx
f01016b8:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01016bb:	8b 17                	mov    (%edi),%edx
f01016bd:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01016c3:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01016c6:	29 c8                	sub    %ecx,%eax
f01016c8:	c1 f8 03             	sar    $0x3,%eax
f01016cb:	c1 e0 0c             	shl    $0xc,%eax
f01016ce:	39 c2                	cmp    %eax,%edx
f01016d0:	74 19                	je     f01016eb <mem_init+0x6ed>
f01016d2:	68 e8 3c 10 f0       	push   $0xf0103ce8
f01016d7:	68 31 42 10 f0       	push   $0xf0104231
f01016dc:	68 fb 02 00 00       	push   $0x2fb
f01016e1:	68 fc 41 10 f0       	push   $0xf01041fc
f01016e6:	e8 a0 e9 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f01016eb:	ba 00 00 00 00       	mov    $0x0,%edx
f01016f0:	89 f8                	mov    %edi,%eax
f01016f2:	e8 06 f2 ff ff       	call   f01008fd <check_va2pa>
f01016f7:	89 da                	mov    %ebx,%edx
f01016f9:	2b 55 cc             	sub    -0x34(%ebp),%edx
f01016fc:	c1 fa 03             	sar    $0x3,%edx
f01016ff:	c1 e2 0c             	shl    $0xc,%edx
f0101702:	39 d0                	cmp    %edx,%eax
f0101704:	74 19                	je     f010171f <mem_init+0x721>
f0101706:	68 10 3d 10 f0       	push   $0xf0103d10
f010170b:	68 31 42 10 f0       	push   $0xf0104231
f0101710:	68 fc 02 00 00       	push   $0x2fc
f0101715:	68 fc 41 10 f0       	push   $0xf01041fc
f010171a:	e8 6c e9 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 1);
f010171f:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101724:	74 19                	je     f010173f <mem_init+0x741>
f0101726:	68 d9 43 10 f0       	push   $0xf01043d9
f010172b:	68 31 42 10 f0       	push   $0xf0104231
f0101730:	68 fd 02 00 00       	push   $0x2fd
f0101735:	68 fc 41 10 f0       	push   $0xf01041fc
f010173a:	e8 4c e9 ff ff       	call   f010008b <_panic>
	assert(pp0->pp_ref == 1);
f010173f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101742:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101747:	74 19                	je     f0101762 <mem_init+0x764>
f0101749:	68 ea 43 10 f0       	push   $0xf01043ea
f010174e:	68 31 42 10 f0       	push   $0xf0104231
f0101753:	68 fe 02 00 00       	push   $0x2fe
f0101758:	68 fc 41 10 f0       	push   $0xf01041fc
f010175d:	e8 29 e9 ff ff       	call   f010008b <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101762:	6a 02                	push   $0x2
f0101764:	68 00 10 00 00       	push   $0x1000
f0101769:	56                   	push   %esi
f010176a:	57                   	push   %edi
f010176b:	e8 22 f8 ff ff       	call   f0100f92 <page_insert>
f0101770:	83 c4 10             	add    $0x10,%esp
f0101773:	85 c0                	test   %eax,%eax
f0101775:	74 19                	je     f0101790 <mem_init+0x792>
f0101777:	68 40 3d 10 f0       	push   $0xf0103d40
f010177c:	68 31 42 10 f0       	push   $0xf0104231
f0101781:	68 01 03 00 00       	push   $0x301
f0101786:	68 fc 41 10 f0       	push   $0xf01041fc
f010178b:	e8 fb e8 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101790:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101795:	a1 48 69 11 f0       	mov    0xf0116948,%eax
f010179a:	e8 5e f1 ff ff       	call   f01008fd <check_va2pa>
f010179f:	89 f2                	mov    %esi,%edx
f01017a1:	2b 15 4c 69 11 f0    	sub    0xf011694c,%edx
f01017a7:	c1 fa 03             	sar    $0x3,%edx
f01017aa:	c1 e2 0c             	shl    $0xc,%edx
f01017ad:	39 d0                	cmp    %edx,%eax
f01017af:	74 19                	je     f01017ca <mem_init+0x7cc>
f01017b1:	68 7c 3d 10 f0       	push   $0xf0103d7c
f01017b6:	68 31 42 10 f0       	push   $0xf0104231
f01017bb:	68 02 03 00 00       	push   $0x302
f01017c0:	68 fc 41 10 f0       	push   $0xf01041fc
f01017c5:	e8 c1 e8 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f01017ca:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01017cf:	74 19                	je     f01017ea <mem_init+0x7ec>
f01017d1:	68 fb 43 10 f0       	push   $0xf01043fb
f01017d6:	68 31 42 10 f0       	push   $0xf0104231
f01017db:	68 03 03 00 00       	push   $0x303
f01017e0:	68 fc 41 10 f0       	push   $0xf01041fc
f01017e5:	e8 a1 e8 ff ff       	call   f010008b <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f01017ea:	83 ec 0c             	sub    $0xc,%esp
f01017ed:	6a 00                	push   $0x0
f01017ef:	e8 9b f5 ff ff       	call   f0100d8f <page_alloc>
f01017f4:	83 c4 10             	add    $0x10,%esp
f01017f7:	85 c0                	test   %eax,%eax
f01017f9:	74 19                	je     f0101814 <mem_init+0x816>
f01017fb:	68 87 43 10 f0       	push   $0xf0104387
f0101800:	68 31 42 10 f0       	push   $0xf0104231
f0101805:	68 06 03 00 00       	push   $0x306
f010180a:	68 fc 41 10 f0       	push   $0xf01041fc
f010180f:	e8 77 e8 ff ff       	call   f010008b <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101814:	6a 02                	push   $0x2
f0101816:	68 00 10 00 00       	push   $0x1000
f010181b:	56                   	push   %esi
f010181c:	ff 35 48 69 11 f0    	pushl  0xf0116948
f0101822:	e8 6b f7 ff ff       	call   f0100f92 <page_insert>
f0101827:	83 c4 10             	add    $0x10,%esp
f010182a:	85 c0                	test   %eax,%eax
f010182c:	74 19                	je     f0101847 <mem_init+0x849>
f010182e:	68 40 3d 10 f0       	push   $0xf0103d40
f0101833:	68 31 42 10 f0       	push   $0xf0104231
f0101838:	68 09 03 00 00       	push   $0x309
f010183d:	68 fc 41 10 f0       	push   $0xf01041fc
f0101842:	e8 44 e8 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101847:	ba 00 10 00 00       	mov    $0x1000,%edx
f010184c:	a1 48 69 11 f0       	mov    0xf0116948,%eax
f0101851:	e8 a7 f0 ff ff       	call   f01008fd <check_va2pa>
f0101856:	89 f2                	mov    %esi,%edx
f0101858:	2b 15 4c 69 11 f0    	sub    0xf011694c,%edx
f010185e:	c1 fa 03             	sar    $0x3,%edx
f0101861:	c1 e2 0c             	shl    $0xc,%edx
f0101864:	39 d0                	cmp    %edx,%eax
f0101866:	74 19                	je     f0101881 <mem_init+0x883>
f0101868:	68 7c 3d 10 f0       	push   $0xf0103d7c
f010186d:	68 31 42 10 f0       	push   $0xf0104231
f0101872:	68 0a 03 00 00       	push   $0x30a
f0101877:	68 fc 41 10 f0       	push   $0xf01041fc
f010187c:	e8 0a e8 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f0101881:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101886:	74 19                	je     f01018a1 <mem_init+0x8a3>
f0101888:	68 fb 43 10 f0       	push   $0xf01043fb
f010188d:	68 31 42 10 f0       	push   $0xf0104231
f0101892:	68 0b 03 00 00       	push   $0x30b
f0101897:	68 fc 41 10 f0       	push   $0xf01041fc
f010189c:	e8 ea e7 ff ff       	call   f010008b <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f01018a1:	83 ec 0c             	sub    $0xc,%esp
f01018a4:	6a 00                	push   $0x0
f01018a6:	e8 e4 f4 ff ff       	call   f0100d8f <page_alloc>
f01018ab:	83 c4 10             	add    $0x10,%esp
f01018ae:	85 c0                	test   %eax,%eax
f01018b0:	74 19                	je     f01018cb <mem_init+0x8cd>
f01018b2:	68 87 43 10 f0       	push   $0xf0104387
f01018b7:	68 31 42 10 f0       	push   $0xf0104231
f01018bc:	68 0f 03 00 00       	push   $0x30f
f01018c1:	68 fc 41 10 f0       	push   $0xf01041fc
f01018c6:	e8 c0 e7 ff ff       	call   f010008b <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f01018cb:	8b 15 48 69 11 f0    	mov    0xf0116948,%edx
f01018d1:	8b 02                	mov    (%edx),%eax
f01018d3:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01018d8:	89 c1                	mov    %eax,%ecx
f01018da:	c1 e9 0c             	shr    $0xc,%ecx
f01018dd:	3b 0d 44 69 11 f0    	cmp    0xf0116944,%ecx
f01018e3:	72 15                	jb     f01018fa <mem_init+0x8fc>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01018e5:	50                   	push   %eax
f01018e6:	68 74 3a 10 f0       	push   $0xf0103a74
f01018eb:	68 12 03 00 00       	push   $0x312
f01018f0:	68 fc 41 10 f0       	push   $0xf01041fc
f01018f5:	e8 91 e7 ff ff       	call   f010008b <_panic>
f01018fa:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01018ff:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101902:	83 ec 04             	sub    $0x4,%esp
f0101905:	6a 00                	push   $0x0
f0101907:	68 00 10 00 00       	push   $0x1000
f010190c:	52                   	push   %edx
f010190d:	e8 56 f5 ff ff       	call   f0100e68 <pgdir_walk>
f0101912:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101915:	8d 51 04             	lea    0x4(%ecx),%edx
f0101918:	83 c4 10             	add    $0x10,%esp
f010191b:	39 d0                	cmp    %edx,%eax
f010191d:	74 19                	je     f0101938 <mem_init+0x93a>
f010191f:	68 ac 3d 10 f0       	push   $0xf0103dac
f0101924:	68 31 42 10 f0       	push   $0xf0104231
f0101929:	68 13 03 00 00       	push   $0x313
f010192e:	68 fc 41 10 f0       	push   $0xf01041fc
f0101933:	e8 53 e7 ff ff       	call   f010008b <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101938:	6a 06                	push   $0x6
f010193a:	68 00 10 00 00       	push   $0x1000
f010193f:	56                   	push   %esi
f0101940:	ff 35 48 69 11 f0    	pushl  0xf0116948
f0101946:	e8 47 f6 ff ff       	call   f0100f92 <page_insert>
f010194b:	83 c4 10             	add    $0x10,%esp
f010194e:	85 c0                	test   %eax,%eax
f0101950:	74 19                	je     f010196b <mem_init+0x96d>
f0101952:	68 ec 3d 10 f0       	push   $0xf0103dec
f0101957:	68 31 42 10 f0       	push   $0xf0104231
f010195c:	68 16 03 00 00       	push   $0x316
f0101961:	68 fc 41 10 f0       	push   $0xf01041fc
f0101966:	e8 20 e7 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f010196b:	8b 3d 48 69 11 f0    	mov    0xf0116948,%edi
f0101971:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101976:	89 f8                	mov    %edi,%eax
f0101978:	e8 80 ef ff ff       	call   f01008fd <check_va2pa>
f010197d:	89 f2                	mov    %esi,%edx
f010197f:	2b 15 4c 69 11 f0    	sub    0xf011694c,%edx
f0101985:	c1 fa 03             	sar    $0x3,%edx
f0101988:	c1 e2 0c             	shl    $0xc,%edx
f010198b:	39 d0                	cmp    %edx,%eax
f010198d:	74 19                	je     f01019a8 <mem_init+0x9aa>
f010198f:	68 7c 3d 10 f0       	push   $0xf0103d7c
f0101994:	68 31 42 10 f0       	push   $0xf0104231
f0101999:	68 17 03 00 00       	push   $0x317
f010199e:	68 fc 41 10 f0       	push   $0xf01041fc
f01019a3:	e8 e3 e6 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f01019a8:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01019ad:	74 19                	je     f01019c8 <mem_init+0x9ca>
f01019af:	68 fb 43 10 f0       	push   $0xf01043fb
f01019b4:	68 31 42 10 f0       	push   $0xf0104231
f01019b9:	68 18 03 00 00       	push   $0x318
f01019be:	68 fc 41 10 f0       	push   $0xf01041fc
f01019c3:	e8 c3 e6 ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f01019c8:	83 ec 04             	sub    $0x4,%esp
f01019cb:	6a 00                	push   $0x0
f01019cd:	68 00 10 00 00       	push   $0x1000
f01019d2:	57                   	push   %edi
f01019d3:	e8 90 f4 ff ff       	call   f0100e68 <pgdir_walk>
f01019d8:	83 c4 10             	add    $0x10,%esp
f01019db:	f6 00 04             	testb  $0x4,(%eax)
f01019de:	75 19                	jne    f01019f9 <mem_init+0x9fb>
f01019e0:	68 2c 3e 10 f0       	push   $0xf0103e2c
f01019e5:	68 31 42 10 f0       	push   $0xf0104231
f01019ea:	68 19 03 00 00       	push   $0x319
f01019ef:	68 fc 41 10 f0       	push   $0xf01041fc
f01019f4:	e8 92 e6 ff ff       	call   f010008b <_panic>
	assert(kern_pgdir[0] & PTE_U);
f01019f9:	a1 48 69 11 f0       	mov    0xf0116948,%eax
f01019fe:	f6 00 04             	testb  $0x4,(%eax)
f0101a01:	75 19                	jne    f0101a1c <mem_init+0xa1e>
f0101a03:	68 0c 44 10 f0       	push   $0xf010440c
f0101a08:	68 31 42 10 f0       	push   $0xf0104231
f0101a0d:	68 1a 03 00 00       	push   $0x31a
f0101a12:	68 fc 41 10 f0       	push   $0xf01041fc
f0101a17:	e8 6f e6 ff ff       	call   f010008b <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101a1c:	6a 02                	push   $0x2
f0101a1e:	68 00 10 00 00       	push   $0x1000
f0101a23:	56                   	push   %esi
f0101a24:	50                   	push   %eax
f0101a25:	e8 68 f5 ff ff       	call   f0100f92 <page_insert>
f0101a2a:	83 c4 10             	add    $0x10,%esp
f0101a2d:	85 c0                	test   %eax,%eax
f0101a2f:	74 19                	je     f0101a4a <mem_init+0xa4c>
f0101a31:	68 40 3d 10 f0       	push   $0xf0103d40
f0101a36:	68 31 42 10 f0       	push   $0xf0104231
f0101a3b:	68 1d 03 00 00       	push   $0x31d
f0101a40:	68 fc 41 10 f0       	push   $0xf01041fc
f0101a45:	e8 41 e6 ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101a4a:	83 ec 04             	sub    $0x4,%esp
f0101a4d:	6a 00                	push   $0x0
f0101a4f:	68 00 10 00 00       	push   $0x1000
f0101a54:	ff 35 48 69 11 f0    	pushl  0xf0116948
f0101a5a:	e8 09 f4 ff ff       	call   f0100e68 <pgdir_walk>
f0101a5f:	83 c4 10             	add    $0x10,%esp
f0101a62:	f6 00 02             	testb  $0x2,(%eax)
f0101a65:	75 19                	jne    f0101a80 <mem_init+0xa82>
f0101a67:	68 60 3e 10 f0       	push   $0xf0103e60
f0101a6c:	68 31 42 10 f0       	push   $0xf0104231
f0101a71:	68 1e 03 00 00       	push   $0x31e
f0101a76:	68 fc 41 10 f0       	push   $0xf01041fc
f0101a7b:	e8 0b e6 ff ff       	call   f010008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101a80:	83 ec 04             	sub    $0x4,%esp
f0101a83:	6a 00                	push   $0x0
f0101a85:	68 00 10 00 00       	push   $0x1000
f0101a8a:	ff 35 48 69 11 f0    	pushl  0xf0116948
f0101a90:	e8 d3 f3 ff ff       	call   f0100e68 <pgdir_walk>
f0101a95:	83 c4 10             	add    $0x10,%esp
f0101a98:	f6 00 04             	testb  $0x4,(%eax)
f0101a9b:	74 19                	je     f0101ab6 <mem_init+0xab8>
f0101a9d:	68 94 3e 10 f0       	push   $0xf0103e94
f0101aa2:	68 31 42 10 f0       	push   $0xf0104231
f0101aa7:	68 1f 03 00 00       	push   $0x31f
f0101aac:	68 fc 41 10 f0       	push   $0xf01041fc
f0101ab1:	e8 d5 e5 ff ff       	call   f010008b <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101ab6:	6a 02                	push   $0x2
f0101ab8:	68 00 00 40 00       	push   $0x400000
f0101abd:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101ac0:	ff 35 48 69 11 f0    	pushl  0xf0116948
f0101ac6:	e8 c7 f4 ff ff       	call   f0100f92 <page_insert>
f0101acb:	83 c4 10             	add    $0x10,%esp
f0101ace:	85 c0                	test   %eax,%eax
f0101ad0:	78 19                	js     f0101aeb <mem_init+0xaed>
f0101ad2:	68 cc 3e 10 f0       	push   $0xf0103ecc
f0101ad7:	68 31 42 10 f0       	push   $0xf0104231
f0101adc:	68 22 03 00 00       	push   $0x322
f0101ae1:	68 fc 41 10 f0       	push   $0xf01041fc
f0101ae6:	e8 a0 e5 ff ff       	call   f010008b <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101aeb:	6a 02                	push   $0x2
f0101aed:	68 00 10 00 00       	push   $0x1000
f0101af2:	53                   	push   %ebx
f0101af3:	ff 35 48 69 11 f0    	pushl  0xf0116948
f0101af9:	e8 94 f4 ff ff       	call   f0100f92 <page_insert>
f0101afe:	83 c4 10             	add    $0x10,%esp
f0101b01:	85 c0                	test   %eax,%eax
f0101b03:	74 19                	je     f0101b1e <mem_init+0xb20>
f0101b05:	68 04 3f 10 f0       	push   $0xf0103f04
f0101b0a:	68 31 42 10 f0       	push   $0xf0104231
f0101b0f:	68 25 03 00 00       	push   $0x325
f0101b14:	68 fc 41 10 f0       	push   $0xf01041fc
f0101b19:	e8 6d e5 ff ff       	call   f010008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101b1e:	83 ec 04             	sub    $0x4,%esp
f0101b21:	6a 00                	push   $0x0
f0101b23:	68 00 10 00 00       	push   $0x1000
f0101b28:	ff 35 48 69 11 f0    	pushl  0xf0116948
f0101b2e:	e8 35 f3 ff ff       	call   f0100e68 <pgdir_walk>
f0101b33:	83 c4 10             	add    $0x10,%esp
f0101b36:	f6 00 04             	testb  $0x4,(%eax)
f0101b39:	74 19                	je     f0101b54 <mem_init+0xb56>
f0101b3b:	68 94 3e 10 f0       	push   $0xf0103e94
f0101b40:	68 31 42 10 f0       	push   $0xf0104231
f0101b45:	68 26 03 00 00       	push   $0x326
f0101b4a:	68 fc 41 10 f0       	push   $0xf01041fc
f0101b4f:	e8 37 e5 ff ff       	call   f010008b <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101b54:	8b 3d 48 69 11 f0    	mov    0xf0116948,%edi
f0101b5a:	ba 00 00 00 00       	mov    $0x0,%edx
f0101b5f:	89 f8                	mov    %edi,%eax
f0101b61:	e8 97 ed ff ff       	call   f01008fd <check_va2pa>
f0101b66:	89 c1                	mov    %eax,%ecx
f0101b68:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101b6b:	89 d8                	mov    %ebx,%eax
f0101b6d:	2b 05 4c 69 11 f0    	sub    0xf011694c,%eax
f0101b73:	c1 f8 03             	sar    $0x3,%eax
f0101b76:	c1 e0 0c             	shl    $0xc,%eax
f0101b79:	39 c1                	cmp    %eax,%ecx
f0101b7b:	74 19                	je     f0101b96 <mem_init+0xb98>
f0101b7d:	68 40 3f 10 f0       	push   $0xf0103f40
f0101b82:	68 31 42 10 f0       	push   $0xf0104231
f0101b87:	68 29 03 00 00       	push   $0x329
f0101b8c:	68 fc 41 10 f0       	push   $0xf01041fc
f0101b91:	e8 f5 e4 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101b96:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101b9b:	89 f8                	mov    %edi,%eax
f0101b9d:	e8 5b ed ff ff       	call   f01008fd <check_va2pa>
f0101ba2:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101ba5:	74 19                	je     f0101bc0 <mem_init+0xbc2>
f0101ba7:	68 6c 3f 10 f0       	push   $0xf0103f6c
f0101bac:	68 31 42 10 f0       	push   $0xf0104231
f0101bb1:	68 2a 03 00 00       	push   $0x32a
f0101bb6:	68 fc 41 10 f0       	push   $0xf01041fc
f0101bbb:	e8 cb e4 ff ff       	call   f010008b <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101bc0:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101bc5:	74 19                	je     f0101be0 <mem_init+0xbe2>
f0101bc7:	68 22 44 10 f0       	push   $0xf0104422
f0101bcc:	68 31 42 10 f0       	push   $0xf0104231
f0101bd1:	68 2c 03 00 00       	push   $0x32c
f0101bd6:	68 fc 41 10 f0       	push   $0xf01041fc
f0101bdb:	e8 ab e4 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101be0:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101be5:	74 19                	je     f0101c00 <mem_init+0xc02>
f0101be7:	68 33 44 10 f0       	push   $0xf0104433
f0101bec:	68 31 42 10 f0       	push   $0xf0104231
f0101bf1:	68 2d 03 00 00       	push   $0x32d
f0101bf6:	68 fc 41 10 f0       	push   $0xf01041fc
f0101bfb:	e8 8b e4 ff ff       	call   f010008b <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101c00:	83 ec 0c             	sub    $0xc,%esp
f0101c03:	6a 00                	push   $0x0
f0101c05:	e8 85 f1 ff ff       	call   f0100d8f <page_alloc>
f0101c0a:	83 c4 10             	add    $0x10,%esp
f0101c0d:	39 c6                	cmp    %eax,%esi
f0101c0f:	75 04                	jne    f0101c15 <mem_init+0xc17>
f0101c11:	85 c0                	test   %eax,%eax
f0101c13:	75 19                	jne    f0101c2e <mem_init+0xc30>
f0101c15:	68 9c 3f 10 f0       	push   $0xf0103f9c
f0101c1a:	68 31 42 10 f0       	push   $0xf0104231
f0101c1f:	68 30 03 00 00       	push   $0x330
f0101c24:	68 fc 41 10 f0       	push   $0xf01041fc
f0101c29:	e8 5d e4 ff ff       	call   f010008b <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101c2e:	83 ec 08             	sub    $0x8,%esp
f0101c31:	6a 00                	push   $0x0
f0101c33:	ff 35 48 69 11 f0    	pushl  0xf0116948
f0101c39:	e8 19 f3 ff ff       	call   f0100f57 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101c3e:	8b 3d 48 69 11 f0    	mov    0xf0116948,%edi
f0101c44:	ba 00 00 00 00       	mov    $0x0,%edx
f0101c49:	89 f8                	mov    %edi,%eax
f0101c4b:	e8 ad ec ff ff       	call   f01008fd <check_va2pa>
f0101c50:	83 c4 10             	add    $0x10,%esp
f0101c53:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101c56:	74 19                	je     f0101c71 <mem_init+0xc73>
f0101c58:	68 c0 3f 10 f0       	push   $0xf0103fc0
f0101c5d:	68 31 42 10 f0       	push   $0xf0104231
f0101c62:	68 34 03 00 00       	push   $0x334
f0101c67:	68 fc 41 10 f0       	push   $0xf01041fc
f0101c6c:	e8 1a e4 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101c71:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c76:	89 f8                	mov    %edi,%eax
f0101c78:	e8 80 ec ff ff       	call   f01008fd <check_va2pa>
f0101c7d:	89 da                	mov    %ebx,%edx
f0101c7f:	2b 15 4c 69 11 f0    	sub    0xf011694c,%edx
f0101c85:	c1 fa 03             	sar    $0x3,%edx
f0101c88:	c1 e2 0c             	shl    $0xc,%edx
f0101c8b:	39 d0                	cmp    %edx,%eax
f0101c8d:	74 19                	je     f0101ca8 <mem_init+0xcaa>
f0101c8f:	68 6c 3f 10 f0       	push   $0xf0103f6c
f0101c94:	68 31 42 10 f0       	push   $0xf0104231
f0101c99:	68 35 03 00 00       	push   $0x335
f0101c9e:	68 fc 41 10 f0       	push   $0xf01041fc
f0101ca3:	e8 e3 e3 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 1);
f0101ca8:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101cad:	74 19                	je     f0101cc8 <mem_init+0xcca>
f0101caf:	68 d9 43 10 f0       	push   $0xf01043d9
f0101cb4:	68 31 42 10 f0       	push   $0xf0104231
f0101cb9:	68 36 03 00 00       	push   $0x336
f0101cbe:	68 fc 41 10 f0       	push   $0xf01041fc
f0101cc3:	e8 c3 e3 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101cc8:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101ccd:	74 19                	je     f0101ce8 <mem_init+0xcea>
f0101ccf:	68 33 44 10 f0       	push   $0xf0104433
f0101cd4:	68 31 42 10 f0       	push   $0xf0104231
f0101cd9:	68 37 03 00 00       	push   $0x337
f0101cde:	68 fc 41 10 f0       	push   $0xf01041fc
f0101ce3:	e8 a3 e3 ff ff       	call   f010008b <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101ce8:	6a 00                	push   $0x0
f0101cea:	68 00 10 00 00       	push   $0x1000
f0101cef:	53                   	push   %ebx
f0101cf0:	57                   	push   %edi
f0101cf1:	e8 9c f2 ff ff       	call   f0100f92 <page_insert>
f0101cf6:	83 c4 10             	add    $0x10,%esp
f0101cf9:	85 c0                	test   %eax,%eax
f0101cfb:	74 19                	je     f0101d16 <mem_init+0xd18>
f0101cfd:	68 e4 3f 10 f0       	push   $0xf0103fe4
f0101d02:	68 31 42 10 f0       	push   $0xf0104231
f0101d07:	68 3a 03 00 00       	push   $0x33a
f0101d0c:	68 fc 41 10 f0       	push   $0xf01041fc
f0101d11:	e8 75 e3 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref);
f0101d16:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101d1b:	75 19                	jne    f0101d36 <mem_init+0xd38>
f0101d1d:	68 44 44 10 f0       	push   $0xf0104444
f0101d22:	68 31 42 10 f0       	push   $0xf0104231
f0101d27:	68 3b 03 00 00       	push   $0x33b
f0101d2c:	68 fc 41 10 f0       	push   $0xf01041fc
f0101d31:	e8 55 e3 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_link == NULL);
f0101d36:	83 3b 00             	cmpl   $0x0,(%ebx)
f0101d39:	74 19                	je     f0101d54 <mem_init+0xd56>
f0101d3b:	68 50 44 10 f0       	push   $0xf0104450
f0101d40:	68 31 42 10 f0       	push   $0xf0104231
f0101d45:	68 3c 03 00 00       	push   $0x33c
f0101d4a:	68 fc 41 10 f0       	push   $0xf01041fc
f0101d4f:	e8 37 e3 ff ff       	call   f010008b <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101d54:	83 ec 08             	sub    $0x8,%esp
f0101d57:	68 00 10 00 00       	push   $0x1000
f0101d5c:	ff 35 48 69 11 f0    	pushl  0xf0116948
f0101d62:	e8 f0 f1 ff ff       	call   f0100f57 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101d67:	8b 3d 48 69 11 f0    	mov    0xf0116948,%edi
f0101d6d:	ba 00 00 00 00       	mov    $0x0,%edx
f0101d72:	89 f8                	mov    %edi,%eax
f0101d74:	e8 84 eb ff ff       	call   f01008fd <check_va2pa>
f0101d79:	83 c4 10             	add    $0x10,%esp
f0101d7c:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101d7f:	74 19                	je     f0101d9a <mem_init+0xd9c>
f0101d81:	68 c0 3f 10 f0       	push   $0xf0103fc0
f0101d86:	68 31 42 10 f0       	push   $0xf0104231
f0101d8b:	68 40 03 00 00       	push   $0x340
f0101d90:	68 fc 41 10 f0       	push   $0xf01041fc
f0101d95:	e8 f1 e2 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101d9a:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101d9f:	89 f8                	mov    %edi,%eax
f0101da1:	e8 57 eb ff ff       	call   f01008fd <check_va2pa>
f0101da6:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101da9:	74 19                	je     f0101dc4 <mem_init+0xdc6>
f0101dab:	68 1c 40 10 f0       	push   $0xf010401c
f0101db0:	68 31 42 10 f0       	push   $0xf0104231
f0101db5:	68 41 03 00 00       	push   $0x341
f0101dba:	68 fc 41 10 f0       	push   $0xf01041fc
f0101dbf:	e8 c7 e2 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 0);
f0101dc4:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101dc9:	74 19                	je     f0101de4 <mem_init+0xde6>
f0101dcb:	68 65 44 10 f0       	push   $0xf0104465
f0101dd0:	68 31 42 10 f0       	push   $0xf0104231
f0101dd5:	68 42 03 00 00       	push   $0x342
f0101dda:	68 fc 41 10 f0       	push   $0xf01041fc
f0101ddf:	e8 a7 e2 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101de4:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101de9:	74 19                	je     f0101e04 <mem_init+0xe06>
f0101deb:	68 33 44 10 f0       	push   $0xf0104433
f0101df0:	68 31 42 10 f0       	push   $0xf0104231
f0101df5:	68 43 03 00 00       	push   $0x343
f0101dfa:	68 fc 41 10 f0       	push   $0xf01041fc
f0101dff:	e8 87 e2 ff ff       	call   f010008b <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101e04:	83 ec 0c             	sub    $0xc,%esp
f0101e07:	6a 00                	push   $0x0
f0101e09:	e8 81 ef ff ff       	call   f0100d8f <page_alloc>
f0101e0e:	83 c4 10             	add    $0x10,%esp
f0101e11:	85 c0                	test   %eax,%eax
f0101e13:	74 04                	je     f0101e19 <mem_init+0xe1b>
f0101e15:	39 c3                	cmp    %eax,%ebx
f0101e17:	74 19                	je     f0101e32 <mem_init+0xe34>
f0101e19:	68 44 40 10 f0       	push   $0xf0104044
f0101e1e:	68 31 42 10 f0       	push   $0xf0104231
f0101e23:	68 46 03 00 00       	push   $0x346
f0101e28:	68 fc 41 10 f0       	push   $0xf01041fc
f0101e2d:	e8 59 e2 ff ff       	call   f010008b <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101e32:	83 ec 0c             	sub    $0xc,%esp
f0101e35:	6a 00                	push   $0x0
f0101e37:	e8 53 ef ff ff       	call   f0100d8f <page_alloc>
f0101e3c:	83 c4 10             	add    $0x10,%esp
f0101e3f:	85 c0                	test   %eax,%eax
f0101e41:	74 19                	je     f0101e5c <mem_init+0xe5e>
f0101e43:	68 87 43 10 f0       	push   $0xf0104387
f0101e48:	68 31 42 10 f0       	push   $0xf0104231
f0101e4d:	68 49 03 00 00       	push   $0x349
f0101e52:	68 fc 41 10 f0       	push   $0xf01041fc
f0101e57:	e8 2f e2 ff ff       	call   f010008b <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101e5c:	8b 0d 48 69 11 f0    	mov    0xf0116948,%ecx
f0101e62:	8b 11                	mov    (%ecx),%edx
f0101e64:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101e6a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e6d:	2b 05 4c 69 11 f0    	sub    0xf011694c,%eax
f0101e73:	c1 f8 03             	sar    $0x3,%eax
f0101e76:	c1 e0 0c             	shl    $0xc,%eax
f0101e79:	39 c2                	cmp    %eax,%edx
f0101e7b:	74 19                	je     f0101e96 <mem_init+0xe98>
f0101e7d:	68 e8 3c 10 f0       	push   $0xf0103ce8
f0101e82:	68 31 42 10 f0       	push   $0xf0104231
f0101e87:	68 4c 03 00 00       	push   $0x34c
f0101e8c:	68 fc 41 10 f0       	push   $0xf01041fc
f0101e91:	e8 f5 e1 ff ff       	call   f010008b <_panic>
	kern_pgdir[0] = 0;
f0101e96:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0101e9c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e9f:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101ea4:	74 19                	je     f0101ebf <mem_init+0xec1>
f0101ea6:	68 ea 43 10 f0       	push   $0xf01043ea
f0101eab:	68 31 42 10 f0       	push   $0xf0104231
f0101eb0:	68 4e 03 00 00       	push   $0x34e
f0101eb5:	68 fc 41 10 f0       	push   $0xf01041fc
f0101eba:	e8 cc e1 ff ff       	call   f010008b <_panic>
	pp0->pp_ref = 0;
f0101ebf:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ec2:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0101ec8:	83 ec 0c             	sub    $0xc,%esp
f0101ecb:	50                   	push   %eax
f0101ecc:	e8 35 ef ff ff       	call   f0100e06 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0101ed1:	83 c4 0c             	add    $0xc,%esp
f0101ed4:	6a 01                	push   $0x1
f0101ed6:	68 00 10 40 00       	push   $0x401000
f0101edb:	ff 35 48 69 11 f0    	pushl  0xf0116948
f0101ee1:	e8 82 ef ff ff       	call   f0100e68 <pgdir_walk>
f0101ee6:	89 c7                	mov    %eax,%edi
f0101ee8:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0101eeb:	a1 48 69 11 f0       	mov    0xf0116948,%eax
f0101ef0:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101ef3:	8b 40 04             	mov    0x4(%eax),%eax
f0101ef6:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101efb:	8b 0d 44 69 11 f0    	mov    0xf0116944,%ecx
f0101f01:	89 c2                	mov    %eax,%edx
f0101f03:	c1 ea 0c             	shr    $0xc,%edx
f0101f06:	83 c4 10             	add    $0x10,%esp
f0101f09:	39 ca                	cmp    %ecx,%edx
f0101f0b:	72 15                	jb     f0101f22 <mem_init+0xf24>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101f0d:	50                   	push   %eax
f0101f0e:	68 74 3a 10 f0       	push   $0xf0103a74
f0101f13:	68 55 03 00 00       	push   $0x355
f0101f18:	68 fc 41 10 f0       	push   $0xf01041fc
f0101f1d:	e8 69 e1 ff ff       	call   f010008b <_panic>
	assert(ptep == ptep1 + PTX(va));
f0101f22:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f0101f27:	39 c7                	cmp    %eax,%edi
f0101f29:	74 19                	je     f0101f44 <mem_init+0xf46>
f0101f2b:	68 76 44 10 f0       	push   $0xf0104476
f0101f30:	68 31 42 10 f0       	push   $0xf0104231
f0101f35:	68 56 03 00 00       	push   $0x356
f0101f3a:	68 fc 41 10 f0       	push   $0xf01041fc
f0101f3f:	e8 47 e1 ff ff       	call   f010008b <_panic>
	kern_pgdir[PDX(va)] = 0;
f0101f44:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101f47:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f0101f4e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f51:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101f57:	2b 05 4c 69 11 f0    	sub    0xf011694c,%eax
f0101f5d:	c1 f8 03             	sar    $0x3,%eax
f0101f60:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101f63:	89 c2                	mov    %eax,%edx
f0101f65:	c1 ea 0c             	shr    $0xc,%edx
f0101f68:	39 d1                	cmp    %edx,%ecx
f0101f6a:	77 12                	ja     f0101f7e <mem_init+0xf80>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101f6c:	50                   	push   %eax
f0101f6d:	68 74 3a 10 f0       	push   $0xf0103a74
f0101f72:	6a 52                	push   $0x52
f0101f74:	68 17 42 10 f0       	push   $0xf0104217
f0101f79:	e8 0d e1 ff ff       	call   f010008b <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0101f7e:	83 ec 04             	sub    $0x4,%esp
f0101f81:	68 00 10 00 00       	push   $0x1000
f0101f86:	68 ff 00 00 00       	push   $0xff
f0101f8b:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101f90:	50                   	push   %eax
f0101f91:	e8 4d 11 00 00       	call   f01030e3 <memset>
	page_free(pp0);
f0101f96:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0101f99:	89 3c 24             	mov    %edi,(%esp)
f0101f9c:	e8 65 ee ff ff       	call   f0100e06 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0101fa1:	83 c4 0c             	add    $0xc,%esp
f0101fa4:	6a 01                	push   $0x1
f0101fa6:	6a 00                	push   $0x0
f0101fa8:	ff 35 48 69 11 f0    	pushl  0xf0116948
f0101fae:	e8 b5 ee ff ff       	call   f0100e68 <pgdir_walk>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101fb3:	89 fa                	mov    %edi,%edx
f0101fb5:	2b 15 4c 69 11 f0    	sub    0xf011694c,%edx
f0101fbb:	c1 fa 03             	sar    $0x3,%edx
f0101fbe:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101fc1:	89 d0                	mov    %edx,%eax
f0101fc3:	c1 e8 0c             	shr    $0xc,%eax
f0101fc6:	83 c4 10             	add    $0x10,%esp
f0101fc9:	3b 05 44 69 11 f0    	cmp    0xf0116944,%eax
f0101fcf:	72 12                	jb     f0101fe3 <mem_init+0xfe5>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101fd1:	52                   	push   %edx
f0101fd2:	68 74 3a 10 f0       	push   $0xf0103a74
f0101fd7:	6a 52                	push   $0x52
f0101fd9:	68 17 42 10 f0       	push   $0xf0104217
f0101fde:	e8 a8 e0 ff ff       	call   f010008b <_panic>
	return (void *)(pa + KERNBASE);
f0101fe3:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f0101fe9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101fec:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0101ff2:	f6 00 01             	testb  $0x1,(%eax)
f0101ff5:	74 19                	je     f0102010 <mem_init+0x1012>
f0101ff7:	68 8e 44 10 f0       	push   $0xf010448e
f0101ffc:	68 31 42 10 f0       	push   $0xf0104231
f0102001:	68 60 03 00 00       	push   $0x360
f0102006:	68 fc 41 10 f0       	push   $0xf01041fc
f010200b:	e8 7b e0 ff ff       	call   f010008b <_panic>
f0102010:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f0102013:	39 d0                	cmp    %edx,%eax
f0102015:	75 db                	jne    f0101ff2 <mem_init+0xff4>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f0102017:	a1 48 69 11 f0       	mov    0xf0116948,%eax
f010201c:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102022:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102025:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f010202b:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f010202e:	89 0d 3c 65 11 f0    	mov    %ecx,0xf011653c

	// free the pages we took
	page_free(pp0);
f0102034:	83 ec 0c             	sub    $0xc,%esp
f0102037:	50                   	push   %eax
f0102038:	e8 c9 ed ff ff       	call   f0100e06 <page_free>
	page_free(pp1);
f010203d:	89 1c 24             	mov    %ebx,(%esp)
f0102040:	e8 c1 ed ff ff       	call   f0100e06 <page_free>
	page_free(pp2);
f0102045:	89 34 24             	mov    %esi,(%esp)
f0102048:	e8 b9 ed ff ff       	call   f0100e06 <page_free>

	cprintf("check_page() succeeded!\n");
f010204d:	c7 04 24 a5 44 10 f0 	movl   $0xf01044a5,(%esp)
f0102054:	e8 d1 05 00 00       	call   f010262a <cprintf>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f0102059:	8b 35 48 69 11 f0    	mov    0xf0116948,%esi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f010205f:	a1 44 69 11 f0       	mov    0xf0116944,%eax
f0102064:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102067:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f010206e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102073:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102076:	8b 3d 4c 69 11 f0    	mov    0xf011694c,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010207c:	89 7d d0             	mov    %edi,-0x30(%ebp)
f010207f:	83 c4 10             	add    $0x10,%esp

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102082:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102087:	eb 55                	jmp    f01020de <mem_init+0x10e0>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102089:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
f010208f:	89 f0                	mov    %esi,%eax
f0102091:	e8 67 e8 ff ff       	call   f01008fd <check_va2pa>
f0102096:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f010209d:	77 15                	ja     f01020b4 <mem_init+0x10b6>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010209f:	57                   	push   %edi
f01020a0:	68 98 3a 10 f0       	push   $0xf0103a98
f01020a5:	68 a2 02 00 00       	push   $0x2a2
f01020aa:	68 fc 41 10 f0       	push   $0xf01041fc
f01020af:	e8 d7 df ff ff       	call   f010008b <_panic>
f01020b4:	8d 94 1f 00 00 00 10 	lea    0x10000000(%edi,%ebx,1),%edx
f01020bb:	39 d0                	cmp    %edx,%eax
f01020bd:	74 19                	je     f01020d8 <mem_init+0x10da>
f01020bf:	68 68 40 10 f0       	push   $0xf0104068
f01020c4:	68 31 42 10 f0       	push   $0xf0104231
f01020c9:	68 a2 02 00 00       	push   $0x2a2
f01020ce:	68 fc 41 10 f0       	push   $0xf01041fc
f01020d3:	e8 b3 df ff ff       	call   f010008b <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01020d8:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01020de:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f01020e1:	77 a6                	ja     f0102089 <mem_init+0x108b>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01020e3:	8b 7d cc             	mov    -0x34(%ebp),%edi
f01020e6:	c1 e7 0c             	shl    $0xc,%edi
f01020e9:	bb 00 00 00 00       	mov    $0x0,%ebx
f01020ee:	eb 30                	jmp    f0102120 <mem_init+0x1122>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f01020f0:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
f01020f6:	89 f0                	mov    %esi,%eax
f01020f8:	e8 00 e8 ff ff       	call   f01008fd <check_va2pa>
f01020fd:	39 c3                	cmp    %eax,%ebx
f01020ff:	74 19                	je     f010211a <mem_init+0x111c>
f0102101:	68 9c 40 10 f0       	push   $0xf010409c
f0102106:	68 31 42 10 f0       	push   $0xf0104231
f010210b:	68 a7 02 00 00       	push   $0x2a7
f0102110:	68 fc 41 10 f0       	push   $0xf01041fc
f0102115:	e8 71 df ff ff       	call   f010008b <_panic>
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f010211a:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102120:	39 fb                	cmp    %edi,%ebx
f0102122:	72 cc                	jb     f01020f0 <mem_init+0x10f2>
f0102124:	bb 00 80 ff ef       	mov    $0xefff8000,%ebx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102129:	bf 00 c0 10 f0       	mov    $0xf010c000,%edi
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f010212e:	89 da                	mov    %ebx,%edx
f0102130:	89 f0                	mov    %esi,%eax
f0102132:	e8 c6 e7 ff ff       	call   f01008fd <check_va2pa>
f0102137:	81 ff ff ff ff ef    	cmp    $0xefffffff,%edi
f010213d:	77 19                	ja     f0102158 <mem_init+0x115a>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010213f:	68 00 c0 10 f0       	push   $0xf010c000
f0102144:	68 98 3a 10 f0       	push   $0xf0103a98
f0102149:	68 ab 02 00 00       	push   $0x2ab
f010214e:	68 fc 41 10 f0       	push   $0xf01041fc
f0102153:	e8 33 df ff ff       	call   f010008b <_panic>
f0102158:	8d 93 00 40 11 10    	lea    0x10114000(%ebx),%edx
f010215e:	39 d0                	cmp    %edx,%eax
f0102160:	74 19                	je     f010217b <mem_init+0x117d>
f0102162:	68 c4 40 10 f0       	push   $0xf01040c4
f0102167:	68 31 42 10 f0       	push   $0xf0104231
f010216c:	68 ab 02 00 00       	push   $0x2ab
f0102171:	68 fc 41 10 f0       	push   $0xf01041fc
f0102176:	e8 10 df ff ff       	call   f010008b <_panic>
f010217b:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0102181:	81 fb 00 00 00 f0    	cmp    $0xf0000000,%ebx
f0102187:	75 a5                	jne    f010212e <mem_init+0x1130>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102189:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f010218e:	89 f0                	mov    %esi,%eax
f0102190:	e8 68 e7 ff ff       	call   f01008fd <check_va2pa>
f0102195:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102198:	74 51                	je     f01021eb <mem_init+0x11ed>
f010219a:	68 0c 41 10 f0       	push   $0xf010410c
f010219f:	68 31 42 10 f0       	push   $0xf0104231
f01021a4:	68 ac 02 00 00       	push   $0x2ac
f01021a9:	68 fc 41 10 f0       	push   $0xf01041fc
f01021ae:	e8 d8 de ff ff       	call   f010008b <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f01021b3:	3d bc 03 00 00       	cmp    $0x3bc,%eax
f01021b8:	72 36                	jb     f01021f0 <mem_init+0x11f2>
f01021ba:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f01021bf:	76 07                	jbe    f01021c8 <mem_init+0x11ca>
f01021c1:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f01021c6:	75 28                	jne    f01021f0 <mem_init+0x11f2>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
f01021c8:	f6 04 86 01          	testb  $0x1,(%esi,%eax,4)
f01021cc:	0f 85 83 00 00 00    	jne    f0102255 <mem_init+0x1257>
f01021d2:	68 be 44 10 f0       	push   $0xf01044be
f01021d7:	68 31 42 10 f0       	push   $0xf0104231
f01021dc:	68 b4 02 00 00       	push   $0x2b4
f01021e1:	68 fc 41 10 f0       	push   $0xf01041fc
f01021e6:	e8 a0 de ff ff       	call   f010008b <_panic>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f01021eb:	b8 00 00 00 00       	mov    $0x0,%eax
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f01021f0:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f01021f5:	76 3f                	jbe    f0102236 <mem_init+0x1238>
				assert(pgdir[i] & PTE_P);
f01021f7:	8b 14 86             	mov    (%esi,%eax,4),%edx
f01021fa:	f6 c2 01             	test   $0x1,%dl
f01021fd:	75 19                	jne    f0102218 <mem_init+0x121a>
f01021ff:	68 be 44 10 f0       	push   $0xf01044be
f0102204:	68 31 42 10 f0       	push   $0xf0104231
f0102209:	68 b8 02 00 00       	push   $0x2b8
f010220e:	68 fc 41 10 f0       	push   $0xf01041fc
f0102213:	e8 73 de ff ff       	call   f010008b <_panic>
				assert(pgdir[i] & PTE_W);
f0102218:	f6 c2 02             	test   $0x2,%dl
f010221b:	75 38                	jne    f0102255 <mem_init+0x1257>
f010221d:	68 cf 44 10 f0       	push   $0xf01044cf
f0102222:	68 31 42 10 f0       	push   $0xf0104231
f0102227:	68 b9 02 00 00       	push   $0x2b9
f010222c:	68 fc 41 10 f0       	push   $0xf01041fc
f0102231:	e8 55 de ff ff       	call   f010008b <_panic>
			} else
				assert(pgdir[i] == 0);
f0102236:	83 3c 86 00          	cmpl   $0x0,(%esi,%eax,4)
f010223a:	74 19                	je     f0102255 <mem_init+0x1257>
f010223c:	68 e0 44 10 f0       	push   $0xf01044e0
f0102241:	68 31 42 10 f0       	push   $0xf0104231
f0102246:	68 bb 02 00 00       	push   $0x2bb
f010224b:	68 fc 41 10 f0       	push   $0xf01041fc
f0102250:	e8 36 de ff ff       	call   f010008b <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0102255:	83 c0 01             	add    $0x1,%eax
f0102258:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f010225d:	0f 86 50 ff ff ff    	jbe    f01021b3 <mem_init+0x11b5>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f0102263:	83 ec 0c             	sub    $0xc,%esp
f0102266:	68 3c 41 10 f0       	push   $0xf010413c
f010226b:	e8 ba 03 00 00       	call   f010262a <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f0102270:	a1 48 69 11 f0       	mov    0xf0116948,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102275:	83 c4 10             	add    $0x10,%esp
f0102278:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010227d:	77 15                	ja     f0102294 <mem_init+0x1296>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010227f:	50                   	push   %eax
f0102280:	68 98 3a 10 f0       	push   $0xf0103a98
f0102285:	68 d5 00 00 00       	push   $0xd5
f010228a:	68 fc 41 10 f0       	push   $0xf01041fc
f010228f:	e8 f7 dd ff ff       	call   f010008b <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0102294:	05 00 00 00 10       	add    $0x10000000,%eax
f0102299:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f010229c:	b8 00 00 00 00       	mov    $0x0,%eax
f01022a1:	e8 42 e7 ff ff       	call   f01009e8 <check_page_free_list>

static inline uint32_t
rcr0(void)
{
	uint32_t val;
	asm volatile("movl %%cr0,%0" : "=r" (val));
f01022a6:	0f 20 c0             	mov    %cr0,%eax
f01022a9:	83 e0 f3             	and    $0xfffffff3,%eax
}

static inline void
lcr0(uint32_t val)
{
	asm volatile("movl %0,%%cr0" : : "r" (val));
f01022ac:	0d 23 00 05 80       	or     $0x80050023,%eax
f01022b1:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01022b4:	83 ec 0c             	sub    $0xc,%esp
f01022b7:	6a 00                	push   $0x0
f01022b9:	e8 d1 ea ff ff       	call   f0100d8f <page_alloc>
f01022be:	89 c3                	mov    %eax,%ebx
f01022c0:	83 c4 10             	add    $0x10,%esp
f01022c3:	85 c0                	test   %eax,%eax
f01022c5:	75 19                	jne    f01022e0 <mem_init+0x12e2>
f01022c7:	68 dc 42 10 f0       	push   $0xf01042dc
f01022cc:	68 31 42 10 f0       	push   $0xf0104231
f01022d1:	68 7b 03 00 00       	push   $0x37b
f01022d6:	68 fc 41 10 f0       	push   $0xf01041fc
f01022db:	e8 ab dd ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f01022e0:	83 ec 0c             	sub    $0xc,%esp
f01022e3:	6a 00                	push   $0x0
f01022e5:	e8 a5 ea ff ff       	call   f0100d8f <page_alloc>
f01022ea:	89 c7                	mov    %eax,%edi
f01022ec:	83 c4 10             	add    $0x10,%esp
f01022ef:	85 c0                	test   %eax,%eax
f01022f1:	75 19                	jne    f010230c <mem_init+0x130e>
f01022f3:	68 f2 42 10 f0       	push   $0xf01042f2
f01022f8:	68 31 42 10 f0       	push   $0xf0104231
f01022fd:	68 7c 03 00 00       	push   $0x37c
f0102302:	68 fc 41 10 f0       	push   $0xf01041fc
f0102307:	e8 7f dd ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f010230c:	83 ec 0c             	sub    $0xc,%esp
f010230f:	6a 00                	push   $0x0
f0102311:	e8 79 ea ff ff       	call   f0100d8f <page_alloc>
f0102316:	89 c6                	mov    %eax,%esi
f0102318:	83 c4 10             	add    $0x10,%esp
f010231b:	85 c0                	test   %eax,%eax
f010231d:	75 19                	jne    f0102338 <mem_init+0x133a>
f010231f:	68 08 43 10 f0       	push   $0xf0104308
f0102324:	68 31 42 10 f0       	push   $0xf0104231
f0102329:	68 7d 03 00 00       	push   $0x37d
f010232e:	68 fc 41 10 f0       	push   $0xf01041fc
f0102333:	e8 53 dd ff ff       	call   f010008b <_panic>
	page_free(pp0);
f0102338:	83 ec 0c             	sub    $0xc,%esp
f010233b:	53                   	push   %ebx
f010233c:	e8 c5 ea ff ff       	call   f0100e06 <page_free>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102341:	89 f8                	mov    %edi,%eax
f0102343:	2b 05 4c 69 11 f0    	sub    0xf011694c,%eax
f0102349:	c1 f8 03             	sar    $0x3,%eax
f010234c:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010234f:	89 c2                	mov    %eax,%edx
f0102351:	c1 ea 0c             	shr    $0xc,%edx
f0102354:	83 c4 10             	add    $0x10,%esp
f0102357:	3b 15 44 69 11 f0    	cmp    0xf0116944,%edx
f010235d:	72 12                	jb     f0102371 <mem_init+0x1373>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010235f:	50                   	push   %eax
f0102360:	68 74 3a 10 f0       	push   $0xf0103a74
f0102365:	6a 52                	push   $0x52
f0102367:	68 17 42 10 f0       	push   $0xf0104217
f010236c:	e8 1a dd ff ff       	call   f010008b <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f0102371:	83 ec 04             	sub    $0x4,%esp
f0102374:	68 00 10 00 00       	push   $0x1000
f0102379:	6a 01                	push   $0x1
f010237b:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102380:	50                   	push   %eax
f0102381:	e8 5d 0d 00 00       	call   f01030e3 <memset>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102386:	89 f0                	mov    %esi,%eax
f0102388:	2b 05 4c 69 11 f0    	sub    0xf011694c,%eax
f010238e:	c1 f8 03             	sar    $0x3,%eax
f0102391:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102394:	89 c2                	mov    %eax,%edx
f0102396:	c1 ea 0c             	shr    $0xc,%edx
f0102399:	83 c4 10             	add    $0x10,%esp
f010239c:	3b 15 44 69 11 f0    	cmp    0xf0116944,%edx
f01023a2:	72 12                	jb     f01023b6 <mem_init+0x13b8>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01023a4:	50                   	push   %eax
f01023a5:	68 74 3a 10 f0       	push   $0xf0103a74
f01023aa:	6a 52                	push   $0x52
f01023ac:	68 17 42 10 f0       	push   $0xf0104217
f01023b1:	e8 d5 dc ff ff       	call   f010008b <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f01023b6:	83 ec 04             	sub    $0x4,%esp
f01023b9:	68 00 10 00 00       	push   $0x1000
f01023be:	6a 02                	push   $0x2
f01023c0:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01023c5:	50                   	push   %eax
f01023c6:	e8 18 0d 00 00       	call   f01030e3 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f01023cb:	6a 02                	push   $0x2
f01023cd:	68 00 10 00 00       	push   $0x1000
f01023d2:	57                   	push   %edi
f01023d3:	ff 35 48 69 11 f0    	pushl  0xf0116948
f01023d9:	e8 b4 eb ff ff       	call   f0100f92 <page_insert>
	assert(pp1->pp_ref == 1);
f01023de:	83 c4 20             	add    $0x20,%esp
f01023e1:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f01023e6:	74 19                	je     f0102401 <mem_init+0x1403>
f01023e8:	68 d9 43 10 f0       	push   $0xf01043d9
f01023ed:	68 31 42 10 f0       	push   $0xf0104231
f01023f2:	68 82 03 00 00       	push   $0x382
f01023f7:	68 fc 41 10 f0       	push   $0xf01041fc
f01023fc:	e8 8a dc ff ff       	call   f010008b <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102401:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102408:	01 01 01 
f010240b:	74 19                	je     f0102426 <mem_init+0x1428>
f010240d:	68 5c 41 10 f0       	push   $0xf010415c
f0102412:	68 31 42 10 f0       	push   $0xf0104231
f0102417:	68 83 03 00 00       	push   $0x383
f010241c:	68 fc 41 10 f0       	push   $0xf01041fc
f0102421:	e8 65 dc ff ff       	call   f010008b <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102426:	6a 02                	push   $0x2
f0102428:	68 00 10 00 00       	push   $0x1000
f010242d:	56                   	push   %esi
f010242e:	ff 35 48 69 11 f0    	pushl  0xf0116948
f0102434:	e8 59 eb ff ff       	call   f0100f92 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102439:	83 c4 10             	add    $0x10,%esp
f010243c:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102443:	02 02 02 
f0102446:	74 19                	je     f0102461 <mem_init+0x1463>
f0102448:	68 80 41 10 f0       	push   $0xf0104180
f010244d:	68 31 42 10 f0       	push   $0xf0104231
f0102452:	68 85 03 00 00       	push   $0x385
f0102457:	68 fc 41 10 f0       	push   $0xf01041fc
f010245c:	e8 2a dc ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f0102461:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102466:	74 19                	je     f0102481 <mem_init+0x1483>
f0102468:	68 fb 43 10 f0       	push   $0xf01043fb
f010246d:	68 31 42 10 f0       	push   $0xf0104231
f0102472:	68 86 03 00 00       	push   $0x386
f0102477:	68 fc 41 10 f0       	push   $0xf01041fc
f010247c:	e8 0a dc ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 0);
f0102481:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102486:	74 19                	je     f01024a1 <mem_init+0x14a3>
f0102488:	68 65 44 10 f0       	push   $0xf0104465
f010248d:	68 31 42 10 f0       	push   $0xf0104231
f0102492:	68 87 03 00 00       	push   $0x387
f0102497:	68 fc 41 10 f0       	push   $0xf01041fc
f010249c:	e8 ea db ff ff       	call   f010008b <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f01024a1:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f01024a8:	03 03 03 
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01024ab:	89 f0                	mov    %esi,%eax
f01024ad:	2b 05 4c 69 11 f0    	sub    0xf011694c,%eax
f01024b3:	c1 f8 03             	sar    $0x3,%eax
f01024b6:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01024b9:	89 c2                	mov    %eax,%edx
f01024bb:	c1 ea 0c             	shr    $0xc,%edx
f01024be:	3b 15 44 69 11 f0    	cmp    0xf0116944,%edx
f01024c4:	72 12                	jb     f01024d8 <mem_init+0x14da>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01024c6:	50                   	push   %eax
f01024c7:	68 74 3a 10 f0       	push   $0xf0103a74
f01024cc:	6a 52                	push   $0x52
f01024ce:	68 17 42 10 f0       	push   $0xf0104217
f01024d3:	e8 b3 db ff ff       	call   f010008b <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f01024d8:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f01024df:	03 03 03 
f01024e2:	74 19                	je     f01024fd <mem_init+0x14ff>
f01024e4:	68 a4 41 10 f0       	push   $0xf01041a4
f01024e9:	68 31 42 10 f0       	push   $0xf0104231
f01024ee:	68 89 03 00 00       	push   $0x389
f01024f3:	68 fc 41 10 f0       	push   $0xf01041fc
f01024f8:	e8 8e db ff ff       	call   f010008b <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f01024fd:	83 ec 08             	sub    $0x8,%esp
f0102500:	68 00 10 00 00       	push   $0x1000
f0102505:	ff 35 48 69 11 f0    	pushl  0xf0116948
f010250b:	e8 47 ea ff ff       	call   f0100f57 <page_remove>
	assert(pp2->pp_ref == 0);
f0102510:	83 c4 10             	add    $0x10,%esp
f0102513:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102518:	74 19                	je     f0102533 <mem_init+0x1535>
f010251a:	68 33 44 10 f0       	push   $0xf0104433
f010251f:	68 31 42 10 f0       	push   $0xf0104231
f0102524:	68 8b 03 00 00       	push   $0x38b
f0102529:	68 fc 41 10 f0       	push   $0xf01041fc
f010252e:	e8 58 db ff ff       	call   f010008b <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102533:	8b 0d 48 69 11 f0    	mov    0xf0116948,%ecx
f0102539:	8b 11                	mov    (%ecx),%edx
f010253b:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102541:	89 d8                	mov    %ebx,%eax
f0102543:	2b 05 4c 69 11 f0    	sub    0xf011694c,%eax
f0102549:	c1 f8 03             	sar    $0x3,%eax
f010254c:	c1 e0 0c             	shl    $0xc,%eax
f010254f:	39 c2                	cmp    %eax,%edx
f0102551:	74 19                	je     f010256c <mem_init+0x156e>
f0102553:	68 e8 3c 10 f0       	push   $0xf0103ce8
f0102558:	68 31 42 10 f0       	push   $0xf0104231
f010255d:	68 8e 03 00 00       	push   $0x38e
f0102562:	68 fc 41 10 f0       	push   $0xf01041fc
f0102567:	e8 1f db ff ff       	call   f010008b <_panic>
	kern_pgdir[0] = 0;
f010256c:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102572:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102577:	74 19                	je     f0102592 <mem_init+0x1594>
f0102579:	68 ea 43 10 f0       	push   $0xf01043ea
f010257e:	68 31 42 10 f0       	push   $0xf0104231
f0102583:	68 90 03 00 00       	push   $0x390
f0102588:	68 fc 41 10 f0       	push   $0xf01041fc
f010258d:	e8 f9 da ff ff       	call   f010008b <_panic>
	pp0->pp_ref = 0;
f0102592:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f0102598:	83 ec 0c             	sub    $0xc,%esp
f010259b:	53                   	push   %ebx
f010259c:	e8 65 e8 ff ff       	call   f0100e06 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f01025a1:	c7 04 24 d0 41 10 f0 	movl   $0xf01041d0,(%esp)
f01025a8:	e8 7d 00 00 00       	call   f010262a <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f01025ad:	83 c4 10             	add    $0x10,%esp
f01025b0:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01025b3:	5b                   	pop    %ebx
f01025b4:	5e                   	pop    %esi
f01025b5:	5f                   	pop    %edi
f01025b6:	5d                   	pop    %ebp
f01025b7:	c3                   	ret    

f01025b8 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f01025b8:	55                   	push   %ebp
f01025b9:	89 e5                	mov    %esp,%ebp
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01025bb:	8b 45 0c             	mov    0xc(%ebp),%eax
f01025be:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f01025c1:	5d                   	pop    %ebp
f01025c2:	c3                   	ret    

f01025c3 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f01025c3:	55                   	push   %ebp
f01025c4:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01025c6:	ba 70 00 00 00       	mov    $0x70,%edx
f01025cb:	8b 45 08             	mov    0x8(%ebp),%eax
f01025ce:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01025cf:	ba 71 00 00 00       	mov    $0x71,%edx
f01025d4:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f01025d5:	0f b6 c0             	movzbl %al,%eax
}
f01025d8:	5d                   	pop    %ebp
f01025d9:	c3                   	ret    

f01025da <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f01025da:	55                   	push   %ebp
f01025db:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01025dd:	ba 70 00 00 00       	mov    $0x70,%edx
f01025e2:	8b 45 08             	mov    0x8(%ebp),%eax
f01025e5:	ee                   	out    %al,(%dx)
f01025e6:	ba 71 00 00 00       	mov    $0x71,%edx
f01025eb:	8b 45 0c             	mov    0xc(%ebp),%eax
f01025ee:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f01025ef:	5d                   	pop    %ebp
f01025f0:	c3                   	ret    

f01025f1 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01025f1:	55                   	push   %ebp
f01025f2:	89 e5                	mov    %esp,%ebp
f01025f4:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f01025f7:	ff 75 08             	pushl  0x8(%ebp)
f01025fa:	e8 01 e0 ff ff       	call   f0100600 <cputchar>
	*cnt++;
}
f01025ff:	83 c4 10             	add    $0x10,%esp
f0102602:	c9                   	leave  
f0102603:	c3                   	ret    

f0102604 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0102604:	55                   	push   %ebp
f0102605:	89 e5                	mov    %esp,%ebp
f0102607:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f010260a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0102611:	ff 75 0c             	pushl  0xc(%ebp)
f0102614:	ff 75 08             	pushl  0x8(%ebp)
f0102617:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010261a:	50                   	push   %eax
f010261b:	68 f1 25 10 f0       	push   $0xf01025f1
f0102620:	e8 52 04 00 00       	call   f0102a77 <vprintfmt>
	return cnt;
}
f0102625:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102628:	c9                   	leave  
f0102629:	c3                   	ret    

f010262a <cprintf>:

int
cprintf(const char *fmt, ...)
{
f010262a:	55                   	push   %ebp
f010262b:	89 e5                	mov    %esp,%ebp
f010262d:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0102630:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102633:	50                   	push   %eax
f0102634:	ff 75 08             	pushl  0x8(%ebp)
f0102637:	e8 c8 ff ff ff       	call   f0102604 <vcprintf>
	va_end(ap);

	return cnt;
}
f010263c:	c9                   	leave  
f010263d:	c3                   	ret    

f010263e <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f010263e:	55                   	push   %ebp
f010263f:	89 e5                	mov    %esp,%ebp
f0102641:	57                   	push   %edi
f0102642:	56                   	push   %esi
f0102643:	53                   	push   %ebx
f0102644:	83 ec 14             	sub    $0x14,%esp
f0102647:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010264a:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f010264d:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0102650:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0102653:	8b 1a                	mov    (%edx),%ebx
f0102655:	8b 01                	mov    (%ecx),%eax
f0102657:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010265a:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0102661:	eb 7f                	jmp    f01026e2 <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f0102663:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102666:	01 d8                	add    %ebx,%eax
f0102668:	89 c6                	mov    %eax,%esi
f010266a:	c1 ee 1f             	shr    $0x1f,%esi
f010266d:	01 c6                	add    %eax,%esi
f010266f:	d1 fe                	sar    %esi
f0102671:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0102674:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0102677:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f010267a:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f010267c:	eb 03                	jmp    f0102681 <stab_binsearch+0x43>
			m--;
f010267e:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102681:	39 c3                	cmp    %eax,%ebx
f0102683:	7f 0d                	jg     f0102692 <stab_binsearch+0x54>
f0102685:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0102689:	83 ea 0c             	sub    $0xc,%edx
f010268c:	39 f9                	cmp    %edi,%ecx
f010268e:	75 ee                	jne    f010267e <stab_binsearch+0x40>
f0102690:	eb 05                	jmp    f0102697 <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0102692:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f0102695:	eb 4b                	jmp    f01026e2 <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0102697:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010269a:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010269d:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f01026a1:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01026a4:	76 11                	jbe    f01026b7 <stab_binsearch+0x79>
			*region_left = m;
f01026a6:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01026a9:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f01026ab:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01026ae:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01026b5:	eb 2b                	jmp    f01026e2 <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f01026b7:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01026ba:	73 14                	jae    f01026d0 <stab_binsearch+0x92>
			*region_right = m - 1;
f01026bc:	83 e8 01             	sub    $0x1,%eax
f01026bf:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01026c2:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01026c5:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01026c7:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01026ce:	eb 12                	jmp    f01026e2 <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01026d0:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01026d3:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f01026d5:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f01026d9:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01026db:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f01026e2:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f01026e5:	0f 8e 78 ff ff ff    	jle    f0102663 <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f01026eb:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f01026ef:	75 0f                	jne    f0102700 <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f01026f1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01026f4:	8b 00                	mov    (%eax),%eax
f01026f6:	83 e8 01             	sub    $0x1,%eax
f01026f9:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01026fc:	89 06                	mov    %eax,(%esi)
f01026fe:	eb 2c                	jmp    f010272c <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102700:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102703:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0102705:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0102708:	8b 0e                	mov    (%esi),%ecx
f010270a:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010270d:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0102710:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102713:	eb 03                	jmp    f0102718 <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0102715:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102718:	39 c8                	cmp    %ecx,%eax
f010271a:	7e 0b                	jle    f0102727 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f010271c:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0102720:	83 ea 0c             	sub    $0xc,%edx
f0102723:	39 df                	cmp    %ebx,%edi
f0102725:	75 ee                	jne    f0102715 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f0102727:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010272a:	89 06                	mov    %eax,(%esi)
	}
}
f010272c:	83 c4 14             	add    $0x14,%esp
f010272f:	5b                   	pop    %ebx
f0102730:	5e                   	pop    %esi
f0102731:	5f                   	pop    %edi
f0102732:	5d                   	pop    %ebp
f0102733:	c3                   	ret    

f0102734 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0102734:	55                   	push   %ebp
f0102735:	89 e5                	mov    %esp,%ebp
f0102737:	57                   	push   %edi
f0102738:	56                   	push   %esi
f0102739:	53                   	push   %ebx
f010273a:	83 ec 3c             	sub    $0x3c,%esp
f010273d:	8b 75 08             	mov    0x8(%ebp),%esi
f0102740:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0102743:	c7 03 ee 44 10 f0    	movl   $0xf01044ee,(%ebx)
	info->eip_line = 0;
f0102749:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0102750:	c7 43 08 ee 44 10 f0 	movl   $0xf01044ee,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0102757:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f010275e:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0102761:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0102768:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f010276e:	76 11                	jbe    f0102781 <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102770:	b8 f6 bc 10 f0       	mov    $0xf010bcf6,%eax
f0102775:	3d 75 9f 10 f0       	cmp    $0xf0109f75,%eax
f010277a:	77 19                	ja     f0102795 <debuginfo_eip+0x61>
f010277c:	e9 aa 01 00 00       	jmp    f010292b <debuginfo_eip+0x1f7>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0102781:	83 ec 04             	sub    $0x4,%esp
f0102784:	68 f8 44 10 f0       	push   $0xf01044f8
f0102789:	6a 7f                	push   $0x7f
f010278b:	68 05 45 10 f0       	push   $0xf0104505
f0102790:	e8 f6 d8 ff ff       	call   f010008b <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102795:	80 3d f5 bc 10 f0 00 	cmpb   $0x0,0xf010bcf5
f010279c:	0f 85 90 01 00 00    	jne    f0102932 <debuginfo_eip+0x1fe>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f01027a2:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f01027a9:	b8 74 9f 10 f0       	mov    $0xf0109f74,%eax
f01027ae:	2d 24 47 10 f0       	sub    $0xf0104724,%eax
f01027b3:	c1 f8 02             	sar    $0x2,%eax
f01027b6:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f01027bc:	83 e8 01             	sub    $0x1,%eax
f01027bf:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f01027c2:	83 ec 08             	sub    $0x8,%esp
f01027c5:	56                   	push   %esi
f01027c6:	6a 64                	push   $0x64
f01027c8:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f01027cb:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01027ce:	b8 24 47 10 f0       	mov    $0xf0104724,%eax
f01027d3:	e8 66 fe ff ff       	call   f010263e <stab_binsearch>
	if (lfile == 0)
f01027d8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01027db:	83 c4 10             	add    $0x10,%esp
f01027de:	85 c0                	test   %eax,%eax
f01027e0:	0f 84 53 01 00 00    	je     f0102939 <debuginfo_eip+0x205>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f01027e6:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f01027e9:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01027ec:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f01027ef:	83 ec 08             	sub    $0x8,%esp
f01027f2:	56                   	push   %esi
f01027f3:	6a 24                	push   $0x24
f01027f5:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f01027f8:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01027fb:	b8 24 47 10 f0       	mov    $0xf0104724,%eax
f0102800:	e8 39 fe ff ff       	call   f010263e <stab_binsearch>

	if (lfun <= rfun) {
f0102805:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0102808:	8b 55 d8             	mov    -0x28(%ebp),%edx
f010280b:	83 c4 10             	add    $0x10,%esp
f010280e:	39 d0                	cmp    %edx,%eax
f0102810:	7f 40                	jg     f0102852 <debuginfo_eip+0x11e>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0102812:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f0102815:	c1 e1 02             	shl    $0x2,%ecx
f0102818:	8d b9 24 47 10 f0    	lea    -0xfefb8dc(%ecx),%edi
f010281e:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f0102821:	8b b9 24 47 10 f0    	mov    -0xfefb8dc(%ecx),%edi
f0102827:	b9 f6 bc 10 f0       	mov    $0xf010bcf6,%ecx
f010282c:	81 e9 75 9f 10 f0    	sub    $0xf0109f75,%ecx
f0102832:	39 cf                	cmp    %ecx,%edi
f0102834:	73 09                	jae    f010283f <debuginfo_eip+0x10b>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0102836:	81 c7 75 9f 10 f0    	add    $0xf0109f75,%edi
f010283c:	89 7b 08             	mov    %edi,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f010283f:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0102842:	8b 4f 08             	mov    0x8(%edi),%ecx
f0102845:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0102848:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f010284a:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f010284d:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0102850:	eb 0f                	jmp    f0102861 <debuginfo_eip+0x12d>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0102852:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0102855:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102858:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f010285b:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010285e:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0102861:	83 ec 08             	sub    $0x8,%esp
f0102864:	6a 3a                	push   $0x3a
f0102866:	ff 73 08             	pushl  0x8(%ebx)
f0102869:	e8 59 08 00 00       	call   f01030c7 <strfind>
f010286e:	2b 43 08             	sub    0x8(%ebx),%eax
f0102871:	89 43 0c             	mov    %eax,0xc(%ebx)
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.

	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);	
f0102874:	83 c4 08             	add    $0x8,%esp
f0102877:	56                   	push   %esi
f0102878:	6a 44                	push   $0x44
f010287a:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f010287d:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0102880:	b8 24 47 10 f0       	mov    $0xf0104724,%eax
f0102885:	e8 b4 fd ff ff       	call   f010263e <stab_binsearch>
	if (lline > rline)
f010288a:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f010288d:	83 c4 10             	add    $0x10,%esp
f0102890:	3b 55 d0             	cmp    -0x30(%ebp),%edx
f0102893:	0f 8f a7 00 00 00    	jg     f0102940 <debuginfo_eip+0x20c>
		    return -1;
	info->eip_line = stabs[lline].n_desc;
f0102899:	8d 04 52             	lea    (%edx,%edx,2),%eax
f010289c:	8d 04 85 24 47 10 f0 	lea    -0xfefb8dc(,%eax,4),%eax
f01028a3:	0f b7 48 06          	movzwl 0x6(%eax),%ecx
f01028a7:	89 4b 04             	mov    %ecx,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01028aa:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01028ad:	eb 06                	jmp    f01028b5 <debuginfo_eip+0x181>
f01028af:	83 ea 01             	sub    $0x1,%edx
f01028b2:	83 e8 0c             	sub    $0xc,%eax
f01028b5:	39 d6                	cmp    %edx,%esi
f01028b7:	7f 34                	jg     f01028ed <debuginfo_eip+0x1b9>
	       && stabs[lline].n_type != N_SOL
f01028b9:	0f b6 48 04          	movzbl 0x4(%eax),%ecx
f01028bd:	80 f9 84             	cmp    $0x84,%cl
f01028c0:	74 0b                	je     f01028cd <debuginfo_eip+0x199>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f01028c2:	80 f9 64             	cmp    $0x64,%cl
f01028c5:	75 e8                	jne    f01028af <debuginfo_eip+0x17b>
f01028c7:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f01028cb:	74 e2                	je     f01028af <debuginfo_eip+0x17b>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f01028cd:	8d 04 52             	lea    (%edx,%edx,2),%eax
f01028d0:	8b 14 85 24 47 10 f0 	mov    -0xfefb8dc(,%eax,4),%edx
f01028d7:	b8 f6 bc 10 f0       	mov    $0xf010bcf6,%eax
f01028dc:	2d 75 9f 10 f0       	sub    $0xf0109f75,%eax
f01028e1:	39 c2                	cmp    %eax,%edx
f01028e3:	73 08                	jae    f01028ed <debuginfo_eip+0x1b9>
		info->eip_file = stabstr + stabs[lline].n_strx;
f01028e5:	81 c2 75 9f 10 f0    	add    $0xf0109f75,%edx
f01028eb:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01028ed:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01028f0:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01028f3:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01028f8:	39 f2                	cmp    %esi,%edx
f01028fa:	7d 50                	jge    f010294c <debuginfo_eip+0x218>
		for (lline = lfun + 1;
f01028fc:	83 c2 01             	add    $0x1,%edx
f01028ff:	89 d0                	mov    %edx,%eax
f0102901:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0102904:	8d 14 95 24 47 10 f0 	lea    -0xfefb8dc(,%edx,4),%edx
f010290b:	eb 04                	jmp    f0102911 <debuginfo_eip+0x1dd>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f010290d:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0102911:	39 c6                	cmp    %eax,%esi
f0102913:	7e 32                	jle    f0102947 <debuginfo_eip+0x213>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0102915:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0102919:	83 c0 01             	add    $0x1,%eax
f010291c:	83 c2 0c             	add    $0xc,%edx
f010291f:	80 f9 a0             	cmp    $0xa0,%cl
f0102922:	74 e9                	je     f010290d <debuginfo_eip+0x1d9>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102924:	b8 00 00 00 00       	mov    $0x0,%eax
f0102929:	eb 21                	jmp    f010294c <debuginfo_eip+0x218>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f010292b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102930:	eb 1a                	jmp    f010294c <debuginfo_eip+0x218>
f0102932:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102937:	eb 13                	jmp    f010294c <debuginfo_eip+0x218>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0102939:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010293e:	eb 0c                	jmp    f010294c <debuginfo_eip+0x218>
	//	which one.
	// Your code here.

	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);	
	if (lline > rline)
		    return -1;
f0102940:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102945:	eb 05                	jmp    f010294c <debuginfo_eip+0x218>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102947:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010294c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010294f:	5b                   	pop    %ebx
f0102950:	5e                   	pop    %esi
f0102951:	5f                   	pop    %edi
f0102952:	5d                   	pop    %ebp
f0102953:	c3                   	ret    

f0102954 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0102954:	55                   	push   %ebp
f0102955:	89 e5                	mov    %esp,%ebp
f0102957:	57                   	push   %edi
f0102958:	56                   	push   %esi
f0102959:	53                   	push   %ebx
f010295a:	83 ec 1c             	sub    $0x1c,%esp
f010295d:	89 c7                	mov    %eax,%edi
f010295f:	89 d6                	mov    %edx,%esi
f0102961:	8b 45 08             	mov    0x8(%ebp),%eax
f0102964:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102967:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010296a:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f010296d:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0102970:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102975:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0102978:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f010297b:	39 d3                	cmp    %edx,%ebx
f010297d:	72 05                	jb     f0102984 <printnum+0x30>
f010297f:	39 45 10             	cmp    %eax,0x10(%ebp)
f0102982:	77 45                	ja     f01029c9 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0102984:	83 ec 0c             	sub    $0xc,%esp
f0102987:	ff 75 18             	pushl  0x18(%ebp)
f010298a:	8b 45 14             	mov    0x14(%ebp),%eax
f010298d:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0102990:	53                   	push   %ebx
f0102991:	ff 75 10             	pushl  0x10(%ebp)
f0102994:	83 ec 08             	sub    $0x8,%esp
f0102997:	ff 75 e4             	pushl  -0x1c(%ebp)
f010299a:	ff 75 e0             	pushl  -0x20(%ebp)
f010299d:	ff 75 dc             	pushl  -0x24(%ebp)
f01029a0:	ff 75 d8             	pushl  -0x28(%ebp)
f01029a3:	e8 48 09 00 00       	call   f01032f0 <__udivdi3>
f01029a8:	83 c4 18             	add    $0x18,%esp
f01029ab:	52                   	push   %edx
f01029ac:	50                   	push   %eax
f01029ad:	89 f2                	mov    %esi,%edx
f01029af:	89 f8                	mov    %edi,%eax
f01029b1:	e8 9e ff ff ff       	call   f0102954 <printnum>
f01029b6:	83 c4 20             	add    $0x20,%esp
f01029b9:	eb 18                	jmp    f01029d3 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f01029bb:	83 ec 08             	sub    $0x8,%esp
f01029be:	56                   	push   %esi
f01029bf:	ff 75 18             	pushl  0x18(%ebp)
f01029c2:	ff d7                	call   *%edi
f01029c4:	83 c4 10             	add    $0x10,%esp
f01029c7:	eb 03                	jmp    f01029cc <printnum+0x78>
f01029c9:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f01029cc:	83 eb 01             	sub    $0x1,%ebx
f01029cf:	85 db                	test   %ebx,%ebx
f01029d1:	7f e8                	jg     f01029bb <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f01029d3:	83 ec 08             	sub    $0x8,%esp
f01029d6:	56                   	push   %esi
f01029d7:	83 ec 04             	sub    $0x4,%esp
f01029da:	ff 75 e4             	pushl  -0x1c(%ebp)
f01029dd:	ff 75 e0             	pushl  -0x20(%ebp)
f01029e0:	ff 75 dc             	pushl  -0x24(%ebp)
f01029e3:	ff 75 d8             	pushl  -0x28(%ebp)
f01029e6:	e8 35 0a 00 00       	call   f0103420 <__umoddi3>
f01029eb:	83 c4 14             	add    $0x14,%esp
f01029ee:	0f be 80 13 45 10 f0 	movsbl -0xfefbaed(%eax),%eax
f01029f5:	50                   	push   %eax
f01029f6:	ff d7                	call   *%edi
}
f01029f8:	83 c4 10             	add    $0x10,%esp
f01029fb:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01029fe:	5b                   	pop    %ebx
f01029ff:	5e                   	pop    %esi
f0102a00:	5f                   	pop    %edi
f0102a01:	5d                   	pop    %ebp
f0102a02:	c3                   	ret    

f0102a03 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0102a03:	55                   	push   %ebp
f0102a04:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0102a06:	83 fa 01             	cmp    $0x1,%edx
f0102a09:	7e 0e                	jle    f0102a19 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0102a0b:	8b 10                	mov    (%eax),%edx
f0102a0d:	8d 4a 08             	lea    0x8(%edx),%ecx
f0102a10:	89 08                	mov    %ecx,(%eax)
f0102a12:	8b 02                	mov    (%edx),%eax
f0102a14:	8b 52 04             	mov    0x4(%edx),%edx
f0102a17:	eb 22                	jmp    f0102a3b <getuint+0x38>
	else if (lflag)
f0102a19:	85 d2                	test   %edx,%edx
f0102a1b:	74 10                	je     f0102a2d <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0102a1d:	8b 10                	mov    (%eax),%edx
f0102a1f:	8d 4a 04             	lea    0x4(%edx),%ecx
f0102a22:	89 08                	mov    %ecx,(%eax)
f0102a24:	8b 02                	mov    (%edx),%eax
f0102a26:	ba 00 00 00 00       	mov    $0x0,%edx
f0102a2b:	eb 0e                	jmp    f0102a3b <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0102a2d:	8b 10                	mov    (%eax),%edx
f0102a2f:	8d 4a 04             	lea    0x4(%edx),%ecx
f0102a32:	89 08                	mov    %ecx,(%eax)
f0102a34:	8b 02                	mov    (%edx),%eax
f0102a36:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0102a3b:	5d                   	pop    %ebp
f0102a3c:	c3                   	ret    

f0102a3d <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0102a3d:	55                   	push   %ebp
f0102a3e:	89 e5                	mov    %esp,%ebp
f0102a40:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0102a43:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0102a47:	8b 10                	mov    (%eax),%edx
f0102a49:	3b 50 04             	cmp    0x4(%eax),%edx
f0102a4c:	73 0a                	jae    f0102a58 <sprintputch+0x1b>
		*b->buf++ = ch;
f0102a4e:	8d 4a 01             	lea    0x1(%edx),%ecx
f0102a51:	89 08                	mov    %ecx,(%eax)
f0102a53:	8b 45 08             	mov    0x8(%ebp),%eax
f0102a56:	88 02                	mov    %al,(%edx)
}
f0102a58:	5d                   	pop    %ebp
f0102a59:	c3                   	ret    

f0102a5a <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0102a5a:	55                   	push   %ebp
f0102a5b:	89 e5                	mov    %esp,%ebp
f0102a5d:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0102a60:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0102a63:	50                   	push   %eax
f0102a64:	ff 75 10             	pushl  0x10(%ebp)
f0102a67:	ff 75 0c             	pushl  0xc(%ebp)
f0102a6a:	ff 75 08             	pushl  0x8(%ebp)
f0102a6d:	e8 05 00 00 00       	call   f0102a77 <vprintfmt>
	va_end(ap);
}
f0102a72:	83 c4 10             	add    $0x10,%esp
f0102a75:	c9                   	leave  
f0102a76:	c3                   	ret    

f0102a77 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0102a77:	55                   	push   %ebp
f0102a78:	89 e5                	mov    %esp,%ebp
f0102a7a:	57                   	push   %edi
f0102a7b:	56                   	push   %esi
f0102a7c:	53                   	push   %ebx
f0102a7d:	83 ec 2c             	sub    $0x2c,%esp
f0102a80:	8b 75 08             	mov    0x8(%ebp),%esi
f0102a83:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102a86:	8b 7d 10             	mov    0x10(%ebp),%edi
f0102a89:	eb 12                	jmp    f0102a9d <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0102a8b:	85 c0                	test   %eax,%eax
f0102a8d:	0f 84 89 03 00 00    	je     f0102e1c <vprintfmt+0x3a5>
				return;
			putch(ch, putdat);
f0102a93:	83 ec 08             	sub    $0x8,%esp
f0102a96:	53                   	push   %ebx
f0102a97:	50                   	push   %eax
f0102a98:	ff d6                	call   *%esi
f0102a9a:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0102a9d:	83 c7 01             	add    $0x1,%edi
f0102aa0:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0102aa4:	83 f8 25             	cmp    $0x25,%eax
f0102aa7:	75 e2                	jne    f0102a8b <vprintfmt+0x14>
f0102aa9:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0102aad:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0102ab4:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102abb:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0102ac2:	ba 00 00 00 00       	mov    $0x0,%edx
f0102ac7:	eb 07                	jmp    f0102ad0 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102ac9:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0102acc:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102ad0:	8d 47 01             	lea    0x1(%edi),%eax
f0102ad3:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102ad6:	0f b6 07             	movzbl (%edi),%eax
f0102ad9:	0f b6 c8             	movzbl %al,%ecx
f0102adc:	83 e8 23             	sub    $0x23,%eax
f0102adf:	3c 55                	cmp    $0x55,%al
f0102ae1:	0f 87 1a 03 00 00    	ja     f0102e01 <vprintfmt+0x38a>
f0102ae7:	0f b6 c0             	movzbl %al,%eax
f0102aea:	ff 24 85 a0 45 10 f0 	jmp    *-0xfefba60(,%eax,4)
f0102af1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0102af4:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0102af8:	eb d6                	jmp    f0102ad0 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102afa:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102afd:	b8 00 00 00 00       	mov    $0x0,%eax
f0102b02:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0102b05:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0102b08:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f0102b0c:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0102b0f:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0102b12:	83 fa 09             	cmp    $0x9,%edx
f0102b15:	77 39                	ja     f0102b50 <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0102b17:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0102b1a:	eb e9                	jmp    f0102b05 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0102b1c:	8b 45 14             	mov    0x14(%ebp),%eax
f0102b1f:	8d 48 04             	lea    0x4(%eax),%ecx
f0102b22:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0102b25:	8b 00                	mov    (%eax),%eax
f0102b27:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102b2a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0102b2d:	eb 27                	jmp    f0102b56 <vprintfmt+0xdf>
f0102b2f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102b32:	85 c0                	test   %eax,%eax
f0102b34:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102b39:	0f 49 c8             	cmovns %eax,%ecx
f0102b3c:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102b3f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102b42:	eb 8c                	jmp    f0102ad0 <vprintfmt+0x59>
f0102b44:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0102b47:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0102b4e:	eb 80                	jmp    f0102ad0 <vprintfmt+0x59>
f0102b50:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0102b53:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0102b56:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102b5a:	0f 89 70 ff ff ff    	jns    f0102ad0 <vprintfmt+0x59>
				width = precision, precision = -1;
f0102b60:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102b63:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102b66:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102b6d:	e9 5e ff ff ff       	jmp    f0102ad0 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0102b72:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102b75:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0102b78:	e9 53 ff ff ff       	jmp    f0102ad0 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0102b7d:	8b 45 14             	mov    0x14(%ebp),%eax
f0102b80:	8d 50 04             	lea    0x4(%eax),%edx
f0102b83:	89 55 14             	mov    %edx,0x14(%ebp)
f0102b86:	83 ec 08             	sub    $0x8,%esp
f0102b89:	53                   	push   %ebx
f0102b8a:	ff 30                	pushl  (%eax)
f0102b8c:	ff d6                	call   *%esi
			break;
f0102b8e:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102b91:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0102b94:	e9 04 ff ff ff       	jmp    f0102a9d <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0102b99:	8b 45 14             	mov    0x14(%ebp),%eax
f0102b9c:	8d 50 04             	lea    0x4(%eax),%edx
f0102b9f:	89 55 14             	mov    %edx,0x14(%ebp)
f0102ba2:	8b 00                	mov    (%eax),%eax
f0102ba4:	99                   	cltd   
f0102ba5:	31 d0                	xor    %edx,%eax
f0102ba7:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0102ba9:	83 f8 06             	cmp    $0x6,%eax
f0102bac:	7f 0b                	jg     f0102bb9 <vprintfmt+0x142>
f0102bae:	8b 14 85 f8 46 10 f0 	mov    -0xfefb908(,%eax,4),%edx
f0102bb5:	85 d2                	test   %edx,%edx
f0102bb7:	75 18                	jne    f0102bd1 <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f0102bb9:	50                   	push   %eax
f0102bba:	68 2b 45 10 f0       	push   $0xf010452b
f0102bbf:	53                   	push   %ebx
f0102bc0:	56                   	push   %esi
f0102bc1:	e8 94 fe ff ff       	call   f0102a5a <printfmt>
f0102bc6:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102bc9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0102bcc:	e9 cc fe ff ff       	jmp    f0102a9d <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0102bd1:	52                   	push   %edx
f0102bd2:	68 43 42 10 f0       	push   $0xf0104243
f0102bd7:	53                   	push   %ebx
f0102bd8:	56                   	push   %esi
f0102bd9:	e8 7c fe ff ff       	call   f0102a5a <printfmt>
f0102bde:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102be1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102be4:	e9 b4 fe ff ff       	jmp    f0102a9d <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0102be9:	8b 45 14             	mov    0x14(%ebp),%eax
f0102bec:	8d 50 04             	lea    0x4(%eax),%edx
f0102bef:	89 55 14             	mov    %edx,0x14(%ebp)
f0102bf2:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0102bf4:	85 ff                	test   %edi,%edi
f0102bf6:	b8 24 45 10 f0       	mov    $0xf0104524,%eax
f0102bfb:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0102bfe:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102c02:	0f 8e 94 00 00 00    	jle    f0102c9c <vprintfmt+0x225>
f0102c08:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0102c0c:	0f 84 98 00 00 00    	je     f0102caa <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
f0102c12:	83 ec 08             	sub    $0x8,%esp
f0102c15:	ff 75 d0             	pushl  -0x30(%ebp)
f0102c18:	57                   	push   %edi
f0102c19:	e8 5f 03 00 00       	call   f0102f7d <strnlen>
f0102c1e:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0102c21:	29 c1                	sub    %eax,%ecx
f0102c23:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0102c26:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0102c29:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0102c2d:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102c30:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0102c33:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102c35:	eb 0f                	jmp    f0102c46 <vprintfmt+0x1cf>
					putch(padc, putdat);
f0102c37:	83 ec 08             	sub    $0x8,%esp
f0102c3a:	53                   	push   %ebx
f0102c3b:	ff 75 e0             	pushl  -0x20(%ebp)
f0102c3e:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102c40:	83 ef 01             	sub    $0x1,%edi
f0102c43:	83 c4 10             	add    $0x10,%esp
f0102c46:	85 ff                	test   %edi,%edi
f0102c48:	7f ed                	jg     f0102c37 <vprintfmt+0x1c0>
f0102c4a:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102c4d:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0102c50:	85 c9                	test   %ecx,%ecx
f0102c52:	b8 00 00 00 00       	mov    $0x0,%eax
f0102c57:	0f 49 c1             	cmovns %ecx,%eax
f0102c5a:	29 c1                	sub    %eax,%ecx
f0102c5c:	89 75 08             	mov    %esi,0x8(%ebp)
f0102c5f:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102c62:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102c65:	89 cb                	mov    %ecx,%ebx
f0102c67:	eb 4d                	jmp    f0102cb6 <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0102c69:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0102c6d:	74 1b                	je     f0102c8a <vprintfmt+0x213>
f0102c6f:	0f be c0             	movsbl %al,%eax
f0102c72:	83 e8 20             	sub    $0x20,%eax
f0102c75:	83 f8 5e             	cmp    $0x5e,%eax
f0102c78:	76 10                	jbe    f0102c8a <vprintfmt+0x213>
					putch('?', putdat);
f0102c7a:	83 ec 08             	sub    $0x8,%esp
f0102c7d:	ff 75 0c             	pushl  0xc(%ebp)
f0102c80:	6a 3f                	push   $0x3f
f0102c82:	ff 55 08             	call   *0x8(%ebp)
f0102c85:	83 c4 10             	add    $0x10,%esp
f0102c88:	eb 0d                	jmp    f0102c97 <vprintfmt+0x220>
				else
					putch(ch, putdat);
f0102c8a:	83 ec 08             	sub    $0x8,%esp
f0102c8d:	ff 75 0c             	pushl  0xc(%ebp)
f0102c90:	52                   	push   %edx
f0102c91:	ff 55 08             	call   *0x8(%ebp)
f0102c94:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0102c97:	83 eb 01             	sub    $0x1,%ebx
f0102c9a:	eb 1a                	jmp    f0102cb6 <vprintfmt+0x23f>
f0102c9c:	89 75 08             	mov    %esi,0x8(%ebp)
f0102c9f:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102ca2:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102ca5:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0102ca8:	eb 0c                	jmp    f0102cb6 <vprintfmt+0x23f>
f0102caa:	89 75 08             	mov    %esi,0x8(%ebp)
f0102cad:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102cb0:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102cb3:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0102cb6:	83 c7 01             	add    $0x1,%edi
f0102cb9:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0102cbd:	0f be d0             	movsbl %al,%edx
f0102cc0:	85 d2                	test   %edx,%edx
f0102cc2:	74 23                	je     f0102ce7 <vprintfmt+0x270>
f0102cc4:	85 f6                	test   %esi,%esi
f0102cc6:	78 a1                	js     f0102c69 <vprintfmt+0x1f2>
f0102cc8:	83 ee 01             	sub    $0x1,%esi
f0102ccb:	79 9c                	jns    f0102c69 <vprintfmt+0x1f2>
f0102ccd:	89 df                	mov    %ebx,%edi
f0102ccf:	8b 75 08             	mov    0x8(%ebp),%esi
f0102cd2:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102cd5:	eb 18                	jmp    f0102cef <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0102cd7:	83 ec 08             	sub    $0x8,%esp
f0102cda:	53                   	push   %ebx
f0102cdb:	6a 20                	push   $0x20
f0102cdd:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0102cdf:	83 ef 01             	sub    $0x1,%edi
f0102ce2:	83 c4 10             	add    $0x10,%esp
f0102ce5:	eb 08                	jmp    f0102cef <vprintfmt+0x278>
f0102ce7:	89 df                	mov    %ebx,%edi
f0102ce9:	8b 75 08             	mov    0x8(%ebp),%esi
f0102cec:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102cef:	85 ff                	test   %edi,%edi
f0102cf1:	7f e4                	jg     f0102cd7 <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102cf3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102cf6:	e9 a2 fd ff ff       	jmp    f0102a9d <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0102cfb:	83 fa 01             	cmp    $0x1,%edx
f0102cfe:	7e 16                	jle    f0102d16 <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f0102d00:	8b 45 14             	mov    0x14(%ebp),%eax
f0102d03:	8d 50 08             	lea    0x8(%eax),%edx
f0102d06:	89 55 14             	mov    %edx,0x14(%ebp)
f0102d09:	8b 50 04             	mov    0x4(%eax),%edx
f0102d0c:	8b 00                	mov    (%eax),%eax
f0102d0e:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102d11:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0102d14:	eb 32                	jmp    f0102d48 <vprintfmt+0x2d1>
	else if (lflag)
f0102d16:	85 d2                	test   %edx,%edx
f0102d18:	74 18                	je     f0102d32 <vprintfmt+0x2bb>
		return va_arg(*ap, long);
f0102d1a:	8b 45 14             	mov    0x14(%ebp),%eax
f0102d1d:	8d 50 04             	lea    0x4(%eax),%edx
f0102d20:	89 55 14             	mov    %edx,0x14(%ebp)
f0102d23:	8b 00                	mov    (%eax),%eax
f0102d25:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102d28:	89 c1                	mov    %eax,%ecx
f0102d2a:	c1 f9 1f             	sar    $0x1f,%ecx
f0102d2d:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0102d30:	eb 16                	jmp    f0102d48 <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
f0102d32:	8b 45 14             	mov    0x14(%ebp),%eax
f0102d35:	8d 50 04             	lea    0x4(%eax),%edx
f0102d38:	89 55 14             	mov    %edx,0x14(%ebp)
f0102d3b:	8b 00                	mov    (%eax),%eax
f0102d3d:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102d40:	89 c1                	mov    %eax,%ecx
f0102d42:	c1 f9 1f             	sar    $0x1f,%ecx
f0102d45:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0102d48:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102d4b:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0102d4e:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0102d53:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0102d57:	79 74                	jns    f0102dcd <vprintfmt+0x356>
				putch('-', putdat);
f0102d59:	83 ec 08             	sub    $0x8,%esp
f0102d5c:	53                   	push   %ebx
f0102d5d:	6a 2d                	push   $0x2d
f0102d5f:	ff d6                	call   *%esi
				num = -(long long) num;
f0102d61:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102d64:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102d67:	f7 d8                	neg    %eax
f0102d69:	83 d2 00             	adc    $0x0,%edx
f0102d6c:	f7 da                	neg    %edx
f0102d6e:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0102d71:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0102d76:	eb 55                	jmp    f0102dcd <vprintfmt+0x356>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0102d78:	8d 45 14             	lea    0x14(%ebp),%eax
f0102d7b:	e8 83 fc ff ff       	call   f0102a03 <getuint>
			base = 10;
f0102d80:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0102d85:	eb 46                	jmp    f0102dcd <vprintfmt+0x356>
		// (unsigned) octal
		case 'o':
			//putch('X', putdat);
			//putch('X', putdat);
			//putch('X', putdat);
			num = getuint(&ap, lflag);
f0102d87:	8d 45 14             	lea    0x14(%ebp),%eax
f0102d8a:	e8 74 fc ff ff       	call   f0102a03 <getuint>
			base = 8;
f0102d8f:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0102d94:	eb 37                	jmp    f0102dcd <vprintfmt+0x356>

		// pointer
		case 'p':
			putch('0', putdat);
f0102d96:	83 ec 08             	sub    $0x8,%esp
f0102d99:	53                   	push   %ebx
f0102d9a:	6a 30                	push   $0x30
f0102d9c:	ff d6                	call   *%esi
			putch('x', putdat);
f0102d9e:	83 c4 08             	add    $0x8,%esp
f0102da1:	53                   	push   %ebx
f0102da2:	6a 78                	push   $0x78
f0102da4:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0102da6:	8b 45 14             	mov    0x14(%ebp),%eax
f0102da9:	8d 50 04             	lea    0x4(%eax),%edx
f0102dac:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0102daf:	8b 00                	mov    (%eax),%eax
f0102db1:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0102db6:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0102db9:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0102dbe:	eb 0d                	jmp    f0102dcd <vprintfmt+0x356>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0102dc0:	8d 45 14             	lea    0x14(%ebp),%eax
f0102dc3:	e8 3b fc ff ff       	call   f0102a03 <getuint>
			base = 16;
f0102dc8:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0102dcd:	83 ec 0c             	sub    $0xc,%esp
f0102dd0:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0102dd4:	57                   	push   %edi
f0102dd5:	ff 75 e0             	pushl  -0x20(%ebp)
f0102dd8:	51                   	push   %ecx
f0102dd9:	52                   	push   %edx
f0102dda:	50                   	push   %eax
f0102ddb:	89 da                	mov    %ebx,%edx
f0102ddd:	89 f0                	mov    %esi,%eax
f0102ddf:	e8 70 fb ff ff       	call   f0102954 <printnum>
			break;
f0102de4:	83 c4 20             	add    $0x20,%esp
f0102de7:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102dea:	e9 ae fc ff ff       	jmp    f0102a9d <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0102def:	83 ec 08             	sub    $0x8,%esp
f0102df2:	53                   	push   %ebx
f0102df3:	51                   	push   %ecx
f0102df4:	ff d6                	call   *%esi
			break;
f0102df6:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102df9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0102dfc:	e9 9c fc ff ff       	jmp    f0102a9d <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0102e01:	83 ec 08             	sub    $0x8,%esp
f0102e04:	53                   	push   %ebx
f0102e05:	6a 25                	push   $0x25
f0102e07:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0102e09:	83 c4 10             	add    $0x10,%esp
f0102e0c:	eb 03                	jmp    f0102e11 <vprintfmt+0x39a>
f0102e0e:	83 ef 01             	sub    $0x1,%edi
f0102e11:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0102e15:	75 f7                	jne    f0102e0e <vprintfmt+0x397>
f0102e17:	e9 81 fc ff ff       	jmp    f0102a9d <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0102e1c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102e1f:	5b                   	pop    %ebx
f0102e20:	5e                   	pop    %esi
f0102e21:	5f                   	pop    %edi
f0102e22:	5d                   	pop    %ebp
f0102e23:	c3                   	ret    

f0102e24 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0102e24:	55                   	push   %ebp
f0102e25:	89 e5                	mov    %esp,%ebp
f0102e27:	83 ec 18             	sub    $0x18,%esp
f0102e2a:	8b 45 08             	mov    0x8(%ebp),%eax
f0102e2d:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0102e30:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0102e33:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0102e37:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0102e3a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0102e41:	85 c0                	test   %eax,%eax
f0102e43:	74 26                	je     f0102e6b <vsnprintf+0x47>
f0102e45:	85 d2                	test   %edx,%edx
f0102e47:	7e 22                	jle    f0102e6b <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0102e49:	ff 75 14             	pushl  0x14(%ebp)
f0102e4c:	ff 75 10             	pushl  0x10(%ebp)
f0102e4f:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0102e52:	50                   	push   %eax
f0102e53:	68 3d 2a 10 f0       	push   $0xf0102a3d
f0102e58:	e8 1a fc ff ff       	call   f0102a77 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0102e5d:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0102e60:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0102e63:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102e66:	83 c4 10             	add    $0x10,%esp
f0102e69:	eb 05                	jmp    f0102e70 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0102e6b:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0102e70:	c9                   	leave  
f0102e71:	c3                   	ret    

f0102e72 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0102e72:	55                   	push   %ebp
f0102e73:	89 e5                	mov    %esp,%ebp
f0102e75:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0102e78:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0102e7b:	50                   	push   %eax
f0102e7c:	ff 75 10             	pushl  0x10(%ebp)
f0102e7f:	ff 75 0c             	pushl  0xc(%ebp)
f0102e82:	ff 75 08             	pushl  0x8(%ebp)
f0102e85:	e8 9a ff ff ff       	call   f0102e24 <vsnprintf>
	va_end(ap);

	return rc;
}
f0102e8a:	c9                   	leave  
f0102e8b:	c3                   	ret    

f0102e8c <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0102e8c:	55                   	push   %ebp
f0102e8d:	89 e5                	mov    %esp,%ebp
f0102e8f:	57                   	push   %edi
f0102e90:	56                   	push   %esi
f0102e91:	53                   	push   %ebx
f0102e92:	83 ec 0c             	sub    $0xc,%esp
f0102e95:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0102e98:	85 c0                	test   %eax,%eax
f0102e9a:	74 11                	je     f0102ead <readline+0x21>
		cprintf("%s", prompt);
f0102e9c:	83 ec 08             	sub    $0x8,%esp
f0102e9f:	50                   	push   %eax
f0102ea0:	68 43 42 10 f0       	push   $0xf0104243
f0102ea5:	e8 80 f7 ff ff       	call   f010262a <cprintf>
f0102eaa:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0102ead:	83 ec 0c             	sub    $0xc,%esp
f0102eb0:	6a 00                	push   $0x0
f0102eb2:	e8 6a d7 ff ff       	call   f0100621 <iscons>
f0102eb7:	89 c7                	mov    %eax,%edi
f0102eb9:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0102ebc:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0102ec1:	e8 4a d7 ff ff       	call   f0100610 <getchar>
f0102ec6:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0102ec8:	85 c0                	test   %eax,%eax
f0102eca:	79 18                	jns    f0102ee4 <readline+0x58>
			cprintf("read error: %e\n", c);
f0102ecc:	83 ec 08             	sub    $0x8,%esp
f0102ecf:	50                   	push   %eax
f0102ed0:	68 14 47 10 f0       	push   $0xf0104714
f0102ed5:	e8 50 f7 ff ff       	call   f010262a <cprintf>
			return NULL;
f0102eda:	83 c4 10             	add    $0x10,%esp
f0102edd:	b8 00 00 00 00       	mov    $0x0,%eax
f0102ee2:	eb 79                	jmp    f0102f5d <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0102ee4:	83 f8 08             	cmp    $0x8,%eax
f0102ee7:	0f 94 c2             	sete   %dl
f0102eea:	83 f8 7f             	cmp    $0x7f,%eax
f0102eed:	0f 94 c0             	sete   %al
f0102ef0:	08 c2                	or     %al,%dl
f0102ef2:	74 1a                	je     f0102f0e <readline+0x82>
f0102ef4:	85 f6                	test   %esi,%esi
f0102ef6:	7e 16                	jle    f0102f0e <readline+0x82>
			if (echoing)
f0102ef8:	85 ff                	test   %edi,%edi
f0102efa:	74 0d                	je     f0102f09 <readline+0x7d>
				cputchar('\b');
f0102efc:	83 ec 0c             	sub    $0xc,%esp
f0102eff:	6a 08                	push   $0x8
f0102f01:	e8 fa d6 ff ff       	call   f0100600 <cputchar>
f0102f06:	83 c4 10             	add    $0x10,%esp
			i--;
f0102f09:	83 ee 01             	sub    $0x1,%esi
f0102f0c:	eb b3                	jmp    f0102ec1 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0102f0e:	83 fb 1f             	cmp    $0x1f,%ebx
f0102f11:	7e 23                	jle    f0102f36 <readline+0xaa>
f0102f13:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0102f19:	7f 1b                	jg     f0102f36 <readline+0xaa>
			if (echoing)
f0102f1b:	85 ff                	test   %edi,%edi
f0102f1d:	74 0c                	je     f0102f2b <readline+0x9f>
				cputchar(c);
f0102f1f:	83 ec 0c             	sub    $0xc,%esp
f0102f22:	53                   	push   %ebx
f0102f23:	e8 d8 d6 ff ff       	call   f0100600 <cputchar>
f0102f28:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0102f2b:	88 9e 40 65 11 f0    	mov    %bl,-0xfee9ac0(%esi)
f0102f31:	8d 76 01             	lea    0x1(%esi),%esi
f0102f34:	eb 8b                	jmp    f0102ec1 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0102f36:	83 fb 0a             	cmp    $0xa,%ebx
f0102f39:	74 05                	je     f0102f40 <readline+0xb4>
f0102f3b:	83 fb 0d             	cmp    $0xd,%ebx
f0102f3e:	75 81                	jne    f0102ec1 <readline+0x35>
			if (echoing)
f0102f40:	85 ff                	test   %edi,%edi
f0102f42:	74 0d                	je     f0102f51 <readline+0xc5>
				cputchar('\n');
f0102f44:	83 ec 0c             	sub    $0xc,%esp
f0102f47:	6a 0a                	push   $0xa
f0102f49:	e8 b2 d6 ff ff       	call   f0100600 <cputchar>
f0102f4e:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0102f51:	c6 86 40 65 11 f0 00 	movb   $0x0,-0xfee9ac0(%esi)
			return buf;
f0102f58:	b8 40 65 11 f0       	mov    $0xf0116540,%eax
		}
	}
}
f0102f5d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102f60:	5b                   	pop    %ebx
f0102f61:	5e                   	pop    %esi
f0102f62:	5f                   	pop    %edi
f0102f63:	5d                   	pop    %ebp
f0102f64:	c3                   	ret    

f0102f65 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0102f65:	55                   	push   %ebp
f0102f66:	89 e5                	mov    %esp,%ebp
f0102f68:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0102f6b:	b8 00 00 00 00       	mov    $0x0,%eax
f0102f70:	eb 03                	jmp    f0102f75 <strlen+0x10>
		n++;
f0102f72:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0102f75:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0102f79:	75 f7                	jne    f0102f72 <strlen+0xd>
		n++;
	return n;
}
f0102f7b:	5d                   	pop    %ebp
f0102f7c:	c3                   	ret    

f0102f7d <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0102f7d:	55                   	push   %ebp
f0102f7e:	89 e5                	mov    %esp,%ebp
f0102f80:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0102f83:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0102f86:	ba 00 00 00 00       	mov    $0x0,%edx
f0102f8b:	eb 03                	jmp    f0102f90 <strnlen+0x13>
		n++;
f0102f8d:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0102f90:	39 c2                	cmp    %eax,%edx
f0102f92:	74 08                	je     f0102f9c <strnlen+0x1f>
f0102f94:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f0102f98:	75 f3                	jne    f0102f8d <strnlen+0x10>
f0102f9a:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0102f9c:	5d                   	pop    %ebp
f0102f9d:	c3                   	ret    

f0102f9e <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0102f9e:	55                   	push   %ebp
f0102f9f:	89 e5                	mov    %esp,%ebp
f0102fa1:	53                   	push   %ebx
f0102fa2:	8b 45 08             	mov    0x8(%ebp),%eax
f0102fa5:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0102fa8:	89 c2                	mov    %eax,%edx
f0102faa:	83 c2 01             	add    $0x1,%edx
f0102fad:	83 c1 01             	add    $0x1,%ecx
f0102fb0:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0102fb4:	88 5a ff             	mov    %bl,-0x1(%edx)
f0102fb7:	84 db                	test   %bl,%bl
f0102fb9:	75 ef                	jne    f0102faa <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0102fbb:	5b                   	pop    %ebx
f0102fbc:	5d                   	pop    %ebp
f0102fbd:	c3                   	ret    

f0102fbe <strcat>:

char *
strcat(char *dst, const char *src)
{
f0102fbe:	55                   	push   %ebp
f0102fbf:	89 e5                	mov    %esp,%ebp
f0102fc1:	53                   	push   %ebx
f0102fc2:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0102fc5:	53                   	push   %ebx
f0102fc6:	e8 9a ff ff ff       	call   f0102f65 <strlen>
f0102fcb:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0102fce:	ff 75 0c             	pushl  0xc(%ebp)
f0102fd1:	01 d8                	add    %ebx,%eax
f0102fd3:	50                   	push   %eax
f0102fd4:	e8 c5 ff ff ff       	call   f0102f9e <strcpy>
	return dst;
}
f0102fd9:	89 d8                	mov    %ebx,%eax
f0102fdb:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102fde:	c9                   	leave  
f0102fdf:	c3                   	ret    

f0102fe0 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0102fe0:	55                   	push   %ebp
f0102fe1:	89 e5                	mov    %esp,%ebp
f0102fe3:	56                   	push   %esi
f0102fe4:	53                   	push   %ebx
f0102fe5:	8b 75 08             	mov    0x8(%ebp),%esi
f0102fe8:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0102feb:	89 f3                	mov    %esi,%ebx
f0102fed:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0102ff0:	89 f2                	mov    %esi,%edx
f0102ff2:	eb 0f                	jmp    f0103003 <strncpy+0x23>
		*dst++ = *src;
f0102ff4:	83 c2 01             	add    $0x1,%edx
f0102ff7:	0f b6 01             	movzbl (%ecx),%eax
f0102ffa:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0102ffd:	80 39 01             	cmpb   $0x1,(%ecx)
f0103000:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103003:	39 da                	cmp    %ebx,%edx
f0103005:	75 ed                	jne    f0102ff4 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0103007:	89 f0                	mov    %esi,%eax
f0103009:	5b                   	pop    %ebx
f010300a:	5e                   	pop    %esi
f010300b:	5d                   	pop    %ebp
f010300c:	c3                   	ret    

f010300d <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010300d:	55                   	push   %ebp
f010300e:	89 e5                	mov    %esp,%ebp
f0103010:	56                   	push   %esi
f0103011:	53                   	push   %ebx
f0103012:	8b 75 08             	mov    0x8(%ebp),%esi
f0103015:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103018:	8b 55 10             	mov    0x10(%ebp),%edx
f010301b:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f010301d:	85 d2                	test   %edx,%edx
f010301f:	74 21                	je     f0103042 <strlcpy+0x35>
f0103021:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0103025:	89 f2                	mov    %esi,%edx
f0103027:	eb 09                	jmp    f0103032 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0103029:	83 c2 01             	add    $0x1,%edx
f010302c:	83 c1 01             	add    $0x1,%ecx
f010302f:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0103032:	39 c2                	cmp    %eax,%edx
f0103034:	74 09                	je     f010303f <strlcpy+0x32>
f0103036:	0f b6 19             	movzbl (%ecx),%ebx
f0103039:	84 db                	test   %bl,%bl
f010303b:	75 ec                	jne    f0103029 <strlcpy+0x1c>
f010303d:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f010303f:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0103042:	29 f0                	sub    %esi,%eax
}
f0103044:	5b                   	pop    %ebx
f0103045:	5e                   	pop    %esi
f0103046:	5d                   	pop    %ebp
f0103047:	c3                   	ret    

f0103048 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0103048:	55                   	push   %ebp
f0103049:	89 e5                	mov    %esp,%ebp
f010304b:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010304e:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0103051:	eb 06                	jmp    f0103059 <strcmp+0x11>
		p++, q++;
f0103053:	83 c1 01             	add    $0x1,%ecx
f0103056:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0103059:	0f b6 01             	movzbl (%ecx),%eax
f010305c:	84 c0                	test   %al,%al
f010305e:	74 04                	je     f0103064 <strcmp+0x1c>
f0103060:	3a 02                	cmp    (%edx),%al
f0103062:	74 ef                	je     f0103053 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0103064:	0f b6 c0             	movzbl %al,%eax
f0103067:	0f b6 12             	movzbl (%edx),%edx
f010306a:	29 d0                	sub    %edx,%eax
}
f010306c:	5d                   	pop    %ebp
f010306d:	c3                   	ret    

f010306e <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f010306e:	55                   	push   %ebp
f010306f:	89 e5                	mov    %esp,%ebp
f0103071:	53                   	push   %ebx
f0103072:	8b 45 08             	mov    0x8(%ebp),%eax
f0103075:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103078:	89 c3                	mov    %eax,%ebx
f010307a:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f010307d:	eb 06                	jmp    f0103085 <strncmp+0x17>
		n--, p++, q++;
f010307f:	83 c0 01             	add    $0x1,%eax
f0103082:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0103085:	39 d8                	cmp    %ebx,%eax
f0103087:	74 15                	je     f010309e <strncmp+0x30>
f0103089:	0f b6 08             	movzbl (%eax),%ecx
f010308c:	84 c9                	test   %cl,%cl
f010308e:	74 04                	je     f0103094 <strncmp+0x26>
f0103090:	3a 0a                	cmp    (%edx),%cl
f0103092:	74 eb                	je     f010307f <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0103094:	0f b6 00             	movzbl (%eax),%eax
f0103097:	0f b6 12             	movzbl (%edx),%edx
f010309a:	29 d0                	sub    %edx,%eax
f010309c:	eb 05                	jmp    f01030a3 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f010309e:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01030a3:	5b                   	pop    %ebx
f01030a4:	5d                   	pop    %ebp
f01030a5:	c3                   	ret    

f01030a6 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01030a6:	55                   	push   %ebp
f01030a7:	89 e5                	mov    %esp,%ebp
f01030a9:	8b 45 08             	mov    0x8(%ebp),%eax
f01030ac:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01030b0:	eb 07                	jmp    f01030b9 <strchr+0x13>
		if (*s == c)
f01030b2:	38 ca                	cmp    %cl,%dl
f01030b4:	74 0f                	je     f01030c5 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01030b6:	83 c0 01             	add    $0x1,%eax
f01030b9:	0f b6 10             	movzbl (%eax),%edx
f01030bc:	84 d2                	test   %dl,%dl
f01030be:	75 f2                	jne    f01030b2 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f01030c0:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01030c5:	5d                   	pop    %ebp
f01030c6:	c3                   	ret    

f01030c7 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01030c7:	55                   	push   %ebp
f01030c8:	89 e5                	mov    %esp,%ebp
f01030ca:	8b 45 08             	mov    0x8(%ebp),%eax
f01030cd:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01030d1:	eb 03                	jmp    f01030d6 <strfind+0xf>
f01030d3:	83 c0 01             	add    $0x1,%eax
f01030d6:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f01030d9:	38 ca                	cmp    %cl,%dl
f01030db:	74 04                	je     f01030e1 <strfind+0x1a>
f01030dd:	84 d2                	test   %dl,%dl
f01030df:	75 f2                	jne    f01030d3 <strfind+0xc>
			break;
	return (char *) s;
}
f01030e1:	5d                   	pop    %ebp
f01030e2:	c3                   	ret    

f01030e3 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01030e3:	55                   	push   %ebp
f01030e4:	89 e5                	mov    %esp,%ebp
f01030e6:	57                   	push   %edi
f01030e7:	56                   	push   %esi
f01030e8:	53                   	push   %ebx
f01030e9:	8b 7d 08             	mov    0x8(%ebp),%edi
f01030ec:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01030ef:	85 c9                	test   %ecx,%ecx
f01030f1:	74 36                	je     f0103129 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01030f3:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01030f9:	75 28                	jne    f0103123 <memset+0x40>
f01030fb:	f6 c1 03             	test   $0x3,%cl
f01030fe:	75 23                	jne    f0103123 <memset+0x40>
		c &= 0xFF;
f0103100:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0103104:	89 d3                	mov    %edx,%ebx
f0103106:	c1 e3 08             	shl    $0x8,%ebx
f0103109:	89 d6                	mov    %edx,%esi
f010310b:	c1 e6 18             	shl    $0x18,%esi
f010310e:	89 d0                	mov    %edx,%eax
f0103110:	c1 e0 10             	shl    $0x10,%eax
f0103113:	09 f0                	or     %esi,%eax
f0103115:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f0103117:	89 d8                	mov    %ebx,%eax
f0103119:	09 d0                	or     %edx,%eax
f010311b:	c1 e9 02             	shr    $0x2,%ecx
f010311e:	fc                   	cld    
f010311f:	f3 ab                	rep stos %eax,%es:(%edi)
f0103121:	eb 06                	jmp    f0103129 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0103123:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103126:	fc                   	cld    
f0103127:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0103129:	89 f8                	mov    %edi,%eax
f010312b:	5b                   	pop    %ebx
f010312c:	5e                   	pop    %esi
f010312d:	5f                   	pop    %edi
f010312e:	5d                   	pop    %ebp
f010312f:	c3                   	ret    

f0103130 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0103130:	55                   	push   %ebp
f0103131:	89 e5                	mov    %esp,%ebp
f0103133:	57                   	push   %edi
f0103134:	56                   	push   %esi
f0103135:	8b 45 08             	mov    0x8(%ebp),%eax
f0103138:	8b 75 0c             	mov    0xc(%ebp),%esi
f010313b:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f010313e:	39 c6                	cmp    %eax,%esi
f0103140:	73 35                	jae    f0103177 <memmove+0x47>
f0103142:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0103145:	39 d0                	cmp    %edx,%eax
f0103147:	73 2e                	jae    f0103177 <memmove+0x47>
		s += n;
		d += n;
f0103149:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010314c:	89 d6                	mov    %edx,%esi
f010314e:	09 fe                	or     %edi,%esi
f0103150:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0103156:	75 13                	jne    f010316b <memmove+0x3b>
f0103158:	f6 c1 03             	test   $0x3,%cl
f010315b:	75 0e                	jne    f010316b <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f010315d:	83 ef 04             	sub    $0x4,%edi
f0103160:	8d 72 fc             	lea    -0x4(%edx),%esi
f0103163:	c1 e9 02             	shr    $0x2,%ecx
f0103166:	fd                   	std    
f0103167:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103169:	eb 09                	jmp    f0103174 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f010316b:	83 ef 01             	sub    $0x1,%edi
f010316e:	8d 72 ff             	lea    -0x1(%edx),%esi
f0103171:	fd                   	std    
f0103172:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0103174:	fc                   	cld    
f0103175:	eb 1d                	jmp    f0103194 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103177:	89 f2                	mov    %esi,%edx
f0103179:	09 c2                	or     %eax,%edx
f010317b:	f6 c2 03             	test   $0x3,%dl
f010317e:	75 0f                	jne    f010318f <memmove+0x5f>
f0103180:	f6 c1 03             	test   $0x3,%cl
f0103183:	75 0a                	jne    f010318f <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f0103185:	c1 e9 02             	shr    $0x2,%ecx
f0103188:	89 c7                	mov    %eax,%edi
f010318a:	fc                   	cld    
f010318b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010318d:	eb 05                	jmp    f0103194 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f010318f:	89 c7                	mov    %eax,%edi
f0103191:	fc                   	cld    
f0103192:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0103194:	5e                   	pop    %esi
f0103195:	5f                   	pop    %edi
f0103196:	5d                   	pop    %ebp
f0103197:	c3                   	ret    

f0103198 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0103198:	55                   	push   %ebp
f0103199:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f010319b:	ff 75 10             	pushl  0x10(%ebp)
f010319e:	ff 75 0c             	pushl  0xc(%ebp)
f01031a1:	ff 75 08             	pushl  0x8(%ebp)
f01031a4:	e8 87 ff ff ff       	call   f0103130 <memmove>
}
f01031a9:	c9                   	leave  
f01031aa:	c3                   	ret    

f01031ab <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01031ab:	55                   	push   %ebp
f01031ac:	89 e5                	mov    %esp,%ebp
f01031ae:	56                   	push   %esi
f01031af:	53                   	push   %ebx
f01031b0:	8b 45 08             	mov    0x8(%ebp),%eax
f01031b3:	8b 55 0c             	mov    0xc(%ebp),%edx
f01031b6:	89 c6                	mov    %eax,%esi
f01031b8:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01031bb:	eb 1a                	jmp    f01031d7 <memcmp+0x2c>
		if (*s1 != *s2)
f01031bd:	0f b6 08             	movzbl (%eax),%ecx
f01031c0:	0f b6 1a             	movzbl (%edx),%ebx
f01031c3:	38 d9                	cmp    %bl,%cl
f01031c5:	74 0a                	je     f01031d1 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f01031c7:	0f b6 c1             	movzbl %cl,%eax
f01031ca:	0f b6 db             	movzbl %bl,%ebx
f01031cd:	29 d8                	sub    %ebx,%eax
f01031cf:	eb 0f                	jmp    f01031e0 <memcmp+0x35>
		s1++, s2++;
f01031d1:	83 c0 01             	add    $0x1,%eax
f01031d4:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01031d7:	39 f0                	cmp    %esi,%eax
f01031d9:	75 e2                	jne    f01031bd <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01031db:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01031e0:	5b                   	pop    %ebx
f01031e1:	5e                   	pop    %esi
f01031e2:	5d                   	pop    %ebp
f01031e3:	c3                   	ret    

f01031e4 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01031e4:	55                   	push   %ebp
f01031e5:	89 e5                	mov    %esp,%ebp
f01031e7:	53                   	push   %ebx
f01031e8:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f01031eb:	89 c1                	mov    %eax,%ecx
f01031ed:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f01031f0:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01031f4:	eb 0a                	jmp    f0103200 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f01031f6:	0f b6 10             	movzbl (%eax),%edx
f01031f9:	39 da                	cmp    %ebx,%edx
f01031fb:	74 07                	je     f0103204 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01031fd:	83 c0 01             	add    $0x1,%eax
f0103200:	39 c8                	cmp    %ecx,%eax
f0103202:	72 f2                	jb     f01031f6 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0103204:	5b                   	pop    %ebx
f0103205:	5d                   	pop    %ebp
f0103206:	c3                   	ret    

f0103207 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0103207:	55                   	push   %ebp
f0103208:	89 e5                	mov    %esp,%ebp
f010320a:	57                   	push   %edi
f010320b:	56                   	push   %esi
f010320c:	53                   	push   %ebx
f010320d:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103210:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103213:	eb 03                	jmp    f0103218 <strtol+0x11>
		s++;
f0103215:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103218:	0f b6 01             	movzbl (%ecx),%eax
f010321b:	3c 20                	cmp    $0x20,%al
f010321d:	74 f6                	je     f0103215 <strtol+0xe>
f010321f:	3c 09                	cmp    $0x9,%al
f0103221:	74 f2                	je     f0103215 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0103223:	3c 2b                	cmp    $0x2b,%al
f0103225:	75 0a                	jne    f0103231 <strtol+0x2a>
		s++;
f0103227:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f010322a:	bf 00 00 00 00       	mov    $0x0,%edi
f010322f:	eb 11                	jmp    f0103242 <strtol+0x3b>
f0103231:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0103236:	3c 2d                	cmp    $0x2d,%al
f0103238:	75 08                	jne    f0103242 <strtol+0x3b>
		s++, neg = 1;
f010323a:	83 c1 01             	add    $0x1,%ecx
f010323d:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0103242:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0103248:	75 15                	jne    f010325f <strtol+0x58>
f010324a:	80 39 30             	cmpb   $0x30,(%ecx)
f010324d:	75 10                	jne    f010325f <strtol+0x58>
f010324f:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0103253:	75 7c                	jne    f01032d1 <strtol+0xca>
		s += 2, base = 16;
f0103255:	83 c1 02             	add    $0x2,%ecx
f0103258:	bb 10 00 00 00       	mov    $0x10,%ebx
f010325d:	eb 16                	jmp    f0103275 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f010325f:	85 db                	test   %ebx,%ebx
f0103261:	75 12                	jne    f0103275 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0103263:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0103268:	80 39 30             	cmpb   $0x30,(%ecx)
f010326b:	75 08                	jne    f0103275 <strtol+0x6e>
		s++, base = 8;
f010326d:	83 c1 01             	add    $0x1,%ecx
f0103270:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f0103275:	b8 00 00 00 00       	mov    $0x0,%eax
f010327a:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f010327d:	0f b6 11             	movzbl (%ecx),%edx
f0103280:	8d 72 d0             	lea    -0x30(%edx),%esi
f0103283:	89 f3                	mov    %esi,%ebx
f0103285:	80 fb 09             	cmp    $0x9,%bl
f0103288:	77 08                	ja     f0103292 <strtol+0x8b>
			dig = *s - '0';
f010328a:	0f be d2             	movsbl %dl,%edx
f010328d:	83 ea 30             	sub    $0x30,%edx
f0103290:	eb 22                	jmp    f01032b4 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f0103292:	8d 72 9f             	lea    -0x61(%edx),%esi
f0103295:	89 f3                	mov    %esi,%ebx
f0103297:	80 fb 19             	cmp    $0x19,%bl
f010329a:	77 08                	ja     f01032a4 <strtol+0x9d>
			dig = *s - 'a' + 10;
f010329c:	0f be d2             	movsbl %dl,%edx
f010329f:	83 ea 57             	sub    $0x57,%edx
f01032a2:	eb 10                	jmp    f01032b4 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f01032a4:	8d 72 bf             	lea    -0x41(%edx),%esi
f01032a7:	89 f3                	mov    %esi,%ebx
f01032a9:	80 fb 19             	cmp    $0x19,%bl
f01032ac:	77 16                	ja     f01032c4 <strtol+0xbd>
			dig = *s - 'A' + 10;
f01032ae:	0f be d2             	movsbl %dl,%edx
f01032b1:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f01032b4:	3b 55 10             	cmp    0x10(%ebp),%edx
f01032b7:	7d 0b                	jge    f01032c4 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f01032b9:	83 c1 01             	add    $0x1,%ecx
f01032bc:	0f af 45 10          	imul   0x10(%ebp),%eax
f01032c0:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f01032c2:	eb b9                	jmp    f010327d <strtol+0x76>

	if (endptr)
f01032c4:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01032c8:	74 0d                	je     f01032d7 <strtol+0xd0>
		*endptr = (char *) s;
f01032ca:	8b 75 0c             	mov    0xc(%ebp),%esi
f01032cd:	89 0e                	mov    %ecx,(%esi)
f01032cf:	eb 06                	jmp    f01032d7 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01032d1:	85 db                	test   %ebx,%ebx
f01032d3:	74 98                	je     f010326d <strtol+0x66>
f01032d5:	eb 9e                	jmp    f0103275 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f01032d7:	89 c2                	mov    %eax,%edx
f01032d9:	f7 da                	neg    %edx
f01032db:	85 ff                	test   %edi,%edi
f01032dd:	0f 45 c2             	cmovne %edx,%eax
}
f01032e0:	5b                   	pop    %ebx
f01032e1:	5e                   	pop    %esi
f01032e2:	5f                   	pop    %edi
f01032e3:	5d                   	pop    %ebp
f01032e4:	c3                   	ret    
f01032e5:	66 90                	xchg   %ax,%ax
f01032e7:	66 90                	xchg   %ax,%ax
f01032e9:	66 90                	xchg   %ax,%ax
f01032eb:	66 90                	xchg   %ax,%ax
f01032ed:	66 90                	xchg   %ax,%ax
f01032ef:	90                   	nop

f01032f0 <__udivdi3>:
f01032f0:	55                   	push   %ebp
f01032f1:	57                   	push   %edi
f01032f2:	56                   	push   %esi
f01032f3:	53                   	push   %ebx
f01032f4:	83 ec 1c             	sub    $0x1c,%esp
f01032f7:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f01032fb:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f01032ff:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0103303:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0103307:	85 f6                	test   %esi,%esi
f0103309:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010330d:	89 ca                	mov    %ecx,%edx
f010330f:	89 f8                	mov    %edi,%eax
f0103311:	75 3d                	jne    f0103350 <__udivdi3+0x60>
f0103313:	39 cf                	cmp    %ecx,%edi
f0103315:	0f 87 c5 00 00 00    	ja     f01033e0 <__udivdi3+0xf0>
f010331b:	85 ff                	test   %edi,%edi
f010331d:	89 fd                	mov    %edi,%ebp
f010331f:	75 0b                	jne    f010332c <__udivdi3+0x3c>
f0103321:	b8 01 00 00 00       	mov    $0x1,%eax
f0103326:	31 d2                	xor    %edx,%edx
f0103328:	f7 f7                	div    %edi
f010332a:	89 c5                	mov    %eax,%ebp
f010332c:	89 c8                	mov    %ecx,%eax
f010332e:	31 d2                	xor    %edx,%edx
f0103330:	f7 f5                	div    %ebp
f0103332:	89 c1                	mov    %eax,%ecx
f0103334:	89 d8                	mov    %ebx,%eax
f0103336:	89 cf                	mov    %ecx,%edi
f0103338:	f7 f5                	div    %ebp
f010333a:	89 c3                	mov    %eax,%ebx
f010333c:	89 d8                	mov    %ebx,%eax
f010333e:	89 fa                	mov    %edi,%edx
f0103340:	83 c4 1c             	add    $0x1c,%esp
f0103343:	5b                   	pop    %ebx
f0103344:	5e                   	pop    %esi
f0103345:	5f                   	pop    %edi
f0103346:	5d                   	pop    %ebp
f0103347:	c3                   	ret    
f0103348:	90                   	nop
f0103349:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103350:	39 ce                	cmp    %ecx,%esi
f0103352:	77 74                	ja     f01033c8 <__udivdi3+0xd8>
f0103354:	0f bd fe             	bsr    %esi,%edi
f0103357:	83 f7 1f             	xor    $0x1f,%edi
f010335a:	0f 84 98 00 00 00    	je     f01033f8 <__udivdi3+0x108>
f0103360:	bb 20 00 00 00       	mov    $0x20,%ebx
f0103365:	89 f9                	mov    %edi,%ecx
f0103367:	89 c5                	mov    %eax,%ebp
f0103369:	29 fb                	sub    %edi,%ebx
f010336b:	d3 e6                	shl    %cl,%esi
f010336d:	89 d9                	mov    %ebx,%ecx
f010336f:	d3 ed                	shr    %cl,%ebp
f0103371:	89 f9                	mov    %edi,%ecx
f0103373:	d3 e0                	shl    %cl,%eax
f0103375:	09 ee                	or     %ebp,%esi
f0103377:	89 d9                	mov    %ebx,%ecx
f0103379:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010337d:	89 d5                	mov    %edx,%ebp
f010337f:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103383:	d3 ed                	shr    %cl,%ebp
f0103385:	89 f9                	mov    %edi,%ecx
f0103387:	d3 e2                	shl    %cl,%edx
f0103389:	89 d9                	mov    %ebx,%ecx
f010338b:	d3 e8                	shr    %cl,%eax
f010338d:	09 c2                	or     %eax,%edx
f010338f:	89 d0                	mov    %edx,%eax
f0103391:	89 ea                	mov    %ebp,%edx
f0103393:	f7 f6                	div    %esi
f0103395:	89 d5                	mov    %edx,%ebp
f0103397:	89 c3                	mov    %eax,%ebx
f0103399:	f7 64 24 0c          	mull   0xc(%esp)
f010339d:	39 d5                	cmp    %edx,%ebp
f010339f:	72 10                	jb     f01033b1 <__udivdi3+0xc1>
f01033a1:	8b 74 24 08          	mov    0x8(%esp),%esi
f01033a5:	89 f9                	mov    %edi,%ecx
f01033a7:	d3 e6                	shl    %cl,%esi
f01033a9:	39 c6                	cmp    %eax,%esi
f01033ab:	73 07                	jae    f01033b4 <__udivdi3+0xc4>
f01033ad:	39 d5                	cmp    %edx,%ebp
f01033af:	75 03                	jne    f01033b4 <__udivdi3+0xc4>
f01033b1:	83 eb 01             	sub    $0x1,%ebx
f01033b4:	31 ff                	xor    %edi,%edi
f01033b6:	89 d8                	mov    %ebx,%eax
f01033b8:	89 fa                	mov    %edi,%edx
f01033ba:	83 c4 1c             	add    $0x1c,%esp
f01033bd:	5b                   	pop    %ebx
f01033be:	5e                   	pop    %esi
f01033bf:	5f                   	pop    %edi
f01033c0:	5d                   	pop    %ebp
f01033c1:	c3                   	ret    
f01033c2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01033c8:	31 ff                	xor    %edi,%edi
f01033ca:	31 db                	xor    %ebx,%ebx
f01033cc:	89 d8                	mov    %ebx,%eax
f01033ce:	89 fa                	mov    %edi,%edx
f01033d0:	83 c4 1c             	add    $0x1c,%esp
f01033d3:	5b                   	pop    %ebx
f01033d4:	5e                   	pop    %esi
f01033d5:	5f                   	pop    %edi
f01033d6:	5d                   	pop    %ebp
f01033d7:	c3                   	ret    
f01033d8:	90                   	nop
f01033d9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01033e0:	89 d8                	mov    %ebx,%eax
f01033e2:	f7 f7                	div    %edi
f01033e4:	31 ff                	xor    %edi,%edi
f01033e6:	89 c3                	mov    %eax,%ebx
f01033e8:	89 d8                	mov    %ebx,%eax
f01033ea:	89 fa                	mov    %edi,%edx
f01033ec:	83 c4 1c             	add    $0x1c,%esp
f01033ef:	5b                   	pop    %ebx
f01033f0:	5e                   	pop    %esi
f01033f1:	5f                   	pop    %edi
f01033f2:	5d                   	pop    %ebp
f01033f3:	c3                   	ret    
f01033f4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01033f8:	39 ce                	cmp    %ecx,%esi
f01033fa:	72 0c                	jb     f0103408 <__udivdi3+0x118>
f01033fc:	31 db                	xor    %ebx,%ebx
f01033fe:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0103402:	0f 87 34 ff ff ff    	ja     f010333c <__udivdi3+0x4c>
f0103408:	bb 01 00 00 00       	mov    $0x1,%ebx
f010340d:	e9 2a ff ff ff       	jmp    f010333c <__udivdi3+0x4c>
f0103412:	66 90                	xchg   %ax,%ax
f0103414:	66 90                	xchg   %ax,%ax
f0103416:	66 90                	xchg   %ax,%ax
f0103418:	66 90                	xchg   %ax,%ax
f010341a:	66 90                	xchg   %ax,%ax
f010341c:	66 90                	xchg   %ax,%ax
f010341e:	66 90                	xchg   %ax,%ax

f0103420 <__umoddi3>:
f0103420:	55                   	push   %ebp
f0103421:	57                   	push   %edi
f0103422:	56                   	push   %esi
f0103423:	53                   	push   %ebx
f0103424:	83 ec 1c             	sub    $0x1c,%esp
f0103427:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010342b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f010342f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0103433:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0103437:	85 d2                	test   %edx,%edx
f0103439:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010343d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103441:	89 f3                	mov    %esi,%ebx
f0103443:	89 3c 24             	mov    %edi,(%esp)
f0103446:	89 74 24 04          	mov    %esi,0x4(%esp)
f010344a:	75 1c                	jne    f0103468 <__umoddi3+0x48>
f010344c:	39 f7                	cmp    %esi,%edi
f010344e:	76 50                	jbe    f01034a0 <__umoddi3+0x80>
f0103450:	89 c8                	mov    %ecx,%eax
f0103452:	89 f2                	mov    %esi,%edx
f0103454:	f7 f7                	div    %edi
f0103456:	89 d0                	mov    %edx,%eax
f0103458:	31 d2                	xor    %edx,%edx
f010345a:	83 c4 1c             	add    $0x1c,%esp
f010345d:	5b                   	pop    %ebx
f010345e:	5e                   	pop    %esi
f010345f:	5f                   	pop    %edi
f0103460:	5d                   	pop    %ebp
f0103461:	c3                   	ret    
f0103462:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103468:	39 f2                	cmp    %esi,%edx
f010346a:	89 d0                	mov    %edx,%eax
f010346c:	77 52                	ja     f01034c0 <__umoddi3+0xa0>
f010346e:	0f bd ea             	bsr    %edx,%ebp
f0103471:	83 f5 1f             	xor    $0x1f,%ebp
f0103474:	75 5a                	jne    f01034d0 <__umoddi3+0xb0>
f0103476:	3b 54 24 04          	cmp    0x4(%esp),%edx
f010347a:	0f 82 e0 00 00 00    	jb     f0103560 <__umoddi3+0x140>
f0103480:	39 0c 24             	cmp    %ecx,(%esp)
f0103483:	0f 86 d7 00 00 00    	jbe    f0103560 <__umoddi3+0x140>
f0103489:	8b 44 24 08          	mov    0x8(%esp),%eax
f010348d:	8b 54 24 04          	mov    0x4(%esp),%edx
f0103491:	83 c4 1c             	add    $0x1c,%esp
f0103494:	5b                   	pop    %ebx
f0103495:	5e                   	pop    %esi
f0103496:	5f                   	pop    %edi
f0103497:	5d                   	pop    %ebp
f0103498:	c3                   	ret    
f0103499:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01034a0:	85 ff                	test   %edi,%edi
f01034a2:	89 fd                	mov    %edi,%ebp
f01034a4:	75 0b                	jne    f01034b1 <__umoddi3+0x91>
f01034a6:	b8 01 00 00 00       	mov    $0x1,%eax
f01034ab:	31 d2                	xor    %edx,%edx
f01034ad:	f7 f7                	div    %edi
f01034af:	89 c5                	mov    %eax,%ebp
f01034b1:	89 f0                	mov    %esi,%eax
f01034b3:	31 d2                	xor    %edx,%edx
f01034b5:	f7 f5                	div    %ebp
f01034b7:	89 c8                	mov    %ecx,%eax
f01034b9:	f7 f5                	div    %ebp
f01034bb:	89 d0                	mov    %edx,%eax
f01034bd:	eb 99                	jmp    f0103458 <__umoddi3+0x38>
f01034bf:	90                   	nop
f01034c0:	89 c8                	mov    %ecx,%eax
f01034c2:	89 f2                	mov    %esi,%edx
f01034c4:	83 c4 1c             	add    $0x1c,%esp
f01034c7:	5b                   	pop    %ebx
f01034c8:	5e                   	pop    %esi
f01034c9:	5f                   	pop    %edi
f01034ca:	5d                   	pop    %ebp
f01034cb:	c3                   	ret    
f01034cc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01034d0:	8b 34 24             	mov    (%esp),%esi
f01034d3:	bf 20 00 00 00       	mov    $0x20,%edi
f01034d8:	89 e9                	mov    %ebp,%ecx
f01034da:	29 ef                	sub    %ebp,%edi
f01034dc:	d3 e0                	shl    %cl,%eax
f01034de:	89 f9                	mov    %edi,%ecx
f01034e0:	89 f2                	mov    %esi,%edx
f01034e2:	d3 ea                	shr    %cl,%edx
f01034e4:	89 e9                	mov    %ebp,%ecx
f01034e6:	09 c2                	or     %eax,%edx
f01034e8:	89 d8                	mov    %ebx,%eax
f01034ea:	89 14 24             	mov    %edx,(%esp)
f01034ed:	89 f2                	mov    %esi,%edx
f01034ef:	d3 e2                	shl    %cl,%edx
f01034f1:	89 f9                	mov    %edi,%ecx
f01034f3:	89 54 24 04          	mov    %edx,0x4(%esp)
f01034f7:	8b 54 24 0c          	mov    0xc(%esp),%edx
f01034fb:	d3 e8                	shr    %cl,%eax
f01034fd:	89 e9                	mov    %ebp,%ecx
f01034ff:	89 c6                	mov    %eax,%esi
f0103501:	d3 e3                	shl    %cl,%ebx
f0103503:	89 f9                	mov    %edi,%ecx
f0103505:	89 d0                	mov    %edx,%eax
f0103507:	d3 e8                	shr    %cl,%eax
f0103509:	89 e9                	mov    %ebp,%ecx
f010350b:	09 d8                	or     %ebx,%eax
f010350d:	89 d3                	mov    %edx,%ebx
f010350f:	89 f2                	mov    %esi,%edx
f0103511:	f7 34 24             	divl   (%esp)
f0103514:	89 d6                	mov    %edx,%esi
f0103516:	d3 e3                	shl    %cl,%ebx
f0103518:	f7 64 24 04          	mull   0x4(%esp)
f010351c:	39 d6                	cmp    %edx,%esi
f010351e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0103522:	89 d1                	mov    %edx,%ecx
f0103524:	89 c3                	mov    %eax,%ebx
f0103526:	72 08                	jb     f0103530 <__umoddi3+0x110>
f0103528:	75 11                	jne    f010353b <__umoddi3+0x11b>
f010352a:	39 44 24 08          	cmp    %eax,0x8(%esp)
f010352e:	73 0b                	jae    f010353b <__umoddi3+0x11b>
f0103530:	2b 44 24 04          	sub    0x4(%esp),%eax
f0103534:	1b 14 24             	sbb    (%esp),%edx
f0103537:	89 d1                	mov    %edx,%ecx
f0103539:	89 c3                	mov    %eax,%ebx
f010353b:	8b 54 24 08          	mov    0x8(%esp),%edx
f010353f:	29 da                	sub    %ebx,%edx
f0103541:	19 ce                	sbb    %ecx,%esi
f0103543:	89 f9                	mov    %edi,%ecx
f0103545:	89 f0                	mov    %esi,%eax
f0103547:	d3 e0                	shl    %cl,%eax
f0103549:	89 e9                	mov    %ebp,%ecx
f010354b:	d3 ea                	shr    %cl,%edx
f010354d:	89 e9                	mov    %ebp,%ecx
f010354f:	d3 ee                	shr    %cl,%esi
f0103551:	09 d0                	or     %edx,%eax
f0103553:	89 f2                	mov    %esi,%edx
f0103555:	83 c4 1c             	add    $0x1c,%esp
f0103558:	5b                   	pop    %ebx
f0103559:	5e                   	pop    %esi
f010355a:	5f                   	pop    %edi
f010355b:	5d                   	pop    %ebp
f010355c:	c3                   	ret    
f010355d:	8d 76 00             	lea    0x0(%esi),%esi
f0103560:	29 f9                	sub    %edi,%ecx
f0103562:	19 d6                	sbb    %edx,%esi
f0103564:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103568:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010356c:	e9 18 ff ff ff       	jmp    f0103489 <__umoddi3+0x69>
