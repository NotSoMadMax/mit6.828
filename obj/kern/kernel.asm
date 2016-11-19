
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
f0100015:	b8 00 80 11 00       	mov    $0x118000,%eax
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
f0100034:	bc 00 80 11 f0       	mov    $0xf0118000,%esp

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
f0100046:	b8 50 0c 17 f0       	mov    $0xf0170c50,%eax
f010004b:	2d 26 fd 16 f0       	sub    $0xf016fd26,%eax
f0100050:	50                   	push   %eax
f0100051:	6a 00                	push   $0x0
f0100053:	68 26 fd 16 f0       	push   $0xf016fd26
f0100058:	e8 7e 3c 00 00       	call   f0103cdb <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 ab 04 00 00       	call   f010050d <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 80 41 10 f0       	push   $0xf0104180
f010006f:	e8 e3 2d 00 00       	call   f0102e57 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 10 10 00 00       	call   f0101089 <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f0100079:	e8 3b 28 00 00       	call   f01028b9 <env_init>
	trap_init();
f010007e:	e8 45 2e 00 00       	call   f0102ec8 <trap_init>
#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
#else
	// Touch all you want.
	ENV_CREATE(user_hello, ENV_TYPE_USER);
f0100083:	83 c4 08             	add    $0x8,%esp
f0100086:	6a 00                	push   $0x0
f0100088:	68 56 a3 11 f0       	push   $0xf011a356
f010008d:	e8 d3 29 00 00       	call   f0102a65 <env_create>
#endif // TEST*

	// We only have one user environment for now, so just run it.
	env_run(&envs[0]);
f0100092:	83 c4 04             	add    $0x4,%esp
f0100095:	ff 35 84 ff 16 f0    	pushl  0xf016ff84
f010009b:	e8 df 2c 00 00       	call   f0102d7f <env_run>

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
f01000a8:	83 3d 40 0c 17 f0 00 	cmpl   $0x0,0xf0170c40
f01000af:	75 37                	jne    f01000e8 <_panic+0x48>
		goto dead;
	panicstr = fmt;
f01000b1:	89 35 40 0c 17 f0    	mov    %esi,0xf0170c40

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
f01000c5:	68 9b 41 10 f0       	push   $0xf010419b
f01000ca:	e8 88 2d 00 00       	call   f0102e57 <cprintf>
	vcprintf(fmt, ap);
f01000cf:	83 c4 08             	add    $0x8,%esp
f01000d2:	53                   	push   %ebx
f01000d3:	56                   	push   %esi
f01000d4:	e8 58 2d 00 00       	call   f0102e31 <vcprintf>
	cprintf("\n");
f01000d9:	c7 04 24 ed 50 10 f0 	movl   $0xf01050ed,(%esp)
f01000e0:	e8 72 2d 00 00       	call   f0102e57 <cprintf>
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
f0100107:	68 b3 41 10 f0       	push   $0xf01041b3
f010010c:	e8 46 2d 00 00       	call   f0102e57 <cprintf>
	vcprintf(fmt, ap);
f0100111:	83 c4 08             	add    $0x8,%esp
f0100114:	53                   	push   %ebx
f0100115:	ff 75 10             	pushl  0x10(%ebp)
f0100118:	e8 14 2d 00 00       	call   f0102e31 <vcprintf>
	cprintf("\n");
f010011d:	c7 04 24 ed 50 10 f0 	movl   $0xf01050ed,(%esp)
f0100124:	e8 2e 2d 00 00       	call   f0102e57 <cprintf>
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
f010015f:	8b 0d 64 ff 16 f0    	mov    0xf016ff64,%ecx
f0100165:	8d 51 01             	lea    0x1(%ecx),%edx
f0100168:	89 15 64 ff 16 f0    	mov    %edx,0xf016ff64
f010016e:	88 81 60 fd 16 f0    	mov    %al,-0xfe902a0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f0100174:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010017a:	75 0a                	jne    f0100186 <cons_intr+0x36>
			cons.wpos = 0;
f010017c:	c7 05 64 ff 16 f0 00 	movl   $0x0,0xf016ff64
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
f01001b5:	83 0d 40 fd 16 f0 40 	orl    $0x40,0xf016fd40
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
f01001cd:	8b 0d 40 fd 16 f0    	mov    0xf016fd40,%ecx
f01001d3:	89 cb                	mov    %ecx,%ebx
f01001d5:	83 e3 40             	and    $0x40,%ebx
f01001d8:	83 e0 7f             	and    $0x7f,%eax
f01001db:	85 db                	test   %ebx,%ebx
f01001dd:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01001e0:	0f b6 d2             	movzbl %dl,%edx
f01001e3:	0f b6 82 20 43 10 f0 	movzbl -0xfefbce0(%edx),%eax
f01001ea:	83 c8 40             	or     $0x40,%eax
f01001ed:	0f b6 c0             	movzbl %al,%eax
f01001f0:	f7 d0                	not    %eax
f01001f2:	21 c8                	and    %ecx,%eax
f01001f4:	a3 40 fd 16 f0       	mov    %eax,0xf016fd40
		return 0;
f01001f9:	b8 00 00 00 00       	mov    $0x0,%eax
f01001fe:	e9 a4 00 00 00       	jmp    f01002a7 <kbd_proc_data+0x114>
	} else if (shift & E0ESC) {
f0100203:	8b 0d 40 fd 16 f0    	mov    0xf016fd40,%ecx
f0100209:	f6 c1 40             	test   $0x40,%cl
f010020c:	74 0e                	je     f010021c <kbd_proc_data+0x89>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f010020e:	83 c8 80             	or     $0xffffff80,%eax
f0100211:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100213:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100216:	89 0d 40 fd 16 f0    	mov    %ecx,0xf016fd40
	}

	shift |= shiftcode[data];
f010021c:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f010021f:	0f b6 82 20 43 10 f0 	movzbl -0xfefbce0(%edx),%eax
f0100226:	0b 05 40 fd 16 f0    	or     0xf016fd40,%eax
f010022c:	0f b6 8a 20 42 10 f0 	movzbl -0xfefbde0(%edx),%ecx
f0100233:	31 c8                	xor    %ecx,%eax
f0100235:	a3 40 fd 16 f0       	mov    %eax,0xf016fd40

	c = charcode[shift & (CTL | SHIFT)][data];
f010023a:	89 c1                	mov    %eax,%ecx
f010023c:	83 e1 03             	and    $0x3,%ecx
f010023f:	8b 0c 8d 00 42 10 f0 	mov    -0xfefbe00(,%ecx,4),%ecx
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
f010027d:	68 cd 41 10 f0       	push   $0xf01041cd
f0100282:	e8 d0 2b 00 00       	call   f0102e57 <cprintf>
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
f0100369:	0f b7 05 68 ff 16 f0 	movzwl 0xf016ff68,%eax
f0100370:	66 85 c0             	test   %ax,%ax
f0100373:	0f 84 e6 00 00 00    	je     f010045f <cons_putc+0x1b3>
			crt_pos--;
f0100379:	83 e8 01             	sub    $0x1,%eax
f010037c:	66 a3 68 ff 16 f0    	mov    %ax,0xf016ff68
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100382:	0f b7 c0             	movzwl %ax,%eax
f0100385:	66 81 e7 00 ff       	and    $0xff00,%di
f010038a:	83 cf 20             	or     $0x20,%edi
f010038d:	8b 15 6c ff 16 f0    	mov    0xf016ff6c,%edx
f0100393:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100397:	eb 78                	jmp    f0100411 <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100399:	66 83 05 68 ff 16 f0 	addw   $0x50,0xf016ff68
f01003a0:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01003a1:	0f b7 05 68 ff 16 f0 	movzwl 0xf016ff68,%eax
f01003a8:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003ae:	c1 e8 16             	shr    $0x16,%eax
f01003b1:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003b4:	c1 e0 04             	shl    $0x4,%eax
f01003b7:	66 a3 68 ff 16 f0    	mov    %ax,0xf016ff68
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
f01003f3:	0f b7 05 68 ff 16 f0 	movzwl 0xf016ff68,%eax
f01003fa:	8d 50 01             	lea    0x1(%eax),%edx
f01003fd:	66 89 15 68 ff 16 f0 	mov    %dx,0xf016ff68
f0100404:	0f b7 c0             	movzwl %ax,%eax
f0100407:	8b 15 6c ff 16 f0    	mov    0xf016ff6c,%edx
f010040d:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100411:	66 81 3d 68 ff 16 f0 	cmpw   $0x7cf,0xf016ff68
f0100418:	cf 07 
f010041a:	76 43                	jbe    f010045f <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010041c:	a1 6c ff 16 f0       	mov    0xf016ff6c,%eax
f0100421:	83 ec 04             	sub    $0x4,%esp
f0100424:	68 00 0f 00 00       	push   $0xf00
f0100429:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f010042f:	52                   	push   %edx
f0100430:	50                   	push   %eax
f0100431:	e8 f2 38 00 00       	call   f0103d28 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100436:	8b 15 6c ff 16 f0    	mov    0xf016ff6c,%edx
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
f0100457:	66 83 2d 68 ff 16 f0 	subw   $0x50,0xf016ff68
f010045e:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f010045f:	8b 0d 70 ff 16 f0    	mov    0xf016ff70,%ecx
f0100465:	b8 0e 00 00 00       	mov    $0xe,%eax
f010046a:	89 ca                	mov    %ecx,%edx
f010046c:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010046d:	0f b7 1d 68 ff 16 f0 	movzwl 0xf016ff68,%ebx
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
f0100495:	80 3d 74 ff 16 f0 00 	cmpb   $0x0,0xf016ff74
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
f01004d3:	a1 60 ff 16 f0       	mov    0xf016ff60,%eax
f01004d8:	3b 05 64 ff 16 f0    	cmp    0xf016ff64,%eax
f01004de:	74 26                	je     f0100506 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01004e0:	8d 50 01             	lea    0x1(%eax),%edx
f01004e3:	89 15 60 ff 16 f0    	mov    %edx,0xf016ff60
f01004e9:	0f b6 88 60 fd 16 f0 	movzbl -0xfe902a0(%eax),%ecx
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
f01004fa:	c7 05 60 ff 16 f0 00 	movl   $0x0,0xf016ff60
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
f0100533:	c7 05 70 ff 16 f0 b4 	movl   $0x3b4,0xf016ff70
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
f010054b:	c7 05 70 ff 16 f0 d4 	movl   $0x3d4,0xf016ff70
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
f010055a:	8b 3d 70 ff 16 f0    	mov    0xf016ff70,%edi
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
f010057f:	89 35 6c ff 16 f0    	mov    %esi,0xf016ff6c
	crt_pos = pos;
f0100585:	0f b6 c0             	movzbl %al,%eax
f0100588:	09 c8                	or     %ecx,%eax
f010058a:	66 a3 68 ff 16 f0    	mov    %ax,0xf016ff68
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
f01005eb:	0f 95 05 74 ff 16 f0 	setne  0xf016ff74
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
f0100600:	68 d9 41 10 f0       	push   $0xf01041d9
f0100605:	e8 4d 28 00 00       	call   f0102e57 <cprintf>
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
f0100646:	68 20 44 10 f0       	push   $0xf0104420
f010064b:	68 3e 44 10 f0       	push   $0xf010443e
f0100650:	68 43 44 10 f0       	push   $0xf0104443
f0100655:	e8 fd 27 00 00       	call   f0102e57 <cprintf>
f010065a:	83 c4 0c             	add    $0xc,%esp
f010065d:	68 cc 44 10 f0       	push   $0xf01044cc
f0100662:	68 4c 44 10 f0       	push   $0xf010444c
f0100667:	68 43 44 10 f0       	push   $0xf0104443
f010066c:	e8 e6 27 00 00       	call   f0102e57 <cprintf>
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
f010067e:	68 55 44 10 f0       	push   $0xf0104455
f0100683:	e8 cf 27 00 00       	call   f0102e57 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100688:	83 c4 08             	add    $0x8,%esp
f010068b:	68 0c 00 10 00       	push   $0x10000c
f0100690:	68 f4 44 10 f0       	push   $0xf01044f4
f0100695:	e8 bd 27 00 00       	call   f0102e57 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f010069a:	83 c4 0c             	add    $0xc,%esp
f010069d:	68 0c 00 10 00       	push   $0x10000c
f01006a2:	68 0c 00 10 f0       	push   $0xf010000c
f01006a7:	68 1c 45 10 f0       	push   $0xf010451c
f01006ac:	e8 a6 27 00 00       	call   f0102e57 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006b1:	83 c4 0c             	add    $0xc,%esp
f01006b4:	68 61 41 10 00       	push   $0x104161
f01006b9:	68 61 41 10 f0       	push   $0xf0104161
f01006be:	68 40 45 10 f0       	push   $0xf0104540
f01006c3:	e8 8f 27 00 00       	call   f0102e57 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006c8:	83 c4 0c             	add    $0xc,%esp
f01006cb:	68 26 fd 16 00       	push   $0x16fd26
f01006d0:	68 26 fd 16 f0       	push   $0xf016fd26
f01006d5:	68 64 45 10 f0       	push   $0xf0104564
f01006da:	e8 78 27 00 00       	call   f0102e57 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006df:	83 c4 0c             	add    $0xc,%esp
f01006e2:	68 50 0c 17 00       	push   $0x170c50
f01006e7:	68 50 0c 17 f0       	push   $0xf0170c50
f01006ec:	68 88 45 10 f0       	push   $0xf0104588
f01006f1:	e8 61 27 00 00       	call   f0102e57 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f01006f6:	b8 4f 10 17 f0       	mov    $0xf017104f,%eax
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
f0100717:	68 ac 45 10 f0       	push   $0xf01045ac
f010071c:	e8 36 27 00 00       	call   f0102e57 <cprintf>
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
f0100732:	68 6e 44 10 f0       	push   $0xf010446e
f0100737:	e8 1b 27 00 00       	call   f0102e57 <cprintf>
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
f0100757:	68 d8 45 10 f0       	push   $0xf01045d8
f010075c:	e8 f6 26 00 00       	call   f0102e57 <cprintf>
				*((uintptr_t *)ebp + 1), *((uintptr_t *)ebp + 2), *((uintptr_t *)ebp + 3), 
			    *((uintptr_t *)ebp + 4), *((uintptr_t *)ebp + 5), *((uintptr_t *)ebp + 6));
		debuginfo_eip(*((uintptr_t *)ebp + 1), &info);
