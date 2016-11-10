
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
f0100015:	b8 00 20 11 00       	mov    $0x112000,%eax
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
f0100034:	bc 00 20 11 f0       	mov    $0xf0112000,%esp

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
f0100046:	b8 50 49 11 f0       	mov    $0xf0114950,%eax
f010004b:	2d 00 43 11 f0       	sub    $0xf0114300,%eax
f0100050:	50                   	push   %eax
f0100051:	6a 00                	push   $0x0
f0100053:	68 00 43 11 f0       	push   $0xf0114300
f0100058:	e8 7f 1f 00 00       	call   f0101fdc <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 96 04 00 00       	call   f01004f8 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 80 24 10 f0       	push   $0xf0102480
f010006f:	e8 af 14 00 00       	call   f0101523 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 c8 0d 00 00       	call   f0100e41 <mem_init>
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
f0100093:	83 3d 40 49 11 f0 00 	cmpl   $0x0,0xf0114940
f010009a:	75 37                	jne    f01000d3 <_panic+0x48>
		goto dead;
	panicstr = fmt;
f010009c:	89 35 40 49 11 f0    	mov    %esi,0xf0114940

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
f01000b0:	68 9b 24 10 f0       	push   $0xf010249b
f01000b5:	e8 69 14 00 00       	call   f0101523 <cprintf>
	vcprintf(fmt, ap);
f01000ba:	83 c4 08             	add    $0x8,%esp
f01000bd:	53                   	push   %ebx
f01000be:	56                   	push   %esi
f01000bf:	e8 39 14 00 00       	call   f01014fd <vcprintf>
	cprintf("\n");
f01000c4:	c7 04 24 d7 24 10 f0 	movl   $0xf01024d7,(%esp)
f01000cb:	e8 53 14 00 00       	call   f0101523 <cprintf>
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
f01000f2:	68 b3 24 10 f0       	push   $0xf01024b3
f01000f7:	e8 27 14 00 00       	call   f0101523 <cprintf>
	vcprintf(fmt, ap);
f01000fc:	83 c4 08             	add    $0x8,%esp
f01000ff:	53                   	push   %ebx
f0100100:	ff 75 10             	pushl  0x10(%ebp)
f0100103:	e8 f5 13 00 00       	call   f01014fd <vcprintf>
	cprintf("\n");
f0100108:	c7 04 24 d7 24 10 f0 	movl   $0xf01024d7,(%esp)
f010010f:	e8 0f 14 00 00       	call   f0101523 <cprintf>
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
f010014a:	8b 0d 24 45 11 f0    	mov    0xf0114524,%ecx
f0100150:	8d 51 01             	lea    0x1(%ecx),%edx
f0100153:	89 15 24 45 11 f0    	mov    %edx,0xf0114524
f0100159:	88 81 20 43 11 f0    	mov    %al,-0xfeebce0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f010015f:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100165:	75 0a                	jne    f0100171 <cons_intr+0x36>
			cons.wpos = 0;
f0100167:	c7 05 24 45 11 f0 00 	movl   $0x0,0xf0114524
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
f01001a0:	83 0d 00 43 11 f0 40 	orl    $0x40,0xf0114300
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
f01001b8:	8b 0d 00 43 11 f0    	mov    0xf0114300,%ecx
f01001be:	89 cb                	mov    %ecx,%ebx
f01001c0:	83 e3 40             	and    $0x40,%ebx
f01001c3:	83 e0 7f             	and    $0x7f,%eax
f01001c6:	85 db                	test   %ebx,%ebx
f01001c8:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01001cb:	0f b6 d2             	movzbl %dl,%edx
f01001ce:	0f b6 82 20 26 10 f0 	movzbl -0xfefd9e0(%edx),%eax
f01001d5:	83 c8 40             	or     $0x40,%eax
f01001d8:	0f b6 c0             	movzbl %al,%eax
f01001db:	f7 d0                	not    %eax
f01001dd:	21 c8                	and    %ecx,%eax
f01001df:	a3 00 43 11 f0       	mov    %eax,0xf0114300
		return 0;
f01001e4:	b8 00 00 00 00       	mov    $0x0,%eax
f01001e9:	e9 a4 00 00 00       	jmp    f0100292 <kbd_proc_data+0x114>
	} else if (shift & E0ESC) {
f01001ee:	8b 0d 00 43 11 f0    	mov    0xf0114300,%ecx
f01001f4:	f6 c1 40             	test   $0x40,%cl
f01001f7:	74 0e                	je     f0100207 <kbd_proc_data+0x89>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f01001f9:	83 c8 80             	or     $0xffffff80,%eax
f01001fc:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f01001fe:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100201:	89 0d 00 43 11 f0    	mov    %ecx,0xf0114300
	}

	shift |= shiftcode[data];
f0100207:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f010020a:	0f b6 82 20 26 10 f0 	movzbl -0xfefd9e0(%edx),%eax
f0100211:	0b 05 00 43 11 f0    	or     0xf0114300,%eax
f0100217:	0f b6 8a 20 25 10 f0 	movzbl -0xfefdae0(%edx),%ecx
f010021e:	31 c8                	xor    %ecx,%eax
f0100220:	a3 00 43 11 f0       	mov    %eax,0xf0114300

	c = charcode[shift & (CTL | SHIFT)][data];
f0100225:	89 c1                	mov    %eax,%ecx
f0100227:	83 e1 03             	and    $0x3,%ecx
f010022a:	8b 0c 8d 00 25 10 f0 	mov    -0xfefdb00(,%ecx,4),%ecx
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
f0100268:	68 cd 24 10 f0       	push   $0xf01024cd
f010026d:	e8 b1 12 00 00       	call   f0101523 <cprintf>
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
f0100354:	0f b7 05 28 45 11 f0 	movzwl 0xf0114528,%eax
f010035b:	66 85 c0             	test   %ax,%ax
f010035e:	0f 84 e6 00 00 00    	je     f010044a <cons_putc+0x1b3>
			crt_pos--;
f0100364:	83 e8 01             	sub    $0x1,%eax
f0100367:	66 a3 28 45 11 f0    	mov    %ax,0xf0114528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f010036d:	0f b7 c0             	movzwl %ax,%eax
f0100370:	66 81 e7 00 ff       	and    $0xff00,%di
f0100375:	83 cf 20             	or     $0x20,%edi
f0100378:	8b 15 2c 45 11 f0    	mov    0xf011452c,%edx
f010037e:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100382:	eb 78                	jmp    f01003fc <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100384:	66 83 05 28 45 11 f0 	addw   $0x50,0xf0114528
f010038b:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f010038c:	0f b7 05 28 45 11 f0 	movzwl 0xf0114528,%eax
f0100393:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100399:	c1 e8 16             	shr    $0x16,%eax
f010039c:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010039f:	c1 e0 04             	shl    $0x4,%eax
f01003a2:	66 a3 28 45 11 f0    	mov    %ax,0xf0114528
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
f01003de:	0f b7 05 28 45 11 f0 	movzwl 0xf0114528,%eax
f01003e5:	8d 50 01             	lea    0x1(%eax),%edx
f01003e8:	66 89 15 28 45 11 f0 	mov    %dx,0xf0114528
f01003ef:	0f b7 c0             	movzwl %ax,%eax
f01003f2:	8b 15 2c 45 11 f0    	mov    0xf011452c,%edx
f01003f8:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f01003fc:	66 81 3d 28 45 11 f0 	cmpw   $0x7cf,0xf0114528
f0100403:	cf 07 
f0100405:	76 43                	jbe    f010044a <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100407:	a1 2c 45 11 f0       	mov    0xf011452c,%eax
f010040c:	83 ec 04             	sub    $0x4,%esp
f010040f:	68 00 0f 00 00       	push   $0xf00
f0100414:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f010041a:	52                   	push   %edx
f010041b:	50                   	push   %eax
f010041c:	e8 08 1c 00 00       	call   f0102029 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100421:	8b 15 2c 45 11 f0    	mov    0xf011452c,%edx
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
f0100442:	66 83 2d 28 45 11 f0 	subw   $0x50,0xf0114528
f0100449:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f010044a:	8b 0d 30 45 11 f0    	mov    0xf0114530,%ecx
f0100450:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100455:	89 ca                	mov    %ecx,%edx
f0100457:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100458:	0f b7 1d 28 45 11 f0 	movzwl 0xf0114528,%ebx
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
f0100480:	80 3d 34 45 11 f0 00 	cmpb   $0x0,0xf0114534
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
f01004be:	a1 20 45 11 f0       	mov    0xf0114520,%eax
f01004c3:	3b 05 24 45 11 f0    	cmp    0xf0114524,%eax
f01004c9:	74 26                	je     f01004f1 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01004cb:	8d 50 01             	lea    0x1(%eax),%edx
f01004ce:	89 15 20 45 11 f0    	mov    %edx,0xf0114520
f01004d4:	0f b6 88 20 43 11 f0 	movzbl -0xfeebce0(%eax),%ecx
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
f01004e5:	c7 05 20 45 11 f0 00 	movl   $0x0,0xf0114520
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
f010051e:	c7 05 30 45 11 f0 b4 	movl   $0x3b4,0xf0114530
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
f0100536:	c7 05 30 45 11 f0 d4 	movl   $0x3d4,0xf0114530
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
f0100545:	8b 3d 30 45 11 f0    	mov    0xf0114530,%edi
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
f010056a:	89 35 2c 45 11 f0    	mov    %esi,0xf011452c
	crt_pos = pos;
f0100570:	0f b6 c0             	movzbl %al,%eax
f0100573:	09 c8                	or     %ecx,%eax
f0100575:	66 a3 28 45 11 f0    	mov    %ax,0xf0114528
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
f01005d6:	0f 95 05 34 45 11 f0 	setne  0xf0114534
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
f01005eb:	68 d9 24 10 f0       	push   $0xf01024d9
f01005f0:	e8 2e 0f 00 00       	call   f0101523 <cprintf>
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
f0100631:	68 20 27 10 f0       	push   $0xf0102720
f0100636:	68 3e 27 10 f0       	push   $0xf010273e
f010063b:	68 43 27 10 f0       	push   $0xf0102743
f0100640:	e8 de 0e 00 00       	call   f0101523 <cprintf>
f0100645:	83 c4 0c             	add    $0xc,%esp
f0100648:	68 cc 27 10 f0       	push   $0xf01027cc
f010064d:	68 4c 27 10 f0       	push   $0xf010274c
f0100652:	68 43 27 10 f0       	push   $0xf0102743
f0100657:	e8 c7 0e 00 00       	call   f0101523 <cprintf>
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
f0100669:	68 55 27 10 f0       	push   $0xf0102755
f010066e:	e8 b0 0e 00 00       	call   f0101523 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100673:	83 c4 08             	add    $0x8,%esp
f0100676:	68 0c 00 10 00       	push   $0x10000c
f010067b:	68 f4 27 10 f0       	push   $0xf01027f4
f0100680:	e8 9e 0e 00 00       	call   f0101523 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100685:	83 c4 0c             	add    $0xc,%esp
f0100688:	68 0c 00 10 00       	push   $0x10000c
f010068d:	68 0c 00 10 f0       	push   $0xf010000c
f0100692:	68 1c 28 10 f0       	push   $0xf010281c
f0100697:	e8 87 0e 00 00       	call   f0101523 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f010069c:	83 c4 0c             	add    $0xc,%esp
f010069f:	68 61 24 10 00       	push   $0x102461
f01006a4:	68 61 24 10 f0       	push   $0xf0102461
f01006a9:	68 40 28 10 f0       	push   $0xf0102840
f01006ae:	e8 70 0e 00 00       	call   f0101523 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006b3:	83 c4 0c             	add    $0xc,%esp
f01006b6:	68 00 43 11 00       	push   $0x114300
f01006bb:	68 00 43 11 f0       	push   $0xf0114300
f01006c0:	68 64 28 10 f0       	push   $0xf0102864
f01006c5:	e8 59 0e 00 00       	call   f0101523 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006ca:	83 c4 0c             	add    $0xc,%esp
f01006cd:	68 50 49 11 00       	push   $0x114950
f01006d2:	68 50 49 11 f0       	push   $0xf0114950
f01006d7:	68 88 28 10 f0       	push   $0xf0102888
f01006dc:	e8 42 0e 00 00       	call   f0101523 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f01006e1:	b8 4f 4d 11 f0       	mov    $0xf0114d4f,%eax
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
f0100702:	68 ac 28 10 f0       	push   $0xf01028ac
f0100707:	e8 17 0e 00 00       	call   f0101523 <cprintf>
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
f010071d:	68 6e 27 10 f0       	push   $0xf010276e
f0100722:	e8 fc 0d 00 00       	call   f0101523 <cprintf>
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
f0100742:	68 d8 28 10 f0       	push   $0xf01028d8
f0100747:	e8 d7 0d 00 00       	call   f0101523 <cprintf>
				*((uintptr_t *)ebp + 1), *((uintptr_t *)ebp + 2), *((uintptr_t *)ebp + 3), 
			    *((uintptr_t *)ebp + 4), *((uintptr_t *)ebp + 5), *((uintptr_t *)ebp + 6));
		debuginfo_eip(*((uintptr_t *)ebp + 1), &info);
