
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
f0100015:	b8 00 90 11 00       	mov    $0x119000,%eax
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
f0100034:	bc 00 90 11 f0       	mov    $0xf0119000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/env.h>
#include <kern/trap.h>

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
f0100046:	b8 50 2c 17 f0       	mov    $0xf0172c50,%eax
f010004b:	2d 26 1d 17 f0       	sub    $0xf0171d26,%eax
f0100050:	50                   	push   %eax
f0100051:	6a 00                	push   $0x0
f0100053:	68 26 1d 17 f0       	push   $0xf0171d26
f0100058:	e8 fc 43 00 00       	call   f0104459 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 ab 04 00 00       	call   f010050d <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 00 49 10 f0       	push   $0xf0104900
f010006f:	e8 8c 2e 00 00       	call   f0102f00 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 10 10 00 00       	call   f0101089 <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f0100079:	e8 ec 28 00 00       	call   f010296a <env_init>
	trap_init();
f010007e:	e8 ee 2e 00 00       	call   f0102f71 <trap_init>

#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
f0100083:	83 c4 08             	add    $0x8,%esp
f0100086:	6a 00                	push   $0x0
f0100088:	68 c6 fb 12 f0       	push   $0xf012fbc6
f010008d:	e8 8b 2a 00 00       	call   f0102b1d <env_create>
	// Touch all you want.
	ENV_CREATE(user_hello, ENV_TYPE_USER);
#endif // TEST*

	// We only have one user environment for now, so just run it.
	env_run(&envs[0]);
f0100092:	83 c4 04             	add    $0x4,%esp
f0100095:	ff 35 88 1f 17 f0    	pushl  0xf0171f88
f010009b:	e8 97 2d 00 00       	call   f0102e37 <env_run>

f01000a0 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000a0:	55                   	push   %ebp
f01000a1:	89 e5                	mov    %esp,%ebp
f01000a3:	56                   	push   %esi
f01000a4:	53                   	push   %ebx
f01000a5:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f01000a8:	83 3d 40 2c 17 f0 00 	cmpl   $0x0,0xf0172c40
f01000af:	75 37                	jne    f01000e8 <_panic+0x48>
		goto dead;
	panicstr = fmt;
f01000b1:	89 35 40 2c 17 f0    	mov    %esi,0xf0172c40

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f01000b7:	fa                   	cli    
f01000b8:	fc                   	cld    

	va_start(ap, fmt);
f01000b9:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000bc:	83 ec 04             	sub    $0x4,%esp
f01000bf:	ff 75 0c             	pushl  0xc(%ebp)
f01000c2:	ff 75 08             	pushl  0x8(%ebp)
f01000c5:	68 1b 49 10 f0       	push   $0xf010491b
f01000ca:	e8 31 2e 00 00       	call   f0102f00 <cprintf>
	vcprintf(fmt, ap);
f01000cf:	83 c4 08             	add    $0x8,%esp
f01000d2:	53                   	push   %ebx
f01000d3:	56                   	push   %esi
f01000d4:	e8 01 2e 00 00       	call   f0102eda <vcprintf>
	cprintf("\n");
f01000d9:	c7 04 24 a5 58 10 f0 	movl   $0xf01058a5,(%esp)
f01000e0:	e8 1b 2e 00 00       	call   f0102f00 <cprintf>
	va_end(ap);
f01000e5:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000e8:	83 ec 0c             	sub    $0xc,%esp
f01000eb:	6a 00                	push   $0x0
f01000ed:	e8 b0 06 00 00       	call   f01007a2 <monitor>
f01000f2:	83 c4 10             	add    $0x10,%esp
f01000f5:	eb f1                	jmp    f01000e8 <_panic+0x48>

f01000f7 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01000f7:	55                   	push   %ebp
f01000f8:	89 e5                	mov    %esp,%ebp
f01000fa:	53                   	push   %ebx
f01000fb:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f01000fe:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100101:	ff 75 0c             	pushl  0xc(%ebp)
f0100104:	ff 75 08             	pushl  0x8(%ebp)
f0100107:	68 33 49 10 f0       	push   $0xf0104933
f010010c:	e8 ef 2d 00 00       	call   f0102f00 <cprintf>
	vcprintf(fmt, ap);
f0100111:	83 c4 08             	add    $0x8,%esp
f0100114:	53                   	push   %ebx
f0100115:	ff 75 10             	pushl  0x10(%ebp)
f0100118:	e8 bd 2d 00 00       	call   f0102eda <vcprintf>
	cprintf("\n");
f010011d:	c7 04 24 a5 58 10 f0 	movl   $0xf01058a5,(%esp)
f0100124:	e8 d7 2d 00 00       	call   f0102f00 <cprintf>
	va_end(ap);
}
f0100129:	83 c4 10             	add    $0x10,%esp
f010012c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010012f:	c9                   	leave  
f0100130:	c3                   	ret    

f0100131 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100131:	55                   	push   %ebp
f0100132:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100134:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100139:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f010013a:	a8 01                	test   $0x1,%al
f010013c:	74 0b                	je     f0100149 <serial_proc_data+0x18>
f010013e:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100143:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100144:	0f b6 c0             	movzbl %al,%eax
f0100147:	eb 05                	jmp    f010014e <serial_proc_data+0x1d>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100149:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f010014e:	5d                   	pop    %ebp
f010014f:	c3                   	ret    

f0100150 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f0100150:	55                   	push   %ebp
f0100151:	89 e5                	mov    %esp,%ebp
f0100153:	53                   	push   %ebx
f0100154:	83 ec 04             	sub    $0x4,%esp
f0100157:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100159:	eb 2b                	jmp    f0100186 <cons_intr+0x36>
		if (c == 0)
f010015b:	85 c0                	test   %eax,%eax
f010015d:	74 27                	je     f0100186 <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f010015f:	8b 0d 64 1f 17 f0    	mov    0xf0171f64,%ecx
f0100165:	8d 51 01             	lea    0x1(%ecx),%edx
f0100168:	89 15 64 1f 17 f0    	mov    %edx,0xf0171f64
f010016e:	88 81 60 1d 17 f0    	mov    %al,-0xfe8e2a0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f0100174:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010017a:	75 0a                	jne    f0100186 <cons_intr+0x36>
			cons.wpos = 0;
f010017c:	c7 05 64 1f 17 f0 00 	movl   $0x0,0xf0171f64
f0100183:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f0100186:	ff d3                	call   *%ebx
f0100188:	83 f8 ff             	cmp    $0xffffffff,%eax
f010018b:	75 ce                	jne    f010015b <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f010018d:	83 c4 04             	add    $0x4,%esp
f0100190:	5b                   	pop    %ebx
f0100191:	5d                   	pop    %ebp
f0100192:	c3                   	ret    

f0100193 <kbd_proc_data>:
f0100193:	ba 64 00 00 00       	mov    $0x64,%edx
f0100198:	ec                   	in     (%dx),%al
	int c;
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
f0100199:	a8 01                	test   $0x1,%al
f010019b:	0f 84 f8 00 00 00    	je     f0100299 <kbd_proc_data+0x106>
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
f01001a1:	a8 20                	test   $0x20,%al
f01001a3:	0f 85 f6 00 00 00    	jne    f010029f <kbd_proc_data+0x10c>
f01001a9:	ba 60 00 00 00       	mov    $0x60,%edx
f01001ae:	ec                   	in     (%dx),%al
f01001af:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01001b1:	3c e0                	cmp    $0xe0,%al
f01001b3:	75 0d                	jne    f01001c2 <kbd_proc_data+0x2f>
		// E0 escape character
		shift |= E0ESC;
f01001b5:	83 0d 40 1d 17 f0 40 	orl    $0x40,0xf0171d40
		return 0;
f01001bc:	b8 00 00 00 00       	mov    $0x0,%eax
f01001c1:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01001c2:	55                   	push   %ebp
f01001c3:	89 e5                	mov    %esp,%ebp
f01001c5:	53                   	push   %ebx
f01001c6:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f01001c9:	84 c0                	test   %al,%al
f01001cb:	79 36                	jns    f0100203 <kbd_proc_data+0x70>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01001cd:	8b 0d 40 1d 17 f0    	mov    0xf0171d40,%ecx
f01001d3:	89 cb                	mov    %ecx,%ebx
f01001d5:	83 e3 40             	and    $0x40,%ebx
f01001d8:	83 e0 7f             	and    $0x7f,%eax
f01001db:	85 db                	test   %ebx,%ebx
f01001dd:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01001e0:	0f b6 d2             	movzbl %dl,%edx
f01001e3:	0f b6 82 a0 4a 10 f0 	movzbl -0xfefb560(%edx),%eax
f01001ea:	83 c8 40             	or     $0x40,%eax
f01001ed:	0f b6 c0             	movzbl %al,%eax
f01001f0:	f7 d0                	not    %eax
f01001f2:	21 c8                	and    %ecx,%eax
f01001f4:	a3 40 1d 17 f0       	mov    %eax,0xf0171d40
		return 0;
f01001f9:	b8 00 00 00 00       	mov    $0x0,%eax
f01001fe:	e9 a4 00 00 00       	jmp    f01002a7 <kbd_proc_data+0x114>
	} else if (shift & E0ESC) {
f0100203:	8b 0d 40 1d 17 f0    	mov    0xf0171d40,%ecx
f0100209:	f6 c1 40             	test   $0x40,%cl
f010020c:	74 0e                	je     f010021c <kbd_proc_data+0x89>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f010020e:	83 c8 80             	or     $0xffffff80,%eax
f0100211:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100213:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100216:	89 0d 40 1d 17 f0    	mov    %ecx,0xf0171d40
	}

	shift |= shiftcode[data];
f010021c:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f010021f:	0f b6 82 a0 4a 10 f0 	movzbl -0xfefb560(%edx),%eax
f0100226:	0b 05 40 1d 17 f0    	or     0xf0171d40,%eax
f010022c:	0f b6 8a a0 49 10 f0 	movzbl -0xfefb660(%edx),%ecx
f0100233:	31 c8                	xor    %ecx,%eax
f0100235:	a3 40 1d 17 f0       	mov    %eax,0xf0171d40

	c = charcode[shift & (CTL | SHIFT)][data];
f010023a:	89 c1                	mov    %eax,%ecx
f010023c:	83 e1 03             	and    $0x3,%ecx
f010023f:	8b 0c 8d 80 49 10 f0 	mov    -0xfefb680(,%ecx,4),%ecx
f0100246:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f010024a:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f010024d:	a8 08                	test   $0x8,%al
f010024f:	74 1b                	je     f010026c <kbd_proc_data+0xd9>
		if ('a' <= c && c <= 'z')
f0100251:	89 da                	mov    %ebx,%edx
f0100253:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100256:	83 f9 19             	cmp    $0x19,%ecx
f0100259:	77 05                	ja     f0100260 <kbd_proc_data+0xcd>
			c += 'A' - 'a';
f010025b:	83 eb 20             	sub    $0x20,%ebx
f010025e:	eb 0c                	jmp    f010026c <kbd_proc_data+0xd9>
		else if ('A' <= c && c <= 'Z')
f0100260:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f0100263:	8d 4b 20             	lea    0x20(%ebx),%ecx
f0100266:	83 fa 19             	cmp    $0x19,%edx
f0100269:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f010026c:	f7 d0                	not    %eax
f010026e:	a8 06                	test   $0x6,%al
f0100270:	75 33                	jne    f01002a5 <kbd_proc_data+0x112>
f0100272:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f0100278:	75 2b                	jne    f01002a5 <kbd_proc_data+0x112>
		cprintf("Rebooting!\n");
f010027a:	83 ec 0c             	sub    $0xc,%esp
f010027d:	68 4d 49 10 f0       	push   $0xf010494d
f0100282:	e8 79 2c 00 00       	call   f0102f00 <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100287:	ba 92 00 00 00       	mov    $0x92,%edx
f010028c:	b8 03 00 00 00       	mov    $0x3,%eax
f0100291:	ee                   	out    %al,(%dx)
f0100292:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100295:	89 d8                	mov    %ebx,%eax
f0100297:	eb 0e                	jmp    f01002a7 <kbd_proc_data+0x114>
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
f0100299:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f010029e:	c3                   	ret    
	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
		return -1;
f010029f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01002a4:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002a5:	89 d8                	mov    %ebx,%eax
}
f01002a7:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01002aa:	c9                   	leave  
f01002ab:	c3                   	ret    

f01002ac <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01002ac:	55                   	push   %ebp
f01002ad:	89 e5                	mov    %esp,%ebp
f01002af:	57                   	push   %edi
f01002b0:	56                   	push   %esi
f01002b1:	53                   	push   %ebx
f01002b2:	83 ec 1c             	sub    $0x1c,%esp
f01002b5:	89 c7                	mov    %eax,%edi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01002b7:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002bc:	be fd 03 00 00       	mov    $0x3fd,%esi
f01002c1:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002c6:	eb 09                	jmp    f01002d1 <cons_putc+0x25>
f01002c8:	89 ca                	mov    %ecx,%edx
f01002ca:	ec                   	in     (%dx),%al
f01002cb:	ec                   	in     (%dx),%al
f01002cc:	ec                   	in     (%dx),%al
f01002cd:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f01002ce:	83 c3 01             	add    $0x1,%ebx
f01002d1:	89 f2                	mov    %esi,%edx
f01002d3:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01002d4:	a8 20                	test   $0x20,%al
f01002d6:	75 08                	jne    f01002e0 <cons_putc+0x34>
f01002d8:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01002de:	7e e8                	jle    f01002c8 <cons_putc+0x1c>
f01002e0:	89 f8                	mov    %edi,%eax
f01002e2:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002e5:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01002ea:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01002eb:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002f0:	be 79 03 00 00       	mov    $0x379,%esi
f01002f5:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002fa:	eb 09                	jmp    f0100305 <cons_putc+0x59>
f01002fc:	89 ca                	mov    %ecx,%edx
f01002fe:	ec                   	in     (%dx),%al
f01002ff:	ec                   	in     (%dx),%al
f0100300:	ec                   	in     (%dx),%al
f0100301:	ec                   	in     (%dx),%al
f0100302:	83 c3 01             	add    $0x1,%ebx
f0100305:	89 f2                	mov    %esi,%edx
f0100307:	ec                   	in     (%dx),%al
f0100308:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f010030e:	7f 04                	jg     f0100314 <cons_putc+0x68>
f0100310:	84 c0                	test   %al,%al
f0100312:	79 e8                	jns    f01002fc <cons_putc+0x50>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100314:	ba 78 03 00 00       	mov    $0x378,%edx
f0100319:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f010031d:	ee                   	out    %al,(%dx)
f010031e:	ba 7a 03 00 00       	mov    $0x37a,%edx
f0100323:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100328:	ee                   	out    %al,(%dx)
f0100329:	b8 08 00 00 00       	mov    $0x8,%eax
f010032e:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f010032f:	89 fa                	mov    %edi,%edx
f0100331:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100337:	89 f8                	mov    %edi,%eax
f0100339:	80 cc 07             	or     $0x7,%ah
f010033c:	85 d2                	test   %edx,%edx
f010033e:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100341:	89 f8                	mov    %edi,%eax
f0100343:	0f b6 c0             	movzbl %al,%eax
f0100346:	83 f8 09             	cmp    $0x9,%eax
f0100349:	74 74                	je     f01003bf <cons_putc+0x113>
f010034b:	83 f8 09             	cmp    $0x9,%eax
f010034e:	7f 0a                	jg     f010035a <cons_putc+0xae>
f0100350:	83 f8 08             	cmp    $0x8,%eax
f0100353:	74 14                	je     f0100369 <cons_putc+0xbd>
f0100355:	e9 99 00 00 00       	jmp    f01003f3 <cons_putc+0x147>
f010035a:	83 f8 0a             	cmp    $0xa,%eax
f010035d:	74 3a                	je     f0100399 <cons_putc+0xed>
f010035f:	83 f8 0d             	cmp    $0xd,%eax
f0100362:	74 3d                	je     f01003a1 <cons_putc+0xf5>
f0100364:	e9 8a 00 00 00       	jmp    f01003f3 <cons_putc+0x147>
	case '\b':
		if (crt_pos > 0) {
f0100369:	0f b7 05 68 1f 17 f0 	movzwl 0xf0171f68,%eax
f0100370:	66 85 c0             	test   %ax,%ax
f0100373:	0f 84 e6 00 00 00    	je     f010045f <cons_putc+0x1b3>
			crt_pos--;
f0100379:	83 e8 01             	sub    $0x1,%eax
f010037c:	66 a3 68 1f 17 f0    	mov    %ax,0xf0171f68
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100382:	0f b7 c0             	movzwl %ax,%eax
f0100385:	66 81 e7 00 ff       	and    $0xff00,%di
f010038a:	83 cf 20             	or     $0x20,%edi
f010038d:	8b 15 6c 1f 17 f0    	mov    0xf0171f6c,%edx
f0100393:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100397:	eb 78                	jmp    f0100411 <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100399:	66 83 05 68 1f 17 f0 	addw   $0x50,0xf0171f68
f01003a0:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01003a1:	0f b7 05 68 1f 17 f0 	movzwl 0xf0171f68,%eax
f01003a8:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003ae:	c1 e8 16             	shr    $0x16,%eax
f01003b1:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003b4:	c1 e0 04             	shl    $0x4,%eax
f01003b7:	66 a3 68 1f 17 f0    	mov    %ax,0xf0171f68
f01003bd:	eb 52                	jmp    f0100411 <cons_putc+0x165>
		break;
	case '\t':
		cons_putc(' ');
f01003bf:	b8 20 00 00 00       	mov    $0x20,%eax
f01003c4:	e8 e3 fe ff ff       	call   f01002ac <cons_putc>
		cons_putc(' ');
f01003c9:	b8 20 00 00 00       	mov    $0x20,%eax
f01003ce:	e8 d9 fe ff ff       	call   f01002ac <cons_putc>
		cons_putc(' ');
f01003d3:	b8 20 00 00 00       	mov    $0x20,%eax
f01003d8:	e8 cf fe ff ff       	call   f01002ac <cons_putc>
		cons_putc(' ');
f01003dd:	b8 20 00 00 00       	mov    $0x20,%eax
f01003e2:	e8 c5 fe ff ff       	call   f01002ac <cons_putc>
		cons_putc(' ');
f01003e7:	b8 20 00 00 00       	mov    $0x20,%eax
f01003ec:	e8 bb fe ff ff       	call   f01002ac <cons_putc>
f01003f1:	eb 1e                	jmp    f0100411 <cons_putc+0x165>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f01003f3:	0f b7 05 68 1f 17 f0 	movzwl 0xf0171f68,%eax
f01003fa:	8d 50 01             	lea    0x1(%eax),%edx
f01003fd:	66 89 15 68 1f 17 f0 	mov    %dx,0xf0171f68
f0100404:	0f b7 c0             	movzwl %ax,%eax
f0100407:	8b 15 6c 1f 17 f0    	mov    0xf0171f6c,%edx
f010040d:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100411:	66 81 3d 68 1f 17 f0 	cmpw   $0x7cf,0xf0171f68
f0100418:	cf 07 
f010041a:	76 43                	jbe    f010045f <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010041c:	a1 6c 1f 17 f0       	mov    0xf0171f6c,%eax
f0100421:	83 ec 04             	sub    $0x4,%esp
f0100424:	68 00 0f 00 00       	push   $0xf00
f0100429:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f010042f:	52                   	push   %edx
f0100430:	50                   	push   %eax
f0100431:	e8 70 40 00 00       	call   f01044a6 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100436:	8b 15 6c 1f 17 f0    	mov    0xf0171f6c,%edx
f010043c:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f0100442:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f0100448:	83 c4 10             	add    $0x10,%esp
f010044b:	66 c7 00 20 07       	movw   $0x720,(%eax)
f0100450:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100453:	39 d0                	cmp    %edx,%eax
f0100455:	75 f4                	jne    f010044b <cons_putc+0x19f>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100457:	66 83 2d 68 1f 17 f0 	subw   $0x50,0xf0171f68
f010045e:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f010045f:	8b 0d 70 1f 17 f0    	mov    0xf0171f70,%ecx
f0100465:	b8 0e 00 00 00       	mov    $0xe,%eax
f010046a:	89 ca                	mov    %ecx,%edx
f010046c:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010046d:	0f b7 1d 68 1f 17 f0 	movzwl 0xf0171f68,%ebx
f0100474:	8d 71 01             	lea    0x1(%ecx),%esi
f0100477:	89 d8                	mov    %ebx,%eax
f0100479:	66 c1 e8 08          	shr    $0x8,%ax
f010047d:	89 f2                	mov    %esi,%edx
f010047f:	ee                   	out    %al,(%dx)
f0100480:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100485:	89 ca                	mov    %ecx,%edx
f0100487:	ee                   	out    %al,(%dx)
f0100488:	89 d8                	mov    %ebx,%eax
f010048a:	89 f2                	mov    %esi,%edx
f010048c:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f010048d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100490:	5b                   	pop    %ebx
f0100491:	5e                   	pop    %esi
f0100492:	5f                   	pop    %edi
f0100493:	5d                   	pop    %ebp
f0100494:	c3                   	ret    

f0100495 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f0100495:	80 3d 74 1f 17 f0 00 	cmpb   $0x0,0xf0171f74
f010049c:	74 11                	je     f01004af <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f010049e:	55                   	push   %ebp
f010049f:	89 e5                	mov    %esp,%ebp
f01004a1:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f01004a4:	b8 31 01 10 f0       	mov    $0xf0100131,%eax
f01004a9:	e8 a2 fc ff ff       	call   f0100150 <cons_intr>
}
f01004ae:	c9                   	leave  
f01004af:	f3 c3                	repz ret 

f01004b1 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01004b1:	55                   	push   %ebp
f01004b2:	89 e5                	mov    %esp,%ebp
f01004b4:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004b7:	b8 93 01 10 f0       	mov    $0xf0100193,%eax
f01004bc:	e8 8f fc ff ff       	call   f0100150 <cons_intr>
}
f01004c1:	c9                   	leave  
f01004c2:	c3                   	ret    

f01004c3 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004c3:	55                   	push   %ebp
f01004c4:	89 e5                	mov    %esp,%ebp
f01004c6:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01004c9:	e8 c7 ff ff ff       	call   f0100495 <serial_intr>
	kbd_intr();
f01004ce:	e8 de ff ff ff       	call   f01004b1 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004d3:	a1 60 1f 17 f0       	mov    0xf0171f60,%eax
f01004d8:	3b 05 64 1f 17 f0    	cmp    0xf0171f64,%eax
f01004de:	74 26                	je     f0100506 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01004e0:	8d 50 01             	lea    0x1(%eax),%edx
f01004e3:	89 15 60 1f 17 f0    	mov    %edx,0xf0171f60
f01004e9:	0f b6 88 60 1d 17 f0 	movzbl -0xfe8e2a0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f01004f0:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f01004f2:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01004f8:	75 11                	jne    f010050b <cons_getc+0x48>
			cons.rpos = 0;
f01004fa:	c7 05 60 1f 17 f0 00 	movl   $0x0,0xf0171f60
f0100501:	00 00 00 
f0100504:	eb 05                	jmp    f010050b <cons_getc+0x48>
		return c;
	}
	return 0;
f0100506:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010050b:	c9                   	leave  
f010050c:	c3                   	ret    

f010050d <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f010050d:	55                   	push   %ebp
f010050e:	89 e5                	mov    %esp,%ebp
f0100510:	57                   	push   %edi
f0100511:	56                   	push   %esi
f0100512:	53                   	push   %ebx
f0100513:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100516:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010051d:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100524:	5a a5 
	if (*cp != 0xA55A) {
f0100526:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010052d:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100531:	74 11                	je     f0100544 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100533:	c7 05 70 1f 17 f0 b4 	movl   $0x3b4,0xf0171f70
f010053a:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010053d:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f0100542:	eb 16                	jmp    f010055a <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100544:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010054b:	c7 05 70 1f 17 f0 d4 	movl   $0x3d4,0xf0171f70
f0100552:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100555:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f010055a:	8b 3d 70 1f 17 f0    	mov    0xf0171f70,%edi
f0100560:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100565:	89 fa                	mov    %edi,%edx
f0100567:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100568:	8d 5f 01             	lea    0x1(%edi),%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010056b:	89 da                	mov    %ebx,%edx
f010056d:	ec                   	in     (%dx),%al
f010056e:	0f b6 c8             	movzbl %al,%ecx
f0100571:	c1 e1 08             	shl    $0x8,%ecx
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100574:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100579:	89 fa                	mov    %edi,%edx
f010057b:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010057c:	89 da                	mov    %ebx,%edx
f010057e:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f010057f:	89 35 6c 1f 17 f0    	mov    %esi,0xf0171f6c
	crt_pos = pos;
f0100585:	0f b6 c0             	movzbl %al,%eax
f0100588:	09 c8                	or     %ecx,%eax
f010058a:	66 a3 68 1f 17 f0    	mov    %ax,0xf0171f68
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100590:	be fa 03 00 00       	mov    $0x3fa,%esi
f0100595:	b8 00 00 00 00       	mov    $0x0,%eax
f010059a:	89 f2                	mov    %esi,%edx
f010059c:	ee                   	out    %al,(%dx)
f010059d:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005a2:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01005a7:	ee                   	out    %al,(%dx)
f01005a8:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f01005ad:	b8 0c 00 00 00       	mov    $0xc,%eax
f01005b2:	89 da                	mov    %ebx,%edx
f01005b4:	ee                   	out    %al,(%dx)
f01005b5:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005ba:	b8 00 00 00 00       	mov    $0x0,%eax
f01005bf:	ee                   	out    %al,(%dx)
f01005c0:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005c5:	b8 03 00 00 00       	mov    $0x3,%eax
f01005ca:	ee                   	out    %al,(%dx)
f01005cb:	ba fc 03 00 00       	mov    $0x3fc,%edx
f01005d0:	b8 00 00 00 00       	mov    $0x0,%eax
f01005d5:	ee                   	out    %al,(%dx)
f01005d6:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005db:	b8 01 00 00 00       	mov    $0x1,%eax
f01005e0:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005e1:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01005e6:	ec                   	in     (%dx),%al
f01005e7:	89 c1                	mov    %eax,%ecx
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01005e9:	3c ff                	cmp    $0xff,%al
f01005eb:	0f 95 05 74 1f 17 f0 	setne  0xf0171f74
f01005f2:	89 f2                	mov    %esi,%edx
f01005f4:	ec                   	in     (%dx),%al
f01005f5:	89 da                	mov    %ebx,%edx
f01005f7:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01005f8:	80 f9 ff             	cmp    $0xff,%cl
f01005fb:	75 10                	jne    f010060d <cons_init+0x100>
		cprintf("Serial port does not exist!\n");
f01005fd:	83 ec 0c             	sub    $0xc,%esp
f0100600:	68 59 49 10 f0       	push   $0xf0104959
f0100605:	e8 f6 28 00 00       	call   f0102f00 <cprintf>
f010060a:	83 c4 10             	add    $0x10,%esp
}
f010060d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100610:	5b                   	pop    %ebx
f0100611:	5e                   	pop    %esi
f0100612:	5f                   	pop    %edi
f0100613:	5d                   	pop    %ebp
f0100614:	c3                   	ret    

f0100615 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100615:	55                   	push   %ebp
f0100616:	89 e5                	mov    %esp,%ebp
f0100618:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f010061b:	8b 45 08             	mov    0x8(%ebp),%eax
f010061e:	e8 89 fc ff ff       	call   f01002ac <cons_putc>
}
f0100623:	c9                   	leave  
f0100624:	c3                   	ret    

f0100625 <getchar>:

int
getchar(void)
{
f0100625:	55                   	push   %ebp
f0100626:	89 e5                	mov    %esp,%ebp
f0100628:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f010062b:	e8 93 fe ff ff       	call   f01004c3 <cons_getc>
f0100630:	85 c0                	test   %eax,%eax
f0100632:	74 f7                	je     f010062b <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100634:	c9                   	leave  
f0100635:	c3                   	ret    

f0100636 <iscons>:

int
iscons(int fdnum)
{
f0100636:	55                   	push   %ebp
f0100637:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100639:	b8 01 00 00 00       	mov    $0x1,%eax
f010063e:	5d                   	pop    %ebp
f010063f:	c3                   	ret    

f0100640 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100640:	55                   	push   %ebp
f0100641:	89 e5                	mov    %esp,%ebp
f0100643:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100646:	68 a0 4b 10 f0       	push   $0xf0104ba0
f010064b:	68 be 4b 10 f0       	push   $0xf0104bbe
f0100650:	68 c3 4b 10 f0       	push   $0xf0104bc3
f0100655:	e8 a6 28 00 00       	call   f0102f00 <cprintf>
f010065a:	83 c4 0c             	add    $0xc,%esp
f010065d:	68 4c 4c 10 f0       	push   $0xf0104c4c
f0100662:	68 cc 4b 10 f0       	push   $0xf0104bcc
f0100667:	68 c3 4b 10 f0       	push   $0xf0104bc3
f010066c:	e8 8f 28 00 00       	call   f0102f00 <cprintf>
	return 0;
}
f0100671:	b8 00 00 00 00       	mov    $0x0,%eax
f0100676:	c9                   	leave  
f0100677:	c3                   	ret    

f0100678 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100678:	55                   	push   %ebp
f0100679:	89 e5                	mov    %esp,%ebp
f010067b:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f010067e:	68 d5 4b 10 f0       	push   $0xf0104bd5
f0100683:	e8 78 28 00 00       	call   f0102f00 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100688:	83 c4 08             	add    $0x8,%esp
f010068b:	68 0c 00 10 00       	push   $0x10000c
f0100690:	68 74 4c 10 f0       	push   $0xf0104c74
f0100695:	e8 66 28 00 00       	call   f0102f00 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f010069a:	83 c4 0c             	add    $0xc,%esp
f010069d:	68 0c 00 10 00       	push   $0x10000c
f01006a2:	68 0c 00 10 f0       	push   $0xf010000c
f01006a7:	68 9c 4c 10 f0       	push   $0xf0104c9c
f01006ac:	e8 4f 28 00 00       	call   f0102f00 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006b1:	83 c4 0c             	add    $0xc,%esp
f01006b4:	68 e1 48 10 00       	push   $0x1048e1
f01006b9:	68 e1 48 10 f0       	push   $0xf01048e1
f01006be:	68 c0 4c 10 f0       	push   $0xf0104cc0
f01006c3:	e8 38 28 00 00       	call   f0102f00 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006c8:	83 c4 0c             	add    $0xc,%esp
f01006cb:	68 26 1d 17 00       	push   $0x171d26
f01006d0:	68 26 1d 17 f0       	push   $0xf0171d26
f01006d5:	68 e4 4c 10 f0       	push   $0xf0104ce4
f01006da:	e8 21 28 00 00       	call   f0102f00 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006df:	83 c4 0c             	add    $0xc,%esp
f01006e2:	68 50 2c 17 00       	push   $0x172c50
f01006e7:	68 50 2c 17 f0       	push   $0xf0172c50
f01006ec:	68 08 4d 10 f0       	push   $0xf0104d08
f01006f1:	e8 0a 28 00 00       	call   f0102f00 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f01006f6:	b8 4f 30 17 f0       	mov    $0xf017304f,%eax
f01006fb:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100700:	83 c4 08             	add    $0x8,%esp
f0100703:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f0100708:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f010070e:	85 c0                	test   %eax,%eax
f0100710:	0f 48 c2             	cmovs  %edx,%eax
f0100713:	c1 f8 0a             	sar    $0xa,%eax
f0100716:	50                   	push   %eax
f0100717:	68 2c 4d 10 f0       	push   $0xf0104d2c
f010071c:	e8 df 27 00 00       	call   f0102f00 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100721:	b8 00 00 00 00       	mov    $0x0,%eax
f0100726:	c9                   	leave  
f0100727:	c3                   	ret    

f0100728 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100728:	55                   	push   %ebp
f0100729:	89 e5                	mov    %esp,%ebp
f010072b:	56                   	push   %esi
f010072c:	53                   	push   %ebx
f010072d:	83 ec 2c             	sub    $0x2c,%esp

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f0100730:	89 eb                	mov    %ebp,%ebx
	uintptr_t ebp = read_ebp();
	struct Eipdebuginfo info;
	cprintf("Stack backtrace:\n");
f0100732:	68 ee 4b 10 f0       	push   $0xf0104bee
f0100737:	e8 c4 27 00 00       	call   f0102f00 <cprintf>
	while(ebp != 0){
f010073c:	83 c4 10             	add    $0x10,%esp
		cprintf("  ebp %08x  eip %08x  args %08x %08x %08x %08x %08x\n", ebp , 
				*((uintptr_t *)ebp + 1), *((uintptr_t *)ebp + 2), *((uintptr_t *)ebp + 3), 
			    *((uintptr_t *)ebp + 4), *((uintptr_t *)ebp + 5), *((uintptr_t *)ebp + 6));
		debuginfo_eip(*((uintptr_t *)ebp + 1), &info);
f010073f:	8d 75 e0             	lea    -0x20(%ebp),%esi
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	uintptr_t ebp = read_ebp();
	struct Eipdebuginfo info;
	cprintf("Stack backtrace:\n");
	while(ebp != 0){
f0100742:	eb 4e                	jmp    f0100792 <mon_backtrace+0x6a>
		cprintf("  ebp %08x  eip %08x  args %08x %08x %08x %08x %08x\n", ebp , 
f0100744:	ff 73 18             	pushl  0x18(%ebx)
f0100747:	ff 73 14             	pushl  0x14(%ebx)
f010074a:	ff 73 10             	pushl  0x10(%ebx)
f010074d:	ff 73 0c             	pushl  0xc(%ebx)
f0100750:	ff 73 08             	pushl  0x8(%ebx)
f0100753:	ff 73 04             	pushl  0x4(%ebx)
f0100756:	53                   	push   %ebx
f0100757:	68 58 4d 10 f0       	push   $0xf0104d58
f010075c:	e8 9f 27 00 00       	call   f0102f00 <cprintf>
				*((uintptr_t *)ebp + 1), *((uintptr_t *)ebp + 2), *((uintptr_t *)ebp + 3), 
			    *((uintptr_t *)ebp + 4), *((uintptr_t *)ebp + 5), *((uintptr_t *)ebp + 6));
		debuginfo_eip(*((uintptr_t *)ebp + 1), &info);
f0100761:	83 c4 18             	add    $0x18,%esp
f0100764:	56                   	push   %esi
f0100765:	ff 73 04             	pushl  0x4(%ebx)
f0100768:	e8 57 32 00 00       	call   f01039c4 <debuginfo_eip>
		cprintf("%s:%d: %.*s+%d\n", info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, 
f010076d:	83 c4 08             	add    $0x8,%esp
f0100770:	8b 43 04             	mov    0x4(%ebx),%eax
f0100773:	2b 45 f0             	sub    -0x10(%ebp),%eax
f0100776:	50                   	push   %eax
f0100777:	ff 75 e8             	pushl  -0x18(%ebp)
f010077a:	ff 75 ec             	pushl  -0x14(%ebp)
f010077d:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100780:	ff 75 e0             	pushl  -0x20(%ebp)
f0100783:	68 00 4c 10 f0       	push   $0xf0104c00
f0100788:	e8 73 27 00 00       	call   f0102f00 <cprintf>
				*((uintptr_t *)ebp + 1) - info.eip_fn_addr);
		ebp = *(uintptr_t *)ebp;
f010078d:	8b 1b                	mov    (%ebx),%ebx
f010078f:	83 c4 20             	add    $0x20,%esp
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	uintptr_t ebp = read_ebp();
	struct Eipdebuginfo info;
	cprintf("Stack backtrace:\n");
	while(ebp != 0){
f0100792:	85 db                	test   %ebx,%ebx
f0100794:	75 ae                	jne    f0100744 <mon_backtrace+0x1c>
		cprintf("%s:%d: %.*s+%d\n", info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, 
				*((uintptr_t *)ebp + 1) - info.eip_fn_addr);
		ebp = *(uintptr_t *)ebp;
	}
	return 0;
}
f0100796:	b8 00 00 00 00       	mov    $0x0,%eax
f010079b:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010079e:	5b                   	pop    %ebx
f010079f:	5e                   	pop    %esi
f01007a0:	5d                   	pop    %ebp
f01007a1:	c3                   	ret    

f01007a2 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01007a2:	55                   	push   %ebp
f01007a3:	89 e5                	mov    %esp,%ebp
f01007a5:	57                   	push   %edi
f01007a6:	56                   	push   %esi
f01007a7:	53                   	push   %ebx
f01007a8:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01007ab:	68 90 4d 10 f0       	push   $0xf0104d90
f01007b0:	e8 4b 27 00 00       	call   f0102f00 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01007b5:	c7 04 24 b4 4d 10 f0 	movl   $0xf0104db4,(%esp)
f01007bc:	e8 3f 27 00 00       	call   f0102f00 <cprintf>

	if (tf != NULL)
f01007c1:	83 c4 10             	add    $0x10,%esp
f01007c4:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f01007c8:	74 0e                	je     f01007d8 <monitor+0x36>
		print_trapframe(tf);
f01007ca:	83 ec 0c             	sub    $0xc,%esp
f01007cd:	ff 75 08             	pushl  0x8(%ebp)
f01007d0:	e8 67 2c 00 00       	call   f010343c <print_trapframe>
f01007d5:	83 c4 10             	add    $0x10,%esp

	while (1) {
		buf = readline("K> ");
f01007d8:	83 ec 0c             	sub    $0xc,%esp
f01007db:	68 10 4c 10 f0       	push   $0xf0104c10
f01007e0:	e8 1d 3a 00 00       	call   f0104202 <readline>
f01007e5:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f01007e7:	83 c4 10             	add    $0x10,%esp
f01007ea:	85 c0                	test   %eax,%eax
f01007ec:	74 ea                	je     f01007d8 <monitor+0x36>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f01007ee:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f01007f5:	be 00 00 00 00       	mov    $0x0,%esi
f01007fa:	eb 0a                	jmp    f0100806 <monitor+0x64>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f01007fc:	c6 03 00             	movb   $0x0,(%ebx)
f01007ff:	89 f7                	mov    %esi,%edi
f0100801:	8d 5b 01             	lea    0x1(%ebx),%ebx
f0100804:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100806:	0f b6 03             	movzbl (%ebx),%eax
f0100809:	84 c0                	test   %al,%al
f010080b:	74 63                	je     f0100870 <monitor+0xce>
f010080d:	83 ec 08             	sub    $0x8,%esp
f0100810:	0f be c0             	movsbl %al,%eax
f0100813:	50                   	push   %eax
f0100814:	68 14 4c 10 f0       	push   $0xf0104c14
f0100819:	e8 fe 3b 00 00       	call   f010441c <strchr>
f010081e:	83 c4 10             	add    $0x10,%esp
f0100821:	85 c0                	test   %eax,%eax
f0100823:	75 d7                	jne    f01007fc <monitor+0x5a>
			*buf++ = 0;
		if (*buf == 0)
f0100825:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100828:	74 46                	je     f0100870 <monitor+0xce>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f010082a:	83 fe 0f             	cmp    $0xf,%esi
f010082d:	75 14                	jne    f0100843 <monitor+0xa1>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f010082f:	83 ec 08             	sub    $0x8,%esp
f0100832:	6a 10                	push   $0x10
f0100834:	68 19 4c 10 f0       	push   $0xf0104c19
f0100839:	e8 c2 26 00 00       	call   f0102f00 <cprintf>
f010083e:	83 c4 10             	add    $0x10,%esp
f0100841:	eb 95                	jmp    f01007d8 <monitor+0x36>
			return 0;
		}
		argv[argc++] = buf;
f0100843:	8d 7e 01             	lea    0x1(%esi),%edi
f0100846:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f010084a:	eb 03                	jmp    f010084f <monitor+0xad>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f010084c:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f010084f:	0f b6 03             	movzbl (%ebx),%eax
f0100852:	84 c0                	test   %al,%al
f0100854:	74 ae                	je     f0100804 <monitor+0x62>
f0100856:	83 ec 08             	sub    $0x8,%esp
f0100859:	0f be c0             	movsbl %al,%eax
f010085c:	50                   	push   %eax
f010085d:	68 14 4c 10 f0       	push   $0xf0104c14
f0100862:	e8 b5 3b 00 00       	call   f010441c <strchr>
f0100867:	83 c4 10             	add    $0x10,%esp
f010086a:	85 c0                	test   %eax,%eax
f010086c:	74 de                	je     f010084c <monitor+0xaa>
f010086e:	eb 94                	jmp    f0100804 <monitor+0x62>
			buf++;
	}
	argv[argc] = 0;
f0100870:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100877:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100878:	85 f6                	test   %esi,%esi
f010087a:	0f 84 58 ff ff ff    	je     f01007d8 <monitor+0x36>
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100880:	83 ec 08             	sub    $0x8,%esp
f0100883:	68 be 4b 10 f0       	push   $0xf0104bbe
f0100888:	ff 75 a8             	pushl  -0x58(%ebp)
f010088b:	e8 2e 3b 00 00       	call   f01043be <strcmp>
f0100890:	83 c4 10             	add    $0x10,%esp
f0100893:	85 c0                	test   %eax,%eax
f0100895:	74 1e                	je     f01008b5 <monitor+0x113>
f0100897:	83 ec 08             	sub    $0x8,%esp
f010089a:	68 cc 4b 10 f0       	push   $0xf0104bcc
f010089f:	ff 75 a8             	pushl  -0x58(%ebp)
f01008a2:	e8 17 3b 00 00       	call   f01043be <strcmp>
f01008a7:	83 c4 10             	add    $0x10,%esp
f01008aa:	85 c0                	test   %eax,%eax
f01008ac:	75 2f                	jne    f01008dd <monitor+0x13b>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f01008ae:	b8 01 00 00 00       	mov    $0x1,%eax
f01008b3:	eb 05                	jmp    f01008ba <monitor+0x118>
		if (strcmp(argv[0], commands[i].name) == 0)
f01008b5:	b8 00 00 00 00       	mov    $0x0,%eax
			return commands[i].func(argc, argv, tf);
f01008ba:	83 ec 04             	sub    $0x4,%esp
f01008bd:	8d 14 00             	lea    (%eax,%eax,1),%edx
f01008c0:	01 d0                	add    %edx,%eax
f01008c2:	ff 75 08             	pushl  0x8(%ebp)
f01008c5:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f01008c8:	51                   	push   %ecx
f01008c9:	56                   	push   %esi
f01008ca:	ff 14 85 e4 4d 10 f0 	call   *-0xfefb21c(,%eax,4)
		print_trapframe(tf);

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f01008d1:	83 c4 10             	add    $0x10,%esp
f01008d4:	85 c0                	test   %eax,%eax
f01008d6:	78 1d                	js     f01008f5 <monitor+0x153>
f01008d8:	e9 fb fe ff ff       	jmp    f01007d8 <monitor+0x36>
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f01008dd:	83 ec 08             	sub    $0x8,%esp
f01008e0:	ff 75 a8             	pushl  -0x58(%ebp)
f01008e3:	68 36 4c 10 f0       	push   $0xf0104c36
f01008e8:	e8 13 26 00 00       	call   f0102f00 <cprintf>
f01008ed:	83 c4 10             	add    $0x10,%esp
f01008f0:	e9 e3 fe ff ff       	jmp    f01007d8 <monitor+0x36>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f01008f5:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01008f8:	5b                   	pop    %ebx
f01008f9:	5e                   	pop    %esi
f01008fa:	5f                   	pop    %edi
f01008fb:	5d                   	pop    %ebp
f01008fc:	c3                   	ret    

f01008fd <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f01008fd:	55                   	push   %ebp
f01008fe:	89 e5                	mov    %esp,%ebp
f0100900:	56                   	push   %esi
f0100901:	53                   	push   %ebx
f0100902:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100904:	83 ec 0c             	sub    $0xc,%esp
f0100907:	50                   	push   %eax
f0100908:	e8 8c 25 00 00       	call   f0102e99 <mc146818_read>
f010090d:	89 c6                	mov    %eax,%esi
f010090f:	83 c3 01             	add    $0x1,%ebx
f0100912:	89 1c 24             	mov    %ebx,(%esp)
f0100915:	e8 7f 25 00 00       	call   f0102e99 <mc146818_read>
f010091a:	c1 e0 08             	shl    $0x8,%eax
f010091d:	09 f0                	or     %esi,%eax
}
f010091f:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100922:	5b                   	pop    %ebx
f0100923:	5e                   	pop    %esi
f0100924:	5d                   	pop    %ebp
f0100925:	c3                   	ret    

f0100926 <check_va2pa>:
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f0100926:	89 d1                	mov    %edx,%ecx
f0100928:	c1 e9 16             	shr    $0x16,%ecx
f010092b:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f010092e:	a8 01                	test   $0x1,%al
f0100930:	74 52                	je     f0100984 <check_va2pa+0x5e>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100932:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100937:	89 c1                	mov    %eax,%ecx
f0100939:	c1 e9 0c             	shr    $0xc,%ecx
f010093c:	3b 0d 44 2c 17 f0    	cmp    0xf0172c44,%ecx
f0100942:	72 1b                	jb     f010095f <check_va2pa+0x39>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100944:	55                   	push   %ebp
f0100945:	89 e5                	mov    %esp,%ebp
f0100947:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010094a:	50                   	push   %eax
f010094b:	68 f4 4d 10 f0       	push   $0xf0104df4
f0100950:	68 24 03 00 00       	push   $0x324
f0100955:	68 e5 55 10 f0       	push   $0xf01055e5
f010095a:	e8 41 f7 ff ff       	call   f01000a0 <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f010095f:	c1 ea 0c             	shr    $0xc,%edx
f0100962:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100968:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f010096f:	89 c2                	mov    %eax,%edx
f0100971:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100974:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100979:	85 d2                	test   %edx,%edx
f010097b:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100980:	0f 44 c2             	cmove  %edx,%eax
f0100983:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f0100984:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f0100989:	c3                   	ret    

f010098a <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f010098a:	89 c2                	mov    %eax,%edx
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f010098c:	83 3d 78 1f 17 f0 00 	cmpl   $0x0,0xf0171f78
f0100993:	75 0f                	jne    f01009a4 <boot_alloc+0x1a>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100995:	b8 4f 3c 17 f0       	mov    $0xf0173c4f,%eax
f010099a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010099f:	a3 78 1f 17 f0       	mov    %eax,0xf0171f78
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	result = nextfree;
f01009a4:	a1 78 1f 17 f0       	mov    0xf0171f78,%eax
	if(n > 0){
f01009a9:	85 d2                	test   %edx,%edx
f01009ab:	74 62                	je     f0100a0f <boot_alloc+0x85>
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f01009ad:	55                   	push   %ebp
f01009ae:	89 e5                	mov    %esp,%ebp
f01009b0:	53                   	push   %ebx
f01009b1:	83 ec 04             	sub    $0x4,%esp
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01009b4:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01009b9:	77 12                	ja     f01009cd <boot_alloc+0x43>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01009bb:	50                   	push   %eax
f01009bc:	68 18 4e 10 f0       	push   $0xf0104e18
f01009c1:	6a 6c                	push   $0x6c
f01009c3:	68 e5 55 10 f0       	push   $0xf01055e5
f01009c8:	e8 d3 f6 ff ff       	call   f01000a0 <_panic>
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	result = nextfree;
	if(n > 0){
		if (PADDR(nextfree) + n > (npages + 1) * PGSIZE) {
f01009cd:	8d 9c 10 00 00 00 10 	lea    0x10000000(%eax,%edx,1),%ebx
f01009d4:	8b 0d 44 2c 17 f0    	mov    0xf0172c44,%ecx
f01009da:	83 c1 01             	add    $0x1,%ecx
f01009dd:	c1 e1 0c             	shl    $0xc,%ecx
f01009e0:	39 cb                	cmp    %ecx,%ebx
f01009e2:	76 14                	jbe    f01009f8 <boot_alloc+0x6e>
			panic("out of memory\n");
f01009e4:	83 ec 04             	sub    $0x4,%esp
f01009e7:	68 f1 55 10 f0       	push   $0xf01055f1
f01009ec:	6a 6d                	push   $0x6d
f01009ee:	68 e5 55 10 f0       	push   $0xf01055e5
f01009f3:	e8 a8 f6 ff ff       	call   f01000a0 <_panic>
		}
		nextfree = ROUNDUP((char *)nextfree + n, PGSIZE);
f01009f8:	8d 94 10 ff 0f 00 00 	lea    0xfff(%eax,%edx,1),%edx
f01009ff:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100a05:	89 15 78 1f 17 f0    	mov    %edx,0xf0171f78
	}
	return result;
}
f0100a0b:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100a0e:	c9                   	leave  
f0100a0f:	f3 c3                	repz ret 

f0100a11 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100a11:	55                   	push   %ebp
f0100a12:	89 e5                	mov    %esp,%ebp
f0100a14:	57                   	push   %edi
f0100a15:	56                   	push   %esi
f0100a16:	53                   	push   %ebx
f0100a17:	83 ec 2c             	sub    $0x2c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100a1a:	84 c0                	test   %al,%al
f0100a1c:	0f 85 72 02 00 00    	jne    f0100c94 <check_page_free_list+0x283>
f0100a22:	e9 7f 02 00 00       	jmp    f0100ca6 <check_page_free_list+0x295>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f0100a27:	83 ec 04             	sub    $0x4,%esp
f0100a2a:	68 3c 4e 10 f0       	push   $0xf0104e3c
f0100a2f:	68 62 02 00 00       	push   $0x262
f0100a34:	68 e5 55 10 f0       	push   $0xf01055e5
f0100a39:	e8 62 f6 ff ff       	call   f01000a0 <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100a3e:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100a41:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100a44:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100a47:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100a4a:	89 c2                	mov    %eax,%edx
f0100a4c:	2b 15 4c 2c 17 f0    	sub    0xf0172c4c,%edx
f0100a52:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100a58:	0f 95 c2             	setne  %dl
f0100a5b:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100a5e:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100a62:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100a64:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100a68:	8b 00                	mov    (%eax),%eax
f0100a6a:	85 c0                	test   %eax,%eax
f0100a6c:	75 dc                	jne    f0100a4a <check_page_free_list+0x39>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100a6e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a71:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100a77:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100a7a:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100a7d:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100a7f:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100a82:	a3 80 1f 17 f0       	mov    %eax,0xf0171f80
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100a87:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100a8c:	8b 1d 80 1f 17 f0    	mov    0xf0171f80,%ebx
f0100a92:	eb 53                	jmp    f0100ae7 <check_page_free_list+0xd6>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100a94:	89 d8                	mov    %ebx,%eax
f0100a96:	2b 05 4c 2c 17 f0    	sub    0xf0172c4c,%eax
f0100a9c:	c1 f8 03             	sar    $0x3,%eax
f0100a9f:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100aa2:	89 c2                	mov    %eax,%edx
f0100aa4:	c1 ea 16             	shr    $0x16,%edx
f0100aa7:	39 f2                	cmp    %esi,%edx
f0100aa9:	73 3a                	jae    f0100ae5 <check_page_free_list+0xd4>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100aab:	89 c2                	mov    %eax,%edx
f0100aad:	c1 ea 0c             	shr    $0xc,%edx
f0100ab0:	3b 15 44 2c 17 f0    	cmp    0xf0172c44,%edx
f0100ab6:	72 12                	jb     f0100aca <check_page_free_list+0xb9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ab8:	50                   	push   %eax
f0100ab9:	68 f4 4d 10 f0       	push   $0xf0104df4
f0100abe:	6a 56                	push   $0x56
f0100ac0:	68 00 56 10 f0       	push   $0xf0105600
f0100ac5:	e8 d6 f5 ff ff       	call   f01000a0 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100aca:	83 ec 04             	sub    $0x4,%esp
f0100acd:	68 80 00 00 00       	push   $0x80
f0100ad2:	68 97 00 00 00       	push   $0x97
f0100ad7:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100adc:	50                   	push   %eax
f0100add:	e8 77 39 00 00       	call   f0104459 <memset>
f0100ae2:	83 c4 10             	add    $0x10,%esp
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100ae5:	8b 1b                	mov    (%ebx),%ebx
f0100ae7:	85 db                	test   %ebx,%ebx
f0100ae9:	75 a9                	jne    f0100a94 <check_page_free_list+0x83>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100aeb:	b8 00 00 00 00       	mov    $0x0,%eax
f0100af0:	e8 95 fe ff ff       	call   f010098a <boot_alloc>
f0100af5:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100af8:	8b 15 80 1f 17 f0    	mov    0xf0171f80,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100afe:	8b 0d 4c 2c 17 f0    	mov    0xf0172c4c,%ecx
		assert(pp < pages + npages);
f0100b04:	a1 44 2c 17 f0       	mov    0xf0172c44,%eax
f0100b09:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0100b0c:	8d 3c c1             	lea    (%ecx,%eax,8),%edi
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100b0f:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100b12:	be 00 00 00 00       	mov    $0x0,%esi
f0100b17:	89 5d d0             	mov    %ebx,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b1a:	e9 30 01 00 00       	jmp    f0100c4f <check_page_free_list+0x23e>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100b1f:	39 ca                	cmp    %ecx,%edx
f0100b21:	73 19                	jae    f0100b3c <check_page_free_list+0x12b>
f0100b23:	68 0e 56 10 f0       	push   $0xf010560e
f0100b28:	68 1a 56 10 f0       	push   $0xf010561a
f0100b2d:	68 7c 02 00 00       	push   $0x27c
f0100b32:	68 e5 55 10 f0       	push   $0xf01055e5
f0100b37:	e8 64 f5 ff ff       	call   f01000a0 <_panic>
		assert(pp < pages + npages);
f0100b3c:	39 fa                	cmp    %edi,%edx
f0100b3e:	72 19                	jb     f0100b59 <check_page_free_list+0x148>
f0100b40:	68 2f 56 10 f0       	push   $0xf010562f
f0100b45:	68 1a 56 10 f0       	push   $0xf010561a
f0100b4a:	68 7d 02 00 00       	push   $0x27d
f0100b4f:	68 e5 55 10 f0       	push   $0xf01055e5
f0100b54:	e8 47 f5 ff ff       	call   f01000a0 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100b59:	89 d0                	mov    %edx,%eax
f0100b5b:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100b5e:	a8 07                	test   $0x7,%al
f0100b60:	74 19                	je     f0100b7b <check_page_free_list+0x16a>
f0100b62:	68 60 4e 10 f0       	push   $0xf0104e60
f0100b67:	68 1a 56 10 f0       	push   $0xf010561a
f0100b6c:	68 7e 02 00 00       	push   $0x27e
f0100b71:	68 e5 55 10 f0       	push   $0xf01055e5
f0100b76:	e8 25 f5 ff ff       	call   f01000a0 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100b7b:	c1 f8 03             	sar    $0x3,%eax
f0100b7e:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100b81:	85 c0                	test   %eax,%eax
f0100b83:	75 19                	jne    f0100b9e <check_page_free_list+0x18d>
f0100b85:	68 43 56 10 f0       	push   $0xf0105643
f0100b8a:	68 1a 56 10 f0       	push   $0xf010561a
f0100b8f:	68 81 02 00 00       	push   $0x281
f0100b94:	68 e5 55 10 f0       	push   $0xf01055e5
f0100b99:	e8 02 f5 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100b9e:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100ba3:	75 19                	jne    f0100bbe <check_page_free_list+0x1ad>
f0100ba5:	68 54 56 10 f0       	push   $0xf0105654
f0100baa:	68 1a 56 10 f0       	push   $0xf010561a
f0100baf:	68 82 02 00 00       	push   $0x282
f0100bb4:	68 e5 55 10 f0       	push   $0xf01055e5
f0100bb9:	e8 e2 f4 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100bbe:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100bc3:	75 19                	jne    f0100bde <check_page_free_list+0x1cd>
f0100bc5:	68 94 4e 10 f0       	push   $0xf0104e94
f0100bca:	68 1a 56 10 f0       	push   $0xf010561a
f0100bcf:	68 83 02 00 00       	push   $0x283
f0100bd4:	68 e5 55 10 f0       	push   $0xf01055e5
f0100bd9:	e8 c2 f4 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100bde:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100be3:	75 19                	jne    f0100bfe <check_page_free_list+0x1ed>
f0100be5:	68 6d 56 10 f0       	push   $0xf010566d
f0100bea:	68 1a 56 10 f0       	push   $0xf010561a
f0100bef:	68 84 02 00 00       	push   $0x284
f0100bf4:	68 e5 55 10 f0       	push   $0xf01055e5
f0100bf9:	e8 a2 f4 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100bfe:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100c03:	76 3f                	jbe    f0100c44 <check_page_free_list+0x233>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100c05:	89 c3                	mov    %eax,%ebx
f0100c07:	c1 eb 0c             	shr    $0xc,%ebx
f0100c0a:	39 5d c8             	cmp    %ebx,-0x38(%ebp)
f0100c0d:	77 12                	ja     f0100c21 <check_page_free_list+0x210>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100c0f:	50                   	push   %eax
f0100c10:	68 f4 4d 10 f0       	push   $0xf0104df4
f0100c15:	6a 56                	push   $0x56
f0100c17:	68 00 56 10 f0       	push   $0xf0105600
f0100c1c:	e8 7f f4 ff ff       	call   f01000a0 <_panic>
f0100c21:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100c26:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100c29:	76 1e                	jbe    f0100c49 <check_page_free_list+0x238>
f0100c2b:	68 b8 4e 10 f0       	push   $0xf0104eb8
f0100c30:	68 1a 56 10 f0       	push   $0xf010561a
f0100c35:	68 85 02 00 00       	push   $0x285
f0100c3a:	68 e5 55 10 f0       	push   $0xf01055e5
f0100c3f:	e8 5c f4 ff ff       	call   f01000a0 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100c44:	83 c6 01             	add    $0x1,%esi
f0100c47:	eb 04                	jmp    f0100c4d <check_page_free_list+0x23c>
		else
			++nfree_extmem;
f0100c49:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c4d:	8b 12                	mov    (%edx),%edx
f0100c4f:	85 d2                	test   %edx,%edx
f0100c51:	0f 85 c8 fe ff ff    	jne    f0100b1f <check_page_free_list+0x10e>
f0100c57:	8b 5d d0             	mov    -0x30(%ebp),%ebx
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100c5a:	85 f6                	test   %esi,%esi
f0100c5c:	7f 19                	jg     f0100c77 <check_page_free_list+0x266>
f0100c5e:	68 87 56 10 f0       	push   $0xf0105687
f0100c63:	68 1a 56 10 f0       	push   $0xf010561a
f0100c68:	68 8d 02 00 00       	push   $0x28d
f0100c6d:	68 e5 55 10 f0       	push   $0xf01055e5
f0100c72:	e8 29 f4 ff ff       	call   f01000a0 <_panic>
	assert(nfree_extmem > 0);
f0100c77:	85 db                	test   %ebx,%ebx
f0100c79:	7f 42                	jg     f0100cbd <check_page_free_list+0x2ac>
f0100c7b:	68 99 56 10 f0       	push   $0xf0105699
f0100c80:	68 1a 56 10 f0       	push   $0xf010561a
f0100c85:	68 8e 02 00 00       	push   $0x28e
f0100c8a:	68 e5 55 10 f0       	push   $0xf01055e5
f0100c8f:	e8 0c f4 ff ff       	call   f01000a0 <_panic>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100c94:	a1 80 1f 17 f0       	mov    0xf0171f80,%eax
f0100c99:	85 c0                	test   %eax,%eax
f0100c9b:	0f 85 9d fd ff ff    	jne    f0100a3e <check_page_free_list+0x2d>
f0100ca1:	e9 81 fd ff ff       	jmp    f0100a27 <check_page_free_list+0x16>
f0100ca6:	83 3d 80 1f 17 f0 00 	cmpl   $0x0,0xf0171f80
f0100cad:	0f 84 74 fd ff ff    	je     f0100a27 <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100cb3:	be 00 04 00 00       	mov    $0x400,%esi
f0100cb8:	e9 cf fd ff ff       	jmp    f0100a8c <check_page_free_list+0x7b>
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
}
f0100cbd:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100cc0:	5b                   	pop    %ebx
f0100cc1:	5e                   	pop    %esi
f0100cc2:	5f                   	pop    %edi
f0100cc3:	5d                   	pop    %ebp
f0100cc4:	c3                   	ret    

f0100cc5 <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100cc5:	55                   	push   %ebp
f0100cc6:	89 e5                	mov    %esp,%ebp
f0100cc8:	53                   	push   %ebx
f0100cc9:	83 ec 04             	sub    $0x4,%esp
f0100ccc:	8b 1d 80 1f 17 f0    	mov    0xf0171f80,%ebx
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	
	size_t i, io_page_i, ext_page_i, free_top;
	for (i = 0; i < npages; i++) {
f0100cd2:	ba 00 00 00 00       	mov    $0x0,%edx
f0100cd7:	b8 00 00 00 00       	mov    $0x0,%eax
f0100cdc:	eb 27                	jmp    f0100d05 <page_init+0x40>
f0100cde:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
		pages[i].pp_ref = 0;
f0100ce5:	89 d1                	mov    %edx,%ecx
f0100ce7:	03 0d 4c 2c 17 f0    	add    0xf0172c4c,%ecx
f0100ced:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = page_free_list;
f0100cf3:	89 19                	mov    %ebx,(%ecx)
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	
	size_t i, io_page_i, ext_page_i, free_top;
	for (i = 0; i < npages; i++) {
f0100cf5:	83 c0 01             	add    $0x1,%eax
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
f0100cf8:	89 d3                	mov    %edx,%ebx
f0100cfa:	03 1d 4c 2c 17 f0    	add    0xf0172c4c,%ebx
f0100d00:	ba 01 00 00 00       	mov    $0x1,%edx
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	
	size_t i, io_page_i, ext_page_i, free_top;
	for (i = 0; i < npages; i++) {
f0100d05:	3b 05 44 2c 17 f0    	cmp    0xf0172c44,%eax
f0100d0b:	72 d1                	jb     f0100cde <page_init+0x19>
f0100d0d:	84 d2                	test   %dl,%dl
f0100d0f:	74 06                	je     f0100d17 <page_init+0x52>
f0100d11:	89 1d 80 1f 17 f0    	mov    %ebx,0xf0171f80
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
  
	pages[0].pp_link = NULL;
f0100d17:	a1 4c 2c 17 f0       	mov    0xf0172c4c,%eax
f0100d1c:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pages[1].pp_link = NULL;
f0100d22:	a1 4c 2c 17 f0       	mov    0xf0172c4c,%eax
f0100d27:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)

	io_page_i = PGNUM(IOPHYSMEM);
	ext_page_i = PGNUM(EXTPHYSMEM);
	free_top = PGNUM(PADDR(boot_alloc(0)));
f0100d2e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d33:	e8 52 fc ff ff       	call   f010098a <boot_alloc>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100d38:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100d3d:	77 15                	ja     f0100d54 <page_init+0x8f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100d3f:	50                   	push   %eax
f0100d40:	68 18 4e 10 f0       	push   $0xf0104e18
f0100d45:	68 24 01 00 00       	push   $0x124
f0100d4a:	68 e5 55 10 f0       	push   $0xf01055e5
f0100d4f:	e8 4c f3 ff ff       	call   f01000a0 <_panic>
f0100d54:	8d 88 00 00 00 10    	lea    0x10000000(%eax),%ecx
f0100d5a:	c1 e9 0c             	shr    $0xc,%ecx

	pages[ext_page_i].pp_link = pages[io_page_i].pp_link;
f0100d5d:	a1 4c 2c 17 f0       	mov    0xf0172c4c,%eax
f0100d62:	8b 90 00 05 00 00    	mov    0x500(%eax),%edx
f0100d68:	89 90 00 08 00 00    	mov    %edx,0x800(%eax)
f0100d6e:	b8 00 05 00 00       	mov    $0x500,%eax
	for(i = io_page_i;i < ext_page_i;i++)
		pages[i].pp_link = NULL;
f0100d73:	8b 15 4c 2c 17 f0    	mov    0xf0172c4c,%edx
f0100d79:	c7 04 02 00 00 00 00 	movl   $0x0,(%edx,%eax,1)
f0100d80:	83 c0 08             	add    $0x8,%eax
	io_page_i = PGNUM(IOPHYSMEM);
	ext_page_i = PGNUM(EXTPHYSMEM);
	free_top = PGNUM(PADDR(boot_alloc(0)));

	pages[ext_page_i].pp_link = pages[io_page_i].pp_link;
	for(i = io_page_i;i < ext_page_i;i++)
f0100d83:	3d 00 08 00 00       	cmp    $0x800,%eax
f0100d88:	75 e9                	jne    f0100d73 <page_init+0xae>
		pages[i].pp_link = NULL;

	pages[free_top].pp_link = pages[ext_page_i].pp_link;
f0100d8a:	a1 4c 2c 17 f0       	mov    0xf0172c4c,%eax
f0100d8f:	8b 90 00 08 00 00    	mov    0x800(%eax),%edx
f0100d95:	89 14 c8             	mov    %edx,(%eax,%ecx,8)
	for (i = ext_page_i; i < free_top; i++)
f0100d98:	b8 00 01 00 00       	mov    $0x100,%eax
f0100d9d:	eb 10                	jmp    f0100daf <page_init+0xea>
		pages[i].pp_link = NULL;
f0100d9f:	8b 15 4c 2c 17 f0    	mov    0xf0172c4c,%edx
f0100da5:	c7 04 c2 00 00 00 00 	movl   $0x0,(%edx,%eax,8)
	pages[ext_page_i].pp_link = pages[io_page_i].pp_link;
	for(i = io_page_i;i < ext_page_i;i++)
		pages[i].pp_link = NULL;

	pages[free_top].pp_link = pages[ext_page_i].pp_link;
	for (i = ext_page_i; i < free_top; i++)
f0100dac:	83 c0 01             	add    $0x1,%eax
f0100daf:	39 c8                	cmp    %ecx,%eax
f0100db1:	72 ec                	jb     f0100d9f <page_init+0xda>
		pages[i].pp_link = NULL;

}
f0100db3:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100db6:	c9                   	leave  
f0100db7:	c3                   	ret    

f0100db8 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100db8:	55                   	push   %ebp
f0100db9:	89 e5                	mov    %esp,%ebp
f0100dbb:	53                   	push   %ebx
f0100dbc:	83 ec 04             	sub    $0x4,%esp
	//Fill this function in
	struct PageInfo *p = page_free_list;
f0100dbf:	8b 1d 80 1f 17 f0    	mov    0xf0171f80,%ebx
	if(p){
f0100dc5:	85 db                	test   %ebx,%ebx
f0100dc7:	74 5c                	je     f0100e25 <page_alloc+0x6d>
		page_free_list = p->pp_link;
f0100dc9:	8b 03                	mov    (%ebx),%eax
f0100dcb:	a3 80 1f 17 f0       	mov    %eax,0xf0171f80
		p->pp_link = NULL;
f0100dd0:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
		if(alloc_flags & ALLOC_ZERO){
			memset(page2kva(p), 0, PGSIZE);
		}
	}
	else return NULL;
	return p;
f0100dd6:	89 d8                	mov    %ebx,%eax
	//Fill this function in
	struct PageInfo *p = page_free_list;
	if(p){
		page_free_list = p->pp_link;
		p->pp_link = NULL;
		if(alloc_flags & ALLOC_ZERO){
f0100dd8:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100ddc:	74 4c                	je     f0100e2a <page_alloc+0x72>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100dde:	2b 05 4c 2c 17 f0    	sub    0xf0172c4c,%eax
f0100de4:	c1 f8 03             	sar    $0x3,%eax
f0100de7:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100dea:	89 c2                	mov    %eax,%edx
f0100dec:	c1 ea 0c             	shr    $0xc,%edx
f0100def:	3b 15 44 2c 17 f0    	cmp    0xf0172c44,%edx
f0100df5:	72 12                	jb     f0100e09 <page_alloc+0x51>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100df7:	50                   	push   %eax
f0100df8:	68 f4 4d 10 f0       	push   $0xf0104df4
f0100dfd:	6a 56                	push   $0x56
f0100dff:	68 00 56 10 f0       	push   $0xf0105600
f0100e04:	e8 97 f2 ff ff       	call   f01000a0 <_panic>
			memset(page2kva(p), 0, PGSIZE);
f0100e09:	83 ec 04             	sub    $0x4,%esp
f0100e0c:	68 00 10 00 00       	push   $0x1000
f0100e11:	6a 00                	push   $0x0
f0100e13:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100e18:	50                   	push   %eax
f0100e19:	e8 3b 36 00 00       	call   f0104459 <memset>
f0100e1e:	83 c4 10             	add    $0x10,%esp
		}
	}
	else return NULL;
	return p;
f0100e21:	89 d8                	mov    %ebx,%eax
f0100e23:	eb 05                	jmp    f0100e2a <page_alloc+0x72>
		p->pp_link = NULL;
		if(alloc_flags & ALLOC_ZERO){
			memset(page2kva(p), 0, PGSIZE);
		}
	}
	else return NULL;
f0100e25:	b8 00 00 00 00       	mov    $0x0,%eax
	return p;
}
f0100e2a:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100e2d:	c9                   	leave  
f0100e2e:	c3                   	ret    

f0100e2f <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100e2f:	55                   	push   %ebp
f0100e30:	89 e5                	mov    %esp,%ebp
f0100e32:	83 ec 08             	sub    $0x8,%esp
f0100e35:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
	if(pp->pp_ref != 0 || pp->pp_link!=NULL){
f0100e38:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100e3d:	75 05                	jne    f0100e44 <page_free+0x15>
f0100e3f:	83 38 00             	cmpl   $0x0,(%eax)
f0100e42:	74 17                	je     f0100e5b <page_free+0x2c>
		panic("pp->pp_ref is nonzero or pp->pp_link is not NULL\n");
f0100e44:	83 ec 04             	sub    $0x4,%esp
f0100e47:	68 00 4f 10 f0       	push   $0xf0104f00
f0100e4c:	68 57 01 00 00       	push   $0x157
f0100e51:	68 e5 55 10 f0       	push   $0xf01055e5
f0100e56:	e8 45 f2 ff ff       	call   f01000a0 <_panic>
	}
	pp->pp_link = page_free_list;
f0100e5b:	8b 15 80 1f 17 f0    	mov    0xf0171f80,%edx
f0100e61:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f0100e63:	a3 80 1f 17 f0       	mov    %eax,0xf0171f80


}
f0100e68:	c9                   	leave  
f0100e69:	c3                   	ret    

f0100e6a <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0100e6a:	55                   	push   %ebp
f0100e6b:	89 e5                	mov    %esp,%ebp
f0100e6d:	83 ec 08             	sub    $0x8,%esp
f0100e70:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0100e73:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0100e77:	83 e8 01             	sub    $0x1,%eax
f0100e7a:	66 89 42 04          	mov    %ax,0x4(%edx)
f0100e7e:	66 85 c0             	test   %ax,%ax
f0100e81:	75 0c                	jne    f0100e8f <page_decref+0x25>
		page_free(pp);
f0100e83:	83 ec 0c             	sub    $0xc,%esp
f0100e86:	52                   	push   %edx
f0100e87:	e8 a3 ff ff ff       	call   f0100e2f <page_free>
f0100e8c:	83 c4 10             	add    $0x10,%esp
}
f0100e8f:	c9                   	leave  
f0100e90:	c3                   	ret    

f0100e91 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100e91:	55                   	push   %ebp
f0100e92:	89 e5                	mov    %esp,%ebp
f0100e94:	56                   	push   %esi
f0100e95:	53                   	push   %ebx
f0100e96:	8b 75 0c             	mov    0xc(%ebp),%esi
	int pdr_i = PDX(va);
	pde_t *pde = &pgdir[pdr_i];
f0100e99:	89 f3                	mov    %esi,%ebx
f0100e9b:	c1 eb 16             	shr    $0x16,%ebx
f0100e9e:	c1 e3 02             	shl    $0x2,%ebx
f0100ea1:	03 5d 08             	add    0x8(%ebp),%ebx
	pte_t *pgt;
	if(!(*pde & PTE_P)){
f0100ea4:	f6 03 01             	testb  $0x1,(%ebx)
f0100ea7:	75 2f                	jne    f0100ed8 <pgdir_walk+0x47>
		if(!create)	
f0100ea9:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100ead:	74 64                	je     f0100f13 <pgdir_walk+0x82>
			return NULL;
		struct PageInfo *page = page_alloc(ALLOC_ZERO);
f0100eaf:	83 ec 0c             	sub    $0xc,%esp
f0100eb2:	6a 01                	push   $0x1
f0100eb4:	e8 ff fe ff ff       	call   f0100db8 <page_alloc>
		if(page == NULL) return NULL;
f0100eb9:	83 c4 10             	add    $0x10,%esp
f0100ebc:	85 c0                	test   %eax,%eax
f0100ebe:	74 5a                	je     f0100f1a <pgdir_walk+0x89>
		*pde = page2pa(page) | PTE_P | PTE_U | PTE_W;
f0100ec0:	89 c2                	mov    %eax,%edx
f0100ec2:	2b 15 4c 2c 17 f0    	sub    0xf0172c4c,%edx
f0100ec8:	c1 fa 03             	sar    $0x3,%edx
f0100ecb:	c1 e2 0c             	shl    $0xc,%edx
f0100ece:	83 ca 07             	or     $0x7,%edx
f0100ed1:	89 13                	mov    %edx,(%ebx)
		page->pp_ref ++;
f0100ed3:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
	}
	pgt = KADDR(PTE_ADDR(*pde));
f0100ed8:	8b 03                	mov    (%ebx),%eax
f0100eda:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100edf:	89 c2                	mov    %eax,%edx
f0100ee1:	c1 ea 0c             	shr    $0xc,%edx
f0100ee4:	3b 15 44 2c 17 f0    	cmp    0xf0172c44,%edx
f0100eea:	72 15                	jb     f0100f01 <pgdir_walk+0x70>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100eec:	50                   	push   %eax
f0100eed:	68 f4 4d 10 f0       	push   $0xf0104df4
f0100ef2:	68 8e 01 00 00       	push   $0x18e
f0100ef7:	68 e5 55 10 f0       	push   $0xf01055e5
f0100efc:	e8 9f f1 ff ff       	call   f01000a0 <_panic>
	
	return &pgt[PTX(va)];
f0100f01:	c1 ee 0a             	shr    $0xa,%esi
f0100f04:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f0100f0a:	8d 84 30 00 00 00 f0 	lea    -0x10000000(%eax,%esi,1),%eax
f0100f11:	eb 0c                	jmp    f0100f1f <pgdir_walk+0x8e>
	int pdr_i = PDX(va);
	pde_t *pde = &pgdir[pdr_i];
	pte_t *pgt;
	if(!(*pde & PTE_P)){
		if(!create)	
			return NULL;
f0100f13:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f18:	eb 05                	jmp    f0100f1f <pgdir_walk+0x8e>
		struct PageInfo *page = page_alloc(ALLOC_ZERO);
		if(page == NULL) return NULL;
f0100f1a:	b8 00 00 00 00       	mov    $0x0,%eax
		page->pp_ref ++;
	}
	pgt = KADDR(PTE_ADDR(*pde));
	
	return &pgt[PTX(va)];
}
f0100f1f:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100f22:	5b                   	pop    %ebx
f0100f23:	5e                   	pop    %esi
f0100f24:	5d                   	pop    %ebp
f0100f25:	c3                   	ret    

f0100f26 <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f0100f26:	55                   	push   %ebp
f0100f27:	89 e5                	mov    %esp,%ebp
f0100f29:	57                   	push   %edi
f0100f2a:	56                   	push   %esi
f0100f2b:	53                   	push   %ebx
f0100f2c:	83 ec 1c             	sub    $0x1c,%esp
f0100f2f:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0100f32:	c1 e9 0c             	shr    $0xc,%ecx
f0100f35:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	int i;
	for(i = 0; i < (size / PGSIZE); i++, va += PGSIZE, pa+=PGSIZE){
f0100f38:	89 d3                	mov    %edx,%ebx
f0100f3a:	bf 00 00 00 00       	mov    $0x0,%edi
f0100f3f:	8b 45 08             	mov    0x8(%ebp),%eax
f0100f42:	29 d0                	sub    %edx,%eax
f0100f44:	89 45 e0             	mov    %eax,-0x20(%ebp)
		pte_t* pte = pgdir_walk(pgdir,(const void *) va, 1);	
		if(pte!=NULL){
			*pte = pa|perm|PTE_P;
f0100f47:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100f4a:	83 c8 01             	or     $0x1,%eax
f0100f4d:	89 45 d8             	mov    %eax,-0x28(%ebp)
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	int i;
	for(i = 0; i < (size / PGSIZE); i++, va += PGSIZE, pa+=PGSIZE){
f0100f50:	eb 23                	jmp    f0100f75 <boot_map_region+0x4f>
		pte_t* pte = pgdir_walk(pgdir,(const void *) va, 1);	
f0100f52:	83 ec 04             	sub    $0x4,%esp
f0100f55:	6a 01                	push   $0x1
f0100f57:	53                   	push   %ebx
f0100f58:	ff 75 dc             	pushl  -0x24(%ebp)
f0100f5b:	e8 31 ff ff ff       	call   f0100e91 <pgdir_walk>
		if(pte!=NULL){
f0100f60:	83 c4 10             	add    $0x10,%esp
f0100f63:	85 c0                	test   %eax,%eax
f0100f65:	74 05                	je     f0100f6c <boot_map_region+0x46>
			*pte = pa|perm|PTE_P;
f0100f67:	0b 75 d8             	or     -0x28(%ebp),%esi
f0100f6a:	89 30                	mov    %esi,(%eax)
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	int i;
	for(i = 0; i < (size / PGSIZE); i++, va += PGSIZE, pa+=PGSIZE){
f0100f6c:	83 c7 01             	add    $0x1,%edi
f0100f6f:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0100f75:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100f78:	8d 34 18             	lea    (%eax,%ebx,1),%esi
f0100f7b:	3b 7d e4             	cmp    -0x1c(%ebp),%edi
f0100f7e:	75 d2                	jne    f0100f52 <boot_map_region+0x2c>
		pte_t* pte = pgdir_walk(pgdir,(const void *) va, 1);	
		if(pte!=NULL){
			*pte = pa|perm|PTE_P;
		}
	}
}
f0100f80:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100f83:	5b                   	pop    %ebx
f0100f84:	5e                   	pop    %esi
f0100f85:	5f                   	pop    %edi
f0100f86:	5d                   	pop    %ebp
f0100f87:	c3                   	ret    

f0100f88 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0100f88:	55                   	push   %ebp
f0100f89:	89 e5                	mov    %esp,%ebp
f0100f8b:	53                   	push   %ebx
f0100f8c:	83 ec 08             	sub    $0x8,%esp
f0100f8f:	8b 5d 10             	mov    0x10(%ebp),%ebx
	pte_t *pte = pgdir_walk(pgdir, va, 0);
f0100f92:	6a 00                	push   $0x0
f0100f94:	ff 75 0c             	pushl  0xc(%ebp)
f0100f97:	ff 75 08             	pushl  0x8(%ebp)
f0100f9a:	e8 f2 fe ff ff       	call   f0100e91 <pgdir_walk>
	if(pte == NULL)
f0100f9f:	83 c4 10             	add    $0x10,%esp
f0100fa2:	85 c0                	test   %eax,%eax
f0100fa4:	74 32                	je     f0100fd8 <page_lookup+0x50>
		return NULL;
	else{
		if(pte_store!=NULL)		
f0100fa6:	85 db                	test   %ebx,%ebx
f0100fa8:	74 02                	je     f0100fac <page_lookup+0x24>
			*pte_store = pte;
f0100faa:	89 03                	mov    %eax,(%ebx)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100fac:	8b 00                	mov    (%eax),%eax
f0100fae:	c1 e8 0c             	shr    $0xc,%eax
f0100fb1:	3b 05 44 2c 17 f0    	cmp    0xf0172c44,%eax
f0100fb7:	72 14                	jb     f0100fcd <page_lookup+0x45>
		panic("pa2page called with invalid pa");
f0100fb9:	83 ec 04             	sub    $0x4,%esp
f0100fbc:	68 34 4f 10 f0       	push   $0xf0104f34
f0100fc1:	6a 4f                	push   $0x4f
f0100fc3:	68 00 56 10 f0       	push   $0xf0105600
f0100fc8:	e8 d3 f0 ff ff       	call   f01000a0 <_panic>
	return &pages[PGNUM(pa)];
f0100fcd:	8b 15 4c 2c 17 f0    	mov    0xf0172c4c,%edx
f0100fd3:	8d 04 c2             	lea    (%edx,%eax,8),%eax
		
		return pa2page(PTE_ADDR(*pte));
f0100fd6:	eb 05                	jmp    f0100fdd <page_lookup+0x55>
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
	pte_t *pte = pgdir_walk(pgdir, va, 0);
	if(pte == NULL)
		return NULL;
f0100fd8:	b8 00 00 00 00       	mov    $0x0,%eax
			*pte_store = pte;
		
		return pa2page(PTE_ADDR(*pte));
	}

}
f0100fdd:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100fe0:	c9                   	leave  
f0100fe1:	c3                   	ret    

f0100fe2 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0100fe2:	55                   	push   %ebp
f0100fe3:	89 e5                	mov    %esp,%ebp
f0100fe5:	53                   	push   %ebx
f0100fe6:	83 ec 18             	sub    $0x18,%esp
f0100fe9:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
	pte_t *pte;
	struct PageInfo *pp = page_lookup(pgdir, va, &pte);
f0100fec:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100fef:	50                   	push   %eax
f0100ff0:	53                   	push   %ebx
f0100ff1:	ff 75 08             	pushl  0x8(%ebp)
f0100ff4:	e8 8f ff ff ff       	call   f0100f88 <page_lookup>
	if(pp!=NULL){
f0100ff9:	83 c4 10             	add    $0x10,%esp
f0100ffc:	85 c0                	test   %eax,%eax
f0100ffe:	74 18                	je     f0101018 <page_remove+0x36>
		page_decref(pp);
f0101000:	83 ec 0c             	sub    $0xc,%esp
f0101003:	50                   	push   %eax
f0101004:	e8 61 fe ff ff       	call   f0100e6a <page_decref>
		*pte = 0;
f0101009:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010100c:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0101012:	0f 01 3b             	invlpg (%ebx)
f0101015:	83 c4 10             	add    $0x10,%esp
		tlb_invalidate(pgdir, va);
	}
}
f0101018:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010101b:	c9                   	leave  
f010101c:	c3                   	ret    

f010101d <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f010101d:	55                   	push   %ebp
f010101e:	89 e5                	mov    %esp,%ebp
f0101020:	57                   	push   %edi
f0101021:	56                   	push   %esi
f0101022:	53                   	push   %ebx
f0101023:	83 ec 10             	sub    $0x10,%esp
f0101026:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101029:	8b 7d 10             	mov    0x10(%ebp),%edi
	pte_t *pte = pgdir_walk(pgdir, va, 1); 
f010102c:	6a 01                	push   $0x1
f010102e:	57                   	push   %edi
f010102f:	ff 75 08             	pushl  0x8(%ebp)
f0101032:	e8 5a fe ff ff       	call   f0100e91 <pgdir_walk>
	if(pte){
f0101037:	83 c4 10             	add    $0x10,%esp
f010103a:	85 c0                	test   %eax,%eax
f010103c:	74 3e                	je     f010107c <page_insert+0x5f>
f010103e:	89 c6                	mov    %eax,%esi
		pp->pp_ref ++;
f0101040:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
		if(PTE_ADDR(*pte))
f0101045:	f7 00 00 f0 ff ff    	testl  $0xfffff000,(%eax)
f010104b:	74 0f                	je     f010105c <page_insert+0x3f>
			page_remove(pgdir, va);
f010104d:	83 ec 08             	sub    $0x8,%esp
f0101050:	57                   	push   %edi
f0101051:	ff 75 08             	pushl  0x8(%ebp)
f0101054:	e8 89 ff ff ff       	call   f0100fe2 <page_remove>
f0101059:	83 c4 10             	add    $0x10,%esp
		*pte = page2pa(pp) | perm |PTE_P;
f010105c:	2b 1d 4c 2c 17 f0    	sub    0xf0172c4c,%ebx
f0101062:	c1 fb 03             	sar    $0x3,%ebx
f0101065:	c1 e3 0c             	shl    $0xc,%ebx
f0101068:	8b 45 14             	mov    0x14(%ebp),%eax
f010106b:	83 c8 01             	or     $0x1,%eax
f010106e:	09 c3                	or     %eax,%ebx
f0101070:	89 1e                	mov    %ebx,(%esi)
f0101072:	0f 01 3f             	invlpg (%edi)
		tlb_invalidate(pgdir, va);
		return 0;
f0101075:	b8 00 00 00 00       	mov    $0x0,%eax
f010107a:	eb 05                	jmp    f0101081 <page_insert+0x64>
	}
	return -E_NO_MEM;
f010107c:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	
}
f0101081:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101084:	5b                   	pop    %ebx
f0101085:	5e                   	pop    %esi
f0101086:	5f                   	pop    %edi
f0101087:	5d                   	pop    %ebp
f0101088:	c3                   	ret    

f0101089 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0101089:	55                   	push   %ebp
f010108a:	89 e5                	mov    %esp,%ebp
f010108c:	57                   	push   %edi
f010108d:	56                   	push   %esi
f010108e:	53                   	push   %ebx
f010108f:	83 ec 2c             	sub    $0x2c,%esp
{
	size_t basemem, extmem, ext16mem, totalmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	basemem = nvram_read(NVRAM_BASELO);
f0101092:	b8 15 00 00 00       	mov    $0x15,%eax
f0101097:	e8 61 f8 ff ff       	call   f01008fd <nvram_read>
f010109c:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f010109e:	b8 17 00 00 00       	mov    $0x17,%eax
f01010a3:	e8 55 f8 ff ff       	call   f01008fd <nvram_read>
f01010a8:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f01010aa:	b8 34 00 00 00       	mov    $0x34,%eax
f01010af:	e8 49 f8 ff ff       	call   f01008fd <nvram_read>
f01010b4:	c1 e0 06             	shl    $0x6,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (ext16mem)
f01010b7:	85 c0                	test   %eax,%eax
f01010b9:	74 07                	je     f01010c2 <mem_init+0x39>
		totalmem = 16 * 1024 + ext16mem;
f01010bb:	05 00 40 00 00       	add    $0x4000,%eax
f01010c0:	eb 0b                	jmp    f01010cd <mem_init+0x44>
	else if (extmem)
		totalmem = 1 * 1024 + extmem;
f01010c2:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f01010c8:	85 f6                	test   %esi,%esi
f01010ca:	0f 44 c3             	cmove  %ebx,%eax
	else
		totalmem = basemem;

	npages = totalmem / (PGSIZE / 1024);
f01010cd:	89 c2                	mov    %eax,%edx
f01010cf:	c1 ea 02             	shr    $0x2,%edx
f01010d2:	89 15 44 2c 17 f0    	mov    %edx,0xf0172c44
	npages_basemem = basemem / (PGSIZE / 1024);

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01010d8:	89 c2                	mov    %eax,%edx
f01010da:	29 da                	sub    %ebx,%edx
f01010dc:	52                   	push   %edx
f01010dd:	53                   	push   %ebx
f01010de:	50                   	push   %eax
f01010df:	68 54 4f 10 f0       	push   $0xf0104f54
f01010e4:	e8 17 1e 00 00       	call   f0102f00 <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f01010e9:	b8 00 10 00 00       	mov    $0x1000,%eax
f01010ee:	e8 97 f8 ff ff       	call   f010098a <boot_alloc>
f01010f3:	a3 48 2c 17 f0       	mov    %eax,0xf0172c48
	memset(kern_pgdir, 0, PGSIZE);
f01010f8:	83 c4 0c             	add    $0xc,%esp
f01010fb:	68 00 10 00 00       	push   $0x1000
f0101100:	6a 00                	push   $0x0
f0101102:	50                   	push   %eax
f0101103:	e8 51 33 00 00       	call   f0104459 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0101108:	a1 48 2c 17 f0       	mov    0xf0172c48,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010110d:	83 c4 10             	add    $0x10,%esp
f0101110:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101115:	77 15                	ja     f010112c <mem_init+0xa3>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101117:	50                   	push   %eax
f0101118:	68 18 4e 10 f0       	push   $0xf0104e18
f010111d:	68 94 00 00 00       	push   $0x94
f0101122:	68 e5 55 10 f0       	push   $0xf01055e5
f0101127:	e8 74 ef ff ff       	call   f01000a0 <_panic>
f010112c:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0101132:	83 ca 05             	or     $0x5,%edx
f0101135:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	pages = (struct PageInfo *) boot_alloc(npages * sizeof(struct PageInfo));
f010113b:	a1 44 2c 17 f0       	mov    0xf0172c44,%eax
f0101140:	c1 e0 03             	shl    $0x3,%eax
f0101143:	e8 42 f8 ff ff       	call   f010098a <boot_alloc>
f0101148:	a3 4c 2c 17 f0       	mov    %eax,0xf0172c4c
	memset(pages, 0, npages * sizeof(struct PageInfo));
f010114d:	83 ec 04             	sub    $0x4,%esp
f0101150:	8b 3d 44 2c 17 f0    	mov    0xf0172c44,%edi
f0101156:	8d 14 fd 00 00 00 00 	lea    0x0(,%edi,8),%edx
f010115d:	52                   	push   %edx
f010115e:	6a 00                	push   $0x0
f0101160:	50                   	push   %eax
f0101161:	e8 f3 32 00 00       	call   f0104459 <memset>

	//////////////////////////////////////////////////////////////////////
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.
	envs = (struct Env *) boot_alloc(NENV * sizeof(struct Env));
f0101166:	b8 00 80 01 00       	mov    $0x18000,%eax
f010116b:	e8 1a f8 ff ff       	call   f010098a <boot_alloc>
f0101170:	a3 88 1f 17 f0       	mov    %eax,0xf0171f88
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f0101175:	e8 4b fb ff ff       	call   f0100cc5 <page_init>

	check_page_free_list(1);
f010117a:	b8 01 00 00 00       	mov    $0x1,%eax
f010117f:	e8 8d f8 ff ff       	call   f0100a11 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f0101184:	83 c4 10             	add    $0x10,%esp
f0101187:	83 3d 4c 2c 17 f0 00 	cmpl   $0x0,0xf0172c4c
f010118e:	75 17                	jne    f01011a7 <mem_init+0x11e>
		panic("'pages' is a null pointer!");
f0101190:	83 ec 04             	sub    $0x4,%esp
f0101193:	68 aa 56 10 f0       	push   $0xf01056aa
f0101198:	68 9f 02 00 00       	push   $0x29f
f010119d:	68 e5 55 10 f0       	push   $0xf01055e5
f01011a2:	e8 f9 ee ff ff       	call   f01000a0 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01011a7:	a1 80 1f 17 f0       	mov    0xf0171f80,%eax
f01011ac:	bb 00 00 00 00       	mov    $0x0,%ebx
f01011b1:	eb 05                	jmp    f01011b8 <mem_init+0x12f>
		++nfree;
f01011b3:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01011b6:	8b 00                	mov    (%eax),%eax
f01011b8:	85 c0                	test   %eax,%eax
f01011ba:	75 f7                	jne    f01011b3 <mem_init+0x12a>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01011bc:	83 ec 0c             	sub    $0xc,%esp
f01011bf:	6a 00                	push   $0x0
f01011c1:	e8 f2 fb ff ff       	call   f0100db8 <page_alloc>
f01011c6:	89 c7                	mov    %eax,%edi
f01011c8:	83 c4 10             	add    $0x10,%esp
f01011cb:	85 c0                	test   %eax,%eax
f01011cd:	75 19                	jne    f01011e8 <mem_init+0x15f>
f01011cf:	68 c5 56 10 f0       	push   $0xf01056c5
f01011d4:	68 1a 56 10 f0       	push   $0xf010561a
f01011d9:	68 a7 02 00 00       	push   $0x2a7
f01011de:	68 e5 55 10 f0       	push   $0xf01055e5
f01011e3:	e8 b8 ee ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f01011e8:	83 ec 0c             	sub    $0xc,%esp
f01011eb:	6a 00                	push   $0x0
f01011ed:	e8 c6 fb ff ff       	call   f0100db8 <page_alloc>
f01011f2:	89 c6                	mov    %eax,%esi
f01011f4:	83 c4 10             	add    $0x10,%esp
f01011f7:	85 c0                	test   %eax,%eax
f01011f9:	75 19                	jne    f0101214 <mem_init+0x18b>
f01011fb:	68 db 56 10 f0       	push   $0xf01056db
f0101200:	68 1a 56 10 f0       	push   $0xf010561a
f0101205:	68 a8 02 00 00       	push   $0x2a8
f010120a:	68 e5 55 10 f0       	push   $0xf01055e5
f010120f:	e8 8c ee ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f0101214:	83 ec 0c             	sub    $0xc,%esp
f0101217:	6a 00                	push   $0x0
f0101219:	e8 9a fb ff ff       	call   f0100db8 <page_alloc>
f010121e:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101221:	83 c4 10             	add    $0x10,%esp
f0101224:	85 c0                	test   %eax,%eax
f0101226:	75 19                	jne    f0101241 <mem_init+0x1b8>
f0101228:	68 f1 56 10 f0       	push   $0xf01056f1
f010122d:	68 1a 56 10 f0       	push   $0xf010561a
f0101232:	68 a9 02 00 00       	push   $0x2a9
f0101237:	68 e5 55 10 f0       	push   $0xf01055e5
f010123c:	e8 5f ee ff ff       	call   f01000a0 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101241:	39 f7                	cmp    %esi,%edi
f0101243:	75 19                	jne    f010125e <mem_init+0x1d5>
f0101245:	68 07 57 10 f0       	push   $0xf0105707
f010124a:	68 1a 56 10 f0       	push   $0xf010561a
f010124f:	68 ac 02 00 00       	push   $0x2ac
f0101254:	68 e5 55 10 f0       	push   $0xf01055e5
f0101259:	e8 42 ee ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010125e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101261:	39 c6                	cmp    %eax,%esi
f0101263:	74 04                	je     f0101269 <mem_init+0x1e0>
f0101265:	39 c7                	cmp    %eax,%edi
f0101267:	75 19                	jne    f0101282 <mem_init+0x1f9>
f0101269:	68 90 4f 10 f0       	push   $0xf0104f90
f010126e:	68 1a 56 10 f0       	push   $0xf010561a
f0101273:	68 ad 02 00 00       	push   $0x2ad
f0101278:	68 e5 55 10 f0       	push   $0xf01055e5
f010127d:	e8 1e ee ff ff       	call   f01000a0 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101282:	8b 0d 4c 2c 17 f0    	mov    0xf0172c4c,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101288:	8b 15 44 2c 17 f0    	mov    0xf0172c44,%edx
f010128e:	c1 e2 0c             	shl    $0xc,%edx
f0101291:	89 f8                	mov    %edi,%eax
f0101293:	29 c8                	sub    %ecx,%eax
f0101295:	c1 f8 03             	sar    $0x3,%eax
f0101298:	c1 e0 0c             	shl    $0xc,%eax
f010129b:	39 d0                	cmp    %edx,%eax
f010129d:	72 19                	jb     f01012b8 <mem_init+0x22f>
f010129f:	68 19 57 10 f0       	push   $0xf0105719
f01012a4:	68 1a 56 10 f0       	push   $0xf010561a
f01012a9:	68 ae 02 00 00       	push   $0x2ae
f01012ae:	68 e5 55 10 f0       	push   $0xf01055e5
f01012b3:	e8 e8 ed ff ff       	call   f01000a0 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f01012b8:	89 f0                	mov    %esi,%eax
f01012ba:	29 c8                	sub    %ecx,%eax
f01012bc:	c1 f8 03             	sar    $0x3,%eax
f01012bf:	c1 e0 0c             	shl    $0xc,%eax
f01012c2:	39 c2                	cmp    %eax,%edx
f01012c4:	77 19                	ja     f01012df <mem_init+0x256>
f01012c6:	68 36 57 10 f0       	push   $0xf0105736
f01012cb:	68 1a 56 10 f0       	push   $0xf010561a
f01012d0:	68 af 02 00 00       	push   $0x2af
f01012d5:	68 e5 55 10 f0       	push   $0xf01055e5
f01012da:	e8 c1 ed ff ff       	call   f01000a0 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f01012df:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01012e2:	29 c8                	sub    %ecx,%eax
f01012e4:	c1 f8 03             	sar    $0x3,%eax
f01012e7:	c1 e0 0c             	shl    $0xc,%eax
f01012ea:	39 c2                	cmp    %eax,%edx
f01012ec:	77 19                	ja     f0101307 <mem_init+0x27e>
f01012ee:	68 53 57 10 f0       	push   $0xf0105753
f01012f3:	68 1a 56 10 f0       	push   $0xf010561a
f01012f8:	68 b0 02 00 00       	push   $0x2b0
f01012fd:	68 e5 55 10 f0       	push   $0xf01055e5
f0101302:	e8 99 ed ff ff       	call   f01000a0 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101307:	a1 80 1f 17 f0       	mov    0xf0171f80,%eax
f010130c:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f010130f:	c7 05 80 1f 17 f0 00 	movl   $0x0,0xf0171f80
f0101316:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101319:	83 ec 0c             	sub    $0xc,%esp
f010131c:	6a 00                	push   $0x0
f010131e:	e8 95 fa ff ff       	call   f0100db8 <page_alloc>
f0101323:	83 c4 10             	add    $0x10,%esp
f0101326:	85 c0                	test   %eax,%eax
f0101328:	74 19                	je     f0101343 <mem_init+0x2ba>
f010132a:	68 70 57 10 f0       	push   $0xf0105770
f010132f:	68 1a 56 10 f0       	push   $0xf010561a
f0101334:	68 b7 02 00 00       	push   $0x2b7
f0101339:	68 e5 55 10 f0       	push   $0xf01055e5
f010133e:	e8 5d ed ff ff       	call   f01000a0 <_panic>

	// free and re-allocate?
	page_free(pp0);
f0101343:	83 ec 0c             	sub    $0xc,%esp
f0101346:	57                   	push   %edi
f0101347:	e8 e3 fa ff ff       	call   f0100e2f <page_free>
	page_free(pp1);
f010134c:	89 34 24             	mov    %esi,(%esp)
f010134f:	e8 db fa ff ff       	call   f0100e2f <page_free>
	page_free(pp2);
f0101354:	83 c4 04             	add    $0x4,%esp
f0101357:	ff 75 d4             	pushl  -0x2c(%ebp)
f010135a:	e8 d0 fa ff ff       	call   f0100e2f <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010135f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101366:	e8 4d fa ff ff       	call   f0100db8 <page_alloc>
f010136b:	89 c6                	mov    %eax,%esi
f010136d:	83 c4 10             	add    $0x10,%esp
f0101370:	85 c0                	test   %eax,%eax
f0101372:	75 19                	jne    f010138d <mem_init+0x304>
f0101374:	68 c5 56 10 f0       	push   $0xf01056c5
f0101379:	68 1a 56 10 f0       	push   $0xf010561a
f010137e:	68 be 02 00 00       	push   $0x2be
f0101383:	68 e5 55 10 f0       	push   $0xf01055e5
f0101388:	e8 13 ed ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f010138d:	83 ec 0c             	sub    $0xc,%esp
f0101390:	6a 00                	push   $0x0
f0101392:	e8 21 fa ff ff       	call   f0100db8 <page_alloc>
f0101397:	89 c7                	mov    %eax,%edi
f0101399:	83 c4 10             	add    $0x10,%esp
f010139c:	85 c0                	test   %eax,%eax
f010139e:	75 19                	jne    f01013b9 <mem_init+0x330>
f01013a0:	68 db 56 10 f0       	push   $0xf01056db
f01013a5:	68 1a 56 10 f0       	push   $0xf010561a
f01013aa:	68 bf 02 00 00       	push   $0x2bf
f01013af:	68 e5 55 10 f0       	push   $0xf01055e5
f01013b4:	e8 e7 ec ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f01013b9:	83 ec 0c             	sub    $0xc,%esp
f01013bc:	6a 00                	push   $0x0
f01013be:	e8 f5 f9 ff ff       	call   f0100db8 <page_alloc>
f01013c3:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01013c6:	83 c4 10             	add    $0x10,%esp
f01013c9:	85 c0                	test   %eax,%eax
f01013cb:	75 19                	jne    f01013e6 <mem_init+0x35d>
f01013cd:	68 f1 56 10 f0       	push   $0xf01056f1
f01013d2:	68 1a 56 10 f0       	push   $0xf010561a
f01013d7:	68 c0 02 00 00       	push   $0x2c0
f01013dc:	68 e5 55 10 f0       	push   $0xf01055e5
f01013e1:	e8 ba ec ff ff       	call   f01000a0 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01013e6:	39 fe                	cmp    %edi,%esi
f01013e8:	75 19                	jne    f0101403 <mem_init+0x37a>
f01013ea:	68 07 57 10 f0       	push   $0xf0105707
f01013ef:	68 1a 56 10 f0       	push   $0xf010561a
f01013f4:	68 c2 02 00 00       	push   $0x2c2
f01013f9:	68 e5 55 10 f0       	push   $0xf01055e5
f01013fe:	e8 9d ec ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101403:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101406:	39 c7                	cmp    %eax,%edi
f0101408:	74 04                	je     f010140e <mem_init+0x385>
f010140a:	39 c6                	cmp    %eax,%esi
f010140c:	75 19                	jne    f0101427 <mem_init+0x39e>
f010140e:	68 90 4f 10 f0       	push   $0xf0104f90
f0101413:	68 1a 56 10 f0       	push   $0xf010561a
f0101418:	68 c3 02 00 00       	push   $0x2c3
f010141d:	68 e5 55 10 f0       	push   $0xf01055e5
f0101422:	e8 79 ec ff ff       	call   f01000a0 <_panic>
	assert(!page_alloc(0));
f0101427:	83 ec 0c             	sub    $0xc,%esp
f010142a:	6a 00                	push   $0x0
f010142c:	e8 87 f9 ff ff       	call   f0100db8 <page_alloc>
f0101431:	83 c4 10             	add    $0x10,%esp
f0101434:	85 c0                	test   %eax,%eax
f0101436:	74 19                	je     f0101451 <mem_init+0x3c8>
f0101438:	68 70 57 10 f0       	push   $0xf0105770
f010143d:	68 1a 56 10 f0       	push   $0xf010561a
f0101442:	68 c4 02 00 00       	push   $0x2c4
f0101447:	68 e5 55 10 f0       	push   $0xf01055e5
f010144c:	e8 4f ec ff ff       	call   f01000a0 <_panic>
f0101451:	89 f0                	mov    %esi,%eax
f0101453:	2b 05 4c 2c 17 f0    	sub    0xf0172c4c,%eax
f0101459:	c1 f8 03             	sar    $0x3,%eax
f010145c:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010145f:	89 c2                	mov    %eax,%edx
f0101461:	c1 ea 0c             	shr    $0xc,%edx
f0101464:	3b 15 44 2c 17 f0    	cmp    0xf0172c44,%edx
f010146a:	72 12                	jb     f010147e <mem_init+0x3f5>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010146c:	50                   	push   %eax
f010146d:	68 f4 4d 10 f0       	push   $0xf0104df4
f0101472:	6a 56                	push   $0x56
f0101474:	68 00 56 10 f0       	push   $0xf0105600
f0101479:	e8 22 ec ff ff       	call   f01000a0 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f010147e:	83 ec 04             	sub    $0x4,%esp
f0101481:	68 00 10 00 00       	push   $0x1000
f0101486:	6a 01                	push   $0x1
f0101488:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010148d:	50                   	push   %eax
f010148e:	e8 c6 2f 00 00       	call   f0104459 <memset>
	page_free(pp0);
f0101493:	89 34 24             	mov    %esi,(%esp)
f0101496:	e8 94 f9 ff ff       	call   f0100e2f <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f010149b:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01014a2:	e8 11 f9 ff ff       	call   f0100db8 <page_alloc>
f01014a7:	83 c4 10             	add    $0x10,%esp
f01014aa:	85 c0                	test   %eax,%eax
f01014ac:	75 19                	jne    f01014c7 <mem_init+0x43e>
f01014ae:	68 7f 57 10 f0       	push   $0xf010577f
f01014b3:	68 1a 56 10 f0       	push   $0xf010561a
f01014b8:	68 c9 02 00 00       	push   $0x2c9
f01014bd:	68 e5 55 10 f0       	push   $0xf01055e5
f01014c2:	e8 d9 eb ff ff       	call   f01000a0 <_panic>
	assert(pp && pp0 == pp);
f01014c7:	39 c6                	cmp    %eax,%esi
f01014c9:	74 19                	je     f01014e4 <mem_init+0x45b>
f01014cb:	68 9d 57 10 f0       	push   $0xf010579d
f01014d0:	68 1a 56 10 f0       	push   $0xf010561a
f01014d5:	68 ca 02 00 00       	push   $0x2ca
f01014da:	68 e5 55 10 f0       	push   $0xf01055e5
f01014df:	e8 bc eb ff ff       	call   f01000a0 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01014e4:	89 f0                	mov    %esi,%eax
f01014e6:	2b 05 4c 2c 17 f0    	sub    0xf0172c4c,%eax
f01014ec:	c1 f8 03             	sar    $0x3,%eax
f01014ef:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01014f2:	89 c2                	mov    %eax,%edx
f01014f4:	c1 ea 0c             	shr    $0xc,%edx
f01014f7:	3b 15 44 2c 17 f0    	cmp    0xf0172c44,%edx
f01014fd:	72 12                	jb     f0101511 <mem_init+0x488>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01014ff:	50                   	push   %eax
f0101500:	68 f4 4d 10 f0       	push   $0xf0104df4
f0101505:	6a 56                	push   $0x56
f0101507:	68 00 56 10 f0       	push   $0xf0105600
f010150c:	e8 8f eb ff ff       	call   f01000a0 <_panic>
f0101511:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f0101517:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f010151d:	80 38 00             	cmpb   $0x0,(%eax)
f0101520:	74 19                	je     f010153b <mem_init+0x4b2>
f0101522:	68 ad 57 10 f0       	push   $0xf01057ad
f0101527:	68 1a 56 10 f0       	push   $0xf010561a
f010152c:	68 cd 02 00 00       	push   $0x2cd
f0101531:	68 e5 55 10 f0       	push   $0xf01055e5
f0101536:	e8 65 eb ff ff       	call   f01000a0 <_panic>
f010153b:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f010153e:	39 d0                	cmp    %edx,%eax
f0101540:	75 db                	jne    f010151d <mem_init+0x494>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101542:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101545:	a3 80 1f 17 f0       	mov    %eax,0xf0171f80

	// free the pages we took
	page_free(pp0);
f010154a:	83 ec 0c             	sub    $0xc,%esp
f010154d:	56                   	push   %esi
f010154e:	e8 dc f8 ff ff       	call   f0100e2f <page_free>
	page_free(pp1);
f0101553:	89 3c 24             	mov    %edi,(%esp)
f0101556:	e8 d4 f8 ff ff       	call   f0100e2f <page_free>
	page_free(pp2);
f010155b:	83 c4 04             	add    $0x4,%esp
f010155e:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101561:	e8 c9 f8 ff ff       	call   f0100e2f <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101566:	a1 80 1f 17 f0       	mov    0xf0171f80,%eax
f010156b:	83 c4 10             	add    $0x10,%esp
f010156e:	eb 05                	jmp    f0101575 <mem_init+0x4ec>
		--nfree;
f0101570:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101573:	8b 00                	mov    (%eax),%eax
f0101575:	85 c0                	test   %eax,%eax
f0101577:	75 f7                	jne    f0101570 <mem_init+0x4e7>
		--nfree;
	assert(nfree == 0);
f0101579:	85 db                	test   %ebx,%ebx
f010157b:	74 19                	je     f0101596 <mem_init+0x50d>
f010157d:	68 b7 57 10 f0       	push   $0xf01057b7
f0101582:	68 1a 56 10 f0       	push   $0xf010561a
f0101587:	68 da 02 00 00       	push   $0x2da
f010158c:	68 e5 55 10 f0       	push   $0xf01055e5
f0101591:	e8 0a eb ff ff       	call   f01000a0 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f0101596:	83 ec 0c             	sub    $0xc,%esp
f0101599:	68 b0 4f 10 f0       	push   $0xf0104fb0
f010159e:	e8 5d 19 00 00       	call   f0102f00 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01015a3:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01015aa:	e8 09 f8 ff ff       	call   f0100db8 <page_alloc>
f01015af:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01015b2:	83 c4 10             	add    $0x10,%esp
f01015b5:	85 c0                	test   %eax,%eax
f01015b7:	75 19                	jne    f01015d2 <mem_init+0x549>
f01015b9:	68 c5 56 10 f0       	push   $0xf01056c5
f01015be:	68 1a 56 10 f0       	push   $0xf010561a
f01015c3:	68 38 03 00 00       	push   $0x338
f01015c8:	68 e5 55 10 f0       	push   $0xf01055e5
f01015cd:	e8 ce ea ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f01015d2:	83 ec 0c             	sub    $0xc,%esp
f01015d5:	6a 00                	push   $0x0
f01015d7:	e8 dc f7 ff ff       	call   f0100db8 <page_alloc>
f01015dc:	89 c3                	mov    %eax,%ebx
f01015de:	83 c4 10             	add    $0x10,%esp
f01015e1:	85 c0                	test   %eax,%eax
f01015e3:	75 19                	jne    f01015fe <mem_init+0x575>
f01015e5:	68 db 56 10 f0       	push   $0xf01056db
f01015ea:	68 1a 56 10 f0       	push   $0xf010561a
f01015ef:	68 39 03 00 00       	push   $0x339
f01015f4:	68 e5 55 10 f0       	push   $0xf01055e5
f01015f9:	e8 a2 ea ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f01015fe:	83 ec 0c             	sub    $0xc,%esp
f0101601:	6a 00                	push   $0x0
f0101603:	e8 b0 f7 ff ff       	call   f0100db8 <page_alloc>
f0101608:	89 c6                	mov    %eax,%esi
f010160a:	83 c4 10             	add    $0x10,%esp
f010160d:	85 c0                	test   %eax,%eax
f010160f:	75 19                	jne    f010162a <mem_init+0x5a1>
f0101611:	68 f1 56 10 f0       	push   $0xf01056f1
f0101616:	68 1a 56 10 f0       	push   $0xf010561a
f010161b:	68 3a 03 00 00       	push   $0x33a
f0101620:	68 e5 55 10 f0       	push   $0xf01055e5
f0101625:	e8 76 ea ff ff       	call   f01000a0 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010162a:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f010162d:	75 19                	jne    f0101648 <mem_init+0x5bf>
f010162f:	68 07 57 10 f0       	push   $0xf0105707
f0101634:	68 1a 56 10 f0       	push   $0xf010561a
f0101639:	68 3d 03 00 00       	push   $0x33d
f010163e:	68 e5 55 10 f0       	push   $0xf01055e5
f0101643:	e8 58 ea ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101648:	39 c3                	cmp    %eax,%ebx
f010164a:	74 05                	je     f0101651 <mem_init+0x5c8>
f010164c:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f010164f:	75 19                	jne    f010166a <mem_init+0x5e1>
f0101651:	68 90 4f 10 f0       	push   $0xf0104f90
f0101656:	68 1a 56 10 f0       	push   $0xf010561a
f010165b:	68 3e 03 00 00       	push   $0x33e
f0101660:	68 e5 55 10 f0       	push   $0xf01055e5
f0101665:	e8 36 ea ff ff       	call   f01000a0 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f010166a:	a1 80 1f 17 f0       	mov    0xf0171f80,%eax
f010166f:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101672:	c7 05 80 1f 17 f0 00 	movl   $0x0,0xf0171f80
f0101679:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f010167c:	83 ec 0c             	sub    $0xc,%esp
f010167f:	6a 00                	push   $0x0
f0101681:	e8 32 f7 ff ff       	call   f0100db8 <page_alloc>
f0101686:	83 c4 10             	add    $0x10,%esp
f0101689:	85 c0                	test   %eax,%eax
f010168b:	74 19                	je     f01016a6 <mem_init+0x61d>
f010168d:	68 70 57 10 f0       	push   $0xf0105770
f0101692:	68 1a 56 10 f0       	push   $0xf010561a
f0101697:	68 45 03 00 00       	push   $0x345
f010169c:	68 e5 55 10 f0       	push   $0xf01055e5
f01016a1:	e8 fa e9 ff ff       	call   f01000a0 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f01016a6:	83 ec 04             	sub    $0x4,%esp
f01016a9:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01016ac:	50                   	push   %eax
f01016ad:	6a 00                	push   $0x0
f01016af:	ff 35 48 2c 17 f0    	pushl  0xf0172c48
f01016b5:	e8 ce f8 ff ff       	call   f0100f88 <page_lookup>
f01016ba:	83 c4 10             	add    $0x10,%esp
f01016bd:	85 c0                	test   %eax,%eax
f01016bf:	74 19                	je     f01016da <mem_init+0x651>
f01016c1:	68 d0 4f 10 f0       	push   $0xf0104fd0
f01016c6:	68 1a 56 10 f0       	push   $0xf010561a
f01016cb:	68 48 03 00 00       	push   $0x348
f01016d0:	68 e5 55 10 f0       	push   $0xf01055e5
f01016d5:	e8 c6 e9 ff ff       	call   f01000a0 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f01016da:	6a 02                	push   $0x2
f01016dc:	6a 00                	push   $0x0
f01016de:	53                   	push   %ebx
f01016df:	ff 35 48 2c 17 f0    	pushl  0xf0172c48
f01016e5:	e8 33 f9 ff ff       	call   f010101d <page_insert>
f01016ea:	83 c4 10             	add    $0x10,%esp
f01016ed:	85 c0                	test   %eax,%eax
f01016ef:	78 19                	js     f010170a <mem_init+0x681>
f01016f1:	68 08 50 10 f0       	push   $0xf0105008
f01016f6:	68 1a 56 10 f0       	push   $0xf010561a
f01016fb:	68 4b 03 00 00       	push   $0x34b
f0101700:	68 e5 55 10 f0       	push   $0xf01055e5
f0101705:	e8 96 e9 ff ff       	call   f01000a0 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f010170a:	83 ec 0c             	sub    $0xc,%esp
f010170d:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101710:	e8 1a f7 ff ff       	call   f0100e2f <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101715:	6a 02                	push   $0x2
f0101717:	6a 00                	push   $0x0
f0101719:	53                   	push   %ebx
f010171a:	ff 35 48 2c 17 f0    	pushl  0xf0172c48
f0101720:	e8 f8 f8 ff ff       	call   f010101d <page_insert>
f0101725:	83 c4 20             	add    $0x20,%esp
f0101728:	85 c0                	test   %eax,%eax
f010172a:	74 19                	je     f0101745 <mem_init+0x6bc>
f010172c:	68 38 50 10 f0       	push   $0xf0105038
f0101731:	68 1a 56 10 f0       	push   $0xf010561a
f0101736:	68 4f 03 00 00       	push   $0x34f
f010173b:	68 e5 55 10 f0       	push   $0xf01055e5
f0101740:	e8 5b e9 ff ff       	call   f01000a0 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101745:	8b 3d 48 2c 17 f0    	mov    0xf0172c48,%edi
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010174b:	a1 4c 2c 17 f0       	mov    0xf0172c4c,%eax
f0101750:	89 c1                	mov    %eax,%ecx
f0101752:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101755:	8b 17                	mov    (%edi),%edx
f0101757:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010175d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101760:	29 c8                	sub    %ecx,%eax
f0101762:	c1 f8 03             	sar    $0x3,%eax
f0101765:	c1 e0 0c             	shl    $0xc,%eax
f0101768:	39 c2                	cmp    %eax,%edx
f010176a:	74 19                	je     f0101785 <mem_init+0x6fc>
f010176c:	68 68 50 10 f0       	push   $0xf0105068
f0101771:	68 1a 56 10 f0       	push   $0xf010561a
f0101776:	68 50 03 00 00       	push   $0x350
f010177b:	68 e5 55 10 f0       	push   $0xf01055e5
f0101780:	e8 1b e9 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101785:	ba 00 00 00 00       	mov    $0x0,%edx
f010178a:	89 f8                	mov    %edi,%eax
f010178c:	e8 95 f1 ff ff       	call   f0100926 <check_va2pa>
f0101791:	89 da                	mov    %ebx,%edx
f0101793:	2b 55 cc             	sub    -0x34(%ebp),%edx
f0101796:	c1 fa 03             	sar    $0x3,%edx
f0101799:	c1 e2 0c             	shl    $0xc,%edx
f010179c:	39 d0                	cmp    %edx,%eax
f010179e:	74 19                	je     f01017b9 <mem_init+0x730>
f01017a0:	68 90 50 10 f0       	push   $0xf0105090
f01017a5:	68 1a 56 10 f0       	push   $0xf010561a
f01017aa:	68 51 03 00 00       	push   $0x351
f01017af:	68 e5 55 10 f0       	push   $0xf01055e5
f01017b4:	e8 e7 e8 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 1);
f01017b9:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01017be:	74 19                	je     f01017d9 <mem_init+0x750>
f01017c0:	68 c2 57 10 f0       	push   $0xf01057c2
f01017c5:	68 1a 56 10 f0       	push   $0xf010561a
f01017ca:	68 52 03 00 00       	push   $0x352
f01017cf:	68 e5 55 10 f0       	push   $0xf01055e5
f01017d4:	e8 c7 e8 ff ff       	call   f01000a0 <_panic>
	assert(pp0->pp_ref == 1);
f01017d9:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01017dc:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f01017e1:	74 19                	je     f01017fc <mem_init+0x773>
f01017e3:	68 d3 57 10 f0       	push   $0xf01057d3
f01017e8:	68 1a 56 10 f0       	push   $0xf010561a
f01017ed:	68 53 03 00 00       	push   $0x353
f01017f2:	68 e5 55 10 f0       	push   $0xf01055e5
f01017f7:	e8 a4 e8 ff ff       	call   f01000a0 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01017fc:	6a 02                	push   $0x2
f01017fe:	68 00 10 00 00       	push   $0x1000
f0101803:	56                   	push   %esi
f0101804:	57                   	push   %edi
f0101805:	e8 13 f8 ff ff       	call   f010101d <page_insert>
f010180a:	83 c4 10             	add    $0x10,%esp
f010180d:	85 c0                	test   %eax,%eax
f010180f:	74 19                	je     f010182a <mem_init+0x7a1>
f0101811:	68 c0 50 10 f0       	push   $0xf01050c0
f0101816:	68 1a 56 10 f0       	push   $0xf010561a
f010181b:	68 56 03 00 00       	push   $0x356
f0101820:	68 e5 55 10 f0       	push   $0xf01055e5
f0101825:	e8 76 e8 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f010182a:	ba 00 10 00 00       	mov    $0x1000,%edx
f010182f:	a1 48 2c 17 f0       	mov    0xf0172c48,%eax
f0101834:	e8 ed f0 ff ff       	call   f0100926 <check_va2pa>
f0101839:	89 f2                	mov    %esi,%edx
f010183b:	2b 15 4c 2c 17 f0    	sub    0xf0172c4c,%edx
f0101841:	c1 fa 03             	sar    $0x3,%edx
f0101844:	c1 e2 0c             	shl    $0xc,%edx
f0101847:	39 d0                	cmp    %edx,%eax
f0101849:	74 19                	je     f0101864 <mem_init+0x7db>
f010184b:	68 fc 50 10 f0       	push   $0xf01050fc
f0101850:	68 1a 56 10 f0       	push   $0xf010561a
f0101855:	68 57 03 00 00       	push   $0x357
f010185a:	68 e5 55 10 f0       	push   $0xf01055e5
f010185f:	e8 3c e8 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f0101864:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101869:	74 19                	je     f0101884 <mem_init+0x7fb>
f010186b:	68 e4 57 10 f0       	push   $0xf01057e4
f0101870:	68 1a 56 10 f0       	push   $0xf010561a
f0101875:	68 58 03 00 00       	push   $0x358
f010187a:	68 e5 55 10 f0       	push   $0xf01055e5
f010187f:	e8 1c e8 ff ff       	call   f01000a0 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101884:	83 ec 0c             	sub    $0xc,%esp
f0101887:	6a 00                	push   $0x0
f0101889:	e8 2a f5 ff ff       	call   f0100db8 <page_alloc>
f010188e:	83 c4 10             	add    $0x10,%esp
f0101891:	85 c0                	test   %eax,%eax
f0101893:	74 19                	je     f01018ae <mem_init+0x825>
f0101895:	68 70 57 10 f0       	push   $0xf0105770
f010189a:	68 1a 56 10 f0       	push   $0xf010561a
f010189f:	68 5b 03 00 00       	push   $0x35b
f01018a4:	68 e5 55 10 f0       	push   $0xf01055e5
f01018a9:	e8 f2 e7 ff ff       	call   f01000a0 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01018ae:	6a 02                	push   $0x2
f01018b0:	68 00 10 00 00       	push   $0x1000
f01018b5:	56                   	push   %esi
f01018b6:	ff 35 48 2c 17 f0    	pushl  0xf0172c48
f01018bc:	e8 5c f7 ff ff       	call   f010101d <page_insert>
f01018c1:	83 c4 10             	add    $0x10,%esp
f01018c4:	85 c0                	test   %eax,%eax
f01018c6:	74 19                	je     f01018e1 <mem_init+0x858>
f01018c8:	68 c0 50 10 f0       	push   $0xf01050c0
f01018cd:	68 1a 56 10 f0       	push   $0xf010561a
f01018d2:	68 5e 03 00 00       	push   $0x35e
f01018d7:	68 e5 55 10 f0       	push   $0xf01055e5
f01018dc:	e8 bf e7 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01018e1:	ba 00 10 00 00       	mov    $0x1000,%edx
f01018e6:	a1 48 2c 17 f0       	mov    0xf0172c48,%eax
f01018eb:	e8 36 f0 ff ff       	call   f0100926 <check_va2pa>
f01018f0:	89 f2                	mov    %esi,%edx
f01018f2:	2b 15 4c 2c 17 f0    	sub    0xf0172c4c,%edx
f01018f8:	c1 fa 03             	sar    $0x3,%edx
f01018fb:	c1 e2 0c             	shl    $0xc,%edx
f01018fe:	39 d0                	cmp    %edx,%eax
f0101900:	74 19                	je     f010191b <mem_init+0x892>
f0101902:	68 fc 50 10 f0       	push   $0xf01050fc
f0101907:	68 1a 56 10 f0       	push   $0xf010561a
f010190c:	68 5f 03 00 00       	push   $0x35f
f0101911:	68 e5 55 10 f0       	push   $0xf01055e5
f0101916:	e8 85 e7 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f010191b:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101920:	74 19                	je     f010193b <mem_init+0x8b2>
f0101922:	68 e4 57 10 f0       	push   $0xf01057e4
f0101927:	68 1a 56 10 f0       	push   $0xf010561a
f010192c:	68 60 03 00 00       	push   $0x360
f0101931:	68 e5 55 10 f0       	push   $0xf01055e5
f0101936:	e8 65 e7 ff ff       	call   f01000a0 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f010193b:	83 ec 0c             	sub    $0xc,%esp
f010193e:	6a 00                	push   $0x0
f0101940:	e8 73 f4 ff ff       	call   f0100db8 <page_alloc>
f0101945:	83 c4 10             	add    $0x10,%esp
f0101948:	85 c0                	test   %eax,%eax
f010194a:	74 19                	je     f0101965 <mem_init+0x8dc>
f010194c:	68 70 57 10 f0       	push   $0xf0105770
f0101951:	68 1a 56 10 f0       	push   $0xf010561a
f0101956:	68 64 03 00 00       	push   $0x364
f010195b:	68 e5 55 10 f0       	push   $0xf01055e5
f0101960:	e8 3b e7 ff ff       	call   f01000a0 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101965:	8b 15 48 2c 17 f0    	mov    0xf0172c48,%edx
f010196b:	8b 02                	mov    (%edx),%eax
f010196d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101972:	89 c1                	mov    %eax,%ecx
f0101974:	c1 e9 0c             	shr    $0xc,%ecx
f0101977:	3b 0d 44 2c 17 f0    	cmp    0xf0172c44,%ecx
f010197d:	72 15                	jb     f0101994 <mem_init+0x90b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010197f:	50                   	push   %eax
f0101980:	68 f4 4d 10 f0       	push   $0xf0104df4
f0101985:	68 67 03 00 00       	push   $0x367
f010198a:	68 e5 55 10 f0       	push   $0xf01055e5
f010198f:	e8 0c e7 ff ff       	call   f01000a0 <_panic>
f0101994:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101999:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f010199c:	83 ec 04             	sub    $0x4,%esp
f010199f:	6a 00                	push   $0x0
f01019a1:	68 00 10 00 00       	push   $0x1000
f01019a6:	52                   	push   %edx
f01019a7:	e8 e5 f4 ff ff       	call   f0100e91 <pgdir_walk>
f01019ac:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01019af:	8d 57 04             	lea    0x4(%edi),%edx
f01019b2:	83 c4 10             	add    $0x10,%esp
f01019b5:	39 d0                	cmp    %edx,%eax
f01019b7:	74 19                	je     f01019d2 <mem_init+0x949>
f01019b9:	68 2c 51 10 f0       	push   $0xf010512c
f01019be:	68 1a 56 10 f0       	push   $0xf010561a
f01019c3:	68 68 03 00 00       	push   $0x368
f01019c8:	68 e5 55 10 f0       	push   $0xf01055e5
f01019cd:	e8 ce e6 ff ff       	call   f01000a0 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f01019d2:	6a 06                	push   $0x6
f01019d4:	68 00 10 00 00       	push   $0x1000
f01019d9:	56                   	push   %esi
f01019da:	ff 35 48 2c 17 f0    	pushl  0xf0172c48
f01019e0:	e8 38 f6 ff ff       	call   f010101d <page_insert>
f01019e5:	83 c4 10             	add    $0x10,%esp
f01019e8:	85 c0                	test   %eax,%eax
f01019ea:	74 19                	je     f0101a05 <mem_init+0x97c>
f01019ec:	68 6c 51 10 f0       	push   $0xf010516c
f01019f1:	68 1a 56 10 f0       	push   $0xf010561a
f01019f6:	68 6b 03 00 00       	push   $0x36b
f01019fb:	68 e5 55 10 f0       	push   $0xf01055e5
f0101a00:	e8 9b e6 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101a05:	8b 3d 48 2c 17 f0    	mov    0xf0172c48,%edi
f0101a0b:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101a10:	89 f8                	mov    %edi,%eax
f0101a12:	e8 0f ef ff ff       	call   f0100926 <check_va2pa>
f0101a17:	89 f2                	mov    %esi,%edx
f0101a19:	2b 15 4c 2c 17 f0    	sub    0xf0172c4c,%edx
f0101a1f:	c1 fa 03             	sar    $0x3,%edx
f0101a22:	c1 e2 0c             	shl    $0xc,%edx
f0101a25:	39 d0                	cmp    %edx,%eax
f0101a27:	74 19                	je     f0101a42 <mem_init+0x9b9>
f0101a29:	68 fc 50 10 f0       	push   $0xf01050fc
f0101a2e:	68 1a 56 10 f0       	push   $0xf010561a
f0101a33:	68 6c 03 00 00       	push   $0x36c
f0101a38:	68 e5 55 10 f0       	push   $0xf01055e5
f0101a3d:	e8 5e e6 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f0101a42:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101a47:	74 19                	je     f0101a62 <mem_init+0x9d9>
f0101a49:	68 e4 57 10 f0       	push   $0xf01057e4
f0101a4e:	68 1a 56 10 f0       	push   $0xf010561a
f0101a53:	68 6d 03 00 00       	push   $0x36d
f0101a58:	68 e5 55 10 f0       	push   $0xf01055e5
f0101a5d:	e8 3e e6 ff ff       	call   f01000a0 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101a62:	83 ec 04             	sub    $0x4,%esp
f0101a65:	6a 00                	push   $0x0
f0101a67:	68 00 10 00 00       	push   $0x1000
f0101a6c:	57                   	push   %edi
f0101a6d:	e8 1f f4 ff ff       	call   f0100e91 <pgdir_walk>
f0101a72:	83 c4 10             	add    $0x10,%esp
f0101a75:	f6 00 04             	testb  $0x4,(%eax)
f0101a78:	75 19                	jne    f0101a93 <mem_init+0xa0a>
f0101a7a:	68 ac 51 10 f0       	push   $0xf01051ac
f0101a7f:	68 1a 56 10 f0       	push   $0xf010561a
f0101a84:	68 6e 03 00 00       	push   $0x36e
f0101a89:	68 e5 55 10 f0       	push   $0xf01055e5
f0101a8e:	e8 0d e6 ff ff       	call   f01000a0 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101a93:	a1 48 2c 17 f0       	mov    0xf0172c48,%eax
f0101a98:	f6 00 04             	testb  $0x4,(%eax)
f0101a9b:	75 19                	jne    f0101ab6 <mem_init+0xa2d>
f0101a9d:	68 f5 57 10 f0       	push   $0xf01057f5
f0101aa2:	68 1a 56 10 f0       	push   $0xf010561a
f0101aa7:	68 6f 03 00 00       	push   $0x36f
f0101aac:	68 e5 55 10 f0       	push   $0xf01055e5
f0101ab1:	e8 ea e5 ff ff       	call   f01000a0 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101ab6:	6a 02                	push   $0x2
f0101ab8:	68 00 10 00 00       	push   $0x1000
f0101abd:	56                   	push   %esi
f0101abe:	50                   	push   %eax
f0101abf:	e8 59 f5 ff ff       	call   f010101d <page_insert>
f0101ac4:	83 c4 10             	add    $0x10,%esp
f0101ac7:	85 c0                	test   %eax,%eax
f0101ac9:	74 19                	je     f0101ae4 <mem_init+0xa5b>
f0101acb:	68 c0 50 10 f0       	push   $0xf01050c0
f0101ad0:	68 1a 56 10 f0       	push   $0xf010561a
f0101ad5:	68 72 03 00 00       	push   $0x372
f0101ada:	68 e5 55 10 f0       	push   $0xf01055e5
f0101adf:	e8 bc e5 ff ff       	call   f01000a0 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101ae4:	83 ec 04             	sub    $0x4,%esp
f0101ae7:	6a 00                	push   $0x0
f0101ae9:	68 00 10 00 00       	push   $0x1000
f0101aee:	ff 35 48 2c 17 f0    	pushl  0xf0172c48
f0101af4:	e8 98 f3 ff ff       	call   f0100e91 <pgdir_walk>
f0101af9:	83 c4 10             	add    $0x10,%esp
f0101afc:	f6 00 02             	testb  $0x2,(%eax)
f0101aff:	75 19                	jne    f0101b1a <mem_init+0xa91>
f0101b01:	68 e0 51 10 f0       	push   $0xf01051e0
f0101b06:	68 1a 56 10 f0       	push   $0xf010561a
f0101b0b:	68 73 03 00 00       	push   $0x373
f0101b10:	68 e5 55 10 f0       	push   $0xf01055e5
f0101b15:	e8 86 e5 ff ff       	call   f01000a0 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101b1a:	83 ec 04             	sub    $0x4,%esp
f0101b1d:	6a 00                	push   $0x0
f0101b1f:	68 00 10 00 00       	push   $0x1000
f0101b24:	ff 35 48 2c 17 f0    	pushl  0xf0172c48
f0101b2a:	e8 62 f3 ff ff       	call   f0100e91 <pgdir_walk>
f0101b2f:	83 c4 10             	add    $0x10,%esp
f0101b32:	f6 00 04             	testb  $0x4,(%eax)
f0101b35:	74 19                	je     f0101b50 <mem_init+0xac7>
f0101b37:	68 14 52 10 f0       	push   $0xf0105214
f0101b3c:	68 1a 56 10 f0       	push   $0xf010561a
f0101b41:	68 74 03 00 00       	push   $0x374
f0101b46:	68 e5 55 10 f0       	push   $0xf01055e5
f0101b4b:	e8 50 e5 ff ff       	call   f01000a0 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101b50:	6a 02                	push   $0x2
f0101b52:	68 00 00 40 00       	push   $0x400000
f0101b57:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101b5a:	ff 35 48 2c 17 f0    	pushl  0xf0172c48
f0101b60:	e8 b8 f4 ff ff       	call   f010101d <page_insert>
f0101b65:	83 c4 10             	add    $0x10,%esp
f0101b68:	85 c0                	test   %eax,%eax
f0101b6a:	78 19                	js     f0101b85 <mem_init+0xafc>
f0101b6c:	68 4c 52 10 f0       	push   $0xf010524c
f0101b71:	68 1a 56 10 f0       	push   $0xf010561a
f0101b76:	68 77 03 00 00       	push   $0x377
f0101b7b:	68 e5 55 10 f0       	push   $0xf01055e5
f0101b80:	e8 1b e5 ff ff       	call   f01000a0 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101b85:	6a 02                	push   $0x2
f0101b87:	68 00 10 00 00       	push   $0x1000
f0101b8c:	53                   	push   %ebx
f0101b8d:	ff 35 48 2c 17 f0    	pushl  0xf0172c48
f0101b93:	e8 85 f4 ff ff       	call   f010101d <page_insert>
f0101b98:	83 c4 10             	add    $0x10,%esp
f0101b9b:	85 c0                	test   %eax,%eax
f0101b9d:	74 19                	je     f0101bb8 <mem_init+0xb2f>
f0101b9f:	68 84 52 10 f0       	push   $0xf0105284
f0101ba4:	68 1a 56 10 f0       	push   $0xf010561a
f0101ba9:	68 7a 03 00 00       	push   $0x37a
f0101bae:	68 e5 55 10 f0       	push   $0xf01055e5
f0101bb3:	e8 e8 e4 ff ff       	call   f01000a0 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101bb8:	83 ec 04             	sub    $0x4,%esp
f0101bbb:	6a 00                	push   $0x0
f0101bbd:	68 00 10 00 00       	push   $0x1000
f0101bc2:	ff 35 48 2c 17 f0    	pushl  0xf0172c48
f0101bc8:	e8 c4 f2 ff ff       	call   f0100e91 <pgdir_walk>
f0101bcd:	83 c4 10             	add    $0x10,%esp
f0101bd0:	f6 00 04             	testb  $0x4,(%eax)
f0101bd3:	74 19                	je     f0101bee <mem_init+0xb65>
f0101bd5:	68 14 52 10 f0       	push   $0xf0105214
f0101bda:	68 1a 56 10 f0       	push   $0xf010561a
f0101bdf:	68 7b 03 00 00       	push   $0x37b
f0101be4:	68 e5 55 10 f0       	push   $0xf01055e5
f0101be9:	e8 b2 e4 ff ff       	call   f01000a0 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101bee:	8b 3d 48 2c 17 f0    	mov    0xf0172c48,%edi
f0101bf4:	ba 00 00 00 00       	mov    $0x0,%edx
f0101bf9:	89 f8                	mov    %edi,%eax
f0101bfb:	e8 26 ed ff ff       	call   f0100926 <check_va2pa>
f0101c00:	89 c1                	mov    %eax,%ecx
f0101c02:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101c05:	89 d8                	mov    %ebx,%eax
f0101c07:	2b 05 4c 2c 17 f0    	sub    0xf0172c4c,%eax
f0101c0d:	c1 f8 03             	sar    $0x3,%eax
f0101c10:	c1 e0 0c             	shl    $0xc,%eax
f0101c13:	39 c1                	cmp    %eax,%ecx
f0101c15:	74 19                	je     f0101c30 <mem_init+0xba7>
f0101c17:	68 c0 52 10 f0       	push   $0xf01052c0
f0101c1c:	68 1a 56 10 f0       	push   $0xf010561a
f0101c21:	68 7e 03 00 00       	push   $0x37e
f0101c26:	68 e5 55 10 f0       	push   $0xf01055e5
f0101c2b:	e8 70 e4 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101c30:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c35:	89 f8                	mov    %edi,%eax
f0101c37:	e8 ea ec ff ff       	call   f0100926 <check_va2pa>
f0101c3c:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101c3f:	74 19                	je     f0101c5a <mem_init+0xbd1>
f0101c41:	68 ec 52 10 f0       	push   $0xf01052ec
f0101c46:	68 1a 56 10 f0       	push   $0xf010561a
f0101c4b:	68 7f 03 00 00       	push   $0x37f
f0101c50:	68 e5 55 10 f0       	push   $0xf01055e5
f0101c55:	e8 46 e4 ff ff       	call   f01000a0 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101c5a:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101c5f:	74 19                	je     f0101c7a <mem_init+0xbf1>
f0101c61:	68 0b 58 10 f0       	push   $0xf010580b
f0101c66:	68 1a 56 10 f0       	push   $0xf010561a
f0101c6b:	68 81 03 00 00       	push   $0x381
f0101c70:	68 e5 55 10 f0       	push   $0xf01055e5
f0101c75:	e8 26 e4 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101c7a:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101c7f:	74 19                	je     f0101c9a <mem_init+0xc11>
f0101c81:	68 1c 58 10 f0       	push   $0xf010581c
f0101c86:	68 1a 56 10 f0       	push   $0xf010561a
f0101c8b:	68 82 03 00 00       	push   $0x382
f0101c90:	68 e5 55 10 f0       	push   $0xf01055e5
f0101c95:	e8 06 e4 ff ff       	call   f01000a0 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101c9a:	83 ec 0c             	sub    $0xc,%esp
f0101c9d:	6a 00                	push   $0x0
f0101c9f:	e8 14 f1 ff ff       	call   f0100db8 <page_alloc>
f0101ca4:	83 c4 10             	add    $0x10,%esp
f0101ca7:	39 c6                	cmp    %eax,%esi
f0101ca9:	75 04                	jne    f0101caf <mem_init+0xc26>
f0101cab:	85 c0                	test   %eax,%eax
f0101cad:	75 19                	jne    f0101cc8 <mem_init+0xc3f>
f0101caf:	68 1c 53 10 f0       	push   $0xf010531c
f0101cb4:	68 1a 56 10 f0       	push   $0xf010561a
f0101cb9:	68 85 03 00 00       	push   $0x385
f0101cbe:	68 e5 55 10 f0       	push   $0xf01055e5
f0101cc3:	e8 d8 e3 ff ff       	call   f01000a0 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101cc8:	83 ec 08             	sub    $0x8,%esp
f0101ccb:	6a 00                	push   $0x0
f0101ccd:	ff 35 48 2c 17 f0    	pushl  0xf0172c48
f0101cd3:	e8 0a f3 ff ff       	call   f0100fe2 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101cd8:	8b 3d 48 2c 17 f0    	mov    0xf0172c48,%edi
f0101cde:	ba 00 00 00 00       	mov    $0x0,%edx
f0101ce3:	89 f8                	mov    %edi,%eax
f0101ce5:	e8 3c ec ff ff       	call   f0100926 <check_va2pa>
f0101cea:	83 c4 10             	add    $0x10,%esp
f0101ced:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101cf0:	74 19                	je     f0101d0b <mem_init+0xc82>
f0101cf2:	68 40 53 10 f0       	push   $0xf0105340
f0101cf7:	68 1a 56 10 f0       	push   $0xf010561a
f0101cfc:	68 89 03 00 00       	push   $0x389
f0101d01:	68 e5 55 10 f0       	push   $0xf01055e5
f0101d06:	e8 95 e3 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101d0b:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101d10:	89 f8                	mov    %edi,%eax
f0101d12:	e8 0f ec ff ff       	call   f0100926 <check_va2pa>
f0101d17:	89 da                	mov    %ebx,%edx
f0101d19:	2b 15 4c 2c 17 f0    	sub    0xf0172c4c,%edx
f0101d1f:	c1 fa 03             	sar    $0x3,%edx
f0101d22:	c1 e2 0c             	shl    $0xc,%edx
f0101d25:	39 d0                	cmp    %edx,%eax
f0101d27:	74 19                	je     f0101d42 <mem_init+0xcb9>
f0101d29:	68 ec 52 10 f0       	push   $0xf01052ec
f0101d2e:	68 1a 56 10 f0       	push   $0xf010561a
f0101d33:	68 8a 03 00 00       	push   $0x38a
f0101d38:	68 e5 55 10 f0       	push   $0xf01055e5
f0101d3d:	e8 5e e3 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 1);
f0101d42:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101d47:	74 19                	je     f0101d62 <mem_init+0xcd9>
f0101d49:	68 c2 57 10 f0       	push   $0xf01057c2
f0101d4e:	68 1a 56 10 f0       	push   $0xf010561a
f0101d53:	68 8b 03 00 00       	push   $0x38b
f0101d58:	68 e5 55 10 f0       	push   $0xf01055e5
f0101d5d:	e8 3e e3 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101d62:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101d67:	74 19                	je     f0101d82 <mem_init+0xcf9>
f0101d69:	68 1c 58 10 f0       	push   $0xf010581c
f0101d6e:	68 1a 56 10 f0       	push   $0xf010561a
f0101d73:	68 8c 03 00 00       	push   $0x38c
f0101d78:	68 e5 55 10 f0       	push   $0xf01055e5
f0101d7d:	e8 1e e3 ff ff       	call   f01000a0 <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101d82:	6a 00                	push   $0x0
f0101d84:	68 00 10 00 00       	push   $0x1000
f0101d89:	53                   	push   %ebx
f0101d8a:	57                   	push   %edi
f0101d8b:	e8 8d f2 ff ff       	call   f010101d <page_insert>
f0101d90:	83 c4 10             	add    $0x10,%esp
f0101d93:	85 c0                	test   %eax,%eax
f0101d95:	74 19                	je     f0101db0 <mem_init+0xd27>
f0101d97:	68 64 53 10 f0       	push   $0xf0105364
f0101d9c:	68 1a 56 10 f0       	push   $0xf010561a
f0101da1:	68 8f 03 00 00       	push   $0x38f
f0101da6:	68 e5 55 10 f0       	push   $0xf01055e5
f0101dab:	e8 f0 e2 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref);
f0101db0:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101db5:	75 19                	jne    f0101dd0 <mem_init+0xd47>
f0101db7:	68 2d 58 10 f0       	push   $0xf010582d
f0101dbc:	68 1a 56 10 f0       	push   $0xf010561a
f0101dc1:	68 90 03 00 00       	push   $0x390
f0101dc6:	68 e5 55 10 f0       	push   $0xf01055e5
f0101dcb:	e8 d0 e2 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_link == NULL);
f0101dd0:	83 3b 00             	cmpl   $0x0,(%ebx)
f0101dd3:	74 19                	je     f0101dee <mem_init+0xd65>
f0101dd5:	68 39 58 10 f0       	push   $0xf0105839
f0101dda:	68 1a 56 10 f0       	push   $0xf010561a
f0101ddf:	68 91 03 00 00       	push   $0x391
f0101de4:	68 e5 55 10 f0       	push   $0xf01055e5
f0101de9:	e8 b2 e2 ff ff       	call   f01000a0 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101dee:	83 ec 08             	sub    $0x8,%esp
f0101df1:	68 00 10 00 00       	push   $0x1000
f0101df6:	ff 35 48 2c 17 f0    	pushl  0xf0172c48
f0101dfc:	e8 e1 f1 ff ff       	call   f0100fe2 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101e01:	8b 3d 48 2c 17 f0    	mov    0xf0172c48,%edi
f0101e07:	ba 00 00 00 00       	mov    $0x0,%edx
f0101e0c:	89 f8                	mov    %edi,%eax
f0101e0e:	e8 13 eb ff ff       	call   f0100926 <check_va2pa>
f0101e13:	83 c4 10             	add    $0x10,%esp
f0101e16:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e19:	74 19                	je     f0101e34 <mem_init+0xdab>
f0101e1b:	68 40 53 10 f0       	push   $0xf0105340
f0101e20:	68 1a 56 10 f0       	push   $0xf010561a
f0101e25:	68 95 03 00 00       	push   $0x395
f0101e2a:	68 e5 55 10 f0       	push   $0xf01055e5
f0101e2f:	e8 6c e2 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101e34:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e39:	89 f8                	mov    %edi,%eax
f0101e3b:	e8 e6 ea ff ff       	call   f0100926 <check_va2pa>
f0101e40:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e43:	74 19                	je     f0101e5e <mem_init+0xdd5>
f0101e45:	68 9c 53 10 f0       	push   $0xf010539c
f0101e4a:	68 1a 56 10 f0       	push   $0xf010561a
f0101e4f:	68 96 03 00 00       	push   $0x396
f0101e54:	68 e5 55 10 f0       	push   $0xf01055e5
f0101e59:	e8 42 e2 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 0);
f0101e5e:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101e63:	74 19                	je     f0101e7e <mem_init+0xdf5>
f0101e65:	68 4e 58 10 f0       	push   $0xf010584e
f0101e6a:	68 1a 56 10 f0       	push   $0xf010561a
f0101e6f:	68 97 03 00 00       	push   $0x397
f0101e74:	68 e5 55 10 f0       	push   $0xf01055e5
f0101e79:	e8 22 e2 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101e7e:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101e83:	74 19                	je     f0101e9e <mem_init+0xe15>
f0101e85:	68 1c 58 10 f0       	push   $0xf010581c
f0101e8a:	68 1a 56 10 f0       	push   $0xf010561a
f0101e8f:	68 98 03 00 00       	push   $0x398
f0101e94:	68 e5 55 10 f0       	push   $0xf01055e5
f0101e99:	e8 02 e2 ff ff       	call   f01000a0 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101e9e:	83 ec 0c             	sub    $0xc,%esp
f0101ea1:	6a 00                	push   $0x0
f0101ea3:	e8 10 ef ff ff       	call   f0100db8 <page_alloc>
f0101ea8:	83 c4 10             	add    $0x10,%esp
f0101eab:	85 c0                	test   %eax,%eax
f0101ead:	74 04                	je     f0101eb3 <mem_init+0xe2a>
f0101eaf:	39 c3                	cmp    %eax,%ebx
f0101eb1:	74 19                	je     f0101ecc <mem_init+0xe43>
f0101eb3:	68 c4 53 10 f0       	push   $0xf01053c4
f0101eb8:	68 1a 56 10 f0       	push   $0xf010561a
f0101ebd:	68 9b 03 00 00       	push   $0x39b
f0101ec2:	68 e5 55 10 f0       	push   $0xf01055e5
f0101ec7:	e8 d4 e1 ff ff       	call   f01000a0 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101ecc:	83 ec 0c             	sub    $0xc,%esp
f0101ecf:	6a 00                	push   $0x0
f0101ed1:	e8 e2 ee ff ff       	call   f0100db8 <page_alloc>
f0101ed6:	83 c4 10             	add    $0x10,%esp
f0101ed9:	85 c0                	test   %eax,%eax
f0101edb:	74 19                	je     f0101ef6 <mem_init+0xe6d>
f0101edd:	68 70 57 10 f0       	push   $0xf0105770
f0101ee2:	68 1a 56 10 f0       	push   $0xf010561a
f0101ee7:	68 9e 03 00 00       	push   $0x39e
f0101eec:	68 e5 55 10 f0       	push   $0xf01055e5
f0101ef1:	e8 aa e1 ff ff       	call   f01000a0 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101ef6:	8b 0d 48 2c 17 f0    	mov    0xf0172c48,%ecx
f0101efc:	8b 11                	mov    (%ecx),%edx
f0101efe:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101f04:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f07:	2b 05 4c 2c 17 f0    	sub    0xf0172c4c,%eax
f0101f0d:	c1 f8 03             	sar    $0x3,%eax
f0101f10:	c1 e0 0c             	shl    $0xc,%eax
f0101f13:	39 c2                	cmp    %eax,%edx
f0101f15:	74 19                	je     f0101f30 <mem_init+0xea7>
f0101f17:	68 68 50 10 f0       	push   $0xf0105068
f0101f1c:	68 1a 56 10 f0       	push   $0xf010561a
f0101f21:	68 a1 03 00 00       	push   $0x3a1
f0101f26:	68 e5 55 10 f0       	push   $0xf01055e5
f0101f2b:	e8 70 e1 ff ff       	call   f01000a0 <_panic>
	kern_pgdir[0] = 0;
f0101f30:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0101f36:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f39:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101f3e:	74 19                	je     f0101f59 <mem_init+0xed0>
f0101f40:	68 d3 57 10 f0       	push   $0xf01057d3
f0101f45:	68 1a 56 10 f0       	push   $0xf010561a
f0101f4a:	68 a3 03 00 00       	push   $0x3a3
f0101f4f:	68 e5 55 10 f0       	push   $0xf01055e5
f0101f54:	e8 47 e1 ff ff       	call   f01000a0 <_panic>
	pp0->pp_ref = 0;
f0101f59:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f5c:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0101f62:	83 ec 0c             	sub    $0xc,%esp
f0101f65:	50                   	push   %eax
f0101f66:	e8 c4 ee ff ff       	call   f0100e2f <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0101f6b:	83 c4 0c             	add    $0xc,%esp
f0101f6e:	6a 01                	push   $0x1
f0101f70:	68 00 10 40 00       	push   $0x401000
f0101f75:	ff 35 48 2c 17 f0    	pushl  0xf0172c48
f0101f7b:	e8 11 ef ff ff       	call   f0100e91 <pgdir_walk>
f0101f80:	89 c7                	mov    %eax,%edi
f0101f82:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0101f85:	a1 48 2c 17 f0       	mov    0xf0172c48,%eax
f0101f8a:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101f8d:	8b 40 04             	mov    0x4(%eax),%eax
f0101f90:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101f95:	8b 0d 44 2c 17 f0    	mov    0xf0172c44,%ecx
f0101f9b:	89 c2                	mov    %eax,%edx
f0101f9d:	c1 ea 0c             	shr    $0xc,%edx
f0101fa0:	83 c4 10             	add    $0x10,%esp
f0101fa3:	39 ca                	cmp    %ecx,%edx
f0101fa5:	72 15                	jb     f0101fbc <mem_init+0xf33>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101fa7:	50                   	push   %eax
f0101fa8:	68 f4 4d 10 f0       	push   $0xf0104df4
f0101fad:	68 aa 03 00 00       	push   $0x3aa
f0101fb2:	68 e5 55 10 f0       	push   $0xf01055e5
f0101fb7:	e8 e4 e0 ff ff       	call   f01000a0 <_panic>
	assert(ptep == ptep1 + PTX(va));
f0101fbc:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f0101fc1:	39 c7                	cmp    %eax,%edi
f0101fc3:	74 19                	je     f0101fde <mem_init+0xf55>
f0101fc5:	68 5f 58 10 f0       	push   $0xf010585f
f0101fca:	68 1a 56 10 f0       	push   $0xf010561a
f0101fcf:	68 ab 03 00 00       	push   $0x3ab
f0101fd4:	68 e5 55 10 f0       	push   $0xf01055e5
f0101fd9:	e8 c2 e0 ff ff       	call   f01000a0 <_panic>
	kern_pgdir[PDX(va)] = 0;
f0101fde:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101fe1:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f0101fe8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101feb:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101ff1:	2b 05 4c 2c 17 f0    	sub    0xf0172c4c,%eax
f0101ff7:	c1 f8 03             	sar    $0x3,%eax
f0101ffa:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101ffd:	89 c2                	mov    %eax,%edx
f0101fff:	c1 ea 0c             	shr    $0xc,%edx
f0102002:	39 d1                	cmp    %edx,%ecx
f0102004:	77 12                	ja     f0102018 <mem_init+0xf8f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102006:	50                   	push   %eax
f0102007:	68 f4 4d 10 f0       	push   $0xf0104df4
f010200c:	6a 56                	push   $0x56
f010200e:	68 00 56 10 f0       	push   $0xf0105600
f0102013:	e8 88 e0 ff ff       	call   f01000a0 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0102018:	83 ec 04             	sub    $0x4,%esp
f010201b:	68 00 10 00 00       	push   $0x1000
f0102020:	68 ff 00 00 00       	push   $0xff
f0102025:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010202a:	50                   	push   %eax
f010202b:	e8 29 24 00 00       	call   f0104459 <memset>
	page_free(pp0);
f0102030:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102033:	89 3c 24             	mov    %edi,(%esp)
f0102036:	e8 f4 ed ff ff       	call   f0100e2f <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f010203b:	83 c4 0c             	add    $0xc,%esp
f010203e:	6a 01                	push   $0x1
f0102040:	6a 00                	push   $0x0
f0102042:	ff 35 48 2c 17 f0    	pushl  0xf0172c48
f0102048:	e8 44 ee ff ff       	call   f0100e91 <pgdir_walk>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010204d:	89 fa                	mov    %edi,%edx
f010204f:	2b 15 4c 2c 17 f0    	sub    0xf0172c4c,%edx
f0102055:	c1 fa 03             	sar    $0x3,%edx
f0102058:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010205b:	89 d0                	mov    %edx,%eax
f010205d:	c1 e8 0c             	shr    $0xc,%eax
f0102060:	83 c4 10             	add    $0x10,%esp
f0102063:	3b 05 44 2c 17 f0    	cmp    0xf0172c44,%eax
f0102069:	72 12                	jb     f010207d <mem_init+0xff4>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010206b:	52                   	push   %edx
f010206c:	68 f4 4d 10 f0       	push   $0xf0104df4
f0102071:	6a 56                	push   $0x56
f0102073:	68 00 56 10 f0       	push   $0xf0105600
f0102078:	e8 23 e0 ff ff       	call   f01000a0 <_panic>
	return (void *)(pa + KERNBASE);
f010207d:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f0102083:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102086:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f010208c:	f6 00 01             	testb  $0x1,(%eax)
f010208f:	74 19                	je     f01020aa <mem_init+0x1021>
f0102091:	68 77 58 10 f0       	push   $0xf0105877
f0102096:	68 1a 56 10 f0       	push   $0xf010561a
f010209b:	68 b5 03 00 00       	push   $0x3b5
f01020a0:	68 e5 55 10 f0       	push   $0xf01055e5
f01020a5:	e8 f6 df ff ff       	call   f01000a0 <_panic>
f01020aa:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f01020ad:	39 d0                	cmp    %edx,%eax
f01020af:	75 db                	jne    f010208c <mem_init+0x1003>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f01020b1:	a1 48 2c 17 f0       	mov    0xf0172c48,%eax
f01020b6:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f01020bc:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01020bf:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f01020c5:	8b 7d d0             	mov    -0x30(%ebp),%edi
f01020c8:	89 3d 80 1f 17 f0    	mov    %edi,0xf0171f80

	// free the pages we took
	page_free(pp0);
f01020ce:	83 ec 0c             	sub    $0xc,%esp
f01020d1:	50                   	push   %eax
f01020d2:	e8 58 ed ff ff       	call   f0100e2f <page_free>
	page_free(pp1);
f01020d7:	89 1c 24             	mov    %ebx,(%esp)
f01020da:	e8 50 ed ff ff       	call   f0100e2f <page_free>
	page_free(pp2);
f01020df:	89 34 24             	mov    %esi,(%esp)
f01020e2:	e8 48 ed ff ff       	call   f0100e2f <page_free>

	cprintf("check_page() succeeded!\n");
f01020e7:	c7 04 24 8e 58 10 f0 	movl   $0xf010588e,(%esp)
f01020ee:	e8 0d 0e 00 00       	call   f0102f00 <cprintf>
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	
	boot_map_region(kern_pgdir, UPAGES, PTSIZE, PADDR(pages), PTE_U);
f01020f3:	a1 4c 2c 17 f0       	mov    0xf0172c4c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01020f8:	83 c4 10             	add    $0x10,%esp
f01020fb:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102100:	77 15                	ja     f0102117 <mem_init+0x108e>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102102:	50                   	push   %eax
f0102103:	68 18 4e 10 f0       	push   $0xf0104e18
f0102108:	68 bc 00 00 00       	push   $0xbc
f010210d:	68 e5 55 10 f0       	push   $0xf01055e5
f0102112:	e8 89 df ff ff       	call   f01000a0 <_panic>
f0102117:	83 ec 08             	sub    $0x8,%esp
f010211a:	6a 04                	push   $0x4
f010211c:	05 00 00 00 10       	add    $0x10000000,%eax
f0102121:	50                   	push   %eax
f0102122:	b9 00 00 40 00       	mov    $0x400000,%ecx
f0102127:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f010212c:	a1 48 2c 17 f0       	mov    0xf0172c48,%eax
f0102131:	e8 f0 ed ff ff       	call   f0100f26 <boot_map_region>
	// (ie. perm = PTE_U | PTE_P).
	// Permissions:
	//    - the new image at UENVS  -- kernel R, user R
	//    - envs itself -- kernel RW, user NONE
	// LAB 3: Your code here.
	boot_map_region(kern_pgdir, UENVS, PTSIZE, PADDR(envs), PTE_U);
f0102136:	a1 88 1f 17 f0       	mov    0xf0171f88,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010213b:	83 c4 10             	add    $0x10,%esp
f010213e:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102143:	77 15                	ja     f010215a <mem_init+0x10d1>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102145:	50                   	push   %eax
f0102146:	68 18 4e 10 f0       	push   $0xf0104e18
f010214b:	68 c5 00 00 00       	push   $0xc5
f0102150:	68 e5 55 10 f0       	push   $0xf01055e5
f0102155:	e8 46 df ff ff       	call   f01000a0 <_panic>
f010215a:	83 ec 08             	sub    $0x8,%esp
f010215d:	6a 04                	push   $0x4
f010215f:	05 00 00 00 10       	add    $0x10000000,%eax
f0102164:	50                   	push   %eax
f0102165:	b9 00 00 40 00       	mov    $0x400000,%ecx
f010216a:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f010216f:	a1 48 2c 17 f0       	mov    0xf0172c48,%eax
f0102174:	e8 ad ed ff ff       	call   f0100f26 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102179:	83 c4 10             	add    $0x10,%esp
f010217c:	b8 00 10 11 f0       	mov    $0xf0111000,%eax
f0102181:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102186:	77 15                	ja     f010219d <mem_init+0x1114>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102188:	50                   	push   %eax
f0102189:	68 18 4e 10 f0       	push   $0xf0104e18
f010218e:	68 d2 00 00 00       	push   $0xd2
f0102193:	68 e5 55 10 f0       	push   $0xf01055e5
f0102198:	e8 03 df ff ff       	call   f01000a0 <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KSTACKTOP-KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W);
f010219d:	83 ec 08             	sub    $0x8,%esp
f01021a0:	6a 02                	push   $0x2
f01021a2:	68 00 10 11 00       	push   $0x111000
f01021a7:	b9 00 80 00 00       	mov    $0x8000,%ecx
f01021ac:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f01021b1:	a1 48 2c 17 f0       	mov    0xf0172c48,%eax
f01021b6:	e8 6b ed ff ff       	call   f0100f26 <boot_map_region>
	//      the PA range [0, 2^32 - KERNBASE)
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KERNBASE, 0xffffffff - KERNBASE, 0, PTE_W);
f01021bb:	83 c4 08             	add    $0x8,%esp
f01021be:	6a 02                	push   $0x2
f01021c0:	6a 00                	push   $0x0
f01021c2:	b9 ff ff ff 0f       	mov    $0xfffffff,%ecx
f01021c7:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f01021cc:	a1 48 2c 17 f0       	mov    0xf0172c48,%eax
f01021d1:	e8 50 ed ff ff       	call   f0100f26 <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f01021d6:	8b 1d 48 2c 17 f0    	mov    0xf0172c48,%ebx

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f01021dc:	a1 44 2c 17 f0       	mov    0xf0172c44,%eax
f01021e1:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01021e4:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f01021eb:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01021f0:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01021f3:	8b 3d 4c 2c 17 f0    	mov    0xf0172c4c,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01021f9:	89 7d d0             	mov    %edi,-0x30(%ebp)
f01021fc:	83 c4 10             	add    $0x10,%esp

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01021ff:	be 00 00 00 00       	mov    $0x0,%esi
f0102204:	eb 55                	jmp    f010225b <mem_init+0x11d2>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102206:	8d 96 00 00 00 ef    	lea    -0x11000000(%esi),%edx
f010220c:	89 d8                	mov    %ebx,%eax
f010220e:	e8 13 e7 ff ff       	call   f0100926 <check_va2pa>
f0102213:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f010221a:	77 15                	ja     f0102231 <mem_init+0x11a8>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010221c:	57                   	push   %edi
f010221d:	68 18 4e 10 f0       	push   $0xf0104e18
f0102222:	68 f2 02 00 00       	push   $0x2f2
f0102227:	68 e5 55 10 f0       	push   $0xf01055e5
f010222c:	e8 6f de ff ff       	call   f01000a0 <_panic>
f0102231:	8d 94 37 00 00 00 10 	lea    0x10000000(%edi,%esi,1),%edx
f0102238:	39 d0                	cmp    %edx,%eax
f010223a:	74 19                	je     f0102255 <mem_init+0x11cc>
f010223c:	68 e8 53 10 f0       	push   $0xf01053e8
f0102241:	68 1a 56 10 f0       	push   $0xf010561a
f0102246:	68 f2 02 00 00       	push   $0x2f2
f010224b:	68 e5 55 10 f0       	push   $0xf01055e5
f0102250:	e8 4b de ff ff       	call   f01000a0 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102255:	81 c6 00 10 00 00    	add    $0x1000,%esi
f010225b:	39 75 d4             	cmp    %esi,-0x2c(%ebp)
f010225e:	77 a6                	ja     f0102206 <mem_init+0x117d>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f0102260:	8b 3d 88 1f 17 f0    	mov    0xf0171f88,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102266:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0102269:	be 00 00 c0 ee       	mov    $0xeec00000,%esi
f010226e:	89 f2                	mov    %esi,%edx
f0102270:	89 d8                	mov    %ebx,%eax
f0102272:	e8 af e6 ff ff       	call   f0100926 <check_va2pa>
f0102277:	81 7d d4 ff ff ff ef 	cmpl   $0xefffffff,-0x2c(%ebp)
f010227e:	77 15                	ja     f0102295 <mem_init+0x120c>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102280:	57                   	push   %edi
f0102281:	68 18 4e 10 f0       	push   $0xf0104e18
f0102286:	68 f7 02 00 00       	push   $0x2f7
f010228b:	68 e5 55 10 f0       	push   $0xf01055e5
f0102290:	e8 0b de ff ff       	call   f01000a0 <_panic>
f0102295:	8d 94 37 00 00 40 21 	lea    0x21400000(%edi,%esi,1),%edx
f010229c:	39 c2                	cmp    %eax,%edx
f010229e:	74 19                	je     f01022b9 <mem_init+0x1230>
f01022a0:	68 1c 54 10 f0       	push   $0xf010541c
f01022a5:	68 1a 56 10 f0       	push   $0xf010561a
f01022aa:	68 f7 02 00 00       	push   $0x2f7
f01022af:	68 e5 55 10 f0       	push   $0xf01055e5
f01022b4:	e8 e7 dd ff ff       	call   f01000a0 <_panic>
f01022b9:	81 c6 00 10 00 00    	add    $0x1000,%esi
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01022bf:	81 fe 00 80 c1 ee    	cmp    $0xeec18000,%esi
f01022c5:	75 a7                	jne    f010226e <mem_init+0x11e5>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01022c7:	8b 7d cc             	mov    -0x34(%ebp),%edi
f01022ca:	c1 e7 0c             	shl    $0xc,%edi
f01022cd:	be 00 00 00 00       	mov    $0x0,%esi
f01022d2:	eb 30                	jmp    f0102304 <mem_init+0x127b>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f01022d4:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
f01022da:	89 d8                	mov    %ebx,%eax
f01022dc:	e8 45 e6 ff ff       	call   f0100926 <check_va2pa>
f01022e1:	39 c6                	cmp    %eax,%esi
f01022e3:	74 19                	je     f01022fe <mem_init+0x1275>
f01022e5:	68 50 54 10 f0       	push   $0xf0105450
f01022ea:	68 1a 56 10 f0       	push   $0xf010561a
f01022ef:	68 fb 02 00 00       	push   $0x2fb
f01022f4:	68 e5 55 10 f0       	push   $0xf01055e5
f01022f9:	e8 a2 dd ff ff       	call   f01000a0 <_panic>
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01022fe:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102304:	39 fe                	cmp    %edi,%esi
f0102306:	72 cc                	jb     f01022d4 <mem_init+0x124b>
f0102308:	be 00 80 ff ef       	mov    $0xefff8000,%esi
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f010230d:	89 f2                	mov    %esi,%edx
f010230f:	89 d8                	mov    %ebx,%eax
f0102311:	e8 10 e6 ff ff       	call   f0100926 <check_va2pa>
f0102316:	8d 96 00 90 11 10    	lea    0x10119000(%esi),%edx
f010231c:	39 c2                	cmp    %eax,%edx
f010231e:	74 19                	je     f0102339 <mem_init+0x12b0>
f0102320:	68 78 54 10 f0       	push   $0xf0105478
f0102325:	68 1a 56 10 f0       	push   $0xf010561a
f010232a:	68 ff 02 00 00       	push   $0x2ff
f010232f:	68 e5 55 10 f0       	push   $0xf01055e5
f0102334:	e8 67 dd ff ff       	call   f01000a0 <_panic>
f0102339:	81 c6 00 10 00 00    	add    $0x1000,%esi
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f010233f:	81 fe 00 00 00 f0    	cmp    $0xf0000000,%esi
f0102345:	75 c6                	jne    f010230d <mem_init+0x1284>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102347:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f010234c:	89 d8                	mov    %ebx,%eax
f010234e:	e8 d3 e5 ff ff       	call   f0100926 <check_va2pa>
f0102353:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102356:	74 51                	je     f01023a9 <mem_init+0x1320>
f0102358:	68 c0 54 10 f0       	push   $0xf01054c0
f010235d:	68 1a 56 10 f0       	push   $0xf010561a
f0102362:	68 00 03 00 00       	push   $0x300
f0102367:	68 e5 55 10 f0       	push   $0xf01055e5
f010236c:	e8 2f dd ff ff       	call   f01000a0 <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f0102371:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f0102376:	72 36                	jb     f01023ae <mem_init+0x1325>
f0102378:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f010237d:	76 07                	jbe    f0102386 <mem_init+0x12fd>
f010237f:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102384:	75 28                	jne    f01023ae <mem_init+0x1325>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
		case PDX(UENVS):
			assert(pgdir[i] & PTE_P);
f0102386:	f6 04 83 01          	testb  $0x1,(%ebx,%eax,4)
f010238a:	0f 85 83 00 00 00    	jne    f0102413 <mem_init+0x138a>
f0102390:	68 a7 58 10 f0       	push   $0xf01058a7
f0102395:	68 1a 56 10 f0       	push   $0xf010561a
f010239a:	68 09 03 00 00       	push   $0x309
f010239f:	68 e5 55 10 f0       	push   $0xf01055e5
f01023a4:	e8 f7 dc ff ff       	call   f01000a0 <_panic>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f01023a9:	b8 00 00 00 00       	mov    $0x0,%eax
		case PDX(UPAGES):
		case PDX(UENVS):
			assert(pgdir[i] & PTE_P);
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f01023ae:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f01023b3:	76 3f                	jbe    f01023f4 <mem_init+0x136b>
				assert(pgdir[i] & PTE_P);
f01023b5:	8b 14 83             	mov    (%ebx,%eax,4),%edx
f01023b8:	f6 c2 01             	test   $0x1,%dl
f01023bb:	75 19                	jne    f01023d6 <mem_init+0x134d>
f01023bd:	68 a7 58 10 f0       	push   $0xf01058a7
f01023c2:	68 1a 56 10 f0       	push   $0xf010561a
f01023c7:	68 0d 03 00 00       	push   $0x30d
f01023cc:	68 e5 55 10 f0       	push   $0xf01055e5
f01023d1:	e8 ca dc ff ff       	call   f01000a0 <_panic>
				assert(pgdir[i] & PTE_W);
f01023d6:	f6 c2 02             	test   $0x2,%dl
f01023d9:	75 38                	jne    f0102413 <mem_init+0x138a>
f01023db:	68 b8 58 10 f0       	push   $0xf01058b8
f01023e0:	68 1a 56 10 f0       	push   $0xf010561a
f01023e5:	68 0e 03 00 00       	push   $0x30e
f01023ea:	68 e5 55 10 f0       	push   $0xf01055e5
f01023ef:	e8 ac dc ff ff       	call   f01000a0 <_panic>
			} else
				assert(pgdir[i] == 0);
f01023f4:	83 3c 83 00          	cmpl   $0x0,(%ebx,%eax,4)
f01023f8:	74 19                	je     f0102413 <mem_init+0x138a>
f01023fa:	68 c9 58 10 f0       	push   $0xf01058c9
f01023ff:	68 1a 56 10 f0       	push   $0xf010561a
f0102404:	68 10 03 00 00       	push   $0x310
f0102409:	68 e5 55 10 f0       	push   $0xf01055e5
f010240e:	e8 8d dc ff ff       	call   f01000a0 <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0102413:	83 c0 01             	add    $0x1,%eax
f0102416:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f010241b:	0f 86 50 ff ff ff    	jbe    f0102371 <mem_init+0x12e8>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f0102421:	83 ec 0c             	sub    $0xc,%esp
f0102424:	68 f0 54 10 f0       	push   $0xf01054f0
f0102429:	e8 d2 0a 00 00       	call   f0102f00 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f010242e:	a1 48 2c 17 f0       	mov    0xf0172c48,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102433:	83 c4 10             	add    $0x10,%esp
f0102436:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010243b:	77 15                	ja     f0102452 <mem_init+0x13c9>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010243d:	50                   	push   %eax
f010243e:	68 18 4e 10 f0       	push   $0xf0104e18
f0102443:	68 e8 00 00 00       	push   $0xe8
f0102448:	68 e5 55 10 f0       	push   $0xf01055e5
f010244d:	e8 4e dc ff ff       	call   f01000a0 <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0102452:	05 00 00 00 10       	add    $0x10000000,%eax
f0102457:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f010245a:	b8 00 00 00 00       	mov    $0x0,%eax
f010245f:	e8 ad e5 ff ff       	call   f0100a11 <check_page_free_list>

static inline uint32_t
rcr0(void)
{
	uint32_t val;
	asm volatile("movl %%cr0,%0" : "=r" (val));
f0102464:	0f 20 c0             	mov    %cr0,%eax
f0102467:	83 e0 f3             	and    $0xfffffff3,%eax
}

static inline void
lcr0(uint32_t val)
{
	asm volatile("movl %0,%%cr0" : : "r" (val));
f010246a:	0d 23 00 05 80       	or     $0x80050023,%eax
f010246f:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102472:	83 ec 0c             	sub    $0xc,%esp
f0102475:	6a 00                	push   $0x0
f0102477:	e8 3c e9 ff ff       	call   f0100db8 <page_alloc>
f010247c:	89 c3                	mov    %eax,%ebx
f010247e:	83 c4 10             	add    $0x10,%esp
f0102481:	85 c0                	test   %eax,%eax
f0102483:	75 19                	jne    f010249e <mem_init+0x1415>
f0102485:	68 c5 56 10 f0       	push   $0xf01056c5
f010248a:	68 1a 56 10 f0       	push   $0xf010561a
f010248f:	68 d0 03 00 00       	push   $0x3d0
f0102494:	68 e5 55 10 f0       	push   $0xf01055e5
f0102499:	e8 02 dc ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f010249e:	83 ec 0c             	sub    $0xc,%esp
f01024a1:	6a 00                	push   $0x0
f01024a3:	e8 10 e9 ff ff       	call   f0100db8 <page_alloc>
f01024a8:	89 c7                	mov    %eax,%edi
f01024aa:	83 c4 10             	add    $0x10,%esp
f01024ad:	85 c0                	test   %eax,%eax
f01024af:	75 19                	jne    f01024ca <mem_init+0x1441>
f01024b1:	68 db 56 10 f0       	push   $0xf01056db
f01024b6:	68 1a 56 10 f0       	push   $0xf010561a
f01024bb:	68 d1 03 00 00       	push   $0x3d1
f01024c0:	68 e5 55 10 f0       	push   $0xf01055e5
f01024c5:	e8 d6 db ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f01024ca:	83 ec 0c             	sub    $0xc,%esp
f01024cd:	6a 00                	push   $0x0
f01024cf:	e8 e4 e8 ff ff       	call   f0100db8 <page_alloc>
f01024d4:	89 c6                	mov    %eax,%esi
f01024d6:	83 c4 10             	add    $0x10,%esp
f01024d9:	85 c0                	test   %eax,%eax
f01024db:	75 19                	jne    f01024f6 <mem_init+0x146d>
f01024dd:	68 f1 56 10 f0       	push   $0xf01056f1
f01024e2:	68 1a 56 10 f0       	push   $0xf010561a
f01024e7:	68 d2 03 00 00       	push   $0x3d2
f01024ec:	68 e5 55 10 f0       	push   $0xf01055e5
f01024f1:	e8 aa db ff ff       	call   f01000a0 <_panic>
	page_free(pp0);
f01024f6:	83 ec 0c             	sub    $0xc,%esp
f01024f9:	53                   	push   %ebx
f01024fa:	e8 30 e9 ff ff       	call   f0100e2f <page_free>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01024ff:	89 f8                	mov    %edi,%eax
f0102501:	2b 05 4c 2c 17 f0    	sub    0xf0172c4c,%eax
f0102507:	c1 f8 03             	sar    $0x3,%eax
f010250a:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010250d:	89 c2                	mov    %eax,%edx
f010250f:	c1 ea 0c             	shr    $0xc,%edx
f0102512:	83 c4 10             	add    $0x10,%esp
f0102515:	3b 15 44 2c 17 f0    	cmp    0xf0172c44,%edx
f010251b:	72 12                	jb     f010252f <mem_init+0x14a6>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010251d:	50                   	push   %eax
f010251e:	68 f4 4d 10 f0       	push   $0xf0104df4
f0102523:	6a 56                	push   $0x56
f0102525:	68 00 56 10 f0       	push   $0xf0105600
f010252a:	e8 71 db ff ff       	call   f01000a0 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f010252f:	83 ec 04             	sub    $0x4,%esp
f0102532:	68 00 10 00 00       	push   $0x1000
f0102537:	6a 01                	push   $0x1
f0102539:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010253e:	50                   	push   %eax
f010253f:	e8 15 1f 00 00       	call   f0104459 <memset>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102544:	89 f0                	mov    %esi,%eax
f0102546:	2b 05 4c 2c 17 f0    	sub    0xf0172c4c,%eax
f010254c:	c1 f8 03             	sar    $0x3,%eax
f010254f:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102552:	89 c2                	mov    %eax,%edx
f0102554:	c1 ea 0c             	shr    $0xc,%edx
f0102557:	83 c4 10             	add    $0x10,%esp
f010255a:	3b 15 44 2c 17 f0    	cmp    0xf0172c44,%edx
f0102560:	72 12                	jb     f0102574 <mem_init+0x14eb>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102562:	50                   	push   %eax
f0102563:	68 f4 4d 10 f0       	push   $0xf0104df4
f0102568:	6a 56                	push   $0x56
f010256a:	68 00 56 10 f0       	push   $0xf0105600
f010256f:	e8 2c db ff ff       	call   f01000a0 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f0102574:	83 ec 04             	sub    $0x4,%esp
f0102577:	68 00 10 00 00       	push   $0x1000
f010257c:	6a 02                	push   $0x2
f010257e:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102583:	50                   	push   %eax
f0102584:	e8 d0 1e 00 00       	call   f0104459 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102589:	6a 02                	push   $0x2
f010258b:	68 00 10 00 00       	push   $0x1000
f0102590:	57                   	push   %edi
f0102591:	ff 35 48 2c 17 f0    	pushl  0xf0172c48
f0102597:	e8 81 ea ff ff       	call   f010101d <page_insert>
	assert(pp1->pp_ref == 1);
f010259c:	83 c4 20             	add    $0x20,%esp
f010259f:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f01025a4:	74 19                	je     f01025bf <mem_init+0x1536>
f01025a6:	68 c2 57 10 f0       	push   $0xf01057c2
f01025ab:	68 1a 56 10 f0       	push   $0xf010561a
f01025b0:	68 d7 03 00 00       	push   $0x3d7
f01025b5:	68 e5 55 10 f0       	push   $0xf01055e5
f01025ba:	e8 e1 da ff ff       	call   f01000a0 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f01025bf:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f01025c6:	01 01 01 
f01025c9:	74 19                	je     f01025e4 <mem_init+0x155b>
f01025cb:	68 10 55 10 f0       	push   $0xf0105510
f01025d0:	68 1a 56 10 f0       	push   $0xf010561a
f01025d5:	68 d8 03 00 00       	push   $0x3d8
f01025da:	68 e5 55 10 f0       	push   $0xf01055e5
f01025df:	e8 bc da ff ff       	call   f01000a0 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f01025e4:	6a 02                	push   $0x2
f01025e6:	68 00 10 00 00       	push   $0x1000
f01025eb:	56                   	push   %esi
f01025ec:	ff 35 48 2c 17 f0    	pushl  0xf0172c48
f01025f2:	e8 26 ea ff ff       	call   f010101d <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f01025f7:	83 c4 10             	add    $0x10,%esp
f01025fa:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102601:	02 02 02 
f0102604:	74 19                	je     f010261f <mem_init+0x1596>
f0102606:	68 34 55 10 f0       	push   $0xf0105534
f010260b:	68 1a 56 10 f0       	push   $0xf010561a
f0102610:	68 da 03 00 00       	push   $0x3da
f0102615:	68 e5 55 10 f0       	push   $0xf01055e5
f010261a:	e8 81 da ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f010261f:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102624:	74 19                	je     f010263f <mem_init+0x15b6>
f0102626:	68 e4 57 10 f0       	push   $0xf01057e4
f010262b:	68 1a 56 10 f0       	push   $0xf010561a
f0102630:	68 db 03 00 00       	push   $0x3db
f0102635:	68 e5 55 10 f0       	push   $0xf01055e5
f010263a:	e8 61 da ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 0);
f010263f:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102644:	74 19                	je     f010265f <mem_init+0x15d6>
f0102646:	68 4e 58 10 f0       	push   $0xf010584e
f010264b:	68 1a 56 10 f0       	push   $0xf010561a
f0102650:	68 dc 03 00 00       	push   $0x3dc
f0102655:	68 e5 55 10 f0       	push   $0xf01055e5
f010265a:	e8 41 da ff ff       	call   f01000a0 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f010265f:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102666:	03 03 03 
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102669:	89 f0                	mov    %esi,%eax
f010266b:	2b 05 4c 2c 17 f0    	sub    0xf0172c4c,%eax
f0102671:	c1 f8 03             	sar    $0x3,%eax
f0102674:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102677:	89 c2                	mov    %eax,%edx
f0102679:	c1 ea 0c             	shr    $0xc,%edx
f010267c:	3b 15 44 2c 17 f0    	cmp    0xf0172c44,%edx
f0102682:	72 12                	jb     f0102696 <mem_init+0x160d>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102684:	50                   	push   %eax
f0102685:	68 f4 4d 10 f0       	push   $0xf0104df4
f010268a:	6a 56                	push   $0x56
f010268c:	68 00 56 10 f0       	push   $0xf0105600
f0102691:	e8 0a da ff ff       	call   f01000a0 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102696:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f010269d:	03 03 03 
f01026a0:	74 19                	je     f01026bb <mem_init+0x1632>
f01026a2:	68 58 55 10 f0       	push   $0xf0105558
f01026a7:	68 1a 56 10 f0       	push   $0xf010561a
f01026ac:	68 de 03 00 00       	push   $0x3de
f01026b1:	68 e5 55 10 f0       	push   $0xf01055e5
f01026b6:	e8 e5 d9 ff ff       	call   f01000a0 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f01026bb:	83 ec 08             	sub    $0x8,%esp
f01026be:	68 00 10 00 00       	push   $0x1000
f01026c3:	ff 35 48 2c 17 f0    	pushl  0xf0172c48
f01026c9:	e8 14 e9 ff ff       	call   f0100fe2 <page_remove>
	assert(pp2->pp_ref == 0);
f01026ce:	83 c4 10             	add    $0x10,%esp
f01026d1:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01026d6:	74 19                	je     f01026f1 <mem_init+0x1668>
f01026d8:	68 1c 58 10 f0       	push   $0xf010581c
f01026dd:	68 1a 56 10 f0       	push   $0xf010561a
f01026e2:	68 e0 03 00 00       	push   $0x3e0
f01026e7:	68 e5 55 10 f0       	push   $0xf01055e5
f01026ec:	e8 af d9 ff ff       	call   f01000a0 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01026f1:	8b 0d 48 2c 17 f0    	mov    0xf0172c48,%ecx
f01026f7:	8b 11                	mov    (%ecx),%edx
f01026f9:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01026ff:	89 d8                	mov    %ebx,%eax
f0102701:	2b 05 4c 2c 17 f0    	sub    0xf0172c4c,%eax
f0102707:	c1 f8 03             	sar    $0x3,%eax
f010270a:	c1 e0 0c             	shl    $0xc,%eax
f010270d:	39 c2                	cmp    %eax,%edx
f010270f:	74 19                	je     f010272a <mem_init+0x16a1>
f0102711:	68 68 50 10 f0       	push   $0xf0105068
f0102716:	68 1a 56 10 f0       	push   $0xf010561a
f010271b:	68 e3 03 00 00       	push   $0x3e3
f0102720:	68 e5 55 10 f0       	push   $0xf01055e5
f0102725:	e8 76 d9 ff ff       	call   f01000a0 <_panic>
	kern_pgdir[0] = 0;
f010272a:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102730:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102735:	74 19                	je     f0102750 <mem_init+0x16c7>
f0102737:	68 d3 57 10 f0       	push   $0xf01057d3
f010273c:	68 1a 56 10 f0       	push   $0xf010561a
f0102741:	68 e5 03 00 00       	push   $0x3e5
f0102746:	68 e5 55 10 f0       	push   $0xf01055e5
f010274b:	e8 50 d9 ff ff       	call   f01000a0 <_panic>
	pp0->pp_ref = 0;
f0102750:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f0102756:	83 ec 0c             	sub    $0xc,%esp
f0102759:	53                   	push   %ebx
f010275a:	e8 d0 e6 ff ff       	call   f0100e2f <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f010275f:	c7 04 24 84 55 10 f0 	movl   $0xf0105584,(%esp)
f0102766:	e8 95 07 00 00       	call   f0102f00 <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f010276b:	83 c4 10             	add    $0x10,%esp
f010276e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102771:	5b                   	pop    %ebx
f0102772:	5e                   	pop    %esi
f0102773:	5f                   	pop    %edi
f0102774:	5d                   	pop    %ebp
f0102775:	c3                   	ret    

f0102776 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0102776:	55                   	push   %ebp
f0102777:	89 e5                	mov    %esp,%ebp
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0102779:	8b 45 0c             	mov    0xc(%ebp),%eax
f010277c:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f010277f:	5d                   	pop    %ebp
f0102780:	c3                   	ret    

f0102781 <user_mem_check>:
// Returns 0 if the user program can access this range of addresses,
// and -E_FAULT otherwise.
//
int
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
f0102781:	55                   	push   %ebp
f0102782:	89 e5                	mov    %esp,%ebp
f0102784:	57                   	push   %edi
f0102785:	56                   	push   %esi
f0102786:	53                   	push   %ebx
f0102787:	83 ec 2c             	sub    $0x2c,%esp
f010278a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// LAB 3: Your code here.
	void *vat =(void *) va;
	void *end =(void *)va + len;
f010278d:	89 d8                	mov    %ebx,%eax
f010278f:	03 45 10             	add    0x10(%ebp),%eax
f0102792:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	int p = perm | PTE_P;
f0102795:	8b 75 14             	mov    0x14(%ebp),%esi
f0102798:	83 ce 01             	or     $0x1,%esi
	for (; vat < end; vat = ROUNDDOWN(vat+PGSIZE, PGSIZE)) {
		if ((uint32_t)vat > ULIM) {
			user_mem_check_addr =(uintptr_t) vat;
			return -E_FAULT;
		}
		page_lookup(env->env_pgdir, vat, &pte);
f010279b:	8d 7d e4             	lea    -0x1c(%ebp),%edi
	// LAB 3: Your code here.
	void *vat =(void *) va;
	void *end =(void *)va + len;
	int p = perm | PTE_P;
	pte_t *pte;
	for (; vat < end; vat = ROUNDDOWN(vat+PGSIZE, PGSIZE)) {
f010279e:	eb 55                	jmp    f01027f5 <user_mem_check+0x74>
		if ((uint32_t)vat > ULIM) {
f01027a0:	89 5d d0             	mov    %ebx,-0x30(%ebp)
f01027a3:	81 fb 00 00 80 ef    	cmp    $0xef800000,%ebx
f01027a9:	76 0d                	jbe    f01027b8 <user_mem_check+0x37>
			user_mem_check_addr =(uintptr_t) vat;
f01027ab:	89 1d 7c 1f 17 f0    	mov    %ebx,0xf0171f7c
			return -E_FAULT;
f01027b1:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f01027b6:	eb 47                	jmp    f01027ff <user_mem_check+0x7e>
		}
		page_lookup(env->env_pgdir, vat, &pte);
f01027b8:	83 ec 04             	sub    $0x4,%esp
f01027bb:	57                   	push   %edi
f01027bc:	53                   	push   %ebx
f01027bd:	8b 45 08             	mov    0x8(%ebp),%eax
f01027c0:	ff 70 5c             	pushl  0x5c(%eax)
f01027c3:	e8 c0 e7 ff ff       	call   f0100f88 <page_lookup>
		if (!(pte && ((*pte & p) == p))) {
f01027c8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01027cb:	83 c4 10             	add    $0x10,%esp
f01027ce:	85 c0                	test   %eax,%eax
f01027d0:	74 08                	je     f01027da <user_mem_check+0x59>
f01027d2:	89 f2                	mov    %esi,%edx
f01027d4:	23 10                	and    (%eax),%edx
f01027d6:	39 d6                	cmp    %edx,%esi
f01027d8:	74 0f                	je     f01027e9 <user_mem_check+0x68>
			user_mem_check_addr = (uintptr_t) vat;
f01027da:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01027dd:	a3 7c 1f 17 f0       	mov    %eax,0xf0171f7c
			return -E_FAULT;
f01027e2:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f01027e7:	eb 16                	jmp    f01027ff <user_mem_check+0x7e>
	// LAB 3: Your code here.
	void *vat =(void *) va;
	void *end =(void *)va + len;
	int p = perm | PTE_P;
	pte_t *pte;
	for (; vat < end; vat = ROUNDDOWN(vat+PGSIZE, PGSIZE)) {
f01027e9:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01027ef:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
f01027f5:	3b 5d d4             	cmp    -0x2c(%ebp),%ebx
f01027f8:	72 a6                	jb     f01027a0 <user_mem_check+0x1f>
			user_mem_check_addr = (uintptr_t) vat;
			return -E_FAULT;
		}
	}

	return 0;
f01027fa:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01027ff:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102802:	5b                   	pop    %ebx
f0102803:	5e                   	pop    %esi
f0102804:	5f                   	pop    %edi
f0102805:	5d                   	pop    %ebp
f0102806:	c3                   	ret    

f0102807 <user_mem_assert>:
// If it cannot, 'env' is destroyed and, if env is the current
// environment, this function will not return.
//
void
user_mem_assert(struct Env *env, const void *va, size_t len, int perm)
{
f0102807:	55                   	push   %ebp
f0102808:	89 e5                	mov    %esp,%ebp
f010280a:	53                   	push   %ebx
f010280b:	83 ec 04             	sub    $0x4,%esp
f010280e:	8b 5d 08             	mov    0x8(%ebp),%ebx
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
f0102811:	8b 45 14             	mov    0x14(%ebp),%eax
f0102814:	83 c8 04             	or     $0x4,%eax
f0102817:	50                   	push   %eax
f0102818:	ff 75 10             	pushl  0x10(%ebp)
f010281b:	ff 75 0c             	pushl  0xc(%ebp)
f010281e:	53                   	push   %ebx
f010281f:	e8 5d ff ff ff       	call   f0102781 <user_mem_check>
f0102824:	83 c4 10             	add    $0x10,%esp
f0102827:	85 c0                	test   %eax,%eax
f0102829:	79 21                	jns    f010284c <user_mem_assert+0x45>
		cprintf("[%08x] user_mem_check assertion failure for "
f010282b:	83 ec 04             	sub    $0x4,%esp
f010282e:	ff 35 7c 1f 17 f0    	pushl  0xf0171f7c
f0102834:	ff 73 48             	pushl  0x48(%ebx)
f0102837:	68 b0 55 10 f0       	push   $0xf01055b0
f010283c:	e8 bf 06 00 00       	call   f0102f00 <cprintf>
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
f0102841:	89 1c 24             	mov    %ebx,(%esp)
f0102844:	e8 9e 05 00 00       	call   f0102de7 <env_destroy>
f0102849:	83 c4 10             	add    $0x10,%esp
	}
}
f010284c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010284f:	c9                   	leave  
f0102850:	c3                   	ret    

f0102851 <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f0102851:	55                   	push   %ebp
f0102852:	89 e5                	mov    %esp,%ebp
f0102854:	57                   	push   %edi
f0102855:	56                   	push   %esi
f0102856:	53                   	push   %ebx
f0102857:	83 ec 0c             	sub    $0xc,%esp
f010285a:	89 c7                	mov    %eax,%edi
	//
	// Hint: It is easier to use region_alloc if the caller can pass
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	void *va_t = ROUNDDOWN(va, PGSIZE);
f010285c:	89 d3                	mov    %edx,%ebx
f010285e:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx

	void *end = ROUNDUP(va + len, PGSIZE);
f0102864:	8d b4 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%esi
f010286b:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	for(; va_t < end;va_t += PGSIZE){
f0102871:	eb 3d                	jmp    f01028b0 <region_alloc+0x5f>
		struct PageInfo *pp = page_alloc(1);	
f0102873:	83 ec 0c             	sub    $0xc,%esp
f0102876:	6a 01                	push   $0x1
f0102878:	e8 3b e5 ff ff       	call   f0100db8 <page_alloc>
		if(pp == NULL){
f010287d:	83 c4 10             	add    $0x10,%esp
f0102880:	85 c0                	test   %eax,%eax
f0102882:	75 17                	jne    f010289b <region_alloc+0x4a>
			panic("page alloc failed!\n");	
f0102884:	83 ec 04             	sub    $0x4,%esp
f0102887:	68 d7 58 10 f0       	push   $0xf01058d7
f010288c:	68 1d 01 00 00       	push   $0x11d
f0102891:	68 eb 58 10 f0       	push   $0xf01058eb
f0102896:	e8 05 d8 ff ff       	call   f01000a0 <_panic>
		}
		page_insert(e->env_pgdir, pp, va_t, PTE_U | PTE_W);	
f010289b:	6a 06                	push   $0x6
f010289d:	53                   	push   %ebx
f010289e:	50                   	push   %eax
f010289f:	ff 77 5c             	pushl  0x5c(%edi)
f01028a2:	e8 76 e7 ff ff       	call   f010101d <page_insert>
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	void *va_t = ROUNDDOWN(va, PGSIZE);

	void *end = ROUNDUP(va + len, PGSIZE);
	for(; va_t < end;va_t += PGSIZE){
f01028a7:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01028ad:	83 c4 10             	add    $0x10,%esp
f01028b0:	39 f3                	cmp    %esi,%ebx
f01028b2:	72 bf                	jb     f0102873 <region_alloc+0x22>
		if(pp == NULL){
			panic("page alloc failed!\n");	
		}
		page_insert(e->env_pgdir, pp, va_t, PTE_U | PTE_W);	
	}
}
f01028b4:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01028b7:	5b                   	pop    %ebx
f01028b8:	5e                   	pop    %esi
f01028b9:	5f                   	pop    %edi
f01028ba:	5d                   	pop    %ebp
f01028bb:	c3                   	ret    

f01028bc <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f01028bc:	55                   	push   %ebp
f01028bd:	89 e5                	mov    %esp,%ebp
f01028bf:	8b 55 08             	mov    0x8(%ebp),%edx
f01028c2:	8b 4d 10             	mov    0x10(%ebp),%ecx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f01028c5:	85 d2                	test   %edx,%edx
f01028c7:	75 11                	jne    f01028da <envid2env+0x1e>
		*env_store = curenv;
f01028c9:	a1 84 1f 17 f0       	mov    0xf0171f84,%eax
f01028ce:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01028d1:	89 01                	mov    %eax,(%ecx)
		return 0;
f01028d3:	b8 00 00 00 00       	mov    $0x0,%eax
f01028d8:	eb 5e                	jmp    f0102938 <envid2env+0x7c>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f01028da:	89 d0                	mov    %edx,%eax
f01028dc:	25 ff 03 00 00       	and    $0x3ff,%eax
f01028e1:	8d 04 40             	lea    (%eax,%eax,2),%eax
f01028e4:	c1 e0 05             	shl    $0x5,%eax
f01028e7:	03 05 88 1f 17 f0    	add    0xf0171f88,%eax
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f01028ed:	83 78 54 00          	cmpl   $0x0,0x54(%eax)
f01028f1:	74 05                	je     f01028f8 <envid2env+0x3c>
f01028f3:	3b 50 48             	cmp    0x48(%eax),%edx
f01028f6:	74 10                	je     f0102908 <envid2env+0x4c>
		*env_store = 0;
f01028f8:	8b 45 0c             	mov    0xc(%ebp),%eax
f01028fb:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0102901:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0102906:	eb 30                	jmp    f0102938 <envid2env+0x7c>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f0102908:	84 c9                	test   %cl,%cl
f010290a:	74 22                	je     f010292e <envid2env+0x72>
f010290c:	8b 15 84 1f 17 f0    	mov    0xf0171f84,%edx
f0102912:	39 d0                	cmp    %edx,%eax
f0102914:	74 18                	je     f010292e <envid2env+0x72>
f0102916:	8b 4a 48             	mov    0x48(%edx),%ecx
f0102919:	39 48 4c             	cmp    %ecx,0x4c(%eax)
f010291c:	74 10                	je     f010292e <envid2env+0x72>
		*env_store = 0;
f010291e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102921:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0102927:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f010292c:	eb 0a                	jmp    f0102938 <envid2env+0x7c>
	}

	*env_store = e;
f010292e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0102931:	89 01                	mov    %eax,(%ecx)
	return 0;
f0102933:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102938:	5d                   	pop    %ebp
f0102939:	c3                   	ret    

f010293a <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f010293a:	55                   	push   %ebp
f010293b:	89 e5                	mov    %esp,%ebp
}

static inline void
lgdt(void *p)
{
	asm volatile("lgdt (%0)" : : "r" (p));
f010293d:	b8 00 b3 11 f0       	mov    $0xf011b300,%eax
f0102942:	0f 01 10             	lgdtl  (%eax)
	lgdt(&gdt_pd);
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" : : "a" (GD_UD|3));
f0102945:	b8 23 00 00 00       	mov    $0x23,%eax
f010294a:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" : : "a" (GD_UD|3));
f010294c:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" : : "a" (GD_KD));
f010294e:	b8 10 00 00 00       	mov    $0x10,%eax
f0102953:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" : : "a" (GD_KD));
f0102955:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" : : "a" (GD_KD));
f0102957:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" : : "i" (GD_KT));
f0102959:	ea 60 29 10 f0 08 00 	ljmp   $0x8,$0xf0102960
}

static inline void
lldt(uint16_t sel)
{
	asm volatile("lldt %0" : : "r" (sel));
f0102960:	b8 00 00 00 00       	mov    $0x0,%eax
f0102965:	0f 00 d0             	lldt   %ax
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
}
f0102968:	5d                   	pop    %ebp
f0102969:	c3                   	ret    

f010296a <env_init>:
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f010296a:	55                   	push   %ebp
f010296b:	89 e5                	mov    %esp,%ebp
f010296d:	56                   	push   %esi
f010296e:	53                   	push   %ebx
	// Set up envs array
	// LAB 3: Your code here.
	for (int i = NENV - 1; i >= 0; i--) {
		envs[i].env_id = 0;
f010296f:	8b 35 88 1f 17 f0    	mov    0xf0171f88,%esi
f0102975:	8b 15 8c 1f 17 f0    	mov    0xf0171f8c,%edx
f010297b:	8d 86 a0 7f 01 00    	lea    0x17fa0(%esi),%eax
f0102981:	8d 5e a0             	lea    -0x60(%esi),%ebx
f0102984:	89 c1                	mov    %eax,%ecx
f0102986:	c7 40 48 00 00 00 00 	movl   $0x0,0x48(%eax)
		envs[i].env_status = ENV_FREE;
f010298d:	c7 40 54 00 00 00 00 	movl   $0x0,0x54(%eax)
		envs[i].env_link = env_free_list;
f0102994:	89 50 44             	mov    %edx,0x44(%eax)
f0102997:	83 e8 60             	sub    $0x60,%eax
		env_free_list = &envs[i];
f010299a:	89 ca                	mov    %ecx,%edx
void
env_init(void)
{
	// Set up envs array
	// LAB 3: Your code here.
	for (int i = NENV - 1; i >= 0; i--) {
f010299c:	39 d8                	cmp    %ebx,%eax
f010299e:	75 e4                	jne    f0102984 <env_init+0x1a>
f01029a0:	89 35 8c 1f 17 f0    	mov    %esi,0xf0171f8c
		envs[i].env_link = env_free_list;
		env_free_list = &envs[i];
	}

	// Per-CPU part of the initialization
	env_init_percpu();
f01029a6:	e8 8f ff ff ff       	call   f010293a <env_init_percpu>
}
f01029ab:	5b                   	pop    %ebx
f01029ac:	5e                   	pop    %esi
f01029ad:	5d                   	pop    %ebp
f01029ae:	c3                   	ret    

f01029af <env_alloc>:
//	-E_NO_FREE_ENV if all NENVS environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f01029af:	55                   	push   %ebp
f01029b0:	89 e5                	mov    %esp,%ebp
f01029b2:	53                   	push   %ebx
f01029b3:	83 ec 04             	sub    $0x4,%esp
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f01029b6:	8b 1d 8c 1f 17 f0    	mov    0xf0171f8c,%ebx
f01029bc:	85 db                	test   %ebx,%ebx
f01029be:	0f 84 48 01 00 00    	je     f0102b0c <env_alloc+0x15d>
{
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
f01029c4:	83 ec 0c             	sub    $0xc,%esp
f01029c7:	6a 01                	push   $0x1
f01029c9:	e8 ea e3 ff ff       	call   f0100db8 <page_alloc>
f01029ce:	83 c4 10             	add    $0x10,%esp
f01029d1:	85 c0                	test   %eax,%eax
f01029d3:	0f 84 3a 01 00 00    	je     f0102b13 <env_alloc+0x164>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01029d9:	89 c2                	mov    %eax,%edx
f01029db:	2b 15 4c 2c 17 f0    	sub    0xf0172c4c,%edx
f01029e1:	c1 fa 03             	sar    $0x3,%edx
f01029e4:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01029e7:	89 d1                	mov    %edx,%ecx
f01029e9:	c1 e9 0c             	shr    $0xc,%ecx
f01029ec:	3b 0d 44 2c 17 f0    	cmp    0xf0172c44,%ecx
f01029f2:	72 12                	jb     f0102a06 <env_alloc+0x57>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01029f4:	52                   	push   %edx
f01029f5:	68 f4 4d 10 f0       	push   $0xf0104df4
f01029fa:	6a 56                	push   $0x56
f01029fc:	68 00 56 10 f0       	push   $0xf0105600
f0102a01:	e8 9a d6 ff ff       	call   f01000a0 <_panic>
	//	is an exception -- you need to increment env_pgdir's
	//	pp_ref for env_free to work correctly.
	//    - The functions in kern/pmap.h are handy.

	// LAB 3: Your code here.
	e->env_pgdir = page2kva(p);
f0102a06:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f0102a0c:	89 53 5c             	mov    %edx,0x5c(%ebx)
	p->pp_ref++;
f0102a0f:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
	memcpy(e->env_pgdir, kern_pgdir, PGSIZE);
f0102a14:	83 ec 04             	sub    $0x4,%esp
f0102a17:	68 00 10 00 00       	push   $0x1000
f0102a1c:	ff 35 48 2c 17 f0    	pushl  0xf0172c48
f0102a22:	ff 73 5c             	pushl  0x5c(%ebx)
f0102a25:	e8 e4 1a 00 00       	call   f010450e <memcpy>

	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f0102a2a:	8b 43 5c             	mov    0x5c(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102a2d:	83 c4 10             	add    $0x10,%esp
f0102a30:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102a35:	77 15                	ja     f0102a4c <env_alloc+0x9d>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102a37:	50                   	push   %eax
f0102a38:	68 18 4e 10 f0       	push   $0xf0104e18
f0102a3d:	68 c2 00 00 00       	push   $0xc2
f0102a42:	68 eb 58 10 f0       	push   $0xf01058eb
f0102a47:	e8 54 d6 ff ff       	call   f01000a0 <_panic>
f0102a4c:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0102a52:	83 ca 05             	or     $0x5,%edx
f0102a55:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f0102a5b:	8b 43 48             	mov    0x48(%ebx),%eax
f0102a5e:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f0102a63:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f0102a68:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102a6d:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f0102a70:	89 da                	mov    %ebx,%edx
f0102a72:	2b 15 88 1f 17 f0    	sub    0xf0171f88,%edx
f0102a78:	c1 fa 05             	sar    $0x5,%edx
f0102a7b:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f0102a81:	09 d0                	or     %edx,%eax
f0102a83:	89 43 48             	mov    %eax,0x48(%ebx)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f0102a86:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102a89:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f0102a8c:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f0102a93:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f0102a9a:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f0102aa1:	83 ec 04             	sub    $0x4,%esp
f0102aa4:	6a 44                	push   $0x44
f0102aa6:	6a 00                	push   $0x0
f0102aa8:	53                   	push   %ebx
f0102aa9:	e8 ab 19 00 00       	call   f0104459 <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f0102aae:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f0102ab4:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f0102aba:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f0102ac0:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f0102ac7:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)
	// You will set e->env_tf.tf_eip later.

	// commit the allocation
	env_free_list = e->env_link;
f0102acd:	8b 43 44             	mov    0x44(%ebx),%eax
f0102ad0:	a3 8c 1f 17 f0       	mov    %eax,0xf0171f8c
	*newenv_store = e;
f0102ad5:	8b 45 08             	mov    0x8(%ebp),%eax
f0102ad8:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0102ada:	8b 53 48             	mov    0x48(%ebx),%edx
f0102add:	a1 84 1f 17 f0       	mov    0xf0171f84,%eax
f0102ae2:	83 c4 10             	add    $0x10,%esp
f0102ae5:	85 c0                	test   %eax,%eax
f0102ae7:	74 05                	je     f0102aee <env_alloc+0x13f>
f0102ae9:	8b 40 48             	mov    0x48(%eax),%eax
f0102aec:	eb 05                	jmp    f0102af3 <env_alloc+0x144>
f0102aee:	b8 00 00 00 00       	mov    $0x0,%eax
f0102af3:	83 ec 04             	sub    $0x4,%esp
f0102af6:	52                   	push   %edx
f0102af7:	50                   	push   %eax
f0102af8:	68 f6 58 10 f0       	push   $0xf01058f6
f0102afd:	e8 fe 03 00 00       	call   f0102f00 <cprintf>
	return 0;
f0102b02:	83 c4 10             	add    $0x10,%esp
f0102b05:	b8 00 00 00 00       	mov    $0x0,%eax
f0102b0a:	eb 0c                	jmp    f0102b18 <env_alloc+0x169>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f0102b0c:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f0102b11:	eb 05                	jmp    f0102b18 <env_alloc+0x169>
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f0102b13:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	env_free_list = e->env_link;
	*newenv_store = e;

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f0102b18:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102b1b:	c9                   	leave  
f0102b1c:	c3                   	ret    

f0102b1d <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f0102b1d:	55                   	push   %ebp
f0102b1e:	89 e5                	mov    %esp,%ebp
f0102b20:	57                   	push   %edi
f0102b21:	56                   	push   %esi
f0102b22:	53                   	push   %ebx
f0102b23:	83 ec 34             	sub    $0x34,%esp
f0102b26:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.
	struct Env *e;
	env_alloc(&e, 0);
f0102b29:	6a 00                	push   $0x0
f0102b2b:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0102b2e:	50                   	push   %eax
f0102b2f:	e8 7b fe ff ff       	call   f01029af <env_alloc>
	load_icode(e, binary);
f0102b34:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102b37:	89 45 d4             	mov    %eax,-0x2c(%ebp)

	// LAB 3: Your code here.
	
	struct Elf *elf = (struct Elf *) binary;

	if (elf->e_magic != ELF_MAGIC)
f0102b3a:	83 c4 10             	add    $0x10,%esp
f0102b3d:	81 3f 7f 45 4c 46    	cmpl   $0x464c457f,(%edi)
f0102b43:	74 17                	je     f0102b5c <env_create+0x3f>
		panic("load_icode: not ELF executable.");
f0102b45:	83 ec 04             	sub    $0x4,%esp
f0102b48:	68 30 59 10 f0       	push   $0xf0105930
f0102b4d:	68 5d 01 00 00       	push   $0x15d
f0102b52:	68 eb 58 10 f0       	push   $0xf01058eb
f0102b57:	e8 44 d5 ff ff       	call   f01000a0 <_panic>

	struct Proghdr *ph = (struct Proghdr *) (elf->e_phoff + binary);
f0102b5c:	89 fb                	mov    %edi,%ebx
f0102b5e:	03 5f 1c             	add    0x1c(%edi),%ebx
	struct Proghdr *eph = ph + elf->e_phnum;
f0102b61:	0f b7 77 2c          	movzwl 0x2c(%edi),%esi
f0102b65:	c1 e6 05             	shl    $0x5,%esi
f0102b68:	01 de                	add    %ebx,%esi

	lcr3(PADDR(e->env_pgdir));
f0102b6a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102b6d:	8b 40 5c             	mov    0x5c(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102b70:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102b75:	77 15                	ja     f0102b8c <env_create+0x6f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102b77:	50                   	push   %eax
f0102b78:	68 18 4e 10 f0       	push   $0xf0104e18
f0102b7d:	68 62 01 00 00       	push   $0x162
f0102b82:	68 eb 58 10 f0       	push   $0xf01058eb
f0102b87:	e8 14 d5 ff ff       	call   f01000a0 <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0102b8c:	05 00 00 00 10       	add    $0x10000000,%eax
f0102b91:	0f 22 d8             	mov    %eax,%cr3
f0102b94:	eb 3d                	jmp    f0102bd3 <env_create+0xb6>
	for(; ph < eph; ph++){
		if(ph->p_type == ELF_PROG_LOAD){
f0102b96:	83 3b 01             	cmpl   $0x1,(%ebx)
f0102b99:	75 35                	jne    f0102bd0 <env_create+0xb3>
			region_alloc(e, (void *) ph->p_va, ph->p_memsz);
f0102b9b:	8b 4b 14             	mov    0x14(%ebx),%ecx
f0102b9e:	8b 53 08             	mov    0x8(%ebx),%edx
f0102ba1:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102ba4:	e8 a8 fc ff ff       	call   f0102851 <region_alloc>
			memset((void *) ph->p_va, 0, ph->p_memsz);
f0102ba9:	83 ec 04             	sub    $0x4,%esp
f0102bac:	ff 73 14             	pushl  0x14(%ebx)
f0102baf:	6a 00                	push   $0x0
f0102bb1:	ff 73 08             	pushl  0x8(%ebx)
f0102bb4:	e8 a0 18 00 00       	call   f0104459 <memset>
			memcpy((void *) ph->p_va, binary + ph->p_offset, ph->p_filesz);
f0102bb9:	83 c4 0c             	add    $0xc,%esp
f0102bbc:	ff 73 10             	pushl  0x10(%ebx)
f0102bbf:	89 f8                	mov    %edi,%eax
f0102bc1:	03 43 04             	add    0x4(%ebx),%eax
f0102bc4:	50                   	push   %eax
f0102bc5:	ff 73 08             	pushl  0x8(%ebx)
f0102bc8:	e8 41 19 00 00       	call   f010450e <memcpy>
f0102bcd:	83 c4 10             	add    $0x10,%esp

	struct Proghdr *ph = (struct Proghdr *) (elf->e_phoff + binary);
	struct Proghdr *eph = ph + elf->e_phnum;

	lcr3(PADDR(e->env_pgdir));
	for(; ph < eph; ph++){
f0102bd0:	83 c3 20             	add    $0x20,%ebx
f0102bd3:	39 de                	cmp    %ebx,%esi
f0102bd5:	77 bf                	ja     f0102b96 <env_create+0x79>
			region_alloc(e, (void *) ph->p_va, ph->p_memsz);
			memset((void *) ph->p_va, 0, ph->p_memsz);
			memcpy((void *) ph->p_va, binary + ph->p_offset, ph->p_filesz);
		}
	}
	lcr3(PADDR(kern_pgdir));
f0102bd7:	a1 48 2c 17 f0       	mov    0xf0172c48,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102bdc:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102be1:	77 15                	ja     f0102bf8 <env_create+0xdb>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102be3:	50                   	push   %eax
f0102be4:	68 18 4e 10 f0       	push   $0xf0104e18
f0102be9:	68 6a 01 00 00       	push   $0x16a
f0102bee:	68 eb 58 10 f0       	push   $0xf01058eb
f0102bf3:	e8 a8 d4 ff ff       	call   f01000a0 <_panic>
f0102bf8:	05 00 00 00 10       	add    $0x10000000,%eax
f0102bfd:	0f 22 d8             	mov    %eax,%cr3
	e->env_tf.tf_eip = elf->e_entry;
f0102c00:	8b 47 18             	mov    0x18(%edi),%eax
f0102c03:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102c06:	89 47 30             	mov    %eax,0x30(%edi)
	// Now map one page for the program's initial stack
	// at virtual address USTACKTOP - PGSIZE.

	// LAB 3: Your code here.
	region_alloc(e, (void *) (USTACKTOP - PGSIZE), PGSIZE);
f0102c09:	b9 00 10 00 00       	mov    $0x1000,%ecx
f0102c0e:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f0102c13:	89 f8                	mov    %edi,%eax
f0102c15:	e8 37 fc ff ff       	call   f0102851 <region_alloc>
{
	// LAB 3: Your code here.
	struct Env *e;
	env_alloc(&e, 0);
	load_icode(e, binary);
	e->env_type = type;
f0102c1a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102c1d:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102c20:	89 50 50             	mov    %edx,0x50(%eax)
}
f0102c23:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102c26:	5b                   	pop    %ebx
f0102c27:	5e                   	pop    %esi
f0102c28:	5f                   	pop    %edi
f0102c29:	5d                   	pop    %ebp
f0102c2a:	c3                   	ret    

f0102c2b <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f0102c2b:	55                   	push   %ebp
f0102c2c:	89 e5                	mov    %esp,%ebp
f0102c2e:	57                   	push   %edi
f0102c2f:	56                   	push   %esi
f0102c30:	53                   	push   %ebx
f0102c31:	83 ec 1c             	sub    $0x1c,%esp
f0102c34:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f0102c37:	8b 15 84 1f 17 f0    	mov    0xf0171f84,%edx
f0102c3d:	39 fa                	cmp    %edi,%edx
f0102c3f:	75 29                	jne    f0102c6a <env_free+0x3f>
		lcr3(PADDR(kern_pgdir));
f0102c41:	a1 48 2c 17 f0       	mov    0xf0172c48,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102c46:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102c4b:	77 15                	ja     f0102c62 <env_free+0x37>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102c4d:	50                   	push   %eax
f0102c4e:	68 18 4e 10 f0       	push   $0xf0104e18
f0102c53:	68 93 01 00 00       	push   $0x193
f0102c58:	68 eb 58 10 f0       	push   $0xf01058eb
f0102c5d:	e8 3e d4 ff ff       	call   f01000a0 <_panic>
f0102c62:	05 00 00 00 10       	add    $0x10000000,%eax
f0102c67:	0f 22 d8             	mov    %eax,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0102c6a:	8b 4f 48             	mov    0x48(%edi),%ecx
f0102c6d:	85 d2                	test   %edx,%edx
f0102c6f:	74 05                	je     f0102c76 <env_free+0x4b>
f0102c71:	8b 42 48             	mov    0x48(%edx),%eax
f0102c74:	eb 05                	jmp    f0102c7b <env_free+0x50>
f0102c76:	b8 00 00 00 00       	mov    $0x0,%eax
f0102c7b:	83 ec 04             	sub    $0x4,%esp
f0102c7e:	51                   	push   %ecx
f0102c7f:	50                   	push   %eax
f0102c80:	68 0b 59 10 f0       	push   $0xf010590b
f0102c85:	e8 76 02 00 00       	call   f0102f00 <cprintf>
f0102c8a:	83 c4 10             	add    $0x10,%esp

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0102c8d:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0102c94:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0102c97:	89 d0                	mov    %edx,%eax
f0102c99:	c1 e0 02             	shl    $0x2,%eax
f0102c9c:	89 45 dc             	mov    %eax,-0x24(%ebp)

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f0102c9f:	8b 47 5c             	mov    0x5c(%edi),%eax
f0102ca2:	8b 34 90             	mov    (%eax,%edx,4),%esi
f0102ca5:	f7 c6 01 00 00 00    	test   $0x1,%esi
f0102cab:	0f 84 a8 00 00 00    	je     f0102d59 <env_free+0x12e>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f0102cb1:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102cb7:	89 f0                	mov    %esi,%eax
f0102cb9:	c1 e8 0c             	shr    $0xc,%eax
f0102cbc:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102cbf:	39 05 44 2c 17 f0    	cmp    %eax,0xf0172c44
f0102cc5:	77 15                	ja     f0102cdc <env_free+0xb1>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102cc7:	56                   	push   %esi
f0102cc8:	68 f4 4d 10 f0       	push   $0xf0104df4
f0102ccd:	68 a2 01 00 00       	push   $0x1a2
f0102cd2:	68 eb 58 10 f0       	push   $0xf01058eb
f0102cd7:	e8 c4 d3 ff ff       	call   f01000a0 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0102cdc:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102cdf:	c1 e0 16             	shl    $0x16,%eax
f0102ce2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0102ce5:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f0102cea:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f0102cf1:	01 
f0102cf2:	74 17                	je     f0102d0b <env_free+0xe0>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0102cf4:	83 ec 08             	sub    $0x8,%esp
f0102cf7:	89 d8                	mov    %ebx,%eax
f0102cf9:	c1 e0 0c             	shl    $0xc,%eax
f0102cfc:	0b 45 e4             	or     -0x1c(%ebp),%eax
f0102cff:	50                   	push   %eax
f0102d00:	ff 77 5c             	pushl  0x5c(%edi)
f0102d03:	e8 da e2 ff ff       	call   f0100fe2 <page_remove>
f0102d08:	83 c4 10             	add    $0x10,%esp
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0102d0b:	83 c3 01             	add    $0x1,%ebx
f0102d0e:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f0102d14:	75 d4                	jne    f0102cea <env_free+0xbf>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f0102d16:	8b 47 5c             	mov    0x5c(%edi),%eax
f0102d19:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102d1c:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102d23:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102d26:	3b 05 44 2c 17 f0    	cmp    0xf0172c44,%eax
f0102d2c:	72 14                	jb     f0102d42 <env_free+0x117>
		panic("pa2page called with invalid pa");
f0102d2e:	83 ec 04             	sub    $0x4,%esp
f0102d31:	68 34 4f 10 f0       	push   $0xf0104f34
f0102d36:	6a 4f                	push   $0x4f
f0102d38:	68 00 56 10 f0       	push   $0xf0105600
f0102d3d:	e8 5e d3 ff ff       	call   f01000a0 <_panic>
		page_decref(pa2page(pa));
f0102d42:	83 ec 0c             	sub    $0xc,%esp
f0102d45:	a1 4c 2c 17 f0       	mov    0xf0172c4c,%eax
f0102d4a:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102d4d:	8d 04 d0             	lea    (%eax,%edx,8),%eax
f0102d50:	50                   	push   %eax
f0102d51:	e8 14 e1 ff ff       	call   f0100e6a <page_decref>
f0102d56:	83 c4 10             	add    $0x10,%esp
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0102d59:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f0102d5d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102d60:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f0102d65:	0f 85 29 ff ff ff    	jne    f0102c94 <env_free+0x69>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f0102d6b:	8b 47 5c             	mov    0x5c(%edi),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102d6e:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102d73:	77 15                	ja     f0102d8a <env_free+0x15f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102d75:	50                   	push   %eax
f0102d76:	68 18 4e 10 f0       	push   $0xf0104e18
f0102d7b:	68 b0 01 00 00       	push   $0x1b0
f0102d80:	68 eb 58 10 f0       	push   $0xf01058eb
f0102d85:	e8 16 d3 ff ff       	call   f01000a0 <_panic>
	e->env_pgdir = 0;
f0102d8a:	c7 47 5c 00 00 00 00 	movl   $0x0,0x5c(%edi)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102d91:	05 00 00 00 10       	add    $0x10000000,%eax
f0102d96:	c1 e8 0c             	shr    $0xc,%eax
f0102d99:	3b 05 44 2c 17 f0    	cmp    0xf0172c44,%eax
f0102d9f:	72 14                	jb     f0102db5 <env_free+0x18a>
		panic("pa2page called with invalid pa");
f0102da1:	83 ec 04             	sub    $0x4,%esp
f0102da4:	68 34 4f 10 f0       	push   $0xf0104f34
f0102da9:	6a 4f                	push   $0x4f
f0102dab:	68 00 56 10 f0       	push   $0xf0105600
f0102db0:	e8 eb d2 ff ff       	call   f01000a0 <_panic>
	page_decref(pa2page(pa));
f0102db5:	83 ec 0c             	sub    $0xc,%esp
f0102db8:	8b 15 4c 2c 17 f0    	mov    0xf0172c4c,%edx
f0102dbe:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f0102dc1:	50                   	push   %eax
f0102dc2:	e8 a3 e0 ff ff       	call   f0100e6a <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f0102dc7:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f0102dce:	a1 8c 1f 17 f0       	mov    0xf0171f8c,%eax
f0102dd3:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f0102dd6:	89 3d 8c 1f 17 f0    	mov    %edi,0xf0171f8c
}
f0102ddc:	83 c4 10             	add    $0x10,%esp
f0102ddf:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102de2:	5b                   	pop    %ebx
f0102de3:	5e                   	pop    %esi
f0102de4:	5f                   	pop    %edi
f0102de5:	5d                   	pop    %ebp
f0102de6:	c3                   	ret    

f0102de7 <env_destroy>:
//
// Frees environment e.
//
void
env_destroy(struct Env *e)
{
f0102de7:	55                   	push   %ebp
f0102de8:	89 e5                	mov    %esp,%ebp
f0102dea:	83 ec 14             	sub    $0x14,%esp
	env_free(e);
f0102ded:	ff 75 08             	pushl  0x8(%ebp)
f0102df0:	e8 36 fe ff ff       	call   f0102c2b <env_free>

	cprintf("Destroyed the only environment - nothing more to do!\n");
f0102df5:	c7 04 24 50 59 10 f0 	movl   $0xf0105950,(%esp)
f0102dfc:	e8 ff 00 00 00       	call   f0102f00 <cprintf>
f0102e01:	83 c4 10             	add    $0x10,%esp
	while (1)
		monitor(NULL);
f0102e04:	83 ec 0c             	sub    $0xc,%esp
f0102e07:	6a 00                	push   $0x0
f0102e09:	e8 94 d9 ff ff       	call   f01007a2 <monitor>
f0102e0e:	83 c4 10             	add    $0x10,%esp
f0102e11:	eb f1                	jmp    f0102e04 <env_destroy+0x1d>

f0102e13 <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f0102e13:	55                   	push   %ebp
f0102e14:	89 e5                	mov    %esp,%ebp
f0102e16:	83 ec 0c             	sub    $0xc,%esp
	asm volatile(
f0102e19:	8b 65 08             	mov    0x8(%ebp),%esp
f0102e1c:	61                   	popa   
f0102e1d:	07                   	pop    %es
f0102e1e:	1f                   	pop    %ds
f0102e1f:	83 c4 08             	add    $0x8,%esp
f0102e22:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret\n"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f0102e23:	68 21 59 10 f0       	push   $0xf0105921
f0102e28:	68 d9 01 00 00       	push   $0x1d9
f0102e2d:	68 eb 58 10 f0       	push   $0xf01058eb
f0102e32:	e8 69 d2 ff ff       	call   f01000a0 <_panic>

f0102e37 <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f0102e37:	55                   	push   %ebp
f0102e38:	89 e5                	mov    %esp,%ebp
f0102e3a:	83 ec 08             	sub    $0x8,%esp
f0102e3d:	8b 45 08             	mov    0x8(%ebp),%eax
	//	e->env_tf.  Go back through the code you wrote above
	//	and make sure you have set the relevant parts of
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.
	if(curenv != NULL){
f0102e40:	8b 15 84 1f 17 f0    	mov    0xf0171f84,%edx
f0102e46:	85 d2                	test   %edx,%edx
f0102e48:	74 0d                	je     f0102e57 <env_run+0x20>
		if(curenv->env_status == ENV_RUNNING)
f0102e4a:	83 7a 54 03          	cmpl   $0x3,0x54(%edx)
f0102e4e:	75 07                	jne    f0102e57 <env_run+0x20>
			curenv->env_status = ENV_RUNNABLE;
f0102e50:	c7 42 54 02 00 00 00 	movl   $0x2,0x54(%edx)
	}
	curenv = e;
f0102e57:	a3 84 1f 17 f0       	mov    %eax,0xf0171f84
	curenv->env_status = ENV_RUNNING;
f0102e5c:	c7 40 54 03 00 00 00 	movl   $0x3,0x54(%eax)
	curenv->env_runs ++;
f0102e63:	83 40 58 01          	addl   $0x1,0x58(%eax)
	lcr3(PADDR(e->env_pgdir));
f0102e67:	8b 50 5c             	mov    0x5c(%eax),%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102e6a:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0102e70:	77 15                	ja     f0102e87 <env_run+0x50>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102e72:	52                   	push   %edx
f0102e73:	68 18 4e 10 f0       	push   $0xf0104e18
f0102e78:	68 fe 01 00 00       	push   $0x1fe
f0102e7d:	68 eb 58 10 f0       	push   $0xf01058eb
f0102e82:	e8 19 d2 ff ff       	call   f01000a0 <_panic>
f0102e87:	81 c2 00 00 00 10    	add    $0x10000000,%edx
f0102e8d:	0f 22 da             	mov    %edx,%cr3
	env_pop_tf(&e->env_tf);
f0102e90:	83 ec 0c             	sub    $0xc,%esp
f0102e93:	50                   	push   %eax
f0102e94:	e8 7a ff ff ff       	call   f0102e13 <env_pop_tf>

f0102e99 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102e99:	55                   	push   %ebp
f0102e9a:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102e9c:	ba 70 00 00 00       	mov    $0x70,%edx
f0102ea1:	8b 45 08             	mov    0x8(%ebp),%eax
f0102ea4:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102ea5:	ba 71 00 00 00       	mov    $0x71,%edx
f0102eaa:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0102eab:	0f b6 c0             	movzbl %al,%eax
}
f0102eae:	5d                   	pop    %ebp
f0102eaf:	c3                   	ret    

f0102eb0 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102eb0:	55                   	push   %ebp
f0102eb1:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102eb3:	ba 70 00 00 00       	mov    $0x70,%edx
f0102eb8:	8b 45 08             	mov    0x8(%ebp),%eax
f0102ebb:	ee                   	out    %al,(%dx)
f0102ebc:	ba 71 00 00 00       	mov    $0x71,%edx
f0102ec1:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102ec4:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0102ec5:	5d                   	pop    %ebp
f0102ec6:	c3                   	ret    

f0102ec7 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0102ec7:	55                   	push   %ebp
f0102ec8:	89 e5                	mov    %esp,%ebp
f0102eca:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0102ecd:	ff 75 08             	pushl  0x8(%ebp)
f0102ed0:	e8 40 d7 ff ff       	call   f0100615 <cputchar>
	*cnt++;
}
f0102ed5:	83 c4 10             	add    $0x10,%esp
f0102ed8:	c9                   	leave  
f0102ed9:	c3                   	ret    

f0102eda <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0102eda:	55                   	push   %ebp
f0102edb:	89 e5                	mov    %esp,%ebp
f0102edd:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0102ee0:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0102ee7:	ff 75 0c             	pushl  0xc(%ebp)
f0102eea:	ff 75 08             	pushl  0x8(%ebp)
f0102eed:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102ef0:	50                   	push   %eax
f0102ef1:	68 c7 2e 10 f0       	push   $0xf0102ec7
f0102ef6:	e8 f2 0e 00 00       	call   f0103ded <vprintfmt>
	return cnt;
}
f0102efb:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102efe:	c9                   	leave  
f0102eff:	c3                   	ret    

f0102f00 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0102f00:	55                   	push   %ebp
f0102f01:	89 e5                	mov    %esp,%ebp
f0102f03:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0102f06:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102f09:	50                   	push   %eax
f0102f0a:	ff 75 08             	pushl  0x8(%ebp)
f0102f0d:	e8 c8 ff ff ff       	call   f0102eda <vcprintf>
	va_end(ap);

	return cnt;
}
f0102f12:	c9                   	leave  
f0102f13:	c3                   	ret    

f0102f14 <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f0102f14:	55                   	push   %ebp
f0102f15:	89 e5                	mov    %esp,%ebp
	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	ts.ts_esp0 = KSTACKTOP;
f0102f17:	b8 c0 27 17 f0       	mov    $0xf01727c0,%eax
f0102f1c:	c7 05 c4 27 17 f0 00 	movl   $0xf0000000,0xf01727c4
f0102f23:	00 00 f0 
	ts.ts_ss0 = GD_KD;
f0102f26:	66 c7 05 c8 27 17 f0 	movw   $0x10,0xf01727c8
f0102f2d:	10 00 

	// Initialize the TSS slot of the gdt.
	gdt[GD_TSS0 >> 3] = SEG16(STS_T32A, (uint32_t) (&ts),
f0102f2f:	66 c7 05 48 b3 11 f0 	movw   $0x67,0xf011b348
f0102f36:	67 00 
f0102f38:	66 a3 4a b3 11 f0    	mov    %ax,0xf011b34a
f0102f3e:	89 c2                	mov    %eax,%edx
f0102f40:	c1 ea 10             	shr    $0x10,%edx
f0102f43:	88 15 4c b3 11 f0    	mov    %dl,0xf011b34c
f0102f49:	c6 05 4e b3 11 f0 40 	movb   $0x40,0xf011b34e
f0102f50:	c1 e8 18             	shr    $0x18,%eax
f0102f53:	a2 4f b3 11 f0       	mov    %al,0xf011b34f
					sizeof(struct Taskstate) - 1, 0);
	gdt[GD_TSS0 >> 3].sd_s = 0;
f0102f58:	c6 05 4d b3 11 f0 89 	movb   $0x89,0xf011b34d
}

static inline void
ltr(uint16_t sel)
{
	asm volatile("ltr %0" : : "r" (sel));
f0102f5f:	b8 28 00 00 00       	mov    $0x28,%eax
f0102f64:	0f 00 d8             	ltr    %ax
}

static inline void
lidt(void *p)
{
	asm volatile("lidt (%0)" : : "r" (p));
f0102f67:	b8 50 b3 11 f0       	mov    $0xf011b350,%eax
f0102f6c:	0f 01 18             	lidtl  (%eax)
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0);

	// Load the IDT
	lidt(&idt_pd);
}
f0102f6f:	5d                   	pop    %ebp
f0102f70:	c3                   	ret    

f0102f71 <trap_init>:
}


void
trap_init(void)
{
f0102f71:	55                   	push   %ebp
f0102f72:	89 e5                	mov    %esp,%ebp
	extern struct Segdesc gdt[];

	// LAB 3: Your code here.

	SETGATE(idt[T_DIVIDE], 0, GD_KT, t_divide, 0);
f0102f74:	b8 62 37 10 f0       	mov    $0xf0103762,%eax
f0102f79:	66 a3 a0 1f 17 f0    	mov    %ax,0xf0171fa0
f0102f7f:	66 c7 05 a2 1f 17 f0 	movw   $0x8,0xf0171fa2
f0102f86:	08 00 
f0102f88:	c6 05 a4 1f 17 f0 00 	movb   $0x0,0xf0171fa4
f0102f8f:	c6 05 a5 1f 17 f0 8e 	movb   $0x8e,0xf0171fa5
f0102f96:	c1 e8 10             	shr    $0x10,%eax
f0102f99:	66 a3 a6 1f 17 f0    	mov    %ax,0xf0171fa6
	SETGATE(idt[T_DEBUG], 0, GD_KT, t_debug, 0);
f0102f9f:	b8 6c 37 10 f0       	mov    $0xf010376c,%eax
f0102fa4:	66 a3 a8 1f 17 f0    	mov    %ax,0xf0171fa8
f0102faa:	66 c7 05 aa 1f 17 f0 	movw   $0x8,0xf0171faa
f0102fb1:	08 00 
f0102fb3:	c6 05 ac 1f 17 f0 00 	movb   $0x0,0xf0171fac
f0102fba:	c6 05 ad 1f 17 f0 8e 	movb   $0x8e,0xf0171fad
f0102fc1:	c1 e8 10             	shr    $0x10,%eax
f0102fc4:	66 a3 ae 1f 17 f0    	mov    %ax,0xf0171fae
	SETGATE(idt[T_NMI], 0, GD_KT, t_nmi, 0);
f0102fca:	b8 72 37 10 f0       	mov    $0xf0103772,%eax
f0102fcf:	66 a3 b0 1f 17 f0    	mov    %ax,0xf0171fb0
f0102fd5:	66 c7 05 b2 1f 17 f0 	movw   $0x8,0xf0171fb2
f0102fdc:	08 00 
f0102fde:	c6 05 b4 1f 17 f0 00 	movb   $0x0,0xf0171fb4
f0102fe5:	c6 05 b5 1f 17 f0 8e 	movb   $0x8e,0xf0171fb5
f0102fec:	c1 e8 10             	shr    $0x10,%eax
f0102fef:	66 a3 b6 1f 17 f0    	mov    %ax,0xf0171fb6
	SETGATE(idt[T_BRKPT], 0, GD_KT, t_brkpt, 3);
f0102ff5:	b8 78 37 10 f0       	mov    $0xf0103778,%eax
f0102ffa:	66 a3 b8 1f 17 f0    	mov    %ax,0xf0171fb8
f0103000:	66 c7 05 ba 1f 17 f0 	movw   $0x8,0xf0171fba
f0103007:	08 00 
f0103009:	c6 05 bc 1f 17 f0 00 	movb   $0x0,0xf0171fbc
f0103010:	c6 05 bd 1f 17 f0 ee 	movb   $0xee,0xf0171fbd
f0103017:	c1 e8 10             	shr    $0x10,%eax
f010301a:	66 a3 be 1f 17 f0    	mov    %ax,0xf0171fbe
	SETGATE(idt[T_OFLOW], 0, GD_KT, t_oflow, 0);
f0103020:	b8 7e 37 10 f0       	mov    $0xf010377e,%eax
f0103025:	66 a3 c0 1f 17 f0    	mov    %ax,0xf0171fc0
f010302b:	66 c7 05 c2 1f 17 f0 	movw   $0x8,0xf0171fc2
f0103032:	08 00 
f0103034:	c6 05 c4 1f 17 f0 00 	movb   $0x0,0xf0171fc4
f010303b:	c6 05 c5 1f 17 f0 8e 	movb   $0x8e,0xf0171fc5
f0103042:	c1 e8 10             	shr    $0x10,%eax
f0103045:	66 a3 c6 1f 17 f0    	mov    %ax,0xf0171fc6
	SETGATE(idt[T_BOUND], 0, GD_KT, t_bound, 0);
f010304b:	b8 84 37 10 f0       	mov    $0xf0103784,%eax
f0103050:	66 a3 c8 1f 17 f0    	mov    %ax,0xf0171fc8
f0103056:	66 c7 05 ca 1f 17 f0 	movw   $0x8,0xf0171fca
f010305d:	08 00 
f010305f:	c6 05 cc 1f 17 f0 00 	movb   $0x0,0xf0171fcc
f0103066:	c6 05 cd 1f 17 f0 8e 	movb   $0x8e,0xf0171fcd
f010306d:	c1 e8 10             	shr    $0x10,%eax
f0103070:	66 a3 ce 1f 17 f0    	mov    %ax,0xf0171fce
	SETGATE(idt[T_ILLOP], 0, GD_KT, t_illop, 0);
f0103076:	b8 8a 37 10 f0       	mov    $0xf010378a,%eax
f010307b:	66 a3 d0 1f 17 f0    	mov    %ax,0xf0171fd0
f0103081:	66 c7 05 d2 1f 17 f0 	movw   $0x8,0xf0171fd2
f0103088:	08 00 
f010308a:	c6 05 d4 1f 17 f0 00 	movb   $0x0,0xf0171fd4
f0103091:	c6 05 d5 1f 17 f0 8e 	movb   $0x8e,0xf0171fd5
f0103098:	c1 e8 10             	shr    $0x10,%eax
f010309b:	66 a3 d6 1f 17 f0    	mov    %ax,0xf0171fd6
	SETGATE(idt[T_DEVICE], 0, GD_KT, t_device, 0);
f01030a1:	b8 90 37 10 f0       	mov    $0xf0103790,%eax
f01030a6:	66 a3 d8 1f 17 f0    	mov    %ax,0xf0171fd8
f01030ac:	66 c7 05 da 1f 17 f0 	movw   $0x8,0xf0171fda
f01030b3:	08 00 
f01030b5:	c6 05 dc 1f 17 f0 00 	movb   $0x0,0xf0171fdc
f01030bc:	c6 05 dd 1f 17 f0 8e 	movb   $0x8e,0xf0171fdd
f01030c3:	c1 e8 10             	shr    $0x10,%eax
f01030c6:	66 a3 de 1f 17 f0    	mov    %ax,0xf0171fde
	SETGATE(idt[T_DBLFLT], 0, GD_KT, t_dblflt, 0);
f01030cc:	b8 96 37 10 f0       	mov    $0xf0103796,%eax
f01030d1:	66 a3 e0 1f 17 f0    	mov    %ax,0xf0171fe0
f01030d7:	66 c7 05 e2 1f 17 f0 	movw   $0x8,0xf0171fe2
f01030de:	08 00 
f01030e0:	c6 05 e4 1f 17 f0 00 	movb   $0x0,0xf0171fe4
f01030e7:	c6 05 e5 1f 17 f0 8e 	movb   $0x8e,0xf0171fe5
f01030ee:	c1 e8 10             	shr    $0x10,%eax
f01030f1:	66 a3 e6 1f 17 f0    	mov    %ax,0xf0171fe6
	SETGATE(idt[T_TSS], 0, GD_KT, t_tss, 0);
f01030f7:	b8 9a 37 10 f0       	mov    $0xf010379a,%eax
f01030fc:	66 a3 f0 1f 17 f0    	mov    %ax,0xf0171ff0
f0103102:	66 c7 05 f2 1f 17 f0 	movw   $0x8,0xf0171ff2
f0103109:	08 00 
f010310b:	c6 05 f4 1f 17 f0 00 	movb   $0x0,0xf0171ff4
f0103112:	c6 05 f5 1f 17 f0 8e 	movb   $0x8e,0xf0171ff5
f0103119:	c1 e8 10             	shr    $0x10,%eax
f010311c:	66 a3 f6 1f 17 f0    	mov    %ax,0xf0171ff6
	SETGATE(idt[T_SEGNP], 0, GD_KT, t_segnp, 0);
f0103122:	b8 9e 37 10 f0       	mov    $0xf010379e,%eax
f0103127:	66 a3 f8 1f 17 f0    	mov    %ax,0xf0171ff8
f010312d:	66 c7 05 fa 1f 17 f0 	movw   $0x8,0xf0171ffa
f0103134:	08 00 
f0103136:	c6 05 fc 1f 17 f0 00 	movb   $0x0,0xf0171ffc
f010313d:	c6 05 fd 1f 17 f0 8e 	movb   $0x8e,0xf0171ffd
f0103144:	c1 e8 10             	shr    $0x10,%eax
f0103147:	66 a3 fe 1f 17 f0    	mov    %ax,0xf0171ffe
	SETGATE(idt[T_STACK], 0, GD_KT, t_stack, 0);
f010314d:	b8 a2 37 10 f0       	mov    $0xf01037a2,%eax
f0103152:	66 a3 00 20 17 f0    	mov    %ax,0xf0172000
f0103158:	66 c7 05 02 20 17 f0 	movw   $0x8,0xf0172002
f010315f:	08 00 
f0103161:	c6 05 04 20 17 f0 00 	movb   $0x0,0xf0172004
f0103168:	c6 05 05 20 17 f0 8e 	movb   $0x8e,0xf0172005
f010316f:	c1 e8 10             	shr    $0x10,%eax
f0103172:	66 a3 06 20 17 f0    	mov    %ax,0xf0172006
	SETGATE(idt[T_GPFLT], 0, GD_KT, t_gpflt, 0);
f0103178:	b8 a6 37 10 f0       	mov    $0xf01037a6,%eax
f010317d:	66 a3 08 20 17 f0    	mov    %ax,0xf0172008
f0103183:	66 c7 05 0a 20 17 f0 	movw   $0x8,0xf017200a
f010318a:	08 00 
f010318c:	c6 05 0c 20 17 f0 00 	movb   $0x0,0xf017200c
f0103193:	c6 05 0d 20 17 f0 8e 	movb   $0x8e,0xf017200d
f010319a:	c1 e8 10             	shr    $0x10,%eax
f010319d:	66 a3 0e 20 17 f0    	mov    %ax,0xf017200e
	SETGATE(idt[T_PGFLT], 0, GD_KT, t_pgflt, 0);
f01031a3:	b8 aa 37 10 f0       	mov    $0xf01037aa,%eax
f01031a8:	66 a3 10 20 17 f0    	mov    %ax,0xf0172010
f01031ae:	66 c7 05 12 20 17 f0 	movw   $0x8,0xf0172012
f01031b5:	08 00 
f01031b7:	c6 05 14 20 17 f0 00 	movb   $0x0,0xf0172014
f01031be:	c6 05 15 20 17 f0 8e 	movb   $0x8e,0xf0172015
f01031c5:	c1 e8 10             	shr    $0x10,%eax
f01031c8:	66 a3 16 20 17 f0    	mov    %ax,0xf0172016
	SETGATE(idt[T_FPERR], 0, GD_KT, t_fperr, 0);
f01031ce:	b8 ae 37 10 f0       	mov    $0xf01037ae,%eax
f01031d3:	66 a3 20 20 17 f0    	mov    %ax,0xf0172020
f01031d9:	66 c7 05 22 20 17 f0 	movw   $0x8,0xf0172022
f01031e0:	08 00 
f01031e2:	c6 05 24 20 17 f0 00 	movb   $0x0,0xf0172024
f01031e9:	c6 05 25 20 17 f0 8e 	movb   $0x8e,0xf0172025
f01031f0:	c1 e8 10             	shr    $0x10,%eax
f01031f3:	66 a3 26 20 17 f0    	mov    %ax,0xf0172026
	SETGATE(idt[T_ALIGN], 0, GD_KT, t_align, 0);
f01031f9:	b8 b4 37 10 f0       	mov    $0xf01037b4,%eax
f01031fe:	66 a3 28 20 17 f0    	mov    %ax,0xf0172028
f0103204:	66 c7 05 2a 20 17 f0 	movw   $0x8,0xf017202a
f010320b:	08 00 
f010320d:	c6 05 2c 20 17 f0 00 	movb   $0x0,0xf017202c
f0103214:	c6 05 2d 20 17 f0 8e 	movb   $0x8e,0xf017202d
f010321b:	c1 e8 10             	shr    $0x10,%eax
f010321e:	66 a3 2e 20 17 f0    	mov    %ax,0xf017202e
	SETGATE(idt[T_MCHK], 0, GD_KT, t_mchk, 0);
f0103224:	b8 b8 37 10 f0       	mov    $0xf01037b8,%eax
f0103229:	66 a3 30 20 17 f0    	mov    %ax,0xf0172030
f010322f:	66 c7 05 32 20 17 f0 	movw   $0x8,0xf0172032
f0103236:	08 00 
f0103238:	c6 05 34 20 17 f0 00 	movb   $0x0,0xf0172034
f010323f:	c6 05 35 20 17 f0 8e 	movb   $0x8e,0xf0172035
f0103246:	c1 e8 10             	shr    $0x10,%eax
f0103249:	66 a3 36 20 17 f0    	mov    %ax,0xf0172036
	SETGATE(idt[T_SIMDERR], 0, GD_KT, t_simderr, 0);
f010324f:	b8 be 37 10 f0       	mov    $0xf01037be,%eax
f0103254:	66 a3 38 20 17 f0    	mov    %ax,0xf0172038
f010325a:	66 c7 05 3a 20 17 f0 	movw   $0x8,0xf017203a
f0103261:	08 00 
f0103263:	c6 05 3c 20 17 f0 00 	movb   $0x0,0xf017203c
f010326a:	c6 05 3d 20 17 f0 8e 	movb   $0x8e,0xf017203d
f0103271:	c1 e8 10             	shr    $0x10,%eax
f0103274:	66 a3 3e 20 17 f0    	mov    %ax,0xf017203e

	SETGATE(idt[T_SYSCALL], 0, GD_KT, t_syscall, 3);
f010327a:	b8 c4 37 10 f0       	mov    $0xf01037c4,%eax
f010327f:	66 a3 20 21 17 f0    	mov    %ax,0xf0172120
f0103285:	66 c7 05 22 21 17 f0 	movw   $0x8,0xf0172122
f010328c:	08 00 
f010328e:	c6 05 24 21 17 f0 00 	movb   $0x0,0xf0172124
f0103295:	c6 05 25 21 17 f0 ee 	movb   $0xee,0xf0172125
f010329c:	c1 e8 10             	shr    $0x10,%eax
f010329f:	66 a3 26 21 17 f0    	mov    %ax,0xf0172126

	SETGATE(idt[IRQ_OFFSET + IRQ_TIMER], 0, GD_KT, irq_timer, 0);
f01032a5:	b8 ca 37 10 f0       	mov    $0xf01037ca,%eax
f01032aa:	66 a3 a0 20 17 f0    	mov    %ax,0xf01720a0
f01032b0:	66 c7 05 a2 20 17 f0 	movw   $0x8,0xf01720a2
f01032b7:	08 00 
f01032b9:	c6 05 a4 20 17 f0 00 	movb   $0x0,0xf01720a4
f01032c0:	c6 05 a5 20 17 f0 8e 	movb   $0x8e,0xf01720a5
f01032c7:	c1 e8 10             	shr    $0x10,%eax
f01032ca:	66 a3 a6 20 17 f0    	mov    %ax,0xf01720a6
	SETGATE(idt[IRQ_OFFSET + IRQ_KBD], 0, GD_KT, irq_kbd, 0);
f01032d0:	b8 d0 37 10 f0       	mov    $0xf01037d0,%eax
f01032d5:	66 a3 a8 20 17 f0    	mov    %ax,0xf01720a8
f01032db:	66 c7 05 aa 20 17 f0 	movw   $0x8,0xf01720aa
f01032e2:	08 00 
f01032e4:	c6 05 ac 20 17 f0 00 	movb   $0x0,0xf01720ac
f01032eb:	c6 05 ad 20 17 f0 8e 	movb   $0x8e,0xf01720ad
f01032f2:	c1 e8 10             	shr    $0x10,%eax
f01032f5:	66 a3 ae 20 17 f0    	mov    %ax,0xf01720ae
	SETGATE(idt[IRQ_OFFSET + IRQ_SERIAL], 0, GD_KT, irq_serial, 0);
f01032fb:	b8 d6 37 10 f0       	mov    $0xf01037d6,%eax
f0103300:	66 a3 c0 20 17 f0    	mov    %ax,0xf01720c0
f0103306:	66 c7 05 c2 20 17 f0 	movw   $0x8,0xf01720c2
f010330d:	08 00 
f010330f:	c6 05 c4 20 17 f0 00 	movb   $0x0,0xf01720c4
f0103316:	c6 05 c5 20 17 f0 8e 	movb   $0x8e,0xf01720c5
f010331d:	c1 e8 10             	shr    $0x10,%eax
f0103320:	66 a3 c6 20 17 f0    	mov    %ax,0xf01720c6
	SETGATE(idt[IRQ_OFFSET + IRQ_SPURIOUS], 0, GD_KT, irq_spurious, 0);
f0103326:	b8 dc 37 10 f0       	mov    $0xf01037dc,%eax
f010332b:	66 a3 d8 20 17 f0    	mov    %ax,0xf01720d8
f0103331:	66 c7 05 da 20 17 f0 	movw   $0x8,0xf01720da
f0103338:	08 00 
f010333a:	c6 05 dc 20 17 f0 00 	movb   $0x0,0xf01720dc
f0103341:	c6 05 dd 20 17 f0 8e 	movb   $0x8e,0xf01720dd
f0103348:	c1 e8 10             	shr    $0x10,%eax
f010334b:	66 a3 de 20 17 f0    	mov    %ax,0xf01720de
	SETGATE(idt[IRQ_OFFSET + IRQ_IDE], 0, GD_KT, irq_ide, 0);
f0103351:	b8 e2 37 10 f0       	mov    $0xf01037e2,%eax
f0103356:	66 a3 10 21 17 f0    	mov    %ax,0xf0172110
f010335c:	66 c7 05 12 21 17 f0 	movw   $0x8,0xf0172112
f0103363:	08 00 
f0103365:	c6 05 14 21 17 f0 00 	movb   $0x0,0xf0172114
f010336c:	c6 05 15 21 17 f0 8e 	movb   $0x8e,0xf0172115
f0103373:	c1 e8 10             	shr    $0x10,%eax
f0103376:	66 a3 16 21 17 f0    	mov    %ax,0xf0172116
	SETGATE(idt[IRQ_OFFSET + IRQ_ERROR], 0, GD_KT, irq_error, 0);
f010337c:	b8 e8 37 10 f0       	mov    $0xf01037e8,%eax
f0103381:	66 a3 38 21 17 f0    	mov    %ax,0xf0172138
f0103387:	66 c7 05 3a 21 17 f0 	movw   $0x8,0xf017213a
f010338e:	08 00 
f0103390:	c6 05 3c 21 17 f0 00 	movb   $0x0,0xf017213c
f0103397:	c6 05 3d 21 17 f0 8e 	movb   $0x8e,0xf017213d
f010339e:	c1 e8 10             	shr    $0x10,%eax
f01033a1:	66 a3 3e 21 17 f0    	mov    %ax,0xf017213e
	// Per-CPU setup 
	trap_init_percpu();
f01033a7:	e8 68 fb ff ff       	call   f0102f14 <trap_init_percpu>
}
f01033ac:	5d                   	pop    %ebp
f01033ad:	c3                   	ret    

f01033ae <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f01033ae:	55                   	push   %ebp
f01033af:	89 e5                	mov    %esp,%ebp
f01033b1:	53                   	push   %ebx
f01033b2:	83 ec 0c             	sub    $0xc,%esp
f01033b5:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f01033b8:	ff 33                	pushl  (%ebx)
f01033ba:	68 86 59 10 f0       	push   $0xf0105986
f01033bf:	e8 3c fb ff ff       	call   f0102f00 <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f01033c4:	83 c4 08             	add    $0x8,%esp
f01033c7:	ff 73 04             	pushl  0x4(%ebx)
f01033ca:	68 95 59 10 f0       	push   $0xf0105995
f01033cf:	e8 2c fb ff ff       	call   f0102f00 <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f01033d4:	83 c4 08             	add    $0x8,%esp
f01033d7:	ff 73 08             	pushl  0x8(%ebx)
f01033da:	68 a4 59 10 f0       	push   $0xf01059a4
f01033df:	e8 1c fb ff ff       	call   f0102f00 <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f01033e4:	83 c4 08             	add    $0x8,%esp
f01033e7:	ff 73 0c             	pushl  0xc(%ebx)
f01033ea:	68 b3 59 10 f0       	push   $0xf01059b3
f01033ef:	e8 0c fb ff ff       	call   f0102f00 <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f01033f4:	83 c4 08             	add    $0x8,%esp
f01033f7:	ff 73 10             	pushl  0x10(%ebx)
f01033fa:	68 c2 59 10 f0       	push   $0xf01059c2
f01033ff:	e8 fc fa ff ff       	call   f0102f00 <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f0103404:	83 c4 08             	add    $0x8,%esp
f0103407:	ff 73 14             	pushl  0x14(%ebx)
f010340a:	68 d1 59 10 f0       	push   $0xf01059d1
f010340f:	e8 ec fa ff ff       	call   f0102f00 <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f0103414:	83 c4 08             	add    $0x8,%esp
f0103417:	ff 73 18             	pushl  0x18(%ebx)
f010341a:	68 e0 59 10 f0       	push   $0xf01059e0
f010341f:	e8 dc fa ff ff       	call   f0102f00 <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f0103424:	83 c4 08             	add    $0x8,%esp
f0103427:	ff 73 1c             	pushl  0x1c(%ebx)
f010342a:	68 ef 59 10 f0       	push   $0xf01059ef
f010342f:	e8 cc fa ff ff       	call   f0102f00 <cprintf>
}
f0103434:	83 c4 10             	add    $0x10,%esp
f0103437:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010343a:	c9                   	leave  
f010343b:	c3                   	ret    

f010343c <print_trapframe>:
	lidt(&idt_pd);
}

void
print_trapframe(struct Trapframe *tf)
{
f010343c:	55                   	push   %ebp
f010343d:	89 e5                	mov    %esp,%ebp
f010343f:	56                   	push   %esi
f0103440:	53                   	push   %ebx
f0103441:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p\n", tf);
f0103444:	83 ec 08             	sub    $0x8,%esp
f0103447:	53                   	push   %ebx
f0103448:	68 25 5b 10 f0       	push   $0xf0105b25
f010344d:	e8 ae fa ff ff       	call   f0102f00 <cprintf>
	print_regs(&tf->tf_regs);
f0103452:	89 1c 24             	mov    %ebx,(%esp)
f0103455:	e8 54 ff ff ff       	call   f01033ae <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f010345a:	83 c4 08             	add    $0x8,%esp
f010345d:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f0103461:	50                   	push   %eax
f0103462:	68 40 5a 10 f0       	push   $0xf0105a40
f0103467:	e8 94 fa ff ff       	call   f0102f00 <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f010346c:	83 c4 08             	add    $0x8,%esp
f010346f:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f0103473:	50                   	push   %eax
f0103474:	68 53 5a 10 f0       	push   $0xf0105a53
f0103479:	e8 82 fa ff ff       	call   f0102f00 <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f010347e:	8b 43 28             	mov    0x28(%ebx),%eax
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < ARRAY_SIZE(excnames))
f0103481:	83 c4 10             	add    $0x10,%esp
f0103484:	83 f8 13             	cmp    $0x13,%eax
f0103487:	77 09                	ja     f0103492 <print_trapframe+0x56>
		return excnames[trapno];
f0103489:	8b 14 85 40 5d 10 f0 	mov    -0xfefa2c0(,%eax,4),%edx
f0103490:	eb 10                	jmp    f01034a2 <print_trapframe+0x66>
	if (trapno == T_SYSCALL)
		return "System call";
	return "(unknown trap)";
f0103492:	83 f8 30             	cmp    $0x30,%eax
f0103495:	b9 0a 5a 10 f0       	mov    $0xf0105a0a,%ecx
f010349a:	ba fe 59 10 f0       	mov    $0xf01059fe,%edx
f010349f:	0f 45 d1             	cmovne %ecx,%edx
{
	cprintf("TRAP frame at %p\n", tf);
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f01034a2:	83 ec 04             	sub    $0x4,%esp
f01034a5:	52                   	push   %edx
f01034a6:	50                   	push   %eax
f01034a7:	68 66 5a 10 f0       	push   $0xf0105a66
f01034ac:	e8 4f fa ff ff       	call   f0102f00 <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f01034b1:	83 c4 10             	add    $0x10,%esp
f01034b4:	3b 1d a0 27 17 f0    	cmp    0xf01727a0,%ebx
f01034ba:	75 1a                	jne    f01034d6 <print_trapframe+0x9a>
f01034bc:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f01034c0:	75 14                	jne    f01034d6 <print_trapframe+0x9a>

static inline uint32_t
rcr2(void)
{
	uint32_t val;
	asm volatile("movl %%cr2,%0" : "=r" (val));
f01034c2:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f01034c5:	83 ec 08             	sub    $0x8,%esp
f01034c8:	50                   	push   %eax
f01034c9:	68 78 5a 10 f0       	push   $0xf0105a78
f01034ce:	e8 2d fa ff ff       	call   f0102f00 <cprintf>
f01034d3:	83 c4 10             	add    $0x10,%esp
	cprintf("  err  0x%08x", tf->tf_err);
f01034d6:	83 ec 08             	sub    $0x8,%esp
f01034d9:	ff 73 2c             	pushl  0x2c(%ebx)
f01034dc:	68 87 5a 10 f0       	push   $0xf0105a87
f01034e1:	e8 1a fa ff ff       	call   f0102f00 <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f01034e6:	83 c4 10             	add    $0x10,%esp
f01034e9:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f01034ed:	75 49                	jne    f0103538 <print_trapframe+0xfc>
		cprintf(" [%s, %s, %s]\n",
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
f01034ef:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f01034f2:	89 c2                	mov    %eax,%edx
f01034f4:	83 e2 01             	and    $0x1,%edx
f01034f7:	ba 24 5a 10 f0       	mov    $0xf0105a24,%edx
f01034fc:	b9 19 5a 10 f0       	mov    $0xf0105a19,%ecx
f0103501:	0f 44 ca             	cmove  %edx,%ecx
f0103504:	89 c2                	mov    %eax,%edx
f0103506:	83 e2 02             	and    $0x2,%edx
f0103509:	ba 36 5a 10 f0       	mov    $0xf0105a36,%edx
f010350e:	be 30 5a 10 f0       	mov    $0xf0105a30,%esi
f0103513:	0f 45 d6             	cmovne %esi,%edx
f0103516:	83 e0 04             	and    $0x4,%eax
f0103519:	be 62 5b 10 f0       	mov    $0xf0105b62,%esi
f010351e:	b8 3b 5a 10 f0       	mov    $0xf0105a3b,%eax
f0103523:	0f 44 c6             	cmove  %esi,%eax
f0103526:	51                   	push   %ecx
f0103527:	52                   	push   %edx
f0103528:	50                   	push   %eax
f0103529:	68 95 5a 10 f0       	push   $0xf0105a95
f010352e:	e8 cd f9 ff ff       	call   f0102f00 <cprintf>
f0103533:	83 c4 10             	add    $0x10,%esp
f0103536:	eb 10                	jmp    f0103548 <print_trapframe+0x10c>
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f0103538:	83 ec 0c             	sub    $0xc,%esp
f010353b:	68 a5 58 10 f0       	push   $0xf01058a5
f0103540:	e8 bb f9 ff ff       	call   f0102f00 <cprintf>
f0103545:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f0103548:	83 ec 08             	sub    $0x8,%esp
f010354b:	ff 73 30             	pushl  0x30(%ebx)
f010354e:	68 a4 5a 10 f0       	push   $0xf0105aa4
f0103553:	e8 a8 f9 ff ff       	call   f0102f00 <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f0103558:	83 c4 08             	add    $0x8,%esp
f010355b:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f010355f:	50                   	push   %eax
f0103560:	68 b3 5a 10 f0       	push   $0xf0105ab3
f0103565:	e8 96 f9 ff ff       	call   f0102f00 <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f010356a:	83 c4 08             	add    $0x8,%esp
f010356d:	ff 73 38             	pushl  0x38(%ebx)
f0103570:	68 c6 5a 10 f0       	push   $0xf0105ac6
f0103575:	e8 86 f9 ff ff       	call   f0102f00 <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f010357a:	83 c4 10             	add    $0x10,%esp
f010357d:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0103581:	74 25                	je     f01035a8 <print_trapframe+0x16c>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f0103583:	83 ec 08             	sub    $0x8,%esp
f0103586:	ff 73 3c             	pushl  0x3c(%ebx)
f0103589:	68 d5 5a 10 f0       	push   $0xf0105ad5
f010358e:	e8 6d f9 ff ff       	call   f0102f00 <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f0103593:	83 c4 08             	add    $0x8,%esp
f0103596:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f010359a:	50                   	push   %eax
f010359b:	68 e4 5a 10 f0       	push   $0xf0105ae4
f01035a0:	e8 5b f9 ff ff       	call   f0102f00 <cprintf>
f01035a5:	83 c4 10             	add    $0x10,%esp
	}
}
f01035a8:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01035ab:	5b                   	pop    %ebx
f01035ac:	5e                   	pop    %esi
f01035ad:	5d                   	pop    %ebp
f01035ae:	c3                   	ret    

f01035af <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f01035af:	55                   	push   %ebp
f01035b0:	89 e5                	mov    %esp,%ebp
f01035b2:	53                   	push   %ebx
f01035b3:	83 ec 04             	sub    $0x4,%esp
f01035b6:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01035b9:	0f 20 d0             	mov    %cr2,%eax
	fault_va = rcr2();

	// Handle kernel-mode page faults.

	// LAB 3: Your code here.
	if (tf->tf_cs == GD_KT) {
f01035bc:	66 83 7b 34 08       	cmpw   $0x8,0x34(%ebx)
f01035c1:	75 17                	jne    f01035da <page_fault_handler+0x2b>
		// Trapped from kernel mode
		panic("page_fault_handler: page fault in kernel mode");
f01035c3:	83 ec 04             	sub    $0x4,%esp
f01035c6:	68 ac 5c 10 f0       	push   $0xf0105cac
f01035cb:	68 22 01 00 00       	push   $0x122
f01035d0:	68 f7 5a 10 f0       	push   $0xf0105af7
f01035d5:	e8 c6 ca ff ff       	call   f01000a0 <_panic>
	}
	// We've already handled kernel-mode exceptions, so if we get here,
	// the page fault happened in user mode.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f01035da:	ff 73 30             	pushl  0x30(%ebx)
f01035dd:	50                   	push   %eax
f01035de:	a1 84 1f 17 f0       	mov    0xf0171f84,%eax
f01035e3:	ff 70 48             	pushl  0x48(%eax)
f01035e6:	68 dc 5c 10 f0       	push   $0xf0105cdc
f01035eb:	e8 10 f9 ff ff       	call   f0102f00 <cprintf>
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f01035f0:	89 1c 24             	mov    %ebx,(%esp)
f01035f3:	e8 44 fe ff ff       	call   f010343c <print_trapframe>
	env_destroy(curenv);
f01035f8:	83 c4 04             	add    $0x4,%esp
f01035fb:	ff 35 84 1f 17 f0    	pushl  0xf0171f84
f0103601:	e8 e1 f7 ff ff       	call   f0102de7 <env_destroy>
}
f0103606:	83 c4 10             	add    $0x10,%esp
f0103609:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010360c:	c9                   	leave  
f010360d:	c3                   	ret    

f010360e <trap>:
	}
}

void
trap(struct Trapframe *tf)
{
f010360e:	55                   	push   %ebp
f010360f:	89 e5                	mov    %esp,%ebp
f0103611:	57                   	push   %edi
f0103612:	56                   	push   %esi
f0103613:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f0103616:	fc                   	cld    

static inline uint32_t
read_eflags(void)
{
	uint32_t eflags;
	asm volatile("pushfl; popl %0" : "=r" (eflags));
f0103617:	9c                   	pushf  
f0103618:	58                   	pop    %eax

	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f0103619:	f6 c4 02             	test   $0x2,%ah
f010361c:	74 19                	je     f0103637 <trap+0x29>
f010361e:	68 03 5b 10 f0       	push   $0xf0105b03
f0103623:	68 1a 56 10 f0       	push   $0xf010561a
f0103628:	68 f8 00 00 00       	push   $0xf8
f010362d:	68 f7 5a 10 f0       	push   $0xf0105af7
f0103632:	e8 69 ca ff ff       	call   f01000a0 <_panic>

	cprintf("Incoming TRAP frame at %p\n", tf);
f0103637:	83 ec 08             	sub    $0x8,%esp
f010363a:	56                   	push   %esi
f010363b:	68 1c 5b 10 f0       	push   $0xf0105b1c
f0103640:	e8 bb f8 ff ff       	call   f0102f00 <cprintf>

	if ((tf->tf_cs & 3) == 3) {
f0103645:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0103649:	83 e0 03             	and    $0x3,%eax
f010364c:	83 c4 10             	add    $0x10,%esp
f010364f:	66 83 f8 03          	cmp    $0x3,%ax
f0103653:	75 31                	jne    f0103686 <trap+0x78>
		// Trapped from user mode.
		assert(curenv);
f0103655:	a1 84 1f 17 f0       	mov    0xf0171f84,%eax
f010365a:	85 c0                	test   %eax,%eax
f010365c:	75 19                	jne    f0103677 <trap+0x69>
f010365e:	68 37 5b 10 f0       	push   $0xf0105b37
f0103663:	68 1a 56 10 f0       	push   $0xf010561a
f0103668:	68 fe 00 00 00       	push   $0xfe
f010366d:	68 f7 5a 10 f0       	push   $0xf0105af7
f0103672:	e8 29 ca ff ff       	call   f01000a0 <_panic>

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f0103677:	b9 11 00 00 00       	mov    $0x11,%ecx
f010367c:	89 c7                	mov    %eax,%edi
f010367e:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f0103680:	8b 35 84 1f 17 f0    	mov    0xf0171f84,%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f0103686:	89 35 a0 27 17 f0    	mov    %esi,0xf01727a0
trap_dispatch(struct Trapframe *tf)
{
	// Handle processor exceptions.
	// LAB 3: Your code here.
	int r;
	switch(tf->tf_trapno){
f010368c:	8b 46 28             	mov    0x28(%esi),%eax
f010368f:	83 f8 0e             	cmp    $0xe,%eax
f0103692:	74 46                	je     f01036da <trap+0xcc>
f0103694:	83 f8 30             	cmp    $0x30,%eax
f0103697:	74 07                	je     f01036a0 <trap+0x92>
f0103699:	83 f8 03             	cmp    $0x3,%eax
f010369c:	75 58                	jne    f01036f6 <trap+0xe8>
f010369e:	eb 48                	jmp    f01036e8 <trap+0xda>
		case T_SYSCALL:
			r = syscall(
f01036a0:	83 ec 08             	sub    $0x8,%esp
f01036a3:	ff 76 04             	pushl  0x4(%esi)
f01036a6:	ff 36                	pushl  (%esi)
f01036a8:	ff 76 10             	pushl  0x10(%esi)
f01036ab:	ff 76 18             	pushl  0x18(%esi)
f01036ae:	ff 76 14             	pushl  0x14(%esi)
f01036b1:	ff 76 1c             	pushl  0x1c(%esi)
f01036b4:	e8 46 01 00 00       	call   f01037ff <syscall>
					tf->tf_regs.reg_ecx, 
					tf->tf_regs.reg_ebx, 
					tf->tf_regs.reg_edi, 
					tf->tf_regs.reg_esi);

			if (r < 0) {
f01036b9:	83 c4 20             	add    $0x20,%esp
f01036bc:	85 c0                	test   %eax,%eax
f01036be:	79 15                	jns    f01036d5 <trap+0xc7>
				panic("trap_dispatch: %e", r);
f01036c0:	50                   	push   %eax
f01036c1:	68 3e 5b 10 f0       	push   $0xf0105b3e
f01036c6:	68 d8 00 00 00       	push   $0xd8
f01036cb:	68 f7 5a 10 f0       	push   $0xf0105af7
f01036d0:	e8 cb c9 ff ff       	call   f01000a0 <_panic>
			}
			tf->tf_regs.reg_eax = r; 
f01036d5:	89 46 1c             	mov    %eax,0x1c(%esi)
f01036d8:	eb 57                	jmp    f0103731 <trap+0x123>
			return;
		case T_PGFLT:
			page_fault_handler(tf);
f01036da:	83 ec 0c             	sub    $0xc,%esp
f01036dd:	56                   	push   %esi
f01036de:	e8 cc fe ff ff       	call   f01035af <page_fault_handler>
f01036e3:	83 c4 10             	add    $0x10,%esp
f01036e6:	eb 49                	jmp    f0103731 <trap+0x123>
			return;
		case T_BRKPT:
			monitor(tf);
f01036e8:	83 ec 0c             	sub    $0xc,%esp
f01036eb:	56                   	push   %esi
f01036ec:	e8 b1 d0 ff ff       	call   f01007a2 <monitor>
f01036f1:	83 c4 10             	add    $0x10,%esp
f01036f4:	eb 3b                	jmp    f0103731 <trap+0x123>
			return;
	}

	// Unexpected trap: The user process or the kernel has a bug.
	print_trapframe(tf);
f01036f6:	83 ec 0c             	sub    $0xc,%esp
f01036f9:	56                   	push   %esi
f01036fa:	e8 3d fd ff ff       	call   f010343c <print_trapframe>
	if (tf->tf_cs == GD_KT)
f01036ff:	83 c4 10             	add    $0x10,%esp
f0103702:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f0103707:	75 17                	jne    f0103720 <trap+0x112>
		panic("unhandled trap in kernel");
f0103709:	83 ec 04             	sub    $0x4,%esp
f010370c:	68 50 5b 10 f0       	push   $0xf0105b50
f0103711:	68 e7 00 00 00       	push   $0xe7
f0103716:	68 f7 5a 10 f0       	push   $0xf0105af7
f010371b:	e8 80 c9 ff ff       	call   f01000a0 <_panic>
	else {
		env_destroy(curenv);
f0103720:	83 ec 0c             	sub    $0xc,%esp
f0103723:	ff 35 84 1f 17 f0    	pushl  0xf0171f84
f0103729:	e8 b9 f6 ff ff       	call   f0102de7 <env_destroy>
f010372e:	83 c4 10             	add    $0x10,%esp

	// Dispatch based on what type of trap occurred
	trap_dispatch(tf);

	// Return to the current environment, which should be running.
	assert(curenv && curenv->env_status == ENV_RUNNING);
f0103731:	a1 84 1f 17 f0       	mov    0xf0171f84,%eax
f0103736:	85 c0                	test   %eax,%eax
f0103738:	74 06                	je     f0103740 <trap+0x132>
f010373a:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f010373e:	74 19                	je     f0103759 <trap+0x14b>
f0103740:	68 00 5d 10 f0       	push   $0xf0105d00
f0103745:	68 1a 56 10 f0       	push   $0xf010561a
f010374a:	68 10 01 00 00       	push   $0x110
f010374f:	68 f7 5a 10 f0       	push   $0xf0105af7
f0103754:	e8 47 c9 ff ff       	call   f01000a0 <_panic>
	env_run(curenv);
f0103759:	83 ec 0c             	sub    $0xc,%esp
f010375c:	50                   	push   %eax
f010375d:	e8 d5 f6 ff ff       	call   f0102e37 <env_run>

f0103762 <t_divide>:
.text

/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */
TRAPHANDLER_NOEC(t_divide, T_DIVIDE)
f0103762:	6a 00                	push   $0x0
f0103764:	6a 00                	push   $0x0
f0103766:	e9 83 00 00 00       	jmp    f01037ee <_alltraps>
f010376b:	90                   	nop

f010376c <t_debug>:
TRAPHANDLER_NOEC(t_debug, T_DEBUG)
f010376c:	6a 00                	push   $0x0
f010376e:	6a 01                	push   $0x1
f0103770:	eb 7c                	jmp    f01037ee <_alltraps>

f0103772 <t_nmi>:
TRAPHANDLER_NOEC(t_nmi, T_NMI)
f0103772:	6a 00                	push   $0x0
f0103774:	6a 02                	push   $0x2
f0103776:	eb 76                	jmp    f01037ee <_alltraps>

f0103778 <t_brkpt>:
TRAPHANDLER_NOEC(t_brkpt, T_BRKPT)
f0103778:	6a 00                	push   $0x0
f010377a:	6a 03                	push   $0x3
f010377c:	eb 70                	jmp    f01037ee <_alltraps>

f010377e <t_oflow>:
TRAPHANDLER_NOEC(t_oflow, T_OFLOW)
f010377e:	6a 00                	push   $0x0
f0103780:	6a 04                	push   $0x4
f0103782:	eb 6a                	jmp    f01037ee <_alltraps>

f0103784 <t_bound>:
TRAPHANDLER_NOEC(t_bound, T_BOUND)
f0103784:	6a 00                	push   $0x0
f0103786:	6a 05                	push   $0x5
f0103788:	eb 64                	jmp    f01037ee <_alltraps>

f010378a <t_illop>:
TRAPHANDLER_NOEC(t_illop, T_ILLOP)
f010378a:	6a 00                	push   $0x0
f010378c:	6a 06                	push   $0x6
f010378e:	eb 5e                	jmp    f01037ee <_alltraps>

f0103790 <t_device>:
TRAPHANDLER_NOEC(t_device, T_DEVICE)
f0103790:	6a 00                	push   $0x0
f0103792:	6a 07                	push   $0x7
f0103794:	eb 58                	jmp    f01037ee <_alltraps>

f0103796 <t_dblflt>:
TRAPHANDLER(t_dblflt, T_DBLFLT)
f0103796:	6a 08                	push   $0x8
f0103798:	eb 54                	jmp    f01037ee <_alltraps>

f010379a <t_tss>:
TRAPHANDLER(t_tss, T_TSS)
f010379a:	6a 0a                	push   $0xa
f010379c:	eb 50                	jmp    f01037ee <_alltraps>

f010379e <t_segnp>:
TRAPHANDLER(t_segnp, T_SEGNP)
f010379e:	6a 0b                	push   $0xb
f01037a0:	eb 4c                	jmp    f01037ee <_alltraps>

f01037a2 <t_stack>:
TRAPHANDLER(t_stack, T_STACK)
f01037a2:	6a 0c                	push   $0xc
f01037a4:	eb 48                	jmp    f01037ee <_alltraps>

f01037a6 <t_gpflt>:
TRAPHANDLER(t_gpflt, T_GPFLT)
f01037a6:	6a 0d                	push   $0xd
f01037a8:	eb 44                	jmp    f01037ee <_alltraps>

f01037aa <t_pgflt>:
TRAPHANDLER(t_pgflt, T_PGFLT)
f01037aa:	6a 0e                	push   $0xe
f01037ac:	eb 40                	jmp    f01037ee <_alltraps>

f01037ae <t_fperr>:
TRAPHANDLER_NOEC(t_fperr, T_FPERR)
f01037ae:	6a 00                	push   $0x0
f01037b0:	6a 10                	push   $0x10
f01037b2:	eb 3a                	jmp    f01037ee <_alltraps>

f01037b4 <t_align>:
TRAPHANDLER(t_align, T_ALIGN)
f01037b4:	6a 11                	push   $0x11
f01037b6:	eb 36                	jmp    f01037ee <_alltraps>

f01037b8 <t_mchk>:
TRAPHANDLER_NOEC(t_mchk, T_MCHK)
f01037b8:	6a 00                	push   $0x0
f01037ba:	6a 12                	push   $0x12
f01037bc:	eb 30                	jmp    f01037ee <_alltraps>

f01037be <t_simderr>:
TRAPHANDLER_NOEC(t_simderr, T_SIMDERR)
f01037be:	6a 00                	push   $0x0
f01037c0:	6a 13                	push   $0x13
f01037c2:	eb 2a                	jmp    f01037ee <_alltraps>

f01037c4 <t_syscall>:
TRAPHANDLER_NOEC(t_syscall, T_SYSCALL)
f01037c4:	6a 00                	push   $0x0
f01037c6:	6a 30                	push   $0x30
f01037c8:	eb 24                	jmp    f01037ee <_alltraps>

f01037ca <irq_timer>:
TRAPHANDLER_NOEC(irq_timer, IRQ_OFFSET + IRQ_TIMER)
f01037ca:	6a 00                	push   $0x0
f01037cc:	6a 20                	push   $0x20
f01037ce:	eb 1e                	jmp    f01037ee <_alltraps>

f01037d0 <irq_kbd>:
TRAPHANDLER_NOEC(irq_kbd, IRQ_OFFSET + IRQ_KBD)
f01037d0:	6a 00                	push   $0x0
f01037d2:	6a 21                	push   $0x21
f01037d4:	eb 18                	jmp    f01037ee <_alltraps>

f01037d6 <irq_serial>:
TRAPHANDLER_NOEC(irq_serial, IRQ_OFFSET + IRQ_SERIAL)
f01037d6:	6a 00                	push   $0x0
f01037d8:	6a 24                	push   $0x24
f01037da:	eb 12                	jmp    f01037ee <_alltraps>

f01037dc <irq_spurious>:
TRAPHANDLER_NOEC(irq_spurious, IRQ_OFFSET + IRQ_SPURIOUS)
f01037dc:	6a 00                	push   $0x0
f01037de:	6a 27                	push   $0x27
f01037e0:	eb 0c                	jmp    f01037ee <_alltraps>

f01037e2 <irq_ide>:
TRAPHANDLER_NOEC(irq_ide, IRQ_OFFSET + IRQ_IDE)
f01037e2:	6a 00                	push   $0x0
f01037e4:	6a 2e                	push   $0x2e
f01037e6:	eb 06                	jmp    f01037ee <_alltraps>

f01037e8 <irq_error>:
TRAPHANDLER_NOEC(irq_error, IRQ_OFFSET + IRQ_ERROR)
f01037e8:	6a 00                	push   $0x0
f01037ea:	6a 33                	push   $0x33
f01037ec:	eb 00                	jmp    f01037ee <_alltraps>

f01037ee <_alltraps>:
/*
 * Lab 3: Your code here for _alltraps
 */
_alltraps:
	# Build trap frame.
	pushl %ds
f01037ee:	1e                   	push   %ds
	pushl %es
f01037ef:	06                   	push   %es
	pushal	
f01037f0:	60                   	pusha  

	movw $(GD_KD), %ax
f01037f1:	66 b8 10 00          	mov    $0x10,%ax
	movw %ax, %ds
f01037f5:	8e d8                	mov    %eax,%ds
	movw %ax, %es
f01037f7:	8e c0                	mov    %eax,%es

	pushl %esp
f01037f9:	54                   	push   %esp
	call trap
f01037fa:	e8 0f fe ff ff       	call   f010360e <trap>

f01037ff <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f01037ff:	55                   	push   %ebp
f0103800:	89 e5                	mov    %esp,%ebp
f0103802:	83 ec 18             	sub    $0x18,%esp
f0103805:	8b 45 08             	mov    0x8(%ebp),%eax
	// Return any appropriate return value.
	// LAB 3: Your code here.

	//panic("syscall not implemented");

	switch (syscallno) {
f0103808:	83 f8 01             	cmp    $0x1,%eax
f010380b:	74 44                	je     f0103851 <syscall+0x52>
f010380d:	83 f8 01             	cmp    $0x1,%eax
f0103810:	72 0f                	jb     f0103821 <syscall+0x22>
f0103812:	83 f8 02             	cmp    $0x2,%eax
f0103815:	74 41                	je     f0103858 <syscall+0x59>
f0103817:	83 f8 03             	cmp    $0x3,%eax
f010381a:	74 46                	je     f0103862 <syscall+0x63>
f010381c:	e9 a6 00 00 00       	jmp    f01038c7 <syscall+0xc8>
{
	// Check that the user has permission to read memory [s, s+len).
	// Destroy the environment if not.

	// LAB 3: Your code here.
	user_mem_assert(curenv, s, len, PTE_U | PTE_W);
f0103821:	6a 06                	push   $0x6
f0103823:	ff 75 10             	pushl  0x10(%ebp)
f0103826:	ff 75 0c             	pushl  0xc(%ebp)
f0103829:	ff 35 84 1f 17 f0    	pushl  0xf0171f84
f010382f:	e8 d3 ef ff ff       	call   f0102807 <user_mem_assert>

	// Print the string supplied by the user.
	cprintf("%.*s", len, s);
f0103834:	83 c4 0c             	add    $0xc,%esp
f0103837:	ff 75 0c             	pushl  0xc(%ebp)
f010383a:	ff 75 10             	pushl  0x10(%ebp)
f010383d:	68 90 5d 10 f0       	push   $0xf0105d90
f0103842:	e8 b9 f6 ff ff       	call   f0102f00 <cprintf>
f0103847:	83 c4 10             	add    $0x10,%esp
	//panic("syscall not implemented");

	switch (syscallno) {
		case SYS_cputs:
			sys_cputs((const char *) a1,(size_t) a2);
			return 0;
f010384a:	b8 00 00 00 00       	mov    $0x0,%eax
f010384f:	eb 7b                	jmp    f01038cc <syscall+0xcd>
// Read a character from the system console without blocking.
// Returns the character, or 0 if there is no input waiting.
static int
sys_cgetc(void)
{
	return cons_getc();
f0103851:	e8 6d cc ff ff       	call   f01004c3 <cons_getc>
	switch (syscallno) {
		case SYS_cputs:
			sys_cputs((const char *) a1,(size_t) a2);
			return 0;
		case SYS_cgetc:
			return sys_cgetc();
f0103856:	eb 74                	jmp    f01038cc <syscall+0xcd>

// Returns the current environment's envid.
static envid_t
sys_getenvid(void)
{
	return curenv->env_id;
f0103858:	a1 84 1f 17 f0       	mov    0xf0171f84,%eax
f010385d:	8b 40 48             	mov    0x48(%eax),%eax
			sys_cputs((const char *) a1,(size_t) a2);
			return 0;
		case SYS_cgetc:
			return sys_cgetc();
		case SYS_getenvid:
			return sys_getenvid();
f0103860:	eb 6a                	jmp    f01038cc <syscall+0xcd>
sys_env_destroy(envid_t envid)
{
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
f0103862:	83 ec 04             	sub    $0x4,%esp
f0103865:	6a 01                	push   $0x1
f0103867:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010386a:	50                   	push   %eax
f010386b:	ff 75 0c             	pushl  0xc(%ebp)
f010386e:	e8 49 f0 ff ff       	call   f01028bc <envid2env>
f0103873:	83 c4 10             	add    $0x10,%esp
f0103876:	85 c0                	test   %eax,%eax
f0103878:	78 52                	js     f01038cc <syscall+0xcd>
		return r;
	if (e == curenv)
f010387a:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010387d:	8b 15 84 1f 17 f0    	mov    0xf0171f84,%edx
f0103883:	39 d0                	cmp    %edx,%eax
f0103885:	75 15                	jne    f010389c <syscall+0x9d>
		cprintf("[%08x] exiting gracefully\n", curenv->env_id);
f0103887:	83 ec 08             	sub    $0x8,%esp
f010388a:	ff 70 48             	pushl  0x48(%eax)
f010388d:	68 95 5d 10 f0       	push   $0xf0105d95
f0103892:	e8 69 f6 ff ff       	call   f0102f00 <cprintf>
f0103897:	83 c4 10             	add    $0x10,%esp
f010389a:	eb 16                	jmp    f01038b2 <syscall+0xb3>
	else
		cprintf("[%08x] destroying %08x\n", curenv->env_id, e->env_id);
f010389c:	83 ec 04             	sub    $0x4,%esp
f010389f:	ff 70 48             	pushl  0x48(%eax)
f01038a2:	ff 72 48             	pushl  0x48(%edx)
f01038a5:	68 b0 5d 10 f0       	push   $0xf0105db0
f01038aa:	e8 51 f6 ff ff       	call   f0102f00 <cprintf>
f01038af:	83 c4 10             	add    $0x10,%esp
	env_destroy(e);
f01038b2:	83 ec 0c             	sub    $0xc,%esp
f01038b5:	ff 75 f4             	pushl  -0xc(%ebp)
f01038b8:	e8 2a f5 ff ff       	call   f0102de7 <env_destroy>
f01038bd:	83 c4 10             	add    $0x10,%esp
	return 0;
f01038c0:	b8 00 00 00 00       	mov    $0x0,%eax
f01038c5:	eb 05                	jmp    f01038cc <syscall+0xcd>
		case SYS_getenvid:
			return sys_getenvid();
		case SYS_env_destroy:
			return sys_env_destroy((envid_t)a1);
		default:
			return -E_INVAL;
f01038c7:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
	}
}
f01038cc:	c9                   	leave  
f01038cd:	c3                   	ret    

f01038ce <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01038ce:	55                   	push   %ebp
f01038cf:	89 e5                	mov    %esp,%ebp
f01038d1:	57                   	push   %edi
f01038d2:	56                   	push   %esi
f01038d3:	53                   	push   %ebx
f01038d4:	83 ec 14             	sub    $0x14,%esp
f01038d7:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01038da:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01038dd:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01038e0:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f01038e3:	8b 1a                	mov    (%edx),%ebx
f01038e5:	8b 01                	mov    (%ecx),%eax
f01038e7:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01038ea:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f01038f1:	eb 7f                	jmp    f0103972 <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f01038f3:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01038f6:	01 d8                	add    %ebx,%eax
f01038f8:	89 c6                	mov    %eax,%esi
f01038fa:	c1 ee 1f             	shr    $0x1f,%esi
f01038fd:	01 c6                	add    %eax,%esi
f01038ff:	d1 fe                	sar    %esi
f0103901:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0103904:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0103907:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f010390a:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f010390c:	eb 03                	jmp    f0103911 <stab_binsearch+0x43>
			m--;
f010390e:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0103911:	39 c3                	cmp    %eax,%ebx
f0103913:	7f 0d                	jg     f0103922 <stab_binsearch+0x54>
f0103915:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0103919:	83 ea 0c             	sub    $0xc,%edx
f010391c:	39 f9                	cmp    %edi,%ecx
f010391e:	75 ee                	jne    f010390e <stab_binsearch+0x40>
f0103920:	eb 05                	jmp    f0103927 <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0103922:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f0103925:	eb 4b                	jmp    f0103972 <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0103927:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010392a:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010392d:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0103931:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0103934:	76 11                	jbe    f0103947 <stab_binsearch+0x79>
			*region_left = m;
f0103936:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0103939:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f010393b:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010393e:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0103945:	eb 2b                	jmp    f0103972 <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0103947:	39 55 0c             	cmp    %edx,0xc(%ebp)
f010394a:	73 14                	jae    f0103960 <stab_binsearch+0x92>
			*region_right = m - 1;
f010394c:	83 e8 01             	sub    $0x1,%eax
f010394f:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0103952:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0103955:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0103957:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f010395e:	eb 12                	jmp    f0103972 <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0103960:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103963:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0103965:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0103969:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010396b:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0103972:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0103975:	0f 8e 78 ff ff ff    	jle    f01038f3 <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f010397b:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f010397f:	75 0f                	jne    f0103990 <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f0103981:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103984:	8b 00                	mov    (%eax),%eax
f0103986:	83 e8 01             	sub    $0x1,%eax
f0103989:	8b 75 e0             	mov    -0x20(%ebp),%esi
f010398c:	89 06                	mov    %eax,(%esi)
f010398e:	eb 2c                	jmp    f01039bc <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103990:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103993:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0103995:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103998:	8b 0e                	mov    (%esi),%ecx
f010399a:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010399d:	8b 75 ec             	mov    -0x14(%ebp),%esi
f01039a0:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01039a3:	eb 03                	jmp    f01039a8 <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f01039a5:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01039a8:	39 c8                	cmp    %ecx,%eax
f01039aa:	7e 0b                	jle    f01039b7 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f01039ac:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f01039b0:	83 ea 0c             	sub    $0xc,%edx
f01039b3:	39 df                	cmp    %ebx,%edi
f01039b5:	75 ee                	jne    f01039a5 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f01039b7:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01039ba:	89 06                	mov    %eax,(%esi)
	}
}
f01039bc:	83 c4 14             	add    $0x14,%esp
f01039bf:	5b                   	pop    %ebx
f01039c0:	5e                   	pop    %esi
f01039c1:	5f                   	pop    %edi
f01039c2:	5d                   	pop    %ebp
f01039c3:	c3                   	ret    

f01039c4 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f01039c4:	55                   	push   %ebp
f01039c5:	89 e5                	mov    %esp,%ebp
f01039c7:	57                   	push   %edi
f01039c8:	56                   	push   %esi
f01039c9:	53                   	push   %ebx
f01039ca:	83 ec 3c             	sub    $0x3c,%esp
f01039cd:	8b 75 08             	mov    0x8(%ebp),%esi
f01039d0:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f01039d3:	c7 03 c8 5d 10 f0    	movl   $0xf0105dc8,(%ebx)
	info->eip_line = 0;
f01039d9:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f01039e0:	c7 43 08 c8 5d 10 f0 	movl   $0xf0105dc8,0x8(%ebx)
	info->eip_fn_namelen = 9;
f01039e7:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f01039ee:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f01039f1:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f01039f8:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f01039fe:	0f 87 db 00 00 00    	ja     f0103adf <debuginfo_eip+0x11b>
		const struct UserStabData *usd = (const struct UserStabData *) USTABDATA;

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, usd, sizeof(struct UserStabData), PTE_U) < 0) {
f0103a04:	6a 04                	push   $0x4
f0103a06:	6a 10                	push   $0x10
f0103a08:	68 00 00 20 00       	push   $0x200000
f0103a0d:	ff 35 84 1f 17 f0    	pushl  0xf0171f84
f0103a13:	e8 69 ed ff ff       	call   f0102781 <user_mem_check>
f0103a18:	83 c4 10             	add    $0x10,%esp
f0103a1b:	85 c0                	test   %eax,%eax
f0103a1d:	79 1f                	jns    f0103a3e <debuginfo_eip+0x7a>
			cprintf("debuginfo_eip: invalid usd addr %08x", usd);
f0103a1f:	83 ec 08             	sub    $0x8,%esp
f0103a22:	68 00 00 20 00       	push   $0x200000
f0103a27:	68 d4 5d 10 f0       	push   $0xf0105dd4
f0103a2c:	e8 cf f4 ff ff       	call   f0102f00 <cprintf>
			return -1;
f0103a31:	83 c4 10             	add    $0x10,%esp
f0103a34:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103a39:	e9 84 02 00 00       	jmp    f0103cc2 <debuginfo_eip+0x2fe>
		}

		stabs = usd->stabs;
f0103a3e:	a1 00 00 20 00       	mov    0x200000,%eax
f0103a43:	89 c1                	mov    %eax,%ecx
f0103a45:	89 45 c0             	mov    %eax,-0x40(%ebp)
		stab_end = usd->stab_end;
f0103a48:	8b 3d 04 00 20 00    	mov    0x200004,%edi
		stabstr = usd->stabstr;
f0103a4e:	a1 08 00 20 00       	mov    0x200008,%eax
f0103a53:	89 45 b8             	mov    %eax,-0x48(%ebp)
		stabstr_end = usd->stabstr_end;
f0103a56:	a1 0c 00 20 00       	mov    0x20000c,%eax
f0103a5b:	89 45 bc             	mov    %eax,-0x44(%ebp)

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, stabs, stab_end-stabs+1, PTE_U) < 0){
f0103a5e:	6a 04                	push   $0x4
f0103a60:	89 f8                	mov    %edi,%eax
f0103a62:	29 c8                	sub    %ecx,%eax
f0103a64:	c1 f8 02             	sar    $0x2,%eax
f0103a67:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0103a6d:	83 c0 01             	add    $0x1,%eax
f0103a70:	50                   	push   %eax
f0103a71:	51                   	push   %ecx
f0103a72:	ff 35 84 1f 17 f0    	pushl  0xf0171f84
f0103a78:	e8 04 ed ff ff       	call   f0102781 <user_mem_check>
f0103a7d:	83 c4 10             	add    $0x10,%esp
f0103a80:	85 c0                	test   %eax,%eax
f0103a82:	79 1d                	jns    f0103aa1 <debuginfo_eip+0xdd>
			cprintf("debuginfo_eip: invalid stabs addr %08x", stabs);
f0103a84:	83 ec 08             	sub    $0x8,%esp
f0103a87:	ff 75 c0             	pushl  -0x40(%ebp)
f0103a8a:	68 fc 5d 10 f0       	push   $0xf0105dfc
f0103a8f:	e8 6c f4 ff ff       	call   f0102f00 <cprintf>
			return -1;
f0103a94:	83 c4 10             	add    $0x10,%esp
f0103a97:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103a9c:	e9 21 02 00 00       	jmp    f0103cc2 <debuginfo_eip+0x2fe>
		}
		if (user_mem_check(curenv, stabstr, stabstr_end-stabstr+1, PTE_U) < 0) {
f0103aa1:	6a 04                	push   $0x4
f0103aa3:	8b 45 bc             	mov    -0x44(%ebp),%eax
f0103aa6:	8b 4d b8             	mov    -0x48(%ebp),%ecx
f0103aa9:	29 c8                	sub    %ecx,%eax
f0103aab:	83 c0 01             	add    $0x1,%eax
f0103aae:	50                   	push   %eax
f0103aaf:	51                   	push   %ecx
f0103ab0:	ff 35 84 1f 17 f0    	pushl  0xf0171f84
f0103ab6:	e8 c6 ec ff ff       	call   f0102781 <user_mem_check>
f0103abb:	83 c4 10             	add    $0x10,%esp
f0103abe:	85 c0                	test   %eax,%eax
f0103ac0:	79 37                	jns    f0103af9 <debuginfo_eip+0x135>
			cprintf("debuginfo_eip: invalid stabstr addr %08x", stabstr);
f0103ac2:	83 ec 08             	sub    $0x8,%esp
f0103ac5:	ff 75 b8             	pushl  -0x48(%ebp)
f0103ac8:	68 24 5e 10 f0       	push   $0xf0105e24
f0103acd:	e8 2e f4 ff ff       	call   f0102f00 <cprintf>
			return -1;
f0103ad2:	83 c4 10             	add    $0x10,%esp
f0103ad5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103ada:	e9 e3 01 00 00       	jmp    f0103cc2 <debuginfo_eip+0x2fe>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f0103adf:	c7 45 bc 37 04 11 f0 	movl   $0xf0110437,-0x44(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f0103ae6:	c7 45 b8 e1 d9 10 f0 	movl   $0xf010d9e1,-0x48(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f0103aed:	bf e0 d9 10 f0       	mov    $0xf010d9e0,%edi
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f0103af2:	c7 45 c0 60 60 10 f0 	movl   $0xf0106060,-0x40(%ebp)
			return -1;
		}
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0103af9:	8b 45 bc             	mov    -0x44(%ebp),%eax
f0103afc:	39 45 b8             	cmp    %eax,-0x48(%ebp)
f0103aff:	0f 83 9c 01 00 00    	jae    f0103ca1 <debuginfo_eip+0x2dd>
f0103b05:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f0103b09:	0f 85 99 01 00 00    	jne    f0103ca8 <debuginfo_eip+0x2e4>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0103b0f:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0103b16:	2b 7d c0             	sub    -0x40(%ebp),%edi
f0103b19:	c1 ff 02             	sar    $0x2,%edi
f0103b1c:	69 c7 ab aa aa aa    	imul   $0xaaaaaaab,%edi,%eax
f0103b22:	83 e8 01             	sub    $0x1,%eax
f0103b25:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0103b28:	83 ec 08             	sub    $0x8,%esp
f0103b2b:	56                   	push   %esi
f0103b2c:	6a 64                	push   $0x64
f0103b2e:	8d 55 e0             	lea    -0x20(%ebp),%edx
f0103b31:	89 d1                	mov    %edx,%ecx
f0103b33:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0103b36:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0103b39:	89 f8                	mov    %edi,%eax
f0103b3b:	e8 8e fd ff ff       	call   f01038ce <stab_binsearch>
	if (lfile == 0)
f0103b40:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103b43:	83 c4 10             	add    $0x10,%esp
f0103b46:	85 c0                	test   %eax,%eax
f0103b48:	0f 84 61 01 00 00    	je     f0103caf <debuginfo_eip+0x2eb>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0103b4e:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0103b51:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103b54:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0103b57:	83 ec 08             	sub    $0x8,%esp
f0103b5a:	56                   	push   %esi
f0103b5b:	6a 24                	push   $0x24
f0103b5d:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0103b60:	89 d1                	mov    %edx,%ecx
f0103b62:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0103b65:	89 f8                	mov    %edi,%eax
f0103b67:	e8 62 fd ff ff       	call   f01038ce <stab_binsearch>

	if (lfun <= rfun) {
f0103b6c:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103b6f:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103b72:	89 55 c4             	mov    %edx,-0x3c(%ebp)
f0103b75:	83 c4 10             	add    $0x10,%esp
f0103b78:	39 d0                	cmp    %edx,%eax
f0103b7a:	7f 2b                	jg     f0103ba7 <debuginfo_eip+0x1e3>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0103b7c:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103b7f:	8d 0c 97             	lea    (%edi,%edx,4),%ecx
f0103b82:	8b 11                	mov    (%ecx),%edx
f0103b84:	8b 7d bc             	mov    -0x44(%ebp),%edi
f0103b87:	2b 7d b8             	sub    -0x48(%ebp),%edi
f0103b8a:	39 fa                	cmp    %edi,%edx
f0103b8c:	73 06                	jae    f0103b94 <debuginfo_eip+0x1d0>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0103b8e:	03 55 b8             	add    -0x48(%ebp),%edx
f0103b91:	89 53 08             	mov    %edx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0103b94:	8b 51 08             	mov    0x8(%ecx),%edx
f0103b97:	89 53 10             	mov    %edx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0103b9a:	29 d6                	sub    %edx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0103b9c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0103b9f:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0103ba2:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0103ba5:	eb 0f                	jmp    f0103bb6 <debuginfo_eip+0x1f2>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0103ba7:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0103baa:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103bad:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0103bb0:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103bb3:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0103bb6:	83 ec 08             	sub    $0x8,%esp
f0103bb9:	6a 3a                	push   $0x3a
f0103bbb:	ff 73 08             	pushl  0x8(%ebx)
f0103bbe:	e8 7a 08 00 00       	call   f010443d <strfind>
f0103bc3:	2b 43 08             	sub    0x8(%ebx),%eax
f0103bc6:	89 43 0c             	mov    %eax,0xc(%ebx)
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.

	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);	
f0103bc9:	83 c4 08             	add    $0x8,%esp
f0103bcc:	56                   	push   %esi
f0103bcd:	6a 44                	push   $0x44
f0103bcf:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0103bd2:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0103bd5:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0103bd8:	89 f8                	mov    %edi,%eax
f0103bda:	e8 ef fc ff ff       	call   f01038ce <stab_binsearch>
	if (lline > rline)
f0103bdf:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103be2:	83 c4 10             	add    $0x10,%esp
f0103be5:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0103be8:	0f 8f c8 00 00 00    	jg     f0103cb6 <debuginfo_eip+0x2f2>
		    return -1;
	info->eip_line = stabs[lline].n_desc;
f0103bee:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103bf1:	8d 14 97             	lea    (%edi,%edx,4),%edx
f0103bf4:	0f b7 4a 06          	movzwl 0x6(%edx),%ecx
f0103bf8:	89 4b 04             	mov    %ecx,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0103bfb:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103bfe:	c6 45 c4 00          	movb   $0x0,-0x3c(%ebp)
f0103c02:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103c05:	eb 0a                	jmp    f0103c11 <debuginfo_eip+0x24d>
f0103c07:	83 e8 01             	sub    $0x1,%eax
f0103c0a:	83 ea 0c             	sub    $0xc,%edx
f0103c0d:	c6 45 c4 01          	movb   $0x1,-0x3c(%ebp)
f0103c11:	39 c7                	cmp    %eax,%edi
f0103c13:	7e 05                	jle    f0103c1a <debuginfo_eip+0x256>
f0103c15:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103c18:	eb 47                	jmp    f0103c61 <debuginfo_eip+0x29d>
	       && stabs[lline].n_type != N_SOL
f0103c1a:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0103c1e:	80 f9 84             	cmp    $0x84,%cl
f0103c21:	75 0e                	jne    f0103c31 <debuginfo_eip+0x26d>
f0103c23:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103c26:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f0103c2a:	74 1c                	je     f0103c48 <debuginfo_eip+0x284>
f0103c2c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0103c2f:	eb 17                	jmp    f0103c48 <debuginfo_eip+0x284>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0103c31:	80 f9 64             	cmp    $0x64,%cl
f0103c34:	75 d1                	jne    f0103c07 <debuginfo_eip+0x243>
f0103c36:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f0103c3a:	74 cb                	je     f0103c07 <debuginfo_eip+0x243>
f0103c3c:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103c3f:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f0103c43:	74 03                	je     f0103c48 <debuginfo_eip+0x284>
f0103c45:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0103c48:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0103c4b:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0103c4e:	8b 14 87             	mov    (%edi,%eax,4),%edx
f0103c51:	8b 45 bc             	mov    -0x44(%ebp),%eax
f0103c54:	8b 75 b8             	mov    -0x48(%ebp),%esi
f0103c57:	29 f0                	sub    %esi,%eax
f0103c59:	39 c2                	cmp    %eax,%edx
f0103c5b:	73 04                	jae    f0103c61 <debuginfo_eip+0x29d>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0103c5d:	01 f2                	add    %esi,%edx
f0103c5f:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103c61:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103c64:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103c67:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103c6c:	39 f2                	cmp    %esi,%edx
f0103c6e:	7d 52                	jge    f0103cc2 <debuginfo_eip+0x2fe>
		for (lline = lfun + 1;
f0103c70:	83 c2 01             	add    $0x1,%edx
f0103c73:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0103c76:	89 d0                	mov    %edx,%eax
f0103c78:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0103c7b:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0103c7e:	8d 14 97             	lea    (%edi,%edx,4),%edx
f0103c81:	eb 04                	jmp    f0103c87 <debuginfo_eip+0x2c3>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0103c83:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0103c87:	39 c6                	cmp    %eax,%esi
f0103c89:	7e 32                	jle    f0103cbd <debuginfo_eip+0x2f9>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0103c8b:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0103c8f:	83 c0 01             	add    $0x1,%eax
f0103c92:	83 c2 0c             	add    $0xc,%edx
f0103c95:	80 f9 a0             	cmp    $0xa0,%cl
f0103c98:	74 e9                	je     f0103c83 <debuginfo_eip+0x2bf>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103c9a:	b8 00 00 00 00       	mov    $0x0,%eax
f0103c9f:	eb 21                	jmp    f0103cc2 <debuginfo_eip+0x2fe>
		}
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0103ca1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103ca6:	eb 1a                	jmp    f0103cc2 <debuginfo_eip+0x2fe>
f0103ca8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103cad:	eb 13                	jmp    f0103cc2 <debuginfo_eip+0x2fe>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0103caf:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103cb4:	eb 0c                	jmp    f0103cc2 <debuginfo_eip+0x2fe>
	//	which one.
	// Your code here.

	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);	
	if (lline > rline)
		    return -1;
f0103cb6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103cbb:	eb 05                	jmp    f0103cc2 <debuginfo_eip+0x2fe>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103cbd:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103cc2:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103cc5:	5b                   	pop    %ebx
f0103cc6:	5e                   	pop    %esi
f0103cc7:	5f                   	pop    %edi
f0103cc8:	5d                   	pop    %ebp
f0103cc9:	c3                   	ret    

f0103cca <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0103cca:	55                   	push   %ebp
f0103ccb:	89 e5                	mov    %esp,%ebp
f0103ccd:	57                   	push   %edi
f0103cce:	56                   	push   %esi
f0103ccf:	53                   	push   %ebx
f0103cd0:	83 ec 1c             	sub    $0x1c,%esp
f0103cd3:	89 c7                	mov    %eax,%edi
f0103cd5:	89 d6                	mov    %edx,%esi
f0103cd7:	8b 45 08             	mov    0x8(%ebp),%eax
f0103cda:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103cdd:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103ce0:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0103ce3:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0103ce6:	bb 00 00 00 00       	mov    $0x0,%ebx
f0103ceb:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0103cee:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0103cf1:	39 d3                	cmp    %edx,%ebx
f0103cf3:	72 05                	jb     f0103cfa <printnum+0x30>
f0103cf5:	39 45 10             	cmp    %eax,0x10(%ebp)
f0103cf8:	77 45                	ja     f0103d3f <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0103cfa:	83 ec 0c             	sub    $0xc,%esp
f0103cfd:	ff 75 18             	pushl  0x18(%ebp)
f0103d00:	8b 45 14             	mov    0x14(%ebp),%eax
f0103d03:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0103d06:	53                   	push   %ebx
f0103d07:	ff 75 10             	pushl  0x10(%ebp)
f0103d0a:	83 ec 08             	sub    $0x8,%esp
f0103d0d:	ff 75 e4             	pushl  -0x1c(%ebp)
f0103d10:	ff 75 e0             	pushl  -0x20(%ebp)
f0103d13:	ff 75 dc             	pushl  -0x24(%ebp)
f0103d16:	ff 75 d8             	pushl  -0x28(%ebp)
f0103d19:	e8 42 09 00 00       	call   f0104660 <__udivdi3>
f0103d1e:	83 c4 18             	add    $0x18,%esp
f0103d21:	52                   	push   %edx
f0103d22:	50                   	push   %eax
f0103d23:	89 f2                	mov    %esi,%edx
f0103d25:	89 f8                	mov    %edi,%eax
f0103d27:	e8 9e ff ff ff       	call   f0103cca <printnum>
f0103d2c:	83 c4 20             	add    $0x20,%esp
f0103d2f:	eb 18                	jmp    f0103d49 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0103d31:	83 ec 08             	sub    $0x8,%esp
f0103d34:	56                   	push   %esi
f0103d35:	ff 75 18             	pushl  0x18(%ebp)
f0103d38:	ff d7                	call   *%edi
f0103d3a:	83 c4 10             	add    $0x10,%esp
f0103d3d:	eb 03                	jmp    f0103d42 <printnum+0x78>
f0103d3f:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0103d42:	83 eb 01             	sub    $0x1,%ebx
f0103d45:	85 db                	test   %ebx,%ebx
f0103d47:	7f e8                	jg     f0103d31 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0103d49:	83 ec 08             	sub    $0x8,%esp
f0103d4c:	56                   	push   %esi
f0103d4d:	83 ec 04             	sub    $0x4,%esp
f0103d50:	ff 75 e4             	pushl  -0x1c(%ebp)
f0103d53:	ff 75 e0             	pushl  -0x20(%ebp)
f0103d56:	ff 75 dc             	pushl  -0x24(%ebp)
f0103d59:	ff 75 d8             	pushl  -0x28(%ebp)
f0103d5c:	e8 2f 0a 00 00       	call   f0104790 <__umoddi3>
f0103d61:	83 c4 14             	add    $0x14,%esp
f0103d64:	0f be 80 50 5e 10 f0 	movsbl -0xfefa1b0(%eax),%eax
f0103d6b:	50                   	push   %eax
f0103d6c:	ff d7                	call   *%edi
}
f0103d6e:	83 c4 10             	add    $0x10,%esp
f0103d71:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103d74:	5b                   	pop    %ebx
f0103d75:	5e                   	pop    %esi
f0103d76:	5f                   	pop    %edi
f0103d77:	5d                   	pop    %ebp
f0103d78:	c3                   	ret    

f0103d79 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0103d79:	55                   	push   %ebp
f0103d7a:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0103d7c:	83 fa 01             	cmp    $0x1,%edx
f0103d7f:	7e 0e                	jle    f0103d8f <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0103d81:	8b 10                	mov    (%eax),%edx
f0103d83:	8d 4a 08             	lea    0x8(%edx),%ecx
f0103d86:	89 08                	mov    %ecx,(%eax)
f0103d88:	8b 02                	mov    (%edx),%eax
f0103d8a:	8b 52 04             	mov    0x4(%edx),%edx
f0103d8d:	eb 22                	jmp    f0103db1 <getuint+0x38>
	else if (lflag)
f0103d8f:	85 d2                	test   %edx,%edx
f0103d91:	74 10                	je     f0103da3 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0103d93:	8b 10                	mov    (%eax),%edx
f0103d95:	8d 4a 04             	lea    0x4(%edx),%ecx
f0103d98:	89 08                	mov    %ecx,(%eax)
f0103d9a:	8b 02                	mov    (%edx),%eax
f0103d9c:	ba 00 00 00 00       	mov    $0x0,%edx
f0103da1:	eb 0e                	jmp    f0103db1 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0103da3:	8b 10                	mov    (%eax),%edx
f0103da5:	8d 4a 04             	lea    0x4(%edx),%ecx
f0103da8:	89 08                	mov    %ecx,(%eax)
f0103daa:	8b 02                	mov    (%edx),%eax
f0103dac:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0103db1:	5d                   	pop    %ebp
f0103db2:	c3                   	ret    

f0103db3 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0103db3:	55                   	push   %ebp
f0103db4:	89 e5                	mov    %esp,%ebp
f0103db6:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0103db9:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0103dbd:	8b 10                	mov    (%eax),%edx
f0103dbf:	3b 50 04             	cmp    0x4(%eax),%edx
f0103dc2:	73 0a                	jae    f0103dce <sprintputch+0x1b>
		*b->buf++ = ch;
f0103dc4:	8d 4a 01             	lea    0x1(%edx),%ecx
f0103dc7:	89 08                	mov    %ecx,(%eax)
f0103dc9:	8b 45 08             	mov    0x8(%ebp),%eax
f0103dcc:	88 02                	mov    %al,(%edx)
}
f0103dce:	5d                   	pop    %ebp
f0103dcf:	c3                   	ret    

f0103dd0 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0103dd0:	55                   	push   %ebp
f0103dd1:	89 e5                	mov    %esp,%ebp
f0103dd3:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0103dd6:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0103dd9:	50                   	push   %eax
f0103dda:	ff 75 10             	pushl  0x10(%ebp)
f0103ddd:	ff 75 0c             	pushl  0xc(%ebp)
f0103de0:	ff 75 08             	pushl  0x8(%ebp)
f0103de3:	e8 05 00 00 00       	call   f0103ded <vprintfmt>
	va_end(ap);
}
f0103de8:	83 c4 10             	add    $0x10,%esp
f0103deb:	c9                   	leave  
f0103dec:	c3                   	ret    

f0103ded <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0103ded:	55                   	push   %ebp
f0103dee:	89 e5                	mov    %esp,%ebp
f0103df0:	57                   	push   %edi
f0103df1:	56                   	push   %esi
f0103df2:	53                   	push   %ebx
f0103df3:	83 ec 2c             	sub    $0x2c,%esp
f0103df6:	8b 75 08             	mov    0x8(%ebp),%esi
f0103df9:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103dfc:	8b 7d 10             	mov    0x10(%ebp),%edi
f0103dff:	eb 12                	jmp    f0103e13 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0103e01:	85 c0                	test   %eax,%eax
f0103e03:	0f 84 89 03 00 00    	je     f0104192 <vprintfmt+0x3a5>
				return;
			putch(ch, putdat);
f0103e09:	83 ec 08             	sub    $0x8,%esp
f0103e0c:	53                   	push   %ebx
f0103e0d:	50                   	push   %eax
f0103e0e:	ff d6                	call   *%esi
f0103e10:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0103e13:	83 c7 01             	add    $0x1,%edi
f0103e16:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0103e1a:	83 f8 25             	cmp    $0x25,%eax
f0103e1d:	75 e2                	jne    f0103e01 <vprintfmt+0x14>
f0103e1f:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0103e23:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0103e2a:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0103e31:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0103e38:	ba 00 00 00 00       	mov    $0x0,%edx
f0103e3d:	eb 07                	jmp    f0103e46 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103e3f:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0103e42:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103e46:	8d 47 01             	lea    0x1(%edi),%eax
f0103e49:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103e4c:	0f b6 07             	movzbl (%edi),%eax
f0103e4f:	0f b6 c8             	movzbl %al,%ecx
f0103e52:	83 e8 23             	sub    $0x23,%eax
f0103e55:	3c 55                	cmp    $0x55,%al
f0103e57:	0f 87 1a 03 00 00    	ja     f0104177 <vprintfmt+0x38a>
f0103e5d:	0f b6 c0             	movzbl %al,%eax
f0103e60:	ff 24 85 dc 5e 10 f0 	jmp    *-0xfefa124(,%eax,4)
f0103e67:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0103e6a:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0103e6e:	eb d6                	jmp    f0103e46 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103e70:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103e73:	b8 00 00 00 00       	mov    $0x0,%eax
f0103e78:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0103e7b:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0103e7e:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f0103e82:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0103e85:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0103e88:	83 fa 09             	cmp    $0x9,%edx
f0103e8b:	77 39                	ja     f0103ec6 <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0103e8d:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0103e90:	eb e9                	jmp    f0103e7b <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0103e92:	8b 45 14             	mov    0x14(%ebp),%eax
f0103e95:	8d 48 04             	lea    0x4(%eax),%ecx
f0103e98:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0103e9b:	8b 00                	mov    (%eax),%eax
f0103e9d:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103ea0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0103ea3:	eb 27                	jmp    f0103ecc <vprintfmt+0xdf>
f0103ea5:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103ea8:	85 c0                	test   %eax,%eax
f0103eaa:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103eaf:	0f 49 c8             	cmovns %eax,%ecx
f0103eb2:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103eb5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103eb8:	eb 8c                	jmp    f0103e46 <vprintfmt+0x59>
f0103eba:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0103ebd:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0103ec4:	eb 80                	jmp    f0103e46 <vprintfmt+0x59>
f0103ec6:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0103ec9:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0103ecc:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0103ed0:	0f 89 70 ff ff ff    	jns    f0103e46 <vprintfmt+0x59>
				width = precision, precision = -1;
f0103ed6:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0103ed9:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103edc:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0103ee3:	e9 5e ff ff ff       	jmp    f0103e46 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0103ee8:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103eeb:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0103eee:	e9 53 ff ff ff       	jmp    f0103e46 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0103ef3:	8b 45 14             	mov    0x14(%ebp),%eax
f0103ef6:	8d 50 04             	lea    0x4(%eax),%edx
f0103ef9:	89 55 14             	mov    %edx,0x14(%ebp)
f0103efc:	83 ec 08             	sub    $0x8,%esp
f0103eff:	53                   	push   %ebx
f0103f00:	ff 30                	pushl  (%eax)
f0103f02:	ff d6                	call   *%esi
			break;
f0103f04:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103f07:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0103f0a:	e9 04 ff ff ff       	jmp    f0103e13 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0103f0f:	8b 45 14             	mov    0x14(%ebp),%eax
f0103f12:	8d 50 04             	lea    0x4(%eax),%edx
f0103f15:	89 55 14             	mov    %edx,0x14(%ebp)
f0103f18:	8b 00                	mov    (%eax),%eax
f0103f1a:	99                   	cltd   
f0103f1b:	31 d0                	xor    %edx,%eax
f0103f1d:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0103f1f:	83 f8 06             	cmp    $0x6,%eax
f0103f22:	7f 0b                	jg     f0103f2f <vprintfmt+0x142>
f0103f24:	8b 14 85 34 60 10 f0 	mov    -0xfef9fcc(,%eax,4),%edx
f0103f2b:	85 d2                	test   %edx,%edx
f0103f2d:	75 18                	jne    f0103f47 <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f0103f2f:	50                   	push   %eax
f0103f30:	68 68 5e 10 f0       	push   $0xf0105e68
f0103f35:	53                   	push   %ebx
f0103f36:	56                   	push   %esi
f0103f37:	e8 94 fe ff ff       	call   f0103dd0 <printfmt>
f0103f3c:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103f3f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0103f42:	e9 cc fe ff ff       	jmp    f0103e13 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0103f47:	52                   	push   %edx
f0103f48:	68 2c 56 10 f0       	push   $0xf010562c
f0103f4d:	53                   	push   %ebx
f0103f4e:	56                   	push   %esi
f0103f4f:	e8 7c fe ff ff       	call   f0103dd0 <printfmt>
f0103f54:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103f57:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103f5a:	e9 b4 fe ff ff       	jmp    f0103e13 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0103f5f:	8b 45 14             	mov    0x14(%ebp),%eax
f0103f62:	8d 50 04             	lea    0x4(%eax),%edx
f0103f65:	89 55 14             	mov    %edx,0x14(%ebp)
f0103f68:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0103f6a:	85 ff                	test   %edi,%edi
f0103f6c:	b8 61 5e 10 f0       	mov    $0xf0105e61,%eax
f0103f71:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0103f74:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0103f78:	0f 8e 94 00 00 00    	jle    f0104012 <vprintfmt+0x225>
f0103f7e:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0103f82:	0f 84 98 00 00 00    	je     f0104020 <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
f0103f88:	83 ec 08             	sub    $0x8,%esp
f0103f8b:	ff 75 d0             	pushl  -0x30(%ebp)
f0103f8e:	57                   	push   %edi
f0103f8f:	e8 5f 03 00 00       	call   f01042f3 <strnlen>
f0103f94:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0103f97:	29 c1                	sub    %eax,%ecx
f0103f99:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0103f9c:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0103f9f:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0103fa3:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103fa6:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0103fa9:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0103fab:	eb 0f                	jmp    f0103fbc <vprintfmt+0x1cf>
					putch(padc, putdat);
f0103fad:	83 ec 08             	sub    $0x8,%esp
f0103fb0:	53                   	push   %ebx
f0103fb1:	ff 75 e0             	pushl  -0x20(%ebp)
f0103fb4:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0103fb6:	83 ef 01             	sub    $0x1,%edi
f0103fb9:	83 c4 10             	add    $0x10,%esp
f0103fbc:	85 ff                	test   %edi,%edi
f0103fbe:	7f ed                	jg     f0103fad <vprintfmt+0x1c0>
f0103fc0:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0103fc3:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0103fc6:	85 c9                	test   %ecx,%ecx
f0103fc8:	b8 00 00 00 00       	mov    $0x0,%eax
f0103fcd:	0f 49 c1             	cmovns %ecx,%eax
f0103fd0:	29 c1                	sub    %eax,%ecx
f0103fd2:	89 75 08             	mov    %esi,0x8(%ebp)
f0103fd5:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0103fd8:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103fdb:	89 cb                	mov    %ecx,%ebx
f0103fdd:	eb 4d                	jmp    f010402c <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0103fdf:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0103fe3:	74 1b                	je     f0104000 <vprintfmt+0x213>
f0103fe5:	0f be c0             	movsbl %al,%eax
f0103fe8:	83 e8 20             	sub    $0x20,%eax
f0103feb:	83 f8 5e             	cmp    $0x5e,%eax
f0103fee:	76 10                	jbe    f0104000 <vprintfmt+0x213>
					putch('?', putdat);
f0103ff0:	83 ec 08             	sub    $0x8,%esp
f0103ff3:	ff 75 0c             	pushl  0xc(%ebp)
f0103ff6:	6a 3f                	push   $0x3f
f0103ff8:	ff 55 08             	call   *0x8(%ebp)
f0103ffb:	83 c4 10             	add    $0x10,%esp
f0103ffe:	eb 0d                	jmp    f010400d <vprintfmt+0x220>
				else
					putch(ch, putdat);
f0104000:	83 ec 08             	sub    $0x8,%esp
f0104003:	ff 75 0c             	pushl  0xc(%ebp)
f0104006:	52                   	push   %edx
f0104007:	ff 55 08             	call   *0x8(%ebp)
f010400a:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f010400d:	83 eb 01             	sub    $0x1,%ebx
f0104010:	eb 1a                	jmp    f010402c <vprintfmt+0x23f>
f0104012:	89 75 08             	mov    %esi,0x8(%ebp)
f0104015:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0104018:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f010401b:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f010401e:	eb 0c                	jmp    f010402c <vprintfmt+0x23f>
f0104020:	89 75 08             	mov    %esi,0x8(%ebp)
f0104023:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0104026:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0104029:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f010402c:	83 c7 01             	add    $0x1,%edi
f010402f:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0104033:	0f be d0             	movsbl %al,%edx
f0104036:	85 d2                	test   %edx,%edx
f0104038:	74 23                	je     f010405d <vprintfmt+0x270>
f010403a:	85 f6                	test   %esi,%esi
f010403c:	78 a1                	js     f0103fdf <vprintfmt+0x1f2>
f010403e:	83 ee 01             	sub    $0x1,%esi
f0104041:	79 9c                	jns    f0103fdf <vprintfmt+0x1f2>
f0104043:	89 df                	mov    %ebx,%edi
f0104045:	8b 75 08             	mov    0x8(%ebp),%esi
f0104048:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010404b:	eb 18                	jmp    f0104065 <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f010404d:	83 ec 08             	sub    $0x8,%esp
f0104050:	53                   	push   %ebx
f0104051:	6a 20                	push   $0x20
f0104053:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0104055:	83 ef 01             	sub    $0x1,%edi
f0104058:	83 c4 10             	add    $0x10,%esp
f010405b:	eb 08                	jmp    f0104065 <vprintfmt+0x278>
f010405d:	89 df                	mov    %ebx,%edi
f010405f:	8b 75 08             	mov    0x8(%ebp),%esi
f0104062:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104065:	85 ff                	test   %edi,%edi
f0104067:	7f e4                	jg     f010404d <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104069:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010406c:	e9 a2 fd ff ff       	jmp    f0103e13 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0104071:	83 fa 01             	cmp    $0x1,%edx
f0104074:	7e 16                	jle    f010408c <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f0104076:	8b 45 14             	mov    0x14(%ebp),%eax
f0104079:	8d 50 08             	lea    0x8(%eax),%edx
f010407c:	89 55 14             	mov    %edx,0x14(%ebp)
f010407f:	8b 50 04             	mov    0x4(%eax),%edx
f0104082:	8b 00                	mov    (%eax),%eax
f0104084:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104087:	89 55 dc             	mov    %edx,-0x24(%ebp)
f010408a:	eb 32                	jmp    f01040be <vprintfmt+0x2d1>
	else if (lflag)
f010408c:	85 d2                	test   %edx,%edx
f010408e:	74 18                	je     f01040a8 <vprintfmt+0x2bb>
		return va_arg(*ap, long);
f0104090:	8b 45 14             	mov    0x14(%ebp),%eax
f0104093:	8d 50 04             	lea    0x4(%eax),%edx
f0104096:	89 55 14             	mov    %edx,0x14(%ebp)
f0104099:	8b 00                	mov    (%eax),%eax
f010409b:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010409e:	89 c1                	mov    %eax,%ecx
f01040a0:	c1 f9 1f             	sar    $0x1f,%ecx
f01040a3:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f01040a6:	eb 16                	jmp    f01040be <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
f01040a8:	8b 45 14             	mov    0x14(%ebp),%eax
f01040ab:	8d 50 04             	lea    0x4(%eax),%edx
f01040ae:	89 55 14             	mov    %edx,0x14(%ebp)
f01040b1:	8b 00                	mov    (%eax),%eax
f01040b3:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01040b6:	89 c1                	mov    %eax,%ecx
f01040b8:	c1 f9 1f             	sar    $0x1f,%ecx
f01040bb:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f01040be:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01040c1:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f01040c4:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f01040c9:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f01040cd:	79 74                	jns    f0104143 <vprintfmt+0x356>
				putch('-', putdat);
f01040cf:	83 ec 08             	sub    $0x8,%esp
f01040d2:	53                   	push   %ebx
f01040d3:	6a 2d                	push   $0x2d
f01040d5:	ff d6                	call   *%esi
				num = -(long long) num;
f01040d7:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01040da:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01040dd:	f7 d8                	neg    %eax
f01040df:	83 d2 00             	adc    $0x0,%edx
f01040e2:	f7 da                	neg    %edx
f01040e4:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f01040e7:	b9 0a 00 00 00       	mov    $0xa,%ecx
f01040ec:	eb 55                	jmp    f0104143 <vprintfmt+0x356>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f01040ee:	8d 45 14             	lea    0x14(%ebp),%eax
f01040f1:	e8 83 fc ff ff       	call   f0103d79 <getuint>
			base = 10;
f01040f6:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f01040fb:	eb 46                	jmp    f0104143 <vprintfmt+0x356>
		// (unsigned) octal
		case 'o':
			//putch('X', putdat);
			//putch('X', putdat);
			//putch('X', putdat);
			num = getuint(&ap, lflag);
f01040fd:	8d 45 14             	lea    0x14(%ebp),%eax
f0104100:	e8 74 fc ff ff       	call   f0103d79 <getuint>
			base = 8;
f0104105:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f010410a:	eb 37                	jmp    f0104143 <vprintfmt+0x356>

		// pointer
		case 'p':
			putch('0', putdat);
f010410c:	83 ec 08             	sub    $0x8,%esp
f010410f:	53                   	push   %ebx
f0104110:	6a 30                	push   $0x30
f0104112:	ff d6                	call   *%esi
			putch('x', putdat);
f0104114:	83 c4 08             	add    $0x8,%esp
f0104117:	53                   	push   %ebx
f0104118:	6a 78                	push   $0x78
f010411a:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f010411c:	8b 45 14             	mov    0x14(%ebp),%eax
f010411f:	8d 50 04             	lea    0x4(%eax),%edx
f0104122:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0104125:	8b 00                	mov    (%eax),%eax
f0104127:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f010412c:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f010412f:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0104134:	eb 0d                	jmp    f0104143 <vprintfmt+0x356>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0104136:	8d 45 14             	lea    0x14(%ebp),%eax
f0104139:	e8 3b fc ff ff       	call   f0103d79 <getuint>
			base = 16;
f010413e:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0104143:	83 ec 0c             	sub    $0xc,%esp
f0104146:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f010414a:	57                   	push   %edi
f010414b:	ff 75 e0             	pushl  -0x20(%ebp)
f010414e:	51                   	push   %ecx
f010414f:	52                   	push   %edx
f0104150:	50                   	push   %eax
f0104151:	89 da                	mov    %ebx,%edx
f0104153:	89 f0                	mov    %esi,%eax
f0104155:	e8 70 fb ff ff       	call   f0103cca <printnum>
			break;
f010415a:	83 c4 20             	add    $0x20,%esp
f010415d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104160:	e9 ae fc ff ff       	jmp    f0103e13 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0104165:	83 ec 08             	sub    $0x8,%esp
f0104168:	53                   	push   %ebx
f0104169:	51                   	push   %ecx
f010416a:	ff d6                	call   *%esi
			break;
f010416c:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010416f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0104172:	e9 9c fc ff ff       	jmp    f0103e13 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0104177:	83 ec 08             	sub    $0x8,%esp
f010417a:	53                   	push   %ebx
f010417b:	6a 25                	push   $0x25
f010417d:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f010417f:	83 c4 10             	add    $0x10,%esp
f0104182:	eb 03                	jmp    f0104187 <vprintfmt+0x39a>
f0104184:	83 ef 01             	sub    $0x1,%edi
f0104187:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f010418b:	75 f7                	jne    f0104184 <vprintfmt+0x397>
f010418d:	e9 81 fc ff ff       	jmp    f0103e13 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0104192:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104195:	5b                   	pop    %ebx
f0104196:	5e                   	pop    %esi
f0104197:	5f                   	pop    %edi
f0104198:	5d                   	pop    %ebp
f0104199:	c3                   	ret    

f010419a <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f010419a:	55                   	push   %ebp
f010419b:	89 e5                	mov    %esp,%ebp
f010419d:	83 ec 18             	sub    $0x18,%esp
f01041a0:	8b 45 08             	mov    0x8(%ebp),%eax
f01041a3:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01041a6:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01041a9:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01041ad:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01041b0:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01041b7:	85 c0                	test   %eax,%eax
f01041b9:	74 26                	je     f01041e1 <vsnprintf+0x47>
f01041bb:	85 d2                	test   %edx,%edx
f01041bd:	7e 22                	jle    f01041e1 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01041bf:	ff 75 14             	pushl  0x14(%ebp)
f01041c2:	ff 75 10             	pushl  0x10(%ebp)
f01041c5:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01041c8:	50                   	push   %eax
f01041c9:	68 b3 3d 10 f0       	push   $0xf0103db3
f01041ce:	e8 1a fc ff ff       	call   f0103ded <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01041d3:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01041d6:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01041d9:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01041dc:	83 c4 10             	add    $0x10,%esp
f01041df:	eb 05                	jmp    f01041e6 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f01041e1:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f01041e6:	c9                   	leave  
f01041e7:	c3                   	ret    

f01041e8 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01041e8:	55                   	push   %ebp
f01041e9:	89 e5                	mov    %esp,%ebp
f01041eb:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01041ee:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01041f1:	50                   	push   %eax
f01041f2:	ff 75 10             	pushl  0x10(%ebp)
f01041f5:	ff 75 0c             	pushl  0xc(%ebp)
f01041f8:	ff 75 08             	pushl  0x8(%ebp)
f01041fb:	e8 9a ff ff ff       	call   f010419a <vsnprintf>
	va_end(ap);

	return rc;
}
f0104200:	c9                   	leave  
f0104201:	c3                   	ret    

f0104202 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0104202:	55                   	push   %ebp
f0104203:	89 e5                	mov    %esp,%ebp
f0104205:	57                   	push   %edi
f0104206:	56                   	push   %esi
f0104207:	53                   	push   %ebx
f0104208:	83 ec 0c             	sub    $0xc,%esp
f010420b:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010420e:	85 c0                	test   %eax,%eax
f0104210:	74 11                	je     f0104223 <readline+0x21>
		cprintf("%s", prompt);
f0104212:	83 ec 08             	sub    $0x8,%esp
f0104215:	50                   	push   %eax
f0104216:	68 2c 56 10 f0       	push   $0xf010562c
f010421b:	e8 e0 ec ff ff       	call   f0102f00 <cprintf>
f0104220:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0104223:	83 ec 0c             	sub    $0xc,%esp
f0104226:	6a 00                	push   $0x0
f0104228:	e8 09 c4 ff ff       	call   f0100636 <iscons>
f010422d:	89 c7                	mov    %eax,%edi
f010422f:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0104232:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0104237:	e8 e9 c3 ff ff       	call   f0100625 <getchar>
f010423c:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010423e:	85 c0                	test   %eax,%eax
f0104240:	79 18                	jns    f010425a <readline+0x58>
			cprintf("read error: %e\n", c);
f0104242:	83 ec 08             	sub    $0x8,%esp
f0104245:	50                   	push   %eax
f0104246:	68 50 60 10 f0       	push   $0xf0106050
f010424b:	e8 b0 ec ff ff       	call   f0102f00 <cprintf>
			return NULL;
f0104250:	83 c4 10             	add    $0x10,%esp
f0104253:	b8 00 00 00 00       	mov    $0x0,%eax
f0104258:	eb 79                	jmp    f01042d3 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f010425a:	83 f8 08             	cmp    $0x8,%eax
f010425d:	0f 94 c2             	sete   %dl
f0104260:	83 f8 7f             	cmp    $0x7f,%eax
f0104263:	0f 94 c0             	sete   %al
f0104266:	08 c2                	or     %al,%dl
f0104268:	74 1a                	je     f0104284 <readline+0x82>
f010426a:	85 f6                	test   %esi,%esi
f010426c:	7e 16                	jle    f0104284 <readline+0x82>
			if (echoing)
f010426e:	85 ff                	test   %edi,%edi
f0104270:	74 0d                	je     f010427f <readline+0x7d>
				cputchar('\b');
f0104272:	83 ec 0c             	sub    $0xc,%esp
f0104275:	6a 08                	push   $0x8
f0104277:	e8 99 c3 ff ff       	call   f0100615 <cputchar>
f010427c:	83 c4 10             	add    $0x10,%esp
			i--;
f010427f:	83 ee 01             	sub    $0x1,%esi
f0104282:	eb b3                	jmp    f0104237 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0104284:	83 fb 1f             	cmp    $0x1f,%ebx
f0104287:	7e 23                	jle    f01042ac <readline+0xaa>
f0104289:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010428f:	7f 1b                	jg     f01042ac <readline+0xaa>
			if (echoing)
f0104291:	85 ff                	test   %edi,%edi
f0104293:	74 0c                	je     f01042a1 <readline+0x9f>
				cputchar(c);
f0104295:	83 ec 0c             	sub    $0xc,%esp
f0104298:	53                   	push   %ebx
f0104299:	e8 77 c3 ff ff       	call   f0100615 <cputchar>
f010429e:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f01042a1:	88 9e 40 28 17 f0    	mov    %bl,-0xfe8d7c0(%esi)
f01042a7:	8d 76 01             	lea    0x1(%esi),%esi
f01042aa:	eb 8b                	jmp    f0104237 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f01042ac:	83 fb 0a             	cmp    $0xa,%ebx
f01042af:	74 05                	je     f01042b6 <readline+0xb4>
f01042b1:	83 fb 0d             	cmp    $0xd,%ebx
f01042b4:	75 81                	jne    f0104237 <readline+0x35>
			if (echoing)
f01042b6:	85 ff                	test   %edi,%edi
f01042b8:	74 0d                	je     f01042c7 <readline+0xc5>
				cputchar('\n');
f01042ba:	83 ec 0c             	sub    $0xc,%esp
f01042bd:	6a 0a                	push   $0xa
f01042bf:	e8 51 c3 ff ff       	call   f0100615 <cputchar>
f01042c4:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f01042c7:	c6 86 40 28 17 f0 00 	movb   $0x0,-0xfe8d7c0(%esi)
			return buf;
f01042ce:	b8 40 28 17 f0       	mov    $0xf0172840,%eax
		}
	}
}
f01042d3:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01042d6:	5b                   	pop    %ebx
f01042d7:	5e                   	pop    %esi
f01042d8:	5f                   	pop    %edi
f01042d9:	5d                   	pop    %ebp
f01042da:	c3                   	ret    

f01042db <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01042db:	55                   	push   %ebp
f01042dc:	89 e5                	mov    %esp,%ebp
f01042de:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01042e1:	b8 00 00 00 00       	mov    $0x0,%eax
f01042e6:	eb 03                	jmp    f01042eb <strlen+0x10>
		n++;
f01042e8:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01042eb:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01042ef:	75 f7                	jne    f01042e8 <strlen+0xd>
		n++;
	return n;
}
f01042f1:	5d                   	pop    %ebp
f01042f2:	c3                   	ret    

f01042f3 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01042f3:	55                   	push   %ebp
f01042f4:	89 e5                	mov    %esp,%ebp
f01042f6:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01042f9:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01042fc:	ba 00 00 00 00       	mov    $0x0,%edx
f0104301:	eb 03                	jmp    f0104306 <strnlen+0x13>
		n++;
f0104303:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0104306:	39 c2                	cmp    %eax,%edx
f0104308:	74 08                	je     f0104312 <strnlen+0x1f>
f010430a:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f010430e:	75 f3                	jne    f0104303 <strnlen+0x10>
f0104310:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0104312:	5d                   	pop    %ebp
f0104313:	c3                   	ret    

f0104314 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0104314:	55                   	push   %ebp
f0104315:	89 e5                	mov    %esp,%ebp
f0104317:	53                   	push   %ebx
f0104318:	8b 45 08             	mov    0x8(%ebp),%eax
f010431b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f010431e:	89 c2                	mov    %eax,%edx
f0104320:	83 c2 01             	add    $0x1,%edx
f0104323:	83 c1 01             	add    $0x1,%ecx
f0104326:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f010432a:	88 5a ff             	mov    %bl,-0x1(%edx)
f010432d:	84 db                	test   %bl,%bl
f010432f:	75 ef                	jne    f0104320 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0104331:	5b                   	pop    %ebx
f0104332:	5d                   	pop    %ebp
f0104333:	c3                   	ret    

f0104334 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0104334:	55                   	push   %ebp
f0104335:	89 e5                	mov    %esp,%ebp
f0104337:	53                   	push   %ebx
f0104338:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f010433b:	53                   	push   %ebx
f010433c:	e8 9a ff ff ff       	call   f01042db <strlen>
f0104341:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0104344:	ff 75 0c             	pushl  0xc(%ebp)
f0104347:	01 d8                	add    %ebx,%eax
f0104349:	50                   	push   %eax
f010434a:	e8 c5 ff ff ff       	call   f0104314 <strcpy>
	return dst;
}
f010434f:	89 d8                	mov    %ebx,%eax
f0104351:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0104354:	c9                   	leave  
f0104355:	c3                   	ret    

f0104356 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0104356:	55                   	push   %ebp
f0104357:	89 e5                	mov    %esp,%ebp
f0104359:	56                   	push   %esi
f010435a:	53                   	push   %ebx
f010435b:	8b 75 08             	mov    0x8(%ebp),%esi
f010435e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0104361:	89 f3                	mov    %esi,%ebx
f0104363:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104366:	89 f2                	mov    %esi,%edx
f0104368:	eb 0f                	jmp    f0104379 <strncpy+0x23>
		*dst++ = *src;
f010436a:	83 c2 01             	add    $0x1,%edx
f010436d:	0f b6 01             	movzbl (%ecx),%eax
f0104370:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0104373:	80 39 01             	cmpb   $0x1,(%ecx)
f0104376:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104379:	39 da                	cmp    %ebx,%edx
f010437b:	75 ed                	jne    f010436a <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f010437d:	89 f0                	mov    %esi,%eax
f010437f:	5b                   	pop    %ebx
f0104380:	5e                   	pop    %esi
f0104381:	5d                   	pop    %ebp
f0104382:	c3                   	ret    

f0104383 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0104383:	55                   	push   %ebp
f0104384:	89 e5                	mov    %esp,%ebp
f0104386:	56                   	push   %esi
f0104387:	53                   	push   %ebx
f0104388:	8b 75 08             	mov    0x8(%ebp),%esi
f010438b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010438e:	8b 55 10             	mov    0x10(%ebp),%edx
f0104391:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0104393:	85 d2                	test   %edx,%edx
f0104395:	74 21                	je     f01043b8 <strlcpy+0x35>
f0104397:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f010439b:	89 f2                	mov    %esi,%edx
f010439d:	eb 09                	jmp    f01043a8 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f010439f:	83 c2 01             	add    $0x1,%edx
f01043a2:	83 c1 01             	add    $0x1,%ecx
f01043a5:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f01043a8:	39 c2                	cmp    %eax,%edx
f01043aa:	74 09                	je     f01043b5 <strlcpy+0x32>
f01043ac:	0f b6 19             	movzbl (%ecx),%ebx
f01043af:	84 db                	test   %bl,%bl
f01043b1:	75 ec                	jne    f010439f <strlcpy+0x1c>
f01043b3:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f01043b5:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f01043b8:	29 f0                	sub    %esi,%eax
}
f01043ba:	5b                   	pop    %ebx
f01043bb:	5e                   	pop    %esi
f01043bc:	5d                   	pop    %ebp
f01043bd:	c3                   	ret    

f01043be <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01043be:	55                   	push   %ebp
f01043bf:	89 e5                	mov    %esp,%ebp
f01043c1:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01043c4:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01043c7:	eb 06                	jmp    f01043cf <strcmp+0x11>
		p++, q++;
f01043c9:	83 c1 01             	add    $0x1,%ecx
f01043cc:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01043cf:	0f b6 01             	movzbl (%ecx),%eax
f01043d2:	84 c0                	test   %al,%al
f01043d4:	74 04                	je     f01043da <strcmp+0x1c>
f01043d6:	3a 02                	cmp    (%edx),%al
f01043d8:	74 ef                	je     f01043c9 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01043da:	0f b6 c0             	movzbl %al,%eax
f01043dd:	0f b6 12             	movzbl (%edx),%edx
f01043e0:	29 d0                	sub    %edx,%eax
}
f01043e2:	5d                   	pop    %ebp
f01043e3:	c3                   	ret    

f01043e4 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01043e4:	55                   	push   %ebp
f01043e5:	89 e5                	mov    %esp,%ebp
f01043e7:	53                   	push   %ebx
f01043e8:	8b 45 08             	mov    0x8(%ebp),%eax
f01043eb:	8b 55 0c             	mov    0xc(%ebp),%edx
f01043ee:	89 c3                	mov    %eax,%ebx
f01043f0:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01043f3:	eb 06                	jmp    f01043fb <strncmp+0x17>
		n--, p++, q++;
f01043f5:	83 c0 01             	add    $0x1,%eax
f01043f8:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01043fb:	39 d8                	cmp    %ebx,%eax
f01043fd:	74 15                	je     f0104414 <strncmp+0x30>
f01043ff:	0f b6 08             	movzbl (%eax),%ecx
f0104402:	84 c9                	test   %cl,%cl
f0104404:	74 04                	je     f010440a <strncmp+0x26>
f0104406:	3a 0a                	cmp    (%edx),%cl
f0104408:	74 eb                	je     f01043f5 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f010440a:	0f b6 00             	movzbl (%eax),%eax
f010440d:	0f b6 12             	movzbl (%edx),%edx
f0104410:	29 d0                	sub    %edx,%eax
f0104412:	eb 05                	jmp    f0104419 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0104414:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0104419:	5b                   	pop    %ebx
f010441a:	5d                   	pop    %ebp
f010441b:	c3                   	ret    

f010441c <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010441c:	55                   	push   %ebp
f010441d:	89 e5                	mov    %esp,%ebp
f010441f:	8b 45 08             	mov    0x8(%ebp),%eax
f0104422:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0104426:	eb 07                	jmp    f010442f <strchr+0x13>
		if (*s == c)
f0104428:	38 ca                	cmp    %cl,%dl
f010442a:	74 0f                	je     f010443b <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f010442c:	83 c0 01             	add    $0x1,%eax
f010442f:	0f b6 10             	movzbl (%eax),%edx
f0104432:	84 d2                	test   %dl,%dl
f0104434:	75 f2                	jne    f0104428 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0104436:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010443b:	5d                   	pop    %ebp
f010443c:	c3                   	ret    

f010443d <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010443d:	55                   	push   %ebp
f010443e:	89 e5                	mov    %esp,%ebp
f0104440:	8b 45 08             	mov    0x8(%ebp),%eax
f0104443:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0104447:	eb 03                	jmp    f010444c <strfind+0xf>
f0104449:	83 c0 01             	add    $0x1,%eax
f010444c:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f010444f:	38 ca                	cmp    %cl,%dl
f0104451:	74 04                	je     f0104457 <strfind+0x1a>
f0104453:	84 d2                	test   %dl,%dl
f0104455:	75 f2                	jne    f0104449 <strfind+0xc>
			break;
	return (char *) s;
}
f0104457:	5d                   	pop    %ebp
f0104458:	c3                   	ret    

f0104459 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0104459:	55                   	push   %ebp
f010445a:	89 e5                	mov    %esp,%ebp
f010445c:	57                   	push   %edi
f010445d:	56                   	push   %esi
f010445e:	53                   	push   %ebx
f010445f:	8b 7d 08             	mov    0x8(%ebp),%edi
f0104462:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0104465:	85 c9                	test   %ecx,%ecx
f0104467:	74 36                	je     f010449f <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0104469:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010446f:	75 28                	jne    f0104499 <memset+0x40>
f0104471:	f6 c1 03             	test   $0x3,%cl
f0104474:	75 23                	jne    f0104499 <memset+0x40>
		c &= 0xFF;
f0104476:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f010447a:	89 d3                	mov    %edx,%ebx
f010447c:	c1 e3 08             	shl    $0x8,%ebx
f010447f:	89 d6                	mov    %edx,%esi
f0104481:	c1 e6 18             	shl    $0x18,%esi
f0104484:	89 d0                	mov    %edx,%eax
f0104486:	c1 e0 10             	shl    $0x10,%eax
f0104489:	09 f0                	or     %esi,%eax
f010448b:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f010448d:	89 d8                	mov    %ebx,%eax
f010448f:	09 d0                	or     %edx,%eax
f0104491:	c1 e9 02             	shr    $0x2,%ecx
f0104494:	fc                   	cld    
f0104495:	f3 ab                	rep stos %eax,%es:(%edi)
f0104497:	eb 06                	jmp    f010449f <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0104499:	8b 45 0c             	mov    0xc(%ebp),%eax
f010449c:	fc                   	cld    
f010449d:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f010449f:	89 f8                	mov    %edi,%eax
f01044a1:	5b                   	pop    %ebx
f01044a2:	5e                   	pop    %esi
f01044a3:	5f                   	pop    %edi
f01044a4:	5d                   	pop    %ebp
f01044a5:	c3                   	ret    

f01044a6 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01044a6:	55                   	push   %ebp
f01044a7:	89 e5                	mov    %esp,%ebp
f01044a9:	57                   	push   %edi
f01044aa:	56                   	push   %esi
f01044ab:	8b 45 08             	mov    0x8(%ebp),%eax
f01044ae:	8b 75 0c             	mov    0xc(%ebp),%esi
f01044b1:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01044b4:	39 c6                	cmp    %eax,%esi
f01044b6:	73 35                	jae    f01044ed <memmove+0x47>
f01044b8:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01044bb:	39 d0                	cmp    %edx,%eax
f01044bd:	73 2e                	jae    f01044ed <memmove+0x47>
		s += n;
		d += n;
f01044bf:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01044c2:	89 d6                	mov    %edx,%esi
f01044c4:	09 fe                	or     %edi,%esi
f01044c6:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01044cc:	75 13                	jne    f01044e1 <memmove+0x3b>
f01044ce:	f6 c1 03             	test   $0x3,%cl
f01044d1:	75 0e                	jne    f01044e1 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f01044d3:	83 ef 04             	sub    $0x4,%edi
f01044d6:	8d 72 fc             	lea    -0x4(%edx),%esi
f01044d9:	c1 e9 02             	shr    $0x2,%ecx
f01044dc:	fd                   	std    
f01044dd:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01044df:	eb 09                	jmp    f01044ea <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01044e1:	83 ef 01             	sub    $0x1,%edi
f01044e4:	8d 72 ff             	lea    -0x1(%edx),%esi
f01044e7:	fd                   	std    
f01044e8:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01044ea:	fc                   	cld    
f01044eb:	eb 1d                	jmp    f010450a <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01044ed:	89 f2                	mov    %esi,%edx
f01044ef:	09 c2                	or     %eax,%edx
f01044f1:	f6 c2 03             	test   $0x3,%dl
f01044f4:	75 0f                	jne    f0104505 <memmove+0x5f>
f01044f6:	f6 c1 03             	test   $0x3,%cl
f01044f9:	75 0a                	jne    f0104505 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f01044fb:	c1 e9 02             	shr    $0x2,%ecx
f01044fe:	89 c7                	mov    %eax,%edi
f0104500:	fc                   	cld    
f0104501:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0104503:	eb 05                	jmp    f010450a <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0104505:	89 c7                	mov    %eax,%edi
f0104507:	fc                   	cld    
f0104508:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f010450a:	5e                   	pop    %esi
f010450b:	5f                   	pop    %edi
f010450c:	5d                   	pop    %ebp
f010450d:	c3                   	ret    

f010450e <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f010450e:	55                   	push   %ebp
f010450f:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0104511:	ff 75 10             	pushl  0x10(%ebp)
f0104514:	ff 75 0c             	pushl  0xc(%ebp)
f0104517:	ff 75 08             	pushl  0x8(%ebp)
f010451a:	e8 87 ff ff ff       	call   f01044a6 <memmove>
}
f010451f:	c9                   	leave  
f0104520:	c3                   	ret    

f0104521 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0104521:	55                   	push   %ebp
f0104522:	89 e5                	mov    %esp,%ebp
f0104524:	56                   	push   %esi
f0104525:	53                   	push   %ebx
f0104526:	8b 45 08             	mov    0x8(%ebp),%eax
f0104529:	8b 55 0c             	mov    0xc(%ebp),%edx
f010452c:	89 c6                	mov    %eax,%esi
f010452e:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0104531:	eb 1a                	jmp    f010454d <memcmp+0x2c>
		if (*s1 != *s2)
f0104533:	0f b6 08             	movzbl (%eax),%ecx
f0104536:	0f b6 1a             	movzbl (%edx),%ebx
f0104539:	38 d9                	cmp    %bl,%cl
f010453b:	74 0a                	je     f0104547 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f010453d:	0f b6 c1             	movzbl %cl,%eax
f0104540:	0f b6 db             	movzbl %bl,%ebx
f0104543:	29 d8                	sub    %ebx,%eax
f0104545:	eb 0f                	jmp    f0104556 <memcmp+0x35>
		s1++, s2++;
f0104547:	83 c0 01             	add    $0x1,%eax
f010454a:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010454d:	39 f0                	cmp    %esi,%eax
f010454f:	75 e2                	jne    f0104533 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0104551:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104556:	5b                   	pop    %ebx
f0104557:	5e                   	pop    %esi
f0104558:	5d                   	pop    %ebp
f0104559:	c3                   	ret    

f010455a <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f010455a:	55                   	push   %ebp
f010455b:	89 e5                	mov    %esp,%ebp
f010455d:	53                   	push   %ebx
f010455e:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0104561:	89 c1                	mov    %eax,%ecx
f0104563:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f0104566:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010456a:	eb 0a                	jmp    f0104576 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f010456c:	0f b6 10             	movzbl (%eax),%edx
f010456f:	39 da                	cmp    %ebx,%edx
f0104571:	74 07                	je     f010457a <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0104573:	83 c0 01             	add    $0x1,%eax
f0104576:	39 c8                	cmp    %ecx,%eax
f0104578:	72 f2                	jb     f010456c <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f010457a:	5b                   	pop    %ebx
f010457b:	5d                   	pop    %ebp
f010457c:	c3                   	ret    

f010457d <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f010457d:	55                   	push   %ebp
f010457e:	89 e5                	mov    %esp,%ebp
f0104580:	57                   	push   %edi
f0104581:	56                   	push   %esi
f0104582:	53                   	push   %ebx
f0104583:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104586:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0104589:	eb 03                	jmp    f010458e <strtol+0x11>
		s++;
f010458b:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010458e:	0f b6 01             	movzbl (%ecx),%eax
f0104591:	3c 20                	cmp    $0x20,%al
f0104593:	74 f6                	je     f010458b <strtol+0xe>
f0104595:	3c 09                	cmp    $0x9,%al
f0104597:	74 f2                	je     f010458b <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0104599:	3c 2b                	cmp    $0x2b,%al
f010459b:	75 0a                	jne    f01045a7 <strtol+0x2a>
		s++;
f010459d:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01045a0:	bf 00 00 00 00       	mov    $0x0,%edi
f01045a5:	eb 11                	jmp    f01045b8 <strtol+0x3b>
f01045a7:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f01045ac:	3c 2d                	cmp    $0x2d,%al
f01045ae:	75 08                	jne    f01045b8 <strtol+0x3b>
		s++, neg = 1;
f01045b0:	83 c1 01             	add    $0x1,%ecx
f01045b3:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01045b8:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f01045be:	75 15                	jne    f01045d5 <strtol+0x58>
f01045c0:	80 39 30             	cmpb   $0x30,(%ecx)
f01045c3:	75 10                	jne    f01045d5 <strtol+0x58>
f01045c5:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f01045c9:	75 7c                	jne    f0104647 <strtol+0xca>
		s += 2, base = 16;
f01045cb:	83 c1 02             	add    $0x2,%ecx
f01045ce:	bb 10 00 00 00       	mov    $0x10,%ebx
f01045d3:	eb 16                	jmp    f01045eb <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f01045d5:	85 db                	test   %ebx,%ebx
f01045d7:	75 12                	jne    f01045eb <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01045d9:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01045de:	80 39 30             	cmpb   $0x30,(%ecx)
f01045e1:	75 08                	jne    f01045eb <strtol+0x6e>
		s++, base = 8;
f01045e3:	83 c1 01             	add    $0x1,%ecx
f01045e6:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f01045eb:	b8 00 00 00 00       	mov    $0x0,%eax
f01045f0:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f01045f3:	0f b6 11             	movzbl (%ecx),%edx
f01045f6:	8d 72 d0             	lea    -0x30(%edx),%esi
f01045f9:	89 f3                	mov    %esi,%ebx
f01045fb:	80 fb 09             	cmp    $0x9,%bl
f01045fe:	77 08                	ja     f0104608 <strtol+0x8b>
			dig = *s - '0';
f0104600:	0f be d2             	movsbl %dl,%edx
f0104603:	83 ea 30             	sub    $0x30,%edx
f0104606:	eb 22                	jmp    f010462a <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f0104608:	8d 72 9f             	lea    -0x61(%edx),%esi
f010460b:	89 f3                	mov    %esi,%ebx
f010460d:	80 fb 19             	cmp    $0x19,%bl
f0104610:	77 08                	ja     f010461a <strtol+0x9d>
			dig = *s - 'a' + 10;
f0104612:	0f be d2             	movsbl %dl,%edx
f0104615:	83 ea 57             	sub    $0x57,%edx
f0104618:	eb 10                	jmp    f010462a <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f010461a:	8d 72 bf             	lea    -0x41(%edx),%esi
f010461d:	89 f3                	mov    %esi,%ebx
f010461f:	80 fb 19             	cmp    $0x19,%bl
f0104622:	77 16                	ja     f010463a <strtol+0xbd>
			dig = *s - 'A' + 10;
f0104624:	0f be d2             	movsbl %dl,%edx
f0104627:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f010462a:	3b 55 10             	cmp    0x10(%ebp),%edx
f010462d:	7d 0b                	jge    f010463a <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f010462f:	83 c1 01             	add    $0x1,%ecx
f0104632:	0f af 45 10          	imul   0x10(%ebp),%eax
f0104636:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f0104638:	eb b9                	jmp    f01045f3 <strtol+0x76>

	if (endptr)
f010463a:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f010463e:	74 0d                	je     f010464d <strtol+0xd0>
		*endptr = (char *) s;
f0104640:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104643:	89 0e                	mov    %ecx,(%esi)
f0104645:	eb 06                	jmp    f010464d <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0104647:	85 db                	test   %ebx,%ebx
f0104649:	74 98                	je     f01045e3 <strtol+0x66>
f010464b:	eb 9e                	jmp    f01045eb <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f010464d:	89 c2                	mov    %eax,%edx
f010464f:	f7 da                	neg    %edx
f0104651:	85 ff                	test   %edi,%edi
f0104653:	0f 45 c2             	cmovne %edx,%eax
}
f0104656:	5b                   	pop    %ebx
f0104657:	5e                   	pop    %esi
f0104658:	5f                   	pop    %edi
f0104659:	5d                   	pop    %ebp
f010465a:	c3                   	ret    
f010465b:	66 90                	xchg   %ax,%ax
f010465d:	66 90                	xchg   %ax,%ax
f010465f:	90                   	nop

f0104660 <__udivdi3>:
f0104660:	55                   	push   %ebp
f0104661:	57                   	push   %edi
f0104662:	56                   	push   %esi
f0104663:	53                   	push   %ebx
f0104664:	83 ec 1c             	sub    $0x1c,%esp
f0104667:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f010466b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f010466f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0104673:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0104677:	85 f6                	test   %esi,%esi
f0104679:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010467d:	89 ca                	mov    %ecx,%edx
f010467f:	89 f8                	mov    %edi,%eax
f0104681:	75 3d                	jne    f01046c0 <__udivdi3+0x60>
f0104683:	39 cf                	cmp    %ecx,%edi
f0104685:	0f 87 c5 00 00 00    	ja     f0104750 <__udivdi3+0xf0>
f010468b:	85 ff                	test   %edi,%edi
f010468d:	89 fd                	mov    %edi,%ebp
f010468f:	75 0b                	jne    f010469c <__udivdi3+0x3c>
f0104691:	b8 01 00 00 00       	mov    $0x1,%eax
f0104696:	31 d2                	xor    %edx,%edx
f0104698:	f7 f7                	div    %edi
f010469a:	89 c5                	mov    %eax,%ebp
f010469c:	89 c8                	mov    %ecx,%eax
f010469e:	31 d2                	xor    %edx,%edx
f01046a0:	f7 f5                	div    %ebp
f01046a2:	89 c1                	mov    %eax,%ecx
f01046a4:	89 d8                	mov    %ebx,%eax
f01046a6:	89 cf                	mov    %ecx,%edi
f01046a8:	f7 f5                	div    %ebp
f01046aa:	89 c3                	mov    %eax,%ebx
f01046ac:	89 d8                	mov    %ebx,%eax
f01046ae:	89 fa                	mov    %edi,%edx
f01046b0:	83 c4 1c             	add    $0x1c,%esp
f01046b3:	5b                   	pop    %ebx
f01046b4:	5e                   	pop    %esi
f01046b5:	5f                   	pop    %edi
f01046b6:	5d                   	pop    %ebp
f01046b7:	c3                   	ret    
f01046b8:	90                   	nop
f01046b9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01046c0:	39 ce                	cmp    %ecx,%esi
f01046c2:	77 74                	ja     f0104738 <__udivdi3+0xd8>
f01046c4:	0f bd fe             	bsr    %esi,%edi
f01046c7:	83 f7 1f             	xor    $0x1f,%edi
f01046ca:	0f 84 98 00 00 00    	je     f0104768 <__udivdi3+0x108>
f01046d0:	bb 20 00 00 00       	mov    $0x20,%ebx
f01046d5:	89 f9                	mov    %edi,%ecx
f01046d7:	89 c5                	mov    %eax,%ebp
f01046d9:	29 fb                	sub    %edi,%ebx
f01046db:	d3 e6                	shl    %cl,%esi
f01046dd:	89 d9                	mov    %ebx,%ecx
f01046df:	d3 ed                	shr    %cl,%ebp
f01046e1:	89 f9                	mov    %edi,%ecx
f01046e3:	d3 e0                	shl    %cl,%eax
f01046e5:	09 ee                	or     %ebp,%esi
f01046e7:	89 d9                	mov    %ebx,%ecx
f01046e9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01046ed:	89 d5                	mov    %edx,%ebp
f01046ef:	8b 44 24 08          	mov    0x8(%esp),%eax
f01046f3:	d3 ed                	shr    %cl,%ebp
f01046f5:	89 f9                	mov    %edi,%ecx
f01046f7:	d3 e2                	shl    %cl,%edx
f01046f9:	89 d9                	mov    %ebx,%ecx
f01046fb:	d3 e8                	shr    %cl,%eax
f01046fd:	09 c2                	or     %eax,%edx
f01046ff:	89 d0                	mov    %edx,%eax
f0104701:	89 ea                	mov    %ebp,%edx
f0104703:	f7 f6                	div    %esi
f0104705:	89 d5                	mov    %edx,%ebp
f0104707:	89 c3                	mov    %eax,%ebx
f0104709:	f7 64 24 0c          	mull   0xc(%esp)
f010470d:	39 d5                	cmp    %edx,%ebp
f010470f:	72 10                	jb     f0104721 <__udivdi3+0xc1>
f0104711:	8b 74 24 08          	mov    0x8(%esp),%esi
f0104715:	89 f9                	mov    %edi,%ecx
f0104717:	d3 e6                	shl    %cl,%esi
f0104719:	39 c6                	cmp    %eax,%esi
f010471b:	73 07                	jae    f0104724 <__udivdi3+0xc4>
f010471d:	39 d5                	cmp    %edx,%ebp
f010471f:	75 03                	jne    f0104724 <__udivdi3+0xc4>
f0104721:	83 eb 01             	sub    $0x1,%ebx
f0104724:	31 ff                	xor    %edi,%edi
f0104726:	89 d8                	mov    %ebx,%eax
f0104728:	89 fa                	mov    %edi,%edx
f010472a:	83 c4 1c             	add    $0x1c,%esp
f010472d:	5b                   	pop    %ebx
f010472e:	5e                   	pop    %esi
f010472f:	5f                   	pop    %edi
f0104730:	5d                   	pop    %ebp
f0104731:	c3                   	ret    
f0104732:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0104738:	31 ff                	xor    %edi,%edi
f010473a:	31 db                	xor    %ebx,%ebx
f010473c:	89 d8                	mov    %ebx,%eax
f010473e:	89 fa                	mov    %edi,%edx
f0104740:	83 c4 1c             	add    $0x1c,%esp
f0104743:	5b                   	pop    %ebx
f0104744:	5e                   	pop    %esi
f0104745:	5f                   	pop    %edi
f0104746:	5d                   	pop    %ebp
f0104747:	c3                   	ret    
f0104748:	90                   	nop
f0104749:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104750:	89 d8                	mov    %ebx,%eax
f0104752:	f7 f7                	div    %edi
f0104754:	31 ff                	xor    %edi,%edi
f0104756:	89 c3                	mov    %eax,%ebx
f0104758:	89 d8                	mov    %ebx,%eax
f010475a:	89 fa                	mov    %edi,%edx
f010475c:	83 c4 1c             	add    $0x1c,%esp
f010475f:	5b                   	pop    %ebx
f0104760:	5e                   	pop    %esi
f0104761:	5f                   	pop    %edi
f0104762:	5d                   	pop    %ebp
f0104763:	c3                   	ret    
f0104764:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104768:	39 ce                	cmp    %ecx,%esi
f010476a:	72 0c                	jb     f0104778 <__udivdi3+0x118>
f010476c:	31 db                	xor    %ebx,%ebx
f010476e:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0104772:	0f 87 34 ff ff ff    	ja     f01046ac <__udivdi3+0x4c>
f0104778:	bb 01 00 00 00       	mov    $0x1,%ebx
f010477d:	e9 2a ff ff ff       	jmp    f01046ac <__udivdi3+0x4c>
f0104782:	66 90                	xchg   %ax,%ax
f0104784:	66 90                	xchg   %ax,%ax
f0104786:	66 90                	xchg   %ax,%ax
f0104788:	66 90                	xchg   %ax,%ax
f010478a:	66 90                	xchg   %ax,%ax
f010478c:	66 90                	xchg   %ax,%ax
f010478e:	66 90                	xchg   %ax,%ax

f0104790 <__umoddi3>:
f0104790:	55                   	push   %ebp
f0104791:	57                   	push   %edi
f0104792:	56                   	push   %esi
f0104793:	53                   	push   %ebx
f0104794:	83 ec 1c             	sub    $0x1c,%esp
f0104797:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010479b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f010479f:	8b 74 24 34          	mov    0x34(%esp),%esi
f01047a3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01047a7:	85 d2                	test   %edx,%edx
f01047a9:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01047ad:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01047b1:	89 f3                	mov    %esi,%ebx
f01047b3:	89 3c 24             	mov    %edi,(%esp)
f01047b6:	89 74 24 04          	mov    %esi,0x4(%esp)
f01047ba:	75 1c                	jne    f01047d8 <__umoddi3+0x48>
f01047bc:	39 f7                	cmp    %esi,%edi
f01047be:	76 50                	jbe    f0104810 <__umoddi3+0x80>
f01047c0:	89 c8                	mov    %ecx,%eax
f01047c2:	89 f2                	mov    %esi,%edx
f01047c4:	f7 f7                	div    %edi
f01047c6:	89 d0                	mov    %edx,%eax
f01047c8:	31 d2                	xor    %edx,%edx
f01047ca:	83 c4 1c             	add    $0x1c,%esp
f01047cd:	5b                   	pop    %ebx
f01047ce:	5e                   	pop    %esi
f01047cf:	5f                   	pop    %edi
f01047d0:	5d                   	pop    %ebp
f01047d1:	c3                   	ret    
f01047d2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01047d8:	39 f2                	cmp    %esi,%edx
f01047da:	89 d0                	mov    %edx,%eax
f01047dc:	77 52                	ja     f0104830 <__umoddi3+0xa0>
f01047de:	0f bd ea             	bsr    %edx,%ebp
f01047e1:	83 f5 1f             	xor    $0x1f,%ebp
f01047e4:	75 5a                	jne    f0104840 <__umoddi3+0xb0>
f01047e6:	3b 54 24 04          	cmp    0x4(%esp),%edx
f01047ea:	0f 82 e0 00 00 00    	jb     f01048d0 <__umoddi3+0x140>
f01047f0:	39 0c 24             	cmp    %ecx,(%esp)
f01047f3:	0f 86 d7 00 00 00    	jbe    f01048d0 <__umoddi3+0x140>
f01047f9:	8b 44 24 08          	mov    0x8(%esp),%eax
f01047fd:	8b 54 24 04          	mov    0x4(%esp),%edx
f0104801:	83 c4 1c             	add    $0x1c,%esp
f0104804:	5b                   	pop    %ebx
f0104805:	5e                   	pop    %esi
f0104806:	5f                   	pop    %edi
f0104807:	5d                   	pop    %ebp
f0104808:	c3                   	ret    
f0104809:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104810:	85 ff                	test   %edi,%edi
f0104812:	89 fd                	mov    %edi,%ebp
f0104814:	75 0b                	jne    f0104821 <__umoddi3+0x91>
f0104816:	b8 01 00 00 00       	mov    $0x1,%eax
f010481b:	31 d2                	xor    %edx,%edx
f010481d:	f7 f7                	div    %edi
f010481f:	89 c5                	mov    %eax,%ebp
f0104821:	89 f0                	mov    %esi,%eax
f0104823:	31 d2                	xor    %edx,%edx
f0104825:	f7 f5                	div    %ebp
f0104827:	89 c8                	mov    %ecx,%eax
f0104829:	f7 f5                	div    %ebp
f010482b:	89 d0                	mov    %edx,%eax
f010482d:	eb 99                	jmp    f01047c8 <__umoddi3+0x38>
f010482f:	90                   	nop
f0104830:	89 c8                	mov    %ecx,%eax
f0104832:	89 f2                	mov    %esi,%edx
f0104834:	83 c4 1c             	add    $0x1c,%esp
f0104837:	5b                   	pop    %ebx
f0104838:	5e                   	pop    %esi
f0104839:	5f                   	pop    %edi
f010483a:	5d                   	pop    %ebp
f010483b:	c3                   	ret    
f010483c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104840:	8b 34 24             	mov    (%esp),%esi
f0104843:	bf 20 00 00 00       	mov    $0x20,%edi
f0104848:	89 e9                	mov    %ebp,%ecx
f010484a:	29 ef                	sub    %ebp,%edi
f010484c:	d3 e0                	shl    %cl,%eax
f010484e:	89 f9                	mov    %edi,%ecx
f0104850:	89 f2                	mov    %esi,%edx
f0104852:	d3 ea                	shr    %cl,%edx
f0104854:	89 e9                	mov    %ebp,%ecx
f0104856:	09 c2                	or     %eax,%edx
f0104858:	89 d8                	mov    %ebx,%eax
f010485a:	89 14 24             	mov    %edx,(%esp)
f010485d:	89 f2                	mov    %esi,%edx
f010485f:	d3 e2                	shl    %cl,%edx
f0104861:	89 f9                	mov    %edi,%ecx
f0104863:	89 54 24 04          	mov    %edx,0x4(%esp)
f0104867:	8b 54 24 0c          	mov    0xc(%esp),%edx
f010486b:	d3 e8                	shr    %cl,%eax
f010486d:	89 e9                	mov    %ebp,%ecx
f010486f:	89 c6                	mov    %eax,%esi
f0104871:	d3 e3                	shl    %cl,%ebx
f0104873:	89 f9                	mov    %edi,%ecx
f0104875:	89 d0                	mov    %edx,%eax
f0104877:	d3 e8                	shr    %cl,%eax
f0104879:	89 e9                	mov    %ebp,%ecx
f010487b:	09 d8                	or     %ebx,%eax
f010487d:	89 d3                	mov    %edx,%ebx
f010487f:	89 f2                	mov    %esi,%edx
f0104881:	f7 34 24             	divl   (%esp)
f0104884:	89 d6                	mov    %edx,%esi
f0104886:	d3 e3                	shl    %cl,%ebx
f0104888:	f7 64 24 04          	mull   0x4(%esp)
f010488c:	39 d6                	cmp    %edx,%esi
f010488e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0104892:	89 d1                	mov    %edx,%ecx
f0104894:	89 c3                	mov    %eax,%ebx
f0104896:	72 08                	jb     f01048a0 <__umoddi3+0x110>
f0104898:	75 11                	jne    f01048ab <__umoddi3+0x11b>
f010489a:	39 44 24 08          	cmp    %eax,0x8(%esp)
f010489e:	73 0b                	jae    f01048ab <__umoddi3+0x11b>
f01048a0:	2b 44 24 04          	sub    0x4(%esp),%eax
f01048a4:	1b 14 24             	sbb    (%esp),%edx
f01048a7:	89 d1                	mov    %edx,%ecx
f01048a9:	89 c3                	mov    %eax,%ebx
f01048ab:	8b 54 24 08          	mov    0x8(%esp),%edx
f01048af:	29 da                	sub    %ebx,%edx
f01048b1:	19 ce                	sbb    %ecx,%esi
f01048b3:	89 f9                	mov    %edi,%ecx
f01048b5:	89 f0                	mov    %esi,%eax
f01048b7:	d3 e0                	shl    %cl,%eax
f01048b9:	89 e9                	mov    %ebp,%ecx
f01048bb:	d3 ea                	shr    %cl,%edx
f01048bd:	89 e9                	mov    %ebp,%ecx
f01048bf:	d3 ee                	shr    %cl,%esi
f01048c1:	09 d0                	or     %edx,%eax
f01048c3:	89 f2                	mov    %esi,%edx
f01048c5:	83 c4 1c             	add    $0x1c,%esp
f01048c8:	5b                   	pop    %ebx
f01048c9:	5e                   	pop    %esi
f01048ca:	5f                   	pop    %edi
f01048cb:	5d                   	pop    %ebp
f01048cc:	c3                   	ret    
f01048cd:	8d 76 00             	lea    0x0(%esi),%esi
f01048d0:	29 f9                	sub    %edi,%ecx
f01048d2:	19 d6                	sbb    %edx,%esi
f01048d4:	89 74 24 04          	mov    %esi,0x4(%esp)
f01048d8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01048dc:	e9 18 ff ff ff       	jmp    f01047f9 <__umoddi3+0x69>