f0100761:	83 c4 18             	add    $0x18,%esp
f0100764:	56                   	push   %esi
f0100765:	ff 73 04             	pushl  0x4(%ebx)
f0100768:	e8 9e 2b 00 00       	call   f010330b <debuginfo_eip>
		cprintf("%s:%d: %.*s+%d\n", info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, 
f010076d:	83 c4 08             	add    $0x8,%esp
f0100770:	8b 43 04             	mov    0x4(%ebx),%eax
f0100773:	2b 45 f0             	sub    -0x10(%ebp),%eax
f0100776:	50                   	push   %eax
f0100777:	ff 75 e8             	pushl  -0x18(%ebp)
f010077a:	ff 75 ec             	pushl  -0x14(%ebp)
f010077d:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100780:	ff 75 e0             	pushl  -0x20(%ebp)
f0100783:	68 80 44 10 f0       	push   $0xf0104480
f0100788:	e8 ca 26 00 00       	call   f0102e57 <cprintf>
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
f01007ab:	68 10 46 10 f0       	push   $0xf0104610
f01007b0:	e8 a2 26 00 00       	call   f0102e57 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01007b5:	c7 04 24 34 46 10 f0 	movl   $0xf0104634,(%esp)
f01007bc:	e8 96 26 00 00       	call   f0102e57 <cprintf>

	if (tf != NULL)
f01007c1:	83 c4 10             	add    $0x10,%esp
f01007c4:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f01007c8:	74 0e                	je     f01007d8 <monitor+0x36>
		print_trapframe(tf);
f01007ca:	83 ec 0c             	sub    $0xc,%esp
f01007cd:	ff 75 08             	pushl  0x8(%ebp)
f01007d0:	e8 8b 27 00 00       	call   f0102f60 <print_trapframe>
f01007d5:	83 c4 10             	add    $0x10,%esp

	while (1) {
		buf = readline("K> ");
f01007d8:	83 ec 0c             	sub    $0xc,%esp
f01007db:	68 90 44 10 f0       	push   $0xf0104490
f01007e0:	e8 9f 32 00 00       	call   f0103a84 <readline>
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
f0100814:	68 94 44 10 f0       	push   $0xf0104494
f0100819:	e8 80 34 00 00       	call   f0103c9e <strchr>
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
f0100834:	68 99 44 10 f0       	push   $0xf0104499
f0100839:	e8 19 26 00 00       	call   f0102e57 <cprintf>
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
f010085d:	68 94 44 10 f0       	push   $0xf0104494
f0100862:	e8 37 34 00 00       	call   f0103c9e <strchr>
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
f0100883:	68 3e 44 10 f0       	push   $0xf010443e
f0100888:	ff 75 a8             	pushl  -0x58(%ebp)
f010088b:	e8 b0 33 00 00       	call   f0103c40 <strcmp>
f0100890:	83 c4 10             	add    $0x10,%esp
f0100893:	85 c0                	test   %eax,%eax
f0100895:	74 1e                	je     f01008b5 <monitor+0x113>
f0100897:	83 ec 08             	sub    $0x8,%esp
f010089a:	68 4c 44 10 f0       	push   $0xf010444c
f010089f:	ff 75 a8             	pushl  -0x58(%ebp)
f01008a2:	e8 99 33 00 00       	call   f0103c40 <strcmp>
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
f01008ca:	ff 14 85 64 46 10 f0 	call   *-0xfefb99c(,%eax,4)
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
f01008e3:	68 b6 44 10 f0       	push   $0xf01044b6
f01008e8:	e8 6a 25 00 00       	call   f0102e57 <cprintf>
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
f0100908:	e8 e3 24 00 00       	call   f0102df0 <mc146818_read>
f010090d:	89 c6                	mov    %eax,%esi
f010090f:	83 c3 01             	add    $0x1,%ebx
f0100912:	89 1c 24             	mov    %ebx,(%esp)
f0100915:	e8 d6 24 00 00       	call   f0102df0 <mc146818_read>
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
f010093c:	3b 0d 44 0c 17 f0    	cmp    0xf0170c44,%ecx
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
f010094b:	68 74 46 10 f0       	push   $0xf0104674
f0100950:	68 16 03 00 00       	push   $0x316
f0100955:	68 2d 4e 10 f0       	push   $0xf0104e2d
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
f010098c:	83 3d 78 ff 16 f0 00 	cmpl   $0x0,0xf016ff78
f0100993:	75 0f                	jne    f01009a4 <boot_alloc+0x1a>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100995:	b8 4f 1c 17 f0       	mov    $0xf0171c4f,%eax
f010099a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010099f:	a3 78 ff 16 f0       	mov    %eax,0xf016ff78
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	result = nextfree;
f01009a4:	a1 78 ff 16 f0       	mov    0xf016ff78,%eax
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
f01009bc:	68 98 46 10 f0       	push   $0xf0104698
f01009c1:	6a 6c                	push   $0x6c
f01009c3:	68 2d 4e 10 f0       	push   $0xf0104e2d
f01009c8:	e8 d3 f6 ff ff       	call   f01000a0 <_panic>
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	result = nextfree;
	if(n > 0){
		if (PADDR(nextfree) + n > (npages + 1) * PGSIZE) {
f01009cd:	8d 9c 10 00 00 00 10 	lea    0x10000000(%eax,%edx,1),%ebx
f01009d4:	8b 0d 44 0c 17 f0    	mov    0xf0170c44,%ecx
f01009da:	83 c1 01             	add    $0x1,%ecx
f01009dd:	c1 e1 0c             	shl    $0xc,%ecx
f01009e0:	39 cb                	cmp    %ecx,%ebx
f01009e2:	76 14                	jbe    f01009f8 <boot_alloc+0x6e>
			panic("out of memory\n");
f01009e4:	83 ec 04             	sub    $0x4,%esp
f01009e7:	68 39 4e 10 f0       	push   $0xf0104e39
f01009ec:	6a 6d                	push   $0x6d
f01009ee:	68 2d 4e 10 f0       	push   $0xf0104e2d
f01009f3:	e8 a8 f6 ff ff       	call   f01000a0 <_panic>
		}
		nextfree = ROUNDUP((char *)nextfree + n, PGSIZE);
f01009f8:	8d 94 10 ff 0f 00 00 	lea    0xfff(%eax,%edx,1),%edx
f01009ff:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100a05:	89 15 78 ff 16 f0    	mov    %edx,0xf016ff78
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
f0100a2a:	68 bc 46 10 f0       	push   $0xf01046bc
f0100a2f:	68 54 02 00 00       	push   $0x254
f0100a34:	68 2d 4e 10 f0       	push   $0xf0104e2d
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
f0100a4c:	2b 15 4c 0c 17 f0    	sub    0xf0170c4c,%edx
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
f0100a82:	a3 7c ff 16 f0       	mov    %eax,0xf016ff7c
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
f0100a8c:	8b 1d 7c ff 16 f0    	mov    0xf016ff7c,%ebx
f0100a92:	eb 53                	jmp    f0100ae7 <check_page_free_list+0xd6>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100a94:	89 d8                	mov    %ebx,%eax
f0100a96:	2b 05 4c 0c 17 f0    	sub    0xf0170c4c,%eax
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
f0100ab0:	3b 15 44 0c 17 f0    	cmp    0xf0170c44,%edx
f0100ab6:	72 12                	jb     f0100aca <check_page_free_list+0xb9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ab8:	50                   	push   %eax
f0100ab9:	68 74 46 10 f0       	push   $0xf0104674
f0100abe:	6a 56                	push   $0x56
f0100ac0:	68 48 4e 10 f0       	push   $0xf0104e48
f0100ac5:	e8 d6 f5 ff ff       	call   f01000a0 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100aca:	83 ec 04             	sub    $0x4,%esp
f0100acd:	68 80 00 00 00       	push   $0x80
f0100ad2:	68 97 00 00 00       	push   $0x97
f0100ad7:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100adc:	50                   	push   %eax
f0100add:	e8 f9 31 00 00       	call   f0103cdb <memset>
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
f0100af8:	8b 15 7c ff 16 f0    	mov    0xf016ff7c,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100afe:	8b 0d 4c 0c 17 f0    	mov    0xf0170c4c,%ecx
		assert(pp < pages + npages);
f0100b04:	a1 44 0c 17 f0       	mov    0xf0170c44,%eax
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
f0100b23:	68 56 4e 10 f0       	push   $0xf0104e56
f0100b28:	68 62 4e 10 f0       	push   $0xf0104e62
f0100b2d:	68 6e 02 00 00       	push   $0x26e
f0100b32:	68 2d 4e 10 f0       	push   $0xf0104e2d
f0100b37:	e8 64 f5 ff ff       	call   f01000a0 <_panic>
		assert(pp < pages + npages);
f0100b3c:	39 fa                	cmp    %edi,%edx
f0100b3e:	72 19                	jb     f0100b59 <check_page_free_list+0x148>
f0100b40:	68 77 4e 10 f0       	push   $0xf0104e77
f0100b45:	68 62 4e 10 f0       	push   $0xf0104e62
f0100b4a:	68 6f 02 00 00       	push   $0x26f
f0100b4f:	68 2d 4e 10 f0       	push   $0xf0104e2d
f0100b54:	e8 47 f5 ff ff       	call   f01000a0 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100b59:	89 d0                	mov    %edx,%eax
f0100b5b:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100b5e:	a8 07                	test   $0x7,%al
f0100b60:	74 19                	je     f0100b7b <check_page_free_list+0x16a>
f0100b62:	68 e0 46 10 f0       	push   $0xf01046e0
f0100b67:	68 62 4e 10 f0       	push   $0xf0104e62
f0100b6c:	68 70 02 00 00       	push   $0x270
f0100b71:	68 2d 4e 10 f0       	push   $0xf0104e2d
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
f0100b85:	68 8b 4e 10 f0       	push   $0xf0104e8b
f0100b8a:	68 62 4e 10 f0       	push   $0xf0104e62
f0100b8f:	68 73 02 00 00       	push   $0x273
f0100b94:	68 2d 4e 10 f0       	push   $0xf0104e2d
f0100b99:	e8 02 f5 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100b9e:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100ba3:	75 19                	jne    f0100bbe <check_page_free_list+0x1ad>
f0100ba5:	68 9c 4e 10 f0       	push   $0xf0104e9c
f0100baa:	68 62 4e 10 f0       	push   $0xf0104e62
f0100baf:	68 74 02 00 00       	push   $0x274
f0100bb4:	68 2d 4e 10 f0       	push   $0xf0104e2d
f0100bb9:	e8 e2 f4 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100bbe:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100bc3:	75 19                	jne    f0100bde <check_page_free_list+0x1cd>
f0100bc5:	68 14 47 10 f0       	push   $0xf0104714
f0100bca:	68 62 4e 10 f0       	push   $0xf0104e62
f0100bcf:	68 75 02 00 00       	push   $0x275
f0100bd4:	68 2d 4e 10 f0       	push   $0xf0104e2d
f0100bd9:	e8 c2 f4 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100bde:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100be3:	75 19                	jne    f0100bfe <check_page_free_list+0x1ed>
f0100be5:	68 b5 4e 10 f0       	push   $0xf0104eb5
f0100bea:	68 62 4e 10 f0       	push   $0xf0104e62
f0100bef:	68 76 02 00 00       	push   $0x276
f0100bf4:	68 2d 4e 10 f0       	push   $0xf0104e2d
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
f0100c10:	68 74 46 10 f0       	push   $0xf0104674
f0100c15:	6a 56                	push   $0x56
f0100c17:	68 48 4e 10 f0       	push   $0xf0104e48
f0100c1c:	e8 7f f4 ff ff       	call   f01000a0 <_panic>
f0100c21:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100c26:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100c29:	76 1e                	jbe    f0100c49 <check_page_free_list+0x238>
f0100c2b:	68 38 47 10 f0       	push   $0xf0104738
f0100c30:	68 62 4e 10 f0       	push   $0xf0104e62
f0100c35:	68 77 02 00 00       	push   $0x277
f0100c3a:	68 2d 4e 10 f0       	push   $0xf0104e2d
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
f0100c5e:	68 cf 4e 10 f0       	push   $0xf0104ecf
f0100c63:	68 62 4e 10 f0       	push   $0xf0104e62
f0100c68:	68 7f 02 00 00       	push   $0x27f
f0100c6d:	68 2d 4e 10 f0       	push   $0xf0104e2d
f0100c72:	e8 29 f4 ff ff       	call   f01000a0 <_panic>
	assert(nfree_extmem > 0);
f0100c77:	85 db                	test   %ebx,%ebx
f0100c79:	7f 42                	jg     f0100cbd <check_page_free_list+0x2ac>
f0100c7b:	68 e1 4e 10 f0       	push   $0xf0104ee1
f0100c80:	68 62 4e 10 f0       	push   $0xf0104e62
f0100c85:	68 80 02 00 00       	push   $0x280
f0100c8a:	68 2d 4e 10 f0       	push   $0xf0104e2d
f0100c8f:	e8 0c f4 ff ff       	call   f01000a0 <_panic>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100c94:	a1 7c ff 16 f0       	mov    0xf016ff7c,%eax
f0100c99:	85 c0                	test   %eax,%eax
f0100c9b:	0f 85 9d fd ff ff    	jne    f0100a3e <check_page_free_list+0x2d>
f0100ca1:	e9 81 fd ff ff       	jmp    f0100a27 <check_page_free_list+0x16>
f0100ca6:	83 3d 7c ff 16 f0 00 	cmpl   $0x0,0xf016ff7c
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
f0100ccc:	8b 1d 7c ff 16 f0    	mov    0xf016ff7c,%ebx
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
f0100ce7:	03 0d 4c 0c 17 f0    	add    0xf0170c4c,%ecx
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
f0100cfa:	03 1d 4c 0c 17 f0    	add    0xf0170c4c,%ebx
f0100d00:	ba 01 00 00 00       	mov    $0x1,%edx
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	
	size_t i, io_page_i, ext_page_i, free_top;
	for (i = 0; i < npages; i++) {
f0100d05:	3b 05 44 0c 17 f0    	cmp    0xf0170c44,%eax
f0100d0b:	72 d1                	jb     f0100cde <page_init+0x19>
f0100d0d:	84 d2                	test   %dl,%dl
f0100d0f:	74 06                	je     f0100d17 <page_init+0x52>
f0100d11:	89 1d 7c ff 16 f0    	mov    %ebx,0xf016ff7c
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
  
	pages[0].pp_link = NULL;
f0100d17:	a1 4c 0c 17 f0       	mov    0xf0170c4c,%eax
f0100d1c:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pages[1].pp_link = NULL;
f0100d22:	a1 4c 0c 17 f0       	mov    0xf0170c4c,%eax
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
f0100d40:	68 98 46 10 f0       	push   $0xf0104698
f0100d45:	68 25 01 00 00       	push   $0x125
f0100d4a:	68 2d 4e 10 f0       	push   $0xf0104e2d
f0100d4f:	e8 4c f3 ff ff       	call   f01000a0 <_panic>
f0100d54:	8d 88 00 00 00 10    	lea    0x10000000(%eax),%ecx
f0100d5a:	c1 e9 0c             	shr    $0xc,%ecx

	pages[ext_page_i].pp_link = pages[io_page_i].pp_link;
f0100d5d:	a1 4c 0c 17 f0       	mov    0xf0170c4c,%eax
f0100d62:	8b 90 00 05 00 00    	mov    0x500(%eax),%edx
f0100d68:	89 90 00 08 00 00    	mov    %edx,0x800(%eax)
f0100d6e:	b8 00 05 00 00       	mov    $0x500,%eax
	for(i = io_page_i;i < ext_page_i;i++)
		pages[i].pp_link = NULL;
f0100d73:	8b 15 4c 0c 17 f0    	mov    0xf0170c4c,%edx
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
f0100d8a:	a1 4c 0c 17 f0       	mov    0xf0170c4c,%eax
f0100d8f:	8b 90 00 08 00 00    	mov    0x800(%eax),%edx
f0100d95:	89 14 c8             	mov    %edx,(%eax,%ecx,8)
	for (i = ext_page_i; i < free_top; i++)
f0100d98:	b8 00 01 00 00       	mov    $0x100,%eax
f0100d9d:	eb 10                	jmp    f0100daf <page_init+0xea>
		pages[i].pp_link = NULL;
f0100d9f:	8b 15 4c 0c 17 f0    	mov    0xf0170c4c,%edx
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
f0100dbf:	8b 1d 7c ff 16 f0    	mov    0xf016ff7c,%ebx
	if(p){
f0100dc5:	85 db                	test   %ebx,%ebx
f0100dc7:	74 5c                	je     f0100e25 <page_alloc+0x6d>
		page_free_list = p->pp_link;
f0100dc9:	8b 03                	mov    (%ebx),%eax
f0100dcb:	a3 7c ff 16 f0       	mov    %eax,0xf016ff7c
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
f0100dde:	2b 05 4c 0c 17 f0    	sub    0xf0170c4c,%eax
f0100de4:	c1 f8 03             	sar    $0x3,%eax
f0100de7:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100dea:	89 c2                	mov    %eax,%edx
f0100dec:	c1 ea 0c             	shr    $0xc,%edx
f0100def:	3b 15 44 0c 17 f0    	cmp    0xf0170c44,%edx
f0100df5:	72 12                	jb     f0100e09 <page_alloc+0x51>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100df7:	50                   	push   %eax
f0100df8:	68 74 46 10 f0       	push   $0xf0104674
f0100dfd:	6a 56                	push   $0x56
f0100dff:	68 48 4e 10 f0       	push   $0xf0104e48
f0100e04:	e8 97 f2 ff ff       	call   f01000a0 <_panic>
			memset(page2kva(p), 0, PGSIZE);
f0100e09:	83 ec 04             	sub    $0x4,%esp
f0100e0c:	68 00 10 00 00       	push   $0x1000
f0100e11:	6a 00                	push   $0x0
f0100e13:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100e18:	50                   	push   %eax
f0100e19:	e8 bd 2e 00 00       	call   f0103cdb <memset>
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
f0100e47:	68 80 47 10 f0       	push   $0xf0104780
f0100e4c:	68 58 01 00 00       	push   $0x158
f0100e51:	68 2d 4e 10 f0       	push   $0xf0104e2d
f0100e56:	e8 45 f2 ff ff       	call   f01000a0 <_panic>
	}
	pp->pp_link = page_free_list;
f0100e5b:	8b 15 7c ff 16 f0    	mov    0xf016ff7c,%edx
f0100e61:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f0100e63:	a3 7c ff 16 f0       	mov    %eax,0xf016ff7c


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
f0100ec2:	2b 15 4c 0c 17 f0    	sub    0xf0170c4c,%edx
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
f0100ee4:	3b 15 44 0c 17 f0    	cmp    0xf0170c44,%edx
f0100eea:	72 15                	jb     f0100f01 <pgdir_walk+0x70>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100eec:	50                   	push   %eax
f0100eed:	68 74 46 10 f0       	push   $0xf0104674
f0100ef2:	68 8f 01 00 00       	push   $0x18f
f0100ef7:	68 2d 4e 10 f0       	push   $0xf0104e2d
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
f0100fb1:	3b 05 44 0c 17 f0    	cmp    0xf0170c44,%eax
f0100fb7:	72 14                	jb     f0100fcd <page_lookup+0x45>
		panic("pa2page called with invalid pa");
f0100fb9:	83 ec 04             	sub    $0x4,%esp
f0100fbc:	68 b4 47 10 f0       	push   $0xf01047b4
f0100fc1:	6a 4f                	push   $0x4f
f0100fc3:	68 48 4e 10 f0       	push   $0xf0104e48
f0100fc8:	e8 d3 f0 ff ff       	call   f01000a0 <_panic>
	return &pages[PGNUM(pa)];
f0100fcd:	8b 15 4c 0c 17 f0    	mov    0xf0170c4c,%edx
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
f010105c:	2b 1d 4c 0c 17 f0    	sub    0xf0170c4c,%ebx
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
f01010d2:	89 15 44 0c 17 f0    	mov    %edx,0xf0170c44
	npages_basemem = basemem / (PGSIZE / 1024);

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01010d8:	89 c2                	mov    %eax,%edx
f01010da:	29 da                	sub    %ebx,%edx
f01010dc:	52                   	push   %edx
f01010dd:	53                   	push   %ebx
f01010de:	50                   	push   %eax
f01010df:	68 d4 47 10 f0       	push   $0xf01047d4
f01010e4:	e8 6e 1d 00 00       	call   f0102e57 <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f01010e9:	b8 00 10 00 00       	mov    $0x1000,%eax
f01010ee:	e8 97 f8 ff ff       	call   f010098a <boot_alloc>
f01010f3:	a3 48 0c 17 f0       	mov    %eax,0xf0170c48
	memset(kern_pgdir, 0, PGSIZE);
f01010f8:	83 c4 0c             	add    $0xc,%esp
f01010fb:	68 00 10 00 00       	push   $0x1000
f0101100:	6a 00                	push   $0x0
f0101102:	50                   	push   %eax
f0101103:	e8 d3 2b 00 00       	call   f0103cdb <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0101108:	a1 48 0c 17 f0       	mov    0xf0170c48,%eax
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
f0101118:	68 98 46 10 f0       	push   $0xf0104698
f010111d:	68 94 00 00 00       	push   $0x94
f0101122:	68 2d 4e 10 f0       	push   $0xf0104e2d
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
f010113b:	a1 44 0c 17 f0       	mov    0xf0170c44,%eax
f0101140:	c1 e0 03             	shl    $0x3,%eax
f0101143:	e8 42 f8 ff ff       	call   f010098a <boot_alloc>
f0101148:	a3 4c 0c 17 f0       	mov    %eax,0xf0170c4c
	memset(pages, 0, npages * sizeof(struct PageInfo));
f010114d:	83 ec 04             	sub    $0x4,%esp
f0101150:	8b 3d 44 0c 17 f0    	mov    0xf0170c44,%edi
f0101156:	8d 14 fd 00 00 00 00 	lea    0x0(,%edi,8),%edx
f010115d:	52                   	push   %edx
f010115e:	6a 00                	push   $0x0
f0101160:	50                   	push   %eax
f0101161:	e8 75 2b 00 00       	call   f0103cdb <memset>

	//////////////////////////////////////////////////////////////////////
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.
	envs = (struct Env *) boot_alloc(NENV * sizeof(struct Env));
f0101166:	b8 00 80 01 00       	mov    $0x18000,%eax
f010116b:	e8 1a f8 ff ff       	call   f010098a <boot_alloc>
f0101170:	a3 84 ff 16 f0       	mov    %eax,0xf016ff84
	memset(envs, 0, NENV * sizeof(struct Env));
f0101175:	83 c4 0c             	add    $0xc,%esp
f0101178:	68 00 80 01 00       	push   $0x18000
f010117d:	6a 00                	push   $0x0
f010117f:	50                   	push   %eax
f0101180:	e8 56 2b 00 00       	call   f0103cdb <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f0101185:	e8 3b fb ff ff       	call   f0100cc5 <page_init>

	check_page_free_list(1);
f010118a:	b8 01 00 00 00       	mov    $0x1,%eax
f010118f:	e8 7d f8 ff ff       	call   f0100a11 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f0101194:	83 c4 10             	add    $0x10,%esp
f0101197:	83 3d 4c 0c 17 f0 00 	cmpl   $0x0,0xf0170c4c
f010119e:	75 17                	jne    f01011b7 <mem_init+0x12e>
		panic("'pages' is a null pointer!");
f01011a0:	83 ec 04             	sub    $0x4,%esp
f01011a3:	68 f2 4e 10 f0       	push   $0xf0104ef2
f01011a8:	68 91 02 00 00       	push   $0x291
f01011ad:	68 2d 4e 10 f0       	push   $0xf0104e2d
f01011b2:	e8 e9 ee ff ff       	call   f01000a0 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01011b7:	a1 7c ff 16 f0       	mov    0xf016ff7c,%eax
f01011bc:	bb 00 00 00 00       	mov    $0x0,%ebx
f01011c1:	eb 05                	jmp    f01011c8 <mem_init+0x13f>
		++nfree;
f01011c3:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01011c6:	8b 00                	mov    (%eax),%eax
f01011c8:	85 c0                	test   %eax,%eax
f01011ca:	75 f7                	jne    f01011c3 <mem_init+0x13a>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01011cc:	83 ec 0c             	sub    $0xc,%esp
f01011cf:	6a 00                	push   $0x0
f01011d1:	e8 e2 fb ff ff       	call   f0100db8 <page_alloc>
f01011d6:	89 c7                	mov    %eax,%edi
f01011d8:	83 c4 10             	add    $0x10,%esp
f01011db:	85 c0                	test   %eax,%eax
f01011dd:	75 19                	jne    f01011f8 <mem_init+0x16f>
f01011df:	68 0d 4f 10 f0       	push   $0xf0104f0d
f01011e4:	68 62 4e 10 f0       	push   $0xf0104e62
f01011e9:	68 99 02 00 00       	push   $0x299
f01011ee:	68 2d 4e 10 f0       	push   $0xf0104e2d
f01011f3:	e8 a8 ee ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f01011f8:	83 ec 0c             	sub    $0xc,%esp
f01011fb:	6a 00                	push   $0x0
f01011fd:	e8 b6 fb ff ff       	call   f0100db8 <page_alloc>
f0101202:	89 c6                	mov    %eax,%esi
f0101204:	83 c4 10             	add    $0x10,%esp
f0101207:	85 c0                	test   %eax,%eax
f0101209:	75 19                	jne    f0101224 <mem_init+0x19b>
f010120b:	68 23 4f 10 f0       	push   $0xf0104f23
f0101210:	68 62 4e 10 f0       	push   $0xf0104e62
f0101215:	68 9a 02 00 00       	push   $0x29a
f010121a:	68 2d 4e 10 f0       	push   $0xf0104e2d
f010121f:	e8 7c ee ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f0101224:	83 ec 0c             	sub    $0xc,%esp
f0101227:	6a 00                	push   $0x0
f0101229:	e8 8a fb ff ff       	call   f0100db8 <page_alloc>
f010122e:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101231:	83 c4 10             	add    $0x10,%esp
f0101234:	85 c0                	test   %eax,%eax
f0101236:	75 19                	jne    f0101251 <mem_init+0x1c8>
f0101238:	68 39 4f 10 f0       	push   $0xf0104f39
f010123d:	68 62 4e 10 f0       	push   $0xf0104e62
f0101242:	68 9b 02 00 00       	push   $0x29b
f0101247:	68 2d 4e 10 f0       	push   $0xf0104e2d
f010124c:	e8 4f ee ff ff       	call   f01000a0 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101251:	39 f7                	cmp    %esi,%edi
f0101253:	75 19                	jne    f010126e <mem_init+0x1e5>
f0101255:	68 4f 4f 10 f0       	push   $0xf0104f4f
f010125a:	68 62 4e 10 f0       	push   $0xf0104e62
f010125f:	68 9e 02 00 00       	push   $0x29e
f0101264:	68 2d 4e 10 f0       	push   $0xf0104e2d
f0101269:	e8 32 ee ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010126e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101271:	39 c6                	cmp    %eax,%esi
f0101273:	74 04                	je     f0101279 <mem_init+0x1f0>
f0101275:	39 c7                	cmp    %eax,%edi
f0101277:	75 19                	jne    f0101292 <mem_init+0x209>
f0101279:	68 10 48 10 f0       	push   $0xf0104810
f010127e:	68 62 4e 10 f0       	push   $0xf0104e62
f0101283:	68 9f 02 00 00       	push   $0x29f
f0101288:	68 2d 4e 10 f0       	push   $0xf0104e2d
f010128d:	e8 0e ee ff ff       	call   f01000a0 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101292:	8b 0d 4c 0c 17 f0    	mov    0xf0170c4c,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101298:	8b 15 44 0c 17 f0    	mov    0xf0170c44,%edx
f010129e:	c1 e2 0c             	shl    $0xc,%edx
f01012a1:	89 f8                	mov    %edi,%eax
f01012a3:	29 c8                	sub    %ecx,%eax
f01012a5:	c1 f8 03             	sar    $0x3,%eax
f01012a8:	c1 e0 0c             	shl    $0xc,%eax
f01012ab:	39 d0                	cmp    %edx,%eax
f01012ad:	72 19                	jb     f01012c8 <mem_init+0x23f>
f01012af:	68 61 4f 10 f0       	push   $0xf0104f61
f01012b4:	68 62 4e 10 f0       	push   $0xf0104e62
f01012b9:	68 a0 02 00 00       	push   $0x2a0
f01012be:	68 2d 4e 10 f0       	push   $0xf0104e2d
f01012c3:	e8 d8 ed ff ff       	call   f01000a0 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f01012c8:	89 f0                	mov    %esi,%eax
f01012ca:	29 c8                	sub    %ecx,%eax
f01012cc:	c1 f8 03             	sar    $0x3,%eax
f01012cf:	c1 e0 0c             	shl    $0xc,%eax
f01012d2:	39 c2                	cmp    %eax,%edx
f01012d4:	77 19                	ja     f01012ef <mem_init+0x266>
f01012d6:	68 7e 4f 10 f0       	push   $0xf0104f7e
f01012db:	68 62 4e 10 f0       	push   $0xf0104e62
f01012e0:	68 a1 02 00 00       	push   $0x2a1
f01012e5:	68 2d 4e 10 f0       	push   $0xf0104e2d
f01012ea:	e8 b1 ed ff ff       	call   f01000a0 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f01012ef:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01012f2:	29 c8                	sub    %ecx,%eax
f01012f4:	c1 f8 03             	sar    $0x3,%eax
f01012f7:	c1 e0 0c             	shl    $0xc,%eax
f01012fa:	39 c2                	cmp    %eax,%edx
f01012fc:	77 19                	ja     f0101317 <mem_init+0x28e>
f01012fe:	68 9b 4f 10 f0       	push   $0xf0104f9b
f0101303:	68 62 4e 10 f0       	push   $0xf0104e62
f0101308:	68 a2 02 00 00       	push   $0x2a2
f010130d:	68 2d 4e 10 f0       	push   $0xf0104e2d
f0101312:	e8 89 ed ff ff       	call   f01000a0 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101317:	a1 7c ff 16 f0       	mov    0xf016ff7c,%eax
f010131c:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f010131f:	c7 05 7c ff 16 f0 00 	movl   $0x0,0xf016ff7c
f0101326:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101329:	83 ec 0c             	sub    $0xc,%esp
f010132c:	6a 00                	push   $0x0
f010132e:	e8 85 fa ff ff       	call   f0100db8 <page_alloc>
f0101333:	83 c4 10             	add    $0x10,%esp
f0101336:	85 c0                	test   %eax,%eax
f0101338:	74 19                	je     f0101353 <mem_init+0x2ca>
f010133a:	68 b8 4f 10 f0       	push   $0xf0104fb8
f010133f:	68 62 4e 10 f0       	push   $0xf0104e62
f0101344:	68 a9 02 00 00       	push   $0x2a9
f0101349:	68 2d 4e 10 f0       	push   $0xf0104e2d
f010134e:	e8 4d ed ff ff       	call   f01000a0 <_panic>

	// free and re-allocate?
	page_free(pp0);
f0101353:	83 ec 0c             	sub    $0xc,%esp
f0101356:	57                   	push   %edi
f0101357:	e8 d3 fa ff ff       	call   f0100e2f <page_free>
	page_free(pp1);
f010135c:	89 34 24             	mov    %esi,(%esp)
f010135f:	e8 cb fa ff ff       	call   f0100e2f <page_free>
	page_free(pp2);
f0101364:	83 c4 04             	add    $0x4,%esp
f0101367:	ff 75 d4             	pushl  -0x2c(%ebp)
f010136a:	e8 c0 fa ff ff       	call   f0100e2f <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010136f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101376:	e8 3d fa ff ff       	call   f0100db8 <page_alloc>
f010137b:	89 c6                	mov    %eax,%esi
f010137d:	83 c4 10             	add    $0x10,%esp
f0101380:	85 c0                	test   %eax,%eax
f0101382:	75 19                	jne    f010139d <mem_init+0x314>
f0101384:	68 0d 4f 10 f0       	push   $0xf0104f0d
f0101389:	68 62 4e 10 f0       	push   $0xf0104e62
f010138e:	68 b0 02 00 00       	push   $0x2b0
f0101393:	68 2d 4e 10 f0       	push   $0xf0104e2d
f0101398:	e8 03 ed ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f010139d:	83 ec 0c             	sub    $0xc,%esp
f01013a0:	6a 00                	push   $0x0
f01013a2:	e8 11 fa ff ff       	call   f0100db8 <page_alloc>
f01013a7:	89 c7                	mov    %eax,%edi
f01013a9:	83 c4 10             	add    $0x10,%esp
f01013ac:	85 c0                	test   %eax,%eax
f01013ae:	75 19                	jne    f01013c9 <mem_init+0x340>
f01013b0:	68 23 4f 10 f0       	push   $0xf0104f23
f01013b5:	68 62 4e 10 f0       	push   $0xf0104e62
f01013ba:	68 b1 02 00 00       	push   $0x2b1
f01013bf:	68 2d 4e 10 f0       	push   $0xf0104e2d
f01013c4:	e8 d7 ec ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f01013c9:	83 ec 0c             	sub    $0xc,%esp
f01013cc:	6a 00                	push   $0x0
f01013ce:	e8 e5 f9 ff ff       	call   f0100db8 <page_alloc>
f01013d3:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01013d6:	83 c4 10             	add    $0x10,%esp
f01013d9:	85 c0                	test   %eax,%eax
f01013db:	75 19                	jne    f01013f6 <mem_init+0x36d>
f01013dd:	68 39 4f 10 f0       	push   $0xf0104f39
f01013e2:	68 62 4e 10 f0       	push   $0xf0104e62
f01013e7:	68 b2 02 00 00       	push   $0x2b2
f01013ec:	68 2d 4e 10 f0       	push   $0xf0104e2d
f01013f1:	e8 aa ec ff ff       	call   f01000a0 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01013f6:	39 fe                	cmp    %edi,%esi
f01013f8:	75 19                	jne    f0101413 <mem_init+0x38a>
f01013fa:	68 4f 4f 10 f0       	push   $0xf0104f4f
f01013ff:	68 62 4e 10 f0       	push   $0xf0104e62
f0101404:	68 b4 02 00 00       	push   $0x2b4
f0101409:	68 2d 4e 10 f0       	push   $0xf0104e2d
f010140e:	e8 8d ec ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101413:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101416:	39 c7                	cmp    %eax,%edi
f0101418:	74 04                	je     f010141e <mem_init+0x395>
f010141a:	39 c6                	cmp    %eax,%esi
f010141c:	75 19                	jne    f0101437 <mem_init+0x3ae>
f010141e:	68 10 48 10 f0       	push   $0xf0104810
f0101423:	68 62 4e 10 f0       	push   $0xf0104e62
f0101428:	68 b5 02 00 00       	push   $0x2b5
f010142d:	68 2d 4e 10 f0       	push   $0xf0104e2d
f0101432:	e8 69 ec ff ff       	call   f01000a0 <_panic>
	assert(!page_alloc(0));
f0101437:	83 ec 0c             	sub    $0xc,%esp
f010143a:	6a 00                	push   $0x0
f010143c:	e8 77 f9 ff ff       	call   f0100db8 <page_alloc>
f0101441:	83 c4 10             	add    $0x10,%esp
f0101444:	85 c0                	test   %eax,%eax
f0101446:	74 19                	je     f0101461 <mem_init+0x3d8>
f0101448:	68 b8 4f 10 f0       	push   $0xf0104fb8
f010144d:	68 62 4e 10 f0       	push   $0xf0104e62
f0101452:	68 b6 02 00 00       	push   $0x2b6
f0101457:	68 2d 4e 10 f0       	push   $0xf0104e2d
f010145c:	e8 3f ec ff ff       	call   f01000a0 <_panic>
f0101461:	89 f0                	mov    %esi,%eax
f0101463:	2b 05 4c 0c 17 f0    	sub    0xf0170c4c,%eax
f0101469:	c1 f8 03             	sar    $0x3,%eax
f010146c:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010146f:	89 c2                	mov    %eax,%edx
f0101471:	c1 ea 0c             	shr    $0xc,%edx
f0101474:	3b 15 44 0c 17 f0    	cmp    0xf0170c44,%edx
f010147a:	72 12                	jb     f010148e <mem_init+0x405>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010147c:	50                   	push   %eax
f010147d:	68 74 46 10 f0       	push   $0xf0104674
f0101482:	6a 56                	push   $0x56
f0101484:	68 48 4e 10 f0       	push   $0xf0104e48
f0101489:	e8 12 ec ff ff       	call   f01000a0 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f010148e:	83 ec 04             	sub    $0x4,%esp
f0101491:	68 00 10 00 00       	push   $0x1000
f0101496:	6a 01                	push   $0x1
f0101498:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010149d:	50                   	push   %eax
f010149e:	e8 38 28 00 00       	call   f0103cdb <memset>
	page_free(pp0);
f01014a3:	89 34 24             	mov    %esi,(%esp)
f01014a6:	e8 84 f9 ff ff       	call   f0100e2f <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01014ab:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01014b2:	e8 01 f9 ff ff       	call   f0100db8 <page_alloc>
f01014b7:	83 c4 10             	add    $0x10,%esp
f01014ba:	85 c0                	test   %eax,%eax
f01014bc:	75 19                	jne    f01014d7 <mem_init+0x44e>
f01014be:	68 c7 4f 10 f0       	push   $0xf0104fc7
f01014c3:	68 62 4e 10 f0       	push   $0xf0104e62
f01014c8:	68 bb 02 00 00       	push   $0x2bb
f01014cd:	68 2d 4e 10 f0       	push   $0xf0104e2d
f01014d2:	e8 c9 eb ff ff       	call   f01000a0 <_panic>
	assert(pp && pp0 == pp);
f01014d7:	39 c6                	cmp    %eax,%esi
f01014d9:	74 19                	je     f01014f4 <mem_init+0x46b>
f01014db:	68 e5 4f 10 f0       	push   $0xf0104fe5
f01014e0:	68 62 4e 10 f0       	push   $0xf0104e62
f01014e5:	68 bc 02 00 00       	push   $0x2bc
f01014ea:	68 2d 4e 10 f0       	push   $0xf0104e2d
f01014ef:	e8 ac eb ff ff       	call   f01000a0 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01014f4:	89 f0                	mov    %esi,%eax
f01014f6:	2b 05 4c 0c 17 f0    	sub    0xf0170c4c,%eax
f01014fc:	c1 f8 03             	sar    $0x3,%eax
f01014ff:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101502:	89 c2                	mov    %eax,%edx
f0101504:	c1 ea 0c             	shr    $0xc,%edx
f0101507:	3b 15 44 0c 17 f0    	cmp    0xf0170c44,%edx
f010150d:	72 12                	jb     f0101521 <mem_init+0x498>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010150f:	50                   	push   %eax
f0101510:	68 74 46 10 f0       	push   $0xf0104674
f0101515:	6a 56                	push   $0x56
f0101517:	68 48 4e 10 f0       	push   $0xf0104e48
f010151c:	e8 7f eb ff ff       	call   f01000a0 <_panic>
f0101521:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f0101527:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f010152d:	80 38 00             	cmpb   $0x0,(%eax)
f0101530:	74 19                	je     f010154b <mem_init+0x4c2>
f0101532:	68 f5 4f 10 f0       	push   $0xf0104ff5
f0101537:	68 62 4e 10 f0       	push   $0xf0104e62
f010153c:	68 bf 02 00 00       	push   $0x2bf
f0101541:	68 2d 4e 10 f0       	push   $0xf0104e2d
f0101546:	e8 55 eb ff ff       	call   f01000a0 <_panic>
f010154b:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f010154e:	39 d0                	cmp    %edx,%eax
f0101550:	75 db                	jne    f010152d <mem_init+0x4a4>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101552:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101555:	a3 7c ff 16 f0       	mov    %eax,0xf016ff7c

	// free the pages we took
	page_free(pp0);
f010155a:	83 ec 0c             	sub    $0xc,%esp
f010155d:	56                   	push   %esi
f010155e:	e8 cc f8 ff ff       	call   f0100e2f <page_free>
	page_free(pp1);
f0101563:	89 3c 24             	mov    %edi,(%esp)
f0101566:	e8 c4 f8 ff ff       	call   f0100e2f <page_free>
	page_free(pp2);
f010156b:	83 c4 04             	add    $0x4,%esp
f010156e:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101571:	e8 b9 f8 ff ff       	call   f0100e2f <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101576:	a1 7c ff 16 f0       	mov    0xf016ff7c,%eax
f010157b:	83 c4 10             	add    $0x10,%esp
f010157e:	eb 05                	jmp    f0101585 <mem_init+0x4fc>
		--nfree;
f0101580:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101583:	8b 00                	mov    (%eax),%eax
f0101585:	85 c0                	test   %eax,%eax
f0101587:	75 f7                	jne    f0101580 <mem_init+0x4f7>
		--nfree;
	assert(nfree == 0);
f0101589:	85 db                	test   %ebx,%ebx
f010158b:	74 19                	je     f01015a6 <mem_init+0x51d>
f010158d:	68 ff 4f 10 f0       	push   $0xf0104fff
f0101592:	68 62 4e 10 f0       	push   $0xf0104e62
f0101597:	68 cc 02 00 00       	push   $0x2cc
f010159c:	68 2d 4e 10 f0       	push   $0xf0104e2d
f01015a1:	e8 fa ea ff ff       	call   f01000a0 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f01015a6:	83 ec 0c             	sub    $0xc,%esp
f01015a9:	68 30 48 10 f0       	push   $0xf0104830
f01015ae:	e8 a4 18 00 00       	call   f0102e57 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01015b3:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01015ba:	e8 f9 f7 ff ff       	call   f0100db8 <page_alloc>
f01015bf:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01015c2:	83 c4 10             	add    $0x10,%esp
f01015c5:	85 c0                	test   %eax,%eax
f01015c7:	75 19                	jne    f01015e2 <mem_init+0x559>
f01015c9:	68 0d 4f 10 f0       	push   $0xf0104f0d
f01015ce:	68 62 4e 10 f0       	push   $0xf0104e62
f01015d3:	68 2a 03 00 00       	push   $0x32a
f01015d8:	68 2d 4e 10 f0       	push   $0xf0104e2d
f01015dd:	e8 be ea ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f01015e2:	83 ec 0c             	sub    $0xc,%esp
f01015e5:	6a 00                	push   $0x0
f01015e7:	e8 cc f7 ff ff       	call   f0100db8 <page_alloc>
f01015ec:	89 c3                	mov    %eax,%ebx
f01015ee:	83 c4 10             	add    $0x10,%esp
f01015f1:	85 c0                	test   %eax,%eax
f01015f3:	75 19                	jne    f010160e <mem_init+0x585>
f01015f5:	68 23 4f 10 f0       	push   $0xf0104f23
f01015fa:	68 62 4e 10 f0       	push   $0xf0104e62
f01015ff:	68 2b 03 00 00       	push   $0x32b
f0101604:	68 2d 4e 10 f0       	push   $0xf0104e2d
f0101609:	e8 92 ea ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f010160e:	83 ec 0c             	sub    $0xc,%esp
f0101611:	6a 00                	push   $0x0
f0101613:	e8 a0 f7 ff ff       	call   f0100db8 <page_alloc>
f0101618:	89 c6                	mov    %eax,%esi
f010161a:	83 c4 10             	add    $0x10,%esp
f010161d:	85 c0                	test   %eax,%eax
f010161f:	75 19                	jne    f010163a <mem_init+0x5b1>
f0101621:	68 39 4f 10 f0       	push   $0xf0104f39
f0101626:	68 62 4e 10 f0       	push   $0xf0104e62
f010162b:	68 2c 03 00 00       	push   $0x32c
f0101630:	68 2d 4e 10 f0       	push   $0xf0104e2d
f0101635:	e8 66 ea ff ff       	call   f01000a0 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010163a:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f010163d:	75 19                	jne    f0101658 <mem_init+0x5cf>
f010163f:	68 4f 4f 10 f0       	push   $0xf0104f4f
f0101644:	68 62 4e 10 f0       	push   $0xf0104e62
f0101649:	68 2f 03 00 00       	push   $0x32f
f010164e:	68 2d 4e 10 f0       	push   $0xf0104e2d
f0101653:	e8 48 ea ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101658:	39 c3                	cmp    %eax,%ebx
f010165a:	74 05                	je     f0101661 <mem_init+0x5d8>
f010165c:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f010165f:	75 19                	jne    f010167a <mem_init+0x5f1>
f0101661:	68 10 48 10 f0       	push   $0xf0104810
f0101666:	68 62 4e 10 f0       	push   $0xf0104e62
f010166b:	68 30 03 00 00       	push   $0x330
f0101670:	68 2d 4e 10 f0       	push   $0xf0104e2d
f0101675:	e8 26 ea ff ff       	call   f01000a0 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f010167a:	a1 7c ff 16 f0       	mov    0xf016ff7c,%eax
f010167f:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101682:	c7 05 7c ff 16 f0 00 	movl   $0x0,0xf016ff7c
f0101689:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f010168c:	83 ec 0c             	sub    $0xc,%esp
f010168f:	6a 00                	push   $0x0
f0101691:	e8 22 f7 ff ff       	call   f0100db8 <page_alloc>
f0101696:	83 c4 10             	add    $0x10,%esp
f0101699:	85 c0                	test   %eax,%eax
f010169b:	74 19                	je     f01016b6 <mem_init+0x62d>
f010169d:	68 b8 4f 10 f0       	push   $0xf0104fb8
f01016a2:	68 62 4e 10 f0       	push   $0xf0104e62
f01016a7:	68 37 03 00 00       	push   $0x337
f01016ac:	68 2d 4e 10 f0       	push   $0xf0104e2d
f01016b1:	e8 ea e9 ff ff       	call   f01000a0 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f01016b6:	83 ec 04             	sub    $0x4,%esp
f01016b9:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01016bc:	50                   	push   %eax
f01016bd:	6a 00                	push   $0x0
f01016bf:	ff 35 48 0c 17 f0    	pushl  0xf0170c48
f01016c5:	e8 be f8 ff ff       	call   f0100f88 <page_lookup>
f01016ca:	83 c4 10             	add    $0x10,%esp
f01016cd:	85 c0                	test   %eax,%eax
f01016cf:	74 19                	je     f01016ea <mem_init+0x661>
f01016d1:	68 50 48 10 f0       	push   $0xf0104850
f01016d6:	68 62 4e 10 f0       	push   $0xf0104e62
f01016db:	68 3a 03 00 00       	push   $0x33a
f01016e0:	68 2d 4e 10 f0       	push   $0xf0104e2d
f01016e5:	e8 b6 e9 ff ff       	call   f01000a0 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f01016ea:	6a 02                	push   $0x2
f01016ec:	6a 00                	push   $0x0
f01016ee:	53                   	push   %ebx
f01016ef:	ff 35 48 0c 17 f0    	pushl  0xf0170c48
f01016f5:	e8 23 f9 ff ff       	call   f010101d <page_insert>
f01016fa:	83 c4 10             	add    $0x10,%esp
f01016fd:	85 c0                	test   %eax,%eax
f01016ff:	78 19                	js     f010171a <mem_init+0x691>
f0101701:	68 88 48 10 f0       	push   $0xf0104888
f0101706:	68 62 4e 10 f0       	push   $0xf0104e62
f010170b:	68 3d 03 00 00       	push   $0x33d
f0101710:	68 2d 4e 10 f0       	push   $0xf0104e2d
f0101715:	e8 86 e9 ff ff       	call   f01000a0 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f010171a:	83 ec 0c             	sub    $0xc,%esp
f010171d:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101720:	e8 0a f7 ff ff       	call   f0100e2f <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101725:	6a 02                	push   $0x2
f0101727:	6a 00                	push   $0x0
f0101729:	53                   	push   %ebx
f010172a:	ff 35 48 0c 17 f0    	pushl  0xf0170c48
f0101730:	e8 e8 f8 ff ff       	call   f010101d <page_insert>
f0101735:	83 c4 20             	add    $0x20,%esp
f0101738:	85 c0                	test   %eax,%eax
f010173a:	74 19                	je     f0101755 <mem_init+0x6cc>
f010173c:	68 b8 48 10 f0       	push   $0xf01048b8
f0101741:	68 62 4e 10 f0       	push   $0xf0104e62
f0101746:	68 41 03 00 00       	push   $0x341
f010174b:	68 2d 4e 10 f0       	push   $0xf0104e2d
f0101750:	e8 4b e9 ff ff       	call   f01000a0 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101755:	8b 3d 48 0c 17 f0    	mov    0xf0170c48,%edi
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010175b:	a1 4c 0c 17 f0       	mov    0xf0170c4c,%eax
f0101760:	89 c1                	mov    %eax,%ecx
f0101762:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101765:	8b 17                	mov    (%edi),%edx
f0101767:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010176d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101770:	29 c8                	sub    %ecx,%eax
f0101772:	c1 f8 03             	sar    $0x3,%eax
f0101775:	c1 e0 0c             	shl    $0xc,%eax
f0101778:	39 c2                	cmp    %eax,%edx
f010177a:	74 19                	je     f0101795 <mem_init+0x70c>
f010177c:	68 e8 48 10 f0       	push   $0xf01048e8
f0101781:	68 62 4e 10 f0       	push   $0xf0104e62
f0101786:	68 42 03 00 00       	push   $0x342
f010178b:	68 2d 4e 10 f0       	push   $0xf0104e2d
f0101790:	e8 0b e9 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101795:	ba 00 00 00 00       	mov    $0x0,%edx
f010179a:	89 f8                	mov    %edi,%eax
f010179c:	e8 85 f1 ff ff       	call   f0100926 <check_va2pa>
f01017a1:	89 da                	mov    %ebx,%edx
f01017a3:	2b 55 cc             	sub    -0x34(%ebp),%edx
f01017a6:	c1 fa 03             	sar    $0x3,%edx
f01017a9:	c1 e2 0c             	shl    $0xc,%edx
f01017ac:	39 d0                	cmp    %edx,%eax
f01017ae:	74 19                	je     f01017c9 <mem_init+0x740>
f01017b0:	68 10 49 10 f0       	push   $0xf0104910
f01017b5:	68 62 4e 10 f0       	push   $0xf0104e62
f01017ba:	68 43 03 00 00       	push   $0x343
f01017bf:	68 2d 4e 10 f0       	push   $0xf0104e2d
f01017c4:	e8 d7 e8 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 1);
f01017c9:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01017ce:	74 19                	je     f01017e9 <mem_init+0x760>
f01017d0:	68 0a 50 10 f0       	push   $0xf010500a
f01017d5:	68 62 4e 10 f0       	push   $0xf0104e62
f01017da:	68 44 03 00 00       	push   $0x344
f01017df:	68 2d 4e 10 f0       	push   $0xf0104e2d
f01017e4:	e8 b7 e8 ff ff       	call   f01000a0 <_panic>
	assert(pp0->pp_ref == 1);
f01017e9:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01017ec:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f01017f1:	74 19                	je     f010180c <mem_init+0x783>
f01017f3:	68 1b 50 10 f0       	push   $0xf010501b
f01017f8:	68 62 4e 10 f0       	push   $0xf0104e62
f01017fd:	68 45 03 00 00       	push   $0x345
f0101802:	68 2d 4e 10 f0       	push   $0xf0104e2d
f0101807:	e8 94 e8 ff ff       	call   f01000a0 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f010180c:	6a 02                	push   $0x2
f010180e:	68 00 10 00 00       	push   $0x1000
f0101813:	56                   	push   %esi
f0101814:	57                   	push   %edi
f0101815:	e8 03 f8 ff ff       	call   f010101d <page_insert>
f010181a:	83 c4 10             	add    $0x10,%esp
f010181d:	85 c0                	test   %eax,%eax
f010181f:	74 19                	je     f010183a <mem_init+0x7b1>
f0101821:	68 40 49 10 f0       	push   $0xf0104940
f0101826:	68 62 4e 10 f0       	push   $0xf0104e62
f010182b:	68 48 03 00 00       	push   $0x348
f0101830:	68 2d 4e 10 f0       	push   $0xf0104e2d
f0101835:	e8 66 e8 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f010183a:	ba 00 10 00 00       	mov    $0x1000,%edx
f010183f:	a1 48 0c 17 f0       	mov    0xf0170c48,%eax
f0101844:	e8 dd f0 ff ff       	call   f0100926 <check_va2pa>
f0101849:	89 f2                	mov    %esi,%edx
f010184b:	2b 15 4c 0c 17 f0    	sub    0xf0170c4c,%edx
f0101851:	c1 fa 03             	sar    $0x3,%edx
f0101854:	c1 e2 0c             	shl    $0xc,%edx
f0101857:	39 d0                	cmp    %edx,%eax
f0101859:	74 19                	je     f0101874 <mem_init+0x7eb>
f010185b:	68 7c 49 10 f0       	push   $0xf010497c
f0101860:	68 62 4e 10 f0       	push   $0xf0104e62
f0101865:	68 49 03 00 00       	push   $0x349
f010186a:	68 2d 4e 10 f0       	push   $0xf0104e2d
f010186f:	e8 2c e8 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f0101874:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101879:	74 19                	je     f0101894 <mem_init+0x80b>
f010187b:	68 2c 50 10 f0       	push   $0xf010502c
f0101880:	68 62 4e 10 f0       	push   $0xf0104e62
f0101885:	68 4a 03 00 00       	push   $0x34a
f010188a:	68 2d 4e 10 f0       	push   $0xf0104e2d
f010188f:	e8 0c e8 ff ff       	call   f01000a0 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101894:	83 ec 0c             	sub    $0xc,%esp
f0101897:	6a 00                	push   $0x0
f0101899:	e8 1a f5 ff ff       	call   f0100db8 <page_alloc>
f010189e:	83 c4 10             	add    $0x10,%esp
f01018a1:	85 c0                	test   %eax,%eax
f01018a3:	74 19                	je     f01018be <mem_init+0x835>
f01018a5:	68 b8 4f 10 f0       	push   $0xf0104fb8
f01018aa:	68 62 4e 10 f0       	push   $0xf0104e62
f01018af:	68 4d 03 00 00       	push   $0x34d
f01018b4:	68 2d 4e 10 f0       	push   $0xf0104e2d
f01018b9:	e8 e2 e7 ff ff       	call   f01000a0 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01018be:	6a 02                	push   $0x2
f01018c0:	68 00 10 00 00       	push   $0x1000
f01018c5:	56                   	push   %esi
f01018c6:	ff 35 48 0c 17 f0    	pushl  0xf0170c48
f01018cc:	e8 4c f7 ff ff       	call   f010101d <page_insert>
f01018d1:	83 c4 10             	add    $0x10,%esp
f01018d4:	85 c0                	test   %eax,%eax
f01018d6:	74 19                	je     f01018f1 <mem_init+0x868>
f01018d8:	68 40 49 10 f0       	push   $0xf0104940
f01018dd:	68 62 4e 10 f0       	push   $0xf0104e62
f01018e2:	68 50 03 00 00       	push   $0x350
f01018e7:	68 2d 4e 10 f0       	push   $0xf0104e2d
f01018ec:	e8 af e7 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01018f1:	ba 00 10 00 00       	mov    $0x1000,%edx
f01018f6:	a1 48 0c 17 f0       	mov    0xf0170c48,%eax
f01018fb:	e8 26 f0 ff ff       	call   f0100926 <check_va2pa>
f0101900:	89 f2                	mov    %esi,%edx
f0101902:	2b 15 4c 0c 17 f0    	sub    0xf0170c4c,%edx
f0101908:	c1 fa 03             	sar    $0x3,%edx
f010190b:	c1 e2 0c             	shl    $0xc,%edx
f010190e:	39 d0                	cmp    %edx,%eax
f0101910:	74 19                	je     f010192b <mem_init+0x8a2>
f0101912:	68 7c 49 10 f0       	push   $0xf010497c
f0101917:	68 62 4e 10 f0       	push   $0xf0104e62
f010191c:	68 51 03 00 00       	push   $0x351
f0101921:	68 2d 4e 10 f0       	push   $0xf0104e2d
f0101926:	e8 75 e7 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f010192b:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101930:	74 19                	je     f010194b <mem_init+0x8c2>
f0101932:	68 2c 50 10 f0       	push   $0xf010502c
f0101937:	68 62 4e 10 f0       	push   $0xf0104e62
f010193c:	68 52 03 00 00       	push   $0x352
f0101941:	68 2d 4e 10 f0       	push   $0xf0104e2d
f0101946:	e8 55 e7 ff ff       	call   f01000a0 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f010194b:	83 ec 0c             	sub    $0xc,%esp
f010194e:	6a 00                	push   $0x0
f0101950:	e8 63 f4 ff ff       	call   f0100db8 <page_alloc>
f0101955:	83 c4 10             	add    $0x10,%esp
f0101958:	85 c0                	test   %eax,%eax
f010195a:	74 19                	je     f0101975 <mem_init+0x8ec>
f010195c:	68 b8 4f 10 f0       	push   $0xf0104fb8
f0101961:	68 62 4e 10 f0       	push   $0xf0104e62
f0101966:	68 56 03 00 00       	push   $0x356
f010196b:	68 2d 4e 10 f0       	push   $0xf0104e2d
f0101970:	e8 2b e7 ff ff       	call   f01000a0 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101975:	8b 15 48 0c 17 f0    	mov    0xf0170c48,%edx
f010197b:	8b 02                	mov    (%edx),%eax
f010197d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101982:	89 c1                	mov    %eax,%ecx
f0101984:	c1 e9 0c             	shr    $0xc,%ecx
f0101987:	3b 0d 44 0c 17 f0    	cmp    0xf0170c44,%ecx
f010198d:	72 15                	jb     f01019a4 <mem_init+0x91b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010198f:	50                   	push   %eax
f0101990:	68 74 46 10 f0       	push   $0xf0104674
f0101995:	68 59 03 00 00       	push   $0x359
f010199a:	68 2d 4e 10 f0       	push   $0xf0104e2d
f010199f:	e8 fc e6 ff ff       	call   f01000a0 <_panic>
f01019a4:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01019a9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f01019ac:	83 ec 04             	sub    $0x4,%esp
f01019af:	6a 00                	push   $0x0
f01019b1:	68 00 10 00 00       	push   $0x1000
f01019b6:	52                   	push   %edx
f01019b7:	e8 d5 f4 ff ff       	call   f0100e91 <pgdir_walk>
f01019bc:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01019bf:	8d 57 04             	lea    0x4(%edi),%edx
f01019c2:	83 c4 10             	add    $0x10,%esp
f01019c5:	39 d0                	cmp    %edx,%eax
f01019c7:	74 19                	je     f01019e2 <mem_init+0x959>
f01019c9:	68 ac 49 10 f0       	push   $0xf01049ac
f01019ce:	68 62 4e 10 f0       	push   $0xf0104e62
f01019d3:	68 5a 03 00 00       	push   $0x35a
f01019d8:	68 2d 4e 10 f0       	push   $0xf0104e2d
f01019dd:	e8 be e6 ff ff       	call   f01000a0 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f01019e2:	6a 06                	push   $0x6
f01019e4:	68 00 10 00 00       	push   $0x1000
f01019e9:	56                   	push   %esi
f01019ea:	ff 35 48 0c 17 f0    	pushl  0xf0170c48
f01019f0:	e8 28 f6 ff ff       	call   f010101d <page_insert>
f01019f5:	83 c4 10             	add    $0x10,%esp
f01019f8:	85 c0                	test   %eax,%eax
f01019fa:	74 19                	je     f0101a15 <mem_init+0x98c>
f01019fc:	68 ec 49 10 f0       	push   $0xf01049ec
f0101a01:	68 62 4e 10 f0       	push   $0xf0104e62
f0101a06:	68 5d 03 00 00       	push   $0x35d
f0101a0b:	68 2d 4e 10 f0       	push   $0xf0104e2d
f0101a10:	e8 8b e6 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101a15:	8b 3d 48 0c 17 f0    	mov    0xf0170c48,%edi
f0101a1b:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101a20:	89 f8                	mov    %edi,%eax
f0101a22:	e8 ff ee ff ff       	call   f0100926 <check_va2pa>
f0101a27:	89 f2                	mov    %esi,%edx
f0101a29:	2b 15 4c 0c 17 f0    	sub    0xf0170c4c,%edx
f0101a2f:	c1 fa 03             	sar    $0x3,%edx
f0101a32:	c1 e2 0c             	shl    $0xc,%edx
f0101a35:	39 d0                	cmp    %edx,%eax
f0101a37:	74 19                	je     f0101a52 <mem_init+0x9c9>
f0101a39:	68 7c 49 10 f0       	push   $0xf010497c
f0101a3e:	68 62 4e 10 f0       	push   $0xf0104e62
f0101a43:	68 5e 03 00 00       	push   $0x35e
f0101a48:	68 2d 4e 10 f0       	push   $0xf0104e2d
f0101a4d:	e8 4e e6 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f0101a52:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101a57:	74 19                	je     f0101a72 <mem_init+0x9e9>
f0101a59:	68 2c 50 10 f0       	push   $0xf010502c
f0101a5e:	68 62 4e 10 f0       	push   $0xf0104e62
f0101a63:	68 5f 03 00 00       	push   $0x35f
f0101a68:	68 2d 4e 10 f0       	push   $0xf0104e2d
f0101a6d:	e8 2e e6 ff ff       	call   f01000a0 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101a72:	83 ec 04             	sub    $0x4,%esp
f0101a75:	6a 00                	push   $0x0
f0101a77:	68 00 10 00 00       	push   $0x1000
f0101a7c:	57                   	push   %edi
f0101a7d:	e8 0f f4 ff ff       	call   f0100e91 <pgdir_walk>
f0101a82:	83 c4 10             	add    $0x10,%esp
f0101a85:	f6 00 04             	testb  $0x4,(%eax)
f0101a88:	75 19                	jne    f0101aa3 <mem_init+0xa1a>
f0101a8a:	68 2c 4a 10 f0       	push   $0xf0104a2c
f0101a8f:	68 62 4e 10 f0       	push   $0xf0104e62
f0101a94:	68 60 03 00 00       	push   $0x360
f0101a99:	68 2d 4e 10 f0       	push   $0xf0104e2d
f0101a9e:	e8 fd e5 ff ff       	call   f01000a0 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101aa3:	a1 48 0c 17 f0       	mov    0xf0170c48,%eax
f0101aa8:	f6 00 04             	testb  $0x4,(%eax)
f0101aab:	75 19                	jne    f0101ac6 <mem_init+0xa3d>
f0101aad:	68 3d 50 10 f0       	push   $0xf010503d
f0101ab2:	68 62 4e 10 f0       	push   $0xf0104e62
f0101ab7:	68 61 03 00 00       	push   $0x361
f0101abc:	68 2d 4e 10 f0       	push   $0xf0104e2d
f0101ac1:	e8 da e5 ff ff       	call   f01000a0 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101ac6:	6a 02                	push   $0x2
f0101ac8:	68 00 10 00 00       	push   $0x1000
f0101acd:	56                   	push   %esi
f0101ace:	50                   	push   %eax
f0101acf:	e8 49 f5 ff ff       	call   f010101d <page_insert>
f0101ad4:	83 c4 10             	add    $0x10,%esp
f0101ad7:	85 c0                	test   %eax,%eax
f0101ad9:	74 19                	je     f0101af4 <mem_init+0xa6b>
f0101adb:	68 40 49 10 f0       	push   $0xf0104940
f0101ae0:	68 62 4e 10 f0       	push   $0xf0104e62
f0101ae5:	68 64 03 00 00       	push   $0x364
f0101aea:	68 2d 4e 10 f0       	push   $0xf0104e2d
f0101aef:	e8 ac e5 ff ff       	call   f01000a0 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101af4:	83 ec 04             	sub    $0x4,%esp
f0101af7:	6a 00                	push   $0x0
f0101af9:	68 00 10 00 00       	push   $0x1000
f0101afe:	ff 35 48 0c 17 f0    	pushl  0xf0170c48
f0101b04:	e8 88 f3 ff ff       	call   f0100e91 <pgdir_walk>
f0101b09:	83 c4 10             	add    $0x10,%esp
f0101b0c:	f6 00 02             	testb  $0x2,(%eax)
f0101b0f:	75 19                	jne    f0101b2a <mem_init+0xaa1>
f0101b11:	68 60 4a 10 f0       	push   $0xf0104a60
f0101b16:	68 62 4e 10 f0       	push   $0xf0104e62
f0101b1b:	68 65 03 00 00       	push   $0x365
f0101b20:	68 2d 4e 10 f0       	push   $0xf0104e2d
f0101b25:	e8 76 e5 ff ff       	call   f01000a0 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101b2a:	83 ec 04             	sub    $0x4,%esp
f0101b2d:	6a 00                	push   $0x0
f0101b2f:	68 00 10 00 00       	push   $0x1000
f0101b34:	ff 35 48 0c 17 f0    	pushl  0xf0170c48
f0101b3a:	e8 52 f3 ff ff       	call   f0100e91 <pgdir_walk>
f0101b3f:	83 c4 10             	add    $0x10,%esp
f0101b42:	f6 00 04             	testb  $0x4,(%eax)
f0101b45:	74 19                	je     f0101b60 <mem_init+0xad7>
f0101b47:	68 94 4a 10 f0       	push   $0xf0104a94
f0101b4c:	68 62 4e 10 f0       	push   $0xf0104e62
f0101b51:	68 66 03 00 00       	push   $0x366
f0101b56:	68 2d 4e 10 f0       	push   $0xf0104e2d
f0101b5b:	e8 40 e5 ff ff       	call   f01000a0 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101b60:	6a 02                	push   $0x2
f0101b62:	68 00 00 40 00       	push   $0x400000
f0101b67:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101b6a:	ff 35 48 0c 17 f0    	pushl  0xf0170c48
f0101b70:	e8 a8 f4 ff ff       	call   f010101d <page_insert>
f0101b75:	83 c4 10             	add    $0x10,%esp
f0101b78:	85 c0                	test   %eax,%eax
f0101b7a:	78 19                	js     f0101b95 <mem_init+0xb0c>
f0101b7c:	68 cc 4a 10 f0       	push   $0xf0104acc
f0101b81:	68 62 4e 10 f0       	push   $0xf0104e62
f0101b86:	68 69 03 00 00       	push   $0x369
f0101b8b:	68 2d 4e 10 f0       	push   $0xf0104e2d
f0101b90:	e8 0b e5 ff ff       	call   f01000a0 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101b95:	6a 02                	push   $0x2
f0101b97:	68 00 10 00 00       	push   $0x1000
f0101b9c:	53                   	push   %ebx
f0101b9d:	ff 35 48 0c 17 f0    	pushl  0xf0170c48
f0101ba3:	e8 75 f4 ff ff       	call   f010101d <page_insert>
f0101ba8:	83 c4 10             	add    $0x10,%esp
f0101bab:	85 c0                	test   %eax,%eax
f0101bad:	74 19                	je     f0101bc8 <mem_init+0xb3f>
f0101baf:	68 04 4b 10 f0       	push   $0xf0104b04
f0101bb4:	68 62 4e 10 f0       	push   $0xf0104e62
f0101bb9:	68 6c 03 00 00       	push   $0x36c
f0101bbe:	68 2d 4e 10 f0       	push   $0xf0104e2d
f0101bc3:	e8 d8 e4 ff ff       	call   f01000a0 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101bc8:	83 ec 04             	sub    $0x4,%esp
f0101bcb:	6a 00                	push   $0x0
f0101bcd:	68 00 10 00 00       	push   $0x1000
f0101bd2:	ff 35 48 0c 17 f0    	pushl  0xf0170c48
f0101bd8:	e8 b4 f2 ff ff       	call   f0100e91 <pgdir_walk>
f0101bdd:	83 c4 10             	add    $0x10,%esp
f0101be0:	f6 00 04             	testb  $0x4,(%eax)
f0101be3:	74 19                	je     f0101bfe <mem_init+0xb75>
f0101be5:	68 94 4a 10 f0       	push   $0xf0104a94
f0101bea:	68 62 4e 10 f0       	push   $0xf0104e62
f0101bef:	68 6d 03 00 00       	push   $0x36d
f0101bf4:	68 2d 4e 10 f0       	push   $0xf0104e2d
f0101bf9:	e8 a2 e4 ff ff       	call   f01000a0 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101bfe:	8b 3d 48 0c 17 f0    	mov    0xf0170c48,%edi
f0101c04:	ba 00 00 00 00       	mov    $0x0,%edx
f0101c09:	89 f8                	mov    %edi,%eax
f0101c0b:	e8 16 ed ff ff       	call   f0100926 <check_va2pa>
f0101c10:	89 c1                	mov    %eax,%ecx
f0101c12:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101c15:	89 d8                	mov    %ebx,%eax
f0101c17:	2b 05 4c 0c 17 f0    	sub    0xf0170c4c,%eax
f0101c1d:	c1 f8 03             	sar    $0x3,%eax
f0101c20:	c1 e0 0c             	shl    $0xc,%eax
f0101c23:	39 c1                	cmp    %eax,%ecx
f0101c25:	74 19                	je     f0101c40 <mem_init+0xbb7>
f0101c27:	68 40 4b 10 f0       	push   $0xf0104b40
f0101c2c:	68 62 4e 10 f0       	push   $0xf0104e62
f0101c31:	68 70 03 00 00       	push   $0x370
f0101c36:	68 2d 4e 10 f0       	push   $0xf0104e2d
f0101c3b:	e8 60 e4 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101c40:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c45:	89 f8                	mov    %edi,%eax
f0101c47:	e8 da ec ff ff       	call   f0100926 <check_va2pa>
f0101c4c:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101c4f:	74 19                	je     f0101c6a <mem_init+0xbe1>
f0101c51:	68 6c 4b 10 f0       	push   $0xf0104b6c
f0101c56:	68 62 4e 10 f0       	push   $0xf0104e62
f0101c5b:	68 71 03 00 00       	push   $0x371
f0101c60:	68 2d 4e 10 f0       	push   $0xf0104e2d
f0101c65:	e8 36 e4 ff ff       	call   f01000a0 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101c6a:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101c6f:	74 19                	je     f0101c8a <mem_init+0xc01>
f0101c71:	68 53 50 10 f0       	push   $0xf0105053
f0101c76:	68 62 4e 10 f0       	push   $0xf0104e62
f0101c7b:	68 73 03 00 00       	push   $0x373
f0101c80:	68 2d 4e 10 f0       	push   $0xf0104e2d
f0101c85:	e8 16 e4 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101c8a:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101c8f:	74 19                	je     f0101caa <mem_init+0xc21>
f0101c91:	68 64 50 10 f0       	push   $0xf0105064
f0101c96:	68 62 4e 10 f0       	push   $0xf0104e62
f0101c9b:	68 74 03 00 00       	push   $0x374
f0101ca0:	68 2d 4e 10 f0       	push   $0xf0104e2d
f0101ca5:	e8 f6 e3 ff ff       	call   f01000a0 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101caa:	83 ec 0c             	sub    $0xc,%esp
f0101cad:	6a 00                	push   $0x0
f0101caf:	e8 04 f1 ff ff       	call   f0100db8 <page_alloc>
f0101cb4:	83 c4 10             	add    $0x10,%esp
f0101cb7:	39 c6                	cmp    %eax,%esi
f0101cb9:	75 04                	jne    f0101cbf <mem_init+0xc36>
f0101cbb:	85 c0                	test   %eax,%eax
f0101cbd:	75 19                	jne    f0101cd8 <mem_init+0xc4f>
f0101cbf:	68 9c 4b 10 f0       	push   $0xf0104b9c
f0101cc4:	68 62 4e 10 f0       	push   $0xf0104e62
f0101cc9:	68 77 03 00 00       	push   $0x377
f0101cce:	68 2d 4e 10 f0       	push   $0xf0104e2d
f0101cd3:	e8 c8 e3 ff ff       	call   f01000a0 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101cd8:	83 ec 08             	sub    $0x8,%esp
f0101cdb:	6a 00                	push   $0x0
f0101cdd:	ff 35 48 0c 17 f0    	pushl  0xf0170c48
f0101ce3:	e8 fa f2 ff ff       	call   f0100fe2 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101ce8:	8b 3d 48 0c 17 f0    	mov    0xf0170c48,%edi
f0101cee:	ba 00 00 00 00       	mov    $0x0,%edx
f0101cf3:	89 f8                	mov    %edi,%eax
f0101cf5:	e8 2c ec ff ff       	call   f0100926 <check_va2pa>
f0101cfa:	83 c4 10             	add    $0x10,%esp
f0101cfd:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101d00:	74 19                	je     f0101d1b <mem_init+0xc92>
f0101d02:	68 c0 4b 10 f0       	push   $0xf0104bc0
f0101d07:	68 62 4e 10 f0       	push   $0xf0104e62
f0101d0c:	68 7b 03 00 00       	push   $0x37b
f0101d11:	68 2d 4e 10 f0       	push   $0xf0104e2d
f0101d16:	e8 85 e3 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101d1b:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101d20:	89 f8                	mov    %edi,%eax
f0101d22:	e8 ff eb ff ff       	call   f0100926 <check_va2pa>
f0101d27:	89 da                	mov    %ebx,%edx
f0101d29:	2b 15 4c 0c 17 f0    	sub    0xf0170c4c,%edx
f0101d2f:	c1 fa 03             	sar    $0x3,%edx
f0101d32:	c1 e2 0c             	shl    $0xc,%edx
f0101d35:	39 d0                	cmp    %edx,%eax
f0101d37:	74 19                	je     f0101d52 <mem_init+0xcc9>
f0101d39:	68 6c 4b 10 f0       	push   $0xf0104b6c
f0101d3e:	68 62 4e 10 f0       	push   $0xf0104e62
f0101d43:	68 7c 03 00 00       	push   $0x37c
f0101d48:	68 2d 4e 10 f0       	push   $0xf0104e2d
f0101d4d:	e8 4e e3 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 1);
f0101d52:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101d57:	74 19                	je     f0101d72 <mem_init+0xce9>
f0101d59:	68 0a 50 10 f0       	push   $0xf010500a
f0101d5e:	68 62 4e 10 f0       	push   $0xf0104e62
f0101d63:	68 7d 03 00 00       	push   $0x37d
f0101d68:	68 2d 4e 10 f0       	push   $0xf0104e2d
f0101d6d:	e8 2e e3 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101d72:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101d77:	74 19                	je     f0101d92 <mem_init+0xd09>
f0101d79:	68 64 50 10 f0       	push   $0xf0105064
f0101d7e:	68 62 4e 10 f0       	push   $0xf0104e62
f0101d83:	68 7e 03 00 00       	push   $0x37e
f0101d88:	68 2d 4e 10 f0       	push   $0xf0104e2d
f0101d8d:	e8 0e e3 ff ff       	call   f01000a0 <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101d92:	6a 00                	push   $0x0
f0101d94:	68 00 10 00 00       	push   $0x1000
f0101d99:	53                   	push   %ebx
f0101d9a:	57                   	push   %edi
f0101d9b:	e8 7d f2 ff ff       	call   f010101d <page_insert>
f0101da0:	83 c4 10             	add    $0x10,%esp
f0101da3:	85 c0                	test   %eax,%eax
f0101da5:	74 19                	je     f0101dc0 <mem_init+0xd37>
f0101da7:	68 e4 4b 10 f0       	push   $0xf0104be4
f0101dac:	68 62 4e 10 f0       	push   $0xf0104e62
f0101db1:	68 81 03 00 00       	push   $0x381
f0101db6:	68 2d 4e 10 f0       	push   $0xf0104e2d
f0101dbb:	e8 e0 e2 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref);
f0101dc0:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101dc5:	75 19                	jne    f0101de0 <mem_init+0xd57>
f0101dc7:	68 75 50 10 f0       	push   $0xf0105075
f0101dcc:	68 62 4e 10 f0       	push   $0xf0104e62
f0101dd1:	68 82 03 00 00       	push   $0x382
f0101dd6:	68 2d 4e 10 f0       	push   $0xf0104e2d
f0101ddb:	e8 c0 e2 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_link == NULL);
f0101de0:	83 3b 00             	cmpl   $0x0,(%ebx)
f0101de3:	74 19                	je     f0101dfe <mem_init+0xd75>
f0101de5:	68 81 50 10 f0       	push   $0xf0105081
f0101dea:	68 62 4e 10 f0       	push   $0xf0104e62
f0101def:	68 83 03 00 00       	push   $0x383
f0101df4:	68 2d 4e 10 f0       	push   $0xf0104e2d
f0101df9:	e8 a2 e2 ff ff       	call   f01000a0 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101dfe:	83 ec 08             	sub    $0x8,%esp
f0101e01:	68 00 10 00 00       	push   $0x1000
f0101e06:	ff 35 48 0c 17 f0    	pushl  0xf0170c48
f0101e0c:	e8 d1 f1 ff ff       	call   f0100fe2 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101e11:	8b 3d 48 0c 17 f0    	mov    0xf0170c48,%edi
f0101e17:	ba 00 00 00 00       	mov    $0x0,%edx
f0101e1c:	89 f8                	mov    %edi,%eax
f0101e1e:	e8 03 eb ff ff       	call   f0100926 <check_va2pa>
f0101e23:	83 c4 10             	add    $0x10,%esp
f0101e26:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e29:	74 19                	je     f0101e44 <mem_init+0xdbb>
f0101e2b:	68 c0 4b 10 f0       	push   $0xf0104bc0
f0101e30:	68 62 4e 10 f0       	push   $0xf0104e62
f0101e35:	68 87 03 00 00       	push   $0x387
f0101e3a:	68 2d 4e 10 f0       	push   $0xf0104e2d
f0101e3f:	e8 5c e2 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101e44:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e49:	89 f8                	mov    %edi,%eax
f0101e4b:	e8 d6 ea ff ff       	call   f0100926 <check_va2pa>
f0101e50:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e53:	74 19                	je     f0101e6e <mem_init+0xde5>
f0101e55:	68 1c 4c 10 f0       	push   $0xf0104c1c
f0101e5a:	68 62 4e 10 f0       	push   $0xf0104e62
f0101e5f:	68 88 03 00 00       	push   $0x388
f0101e64:	68 2d 4e 10 f0       	push   $0xf0104e2d
f0101e69:	e8 32 e2 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 0);
f0101e6e:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101e73:	74 19                	je     f0101e8e <mem_init+0xe05>
f0101e75:	68 96 50 10 f0       	push   $0xf0105096
f0101e7a:	68 62 4e 10 f0       	push   $0xf0104e62
f0101e7f:	68 89 03 00 00       	push   $0x389
f0101e84:	68 2d 4e 10 f0       	push   $0xf0104e2d
f0101e89:	e8 12 e2 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101e8e:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101e93:	74 19                	je     f0101eae <mem_init+0xe25>
f0101e95:	68 64 50 10 f0       	push   $0xf0105064
f0101e9a:	68 62 4e 10 f0       	push   $0xf0104e62
f0101e9f:	68 8a 03 00 00       	push   $0x38a
f0101ea4:	68 2d 4e 10 f0       	push   $0xf0104e2d
f0101ea9:	e8 f2 e1 ff ff       	call   f01000a0 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101eae:	83 ec 0c             	sub    $0xc,%esp
f0101eb1:	6a 00                	push   $0x0
f0101eb3:	e8 00 ef ff ff       	call   f0100db8 <page_alloc>
f0101eb8:	83 c4 10             	add    $0x10,%esp
f0101ebb:	85 c0                	test   %eax,%eax
f0101ebd:	74 04                	je     f0101ec3 <mem_init+0xe3a>
f0101ebf:	39 c3                	cmp    %eax,%ebx
f0101ec1:	74 19                	je     f0101edc <mem_init+0xe53>
f0101ec3:	68 44 4c 10 f0       	push   $0xf0104c44
f0101ec8:	68 62 4e 10 f0       	push   $0xf0104e62
f0101ecd:	68 8d 03 00 00       	push   $0x38d
f0101ed2:	68 2d 4e 10 f0       	push   $0xf0104e2d
f0101ed7:	e8 c4 e1 ff ff       	call   f01000a0 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101edc:	83 ec 0c             	sub    $0xc,%esp
f0101edf:	6a 00                	push   $0x0
f0101ee1:	e8 d2 ee ff ff       	call   f0100db8 <page_alloc>
f0101ee6:	83 c4 10             	add    $0x10,%esp
f0101ee9:	85 c0                	test   %eax,%eax
f0101eeb:	74 19                	je     f0101f06 <mem_init+0xe7d>
f0101eed:	68 b8 4f 10 f0       	push   $0xf0104fb8
f0101ef2:	68 62 4e 10 f0       	push   $0xf0104e62
f0101ef7:	68 90 03 00 00       	push   $0x390
f0101efc:	68 2d 4e 10 f0       	push   $0xf0104e2d
f0101f01:	e8 9a e1 ff ff       	call   f01000a0 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101f06:	8b 0d 48 0c 17 f0    	mov    0xf0170c48,%ecx
f0101f0c:	8b 11                	mov    (%ecx),%edx
f0101f0e:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101f14:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f17:	2b 05 4c 0c 17 f0    	sub    0xf0170c4c,%eax
f0101f1d:	c1 f8 03             	sar    $0x3,%eax
f0101f20:	c1 e0 0c             	shl    $0xc,%eax
f0101f23:	39 c2                	cmp    %eax,%edx
f0101f25:	74 19                	je     f0101f40 <mem_init+0xeb7>
f0101f27:	68 e8 48 10 f0       	push   $0xf01048e8
f0101f2c:	68 62 4e 10 f0       	push   $0xf0104e62
f0101f31:	68 93 03 00 00       	push   $0x393
f0101f36:	68 2d 4e 10 f0       	push   $0xf0104e2d
f0101f3b:	e8 60 e1 ff ff       	call   f01000a0 <_panic>
	kern_pgdir[0] = 0;