f010074c:	83 c4 18             	add    $0x18,%esp
f010074f:	56                   	push   %esi
f0100750:	ff 73 04             	pushl  0x4(%ebx)
f0100753:	e8 d5 0e 00 00       	call   f010162d <debuginfo_eip>
		cprintf("%s:%d: %.*s+%d\n", info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, 
f0100758:	83 c4 08             	add    $0x8,%esp
f010075b:	8b 43 04             	mov    0x4(%ebx),%eax
f010075e:	2b 45 f0             	sub    -0x10(%ebp),%eax
f0100761:	50                   	push   %eax
f0100762:	ff 75 e8             	pushl  -0x18(%ebp)
f0100765:	ff 75 ec             	pushl  -0x14(%ebp)
f0100768:	ff 75 e4             	pushl  -0x1c(%ebp)
f010076b:	ff 75 e0             	pushl  -0x20(%ebp)
f010076e:	68 80 27 10 f0       	push   $0xf0102780
f0100773:	e8 ab 0d 00 00       	call   f0101523 <cprintf>
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
f0100796:	68 10 29 10 f0       	push   $0xf0102910
f010079b:	e8 83 0d 00 00       	call   f0101523 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01007a0:	c7 04 24 34 29 10 f0 	movl   $0xf0102934,(%esp)
f01007a7:	e8 77 0d 00 00       	call   f0101523 <cprintf>
f01007ac:	83 c4 10             	add    $0x10,%esp

	while (1) {
		buf = readline("K> ");
f01007af:	83 ec 0c             	sub    $0xc,%esp
f01007b2:	68 90 27 10 f0       	push   $0xf0102790
f01007b7:	e8 c9 15 00 00       	call   f0101d85 <readline>
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
f01007eb:	68 94 27 10 f0       	push   $0xf0102794
f01007f0:	e8 aa 17 00 00       	call   f0101f9f <strchr>
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
f010080b:	68 99 27 10 f0       	push   $0xf0102799
f0100810:	e8 0e 0d 00 00       	call   f0101523 <cprintf>
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
f0100834:	68 94 27 10 f0       	push   $0xf0102794
f0100839:	e8 61 17 00 00       	call   f0101f9f <strchr>
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
f010085a:	68 3e 27 10 f0       	push   $0xf010273e
f010085f:	ff 75 a8             	pushl  -0x58(%ebp)
f0100862:	e8 da 16 00 00       	call   f0101f41 <strcmp>
f0100867:	83 c4 10             	add    $0x10,%esp
f010086a:	85 c0                	test   %eax,%eax
f010086c:	74 1e                	je     f010088c <monitor+0xff>
f010086e:	83 ec 08             	sub    $0x8,%esp
f0100871:	68 4c 27 10 f0       	push   $0xf010274c
f0100876:	ff 75 a8             	pushl  -0x58(%ebp)
f0100879:	e8 c3 16 00 00       	call   f0101f41 <strcmp>
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
f01008a1:	ff 14 85 64 29 10 f0 	call   *-0xfefd69c(,%eax,4)
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
f01008ba:	68 b6 27 10 f0       	push   $0xf01027b6
f01008bf:	e8 5f 0c 00 00       	call   f0101523 <cprintf>
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
f01008df:	e8 d8 0b 00 00       	call   f01014bc <mc146818_read>
f01008e4:	89 c6                	mov    %eax,%esi
f01008e6:	83 c3 01             	add    $0x1,%ebx
f01008e9:	89 1c 24             	mov    %ebx,(%esp)
f01008ec:	e8 cb 0b 00 00       	call   f01014bc <mc146818_read>
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
f0100913:	3b 0d 44 49 11 f0    	cmp    0xf0114944,%ecx
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
f0100922:	68 74 29 10 f0       	push   $0xf0102974
f0100927:	68 a7 02 00 00       	push   $0x2a7
f010092c:	68 60 2b 10 f0       	push   $0xf0102b60
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
f0100963:	83 3d 38 45 11 f0 00 	cmpl   $0x0,0xf0114538
f010096a:	75 0f                	jne    f010097b <boot_alloc+0x1a>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f010096c:	b8 4f 59 11 f0       	mov    $0xf011594f,%eax
f0100971:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100976:	a3 38 45 11 f0       	mov    %eax,0xf0114538
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	result = nextfree;
f010097b:	a1 38 45 11 f0       	mov    0xf0114538,%eax
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
f0100993:	68 98 29 10 f0       	push   $0xf0102998
f0100998:	6a 6b                	push   $0x6b
f010099a:	68 60 2b 10 f0       	push   $0xf0102b60
f010099f:	e8 e7 f6 ff ff       	call   f010008b <_panic>
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	result = nextfree;
	if(n > 0){
		if (PADDR(nextfree) + n > (npages + 1) * PGSIZE) {
f01009a4:	8d 9c 10 00 00 00 10 	lea    0x10000000(%eax,%edx,1),%ebx
f01009ab:	8b 0d 44 49 11 f0    	mov    0xf0114944,%ecx
f01009b1:	83 c1 01             	add    $0x1,%ecx
f01009b4:	c1 e1 0c             	shl    $0xc,%ecx
f01009b7:	39 cb                	cmp    %ecx,%ebx
f01009b9:	76 14                	jbe    f01009cf <boot_alloc+0x6e>
			panic("out of memory\n");
f01009bb:	83 ec 04             	sub    $0x4,%esp
f01009be:	68 6c 2b 10 f0       	push   $0xf0102b6c
f01009c3:	6a 6c                	push   $0x6c
f01009c5:	68 60 2b 10 f0       	push   $0xf0102b60
f01009ca:	e8 bc f6 ff ff       	call   f010008b <_panic>
		}
		nextfree = ROUNDUP((char *)nextfree + n, PGSIZE);
f01009cf:	8d 94 10 ff 0f 00 00 	lea    0xfff(%eax,%edx,1),%edx
f01009d6:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01009dc:	89 15 38 45 11 f0    	mov    %edx,0xf0114538
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
f0100a01:	68 bc 29 10 f0       	push   $0xf01029bc
f0100a06:	68 ea 01 00 00       	push   $0x1ea
f0100a0b:	68 60 2b 10 f0       	push   $0xf0102b60
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
f0100a23:	2b 15 4c 49 11 f0    	sub    0xf011494c,%edx
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
f0100a59:	a3 3c 45 11 f0       	mov    %eax,0xf011453c
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
f0100a63:	8b 1d 3c 45 11 f0    	mov    0xf011453c,%ebx
f0100a69:	eb 53                	jmp    f0100abe <check_page_free_list+0xd6>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100a6b:	89 d8                	mov    %ebx,%eax
f0100a6d:	2b 05 4c 49 11 f0    	sub    0xf011494c,%eax
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
f0100a87:	3b 15 44 49 11 f0    	cmp    0xf0114944,%edx
f0100a8d:	72 12                	jb     f0100aa1 <check_page_free_list+0xb9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100a8f:	50                   	push   %eax
f0100a90:	68 74 29 10 f0       	push   $0xf0102974
f0100a95:	6a 52                	push   $0x52
f0100a97:	68 7b 2b 10 f0       	push   $0xf0102b7b
f0100a9c:	e8 ea f5 ff ff       	call   f010008b <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100aa1:	83 ec 04             	sub    $0x4,%esp
f0100aa4:	68 80 00 00 00       	push   $0x80
f0100aa9:	68 97 00 00 00       	push   $0x97
f0100aae:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100ab3:	50                   	push   %eax
f0100ab4:	e8 23 15 00 00       	call   f0101fdc <memset>
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
f0100acf:	8b 15 3c 45 11 f0    	mov    0xf011453c,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100ad5:	8b 0d 4c 49 11 f0    	mov    0xf011494c,%ecx
		assert(pp < pages + npages);
f0100adb:	a1 44 49 11 f0       	mov    0xf0114944,%eax
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
f0100afa:	68 89 2b 10 f0       	push   $0xf0102b89
f0100aff:	68 95 2b 10 f0       	push   $0xf0102b95
f0100b04:	68 04 02 00 00       	push   $0x204
f0100b09:	68 60 2b 10 f0       	push   $0xf0102b60
f0100b0e:	e8 78 f5 ff ff       	call   f010008b <_panic>
		assert(pp < pages + npages);
f0100b13:	39 fa                	cmp    %edi,%edx
f0100b15:	72 19                	jb     f0100b30 <check_page_free_list+0x148>
f0100b17:	68 aa 2b 10 f0       	push   $0xf0102baa
f0100b1c:	68 95 2b 10 f0       	push   $0xf0102b95
f0100b21:	68 05 02 00 00       	push   $0x205
f0100b26:	68 60 2b 10 f0       	push   $0xf0102b60
f0100b2b:	e8 5b f5 ff ff       	call   f010008b <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100b30:	89 d0                	mov    %edx,%eax
f0100b32:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100b35:	a8 07                	test   $0x7,%al
f0100b37:	74 19                	je     f0100b52 <check_page_free_list+0x16a>
f0100b39:	68 e0 29 10 f0       	push   $0xf01029e0
f0100b3e:	68 95 2b 10 f0       	push   $0xf0102b95
f0100b43:	68 06 02 00 00       	push   $0x206
f0100b48:	68 60 2b 10 f0       	push   $0xf0102b60
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
f0100b5c:	68 be 2b 10 f0       	push   $0xf0102bbe
f0100b61:	68 95 2b 10 f0       	push   $0xf0102b95
f0100b66:	68 09 02 00 00       	push   $0x209
f0100b6b:	68 60 2b 10 f0       	push   $0xf0102b60
f0100b70:	e8 16 f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100b75:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100b7a:	75 19                	jne    f0100b95 <check_page_free_list+0x1ad>
f0100b7c:	68 cf 2b 10 f0       	push   $0xf0102bcf
f0100b81:	68 95 2b 10 f0       	push   $0xf0102b95
f0100b86:	68 0a 02 00 00       	push   $0x20a
f0100b8b:	68 60 2b 10 f0       	push   $0xf0102b60
f0100b90:	e8 f6 f4 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100b95:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100b9a:	75 19                	jne    f0100bb5 <check_page_free_list+0x1cd>
f0100b9c:	68 14 2a 10 f0       	push   $0xf0102a14
f0100ba1:	68 95 2b 10 f0       	push   $0xf0102b95
f0100ba6:	68 0b 02 00 00       	push   $0x20b
f0100bab:	68 60 2b 10 f0       	push   $0xf0102b60
f0100bb0:	e8 d6 f4 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100bb5:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100bba:	75 19                	jne    f0100bd5 <check_page_free_list+0x1ed>
f0100bbc:	68 e8 2b 10 f0       	push   $0xf0102be8
f0100bc1:	68 95 2b 10 f0       	push   $0xf0102b95
f0100bc6:	68 0c 02 00 00       	push   $0x20c
f0100bcb:	68 60 2b 10 f0       	push   $0xf0102b60
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
f0100be7:	68 74 29 10 f0       	push   $0xf0102974
f0100bec:	6a 52                	push   $0x52
f0100bee:	68 7b 2b 10 f0       	push   $0xf0102b7b
f0100bf3:	e8 93 f4 ff ff       	call   f010008b <_panic>
f0100bf8:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100bfd:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100c00:	76 1e                	jbe    f0100c20 <check_page_free_list+0x238>
f0100c02:	68 38 2a 10 f0       	push   $0xf0102a38
f0100c07:	68 95 2b 10 f0       	push   $0xf0102b95
f0100c0c:	68 0d 02 00 00       	push   $0x20d
f0100c11:	68 60 2b 10 f0       	push   $0xf0102b60
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
f0100c35:	68 02 2c 10 f0       	push   $0xf0102c02
f0100c3a:	68 95 2b 10 f0       	push   $0xf0102b95
f0100c3f:	68 15 02 00 00       	push   $0x215
f0100c44:	68 60 2b 10 f0       	push   $0xf0102b60
f0100c49:	e8 3d f4 ff ff       	call   f010008b <_panic>
	assert(nfree_extmem > 0);
f0100c4e:	85 db                	test   %ebx,%ebx
f0100c50:	7f 42                	jg     f0100c94 <check_page_free_list+0x2ac>
f0100c52:	68 14 2c 10 f0       	push   $0xf0102c14
f0100c57:	68 95 2b 10 f0       	push   $0xf0102b95
f0100c5c:	68 16 02 00 00       	push   $0x216
f0100c61:	68 60 2b 10 f0       	push   $0xf0102b60
f0100c66:	e8 20 f4 ff ff       	call   f010008b <_panic>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100c6b:	a1 3c 45 11 f0       	mov    0xf011453c,%eax
f0100c70:	85 c0                	test   %eax,%eax
f0100c72:	0f 85 9d fd ff ff    	jne    f0100a15 <check_page_free_list+0x2d>
f0100c78:	e9 81 fd ff ff       	jmp    f01009fe <check_page_free_list+0x16>
f0100c7d:	83 3d 3c 45 11 f0 00 	cmpl   $0x0,0xf011453c
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
f0100ca3:	8b 1d 3c 45 11 f0    	mov    0xf011453c,%ebx
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
f0100cbe:	03 0d 4c 49 11 f0    	add    0xf011494c,%ecx
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
f0100cd1:	03 1d 4c 49 11 f0    	add    0xf011494c,%ebx
f0100cd7:	ba 01 00 00 00       	mov    $0x1,%edx
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	
	size_t i, io_page_i, ext_page_i, free_top;
	for (i = 0; i < npages; i++) {
f0100cdc:	3b 05 44 49 11 f0    	cmp    0xf0114944,%eax
f0100ce2:	72 d1                	jb     f0100cb5 <page_init+0x19>
f0100ce4:	84 d2                	test   %dl,%dl
f0100ce6:	74 06                	je     f0100cee <page_init+0x52>
f0100ce8:	89 1d 3c 45 11 f0    	mov    %ebx,0xf011453c
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
  
	pages[0].pp_link = NULL;
f0100cee:	a1 4c 49 11 f0       	mov    0xf011494c,%eax
f0100cf3:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pages[1].pp_link = NULL;
f0100cf9:	a1 4c 49 11 f0       	mov    0xf011494c,%eax
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
f0100d17:	68 98 29 10 f0       	push   $0xf0102998
f0100d1c:	68 12 01 00 00       	push   $0x112
f0100d21:	68 60 2b 10 f0       	push   $0xf0102b60
f0100d26:	e8 60 f3 ff ff       	call   f010008b <_panic>
f0100d2b:	8d 88 00 00 00 10    	lea    0x10000000(%eax),%ecx
f0100d31:	c1 e9 0c             	shr    $0xc,%ecx

	pages[ext_page_i].pp_link = pages[io_page_i].pp_link;
f0100d34:	a1 4c 49 11 f0       	mov    0xf011494c,%eax
f0100d39:	8b 90 00 05 00 00    	mov    0x500(%eax),%edx
f0100d3f:	89 90 00 08 00 00    	mov    %edx,0x800(%eax)
f0100d45:	b8 00 05 00 00       	mov    $0x500,%eax
	for(i = io_page_i;i < ext_page_i;i++)
		pages[i].pp_link = NULL;
f0100d4a:	8b 15 4c 49 11 f0    	mov    0xf011494c,%edx
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
f0100d61:	a1 4c 49 11 f0       	mov    0xf011494c,%eax
f0100d66:	8b 90 00 08 00 00    	mov    0x800(%eax),%edx
f0100d6c:	89 14 c8             	mov    %edx,(%eax,%ecx,8)
	for (i = ext_page_i; i < free_top; i++)
f0100d6f:	b8 00 01 00 00       	mov    $0x100,%eax
f0100d74:	eb 10                	jmp    f0100d86 <page_init+0xea>
		pages[i].pp_link = NULL;
f0100d76:	8b 15 4c 49 11 f0    	mov    0xf011494c,%edx
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
f0100d96:	8b 1d 3c 45 11 f0    	mov    0xf011453c,%ebx
	if(p){
f0100d9c:	85 db                	test   %ebx,%ebx
f0100d9e:	74 5c                	je     f0100dfc <page_alloc+0x6d>
		page_free_list = p->pp_link;
f0100da0:	8b 03                	mov    (%ebx),%eax
f0100da2:	a3 3c 45 11 f0       	mov    %eax,0xf011453c
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
f0100db5:	2b 05 4c 49 11 f0    	sub    0xf011494c,%eax
f0100dbb:	c1 f8 03             	sar    $0x3,%eax
f0100dbe:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100dc1:	89 c2                	mov    %eax,%edx
f0100dc3:	c1 ea 0c             	shr    $0xc,%edx
f0100dc6:	3b 15 44 49 11 f0    	cmp    0xf0114944,%edx
f0100dcc:	72 12                	jb     f0100de0 <page_alloc+0x51>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100dce:	50                   	push   %eax
f0100dcf:	68 74 29 10 f0       	push   $0xf0102974
f0100dd4:	6a 52                	push   $0x52
f0100dd6:	68 7b 2b 10 f0       	push   $0xf0102b7b
f0100ddb:	e8 ab f2 ff ff       	call   f010008b <_panic>
			memset(page2kva(p), 0, PGSIZE);
f0100de0:	83 ec 04             	sub    $0x4,%esp
f0100de3:	68 00 10 00 00       	push   $0x1000
f0100de8:	6a 00                	push   $0x0
f0100dea:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100def:	50                   	push   %eax
f0100df0:	e8 e7 11 00 00       	call   f0101fdc <memset>
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
f0100e1e:	68 80 2a 10 f0       	push   $0xf0102a80
f0100e23:	68 45 01 00 00       	push   $0x145
f0100e28:	68 60 2b 10 f0       	push   $0xf0102b60
f0100e2d:	e8 59 f2 ff ff       	call   f010008b <_panic>
	}
	pp->pp_link = page_free_list;
f0100e32:	8b 15 3c 45 11 f0    	mov    0xf011453c,%edx
f0100e38:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f0100e3a:	a3 3c 45 11 f0       	mov    %eax,0xf011453c


}
f0100e3f:	c9                   	leave  
f0100e40:	c3                   	ret    

f0100e41 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0100e41:	55                   	push   %ebp
f0100e42:	89 e5                	mov    %esp,%ebp
f0100e44:	57                   	push   %edi
f0100e45:	56                   	push   %esi
f0100e46:	53                   	push   %ebx
f0100e47:	83 ec 1c             	sub    $0x1c,%esp
{
	size_t basemem, extmem, ext16mem, totalmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	basemem = nvram_read(NVRAM_BASELO);
f0100e4a:	b8 15 00 00 00       	mov    $0x15,%eax
f0100e4f:	e8 80 fa ff ff       	call   f01008d4 <nvram_read>
f0100e54:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f0100e56:	b8 17 00 00 00       	mov    $0x17,%eax
f0100e5b:	e8 74 fa ff ff       	call   f01008d4 <nvram_read>
f0100e60:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f0100e62:	b8 34 00 00 00       	mov    $0x34,%eax
f0100e67:	e8 68 fa ff ff       	call   f01008d4 <nvram_read>
f0100e6c:	c1 e0 06             	shl    $0x6,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (ext16mem)
f0100e6f:	85 c0                	test   %eax,%eax
f0100e71:	74 07                	je     f0100e7a <mem_init+0x39>
		totalmem = 16 * 1024 + ext16mem;
f0100e73:	05 00 40 00 00       	add    $0x4000,%eax
f0100e78:	eb 0b                	jmp    f0100e85 <mem_init+0x44>
	else if (extmem)
		totalmem = 1 * 1024 + extmem;
f0100e7a:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f0100e80:	85 f6                	test   %esi,%esi
f0100e82:	0f 44 c3             	cmove  %ebx,%eax
	else
		totalmem = basemem;

	npages = totalmem / (PGSIZE / 1024);
f0100e85:	89 c2                	mov    %eax,%edx
f0100e87:	c1 ea 02             	shr    $0x2,%edx
f0100e8a:	89 15 44 49 11 f0    	mov    %edx,0xf0114944
	npages_basemem = basemem / (PGSIZE / 1024);

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0100e90:	89 c2                	mov    %eax,%edx
f0100e92:	29 da                	sub    %ebx,%edx
f0100e94:	52                   	push   %edx
f0100e95:	53                   	push   %ebx
f0100e96:	50                   	push   %eax
f0100e97:	68 b4 2a 10 f0       	push   $0xf0102ab4
f0100e9c:	e8 82 06 00 00       	call   f0101523 <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0100ea1:	b8 00 10 00 00       	mov    $0x1000,%eax
f0100ea6:	e8 b6 fa ff ff       	call   f0100961 <boot_alloc>
f0100eab:	a3 48 49 11 f0       	mov    %eax,0xf0114948
	memset(kern_pgdir, 0, PGSIZE);
f0100eb0:	83 c4 0c             	add    $0xc,%esp
f0100eb3:	68 00 10 00 00       	push   $0x1000
f0100eb8:	6a 00                	push   $0x0
f0100eba:	50                   	push   %eax
f0100ebb:	e8 1c 11 00 00       	call   f0101fdc <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0100ec0:	a1 48 49 11 f0       	mov    0xf0114948,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100ec5:	83 c4 10             	add    $0x10,%esp
f0100ec8:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100ecd:	77 15                	ja     f0100ee4 <mem_init+0xa3>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100ecf:	50                   	push   %eax
f0100ed0:	68 98 29 10 f0       	push   $0xf0102998
f0100ed5:	68 93 00 00 00       	push   $0x93
f0100eda:	68 60 2b 10 f0       	push   $0xf0102b60
f0100edf:	e8 a7 f1 ff ff       	call   f010008b <_panic>
f0100ee4:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0100eea:	83 ca 05             	or     $0x5,%edx
f0100eed:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	pages = (struct PageInfo *) boot_alloc(npages * sizeof(struct PageInfo));
f0100ef3:	a1 44 49 11 f0       	mov    0xf0114944,%eax
f0100ef8:	c1 e0 03             	shl    $0x3,%eax
f0100efb:	e8 61 fa ff ff       	call   f0100961 <boot_alloc>
f0100f00:	a3 4c 49 11 f0       	mov    %eax,0xf011494c
	memset(pages, 0, npages * sizeof(struct PageInfo));
f0100f05:	83 ec 04             	sub    $0x4,%esp
f0100f08:	8b 0d 44 49 11 f0    	mov    0xf0114944,%ecx
f0100f0e:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f0100f15:	52                   	push   %edx
f0100f16:	6a 00                	push   $0x0
f0100f18:	50                   	push   %eax
f0100f19:	e8 be 10 00 00       	call   f0101fdc <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f0100f1e:	e8 79 fd ff ff       	call   f0100c9c <page_init>

	check_page_free_list(1);
f0100f23:	b8 01 00 00 00       	mov    $0x1,%eax
f0100f28:	e8 bb fa ff ff       	call   f01009e8 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f0100f2d:	83 c4 10             	add    $0x10,%esp
f0100f30:	83 3d 4c 49 11 f0 00 	cmpl   $0x0,0xf011494c
f0100f37:	75 17                	jne    f0100f50 <mem_init+0x10f>
		panic("'pages' is a null pointer!");
f0100f39:	83 ec 04             	sub    $0x4,%esp
f0100f3c:	68 25 2c 10 f0       	push   $0xf0102c25
f0100f41:	68 27 02 00 00       	push   $0x227
f0100f46:	68 60 2b 10 f0       	push   $0xf0102b60
f0100f4b:	e8 3b f1 ff ff       	call   f010008b <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0100f50:	a1 3c 45 11 f0       	mov    0xf011453c,%eax
f0100f55:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100f5a:	eb 05                	jmp    f0100f61 <mem_init+0x120>
		++nfree;
f0100f5c:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0100f5f:	8b 00                	mov    (%eax),%eax
f0100f61:	85 c0                	test   %eax,%eax
f0100f63:	75 f7                	jne    f0100f5c <mem_init+0x11b>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0100f65:	83 ec 0c             	sub    $0xc,%esp
f0100f68:	6a 00                	push   $0x0
f0100f6a:	e8 20 fe ff ff       	call   f0100d8f <page_alloc>
f0100f6f:	89 c7                	mov    %eax,%edi
f0100f71:	83 c4 10             	add    $0x10,%esp
f0100f74:	85 c0                	test   %eax,%eax
f0100f76:	75 19                	jne    f0100f91 <mem_init+0x150>
f0100f78:	68 40 2c 10 f0       	push   $0xf0102c40
f0100f7d:	68 95 2b 10 f0       	push   $0xf0102b95
f0100f82:	68 2f 02 00 00       	push   $0x22f
f0100f87:	68 60 2b 10 f0       	push   $0xf0102b60
f0100f8c:	e8 fa f0 ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f0100f91:	83 ec 0c             	sub    $0xc,%esp
f0100f94:	6a 00                	push   $0x0
f0100f96:	e8 f4 fd ff ff       	call   f0100d8f <page_alloc>
f0100f9b:	89 c6                	mov    %eax,%esi
f0100f9d:	83 c4 10             	add    $0x10,%esp
f0100fa0:	85 c0                	test   %eax,%eax
f0100fa2:	75 19                	jne    f0100fbd <mem_init+0x17c>
f0100fa4:	68 56 2c 10 f0       	push   $0xf0102c56
f0100fa9:	68 95 2b 10 f0       	push   $0xf0102b95
f0100fae:	68 30 02 00 00       	push   $0x230
f0100fb3:	68 60 2b 10 f0       	push   $0xf0102b60
f0100fb8:	e8 ce f0 ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0100fbd:	83 ec 0c             	sub    $0xc,%esp
f0100fc0:	6a 00                	push   $0x0
f0100fc2:	e8 c8 fd ff ff       	call   f0100d8f <page_alloc>
f0100fc7:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100fca:	83 c4 10             	add    $0x10,%esp
f0100fcd:	85 c0                	test   %eax,%eax
f0100fcf:	75 19                	jne    f0100fea <mem_init+0x1a9>
f0100fd1:	68 6c 2c 10 f0       	push   $0xf0102c6c
f0100fd6:	68 95 2b 10 f0       	push   $0xf0102b95
f0100fdb:	68 31 02 00 00       	push   $0x231
f0100fe0:	68 60 2b 10 f0       	push   $0xf0102b60
f0100fe5:	e8 a1 f0 ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0100fea:	39 f7                	cmp    %esi,%edi
f0100fec:	75 19                	jne    f0101007 <mem_init+0x1c6>
f0100fee:	68 82 2c 10 f0       	push   $0xf0102c82
f0100ff3:	68 95 2b 10 f0       	push   $0xf0102b95
f0100ff8:	68 34 02 00 00       	push   $0x234
f0100ffd:	68 60 2b 10 f0       	push   $0xf0102b60
f0101002:	e8 84 f0 ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101007:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010100a:	39 c7                	cmp    %eax,%edi
f010100c:	74 04                	je     f0101012 <mem_init+0x1d1>
f010100e:	39 c6                	cmp    %eax,%esi
f0101010:	75 19                	jne    f010102b <mem_init+0x1ea>
f0101012:	68 f0 2a 10 f0       	push   $0xf0102af0
f0101017:	68 95 2b 10 f0       	push   $0xf0102b95
f010101c:	68 35 02 00 00       	push   $0x235
f0101021:	68 60 2b 10 f0       	push   $0xf0102b60
f0101026:	e8 60 f0 ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010102b:	8b 0d 4c 49 11 f0    	mov    0xf011494c,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101031:	8b 15 44 49 11 f0    	mov    0xf0114944,%edx
f0101037:	c1 e2 0c             	shl    $0xc,%edx
f010103a:	89 f8                	mov    %edi,%eax
f010103c:	29 c8                	sub    %ecx,%eax
f010103e:	c1 f8 03             	sar    $0x3,%eax
f0101041:	c1 e0 0c             	shl    $0xc,%eax
f0101044:	39 d0                	cmp    %edx,%eax
f0101046:	72 19                	jb     f0101061 <mem_init+0x220>
f0101048:	68 94 2c 10 f0       	push   $0xf0102c94
f010104d:	68 95 2b 10 f0       	push   $0xf0102b95
f0101052:	68 36 02 00 00       	push   $0x236
f0101057:	68 60 2b 10 f0       	push   $0xf0102b60
f010105c:	e8 2a f0 ff ff       	call   f010008b <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f0101061:	89 f0                	mov    %esi,%eax
f0101063:	29 c8                	sub    %ecx,%eax
f0101065:	c1 f8 03             	sar    $0x3,%eax
f0101068:	c1 e0 0c             	shl    $0xc,%eax
f010106b:	39 c2                	cmp    %eax,%edx
f010106d:	77 19                	ja     f0101088 <mem_init+0x247>
f010106f:	68 b1 2c 10 f0       	push   $0xf0102cb1
f0101074:	68 95 2b 10 f0       	push   $0xf0102b95
f0101079:	68 37 02 00 00       	push   $0x237
f010107e:	68 60 2b 10 f0       	push   $0xf0102b60
f0101083:	e8 03 f0 ff ff       	call   f010008b <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f0101088:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010108b:	29 c8                	sub    %ecx,%eax
f010108d:	c1 f8 03             	sar    $0x3,%eax
f0101090:	c1 e0 0c             	shl    $0xc,%eax
f0101093:	39 c2                	cmp    %eax,%edx
f0101095:	77 19                	ja     f01010b0 <mem_init+0x26f>
f0101097:	68 ce 2c 10 f0       	push   $0xf0102cce
f010109c:	68 95 2b 10 f0       	push   $0xf0102b95
f01010a1:	68 38 02 00 00       	push   $0x238
f01010a6:	68 60 2b 10 f0       	push   $0xf0102b60
f01010ab:	e8 db ef ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01010b0:	a1 3c 45 11 f0       	mov    0xf011453c,%eax
f01010b5:	89 45 e0             	mov    %eax,-0x20(%ebp)
	page_free_list = 0;
f01010b8:	c7 05 3c 45 11 f0 00 	movl   $0x0,0xf011453c
f01010bf:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01010c2:	83 ec 0c             	sub    $0xc,%esp
f01010c5:	6a 00                	push   $0x0
f01010c7:	e8 c3 fc ff ff       	call   f0100d8f <page_alloc>
f01010cc:	83 c4 10             	add    $0x10,%esp
f01010cf:	85 c0                	test   %eax,%eax
f01010d1:	74 19                	je     f01010ec <mem_init+0x2ab>
f01010d3:	68 eb 2c 10 f0       	push   $0xf0102ceb
f01010d8:	68 95 2b 10 f0       	push   $0xf0102b95
f01010dd:	68 3f 02 00 00       	push   $0x23f
f01010e2:	68 60 2b 10 f0       	push   $0xf0102b60
f01010e7:	e8 9f ef ff ff       	call   f010008b <_panic>

	// free and re-allocate?
	page_free(pp0);
f01010ec:	83 ec 0c             	sub    $0xc,%esp
f01010ef:	57                   	push   %edi
f01010f0:	e8 11 fd ff ff       	call   f0100e06 <page_free>
	page_free(pp1);
f01010f5:	89 34 24             	mov    %esi,(%esp)
f01010f8:	e8 09 fd ff ff       	call   f0100e06 <page_free>
	page_free(pp2);
f01010fd:	83 c4 04             	add    $0x4,%esp
f0101100:	ff 75 e4             	pushl  -0x1c(%ebp)
f0101103:	e8 fe fc ff ff       	call   f0100e06 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101108:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010110f:	e8 7b fc ff ff       	call   f0100d8f <page_alloc>
f0101114:	89 c6                	mov    %eax,%esi
f0101116:	83 c4 10             	add    $0x10,%esp
f0101119:	85 c0                	test   %eax,%eax
f010111b:	75 19                	jne    f0101136 <mem_init+0x2f5>
f010111d:	68 40 2c 10 f0       	push   $0xf0102c40
f0101122:	68 95 2b 10 f0       	push   $0xf0102b95
f0101127:	68 46 02 00 00       	push   $0x246
f010112c:	68 60 2b 10 f0       	push   $0xf0102b60
f0101131:	e8 55 ef ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f0101136:	83 ec 0c             	sub    $0xc,%esp
f0101139:	6a 00                	push   $0x0
f010113b:	e8 4f fc ff ff       	call   f0100d8f <page_alloc>
f0101140:	89 c7                	mov    %eax,%edi
f0101142:	83 c4 10             	add    $0x10,%esp
f0101145:	85 c0                	test   %eax,%eax
f0101147:	75 19                	jne    f0101162 <mem_init+0x321>
f0101149:	68 56 2c 10 f0       	push   $0xf0102c56
f010114e:	68 95 2b 10 f0       	push   $0xf0102b95
f0101153:	68 47 02 00 00       	push   $0x247
f0101158:	68 60 2b 10 f0       	push   $0xf0102b60
f010115d:	e8 29 ef ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0101162:	83 ec 0c             	sub    $0xc,%esp
f0101165:	6a 00                	push   $0x0
f0101167:	e8 23 fc ff ff       	call   f0100d8f <page_alloc>
f010116c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010116f:	83 c4 10             	add    $0x10,%esp
f0101172:	85 c0                	test   %eax,%eax
f0101174:	75 19                	jne    f010118f <mem_init+0x34e>
f0101176:	68 6c 2c 10 f0       	push   $0xf0102c6c
f010117b:	68 95 2b 10 f0       	push   $0xf0102b95
f0101180:	68 48 02 00 00       	push   $0x248
f0101185:	68 60 2b 10 f0       	push   $0xf0102b60
f010118a:	e8 fc ee ff ff       	call   f010008b <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010118f:	39 fe                	cmp    %edi,%esi
f0101191:	75 19                	jne    f01011ac <mem_init+0x36b>
f0101193:	68 82 2c 10 f0       	push   $0xf0102c82
f0101198:	68 95 2b 10 f0       	push   $0xf0102b95
f010119d:	68 4a 02 00 00       	push   $0x24a
f01011a2:	68 60 2b 10 f0       	push   $0xf0102b60
f01011a7:	e8 df ee ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01011ac:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01011af:	39 c6                	cmp    %eax,%esi
f01011b1:	74 04                	je     f01011b7 <mem_init+0x376>
f01011b3:	39 c7                	cmp    %eax,%edi
f01011b5:	75 19                	jne    f01011d0 <mem_init+0x38f>
f01011b7:	68 f0 2a 10 f0       	push   $0xf0102af0
f01011bc:	68 95 2b 10 f0       	push   $0xf0102b95
f01011c1:	68 4b 02 00 00       	push   $0x24b
f01011c6:	68 60 2b 10 f0       	push   $0xf0102b60
f01011cb:	e8 bb ee ff ff       	call   f010008b <_panic>
	assert(!page_alloc(0));
f01011d0:	83 ec 0c             	sub    $0xc,%esp
f01011d3:	6a 00                	push   $0x0
f01011d5:	e8 b5 fb ff ff       	call   f0100d8f <page_alloc>
f01011da:	83 c4 10             	add    $0x10,%esp
f01011dd:	85 c0                	test   %eax,%eax
f01011df:	74 19                	je     f01011fa <mem_init+0x3b9>
f01011e1:	68 eb 2c 10 f0       	push   $0xf0102ceb
f01011e6:	68 95 2b 10 f0       	push   $0xf0102b95
f01011eb:	68 4c 02 00 00       	push   $0x24c
f01011f0:	68 60 2b 10 f0       	push   $0xf0102b60
f01011f5:	e8 91 ee ff ff       	call   f010008b <_panic>
f01011fa:	89 f0                	mov    %esi,%eax
f01011fc:	2b 05 4c 49 11 f0    	sub    0xf011494c,%eax
f0101202:	c1 f8 03             	sar    $0x3,%eax
f0101205:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101208:	89 c2                	mov    %eax,%edx
f010120a:	c1 ea 0c             	shr    $0xc,%edx
f010120d:	3b 15 44 49 11 f0    	cmp    0xf0114944,%edx
f0101213:	72 12                	jb     f0101227 <mem_init+0x3e6>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101215:	50                   	push   %eax
f0101216:	68 74 29 10 f0       	push   $0xf0102974
f010121b:	6a 52                	push   $0x52
f010121d:	68 7b 2b 10 f0       	push   $0xf0102b7b
f0101222:	e8 64 ee ff ff       	call   f010008b <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f0101227:	83 ec 04             	sub    $0x4,%esp
f010122a:	68 00 10 00 00       	push   $0x1000
f010122f:	6a 01                	push   $0x1
f0101231:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101236:	50                   	push   %eax
f0101237:	e8 a0 0d 00 00       	call   f0101fdc <memset>
	page_free(pp0);
f010123c:	89 34 24             	mov    %esi,(%esp)
f010123f:	e8 c2 fb ff ff       	call   f0100e06 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101244:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f010124b:	e8 3f fb ff ff       	call   f0100d8f <page_alloc>
f0101250:	83 c4 10             	add    $0x10,%esp
f0101253:	85 c0                	test   %eax,%eax
f0101255:	75 19                	jne    f0101270 <mem_init+0x42f>
f0101257:	68 fa 2c 10 f0       	push   $0xf0102cfa
f010125c:	68 95 2b 10 f0       	push   $0xf0102b95
f0101261:	68 51 02 00 00       	push   $0x251
f0101266:	68 60 2b 10 f0       	push   $0xf0102b60
f010126b:	e8 1b ee ff ff       	call   f010008b <_panic>
	assert(pp && pp0 == pp);
f0101270:	39 c6                	cmp    %eax,%esi
f0101272:	74 19                	je     f010128d <mem_init+0x44c>
f0101274:	68 18 2d 10 f0       	push   $0xf0102d18
f0101279:	68 95 2b 10 f0       	push   $0xf0102b95
f010127e:	68 52 02 00 00       	push   $0x252
f0101283:	68 60 2b 10 f0       	push   $0xf0102b60
f0101288:	e8 fe ed ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010128d:	89 f0                	mov    %esi,%eax
f010128f:	2b 05 4c 49 11 f0    	sub    0xf011494c,%eax
f0101295:	c1 f8 03             	sar    $0x3,%eax
f0101298:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010129b:	89 c2                	mov    %eax,%edx
f010129d:	c1 ea 0c             	shr    $0xc,%edx
f01012a0:	3b 15 44 49 11 f0    	cmp    0xf0114944,%edx
f01012a6:	72 12                	jb     f01012ba <mem_init+0x479>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01012a8:	50                   	push   %eax
f01012a9:	68 74 29 10 f0       	push   $0xf0102974
f01012ae:	6a 52                	push   $0x52
f01012b0:	68 7b 2b 10 f0       	push   $0xf0102b7b
f01012b5:	e8 d1 ed ff ff       	call   f010008b <_panic>
f01012ba:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f01012c0:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f01012c6:	80 38 00             	cmpb   $0x0,(%eax)
f01012c9:	74 19                	je     f01012e4 <mem_init+0x4a3>
f01012cb:	68 28 2d 10 f0       	push   $0xf0102d28
f01012d0:	68 95 2b 10 f0       	push   $0xf0102b95
f01012d5:	68 55 02 00 00       	push   $0x255
f01012da:	68 60 2b 10 f0       	push   $0xf0102b60
f01012df:	e8 a7 ed ff ff       	call   f010008b <_panic>
f01012e4:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f01012e7:	39 d0                	cmp    %edx,%eax
f01012e9:	75 db                	jne    f01012c6 <mem_init+0x485>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f01012eb:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01012ee:	a3 3c 45 11 f0       	mov    %eax,0xf011453c

	// free the pages we took
	page_free(pp0);
f01012f3:	83 ec 0c             	sub    $0xc,%esp
f01012f6:	56                   	push   %esi
f01012f7:	e8 0a fb ff ff       	call   f0100e06 <page_free>
	page_free(pp1);
f01012fc:	89 3c 24             	mov    %edi,(%esp)
f01012ff:	e8 02 fb ff ff       	call   f0100e06 <page_free>
	page_free(pp2);
f0101304:	83 c4 04             	add    $0x4,%esp
f0101307:	ff 75 e4             	pushl  -0x1c(%ebp)
f010130a:	e8 f7 fa ff ff       	call   f0100e06 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010130f:	a1 3c 45 11 f0       	mov    0xf011453c,%eax
f0101314:	83 c4 10             	add    $0x10,%esp
f0101317:	eb 05                	jmp    f010131e <mem_init+0x4dd>
		--nfree;
f0101319:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010131c:	8b 00                	mov    (%eax),%eax
f010131e:	85 c0                	test   %eax,%eax
f0101320:	75 f7                	jne    f0101319 <mem_init+0x4d8>
		--nfree;
	assert(nfree == 0);
f0101322:	85 db                	test   %ebx,%ebx
f0101324:	74 19                	je     f010133f <mem_init+0x4fe>
f0101326:	68 32 2d 10 f0       	push   $0xf0102d32
f010132b:	68 95 2b 10 f0       	push   $0xf0102b95
f0101330:	68 62 02 00 00       	push   $0x262
f0101335:	68 60 2b 10 f0       	push   $0xf0102b60
f010133a:	e8 4c ed ff ff       	call   f010008b <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f010133f:	83 ec 0c             	sub    $0xc,%esp
f0101342:	68 10 2b 10 f0       	push   $0xf0102b10
f0101347:	e8 d7 01 00 00       	call   f0101523 <cprintf>
	// or page_insert
	page_init();

	check_page_free_list(1);
	check_page_alloc();
	cprintf("checked\n");
f010134c:	c7 04 24 3d 2d 10 f0 	movl   $0xf0102d3d,(%esp)
f0101353:	e8 cb 01 00 00       	call   f0101523 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101358:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010135f:	e8 2b fa ff ff       	call   f0100d8f <page_alloc>
f0101364:	89 c3                	mov    %eax,%ebx
f0101366:	83 c4 10             	add    $0x10,%esp
f0101369:	85 c0                	test   %eax,%eax
f010136b:	75 19                	jne    f0101386 <mem_init+0x545>
f010136d:	68 40 2c 10 f0       	push   $0xf0102c40
f0101372:	68 95 2b 10 f0       	push   $0xf0102b95
f0101377:	68 bb 02 00 00       	push   $0x2bb
f010137c:	68 60 2b 10 f0       	push   $0xf0102b60
f0101381:	e8 05 ed ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f0101386:	83 ec 0c             	sub    $0xc,%esp
f0101389:	6a 00                	push   $0x0
f010138b:	e8 ff f9 ff ff       	call   f0100d8f <page_alloc>
f0101390:	89 c6                	mov    %eax,%esi
f0101392:	83 c4 10             	add    $0x10,%esp
f0101395:	85 c0                	test   %eax,%eax
f0101397:	75 19                	jne    f01013b2 <mem_init+0x571>
f0101399:	68 56 2c 10 f0       	push   $0xf0102c56
f010139e:	68 95 2b 10 f0       	push   $0xf0102b95
f01013a3:	68 bc 02 00 00       	push   $0x2bc
f01013a8:	68 60 2b 10 f0       	push   $0xf0102b60
f01013ad:	e8 d9 ec ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f01013b2:	83 ec 0c             	sub    $0xc,%esp
f01013b5:	6a 00                	push   $0x0
f01013b7:	e8 d3 f9 ff ff       	call   f0100d8f <page_alloc>
f01013bc:	83 c4 10             	add    $0x10,%esp
f01013bf:	85 c0                	test   %eax,%eax
f01013c1:	75 19                	jne    f01013dc <mem_init+0x59b>
f01013c3:	68 6c 2c 10 f0       	push   $0xf0102c6c
f01013c8:	68 95 2b 10 f0       	push   $0xf0102b95
f01013cd:	68 bd 02 00 00       	push   $0x2bd
f01013d2:	68 60 2b 10 f0       	push   $0xf0102b60
f01013d7:	e8 af ec ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01013dc:	39 f3                	cmp    %esi,%ebx
f01013de:	75 19                	jne    f01013f9 <mem_init+0x5b8>
f01013e0:	68 82 2c 10 f0       	push   $0xf0102c82
f01013e5:	68 95 2b 10 f0       	push   $0xf0102b95
f01013ea:	68 c0 02 00 00       	push   $0x2c0
f01013ef:	68 60 2b 10 f0       	push   $0xf0102b60
f01013f4:	e8 92 ec ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01013f9:	39 c6                	cmp    %eax,%esi
f01013fb:	74 04                	je     f0101401 <mem_init+0x5c0>
f01013fd:	39 c3                	cmp    %eax,%ebx
f01013ff:	75 19                	jne    f010141a <mem_init+0x5d9>
f0101401:	68 f0 2a 10 f0       	push   $0xf0102af0
f0101406:	68 95 2b 10 f0       	push   $0xf0102b95
f010140b:	68 c1 02 00 00       	push   $0x2c1
f0101410:	68 60 2b 10 f0       	push   $0xf0102b60
f0101415:	e8 71 ec ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
	page_free_list = 0;
f010141a:	c7 05 3c 45 11 f0 00 	movl   $0x0,0xf011453c
f0101421:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101424:	83 ec 0c             	sub    $0xc,%esp
f0101427:	6a 00                	push   $0x0
f0101429:	e8 61 f9 ff ff       	call   f0100d8f <page_alloc>
f010142e:	83 c4 10             	add    $0x10,%esp
f0101431:	85 c0                	test   %eax,%eax
f0101433:	74 19                	je     f010144e <mem_init+0x60d>
f0101435:	68 eb 2c 10 f0       	push   $0xf0102ceb
f010143a:	68 95 2b 10 f0       	push   $0xf0102b95
f010143f:	68 c8 02 00 00       	push   $0x2c8
f0101444:	68 60 2b 10 f0       	push   $0xf0102b60
f0101449:	e8 3d ec ff ff       	call   f010008b <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f010144e:	68 30 2b 10 f0       	push   $0xf0102b30
f0101453:	68 95 2b 10 f0       	push   $0xf0102b95
f0101458:	68 ce 02 00 00       	push   $0x2ce
f010145d:	68 60 2b 10 f0       	push   $0xf0102b60
f0101462:	e8 24 ec ff ff       	call   f010008b <_panic>

f0101467 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0101467:	55                   	push   %ebp
f0101468:	89 e5                	mov    %esp,%ebp
f010146a:	83 ec 08             	sub    $0x8,%esp
f010146d:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0101470:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0101474:	83 e8 01             	sub    $0x1,%eax
f0101477:	66 89 42 04          	mov    %ax,0x4(%edx)
f010147b:	66 85 c0             	test   %ax,%ax
f010147e:	75 0c                	jne    f010148c <page_decref+0x25>
		page_free(pp);
f0101480:	83 ec 0c             	sub    $0xc,%esp
f0101483:	52                   	push   %edx
f0101484:	e8 7d f9 ff ff       	call   f0100e06 <page_free>
f0101489:	83 c4 10             	add    $0x10,%esp
}
f010148c:	c9                   	leave  
f010148d:	c3                   	ret    

f010148e <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f010148e:	55                   	push   %ebp
f010148f:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return NULL;
}
f0101491:	b8 00 00 00 00       	mov    $0x0,%eax
f0101496:	5d                   	pop    %ebp
f0101497:	c3                   	ret    

f0101498 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f0101498:	55                   	push   %ebp
f0101499:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return 0;
}
f010149b:	b8 00 00 00 00       	mov    $0x0,%eax
f01014a0:	5d                   	pop    %ebp
f01014a1:	c3                   	ret    

f01014a2 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f01014a2:	55                   	push   %ebp
f01014a3:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return NULL;
}
f01014a5:	b8 00 00 00 00       	mov    $0x0,%eax
f01014aa:	5d                   	pop    %ebp
f01014ab:	c3                   	ret    

