
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
f0100015:	b8 00 b0 11 00       	mov    $0x11b000,%eax
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
f0100034:	bc 00 b0 11 f0       	mov    $0xf011b000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 5c 00 00 00       	call   f010009a <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	56                   	push   %esi
f0100044:	53                   	push   %ebx
f0100045:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100048:	83 3d 00 8f 22 f0 00 	cmpl   $0x0,0xf0228f00
f010004f:	75 3a                	jne    f010008b <_panic+0x4b>
		goto dead;
	panicstr = fmt;
f0100051:	89 35 00 8f 22 f0    	mov    %esi,0xf0228f00

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f0100057:	fa                   	cli    
f0100058:	fc                   	cld    

	va_start(ap, fmt);
f0100059:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic on CPU %d at %s:%d: ", cpunum(), file, line);
f010005c:	e8 85 48 00 00       	call   f01048e6 <cpunum>
f0100061:	ff 75 0c             	pushl  0xc(%ebp)
f0100064:	ff 75 08             	pushl  0x8(%ebp)
f0100067:	50                   	push   %eax
f0100068:	68 80 4f 10 f0       	push   $0xf0104f80
f010006d:	e8 cb 2a 00 00       	call   f0102b3d <cprintf>
	vcprintf(fmt, ap);
f0100072:	83 c4 08             	add    $0x8,%esp
f0100075:	53                   	push   %ebx
f0100076:	56                   	push   %esi
f0100077:	e8 9b 2a 00 00       	call   f0102b17 <vcprintf>
	cprintf("\n");
f010007c:	c7 04 24 f1 5d 10 f0 	movl   $0xf0105df1,(%esp)
f0100083:	e8 b5 2a 00 00       	call   f0102b3d <cprintf>
	va_end(ap);
f0100088:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f010008b:	83 ec 0c             	sub    $0xc,%esp
f010008e:	6a 00                	push   $0x0
f0100090:	e8 44 08 00 00       	call   f01008d9 <monitor>
f0100095:	83 c4 10             	add    $0x10,%esp
f0100098:	eb f1                	jmp    f010008b <_panic+0x4b>

f010009a <i386_init>:

static void boot_aps(void);

void
i386_init(void)
{
f010009a:	55                   	push   %ebp
f010009b:	89 e5                	mov    %esp,%ebp
f010009d:	53                   	push   %ebx
f010009e:	83 ec 08             	sub    $0x8,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f01000a1:	b8 08 a0 26 f0       	mov    $0xf026a008,%eax
f01000a6:	2d 78 75 22 f0       	sub    $0xf0227578,%eax
f01000ab:	50                   	push   %eax
f01000ac:	6a 00                	push   $0x0
f01000ae:	68 78 75 22 f0       	push   $0xf0227578
f01000b3:	e8 0e 42 00 00       	call   f01042c6 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000b8:	e8 6a 05 00 00       	call   f0100627 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000bd:	83 c4 08             	add    $0x8,%esp
f01000c0:	68 ac 1a 00 00       	push   $0x1aac
f01000c5:	68 ec 4f 10 f0       	push   $0xf0104fec
f01000ca:	e8 6e 2a 00 00       	call   f0102b3d <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f01000cf:	e8 73 0e 00 00       	call   f0100f47 <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f01000d4:	e8 e2 22 00 00       	call   f01023bb <env_init>
	trap_init();
f01000d9:	e8 d9 2a 00 00       	call   f0102bb7 <trap_init>

	// Lab 4 multiprocessor initialization functions
	mp_init();
f01000de:	e8 f9 44 00 00       	call   f01045dc <mp_init>
	lapic_init();
f01000e3:	e8 19 48 00 00       	call   f0104901 <lapic_init>

	// Lab 4 multitasking initialization functions
	pic_init();
f01000e8:	e8 77 29 00 00       	call   f0102a64 <pic_init>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01000ed:	83 c4 10             	add    $0x10,%esp
f01000f0:	83 3d 08 8f 22 f0 07 	cmpl   $0x7,0xf0228f08
f01000f7:	77 16                	ja     f010010f <i386_init+0x75>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01000f9:	68 00 70 00 00       	push   $0x7000
f01000fe:	68 a4 4f 10 f0       	push   $0xf0104fa4
f0100103:	6a 52                	push   $0x52
f0100105:	68 07 50 10 f0       	push   $0xf0105007
f010010a:	e8 31 ff ff ff       	call   f0100040 <_panic>
	void *code;
	struct CpuInfo *c;

	// Write entry code to unused memory at MPENTRY_PADDR
	code = KADDR(MPENTRY_PADDR);
	memmove(code, mpentry_start, mpentry_end - mpentry_start);
f010010f:	83 ec 04             	sub    $0x4,%esp
f0100112:	b8 42 45 10 f0       	mov    $0xf0104542,%eax
f0100117:	2d c8 44 10 f0       	sub    $0xf01044c8,%eax
f010011c:	50                   	push   %eax
f010011d:	68 c8 44 10 f0       	push   $0xf01044c8
f0100122:	68 00 70 00 f0       	push   $0xf0007000
f0100127:	e8 e7 41 00 00       	call   f0104313 <memmove>
f010012c:	83 c4 10             	add    $0x10,%esp

	// Boot each AP one at a time
	for (c = cpus; c < cpus + ncpu; c++) {
f010012f:	bb 20 90 22 f0       	mov    $0xf0229020,%ebx
f0100134:	eb 4d                	jmp    f0100183 <i386_init+0xe9>
		if (c == cpus + cpunum())  // We've started already.
f0100136:	e8 ab 47 00 00       	call   f01048e6 <cpunum>
f010013b:	6b c0 74             	imul   $0x74,%eax,%eax
f010013e:	05 20 90 22 f0       	add    $0xf0229020,%eax
f0100143:	39 c3                	cmp    %eax,%ebx
f0100145:	74 39                	je     f0100180 <i386_init+0xe6>
			continue;

		// Tell mpentry.S what stack to use 
		mpentry_kstack = percpu_kstacks[c - cpus] + KSTKSIZE;
f0100147:	89 d8                	mov    %ebx,%eax
f0100149:	2d 20 90 22 f0       	sub    $0xf0229020,%eax
f010014e:	c1 f8 02             	sar    $0x2,%eax
f0100151:	69 c0 35 c2 72 4f    	imul   $0x4f72c235,%eax,%eax
f0100157:	c1 e0 0f             	shl    $0xf,%eax
f010015a:	05 00 20 23 f0       	add    $0xf0232000,%eax
f010015f:	a3 04 8f 22 f0       	mov    %eax,0xf0228f04
		// Start the CPU at mpentry_start
		lapic_startap(c->cpu_id, PADDR(code));
f0100164:	83 ec 08             	sub    $0x8,%esp
f0100167:	68 00 70 00 00       	push   $0x7000
f010016c:	0f b6 03             	movzbl (%ebx),%eax
f010016f:	50                   	push   %eax
f0100170:	e8 da 48 00 00       	call   f0104a4f <lapic_startap>
f0100175:	83 c4 10             	add    $0x10,%esp
		// Wait for the CPU to finish some basic setup in mp_main()
		while(c->cpu_status != CPU_STARTED)
f0100178:	8b 43 04             	mov    0x4(%ebx),%eax
f010017b:	83 f8 01             	cmp    $0x1,%eax
f010017e:	75 f8                	jne    f0100178 <i386_init+0xde>
	// Write entry code to unused memory at MPENTRY_PADDR
	code = KADDR(MPENTRY_PADDR);
	memmove(code, mpentry_start, mpentry_end - mpentry_start);

	// Boot each AP one at a time
	for (c = cpus; c < cpus + ncpu; c++) {
f0100180:	83 c3 74             	add    $0x74,%ebx
f0100183:	6b 05 c4 93 22 f0 74 	imul   $0x74,0xf02293c4,%eax
f010018a:	05 20 90 22 f0       	add    $0xf0229020,%eax
f010018f:	39 c3                	cmp    %eax,%ebx
f0100191:	72 a3                	jb     f0100136 <i386_init+0x9c>
	// Starting non-boot CPUs
	boot_aps();

#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
f0100193:	83 ec 08             	sub    $0x8,%esp
f0100196:	6a 00                	push   $0x0
f0100198:	68 d4 d3 11 f0       	push   $0xf011d3d4
f010019d:	e8 eb 23 00 00       	call   f010258d <env_create>
	// Touch all you want.
	ENV_CREATE(user_primes, ENV_TYPE_USER);
#endif // TEST*

	// Schedule and run the first user environment!
	sched_yield();
f01001a2:	e8 5c 34 00 00       	call   f0103603 <sched_yield>

f01001a7 <mp_main>:
}

// Setup code for APs
void
mp_main(void)
{
f01001a7:	55                   	push   %ebp
f01001a8:	89 e5                	mov    %esp,%ebp
f01001aa:	83 ec 08             	sub    $0x8,%esp
	// We are in high EIP now, safe to switch to kern_pgdir 
	lcr3(PADDR(kern_pgdir));
f01001ad:	a1 0c 8f 22 f0       	mov    0xf0228f0c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01001b2:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01001b7:	77 12                	ja     f01001cb <mp_main+0x24>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01001b9:	50                   	push   %eax
f01001ba:	68 c8 4f 10 f0       	push   $0xf0104fc8
f01001bf:	6a 69                	push   $0x69
f01001c1:	68 07 50 10 f0       	push   $0xf0105007
f01001c6:	e8 75 fe ff ff       	call   f0100040 <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f01001cb:	05 00 00 00 10       	add    $0x10000000,%eax
f01001d0:	0f 22 d8             	mov    %eax,%cr3
	cprintf("SMP: CPU %d starting\n", cpunum());
f01001d3:	e8 0e 47 00 00       	call   f01048e6 <cpunum>
f01001d8:	83 ec 08             	sub    $0x8,%esp
f01001db:	50                   	push   %eax
f01001dc:	68 13 50 10 f0       	push   $0xf0105013
f01001e1:	e8 57 29 00 00       	call   f0102b3d <cprintf>

	lapic_init();
f01001e6:	e8 16 47 00 00       	call   f0104901 <lapic_init>
	env_init_percpu();
f01001eb:	e8 9b 21 00 00       	call   f010238b <env_init_percpu>
	trap_init_percpu();
f01001f0:	e8 5c 29 00 00       	call   f0102b51 <trap_init_percpu>
	xchg(&thiscpu->cpu_status, CPU_STARTED); // tell boot_aps() we're up
f01001f5:	e8 ec 46 00 00       	call   f01048e6 <cpunum>
f01001fa:	6b d0 74             	imul   $0x74,%eax,%edx
f01001fd:	81 c2 20 90 22 f0    	add    $0xf0229020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"
f0100203:	b8 01 00 00 00       	mov    $0x1,%eax
f0100208:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
f010020c:	83 c4 10             	add    $0x10,%esp
f010020f:	eb fe                	jmp    f010020f <mp_main+0x68>

f0100211 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100211:	55                   	push   %ebp
f0100212:	89 e5                	mov    %esp,%ebp
f0100214:	53                   	push   %ebx
f0100215:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100218:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f010021b:	ff 75 0c             	pushl  0xc(%ebp)
f010021e:	ff 75 08             	pushl  0x8(%ebp)
f0100221:	68 29 50 10 f0       	push   $0xf0105029
f0100226:	e8 12 29 00 00       	call   f0102b3d <cprintf>
	vcprintf(fmt, ap);
f010022b:	83 c4 08             	add    $0x8,%esp
f010022e:	53                   	push   %ebx
f010022f:	ff 75 10             	pushl  0x10(%ebp)
f0100232:	e8 e0 28 00 00       	call   f0102b17 <vcprintf>
	cprintf("\n");
f0100237:	c7 04 24 f1 5d 10 f0 	movl   $0xf0105df1,(%esp)
f010023e:	e8 fa 28 00 00       	call   f0102b3d <cprintf>
	va_end(ap);
}
f0100243:	83 c4 10             	add    $0x10,%esp
f0100246:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100249:	c9                   	leave  
f010024a:	c3                   	ret    

f010024b <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f010024b:	55                   	push   %ebp
f010024c:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010024e:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100253:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100254:	a8 01                	test   $0x1,%al
f0100256:	74 0b                	je     f0100263 <serial_proc_data+0x18>
f0100258:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010025d:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f010025e:	0f b6 c0             	movzbl %al,%eax
f0100261:	eb 05                	jmp    f0100268 <serial_proc_data+0x1d>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100263:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f0100268:	5d                   	pop    %ebp
f0100269:	c3                   	ret    

f010026a <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010026a:	55                   	push   %ebp
f010026b:	89 e5                	mov    %esp,%ebp
f010026d:	53                   	push   %ebx
f010026e:	83 ec 04             	sub    $0x4,%esp
f0100271:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100273:	eb 2b                	jmp    f01002a0 <cons_intr+0x36>
		if (c == 0)
f0100275:	85 c0                	test   %eax,%eax
f0100277:	74 27                	je     f01002a0 <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f0100279:	8b 0d 24 82 22 f0    	mov    0xf0228224,%ecx
f010027f:	8d 51 01             	lea    0x1(%ecx),%edx
f0100282:	89 15 24 82 22 f0    	mov    %edx,0xf0228224
f0100288:	88 81 20 80 22 f0    	mov    %al,-0xfdd7fe0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f010028e:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100294:	75 0a                	jne    f01002a0 <cons_intr+0x36>
			cons.wpos = 0;
f0100296:	c7 05 24 82 22 f0 00 	movl   $0x0,0xf0228224
f010029d:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01002a0:	ff d3                	call   *%ebx
f01002a2:	83 f8 ff             	cmp    $0xffffffff,%eax
f01002a5:	75 ce                	jne    f0100275 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01002a7:	83 c4 04             	add    $0x4,%esp
f01002aa:	5b                   	pop    %ebx
f01002ab:	5d                   	pop    %ebp
f01002ac:	c3                   	ret    

f01002ad <kbd_proc_data>:
f01002ad:	ba 64 00 00 00       	mov    $0x64,%edx
f01002b2:	ec                   	in     (%dx),%al
	int c;
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
f01002b3:	a8 01                	test   $0x1,%al
f01002b5:	0f 84 f8 00 00 00    	je     f01003b3 <kbd_proc_data+0x106>
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
f01002bb:	a8 20                	test   $0x20,%al
f01002bd:	0f 85 f6 00 00 00    	jne    f01003b9 <kbd_proc_data+0x10c>
f01002c3:	ba 60 00 00 00       	mov    $0x60,%edx
f01002c8:	ec                   	in     (%dx),%al
f01002c9:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01002cb:	3c e0                	cmp    $0xe0,%al
f01002cd:	75 0d                	jne    f01002dc <kbd_proc_data+0x2f>
		// E0 escape character
		shift |= E0ESC;
f01002cf:	83 0d 00 80 22 f0 40 	orl    $0x40,0xf0228000
		return 0;
f01002d6:	b8 00 00 00 00       	mov    $0x0,%eax
f01002db:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01002dc:	55                   	push   %ebp
f01002dd:	89 e5                	mov    %esp,%ebp
f01002df:	53                   	push   %ebx
f01002e0:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f01002e3:	84 c0                	test   %al,%al
f01002e5:	79 36                	jns    f010031d <kbd_proc_data+0x70>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01002e7:	8b 0d 00 80 22 f0    	mov    0xf0228000,%ecx
f01002ed:	89 cb                	mov    %ecx,%ebx
f01002ef:	83 e3 40             	and    $0x40,%ebx
f01002f2:	83 e0 7f             	and    $0x7f,%eax
f01002f5:	85 db                	test   %ebx,%ebx
f01002f7:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01002fa:	0f b6 d2             	movzbl %dl,%edx
f01002fd:	0f b6 82 a0 51 10 f0 	movzbl -0xfefae60(%edx),%eax
f0100304:	83 c8 40             	or     $0x40,%eax
f0100307:	0f b6 c0             	movzbl %al,%eax
f010030a:	f7 d0                	not    %eax
f010030c:	21 c8                	and    %ecx,%eax
f010030e:	a3 00 80 22 f0       	mov    %eax,0xf0228000
		return 0;
f0100313:	b8 00 00 00 00       	mov    $0x0,%eax
f0100318:	e9 a4 00 00 00       	jmp    f01003c1 <kbd_proc_data+0x114>
	} else if (shift & E0ESC) {
f010031d:	8b 0d 00 80 22 f0    	mov    0xf0228000,%ecx
f0100323:	f6 c1 40             	test   $0x40,%cl
f0100326:	74 0e                	je     f0100336 <kbd_proc_data+0x89>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100328:	83 c8 80             	or     $0xffffff80,%eax
f010032b:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f010032d:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100330:	89 0d 00 80 22 f0    	mov    %ecx,0xf0228000
	}

	shift |= shiftcode[data];
f0100336:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f0100339:	0f b6 82 a0 51 10 f0 	movzbl -0xfefae60(%edx),%eax
f0100340:	0b 05 00 80 22 f0    	or     0xf0228000,%eax
f0100346:	0f b6 8a a0 50 10 f0 	movzbl -0xfefaf60(%edx),%ecx
f010034d:	31 c8                	xor    %ecx,%eax
f010034f:	a3 00 80 22 f0       	mov    %eax,0xf0228000

	c = charcode[shift & (CTL | SHIFT)][data];
f0100354:	89 c1                	mov    %eax,%ecx
f0100356:	83 e1 03             	and    $0x3,%ecx
f0100359:	8b 0c 8d 80 50 10 f0 	mov    -0xfefaf80(,%ecx,4),%ecx
f0100360:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0100364:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100367:	a8 08                	test   $0x8,%al
f0100369:	74 1b                	je     f0100386 <kbd_proc_data+0xd9>
		if ('a' <= c && c <= 'z')
f010036b:	89 da                	mov    %ebx,%edx
f010036d:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100370:	83 f9 19             	cmp    $0x19,%ecx
f0100373:	77 05                	ja     f010037a <kbd_proc_data+0xcd>
			c += 'A' - 'a';
f0100375:	83 eb 20             	sub    $0x20,%ebx
f0100378:	eb 0c                	jmp    f0100386 <kbd_proc_data+0xd9>
		else if ('A' <= c && c <= 'Z')
f010037a:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f010037d:	8d 4b 20             	lea    0x20(%ebx),%ecx
f0100380:	83 fa 19             	cmp    $0x19,%edx
f0100383:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100386:	f7 d0                	not    %eax
f0100388:	a8 06                	test   $0x6,%al
f010038a:	75 33                	jne    f01003bf <kbd_proc_data+0x112>
f010038c:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f0100392:	75 2b                	jne    f01003bf <kbd_proc_data+0x112>
		cprintf("Rebooting!\n");
f0100394:	83 ec 0c             	sub    $0xc,%esp
f0100397:	68 43 50 10 f0       	push   $0xf0105043
f010039c:	e8 9c 27 00 00       	call   f0102b3d <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01003a1:	ba 92 00 00 00       	mov    $0x92,%edx
f01003a6:	b8 03 00 00 00       	mov    $0x3,%eax
f01003ab:	ee                   	out    %al,(%dx)
f01003ac:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01003af:	89 d8                	mov    %ebx,%eax
f01003b1:	eb 0e                	jmp    f01003c1 <kbd_proc_data+0x114>
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
f01003b3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01003b8:	c3                   	ret    
	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
		return -1;
f01003b9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01003be:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01003bf:	89 d8                	mov    %ebx,%eax
}
f01003c1:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01003c4:	c9                   	leave  
f01003c5:	c3                   	ret    

f01003c6 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01003c6:	55                   	push   %ebp
f01003c7:	89 e5                	mov    %esp,%ebp
f01003c9:	57                   	push   %edi
f01003ca:	56                   	push   %esi
f01003cb:	53                   	push   %ebx
f01003cc:	83 ec 1c             	sub    $0x1c,%esp
f01003cf:	89 c7                	mov    %eax,%edi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01003d1:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01003d6:	be fd 03 00 00       	mov    $0x3fd,%esi
f01003db:	b9 84 00 00 00       	mov    $0x84,%ecx
f01003e0:	eb 09                	jmp    f01003eb <cons_putc+0x25>
f01003e2:	89 ca                	mov    %ecx,%edx
f01003e4:	ec                   	in     (%dx),%al
f01003e5:	ec                   	in     (%dx),%al
f01003e6:	ec                   	in     (%dx),%al
f01003e7:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f01003e8:	83 c3 01             	add    $0x1,%ebx
f01003eb:	89 f2                	mov    %esi,%edx
f01003ed:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01003ee:	a8 20                	test   $0x20,%al
f01003f0:	75 08                	jne    f01003fa <cons_putc+0x34>
f01003f2:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01003f8:	7e e8                	jle    f01003e2 <cons_putc+0x1c>
f01003fa:	89 f8                	mov    %edi,%eax
f01003fc:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01003ff:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100404:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100405:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010040a:	be 79 03 00 00       	mov    $0x379,%esi
f010040f:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100414:	eb 09                	jmp    f010041f <cons_putc+0x59>
f0100416:	89 ca                	mov    %ecx,%edx
f0100418:	ec                   	in     (%dx),%al
f0100419:	ec                   	in     (%dx),%al
f010041a:	ec                   	in     (%dx),%al
f010041b:	ec                   	in     (%dx),%al
f010041c:	83 c3 01             	add    $0x1,%ebx
f010041f:	89 f2                	mov    %esi,%edx
f0100421:	ec                   	in     (%dx),%al
f0100422:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100428:	7f 04                	jg     f010042e <cons_putc+0x68>
f010042a:	84 c0                	test   %al,%al
f010042c:	79 e8                	jns    f0100416 <cons_putc+0x50>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010042e:	ba 78 03 00 00       	mov    $0x378,%edx
f0100433:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f0100437:	ee                   	out    %al,(%dx)
f0100438:	ba 7a 03 00 00       	mov    $0x37a,%edx
f010043d:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100442:	ee                   	out    %al,(%dx)
f0100443:	b8 08 00 00 00       	mov    $0x8,%eax
f0100448:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100449:	89 fa                	mov    %edi,%edx
f010044b:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100451:	89 f8                	mov    %edi,%eax
f0100453:	80 cc 07             	or     $0x7,%ah
f0100456:	85 d2                	test   %edx,%edx
f0100458:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f010045b:	89 f8                	mov    %edi,%eax
f010045d:	0f b6 c0             	movzbl %al,%eax
f0100460:	83 f8 09             	cmp    $0x9,%eax
f0100463:	74 74                	je     f01004d9 <cons_putc+0x113>
f0100465:	83 f8 09             	cmp    $0x9,%eax
f0100468:	7f 0a                	jg     f0100474 <cons_putc+0xae>
f010046a:	83 f8 08             	cmp    $0x8,%eax
f010046d:	74 14                	je     f0100483 <cons_putc+0xbd>
f010046f:	e9 99 00 00 00       	jmp    f010050d <cons_putc+0x147>
f0100474:	83 f8 0a             	cmp    $0xa,%eax
f0100477:	74 3a                	je     f01004b3 <cons_putc+0xed>
f0100479:	83 f8 0d             	cmp    $0xd,%eax
f010047c:	74 3d                	je     f01004bb <cons_putc+0xf5>
f010047e:	e9 8a 00 00 00       	jmp    f010050d <cons_putc+0x147>
	case '\b':
		if (crt_pos > 0) {
f0100483:	0f b7 05 28 82 22 f0 	movzwl 0xf0228228,%eax
f010048a:	66 85 c0             	test   %ax,%ax
f010048d:	0f 84 e6 00 00 00    	je     f0100579 <cons_putc+0x1b3>
			crt_pos--;
f0100493:	83 e8 01             	sub    $0x1,%eax
f0100496:	66 a3 28 82 22 f0    	mov    %ax,0xf0228228
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f010049c:	0f b7 c0             	movzwl %ax,%eax
f010049f:	66 81 e7 00 ff       	and    $0xff00,%di
f01004a4:	83 cf 20             	or     $0x20,%edi
f01004a7:	8b 15 2c 82 22 f0    	mov    0xf022822c,%edx
f01004ad:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01004b1:	eb 78                	jmp    f010052b <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01004b3:	66 83 05 28 82 22 f0 	addw   $0x50,0xf0228228
f01004ba:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01004bb:	0f b7 05 28 82 22 f0 	movzwl 0xf0228228,%eax
f01004c2:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01004c8:	c1 e8 16             	shr    $0x16,%eax
f01004cb:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01004ce:	c1 e0 04             	shl    $0x4,%eax
f01004d1:	66 a3 28 82 22 f0    	mov    %ax,0xf0228228
f01004d7:	eb 52                	jmp    f010052b <cons_putc+0x165>
		break;
	case '\t':
		cons_putc(' ');
f01004d9:	b8 20 00 00 00       	mov    $0x20,%eax
f01004de:	e8 e3 fe ff ff       	call   f01003c6 <cons_putc>
		cons_putc(' ');
f01004e3:	b8 20 00 00 00       	mov    $0x20,%eax
f01004e8:	e8 d9 fe ff ff       	call   f01003c6 <cons_putc>
		cons_putc(' ');
f01004ed:	b8 20 00 00 00       	mov    $0x20,%eax
f01004f2:	e8 cf fe ff ff       	call   f01003c6 <cons_putc>
		cons_putc(' ');
f01004f7:	b8 20 00 00 00       	mov    $0x20,%eax
f01004fc:	e8 c5 fe ff ff       	call   f01003c6 <cons_putc>
		cons_putc(' ');
f0100501:	b8 20 00 00 00       	mov    $0x20,%eax
f0100506:	e8 bb fe ff ff       	call   f01003c6 <cons_putc>
f010050b:	eb 1e                	jmp    f010052b <cons_putc+0x165>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f010050d:	0f b7 05 28 82 22 f0 	movzwl 0xf0228228,%eax
f0100514:	8d 50 01             	lea    0x1(%eax),%edx
f0100517:	66 89 15 28 82 22 f0 	mov    %dx,0xf0228228
f010051e:	0f b7 c0             	movzwl %ax,%eax
f0100521:	8b 15 2c 82 22 f0    	mov    0xf022822c,%edx
f0100527:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f010052b:	66 81 3d 28 82 22 f0 	cmpw   $0x7cf,0xf0228228
f0100532:	cf 07 
f0100534:	76 43                	jbe    f0100579 <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100536:	a1 2c 82 22 f0       	mov    0xf022822c,%eax
f010053b:	83 ec 04             	sub    $0x4,%esp
f010053e:	68 00 0f 00 00       	push   $0xf00
f0100543:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100549:	52                   	push   %edx
f010054a:	50                   	push   %eax
f010054b:	e8 c3 3d 00 00       	call   f0104313 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100550:	8b 15 2c 82 22 f0    	mov    0xf022822c,%edx
f0100556:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f010055c:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f0100562:	83 c4 10             	add    $0x10,%esp
f0100565:	66 c7 00 20 07       	movw   $0x720,(%eax)
f010056a:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010056d:	39 d0                	cmp    %edx,%eax
f010056f:	75 f4                	jne    f0100565 <cons_putc+0x19f>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100571:	66 83 2d 28 82 22 f0 	subw   $0x50,0xf0228228
f0100578:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100579:	8b 0d 30 82 22 f0    	mov    0xf0228230,%ecx
f010057f:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100584:	89 ca                	mov    %ecx,%edx
f0100586:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100587:	0f b7 1d 28 82 22 f0 	movzwl 0xf0228228,%ebx
f010058e:	8d 71 01             	lea    0x1(%ecx),%esi
f0100591:	89 d8                	mov    %ebx,%eax
f0100593:	66 c1 e8 08          	shr    $0x8,%ax
f0100597:	89 f2                	mov    %esi,%edx
f0100599:	ee                   	out    %al,(%dx)
f010059a:	b8 0f 00 00 00       	mov    $0xf,%eax
f010059f:	89 ca                	mov    %ecx,%edx
f01005a1:	ee                   	out    %al,(%dx)
f01005a2:	89 d8                	mov    %ebx,%eax
f01005a4:	89 f2                	mov    %esi,%edx
f01005a6:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01005a7:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01005aa:	5b                   	pop    %ebx
f01005ab:	5e                   	pop    %esi
f01005ac:	5f                   	pop    %edi
f01005ad:	5d                   	pop    %ebp
f01005ae:	c3                   	ret    

f01005af <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01005af:	80 3d 34 82 22 f0 00 	cmpb   $0x0,0xf0228234
f01005b6:	74 11                	je     f01005c9 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01005b8:	55                   	push   %ebp
f01005b9:	89 e5                	mov    %esp,%ebp
f01005bb:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f01005be:	b8 4b 02 10 f0       	mov    $0xf010024b,%eax
f01005c3:	e8 a2 fc ff ff       	call   f010026a <cons_intr>
}
f01005c8:	c9                   	leave  
f01005c9:	f3 c3                	repz ret 

f01005cb <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01005cb:	55                   	push   %ebp
f01005cc:	89 e5                	mov    %esp,%ebp
f01005ce:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01005d1:	b8 ad 02 10 f0       	mov    $0xf01002ad,%eax
f01005d6:	e8 8f fc ff ff       	call   f010026a <cons_intr>
}
f01005db:	c9                   	leave  
f01005dc:	c3                   	ret    

f01005dd <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01005dd:	55                   	push   %ebp
f01005de:	89 e5                	mov    %esp,%ebp
f01005e0:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01005e3:	e8 c7 ff ff ff       	call   f01005af <serial_intr>
	kbd_intr();
f01005e8:	e8 de ff ff ff       	call   f01005cb <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01005ed:	a1 20 82 22 f0       	mov    0xf0228220,%eax
f01005f2:	3b 05 24 82 22 f0    	cmp    0xf0228224,%eax
f01005f8:	74 26                	je     f0100620 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01005fa:	8d 50 01             	lea    0x1(%eax),%edx
f01005fd:	89 15 20 82 22 f0    	mov    %edx,0xf0228220
f0100603:	0f b6 88 20 80 22 f0 	movzbl -0xfdd7fe0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f010060a:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f010060c:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100612:	75 11                	jne    f0100625 <cons_getc+0x48>
			cons.rpos = 0;
f0100614:	c7 05 20 82 22 f0 00 	movl   $0x0,0xf0228220
f010061b:	00 00 00 
f010061e:	eb 05                	jmp    f0100625 <cons_getc+0x48>
		return c;
	}
	return 0;
f0100620:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100625:	c9                   	leave  
f0100626:	c3                   	ret    

f0100627 <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f0100627:	55                   	push   %ebp
f0100628:	89 e5                	mov    %esp,%ebp
f010062a:	57                   	push   %edi
f010062b:	56                   	push   %esi
f010062c:	53                   	push   %ebx
f010062d:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100630:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f0100637:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f010063e:	5a a5 
	if (*cp != 0xA55A) {
f0100640:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f0100647:	66 3d 5a a5          	cmp    $0xa55a,%ax
f010064b:	74 11                	je     f010065e <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f010064d:	c7 05 30 82 22 f0 b4 	movl   $0x3b4,0xf0228230
f0100654:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100657:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f010065c:	eb 16                	jmp    f0100674 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f010065e:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100665:	c7 05 30 82 22 f0 d4 	movl   $0x3d4,0xf0228230
f010066c:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f010066f:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f0100674:	8b 3d 30 82 22 f0    	mov    0xf0228230,%edi
f010067a:	b8 0e 00 00 00       	mov    $0xe,%eax
f010067f:	89 fa                	mov    %edi,%edx
f0100681:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100682:	8d 5f 01             	lea    0x1(%edi),%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100685:	89 da                	mov    %ebx,%edx
f0100687:	ec                   	in     (%dx),%al
f0100688:	0f b6 c8             	movzbl %al,%ecx
f010068b:	c1 e1 08             	shl    $0x8,%ecx
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010068e:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100693:	89 fa                	mov    %edi,%edx
f0100695:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100696:	89 da                	mov    %ebx,%edx
f0100698:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f0100699:	89 35 2c 82 22 f0    	mov    %esi,0xf022822c
	crt_pos = pos;
f010069f:	0f b6 c0             	movzbl %al,%eax
f01006a2:	09 c8                	or     %ecx,%eax
f01006a4:	66 a3 28 82 22 f0    	mov    %ax,0xf0228228

static void
kbd_init(void)
{
	// Drain the kbd buffer so that QEMU generates interrupts.
	kbd_intr();
f01006aa:	e8 1c ff ff ff       	call   f01005cb <kbd_intr>
	irq_setmask_8259A(irq_mask_8259A & ~(1<<IRQ_KBD));
f01006af:	83 ec 0c             	sub    $0xc,%esp
f01006b2:	0f b7 05 88 d3 11 f0 	movzwl 0xf011d388,%eax
f01006b9:	25 fd ff 00 00       	and    $0xfffd,%eax
f01006be:	50                   	push   %eax
f01006bf:	e8 28 23 00 00       	call   f01029ec <irq_setmask_8259A>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01006c4:	be fa 03 00 00       	mov    $0x3fa,%esi
f01006c9:	b8 00 00 00 00       	mov    $0x0,%eax
f01006ce:	89 f2                	mov    %esi,%edx
f01006d0:	ee                   	out    %al,(%dx)
f01006d1:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01006d6:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01006db:	ee                   	out    %al,(%dx)
f01006dc:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f01006e1:	b8 0c 00 00 00       	mov    $0xc,%eax
f01006e6:	89 da                	mov    %ebx,%edx
f01006e8:	ee                   	out    %al,(%dx)
f01006e9:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01006ee:	b8 00 00 00 00       	mov    $0x0,%eax
f01006f3:	ee                   	out    %al,(%dx)
f01006f4:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01006f9:	b8 03 00 00 00       	mov    $0x3,%eax
f01006fe:	ee                   	out    %al,(%dx)
f01006ff:	ba fc 03 00 00       	mov    $0x3fc,%edx
f0100704:	b8 00 00 00 00       	mov    $0x0,%eax
f0100709:	ee                   	out    %al,(%dx)
f010070a:	ba f9 03 00 00       	mov    $0x3f9,%edx
f010070f:	b8 01 00 00 00       	mov    $0x1,%eax
f0100714:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100715:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010071a:	ec                   	in     (%dx),%al
f010071b:	89 c1                	mov    %eax,%ecx
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f010071d:	83 c4 10             	add    $0x10,%esp
f0100720:	3c ff                	cmp    $0xff,%al
f0100722:	0f 95 05 34 82 22 f0 	setne  0xf0228234
f0100729:	89 f2                	mov    %esi,%edx
f010072b:	ec                   	in     (%dx),%al
f010072c:	89 da                	mov    %ebx,%edx
f010072e:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f010072f:	80 f9 ff             	cmp    $0xff,%cl
f0100732:	75 10                	jne    f0100744 <cons_init+0x11d>
		cprintf("Serial port does not exist!\n");
f0100734:	83 ec 0c             	sub    $0xc,%esp
f0100737:	68 4f 50 10 f0       	push   $0xf010504f
f010073c:	e8 fc 23 00 00       	call   f0102b3d <cprintf>
f0100741:	83 c4 10             	add    $0x10,%esp
}
f0100744:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100747:	5b                   	pop    %ebx
f0100748:	5e                   	pop    %esi
f0100749:	5f                   	pop    %edi
f010074a:	5d                   	pop    %ebp
f010074b:	c3                   	ret    

f010074c <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f010074c:	55                   	push   %ebp
f010074d:	89 e5                	mov    %esp,%ebp
f010074f:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100752:	8b 45 08             	mov    0x8(%ebp),%eax
f0100755:	e8 6c fc ff ff       	call   f01003c6 <cons_putc>
}
f010075a:	c9                   	leave  
f010075b:	c3                   	ret    

f010075c <getchar>:

int
getchar(void)
{
f010075c:	55                   	push   %ebp
f010075d:	89 e5                	mov    %esp,%ebp
f010075f:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100762:	e8 76 fe ff ff       	call   f01005dd <cons_getc>
f0100767:	85 c0                	test   %eax,%eax
f0100769:	74 f7                	je     f0100762 <getchar+0x6>
		/* do nothing */;
	return c;
}
f010076b:	c9                   	leave  
f010076c:	c3                   	ret    

f010076d <iscons>:

int
iscons(int fdnum)
{
f010076d:	55                   	push   %ebp
f010076e:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100770:	b8 01 00 00 00       	mov    $0x1,%eax
f0100775:	5d                   	pop    %ebp
f0100776:	c3                   	ret    

f0100777 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100777:	55                   	push   %ebp
f0100778:	89 e5                	mov    %esp,%ebp
f010077a:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f010077d:	68 a0 52 10 f0       	push   $0xf01052a0
f0100782:	68 be 52 10 f0       	push   $0xf01052be
f0100787:	68 c3 52 10 f0       	push   $0xf01052c3
f010078c:	e8 ac 23 00 00       	call   f0102b3d <cprintf>
f0100791:	83 c4 0c             	add    $0xc,%esp
f0100794:	68 4c 53 10 f0       	push   $0xf010534c
f0100799:	68 cc 52 10 f0       	push   $0xf01052cc
f010079e:	68 c3 52 10 f0       	push   $0xf01052c3
f01007a3:	e8 95 23 00 00       	call   f0102b3d <cprintf>
	return 0;
}
f01007a8:	b8 00 00 00 00       	mov    $0x0,%eax
f01007ad:	c9                   	leave  
f01007ae:	c3                   	ret    

f01007af <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01007af:	55                   	push   %ebp
f01007b0:	89 e5                	mov    %esp,%ebp
f01007b2:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01007b5:	68 d5 52 10 f0       	push   $0xf01052d5
f01007ba:	e8 7e 23 00 00       	call   f0102b3d <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01007bf:	83 c4 08             	add    $0x8,%esp
f01007c2:	68 0c 00 10 00       	push   $0x10000c
f01007c7:	68 74 53 10 f0       	push   $0xf0105374
f01007cc:	e8 6c 23 00 00       	call   f0102b3d <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01007d1:	83 c4 0c             	add    $0xc,%esp
f01007d4:	68 0c 00 10 00       	push   $0x10000c
f01007d9:	68 0c 00 10 f0       	push   $0xf010000c
f01007de:	68 9c 53 10 f0       	push   $0xf010539c
f01007e3:	e8 55 23 00 00       	call   f0102b3d <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01007e8:	83 c4 0c             	add    $0xc,%esp
f01007eb:	68 61 4f 10 00       	push   $0x104f61
f01007f0:	68 61 4f 10 f0       	push   $0xf0104f61
f01007f5:	68 c0 53 10 f0       	push   $0xf01053c0
f01007fa:	e8 3e 23 00 00       	call   f0102b3d <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01007ff:	83 c4 0c             	add    $0xc,%esp
f0100802:	68 78 75 22 00       	push   $0x227578
f0100807:	68 78 75 22 f0       	push   $0xf0227578
f010080c:	68 e4 53 10 f0       	push   $0xf01053e4
f0100811:	e8 27 23 00 00       	call   f0102b3d <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100816:	83 c4 0c             	add    $0xc,%esp
f0100819:	68 08 a0 26 00       	push   $0x26a008
f010081e:	68 08 a0 26 f0       	push   $0xf026a008
f0100823:	68 08 54 10 f0       	push   $0xf0105408
f0100828:	e8 10 23 00 00       	call   f0102b3d <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f010082d:	b8 07 a4 26 f0       	mov    $0xf026a407,%eax
f0100832:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100837:	83 c4 08             	add    $0x8,%esp
f010083a:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f010083f:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100845:	85 c0                	test   %eax,%eax
f0100847:	0f 48 c2             	cmovs  %edx,%eax
f010084a:	c1 f8 0a             	sar    $0xa,%eax
f010084d:	50                   	push   %eax
f010084e:	68 2c 54 10 f0       	push   $0xf010542c
f0100853:	e8 e5 22 00 00       	call   f0102b3d <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100858:	b8 00 00 00 00       	mov    $0x0,%eax
f010085d:	c9                   	leave  
f010085e:	c3                   	ret    

f010085f <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f010085f:	55                   	push   %ebp
f0100860:	89 e5                	mov    %esp,%ebp
f0100862:	56                   	push   %esi
f0100863:	53                   	push   %ebx
f0100864:	83 ec 2c             	sub    $0x2c,%esp

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f0100867:	89 eb                	mov    %ebp,%ebx
	uintptr_t ebp = read_ebp();
	struct Eipdebuginfo info;
	cprintf("Stack backtrace:\n");
f0100869:	68 ee 52 10 f0       	push   $0xf01052ee
f010086e:	e8 ca 22 00 00       	call   f0102b3d <cprintf>
	while(ebp != 0){
f0100873:	83 c4 10             	add    $0x10,%esp
		cprintf("  ebp %08x  eip %08x  args %08x %08x %08x %08x %08x\n", ebp , 
				*((uintptr_t *)ebp + 1), *((uintptr_t *)ebp + 2), *((uintptr_t *)ebp + 3), 
			    *((uintptr_t *)ebp + 4), *((uintptr_t *)ebp + 5), *((uintptr_t *)ebp + 6));
		debuginfo_eip(*((uintptr_t *)ebp + 1), &info);
f0100876:	8d 75 e0             	lea    -0x20(%ebp),%esi
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	uintptr_t ebp = read_ebp();
	struct Eipdebuginfo info;
	cprintf("Stack backtrace:\n");
	while(ebp != 0){
f0100879:	eb 4e                	jmp    f01008c9 <mon_backtrace+0x6a>
		cprintf("  ebp %08x  eip %08x  args %08x %08x %08x %08x %08x\n", ebp , 
f010087b:	ff 73 18             	pushl  0x18(%ebx)
f010087e:	ff 73 14             	pushl  0x14(%ebx)
f0100881:	ff 73 10             	pushl  0x10(%ebx)
f0100884:	ff 73 0c             	pushl  0xc(%ebx)
f0100887:	ff 73 08             	pushl  0x8(%ebx)
f010088a:	ff 73 04             	pushl  0x4(%ebx)
f010088d:	53                   	push   %ebx
f010088e:	68 58 54 10 f0       	push   $0xf0105458
f0100893:	e8 a5 22 00 00       	call   f0102b3d <cprintf>
				*((uintptr_t *)ebp + 1), *((uintptr_t *)ebp + 2), *((uintptr_t *)ebp + 3), 
			    *((uintptr_t *)ebp + 4), *((uintptr_t *)ebp + 5), *((uintptr_t *)ebp + 6));
		debuginfo_eip(*((uintptr_t *)ebp + 1), &info);
f0100898:	83 c4 18             	add    $0x18,%esp
f010089b:	56                   	push   %esi
f010089c:	ff 73 04             	pushl  0x4(%ebx)
f010089f:	e8 72 2f 00 00       	call   f0103816 <debuginfo_eip>
		cprintf("%s:%d: %.*s+%d\n", info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, 
f01008a4:	83 c4 08             	add    $0x8,%esp
f01008a7:	8b 43 04             	mov    0x4(%ebx),%eax
f01008aa:	2b 45 f0             	sub    -0x10(%ebp),%eax
f01008ad:	50                   	push   %eax
f01008ae:	ff 75 e8             	pushl  -0x18(%ebp)
f01008b1:	ff 75 ec             	pushl  -0x14(%ebp)
f01008b4:	ff 75 e4             	pushl  -0x1c(%ebp)
f01008b7:	ff 75 e0             	pushl  -0x20(%ebp)
f01008ba:	68 00 53 10 f0       	push   $0xf0105300
f01008bf:	e8 79 22 00 00       	call   f0102b3d <cprintf>
				*((uintptr_t *)ebp + 1) - info.eip_fn_addr);
		ebp = *(uintptr_t *)ebp;
f01008c4:	8b 1b                	mov    (%ebx),%ebx
f01008c6:	83 c4 20             	add    $0x20,%esp
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	uintptr_t ebp = read_ebp();
	struct Eipdebuginfo info;
	cprintf("Stack backtrace:\n");
	while(ebp != 0){
f01008c9:	85 db                	test   %ebx,%ebx
f01008cb:	75 ae                	jne    f010087b <mon_backtrace+0x1c>
		cprintf("%s:%d: %.*s+%d\n", info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, 
				*((uintptr_t *)ebp + 1) - info.eip_fn_addr);
		ebp = *(uintptr_t *)ebp;
	}
	return 0;
}
f01008cd:	b8 00 00 00 00       	mov    $0x0,%eax
f01008d2:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01008d5:	5b                   	pop    %ebx
f01008d6:	5e                   	pop    %esi
f01008d7:	5d                   	pop    %ebp
f01008d8:	c3                   	ret    

f01008d9 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01008d9:	55                   	push   %ebp
f01008da:	89 e5                	mov    %esp,%ebp
f01008dc:	57                   	push   %edi
f01008dd:	56                   	push   %esi
f01008de:	53                   	push   %ebx
f01008df:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01008e2:	68 90 54 10 f0       	push   $0xf0105490
f01008e7:	e8 51 22 00 00       	call   f0102b3d <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01008ec:	c7 04 24 b4 54 10 f0 	movl   $0xf01054b4,(%esp)
f01008f3:	e8 45 22 00 00       	call   f0102b3d <cprintf>

	if (tf != NULL)
f01008f8:	83 c4 10             	add    $0x10,%esp
f01008fb:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f01008ff:	74 0e                	je     f010090f <monitor+0x36>
		print_trapframe(tf);
f0100901:	83 ec 0c             	sub    $0xc,%esp
f0100904:	ff 75 08             	pushl  0x8(%ebp)
f0100907:	e8 76 27 00 00       	call   f0103082 <print_trapframe>
f010090c:	83 c4 10             	add    $0x10,%esp

	while (1) {
		buf = readline("K> ");
f010090f:	83 ec 0c             	sub    $0xc,%esp
f0100912:	68 10 53 10 f0       	push   $0xf0105310
f0100917:	e8 53 37 00 00       	call   f010406f <readline>
f010091c:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f010091e:	83 c4 10             	add    $0x10,%esp
f0100921:	85 c0                	test   %eax,%eax
f0100923:	74 ea                	je     f010090f <monitor+0x36>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100925:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f010092c:	be 00 00 00 00       	mov    $0x0,%esi
f0100931:	eb 0a                	jmp    f010093d <monitor+0x64>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100933:	c6 03 00             	movb   $0x0,(%ebx)
f0100936:	89 f7                	mov    %esi,%edi
f0100938:	8d 5b 01             	lea    0x1(%ebx),%ebx
f010093b:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f010093d:	0f b6 03             	movzbl (%ebx),%eax
f0100940:	84 c0                	test   %al,%al
f0100942:	74 63                	je     f01009a7 <monitor+0xce>
f0100944:	83 ec 08             	sub    $0x8,%esp
f0100947:	0f be c0             	movsbl %al,%eax
f010094a:	50                   	push   %eax
f010094b:	68 14 53 10 f0       	push   $0xf0105314
f0100950:	e8 34 39 00 00       	call   f0104289 <strchr>
f0100955:	83 c4 10             	add    $0x10,%esp
f0100958:	85 c0                	test   %eax,%eax
f010095a:	75 d7                	jne    f0100933 <monitor+0x5a>
			*buf++ = 0;
		if (*buf == 0)
f010095c:	80 3b 00             	cmpb   $0x0,(%ebx)
f010095f:	74 46                	je     f01009a7 <monitor+0xce>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100961:	83 fe 0f             	cmp    $0xf,%esi
f0100964:	75 14                	jne    f010097a <monitor+0xa1>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100966:	83 ec 08             	sub    $0x8,%esp
f0100969:	6a 10                	push   $0x10
f010096b:	68 19 53 10 f0       	push   $0xf0105319
f0100970:	e8 c8 21 00 00       	call   f0102b3d <cprintf>
f0100975:	83 c4 10             	add    $0x10,%esp
f0100978:	eb 95                	jmp    f010090f <monitor+0x36>
			return 0;
		}
		argv[argc++] = buf;
f010097a:	8d 7e 01             	lea    0x1(%esi),%edi
f010097d:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100981:	eb 03                	jmp    f0100986 <monitor+0xad>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f0100983:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100986:	0f b6 03             	movzbl (%ebx),%eax
f0100989:	84 c0                	test   %al,%al
f010098b:	74 ae                	je     f010093b <monitor+0x62>
f010098d:	83 ec 08             	sub    $0x8,%esp
f0100990:	0f be c0             	movsbl %al,%eax
f0100993:	50                   	push   %eax
f0100994:	68 14 53 10 f0       	push   $0xf0105314
f0100999:	e8 eb 38 00 00       	call   f0104289 <strchr>
f010099e:	83 c4 10             	add    $0x10,%esp
f01009a1:	85 c0                	test   %eax,%eax
f01009a3:	74 de                	je     f0100983 <monitor+0xaa>
f01009a5:	eb 94                	jmp    f010093b <monitor+0x62>
			buf++;
	}
	argv[argc] = 0;
f01009a7:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01009ae:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01009af:	85 f6                	test   %esi,%esi
f01009b1:	0f 84 58 ff ff ff    	je     f010090f <monitor+0x36>
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01009b7:	83 ec 08             	sub    $0x8,%esp
f01009ba:	68 be 52 10 f0       	push   $0xf01052be
f01009bf:	ff 75 a8             	pushl  -0x58(%ebp)
f01009c2:	e8 64 38 00 00       	call   f010422b <strcmp>
f01009c7:	83 c4 10             	add    $0x10,%esp
f01009ca:	85 c0                	test   %eax,%eax
f01009cc:	74 1e                	je     f01009ec <monitor+0x113>
f01009ce:	83 ec 08             	sub    $0x8,%esp
f01009d1:	68 cc 52 10 f0       	push   $0xf01052cc
f01009d6:	ff 75 a8             	pushl  -0x58(%ebp)
f01009d9:	e8 4d 38 00 00       	call   f010422b <strcmp>
f01009de:	83 c4 10             	add    $0x10,%esp
f01009e1:	85 c0                	test   %eax,%eax
f01009e3:	75 2f                	jne    f0100a14 <monitor+0x13b>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f01009e5:	b8 01 00 00 00       	mov    $0x1,%eax
f01009ea:	eb 05                	jmp    f01009f1 <monitor+0x118>
		if (strcmp(argv[0], commands[i].name) == 0)
f01009ec:	b8 00 00 00 00       	mov    $0x0,%eax
			return commands[i].func(argc, argv, tf);
f01009f1:	83 ec 04             	sub    $0x4,%esp
f01009f4:	8d 14 00             	lea    (%eax,%eax,1),%edx
f01009f7:	01 d0                	add    %edx,%eax
f01009f9:	ff 75 08             	pushl  0x8(%ebp)
f01009fc:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f01009ff:	51                   	push   %ecx
f0100a00:	56                   	push   %esi
f0100a01:	ff 14 85 e4 54 10 f0 	call   *-0xfefab1c(,%eax,4)
		print_trapframe(tf);

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100a08:	83 c4 10             	add    $0x10,%esp
f0100a0b:	85 c0                	test   %eax,%eax
f0100a0d:	78 1d                	js     f0100a2c <monitor+0x153>
f0100a0f:	e9 fb fe ff ff       	jmp    f010090f <monitor+0x36>
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100a14:	83 ec 08             	sub    $0x8,%esp
f0100a17:	ff 75 a8             	pushl  -0x58(%ebp)
f0100a1a:	68 36 53 10 f0       	push   $0xf0105336
f0100a1f:	e8 19 21 00 00       	call   f0102b3d <cprintf>
f0100a24:	83 c4 10             	add    $0x10,%esp
f0100a27:	e9 e3 fe ff ff       	jmp    f010090f <monitor+0x36>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100a2c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100a2f:	5b                   	pop    %ebx
f0100a30:	5e                   	pop    %esi
f0100a31:	5f                   	pop    %edi
f0100a32:	5d                   	pop    %ebp
f0100a33:	c3                   	ret    

f0100a34 <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f0100a34:	55                   	push   %ebp
f0100a35:	89 e5                	mov    %esp,%ebp
f0100a37:	56                   	push   %esi
f0100a38:	53                   	push   %ebx
f0100a39:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100a3b:	83 ec 0c             	sub    $0xc,%esp
f0100a3e:	50                   	push   %eax
f0100a3f:	e8 7a 1f 00 00       	call   f01029be <mc146818_read>
f0100a44:	89 c6                	mov    %eax,%esi
f0100a46:	83 c3 01             	add    $0x1,%ebx
f0100a49:	89 1c 24             	mov    %ebx,(%esp)
f0100a4c:	e8 6d 1f 00 00       	call   f01029be <mc146818_read>
f0100a51:	c1 e0 08             	shl    $0x8,%eax
f0100a54:	09 f0                	or     %esi,%eax
}
f0100a56:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100a59:	5b                   	pop    %ebx
f0100a5a:	5e                   	pop    %esi
f0100a5b:	5d                   	pop    %ebp
f0100a5c:	c3                   	ret    

f0100a5d <page2kva>:
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100a5d:	2b 05 10 8f 22 f0    	sub    0xf0228f10,%eax
f0100a63:	c1 f8 03             	sar    $0x3,%eax
f0100a66:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100a69:	89 c2                	mov    %eax,%edx
f0100a6b:	c1 ea 0c             	shr    $0xc,%edx
f0100a6e:	39 15 08 8f 22 f0    	cmp    %edx,0xf0228f08
f0100a74:	77 18                	ja     f0100a8e <page2kva+0x31>
	return &pages[PGNUM(pa)];
}

static inline void*
page2kva(struct PageInfo *pp)
{
f0100a76:	55                   	push   %ebp
f0100a77:	89 e5                	mov    %esp,%ebp
f0100a79:	83 ec 08             	sub    $0x8,%esp

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100a7c:	50                   	push   %eax
f0100a7d:	68 a4 4f 10 f0       	push   $0xf0104fa4
f0100a82:	6a 58                	push   $0x58
f0100a84:	68 19 5b 10 f0       	push   $0xf0105b19
f0100a89:	e8 b2 f5 ff ff       	call   f0100040 <_panic>
}

static inline void*
page2kva(struct PageInfo *pp)
{
	return KADDR(page2pa(pp));
f0100a8e:	2d 00 00 00 10       	sub    $0x10000000,%eax
}
f0100a93:	c3                   	ret    

f0100a94 <check_va2pa>:
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f0100a94:	89 d1                	mov    %edx,%ecx
f0100a96:	c1 e9 16             	shr    $0x16,%ecx
f0100a99:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0100a9c:	a8 01                	test   $0x1,%al
f0100a9e:	74 52                	je     f0100af2 <check_va2pa+0x5e>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100aa0:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100aa5:	89 c1                	mov    %eax,%ecx
f0100aa7:	c1 e9 0c             	shr    $0xc,%ecx
f0100aaa:	3b 0d 08 8f 22 f0    	cmp    0xf0228f08,%ecx
f0100ab0:	72 1b                	jb     f0100acd <check_va2pa+0x39>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100ab2:	55                   	push   %ebp
f0100ab3:	89 e5                	mov    %esp,%ebp
f0100ab5:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ab8:	50                   	push   %eax
f0100ab9:	68 a4 4f 10 f0       	push   $0xf0104fa4
f0100abe:	68 74 03 00 00       	push   $0x374
f0100ac3:	68 27 5b 10 f0       	push   $0xf0105b27
f0100ac8:	e8 73 f5 ff ff       	call   f0100040 <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f0100acd:	c1 ea 0c             	shr    $0xc,%edx
f0100ad0:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100ad6:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100add:	89 c2                	mov    %eax,%edx
f0100adf:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100ae2:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100ae7:	85 d2                	test   %edx,%edx
f0100ae9:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100aee:	0f 44 c2             	cmove  %edx,%eax
f0100af1:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f0100af2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f0100af7:	c3                   	ret    

f0100af8 <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100af8:	89 c2                	mov    %eax,%edx
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100afa:	83 3d 38 82 22 f0 00 	cmpl   $0x0,0xf0228238
f0100b01:	75 0f                	jne    f0100b12 <boot_alloc+0x1a>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100b03:	b8 07 b0 26 f0       	mov    $0xf026b007,%eax
f0100b08:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100b0d:	a3 38 82 22 f0       	mov    %eax,0xf0228238
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	result = nextfree;
f0100b12:	a1 38 82 22 f0       	mov    0xf0228238,%eax
	if(n > 0){
f0100b17:	85 d2                	test   %edx,%edx
f0100b19:	74 62                	je     f0100b7d <boot_alloc+0x85>
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100b1b:	55                   	push   %ebp
f0100b1c:	89 e5                	mov    %esp,%ebp
f0100b1e:	53                   	push   %ebx
f0100b1f:	83 ec 04             	sub    $0x4,%esp
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100b22:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100b27:	77 12                	ja     f0100b3b <boot_alloc+0x43>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100b29:	50                   	push   %eax
f0100b2a:	68 c8 4f 10 f0       	push   $0xf0104fc8
f0100b2f:	6a 6e                	push   $0x6e
f0100b31:	68 27 5b 10 f0       	push   $0xf0105b27
f0100b36:	e8 05 f5 ff ff       	call   f0100040 <_panic>
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	result = nextfree;
	if(n > 0){
		if (PADDR(nextfree) + n > (npages + 1) * PGSIZE) {
f0100b3b:	8d 9c 10 00 00 00 10 	lea    0x10000000(%eax,%edx,1),%ebx
f0100b42:	8b 0d 08 8f 22 f0    	mov    0xf0228f08,%ecx
f0100b48:	83 c1 01             	add    $0x1,%ecx
f0100b4b:	c1 e1 0c             	shl    $0xc,%ecx
f0100b4e:	39 cb                	cmp    %ecx,%ebx
f0100b50:	76 14                	jbe    f0100b66 <boot_alloc+0x6e>
			panic("out of memory\n");
f0100b52:	83 ec 04             	sub    $0x4,%esp
f0100b55:	68 33 5b 10 f0       	push   $0xf0105b33
f0100b5a:	6a 6f                	push   $0x6f
f0100b5c:	68 27 5b 10 f0       	push   $0xf0105b27
f0100b61:	e8 da f4 ff ff       	call   f0100040 <_panic>
		}
		nextfree = ROUNDUP((char *)nextfree + n, PGSIZE);
f0100b66:	8d 94 10 ff 0f 00 00 	lea    0xfff(%eax,%edx,1),%edx
f0100b6d:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100b73:	89 15 38 82 22 f0    	mov    %edx,0xf0228238
	}
	return result;
}
f0100b79:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100b7c:	c9                   	leave  
f0100b7d:	f3 c3                	repz ret 

f0100b7f <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100b7f:	55                   	push   %ebp
f0100b80:	89 e5                	mov    %esp,%ebp
f0100b82:	53                   	push   %ebx
f0100b83:	83 ec 04             	sub    $0x4,%esp
f0100b86:	8b 1d 40 82 22 f0    	mov    0xf0228240,%ebx
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	
	size_t i, io_page_i, ext_page_i, free_top;
	for (i = 0; i < npages; i++) {
f0100b8c:	ba 00 00 00 00       	mov    $0x0,%edx
f0100b91:	b8 00 00 00 00       	mov    $0x0,%eax
f0100b96:	eb 27                	jmp    f0100bbf <page_init+0x40>
f0100b98:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
		pages[i].pp_ref = 0;
f0100b9f:	89 d1                	mov    %edx,%ecx
f0100ba1:	03 0d 10 8f 22 f0    	add    0xf0228f10,%ecx
f0100ba7:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = page_free_list;
f0100bad:	89 19                	mov    %ebx,(%ecx)
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	
	size_t i, io_page_i, ext_page_i, free_top;
	for (i = 0; i < npages; i++) {
f0100baf:	83 c0 01             	add    $0x1,%eax
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
f0100bb2:	89 d3                	mov    %edx,%ebx
f0100bb4:	03 1d 10 8f 22 f0    	add    0xf0228f10,%ebx
f0100bba:	ba 01 00 00 00       	mov    $0x1,%edx
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	
	size_t i, io_page_i, ext_page_i, free_top;
	for (i = 0; i < npages; i++) {
f0100bbf:	3b 05 08 8f 22 f0    	cmp    0xf0228f08,%eax
f0100bc5:	72 d1                	jb     f0100b98 <page_init+0x19>
f0100bc7:	84 d2                	test   %dl,%dl
f0100bc9:	74 06                	je     f0100bd1 <page_init+0x52>
f0100bcb:	89 1d 40 82 22 f0    	mov    %ebx,0xf0228240
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
  
	pages[0].pp_link = NULL;
f0100bd1:	a1 10 8f 22 f0       	mov    0xf0228f10,%eax
f0100bd6:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pages[1].pp_link = NULL;
f0100bdc:	a1 10 8f 22 f0       	mov    0xf0228f10,%eax
f0100be1:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)

	io_page_i = PGNUM(IOPHYSMEM);
	ext_page_i = PGNUM(EXTPHYSMEM);
	free_top = PGNUM(PADDR(boot_alloc(0)));
f0100be8:	b8 00 00 00 00       	mov    $0x0,%eax
f0100bed:	e8 06 ff ff ff       	call   f0100af8 <boot_alloc>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100bf2:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100bf7:	77 15                	ja     f0100c0e <page_init+0x8f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100bf9:	50                   	push   %eax
f0100bfa:	68 c8 4f 10 f0       	push   $0xf0104fc8
f0100bff:	68 46 01 00 00       	push   $0x146
f0100c04:	68 27 5b 10 f0       	push   $0xf0105b27
f0100c09:	e8 32 f4 ff ff       	call   f0100040 <_panic>
f0100c0e:	8d 88 00 00 00 10    	lea    0x10000000(%eax),%ecx
f0100c14:	c1 e9 0c             	shr    $0xc,%ecx

	pages[ext_page_i].pp_link = pages[io_page_i].pp_link;
f0100c17:	a1 10 8f 22 f0       	mov    0xf0228f10,%eax
f0100c1c:	8b 90 00 05 00 00    	mov    0x500(%eax),%edx
f0100c22:	89 90 00 08 00 00    	mov    %edx,0x800(%eax)
f0100c28:	b8 00 05 00 00       	mov    $0x500,%eax
	for(i = io_page_i;i < ext_page_i;i++)
		pages[i].pp_link = NULL;
f0100c2d:	8b 15 10 8f 22 f0    	mov    0xf0228f10,%edx
f0100c33:	c7 04 02 00 00 00 00 	movl   $0x0,(%edx,%eax,1)
f0100c3a:	83 c0 08             	add    $0x8,%eax
	io_page_i = PGNUM(IOPHYSMEM);
	ext_page_i = PGNUM(EXTPHYSMEM);
	free_top = PGNUM(PADDR(boot_alloc(0)));

	pages[ext_page_i].pp_link = pages[io_page_i].pp_link;
	for(i = io_page_i;i < ext_page_i;i++)
f0100c3d:	3d 00 08 00 00       	cmp    $0x800,%eax
f0100c42:	75 e9                	jne    f0100c2d <page_init+0xae>
		pages[i].pp_link = NULL;

	pages[free_top].pp_link = pages[ext_page_i].pp_link;
f0100c44:	a1 10 8f 22 f0       	mov    0xf0228f10,%eax
f0100c49:	8b 90 00 08 00 00    	mov    0x800(%eax),%edx
f0100c4f:	89 14 c8             	mov    %edx,(%eax,%ecx,8)
	for (i = ext_page_i; i < free_top; i++)
f0100c52:	b8 00 01 00 00       	mov    $0x100,%eax
f0100c57:	eb 10                	jmp    f0100c69 <page_init+0xea>
		pages[i].pp_link = NULL;
f0100c59:	8b 15 10 8f 22 f0    	mov    0xf0228f10,%edx
f0100c5f:	c7 04 c2 00 00 00 00 	movl   $0x0,(%edx,%eax,8)
	pages[ext_page_i].pp_link = pages[io_page_i].pp_link;
	for(i = io_page_i;i < ext_page_i;i++)
		pages[i].pp_link = NULL;

	pages[free_top].pp_link = pages[ext_page_i].pp_link;
	for (i = ext_page_i; i < free_top; i++)
f0100c66:	83 c0 01             	add    $0x1,%eax
f0100c69:	39 c8                	cmp    %ecx,%eax
f0100c6b:	72 ec                	jb     f0100c59 <page_init+0xda>
		pages[i].pp_link = NULL;

}
f0100c6d:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100c70:	c9                   	leave  
f0100c71:	c3                   	ret    

f0100c72 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100c72:	55                   	push   %ebp
f0100c73:	89 e5                	mov    %esp,%ebp
f0100c75:	53                   	push   %ebx
f0100c76:	83 ec 04             	sub    $0x4,%esp
	//Fill this function in
	struct PageInfo *p = page_free_list;
f0100c79:	8b 1d 40 82 22 f0    	mov    0xf0228240,%ebx
	if(p){
f0100c7f:	85 db                	test   %ebx,%ebx
f0100c81:	74 5c                	je     f0100cdf <page_alloc+0x6d>
		page_free_list = p->pp_link;
f0100c83:	8b 03                	mov    (%ebx),%eax
f0100c85:	a3 40 82 22 f0       	mov    %eax,0xf0228240
		p->pp_link = NULL;
f0100c8a:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
		if(alloc_flags & ALLOC_ZERO){
			memset(page2kva(p), 0, PGSIZE);
		}
	}
	else return NULL;
	return p;
f0100c90:	89 d8                	mov    %ebx,%eax
	//Fill this function in
	struct PageInfo *p = page_free_list;
	if(p){
		page_free_list = p->pp_link;
		p->pp_link = NULL;
		if(alloc_flags & ALLOC_ZERO){
f0100c92:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100c96:	74 4c                	je     f0100ce4 <page_alloc+0x72>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100c98:	2b 05 10 8f 22 f0    	sub    0xf0228f10,%eax
f0100c9e:	c1 f8 03             	sar    $0x3,%eax
f0100ca1:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100ca4:	89 c2                	mov    %eax,%edx
f0100ca6:	c1 ea 0c             	shr    $0xc,%edx
f0100ca9:	3b 15 08 8f 22 f0    	cmp    0xf0228f08,%edx
f0100caf:	72 12                	jb     f0100cc3 <page_alloc+0x51>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100cb1:	50                   	push   %eax
f0100cb2:	68 a4 4f 10 f0       	push   $0xf0104fa4
f0100cb7:	6a 58                	push   $0x58
f0100cb9:	68 19 5b 10 f0       	push   $0xf0105b19
f0100cbe:	e8 7d f3 ff ff       	call   f0100040 <_panic>
			memset(page2kva(p), 0, PGSIZE);
f0100cc3:	83 ec 04             	sub    $0x4,%esp
f0100cc6:	68 00 10 00 00       	push   $0x1000
f0100ccb:	6a 00                	push   $0x0
f0100ccd:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100cd2:	50                   	push   %eax
f0100cd3:	e8 ee 35 00 00       	call   f01042c6 <memset>
f0100cd8:	83 c4 10             	add    $0x10,%esp
		}
	}
	else return NULL;
	return p;
f0100cdb:	89 d8                	mov    %ebx,%eax
f0100cdd:	eb 05                	jmp    f0100ce4 <page_alloc+0x72>
		p->pp_link = NULL;
		if(alloc_flags & ALLOC_ZERO){
			memset(page2kva(p), 0, PGSIZE);
		}
	}
	else return NULL;
f0100cdf:	b8 00 00 00 00       	mov    $0x0,%eax
	return p;
}
f0100ce4:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100ce7:	c9                   	leave  
f0100ce8:	c3                   	ret    

f0100ce9 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100ce9:	55                   	push   %ebp
f0100cea:	89 e5                	mov    %esp,%ebp
f0100cec:	83 ec 08             	sub    $0x8,%esp
f0100cef:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
	if(pp->pp_ref != 0 || pp->pp_link!=NULL){
f0100cf2:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100cf7:	75 05                	jne    f0100cfe <page_free+0x15>
f0100cf9:	83 38 00             	cmpl   $0x0,(%eax)
f0100cfc:	74 17                	je     f0100d15 <page_free+0x2c>
		panic("pp->pp_ref is nonzero or pp->pp_link is not NULL\n");
f0100cfe:	83 ec 04             	sub    $0x4,%esp
f0100d01:	68 f4 54 10 f0       	push   $0xf01054f4
f0100d06:	68 79 01 00 00       	push   $0x179
f0100d0b:	68 27 5b 10 f0       	push   $0xf0105b27
f0100d10:	e8 2b f3 ff ff       	call   f0100040 <_panic>
	}
	pp->pp_link = page_free_list;
f0100d15:	8b 15 40 82 22 f0    	mov    0xf0228240,%edx
f0100d1b:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f0100d1d:	a3 40 82 22 f0       	mov    %eax,0xf0228240


}
f0100d22:	c9                   	leave  
f0100d23:	c3                   	ret    

f0100d24 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0100d24:	55                   	push   %ebp
f0100d25:	89 e5                	mov    %esp,%ebp
f0100d27:	83 ec 08             	sub    $0x8,%esp
f0100d2a:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0100d2d:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0100d31:	83 e8 01             	sub    $0x1,%eax
f0100d34:	66 89 42 04          	mov    %ax,0x4(%edx)
f0100d38:	66 85 c0             	test   %ax,%ax
f0100d3b:	75 0c                	jne    f0100d49 <page_decref+0x25>
		page_free(pp);
f0100d3d:	83 ec 0c             	sub    $0xc,%esp
f0100d40:	52                   	push   %edx
f0100d41:	e8 a3 ff ff ff       	call   f0100ce9 <page_free>
f0100d46:	83 c4 10             	add    $0x10,%esp
}
f0100d49:	c9                   	leave  
f0100d4a:	c3                   	ret    

f0100d4b <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100d4b:	55                   	push   %ebp
f0100d4c:	89 e5                	mov    %esp,%ebp
f0100d4e:	56                   	push   %esi
f0100d4f:	53                   	push   %ebx
f0100d50:	8b 75 0c             	mov    0xc(%ebp),%esi
	int pdr_i = PDX(va);
	pde_t *pde = &pgdir[pdr_i];
f0100d53:	89 f3                	mov    %esi,%ebx
f0100d55:	c1 eb 16             	shr    $0x16,%ebx
f0100d58:	c1 e3 02             	shl    $0x2,%ebx
f0100d5b:	03 5d 08             	add    0x8(%ebp),%ebx
	pte_t *pgt;
	if(!(*pde & PTE_P)){
f0100d5e:	f6 03 01             	testb  $0x1,(%ebx)
f0100d61:	75 2f                	jne    f0100d92 <pgdir_walk+0x47>
		if(!create)	
f0100d63:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100d67:	74 64                	je     f0100dcd <pgdir_walk+0x82>
			return NULL;
		struct PageInfo *page = page_alloc(ALLOC_ZERO);
f0100d69:	83 ec 0c             	sub    $0xc,%esp
f0100d6c:	6a 01                	push   $0x1
f0100d6e:	e8 ff fe ff ff       	call   f0100c72 <page_alloc>
		if(page == NULL) return NULL;
f0100d73:	83 c4 10             	add    $0x10,%esp
f0100d76:	85 c0                	test   %eax,%eax
f0100d78:	74 5a                	je     f0100dd4 <pgdir_walk+0x89>
		*pde = page2pa(page) | PTE_P | PTE_U | PTE_W;
f0100d7a:	89 c2                	mov    %eax,%edx
f0100d7c:	2b 15 10 8f 22 f0    	sub    0xf0228f10,%edx
f0100d82:	c1 fa 03             	sar    $0x3,%edx
f0100d85:	c1 e2 0c             	shl    $0xc,%edx
f0100d88:	83 ca 07             	or     $0x7,%edx
f0100d8b:	89 13                	mov    %edx,(%ebx)
		page->pp_ref ++;
f0100d8d:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
	}
	pgt = KADDR(PTE_ADDR(*pde));
f0100d92:	8b 03                	mov    (%ebx),%eax
f0100d94:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100d99:	89 c2                	mov    %eax,%edx
f0100d9b:	c1 ea 0c             	shr    $0xc,%edx
f0100d9e:	3b 15 08 8f 22 f0    	cmp    0xf0228f08,%edx
f0100da4:	72 15                	jb     f0100dbb <pgdir_walk+0x70>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100da6:	50                   	push   %eax
f0100da7:	68 a4 4f 10 f0       	push   $0xf0104fa4
f0100dac:	68 b0 01 00 00       	push   $0x1b0
f0100db1:	68 27 5b 10 f0       	push   $0xf0105b27
f0100db6:	e8 85 f2 ff ff       	call   f0100040 <_panic>
	
	return &pgt[PTX(va)];
f0100dbb:	c1 ee 0a             	shr    $0xa,%esi
f0100dbe:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f0100dc4:	8d 84 30 00 00 00 f0 	lea    -0x10000000(%eax,%esi,1),%eax
f0100dcb:	eb 0c                	jmp    f0100dd9 <pgdir_walk+0x8e>
	int pdr_i = PDX(va);
	pde_t *pde = &pgdir[pdr_i];
	pte_t *pgt;
	if(!(*pde & PTE_P)){
		if(!create)	
			return NULL;
f0100dcd:	b8 00 00 00 00       	mov    $0x0,%eax
f0100dd2:	eb 05                	jmp    f0100dd9 <pgdir_walk+0x8e>
		struct PageInfo *page = page_alloc(ALLOC_ZERO);
		if(page == NULL) return NULL;
f0100dd4:	b8 00 00 00 00       	mov    $0x0,%eax
		page->pp_ref ++;
	}
	pgt = KADDR(PTE_ADDR(*pde));
	
	return &pgt[PTX(va)];
}
f0100dd9:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100ddc:	5b                   	pop    %ebx
f0100ddd:	5e                   	pop    %esi
f0100dde:	5d                   	pop    %ebp
f0100ddf:	c3                   	ret    

f0100de0 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0100de0:	55                   	push   %ebp
f0100de1:	89 e5                	mov    %esp,%ebp
f0100de3:	53                   	push   %ebx
f0100de4:	83 ec 08             	sub    $0x8,%esp
f0100de7:	8b 5d 10             	mov    0x10(%ebp),%ebx
	pte_t *pte = pgdir_walk(pgdir, va, 0);
f0100dea:	6a 00                	push   $0x0
f0100dec:	ff 75 0c             	pushl  0xc(%ebp)
f0100def:	ff 75 08             	pushl  0x8(%ebp)
f0100df2:	e8 54 ff ff ff       	call   f0100d4b <pgdir_walk>
	if(pte == NULL)
f0100df7:	83 c4 10             	add    $0x10,%esp
f0100dfa:	85 c0                	test   %eax,%eax
f0100dfc:	74 32                	je     f0100e30 <page_lookup+0x50>
		return NULL;
	else{
		if(pte_store!=NULL)		
f0100dfe:	85 db                	test   %ebx,%ebx
f0100e00:	74 02                	je     f0100e04 <page_lookup+0x24>
			*pte_store = pte;
f0100e02:	89 03                	mov    %eax,(%ebx)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100e04:	8b 00                	mov    (%eax),%eax
f0100e06:	c1 e8 0c             	shr    $0xc,%eax
f0100e09:	3b 05 08 8f 22 f0    	cmp    0xf0228f08,%eax
f0100e0f:	72 14                	jb     f0100e25 <page_lookup+0x45>
		panic("pa2page called with invalid pa");
f0100e11:	83 ec 04             	sub    $0x4,%esp
f0100e14:	68 28 55 10 f0       	push   $0xf0105528
f0100e19:	6a 51                	push   $0x51
f0100e1b:	68 19 5b 10 f0       	push   $0xf0105b19
f0100e20:	e8 1b f2 ff ff       	call   f0100040 <_panic>
	return &pages[PGNUM(pa)];
f0100e25:	8b 15 10 8f 22 f0    	mov    0xf0228f10,%edx
f0100e2b:	8d 04 c2             	lea    (%edx,%eax,8),%eax
		
		return pa2page(PTE_ADDR(*pte));
f0100e2e:	eb 05                	jmp    f0100e35 <page_lookup+0x55>
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
	pte_t *pte = pgdir_walk(pgdir, va, 0);
	if(pte == NULL)
		return NULL;
f0100e30:	b8 00 00 00 00       	mov    $0x0,%eax
			*pte_store = pte;
		
		return pa2page(PTE_ADDR(*pte));
	}

}
f0100e35:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100e38:	c9                   	leave  
f0100e39:	c3                   	ret    

f0100e3a <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0100e3a:	55                   	push   %ebp
f0100e3b:	89 e5                	mov    %esp,%ebp
f0100e3d:	83 ec 08             	sub    $0x8,%esp
	// Flush the entry only if we're modifying the current address space.
	if (!curenv || curenv->env_pgdir == pgdir)
f0100e40:	e8 a1 3a 00 00       	call   f01048e6 <cpunum>
f0100e45:	6b c0 74             	imul   $0x74,%eax,%eax
f0100e48:	83 b8 28 90 22 f0 00 	cmpl   $0x0,-0xfdd6fd8(%eax)
f0100e4f:	74 16                	je     f0100e67 <tlb_invalidate+0x2d>
f0100e51:	e8 90 3a 00 00       	call   f01048e6 <cpunum>
f0100e56:	6b c0 74             	imul   $0x74,%eax,%eax
f0100e59:	8b 80 28 90 22 f0    	mov    -0xfdd6fd8(%eax),%eax
f0100e5f:	8b 55 08             	mov    0x8(%ebp),%edx
f0100e62:	39 50 60             	cmp    %edx,0x60(%eax)
f0100e65:	75 06                	jne    f0100e6d <tlb_invalidate+0x33>
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0100e67:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100e6a:	0f 01 38             	invlpg (%eax)
		invlpg(va);
}
f0100e6d:	c9                   	leave  
f0100e6e:	c3                   	ret    

f0100e6f <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0100e6f:	55                   	push   %ebp
f0100e70:	89 e5                	mov    %esp,%ebp
f0100e72:	56                   	push   %esi
f0100e73:	53                   	push   %ebx
f0100e74:	83 ec 14             	sub    $0x14,%esp
f0100e77:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0100e7a:	8b 75 0c             	mov    0xc(%ebp),%esi
	// Fill this function in
	pte_t *pte;
	struct PageInfo *pp = page_lookup(pgdir, va, &pte);
f0100e7d:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100e80:	50                   	push   %eax
f0100e81:	56                   	push   %esi
f0100e82:	53                   	push   %ebx
f0100e83:	e8 58 ff ff ff       	call   f0100de0 <page_lookup>
	if(pp!=NULL){
f0100e88:	83 c4 10             	add    $0x10,%esp
f0100e8b:	85 c0                	test   %eax,%eax
f0100e8d:	74 1f                	je     f0100eae <page_remove+0x3f>
		page_decref(pp);
f0100e8f:	83 ec 0c             	sub    $0xc,%esp
f0100e92:	50                   	push   %eax
f0100e93:	e8 8c fe ff ff       	call   f0100d24 <page_decref>
		*pte = 0;
f0100e98:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100e9b:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		tlb_invalidate(pgdir, va);
f0100ea1:	83 c4 08             	add    $0x8,%esp
f0100ea4:	56                   	push   %esi
f0100ea5:	53                   	push   %ebx
f0100ea6:	e8 8f ff ff ff       	call   f0100e3a <tlb_invalidate>
f0100eab:	83 c4 10             	add    $0x10,%esp
	}
}
f0100eae:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100eb1:	5b                   	pop    %ebx
f0100eb2:	5e                   	pop    %esi
f0100eb3:	5d                   	pop    %ebp
f0100eb4:	c3                   	ret    

f0100eb5 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f0100eb5:	55                   	push   %ebp
f0100eb6:	89 e5                	mov    %esp,%ebp
f0100eb8:	57                   	push   %edi
f0100eb9:	56                   	push   %esi
f0100eba:	53                   	push   %ebx
f0100ebb:	83 ec 10             	sub    $0x10,%esp
f0100ebe:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100ec1:	8b 7d 10             	mov    0x10(%ebp),%edi
	pte_t *pte = pgdir_walk(pgdir, va, 1); 
f0100ec4:	6a 01                	push   $0x1
f0100ec6:	57                   	push   %edi
f0100ec7:	ff 75 08             	pushl  0x8(%ebp)
f0100eca:	e8 7c fe ff ff       	call   f0100d4b <pgdir_walk>
	if(pte){
f0100ecf:	83 c4 10             	add    $0x10,%esp
f0100ed2:	85 c0                	test   %eax,%eax
f0100ed4:	74 4a                	je     f0100f20 <page_insert+0x6b>
f0100ed6:	89 c6                	mov    %eax,%esi
		pp->pp_ref ++;
f0100ed8:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
		if(PTE_ADDR(*pte))
f0100edd:	f7 00 00 f0 ff ff    	testl  $0xfffff000,(%eax)
f0100ee3:	74 0f                	je     f0100ef4 <page_insert+0x3f>
			page_remove(pgdir, va);
f0100ee5:	83 ec 08             	sub    $0x8,%esp
f0100ee8:	57                   	push   %edi
f0100ee9:	ff 75 08             	pushl  0x8(%ebp)
f0100eec:	e8 7e ff ff ff       	call   f0100e6f <page_remove>
f0100ef1:	83 c4 10             	add    $0x10,%esp
		*pte = page2pa(pp) | perm |PTE_P;
f0100ef4:	2b 1d 10 8f 22 f0    	sub    0xf0228f10,%ebx
f0100efa:	c1 fb 03             	sar    $0x3,%ebx
f0100efd:	c1 e3 0c             	shl    $0xc,%ebx
f0100f00:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f03:	83 c8 01             	or     $0x1,%eax
f0100f06:	09 c3                	or     %eax,%ebx
f0100f08:	89 1e                	mov    %ebx,(%esi)
		tlb_invalidate(pgdir, va);
f0100f0a:	83 ec 08             	sub    $0x8,%esp
f0100f0d:	57                   	push   %edi
f0100f0e:	ff 75 08             	pushl  0x8(%ebp)
f0100f11:	e8 24 ff ff ff       	call   f0100e3a <tlb_invalidate>
		return 0;
f0100f16:	83 c4 10             	add    $0x10,%esp
f0100f19:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f1e:	eb 05                	jmp    f0100f25 <page_insert+0x70>
	}
	return -E_NO_MEM;
f0100f20:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	
}
f0100f25:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100f28:	5b                   	pop    %ebx
f0100f29:	5e                   	pop    %esi
f0100f2a:	5f                   	pop    %edi
f0100f2b:	5d                   	pop    %ebp
f0100f2c:	c3                   	ret    

f0100f2d <mmio_map_region>:
// location.  Return the base of the reserved region.  size does *not*
// have to be multiple of PGSIZE.
//
void *
mmio_map_region(physaddr_t pa, size_t size)
{
f0100f2d:	55                   	push   %ebp
f0100f2e:	89 e5                	mov    %esp,%ebp
f0100f30:	83 ec 0c             	sub    $0xc,%esp
	// okay to simply panic if this happens).
	//
	// Hint: The staff solution uses boot_map_region.
	//
	// Your code here:
	panic("mmio_map_region not implemented");
f0100f33:	68 48 55 10 f0       	push   $0xf0105548
f0100f38:	68 57 02 00 00       	push   $0x257
f0100f3d:	68 27 5b 10 f0       	push   $0xf0105b27
f0100f42:	e8 f9 f0 ff ff       	call   f0100040 <_panic>

f0100f47 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0100f47:	55                   	push   %ebp
f0100f48:	89 e5                	mov    %esp,%ebp
f0100f4a:	57                   	push   %edi
f0100f4b:	56                   	push   %esi
f0100f4c:	53                   	push   %ebx
f0100f4d:	83 ec 2c             	sub    $0x2c,%esp
{
	size_t basemem, extmem, ext16mem, totalmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	basemem = nvram_read(NVRAM_BASELO);
f0100f50:	b8 15 00 00 00       	mov    $0x15,%eax
f0100f55:	e8 da fa ff ff       	call   f0100a34 <nvram_read>
f0100f5a:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f0100f5c:	b8 17 00 00 00       	mov    $0x17,%eax
f0100f61:	e8 ce fa ff ff       	call   f0100a34 <nvram_read>
f0100f66:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f0100f68:	b8 34 00 00 00       	mov    $0x34,%eax
f0100f6d:	e8 c2 fa ff ff       	call   f0100a34 <nvram_read>
f0100f72:	c1 e0 06             	shl    $0x6,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (ext16mem)
f0100f75:	85 c0                	test   %eax,%eax
f0100f77:	74 07                	je     f0100f80 <mem_init+0x39>
		totalmem = 16 * 1024 + ext16mem;
f0100f79:	05 00 40 00 00       	add    $0x4000,%eax
f0100f7e:	eb 0b                	jmp    f0100f8b <mem_init+0x44>
	else if (extmem)
		totalmem = 1 * 1024 + extmem;
f0100f80:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f0100f86:	85 f6                	test   %esi,%esi
f0100f88:	0f 44 c3             	cmove  %ebx,%eax
	else
		totalmem = basemem;

	npages = totalmem / (PGSIZE / 1024);
f0100f8b:	89 c2                	mov    %eax,%edx
f0100f8d:	c1 ea 02             	shr    $0x2,%edx
f0100f90:	89 15 08 8f 22 f0    	mov    %edx,0xf0228f08
	npages_basemem = basemem / (PGSIZE / 1024);

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0100f96:	89 c2                	mov    %eax,%edx
f0100f98:	29 da                	sub    %ebx,%edx
f0100f9a:	52                   	push   %edx
f0100f9b:	53                   	push   %ebx
f0100f9c:	50                   	push   %eax
f0100f9d:	68 68 55 10 f0       	push   $0xf0105568
f0100fa2:	e8 96 1b 00 00       	call   f0102b3d <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0100fa7:	b8 00 10 00 00       	mov    $0x1000,%eax
f0100fac:	e8 47 fb ff ff       	call   f0100af8 <boot_alloc>
f0100fb1:	a3 0c 8f 22 f0       	mov    %eax,0xf0228f0c
	memset(kern_pgdir, 0, PGSIZE);
f0100fb6:	83 c4 0c             	add    $0xc,%esp
f0100fb9:	68 00 10 00 00       	push   $0x1000
f0100fbe:	6a 00                	push   $0x0
f0100fc0:	50                   	push   %eax
f0100fc1:	e8 00 33 00 00       	call   f01042c6 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0100fc6:	a1 0c 8f 22 f0       	mov    0xf0228f0c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100fcb:	83 c4 10             	add    $0x10,%esp
f0100fce:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100fd3:	77 15                	ja     f0100fea <mem_init+0xa3>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100fd5:	50                   	push   %eax
f0100fd6:	68 c8 4f 10 f0       	push   $0xf0104fc8
f0100fdb:	68 96 00 00 00       	push   $0x96
f0100fe0:	68 27 5b 10 f0       	push   $0xf0105b27
f0100fe5:	e8 56 f0 ff ff       	call   f0100040 <_panic>
f0100fea:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0100ff0:	83 ca 05             	or     $0x5,%edx
f0100ff3:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	pages = (struct PageInfo *) boot_alloc(npages * sizeof(struct PageInfo));
f0100ff9:	a1 08 8f 22 f0       	mov    0xf0228f08,%eax
f0100ffe:	c1 e0 03             	shl    $0x3,%eax
f0101001:	e8 f2 fa ff ff       	call   f0100af8 <boot_alloc>
f0101006:	a3 10 8f 22 f0       	mov    %eax,0xf0228f10
	memset(pages, 0, npages * sizeof(struct PageInfo));
f010100b:	83 ec 04             	sub    $0x4,%esp
f010100e:	8b 35 08 8f 22 f0    	mov    0xf0228f08,%esi
f0101014:	8d 14 f5 00 00 00 00 	lea    0x0(,%esi,8),%edx
f010101b:	52                   	push   %edx
f010101c:	6a 00                	push   $0x0
f010101e:	50                   	push   %eax
f010101f:	e8 a2 32 00 00       	call   f01042c6 <memset>

	//////////////////////////////////////////////////////////////////////
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.
	envs = (struct Env *) boot_alloc(NENV * sizeof(struct Env));
f0101024:	b8 00 f0 01 00       	mov    $0x1f000,%eax
f0101029:	e8 ca fa ff ff       	call   f0100af8 <boot_alloc>
f010102e:	a3 44 82 22 f0       	mov    %eax,0xf0228244
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f0101033:	e8 47 fb ff ff       	call   f0100b7f <page_init>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0101038:	a1 40 82 22 f0       	mov    0xf0228240,%eax
f010103d:	83 c4 10             	add    $0x10,%esp
f0101040:	85 c0                	test   %eax,%eax
f0101042:	75 17                	jne    f010105b <mem_init+0x114>
		panic("'page_free_list' is a null pointer!");
f0101044:	83 ec 04             	sub    $0x4,%esp
f0101047:	68 a4 55 10 f0       	push   $0xf01055a4
f010104c:	68 a7 02 00 00       	push   $0x2a7
f0101051:	68 27 5b 10 f0       	push   $0xf0105b27
f0101056:	e8 e5 ef ff ff       	call   f0100040 <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f010105b:	8d 55 d8             	lea    -0x28(%ebp),%edx
f010105e:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0101061:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0101064:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0101067:	89 c2                	mov    %eax,%edx
f0101069:	2b 15 10 8f 22 f0    	sub    0xf0228f10,%edx
f010106f:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0101075:	0f 95 c2             	setne  %dl
f0101078:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f010107b:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f010107f:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0101081:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0101085:	8b 00                	mov    (%eax),%eax
f0101087:	85 c0                	test   %eax,%eax
f0101089:	75 dc                	jne    f0101067 <mem_init+0x120>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f010108b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010108e:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0101094:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101097:	8b 55 dc             	mov    -0x24(%ebp),%edx
f010109a:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f010109c:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f010109f:	89 1d 40 82 22 f0    	mov    %ebx,0xf0228240
f01010a5:	eb 54                	jmp    f01010fb <mem_init+0x1b4>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01010a7:	89 d8                	mov    %ebx,%eax
f01010a9:	2b 05 10 8f 22 f0    	sub    0xf0228f10,%eax
f01010af:	c1 f8 03             	sar    $0x3,%eax
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
f01010b2:	89 c2                	mov    %eax,%edx
f01010b4:	c1 e2 0c             	shl    $0xc,%edx
f01010b7:	a9 00 fc 0f 00       	test   $0xffc00,%eax
f01010bc:	75 3b                	jne    f01010f9 <mem_init+0x1b2>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01010be:	89 d0                	mov    %edx,%eax
f01010c0:	c1 e8 0c             	shr    $0xc,%eax
f01010c3:	3b 05 08 8f 22 f0    	cmp    0xf0228f08,%eax
f01010c9:	72 12                	jb     f01010dd <mem_init+0x196>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01010cb:	52                   	push   %edx
f01010cc:	68 a4 4f 10 f0       	push   $0xf0104fa4
f01010d1:	6a 58                	push   $0x58
f01010d3:	68 19 5b 10 f0       	push   $0xf0105b19
f01010d8:	e8 63 ef ff ff       	call   f0100040 <_panic>
			memset(page2kva(pp), 0x97, 128);
f01010dd:	83 ec 04             	sub    $0x4,%esp
f01010e0:	68 80 00 00 00       	push   $0x80
f01010e5:	68 97 00 00 00       	push   $0x97
f01010ea:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f01010f0:	52                   	push   %edx
f01010f1:	e8 d0 31 00 00       	call   f01042c6 <memset>
f01010f6:	83 c4 10             	add    $0x10,%esp
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01010f9:	8b 1b                	mov    (%ebx),%ebx
f01010fb:	85 db                	test   %ebx,%ebx
f01010fd:	75 a8                	jne    f01010a7 <mem_init+0x160>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f01010ff:	b8 00 00 00 00       	mov    $0x0,%eax
f0101104:	e8 ef f9 ff ff       	call   f0100af8 <boot_alloc>
f0101109:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f010110c:	8b 15 40 82 22 f0    	mov    0xf0228240,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0101112:	8b 0d 10 8f 22 f0    	mov    0xf0228f10,%ecx
		assert(pp < pages + npages);
f0101118:	a1 08 8f 22 f0       	mov    0xf0228f08,%eax
f010111d:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0101120:	8d 34 c1             	lea    (%ecx,%eax,8),%esi
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0101123:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0101126:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
f010112d:	e9 52 01 00 00       	jmp    f0101284 <mem_init+0x33d>
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0101132:	39 d1                	cmp    %edx,%ecx
f0101134:	76 19                	jbe    f010114f <mem_init+0x208>
f0101136:	68 42 5b 10 f0       	push   $0xf0105b42
f010113b:	68 4e 5b 10 f0       	push   $0xf0105b4e
f0101140:	68 c1 02 00 00       	push   $0x2c1
f0101145:	68 27 5b 10 f0       	push   $0xf0105b27
f010114a:	e8 f1 ee ff ff       	call   f0100040 <_panic>
		assert(pp < pages + npages);
f010114f:	39 f2                	cmp    %esi,%edx
f0101151:	72 19                	jb     f010116c <mem_init+0x225>
f0101153:	68 63 5b 10 f0       	push   $0xf0105b63
f0101158:	68 4e 5b 10 f0       	push   $0xf0105b4e
f010115d:	68 c2 02 00 00       	push   $0x2c2
f0101162:	68 27 5b 10 f0       	push   $0xf0105b27
f0101167:	e8 d4 ee ff ff       	call   f0100040 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f010116c:	89 d0                	mov    %edx,%eax
f010116e:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0101171:	a8 07                	test   $0x7,%al
f0101173:	74 19                	je     f010118e <mem_init+0x247>
f0101175:	68 c8 55 10 f0       	push   $0xf01055c8
f010117a:	68 4e 5b 10 f0       	push   $0xf0105b4e
f010117f:	68 c3 02 00 00       	push   $0x2c3
f0101184:	68 27 5b 10 f0       	push   $0xf0105b27
f0101189:	e8 b2 ee ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010118e:	c1 f8 03             	sar    $0x3,%eax
f0101191:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0101194:	85 c0                	test   %eax,%eax
f0101196:	75 19                	jne    f01011b1 <mem_init+0x26a>
f0101198:	68 77 5b 10 f0       	push   $0xf0105b77
f010119d:	68 4e 5b 10 f0       	push   $0xf0105b4e
f01011a2:	68 c6 02 00 00       	push   $0x2c6
f01011a7:	68 27 5b 10 f0       	push   $0xf0105b27
f01011ac:	e8 8f ee ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f01011b1:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f01011b6:	75 19                	jne    f01011d1 <mem_init+0x28a>
f01011b8:	68 88 5b 10 f0       	push   $0xf0105b88
f01011bd:	68 4e 5b 10 f0       	push   $0xf0105b4e
f01011c2:	68 c7 02 00 00       	push   $0x2c7
f01011c7:	68 27 5b 10 f0       	push   $0xf0105b27
f01011cc:	e8 6f ee ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f01011d1:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f01011d6:	75 19                	jne    f01011f1 <mem_init+0x2aa>
f01011d8:	68 fc 55 10 f0       	push   $0xf01055fc
f01011dd:	68 4e 5b 10 f0       	push   $0xf0105b4e
f01011e2:	68 c8 02 00 00       	push   $0x2c8
f01011e7:	68 27 5b 10 f0       	push   $0xf0105b27
f01011ec:	e8 4f ee ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f01011f1:	3d 00 00 10 00       	cmp    $0x100000,%eax
f01011f6:	75 19                	jne    f0101211 <mem_init+0x2ca>
f01011f8:	68 a1 5b 10 f0       	push   $0xf0105ba1
f01011fd:	68 4e 5b 10 f0       	push   $0xf0105b4e
f0101202:	68 c9 02 00 00       	push   $0x2c9
f0101207:	68 27 5b 10 f0       	push   $0xf0105b27
f010120c:	e8 2f ee ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0101211:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0101216:	0f 86 77 0f 00 00    	jbe    f0102193 <mem_init+0x124c>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010121c:	89 c7                	mov    %eax,%edi
f010121e:	c1 ef 0c             	shr    $0xc,%edi
f0101221:	39 7d c8             	cmp    %edi,-0x38(%ebp)
f0101224:	77 12                	ja     f0101238 <mem_init+0x2f1>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101226:	50                   	push   %eax
f0101227:	68 a4 4f 10 f0       	push   $0xf0104fa4
f010122c:	6a 58                	push   $0x58
f010122e:	68 19 5b 10 f0       	push   $0xf0105b19
f0101233:	e8 08 ee ff ff       	call   f0100040 <_panic>
f0101238:	8d b8 00 00 00 f0    	lea    -0x10000000(%eax),%edi
f010123e:	39 7d cc             	cmp    %edi,-0x34(%ebp)
f0101241:	0f 86 5c 0f 00 00    	jbe    f01021a3 <mem_init+0x125c>
f0101247:	68 20 56 10 f0       	push   $0xf0105620
f010124c:	68 4e 5b 10 f0       	push   $0xf0105b4e
f0101251:	68 ca 02 00 00       	push   $0x2ca
f0101256:	68 27 5b 10 f0       	push   $0xf0105b27
f010125b:	e8 e0 ed ff ff       	call   f0100040 <_panic>
		// (new test for lab 4)
		assert(page2pa(pp) != MPENTRY_PADDR);
f0101260:	68 bb 5b 10 f0       	push   $0xf0105bbb
f0101265:	68 4e 5b 10 f0       	push   $0xf0105b4e
f010126a:	68 cc 02 00 00       	push   $0x2cc
f010126f:	68 27 5b 10 f0       	push   $0xf0105b27
f0101274:	e8 c7 ed ff ff       	call   f0100040 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0101279:	83 c3 01             	add    $0x1,%ebx
f010127c:	eb 04                	jmp    f0101282 <mem_init+0x33b>
		else
			++nfree_extmem;
f010127e:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0101282:	8b 12                	mov    (%edx),%edx
f0101284:	85 d2                	test   %edx,%edx
f0101286:	0f 85 a6 fe ff ff    	jne    f0101132 <mem_init+0x1eb>
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f010128c:	85 db                	test   %ebx,%ebx
f010128e:	7f 19                	jg     f01012a9 <mem_init+0x362>
f0101290:	68 d8 5b 10 f0       	push   $0xf0105bd8
f0101295:	68 4e 5b 10 f0       	push   $0xf0105b4e
f010129a:	68 d4 02 00 00       	push   $0x2d4
f010129f:	68 27 5b 10 f0       	push   $0xf0105b27
f01012a4:	e8 97 ed ff ff       	call   f0100040 <_panic>
	assert(nfree_extmem > 0);
f01012a9:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f01012ad:	7f 19                	jg     f01012c8 <mem_init+0x381>
f01012af:	68 ea 5b 10 f0       	push   $0xf0105bea
f01012b4:	68 4e 5b 10 f0       	push   $0xf0105b4e
f01012b9:	68 d5 02 00 00       	push   $0x2d5
f01012be:	68 27 5b 10 f0       	push   $0xf0105b27
f01012c3:	e8 78 ed ff ff       	call   f0100040 <_panic>

	cprintf("check_page_free_list() succeeded!\n");
f01012c8:	83 ec 0c             	sub    $0xc,%esp
f01012cb:	68 68 56 10 f0       	push   $0xf0105668
f01012d0:	e8 68 18 00 00       	call   f0102b3d <cprintf>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f01012d5:	83 c4 10             	add    $0x10,%esp
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01012d8:	a1 40 82 22 f0       	mov    0xf0228240,%eax
f01012dd:	bb 00 00 00 00       	mov    $0x0,%ebx
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f01012e2:	83 3d 10 8f 22 f0 00 	cmpl   $0x0,0xf0228f10
f01012e9:	75 1c                	jne    f0101307 <mem_init+0x3c0>
		panic("'pages' is a null pointer!");
f01012eb:	83 ec 04             	sub    $0x4,%esp
f01012ee:	68 fb 5b 10 f0       	push   $0xf0105bfb
f01012f3:	68 e8 02 00 00       	push   $0x2e8
f01012f8:	68 27 5b 10 f0       	push   $0xf0105b27
f01012fd:	e8 3e ed ff ff       	call   f0100040 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
		++nfree;
f0101302:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101305:	8b 00                	mov    (%eax),%eax
f0101307:	85 c0                	test   %eax,%eax
f0101309:	75 f7                	jne    f0101302 <mem_init+0x3bb>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010130b:	83 ec 0c             	sub    $0xc,%esp
f010130e:	6a 00                	push   $0x0
f0101310:	e8 5d f9 ff ff       	call   f0100c72 <page_alloc>
f0101315:	89 c7                	mov    %eax,%edi
f0101317:	83 c4 10             	add    $0x10,%esp
f010131a:	85 c0                	test   %eax,%eax
f010131c:	75 19                	jne    f0101337 <mem_init+0x3f0>
f010131e:	68 16 5c 10 f0       	push   $0xf0105c16
f0101323:	68 4e 5b 10 f0       	push   $0xf0105b4e
f0101328:	68 f0 02 00 00       	push   $0x2f0
f010132d:	68 27 5b 10 f0       	push   $0xf0105b27
f0101332:	e8 09 ed ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0101337:	83 ec 0c             	sub    $0xc,%esp
f010133a:	6a 00                	push   $0x0
f010133c:	e8 31 f9 ff ff       	call   f0100c72 <page_alloc>
f0101341:	89 c6                	mov    %eax,%esi
f0101343:	83 c4 10             	add    $0x10,%esp
f0101346:	85 c0                	test   %eax,%eax
f0101348:	75 19                	jne    f0101363 <mem_init+0x41c>
f010134a:	68 2c 5c 10 f0       	push   $0xf0105c2c
f010134f:	68 4e 5b 10 f0       	push   $0xf0105b4e
f0101354:	68 f1 02 00 00       	push   $0x2f1
f0101359:	68 27 5b 10 f0       	push   $0xf0105b27
f010135e:	e8 dd ec ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0101363:	83 ec 0c             	sub    $0xc,%esp
f0101366:	6a 00                	push   $0x0
f0101368:	e8 05 f9 ff ff       	call   f0100c72 <page_alloc>
f010136d:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101370:	83 c4 10             	add    $0x10,%esp
f0101373:	85 c0                	test   %eax,%eax
f0101375:	75 19                	jne    f0101390 <mem_init+0x449>
f0101377:	68 42 5c 10 f0       	push   $0xf0105c42
f010137c:	68 4e 5b 10 f0       	push   $0xf0105b4e
f0101381:	68 f2 02 00 00       	push   $0x2f2
f0101386:	68 27 5b 10 f0       	push   $0xf0105b27
f010138b:	e8 b0 ec ff ff       	call   f0100040 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101390:	39 f7                	cmp    %esi,%edi
f0101392:	75 19                	jne    f01013ad <mem_init+0x466>
f0101394:	68 58 5c 10 f0       	push   $0xf0105c58
f0101399:	68 4e 5b 10 f0       	push   $0xf0105b4e
f010139e:	68 f5 02 00 00       	push   $0x2f5
f01013a3:	68 27 5b 10 f0       	push   $0xf0105b27
f01013a8:	e8 93 ec ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01013ad:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01013b0:	39 c7                	cmp    %eax,%edi
f01013b2:	74 04                	je     f01013b8 <mem_init+0x471>
f01013b4:	39 c6                	cmp    %eax,%esi
f01013b6:	75 19                	jne    f01013d1 <mem_init+0x48a>
f01013b8:	68 8c 56 10 f0       	push   $0xf010568c
f01013bd:	68 4e 5b 10 f0       	push   $0xf0105b4e
f01013c2:	68 f6 02 00 00       	push   $0x2f6
f01013c7:	68 27 5b 10 f0       	push   $0xf0105b27
f01013cc:	e8 6f ec ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01013d1:	8b 0d 10 8f 22 f0    	mov    0xf0228f10,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f01013d7:	8b 15 08 8f 22 f0    	mov    0xf0228f08,%edx
f01013dd:	c1 e2 0c             	shl    $0xc,%edx
f01013e0:	89 f8                	mov    %edi,%eax
f01013e2:	29 c8                	sub    %ecx,%eax
f01013e4:	c1 f8 03             	sar    $0x3,%eax
f01013e7:	c1 e0 0c             	shl    $0xc,%eax
f01013ea:	39 d0                	cmp    %edx,%eax
f01013ec:	72 19                	jb     f0101407 <mem_init+0x4c0>
f01013ee:	68 6a 5c 10 f0       	push   $0xf0105c6a
f01013f3:	68 4e 5b 10 f0       	push   $0xf0105b4e
f01013f8:	68 f7 02 00 00       	push   $0x2f7
f01013fd:	68 27 5b 10 f0       	push   $0xf0105b27
f0101402:	e8 39 ec ff ff       	call   f0100040 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f0101407:	89 f0                	mov    %esi,%eax
f0101409:	29 c8                	sub    %ecx,%eax
f010140b:	c1 f8 03             	sar    $0x3,%eax
f010140e:	c1 e0 0c             	shl    $0xc,%eax
f0101411:	39 c2                	cmp    %eax,%edx
f0101413:	77 19                	ja     f010142e <mem_init+0x4e7>
f0101415:	68 87 5c 10 f0       	push   $0xf0105c87
f010141a:	68 4e 5b 10 f0       	push   $0xf0105b4e
f010141f:	68 f8 02 00 00       	push   $0x2f8
f0101424:	68 27 5b 10 f0       	push   $0xf0105b27
f0101429:	e8 12 ec ff ff       	call   f0100040 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f010142e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101431:	29 c8                	sub    %ecx,%eax
f0101433:	c1 f8 03             	sar    $0x3,%eax
f0101436:	c1 e0 0c             	shl    $0xc,%eax
f0101439:	39 c2                	cmp    %eax,%edx
f010143b:	77 19                	ja     f0101456 <mem_init+0x50f>
f010143d:	68 a4 5c 10 f0       	push   $0xf0105ca4
f0101442:	68 4e 5b 10 f0       	push   $0xf0105b4e
f0101447:	68 f9 02 00 00       	push   $0x2f9
f010144c:	68 27 5b 10 f0       	push   $0xf0105b27
f0101451:	e8 ea eb ff ff       	call   f0100040 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101456:	a1 40 82 22 f0       	mov    0xf0228240,%eax
f010145b:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f010145e:	c7 05 40 82 22 f0 00 	movl   $0x0,0xf0228240
f0101465:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101468:	83 ec 0c             	sub    $0xc,%esp
f010146b:	6a 00                	push   $0x0
f010146d:	e8 00 f8 ff ff       	call   f0100c72 <page_alloc>
f0101472:	83 c4 10             	add    $0x10,%esp
f0101475:	85 c0                	test   %eax,%eax
f0101477:	74 19                	je     f0101492 <mem_init+0x54b>
f0101479:	68 c1 5c 10 f0       	push   $0xf0105cc1
f010147e:	68 4e 5b 10 f0       	push   $0xf0105b4e
f0101483:	68 00 03 00 00       	push   $0x300
f0101488:	68 27 5b 10 f0       	push   $0xf0105b27
f010148d:	e8 ae eb ff ff       	call   f0100040 <_panic>

	// free and re-allocate?
	page_free(pp0);
f0101492:	83 ec 0c             	sub    $0xc,%esp
f0101495:	57                   	push   %edi
f0101496:	e8 4e f8 ff ff       	call   f0100ce9 <page_free>
	page_free(pp1);
f010149b:	89 34 24             	mov    %esi,(%esp)
f010149e:	e8 46 f8 ff ff       	call   f0100ce9 <page_free>
	page_free(pp2);
f01014a3:	83 c4 04             	add    $0x4,%esp
f01014a6:	ff 75 d4             	pushl  -0x2c(%ebp)
f01014a9:	e8 3b f8 ff ff       	call   f0100ce9 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01014ae:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01014b5:	e8 b8 f7 ff ff       	call   f0100c72 <page_alloc>
f01014ba:	89 c6                	mov    %eax,%esi
f01014bc:	83 c4 10             	add    $0x10,%esp
f01014bf:	85 c0                	test   %eax,%eax
f01014c1:	75 19                	jne    f01014dc <mem_init+0x595>
f01014c3:	68 16 5c 10 f0       	push   $0xf0105c16
f01014c8:	68 4e 5b 10 f0       	push   $0xf0105b4e
f01014cd:	68 07 03 00 00       	push   $0x307
f01014d2:	68 27 5b 10 f0       	push   $0xf0105b27
f01014d7:	e8 64 eb ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f01014dc:	83 ec 0c             	sub    $0xc,%esp
f01014df:	6a 00                	push   $0x0
f01014e1:	e8 8c f7 ff ff       	call   f0100c72 <page_alloc>
f01014e6:	89 c7                	mov    %eax,%edi
f01014e8:	83 c4 10             	add    $0x10,%esp
f01014eb:	85 c0                	test   %eax,%eax
f01014ed:	75 19                	jne    f0101508 <mem_init+0x5c1>
f01014ef:	68 2c 5c 10 f0       	push   $0xf0105c2c
f01014f4:	68 4e 5b 10 f0       	push   $0xf0105b4e
f01014f9:	68 08 03 00 00       	push   $0x308
f01014fe:	68 27 5b 10 f0       	push   $0xf0105b27
f0101503:	e8 38 eb ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0101508:	83 ec 0c             	sub    $0xc,%esp
f010150b:	6a 00                	push   $0x0
f010150d:	e8 60 f7 ff ff       	call   f0100c72 <page_alloc>
f0101512:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101515:	83 c4 10             	add    $0x10,%esp
f0101518:	85 c0                	test   %eax,%eax
f010151a:	75 19                	jne    f0101535 <mem_init+0x5ee>
f010151c:	68 42 5c 10 f0       	push   $0xf0105c42
f0101521:	68 4e 5b 10 f0       	push   $0xf0105b4e
f0101526:	68 09 03 00 00       	push   $0x309
f010152b:	68 27 5b 10 f0       	push   $0xf0105b27
f0101530:	e8 0b eb ff ff       	call   f0100040 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101535:	39 fe                	cmp    %edi,%esi
f0101537:	75 19                	jne    f0101552 <mem_init+0x60b>
f0101539:	68 58 5c 10 f0       	push   $0xf0105c58
f010153e:	68 4e 5b 10 f0       	push   $0xf0105b4e
f0101543:	68 0b 03 00 00       	push   $0x30b
f0101548:	68 27 5b 10 f0       	push   $0xf0105b27
f010154d:	e8 ee ea ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101552:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101555:	39 c6                	cmp    %eax,%esi
f0101557:	74 04                	je     f010155d <mem_init+0x616>
f0101559:	39 c7                	cmp    %eax,%edi
f010155b:	75 19                	jne    f0101576 <mem_init+0x62f>
f010155d:	68 8c 56 10 f0       	push   $0xf010568c
f0101562:	68 4e 5b 10 f0       	push   $0xf0105b4e
f0101567:	68 0c 03 00 00       	push   $0x30c
f010156c:	68 27 5b 10 f0       	push   $0xf0105b27
f0101571:	e8 ca ea ff ff       	call   f0100040 <_panic>
	assert(!page_alloc(0));
f0101576:	83 ec 0c             	sub    $0xc,%esp
f0101579:	6a 00                	push   $0x0
f010157b:	e8 f2 f6 ff ff       	call   f0100c72 <page_alloc>
f0101580:	83 c4 10             	add    $0x10,%esp
f0101583:	85 c0                	test   %eax,%eax
f0101585:	74 19                	je     f01015a0 <mem_init+0x659>
f0101587:	68 c1 5c 10 f0       	push   $0xf0105cc1
f010158c:	68 4e 5b 10 f0       	push   $0xf0105b4e
f0101591:	68 0d 03 00 00       	push   $0x30d
f0101596:	68 27 5b 10 f0       	push   $0xf0105b27
f010159b:	e8 a0 ea ff ff       	call   f0100040 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f01015a0:	89 f0                	mov    %esi,%eax
f01015a2:	e8 b6 f4 ff ff       	call   f0100a5d <page2kva>
f01015a7:	83 ec 04             	sub    $0x4,%esp
f01015aa:	68 00 10 00 00       	push   $0x1000
f01015af:	6a 01                	push   $0x1
f01015b1:	50                   	push   %eax
f01015b2:	e8 0f 2d 00 00       	call   f01042c6 <memset>
	page_free(pp0);
f01015b7:	89 34 24             	mov    %esi,(%esp)
f01015ba:	e8 2a f7 ff ff       	call   f0100ce9 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01015bf:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01015c6:	e8 a7 f6 ff ff       	call   f0100c72 <page_alloc>
f01015cb:	83 c4 10             	add    $0x10,%esp
f01015ce:	85 c0                	test   %eax,%eax
f01015d0:	75 19                	jne    f01015eb <mem_init+0x6a4>
f01015d2:	68 d0 5c 10 f0       	push   $0xf0105cd0
f01015d7:	68 4e 5b 10 f0       	push   $0xf0105b4e
f01015dc:	68 12 03 00 00       	push   $0x312
f01015e1:	68 27 5b 10 f0       	push   $0xf0105b27
f01015e6:	e8 55 ea ff ff       	call   f0100040 <_panic>
	assert(pp && pp0 == pp);
f01015eb:	39 c6                	cmp    %eax,%esi
f01015ed:	74 19                	je     f0101608 <mem_init+0x6c1>
f01015ef:	68 ee 5c 10 f0       	push   $0xf0105cee
f01015f4:	68 4e 5b 10 f0       	push   $0xf0105b4e
f01015f9:	68 13 03 00 00       	push   $0x313
f01015fe:	68 27 5b 10 f0       	push   $0xf0105b27
f0101603:	e8 38 ea ff ff       	call   f0100040 <_panic>
	c = page2kva(pp);
f0101608:	89 f0                	mov    %esi,%eax
f010160a:	e8 4e f4 ff ff       	call   f0100a5d <page2kva>
f010160f:	8d 90 00 10 00 00    	lea    0x1000(%eax),%edx
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f0101615:	80 38 00             	cmpb   $0x0,(%eax)
f0101618:	74 19                	je     f0101633 <mem_init+0x6ec>
f010161a:	68 fe 5c 10 f0       	push   $0xf0105cfe
f010161f:	68 4e 5b 10 f0       	push   $0xf0105b4e
f0101624:	68 16 03 00 00       	push   $0x316
f0101629:	68 27 5b 10 f0       	push   $0xf0105b27
f010162e:	e8 0d ea ff ff       	call   f0100040 <_panic>
f0101633:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f0101636:	39 d0                	cmp    %edx,%eax
f0101638:	75 db                	jne    f0101615 <mem_init+0x6ce>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f010163a:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010163d:	a3 40 82 22 f0       	mov    %eax,0xf0228240

	// free the pages we took
	page_free(pp0);
f0101642:	83 ec 0c             	sub    $0xc,%esp
f0101645:	56                   	push   %esi
f0101646:	e8 9e f6 ff ff       	call   f0100ce9 <page_free>
	page_free(pp1);
f010164b:	89 3c 24             	mov    %edi,(%esp)
f010164e:	e8 96 f6 ff ff       	call   f0100ce9 <page_free>
	page_free(pp2);
f0101653:	83 c4 04             	add    $0x4,%esp
f0101656:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101659:	e8 8b f6 ff ff       	call   f0100ce9 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010165e:	a1 40 82 22 f0       	mov    0xf0228240,%eax
f0101663:	83 c4 10             	add    $0x10,%esp
f0101666:	eb 05                	jmp    f010166d <mem_init+0x726>
		--nfree;
f0101668:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010166b:	8b 00                	mov    (%eax),%eax
f010166d:	85 c0                	test   %eax,%eax
f010166f:	75 f7                	jne    f0101668 <mem_init+0x721>
		--nfree;
	assert(nfree == 0);
f0101671:	85 db                	test   %ebx,%ebx
f0101673:	74 19                	je     f010168e <mem_init+0x747>
f0101675:	68 08 5d 10 f0       	push   $0xf0105d08
f010167a:	68 4e 5b 10 f0       	push   $0xf0105b4e
f010167f:	68 23 03 00 00       	push   $0x323
f0101684:	68 27 5b 10 f0       	push   $0xf0105b27
f0101689:	e8 b2 e9 ff ff       	call   f0100040 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f010168e:	83 ec 0c             	sub    $0xc,%esp
f0101691:	68 ac 56 10 f0       	push   $0xf01056ac
f0101696:	e8 a2 14 00 00       	call   f0102b3d <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010169b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01016a2:	e8 cb f5 ff ff       	call   f0100c72 <page_alloc>
f01016a7:	89 c3                	mov    %eax,%ebx
f01016a9:	83 c4 10             	add    $0x10,%esp
f01016ac:	85 c0                	test   %eax,%eax
f01016ae:	75 19                	jne    f01016c9 <mem_init+0x782>
f01016b0:	68 16 5c 10 f0       	push   $0xf0105c16
f01016b5:	68 4e 5b 10 f0       	push   $0xf0105b4e
f01016ba:	68 89 03 00 00       	push   $0x389
f01016bf:	68 27 5b 10 f0       	push   $0xf0105b27
f01016c4:	e8 77 e9 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f01016c9:	83 ec 0c             	sub    $0xc,%esp
f01016cc:	6a 00                	push   $0x0
f01016ce:	e8 9f f5 ff ff       	call   f0100c72 <page_alloc>
f01016d3:	89 c6                	mov    %eax,%esi
f01016d5:	83 c4 10             	add    $0x10,%esp
f01016d8:	85 c0                	test   %eax,%eax
f01016da:	75 19                	jne    f01016f5 <mem_init+0x7ae>
f01016dc:	68 2c 5c 10 f0       	push   $0xf0105c2c
f01016e1:	68 4e 5b 10 f0       	push   $0xf0105b4e
f01016e6:	68 8a 03 00 00       	push   $0x38a
f01016eb:	68 27 5b 10 f0       	push   $0xf0105b27
f01016f0:	e8 4b e9 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f01016f5:	83 ec 0c             	sub    $0xc,%esp
f01016f8:	6a 00                	push   $0x0
f01016fa:	e8 73 f5 ff ff       	call   f0100c72 <page_alloc>
f01016ff:	89 c7                	mov    %eax,%edi
f0101701:	83 c4 10             	add    $0x10,%esp
f0101704:	85 c0                	test   %eax,%eax
f0101706:	75 19                	jne    f0101721 <mem_init+0x7da>
f0101708:	68 42 5c 10 f0       	push   $0xf0105c42
f010170d:	68 4e 5b 10 f0       	push   $0xf0105b4e
f0101712:	68 8b 03 00 00       	push   $0x38b
f0101717:	68 27 5b 10 f0       	push   $0xf0105b27
f010171c:	e8 1f e9 ff ff       	call   f0100040 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101721:	39 f3                	cmp    %esi,%ebx
f0101723:	75 19                	jne    f010173e <mem_init+0x7f7>
f0101725:	68 58 5c 10 f0       	push   $0xf0105c58
f010172a:	68 4e 5b 10 f0       	push   $0xf0105b4e
f010172f:	68 8e 03 00 00       	push   $0x38e
f0101734:	68 27 5b 10 f0       	push   $0xf0105b27
f0101739:	e8 02 e9 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010173e:	39 c6                	cmp    %eax,%esi
f0101740:	74 04                	je     f0101746 <mem_init+0x7ff>
f0101742:	39 c3                	cmp    %eax,%ebx
f0101744:	75 19                	jne    f010175f <mem_init+0x818>
f0101746:	68 8c 56 10 f0       	push   $0xf010568c
f010174b:	68 4e 5b 10 f0       	push   $0xf0105b4e
f0101750:	68 8f 03 00 00       	push   $0x38f
f0101755:	68 27 5b 10 f0       	push   $0xf0105b27
f010175a:	e8 e1 e8 ff ff       	call   f0100040 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f010175f:	a1 40 82 22 f0       	mov    0xf0228240,%eax
f0101764:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	page_free_list = 0;
f0101767:	c7 05 40 82 22 f0 00 	movl   $0x0,0xf0228240
f010176e:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101771:	83 ec 0c             	sub    $0xc,%esp
f0101774:	6a 00                	push   $0x0
f0101776:	e8 f7 f4 ff ff       	call   f0100c72 <page_alloc>
f010177b:	83 c4 10             	add    $0x10,%esp
f010177e:	85 c0                	test   %eax,%eax
f0101780:	74 19                	je     f010179b <mem_init+0x854>
f0101782:	68 c1 5c 10 f0       	push   $0xf0105cc1
f0101787:	68 4e 5b 10 f0       	push   $0xf0105b4e
f010178c:	68 96 03 00 00       	push   $0x396
f0101791:	68 27 5b 10 f0       	push   $0xf0105b27
f0101796:	e8 a5 e8 ff ff       	call   f0100040 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f010179b:	83 ec 04             	sub    $0x4,%esp
f010179e:	8d 45 e0             	lea    -0x20(%ebp),%eax
f01017a1:	50                   	push   %eax
f01017a2:	6a 00                	push   $0x0
f01017a4:	ff 35 0c 8f 22 f0    	pushl  0xf0228f0c
f01017aa:	e8 31 f6 ff ff       	call   f0100de0 <page_lookup>
f01017af:	83 c4 10             	add    $0x10,%esp
f01017b2:	85 c0                	test   %eax,%eax
f01017b4:	74 19                	je     f01017cf <mem_init+0x888>
f01017b6:	68 cc 56 10 f0       	push   $0xf01056cc
f01017bb:	68 4e 5b 10 f0       	push   $0xf0105b4e
f01017c0:	68 99 03 00 00       	push   $0x399
f01017c5:	68 27 5b 10 f0       	push   $0xf0105b27
f01017ca:	e8 71 e8 ff ff       	call   f0100040 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f01017cf:	6a 02                	push   $0x2
f01017d1:	6a 00                	push   $0x0
f01017d3:	56                   	push   %esi
f01017d4:	ff 35 0c 8f 22 f0    	pushl  0xf0228f0c
f01017da:	e8 d6 f6 ff ff       	call   f0100eb5 <page_insert>
f01017df:	83 c4 10             	add    $0x10,%esp
f01017e2:	85 c0                	test   %eax,%eax
f01017e4:	78 19                	js     f01017ff <mem_init+0x8b8>
f01017e6:	68 04 57 10 f0       	push   $0xf0105704
f01017eb:	68 4e 5b 10 f0       	push   $0xf0105b4e
f01017f0:	68 9c 03 00 00       	push   $0x39c
f01017f5:	68 27 5b 10 f0       	push   $0xf0105b27
f01017fa:	e8 41 e8 ff ff       	call   f0100040 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f01017ff:	83 ec 0c             	sub    $0xc,%esp
f0101802:	53                   	push   %ebx
f0101803:	e8 e1 f4 ff ff       	call   f0100ce9 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101808:	6a 02                	push   $0x2
f010180a:	6a 00                	push   $0x0
f010180c:	56                   	push   %esi
f010180d:	ff 35 0c 8f 22 f0    	pushl  0xf0228f0c
f0101813:	e8 9d f6 ff ff       	call   f0100eb5 <page_insert>
f0101818:	83 c4 20             	add    $0x20,%esp
f010181b:	85 c0                	test   %eax,%eax
f010181d:	74 19                	je     f0101838 <mem_init+0x8f1>
f010181f:	68 34 57 10 f0       	push   $0xf0105734
f0101824:	68 4e 5b 10 f0       	push   $0xf0105b4e
f0101829:	68 a0 03 00 00       	push   $0x3a0
f010182e:	68 27 5b 10 f0       	push   $0xf0105b27
f0101833:	e8 08 e8 ff ff       	call   f0100040 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101838:	a1 0c 8f 22 f0       	mov    0xf0228f0c,%eax
f010183d:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101840:	8b 0d 10 8f 22 f0    	mov    0xf0228f10,%ecx
f0101846:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0101849:	8b 00                	mov    (%eax),%eax
f010184b:	89 45 c8             	mov    %eax,-0x38(%ebp)
f010184e:	89 c2                	mov    %eax,%edx
f0101850:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101856:	89 d8                	mov    %ebx,%eax
f0101858:	29 c8                	sub    %ecx,%eax
f010185a:	c1 f8 03             	sar    $0x3,%eax
f010185d:	c1 e0 0c             	shl    $0xc,%eax
f0101860:	39 c2                	cmp    %eax,%edx
f0101862:	74 19                	je     f010187d <mem_init+0x936>
f0101864:	68 64 57 10 f0       	push   $0xf0105764
f0101869:	68 4e 5b 10 f0       	push   $0xf0105b4e
f010186e:	68 a1 03 00 00       	push   $0x3a1
f0101873:	68 27 5b 10 f0       	push   $0xf0105b27
f0101878:	e8 c3 e7 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f010187d:	ba 00 00 00 00       	mov    $0x0,%edx
f0101882:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101885:	e8 0a f2 ff ff       	call   f0100a94 <check_va2pa>
f010188a:	89 f2                	mov    %esi,%edx
f010188c:	2b 55 cc             	sub    -0x34(%ebp),%edx
f010188f:	c1 fa 03             	sar    $0x3,%edx
f0101892:	c1 e2 0c             	shl    $0xc,%edx
f0101895:	39 d0                	cmp    %edx,%eax
f0101897:	74 19                	je     f01018b2 <mem_init+0x96b>
f0101899:	68 8c 57 10 f0       	push   $0xf010578c
f010189e:	68 4e 5b 10 f0       	push   $0xf0105b4e
f01018a3:	68 a2 03 00 00       	push   $0x3a2
f01018a8:	68 27 5b 10 f0       	push   $0xf0105b27
f01018ad:	e8 8e e7 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f01018b2:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01018b7:	74 19                	je     f01018d2 <mem_init+0x98b>
f01018b9:	68 13 5d 10 f0       	push   $0xf0105d13
f01018be:	68 4e 5b 10 f0       	push   $0xf0105b4e
f01018c3:	68 a3 03 00 00       	push   $0x3a3
f01018c8:	68 27 5b 10 f0       	push   $0xf0105b27
f01018cd:	e8 6e e7 ff ff       	call   f0100040 <_panic>
	assert(pp0->pp_ref == 1);
f01018d2:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01018d7:	74 19                	je     f01018f2 <mem_init+0x9ab>
f01018d9:	68 24 5d 10 f0       	push   $0xf0105d24
f01018de:	68 4e 5b 10 f0       	push   $0xf0105b4e
f01018e3:	68 a4 03 00 00       	push   $0x3a4
f01018e8:	68 27 5b 10 f0       	push   $0xf0105b27
f01018ed:	e8 4e e7 ff ff       	call   f0100040 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01018f2:	6a 02                	push   $0x2
f01018f4:	68 00 10 00 00       	push   $0x1000
f01018f9:	57                   	push   %edi
f01018fa:	ff 75 d0             	pushl  -0x30(%ebp)
f01018fd:	e8 b3 f5 ff ff       	call   f0100eb5 <page_insert>
f0101902:	83 c4 10             	add    $0x10,%esp
f0101905:	85 c0                	test   %eax,%eax
f0101907:	74 19                	je     f0101922 <mem_init+0x9db>
f0101909:	68 bc 57 10 f0       	push   $0xf01057bc
f010190e:	68 4e 5b 10 f0       	push   $0xf0105b4e
f0101913:	68 a7 03 00 00       	push   $0x3a7
f0101918:	68 27 5b 10 f0       	push   $0xf0105b27
f010191d:	e8 1e e7 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101922:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101927:	a1 0c 8f 22 f0       	mov    0xf0228f0c,%eax
f010192c:	e8 63 f1 ff ff       	call   f0100a94 <check_va2pa>
f0101931:	89 fa                	mov    %edi,%edx
f0101933:	2b 15 10 8f 22 f0    	sub    0xf0228f10,%edx
f0101939:	c1 fa 03             	sar    $0x3,%edx
f010193c:	c1 e2 0c             	shl    $0xc,%edx
f010193f:	39 d0                	cmp    %edx,%eax
f0101941:	74 19                	je     f010195c <mem_init+0xa15>
f0101943:	68 f8 57 10 f0       	push   $0xf01057f8
f0101948:	68 4e 5b 10 f0       	push   $0xf0105b4e
f010194d:	68 a8 03 00 00       	push   $0x3a8
f0101952:	68 27 5b 10 f0       	push   $0xf0105b27
f0101957:	e8 e4 e6 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f010195c:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0101961:	74 19                	je     f010197c <mem_init+0xa35>
f0101963:	68 35 5d 10 f0       	push   $0xf0105d35
f0101968:	68 4e 5b 10 f0       	push   $0xf0105b4e
f010196d:	68 a9 03 00 00       	push   $0x3a9
f0101972:	68 27 5b 10 f0       	push   $0xf0105b27
f0101977:	e8 c4 e6 ff ff       	call   f0100040 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f010197c:	83 ec 0c             	sub    $0xc,%esp
f010197f:	6a 00                	push   $0x0
f0101981:	e8 ec f2 ff ff       	call   f0100c72 <page_alloc>
f0101986:	83 c4 10             	add    $0x10,%esp
f0101989:	85 c0                	test   %eax,%eax
f010198b:	74 19                	je     f01019a6 <mem_init+0xa5f>
f010198d:	68 c1 5c 10 f0       	push   $0xf0105cc1
f0101992:	68 4e 5b 10 f0       	push   $0xf0105b4e
f0101997:	68 ac 03 00 00       	push   $0x3ac
f010199c:	68 27 5b 10 f0       	push   $0xf0105b27
f01019a1:	e8 9a e6 ff ff       	call   f0100040 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01019a6:	6a 02                	push   $0x2
f01019a8:	68 00 10 00 00       	push   $0x1000
f01019ad:	57                   	push   %edi
f01019ae:	ff 35 0c 8f 22 f0    	pushl  0xf0228f0c
f01019b4:	e8 fc f4 ff ff       	call   f0100eb5 <page_insert>
f01019b9:	83 c4 10             	add    $0x10,%esp
f01019bc:	85 c0                	test   %eax,%eax
f01019be:	74 19                	je     f01019d9 <mem_init+0xa92>
f01019c0:	68 bc 57 10 f0       	push   $0xf01057bc
f01019c5:	68 4e 5b 10 f0       	push   $0xf0105b4e
f01019ca:	68 af 03 00 00       	push   $0x3af
f01019cf:	68 27 5b 10 f0       	push   $0xf0105b27
f01019d4:	e8 67 e6 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01019d9:	ba 00 10 00 00       	mov    $0x1000,%edx
f01019de:	a1 0c 8f 22 f0       	mov    0xf0228f0c,%eax
f01019e3:	e8 ac f0 ff ff       	call   f0100a94 <check_va2pa>
f01019e8:	89 fa                	mov    %edi,%edx
f01019ea:	2b 15 10 8f 22 f0    	sub    0xf0228f10,%edx
f01019f0:	c1 fa 03             	sar    $0x3,%edx
f01019f3:	c1 e2 0c             	shl    $0xc,%edx
f01019f6:	39 d0                	cmp    %edx,%eax
f01019f8:	74 19                	je     f0101a13 <mem_init+0xacc>
f01019fa:	68 f8 57 10 f0       	push   $0xf01057f8
f01019ff:	68 4e 5b 10 f0       	push   $0xf0105b4e
f0101a04:	68 b0 03 00 00       	push   $0x3b0
f0101a09:	68 27 5b 10 f0       	push   $0xf0105b27
f0101a0e:	e8 2d e6 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101a13:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0101a18:	74 19                	je     f0101a33 <mem_init+0xaec>
f0101a1a:	68 35 5d 10 f0       	push   $0xf0105d35
f0101a1f:	68 4e 5b 10 f0       	push   $0xf0105b4e
f0101a24:	68 b1 03 00 00       	push   $0x3b1
f0101a29:	68 27 5b 10 f0       	push   $0xf0105b27
f0101a2e:	e8 0d e6 ff ff       	call   f0100040 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101a33:	83 ec 0c             	sub    $0xc,%esp
f0101a36:	6a 00                	push   $0x0
f0101a38:	e8 35 f2 ff ff       	call   f0100c72 <page_alloc>
f0101a3d:	83 c4 10             	add    $0x10,%esp
f0101a40:	85 c0                	test   %eax,%eax
f0101a42:	74 19                	je     f0101a5d <mem_init+0xb16>
f0101a44:	68 c1 5c 10 f0       	push   $0xf0105cc1
f0101a49:	68 4e 5b 10 f0       	push   $0xf0105b4e
f0101a4e:	68 b5 03 00 00       	push   $0x3b5
f0101a53:	68 27 5b 10 f0       	push   $0xf0105b27
f0101a58:	e8 e3 e5 ff ff       	call   f0100040 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101a5d:	8b 15 0c 8f 22 f0    	mov    0xf0228f0c,%edx
f0101a63:	8b 02                	mov    (%edx),%eax
f0101a65:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101a6a:	89 c1                	mov    %eax,%ecx
f0101a6c:	c1 e9 0c             	shr    $0xc,%ecx
f0101a6f:	3b 0d 08 8f 22 f0    	cmp    0xf0228f08,%ecx
f0101a75:	72 15                	jb     f0101a8c <mem_init+0xb45>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101a77:	50                   	push   %eax
f0101a78:	68 a4 4f 10 f0       	push   $0xf0104fa4
f0101a7d:	68 b8 03 00 00       	push   $0x3b8
f0101a82:	68 27 5b 10 f0       	push   $0xf0105b27
f0101a87:	e8 b4 e5 ff ff       	call   f0100040 <_panic>
f0101a8c:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101a91:	89 45 e0             	mov    %eax,-0x20(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101a94:	83 ec 04             	sub    $0x4,%esp
f0101a97:	6a 00                	push   $0x0
f0101a99:	68 00 10 00 00       	push   $0x1000
f0101a9e:	52                   	push   %edx
f0101a9f:	e8 a7 f2 ff ff       	call   f0100d4b <pgdir_walk>
f0101aa4:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0101aa7:	8d 51 04             	lea    0x4(%ecx),%edx
f0101aaa:	83 c4 10             	add    $0x10,%esp
f0101aad:	39 d0                	cmp    %edx,%eax
f0101aaf:	74 19                	je     f0101aca <mem_init+0xb83>
f0101ab1:	68 28 58 10 f0       	push   $0xf0105828
f0101ab6:	68 4e 5b 10 f0       	push   $0xf0105b4e
f0101abb:	68 b9 03 00 00       	push   $0x3b9
f0101ac0:	68 27 5b 10 f0       	push   $0xf0105b27
f0101ac5:	e8 76 e5 ff ff       	call   f0100040 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101aca:	6a 06                	push   $0x6
f0101acc:	68 00 10 00 00       	push   $0x1000
f0101ad1:	57                   	push   %edi
f0101ad2:	ff 35 0c 8f 22 f0    	pushl  0xf0228f0c
f0101ad8:	e8 d8 f3 ff ff       	call   f0100eb5 <page_insert>
f0101add:	83 c4 10             	add    $0x10,%esp
f0101ae0:	85 c0                	test   %eax,%eax
f0101ae2:	74 19                	je     f0101afd <mem_init+0xbb6>
f0101ae4:	68 68 58 10 f0       	push   $0xf0105868
f0101ae9:	68 4e 5b 10 f0       	push   $0xf0105b4e
f0101aee:	68 bc 03 00 00       	push   $0x3bc
f0101af3:	68 27 5b 10 f0       	push   $0xf0105b27
f0101af8:	e8 43 e5 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101afd:	a1 0c 8f 22 f0       	mov    0xf0228f0c,%eax
f0101b02:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101b05:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101b0a:	e8 85 ef ff ff       	call   f0100a94 <check_va2pa>
f0101b0f:	89 fa                	mov    %edi,%edx
f0101b11:	2b 15 10 8f 22 f0    	sub    0xf0228f10,%edx
f0101b17:	c1 fa 03             	sar    $0x3,%edx
f0101b1a:	c1 e2 0c             	shl    $0xc,%edx
f0101b1d:	39 d0                	cmp    %edx,%eax
f0101b1f:	74 19                	je     f0101b3a <mem_init+0xbf3>
f0101b21:	68 f8 57 10 f0       	push   $0xf01057f8
f0101b26:	68 4e 5b 10 f0       	push   $0xf0105b4e
f0101b2b:	68 bd 03 00 00       	push   $0x3bd
f0101b30:	68 27 5b 10 f0       	push   $0xf0105b27
f0101b35:	e8 06 e5 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101b3a:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0101b3f:	74 19                	je     f0101b5a <mem_init+0xc13>
f0101b41:	68 35 5d 10 f0       	push   $0xf0105d35
f0101b46:	68 4e 5b 10 f0       	push   $0xf0105b4e
f0101b4b:	68 be 03 00 00       	push   $0x3be
f0101b50:	68 27 5b 10 f0       	push   $0xf0105b27
f0101b55:	e8 e6 e4 ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101b5a:	83 ec 04             	sub    $0x4,%esp
f0101b5d:	6a 00                	push   $0x0
f0101b5f:	68 00 10 00 00       	push   $0x1000
f0101b64:	ff 75 d0             	pushl  -0x30(%ebp)
f0101b67:	e8 df f1 ff ff       	call   f0100d4b <pgdir_walk>
f0101b6c:	83 c4 10             	add    $0x10,%esp
f0101b6f:	f6 00 04             	testb  $0x4,(%eax)
f0101b72:	75 19                	jne    f0101b8d <mem_init+0xc46>
f0101b74:	68 a8 58 10 f0       	push   $0xf01058a8
f0101b79:	68 4e 5b 10 f0       	push   $0xf0105b4e
f0101b7e:	68 bf 03 00 00       	push   $0x3bf
f0101b83:	68 27 5b 10 f0       	push   $0xf0105b27
f0101b88:	e8 b3 e4 ff ff       	call   f0100040 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101b8d:	a1 0c 8f 22 f0       	mov    0xf0228f0c,%eax
f0101b92:	f6 00 04             	testb  $0x4,(%eax)
f0101b95:	75 19                	jne    f0101bb0 <mem_init+0xc69>
f0101b97:	68 46 5d 10 f0       	push   $0xf0105d46
f0101b9c:	68 4e 5b 10 f0       	push   $0xf0105b4e
f0101ba1:	68 c0 03 00 00       	push   $0x3c0
f0101ba6:	68 27 5b 10 f0       	push   $0xf0105b27
f0101bab:	e8 90 e4 ff ff       	call   f0100040 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101bb0:	6a 02                	push   $0x2
f0101bb2:	68 00 10 00 00       	push   $0x1000
f0101bb7:	57                   	push   %edi
f0101bb8:	50                   	push   %eax
f0101bb9:	e8 f7 f2 ff ff       	call   f0100eb5 <page_insert>
f0101bbe:	83 c4 10             	add    $0x10,%esp
f0101bc1:	85 c0                	test   %eax,%eax
f0101bc3:	74 19                	je     f0101bde <mem_init+0xc97>
f0101bc5:	68 bc 57 10 f0       	push   $0xf01057bc
f0101bca:	68 4e 5b 10 f0       	push   $0xf0105b4e
f0101bcf:	68 c3 03 00 00       	push   $0x3c3
f0101bd4:	68 27 5b 10 f0       	push   $0xf0105b27
f0101bd9:	e8 62 e4 ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101bde:	83 ec 04             	sub    $0x4,%esp
f0101be1:	6a 00                	push   $0x0
f0101be3:	68 00 10 00 00       	push   $0x1000
f0101be8:	ff 35 0c 8f 22 f0    	pushl  0xf0228f0c
f0101bee:	e8 58 f1 ff ff       	call   f0100d4b <pgdir_walk>
f0101bf3:	83 c4 10             	add    $0x10,%esp
f0101bf6:	f6 00 02             	testb  $0x2,(%eax)
f0101bf9:	75 19                	jne    f0101c14 <mem_init+0xccd>
f0101bfb:	68 dc 58 10 f0       	push   $0xf01058dc
f0101c00:	68 4e 5b 10 f0       	push   $0xf0105b4e
f0101c05:	68 c4 03 00 00       	push   $0x3c4
f0101c0a:	68 27 5b 10 f0       	push   $0xf0105b27
f0101c0f:	e8 2c e4 ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101c14:	83 ec 04             	sub    $0x4,%esp
f0101c17:	6a 00                	push   $0x0
f0101c19:	68 00 10 00 00       	push   $0x1000
f0101c1e:	ff 35 0c 8f 22 f0    	pushl  0xf0228f0c
f0101c24:	e8 22 f1 ff ff       	call   f0100d4b <pgdir_walk>
f0101c29:	83 c4 10             	add    $0x10,%esp
f0101c2c:	f6 00 04             	testb  $0x4,(%eax)
f0101c2f:	74 19                	je     f0101c4a <mem_init+0xd03>
f0101c31:	68 10 59 10 f0       	push   $0xf0105910
f0101c36:	68 4e 5b 10 f0       	push   $0xf0105b4e
f0101c3b:	68 c5 03 00 00       	push   $0x3c5
f0101c40:	68 27 5b 10 f0       	push   $0xf0105b27
f0101c45:	e8 f6 e3 ff ff       	call   f0100040 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101c4a:	6a 02                	push   $0x2
f0101c4c:	68 00 00 40 00       	push   $0x400000
f0101c51:	53                   	push   %ebx
f0101c52:	ff 35 0c 8f 22 f0    	pushl  0xf0228f0c
f0101c58:	e8 58 f2 ff ff       	call   f0100eb5 <page_insert>
f0101c5d:	83 c4 10             	add    $0x10,%esp
f0101c60:	85 c0                	test   %eax,%eax
f0101c62:	78 19                	js     f0101c7d <mem_init+0xd36>
f0101c64:	68 48 59 10 f0       	push   $0xf0105948
f0101c69:	68 4e 5b 10 f0       	push   $0xf0105b4e
f0101c6e:	68 c8 03 00 00       	push   $0x3c8
f0101c73:	68 27 5b 10 f0       	push   $0xf0105b27
f0101c78:	e8 c3 e3 ff ff       	call   f0100040 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101c7d:	6a 02                	push   $0x2
f0101c7f:	68 00 10 00 00       	push   $0x1000
f0101c84:	56                   	push   %esi
f0101c85:	ff 35 0c 8f 22 f0    	pushl  0xf0228f0c
f0101c8b:	e8 25 f2 ff ff       	call   f0100eb5 <page_insert>
f0101c90:	83 c4 10             	add    $0x10,%esp
f0101c93:	85 c0                	test   %eax,%eax
f0101c95:	74 19                	je     f0101cb0 <mem_init+0xd69>
f0101c97:	68 80 59 10 f0       	push   $0xf0105980
f0101c9c:	68 4e 5b 10 f0       	push   $0xf0105b4e
f0101ca1:	68 cb 03 00 00       	push   $0x3cb
f0101ca6:	68 27 5b 10 f0       	push   $0xf0105b27
f0101cab:	e8 90 e3 ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101cb0:	83 ec 04             	sub    $0x4,%esp
f0101cb3:	6a 00                	push   $0x0
f0101cb5:	68 00 10 00 00       	push   $0x1000
f0101cba:	ff 35 0c 8f 22 f0    	pushl  0xf0228f0c
f0101cc0:	e8 86 f0 ff ff       	call   f0100d4b <pgdir_walk>
f0101cc5:	83 c4 10             	add    $0x10,%esp
f0101cc8:	f6 00 04             	testb  $0x4,(%eax)
f0101ccb:	74 19                	je     f0101ce6 <mem_init+0xd9f>
f0101ccd:	68 10 59 10 f0       	push   $0xf0105910
f0101cd2:	68 4e 5b 10 f0       	push   $0xf0105b4e
f0101cd7:	68 cc 03 00 00       	push   $0x3cc
f0101cdc:	68 27 5b 10 f0       	push   $0xf0105b27
f0101ce1:	e8 5a e3 ff ff       	call   f0100040 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101ce6:	a1 0c 8f 22 f0       	mov    0xf0228f0c,%eax
f0101ceb:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101cee:	ba 00 00 00 00       	mov    $0x0,%edx
f0101cf3:	e8 9c ed ff ff       	call   f0100a94 <check_va2pa>
f0101cf8:	89 c1                	mov    %eax,%ecx
f0101cfa:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101cfd:	89 f0                	mov    %esi,%eax
f0101cff:	2b 05 10 8f 22 f0    	sub    0xf0228f10,%eax
f0101d05:	c1 f8 03             	sar    $0x3,%eax
f0101d08:	c1 e0 0c             	shl    $0xc,%eax
f0101d0b:	39 c1                	cmp    %eax,%ecx
f0101d0d:	74 19                	je     f0101d28 <mem_init+0xde1>
f0101d0f:	68 bc 59 10 f0       	push   $0xf01059bc
f0101d14:	68 4e 5b 10 f0       	push   $0xf0105b4e
f0101d19:	68 cf 03 00 00       	push   $0x3cf
f0101d1e:	68 27 5b 10 f0       	push   $0xf0105b27
f0101d23:	e8 18 e3 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101d28:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101d2d:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101d30:	e8 5f ed ff ff       	call   f0100a94 <check_va2pa>
f0101d35:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101d38:	74 19                	je     f0101d53 <mem_init+0xe0c>
f0101d3a:	68 e8 59 10 f0       	push   $0xf01059e8
f0101d3f:	68 4e 5b 10 f0       	push   $0xf0105b4e
f0101d44:	68 d0 03 00 00       	push   $0x3d0
f0101d49:	68 27 5b 10 f0       	push   $0xf0105b27
f0101d4e:	e8 ed e2 ff ff       	call   f0100040 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101d53:	66 83 7e 04 02       	cmpw   $0x2,0x4(%esi)
f0101d58:	74 19                	je     f0101d73 <mem_init+0xe2c>
f0101d5a:	68 5c 5d 10 f0       	push   $0xf0105d5c
f0101d5f:	68 4e 5b 10 f0       	push   $0xf0105b4e
f0101d64:	68 d2 03 00 00       	push   $0x3d2
f0101d69:	68 27 5b 10 f0       	push   $0xf0105b27
f0101d6e:	e8 cd e2 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f0101d73:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0101d78:	74 19                	je     f0101d93 <mem_init+0xe4c>
f0101d7a:	68 6d 5d 10 f0       	push   $0xf0105d6d
f0101d7f:	68 4e 5b 10 f0       	push   $0xf0105b4e
f0101d84:	68 d3 03 00 00       	push   $0x3d3
f0101d89:	68 27 5b 10 f0       	push   $0xf0105b27
f0101d8e:	e8 ad e2 ff ff       	call   f0100040 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101d93:	83 ec 0c             	sub    $0xc,%esp
f0101d96:	6a 00                	push   $0x0
f0101d98:	e8 d5 ee ff ff       	call   f0100c72 <page_alloc>
f0101d9d:	83 c4 10             	add    $0x10,%esp
f0101da0:	39 c7                	cmp    %eax,%edi
f0101da2:	75 04                	jne    f0101da8 <mem_init+0xe61>
f0101da4:	85 c0                	test   %eax,%eax
f0101da6:	75 19                	jne    f0101dc1 <mem_init+0xe7a>
f0101da8:	68 18 5a 10 f0       	push   $0xf0105a18
f0101dad:	68 4e 5b 10 f0       	push   $0xf0105b4e
f0101db2:	68 d6 03 00 00       	push   $0x3d6
f0101db7:	68 27 5b 10 f0       	push   $0xf0105b27
f0101dbc:	e8 7f e2 ff ff       	call   f0100040 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101dc1:	83 ec 08             	sub    $0x8,%esp
f0101dc4:	6a 00                	push   $0x0
f0101dc6:	ff 35 0c 8f 22 f0    	pushl  0xf0228f0c
f0101dcc:	e8 9e f0 ff ff       	call   f0100e6f <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101dd1:	a1 0c 8f 22 f0       	mov    0xf0228f0c,%eax
f0101dd6:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101dd9:	ba 00 00 00 00       	mov    $0x0,%edx
f0101dde:	e8 b1 ec ff ff       	call   f0100a94 <check_va2pa>
f0101de3:	83 c4 10             	add    $0x10,%esp
f0101de6:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101de9:	74 19                	je     f0101e04 <mem_init+0xebd>
f0101deb:	68 3c 5a 10 f0       	push   $0xf0105a3c
f0101df0:	68 4e 5b 10 f0       	push   $0xf0105b4e
f0101df5:	68 da 03 00 00       	push   $0x3da
f0101dfa:	68 27 5b 10 f0       	push   $0xf0105b27
f0101dff:	e8 3c e2 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101e04:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e09:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101e0c:	e8 83 ec ff ff       	call   f0100a94 <check_va2pa>
f0101e11:	89 f2                	mov    %esi,%edx
f0101e13:	2b 15 10 8f 22 f0    	sub    0xf0228f10,%edx
f0101e19:	c1 fa 03             	sar    $0x3,%edx
f0101e1c:	c1 e2 0c             	shl    $0xc,%edx
f0101e1f:	39 d0                	cmp    %edx,%eax
f0101e21:	74 19                	je     f0101e3c <mem_init+0xef5>
f0101e23:	68 e8 59 10 f0       	push   $0xf01059e8
f0101e28:	68 4e 5b 10 f0       	push   $0xf0105b4e
f0101e2d:	68 db 03 00 00       	push   $0x3db
f0101e32:	68 27 5b 10 f0       	push   $0xf0105b27
f0101e37:	e8 04 e2 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f0101e3c:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101e41:	74 19                	je     f0101e5c <mem_init+0xf15>
f0101e43:	68 13 5d 10 f0       	push   $0xf0105d13
f0101e48:	68 4e 5b 10 f0       	push   $0xf0105b4e
f0101e4d:	68 dc 03 00 00       	push   $0x3dc
f0101e52:	68 27 5b 10 f0       	push   $0xf0105b27
f0101e57:	e8 e4 e1 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f0101e5c:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0101e61:	74 19                	je     f0101e7c <mem_init+0xf35>
f0101e63:	68 6d 5d 10 f0       	push   $0xf0105d6d
f0101e68:	68 4e 5b 10 f0       	push   $0xf0105b4e
f0101e6d:	68 dd 03 00 00       	push   $0x3dd
f0101e72:	68 27 5b 10 f0       	push   $0xf0105b27
f0101e77:	e8 c4 e1 ff ff       	call   f0100040 <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101e7c:	6a 00                	push   $0x0
f0101e7e:	68 00 10 00 00       	push   $0x1000
f0101e83:	56                   	push   %esi
f0101e84:	ff 75 d0             	pushl  -0x30(%ebp)
f0101e87:	e8 29 f0 ff ff       	call   f0100eb5 <page_insert>
f0101e8c:	83 c4 10             	add    $0x10,%esp
f0101e8f:	85 c0                	test   %eax,%eax
f0101e91:	74 19                	je     f0101eac <mem_init+0xf65>
f0101e93:	68 60 5a 10 f0       	push   $0xf0105a60
f0101e98:	68 4e 5b 10 f0       	push   $0xf0105b4e
f0101e9d:	68 e0 03 00 00       	push   $0x3e0
f0101ea2:	68 27 5b 10 f0       	push   $0xf0105b27
f0101ea7:	e8 94 e1 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref);
f0101eac:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101eb1:	75 19                	jne    f0101ecc <mem_init+0xf85>
f0101eb3:	68 7e 5d 10 f0       	push   $0xf0105d7e
f0101eb8:	68 4e 5b 10 f0       	push   $0xf0105b4e
f0101ebd:	68 e1 03 00 00       	push   $0x3e1
f0101ec2:	68 27 5b 10 f0       	push   $0xf0105b27
f0101ec7:	e8 74 e1 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_link == NULL);
f0101ecc:	83 3e 00             	cmpl   $0x0,(%esi)
f0101ecf:	74 19                	je     f0101eea <mem_init+0xfa3>
f0101ed1:	68 8a 5d 10 f0       	push   $0xf0105d8a
f0101ed6:	68 4e 5b 10 f0       	push   $0xf0105b4e
f0101edb:	68 e2 03 00 00       	push   $0x3e2
f0101ee0:	68 27 5b 10 f0       	push   $0xf0105b27
f0101ee5:	e8 56 e1 ff ff       	call   f0100040 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101eea:	83 ec 08             	sub    $0x8,%esp
f0101eed:	68 00 10 00 00       	push   $0x1000
f0101ef2:	ff 35 0c 8f 22 f0    	pushl  0xf0228f0c
f0101ef8:	e8 72 ef ff ff       	call   f0100e6f <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101efd:	a1 0c 8f 22 f0       	mov    0xf0228f0c,%eax
f0101f02:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101f05:	ba 00 00 00 00       	mov    $0x0,%edx
f0101f0a:	e8 85 eb ff ff       	call   f0100a94 <check_va2pa>
f0101f0f:	83 c4 10             	add    $0x10,%esp
f0101f12:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101f15:	74 19                	je     f0101f30 <mem_init+0xfe9>
f0101f17:	68 3c 5a 10 f0       	push   $0xf0105a3c
f0101f1c:	68 4e 5b 10 f0       	push   $0xf0105b4e
f0101f21:	68 e6 03 00 00       	push   $0x3e6
f0101f26:	68 27 5b 10 f0       	push   $0xf0105b27
f0101f2b:	e8 10 e1 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101f30:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101f35:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101f38:	e8 57 eb ff ff       	call   f0100a94 <check_va2pa>
f0101f3d:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101f40:	74 19                	je     f0101f5b <mem_init+0x1014>
f0101f42:	68 98 5a 10 f0       	push   $0xf0105a98
f0101f47:	68 4e 5b 10 f0       	push   $0xf0105b4e
f0101f4c:	68 e7 03 00 00       	push   $0x3e7
f0101f51:	68 27 5b 10 f0       	push   $0xf0105b27
f0101f56:	e8 e5 e0 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f0101f5b:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101f60:	74 19                	je     f0101f7b <mem_init+0x1034>
f0101f62:	68 9f 5d 10 f0       	push   $0xf0105d9f
f0101f67:	68 4e 5b 10 f0       	push   $0xf0105b4e
f0101f6c:	68 e8 03 00 00       	push   $0x3e8
f0101f71:	68 27 5b 10 f0       	push   $0xf0105b27
f0101f76:	e8 c5 e0 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f0101f7b:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0101f80:	74 19                	je     f0101f9b <mem_init+0x1054>
f0101f82:	68 6d 5d 10 f0       	push   $0xf0105d6d
f0101f87:	68 4e 5b 10 f0       	push   $0xf0105b4e
f0101f8c:	68 e9 03 00 00       	push   $0x3e9
f0101f91:	68 27 5b 10 f0       	push   $0xf0105b27
f0101f96:	e8 a5 e0 ff ff       	call   f0100040 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101f9b:	83 ec 0c             	sub    $0xc,%esp
f0101f9e:	6a 00                	push   $0x0
f0101fa0:	e8 cd ec ff ff       	call   f0100c72 <page_alloc>
f0101fa5:	83 c4 10             	add    $0x10,%esp
f0101fa8:	39 c6                	cmp    %eax,%esi
f0101faa:	75 04                	jne    f0101fb0 <mem_init+0x1069>
f0101fac:	85 c0                	test   %eax,%eax
f0101fae:	75 19                	jne    f0101fc9 <mem_init+0x1082>
f0101fb0:	68 c0 5a 10 f0       	push   $0xf0105ac0
f0101fb5:	68 4e 5b 10 f0       	push   $0xf0105b4e
f0101fba:	68 ec 03 00 00       	push   $0x3ec
f0101fbf:	68 27 5b 10 f0       	push   $0xf0105b27
f0101fc4:	e8 77 e0 ff ff       	call   f0100040 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101fc9:	83 ec 0c             	sub    $0xc,%esp
f0101fcc:	6a 00                	push   $0x0
f0101fce:	e8 9f ec ff ff       	call   f0100c72 <page_alloc>
f0101fd3:	83 c4 10             	add    $0x10,%esp
f0101fd6:	85 c0                	test   %eax,%eax
f0101fd8:	74 19                	je     f0101ff3 <mem_init+0x10ac>
f0101fda:	68 c1 5c 10 f0       	push   $0xf0105cc1
f0101fdf:	68 4e 5b 10 f0       	push   $0xf0105b4e
f0101fe4:	68 ef 03 00 00       	push   $0x3ef
f0101fe9:	68 27 5b 10 f0       	push   $0xf0105b27
f0101fee:	e8 4d e0 ff ff       	call   f0100040 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101ff3:	8b 0d 0c 8f 22 f0    	mov    0xf0228f0c,%ecx
f0101ff9:	8b 11                	mov    (%ecx),%edx
f0101ffb:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102001:	89 d8                	mov    %ebx,%eax
f0102003:	2b 05 10 8f 22 f0    	sub    0xf0228f10,%eax
f0102009:	c1 f8 03             	sar    $0x3,%eax
f010200c:	c1 e0 0c             	shl    $0xc,%eax
f010200f:	39 c2                	cmp    %eax,%edx
f0102011:	74 19                	je     f010202c <mem_init+0x10e5>
f0102013:	68 64 57 10 f0       	push   $0xf0105764
f0102018:	68 4e 5b 10 f0       	push   $0xf0105b4e
f010201d:	68 f2 03 00 00       	push   $0x3f2
f0102022:	68 27 5b 10 f0       	push   $0xf0105b27
f0102027:	e8 14 e0 ff ff       	call   f0100040 <_panic>
	kern_pgdir[0] = 0;
f010202c:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102032:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102037:	74 19                	je     f0102052 <mem_init+0x110b>
f0102039:	68 24 5d 10 f0       	push   $0xf0105d24
f010203e:	68 4e 5b 10 f0       	push   $0xf0105b4e
f0102043:	68 f4 03 00 00       	push   $0x3f4
f0102048:	68 27 5b 10 f0       	push   $0xf0105b27
f010204d:	e8 ee df ff ff       	call   f0100040 <_panic>
	pp0->pp_ref = 0;
f0102052:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0102058:	83 ec 0c             	sub    $0xc,%esp
f010205b:	53                   	push   %ebx
f010205c:	e8 88 ec ff ff       	call   f0100ce9 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0102061:	83 c4 0c             	add    $0xc,%esp
f0102064:	6a 01                	push   $0x1
f0102066:	68 00 10 40 00       	push   $0x401000
f010206b:	ff 35 0c 8f 22 f0    	pushl  0xf0228f0c
f0102071:	e8 d5 ec ff ff       	call   f0100d4b <pgdir_walk>
f0102076:	89 c1                	mov    %eax,%ecx
f0102078:	89 45 e0             	mov    %eax,-0x20(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f010207b:	a1 0c 8f 22 f0       	mov    0xf0228f0c,%eax
f0102080:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102083:	8b 40 04             	mov    0x4(%eax),%eax
f0102086:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010208b:	89 c2                	mov    %eax,%edx
f010208d:	c1 ea 0c             	shr    $0xc,%edx
f0102090:	83 c4 10             	add    $0x10,%esp
f0102093:	3b 15 08 8f 22 f0    	cmp    0xf0228f08,%edx
f0102099:	72 15                	jb     f01020b0 <mem_init+0x1169>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010209b:	50                   	push   %eax
f010209c:	68 a4 4f 10 f0       	push   $0xf0104fa4
f01020a1:	68 fb 03 00 00       	push   $0x3fb
f01020a6:	68 27 5b 10 f0       	push   $0xf0105b27
f01020ab:	e8 90 df ff ff       	call   f0100040 <_panic>
	assert(ptep == ptep1 + PTX(va));
f01020b0:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f01020b5:	39 c1                	cmp    %eax,%ecx
f01020b7:	74 19                	je     f01020d2 <mem_init+0x118b>
f01020b9:	68 b0 5d 10 f0       	push   $0xf0105db0
f01020be:	68 4e 5b 10 f0       	push   $0xf0105b4e
f01020c3:	68 fc 03 00 00       	push   $0x3fc
f01020c8:	68 27 5b 10 f0       	push   $0xf0105b27
f01020cd:	e8 6e df ff ff       	call   f0100040 <_panic>
	kern_pgdir[PDX(va)] = 0;
f01020d2:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01020d5:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f01020dc:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f01020e2:	89 d8                	mov    %ebx,%eax
f01020e4:	e8 74 e9 ff ff       	call   f0100a5d <page2kva>
f01020e9:	83 ec 04             	sub    $0x4,%esp
f01020ec:	68 00 10 00 00       	push   $0x1000
f01020f1:	68 ff 00 00 00       	push   $0xff
f01020f6:	50                   	push   %eax
f01020f7:	e8 ca 21 00 00       	call   f01042c6 <memset>
	page_free(pp0);
f01020fc:	89 1c 24             	mov    %ebx,(%esp)
f01020ff:	e8 e5 eb ff ff       	call   f0100ce9 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0102104:	83 c4 0c             	add    $0xc,%esp
f0102107:	6a 01                	push   $0x1
f0102109:	6a 00                	push   $0x0
f010210b:	ff 35 0c 8f 22 f0    	pushl  0xf0228f0c
f0102111:	e8 35 ec ff ff       	call   f0100d4b <pgdir_walk>
	ptep = (pte_t *) page2kva(pp0);
f0102116:	89 d8                	mov    %ebx,%eax
f0102118:	e8 40 e9 ff ff       	call   f0100a5d <page2kva>
f010211d:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102120:	83 c4 10             	add    $0x10,%esp
	for(i=0; i<NPTENTRIES; i++)
f0102123:	ba 00 00 00 00       	mov    $0x0,%edx
		assert((ptep[i] & PTE_P) == 0);
f0102128:	f6 04 90 01          	testb  $0x1,(%eax,%edx,4)
f010212c:	74 19                	je     f0102147 <mem_init+0x1200>
f010212e:	68 c8 5d 10 f0       	push   $0xf0105dc8
f0102133:	68 4e 5b 10 f0       	push   $0xf0105b4e
f0102138:	68 06 04 00 00       	push   $0x406
f010213d:	68 27 5b 10 f0       	push   $0xf0105b27
f0102142:	e8 f9 de ff ff       	call   f0100040 <_panic>
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f0102147:	83 c2 01             	add    $0x1,%edx
f010214a:	81 fa 00 04 00 00    	cmp    $0x400,%edx
f0102150:	75 d6                	jne    f0102128 <mem_init+0x11e1>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f0102152:	a1 0c 8f 22 f0       	mov    0xf0228f0c,%eax
f0102157:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f010215d:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// give free list back
	page_free_list = fl;
f0102163:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102166:	a3 40 82 22 f0       	mov    %eax,0xf0228240

	// free the pages we took
	page_free(pp0);
f010216b:	83 ec 0c             	sub    $0xc,%esp
f010216e:	53                   	push   %ebx
f010216f:	e8 75 eb ff ff       	call   f0100ce9 <page_free>
	page_free(pp1);
f0102174:	89 34 24             	mov    %esi,(%esp)
f0102177:	e8 6d eb ff ff       	call   f0100ce9 <page_free>
	page_free(pp2);
f010217c:	89 3c 24             	mov    %edi,(%esp)
f010217f:	e8 65 eb ff ff       	call   f0100ce9 <page_free>

	// test mmio_map_region
	mm1 = (uintptr_t) mmio_map_region(0, 4097);
f0102184:	83 c4 08             	add    $0x8,%esp
f0102187:	68 01 10 00 00       	push   $0x1001
f010218c:	6a 00                	push   $0x0
f010218e:	e8 9a ed ff ff       	call   f0100f2d <mmio_map_region>
		assert(page2pa(pp) != IOPHYSMEM);
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
		assert(page2pa(pp) != EXTPHYSMEM);
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
		// (new test for lab 4)
		assert(page2pa(pp) != MPENTRY_PADDR);
f0102193:	3d 00 70 00 00       	cmp    $0x7000,%eax
f0102198:	0f 85 db f0 ff ff    	jne    f0101279 <mem_init+0x332>
f010219e:	e9 bd f0 ff ff       	jmp    f0101260 <mem_init+0x319>
f01021a3:	3d 00 70 00 00       	cmp    $0x7000,%eax
f01021a8:	0f 85 d0 f0 ff ff    	jne    f010127e <mem_init+0x337>
f01021ae:	e9 ad f0 ff ff       	jmp    f0101260 <mem_init+0x319>

f01021b3 <user_mem_check>:
// Returns 0 if the user program can access this range of addresses,
// and -E_FAULT otherwise.
//
int
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
f01021b3:	55                   	push   %ebp
f01021b4:	89 e5                	mov    %esp,%ebp
f01021b6:	57                   	push   %edi
f01021b7:	56                   	push   %esi
f01021b8:	53                   	push   %ebx
f01021b9:	83 ec 2c             	sub    $0x2c,%esp
f01021bc:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// LAB 3: Your code here.
	void *vat =(void *) va;
	void *end =(void *)va + len;
f01021bf:	89 d8                	mov    %ebx,%eax
f01021c1:	03 45 10             	add    0x10(%ebp),%eax
f01021c4:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	int p = perm | PTE_P;
f01021c7:	8b 75 14             	mov    0x14(%ebp),%esi
f01021ca:	83 ce 01             	or     $0x1,%esi
	for (; vat < end; vat = ROUNDDOWN(vat+PGSIZE, PGSIZE)) {
		if ((uint32_t)vat > ULIM) {
			user_mem_check_addr =(uintptr_t) vat;
			return -E_FAULT;
		}
		page_lookup(env->env_pgdir, vat, &pte);
f01021cd:	8d 7d e4             	lea    -0x1c(%ebp),%edi
	// LAB 3: Your code here.
	void *vat =(void *) va;
	void *end =(void *)va + len;
	int p = perm | PTE_P;
	pte_t *pte;
	for (; vat < end; vat = ROUNDDOWN(vat+PGSIZE, PGSIZE)) {
f01021d0:	eb 55                	jmp    f0102227 <user_mem_check+0x74>
		if ((uint32_t)vat > ULIM) {
f01021d2:	89 5d d0             	mov    %ebx,-0x30(%ebp)
f01021d5:	81 fb 00 00 80 ef    	cmp    $0xef800000,%ebx
f01021db:	76 0d                	jbe    f01021ea <user_mem_check+0x37>
			user_mem_check_addr =(uintptr_t) vat;
f01021dd:	89 1d 3c 82 22 f0    	mov    %ebx,0xf022823c
			return -E_FAULT;
f01021e3:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f01021e8:	eb 47                	jmp    f0102231 <user_mem_check+0x7e>
		}
		page_lookup(env->env_pgdir, vat, &pte);
f01021ea:	83 ec 04             	sub    $0x4,%esp
f01021ed:	57                   	push   %edi
f01021ee:	53                   	push   %ebx
f01021ef:	8b 45 08             	mov    0x8(%ebp),%eax
f01021f2:	ff 70 60             	pushl  0x60(%eax)
f01021f5:	e8 e6 eb ff ff       	call   f0100de0 <page_lookup>
		if (!(pte && ((*pte & p) == p))) {
f01021fa:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01021fd:	83 c4 10             	add    $0x10,%esp
f0102200:	85 c0                	test   %eax,%eax
f0102202:	74 08                	je     f010220c <user_mem_check+0x59>
f0102204:	89 f2                	mov    %esi,%edx
f0102206:	23 10                	and    (%eax),%edx
f0102208:	39 d6                	cmp    %edx,%esi
f010220a:	74 0f                	je     f010221b <user_mem_check+0x68>
			user_mem_check_addr = (uintptr_t) vat;
f010220c:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010220f:	a3 3c 82 22 f0       	mov    %eax,0xf022823c
			return -E_FAULT;
f0102214:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0102219:	eb 16                	jmp    f0102231 <user_mem_check+0x7e>
	// LAB 3: Your code here.
	void *vat =(void *) va;
	void *end =(void *)va + len;
	int p = perm | PTE_P;
	pte_t *pte;
	for (; vat < end; vat = ROUNDDOWN(vat+PGSIZE, PGSIZE)) {
f010221b:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102221:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
f0102227:	3b 5d d4             	cmp    -0x2c(%ebp),%ebx
f010222a:	72 a6                	jb     f01021d2 <user_mem_check+0x1f>
			user_mem_check_addr = (uintptr_t) vat;
			return -E_FAULT;
		}
	}

	return 0;
f010222c:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102231:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102234:	5b                   	pop    %ebx
f0102235:	5e                   	pop    %esi
f0102236:	5f                   	pop    %edi
f0102237:	5d                   	pop    %ebp
f0102238:	c3                   	ret    

f0102239 <user_mem_assert>:
// If it cannot, 'env' is destroyed and, if env is the current
// environment, this function will not return.
//
void
user_mem_assert(struct Env *env, const void *va, size_t len, int perm)
{
f0102239:	55                   	push   %ebp
f010223a:	89 e5                	mov    %esp,%ebp
f010223c:	53                   	push   %ebx
f010223d:	83 ec 04             	sub    $0x4,%esp
f0102240:	8b 5d 08             	mov    0x8(%ebp),%ebx
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
f0102243:	8b 45 14             	mov    0x14(%ebp),%eax
f0102246:	83 c8 04             	or     $0x4,%eax
f0102249:	50                   	push   %eax
f010224a:	ff 75 10             	pushl  0x10(%ebp)
f010224d:	ff 75 0c             	pushl  0xc(%ebp)
f0102250:	53                   	push   %ebx
f0102251:	e8 5d ff ff ff       	call   f01021b3 <user_mem_check>
f0102256:	83 c4 10             	add    $0x10,%esp
f0102259:	85 c0                	test   %eax,%eax
f010225b:	79 21                	jns    f010227e <user_mem_assert+0x45>
		cprintf("[%08x] user_mem_check assertion failure for "
f010225d:	83 ec 04             	sub    $0x4,%esp
f0102260:	ff 35 3c 82 22 f0    	pushl  0xf022823c
f0102266:	ff 73 48             	pushl  0x48(%ebx)
f0102269:	68 e4 5a 10 f0       	push   $0xf0105ae4
f010226e:	e8 ca 08 00 00       	call   f0102b3d <cprintf>
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
f0102273:	89 1c 24             	mov    %ebx,(%esp)
f0102276:	e8 fb 05 00 00       	call   f0102876 <env_destroy>
f010227b:	83 c4 10             	add    $0x10,%esp
	}
}
f010227e:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102281:	c9                   	leave  
f0102282:	c3                   	ret    

f0102283 <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f0102283:	55                   	push   %ebp
f0102284:	89 e5                	mov    %esp,%ebp
f0102286:	57                   	push   %edi
f0102287:	56                   	push   %esi
f0102288:	53                   	push   %ebx
f0102289:	83 ec 0c             	sub    $0xc,%esp
f010228c:	89 c7                	mov    %eax,%edi
	//
	// Hint: It is easier to use region_alloc if the caller can pass
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	void *va_t = ROUNDDOWN(va, PGSIZE);
f010228e:	89 d3                	mov    %edx,%ebx
f0102290:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx

	void *end = ROUNDUP(va + len, PGSIZE);
f0102296:	8d b4 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%esi
f010229d:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	for(; va_t < end;va_t += PGSIZE){
f01022a3:	eb 3d                	jmp    f01022e2 <region_alloc+0x5f>
		struct PageInfo *pp = page_alloc(1);	
f01022a5:	83 ec 0c             	sub    $0xc,%esp
f01022a8:	6a 01                	push   $0x1
f01022aa:	e8 c3 e9 ff ff       	call   f0100c72 <page_alloc>
		if(pp == NULL){
f01022af:	83 c4 10             	add    $0x10,%esp
f01022b2:	85 c0                	test   %eax,%eax
f01022b4:	75 17                	jne    f01022cd <region_alloc+0x4a>
			panic("page alloc failed!\n");	
f01022b6:	83 ec 04             	sub    $0x4,%esp
f01022b9:	68 df 5d 10 f0       	push   $0xf0105ddf
f01022be:	68 29 01 00 00       	push   $0x129
f01022c3:	68 f3 5d 10 f0       	push   $0xf0105df3
f01022c8:	e8 73 dd ff ff       	call   f0100040 <_panic>
		}
		page_insert(e->env_pgdir, pp, va_t, PTE_U | PTE_W);	
f01022cd:	6a 06                	push   $0x6
f01022cf:	53                   	push   %ebx
f01022d0:	50                   	push   %eax
f01022d1:	ff 77 60             	pushl  0x60(%edi)
f01022d4:	e8 dc eb ff ff       	call   f0100eb5 <page_insert>
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	void *va_t = ROUNDDOWN(va, PGSIZE);

	void *end = ROUNDUP(va + len, PGSIZE);
	for(; va_t < end;va_t += PGSIZE){
f01022d9:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01022df:	83 c4 10             	add    $0x10,%esp
f01022e2:	39 f3                	cmp    %esi,%ebx
f01022e4:	72 bf                	jb     f01022a5 <region_alloc+0x22>
		if(pp == NULL){
			panic("page alloc failed!\n");	
		}
		page_insert(e->env_pgdir, pp, va_t, PTE_U | PTE_W);	
	}
}
f01022e6:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01022e9:	5b                   	pop    %ebx
f01022ea:	5e                   	pop    %esi
f01022eb:	5f                   	pop    %edi
f01022ec:	5d                   	pop    %ebp
f01022ed:	c3                   	ret    

f01022ee <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f01022ee:	55                   	push   %ebp
f01022ef:	89 e5                	mov    %esp,%ebp
f01022f1:	56                   	push   %esi
f01022f2:	53                   	push   %ebx
f01022f3:	8b 45 08             	mov    0x8(%ebp),%eax
f01022f6:	8b 55 10             	mov    0x10(%ebp),%edx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f01022f9:	85 c0                	test   %eax,%eax
f01022fb:	75 1a                	jne    f0102317 <envid2env+0x29>
		*env_store = curenv;
f01022fd:	e8 e4 25 00 00       	call   f01048e6 <cpunum>
f0102302:	6b c0 74             	imul   $0x74,%eax,%eax
f0102305:	8b 80 28 90 22 f0    	mov    -0xfdd6fd8(%eax),%eax
f010230b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010230e:	89 01                	mov    %eax,(%ecx)
		return 0;
f0102310:	b8 00 00 00 00       	mov    $0x0,%eax
f0102315:	eb 70                	jmp    f0102387 <envid2env+0x99>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f0102317:	89 c3                	mov    %eax,%ebx
f0102319:	81 e3 ff 03 00 00    	and    $0x3ff,%ebx
f010231f:	6b db 7c             	imul   $0x7c,%ebx,%ebx
f0102322:	03 1d 44 82 22 f0    	add    0xf0228244,%ebx
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f0102328:	83 7b 54 00          	cmpl   $0x0,0x54(%ebx)
f010232c:	74 05                	je     f0102333 <envid2env+0x45>
f010232e:	3b 43 48             	cmp    0x48(%ebx),%eax
f0102331:	74 10                	je     f0102343 <envid2env+0x55>
		*env_store = 0;
f0102333:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102336:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f010233c:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0102341:	eb 44                	jmp    f0102387 <envid2env+0x99>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f0102343:	84 d2                	test   %dl,%dl
f0102345:	74 36                	je     f010237d <envid2env+0x8f>
f0102347:	e8 9a 25 00 00       	call   f01048e6 <cpunum>
f010234c:	6b c0 74             	imul   $0x74,%eax,%eax
f010234f:	3b 98 28 90 22 f0    	cmp    -0xfdd6fd8(%eax),%ebx
f0102355:	74 26                	je     f010237d <envid2env+0x8f>
f0102357:	8b 73 4c             	mov    0x4c(%ebx),%esi
f010235a:	e8 87 25 00 00       	call   f01048e6 <cpunum>
f010235f:	6b c0 74             	imul   $0x74,%eax,%eax
f0102362:	8b 80 28 90 22 f0    	mov    -0xfdd6fd8(%eax),%eax
f0102368:	3b 70 48             	cmp    0x48(%eax),%esi
f010236b:	74 10                	je     f010237d <envid2env+0x8f>
		*env_store = 0;
f010236d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102370:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0102376:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f010237b:	eb 0a                	jmp    f0102387 <envid2env+0x99>
	}

	*env_store = e;
f010237d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102380:	89 18                	mov    %ebx,(%eax)
	return 0;
f0102382:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102387:	5b                   	pop    %ebx
f0102388:	5e                   	pop    %esi
f0102389:	5d                   	pop    %ebp
f010238a:	c3                   	ret    

f010238b <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f010238b:	55                   	push   %ebp
f010238c:	89 e5                	mov    %esp,%ebp
}

static inline void
lgdt(void *p)
{
	asm volatile("lgdt (%0)" : : "r" (p));
f010238e:	b8 00 d3 11 f0       	mov    $0xf011d300,%eax
f0102393:	0f 01 10             	lgdtl  (%eax)
	lgdt(&gdt_pd);
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" : : "a" (GD_UD|3));
f0102396:	b8 23 00 00 00       	mov    $0x23,%eax
f010239b:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" : : "a" (GD_UD|3));
f010239d:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" : : "a" (GD_KD));
f010239f:	b8 10 00 00 00       	mov    $0x10,%eax
f01023a4:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" : : "a" (GD_KD));
f01023a6:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" : : "a" (GD_KD));
f01023a8:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" : : "i" (GD_KT));
f01023aa:	ea b1 23 10 f0 08 00 	ljmp   $0x8,$0xf01023b1
}

static inline void
lldt(uint16_t sel)
{
	asm volatile("lldt %0" : : "r" (sel));
f01023b1:	b8 00 00 00 00       	mov    $0x0,%eax
f01023b6:	0f 00 d0             	lldt   %ax
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
}
f01023b9:	5d                   	pop    %ebp
f01023ba:	c3                   	ret    

f01023bb <env_init>:
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f01023bb:	55                   	push   %ebp
f01023bc:	89 e5                	mov    %esp,%ebp
f01023be:	56                   	push   %esi
f01023bf:	53                   	push   %ebx
	// Set up envs array
	// LAB 3: Your code here.
	for (int i = NENV - 1; i >= 0; i--) {
		envs[i].env_id = 0;
f01023c0:	8b 35 44 82 22 f0    	mov    0xf0228244,%esi
f01023c6:	8b 15 48 82 22 f0    	mov    0xf0228248,%edx
f01023cc:	8d 86 84 ef 01 00    	lea    0x1ef84(%esi),%eax
f01023d2:	8d 5e 84             	lea    -0x7c(%esi),%ebx
f01023d5:	89 c1                	mov    %eax,%ecx
f01023d7:	c7 40 48 00 00 00 00 	movl   $0x0,0x48(%eax)
		envs[i].env_status = ENV_FREE;
f01023de:	c7 40 54 00 00 00 00 	movl   $0x0,0x54(%eax)
		envs[i].env_link = env_free_list;
f01023e5:	89 50 44             	mov    %edx,0x44(%eax)
f01023e8:	83 e8 7c             	sub    $0x7c,%eax
		env_free_list = &envs[i];
f01023eb:	89 ca                	mov    %ecx,%edx
void
env_init(void)
{
	// Set up envs array
	// LAB 3: Your code here.
	for (int i = NENV - 1; i >= 0; i--) {
f01023ed:	39 d8                	cmp    %ebx,%eax
f01023ef:	75 e4                	jne    f01023d5 <env_init+0x1a>
f01023f1:	89 35 48 82 22 f0    	mov    %esi,0xf0228248
		envs[i].env_link = env_free_list;
		env_free_list = &envs[i];
	}

	// Per-CPU part of the initialization
	env_init_percpu();
f01023f7:	e8 8f ff ff ff       	call   f010238b <env_init_percpu>
}
f01023fc:	5b                   	pop    %ebx
f01023fd:	5e                   	pop    %esi
f01023fe:	5d                   	pop    %ebp
f01023ff:	c3                   	ret    

f0102400 <env_alloc>:
//	-E_NO_FREE_ENV if all NENVS environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f0102400:	55                   	push   %ebp
f0102401:	89 e5                	mov    %esp,%ebp
f0102403:	53                   	push   %ebx
f0102404:	83 ec 04             	sub    $0x4,%esp
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f0102407:	8b 1d 48 82 22 f0    	mov    0xf0228248,%ebx
f010240d:	85 db                	test   %ebx,%ebx
f010240f:	0f 84 67 01 00 00    	je     f010257c <env_alloc+0x17c>
{
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
f0102415:	83 ec 0c             	sub    $0xc,%esp
f0102418:	6a 01                	push   $0x1
f010241a:	e8 53 e8 ff ff       	call   f0100c72 <page_alloc>
f010241f:	83 c4 10             	add    $0x10,%esp
f0102422:	85 c0                	test   %eax,%eax
f0102424:	0f 84 59 01 00 00    	je     f0102583 <env_alloc+0x183>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010242a:	89 c2                	mov    %eax,%edx
f010242c:	2b 15 10 8f 22 f0    	sub    0xf0228f10,%edx
f0102432:	c1 fa 03             	sar    $0x3,%edx
f0102435:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102438:	89 d1                	mov    %edx,%ecx
f010243a:	c1 e9 0c             	shr    $0xc,%ecx
f010243d:	3b 0d 08 8f 22 f0    	cmp    0xf0228f08,%ecx
f0102443:	72 12                	jb     f0102457 <env_alloc+0x57>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102445:	52                   	push   %edx
f0102446:	68 a4 4f 10 f0       	push   $0xf0104fa4
f010244b:	6a 58                	push   $0x58
f010244d:	68 19 5b 10 f0       	push   $0xf0105b19
f0102452:	e8 e9 db ff ff       	call   f0100040 <_panic>
	//	is an exception -- you need to increment env_pgdir's
	//	pp_ref for env_free to work correctly.
	//    - The functions in kern/pmap.h are handy.

	// LAB 3: Your code here.
	e->env_pgdir = page2kva(p);
f0102457:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f010245d:	89 53 60             	mov    %edx,0x60(%ebx)
	p->pp_ref++;
f0102460:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
	memcpy(e->env_pgdir, kern_pgdir, PGSIZE);
f0102465:	83 ec 04             	sub    $0x4,%esp
f0102468:	68 00 10 00 00       	push   $0x1000
f010246d:	ff 35 0c 8f 22 f0    	pushl  0xf0228f0c
f0102473:	ff 73 60             	pushl  0x60(%ebx)
f0102476:	e8 00 1f 00 00       	call   f010437b <memcpy>

	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f010247b:	8b 43 60             	mov    0x60(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010247e:	83 c4 10             	add    $0x10,%esp
f0102481:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102486:	77 15                	ja     f010249d <env_alloc+0x9d>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102488:	50                   	push   %eax
f0102489:	68 c8 4f 10 f0       	push   $0xf0104fc8
f010248e:	68 c5 00 00 00       	push   $0xc5
f0102493:	68 f3 5d 10 f0       	push   $0xf0105df3
f0102498:	e8 a3 db ff ff       	call   f0100040 <_panic>
f010249d:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01024a3:	83 ca 05             	or     $0x5,%edx
f01024a6:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f01024ac:	8b 43 48             	mov    0x48(%ebx),%eax
f01024af:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f01024b4:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f01024b9:	ba 00 10 00 00       	mov    $0x1000,%edx
f01024be:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f01024c1:	89 da                	mov    %ebx,%edx
f01024c3:	2b 15 44 82 22 f0    	sub    0xf0228244,%edx
f01024c9:	c1 fa 02             	sar    $0x2,%edx
f01024cc:	69 d2 df 7b ef bd    	imul   $0xbdef7bdf,%edx,%edx
f01024d2:	09 d0                	or     %edx,%eax
f01024d4:	89 43 48             	mov    %eax,0x48(%ebx)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f01024d7:	8b 45 0c             	mov    0xc(%ebp),%eax
f01024da:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f01024dd:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f01024e4:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f01024eb:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f01024f2:	83 ec 04             	sub    $0x4,%esp
f01024f5:	6a 44                	push   $0x44
f01024f7:	6a 00                	push   $0x0
f01024f9:	53                   	push   %ebx
f01024fa:	e8 c7 1d 00 00       	call   f01042c6 <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f01024ff:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f0102505:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f010250b:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f0102511:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f0102518:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)

	// Enable interrupts while in user mode.
	// LAB 4: Your code here.

	// Clear the page fault handler until user installs one.
	e->env_pgfault_upcall = 0;
f010251e:	c7 43 64 00 00 00 00 	movl   $0x0,0x64(%ebx)

	// Also clear the IPC receiving flag.
	e->env_ipc_recving = 0;
f0102525:	c6 43 68 00          	movb   $0x0,0x68(%ebx)

	// commit the allocation
	env_free_list = e->env_link;
f0102529:	8b 43 44             	mov    0x44(%ebx),%eax
f010252c:	a3 48 82 22 f0       	mov    %eax,0xf0228248
	*newenv_store = e;
f0102531:	8b 45 08             	mov    0x8(%ebp),%eax
f0102534:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0102536:	8b 5b 48             	mov    0x48(%ebx),%ebx
f0102539:	e8 a8 23 00 00       	call   f01048e6 <cpunum>
f010253e:	6b c0 74             	imul   $0x74,%eax,%eax
f0102541:	83 c4 10             	add    $0x10,%esp
f0102544:	ba 00 00 00 00       	mov    $0x0,%edx
f0102549:	83 b8 28 90 22 f0 00 	cmpl   $0x0,-0xfdd6fd8(%eax)
f0102550:	74 11                	je     f0102563 <env_alloc+0x163>
f0102552:	e8 8f 23 00 00       	call   f01048e6 <cpunum>
f0102557:	6b c0 74             	imul   $0x74,%eax,%eax
f010255a:	8b 80 28 90 22 f0    	mov    -0xfdd6fd8(%eax),%eax
f0102560:	8b 50 48             	mov    0x48(%eax),%edx
f0102563:	83 ec 04             	sub    $0x4,%esp
f0102566:	53                   	push   %ebx
f0102567:	52                   	push   %edx
f0102568:	68 fe 5d 10 f0       	push   $0xf0105dfe
f010256d:	e8 cb 05 00 00       	call   f0102b3d <cprintf>
	return 0;
f0102572:	83 c4 10             	add    $0x10,%esp
f0102575:	b8 00 00 00 00       	mov    $0x0,%eax
f010257a:	eb 0c                	jmp    f0102588 <env_alloc+0x188>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f010257c:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f0102581:	eb 05                	jmp    f0102588 <env_alloc+0x188>
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f0102583:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	env_free_list = e->env_link;
	*newenv_store = e;

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f0102588:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010258b:	c9                   	leave  
f010258c:	c3                   	ret    

f010258d <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f010258d:	55                   	push   %ebp
f010258e:	89 e5                	mov    %esp,%ebp
f0102590:	57                   	push   %edi
f0102591:	56                   	push   %esi
f0102592:	53                   	push   %ebx
f0102593:	83 ec 34             	sub    $0x34,%esp
f0102596:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.
	struct Env *e;
	env_alloc(&e, 0);
f0102599:	6a 00                	push   $0x0
f010259b:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010259e:	50                   	push   %eax
f010259f:	e8 5c fe ff ff       	call   f0102400 <env_alloc>
	load_icode(e, binary);
f01025a4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01025a7:	89 45 d4             	mov    %eax,-0x2c(%ebp)

	// LAB 3: Your code here.
	
	struct Elf *elf = (struct Elf *) binary;

	if (elf->e_magic != ELF_MAGIC)
f01025aa:	83 c4 10             	add    $0x10,%esp
f01025ad:	81 3f 7f 45 4c 46    	cmpl   $0x464c457f,(%edi)
f01025b3:	74 17                	je     f01025cc <env_create+0x3f>
		panic("load_icode: not ELF executable.");
f01025b5:	83 ec 04             	sub    $0x4,%esp
f01025b8:	68 38 5e 10 f0       	push   $0xf0105e38
f01025bd:	68 69 01 00 00       	push   $0x169
f01025c2:	68 f3 5d 10 f0       	push   $0xf0105df3
f01025c7:	e8 74 da ff ff       	call   f0100040 <_panic>

	struct Proghdr *ph = (struct Proghdr *) (elf->e_phoff + binary);
f01025cc:	89 fb                	mov    %edi,%ebx
f01025ce:	03 5f 1c             	add    0x1c(%edi),%ebx
	struct Proghdr *eph = ph + elf->e_phnum;
f01025d1:	0f b7 77 2c          	movzwl 0x2c(%edi),%esi
f01025d5:	c1 e6 05             	shl    $0x5,%esi
f01025d8:	01 de                	add    %ebx,%esi

	lcr3(PADDR(e->env_pgdir));
f01025da:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01025dd:	8b 40 60             	mov    0x60(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01025e0:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01025e5:	77 15                	ja     f01025fc <env_create+0x6f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01025e7:	50                   	push   %eax
f01025e8:	68 c8 4f 10 f0       	push   $0xf0104fc8
f01025ed:	68 6e 01 00 00       	push   $0x16e
f01025f2:	68 f3 5d 10 f0       	push   $0xf0105df3
f01025f7:	e8 44 da ff ff       	call   f0100040 <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f01025fc:	05 00 00 00 10       	add    $0x10000000,%eax
f0102601:	0f 22 d8             	mov    %eax,%cr3
f0102604:	eb 3d                	jmp    f0102643 <env_create+0xb6>
	for(; ph < eph; ph++){
		if(ph->p_type == ELF_PROG_LOAD){
f0102606:	83 3b 01             	cmpl   $0x1,(%ebx)
f0102609:	75 35                	jne    f0102640 <env_create+0xb3>
			region_alloc(e, (void *) ph->p_va, ph->p_memsz);
f010260b:	8b 4b 14             	mov    0x14(%ebx),%ecx
f010260e:	8b 53 08             	mov    0x8(%ebx),%edx
f0102611:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102614:	e8 6a fc ff ff       	call   f0102283 <region_alloc>
			memset((void *) ph->p_va, 0, ph->p_memsz);
f0102619:	83 ec 04             	sub    $0x4,%esp
f010261c:	ff 73 14             	pushl  0x14(%ebx)
f010261f:	6a 00                	push   $0x0
f0102621:	ff 73 08             	pushl  0x8(%ebx)
f0102624:	e8 9d 1c 00 00       	call   f01042c6 <memset>
			memcpy((void *) ph->p_va, binary + ph->p_offset, ph->p_filesz);
f0102629:	83 c4 0c             	add    $0xc,%esp
f010262c:	ff 73 10             	pushl  0x10(%ebx)
f010262f:	89 f8                	mov    %edi,%eax
f0102631:	03 43 04             	add    0x4(%ebx),%eax
f0102634:	50                   	push   %eax
f0102635:	ff 73 08             	pushl  0x8(%ebx)
f0102638:	e8 3e 1d 00 00       	call   f010437b <memcpy>
f010263d:	83 c4 10             	add    $0x10,%esp

	struct Proghdr *ph = (struct Proghdr *) (elf->e_phoff + binary);
	struct Proghdr *eph = ph + elf->e_phnum;

	lcr3(PADDR(e->env_pgdir));
	for(; ph < eph; ph++){
f0102640:	83 c3 20             	add    $0x20,%ebx
f0102643:	39 de                	cmp    %ebx,%esi
f0102645:	77 bf                	ja     f0102606 <env_create+0x79>
			region_alloc(e, (void *) ph->p_va, ph->p_memsz);
			memset((void *) ph->p_va, 0, ph->p_memsz);
			memcpy((void *) ph->p_va, binary + ph->p_offset, ph->p_filesz);
		}
	}
	lcr3(PADDR(kern_pgdir));
f0102647:	a1 0c 8f 22 f0       	mov    0xf0228f0c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010264c:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102651:	77 15                	ja     f0102668 <env_create+0xdb>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102653:	50                   	push   %eax
f0102654:	68 c8 4f 10 f0       	push   $0xf0104fc8
f0102659:	68 76 01 00 00       	push   $0x176
f010265e:	68 f3 5d 10 f0       	push   $0xf0105df3
f0102663:	e8 d8 d9 ff ff       	call   f0100040 <_panic>
f0102668:	05 00 00 00 10       	add    $0x10000000,%eax
f010266d:	0f 22 d8             	mov    %eax,%cr3
	e->env_tf.tf_eip = elf->e_entry;
f0102670:	8b 47 18             	mov    0x18(%edi),%eax
f0102673:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102676:	89 47 30             	mov    %eax,0x30(%edi)
	// Now map one page for the program's initial stack
	// at virtual address USTACKTOP - PGSIZE.

	// LAB 3: Your code here.
	region_alloc(e, (void *) (USTACKTOP - PGSIZE), PGSIZE);
f0102679:	b9 00 10 00 00       	mov    $0x1000,%ecx
f010267e:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f0102683:	89 f8                	mov    %edi,%eax
f0102685:	e8 f9 fb ff ff       	call   f0102283 <region_alloc>
{
	// LAB 3: Your code here.
	struct Env *e;
	env_alloc(&e, 0);
	load_icode(e, binary);
	e->env_type = type;
f010268a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010268d:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102690:	89 50 50             	mov    %edx,0x50(%eax)
}
f0102693:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102696:	5b                   	pop    %ebx
f0102697:	5e                   	pop    %esi
f0102698:	5f                   	pop    %edi
f0102699:	5d                   	pop    %ebp
f010269a:	c3                   	ret    

f010269b <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f010269b:	55                   	push   %ebp
f010269c:	89 e5                	mov    %esp,%ebp
f010269e:	57                   	push   %edi
f010269f:	56                   	push   %esi
f01026a0:	53                   	push   %ebx
f01026a1:	83 ec 1c             	sub    $0x1c,%esp
f01026a4:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f01026a7:	e8 3a 22 00 00       	call   f01048e6 <cpunum>
f01026ac:	6b c0 74             	imul   $0x74,%eax,%eax
f01026af:	39 b8 28 90 22 f0    	cmp    %edi,-0xfdd6fd8(%eax)
f01026b5:	75 29                	jne    f01026e0 <env_free+0x45>
		lcr3(PADDR(kern_pgdir));
f01026b7:	a1 0c 8f 22 f0       	mov    0xf0228f0c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01026bc:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01026c1:	77 15                	ja     f01026d8 <env_free+0x3d>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01026c3:	50                   	push   %eax
f01026c4:	68 c8 4f 10 f0       	push   $0xf0104fc8
f01026c9:	68 9f 01 00 00       	push   $0x19f
f01026ce:	68 f3 5d 10 f0       	push   $0xf0105df3
f01026d3:	e8 68 d9 ff ff       	call   f0100040 <_panic>
f01026d8:	05 00 00 00 10       	add    $0x10000000,%eax
f01026dd:	0f 22 d8             	mov    %eax,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f01026e0:	8b 5f 48             	mov    0x48(%edi),%ebx
f01026e3:	e8 fe 21 00 00       	call   f01048e6 <cpunum>
f01026e8:	6b c0 74             	imul   $0x74,%eax,%eax
f01026eb:	ba 00 00 00 00       	mov    $0x0,%edx
f01026f0:	83 b8 28 90 22 f0 00 	cmpl   $0x0,-0xfdd6fd8(%eax)
f01026f7:	74 11                	je     f010270a <env_free+0x6f>
f01026f9:	e8 e8 21 00 00       	call   f01048e6 <cpunum>
f01026fe:	6b c0 74             	imul   $0x74,%eax,%eax
f0102701:	8b 80 28 90 22 f0    	mov    -0xfdd6fd8(%eax),%eax
f0102707:	8b 50 48             	mov    0x48(%eax),%edx
f010270a:	83 ec 04             	sub    $0x4,%esp
f010270d:	53                   	push   %ebx
f010270e:	52                   	push   %edx
f010270f:	68 13 5e 10 f0       	push   $0xf0105e13
f0102714:	e8 24 04 00 00       	call   f0102b3d <cprintf>
f0102719:	83 c4 10             	add    $0x10,%esp

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f010271c:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0102723:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0102726:	89 d0                	mov    %edx,%eax
f0102728:	c1 e0 02             	shl    $0x2,%eax
f010272b:	89 45 dc             	mov    %eax,-0x24(%ebp)

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f010272e:	8b 47 60             	mov    0x60(%edi),%eax
f0102731:	8b 34 90             	mov    (%eax,%edx,4),%esi
f0102734:	f7 c6 01 00 00 00    	test   $0x1,%esi
f010273a:	0f 84 a8 00 00 00    	je     f01027e8 <env_free+0x14d>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f0102740:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102746:	89 f0                	mov    %esi,%eax
f0102748:	c1 e8 0c             	shr    $0xc,%eax
f010274b:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010274e:	39 05 08 8f 22 f0    	cmp    %eax,0xf0228f08
f0102754:	77 15                	ja     f010276b <env_free+0xd0>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102756:	56                   	push   %esi
f0102757:	68 a4 4f 10 f0       	push   $0xf0104fa4
f010275c:	68 ae 01 00 00       	push   $0x1ae
f0102761:	68 f3 5d 10 f0       	push   $0xf0105df3
f0102766:	e8 d5 d8 ff ff       	call   f0100040 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f010276b:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010276e:	c1 e0 16             	shl    $0x16,%eax
f0102771:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0102774:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f0102779:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f0102780:	01 
f0102781:	74 17                	je     f010279a <env_free+0xff>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0102783:	83 ec 08             	sub    $0x8,%esp
f0102786:	89 d8                	mov    %ebx,%eax
f0102788:	c1 e0 0c             	shl    $0xc,%eax
f010278b:	0b 45 e4             	or     -0x1c(%ebp),%eax
f010278e:	50                   	push   %eax
f010278f:	ff 77 60             	pushl  0x60(%edi)
f0102792:	e8 d8 e6 ff ff       	call   f0100e6f <page_remove>
f0102797:	83 c4 10             	add    $0x10,%esp
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f010279a:	83 c3 01             	add    $0x1,%ebx
f010279d:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f01027a3:	75 d4                	jne    f0102779 <env_free+0xde>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f01027a5:	8b 47 60             	mov    0x60(%edi),%eax
f01027a8:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01027ab:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01027b2:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01027b5:	3b 05 08 8f 22 f0    	cmp    0xf0228f08,%eax
f01027bb:	72 14                	jb     f01027d1 <env_free+0x136>
		panic("pa2page called with invalid pa");
f01027bd:	83 ec 04             	sub    $0x4,%esp
f01027c0:	68 28 55 10 f0       	push   $0xf0105528
f01027c5:	6a 51                	push   $0x51
f01027c7:	68 19 5b 10 f0       	push   $0xf0105b19
f01027cc:	e8 6f d8 ff ff       	call   f0100040 <_panic>
		page_decref(pa2page(pa));
f01027d1:	83 ec 0c             	sub    $0xc,%esp
f01027d4:	a1 10 8f 22 f0       	mov    0xf0228f10,%eax
f01027d9:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01027dc:	8d 04 d0             	lea    (%eax,%edx,8),%eax
f01027df:	50                   	push   %eax
f01027e0:	e8 3f e5 ff ff       	call   f0100d24 <page_decref>
f01027e5:	83 c4 10             	add    $0x10,%esp
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f01027e8:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f01027ec:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01027ef:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f01027f4:	0f 85 29 ff ff ff    	jne    f0102723 <env_free+0x88>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f01027fa:	8b 47 60             	mov    0x60(%edi),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01027fd:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102802:	77 15                	ja     f0102819 <env_free+0x17e>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102804:	50                   	push   %eax
f0102805:	68 c8 4f 10 f0       	push   $0xf0104fc8
f010280a:	68 bc 01 00 00       	push   $0x1bc
f010280f:	68 f3 5d 10 f0       	push   $0xf0105df3
f0102814:	e8 27 d8 ff ff       	call   f0100040 <_panic>
	e->env_pgdir = 0;
f0102819:	c7 47 60 00 00 00 00 	movl   $0x0,0x60(%edi)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102820:	05 00 00 00 10       	add    $0x10000000,%eax
f0102825:	c1 e8 0c             	shr    $0xc,%eax
f0102828:	3b 05 08 8f 22 f0    	cmp    0xf0228f08,%eax
f010282e:	72 14                	jb     f0102844 <env_free+0x1a9>
		panic("pa2page called with invalid pa");
f0102830:	83 ec 04             	sub    $0x4,%esp
f0102833:	68 28 55 10 f0       	push   $0xf0105528
f0102838:	6a 51                	push   $0x51
f010283a:	68 19 5b 10 f0       	push   $0xf0105b19
f010283f:	e8 fc d7 ff ff       	call   f0100040 <_panic>
	page_decref(pa2page(pa));
f0102844:	83 ec 0c             	sub    $0xc,%esp
f0102847:	8b 15 10 8f 22 f0    	mov    0xf0228f10,%edx
f010284d:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f0102850:	50                   	push   %eax
f0102851:	e8 ce e4 ff ff       	call   f0100d24 <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f0102856:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f010285d:	a1 48 82 22 f0       	mov    0xf0228248,%eax
f0102862:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f0102865:	89 3d 48 82 22 f0    	mov    %edi,0xf0228248
}
f010286b:	83 c4 10             	add    $0x10,%esp
f010286e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102871:	5b                   	pop    %ebx
f0102872:	5e                   	pop    %esi
f0102873:	5f                   	pop    %edi
f0102874:	5d                   	pop    %ebp
f0102875:	c3                   	ret    

f0102876 <env_destroy>:
// If e was the current env, then runs a new environment (and does not return
// to the caller).
//
void
env_destroy(struct Env *e)
{
f0102876:	55                   	push   %ebp
f0102877:	89 e5                	mov    %esp,%ebp
f0102879:	53                   	push   %ebx
f010287a:	83 ec 04             	sub    $0x4,%esp
f010287d:	8b 5d 08             	mov    0x8(%ebp),%ebx
	// If e is currently running on other CPUs, we change its state to
	// ENV_DYING. A zombie environment will be freed the next time
	// it traps to the kernel.
	if (e->env_status == ENV_RUNNING && curenv != e) {
f0102880:	83 7b 54 03          	cmpl   $0x3,0x54(%ebx)
f0102884:	75 19                	jne    f010289f <env_destroy+0x29>
f0102886:	e8 5b 20 00 00       	call   f01048e6 <cpunum>
f010288b:	6b c0 74             	imul   $0x74,%eax,%eax
f010288e:	3b 98 28 90 22 f0    	cmp    -0xfdd6fd8(%eax),%ebx
f0102894:	74 09                	je     f010289f <env_destroy+0x29>
		e->env_status = ENV_DYING;
f0102896:	c7 43 54 01 00 00 00 	movl   $0x1,0x54(%ebx)
		return;
f010289d:	eb 33                	jmp    f01028d2 <env_destroy+0x5c>
	}

	env_free(e);
f010289f:	83 ec 0c             	sub    $0xc,%esp
f01028a2:	53                   	push   %ebx
f01028a3:	e8 f3 fd ff ff       	call   f010269b <env_free>

	if (curenv == e) {
f01028a8:	e8 39 20 00 00       	call   f01048e6 <cpunum>
f01028ad:	6b c0 74             	imul   $0x74,%eax,%eax
f01028b0:	83 c4 10             	add    $0x10,%esp
f01028b3:	3b 98 28 90 22 f0    	cmp    -0xfdd6fd8(%eax),%ebx
f01028b9:	75 17                	jne    f01028d2 <env_destroy+0x5c>
		curenv = NULL;
f01028bb:	e8 26 20 00 00       	call   f01048e6 <cpunum>
f01028c0:	6b c0 74             	imul   $0x74,%eax,%eax
f01028c3:	c7 80 28 90 22 f0 00 	movl   $0x0,-0xfdd6fd8(%eax)
f01028ca:	00 00 00 
		sched_yield();
f01028cd:	e8 31 0d 00 00       	call   f0103603 <sched_yield>
	}
}
f01028d2:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01028d5:	c9                   	leave  
f01028d6:	c3                   	ret    

f01028d7 <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f01028d7:	55                   	push   %ebp
f01028d8:	89 e5                	mov    %esp,%ebp
f01028da:	53                   	push   %ebx
f01028db:	83 ec 04             	sub    $0x4,%esp
	// Record the CPU we are running on for user-space debugging
	curenv->env_cpunum = cpunum();
f01028de:	e8 03 20 00 00       	call   f01048e6 <cpunum>
f01028e3:	6b c0 74             	imul   $0x74,%eax,%eax
f01028e6:	8b 98 28 90 22 f0    	mov    -0xfdd6fd8(%eax),%ebx
f01028ec:	e8 f5 1f 00 00       	call   f01048e6 <cpunum>
f01028f1:	89 43 5c             	mov    %eax,0x5c(%ebx)

	asm volatile(
f01028f4:	8b 65 08             	mov    0x8(%ebp),%esp
f01028f7:	61                   	popa   
f01028f8:	07                   	pop    %es
f01028f9:	1f                   	pop    %ds
f01028fa:	83 c4 08             	add    $0x8,%esp
f01028fd:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret\n"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f01028fe:	83 ec 04             	sub    $0x4,%esp
f0102901:	68 29 5e 10 f0       	push   $0xf0105e29
f0102906:	68 f3 01 00 00       	push   $0x1f3
f010290b:	68 f3 5d 10 f0       	push   $0xf0105df3
f0102910:	e8 2b d7 ff ff       	call   f0100040 <_panic>

f0102915 <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f0102915:	55                   	push   %ebp
f0102916:	89 e5                	mov    %esp,%ebp
f0102918:	53                   	push   %ebx
f0102919:	83 ec 04             	sub    $0x4,%esp
f010291c:	8b 5d 08             	mov    0x8(%ebp),%ebx
	//	e->env_tf.  Go back through the code you wrote above
	//	and make sure you have set the relevant parts of
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.
	if(curenv != NULL){
f010291f:	e8 c2 1f 00 00       	call   f01048e6 <cpunum>
f0102924:	6b c0 74             	imul   $0x74,%eax,%eax
f0102927:	83 b8 28 90 22 f0 00 	cmpl   $0x0,-0xfdd6fd8(%eax)
f010292e:	74 29                	je     f0102959 <env_run+0x44>
		if(curenv->env_status == ENV_RUNNING)
f0102930:	e8 b1 1f 00 00       	call   f01048e6 <cpunum>
f0102935:	6b c0 74             	imul   $0x74,%eax,%eax
f0102938:	8b 80 28 90 22 f0    	mov    -0xfdd6fd8(%eax),%eax
f010293e:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0102942:	75 15                	jne    f0102959 <env_run+0x44>
			curenv->env_status = ENV_RUNNABLE;
f0102944:	e8 9d 1f 00 00       	call   f01048e6 <cpunum>
f0102949:	6b c0 74             	imul   $0x74,%eax,%eax
f010294c:	8b 80 28 90 22 f0    	mov    -0xfdd6fd8(%eax),%eax
f0102952:	c7 40 54 02 00 00 00 	movl   $0x2,0x54(%eax)
	}
	curenv = e;
f0102959:	e8 88 1f 00 00       	call   f01048e6 <cpunum>
f010295e:	6b c0 74             	imul   $0x74,%eax,%eax
f0102961:	89 98 28 90 22 f0    	mov    %ebx,-0xfdd6fd8(%eax)
	curenv->env_status = ENV_RUNNING;
f0102967:	e8 7a 1f 00 00       	call   f01048e6 <cpunum>
f010296c:	6b c0 74             	imul   $0x74,%eax,%eax
f010296f:	8b 80 28 90 22 f0    	mov    -0xfdd6fd8(%eax),%eax
f0102975:	c7 40 54 03 00 00 00 	movl   $0x3,0x54(%eax)
	curenv->env_runs ++;
f010297c:	e8 65 1f 00 00       	call   f01048e6 <cpunum>
f0102981:	6b c0 74             	imul   $0x74,%eax,%eax
f0102984:	8b 80 28 90 22 f0    	mov    -0xfdd6fd8(%eax),%eax
f010298a:	83 40 58 01          	addl   $0x1,0x58(%eax)
	lcr3(PADDR(e->env_pgdir));
f010298e:	8b 43 60             	mov    0x60(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102991:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102996:	77 15                	ja     f01029ad <env_run+0x98>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102998:	50                   	push   %eax
f0102999:	68 c8 4f 10 f0       	push   $0xf0104fc8
f010299e:	68 18 02 00 00       	push   $0x218
f01029a3:	68 f3 5d 10 f0       	push   $0xf0105df3
f01029a8:	e8 93 d6 ff ff       	call   f0100040 <_panic>
f01029ad:	05 00 00 00 10       	add    $0x10000000,%eax
f01029b2:	0f 22 d8             	mov    %eax,%cr3
	env_pop_tf(&e->env_tf);
f01029b5:	83 ec 0c             	sub    $0xc,%esp
f01029b8:	53                   	push   %ebx
f01029b9:	e8 19 ff ff ff       	call   f01028d7 <env_pop_tf>

f01029be <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f01029be:	55                   	push   %ebp
f01029bf:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01029c1:	ba 70 00 00 00       	mov    $0x70,%edx
f01029c6:	8b 45 08             	mov    0x8(%ebp),%eax
f01029c9:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01029ca:	ba 71 00 00 00       	mov    $0x71,%edx
f01029cf:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f01029d0:	0f b6 c0             	movzbl %al,%eax
}
f01029d3:	5d                   	pop    %ebp
f01029d4:	c3                   	ret    

f01029d5 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f01029d5:	55                   	push   %ebp
f01029d6:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01029d8:	ba 70 00 00 00       	mov    $0x70,%edx
f01029dd:	8b 45 08             	mov    0x8(%ebp),%eax
f01029e0:	ee                   	out    %al,(%dx)
f01029e1:	ba 71 00 00 00       	mov    $0x71,%edx
f01029e6:	8b 45 0c             	mov    0xc(%ebp),%eax
f01029e9:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f01029ea:	5d                   	pop    %ebp
f01029eb:	c3                   	ret    

f01029ec <irq_setmask_8259A>:
		irq_setmask_8259A(irq_mask_8259A);
}

void
irq_setmask_8259A(uint16_t mask)
{
f01029ec:	55                   	push   %ebp
f01029ed:	89 e5                	mov    %esp,%ebp
f01029ef:	56                   	push   %esi
f01029f0:	53                   	push   %ebx
f01029f1:	8b 45 08             	mov    0x8(%ebp),%eax
	int i;
	irq_mask_8259A = mask;
f01029f4:	66 a3 88 d3 11 f0    	mov    %ax,0xf011d388
	if (!didinit)
f01029fa:	80 3d 4c 82 22 f0 00 	cmpb   $0x0,0xf022824c
f0102a01:	74 5a                	je     f0102a5d <irq_setmask_8259A+0x71>
f0102a03:	89 c6                	mov    %eax,%esi
f0102a05:	ba 21 00 00 00       	mov    $0x21,%edx
f0102a0a:	ee                   	out    %al,(%dx)
f0102a0b:	66 c1 e8 08          	shr    $0x8,%ax
f0102a0f:	ba a1 00 00 00       	mov    $0xa1,%edx
f0102a14:	ee                   	out    %al,(%dx)
		return;
	outb(IO_PIC1+1, (char)mask);
	outb(IO_PIC2+1, (char)(mask >> 8));
	cprintf("enabled interrupts:");
f0102a15:	83 ec 0c             	sub    $0xc,%esp
f0102a18:	68 58 5e 10 f0       	push   $0xf0105e58
f0102a1d:	e8 1b 01 00 00       	call   f0102b3d <cprintf>
f0102a22:	83 c4 10             	add    $0x10,%esp
	for (i = 0; i < 16; i++)
f0102a25:	bb 00 00 00 00       	mov    $0x0,%ebx
		if (~mask & (1<<i))
f0102a2a:	0f b7 f6             	movzwl %si,%esi
f0102a2d:	f7 d6                	not    %esi
f0102a2f:	0f a3 de             	bt     %ebx,%esi
f0102a32:	73 11                	jae    f0102a45 <irq_setmask_8259A+0x59>
			cprintf(" %d", i);
f0102a34:	83 ec 08             	sub    $0x8,%esp
f0102a37:	53                   	push   %ebx
f0102a38:	68 7e 63 10 f0       	push   $0xf010637e
f0102a3d:	e8 fb 00 00 00       	call   f0102b3d <cprintf>
f0102a42:	83 c4 10             	add    $0x10,%esp
	if (!didinit)
		return;
	outb(IO_PIC1+1, (char)mask);
	outb(IO_PIC2+1, (char)(mask >> 8));
	cprintf("enabled interrupts:");
	for (i = 0; i < 16; i++)
f0102a45:	83 c3 01             	add    $0x1,%ebx
f0102a48:	83 fb 10             	cmp    $0x10,%ebx
f0102a4b:	75 e2                	jne    f0102a2f <irq_setmask_8259A+0x43>
		if (~mask & (1<<i))
			cprintf(" %d", i);
	cprintf("\n");
f0102a4d:	83 ec 0c             	sub    $0xc,%esp
f0102a50:	68 f1 5d 10 f0       	push   $0xf0105df1
f0102a55:	e8 e3 00 00 00       	call   f0102b3d <cprintf>
f0102a5a:	83 c4 10             	add    $0x10,%esp
}
f0102a5d:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0102a60:	5b                   	pop    %ebx
f0102a61:	5e                   	pop    %esi
f0102a62:	5d                   	pop    %ebp
f0102a63:	c3                   	ret    

f0102a64 <pic_init>:

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
	didinit = 1;
f0102a64:	c6 05 4c 82 22 f0 01 	movb   $0x1,0xf022824c
f0102a6b:	ba 21 00 00 00       	mov    $0x21,%edx
f0102a70:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102a75:	ee                   	out    %al,(%dx)
f0102a76:	ba a1 00 00 00       	mov    $0xa1,%edx
f0102a7b:	ee                   	out    %al,(%dx)
f0102a7c:	ba 20 00 00 00       	mov    $0x20,%edx
f0102a81:	b8 11 00 00 00       	mov    $0x11,%eax
f0102a86:	ee                   	out    %al,(%dx)
f0102a87:	ba 21 00 00 00       	mov    $0x21,%edx
f0102a8c:	b8 20 00 00 00       	mov    $0x20,%eax
f0102a91:	ee                   	out    %al,(%dx)
f0102a92:	b8 04 00 00 00       	mov    $0x4,%eax
f0102a97:	ee                   	out    %al,(%dx)
f0102a98:	b8 03 00 00 00       	mov    $0x3,%eax
f0102a9d:	ee                   	out    %al,(%dx)
f0102a9e:	ba a0 00 00 00       	mov    $0xa0,%edx
f0102aa3:	b8 11 00 00 00       	mov    $0x11,%eax
f0102aa8:	ee                   	out    %al,(%dx)
f0102aa9:	ba a1 00 00 00       	mov    $0xa1,%edx
f0102aae:	b8 28 00 00 00       	mov    $0x28,%eax
f0102ab3:	ee                   	out    %al,(%dx)
f0102ab4:	b8 02 00 00 00       	mov    $0x2,%eax
f0102ab9:	ee                   	out    %al,(%dx)
f0102aba:	b8 01 00 00 00       	mov    $0x1,%eax
f0102abf:	ee                   	out    %al,(%dx)
f0102ac0:	ba 20 00 00 00       	mov    $0x20,%edx
f0102ac5:	b8 68 00 00 00       	mov    $0x68,%eax
f0102aca:	ee                   	out    %al,(%dx)
f0102acb:	b8 0a 00 00 00       	mov    $0xa,%eax
f0102ad0:	ee                   	out    %al,(%dx)
f0102ad1:	ba a0 00 00 00       	mov    $0xa0,%edx
f0102ad6:	b8 68 00 00 00       	mov    $0x68,%eax
f0102adb:	ee                   	out    %al,(%dx)
f0102adc:	b8 0a 00 00 00       	mov    $0xa,%eax
f0102ae1:	ee                   	out    %al,(%dx)
	outb(IO_PIC1, 0x0a);             /* read IRR by default */

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irq_mask_8259A != 0xFFFF)
f0102ae2:	0f b7 05 88 d3 11 f0 	movzwl 0xf011d388,%eax
f0102ae9:	66 83 f8 ff          	cmp    $0xffff,%ax
f0102aed:	74 13                	je     f0102b02 <pic_init+0x9e>
static bool didinit;

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
f0102aef:	55                   	push   %ebp
f0102af0:	89 e5                	mov    %esp,%ebp
f0102af2:	83 ec 14             	sub    $0x14,%esp

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irq_mask_8259A != 0xFFFF)
		irq_setmask_8259A(irq_mask_8259A);
f0102af5:	0f b7 c0             	movzwl %ax,%eax
f0102af8:	50                   	push   %eax
f0102af9:	e8 ee fe ff ff       	call   f01029ec <irq_setmask_8259A>
f0102afe:	83 c4 10             	add    $0x10,%esp
}
f0102b01:	c9                   	leave  
f0102b02:	f3 c3                	repz ret 

f0102b04 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0102b04:	55                   	push   %ebp
f0102b05:	89 e5                	mov    %esp,%ebp
f0102b07:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0102b0a:	ff 75 08             	pushl  0x8(%ebp)
f0102b0d:	e8 3a dc ff ff       	call   f010074c <cputchar>
	*cnt++;
}
f0102b12:	83 c4 10             	add    $0x10,%esp
f0102b15:	c9                   	leave  
f0102b16:	c3                   	ret    

f0102b17 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0102b17:	55                   	push   %ebp
f0102b18:	89 e5                	mov    %esp,%ebp
f0102b1a:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0102b1d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0102b24:	ff 75 0c             	pushl  0xc(%ebp)
f0102b27:	ff 75 08             	pushl  0x8(%ebp)
f0102b2a:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102b2d:	50                   	push   %eax
f0102b2e:	68 04 2b 10 f0       	push   $0xf0102b04
f0102b33:	e8 22 11 00 00       	call   f0103c5a <vprintfmt>
	return cnt;
}
f0102b38:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102b3b:	c9                   	leave  
f0102b3c:	c3                   	ret    

f0102b3d <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0102b3d:	55                   	push   %ebp
f0102b3e:	89 e5                	mov    %esp,%ebp
f0102b40:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0102b43:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102b46:	50                   	push   %eax
f0102b47:	ff 75 08             	pushl  0x8(%ebp)
f0102b4a:	e8 c8 ff ff ff       	call   f0102b17 <vcprintf>
	va_end(ap);

	return cnt;
}
f0102b4f:	c9                   	leave  
f0102b50:	c3                   	ret    

f0102b51 <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f0102b51:	55                   	push   %ebp
f0102b52:	89 e5                	mov    %esp,%ebp
	//
	// LAB 4: Your code here:

	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	ts.ts_esp0 = KSTACKTOP;
f0102b54:	b8 80 8a 22 f0       	mov    $0xf0228a80,%eax
f0102b59:	c7 05 84 8a 22 f0 00 	movl   $0xf0000000,0xf0228a84
f0102b60:	00 00 f0 
	ts.ts_ss0 = GD_KD;
f0102b63:	66 c7 05 88 8a 22 f0 	movw   $0x10,0xf0228a88
f0102b6a:	10 00 
	ts.ts_iomb = sizeof(struct Taskstate);
f0102b6c:	66 c7 05 e6 8a 22 f0 	movw   $0x68,0xf0228ae6
f0102b73:	68 00 

	// Initialize the TSS slot of the gdt.
	gdt[GD_TSS0 >> 3] = SEG16(STS_T32A, (uint32_t) (&ts),
f0102b75:	66 c7 05 48 d3 11 f0 	movw   $0x67,0xf011d348
f0102b7c:	67 00 
f0102b7e:	66 a3 4a d3 11 f0    	mov    %ax,0xf011d34a
f0102b84:	89 c2                	mov    %eax,%edx
f0102b86:	c1 ea 10             	shr    $0x10,%edx
f0102b89:	88 15 4c d3 11 f0    	mov    %dl,0xf011d34c
f0102b8f:	c6 05 4e d3 11 f0 40 	movb   $0x40,0xf011d34e
f0102b96:	c1 e8 18             	shr    $0x18,%eax
f0102b99:	a2 4f d3 11 f0       	mov    %al,0xf011d34f
					sizeof(struct Taskstate) - 1, 0);
	gdt[GD_TSS0 >> 3].sd_s = 0;
f0102b9e:	c6 05 4d d3 11 f0 89 	movb   $0x89,0xf011d34d
}

static inline void
ltr(uint16_t sel)
{
	asm volatile("ltr %0" : : "r" (sel));
f0102ba5:	b8 28 00 00 00       	mov    $0x28,%eax
f0102baa:	0f 00 d8             	ltr    %ax
}

static inline void
lidt(void *p)
{
	asm volatile("lidt (%0)" : : "r" (p));
f0102bad:	b8 8c d3 11 f0       	mov    $0xf011d38c,%eax
f0102bb2:	0f 01 18             	lidtl  (%eax)
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0);

	// Load the IDT
	lidt(&idt_pd);
}
f0102bb5:	5d                   	pop    %ebp
f0102bb6:	c3                   	ret    

f0102bb7 <trap_init>:
}


void
trap_init(void)
{
f0102bb7:	55                   	push   %ebp
f0102bb8:	89 e5                	mov    %esp,%ebp
	extern struct Segdesc gdt[];

	// LAB 3: Your code here.

	SETGATE(idt[T_DIVIDE], 0, GD_KT, t_divide, 0);
f0102bba:	b8 92 34 10 f0       	mov    $0xf0103492,%eax
f0102bbf:	66 a3 60 82 22 f0    	mov    %ax,0xf0228260
f0102bc5:	66 c7 05 62 82 22 f0 	movw   $0x8,0xf0228262
f0102bcc:	08 00 
f0102bce:	c6 05 64 82 22 f0 00 	movb   $0x0,0xf0228264
f0102bd5:	c6 05 65 82 22 f0 8e 	movb   $0x8e,0xf0228265
f0102bdc:	c1 e8 10             	shr    $0x10,%eax
f0102bdf:	66 a3 66 82 22 f0    	mov    %ax,0xf0228266
	SETGATE(idt[T_DEBUG], 0, GD_KT, t_debug, 0);
f0102be5:	b8 9c 34 10 f0       	mov    $0xf010349c,%eax
f0102bea:	66 a3 68 82 22 f0    	mov    %ax,0xf0228268
f0102bf0:	66 c7 05 6a 82 22 f0 	movw   $0x8,0xf022826a
f0102bf7:	08 00 
f0102bf9:	c6 05 6c 82 22 f0 00 	movb   $0x0,0xf022826c
f0102c00:	c6 05 6d 82 22 f0 8e 	movb   $0x8e,0xf022826d
f0102c07:	c1 e8 10             	shr    $0x10,%eax
f0102c0a:	66 a3 6e 82 22 f0    	mov    %ax,0xf022826e
	SETGATE(idt[T_NMI], 0, GD_KT, t_nmi, 0);
f0102c10:	b8 a2 34 10 f0       	mov    $0xf01034a2,%eax
f0102c15:	66 a3 70 82 22 f0    	mov    %ax,0xf0228270
f0102c1b:	66 c7 05 72 82 22 f0 	movw   $0x8,0xf0228272
f0102c22:	08 00 
f0102c24:	c6 05 74 82 22 f0 00 	movb   $0x0,0xf0228274
f0102c2b:	c6 05 75 82 22 f0 8e 	movb   $0x8e,0xf0228275
f0102c32:	c1 e8 10             	shr    $0x10,%eax
f0102c35:	66 a3 76 82 22 f0    	mov    %ax,0xf0228276
	SETGATE(idt[T_BRKPT], 0, GD_KT, t_brkpt, 3);
f0102c3b:	b8 a8 34 10 f0       	mov    $0xf01034a8,%eax
f0102c40:	66 a3 78 82 22 f0    	mov    %ax,0xf0228278
f0102c46:	66 c7 05 7a 82 22 f0 	movw   $0x8,0xf022827a
f0102c4d:	08 00 
f0102c4f:	c6 05 7c 82 22 f0 00 	movb   $0x0,0xf022827c
f0102c56:	c6 05 7d 82 22 f0 ee 	movb   $0xee,0xf022827d
f0102c5d:	c1 e8 10             	shr    $0x10,%eax
f0102c60:	66 a3 7e 82 22 f0    	mov    %ax,0xf022827e
	SETGATE(idt[T_OFLOW], 0, GD_KT, t_oflow, 0);
f0102c66:	b8 ae 34 10 f0       	mov    $0xf01034ae,%eax
f0102c6b:	66 a3 80 82 22 f0    	mov    %ax,0xf0228280
f0102c71:	66 c7 05 82 82 22 f0 	movw   $0x8,0xf0228282
f0102c78:	08 00 
f0102c7a:	c6 05 84 82 22 f0 00 	movb   $0x0,0xf0228284
f0102c81:	c6 05 85 82 22 f0 8e 	movb   $0x8e,0xf0228285
f0102c88:	c1 e8 10             	shr    $0x10,%eax
f0102c8b:	66 a3 86 82 22 f0    	mov    %ax,0xf0228286
	SETGATE(idt[T_BOUND], 0, GD_KT, t_bound, 0);
f0102c91:	b8 b4 34 10 f0       	mov    $0xf01034b4,%eax
f0102c96:	66 a3 88 82 22 f0    	mov    %ax,0xf0228288
f0102c9c:	66 c7 05 8a 82 22 f0 	movw   $0x8,0xf022828a
f0102ca3:	08 00 
f0102ca5:	c6 05 8c 82 22 f0 00 	movb   $0x0,0xf022828c
f0102cac:	c6 05 8d 82 22 f0 8e 	movb   $0x8e,0xf022828d
f0102cb3:	c1 e8 10             	shr    $0x10,%eax
f0102cb6:	66 a3 8e 82 22 f0    	mov    %ax,0xf022828e
	SETGATE(idt[T_ILLOP], 0, GD_KT, t_illop, 0);
f0102cbc:	b8 ba 34 10 f0       	mov    $0xf01034ba,%eax
f0102cc1:	66 a3 90 82 22 f0    	mov    %ax,0xf0228290
f0102cc7:	66 c7 05 92 82 22 f0 	movw   $0x8,0xf0228292
f0102cce:	08 00 
f0102cd0:	c6 05 94 82 22 f0 00 	movb   $0x0,0xf0228294
f0102cd7:	c6 05 95 82 22 f0 8e 	movb   $0x8e,0xf0228295
f0102cde:	c1 e8 10             	shr    $0x10,%eax
f0102ce1:	66 a3 96 82 22 f0    	mov    %ax,0xf0228296
	SETGATE(idt[T_DEVICE], 0, GD_KT, t_device, 0);
f0102ce7:	b8 c0 34 10 f0       	mov    $0xf01034c0,%eax
f0102cec:	66 a3 98 82 22 f0    	mov    %ax,0xf0228298
f0102cf2:	66 c7 05 9a 82 22 f0 	movw   $0x8,0xf022829a
f0102cf9:	08 00 
f0102cfb:	c6 05 9c 82 22 f0 00 	movb   $0x0,0xf022829c
f0102d02:	c6 05 9d 82 22 f0 8e 	movb   $0x8e,0xf022829d
f0102d09:	c1 e8 10             	shr    $0x10,%eax
f0102d0c:	66 a3 9e 82 22 f0    	mov    %ax,0xf022829e
	SETGATE(idt[T_DBLFLT], 0, GD_KT, t_dblflt, 0);
f0102d12:	b8 c6 34 10 f0       	mov    $0xf01034c6,%eax
f0102d17:	66 a3 a0 82 22 f0    	mov    %ax,0xf02282a0
f0102d1d:	66 c7 05 a2 82 22 f0 	movw   $0x8,0xf02282a2
f0102d24:	08 00 
f0102d26:	c6 05 a4 82 22 f0 00 	movb   $0x0,0xf02282a4
f0102d2d:	c6 05 a5 82 22 f0 8e 	movb   $0x8e,0xf02282a5
f0102d34:	c1 e8 10             	shr    $0x10,%eax
f0102d37:	66 a3 a6 82 22 f0    	mov    %ax,0xf02282a6
	SETGATE(idt[T_TSS], 0, GD_KT, t_tss, 0);
f0102d3d:	b8 ca 34 10 f0       	mov    $0xf01034ca,%eax
f0102d42:	66 a3 b0 82 22 f0    	mov    %ax,0xf02282b0
f0102d48:	66 c7 05 b2 82 22 f0 	movw   $0x8,0xf02282b2
f0102d4f:	08 00 
f0102d51:	c6 05 b4 82 22 f0 00 	movb   $0x0,0xf02282b4
f0102d58:	c6 05 b5 82 22 f0 8e 	movb   $0x8e,0xf02282b5
f0102d5f:	c1 e8 10             	shr    $0x10,%eax
f0102d62:	66 a3 b6 82 22 f0    	mov    %ax,0xf02282b6
	SETGATE(idt[T_SEGNP], 0, GD_KT, t_segnp, 0);
f0102d68:	b8 ce 34 10 f0       	mov    $0xf01034ce,%eax
f0102d6d:	66 a3 b8 82 22 f0    	mov    %ax,0xf02282b8
f0102d73:	66 c7 05 ba 82 22 f0 	movw   $0x8,0xf02282ba
f0102d7a:	08 00 
f0102d7c:	c6 05 bc 82 22 f0 00 	movb   $0x0,0xf02282bc
f0102d83:	c6 05 bd 82 22 f0 8e 	movb   $0x8e,0xf02282bd
f0102d8a:	c1 e8 10             	shr    $0x10,%eax
f0102d8d:	66 a3 be 82 22 f0    	mov    %ax,0xf02282be
	SETGATE(idt[T_STACK], 0, GD_KT, t_stack, 0);
f0102d93:	b8 d2 34 10 f0       	mov    $0xf01034d2,%eax
f0102d98:	66 a3 c0 82 22 f0    	mov    %ax,0xf02282c0
f0102d9e:	66 c7 05 c2 82 22 f0 	movw   $0x8,0xf02282c2
f0102da5:	08 00 
f0102da7:	c6 05 c4 82 22 f0 00 	movb   $0x0,0xf02282c4
f0102dae:	c6 05 c5 82 22 f0 8e 	movb   $0x8e,0xf02282c5
f0102db5:	c1 e8 10             	shr    $0x10,%eax
f0102db8:	66 a3 c6 82 22 f0    	mov    %ax,0xf02282c6
	SETGATE(idt[T_GPFLT], 0, GD_KT, t_gpflt, 0);
f0102dbe:	b8 d6 34 10 f0       	mov    $0xf01034d6,%eax
f0102dc3:	66 a3 c8 82 22 f0    	mov    %ax,0xf02282c8
f0102dc9:	66 c7 05 ca 82 22 f0 	movw   $0x8,0xf02282ca
f0102dd0:	08 00 
f0102dd2:	c6 05 cc 82 22 f0 00 	movb   $0x0,0xf02282cc
f0102dd9:	c6 05 cd 82 22 f0 8e 	movb   $0x8e,0xf02282cd
f0102de0:	c1 e8 10             	shr    $0x10,%eax
f0102de3:	66 a3 ce 82 22 f0    	mov    %ax,0xf02282ce
	SETGATE(idt[T_PGFLT], 0, GD_KT, t_pgflt, 0);
f0102de9:	b8 da 34 10 f0       	mov    $0xf01034da,%eax
f0102dee:	66 a3 d0 82 22 f0    	mov    %ax,0xf02282d0
f0102df4:	66 c7 05 d2 82 22 f0 	movw   $0x8,0xf02282d2
f0102dfb:	08 00 
f0102dfd:	c6 05 d4 82 22 f0 00 	movb   $0x0,0xf02282d4
f0102e04:	c6 05 d5 82 22 f0 8e 	movb   $0x8e,0xf02282d5
f0102e0b:	c1 e8 10             	shr    $0x10,%eax
f0102e0e:	66 a3 d6 82 22 f0    	mov    %ax,0xf02282d6
	SETGATE(idt[T_FPERR], 0, GD_KT, t_fperr, 0);
f0102e14:	b8 de 34 10 f0       	mov    $0xf01034de,%eax
f0102e19:	66 a3 e0 82 22 f0    	mov    %ax,0xf02282e0
f0102e1f:	66 c7 05 e2 82 22 f0 	movw   $0x8,0xf02282e2
f0102e26:	08 00 
f0102e28:	c6 05 e4 82 22 f0 00 	movb   $0x0,0xf02282e4
f0102e2f:	c6 05 e5 82 22 f0 8e 	movb   $0x8e,0xf02282e5
f0102e36:	c1 e8 10             	shr    $0x10,%eax
f0102e39:	66 a3 e6 82 22 f0    	mov    %ax,0xf02282e6
	SETGATE(idt[T_ALIGN], 0, GD_KT, t_align, 0);
f0102e3f:	b8 e4 34 10 f0       	mov    $0xf01034e4,%eax
f0102e44:	66 a3 e8 82 22 f0    	mov    %ax,0xf02282e8
f0102e4a:	66 c7 05 ea 82 22 f0 	movw   $0x8,0xf02282ea
f0102e51:	08 00 
f0102e53:	c6 05 ec 82 22 f0 00 	movb   $0x0,0xf02282ec
f0102e5a:	c6 05 ed 82 22 f0 8e 	movb   $0x8e,0xf02282ed
f0102e61:	c1 e8 10             	shr    $0x10,%eax
f0102e64:	66 a3 ee 82 22 f0    	mov    %ax,0xf02282ee
	SETGATE(idt[T_MCHK], 0, GD_KT, t_mchk, 0);
f0102e6a:	b8 e8 34 10 f0       	mov    $0xf01034e8,%eax
f0102e6f:	66 a3 f0 82 22 f0    	mov    %ax,0xf02282f0
f0102e75:	66 c7 05 f2 82 22 f0 	movw   $0x8,0xf02282f2
f0102e7c:	08 00 
f0102e7e:	c6 05 f4 82 22 f0 00 	movb   $0x0,0xf02282f4
f0102e85:	c6 05 f5 82 22 f0 8e 	movb   $0x8e,0xf02282f5
f0102e8c:	c1 e8 10             	shr    $0x10,%eax
f0102e8f:	66 a3 f6 82 22 f0    	mov    %ax,0xf02282f6
	SETGATE(idt[T_SIMDERR], 0, GD_KT, t_simderr, 0);
f0102e95:	b8 ee 34 10 f0       	mov    $0xf01034ee,%eax
f0102e9a:	66 a3 f8 82 22 f0    	mov    %ax,0xf02282f8
f0102ea0:	66 c7 05 fa 82 22 f0 	movw   $0x8,0xf02282fa
f0102ea7:	08 00 
f0102ea9:	c6 05 fc 82 22 f0 00 	movb   $0x0,0xf02282fc
f0102eb0:	c6 05 fd 82 22 f0 8e 	movb   $0x8e,0xf02282fd
f0102eb7:	c1 e8 10             	shr    $0x10,%eax
f0102eba:	66 a3 fe 82 22 f0    	mov    %ax,0xf02282fe

	SETGATE(idt[T_SYSCALL], 0, GD_KT, t_syscall, 3);
f0102ec0:	b8 f4 34 10 f0       	mov    $0xf01034f4,%eax
f0102ec5:	66 a3 e0 83 22 f0    	mov    %ax,0xf02283e0
f0102ecb:	66 c7 05 e2 83 22 f0 	movw   $0x8,0xf02283e2
f0102ed2:	08 00 
f0102ed4:	c6 05 e4 83 22 f0 00 	movb   $0x0,0xf02283e4
f0102edb:	c6 05 e5 83 22 f0 ee 	movb   $0xee,0xf02283e5
f0102ee2:	c1 e8 10             	shr    $0x10,%eax
f0102ee5:	66 a3 e6 83 22 f0    	mov    %ax,0xf02283e6

	SETGATE(idt[IRQ_OFFSET + IRQ_TIMER], 0, GD_KT, irq_timer, 0);
f0102eeb:	b8 fa 34 10 f0       	mov    $0xf01034fa,%eax
f0102ef0:	66 a3 60 83 22 f0    	mov    %ax,0xf0228360
f0102ef6:	66 c7 05 62 83 22 f0 	movw   $0x8,0xf0228362
f0102efd:	08 00 
f0102eff:	c6 05 64 83 22 f0 00 	movb   $0x0,0xf0228364
f0102f06:	c6 05 65 83 22 f0 8e 	movb   $0x8e,0xf0228365
f0102f0d:	c1 e8 10             	shr    $0x10,%eax
f0102f10:	66 a3 66 83 22 f0    	mov    %ax,0xf0228366
	SETGATE(idt[IRQ_OFFSET + IRQ_KBD], 0, GD_KT, irq_kbd, 0);
f0102f16:	b8 00 35 10 f0       	mov    $0xf0103500,%eax
f0102f1b:	66 a3 68 83 22 f0    	mov    %ax,0xf0228368
f0102f21:	66 c7 05 6a 83 22 f0 	movw   $0x8,0xf022836a
f0102f28:	08 00 
f0102f2a:	c6 05 6c 83 22 f0 00 	movb   $0x0,0xf022836c
f0102f31:	c6 05 6d 83 22 f0 8e 	movb   $0x8e,0xf022836d
f0102f38:	c1 e8 10             	shr    $0x10,%eax
f0102f3b:	66 a3 6e 83 22 f0    	mov    %ax,0xf022836e
	SETGATE(idt[IRQ_OFFSET + IRQ_SERIAL], 0, GD_KT, irq_serial, 0);
f0102f41:	b8 06 35 10 f0       	mov    $0xf0103506,%eax
f0102f46:	66 a3 80 83 22 f0    	mov    %ax,0xf0228380
f0102f4c:	66 c7 05 82 83 22 f0 	movw   $0x8,0xf0228382
f0102f53:	08 00 
f0102f55:	c6 05 84 83 22 f0 00 	movb   $0x0,0xf0228384
f0102f5c:	c6 05 85 83 22 f0 8e 	movb   $0x8e,0xf0228385
f0102f63:	c1 e8 10             	shr    $0x10,%eax
f0102f66:	66 a3 86 83 22 f0    	mov    %ax,0xf0228386
	SETGATE(idt[IRQ_OFFSET + IRQ_SPURIOUS], 0, GD_KT, irq_spurious, 0);
f0102f6c:	b8 0c 35 10 f0       	mov    $0xf010350c,%eax
f0102f71:	66 a3 98 83 22 f0    	mov    %ax,0xf0228398
f0102f77:	66 c7 05 9a 83 22 f0 	movw   $0x8,0xf022839a
f0102f7e:	08 00 
f0102f80:	c6 05 9c 83 22 f0 00 	movb   $0x0,0xf022839c
f0102f87:	c6 05 9d 83 22 f0 8e 	movb   $0x8e,0xf022839d
f0102f8e:	c1 e8 10             	shr    $0x10,%eax
f0102f91:	66 a3 9e 83 22 f0    	mov    %ax,0xf022839e
	SETGATE(idt[IRQ_OFFSET + IRQ_IDE], 0, GD_KT, irq_ide, 0);
f0102f97:	b8 12 35 10 f0       	mov    $0xf0103512,%eax
f0102f9c:	66 a3 d0 83 22 f0    	mov    %ax,0xf02283d0
f0102fa2:	66 c7 05 d2 83 22 f0 	movw   $0x8,0xf02283d2
f0102fa9:	08 00 
f0102fab:	c6 05 d4 83 22 f0 00 	movb   $0x0,0xf02283d4
f0102fb2:	c6 05 d5 83 22 f0 8e 	movb   $0x8e,0xf02283d5
f0102fb9:	c1 e8 10             	shr    $0x10,%eax
f0102fbc:	66 a3 d6 83 22 f0    	mov    %ax,0xf02283d6
	SETGATE(idt[IRQ_OFFSET + IRQ_ERROR], 0, GD_KT, irq_error, 0);
f0102fc2:	b8 18 35 10 f0       	mov    $0xf0103518,%eax
f0102fc7:	66 a3 f8 83 22 f0    	mov    %ax,0xf02283f8
f0102fcd:	66 c7 05 fa 83 22 f0 	movw   $0x8,0xf02283fa
f0102fd4:	08 00 
f0102fd6:	c6 05 fc 83 22 f0 00 	movb   $0x0,0xf02283fc
f0102fdd:	c6 05 fd 83 22 f0 8e 	movb   $0x8e,0xf02283fd
f0102fe4:	c1 e8 10             	shr    $0x10,%eax
f0102fe7:	66 a3 fe 83 22 f0    	mov    %ax,0xf02283fe
	// Per-CPU setup 
	trap_init_percpu();
f0102fed:	e8 5f fb ff ff       	call   f0102b51 <trap_init_percpu>
}
f0102ff2:	5d                   	pop    %ebp
f0102ff3:	c3                   	ret    

f0102ff4 <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f0102ff4:	55                   	push   %ebp
f0102ff5:	89 e5                	mov    %esp,%ebp
f0102ff7:	53                   	push   %ebx
f0102ff8:	83 ec 0c             	sub    $0xc,%esp
f0102ffb:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f0102ffe:	ff 33                	pushl  (%ebx)
f0103000:	68 6c 5e 10 f0       	push   $0xf0105e6c
f0103005:	e8 33 fb ff ff       	call   f0102b3d <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f010300a:	83 c4 08             	add    $0x8,%esp
f010300d:	ff 73 04             	pushl  0x4(%ebx)
f0103010:	68 7b 5e 10 f0       	push   $0xf0105e7b
f0103015:	e8 23 fb ff ff       	call   f0102b3d <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f010301a:	83 c4 08             	add    $0x8,%esp
f010301d:	ff 73 08             	pushl  0x8(%ebx)
f0103020:	68 8a 5e 10 f0       	push   $0xf0105e8a
f0103025:	e8 13 fb ff ff       	call   f0102b3d <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f010302a:	83 c4 08             	add    $0x8,%esp
f010302d:	ff 73 0c             	pushl  0xc(%ebx)
f0103030:	68 99 5e 10 f0       	push   $0xf0105e99
f0103035:	e8 03 fb ff ff       	call   f0102b3d <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f010303a:	83 c4 08             	add    $0x8,%esp
f010303d:	ff 73 10             	pushl  0x10(%ebx)
f0103040:	68 a8 5e 10 f0       	push   $0xf0105ea8
f0103045:	e8 f3 fa ff ff       	call   f0102b3d <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f010304a:	83 c4 08             	add    $0x8,%esp
f010304d:	ff 73 14             	pushl  0x14(%ebx)
f0103050:	68 b7 5e 10 f0       	push   $0xf0105eb7
f0103055:	e8 e3 fa ff ff       	call   f0102b3d <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f010305a:	83 c4 08             	add    $0x8,%esp
f010305d:	ff 73 18             	pushl  0x18(%ebx)
f0103060:	68 c6 5e 10 f0       	push   $0xf0105ec6
f0103065:	e8 d3 fa ff ff       	call   f0102b3d <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f010306a:	83 c4 08             	add    $0x8,%esp
f010306d:	ff 73 1c             	pushl  0x1c(%ebx)
f0103070:	68 d5 5e 10 f0       	push   $0xf0105ed5
f0103075:	e8 c3 fa ff ff       	call   f0102b3d <cprintf>
}
f010307a:	83 c4 10             	add    $0x10,%esp
f010307d:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103080:	c9                   	leave  
f0103081:	c3                   	ret    

f0103082 <print_trapframe>:
	lidt(&idt_pd);
}

void
print_trapframe(struct Trapframe *tf)
{
f0103082:	55                   	push   %ebp
f0103083:	89 e5                	mov    %esp,%ebp
f0103085:	56                   	push   %esi
f0103086:	53                   	push   %ebx
f0103087:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p from CPU %d\n", tf, cpunum());
f010308a:	e8 57 18 00 00       	call   f01048e6 <cpunum>
f010308f:	83 ec 04             	sub    $0x4,%esp
f0103092:	50                   	push   %eax
f0103093:	53                   	push   %ebx
f0103094:	68 39 5f 10 f0       	push   $0xf0105f39
f0103099:	e8 9f fa ff ff       	call   f0102b3d <cprintf>
	print_regs(&tf->tf_regs);
f010309e:	89 1c 24             	mov    %ebx,(%esp)
f01030a1:	e8 4e ff ff ff       	call   f0102ff4 <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f01030a6:	83 c4 08             	add    $0x8,%esp
f01030a9:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f01030ad:	50                   	push   %eax
f01030ae:	68 57 5f 10 f0       	push   $0xf0105f57
f01030b3:	e8 85 fa ff ff       	call   f0102b3d <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f01030b8:	83 c4 08             	add    $0x8,%esp
f01030bb:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f01030bf:	50                   	push   %eax
f01030c0:	68 6a 5f 10 f0       	push   $0xf0105f6a
f01030c5:	e8 73 fa ff ff       	call   f0102b3d <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f01030ca:	8b 43 28             	mov    0x28(%ebx),%eax
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < ARRAY_SIZE(excnames))
f01030cd:	83 c4 10             	add    $0x10,%esp
f01030d0:	83 f8 13             	cmp    $0x13,%eax
f01030d3:	77 09                	ja     f01030de <print_trapframe+0x5c>
		return excnames[trapno];
f01030d5:	8b 14 85 20 62 10 f0 	mov    -0xfef9de0(,%eax,4),%edx
f01030dc:	eb 1f                	jmp    f01030fd <print_trapframe+0x7b>
	if (trapno == T_SYSCALL)
f01030de:	83 f8 30             	cmp    $0x30,%eax
f01030e1:	74 15                	je     f01030f8 <print_trapframe+0x76>
		return "System call";
	if (trapno >= IRQ_OFFSET && trapno < IRQ_OFFSET + 16)
f01030e3:	8d 50 e0             	lea    -0x20(%eax),%edx
		return "Hardware Interrupt";
	return "(unknown trap)";
f01030e6:	83 fa 10             	cmp    $0x10,%edx
f01030e9:	b9 03 5f 10 f0       	mov    $0xf0105f03,%ecx
f01030ee:	ba f0 5e 10 f0       	mov    $0xf0105ef0,%edx
f01030f3:	0f 43 d1             	cmovae %ecx,%edx
f01030f6:	eb 05                	jmp    f01030fd <print_trapframe+0x7b>
	};

	if (trapno < ARRAY_SIZE(excnames))
		return excnames[trapno];
	if (trapno == T_SYSCALL)
		return "System call";
f01030f8:	ba e4 5e 10 f0       	mov    $0xf0105ee4,%edx
{
	cprintf("TRAP frame at %p from CPU %d\n", tf, cpunum());
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f01030fd:	83 ec 04             	sub    $0x4,%esp
f0103100:	52                   	push   %edx
f0103101:	50                   	push   %eax
f0103102:	68 7d 5f 10 f0       	push   $0xf0105f7d
f0103107:	e8 31 fa ff ff       	call   f0102b3d <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f010310c:	83 c4 10             	add    $0x10,%esp
f010310f:	3b 1d 60 8a 22 f0    	cmp    0xf0228a60,%ebx
f0103115:	75 1a                	jne    f0103131 <print_trapframe+0xaf>
f0103117:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f010311b:	75 14                	jne    f0103131 <print_trapframe+0xaf>

static inline uint32_t
rcr2(void)
{
	uint32_t val;
	asm volatile("movl %%cr2,%0" : "=r" (val));
f010311d:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f0103120:	83 ec 08             	sub    $0x8,%esp
f0103123:	50                   	push   %eax
f0103124:	68 8f 5f 10 f0       	push   $0xf0105f8f
f0103129:	e8 0f fa ff ff       	call   f0102b3d <cprintf>
f010312e:	83 c4 10             	add    $0x10,%esp
	cprintf("  err  0x%08x", tf->tf_err);
f0103131:	83 ec 08             	sub    $0x8,%esp
f0103134:	ff 73 2c             	pushl  0x2c(%ebx)
f0103137:	68 9e 5f 10 f0       	push   $0xf0105f9e
f010313c:	e8 fc f9 ff ff       	call   f0102b3d <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f0103141:	83 c4 10             	add    $0x10,%esp
f0103144:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103148:	75 49                	jne    f0103193 <print_trapframe+0x111>
		cprintf(" [%s, %s, %s]\n",
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
f010314a:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f010314d:	89 c2                	mov    %eax,%edx
f010314f:	83 e2 01             	and    $0x1,%edx
f0103152:	ba 1d 5f 10 f0       	mov    $0xf0105f1d,%edx
f0103157:	b9 12 5f 10 f0       	mov    $0xf0105f12,%ecx
f010315c:	0f 44 ca             	cmove  %edx,%ecx
f010315f:	89 c2                	mov    %eax,%edx
f0103161:	83 e2 02             	and    $0x2,%edx
f0103164:	ba 2f 5f 10 f0       	mov    $0xf0105f2f,%edx
f0103169:	be 29 5f 10 f0       	mov    $0xf0105f29,%esi
f010316e:	0f 45 d6             	cmovne %esi,%edx
f0103171:	83 e0 04             	and    $0x4,%eax
f0103174:	be 7b 60 10 f0       	mov    $0xf010607b,%esi
f0103179:	b8 34 5f 10 f0       	mov    $0xf0105f34,%eax
f010317e:	0f 44 c6             	cmove  %esi,%eax
f0103181:	51                   	push   %ecx
f0103182:	52                   	push   %edx
f0103183:	50                   	push   %eax
f0103184:	68 ac 5f 10 f0       	push   $0xf0105fac
f0103189:	e8 af f9 ff ff       	call   f0102b3d <cprintf>
f010318e:	83 c4 10             	add    $0x10,%esp
f0103191:	eb 10                	jmp    f01031a3 <print_trapframe+0x121>
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f0103193:	83 ec 0c             	sub    $0xc,%esp
f0103196:	68 f1 5d 10 f0       	push   $0xf0105df1
f010319b:	e8 9d f9 ff ff       	call   f0102b3d <cprintf>
f01031a0:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f01031a3:	83 ec 08             	sub    $0x8,%esp
f01031a6:	ff 73 30             	pushl  0x30(%ebx)
f01031a9:	68 bb 5f 10 f0       	push   $0xf0105fbb
f01031ae:	e8 8a f9 ff ff       	call   f0102b3d <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f01031b3:	83 c4 08             	add    $0x8,%esp
f01031b6:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f01031ba:	50                   	push   %eax
f01031bb:	68 ca 5f 10 f0       	push   $0xf0105fca
f01031c0:	e8 78 f9 ff ff       	call   f0102b3d <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f01031c5:	83 c4 08             	add    $0x8,%esp
f01031c8:	ff 73 38             	pushl  0x38(%ebx)
f01031cb:	68 dd 5f 10 f0       	push   $0xf0105fdd
f01031d0:	e8 68 f9 ff ff       	call   f0102b3d <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f01031d5:	83 c4 10             	add    $0x10,%esp
f01031d8:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f01031dc:	74 25                	je     f0103203 <print_trapframe+0x181>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f01031de:	83 ec 08             	sub    $0x8,%esp
f01031e1:	ff 73 3c             	pushl  0x3c(%ebx)
f01031e4:	68 ec 5f 10 f0       	push   $0xf0105fec
f01031e9:	e8 4f f9 ff ff       	call   f0102b3d <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f01031ee:	83 c4 08             	add    $0x8,%esp
f01031f1:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f01031f5:	50                   	push   %eax
f01031f6:	68 fb 5f 10 f0       	push   $0xf0105ffb
f01031fb:	e8 3d f9 ff ff       	call   f0102b3d <cprintf>
f0103200:	83 c4 10             	add    $0x10,%esp
	}
}
f0103203:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0103206:	5b                   	pop    %ebx
f0103207:	5e                   	pop    %esi
f0103208:	5d                   	pop    %ebp
f0103209:	c3                   	ret    

f010320a <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f010320a:	55                   	push   %ebp
f010320b:	89 e5                	mov    %esp,%ebp
f010320d:	57                   	push   %edi
f010320e:	56                   	push   %esi
f010320f:	53                   	push   %ebx
f0103210:	83 ec 0c             	sub    $0xc,%esp
f0103213:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103216:	0f 20 d6             	mov    %cr2,%esi
	fault_va = rcr2();

	// Handle kernel-mode page faults.

	// LAB 3: Your code here.
	if (tf->tf_cs == GD_KT) {
f0103219:	66 83 7b 34 08       	cmpw   $0x8,0x34(%ebx)
f010321e:	75 17                	jne    f0103237 <page_fault_handler+0x2d>
		// Trapped from kernel mode
		panic("page_fault_handler: page fault in kernel mode");
f0103220:	83 ec 04             	sub    $0x4,%esp
f0103223:	68 c8 61 10 f0       	push   $0xf01061c8
f0103228:	68 63 01 00 00       	push   $0x163
f010322d:	68 0e 60 10 f0       	push   $0xf010600e
f0103232:	e8 09 ce ff ff       	call   f0100040 <_panic>
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103237:	8b 7b 30             	mov    0x30(%ebx),%edi
		curenv->env_id, fault_va, tf->tf_eip);
f010323a:	e8 a7 16 00 00       	call   f01048e6 <cpunum>
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f010323f:	57                   	push   %edi
f0103240:	56                   	push   %esi
		curenv->env_id, fault_va, tf->tf_eip);
f0103241:	6b c0 74             	imul   $0x74,%eax,%eax
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103244:	8b 80 28 90 22 f0    	mov    -0xfdd6fd8(%eax),%eax
f010324a:	ff 70 48             	pushl  0x48(%eax)
f010324d:	68 f8 61 10 f0       	push   $0xf01061f8
f0103252:	e8 e6 f8 ff ff       	call   f0102b3d <cprintf>
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f0103257:	89 1c 24             	mov    %ebx,(%esp)
f010325a:	e8 23 fe ff ff       	call   f0103082 <print_trapframe>
	env_destroy(curenv);
f010325f:	e8 82 16 00 00       	call   f01048e6 <cpunum>
f0103264:	83 c4 04             	add    $0x4,%esp
f0103267:	6b c0 74             	imul   $0x74,%eax,%eax
f010326a:	ff b0 28 90 22 f0    	pushl  -0xfdd6fd8(%eax)
f0103270:	e8 01 f6 ff ff       	call   f0102876 <env_destroy>
}
f0103275:	83 c4 10             	add    $0x10,%esp
f0103278:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010327b:	5b                   	pop    %ebx
f010327c:	5e                   	pop    %esi
f010327d:	5f                   	pop    %edi
f010327e:	5d                   	pop    %ebp
f010327f:	c3                   	ret    

f0103280 <trap>:
	}
}

void
trap(struct Trapframe *tf)
{
f0103280:	55                   	push   %ebp
f0103281:	89 e5                	mov    %esp,%ebp
f0103283:	57                   	push   %edi
f0103284:	56                   	push   %esi
f0103285:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f0103288:	fc                   	cld    

	// Halt the CPU if some other CPU has called panic()
	extern char *panicstr;
	if (panicstr)
f0103289:	83 3d 00 8f 22 f0 00 	cmpl   $0x0,0xf0228f00
f0103290:	74 01                	je     f0103293 <trap+0x13>
		asm volatile("hlt");
f0103292:	f4                   	hlt    

	// Re-acqurie the big kernel lock if we were halted in
	// sched_yield()
	if (xchg(&thiscpu->cpu_status, CPU_STARTED) == CPU_HALTED)
f0103293:	e8 4e 16 00 00       	call   f01048e6 <cpunum>
f0103298:	6b d0 74             	imul   $0x74,%eax,%edx
f010329b:	81 c2 20 90 22 f0    	add    $0xf0229020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"
f01032a1:	b8 01 00 00 00       	mov    $0x1,%eax
f01032a6:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
f01032aa:	83 f8 02             	cmp    $0x2,%eax
f01032ad:	75 10                	jne    f01032bf <trap+0x3f>
extern struct spinlock kernel_lock;

static inline void
lock_kernel(void)
{
	spin_lock(&kernel_lock);
f01032af:	83 ec 0c             	sub    $0xc,%esp
f01032b2:	68 a0 d3 11 f0       	push   $0xf011d3a0
f01032b7:	e8 98 18 00 00       	call   f0104b54 <spin_lock>
f01032bc:	83 c4 10             	add    $0x10,%esp

static inline uint32_t
read_eflags(void)
{
	uint32_t eflags;
	asm volatile("pushfl; popl %0" : "=r" (eflags));
f01032bf:	9c                   	pushf  
f01032c0:	58                   	pop    %eax
		lock_kernel();
	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f01032c1:	f6 c4 02             	test   $0x2,%ah
f01032c4:	74 19                	je     f01032df <trap+0x5f>
f01032c6:	68 1a 60 10 f0       	push   $0xf010601a
f01032cb:	68 4e 5b 10 f0       	push   $0xf0105b4e
f01032d0:	68 2d 01 00 00       	push   $0x12d
f01032d5:	68 0e 60 10 f0       	push   $0xf010600e
f01032da:	e8 61 cd ff ff       	call   f0100040 <_panic>

	if ((tf->tf_cs & 3) == 3) {
f01032df:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f01032e3:	83 e0 03             	and    $0x3,%eax
f01032e6:	66 83 f8 03          	cmp    $0x3,%ax
f01032ea:	0f 85 90 00 00 00    	jne    f0103380 <trap+0x100>
		// Trapped from user mode.
		// Acquire the big kernel lock before doing any
		// serious kernel work.
		// LAB 4: Your code here.
		assert(curenv);
f01032f0:	e8 f1 15 00 00       	call   f01048e6 <cpunum>
f01032f5:	6b c0 74             	imul   $0x74,%eax,%eax
f01032f8:	83 b8 28 90 22 f0 00 	cmpl   $0x0,-0xfdd6fd8(%eax)
f01032ff:	75 19                	jne    f010331a <trap+0x9a>
f0103301:	68 33 60 10 f0       	push   $0xf0106033
f0103306:	68 4e 5b 10 f0       	push   $0xf0105b4e
f010330b:	68 34 01 00 00       	push   $0x134
f0103310:	68 0e 60 10 f0       	push   $0xf010600e
f0103315:	e8 26 cd ff ff       	call   f0100040 <_panic>

		// Garbage collect if current enviroment is a zombie
		if (curenv->env_status == ENV_DYING) {
f010331a:	e8 c7 15 00 00       	call   f01048e6 <cpunum>
f010331f:	6b c0 74             	imul   $0x74,%eax,%eax
f0103322:	8b 80 28 90 22 f0    	mov    -0xfdd6fd8(%eax),%eax
f0103328:	83 78 54 01          	cmpl   $0x1,0x54(%eax)
f010332c:	75 2d                	jne    f010335b <trap+0xdb>
			env_free(curenv);
f010332e:	e8 b3 15 00 00       	call   f01048e6 <cpunum>
f0103333:	83 ec 0c             	sub    $0xc,%esp
f0103336:	6b c0 74             	imul   $0x74,%eax,%eax
f0103339:	ff b0 28 90 22 f0    	pushl  -0xfdd6fd8(%eax)
f010333f:	e8 57 f3 ff ff       	call   f010269b <env_free>
			curenv = NULL;
f0103344:	e8 9d 15 00 00       	call   f01048e6 <cpunum>
f0103349:	6b c0 74             	imul   $0x74,%eax,%eax
f010334c:	c7 80 28 90 22 f0 00 	movl   $0x0,-0xfdd6fd8(%eax)
f0103353:	00 00 00 
			sched_yield();
f0103356:	e8 a8 02 00 00       	call   f0103603 <sched_yield>
		}

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f010335b:	e8 86 15 00 00       	call   f01048e6 <cpunum>
f0103360:	6b c0 74             	imul   $0x74,%eax,%eax
f0103363:	8b 80 28 90 22 f0    	mov    -0xfdd6fd8(%eax),%eax
f0103369:	b9 11 00 00 00       	mov    $0x11,%ecx
f010336e:	89 c7                	mov    %eax,%edi
f0103370:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f0103372:	e8 6f 15 00 00       	call   f01048e6 <cpunum>
f0103377:	6b c0 74             	imul   $0x74,%eax,%eax
f010337a:	8b b0 28 90 22 f0    	mov    -0xfdd6fd8(%eax),%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f0103380:	89 35 60 8a 22 f0    	mov    %esi,0xf0228a60
trap_dispatch(struct Trapframe *tf)
{
	// Handle processor exceptions.
	// LAB 3: Your code here.
	int r;
	switch(tf->tf_trapno){
f0103386:	8b 46 28             	mov    0x28(%esi),%eax
f0103389:	83 f8 0e             	cmp    $0xe,%eax
f010338c:	74 46                	je     f01033d4 <trap+0x154>
f010338e:	83 f8 30             	cmp    $0x30,%eax
f0103391:	74 07                	je     f010339a <trap+0x11a>
f0103393:	83 f8 03             	cmp    $0x3,%eax
f0103396:	75 58                	jne    f01033f0 <trap+0x170>
f0103398:	eb 48                	jmp    f01033e2 <trap+0x162>
		case T_SYSCALL:
			r = syscall(
f010339a:	83 ec 08             	sub    $0x8,%esp
f010339d:	ff 76 04             	pushl  0x4(%esi)
f01033a0:	ff 36                	pushl  (%esi)
f01033a2:	ff 76 10             	pushl  0x10(%esi)
f01033a5:	ff 76 18             	pushl  0x18(%esi)
f01033a8:	ff 76 14             	pushl  0x14(%esi)
f01033ab:	ff 76 1c             	pushl  0x1c(%esi)
f01033ae:	e8 5d 02 00 00       	call   f0103610 <syscall>
					tf->tf_regs.reg_ecx, 
					tf->tf_regs.reg_ebx, 
					tf->tf_regs.reg_edi, 
					tf->tf_regs.reg_esi);

			if (r < 0) {
f01033b3:	83 c4 20             	add    $0x20,%esp
f01033b6:	85 c0                	test   %eax,%eax
f01033b8:	79 15                	jns    f01033cf <trap+0x14f>
				panic("trap_dispatch: %e", r);
f01033ba:	50                   	push   %eax
f01033bb:	68 3a 60 10 f0       	push   $0xf010603a
f01033c0:	68 f7 00 00 00       	push   $0xf7
f01033c5:	68 0e 60 10 f0       	push   $0xf010600e
f01033ca:	e8 71 cc ff ff       	call   f0100040 <_panic>
			}
			tf->tf_regs.reg_eax = r; 
f01033cf:	89 46 1c             	mov    %eax,0x1c(%esi)
f01033d2:	eb 7e                	jmp    f0103452 <trap+0x1d2>
			return;
		case T_PGFLT:
			page_fault_handler(tf);
f01033d4:	83 ec 0c             	sub    $0xc,%esp
f01033d7:	56                   	push   %esi
f01033d8:	e8 2d fe ff ff       	call   f010320a <page_fault_handler>
f01033dd:	83 c4 10             	add    $0x10,%esp
f01033e0:	eb 70                	jmp    f0103452 <trap+0x1d2>
			return;
		case T_BRKPT:
			monitor(tf);
f01033e2:	83 ec 0c             	sub    $0xc,%esp
f01033e5:	56                   	push   %esi
f01033e6:	e8 ee d4 ff ff       	call   f01008d9 <monitor>
f01033eb:	83 c4 10             	add    $0x10,%esp
f01033ee:	eb 62                	jmp    f0103452 <trap+0x1d2>
	}

	// Handle spurious interrupts
	// The hardware sometimes raises these because of noise on the
	// IRQ line or other reasons. We don't care.
	if (tf->tf_trapno == IRQ_OFFSET + IRQ_SPURIOUS) {
f01033f0:	83 f8 27             	cmp    $0x27,%eax
f01033f3:	75 1a                	jne    f010340f <trap+0x18f>
		cprintf("Spurious interrupt on irq 7\n");
f01033f5:	83 ec 0c             	sub    $0xc,%esp
f01033f8:	68 4c 60 10 f0       	push   $0xf010604c
f01033fd:	e8 3b f7 ff ff       	call   f0102b3d <cprintf>
		print_trapframe(tf);
f0103402:	89 34 24             	mov    %esi,(%esp)
f0103405:	e8 78 fc ff ff       	call   f0103082 <print_trapframe>
f010340a:	83 c4 10             	add    $0x10,%esp
f010340d:	eb 43                	jmp    f0103452 <trap+0x1d2>
	// Handle clock interrupts. Don't forget to acknowledge the
	// interrupt using lapic_eoi() before calling the scheduler!
	// LAB 4: Your code here.

	// Unexpected trap: The user process or the kernel has a bug.
	print_trapframe(tf);
f010340f:	83 ec 0c             	sub    $0xc,%esp
f0103412:	56                   	push   %esi
f0103413:	e8 6a fc ff ff       	call   f0103082 <print_trapframe>
	if (tf->tf_cs == GD_KT)
f0103418:	83 c4 10             	add    $0x10,%esp
f010341b:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f0103420:	75 17                	jne    f0103439 <trap+0x1b9>
		panic("unhandled trap in kernel");
f0103422:	83 ec 04             	sub    $0x4,%esp
f0103425:	68 69 60 10 f0       	push   $0xf0106069
f010342a:	68 13 01 00 00       	push   $0x113
f010342f:	68 0e 60 10 f0       	push   $0xf010600e
f0103434:	e8 07 cc ff ff       	call   f0100040 <_panic>
	else {
		env_destroy(curenv);
f0103439:	e8 a8 14 00 00       	call   f01048e6 <cpunum>
f010343e:	83 ec 0c             	sub    $0xc,%esp
f0103441:	6b c0 74             	imul   $0x74,%eax,%eax
f0103444:	ff b0 28 90 22 f0    	pushl  -0xfdd6fd8(%eax)
f010344a:	e8 27 f4 ff ff       	call   f0102876 <env_destroy>
f010344f:	83 c4 10             	add    $0x10,%esp
	trap_dispatch(tf);

	// If we made it to this point, then no other environment was
	// scheduled, so we should return to the current environment
	// if doing so makes sense.
	if (curenv && curenv->env_status == ENV_RUNNING)
f0103452:	e8 8f 14 00 00       	call   f01048e6 <cpunum>
f0103457:	6b c0 74             	imul   $0x74,%eax,%eax
f010345a:	83 b8 28 90 22 f0 00 	cmpl   $0x0,-0xfdd6fd8(%eax)
f0103461:	74 2a                	je     f010348d <trap+0x20d>
f0103463:	e8 7e 14 00 00       	call   f01048e6 <cpunum>
f0103468:	6b c0 74             	imul   $0x74,%eax,%eax
f010346b:	8b 80 28 90 22 f0    	mov    -0xfdd6fd8(%eax),%eax
f0103471:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0103475:	75 16                	jne    f010348d <trap+0x20d>
		env_run(curenv);
f0103477:	e8 6a 14 00 00       	call   f01048e6 <cpunum>
f010347c:	83 ec 0c             	sub    $0xc,%esp
f010347f:	6b c0 74             	imul   $0x74,%eax,%eax
f0103482:	ff b0 28 90 22 f0    	pushl  -0xfdd6fd8(%eax)
f0103488:	e8 88 f4 ff ff       	call   f0102915 <env_run>
	else
		sched_yield();
f010348d:	e8 71 01 00 00       	call   f0103603 <sched_yield>

f0103492 <t_divide>:
.text

/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */
TRAPHANDLER_NOEC(t_divide, T_DIVIDE)
f0103492:	6a 00                	push   $0x0
f0103494:	6a 00                	push   $0x0
f0103496:	e9 83 00 00 00       	jmp    f010351e <_alltraps>
f010349b:	90                   	nop

f010349c <t_debug>:
TRAPHANDLER_NOEC(t_debug, T_DEBUG)
f010349c:	6a 00                	push   $0x0
f010349e:	6a 01                	push   $0x1
f01034a0:	eb 7c                	jmp    f010351e <_alltraps>

f01034a2 <t_nmi>:
TRAPHANDLER_NOEC(t_nmi, T_NMI)
f01034a2:	6a 00                	push   $0x0
f01034a4:	6a 02                	push   $0x2
f01034a6:	eb 76                	jmp    f010351e <_alltraps>

f01034a8 <t_brkpt>:
TRAPHANDLER_NOEC(t_brkpt, T_BRKPT)
f01034a8:	6a 00                	push   $0x0
f01034aa:	6a 03                	push   $0x3
f01034ac:	eb 70                	jmp    f010351e <_alltraps>

f01034ae <t_oflow>:
TRAPHANDLER_NOEC(t_oflow, T_OFLOW)
f01034ae:	6a 00                	push   $0x0
f01034b0:	6a 04                	push   $0x4
f01034b2:	eb 6a                	jmp    f010351e <_alltraps>

f01034b4 <t_bound>:
TRAPHANDLER_NOEC(t_bound, T_BOUND)
f01034b4:	6a 00                	push   $0x0
f01034b6:	6a 05                	push   $0x5
f01034b8:	eb 64                	jmp    f010351e <_alltraps>

f01034ba <t_illop>:
TRAPHANDLER_NOEC(t_illop, T_ILLOP)
f01034ba:	6a 00                	push   $0x0
f01034bc:	6a 06                	push   $0x6
f01034be:	eb 5e                	jmp    f010351e <_alltraps>

f01034c0 <t_device>:
TRAPHANDLER_NOEC(t_device, T_DEVICE)
f01034c0:	6a 00                	push   $0x0
f01034c2:	6a 07                	push   $0x7
f01034c4:	eb 58                	jmp    f010351e <_alltraps>

f01034c6 <t_dblflt>:
TRAPHANDLER(t_dblflt, T_DBLFLT)
f01034c6:	6a 08                	push   $0x8
f01034c8:	eb 54                	jmp    f010351e <_alltraps>

f01034ca <t_tss>:
TRAPHANDLER(t_tss, T_TSS)
f01034ca:	6a 0a                	push   $0xa
f01034cc:	eb 50                	jmp    f010351e <_alltraps>

f01034ce <t_segnp>:
TRAPHANDLER(t_segnp, T_SEGNP)
f01034ce:	6a 0b                	push   $0xb
f01034d0:	eb 4c                	jmp    f010351e <_alltraps>

f01034d2 <t_stack>:
TRAPHANDLER(t_stack, T_STACK)
f01034d2:	6a 0c                	push   $0xc
f01034d4:	eb 48                	jmp    f010351e <_alltraps>

f01034d6 <t_gpflt>:
TRAPHANDLER(t_gpflt, T_GPFLT)
f01034d6:	6a 0d                	push   $0xd
f01034d8:	eb 44                	jmp    f010351e <_alltraps>

f01034da <t_pgflt>:
TRAPHANDLER(t_pgflt, T_PGFLT)
f01034da:	6a 0e                	push   $0xe
f01034dc:	eb 40                	jmp    f010351e <_alltraps>

f01034de <t_fperr>:
TRAPHANDLER_NOEC(t_fperr, T_FPERR)
f01034de:	6a 00                	push   $0x0
f01034e0:	6a 10                	push   $0x10
f01034e2:	eb 3a                	jmp    f010351e <_alltraps>

f01034e4 <t_align>:
TRAPHANDLER(t_align, T_ALIGN)
f01034e4:	6a 11                	push   $0x11
f01034e6:	eb 36                	jmp    f010351e <_alltraps>

f01034e8 <t_mchk>:
TRAPHANDLER_NOEC(t_mchk, T_MCHK)
f01034e8:	6a 00                	push   $0x0
f01034ea:	6a 12                	push   $0x12
f01034ec:	eb 30                	jmp    f010351e <_alltraps>

f01034ee <t_simderr>:
TRAPHANDLER_NOEC(t_simderr, T_SIMDERR)
f01034ee:	6a 00                	push   $0x0
f01034f0:	6a 13                	push   $0x13
f01034f2:	eb 2a                	jmp    f010351e <_alltraps>

f01034f4 <t_syscall>:
TRAPHANDLER_NOEC(t_syscall, T_SYSCALL)
f01034f4:	6a 00                	push   $0x0
f01034f6:	6a 30                	push   $0x30
f01034f8:	eb 24                	jmp    f010351e <_alltraps>

f01034fa <irq_timer>:
TRAPHANDLER_NOEC(irq_timer, IRQ_OFFSET + IRQ_TIMER)
f01034fa:	6a 00                	push   $0x0
f01034fc:	6a 20                	push   $0x20
f01034fe:	eb 1e                	jmp    f010351e <_alltraps>

f0103500 <irq_kbd>:
TRAPHANDLER_NOEC(irq_kbd, IRQ_OFFSET + IRQ_KBD)
f0103500:	6a 00                	push   $0x0
f0103502:	6a 21                	push   $0x21
f0103504:	eb 18                	jmp    f010351e <_alltraps>

f0103506 <irq_serial>:
TRAPHANDLER_NOEC(irq_serial, IRQ_OFFSET + IRQ_SERIAL)
f0103506:	6a 00                	push   $0x0
f0103508:	6a 24                	push   $0x24
f010350a:	eb 12                	jmp    f010351e <_alltraps>

f010350c <irq_spurious>:
TRAPHANDLER_NOEC(irq_spurious, IRQ_OFFSET + IRQ_SPURIOUS)
f010350c:	6a 00                	push   $0x0
f010350e:	6a 27                	push   $0x27
f0103510:	eb 0c                	jmp    f010351e <_alltraps>

f0103512 <irq_ide>:
TRAPHANDLER_NOEC(irq_ide, IRQ_OFFSET + IRQ_IDE)
f0103512:	6a 00                	push   $0x0
f0103514:	6a 2e                	push   $0x2e
f0103516:	eb 06                	jmp    f010351e <_alltraps>

f0103518 <irq_error>:
TRAPHANDLER_NOEC(irq_error, IRQ_OFFSET + IRQ_ERROR)
f0103518:	6a 00                	push   $0x0
f010351a:	6a 33                	push   $0x33
f010351c:	eb 00                	jmp    f010351e <_alltraps>

f010351e <_alltraps>:
/*
 * Lab 3: Your code here for _alltraps
 */
_alltraps:
	# Build trap frame.
	pushl %ds
f010351e:	1e                   	push   %ds
	pushl %es
f010351f:	06                   	push   %es
	pushal	
f0103520:	60                   	pusha  

	movw $(GD_KD), %ax
f0103521:	66 b8 10 00          	mov    $0x10,%ax
	movw %ax, %ds
f0103525:	8e d8                	mov    %eax,%ds
	movw %ax, %es
f0103527:	8e c0                	mov    %eax,%es

	pushl %esp
f0103529:	54                   	push   %esp
	call trap
f010352a:	e8 51 fd ff ff       	call   f0103280 <trap>

f010352f <sched_halt>:
// Halt this CPU when there is nothing to do. Wait until the
// timer interrupt wakes it up. This function never returns.
//
void
sched_halt(void)
{
f010352f:	55                   	push   %ebp
f0103530:	89 e5                	mov    %esp,%ebp
f0103532:	83 ec 08             	sub    $0x8,%esp
f0103535:	a1 44 82 22 f0       	mov    0xf0228244,%eax
f010353a:	8d 50 54             	lea    0x54(%eax),%edx
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
f010353d:	b9 00 00 00 00       	mov    $0x0,%ecx
		if ((envs[i].env_status == ENV_RUNNABLE ||
f0103542:	8b 02                	mov    (%edx),%eax
f0103544:	83 e8 01             	sub    $0x1,%eax
f0103547:	83 f8 02             	cmp    $0x2,%eax
f010354a:	76 10                	jbe    f010355c <sched_halt+0x2d>
{
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
f010354c:	83 c1 01             	add    $0x1,%ecx
f010354f:	83 c2 7c             	add    $0x7c,%edx
f0103552:	81 f9 00 04 00 00    	cmp    $0x400,%ecx
f0103558:	75 e8                	jne    f0103542 <sched_halt+0x13>
f010355a:	eb 08                	jmp    f0103564 <sched_halt+0x35>
		if ((envs[i].env_status == ENV_RUNNABLE ||
		     envs[i].env_status == ENV_RUNNING ||
		     envs[i].env_status == ENV_DYING))
			break;
	}
	if (i == NENV) {
f010355c:	81 f9 00 04 00 00    	cmp    $0x400,%ecx
f0103562:	75 1f                	jne    f0103583 <sched_halt+0x54>
		cprintf("No runnable environments in the system!\n");
f0103564:	83 ec 0c             	sub    $0xc,%esp
f0103567:	68 70 62 10 f0       	push   $0xf0106270
f010356c:	e8 cc f5 ff ff       	call   f0102b3d <cprintf>
f0103571:	83 c4 10             	add    $0x10,%esp
		while (1)
			monitor(NULL);
f0103574:	83 ec 0c             	sub    $0xc,%esp
f0103577:	6a 00                	push   $0x0
f0103579:	e8 5b d3 ff ff       	call   f01008d9 <monitor>
f010357e:	83 c4 10             	add    $0x10,%esp
f0103581:	eb f1                	jmp    f0103574 <sched_halt+0x45>
	}

	// Mark that no environment is running on this CPU
	curenv = NULL;
f0103583:	e8 5e 13 00 00       	call   f01048e6 <cpunum>
f0103588:	6b c0 74             	imul   $0x74,%eax,%eax
f010358b:	c7 80 28 90 22 f0 00 	movl   $0x0,-0xfdd6fd8(%eax)
f0103592:	00 00 00 
	lcr3(PADDR(kern_pgdir));
f0103595:	a1 0c 8f 22 f0       	mov    0xf0228f0c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010359a:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010359f:	77 12                	ja     f01035b3 <sched_halt+0x84>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01035a1:	50                   	push   %eax
f01035a2:	68 c8 4f 10 f0       	push   $0xf0104fc8
f01035a7:	6a 3d                	push   $0x3d
f01035a9:	68 99 62 10 f0       	push   $0xf0106299
f01035ae:	e8 8d ca ff ff       	call   f0100040 <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f01035b3:	05 00 00 00 10       	add    $0x10000000,%eax
f01035b8:	0f 22 d8             	mov    %eax,%cr3

	// Mark that this CPU is in the HALT state, so that when
	// timer interupts come in, we know we should re-acquire the
	// big kernel lock
	xchg(&thiscpu->cpu_status, CPU_HALTED);
f01035bb:	e8 26 13 00 00       	call   f01048e6 <cpunum>
f01035c0:	6b d0 74             	imul   $0x74,%eax,%edx
f01035c3:	81 c2 20 90 22 f0    	add    $0xf0229020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"
f01035c9:	b8 02 00 00 00       	mov    $0x2,%eax
f01035ce:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
}

static inline void
unlock_kernel(void)
{
	spin_unlock(&kernel_lock);
f01035d2:	83 ec 0c             	sub    $0xc,%esp
f01035d5:	68 a0 d3 11 f0       	push   $0xf011d3a0
f01035da:	e8 12 16 00 00       	call   f0104bf1 <spin_unlock>

	// Normally we wouldn't need to do this, but QEMU only runs
	// one CPU at a time and has a long time-slice.  Without the
	// pause, this CPU is likely to reacquire the lock before
	// another CPU has even been given a chance to acquire it.
	asm volatile("pause");
f01035df:	f3 90                	pause  
		"pushl $0\n"
		"sti\n"
		"1:\n"
		"hlt\n"
		"jmp 1b\n"
	: : "a" (thiscpu->cpu_ts.ts_esp0));
f01035e1:	e8 00 13 00 00       	call   f01048e6 <cpunum>
f01035e6:	6b c0 74             	imul   $0x74,%eax,%eax

	// Release the big kernel lock as if we were "leaving" the kernel
	unlock_kernel();

	// Reset stack pointer, enable interrupts and then halt.
	asm volatile (
f01035e9:	8b 80 30 90 22 f0    	mov    -0xfdd6fd0(%eax),%eax
f01035ef:	bd 00 00 00 00       	mov    $0x0,%ebp
f01035f4:	89 c4                	mov    %eax,%esp
f01035f6:	6a 00                	push   $0x0
f01035f8:	6a 00                	push   $0x0
f01035fa:	fb                   	sti    
f01035fb:	f4                   	hlt    
f01035fc:	eb fd                	jmp    f01035fb <sched_halt+0xcc>
		"sti\n"
		"1:\n"
		"hlt\n"
		"jmp 1b\n"
	: : "a" (thiscpu->cpu_ts.ts_esp0));
}
f01035fe:	83 c4 10             	add    $0x10,%esp
f0103601:	c9                   	leave  
f0103602:	c3                   	ret    

f0103603 <sched_yield>:
void sched_halt(void);

// Choose a user environment to run and run it.
void
sched_yield(void)
{
f0103603:	55                   	push   %ebp
f0103604:	89 e5                	mov    %esp,%ebp
f0103606:	83 ec 08             	sub    $0x8,%esp
	// below to halt the cpu.

	// LAB 4: Your code here.

	// sched_halt never returns
	sched_halt();
f0103609:	e8 21 ff ff ff       	call   f010352f <sched_halt>
}
f010360e:	c9                   	leave  
f010360f:	c3                   	ret    

f0103610 <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f0103610:	55                   	push   %ebp
f0103611:	89 e5                	mov    %esp,%ebp
f0103613:	53                   	push   %ebx
f0103614:	83 ec 14             	sub    $0x14,%esp
f0103617:	8b 45 08             	mov    0x8(%ebp),%eax
	// Return any appropriate return value.
	// LAB 3: Your code here.

	//panic("syscall not implemented");

	switch (syscallno) {
f010361a:	83 f8 01             	cmp    $0x1,%eax
f010361d:	74 4f                	je     f010366e <syscall+0x5e>
f010361f:	83 f8 01             	cmp    $0x1,%eax
f0103622:	72 0f                	jb     f0103633 <syscall+0x23>
f0103624:	83 f8 02             	cmp    $0x2,%eax
f0103627:	74 4f                	je     f0103678 <syscall+0x68>
f0103629:	83 f8 03             	cmp    $0x3,%eax
f010362c:	74 60                	je     f010368e <syscall+0x7e>
f010362e:	e9 e3 00 00 00       	jmp    f0103716 <syscall+0x106>
{
	// Check that the user has permission to read memory [s, s+len).
	// Destroy the environment if not.

	// LAB 3: Your code here.
	user_mem_assert(curenv, s, len, PTE_U | PTE_W);
f0103633:	e8 ae 12 00 00       	call   f01048e6 <cpunum>
f0103638:	6a 06                	push   $0x6
f010363a:	ff 75 10             	pushl  0x10(%ebp)
f010363d:	ff 75 0c             	pushl  0xc(%ebp)
f0103640:	6b c0 74             	imul   $0x74,%eax,%eax
f0103643:	ff b0 28 90 22 f0    	pushl  -0xfdd6fd8(%eax)
f0103649:	e8 eb eb ff ff       	call   f0102239 <user_mem_assert>

	// Print the string supplied by the user.
	cprintf("%.*s", len, s);
f010364e:	83 c4 0c             	add    $0xc,%esp
f0103651:	ff 75 0c             	pushl  0xc(%ebp)
f0103654:	ff 75 10             	pushl  0x10(%ebp)
f0103657:	68 a6 62 10 f0       	push   $0xf01062a6
f010365c:	e8 dc f4 ff ff       	call   f0102b3d <cprintf>
f0103661:	83 c4 10             	add    $0x10,%esp
	//panic("syscall not implemented");

	switch (syscallno) {
		case SYS_cputs:
			sys_cputs((const char *) a1,(size_t) a2);
			return 0;
f0103664:	b8 00 00 00 00       	mov    $0x0,%eax
f0103669:	e9 ad 00 00 00       	jmp    f010371b <syscall+0x10b>
// Read a character from the system console without blocking.
// Returns the character, or 0 if there is no input waiting.
static int
sys_cgetc(void)
{
	return cons_getc();
f010366e:	e8 6a cf ff ff       	call   f01005dd <cons_getc>
	switch (syscallno) {
		case SYS_cputs:
			sys_cputs((const char *) a1,(size_t) a2);
			return 0;
		case SYS_cgetc:
			return sys_cgetc();
f0103673:	e9 a3 00 00 00       	jmp    f010371b <syscall+0x10b>

// Returns the current environment's envid.
static envid_t
sys_getenvid(void)
{
	return curenv->env_id;
f0103678:	e8 69 12 00 00       	call   f01048e6 <cpunum>
f010367d:	6b c0 74             	imul   $0x74,%eax,%eax
f0103680:	8b 80 28 90 22 f0    	mov    -0xfdd6fd8(%eax),%eax
f0103686:	8b 40 48             	mov    0x48(%eax),%eax
			sys_cputs((const char *) a1,(size_t) a2);
			return 0;
		case SYS_cgetc:
			return sys_cgetc();
		case SYS_getenvid:
			return sys_getenvid();
f0103689:	e9 8d 00 00 00       	jmp    f010371b <syscall+0x10b>
sys_env_destroy(envid_t envid)
{
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
f010368e:	83 ec 04             	sub    $0x4,%esp
f0103691:	6a 01                	push   $0x1
f0103693:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0103696:	50                   	push   %eax
f0103697:	ff 75 0c             	pushl  0xc(%ebp)
f010369a:	e8 4f ec ff ff       	call   f01022ee <envid2env>
f010369f:	83 c4 10             	add    $0x10,%esp
f01036a2:	85 c0                	test   %eax,%eax
f01036a4:	78 75                	js     f010371b <syscall+0x10b>
		return r;
	if (e == curenv)
f01036a6:	e8 3b 12 00 00       	call   f01048e6 <cpunum>
f01036ab:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01036ae:	6b c0 74             	imul   $0x74,%eax,%eax
f01036b1:	39 90 28 90 22 f0    	cmp    %edx,-0xfdd6fd8(%eax)
f01036b7:	75 23                	jne    f01036dc <syscall+0xcc>
		cprintf("[%08x] exiting gracefully\n", curenv->env_id);
f01036b9:	e8 28 12 00 00       	call   f01048e6 <cpunum>
f01036be:	83 ec 08             	sub    $0x8,%esp
f01036c1:	6b c0 74             	imul   $0x74,%eax,%eax
f01036c4:	8b 80 28 90 22 f0    	mov    -0xfdd6fd8(%eax),%eax
f01036ca:	ff 70 48             	pushl  0x48(%eax)
f01036cd:	68 ab 62 10 f0       	push   $0xf01062ab
f01036d2:	e8 66 f4 ff ff       	call   f0102b3d <cprintf>
f01036d7:	83 c4 10             	add    $0x10,%esp
f01036da:	eb 25                	jmp    f0103701 <syscall+0xf1>
	else
		cprintf("[%08x] destroying %08x\n", curenv->env_id, e->env_id);
f01036dc:	8b 5a 48             	mov    0x48(%edx),%ebx
f01036df:	e8 02 12 00 00       	call   f01048e6 <cpunum>
f01036e4:	83 ec 04             	sub    $0x4,%esp
f01036e7:	53                   	push   %ebx
f01036e8:	6b c0 74             	imul   $0x74,%eax,%eax
f01036eb:	8b 80 28 90 22 f0    	mov    -0xfdd6fd8(%eax),%eax
f01036f1:	ff 70 48             	pushl  0x48(%eax)
f01036f4:	68 c6 62 10 f0       	push   $0xf01062c6
f01036f9:	e8 3f f4 ff ff       	call   f0102b3d <cprintf>
f01036fe:	83 c4 10             	add    $0x10,%esp
	env_destroy(e);
f0103701:	83 ec 0c             	sub    $0xc,%esp
f0103704:	ff 75 f4             	pushl  -0xc(%ebp)
f0103707:	e8 6a f1 ff ff       	call   f0102876 <env_destroy>
f010370c:	83 c4 10             	add    $0x10,%esp
	return 0;
f010370f:	b8 00 00 00 00       	mov    $0x0,%eax
f0103714:	eb 05                	jmp    f010371b <syscall+0x10b>
		case SYS_getenvid:
			return sys_getenvid();
		case SYS_env_destroy:
			return sys_env_destroy((envid_t)a1);
		default:
			return -E_INVAL;
f0103716:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
	}
}
f010371b:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010371e:	c9                   	leave  
f010371f:	c3                   	ret    

f0103720 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0103720:	55                   	push   %ebp
f0103721:	89 e5                	mov    %esp,%ebp
f0103723:	57                   	push   %edi
f0103724:	56                   	push   %esi
f0103725:	53                   	push   %ebx
f0103726:	83 ec 14             	sub    $0x14,%esp
f0103729:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010372c:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f010372f:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0103732:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0103735:	8b 1a                	mov    (%edx),%ebx
f0103737:	8b 01                	mov    (%ecx),%eax
f0103739:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010373c:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0103743:	eb 7f                	jmp    f01037c4 <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f0103745:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0103748:	01 d8                	add    %ebx,%eax
f010374a:	89 c6                	mov    %eax,%esi
f010374c:	c1 ee 1f             	shr    $0x1f,%esi
f010374f:	01 c6                	add    %eax,%esi
f0103751:	d1 fe                	sar    %esi
f0103753:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0103756:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0103759:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f010375c:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f010375e:	eb 03                	jmp    f0103763 <stab_binsearch+0x43>
			m--;
f0103760:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0103763:	39 c3                	cmp    %eax,%ebx
f0103765:	7f 0d                	jg     f0103774 <stab_binsearch+0x54>
f0103767:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f010376b:	83 ea 0c             	sub    $0xc,%edx
f010376e:	39 f9                	cmp    %edi,%ecx
f0103770:	75 ee                	jne    f0103760 <stab_binsearch+0x40>
f0103772:	eb 05                	jmp    f0103779 <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0103774:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f0103777:	eb 4b                	jmp    f01037c4 <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0103779:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010377c:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010377f:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0103783:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0103786:	76 11                	jbe    f0103799 <stab_binsearch+0x79>
			*region_left = m;
f0103788:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f010378b:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f010378d:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0103790:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0103797:	eb 2b                	jmp    f01037c4 <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0103799:	39 55 0c             	cmp    %edx,0xc(%ebp)
f010379c:	73 14                	jae    f01037b2 <stab_binsearch+0x92>
			*region_right = m - 1;
f010379e:	83 e8 01             	sub    $0x1,%eax
f01037a1:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01037a4:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01037a7:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01037a9:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01037b0:	eb 12                	jmp    f01037c4 <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01037b2:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01037b5:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f01037b7:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f01037bb:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01037bd:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f01037c4:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f01037c7:	0f 8e 78 ff ff ff    	jle    f0103745 <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f01037cd:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f01037d1:	75 0f                	jne    f01037e2 <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f01037d3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01037d6:	8b 00                	mov    (%eax),%eax
f01037d8:	83 e8 01             	sub    $0x1,%eax
f01037db:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01037de:	89 06                	mov    %eax,(%esi)
f01037e0:	eb 2c                	jmp    f010380e <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01037e2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01037e5:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f01037e7:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01037ea:	8b 0e                	mov    (%esi),%ecx
f01037ec:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01037ef:	8b 75 ec             	mov    -0x14(%ebp),%esi
f01037f2:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01037f5:	eb 03                	jmp    f01037fa <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f01037f7:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01037fa:	39 c8                	cmp    %ecx,%eax
f01037fc:	7e 0b                	jle    f0103809 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f01037fe:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0103802:	83 ea 0c             	sub    $0xc,%edx
f0103805:	39 df                	cmp    %ebx,%edi
f0103807:	75 ee                	jne    f01037f7 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f0103809:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010380c:	89 06                	mov    %eax,(%esi)
	}
}
f010380e:	83 c4 14             	add    $0x14,%esp
f0103811:	5b                   	pop    %ebx
f0103812:	5e                   	pop    %esi
f0103813:	5f                   	pop    %edi
f0103814:	5d                   	pop    %ebp
f0103815:	c3                   	ret    

f0103816 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0103816:	55                   	push   %ebp
f0103817:	89 e5                	mov    %esp,%ebp
f0103819:	57                   	push   %edi
f010381a:	56                   	push   %esi
f010381b:	53                   	push   %ebx
f010381c:	83 ec 3c             	sub    $0x3c,%esp
f010381f:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103822:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0103825:	c7 03 de 62 10 f0    	movl   $0xf01062de,(%ebx)
	info->eip_line = 0;
f010382b:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0103832:	c7 43 08 de 62 10 f0 	movl   $0xf01062de,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0103839:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0103840:	89 7b 10             	mov    %edi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0103843:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f010384a:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f0103850:	0f 87 f6 00 00 00    	ja     f010394c <debuginfo_eip+0x136>
		const struct UserStabData *usd = (const struct UserStabData *) USTABDATA;

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, usd, sizeof(struct UserStabData), PTE_U) < 0) {
f0103856:	e8 8b 10 00 00       	call   f01048e6 <cpunum>
f010385b:	6a 04                	push   $0x4
f010385d:	6a 10                	push   $0x10
f010385f:	68 00 00 20 00       	push   $0x200000
f0103864:	6b c0 74             	imul   $0x74,%eax,%eax
f0103867:	ff b0 28 90 22 f0    	pushl  -0xfdd6fd8(%eax)
f010386d:	e8 41 e9 ff ff       	call   f01021b3 <user_mem_check>
f0103872:	83 c4 10             	add    $0x10,%esp
f0103875:	85 c0                	test   %eax,%eax
f0103877:	79 1f                	jns    f0103898 <debuginfo_eip+0x82>
			cprintf("debuginfo_eip: invalid usd addr %08x", usd);
f0103879:	83 ec 08             	sub    $0x8,%esp
f010387c:	68 00 00 20 00       	push   $0x200000
f0103881:	68 e8 62 10 f0       	push   $0xf01062e8
f0103886:	e8 b2 f2 ff ff       	call   f0102b3d <cprintf>
			return -1;
f010388b:	83 c4 10             	add    $0x10,%esp
f010388e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103893:	e9 97 02 00 00       	jmp    f0103b2f <debuginfo_eip+0x319>
		}

		stabs = usd->stabs;
f0103898:	a1 00 00 20 00       	mov    0x200000,%eax
f010389d:	89 45 c0             	mov    %eax,-0x40(%ebp)
		stab_end = usd->stab_end;
f01038a0:	8b 35 04 00 20 00    	mov    0x200004,%esi
		stabstr = usd->stabstr;
f01038a6:	8b 15 08 00 20 00    	mov    0x200008,%edx
f01038ac:	89 55 b8             	mov    %edx,-0x48(%ebp)
		stabstr_end = usd->stabstr_end;
f01038af:	8b 15 0c 00 20 00    	mov    0x20000c,%edx
f01038b5:	89 55 bc             	mov    %edx,-0x44(%ebp)

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, stabs, stab_end-stabs+1, PTE_U) < 0){
f01038b8:	e8 29 10 00 00       	call   f01048e6 <cpunum>
f01038bd:	6a 04                	push   $0x4
f01038bf:	89 f2                	mov    %esi,%edx
f01038c1:	8b 4d c0             	mov    -0x40(%ebp),%ecx
f01038c4:	29 ca                	sub    %ecx,%edx
f01038c6:	c1 fa 02             	sar    $0x2,%edx
f01038c9:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f01038cf:	83 c2 01             	add    $0x1,%edx
f01038d2:	52                   	push   %edx
f01038d3:	51                   	push   %ecx
f01038d4:	6b c0 74             	imul   $0x74,%eax,%eax
f01038d7:	ff b0 28 90 22 f0    	pushl  -0xfdd6fd8(%eax)
f01038dd:	e8 d1 e8 ff ff       	call   f01021b3 <user_mem_check>
f01038e2:	83 c4 10             	add    $0x10,%esp
f01038e5:	85 c0                	test   %eax,%eax
f01038e7:	79 1d                	jns    f0103906 <debuginfo_eip+0xf0>
			cprintf("debuginfo_eip: invalid stabs addr %08x", stabs);
f01038e9:	83 ec 08             	sub    $0x8,%esp
f01038ec:	ff 75 c0             	pushl  -0x40(%ebp)
f01038ef:	68 10 63 10 f0       	push   $0xf0106310
f01038f4:	e8 44 f2 ff ff       	call   f0102b3d <cprintf>
			return -1;
f01038f9:	83 c4 10             	add    $0x10,%esp
f01038fc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103901:	e9 29 02 00 00       	jmp    f0103b2f <debuginfo_eip+0x319>
		}
		if (user_mem_check(curenv, stabstr, stabstr_end-stabstr+1, PTE_U) < 0) {
f0103906:	e8 db 0f 00 00       	call   f01048e6 <cpunum>
f010390b:	6a 04                	push   $0x4
f010390d:	8b 55 bc             	mov    -0x44(%ebp),%edx
f0103910:	8b 4d b8             	mov    -0x48(%ebp),%ecx
f0103913:	29 ca                	sub    %ecx,%edx
f0103915:	83 c2 01             	add    $0x1,%edx
f0103918:	52                   	push   %edx
f0103919:	51                   	push   %ecx
f010391a:	6b c0 74             	imul   $0x74,%eax,%eax
f010391d:	ff b0 28 90 22 f0    	pushl  -0xfdd6fd8(%eax)
f0103923:	e8 8b e8 ff ff       	call   f01021b3 <user_mem_check>
f0103928:	83 c4 10             	add    $0x10,%esp
f010392b:	85 c0                	test   %eax,%eax
f010392d:	79 37                	jns    f0103966 <debuginfo_eip+0x150>
			cprintf("debuginfo_eip: invalid stabstr addr %08x", stabstr);
f010392f:	83 ec 08             	sub    $0x8,%esp
f0103932:	ff 75 b8             	pushl  -0x48(%ebp)
f0103935:	68 38 63 10 f0       	push   $0xf0106338
f010393a:	e8 fe f1 ff ff       	call   f0102b3d <cprintf>
			return -1;
f010393f:	83 c4 10             	add    $0x10,%esp
f0103942:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103947:	e9 e3 01 00 00       	jmp    f0103b2f <debuginfo_eip+0x319>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f010394c:	c7 45 bc 5e 2c 11 f0 	movl   $0xf0112c5e,-0x44(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f0103953:	c7 45 b8 cd f6 10 f0 	movl   $0xf010f6cd,-0x48(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f010395a:	be cc f6 10 f0       	mov    $0xf010f6cc,%esi
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f010395f:	c7 45 c0 34 68 10 f0 	movl   $0xf0106834,-0x40(%ebp)
			return -1;
		}
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0103966:	8b 45 bc             	mov    -0x44(%ebp),%eax
f0103969:	39 45 b8             	cmp    %eax,-0x48(%ebp)
f010396c:	0f 83 9c 01 00 00    	jae    f0103b0e <debuginfo_eip+0x2f8>
f0103972:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f0103976:	0f 85 99 01 00 00    	jne    f0103b15 <debuginfo_eip+0x2ff>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f010397c:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0103983:	2b 75 c0             	sub    -0x40(%ebp),%esi
f0103986:	c1 fe 02             	sar    $0x2,%esi
f0103989:	69 c6 ab aa aa aa    	imul   $0xaaaaaaab,%esi,%eax
f010398f:	83 e8 01             	sub    $0x1,%eax
f0103992:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0103995:	83 ec 08             	sub    $0x8,%esp
f0103998:	57                   	push   %edi
f0103999:	6a 64                	push   $0x64
f010399b:	8d 55 e0             	lea    -0x20(%ebp),%edx
f010399e:	89 d1                	mov    %edx,%ecx
f01039a0:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01039a3:	8b 75 c0             	mov    -0x40(%ebp),%esi
f01039a6:	89 f0                	mov    %esi,%eax
f01039a8:	e8 73 fd ff ff       	call   f0103720 <stab_binsearch>
	if (lfile == 0)
f01039ad:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01039b0:	83 c4 10             	add    $0x10,%esp
f01039b3:	85 c0                	test   %eax,%eax
f01039b5:	0f 84 61 01 00 00    	je     f0103b1c <debuginfo_eip+0x306>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f01039bb:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f01039be:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01039c1:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f01039c4:	83 ec 08             	sub    $0x8,%esp
f01039c7:	57                   	push   %edi
f01039c8:	6a 24                	push   $0x24
f01039ca:	8d 55 d8             	lea    -0x28(%ebp),%edx
f01039cd:	89 d1                	mov    %edx,%ecx
f01039cf:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01039d2:	89 f0                	mov    %esi,%eax
f01039d4:	e8 47 fd ff ff       	call   f0103720 <stab_binsearch>

	if (lfun <= rfun) {
f01039d9:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01039dc:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01039df:	83 c4 10             	add    $0x10,%esp
f01039e2:	39 d0                	cmp    %edx,%eax
f01039e4:	7f 2e                	jg     f0103a14 <debuginfo_eip+0x1fe>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f01039e6:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f01039e9:	8d 34 8e             	lea    (%esi,%ecx,4),%esi
f01039ec:	89 75 c4             	mov    %esi,-0x3c(%ebp)
f01039ef:	8b 36                	mov    (%esi),%esi
f01039f1:	8b 4d bc             	mov    -0x44(%ebp),%ecx
f01039f4:	2b 4d b8             	sub    -0x48(%ebp),%ecx
f01039f7:	39 ce                	cmp    %ecx,%esi
f01039f9:	73 06                	jae    f0103a01 <debuginfo_eip+0x1eb>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f01039fb:	03 75 b8             	add    -0x48(%ebp),%esi
f01039fe:	89 73 08             	mov    %esi,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0103a01:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f0103a04:	8b 4e 08             	mov    0x8(%esi),%ecx
f0103a07:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0103a0a:	29 cf                	sub    %ecx,%edi
		// Search within the function definition for the line number.
		lline = lfun;
f0103a0c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0103a0f:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0103a12:	eb 0f                	jmp    f0103a23 <debuginfo_eip+0x20d>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0103a14:	89 7b 10             	mov    %edi,0x10(%ebx)
		lline = lfile;
f0103a17:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103a1a:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0103a1d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103a20:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0103a23:	83 ec 08             	sub    $0x8,%esp
f0103a26:	6a 3a                	push   $0x3a
f0103a28:	ff 73 08             	pushl  0x8(%ebx)
f0103a2b:	e8 7a 08 00 00       	call   f01042aa <strfind>
f0103a30:	2b 43 08             	sub    0x8(%ebx),%eax
f0103a33:	89 43 0c             	mov    %eax,0xc(%ebx)
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.

	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);	
f0103a36:	83 c4 08             	add    $0x8,%esp
f0103a39:	57                   	push   %edi
f0103a3a:	6a 44                	push   $0x44
f0103a3c:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0103a3f:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0103a42:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0103a45:	89 f8                	mov    %edi,%eax
f0103a47:	e8 d4 fc ff ff       	call   f0103720 <stab_binsearch>
	if (lline > rline)
f0103a4c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103a4f:	83 c4 10             	add    $0x10,%esp
f0103a52:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0103a55:	0f 8f c8 00 00 00    	jg     f0103b23 <debuginfo_eip+0x30d>
		    return -1;
	info->eip_line = stabs[lline].n_desc;
f0103a5b:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103a5e:	8d 14 97             	lea    (%edi,%edx,4),%edx
f0103a61:	0f b7 4a 06          	movzwl 0x6(%edx),%ecx
f0103a65:	89 4b 04             	mov    %ecx,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0103a68:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103a6b:	c6 45 c4 00          	movb   $0x0,-0x3c(%ebp)
f0103a6f:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103a72:	eb 0a                	jmp    f0103a7e <debuginfo_eip+0x268>
f0103a74:	83 e8 01             	sub    $0x1,%eax
f0103a77:	83 ea 0c             	sub    $0xc,%edx
f0103a7a:	c6 45 c4 01          	movb   $0x1,-0x3c(%ebp)
f0103a7e:	39 c7                	cmp    %eax,%edi
f0103a80:	7e 05                	jle    f0103a87 <debuginfo_eip+0x271>
f0103a82:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103a85:	eb 47                	jmp    f0103ace <debuginfo_eip+0x2b8>
	       && stabs[lline].n_type != N_SOL
f0103a87:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0103a8b:	80 f9 84             	cmp    $0x84,%cl
f0103a8e:	75 0e                	jne    f0103a9e <debuginfo_eip+0x288>
f0103a90:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103a93:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f0103a97:	74 1c                	je     f0103ab5 <debuginfo_eip+0x29f>
f0103a99:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0103a9c:	eb 17                	jmp    f0103ab5 <debuginfo_eip+0x29f>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0103a9e:	80 f9 64             	cmp    $0x64,%cl
f0103aa1:	75 d1                	jne    f0103a74 <debuginfo_eip+0x25e>
f0103aa3:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f0103aa7:	74 cb                	je     f0103a74 <debuginfo_eip+0x25e>
f0103aa9:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103aac:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f0103ab0:	74 03                	je     f0103ab5 <debuginfo_eip+0x29f>
f0103ab2:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0103ab5:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0103ab8:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0103abb:	8b 14 87             	mov    (%edi,%eax,4),%edx
f0103abe:	8b 45 bc             	mov    -0x44(%ebp),%eax
f0103ac1:	8b 7d b8             	mov    -0x48(%ebp),%edi
f0103ac4:	29 f8                	sub    %edi,%eax
f0103ac6:	39 c2                	cmp    %eax,%edx
f0103ac8:	73 04                	jae    f0103ace <debuginfo_eip+0x2b8>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0103aca:	01 fa                	add    %edi,%edx
f0103acc:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103ace:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103ad1:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103ad4:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103ad9:	39 f2                	cmp    %esi,%edx
f0103adb:	7d 52                	jge    f0103b2f <debuginfo_eip+0x319>
		for (lline = lfun + 1;
f0103add:	83 c2 01             	add    $0x1,%edx
f0103ae0:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0103ae3:	89 d0                	mov    %edx,%eax
f0103ae5:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0103ae8:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0103aeb:	8d 14 97             	lea    (%edi,%edx,4),%edx
f0103aee:	eb 04                	jmp    f0103af4 <debuginfo_eip+0x2de>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0103af0:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0103af4:	39 c6                	cmp    %eax,%esi
f0103af6:	7e 32                	jle    f0103b2a <debuginfo_eip+0x314>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0103af8:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0103afc:	83 c0 01             	add    $0x1,%eax
f0103aff:	83 c2 0c             	add    $0xc,%edx
f0103b02:	80 f9 a0             	cmp    $0xa0,%cl
f0103b05:	74 e9                	je     f0103af0 <debuginfo_eip+0x2da>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103b07:	b8 00 00 00 00       	mov    $0x0,%eax
f0103b0c:	eb 21                	jmp    f0103b2f <debuginfo_eip+0x319>
		}
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0103b0e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103b13:	eb 1a                	jmp    f0103b2f <debuginfo_eip+0x319>
f0103b15:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103b1a:	eb 13                	jmp    f0103b2f <debuginfo_eip+0x319>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0103b1c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103b21:	eb 0c                	jmp    f0103b2f <debuginfo_eip+0x319>
	//	which one.
	// Your code here.

	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);	
	if (lline > rline)
		    return -1;
f0103b23:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103b28:	eb 05                	jmp    f0103b2f <debuginfo_eip+0x319>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103b2a:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103b2f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103b32:	5b                   	pop    %ebx
f0103b33:	5e                   	pop    %esi
f0103b34:	5f                   	pop    %edi
f0103b35:	5d                   	pop    %ebp
f0103b36:	c3                   	ret    

f0103b37 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0103b37:	55                   	push   %ebp
f0103b38:	89 e5                	mov    %esp,%ebp
f0103b3a:	57                   	push   %edi
f0103b3b:	56                   	push   %esi
f0103b3c:	53                   	push   %ebx
f0103b3d:	83 ec 1c             	sub    $0x1c,%esp
f0103b40:	89 c7                	mov    %eax,%edi
f0103b42:	89 d6                	mov    %edx,%esi
f0103b44:	8b 45 08             	mov    0x8(%ebp),%eax
f0103b47:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103b4a:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103b4d:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0103b50:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0103b53:	bb 00 00 00 00       	mov    $0x0,%ebx
f0103b58:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0103b5b:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0103b5e:	39 d3                	cmp    %edx,%ebx
f0103b60:	72 05                	jb     f0103b67 <printnum+0x30>
f0103b62:	39 45 10             	cmp    %eax,0x10(%ebp)
f0103b65:	77 45                	ja     f0103bac <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0103b67:	83 ec 0c             	sub    $0xc,%esp
f0103b6a:	ff 75 18             	pushl  0x18(%ebp)
f0103b6d:	8b 45 14             	mov    0x14(%ebp),%eax
f0103b70:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0103b73:	53                   	push   %ebx
f0103b74:	ff 75 10             	pushl  0x10(%ebp)
f0103b77:	83 ec 08             	sub    $0x8,%esp
f0103b7a:	ff 75 e4             	pushl  -0x1c(%ebp)
f0103b7d:	ff 75 e0             	pushl  -0x20(%ebp)
f0103b80:	ff 75 dc             	pushl  -0x24(%ebp)
f0103b83:	ff 75 d8             	pushl  -0x28(%ebp)
f0103b86:	e8 55 11 00 00       	call   f0104ce0 <__udivdi3>
f0103b8b:	83 c4 18             	add    $0x18,%esp
f0103b8e:	52                   	push   %edx
f0103b8f:	50                   	push   %eax
f0103b90:	89 f2                	mov    %esi,%edx
f0103b92:	89 f8                	mov    %edi,%eax
f0103b94:	e8 9e ff ff ff       	call   f0103b37 <printnum>
f0103b99:	83 c4 20             	add    $0x20,%esp
f0103b9c:	eb 18                	jmp    f0103bb6 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0103b9e:	83 ec 08             	sub    $0x8,%esp
f0103ba1:	56                   	push   %esi
f0103ba2:	ff 75 18             	pushl  0x18(%ebp)
f0103ba5:	ff d7                	call   *%edi
f0103ba7:	83 c4 10             	add    $0x10,%esp
f0103baa:	eb 03                	jmp    f0103baf <printnum+0x78>
f0103bac:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0103baf:	83 eb 01             	sub    $0x1,%ebx
f0103bb2:	85 db                	test   %ebx,%ebx
f0103bb4:	7f e8                	jg     f0103b9e <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0103bb6:	83 ec 08             	sub    $0x8,%esp
f0103bb9:	56                   	push   %esi
f0103bba:	83 ec 04             	sub    $0x4,%esp
f0103bbd:	ff 75 e4             	pushl  -0x1c(%ebp)
f0103bc0:	ff 75 e0             	pushl  -0x20(%ebp)
f0103bc3:	ff 75 dc             	pushl  -0x24(%ebp)
f0103bc6:	ff 75 d8             	pushl  -0x28(%ebp)
f0103bc9:	e8 42 12 00 00       	call   f0104e10 <__umoddi3>
f0103bce:	83 c4 14             	add    $0x14,%esp
f0103bd1:	0f be 80 61 63 10 f0 	movsbl -0xfef9c9f(%eax),%eax
f0103bd8:	50                   	push   %eax
f0103bd9:	ff d7                	call   *%edi
}
f0103bdb:	83 c4 10             	add    $0x10,%esp
f0103bde:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103be1:	5b                   	pop    %ebx
f0103be2:	5e                   	pop    %esi
f0103be3:	5f                   	pop    %edi
f0103be4:	5d                   	pop    %ebp
f0103be5:	c3                   	ret    

f0103be6 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0103be6:	55                   	push   %ebp
f0103be7:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0103be9:	83 fa 01             	cmp    $0x1,%edx
f0103bec:	7e 0e                	jle    f0103bfc <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0103bee:	8b 10                	mov    (%eax),%edx
f0103bf0:	8d 4a 08             	lea    0x8(%edx),%ecx
f0103bf3:	89 08                	mov    %ecx,(%eax)
f0103bf5:	8b 02                	mov    (%edx),%eax
f0103bf7:	8b 52 04             	mov    0x4(%edx),%edx
f0103bfa:	eb 22                	jmp    f0103c1e <getuint+0x38>
	else if (lflag)
f0103bfc:	85 d2                	test   %edx,%edx
f0103bfe:	74 10                	je     f0103c10 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0103c00:	8b 10                	mov    (%eax),%edx
f0103c02:	8d 4a 04             	lea    0x4(%edx),%ecx
f0103c05:	89 08                	mov    %ecx,(%eax)
f0103c07:	8b 02                	mov    (%edx),%eax
f0103c09:	ba 00 00 00 00       	mov    $0x0,%edx
f0103c0e:	eb 0e                	jmp    f0103c1e <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0103c10:	8b 10                	mov    (%eax),%edx
f0103c12:	8d 4a 04             	lea    0x4(%edx),%ecx
f0103c15:	89 08                	mov    %ecx,(%eax)
f0103c17:	8b 02                	mov    (%edx),%eax
f0103c19:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0103c1e:	5d                   	pop    %ebp
f0103c1f:	c3                   	ret    

f0103c20 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0103c20:	55                   	push   %ebp
f0103c21:	89 e5                	mov    %esp,%ebp
f0103c23:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0103c26:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0103c2a:	8b 10                	mov    (%eax),%edx
f0103c2c:	3b 50 04             	cmp    0x4(%eax),%edx
f0103c2f:	73 0a                	jae    f0103c3b <sprintputch+0x1b>
		*b->buf++ = ch;
f0103c31:	8d 4a 01             	lea    0x1(%edx),%ecx
f0103c34:	89 08                	mov    %ecx,(%eax)
f0103c36:	8b 45 08             	mov    0x8(%ebp),%eax
f0103c39:	88 02                	mov    %al,(%edx)
}
f0103c3b:	5d                   	pop    %ebp
f0103c3c:	c3                   	ret    

f0103c3d <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0103c3d:	55                   	push   %ebp
f0103c3e:	89 e5                	mov    %esp,%ebp
f0103c40:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0103c43:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0103c46:	50                   	push   %eax
f0103c47:	ff 75 10             	pushl  0x10(%ebp)
f0103c4a:	ff 75 0c             	pushl  0xc(%ebp)
f0103c4d:	ff 75 08             	pushl  0x8(%ebp)
f0103c50:	e8 05 00 00 00       	call   f0103c5a <vprintfmt>
	va_end(ap);
}
f0103c55:	83 c4 10             	add    $0x10,%esp
f0103c58:	c9                   	leave  
f0103c59:	c3                   	ret    

f0103c5a <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0103c5a:	55                   	push   %ebp
f0103c5b:	89 e5                	mov    %esp,%ebp
f0103c5d:	57                   	push   %edi
f0103c5e:	56                   	push   %esi
f0103c5f:	53                   	push   %ebx
f0103c60:	83 ec 2c             	sub    $0x2c,%esp
f0103c63:	8b 75 08             	mov    0x8(%ebp),%esi
f0103c66:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103c69:	8b 7d 10             	mov    0x10(%ebp),%edi
f0103c6c:	eb 12                	jmp    f0103c80 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0103c6e:	85 c0                	test   %eax,%eax
f0103c70:	0f 84 89 03 00 00    	je     f0103fff <vprintfmt+0x3a5>
				return;
			putch(ch, putdat);
f0103c76:	83 ec 08             	sub    $0x8,%esp
f0103c79:	53                   	push   %ebx
f0103c7a:	50                   	push   %eax
f0103c7b:	ff d6                	call   *%esi
f0103c7d:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0103c80:	83 c7 01             	add    $0x1,%edi
f0103c83:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0103c87:	83 f8 25             	cmp    $0x25,%eax
f0103c8a:	75 e2                	jne    f0103c6e <vprintfmt+0x14>
f0103c8c:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0103c90:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0103c97:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0103c9e:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0103ca5:	ba 00 00 00 00       	mov    $0x0,%edx
f0103caa:	eb 07                	jmp    f0103cb3 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103cac:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0103caf:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103cb3:	8d 47 01             	lea    0x1(%edi),%eax
f0103cb6:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103cb9:	0f b6 07             	movzbl (%edi),%eax
f0103cbc:	0f b6 c8             	movzbl %al,%ecx
f0103cbf:	83 e8 23             	sub    $0x23,%eax
f0103cc2:	3c 55                	cmp    $0x55,%al
f0103cc4:	0f 87 1a 03 00 00    	ja     f0103fe4 <vprintfmt+0x38a>
f0103cca:	0f b6 c0             	movzbl %al,%eax
f0103ccd:	ff 24 85 20 64 10 f0 	jmp    *-0xfef9be0(,%eax,4)
f0103cd4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0103cd7:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0103cdb:	eb d6                	jmp    f0103cb3 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103cdd:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103ce0:	b8 00 00 00 00       	mov    $0x0,%eax
f0103ce5:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0103ce8:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0103ceb:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f0103cef:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0103cf2:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0103cf5:	83 fa 09             	cmp    $0x9,%edx
f0103cf8:	77 39                	ja     f0103d33 <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0103cfa:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0103cfd:	eb e9                	jmp    f0103ce8 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0103cff:	8b 45 14             	mov    0x14(%ebp),%eax
f0103d02:	8d 48 04             	lea    0x4(%eax),%ecx
f0103d05:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0103d08:	8b 00                	mov    (%eax),%eax
f0103d0a:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103d0d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0103d10:	eb 27                	jmp    f0103d39 <vprintfmt+0xdf>
f0103d12:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103d15:	85 c0                	test   %eax,%eax
f0103d17:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103d1c:	0f 49 c8             	cmovns %eax,%ecx
f0103d1f:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103d22:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103d25:	eb 8c                	jmp    f0103cb3 <vprintfmt+0x59>
f0103d27:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0103d2a:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0103d31:	eb 80                	jmp    f0103cb3 <vprintfmt+0x59>
f0103d33:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0103d36:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0103d39:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0103d3d:	0f 89 70 ff ff ff    	jns    f0103cb3 <vprintfmt+0x59>
				width = precision, precision = -1;
f0103d43:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0103d46:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103d49:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0103d50:	e9 5e ff ff ff       	jmp    f0103cb3 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0103d55:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103d58:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0103d5b:	e9 53 ff ff ff       	jmp    f0103cb3 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0103d60:	8b 45 14             	mov    0x14(%ebp),%eax
f0103d63:	8d 50 04             	lea    0x4(%eax),%edx
f0103d66:	89 55 14             	mov    %edx,0x14(%ebp)
f0103d69:	83 ec 08             	sub    $0x8,%esp
f0103d6c:	53                   	push   %ebx
f0103d6d:	ff 30                	pushl  (%eax)
f0103d6f:	ff d6                	call   *%esi
			break;
f0103d71:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103d74:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0103d77:	e9 04 ff ff ff       	jmp    f0103c80 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0103d7c:	8b 45 14             	mov    0x14(%ebp),%eax
f0103d7f:	8d 50 04             	lea    0x4(%eax),%edx
f0103d82:	89 55 14             	mov    %edx,0x14(%ebp)
f0103d85:	8b 00                	mov    (%eax),%eax
f0103d87:	99                   	cltd   
f0103d88:	31 d0                	xor    %edx,%eax
f0103d8a:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0103d8c:	83 f8 08             	cmp    $0x8,%eax
f0103d8f:	7f 0b                	jg     f0103d9c <vprintfmt+0x142>
f0103d91:	8b 14 85 80 65 10 f0 	mov    -0xfef9a80(,%eax,4),%edx
f0103d98:	85 d2                	test   %edx,%edx
f0103d9a:	75 18                	jne    f0103db4 <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f0103d9c:	50                   	push   %eax
f0103d9d:	68 79 63 10 f0       	push   $0xf0106379
f0103da2:	53                   	push   %ebx
f0103da3:	56                   	push   %esi
f0103da4:	e8 94 fe ff ff       	call   f0103c3d <printfmt>
f0103da9:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103dac:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0103daf:	e9 cc fe ff ff       	jmp    f0103c80 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0103db4:	52                   	push   %edx
f0103db5:	68 60 5b 10 f0       	push   $0xf0105b60
f0103dba:	53                   	push   %ebx
f0103dbb:	56                   	push   %esi
f0103dbc:	e8 7c fe ff ff       	call   f0103c3d <printfmt>
f0103dc1:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103dc4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103dc7:	e9 b4 fe ff ff       	jmp    f0103c80 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0103dcc:	8b 45 14             	mov    0x14(%ebp),%eax
f0103dcf:	8d 50 04             	lea    0x4(%eax),%edx
f0103dd2:	89 55 14             	mov    %edx,0x14(%ebp)
f0103dd5:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0103dd7:	85 ff                	test   %edi,%edi
f0103dd9:	b8 72 63 10 f0       	mov    $0xf0106372,%eax
f0103dde:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0103de1:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0103de5:	0f 8e 94 00 00 00    	jle    f0103e7f <vprintfmt+0x225>
f0103deb:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0103def:	0f 84 98 00 00 00    	je     f0103e8d <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
f0103df5:	83 ec 08             	sub    $0x8,%esp
f0103df8:	ff 75 d0             	pushl  -0x30(%ebp)
f0103dfb:	57                   	push   %edi
f0103dfc:	e8 5f 03 00 00       	call   f0104160 <strnlen>
f0103e01:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0103e04:	29 c1                	sub    %eax,%ecx
f0103e06:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0103e09:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0103e0c:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0103e10:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103e13:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0103e16:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0103e18:	eb 0f                	jmp    f0103e29 <vprintfmt+0x1cf>
					putch(padc, putdat);
f0103e1a:	83 ec 08             	sub    $0x8,%esp
f0103e1d:	53                   	push   %ebx
f0103e1e:	ff 75 e0             	pushl  -0x20(%ebp)
f0103e21:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0103e23:	83 ef 01             	sub    $0x1,%edi
f0103e26:	83 c4 10             	add    $0x10,%esp
f0103e29:	85 ff                	test   %edi,%edi
f0103e2b:	7f ed                	jg     f0103e1a <vprintfmt+0x1c0>
f0103e2d:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0103e30:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0103e33:	85 c9                	test   %ecx,%ecx
f0103e35:	b8 00 00 00 00       	mov    $0x0,%eax
f0103e3a:	0f 49 c1             	cmovns %ecx,%eax
f0103e3d:	29 c1                	sub    %eax,%ecx
f0103e3f:	89 75 08             	mov    %esi,0x8(%ebp)
f0103e42:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0103e45:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103e48:	89 cb                	mov    %ecx,%ebx
f0103e4a:	eb 4d                	jmp    f0103e99 <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0103e4c:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0103e50:	74 1b                	je     f0103e6d <vprintfmt+0x213>
f0103e52:	0f be c0             	movsbl %al,%eax
f0103e55:	83 e8 20             	sub    $0x20,%eax
f0103e58:	83 f8 5e             	cmp    $0x5e,%eax
f0103e5b:	76 10                	jbe    f0103e6d <vprintfmt+0x213>
					putch('?', putdat);
f0103e5d:	83 ec 08             	sub    $0x8,%esp
f0103e60:	ff 75 0c             	pushl  0xc(%ebp)
f0103e63:	6a 3f                	push   $0x3f
f0103e65:	ff 55 08             	call   *0x8(%ebp)
f0103e68:	83 c4 10             	add    $0x10,%esp
f0103e6b:	eb 0d                	jmp    f0103e7a <vprintfmt+0x220>
				else
					putch(ch, putdat);
f0103e6d:	83 ec 08             	sub    $0x8,%esp
f0103e70:	ff 75 0c             	pushl  0xc(%ebp)
f0103e73:	52                   	push   %edx
f0103e74:	ff 55 08             	call   *0x8(%ebp)
f0103e77:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0103e7a:	83 eb 01             	sub    $0x1,%ebx
f0103e7d:	eb 1a                	jmp    f0103e99 <vprintfmt+0x23f>
f0103e7f:	89 75 08             	mov    %esi,0x8(%ebp)
f0103e82:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0103e85:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103e88:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0103e8b:	eb 0c                	jmp    f0103e99 <vprintfmt+0x23f>
f0103e8d:	89 75 08             	mov    %esi,0x8(%ebp)
f0103e90:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0103e93:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103e96:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0103e99:	83 c7 01             	add    $0x1,%edi
f0103e9c:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0103ea0:	0f be d0             	movsbl %al,%edx
f0103ea3:	85 d2                	test   %edx,%edx
f0103ea5:	74 23                	je     f0103eca <vprintfmt+0x270>
f0103ea7:	85 f6                	test   %esi,%esi
f0103ea9:	78 a1                	js     f0103e4c <vprintfmt+0x1f2>
f0103eab:	83 ee 01             	sub    $0x1,%esi
f0103eae:	79 9c                	jns    f0103e4c <vprintfmt+0x1f2>
f0103eb0:	89 df                	mov    %ebx,%edi
f0103eb2:	8b 75 08             	mov    0x8(%ebp),%esi
f0103eb5:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103eb8:	eb 18                	jmp    f0103ed2 <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0103eba:	83 ec 08             	sub    $0x8,%esp
f0103ebd:	53                   	push   %ebx
f0103ebe:	6a 20                	push   $0x20
f0103ec0:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0103ec2:	83 ef 01             	sub    $0x1,%edi
f0103ec5:	83 c4 10             	add    $0x10,%esp
f0103ec8:	eb 08                	jmp    f0103ed2 <vprintfmt+0x278>
f0103eca:	89 df                	mov    %ebx,%edi
f0103ecc:	8b 75 08             	mov    0x8(%ebp),%esi
f0103ecf:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103ed2:	85 ff                	test   %edi,%edi
f0103ed4:	7f e4                	jg     f0103eba <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103ed6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103ed9:	e9 a2 fd ff ff       	jmp    f0103c80 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0103ede:	83 fa 01             	cmp    $0x1,%edx
f0103ee1:	7e 16                	jle    f0103ef9 <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f0103ee3:	8b 45 14             	mov    0x14(%ebp),%eax
f0103ee6:	8d 50 08             	lea    0x8(%eax),%edx
f0103ee9:	89 55 14             	mov    %edx,0x14(%ebp)
f0103eec:	8b 50 04             	mov    0x4(%eax),%edx
f0103eef:	8b 00                	mov    (%eax),%eax
f0103ef1:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103ef4:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0103ef7:	eb 32                	jmp    f0103f2b <vprintfmt+0x2d1>
	else if (lflag)
f0103ef9:	85 d2                	test   %edx,%edx
f0103efb:	74 18                	je     f0103f15 <vprintfmt+0x2bb>
		return va_arg(*ap, long);
f0103efd:	8b 45 14             	mov    0x14(%ebp),%eax
f0103f00:	8d 50 04             	lea    0x4(%eax),%edx
f0103f03:	89 55 14             	mov    %edx,0x14(%ebp)
f0103f06:	8b 00                	mov    (%eax),%eax
f0103f08:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103f0b:	89 c1                	mov    %eax,%ecx
f0103f0d:	c1 f9 1f             	sar    $0x1f,%ecx
f0103f10:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0103f13:	eb 16                	jmp    f0103f2b <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
f0103f15:	8b 45 14             	mov    0x14(%ebp),%eax
f0103f18:	8d 50 04             	lea    0x4(%eax),%edx
f0103f1b:	89 55 14             	mov    %edx,0x14(%ebp)
f0103f1e:	8b 00                	mov    (%eax),%eax
f0103f20:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103f23:	89 c1                	mov    %eax,%ecx
f0103f25:	c1 f9 1f             	sar    $0x1f,%ecx
f0103f28:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0103f2b:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0103f2e:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0103f31:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0103f36:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0103f3a:	79 74                	jns    f0103fb0 <vprintfmt+0x356>
				putch('-', putdat);
f0103f3c:	83 ec 08             	sub    $0x8,%esp
f0103f3f:	53                   	push   %ebx
f0103f40:	6a 2d                	push   $0x2d
f0103f42:	ff d6                	call   *%esi
				num = -(long long) num;
f0103f44:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0103f47:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103f4a:	f7 d8                	neg    %eax
f0103f4c:	83 d2 00             	adc    $0x0,%edx
f0103f4f:	f7 da                	neg    %edx
f0103f51:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0103f54:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0103f59:	eb 55                	jmp    f0103fb0 <vprintfmt+0x356>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0103f5b:	8d 45 14             	lea    0x14(%ebp),%eax
f0103f5e:	e8 83 fc ff ff       	call   f0103be6 <getuint>
			base = 10;
f0103f63:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0103f68:	eb 46                	jmp    f0103fb0 <vprintfmt+0x356>
		// (unsigned) octal
		case 'o':
			//putch('X', putdat);
			//putch('X', putdat);
			//putch('X', putdat);
			num = getuint(&ap, lflag);
f0103f6a:	8d 45 14             	lea    0x14(%ebp),%eax
f0103f6d:	e8 74 fc ff ff       	call   f0103be6 <getuint>
			base = 8;
f0103f72:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0103f77:	eb 37                	jmp    f0103fb0 <vprintfmt+0x356>

		// pointer
		case 'p':
			putch('0', putdat);
f0103f79:	83 ec 08             	sub    $0x8,%esp
f0103f7c:	53                   	push   %ebx
f0103f7d:	6a 30                	push   $0x30
f0103f7f:	ff d6                	call   *%esi
			putch('x', putdat);
f0103f81:	83 c4 08             	add    $0x8,%esp
f0103f84:	53                   	push   %ebx
f0103f85:	6a 78                	push   $0x78
f0103f87:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0103f89:	8b 45 14             	mov    0x14(%ebp),%eax
f0103f8c:	8d 50 04             	lea    0x4(%eax),%edx
f0103f8f:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0103f92:	8b 00                	mov    (%eax),%eax
f0103f94:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0103f99:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0103f9c:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0103fa1:	eb 0d                	jmp    f0103fb0 <vprintfmt+0x356>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0103fa3:	8d 45 14             	lea    0x14(%ebp),%eax
f0103fa6:	e8 3b fc ff ff       	call   f0103be6 <getuint>
			base = 16;
f0103fab:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0103fb0:	83 ec 0c             	sub    $0xc,%esp
f0103fb3:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0103fb7:	57                   	push   %edi
f0103fb8:	ff 75 e0             	pushl  -0x20(%ebp)
f0103fbb:	51                   	push   %ecx
f0103fbc:	52                   	push   %edx
f0103fbd:	50                   	push   %eax
f0103fbe:	89 da                	mov    %ebx,%edx
f0103fc0:	89 f0                	mov    %esi,%eax
f0103fc2:	e8 70 fb ff ff       	call   f0103b37 <printnum>
			break;
f0103fc7:	83 c4 20             	add    $0x20,%esp
f0103fca:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103fcd:	e9 ae fc ff ff       	jmp    f0103c80 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0103fd2:	83 ec 08             	sub    $0x8,%esp
f0103fd5:	53                   	push   %ebx
f0103fd6:	51                   	push   %ecx
f0103fd7:	ff d6                	call   *%esi
			break;
f0103fd9:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103fdc:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0103fdf:	e9 9c fc ff ff       	jmp    f0103c80 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0103fe4:	83 ec 08             	sub    $0x8,%esp
f0103fe7:	53                   	push   %ebx
f0103fe8:	6a 25                	push   $0x25
f0103fea:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0103fec:	83 c4 10             	add    $0x10,%esp
f0103fef:	eb 03                	jmp    f0103ff4 <vprintfmt+0x39a>
f0103ff1:	83 ef 01             	sub    $0x1,%edi
f0103ff4:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0103ff8:	75 f7                	jne    f0103ff1 <vprintfmt+0x397>
f0103ffa:	e9 81 fc ff ff       	jmp    f0103c80 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0103fff:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104002:	5b                   	pop    %ebx
f0104003:	5e                   	pop    %esi
f0104004:	5f                   	pop    %edi
f0104005:	5d                   	pop    %ebp
f0104006:	c3                   	ret    

f0104007 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0104007:	55                   	push   %ebp
f0104008:	89 e5                	mov    %esp,%ebp
f010400a:	83 ec 18             	sub    $0x18,%esp
f010400d:	8b 45 08             	mov    0x8(%ebp),%eax
f0104010:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0104013:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0104016:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f010401a:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f010401d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0104024:	85 c0                	test   %eax,%eax
f0104026:	74 26                	je     f010404e <vsnprintf+0x47>
f0104028:	85 d2                	test   %edx,%edx
f010402a:	7e 22                	jle    f010404e <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f010402c:	ff 75 14             	pushl  0x14(%ebp)
f010402f:	ff 75 10             	pushl  0x10(%ebp)
f0104032:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0104035:	50                   	push   %eax
f0104036:	68 20 3c 10 f0       	push   $0xf0103c20
f010403b:	e8 1a fc ff ff       	call   f0103c5a <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0104040:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0104043:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0104046:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104049:	83 c4 10             	add    $0x10,%esp
f010404c:	eb 05                	jmp    f0104053 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f010404e:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0104053:	c9                   	leave  
f0104054:	c3                   	ret    

f0104055 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0104055:	55                   	push   %ebp
f0104056:	89 e5                	mov    %esp,%ebp
f0104058:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f010405b:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f010405e:	50                   	push   %eax
f010405f:	ff 75 10             	pushl  0x10(%ebp)
f0104062:	ff 75 0c             	pushl  0xc(%ebp)
f0104065:	ff 75 08             	pushl  0x8(%ebp)
f0104068:	e8 9a ff ff ff       	call   f0104007 <vsnprintf>
	va_end(ap);

	return rc;
}
f010406d:	c9                   	leave  
f010406e:	c3                   	ret    

f010406f <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f010406f:	55                   	push   %ebp
f0104070:	89 e5                	mov    %esp,%ebp
f0104072:	57                   	push   %edi
f0104073:	56                   	push   %esi
f0104074:	53                   	push   %ebx
f0104075:	83 ec 0c             	sub    $0xc,%esp
f0104078:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010407b:	85 c0                	test   %eax,%eax
f010407d:	74 11                	je     f0104090 <readline+0x21>
		cprintf("%s", prompt);
f010407f:	83 ec 08             	sub    $0x8,%esp
f0104082:	50                   	push   %eax
f0104083:	68 60 5b 10 f0       	push   $0xf0105b60
f0104088:	e8 b0 ea ff ff       	call   f0102b3d <cprintf>
f010408d:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0104090:	83 ec 0c             	sub    $0xc,%esp
f0104093:	6a 00                	push   $0x0
f0104095:	e8 d3 c6 ff ff       	call   f010076d <iscons>
f010409a:	89 c7                	mov    %eax,%edi
f010409c:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010409f:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f01040a4:	e8 b3 c6 ff ff       	call   f010075c <getchar>
f01040a9:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01040ab:	85 c0                	test   %eax,%eax
f01040ad:	79 18                	jns    f01040c7 <readline+0x58>
			cprintf("read error: %e\n", c);
f01040af:	83 ec 08             	sub    $0x8,%esp
f01040b2:	50                   	push   %eax
f01040b3:	68 a4 65 10 f0       	push   $0xf01065a4
f01040b8:	e8 80 ea ff ff       	call   f0102b3d <cprintf>
			return NULL;
f01040bd:	83 c4 10             	add    $0x10,%esp
f01040c0:	b8 00 00 00 00       	mov    $0x0,%eax
f01040c5:	eb 79                	jmp    f0104140 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01040c7:	83 f8 08             	cmp    $0x8,%eax
f01040ca:	0f 94 c2             	sete   %dl
f01040cd:	83 f8 7f             	cmp    $0x7f,%eax
f01040d0:	0f 94 c0             	sete   %al
f01040d3:	08 c2                	or     %al,%dl
f01040d5:	74 1a                	je     f01040f1 <readline+0x82>
f01040d7:	85 f6                	test   %esi,%esi
f01040d9:	7e 16                	jle    f01040f1 <readline+0x82>
			if (echoing)
f01040db:	85 ff                	test   %edi,%edi
f01040dd:	74 0d                	je     f01040ec <readline+0x7d>
				cputchar('\b');
f01040df:	83 ec 0c             	sub    $0xc,%esp
f01040e2:	6a 08                	push   $0x8
f01040e4:	e8 63 c6 ff ff       	call   f010074c <cputchar>
f01040e9:	83 c4 10             	add    $0x10,%esp
			i--;
f01040ec:	83 ee 01             	sub    $0x1,%esi
f01040ef:	eb b3                	jmp    f01040a4 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01040f1:	83 fb 1f             	cmp    $0x1f,%ebx
f01040f4:	7e 23                	jle    f0104119 <readline+0xaa>
f01040f6:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01040fc:	7f 1b                	jg     f0104119 <readline+0xaa>
			if (echoing)
f01040fe:	85 ff                	test   %edi,%edi
f0104100:	74 0c                	je     f010410e <readline+0x9f>
				cputchar(c);
f0104102:	83 ec 0c             	sub    $0xc,%esp
f0104105:	53                   	push   %ebx
f0104106:	e8 41 c6 ff ff       	call   f010074c <cputchar>
f010410b:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f010410e:	88 9e 00 8b 22 f0    	mov    %bl,-0xfdd7500(%esi)
f0104114:	8d 76 01             	lea    0x1(%esi),%esi
f0104117:	eb 8b                	jmp    f01040a4 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0104119:	83 fb 0a             	cmp    $0xa,%ebx
f010411c:	74 05                	je     f0104123 <readline+0xb4>
f010411e:	83 fb 0d             	cmp    $0xd,%ebx
f0104121:	75 81                	jne    f01040a4 <readline+0x35>
			if (echoing)
f0104123:	85 ff                	test   %edi,%edi
f0104125:	74 0d                	je     f0104134 <readline+0xc5>
				cputchar('\n');
f0104127:	83 ec 0c             	sub    $0xc,%esp
f010412a:	6a 0a                	push   $0xa
f010412c:	e8 1b c6 ff ff       	call   f010074c <cputchar>
f0104131:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0104134:	c6 86 00 8b 22 f0 00 	movb   $0x0,-0xfdd7500(%esi)
			return buf;
f010413b:	b8 00 8b 22 f0       	mov    $0xf0228b00,%eax
		}
	}
}
f0104140:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104143:	5b                   	pop    %ebx
f0104144:	5e                   	pop    %esi
f0104145:	5f                   	pop    %edi
f0104146:	5d                   	pop    %ebp
f0104147:	c3                   	ret    

f0104148 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0104148:	55                   	push   %ebp
f0104149:	89 e5                	mov    %esp,%ebp
f010414b:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f010414e:	b8 00 00 00 00       	mov    $0x0,%eax
f0104153:	eb 03                	jmp    f0104158 <strlen+0x10>
		n++;
f0104155:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0104158:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f010415c:	75 f7                	jne    f0104155 <strlen+0xd>
		n++;
	return n;
}
f010415e:	5d                   	pop    %ebp
f010415f:	c3                   	ret    

f0104160 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0104160:	55                   	push   %ebp
f0104161:	89 e5                	mov    %esp,%ebp
f0104163:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104166:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0104169:	ba 00 00 00 00       	mov    $0x0,%edx
f010416e:	eb 03                	jmp    f0104173 <strnlen+0x13>
		n++;
f0104170:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0104173:	39 c2                	cmp    %eax,%edx
f0104175:	74 08                	je     f010417f <strnlen+0x1f>
f0104177:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f010417b:	75 f3                	jne    f0104170 <strnlen+0x10>
f010417d:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f010417f:	5d                   	pop    %ebp
f0104180:	c3                   	ret    

f0104181 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0104181:	55                   	push   %ebp
f0104182:	89 e5                	mov    %esp,%ebp
f0104184:	53                   	push   %ebx
f0104185:	8b 45 08             	mov    0x8(%ebp),%eax
f0104188:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f010418b:	89 c2                	mov    %eax,%edx
f010418d:	83 c2 01             	add    $0x1,%edx
f0104190:	83 c1 01             	add    $0x1,%ecx
f0104193:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0104197:	88 5a ff             	mov    %bl,-0x1(%edx)
f010419a:	84 db                	test   %bl,%bl
f010419c:	75 ef                	jne    f010418d <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f010419e:	5b                   	pop    %ebx
f010419f:	5d                   	pop    %ebp
f01041a0:	c3                   	ret    

f01041a1 <strcat>:

char *
strcat(char *dst, const char *src)
{
f01041a1:	55                   	push   %ebp
f01041a2:	89 e5                	mov    %esp,%ebp
f01041a4:	53                   	push   %ebx
f01041a5:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01041a8:	53                   	push   %ebx
f01041a9:	e8 9a ff ff ff       	call   f0104148 <strlen>
f01041ae:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f01041b1:	ff 75 0c             	pushl  0xc(%ebp)
f01041b4:	01 d8                	add    %ebx,%eax
f01041b6:	50                   	push   %eax
f01041b7:	e8 c5 ff ff ff       	call   f0104181 <strcpy>
	return dst;
}
f01041bc:	89 d8                	mov    %ebx,%eax
f01041be:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01041c1:	c9                   	leave  
f01041c2:	c3                   	ret    

f01041c3 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01041c3:	55                   	push   %ebp
f01041c4:	89 e5                	mov    %esp,%ebp
f01041c6:	56                   	push   %esi
f01041c7:	53                   	push   %ebx
f01041c8:	8b 75 08             	mov    0x8(%ebp),%esi
f01041cb:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01041ce:	89 f3                	mov    %esi,%ebx
f01041d0:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01041d3:	89 f2                	mov    %esi,%edx
f01041d5:	eb 0f                	jmp    f01041e6 <strncpy+0x23>
		*dst++ = *src;
f01041d7:	83 c2 01             	add    $0x1,%edx
f01041da:	0f b6 01             	movzbl (%ecx),%eax
f01041dd:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01041e0:	80 39 01             	cmpb   $0x1,(%ecx)
f01041e3:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01041e6:	39 da                	cmp    %ebx,%edx
f01041e8:	75 ed                	jne    f01041d7 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01041ea:	89 f0                	mov    %esi,%eax
f01041ec:	5b                   	pop    %ebx
f01041ed:	5e                   	pop    %esi
f01041ee:	5d                   	pop    %ebp
f01041ef:	c3                   	ret    

f01041f0 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01041f0:	55                   	push   %ebp
f01041f1:	89 e5                	mov    %esp,%ebp
f01041f3:	56                   	push   %esi
f01041f4:	53                   	push   %ebx
f01041f5:	8b 75 08             	mov    0x8(%ebp),%esi
f01041f8:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01041fb:	8b 55 10             	mov    0x10(%ebp),%edx
f01041fe:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0104200:	85 d2                	test   %edx,%edx
f0104202:	74 21                	je     f0104225 <strlcpy+0x35>
f0104204:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0104208:	89 f2                	mov    %esi,%edx
f010420a:	eb 09                	jmp    f0104215 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f010420c:	83 c2 01             	add    $0x1,%edx
f010420f:	83 c1 01             	add    $0x1,%ecx
f0104212:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0104215:	39 c2                	cmp    %eax,%edx
f0104217:	74 09                	je     f0104222 <strlcpy+0x32>
f0104219:	0f b6 19             	movzbl (%ecx),%ebx
f010421c:	84 db                	test   %bl,%bl
f010421e:	75 ec                	jne    f010420c <strlcpy+0x1c>
f0104220:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f0104222:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0104225:	29 f0                	sub    %esi,%eax
}
f0104227:	5b                   	pop    %ebx
f0104228:	5e                   	pop    %esi
f0104229:	5d                   	pop    %ebp
f010422a:	c3                   	ret    

f010422b <strcmp>:

int
strcmp(const char *p, const char *q)
{
f010422b:	55                   	push   %ebp
f010422c:	89 e5                	mov    %esp,%ebp
f010422e:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104231:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0104234:	eb 06                	jmp    f010423c <strcmp+0x11>
		p++, q++;
f0104236:	83 c1 01             	add    $0x1,%ecx
f0104239:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f010423c:	0f b6 01             	movzbl (%ecx),%eax
f010423f:	84 c0                	test   %al,%al
f0104241:	74 04                	je     f0104247 <strcmp+0x1c>
f0104243:	3a 02                	cmp    (%edx),%al
f0104245:	74 ef                	je     f0104236 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0104247:	0f b6 c0             	movzbl %al,%eax
f010424a:	0f b6 12             	movzbl (%edx),%edx
f010424d:	29 d0                	sub    %edx,%eax
}
f010424f:	5d                   	pop    %ebp
f0104250:	c3                   	ret    

f0104251 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0104251:	55                   	push   %ebp
f0104252:	89 e5                	mov    %esp,%ebp
f0104254:	53                   	push   %ebx
f0104255:	8b 45 08             	mov    0x8(%ebp),%eax
f0104258:	8b 55 0c             	mov    0xc(%ebp),%edx
f010425b:	89 c3                	mov    %eax,%ebx
f010425d:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0104260:	eb 06                	jmp    f0104268 <strncmp+0x17>
		n--, p++, q++;
f0104262:	83 c0 01             	add    $0x1,%eax
f0104265:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0104268:	39 d8                	cmp    %ebx,%eax
f010426a:	74 15                	je     f0104281 <strncmp+0x30>
f010426c:	0f b6 08             	movzbl (%eax),%ecx
f010426f:	84 c9                	test   %cl,%cl
f0104271:	74 04                	je     f0104277 <strncmp+0x26>
f0104273:	3a 0a                	cmp    (%edx),%cl
f0104275:	74 eb                	je     f0104262 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0104277:	0f b6 00             	movzbl (%eax),%eax
f010427a:	0f b6 12             	movzbl (%edx),%edx
f010427d:	29 d0                	sub    %edx,%eax
f010427f:	eb 05                	jmp    f0104286 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0104281:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0104286:	5b                   	pop    %ebx
f0104287:	5d                   	pop    %ebp
f0104288:	c3                   	ret    

f0104289 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0104289:	55                   	push   %ebp
f010428a:	89 e5                	mov    %esp,%ebp
f010428c:	8b 45 08             	mov    0x8(%ebp),%eax
f010428f:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0104293:	eb 07                	jmp    f010429c <strchr+0x13>
		if (*s == c)
f0104295:	38 ca                	cmp    %cl,%dl
f0104297:	74 0f                	je     f01042a8 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0104299:	83 c0 01             	add    $0x1,%eax
f010429c:	0f b6 10             	movzbl (%eax),%edx
f010429f:	84 d2                	test   %dl,%dl
f01042a1:	75 f2                	jne    f0104295 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f01042a3:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01042a8:	5d                   	pop    %ebp
f01042a9:	c3                   	ret    

f01042aa <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01042aa:	55                   	push   %ebp
f01042ab:	89 e5                	mov    %esp,%ebp
f01042ad:	8b 45 08             	mov    0x8(%ebp),%eax
f01042b0:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01042b4:	eb 03                	jmp    f01042b9 <strfind+0xf>
f01042b6:	83 c0 01             	add    $0x1,%eax
f01042b9:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f01042bc:	38 ca                	cmp    %cl,%dl
f01042be:	74 04                	je     f01042c4 <strfind+0x1a>
f01042c0:	84 d2                	test   %dl,%dl
f01042c2:	75 f2                	jne    f01042b6 <strfind+0xc>
			break;
	return (char *) s;
}
f01042c4:	5d                   	pop    %ebp
f01042c5:	c3                   	ret    

f01042c6 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01042c6:	55                   	push   %ebp
f01042c7:	89 e5                	mov    %esp,%ebp
f01042c9:	57                   	push   %edi
f01042ca:	56                   	push   %esi
f01042cb:	53                   	push   %ebx
f01042cc:	8b 7d 08             	mov    0x8(%ebp),%edi
f01042cf:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01042d2:	85 c9                	test   %ecx,%ecx
f01042d4:	74 36                	je     f010430c <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01042d6:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01042dc:	75 28                	jne    f0104306 <memset+0x40>
f01042de:	f6 c1 03             	test   $0x3,%cl
f01042e1:	75 23                	jne    f0104306 <memset+0x40>
		c &= 0xFF;
f01042e3:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01042e7:	89 d3                	mov    %edx,%ebx
f01042e9:	c1 e3 08             	shl    $0x8,%ebx
f01042ec:	89 d6                	mov    %edx,%esi
f01042ee:	c1 e6 18             	shl    $0x18,%esi
f01042f1:	89 d0                	mov    %edx,%eax
f01042f3:	c1 e0 10             	shl    $0x10,%eax
f01042f6:	09 f0                	or     %esi,%eax
f01042f8:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f01042fa:	89 d8                	mov    %ebx,%eax
f01042fc:	09 d0                	or     %edx,%eax
f01042fe:	c1 e9 02             	shr    $0x2,%ecx
f0104301:	fc                   	cld    
f0104302:	f3 ab                	rep stos %eax,%es:(%edi)
f0104304:	eb 06                	jmp    f010430c <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0104306:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104309:	fc                   	cld    
f010430a:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f010430c:	89 f8                	mov    %edi,%eax
f010430e:	5b                   	pop    %ebx
f010430f:	5e                   	pop    %esi
f0104310:	5f                   	pop    %edi
f0104311:	5d                   	pop    %ebp
f0104312:	c3                   	ret    

f0104313 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0104313:	55                   	push   %ebp
f0104314:	89 e5                	mov    %esp,%ebp
f0104316:	57                   	push   %edi
f0104317:	56                   	push   %esi
f0104318:	8b 45 08             	mov    0x8(%ebp),%eax
f010431b:	8b 75 0c             	mov    0xc(%ebp),%esi
f010431e:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0104321:	39 c6                	cmp    %eax,%esi
f0104323:	73 35                	jae    f010435a <memmove+0x47>
f0104325:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0104328:	39 d0                	cmp    %edx,%eax
f010432a:	73 2e                	jae    f010435a <memmove+0x47>
		s += n;
		d += n;
f010432c:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010432f:	89 d6                	mov    %edx,%esi
f0104331:	09 fe                	or     %edi,%esi
f0104333:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0104339:	75 13                	jne    f010434e <memmove+0x3b>
f010433b:	f6 c1 03             	test   $0x3,%cl
f010433e:	75 0e                	jne    f010434e <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f0104340:	83 ef 04             	sub    $0x4,%edi
f0104343:	8d 72 fc             	lea    -0x4(%edx),%esi
f0104346:	c1 e9 02             	shr    $0x2,%ecx
f0104349:	fd                   	std    
f010434a:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010434c:	eb 09                	jmp    f0104357 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f010434e:	83 ef 01             	sub    $0x1,%edi
f0104351:	8d 72 ff             	lea    -0x1(%edx),%esi
f0104354:	fd                   	std    
f0104355:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0104357:	fc                   	cld    
f0104358:	eb 1d                	jmp    f0104377 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010435a:	89 f2                	mov    %esi,%edx
f010435c:	09 c2                	or     %eax,%edx
f010435e:	f6 c2 03             	test   $0x3,%dl
f0104361:	75 0f                	jne    f0104372 <memmove+0x5f>
f0104363:	f6 c1 03             	test   $0x3,%cl
f0104366:	75 0a                	jne    f0104372 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f0104368:	c1 e9 02             	shr    $0x2,%ecx
f010436b:	89 c7                	mov    %eax,%edi
f010436d:	fc                   	cld    
f010436e:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0104370:	eb 05                	jmp    f0104377 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0104372:	89 c7                	mov    %eax,%edi
f0104374:	fc                   	cld    
f0104375:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0104377:	5e                   	pop    %esi
f0104378:	5f                   	pop    %edi
f0104379:	5d                   	pop    %ebp
f010437a:	c3                   	ret    

f010437b <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f010437b:	55                   	push   %ebp
f010437c:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f010437e:	ff 75 10             	pushl  0x10(%ebp)
f0104381:	ff 75 0c             	pushl  0xc(%ebp)
f0104384:	ff 75 08             	pushl  0x8(%ebp)
f0104387:	e8 87 ff ff ff       	call   f0104313 <memmove>
}
f010438c:	c9                   	leave  
f010438d:	c3                   	ret    

f010438e <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f010438e:	55                   	push   %ebp
f010438f:	89 e5                	mov    %esp,%ebp
f0104391:	56                   	push   %esi
f0104392:	53                   	push   %ebx
f0104393:	8b 45 08             	mov    0x8(%ebp),%eax
f0104396:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104399:	89 c6                	mov    %eax,%esi
f010439b:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010439e:	eb 1a                	jmp    f01043ba <memcmp+0x2c>
		if (*s1 != *s2)
f01043a0:	0f b6 08             	movzbl (%eax),%ecx
f01043a3:	0f b6 1a             	movzbl (%edx),%ebx
f01043a6:	38 d9                	cmp    %bl,%cl
f01043a8:	74 0a                	je     f01043b4 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f01043aa:	0f b6 c1             	movzbl %cl,%eax
f01043ad:	0f b6 db             	movzbl %bl,%ebx
f01043b0:	29 d8                	sub    %ebx,%eax
f01043b2:	eb 0f                	jmp    f01043c3 <memcmp+0x35>
		s1++, s2++;
f01043b4:	83 c0 01             	add    $0x1,%eax
f01043b7:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01043ba:	39 f0                	cmp    %esi,%eax
f01043bc:	75 e2                	jne    f01043a0 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01043be:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01043c3:	5b                   	pop    %ebx
f01043c4:	5e                   	pop    %esi
f01043c5:	5d                   	pop    %ebp
f01043c6:	c3                   	ret    

f01043c7 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01043c7:	55                   	push   %ebp
f01043c8:	89 e5                	mov    %esp,%ebp
f01043ca:	53                   	push   %ebx
f01043cb:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f01043ce:	89 c1                	mov    %eax,%ecx
f01043d0:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f01043d3:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01043d7:	eb 0a                	jmp    f01043e3 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f01043d9:	0f b6 10             	movzbl (%eax),%edx
f01043dc:	39 da                	cmp    %ebx,%edx
f01043de:	74 07                	je     f01043e7 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01043e0:	83 c0 01             	add    $0x1,%eax
f01043e3:	39 c8                	cmp    %ecx,%eax
f01043e5:	72 f2                	jb     f01043d9 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01043e7:	5b                   	pop    %ebx
f01043e8:	5d                   	pop    %ebp
f01043e9:	c3                   	ret    

f01043ea <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01043ea:	55                   	push   %ebp
f01043eb:	89 e5                	mov    %esp,%ebp
f01043ed:	57                   	push   %edi
f01043ee:	56                   	push   %esi
f01043ef:	53                   	push   %ebx
f01043f0:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01043f3:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01043f6:	eb 03                	jmp    f01043fb <strtol+0x11>
		s++;
f01043f8:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01043fb:	0f b6 01             	movzbl (%ecx),%eax
f01043fe:	3c 20                	cmp    $0x20,%al
f0104400:	74 f6                	je     f01043f8 <strtol+0xe>
f0104402:	3c 09                	cmp    $0x9,%al
f0104404:	74 f2                	je     f01043f8 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0104406:	3c 2b                	cmp    $0x2b,%al
f0104408:	75 0a                	jne    f0104414 <strtol+0x2a>
		s++;
f010440a:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f010440d:	bf 00 00 00 00       	mov    $0x0,%edi
f0104412:	eb 11                	jmp    f0104425 <strtol+0x3b>
f0104414:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0104419:	3c 2d                	cmp    $0x2d,%al
f010441b:	75 08                	jne    f0104425 <strtol+0x3b>
		s++, neg = 1;
f010441d:	83 c1 01             	add    $0x1,%ecx
f0104420:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0104425:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f010442b:	75 15                	jne    f0104442 <strtol+0x58>
f010442d:	80 39 30             	cmpb   $0x30,(%ecx)
f0104430:	75 10                	jne    f0104442 <strtol+0x58>
f0104432:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0104436:	75 7c                	jne    f01044b4 <strtol+0xca>
		s += 2, base = 16;
f0104438:	83 c1 02             	add    $0x2,%ecx
f010443b:	bb 10 00 00 00       	mov    $0x10,%ebx
f0104440:	eb 16                	jmp    f0104458 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f0104442:	85 db                	test   %ebx,%ebx
f0104444:	75 12                	jne    f0104458 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0104446:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f010444b:	80 39 30             	cmpb   $0x30,(%ecx)
f010444e:	75 08                	jne    f0104458 <strtol+0x6e>
		s++, base = 8;
f0104450:	83 c1 01             	add    $0x1,%ecx
f0104453:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f0104458:	b8 00 00 00 00       	mov    $0x0,%eax
f010445d:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0104460:	0f b6 11             	movzbl (%ecx),%edx
f0104463:	8d 72 d0             	lea    -0x30(%edx),%esi
f0104466:	89 f3                	mov    %esi,%ebx
f0104468:	80 fb 09             	cmp    $0x9,%bl
f010446b:	77 08                	ja     f0104475 <strtol+0x8b>
			dig = *s - '0';
f010446d:	0f be d2             	movsbl %dl,%edx
f0104470:	83 ea 30             	sub    $0x30,%edx
f0104473:	eb 22                	jmp    f0104497 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f0104475:	8d 72 9f             	lea    -0x61(%edx),%esi
f0104478:	89 f3                	mov    %esi,%ebx
f010447a:	80 fb 19             	cmp    $0x19,%bl
f010447d:	77 08                	ja     f0104487 <strtol+0x9d>
			dig = *s - 'a' + 10;
f010447f:	0f be d2             	movsbl %dl,%edx
f0104482:	83 ea 57             	sub    $0x57,%edx
f0104485:	eb 10                	jmp    f0104497 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f0104487:	8d 72 bf             	lea    -0x41(%edx),%esi
f010448a:	89 f3                	mov    %esi,%ebx
f010448c:	80 fb 19             	cmp    $0x19,%bl
f010448f:	77 16                	ja     f01044a7 <strtol+0xbd>
			dig = *s - 'A' + 10;
f0104491:	0f be d2             	movsbl %dl,%edx
f0104494:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f0104497:	3b 55 10             	cmp    0x10(%ebp),%edx
f010449a:	7d 0b                	jge    f01044a7 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f010449c:	83 c1 01             	add    $0x1,%ecx
f010449f:	0f af 45 10          	imul   0x10(%ebp),%eax
f01044a3:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f01044a5:	eb b9                	jmp    f0104460 <strtol+0x76>

	if (endptr)
f01044a7:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01044ab:	74 0d                	je     f01044ba <strtol+0xd0>
		*endptr = (char *) s;
f01044ad:	8b 75 0c             	mov    0xc(%ebp),%esi
f01044b0:	89 0e                	mov    %ecx,(%esi)
f01044b2:	eb 06                	jmp    f01044ba <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01044b4:	85 db                	test   %ebx,%ebx
f01044b6:	74 98                	je     f0104450 <strtol+0x66>
f01044b8:	eb 9e                	jmp    f0104458 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f01044ba:	89 c2                	mov    %eax,%edx
f01044bc:	f7 da                	neg    %edx
f01044be:	85 ff                	test   %edi,%edi
f01044c0:	0f 45 c2             	cmovne %edx,%eax
}
f01044c3:	5b                   	pop    %ebx
f01044c4:	5e                   	pop    %esi
f01044c5:	5f                   	pop    %edi
f01044c6:	5d                   	pop    %ebp
f01044c7:	c3                   	ret    

f01044c8 <mpentry_start>:
.set PROT_MODE_DSEG, 0x10	# kernel data segment selector

.code16           
.globl mpentry_start
mpentry_start:
	cli            
f01044c8:	fa                   	cli    

	xorw    %ax, %ax
f01044c9:	31 c0                	xor    %eax,%eax
	movw    %ax, %ds
f01044cb:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f01044cd:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f01044cf:	8e d0                	mov    %eax,%ss

	lgdt    MPBOOTPHYS(gdtdesc)
f01044d1:	0f 01 16             	lgdtl  (%esi)
f01044d4:	74 70                	je     f0104546 <mpsearch1+0x3>
	movl    %cr0, %eax
f01044d6:	0f 20 c0             	mov    %cr0,%eax
	orl     $CR0_PE, %eax
f01044d9:	66 83 c8 01          	or     $0x1,%ax
	movl    %eax, %cr0
f01044dd:	0f 22 c0             	mov    %eax,%cr0

	ljmpl   $(PROT_MODE_CSEG), $(MPBOOTPHYS(start32))
f01044e0:	66 ea 20 70 00 00    	ljmpw  $0x0,$0x7020
f01044e6:	08 00                	or     %al,(%eax)

f01044e8 <start32>:

.code32
start32:
	movw    $(PROT_MODE_DSEG), %ax
f01044e8:	66 b8 10 00          	mov    $0x10,%ax
	movw    %ax, %ds
f01044ec:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f01044ee:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f01044f0:	8e d0                	mov    %eax,%ss
	movw    $0, %ax
f01044f2:	66 b8 00 00          	mov    $0x0,%ax
	movw    %ax, %fs
f01044f6:	8e e0                	mov    %eax,%fs
	movw    %ax, %gs
f01044f8:	8e e8                	mov    %eax,%gs

	# Set up initial page table. We cannot use kern_pgdir yet because
	# we are still running at a low EIP.
	movl    $(RELOC(entry_pgdir)), %eax
f01044fa:	b8 00 b0 11 00       	mov    $0x11b000,%eax
	movl    %eax, %cr3
f01044ff:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl    %cr0, %eax
f0104502:	0f 20 c0             	mov    %cr0,%eax
	orl     $(CR0_PE|CR0_PG|CR0_WP), %eax
f0104505:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl    %eax, %cr0
f010450a:	0f 22 c0             	mov    %eax,%cr0

	# Switch to the per-cpu stack allocated in boot_aps()
	movl    mpentry_kstack, %esp
f010450d:	8b 25 04 8f 22 f0    	mov    0xf0228f04,%esp
	movl    $0x0, %ebp       # nuke frame pointer
f0104513:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Call mp_main().  (Exercise for the reader: why the indirect call?)
	movl    $mp_main, %eax
f0104518:	b8 a7 01 10 f0       	mov    $0xf01001a7,%eax
	call    *%eax
f010451d:	ff d0                	call   *%eax

f010451f <spin>:

	# If mp_main returns (it shouldn't), loop.
spin:
	jmp     spin
f010451f:	eb fe                	jmp    f010451f <spin>
f0104521:	8d 76 00             	lea    0x0(%esi),%esi

f0104524 <gdt>:
	...
f010452c:	ff                   	(bad)  
f010452d:	ff 00                	incl   (%eax)
f010452f:	00 00                	add    %al,(%eax)
f0104531:	9a cf 00 ff ff 00 00 	lcall  $0x0,$0xffff00cf
f0104538:	00                   	.byte 0x0
f0104539:	92                   	xchg   %eax,%edx
f010453a:	cf                   	iret   
	...

f010453c <gdtdesc>:
f010453c:	17                   	pop    %ss
f010453d:	00 5c 70 00          	add    %bl,0x0(%eax,%esi,2)
	...

f0104542 <mpentry_end>:
	.word   0x17				# sizeof(gdt) - 1
	.long   MPBOOTPHYS(gdt)			# address gdt

.globl mpentry_end
mpentry_end:
	nop
f0104542:	90                   	nop

f0104543 <mpsearch1>:
}

// Look for an MP structure in the len bytes at physical address addr.
static struct mp *
mpsearch1(physaddr_t a, int len)
{
f0104543:	55                   	push   %ebp
f0104544:	89 e5                	mov    %esp,%ebp
f0104546:	57                   	push   %edi
f0104547:	56                   	push   %esi
f0104548:	53                   	push   %ebx
f0104549:	83 ec 0c             	sub    $0xc,%esp
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010454c:	8b 0d 08 8f 22 f0    	mov    0xf0228f08,%ecx
f0104552:	89 c3                	mov    %eax,%ebx
f0104554:	c1 eb 0c             	shr    $0xc,%ebx
f0104557:	39 cb                	cmp    %ecx,%ebx
f0104559:	72 12                	jb     f010456d <mpsearch1+0x2a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010455b:	50                   	push   %eax
f010455c:	68 a4 4f 10 f0       	push   $0xf0104fa4
f0104561:	6a 57                	push   $0x57
f0104563:	68 41 67 10 f0       	push   $0xf0106741
f0104568:	e8 d3 ba ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f010456d:	8d 98 00 00 00 f0    	lea    -0x10000000(%eax),%ebx
	struct mp *mp = KADDR(a), *end = KADDR(a + len);
f0104573:	01 d0                	add    %edx,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0104575:	89 c2                	mov    %eax,%edx
f0104577:	c1 ea 0c             	shr    $0xc,%edx
f010457a:	39 ca                	cmp    %ecx,%edx
f010457c:	72 12                	jb     f0104590 <mpsearch1+0x4d>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010457e:	50                   	push   %eax
f010457f:	68 a4 4f 10 f0       	push   $0xf0104fa4
f0104584:	6a 57                	push   $0x57
f0104586:	68 41 67 10 f0       	push   $0xf0106741
f010458b:	e8 b0 ba ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0104590:	8d b0 00 00 00 f0    	lea    -0x10000000(%eax),%esi

	for (; mp < end; mp++)
f0104596:	eb 2f                	jmp    f01045c7 <mpsearch1+0x84>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f0104598:	83 ec 04             	sub    $0x4,%esp
f010459b:	6a 04                	push   $0x4
f010459d:	68 51 67 10 f0       	push   $0xf0106751
f01045a2:	53                   	push   %ebx
f01045a3:	e8 e6 fd ff ff       	call   f010438e <memcmp>
f01045a8:	83 c4 10             	add    $0x10,%esp
f01045ab:	85 c0                	test   %eax,%eax
f01045ad:	75 15                	jne    f01045c4 <mpsearch1+0x81>
f01045af:	89 da                	mov    %ebx,%edx
f01045b1:	8d 7b 10             	lea    0x10(%ebx),%edi
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
		sum += ((uint8_t *)addr)[i];
f01045b4:	0f b6 0a             	movzbl (%edx),%ecx
f01045b7:	01 c8                	add    %ecx,%eax
f01045b9:	83 c2 01             	add    $0x1,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f01045bc:	39 d7                	cmp    %edx,%edi
f01045be:	75 f4                	jne    f01045b4 <mpsearch1+0x71>
mpsearch1(physaddr_t a, int len)
{
	struct mp *mp = KADDR(a), *end = KADDR(a + len);

	for (; mp < end; mp++)
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f01045c0:	84 c0                	test   %al,%al
f01045c2:	74 0e                	je     f01045d2 <mpsearch1+0x8f>
static struct mp *
mpsearch1(physaddr_t a, int len)
{
	struct mp *mp = KADDR(a), *end = KADDR(a + len);

	for (; mp < end; mp++)
f01045c4:	83 c3 10             	add    $0x10,%ebx
f01045c7:	39 f3                	cmp    %esi,%ebx
f01045c9:	72 cd                	jb     f0104598 <mpsearch1+0x55>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
		    sum(mp, sizeof(*mp)) == 0)
			return mp;
	return NULL;
f01045cb:	b8 00 00 00 00       	mov    $0x0,%eax
f01045d0:	eb 02                	jmp    f01045d4 <mpsearch1+0x91>
f01045d2:	89 d8                	mov    %ebx,%eax
}
f01045d4:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01045d7:	5b                   	pop    %ebx
f01045d8:	5e                   	pop    %esi
f01045d9:	5f                   	pop    %edi
f01045da:	5d                   	pop    %ebp
f01045db:	c3                   	ret    

f01045dc <mp_init>:
	return conf;
}

void
mp_init(void)
{
f01045dc:	55                   	push   %ebp
f01045dd:	89 e5                	mov    %esp,%ebp
f01045df:	57                   	push   %edi
f01045e0:	56                   	push   %esi
f01045e1:	53                   	push   %ebx
f01045e2:	83 ec 1c             	sub    $0x1c,%esp
	struct mpconf *conf;
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
f01045e5:	c7 05 c0 93 22 f0 20 	movl   $0xf0229020,0xf02293c0
f01045ec:	90 22 f0 
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01045ef:	83 3d 08 8f 22 f0 00 	cmpl   $0x0,0xf0228f08
f01045f6:	75 16                	jne    f010460e <mp_init+0x32>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01045f8:	68 00 04 00 00       	push   $0x400
f01045fd:	68 a4 4f 10 f0       	push   $0xf0104fa4
f0104602:	6a 6f                	push   $0x6f
f0104604:	68 41 67 10 f0       	push   $0xf0106741
f0104609:	e8 32 ba ff ff       	call   f0100040 <_panic>
	// The BIOS data area lives in 16-bit segment 0x40.
	bda = (uint8_t *) KADDR(0x40 << 4);

	// [MP 4] The 16-bit segment of the EBDA is in the two bytes
	// starting at byte 0x0E of the BDA.  0 if not present.
	if ((p = *(uint16_t *) (bda + 0x0E))) {
f010460e:	0f b7 05 0e 04 00 f0 	movzwl 0xf000040e,%eax
f0104615:	85 c0                	test   %eax,%eax
f0104617:	74 16                	je     f010462f <mp_init+0x53>
		p <<= 4;	// Translate from segment to PA
		if ((mp = mpsearch1(p, 1024)))
f0104619:	c1 e0 04             	shl    $0x4,%eax
f010461c:	ba 00 04 00 00       	mov    $0x400,%edx
f0104621:	e8 1d ff ff ff       	call   f0104543 <mpsearch1>
f0104626:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0104629:	85 c0                	test   %eax,%eax
f010462b:	75 3c                	jne    f0104669 <mp_init+0x8d>
f010462d:	eb 20                	jmp    f010464f <mp_init+0x73>
			return mp;
	} else {
		// The size of base memory, in KB is in the two bytes
		// starting at 0x13 of the BDA.
		p = *(uint16_t *) (bda + 0x13) * 1024;
		if ((mp = mpsearch1(p - 1024, 1024)))
f010462f:	0f b7 05 13 04 00 f0 	movzwl 0xf0000413,%eax
f0104636:	c1 e0 0a             	shl    $0xa,%eax
f0104639:	2d 00 04 00 00       	sub    $0x400,%eax
f010463e:	ba 00 04 00 00       	mov    $0x400,%edx
f0104643:	e8 fb fe ff ff       	call   f0104543 <mpsearch1>
f0104648:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010464b:	85 c0                	test   %eax,%eax
f010464d:	75 1a                	jne    f0104669 <mp_init+0x8d>
			return mp;
	}
	return mpsearch1(0xF0000, 0x10000);
f010464f:	ba 00 00 01 00       	mov    $0x10000,%edx
f0104654:	b8 00 00 0f 00       	mov    $0xf0000,%eax
f0104659:	e8 e5 fe ff ff       	call   f0104543 <mpsearch1>
f010465e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
mpconfig(struct mp **pmp)
{
	struct mpconf *conf;
	struct mp *mp;

	if ((mp = mpsearch()) == 0)
f0104661:	85 c0                	test   %eax,%eax
f0104663:	0f 84 5d 02 00 00    	je     f01048c6 <mp_init+0x2ea>
		return NULL;
	if (mp->physaddr == 0 || mp->type != 0) {
f0104669:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010466c:	8b 70 04             	mov    0x4(%eax),%esi
f010466f:	85 f6                	test   %esi,%esi
f0104671:	74 06                	je     f0104679 <mp_init+0x9d>
f0104673:	80 78 0b 00          	cmpb   $0x0,0xb(%eax)
f0104677:	74 15                	je     f010468e <mp_init+0xb2>
		cprintf("SMP: Default configurations not implemented\n");
f0104679:	83 ec 0c             	sub    $0xc,%esp
f010467c:	68 b4 65 10 f0       	push   $0xf01065b4
f0104681:	e8 b7 e4 ff ff       	call   f0102b3d <cprintf>
f0104686:	83 c4 10             	add    $0x10,%esp
f0104689:	e9 38 02 00 00       	jmp    f01048c6 <mp_init+0x2ea>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010468e:	89 f0                	mov    %esi,%eax
f0104690:	c1 e8 0c             	shr    $0xc,%eax
f0104693:	3b 05 08 8f 22 f0    	cmp    0xf0228f08,%eax
f0104699:	72 15                	jb     f01046b0 <mp_init+0xd4>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010469b:	56                   	push   %esi
f010469c:	68 a4 4f 10 f0       	push   $0xf0104fa4
f01046a1:	68 90 00 00 00       	push   $0x90
f01046a6:	68 41 67 10 f0       	push   $0xf0106741
f01046ab:	e8 90 b9 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f01046b0:	8d 9e 00 00 00 f0    	lea    -0x10000000(%esi),%ebx
		return NULL;
	}
	conf = (struct mpconf *) KADDR(mp->physaddr);
	if (memcmp(conf, "PCMP", 4) != 0) {
f01046b6:	83 ec 04             	sub    $0x4,%esp
f01046b9:	6a 04                	push   $0x4
f01046bb:	68 56 67 10 f0       	push   $0xf0106756
f01046c0:	53                   	push   %ebx
f01046c1:	e8 c8 fc ff ff       	call   f010438e <memcmp>
f01046c6:	83 c4 10             	add    $0x10,%esp
f01046c9:	85 c0                	test   %eax,%eax
f01046cb:	74 15                	je     f01046e2 <mp_init+0x106>
		cprintf("SMP: Incorrect MP configuration table signature\n");
f01046cd:	83 ec 0c             	sub    $0xc,%esp
f01046d0:	68 e4 65 10 f0       	push   $0xf01065e4
f01046d5:	e8 63 e4 ff ff       	call   f0102b3d <cprintf>
f01046da:	83 c4 10             	add    $0x10,%esp
f01046dd:	e9 e4 01 00 00       	jmp    f01048c6 <mp_init+0x2ea>
		return NULL;
	}
	if (sum(conf, conf->length) != 0) {
f01046e2:	0f b7 43 04          	movzwl 0x4(%ebx),%eax
f01046e6:	66 89 45 e2          	mov    %ax,-0x1e(%ebp)
f01046ea:	0f b7 f8             	movzwl %ax,%edi
static uint8_t
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
f01046ed:	ba 00 00 00 00       	mov    $0x0,%edx
	for (i = 0; i < len; i++)
f01046f2:	b8 00 00 00 00       	mov    $0x0,%eax
f01046f7:	eb 0d                	jmp    f0104706 <mp_init+0x12a>
		sum += ((uint8_t *)addr)[i];
f01046f9:	0f b6 8c 30 00 00 00 	movzbl -0x10000000(%eax,%esi,1),%ecx
f0104700:	f0 
f0104701:	01 ca                	add    %ecx,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f0104703:	83 c0 01             	add    $0x1,%eax
f0104706:	39 c7                	cmp    %eax,%edi
f0104708:	75 ef                	jne    f01046f9 <mp_init+0x11d>
	conf = (struct mpconf *) KADDR(mp->physaddr);
	if (memcmp(conf, "PCMP", 4) != 0) {
		cprintf("SMP: Incorrect MP configuration table signature\n");
		return NULL;
	}
	if (sum(conf, conf->length) != 0) {
f010470a:	84 d2                	test   %dl,%dl
f010470c:	74 15                	je     f0104723 <mp_init+0x147>
		cprintf("SMP: Bad MP configuration checksum\n");
f010470e:	83 ec 0c             	sub    $0xc,%esp
f0104711:	68 18 66 10 f0       	push   $0xf0106618
f0104716:	e8 22 e4 ff ff       	call   f0102b3d <cprintf>
f010471b:	83 c4 10             	add    $0x10,%esp
f010471e:	e9 a3 01 00 00       	jmp    f01048c6 <mp_init+0x2ea>
		return NULL;
	}
	if (conf->version != 1 && conf->version != 4) {
f0104723:	0f b6 43 06          	movzbl 0x6(%ebx),%eax
f0104727:	3c 01                	cmp    $0x1,%al
f0104729:	74 1d                	je     f0104748 <mp_init+0x16c>
f010472b:	3c 04                	cmp    $0x4,%al
f010472d:	74 19                	je     f0104748 <mp_init+0x16c>
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
f010472f:	83 ec 08             	sub    $0x8,%esp
f0104732:	0f b6 c0             	movzbl %al,%eax
f0104735:	50                   	push   %eax
f0104736:	68 3c 66 10 f0       	push   $0xf010663c
f010473b:	e8 fd e3 ff ff       	call   f0102b3d <cprintf>
f0104740:	83 c4 10             	add    $0x10,%esp
f0104743:	e9 7e 01 00 00       	jmp    f01048c6 <mp_init+0x2ea>
		return NULL;
	}
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f0104748:	0f b7 7b 28          	movzwl 0x28(%ebx),%edi
f010474c:	0f b7 4d e2          	movzwl -0x1e(%ebp),%ecx
static uint8_t
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
f0104750:	ba 00 00 00 00       	mov    $0x0,%edx
	for (i = 0; i < len; i++)
f0104755:	b8 00 00 00 00       	mov    $0x0,%eax
		sum += ((uint8_t *)addr)[i];
f010475a:	01 ce                	add    %ecx,%esi
f010475c:	eb 0d                	jmp    f010476b <mp_init+0x18f>
f010475e:	0f b6 8c 06 00 00 00 	movzbl -0x10000000(%esi,%eax,1),%ecx
f0104765:	f0 
f0104766:	01 ca                	add    %ecx,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f0104768:	83 c0 01             	add    $0x1,%eax
f010476b:	39 c7                	cmp    %eax,%edi
f010476d:	75 ef                	jne    f010475e <mp_init+0x182>
	}
	if (conf->version != 1 && conf->version != 4) {
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
		return NULL;
	}
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f010476f:	89 d0                	mov    %edx,%eax
f0104771:	02 43 2a             	add    0x2a(%ebx),%al
f0104774:	74 15                	je     f010478b <mp_init+0x1af>
		cprintf("SMP: Bad MP configuration extended checksum\n");
f0104776:	83 ec 0c             	sub    $0xc,%esp
f0104779:	68 5c 66 10 f0       	push   $0xf010665c
f010477e:	e8 ba e3 ff ff       	call   f0102b3d <cprintf>
f0104783:	83 c4 10             	add    $0x10,%esp
f0104786:	e9 3b 01 00 00       	jmp    f01048c6 <mp_init+0x2ea>
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
	if ((conf = mpconfig(&mp)) == 0)
f010478b:	85 db                	test   %ebx,%ebx
f010478d:	0f 84 33 01 00 00    	je     f01048c6 <mp_init+0x2ea>
		return;
	ismp = 1;
f0104793:	c7 05 00 90 22 f0 01 	movl   $0x1,0xf0229000
f010479a:	00 00 00 
	lapicaddr = conf->lapicaddr;
f010479d:	8b 43 24             	mov    0x24(%ebx),%eax
f01047a0:	a3 00 a0 26 f0       	mov    %eax,0xf026a000

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f01047a5:	8d 7b 2c             	lea    0x2c(%ebx),%edi
f01047a8:	be 00 00 00 00       	mov    $0x0,%esi
f01047ad:	e9 85 00 00 00       	jmp    f0104837 <mp_init+0x25b>
		switch (*p) {
f01047b2:	0f b6 07             	movzbl (%edi),%eax
f01047b5:	84 c0                	test   %al,%al
f01047b7:	74 06                	je     f01047bf <mp_init+0x1e3>
f01047b9:	3c 04                	cmp    $0x4,%al
f01047bb:	77 55                	ja     f0104812 <mp_init+0x236>
f01047bd:	eb 4e                	jmp    f010480d <mp_init+0x231>
		case MPPROC:
			proc = (struct mpproc *)p;
			if (proc->flags & MPPROC_BOOT)
f01047bf:	f6 47 03 02          	testb  $0x2,0x3(%edi)
f01047c3:	74 11                	je     f01047d6 <mp_init+0x1fa>
				bootcpu = &cpus[ncpu];
f01047c5:	6b 05 c4 93 22 f0 74 	imul   $0x74,0xf02293c4,%eax
f01047cc:	05 20 90 22 f0       	add    $0xf0229020,%eax
f01047d1:	a3 c0 93 22 f0       	mov    %eax,0xf02293c0
			if (ncpu < NCPU) {
f01047d6:	a1 c4 93 22 f0       	mov    0xf02293c4,%eax
f01047db:	83 f8 07             	cmp    $0x7,%eax
f01047de:	7f 13                	jg     f01047f3 <mp_init+0x217>
				cpus[ncpu].cpu_id = ncpu;
f01047e0:	6b d0 74             	imul   $0x74,%eax,%edx
f01047e3:	88 82 20 90 22 f0    	mov    %al,-0xfdd6fe0(%edx)
				ncpu++;
f01047e9:	83 c0 01             	add    $0x1,%eax
f01047ec:	a3 c4 93 22 f0       	mov    %eax,0xf02293c4
f01047f1:	eb 15                	jmp    f0104808 <mp_init+0x22c>
			} else {
				cprintf("SMP: too many CPUs, CPU %d disabled\n",
f01047f3:	83 ec 08             	sub    $0x8,%esp
f01047f6:	0f b6 47 01          	movzbl 0x1(%edi),%eax
f01047fa:	50                   	push   %eax
f01047fb:	68 8c 66 10 f0       	push   $0xf010668c
f0104800:	e8 38 e3 ff ff       	call   f0102b3d <cprintf>
f0104805:	83 c4 10             	add    $0x10,%esp
					proc->apicid);
			}
			p += sizeof(struct mpproc);
f0104808:	83 c7 14             	add    $0x14,%edi
			continue;
f010480b:	eb 27                	jmp    f0104834 <mp_init+0x258>
		case MPBUS:
		case MPIOAPIC:
		case MPIOINTR:
		case MPLINTR:
			p += 8;
f010480d:	83 c7 08             	add    $0x8,%edi
			continue;
f0104810:	eb 22                	jmp    f0104834 <mp_init+0x258>
		default:
			cprintf("mpinit: unknown config type %x\n", *p);
f0104812:	83 ec 08             	sub    $0x8,%esp
f0104815:	0f b6 c0             	movzbl %al,%eax
f0104818:	50                   	push   %eax
f0104819:	68 b4 66 10 f0       	push   $0xf01066b4
f010481e:	e8 1a e3 ff ff       	call   f0102b3d <cprintf>
			ismp = 0;
f0104823:	c7 05 00 90 22 f0 00 	movl   $0x0,0xf0229000
f010482a:	00 00 00 
			i = conf->entry;
f010482d:	0f b7 73 22          	movzwl 0x22(%ebx),%esi
f0104831:	83 c4 10             	add    $0x10,%esp
	if ((conf = mpconfig(&mp)) == 0)
		return;
	ismp = 1;
	lapicaddr = conf->lapicaddr;

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f0104834:	83 c6 01             	add    $0x1,%esi
f0104837:	0f b7 43 22          	movzwl 0x22(%ebx),%eax
f010483b:	39 c6                	cmp    %eax,%esi
f010483d:	0f 82 6f ff ff ff    	jb     f01047b2 <mp_init+0x1d6>
			ismp = 0;
			i = conf->entry;
		}
	}

	bootcpu->cpu_status = CPU_STARTED;
f0104843:	a1 c0 93 22 f0       	mov    0xf02293c0,%eax
f0104848:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
	if (!ismp) {
f010484f:	83 3d 00 90 22 f0 00 	cmpl   $0x0,0xf0229000
f0104856:	75 26                	jne    f010487e <mp_init+0x2a2>
		// Didn't like what we found; fall back to no MP.
		ncpu = 1;
f0104858:	c7 05 c4 93 22 f0 01 	movl   $0x1,0xf02293c4
f010485f:	00 00 00 
		lapicaddr = 0;
f0104862:	c7 05 00 a0 26 f0 00 	movl   $0x0,0xf026a000
f0104869:	00 00 00 
		cprintf("SMP: configuration not found, SMP disabled\n");
f010486c:	83 ec 0c             	sub    $0xc,%esp
f010486f:	68 d4 66 10 f0       	push   $0xf01066d4
f0104874:	e8 c4 e2 ff ff       	call   f0102b3d <cprintf>
		return;
f0104879:	83 c4 10             	add    $0x10,%esp
f010487c:	eb 48                	jmp    f01048c6 <mp_init+0x2ea>
	}
	cprintf("SMP: CPU %d found %d CPU(s)\n", bootcpu->cpu_id,  ncpu);
f010487e:	83 ec 04             	sub    $0x4,%esp
f0104881:	ff 35 c4 93 22 f0    	pushl  0xf02293c4
f0104887:	0f b6 00             	movzbl (%eax),%eax
f010488a:	50                   	push   %eax
f010488b:	68 5b 67 10 f0       	push   $0xf010675b
f0104890:	e8 a8 e2 ff ff       	call   f0102b3d <cprintf>

	if (mp->imcrp) {
f0104895:	83 c4 10             	add    $0x10,%esp
f0104898:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010489b:	80 78 0c 00          	cmpb   $0x0,0xc(%eax)
f010489f:	74 25                	je     f01048c6 <mp_init+0x2ea>
		// [MP 3.2.6.1] If the hardware implements PIC mode,
		// switch to getting interrupts from the LAPIC.
		cprintf("SMP: Setting IMCR to switch from PIC mode to symmetric I/O mode\n");
f01048a1:	83 ec 0c             	sub    $0xc,%esp
f01048a4:	68 00 67 10 f0       	push   $0xf0106700
f01048a9:	e8 8f e2 ff ff       	call   f0102b3d <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01048ae:	ba 22 00 00 00       	mov    $0x22,%edx
f01048b3:	b8 70 00 00 00       	mov    $0x70,%eax
f01048b8:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01048b9:	ba 23 00 00 00       	mov    $0x23,%edx
f01048be:	ec                   	in     (%dx),%al
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01048bf:	83 c8 01             	or     $0x1,%eax
f01048c2:	ee                   	out    %al,(%dx)
f01048c3:	83 c4 10             	add    $0x10,%esp
		outb(0x22, 0x70);   // Select IMCR
		outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
	}
}
f01048c6:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01048c9:	5b                   	pop    %ebx
f01048ca:	5e                   	pop    %esi
f01048cb:	5f                   	pop    %edi
f01048cc:	5d                   	pop    %ebp
f01048cd:	c3                   	ret    

f01048ce <lapicw>:
physaddr_t lapicaddr;        // Initialized in mpconfig.c
volatile uint32_t *lapic;

static void
lapicw(int index, int value)
{
f01048ce:	55                   	push   %ebp
f01048cf:	89 e5                	mov    %esp,%ebp
	lapic[index] = value;
f01048d1:	8b 0d 04 a0 26 f0    	mov    0xf026a004,%ecx
f01048d7:	8d 04 81             	lea    (%ecx,%eax,4),%eax
f01048da:	89 10                	mov    %edx,(%eax)
	lapic[ID];  // wait for write to finish, by reading
f01048dc:	a1 04 a0 26 f0       	mov    0xf026a004,%eax
f01048e1:	8b 40 20             	mov    0x20(%eax),%eax
}
f01048e4:	5d                   	pop    %ebp
f01048e5:	c3                   	ret    

f01048e6 <cpunum>:
	lapicw(TPR, 0);
}

int
cpunum(void)
{
f01048e6:	55                   	push   %ebp
f01048e7:	89 e5                	mov    %esp,%ebp
	if (lapic)
f01048e9:	a1 04 a0 26 f0       	mov    0xf026a004,%eax
f01048ee:	85 c0                	test   %eax,%eax
f01048f0:	74 08                	je     f01048fa <cpunum+0x14>
		return lapic[ID] >> 24;
f01048f2:	8b 40 20             	mov    0x20(%eax),%eax
f01048f5:	c1 e8 18             	shr    $0x18,%eax
f01048f8:	eb 05                	jmp    f01048ff <cpunum+0x19>
	return 0;
f01048fa:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01048ff:	5d                   	pop    %ebp
f0104900:	c3                   	ret    

f0104901 <lapic_init>:
}

void
lapic_init(void)
{
	if (!lapicaddr)
f0104901:	a1 00 a0 26 f0       	mov    0xf026a000,%eax
f0104906:	85 c0                	test   %eax,%eax
f0104908:	0f 84 21 01 00 00    	je     f0104a2f <lapic_init+0x12e>
	lapic[ID];  // wait for write to finish, by reading
}

void
lapic_init(void)
{
f010490e:	55                   	push   %ebp
f010490f:	89 e5                	mov    %esp,%ebp
f0104911:	83 ec 10             	sub    $0x10,%esp
	if (!lapicaddr)
		return;

	// lapicaddr is the physical address of the LAPIC's 4K MMIO
	// region.  Map it in to virtual memory so we can access it.
	lapic = mmio_map_region(lapicaddr, 4096);
f0104914:	68 00 10 00 00       	push   $0x1000
f0104919:	50                   	push   %eax
f010491a:	e8 0e c6 ff ff       	call   f0100f2d <mmio_map_region>
f010491f:	a3 04 a0 26 f0       	mov    %eax,0xf026a004

	// Enable local APIC; set spurious interrupt vector.
	lapicw(SVR, ENABLE | (IRQ_OFFSET + IRQ_SPURIOUS));
f0104924:	ba 27 01 00 00       	mov    $0x127,%edx
f0104929:	b8 3c 00 00 00       	mov    $0x3c,%eax
f010492e:	e8 9b ff ff ff       	call   f01048ce <lapicw>

	// The timer repeatedly counts down at bus frequency
	// from lapic[TICR] and then issues an interrupt.  
	// If we cared more about precise timekeeping,
	// TICR would be calibrated using an external time source.
	lapicw(TDCR, X1);
f0104933:	ba 0b 00 00 00       	mov    $0xb,%edx
f0104938:	b8 f8 00 00 00       	mov    $0xf8,%eax
f010493d:	e8 8c ff ff ff       	call   f01048ce <lapicw>
	lapicw(TIMER, PERIODIC | (IRQ_OFFSET + IRQ_TIMER));
f0104942:	ba 20 00 02 00       	mov    $0x20020,%edx
f0104947:	b8 c8 00 00 00       	mov    $0xc8,%eax
f010494c:	e8 7d ff ff ff       	call   f01048ce <lapicw>
	lapicw(TICR, 10000000); 
f0104951:	ba 80 96 98 00       	mov    $0x989680,%edx
f0104956:	b8 e0 00 00 00       	mov    $0xe0,%eax
f010495b:	e8 6e ff ff ff       	call   f01048ce <lapicw>
	//
	// According to Intel MP Specification, the BIOS should initialize
	// BSP's local APIC in Virtual Wire Mode, in which 8259A's
	// INTR is virtually connected to BSP's LINTIN0. In this mode,
	// we do not need to program the IOAPIC.
	if (thiscpu != bootcpu)
f0104960:	e8 81 ff ff ff       	call   f01048e6 <cpunum>
f0104965:	6b c0 74             	imul   $0x74,%eax,%eax
f0104968:	05 20 90 22 f0       	add    $0xf0229020,%eax
f010496d:	83 c4 10             	add    $0x10,%esp
f0104970:	39 05 c0 93 22 f0    	cmp    %eax,0xf02293c0
f0104976:	74 0f                	je     f0104987 <lapic_init+0x86>
		lapicw(LINT0, MASKED);
f0104978:	ba 00 00 01 00       	mov    $0x10000,%edx
f010497d:	b8 d4 00 00 00       	mov    $0xd4,%eax
f0104982:	e8 47 ff ff ff       	call   f01048ce <lapicw>

	// Disable NMI (LINT1) on all CPUs
	lapicw(LINT1, MASKED);
f0104987:	ba 00 00 01 00       	mov    $0x10000,%edx
f010498c:	b8 d8 00 00 00       	mov    $0xd8,%eax
f0104991:	e8 38 ff ff ff       	call   f01048ce <lapicw>

	// Disable performance counter overflow interrupts
	// on machines that provide that interrupt entry.
	if (((lapic[VER]>>16) & 0xFF) >= 4)
f0104996:	a1 04 a0 26 f0       	mov    0xf026a004,%eax
f010499b:	8b 40 30             	mov    0x30(%eax),%eax
f010499e:	c1 e8 10             	shr    $0x10,%eax
f01049a1:	3c 03                	cmp    $0x3,%al
f01049a3:	76 0f                	jbe    f01049b4 <lapic_init+0xb3>
		lapicw(PCINT, MASKED);
f01049a5:	ba 00 00 01 00       	mov    $0x10000,%edx
f01049aa:	b8 d0 00 00 00       	mov    $0xd0,%eax
f01049af:	e8 1a ff ff ff       	call   f01048ce <lapicw>

	// Map error interrupt to IRQ_ERROR.
	lapicw(ERROR, IRQ_OFFSET + IRQ_ERROR);
f01049b4:	ba 33 00 00 00       	mov    $0x33,%edx
f01049b9:	b8 dc 00 00 00       	mov    $0xdc,%eax
f01049be:	e8 0b ff ff ff       	call   f01048ce <lapicw>

	// Clear error status register (requires back-to-back writes).
	lapicw(ESR, 0);
f01049c3:	ba 00 00 00 00       	mov    $0x0,%edx
f01049c8:	b8 a0 00 00 00       	mov    $0xa0,%eax
f01049cd:	e8 fc fe ff ff       	call   f01048ce <lapicw>
	lapicw(ESR, 0);
f01049d2:	ba 00 00 00 00       	mov    $0x0,%edx
f01049d7:	b8 a0 00 00 00       	mov    $0xa0,%eax
f01049dc:	e8 ed fe ff ff       	call   f01048ce <lapicw>

	// Ack any outstanding interrupts.
	lapicw(EOI, 0);
f01049e1:	ba 00 00 00 00       	mov    $0x0,%edx
f01049e6:	b8 2c 00 00 00       	mov    $0x2c,%eax
f01049eb:	e8 de fe ff ff       	call   f01048ce <lapicw>

	// Send an Init Level De-Assert to synchronize arbitration ID's.
	lapicw(ICRHI, 0);
f01049f0:	ba 00 00 00 00       	mov    $0x0,%edx
f01049f5:	b8 c4 00 00 00       	mov    $0xc4,%eax
f01049fa:	e8 cf fe ff ff       	call   f01048ce <lapicw>
	lapicw(ICRLO, BCAST | INIT | LEVEL);
f01049ff:	ba 00 85 08 00       	mov    $0x88500,%edx
f0104a04:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0104a09:	e8 c0 fe ff ff       	call   f01048ce <lapicw>
	while(lapic[ICRLO] & DELIVS)
f0104a0e:	8b 15 04 a0 26 f0    	mov    0xf026a004,%edx
f0104a14:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f0104a1a:	f6 c4 10             	test   $0x10,%ah
f0104a1d:	75 f5                	jne    f0104a14 <lapic_init+0x113>
		;

	// Enable interrupts on the APIC (but not on the processor).
	lapicw(TPR, 0);
f0104a1f:	ba 00 00 00 00       	mov    $0x0,%edx
f0104a24:	b8 20 00 00 00       	mov    $0x20,%eax
f0104a29:	e8 a0 fe ff ff       	call   f01048ce <lapicw>
}
f0104a2e:	c9                   	leave  
f0104a2f:	f3 c3                	repz ret 

f0104a31 <lapic_eoi>:

// Acknowledge interrupt.
void
lapic_eoi(void)
{
	if (lapic)
f0104a31:	83 3d 04 a0 26 f0 00 	cmpl   $0x0,0xf026a004
f0104a38:	74 13                	je     f0104a4d <lapic_eoi+0x1c>
}

// Acknowledge interrupt.
void
lapic_eoi(void)
{
f0104a3a:	55                   	push   %ebp
f0104a3b:	89 e5                	mov    %esp,%ebp
	if (lapic)
		lapicw(EOI, 0);
f0104a3d:	ba 00 00 00 00       	mov    $0x0,%edx
f0104a42:	b8 2c 00 00 00       	mov    $0x2c,%eax
f0104a47:	e8 82 fe ff ff       	call   f01048ce <lapicw>
}
f0104a4c:	5d                   	pop    %ebp
f0104a4d:	f3 c3                	repz ret 

f0104a4f <lapic_startap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapic_startap(uint8_t apicid, uint32_t addr)
{
f0104a4f:	55                   	push   %ebp
f0104a50:	89 e5                	mov    %esp,%ebp
f0104a52:	56                   	push   %esi
f0104a53:	53                   	push   %ebx
f0104a54:	8b 75 08             	mov    0x8(%ebp),%esi
f0104a57:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104a5a:	ba 70 00 00 00       	mov    $0x70,%edx
f0104a5f:	b8 0f 00 00 00       	mov    $0xf,%eax
f0104a64:	ee                   	out    %al,(%dx)
f0104a65:	ba 71 00 00 00       	mov    $0x71,%edx
f0104a6a:	b8 0a 00 00 00       	mov    $0xa,%eax
f0104a6f:	ee                   	out    %al,(%dx)
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0104a70:	83 3d 08 8f 22 f0 00 	cmpl   $0x0,0xf0228f08
f0104a77:	75 19                	jne    f0104a92 <lapic_startap+0x43>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0104a79:	68 67 04 00 00       	push   $0x467
f0104a7e:	68 a4 4f 10 f0       	push   $0xf0104fa4
f0104a83:	68 98 00 00 00       	push   $0x98
f0104a88:	68 78 67 10 f0       	push   $0xf0106778
f0104a8d:	e8 ae b5 ff ff       	call   f0100040 <_panic>
	// and the warm reset vector (DWORD based at 40:67) to point at
	// the AP startup code prior to the [universal startup algorithm]."
	outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
	outb(IO_RTC+1, 0x0A);
	wrv = (uint16_t *)KADDR((0x40 << 4 | 0x67));  // Warm reset vector
	wrv[0] = 0;
f0104a92:	66 c7 05 67 04 00 f0 	movw   $0x0,0xf0000467
f0104a99:	00 00 
	wrv[1] = addr >> 4;
f0104a9b:	89 d8                	mov    %ebx,%eax
f0104a9d:	c1 e8 04             	shr    $0x4,%eax
f0104aa0:	66 a3 69 04 00 f0    	mov    %ax,0xf0000469

	// "Universal startup algorithm."
	// Send INIT (level-triggered) interrupt to reset other CPU.
	lapicw(ICRHI, apicid << 24);
f0104aa6:	c1 e6 18             	shl    $0x18,%esi
f0104aa9:	89 f2                	mov    %esi,%edx
f0104aab:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0104ab0:	e8 19 fe ff ff       	call   f01048ce <lapicw>
	lapicw(ICRLO, INIT | LEVEL | ASSERT);
f0104ab5:	ba 00 c5 00 00       	mov    $0xc500,%edx
f0104aba:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0104abf:	e8 0a fe ff ff       	call   f01048ce <lapicw>
	microdelay(200);
	lapicw(ICRLO, INIT | LEVEL);
f0104ac4:	ba 00 85 00 00       	mov    $0x8500,%edx
f0104ac9:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0104ace:	e8 fb fd ff ff       	call   f01048ce <lapicw>
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0104ad3:	c1 eb 0c             	shr    $0xc,%ebx
f0104ad6:	80 cf 06             	or     $0x6,%bh
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
f0104ad9:	89 f2                	mov    %esi,%edx
f0104adb:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0104ae0:	e8 e9 fd ff ff       	call   f01048ce <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0104ae5:	89 da                	mov    %ebx,%edx
f0104ae7:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0104aec:	e8 dd fd ff ff       	call   f01048ce <lapicw>
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
f0104af1:	89 f2                	mov    %esi,%edx
f0104af3:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0104af8:	e8 d1 fd ff ff       	call   f01048ce <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0104afd:	89 da                	mov    %ebx,%edx
f0104aff:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0104b04:	e8 c5 fd ff ff       	call   f01048ce <lapicw>
		microdelay(200);
	}
}
f0104b09:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0104b0c:	5b                   	pop    %ebx
f0104b0d:	5e                   	pop    %esi
f0104b0e:	5d                   	pop    %ebp
f0104b0f:	c3                   	ret    

f0104b10 <lapic_ipi>:

void
lapic_ipi(int vector)
{
f0104b10:	55                   	push   %ebp
f0104b11:	89 e5                	mov    %esp,%ebp
	lapicw(ICRLO, OTHERS | FIXED | vector);
f0104b13:	8b 55 08             	mov    0x8(%ebp),%edx
f0104b16:	81 ca 00 00 0c 00    	or     $0xc0000,%edx
f0104b1c:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0104b21:	e8 a8 fd ff ff       	call   f01048ce <lapicw>
	while (lapic[ICRLO] & DELIVS)
f0104b26:	8b 15 04 a0 26 f0    	mov    0xf026a004,%edx
f0104b2c:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f0104b32:	f6 c4 10             	test   $0x10,%ah
f0104b35:	75 f5                	jne    f0104b2c <lapic_ipi+0x1c>
		;
}
f0104b37:	5d                   	pop    %ebp
f0104b38:	c3                   	ret    

f0104b39 <__spin_initlock>:
}
#endif

void
__spin_initlock(struct spinlock *lk, char *name)
{
f0104b39:	55                   	push   %ebp
f0104b3a:	89 e5                	mov    %esp,%ebp
f0104b3c:	8b 45 08             	mov    0x8(%ebp),%eax
	lk->locked = 0;
f0104b3f:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
#ifdef DEBUG_SPINLOCK
	lk->name = name;
f0104b45:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104b48:	89 50 04             	mov    %edx,0x4(%eax)
	lk->cpu = 0;
f0104b4b:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
#endif
}
f0104b52:	5d                   	pop    %ebp
f0104b53:	c3                   	ret    

f0104b54 <spin_lock>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
spin_lock(struct spinlock *lk)
{
f0104b54:	55                   	push   %ebp
f0104b55:	89 e5                	mov    %esp,%ebp
f0104b57:	56                   	push   %esi
f0104b58:	53                   	push   %ebx
f0104b59:	8b 5d 08             	mov    0x8(%ebp),%ebx

// Check whether this CPU is holding the lock.
static int
holding(struct spinlock *lock)
{
	return lock->locked && lock->cpu == thiscpu;
f0104b5c:	83 3b 00             	cmpl   $0x0,(%ebx)
f0104b5f:	74 14                	je     f0104b75 <spin_lock+0x21>
f0104b61:	8b 73 08             	mov    0x8(%ebx),%esi
f0104b64:	e8 7d fd ff ff       	call   f01048e6 <cpunum>
f0104b69:	6b c0 74             	imul   $0x74,%eax,%eax
f0104b6c:	05 20 90 22 f0       	add    $0xf0229020,%eax
// other CPUs to waste time spinning to acquire it.
void
spin_lock(struct spinlock *lk)
{
#ifdef DEBUG_SPINLOCK
	if (holding(lk))
f0104b71:	39 c6                	cmp    %eax,%esi
f0104b73:	74 07                	je     f0104b7c <spin_lock+0x28>
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"
f0104b75:	ba 01 00 00 00       	mov    $0x1,%edx
f0104b7a:	eb 20                	jmp    f0104b9c <spin_lock+0x48>
		panic("CPU %d cannot acquire %s: already holding", cpunum(), lk->name);
f0104b7c:	8b 5b 04             	mov    0x4(%ebx),%ebx
f0104b7f:	e8 62 fd ff ff       	call   f01048e6 <cpunum>
f0104b84:	83 ec 0c             	sub    $0xc,%esp
f0104b87:	53                   	push   %ebx
f0104b88:	50                   	push   %eax
f0104b89:	68 88 67 10 f0       	push   $0xf0106788
f0104b8e:	6a 41                	push   $0x41
f0104b90:	68 ec 67 10 f0       	push   $0xf01067ec
f0104b95:	e8 a6 b4 ff ff       	call   f0100040 <_panic>

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
		asm volatile ("pause");
f0104b9a:	f3 90                	pause  
f0104b9c:	89 d0                	mov    %edx,%eax
f0104b9e:	f0 87 03             	lock xchg %eax,(%ebx)
#endif

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
f0104ba1:	85 c0                	test   %eax,%eax
f0104ba3:	75 f5                	jne    f0104b9a <spin_lock+0x46>
		asm volatile ("pause");

	// Record info about lock acquisition for debugging.
#ifdef DEBUG_SPINLOCK
	lk->cpu = thiscpu;
f0104ba5:	e8 3c fd ff ff       	call   f01048e6 <cpunum>
f0104baa:	6b c0 74             	imul   $0x74,%eax,%eax
f0104bad:	05 20 90 22 f0       	add    $0xf0229020,%eax
f0104bb2:	89 43 08             	mov    %eax,0x8(%ebx)
	get_caller_pcs(lk->pcs);
f0104bb5:	83 c3 0c             	add    $0xc,%ebx

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f0104bb8:	89 ea                	mov    %ebp,%edx
{
	uint32_t *ebp;
	int i;

	ebp = (uint32_t *)read_ebp();
	for (i = 0; i < 10; i++){
f0104bba:	b8 00 00 00 00       	mov    $0x0,%eax
f0104bbf:	eb 0b                	jmp    f0104bcc <spin_lock+0x78>
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
			break;
		pcs[i] = ebp[1];          // saved %eip
f0104bc1:	8b 4a 04             	mov    0x4(%edx),%ecx
f0104bc4:	89 0c 83             	mov    %ecx,(%ebx,%eax,4)
		ebp = (uint32_t *)ebp[0]; // saved %ebp
f0104bc7:	8b 12                	mov    (%edx),%edx
{
	uint32_t *ebp;
	int i;

	ebp = (uint32_t *)read_ebp();
	for (i = 0; i < 10; i++){
f0104bc9:	83 c0 01             	add    $0x1,%eax
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
f0104bcc:	81 fa ff ff 7f ef    	cmp    $0xef7fffff,%edx
f0104bd2:	76 11                	jbe    f0104be5 <spin_lock+0x91>
f0104bd4:	83 f8 09             	cmp    $0x9,%eax
f0104bd7:	7e e8                	jle    f0104bc1 <spin_lock+0x6d>
f0104bd9:	eb 0a                	jmp    f0104be5 <spin_lock+0x91>
			break;
		pcs[i] = ebp[1];          // saved %eip
		ebp = (uint32_t *)ebp[0]; // saved %ebp
	}
	for (; i < 10; i++)
		pcs[i] = 0;
f0104bdb:	c7 04 83 00 00 00 00 	movl   $0x0,(%ebx,%eax,4)
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
			break;
		pcs[i] = ebp[1];          // saved %eip
		ebp = (uint32_t *)ebp[0]; // saved %ebp
	}
	for (; i < 10; i++)
f0104be2:	83 c0 01             	add    $0x1,%eax
f0104be5:	83 f8 09             	cmp    $0x9,%eax
f0104be8:	7e f1                	jle    f0104bdb <spin_lock+0x87>
	// Record info about lock acquisition for debugging.
#ifdef DEBUG_SPINLOCK
	lk->cpu = thiscpu;
	get_caller_pcs(lk->pcs);
#endif
}
f0104bea:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0104bed:	5b                   	pop    %ebx
f0104bee:	5e                   	pop    %esi
f0104bef:	5d                   	pop    %ebp
f0104bf0:	c3                   	ret    

f0104bf1 <spin_unlock>:

// Release the lock.
void
spin_unlock(struct spinlock *lk)
{
f0104bf1:	55                   	push   %ebp
f0104bf2:	89 e5                	mov    %esp,%ebp
f0104bf4:	57                   	push   %edi
f0104bf5:	56                   	push   %esi
f0104bf6:	53                   	push   %ebx
f0104bf7:	83 ec 4c             	sub    $0x4c,%esp
f0104bfa:	8b 75 08             	mov    0x8(%ebp),%esi

// Check whether this CPU is holding the lock.
static int
holding(struct spinlock *lock)
{
	return lock->locked && lock->cpu == thiscpu;
f0104bfd:	83 3e 00             	cmpl   $0x0,(%esi)
f0104c00:	74 18                	je     f0104c1a <spin_unlock+0x29>
f0104c02:	8b 5e 08             	mov    0x8(%esi),%ebx
f0104c05:	e8 dc fc ff ff       	call   f01048e6 <cpunum>
f0104c0a:	6b c0 74             	imul   $0x74,%eax,%eax
f0104c0d:	05 20 90 22 f0       	add    $0xf0229020,%eax
// Release the lock.
void
spin_unlock(struct spinlock *lk)
{
#ifdef DEBUG_SPINLOCK
	if (!holding(lk)) {
f0104c12:	39 c3                	cmp    %eax,%ebx
f0104c14:	0f 84 a5 00 00 00    	je     f0104cbf <spin_unlock+0xce>
		int i;
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
f0104c1a:	83 ec 04             	sub    $0x4,%esp
f0104c1d:	6a 28                	push   $0x28
f0104c1f:	8d 46 0c             	lea    0xc(%esi),%eax
f0104c22:	50                   	push   %eax
f0104c23:	8d 5d c0             	lea    -0x40(%ebp),%ebx
f0104c26:	53                   	push   %ebx
f0104c27:	e8 e7 f6 ff ff       	call   f0104313 <memmove>
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
f0104c2c:	8b 46 08             	mov    0x8(%esi),%eax
	if (!holding(lk)) {
		int i;
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
f0104c2f:	0f b6 38             	movzbl (%eax),%edi
f0104c32:	8b 76 04             	mov    0x4(%esi),%esi
f0104c35:	e8 ac fc ff ff       	call   f01048e6 <cpunum>
f0104c3a:	57                   	push   %edi
f0104c3b:	56                   	push   %esi
f0104c3c:	50                   	push   %eax
f0104c3d:	68 b4 67 10 f0       	push   $0xf01067b4
f0104c42:	e8 f6 de ff ff       	call   f0102b3d <cprintf>
f0104c47:	83 c4 20             	add    $0x20,%esp
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
			struct Eipdebuginfo info;
			if (debuginfo_eip(pcs[i], &info) >= 0)
f0104c4a:	8d 7d a8             	lea    -0x58(%ebp),%edi
f0104c4d:	eb 54                	jmp    f0104ca3 <spin_unlock+0xb2>
f0104c4f:	83 ec 08             	sub    $0x8,%esp
f0104c52:	57                   	push   %edi
f0104c53:	50                   	push   %eax
f0104c54:	e8 bd eb ff ff       	call   f0103816 <debuginfo_eip>
f0104c59:	83 c4 10             	add    $0x10,%esp
f0104c5c:	85 c0                	test   %eax,%eax
f0104c5e:	78 27                	js     f0104c87 <spin_unlock+0x96>
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
					info.eip_file, info.eip_line,
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
f0104c60:	8b 06                	mov    (%esi),%eax
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
			struct Eipdebuginfo info;
			if (debuginfo_eip(pcs[i], &info) >= 0)
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
f0104c62:	83 ec 04             	sub    $0x4,%esp
f0104c65:	89 c2                	mov    %eax,%edx
f0104c67:	2b 55 b8             	sub    -0x48(%ebp),%edx
f0104c6a:	52                   	push   %edx
f0104c6b:	ff 75 b0             	pushl  -0x50(%ebp)
f0104c6e:	ff 75 b4             	pushl  -0x4c(%ebp)
f0104c71:	ff 75 ac             	pushl  -0x54(%ebp)
f0104c74:	ff 75 a8             	pushl  -0x58(%ebp)
f0104c77:	50                   	push   %eax
f0104c78:	68 fc 67 10 f0       	push   $0xf01067fc
f0104c7d:	e8 bb de ff ff       	call   f0102b3d <cprintf>
f0104c82:	83 c4 20             	add    $0x20,%esp
f0104c85:	eb 12                	jmp    f0104c99 <spin_unlock+0xa8>
					info.eip_file, info.eip_line,
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
			else
				cprintf("  %08x\n", pcs[i]);
f0104c87:	83 ec 08             	sub    $0x8,%esp
f0104c8a:	ff 36                	pushl  (%esi)
f0104c8c:	68 13 68 10 f0       	push   $0xf0106813
f0104c91:	e8 a7 de ff ff       	call   f0102b3d <cprintf>
f0104c96:	83 c4 10             	add    $0x10,%esp
f0104c99:	83 c3 04             	add    $0x4,%ebx
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
f0104c9c:	8d 45 e8             	lea    -0x18(%ebp),%eax
f0104c9f:	39 c3                	cmp    %eax,%ebx
f0104ca1:	74 08                	je     f0104cab <spin_unlock+0xba>
f0104ca3:	89 de                	mov    %ebx,%esi
f0104ca5:	8b 03                	mov    (%ebx),%eax
f0104ca7:	85 c0                	test   %eax,%eax
f0104ca9:	75 a4                	jne    f0104c4f <spin_unlock+0x5e>
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
			else
				cprintf("  %08x\n", pcs[i]);
		}
		panic("spin_unlock");
f0104cab:	83 ec 04             	sub    $0x4,%esp
f0104cae:	68 1b 68 10 f0       	push   $0xf010681b
f0104cb3:	6a 67                	push   $0x67
f0104cb5:	68 ec 67 10 f0       	push   $0xf01067ec
f0104cba:	e8 81 b3 ff ff       	call   f0100040 <_panic>
	}

	lk->pcs[0] = 0;
f0104cbf:	c7 46 0c 00 00 00 00 	movl   $0x0,0xc(%esi)
	lk->cpu = 0;
f0104cc6:	c7 46 08 00 00 00 00 	movl   $0x0,0x8(%esi)
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"
f0104ccd:	b8 00 00 00 00       	mov    $0x0,%eax
f0104cd2:	f0 87 06             	lock xchg %eax,(%esi)
	// respect to any other instruction which references the same memory.
	// x86 CPUs will not reorder loads/stores across locked instructions
	// (vol 3, 8.2.2). Because xchg() is implemented using asm volatile,
	// gcc will not reorder C statements across the xchg.
	xchg(&lk->locked, 0);
}
f0104cd5:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104cd8:	5b                   	pop    %ebx
f0104cd9:	5e                   	pop    %esi
f0104cda:	5f                   	pop    %edi
f0104cdb:	5d                   	pop    %ebp
f0104cdc:	c3                   	ret    
f0104cdd:	66 90                	xchg   %ax,%ax
f0104cdf:	90                   	nop

f0104ce0 <__udivdi3>:
f0104ce0:	55                   	push   %ebp
f0104ce1:	57                   	push   %edi
f0104ce2:	56                   	push   %esi
f0104ce3:	53                   	push   %ebx
f0104ce4:	83 ec 1c             	sub    $0x1c,%esp
f0104ce7:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f0104ceb:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f0104cef:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0104cf3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0104cf7:	85 f6                	test   %esi,%esi
f0104cf9:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0104cfd:	89 ca                	mov    %ecx,%edx
f0104cff:	89 f8                	mov    %edi,%eax
f0104d01:	75 3d                	jne    f0104d40 <__udivdi3+0x60>
f0104d03:	39 cf                	cmp    %ecx,%edi
f0104d05:	0f 87 c5 00 00 00    	ja     f0104dd0 <__udivdi3+0xf0>
f0104d0b:	85 ff                	test   %edi,%edi
f0104d0d:	89 fd                	mov    %edi,%ebp
f0104d0f:	75 0b                	jne    f0104d1c <__udivdi3+0x3c>
f0104d11:	b8 01 00 00 00       	mov    $0x1,%eax
f0104d16:	31 d2                	xor    %edx,%edx
f0104d18:	f7 f7                	div    %edi
f0104d1a:	89 c5                	mov    %eax,%ebp
f0104d1c:	89 c8                	mov    %ecx,%eax
f0104d1e:	31 d2                	xor    %edx,%edx
f0104d20:	f7 f5                	div    %ebp
f0104d22:	89 c1                	mov    %eax,%ecx
f0104d24:	89 d8                	mov    %ebx,%eax
f0104d26:	89 cf                	mov    %ecx,%edi
f0104d28:	f7 f5                	div    %ebp
f0104d2a:	89 c3                	mov    %eax,%ebx
f0104d2c:	89 d8                	mov    %ebx,%eax
f0104d2e:	89 fa                	mov    %edi,%edx
f0104d30:	83 c4 1c             	add    $0x1c,%esp
f0104d33:	5b                   	pop    %ebx
f0104d34:	5e                   	pop    %esi
f0104d35:	5f                   	pop    %edi
f0104d36:	5d                   	pop    %ebp
f0104d37:	c3                   	ret    
f0104d38:	90                   	nop
f0104d39:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104d40:	39 ce                	cmp    %ecx,%esi
f0104d42:	77 74                	ja     f0104db8 <__udivdi3+0xd8>
f0104d44:	0f bd fe             	bsr    %esi,%edi
f0104d47:	83 f7 1f             	xor    $0x1f,%edi
f0104d4a:	0f 84 98 00 00 00    	je     f0104de8 <__udivdi3+0x108>
f0104d50:	bb 20 00 00 00       	mov    $0x20,%ebx
f0104d55:	89 f9                	mov    %edi,%ecx
f0104d57:	89 c5                	mov    %eax,%ebp
f0104d59:	29 fb                	sub    %edi,%ebx
f0104d5b:	d3 e6                	shl    %cl,%esi
f0104d5d:	89 d9                	mov    %ebx,%ecx
f0104d5f:	d3 ed                	shr    %cl,%ebp
f0104d61:	89 f9                	mov    %edi,%ecx
f0104d63:	d3 e0                	shl    %cl,%eax
f0104d65:	09 ee                	or     %ebp,%esi
f0104d67:	89 d9                	mov    %ebx,%ecx
f0104d69:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0104d6d:	89 d5                	mov    %edx,%ebp
f0104d6f:	8b 44 24 08          	mov    0x8(%esp),%eax
f0104d73:	d3 ed                	shr    %cl,%ebp
f0104d75:	89 f9                	mov    %edi,%ecx
f0104d77:	d3 e2                	shl    %cl,%edx
f0104d79:	89 d9                	mov    %ebx,%ecx
f0104d7b:	d3 e8                	shr    %cl,%eax
f0104d7d:	09 c2                	or     %eax,%edx
f0104d7f:	89 d0                	mov    %edx,%eax
f0104d81:	89 ea                	mov    %ebp,%edx
f0104d83:	f7 f6                	div    %esi
f0104d85:	89 d5                	mov    %edx,%ebp
f0104d87:	89 c3                	mov    %eax,%ebx
f0104d89:	f7 64 24 0c          	mull   0xc(%esp)
f0104d8d:	39 d5                	cmp    %edx,%ebp
f0104d8f:	72 10                	jb     f0104da1 <__udivdi3+0xc1>
f0104d91:	8b 74 24 08          	mov    0x8(%esp),%esi
f0104d95:	89 f9                	mov    %edi,%ecx
f0104d97:	d3 e6                	shl    %cl,%esi
f0104d99:	39 c6                	cmp    %eax,%esi
f0104d9b:	73 07                	jae    f0104da4 <__udivdi3+0xc4>
f0104d9d:	39 d5                	cmp    %edx,%ebp
f0104d9f:	75 03                	jne    f0104da4 <__udivdi3+0xc4>
f0104da1:	83 eb 01             	sub    $0x1,%ebx
f0104da4:	31 ff                	xor    %edi,%edi
f0104da6:	89 d8                	mov    %ebx,%eax
f0104da8:	89 fa                	mov    %edi,%edx
f0104daa:	83 c4 1c             	add    $0x1c,%esp
f0104dad:	5b                   	pop    %ebx
f0104dae:	5e                   	pop    %esi
f0104daf:	5f                   	pop    %edi
f0104db0:	5d                   	pop    %ebp
f0104db1:	c3                   	ret    
f0104db2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0104db8:	31 ff                	xor    %edi,%edi
f0104dba:	31 db                	xor    %ebx,%ebx
f0104dbc:	89 d8                	mov    %ebx,%eax
f0104dbe:	89 fa                	mov    %edi,%edx
f0104dc0:	83 c4 1c             	add    $0x1c,%esp
f0104dc3:	5b                   	pop    %ebx
f0104dc4:	5e                   	pop    %esi
f0104dc5:	5f                   	pop    %edi
f0104dc6:	5d                   	pop    %ebp
f0104dc7:	c3                   	ret    
f0104dc8:	90                   	nop
f0104dc9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104dd0:	89 d8                	mov    %ebx,%eax
f0104dd2:	f7 f7                	div    %edi
f0104dd4:	31 ff                	xor    %edi,%edi
f0104dd6:	89 c3                	mov    %eax,%ebx
f0104dd8:	89 d8                	mov    %ebx,%eax
f0104dda:	89 fa                	mov    %edi,%edx
f0104ddc:	83 c4 1c             	add    $0x1c,%esp
f0104ddf:	5b                   	pop    %ebx
f0104de0:	5e                   	pop    %esi
f0104de1:	5f                   	pop    %edi
f0104de2:	5d                   	pop    %ebp
f0104de3:	c3                   	ret    
f0104de4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104de8:	39 ce                	cmp    %ecx,%esi
f0104dea:	72 0c                	jb     f0104df8 <__udivdi3+0x118>
f0104dec:	31 db                	xor    %ebx,%ebx
f0104dee:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0104df2:	0f 87 34 ff ff ff    	ja     f0104d2c <__udivdi3+0x4c>
f0104df8:	bb 01 00 00 00       	mov    $0x1,%ebx
f0104dfd:	e9 2a ff ff ff       	jmp    f0104d2c <__udivdi3+0x4c>
f0104e02:	66 90                	xchg   %ax,%ax
f0104e04:	66 90                	xchg   %ax,%ax
f0104e06:	66 90                	xchg   %ax,%ax
f0104e08:	66 90                	xchg   %ax,%ax
f0104e0a:	66 90                	xchg   %ax,%ax
f0104e0c:	66 90                	xchg   %ax,%ax
f0104e0e:	66 90                	xchg   %ax,%ax

f0104e10 <__umoddi3>:
f0104e10:	55                   	push   %ebp
f0104e11:	57                   	push   %edi
f0104e12:	56                   	push   %esi
f0104e13:	53                   	push   %ebx
f0104e14:	83 ec 1c             	sub    $0x1c,%esp
f0104e17:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f0104e1b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f0104e1f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0104e23:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0104e27:	85 d2                	test   %edx,%edx
f0104e29:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0104e2d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0104e31:	89 f3                	mov    %esi,%ebx
f0104e33:	89 3c 24             	mov    %edi,(%esp)
f0104e36:	89 74 24 04          	mov    %esi,0x4(%esp)
f0104e3a:	75 1c                	jne    f0104e58 <__umoddi3+0x48>
f0104e3c:	39 f7                	cmp    %esi,%edi
f0104e3e:	76 50                	jbe    f0104e90 <__umoddi3+0x80>
f0104e40:	89 c8                	mov    %ecx,%eax
f0104e42:	89 f2                	mov    %esi,%edx
f0104e44:	f7 f7                	div    %edi
f0104e46:	89 d0                	mov    %edx,%eax
f0104e48:	31 d2                	xor    %edx,%edx
f0104e4a:	83 c4 1c             	add    $0x1c,%esp
f0104e4d:	5b                   	pop    %ebx
f0104e4e:	5e                   	pop    %esi
f0104e4f:	5f                   	pop    %edi
f0104e50:	5d                   	pop    %ebp
f0104e51:	c3                   	ret    
f0104e52:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0104e58:	39 f2                	cmp    %esi,%edx
f0104e5a:	89 d0                	mov    %edx,%eax
f0104e5c:	77 52                	ja     f0104eb0 <__umoddi3+0xa0>
f0104e5e:	0f bd ea             	bsr    %edx,%ebp
f0104e61:	83 f5 1f             	xor    $0x1f,%ebp
f0104e64:	75 5a                	jne    f0104ec0 <__umoddi3+0xb0>
f0104e66:	3b 54 24 04          	cmp    0x4(%esp),%edx
f0104e6a:	0f 82 e0 00 00 00    	jb     f0104f50 <__umoddi3+0x140>
f0104e70:	39 0c 24             	cmp    %ecx,(%esp)
f0104e73:	0f 86 d7 00 00 00    	jbe    f0104f50 <__umoddi3+0x140>
f0104e79:	8b 44 24 08          	mov    0x8(%esp),%eax
f0104e7d:	8b 54 24 04          	mov    0x4(%esp),%edx
f0104e81:	83 c4 1c             	add    $0x1c,%esp
f0104e84:	5b                   	pop    %ebx
f0104e85:	5e                   	pop    %esi
f0104e86:	5f                   	pop    %edi
f0104e87:	5d                   	pop    %ebp
f0104e88:	c3                   	ret    
f0104e89:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104e90:	85 ff                	test   %edi,%edi
f0104e92:	89 fd                	mov    %edi,%ebp
f0104e94:	75 0b                	jne    f0104ea1 <__umoddi3+0x91>
f0104e96:	b8 01 00 00 00       	mov    $0x1,%eax
f0104e9b:	31 d2                	xor    %edx,%edx
f0104e9d:	f7 f7                	div    %edi
f0104e9f:	89 c5                	mov    %eax,%ebp
f0104ea1:	89 f0                	mov    %esi,%eax
f0104ea3:	31 d2                	xor    %edx,%edx
f0104ea5:	f7 f5                	div    %ebp
f0104ea7:	89 c8                	mov    %ecx,%eax
f0104ea9:	f7 f5                	div    %ebp
f0104eab:	89 d0                	mov    %edx,%eax
f0104ead:	eb 99                	jmp    f0104e48 <__umoddi3+0x38>
f0104eaf:	90                   	nop
f0104eb0:	89 c8                	mov    %ecx,%eax
f0104eb2:	89 f2                	mov    %esi,%edx
f0104eb4:	83 c4 1c             	add    $0x1c,%esp
f0104eb7:	5b                   	pop    %ebx
f0104eb8:	5e                   	pop    %esi
f0104eb9:	5f                   	pop    %edi
f0104eba:	5d                   	pop    %ebp
f0104ebb:	c3                   	ret    
f0104ebc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104ec0:	8b 34 24             	mov    (%esp),%esi
f0104ec3:	bf 20 00 00 00       	mov    $0x20,%edi
f0104ec8:	89 e9                	mov    %ebp,%ecx
f0104eca:	29 ef                	sub    %ebp,%edi
f0104ecc:	d3 e0                	shl    %cl,%eax
f0104ece:	89 f9                	mov    %edi,%ecx
f0104ed0:	89 f2                	mov    %esi,%edx
f0104ed2:	d3 ea                	shr    %cl,%edx
f0104ed4:	89 e9                	mov    %ebp,%ecx
f0104ed6:	09 c2                	or     %eax,%edx
f0104ed8:	89 d8                	mov    %ebx,%eax
f0104eda:	89 14 24             	mov    %edx,(%esp)
f0104edd:	89 f2                	mov    %esi,%edx
f0104edf:	d3 e2                	shl    %cl,%edx
f0104ee1:	89 f9                	mov    %edi,%ecx
f0104ee3:	89 54 24 04          	mov    %edx,0x4(%esp)
f0104ee7:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0104eeb:	d3 e8                	shr    %cl,%eax
f0104eed:	89 e9                	mov    %ebp,%ecx
f0104eef:	89 c6                	mov    %eax,%esi
f0104ef1:	d3 e3                	shl    %cl,%ebx
f0104ef3:	89 f9                	mov    %edi,%ecx
f0104ef5:	89 d0                	mov    %edx,%eax
f0104ef7:	d3 e8                	shr    %cl,%eax
f0104ef9:	89 e9                	mov    %ebp,%ecx
f0104efb:	09 d8                	or     %ebx,%eax
f0104efd:	89 d3                	mov    %edx,%ebx
f0104eff:	89 f2                	mov    %esi,%edx
f0104f01:	f7 34 24             	divl   (%esp)
f0104f04:	89 d6                	mov    %edx,%esi
f0104f06:	d3 e3                	shl    %cl,%ebx
f0104f08:	f7 64 24 04          	mull   0x4(%esp)
f0104f0c:	39 d6                	cmp    %edx,%esi
f0104f0e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0104f12:	89 d1                	mov    %edx,%ecx
f0104f14:	89 c3                	mov    %eax,%ebx
f0104f16:	72 08                	jb     f0104f20 <__umoddi3+0x110>
f0104f18:	75 11                	jne    f0104f2b <__umoddi3+0x11b>
f0104f1a:	39 44 24 08          	cmp    %eax,0x8(%esp)
f0104f1e:	73 0b                	jae    f0104f2b <__umoddi3+0x11b>
f0104f20:	2b 44 24 04          	sub    0x4(%esp),%eax
f0104f24:	1b 14 24             	sbb    (%esp),%edx
f0104f27:	89 d1                	mov    %edx,%ecx
f0104f29:	89 c3                	mov    %eax,%ebx
f0104f2b:	8b 54 24 08          	mov    0x8(%esp),%edx
f0104f2f:	29 da                	sub    %ebx,%edx
f0104f31:	19 ce                	sbb    %ecx,%esi
f0104f33:	89 f9                	mov    %edi,%ecx
f0104f35:	89 f0                	mov    %esi,%eax
f0104f37:	d3 e0                	shl    %cl,%eax
f0104f39:	89 e9                	mov    %ebp,%ecx
f0104f3b:	d3 ea                	shr    %cl,%edx
f0104f3d:	89 e9                	mov    %ebp,%ecx
f0104f3f:	d3 ee                	shr    %cl,%esi
f0104f41:	09 d0                	or     %edx,%eax
f0104f43:	89 f2                	mov    %esi,%edx
f0104f45:	83 c4 1c             	add    $0x1c,%esp
f0104f48:	5b                   	pop    %ebx
f0104f49:	5e                   	pop    %esi
f0104f4a:	5f                   	pop    %edi
f0104f4b:	5d                   	pop    %ebp
f0104f4c:	c3                   	ret    
f0104f4d:	8d 76 00             	lea    0x0(%esi),%esi
f0104f50:	29 f9                	sub    %edi,%ecx
f0104f52:	19 d6                	sbb    %edx,%esi
f0104f54:	89 74 24 04          	mov    %esi,0x4(%esp)
f0104f58:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0104f5c:	e9 18 ff ff ff       	jmp    f0104e79 <__umoddi3+0x69>
