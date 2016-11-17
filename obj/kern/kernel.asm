
obj/kern/kernel：     文件格式 elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
# bootloader to jump to the *physical* address of the entry point.
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4                   	.byte 0xe4

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# physical addresses [0, 4MB).  This 4MB region will be
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
f0100015:	b8 00 70 11 00       	mov    $0x117000,%eax
	movl	$(RELOC(entry_pgdir)), %eax
f010001a:	0f 22 d8             	mov    %eax,%cr3
	movl	%eax, %cr3
	# Turn on paging.
f010001d:	0f 20 c0             	mov    %cr0,%eax
	movl	%cr0, %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100025:	0f 22 c0             	mov    %eax,%cr0
	movl	%eax, %cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	mov	$relocated, %eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
	jmp	*%eax
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp
	movl	$0x0,%ebp			# nuke frame pointer

	# Set the stack pointer
f0100034:	bc 00 70 11 f0       	mov    $0xf0117000,%esp
	movl	$(bootstacktop),%esp

	# now to C code
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:
	call	i386_init

	# Should never get here, but in case we do, just spin.
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
f0100046:	b8 50 fc 16 f0       	mov    $0xf016fc50,%eax
f010004b:	2d 26 ed 16 f0       	sub    $0xf016ed26,%eax
f0100050:	50                   	push   %eax
f0100051:	6a 00                	push   $0x0
f0100053:	68 26 ed 16 f0       	push   $0xf016ed26
f0100058:	e8 c9 39 00 00       	call   f0103a26 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 ab 04 00 00       	call   f010050d <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 c0 3e 10 f0       	push   $0xf0103ec0
f010006f:	e8 2e 2b 00 00       	call   f0102ba2 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 10 10 00 00       	call   f0101089 <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f0100079:	e8 6e 27 00 00       	call   f01027ec <env_init>
	trap_init();
f010007e:	e8 90 2b 00 00       	call   f0102c13 <trap_init>
#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
#else
	// Touch all you want.
	ENV_CREATE(user_hello, ENV_TYPE_USER);
f0100083:	83 c4 08             	add    $0x8,%esp
f0100086:	6a 00                	push   $0x0
f0100088:	68 56 93 11 f0       	push   $0xf0119356
f010008d:	e8 7e 28 00 00       	call   f0102910 <env_create>
#endif // TEST*

	// We only have one user environment for now, so just run it.
	env_run(&envs[0]);
f0100092:	83 c4 04             	add    $0x4,%esp
f0100095:	ff 35 84 ef 16 f0    	pushl  0xf016ef84
f010009b:	e8 81 2a 00 00       	call   f0102b21 <env_run>

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
f01000a8:	83 3d 40 fc 16 f0 00 	cmpl   $0x0,0xf016fc40
f01000af:	75 37                	jne    f01000e8 <_panic+0x48>
		goto dead;
	panicstr = fmt;
f01000b1:	89 35 40 fc 16 f0    	mov    %esi,0xf016fc40

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
f01000c5:	68 db 3e 10 f0       	push   $0xf0103edb
f01000ca:	e8 d3 2a 00 00       	call   f0102ba2 <cprintf>
	vcprintf(fmt, ap);
f01000cf:	83 c4 08             	add    $0x8,%esp
f01000d2:	53                   	push   %ebx
f01000d3:	56                   	push   %esi
f01000d4:	e8 a3 2a 00 00       	call   f0102b7c <vcprintf>
	cprintf("\n");
f01000d9:	c7 04 24 2d 4e 10 f0 	movl   $0xf0104e2d,(%esp)
f01000e0:	e8 bd 2a 00 00       	call   f0102ba2 <cprintf>
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
f0100107:	68 f3 3e 10 f0       	push   $0xf0103ef3
f010010c:	e8 91 2a 00 00       	call   f0102ba2 <cprintf>
	vcprintf(fmt, ap);
f0100111:	83 c4 08             	add    $0x8,%esp
f0100114:	53                   	push   %ebx
f0100115:	ff 75 10             	pushl  0x10(%ebp)
f0100118:	e8 5f 2a 00 00       	call   f0102b7c <vcprintf>
	cprintf("\n");
f010011d:	c7 04 24 2d 4e 10 f0 	movl   $0xf0104e2d,(%esp)
f0100124:	e8 79 2a 00 00       	call   f0102ba2 <cprintf>
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
f010015f:	8b 0d 64 ef 16 f0    	mov    0xf016ef64,%ecx
f0100165:	8d 51 01             	lea    0x1(%ecx),%edx
f0100168:	89 15 64 ef 16 f0    	mov    %edx,0xf016ef64
f010016e:	88 81 60 ed 16 f0    	mov    %al,-0xfe912a0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f0100174:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010017a:	75 0a                	jne    f0100186 <cons_intr+0x36>
			cons.wpos = 0;
f010017c:	c7 05 64 ef 16 f0 00 	movl   $0x0,0xf016ef64
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
f01001b5:	83 0d 40 ed 16 f0 40 	orl    $0x40,0xf016ed40
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
f01001cd:	8b 0d 40 ed 16 f0    	mov    0xf016ed40,%ecx
f01001d3:	89 cb                	mov    %ecx,%ebx
f01001d5:	83 e3 40             	and    $0x40,%ebx
f01001d8:	83 e0 7f             	and    $0x7f,%eax
f01001db:	85 db                	test   %ebx,%ebx
f01001dd:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01001e0:	0f b6 d2             	movzbl %dl,%edx
f01001e3:	0f b6 82 60 40 10 f0 	movzbl -0xfefbfa0(%edx),%eax
f01001ea:	83 c8 40             	or     $0x40,%eax
f01001ed:	0f b6 c0             	movzbl %al,%eax
f01001f0:	f7 d0                	not    %eax
f01001f2:	21 c8                	and    %ecx,%eax
f01001f4:	a3 40 ed 16 f0       	mov    %eax,0xf016ed40
		return 0;
f01001f9:	b8 00 00 00 00       	mov    $0x0,%eax
f01001fe:	e9 a4 00 00 00       	jmp    f01002a7 <kbd_proc_data+0x114>
	} else if (shift & E0ESC) {
f0100203:	8b 0d 40 ed 16 f0    	mov    0xf016ed40,%ecx
f0100209:	f6 c1 40             	test   $0x40,%cl
f010020c:	74 0e                	je     f010021c <kbd_proc_data+0x89>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f010020e:	83 c8 80             	or     $0xffffff80,%eax
f0100211:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100213:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100216:	89 0d 40 ed 16 f0    	mov    %ecx,0xf016ed40
	}

	shift |= shiftcode[data];
f010021c:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f010021f:	0f b6 82 60 40 10 f0 	movzbl -0xfefbfa0(%edx),%eax
f0100226:	0b 05 40 ed 16 f0    	or     0xf016ed40,%eax
f010022c:	0f b6 8a 60 3f 10 f0 	movzbl -0xfefc0a0(%edx),%ecx
f0100233:	31 c8                	xor    %ecx,%eax
f0100235:	a3 40 ed 16 f0       	mov    %eax,0xf016ed40

	c = charcode[shift & (CTL | SHIFT)][data];
f010023a:	89 c1                	mov    %eax,%ecx
f010023c:	83 e1 03             	and    $0x3,%ecx
f010023f:	8b 0c 8d 40 3f 10 f0 	mov    -0xfefc0c0(,%ecx,4),%ecx
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
f010027d:	68 0d 3f 10 f0       	push   $0xf0103f0d
f0100282:	e8 1b 29 00 00       	call   f0102ba2 <cprintf>
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
f0100369:	0f b7 05 68 ef 16 f0 	movzwl 0xf016ef68,%eax
f0100370:	66 85 c0             	test   %ax,%ax
f0100373:	0f 84 e6 00 00 00    	je     f010045f <cons_putc+0x1b3>
			crt_pos--;
f0100379:	83 e8 01             	sub    $0x1,%eax
f010037c:	66 a3 68 ef 16 f0    	mov    %ax,0xf016ef68
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100382:	0f b7 c0             	movzwl %ax,%eax
f0100385:	66 81 e7 00 ff       	and    $0xff00,%di
f010038a:	83 cf 20             	or     $0x20,%edi
f010038d:	8b 15 6c ef 16 f0    	mov    0xf016ef6c,%edx
f0100393:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100397:	eb 78                	jmp    f0100411 <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100399:	66 83 05 68 ef 16 f0 	addw   $0x50,0xf016ef68
f01003a0:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01003a1:	0f b7 05 68 ef 16 f0 	movzwl 0xf016ef68,%eax
f01003a8:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003ae:	c1 e8 16             	shr    $0x16,%eax
f01003b1:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003b4:	c1 e0 04             	shl    $0x4,%eax
f01003b7:	66 a3 68 ef 16 f0    	mov    %ax,0xf016ef68
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
f01003f3:	0f b7 05 68 ef 16 f0 	movzwl 0xf016ef68,%eax
f01003fa:	8d 50 01             	lea    0x1(%eax),%edx
f01003fd:	66 89 15 68 ef 16 f0 	mov    %dx,0xf016ef68
f0100404:	0f b7 c0             	movzwl %ax,%eax
f0100407:	8b 15 6c ef 16 f0    	mov    0xf016ef6c,%edx
f010040d:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100411:	66 81 3d 68 ef 16 f0 	cmpw   $0x7cf,0xf016ef68
f0100418:	cf 07 
f010041a:	76 43                	jbe    f010045f <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010041c:	a1 6c ef 16 f0       	mov    0xf016ef6c,%eax
f0100421:	83 ec 04             	sub    $0x4,%esp
f0100424:	68 00 0f 00 00       	push   $0xf00
f0100429:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f010042f:	52                   	push   %edx
f0100430:	50                   	push   %eax
f0100431:	e8 3d 36 00 00       	call   f0103a73 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100436:	8b 15 6c ef 16 f0    	mov    0xf016ef6c,%edx
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
f0100457:	66 83 2d 68 ef 16 f0 	subw   $0x50,0xf016ef68
f010045e:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f010045f:	8b 0d 70 ef 16 f0    	mov    0xf016ef70,%ecx
f0100465:	b8 0e 00 00 00       	mov    $0xe,%eax
f010046a:	89 ca                	mov    %ecx,%edx
f010046c:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010046d:	0f b7 1d 68 ef 16 f0 	movzwl 0xf016ef68,%ebx
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
f0100495:	80 3d 74 ef 16 f0 00 	cmpb   $0x0,0xf016ef74
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
f01004d3:	a1 60 ef 16 f0       	mov    0xf016ef60,%eax
f01004d8:	3b 05 64 ef 16 f0    	cmp    0xf016ef64,%eax
f01004de:	74 26                	je     f0100506 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01004e0:	8d 50 01             	lea    0x1(%eax),%edx
f01004e3:	89 15 60 ef 16 f0    	mov    %edx,0xf016ef60
f01004e9:	0f b6 88 60 ed 16 f0 	movzbl -0xfe912a0(%eax),%ecx
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
f01004fa:	c7 05 60 ef 16 f0 00 	movl   $0x0,0xf016ef60
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
f0100533:	c7 05 70 ef 16 f0 b4 	movl   $0x3b4,0xf016ef70
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
f010054b:	c7 05 70 ef 16 f0 d4 	movl   $0x3d4,0xf016ef70
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
f010055a:	8b 3d 70 ef 16 f0    	mov    0xf016ef70,%edi
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
f010057f:	89 35 6c ef 16 f0    	mov    %esi,0xf016ef6c
	crt_pos = pos;
f0100585:	0f b6 c0             	movzbl %al,%eax
f0100588:	09 c8                	or     %ecx,%eax
f010058a:	66 a3 68 ef 16 f0    	mov    %ax,0xf016ef68
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
f01005eb:	0f 95 05 74 ef 16 f0 	setne  0xf016ef74
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
f0100600:	68 19 3f 10 f0       	push   $0xf0103f19
f0100605:	e8 98 25 00 00       	call   f0102ba2 <cprintf>
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
f0100646:	68 60 41 10 f0       	push   $0xf0104160
f010064b:	68 7e 41 10 f0       	push   $0xf010417e
f0100650:	68 83 41 10 f0       	push   $0xf0104183
f0100655:	e8 48 25 00 00       	call   f0102ba2 <cprintf>
f010065a:	83 c4 0c             	add    $0xc,%esp
f010065d:	68 0c 42 10 f0       	push   $0xf010420c
f0100662:	68 8c 41 10 f0       	push   $0xf010418c
f0100667:	68 83 41 10 f0       	push   $0xf0104183
f010066c:	e8 31 25 00 00       	call   f0102ba2 <cprintf>
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
f010067e:	68 95 41 10 f0       	push   $0xf0104195
f0100683:	e8 1a 25 00 00       	call   f0102ba2 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100688:	83 c4 08             	add    $0x8,%esp
f010068b:	68 0c 00 10 00       	push   $0x10000c
f0100690:	68 34 42 10 f0       	push   $0xf0104234
f0100695:	e8 08 25 00 00       	call   f0102ba2 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f010069a:	83 c4 0c             	add    $0xc,%esp
f010069d:	68 0c 00 10 00       	push   $0x10000c
f01006a2:	68 0c 00 10 f0       	push   $0xf010000c
f01006a7:	68 5c 42 10 f0       	push   $0xf010425c
f01006ac:	e8 f1 24 00 00       	call   f0102ba2 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006b1:	83 c4 0c             	add    $0xc,%esp
f01006b4:	68 b1 3e 10 00       	push   $0x103eb1
f01006b9:	68 b1 3e 10 f0       	push   $0xf0103eb1
f01006be:	68 80 42 10 f0       	push   $0xf0104280
f01006c3:	e8 da 24 00 00       	call   f0102ba2 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006c8:	83 c4 0c             	add    $0xc,%esp
f01006cb:	68 26 ed 16 00       	push   $0x16ed26
f01006d0:	68 26 ed 16 f0       	push   $0xf016ed26
f01006d5:	68 a4 42 10 f0       	push   $0xf01042a4
f01006da:	e8 c3 24 00 00       	call   f0102ba2 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006df:	83 c4 0c             	add    $0xc,%esp
f01006e2:	68 50 fc 16 00       	push   $0x16fc50
f01006e7:	68 50 fc 16 f0       	push   $0xf016fc50
f01006ec:	68 c8 42 10 f0       	push   $0xf01042c8
f01006f1:	e8 ac 24 00 00       	call   f0102ba2 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f01006f6:	b8 4f 00 17 f0       	mov    $0xf017004f,%eax
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
f0100717:	68 ec 42 10 f0       	push   $0xf01042ec
f010071c:	e8 81 24 00 00       	call   f0102ba2 <cprintf>
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
f0100732:	68 ae 41 10 f0       	push   $0xf01041ae
f0100737:	e8 66 24 00 00       	call   f0102ba2 <cprintf>
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
f0100757:	68 18 43 10 f0       	push   $0xf0104318
f010075c:	e8 41 24 00 00       	call   f0102ba2 <cprintf>
				*((uintptr_t *)ebp + 1), *((uintptr_t *)ebp + 2), *((uintptr_t *)ebp + 3), 
			    *((uintptr_t *)ebp + 4), *((uintptr_t *)ebp + 5), *((uintptr_t *)ebp + 6));
		debuginfo_eip(*((uintptr_t *)ebp + 1), &info);