f01014ac <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f01014ac:	55                   	push   %ebp
f01014ad:	89 e5                	mov    %esp,%ebp
	// Fill this function in
}
f01014af:	5d                   	pop    %ebp
f01014b0:	c3                   	ret    

f01014b1 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f01014b1:	55                   	push   %ebp
f01014b2:	89 e5                	mov    %esp,%ebp
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01014b4:	8b 45 0c             	mov    0xc(%ebp),%eax
f01014b7:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f01014ba:	5d                   	pop    %ebp
f01014bb:	c3                   	ret    

f01014bc <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f01014bc:	55                   	push   %ebp
f01014bd:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01014bf:	ba 70 00 00 00       	mov    $0x70,%edx
f01014c4:	8b 45 08             	mov    0x8(%ebp),%eax
f01014c7:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01014c8:	ba 71 00 00 00       	mov    $0x71,%edx
f01014cd:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f01014ce:	0f b6 c0             	movzbl %al,%eax
}
f01014d1:	5d                   	pop    %ebp
f01014d2:	c3                   	ret    

f01014d3 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f01014d3:	55                   	push   %ebp
f01014d4:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01014d6:	ba 70 00 00 00       	mov    $0x70,%edx
f01014db:	8b 45 08             	mov    0x8(%ebp),%eax
f01014de:	ee                   	out    %al,(%dx)
f01014df:	ba 71 00 00 00       	mov    $0x71,%edx
f01014e4:	8b 45 0c             	mov    0xc(%ebp),%eax
f01014e7:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f01014e8:	5d                   	pop    %ebp
f01014e9:	c3                   	ret    