f0101f40:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0101f46:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f49:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101f4e:	74 19                	je     f0101f69 <mem_init+0xee0>
f0101f50:	68 1b 50 10 f0       	push   $0xf010501b
f0101f55:	68 62 4e 10 f0       	push   $0xf0104e62
f0101f5a:	68 95 03 00 00       	push   $0x395
f0101f5f:	68 2d 4e 10 f0       	push   $0xf0104e2d
f0101f64:	e8 37 e1 ff ff       	call   f01000a0 <_panic>
	pp0->pp_ref = 0;
f0101f69:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f6c:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0101f72:	83 ec 0c             	sub    $0xc,%esp
f0101f75:	50                   	push   %eax
f0101f76:	e8 b4 ee ff ff       	call   f0100e2f <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0101f7b:	83 c4 0c             	add    $0xc,%esp
f0101f7e:	6a 01                	push   $0x1
f0101f80:	68 00 10 40 00       	push   $0x401000
f0101f85:	ff 35 48 0c 17 f0    	pushl  0xf0170c48
f0101f8b:	e8 01 ef ff ff       	call   f0100e91 <pgdir_walk>
f0101f90:	89 c7                	mov    %eax,%edi
f0101f92:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0101f95:	a1 48 0c 17 f0       	mov    0xf0170c48,%eax
f0101f9a:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101f9d:	8b 40 04             	mov    0x4(%eax),%eax
f0101fa0:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101fa5:	8b 0d 44 0c 17 f0    	mov    0xf0170c44,%ecx
f0101fab:	89 c2                	mov    %eax,%edx
f0101fad:	c1 ea 0c             	shr    $0xc,%edx
f0101fb0:	83 c4 10             	add    $0x10,%esp
f0101fb3:	39 ca                	cmp    %ecx,%edx
f0101fb5:	72 15                	jb     f0101fcc <mem_init+0xf43>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101fb7:	50                   	push   %eax
f0101fb8:	68 74 46 10 f0       	push   $0xf0104674
f0101fbd:	68 9c 03 00 00       	push   $0x39c
f0101fc2:	68 2d 4e 10 f0       	push   $0xf0104e2d
f0101fc7:	e8 d4 e0 ff ff       	call   f01000a0 <_panic>
	assert(ptep == ptep1 + PTX(va));
f0101fcc:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f0101fd1:	39 c7                	cmp    %eax,%edi
f0101fd3:	74 19                	je     f0101fee <mem_init+0xf65>
f0101fd5:	68 a7 50 10 f0       	push   $0xf01050a7
f0101fda:	68 62 4e 10 f0       	push   $0xf0104e62
f0101fdf:	68 9d 03 00 00       	push   $0x39d
f0101fe4:	68 2d 4e 10 f0       	push   $0xf0104e2d
f0101fe9:	e8 b2 e0 ff ff       	call   f01000a0 <_panic>
	kern_pgdir[PDX(va)] = 0;
f0101fee:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101ff1:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f0101ff8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ffb:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102001:	2b 05 4c 0c 17 f0    	sub    0xf0170c4c,%eax
f0102007:	c1 f8 03             	sar    $0x3,%eax
f010200a:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010200d:	89 c2                	mov    %eax,%edx
f010200f:	c1 ea 0c             	shr    $0xc,%edx
f0102012:	39 d1                	cmp    %edx,%ecx
f0102014:	77 12                	ja     f0102028 <mem_init+0xf9f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102016:	50                   	push   %eax
f0102017:	68 74 46 10 f0       	push   $0xf0104674
f010201c:	6a 56                	push   $0x56
f010201e:	68 48 4e 10 f0       	push   $0xf0104e48
f0102023:	e8 78 e0 ff ff       	call   f01000a0 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0102028:	83 ec 04             	sub    $0x4,%esp
f010202b:	68 00 10 00 00       	push   $0x1000
f0102030:	68 ff 00 00 00       	push   $0xff
f0102035:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010203a:	50                   	push   %eax
f010203b:	e8 9b 1c 00 00       	call   f0103cdb <memset>
	page_free(pp0);
f0102040:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102043:	89 3c 24             	mov    %edi,(%esp)
f0102046:	e8 e4 ed ff ff       	call   f0100e2f <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f010204b:	83 c4 0c             	add    $0xc,%esp
f010204e:	6a 01                	push   $0x1
f0102050:	6a 00                	push   $0x0
f0102052:	ff 35 48 0c 17 f0    	pushl  0xf0170c48
f0102058:	e8 34 ee ff ff       	call   f0100e91 <pgdir_walk>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010205d:	89 fa                	mov    %edi,%edx
f010205f:	2b 15 4c 0c 17 f0    	sub    0xf0170c4c,%edx
f0102065:	c1 fa 03             	sar    $0x3,%edx
f0102068:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010206b:	89 d0                	mov    %edx,%eax
f010206d:	c1 e8 0c             	shr    $0xc,%eax
f0102070:	83 c4 10             	add    $0x10,%esp
f0102073:	3b 05 44 0c 17 f0    	cmp    0xf0170c44,%eax
f0102079:	72 12                	jb     f010208d <mem_init+0x1004>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010207b:	52                   	push   %edx
f010207c:	68 74 46 10 f0       	push   $0xf0104674
f0102081:	6a 56                	push   $0x56
f0102083:	68 48 4e 10 f0       	push   $0xf0104e48
f0102088:	e8 13 e0 ff ff       	call   f01000a0 <_panic>
	return (void *)(pa + KERNBASE);