f0100761:	83 c4 18             	add    $0x18,%esp
f0100764:	56                   	push   %esi
f0100765:	ff 73 04             	pushl  0x4(%ebx)
f0100768:	e8 e9 28 00 00       	call   f0103056 <debuginfo_eip>
		cprintf("%s:%d: %.*s+%d\n", info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, 
f010076d:	83 c4 08             	add    $0x8,%esp
f0100770:	8b 43 04             	mov    0x4(%ebx),%eax
f0100773:	2b 45 f0             	sub    -0x10(%ebp),%eax
f0100776:	50                   	push   %eax
f0100777:	ff 75 e8             	pushl  -0x18(%ebp)
f010077a:	ff 75 ec             	pushl  -0x14(%ebp)
f010077d:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100780:	ff 75 e0             	pushl  -0x20(%ebp)
f0100783:	68 c0 41 10 f0       	push   $0xf01041c0
f0100788:	e8 15 24 00 00       	call   f0102ba2 <cprintf>
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
f01007ab:	68 50 43 10 f0       	push   $0xf0104350
f01007b0:	e8 ed 23 00 00       	call   f0102ba2 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01007b5:	c7 04 24 74 43 10 f0 	movl   $0xf0104374,(%esp)
f01007bc:	e8 e1 23 00 00       	call   f0102ba2 <cprintf>

	if (tf != NULL)
f01007c1:	83 c4 10             	add    $0x10,%esp
f01007c4:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f01007c8:	74 0e                	je     f01007d8 <monitor+0x36>
		print_trapframe(tf);
f01007ca:	83 ec 0c             	sub    $0xc,%esp
f01007cd:	ff 75 08             	pushl  0x8(%ebp)
f01007d0:	e8 d6 24 00 00       	call   f0102cab <print_trapframe>
f01007d5:	83 c4 10             	add    $0x10,%esp

	while (1) {
		buf = readline("K> ");
f01007d8:	83 ec 0c             	sub    $0xc,%esp
f01007db:	68 d0 41 10 f0       	push   $0xf01041d0
f01007e0:	e8 ea 2f 00 00       	call   f01037cf <readline>
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
f0100814:	68 d4 41 10 f0       	push   $0xf01041d4
f0100819:	e8 cb 31 00 00       	call   f01039e9 <strchr>
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
f0100834:	68 d9 41 10 f0       	push   $0xf01041d9
f0100839:	e8 64 23 00 00       	call   f0102ba2 <cprintf>
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
f010085d:	68 d4 41 10 f0       	push   $0xf01041d4
f0100862:	e8 82 31 00 00       	call   f01039e9 <strchr>
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
f0100883:	68 7e 41 10 f0       	push   $0xf010417e
f0100888:	ff 75 a8             	pushl  -0x58(%ebp)
f010088b:	e8 fb 30 00 00       	call   f010398b <strcmp>
f0100890:	83 c4 10             	add    $0x10,%esp
f0100893:	85 c0                	test   %eax,%eax
f0100895:	74 1e                	je     f01008b5 <monitor+0x113>
f0100897:	83 ec 08             	sub    $0x8,%esp
f010089a:	68 8c 41 10 f0       	push   $0xf010418c
f010089f:	ff 75 a8             	pushl  -0x58(%ebp)
f01008a2:	e8 e4 30 00 00       	call   f010398b <strcmp>
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
f01008ca:	ff 14 85 a4 43 10 f0 	call   *-0xfefbc5c(,%eax,4)
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
f01008e3:	68 f6 41 10 f0       	push   $0xf01041f6
f01008e8:	e8 b5 22 00 00       	call   f0102ba2 <cprintf>
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
f0100908:	e8 2e 22 00 00       	call   f0102b3b <mc146818_read>
f010090d:	89 c6                	mov    %eax,%esi
f010090f:	83 c3 01             	add    $0x1,%ebx
f0100912:	89 1c 24             	mov    %ebx,(%esp)
f0100915:	e8 21 22 00 00       	call   f0102b3b <mc146818_read>
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
f010093c:	3b 0d 44 fc 16 f0    	cmp    0xf016fc44,%ecx
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
f010094b:	68 b4 43 10 f0       	push   $0xf01043b4
f0100950:	68 13 03 00 00       	push   $0x313
f0100955:	68 6d 4b 10 f0       	push   $0xf0104b6d
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
f010098c:	83 3d 78 ef 16 f0 00 	cmpl   $0x0,0xf016ef78
f0100993:	75 0f                	jne    f01009a4 <boot_alloc+0x1a>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100995:	b8 4f 0c 17 f0       	mov    $0xf0170c4f,%eax
f010099a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010099f:	a3 78 ef 16 f0       	mov    %eax,0xf016ef78
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	result = nextfree;
f01009a4:	a1 78 ef 16 f0       	mov    0xf016ef78,%eax
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
f01009bc:	68 d8 43 10 f0       	push   $0xf01043d8
f01009c1:	6a 6c                	push   $0x6c
f01009c3:	68 6d 4b 10 f0       	push   $0xf0104b6d
f01009c8:	e8 d3 f6 ff ff       	call   f01000a0 <_panic>
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	result = nextfree;
	if(n > 0){
		if (PADDR(nextfree) + n > (npages + 1) * PGSIZE) {
f01009cd:	8d 9c 10 00 00 00 10 	lea    0x10000000(%eax,%edx,1),%ebx
f01009d4:	8b 0d 44 fc 16 f0    	mov    0xf016fc44,%ecx
f01009da:	83 c1 01             	add    $0x1,%ecx
f01009dd:	c1 e1 0c             	shl    $0xc,%ecx
f01009e0:	39 cb                	cmp    %ecx,%ebx
f01009e2:	76 14                	jbe    f01009f8 <boot_alloc+0x6e>
			panic("out of memory\n");
f01009e4:	83 ec 04             	sub    $0x4,%esp
f01009e7:	68 79 4b 10 f0       	push   $0xf0104b79
f01009ec:	6a 6d                	push   $0x6d
f01009ee:	68 6d 4b 10 f0       	push   $0xf0104b6d
f01009f3:	e8 a8 f6 ff ff       	call   f01000a0 <_panic>
		}
		nextfree = ROUNDUP((char *)nextfree + n, PGSIZE);
f01009f8:	8d 94 10 ff 0f 00 00 	lea    0xfff(%eax,%edx,1),%edx
f01009ff:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100a05:	89 15 78 ef 16 f0    	mov    %edx,0xf016ef78
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
f0100a2a:	68 fc 43 10 f0       	push   $0xf01043fc
f0100a2f:	68 51 02 00 00       	push   $0x251
f0100a34:	68 6d 4b 10 f0       	push   $0xf0104b6d
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
f0100a4c:	2b 15 4c fc 16 f0    	sub    0xf016fc4c,%edx
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
f0100a82:	a3 7c ef 16 f0       	mov    %eax,0xf016ef7c
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
f0100a8c:	8b 1d 7c ef 16 f0    	mov    0xf016ef7c,%ebx
f0100a92:	eb 53                	jmp    f0100ae7 <check_page_free_list+0xd6>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100a94:	89 d8                	mov    %ebx,%eax
f0100a96:	2b 05 4c fc 16 f0    	sub    0xf016fc4c,%eax
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
f0100ab0:	3b 15 44 fc 16 f0    	cmp    0xf016fc44,%edx
f0100ab6:	72 12                	jb     f0100aca <check_page_free_list+0xb9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ab8:	50                   	push   %eax
f0100ab9:	68 b4 43 10 f0       	push   $0xf01043b4
f0100abe:	6a 56                	push   $0x56
f0100ac0:	68 88 4b 10 f0       	push   $0xf0104b88
f0100ac5:	e8 d6 f5 ff ff       	call   f01000a0 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100aca:	83 ec 04             	sub    $0x4,%esp
f0100acd:	68 80 00 00 00       	push   $0x80
f0100ad2:	68 97 00 00 00       	push   $0x97
f0100ad7:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100adc:	50                   	push   %eax
f0100add:	e8 44 2f 00 00       	call   f0103a26 <memset>
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
f0100af8:	8b 15 7c ef 16 f0    	mov    0xf016ef7c,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100afe:	8b 0d 4c fc 16 f0    	mov    0xf016fc4c,%ecx
		assert(pp < pages + npages);
f0100b04:	a1 44 fc 16 f0       	mov    0xf016fc44,%eax
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
f0100b23:	68 96 4b 10 f0       	push   $0xf0104b96
f0100b28:	68 a2 4b 10 f0       	push   $0xf0104ba2
f0100b2d:	68 6b 02 00 00       	push   $0x26b
f0100b32:	68 6d 4b 10 f0       	push   $0xf0104b6d
f0100b37:	e8 64 f5 ff ff       	call   f01000a0 <_panic>
		assert(pp < pages + npages);
f0100b3c:	39 fa                	cmp    %edi,%edx
f0100b3e:	72 19                	jb     f0100b59 <check_page_free_list+0x148>
f0100b40:	68 b7 4b 10 f0       	push   $0xf0104bb7
f0100b45:	68 a2 4b 10 f0       	push   $0xf0104ba2
f0100b4a:	68 6c 02 00 00       	push   $0x26c
f0100b4f:	68 6d 4b 10 f0       	push   $0xf0104b6d
f0100b54:	e8 47 f5 ff ff       	call   f01000a0 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100b59:	89 d0                	mov    %edx,%eax
f0100b5b:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100b5e:	a8 07                	test   $0x7,%al
f0100b60:	74 19                	je     f0100b7b <check_page_free_list+0x16a>
f0100b62:	68 20 44 10 f0       	push   $0xf0104420
f0100b67:	68 a2 4b 10 f0       	push   $0xf0104ba2
f0100b6c:	68 6d 02 00 00       	push   $0x26d
f0100b71:	68 6d 4b 10 f0       	push   $0xf0104b6d
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
f0100b85:	68 cb 4b 10 f0       	push   $0xf0104bcb
f0100b8a:	68 a2 4b 10 f0       	push   $0xf0104ba2
f0100b8f:	68 70 02 00 00       	push   $0x270
f0100b94:	68 6d 4b 10 f0       	push   $0xf0104b6d
f0100b99:	e8 02 f5 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100b9e:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100ba3:	75 19                	jne    f0100bbe <check_page_free_list+0x1ad>
f0100ba5:	68 dc 4b 10 f0       	push   $0xf0104bdc
f0100baa:	68 a2 4b 10 f0       	push   $0xf0104ba2
f0100baf:	68 71 02 00 00       	push   $0x271
f0100bb4:	68 6d 4b 10 f0       	push   $0xf0104b6d
f0100bb9:	e8 e2 f4 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100bbe:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100bc3:	75 19                	jne    f0100bde <check_page_free_list+0x1cd>
f0100bc5:	68 54 44 10 f0       	push   $0xf0104454
f0100bca:	68 a2 4b 10 f0       	push   $0xf0104ba2
f0100bcf:	68 72 02 00 00       	push   $0x272
f0100bd4:	68 6d 4b 10 f0       	push   $0xf0104b6d
f0100bd9:	e8 c2 f4 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100bde:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100be3:	75 19                	jne    f0100bfe <check_page_free_list+0x1ed>
f0100be5:	68 f5 4b 10 f0       	push   $0xf0104bf5
f0100bea:	68 a2 4b 10 f0       	push   $0xf0104ba2
f0100bef:	68 73 02 00 00       	push   $0x273
f0100bf4:	68 6d 4b 10 f0       	push   $0xf0104b6d
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
f0100c10:	68 b4 43 10 f0       	push   $0xf01043b4
f0100c15:	6a 56                	push   $0x56
f0100c17:	68 88 4b 10 f0       	push   $0xf0104b88
f0100c1c:	e8 7f f4 ff ff       	call   f01000a0 <_panic>
f0100c21:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100c26:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100c29:	76 1e                	jbe    f0100c49 <check_page_free_list+0x238>
f0100c2b:	68 78 44 10 f0       	push   $0xf0104478
f0100c30:	68 a2 4b 10 f0       	push   $0xf0104ba2
f0100c35:	68 74 02 00 00       	push   $0x274
f0100c3a:	68 6d 4b 10 f0       	push   $0xf0104b6d
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
f0100c5e:	68 0f 4c 10 f0       	push   $0xf0104c0f
f0100c63:	68 a2 4b 10 f0       	push   $0xf0104ba2
f0100c68:	68 7c 02 00 00       	push   $0x27c
f0100c6d:	68 6d 4b 10 f0       	push   $0xf0104b6d
f0100c72:	e8 29 f4 ff ff       	call   f01000a0 <_panic>
	assert(nfree_extmem > 0);
f0100c77:	85 db                	test   %ebx,%ebx
f0100c79:	7f 42                	jg     f0100cbd <check_page_free_list+0x2ac>
f0100c7b:	68 21 4c 10 f0       	push   $0xf0104c21
f0100c80:	68 a2 4b 10 f0       	push   $0xf0104ba2
f0100c85:	68 7d 02 00 00       	push   $0x27d
f0100c8a:	68 6d 4b 10 f0       	push   $0xf0104b6d
f0100c8f:	e8 0c f4 ff ff       	call   f01000a0 <_panic>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100c94:	a1 7c ef 16 f0       	mov    0xf016ef7c,%eax
f0100c99:	85 c0                	test   %eax,%eax
f0100c9b:	0f 85 9d fd ff ff    	jne    f0100a3e <check_page_free_list+0x2d>
f0100ca1:	e9 81 fd ff ff       	jmp    f0100a27 <check_page_free_list+0x16>
f0100ca6:	83 3d 7c ef 16 f0 00 	cmpl   $0x0,0xf016ef7c
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
f0100ccc:	8b 1d 7c ef 16 f0    	mov    0xf016ef7c,%ebx
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
f0100ce7:	03 0d 4c fc 16 f0    	add    0xf016fc4c,%ecx
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
f0100cfa:	03 1d 4c fc 16 f0    	add    0xf016fc4c,%ebx
f0100d00:	ba 01 00 00 00       	mov    $0x1,%edx
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	
	size_t i, io_page_i, ext_page_i, free_top;
	for (i = 0; i < npages; i++) {
f0100d05:	3b 05 44 fc 16 f0    	cmp    0xf016fc44,%eax
f0100d0b:	72 d1                	jb     f0100cde <page_init+0x19>
f0100d0d:	84 d2                	test   %dl,%dl
f0100d0f:	74 06                	je     f0100d17 <page_init+0x52>
f0100d11:	89 1d 7c ef 16 f0    	mov    %ebx,0xf016ef7c
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
  
	pages[0].pp_link = NULL;
f0100d17:	a1 4c fc 16 f0       	mov    0xf016fc4c,%eax
f0100d1c:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pages[1].pp_link = NULL;
f0100d22:	a1 4c fc 16 f0       	mov    0xf016fc4c,%eax
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
f0100d40:	68 d8 43 10 f0       	push   $0xf01043d8
f0100d45:	68 22 01 00 00       	push   $0x122
f0100d4a:	68 6d 4b 10 f0       	push   $0xf0104b6d
f0100d4f:	e8 4c f3 ff ff       	call   f01000a0 <_panic>
f0100d54:	8d 88 00 00 00 10    	lea    0x10000000(%eax),%ecx
f0100d5a:	c1 e9 0c             	shr    $0xc,%ecx

	pages[ext_page_i].pp_link = pages[io_page_i].pp_link;
f0100d5d:	a1 4c fc 16 f0       	mov    0xf016fc4c,%eax
f0100d62:	8b 90 00 05 00 00    	mov    0x500(%eax),%edx
f0100d68:	89 90 00 08 00 00    	mov    %edx,0x800(%eax)
f0100d6e:	b8 00 05 00 00       	mov    $0x500,%eax
	for(i = io_page_i;i < ext_page_i;i++)
		pages[i].pp_link = NULL;
f0100d73:	8b 15 4c fc 16 f0    	mov    0xf016fc4c,%edx
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
f0100d8a:	a1 4c fc 16 f0       	mov    0xf016fc4c,%eax
f0100d8f:	8b 90 00 08 00 00    	mov    0x800(%eax),%edx
f0100d95:	89 14 c8             	mov    %edx,(%eax,%ecx,8)
	for (i = ext_page_i; i < free_top; i++)
f0100d98:	b8 00 01 00 00       	mov    $0x100,%eax
f0100d9d:	eb 10                	jmp    f0100daf <page_init+0xea>
		pages[i].pp_link = NULL;
f0100d9f:	8b 15 4c fc 16 f0    	mov    0xf016fc4c,%edx
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
f0100dbf:	8b 1d 7c ef 16 f0    	mov    0xf016ef7c,%ebx
	if(p){
f0100dc5:	85 db                	test   %ebx,%ebx
f0100dc7:	74 5c                	je     f0100e25 <page_alloc+0x6d>
		page_free_list = p->pp_link;
f0100dc9:	8b 03                	mov    (%ebx),%eax
f0100dcb:	a3 7c ef 16 f0       	mov    %eax,0xf016ef7c
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
f0100dde:	2b 05 4c fc 16 f0    	sub    0xf016fc4c,%eax
f0100de4:	c1 f8 03             	sar    $0x3,%eax
f0100de7:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100dea:	89 c2                	mov    %eax,%edx
f0100dec:	c1 ea 0c             	shr    $0xc,%edx
f0100def:	3b 15 44 fc 16 f0    	cmp    0xf016fc44,%edx
f0100df5:	72 12                	jb     f0100e09 <page_alloc+0x51>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100df7:	50                   	push   %eax
f0100df8:	68 b4 43 10 f0       	push   $0xf01043b4
f0100dfd:	6a 56                	push   $0x56
f0100dff:	68 88 4b 10 f0       	push   $0xf0104b88
f0100e04:	e8 97 f2 ff ff       	call   f01000a0 <_panic>
			memset(page2kva(p), 0, PGSIZE);
f0100e09:	83 ec 04             	sub    $0x4,%esp
f0100e0c:	68 00 10 00 00       	push   $0x1000
f0100e11:	6a 00                	push   $0x0
f0100e13:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100e18:	50                   	push   %eax
f0100e19:	e8 08 2c 00 00       	call   f0103a26 <memset>
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
f0100e47:	68 c0 44 10 f0       	push   $0xf01044c0
f0100e4c:	68 55 01 00 00       	push   $0x155
f0100e51:	68 6d 4b 10 f0       	push   $0xf0104b6d
f0100e56:	e8 45 f2 ff ff       	call   f01000a0 <_panic>
	}
	pp->pp_link = page_free_list;
f0100e5b:	8b 15 7c ef 16 f0    	mov    0xf016ef7c,%edx
f0100e61:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f0100e63:	a3 7c ef 16 f0       	mov    %eax,0xf016ef7c


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
f0100ec2:	2b 15 4c fc 16 f0    	sub    0xf016fc4c,%edx
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
f0100ee4:	3b 15 44 fc 16 f0    	cmp    0xf016fc44,%edx
f0100eea:	72 15                	jb     f0100f01 <pgdir_walk+0x70>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100eec:	50                   	push   %eax
f0100eed:	68 b4 43 10 f0       	push   $0xf01043b4
f0100ef2:	68 8c 01 00 00       	push   $0x18c
f0100ef7:	68 6d 4b 10 f0       	push   $0xf0104b6d
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
f0100fb1:	3b 05 44 fc 16 f0    	cmp    0xf016fc44,%eax
f0100fb7:	72 14                	jb     f0100fcd <page_lookup+0x45>
		panic("pa2page called with invalid pa");
f0100fb9:	83 ec 04             	sub    $0x4,%esp
f0100fbc:	68 f4 44 10 f0       	push   $0xf01044f4
f0100fc1:	6a 4f                	push   $0x4f
f0100fc3:	68 88 4b 10 f0       	push   $0xf0104b88
f0100fc8:	e8 d3 f0 ff ff       	call   f01000a0 <_panic>
	return &pages[PGNUM(pa)];
f0100fcd:	8b 15 4c fc 16 f0    	mov    0xf016fc4c,%edx
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
f010105c:	2b 1d 4c fc 16 f0    	sub    0xf016fc4c,%ebx
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
f01010d2:	89 15 44 fc 16 f0    	mov    %edx,0xf016fc44
	npages_basemem = basemem / (PGSIZE / 1024);

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01010d8:	89 c2                	mov    %eax,%edx
f01010da:	29 da                	sub    %ebx,%edx
f01010dc:	52                   	push   %edx
f01010dd:	53                   	push   %ebx
f01010de:	50                   	push   %eax
f01010df:	68 14 45 10 f0       	push   $0xf0104514
f01010e4:	e8 b9 1a 00 00       	call   f0102ba2 <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f01010e9:	b8 00 10 00 00       	mov    $0x1000,%eax
f01010ee:	e8 97 f8 ff ff       	call   f010098a <boot_alloc>
f01010f3:	a3 48 fc 16 f0       	mov    %eax,0xf016fc48
	memset(kern_pgdir, 0, PGSIZE);
f01010f8:	83 c4 0c             	add    $0xc,%esp
f01010fb:	68 00 10 00 00       	push   $0x1000
f0101100:	6a 00                	push   $0x0
f0101102:	50                   	push   %eax
f0101103:	e8 1e 29 00 00       	call   f0103a26 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0101108:	a1 48 fc 16 f0       	mov    0xf016fc48,%eax
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
f0101118:	68 d8 43 10 f0       	push   $0xf01043d8
f010111d:	68 94 00 00 00       	push   $0x94
f0101122:	68 6d 4b 10 f0       	push   $0xf0104b6d
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
f010113b:	a1 44 fc 16 f0       	mov    0xf016fc44,%eax
f0101140:	c1 e0 03             	shl    $0x3,%eax
f0101143:	e8 42 f8 ff ff       	call   f010098a <boot_alloc>
f0101148:	a3 4c fc 16 f0       	mov    %eax,0xf016fc4c
	memset(pages, 0, npages * sizeof(struct PageInfo));
f010114d:	83 ec 04             	sub    $0x4,%esp
f0101150:	8b 3d 44 fc 16 f0    	mov    0xf016fc44,%edi
f0101156:	8d 14 fd 00 00 00 00 	lea    0x0(,%edi,8),%edx
f010115d:	52                   	push   %edx
f010115e:	6a 00                	push   $0x0
f0101160:	50                   	push   %eax
f0101161:	e8 c0 28 00 00       	call   f0103a26 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f0101166:	e8 5a fb ff ff       	call   f0100cc5 <page_init>

	check_page_free_list(1);
f010116b:	b8 01 00 00 00       	mov    $0x1,%eax
f0101170:	e8 9c f8 ff ff       	call   f0100a11 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f0101175:	83 c4 10             	add    $0x10,%esp
f0101178:	83 3d 4c fc 16 f0 00 	cmpl   $0x0,0xf016fc4c
f010117f:	75 17                	jne    f0101198 <mem_init+0x10f>
		panic("'pages' is a null pointer!");
f0101181:	83 ec 04             	sub    $0x4,%esp
f0101184:	68 32 4c 10 f0       	push   $0xf0104c32
f0101189:	68 8e 02 00 00       	push   $0x28e
f010118e:	68 6d 4b 10 f0       	push   $0xf0104b6d
f0101193:	e8 08 ef ff ff       	call   f01000a0 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101198:	a1 7c ef 16 f0       	mov    0xf016ef7c,%eax
f010119d:	bb 00 00 00 00       	mov    $0x0,%ebx
f01011a2:	eb 05                	jmp    f01011a9 <mem_init+0x120>
		++nfree;
f01011a4:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01011a7:	8b 00                	mov    (%eax),%eax
f01011a9:	85 c0                	test   %eax,%eax
f01011ab:	75 f7                	jne    f01011a4 <mem_init+0x11b>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01011ad:	83 ec 0c             	sub    $0xc,%esp
f01011b0:	6a 00                	push   $0x0
f01011b2:	e8 01 fc ff ff       	call   f0100db8 <page_alloc>
f01011b7:	89 c7                	mov    %eax,%edi
f01011b9:	83 c4 10             	add    $0x10,%esp
f01011bc:	85 c0                	test   %eax,%eax
f01011be:	75 19                	jne    f01011d9 <mem_init+0x150>
f01011c0:	68 4d 4c 10 f0       	push   $0xf0104c4d
f01011c5:	68 a2 4b 10 f0       	push   $0xf0104ba2
f01011ca:	68 96 02 00 00       	push   $0x296
f01011cf:	68 6d 4b 10 f0       	push   $0xf0104b6d
f01011d4:	e8 c7 ee ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f01011d9:	83 ec 0c             	sub    $0xc,%esp
f01011dc:	6a 00                	push   $0x0
f01011de:	e8 d5 fb ff ff       	call   f0100db8 <page_alloc>
f01011e3:	89 c6                	mov    %eax,%esi
f01011e5:	83 c4 10             	add    $0x10,%esp
f01011e8:	85 c0                	test   %eax,%eax
f01011ea:	75 19                	jne    f0101205 <mem_init+0x17c>
f01011ec:	68 63 4c 10 f0       	push   $0xf0104c63
f01011f1:	68 a2 4b 10 f0       	push   $0xf0104ba2
f01011f6:	68 97 02 00 00       	push   $0x297
f01011fb:	68 6d 4b 10 f0       	push   $0xf0104b6d
f0101200:	e8 9b ee ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f0101205:	83 ec 0c             	sub    $0xc,%esp
f0101208:	6a 00                	push   $0x0
f010120a:	e8 a9 fb ff ff       	call   f0100db8 <page_alloc>
f010120f:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101212:	83 c4 10             	add    $0x10,%esp
f0101215:	85 c0                	test   %eax,%eax
f0101217:	75 19                	jne    f0101232 <mem_init+0x1a9>
f0101219:	68 79 4c 10 f0       	push   $0xf0104c79
f010121e:	68 a2 4b 10 f0       	push   $0xf0104ba2
f0101223:	68 98 02 00 00       	push   $0x298
f0101228:	68 6d 4b 10 f0       	push   $0xf0104b6d
f010122d:	e8 6e ee ff ff       	call   f01000a0 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101232:	39 f7                	cmp    %esi,%edi
f0101234:	75 19                	jne    f010124f <mem_init+0x1c6>
f0101236:	68 8f 4c 10 f0       	push   $0xf0104c8f
f010123b:	68 a2 4b 10 f0       	push   $0xf0104ba2
f0101240:	68 9b 02 00 00       	push   $0x29b
f0101245:	68 6d 4b 10 f0       	push   $0xf0104b6d
f010124a:	e8 51 ee ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010124f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101252:	39 c6                	cmp    %eax,%esi
f0101254:	74 04                	je     f010125a <mem_init+0x1d1>
f0101256:	39 c7                	cmp    %eax,%edi
f0101258:	75 19                	jne    f0101273 <mem_init+0x1ea>
f010125a:	68 50 45 10 f0       	push   $0xf0104550
f010125f:	68 a2 4b 10 f0       	push   $0xf0104ba2
f0101264:	68 9c 02 00 00       	push   $0x29c
f0101269:	68 6d 4b 10 f0       	push   $0xf0104b6d
f010126e:	e8 2d ee ff ff       	call   f01000a0 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101273:	8b 0d 4c fc 16 f0    	mov    0xf016fc4c,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101279:	8b 15 44 fc 16 f0    	mov    0xf016fc44,%edx
f010127f:	c1 e2 0c             	shl    $0xc,%edx
f0101282:	89 f8                	mov    %edi,%eax
f0101284:	29 c8                	sub    %ecx,%eax
f0101286:	c1 f8 03             	sar    $0x3,%eax
f0101289:	c1 e0 0c             	shl    $0xc,%eax
f010128c:	39 d0                	cmp    %edx,%eax
f010128e:	72 19                	jb     f01012a9 <mem_init+0x220>
f0101290:	68 a1 4c 10 f0       	push   $0xf0104ca1
f0101295:	68 a2 4b 10 f0       	push   $0xf0104ba2
f010129a:	68 9d 02 00 00       	push   $0x29d
f010129f:	68 6d 4b 10 f0       	push   $0xf0104b6d
f01012a4:	e8 f7 ed ff ff       	call   f01000a0 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f01012a9:	89 f0                	mov    %esi,%eax
f01012ab:	29 c8                	sub    %ecx,%eax
f01012ad:	c1 f8 03             	sar    $0x3,%eax
f01012b0:	c1 e0 0c             	shl    $0xc,%eax
f01012b3:	39 c2                	cmp    %eax,%edx
f01012b5:	77 19                	ja     f01012d0 <mem_init+0x247>
f01012b7:	68 be 4c 10 f0       	push   $0xf0104cbe
f01012bc:	68 a2 4b 10 f0       	push   $0xf0104ba2
f01012c1:	68 9e 02 00 00       	push   $0x29e
f01012c6:	68 6d 4b 10 f0       	push   $0xf0104b6d
f01012cb:	e8 d0 ed ff ff       	call   f01000a0 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f01012d0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01012d3:	29 c8                	sub    %ecx,%eax
f01012d5:	c1 f8 03             	sar    $0x3,%eax
f01012d8:	c1 e0 0c             	shl    $0xc,%eax
f01012db:	39 c2                	cmp    %eax,%edx
f01012dd:	77 19                	ja     f01012f8 <mem_init+0x26f>
f01012df:	68 db 4c 10 f0       	push   $0xf0104cdb
f01012e4:	68 a2 4b 10 f0       	push   $0xf0104ba2
f01012e9:	68 9f 02 00 00       	push   $0x29f
f01012ee:	68 6d 4b 10 f0       	push   $0xf0104b6d
f01012f3:	e8 a8 ed ff ff       	call   f01000a0 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01012f8:	a1 7c ef 16 f0       	mov    0xf016ef7c,%eax
f01012fd:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101300:	c7 05 7c ef 16 f0 00 	movl   $0x0,0xf016ef7c
f0101307:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f010130a:	83 ec 0c             	sub    $0xc,%esp
f010130d:	6a 00                	push   $0x0
f010130f:	e8 a4 fa ff ff       	call   f0100db8 <page_alloc>
f0101314:	83 c4 10             	add    $0x10,%esp
f0101317:	85 c0                	test   %eax,%eax
f0101319:	74 19                	je     f0101334 <mem_init+0x2ab>
f010131b:	68 f8 4c 10 f0       	push   $0xf0104cf8
f0101320:	68 a2 4b 10 f0       	push   $0xf0104ba2
f0101325:	68 a6 02 00 00       	push   $0x2a6
f010132a:	68 6d 4b 10 f0       	push   $0xf0104b6d
f010132f:	e8 6c ed ff ff       	call   f01000a0 <_panic>

	// free and re-allocate?
	page_free(pp0);
f0101334:	83 ec 0c             	sub    $0xc,%esp
f0101337:	57                   	push   %edi
f0101338:	e8 f2 fa ff ff       	call   f0100e2f <page_free>
	page_free(pp1);
f010133d:	89 34 24             	mov    %esi,(%esp)
f0101340:	e8 ea fa ff ff       	call   f0100e2f <page_free>
	page_free(pp2);
f0101345:	83 c4 04             	add    $0x4,%esp
f0101348:	ff 75 d4             	pushl  -0x2c(%ebp)
f010134b:	e8 df fa ff ff       	call   f0100e2f <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101350:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101357:	e8 5c fa ff ff       	call   f0100db8 <page_alloc>
f010135c:	89 c6                	mov    %eax,%esi
f010135e:	83 c4 10             	add    $0x10,%esp
f0101361:	85 c0                	test   %eax,%eax
f0101363:	75 19                	jne    f010137e <mem_init+0x2f5>
f0101365:	68 4d 4c 10 f0       	push   $0xf0104c4d
f010136a:	68 a2 4b 10 f0       	push   $0xf0104ba2
f010136f:	68 ad 02 00 00       	push   $0x2ad
f0101374:	68 6d 4b 10 f0       	push   $0xf0104b6d
f0101379:	e8 22 ed ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f010137e:	83 ec 0c             	sub    $0xc,%esp
f0101381:	6a 00                	push   $0x0
f0101383:	e8 30 fa ff ff       	call   f0100db8 <page_alloc>
f0101388:	89 c7                	mov    %eax,%edi
f010138a:	83 c4 10             	add    $0x10,%esp
f010138d:	85 c0                	test   %eax,%eax
f010138f:	75 19                	jne    f01013aa <mem_init+0x321>
f0101391:	68 63 4c 10 f0       	push   $0xf0104c63
f0101396:	68 a2 4b 10 f0       	push   $0xf0104ba2
f010139b:	68 ae 02 00 00       	push   $0x2ae
f01013a0:	68 6d 4b 10 f0       	push   $0xf0104b6d
f01013a5:	e8 f6 ec ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f01013aa:	83 ec 0c             	sub    $0xc,%esp
f01013ad:	6a 00                	push   $0x0
f01013af:	e8 04 fa ff ff       	call   f0100db8 <page_alloc>
f01013b4:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01013b7:	83 c4 10             	add    $0x10,%esp
f01013ba:	85 c0                	test   %eax,%eax
f01013bc:	75 19                	jne    f01013d7 <mem_init+0x34e>
f01013be:	68 79 4c 10 f0       	push   $0xf0104c79
f01013c3:	68 a2 4b 10 f0       	push   $0xf0104ba2
f01013c8:	68 af 02 00 00       	push   $0x2af
f01013cd:	68 6d 4b 10 f0       	push   $0xf0104b6d
f01013d2:	e8 c9 ec ff ff       	call   f01000a0 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01013d7:	39 fe                	cmp    %edi,%esi
f01013d9:	75 19                	jne    f01013f4 <mem_init+0x36b>
f01013db:	68 8f 4c 10 f0       	push   $0xf0104c8f
f01013e0:	68 a2 4b 10 f0       	push   $0xf0104ba2
f01013e5:	68 b1 02 00 00       	push   $0x2b1
f01013ea:	68 6d 4b 10 f0       	push   $0xf0104b6d
f01013ef:	e8 ac ec ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01013f4:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01013f7:	39 c7                	cmp    %eax,%edi
f01013f9:	74 04                	je     f01013ff <mem_init+0x376>
f01013fb:	39 c6                	cmp    %eax,%esi
f01013fd:	75 19                	jne    f0101418 <mem_init+0x38f>
f01013ff:	68 50 45 10 f0       	push   $0xf0104550
f0101404:	68 a2 4b 10 f0       	push   $0xf0104ba2
f0101409:	68 b2 02 00 00       	push   $0x2b2
f010140e:	68 6d 4b 10 f0       	push   $0xf0104b6d
f0101413:	e8 88 ec ff ff       	call   f01000a0 <_panic>
	assert(!page_alloc(0));
f0101418:	83 ec 0c             	sub    $0xc,%esp
f010141b:	6a 00                	push   $0x0
f010141d:	e8 96 f9 ff ff       	call   f0100db8 <page_alloc>
f0101422:	83 c4 10             	add    $0x10,%esp
f0101425:	85 c0                	test   %eax,%eax
f0101427:	74 19                	je     f0101442 <mem_init+0x3b9>
f0101429:	68 f8 4c 10 f0       	push   $0xf0104cf8
f010142e:	68 a2 4b 10 f0       	push   $0xf0104ba2
f0101433:	68 b3 02 00 00       	push   $0x2b3
f0101438:	68 6d 4b 10 f0       	push   $0xf0104b6d
f010143d:	e8 5e ec ff ff       	call   f01000a0 <_panic>
f0101442:	89 f0                	mov    %esi,%eax
f0101444:	2b 05 4c fc 16 f0    	sub    0xf016fc4c,%eax
f010144a:	c1 f8 03             	sar    $0x3,%eax
f010144d:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101450:	89 c2                	mov    %eax,%edx
f0101452:	c1 ea 0c             	shr    $0xc,%edx
f0101455:	3b 15 44 fc 16 f0    	cmp    0xf016fc44,%edx
f010145b:	72 12                	jb     f010146f <mem_init+0x3e6>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010145d:	50                   	push   %eax
f010145e:	68 b4 43 10 f0       	push   $0xf01043b4
f0101463:	6a 56                	push   $0x56
f0101465:	68 88 4b 10 f0       	push   $0xf0104b88
f010146a:	e8 31 ec ff ff       	call   f01000a0 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f010146f:	83 ec 04             	sub    $0x4,%esp
f0101472:	68 00 10 00 00       	push   $0x1000
f0101477:	6a 01                	push   $0x1
f0101479:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010147e:	50                   	push   %eax
f010147f:	e8 a2 25 00 00       	call   f0103a26 <memset>
	page_free(pp0);
f0101484:	89 34 24             	mov    %esi,(%esp)
f0101487:	e8 a3 f9 ff ff       	call   f0100e2f <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f010148c:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101493:	e8 20 f9 ff ff       	call   f0100db8 <page_alloc>
f0101498:	83 c4 10             	add    $0x10,%esp
f010149b:	85 c0                	test   %eax,%eax
f010149d:	75 19                	jne    f01014b8 <mem_init+0x42f>
f010149f:	68 07 4d 10 f0       	push   $0xf0104d07
f01014a4:	68 a2 4b 10 f0       	push   $0xf0104ba2
f01014a9:	68 b8 02 00 00       	push   $0x2b8
f01014ae:	68 6d 4b 10 f0       	push   $0xf0104b6d
f01014b3:	e8 e8 eb ff ff       	call   f01000a0 <_panic>
	assert(pp && pp0 == pp);
f01014b8:	39 c6                	cmp    %eax,%esi
f01014ba:	74 19                	je     f01014d5 <mem_init+0x44c>
f01014bc:	68 25 4d 10 f0       	push   $0xf0104d25
f01014c1:	68 a2 4b 10 f0       	push   $0xf0104ba2
f01014c6:	68 b9 02 00 00       	push   $0x2b9
f01014cb:	68 6d 4b 10 f0       	push   $0xf0104b6d
f01014d0:	e8 cb eb ff ff       	call   f01000a0 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01014d5:	89 f0                	mov    %esi,%eax
f01014d7:	2b 05 4c fc 16 f0    	sub    0xf016fc4c,%eax
f01014dd:	c1 f8 03             	sar    $0x3,%eax
f01014e0:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01014e3:	89 c2                	mov    %eax,%edx
f01014e5:	c1 ea 0c             	shr    $0xc,%edx
f01014e8:	3b 15 44 fc 16 f0    	cmp    0xf016fc44,%edx
f01014ee:	72 12                	jb     f0101502 <mem_init+0x479>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01014f0:	50                   	push   %eax
f01014f1:	68 b4 43 10 f0       	push   $0xf01043b4
f01014f6:	6a 56                	push   $0x56
f01014f8:	68 88 4b 10 f0       	push   $0xf0104b88
f01014fd:	e8 9e eb ff ff       	call   f01000a0 <_panic>
f0101502:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f0101508:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f010150e:	80 38 00             	cmpb   $0x0,(%eax)
f0101511:	74 19                	je     f010152c <mem_init+0x4a3>
f0101513:	68 35 4d 10 f0       	push   $0xf0104d35
f0101518:	68 a2 4b 10 f0       	push   $0xf0104ba2
f010151d:	68 bc 02 00 00       	push   $0x2bc
f0101522:	68 6d 4b 10 f0       	push   $0xf0104b6d
f0101527:	e8 74 eb ff ff       	call   f01000a0 <_panic>
f010152c:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f010152f:	39 d0                	cmp    %edx,%eax
f0101531:	75 db                	jne    f010150e <mem_init+0x485>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101533:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101536:	a3 7c ef 16 f0       	mov    %eax,0xf016ef7c

	// free the pages we took
	page_free(pp0);
f010153b:	83 ec 0c             	sub    $0xc,%esp
f010153e:	56                   	push   %esi
f010153f:	e8 eb f8 ff ff       	call   f0100e2f <page_free>
	page_free(pp1);
f0101544:	89 3c 24             	mov    %edi,(%esp)
f0101547:	e8 e3 f8 ff ff       	call   f0100e2f <page_free>
	page_free(pp2);
f010154c:	83 c4 04             	add    $0x4,%esp
f010154f:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101552:	e8 d8 f8 ff ff       	call   f0100e2f <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101557:	a1 7c ef 16 f0       	mov    0xf016ef7c,%eax
f010155c:	83 c4 10             	add    $0x10,%esp
f010155f:	eb 05                	jmp    f0101566 <mem_init+0x4dd>
		--nfree;
f0101561:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101564:	8b 00                	mov    (%eax),%eax
f0101566:	85 c0                	test   %eax,%eax
f0101568:	75 f7                	jne    f0101561 <mem_init+0x4d8>
		--nfree;
	assert(nfree == 0);
f010156a:	85 db                	test   %ebx,%ebx
f010156c:	74 19                	je     f0101587 <mem_init+0x4fe>
f010156e:	68 3f 4d 10 f0       	push   $0xf0104d3f
f0101573:	68 a2 4b 10 f0       	push   $0xf0104ba2
f0101578:	68 c9 02 00 00       	push   $0x2c9
f010157d:	68 6d 4b 10 f0       	push   $0xf0104b6d
f0101582:	e8 19 eb ff ff       	call   f01000a0 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f0101587:	83 ec 0c             	sub    $0xc,%esp
f010158a:	68 70 45 10 f0       	push   $0xf0104570
f010158f:	e8 0e 16 00 00       	call   f0102ba2 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101594:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010159b:	e8 18 f8 ff ff       	call   f0100db8 <page_alloc>
f01015a0:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01015a3:	83 c4 10             	add    $0x10,%esp
f01015a6:	85 c0                	test   %eax,%eax
f01015a8:	75 19                	jne    f01015c3 <mem_init+0x53a>
f01015aa:	68 4d 4c 10 f0       	push   $0xf0104c4d
f01015af:	68 a2 4b 10 f0       	push   $0xf0104ba2
f01015b4:	68 27 03 00 00       	push   $0x327
f01015b9:	68 6d 4b 10 f0       	push   $0xf0104b6d
f01015be:	e8 dd ea ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f01015c3:	83 ec 0c             	sub    $0xc,%esp
f01015c6:	6a 00                	push   $0x0
f01015c8:	e8 eb f7 ff ff       	call   f0100db8 <page_alloc>
f01015cd:	89 c3                	mov    %eax,%ebx
f01015cf:	83 c4 10             	add    $0x10,%esp
f01015d2:	85 c0                	test   %eax,%eax
f01015d4:	75 19                	jne    f01015ef <mem_init+0x566>
f01015d6:	68 63 4c 10 f0       	push   $0xf0104c63
f01015db:	68 a2 4b 10 f0       	push   $0xf0104ba2
f01015e0:	68 28 03 00 00       	push   $0x328
f01015e5:	68 6d 4b 10 f0       	push   $0xf0104b6d
f01015ea:	e8 b1 ea ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f01015ef:	83 ec 0c             	sub    $0xc,%esp
f01015f2:	6a 00                	push   $0x0
f01015f4:	e8 bf f7 ff ff       	call   f0100db8 <page_alloc>
f01015f9:	89 c6                	mov    %eax,%esi
f01015fb:	83 c4 10             	add    $0x10,%esp
f01015fe:	85 c0                	test   %eax,%eax
f0101600:	75 19                	jne    f010161b <mem_init+0x592>
f0101602:	68 79 4c 10 f0       	push   $0xf0104c79
f0101607:	68 a2 4b 10 f0       	push   $0xf0104ba2
f010160c:	68 29 03 00 00       	push   $0x329
f0101611:	68 6d 4b 10 f0       	push   $0xf0104b6d
f0101616:	e8 85 ea ff ff       	call   f01000a0 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010161b:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f010161e:	75 19                	jne    f0101639 <mem_init+0x5b0>
f0101620:	68 8f 4c 10 f0       	push   $0xf0104c8f
f0101625:	68 a2 4b 10 f0       	push   $0xf0104ba2
f010162a:	68 2c 03 00 00       	push   $0x32c
f010162f:	68 6d 4b 10 f0       	push   $0xf0104b6d
f0101634:	e8 67 ea ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101639:	39 c3                	cmp    %eax,%ebx
f010163b:	74 05                	je     f0101642 <mem_init+0x5b9>
f010163d:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101640:	75 19                	jne    f010165b <mem_init+0x5d2>
f0101642:	68 50 45 10 f0       	push   $0xf0104550
f0101647:	68 a2 4b 10 f0       	push   $0xf0104ba2
f010164c:	68 2d 03 00 00       	push   $0x32d
f0101651:	68 6d 4b 10 f0       	push   $0xf0104b6d
f0101656:	e8 45 ea ff ff       	call   f01000a0 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f010165b:	a1 7c ef 16 f0       	mov    0xf016ef7c,%eax
f0101660:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101663:	c7 05 7c ef 16 f0 00 	movl   $0x0,0xf016ef7c
f010166a:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f010166d:	83 ec 0c             	sub    $0xc,%esp
f0101670:	6a 00                	push   $0x0
f0101672:	e8 41 f7 ff ff       	call   f0100db8 <page_alloc>
f0101677:	83 c4 10             	add    $0x10,%esp
f010167a:	85 c0                	test   %eax,%eax
f010167c:	74 19                	je     f0101697 <mem_init+0x60e>
f010167e:	68 f8 4c 10 f0       	push   $0xf0104cf8
f0101683:	68 a2 4b 10 f0       	push   $0xf0104ba2
f0101688:	68 34 03 00 00       	push   $0x334
f010168d:	68 6d 4b 10 f0       	push   $0xf0104b6d
f0101692:	e8 09 ea ff ff       	call   f01000a0 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101697:	83 ec 04             	sub    $0x4,%esp
f010169a:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010169d:	50                   	push   %eax
f010169e:	6a 00                	push   $0x0
f01016a0:	ff 35 48 fc 16 f0    	pushl  0xf016fc48
f01016a6:	e8 dd f8 ff ff       	call   f0100f88 <page_lookup>
f01016ab:	83 c4 10             	add    $0x10,%esp
f01016ae:	85 c0                	test   %eax,%eax
f01016b0:	74 19                	je     f01016cb <mem_init+0x642>
f01016b2:	68 90 45 10 f0       	push   $0xf0104590
f01016b7:	68 a2 4b 10 f0       	push   $0xf0104ba2
f01016bc:	68 37 03 00 00       	push   $0x337
f01016c1:	68 6d 4b 10 f0       	push   $0xf0104b6d
f01016c6:	e8 d5 e9 ff ff       	call   f01000a0 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f01016cb:	6a 02                	push   $0x2
f01016cd:	6a 00                	push   $0x0
f01016cf:	53                   	push   %ebx
f01016d0:	ff 35 48 fc 16 f0    	pushl  0xf016fc48
f01016d6:	e8 42 f9 ff ff       	call   f010101d <page_insert>
f01016db:	83 c4 10             	add    $0x10,%esp
f01016de:	85 c0                	test   %eax,%eax
f01016e0:	78 19                	js     f01016fb <mem_init+0x672>
f01016e2:	68 c8 45 10 f0       	push   $0xf01045c8
f01016e7:	68 a2 4b 10 f0       	push   $0xf0104ba2
f01016ec:	68 3a 03 00 00       	push   $0x33a
f01016f1:	68 6d 4b 10 f0       	push   $0xf0104b6d
f01016f6:	e8 a5 e9 ff ff       	call   f01000a0 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f01016fb:	83 ec 0c             	sub    $0xc,%esp
f01016fe:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101701:	e8 29 f7 ff ff       	call   f0100e2f <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101706:	6a 02                	push   $0x2
f0101708:	6a 00                	push   $0x0
f010170a:	53                   	push   %ebx
f010170b:	ff 35 48 fc 16 f0    	pushl  0xf016fc48
f0101711:	e8 07 f9 ff ff       	call   f010101d <page_insert>
f0101716:	83 c4 20             	add    $0x20,%esp
f0101719:	85 c0                	test   %eax,%eax
f010171b:	74 19                	je     f0101736 <mem_init+0x6ad>
f010171d:	68 f8 45 10 f0       	push   $0xf01045f8
f0101722:	68 a2 4b 10 f0       	push   $0xf0104ba2
f0101727:	68 3e 03 00 00       	push   $0x33e
f010172c:	68 6d 4b 10 f0       	push   $0xf0104b6d
f0101731:	e8 6a e9 ff ff       	call   f01000a0 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101736:	8b 3d 48 fc 16 f0    	mov    0xf016fc48,%edi
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010173c:	a1 4c fc 16 f0       	mov    0xf016fc4c,%eax
f0101741:	89 c1                	mov    %eax,%ecx
f0101743:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101746:	8b 17                	mov    (%edi),%edx
f0101748:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010174e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101751:	29 c8                	sub    %ecx,%eax
f0101753:	c1 f8 03             	sar    $0x3,%eax
f0101756:	c1 e0 0c             	shl    $0xc,%eax
f0101759:	39 c2                	cmp    %eax,%edx
f010175b:	74 19                	je     f0101776 <mem_init+0x6ed>
f010175d:	68 28 46 10 f0       	push   $0xf0104628
f0101762:	68 a2 4b 10 f0       	push   $0xf0104ba2
f0101767:	68 3f 03 00 00       	push   $0x33f
f010176c:	68 6d 4b 10 f0       	push   $0xf0104b6d
f0101771:	e8 2a e9 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101776:	ba 00 00 00 00       	mov    $0x0,%edx
f010177b:	89 f8                	mov    %edi,%eax
f010177d:	e8 a4 f1 ff ff       	call   f0100926 <check_va2pa>
f0101782:	89 da                	mov    %ebx,%edx
f0101784:	2b 55 cc             	sub    -0x34(%ebp),%edx
f0101787:	c1 fa 03             	sar    $0x3,%edx
f010178a:	c1 e2 0c             	shl    $0xc,%edx
f010178d:	39 d0                	cmp    %edx,%eax
f010178f:	74 19                	je     f01017aa <mem_init+0x721>
f0101791:	68 50 46 10 f0       	push   $0xf0104650
f0101796:	68 a2 4b 10 f0       	push   $0xf0104ba2
f010179b:	68 40 03 00 00       	push   $0x340
f01017a0:	68 6d 4b 10 f0       	push   $0xf0104b6d
f01017a5:	e8 f6 e8 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 1);
f01017aa:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01017af:	74 19                	je     f01017ca <mem_init+0x741>
f01017b1:	68 4a 4d 10 f0       	push   $0xf0104d4a
f01017b6:	68 a2 4b 10 f0       	push   $0xf0104ba2
f01017bb:	68 41 03 00 00       	push   $0x341
f01017c0:	68 6d 4b 10 f0       	push   $0xf0104b6d
f01017c5:	e8 d6 e8 ff ff       	call   f01000a0 <_panic>
	assert(pp0->pp_ref == 1);
f01017ca:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01017cd:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f01017d2:	74 19                	je     f01017ed <mem_init+0x764>
f01017d4:	68 5b 4d 10 f0       	push   $0xf0104d5b
f01017d9:	68 a2 4b 10 f0       	push   $0xf0104ba2
f01017de:	68 42 03 00 00       	push   $0x342
f01017e3:	68 6d 4b 10 f0       	push   $0xf0104b6d
f01017e8:	e8 b3 e8 ff ff       	call   f01000a0 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01017ed:	6a 02                	push   $0x2
f01017ef:	68 00 10 00 00       	push   $0x1000
f01017f4:	56                   	push   %esi
f01017f5:	57                   	push   %edi
f01017f6:	e8 22 f8 ff ff       	call   f010101d <page_insert>
f01017fb:	83 c4 10             	add    $0x10,%esp
f01017fe:	85 c0                	test   %eax,%eax
f0101800:	74 19                	je     f010181b <mem_init+0x792>
f0101802:	68 80 46 10 f0       	push   $0xf0104680
f0101807:	68 a2 4b 10 f0       	push   $0xf0104ba2
f010180c:	68 45 03 00 00       	push   $0x345
f0101811:	68 6d 4b 10 f0       	push   $0xf0104b6d
f0101816:	e8 85 e8 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f010181b:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101820:	a1 48 fc 16 f0       	mov    0xf016fc48,%eax
f0101825:	e8 fc f0 ff ff       	call   f0100926 <check_va2pa>
f010182a:	89 f2                	mov    %esi,%edx
f010182c:	2b 15 4c fc 16 f0    	sub    0xf016fc4c,%edx
f0101832:	c1 fa 03             	sar    $0x3,%edx
f0101835:	c1 e2 0c             	shl    $0xc,%edx
f0101838:	39 d0                	cmp    %edx,%eax
f010183a:	74 19                	je     f0101855 <mem_init+0x7cc>
f010183c:	68 bc 46 10 f0       	push   $0xf01046bc
f0101841:	68 a2 4b 10 f0       	push   $0xf0104ba2
f0101846:	68 46 03 00 00       	push   $0x346
f010184b:	68 6d 4b 10 f0       	push   $0xf0104b6d
f0101850:	e8 4b e8 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f0101855:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f010185a:	74 19                	je     f0101875 <mem_init+0x7ec>
f010185c:	68 6c 4d 10 f0       	push   $0xf0104d6c
f0101861:	68 a2 4b 10 f0       	push   $0xf0104ba2
f0101866:	68 47 03 00 00       	push   $0x347
f010186b:	68 6d 4b 10 f0       	push   $0xf0104b6d
f0101870:	e8 2b e8 ff ff       	call   f01000a0 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101875:	83 ec 0c             	sub    $0xc,%esp
f0101878:	6a 00                	push   $0x0
f010187a:	e8 39 f5 ff ff       	call   f0100db8 <page_alloc>
f010187f:	83 c4 10             	add    $0x10,%esp
f0101882:	85 c0                	test   %eax,%eax
f0101884:	74 19                	je     f010189f <mem_init+0x816>
f0101886:	68 f8 4c 10 f0       	push   $0xf0104cf8
f010188b:	68 a2 4b 10 f0       	push   $0xf0104ba2
f0101890:	68 4a 03 00 00       	push   $0x34a
f0101895:	68 6d 4b 10 f0       	push   $0xf0104b6d
f010189a:	e8 01 e8 ff ff       	call   f01000a0 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f010189f:	6a 02                	push   $0x2
f01018a1:	68 00 10 00 00       	push   $0x1000
f01018a6:	56                   	push   %esi
f01018a7:	ff 35 48 fc 16 f0    	pushl  0xf016fc48
f01018ad:	e8 6b f7 ff ff       	call   f010101d <page_insert>
f01018b2:	83 c4 10             	add    $0x10,%esp
f01018b5:	85 c0                	test   %eax,%eax
f01018b7:	74 19                	je     f01018d2 <mem_init+0x849>
f01018b9:	68 80 46 10 f0       	push   $0xf0104680
f01018be:	68 a2 4b 10 f0       	push   $0xf0104ba2
f01018c3:	68 4d 03 00 00       	push   $0x34d
f01018c8:	68 6d 4b 10 f0       	push   $0xf0104b6d
f01018cd:	e8 ce e7 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01018d2:	ba 00 10 00 00       	mov    $0x1000,%edx
f01018d7:	a1 48 fc 16 f0       	mov    0xf016fc48,%eax
f01018dc:	e8 45 f0 ff ff       	call   f0100926 <check_va2pa>
f01018e1:	89 f2                	mov    %esi,%edx
f01018e3:	2b 15 4c fc 16 f0    	sub    0xf016fc4c,%edx
f01018e9:	c1 fa 03             	sar    $0x3,%edx
f01018ec:	c1 e2 0c             	shl    $0xc,%edx
f01018ef:	39 d0                	cmp    %edx,%eax
f01018f1:	74 19                	je     f010190c <mem_init+0x883>
f01018f3:	68 bc 46 10 f0       	push   $0xf01046bc
f01018f8:	68 a2 4b 10 f0       	push   $0xf0104ba2
f01018fd:	68 4e 03 00 00       	push   $0x34e
f0101902:	68 6d 4b 10 f0       	push   $0xf0104b6d
f0101907:	e8 94 e7 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f010190c:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101911:	74 19                	je     f010192c <mem_init+0x8a3>
f0101913:	68 6c 4d 10 f0       	push   $0xf0104d6c
f0101918:	68 a2 4b 10 f0       	push   $0xf0104ba2
f010191d:	68 4f 03 00 00       	push   $0x34f
f0101922:	68 6d 4b 10 f0       	push   $0xf0104b6d
f0101927:	e8 74 e7 ff ff       	call   f01000a0 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f010192c:	83 ec 0c             	sub    $0xc,%esp
f010192f:	6a 00                	push   $0x0
f0101931:	e8 82 f4 ff ff       	call   f0100db8 <page_alloc>
f0101936:	83 c4 10             	add    $0x10,%esp
f0101939:	85 c0                	test   %eax,%eax
f010193b:	74 19                	je     f0101956 <mem_init+0x8cd>
f010193d:	68 f8 4c 10 f0       	push   $0xf0104cf8
f0101942:	68 a2 4b 10 f0       	push   $0xf0104ba2
f0101947:	68 53 03 00 00       	push   $0x353
f010194c:	68 6d 4b 10 f0       	push   $0xf0104b6d
f0101951:	e8 4a e7 ff ff       	call   f01000a0 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101956:	8b 15 48 fc 16 f0    	mov    0xf016fc48,%edx
f010195c:	8b 02                	mov    (%edx),%eax
f010195e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101963:	89 c1                	mov    %eax,%ecx
f0101965:	c1 e9 0c             	shr    $0xc,%ecx
f0101968:	3b 0d 44 fc 16 f0    	cmp    0xf016fc44,%ecx
f010196e:	72 15                	jb     f0101985 <mem_init+0x8fc>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101970:	50                   	push   %eax
f0101971:	68 b4 43 10 f0       	push   $0xf01043b4
f0101976:	68 56 03 00 00       	push   $0x356
f010197b:	68 6d 4b 10 f0       	push   $0xf0104b6d
f0101980:	e8 1b e7 ff ff       	call   f01000a0 <_panic>
f0101985:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010198a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f010198d:	83 ec 04             	sub    $0x4,%esp
f0101990:	6a 00                	push   $0x0
f0101992:	68 00 10 00 00       	push   $0x1000
f0101997:	52                   	push   %edx
f0101998:	e8 f4 f4 ff ff       	call   f0100e91 <pgdir_walk>
f010199d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01019a0:	8d 57 04             	lea    0x4(%edi),%edx
f01019a3:	83 c4 10             	add    $0x10,%esp
f01019a6:	39 d0                	cmp    %edx,%eax
f01019a8:	74 19                	je     f01019c3 <mem_init+0x93a>
f01019aa:	68 ec 46 10 f0       	push   $0xf01046ec
f01019af:	68 a2 4b 10 f0       	push   $0xf0104ba2
f01019b4:	68 57 03 00 00       	push   $0x357
f01019b9:	68 6d 4b 10 f0       	push   $0xf0104b6d
f01019be:	e8 dd e6 ff ff       	call   f01000a0 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f01019c3:	6a 06                	push   $0x6
f01019c5:	68 00 10 00 00       	push   $0x1000
f01019ca:	56                   	push   %esi
f01019cb:	ff 35 48 fc 16 f0    	pushl  0xf016fc48
f01019d1:	e8 47 f6 ff ff       	call   f010101d <page_insert>
f01019d6:	83 c4 10             	add    $0x10,%esp
f01019d9:	85 c0                	test   %eax,%eax
f01019db:	74 19                	je     f01019f6 <mem_init+0x96d>
f01019dd:	68 2c 47 10 f0       	push   $0xf010472c
f01019e2:	68 a2 4b 10 f0       	push   $0xf0104ba2
f01019e7:	68 5a 03 00 00       	push   $0x35a
f01019ec:	68 6d 4b 10 f0       	push   $0xf0104b6d
f01019f1:	e8 aa e6 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01019f6:	8b 3d 48 fc 16 f0    	mov    0xf016fc48,%edi
f01019fc:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101a01:	89 f8                	mov    %edi,%eax
f0101a03:	e8 1e ef ff ff       	call   f0100926 <check_va2pa>
f0101a08:	89 f2                	mov    %esi,%edx
f0101a0a:	2b 15 4c fc 16 f0    	sub    0xf016fc4c,%edx
f0101a10:	c1 fa 03             	sar    $0x3,%edx
f0101a13:	c1 e2 0c             	shl    $0xc,%edx
f0101a16:	39 d0                	cmp    %edx,%eax
f0101a18:	74 19                	je     f0101a33 <mem_init+0x9aa>
f0101a1a:	68 bc 46 10 f0       	push   $0xf01046bc
f0101a1f:	68 a2 4b 10 f0       	push   $0xf0104ba2
f0101a24:	68 5b 03 00 00       	push   $0x35b
f0101a29:	68 6d 4b 10 f0       	push   $0xf0104b6d
f0101a2e:	e8 6d e6 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f0101a33:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101a38:	74 19                	je     f0101a53 <mem_init+0x9ca>
f0101a3a:	68 6c 4d 10 f0       	push   $0xf0104d6c
f0101a3f:	68 a2 4b 10 f0       	push   $0xf0104ba2
f0101a44:	68 5c 03 00 00       	push   $0x35c
f0101a49:	68 6d 4b 10 f0       	push   $0xf0104b6d
f0101a4e:	e8 4d e6 ff ff       	call   f01000a0 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101a53:	83 ec 04             	sub    $0x4,%esp
f0101a56:	6a 00                	push   $0x0
f0101a58:	68 00 10 00 00       	push   $0x1000
f0101a5d:	57                   	push   %edi
f0101a5e:	e8 2e f4 ff ff       	call   f0100e91 <pgdir_walk>
f0101a63:	83 c4 10             	add    $0x10,%esp
f0101a66:	f6 00 04             	testb  $0x4,(%eax)
f0101a69:	75 19                	jne    f0101a84 <mem_init+0x9fb>
f0101a6b:	68 6c 47 10 f0       	push   $0xf010476c
f0101a70:	68 a2 4b 10 f0       	push   $0xf0104ba2
f0101a75:	68 5d 03 00 00       	push   $0x35d
f0101a7a:	68 6d 4b 10 f0       	push   $0xf0104b6d
f0101a7f:	e8 1c e6 ff ff       	call   f01000a0 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101a84:	a1 48 fc 16 f0       	mov    0xf016fc48,%eax
f0101a89:	f6 00 04             	testb  $0x4,(%eax)
f0101a8c:	75 19                	jne    f0101aa7 <mem_init+0xa1e>
f0101a8e:	68 7d 4d 10 f0       	push   $0xf0104d7d
f0101a93:	68 a2 4b 10 f0       	push   $0xf0104ba2
f0101a98:	68 5e 03 00 00       	push   $0x35e
f0101a9d:	68 6d 4b 10 f0       	push   $0xf0104b6d
f0101aa2:	e8 f9 e5 ff ff       	call   f01000a0 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101aa7:	6a 02                	push   $0x2
f0101aa9:	68 00 10 00 00       	push   $0x1000
f0101aae:	56                   	push   %esi
f0101aaf:	50                   	push   %eax
f0101ab0:	e8 68 f5 ff ff       	call   f010101d <page_insert>
f0101ab5:	83 c4 10             	add    $0x10,%esp
f0101ab8:	85 c0                	test   %eax,%eax
f0101aba:	74 19                	je     f0101ad5 <mem_init+0xa4c>
f0101abc:	68 80 46 10 f0       	push   $0xf0104680
f0101ac1:	68 a2 4b 10 f0       	push   $0xf0104ba2
f0101ac6:	68 61 03 00 00       	push   $0x361
f0101acb:	68 6d 4b 10 f0       	push   $0xf0104b6d
f0101ad0:	e8 cb e5 ff ff       	call   f01000a0 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101ad5:	83 ec 04             	sub    $0x4,%esp
f0101ad8:	6a 00                	push   $0x0
f0101ada:	68 00 10 00 00       	push   $0x1000
f0101adf:	ff 35 48 fc 16 f0    	pushl  0xf016fc48
f0101ae5:	e8 a7 f3 ff ff       	call   f0100e91 <pgdir_walk>
f0101aea:	83 c4 10             	add    $0x10,%esp
f0101aed:	f6 00 02             	testb  $0x2,(%eax)
f0101af0:	75 19                	jne    f0101b0b <mem_init+0xa82>
f0101af2:	68 a0 47 10 f0       	push   $0xf01047a0
f0101af7:	68 a2 4b 10 f0       	push   $0xf0104ba2
f0101afc:	68 62 03 00 00       	push   $0x362
f0101b01:	68 6d 4b 10 f0       	push   $0xf0104b6d
f0101b06:	e8 95 e5 ff ff       	call   f01000a0 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101b0b:	83 ec 04             	sub    $0x4,%esp
f0101b0e:	6a 00                	push   $0x0
f0101b10:	68 00 10 00 00       	push   $0x1000
f0101b15:	ff 35 48 fc 16 f0    	pushl  0xf016fc48
f0101b1b:	e8 71 f3 ff ff       	call   f0100e91 <pgdir_walk>
f0101b20:	83 c4 10             	add    $0x10,%esp
f0101b23:	f6 00 04             	testb  $0x4,(%eax)
f0101b26:	74 19                	je     f0101b41 <mem_init+0xab8>
f0101b28:	68 d4 47 10 f0       	push   $0xf01047d4
f0101b2d:	68 a2 4b 10 f0       	push   $0xf0104ba2
f0101b32:	68 63 03 00 00       	push   $0x363
f0101b37:	68 6d 4b 10 f0       	push   $0xf0104b6d
f0101b3c:	e8 5f e5 ff ff       	call   f01000a0 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101b41:	6a 02                	push   $0x2
f0101b43:	68 00 00 40 00       	push   $0x400000
f0101b48:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101b4b:	ff 35 48 fc 16 f0    	pushl  0xf016fc48
f0101b51:	e8 c7 f4 ff ff       	call   f010101d <page_insert>
f0101b56:	83 c4 10             	add    $0x10,%esp
f0101b59:	85 c0                	test   %eax,%eax
f0101b5b:	78 19                	js     f0101b76 <mem_init+0xaed>
f0101b5d:	68 0c 48 10 f0       	push   $0xf010480c
f0101b62:	68 a2 4b 10 f0       	push   $0xf0104ba2
f0101b67:	68 66 03 00 00       	push   $0x366
f0101b6c:	68 6d 4b 10 f0       	push   $0xf0104b6d
f0101b71:	e8 2a e5 ff ff       	call   f01000a0 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101b76:	6a 02                	push   $0x2
f0101b78:	68 00 10 00 00       	push   $0x1000
f0101b7d:	53                   	push   %ebx
f0101b7e:	ff 35 48 fc 16 f0    	pushl  0xf016fc48
f0101b84:	e8 94 f4 ff ff       	call   f010101d <page_insert>
f0101b89:	83 c4 10             	add    $0x10,%esp
f0101b8c:	85 c0                	test   %eax,%eax
f0101b8e:	74 19                	je     f0101ba9 <mem_init+0xb20>
f0101b90:	68 44 48 10 f0       	push   $0xf0104844
f0101b95:	68 a2 4b 10 f0       	push   $0xf0104ba2
f0101b9a:	68 69 03 00 00       	push   $0x369
f0101b9f:	68 6d 4b 10 f0       	push   $0xf0104b6d
f0101ba4:	e8 f7 e4 ff ff       	call   f01000a0 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101ba9:	83 ec 04             	sub    $0x4,%esp
f0101bac:	6a 00                	push   $0x0
f0101bae:	68 00 10 00 00       	push   $0x1000
f0101bb3:	ff 35 48 fc 16 f0    	pushl  0xf016fc48
f0101bb9:	e8 d3 f2 ff ff       	call   f0100e91 <pgdir_walk>
f0101bbe:	83 c4 10             	add    $0x10,%esp
f0101bc1:	f6 00 04             	testb  $0x4,(%eax)
f0101bc4:	74 19                	je     f0101bdf <mem_init+0xb56>
f0101bc6:	68 d4 47 10 f0       	push   $0xf01047d4
f0101bcb:	68 a2 4b 10 f0       	push   $0xf0104ba2
f0101bd0:	68 6a 03 00 00       	push   $0x36a
f0101bd5:	68 6d 4b 10 f0       	push   $0xf0104b6d
f0101bda:	e8 c1 e4 ff ff       	call   f01000a0 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101bdf:	8b 3d 48 fc 16 f0    	mov    0xf016fc48,%edi
f0101be5:	ba 00 00 00 00       	mov    $0x0,%edx
f0101bea:	89 f8                	mov    %edi,%eax
f0101bec:	e8 35 ed ff ff       	call   f0100926 <check_va2pa>
f0101bf1:	89 c1                	mov    %eax,%ecx
f0101bf3:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101bf6:	89 d8                	mov    %ebx,%eax
f0101bf8:	2b 05 4c fc 16 f0    	sub    0xf016fc4c,%eax
f0101bfe:	c1 f8 03             	sar    $0x3,%eax
f0101c01:	c1 e0 0c             	shl    $0xc,%eax
f0101c04:	39 c1                	cmp    %eax,%ecx
f0101c06:	74 19                	je     f0101c21 <mem_init+0xb98>
f0101c08:	68 80 48 10 f0       	push   $0xf0104880
f0101c0d:	68 a2 4b 10 f0       	push   $0xf0104ba2
f0101c12:	68 6d 03 00 00       	push   $0x36d
f0101c17:	68 6d 4b 10 f0       	push   $0xf0104b6d
f0101c1c:	e8 7f e4 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101c21:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c26:	89 f8                	mov    %edi,%eax
f0101c28:	e8 f9 ec ff ff       	call   f0100926 <check_va2pa>
f0101c2d:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101c30:	74 19                	je     f0101c4b <mem_init+0xbc2>
f0101c32:	68 ac 48 10 f0       	push   $0xf01048ac
f0101c37:	68 a2 4b 10 f0       	push   $0xf0104ba2
f0101c3c:	68 6e 03 00 00       	push   $0x36e
f0101c41:	68 6d 4b 10 f0       	push   $0xf0104b6d
f0101c46:	e8 55 e4 ff ff       	call   f01000a0 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101c4b:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101c50:	74 19                	je     f0101c6b <mem_init+0xbe2>
f0101c52:	68 93 4d 10 f0       	push   $0xf0104d93
f0101c57:	68 a2 4b 10 f0       	push   $0xf0104ba2
f0101c5c:	68 70 03 00 00       	push   $0x370
f0101c61:	68 6d 4b 10 f0       	push   $0xf0104b6d
f0101c66:	e8 35 e4 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101c6b:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101c70:	74 19                	je     f0101c8b <mem_init+0xc02>
f0101c72:	68 a4 4d 10 f0       	push   $0xf0104da4
f0101c77:	68 a2 4b 10 f0       	push   $0xf0104ba2
f0101c7c:	68 71 03 00 00       	push   $0x371
f0101c81:	68 6d 4b 10 f0       	push   $0xf0104b6d
f0101c86:	e8 15 e4 ff ff       	call   f01000a0 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101c8b:	83 ec 0c             	sub    $0xc,%esp
f0101c8e:	6a 00                	push   $0x0
f0101c90:	e8 23 f1 ff ff       	call   f0100db8 <page_alloc>
f0101c95:	83 c4 10             	add    $0x10,%esp
f0101c98:	39 c6                	cmp    %eax,%esi
f0101c9a:	75 04                	jne    f0101ca0 <mem_init+0xc17>
f0101c9c:	85 c0                	test   %eax,%eax
f0101c9e:	75 19                	jne    f0101cb9 <mem_init+0xc30>
f0101ca0:	68 dc 48 10 f0       	push   $0xf01048dc
f0101ca5:	68 a2 4b 10 f0       	push   $0xf0104ba2
f0101caa:	68 74 03 00 00       	push   $0x374
f0101caf:	68 6d 4b 10 f0       	push   $0xf0104b6d
f0101cb4:	e8 e7 e3 ff ff       	call   f01000a0 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101cb9:	83 ec 08             	sub    $0x8,%esp
f0101cbc:	6a 00                	push   $0x0
f0101cbe:	ff 35 48 fc 16 f0    	pushl  0xf016fc48
f0101cc4:	e8 19 f3 ff ff       	call   f0100fe2 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101cc9:	8b 3d 48 fc 16 f0    	mov    0xf016fc48,%edi
f0101ccf:	ba 00 00 00 00       	mov    $0x0,%edx
f0101cd4:	89 f8                	mov    %edi,%eax
f0101cd6:	e8 4b ec ff ff       	call   f0100926 <check_va2pa>
f0101cdb:	83 c4 10             	add    $0x10,%esp
f0101cde:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101ce1:	74 19                	je     f0101cfc <mem_init+0xc73>
f0101ce3:	68 00 49 10 f0       	push   $0xf0104900
f0101ce8:	68 a2 4b 10 f0       	push   $0xf0104ba2
f0101ced:	68 78 03 00 00       	push   $0x378
f0101cf2:	68 6d 4b 10 f0       	push   $0xf0104b6d
f0101cf7:	e8 a4 e3 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101cfc:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101d01:	89 f8                	mov    %edi,%eax
f0101d03:	e8 1e ec ff ff       	call   f0100926 <check_va2pa>
f0101d08:	89 da                	mov    %ebx,%edx
f0101d0a:	2b 15 4c fc 16 f0    	sub    0xf016fc4c,%edx
f0101d10:	c1 fa 03             	sar    $0x3,%edx
f0101d13:	c1 e2 0c             	shl    $0xc,%edx
f0101d16:	39 d0                	cmp    %edx,%eax
f0101d18:	74 19                	je     f0101d33 <mem_init+0xcaa>
f0101d1a:	68 ac 48 10 f0       	push   $0xf01048ac
f0101d1f:	68 a2 4b 10 f0       	push   $0xf0104ba2
f0101d24:	68 79 03 00 00       	push   $0x379
f0101d29:	68 6d 4b 10 f0       	push   $0xf0104b6d
f0101d2e:	e8 6d e3 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 1);
f0101d33:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101d38:	74 19                	je     f0101d53 <mem_init+0xcca>
f0101d3a:	68 4a 4d 10 f0       	push   $0xf0104d4a
f0101d3f:	68 a2 4b 10 f0       	push   $0xf0104ba2
f0101d44:	68 7a 03 00 00       	push   $0x37a
f0101d49:	68 6d 4b 10 f0       	push   $0xf0104b6d
f0101d4e:	e8 4d e3 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101d53:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101d58:	74 19                	je     f0101d73 <mem_init+0xcea>
f0101d5a:	68 a4 4d 10 f0       	push   $0xf0104da4
f0101d5f:	68 a2 4b 10 f0       	push   $0xf0104ba2
f0101d64:	68 7b 03 00 00       	push   $0x37b
f0101d69:	68 6d 4b 10 f0       	push   $0xf0104b6d
f0101d6e:	e8 2d e3 ff ff       	call   f01000a0 <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101d73:	6a 00                	push   $0x0
f0101d75:	68 00 10 00 00       	push   $0x1000
f0101d7a:	53                   	push   %ebx
f0101d7b:	57                   	push   %edi
f0101d7c:	e8 9c f2 ff ff       	call   f010101d <page_insert>
f0101d81:	83 c4 10             	add    $0x10,%esp
f0101d84:	85 c0                	test   %eax,%eax
f0101d86:	74 19                	je     f0101da1 <mem_init+0xd18>
f0101d88:	68 24 49 10 f0       	push   $0xf0104924
f0101d8d:	68 a2 4b 10 f0       	push   $0xf0104ba2
f0101d92:	68 7e 03 00 00       	push   $0x37e
f0101d97:	68 6d 4b 10 f0       	push   $0xf0104b6d
f0101d9c:	e8 ff e2 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref);
f0101da1:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101da6:	75 19                	jne    f0101dc1 <mem_init+0xd38>
f0101da8:	68 b5 4d 10 f0       	push   $0xf0104db5
f0101dad:	68 a2 4b 10 f0       	push   $0xf0104ba2
f0101db2:	68 7f 03 00 00       	push   $0x37f
f0101db7:	68 6d 4b 10 f0       	push   $0xf0104b6d
f0101dbc:	e8 df e2 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_link == NULL);
f0101dc1:	83 3b 00             	cmpl   $0x0,(%ebx)
f0101dc4:	74 19                	je     f0101ddf <mem_init+0xd56>
f0101dc6:	68 c1 4d 10 f0       	push   $0xf0104dc1
f0101dcb:	68 a2 4b 10 f0       	push   $0xf0104ba2
f0101dd0:	68 80 03 00 00       	push   $0x380
f0101dd5:	68 6d 4b 10 f0       	push   $0xf0104b6d
f0101dda:	e8 c1 e2 ff ff       	call   f01000a0 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101ddf:	83 ec 08             	sub    $0x8,%esp
f0101de2:	68 00 10 00 00       	push   $0x1000
f0101de7:	ff 35 48 fc 16 f0    	pushl  0xf016fc48
f0101ded:	e8 f0 f1 ff ff       	call   f0100fe2 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101df2:	8b 3d 48 fc 16 f0    	mov    0xf016fc48,%edi
f0101df8:	ba 00 00 00 00       	mov    $0x0,%edx
f0101dfd:	89 f8                	mov    %edi,%eax
f0101dff:	e8 22 eb ff ff       	call   f0100926 <check_va2pa>
f0101e04:	83 c4 10             	add    $0x10,%esp
f0101e07:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e0a:	74 19                	je     f0101e25 <mem_init+0xd9c>
f0101e0c:	68 00 49 10 f0       	push   $0xf0104900
f0101e11:	68 a2 4b 10 f0       	push   $0xf0104ba2
f0101e16:	68 84 03 00 00       	push   $0x384
f0101e1b:	68 6d 4b 10 f0       	push   $0xf0104b6d
f0101e20:	e8 7b e2 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101e25:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e2a:	89 f8                	mov    %edi,%eax
f0101e2c:	e8 f5 ea ff ff       	call   f0100926 <check_va2pa>
f0101e31:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e34:	74 19                	je     f0101e4f <mem_init+0xdc6>
f0101e36:	68 5c 49 10 f0       	push   $0xf010495c
f0101e3b:	68 a2 4b 10 f0       	push   $0xf0104ba2
f0101e40:	68 85 03 00 00       	push   $0x385
f0101e45:	68 6d 4b 10 f0       	push   $0xf0104b6d
f0101e4a:	e8 51 e2 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 0);
f0101e4f:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101e54:	74 19                	je     f0101e6f <mem_init+0xde6>
f0101e56:	68 d6 4d 10 f0       	push   $0xf0104dd6
f0101e5b:	68 a2 4b 10 f0       	push   $0xf0104ba2
f0101e60:	68 86 03 00 00       	push   $0x386
f0101e65:	68 6d 4b 10 f0       	push   $0xf0104b6d
f0101e6a:	e8 31 e2 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101e6f:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101e74:	74 19                	je     f0101e8f <mem_init+0xe06>
f0101e76:	68 a4 4d 10 f0       	push   $0xf0104da4
f0101e7b:	68 a2 4b 10 f0       	push   $0xf0104ba2
f0101e80:	68 87 03 00 00       	push   $0x387
f0101e85:	68 6d 4b 10 f0       	push   $0xf0104b6d
f0101e8a:	e8 11 e2 ff ff       	call   f01000a0 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101e8f:	83 ec 0c             	sub    $0xc,%esp
f0101e92:	6a 00                	push   $0x0
f0101e94:	e8 1f ef ff ff       	call   f0100db8 <page_alloc>
f0101e99:	83 c4 10             	add    $0x10,%esp
f0101e9c:	85 c0                	test   %eax,%eax
f0101e9e:	74 04                	je     f0101ea4 <mem_init+0xe1b>
f0101ea0:	39 c3                	cmp    %eax,%ebx
f0101ea2:	74 19                	je     f0101ebd <mem_init+0xe34>
f0101ea4:	68 84 49 10 f0       	push   $0xf0104984
f0101ea9:	68 a2 4b 10 f0       	push   $0xf0104ba2
f0101eae:	68 8a 03 00 00       	push   $0x38a
f0101eb3:	68 6d 4b 10 f0       	push   $0xf0104b6d
f0101eb8:	e8 e3 e1 ff ff       	call   f01000a0 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101ebd:	83 ec 0c             	sub    $0xc,%esp
f0101ec0:	6a 00                	push   $0x0
f0101ec2:	e8 f1 ee ff ff       	call   f0100db8 <page_alloc>
f0101ec7:	83 c4 10             	add    $0x10,%esp
f0101eca:	85 c0                	test   %eax,%eax
f0101ecc:	74 19                	je     f0101ee7 <mem_init+0xe5e>
f0101ece:	68 f8 4c 10 f0       	push   $0xf0104cf8
f0101ed3:	68 a2 4b 10 f0       	push   $0xf0104ba2
f0101ed8:	68 8d 03 00 00       	push   $0x38d
f0101edd:	68 6d 4b 10 f0       	push   $0xf0104b6d
f0101ee2:	e8 b9 e1 ff ff       	call   f01000a0 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101ee7:	8b 0d 48 fc 16 f0    	mov    0xf016fc48,%ecx
f0101eed:	8b 11                	mov    (%ecx),%edx
f0101eef:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101ef5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ef8:	2b 05 4c fc 16 f0    	sub    0xf016fc4c,%eax
f0101efe:	c1 f8 03             	sar    $0x3,%eax
f0101f01:	c1 e0 0c             	shl    $0xc,%eax
f0101f04:	39 c2                	cmp    %eax,%edx
f0101f06:	74 19                	je     f0101f21 <mem_init+0xe98>
f0101f08:	68 28 46 10 f0       	push   $0xf0104628
f0101f0d:	68 a2 4b 10 f0       	push   $0xf0104ba2
f0101f12:	68 90 03 00 00       	push   $0x390
f0101f17:	68 6d 4b 10 f0       	push   $0xf0104b6d
f0101f1c:	e8 7f e1 ff ff       	call   f01000a0 <_panic>
	kern_pgdir[0] = 0;