f01014ea <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01014ea:	55                   	push   %ebp
f01014eb:	89 e5                	mov    %esp,%ebp
f01014ed:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f01014f0:	ff 75 08             	pushl  0x8(%ebp)
f01014f3:	e8 08 f1 ff ff       	call   f0100600 <cputchar>
	*cnt++;
}
f01014f8:	83 c4 10             	add    $0x10,%esp
f01014fb:	c9                   	leave  
f01014fc:	c3                   	ret    

f01014fd <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01014fd:	55                   	push   %ebp
f01014fe:	89 e5                	mov    %esp,%ebp
f0101500:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0101503:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f010150a:	ff 75 0c             	pushl  0xc(%ebp)
f010150d:	ff 75 08             	pushl  0x8(%ebp)
f0101510:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101513:	50                   	push   %eax
f0101514:	68 ea 14 10 f0       	push   $0xf01014ea
f0101519:	e8 52 04 00 00       	call   f0101970 <vprintfmt>
	return cnt;
}
f010151e:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101521:	c9                   	leave  
f0101522:	c3                   	ret    

f0101523 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0101523:	55                   	push   %ebp
f0101524:	89 e5                	mov    %esp,%ebp
f0101526:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0101529:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f010152c:	50                   	push   %eax
f010152d:	ff 75 08             	pushl  0x8(%ebp)
f0101530:	e8 c8 ff ff ff       	call   f01014fd <vcprintf>
	va_end(ap);

	return cnt;
}
f0101535:	c9                   	leave  
f0101536:	c3                   	ret    

f0101537 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0101537:	55                   	push   %ebp
f0101538:	89 e5                	mov    %esp,%ebp
f010153a:	57                   	push   %edi
f010153b:	56                   	push   %esi
f010153c:	53                   	push   %ebx
f010153d:	83 ec 14             	sub    $0x14,%esp
f0101540:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101543:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0101546:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0101549:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f010154c:	8b 1a                	mov    (%edx),%ebx
f010154e:	8b 01                	mov    (%ecx),%eax
f0101550:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0101553:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f010155a:	eb 7f                	jmp    f01015db <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f010155c:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010155f:	01 d8                	add    %ebx,%eax
f0101561:	89 c6                	mov    %eax,%esi
f0101563:	c1 ee 1f             	shr    $0x1f,%esi
f0101566:	01 c6                	add    %eax,%esi
f0101568:	d1 fe                	sar    %esi
f010156a:	8d 04 76             	lea    (%esi,%esi,2),%eax
f010156d:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0101570:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f0101573:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0101575:	eb 03                	jmp    f010157a <stab_binsearch+0x43>
			m--;
f0101577:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f010157a:	39 c3                	cmp    %eax,%ebx
f010157c:	7f 0d                	jg     f010158b <stab_binsearch+0x54>
f010157e:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0101582:	83 ea 0c             	sub    $0xc,%edx
f0101585:	39 f9                	cmp    %edi,%ecx
f0101587:	75 ee                	jne    f0101577 <stab_binsearch+0x40>
f0101589:	eb 05                	jmp    f0101590 <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f010158b:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f010158e:	eb 4b                	jmp    f01015db <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0101590:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0101593:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0101596:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f010159a:	39 55 0c             	cmp    %edx,0xc(%ebp)
f010159d:	76 11                	jbe    f01015b0 <stab_binsearch+0x79>
			*region_left = m;
f010159f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01015a2:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f01015a4:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01015a7:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01015ae:	eb 2b                	jmp    f01015db <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f01015b0:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01015b3:	73 14                	jae    f01015c9 <stab_binsearch+0x92>
			*region_right = m - 1;
f01015b5:	83 e8 01             	sub    $0x1,%eax
f01015b8:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01015bb:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01015be:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01015c0:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01015c7:	eb 12                	jmp    f01015db <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01015c9:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01015cc:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f01015ce:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f01015d2:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01015d4:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f01015db:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f01015de:	0f 8e 78 ff ff ff    	jle    f010155c <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f01015e4:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f01015e8:	75 0f                	jne    f01015f9 <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f01015ea:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01015ed:	8b 00                	mov    (%eax),%eax
f01015ef:	83 e8 01             	sub    $0x1,%eax
f01015f2:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01015f5:	89 06                	mov    %eax,(%esi)
f01015f7:	eb 2c                	jmp    f0101625 <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01015f9:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01015fc:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f01015fe:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0101601:	8b 0e                	mov    (%esi),%ecx
f0101603:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0101606:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0101609:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010160c:	eb 03                	jmp    f0101611 <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f010160e:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0101611:	39 c8                	cmp    %ecx,%eax
f0101613:	7e 0b                	jle    f0101620 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f0101615:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0101619:	83 ea 0c             	sub    $0xc,%edx
f010161c:	39 df                	cmp    %ebx,%edi
f010161e:	75 ee                	jne    f010160e <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f0101620:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0101623:	89 06                	mov    %eax,(%esi)
	}
}
f0101625:	83 c4 14             	add    $0x14,%esp
f0101628:	5b                   	pop    %ebx
f0101629:	5e                   	pop    %esi
f010162a:	5f                   	pop    %edi
f010162b:	5d                   	pop    %ebp
f010162c:	c3                   	ret    

f010162d <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f010162d:	55                   	push   %ebp
f010162e:	89 e5                	mov    %esp,%ebp
f0101630:	57                   	push   %edi
f0101631:	56                   	push   %esi
f0101632:	53                   	push   %ebx
f0101633:	83 ec 3c             	sub    $0x3c,%esp
f0101636:	8b 75 08             	mov    0x8(%ebp),%esi
f0101639:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f010163c:	c7 03 46 2d 10 f0    	movl   $0xf0102d46,(%ebx)
	info->eip_line = 0;
f0101642:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0101649:	c7 43 08 46 2d 10 f0 	movl   $0xf0102d46,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0101650:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0101657:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f010165a:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0101661:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0101667:	76 11                	jbe    f010167a <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0101669:	b8 a0 98 10 f0       	mov    $0xf01098a0,%eax
f010166e:	3d 85 7b 10 f0       	cmp    $0xf0107b85,%eax
f0101673:	77 19                	ja     f010168e <debuginfo_eip+0x61>
f0101675:	e9 aa 01 00 00       	jmp    f0101824 <debuginfo_eip+0x1f7>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f010167a:	83 ec 04             	sub    $0x4,%esp
f010167d:	68 50 2d 10 f0       	push   $0xf0102d50
f0101682:	6a 7f                	push   $0x7f
f0101684:	68 5d 2d 10 f0       	push   $0xf0102d5d
f0101689:	e8 fd e9 ff ff       	call   f010008b <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f010168e:	80 3d 9f 98 10 f0 00 	cmpb   $0x0,0xf010989f
f0101695:	0f 85 90 01 00 00    	jne    f010182b <debuginfo_eip+0x1fe>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f010169b:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f01016a2:	b8 84 7b 10 f0       	mov    $0xf0107b84,%eax
f01016a7:	2d 7c 2f 10 f0       	sub    $0xf0102f7c,%eax
f01016ac:	c1 f8 02             	sar    $0x2,%eax
f01016af:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f01016b5:	83 e8 01             	sub    $0x1,%eax
f01016b8:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f01016bb:	83 ec 08             	sub    $0x8,%esp
f01016be:	56                   	push   %esi
f01016bf:	6a 64                	push   $0x64
f01016c1:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f01016c4:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01016c7:	b8 7c 2f 10 f0       	mov    $0xf0102f7c,%eax
f01016cc:	e8 66 fe ff ff       	call   f0101537 <stab_binsearch>
	if (lfile == 0)
f01016d1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01016d4:	83 c4 10             	add    $0x10,%esp
f01016d7:	85 c0                	test   %eax,%eax
f01016d9:	0f 84 53 01 00 00    	je     f0101832 <debuginfo_eip+0x205>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f01016df:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f01016e2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01016e5:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f01016e8:	83 ec 08             	sub    $0x8,%esp
f01016eb:	56                   	push   %esi
f01016ec:	6a 24                	push   $0x24
f01016ee:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f01016f1:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01016f4:	b8 7c 2f 10 f0       	mov    $0xf0102f7c,%eax
f01016f9:	e8 39 fe ff ff       	call   f0101537 <stab_binsearch>

	if (lfun <= rfun) {
f01016fe:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0101701:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0101704:	83 c4 10             	add    $0x10,%esp
f0101707:	39 d0                	cmp    %edx,%eax
f0101709:	7f 40                	jg     f010174b <debuginfo_eip+0x11e>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f010170b:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f010170e:	c1 e1 02             	shl    $0x2,%ecx
f0101711:	8d b9 7c 2f 10 f0    	lea    -0xfefd084(%ecx),%edi
f0101717:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f010171a:	8b b9 7c 2f 10 f0    	mov    -0xfefd084(%ecx),%edi
f0101720:	b9 a0 98 10 f0       	mov    $0xf01098a0,%ecx
f0101725:	81 e9 85 7b 10 f0    	sub    $0xf0107b85,%ecx
f010172b:	39 cf                	cmp    %ecx,%edi
f010172d:	73 09                	jae    f0101738 <debuginfo_eip+0x10b>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f010172f:	81 c7 85 7b 10 f0    	add    $0xf0107b85,%edi
f0101735:	89 7b 08             	mov    %edi,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0101738:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f010173b:	8b 4f 08             	mov    0x8(%edi),%ecx
f010173e:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0101741:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0101743:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0101746:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0101749:	eb 0f                	jmp    f010175a <debuginfo_eip+0x12d>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f010174b:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f010174e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101751:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0101754:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101757:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f010175a:	83 ec 08             	sub    $0x8,%esp
f010175d:	6a 3a                	push   $0x3a
f010175f:	ff 73 08             	pushl  0x8(%ebx)
f0101762:	e8 59 08 00 00       	call   f0101fc0 <strfind>
f0101767:	2b 43 08             	sub    0x8(%ebx),%eax
f010176a:	89 43 0c             	mov    %eax,0xc(%ebx)
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.

	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);	