f010208d:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f0102093:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102096:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f010209c:	f6 00 01             	testb  $0x1,(%eax)
f010209f:	74 19                	je     f01020ba <mem_init+0x1031>
f01020a1:	68 bf 50 10 f0       	push   $0xf01050bf
f01020a6:	68 62 4e 10 f0       	push   $0xf0104e62
f01020ab:	68 a7 03 00 00       	push   $0x3a7
f01020b0:	68 2d 4e 10 f0       	push   $0xf0104e2d
f01020b5:	e8 e6 df ff ff       	call   f01000a0 <_panic>
f01020ba:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f01020bd:	39 d0                	cmp    %edx,%eax
f01020bf:	75 db                	jne    f010209c <mem_init+0x1013>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f01020c1:	a1 48 0c 17 f0       	mov    0xf0170c48,%eax
f01020c6:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f01020cc:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01020cf:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f01020d5:	8b 7d d0             	mov    -0x30(%ebp),%edi
f01020d8:	89 3d 7c ff 16 f0    	mov    %edi,0xf016ff7c

	// free the pages we took
	page_free(pp0);
f01020de:	83 ec 0c             	sub    $0xc,%esp
f01020e1:	50                   	push   %eax
f01020e2:	e8 48 ed ff ff       	call   f0100e2f <page_free>
	page_free(pp1);
f01020e7:	89 1c 24             	mov    %ebx,(%esp)
f01020ea:	e8 40 ed ff ff       	call   f0100e2f <page_free>
	page_free(pp2);
f01020ef:	89 34 24             	mov    %esi,(%esp)
f01020f2:	e8 38 ed ff ff       	call   f0100e2f <page_free>

	cprintf("check_page() succeeded!\n");
f01020f7:	c7 04 24 d6 50 10 f0 	movl   $0xf01050d6,(%esp)
f01020fe:	e8 54 0d 00 00       	call   f0102e57 <cprintf>
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	
	boot_map_region(kern_pgdir, UPAGES, PTSIZE, PADDR(pages), PTE_U);
f0102103:	a1 4c 0c 17 f0       	mov    0xf0170c4c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102108:	83 c4 10             	add    $0x10,%esp
f010210b:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102110:	77 15                	ja     f0102127 <mem_init+0x109e>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102112:	50                   	push   %eax
f0102113:	68 98 46 10 f0       	push   $0xf0104698
f0102118:	68 bd 00 00 00       	push   $0xbd
f010211d:	68 2d 4e 10 f0       	push   $0xf0104e2d
f0102122:	e8 79 df ff ff       	call   f01000a0 <_panic>
f0102127:	83 ec 08             	sub    $0x8,%esp
f010212a:	6a 04                	push   $0x4
f010212c:	05 00 00 00 10       	add    $0x10000000,%eax
f0102131:	50                   	push   %eax
f0102132:	b9 00 00 40 00       	mov    $0x400000,%ecx
f0102137:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f010213c:	a1 48 0c 17 f0       	mov    0xf0170c48,%eax
f0102141:	e8 e0 ed ff ff       	call   f0100f26 <boot_map_region>
	// (ie. perm = PTE_U | PTE_P).
	// Permissions:
	//    - the new image at UENVS  -- kernel R, user R
	//    - envs itself -- kernel RW, user NONE
	// LAB 3: Your code here.
	boot_map_region(kern_pgdir, UENVS, PTSIZE, PADDR(envs), PTE_U);
f0102146:	a1 84 ff 16 f0       	mov    0xf016ff84,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010214b:	83 c4 10             	add    $0x10,%esp
f010214e:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102153:	77 15                	ja     f010216a <mem_init+0x10e1>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102155:	50                   	push   %eax
f0102156:	68 98 46 10 f0       	push   $0xf0104698
f010215b:	68 c6 00 00 00       	push   $0xc6
f0102160:	68 2d 4e 10 f0       	push   $0xf0104e2d
f0102165:	e8 36 df ff ff       	call   f01000a0 <_panic>
f010216a:	83 ec 08             	sub    $0x8,%esp
f010216d:	6a 04                	push   $0x4
f010216f:	05 00 00 00 10       	add    $0x10000000,%eax
f0102174:	50                   	push   %eax
f0102175:	b9 00 00 40 00       	mov    $0x400000,%ecx
f010217a:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f010217f:	a1 48 0c 17 f0       	mov    0xf0170c48,%eax
f0102184:	e8 9d ed ff ff       	call   f0100f26 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102189:	83 c4 10             	add    $0x10,%esp
f010218c:	b8 00 00 11 f0       	mov    $0xf0110000,%eax
f0102191:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102196:	77 15                	ja     f01021ad <mem_init+0x1124>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102198:	50                   	push   %eax
f0102199:	68 98 46 10 f0       	push   $0xf0104698
f010219e:	68 d3 00 00 00       	push   $0xd3
f01021a3:	68 2d 4e 10 f0       	push   $0xf0104e2d
f01021a8:	e8 f3 de ff ff       	call   f01000a0 <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KSTACKTOP-KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W);
f01021ad:	83 ec 08             	sub    $0x8,%esp
f01021b0:	6a 02                	push   $0x2
f01021b2:	68 00 00 11 00       	push   $0x110000
f01021b7:	b9 00 80 00 00       	mov    $0x8000,%ecx
f01021bc:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f01021c1:	a1 48 0c 17 f0       	mov    0xf0170c48,%eax
f01021c6:	e8 5b ed ff ff       	call   f0100f26 <boot_map_region>
	//      the PA range [0, 2^32 - KERNBASE)
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KERNBASE, 0xffffffff - KERNBASE, 0, PTE_W);
f01021cb:	83 c4 08             	add    $0x8,%esp
f01021ce:	6a 02                	push   $0x2
f01021d0:	6a 00                	push   $0x0
f01021d2:	b9 ff ff ff 0f       	mov    $0xfffffff,%ecx
f01021d7:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f01021dc:	a1 48 0c 17 f0       	mov    0xf0170c48,%eax
f01021e1:	e8 40 ed ff ff       	call   f0100f26 <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f01021e6:	8b 1d 48 0c 17 f0    	mov    0xf0170c48,%ebx

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f01021ec:	a1 44 0c 17 f0       	mov    0xf0170c44,%eax
f01021f1:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01021f4:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f01021fb:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102200:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102203:	8b 3d 4c 0c 17 f0    	mov    0xf0170c4c,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102209:	89 7d d0             	mov    %edi,-0x30(%ebp)
f010220c:	83 c4 10             	add    $0x10,%esp

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f010220f:	be 00 00 00 00       	mov    $0x0,%esi
f0102214:	eb 55                	jmp    f010226b <mem_init+0x11e2>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102216:	8d 96 00 00 00 ef    	lea    -0x11000000(%esi),%edx
f010221c:	89 d8                	mov    %ebx,%eax
f010221e:	e8 03 e7 ff ff       	call   f0100926 <check_va2pa>
f0102223:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f010222a:	77 15                	ja     f0102241 <mem_init+0x11b8>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010222c:	57                   	push   %edi
f010222d:	68 98 46 10 f0       	push   $0xf0104698
f0102232:	68 e4 02 00 00       	push   $0x2e4
f0102237:	68 2d 4e 10 f0       	push   $0xf0104e2d
f010223c:	e8 5f de ff ff       	call   f01000a0 <_panic>
f0102241:	8d 94 37 00 00 00 10 	lea    0x10000000(%edi,%esi,1),%edx
f0102248:	39 d0                	cmp    %edx,%eax
f010224a:	74 19                	je     f0102265 <mem_init+0x11dc>
f010224c:	68 68 4c 10 f0       	push   $0xf0104c68
f0102251:	68 62 4e 10 f0       	push   $0xf0104e62
f0102256:	68 e4 02 00 00       	push   $0x2e4
f010225b:	68 2d 4e 10 f0       	push   $0xf0104e2d
f0102260:	e8 3b de ff ff       	call   f01000a0 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102265:	81 c6 00 10 00 00    	add    $0x1000,%esi
f010226b:	39 75 d4             	cmp    %esi,-0x2c(%ebp)
f010226e:	77 a6                	ja     f0102216 <mem_init+0x118d>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f0102270:	8b 3d 84 ff 16 f0    	mov    0xf016ff84,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102276:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0102279:	be 00 00 c0 ee       	mov    $0xeec00000,%esi
f010227e:	89 f2                	mov    %esi,%edx
f0102280:	89 d8                	mov    %ebx,%eax
f0102282:	e8 9f e6 ff ff       	call   f0100926 <check_va2pa>
f0102287:	81 7d d4 ff ff ff ef 	cmpl   $0xefffffff,-0x2c(%ebp)
f010228e:	77 15                	ja     f01022a5 <mem_init+0x121c>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102290:	57                   	push   %edi
f0102291:	68 98 46 10 f0       	push   $0xf0104698
f0102296:	68 e9 02 00 00       	push   $0x2e9
f010229b:	68 2d 4e 10 f0       	push   $0xf0104e2d
f01022a0:	e8 fb dd ff ff       	call   f01000a0 <_panic>
f01022a5:	8d 94 37 00 00 40 21 	lea    0x21400000(%edi,%esi,1),%edx
f01022ac:	39 c2                	cmp    %eax,%edx
f01022ae:	74 19                	je     f01022c9 <mem_init+0x1240>
f01022b0:	68 9c 4c 10 f0       	push   $0xf0104c9c
f01022b5:	68 62 4e 10 f0       	push   $0xf0104e62
f01022ba:	68 e9 02 00 00       	push   $0x2e9
f01022bf:	68 2d 4e 10 f0       	push   $0xf0104e2d
f01022c4:	e8 d7 dd ff ff       	call   f01000a0 <_panic>
f01022c9:	81 c6 00 10 00 00    	add    $0x1000,%esi
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01022cf:	81 fe 00 80 c1 ee    	cmp    $0xeec18000,%esi
f01022d5:	75 a7                	jne    f010227e <mem_init+0x11f5>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01022d7:	8b 7d cc             	mov    -0x34(%ebp),%edi
f01022da:	c1 e7 0c             	shl    $0xc,%edi
f01022dd:	be 00 00 00 00       	mov    $0x0,%esi
f01022e2:	eb 30                	jmp    f0102314 <mem_init+0x128b>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f01022e4:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
f01022ea:	89 d8                	mov    %ebx,%eax
f01022ec:	e8 35 e6 ff ff       	call   f0100926 <check_va2pa>
f01022f1:	39 c6                	cmp    %eax,%esi
f01022f3:	74 19                	je     f010230e <mem_init+0x1285>
f01022f5:	68 d0 4c 10 f0       	push   $0xf0104cd0
f01022fa:	68 62 4e 10 f0       	push   $0xf0104e62
f01022ff:	68 ed 02 00 00       	push   $0x2ed
f0102304:	68 2d 4e 10 f0       	push   $0xf0104e2d
f0102309:	e8 92 dd ff ff       	call   f01000a0 <_panic>
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f010230e:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102314:	39 fe                	cmp    %edi,%esi
f0102316:	72 cc                	jb     f01022e4 <mem_init+0x125b>
f0102318:	be 00 80 ff ef       	mov    $0xefff8000,%esi
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f010231d:	89 f2                	mov    %esi,%edx
f010231f:	89 d8                	mov    %ebx,%eax
f0102321:	e8 00 e6 ff ff       	call   f0100926 <check_va2pa>
f0102326:	8d 96 00 80 11 10    	lea    0x10118000(%esi),%edx
f010232c:	39 c2                	cmp    %eax,%edx
f010232e:	74 19                	je     f0102349 <mem_init+0x12c0>
f0102330:	68 f8 4c 10 f0       	push   $0xf0104cf8
f0102335:	68 62 4e 10 f0       	push   $0xf0104e62
f010233a:	68 f1 02 00 00       	push   $0x2f1
f010233f:	68 2d 4e 10 f0       	push   $0xf0104e2d
f0102344:	e8 57 dd ff ff       	call   f01000a0 <_panic>
f0102349:	81 c6 00 10 00 00    	add    $0x1000,%esi
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f010234f:	81 fe 00 00 00 f0    	cmp    $0xf0000000,%esi
f0102355:	75 c6                	jne    f010231d <mem_init+0x1294>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102357:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f010235c:	89 d8                	mov    %ebx,%eax
f010235e:	e8 c3 e5 ff ff       	call   f0100926 <check_va2pa>
f0102363:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102366:	74 51                	je     f01023b9 <mem_init+0x1330>
f0102368:	68 40 4d 10 f0       	push   $0xf0104d40
f010236d:	68 62 4e 10 f0       	push   $0xf0104e62
f0102372:	68 f2 02 00 00       	push   $0x2f2
f0102377:	68 2d 4e 10 f0       	push   $0xf0104e2d
f010237c:	e8 1f dd ff ff       	call   f01000a0 <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f0102381:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f0102386:	72 36                	jb     f01023be <mem_init+0x1335>
f0102388:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f010238d:	76 07                	jbe    f0102396 <mem_init+0x130d>
f010238f:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102394:	75 28                	jne    f01023be <mem_init+0x1335>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
		case PDX(UENVS):
			assert(pgdir[i] & PTE_P);
f0102396:	f6 04 83 01          	testb  $0x1,(%ebx,%eax,4)
f010239a:	0f 85 83 00 00 00    	jne    f0102423 <mem_init+0x139a>
f01023a0:	68 ef 50 10 f0       	push   $0xf01050ef
f01023a5:	68 62 4e 10 f0       	push   $0xf0104e62
f01023aa:	68 fb 02 00 00       	push   $0x2fb
f01023af:	68 2d 4e 10 f0       	push   $0xf0104e2d
f01023b4:	e8 e7 dc ff ff       	call   f01000a0 <_panic>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f01023b9:	b8 00 00 00 00       	mov    $0x0,%eax
		case PDX(UPAGES):
		case PDX(UENVS):
			assert(pgdir[i] & PTE_P);
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f01023be:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f01023c3:	76 3f                	jbe    f0102404 <mem_init+0x137b>
				assert(pgdir[i] & PTE_P);
f01023c5:	8b 14 83             	mov    (%ebx,%eax,4),%edx
f01023c8:	f6 c2 01             	test   $0x1,%dl
f01023cb:	75 19                	jne    f01023e6 <mem_init+0x135d>
f01023cd:	68 ef 50 10 f0       	push   $0xf01050ef
f01023d2:	68 62 4e 10 f0       	push   $0xf0104e62
f01023d7:	68 ff 02 00 00       	push   $0x2ff
f01023dc:	68 2d 4e 10 f0       	push   $0xf0104e2d
f01023e1:	e8 ba dc ff ff       	call   f01000a0 <_panic>
				assert(pgdir[i] & PTE_W);
f01023e6:	f6 c2 02             	test   $0x2,%dl
f01023e9:	75 38                	jne    f0102423 <mem_init+0x139a>
f01023eb:	68 00 51 10 f0       	push   $0xf0105100
f01023f0:	68 62 4e 10 f0       	push   $0xf0104e62
f01023f5:	68 00 03 00 00       	push   $0x300
f01023fa:	68 2d 4e 10 f0       	push   $0xf0104e2d
f01023ff:	e8 9c dc ff ff       	call   f01000a0 <_panic>
			} else
				assert(pgdir[i] == 0);
f0102404:	83 3c 83 00          	cmpl   $0x0,(%ebx,%eax,4)
f0102408:	74 19                	je     f0102423 <mem_init+0x139a>
f010240a:	68 11 51 10 f0       	push   $0xf0105111
f010240f:	68 62 4e 10 f0       	push   $0xf0104e62
f0102414:	68 02 03 00 00       	push   $0x302
f0102419:	68 2d 4e 10 f0       	push   $0xf0104e2d
f010241e:	e8 7d dc ff ff       	call   f01000a0 <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0102423:	83 c0 01             	add    $0x1,%eax
f0102426:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f010242b:	0f 86 50 ff ff ff    	jbe    f0102381 <mem_init+0x12f8>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f0102431:	83 ec 0c             	sub    $0xc,%esp
f0102434:	68 70 4d 10 f0       	push   $0xf0104d70
f0102439:	e8 19 0a 00 00       	call   f0102e57 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f010243e:	a1 48 0c 17 f0       	mov    0xf0170c48,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102443:	83 c4 10             	add    $0x10,%esp
f0102446:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010244b:	77 15                	ja     f0102462 <mem_init+0x13d9>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010244d:	50                   	push   %eax
f010244e:	68 98 46 10 f0       	push   $0xf0104698
f0102453:	68 e9 00 00 00       	push   $0xe9
f0102458:	68 2d 4e 10 f0       	push   $0xf0104e2d
f010245d:	e8 3e dc ff ff       	call   f01000a0 <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0102462:	05 00 00 00 10       	add    $0x10000000,%eax
f0102467:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f010246a:	b8 00 00 00 00       	mov    $0x0,%eax
f010246f:	e8 9d e5 ff ff       	call   f0100a11 <check_page_free_list>

static inline uint32_t
rcr0(void)
{
	uint32_t val;
	asm volatile("movl %%cr0,%0" : "=r" (val));
f0102474:	0f 20 c0             	mov    %cr0,%eax
f0102477:	83 e0 f3             	and    $0xfffffff3,%eax
}

static inline void
lcr0(uint32_t val)
{
	asm volatile("movl %0,%%cr0" : : "r" (val));
f010247a:	0d 23 00 05 80       	or     $0x80050023,%eax
f010247f:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102482:	83 ec 0c             	sub    $0xc,%esp
f0102485:	6a 00                	push   $0x0
f0102487:	e8 2c e9 ff ff       	call   f0100db8 <page_alloc>
f010248c:	89 c3                	mov    %eax,%ebx
f010248e:	83 c4 10             	add    $0x10,%esp
f0102491:	85 c0                	test   %eax,%eax
f0102493:	75 19                	jne    f01024ae <mem_init+0x1425>
f0102495:	68 0d 4f 10 f0       	push   $0xf0104f0d
f010249a:	68 62 4e 10 f0       	push   $0xf0104e62
f010249f:	68 c2 03 00 00       	push   $0x3c2
f01024a4:	68 2d 4e 10 f0       	push   $0xf0104e2d
f01024a9:	e8 f2 db ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f01024ae:	83 ec 0c             	sub    $0xc,%esp
f01024b1:	6a 00                	push   $0x0
f01024b3:	e8 00 e9 ff ff       	call   f0100db8 <page_alloc>
f01024b8:	89 c7                	mov    %eax,%edi
f01024ba:	83 c4 10             	add    $0x10,%esp
f01024bd:	85 c0                	test   %eax,%eax
f01024bf:	75 19                	jne    f01024da <mem_init+0x1451>
f01024c1:	68 23 4f 10 f0       	push   $0xf0104f23
f01024c6:	68 62 4e 10 f0       	push   $0xf0104e62
f01024cb:	68 c3 03 00 00       	push   $0x3c3
f01024d0:	68 2d 4e 10 f0       	push   $0xf0104e2d
f01024d5:	e8 c6 db ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f01024da:	83 ec 0c             	sub    $0xc,%esp
f01024dd:	6a 00                	push   $0x0
f01024df:	e8 d4 e8 ff ff       	call   f0100db8 <page_alloc>
f01024e4:	89 c6                	mov    %eax,%esi
f01024e6:	83 c4 10             	add    $0x10,%esp
f01024e9:	85 c0                	test   %eax,%eax
f01024eb:	75 19                	jne    f0102506 <mem_init+0x147d>
f01024ed:	68 39 4f 10 f0       	push   $0xf0104f39
f01024f2:	68 62 4e 10 f0       	push   $0xf0104e62
f01024f7:	68 c4 03 00 00       	push   $0x3c4
f01024fc:	68 2d 4e 10 f0       	push   $0xf0104e2d
f0102501:	e8 9a db ff ff       	call   f01000a0 <_panic>
	page_free(pp0);
f0102506:	83 ec 0c             	sub    $0xc,%esp
f0102509:	53                   	push   %ebx
f010250a:	e8 20 e9 ff ff       	call   f0100e2f <page_free>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010250f:	89 f8                	mov    %edi,%eax
f0102511:	2b 05 4c 0c 17 f0    	sub    0xf0170c4c,%eax
f0102517:	c1 f8 03             	sar    $0x3,%eax
f010251a:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010251d:	89 c2                	mov    %eax,%edx
f010251f:	c1 ea 0c             	shr    $0xc,%edx
f0102522:	83 c4 10             	add    $0x10,%esp
f0102525:	3b 15 44 0c 17 f0    	cmp    0xf0170c44,%edx
f010252b:	72 12                	jb     f010253f <mem_init+0x14b6>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010252d:	50                   	push   %eax
f010252e:	68 74 46 10 f0       	push   $0xf0104674
f0102533:	6a 56                	push   $0x56
f0102535:	68 48 4e 10 f0       	push   $0xf0104e48
f010253a:	e8 61 db ff ff       	call   f01000a0 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f010253f:	83 ec 04             	sub    $0x4,%esp
f0102542:	68 00 10 00 00       	push   $0x1000
f0102547:	6a 01                	push   $0x1
f0102549:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010254e:	50                   	push   %eax
f010254f:	e8 87 17 00 00       	call   f0103cdb <memset>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102554:	89 f0                	mov    %esi,%eax
f0102556:	2b 05 4c 0c 17 f0    	sub    0xf0170c4c,%eax
f010255c:	c1 f8 03             	sar    $0x3,%eax
f010255f:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102562:	89 c2                	mov    %eax,%edx
f0102564:	c1 ea 0c             	shr    $0xc,%edx
f0102567:	83 c4 10             	add    $0x10,%esp
f010256a:	3b 15 44 0c 17 f0    	cmp    0xf0170c44,%edx
f0102570:	72 12                	jb     f0102584 <mem_init+0x14fb>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102572:	50                   	push   %eax
f0102573:	68 74 46 10 f0       	push   $0xf0104674
f0102578:	6a 56                	push   $0x56
f010257a:	68 48 4e 10 f0       	push   $0xf0104e48
f010257f:	e8 1c db ff ff       	call   f01000a0 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f0102584:	83 ec 04             	sub    $0x4,%esp
f0102587:	68 00 10 00 00       	push   $0x1000
f010258c:	6a 02                	push   $0x2
f010258e:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102593:	50                   	push   %eax
f0102594:	e8 42 17 00 00       	call   f0103cdb <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102599:	6a 02                	push   $0x2
f010259b:	68 00 10 00 00       	push   $0x1000
f01025a0:	57                   	push   %edi
f01025a1:	ff 35 48 0c 17 f0    	pushl  0xf0170c48
f01025a7:	e8 71 ea ff ff       	call   f010101d <page_insert>
	assert(pp1->pp_ref == 1);
f01025ac:	83 c4 20             	add    $0x20,%esp
f01025af:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f01025b4:	74 19                	je     f01025cf <mem_init+0x1546>
f01025b6:	68 0a 50 10 f0       	push   $0xf010500a
f01025bb:	68 62 4e 10 f0       	push   $0xf0104e62
f01025c0:	68 c9 03 00 00       	push   $0x3c9
f01025c5:	68 2d 4e 10 f0       	push   $0xf0104e2d
f01025ca:	e8 d1 da ff ff       	call   f01000a0 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f01025cf:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f01025d6:	01 01 01 
f01025d9:	74 19                	je     f01025f4 <mem_init+0x156b>
f01025db:	68 90 4d 10 f0       	push   $0xf0104d90
f01025e0:	68 62 4e 10 f0       	push   $0xf0104e62
f01025e5:	68 ca 03 00 00       	push   $0x3ca
f01025ea:	68 2d 4e 10 f0       	push   $0xf0104e2d
f01025ef:	e8 ac da ff ff       	call   f01000a0 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f01025f4:	6a 02                	push   $0x2
f01025f6:	68 00 10 00 00       	push   $0x1000
f01025fb:	56                   	push   %esi
f01025fc:	ff 35 48 0c 17 f0    	pushl  0xf0170c48
f0102602:	e8 16 ea ff ff       	call   f010101d <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102607:	83 c4 10             	add    $0x10,%esp
f010260a:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102611:	02 02 02 
f0102614:	74 19                	je     f010262f <mem_init+0x15a6>
f0102616:	68 b4 4d 10 f0       	push   $0xf0104db4
f010261b:	68 62 4e 10 f0       	push   $0xf0104e62
f0102620:	68 cc 03 00 00       	push   $0x3cc
f0102625:	68 2d 4e 10 f0       	push   $0xf0104e2d
f010262a:	e8 71 da ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f010262f:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102634:	74 19                	je     f010264f <mem_init+0x15c6>
f0102636:	68 2c 50 10 f0       	push   $0xf010502c
f010263b:	68 62 4e 10 f0       	push   $0xf0104e62
f0102640:	68 cd 03 00 00       	push   $0x3cd
f0102645:	68 2d 4e 10 f0       	push   $0xf0104e2d
f010264a:	e8 51 da ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 0);
f010264f:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102654:	74 19                	je     f010266f <mem_init+0x15e6>
f0102656:	68 96 50 10 f0       	push   $0xf0105096
f010265b:	68 62 4e 10 f0       	push   $0xf0104e62
f0102660:	68 ce 03 00 00       	push   $0x3ce
f0102665:	68 2d 4e 10 f0       	push   $0xf0104e2d
f010266a:	e8 31 da ff ff       	call   f01000a0 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f010266f:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102676:	03 03 03 
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102679:	89 f0                	mov    %esi,%eax
f010267b:	2b 05 4c 0c 17 f0    	sub    0xf0170c4c,%eax
f0102681:	c1 f8 03             	sar    $0x3,%eax
f0102684:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102687:	89 c2                	mov    %eax,%edx
f0102689:	c1 ea 0c             	shr    $0xc,%edx
f010268c:	3b 15 44 0c 17 f0    	cmp    0xf0170c44,%edx
f0102692:	72 12                	jb     f01026a6 <mem_init+0x161d>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102694:	50                   	push   %eax
f0102695:	68 74 46 10 f0       	push   $0xf0104674
f010269a:	6a 56                	push   $0x56
f010269c:	68 48 4e 10 f0       	push   $0xf0104e48
f01026a1:	e8 fa d9 ff ff       	call   f01000a0 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f01026a6:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f01026ad:	03 03 03 
f01026b0:	74 19                	je     f01026cb <mem_init+0x1642>
f01026b2:	68 d8 4d 10 f0       	push   $0xf0104dd8
f01026b7:	68 62 4e 10 f0       	push   $0xf0104e62
f01026bc:	68 d0 03 00 00       	push   $0x3d0
f01026c1:	68 2d 4e 10 f0       	push   $0xf0104e2d
f01026c6:	e8 d5 d9 ff ff       	call   f01000a0 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f01026cb:	83 ec 08             	sub    $0x8,%esp
f01026ce:	68 00 10 00 00       	push   $0x1000
f01026d3:	ff 35 48 0c 17 f0    	pushl  0xf0170c48
f01026d9:	e8 04 e9 ff ff       	call   f0100fe2 <page_remove>
	assert(pp2->pp_ref == 0);
f01026de:	83 c4 10             	add    $0x10,%esp
f01026e1:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01026e6:	74 19                	je     f0102701 <mem_init+0x1678>
f01026e8:	68 64 50 10 f0       	push   $0xf0105064
f01026ed:	68 62 4e 10 f0       	push   $0xf0104e62
f01026f2:	68 d2 03 00 00       	push   $0x3d2
f01026f7:	68 2d 4e 10 f0       	push   $0xf0104e2d
f01026fc:	e8 9f d9 ff ff       	call   f01000a0 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102701:	8b 0d 48 0c 17 f0    	mov    0xf0170c48,%ecx
f0102707:	8b 11                	mov    (%ecx),%edx
f0102709:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010270f:	89 d8                	mov    %ebx,%eax
f0102711:	2b 05 4c 0c 17 f0    	sub    0xf0170c4c,%eax
f0102717:	c1 f8 03             	sar    $0x3,%eax
f010271a:	c1 e0 0c             	shl    $0xc,%eax
f010271d:	39 c2                	cmp    %eax,%edx
f010271f:	74 19                	je     f010273a <mem_init+0x16b1>
f0102721:	68 e8 48 10 f0       	push   $0xf01048e8
f0102726:	68 62 4e 10 f0       	push   $0xf0104e62
f010272b:	68 d5 03 00 00       	push   $0x3d5
f0102730:	68 2d 4e 10 f0       	push   $0xf0104e2d
f0102735:	e8 66 d9 ff ff       	call   f01000a0 <_panic>
	kern_pgdir[0] = 0;
f010273a:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102740:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102745:	74 19                	je     f0102760 <mem_init+0x16d7>
f0102747:	68 1b 50 10 f0       	push   $0xf010501b
f010274c:	68 62 4e 10 f0       	push   $0xf0104e62
f0102751:	68 d7 03 00 00       	push   $0x3d7
f0102756:	68 2d 4e 10 f0       	push   $0xf0104e2d
f010275b:	e8 40 d9 ff ff       	call   f01000a0 <_panic>
	pp0->pp_ref = 0;
f0102760:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f0102766:	83 ec 0c             	sub    $0xc,%esp
f0102769:	53                   	push   %ebx
f010276a:	e8 c0 e6 ff ff       	call   f0100e2f <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f010276f:	c7 04 24 04 4e 10 f0 	movl   $0xf0104e04,(%esp)
f0102776:	e8 dc 06 00 00       	call   f0102e57 <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f010277b:	83 c4 10             	add    $0x10,%esp
f010277e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102781:	5b                   	pop    %ebx
f0102782:	5e                   	pop    %esi
f0102783:	5f                   	pop    %edi
f0102784:	5d                   	pop    %ebp
f0102785:	c3                   	ret    

f0102786 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0102786:	55                   	push   %ebp
f0102787:	89 e5                	mov    %esp,%ebp
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0102789:	8b 45 0c             	mov    0xc(%ebp),%eax
f010278c:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f010278f:	5d                   	pop    %ebp
f0102790:	c3                   	ret    

f0102791 <user_mem_check>:
// Returns 0 if the user program can access this range of addresses,
// and -E_FAULT otherwise.
//
int
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
f0102791:	55                   	push   %ebp
f0102792:	89 e5                	mov    %esp,%ebp
	// LAB 3: Your code here.

	return 0;
}
f0102794:	b8 00 00 00 00       	mov    $0x0,%eax
f0102799:	5d                   	pop    %ebp
f010279a:	c3                   	ret    

f010279b <user_mem_assert>:
// If it cannot, 'env' is destroyed and, if env is the current
// environment, this function will not return.
//
void
user_mem_assert(struct Env *env, const void *va, size_t len, int perm)
{
f010279b:	55                   	push   %ebp
f010279c:	89 e5                	mov    %esp,%ebp
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
		cprintf("[%08x] user_mem_check assertion failure for "
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
	}
}
f010279e:	5d                   	pop    %ebp
f010279f:	c3                   	ret    

f01027a0 <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f01027a0:	55                   	push   %ebp
f01027a1:	89 e5                	mov    %esp,%ebp
f01027a3:	57                   	push   %edi
f01027a4:	56                   	push   %esi
f01027a5:	53                   	push   %ebx
f01027a6:	83 ec 0c             	sub    $0xc,%esp
f01027a9:	89 c7                	mov    %eax,%edi
	//
	// Hint: It is easier to use region_alloc if the caller can pass
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	va = ROUNDDOWN(va, PGSIZE);
f01027ab:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01027b1:	89 d3                	mov    %edx,%ebx
	void *end = ROUNDUP(va + len, PGSIZE);
f01027b3:	8d b4 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%esi
f01027ba:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	for(; va < end;va+=PGSIZE){
f01027c0:	eb 3d                	jmp    f01027ff <region_alloc+0x5f>
		struct PageInfo *pp = page_alloc(1);	
f01027c2:	83 ec 0c             	sub    $0xc,%esp
f01027c5:	6a 01                	push   $0x1
f01027c7:	e8 ec e5 ff ff       	call   f0100db8 <page_alloc>
		if(pp == NULL){
f01027cc:	83 c4 10             	add    $0x10,%esp
f01027cf:	85 c0                	test   %eax,%eax
f01027d1:	75 17                	jne    f01027ea <region_alloc+0x4a>
			panic("page alloc failed!\n");	
f01027d3:	83 ec 04             	sub    $0x4,%esp
f01027d6:	68 1f 51 10 f0       	push   $0xf010511f
f01027db:	68 1b 01 00 00       	push   $0x11b
f01027e0:	68 33 51 10 f0       	push   $0xf0105133
f01027e5:	e8 b6 d8 ff ff       	call   f01000a0 <_panic>
		}
		page_insert(e->env_pgdir, pp, va, PTE_U | PTE_W);	
f01027ea:	6a 06                	push   $0x6
f01027ec:	53                   	push   %ebx
f01027ed:	50                   	push   %eax
f01027ee:	ff 77 5c             	pushl  0x5c(%edi)
f01027f1:	e8 27 e8 ff ff       	call   f010101d <page_insert>
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	va = ROUNDDOWN(va, PGSIZE);
	void *end = ROUNDUP(va + len, PGSIZE);
	for(; va < end;va+=PGSIZE){
f01027f6:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01027fc:	83 c4 10             	add    $0x10,%esp
f01027ff:	39 f3                	cmp    %esi,%ebx
f0102801:	72 bf                	jb     f01027c2 <region_alloc+0x22>
		if(pp == NULL){
			panic("page alloc failed!\n");	
		}
		page_insert(e->env_pgdir, pp, va, PTE_U | PTE_W);	
	}
}
f0102803:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102806:	5b                   	pop    %ebx
f0102807:	5e                   	pop    %esi
f0102808:	5f                   	pop    %edi
f0102809:	5d                   	pop    %ebp
f010280a:	c3                   	ret    

f010280b <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f010280b:	55                   	push   %ebp
f010280c:	89 e5                	mov    %esp,%ebp
f010280e:	8b 55 08             	mov    0x8(%ebp),%edx
f0102811:	8b 4d 10             	mov    0x10(%ebp),%ecx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f0102814:	85 d2                	test   %edx,%edx
f0102816:	75 11                	jne    f0102829 <envid2env+0x1e>
		*env_store = curenv;