f0101f21:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0101f27:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f2a:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101f2f:	74 19                	je     f0101f4a <mem_init+0xec1>
f0101f31:	68 5b 4d 10 f0       	push   $0xf0104d5b
f0101f36:	68 a2 4b 10 f0       	push   $0xf0104ba2
f0101f3b:	68 92 03 00 00       	push   $0x392
f0101f40:	68 6d 4b 10 f0       	push   $0xf0104b6d
f0101f45:	e8 56 e1 ff ff       	call   f01000a0 <_panic>
	pp0->pp_ref = 0;
f0101f4a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f4d:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0101f53:	83 ec 0c             	sub    $0xc,%esp
f0101f56:	50                   	push   %eax
f0101f57:	e8 d3 ee ff ff       	call   f0100e2f <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0101f5c:	83 c4 0c             	add    $0xc,%esp
f0101f5f:	6a 01                	push   $0x1
f0101f61:	68 00 10 40 00       	push   $0x401000
f0101f66:	ff 35 48 fc 16 f0    	pushl  0xf016fc48
f0101f6c:	e8 20 ef ff ff       	call   f0100e91 <pgdir_walk>
f0101f71:	89 c7                	mov    %eax,%edi
f0101f73:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0101f76:	a1 48 fc 16 f0       	mov    0xf016fc48,%eax
f0101f7b:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101f7e:	8b 40 04             	mov    0x4(%eax),%eax
f0101f81:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101f86:	8b 0d 44 fc 16 f0    	mov    0xf016fc44,%ecx
f0101f8c:	89 c2                	mov    %eax,%edx
f0101f8e:	c1 ea 0c             	shr    $0xc,%edx
f0101f91:	83 c4 10             	add    $0x10,%esp
f0101f94:	39 ca                	cmp    %ecx,%edx
f0101f96:	72 15                	jb     f0101fad <mem_init+0xf24>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101f98:	50                   	push   %eax
f0101f99:	68 b4 43 10 f0       	push   $0xf01043b4
f0101f9e:	68 99 03 00 00       	push   $0x399
f0101fa3:	68 6d 4b 10 f0       	push   $0xf0104b6d
f0101fa8:	e8 f3 e0 ff ff       	call   f01000a0 <_panic>
	assert(ptep == ptep1 + PTX(va));