f010176d:	83 c4 08             	add    $0x8,%esp
f0101770:	56                   	push   %esi
f0101771:	6a 44                	push   $0x44
f0101773:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0101776:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0101779:	b8 7c 2f 10 f0       	mov    $0xf0102f7c,%eax
f010177e:	e8 b4 fd ff ff       	call   f0101537 <stab_binsearch>
	if (lline > rline)
f0101783:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0101786:	83 c4 10             	add    $0x10,%esp
f0101789:	3b 55 d0             	cmp    -0x30(%ebp),%edx
f010178c:	0f 8f a7 00 00 00    	jg     f0101839 <debuginfo_eip+0x20c>
		    return -1;
	info->eip_line = stabs[lline].n_desc;
f0101792:	8d 04 52             	lea    (%edx,%edx,2),%eax
f0101795:	8d 04 85 7c 2f 10 f0 	lea    -0xfefd084(,%eax,4),%eax
f010179c:	0f b7 48 06          	movzwl 0x6(%eax),%ecx
f01017a0:	89 4b 04             	mov    %ecx,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01017a3:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01017a6:	eb 06                	jmp    f01017ae <debuginfo_eip+0x181>
f01017a8:	83 ea 01             	sub    $0x1,%edx
f01017ab:	83 e8 0c             	sub    $0xc,%eax
f01017ae:	39 d6                	cmp    %edx,%esi
f01017b0:	7f 34                	jg     f01017e6 <debuginfo_eip+0x1b9>
	       && stabs[lline].n_type != N_SOL
f01017b2:	0f b6 48 04          	movzbl 0x4(%eax),%ecx
f01017b6:	80 f9 84             	cmp    $0x84,%cl
f01017b9:	74 0b                	je     f01017c6 <debuginfo_eip+0x199>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f01017bb:	80 f9 64             	cmp    $0x64,%cl
f01017be:	75 e8                	jne    f01017a8 <debuginfo_eip+0x17b>
f01017c0:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f01017c4:	74 e2                	je     f01017a8 <debuginfo_eip+0x17b>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f01017c6:	8d 04 52             	lea    (%edx,%edx,2),%eax
f01017c9:	8b 14 85 7c 2f 10 f0 	mov    -0xfefd084(,%eax,4),%edx
f01017d0:	b8 a0 98 10 f0       	mov    $0xf01098a0,%eax
f01017d5:	2d 85 7b 10 f0       	sub    $0xf0107b85,%eax
f01017da:	39 c2                	cmp    %eax,%edx
f01017dc:	73 08                	jae    f01017e6 <debuginfo_eip+0x1b9>
		info->eip_file = stabstr + stabs[lline].n_strx;
f01017de:	81 c2 85 7b 10 f0    	add    $0xf0107b85,%edx
f01017e4:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01017e6:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01017e9:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01017ec:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01017f1:	39 f2                	cmp    %esi,%edx
f01017f3:	7d 50                	jge    f0101845 <debuginfo_eip+0x218>
		for (lline = lfun + 1;
f01017f5:	83 c2 01             	add    $0x1,%edx
f01017f8:	89 d0                	mov    %edx,%eax
f01017fa:	8d 14 52             	lea    (%edx,%edx,2),%edx
f01017fd:	8d 14 95 7c 2f 10 f0 	lea    -0xfefd084(,%edx,4),%edx
f0101804:	eb 04                	jmp    f010180a <debuginfo_eip+0x1dd>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0101806:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f010180a:	39 c6                	cmp    %eax,%esi
f010180c:	7e 32                	jle    f0101840 <debuginfo_eip+0x213>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f010180e:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0101812:	83 c0 01             	add    $0x1,%eax
f0101815:	83 c2 0c             	add    $0xc,%edx
f0101818:	80 f9 a0             	cmp    $0xa0,%cl
f010181b:	74 e9                	je     f0101806 <debuginfo_eip+0x1d9>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f010181d:	b8 00 00 00 00       	mov    $0x0,%eax
f0101822:	eb 21                	jmp    f0101845 <debuginfo_eip+0x218>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0101824:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0101829:	eb 1a                	jmp    f0101845 <debuginfo_eip+0x218>
f010182b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0101830:	eb 13                	jmp    f0101845 <debuginfo_eip+0x218>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0101832:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0101837:	eb 0c                	jmp    f0101845 <debuginfo_eip+0x218>
	//	which one.
	// Your code here.

	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);	
	if (lline > rline)
		    return -1;
f0101839:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010183e:	eb 05                	jmp    f0101845 <debuginfo_eip+0x218>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0101840:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101845:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101848:	5b                   	pop    %ebx
f0101849:	5e                   	pop    %esi
f010184a:	5f                   	pop    %edi
f010184b:	5d                   	pop    %ebp
f010184c:	c3                   	ret    

f010184d <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f010184d:	55                   	push   %ebp
f010184e:	89 e5                	mov    %esp,%ebp
f0101850:	57                   	push   %edi
f0101851:	56                   	push   %esi
f0101852:	53                   	push   %ebx
f0101853:	83 ec 1c             	sub    $0x1c,%esp
f0101856:	89 c7                	mov    %eax,%edi
f0101858:	89 d6                	mov    %edx,%esi
f010185a:	8b 45 08             	mov    0x8(%ebp),%eax
f010185d:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101860:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101863:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0101866:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0101869:	bb 00 00 00 00       	mov    $0x0,%ebx
f010186e:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0101871:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0101874:	39 d3                	cmp    %edx,%ebx
f0101876:	72 05                	jb     f010187d <printnum+0x30>
f0101878:	39 45 10             	cmp    %eax,0x10(%ebp)
f010187b:	77 45                	ja     f01018c2 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f010187d:	83 ec 0c             	sub    $0xc,%esp
f0101880:	ff 75 18             	pushl  0x18(%ebp)
f0101883:	8b 45 14             	mov    0x14(%ebp),%eax
f0101886:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0101889:	53                   	push   %ebx
f010188a:	ff 75 10             	pushl  0x10(%ebp)
f010188d:	83 ec 08             	sub    $0x8,%esp
f0101890:	ff 75 e4             	pushl  -0x1c(%ebp)
f0101893:	ff 75 e0             	pushl  -0x20(%ebp)
f0101896:	ff 75 dc             	pushl  -0x24(%ebp)
f0101899:	ff 75 d8             	pushl  -0x28(%ebp)
f010189c:	e8 3f 09 00 00       	call   f01021e0 <__udivdi3>
f01018a1:	83 c4 18             	add    $0x18,%esp
f01018a4:	52                   	push   %edx
f01018a5:	50                   	push   %eax
f01018a6:	89 f2                	mov    %esi,%edx
f01018a8:	89 f8                	mov    %edi,%eax
f01018aa:	e8 9e ff ff ff       	call   f010184d <printnum>
f01018af:	83 c4 20             	add    $0x20,%esp
f01018b2:	eb 18                	jmp    f01018cc <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f01018b4:	83 ec 08             	sub    $0x8,%esp
f01018b7:	56                   	push   %esi
f01018b8:	ff 75 18             	pushl  0x18(%ebp)
f01018bb:	ff d7                	call   *%edi
f01018bd:	83 c4 10             	add    $0x10,%esp
f01018c0:	eb 03                	jmp    f01018c5 <printnum+0x78>
f01018c2:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f01018c5:	83 eb 01             	sub    $0x1,%ebx
f01018c8:	85 db                	test   %ebx,%ebx
f01018ca:	7f e8                	jg     f01018b4 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f01018cc:	83 ec 08             	sub    $0x8,%esp
f01018cf:	56                   	push   %esi
f01018d0:	83 ec 04             	sub    $0x4,%esp
f01018d3:	ff 75 e4             	pushl  -0x1c(%ebp)
f01018d6:	ff 75 e0             	pushl  -0x20(%ebp)
f01018d9:	ff 75 dc             	pushl  -0x24(%ebp)
f01018dc:	ff 75 d8             	pushl  -0x28(%ebp)
f01018df:	e8 2c 0a 00 00       	call   f0102310 <__umoddi3>
f01018e4:	83 c4 14             	add    $0x14,%esp
f01018e7:	0f be 80 6b 2d 10 f0 	movsbl -0xfefd295(%eax),%eax
f01018ee:	50                   	push   %eax
f01018ef:	ff d7                	call   *%edi
}
f01018f1:	83 c4 10             	add    $0x10,%esp
f01018f4:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01018f7:	5b                   	pop    %ebx
f01018f8:	5e                   	pop    %esi
f01018f9:	5f                   	pop    %edi
f01018fa:	5d                   	pop    %ebp
f01018fb:	c3                   	ret    

f01018fc <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f01018fc:	55                   	push   %ebp
f01018fd:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f01018ff:	83 fa 01             	cmp    $0x1,%edx
f0101902:	7e 0e                	jle    f0101912 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0101904:	8b 10                	mov    (%eax),%edx
f0101906:	8d 4a 08             	lea    0x8(%edx),%ecx
f0101909:	89 08                	mov    %ecx,(%eax)
f010190b:	8b 02                	mov    (%edx),%eax
f010190d:	8b 52 04             	mov    0x4(%edx),%edx
f0101910:	eb 22                	jmp    f0101934 <getuint+0x38>
	else if (lflag)
f0101912:	85 d2                	test   %edx,%edx
f0101914:	74 10                	je     f0101926 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0101916:	8b 10                	mov    (%eax),%edx
f0101918:	8d 4a 04             	lea    0x4(%edx),%ecx
f010191b:	89 08                	mov    %ecx,(%eax)
f010191d:	8b 02                	mov    (%edx),%eax
f010191f:	ba 00 00 00 00       	mov    $0x0,%edx
f0101924:	eb 0e                	jmp    f0101934 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0101926:	8b 10                	mov    (%eax),%edx
f0101928:	8d 4a 04             	lea    0x4(%edx),%ecx
f010192b:	89 08                	mov    %ecx,(%eax)
f010192d:	8b 02                	mov    (%edx),%eax
f010192f:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0101934:	5d                   	pop    %ebp
f0101935:	c3                   	ret    

f0101936 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0101936:	55                   	push   %ebp
f0101937:	89 e5                	mov    %esp,%ebp
f0101939:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f010193c:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0101940:	8b 10                	mov    (%eax),%edx
f0101942:	3b 50 04             	cmp    0x4(%eax),%edx
f0101945:	73 0a                	jae    f0101951 <sprintputch+0x1b>
		*b->buf++ = ch;
f0101947:	8d 4a 01             	lea    0x1(%edx),%ecx
f010194a:	89 08                	mov    %ecx,(%eax)
f010194c:	8b 45 08             	mov    0x8(%ebp),%eax
f010194f:	88 02                	mov    %al,(%edx)
}
f0101951:	5d                   	pop    %ebp
f0101952:	c3                   	ret    

f0101953 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0101953:	55                   	push   %ebp
f0101954:	89 e5                	mov    %esp,%ebp
f0101956:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0101959:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f010195c:	50                   	push   %eax
f010195d:	ff 75 10             	pushl  0x10(%ebp)
f0101960:	ff 75 0c             	pushl  0xc(%ebp)
f0101963:	ff 75 08             	pushl  0x8(%ebp)
f0101966:	e8 05 00 00 00       	call   f0101970 <vprintfmt>
	va_end(ap);
}
f010196b:	83 c4 10             	add    $0x10,%esp
f010196e:	c9                   	leave  
f010196f:	c3                   	ret    

f0101970 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0101970:	55                   	push   %ebp
f0101971:	89 e5                	mov    %esp,%ebp
f0101973:	57                   	push   %edi
f0101974:	56                   	push   %esi
f0101975:	53                   	push   %ebx
f0101976:	83 ec 2c             	sub    $0x2c,%esp
f0101979:	8b 75 08             	mov    0x8(%ebp),%esi
f010197c:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010197f:	8b 7d 10             	mov    0x10(%ebp),%edi
f0101982:	eb 12                	jmp    f0101996 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0101984:	85 c0                	test   %eax,%eax
f0101986:	0f 84 89 03 00 00    	je     f0101d15 <vprintfmt+0x3a5>
				return;
			putch(ch, putdat);
f010198c:	83 ec 08             	sub    $0x8,%esp
f010198f:	53                   	push   %ebx
f0101990:	50                   	push   %eax
f0101991:	ff d6                	call   *%esi
f0101993:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0101996:	83 c7 01             	add    $0x1,%edi
f0101999:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f010199d:	83 f8 25             	cmp    $0x25,%eax
f01019a0:	75 e2                	jne    f0101984 <vprintfmt+0x14>
f01019a2:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f01019a6:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f01019ad:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f01019b4:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f01019bb:	ba 00 00 00 00       	mov    $0x0,%edx
f01019c0:	eb 07                	jmp    f01019c9 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01019c2:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f01019c5:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01019c9:	8d 47 01             	lea    0x1(%edi),%eax
f01019cc:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01019cf:	0f b6 07             	movzbl (%edi),%eax
f01019d2:	0f b6 c8             	movzbl %al,%ecx
f01019d5:	83 e8 23             	sub    $0x23,%eax
f01019d8:	3c 55                	cmp    $0x55,%al
f01019da:	0f 87 1a 03 00 00    	ja     f0101cfa <vprintfmt+0x38a>
f01019e0:	0f b6 c0             	movzbl %al,%eax
f01019e3:	ff 24 85 f8 2d 10 f0 	jmp    *-0xfefd208(,%eax,4)
f01019ea:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f01019ed:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f01019f1:	eb d6                	jmp    f01019c9 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01019f3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01019f6:	b8 00 00 00 00       	mov    $0x0,%eax
f01019fb:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f01019fe:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0101a01:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f0101a05:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0101a08:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0101a0b:	83 fa 09             	cmp    $0x9,%edx
f0101a0e:	77 39                	ja     f0101a49 <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0101a10:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0101a13:	eb e9                	jmp    f01019fe <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0101a15:	8b 45 14             	mov    0x14(%ebp),%eax
f0101a18:	8d 48 04             	lea    0x4(%eax),%ecx
f0101a1b:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0101a1e:	8b 00                	mov    (%eax),%eax
f0101a20:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101a23:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0101a26:	eb 27                	jmp    f0101a4f <vprintfmt+0xdf>
f0101a28:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101a2b:	85 c0                	test   %eax,%eax
f0101a2d:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101a32:	0f 49 c8             	cmovns %eax,%ecx
f0101a35:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101a38:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101a3b:	eb 8c                	jmp    f01019c9 <vprintfmt+0x59>
f0101a3d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0101a40:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0101a47:	eb 80                	jmp    f01019c9 <vprintfmt+0x59>
f0101a49:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0101a4c:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0101a4f:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0101a53:	0f 89 70 ff ff ff    	jns    f01019c9 <vprintfmt+0x59>
				width = precision, precision = -1;
f0101a59:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101a5c:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101a5f:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0101a66:	e9 5e ff ff ff       	jmp    f01019c9 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0101a6b:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101a6e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0101a71:	e9 53 ff ff ff       	jmp    f01019c9 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0101a76:	8b 45 14             	mov    0x14(%ebp),%eax
f0101a79:	8d 50 04             	lea    0x4(%eax),%edx
f0101a7c:	89 55 14             	mov    %edx,0x14(%ebp)
f0101a7f:	83 ec 08             	sub    $0x8,%esp
f0101a82:	53                   	push   %ebx
f0101a83:	ff 30                	pushl  (%eax)
f0101a85:	ff d6                	call   *%esi
			break;
f0101a87:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101a8a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0101a8d:	e9 04 ff ff ff       	jmp    f0101996 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0101a92:	8b 45 14             	mov    0x14(%ebp),%eax
f0101a95:	8d 50 04             	lea    0x4(%eax),%edx
f0101a98:	89 55 14             	mov    %edx,0x14(%ebp)
f0101a9b:	8b 00                	mov    (%eax),%eax
f0101a9d:	99                   	cltd   
f0101a9e:	31 d0                	xor    %edx,%eax
f0101aa0:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0101aa2:	83 f8 06             	cmp    $0x6,%eax
f0101aa5:	7f 0b                	jg     f0101ab2 <vprintfmt+0x142>
f0101aa7:	8b 14 85 50 2f 10 f0 	mov    -0xfefd0b0(,%eax,4),%edx
f0101aae:	85 d2                	test   %edx,%edx
f0101ab0:	75 18                	jne    f0101aca <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f0101ab2:	50                   	push   %eax
f0101ab3:	68 83 2d 10 f0       	push   $0xf0102d83
f0101ab8:	53                   	push   %ebx
f0101ab9:	56                   	push   %esi
f0101aba:	e8 94 fe ff ff       	call   f0101953 <printfmt>
f0101abf:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101ac2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0101ac5:	e9 cc fe ff ff       	jmp    f0101996 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0101aca:	52                   	push   %edx
f0101acb:	68 a7 2b 10 f0       	push   $0xf0102ba7
f0101ad0:	53                   	push   %ebx
f0101ad1:	56                   	push   %esi
f0101ad2:	e8 7c fe ff ff       	call   f0101953 <printfmt>
f0101ad7:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101ada:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101add:	e9 b4 fe ff ff       	jmp    f0101996 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0101ae2:	8b 45 14             	mov    0x14(%ebp),%eax
f0101ae5:	8d 50 04             	lea    0x4(%eax),%edx
f0101ae8:	89 55 14             	mov    %edx,0x14(%ebp)
f0101aeb:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0101aed:	85 ff                	test   %edi,%edi
f0101aef:	b8 7c 2d 10 f0       	mov    $0xf0102d7c,%eax
f0101af4:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0101af7:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0101afb:	0f 8e 94 00 00 00    	jle    f0101b95 <vprintfmt+0x225>
f0101b01:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0101b05:	0f 84 98 00 00 00    	je     f0101ba3 <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
f0101b0b:	83 ec 08             	sub    $0x8,%esp
f0101b0e:	ff 75 d0             	pushl  -0x30(%ebp)
f0101b11:	57                   	push   %edi
f0101b12:	e8 5f 03 00 00       	call   f0101e76 <strnlen>
f0101b17:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0101b1a:	29 c1                	sub    %eax,%ecx
f0101b1c:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0101b1f:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0101b22:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0101b26:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101b29:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0101b2c:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0101b2e:	eb 0f                	jmp    f0101b3f <vprintfmt+0x1cf>
					putch(padc, putdat);