f0102818:	a1 80 ff 16 f0       	mov    0xf016ff80,%eax
f010281d:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0102820:	89 01                	mov    %eax,(%ecx)
		return 0;
f0102822:	b8 00 00 00 00       	mov    $0x0,%eax
f0102827:	eb 5e                	jmp    f0102887 <envid2env+0x7c>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f0102829:	89 d0                	mov    %edx,%eax
f010282b:	25 ff 03 00 00       	and    $0x3ff,%eax
f0102830:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0102833:	c1 e0 05             	shl    $0x5,%eax
f0102836:	03 05 84 ff 16 f0    	add    0xf016ff84,%eax
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f010283c:	83 78 54 00          	cmpl   $0x0,0x54(%eax)
f0102840:	74 05                	je     f0102847 <envid2env+0x3c>
f0102842:	3b 50 48             	cmp    0x48(%eax),%edx
f0102845:	74 10                	je     f0102857 <envid2env+0x4c>
		*env_store = 0;
f0102847:	8b 45 0c             	mov    0xc(%ebp),%eax
f010284a:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0102850:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0102855:	eb 30                	jmp    f0102887 <envid2env+0x7c>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f0102857:	84 c9                	test   %cl,%cl
f0102859:	74 22                	je     f010287d <envid2env+0x72>
f010285b:	8b 15 80 ff 16 f0    	mov    0xf016ff80,%edx
f0102861:	39 d0                	cmp    %edx,%eax
f0102863:	74 18                	je     f010287d <envid2env+0x72>
f0102865:	8b 4a 48             	mov    0x48(%edx),%ecx
f0102868:	39 48 4c             	cmp    %ecx,0x4c(%eax)
f010286b:	74 10                	je     f010287d <envid2env+0x72>
		*env_store = 0;
f010286d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102870:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0102876:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f010287b:	eb 0a                	jmp    f0102887 <envid2env+0x7c>
	}

	*env_store = e;
f010287d:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0102880:	89 01                	mov    %eax,(%ecx)
	return 0;
f0102882:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102887:	5d                   	pop    %ebp
f0102888:	c3                   	ret    

f0102889 <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f0102889:	55                   	push   %ebp
f010288a:	89 e5                	mov    %esp,%ebp
}

static inline void
lgdt(void *p)
{
	asm volatile("lgdt (%0)" : : "r" (p));
f010288c:	b8 00 a3 11 f0       	mov    $0xf011a300,%eax
f0102891:	0f 01 10             	lgdtl  (%eax)
	lgdt(&gdt_pd);
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" : : "a" (GD_UD|3));
f0102894:	b8 23 00 00 00       	mov    $0x23,%eax
f0102899:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" : : "a" (GD_UD|3));
f010289b:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" : : "a" (GD_KD));
f010289d:	b8 10 00 00 00       	mov    $0x10,%eax
f01028a2:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" : : "a" (GD_KD));
f01028a4:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" : : "a" (GD_KD));
f01028a6:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" : : "i" (GD_KT));
f01028a8:	ea af 28 10 f0 08 00 	ljmp   $0x8,$0xf01028af
}

static inline void
lldt(uint16_t sel)
{
	asm volatile("lldt %0" : : "r" (sel));
f01028af:	b8 00 00 00 00       	mov    $0x0,%eax
f01028b4:	0f 00 d0             	lldt   %ax
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
}
f01028b7:	5d                   	pop    %ebp
f01028b8:	c3                   	ret    

f01028b9 <env_init>:
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f01028b9:	55                   	push   %ebp
f01028ba:	89 e5                	mov    %esp,%ebp
f01028bc:	56                   	push   %esi
f01028bd:	53                   	push   %ebx
	// Set up envs array
	// LAB 3: Your code here.
	for (int i = NENV - 1; i >= 0; i--) {
		envs[i].env_id = 0;
f01028be:	8b 35 84 ff 16 f0    	mov    0xf016ff84,%esi
f01028c4:	8b 15 88 ff 16 f0    	mov    0xf016ff88,%edx
f01028ca:	8d 86 a0 7f 01 00    	lea    0x17fa0(%esi),%eax
f01028d0:	8d 5e a0             	lea    -0x60(%esi),%ebx
f01028d3:	89 c1                	mov    %eax,%ecx
f01028d5:	c7 40 48 00 00 00 00 	movl   $0x0,0x48(%eax)
		envs[i].env_link = env_free_list;
f01028dc:	89 50 44             	mov    %edx,0x44(%eax)
f01028df:	83 e8 60             	sub    $0x60,%eax
		env_free_list = &envs[i];
f01028e2:	89 ca                	mov    %ecx,%edx
void
env_init(void)
{
	// Set up envs array
	// LAB 3: Your code here.
	for (int i = NENV - 1; i >= 0; i--) {
f01028e4:	39 d8                	cmp    %ebx,%eax
f01028e6:	75 eb                	jne    f01028d3 <env_init+0x1a>
f01028e8:	89 35 88 ff 16 f0    	mov    %esi,0xf016ff88
		envs[i].env_link = env_free_list;
		env_free_list = &envs[i];
	}

	// Per-CPU part of the initialization
	env_init_percpu();
f01028ee:	e8 96 ff ff ff       	call   f0102889 <env_init_percpu>
}
f01028f3:	5b                   	pop    %ebx
f01028f4:	5e                   	pop    %esi
f01028f5:	5d                   	pop    %ebp
f01028f6:	c3                   	ret    

f01028f7 <env_alloc>:
//	-E_NO_FREE_ENV if all NENVS environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f01028f7:	55                   	push   %ebp
f01028f8:	89 e5                	mov    %esp,%ebp
f01028fa:	53                   	push   %ebx
f01028fb:	83 ec 04             	sub    $0x4,%esp
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f01028fe:	8b 1d 88 ff 16 f0    	mov    0xf016ff88,%ebx
f0102904:	85 db                	test   %ebx,%ebx
f0102906:	0f 84 48 01 00 00    	je     f0102a54 <env_alloc+0x15d>
{
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
f010290c:	83 ec 0c             	sub    $0xc,%esp
f010290f:	6a 01                	push   $0x1
f0102911:	e8 a2 e4 ff ff       	call   f0100db8 <page_alloc>
f0102916:	83 c4 10             	add    $0x10,%esp
f0102919:	85 c0                	test   %eax,%eax
f010291b:	0f 84 3a 01 00 00    	je     f0102a5b <env_alloc+0x164>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102921:	89 c2                	mov    %eax,%edx
f0102923:	2b 15 4c 0c 17 f0    	sub    0xf0170c4c,%edx
f0102929:	c1 fa 03             	sar    $0x3,%edx
f010292c:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010292f:	89 d1                	mov    %edx,%ecx
f0102931:	c1 e9 0c             	shr    $0xc,%ecx
f0102934:	3b 0d 44 0c 17 f0    	cmp    0xf0170c44,%ecx
f010293a:	72 12                	jb     f010294e <env_alloc+0x57>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010293c:	52                   	push   %edx
f010293d:	68 74 46 10 f0       	push   $0xf0104674
f0102942:	6a 56                	push   $0x56
f0102944:	68 48 4e 10 f0       	push   $0xf0104e48
f0102949:	e8 52 d7 ff ff       	call   f01000a0 <_panic>
	//	is an exception -- you need to increment env_pgdir's
	//	pp_ref for env_free to work correctly.
	//    - The functions in kern/pmap.h are handy.

	// LAB 3: Your code here.
	e->env_pgdir = page2kva(p);
f010294e:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f0102954:	89 53 5c             	mov    %edx,0x5c(%ebx)
	p->pp_ref++;
f0102957:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
	memcpy(e->env_pgdir, kern_pgdir, PGSIZE);
f010295c:	83 ec 04             	sub    $0x4,%esp
f010295f:	68 00 10 00 00       	push   $0x1000
f0102964:	ff 35 48 0c 17 f0    	pushl  0xf0170c48
f010296a:	ff 73 5c             	pushl  0x5c(%ebx)
f010296d:	e8 1e 14 00 00       	call   f0103d90 <memcpy>

	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f0102972:	8b 43 5c             	mov    0x5c(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102975:	83 c4 10             	add    $0x10,%esp
f0102978:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010297d:	77 15                	ja     f0102994 <env_alloc+0x9d>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010297f:	50                   	push   %eax
f0102980:	68 98 46 10 f0       	push   $0xf0104698
f0102985:	68 c1 00 00 00       	push   $0xc1
f010298a:	68 33 51 10 f0       	push   $0xf0105133
f010298f:	e8 0c d7 ff ff       	call   f01000a0 <_panic>
f0102994:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f010299a:	83 ca 05             	or     $0x5,%edx
f010299d:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f01029a3:	8b 43 48             	mov    0x48(%ebx),%eax
f01029a6:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f01029ab:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f01029b0:	ba 00 10 00 00       	mov    $0x1000,%edx
f01029b5:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f01029b8:	89 da                	mov    %ebx,%edx
f01029ba:	2b 15 84 ff 16 f0    	sub    0xf016ff84,%edx
f01029c0:	c1 fa 05             	sar    $0x5,%edx
f01029c3:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f01029c9:	09 d0                	or     %edx,%eax
f01029cb:	89 43 48             	mov    %eax,0x48(%ebx)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f01029ce:	8b 45 0c             	mov    0xc(%ebp),%eax
f01029d1:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f01029d4:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f01029db:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f01029e2:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f01029e9:	83 ec 04             	sub    $0x4,%esp
f01029ec:	6a 44                	push   $0x44
f01029ee:	6a 00                	push   $0x0
f01029f0:	53                   	push   %ebx
f01029f1:	e8 e5 12 00 00       	call   f0103cdb <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f01029f6:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f01029fc:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f0102a02:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f0102a08:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f0102a0f:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)
	// You will set e->env_tf.tf_eip later.

	// commit the allocation
	env_free_list = e->env_link;
f0102a15:	8b 43 44             	mov    0x44(%ebx),%eax
f0102a18:	a3 88 ff 16 f0       	mov    %eax,0xf016ff88
	*newenv_store = e;
f0102a1d:	8b 45 08             	mov    0x8(%ebp),%eax
f0102a20:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0102a22:	8b 53 48             	mov    0x48(%ebx),%edx
f0102a25:	a1 80 ff 16 f0       	mov    0xf016ff80,%eax
f0102a2a:	83 c4 10             	add    $0x10,%esp
f0102a2d:	85 c0                	test   %eax,%eax
f0102a2f:	74 05                	je     f0102a36 <env_alloc+0x13f>
f0102a31:	8b 40 48             	mov    0x48(%eax),%eax
f0102a34:	eb 05                	jmp    f0102a3b <env_alloc+0x144>
f0102a36:	b8 00 00 00 00       	mov    $0x0,%eax
f0102a3b:	83 ec 04             	sub    $0x4,%esp
f0102a3e:	52                   	push   %edx
f0102a3f:	50                   	push   %eax
f0102a40:	68 3e 51 10 f0       	push   $0xf010513e
f0102a45:	e8 0d 04 00 00       	call   f0102e57 <cprintf>
	return 0;
f0102a4a:	83 c4 10             	add    $0x10,%esp
f0102a4d:	b8 00 00 00 00       	mov    $0x0,%eax
f0102a52:	eb 0c                	jmp    f0102a60 <env_alloc+0x169>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f0102a54:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f0102a59:	eb 05                	jmp    f0102a60 <env_alloc+0x169>
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f0102a5b:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	env_free_list = e->env_link;
	*newenv_store = e;

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f0102a60:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102a63:	c9                   	leave  
f0102a64:	c3                   	ret    

f0102a65 <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f0102a65:	55                   	push   %ebp
f0102a66:	89 e5                	mov    %esp,%ebp
f0102a68:	57                   	push   %edi
f0102a69:	56                   	push   %esi
f0102a6a:	53                   	push   %ebx
f0102a6b:	83 ec 34             	sub    $0x34,%esp
f0102a6e:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.
	struct Env *e;
	env_alloc(&e, 0);
f0102a71:	6a 00                	push   $0x0
f0102a73:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0102a76:	50                   	push   %eax
f0102a77:	e8 7b fe ff ff       	call   f01028f7 <env_alloc>
	load_icode(e, binary);
f0102a7c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102a7f:	89 45 d4             	mov    %eax,-0x2c(%ebp)

	// LAB 3: Your code here.
	
	struct Elf *elf = (struct Elf *) binary;

	if (elf->e_magic != ELF_MAGIC)
f0102a82:	83 c4 10             	add    $0x10,%esp
f0102a85:	81 3f 7f 45 4c 46    	cmpl   $0x464c457f,(%edi)
f0102a8b:	74 17                	je     f0102aa4 <env_create+0x3f>
		panic("load_icode: not ELF executable.");
f0102a8d:	83 ec 04             	sub    $0x4,%esp
f0102a90:	68 7c 51 10 f0       	push   $0xf010517c
f0102a95:	68 5b 01 00 00       	push   $0x15b
f0102a9a:	68 33 51 10 f0       	push   $0xf0105133
f0102a9f:	e8 fc d5 ff ff       	call   f01000a0 <_panic>

	struct Proghdr *ph = (struct Proghdr *) (elf->e_phoff + binary);
f0102aa4:	89 fb                	mov    %edi,%ebx
f0102aa6:	03 5f 1c             	add    0x1c(%edi),%ebx
	struct Proghdr *eph = ph + elf->e_phnum;
f0102aa9:	0f b7 77 2c          	movzwl 0x2c(%edi),%esi
f0102aad:	c1 e6 05             	shl    $0x5,%esi
f0102ab0:	01 de                	add    %ebx,%esi

	lcr3(PADDR(e->env_pgdir));
f0102ab2:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102ab5:	8b 40 5c             	mov    0x5c(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102ab8:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102abd:	77 15                	ja     f0102ad4 <env_create+0x6f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102abf:	50                   	push   %eax
f0102ac0:	68 98 46 10 f0       	push   $0xf0104698
f0102ac5:	68 60 01 00 00       	push   $0x160
f0102aca:	68 33 51 10 f0       	push   $0xf0105133
f0102acf:	e8 cc d5 ff ff       	call   f01000a0 <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0102ad4:	05 00 00 00 10       	add    $0x10000000,%eax
f0102ad9:	0f 22 d8             	mov    %eax,%cr3
f0102adc:	eb 3d                	jmp    f0102b1b <env_create+0xb6>
	for(; ph < eph; ph++){
		if(ph->p_type == ELF_PROG_LOAD){
f0102ade:	83 3b 01             	cmpl   $0x1,(%ebx)
f0102ae1:	75 35                	jne    f0102b18 <env_create+0xb3>
			region_alloc(e, (void *) ph->p_va, ph->p_memsz);
f0102ae3:	8b 4b 14             	mov    0x14(%ebx),%ecx
f0102ae6:	8b 53 08             	mov    0x8(%ebx),%edx
f0102ae9:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102aec:	e8 af fc ff ff       	call   f01027a0 <region_alloc>
			memset((void *) ph->p_va, 0, ph->p_memsz);
f0102af1:	83 ec 04             	sub    $0x4,%esp
f0102af4:	ff 73 14             	pushl  0x14(%ebx)
f0102af7:	6a 00                	push   $0x0
f0102af9:	ff 73 08             	pushl  0x8(%ebx)
f0102afc:	e8 da 11 00 00       	call   f0103cdb <memset>
			memcpy((void *) ph->p_va, binary + ph->p_offset, ph->p_filesz);
f0102b01:	83 c4 0c             	add    $0xc,%esp
f0102b04:	ff 73 10             	pushl  0x10(%ebx)
f0102b07:	89 f8                	mov    %edi,%eax
f0102b09:	03 43 04             	add    0x4(%ebx),%eax
f0102b0c:	50                   	push   %eax
f0102b0d:	ff 73 08             	pushl  0x8(%ebx)
f0102b10:	e8 7b 12 00 00       	call   f0103d90 <memcpy>
f0102b15:	83 c4 10             	add    $0x10,%esp

	struct Proghdr *ph = (struct Proghdr *) (elf->e_phoff + binary);
	struct Proghdr *eph = ph + elf->e_phnum;

	lcr3(PADDR(e->env_pgdir));
	for(; ph < eph; ph++){
f0102b18:	83 c3 20             	add    $0x20,%ebx
f0102b1b:	39 de                	cmp    %ebx,%esi
f0102b1d:	77 bf                	ja     f0102ade <env_create+0x79>
			region_alloc(e, (void *) ph->p_va, ph->p_memsz);
			memset((void *) ph->p_va, 0, ph->p_memsz);
			memcpy((void *) ph->p_va, binary + ph->p_offset, ph->p_filesz);
		}
	}
	lcr3(PADDR(kern_pgdir));
f0102b1f:	a1 48 0c 17 f0       	mov    0xf0170c48,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102b24:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102b29:	77 15                	ja     f0102b40 <env_create+0xdb>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102b2b:	50                   	push   %eax
f0102b2c:	68 98 46 10 f0       	push   $0xf0104698
f0102b31:	68 68 01 00 00       	push   $0x168
f0102b36:	68 33 51 10 f0       	push   $0xf0105133
f0102b3b:	e8 60 d5 ff ff       	call   f01000a0 <_panic>
f0102b40:	05 00 00 00 10       	add    $0x10000000,%eax
f0102b45:	0f 22 d8             	mov    %eax,%cr3
	e->env_tf.tf_eip = elf->e_entry;
f0102b48:	8b 47 18             	mov    0x18(%edi),%eax
f0102b4b:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102b4e:	89 47 30             	mov    %eax,0x30(%edi)
	// Now map one page for the program's initial stack
	// at virtual address USTACKTOP - PGSIZE.

	// LAB 3: Your code here.
	region_alloc(e, (void *) (USTACKTOP - PGSIZE), PGSIZE);
f0102b51:	b9 00 10 00 00       	mov    $0x1000,%ecx
f0102b56:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f0102b5b:	89 f8                	mov    %edi,%eax
f0102b5d:	e8 3e fc ff ff       	call   f01027a0 <region_alloc>
{
	// LAB 3: Your code here.
	struct Env *e;
	env_alloc(&e, 0);
	load_icode(e, binary);
	e->env_type = type;
f0102b62:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102b65:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102b68:	89 50 50             	mov    %edx,0x50(%eax)
}
f0102b6b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102b6e:	5b                   	pop    %ebx
f0102b6f:	5e                   	pop    %esi
f0102b70:	5f                   	pop    %edi
f0102b71:	5d                   	pop    %ebp
f0102b72:	c3                   	ret    

f0102b73 <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f0102b73:	55                   	push   %ebp
f0102b74:	89 e5                	mov    %esp,%ebp
f0102b76:	57                   	push   %edi
f0102b77:	56                   	push   %esi
f0102b78:	53                   	push   %ebx
f0102b79:	83 ec 1c             	sub    $0x1c,%esp
f0102b7c:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f0102b7f:	8b 15 80 ff 16 f0    	mov    0xf016ff80,%edx
f0102b85:	39 fa                	cmp    %edi,%edx
f0102b87:	75 29                	jne    f0102bb2 <env_free+0x3f>
		lcr3(PADDR(kern_pgdir));
f0102b89:	a1 48 0c 17 f0       	mov    0xf0170c48,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102b8e:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102b93:	77 15                	ja     f0102baa <env_free+0x37>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102b95:	50                   	push   %eax
f0102b96:	68 98 46 10 f0       	push   $0xf0104698
f0102b9b:	68 90 01 00 00       	push   $0x190
f0102ba0:	68 33 51 10 f0       	push   $0xf0105133
f0102ba5:	e8 f6 d4 ff ff       	call   f01000a0 <_panic>
f0102baa:	05 00 00 00 10       	add    $0x10000000,%eax
f0102baf:	0f 22 d8             	mov    %eax,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0102bb2:	8b 4f 48             	mov    0x48(%edi),%ecx
f0102bb5:	85 d2                	test   %edx,%edx
f0102bb7:	74 05                	je     f0102bbe <env_free+0x4b>
f0102bb9:	8b 42 48             	mov    0x48(%edx),%eax
f0102bbc:	eb 05                	jmp    f0102bc3 <env_free+0x50>
f0102bbe:	b8 00 00 00 00       	mov    $0x0,%eax
f0102bc3:	83 ec 04             	sub    $0x4,%esp
f0102bc6:	51                   	push   %ecx
f0102bc7:	50                   	push   %eax
f0102bc8:	68 53 51 10 f0       	push   $0xf0105153
f0102bcd:	e8 85 02 00 00       	call   f0102e57 <cprintf>
f0102bd2:	83 c4 10             	add    $0x10,%esp

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0102bd5:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0102bdc:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0102bdf:	89 d0                	mov    %edx,%eax
f0102be1:	c1 e0 02             	shl    $0x2,%eax
f0102be4:	89 45 dc             	mov    %eax,-0x24(%ebp)

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f0102be7:	8b 47 5c             	mov    0x5c(%edi),%eax
f0102bea:	8b 34 90             	mov    (%eax,%edx,4),%esi
f0102bed:	f7 c6 01 00 00 00    	test   $0x1,%esi
f0102bf3:	0f 84 a8 00 00 00    	je     f0102ca1 <env_free+0x12e>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f0102bf9:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102bff:	89 f0                	mov    %esi,%eax
f0102c01:	c1 e8 0c             	shr    $0xc,%eax
f0102c04:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102c07:	39 05 44 0c 17 f0    	cmp    %eax,0xf0170c44
f0102c0d:	77 15                	ja     f0102c24 <env_free+0xb1>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102c0f:	56                   	push   %esi
f0102c10:	68 74 46 10 f0       	push   $0xf0104674
f0102c15:	68 9f 01 00 00       	push   $0x19f
f0102c1a:	68 33 51 10 f0       	push   $0xf0105133
f0102c1f:	e8 7c d4 ff ff       	call   f01000a0 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0102c24:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102c27:	c1 e0 16             	shl    $0x16,%eax
f0102c2a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0102c2d:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f0102c32:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f0102c39:	01 
f0102c3a:	74 17                	je     f0102c53 <env_free+0xe0>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0102c3c:	83 ec 08             	sub    $0x8,%esp
f0102c3f:	89 d8                	mov    %ebx,%eax
f0102c41:	c1 e0 0c             	shl    $0xc,%eax
f0102c44:	0b 45 e4             	or     -0x1c(%ebp),%eax
f0102c47:	50                   	push   %eax
f0102c48:	ff 77 5c             	pushl  0x5c(%edi)
f0102c4b:	e8 92 e3 ff ff       	call   f0100fe2 <page_remove>
f0102c50:	83 c4 10             	add    $0x10,%esp
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0102c53:	83 c3 01             	add    $0x1,%ebx
f0102c56:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f0102c5c:	75 d4                	jne    f0102c32 <env_free+0xbf>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f0102c5e:	8b 47 5c             	mov    0x5c(%edi),%eax
f0102c61:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102c64:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102c6b:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102c6e:	3b 05 44 0c 17 f0    	cmp    0xf0170c44,%eax
f0102c74:	72 14                	jb     f0102c8a <env_free+0x117>
		panic("pa2page called with invalid pa");
f0102c76:	83 ec 04             	sub    $0x4,%esp
f0102c79:	68 b4 47 10 f0       	push   $0xf01047b4
f0102c7e:	6a 4f                	push   $0x4f
f0102c80:	68 48 4e 10 f0       	push   $0xf0104e48
f0102c85:	e8 16 d4 ff ff       	call   f01000a0 <_panic>
		page_decref(pa2page(pa));
f0102c8a:	83 ec 0c             	sub    $0xc,%esp
f0102c8d:	a1 4c 0c 17 f0       	mov    0xf0170c4c,%eax
f0102c92:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102c95:	8d 04 d0             	lea    (%eax,%edx,8),%eax
f0102c98:	50                   	push   %eax
f0102c99:	e8 cc e1 ff ff       	call   f0100e6a <page_decref>
f0102c9e:	83 c4 10             	add    $0x10,%esp
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0102ca1:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f0102ca5:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102ca8:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f0102cad:	0f 85 29 ff ff ff    	jne    f0102bdc <env_free+0x69>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f0102cb3:	8b 47 5c             	mov    0x5c(%edi),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102cb6:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102cbb:	77 15                	ja     f0102cd2 <env_free+0x15f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102cbd:	50                   	push   %eax
f0102cbe:	68 98 46 10 f0       	push   $0xf0104698
f0102cc3:	68 ad 01 00 00       	push   $0x1ad
f0102cc8:	68 33 51 10 f0       	push   $0xf0105133
f0102ccd:	e8 ce d3 ff ff       	call   f01000a0 <_panic>
	e->env_pgdir = 0;
f0102cd2:	c7 47 5c 00 00 00 00 	movl   $0x0,0x5c(%edi)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102cd9:	05 00 00 00 10       	add    $0x10000000,%eax
f0102cde:	c1 e8 0c             	shr    $0xc,%eax
f0102ce1:	3b 05 44 0c 17 f0    	cmp    0xf0170c44,%eax
f0102ce7:	72 14                	jb     f0102cfd <env_free+0x18a>
		panic("pa2page called with invalid pa");
f0102ce9:	83 ec 04             	sub    $0x4,%esp
f0102cec:	68 b4 47 10 f0       	push   $0xf01047b4
f0102cf1:	6a 4f                	push   $0x4f
f0102cf3:	68 48 4e 10 f0       	push   $0xf0104e48
f0102cf8:	e8 a3 d3 ff ff       	call   f01000a0 <_panic>
	page_decref(pa2page(pa));
f0102cfd:	83 ec 0c             	sub    $0xc,%esp
f0102d00:	8b 15 4c 0c 17 f0    	mov    0xf0170c4c,%edx
f0102d06:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f0102d09:	50                   	push   %eax
f0102d0a:	e8 5b e1 ff ff       	call   f0100e6a <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f0102d0f:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f0102d16:	a1 88 ff 16 f0       	mov    0xf016ff88,%eax
f0102d1b:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f0102d1e:	89 3d 88 ff 16 f0    	mov    %edi,0xf016ff88
}
f0102d24:	83 c4 10             	add    $0x10,%esp
f0102d27:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102d2a:	5b                   	pop    %ebx
f0102d2b:	5e                   	pop    %esi
f0102d2c:	5f                   	pop    %edi
f0102d2d:	5d                   	pop    %ebp
f0102d2e:	c3                   	ret    

f0102d2f <env_destroy>:
//
// Frees environment e.
//
void
env_destroy(struct Env *e)
{
f0102d2f:	55                   	push   %ebp
f0102d30:	89 e5                	mov    %esp,%ebp
f0102d32:	83 ec 14             	sub    $0x14,%esp
	env_free(e);
f0102d35:	ff 75 08             	pushl  0x8(%ebp)
f0102d38:	e8 36 fe ff ff       	call   f0102b73 <env_free>

	cprintf("Destroyed the only environment - nothing more to do!\n");
f0102d3d:	c7 04 24 9c 51 10 f0 	movl   $0xf010519c,(%esp)
f0102d44:	e8 0e 01 00 00       	call   f0102e57 <cprintf>
f0102d49:	83 c4 10             	add    $0x10,%esp
	while (1)
		monitor(NULL);
f0102d4c:	83 ec 0c             	sub    $0xc,%esp
f0102d4f:	6a 00                	push   $0x0
f0102d51:	e8 4c da ff ff       	call   f01007a2 <monitor>
f0102d56:	83 c4 10             	add    $0x10,%esp
f0102d59:	eb f1                	jmp    f0102d4c <env_destroy+0x1d>

f0102d5b <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f0102d5b:	55                   	push   %ebp
f0102d5c:	89 e5                	mov    %esp,%ebp
f0102d5e:	83 ec 0c             	sub    $0xc,%esp
	asm volatile(
f0102d61:	8b 65 08             	mov    0x8(%ebp),%esp
f0102d64:	61                   	popa   
f0102d65:	07                   	pop    %es
f0102d66:	1f                   	pop    %ds
f0102d67:	83 c4 08             	add    $0x8,%esp
f0102d6a:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret\n"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f0102d6b:	68 69 51 10 f0       	push   $0xf0105169
f0102d70:	68 d6 01 00 00       	push   $0x1d6
f0102d75:	68 33 51 10 f0       	push   $0xf0105133
f0102d7a:	e8 21 d3 ff ff       	call   f01000a0 <_panic>

f0102d7f <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f0102d7f:	55                   	push   %ebp
f0102d80:	89 e5                	mov    %esp,%ebp
f0102d82:	53                   	push   %ebx
f0102d83:	83 ec 04             	sub    $0x4,%esp
f0102d86:	8b 5d 08             	mov    0x8(%ebp),%ebx
	//	e->env_tf.  Go back through the code you wrote above
	//	and make sure you have set the relevant parts of
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.
	if(curenv != NULL){
f0102d89:	a1 80 ff 16 f0       	mov    0xf016ff80,%eax
f0102d8e:	85 c0                	test   %eax,%eax
f0102d90:	74 0d                	je     f0102d9f <env_run+0x20>
		if(curenv->env_status == ENV_RUNNING)
f0102d92:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0102d96:	75 07                	jne    f0102d9f <env_run+0x20>
			curenv->env_status = ENV_RUNNABLE;
f0102d98:	c7 40 54 02 00 00 00 	movl   $0x2,0x54(%eax)
	}
	curenv = e;
f0102d9f:	89 1d 80 ff 16 f0    	mov    %ebx,0xf016ff80
	curenv->env_status = ENV_RUNNING;
f0102da5:	c7 43 54 03 00 00 00 	movl   $0x3,0x54(%ebx)
	curenv->env_runs ++;
f0102dac:	83 43 58 01          	addl   $0x1,0x58(%ebx)
	cprintf("hello\n");
f0102db0:	83 ec 0c             	sub    $0xc,%esp
f0102db3:	68 75 51 10 f0       	push   $0xf0105175
f0102db8:	e8 9a 00 00 00       	call   f0102e57 <cprintf>
	lcr3(PADDR(e->env_pgdir));
f0102dbd:	8b 43 5c             	mov    0x5c(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102dc0:	83 c4 10             	add    $0x10,%esp
f0102dc3:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102dc8:	77 15                	ja     f0102ddf <env_run+0x60>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102dca:	50                   	push   %eax
f0102dcb:	68 98 46 10 f0       	push   $0xf0104698
f0102dd0:	68 fc 01 00 00       	push   $0x1fc
f0102dd5:	68 33 51 10 f0       	push   $0xf0105133
f0102dda:	e8 c1 d2 ff ff       	call   f01000a0 <_panic>
f0102ddf:	05 00 00 00 10       	add    $0x10000000,%eax
f0102de4:	0f 22 d8             	mov    %eax,%cr3
	env_pop_tf(&e->env_tf);
f0102de7:	83 ec 0c             	sub    $0xc,%esp
f0102dea:	53                   	push   %ebx
f0102deb:	e8 6b ff ff ff       	call   f0102d5b <env_pop_tf>

f0102df0 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102df0:	55                   	push   %ebp
f0102df1:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102df3:	ba 70 00 00 00       	mov    $0x70,%edx
f0102df8:	8b 45 08             	mov    0x8(%ebp),%eax
f0102dfb:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102dfc:	ba 71 00 00 00       	mov    $0x71,%edx
f0102e01:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0102e02:	0f b6 c0             	movzbl %al,%eax
}
f0102e05:	5d                   	pop    %ebp
f0102e06:	c3                   	ret    

f0102e07 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102e07:	55                   	push   %ebp
f0102e08:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102e0a:	ba 70 00 00 00       	mov    $0x70,%edx
f0102e0f:	8b 45 08             	mov    0x8(%ebp),%eax
f0102e12:	ee                   	out    %al,(%dx)
f0102e13:	ba 71 00 00 00       	mov    $0x71,%edx
f0102e18:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102e1b:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0102e1c:	5d                   	pop    %ebp
f0102e1d:	c3                   	ret    

f0102e1e <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0102e1e:	55                   	push   %ebp
f0102e1f:	89 e5                	mov    %esp,%ebp
f0102e21:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0102e24:	ff 75 08             	pushl  0x8(%ebp)
f0102e27:	e8 e9 d7 ff ff       	call   f0100615 <cputchar>
	*cnt++;
}
f0102e2c:	83 c4 10             	add    $0x10,%esp
f0102e2f:	c9                   	leave  
f0102e30:	c3                   	ret    

f0102e31 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0102e31:	55                   	push   %ebp
f0102e32:	89 e5                	mov    %esp,%ebp
f0102e34:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0102e37:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0102e3e:	ff 75 0c             	pushl  0xc(%ebp)
f0102e41:	ff 75 08             	pushl  0x8(%ebp)
f0102e44:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102e47:	50                   	push   %eax
f0102e48:	68 1e 2e 10 f0       	push   $0xf0102e1e
f0102e4d:	e8 1d 08 00 00       	call   f010366f <vprintfmt>
	return cnt;
}
f0102e52:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102e55:	c9                   	leave  
f0102e56:	c3                   	ret    

f0102e57 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0102e57:	55                   	push   %ebp
f0102e58:	89 e5                	mov    %esp,%ebp
f0102e5a:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0102e5d:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102e60:	50                   	push   %eax
f0102e61:	ff 75 08             	pushl  0x8(%ebp)
f0102e64:	e8 c8 ff ff ff       	call   f0102e31 <vcprintf>
	va_end(ap);

	return cnt;
}
f0102e69:	c9                   	leave  
f0102e6a:	c3                   	ret    

f0102e6b <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f0102e6b:	55                   	push   %ebp
f0102e6c:	89 e5                	mov    %esp,%ebp
	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	ts.ts_esp0 = KSTACKTOP;
f0102e6e:	b8 c0 07 17 f0       	mov    $0xf01707c0,%eax
f0102e73:	c7 05 c4 07 17 f0 00 	movl   $0xf0000000,0xf01707c4
f0102e7a:	00 00 f0 
	ts.ts_ss0 = GD_KD;
f0102e7d:	66 c7 05 c8 07 17 f0 	movw   $0x10,0xf01707c8
f0102e84:	10 00 

	// Initialize the TSS slot of the gdt.
	gdt[GD_TSS0 >> 3] = SEG16(STS_T32A, (uint32_t) (&ts),
f0102e86:	66 c7 05 48 a3 11 f0 	movw   $0x67,0xf011a348
f0102e8d:	67 00 
f0102e8f:	66 a3 4a a3 11 f0    	mov    %ax,0xf011a34a
f0102e95:	89 c2                	mov    %eax,%edx
f0102e97:	c1 ea 10             	shr    $0x10,%edx
f0102e9a:	88 15 4c a3 11 f0    	mov    %dl,0xf011a34c
f0102ea0:	c6 05 4e a3 11 f0 40 	movb   $0x40,0xf011a34e
f0102ea7:	c1 e8 18             	shr    $0x18,%eax
f0102eaa:	a2 4f a3 11 f0       	mov    %al,0xf011a34f
					sizeof(struct Taskstate) - 1, 0);
	gdt[GD_TSS0 >> 3].sd_s = 0;
f0102eaf:	c6 05 4d a3 11 f0 89 	movb   $0x89,0xf011a34d
}

static inline void
ltr(uint16_t sel)
{
	asm volatile("ltr %0" : : "r" (sel));
f0102eb6:	b8 28 00 00 00       	mov    $0x28,%eax
f0102ebb:	0f 00 d8             	ltr    %ax
}

static inline void
lidt(void *p)
{
	asm volatile("lidt (%0)" : : "r" (p));
f0102ebe:	b8 50 a3 11 f0       	mov    $0xf011a350,%eax
f0102ec3:	0f 01 18             	lidtl  (%eax)
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0);

	// Load the IDT
	lidt(&idt_pd);
}
f0102ec6:	5d                   	pop    %ebp
f0102ec7:	c3                   	ret    