f0101fad:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f0101fb2:	39 c7                	cmp    %eax,%edi
f0101fb4:	74 19                	je     f0101fcf <mem_init+0xf46>
f0101fb6:	68 e7 4d 10 f0       	push   $0xf0104de7
f0101fbb:	68 a2 4b 10 f0       	push   $0xf0104ba2
f0101fc0:	68 9a 03 00 00       	push   $0x39a
f0101fc5:	68 6d 4b 10 f0       	push   $0xf0104b6d
f0101fca:	e8 d1 e0 ff ff       	call   f01000a0 <_panic>
	kern_pgdir[PDX(va)] = 0;
f0101fcf:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101fd2:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f0101fd9:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101fdc:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101fe2:	2b 05 4c fc 16 f0    	sub    0xf016fc4c,%eax
f0101fe8:	c1 f8 03             	sar    $0x3,%eax
f0101feb:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101fee:	89 c2                	mov    %eax,%edx
f0101ff0:	c1 ea 0c             	shr    $0xc,%edx
f0101ff3:	39 d1                	cmp    %edx,%ecx
f0101ff5:	77 12                	ja     f0102009 <mem_init+0xf80>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101ff7:	50                   	push   %eax
f0101ff8:	68 b4 43 10 f0       	push   $0xf01043b4
f0101ffd:	6a 56                	push   $0x56
f0101fff:	68 88 4b 10 f0       	push   $0xf0104b88
f0102004:	e8 97 e0 ff ff       	call   f01000a0 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0102009:	83 ec 04             	sub    $0x4,%esp
f010200c:	68 00 10 00 00       	push   $0x1000
f0102011:	68 ff 00 00 00       	push   $0xff
f0102016:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010201b:	50                   	push   %eax
f010201c:	e8 05 1a 00 00       	call   f0103a26 <memset>
	page_free(pp0);
f0102021:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102024:	89 3c 24             	mov    %edi,(%esp)
f0102027:	e8 03 ee ff ff       	call   f0100e2f <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f010202c:	83 c4 0c             	add    $0xc,%esp
f010202f:	6a 01                	push   $0x1
f0102031:	6a 00                	push   $0x0
f0102033:	ff 35 48 fc 16 f0    	pushl  0xf016fc48
f0102039:	e8 53 ee ff ff       	call   f0100e91 <pgdir_walk>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010203e:	89 fa                	mov    %edi,%edx
f0102040:	2b 15 4c fc 16 f0    	sub    0xf016fc4c,%edx
f0102046:	c1 fa 03             	sar    $0x3,%edx
f0102049:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010204c:	89 d0                	mov    %edx,%eax
f010204e:	c1 e8 0c             	shr    $0xc,%eax
f0102051:	83 c4 10             	add    $0x10,%esp
f0102054:	3b 05 44 fc 16 f0    	cmp    0xf016fc44,%eax
f010205a:	72 12                	jb     f010206e <mem_init+0xfe5>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010205c:	52                   	push   %edx
f010205d:	68 b4 43 10 f0       	push   $0xf01043b4
f0102062:	6a 56                	push   $0x56
f0102064:	68 88 4b 10 f0       	push   $0xf0104b88
f0102069:	e8 32 e0 ff ff       	call   f01000a0 <_panic>
	return (void *)(pa + KERNBASE);
f010206e:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f0102074:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102077:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f010207d:	f6 00 01             	testb  $0x1,(%eax)
f0102080:	74 19                	je     f010209b <mem_init+0x1012>
f0102082:	68 ff 4d 10 f0       	push   $0xf0104dff
f0102087:	68 a2 4b 10 f0       	push   $0xf0104ba2
f010208c:	68 a4 03 00 00       	push   $0x3a4
f0102091:	68 6d 4b 10 f0       	push   $0xf0104b6d
f0102096:	e8 05 e0 ff ff       	call   f01000a0 <_panic>
f010209b:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f010209e:	39 d0                	cmp    %edx,%eax
f01020a0:	75 db                	jne    f010207d <mem_init+0xff4>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f01020a2:	a1 48 fc 16 f0       	mov    0xf016fc48,%eax
f01020a7:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f01020ad:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01020b0:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f01020b6:	8b 7d d0             	mov    -0x30(%ebp),%edi
f01020b9:	89 3d 7c ef 16 f0    	mov    %edi,0xf016ef7c

	// free the pages we took
	page_free(pp0);
f01020bf:	83 ec 0c             	sub    $0xc,%esp
f01020c2:	50                   	push   %eax
f01020c3:	e8 67 ed ff ff       	call   f0100e2f <page_free>
	page_free(pp1);
f01020c8:	89 1c 24             	mov    %ebx,(%esp)
f01020cb:	e8 5f ed ff ff       	call   f0100e2f <page_free>
	page_free(pp2);
f01020d0:	89 34 24             	mov    %esi,(%esp)
f01020d3:	e8 57 ed ff ff       	call   f0100e2f <page_free>

	cprintf("check_page() succeeded!\n");
f01020d8:	c7 04 24 16 4e 10 f0 	movl   $0xf0104e16,(%esp)
f01020df:	e8 be 0a 00 00       	call   f0102ba2 <cprintf>
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	
	boot_map_region(kern_pgdir, UPAGES, PTSIZE, PADDR(pages), PTE_U);
f01020e4:	a1 4c fc 16 f0       	mov    0xf016fc4c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01020e9:	83 c4 10             	add    $0x10,%esp
f01020ec:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01020f1:	77 15                	ja     f0102108 <mem_init+0x107f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01020f3:	50                   	push   %eax
f01020f4:	68 d8 43 10 f0       	push   $0xf01043d8
f01020f9:	68 bb 00 00 00       	push   $0xbb
f01020fe:	68 6d 4b 10 f0       	push   $0xf0104b6d
f0102103:	e8 98 df ff ff       	call   f01000a0 <_panic>
f0102108:	83 ec 08             	sub    $0x8,%esp
f010210b:	6a 04                	push   $0x4
f010210d:	05 00 00 00 10       	add    $0x10000000,%eax
f0102112:	50                   	push   %eax
f0102113:	b9 00 00 40 00       	mov    $0x400000,%ecx
f0102118:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f010211d:	a1 48 fc 16 f0       	mov    0xf016fc48,%eax
f0102122:	e8 ff ed ff ff       	call   f0100f26 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102127:	83 c4 10             	add    $0x10,%esp
f010212a:	b8 00 f0 10 f0       	mov    $0xf010f000,%eax
f010212f:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102134:	77 15                	ja     f010214b <mem_init+0x10c2>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102136:	50                   	push   %eax
f0102137:	68 d8 43 10 f0       	push   $0xf01043d8
f010213c:	68 d0 00 00 00       	push   $0xd0
f0102141:	68 6d 4b 10 f0       	push   $0xf0104b6d
f0102146:	e8 55 df ff ff       	call   f01000a0 <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KSTACKTOP-KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W);
f010214b:	83 ec 08             	sub    $0x8,%esp
f010214e:	6a 02                	push   $0x2
f0102150:	68 00 f0 10 00       	push   $0x10f000
f0102155:	b9 00 80 00 00       	mov    $0x8000,%ecx
f010215a:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f010215f:	a1 48 fc 16 f0       	mov    0xf016fc48,%eax
f0102164:	e8 bd ed ff ff       	call   f0100f26 <boot_map_region>
	//      the PA range [0, 2^32 - KERNBASE)
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KERNBASE, 0xffffffff - KERNBASE, 0, PTE_W);
f0102169:	83 c4 08             	add    $0x8,%esp
f010216c:	6a 02                	push   $0x2
f010216e:	6a 00                	push   $0x0
f0102170:	b9 ff ff ff 0f       	mov    $0xfffffff,%ecx
f0102175:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f010217a:	a1 48 fc 16 f0       	mov    0xf016fc48,%eax
f010217f:	e8 a2 ed ff ff       	call   f0100f26 <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f0102184:	8b 1d 48 fc 16 f0    	mov    0xf016fc48,%ebx

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f010218a:	a1 44 fc 16 f0       	mov    0xf016fc44,%eax
f010218f:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102192:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0102199:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010219e:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01021a1:	8b 3d 4c fc 16 f0    	mov    0xf016fc4c,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01021a7:	89 7d d0             	mov    %edi,-0x30(%ebp)
f01021aa:	83 c4 10             	add    $0x10,%esp

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01021ad:	be 00 00 00 00       	mov    $0x0,%esi
f01021b2:	eb 55                	jmp    f0102209 <mem_init+0x1180>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01021b4:	8d 96 00 00 00 ef    	lea    -0x11000000(%esi),%edx
f01021ba:	89 d8                	mov    %ebx,%eax
f01021bc:	e8 65 e7 ff ff       	call   f0100926 <check_va2pa>
f01021c1:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f01021c8:	77 15                	ja     f01021df <mem_init+0x1156>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01021ca:	57                   	push   %edi
f01021cb:	68 d8 43 10 f0       	push   $0xf01043d8
f01021d0:	68 e1 02 00 00       	push   $0x2e1
f01021d5:	68 6d 4b 10 f0       	push   $0xf0104b6d
f01021da:	e8 c1 de ff ff       	call   f01000a0 <_panic>
f01021df:	8d 94 37 00 00 00 10 	lea    0x10000000(%edi,%esi,1),%edx
f01021e6:	39 d0                	cmp    %edx,%eax
f01021e8:	74 19                	je     f0102203 <mem_init+0x117a>
f01021ea:	68 a8 49 10 f0       	push   $0xf01049a8
f01021ef:	68 a2 4b 10 f0       	push   $0xf0104ba2
f01021f4:	68 e1 02 00 00       	push   $0x2e1
f01021f9:	68 6d 4b 10 f0       	push   $0xf0104b6d
f01021fe:	e8 9d de ff ff       	call   f01000a0 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102203:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102209:	39 75 d4             	cmp    %esi,-0x2c(%ebp)
f010220c:	77 a6                	ja     f01021b4 <mem_init+0x112b>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f010220e:	8b 3d 84 ef 16 f0    	mov    0xf016ef84,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102214:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0102217:	be 00 00 c0 ee       	mov    $0xeec00000,%esi
f010221c:	89 f2                	mov    %esi,%edx
f010221e:	89 d8                	mov    %ebx,%eax
f0102220:	e8 01 e7 ff ff       	call   f0100926 <check_va2pa>
f0102225:	81 7d d4 ff ff ff ef 	cmpl   $0xefffffff,-0x2c(%ebp)
f010222c:	77 15                	ja     f0102243 <mem_init+0x11ba>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010222e:	57                   	push   %edi
f010222f:	68 d8 43 10 f0       	push   $0xf01043d8
f0102234:	68 e6 02 00 00       	push   $0x2e6
f0102239:	68 6d 4b 10 f0       	push   $0xf0104b6d
f010223e:	e8 5d de ff ff       	call   f01000a0 <_panic>
f0102243:	8d 94 37 00 00 40 21 	lea    0x21400000(%edi,%esi,1),%edx
f010224a:	39 c2                	cmp    %eax,%edx
f010224c:	74 19                	je     f0102267 <mem_init+0x11de>
f010224e:	68 dc 49 10 f0       	push   $0xf01049dc
f0102253:	68 a2 4b 10 f0       	push   $0xf0104ba2
f0102258:	68 e6 02 00 00       	push   $0x2e6
f010225d:	68 6d 4b 10 f0       	push   $0xf0104b6d
f0102262:	e8 39 de ff ff       	call   f01000a0 <_panic>
f0102267:	81 c6 00 10 00 00    	add    $0x1000,%esi
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f010226d:	81 fe 00 80 c1 ee    	cmp    $0xeec18000,%esi
f0102273:	75 a7                	jne    f010221c <mem_init+0x1193>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102275:	8b 7d cc             	mov    -0x34(%ebp),%edi
f0102278:	c1 e7 0c             	shl    $0xc,%edi
f010227b:	be 00 00 00 00       	mov    $0x0,%esi
f0102280:	eb 30                	jmp    f01022b2 <mem_init+0x1229>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102282:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
f0102288:	89 d8                	mov    %ebx,%eax
f010228a:	e8 97 e6 ff ff       	call   f0100926 <check_va2pa>
f010228f:	39 c6                	cmp    %eax,%esi
f0102291:	74 19                	je     f01022ac <mem_init+0x1223>
f0102293:	68 10 4a 10 f0       	push   $0xf0104a10
f0102298:	68 a2 4b 10 f0       	push   $0xf0104ba2
f010229d:	68 ea 02 00 00       	push   $0x2ea
f01022a2:	68 6d 4b 10 f0       	push   $0xf0104b6d
f01022a7:	e8 f4 dd ff ff       	call   f01000a0 <_panic>
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01022ac:	81 c6 00 10 00 00    	add    $0x1000,%esi
f01022b2:	39 fe                	cmp    %edi,%esi
f01022b4:	72 cc                	jb     f0102282 <mem_init+0x11f9>
f01022b6:	be 00 80 ff ef       	mov    $0xefff8000,%esi
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f01022bb:	89 f2                	mov    %esi,%edx
f01022bd:	89 d8                	mov    %ebx,%eax
f01022bf:	e8 62 e6 ff ff       	call   f0100926 <check_va2pa>
f01022c4:	8d 96 00 70 11 10    	lea    0x10117000(%esi),%edx
f01022ca:	39 c2                	cmp    %eax,%edx
f01022cc:	74 19                	je     f01022e7 <mem_init+0x125e>
f01022ce:	68 38 4a 10 f0       	push   $0xf0104a38
f01022d3:	68 a2 4b 10 f0       	push   $0xf0104ba2
f01022d8:	68 ee 02 00 00       	push   $0x2ee
f01022dd:	68 6d 4b 10 f0       	push   $0xf0104b6d
f01022e2:	e8 b9 dd ff ff       	call   f01000a0 <_panic>
f01022e7:	81 c6 00 10 00 00    	add    $0x1000,%esi
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f01022ed:	81 fe 00 00 00 f0    	cmp    $0xf0000000,%esi
f01022f3:	75 c6                	jne    f01022bb <mem_init+0x1232>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f01022f5:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f01022fa:	89 d8                	mov    %ebx,%eax
f01022fc:	e8 25 e6 ff ff       	call   f0100926 <check_va2pa>
f0102301:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102304:	74 51                	je     f0102357 <mem_init+0x12ce>
f0102306:	68 80 4a 10 f0       	push   $0xf0104a80
f010230b:	68 a2 4b 10 f0       	push   $0xf0104ba2
f0102310:	68 ef 02 00 00       	push   $0x2ef
f0102315:	68 6d 4b 10 f0       	push   $0xf0104b6d
f010231a:	e8 81 dd ff ff       	call   f01000a0 <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f010231f:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f0102324:	72 36                	jb     f010235c <mem_init+0x12d3>
f0102326:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f010232b:	76 07                	jbe    f0102334 <mem_init+0x12ab>
f010232d:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102332:	75 28                	jne    f010235c <mem_init+0x12d3>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
		case PDX(UENVS):
			assert(pgdir[i] & PTE_P);
f0102334:	f6 04 83 01          	testb  $0x1,(%ebx,%eax,4)
f0102338:	0f 85 83 00 00 00    	jne    f01023c1 <mem_init+0x1338>
f010233e:	68 2f 4e 10 f0       	push   $0xf0104e2f
f0102343:	68 a2 4b 10 f0       	push   $0xf0104ba2
f0102348:	68 f8 02 00 00       	push   $0x2f8
f010234d:	68 6d 4b 10 f0       	push   $0xf0104b6d
f0102352:	e8 49 dd ff ff       	call   f01000a0 <_panic>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102357:	b8 00 00 00 00       	mov    $0x0,%eax
		case PDX(UPAGES):
		case PDX(UENVS):
			assert(pgdir[i] & PTE_P);
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f010235c:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102361:	76 3f                	jbe    f01023a2 <mem_init+0x1319>
				assert(pgdir[i] & PTE_P);
f0102363:	8b 14 83             	mov    (%ebx,%eax,4),%edx
f0102366:	f6 c2 01             	test   $0x1,%dl
f0102369:	75 19                	jne    f0102384 <mem_init+0x12fb>
f010236b:	68 2f 4e 10 f0       	push   $0xf0104e2f
f0102370:	68 a2 4b 10 f0       	push   $0xf0104ba2
f0102375:	68 fc 02 00 00       	push   $0x2fc
f010237a:	68 6d 4b 10 f0       	push   $0xf0104b6d
f010237f:	e8 1c dd ff ff       	call   f01000a0 <_panic>
				assert(pgdir[i] & PTE_W);
f0102384:	f6 c2 02             	test   $0x2,%dl
f0102387:	75 38                	jne    f01023c1 <mem_init+0x1338>
f0102389:	68 40 4e 10 f0       	push   $0xf0104e40
f010238e:	68 a2 4b 10 f0       	push   $0xf0104ba2
f0102393:	68 fd 02 00 00       	push   $0x2fd
f0102398:	68 6d 4b 10 f0       	push   $0xf0104b6d
f010239d:	e8 fe dc ff ff       	call   f01000a0 <_panic>
			} else
				assert(pgdir[i] == 0);
f01023a2:	83 3c 83 00          	cmpl   $0x0,(%ebx,%eax,4)
f01023a6:	74 19                	je     f01023c1 <mem_init+0x1338>
f01023a8:	68 51 4e 10 f0       	push   $0xf0104e51
f01023ad:	68 a2 4b 10 f0       	push   $0xf0104ba2
f01023b2:	68 ff 02 00 00       	push   $0x2ff
f01023b7:	68 6d 4b 10 f0       	push   $0xf0104b6d
f01023bc:	e8 df dc ff ff       	call   f01000a0 <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f01023c1:	83 c0 01             	add    $0x1,%eax
f01023c4:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f01023c9:	0f 86 50 ff ff ff    	jbe    f010231f <mem_init+0x1296>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f01023cf:	83 ec 0c             	sub    $0xc,%esp
f01023d2:	68 b0 4a 10 f0       	push   $0xf0104ab0
f01023d7:	e8 c6 07 00 00       	call   f0102ba2 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f01023dc:	a1 48 fc 16 f0       	mov    0xf016fc48,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01023e1:	83 c4 10             	add    $0x10,%esp
f01023e4:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01023e9:	77 15                	ja     f0102400 <mem_init+0x1377>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01023eb:	50                   	push   %eax
f01023ec:	68 d8 43 10 f0       	push   $0xf01043d8
f01023f1:	68 e6 00 00 00       	push   $0xe6
f01023f6:	68 6d 4b 10 f0       	push   $0xf0104b6d
f01023fb:	e8 a0 dc ff ff       	call   f01000a0 <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0102400:	05 00 00 00 10       	add    $0x10000000,%eax
f0102405:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f0102408:	b8 00 00 00 00       	mov    $0x0,%eax
f010240d:	e8 ff e5 ff ff       	call   f0100a11 <check_page_free_list>

static inline uint32_t
rcr0(void)
{
	uint32_t val;
	asm volatile("movl %%cr0,%0" : "=r" (val));
f0102412:	0f 20 c0             	mov    %cr0,%eax
f0102415:	83 e0 f3             	and    $0xfffffff3,%eax
}

static inline void
lcr0(uint32_t val)
{
	asm volatile("movl %0,%%cr0" : : "r" (val));
f0102418:	0d 23 00 05 80       	or     $0x80050023,%eax
f010241d:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102420:	83 ec 0c             	sub    $0xc,%esp
f0102423:	6a 00                	push   $0x0
f0102425:	e8 8e e9 ff ff       	call   f0100db8 <page_alloc>
f010242a:	89 c3                	mov    %eax,%ebx
f010242c:	83 c4 10             	add    $0x10,%esp
f010242f:	85 c0                	test   %eax,%eax
f0102431:	75 19                	jne    f010244c <mem_init+0x13c3>
f0102433:	68 4d 4c 10 f0       	push   $0xf0104c4d
f0102438:	68 a2 4b 10 f0       	push   $0xf0104ba2
f010243d:	68 bf 03 00 00       	push   $0x3bf
f0102442:	68 6d 4b 10 f0       	push   $0xf0104b6d
f0102447:	e8 54 dc ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f010244c:	83 ec 0c             	sub    $0xc,%esp
f010244f:	6a 00                	push   $0x0
f0102451:	e8 62 e9 ff ff       	call   f0100db8 <page_alloc>
f0102456:	89 c7                	mov    %eax,%edi
f0102458:	83 c4 10             	add    $0x10,%esp
f010245b:	85 c0                	test   %eax,%eax
f010245d:	75 19                	jne    f0102478 <mem_init+0x13ef>
f010245f:	68 63 4c 10 f0       	push   $0xf0104c63
f0102464:	68 a2 4b 10 f0       	push   $0xf0104ba2
f0102469:	68 c0 03 00 00       	push   $0x3c0
f010246e:	68 6d 4b 10 f0       	push   $0xf0104b6d
f0102473:	e8 28 dc ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f0102478:	83 ec 0c             	sub    $0xc,%esp
f010247b:	6a 00                	push   $0x0
f010247d:	e8 36 e9 ff ff       	call   f0100db8 <page_alloc>
f0102482:	89 c6                	mov    %eax,%esi
f0102484:	83 c4 10             	add    $0x10,%esp
f0102487:	85 c0                	test   %eax,%eax
f0102489:	75 19                	jne    f01024a4 <mem_init+0x141b>
f010248b:	68 79 4c 10 f0       	push   $0xf0104c79
f0102490:	68 a2 4b 10 f0       	push   $0xf0104ba2
f0102495:	68 c1 03 00 00       	push   $0x3c1
f010249a:	68 6d 4b 10 f0       	push   $0xf0104b6d
f010249f:	e8 fc db ff ff       	call   f01000a0 <_panic>
	page_free(pp0);
f01024a4:	83 ec 0c             	sub    $0xc,%esp
f01024a7:	53                   	push   %ebx
f01024a8:	e8 82 e9 ff ff       	call   f0100e2f <page_free>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01024ad:	89 f8                	mov    %edi,%eax
f01024af:	2b 05 4c fc 16 f0    	sub    0xf016fc4c,%eax
f01024b5:	c1 f8 03             	sar    $0x3,%eax
f01024b8:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01024bb:	89 c2                	mov    %eax,%edx
f01024bd:	c1 ea 0c             	shr    $0xc,%edx
f01024c0:	83 c4 10             	add    $0x10,%esp
f01024c3:	3b 15 44 fc 16 f0    	cmp    0xf016fc44,%edx
f01024c9:	72 12                	jb     f01024dd <mem_init+0x1454>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01024cb:	50                   	push   %eax
f01024cc:	68 b4 43 10 f0       	push   $0xf01043b4
f01024d1:	6a 56                	push   $0x56
f01024d3:	68 88 4b 10 f0       	push   $0xf0104b88
f01024d8:	e8 c3 db ff ff       	call   f01000a0 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f01024dd:	83 ec 04             	sub    $0x4,%esp
f01024e0:	68 00 10 00 00       	push   $0x1000
f01024e5:	6a 01                	push   $0x1
f01024e7:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01024ec:	50                   	push   %eax
f01024ed:	e8 34 15 00 00       	call   f0103a26 <memset>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01024f2:	89 f0                	mov    %esi,%eax
f01024f4:	2b 05 4c fc 16 f0    	sub    0xf016fc4c,%eax
f01024fa:	c1 f8 03             	sar    $0x3,%eax
f01024fd:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102500:	89 c2                	mov    %eax,%edx
f0102502:	c1 ea 0c             	shr    $0xc,%edx
f0102505:	83 c4 10             	add    $0x10,%esp
f0102508:	3b 15 44 fc 16 f0    	cmp    0xf016fc44,%edx
f010250e:	72 12                	jb     f0102522 <mem_init+0x1499>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102510:	50                   	push   %eax
f0102511:	68 b4 43 10 f0       	push   $0xf01043b4
f0102516:	6a 56                	push   $0x56
f0102518:	68 88 4b 10 f0       	push   $0xf0104b88
f010251d:	e8 7e db ff ff       	call   f01000a0 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f0102522:	83 ec 04             	sub    $0x4,%esp
f0102525:	68 00 10 00 00       	push   $0x1000
f010252a:	6a 02                	push   $0x2
f010252c:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102531:	50                   	push   %eax
f0102532:	e8 ef 14 00 00       	call   f0103a26 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102537:	6a 02                	push   $0x2
f0102539:	68 00 10 00 00       	push   $0x1000
f010253e:	57                   	push   %edi
f010253f:	ff 35 48 fc 16 f0    	pushl  0xf016fc48
f0102545:	e8 d3 ea ff ff       	call   f010101d <page_insert>
	assert(pp1->pp_ref == 1);
f010254a:	83 c4 20             	add    $0x20,%esp
f010254d:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102552:	74 19                	je     f010256d <mem_init+0x14e4>
f0102554:	68 4a 4d 10 f0       	push   $0xf0104d4a
f0102559:	68 a2 4b 10 f0       	push   $0xf0104ba2
f010255e:	68 c6 03 00 00       	push   $0x3c6
f0102563:	68 6d 4b 10 f0       	push   $0xf0104b6d
f0102568:	e8 33 db ff ff       	call   f01000a0 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f010256d:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102574:	01 01 01 
f0102577:	74 19                	je     f0102592 <mem_init+0x1509>
f0102579:	68 d0 4a 10 f0       	push   $0xf0104ad0
f010257e:	68 a2 4b 10 f0       	push   $0xf0104ba2
f0102583:	68 c7 03 00 00       	push   $0x3c7
f0102588:	68 6d 4b 10 f0       	push   $0xf0104b6d
f010258d:	e8 0e db ff ff       	call   f01000a0 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102592:	6a 02                	push   $0x2
f0102594:	68 00 10 00 00       	push   $0x1000
f0102599:	56                   	push   %esi
f010259a:	ff 35 48 fc 16 f0    	pushl  0xf016fc48
f01025a0:	e8 78 ea ff ff       	call   f010101d <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f01025a5:	83 c4 10             	add    $0x10,%esp
f01025a8:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f01025af:	02 02 02 
f01025b2:	74 19                	je     f01025cd <mem_init+0x1544>
f01025b4:	68 f4 4a 10 f0       	push   $0xf0104af4
f01025b9:	68 a2 4b 10 f0       	push   $0xf0104ba2
f01025be:	68 c9 03 00 00       	push   $0x3c9
f01025c3:	68 6d 4b 10 f0       	push   $0xf0104b6d
f01025c8:	e8 d3 da ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f01025cd:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01025d2:	74 19                	je     f01025ed <mem_init+0x1564>
f01025d4:	68 6c 4d 10 f0       	push   $0xf0104d6c
f01025d9:	68 a2 4b 10 f0       	push   $0xf0104ba2
f01025de:	68 ca 03 00 00       	push   $0x3ca
f01025e3:	68 6d 4b 10 f0       	push   $0xf0104b6d
f01025e8:	e8 b3 da ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 0);
f01025ed:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f01025f2:	74 19                	je     f010260d <mem_init+0x1584>
f01025f4:	68 d6 4d 10 f0       	push   $0xf0104dd6
f01025f9:	68 a2 4b 10 f0       	push   $0xf0104ba2
f01025fe:	68 cb 03 00 00       	push   $0x3cb
f0102603:	68 6d 4b 10 f0       	push   $0xf0104b6d
f0102608:	e8 93 da ff ff       	call   f01000a0 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f010260d:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102614:	03 03 03 
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102617:	89 f0                	mov    %esi,%eax
f0102619:	2b 05 4c fc 16 f0    	sub    0xf016fc4c,%eax
f010261f:	c1 f8 03             	sar    $0x3,%eax
f0102622:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102625:	89 c2                	mov    %eax,%edx
f0102627:	c1 ea 0c             	shr    $0xc,%edx
f010262a:	3b 15 44 fc 16 f0    	cmp    0xf016fc44,%edx
f0102630:	72 12                	jb     f0102644 <mem_init+0x15bb>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102632:	50                   	push   %eax
f0102633:	68 b4 43 10 f0       	push   $0xf01043b4
f0102638:	6a 56                	push   $0x56
f010263a:	68 88 4b 10 f0       	push   $0xf0104b88
f010263f:	e8 5c da ff ff       	call   f01000a0 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102644:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f010264b:	03 03 03 
f010264e:	74 19                	je     f0102669 <mem_init+0x15e0>
f0102650:	68 18 4b 10 f0       	push   $0xf0104b18
f0102655:	68 a2 4b 10 f0       	push   $0xf0104ba2
f010265a:	68 cd 03 00 00       	push   $0x3cd
f010265f:	68 6d 4b 10 f0       	push   $0xf0104b6d
f0102664:	e8 37 da ff ff       	call   f01000a0 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102669:	83 ec 08             	sub    $0x8,%esp
f010266c:	68 00 10 00 00       	push   $0x1000
f0102671:	ff 35 48 fc 16 f0    	pushl  0xf016fc48
f0102677:	e8 66 e9 ff ff       	call   f0100fe2 <page_remove>
	assert(pp2->pp_ref == 0);