f0101b30:	83 ec 08             	sub    $0x8,%esp
f0101b33:	53                   	push   %ebx
f0101b34:	ff 75 e0             	pushl  -0x20(%ebp)
f0101b37:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0101b39:	83 ef 01             	sub    $0x1,%edi
f0101b3c:	83 c4 10             	add    $0x10,%esp
f0101b3f:	85 ff                	test   %edi,%edi
f0101b41:	7f ed                	jg     f0101b30 <vprintfmt+0x1c0>
f0101b43:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0101b46:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0101b49:	85 c9                	test   %ecx,%ecx
f0101b4b:	b8 00 00 00 00       	mov    $0x0,%eax
f0101b50:	0f 49 c1             	cmovns %ecx,%eax
f0101b53:	29 c1                	sub    %eax,%ecx
f0101b55:	89 75 08             	mov    %esi,0x8(%ebp)
f0101b58:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101b5b:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0101b5e:	89 cb                	mov    %ecx,%ebx
f0101b60:	eb 4d                	jmp    f0101baf <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0101b62:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0101b66:	74 1b                	je     f0101b83 <vprintfmt+0x213>
f0101b68:	0f be c0             	movsbl %al,%eax
f0101b6b:	83 e8 20             	sub    $0x20,%eax
f0101b6e:	83 f8 5e             	cmp    $0x5e,%eax
f0101b71:	76 10                	jbe    f0101b83 <vprintfmt+0x213>
					putch('?', putdat);
f0101b73:	83 ec 08             	sub    $0x8,%esp
f0101b76:	ff 75 0c             	pushl  0xc(%ebp)
f0101b79:	6a 3f                	push   $0x3f
f0101b7b:	ff 55 08             	call   *0x8(%ebp)
f0101b7e:	83 c4 10             	add    $0x10,%esp
f0101b81:	eb 0d                	jmp    f0101b90 <vprintfmt+0x220>
				else
					putch(ch, putdat);
f0101b83:	83 ec 08             	sub    $0x8,%esp
f0101b86:	ff 75 0c             	pushl  0xc(%ebp)
f0101b89:	52                   	push   %edx
f0101b8a:	ff 55 08             	call   *0x8(%ebp)
f0101b8d:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101b90:	83 eb 01             	sub    $0x1,%ebx
f0101b93:	eb 1a                	jmp    f0101baf <vprintfmt+0x23f>
f0101b95:	89 75 08             	mov    %esi,0x8(%ebp)
f0101b98:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101b9b:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0101b9e:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0101ba1:	eb 0c                	jmp    f0101baf <vprintfmt+0x23f>
f0101ba3:	89 75 08             	mov    %esi,0x8(%ebp)
f0101ba6:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101ba9:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0101bac:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0101baf:	83 c7 01             	add    $0x1,%edi
f0101bb2:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0101bb6:	0f be d0             	movsbl %al,%edx
f0101bb9:	85 d2                	test   %edx,%edx
f0101bbb:	74 23                	je     f0101be0 <vprintfmt+0x270>
f0101bbd:	85 f6                	test   %esi,%esi
f0101bbf:	78 a1                	js     f0101b62 <vprintfmt+0x1f2>
f0101bc1:	83 ee 01             	sub    $0x1,%esi
f0101bc4:	79 9c                	jns    f0101b62 <vprintfmt+0x1f2>
f0101bc6:	89 df                	mov    %ebx,%edi
f0101bc8:	8b 75 08             	mov    0x8(%ebp),%esi
f0101bcb:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101bce:	eb 18                	jmp    f0101be8 <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0101bd0:	83 ec 08             	sub    $0x8,%esp
f0101bd3:	53                   	push   %ebx
f0101bd4:	6a 20                	push   $0x20
f0101bd6:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101bd8:	83 ef 01             	sub    $0x1,%edi
f0101bdb:	83 c4 10             	add    $0x10,%esp
f0101bde:	eb 08                	jmp    f0101be8 <vprintfmt+0x278>
f0101be0:	89 df                	mov    %ebx,%edi
f0101be2:	8b 75 08             	mov    0x8(%ebp),%esi
f0101be5:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101be8:	85 ff                	test   %edi,%edi
f0101bea:	7f e4                	jg     f0101bd0 <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101bec:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101bef:	e9 a2 fd ff ff       	jmp    f0101996 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0101bf4:	83 fa 01             	cmp    $0x1,%edx
f0101bf7:	7e 16                	jle    f0101c0f <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f0101bf9:	8b 45 14             	mov    0x14(%ebp),%eax
f0101bfc:	8d 50 08             	lea    0x8(%eax),%edx
f0101bff:	89 55 14             	mov    %edx,0x14(%ebp)
f0101c02:	8b 50 04             	mov    0x4(%eax),%edx
f0101c05:	8b 00                	mov    (%eax),%eax
f0101c07:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101c0a:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0101c0d:	eb 32                	jmp    f0101c41 <vprintfmt+0x2d1>
	else if (lflag)
f0101c0f:	85 d2                	test   %edx,%edx
f0101c11:	74 18                	je     f0101c2b <vprintfmt+0x2bb>
		return va_arg(*ap, long);
f0101c13:	8b 45 14             	mov    0x14(%ebp),%eax
f0101c16:	8d 50 04             	lea    0x4(%eax),%edx
f0101c19:	89 55 14             	mov    %edx,0x14(%ebp)
f0101c1c:	8b 00                	mov    (%eax),%eax
f0101c1e:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101c21:	89 c1                	mov    %eax,%ecx
f0101c23:	c1 f9 1f             	sar    $0x1f,%ecx
f0101c26:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0101c29:	eb 16                	jmp    f0101c41 <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
f0101c2b:	8b 45 14             	mov    0x14(%ebp),%eax
f0101c2e:	8d 50 04             	lea    0x4(%eax),%edx
f0101c31:	89 55 14             	mov    %edx,0x14(%ebp)
f0101c34:	8b 00                	mov    (%eax),%eax
f0101c36:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101c39:	89 c1                	mov    %eax,%ecx
f0101c3b:	c1 f9 1f             	sar    $0x1f,%ecx
f0101c3e:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0101c41:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0101c44:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0101c47:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0101c4c:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0101c50:	79 74                	jns    f0101cc6 <vprintfmt+0x356>
				putch('-', putdat);
f0101c52:	83 ec 08             	sub    $0x8,%esp
f0101c55:	53                   	push   %ebx
f0101c56:	6a 2d                	push   $0x2d
f0101c58:	ff d6                	call   *%esi
				num = -(long long) num;
f0101c5a:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0101c5d:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0101c60:	f7 d8                	neg    %eax
f0101c62:	83 d2 00             	adc    $0x0,%edx
f0101c65:	f7 da                	neg    %edx
f0101c67:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0101c6a:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0101c6f:	eb 55                	jmp    f0101cc6 <vprintfmt+0x356>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0101c71:	8d 45 14             	lea    0x14(%ebp),%eax
f0101c74:	e8 83 fc ff ff       	call   f01018fc <getuint>
			base = 10;
f0101c79:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0101c7e:	eb 46                	jmp    f0101cc6 <vprintfmt+0x356>
		// (unsigned) octal
		case 'o':
			//putch('X', putdat);
			//putch('X', putdat);
			//putch('X', putdat);
			num = getuint(&ap, lflag);
f0101c80:	8d 45 14             	lea    0x14(%ebp),%eax
f0101c83:	e8 74 fc ff ff       	call   f01018fc <getuint>
			base = 8;
f0101c88:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0101c8d:	eb 37                	jmp    f0101cc6 <vprintfmt+0x356>

		// pointer
		case 'p':
			putch('0', putdat);
f0101c8f:	83 ec 08             	sub    $0x8,%esp
f0101c92:	53                   	push   %ebx
f0101c93:	6a 30                	push   $0x30
f0101c95:	ff d6                	call   *%esi
			putch('x', putdat);
f0101c97:	83 c4 08             	add    $0x8,%esp
f0101c9a:	53                   	push   %ebx
f0101c9b:	6a 78                	push   $0x78
f0101c9d:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0101c9f:	8b 45 14             	mov    0x14(%ebp),%eax
f0101ca2:	8d 50 04             	lea    0x4(%eax),%edx
f0101ca5:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0101ca8:	8b 00                	mov    (%eax),%eax
f0101caa:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0101caf:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0101cb2:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0101cb7:	eb 0d                	jmp    f0101cc6 <vprintfmt+0x356>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0101cb9:	8d 45 14             	lea    0x14(%ebp),%eax
f0101cbc:	e8 3b fc ff ff       	call   f01018fc <getuint>
			base = 16;
f0101cc1:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0101cc6:	83 ec 0c             	sub    $0xc,%esp
f0101cc9:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0101ccd:	57                   	push   %edi
f0101cce:	ff 75 e0             	pushl  -0x20(%ebp)
f0101cd1:	51                   	push   %ecx
f0101cd2:	52                   	push   %edx
f0101cd3:	50                   	push   %eax
f0101cd4:	89 da                	mov    %ebx,%edx
f0101cd6:	89 f0                	mov    %esi,%eax
f0101cd8:	e8 70 fb ff ff       	call   f010184d <printnum>
			break;
f0101cdd:	83 c4 20             	add    $0x20,%esp
f0101ce0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101ce3:	e9 ae fc ff ff       	jmp    f0101996 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0101ce8:	83 ec 08             	sub    $0x8,%esp
f0101ceb:	53                   	push   %ebx
f0101cec:	51                   	push   %ecx
f0101ced:	ff d6                	call   *%esi
			break;
f0101cef:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101cf2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0101cf5:	e9 9c fc ff ff       	jmp    f0101996 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0101cfa:	83 ec 08             	sub    $0x8,%esp
f0101cfd:	53                   	push   %ebx
f0101cfe:	6a 25                	push   $0x25
f0101d00:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0101d02:	83 c4 10             	add    $0x10,%esp
f0101d05:	eb 03                	jmp    f0101d0a <vprintfmt+0x39a>
f0101d07:	83 ef 01             	sub    $0x1,%edi
f0101d0a:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0101d0e:	75 f7                	jne    f0101d07 <vprintfmt+0x397>
f0101d10:	e9 81 fc ff ff       	jmp    f0101996 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0101d15:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101d18:	5b                   	pop    %ebx
f0101d19:	5e                   	pop    %esi
f0101d1a:	5f                   	pop    %edi
f0101d1b:	5d                   	pop    %ebp
f0101d1c:	c3                   	ret    

f0101d1d <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0101d1d:	55                   	push   %ebp
f0101d1e:	89 e5                	mov    %esp,%ebp
f0101d20:	83 ec 18             	sub    $0x18,%esp
f0101d23:	8b 45 08             	mov    0x8(%ebp),%eax
f0101d26:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0101d29:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101d2c:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0101d30:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0101d33:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0101d3a:	85 c0                	test   %eax,%eax
f0101d3c:	74 26                	je     f0101d64 <vsnprintf+0x47>
f0101d3e:	85 d2                	test   %edx,%edx
f0101d40:	7e 22                	jle    f0101d64 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0101d42:	ff 75 14             	pushl  0x14(%ebp)
f0101d45:	ff 75 10             	pushl  0x10(%ebp)
f0101d48:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0101d4b:	50                   	push   %eax
f0101d4c:	68 36 19 10 f0       	push   $0xf0101936
f0101d51:	e8 1a fc ff ff       	call   f0101970 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0101d56:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101d59:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0101d5c:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101d5f:	83 c4 10             	add    $0x10,%esp
f0101d62:	eb 05                	jmp    f0101d69 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0101d64:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0101d69:	c9                   	leave  
f0101d6a:	c3                   	ret    

f0101d6b <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0101d6b:	55                   	push   %ebp
f0101d6c:	89 e5                	mov    %esp,%ebp
f0101d6e:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0101d71:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0101d74:	50                   	push   %eax
f0101d75:	ff 75 10             	pushl  0x10(%ebp)
f0101d78:	ff 75 0c             	pushl  0xc(%ebp)
f0101d7b:	ff 75 08             	pushl  0x8(%ebp)
f0101d7e:	e8 9a ff ff ff       	call   f0101d1d <vsnprintf>
	va_end(ap);

	return rc;
}
f0101d83:	c9                   	leave  
f0101d84:	c3                   	ret    

f0101d85 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0101d85:	55                   	push   %ebp
f0101d86:	89 e5                	mov    %esp,%ebp
f0101d88:	57                   	push   %edi
f0101d89:	56                   	push   %esi
f0101d8a:	53                   	push   %ebx
f0101d8b:	83 ec 0c             	sub    $0xc,%esp
f0101d8e:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0101d91:	85 c0                	test   %eax,%eax
f0101d93:	74 11                	je     f0101da6 <readline+0x21>
		cprintf("%s", prompt);
f0101d95:	83 ec 08             	sub    $0x8,%esp
f0101d98:	50                   	push   %eax
f0101d99:	68 a7 2b 10 f0       	push   $0xf0102ba7
f0101d9e:	e8 80 f7 ff ff       	call   f0101523 <cprintf>
f0101da3:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0101da6:	83 ec 0c             	sub    $0xc,%esp
f0101da9:	6a 00                	push   $0x0
f0101dab:	e8 71 e8 ff ff       	call   f0100621 <iscons>
f0101db0:	89 c7                	mov    %eax,%edi
f0101db2:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0101db5:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0101dba:	e8 51 e8 ff ff       	call   f0100610 <getchar>
f0101dbf:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0101dc1:	85 c0                	test   %eax,%eax
f0101dc3:	79 18                	jns    f0101ddd <readline+0x58>
			cprintf("read error: %e\n", c);
f0101dc5:	83 ec 08             	sub    $0x8,%esp
f0101dc8:	50                   	push   %eax
f0101dc9:	68 6c 2f 10 f0       	push   $0xf0102f6c
f0101dce:	e8 50 f7 ff ff       	call   f0101523 <cprintf>
			return NULL;
f0101dd3:	83 c4 10             	add    $0x10,%esp
f0101dd6:	b8 00 00 00 00       	mov    $0x0,%eax
f0101ddb:	eb 79                	jmp    f0101e56 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101ddd:	83 f8 08             	cmp    $0x8,%eax
f0101de0:	0f 94 c2             	sete   %dl
f0101de3:	83 f8 7f             	cmp    $0x7f,%eax
f0101de6:	0f 94 c0             	sete   %al
f0101de9:	08 c2                	or     %al,%dl
f0101deb:	74 1a                	je     f0101e07 <readline+0x82>
f0101ded:	85 f6                	test   %esi,%esi
f0101def:	7e 16                	jle    f0101e07 <readline+0x82>
			if (echoing)
f0101df1:	85 ff                	test   %edi,%edi
f0101df3:	74 0d                	je     f0101e02 <readline+0x7d>
				cputchar('\b');
f0101df5:	83 ec 0c             	sub    $0xc,%esp
f0101df8:	6a 08                	push   $0x8
f0101dfa:	e8 01 e8 ff ff       	call   f0100600 <cputchar>
f0101dff:	83 c4 10             	add    $0x10,%esp
			i--;
f0101e02:	83 ee 01             	sub    $0x1,%esi
f0101e05:	eb b3                	jmp    f0101dba <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101e07:	83 fb 1f             	cmp    $0x1f,%ebx
f0101e0a:	7e 23                	jle    f0101e2f <readline+0xaa>
f0101e0c:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0101e12:	7f 1b                	jg     f0101e2f <readline+0xaa>
			if (echoing)
f0101e14:	85 ff                	test   %edi,%edi
f0101e16:	74 0c                	je     f0101e24 <readline+0x9f>
				cputchar(c);
f0101e18:	83 ec 0c             	sub    $0xc,%esp
f0101e1b:	53                   	push   %ebx
f0101e1c:	e8 df e7 ff ff       	call   f0100600 <cputchar>
f0101e21:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0101e24:	88 9e 40 45 11 f0    	mov    %bl,-0xfeebac0(%esi)
f0101e2a:	8d 76 01             	lea    0x1(%esi),%esi
f0101e2d:	eb 8b                	jmp    f0101dba <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0101e2f:	83 fb 0a             	cmp    $0xa,%ebx
f0101e32:	74 05                	je     f0101e39 <readline+0xb4>
f0101e34:	83 fb 0d             	cmp    $0xd,%ebx
f0101e37:	75 81                	jne    f0101dba <readline+0x35>
			if (echoing)
f0101e39:	85 ff                	test   %edi,%edi
f0101e3b:	74 0d                	je     f0101e4a <readline+0xc5>
				cputchar('\n');
f0101e3d:	83 ec 0c             	sub    $0xc,%esp
f0101e40:	6a 0a                	push   $0xa
f0101e42:	e8 b9 e7 ff ff       	call   f0100600 <cputchar>
f0101e47:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0101e4a:	c6 86 40 45 11 f0 00 	movb   $0x0,-0xfeebac0(%esi)
			return buf;
f0101e51:	b8 40 45 11 f0       	mov    $0xf0114540,%eax
		}
	}
}
f0101e56:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101e59:	5b                   	pop    %ebx
f0101e5a:	5e                   	pop    %esi
f0101e5b:	5f                   	pop    %edi
f0101e5c:	5d                   	pop    %ebp
f0101e5d:	c3                   	ret    

f0101e5e <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0101e5e:	55                   	push   %ebp
f0101e5f:	89 e5                	mov    %esp,%ebp
f0101e61:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0101e64:	b8 00 00 00 00       	mov    $0x0,%eax
f0101e69:	eb 03                	jmp    f0101e6e <strlen+0x10>
		n++;
f0101e6b:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0101e6e:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0101e72:	75 f7                	jne    f0101e6b <strlen+0xd>
		n++;
	return n;
}
f0101e74:	5d                   	pop    %ebp
f0101e75:	c3                   	ret    

f0101e76 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0101e76:	55                   	push   %ebp
f0101e77:	89 e5                	mov    %esp,%ebp
f0101e79:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101e7c:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101e7f:	ba 00 00 00 00       	mov    $0x0,%edx
f0101e84:	eb 03                	jmp    f0101e89 <strnlen+0x13>
		n++;