f0102ec8 <trap_init>:
}


void
trap_init(void)
{
f0102ec8:	55                   	push   %ebp
f0102ec9:	89 e5                	mov    %esp,%ebp
	extern struct Segdesc gdt[];

	// LAB 3: Your code here.

	// Per-CPU setup 
	trap_init_percpu();
f0102ecb:	e8 9b ff ff ff       	call   f0102e6b <trap_init_percpu>
}
f0102ed0:	5d                   	pop    %ebp
f0102ed1:	c3                   	ret    

f0102ed2 <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f0102ed2:	55                   	push   %ebp
f0102ed3:	89 e5                	mov    %esp,%ebp
f0102ed5:	53                   	push   %ebx
f0102ed6:	83 ec 0c             	sub    $0xc,%esp
f0102ed9:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f0102edc:	ff 33                	pushl  (%ebx)
f0102ede:	68 d2 51 10 f0       	push   $0xf01051d2
f0102ee3:	e8 6f ff ff ff       	call   f0102e57 <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f0102ee8:	83 c4 08             	add    $0x8,%esp
f0102eeb:	ff 73 04             	pushl  0x4(%ebx)
f0102eee:	68 e1 51 10 f0       	push   $0xf01051e1
f0102ef3:	e8 5f ff ff ff       	call   f0102e57 <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f0102ef8:	83 c4 08             	add    $0x8,%esp
f0102efb:	ff 73 08             	pushl  0x8(%ebx)
f0102efe:	68 f0 51 10 f0       	push   $0xf01051f0
f0102f03:	e8 4f ff ff ff       	call   f0102e57 <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f0102f08:	83 c4 08             	add    $0x8,%esp
f0102f0b:	ff 73 0c             	pushl  0xc(%ebx)
f0102f0e:	68 ff 51 10 f0       	push   $0xf01051ff
f0102f13:	e8 3f ff ff ff       	call   f0102e57 <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f0102f18:	83 c4 08             	add    $0x8,%esp
f0102f1b:	ff 73 10             	pushl  0x10(%ebx)
f0102f1e:	68 0e 52 10 f0       	push   $0xf010520e
f0102f23:	e8 2f ff ff ff       	call   f0102e57 <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f0102f28:	83 c4 08             	add    $0x8,%esp
f0102f2b:	ff 73 14             	pushl  0x14(%ebx)
f0102f2e:	68 1d 52 10 f0       	push   $0xf010521d
f0102f33:	e8 1f ff ff ff       	call   f0102e57 <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f0102f38:	83 c4 08             	add    $0x8,%esp
f0102f3b:	ff 73 18             	pushl  0x18(%ebx)
f0102f3e:	68 2c 52 10 f0       	push   $0xf010522c
f0102f43:	e8 0f ff ff ff       	call   f0102e57 <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f0102f48:	83 c4 08             	add    $0x8,%esp
f0102f4b:	ff 73 1c             	pushl  0x1c(%ebx)
f0102f4e:	68 3b 52 10 f0       	push   $0xf010523b
f0102f53:	e8 ff fe ff ff       	call   f0102e57 <cprintf>
}
f0102f58:	83 c4 10             	add    $0x10,%esp
f0102f5b:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102f5e:	c9                   	leave  
f0102f5f:	c3                   	ret    

f0102f60 <print_trapframe>:
	lidt(&idt_pd);
}

void
print_trapframe(struct Trapframe *tf)
{
f0102f60:	55                   	push   %ebp
f0102f61:	89 e5                	mov    %esp,%ebp
f0102f63:	56                   	push   %esi
f0102f64:	53                   	push   %ebx
f0102f65:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p\n", tf);
f0102f68:	83 ec 08             	sub    $0x8,%esp
f0102f6b:	53                   	push   %ebx
f0102f6c:	68 71 53 10 f0       	push   $0xf0105371
f0102f71:	e8 e1 fe ff ff       	call   f0102e57 <cprintf>
	print_regs(&tf->tf_regs);
f0102f76:	89 1c 24             	mov    %ebx,(%esp)
f0102f79:	e8 54 ff ff ff       	call   f0102ed2 <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f0102f7e:	83 c4 08             	add    $0x8,%esp
f0102f81:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f0102f85:	50                   	push   %eax
f0102f86:	68 8c 52 10 f0       	push   $0xf010528c
f0102f8b:	e8 c7 fe ff ff       	call   f0102e57 <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f0102f90:	83 c4 08             	add    $0x8,%esp
f0102f93:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f0102f97:	50                   	push   %eax
f0102f98:	68 9f 52 10 f0       	push   $0xf010529f
f0102f9d:	e8 b5 fe ff ff       	call   f0102e57 <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0102fa2:	8b 43 28             	mov    0x28(%ebx),%eax
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < ARRAY_SIZE(excnames))
f0102fa5:	83 c4 10             	add    $0x10,%esp
f0102fa8:	83 f8 13             	cmp    $0x13,%eax
f0102fab:	77 09                	ja     f0102fb6 <print_trapframe+0x56>
		return excnames[trapno];
f0102fad:	8b 14 85 40 55 10 f0 	mov    -0xfefaac0(,%eax,4),%edx
f0102fb4:	eb 10                	jmp    f0102fc6 <print_trapframe+0x66>
	if (trapno == T_SYSCALL)
		return "System call";
	return "(unknown trap)";
f0102fb6:	83 f8 30             	cmp    $0x30,%eax
f0102fb9:	b9 56 52 10 f0       	mov    $0xf0105256,%ecx
f0102fbe:	ba 4a 52 10 f0       	mov    $0xf010524a,%edx
f0102fc3:	0f 45 d1             	cmovne %ecx,%edx
{
	cprintf("TRAP frame at %p\n", tf);
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0102fc6:	83 ec 04             	sub    $0x4,%esp
f0102fc9:	52                   	push   %edx
f0102fca:	50                   	push   %eax
f0102fcb:	68 b2 52 10 f0       	push   $0xf01052b2
f0102fd0:	e8 82 fe ff ff       	call   f0102e57 <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0102fd5:	83 c4 10             	add    $0x10,%esp
f0102fd8:	3b 1d a0 07 17 f0    	cmp    0xf01707a0,%ebx
f0102fde:	75 1a                	jne    f0102ffa <print_trapframe+0x9a>
f0102fe0:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0102fe4:	75 14                	jne    f0102ffa <print_trapframe+0x9a>

static inline uint32_t
rcr2(void)
{
	uint32_t val;
	asm volatile("movl %%cr2,%0" : "=r" (val));
f0102fe6:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f0102fe9:	83 ec 08             	sub    $0x8,%esp
f0102fec:	50                   	push   %eax
f0102fed:	68 c4 52 10 f0       	push   $0xf01052c4
f0102ff2:	e8 60 fe ff ff       	call   f0102e57 <cprintf>
f0102ff7:	83 c4 10             	add    $0x10,%esp
	cprintf("  err  0x%08x", tf->tf_err);
f0102ffa:	83 ec 08             	sub    $0x8,%esp
f0102ffd:	ff 73 2c             	pushl  0x2c(%ebx)
f0103000:	68 d3 52 10 f0       	push   $0xf01052d3
f0103005:	e8 4d fe ff ff       	call   f0102e57 <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f010300a:	83 c4 10             	add    $0x10,%esp
f010300d:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103011:	75 49                	jne    f010305c <print_trapframe+0xfc>
		cprintf(" [%s, %s, %s]\n",
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
f0103013:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f0103016:	89 c2                	mov    %eax,%edx
f0103018:	83 e2 01             	and    $0x1,%edx
f010301b:	ba 70 52 10 f0       	mov    $0xf0105270,%edx
f0103020:	b9 65 52 10 f0       	mov    $0xf0105265,%ecx
f0103025:	0f 44 ca             	cmove  %edx,%ecx
f0103028:	89 c2                	mov    %eax,%edx
f010302a:	83 e2 02             	and    $0x2,%edx
f010302d:	ba 82 52 10 f0       	mov    $0xf0105282,%edx
f0103032:	be 7c 52 10 f0       	mov    $0xf010527c,%esi
f0103037:	0f 45 d6             	cmovne %esi,%edx
f010303a:	83 e0 04             	and    $0x4,%eax
f010303d:	be 9c 53 10 f0       	mov    $0xf010539c,%esi
f0103042:	b8 87 52 10 f0       	mov    $0xf0105287,%eax
f0103047:	0f 44 c6             	cmove  %esi,%eax
f010304a:	51                   	push   %ecx
f010304b:	52                   	push   %edx
f010304c:	50                   	push   %eax
f010304d:	68 e1 52 10 f0       	push   $0xf01052e1
f0103052:	e8 00 fe ff ff       	call   f0102e57 <cprintf>
f0103057:	83 c4 10             	add    $0x10,%esp
f010305a:	eb 10                	jmp    f010306c <print_trapframe+0x10c>
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f010305c:	83 ec 0c             	sub    $0xc,%esp
f010305f:	68 ed 50 10 f0       	push   $0xf01050ed
f0103064:	e8 ee fd ff ff       	call   f0102e57 <cprintf>
f0103069:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f010306c:	83 ec 08             	sub    $0x8,%esp
f010306f:	ff 73 30             	pushl  0x30(%ebx)
f0103072:	68 f0 52 10 f0       	push   $0xf01052f0
f0103077:	e8 db fd ff ff       	call   f0102e57 <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f010307c:	83 c4 08             	add    $0x8,%esp
f010307f:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f0103083:	50                   	push   %eax
f0103084:	68 ff 52 10 f0       	push   $0xf01052ff
f0103089:	e8 c9 fd ff ff       	call   f0102e57 <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f010308e:	83 c4 08             	add    $0x8,%esp
f0103091:	ff 73 38             	pushl  0x38(%ebx)
f0103094:	68 12 53 10 f0       	push   $0xf0105312
f0103099:	e8 b9 fd ff ff       	call   f0102e57 <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f010309e:	83 c4 10             	add    $0x10,%esp
f01030a1:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f01030a5:	74 25                	je     f01030cc <print_trapframe+0x16c>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f01030a7:	83 ec 08             	sub    $0x8,%esp
f01030aa:	ff 73 3c             	pushl  0x3c(%ebx)
f01030ad:	68 21 53 10 f0       	push   $0xf0105321
f01030b2:	e8 a0 fd ff ff       	call   f0102e57 <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f01030b7:	83 c4 08             	add    $0x8,%esp
f01030ba:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f01030be:	50                   	push   %eax
f01030bf:	68 30 53 10 f0       	push   $0xf0105330
f01030c4:	e8 8e fd ff ff       	call   f0102e57 <cprintf>
f01030c9:	83 c4 10             	add    $0x10,%esp
	}
}
f01030cc:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01030cf:	5b                   	pop    %ebx
f01030d0:	5e                   	pop    %esi
f01030d1:	5d                   	pop    %ebp
f01030d2:	c3                   	ret    

f01030d3 <trap>:
	}
}