f010267c:	83 c4 10             	add    $0x10,%esp
f010267f:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102684:	74 19                	je     f010269f <mem_init+0x1616>
f0102686:	68 a4 4d 10 f0       	push   $0xf0104da4
f010268b:	68 a2 4b 10 f0       	push   $0xf0104ba2
f0102690:	68 cf 03 00 00       	push   $0x3cf
f0102695:	68 6d 4b 10 f0       	push   $0xf0104b6d
f010269a:	e8 01 da ff ff       	call   f01000a0 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010269f:	8b 0d 48 fc 16 f0    	mov    0xf016fc48,%ecx
f01026a5:	8b 11                	mov    (%ecx),%edx
f01026a7:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01026ad:	89 d8                	mov    %ebx,%eax
f01026af:	2b 05 4c fc 16 f0    	sub    0xf016fc4c,%eax
f01026b5:	c1 f8 03             	sar    $0x3,%eax
f01026b8:	c1 e0 0c             	shl    $0xc,%eax
f01026bb:	39 c2                	cmp    %eax,%edx
f01026bd:	74 19                	je     f01026d8 <mem_init+0x164f>
f01026bf:	68 28 46 10 f0       	push   $0xf0104628
f01026c4:	68 a2 4b 10 f0       	push   $0xf0104ba2
f01026c9:	68 d2 03 00 00       	push   $0x3d2
f01026ce:	68 6d 4b 10 f0       	push   $0xf0104b6d
f01026d3:	e8 c8 d9 ff ff       	call   f01000a0 <_panic>
	kern_pgdir[0] = 0;
f01026d8:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f01026de:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01026e3:	74 19                	je     f01026fe <mem_init+0x1675>
f01026e5:	68 5b 4d 10 f0       	push   $0xf0104d5b
f01026ea:	68 a2 4b 10 f0       	push   $0xf0104ba2
f01026ef:	68 d4 03 00 00       	push   $0x3d4
f01026f4:	68 6d 4b 10 f0       	push   $0xf0104b6d
f01026f9:	e8 a2 d9 ff ff       	call   f01000a0 <_panic>
	pp0->pp_ref = 0;
f01026fe:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f0102704:	83 ec 0c             	sub    $0xc,%esp
f0102707:	53                   	push   %ebx
f0102708:	e8 22 e7 ff ff       	call   f0100e2f <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f010270d:	c7 04 24 44 4b 10 f0 	movl   $0xf0104b44,(%esp)
f0102714:	e8 89 04 00 00       	call   f0102ba2 <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f0102719:	83 c4 10             	add    $0x10,%esp
f010271c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010271f:	5b                   	pop    %ebx
f0102720:	5e                   	pop    %esi
f0102721:	5f                   	pop    %edi
f0102722:	5d                   	pop    %ebp
f0102723:	c3                   	ret    

f0102724 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0102724:	55                   	push   %ebp
f0102725:	89 e5                	mov    %esp,%ebp
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0102727:	8b 45 0c             	mov    0xc(%ebp),%eax
f010272a:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f010272d:	5d                   	pop    %ebp
f010272e:	c3                   	ret    

f010272f <user_mem_check>:
// Returns 0 if the user program can access this range of addresses,
// and -E_FAULT otherwise.
//
int
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
f010272f:	55                   	push   %ebp
f0102730:	89 e5                	mov    %esp,%ebp
	// LAB 3: Your code here.

	return 0;
}
f0102732:	b8 00 00 00 00       	mov    $0x0,%eax
f0102737:	5d                   	pop    %ebp
f0102738:	c3                   	ret    

f0102739 <user_mem_assert>:
// If it cannot, 'env' is destroyed and, if env is the current
// environment, this function will not return.
//
void
user_mem_assert(struct Env *env, const void *va, size_t len, int perm)
{
f0102739:	55                   	push   %ebp
f010273a:	89 e5                	mov    %esp,%ebp
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
		cprintf("[%08x] user_mem_check assertion failure for "
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
	}
}
f010273c:	5d                   	pop    %ebp
f010273d:	c3                   	ret    

f010273e <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f010273e:	55                   	push   %ebp
f010273f:	89 e5                	mov    %esp,%ebp
f0102741:	8b 55 08             	mov    0x8(%ebp),%edx
f0102744:	8b 4d 10             	mov    0x10(%ebp),%ecx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f0102747:	85 d2                	test   %edx,%edx
f0102749:	75 11                	jne    f010275c <envid2env+0x1e>
		*env_store = curenv;
f010274b:	a1 80 ef 16 f0       	mov    0xf016ef80,%eax
f0102750:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0102753:	89 01                	mov    %eax,(%ecx)
		return 0;
f0102755:	b8 00 00 00 00       	mov    $0x0,%eax
f010275a:	eb 5e                	jmp    f01027ba <envid2env+0x7c>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f010275c:	89 d0                	mov    %edx,%eax
f010275e:	25 ff 03 00 00       	and    $0x3ff,%eax
f0102763:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0102766:	c1 e0 05             	shl    $0x5,%eax
f0102769:	03 05 84 ef 16 f0    	add    0xf016ef84,%eax
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f010276f:	83 78 54 00          	cmpl   $0x0,0x54(%eax)
f0102773:	74 05                	je     f010277a <envid2env+0x3c>
f0102775:	3b 50 48             	cmp    0x48(%eax),%edx
f0102778:	74 10                	je     f010278a <envid2env+0x4c>
		*env_store = 0;
f010277a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010277d:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0102783:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0102788:	eb 30                	jmp    f01027ba <envid2env+0x7c>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f010278a:	84 c9                	test   %cl,%cl
f010278c:	74 22                	je     f01027b0 <envid2env+0x72>
f010278e:	8b 15 80 ef 16 f0    	mov    0xf016ef80,%edx
f0102794:	39 d0                	cmp    %edx,%eax
f0102796:	74 18                	je     f01027b0 <envid2env+0x72>
f0102798:	8b 4a 48             	mov    0x48(%edx),%ecx
f010279b:	39 48 4c             	cmp    %ecx,0x4c(%eax)
f010279e:	74 10                	je     f01027b0 <envid2env+0x72>
		*env_store = 0;
f01027a0:	8b 45 0c             	mov    0xc(%ebp),%eax
f01027a3:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f01027a9:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f01027ae:	eb 0a                	jmp    f01027ba <envid2env+0x7c>
	}

	*env_store = e;
f01027b0:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01027b3:	89 01                	mov    %eax,(%ecx)
	return 0;
f01027b5:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01027ba:	5d                   	pop    %ebp
f01027bb:	c3                   	ret    

f01027bc <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f01027bc:	55                   	push   %ebp
f01027bd:	89 e5                	mov    %esp,%ebp
}

static inline void
lgdt(void *p)
{
	asm volatile("lgdt (%0)" : : "r" (p));
f01027bf:	b8 00 93 11 f0       	mov    $0xf0119300,%eax
f01027c4:	0f 01 10             	lgdtl  (%eax)
	lgdt(&gdt_pd);
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" : : "a" (GD_UD|3));
f01027c7:	b8 23 00 00 00       	mov    $0x23,%eax
f01027cc:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" : : "a" (GD_UD|3));
f01027ce:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" : : "a" (GD_KD));
f01027d0:	b8 10 00 00 00       	mov    $0x10,%eax
f01027d5:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" : : "a" (GD_KD));
f01027d7:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" : : "a" (GD_KD));
f01027d9:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" : : "i" (GD_KT));
f01027db:	ea e2 27 10 f0 08 00 	ljmp   $0x8,$0xf01027e2
}

static inline void
lldt(uint16_t sel)
{
	asm volatile("lldt %0" : : "r" (sel));
f01027e2:	b8 00 00 00 00       	mov    $0x0,%eax
f01027e7:	0f 00 d0             	lldt   %ax
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
}
f01027ea:	5d                   	pop    %ebp
f01027eb:	c3                   	ret    

f01027ec <env_init>:
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f01027ec:	55                   	push   %ebp
f01027ed:	89 e5                	mov    %esp,%ebp
	// Set up envs array
	// LAB 3: Your code here.

	// Per-CPU part of the initialization
	env_init_percpu();
f01027ef:	e8 c8 ff ff ff       	call   f01027bc <env_init_percpu>
}
f01027f4:	5d                   	pop    %ebp
f01027f5:	c3                   	ret    

f01027f6 <env_alloc>:
//	-E_NO_FREE_ENV if all NENVS environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f01027f6:	55                   	push   %ebp
f01027f7:	89 e5                	mov    %esp,%ebp
f01027f9:	53                   	push   %ebx
f01027fa:	83 ec 04             	sub    $0x4,%esp
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f01027fd:	8b 1d 88 ef 16 f0    	mov    0xf016ef88,%ebx
f0102803:	85 db                	test   %ebx,%ebx
f0102805:	0f 84 f4 00 00 00    	je     f01028ff <env_alloc+0x109>
{
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
f010280b:	83 ec 0c             	sub    $0xc,%esp
f010280e:	6a 01                	push   $0x1
f0102810:	e8 a3 e5 ff ff       	call   f0100db8 <page_alloc>
f0102815:	83 c4 10             	add    $0x10,%esp
f0102818:	85 c0                	test   %eax,%eax
f010281a:	0f 84 e6 00 00 00    	je     f0102906 <env_alloc+0x110>

	// LAB 3: Your code here.

	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f0102820:	8b 43 5c             	mov    0x5c(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102823:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102828:	77 15                	ja     f010283f <env_alloc+0x49>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010282a:	50                   	push   %eax
f010282b:	68 d8 43 10 f0       	push   $0xf01043d8
f0102830:	68 b9 00 00 00       	push   $0xb9
f0102835:	68 96 4e 10 f0       	push   $0xf0104e96
f010283a:	e8 61 d8 ff ff       	call   f01000a0 <_panic>
f010283f:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0102845:	83 ca 05             	or     $0x5,%edx
f0102848:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f010284e:	8b 43 48             	mov    0x48(%ebx),%eax
f0102851:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f0102856:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f010285b:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102860:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f0102863:	89 da                	mov    %ebx,%edx
f0102865:	2b 15 84 ef 16 f0    	sub    0xf016ef84,%edx
f010286b:	c1 fa 05             	sar    $0x5,%edx
f010286e:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f0102874:	09 d0                	or     %edx,%eax
f0102876:	89 43 48             	mov    %eax,0x48(%ebx)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f0102879:	8b 45 0c             	mov    0xc(%ebp),%eax
f010287c:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f010287f:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f0102886:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f010288d:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f0102894:	83 ec 04             	sub    $0x4,%esp
f0102897:	6a 44                	push   $0x44
f0102899:	6a 00                	push   $0x0
f010289b:	53                   	push   %ebx
f010289c:	e8 85 11 00 00       	call   f0103a26 <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f01028a1:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f01028a7:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f01028ad:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f01028b3:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f01028ba:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)
	// You will set e->env_tf.tf_eip later.

	// commit the allocation
	env_free_list = e->env_link;
f01028c0:	8b 43 44             	mov    0x44(%ebx),%eax
f01028c3:	a3 88 ef 16 f0       	mov    %eax,0xf016ef88
	*newenv_store = e;
f01028c8:	8b 45 08             	mov    0x8(%ebp),%eax
f01028cb:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f01028cd:	8b 53 48             	mov    0x48(%ebx),%edx
f01028d0:	a1 80 ef 16 f0       	mov    0xf016ef80,%eax
f01028d5:	83 c4 10             	add    $0x10,%esp
f01028d8:	85 c0                	test   %eax,%eax
f01028da:	74 05                	je     f01028e1 <env_alloc+0xeb>
f01028dc:	8b 40 48             	mov    0x48(%eax),%eax
f01028df:	eb 05                	jmp    f01028e6 <env_alloc+0xf0>
f01028e1:	b8 00 00 00 00       	mov    $0x0,%eax
f01028e6:	83 ec 04             	sub    $0x4,%esp
f01028e9:	52                   	push   %edx
f01028ea:	50                   	push   %eax
f01028eb:	68 a1 4e 10 f0       	push   $0xf0104ea1
f01028f0:	e8 ad 02 00 00       	call   f0102ba2 <cprintf>
	return 0;
f01028f5:	83 c4 10             	add    $0x10,%esp
f01028f8:	b8 00 00 00 00       	mov    $0x0,%eax
f01028fd:	eb 0c                	jmp    f010290b <env_alloc+0x115>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f01028ff:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f0102904:	eb 05                	jmp    f010290b <env_alloc+0x115>
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f0102906:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	env_free_list = e->env_link;
	*newenv_store = e;

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f010290b:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010290e:	c9                   	leave  
f010290f:	c3                   	ret    

f0102910 <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f0102910:	55                   	push   %ebp
f0102911:	89 e5                	mov    %esp,%ebp
	// LAB 3: Your code here.
}
f0102913:	5d                   	pop    %ebp
f0102914:	c3                   	ret    

f0102915 <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f0102915:	55                   	push   %ebp
f0102916:	89 e5                	mov    %esp,%ebp
f0102918:	57                   	push   %edi
f0102919:	56                   	push   %esi
f010291a:	53                   	push   %ebx
f010291b:	83 ec 1c             	sub    $0x1c,%esp
f010291e:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f0102921:	8b 15 80 ef 16 f0    	mov    0xf016ef80,%edx
f0102927:	39 fa                	cmp    %edi,%edx
f0102929:	75 29                	jne    f0102954 <env_free+0x3f>
		lcr3(PADDR(kern_pgdir));
f010292b:	a1 48 fc 16 f0       	mov    0xf016fc48,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102930:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102935:	77 15                	ja     f010294c <env_free+0x37>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102937:	50                   	push   %eax
f0102938:	68 d8 43 10 f0       	push   $0xf01043d8
f010293d:	68 68 01 00 00       	push   $0x168
f0102942:	68 96 4e 10 f0       	push   $0xf0104e96
f0102947:	e8 54 d7 ff ff       	call   f01000a0 <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f010294c:	05 00 00 00 10       	add    $0x10000000,%eax
f0102951:	0f 22 d8             	mov    %eax,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0102954:	8b 4f 48             	mov    0x48(%edi),%ecx
f0102957:	85 d2                	test   %edx,%edx
f0102959:	74 05                	je     f0102960 <env_free+0x4b>
f010295b:	8b 42 48             	mov    0x48(%edx),%eax
f010295e:	eb 05                	jmp    f0102965 <env_free+0x50>
f0102960:	b8 00 00 00 00       	mov    $0x0,%eax
f0102965:	83 ec 04             	sub    $0x4,%esp
f0102968:	51                   	push   %ecx
f0102969:	50                   	push   %eax
f010296a:	68 b6 4e 10 f0       	push   $0xf0104eb6
f010296f:	e8 2e 02 00 00       	call   f0102ba2 <cprintf>
f0102974:	83 c4 10             	add    $0x10,%esp

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0102977:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f010297e:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0102981:	89 d0                	mov    %edx,%eax
f0102983:	c1 e0 02             	shl    $0x2,%eax
f0102986:	89 45 dc             	mov    %eax,-0x24(%ebp)

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f0102989:	8b 47 5c             	mov    0x5c(%edi),%eax
f010298c:	8b 34 90             	mov    (%eax,%edx,4),%esi
f010298f:	f7 c6 01 00 00 00    	test   $0x1,%esi
f0102995:	0f 84 a8 00 00 00    	je     f0102a43 <env_free+0x12e>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f010299b:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01029a1:	89 f0                	mov    %esi,%eax
f01029a3:	c1 e8 0c             	shr    $0xc,%eax
f01029a6:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01029a9:	39 05 44 fc 16 f0    	cmp    %eax,0xf016fc44
f01029af:	77 15                	ja     f01029c6 <env_free+0xb1>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01029b1:	56                   	push   %esi
f01029b2:	68 b4 43 10 f0       	push   $0xf01043b4
f01029b7:	68 77 01 00 00       	push   $0x177
f01029bc:	68 96 4e 10 f0       	push   $0xf0104e96
f01029c1:	e8 da d6 ff ff       	call   f01000a0 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f01029c6:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01029c9:	c1 e0 16             	shl    $0x16,%eax
f01029cc:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f01029cf:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f01029d4:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f01029db:	01 
f01029dc:	74 17                	je     f01029f5 <env_free+0xe0>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f01029de:	83 ec 08             	sub    $0x8,%esp
f01029e1:	89 d8                	mov    %ebx,%eax
f01029e3:	c1 e0 0c             	shl    $0xc,%eax
f01029e6:	0b 45 e4             	or     -0x1c(%ebp),%eax
f01029e9:	50                   	push   %eax
f01029ea:	ff 77 5c             	pushl  0x5c(%edi)
f01029ed:	e8 f0 e5 ff ff       	call   f0100fe2 <page_remove>
f01029f2:	83 c4 10             	add    $0x10,%esp
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f01029f5:	83 c3 01             	add    $0x1,%ebx
f01029f8:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f01029fe:	75 d4                	jne    f01029d4 <env_free+0xbf>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f0102a00:	8b 47 5c             	mov    0x5c(%edi),%eax
f0102a03:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102a06:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102a0d:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102a10:	3b 05 44 fc 16 f0    	cmp    0xf016fc44,%eax
f0102a16:	72 14                	jb     f0102a2c <env_free+0x117>
		panic("pa2page called with invalid pa");
f0102a18:	83 ec 04             	sub    $0x4,%esp
f0102a1b:	68 f4 44 10 f0       	push   $0xf01044f4
f0102a20:	6a 4f                	push   $0x4f
f0102a22:	68 88 4b 10 f0       	push   $0xf0104b88
f0102a27:	e8 74 d6 ff ff       	call   f01000a0 <_panic>
		page_decref(pa2page(pa));
f0102a2c:	83 ec 0c             	sub    $0xc,%esp
f0102a2f:	a1 4c fc 16 f0       	mov    0xf016fc4c,%eax
f0102a34:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102a37:	8d 04 d0             	lea    (%eax,%edx,8),%eax
f0102a3a:	50                   	push   %eax
f0102a3b:	e8 2a e4 ff ff       	call   f0100e6a <page_decref>
f0102a40:	83 c4 10             	add    $0x10,%esp
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0102a43:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f0102a47:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102a4a:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f0102a4f:	0f 85 29 ff ff ff    	jne    f010297e <env_free+0x69>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f0102a55:	8b 47 5c             	mov    0x5c(%edi),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102a58:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102a5d:	77 15                	ja     f0102a74 <env_free+0x15f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102a5f:	50                   	push   %eax
f0102a60:	68 d8 43 10 f0       	push   $0xf01043d8
f0102a65:	68 85 01 00 00       	push   $0x185
f0102a6a:	68 96 4e 10 f0       	push   $0xf0104e96
f0102a6f:	e8 2c d6 ff ff       	call   f01000a0 <_panic>
	e->env_pgdir = 0;
f0102a74:	c7 47 5c 00 00 00 00 	movl   $0x0,0x5c(%edi)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102a7b:	05 00 00 00 10       	add    $0x10000000,%eax
f0102a80:	c1 e8 0c             	shr    $0xc,%eax
f0102a83:	3b 05 44 fc 16 f0    	cmp    0xf016fc44,%eax
f0102a89:	72 14                	jb     f0102a9f <env_free+0x18a>
		panic("pa2page called with invalid pa");
f0102a8b:	83 ec 04             	sub    $0x4,%esp
f0102a8e:	68 f4 44 10 f0       	push   $0xf01044f4
f0102a93:	6a 4f                	push   $0x4f
f0102a95:	68 88 4b 10 f0       	push   $0xf0104b88
f0102a9a:	e8 01 d6 ff ff       	call   f01000a0 <_panic>
	page_decref(pa2page(pa));
f0102a9f:	83 ec 0c             	sub    $0xc,%esp
f0102aa2:	8b 15 4c fc 16 f0    	mov    0xf016fc4c,%edx
f0102aa8:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f0102aab:	50                   	push   %eax
f0102aac:	e8 b9 e3 ff ff       	call   f0100e6a <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f0102ab1:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f0102ab8:	a1 88 ef 16 f0       	mov    0xf016ef88,%eax
f0102abd:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f0102ac0:	89 3d 88 ef 16 f0    	mov    %edi,0xf016ef88
}
f0102ac6:	83 c4 10             	add    $0x10,%esp
f0102ac9:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102acc:	5b                   	pop    %ebx
f0102acd:	5e                   	pop    %esi
f0102ace:	5f                   	pop    %edi
f0102acf:	5d                   	pop    %ebp
f0102ad0:	c3                   	ret    

f0102ad1 <env_destroy>:
//
// Frees environment e.
//
void
env_destroy(struct Env *e)
{
f0102ad1:	55                   	push   %ebp
f0102ad2:	89 e5                	mov    %esp,%ebp
f0102ad4:	83 ec 14             	sub    $0x14,%esp
	env_free(e);
f0102ad7:	ff 75 08             	pushl  0x8(%ebp)
f0102ada:	e8 36 fe ff ff       	call   f0102915 <env_free>

	cprintf("Destroyed the only environment - nothing more to do!\n");
f0102adf:	c7 04 24 60 4e 10 f0 	movl   $0xf0104e60,(%esp)
f0102ae6:	e8 b7 00 00 00       	call   f0102ba2 <cprintf>
f0102aeb:	83 c4 10             	add    $0x10,%esp
	while (1)
		monitor(NULL);
f0102aee:	83 ec 0c             	sub    $0xc,%esp
f0102af1:	6a 00                	push   $0x0
f0102af3:	e8 aa dc ff ff       	call   f01007a2 <monitor>
f0102af8:	83 c4 10             	add    $0x10,%esp
f0102afb:	eb f1                	jmp    f0102aee <env_destroy+0x1d>

f0102afd <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f0102afd:	55                   	push   %ebp
f0102afe:	89 e5                	mov    %esp,%ebp
f0102b00:	83 ec 0c             	sub    $0xc,%esp
	asm volatile(
f0102b03:	8b 65 08             	mov    0x8(%ebp),%esp
f0102b06:	61                   	popa   
f0102b07:	07                   	pop    %es
f0102b08:	1f                   	pop    %ds
f0102b09:	83 c4 08             	add    $0x8,%esp
f0102b0c:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret\n"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f0102b0d:	68 cc 4e 10 f0       	push   $0xf0104ecc
f0102b12:	68 ae 01 00 00       	push   $0x1ae
f0102b17:	68 96 4e 10 f0       	push   $0xf0104e96
f0102b1c:	e8 7f d5 ff ff       	call   f01000a0 <_panic>

f0102b21 <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f0102b21:	55                   	push   %ebp
f0102b22:	89 e5                	mov    %esp,%ebp
f0102b24:	83 ec 0c             	sub    $0xc,%esp
	//	and make sure you have set the relevant parts of
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.

	panic("env_run not yet implemented");
f0102b27:	68 d8 4e 10 f0       	push   $0xf0104ed8
f0102b2c:	68 cd 01 00 00       	push   $0x1cd
f0102b31:	68 96 4e 10 f0       	push   $0xf0104e96
f0102b36:	e8 65 d5 ff ff       	call   f01000a0 <_panic>

f0102b3b <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102b3b:	55                   	push   %ebp
f0102b3c:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102b3e:	ba 70 00 00 00       	mov    $0x70,%edx
f0102b43:	8b 45 08             	mov    0x8(%ebp),%eax
f0102b46:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102b47:	ba 71 00 00 00       	mov    $0x71,%edx
f0102b4c:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0102b4d:	0f b6 c0             	movzbl %al,%eax
}
f0102b50:	5d                   	pop    %ebp
f0102b51:	c3                   	ret    

f0102b52 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102b52:	55                   	push   %ebp
f0102b53:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102b55:	ba 70 00 00 00       	mov    $0x70,%edx
f0102b5a:	8b 45 08             	mov    0x8(%ebp),%eax
f0102b5d:	ee                   	out    %al,(%dx)
f0102b5e:	ba 71 00 00 00       	mov    $0x71,%edx
f0102b63:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102b66:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0102b67:	5d                   	pop    %ebp
f0102b68:	c3                   	ret    

f0102b69 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0102b69:	55                   	push   %ebp
f0102b6a:	89 e5                	mov    %esp,%ebp
f0102b6c:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0102b6f:	ff 75 08             	pushl  0x8(%ebp)
f0102b72:	e8 9e da ff ff       	call   f0100615 <cputchar>
	*cnt++;
}
f0102b77:	83 c4 10             	add    $0x10,%esp
f0102b7a:	c9                   	leave  
f0102b7b:	c3                   	ret    

f0102b7c <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0102b7c:	55                   	push   %ebp
f0102b7d:	89 e5                	mov    %esp,%ebp
f0102b7f:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0102b82:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0102b89:	ff 75 0c             	pushl  0xc(%ebp)
f0102b8c:	ff 75 08             	pushl  0x8(%ebp)
f0102b8f:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102b92:	50                   	push   %eax
f0102b93:	68 69 2b 10 f0       	push   $0xf0102b69
f0102b98:	e8 1d 08 00 00       	call   f01033ba <vprintfmt>
	return cnt;
}
f0102b9d:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102ba0:	c9                   	leave  
f0102ba1:	c3                   	ret    

f0102ba2 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0102ba2:	55                   	push   %ebp
f0102ba3:	89 e5                	mov    %esp,%ebp
f0102ba5:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0102ba8:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102bab:	50                   	push   %eax
f0102bac:	ff 75 08             	pushl  0x8(%ebp)
f0102baf:	e8 c8 ff ff ff       	call   f0102b7c <vcprintf>
	va_end(ap);

	return cnt;
}
f0102bb4:	c9                   	leave  
f0102bb5:	c3                   	ret    

f0102bb6 <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f0102bb6:	55                   	push   %ebp
f0102bb7:	89 e5                	mov    %esp,%ebp
	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	ts.ts_esp0 = KSTACKTOP;
f0102bb9:	b8 c0 f7 16 f0       	mov    $0xf016f7c0,%eax
f0102bbe:	c7 05 c4 f7 16 f0 00 	movl   $0xf0000000,0xf016f7c4
f0102bc5:	00 00 f0 
	ts.ts_ss0 = GD_KD;
f0102bc8:	66 c7 05 c8 f7 16 f0 	movw   $0x10,0xf016f7c8
f0102bcf:	10 00 

	// Initialize the TSS slot of the gdt.
	gdt[GD_TSS0 >> 3] = SEG16(STS_T32A, (uint32_t) (&ts),
f0102bd1:	66 c7 05 48 93 11 f0 	movw   $0x67,0xf0119348
f0102bd8:	67 00 
f0102bda:	66 a3 4a 93 11 f0    	mov    %ax,0xf011934a
f0102be0:	89 c2                	mov    %eax,%edx
f0102be2:	c1 ea 10             	shr    $0x10,%edx
f0102be5:	88 15 4c 93 11 f0    	mov    %dl,0xf011934c
f0102beb:	c6 05 4e 93 11 f0 40 	movb   $0x40,0xf011934e
f0102bf2:	c1 e8 18             	shr    $0x18,%eax
f0102bf5:	a2 4f 93 11 f0       	mov    %al,0xf011934f
					sizeof(struct Taskstate) - 1, 0);
	gdt[GD_TSS0 >> 3].sd_s = 0;
f0102bfa:	c6 05 4d 93 11 f0 89 	movb   $0x89,0xf011934d
}

static inline void
ltr(uint16_t sel)
{
	asm volatile("ltr %0" : : "r" (sel));
f0102c01:	b8 28 00 00 00       	mov    $0x28,%eax
f0102c06:	0f 00 d8             	ltr    %ax
}

static inline void
lidt(void *p)
{
	asm volatile("lidt (%0)" : : "r" (p));
f0102c09:	b8 50 93 11 f0       	mov    $0xf0119350,%eax
f0102c0e:	0f 01 18             	lidtl  (%eax)
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0);

	// Load the IDT
	lidt(&idt_pd);
}
f0102c11:	5d                   	pop    %ebp
f0102c12:	c3                   	ret    

f0102c13 <trap_init>:
}


void
trap_init(void)
{
f0102c13:	55                   	push   %ebp
f0102c14:	89 e5                	mov    %esp,%ebp
	extern struct Segdesc gdt[];

	// LAB 3: Your code here.

	// Per-CPU setup 
	trap_init_percpu();
f0102c16:	e8 9b ff ff ff       	call   f0102bb6 <trap_init_percpu>
}
f0102c1b:	5d                   	pop    %ebp
f0102c1c:	c3                   	ret    

f0102c1d <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f0102c1d:	55                   	push   %ebp
f0102c1e:	89 e5                	mov    %esp,%ebp
f0102c20:	53                   	push   %ebx
f0102c21:	83 ec 0c             	sub    $0xc,%esp
f0102c24:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f0102c27:	ff 33                	pushl  (%ebx)
f0102c29:	68 f4 4e 10 f0       	push   $0xf0104ef4
f0102c2e:	e8 6f ff ff ff       	call   f0102ba2 <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f0102c33:	83 c4 08             	add    $0x8,%esp
f0102c36:	ff 73 04             	pushl  0x4(%ebx)
f0102c39:	68 03 4f 10 f0       	push   $0xf0104f03
f0102c3e:	e8 5f ff ff ff       	call   f0102ba2 <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f0102c43:	83 c4 08             	add    $0x8,%esp
f0102c46:	ff 73 08             	pushl  0x8(%ebx)
f0102c49:	68 12 4f 10 f0       	push   $0xf0104f12
f0102c4e:	e8 4f ff ff ff       	call   f0102ba2 <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f0102c53:	83 c4 08             	add    $0x8,%esp
f0102c56:	ff 73 0c             	pushl  0xc(%ebx)
f0102c59:	68 21 4f 10 f0       	push   $0xf0104f21
f0102c5e:	e8 3f ff ff ff       	call   f0102ba2 <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f0102c63:	83 c4 08             	add    $0x8,%esp
f0102c66:	ff 73 10             	pushl  0x10(%ebx)
f0102c69:	68 30 4f 10 f0       	push   $0xf0104f30
f0102c6e:	e8 2f ff ff ff       	call   f0102ba2 <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f0102c73:	83 c4 08             	add    $0x8,%esp
f0102c76:	ff 73 14             	pushl  0x14(%ebx)
f0102c79:	68 3f 4f 10 f0       	push   $0xf0104f3f
f0102c7e:	e8 1f ff ff ff       	call   f0102ba2 <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f0102c83:	83 c4 08             	add    $0x8,%esp
f0102c86:	ff 73 18             	pushl  0x18(%ebx)
f0102c89:	68 4e 4f 10 f0       	push   $0xf0104f4e
f0102c8e:	e8 0f ff ff ff       	call   f0102ba2 <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f0102c93:	83 c4 08             	add    $0x8,%esp
f0102c96:	ff 73 1c             	pushl  0x1c(%ebx)
f0102c99:	68 5d 4f 10 f0       	push   $0xf0104f5d
f0102c9e:	e8 ff fe ff ff       	call   f0102ba2 <cprintf>
}
f0102ca3:	83 c4 10             	add    $0x10,%esp
f0102ca6:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102ca9:	c9                   	leave  
f0102caa:	c3                   	ret    

f0102cab <print_trapframe>:
	lidt(&idt_pd);
}