f0101e86:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101e89:	39 c2                	cmp    %eax,%edx
f0101e8b:	74 08                	je     f0101e95 <strnlen+0x1f>
f0101e8d:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f0101e91:	75 f3                	jne    f0101e86 <strnlen+0x10>
f0101e93:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0101e95:	5d                   	pop    %ebp
f0101e96:	c3                   	ret    

f0101e97 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0101e97:	55                   	push   %ebp
f0101e98:	89 e5                	mov    %esp,%ebp
f0101e9a:	53                   	push   %ebx
f0101e9b:	8b 45 08             	mov    0x8(%ebp),%eax
f0101e9e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0101ea1:	89 c2                	mov    %eax,%edx
f0101ea3:	83 c2 01             	add    $0x1,%edx
f0101ea6:	83 c1 01             	add    $0x1,%ecx
f0101ea9:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0101ead:	88 5a ff             	mov    %bl,-0x1(%edx)
f0101eb0:	84 db                	test   %bl,%bl
f0101eb2:	75 ef                	jne    f0101ea3 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0101eb4:	5b                   	pop    %ebx
f0101eb5:	5d                   	pop    %ebp
f0101eb6:	c3                   	ret    

f0101eb7 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0101eb7:	55                   	push   %ebp
f0101eb8:	89 e5                	mov    %esp,%ebp
f0101eba:	53                   	push   %ebx
f0101ebb:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0101ebe:	53                   	push   %ebx
f0101ebf:	e8 9a ff ff ff       	call   f0101e5e <strlen>
f0101ec4:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0101ec7:	ff 75 0c             	pushl  0xc(%ebp)
f0101eca:	01 d8                	add    %ebx,%eax
f0101ecc:	50                   	push   %eax
f0101ecd:	e8 c5 ff ff ff       	call   f0101e97 <strcpy>
	return dst;
}
f0101ed2:	89 d8                	mov    %ebx,%eax
f0101ed4:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101ed7:	c9                   	leave  
f0101ed8:	c3                   	ret    

f0101ed9 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0101ed9:	55                   	push   %ebp
f0101eda:	89 e5                	mov    %esp,%ebp
f0101edc:	56                   	push   %esi
f0101edd:	53                   	push   %ebx
f0101ede:	8b 75 08             	mov    0x8(%ebp),%esi
f0101ee1:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101ee4:	89 f3                	mov    %esi,%ebx
f0101ee6:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101ee9:	89 f2                	mov    %esi,%edx
f0101eeb:	eb 0f                	jmp    f0101efc <strncpy+0x23>
		*dst++ = *src;
f0101eed:	83 c2 01             	add    $0x1,%edx
f0101ef0:	0f b6 01             	movzbl (%ecx),%eax
f0101ef3:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0101ef6:	80 39 01             	cmpb   $0x1,(%ecx)
f0101ef9:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101efc:	39 da                	cmp    %ebx,%edx
f0101efe:	75 ed                	jne    f0101eed <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0101f00:	89 f0                	mov    %esi,%eax
f0101f02:	5b                   	pop    %ebx
f0101f03:	5e                   	pop    %esi
f0101f04:	5d                   	pop    %ebp
f0101f05:	c3                   	ret    

f0101f06 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0101f06:	55                   	push   %ebp
f0101f07:	89 e5                	mov    %esp,%ebp
f0101f09:	56                   	push   %esi
f0101f0a:	53                   	push   %ebx
f0101f0b:	8b 75 08             	mov    0x8(%ebp),%esi
f0101f0e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101f11:	8b 55 10             	mov    0x10(%ebp),%edx
f0101f14:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0101f16:	85 d2                	test   %edx,%edx
f0101f18:	74 21                	je     f0101f3b <strlcpy+0x35>
f0101f1a:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0101f1e:	89 f2                	mov    %esi,%edx
f0101f20:	eb 09                	jmp    f0101f2b <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0101f22:	83 c2 01             	add    $0x1,%edx
f0101f25:	83 c1 01             	add    $0x1,%ecx
f0101f28:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0101f2b:	39 c2                	cmp    %eax,%edx
f0101f2d:	74 09                	je     f0101f38 <strlcpy+0x32>
f0101f2f:	0f b6 19             	movzbl (%ecx),%ebx
f0101f32:	84 db                	test   %bl,%bl
f0101f34:	75 ec                	jne    f0101f22 <strlcpy+0x1c>
f0101f36:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f0101f38:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0101f3b:	29 f0                	sub    %esi,%eax
}
f0101f3d:	5b                   	pop    %ebx
f0101f3e:	5e                   	pop    %esi
f0101f3f:	5d                   	pop    %ebp
f0101f40:	c3                   	ret    

f0101f41 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0101f41:	55                   	push   %ebp
f0101f42:	89 e5                	mov    %esp,%ebp
f0101f44:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101f47:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0101f4a:	eb 06                	jmp    f0101f52 <strcmp+0x11>
		p++, q++;
f0101f4c:	83 c1 01             	add    $0x1,%ecx
f0101f4f:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0101f52:	0f b6 01             	movzbl (%ecx),%eax
f0101f55:	84 c0                	test   %al,%al
f0101f57:	74 04                	je     f0101f5d <strcmp+0x1c>
f0101f59:	3a 02                	cmp    (%edx),%al
f0101f5b:	74 ef                	je     f0101f4c <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0101f5d:	0f b6 c0             	movzbl %al,%eax
f0101f60:	0f b6 12             	movzbl (%edx),%edx
f0101f63:	29 d0                	sub    %edx,%eax
}
f0101f65:	5d                   	pop    %ebp
f0101f66:	c3                   	ret    

f0101f67 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0101f67:	55                   	push   %ebp
f0101f68:	89 e5                	mov    %esp,%ebp
f0101f6a:	53                   	push   %ebx
f0101f6b:	8b 45 08             	mov    0x8(%ebp),%eax
f0101f6e:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101f71:	89 c3                	mov    %eax,%ebx
f0101f73:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0101f76:	eb 06                	jmp    f0101f7e <strncmp+0x17>
		n--, p++, q++;
f0101f78:	83 c0 01             	add    $0x1,%eax
f0101f7b:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0101f7e:	39 d8                	cmp    %ebx,%eax
f0101f80:	74 15                	je     f0101f97 <strncmp+0x30>
f0101f82:	0f b6 08             	movzbl (%eax),%ecx
f0101f85:	84 c9                	test   %cl,%cl
f0101f87:	74 04                	je     f0101f8d <strncmp+0x26>
f0101f89:	3a 0a                	cmp    (%edx),%cl
f0101f8b:	74 eb                	je     f0101f78 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0101f8d:	0f b6 00             	movzbl (%eax),%eax
f0101f90:	0f b6 12             	movzbl (%edx),%edx
f0101f93:	29 d0                	sub    %edx,%eax
f0101f95:	eb 05                	jmp    f0101f9c <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0101f97:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0101f9c:	5b                   	pop    %ebx
f0101f9d:	5d                   	pop    %ebp
f0101f9e:	c3                   	ret    

f0101f9f <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0101f9f:	55                   	push   %ebp
f0101fa0:	89 e5                	mov    %esp,%ebp
f0101fa2:	8b 45 08             	mov    0x8(%ebp),%eax
f0101fa5:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101fa9:	eb 07                	jmp    f0101fb2 <strchr+0x13>
		if (*s == c)
f0101fab:	38 ca                	cmp    %cl,%dl
f0101fad:	74 0f                	je     f0101fbe <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0101faf:	83 c0 01             	add    $0x1,%eax
f0101fb2:	0f b6 10             	movzbl (%eax),%edx
f0101fb5:	84 d2                	test   %dl,%dl
f0101fb7:	75 f2                	jne    f0101fab <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0101fb9:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101fbe:	5d                   	pop    %ebp
f0101fbf:	c3                   	ret    

f0101fc0 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0101fc0:	55                   	push   %ebp
f0101fc1:	89 e5                	mov    %esp,%ebp
f0101fc3:	8b 45 08             	mov    0x8(%ebp),%eax
f0101fc6:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101fca:	eb 03                	jmp    f0101fcf <strfind+0xf>
f0101fcc:	83 c0 01             	add    $0x1,%eax
f0101fcf:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0101fd2:	38 ca                	cmp    %cl,%dl
f0101fd4:	74 04                	je     f0101fda <strfind+0x1a>
f0101fd6:	84 d2                	test   %dl,%dl
f0101fd8:	75 f2                	jne    f0101fcc <strfind+0xc>
			break;
	return (char *) s;
}
f0101fda:	5d                   	pop    %ebp
f0101fdb:	c3                   	ret    

f0101fdc <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0101fdc:	55                   	push   %ebp
f0101fdd:	89 e5                	mov    %esp,%ebp
f0101fdf:	57                   	push   %edi
f0101fe0:	56                   	push   %esi
f0101fe1:	53                   	push   %ebx
f0101fe2:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101fe5:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0101fe8:	85 c9                	test   %ecx,%ecx
f0101fea:	74 36                	je     f0102022 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0101fec:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0101ff2:	75 28                	jne    f010201c <memset+0x40>
f0101ff4:	f6 c1 03             	test   $0x3,%cl
f0101ff7:	75 23                	jne    f010201c <memset+0x40>
		c &= 0xFF;
f0101ff9:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0101ffd:	89 d3                	mov    %edx,%ebx
f0101fff:	c1 e3 08             	shl    $0x8,%ebx
f0102002:	89 d6                	mov    %edx,%esi
f0102004:	c1 e6 18             	shl    $0x18,%esi
f0102007:	89 d0                	mov    %edx,%eax
f0102009:	c1 e0 10             	shl    $0x10,%eax
f010200c:	09 f0                	or     %esi,%eax
f010200e:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f0102010:	89 d8                	mov    %ebx,%eax
f0102012:	09 d0                	or     %edx,%eax
f0102014:	c1 e9 02             	shr    $0x2,%ecx
f0102017:	fc                   	cld    
f0102018:	f3 ab                	rep stos %eax,%es:(%edi)
f010201a:	eb 06                	jmp    f0102022 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f010201c:	8b 45 0c             	mov    0xc(%ebp),%eax
f010201f:	fc                   	cld    
f0102020:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0102022:	89 f8                	mov    %edi,%eax
f0102024:	5b                   	pop    %ebx
f0102025:	5e                   	pop    %esi
f0102026:	5f                   	pop    %edi
f0102027:	5d                   	pop    %ebp
f0102028:	c3                   	ret    

f0102029 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0102029:	55                   	push   %ebp
f010202a:	89 e5                	mov    %esp,%ebp
f010202c:	57                   	push   %edi
f010202d:	56                   	push   %esi
f010202e:	8b 45 08             	mov    0x8(%ebp),%eax
f0102031:	8b 75 0c             	mov    0xc(%ebp),%esi
f0102034:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0102037:	39 c6                	cmp    %eax,%esi
f0102039:	73 35                	jae    f0102070 <memmove+0x47>
f010203b:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f010203e:	39 d0                	cmp    %edx,%eax
f0102040:	73 2e                	jae    f0102070 <memmove+0x47>
		s += n;
		d += n;
f0102042:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0102045:	89 d6                	mov    %edx,%esi
f0102047:	09 fe                	or     %edi,%esi
f0102049:	f7 c6 03 00 00 00    	test   $0x3,%esi
f010204f:	75 13                	jne    f0102064 <memmove+0x3b>
f0102051:	f6 c1 03             	test   $0x3,%cl
f0102054:	75 0e                	jne    f0102064 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f0102056:	83 ef 04             	sub    $0x4,%edi
f0102059:	8d 72 fc             	lea    -0x4(%edx),%esi
f010205c:	c1 e9 02             	shr    $0x2,%ecx
f010205f:	fd                   	std    
f0102060:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0102062:	eb 09                	jmp    f010206d <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0102064:	83 ef 01             	sub    $0x1,%edi
f0102067:	8d 72 ff             	lea    -0x1(%edx),%esi
f010206a:	fd                   	std    
f010206b:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f010206d:	fc                   	cld    
f010206e:	eb 1d                	jmp    f010208d <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0102070:	89 f2                	mov    %esi,%edx
f0102072:	09 c2                	or     %eax,%edx
f0102074:	f6 c2 03             	test   $0x3,%dl
f0102077:	75 0f                	jne    f0102088 <memmove+0x5f>
f0102079:	f6 c1 03             	test   $0x3,%cl
f010207c:	75 0a                	jne    f0102088 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f010207e:	c1 e9 02             	shr    $0x2,%ecx
f0102081:	89 c7                	mov    %eax,%edi
f0102083:	fc                   	cld    
f0102084:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0102086:	eb 05                	jmp    f010208d <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0102088:	89 c7                	mov    %eax,%edi
f010208a:	fc                   	cld    
f010208b:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f010208d:	5e                   	pop    %esi
f010208e:	5f                   	pop    %edi
f010208f:	5d                   	pop    %ebp
f0102090:	c3                   	ret    

f0102091 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0102091:	55                   	push   %ebp
f0102092:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0102094:	ff 75 10             	pushl  0x10(%ebp)
f0102097:	ff 75 0c             	pushl  0xc(%ebp)
f010209a:	ff 75 08             	pushl  0x8(%ebp)
f010209d:	e8 87 ff ff ff       	call   f0102029 <memmove>
}
f01020a2:	c9                   	leave  
f01020a3:	c3                   	ret    

f01020a4 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01020a4:	55                   	push   %ebp
f01020a5:	89 e5                	mov    %esp,%ebp
f01020a7:	56                   	push   %esi
f01020a8:	53                   	push   %ebx
f01020a9:	8b 45 08             	mov    0x8(%ebp),%eax
f01020ac:	8b 55 0c             	mov    0xc(%ebp),%edx
f01020af:	89 c6                	mov    %eax,%esi
f01020b1:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01020b4:	eb 1a                	jmp    f01020d0 <memcmp+0x2c>
		if (*s1 != *s2)
f01020b6:	0f b6 08             	movzbl (%eax),%ecx
f01020b9:	0f b6 1a             	movzbl (%edx),%ebx
f01020bc:	38 d9                	cmp    %bl,%cl
f01020be:	74 0a                	je     f01020ca <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f01020c0:	0f b6 c1             	movzbl %cl,%eax
f01020c3:	0f b6 db             	movzbl %bl,%ebx
f01020c6:	29 d8                	sub    %ebx,%eax
f01020c8:	eb 0f                	jmp    f01020d9 <memcmp+0x35>
		s1++, s2++;
f01020ca:	83 c0 01             	add    $0x1,%eax
f01020cd:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01020d0:	39 f0                	cmp    %esi,%eax
f01020d2:	75 e2                	jne    f01020b6 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01020d4:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01020d9:	5b                   	pop    %ebx
f01020da:	5e                   	pop    %esi
f01020db:	5d                   	pop    %ebp
f01020dc:	c3                   	ret    

f01020dd <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01020dd:	55                   	push   %ebp
f01020de:	89 e5                	mov    %esp,%ebp
f01020e0:	53                   	push   %ebx
f01020e1:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f01020e4:	89 c1                	mov    %eax,%ecx
f01020e6:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f01020e9:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01020ed:	eb 0a                	jmp    f01020f9 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f01020ef:	0f b6 10             	movzbl (%eax),%edx
f01020f2:	39 da                	cmp    %ebx,%edx
f01020f4:	74 07                	je     f01020fd <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01020f6:	83 c0 01             	add    $0x1,%eax
f01020f9:	39 c8                	cmp    %ecx,%eax
f01020fb:	72 f2                	jb     f01020ef <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01020fd:	5b                   	pop    %ebx
f01020fe:	5d                   	pop    %ebp
f01020ff:	c3                   	ret    

f0102100 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0102100:	55                   	push   %ebp
f0102101:	89 e5                	mov    %esp,%ebp
f0102103:	57                   	push   %edi
f0102104:	56                   	push   %esi
f0102105:	53                   	push   %ebx
f0102106:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0102109:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010210c:	eb 03                	jmp    f0102111 <strtol+0x11>
		s++;
f010210e:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0102111:	0f b6 01             	movzbl (%ecx),%eax
f0102114:	3c 20                	cmp    $0x20,%al
f0102116:	74 f6                	je     f010210e <strtol+0xe>
f0102118:	3c 09                	cmp    $0x9,%al
f010211a:	74 f2                	je     f010210e <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f010211c:	3c 2b                	cmp    $0x2b,%al
f010211e:	75 0a                	jne    f010212a <strtol+0x2a>
		s++;
f0102120:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0102123:	bf 00 00 00 00       	mov    $0x0,%edi
f0102128:	eb 11                	jmp    f010213b <strtol+0x3b>
f010212a:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f010212f:	3c 2d                	cmp    $0x2d,%al
f0102131:	75 08                	jne    f010213b <strtol+0x3b>
		s++, neg = 1;
f0102133:	83 c1 01             	add    $0x1,%ecx
f0102136:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f010213b:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0102141:	75 15                	jne    f0102158 <strtol+0x58>
f0102143:	80 39 30             	cmpb   $0x30,(%ecx)
f0102146:	75 10                	jne    f0102158 <strtol+0x58>
f0102148:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f010214c:	75 7c                	jne    f01021ca <strtol+0xca>
		s += 2, base = 16;
f010214e:	83 c1 02             	add    $0x2,%ecx
f0102151:	bb 10 00 00 00       	mov    $0x10,%ebx
f0102156:	eb 16                	jmp    f010216e <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f0102158:	85 db                	test   %ebx,%ebx
f010215a:	75 12                	jne    f010216e <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f010215c:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0102161:	80 39 30             	cmpb   $0x30,(%ecx)
f0102164:	75 08                	jne    f010216e <strtol+0x6e>
		s++, base = 8;
f0102166:	83 c1 01             	add    $0x1,%ecx
f0102169:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f010216e:	b8 00 00 00 00       	mov    $0x0,%eax
f0102173:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0102176:	0f b6 11             	movzbl (%ecx),%edx
f0102179:	8d 72 d0             	lea    -0x30(%edx),%esi
f010217c:	89 f3                	mov    %esi,%ebx
f010217e:	80 fb 09             	cmp    $0x9,%bl
f0102181:	77 08                	ja     f010218b <strtol+0x8b>
			dig = *s - '0';