void
trap(struct Trapframe *tf)
{
f01030d3:	55                   	push   %ebp
f01030d4:	89 e5                	mov    %esp,%ebp
f01030d6:	57                   	push   %edi
f01030d7:	56                   	push   %esi
f01030d8:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f01030db:	fc                   	cld    

static inline uint32_t
read_eflags(void)
{
	uint32_t eflags;
	asm volatile("pushfl; popl %0" : "=r" (eflags));
f01030dc:	9c                   	pushf  
f01030dd:	58                   	pop    %eax

	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f01030de:	f6 c4 02             	test   $0x2,%ah
f01030e1:	74 19                	je     f01030fc <trap+0x29>
f01030e3:	68 43 53 10 f0       	push   $0xf0105343
f01030e8:	68 62 4e 10 f0       	push   $0xf0104e62
f01030ed:	68 a7 00 00 00       	push   $0xa7
f01030f2:	68 5c 53 10 f0       	push   $0xf010535c
f01030f7:	e8 a4 cf ff ff       	call   f01000a0 <_panic>

	cprintf("Incoming TRAP frame at %p\n", tf);
f01030fc:	83 ec 08             	sub    $0x8,%esp
f01030ff:	56                   	push   %esi
f0103100:	68 68 53 10 f0       	push   $0xf0105368
f0103105:	e8 4d fd ff ff       	call   f0102e57 <cprintf>

	if ((tf->tf_cs & 3) == 3) {
f010310a:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f010310e:	83 e0 03             	and    $0x3,%eax
f0103111:	83 c4 10             	add    $0x10,%esp
f0103114:	66 83 f8 03          	cmp    $0x3,%ax
f0103118:	75 31                	jne    f010314b <trap+0x78>
		// Trapped from user mode.
		assert(curenv);
f010311a:	a1 80 ff 16 f0       	mov    0xf016ff80,%eax
f010311f:	85 c0                	test   %eax,%eax
f0103121:	75 19                	jne    f010313c <trap+0x69>
f0103123:	68 83 53 10 f0       	push   $0xf0105383
f0103128:	68 62 4e 10 f0       	push   $0xf0104e62
f010312d:	68 ad 00 00 00       	push   $0xad
f0103132:	68 5c 53 10 f0       	push   $0xf010535c
f0103137:	e8 64 cf ff ff       	call   f01000a0 <_panic>

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f010313c:	b9 11 00 00 00       	mov    $0x11,%ecx
f0103141:	89 c7                	mov    %eax,%edi
f0103143:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f0103145:	8b 35 80 ff 16 f0    	mov    0xf016ff80,%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f010314b:	89 35 a0 07 17 f0    	mov    %esi,0xf01707a0
{
	// Handle processor exceptions.
	// LAB 3: Your code here.

	// Unexpected trap: The user process or the kernel has a bug.
	print_trapframe(tf);
f0103151:	83 ec 0c             	sub    $0xc,%esp
f0103154:	56                   	push   %esi
f0103155:	e8 06 fe ff ff       	call   f0102f60 <print_trapframe>
	if (tf->tf_cs == GD_KT)
f010315a:	83 c4 10             	add    $0x10,%esp
f010315d:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f0103162:	75 17                	jne    f010317b <trap+0xa8>
		panic("unhandled trap in kernel");
f0103164:	83 ec 04             	sub    $0x4,%esp
f0103167:	68 8a 53 10 f0       	push   $0xf010538a
f010316c:	68 96 00 00 00       	push   $0x96
f0103171:	68 5c 53 10 f0       	push   $0xf010535c
f0103176:	e8 25 cf ff ff       	call   f01000a0 <_panic>
	else {
		env_destroy(curenv);
f010317b:	83 ec 0c             	sub    $0xc,%esp
f010317e:	ff 35 80 ff 16 f0    	pushl  0xf016ff80
f0103184:	e8 a6 fb ff ff       	call   f0102d2f <env_destroy>

	// Dispatch based on what type of trap occurred
	trap_dispatch(tf);

	// Return to the current environment, which should be running.
	assert(curenv && curenv->env_status == ENV_RUNNING);
f0103189:	a1 80 ff 16 f0       	mov    0xf016ff80,%eax
f010318e:	83 c4 10             	add    $0x10,%esp
f0103191:	85 c0                	test   %eax,%eax
f0103193:	74 06                	je     f010319b <trap+0xc8>
f0103195:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0103199:	74 19                	je     f01031b4 <trap+0xe1>
f010319b:	68 e8 54 10 f0       	push   $0xf01054e8
f01031a0:	68 62 4e 10 f0       	push   $0xf0104e62
f01031a5:	68 bf 00 00 00       	push   $0xbf
f01031aa:	68 5c 53 10 f0       	push   $0xf010535c
f01031af:	e8 ec ce ff ff       	call   f01000a0 <_panic>
	env_run(curenv);
f01031b4:	83 ec 0c             	sub    $0xc,%esp
f01031b7:	50                   	push   %eax
f01031b8:	e8 c2 fb ff ff       	call   f0102d7f <env_run>

f01031bd <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f01031bd:	55                   	push   %ebp
f01031be:	89 e5                	mov    %esp,%ebp
f01031c0:	53                   	push   %ebx
f01031c1:	83 ec 04             	sub    $0x4,%esp
f01031c4:	8b 5d 08             	mov    0x8(%ebp),%ebx

static inline uint32_t
rcr2(void)
{
	uint32_t val;
	asm volatile("movl %%cr2,%0" : "=r" (val));
f01031c7:	0f 20 d0             	mov    %cr2,%eax

	// We've already handled kernel-mode exceptions, so if we get here,
	// the page fault happened in user mode.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f01031ca:	ff 73 30             	pushl  0x30(%ebx)
f01031cd:	50                   	push   %eax
f01031ce:	a1 80 ff 16 f0       	mov    0xf016ff80,%eax
f01031d3:	ff 70 48             	pushl  0x48(%eax)
f01031d6:	68 14 55 10 f0       	push   $0xf0105514
f01031db:	e8 77 fc ff ff       	call   f0102e57 <cprintf>
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f01031e0:	89 1c 24             	mov    %ebx,(%esp)
f01031e3:	e8 78 fd ff ff       	call   f0102f60 <print_trapframe>
	env_destroy(curenv);
f01031e8:	83 c4 04             	add    $0x4,%esp
f01031eb:	ff 35 80 ff 16 f0    	pushl  0xf016ff80
f01031f1:	e8 39 fb ff ff       	call   f0102d2f <env_destroy>
}
f01031f6:	83 c4 10             	add    $0x10,%esp
f01031f9:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01031fc:	c9                   	leave  
f01031fd:	c3                   	ret    

f01031fe <syscall>:
f01031fe:	55                   	push   %ebp
f01031ff:	89 e5                	mov    %esp,%ebp
f0103201:	83 ec 0c             	sub    $0xc,%esp
f0103204:	68 90 55 10 f0       	push   $0xf0105590
f0103209:	6a 49                	push   $0x49
f010320b:	68 a8 55 10 f0       	push   $0xf01055a8
f0103210:	e8 8b ce ff ff       	call   f01000a0 <_panic>

f0103215 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0103215:	55                   	push   %ebp
f0103216:	89 e5                	mov    %esp,%ebp
f0103218:	57                   	push   %edi
f0103219:	56                   	push   %esi
f010321a:	53                   	push   %ebx
f010321b:	83 ec 14             	sub    $0x14,%esp
f010321e:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103221:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0103224:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0103227:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f010322a:	8b 1a                	mov    (%edx),%ebx
f010322c:	8b 01                	mov    (%ecx),%eax
f010322e:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0103231:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0103238:	eb 7f                	jmp    f01032b9 <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f010323a:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010323d:	01 d8                	add    %ebx,%eax
f010323f:	89 c6                	mov    %eax,%esi
f0103241:	c1 ee 1f             	shr    $0x1f,%esi
f0103244:	01 c6                	add    %eax,%esi
f0103246:	d1 fe                	sar    %esi
f0103248:	8d 04 76             	lea    (%esi,%esi,2),%eax
f010324b:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010324e:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f0103251:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0103253:	eb 03                	jmp    f0103258 <stab_binsearch+0x43>
			m--;
f0103255:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0103258:	39 c3                	cmp    %eax,%ebx
f010325a:	7f 0d                	jg     f0103269 <stab_binsearch+0x54>
f010325c:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0103260:	83 ea 0c             	sub    $0xc,%edx
f0103263:	39 f9                	cmp    %edi,%ecx
f0103265:	75 ee                	jne    f0103255 <stab_binsearch+0x40>
f0103267:	eb 05                	jmp    f010326e <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0103269:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f010326c:	eb 4b                	jmp    f01032b9 <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f010326e:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103271:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0103274:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0103278:	39 55 0c             	cmp    %edx,0xc(%ebp)
f010327b:	76 11                	jbe    f010328e <stab_binsearch+0x79>
			*region_left = m;
f010327d:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0103280:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0103282:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0103285:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f010328c:	eb 2b                	jmp    f01032b9 <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f010328e:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0103291:	73 14                	jae    f01032a7 <stab_binsearch+0x92>
			*region_right = m - 1;
f0103293:	83 e8 01             	sub    $0x1,%eax
f0103296:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0103299:	8b 75 e0             	mov    -0x20(%ebp),%esi
f010329c:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010329e:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01032a5:	eb 12                	jmp    f01032b9 <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01032a7:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01032aa:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f01032ac:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f01032b0:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01032b2:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f01032b9:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f01032bc:	0f 8e 78 ff ff ff    	jle    f010323a <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f01032c2:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f01032c6:	75 0f                	jne    f01032d7 <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f01032c8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01032cb:	8b 00                	mov    (%eax),%eax
f01032cd:	83 e8 01             	sub    $0x1,%eax
f01032d0:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01032d3:	89 06                	mov    %eax,(%esi)
f01032d5:	eb 2c                	jmp    f0103303 <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01032d7:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01032da:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f01032dc:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01032df:	8b 0e                	mov    (%esi),%ecx
f01032e1:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01032e4:	8b 75 ec             	mov    -0x14(%ebp),%esi
f01032e7:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01032ea:	eb 03                	jmp    f01032ef <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f01032ec:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01032ef:	39 c8                	cmp    %ecx,%eax
f01032f1:	7e 0b                	jle    f01032fe <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f01032f3:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f01032f7:	83 ea 0c             	sub    $0xc,%edx
f01032fa:	39 df                	cmp    %ebx,%edi
f01032fc:	75 ee                	jne    f01032ec <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f01032fe:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103301:	89 06                	mov    %eax,(%esi)
	}
}
f0103303:	83 c4 14             	add    $0x14,%esp
f0103306:	5b                   	pop    %ebx
f0103307:	5e                   	pop    %esi
f0103308:	5f                   	pop    %edi
f0103309:	5d                   	pop    %ebp
f010330a:	c3                   	ret    

f010330b <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f010330b:	55                   	push   %ebp
f010330c:	89 e5                	mov    %esp,%ebp
f010330e:	57                   	push   %edi
f010330f:	56                   	push   %esi
f0103310:	53                   	push   %ebx
f0103311:	83 ec 3c             	sub    $0x3c,%esp
f0103314:	8b 75 08             	mov    0x8(%ebp),%esi
f0103317:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f010331a:	c7 03 b7 55 10 f0    	movl   $0xf01055b7,(%ebx)
	info->eip_line = 0;
f0103320:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0103327:	c7 43 08 b7 55 10 f0 	movl   $0xf01055b7,0x8(%ebx)
	info->eip_fn_namelen = 9;
f010332e:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0103335:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0103338:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f010333f:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0103345:	77 21                	ja     f0103368 <debuginfo_eip+0x5d>

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.

		stabs = usd->stabs;
f0103347:	a1 00 00 20 00       	mov    0x200000,%eax
f010334c:	89 45 bc             	mov    %eax,-0x44(%ebp)
		stab_end = usd->stab_end;
f010334f:	a1 04 00 20 00       	mov    0x200004,%eax
		stabstr = usd->stabstr;
f0103354:	8b 3d 08 00 20 00    	mov    0x200008,%edi
f010335a:	89 7d b8             	mov    %edi,-0x48(%ebp)
		stabstr_end = usd->stabstr_end;
f010335d:	8b 3d 0c 00 20 00    	mov    0x20000c,%edi
f0103363:	89 7d c0             	mov    %edi,-0x40(%ebp)
f0103366:	eb 1a                	jmp    f0103382 <debuginfo_eip+0x77>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f0103368:	c7 45 c0 5a f5 10 f0 	movl   $0xf010f55a,-0x40(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f010336f:	c7 45 b8 75 cb 10 f0 	movl   $0xf010cb75,-0x48(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f0103376:	b8 74 cb 10 f0       	mov    $0xf010cb74,%eax
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f010337b:	c7 45 bc d0 57 10 f0 	movl   $0xf01057d0,-0x44(%ebp)
		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0103382:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0103385:	39 7d b8             	cmp    %edi,-0x48(%ebp)
f0103388:	0f 83 95 01 00 00    	jae    f0103523 <debuginfo_eip+0x218>
f010338e:	80 7f ff 00          	cmpb   $0x0,-0x1(%edi)
f0103392:	0f 85 92 01 00 00    	jne    f010352a <debuginfo_eip+0x21f>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0103398:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f010339f:	8b 7d bc             	mov    -0x44(%ebp),%edi
f01033a2:	29 f8                	sub    %edi,%eax
f01033a4:	c1 f8 02             	sar    $0x2,%eax
f01033a7:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f01033ad:	83 e8 01             	sub    $0x1,%eax
f01033b0:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f01033b3:	56                   	push   %esi
f01033b4:	6a 64                	push   $0x64
f01033b6:	8d 45 e0             	lea    -0x20(%ebp),%eax
f01033b9:	89 c1                	mov    %eax,%ecx
f01033bb:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01033be:	89 f8                	mov    %edi,%eax
f01033c0:	e8 50 fe ff ff       	call   f0103215 <stab_binsearch>
	if (lfile == 0)
f01033c5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01033c8:	83 c4 08             	add    $0x8,%esp
f01033cb:	85 c0                	test   %eax,%eax
f01033cd:	0f 84 5e 01 00 00    	je     f0103531 <debuginfo_eip+0x226>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f01033d3:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f01033d6:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01033d9:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f01033dc:	56                   	push   %esi
f01033dd:	6a 24                	push   $0x24
f01033df:	8d 45 d8             	lea    -0x28(%ebp),%eax
f01033e2:	89 c1                	mov    %eax,%ecx
f01033e4:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01033e7:	89 f8                	mov    %edi,%eax
f01033e9:	e8 27 fe ff ff       	call   f0103215 <stab_binsearch>

	if (lfun <= rfun) {
f01033ee:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01033f1:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01033f4:	89 55 c4             	mov    %edx,-0x3c(%ebp)
f01033f7:	83 c4 08             	add    $0x8,%esp
f01033fa:	39 d0                	cmp    %edx,%eax
f01033fc:	7f 2b                	jg     f0103429 <debuginfo_eip+0x11e>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f01033fe:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103401:	8d 0c 97             	lea    (%edi,%edx,4),%ecx
f0103404:	8b 11                	mov    (%ecx),%edx
f0103406:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0103409:	2b 7d b8             	sub    -0x48(%ebp),%edi
f010340c:	39 fa                	cmp    %edi,%edx
f010340e:	73 06                	jae    f0103416 <debuginfo_eip+0x10b>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0103410:	03 55 b8             	add    -0x48(%ebp),%edx
f0103413:	89 53 08             	mov    %edx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0103416:	8b 51 08             	mov    0x8(%ecx),%edx
f0103419:	89 53 10             	mov    %edx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f010341c:	29 d6                	sub    %edx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f010341e:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0103421:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0103424:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0103427:	eb 0f                	jmp    f0103438 <debuginfo_eip+0x12d>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0103429:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f010342c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010342f:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0103432:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103435:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0103438:	83 ec 08             	sub    $0x8,%esp
f010343b:	6a 3a                	push   $0x3a
f010343d:	ff 73 08             	pushl  0x8(%ebx)
f0103440:	e8 7a 08 00 00       	call   f0103cbf <strfind>
f0103445:	2b 43 08             	sub    0x8(%ebx),%eax
f0103448:	89 43 0c             	mov    %eax,0xc(%ebx)
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.

	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);	
f010344b:	83 c4 08             	add    $0x8,%esp
f010344e:	56                   	push   %esi
f010344f:	6a 44                	push   $0x44
f0103451:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0103454:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0103457:	8b 75 bc             	mov    -0x44(%ebp),%esi
f010345a:	89 f0                	mov    %esi,%eax
f010345c:	e8 b4 fd ff ff       	call   f0103215 <stab_binsearch>
	if (lline > rline)
f0103461:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103464:	83 c4 10             	add    $0x10,%esp
f0103467:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f010346a:	0f 8f c8 00 00 00    	jg     f0103538 <debuginfo_eip+0x22d>
		    return -1;
	info->eip_line = stabs[lline].n_desc;
f0103470:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103473:	8d 14 96             	lea    (%esi,%edx,4),%edx
f0103476:	0f b7 4a 06          	movzwl 0x6(%edx),%ecx
f010347a:	89 4b 04             	mov    %ecx,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f010347d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103480:	c6 45 c4 00          	movb   $0x0,-0x3c(%ebp)
f0103484:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103487:	eb 0a                	jmp    f0103493 <debuginfo_eip+0x188>
f0103489:	83 e8 01             	sub    $0x1,%eax
f010348c:	83 ea 0c             	sub    $0xc,%edx
f010348f:	c6 45 c4 01          	movb   $0x1,-0x3c(%ebp)
f0103493:	39 c7                	cmp    %eax,%edi
f0103495:	7e 05                	jle    f010349c <debuginfo_eip+0x191>
f0103497:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010349a:	eb 47                	jmp    f01034e3 <debuginfo_eip+0x1d8>
	       && stabs[lline].n_type != N_SOL
f010349c:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01034a0:	80 f9 84             	cmp    $0x84,%cl
f01034a3:	75 0e                	jne    f01034b3 <debuginfo_eip+0x1a8>
f01034a5:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01034a8:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f01034ac:	74 1c                	je     f01034ca <debuginfo_eip+0x1bf>
f01034ae:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01034b1:	eb 17                	jmp    f01034ca <debuginfo_eip+0x1bf>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f01034b3:	80 f9 64             	cmp    $0x64,%cl
f01034b6:	75 d1                	jne    f0103489 <debuginfo_eip+0x17e>
f01034b8:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f01034bc:	74 cb                	je     f0103489 <debuginfo_eip+0x17e>
f01034be:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01034c1:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f01034c5:	74 03                	je     f01034ca <debuginfo_eip+0x1bf>
f01034c7:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f01034ca:	8d 04 40             	lea    (%eax,%eax,2),%eax
f01034cd:	8b 7d bc             	mov    -0x44(%ebp),%edi
f01034d0:	8b 14 87             	mov    (%edi,%eax,4),%edx
f01034d3:	8b 45 c0             	mov    -0x40(%ebp),%eax
f01034d6:	8b 75 b8             	mov    -0x48(%ebp),%esi
f01034d9:	29 f0                	sub    %esi,%eax
f01034db:	39 c2                	cmp    %eax,%edx
f01034dd:	73 04                	jae    f01034e3 <debuginfo_eip+0x1d8>
		info->eip_file = stabstr + stabs[lline].n_strx;
f01034df:	01 f2                	add    %esi,%edx
f01034e1:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01034e3:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01034e6:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01034e9:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01034ee:	39 f2                	cmp    %esi,%edx
f01034f0:	7d 52                	jge    f0103544 <debuginfo_eip+0x239>
		for (lline = lfun + 1;
f01034f2:	83 c2 01             	add    $0x1,%edx
f01034f5:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f01034f8:	89 d0                	mov    %edx,%eax
f01034fa:	8d 14 52             	lea    (%edx,%edx,2),%edx
f01034fd:	8b 7d bc             	mov    -0x44(%ebp),%edi
f0103500:	8d 14 97             	lea    (%edi,%edx,4),%edx
f0103503:	eb 04                	jmp    f0103509 <debuginfo_eip+0x1fe>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0103505:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0103509:	39 c6                	cmp    %eax,%esi
f010350b:	7e 32                	jle    f010353f <debuginfo_eip+0x234>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f010350d:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0103511:	83 c0 01             	add    $0x1,%eax
f0103514:	83 c2 0c             	add    $0xc,%edx
f0103517:	80 f9 a0             	cmp    $0xa0,%cl
f010351a:	74 e9                	je     f0103505 <debuginfo_eip+0x1fa>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f010351c:	b8 00 00 00 00       	mov    $0x0,%eax
f0103521:	eb 21                	jmp    f0103544 <debuginfo_eip+0x239>
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0103523:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103528:	eb 1a                	jmp    f0103544 <debuginfo_eip+0x239>
f010352a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010352f:	eb 13                	jmp    f0103544 <debuginfo_eip+0x239>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0103531:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103536:	eb 0c                	jmp    f0103544 <debuginfo_eip+0x239>
	//	which one.
	// Your code here.

	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);	
	if (lline > rline)
		    return -1;
f0103538:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010353d:	eb 05                	jmp    f0103544 <debuginfo_eip+0x239>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f010353f:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103544:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103547:	5b                   	pop    %ebx
f0103548:	5e                   	pop    %esi
f0103549:	5f                   	pop    %edi
f010354a:	5d                   	pop    %ebp
f010354b:	c3                   	ret    

f010354c <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f010354c:	55                   	push   %ebp
f010354d:	89 e5                	mov    %esp,%ebp
f010354f:	57                   	push   %edi
f0103550:	56                   	push   %esi
f0103551:	53                   	push   %ebx
f0103552:	83 ec 1c             	sub    $0x1c,%esp
f0103555:	89 c7                	mov    %eax,%edi
f0103557:	89 d6                	mov    %edx,%esi
f0103559:	8b 45 08             	mov    0x8(%ebp),%eax
f010355c:	8b 55 0c             	mov    0xc(%ebp),%edx
f010355f:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103562:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0103565:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0103568:	bb 00 00 00 00       	mov    $0x0,%ebx
f010356d:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0103570:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0103573:	39 d3                	cmp    %edx,%ebx
f0103575:	72 05                	jb     f010357c <printnum+0x30>
f0103577:	39 45 10             	cmp    %eax,0x10(%ebp)
f010357a:	77 45                	ja     f01035c1 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f010357c:	83 ec 0c             	sub    $0xc,%esp
f010357f:	ff 75 18             	pushl  0x18(%ebp)
f0103582:	8b 45 14             	mov    0x14(%ebp),%eax
f0103585:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0103588:	53                   	push   %ebx
f0103589:	ff 75 10             	pushl  0x10(%ebp)
f010358c:	83 ec 08             	sub    $0x8,%esp
f010358f:	ff 75 e4             	pushl  -0x1c(%ebp)
f0103592:	ff 75 e0             	pushl  -0x20(%ebp)
f0103595:	ff 75 dc             	pushl  -0x24(%ebp)
f0103598:	ff 75 d8             	pushl  -0x28(%ebp)
f010359b:	e8 40 09 00 00       	call   f0103ee0 <__udivdi3>
f01035a0:	83 c4 18             	add    $0x18,%esp
f01035a3:	52                   	push   %edx
f01035a4:	50                   	push   %eax
f01035a5:	89 f2                	mov    %esi,%edx
f01035a7:	89 f8                	mov    %edi,%eax
f01035a9:	e8 9e ff ff ff       	call   f010354c <printnum>
f01035ae:	83 c4 20             	add    $0x20,%esp
f01035b1:	eb 18                	jmp    f01035cb <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f01035b3:	83 ec 08             	sub    $0x8,%esp
f01035b6:	56                   	push   %esi
f01035b7:	ff 75 18             	pushl  0x18(%ebp)
f01035ba:	ff d7                	call   *%edi
f01035bc:	83 c4 10             	add    $0x10,%esp
f01035bf:	eb 03                	jmp    f01035c4 <printnum+0x78>
f01035c1:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f01035c4:	83 eb 01             	sub    $0x1,%ebx
f01035c7:	85 db                	test   %ebx,%ebx
f01035c9:	7f e8                	jg     f01035b3 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f01035cb:	83 ec 08             	sub    $0x8,%esp
f01035ce:	56                   	push   %esi
f01035cf:	83 ec 04             	sub    $0x4,%esp
f01035d2:	ff 75 e4             	pushl  -0x1c(%ebp)
f01035d5:	ff 75 e0             	pushl  -0x20(%ebp)
f01035d8:	ff 75 dc             	pushl  -0x24(%ebp)
f01035db:	ff 75 d8             	pushl  -0x28(%ebp)
f01035de:	e8 2d 0a 00 00       	call   f0104010 <__umoddi3>
f01035e3:	83 c4 14             	add    $0x14,%esp
f01035e6:	0f be 80 c1 55 10 f0 	movsbl -0xfefaa3f(%eax),%eax
f01035ed:	50                   	push   %eax
f01035ee:	ff d7                	call   *%edi
}
f01035f0:	83 c4 10             	add    $0x10,%esp
f01035f3:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01035f6:	5b                   	pop    %ebx
f01035f7:	5e                   	pop    %esi
f01035f8:	5f                   	pop    %edi
f01035f9:	5d                   	pop    %ebp
f01035fa:	c3                   	ret    

f01035fb <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f01035fb:	55                   	push   %ebp
f01035fc:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f01035fe:	83 fa 01             	cmp    $0x1,%edx
f0103601:	7e 0e                	jle    f0103611 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0103603:	8b 10                	mov    (%eax),%edx
f0103605:	8d 4a 08             	lea    0x8(%edx),%ecx
f0103608:	89 08                	mov    %ecx,(%eax)
f010360a:	8b 02                	mov    (%edx),%eax
f010360c:	8b 52 04             	mov    0x4(%edx),%edx
f010360f:	eb 22                	jmp    f0103633 <getuint+0x38>
	else if (lflag)
f0103611:	85 d2                	test   %edx,%edx
f0103613:	74 10                	je     f0103625 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0103615:	8b 10                	mov    (%eax),%edx
f0103617:	8d 4a 04             	lea    0x4(%edx),%ecx
f010361a:	89 08                	mov    %ecx,(%eax)
f010361c:	8b 02                	mov    (%edx),%eax
f010361e:	ba 00 00 00 00       	mov    $0x0,%edx
f0103623:	eb 0e                	jmp    f0103633 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0103625:	8b 10                	mov    (%eax),%edx
f0103627:	8d 4a 04             	lea    0x4(%edx),%ecx
f010362a:	89 08                	mov    %ecx,(%eax)
f010362c:	8b 02                	mov    (%edx),%eax
f010362e:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0103633:	5d                   	pop    %ebp
f0103634:	c3                   	ret    

f0103635 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0103635:	55                   	push   %ebp
f0103636:	89 e5                	mov    %esp,%ebp
f0103638:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f010363b:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f010363f:	8b 10                	mov    (%eax),%edx
f0103641:	3b 50 04             	cmp    0x4(%eax),%edx
f0103644:	73 0a                	jae    f0103650 <sprintputch+0x1b>
		*b->buf++ = ch;
f0103646:	8d 4a 01             	lea    0x1(%edx),%ecx
f0103649:	89 08                	mov    %ecx,(%eax)
f010364b:	8b 45 08             	mov    0x8(%ebp),%eax
f010364e:	88 02                	mov    %al,(%edx)
}
f0103650:	5d                   	pop    %ebp
f0103651:	c3                   	ret    

f0103652 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0103652:	55                   	push   %ebp
f0103653:	89 e5                	mov    %esp,%ebp
f0103655:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0103658:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f010365b:	50                   	push   %eax
f010365c:	ff 75 10             	pushl  0x10(%ebp)
f010365f:	ff 75 0c             	pushl  0xc(%ebp)
f0103662:	ff 75 08             	pushl  0x8(%ebp)
f0103665:	e8 05 00 00 00       	call   f010366f <vprintfmt>
	va_end(ap);
}
f010366a:	83 c4 10             	add    $0x10,%esp
f010366d:	c9                   	leave  
f010366e:	c3                   	ret    

f010366f <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f010366f:	55                   	push   %ebp
f0103670:	89 e5                	mov    %esp,%ebp
f0103672:	57                   	push   %edi
f0103673:	56                   	push   %esi
f0103674:	53                   	push   %ebx
f0103675:	83 ec 2c             	sub    $0x2c,%esp
f0103678:	8b 75 08             	mov    0x8(%ebp),%esi
f010367b:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010367e:	8b 7d 10             	mov    0x10(%ebp),%edi
f0103681:	eb 12                	jmp    f0103695 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0103683:	85 c0                	test   %eax,%eax
f0103685:	0f 84 89 03 00 00    	je     f0103a14 <vprintfmt+0x3a5>
				return;
			putch(ch, putdat);
f010368b:	83 ec 08             	sub    $0x8,%esp
f010368e:	53                   	push   %ebx
f010368f:	50                   	push   %eax
f0103690:	ff d6                	call   *%esi
f0103692:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0103695:	83 c7 01             	add    $0x1,%edi
f0103698:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f010369c:	83 f8 25             	cmp    $0x25,%eax
f010369f:	75 e2                	jne    f0103683 <vprintfmt+0x14>
f01036a1:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f01036a5:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f01036ac:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f01036b3:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f01036ba:	ba 00 00 00 00       	mov    $0x0,%edx
f01036bf:	eb 07                	jmp    f01036c8 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01036c1:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f01036c4:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01036c8:	8d 47 01             	lea    0x1(%edi),%eax
f01036cb:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01036ce:	0f b6 07             	movzbl (%edi),%eax
f01036d1:	0f b6 c8             	movzbl %al,%ecx
f01036d4:	83 e8 23             	sub    $0x23,%eax
f01036d7:	3c 55                	cmp    $0x55,%al
f01036d9:	0f 87 1a 03 00 00    	ja     f01039f9 <vprintfmt+0x38a>
f01036df:	0f b6 c0             	movzbl %al,%eax
f01036e2:	ff 24 85 4c 56 10 f0 	jmp    *-0xfefa9b4(,%eax,4)
f01036e9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f01036ec:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f01036f0:	eb d6                	jmp    f01036c8 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01036f2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01036f5:	b8 00 00 00 00       	mov    $0x0,%eax
f01036fa:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f01036fd:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0103700:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f0103704:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0103707:	8d 51 d0             	lea    -0x30(%ecx),%edx
f010370a:	83 fa 09             	cmp    $0x9,%edx
f010370d:	77 39                	ja     f0103748 <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f010370f:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0103712:	eb e9                	jmp    f01036fd <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0103714:	8b 45 14             	mov    0x14(%ebp),%eax
f0103717:	8d 48 04             	lea    0x4(%eax),%ecx
f010371a:	89 4d 14             	mov    %ecx,0x14(%ebp)
f010371d:	8b 00                	mov    (%eax),%eax
f010371f:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103722:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0103725:	eb 27                	jmp    f010374e <vprintfmt+0xdf>
f0103727:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010372a:	85 c0                	test   %eax,%eax
f010372c:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103731:	0f 49 c8             	cmovns %eax,%ecx
f0103734:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103737:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010373a:	eb 8c                	jmp    f01036c8 <vprintfmt+0x59>
f010373c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f010373f:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0103746:	eb 80                	jmp    f01036c8 <vprintfmt+0x59>
f0103748:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f010374b:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f010374e:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0103752:	0f 89 70 ff ff ff    	jns    f01036c8 <vprintfmt+0x59>
				width = precision, precision = -1;
f0103758:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010375b:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010375e:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0103765:	e9 5e ff ff ff       	jmp    f01036c8 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f010376a:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010376d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0103770:	e9 53 ff ff ff       	jmp    f01036c8 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0103775:	8b 45 14             	mov    0x14(%ebp),%eax
f0103778:	8d 50 04             	lea    0x4(%eax),%edx
f010377b:	89 55 14             	mov    %edx,0x14(%ebp)
f010377e:	83 ec 08             	sub    $0x8,%esp
f0103781:	53                   	push   %ebx
f0103782:	ff 30                	pushl  (%eax)
f0103784:	ff d6                	call   *%esi
			break;
f0103786:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103789:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f010378c:	e9 04 ff ff ff       	jmp    f0103695 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0103791:	8b 45 14             	mov    0x14(%ebp),%eax
f0103794:	8d 50 04             	lea    0x4(%eax),%edx
f0103797:	89 55 14             	mov    %edx,0x14(%ebp)
f010379a:	8b 00                	mov    (%eax),%eax
f010379c:	99                   	cltd   
f010379d:	31 d0                	xor    %edx,%eax
f010379f:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f01037a1:	83 f8 06             	cmp    $0x6,%eax
f01037a4:	7f 0b                	jg     f01037b1 <vprintfmt+0x142>
f01037a6:	8b 14 85 a4 57 10 f0 	mov    -0xfefa85c(,%eax,4),%edx
f01037ad:	85 d2                	test   %edx,%edx
f01037af:	75 18                	jne    f01037c9 <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f01037b1:	50                   	push   %eax
f01037b2:	68 d9 55 10 f0       	push   $0xf01055d9
f01037b7:	53                   	push   %ebx
f01037b8:	56                   	push   %esi
f01037b9:	e8 94 fe ff ff       	call   f0103652 <printfmt>
f01037be:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01037c1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f01037c4:	e9 cc fe ff ff       	jmp    f0103695 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f01037c9:	52                   	push   %edx
f01037ca:	68 74 4e 10 f0       	push   $0xf0104e74
f01037cf:	53                   	push   %ebx
f01037d0:	56                   	push   %esi
f01037d1:	e8 7c fe ff ff       	call   f0103652 <printfmt>
f01037d6:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01037d9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01037dc:	e9 b4 fe ff ff       	jmp    f0103695 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f01037e1:	8b 45 14             	mov    0x14(%ebp),%eax
f01037e4:	8d 50 04             	lea    0x4(%eax),%edx
f01037e7:	89 55 14             	mov    %edx,0x14(%ebp)
f01037ea:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f01037ec:	85 ff                	test   %edi,%edi
f01037ee:	b8 d2 55 10 f0       	mov    $0xf01055d2,%eax
f01037f3:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f01037f6:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f01037fa:	0f 8e 94 00 00 00    	jle    f0103894 <vprintfmt+0x225>
f0103800:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0103804:	0f 84 98 00 00 00    	je     f01038a2 <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
f010380a:	83 ec 08             	sub    $0x8,%esp
f010380d:	ff 75 d0             	pushl  -0x30(%ebp)
f0103810:	57                   	push   %edi
f0103811:	e8 5f 03 00 00       	call   f0103b75 <strnlen>
f0103816:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0103819:	29 c1                	sub    %eax,%ecx
f010381b:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f010381e:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0103821:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0103825:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103828:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f010382b:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f010382d:	eb 0f                	jmp    f010383e <vprintfmt+0x1cf>
					putch(padc, putdat);
f010382f:	83 ec 08             	sub    $0x8,%esp
f0103832:	53                   	push   %ebx
f0103833:	ff 75 e0             	pushl  -0x20(%ebp)
f0103836:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0103838:	83 ef 01             	sub    $0x1,%edi
f010383b:	83 c4 10             	add    $0x10,%esp
f010383e:	85 ff                	test   %edi,%edi
f0103840:	7f ed                	jg     f010382f <vprintfmt+0x1c0>
f0103842:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0103845:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0103848:	85 c9                	test   %ecx,%ecx
f010384a:	b8 00 00 00 00       	mov    $0x0,%eax
f010384f:	0f 49 c1             	cmovns %ecx,%eax
f0103852:	29 c1                	sub    %eax,%ecx
f0103854:	89 75 08             	mov    %esi,0x8(%ebp)
f0103857:	8b 75 d0             	mov    -0x30(%ebp),%esi
f010385a:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f010385d:	89 cb                	mov    %ecx,%ebx
f010385f:	eb 4d                	jmp    f01038ae <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0103861:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0103865:	74 1b                	je     f0103882 <vprintfmt+0x213>
f0103867:	0f be c0             	movsbl %al,%eax
f010386a:	83 e8 20             	sub    $0x20,%eax
f010386d:	83 f8 5e             	cmp    $0x5e,%eax
f0103870:	76 10                	jbe    f0103882 <vprintfmt+0x213>
					putch('?', putdat);
f0103872:	83 ec 08             	sub    $0x8,%esp
f0103875:	ff 75 0c             	pushl  0xc(%ebp)
f0103878:	6a 3f                	push   $0x3f
f010387a:	ff 55 08             	call   *0x8(%ebp)
f010387d:	83 c4 10             	add    $0x10,%esp
f0103880:	eb 0d                	jmp    f010388f <vprintfmt+0x220>
				else
					putch(ch, putdat);
f0103882:	83 ec 08             	sub    $0x8,%esp
f0103885:	ff 75 0c             	pushl  0xc(%ebp)
f0103888:	52                   	push   %edx
f0103889:	ff 55 08             	call   *0x8(%ebp)
f010388c:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f010388f:	83 eb 01             	sub    $0x1,%ebx
f0103892:	eb 1a                	jmp    f01038ae <vprintfmt+0x23f>
f0103894:	89 75 08             	mov    %esi,0x8(%ebp)
f0103897:	8b 75 d0             	mov    -0x30(%ebp),%esi
f010389a:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f010389d:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f01038a0:	eb 0c                	jmp    f01038ae <vprintfmt+0x23f>
f01038a2:	89 75 08             	mov    %esi,0x8(%ebp)
f01038a5:	8b 75 d0             	mov    -0x30(%ebp),%esi
f01038a8:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f01038ab:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f01038ae:	83 c7 01             	add    $0x1,%edi
f01038b1:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f01038b5:	0f be d0             	movsbl %al,%edx
f01038b8:	85 d2                	test   %edx,%edx
f01038ba:	74 23                	je     f01038df <vprintfmt+0x270>
f01038bc:	85 f6                	test   %esi,%esi
f01038be:	78 a1                	js     f0103861 <vprintfmt+0x1f2>
f01038c0:	83 ee 01             	sub    $0x1,%esi
f01038c3:	79 9c                	jns    f0103861 <vprintfmt+0x1f2>
f01038c5:	89 df                	mov    %ebx,%edi
f01038c7:	8b 75 08             	mov    0x8(%ebp),%esi
f01038ca:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01038cd:	eb 18                	jmp    f01038e7 <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f01038cf:	83 ec 08             	sub    $0x8,%esp
f01038d2:	53                   	push   %ebx
f01038d3:	6a 20                	push   $0x20
f01038d5:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f01038d7:	83 ef 01             	sub    $0x1,%edi
f01038da:	83 c4 10             	add    $0x10,%esp
f01038dd:	eb 08                	jmp    f01038e7 <vprintfmt+0x278>
f01038df:	89 df                	mov    %ebx,%edi
f01038e1:	8b 75 08             	mov    0x8(%ebp),%esi
f01038e4:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01038e7:	85 ff                	test   %edi,%edi
f01038e9:	7f e4                	jg     f01038cf <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01038eb:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01038ee:	e9 a2 fd ff ff       	jmp    f0103695 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f01038f3:	83 fa 01             	cmp    $0x1,%edx
f01038f6:	7e 16                	jle    f010390e <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f01038f8:	8b 45 14             	mov    0x14(%ebp),%eax
f01038fb:	8d 50 08             	lea    0x8(%eax),%edx
f01038fe:	89 55 14             	mov    %edx,0x14(%ebp)
f0103901:	8b 50 04             	mov    0x4(%eax),%edx
f0103904:	8b 00                	mov    (%eax),%eax
f0103906:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103909:	89 55 dc             	mov    %edx,-0x24(%ebp)
f010390c:	eb 32                	jmp    f0103940 <vprintfmt+0x2d1>
	else if (lflag)
f010390e:	85 d2                	test   %edx,%edx
f0103910:	74 18                	je     f010392a <vprintfmt+0x2bb>
		return va_arg(*ap, long);
f0103912:	8b 45 14             	mov    0x14(%ebp),%eax
f0103915:	8d 50 04             	lea    0x4(%eax),%edx
f0103918:	89 55 14             	mov    %edx,0x14(%ebp)
f010391b:	8b 00                	mov    (%eax),%eax
f010391d:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103920:	89 c1                	mov    %eax,%ecx
f0103922:	c1 f9 1f             	sar    $0x1f,%ecx
f0103925:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0103928:	eb 16                	jmp    f0103940 <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
f010392a:	8b 45 14             	mov    0x14(%ebp),%eax
f010392d:	8d 50 04             	lea    0x4(%eax),%edx
f0103930:	89 55 14             	mov    %edx,0x14(%ebp)
f0103933:	8b 00                	mov    (%eax),%eax
f0103935:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103938:	89 c1                	mov    %eax,%ecx
f010393a:	c1 f9 1f             	sar    $0x1f,%ecx
f010393d:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0103940:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0103943:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0103946:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f010394b:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f010394f:	79 74                	jns    f01039c5 <vprintfmt+0x356>
				putch('-', putdat);
f0103951:	83 ec 08             	sub    $0x8,%esp
f0103954:	53                   	push   %ebx
f0103955:	6a 2d                	push   $0x2d
f0103957:	ff d6                	call   *%esi
				num = -(long long) num;
f0103959:	8b 45 d8             	mov    -0x28(%ebp),%eax
f010395c:	8b 55 dc             	mov    -0x24(%ebp),%edx
f010395f:	f7 d8                	neg    %eax
f0103961:	83 d2 00             	adc    $0x0,%edx
f0103964:	f7 da                	neg    %edx
f0103966:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0103969:	b9 0a 00 00 00       	mov    $0xa,%ecx
f010396e:	eb 55                	jmp    f01039c5 <vprintfmt+0x356>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0103970:	8d 45 14             	lea    0x14(%ebp),%eax
f0103973:	e8 83 fc ff ff       	call   f01035fb <getuint>
			base = 10;
f0103978:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f010397d:	eb 46                	jmp    f01039c5 <vprintfmt+0x356>
		// (unsigned) octal
		case 'o':
			//putch('X', putdat);
			//putch('X', putdat);
			//putch('X', putdat);
			num = getuint(&ap, lflag);
f010397f:	8d 45 14             	lea    0x14(%ebp),%eax
f0103982:	e8 74 fc ff ff       	call   f01035fb <getuint>
			base = 8;
f0103987:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f010398c:	eb 37                	jmp    f01039c5 <vprintfmt+0x356>

		// pointer
		case 'p':
			putch('0', putdat);
f010398e:	83 ec 08             	sub    $0x8,%esp
f0103991:	53                   	push   %ebx
f0103992:	6a 30                	push   $0x30
f0103994:	ff d6                	call   *%esi
			putch('x', putdat);
f0103996:	83 c4 08             	add    $0x8,%esp
f0103999:	53                   	push   %ebx
f010399a:	6a 78                	push   $0x78
f010399c:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f010399e:	8b 45 14             	mov    0x14(%ebp),%eax
f01039a1:	8d 50 04             	lea    0x4(%eax),%edx
f01039a4:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f01039a7:	8b 00                	mov    (%eax),%eax
f01039a9:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f01039ae:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f01039b1:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f01039b6:	eb 0d                	jmp    f01039c5 <vprintfmt+0x356>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f01039b8:	8d 45 14             	lea    0x14(%ebp),%eax
f01039bb:	e8 3b fc ff ff       	call   f01035fb <getuint>
			base = 16;
f01039c0:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f01039c5:	83 ec 0c             	sub    $0xc,%esp
f01039c8:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f01039cc:	57                   	push   %edi
f01039cd:	ff 75 e0             	pushl  -0x20(%ebp)
f01039d0:	51                   	push   %ecx
f01039d1:	52                   	push   %edx
f01039d2:	50                   	push   %eax
f01039d3:	89 da                	mov    %ebx,%edx
f01039d5:	89 f0                	mov    %esi,%eax
f01039d7:	e8 70 fb ff ff       	call   f010354c <printnum>
			break;
f01039dc:	83 c4 20             	add    $0x20,%esp
f01039df:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01039e2:	e9 ae fc ff ff       	jmp    f0103695 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f01039e7:	83 ec 08             	sub    $0x8,%esp
f01039ea:	53                   	push   %ebx
f01039eb:	51                   	push   %ecx
f01039ec:	ff d6                	call   *%esi
			break;
f01039ee:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01039f1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f01039f4:	e9 9c fc ff ff       	jmp    f0103695 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f01039f9:	83 ec 08             	sub    $0x8,%esp
f01039fc:	53                   	push   %ebx
f01039fd:	6a 25                	push   $0x25
f01039ff:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0103a01:	83 c4 10             	add    $0x10,%esp
f0103a04:	eb 03                	jmp    f0103a09 <vprintfmt+0x39a>
f0103a06:	83 ef 01             	sub    $0x1,%edi
f0103a09:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0103a0d:	75 f7                	jne    f0103a06 <vprintfmt+0x397>
f0103a0f:	e9 81 fc ff ff       	jmp    f0103695 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0103a14:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103a17:	5b                   	pop    %ebx
f0103a18:	5e                   	pop    %esi
f0103a19:	5f                   	pop    %edi
f0103a1a:	5d                   	pop    %ebp
f0103a1b:	c3                   	ret    

f0103a1c <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0103a1c:	55                   	push   %ebp
f0103a1d:	89 e5                	mov    %esp,%ebp
f0103a1f:	83 ec 18             	sub    $0x18,%esp
f0103a22:	8b 45 08             	mov    0x8(%ebp),%eax
f0103a25:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0103a28:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103a2b:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0103a2f:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0103a32:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0103a39:	85 c0                	test   %eax,%eax
f0103a3b:	74 26                	je     f0103a63 <vsnprintf+0x47>
f0103a3d:	85 d2                	test   %edx,%edx
f0103a3f:	7e 22                	jle    f0103a63 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0103a41:	ff 75 14             	pushl  0x14(%ebp)
f0103a44:	ff 75 10             	pushl  0x10(%ebp)
f0103a47:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0103a4a:	50                   	push   %eax
f0103a4b:	68 35 36 10 f0       	push   $0xf0103635
f0103a50:	e8 1a fc ff ff       	call   f010366f <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0103a55:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0103a58:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0103a5b:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103a5e:	83 c4 10             	add    $0x10,%esp
f0103a61:	eb 05                	jmp    f0103a68 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0103a63:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0103a68:	c9                   	leave  
f0103a69:	c3                   	ret    

f0103a6a <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0103a6a:	55                   	push   %ebp
f0103a6b:	89 e5                	mov    %esp,%ebp
f0103a6d:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0103a70:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0103a73:	50                   	push   %eax
f0103a74:	ff 75 10             	pushl  0x10(%ebp)
f0103a77:	ff 75 0c             	pushl  0xc(%ebp)
f0103a7a:	ff 75 08             	pushl  0x8(%ebp)
f0103a7d:	e8 9a ff ff ff       	call   f0103a1c <vsnprintf>
	va_end(ap);

	return rc;
}
f0103a82:	c9                   	leave  
f0103a83:	c3                   	ret    

f0103a84 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0103a84:	55                   	push   %ebp
f0103a85:	89 e5                	mov    %esp,%ebp
f0103a87:	57                   	push   %edi
f0103a88:	56                   	push   %esi
f0103a89:	53                   	push   %ebx
f0103a8a:	83 ec 0c             	sub    $0xc,%esp
f0103a8d:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0103a90:	85 c0                	test   %eax,%eax
f0103a92:	74 11                	je     f0103aa5 <readline+0x21>
		cprintf("%s", prompt);
f0103a94:	83 ec 08             	sub    $0x8,%esp
f0103a97:	50                   	push   %eax
f0103a98:	68 74 4e 10 f0       	push   $0xf0104e74
f0103a9d:	e8 b5 f3 ff ff       	call   f0102e57 <cprintf>
f0103aa2:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0103aa5:	83 ec 0c             	sub    $0xc,%esp
f0103aa8:	6a 00                	push   $0x0
f0103aaa:	e8 87 cb ff ff       	call   f0100636 <iscons>
f0103aaf:	89 c7                	mov    %eax,%edi
f0103ab1:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0103ab4:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0103ab9:	e8 67 cb ff ff       	call   f0100625 <getchar>
f0103abe:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0103ac0:	85 c0                	test   %eax,%eax
f0103ac2:	79 18                	jns    f0103adc <readline+0x58>
			cprintf("read error: %e\n", c);
f0103ac4:	83 ec 08             	sub    $0x8,%esp
f0103ac7:	50                   	push   %eax
f0103ac8:	68 c0 57 10 f0       	push   $0xf01057c0
f0103acd:	e8 85 f3 ff ff       	call   f0102e57 <cprintf>
			return NULL;
f0103ad2:	83 c4 10             	add    $0x10,%esp
f0103ad5:	b8 00 00 00 00       	mov    $0x0,%eax
f0103ada:	eb 79                	jmp    f0103b55 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0103adc:	83 f8 08             	cmp    $0x8,%eax
f0103adf:	0f 94 c2             	sete   %dl
f0103ae2:	83 f8 7f             	cmp    $0x7f,%eax
f0103ae5:	0f 94 c0             	sete   %al
f0103ae8:	08 c2                	or     %al,%dl
f0103aea:	74 1a                	je     f0103b06 <readline+0x82>
f0103aec:	85 f6                	test   %esi,%esi
f0103aee:	7e 16                	jle    f0103b06 <readline+0x82>
			if (echoing)
f0103af0:	85 ff                	test   %edi,%edi
f0103af2:	74 0d                	je     f0103b01 <readline+0x7d>
				cputchar('\b');
f0103af4:	83 ec 0c             	sub    $0xc,%esp
f0103af7:	6a 08                	push   $0x8
f0103af9:	e8 17 cb ff ff       	call   f0100615 <cputchar>
f0103afe:	83 c4 10             	add    $0x10,%esp
			i--;
f0103b01:	83 ee 01             	sub    $0x1,%esi
f0103b04:	eb b3                	jmp    f0103ab9 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0103b06:	83 fb 1f             	cmp    $0x1f,%ebx
f0103b09:	7e 23                	jle    f0103b2e <readline+0xaa>
f0103b0b:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0103b11:	7f 1b                	jg     f0103b2e <readline+0xaa>
			if (echoing)
f0103b13:	85 ff                	test   %edi,%edi
f0103b15:	74 0c                	je     f0103b23 <readline+0x9f>
				cputchar(c);
f0103b17:	83 ec 0c             	sub    $0xc,%esp
f0103b1a:	53                   	push   %ebx
f0103b1b:	e8 f5 ca ff ff       	call   f0100615 <cputchar>
f0103b20:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0103b23:	88 9e 40 08 17 f0    	mov    %bl,-0xfe8f7c0(%esi)
f0103b29:	8d 76 01             	lea    0x1(%esi),%esi
f0103b2c:	eb 8b                	jmp    f0103ab9 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0103b2e:	83 fb 0a             	cmp    $0xa,%ebx
f0103b31:	74 05                	je     f0103b38 <readline+0xb4>
f0103b33:	83 fb 0d             	cmp    $0xd,%ebx
f0103b36:	75 81                	jne    f0103ab9 <readline+0x35>
			if (echoing)
f0103b38:	85 ff                	test   %edi,%edi
f0103b3a:	74 0d                	je     f0103b49 <readline+0xc5>
				cputchar('\n');
f0103b3c:	83 ec 0c             	sub    $0xc,%esp
f0103b3f:	6a 0a                	push   $0xa
f0103b41:	e8 cf ca ff ff       	call   f0100615 <cputchar>
f0103b46:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0103b49:	c6 86 40 08 17 f0 00 	movb   $0x0,-0xfe8f7c0(%esi)
			return buf;
f0103b50:	b8 40 08 17 f0       	mov    $0xf0170840,%eax
		}
	}
}
f0103b55:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103b58:	5b                   	pop    %ebx
f0103b59:	5e                   	pop    %esi
f0103b5a:	5f                   	pop    %edi
f0103b5b:	5d                   	pop    %ebp
f0103b5c:	c3                   	ret    

f0103b5d <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0103b5d:	55                   	push   %ebp
f0103b5e:	89 e5                	mov    %esp,%ebp
f0103b60:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0103b63:	b8 00 00 00 00       	mov    $0x0,%eax
f0103b68:	eb 03                	jmp    f0103b6d <strlen+0x10>
		n++;
f0103b6a:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0103b6d:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0103b71:	75 f7                	jne    f0103b6a <strlen+0xd>
		n++;
	return n;
}
f0103b73:	5d                   	pop    %ebp
f0103b74:	c3                   	ret    

f0103b75 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0103b75:	55                   	push   %ebp
f0103b76:	89 e5                	mov    %esp,%ebp
f0103b78:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103b7b:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103b7e:	ba 00 00 00 00       	mov    $0x0,%edx
f0103b83:	eb 03                	jmp    f0103b88 <strnlen+0x13>
		n++;
f0103b85:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103b88:	39 c2                	cmp    %eax,%edx
f0103b8a:	74 08                	je     f0103b94 <strnlen+0x1f>
f0103b8c:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f0103b90:	75 f3                	jne    f0103b85 <strnlen+0x10>
f0103b92:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0103b94:	5d                   	pop    %ebp
f0103b95:	c3                   	ret    

f0103b96 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0103b96:	55                   	push   %ebp
f0103b97:	89 e5                	mov    %esp,%ebp
f0103b99:	53                   	push   %ebx
f0103b9a:	8b 45 08             	mov    0x8(%ebp),%eax
f0103b9d:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0103ba0:	89 c2                	mov    %eax,%edx
f0103ba2:	83 c2 01             	add    $0x1,%edx
f0103ba5:	83 c1 01             	add    $0x1,%ecx
f0103ba8:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0103bac:	88 5a ff             	mov    %bl,-0x1(%edx)
f0103baf:	84 db                	test   %bl,%bl
f0103bb1:	75 ef                	jne    f0103ba2 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0103bb3:	5b                   	pop    %ebx
f0103bb4:	5d                   	pop    %ebp
f0103bb5:	c3                   	ret    

f0103bb6 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0103bb6:	55                   	push   %ebp
f0103bb7:	89 e5                	mov    %esp,%ebp
f0103bb9:	53                   	push   %ebx
f0103bba:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0103bbd:	53                   	push   %ebx
f0103bbe:	e8 9a ff ff ff       	call   f0103b5d <strlen>
f0103bc3:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0103bc6:	ff 75 0c             	pushl  0xc(%ebp)
f0103bc9:	01 d8                	add    %ebx,%eax
f0103bcb:	50                   	push   %eax
f0103bcc:	e8 c5 ff ff ff       	call   f0103b96 <strcpy>
	return dst;
}
f0103bd1:	89 d8                	mov    %ebx,%eax
f0103bd3:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103bd6:	c9                   	leave  
f0103bd7:	c3                   	ret    

f0103bd8 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0103bd8:	55                   	push   %ebp
f0103bd9:	89 e5                	mov    %esp,%ebp
f0103bdb:	56                   	push   %esi
f0103bdc:	53                   	push   %ebx
f0103bdd:	8b 75 08             	mov    0x8(%ebp),%esi
f0103be0:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103be3:	89 f3                	mov    %esi,%ebx
f0103be5:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103be8:	89 f2                	mov    %esi,%edx
f0103bea:	eb 0f                	jmp    f0103bfb <strncpy+0x23>
		*dst++ = *src;