void
print_trapframe(struct Trapframe *tf)
{
f0102cab:	55                   	push   %ebp
f0102cac:	89 e5                	mov    %esp,%ebp
f0102cae:	56                   	push   %esi
f0102caf:	53                   	push   %ebx
f0102cb0:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p\n", tf);
f0102cb3:	83 ec 08             	sub    $0x8,%esp
f0102cb6:	53                   	push   %ebx
f0102cb7:	68 93 50 10 f0       	push   $0xf0105093
f0102cbc:	e8 e1 fe ff ff       	call   f0102ba2 <cprintf>
	print_regs(&tf->tf_regs);
f0102cc1:	89 1c 24             	mov    %ebx,(%esp)
f0102cc4:	e8 54 ff ff ff       	call   f0102c1d <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f0102cc9:	83 c4 08             	add    $0x8,%esp
f0102ccc:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f0102cd0:	50                   	push   %eax
f0102cd1:	68 ae 4f 10 f0       	push   $0xf0104fae
f0102cd6:	e8 c7 fe ff ff       	call   f0102ba2 <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f0102cdb:	83 c4 08             	add    $0x8,%esp
f0102cde:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f0102ce2:	50                   	push   %eax
f0102ce3:	68 c1 4f 10 f0       	push   $0xf0104fc1
f0102ce8:	e8 b5 fe ff ff       	call   f0102ba2 <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0102ced:	8b 43 28             	mov    0x28(%ebx),%eax
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < ARRAY_SIZE(excnames))
f0102cf0:	83 c4 10             	add    $0x10,%esp
f0102cf3:	83 f8 13             	cmp    $0x13,%eax
f0102cf6:	77 09                	ja     f0102d01 <print_trapframe+0x56>
		return excnames[trapno];
f0102cf8:	8b 14 85 60 52 10 f0 	mov    -0xfefada0(,%eax,4),%edx
f0102cff:	eb 10                	jmp    f0102d11 <print_trapframe+0x66>
	if (trapno == T_SYSCALL)
		return "System call";
	return "(unknown trap)";
f0102d01:	83 f8 30             	cmp    $0x30,%eax
f0102d04:	b9 78 4f 10 f0       	mov    $0xf0104f78,%ecx
f0102d09:	ba 6c 4f 10 f0       	mov    $0xf0104f6c,%edx
f0102d0e:	0f 45 d1             	cmovne %ecx,%edx
{
	cprintf("TRAP frame at %p\n", tf);
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0102d11:	83 ec 04             	sub    $0x4,%esp
f0102d14:	52                   	push   %edx
f0102d15:	50                   	push   %eax
f0102d16:	68 d4 4f 10 f0       	push   $0xf0104fd4
f0102d1b:	e8 82 fe ff ff       	call   f0102ba2 <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0102d20:	83 c4 10             	add    $0x10,%esp
f0102d23:	3b 1d a0 f7 16 f0    	cmp    0xf016f7a0,%ebx
f0102d29:	75 1a                	jne    f0102d45 <print_trapframe+0x9a>
f0102d2b:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0102d2f:	75 14                	jne    f0102d45 <print_trapframe+0x9a>

static inline uint32_t
rcr2(void)
{
	uint32_t val;
	asm volatile("movl %%cr2,%0" : "=r" (val));
f0102d31:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f0102d34:	83 ec 08             	sub    $0x8,%esp
f0102d37:	50                   	push   %eax
f0102d38:	68 e6 4f 10 f0       	push   $0xf0104fe6
f0102d3d:	e8 60 fe ff ff       	call   f0102ba2 <cprintf>
f0102d42:	83 c4 10             	add    $0x10,%esp
	cprintf("  err  0x%08x", tf->tf_err);
f0102d45:	83 ec 08             	sub    $0x8,%esp
f0102d48:	ff 73 2c             	pushl  0x2c(%ebx)
f0102d4b:	68 f5 4f 10 f0       	push   $0xf0104ff5
f0102d50:	e8 4d fe ff ff       	call   f0102ba2 <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f0102d55:	83 c4 10             	add    $0x10,%esp
f0102d58:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0102d5c:	75 49                	jne    f0102da7 <print_trapframe+0xfc>
		cprintf(" [%s, %s, %s]\n",
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
f0102d5e:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f0102d61:	89 c2                	mov    %eax,%edx
f0102d63:	83 e2 01             	and    $0x1,%edx
f0102d66:	ba 92 4f 10 f0       	mov    $0xf0104f92,%edx
f0102d6b:	b9 87 4f 10 f0       	mov    $0xf0104f87,%ecx
f0102d70:	0f 44 ca             	cmove  %edx,%ecx
f0102d73:	89 c2                	mov    %eax,%edx
f0102d75:	83 e2 02             	and    $0x2,%edx
f0102d78:	ba a4 4f 10 f0       	mov    $0xf0104fa4,%edx
f0102d7d:	be 9e 4f 10 f0       	mov    $0xf0104f9e,%esi
f0102d82:	0f 45 d6             	cmovne %esi,%edx
f0102d85:	83 e0 04             	and    $0x4,%eax
f0102d88:	be be 50 10 f0       	mov    $0xf01050be,%esi
f0102d8d:	b8 a9 4f 10 f0       	mov    $0xf0104fa9,%eax
f0102d92:	0f 44 c6             	cmove  %esi,%eax
f0102d95:	51                   	push   %ecx
f0102d96:	52                   	push   %edx
f0102d97:	50                   	push   %eax
f0102d98:	68 03 50 10 f0       	push   $0xf0105003
f0102d9d:	e8 00 fe ff ff       	call   f0102ba2 <cprintf>
f0102da2:	83 c4 10             	add    $0x10,%esp
f0102da5:	eb 10                	jmp    f0102db7 <print_trapframe+0x10c>
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f0102da7:	83 ec 0c             	sub    $0xc,%esp
f0102daa:	68 2d 4e 10 f0       	push   $0xf0104e2d
f0102daf:	e8 ee fd ff ff       	call   f0102ba2 <cprintf>
f0102db4:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f0102db7:	83 ec 08             	sub    $0x8,%esp
f0102dba:	ff 73 30             	pushl  0x30(%ebx)
f0102dbd:	68 12 50 10 f0       	push   $0xf0105012
f0102dc2:	e8 db fd ff ff       	call   f0102ba2 <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f0102dc7:	83 c4 08             	add    $0x8,%esp
f0102dca:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f0102dce:	50                   	push   %eax
f0102dcf:	68 21 50 10 f0       	push   $0xf0105021
f0102dd4:	e8 c9 fd ff ff       	call   f0102ba2 <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f0102dd9:	83 c4 08             	add    $0x8,%esp
f0102ddc:	ff 73 38             	pushl  0x38(%ebx)
f0102ddf:	68 34 50 10 f0       	push   $0xf0105034
f0102de4:	e8 b9 fd ff ff       	call   f0102ba2 <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f0102de9:	83 c4 10             	add    $0x10,%esp
f0102dec:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0102df0:	74 25                	je     f0102e17 <print_trapframe+0x16c>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f0102df2:	83 ec 08             	sub    $0x8,%esp
f0102df5:	ff 73 3c             	pushl  0x3c(%ebx)
f0102df8:	68 43 50 10 f0       	push   $0xf0105043
f0102dfd:	e8 a0 fd ff ff       	call   f0102ba2 <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f0102e02:	83 c4 08             	add    $0x8,%esp
f0102e05:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f0102e09:	50                   	push   %eax
f0102e0a:	68 52 50 10 f0       	push   $0xf0105052
f0102e0f:	e8 8e fd ff ff       	call   f0102ba2 <cprintf>
f0102e14:	83 c4 10             	add    $0x10,%esp
	}
}
f0102e17:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0102e1a:	5b                   	pop    %ebx
f0102e1b:	5e                   	pop    %esi
f0102e1c:	5d                   	pop    %ebp
f0102e1d:	c3                   	ret    

f0102e1e <trap>:
	}
}

void
trap(struct Trapframe *tf)
{
f0102e1e:	55                   	push   %ebp
f0102e1f:	89 e5                	mov    %esp,%ebp
f0102e21:	57                   	push   %edi
f0102e22:	56                   	push   %esi
f0102e23:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f0102e26:	fc                   	cld    

static inline uint32_t
read_eflags(void)
{
	uint32_t eflags;
	asm volatile("pushfl; popl %0" : "=r" (eflags));
f0102e27:	9c                   	pushf  
f0102e28:	58                   	pop    %eax

	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f0102e29:	f6 c4 02             	test   $0x2,%ah
f0102e2c:	74 19                	je     f0102e47 <trap+0x29>
f0102e2e:	68 65 50 10 f0       	push   $0xf0105065
f0102e33:	68 a2 4b 10 f0       	push   $0xf0104ba2
f0102e38:	68 a7 00 00 00       	push   $0xa7
f0102e3d:	68 7e 50 10 f0       	push   $0xf010507e
f0102e42:	e8 59 d2 ff ff       	call   f01000a0 <_panic>

	cprintf("Incoming TRAP frame at %p\n", tf);
f0102e47:	83 ec 08             	sub    $0x8,%esp
f0102e4a:	56                   	push   %esi
f0102e4b:	68 8a 50 10 f0       	push   $0xf010508a
f0102e50:	e8 4d fd ff ff       	call   f0102ba2 <cprintf>

	if ((tf->tf_cs & 3) == 3) {
f0102e55:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0102e59:	83 e0 03             	and    $0x3,%eax
f0102e5c:	83 c4 10             	add    $0x10,%esp
f0102e5f:	66 83 f8 03          	cmp    $0x3,%ax
f0102e63:	75 31                	jne    f0102e96 <trap+0x78>
		// Trapped from user mode.
		assert(curenv);
f0102e65:	a1 80 ef 16 f0       	mov    0xf016ef80,%eax
f0102e6a:	85 c0                	test   %eax,%eax
f0102e6c:	75 19                	jne    f0102e87 <trap+0x69>
f0102e6e:	68 a5 50 10 f0       	push   $0xf01050a5
f0102e73:	68 a2 4b 10 f0       	push   $0xf0104ba2
f0102e78:	68 ad 00 00 00       	push   $0xad
f0102e7d:	68 7e 50 10 f0       	push   $0xf010507e
f0102e82:	e8 19 d2 ff ff       	call   f01000a0 <_panic>

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f0102e87:	b9 11 00 00 00       	mov    $0x11,%ecx
f0102e8c:	89 c7                	mov    %eax,%edi
f0102e8e:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f0102e90:	8b 35 80 ef 16 f0    	mov    0xf016ef80,%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f0102e96:	89 35 a0 f7 16 f0    	mov    %esi,0xf016f7a0
{
	// Handle processor exceptions.
	// LAB 3: Your code here.

	// Unexpected trap: The user process or the kernel has a bug.
	print_trapframe(tf);
f0102e9c:	83 ec 0c             	sub    $0xc,%esp
f0102e9f:	56                   	push   %esi
f0102ea0:	e8 06 fe ff ff       	call   f0102cab <print_trapframe>
	if (tf->tf_cs == GD_KT)
f0102ea5:	83 c4 10             	add    $0x10,%esp
f0102ea8:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f0102ead:	75 17                	jne    f0102ec6 <trap+0xa8>
		panic("unhandled trap in kernel");
f0102eaf:	83 ec 04             	sub    $0x4,%esp
f0102eb2:	68 ac 50 10 f0       	push   $0xf01050ac
f0102eb7:	68 96 00 00 00       	push   $0x96
f0102ebc:	68 7e 50 10 f0       	push   $0xf010507e
f0102ec1:	e8 da d1 ff ff       	call   f01000a0 <_panic>
	else {
		env_destroy(curenv);
f0102ec6:	83 ec 0c             	sub    $0xc,%esp
f0102ec9:	ff 35 80 ef 16 f0    	pushl  0xf016ef80
f0102ecf:	e8 fd fb ff ff       	call   f0102ad1 <env_destroy>

	// Dispatch based on what type of trap occurred
	trap_dispatch(tf);

	// Return to the current environment, which should be running.
	assert(curenv && curenv->env_status == ENV_RUNNING);
f0102ed4:	a1 80 ef 16 f0       	mov    0xf016ef80,%eax
f0102ed9:	83 c4 10             	add    $0x10,%esp
f0102edc:	85 c0                	test   %eax,%eax
f0102ede:	74 06                	je     f0102ee6 <trap+0xc8>
f0102ee0:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0102ee4:	74 19                	je     f0102eff <trap+0xe1>
f0102ee6:	68 08 52 10 f0       	push   $0xf0105208
f0102eeb:	68 a2 4b 10 f0       	push   $0xf0104ba2
f0102ef0:	68 bf 00 00 00       	push   $0xbf
f0102ef5:	68 7e 50 10 f0       	push   $0xf010507e
f0102efa:	e8 a1 d1 ff ff       	call   f01000a0 <_panic>
	env_run(curenv);
f0102eff:	83 ec 0c             	sub    $0xc,%esp
f0102f02:	50                   	push   %eax
f0102f03:	e8 19 fc ff ff       	call   f0102b21 <env_run>

f0102f08 <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f0102f08:	55                   	push   %ebp
f0102f09:	89 e5                	mov    %esp,%ebp
f0102f0b:	53                   	push   %ebx
f0102f0c:	83 ec 04             	sub    $0x4,%esp
f0102f0f:	8b 5d 08             	mov    0x8(%ebp),%ebx

static inline uint32_t
rcr2(void)
{
	uint32_t val;
	asm volatile("movl %%cr2,%0" : "=r" (val));
f0102f12:	0f 20 d0             	mov    %cr2,%eax

	// We've already handled kernel-mode exceptions, so if we get here,
	// the page fault happened in user mode.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0102f15:	ff 73 30             	pushl  0x30(%ebx)
f0102f18:	50                   	push   %eax
f0102f19:	a1 80 ef 16 f0       	mov    0xf016ef80,%eax
f0102f1e:	ff 70 48             	pushl  0x48(%eax)
f0102f21:	68 34 52 10 f0       	push   $0xf0105234
f0102f26:	e8 77 fc ff ff       	call   f0102ba2 <cprintf>
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f0102f2b:	89 1c 24             	mov    %ebx,(%esp)
f0102f2e:	e8 78 fd ff ff       	call   f0102cab <print_trapframe>
	env_destroy(curenv);
f0102f33:	83 c4 04             	add    $0x4,%esp
f0102f36:	ff 35 80 ef 16 f0    	pushl  0xf016ef80
f0102f3c:	e8 90 fb ff ff       	call   f0102ad1 <env_destroy>
}
f0102f41:	83 c4 10             	add    $0x10,%esp
f0102f44:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102f47:	c9                   	leave  
f0102f48:	c3                   	ret    

f0102f49 <syscall>:
f0102f49:	55                   	push   %ebp
f0102f4a:	89 e5                	mov    %esp,%ebp
f0102f4c:	83 ec 0c             	sub    $0xc,%esp
f0102f4f:	68 b0 52 10 f0       	push   $0xf01052b0
f0102f54:	6a 49                	push   $0x49
f0102f56:	68 c8 52 10 f0       	push   $0xf01052c8
f0102f5b:	e8 40 d1 ff ff       	call   f01000a0 <_panic>

f0102f60 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0102f60:	55                   	push   %ebp
f0102f61:	89 e5                	mov    %esp,%ebp
f0102f63:	57                   	push   %edi
f0102f64:	56                   	push   %esi
f0102f65:	53                   	push   %ebx
f0102f66:	83 ec 14             	sub    $0x14,%esp
f0102f69:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0102f6c:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0102f6f:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0102f72:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0102f75:	8b 1a                	mov    (%edx),%ebx
f0102f77:	8b 01                	mov    (%ecx),%eax
f0102f79:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0102f7c:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0102f83:	eb 7f                	jmp    f0103004 <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f0102f85:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102f88:	01 d8                	add    %ebx,%eax
f0102f8a:	89 c6                	mov    %eax,%esi
f0102f8c:	c1 ee 1f             	shr    $0x1f,%esi
f0102f8f:	01 c6                	add    %eax,%esi
f0102f91:	d1 fe                	sar    %esi
f0102f93:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0102f96:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0102f99:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f0102f9c:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102f9e:	eb 03                	jmp    f0102fa3 <stab_binsearch+0x43>
			m--;
f0102fa0:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102fa3:	39 c3                	cmp    %eax,%ebx
f0102fa5:	7f 0d                	jg     f0102fb4 <stab_binsearch+0x54>
f0102fa7:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0102fab:	83 ea 0c             	sub    $0xc,%edx
f0102fae:	39 f9                	cmp    %edi,%ecx
f0102fb0:	75 ee                	jne    f0102fa0 <stab_binsearch+0x40>
f0102fb2:	eb 05                	jmp    f0102fb9 <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0102fb4:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f0102fb7:	eb 4b                	jmp    f0103004 <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0102fb9:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0102fbc:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0102fbf:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0102fc3:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0102fc6:	76 11                	jbe    f0102fd9 <stab_binsearch+0x79>
			*region_left = m;
f0102fc8:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0102fcb:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0102fcd:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102fd0:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0102fd7:	eb 2b                	jmp    f0103004 <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0102fd9:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0102fdc:	73 14                	jae    f0102ff2 <stab_binsearch+0x92>
			*region_right = m - 1;
f0102fde:	83 e8 01             	sub    $0x1,%eax
f0102fe1:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0102fe4:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0102fe7:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102fe9:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0102ff0:	eb 12                	jmp    f0103004 <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0102ff2:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0102ff5:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0102ff7:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0102ffb:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102ffd:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0103004:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0103007:	0f 8e 78 ff ff ff    	jle    f0102f85 <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f010300d:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0103011:	75 0f                	jne    f0103022 <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f0103013:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103016:	8b 00                	mov    (%eax),%eax
f0103018:	83 e8 01             	sub    $0x1,%eax
f010301b:	8b 75 e0             	mov    -0x20(%ebp),%esi
f010301e:	89 06                	mov    %eax,(%esi)
f0103020:	eb 2c                	jmp    f010304e <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103022:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103025:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0103027:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010302a:	8b 0e                	mov    (%esi),%ecx
f010302c:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010302f:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0103032:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103035:	eb 03                	jmp    f010303a <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0103037:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010303a:	39 c8                	cmp    %ecx,%eax
f010303c:	7e 0b                	jle    f0103049 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f010303e:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0103042:	83 ea 0c             	sub    $0xc,%edx
f0103045:	39 df                	cmp    %ebx,%edi
f0103047:	75 ee                	jne    f0103037 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f0103049:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010304c:	89 06                	mov    %eax,(%esi)
	}
}
f010304e:	83 c4 14             	add    $0x14,%esp
f0103051:	5b                   	pop    %ebx
f0103052:	5e                   	pop    %esi
f0103053:	5f                   	pop    %edi
f0103054:	5d                   	pop    %ebp
f0103055:	c3                   	ret    

f0103056 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0103056:	55                   	push   %ebp
f0103057:	89 e5                	mov    %esp,%ebp
f0103059:	57                   	push   %edi
f010305a:	56                   	push   %esi
f010305b:	53                   	push   %ebx
f010305c:	83 ec 3c             	sub    $0x3c,%esp
f010305f:	8b 75 08             	mov    0x8(%ebp),%esi
f0103062:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0103065:	c7 03 d7 52 10 f0    	movl   $0xf01052d7,(%ebx)
	info->eip_line = 0;
f010306b:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0103072:	c7 43 08 d7 52 10 f0 	movl   $0xf01052d7,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0103079:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0103080:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0103083:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f010308a:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0103090:	77 21                	ja     f01030b3 <debuginfo_eip+0x5d>

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.

		stabs = usd->stabs;
f0103092:	a1 00 00 20 00       	mov    0x200000,%eax
f0103097:	89 45 bc             	mov    %eax,-0x44(%ebp)
		stab_end = usd->stab_end;
f010309a:	a1 04 00 20 00       	mov    0x200004,%eax
		stabstr = usd->stabstr;
f010309f:	8b 3d 08 00 20 00    	mov    0x200008,%edi
f01030a5:	89 7d b8             	mov    %edi,-0x48(%ebp)
		stabstr_end = usd->stabstr_end;
f01030a8:	8b 3d 0c 00 20 00    	mov    0x20000c,%edi
f01030ae:	89 7d c0             	mov    %edi,-0x40(%ebp)
f01030b1:	eb 1a                	jmp    f01030cd <debuginfo_eip+0x77>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f01030b3:	c7 45 c0 56 ed 10 f0 	movl   $0xf010ed56,-0x40(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f01030ba:	c7 45 b8 09 c4 10 f0 	movl   $0xf010c409,-0x48(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f01030c1:	b8 08 c4 10 f0       	mov    $0xf010c408,%eax
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f01030c6:	c7 45 bc f0 54 10 f0 	movl   $0xf01054f0,-0x44(%ebp)
		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01030cd:	8b 7d c0             	mov    -0x40(%ebp),%edi
f01030d0:	39 7d b8             	cmp    %edi,-0x48(%ebp)
f01030d3:	0f 83 95 01 00 00    	jae    f010326e <debuginfo_eip+0x218>
f01030d9:	80 7f ff 00          	cmpb   $0x0,-0x1(%edi)
f01030dd:	0f 85 92 01 00 00    	jne    f0103275 <debuginfo_eip+0x21f>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f01030e3:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f01030ea:	8b 7d bc             	mov    -0x44(%ebp),%edi
f01030ed:	29 f8                	sub    %edi,%eax
f01030ef:	c1 f8 02             	sar    $0x2,%eax
f01030f2:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f01030f8:	83 e8 01             	sub    $0x1,%eax
f01030fb:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f01030fe:	56                   	push   %esi
f01030ff:	6a 64                	push   $0x64
f0103101:	8d 45 e0             	lea    -0x20(%ebp),%eax
f0103104:	89 c1                	mov    %eax,%ecx
f0103106:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0103109:	89 f8                	mov    %edi,%eax
f010310b:	e8 50 fe ff ff       	call   f0102f60 <stab_binsearch>
	if (lfile == 0)
f0103110:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103113:	83 c4 08             	add    $0x8,%esp
f0103116:	85 c0                	test   %eax,%eax
f0103118:	0f 84 5e 01 00 00    	je     f010327c <debuginfo_eip+0x226>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f010311e:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0103121:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103124:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0103127:	56                   	push   %esi
f0103128:	6a 24                	push   $0x24
f010312a:	8d 45 d8             	lea    -0x28(%ebp),%eax
f010312d:	89 c1                	mov    %eax,%ecx
f010312f:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0103132:	89 f8                	mov    %edi,%eax
f0103134:	e8 27 fe ff ff       	call   f0102f60 <stab_binsearch>

	if (lfun <= rfun) {
f0103139:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010313c:	8b 55 d8             	mov    -0x28(%ebp),%edx
f010313f:	89 55 c4             	mov    %edx,-0x3c(%ebp)
f0103142:	83 c4 08             	add    $0x8,%esp
f0103145:	39 d0                	cmp    %edx,%eax
f0103147:	7f 2b                	jg     f0103174 <debuginfo_eip+0x11e>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0103149:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010314c:	8d 0c 97             	lea    (%edi,%edx,4),%ecx
f010314f:	8b 11                	mov    (%ecx),%edx
f0103151:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0103154:	2b 7d b8             	sub    -0x48(%ebp),%edi
f0103157:	39 fa                	cmp    %edi,%edx
f0103159:	73 06                	jae    f0103161 <debuginfo_eip+0x10b>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f010315b:	03 55 b8             	add    -0x48(%ebp),%edx
f010315e:	89 53 08             	mov    %edx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0103161:	8b 51 08             	mov    0x8(%ecx),%edx
f0103164:	89 53 10             	mov    %edx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0103167:	29 d6                	sub    %edx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0103169:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f010316c:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f010316f:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0103172:	eb 0f                	jmp    f0103183 <debuginfo_eip+0x12d>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0103174:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0103177:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010317a:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f010317d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103180:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0103183:	83 ec 08             	sub    $0x8,%esp
f0103186:	6a 3a                	push   $0x3a
f0103188:	ff 73 08             	pushl  0x8(%ebx)
f010318b:	e8 7a 08 00 00       	call   f0103a0a <strfind>
f0103190:	2b 43 08             	sub    0x8(%ebx),%eax
f0103193:	89 43 0c             	mov    %eax,0xc(%ebx)
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.

	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);	
f0103196:	83 c4 08             	add    $0x8,%esp
f0103199:	56                   	push   %esi
f010319a:	6a 44                	push   $0x44
f010319c:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f010319f:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f01031a2:	8b 75 bc             	mov    -0x44(%ebp),%esi
f01031a5:	89 f0                	mov    %esi,%eax
f01031a7:	e8 b4 fd ff ff       	call   f0102f60 <stab_binsearch>
	if (lline > rline)
f01031ac:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01031af:	83 c4 10             	add    $0x10,%esp
f01031b2:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f01031b5:	0f 8f c8 00 00 00    	jg     f0103283 <debuginfo_eip+0x22d>
		    return -1;
	info->eip_line = stabs[lline].n_desc;
f01031bb:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01031be:	8d 14 96             	lea    (%esi,%edx,4),%edx
f01031c1:	0f b7 4a 06          	movzwl 0x6(%edx),%ecx
f01031c5:	89 4b 04             	mov    %ecx,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01031c8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01031cb:	c6 45 c4 00          	movb   $0x0,-0x3c(%ebp)
f01031cf:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f01031d2:	eb 0a                	jmp    f01031de <debuginfo_eip+0x188>
f01031d4:	83 e8 01             	sub    $0x1,%eax
f01031d7:	83 ea 0c             	sub    $0xc,%edx
f01031da:	c6 45 c4 01          	movb   $0x1,-0x3c(%ebp)
f01031de:	39 c7                	cmp    %eax,%edi
f01031e0:	7e 05                	jle    f01031e7 <debuginfo_eip+0x191>
f01031e2:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01031e5:	eb 47                	jmp    f010322e <debuginfo_eip+0x1d8>
	       && stabs[lline].n_type != N_SOL
f01031e7:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01031eb:	80 f9 84             	cmp    $0x84,%cl
f01031ee:	75 0e                	jne    f01031fe <debuginfo_eip+0x1a8>
f01031f0:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01031f3:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f01031f7:	74 1c                	je     f0103215 <debuginfo_eip+0x1bf>
f01031f9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01031fc:	eb 17                	jmp    f0103215 <debuginfo_eip+0x1bf>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f01031fe:	80 f9 64             	cmp    $0x64,%cl
f0103201:	75 d1                	jne    f01031d4 <debuginfo_eip+0x17e>
f0103203:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f0103207:	74 cb                	je     f01031d4 <debuginfo_eip+0x17e>
f0103209:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010320c:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f0103210:	74 03                	je     f0103215 <debuginfo_eip+0x1bf>
f0103212:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0103215:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0103218:	8b 7d bc             	mov    -0x44(%ebp),%edi
f010321b:	8b 14 87             	mov    (%edi,%eax,4),%edx
f010321e:	8b 45 c0             	mov    -0x40(%ebp),%eax
f0103221:	8b 75 b8             	mov    -0x48(%ebp),%esi
f0103224:	29 f0                	sub    %esi,%eax
f0103226:	39 c2                	cmp    %eax,%edx
f0103228:	73 04                	jae    f010322e <debuginfo_eip+0x1d8>
		info->eip_file = stabstr + stabs[lline].n_strx;
f010322a:	01 f2                	add    %esi,%edx
f010322c:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f010322e:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103231:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103234:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103239:	39 f2                	cmp    %esi,%edx
f010323b:	7d 52                	jge    f010328f <debuginfo_eip+0x239>
		for (lline = lfun + 1;
f010323d:	83 c2 01             	add    $0x1,%edx
f0103240:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0103243:	89 d0                	mov    %edx,%eax
f0103245:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0103248:	8b 7d bc             	mov    -0x44(%ebp),%edi
f010324b:	8d 14 97             	lea    (%edi,%edx,4),%edx
f010324e:	eb 04                	jmp    f0103254 <debuginfo_eip+0x1fe>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0103250:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0103254:	39 c6                	cmp    %eax,%esi
f0103256:	7e 32                	jle    f010328a <debuginfo_eip+0x234>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0103258:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f010325c:	83 c0 01             	add    $0x1,%eax
f010325f:	83 c2 0c             	add    $0xc,%edx
f0103262:	80 f9 a0             	cmp    $0xa0,%cl
f0103265:	74 e9                	je     f0103250 <debuginfo_eip+0x1fa>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103267:	b8 00 00 00 00       	mov    $0x0,%eax
f010326c:	eb 21                	jmp    f010328f <debuginfo_eip+0x239>
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f010326e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103273:	eb 1a                	jmp    f010328f <debuginfo_eip+0x239>
f0103275:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010327a:	eb 13                	jmp    f010328f <debuginfo_eip+0x239>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f010327c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103281:	eb 0c                	jmp    f010328f <debuginfo_eip+0x239>
	//	which one.
	// Your code here.

	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);	
	if (lline > rline)
		    return -1;
f0103283:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103288:	eb 05                	jmp    f010328f <debuginfo_eip+0x239>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f010328a:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010328f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103292:	5b                   	pop    %ebx
f0103293:	5e                   	pop    %esi
f0103294:	5f                   	pop    %edi
f0103295:	5d                   	pop    %ebp
f0103296:	c3                   	ret    

f0103297 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0103297:	55                   	push   %ebp
f0103298:	89 e5                	mov    %esp,%ebp
f010329a:	57                   	push   %edi
f010329b:	56                   	push   %esi
f010329c:	53                   	push   %ebx
f010329d:	83 ec 1c             	sub    $0x1c,%esp
f01032a0:	89 c7                	mov    %eax,%edi
f01032a2:	89 d6                	mov    %edx,%esi
f01032a4:	8b 45 08             	mov    0x8(%ebp),%eax
f01032a7:	8b 55 0c             	mov    0xc(%ebp),%edx
f01032aa:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01032ad:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f01032b0:	8b 4d 10             	mov    0x10(%ebp),%ecx
f01032b3:	bb 00 00 00 00       	mov    $0x0,%ebx
f01032b8:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01032bb:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f01032be:	39 d3                	cmp    %edx,%ebx
f01032c0:	72 05                	jb     f01032c7 <printnum+0x30>
f01032c2:	39 45 10             	cmp    %eax,0x10(%ebp)
f01032c5:	77 45                	ja     f010330c <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f01032c7:	83 ec 0c             	sub    $0xc,%esp
f01032ca:	ff 75 18             	pushl  0x18(%ebp)
f01032cd:	8b 45 14             	mov    0x14(%ebp),%eax
f01032d0:	8d 58 ff             	lea    -0x1(%eax),%ebx
f01032d3:	53                   	push   %ebx
f01032d4:	ff 75 10             	pushl  0x10(%ebp)
f01032d7:	83 ec 08             	sub    $0x8,%esp
f01032da:	ff 75 e4             	pushl  -0x1c(%ebp)
f01032dd:	ff 75 e0             	pushl  -0x20(%ebp)
f01032e0:	ff 75 dc             	pushl  -0x24(%ebp)
f01032e3:	ff 75 d8             	pushl  -0x28(%ebp)
f01032e6:	e8 45 09 00 00       	call   f0103c30 <__udivdi3>
f01032eb:	83 c4 18             	add    $0x18,%esp
f01032ee:	52                   	push   %edx
f01032ef:	50                   	push   %eax
f01032f0:	89 f2                	mov    %esi,%edx
f01032f2:	89 f8                	mov    %edi,%eax
f01032f4:	e8 9e ff ff ff       	call   f0103297 <printnum>
f01032f9:	83 c4 20             	add    $0x20,%esp
f01032fc:	eb 18                	jmp    f0103316 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f01032fe:	83 ec 08             	sub    $0x8,%esp
f0103301:	56                   	push   %esi
f0103302:	ff 75 18             	pushl  0x18(%ebp)
f0103305:	ff d7                	call   *%edi
f0103307:	83 c4 10             	add    $0x10,%esp
f010330a:	eb 03                	jmp    f010330f <printnum+0x78>
f010330c:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f010330f:	83 eb 01             	sub    $0x1,%ebx
f0103312:	85 db                	test   %ebx,%ebx
f0103314:	7f e8                	jg     f01032fe <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0103316:	83 ec 08             	sub    $0x8,%esp
f0103319:	56                   	push   %esi
f010331a:	83 ec 04             	sub    $0x4,%esp
f010331d:	ff 75 e4             	pushl  -0x1c(%ebp)
f0103320:	ff 75 e0             	pushl  -0x20(%ebp)
f0103323:	ff 75 dc             	pushl  -0x24(%ebp)
f0103326:	ff 75 d8             	pushl  -0x28(%ebp)
f0103329:	e8 32 0a 00 00       	call   f0103d60 <__umoddi3>
f010332e:	83 c4 14             	add    $0x14,%esp
f0103331:	0f be 80 e1 52 10 f0 	movsbl -0xfefad1f(%eax),%eax
f0103338:	50                   	push   %eax
f0103339:	ff d7                	call   *%edi
}
f010333b:	83 c4 10             	add    $0x10,%esp
f010333e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103341:	5b                   	pop    %ebx
f0103342:	5e                   	pop    %esi
f0103343:	5f                   	pop    %edi
f0103344:	5d                   	pop    %ebp
f0103345:	c3                   	ret    

f0103346 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0103346:	55                   	push   %ebp
f0103347:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0103349:	83 fa 01             	cmp    $0x1,%edx
f010334c:	7e 0e                	jle    f010335c <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f010334e:	8b 10                	mov    (%eax),%edx
f0103350:	8d 4a 08             	lea    0x8(%edx),%ecx
f0103353:	89 08                	mov    %ecx,(%eax)
f0103355:	8b 02                	mov    (%edx),%eax
f0103357:	8b 52 04             	mov    0x4(%edx),%edx
f010335a:	eb 22                	jmp    f010337e <getuint+0x38>
	else if (lflag)
f010335c:	85 d2                	test   %edx,%edx
f010335e:	74 10                	je     f0103370 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0103360:	8b 10                	mov    (%eax),%edx
f0103362:	8d 4a 04             	lea    0x4(%edx),%ecx
f0103365:	89 08                	mov    %ecx,(%eax)
f0103367:	8b 02                	mov    (%edx),%eax
f0103369:	ba 00 00 00 00       	mov    $0x0,%edx
f010336e:	eb 0e                	jmp    f010337e <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0103370:	8b 10                	mov    (%eax),%edx
f0103372:	8d 4a 04             	lea    0x4(%edx),%ecx
f0103375:	89 08                	mov    %ecx,(%eax)
f0103377:	8b 02                	mov    (%edx),%eax
f0103379:	ba 00 00 00 00       	mov    $0x0,%edx
}
f010337e:	5d                   	pop    %ebp
f010337f:	c3                   	ret    

f0103380 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0103380:	55                   	push   %ebp
f0103381:	89 e5                	mov    %esp,%ebp
f0103383:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0103386:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f010338a:	8b 10                	mov    (%eax),%edx
f010338c:	3b 50 04             	cmp    0x4(%eax),%edx
f010338f:	73 0a                	jae    f010339b <sprintputch+0x1b>
		*b->buf++ = ch;
f0103391:	8d 4a 01             	lea    0x1(%edx),%ecx
f0103394:	89 08                	mov    %ecx,(%eax)
f0103396:	8b 45 08             	mov    0x8(%ebp),%eax
f0103399:	88 02                	mov    %al,(%edx)
}
f010339b:	5d                   	pop    %ebp
f010339c:	c3                   	ret    

f010339d <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f010339d:	55                   	push   %ebp
f010339e:	89 e5                	mov    %esp,%ebp
f01033a0:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f01033a3:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f01033a6:	50                   	push   %eax
f01033a7:	ff 75 10             	pushl  0x10(%ebp)
f01033aa:	ff 75 0c             	pushl  0xc(%ebp)
f01033ad:	ff 75 08             	pushl  0x8(%ebp)
f01033b0:	e8 05 00 00 00       	call   f01033ba <vprintfmt>
	va_end(ap);
}
f01033b5:	83 c4 10             	add    $0x10,%esp
f01033b8:	c9                   	leave  
f01033b9:	c3                   	ret    

f01033ba <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f01033ba:	55                   	push   %ebp
f01033bb:	89 e5                	mov    %esp,%ebp
f01033bd:	57                   	push   %edi
f01033be:	56                   	push   %esi
f01033bf:	53                   	push   %ebx
f01033c0:	83 ec 2c             	sub    $0x2c,%esp
f01033c3:	8b 75 08             	mov    0x8(%ebp),%esi
f01033c6:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01033c9:	8b 7d 10             	mov    0x10(%ebp),%edi
f01033cc:	eb 12                	jmp    f01033e0 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f01033ce:	85 c0                	test   %eax,%eax
f01033d0:	0f 84 89 03 00 00    	je     f010375f <vprintfmt+0x3a5>
				return;
			putch(ch, putdat);
f01033d6:	83 ec 08             	sub    $0x8,%esp
f01033d9:	53                   	push   %ebx
f01033da:	50                   	push   %eax
f01033db:	ff d6                	call   *%esi
f01033dd:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f01033e0:	83 c7 01             	add    $0x1,%edi
f01033e3:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f01033e7:	83 f8 25             	cmp    $0x25,%eax
f01033ea:	75 e2                	jne    f01033ce <vprintfmt+0x14>
f01033ec:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f01033f0:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f01033f7:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f01033fe:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0103405:	ba 00 00 00 00       	mov    $0x0,%edx
f010340a:	eb 07                	jmp    f0103413 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010340c:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f010340f:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103413:	8d 47 01             	lea    0x1(%edi),%eax
f0103416:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103419:	0f b6 07             	movzbl (%edi),%eax
f010341c:	0f b6 c8             	movzbl %al,%ecx
f010341f:	83 e8 23             	sub    $0x23,%eax
f0103422:	3c 55                	cmp    $0x55,%al
f0103424:	0f 87 1a 03 00 00    	ja     f0103744 <vprintfmt+0x38a>
f010342a:	0f b6 c0             	movzbl %al,%eax
f010342d:	ff 24 85 6c 53 10 f0 	jmp    *-0xfefac94(,%eax,4)
f0103434:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0103437:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f010343b:	eb d6                	jmp    f0103413 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010343d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103440:	b8 00 00 00 00       	mov    $0x0,%eax
f0103445:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0103448:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010344b:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f010344f:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0103452:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0103455:	83 fa 09             	cmp    $0x9,%edx
f0103458:	77 39                	ja     f0103493 <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f010345a:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f010345d:	eb e9                	jmp    f0103448 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f010345f:	8b 45 14             	mov    0x14(%ebp),%eax
f0103462:	8d 48 04             	lea    0x4(%eax),%ecx
f0103465:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0103468:	8b 00                	mov    (%eax),%eax
f010346a:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010346d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0103470:	eb 27                	jmp    f0103499 <vprintfmt+0xdf>
f0103472:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103475:	85 c0                	test   %eax,%eax
f0103477:	b9 00 00 00 00       	mov    $0x0,%ecx
f010347c:	0f 49 c8             	cmovns %eax,%ecx
f010347f:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103482:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103485:	eb 8c                	jmp    f0103413 <vprintfmt+0x59>
f0103487:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f010348a:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0103491:	eb 80                	jmp    f0103413 <vprintfmt+0x59>
f0103493:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0103496:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0103499:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f010349d:	0f 89 70 ff ff ff    	jns    f0103413 <vprintfmt+0x59>
				width = precision, precision = -1;
f01034a3:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01034a6:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01034a9:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f01034b0:	e9 5e ff ff ff       	jmp    f0103413 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f01034b5:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01034b8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f01034bb:	e9 53 ff ff ff       	jmp    f0103413 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f01034c0:	8b 45 14             	mov    0x14(%ebp),%eax
f01034c3:	8d 50 04             	lea    0x4(%eax),%edx
f01034c6:	89 55 14             	mov    %edx,0x14(%ebp)
f01034c9:	83 ec 08             	sub    $0x8,%esp
f01034cc:	53                   	push   %ebx
f01034cd:	ff 30                	pushl  (%eax)
f01034cf:	ff d6                	call   *%esi
			break;
f01034d1:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01034d4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f01034d7:	e9 04 ff ff ff       	jmp    f01033e0 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f01034dc:	8b 45 14             	mov    0x14(%ebp),%eax
f01034df:	8d 50 04             	lea    0x4(%eax),%edx
f01034e2:	89 55 14             	mov    %edx,0x14(%ebp)
f01034e5:	8b 00                	mov    (%eax),%eax
f01034e7:	99                   	cltd   
f01034e8:	31 d0                	xor    %edx,%eax
f01034ea:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f01034ec:	83 f8 06             	cmp    $0x6,%eax
f01034ef:	7f 0b                	jg     f01034fc <vprintfmt+0x142>
f01034f1:	8b 14 85 c4 54 10 f0 	mov    -0xfefab3c(,%eax,4),%edx
f01034f8:	85 d2                	test   %edx,%edx
f01034fa:	75 18                	jne    f0103514 <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f01034fc:	50                   	push   %eax
f01034fd:	68 f9 52 10 f0       	push   $0xf01052f9
f0103502:	53                   	push   %ebx
f0103503:	56                   	push   %esi
f0103504:	e8 94 fe ff ff       	call   f010339d <printfmt>
f0103509:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010350c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f010350f:	e9 cc fe ff ff       	jmp    f01033e0 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0103514:	52                   	push   %edx
f0103515:	68 b4 4b 10 f0       	push   $0xf0104bb4
f010351a:	53                   	push   %ebx
f010351b:	56                   	push   %esi
f010351c:	e8 7c fe ff ff       	call   f010339d <printfmt>
f0103521:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103524:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103527:	e9 b4 fe ff ff       	jmp    f01033e0 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f010352c:	8b 45 14             	mov    0x14(%ebp),%eax
f010352f:	8d 50 04             	lea    0x4(%eax),%edx
f0103532:	89 55 14             	mov    %edx,0x14(%ebp)
f0103535:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0103537:	85 ff                	test   %edi,%edi
f0103539:	b8 f2 52 10 f0       	mov    $0xf01052f2,%eax
f010353e:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0103541:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0103545:	0f 8e 94 00 00 00    	jle    f01035df <vprintfmt+0x225>
f010354b:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f010354f:	0f 84 98 00 00 00    	je     f01035ed <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
f0103555:	83 ec 08             	sub    $0x8,%esp
f0103558:	ff 75 d0             	pushl  -0x30(%ebp)
f010355b:	57                   	push   %edi
f010355c:	e8 5f 03 00 00       	call   f01038c0 <strnlen>
f0103561:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0103564:	29 c1                	sub    %eax,%ecx
f0103566:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0103569:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f010356c:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0103570:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103573:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0103576:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0103578:	eb 0f                	jmp    f0103589 <vprintfmt+0x1cf>
					putch(padc, putdat);
f010357a:	83 ec 08             	sub    $0x8,%esp
f010357d:	53                   	push   %ebx
f010357e:	ff 75 e0             	pushl  -0x20(%ebp)
f0103581:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0103583:	83 ef 01             	sub    $0x1,%edi
f0103586:	83 c4 10             	add    $0x10,%esp
f0103589:	85 ff                	test   %edi,%edi
f010358b:	7f ed                	jg     f010357a <vprintfmt+0x1c0>
f010358d:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0103590:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0103593:	85 c9                	test   %ecx,%ecx
f0103595:	b8 00 00 00 00       	mov    $0x0,%eax
f010359a:	0f 49 c1             	cmovns %ecx,%eax
f010359d:	29 c1                	sub    %eax,%ecx
f010359f:	89 75 08             	mov    %esi,0x8(%ebp)
f01035a2:	8b 75 d0             	mov    -0x30(%ebp),%esi
f01035a5:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f01035a8:	89 cb                	mov    %ecx,%ebx
f01035aa:	eb 4d                	jmp    f01035f9 <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f01035ac:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f01035b0:	74 1b                	je     f01035cd <vprintfmt+0x213>
f01035b2:	0f be c0             	movsbl %al,%eax
f01035b5:	83 e8 20             	sub    $0x20,%eax
f01035b8:	83 f8 5e             	cmp    $0x5e,%eax
f01035bb:	76 10                	jbe    f01035cd <vprintfmt+0x213>
					putch('?', putdat);
f01035bd:	83 ec 08             	sub    $0x8,%esp
f01035c0:	ff 75 0c             	pushl  0xc(%ebp)
f01035c3:	6a 3f                	push   $0x3f
f01035c5:	ff 55 08             	call   *0x8(%ebp)
f01035c8:	83 c4 10             	add    $0x10,%esp
f01035cb:	eb 0d                	jmp    f01035da <vprintfmt+0x220>
				else
					putch(ch, putdat);
f01035cd:	83 ec 08             	sub    $0x8,%esp
f01035d0:	ff 75 0c             	pushl  0xc(%ebp)
f01035d3:	52                   	push   %edx
f01035d4:	ff 55 08             	call   *0x8(%ebp)
f01035d7:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01035da:	83 eb 01             	sub    $0x1,%ebx
f01035dd:	eb 1a                	jmp    f01035f9 <vprintfmt+0x23f>
f01035df:	89 75 08             	mov    %esi,0x8(%ebp)
f01035e2:	8b 75 d0             	mov    -0x30(%ebp),%esi
f01035e5:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f01035e8:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f01035eb:	eb 0c                	jmp    f01035f9 <vprintfmt+0x23f>
f01035ed:	89 75 08             	mov    %esi,0x8(%ebp)
f01035f0:	8b 75 d0             	mov    -0x30(%ebp),%esi
f01035f3:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f01035f6:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f01035f9:	83 c7 01             	add    $0x1,%edi
f01035fc:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0103600:	0f be d0             	movsbl %al,%edx
f0103603:	85 d2                	test   %edx,%edx
f0103605:	74 23                	je     f010362a <vprintfmt+0x270>
f0103607:	85 f6                	test   %esi,%esi
f0103609:	78 a1                	js     f01035ac <vprintfmt+0x1f2>
f010360b:	83 ee 01             	sub    $0x1,%esi
f010360e:	79 9c                	jns    f01035ac <vprintfmt+0x1f2>
f0103610:	89 df                	mov    %ebx,%edi
f0103612:	8b 75 08             	mov    0x8(%ebp),%esi
f0103615:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103618:	eb 18                	jmp    f0103632 <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f010361a:	83 ec 08             	sub    $0x8,%esp
f010361d:	53                   	push   %ebx
f010361e:	6a 20                	push   $0x20
f0103620:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0103622:	83 ef 01             	sub    $0x1,%edi
f0103625:	83 c4 10             	add    $0x10,%esp
f0103628:	eb 08                	jmp    f0103632 <vprintfmt+0x278>
f010362a:	89 df                	mov    %ebx,%edi
f010362c:	8b 75 08             	mov    0x8(%ebp),%esi
f010362f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103632:	85 ff                	test   %edi,%edi
f0103634:	7f e4                	jg     f010361a <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103636:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103639:	e9 a2 fd ff ff       	jmp    f01033e0 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f010363e:	83 fa 01             	cmp    $0x1,%edx
f0103641:	7e 16                	jle    f0103659 <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f0103643:	8b 45 14             	mov    0x14(%ebp),%eax
f0103646:	8d 50 08             	lea    0x8(%eax),%edx
f0103649:	89 55 14             	mov    %edx,0x14(%ebp)
f010364c:	8b 50 04             	mov    0x4(%eax),%edx
f010364f:	8b 00                	mov    (%eax),%eax
f0103651:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103654:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0103657:	eb 32                	jmp    f010368b <vprintfmt+0x2d1>
	else if (lflag)
f0103659:	85 d2                	test   %edx,%edx
f010365b:	74 18                	je     f0103675 <vprintfmt+0x2bb>
		return va_arg(*ap, long);
f010365d:	8b 45 14             	mov    0x14(%ebp),%eax
f0103660:	8d 50 04             	lea    0x4(%eax),%edx
f0103663:	89 55 14             	mov    %edx,0x14(%ebp)
f0103666:	8b 00                	mov    (%eax),%eax
f0103668:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010366b:	89 c1                	mov    %eax,%ecx
f010366d:	c1 f9 1f             	sar    $0x1f,%ecx
f0103670:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0103673:	eb 16                	jmp    f010368b <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
f0103675:	8b 45 14             	mov    0x14(%ebp),%eax
f0103678:	8d 50 04             	lea    0x4(%eax),%edx
f010367b:	89 55 14             	mov    %edx,0x14(%ebp)
f010367e:	8b 00                	mov    (%eax),%eax
f0103680:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103683:	89 c1                	mov    %eax,%ecx
f0103685:	c1 f9 1f             	sar    $0x1f,%ecx
f0103688:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f010368b:	8b 45 d8             	mov    -0x28(%ebp),%eax
f010368e:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0103691:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0103696:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f010369a:	79 74                	jns    f0103710 <vprintfmt+0x356>
				putch('-', putdat);
f010369c:	83 ec 08             	sub    $0x8,%esp
f010369f:	53                   	push   %ebx
f01036a0:	6a 2d                	push   $0x2d
f01036a2:	ff d6                	call   *%esi
				num = -(long long) num;
f01036a4:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01036a7:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01036aa:	f7 d8                	neg    %eax
f01036ac:	83 d2 00             	adc    $0x0,%edx
f01036af:	f7 da                	neg    %edx
f01036b1:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f01036b4:	b9 0a 00 00 00       	mov    $0xa,%ecx
f01036b9:	eb 55                	jmp    f0103710 <vprintfmt+0x356>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f01036bb:	8d 45 14             	lea    0x14(%ebp),%eax
f01036be:	e8 83 fc ff ff       	call   f0103346 <getuint>
			base = 10;
f01036c3:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f01036c8:	eb 46                	jmp    f0103710 <vprintfmt+0x356>
		// (unsigned) octal
		case 'o':
			//putch('X', putdat);
			//putch('X', putdat);
			//putch('X', putdat);
			num = getuint(&ap, lflag);
f01036ca:	8d 45 14             	lea    0x14(%ebp),%eax
f01036cd:	e8 74 fc ff ff       	call   f0103346 <getuint>
			base = 8;
f01036d2:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f01036d7:	eb 37                	jmp    f0103710 <vprintfmt+0x356>

		// pointer
		case 'p':
			putch('0', putdat);
f01036d9:	83 ec 08             	sub    $0x8,%esp
f01036dc:	53                   	push   %ebx
f01036dd:	6a 30                	push   $0x30
f01036df:	ff d6                	call   *%esi
			putch('x', putdat);
f01036e1:	83 c4 08             	add    $0x8,%esp
f01036e4:	53                   	push   %ebx
f01036e5:	6a 78                	push   $0x78
f01036e7:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f01036e9:	8b 45 14             	mov    0x14(%ebp),%eax
f01036ec:	8d 50 04             	lea    0x4(%eax),%edx
f01036ef:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f01036f2:	8b 00                	mov    (%eax),%eax
f01036f4:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f01036f9:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f01036fc:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0103701:	eb 0d                	jmp    f0103710 <vprintfmt+0x356>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0103703:	8d 45 14             	lea    0x14(%ebp),%eax
f0103706:	e8 3b fc ff ff       	call   f0103346 <getuint>
			base = 16;
f010370b:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0103710:	83 ec 0c             	sub    $0xc,%esp
f0103713:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0103717:	57                   	push   %edi
f0103718:	ff 75 e0             	pushl  -0x20(%ebp)
f010371b:	51                   	push   %ecx
f010371c:	52                   	push   %edx
f010371d:	50                   	push   %eax
f010371e:	89 da                	mov    %ebx,%edx
f0103720:	89 f0                	mov    %esi,%eax
f0103722:	e8 70 fb ff ff       	call   f0103297 <printnum>
			break;
f0103727:	83 c4 20             	add    $0x20,%esp
f010372a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010372d:	e9 ae fc ff ff       	jmp    f01033e0 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0103732:	83 ec 08             	sub    $0x8,%esp
f0103735:	53                   	push   %ebx
f0103736:	51                   	push   %ecx
f0103737:	ff d6                	call   *%esi
			break;
f0103739:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010373c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f010373f:	e9 9c fc ff ff       	jmp    f01033e0 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0103744:	83 ec 08             	sub    $0x8,%esp
f0103747:	53                   	push   %ebx
f0103748:	6a 25                	push   $0x25
f010374a:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f010374c:	83 c4 10             	add    $0x10,%esp
f010374f:	eb 03                	jmp    f0103754 <vprintfmt+0x39a>
f0103751:	83 ef 01             	sub    $0x1,%edi
f0103754:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0103758:	75 f7                	jne    f0103751 <vprintfmt+0x397>
f010375a:	e9 81 fc ff ff       	jmp    f01033e0 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f010375f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103762:	5b                   	pop    %ebx
f0103763:	5e                   	pop    %esi
f0103764:	5f                   	pop    %edi
f0103765:	5d                   	pop    %ebp
f0103766:	c3                   	ret    

f0103767 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0103767:	55                   	push   %ebp
f0103768:	89 e5                	mov    %esp,%ebp
f010376a:	83 ec 18             	sub    $0x18,%esp
f010376d:	8b 45 08             	mov    0x8(%ebp),%eax
f0103770:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0103773:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103776:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f010377a:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f010377d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0103784:	85 c0                	test   %eax,%eax
f0103786:	74 26                	je     f01037ae <vsnprintf+0x47>
f0103788:	85 d2                	test   %edx,%edx
f010378a:	7e 22                	jle    f01037ae <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f010378c:	ff 75 14             	pushl  0x14(%ebp)
f010378f:	ff 75 10             	pushl  0x10(%ebp)
f0103792:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0103795:	50                   	push   %eax
f0103796:	68 80 33 10 f0       	push   $0xf0103380
f010379b:	e8 1a fc ff ff       	call   f01033ba <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01037a0:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01037a3:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01037a6:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01037a9:	83 c4 10             	add    $0x10,%esp
f01037ac:	eb 05                	jmp    f01037b3 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f01037ae:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f01037b3:	c9                   	leave  
f01037b4:	c3                   	ret    

f01037b5 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01037b5:	55                   	push   %ebp
f01037b6:	89 e5                	mov    %esp,%ebp
f01037b8:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01037bb:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01037be:	50                   	push   %eax
f01037bf:	ff 75 10             	pushl  0x10(%ebp)
f01037c2:	ff 75 0c             	pushl  0xc(%ebp)
f01037c5:	ff 75 08             	pushl  0x8(%ebp)
f01037c8:	e8 9a ff ff ff       	call   f0103767 <vsnprintf>
	va_end(ap);

	return rc;
}
f01037cd:	c9                   	leave  
f01037ce:	c3                   	ret    