f0102183:	0f be d2             	movsbl %dl,%edx
f0102186:	83 ea 30             	sub    $0x30,%edx
f0102189:	eb 22                	jmp    f01021ad <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f010218b:	8d 72 9f             	lea    -0x61(%edx),%esi
f010218e:	89 f3                	mov    %esi,%ebx
f0102190:	80 fb 19             	cmp    $0x19,%bl
f0102193:	77 08                	ja     f010219d <strtol+0x9d>
			dig = *s - 'a' + 10;
f0102195:	0f be d2             	movsbl %dl,%edx
f0102198:	83 ea 57             	sub    $0x57,%edx
f010219b:	eb 10                	jmp    f01021ad <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f010219d:	8d 72 bf             	lea    -0x41(%edx),%esi
f01021a0:	89 f3                	mov    %esi,%ebx
f01021a2:	80 fb 19             	cmp    $0x19,%bl
f01021a5:	77 16                	ja     f01021bd <strtol+0xbd>
			dig = *s - 'A' + 10;
f01021a7:	0f be d2             	movsbl %dl,%edx
f01021aa:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f01021ad:	3b 55 10             	cmp    0x10(%ebp),%edx
f01021b0:	7d 0b                	jge    f01021bd <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f01021b2:	83 c1 01             	add    $0x1,%ecx
f01021b5:	0f af 45 10          	imul   0x10(%ebp),%eax
f01021b9:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f01021bb:	eb b9                	jmp    f0102176 <strtol+0x76>

	if (endptr)
f01021bd:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01021c1:	74 0d                	je     f01021d0 <strtol+0xd0>
		*endptr = (char *) s;
f01021c3:	8b 75 0c             	mov    0xc(%ebp),%esi
f01021c6:	89 0e                	mov    %ecx,(%esi)
f01021c8:	eb 06                	jmp    f01021d0 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01021ca:	85 db                	test   %ebx,%ebx
f01021cc:	74 98                	je     f0102166 <strtol+0x66>
f01021ce:	eb 9e                	jmp    f010216e <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f01021d0:	89 c2                	mov    %eax,%edx
f01021d2:	f7 da                	neg    %edx
f01021d4:	85 ff                	test   %edi,%edi
f01021d6:	0f 45 c2             	cmovne %edx,%eax
}
f01021d9:	5b                   	pop    %ebx
f01021da:	5e                   	pop    %esi
f01021db:	5f                   	pop    %edi
f01021dc:	5d                   	pop    %ebp
f01021dd:	c3                   	ret    
f01021de:	66 90                	xchg   %ax,%ax

f01021e0 <__udivdi3>:
f01021e0:	55                   	push   %ebp
f01021e1:	57                   	push   %edi
f01021e2:	56                   	push   %esi
f01021e3:	53                   	push   %ebx
f01021e4:	83 ec 1c             	sub    $0x1c,%esp
f01021e7:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f01021eb:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f01021ef:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f01021f3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01021f7:	85 f6                	test   %esi,%esi
f01021f9:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01021fd:	89 ca                	mov    %ecx,%edx
f01021ff:	89 f8                	mov    %edi,%eax
f0102201:	75 3d                	jne    f0102240 <__udivdi3+0x60>
f0102203:	39 cf                	cmp    %ecx,%edi
f0102205:	0f 87 c5 00 00 00    	ja     f01022d0 <__udivdi3+0xf0>
f010220b:	85 ff                	test   %edi,%edi
f010220d:	89 fd                	mov    %edi,%ebp
f010220f:	75 0b                	jne    f010221c <__udivdi3+0x3c>
f0102211:	b8 01 00 00 00       	mov    $0x1,%eax
f0102216:	31 d2                	xor    %edx,%edx
f0102218:	f7 f7                	div    %edi
f010221a:	89 c5                	mov    %eax,%ebp
f010221c:	89 c8                	mov    %ecx,%eax
f010221e:	31 d2                	xor    %edx,%edx
f0102220:	f7 f5                	div    %ebp
f0102222:	89 c1                	mov    %eax,%ecx
f0102224:	89 d8                	mov    %ebx,%eax
f0102226:	89 cf                	mov    %ecx,%edi
f0102228:	f7 f5                	div    %ebp
f010222a:	89 c3                	mov    %eax,%ebx
f010222c:	89 d8                	mov    %ebx,%eax
f010222e:	89 fa                	mov    %edi,%edx
f0102230:	83 c4 1c             	add    $0x1c,%esp
f0102233:	5b                   	pop    %ebx
f0102234:	5e                   	pop    %esi
f0102235:	5f                   	pop    %edi
f0102236:	5d                   	pop    %ebp
f0102237:	c3                   	ret    
f0102238:	90                   	nop
f0102239:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0102240:	39 ce                	cmp    %ecx,%esi
f0102242:	77 74                	ja     f01022b8 <__udivdi3+0xd8>
f0102244:	0f bd fe             	bsr    %esi,%edi
f0102247:	83 f7 1f             	xor    $0x1f,%edi
f010224a:	0f 84 98 00 00 00    	je     f01022e8 <__udivdi3+0x108>
f0102250:	bb 20 00 00 00       	mov    $0x20,%ebx
f0102255:	89 f9                	mov    %edi,%ecx
f0102257:	89 c5                	mov    %eax,%ebp
f0102259:	29 fb                	sub    %edi,%ebx
f010225b:	d3 e6                	shl    %cl,%esi
f010225d:	89 d9                	mov    %ebx,%ecx
f010225f:	d3 ed                	shr    %cl,%ebp
f0102261:	89 f9                	mov    %edi,%ecx
f0102263:	d3 e0                	shl    %cl,%eax
f0102265:	09 ee                	or     %ebp,%esi
f0102267:	89 d9                	mov    %ebx,%ecx
f0102269:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010226d:	89 d5                	mov    %edx,%ebp
f010226f:	8b 44 24 08          	mov    0x8(%esp),%eax
f0102273:	d3 ed                	shr    %cl,%ebp
f0102275:	89 f9                	mov    %edi,%ecx
f0102277:	d3 e2                	shl    %cl,%edx
f0102279:	89 d9                	mov    %ebx,%ecx
f010227b:	d3 e8                	shr    %cl,%eax
f010227d:	09 c2                	or     %eax,%edx
f010227f:	89 d0                	mov    %edx,%eax
f0102281:	89 ea                	mov    %ebp,%edx
f0102283:	f7 f6                	div    %esi
f0102285:	89 d5                	mov    %edx,%ebp
f0102287:	89 c3                	mov    %eax,%ebx
f0102289:	f7 64 24 0c          	mull   0xc(%esp)
f010228d:	39 d5                	cmp    %edx,%ebp
f010228f:	72 10                	jb     f01022a1 <__udivdi3+0xc1>
f0102291:	8b 74 24 08          	mov    0x8(%esp),%esi
f0102295:	89 f9                	mov    %edi,%ecx
f0102297:	d3 e6                	shl    %cl,%esi
f0102299:	39 c6                	cmp    %eax,%esi
f010229b:	73 07                	jae    f01022a4 <__udivdi3+0xc4>
f010229d:	39 d5                	cmp    %edx,%ebp
f010229f:	75 03                	jne    f01022a4 <__udivdi3+0xc4>
f01022a1:	83 eb 01             	sub    $0x1,%ebx
f01022a4:	31 ff                	xor    %edi,%edi
f01022a6:	89 d8                	mov    %ebx,%eax
f01022a8:	89 fa                	mov    %edi,%edx
f01022aa:	83 c4 1c             	add    $0x1c,%esp
f01022ad:	5b                   	pop    %ebx
f01022ae:	5e                   	pop    %esi
f01022af:	5f                   	pop    %edi
f01022b0:	5d                   	pop    %ebp
f01022b1:	c3                   	ret    
f01022b2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01022b8:	31 ff                	xor    %edi,%edi
f01022ba:	31 db                	xor    %ebx,%ebx
f01022bc:	89 d8                	mov    %ebx,%eax
f01022be:	89 fa                	mov    %edi,%edx
f01022c0:	83 c4 1c             	add    $0x1c,%esp
f01022c3:	5b                   	pop    %ebx
f01022c4:	5e                   	pop    %esi
f01022c5:	5f                   	pop    %edi
f01022c6:	5d                   	pop    %ebp
f01022c7:	c3                   	ret    
f01022c8:	90                   	nop
f01022c9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01022d0:	89 d8                	mov    %ebx,%eax
f01022d2:	f7 f7                	div    %edi
f01022d4:	31 ff                	xor    %edi,%edi
f01022d6:	89 c3                	mov    %eax,%ebx
f01022d8:	89 d8                	mov    %ebx,%eax
f01022da:	89 fa                	mov    %edi,%edx
f01022dc:	83 c4 1c             	add    $0x1c,%esp
f01022df:	5b                   	pop    %ebx
f01022e0:	5e                   	pop    %esi
f01022e1:	5f                   	pop    %edi
f01022e2:	5d                   	pop    %ebp
f01022e3:	c3                   	ret    
f01022e4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01022e8:	39 ce                	cmp    %ecx,%esi
f01022ea:	72 0c                	jb     f01022f8 <__udivdi3+0x118>
f01022ec:	31 db                	xor    %ebx,%ebx
f01022ee:	3b 44 24 08          	cmp    0x8(%esp),%eax
f01022f2:	0f 87 34 ff ff ff    	ja     f010222c <__udivdi3+0x4c>
f01022f8:	bb 01 00 00 00       	mov    $0x1,%ebx
f01022fd:	e9 2a ff ff ff       	jmp    f010222c <__udivdi3+0x4c>
f0102302:	66 90                	xchg   %ax,%ax
f0102304:	66 90                	xchg   %ax,%ax
f0102306:	66 90                	xchg   %ax,%ax
f0102308:	66 90                	xchg   %ax,%ax
f010230a:	66 90                	xchg   %ax,%ax
f010230c:	66 90                	xchg   %ax,%ax
f010230e:	66 90                	xchg   %ax,%ax

f0102310 <__umoddi3>:
f0102310:	55                   	push   %ebp
f0102311:	57                   	push   %edi
f0102312:	56                   	push   %esi
f0102313:	53                   	push   %ebx
f0102314:	83 ec 1c             	sub    $0x1c,%esp
f0102317:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010231b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f010231f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0102323:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0102327:	85 d2                	test   %edx,%edx
f0102329:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010232d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0102331:	89 f3                	mov    %esi,%ebx
f0102333:	89 3c 24             	mov    %edi,(%esp)
f0102336:	89 74 24 04          	mov    %esi,0x4(%esp)
f010233a:	75 1c                	jne    f0102358 <__umoddi3+0x48>
f010233c:	39 f7                	cmp    %esi,%edi
f010233e:	76 50                	jbe    f0102390 <__umoddi3+0x80>
f0102340:	89 c8                	mov    %ecx,%eax
f0102342:	89 f2                	mov    %esi,%edx
f0102344:	f7 f7                	div    %edi
f0102346:	89 d0                	mov    %edx,%eax
f0102348:	31 d2                	xor    %edx,%edx
f010234a:	83 c4 1c             	add    $0x1c,%esp
f010234d:	5b                   	pop    %ebx
f010234e:	5e                   	pop    %esi
f010234f:	5f                   	pop    %edi
f0102350:	5d                   	pop    %ebp
f0102351:	c3                   	ret    
f0102352:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0102358:	39 f2                	cmp    %esi,%edx
f010235a:	89 d0                	mov    %edx,%eax
f010235c:	77 52                	ja     f01023b0 <__umoddi3+0xa0>
f010235e:	0f bd ea             	bsr    %edx,%ebp
f0102361:	83 f5 1f             	xor    $0x1f,%ebp
f0102364:	75 5a                	jne    f01023c0 <__umoddi3+0xb0>
f0102366:	3b 54 24 04          	cmp    0x4(%esp),%edx
f010236a:	0f 82 e0 00 00 00    	jb     f0102450 <__umoddi3+0x140>
f0102370:	39 0c 24             	cmp    %ecx,(%esp)
f0102373:	0f 86 d7 00 00 00    	jbe    f0102450 <__umoddi3+0x140>
f0102379:	8b 44 24 08          	mov    0x8(%esp),%eax
f010237d:	8b 54 24 04          	mov    0x4(%esp),%edx
f0102381:	83 c4 1c             	add    $0x1c,%esp
f0102384:	5b                   	pop    %ebx
f0102385:	5e                   	pop    %esi
f0102386:	5f                   	pop    %edi
f0102387:	5d                   	pop    %ebp
f0102388:	c3                   	ret    
f0102389:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0102390:	85 ff                	test   %edi,%edi
f0102392:	89 fd                	mov    %edi,%ebp
f0102394:	75 0b                	jne    f01023a1 <__umoddi3+0x91>
f0102396:	b8 01 00 00 00       	mov    $0x1,%eax
f010239b:	31 d2                	xor    %edx,%edx
f010239d:	f7 f7                	div    %edi
f010239f:	89 c5                	mov    %eax,%ebp
f01023a1:	89 f0                	mov    %esi,%eax
f01023a3:	31 d2                	xor    %edx,%edx
f01023a5:	f7 f5                	div    %ebp
f01023a7:	89 c8                	mov    %ecx,%eax
f01023a9:	f7 f5                	div    %ebp
f01023ab:	89 d0                	mov    %edx,%eax
f01023ad:	eb 99                	jmp    f0102348 <__umoddi3+0x38>
f01023af:	90                   	nop
f01023b0:	89 c8                	mov    %ecx,%eax
f01023b2:	89 f2                	mov    %esi,%edx
f01023b4:	83 c4 1c             	add    $0x1c,%esp
f01023b7:	5b                   	pop    %ebx
f01023b8:	5e                   	pop    %esi
f01023b9:	5f                   	pop    %edi
f01023ba:	5d                   	pop    %ebp
f01023bb:	c3                   	ret    
f01023bc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01023c0:	8b 34 24             	mov    (%esp),%esi
f01023c3:	bf 20 00 00 00       	mov    $0x20,%edi
f01023c8:	89 e9                	mov    %ebp,%ecx
f01023ca:	29 ef                	sub    %ebp,%edi
f01023cc:	d3 e0                	shl    %cl,%eax
f01023ce:	89 f9                	mov    %edi,%ecx
f01023d0:	89 f2                	mov    %esi,%edx
f01023d2:	d3 ea                	shr    %cl,%edx
f01023d4:	89 e9                	mov    %ebp,%ecx
f01023d6:	09 c2                	or     %eax,%edx
f01023d8:	89 d8                	mov    %ebx,%eax
f01023da:	89 14 24             	mov    %edx,(%esp)
f01023dd:	89 f2                	mov    %esi,%edx
f01023df:	d3 e2                	shl    %cl,%edx
f01023e1:	89 f9                	mov    %edi,%ecx
f01023e3:	89 54 24 04          	mov    %edx,0x4(%esp)
f01023e7:	8b 54 24 0c          	mov    0xc(%esp),%edx
f01023eb:	d3 e8                	shr    %cl,%eax
f01023ed:	89 e9                	mov    %ebp,%ecx
f01023ef:	89 c6                	mov    %eax,%esi
f01023f1:	d3 e3                	shl    %cl,%ebx
f01023f3:	89 f9                	mov    %edi,%ecx
f01023f5:	89 d0                	mov    %edx,%eax
f01023f7:	d3 e8                	shr    %cl,%eax
f01023f9:	89 e9                	mov    %ebp,%ecx
f01023fb:	09 d8                	or     %ebx,%eax
f01023fd:	89 d3                	mov    %edx,%ebx
f01023ff:	89 f2                	mov    %esi,%edx
f0102401:	f7 34 24             	divl   (%esp)
f0102404:	89 d6                	mov    %edx,%esi
f0102406:	d3 e3                	shl    %cl,%ebx
f0102408:	f7 64 24 04          	mull   0x4(%esp)
f010240c:	39 d6                	cmp    %edx,%esi
f010240e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0102412:	89 d1                	mov    %edx,%ecx
f0102414:	89 c3                	mov    %eax,%ebx
f0102416:	72 08                	jb     f0102420 <__umoddi3+0x110>
f0102418:	75 11                	jne    f010242b <__umoddi3+0x11b>
f010241a:	39 44 24 08          	cmp    %eax,0x8(%esp)
f010241e:	73 0b                	jae    f010242b <__umoddi3+0x11b>
f0102420:	2b 44 24 04          	sub    0x4(%esp),%eax
f0102424:	1b 14 24             	sbb    (%esp),%edx
f0102427:	89 d1                	mov    %edx,%ecx
f0102429:	89 c3                	mov    %eax,%ebx
f010242b:	8b 54 24 08          	mov    0x8(%esp),%edx
f010242f:	29 da                	sub    %ebx,%edx
f0102431:	19 ce                	sbb    %ecx,%esi
f0102433:	89 f9                	mov    %edi,%ecx
f0102435:	89 f0                	mov    %esi,%eax
f0102437:	d3 e0                	shl    %cl,%eax
f0102439:	89 e9                	mov    %ebp,%ecx
f010243b:	d3 ea                	shr    %cl,%edx
f010243d:	89 e9                	mov    %ebp,%ecx
f010243f:	d3 ee                	shr    %cl,%esi
f0102441:	09 d0                	or     %edx,%eax
f0102443:	89 f2                	mov    %esi,%edx
f0102445:	83 c4 1c             	add    $0x1c,%esp
f0102448:	5b                   	pop    %ebx
f0102449:	5e                   	pop    %esi
f010244a:	5f                   	pop    %edi
f010244b:	5d                   	pop    %ebp
f010244c:	c3                   	ret    
f010244d:	8d 76 00             	lea    0x0(%esi),%esi
f0102450:	29 f9                	sub    %edi,%ecx
f0102452:	19 d6                	sbb    %edx,%esi
f0102454:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102458:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010245c:	e9 18 ff ff ff       	jmp    f0102379 <__umoddi3+0x69>