f0103bec:	83 c2 01             	add    $0x1,%edx
f0103bef:	0f b6 01             	movzbl (%ecx),%eax
f0103bf2:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0103bf5:	80 39 01             	cmpb   $0x1,(%ecx)
f0103bf8:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103bfb:	39 da                	cmp    %ebx,%edx
f0103bfd:	75 ed                	jne    f0103bec <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0103bff:	89 f0                	mov    %esi,%eax
f0103c01:	5b                   	pop    %ebx
f0103c02:	5e                   	pop    %esi
f0103c03:	5d                   	pop    %ebp
f0103c04:	c3                   	ret    

f0103c05 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0103c05:	55                   	push   %ebp
f0103c06:	89 e5                	mov    %esp,%ebp
f0103c08:	56                   	push   %esi
f0103c09:	53                   	push   %ebx
f0103c0a:	8b 75 08             	mov    0x8(%ebp),%esi
f0103c0d:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103c10:	8b 55 10             	mov    0x10(%ebp),%edx
f0103c13:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0103c15:	85 d2                	test   %edx,%edx
f0103c17:	74 21                	je     f0103c3a <strlcpy+0x35>
f0103c19:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0103c1d:	89 f2                	mov    %esi,%edx
f0103c1f:	eb 09                	jmp    f0103c2a <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0103c21:	83 c2 01             	add    $0x1,%edx
f0103c24:	83 c1 01             	add    $0x1,%ecx
f0103c27:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0103c2a:	39 c2                	cmp    %eax,%edx
f0103c2c:	74 09                	je     f0103c37 <strlcpy+0x32>
f0103c2e:	0f b6 19             	movzbl (%ecx),%ebx
f0103c31:	84 db                	test   %bl,%bl
f0103c33:	75 ec                	jne    f0103c21 <strlcpy+0x1c>
f0103c35:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f0103c37:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0103c3a:	29 f0                	sub    %esi,%eax
}
f0103c3c:	5b                   	pop    %ebx
f0103c3d:	5e                   	pop    %esi
f0103c3e:	5d                   	pop    %ebp
f0103c3f:	c3                   	ret    

f0103c40 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0103c40:	55                   	push   %ebp
f0103c41:	89 e5                	mov    %esp,%ebp
f0103c43:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103c46:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0103c49:	eb 06                	jmp    f0103c51 <strcmp+0x11>
		p++, q++;
f0103c4b:	83 c1 01             	add    $0x1,%ecx
f0103c4e:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0103c51:	0f b6 01             	movzbl (%ecx),%eax
f0103c54:	84 c0                	test   %al,%al
f0103c56:	74 04                	je     f0103c5c <strcmp+0x1c>
f0103c58:	3a 02                	cmp    (%edx),%al
f0103c5a:	74 ef                	je     f0103c4b <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0103c5c:	0f b6 c0             	movzbl %al,%eax
f0103c5f:	0f b6 12             	movzbl (%edx),%edx
f0103c62:	29 d0                	sub    %edx,%eax
}
f0103c64:	5d                   	pop    %ebp
f0103c65:	c3                   	ret    

f0103c66 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0103c66:	55                   	push   %ebp
f0103c67:	89 e5                	mov    %esp,%ebp
f0103c69:	53                   	push   %ebx
f0103c6a:	8b 45 08             	mov    0x8(%ebp),%eax
f0103c6d:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103c70:	89 c3                	mov    %eax,%ebx
f0103c72:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0103c75:	eb 06                	jmp    f0103c7d <strncmp+0x17>
		n--, p++, q++;
f0103c77:	83 c0 01             	add    $0x1,%eax
f0103c7a:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0103c7d:	39 d8                	cmp    %ebx,%eax
f0103c7f:	74 15                	je     f0103c96 <strncmp+0x30>
f0103c81:	0f b6 08             	movzbl (%eax),%ecx
f0103c84:	84 c9                	test   %cl,%cl
f0103c86:	74 04                	je     f0103c8c <strncmp+0x26>
f0103c88:	3a 0a                	cmp    (%edx),%cl
f0103c8a:	74 eb                	je     f0103c77 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0103c8c:	0f b6 00             	movzbl (%eax),%eax
f0103c8f:	0f b6 12             	movzbl (%edx),%edx
f0103c92:	29 d0                	sub    %edx,%eax
f0103c94:	eb 05                	jmp    f0103c9b <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0103c96:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0103c9b:	5b                   	pop    %ebx
f0103c9c:	5d                   	pop    %ebp
f0103c9d:	c3                   	ret    

f0103c9e <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0103c9e:	55                   	push   %ebp
f0103c9f:	89 e5                	mov    %esp,%ebp
f0103ca1:	8b 45 08             	mov    0x8(%ebp),%eax
f0103ca4:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103ca8:	eb 07                	jmp    f0103cb1 <strchr+0x13>
		if (*s == c)
f0103caa:	38 ca                	cmp    %cl,%dl
f0103cac:	74 0f                	je     f0103cbd <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0103cae:	83 c0 01             	add    $0x1,%eax
f0103cb1:	0f b6 10             	movzbl (%eax),%edx
f0103cb4:	84 d2                	test   %dl,%dl
f0103cb6:	75 f2                	jne    f0103caa <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0103cb8:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103cbd:	5d                   	pop    %ebp
f0103cbe:	c3                   	ret    

f0103cbf <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0103cbf:	55                   	push   %ebp
f0103cc0:	89 e5                	mov    %esp,%ebp
f0103cc2:	8b 45 08             	mov    0x8(%ebp),%eax
f0103cc5:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103cc9:	eb 03                	jmp    f0103cce <strfind+0xf>
f0103ccb:	83 c0 01             	add    $0x1,%eax
f0103cce:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0103cd1:	38 ca                	cmp    %cl,%dl
f0103cd3:	74 04                	je     f0103cd9 <strfind+0x1a>
f0103cd5:	84 d2                	test   %dl,%dl
f0103cd7:	75 f2                	jne    f0103ccb <strfind+0xc>
			break;
	return (char *) s;
}
f0103cd9:	5d                   	pop    %ebp
f0103cda:	c3                   	ret    

f0103cdb <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0103cdb:	55                   	push   %ebp
f0103cdc:	89 e5                	mov    %esp,%ebp
f0103cde:	57                   	push   %edi
f0103cdf:	56                   	push   %esi
f0103ce0:	53                   	push   %ebx
f0103ce1:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103ce4:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0103ce7:	85 c9                	test   %ecx,%ecx
f0103ce9:	74 36                	je     f0103d21 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0103ceb:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0103cf1:	75 28                	jne    f0103d1b <memset+0x40>
f0103cf3:	f6 c1 03             	test   $0x3,%cl
f0103cf6:	75 23                	jne    f0103d1b <memset+0x40>
		c &= 0xFF;
f0103cf8:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0103cfc:	89 d3                	mov    %edx,%ebx
f0103cfe:	c1 e3 08             	shl    $0x8,%ebx
f0103d01:	89 d6                	mov    %edx,%esi
f0103d03:	c1 e6 18             	shl    $0x18,%esi
f0103d06:	89 d0                	mov    %edx,%eax
f0103d08:	c1 e0 10             	shl    $0x10,%eax
f0103d0b:	09 f0                	or     %esi,%eax
f0103d0d:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f0103d0f:	89 d8                	mov    %ebx,%eax
f0103d11:	09 d0                	or     %edx,%eax
f0103d13:	c1 e9 02             	shr    $0x2,%ecx
f0103d16:	fc                   	cld    
f0103d17:	f3 ab                	rep stos %eax,%es:(%edi)
f0103d19:	eb 06                	jmp    f0103d21 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0103d1b:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103d1e:	fc                   	cld    
f0103d1f:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0103d21:	89 f8                	mov    %edi,%eax
f0103d23:	5b                   	pop    %ebx
f0103d24:	5e                   	pop    %esi
f0103d25:	5f                   	pop    %edi
f0103d26:	5d                   	pop    %ebp
f0103d27:	c3                   	ret    

f0103d28 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0103d28:	55                   	push   %ebp
f0103d29:	89 e5                	mov    %esp,%ebp
f0103d2b:	57                   	push   %edi
f0103d2c:	56                   	push   %esi
f0103d2d:	8b 45 08             	mov    0x8(%ebp),%eax
f0103d30:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103d33:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0103d36:	39 c6                	cmp    %eax,%esi
f0103d38:	73 35                	jae    f0103d6f <memmove+0x47>
f0103d3a:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0103d3d:	39 d0                	cmp    %edx,%eax
f0103d3f:	73 2e                	jae    f0103d6f <memmove+0x47>
		s += n;
		d += n;
f0103d41:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103d44:	89 d6                	mov    %edx,%esi
f0103d46:	09 fe                	or     %edi,%esi
f0103d48:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0103d4e:	75 13                	jne    f0103d63 <memmove+0x3b>
f0103d50:	f6 c1 03             	test   $0x3,%cl
f0103d53:	75 0e                	jne    f0103d63 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f0103d55:	83 ef 04             	sub    $0x4,%edi
f0103d58:	8d 72 fc             	lea    -0x4(%edx),%esi
f0103d5b:	c1 e9 02             	shr    $0x2,%ecx
f0103d5e:	fd                   	std    
f0103d5f:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103d61:	eb 09                	jmp    f0103d6c <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0103d63:	83 ef 01             	sub    $0x1,%edi
f0103d66:	8d 72 ff             	lea    -0x1(%edx),%esi
f0103d69:	fd                   	std    
f0103d6a:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0103d6c:	fc                   	cld    
f0103d6d:	eb 1d                	jmp    f0103d8c <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103d6f:	89 f2                	mov    %esi,%edx
f0103d71:	09 c2                	or     %eax,%edx
f0103d73:	f6 c2 03             	test   $0x3,%dl
f0103d76:	75 0f                	jne    f0103d87 <memmove+0x5f>
f0103d78:	f6 c1 03             	test   $0x3,%cl
f0103d7b:	75 0a                	jne    f0103d87 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f0103d7d:	c1 e9 02             	shr    $0x2,%ecx
f0103d80:	89 c7                	mov    %eax,%edi
f0103d82:	fc                   	cld    
f0103d83:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103d85:	eb 05                	jmp    f0103d8c <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0103d87:	89 c7                	mov    %eax,%edi
f0103d89:	fc                   	cld    
f0103d8a:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0103d8c:	5e                   	pop    %esi
f0103d8d:	5f                   	pop    %edi
f0103d8e:	5d                   	pop    %ebp
f0103d8f:	c3                   	ret    

f0103d90 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0103d90:	55                   	push   %ebp
f0103d91:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0103d93:	ff 75 10             	pushl  0x10(%ebp)
f0103d96:	ff 75 0c             	pushl  0xc(%ebp)
f0103d99:	ff 75 08             	pushl  0x8(%ebp)
f0103d9c:	e8 87 ff ff ff       	call   f0103d28 <memmove>
}
f0103da1:	c9                   	leave  
f0103da2:	c3                   	ret    

f0103da3 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0103da3:	55                   	push   %ebp
f0103da4:	89 e5                	mov    %esp,%ebp
f0103da6:	56                   	push   %esi
f0103da7:	53                   	push   %ebx
f0103da8:	8b 45 08             	mov    0x8(%ebp),%eax
f0103dab:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103dae:	89 c6                	mov    %eax,%esi
f0103db0:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103db3:	eb 1a                	jmp    f0103dcf <memcmp+0x2c>
		if (*s1 != *s2)
f0103db5:	0f b6 08             	movzbl (%eax),%ecx
f0103db8:	0f b6 1a             	movzbl (%edx),%ebx
f0103dbb:	38 d9                	cmp    %bl,%cl
f0103dbd:	74 0a                	je     f0103dc9 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0103dbf:	0f b6 c1             	movzbl %cl,%eax
f0103dc2:	0f b6 db             	movzbl %bl,%ebx
f0103dc5:	29 d8                	sub    %ebx,%eax
f0103dc7:	eb 0f                	jmp    f0103dd8 <memcmp+0x35>
		s1++, s2++;
f0103dc9:	83 c0 01             	add    $0x1,%eax
f0103dcc:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103dcf:	39 f0                	cmp    %esi,%eax
f0103dd1:	75 e2                	jne    f0103db5 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0103dd3:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103dd8:	5b                   	pop    %ebx
f0103dd9:	5e                   	pop    %esi
f0103dda:	5d                   	pop    %ebp
f0103ddb:	c3                   	ret    

f0103ddc <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0103ddc:	55                   	push   %ebp
f0103ddd:	89 e5                	mov    %esp,%ebp
f0103ddf:	53                   	push   %ebx
f0103de0:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0103de3:	89 c1                	mov    %eax,%ecx
f0103de5:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f0103de8:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0103dec:	eb 0a                	jmp    f0103df8 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f0103dee:	0f b6 10             	movzbl (%eax),%edx
f0103df1:	39 da                	cmp    %ebx,%edx
f0103df3:	74 07                	je     f0103dfc <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0103df5:	83 c0 01             	add    $0x1,%eax
f0103df8:	39 c8                	cmp    %ecx,%eax
f0103dfa:	72 f2                	jb     f0103dee <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0103dfc:	5b                   	pop    %ebx
f0103dfd:	5d                   	pop    %ebp
f0103dfe:	c3                   	ret    

f0103dff <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0103dff:	55                   	push   %ebp
f0103e00:	89 e5                	mov    %esp,%ebp
f0103e02:	57                   	push   %edi
f0103e03:	56                   	push   %esi
f0103e04:	53                   	push   %ebx
f0103e05:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103e08:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103e0b:	eb 03                	jmp    f0103e10 <strtol+0x11>
		s++;
f0103e0d:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103e10:	0f b6 01             	movzbl (%ecx),%eax
f0103e13:	3c 20                	cmp    $0x20,%al
f0103e15:	74 f6                	je     f0103e0d <strtol+0xe>
f0103e17:	3c 09                	cmp    $0x9,%al
f0103e19:	74 f2                	je     f0103e0d <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0103e1b:	3c 2b                	cmp    $0x2b,%al
f0103e1d:	75 0a                	jne    f0103e29 <strtol+0x2a>
		s++;
f0103e1f:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0103e22:	bf 00 00 00 00       	mov    $0x0,%edi
f0103e27:	eb 11                	jmp    f0103e3a <strtol+0x3b>
f0103e29:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0103e2e:	3c 2d                	cmp    $0x2d,%al
f0103e30:	75 08                	jne    f0103e3a <strtol+0x3b>
		s++, neg = 1;
f0103e32:	83 c1 01             	add    $0x1,%ecx
f0103e35:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0103e3a:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0103e40:	75 15                	jne    f0103e57 <strtol+0x58>
f0103e42:	80 39 30             	cmpb   $0x30,(%ecx)
f0103e45:	75 10                	jne    f0103e57 <strtol+0x58>
f0103e47:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0103e4b:	75 7c                	jne    f0103ec9 <strtol+0xca>
		s += 2, base = 16;
f0103e4d:	83 c1 02             	add    $0x2,%ecx
f0103e50:	bb 10 00 00 00       	mov    $0x10,%ebx
f0103e55:	eb 16                	jmp    f0103e6d <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f0103e57:	85 db                	test   %ebx,%ebx
f0103e59:	75 12                	jne    f0103e6d <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0103e5b:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0103e60:	80 39 30             	cmpb   $0x30,(%ecx)
f0103e63:	75 08                	jne    f0103e6d <strtol+0x6e>
		s++, base = 8;
f0103e65:	83 c1 01             	add    $0x1,%ecx
f0103e68:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f0103e6d:	b8 00 00 00 00       	mov    $0x0,%eax
f0103e72:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0103e75:	0f b6 11             	movzbl (%ecx),%edx
f0103e78:	8d 72 d0             	lea    -0x30(%edx),%esi
f0103e7b:	89 f3                	mov    %esi,%ebx
f0103e7d:	80 fb 09             	cmp    $0x9,%bl
f0103e80:	77 08                	ja     f0103e8a <strtol+0x8b>
			dig = *s - '0';
f0103e82:	0f be d2             	movsbl %dl,%edx
f0103e85:	83 ea 30             	sub    $0x30,%edx
f0103e88:	eb 22                	jmp    f0103eac <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f0103e8a:	8d 72 9f             	lea    -0x61(%edx),%esi
f0103e8d:	89 f3                	mov    %esi,%ebx
f0103e8f:	80 fb 19             	cmp    $0x19,%bl
f0103e92:	77 08                	ja     f0103e9c <strtol+0x9d>
			dig = *s - 'a' + 10;
f0103e94:	0f be d2             	movsbl %dl,%edx
f0103e97:	83 ea 57             	sub    $0x57,%edx
f0103e9a:	eb 10                	jmp    f0103eac <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f0103e9c:	8d 72 bf             	lea    -0x41(%edx),%esi
f0103e9f:	89 f3                	mov    %esi,%ebx
f0103ea1:	80 fb 19             	cmp    $0x19,%bl
f0103ea4:	77 16                	ja     f0103ebc <strtol+0xbd>
			dig = *s - 'A' + 10;
f0103ea6:	0f be d2             	movsbl %dl,%edx
f0103ea9:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f0103eac:	3b 55 10             	cmp    0x10(%ebp),%edx
f0103eaf:	7d 0b                	jge    f0103ebc <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f0103eb1:	83 c1 01             	add    $0x1,%ecx
f0103eb4:	0f af 45 10          	imul   0x10(%ebp),%eax
f0103eb8:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f0103eba:	eb b9                	jmp    f0103e75 <strtol+0x76>

	if (endptr)
f0103ebc:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0103ec0:	74 0d                	je     f0103ecf <strtol+0xd0>
		*endptr = (char *) s;
f0103ec2:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103ec5:	89 0e                	mov    %ecx,(%esi)
f0103ec7:	eb 06                	jmp    f0103ecf <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0103ec9:	85 db                	test   %ebx,%ebx
f0103ecb:	74 98                	je     f0103e65 <strtol+0x66>
f0103ecd:	eb 9e                	jmp    f0103e6d <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f0103ecf:	89 c2                	mov    %eax,%edx
f0103ed1:	f7 da                	neg    %edx
f0103ed3:	85 ff                	test   %edi,%edi
f0103ed5:	0f 45 c2             	cmovne %edx,%eax
}
f0103ed8:	5b                   	pop    %ebx
f0103ed9:	5e                   	pop    %esi
f0103eda:	5f                   	pop    %edi
f0103edb:	5d                   	pop    %ebp
f0103edc:	c3                   	ret    
f0103edd:	66 90                	xchg   %ax,%ax
f0103edf:	90                   	nop

f0103ee0 <__udivdi3>:
f0103ee0:	55                   	push   %ebp
f0103ee1:	57                   	push   %edi
f0103ee2:	56                   	push   %esi
f0103ee3:	53                   	push   %ebx
f0103ee4:	83 ec 1c             	sub    $0x1c,%esp
f0103ee7:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f0103eeb:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f0103eef:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0103ef3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0103ef7:	85 f6                	test   %esi,%esi
f0103ef9:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0103efd:	89 ca                	mov    %ecx,%edx
f0103eff:	89 f8                	mov    %edi,%eax
f0103f01:	75 3d                	jne    f0103f40 <__udivdi3+0x60>
f0103f03:	39 cf                	cmp    %ecx,%edi
f0103f05:	0f 87 c5 00 00 00    	ja     f0103fd0 <__udivdi3+0xf0>
f0103f0b:	85 ff                	test   %edi,%edi
f0103f0d:	89 fd                	mov    %edi,%ebp
f0103f0f:	75 0b                	jne    f0103f1c <__udivdi3+0x3c>
f0103f11:	b8 01 00 00 00       	mov    $0x1,%eax
f0103f16:	31 d2                	xor    %edx,%edx
f0103f18:	f7 f7                	div    %edi
f0103f1a:	89 c5                	mov    %eax,%ebp
f0103f1c:	89 c8                	mov    %ecx,%eax
f0103f1e:	31 d2                	xor    %edx,%edx
f0103f20:	f7 f5                	div    %ebp
f0103f22:	89 c1                	mov    %eax,%ecx
f0103f24:	89 d8                	mov    %ebx,%eax
f0103f26:	89 cf                	mov    %ecx,%edi
f0103f28:	f7 f5                	div    %ebp
f0103f2a:	89 c3                	mov    %eax,%ebx
f0103f2c:	89 d8                	mov    %ebx,%eax
f0103f2e:	89 fa                	mov    %edi,%edx
f0103f30:	83 c4 1c             	add    $0x1c,%esp
f0103f33:	5b                   	pop    %ebx
f0103f34:	5e                   	pop    %esi
f0103f35:	5f                   	pop    %edi
f0103f36:	5d                   	pop    %ebp
f0103f37:	c3                   	ret    
f0103f38:	90                   	nop
f0103f39:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103f40:	39 ce                	cmp    %ecx,%esi
f0103f42:	77 74                	ja     f0103fb8 <__udivdi3+0xd8>
f0103f44:	0f bd fe             	bsr    %esi,%edi
f0103f47:	83 f7 1f             	xor    $0x1f,%edi
f0103f4a:	0f 84 98 00 00 00    	je     f0103fe8 <__udivdi3+0x108>
f0103f50:	bb 20 00 00 00       	mov    $0x20,%ebx
f0103f55:	89 f9                	mov    %edi,%ecx
f0103f57:	89 c5                	mov    %eax,%ebp
f0103f59:	29 fb                	sub    %edi,%ebx
f0103f5b:	d3 e6                	shl    %cl,%esi
f0103f5d:	89 d9                	mov    %ebx,%ecx
f0103f5f:	d3 ed                	shr    %cl,%ebp
f0103f61:	89 f9                	mov    %edi,%ecx
f0103f63:	d3 e0                	shl    %cl,%eax
f0103f65:	09 ee                	or     %ebp,%esi
f0103f67:	89 d9                	mov    %ebx,%ecx
f0103f69:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103f6d:	89 d5                	mov    %edx,%ebp
f0103f6f:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103f73:	d3 ed                	shr    %cl,%ebp
f0103f75:	89 f9                	mov    %edi,%ecx
f0103f77:	d3 e2                	shl    %cl,%edx
f0103f79:	89 d9                	mov    %ebx,%ecx
f0103f7b:	d3 e8                	shr    %cl,%eax
f0103f7d:	09 c2                	or     %eax,%edx
f0103f7f:	89 d0                	mov    %edx,%eax
f0103f81:	89 ea                	mov    %ebp,%edx
f0103f83:	f7 f6                	div    %esi
f0103f85:	89 d5                	mov    %edx,%ebp
f0103f87:	89 c3                	mov    %eax,%ebx
f0103f89:	f7 64 24 0c          	mull   0xc(%esp)
f0103f8d:	39 d5                	cmp    %edx,%ebp
f0103f8f:	72 10                	jb     f0103fa1 <__udivdi3+0xc1>
f0103f91:	8b 74 24 08          	mov    0x8(%esp),%esi
f0103f95:	89 f9                	mov    %edi,%ecx
f0103f97:	d3 e6                	shl    %cl,%esi
f0103f99:	39 c6                	cmp    %eax,%esi
f0103f9b:	73 07                	jae    f0103fa4 <__udivdi3+0xc4>
f0103f9d:	39 d5                	cmp    %edx,%ebp
f0103f9f:	75 03                	jne    f0103fa4 <__udivdi3+0xc4>
f0103fa1:	83 eb 01             	sub    $0x1,%ebx
f0103fa4:	31 ff                	xor    %edi,%edi
f0103fa6:	89 d8                	mov    %ebx,%eax
f0103fa8:	89 fa                	mov    %edi,%edx
f0103faa:	83 c4 1c             	add    $0x1c,%esp
f0103fad:	5b                   	pop    %ebx
f0103fae:	5e                   	pop    %esi
f0103faf:	5f                   	pop    %edi
f0103fb0:	5d                   	pop    %ebp
f0103fb1:	c3                   	ret    
f0103fb2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103fb8:	31 ff                	xor    %edi,%edi
f0103fba:	31 db                	xor    %ebx,%ebx
f0103fbc:	89 d8                	mov    %ebx,%eax
f0103fbe:	89 fa                	mov    %edi,%edx
f0103fc0:	83 c4 1c             	add    $0x1c,%esp
f0103fc3:	5b                   	pop    %ebx
f0103fc4:	5e                   	pop    %esi
f0103fc5:	5f                   	pop    %edi
f0103fc6:	5d                   	pop    %ebp
f0103fc7:	c3                   	ret    
f0103fc8:	90                   	nop
f0103fc9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103fd0:	89 d8                	mov    %ebx,%eax
f0103fd2:	f7 f7                	div    %edi
f0103fd4:	31 ff                	xor    %edi,%edi
f0103fd6:	89 c3                	mov    %eax,%ebx
f0103fd8:	89 d8                	mov    %ebx,%eax
f0103fda:	89 fa                	mov    %edi,%edx
f0103fdc:	83 c4 1c             	add    $0x1c,%esp
f0103fdf:	5b                   	pop    %ebx
f0103fe0:	5e                   	pop    %esi
f0103fe1:	5f                   	pop    %edi
f0103fe2:	5d                   	pop    %ebp
f0103fe3:	c3                   	ret    
f0103fe4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103fe8:	39 ce                	cmp    %ecx,%esi
f0103fea:	72 0c                	jb     f0103ff8 <__udivdi3+0x118>
f0103fec:	31 db                	xor    %ebx,%ebx
f0103fee:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0103ff2:	0f 87 34 ff ff ff    	ja     f0103f2c <__udivdi3+0x4c>
f0103ff8:	bb 01 00 00 00       	mov    $0x1,%ebx
f0103ffd:	e9 2a ff ff ff       	jmp    f0103f2c <__udivdi3+0x4c>
f0104002:	66 90                	xchg   %ax,%ax
f0104004:	66 90                	xchg   %ax,%ax
f0104006:	66 90                	xchg   %ax,%ax
f0104008:	66 90                	xchg   %ax,%ax
f010400a:	66 90                	xchg   %ax,%ax
f010400c:	66 90                	xchg   %ax,%ax
f010400e:	66 90                	xchg   %ax,%ax

f0104010 <__umoddi3>:
f0104010:	55                   	push   %ebp
f0104011:	57                   	push   %edi
f0104012:	56                   	push   %esi
f0104013:	53                   	push   %ebx
f0104014:	83 ec 1c             	sub    $0x1c,%esp
f0104017:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010401b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f010401f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0104023:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0104027:	85 d2                	test   %edx,%edx
f0104029:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010402d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0104031:	89 f3                	mov    %esi,%ebx
f0104033:	89 3c 24             	mov    %edi,(%esp)
f0104036:	89 74 24 04          	mov    %esi,0x4(%esp)
f010403a:	75 1c                	jne    f0104058 <__umoddi3+0x48>
f010403c:	39 f7                	cmp    %esi,%edi
f010403e:	76 50                	jbe    f0104090 <__umoddi3+0x80>
f0104040:	89 c8                	mov    %ecx,%eax
f0104042:	89 f2                	mov    %esi,%edx
f0104044:	f7 f7                	div    %edi
f0104046:	89 d0                	mov    %edx,%eax
f0104048:	31 d2                	xor    %edx,%edx
f010404a:	83 c4 1c             	add    $0x1c,%esp
f010404d:	5b                   	pop    %ebx
f010404e:	5e                   	pop    %esi
f010404f:	5f                   	pop    %edi
f0104050:	5d                   	pop    %ebp
f0104051:	c3                   	ret    
f0104052:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0104058:	39 f2                	cmp    %esi,%edx
f010405a:	89 d0                	mov    %edx,%eax
f010405c:	77 52                	ja     f01040b0 <__umoddi3+0xa0>
f010405e:	0f bd ea             	bsr    %edx,%ebp
f0104061:	83 f5 1f             	xor    $0x1f,%ebp
f0104064:	75 5a                	jne    f01040c0 <__umoddi3+0xb0>
f0104066:	3b 54 24 04          	cmp    0x4(%esp),%edx
f010406a:	0f 82 e0 00 00 00    	jb     f0104150 <__umoddi3+0x140>
f0104070:	39 0c 24             	cmp    %ecx,(%esp)
f0104073:	0f 86 d7 00 00 00    	jbe    f0104150 <__umoddi3+0x140>
f0104079:	8b 44 24 08          	mov    0x8(%esp),%eax
f010407d:	8b 54 24 04          	mov    0x4(%esp),%edx
f0104081:	83 c4 1c             	add    $0x1c,%esp
f0104084:	5b                   	pop    %ebx
f0104085:	5e                   	pop    %esi
f0104086:	5f                   	pop    %edi
f0104087:	5d                   	pop    %ebp
f0104088:	c3                   	ret    
f0104089:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104090:	85 ff                	test   %edi,%edi
f0104092:	89 fd                	mov    %edi,%ebp
f0104094:	75 0b                	jne    f01040a1 <__umoddi3+0x91>
f0104096:	b8 01 00 00 00       	mov    $0x1,%eax
f010409b:	31 d2                	xor    %edx,%edx
f010409d:	f7 f7                	div    %edi
f010409f:	89 c5                	mov    %eax,%ebp
f01040a1:	89 f0                	mov    %esi,%eax
f01040a3:	31 d2                	xor    %edx,%edx
f01040a5:	f7 f5                	div    %ebp
f01040a7:	89 c8                	mov    %ecx,%eax
f01040a9:	f7 f5                	div    %ebp
f01040ab:	89 d0                	mov    %edx,%eax
f01040ad:	eb 99                	jmp    f0104048 <__umoddi3+0x38>
f01040af:	90                   	nop
f01040b0:	89 c8                	mov    %ecx,%eax
f01040b2:	89 f2                	mov    %esi,%edx
f01040b4:	83 c4 1c             	add    $0x1c,%esp
f01040b7:	5b                   	pop    %ebx
f01040b8:	5e                   	pop    %esi
f01040b9:	5f                   	pop    %edi
f01040ba:	5d                   	pop    %ebp
f01040bb:	c3                   	ret    
f01040bc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01040c0:	8b 34 24             	mov    (%esp),%esi
f01040c3:	bf 20 00 00 00       	mov    $0x20,%edi
f01040c8:	89 e9                	mov    %ebp,%ecx
f01040ca:	29 ef                	sub    %ebp,%edi
f01040cc:	d3 e0                	shl    %cl,%eax
f01040ce:	89 f9                	mov    %edi,%ecx
f01040d0:	89 f2                	mov    %esi,%edx
f01040d2:	d3 ea                	shr    %cl,%edx
f01040d4:	89 e9                	mov    %ebp,%ecx
f01040d6:	09 c2                	or     %eax,%edx
f01040d8:	89 d8                	mov    %ebx,%eax
f01040da:	89 14 24             	mov    %edx,(%esp)
f01040dd:	89 f2                	mov    %esi,%edx
f01040df:	d3 e2                	shl    %cl,%edx
f01040e1:	89 f9                	mov    %edi,%ecx
f01040e3:	89 54 24 04          	mov    %edx,0x4(%esp)
f01040e7:	8b 54 24 0c          	mov    0xc(%esp),%edx
f01040eb:	d3 e8                	shr    %cl,%eax
f01040ed:	89 e9                	mov    %ebp,%ecx
f01040ef:	89 c6                	mov    %eax,%esi
f01040f1:	d3 e3                	shl    %cl,%ebx
f01040f3:	89 f9                	mov    %edi,%ecx
f01040f5:	89 d0                	mov    %edx,%eax
f01040f7:	d3 e8                	shr    %cl,%eax
f01040f9:	89 e9                	mov    %ebp,%ecx
f01040fb:	09 d8                	or     %ebx,%eax
f01040fd:	89 d3                	mov    %edx,%ebx
f01040ff:	89 f2                	mov    %esi,%edx
f0104101:	f7 34 24             	divl   (%esp)
f0104104:	89 d6                	mov    %edx,%esi
f0104106:	d3 e3                	shl    %cl,%ebx
f0104108:	f7 64 24 04          	mull   0x4(%esp)
f010410c:	39 d6                	cmp    %edx,%esi
f010410e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0104112:	89 d1                	mov    %edx,%ecx
f0104114:	89 c3                	mov    %eax,%ebx
f0104116:	72 08                	jb     f0104120 <__umoddi3+0x110>
f0104118:	75 11                	jne    f010412b <__umoddi3+0x11b>
f010411a:	39 44 24 08          	cmp    %eax,0x8(%esp)
f010411e:	73 0b                	jae    f010412b <__umoddi3+0x11b>
f0104120:	2b 44 24 04          	sub    0x4(%esp),%eax
f0104124:	1b 14 24             	sbb    (%esp),%edx
f0104127:	89 d1                	mov    %edx,%ecx
f0104129:	89 c3                	mov    %eax,%ebx
f010412b:	8b 54 24 08          	mov    0x8(%esp),%edx
f010412f:	29 da                	sub    %ebx,%edx
f0104131:	19 ce                	sbb    %ecx,%esi
f0104133:	89 f9                	mov    %edi,%ecx
f0104135:	89 f0                	mov    %esi,%eax
f0104137:	d3 e0                	shl    %cl,%eax
f0104139:	89 e9                	mov    %ebp,%ecx
f010413b:	d3 ea                	shr    %cl,%edx
f010413d:	89 e9                	mov    %ebp,%ecx
f010413f:	d3 ee                	shr    %cl,%esi
f0104141:	09 d0                	or     %edx,%eax
f0104143:	89 f2                	mov    %esi,%edx
f0104145:	83 c4 1c             	add    $0x1c,%esp
f0104148:	5b                   	pop    %ebx
f0104149:	5e                   	pop    %esi
f010414a:	5f                   	pop    %edi
f010414b:	5d                   	pop    %ebp
f010414c:	c3                   	ret    
f010414d:	8d 76 00             	lea    0x0(%esi),%esi
f0104150:	29 f9                	sub    %edi,%ecx
f0104152:	19 d6                	sbb    %edx,%esi
f0104154:	89 74 24 04          	mov    %esi,0x4(%esp)
f0104158:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010415c:	e9 18 ff ff ff       	jmp    f0104079 <__umoddi3+0x69>