f01037cf <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01037cf:	55                   	push   %ebp
f01037d0:	89 e5                	mov    %esp,%ebp
f01037d2:	57                   	push   %edi
f01037d3:	56                   	push   %esi
f01037d4:	53                   	push   %ebx
f01037d5:	83 ec 0c             	sub    $0xc,%esp
f01037d8:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01037db:	85 c0                	test   %eax,%eax
f01037dd:	74 11                	je     f01037f0 <readline+0x21>
		cprintf("%s", prompt);
f01037df:	83 ec 08             	sub    $0x8,%esp
f01037e2:	50                   	push   %eax
f01037e3:	68 b4 4b 10 f0       	push   $0xf0104bb4
f01037e8:	e8 b5 f3 ff ff       	call   f0102ba2 <cprintf>
f01037ed:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f01037f0:	83 ec 0c             	sub    $0xc,%esp
f01037f3:	6a 00                	push   $0x0
f01037f5:	e8 3c ce ff ff       	call   f0100636 <iscons>
f01037fa:	89 c7                	mov    %eax,%edi
f01037fc:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f01037ff:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0103804:	e8 1c ce ff ff       	call   f0100625 <getchar>
f0103809:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010380b:	85 c0                	test   %eax,%eax
f010380d:	79 18                	jns    f0103827 <readline+0x58>
			cprintf("read error: %e\n", c);
f010380f:	83 ec 08             	sub    $0x8,%esp
f0103812:	50                   	push   %eax
f0103813:	68 e0 54 10 f0       	push   $0xf01054e0
f0103818:	e8 85 f3 ff ff       	call   f0102ba2 <cprintf>
			return NULL;
f010381d:	83 c4 10             	add    $0x10,%esp
f0103820:	b8 00 00 00 00       	mov    $0x0,%eax
f0103825:	eb 79                	jmp    f01038a0 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0103827:	83 f8 08             	cmp    $0x8,%eax
f010382a:	0f 94 c2             	sete   %dl
f010382d:	83 f8 7f             	cmp    $0x7f,%eax
f0103830:	0f 94 c0             	sete   %al
f0103833:	08 c2                	or     %al,%dl
f0103835:	74 1a                	je     f0103851 <readline+0x82>
f0103837:	85 f6                	test   %esi,%esi
f0103839:	7e 16                	jle    f0103851 <readline+0x82>
			if (echoing)
f010383b:	85 ff                	test   %edi,%edi
f010383d:	74 0d                	je     f010384c <readline+0x7d>
				cputchar('\b');
f010383f:	83 ec 0c             	sub    $0xc,%esp
f0103842:	6a 08                	push   $0x8
f0103844:	e8 cc cd ff ff       	call   f0100615 <cputchar>
f0103849:	83 c4 10             	add    $0x10,%esp
			i--;
f010384c:	83 ee 01             	sub    $0x1,%esi
f010384f:	eb b3                	jmp    f0103804 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0103851:	83 fb 1f             	cmp    $0x1f,%ebx
f0103854:	7e 23                	jle    f0103879 <readline+0xaa>
f0103856:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010385c:	7f 1b                	jg     f0103879 <readline+0xaa>
			if (echoing)
f010385e:	85 ff                	test   %edi,%edi
f0103860:	74 0c                	je     f010386e <readline+0x9f>
				cputchar(c);
f0103862:	83 ec 0c             	sub    $0xc,%esp
f0103865:	53                   	push   %ebx
f0103866:	e8 aa cd ff ff       	call   f0100615 <cputchar>
f010386b:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f010386e:	88 9e 40 f8 16 f0    	mov    %bl,-0xfe907c0(%esi)
f0103874:	8d 76 01             	lea    0x1(%esi),%esi
f0103877:	eb 8b                	jmp    f0103804 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0103879:	83 fb 0a             	cmp    $0xa,%ebx
f010387c:	74 05                	je     f0103883 <readline+0xb4>
f010387e:	83 fb 0d             	cmp    $0xd,%ebx
f0103881:	75 81                	jne    f0103804 <readline+0x35>
			if (echoing)
f0103883:	85 ff                	test   %edi,%edi
f0103885:	74 0d                	je     f0103894 <readline+0xc5>
				cputchar('\n');
f0103887:	83 ec 0c             	sub    $0xc,%esp
f010388a:	6a 0a                	push   $0xa
f010388c:	e8 84 cd ff ff       	call   f0100615 <cputchar>
f0103891:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0103894:	c6 86 40 f8 16 f0 00 	movb   $0x0,-0xfe907c0(%esi)
			return buf;
f010389b:	b8 40 f8 16 f0       	mov    $0xf016f840,%eax
		}
	}
}
f01038a0:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01038a3:	5b                   	pop    %ebx
f01038a4:	5e                   	pop    %esi
f01038a5:	5f                   	pop    %edi
f01038a6:	5d                   	pop    %ebp
f01038a7:	c3                   	ret    

f01038a8 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01038a8:	55                   	push   %ebp
f01038a9:	89 e5                	mov    %esp,%ebp
f01038ab:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01038ae:	b8 00 00 00 00       	mov    $0x0,%eax
f01038b3:	eb 03                	jmp    f01038b8 <strlen+0x10>
		n++;
f01038b5:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01038b8:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01038bc:	75 f7                	jne    f01038b5 <strlen+0xd>
		n++;
	return n;
}
f01038be:	5d                   	pop    %ebp
f01038bf:	c3                   	ret    

f01038c0 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01038c0:	55                   	push   %ebp
f01038c1:	89 e5                	mov    %esp,%ebp
f01038c3:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01038c6:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01038c9:	ba 00 00 00 00       	mov    $0x0,%edx
f01038ce:	eb 03                	jmp    f01038d3 <strnlen+0x13>
		n++;
f01038d0:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01038d3:	39 c2                	cmp    %eax,%edx
f01038d5:	74 08                	je     f01038df <strnlen+0x1f>
f01038d7:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f01038db:	75 f3                	jne    f01038d0 <strnlen+0x10>
f01038dd:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f01038df:	5d                   	pop    %ebp
f01038e0:	c3                   	ret    

f01038e1 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01038e1:	55                   	push   %ebp
f01038e2:	89 e5                	mov    %esp,%ebp
f01038e4:	53                   	push   %ebx
f01038e5:	8b 45 08             	mov    0x8(%ebp),%eax
f01038e8:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01038eb:	89 c2                	mov    %eax,%edx
f01038ed:	83 c2 01             	add    $0x1,%edx
f01038f0:	83 c1 01             	add    $0x1,%ecx
f01038f3:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f01038f7:	88 5a ff             	mov    %bl,-0x1(%edx)
f01038fa:	84 db                	test   %bl,%bl
f01038fc:	75 ef                	jne    f01038ed <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f01038fe:	5b                   	pop    %ebx
f01038ff:	5d                   	pop    %ebp
f0103900:	c3                   	ret    

f0103901 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0103901:	55                   	push   %ebp
f0103902:	89 e5                	mov    %esp,%ebp
f0103904:	53                   	push   %ebx
f0103905:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0103908:	53                   	push   %ebx
f0103909:	e8 9a ff ff ff       	call   f01038a8 <strlen>
f010390e:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0103911:	ff 75 0c             	pushl  0xc(%ebp)
f0103914:	01 d8                	add    %ebx,%eax
f0103916:	50                   	push   %eax
f0103917:	e8 c5 ff ff ff       	call   f01038e1 <strcpy>
	return dst;
}
f010391c:	89 d8                	mov    %ebx,%eax
f010391e:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103921:	c9                   	leave  
f0103922:	c3                   	ret    

f0103923 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0103923:	55                   	push   %ebp
f0103924:	89 e5                	mov    %esp,%ebp
f0103926:	56                   	push   %esi
f0103927:	53                   	push   %ebx
f0103928:	8b 75 08             	mov    0x8(%ebp),%esi
f010392b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010392e:	89 f3                	mov    %esi,%ebx
f0103930:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103933:	89 f2                	mov    %esi,%edx
f0103935:	eb 0f                	jmp    f0103946 <strncpy+0x23>
		*dst++ = *src;
f0103937:	83 c2 01             	add    $0x1,%edx
f010393a:	0f b6 01             	movzbl (%ecx),%eax
f010393d:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0103940:	80 39 01             	cmpb   $0x1,(%ecx)
f0103943:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103946:	39 da                	cmp    %ebx,%edx
f0103948:	75 ed                	jne    f0103937 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f010394a:	89 f0                	mov    %esi,%eax
f010394c:	5b                   	pop    %ebx
f010394d:	5e                   	pop    %esi
f010394e:	5d                   	pop    %ebp
f010394f:	c3                   	ret    

f0103950 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0103950:	55                   	push   %ebp
f0103951:	89 e5                	mov    %esp,%ebp
f0103953:	56                   	push   %esi
f0103954:	53                   	push   %ebx
f0103955:	8b 75 08             	mov    0x8(%ebp),%esi
f0103958:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010395b:	8b 55 10             	mov    0x10(%ebp),%edx
f010395e:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0103960:	85 d2                	test   %edx,%edx
f0103962:	74 21                	je     f0103985 <strlcpy+0x35>
f0103964:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0103968:	89 f2                	mov    %esi,%edx
f010396a:	eb 09                	jmp    f0103975 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f010396c:	83 c2 01             	add    $0x1,%edx
f010396f:	83 c1 01             	add    $0x1,%ecx
f0103972:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0103975:	39 c2                	cmp    %eax,%edx
f0103977:	74 09                	je     f0103982 <strlcpy+0x32>
f0103979:	0f b6 19             	movzbl (%ecx),%ebx
f010397c:	84 db                	test   %bl,%bl
f010397e:	75 ec                	jne    f010396c <strlcpy+0x1c>
f0103980:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f0103982:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0103985:	29 f0                	sub    %esi,%eax
}
f0103987:	5b                   	pop    %ebx
f0103988:	5e                   	pop    %esi
f0103989:	5d                   	pop    %ebp
f010398a:	c3                   	ret    

f010398b <strcmp>:

int
strcmp(const char *p, const char *q)
{
f010398b:	55                   	push   %ebp
f010398c:	89 e5                	mov    %esp,%ebp
f010398e:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103991:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0103994:	eb 06                	jmp    f010399c <strcmp+0x11>
		p++, q++;
f0103996:	83 c1 01             	add    $0x1,%ecx
f0103999:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f010399c:	0f b6 01             	movzbl (%ecx),%eax
f010399f:	84 c0                	test   %al,%al
f01039a1:	74 04                	je     f01039a7 <strcmp+0x1c>
f01039a3:	3a 02                	cmp    (%edx),%al
f01039a5:	74 ef                	je     f0103996 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01039a7:	0f b6 c0             	movzbl %al,%eax
f01039aa:	0f b6 12             	movzbl (%edx),%edx
f01039ad:	29 d0                	sub    %edx,%eax
}
f01039af:	5d                   	pop    %ebp
f01039b0:	c3                   	ret    

f01039b1 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01039b1:	55                   	push   %ebp
f01039b2:	89 e5                	mov    %esp,%ebp
f01039b4:	53                   	push   %ebx
f01039b5:	8b 45 08             	mov    0x8(%ebp),%eax
f01039b8:	8b 55 0c             	mov    0xc(%ebp),%edx
f01039bb:	89 c3                	mov    %eax,%ebx
f01039bd:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01039c0:	eb 06                	jmp    f01039c8 <strncmp+0x17>
		n--, p++, q++;
f01039c2:	83 c0 01             	add    $0x1,%eax
f01039c5:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01039c8:	39 d8                	cmp    %ebx,%eax
f01039ca:	74 15                	je     f01039e1 <strncmp+0x30>
f01039cc:	0f b6 08             	movzbl (%eax),%ecx
f01039cf:	84 c9                	test   %cl,%cl
f01039d1:	74 04                	je     f01039d7 <strncmp+0x26>
f01039d3:	3a 0a                	cmp    (%edx),%cl
f01039d5:	74 eb                	je     f01039c2 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01039d7:	0f b6 00             	movzbl (%eax),%eax
f01039da:	0f b6 12             	movzbl (%edx),%edx
f01039dd:	29 d0                	sub    %edx,%eax
f01039df:	eb 05                	jmp    f01039e6 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f01039e1:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01039e6:	5b                   	pop    %ebx
f01039e7:	5d                   	pop    %ebp
f01039e8:	c3                   	ret    

f01039e9 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01039e9:	55                   	push   %ebp
f01039ea:	89 e5                	mov    %esp,%ebp
f01039ec:	8b 45 08             	mov    0x8(%ebp),%eax
f01039ef:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01039f3:	eb 07                	jmp    f01039fc <strchr+0x13>
		if (*s == c)
f01039f5:	38 ca                	cmp    %cl,%dl
f01039f7:	74 0f                	je     f0103a08 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01039f9:	83 c0 01             	add    $0x1,%eax
f01039fc:	0f b6 10             	movzbl (%eax),%edx
f01039ff:	84 d2                	test   %dl,%dl
f0103a01:	75 f2                	jne    f01039f5 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0103a03:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103a08:	5d                   	pop    %ebp
f0103a09:	c3                   	ret    

f0103a0a <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0103a0a:	55                   	push   %ebp
f0103a0b:	89 e5                	mov    %esp,%ebp
f0103a0d:	8b 45 08             	mov    0x8(%ebp),%eax
f0103a10:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103a14:	eb 03                	jmp    f0103a19 <strfind+0xf>
f0103a16:	83 c0 01             	add    $0x1,%eax
f0103a19:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0103a1c:	38 ca                	cmp    %cl,%dl
f0103a1e:	74 04                	je     f0103a24 <strfind+0x1a>
f0103a20:	84 d2                	test   %dl,%dl
f0103a22:	75 f2                	jne    f0103a16 <strfind+0xc>
			break;
	return (char *) s;
}
f0103a24:	5d                   	pop    %ebp
f0103a25:	c3                   	ret    

f0103a26 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0103a26:	55                   	push   %ebp
f0103a27:	89 e5                	mov    %esp,%ebp
f0103a29:	57                   	push   %edi
f0103a2a:	56                   	push   %esi
f0103a2b:	53                   	push   %ebx
f0103a2c:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103a2f:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0103a32:	85 c9                	test   %ecx,%ecx
f0103a34:	74 36                	je     f0103a6c <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0103a36:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0103a3c:	75 28                	jne    f0103a66 <memset+0x40>
f0103a3e:	f6 c1 03             	test   $0x3,%cl
f0103a41:	75 23                	jne    f0103a66 <memset+0x40>
		c &= 0xFF;
f0103a43:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0103a47:	89 d3                	mov    %edx,%ebx
f0103a49:	c1 e3 08             	shl    $0x8,%ebx
f0103a4c:	89 d6                	mov    %edx,%esi
f0103a4e:	c1 e6 18             	shl    $0x18,%esi
f0103a51:	89 d0                	mov    %edx,%eax
f0103a53:	c1 e0 10             	shl    $0x10,%eax
f0103a56:	09 f0                	or     %esi,%eax
f0103a58:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f0103a5a:	89 d8                	mov    %ebx,%eax
f0103a5c:	09 d0                	or     %edx,%eax
f0103a5e:	c1 e9 02             	shr    $0x2,%ecx
f0103a61:	fc                   	cld    
f0103a62:	f3 ab                	rep stos %eax,%es:(%edi)
f0103a64:	eb 06                	jmp    f0103a6c <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0103a66:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103a69:	fc                   	cld    
f0103a6a:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0103a6c:	89 f8                	mov    %edi,%eax
f0103a6e:	5b                   	pop    %ebx
f0103a6f:	5e                   	pop    %esi
f0103a70:	5f                   	pop    %edi
f0103a71:	5d                   	pop    %ebp
f0103a72:	c3                   	ret    

f0103a73 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0103a73:	55                   	push   %ebp
f0103a74:	89 e5                	mov    %esp,%ebp
f0103a76:	57                   	push   %edi
f0103a77:	56                   	push   %esi
f0103a78:	8b 45 08             	mov    0x8(%ebp),%eax
f0103a7b:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103a7e:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0103a81:	39 c6                	cmp    %eax,%esi
f0103a83:	73 35                	jae    f0103aba <memmove+0x47>
f0103a85:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0103a88:	39 d0                	cmp    %edx,%eax
f0103a8a:	73 2e                	jae    f0103aba <memmove+0x47>
		s += n;
		d += n;
f0103a8c:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103a8f:	89 d6                	mov    %edx,%esi
f0103a91:	09 fe                	or     %edi,%esi
f0103a93:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0103a99:	75 13                	jne    f0103aae <memmove+0x3b>
f0103a9b:	f6 c1 03             	test   $0x3,%cl
f0103a9e:	75 0e                	jne    f0103aae <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f0103aa0:	83 ef 04             	sub    $0x4,%edi
f0103aa3:	8d 72 fc             	lea    -0x4(%edx),%esi
f0103aa6:	c1 e9 02             	shr    $0x2,%ecx
f0103aa9:	fd                   	std    
f0103aaa:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103aac:	eb 09                	jmp    f0103ab7 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0103aae:	83 ef 01             	sub    $0x1,%edi
f0103ab1:	8d 72 ff             	lea    -0x1(%edx),%esi
f0103ab4:	fd                   	std    
f0103ab5:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0103ab7:	fc                   	cld    
f0103ab8:	eb 1d                	jmp    f0103ad7 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103aba:	89 f2                	mov    %esi,%edx
f0103abc:	09 c2                	or     %eax,%edx
f0103abe:	f6 c2 03             	test   $0x3,%dl
f0103ac1:	75 0f                	jne    f0103ad2 <memmove+0x5f>
f0103ac3:	f6 c1 03             	test   $0x3,%cl
f0103ac6:	75 0a                	jne    f0103ad2 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f0103ac8:	c1 e9 02             	shr    $0x2,%ecx
f0103acb:	89 c7                	mov    %eax,%edi
f0103acd:	fc                   	cld    
f0103ace:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103ad0:	eb 05                	jmp    f0103ad7 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0103ad2:	89 c7                	mov    %eax,%edi
f0103ad4:	fc                   	cld    
f0103ad5:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0103ad7:	5e                   	pop    %esi
f0103ad8:	5f                   	pop    %edi
f0103ad9:	5d                   	pop    %ebp
f0103ada:	c3                   	ret    

f0103adb <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0103adb:	55                   	push   %ebp
f0103adc:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0103ade:	ff 75 10             	pushl  0x10(%ebp)
f0103ae1:	ff 75 0c             	pushl  0xc(%ebp)
f0103ae4:	ff 75 08             	pushl  0x8(%ebp)
f0103ae7:	e8 87 ff ff ff       	call   f0103a73 <memmove>
}
f0103aec:	c9                   	leave  
f0103aed:	c3                   	ret    

f0103aee <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0103aee:	55                   	push   %ebp
f0103aef:	89 e5                	mov    %esp,%ebp
f0103af1:	56                   	push   %esi
f0103af2:	53                   	push   %ebx
f0103af3:	8b 45 08             	mov    0x8(%ebp),%eax
f0103af6:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103af9:	89 c6                	mov    %eax,%esi
f0103afb:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103afe:	eb 1a                	jmp    f0103b1a <memcmp+0x2c>
		if (*s1 != *s2)
f0103b00:	0f b6 08             	movzbl (%eax),%ecx
f0103b03:	0f b6 1a             	movzbl (%edx),%ebx
f0103b06:	38 d9                	cmp    %bl,%cl
f0103b08:	74 0a                	je     f0103b14 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0103b0a:	0f b6 c1             	movzbl %cl,%eax
f0103b0d:	0f b6 db             	movzbl %bl,%ebx
f0103b10:	29 d8                	sub    %ebx,%eax
f0103b12:	eb 0f                	jmp    f0103b23 <memcmp+0x35>
		s1++, s2++;
f0103b14:	83 c0 01             	add    $0x1,%eax
f0103b17:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103b1a:	39 f0                	cmp    %esi,%eax
f0103b1c:	75 e2                	jne    f0103b00 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0103b1e:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103b23:	5b                   	pop    %ebx
f0103b24:	5e                   	pop    %esi
f0103b25:	5d                   	pop    %ebp
f0103b26:	c3                   	ret    

f0103b27 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0103b27:	55                   	push   %ebp
f0103b28:	89 e5                	mov    %esp,%ebp
f0103b2a:	53                   	push   %ebx
f0103b2b:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0103b2e:	89 c1                	mov    %eax,%ecx
f0103b30:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f0103b33:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0103b37:	eb 0a                	jmp    f0103b43 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f0103b39:	0f b6 10             	movzbl (%eax),%edx
f0103b3c:	39 da                	cmp    %ebx,%edx
f0103b3e:	74 07                	je     f0103b47 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0103b40:	83 c0 01             	add    $0x1,%eax
f0103b43:	39 c8                	cmp    %ecx,%eax
f0103b45:	72 f2                	jb     f0103b39 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0103b47:	5b                   	pop    %ebx
f0103b48:	5d                   	pop    %ebp
f0103b49:	c3                   	ret    

f0103b4a <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0103b4a:	55                   	push   %ebp
f0103b4b:	89 e5                	mov    %esp,%ebp
f0103b4d:	57                   	push   %edi
f0103b4e:	56                   	push   %esi
f0103b4f:	53                   	push   %ebx
f0103b50:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103b53:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103b56:	eb 03                	jmp    f0103b5b <strtol+0x11>
		s++;
f0103b58:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103b5b:	0f b6 01             	movzbl (%ecx),%eax
f0103b5e:	3c 20                	cmp    $0x20,%al
f0103b60:	74 f6                	je     f0103b58 <strtol+0xe>
f0103b62:	3c 09                	cmp    $0x9,%al
f0103b64:	74 f2                	je     f0103b58 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0103b66:	3c 2b                	cmp    $0x2b,%al
f0103b68:	75 0a                	jne    f0103b74 <strtol+0x2a>
		s++;
f0103b6a:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0103b6d:	bf 00 00 00 00       	mov    $0x0,%edi
f0103b72:	eb 11                	jmp    f0103b85 <strtol+0x3b>
f0103b74:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0103b79:	3c 2d                	cmp    $0x2d,%al
f0103b7b:	75 08                	jne    f0103b85 <strtol+0x3b>
		s++, neg = 1;
f0103b7d:	83 c1 01             	add    $0x1,%ecx
f0103b80:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0103b85:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0103b8b:	75 15                	jne    f0103ba2 <strtol+0x58>
f0103b8d:	80 39 30             	cmpb   $0x30,(%ecx)
f0103b90:	75 10                	jne    f0103ba2 <strtol+0x58>
f0103b92:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0103b96:	75 7c                	jne    f0103c14 <strtol+0xca>
		s += 2, base = 16;
f0103b98:	83 c1 02             	add    $0x2,%ecx
f0103b9b:	bb 10 00 00 00       	mov    $0x10,%ebx
f0103ba0:	eb 16                	jmp    f0103bb8 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f0103ba2:	85 db                	test   %ebx,%ebx
f0103ba4:	75 12                	jne    f0103bb8 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0103ba6:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0103bab:	80 39 30             	cmpb   $0x30,(%ecx)
f0103bae:	75 08                	jne    f0103bb8 <strtol+0x6e>
		s++, base = 8;
f0103bb0:	83 c1 01             	add    $0x1,%ecx
f0103bb3:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f0103bb8:	b8 00 00 00 00       	mov    $0x0,%eax
f0103bbd:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0103bc0:	0f b6 11             	movzbl (%ecx),%edx
f0103bc3:	8d 72 d0             	lea    -0x30(%edx),%esi
f0103bc6:	89 f3                	mov    %esi,%ebx
f0103bc8:	80 fb 09             	cmp    $0x9,%bl
f0103bcb:	77 08                	ja     f0103bd5 <strtol+0x8b>
			dig = *s - '0';
f0103bcd:	0f be d2             	movsbl %dl,%edx
f0103bd0:	83 ea 30             	sub    $0x30,%edx
f0103bd3:	eb 22                	jmp    f0103bf7 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f0103bd5:	8d 72 9f             	lea    -0x61(%edx),%esi
f0103bd8:	89 f3                	mov    %esi,%ebx
f0103bda:	80 fb 19             	cmp    $0x19,%bl
f0103bdd:	77 08                	ja     f0103be7 <strtol+0x9d>
			dig = *s - 'a' + 10;
f0103bdf:	0f be d2             	movsbl %dl,%edx
f0103be2:	83 ea 57             	sub    $0x57,%edx
f0103be5:	eb 10                	jmp    f0103bf7 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f0103be7:	8d 72 bf             	lea    -0x41(%edx),%esi
f0103bea:	89 f3                	mov    %esi,%ebx
f0103bec:	80 fb 19             	cmp    $0x19,%bl
f0103bef:	77 16                	ja     f0103c07 <strtol+0xbd>
			dig = *s - 'A' + 10;
f0103bf1:	0f be d2             	movsbl %dl,%edx
f0103bf4:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f0103bf7:	3b 55 10             	cmp    0x10(%ebp),%edx
f0103bfa:	7d 0b                	jge    f0103c07 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f0103bfc:	83 c1 01             	add    $0x1,%ecx
f0103bff:	0f af 45 10          	imul   0x10(%ebp),%eax
f0103c03:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f0103c05:	eb b9                	jmp    f0103bc0 <strtol+0x76>

	if (endptr)
f0103c07:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0103c0b:	74 0d                	je     f0103c1a <strtol+0xd0>
		*endptr = (char *) s;
f0103c0d:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103c10:	89 0e                	mov    %ecx,(%esi)
f0103c12:	eb 06                	jmp    f0103c1a <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0103c14:	85 db                	test   %ebx,%ebx
f0103c16:	74 98                	je     f0103bb0 <strtol+0x66>
f0103c18:	eb 9e                	jmp    f0103bb8 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f0103c1a:	89 c2                	mov    %eax,%edx
f0103c1c:	f7 da                	neg    %edx
f0103c1e:	85 ff                	test   %edi,%edi
f0103c20:	0f 45 c2             	cmovne %edx,%eax
}
f0103c23:	5b                   	pop    %ebx
f0103c24:	5e                   	pop    %esi
f0103c25:	5f                   	pop    %edi
f0103c26:	5d                   	pop    %ebp
f0103c27:	c3                   	ret    
f0103c28:	66 90                	xchg   %ax,%ax
f0103c2a:	66 90                	xchg   %ax,%ax
f0103c2c:	66 90                	xchg   %ax,%ax
f0103c2e:	66 90                	xchg   %ax,%ax

f0103c30 <__udivdi3>:
f0103c30:	55                   	push   %ebp
f0103c31:	57                   	push   %edi
f0103c32:	56                   	push   %esi
f0103c33:	53                   	push   %ebx
f0103c34:	83 ec 1c             	sub    $0x1c,%esp
f0103c37:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f0103c3b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f0103c3f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0103c43:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0103c47:	85 f6                	test   %esi,%esi
f0103c49:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0103c4d:	89 ca                	mov    %ecx,%edx
f0103c4f:	89 f8                	mov    %edi,%eax
f0103c51:	75 3d                	jne    f0103c90 <__udivdi3+0x60>
f0103c53:	39 cf                	cmp    %ecx,%edi
f0103c55:	0f 87 c5 00 00 00    	ja     f0103d20 <__udivdi3+0xf0>
f0103c5b:	85 ff                	test   %edi,%edi
f0103c5d:	89 fd                	mov    %edi,%ebp
f0103c5f:	75 0b                	jne    f0103c6c <__udivdi3+0x3c>
f0103c61:	b8 01 00 00 00       	mov    $0x1,%eax
f0103c66:	31 d2                	xor    %edx,%edx
f0103c68:	f7 f7                	div    %edi
f0103c6a:	89 c5                	mov    %eax,%ebp
f0103c6c:	89 c8                	mov    %ecx,%eax
f0103c6e:	31 d2                	xor    %edx,%edx
f0103c70:	f7 f5                	div    %ebp
f0103c72:	89 c1                	mov    %eax,%ecx
f0103c74:	89 d8                	mov    %ebx,%eax
f0103c76:	89 cf                	mov    %ecx,%edi
f0103c78:	f7 f5                	div    %ebp
f0103c7a:	89 c3                	mov    %eax,%ebx
f0103c7c:	89 d8                	mov    %ebx,%eax
f0103c7e:	89 fa                	mov    %edi,%edx
f0103c80:	83 c4 1c             	add    $0x1c,%esp
f0103c83:	5b                   	pop    %ebx
f0103c84:	5e                   	pop    %esi
f0103c85:	5f                   	pop    %edi
f0103c86:	5d                   	pop    %ebp
f0103c87:	c3                   	ret    
f0103c88:	90                   	nop
f0103c89:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103c90:	39 ce                	cmp    %ecx,%esi
f0103c92:	77 74                	ja     f0103d08 <__udivdi3+0xd8>
f0103c94:	0f bd fe             	bsr    %esi,%edi
f0103c97:	83 f7 1f             	xor    $0x1f,%edi
f0103c9a:	0f 84 98 00 00 00    	je     f0103d38 <__udivdi3+0x108>
f0103ca0:	bb 20 00 00 00       	mov    $0x20,%ebx
f0103ca5:	89 f9                	mov    %edi,%ecx
f0103ca7:	89 c5                	mov    %eax,%ebp
f0103ca9:	29 fb                	sub    %edi,%ebx
f0103cab:	d3 e6                	shl    %cl,%esi
f0103cad:	89 d9                	mov    %ebx,%ecx
f0103caf:	d3 ed                	shr    %cl,%ebp
f0103cb1:	89 f9                	mov    %edi,%ecx
f0103cb3:	d3 e0                	shl    %cl,%eax
f0103cb5:	09 ee                	or     %ebp,%esi
f0103cb7:	89 d9                	mov    %ebx,%ecx
f0103cb9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103cbd:	89 d5                	mov    %edx,%ebp
f0103cbf:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103cc3:	d3 ed                	shr    %cl,%ebp
f0103cc5:	89 f9                	mov    %edi,%ecx
f0103cc7:	d3 e2                	shl    %cl,%edx
f0103cc9:	89 d9                	mov    %ebx,%ecx
f0103ccb:	d3 e8                	shr    %cl,%eax
f0103ccd:	09 c2                	or     %eax,%edx
f0103ccf:	89 d0                	mov    %edx,%eax
f0103cd1:	89 ea                	mov    %ebp,%edx
f0103cd3:	f7 f6                	div    %esi
f0103cd5:	89 d5                	mov    %edx,%ebp
f0103cd7:	89 c3                	mov    %eax,%ebx
f0103cd9:	f7 64 24 0c          	mull   0xc(%esp)
f0103cdd:	39 d5                	cmp    %edx,%ebp
f0103cdf:	72 10                	jb     f0103cf1 <__udivdi3+0xc1>
f0103ce1:	8b 74 24 08          	mov    0x8(%esp),%esi
f0103ce5:	89 f9                	mov    %edi,%ecx
f0103ce7:	d3 e6                	shl    %cl,%esi
f0103ce9:	39 c6                	cmp    %eax,%esi
f0103ceb:	73 07                	jae    f0103cf4 <__udivdi3+0xc4>
f0103ced:	39 d5                	cmp    %edx,%ebp
f0103cef:	75 03                	jne    f0103cf4 <__udivdi3+0xc4>
f0103cf1:	83 eb 01             	sub    $0x1,%ebx
f0103cf4:	31 ff                	xor    %edi,%edi
f0103cf6:	89 d8                	mov    %ebx,%eax
f0103cf8:	89 fa                	mov    %edi,%edx
f0103cfa:	83 c4 1c             	add    $0x1c,%esp
f0103cfd:	5b                   	pop    %ebx
f0103cfe:	5e                   	pop    %esi
f0103cff:	5f                   	pop    %edi
f0103d00:	5d                   	pop    %ebp
f0103d01:	c3                   	ret    
f0103d02:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103d08:	31 ff                	xor    %edi,%edi
f0103d0a:	31 db                	xor    %ebx,%ebx
f0103d0c:	89 d8                	mov    %ebx,%eax
f0103d0e:	89 fa                	mov    %edi,%edx
f0103d10:	83 c4 1c             	add    $0x1c,%esp
f0103d13:	5b                   	pop    %ebx
f0103d14:	5e                   	pop    %esi
f0103d15:	5f                   	pop    %edi
f0103d16:	5d                   	pop    %ebp
f0103d17:	c3                   	ret    
f0103d18:	90                   	nop
f0103d19:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103d20:	89 d8                	mov    %ebx,%eax
f0103d22:	f7 f7                	div    %edi
f0103d24:	31 ff                	xor    %edi,%edi
f0103d26:	89 c3                	mov    %eax,%ebx
f0103d28:	89 d8                	mov    %ebx,%eax
f0103d2a:	89 fa                	mov    %edi,%edx
f0103d2c:	83 c4 1c             	add    $0x1c,%esp
f0103d2f:	5b                   	pop    %ebx
f0103d30:	5e                   	pop    %esi
f0103d31:	5f                   	pop    %edi
f0103d32:	5d                   	pop    %ebp
f0103d33:	c3                   	ret    
f0103d34:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103d38:	39 ce                	cmp    %ecx,%esi
f0103d3a:	72 0c                	jb     f0103d48 <__udivdi3+0x118>
f0103d3c:	31 db                	xor    %ebx,%ebx
f0103d3e:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0103d42:	0f 87 34 ff ff ff    	ja     f0103c7c <__udivdi3+0x4c>
f0103d48:	bb 01 00 00 00       	mov    $0x1,%ebx
f0103d4d:	e9 2a ff ff ff       	jmp    f0103c7c <__udivdi3+0x4c>
f0103d52:	66 90                	xchg   %ax,%ax
f0103d54:	66 90                	xchg   %ax,%ax
f0103d56:	66 90                	xchg   %ax,%ax
f0103d58:	66 90                	xchg   %ax,%ax
f0103d5a:	66 90                	xchg   %ax,%ax
f0103d5c:	66 90                	xchg   %ax,%ax
f0103d5e:	66 90                	xchg   %ax,%ax

f0103d60 <__umoddi3>:
f0103d60:	55                   	push   %ebp
f0103d61:	57                   	push   %edi
f0103d62:	56                   	push   %esi
f0103d63:	53                   	push   %ebx
f0103d64:	83 ec 1c             	sub    $0x1c,%esp
f0103d67:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f0103d6b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f0103d6f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0103d73:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0103d77:	85 d2                	test   %edx,%edx
f0103d79:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0103d7d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103d81:	89 f3                	mov    %esi,%ebx
f0103d83:	89 3c 24             	mov    %edi,(%esp)
f0103d86:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103d8a:	75 1c                	jne    f0103da8 <__umoddi3+0x48>
f0103d8c:	39 f7                	cmp    %esi,%edi
f0103d8e:	76 50                	jbe    f0103de0 <__umoddi3+0x80>
f0103d90:	89 c8                	mov    %ecx,%eax
f0103d92:	89 f2                	mov    %esi,%edx
f0103d94:	f7 f7                	div    %edi
f0103d96:	89 d0                	mov    %edx,%eax
f0103d98:	31 d2                	xor    %edx,%edx
f0103d9a:	83 c4 1c             	add    $0x1c,%esp
f0103d9d:	5b                   	pop    %ebx
f0103d9e:	5e                   	pop    %esi
f0103d9f:	5f                   	pop    %edi
f0103da0:	5d                   	pop    %ebp
f0103da1:	c3                   	ret    
f0103da2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103da8:	39 f2                	cmp    %esi,%edx
f0103daa:	89 d0                	mov    %edx,%eax
f0103dac:	77 52                	ja     f0103e00 <__umoddi3+0xa0>
f0103dae:	0f bd ea             	bsr    %edx,%ebp
f0103db1:	83 f5 1f             	xor    $0x1f,%ebp
f0103db4:	75 5a                	jne    f0103e10 <__umoddi3+0xb0>
f0103db6:	3b 54 24 04          	cmp    0x4(%esp),%edx
f0103dba:	0f 82 e0 00 00 00    	jb     f0103ea0 <__umoddi3+0x140>
f0103dc0:	39 0c 24             	cmp    %ecx,(%esp)
f0103dc3:	0f 86 d7 00 00 00    	jbe    f0103ea0 <__umoddi3+0x140>
f0103dc9:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103dcd:	8b 54 24 04          	mov    0x4(%esp),%edx
f0103dd1:	83 c4 1c             	add    $0x1c,%esp
f0103dd4:	5b                   	pop    %ebx
f0103dd5:	5e                   	pop    %esi
f0103dd6:	5f                   	pop    %edi
f0103dd7:	5d                   	pop    %ebp
f0103dd8:	c3                   	ret    
f0103dd9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103de0:	85 ff                	test   %edi,%edi
f0103de2:	89 fd                	mov    %edi,%ebp
f0103de4:	75 0b                	jne    f0103df1 <__umoddi3+0x91>
f0103de6:	b8 01 00 00 00       	mov    $0x1,%eax
f0103deb:	31 d2                	xor    %edx,%edx
f0103ded:	f7 f7                	div    %edi
f0103def:	89 c5                	mov    %eax,%ebp
f0103df1:	89 f0                	mov    %esi,%eax
f0103df3:	31 d2                	xor    %edx,%edx
f0103df5:	f7 f5                	div    %ebp
f0103df7:	89 c8                	mov    %ecx,%eax
f0103df9:	f7 f5                	div    %ebp
f0103dfb:	89 d0                	mov    %edx,%eax
f0103dfd:	eb 99                	jmp    f0103d98 <__umoddi3+0x38>
f0103dff:	90                   	nop
f0103e00:	89 c8                	mov    %ecx,%eax
f0103e02:	89 f2                	mov    %esi,%edx
f0103e04:	83 c4 1c             	add    $0x1c,%esp
f0103e07:	5b                   	pop    %ebx
f0103e08:	5e                   	pop    %esi
f0103e09:	5f                   	pop    %edi
f0103e0a:	5d                   	pop    %ebp
f0103e0b:	c3                   	ret    
f0103e0c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103e10:	8b 34 24             	mov    (%esp),%esi
f0103e13:	bf 20 00 00 00       	mov    $0x20,%edi
f0103e18:	89 e9                	mov    %ebp,%ecx
f0103e1a:	29 ef                	sub    %ebp,%edi
f0103e1c:	d3 e0                	shl    %cl,%eax
f0103e1e:	89 f9                	mov    %edi,%ecx
f0103e20:	89 f2                	mov    %esi,%edx
f0103e22:	d3 ea                	shr    %cl,%edx
f0103e24:	89 e9                	mov    %ebp,%ecx
f0103e26:	09 c2                	or     %eax,%edx
f0103e28:	89 d8                	mov    %ebx,%eax
f0103e2a:	89 14 24             	mov    %edx,(%esp)
f0103e2d:	89 f2                	mov    %esi,%edx
f0103e2f:	d3 e2                	shl    %cl,%edx
f0103e31:	89 f9                	mov    %edi,%ecx
f0103e33:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103e37:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0103e3b:	d3 e8                	shr    %cl,%eax
f0103e3d:	89 e9                	mov    %ebp,%ecx
f0103e3f:	89 c6                	mov    %eax,%esi
f0103e41:	d3 e3                	shl    %cl,%ebx
f0103e43:	89 f9                	mov    %edi,%ecx
f0103e45:	89 d0                	mov    %edx,%eax
f0103e47:	d3 e8                	shr    %cl,%eax
f0103e49:	89 e9                	mov    %ebp,%ecx
f0103e4b:	09 d8                	or     %ebx,%eax
f0103e4d:	89 d3                	mov    %edx,%ebx
f0103e4f:	89 f2                	mov    %esi,%edx
f0103e51:	f7 34 24             	divl   (%esp)
f0103e54:	89 d6                	mov    %edx,%esi
f0103e56:	d3 e3                	shl    %cl,%ebx
f0103e58:	f7 64 24 04          	mull   0x4(%esp)
f0103e5c:	39 d6                	cmp    %edx,%esi
f0103e5e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0103e62:	89 d1                	mov    %edx,%ecx
f0103e64:	89 c3                	mov    %eax,%ebx
f0103e66:	72 08                	jb     f0103e70 <__umoddi3+0x110>
f0103e68:	75 11                	jne    f0103e7b <__umoddi3+0x11b>
f0103e6a:	39 44 24 08          	cmp    %eax,0x8(%esp)
f0103e6e:	73 0b                	jae    f0103e7b <__umoddi3+0x11b>
f0103e70:	2b 44 24 04          	sub    0x4(%esp),%eax
f0103e74:	1b 14 24             	sbb    (%esp),%edx
f0103e77:	89 d1                	mov    %edx,%ecx
f0103e79:	89 c3                	mov    %eax,%ebx
f0103e7b:	8b 54 24 08          	mov    0x8(%esp),%edx
f0103e7f:	29 da                	sub    %ebx,%edx
f0103e81:	19 ce                	sbb    %ecx,%esi
f0103e83:	89 f9                	mov    %edi,%ecx
f0103e85:	89 f0                	mov    %esi,%eax
f0103e87:	d3 e0                	shl    %cl,%eax
f0103e89:	89 e9                	mov    %ebp,%ecx
f0103e8b:	d3 ea                	shr    %cl,%edx
f0103e8d:	89 e9                	mov    %ebp,%ecx
f0103e8f:	d3 ee                	shr    %cl,%esi
f0103e91:	09 d0                	or     %edx,%eax
f0103e93:	89 f2                	mov    %esi,%edx
f0103e95:	83 c4 1c             	add    $0x1c,%esp
f0103e98:	5b                   	pop    %ebx
f0103e99:	5e                   	pop    %esi
f0103e9a:	5f                   	pop    %edi
f0103e9b:	5d                   	pop    %ebp
f0103e9c:	c3                   	ret    
f0103e9d:	8d 76 00             	lea    0x0(%esi),%esi
f0103ea0:	29 f9                	sub    %edi,%ecx
f0103ea2:	19 d6                	sbb    %edx,%esi
f0103ea4:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103ea8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103eac:	e9 18 ff ff ff       	jmp    f0103dc9 <__umoddi3+0x69>
