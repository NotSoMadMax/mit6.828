
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
f0100015:	b8 00 e0 11 00       	mov    $0x11e000,%eax
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
f0100034:	bc 00 e0 11 f0       	mov    $0xf011e000,%esp

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
f0100048:	83 3d 80 fe 22 f0 00 	cmpl   $0x0,0xf022fe80
f010004f:	75 3a                	jne    f010008b <_panic+0x4b>
		goto dead;
	panicstr = fmt;
f0100051:	89 35 80 fe 22 f0    	mov    %esi,0xf022fe80

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f0100057:	fa                   	cli    
f0100058:	fc                   	cld    

	va_start(ap, fmt);
f0100059:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic on CPU %d at %s:%d: ", cpunum(), file, line);
f010005c:	e8 c5 59 00 00       	call   f0105a26 <cpunum>
f0100061:	ff 75 0c             	pushl  0xc(%ebp)
f0100064:	ff 75 08             	pushl  0x8(%ebp)
f0100067:	50                   	push   %eax
f0100068:	68 c0 60 10 f0       	push   $0xf01060c0
f010006d:	e8 ec 35 00 00       	call   f010365e <cprintf>
	vcprintf(fmt, ap);
f0100072:	83 c4 08             	add    $0x8,%esp
f0100075:	53                   	push   %ebx
f0100076:	56                   	push   %esi
f0100077:	e8 bc 35 00 00       	call   f0103638 <vcprintf>
	cprintf("\n");
f010007c:	c7 04 24 a4 72 10 f0 	movl   $0xf01072a4,(%esp)
f0100083:	e8 d6 35 00 00       	call   f010365e <cprintf>
	va_end(ap);
f0100088:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f010008b:	83 ec 0c             	sub    $0xc,%esp
f010008e:	6a 00                	push   $0x0
f0100090:	e8 5c 08 00 00       	call   f01008f1 <monitor>
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
f01000a1:	b8 08 10 27 f0       	mov    $0xf0271008,%eax
f01000a6:	2d 10 e9 22 f0       	sub    $0xf022e910,%eax
f01000ab:	50                   	push   %eax
f01000ac:	6a 00                	push   $0x0
f01000ae:	68 10 e9 22 f0       	push   $0xf022e910
f01000b3:	e8 4c 53 00 00       	call   f0105404 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000b8:	e8 82 05 00 00       	call   f010063f <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000bd:	83 c4 08             	add    $0x8,%esp
f01000c0:	68 ac 1a 00 00       	push   $0x1aac
f01000c5:	68 2c 61 10 f0       	push   $0xf010612c
f01000ca:	e8 8f 35 00 00       	call   f010365e <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f01000cf:	e8 13 12 00 00       	call   f01012e7 <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f01000d4:	e8 ee 2d 00 00       	call   f0102ec7 <env_init>
	trap_init();
f01000d9:	e8 61 36 00 00       	call   f010373f <trap_init>

	// Lab 4 multiprocessor initialization functions
	mp_init();
f01000de:	e8 39 56 00 00       	call   f010571c <mp_init>
	lapic_init();
f01000e3:	e8 59 59 00 00       	call   f0105a41 <lapic_init>

	// Lab 4 multitasking initialization functions
	pic_init();
f01000e8:	e8 98 34 00 00       	call   f0103585 <pic_init>
extern struct spinlock kernel_lock;

static inline void
lock_kernel(void)
{
	spin_lock(&kernel_lock);
f01000ed:	c7 04 24 c0 03 12 f0 	movl   $0xf01203c0,(%esp)
f01000f4:	e8 9b 5b 00 00       	call   f0105c94 <spin_lock>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01000f9:	83 c4 10             	add    $0x10,%esp
f01000fc:	83 3d 88 fe 22 f0 07 	cmpl   $0x7,0xf022fe88
f0100103:	77 16                	ja     f010011b <i386_init+0x81>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100105:	68 00 70 00 00       	push   $0x7000
f010010a:	68 e4 60 10 f0       	push   $0xf01060e4
f010010f:	6a 56                	push   $0x56
f0100111:	68 47 61 10 f0       	push   $0xf0106147
f0100116:	e8 25 ff ff ff       	call   f0100040 <_panic>
	void *code;
	struct CpuInfo *c;

	// Write entry code to unused memory at MPENTRY_PADDR
	code = KADDR(MPENTRY_PADDR);
	memmove(code, mpentry_start, mpentry_end - mpentry_start);
f010011b:	83 ec 04             	sub    $0x4,%esp
f010011e:	b8 82 56 10 f0       	mov    $0xf0105682,%eax
f0100123:	2d 08 56 10 f0       	sub    $0xf0105608,%eax
f0100128:	50                   	push   %eax
f0100129:	68 08 56 10 f0       	push   $0xf0105608
f010012e:	68 00 70 00 f0       	push   $0xf0007000
f0100133:	e8 19 53 00 00       	call   f0105451 <memmove>
f0100138:	83 c4 10             	add    $0x10,%esp

	// Boot each AP one at a time
	for (c = cpus; c < cpus + ncpu; c++) {
f010013b:	bb 20 00 23 f0       	mov    $0xf0230020,%ebx
f0100140:	eb 4d                	jmp    f010018f <i386_init+0xf5>
		if (c == cpus + cpunum())  // We've started already.
f0100142:	e8 df 58 00 00       	call   f0105a26 <cpunum>
f0100147:	6b c0 74             	imul   $0x74,%eax,%eax
f010014a:	05 20 00 23 f0       	add    $0xf0230020,%eax
f010014f:	39 c3                	cmp    %eax,%ebx
f0100151:	74 39                	je     f010018c <i386_init+0xf2>
			continue;

		// Tell mpentry.S what stack to use 
		mpentry_kstack = percpu_kstacks[c - cpus] + KSTKSIZE;
f0100153:	89 d8                	mov    %ebx,%eax
f0100155:	2d 20 00 23 f0       	sub    $0xf0230020,%eax
f010015a:	c1 f8 02             	sar    $0x2,%eax
f010015d:	69 c0 35 c2 72 4f    	imul   $0x4f72c235,%eax,%eax
f0100163:	c1 e0 0f             	shl    $0xf,%eax
f0100166:	05 00 90 23 f0       	add    $0xf0239000,%eax
f010016b:	a3 84 fe 22 f0       	mov    %eax,0xf022fe84
		// Start the CPU at mpentry_start
		lapic_startap(c->cpu_id, PADDR(code));
f0100170:	83 ec 08             	sub    $0x8,%esp
f0100173:	68 00 70 00 00       	push   $0x7000
f0100178:	0f b6 03             	movzbl (%ebx),%eax
f010017b:	50                   	push   %eax
f010017c:	e8 0e 5a 00 00       	call   f0105b8f <lapic_startap>
f0100181:	83 c4 10             	add    $0x10,%esp
		// Wait for the CPU to finish some basic setup in mp_main()
		while(c->cpu_status != CPU_STARTED)
f0100184:	8b 43 04             	mov    0x4(%ebx),%eax
f0100187:	83 f8 01             	cmp    $0x1,%eax
f010018a:	75 f8                	jne    f0100184 <i386_init+0xea>
	// Write entry code to unused memory at MPENTRY_PADDR
	code = KADDR(MPENTRY_PADDR);
	memmove(code, mpentry_start, mpentry_end - mpentry_start);

	// Boot each AP one at a time
	for (c = cpus; c < cpus + ncpu; c++) {
f010018c:	83 c3 74             	add    $0x74,%ebx
f010018f:	6b 05 c4 03 23 f0 74 	imul   $0x74,0xf02303c4,%eax
f0100196:	05 20 00 23 f0       	add    $0xf0230020,%eax
f010019b:	39 c3                	cmp    %eax,%ebx
f010019d:	72 a3                	jb     f0100142 <i386_init+0xa8>
	// Starting non-boot CPUs
	boot_aps();

#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
f010019f:	83 ec 08             	sub    $0x8,%esp
f01001a2:	6a 00                	push   $0x0
f01001a4:	68 cc 4e 22 f0       	push   $0xf0224ecc
f01001a9:	e8 f2 2e 00 00       	call   f01030a0 <env_create>
	ENV_CREATE(user_yield, ENV_TYPE_USER);
	ENV_CREATE(user_yield, ENV_TYPE_USER);
#endif // TEST*

	// Schedule and run the first user environment!
	sched_yield();
f01001ae:	e8 88 40 00 00       	call   f010423b <sched_yield>

f01001b3 <mp_main>:
}

// Setup code for APs
void
mp_main(void)
{
f01001b3:	55                   	push   %ebp
f01001b4:	89 e5                	mov    %esp,%ebp
f01001b6:	83 ec 08             	sub    $0x8,%esp
	// We are in high EIP now, safe to switch to kern_pgdir 
	lcr3(PADDR(kern_pgdir));
f01001b9:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01001be:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01001c3:	77 12                	ja     f01001d7 <mp_main+0x24>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01001c5:	50                   	push   %eax
f01001c6:	68 08 61 10 f0       	push   $0xf0106108
f01001cb:	6a 6d                	push   $0x6d
f01001cd:	68 47 61 10 f0       	push   $0xf0106147
f01001d2:	e8 69 fe ff ff       	call   f0100040 <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f01001d7:	05 00 00 00 10       	add    $0x10000000,%eax
f01001dc:	0f 22 d8             	mov    %eax,%cr3
	cprintf("SMP: CPU %d starting\n", cpunum());
f01001df:	e8 42 58 00 00       	call   f0105a26 <cpunum>
f01001e4:	83 ec 08             	sub    $0x8,%esp
f01001e7:	50                   	push   %eax
f01001e8:	68 53 61 10 f0       	push   $0xf0106153
f01001ed:	e8 6c 34 00 00       	call   f010365e <cprintf>

	lapic_init();
f01001f2:	e8 4a 58 00 00       	call   f0105a41 <lapic_init>
	env_init_percpu();
f01001f7:	e8 9b 2c 00 00       	call   f0102e97 <env_init_percpu>
	trap_init_percpu();
f01001fc:	e8 71 34 00 00       	call   f0103672 <trap_init_percpu>
	xchg(&thiscpu->cpu_status, CPU_STARTED); // tell boot_aps() we're up
f0100201:	e8 20 58 00 00       	call   f0105a26 <cpunum>
f0100206:	6b d0 74             	imul   $0x74,%eax,%edx
f0100209:	81 c2 20 00 23 f0    	add    $0xf0230020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"
f010020f:	b8 01 00 00 00       	mov    $0x1,%eax
f0100214:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
f0100218:	c7 04 24 c0 03 12 f0 	movl   $0xf01203c0,(%esp)
f010021f:	e8 70 5a 00 00       	call   f0105c94 <spin_lock>
	// only one CPU can enter the scheduler at a time!
	//
	// Your code here:

    lock_kernel();
    sched_yield();
f0100224:	e8 12 40 00 00       	call   f010423b <sched_yield>

f0100229 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100229:	55                   	push   %ebp
f010022a:	89 e5                	mov    %esp,%ebp
f010022c:	53                   	push   %ebx
f010022d:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100230:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100233:	ff 75 0c             	pushl  0xc(%ebp)
f0100236:	ff 75 08             	pushl  0x8(%ebp)
f0100239:	68 69 61 10 f0       	push   $0xf0106169
f010023e:	e8 1b 34 00 00       	call   f010365e <cprintf>
	vcprintf(fmt, ap);
f0100243:	83 c4 08             	add    $0x8,%esp
f0100246:	53                   	push   %ebx
f0100247:	ff 75 10             	pushl  0x10(%ebp)
f010024a:	e8 e9 33 00 00       	call   f0103638 <vcprintf>
	cprintf("\n");
f010024f:	c7 04 24 a4 72 10 f0 	movl   $0xf01072a4,(%esp)
f0100256:	e8 03 34 00 00       	call   f010365e <cprintf>
	va_end(ap);
}
f010025b:	83 c4 10             	add    $0x10,%esp
f010025e:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100261:	c9                   	leave  
f0100262:	c3                   	ret    

f0100263 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100263:	55                   	push   %ebp
f0100264:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100266:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010026b:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f010026c:	a8 01                	test   $0x1,%al
f010026e:	74 0b                	je     f010027b <serial_proc_data+0x18>
f0100270:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100275:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100276:	0f b6 c0             	movzbl %al,%eax
f0100279:	eb 05                	jmp    f0100280 <serial_proc_data+0x1d>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f010027b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f0100280:	5d                   	pop    %ebp
f0100281:	c3                   	ret    

f0100282 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f0100282:	55                   	push   %ebp
f0100283:	89 e5                	mov    %esp,%ebp
f0100285:	53                   	push   %ebx
f0100286:	83 ec 04             	sub    $0x4,%esp
f0100289:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f010028b:	eb 2b                	jmp    f01002b8 <cons_intr+0x36>
		if (c == 0)
f010028d:	85 c0                	test   %eax,%eax
f010028f:	74 27                	je     f01002b8 <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f0100291:	8b 0d 24 f2 22 f0    	mov    0xf022f224,%ecx
f0100297:	8d 51 01             	lea    0x1(%ecx),%edx
f010029a:	89 15 24 f2 22 f0    	mov    %edx,0xf022f224
f01002a0:	88 81 20 f0 22 f0    	mov    %al,-0xfdd0fe0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f01002a6:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01002ac:	75 0a                	jne    f01002b8 <cons_intr+0x36>
			cons.wpos = 0;
f01002ae:	c7 05 24 f2 22 f0 00 	movl   $0x0,0xf022f224
f01002b5:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01002b8:	ff d3                	call   *%ebx
f01002ba:	83 f8 ff             	cmp    $0xffffffff,%eax
f01002bd:	75 ce                	jne    f010028d <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01002bf:	83 c4 04             	add    $0x4,%esp
f01002c2:	5b                   	pop    %ebx
f01002c3:	5d                   	pop    %ebp
f01002c4:	c3                   	ret    

f01002c5 <kbd_proc_data>:
f01002c5:	ba 64 00 00 00       	mov    $0x64,%edx
f01002ca:	ec                   	in     (%dx),%al
	int c;
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
f01002cb:	a8 01                	test   $0x1,%al
f01002cd:	0f 84 f8 00 00 00    	je     f01003cb <kbd_proc_data+0x106>
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
f01002d3:	a8 20                	test   $0x20,%al
f01002d5:	0f 85 f6 00 00 00    	jne    f01003d1 <kbd_proc_data+0x10c>
f01002db:	ba 60 00 00 00       	mov    $0x60,%edx
f01002e0:	ec                   	in     (%dx),%al
f01002e1:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01002e3:	3c e0                	cmp    $0xe0,%al
f01002e5:	75 0d                	jne    f01002f4 <kbd_proc_data+0x2f>
		// E0 escape character
		shift |= E0ESC;
f01002e7:	83 0d 00 f0 22 f0 40 	orl    $0x40,0xf022f000
		return 0;
f01002ee:	b8 00 00 00 00       	mov    $0x0,%eax
f01002f3:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01002f4:	55                   	push   %ebp
f01002f5:	89 e5                	mov    %esp,%ebp
f01002f7:	53                   	push   %ebx
f01002f8:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f01002fb:	84 c0                	test   %al,%al
f01002fd:	79 36                	jns    f0100335 <kbd_proc_data+0x70>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01002ff:	8b 0d 00 f0 22 f0    	mov    0xf022f000,%ecx
f0100305:	89 cb                	mov    %ecx,%ebx
f0100307:	83 e3 40             	and    $0x40,%ebx
f010030a:	83 e0 7f             	and    $0x7f,%eax
f010030d:	85 db                	test   %ebx,%ebx
f010030f:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100312:	0f b6 d2             	movzbl %dl,%edx
f0100315:	0f b6 82 e0 62 10 f0 	movzbl -0xfef9d20(%edx),%eax
f010031c:	83 c8 40             	or     $0x40,%eax
f010031f:	0f b6 c0             	movzbl %al,%eax
f0100322:	f7 d0                	not    %eax
f0100324:	21 c8                	and    %ecx,%eax
f0100326:	a3 00 f0 22 f0       	mov    %eax,0xf022f000
		return 0;
f010032b:	b8 00 00 00 00       	mov    $0x0,%eax
f0100330:	e9 a4 00 00 00       	jmp    f01003d9 <kbd_proc_data+0x114>
	} else if (shift & E0ESC) {
f0100335:	8b 0d 00 f0 22 f0    	mov    0xf022f000,%ecx
f010033b:	f6 c1 40             	test   $0x40,%cl
f010033e:	74 0e                	je     f010034e <kbd_proc_data+0x89>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100340:	83 c8 80             	or     $0xffffff80,%eax
f0100343:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100345:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100348:	89 0d 00 f0 22 f0    	mov    %ecx,0xf022f000
	}

	shift |= shiftcode[data];
f010034e:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f0100351:	0f b6 82 e0 62 10 f0 	movzbl -0xfef9d20(%edx),%eax
f0100358:	0b 05 00 f0 22 f0    	or     0xf022f000,%eax
f010035e:	0f b6 8a e0 61 10 f0 	movzbl -0xfef9e20(%edx),%ecx
f0100365:	31 c8                	xor    %ecx,%eax
f0100367:	a3 00 f0 22 f0       	mov    %eax,0xf022f000

	c = charcode[shift & (CTL | SHIFT)][data];
f010036c:	89 c1                	mov    %eax,%ecx
f010036e:	83 e1 03             	and    $0x3,%ecx
f0100371:	8b 0c 8d c0 61 10 f0 	mov    -0xfef9e40(,%ecx,4),%ecx
f0100378:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f010037c:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f010037f:	a8 08                	test   $0x8,%al
f0100381:	74 1b                	je     f010039e <kbd_proc_data+0xd9>
		if ('a' <= c && c <= 'z')
f0100383:	89 da                	mov    %ebx,%edx
f0100385:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100388:	83 f9 19             	cmp    $0x19,%ecx
f010038b:	77 05                	ja     f0100392 <kbd_proc_data+0xcd>
			c += 'A' - 'a';
f010038d:	83 eb 20             	sub    $0x20,%ebx
f0100390:	eb 0c                	jmp    f010039e <kbd_proc_data+0xd9>
		else if ('A' <= c && c <= 'Z')
f0100392:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f0100395:	8d 4b 20             	lea    0x20(%ebx),%ecx
f0100398:	83 fa 19             	cmp    $0x19,%edx
f010039b:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f010039e:	f7 d0                	not    %eax
f01003a0:	a8 06                	test   $0x6,%al
f01003a2:	75 33                	jne    f01003d7 <kbd_proc_data+0x112>
f01003a4:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01003aa:	75 2b                	jne    f01003d7 <kbd_proc_data+0x112>
		cprintf("Rebooting!\n");
f01003ac:	83 ec 0c             	sub    $0xc,%esp
f01003af:	68 83 61 10 f0       	push   $0xf0106183
f01003b4:	e8 a5 32 00 00       	call   f010365e <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01003b9:	ba 92 00 00 00       	mov    $0x92,%edx
f01003be:	b8 03 00 00 00       	mov    $0x3,%eax
f01003c3:	ee                   	out    %al,(%dx)
f01003c4:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01003c7:	89 d8                	mov    %ebx,%eax
f01003c9:	eb 0e                	jmp    f01003d9 <kbd_proc_data+0x114>
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
f01003cb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01003d0:	c3                   	ret    
	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
		return -1;
f01003d1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01003d6:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01003d7:	89 d8                	mov    %ebx,%eax
}
f01003d9:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01003dc:	c9                   	leave  
f01003dd:	c3                   	ret    

f01003de <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01003de:	55                   	push   %ebp
f01003df:	89 e5                	mov    %esp,%ebp
f01003e1:	57                   	push   %edi
f01003e2:	56                   	push   %esi
f01003e3:	53                   	push   %ebx
f01003e4:	83 ec 1c             	sub    $0x1c,%esp
f01003e7:	89 c7                	mov    %eax,%edi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01003e9:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01003ee:	be fd 03 00 00       	mov    $0x3fd,%esi
f01003f3:	b9 84 00 00 00       	mov    $0x84,%ecx
f01003f8:	eb 09                	jmp    f0100403 <cons_putc+0x25>
f01003fa:	89 ca                	mov    %ecx,%edx
f01003fc:	ec                   	in     (%dx),%al
f01003fd:	ec                   	in     (%dx),%al
f01003fe:	ec                   	in     (%dx),%al
f01003ff:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f0100400:	83 c3 01             	add    $0x1,%ebx
f0100403:	89 f2                	mov    %esi,%edx
f0100405:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100406:	a8 20                	test   $0x20,%al
f0100408:	75 08                	jne    f0100412 <cons_putc+0x34>
f010040a:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100410:	7e e8                	jle    f01003fa <cons_putc+0x1c>
f0100412:	89 f8                	mov    %edi,%eax
f0100414:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100417:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010041c:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010041d:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100422:	be 79 03 00 00       	mov    $0x379,%esi
f0100427:	b9 84 00 00 00       	mov    $0x84,%ecx
f010042c:	eb 09                	jmp    f0100437 <cons_putc+0x59>
f010042e:	89 ca                	mov    %ecx,%edx
f0100430:	ec                   	in     (%dx),%al
f0100431:	ec                   	in     (%dx),%al
f0100432:	ec                   	in     (%dx),%al
f0100433:	ec                   	in     (%dx),%al
f0100434:	83 c3 01             	add    $0x1,%ebx
f0100437:	89 f2                	mov    %esi,%edx
f0100439:	ec                   	in     (%dx),%al
f010043a:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100440:	7f 04                	jg     f0100446 <cons_putc+0x68>
f0100442:	84 c0                	test   %al,%al
f0100444:	79 e8                	jns    f010042e <cons_putc+0x50>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100446:	ba 78 03 00 00       	mov    $0x378,%edx
f010044b:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f010044f:	ee                   	out    %al,(%dx)
f0100450:	ba 7a 03 00 00       	mov    $0x37a,%edx
f0100455:	b8 0d 00 00 00       	mov    $0xd,%eax
f010045a:	ee                   	out    %al,(%dx)
f010045b:	b8 08 00 00 00       	mov    $0x8,%eax
f0100460:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100461:	89 fa                	mov    %edi,%edx
f0100463:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100469:	89 f8                	mov    %edi,%eax
f010046b:	80 cc 07             	or     $0x7,%ah
f010046e:	85 d2                	test   %edx,%edx
f0100470:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100473:	89 f8                	mov    %edi,%eax
f0100475:	0f b6 c0             	movzbl %al,%eax
f0100478:	83 f8 09             	cmp    $0x9,%eax
f010047b:	74 74                	je     f01004f1 <cons_putc+0x113>
f010047d:	83 f8 09             	cmp    $0x9,%eax
f0100480:	7f 0a                	jg     f010048c <cons_putc+0xae>
f0100482:	83 f8 08             	cmp    $0x8,%eax
f0100485:	74 14                	je     f010049b <cons_putc+0xbd>
f0100487:	e9 99 00 00 00       	jmp    f0100525 <cons_putc+0x147>
f010048c:	83 f8 0a             	cmp    $0xa,%eax
f010048f:	74 3a                	je     f01004cb <cons_putc+0xed>
f0100491:	83 f8 0d             	cmp    $0xd,%eax
f0100494:	74 3d                	je     f01004d3 <cons_putc+0xf5>
f0100496:	e9 8a 00 00 00       	jmp    f0100525 <cons_putc+0x147>
	case '\b':
		if (crt_pos > 0) {
f010049b:	0f b7 05 28 f2 22 f0 	movzwl 0xf022f228,%eax
f01004a2:	66 85 c0             	test   %ax,%ax
f01004a5:	0f 84 e6 00 00 00    	je     f0100591 <cons_putc+0x1b3>
			crt_pos--;
f01004ab:	83 e8 01             	sub    $0x1,%eax
f01004ae:	66 a3 28 f2 22 f0    	mov    %ax,0xf022f228
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01004b4:	0f b7 c0             	movzwl %ax,%eax
f01004b7:	66 81 e7 00 ff       	and    $0xff00,%di
f01004bc:	83 cf 20             	or     $0x20,%edi
f01004bf:	8b 15 2c f2 22 f0    	mov    0xf022f22c,%edx
f01004c5:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01004c9:	eb 78                	jmp    f0100543 <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01004cb:	66 83 05 28 f2 22 f0 	addw   $0x50,0xf022f228
f01004d2:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01004d3:	0f b7 05 28 f2 22 f0 	movzwl 0xf022f228,%eax
f01004da:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01004e0:	c1 e8 16             	shr    $0x16,%eax
f01004e3:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01004e6:	c1 e0 04             	shl    $0x4,%eax
f01004e9:	66 a3 28 f2 22 f0    	mov    %ax,0xf022f228
f01004ef:	eb 52                	jmp    f0100543 <cons_putc+0x165>
		break;
	case '\t':
		cons_putc(' ');
f01004f1:	b8 20 00 00 00       	mov    $0x20,%eax
f01004f6:	e8 e3 fe ff ff       	call   f01003de <cons_putc>
		cons_putc(' ');
f01004fb:	b8 20 00 00 00       	mov    $0x20,%eax
f0100500:	e8 d9 fe ff ff       	call   f01003de <cons_putc>
		cons_putc(' ');
f0100505:	b8 20 00 00 00       	mov    $0x20,%eax
f010050a:	e8 cf fe ff ff       	call   f01003de <cons_putc>
		cons_putc(' ');
f010050f:	b8 20 00 00 00       	mov    $0x20,%eax
f0100514:	e8 c5 fe ff ff       	call   f01003de <cons_putc>
		cons_putc(' ');
f0100519:	b8 20 00 00 00       	mov    $0x20,%eax
f010051e:	e8 bb fe ff ff       	call   f01003de <cons_putc>
f0100523:	eb 1e                	jmp    f0100543 <cons_putc+0x165>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100525:	0f b7 05 28 f2 22 f0 	movzwl 0xf022f228,%eax
f010052c:	8d 50 01             	lea    0x1(%eax),%edx
f010052f:	66 89 15 28 f2 22 f0 	mov    %dx,0xf022f228
f0100536:	0f b7 c0             	movzwl %ax,%eax
f0100539:	8b 15 2c f2 22 f0    	mov    0xf022f22c,%edx
f010053f:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100543:	66 81 3d 28 f2 22 f0 	cmpw   $0x7cf,0xf022f228
f010054a:	cf 07 
f010054c:	76 43                	jbe    f0100591 <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010054e:	a1 2c f2 22 f0       	mov    0xf022f22c,%eax
f0100553:	83 ec 04             	sub    $0x4,%esp
f0100556:	68 00 0f 00 00       	push   $0xf00
f010055b:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100561:	52                   	push   %edx
f0100562:	50                   	push   %eax
f0100563:	e8 e9 4e 00 00       	call   f0105451 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100568:	8b 15 2c f2 22 f0    	mov    0xf022f22c,%edx
f010056e:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f0100574:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f010057a:	83 c4 10             	add    $0x10,%esp
f010057d:	66 c7 00 20 07       	movw   $0x720,(%eax)
f0100582:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100585:	39 d0                	cmp    %edx,%eax
f0100587:	75 f4                	jne    f010057d <cons_putc+0x19f>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100589:	66 83 2d 28 f2 22 f0 	subw   $0x50,0xf022f228
f0100590:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100591:	8b 0d 30 f2 22 f0    	mov    0xf022f230,%ecx
f0100597:	b8 0e 00 00 00       	mov    $0xe,%eax
f010059c:	89 ca                	mov    %ecx,%edx
f010059e:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010059f:	0f b7 1d 28 f2 22 f0 	movzwl 0xf022f228,%ebx
f01005a6:	8d 71 01             	lea    0x1(%ecx),%esi
f01005a9:	89 d8                	mov    %ebx,%eax
f01005ab:	66 c1 e8 08          	shr    $0x8,%ax
f01005af:	89 f2                	mov    %esi,%edx
f01005b1:	ee                   	out    %al,(%dx)
f01005b2:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005b7:	89 ca                	mov    %ecx,%edx
f01005b9:	ee                   	out    %al,(%dx)
f01005ba:	89 d8                	mov    %ebx,%eax
f01005bc:	89 f2                	mov    %esi,%edx
f01005be:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01005bf:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01005c2:	5b                   	pop    %ebx
f01005c3:	5e                   	pop    %esi
f01005c4:	5f                   	pop    %edi
f01005c5:	5d                   	pop    %ebp
f01005c6:	c3                   	ret    

f01005c7 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01005c7:	80 3d 34 f2 22 f0 00 	cmpb   $0x0,0xf022f234
f01005ce:	74 11                	je     f01005e1 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01005d0:	55                   	push   %ebp
f01005d1:	89 e5                	mov    %esp,%ebp
f01005d3:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f01005d6:	b8 63 02 10 f0       	mov    $0xf0100263,%eax
f01005db:	e8 a2 fc ff ff       	call   f0100282 <cons_intr>
}
f01005e0:	c9                   	leave  
f01005e1:	f3 c3                	repz ret 

f01005e3 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01005e3:	55                   	push   %ebp
f01005e4:	89 e5                	mov    %esp,%ebp
f01005e6:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01005e9:	b8 c5 02 10 f0       	mov    $0xf01002c5,%eax
f01005ee:	e8 8f fc ff ff       	call   f0100282 <cons_intr>
}
f01005f3:	c9                   	leave  
f01005f4:	c3                   	ret    

f01005f5 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01005f5:	55                   	push   %ebp
f01005f6:	89 e5                	mov    %esp,%ebp
f01005f8:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01005fb:	e8 c7 ff ff ff       	call   f01005c7 <serial_intr>
	kbd_intr();
f0100600:	e8 de ff ff ff       	call   f01005e3 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100605:	a1 20 f2 22 f0       	mov    0xf022f220,%eax
f010060a:	3b 05 24 f2 22 f0    	cmp    0xf022f224,%eax
f0100610:	74 26                	je     f0100638 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f0100612:	8d 50 01             	lea    0x1(%eax),%edx
f0100615:	89 15 20 f2 22 f0    	mov    %edx,0xf022f220
f010061b:	0f b6 88 20 f0 22 f0 	movzbl -0xfdd0fe0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f0100622:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f0100624:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010062a:	75 11                	jne    f010063d <cons_getc+0x48>
			cons.rpos = 0;
f010062c:	c7 05 20 f2 22 f0 00 	movl   $0x0,0xf022f220
f0100633:	00 00 00 
f0100636:	eb 05                	jmp    f010063d <cons_getc+0x48>
		return c;
	}
	return 0;
f0100638:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010063d:	c9                   	leave  
f010063e:	c3                   	ret    

f010063f <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f010063f:	55                   	push   %ebp
f0100640:	89 e5                	mov    %esp,%ebp
f0100642:	57                   	push   %edi
f0100643:	56                   	push   %esi
f0100644:	53                   	push   %ebx
f0100645:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100648:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010064f:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100656:	5a a5 
	if (*cp != 0xA55A) {
f0100658:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010065f:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100663:	74 11                	je     f0100676 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100665:	c7 05 30 f2 22 f0 b4 	movl   $0x3b4,0xf022f230
f010066c:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010066f:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f0100674:	eb 16                	jmp    f010068c <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100676:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010067d:	c7 05 30 f2 22 f0 d4 	movl   $0x3d4,0xf022f230
f0100684:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100687:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f010068c:	8b 3d 30 f2 22 f0    	mov    0xf022f230,%edi
f0100692:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100697:	89 fa                	mov    %edi,%edx
f0100699:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f010069a:	8d 5f 01             	lea    0x1(%edi),%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010069d:	89 da                	mov    %ebx,%edx
f010069f:	ec                   	in     (%dx),%al
f01006a0:	0f b6 c8             	movzbl %al,%ecx
f01006a3:	c1 e1 08             	shl    $0x8,%ecx
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01006a6:	b8 0f 00 00 00       	mov    $0xf,%eax
f01006ab:	89 fa                	mov    %edi,%edx
f01006ad:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01006ae:	89 da                	mov    %ebx,%edx
f01006b0:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01006b1:	89 35 2c f2 22 f0    	mov    %esi,0xf022f22c
	crt_pos = pos;
f01006b7:	0f b6 c0             	movzbl %al,%eax
f01006ba:	09 c8                	or     %ecx,%eax
f01006bc:	66 a3 28 f2 22 f0    	mov    %ax,0xf022f228

static void
kbd_init(void)
{
	// Drain the kbd buffer so that QEMU generates interrupts.
	kbd_intr();
f01006c2:	e8 1c ff ff ff       	call   f01005e3 <kbd_intr>
	irq_setmask_8259A(irq_mask_8259A & ~(1<<IRQ_KBD));
f01006c7:	83 ec 0c             	sub    $0xc,%esp
f01006ca:	0f b7 05 a8 03 12 f0 	movzwl 0xf01203a8,%eax
f01006d1:	25 fd ff 00 00       	and    $0xfffd,%eax
f01006d6:	50                   	push   %eax
f01006d7:	e8 31 2e 00 00       	call   f010350d <irq_setmask_8259A>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01006dc:	be fa 03 00 00       	mov    $0x3fa,%esi
f01006e1:	b8 00 00 00 00       	mov    $0x0,%eax
f01006e6:	89 f2                	mov    %esi,%edx
f01006e8:	ee                   	out    %al,(%dx)
f01006e9:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01006ee:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01006f3:	ee                   	out    %al,(%dx)
f01006f4:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f01006f9:	b8 0c 00 00 00       	mov    $0xc,%eax
f01006fe:	89 da                	mov    %ebx,%edx
f0100700:	ee                   	out    %al,(%dx)
f0100701:	ba f9 03 00 00       	mov    $0x3f9,%edx
f0100706:	b8 00 00 00 00       	mov    $0x0,%eax
f010070b:	ee                   	out    %al,(%dx)
f010070c:	ba fb 03 00 00       	mov    $0x3fb,%edx
f0100711:	b8 03 00 00 00       	mov    $0x3,%eax
f0100716:	ee                   	out    %al,(%dx)
f0100717:	ba fc 03 00 00       	mov    $0x3fc,%edx
f010071c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100721:	ee                   	out    %al,(%dx)
f0100722:	ba f9 03 00 00       	mov    $0x3f9,%edx
f0100727:	b8 01 00 00 00       	mov    $0x1,%eax
f010072c:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010072d:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100732:	ec                   	in     (%dx),%al
f0100733:	89 c1                	mov    %eax,%ecx
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100735:	83 c4 10             	add    $0x10,%esp
f0100738:	3c ff                	cmp    $0xff,%al
f010073a:	0f 95 05 34 f2 22 f0 	setne  0xf022f234
f0100741:	89 f2                	mov    %esi,%edx
f0100743:	ec                   	in     (%dx),%al
f0100744:	89 da                	mov    %ebx,%edx
f0100746:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100747:	80 f9 ff             	cmp    $0xff,%cl
f010074a:	75 10                	jne    f010075c <cons_init+0x11d>
		cprintf("Serial port does not exist!\n");
f010074c:	83 ec 0c             	sub    $0xc,%esp
f010074f:	68 8f 61 10 f0       	push   $0xf010618f
f0100754:	e8 05 2f 00 00       	call   f010365e <cprintf>
f0100759:	83 c4 10             	add    $0x10,%esp
}
f010075c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010075f:	5b                   	pop    %ebx
f0100760:	5e                   	pop    %esi
f0100761:	5f                   	pop    %edi
f0100762:	5d                   	pop    %ebp
f0100763:	c3                   	ret    

f0100764 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100764:	55                   	push   %ebp
f0100765:	89 e5                	mov    %esp,%ebp
f0100767:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f010076a:	8b 45 08             	mov    0x8(%ebp),%eax
f010076d:	e8 6c fc ff ff       	call   f01003de <cons_putc>
}
f0100772:	c9                   	leave  
f0100773:	c3                   	ret    

f0100774 <getchar>:

int
getchar(void)
{
f0100774:	55                   	push   %ebp
f0100775:	89 e5                	mov    %esp,%ebp
f0100777:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f010077a:	e8 76 fe ff ff       	call   f01005f5 <cons_getc>
f010077f:	85 c0                	test   %eax,%eax
f0100781:	74 f7                	je     f010077a <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100783:	c9                   	leave  
f0100784:	c3                   	ret    

f0100785 <iscons>:

int
iscons(int fdnum)
{
f0100785:	55                   	push   %ebp
f0100786:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100788:	b8 01 00 00 00       	mov    $0x1,%eax
f010078d:	5d                   	pop    %ebp
f010078e:	c3                   	ret    

f010078f <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f010078f:	55                   	push   %ebp
f0100790:	89 e5                	mov    %esp,%ebp
f0100792:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100795:	68 e0 63 10 f0       	push   $0xf01063e0
f010079a:	68 fe 63 10 f0       	push   $0xf01063fe
f010079f:	68 03 64 10 f0       	push   $0xf0106403
f01007a4:	e8 b5 2e 00 00       	call   f010365e <cprintf>
f01007a9:	83 c4 0c             	add    $0xc,%esp
f01007ac:	68 8c 64 10 f0       	push   $0xf010648c
f01007b1:	68 0c 64 10 f0       	push   $0xf010640c
f01007b6:	68 03 64 10 f0       	push   $0xf0106403
f01007bb:	e8 9e 2e 00 00       	call   f010365e <cprintf>
	return 0;
}
f01007c0:	b8 00 00 00 00       	mov    $0x0,%eax
f01007c5:	c9                   	leave  
f01007c6:	c3                   	ret    

f01007c7 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01007c7:	55                   	push   %ebp
f01007c8:	89 e5                	mov    %esp,%ebp
f01007ca:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01007cd:	68 15 64 10 f0       	push   $0xf0106415
f01007d2:	e8 87 2e 00 00       	call   f010365e <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01007d7:	83 c4 08             	add    $0x8,%esp
f01007da:	68 0c 00 10 00       	push   $0x10000c
f01007df:	68 b4 64 10 f0       	push   $0xf01064b4
f01007e4:	e8 75 2e 00 00       	call   f010365e <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01007e9:	83 c4 0c             	add    $0xc,%esp
f01007ec:	68 0c 00 10 00       	push   $0x10000c
f01007f1:	68 0c 00 10 f0       	push   $0xf010000c
f01007f6:	68 dc 64 10 f0       	push   $0xf01064dc
f01007fb:	e8 5e 2e 00 00       	call   f010365e <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100800:	83 c4 0c             	add    $0xc,%esp
f0100803:	68 a1 60 10 00       	push   $0x1060a1
f0100808:	68 a1 60 10 f0       	push   $0xf01060a1
f010080d:	68 00 65 10 f0       	push   $0xf0106500
f0100812:	e8 47 2e 00 00       	call   f010365e <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f0100817:	83 c4 0c             	add    $0xc,%esp
f010081a:	68 10 e9 22 00       	push   $0x22e910
f010081f:	68 10 e9 22 f0       	push   $0xf022e910
f0100824:	68 24 65 10 f0       	push   $0xf0106524
f0100829:	e8 30 2e 00 00       	call   f010365e <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010082e:	83 c4 0c             	add    $0xc,%esp
f0100831:	68 08 10 27 00       	push   $0x271008
f0100836:	68 08 10 27 f0       	push   $0xf0271008
f010083b:	68 48 65 10 f0       	push   $0xf0106548
f0100840:	e8 19 2e 00 00       	call   f010365e <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f0100845:	b8 07 14 27 f0       	mov    $0xf0271407,%eax
f010084a:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f010084f:	83 c4 08             	add    $0x8,%esp
f0100852:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f0100857:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f010085d:	85 c0                	test   %eax,%eax
f010085f:	0f 48 c2             	cmovs  %edx,%eax
f0100862:	c1 f8 0a             	sar    $0xa,%eax
f0100865:	50                   	push   %eax
f0100866:	68 6c 65 10 f0       	push   $0xf010656c
f010086b:	e8 ee 2d 00 00       	call   f010365e <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100870:	b8 00 00 00 00       	mov    $0x0,%eax
f0100875:	c9                   	leave  
f0100876:	c3                   	ret    

f0100877 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100877:	55                   	push   %ebp
f0100878:	89 e5                	mov    %esp,%ebp
f010087a:	56                   	push   %esi
f010087b:	53                   	push   %ebx
f010087c:	83 ec 2c             	sub    $0x2c,%esp

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f010087f:	89 eb                	mov    %ebp,%ebx
	uintptr_t ebp = read_ebp();
	struct Eipdebuginfo info;
	cprintf("Stack backtrace:\n");
f0100881:	68 2e 64 10 f0       	push   $0xf010642e
f0100886:	e8 d3 2d 00 00       	call   f010365e <cprintf>
	while(ebp != 0){
f010088b:	83 c4 10             	add    $0x10,%esp
		cprintf("  ebp %08x  eip %08x  args %08x %08x %08x %08x %08x\n", ebp , 
				*((uintptr_t *)ebp + 1), *((uintptr_t *)ebp + 2), *((uintptr_t *)ebp + 3), 
			    *((uintptr_t *)ebp + 4), *((uintptr_t *)ebp + 5), *((uintptr_t *)ebp + 6));
		debuginfo_eip(*((uintptr_t *)ebp + 1), &info);
f010088e:	8d 75 e0             	lea    -0x20(%ebp),%esi
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	uintptr_t ebp = read_ebp();
	struct Eipdebuginfo info;
	cprintf("Stack backtrace:\n");
	while(ebp != 0){
f0100891:	eb 4e                	jmp    f01008e1 <mon_backtrace+0x6a>
		cprintf("  ebp %08x  eip %08x  args %08x %08x %08x %08x %08x\n", ebp , 
f0100893:	ff 73 18             	pushl  0x18(%ebx)
f0100896:	ff 73 14             	pushl  0x14(%ebx)
f0100899:	ff 73 10             	pushl  0x10(%ebx)
f010089c:	ff 73 0c             	pushl  0xc(%ebx)
f010089f:	ff 73 08             	pushl  0x8(%ebx)
f01008a2:	ff 73 04             	pushl  0x4(%ebx)
f01008a5:	53                   	push   %ebx
f01008a6:	68 98 65 10 f0       	push   $0xf0106598
f01008ab:	e8 ae 2d 00 00       	call   f010365e <cprintf>
				*((uintptr_t *)ebp + 1), *((uintptr_t *)ebp + 2), *((uintptr_t *)ebp + 3), 
			    *((uintptr_t *)ebp + 4), *((uintptr_t *)ebp + 5), *((uintptr_t *)ebp + 6));
		debuginfo_eip(*((uintptr_t *)ebp + 1), &info);
f01008b0:	83 c4 18             	add    $0x18,%esp
f01008b3:	56                   	push   %esi
f01008b4:	ff 73 04             	pushl  0x4(%ebx)
f01008b7:	e8 98 40 00 00       	call   f0104954 <debuginfo_eip>
		cprintf("%s:%d: %.*s+%d\n", info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, 
f01008bc:	83 c4 08             	add    $0x8,%esp
f01008bf:	8b 43 04             	mov    0x4(%ebx),%eax
f01008c2:	2b 45 f0             	sub    -0x10(%ebp),%eax
f01008c5:	50                   	push   %eax
f01008c6:	ff 75 e8             	pushl  -0x18(%ebp)
f01008c9:	ff 75 ec             	pushl  -0x14(%ebp)
f01008cc:	ff 75 e4             	pushl  -0x1c(%ebp)
f01008cf:	ff 75 e0             	pushl  -0x20(%ebp)
f01008d2:	68 40 64 10 f0       	push   $0xf0106440
f01008d7:	e8 82 2d 00 00       	call   f010365e <cprintf>
				*((uintptr_t *)ebp + 1) - info.eip_fn_addr);
		ebp = *(uintptr_t *)ebp;
f01008dc:	8b 1b                	mov    (%ebx),%ebx
f01008de:	83 c4 20             	add    $0x20,%esp
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	uintptr_t ebp = read_ebp();
	struct Eipdebuginfo info;
	cprintf("Stack backtrace:\n");
	while(ebp != 0){
f01008e1:	85 db                	test   %ebx,%ebx
f01008e3:	75 ae                	jne    f0100893 <mon_backtrace+0x1c>
		cprintf("%s:%d: %.*s+%d\n", info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, 
				*((uintptr_t *)ebp + 1) - info.eip_fn_addr);
		ebp = *(uintptr_t *)ebp;
	}
	return 0;
}
f01008e5:	b8 00 00 00 00       	mov    $0x0,%eax
f01008ea:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01008ed:	5b                   	pop    %ebx
f01008ee:	5e                   	pop    %esi
f01008ef:	5d                   	pop    %ebp
f01008f0:	c3                   	ret    

f01008f1 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01008f1:	55                   	push   %ebp
f01008f2:	89 e5                	mov    %esp,%ebp
f01008f4:	57                   	push   %edi
f01008f5:	56                   	push   %esi
f01008f6:	53                   	push   %ebx
f01008f7:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01008fa:	68 d0 65 10 f0       	push   $0xf01065d0
f01008ff:	e8 5a 2d 00 00       	call   f010365e <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100904:	c7 04 24 f4 65 10 f0 	movl   $0xf01065f4,(%esp)
f010090b:	e8 4e 2d 00 00       	call   f010365e <cprintf>

	if (tf != NULL)
f0100910:	83 c4 10             	add    $0x10,%esp
f0100913:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f0100917:	74 0e                	je     f0100927 <monitor+0x36>
		print_trapframe(tf);
f0100919:	83 ec 0c             	sub    $0xc,%esp
f010091c:	ff 75 08             	pushl  0x8(%ebp)
f010091f:	e8 e9 32 00 00       	call   f0103c0d <print_trapframe>
f0100924:	83 c4 10             	add    $0x10,%esp

	while (1) {
		buf = readline("K> ");
f0100927:	83 ec 0c             	sub    $0xc,%esp
f010092a:	68 50 64 10 f0       	push   $0xf0106450
f010092f:	e8 79 48 00 00       	call   f01051ad <readline>
f0100934:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100936:	83 c4 10             	add    $0x10,%esp
f0100939:	85 c0                	test   %eax,%eax
f010093b:	74 ea                	je     f0100927 <monitor+0x36>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f010093d:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100944:	be 00 00 00 00       	mov    $0x0,%esi
f0100949:	eb 0a                	jmp    f0100955 <monitor+0x64>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f010094b:	c6 03 00             	movb   $0x0,(%ebx)
f010094e:	89 f7                	mov    %esi,%edi
f0100950:	8d 5b 01             	lea    0x1(%ebx),%ebx
f0100953:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100955:	0f b6 03             	movzbl (%ebx),%eax
f0100958:	84 c0                	test   %al,%al
f010095a:	74 63                	je     f01009bf <monitor+0xce>
f010095c:	83 ec 08             	sub    $0x8,%esp
f010095f:	0f be c0             	movsbl %al,%eax
f0100962:	50                   	push   %eax
f0100963:	68 54 64 10 f0       	push   $0xf0106454
f0100968:	e8 5a 4a 00 00       	call   f01053c7 <strchr>
f010096d:	83 c4 10             	add    $0x10,%esp
f0100970:	85 c0                	test   %eax,%eax
f0100972:	75 d7                	jne    f010094b <monitor+0x5a>
			*buf++ = 0;
		if (*buf == 0)
f0100974:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100977:	74 46                	je     f01009bf <monitor+0xce>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100979:	83 fe 0f             	cmp    $0xf,%esi
f010097c:	75 14                	jne    f0100992 <monitor+0xa1>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f010097e:	83 ec 08             	sub    $0x8,%esp
f0100981:	6a 10                	push   $0x10
f0100983:	68 59 64 10 f0       	push   $0xf0106459
f0100988:	e8 d1 2c 00 00       	call   f010365e <cprintf>
f010098d:	83 c4 10             	add    $0x10,%esp
f0100990:	eb 95                	jmp    f0100927 <monitor+0x36>
			return 0;
		}
		argv[argc++] = buf;
f0100992:	8d 7e 01             	lea    0x1(%esi),%edi
f0100995:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100999:	eb 03                	jmp    f010099e <monitor+0xad>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f010099b:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f010099e:	0f b6 03             	movzbl (%ebx),%eax
f01009a1:	84 c0                	test   %al,%al
f01009a3:	74 ae                	je     f0100953 <monitor+0x62>
f01009a5:	83 ec 08             	sub    $0x8,%esp
f01009a8:	0f be c0             	movsbl %al,%eax
f01009ab:	50                   	push   %eax
f01009ac:	68 54 64 10 f0       	push   $0xf0106454
f01009b1:	e8 11 4a 00 00       	call   f01053c7 <strchr>
f01009b6:	83 c4 10             	add    $0x10,%esp
f01009b9:	85 c0                	test   %eax,%eax
f01009bb:	74 de                	je     f010099b <monitor+0xaa>
f01009bd:	eb 94                	jmp    f0100953 <monitor+0x62>
			buf++;
	}
	argv[argc] = 0;
f01009bf:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01009c6:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01009c7:	85 f6                	test   %esi,%esi
f01009c9:	0f 84 58 ff ff ff    	je     f0100927 <monitor+0x36>
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01009cf:	83 ec 08             	sub    $0x8,%esp
f01009d2:	68 fe 63 10 f0       	push   $0xf01063fe
f01009d7:	ff 75 a8             	pushl  -0x58(%ebp)
f01009da:	e8 8a 49 00 00       	call   f0105369 <strcmp>
f01009df:	83 c4 10             	add    $0x10,%esp
f01009e2:	85 c0                	test   %eax,%eax
f01009e4:	74 1e                	je     f0100a04 <monitor+0x113>
f01009e6:	83 ec 08             	sub    $0x8,%esp
f01009e9:	68 0c 64 10 f0       	push   $0xf010640c
f01009ee:	ff 75 a8             	pushl  -0x58(%ebp)
f01009f1:	e8 73 49 00 00       	call   f0105369 <strcmp>
f01009f6:	83 c4 10             	add    $0x10,%esp
f01009f9:	85 c0                	test   %eax,%eax
f01009fb:	75 2f                	jne    f0100a2c <monitor+0x13b>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f01009fd:	b8 01 00 00 00       	mov    $0x1,%eax
f0100a02:	eb 05                	jmp    f0100a09 <monitor+0x118>
		if (strcmp(argv[0], commands[i].name) == 0)
f0100a04:	b8 00 00 00 00       	mov    $0x0,%eax
			return commands[i].func(argc, argv, tf);
f0100a09:	83 ec 04             	sub    $0x4,%esp
f0100a0c:	8d 14 00             	lea    (%eax,%eax,1),%edx
f0100a0f:	01 d0                	add    %edx,%eax
f0100a11:	ff 75 08             	pushl  0x8(%ebp)
f0100a14:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f0100a17:	51                   	push   %ecx
f0100a18:	56                   	push   %esi
f0100a19:	ff 14 85 24 66 10 f0 	call   *-0xfef99dc(,%eax,4)
		print_trapframe(tf);

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100a20:	83 c4 10             	add    $0x10,%esp
f0100a23:	85 c0                	test   %eax,%eax
f0100a25:	78 1d                	js     f0100a44 <monitor+0x153>
f0100a27:	e9 fb fe ff ff       	jmp    f0100927 <monitor+0x36>
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100a2c:	83 ec 08             	sub    $0x8,%esp
f0100a2f:	ff 75 a8             	pushl  -0x58(%ebp)
f0100a32:	68 76 64 10 f0       	push   $0xf0106476
f0100a37:	e8 22 2c 00 00       	call   f010365e <cprintf>
f0100a3c:	83 c4 10             	add    $0x10,%esp
f0100a3f:	e9 e3 fe ff ff       	jmp    f0100927 <monitor+0x36>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100a44:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100a47:	5b                   	pop    %ebx
f0100a48:	5e                   	pop    %esi
f0100a49:	5f                   	pop    %edi
f0100a4a:	5d                   	pop    %ebp
f0100a4b:	c3                   	ret    

f0100a4c <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f0100a4c:	55                   	push   %ebp
f0100a4d:	89 e5                	mov    %esp,%ebp
f0100a4f:	56                   	push   %esi
f0100a50:	53                   	push   %ebx
f0100a51:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100a53:	83 ec 0c             	sub    $0xc,%esp
f0100a56:	50                   	push   %eax
f0100a57:	e8 83 2a 00 00       	call   f01034df <mc146818_read>
f0100a5c:	89 c6                	mov    %eax,%esi
f0100a5e:	83 c3 01             	add    $0x1,%ebx
f0100a61:	89 1c 24             	mov    %ebx,(%esp)
f0100a64:	e8 76 2a 00 00       	call   f01034df <mc146818_read>
f0100a69:	c1 e0 08             	shl    $0x8,%eax
f0100a6c:	09 f0                	or     %esi,%eax
}
f0100a6e:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100a71:	5b                   	pop    %ebx
f0100a72:	5e                   	pop    %esi
f0100a73:	5d                   	pop    %ebp
f0100a74:	c3                   	ret    

f0100a75 <check_va2pa>:
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f0100a75:	89 d1                	mov    %edx,%ecx
f0100a77:	c1 e9 16             	shr    $0x16,%ecx
f0100a7a:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0100a7d:	a8 01                	test   $0x1,%al
f0100a7f:	74 52                	je     f0100ad3 <check_va2pa+0x5e>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100a81:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100a86:	89 c1                	mov    %eax,%ecx
f0100a88:	c1 e9 0c             	shr    $0xc,%ecx
f0100a8b:	3b 0d 88 fe 22 f0    	cmp    0xf022fe88,%ecx
f0100a91:	72 1b                	jb     f0100aae <check_va2pa+0x39>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100a93:	55                   	push   %ebp
f0100a94:	89 e5                	mov    %esp,%ebp
f0100a96:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100a99:	50                   	push   %eax
f0100a9a:	68 e4 60 10 f0       	push   $0xf01060e4
f0100a9f:	68 85 03 00 00       	push   $0x385
f0100aa4:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0100aa9:	e8 92 f5 ff ff       	call   f0100040 <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f0100aae:	c1 ea 0c             	shr    $0xc,%edx
f0100ab1:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100ab7:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100abe:	89 c2                	mov    %eax,%edx
f0100ac0:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100ac3:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100ac8:	85 d2                	test   %edx,%edx
f0100aca:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100acf:	0f 44 c2             	cmove  %edx,%eax
f0100ad2:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f0100ad3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f0100ad8:	c3                   	ret    

f0100ad9 <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100ad9:	89 c2                	mov    %eax,%edx
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100adb:	83 3d 38 f2 22 f0 00 	cmpl   $0x0,0xf022f238
f0100ae2:	75 0f                	jne    f0100af3 <boot_alloc+0x1a>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100ae4:	b8 07 20 27 f0       	mov    $0xf0272007,%eax
f0100ae9:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100aee:	a3 38 f2 22 f0       	mov    %eax,0xf022f238
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	result = nextfree;
f0100af3:	a1 38 f2 22 f0       	mov    0xf022f238,%eax
	if(n > 0){
f0100af8:	85 d2                	test   %edx,%edx
f0100afa:	74 62                	je     f0100b5e <boot_alloc+0x85>
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100afc:	55                   	push   %ebp
f0100afd:	89 e5                	mov    %esp,%ebp
f0100aff:	53                   	push   %ebx
f0100b00:	83 ec 04             	sub    $0x4,%esp
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100b03:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100b08:	77 12                	ja     f0100b1c <boot_alloc+0x43>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100b0a:	50                   	push   %eax
f0100b0b:	68 08 61 10 f0       	push   $0xf0106108
f0100b10:	6a 6e                	push   $0x6e
f0100b12:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0100b17:	e8 24 f5 ff ff       	call   f0100040 <_panic>
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	result = nextfree;
	if(n > 0){
		if (PADDR(nextfree) + n > (npages + 1) * PGSIZE) {
f0100b1c:	8d 9c 10 00 00 00 10 	lea    0x10000000(%eax,%edx,1),%ebx
f0100b23:	8b 0d 88 fe 22 f0    	mov    0xf022fe88,%ecx
f0100b29:	83 c1 01             	add    $0x1,%ecx
f0100b2c:	c1 e1 0c             	shl    $0xc,%ecx
f0100b2f:	39 cb                	cmp    %ecx,%ebx
f0100b31:	76 14                	jbe    f0100b47 <boot_alloc+0x6e>
			panic("out of memory\n");
f0100b33:	83 ec 04             	sub    $0x4,%esp
f0100b36:	68 c1 6f 10 f0       	push   $0xf0106fc1
f0100b3b:	6a 6f                	push   $0x6f
f0100b3d:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0100b42:	e8 f9 f4 ff ff       	call   f0100040 <_panic>
		}
		nextfree = ROUNDUP((char *)nextfree + n, PGSIZE);
f0100b47:	8d 94 10 ff 0f 00 00 	lea    0xfff(%eax,%edx,1),%edx
f0100b4e:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100b54:	89 15 38 f2 22 f0    	mov    %edx,0xf022f238
	}
	return result;
}
f0100b5a:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100b5d:	c9                   	leave  
f0100b5e:	f3 c3                	repz ret 

f0100b60 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100b60:	55                   	push   %ebp
f0100b61:	89 e5                	mov    %esp,%ebp
f0100b63:	57                   	push   %edi
f0100b64:	56                   	push   %esi
f0100b65:	53                   	push   %ebx
f0100b66:	83 ec 2c             	sub    $0x2c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100b69:	84 c0                	test   %al,%al
f0100b6b:	0f 85 a0 02 00 00    	jne    f0100e11 <check_page_free_list+0x2b1>
f0100b71:	e9 ad 02 00 00       	jmp    f0100e23 <check_page_free_list+0x2c3>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f0100b76:	83 ec 04             	sub    $0x4,%esp
f0100b79:	68 34 66 10 f0       	push   $0xf0106634
f0100b7e:	68 b8 02 00 00       	push   $0x2b8
f0100b83:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0100b88:	e8 b3 f4 ff ff       	call   f0100040 <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100b8d:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100b90:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100b93:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100b96:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100b99:	89 c2                	mov    %eax,%edx
f0100b9b:	2b 15 90 fe 22 f0    	sub    0xf022fe90,%edx
f0100ba1:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100ba7:	0f 95 c2             	setne  %dl
f0100baa:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100bad:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100bb1:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100bb3:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100bb7:	8b 00                	mov    (%eax),%eax
f0100bb9:	85 c0                	test   %eax,%eax
f0100bbb:	75 dc                	jne    f0100b99 <check_page_free_list+0x39>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100bbd:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100bc0:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100bc6:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100bc9:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100bcc:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100bce:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100bd1:	a3 40 f2 22 f0       	mov    %eax,0xf022f240
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100bd6:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100bdb:	8b 1d 40 f2 22 f0    	mov    0xf022f240,%ebx
f0100be1:	eb 53                	jmp    f0100c36 <check_page_free_list+0xd6>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100be3:	89 d8                	mov    %ebx,%eax
f0100be5:	2b 05 90 fe 22 f0    	sub    0xf022fe90,%eax
f0100beb:	c1 f8 03             	sar    $0x3,%eax
f0100bee:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100bf1:	89 c2                	mov    %eax,%edx
f0100bf3:	c1 ea 16             	shr    $0x16,%edx
f0100bf6:	39 f2                	cmp    %esi,%edx
f0100bf8:	73 3a                	jae    f0100c34 <check_page_free_list+0xd4>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100bfa:	89 c2                	mov    %eax,%edx
f0100bfc:	c1 ea 0c             	shr    $0xc,%edx
f0100bff:	3b 15 88 fe 22 f0    	cmp    0xf022fe88,%edx
f0100c05:	72 12                	jb     f0100c19 <check_page_free_list+0xb9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100c07:	50                   	push   %eax
f0100c08:	68 e4 60 10 f0       	push   $0xf01060e4
f0100c0d:	6a 58                	push   $0x58
f0100c0f:	68 d0 6f 10 f0       	push   $0xf0106fd0
f0100c14:	e8 27 f4 ff ff       	call   f0100040 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100c19:	83 ec 04             	sub    $0x4,%esp
f0100c1c:	68 80 00 00 00       	push   $0x80
f0100c21:	68 97 00 00 00       	push   $0x97
f0100c26:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100c2b:	50                   	push   %eax
f0100c2c:	e8 d3 47 00 00       	call   f0105404 <memset>
f0100c31:	83 c4 10             	add    $0x10,%esp
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100c34:	8b 1b                	mov    (%ebx),%ebx
f0100c36:	85 db                	test   %ebx,%ebx
f0100c38:	75 a9                	jne    f0100be3 <check_page_free_list+0x83>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100c3a:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c3f:	e8 95 fe ff ff       	call   f0100ad9 <boot_alloc>
f0100c44:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c47:	8b 15 40 f2 22 f0    	mov    0xf022f240,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100c4d:	8b 0d 90 fe 22 f0    	mov    0xf022fe90,%ecx
		assert(pp < pages + npages);
f0100c53:	a1 88 fe 22 f0       	mov    0xf022fe88,%eax
f0100c58:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0100c5b:	8d 04 c1             	lea    (%ecx,%eax,8),%eax
f0100c5e:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100c61:	89 4d d0             	mov    %ecx,-0x30(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100c64:	be 00 00 00 00       	mov    $0x0,%esi
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c69:	e9 52 01 00 00       	jmp    f0100dc0 <check_page_free_list+0x260>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100c6e:	39 ca                	cmp    %ecx,%edx
f0100c70:	73 19                	jae    f0100c8b <check_page_free_list+0x12b>
f0100c72:	68 de 6f 10 f0       	push   $0xf0106fde
f0100c77:	68 ea 6f 10 f0       	push   $0xf0106fea
f0100c7c:	68 d2 02 00 00       	push   $0x2d2
f0100c81:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0100c86:	e8 b5 f3 ff ff       	call   f0100040 <_panic>
		assert(pp < pages + npages);
f0100c8b:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100c8e:	72 19                	jb     f0100ca9 <check_page_free_list+0x149>
f0100c90:	68 ff 6f 10 f0       	push   $0xf0106fff
f0100c95:	68 ea 6f 10 f0       	push   $0xf0106fea
f0100c9a:	68 d3 02 00 00       	push   $0x2d3
f0100c9f:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0100ca4:	e8 97 f3 ff ff       	call   f0100040 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100ca9:	89 d0                	mov    %edx,%eax
f0100cab:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0100cae:	a8 07                	test   $0x7,%al
f0100cb0:	74 19                	je     f0100ccb <check_page_free_list+0x16b>
f0100cb2:	68 58 66 10 f0       	push   $0xf0106658
f0100cb7:	68 ea 6f 10 f0       	push   $0xf0106fea
f0100cbc:	68 d4 02 00 00       	push   $0x2d4
f0100cc1:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0100cc6:	e8 75 f3 ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100ccb:	c1 f8 03             	sar    $0x3,%eax
f0100cce:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100cd1:	85 c0                	test   %eax,%eax
f0100cd3:	75 19                	jne    f0100cee <check_page_free_list+0x18e>
f0100cd5:	68 13 70 10 f0       	push   $0xf0107013
f0100cda:	68 ea 6f 10 f0       	push   $0xf0106fea
f0100cdf:	68 d7 02 00 00       	push   $0x2d7
f0100ce4:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0100ce9:	e8 52 f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100cee:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100cf3:	75 19                	jne    f0100d0e <check_page_free_list+0x1ae>
f0100cf5:	68 24 70 10 f0       	push   $0xf0107024
f0100cfa:	68 ea 6f 10 f0       	push   $0xf0106fea
f0100cff:	68 d8 02 00 00       	push   $0x2d8
f0100d04:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0100d09:	e8 32 f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100d0e:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100d13:	75 19                	jne    f0100d2e <check_page_free_list+0x1ce>
f0100d15:	68 8c 66 10 f0       	push   $0xf010668c
f0100d1a:	68 ea 6f 10 f0       	push   $0xf0106fea
f0100d1f:	68 d9 02 00 00       	push   $0x2d9
f0100d24:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0100d29:	e8 12 f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100d2e:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100d33:	75 19                	jne    f0100d4e <check_page_free_list+0x1ee>
f0100d35:	68 3d 70 10 f0       	push   $0xf010703d
f0100d3a:	68 ea 6f 10 f0       	push   $0xf0106fea
f0100d3f:	68 da 02 00 00       	push   $0x2da
f0100d44:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0100d49:	e8 f2 f2 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100d4e:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100d53:	0f 86 f1 00 00 00    	jbe    f0100e4a <check_page_free_list+0x2ea>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100d59:	89 c7                	mov    %eax,%edi
f0100d5b:	c1 ef 0c             	shr    $0xc,%edi
f0100d5e:	39 7d c8             	cmp    %edi,-0x38(%ebp)
f0100d61:	77 12                	ja     f0100d75 <check_page_free_list+0x215>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100d63:	50                   	push   %eax
f0100d64:	68 e4 60 10 f0       	push   $0xf01060e4
f0100d69:	6a 58                	push   $0x58
f0100d6b:	68 d0 6f 10 f0       	push   $0xf0106fd0
f0100d70:	e8 cb f2 ff ff       	call   f0100040 <_panic>
f0100d75:	8d b8 00 00 00 f0    	lea    -0x10000000(%eax),%edi
f0100d7b:	39 7d cc             	cmp    %edi,-0x34(%ebp)
f0100d7e:	0f 86 b6 00 00 00    	jbe    f0100e3a <check_page_free_list+0x2da>
f0100d84:	68 b0 66 10 f0       	push   $0xf01066b0
f0100d89:	68 ea 6f 10 f0       	push   $0xf0106fea
f0100d8e:	68 db 02 00 00       	push   $0x2db
f0100d93:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0100d98:	e8 a3 f2 ff ff       	call   f0100040 <_panic>
		// (new test for lab 4)
		assert(page2pa(pp) != MPENTRY_PADDR);
f0100d9d:	68 57 70 10 f0       	push   $0xf0107057
f0100da2:	68 ea 6f 10 f0       	push   $0xf0106fea
f0100da7:	68 dd 02 00 00       	push   $0x2dd
f0100dac:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0100db1:	e8 8a f2 ff ff       	call   f0100040 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100db6:	83 c6 01             	add    $0x1,%esi
f0100db9:	eb 03                	jmp    f0100dbe <check_page_free_list+0x25e>
		else
			++nfree_extmem;
f0100dbb:	83 c3 01             	add    $0x1,%ebx
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100dbe:	8b 12                	mov    (%edx),%edx
f0100dc0:	85 d2                	test   %edx,%edx
f0100dc2:	0f 85 a6 fe ff ff    	jne    f0100c6e <check_page_free_list+0x10e>
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100dc8:	85 f6                	test   %esi,%esi
f0100dca:	7f 19                	jg     f0100de5 <check_page_free_list+0x285>
f0100dcc:	68 74 70 10 f0       	push   $0xf0107074
f0100dd1:	68 ea 6f 10 f0       	push   $0xf0106fea
f0100dd6:	68 e5 02 00 00       	push   $0x2e5
f0100ddb:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0100de0:	e8 5b f2 ff ff       	call   f0100040 <_panic>
	assert(nfree_extmem > 0);
f0100de5:	85 db                	test   %ebx,%ebx
f0100de7:	7f 19                	jg     f0100e02 <check_page_free_list+0x2a2>
f0100de9:	68 86 70 10 f0       	push   $0xf0107086
f0100dee:	68 ea 6f 10 f0       	push   $0xf0106fea
f0100df3:	68 e6 02 00 00       	push   $0x2e6
f0100df8:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0100dfd:	e8 3e f2 ff ff       	call   f0100040 <_panic>

	cprintf("check_page_free_list() succeeded!\n");
f0100e02:	83 ec 0c             	sub    $0xc,%esp
f0100e05:	68 f8 66 10 f0       	push   $0xf01066f8
f0100e0a:	e8 4f 28 00 00       	call   f010365e <cprintf>
}
f0100e0f:	eb 49                	jmp    f0100e5a <check_page_free_list+0x2fa>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100e11:	a1 40 f2 22 f0       	mov    0xf022f240,%eax
f0100e16:	85 c0                	test   %eax,%eax
f0100e18:	0f 85 6f fd ff ff    	jne    f0100b8d <check_page_free_list+0x2d>
f0100e1e:	e9 53 fd ff ff       	jmp    f0100b76 <check_page_free_list+0x16>
f0100e23:	83 3d 40 f2 22 f0 00 	cmpl   $0x0,0xf022f240
f0100e2a:	0f 84 46 fd ff ff    	je     f0100b76 <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100e30:	be 00 04 00 00       	mov    $0x400,%esi
f0100e35:	e9 a1 fd ff ff       	jmp    f0100bdb <check_page_free_list+0x7b>
		assert(page2pa(pp) != IOPHYSMEM);
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
		assert(page2pa(pp) != EXTPHYSMEM);
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
		// (new test for lab 4)
		assert(page2pa(pp) != MPENTRY_PADDR);
f0100e3a:	3d 00 70 00 00       	cmp    $0x7000,%eax
f0100e3f:	0f 85 76 ff ff ff    	jne    f0100dbb <check_page_free_list+0x25b>
f0100e45:	e9 53 ff ff ff       	jmp    f0100d9d <check_page_free_list+0x23d>
f0100e4a:	3d 00 70 00 00       	cmp    $0x7000,%eax
f0100e4f:	0f 85 61 ff ff ff    	jne    f0100db6 <check_page_free_list+0x256>
f0100e55:	e9 43 ff ff ff       	jmp    f0100d9d <check_page_free_list+0x23d>

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);

	cprintf("check_page_free_list() succeeded!\n");
}
f0100e5a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100e5d:	5b                   	pop    %ebx
f0100e5e:	5e                   	pop    %esi
f0100e5f:	5f                   	pop    %edi
f0100e60:	5d                   	pop    %ebp
f0100e61:	c3                   	ret    

f0100e62 <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100e62:	55                   	push   %ebp
f0100e63:	89 e5                	mov    %esp,%ebp
f0100e65:	53                   	push   %ebx
f0100e66:	83 ec 04             	sub    $0x4,%esp
f0100e69:	8b 1d 40 f2 22 f0    	mov    0xf022f240,%ebx
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	
	size_t i, io_page_i, ext_page_i, free_top, mpentry_i;
	for (i = 0; i < npages; i++) {
f0100e6f:	ba 00 00 00 00       	mov    $0x0,%edx
f0100e74:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e79:	eb 27                	jmp    f0100ea2 <page_init+0x40>
f0100e7b:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
		pages[i].pp_ref = 0;
f0100e82:	89 d1                	mov    %edx,%ecx
f0100e84:	03 0d 90 fe 22 f0    	add    0xf022fe90,%ecx
f0100e8a:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = page_free_list;
f0100e90:	89 19                	mov    %ebx,(%ecx)
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	
	size_t i, io_page_i, ext_page_i, free_top, mpentry_i;
	for (i = 0; i < npages; i++) {
f0100e92:	83 c0 01             	add    $0x1,%eax
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
f0100e95:	89 d3                	mov    %edx,%ebx
f0100e97:	03 1d 90 fe 22 f0    	add    0xf022fe90,%ebx
f0100e9d:	ba 01 00 00 00       	mov    $0x1,%edx
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	
	size_t i, io_page_i, ext_page_i, free_top, mpentry_i;
	for (i = 0; i < npages; i++) {
f0100ea2:	3b 05 88 fe 22 f0    	cmp    0xf022fe88,%eax
f0100ea8:	72 d1                	jb     f0100e7b <page_init+0x19>
f0100eaa:	84 d2                	test   %dl,%dl
f0100eac:	74 06                	je     f0100eb4 <page_init+0x52>
f0100eae:	89 1d 40 f2 22 f0    	mov    %ebx,0xf022f240
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
  
	pages[0].pp_link = NULL;
f0100eb4:	a1 90 fe 22 f0       	mov    0xf022fe90,%eax
f0100eb9:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pages[1].pp_link = NULL;
f0100ebf:	a1 90 fe 22 f0       	mov    0xf022fe90,%eax
f0100ec4:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)

	io_page_i = PGNUM(IOPHYSMEM);
	ext_page_i = PGNUM(EXTPHYSMEM);
	free_top = PGNUM(PADDR(boot_alloc(0)));
f0100ecb:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ed0:	e8 04 fc ff ff       	call   f0100ad9 <boot_alloc>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100ed5:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100eda:	77 15                	ja     f0100ef1 <page_init+0x8f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100edc:	50                   	push   %eax
f0100edd:	68 08 61 10 f0       	push   $0xf0106108
f0100ee2:	68 4c 01 00 00       	push   $0x14c
f0100ee7:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0100eec:	e8 4f f1 ff ff       	call   f0100040 <_panic>
f0100ef1:	8d 88 00 00 00 10    	lea    0x10000000(%eax),%ecx
f0100ef7:	c1 e9 0c             	shr    $0xc,%ecx

	pages[ext_page_i].pp_link = pages[io_page_i].pp_link;
f0100efa:	a1 90 fe 22 f0       	mov    0xf022fe90,%eax
f0100eff:	8b 90 00 05 00 00    	mov    0x500(%eax),%edx
f0100f05:	89 90 00 08 00 00    	mov    %edx,0x800(%eax)
f0100f0b:	b8 00 05 00 00       	mov    $0x500,%eax
	for(i = io_page_i;i < ext_page_i;i++)
		pages[i].pp_link = NULL;
f0100f10:	8b 15 90 fe 22 f0    	mov    0xf022fe90,%edx
f0100f16:	c7 04 02 00 00 00 00 	movl   $0x0,(%edx,%eax,1)
f0100f1d:	83 c0 08             	add    $0x8,%eax
	io_page_i = PGNUM(IOPHYSMEM);
	ext_page_i = PGNUM(EXTPHYSMEM);
	free_top = PGNUM(PADDR(boot_alloc(0)));

	pages[ext_page_i].pp_link = pages[io_page_i].pp_link;
	for(i = io_page_i;i < ext_page_i;i++)
f0100f20:	3d 00 08 00 00       	cmp    $0x800,%eax
f0100f25:	75 e9                	jne    f0100f10 <page_init+0xae>
		pages[i].pp_link = NULL;

	pages[free_top].pp_link = pages[ext_page_i].pp_link;
f0100f27:	a1 90 fe 22 f0       	mov    0xf022fe90,%eax
f0100f2c:	8b 90 00 08 00 00    	mov    0x800(%eax),%edx
f0100f32:	89 14 c8             	mov    %edx,(%eax,%ecx,8)
	for (i = ext_page_i; i < free_top; i++)
f0100f35:	b8 00 01 00 00       	mov    $0x100,%eax
f0100f3a:	eb 10                	jmp    f0100f4c <page_init+0xea>
		pages[i].pp_link = NULL;
f0100f3c:	8b 15 90 fe 22 f0    	mov    0xf022fe90,%edx
f0100f42:	c7 04 c2 00 00 00 00 	movl   $0x0,(%edx,%eax,8)
	pages[ext_page_i].pp_link = pages[io_page_i].pp_link;
	for(i = io_page_i;i < ext_page_i;i++)
		pages[i].pp_link = NULL;

	pages[free_top].pp_link = pages[ext_page_i].pp_link;
	for (i = ext_page_i; i < free_top; i++)
f0100f49:	83 c0 01             	add    $0x1,%eax
f0100f4c:	39 c8                	cmp    %ecx,%eax
f0100f4e:	72 ec                	jb     f0100f3c <page_init+0xda>
		pages[i].pp_link = NULL;
        
    mpentry_i = PGNUM(MPENTRY_PADDR);
    pages[mpentry_i + 1].pp_link = pages[mpentry_i].pp_link;
f0100f50:	a1 90 fe 22 f0       	mov    0xf022fe90,%eax
f0100f55:	8b 50 38             	mov    0x38(%eax),%edx
f0100f58:	89 50 40             	mov    %edx,0x40(%eax)
    pages[mpentry_i].pp_link = NULL;
f0100f5b:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)
}
f0100f62:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100f65:	c9                   	leave  
f0100f66:	c3                   	ret    

f0100f67 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100f67:	55                   	push   %ebp
f0100f68:	89 e5                	mov    %esp,%ebp
f0100f6a:	53                   	push   %ebx
f0100f6b:	83 ec 04             	sub    $0x4,%esp
	//Fill this function in
	struct PageInfo *p = page_free_list;
f0100f6e:	8b 1d 40 f2 22 f0    	mov    0xf022f240,%ebx
	if(p){
f0100f74:	85 db                	test   %ebx,%ebx
f0100f76:	74 5c                	je     f0100fd4 <page_alloc+0x6d>
		page_free_list = p->pp_link;
f0100f78:	8b 03                	mov    (%ebx),%eax
f0100f7a:	a3 40 f2 22 f0       	mov    %eax,0xf022f240
		p->pp_link = NULL;
f0100f7f:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
		if(alloc_flags & ALLOC_ZERO){
			memset(page2kva(p), 0, PGSIZE);
		}
	}
	else return NULL;
	return p;
f0100f85:	89 d8                	mov    %ebx,%eax
	//Fill this function in
	struct PageInfo *p = page_free_list;
	if(p){
		page_free_list = p->pp_link;
		p->pp_link = NULL;
		if(alloc_flags & ALLOC_ZERO){
f0100f87:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100f8b:	74 4c                	je     f0100fd9 <page_alloc+0x72>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100f8d:	2b 05 90 fe 22 f0    	sub    0xf022fe90,%eax
f0100f93:	c1 f8 03             	sar    $0x3,%eax
f0100f96:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100f99:	89 c2                	mov    %eax,%edx
f0100f9b:	c1 ea 0c             	shr    $0xc,%edx
f0100f9e:	3b 15 88 fe 22 f0    	cmp    0xf022fe88,%edx
f0100fa4:	72 12                	jb     f0100fb8 <page_alloc+0x51>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100fa6:	50                   	push   %eax
f0100fa7:	68 e4 60 10 f0       	push   $0xf01060e4
f0100fac:	6a 58                	push   $0x58
f0100fae:	68 d0 6f 10 f0       	push   $0xf0106fd0
f0100fb3:	e8 88 f0 ff ff       	call   f0100040 <_panic>
			memset(page2kva(p), 0, PGSIZE);
f0100fb8:	83 ec 04             	sub    $0x4,%esp
f0100fbb:	68 00 10 00 00       	push   $0x1000
f0100fc0:	6a 00                	push   $0x0
f0100fc2:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100fc7:	50                   	push   %eax
f0100fc8:	e8 37 44 00 00       	call   f0105404 <memset>
f0100fcd:	83 c4 10             	add    $0x10,%esp
		}
	}
	else return NULL;
	return p;
f0100fd0:	89 d8                	mov    %ebx,%eax
f0100fd2:	eb 05                	jmp    f0100fd9 <page_alloc+0x72>
		p->pp_link = NULL;
		if(alloc_flags & ALLOC_ZERO){
			memset(page2kva(p), 0, PGSIZE);
		}
	}
	else return NULL;
f0100fd4:	b8 00 00 00 00       	mov    $0x0,%eax
	return p;
}
f0100fd9:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100fdc:	c9                   	leave  
f0100fdd:	c3                   	ret    

f0100fde <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100fde:	55                   	push   %ebp
f0100fdf:	89 e5                	mov    %esp,%ebp
f0100fe1:	83 ec 08             	sub    $0x8,%esp
f0100fe4:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
	if(pp->pp_ref != 0 || pp->pp_link!=NULL){
f0100fe7:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100fec:	75 05                	jne    f0100ff3 <page_free+0x15>
f0100fee:	83 38 00             	cmpl   $0x0,(%eax)
f0100ff1:	74 17                	je     f010100a <page_free+0x2c>
		panic("pp->pp_ref is nonzero or pp->pp_link is not NULL\n");
f0100ff3:	83 ec 04             	sub    $0x4,%esp
f0100ff6:	68 1c 67 10 f0       	push   $0xf010671c
f0100ffb:	68 82 01 00 00       	push   $0x182
f0101000:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0101005:	e8 36 f0 ff ff       	call   f0100040 <_panic>
	}
	pp->pp_link = page_free_list;
f010100a:	8b 15 40 f2 22 f0    	mov    0xf022f240,%edx
f0101010:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f0101012:	a3 40 f2 22 f0       	mov    %eax,0xf022f240


}
f0101017:	c9                   	leave  
f0101018:	c3                   	ret    

f0101019 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0101019:	55                   	push   %ebp
f010101a:	89 e5                	mov    %esp,%ebp
f010101c:	83 ec 08             	sub    $0x8,%esp
f010101f:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0101022:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0101026:	83 e8 01             	sub    $0x1,%eax
f0101029:	66 89 42 04          	mov    %ax,0x4(%edx)
f010102d:	66 85 c0             	test   %ax,%ax
f0101030:	75 0c                	jne    f010103e <page_decref+0x25>
		page_free(pp);
f0101032:	83 ec 0c             	sub    $0xc,%esp
f0101035:	52                   	push   %edx
f0101036:	e8 a3 ff ff ff       	call   f0100fde <page_free>
f010103b:	83 c4 10             	add    $0x10,%esp
}
f010103e:	c9                   	leave  
f010103f:	c3                   	ret    

f0101040 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0101040:	55                   	push   %ebp
f0101041:	89 e5                	mov    %esp,%ebp
f0101043:	56                   	push   %esi
f0101044:	53                   	push   %ebx
f0101045:	8b 75 0c             	mov    0xc(%ebp),%esi
	int pdr_i = PDX(va);
	pde_t *pde = &pgdir[pdr_i];
f0101048:	89 f3                	mov    %esi,%ebx
f010104a:	c1 eb 16             	shr    $0x16,%ebx
f010104d:	c1 e3 02             	shl    $0x2,%ebx
f0101050:	03 5d 08             	add    0x8(%ebp),%ebx
	pte_t *pgt;
	if(!(*pde & PTE_P)){
f0101053:	f6 03 01             	testb  $0x1,(%ebx)
f0101056:	75 2f                	jne    f0101087 <pgdir_walk+0x47>
		if(!create)	
f0101058:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f010105c:	74 64                	je     f01010c2 <pgdir_walk+0x82>
			return NULL;
		struct PageInfo *page = page_alloc(ALLOC_ZERO);
f010105e:	83 ec 0c             	sub    $0xc,%esp
f0101061:	6a 01                	push   $0x1
f0101063:	e8 ff fe ff ff       	call   f0100f67 <page_alloc>
		if(page == NULL) return NULL;
f0101068:	83 c4 10             	add    $0x10,%esp
f010106b:	85 c0                	test   %eax,%eax
f010106d:	74 5a                	je     f01010c9 <pgdir_walk+0x89>
		*pde = page2pa(page) | PTE_P | PTE_U | PTE_W;
f010106f:	89 c2                	mov    %eax,%edx
f0101071:	2b 15 90 fe 22 f0    	sub    0xf022fe90,%edx
f0101077:	c1 fa 03             	sar    $0x3,%edx
f010107a:	c1 e2 0c             	shl    $0xc,%edx
f010107d:	83 ca 07             	or     $0x7,%edx
f0101080:	89 13                	mov    %edx,(%ebx)
		page->pp_ref ++;
f0101082:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
	}
	pgt = KADDR(PTE_ADDR(*pde));
f0101087:	8b 03                	mov    (%ebx),%eax
f0101089:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010108e:	89 c2                	mov    %eax,%edx
f0101090:	c1 ea 0c             	shr    $0xc,%edx
f0101093:	3b 15 88 fe 22 f0    	cmp    0xf022fe88,%edx
f0101099:	72 15                	jb     f01010b0 <pgdir_walk+0x70>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010109b:	50                   	push   %eax
f010109c:	68 e4 60 10 f0       	push   $0xf01060e4
f01010a1:	68 b9 01 00 00       	push   $0x1b9
f01010a6:	68 b5 6f 10 f0       	push   $0xf0106fb5
f01010ab:	e8 90 ef ff ff       	call   f0100040 <_panic>
	
	return &pgt[PTX(va)];
f01010b0:	c1 ee 0a             	shr    $0xa,%esi
f01010b3:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f01010b9:	8d 84 30 00 00 00 f0 	lea    -0x10000000(%eax,%esi,1),%eax
f01010c0:	eb 0c                	jmp    f01010ce <pgdir_walk+0x8e>
	int pdr_i = PDX(va);
	pde_t *pde = &pgdir[pdr_i];
	pte_t *pgt;
	if(!(*pde & PTE_P)){
		if(!create)	
			return NULL;
f01010c2:	b8 00 00 00 00       	mov    $0x0,%eax
f01010c7:	eb 05                	jmp    f01010ce <pgdir_walk+0x8e>
		struct PageInfo *page = page_alloc(ALLOC_ZERO);
		if(page == NULL) return NULL;
f01010c9:	b8 00 00 00 00       	mov    $0x0,%eax
		page->pp_ref ++;
	}
	pgt = KADDR(PTE_ADDR(*pde));
	
	return &pgt[PTX(va)];
}
f01010ce:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01010d1:	5b                   	pop    %ebx
f01010d2:	5e                   	pop    %esi
f01010d3:	5d                   	pop    %ebp
f01010d4:	c3                   	ret    

f01010d5 <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f01010d5:	55                   	push   %ebp
f01010d6:	89 e5                	mov    %esp,%ebp
f01010d8:	57                   	push   %edi
f01010d9:	56                   	push   %esi
f01010da:	53                   	push   %ebx
f01010db:	83 ec 1c             	sub    $0x1c,%esp
f01010de:	89 45 dc             	mov    %eax,-0x24(%ebp)
f01010e1:	c1 e9 0c             	shr    $0xc,%ecx
f01010e4:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	int i;
	for(i = 0; i < (size / PGSIZE); i++, va += PGSIZE, pa+=PGSIZE){
f01010e7:	89 d3                	mov    %edx,%ebx
f01010e9:	bf 00 00 00 00       	mov    $0x0,%edi
f01010ee:	8b 45 08             	mov    0x8(%ebp),%eax
f01010f1:	29 d0                	sub    %edx,%eax
f01010f3:	89 45 e0             	mov    %eax,-0x20(%ebp)
		pte_t* pte = pgdir_walk(pgdir,(const void *) va, 1);	
		if(pte!=NULL){
			*pte = pa|perm|PTE_P;
f01010f6:	8b 45 0c             	mov    0xc(%ebp),%eax
f01010f9:	83 c8 01             	or     $0x1,%eax
f01010fc:	89 45 d8             	mov    %eax,-0x28(%ebp)
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	int i;
	for(i = 0; i < (size / PGSIZE); i++, va += PGSIZE, pa+=PGSIZE){
f01010ff:	eb 23                	jmp    f0101124 <boot_map_region+0x4f>
		pte_t* pte = pgdir_walk(pgdir,(const void *) va, 1);	
f0101101:	83 ec 04             	sub    $0x4,%esp
f0101104:	6a 01                	push   $0x1
f0101106:	53                   	push   %ebx
f0101107:	ff 75 dc             	pushl  -0x24(%ebp)
f010110a:	e8 31 ff ff ff       	call   f0101040 <pgdir_walk>
		if(pte!=NULL){
f010110f:	83 c4 10             	add    $0x10,%esp
f0101112:	85 c0                	test   %eax,%eax
f0101114:	74 05                	je     f010111b <boot_map_region+0x46>
			*pte = pa|perm|PTE_P;
f0101116:	0b 75 d8             	or     -0x28(%ebp),%esi
f0101119:	89 30                	mov    %esi,(%eax)
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	int i;
	for(i = 0; i < (size / PGSIZE); i++, va += PGSIZE, pa+=PGSIZE){
f010111b:	83 c7 01             	add    $0x1,%edi
f010111e:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0101124:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101127:	8d 34 18             	lea    (%eax,%ebx,1),%esi
f010112a:	3b 7d e4             	cmp    -0x1c(%ebp),%edi
f010112d:	75 d2                	jne    f0101101 <boot_map_region+0x2c>
		pte_t* pte = pgdir_walk(pgdir,(const void *) va, 1);	
		if(pte!=NULL){
			*pte = pa|perm|PTE_P;
		}
	}
}
f010112f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101132:	5b                   	pop    %ebx
f0101133:	5e                   	pop    %esi
f0101134:	5f                   	pop    %edi
f0101135:	5d                   	pop    %ebp
f0101136:	c3                   	ret    

f0101137 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0101137:	55                   	push   %ebp
f0101138:	89 e5                	mov    %esp,%ebp
f010113a:	53                   	push   %ebx
f010113b:	83 ec 08             	sub    $0x8,%esp
f010113e:	8b 5d 10             	mov    0x10(%ebp),%ebx
	pte_t *pte = pgdir_walk(pgdir, va, 0);
f0101141:	6a 00                	push   $0x0
f0101143:	ff 75 0c             	pushl  0xc(%ebp)
f0101146:	ff 75 08             	pushl  0x8(%ebp)
f0101149:	e8 f2 fe ff ff       	call   f0101040 <pgdir_walk>
	if(pte == NULL)
f010114e:	83 c4 10             	add    $0x10,%esp
f0101151:	85 c0                	test   %eax,%eax
f0101153:	74 32                	je     f0101187 <page_lookup+0x50>
		return NULL;
	else{
		if(pte_store!=NULL)		
f0101155:	85 db                	test   %ebx,%ebx
f0101157:	74 02                	je     f010115b <page_lookup+0x24>
			*pte_store = pte;
f0101159:	89 03                	mov    %eax,(%ebx)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010115b:	8b 00                	mov    (%eax),%eax
f010115d:	c1 e8 0c             	shr    $0xc,%eax
f0101160:	3b 05 88 fe 22 f0    	cmp    0xf022fe88,%eax
f0101166:	72 14                	jb     f010117c <page_lookup+0x45>
		panic("pa2page called with invalid pa");
f0101168:	83 ec 04             	sub    $0x4,%esp
f010116b:	68 50 67 10 f0       	push   $0xf0106750
f0101170:	6a 51                	push   $0x51
f0101172:	68 d0 6f 10 f0       	push   $0xf0106fd0
f0101177:	e8 c4 ee ff ff       	call   f0100040 <_panic>
	return &pages[PGNUM(pa)];
f010117c:	8b 15 90 fe 22 f0    	mov    0xf022fe90,%edx
f0101182:	8d 04 c2             	lea    (%edx,%eax,8),%eax
		
		return pa2page(PTE_ADDR(*pte));
f0101185:	eb 05                	jmp    f010118c <page_lookup+0x55>
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
	pte_t *pte = pgdir_walk(pgdir, va, 0);
	if(pte == NULL)
		return NULL;
f0101187:	b8 00 00 00 00       	mov    $0x0,%eax
			*pte_store = pte;
		
		return pa2page(PTE_ADDR(*pte));
	}

}
f010118c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010118f:	c9                   	leave  
f0101190:	c3                   	ret    

f0101191 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0101191:	55                   	push   %ebp
f0101192:	89 e5                	mov    %esp,%ebp
f0101194:	83 ec 08             	sub    $0x8,%esp
	// Flush the entry only if we're modifying the current address space.
	if (!curenv || curenv->env_pgdir == pgdir)
f0101197:	e8 8a 48 00 00       	call   f0105a26 <cpunum>
f010119c:	6b c0 74             	imul   $0x74,%eax,%eax
f010119f:	83 b8 28 00 23 f0 00 	cmpl   $0x0,-0xfdcffd8(%eax)
f01011a6:	74 16                	je     f01011be <tlb_invalidate+0x2d>
f01011a8:	e8 79 48 00 00       	call   f0105a26 <cpunum>
f01011ad:	6b c0 74             	imul   $0x74,%eax,%eax
f01011b0:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f01011b6:	8b 55 08             	mov    0x8(%ebp),%edx
f01011b9:	39 50 60             	cmp    %edx,0x60(%eax)
f01011bc:	75 06                	jne    f01011c4 <tlb_invalidate+0x33>
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01011be:	8b 45 0c             	mov    0xc(%ebp),%eax
f01011c1:	0f 01 38             	invlpg (%eax)
		invlpg(va);
}
f01011c4:	c9                   	leave  
f01011c5:	c3                   	ret    

f01011c6 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f01011c6:	55                   	push   %ebp
f01011c7:	89 e5                	mov    %esp,%ebp
f01011c9:	56                   	push   %esi
f01011ca:	53                   	push   %ebx
f01011cb:	83 ec 14             	sub    $0x14,%esp
f01011ce:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01011d1:	8b 75 0c             	mov    0xc(%ebp),%esi
	// Fill this function in
	pte_t *pte;
	struct PageInfo *pp = page_lookup(pgdir, va, &pte);
f01011d4:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01011d7:	50                   	push   %eax
f01011d8:	56                   	push   %esi
f01011d9:	53                   	push   %ebx
f01011da:	e8 58 ff ff ff       	call   f0101137 <page_lookup>
	if(pp!=NULL){
f01011df:	83 c4 10             	add    $0x10,%esp
f01011e2:	85 c0                	test   %eax,%eax
f01011e4:	74 1f                	je     f0101205 <page_remove+0x3f>
		page_decref(pp);
f01011e6:	83 ec 0c             	sub    $0xc,%esp
f01011e9:	50                   	push   %eax
f01011ea:	e8 2a fe ff ff       	call   f0101019 <page_decref>
		*pte = 0;
f01011ef:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01011f2:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		tlb_invalidate(pgdir, va);
f01011f8:	83 c4 08             	add    $0x8,%esp
f01011fb:	56                   	push   %esi
f01011fc:	53                   	push   %ebx
f01011fd:	e8 8f ff ff ff       	call   f0101191 <tlb_invalidate>
f0101202:	83 c4 10             	add    $0x10,%esp
	}
}
f0101205:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0101208:	5b                   	pop    %ebx
f0101209:	5e                   	pop    %esi
f010120a:	5d                   	pop    %ebp
f010120b:	c3                   	ret    

f010120c <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f010120c:	55                   	push   %ebp
f010120d:	89 e5                	mov    %esp,%ebp
f010120f:	57                   	push   %edi
f0101210:	56                   	push   %esi
f0101211:	53                   	push   %ebx
f0101212:	83 ec 10             	sub    $0x10,%esp
f0101215:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101218:	8b 7d 10             	mov    0x10(%ebp),%edi
	pte_t *pte = pgdir_walk(pgdir, va, 1); 
f010121b:	6a 01                	push   $0x1
f010121d:	57                   	push   %edi
f010121e:	ff 75 08             	pushl  0x8(%ebp)
f0101221:	e8 1a fe ff ff       	call   f0101040 <pgdir_walk>
	if(pte){
f0101226:	83 c4 10             	add    $0x10,%esp
f0101229:	85 c0                	test   %eax,%eax
f010122b:	74 4a                	je     f0101277 <page_insert+0x6b>
f010122d:	89 c6                	mov    %eax,%esi
		pp->pp_ref ++;
f010122f:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
		if(PTE_ADDR(*pte))
f0101234:	f7 00 00 f0 ff ff    	testl  $0xfffff000,(%eax)
f010123a:	74 0f                	je     f010124b <page_insert+0x3f>
			page_remove(pgdir, va);
f010123c:	83 ec 08             	sub    $0x8,%esp
f010123f:	57                   	push   %edi
f0101240:	ff 75 08             	pushl  0x8(%ebp)
f0101243:	e8 7e ff ff ff       	call   f01011c6 <page_remove>
f0101248:	83 c4 10             	add    $0x10,%esp
		*pte = page2pa(pp) | perm |PTE_P;
f010124b:	2b 1d 90 fe 22 f0    	sub    0xf022fe90,%ebx
f0101251:	c1 fb 03             	sar    $0x3,%ebx
f0101254:	c1 e3 0c             	shl    $0xc,%ebx
f0101257:	8b 45 14             	mov    0x14(%ebp),%eax
f010125a:	83 c8 01             	or     $0x1,%eax
f010125d:	09 c3                	or     %eax,%ebx
f010125f:	89 1e                	mov    %ebx,(%esi)
		tlb_invalidate(pgdir, va);
f0101261:	83 ec 08             	sub    $0x8,%esp
f0101264:	57                   	push   %edi
f0101265:	ff 75 08             	pushl  0x8(%ebp)
f0101268:	e8 24 ff ff ff       	call   f0101191 <tlb_invalidate>
		return 0;
f010126d:	83 c4 10             	add    $0x10,%esp
f0101270:	b8 00 00 00 00       	mov    $0x0,%eax
f0101275:	eb 05                	jmp    f010127c <page_insert+0x70>
	}
	return -E_NO_MEM;
f0101277:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	
}
f010127c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010127f:	5b                   	pop    %ebx
f0101280:	5e                   	pop    %esi
f0101281:	5f                   	pop    %edi
f0101282:	5d                   	pop    %ebp
f0101283:	c3                   	ret    

f0101284 <mmio_map_region>:
// location.  Return the base of the reserved region.  size does *not*
// have to be multiple of PGSIZE.
//
void *
mmio_map_region(physaddr_t pa, size_t size)
{
f0101284:	55                   	push   %ebp
f0101285:	89 e5                	mov    %esp,%ebp
f0101287:	53                   	push   %ebx
f0101288:	83 ec 04             	sub    $0x4,%esp
	// okay to simply panic if this happens).
	//
	// Hint: The staff solution uses boot_map_region.
	//
	// Your code here:
    size = ROUNDUP(size, PGSIZE);
f010128b:	8b 45 0c             	mov    0xc(%ebp),%eax
f010128e:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
f0101294:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
    if(base + size > MMIOLIM){
f010129a:	8b 15 00 03 12 f0    	mov    0xf0120300,%edx
f01012a0:	8d 04 13             	lea    (%ebx,%edx,1),%eax
f01012a3:	3d 00 00 c0 ef       	cmp    $0xefc00000,%eax
f01012a8:	76 17                	jbe    f01012c1 <mmio_map_region+0x3d>
        panic("mmio_map_region: reservation mem overflow");
f01012aa:	83 ec 04             	sub    $0x4,%esp
f01012ad:	68 70 67 10 f0       	push   $0xf0106770
f01012b2:	68 62 02 00 00       	push   $0x262
f01012b7:	68 b5 6f 10 f0       	push   $0xf0106fb5
f01012bc:	e8 7f ed ff ff       	call   f0100040 <_panic>
    }
    boot_map_region(kern_pgdir, base, size, pa, PTE_W | PTE_PCD | PTE_P);
f01012c1:	83 ec 08             	sub    $0x8,%esp
f01012c4:	6a 13                	push   $0x13
f01012c6:	ff 75 08             	pushl  0x8(%ebp)
f01012c9:	89 d9                	mov    %ebx,%ecx
f01012cb:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
f01012d0:	e8 00 fe ff ff       	call   f01010d5 <boot_map_region>
    uintptr_t b = base;
f01012d5:	a1 00 03 12 f0       	mov    0xf0120300,%eax
    base += size;
f01012da:	01 c3                	add    %eax,%ebx
f01012dc:	89 1d 00 03 12 f0    	mov    %ebx,0xf0120300
    return (void *) b;
    //panic("mmio_map_region not implemented");
}
f01012e2:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01012e5:	c9                   	leave  
f01012e6:	c3                   	ret    

f01012e7 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f01012e7:	55                   	push   %ebp
f01012e8:	89 e5                	mov    %esp,%ebp
f01012ea:	57                   	push   %edi
f01012eb:	56                   	push   %esi
f01012ec:	53                   	push   %ebx
f01012ed:	83 ec 3c             	sub    $0x3c,%esp
{
	size_t basemem, extmem, ext16mem, totalmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	basemem = nvram_read(NVRAM_BASELO);
f01012f0:	b8 15 00 00 00       	mov    $0x15,%eax
f01012f5:	e8 52 f7 ff ff       	call   f0100a4c <nvram_read>
f01012fa:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f01012fc:	b8 17 00 00 00       	mov    $0x17,%eax
f0101301:	e8 46 f7 ff ff       	call   f0100a4c <nvram_read>
f0101306:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f0101308:	b8 34 00 00 00       	mov    $0x34,%eax
f010130d:	e8 3a f7 ff ff       	call   f0100a4c <nvram_read>
f0101312:	c1 e0 06             	shl    $0x6,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (ext16mem)
f0101315:	85 c0                	test   %eax,%eax
f0101317:	74 07                	je     f0101320 <mem_init+0x39>
		totalmem = 16 * 1024 + ext16mem;
f0101319:	05 00 40 00 00       	add    $0x4000,%eax
f010131e:	eb 0b                	jmp    f010132b <mem_init+0x44>
	else if (extmem)
		totalmem = 1 * 1024 + extmem;
f0101320:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f0101326:	85 f6                	test   %esi,%esi
f0101328:	0f 44 c3             	cmove  %ebx,%eax
	else
		totalmem = basemem;

	npages = totalmem / (PGSIZE / 1024);
f010132b:	89 c2                	mov    %eax,%edx
f010132d:	c1 ea 02             	shr    $0x2,%edx
f0101330:	89 15 88 fe 22 f0    	mov    %edx,0xf022fe88
	npages_basemem = basemem / (PGSIZE / 1024);

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101336:	89 c2                	mov    %eax,%edx
f0101338:	29 da                	sub    %ebx,%edx
f010133a:	52                   	push   %edx
f010133b:	53                   	push   %ebx
f010133c:	50                   	push   %eax
f010133d:	68 9c 67 10 f0       	push   $0xf010679c
f0101342:	e8 17 23 00 00       	call   f010365e <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0101347:	b8 00 10 00 00       	mov    $0x1000,%eax
f010134c:	e8 88 f7 ff ff       	call   f0100ad9 <boot_alloc>
f0101351:	a3 8c fe 22 f0       	mov    %eax,0xf022fe8c
	memset(kern_pgdir, 0, PGSIZE);
f0101356:	83 c4 0c             	add    $0xc,%esp
f0101359:	68 00 10 00 00       	push   $0x1000
f010135e:	6a 00                	push   $0x0
f0101360:	50                   	push   %eax
f0101361:	e8 9e 40 00 00       	call   f0105404 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0101366:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010136b:	83 c4 10             	add    $0x10,%esp
f010136e:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101373:	77 15                	ja     f010138a <mem_init+0xa3>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101375:	50                   	push   %eax
f0101376:	68 08 61 10 f0       	push   $0xf0106108
f010137b:	68 96 00 00 00       	push   $0x96
f0101380:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0101385:	e8 b6 ec ff ff       	call   f0100040 <_panic>
f010138a:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0101390:	83 ca 05             	or     $0x5,%edx
f0101393:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	pages = (struct PageInfo *) boot_alloc(npages * sizeof(struct PageInfo));
f0101399:	a1 88 fe 22 f0       	mov    0xf022fe88,%eax
f010139e:	c1 e0 03             	shl    $0x3,%eax
f01013a1:	e8 33 f7 ff ff       	call   f0100ad9 <boot_alloc>
f01013a6:	a3 90 fe 22 f0       	mov    %eax,0xf022fe90
	memset(pages, 0, npages * sizeof(struct PageInfo));
f01013ab:	83 ec 04             	sub    $0x4,%esp
f01013ae:	8b 0d 88 fe 22 f0    	mov    0xf022fe88,%ecx
f01013b4:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f01013bb:	52                   	push   %edx
f01013bc:	6a 00                	push   $0x0
f01013be:	50                   	push   %eax
f01013bf:	e8 40 40 00 00       	call   f0105404 <memset>

	//////////////////////////////////////////////////////////////////////
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.
	envs = (struct Env *) boot_alloc(NENV * sizeof(struct Env));
f01013c4:	b8 00 f0 01 00       	mov    $0x1f000,%eax
f01013c9:	e8 0b f7 ff ff       	call   f0100ad9 <boot_alloc>
f01013ce:	a3 44 f2 22 f0       	mov    %eax,0xf022f244
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f01013d3:	e8 8a fa ff ff       	call   f0100e62 <page_init>

	check_page_free_list(1);
f01013d8:	b8 01 00 00 00       	mov    $0x1,%eax
f01013dd:	e8 7e f7 ff ff       	call   f0100b60 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f01013e2:	83 c4 10             	add    $0x10,%esp
f01013e5:	83 3d 90 fe 22 f0 00 	cmpl   $0x0,0xf022fe90
f01013ec:	75 17                	jne    f0101405 <mem_init+0x11e>
		panic("'pages' is a null pointer!");
f01013ee:	83 ec 04             	sub    $0x4,%esp
f01013f1:	68 97 70 10 f0       	push   $0xf0107097
f01013f6:	68 f9 02 00 00       	push   $0x2f9
f01013fb:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0101400:	e8 3b ec ff ff       	call   f0100040 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101405:	a1 40 f2 22 f0       	mov    0xf022f240,%eax
f010140a:	bb 00 00 00 00       	mov    $0x0,%ebx
f010140f:	eb 05                	jmp    f0101416 <mem_init+0x12f>
		++nfree;
f0101411:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101414:	8b 00                	mov    (%eax),%eax
f0101416:	85 c0                	test   %eax,%eax
f0101418:	75 f7                	jne    f0101411 <mem_init+0x12a>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010141a:	83 ec 0c             	sub    $0xc,%esp
f010141d:	6a 00                	push   $0x0
f010141f:	e8 43 fb ff ff       	call   f0100f67 <page_alloc>
f0101424:	89 c7                	mov    %eax,%edi
f0101426:	83 c4 10             	add    $0x10,%esp
f0101429:	85 c0                	test   %eax,%eax
f010142b:	75 19                	jne    f0101446 <mem_init+0x15f>
f010142d:	68 b2 70 10 f0       	push   $0xf01070b2
f0101432:	68 ea 6f 10 f0       	push   $0xf0106fea
f0101437:	68 01 03 00 00       	push   $0x301
f010143c:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0101441:	e8 fa eb ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0101446:	83 ec 0c             	sub    $0xc,%esp
f0101449:	6a 00                	push   $0x0
f010144b:	e8 17 fb ff ff       	call   f0100f67 <page_alloc>
f0101450:	89 c6                	mov    %eax,%esi
f0101452:	83 c4 10             	add    $0x10,%esp
f0101455:	85 c0                	test   %eax,%eax
f0101457:	75 19                	jne    f0101472 <mem_init+0x18b>
f0101459:	68 c8 70 10 f0       	push   $0xf01070c8
f010145e:	68 ea 6f 10 f0       	push   $0xf0106fea
f0101463:	68 02 03 00 00       	push   $0x302
f0101468:	68 b5 6f 10 f0       	push   $0xf0106fb5
f010146d:	e8 ce eb ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0101472:	83 ec 0c             	sub    $0xc,%esp
f0101475:	6a 00                	push   $0x0
f0101477:	e8 eb fa ff ff       	call   f0100f67 <page_alloc>
f010147c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010147f:	83 c4 10             	add    $0x10,%esp
f0101482:	85 c0                	test   %eax,%eax
f0101484:	75 19                	jne    f010149f <mem_init+0x1b8>
f0101486:	68 de 70 10 f0       	push   $0xf01070de
f010148b:	68 ea 6f 10 f0       	push   $0xf0106fea
f0101490:	68 03 03 00 00       	push   $0x303
f0101495:	68 b5 6f 10 f0       	push   $0xf0106fb5
f010149a:	e8 a1 eb ff ff       	call   f0100040 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010149f:	39 f7                	cmp    %esi,%edi
f01014a1:	75 19                	jne    f01014bc <mem_init+0x1d5>
f01014a3:	68 f4 70 10 f0       	push   $0xf01070f4
f01014a8:	68 ea 6f 10 f0       	push   $0xf0106fea
f01014ad:	68 06 03 00 00       	push   $0x306
f01014b2:	68 b5 6f 10 f0       	push   $0xf0106fb5
f01014b7:	e8 84 eb ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01014bc:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01014bf:	39 c6                	cmp    %eax,%esi
f01014c1:	74 04                	je     f01014c7 <mem_init+0x1e0>
f01014c3:	39 c7                	cmp    %eax,%edi
f01014c5:	75 19                	jne    f01014e0 <mem_init+0x1f9>
f01014c7:	68 d8 67 10 f0       	push   $0xf01067d8
f01014cc:	68 ea 6f 10 f0       	push   $0xf0106fea
f01014d1:	68 07 03 00 00       	push   $0x307
f01014d6:	68 b5 6f 10 f0       	push   $0xf0106fb5
f01014db:	e8 60 eb ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01014e0:	8b 0d 90 fe 22 f0    	mov    0xf022fe90,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f01014e6:	8b 15 88 fe 22 f0    	mov    0xf022fe88,%edx
f01014ec:	c1 e2 0c             	shl    $0xc,%edx
f01014ef:	89 f8                	mov    %edi,%eax
f01014f1:	29 c8                	sub    %ecx,%eax
f01014f3:	c1 f8 03             	sar    $0x3,%eax
f01014f6:	c1 e0 0c             	shl    $0xc,%eax
f01014f9:	39 d0                	cmp    %edx,%eax
f01014fb:	72 19                	jb     f0101516 <mem_init+0x22f>
f01014fd:	68 06 71 10 f0       	push   $0xf0107106
f0101502:	68 ea 6f 10 f0       	push   $0xf0106fea
f0101507:	68 08 03 00 00       	push   $0x308
f010150c:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0101511:	e8 2a eb ff ff       	call   f0100040 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f0101516:	89 f0                	mov    %esi,%eax
f0101518:	29 c8                	sub    %ecx,%eax
f010151a:	c1 f8 03             	sar    $0x3,%eax
f010151d:	c1 e0 0c             	shl    $0xc,%eax
f0101520:	39 c2                	cmp    %eax,%edx
f0101522:	77 19                	ja     f010153d <mem_init+0x256>
f0101524:	68 23 71 10 f0       	push   $0xf0107123
f0101529:	68 ea 6f 10 f0       	push   $0xf0106fea
f010152e:	68 09 03 00 00       	push   $0x309
f0101533:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0101538:	e8 03 eb ff ff       	call   f0100040 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f010153d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101540:	29 c8                	sub    %ecx,%eax
f0101542:	c1 f8 03             	sar    $0x3,%eax
f0101545:	c1 e0 0c             	shl    $0xc,%eax
f0101548:	39 c2                	cmp    %eax,%edx
f010154a:	77 19                	ja     f0101565 <mem_init+0x27e>
f010154c:	68 40 71 10 f0       	push   $0xf0107140
f0101551:	68 ea 6f 10 f0       	push   $0xf0106fea
f0101556:	68 0a 03 00 00       	push   $0x30a
f010155b:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0101560:	e8 db ea ff ff       	call   f0100040 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101565:	a1 40 f2 22 f0       	mov    0xf022f240,%eax
f010156a:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f010156d:	c7 05 40 f2 22 f0 00 	movl   $0x0,0xf022f240
f0101574:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101577:	83 ec 0c             	sub    $0xc,%esp
f010157a:	6a 00                	push   $0x0
f010157c:	e8 e6 f9 ff ff       	call   f0100f67 <page_alloc>
f0101581:	83 c4 10             	add    $0x10,%esp
f0101584:	85 c0                	test   %eax,%eax
f0101586:	74 19                	je     f01015a1 <mem_init+0x2ba>
f0101588:	68 5d 71 10 f0       	push   $0xf010715d
f010158d:	68 ea 6f 10 f0       	push   $0xf0106fea
f0101592:	68 11 03 00 00       	push   $0x311
f0101597:	68 b5 6f 10 f0       	push   $0xf0106fb5
f010159c:	e8 9f ea ff ff       	call   f0100040 <_panic>

	// free and re-allocate?
	page_free(pp0);
f01015a1:	83 ec 0c             	sub    $0xc,%esp
f01015a4:	57                   	push   %edi
f01015a5:	e8 34 fa ff ff       	call   f0100fde <page_free>
	page_free(pp1);
f01015aa:	89 34 24             	mov    %esi,(%esp)
f01015ad:	e8 2c fa ff ff       	call   f0100fde <page_free>
	page_free(pp2);
f01015b2:	83 c4 04             	add    $0x4,%esp
f01015b5:	ff 75 d4             	pushl  -0x2c(%ebp)
f01015b8:	e8 21 fa ff ff       	call   f0100fde <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01015bd:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01015c4:	e8 9e f9 ff ff       	call   f0100f67 <page_alloc>
f01015c9:	89 c6                	mov    %eax,%esi
f01015cb:	83 c4 10             	add    $0x10,%esp
f01015ce:	85 c0                	test   %eax,%eax
f01015d0:	75 19                	jne    f01015eb <mem_init+0x304>
f01015d2:	68 b2 70 10 f0       	push   $0xf01070b2
f01015d7:	68 ea 6f 10 f0       	push   $0xf0106fea
f01015dc:	68 18 03 00 00       	push   $0x318
f01015e1:	68 b5 6f 10 f0       	push   $0xf0106fb5
f01015e6:	e8 55 ea ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f01015eb:	83 ec 0c             	sub    $0xc,%esp
f01015ee:	6a 00                	push   $0x0
f01015f0:	e8 72 f9 ff ff       	call   f0100f67 <page_alloc>
f01015f5:	89 c7                	mov    %eax,%edi
f01015f7:	83 c4 10             	add    $0x10,%esp
f01015fa:	85 c0                	test   %eax,%eax
f01015fc:	75 19                	jne    f0101617 <mem_init+0x330>
f01015fe:	68 c8 70 10 f0       	push   $0xf01070c8
f0101603:	68 ea 6f 10 f0       	push   $0xf0106fea
f0101608:	68 19 03 00 00       	push   $0x319
f010160d:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0101612:	e8 29 ea ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0101617:	83 ec 0c             	sub    $0xc,%esp
f010161a:	6a 00                	push   $0x0
f010161c:	e8 46 f9 ff ff       	call   f0100f67 <page_alloc>
f0101621:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101624:	83 c4 10             	add    $0x10,%esp
f0101627:	85 c0                	test   %eax,%eax
f0101629:	75 19                	jne    f0101644 <mem_init+0x35d>
f010162b:	68 de 70 10 f0       	push   $0xf01070de
f0101630:	68 ea 6f 10 f0       	push   $0xf0106fea
f0101635:	68 1a 03 00 00       	push   $0x31a
f010163a:	68 b5 6f 10 f0       	push   $0xf0106fb5
f010163f:	e8 fc e9 ff ff       	call   f0100040 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101644:	39 fe                	cmp    %edi,%esi
f0101646:	75 19                	jne    f0101661 <mem_init+0x37a>
f0101648:	68 f4 70 10 f0       	push   $0xf01070f4
f010164d:	68 ea 6f 10 f0       	push   $0xf0106fea
f0101652:	68 1c 03 00 00       	push   $0x31c
f0101657:	68 b5 6f 10 f0       	push   $0xf0106fb5
f010165c:	e8 df e9 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101661:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101664:	39 c7                	cmp    %eax,%edi
f0101666:	74 04                	je     f010166c <mem_init+0x385>
f0101668:	39 c6                	cmp    %eax,%esi
f010166a:	75 19                	jne    f0101685 <mem_init+0x39e>
f010166c:	68 d8 67 10 f0       	push   $0xf01067d8
f0101671:	68 ea 6f 10 f0       	push   $0xf0106fea
f0101676:	68 1d 03 00 00       	push   $0x31d
f010167b:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0101680:	e8 bb e9 ff ff       	call   f0100040 <_panic>
	assert(!page_alloc(0));
f0101685:	83 ec 0c             	sub    $0xc,%esp
f0101688:	6a 00                	push   $0x0
f010168a:	e8 d8 f8 ff ff       	call   f0100f67 <page_alloc>
f010168f:	83 c4 10             	add    $0x10,%esp
f0101692:	85 c0                	test   %eax,%eax
f0101694:	74 19                	je     f01016af <mem_init+0x3c8>
f0101696:	68 5d 71 10 f0       	push   $0xf010715d
f010169b:	68 ea 6f 10 f0       	push   $0xf0106fea
f01016a0:	68 1e 03 00 00       	push   $0x31e
f01016a5:	68 b5 6f 10 f0       	push   $0xf0106fb5
f01016aa:	e8 91 e9 ff ff       	call   f0100040 <_panic>
f01016af:	89 f0                	mov    %esi,%eax
f01016b1:	2b 05 90 fe 22 f0    	sub    0xf022fe90,%eax
f01016b7:	c1 f8 03             	sar    $0x3,%eax
f01016ba:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01016bd:	89 c2                	mov    %eax,%edx
f01016bf:	c1 ea 0c             	shr    $0xc,%edx
f01016c2:	3b 15 88 fe 22 f0    	cmp    0xf022fe88,%edx
f01016c8:	72 12                	jb     f01016dc <mem_init+0x3f5>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01016ca:	50                   	push   %eax
f01016cb:	68 e4 60 10 f0       	push   $0xf01060e4
f01016d0:	6a 58                	push   $0x58
f01016d2:	68 d0 6f 10 f0       	push   $0xf0106fd0
f01016d7:	e8 64 e9 ff ff       	call   f0100040 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f01016dc:	83 ec 04             	sub    $0x4,%esp
f01016df:	68 00 10 00 00       	push   $0x1000
f01016e4:	6a 01                	push   $0x1
f01016e6:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01016eb:	50                   	push   %eax
f01016ec:	e8 13 3d 00 00       	call   f0105404 <memset>
	page_free(pp0);
f01016f1:	89 34 24             	mov    %esi,(%esp)
f01016f4:	e8 e5 f8 ff ff       	call   f0100fde <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01016f9:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101700:	e8 62 f8 ff ff       	call   f0100f67 <page_alloc>
f0101705:	83 c4 10             	add    $0x10,%esp
f0101708:	85 c0                	test   %eax,%eax
f010170a:	75 19                	jne    f0101725 <mem_init+0x43e>
f010170c:	68 6c 71 10 f0       	push   $0xf010716c
f0101711:	68 ea 6f 10 f0       	push   $0xf0106fea
f0101716:	68 23 03 00 00       	push   $0x323
f010171b:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0101720:	e8 1b e9 ff ff       	call   f0100040 <_panic>
	assert(pp && pp0 == pp);
f0101725:	39 c6                	cmp    %eax,%esi
f0101727:	74 19                	je     f0101742 <mem_init+0x45b>
f0101729:	68 8a 71 10 f0       	push   $0xf010718a
f010172e:	68 ea 6f 10 f0       	push   $0xf0106fea
f0101733:	68 24 03 00 00       	push   $0x324
f0101738:	68 b5 6f 10 f0       	push   $0xf0106fb5
f010173d:	e8 fe e8 ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101742:	89 f0                	mov    %esi,%eax
f0101744:	2b 05 90 fe 22 f0    	sub    0xf022fe90,%eax
f010174a:	c1 f8 03             	sar    $0x3,%eax
f010174d:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101750:	89 c2                	mov    %eax,%edx
f0101752:	c1 ea 0c             	shr    $0xc,%edx
f0101755:	3b 15 88 fe 22 f0    	cmp    0xf022fe88,%edx
f010175b:	72 12                	jb     f010176f <mem_init+0x488>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010175d:	50                   	push   %eax
f010175e:	68 e4 60 10 f0       	push   $0xf01060e4
f0101763:	6a 58                	push   $0x58
f0101765:	68 d0 6f 10 f0       	push   $0xf0106fd0
f010176a:	e8 d1 e8 ff ff       	call   f0100040 <_panic>
f010176f:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f0101775:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f010177b:	80 38 00             	cmpb   $0x0,(%eax)
f010177e:	74 19                	je     f0101799 <mem_init+0x4b2>
f0101780:	68 9a 71 10 f0       	push   $0xf010719a
f0101785:	68 ea 6f 10 f0       	push   $0xf0106fea
f010178a:	68 27 03 00 00       	push   $0x327
f010178f:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0101794:	e8 a7 e8 ff ff       	call   f0100040 <_panic>
f0101799:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f010179c:	39 d0                	cmp    %edx,%eax
f010179e:	75 db                	jne    f010177b <mem_init+0x494>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f01017a0:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01017a3:	a3 40 f2 22 f0       	mov    %eax,0xf022f240

	// free the pages we took
	page_free(pp0);
f01017a8:	83 ec 0c             	sub    $0xc,%esp
f01017ab:	56                   	push   %esi
f01017ac:	e8 2d f8 ff ff       	call   f0100fde <page_free>
	page_free(pp1);
f01017b1:	89 3c 24             	mov    %edi,(%esp)
f01017b4:	e8 25 f8 ff ff       	call   f0100fde <page_free>
	page_free(pp2);
f01017b9:	83 c4 04             	add    $0x4,%esp
f01017bc:	ff 75 d4             	pushl  -0x2c(%ebp)
f01017bf:	e8 1a f8 ff ff       	call   f0100fde <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01017c4:	a1 40 f2 22 f0       	mov    0xf022f240,%eax
f01017c9:	83 c4 10             	add    $0x10,%esp
f01017cc:	eb 05                	jmp    f01017d3 <mem_init+0x4ec>
		--nfree;
f01017ce:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01017d1:	8b 00                	mov    (%eax),%eax
f01017d3:	85 c0                	test   %eax,%eax
f01017d5:	75 f7                	jne    f01017ce <mem_init+0x4e7>
		--nfree;
	assert(nfree == 0);
f01017d7:	85 db                	test   %ebx,%ebx
f01017d9:	74 19                	je     f01017f4 <mem_init+0x50d>
f01017db:	68 a4 71 10 f0       	push   $0xf01071a4
f01017e0:	68 ea 6f 10 f0       	push   $0xf0106fea
f01017e5:	68 34 03 00 00       	push   $0x334
f01017ea:	68 b5 6f 10 f0       	push   $0xf0106fb5
f01017ef:	e8 4c e8 ff ff       	call   f0100040 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f01017f4:	83 ec 0c             	sub    $0xc,%esp
f01017f7:	68 f8 67 10 f0       	push   $0xf01067f8
f01017fc:	e8 5d 1e 00 00       	call   f010365e <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101801:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101808:	e8 5a f7 ff ff       	call   f0100f67 <page_alloc>
f010180d:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101810:	83 c4 10             	add    $0x10,%esp
f0101813:	85 c0                	test   %eax,%eax
f0101815:	75 19                	jne    f0101830 <mem_init+0x549>
f0101817:	68 b2 70 10 f0       	push   $0xf01070b2
f010181c:	68 ea 6f 10 f0       	push   $0xf0106fea
f0101821:	68 9a 03 00 00       	push   $0x39a
f0101826:	68 b5 6f 10 f0       	push   $0xf0106fb5
f010182b:	e8 10 e8 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0101830:	83 ec 0c             	sub    $0xc,%esp
f0101833:	6a 00                	push   $0x0
f0101835:	e8 2d f7 ff ff       	call   f0100f67 <page_alloc>
f010183a:	89 c3                	mov    %eax,%ebx
f010183c:	83 c4 10             	add    $0x10,%esp
f010183f:	85 c0                	test   %eax,%eax
f0101841:	75 19                	jne    f010185c <mem_init+0x575>
f0101843:	68 c8 70 10 f0       	push   $0xf01070c8
f0101848:	68 ea 6f 10 f0       	push   $0xf0106fea
f010184d:	68 9b 03 00 00       	push   $0x39b
f0101852:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0101857:	e8 e4 e7 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f010185c:	83 ec 0c             	sub    $0xc,%esp
f010185f:	6a 00                	push   $0x0
f0101861:	e8 01 f7 ff ff       	call   f0100f67 <page_alloc>
f0101866:	89 c6                	mov    %eax,%esi
f0101868:	83 c4 10             	add    $0x10,%esp
f010186b:	85 c0                	test   %eax,%eax
f010186d:	75 19                	jne    f0101888 <mem_init+0x5a1>
f010186f:	68 de 70 10 f0       	push   $0xf01070de
f0101874:	68 ea 6f 10 f0       	push   $0xf0106fea
f0101879:	68 9c 03 00 00       	push   $0x39c
f010187e:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0101883:	e8 b8 e7 ff ff       	call   f0100040 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101888:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f010188b:	75 19                	jne    f01018a6 <mem_init+0x5bf>
f010188d:	68 f4 70 10 f0       	push   $0xf01070f4
f0101892:	68 ea 6f 10 f0       	push   $0xf0106fea
f0101897:	68 9f 03 00 00       	push   $0x39f
f010189c:	68 b5 6f 10 f0       	push   $0xf0106fb5
f01018a1:	e8 9a e7 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01018a6:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f01018a9:	74 04                	je     f01018af <mem_init+0x5c8>
f01018ab:	39 c3                	cmp    %eax,%ebx
f01018ad:	75 19                	jne    f01018c8 <mem_init+0x5e1>
f01018af:	68 d8 67 10 f0       	push   $0xf01067d8
f01018b4:	68 ea 6f 10 f0       	push   $0xf0106fea
f01018b9:	68 a0 03 00 00       	push   $0x3a0
f01018be:	68 b5 6f 10 f0       	push   $0xf0106fb5
f01018c3:	e8 78 e7 ff ff       	call   f0100040 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01018c8:	a1 40 f2 22 f0       	mov    0xf022f240,%eax
f01018cd:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01018d0:	c7 05 40 f2 22 f0 00 	movl   $0x0,0xf022f240
f01018d7:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01018da:	83 ec 0c             	sub    $0xc,%esp
f01018dd:	6a 00                	push   $0x0
f01018df:	e8 83 f6 ff ff       	call   f0100f67 <page_alloc>
f01018e4:	83 c4 10             	add    $0x10,%esp
f01018e7:	85 c0                	test   %eax,%eax
f01018e9:	74 19                	je     f0101904 <mem_init+0x61d>
f01018eb:	68 5d 71 10 f0       	push   $0xf010715d
f01018f0:	68 ea 6f 10 f0       	push   $0xf0106fea
f01018f5:	68 a7 03 00 00       	push   $0x3a7
f01018fa:	68 b5 6f 10 f0       	push   $0xf0106fb5
f01018ff:	e8 3c e7 ff ff       	call   f0100040 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101904:	83 ec 04             	sub    $0x4,%esp
f0101907:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010190a:	50                   	push   %eax
f010190b:	6a 00                	push   $0x0
f010190d:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0101913:	e8 1f f8 ff ff       	call   f0101137 <page_lookup>
f0101918:	83 c4 10             	add    $0x10,%esp
f010191b:	85 c0                	test   %eax,%eax
f010191d:	74 19                	je     f0101938 <mem_init+0x651>
f010191f:	68 18 68 10 f0       	push   $0xf0106818
f0101924:	68 ea 6f 10 f0       	push   $0xf0106fea
f0101929:	68 aa 03 00 00       	push   $0x3aa
f010192e:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0101933:	e8 08 e7 ff ff       	call   f0100040 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101938:	6a 02                	push   $0x2
f010193a:	6a 00                	push   $0x0
f010193c:	53                   	push   %ebx
f010193d:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0101943:	e8 c4 f8 ff ff       	call   f010120c <page_insert>
f0101948:	83 c4 10             	add    $0x10,%esp
f010194b:	85 c0                	test   %eax,%eax
f010194d:	78 19                	js     f0101968 <mem_init+0x681>
f010194f:	68 50 68 10 f0       	push   $0xf0106850
f0101954:	68 ea 6f 10 f0       	push   $0xf0106fea
f0101959:	68 ad 03 00 00       	push   $0x3ad
f010195e:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0101963:	e8 d8 e6 ff ff       	call   f0100040 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101968:	83 ec 0c             	sub    $0xc,%esp
f010196b:	ff 75 d4             	pushl  -0x2c(%ebp)
f010196e:	e8 6b f6 ff ff       	call   f0100fde <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101973:	6a 02                	push   $0x2
f0101975:	6a 00                	push   $0x0
f0101977:	53                   	push   %ebx
f0101978:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f010197e:	e8 89 f8 ff ff       	call   f010120c <page_insert>
f0101983:	83 c4 20             	add    $0x20,%esp
f0101986:	85 c0                	test   %eax,%eax
f0101988:	74 19                	je     f01019a3 <mem_init+0x6bc>
f010198a:	68 80 68 10 f0       	push   $0xf0106880
f010198f:	68 ea 6f 10 f0       	push   $0xf0106fea
f0101994:	68 b1 03 00 00       	push   $0x3b1
f0101999:	68 b5 6f 10 f0       	push   $0xf0106fb5
f010199e:	e8 9d e6 ff ff       	call   f0100040 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01019a3:	8b 3d 8c fe 22 f0    	mov    0xf022fe8c,%edi
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01019a9:	a1 90 fe 22 f0       	mov    0xf022fe90,%eax
f01019ae:	89 c1                	mov    %eax,%ecx
f01019b0:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01019b3:	8b 17                	mov    (%edi),%edx
f01019b5:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01019bb:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01019be:	29 c8                	sub    %ecx,%eax
f01019c0:	c1 f8 03             	sar    $0x3,%eax
f01019c3:	c1 e0 0c             	shl    $0xc,%eax
f01019c6:	39 c2                	cmp    %eax,%edx
f01019c8:	74 19                	je     f01019e3 <mem_init+0x6fc>
f01019ca:	68 b0 68 10 f0       	push   $0xf01068b0
f01019cf:	68 ea 6f 10 f0       	push   $0xf0106fea
f01019d4:	68 b2 03 00 00       	push   $0x3b2
f01019d9:	68 b5 6f 10 f0       	push   $0xf0106fb5
f01019de:	e8 5d e6 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f01019e3:	ba 00 00 00 00       	mov    $0x0,%edx
f01019e8:	89 f8                	mov    %edi,%eax
f01019ea:	e8 86 f0 ff ff       	call   f0100a75 <check_va2pa>
f01019ef:	89 da                	mov    %ebx,%edx
f01019f1:	2b 55 cc             	sub    -0x34(%ebp),%edx
f01019f4:	c1 fa 03             	sar    $0x3,%edx
f01019f7:	c1 e2 0c             	shl    $0xc,%edx
f01019fa:	39 d0                	cmp    %edx,%eax
f01019fc:	74 19                	je     f0101a17 <mem_init+0x730>
f01019fe:	68 d8 68 10 f0       	push   $0xf01068d8
f0101a03:	68 ea 6f 10 f0       	push   $0xf0106fea
f0101a08:	68 b3 03 00 00       	push   $0x3b3
f0101a0d:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0101a12:	e8 29 e6 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f0101a17:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101a1c:	74 19                	je     f0101a37 <mem_init+0x750>
f0101a1e:	68 af 71 10 f0       	push   $0xf01071af
f0101a23:	68 ea 6f 10 f0       	push   $0xf0106fea
f0101a28:	68 b4 03 00 00       	push   $0x3b4
f0101a2d:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0101a32:	e8 09 e6 ff ff       	call   f0100040 <_panic>
	assert(pp0->pp_ref == 1);
f0101a37:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a3a:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101a3f:	74 19                	je     f0101a5a <mem_init+0x773>
f0101a41:	68 c0 71 10 f0       	push   $0xf01071c0
f0101a46:	68 ea 6f 10 f0       	push   $0xf0106fea
f0101a4b:	68 b5 03 00 00       	push   $0x3b5
f0101a50:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0101a55:	e8 e6 e5 ff ff       	call   f0100040 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101a5a:	6a 02                	push   $0x2
f0101a5c:	68 00 10 00 00       	push   $0x1000
f0101a61:	56                   	push   %esi
f0101a62:	57                   	push   %edi
f0101a63:	e8 a4 f7 ff ff       	call   f010120c <page_insert>
f0101a68:	83 c4 10             	add    $0x10,%esp
f0101a6b:	85 c0                	test   %eax,%eax
f0101a6d:	74 19                	je     f0101a88 <mem_init+0x7a1>
f0101a6f:	68 08 69 10 f0       	push   $0xf0106908
f0101a74:	68 ea 6f 10 f0       	push   $0xf0106fea
f0101a79:	68 b8 03 00 00       	push   $0x3b8
f0101a7e:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0101a83:	e8 b8 e5 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101a88:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101a8d:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
f0101a92:	e8 de ef ff ff       	call   f0100a75 <check_va2pa>
f0101a97:	89 f2                	mov    %esi,%edx
f0101a99:	2b 15 90 fe 22 f0    	sub    0xf022fe90,%edx
f0101a9f:	c1 fa 03             	sar    $0x3,%edx
f0101aa2:	c1 e2 0c             	shl    $0xc,%edx
f0101aa5:	39 d0                	cmp    %edx,%eax
f0101aa7:	74 19                	je     f0101ac2 <mem_init+0x7db>
f0101aa9:	68 44 69 10 f0       	push   $0xf0106944
f0101aae:	68 ea 6f 10 f0       	push   $0xf0106fea
f0101ab3:	68 b9 03 00 00       	push   $0x3b9
f0101ab8:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0101abd:	e8 7e e5 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101ac2:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101ac7:	74 19                	je     f0101ae2 <mem_init+0x7fb>
f0101ac9:	68 d1 71 10 f0       	push   $0xf01071d1
f0101ace:	68 ea 6f 10 f0       	push   $0xf0106fea
f0101ad3:	68 ba 03 00 00       	push   $0x3ba
f0101ad8:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0101add:	e8 5e e5 ff ff       	call   f0100040 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101ae2:	83 ec 0c             	sub    $0xc,%esp
f0101ae5:	6a 00                	push   $0x0
f0101ae7:	e8 7b f4 ff ff       	call   f0100f67 <page_alloc>
f0101aec:	83 c4 10             	add    $0x10,%esp
f0101aef:	85 c0                	test   %eax,%eax
f0101af1:	74 19                	je     f0101b0c <mem_init+0x825>
f0101af3:	68 5d 71 10 f0       	push   $0xf010715d
f0101af8:	68 ea 6f 10 f0       	push   $0xf0106fea
f0101afd:	68 bd 03 00 00       	push   $0x3bd
f0101b02:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0101b07:	e8 34 e5 ff ff       	call   f0100040 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101b0c:	6a 02                	push   $0x2
f0101b0e:	68 00 10 00 00       	push   $0x1000
f0101b13:	56                   	push   %esi
f0101b14:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0101b1a:	e8 ed f6 ff ff       	call   f010120c <page_insert>
f0101b1f:	83 c4 10             	add    $0x10,%esp
f0101b22:	85 c0                	test   %eax,%eax
f0101b24:	74 19                	je     f0101b3f <mem_init+0x858>
f0101b26:	68 08 69 10 f0       	push   $0xf0106908
f0101b2b:	68 ea 6f 10 f0       	push   $0xf0106fea
f0101b30:	68 c0 03 00 00       	push   $0x3c0
f0101b35:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0101b3a:	e8 01 e5 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101b3f:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101b44:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
f0101b49:	e8 27 ef ff ff       	call   f0100a75 <check_va2pa>
f0101b4e:	89 f2                	mov    %esi,%edx
f0101b50:	2b 15 90 fe 22 f0    	sub    0xf022fe90,%edx
f0101b56:	c1 fa 03             	sar    $0x3,%edx
f0101b59:	c1 e2 0c             	shl    $0xc,%edx
f0101b5c:	39 d0                	cmp    %edx,%eax
f0101b5e:	74 19                	je     f0101b79 <mem_init+0x892>
f0101b60:	68 44 69 10 f0       	push   $0xf0106944
f0101b65:	68 ea 6f 10 f0       	push   $0xf0106fea
f0101b6a:	68 c1 03 00 00       	push   $0x3c1
f0101b6f:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0101b74:	e8 c7 e4 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101b79:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101b7e:	74 19                	je     f0101b99 <mem_init+0x8b2>
f0101b80:	68 d1 71 10 f0       	push   $0xf01071d1
f0101b85:	68 ea 6f 10 f0       	push   $0xf0106fea
f0101b8a:	68 c2 03 00 00       	push   $0x3c2
f0101b8f:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0101b94:	e8 a7 e4 ff ff       	call   f0100040 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101b99:	83 ec 0c             	sub    $0xc,%esp
f0101b9c:	6a 00                	push   $0x0
f0101b9e:	e8 c4 f3 ff ff       	call   f0100f67 <page_alloc>
f0101ba3:	83 c4 10             	add    $0x10,%esp
f0101ba6:	85 c0                	test   %eax,%eax
f0101ba8:	74 19                	je     f0101bc3 <mem_init+0x8dc>
f0101baa:	68 5d 71 10 f0       	push   $0xf010715d
f0101baf:	68 ea 6f 10 f0       	push   $0xf0106fea
f0101bb4:	68 c6 03 00 00       	push   $0x3c6
f0101bb9:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0101bbe:	e8 7d e4 ff ff       	call   f0100040 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101bc3:	8b 15 8c fe 22 f0    	mov    0xf022fe8c,%edx
f0101bc9:	8b 02                	mov    (%edx),%eax
f0101bcb:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101bd0:	89 c1                	mov    %eax,%ecx
f0101bd2:	c1 e9 0c             	shr    $0xc,%ecx
f0101bd5:	3b 0d 88 fe 22 f0    	cmp    0xf022fe88,%ecx
f0101bdb:	72 15                	jb     f0101bf2 <mem_init+0x90b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101bdd:	50                   	push   %eax
f0101bde:	68 e4 60 10 f0       	push   $0xf01060e4
f0101be3:	68 c9 03 00 00       	push   $0x3c9
f0101be8:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0101bed:	e8 4e e4 ff ff       	call   f0100040 <_panic>
f0101bf2:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101bf7:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101bfa:	83 ec 04             	sub    $0x4,%esp
f0101bfd:	6a 00                	push   $0x0
f0101bff:	68 00 10 00 00       	push   $0x1000
f0101c04:	52                   	push   %edx
f0101c05:	e8 36 f4 ff ff       	call   f0101040 <pgdir_walk>
f0101c0a:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101c0d:	8d 51 04             	lea    0x4(%ecx),%edx
f0101c10:	83 c4 10             	add    $0x10,%esp
f0101c13:	39 d0                	cmp    %edx,%eax
f0101c15:	74 19                	je     f0101c30 <mem_init+0x949>
f0101c17:	68 74 69 10 f0       	push   $0xf0106974
f0101c1c:	68 ea 6f 10 f0       	push   $0xf0106fea
f0101c21:	68 ca 03 00 00       	push   $0x3ca
f0101c26:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0101c2b:	e8 10 e4 ff ff       	call   f0100040 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101c30:	6a 06                	push   $0x6
f0101c32:	68 00 10 00 00       	push   $0x1000
f0101c37:	56                   	push   %esi
f0101c38:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0101c3e:	e8 c9 f5 ff ff       	call   f010120c <page_insert>
f0101c43:	83 c4 10             	add    $0x10,%esp
f0101c46:	85 c0                	test   %eax,%eax
f0101c48:	74 19                	je     f0101c63 <mem_init+0x97c>
f0101c4a:	68 b4 69 10 f0       	push   $0xf01069b4
f0101c4f:	68 ea 6f 10 f0       	push   $0xf0106fea
f0101c54:	68 cd 03 00 00       	push   $0x3cd
f0101c59:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0101c5e:	e8 dd e3 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101c63:	8b 3d 8c fe 22 f0    	mov    0xf022fe8c,%edi
f0101c69:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c6e:	89 f8                	mov    %edi,%eax
f0101c70:	e8 00 ee ff ff       	call   f0100a75 <check_va2pa>
f0101c75:	89 f2                	mov    %esi,%edx
f0101c77:	2b 15 90 fe 22 f0    	sub    0xf022fe90,%edx
f0101c7d:	c1 fa 03             	sar    $0x3,%edx
f0101c80:	c1 e2 0c             	shl    $0xc,%edx
f0101c83:	39 d0                	cmp    %edx,%eax
f0101c85:	74 19                	je     f0101ca0 <mem_init+0x9b9>
f0101c87:	68 44 69 10 f0       	push   $0xf0106944
f0101c8c:	68 ea 6f 10 f0       	push   $0xf0106fea
f0101c91:	68 ce 03 00 00       	push   $0x3ce
f0101c96:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0101c9b:	e8 a0 e3 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101ca0:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101ca5:	74 19                	je     f0101cc0 <mem_init+0x9d9>
f0101ca7:	68 d1 71 10 f0       	push   $0xf01071d1
f0101cac:	68 ea 6f 10 f0       	push   $0xf0106fea
f0101cb1:	68 cf 03 00 00       	push   $0x3cf
f0101cb6:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0101cbb:	e8 80 e3 ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101cc0:	83 ec 04             	sub    $0x4,%esp
f0101cc3:	6a 00                	push   $0x0
f0101cc5:	68 00 10 00 00       	push   $0x1000
f0101cca:	57                   	push   %edi
f0101ccb:	e8 70 f3 ff ff       	call   f0101040 <pgdir_walk>
f0101cd0:	83 c4 10             	add    $0x10,%esp
f0101cd3:	f6 00 04             	testb  $0x4,(%eax)
f0101cd6:	75 19                	jne    f0101cf1 <mem_init+0xa0a>
f0101cd8:	68 f4 69 10 f0       	push   $0xf01069f4
f0101cdd:	68 ea 6f 10 f0       	push   $0xf0106fea
f0101ce2:	68 d0 03 00 00       	push   $0x3d0
f0101ce7:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0101cec:	e8 4f e3 ff ff       	call   f0100040 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101cf1:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
f0101cf6:	f6 00 04             	testb  $0x4,(%eax)
f0101cf9:	75 19                	jne    f0101d14 <mem_init+0xa2d>
f0101cfb:	68 e2 71 10 f0       	push   $0xf01071e2
f0101d00:	68 ea 6f 10 f0       	push   $0xf0106fea
f0101d05:	68 d1 03 00 00       	push   $0x3d1
f0101d0a:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0101d0f:	e8 2c e3 ff ff       	call   f0100040 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101d14:	6a 02                	push   $0x2
f0101d16:	68 00 10 00 00       	push   $0x1000
f0101d1b:	56                   	push   %esi
f0101d1c:	50                   	push   %eax
f0101d1d:	e8 ea f4 ff ff       	call   f010120c <page_insert>
f0101d22:	83 c4 10             	add    $0x10,%esp
f0101d25:	85 c0                	test   %eax,%eax
f0101d27:	74 19                	je     f0101d42 <mem_init+0xa5b>
f0101d29:	68 08 69 10 f0       	push   $0xf0106908
f0101d2e:	68 ea 6f 10 f0       	push   $0xf0106fea
f0101d33:	68 d4 03 00 00       	push   $0x3d4
f0101d38:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0101d3d:	e8 fe e2 ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101d42:	83 ec 04             	sub    $0x4,%esp
f0101d45:	6a 00                	push   $0x0
f0101d47:	68 00 10 00 00       	push   $0x1000
f0101d4c:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0101d52:	e8 e9 f2 ff ff       	call   f0101040 <pgdir_walk>
f0101d57:	83 c4 10             	add    $0x10,%esp
f0101d5a:	f6 00 02             	testb  $0x2,(%eax)
f0101d5d:	75 19                	jne    f0101d78 <mem_init+0xa91>
f0101d5f:	68 28 6a 10 f0       	push   $0xf0106a28
f0101d64:	68 ea 6f 10 f0       	push   $0xf0106fea
f0101d69:	68 d5 03 00 00       	push   $0x3d5
f0101d6e:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0101d73:	e8 c8 e2 ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101d78:	83 ec 04             	sub    $0x4,%esp
f0101d7b:	6a 00                	push   $0x0
f0101d7d:	68 00 10 00 00       	push   $0x1000
f0101d82:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0101d88:	e8 b3 f2 ff ff       	call   f0101040 <pgdir_walk>
f0101d8d:	83 c4 10             	add    $0x10,%esp
f0101d90:	f6 00 04             	testb  $0x4,(%eax)
f0101d93:	74 19                	je     f0101dae <mem_init+0xac7>
f0101d95:	68 5c 6a 10 f0       	push   $0xf0106a5c
f0101d9a:	68 ea 6f 10 f0       	push   $0xf0106fea
f0101d9f:	68 d6 03 00 00       	push   $0x3d6
f0101da4:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0101da9:	e8 92 e2 ff ff       	call   f0100040 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101dae:	6a 02                	push   $0x2
f0101db0:	68 00 00 40 00       	push   $0x400000
f0101db5:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101db8:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0101dbe:	e8 49 f4 ff ff       	call   f010120c <page_insert>
f0101dc3:	83 c4 10             	add    $0x10,%esp
f0101dc6:	85 c0                	test   %eax,%eax
f0101dc8:	78 19                	js     f0101de3 <mem_init+0xafc>
f0101dca:	68 94 6a 10 f0       	push   $0xf0106a94
f0101dcf:	68 ea 6f 10 f0       	push   $0xf0106fea
f0101dd4:	68 d9 03 00 00       	push   $0x3d9
f0101dd9:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0101dde:	e8 5d e2 ff ff       	call   f0100040 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101de3:	6a 02                	push   $0x2
f0101de5:	68 00 10 00 00       	push   $0x1000
f0101dea:	53                   	push   %ebx
f0101deb:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0101df1:	e8 16 f4 ff ff       	call   f010120c <page_insert>
f0101df6:	83 c4 10             	add    $0x10,%esp
f0101df9:	85 c0                	test   %eax,%eax
f0101dfb:	74 19                	je     f0101e16 <mem_init+0xb2f>
f0101dfd:	68 cc 6a 10 f0       	push   $0xf0106acc
f0101e02:	68 ea 6f 10 f0       	push   $0xf0106fea
f0101e07:	68 dc 03 00 00       	push   $0x3dc
f0101e0c:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0101e11:	e8 2a e2 ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101e16:	83 ec 04             	sub    $0x4,%esp
f0101e19:	6a 00                	push   $0x0
f0101e1b:	68 00 10 00 00       	push   $0x1000
f0101e20:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0101e26:	e8 15 f2 ff ff       	call   f0101040 <pgdir_walk>
f0101e2b:	83 c4 10             	add    $0x10,%esp
f0101e2e:	f6 00 04             	testb  $0x4,(%eax)
f0101e31:	74 19                	je     f0101e4c <mem_init+0xb65>
f0101e33:	68 5c 6a 10 f0       	push   $0xf0106a5c
f0101e38:	68 ea 6f 10 f0       	push   $0xf0106fea
f0101e3d:	68 dd 03 00 00       	push   $0x3dd
f0101e42:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0101e47:	e8 f4 e1 ff ff       	call   f0100040 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101e4c:	8b 3d 8c fe 22 f0    	mov    0xf022fe8c,%edi
f0101e52:	ba 00 00 00 00       	mov    $0x0,%edx
f0101e57:	89 f8                	mov    %edi,%eax
f0101e59:	e8 17 ec ff ff       	call   f0100a75 <check_va2pa>
f0101e5e:	89 c1                	mov    %eax,%ecx
f0101e60:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101e63:	89 d8                	mov    %ebx,%eax
f0101e65:	2b 05 90 fe 22 f0    	sub    0xf022fe90,%eax
f0101e6b:	c1 f8 03             	sar    $0x3,%eax
f0101e6e:	c1 e0 0c             	shl    $0xc,%eax
f0101e71:	39 c1                	cmp    %eax,%ecx
f0101e73:	74 19                	je     f0101e8e <mem_init+0xba7>
f0101e75:	68 08 6b 10 f0       	push   $0xf0106b08
f0101e7a:	68 ea 6f 10 f0       	push   $0xf0106fea
f0101e7f:	68 e0 03 00 00       	push   $0x3e0
f0101e84:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0101e89:	e8 b2 e1 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101e8e:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e93:	89 f8                	mov    %edi,%eax
f0101e95:	e8 db eb ff ff       	call   f0100a75 <check_va2pa>
f0101e9a:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101e9d:	74 19                	je     f0101eb8 <mem_init+0xbd1>
f0101e9f:	68 34 6b 10 f0       	push   $0xf0106b34
f0101ea4:	68 ea 6f 10 f0       	push   $0xf0106fea
f0101ea9:	68 e1 03 00 00       	push   $0x3e1
f0101eae:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0101eb3:	e8 88 e1 ff ff       	call   f0100040 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101eb8:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101ebd:	74 19                	je     f0101ed8 <mem_init+0xbf1>
f0101ebf:	68 f8 71 10 f0       	push   $0xf01071f8
f0101ec4:	68 ea 6f 10 f0       	push   $0xf0106fea
f0101ec9:	68 e3 03 00 00       	push   $0x3e3
f0101ece:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0101ed3:	e8 68 e1 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f0101ed8:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101edd:	74 19                	je     f0101ef8 <mem_init+0xc11>
f0101edf:	68 09 72 10 f0       	push   $0xf0107209
f0101ee4:	68 ea 6f 10 f0       	push   $0xf0106fea
f0101ee9:	68 e4 03 00 00       	push   $0x3e4
f0101eee:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0101ef3:	e8 48 e1 ff ff       	call   f0100040 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101ef8:	83 ec 0c             	sub    $0xc,%esp
f0101efb:	6a 00                	push   $0x0
f0101efd:	e8 65 f0 ff ff       	call   f0100f67 <page_alloc>
f0101f02:	83 c4 10             	add    $0x10,%esp
f0101f05:	39 c6                	cmp    %eax,%esi
f0101f07:	75 04                	jne    f0101f0d <mem_init+0xc26>
f0101f09:	85 c0                	test   %eax,%eax
f0101f0b:	75 19                	jne    f0101f26 <mem_init+0xc3f>
f0101f0d:	68 64 6b 10 f0       	push   $0xf0106b64
f0101f12:	68 ea 6f 10 f0       	push   $0xf0106fea
f0101f17:	68 e7 03 00 00       	push   $0x3e7
f0101f1c:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0101f21:	e8 1a e1 ff ff       	call   f0100040 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101f26:	83 ec 08             	sub    $0x8,%esp
f0101f29:	6a 00                	push   $0x0
f0101f2b:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0101f31:	e8 90 f2 ff ff       	call   f01011c6 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101f36:	8b 3d 8c fe 22 f0    	mov    0xf022fe8c,%edi
f0101f3c:	ba 00 00 00 00       	mov    $0x0,%edx
f0101f41:	89 f8                	mov    %edi,%eax
f0101f43:	e8 2d eb ff ff       	call   f0100a75 <check_va2pa>
f0101f48:	83 c4 10             	add    $0x10,%esp
f0101f4b:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101f4e:	74 19                	je     f0101f69 <mem_init+0xc82>
f0101f50:	68 88 6b 10 f0       	push   $0xf0106b88
f0101f55:	68 ea 6f 10 f0       	push   $0xf0106fea
f0101f5a:	68 eb 03 00 00       	push   $0x3eb
f0101f5f:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0101f64:	e8 d7 e0 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101f69:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101f6e:	89 f8                	mov    %edi,%eax
f0101f70:	e8 00 eb ff ff       	call   f0100a75 <check_va2pa>
f0101f75:	89 da                	mov    %ebx,%edx
f0101f77:	2b 15 90 fe 22 f0    	sub    0xf022fe90,%edx
f0101f7d:	c1 fa 03             	sar    $0x3,%edx
f0101f80:	c1 e2 0c             	shl    $0xc,%edx
f0101f83:	39 d0                	cmp    %edx,%eax
f0101f85:	74 19                	je     f0101fa0 <mem_init+0xcb9>
f0101f87:	68 34 6b 10 f0       	push   $0xf0106b34
f0101f8c:	68 ea 6f 10 f0       	push   $0xf0106fea
f0101f91:	68 ec 03 00 00       	push   $0x3ec
f0101f96:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0101f9b:	e8 a0 e0 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f0101fa0:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101fa5:	74 19                	je     f0101fc0 <mem_init+0xcd9>
f0101fa7:	68 af 71 10 f0       	push   $0xf01071af
f0101fac:	68 ea 6f 10 f0       	push   $0xf0106fea
f0101fb1:	68 ed 03 00 00       	push   $0x3ed
f0101fb6:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0101fbb:	e8 80 e0 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f0101fc0:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101fc5:	74 19                	je     f0101fe0 <mem_init+0xcf9>
f0101fc7:	68 09 72 10 f0       	push   $0xf0107209
f0101fcc:	68 ea 6f 10 f0       	push   $0xf0106fea
f0101fd1:	68 ee 03 00 00       	push   $0x3ee
f0101fd6:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0101fdb:	e8 60 e0 ff ff       	call   f0100040 <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101fe0:	6a 00                	push   $0x0
f0101fe2:	68 00 10 00 00       	push   $0x1000
f0101fe7:	53                   	push   %ebx
f0101fe8:	57                   	push   %edi
f0101fe9:	e8 1e f2 ff ff       	call   f010120c <page_insert>
f0101fee:	83 c4 10             	add    $0x10,%esp
f0101ff1:	85 c0                	test   %eax,%eax
f0101ff3:	74 19                	je     f010200e <mem_init+0xd27>
f0101ff5:	68 ac 6b 10 f0       	push   $0xf0106bac
f0101ffa:	68 ea 6f 10 f0       	push   $0xf0106fea
f0101fff:	68 f1 03 00 00       	push   $0x3f1
f0102004:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0102009:	e8 32 e0 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref);
f010200e:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102013:	75 19                	jne    f010202e <mem_init+0xd47>
f0102015:	68 1a 72 10 f0       	push   $0xf010721a
f010201a:	68 ea 6f 10 f0       	push   $0xf0106fea
f010201f:	68 f2 03 00 00       	push   $0x3f2
f0102024:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0102029:	e8 12 e0 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_link == NULL);
f010202e:	83 3b 00             	cmpl   $0x0,(%ebx)
f0102031:	74 19                	je     f010204c <mem_init+0xd65>
f0102033:	68 26 72 10 f0       	push   $0xf0107226
f0102038:	68 ea 6f 10 f0       	push   $0xf0106fea
f010203d:	68 f3 03 00 00       	push   $0x3f3
f0102042:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0102047:	e8 f4 df ff ff       	call   f0100040 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f010204c:	83 ec 08             	sub    $0x8,%esp
f010204f:	68 00 10 00 00       	push   $0x1000
f0102054:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f010205a:	e8 67 f1 ff ff       	call   f01011c6 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f010205f:	8b 3d 8c fe 22 f0    	mov    0xf022fe8c,%edi
f0102065:	ba 00 00 00 00       	mov    $0x0,%edx
f010206a:	89 f8                	mov    %edi,%eax
f010206c:	e8 04 ea ff ff       	call   f0100a75 <check_va2pa>
f0102071:	83 c4 10             	add    $0x10,%esp
f0102074:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102077:	74 19                	je     f0102092 <mem_init+0xdab>
f0102079:	68 88 6b 10 f0       	push   $0xf0106b88
f010207e:	68 ea 6f 10 f0       	push   $0xf0106fea
f0102083:	68 f7 03 00 00       	push   $0x3f7
f0102088:	68 b5 6f 10 f0       	push   $0xf0106fb5
f010208d:	e8 ae df ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0102092:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102097:	89 f8                	mov    %edi,%eax
f0102099:	e8 d7 e9 ff ff       	call   f0100a75 <check_va2pa>
f010209e:	83 f8 ff             	cmp    $0xffffffff,%eax
f01020a1:	74 19                	je     f01020bc <mem_init+0xdd5>
f01020a3:	68 e4 6b 10 f0       	push   $0xf0106be4
f01020a8:	68 ea 6f 10 f0       	push   $0xf0106fea
f01020ad:	68 f8 03 00 00       	push   $0x3f8
f01020b2:	68 b5 6f 10 f0       	push   $0xf0106fb5
f01020b7:	e8 84 df ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f01020bc:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f01020c1:	74 19                	je     f01020dc <mem_init+0xdf5>
f01020c3:	68 3b 72 10 f0       	push   $0xf010723b
f01020c8:	68 ea 6f 10 f0       	push   $0xf0106fea
f01020cd:	68 f9 03 00 00       	push   $0x3f9
f01020d2:	68 b5 6f 10 f0       	push   $0xf0106fb5
f01020d7:	e8 64 df ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f01020dc:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01020e1:	74 19                	je     f01020fc <mem_init+0xe15>
f01020e3:	68 09 72 10 f0       	push   $0xf0107209
f01020e8:	68 ea 6f 10 f0       	push   $0xf0106fea
f01020ed:	68 fa 03 00 00       	push   $0x3fa
f01020f2:	68 b5 6f 10 f0       	push   $0xf0106fb5
f01020f7:	e8 44 df ff ff       	call   f0100040 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f01020fc:	83 ec 0c             	sub    $0xc,%esp
f01020ff:	6a 00                	push   $0x0
f0102101:	e8 61 ee ff ff       	call   f0100f67 <page_alloc>
f0102106:	83 c4 10             	add    $0x10,%esp
f0102109:	85 c0                	test   %eax,%eax
f010210b:	74 04                	je     f0102111 <mem_init+0xe2a>
f010210d:	39 c3                	cmp    %eax,%ebx
f010210f:	74 19                	je     f010212a <mem_init+0xe43>
f0102111:	68 0c 6c 10 f0       	push   $0xf0106c0c
f0102116:	68 ea 6f 10 f0       	push   $0xf0106fea
f010211b:	68 fd 03 00 00       	push   $0x3fd
f0102120:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0102125:	e8 16 df ff ff       	call   f0100040 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f010212a:	83 ec 0c             	sub    $0xc,%esp
f010212d:	6a 00                	push   $0x0
f010212f:	e8 33 ee ff ff       	call   f0100f67 <page_alloc>
f0102134:	83 c4 10             	add    $0x10,%esp
f0102137:	85 c0                	test   %eax,%eax
f0102139:	74 19                	je     f0102154 <mem_init+0xe6d>
f010213b:	68 5d 71 10 f0       	push   $0xf010715d
f0102140:	68 ea 6f 10 f0       	push   $0xf0106fea
f0102145:	68 00 04 00 00       	push   $0x400
f010214a:	68 b5 6f 10 f0       	push   $0xf0106fb5
f010214f:	e8 ec de ff ff       	call   f0100040 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102154:	8b 0d 8c fe 22 f0    	mov    0xf022fe8c,%ecx
f010215a:	8b 11                	mov    (%ecx),%edx
f010215c:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102162:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102165:	2b 05 90 fe 22 f0    	sub    0xf022fe90,%eax
f010216b:	c1 f8 03             	sar    $0x3,%eax
f010216e:	c1 e0 0c             	shl    $0xc,%eax
f0102171:	39 c2                	cmp    %eax,%edx
f0102173:	74 19                	je     f010218e <mem_init+0xea7>
f0102175:	68 b0 68 10 f0       	push   $0xf01068b0
f010217a:	68 ea 6f 10 f0       	push   $0xf0106fea
f010217f:	68 03 04 00 00       	push   $0x403
f0102184:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0102189:	e8 b2 de ff ff       	call   f0100040 <_panic>
	kern_pgdir[0] = 0;
f010218e:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102194:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102197:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f010219c:	74 19                	je     f01021b7 <mem_init+0xed0>
f010219e:	68 c0 71 10 f0       	push   $0xf01071c0
f01021a3:	68 ea 6f 10 f0       	push   $0xf0106fea
f01021a8:	68 05 04 00 00       	push   $0x405
f01021ad:	68 b5 6f 10 f0       	push   $0xf0106fb5
f01021b2:	e8 89 de ff ff       	call   f0100040 <_panic>
	pp0->pp_ref = 0;
f01021b7:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01021ba:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f01021c0:	83 ec 0c             	sub    $0xc,%esp
f01021c3:	50                   	push   %eax
f01021c4:	e8 15 ee ff ff       	call   f0100fde <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f01021c9:	83 c4 0c             	add    $0xc,%esp
f01021cc:	6a 01                	push   $0x1
f01021ce:	68 00 10 40 00       	push   $0x401000
f01021d3:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f01021d9:	e8 62 ee ff ff       	call   f0101040 <pgdir_walk>
f01021de:	89 c7                	mov    %eax,%edi
f01021e0:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f01021e3:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
f01021e8:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01021eb:	8b 40 04             	mov    0x4(%eax),%eax
f01021ee:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01021f3:	8b 0d 88 fe 22 f0    	mov    0xf022fe88,%ecx
f01021f9:	89 c2                	mov    %eax,%edx
f01021fb:	c1 ea 0c             	shr    $0xc,%edx
f01021fe:	83 c4 10             	add    $0x10,%esp
f0102201:	39 ca                	cmp    %ecx,%edx
f0102203:	72 15                	jb     f010221a <mem_init+0xf33>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102205:	50                   	push   %eax
f0102206:	68 e4 60 10 f0       	push   $0xf01060e4
f010220b:	68 0c 04 00 00       	push   $0x40c
f0102210:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0102215:	e8 26 de ff ff       	call   f0100040 <_panic>
	assert(ptep == ptep1 + PTX(va));
f010221a:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f010221f:	39 c7                	cmp    %eax,%edi
f0102221:	74 19                	je     f010223c <mem_init+0xf55>
f0102223:	68 4c 72 10 f0       	push   $0xf010724c
f0102228:	68 ea 6f 10 f0       	push   $0xf0106fea
f010222d:	68 0d 04 00 00       	push   $0x40d
f0102232:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0102237:	e8 04 de ff ff       	call   f0100040 <_panic>
	kern_pgdir[PDX(va)] = 0;
f010223c:	8b 45 cc             	mov    -0x34(%ebp),%eax
f010223f:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f0102246:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102249:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010224f:	2b 05 90 fe 22 f0    	sub    0xf022fe90,%eax
f0102255:	c1 f8 03             	sar    $0x3,%eax
f0102258:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010225b:	89 c2                	mov    %eax,%edx
f010225d:	c1 ea 0c             	shr    $0xc,%edx
f0102260:	39 d1                	cmp    %edx,%ecx
f0102262:	77 12                	ja     f0102276 <mem_init+0xf8f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102264:	50                   	push   %eax
f0102265:	68 e4 60 10 f0       	push   $0xf01060e4
f010226a:	6a 58                	push   $0x58
f010226c:	68 d0 6f 10 f0       	push   $0xf0106fd0
f0102271:	e8 ca dd ff ff       	call   f0100040 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0102276:	83 ec 04             	sub    $0x4,%esp
f0102279:	68 00 10 00 00       	push   $0x1000
f010227e:	68 ff 00 00 00       	push   $0xff
f0102283:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102288:	50                   	push   %eax
f0102289:	e8 76 31 00 00       	call   f0105404 <memset>
	page_free(pp0);
f010228e:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102291:	89 3c 24             	mov    %edi,(%esp)
f0102294:	e8 45 ed ff ff       	call   f0100fde <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0102299:	83 c4 0c             	add    $0xc,%esp
f010229c:	6a 01                	push   $0x1
f010229e:	6a 00                	push   $0x0
f01022a0:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f01022a6:	e8 95 ed ff ff       	call   f0101040 <pgdir_walk>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01022ab:	89 fa                	mov    %edi,%edx
f01022ad:	2b 15 90 fe 22 f0    	sub    0xf022fe90,%edx
f01022b3:	c1 fa 03             	sar    $0x3,%edx
f01022b6:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01022b9:	89 d0                	mov    %edx,%eax
f01022bb:	c1 e8 0c             	shr    $0xc,%eax
f01022be:	83 c4 10             	add    $0x10,%esp
f01022c1:	3b 05 88 fe 22 f0    	cmp    0xf022fe88,%eax
f01022c7:	72 12                	jb     f01022db <mem_init+0xff4>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01022c9:	52                   	push   %edx
f01022ca:	68 e4 60 10 f0       	push   $0xf01060e4
f01022cf:	6a 58                	push   $0x58
f01022d1:	68 d0 6f 10 f0       	push   $0xf0106fd0
f01022d6:	e8 65 dd ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f01022db:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f01022e1:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01022e4:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f01022ea:	f6 00 01             	testb  $0x1,(%eax)
f01022ed:	74 19                	je     f0102308 <mem_init+0x1021>
f01022ef:	68 64 72 10 f0       	push   $0xf0107264
f01022f4:	68 ea 6f 10 f0       	push   $0xf0106fea
f01022f9:	68 17 04 00 00       	push   $0x417
f01022fe:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0102303:	e8 38 dd ff ff       	call   f0100040 <_panic>
f0102308:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f010230b:	39 d0                	cmp    %edx,%eax
f010230d:	75 db                	jne    f01022ea <mem_init+0x1003>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f010230f:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
f0102314:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f010231a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010231d:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f0102323:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0102326:	89 0d 40 f2 22 f0    	mov    %ecx,0xf022f240

	// free the pages we took
	page_free(pp0);
f010232c:	83 ec 0c             	sub    $0xc,%esp
f010232f:	50                   	push   %eax
f0102330:	e8 a9 ec ff ff       	call   f0100fde <page_free>
	page_free(pp1);
f0102335:	89 1c 24             	mov    %ebx,(%esp)
f0102338:	e8 a1 ec ff ff       	call   f0100fde <page_free>
	page_free(pp2);
f010233d:	89 34 24             	mov    %esi,(%esp)
f0102340:	e8 99 ec ff ff       	call   f0100fde <page_free>

	// test mmio_map_region
	mm1 = (uintptr_t) mmio_map_region(0, 4097);
f0102345:	83 c4 08             	add    $0x8,%esp
f0102348:	68 01 10 00 00       	push   $0x1001
f010234d:	6a 00                	push   $0x0
f010234f:	e8 30 ef ff ff       	call   f0101284 <mmio_map_region>
f0102354:	89 c3                	mov    %eax,%ebx
	mm2 = (uintptr_t) mmio_map_region(0, 4096);
f0102356:	83 c4 08             	add    $0x8,%esp
f0102359:	68 00 10 00 00       	push   $0x1000
f010235e:	6a 00                	push   $0x0
f0102360:	e8 1f ef ff ff       	call   f0101284 <mmio_map_region>
f0102365:	89 c6                	mov    %eax,%esi
	// check that they're in the right region
	assert(mm1 >= MMIOBASE && mm1 + 8096 < MMIOLIM);
f0102367:	8d 83 a0 1f 00 00    	lea    0x1fa0(%ebx),%eax
f010236d:	83 c4 10             	add    $0x10,%esp
f0102370:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f0102376:	76 07                	jbe    f010237f <mem_init+0x1098>
f0102378:	3d ff ff bf ef       	cmp    $0xefbfffff,%eax
f010237d:	76 19                	jbe    f0102398 <mem_init+0x10b1>
f010237f:	68 30 6c 10 f0       	push   $0xf0106c30
f0102384:	68 ea 6f 10 f0       	push   $0xf0106fea
f0102389:	68 27 04 00 00       	push   $0x427
f010238e:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0102393:	e8 a8 dc ff ff       	call   f0100040 <_panic>
	assert(mm2 >= MMIOBASE && mm2 + 8096 < MMIOLIM);
f0102398:	8d 96 a0 1f 00 00    	lea    0x1fa0(%esi),%edx
f010239e:	81 fa ff ff bf ef    	cmp    $0xefbfffff,%edx
f01023a4:	77 08                	ja     f01023ae <mem_init+0x10c7>
f01023a6:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f01023ac:	77 19                	ja     f01023c7 <mem_init+0x10e0>
f01023ae:	68 58 6c 10 f0       	push   $0xf0106c58
f01023b3:	68 ea 6f 10 f0       	push   $0xf0106fea
f01023b8:	68 28 04 00 00       	push   $0x428
f01023bd:	68 b5 6f 10 f0       	push   $0xf0106fb5
f01023c2:	e8 79 dc ff ff       	call   f0100040 <_panic>
	// check that they're page-aligned
	assert(mm1 % PGSIZE == 0 && mm2 % PGSIZE == 0);
f01023c7:	89 da                	mov    %ebx,%edx
f01023c9:	09 f2                	or     %esi,%edx
f01023cb:	f7 c2 ff 0f 00 00    	test   $0xfff,%edx
f01023d1:	74 19                	je     f01023ec <mem_init+0x1105>
f01023d3:	68 80 6c 10 f0       	push   $0xf0106c80
f01023d8:	68 ea 6f 10 f0       	push   $0xf0106fea
f01023dd:	68 2a 04 00 00       	push   $0x42a
f01023e2:	68 b5 6f 10 f0       	push   $0xf0106fb5
f01023e7:	e8 54 dc ff ff       	call   f0100040 <_panic>
	// check that they don't overlap
	assert(mm1 + 8096 <= mm2);
f01023ec:	39 c6                	cmp    %eax,%esi
f01023ee:	73 19                	jae    f0102409 <mem_init+0x1122>
f01023f0:	68 7b 72 10 f0       	push   $0xf010727b
f01023f5:	68 ea 6f 10 f0       	push   $0xf0106fea
f01023fa:	68 2c 04 00 00       	push   $0x42c
f01023ff:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0102404:	e8 37 dc ff ff       	call   f0100040 <_panic>
	// check page mappings
	assert(check_va2pa(kern_pgdir, mm1) == 0);
f0102409:	8b 3d 8c fe 22 f0    	mov    0xf022fe8c,%edi
f010240f:	89 da                	mov    %ebx,%edx
f0102411:	89 f8                	mov    %edi,%eax
f0102413:	e8 5d e6 ff ff       	call   f0100a75 <check_va2pa>
f0102418:	85 c0                	test   %eax,%eax
f010241a:	74 19                	je     f0102435 <mem_init+0x114e>
f010241c:	68 a8 6c 10 f0       	push   $0xf0106ca8
f0102421:	68 ea 6f 10 f0       	push   $0xf0106fea
f0102426:	68 2e 04 00 00       	push   $0x42e
f010242b:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0102430:	e8 0b dc ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm1+PGSIZE) == PGSIZE);
f0102435:	8d 83 00 10 00 00    	lea    0x1000(%ebx),%eax
f010243b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010243e:	89 c2                	mov    %eax,%edx
f0102440:	89 f8                	mov    %edi,%eax
f0102442:	e8 2e e6 ff ff       	call   f0100a75 <check_va2pa>
f0102447:	3d 00 10 00 00       	cmp    $0x1000,%eax
f010244c:	74 19                	je     f0102467 <mem_init+0x1180>
f010244e:	68 cc 6c 10 f0       	push   $0xf0106ccc
f0102453:	68 ea 6f 10 f0       	push   $0xf0106fea
f0102458:	68 2f 04 00 00       	push   $0x42f
f010245d:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0102462:	e8 d9 db ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm2) == 0);
f0102467:	89 f2                	mov    %esi,%edx
f0102469:	89 f8                	mov    %edi,%eax
f010246b:	e8 05 e6 ff ff       	call   f0100a75 <check_va2pa>
f0102470:	85 c0                	test   %eax,%eax
f0102472:	74 19                	je     f010248d <mem_init+0x11a6>
f0102474:	68 fc 6c 10 f0       	push   $0xf0106cfc
f0102479:	68 ea 6f 10 f0       	push   $0xf0106fea
f010247e:	68 30 04 00 00       	push   $0x430
f0102483:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0102488:	e8 b3 db ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm2+PGSIZE) == ~0);
f010248d:	8d 96 00 10 00 00    	lea    0x1000(%esi),%edx
f0102493:	89 f8                	mov    %edi,%eax
f0102495:	e8 db e5 ff ff       	call   f0100a75 <check_va2pa>
f010249a:	83 f8 ff             	cmp    $0xffffffff,%eax
f010249d:	74 19                	je     f01024b8 <mem_init+0x11d1>
f010249f:	68 20 6d 10 f0       	push   $0xf0106d20
f01024a4:	68 ea 6f 10 f0       	push   $0xf0106fea
f01024a9:	68 31 04 00 00       	push   $0x431
f01024ae:	68 b5 6f 10 f0       	push   $0xf0106fb5
f01024b3:	e8 88 db ff ff       	call   f0100040 <_panic>
	// check permissions
	assert(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & (PTE_W|PTE_PWT|PTE_PCD));
f01024b8:	83 ec 04             	sub    $0x4,%esp
f01024bb:	6a 00                	push   $0x0
f01024bd:	53                   	push   %ebx
f01024be:	57                   	push   %edi
f01024bf:	e8 7c eb ff ff       	call   f0101040 <pgdir_walk>
f01024c4:	83 c4 10             	add    $0x10,%esp
f01024c7:	f6 00 1a             	testb  $0x1a,(%eax)
f01024ca:	75 19                	jne    f01024e5 <mem_init+0x11fe>
f01024cc:	68 4c 6d 10 f0       	push   $0xf0106d4c
f01024d1:	68 ea 6f 10 f0       	push   $0xf0106fea
f01024d6:	68 33 04 00 00       	push   $0x433
f01024db:	68 b5 6f 10 f0       	push   $0xf0106fb5
f01024e0:	e8 5b db ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & PTE_U));
f01024e5:	83 ec 04             	sub    $0x4,%esp
f01024e8:	6a 00                	push   $0x0
f01024ea:	53                   	push   %ebx
f01024eb:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f01024f1:	e8 4a eb ff ff       	call   f0101040 <pgdir_walk>
f01024f6:	8b 00                	mov    (%eax),%eax
f01024f8:	83 c4 10             	add    $0x10,%esp
f01024fb:	83 e0 04             	and    $0x4,%eax
f01024fe:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0102501:	74 19                	je     f010251c <mem_init+0x1235>
f0102503:	68 90 6d 10 f0       	push   $0xf0106d90
f0102508:	68 ea 6f 10 f0       	push   $0xf0106fea
f010250d:	68 34 04 00 00       	push   $0x434
f0102512:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0102517:	e8 24 db ff ff       	call   f0100040 <_panic>
	// clear the mappings
	*pgdir_walk(kern_pgdir, (void*) mm1, 0) = 0;
f010251c:	83 ec 04             	sub    $0x4,%esp
f010251f:	6a 00                	push   $0x0
f0102521:	53                   	push   %ebx
f0102522:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0102528:	e8 13 eb ff ff       	call   f0101040 <pgdir_walk>
f010252d:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm1 + PGSIZE, 0) = 0;
f0102533:	83 c4 0c             	add    $0xc,%esp
f0102536:	6a 00                	push   $0x0
f0102538:	ff 75 d4             	pushl  -0x2c(%ebp)
f010253b:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0102541:	e8 fa ea ff ff       	call   f0101040 <pgdir_walk>
f0102546:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm2, 0) = 0;
f010254c:	83 c4 0c             	add    $0xc,%esp
f010254f:	6a 00                	push   $0x0
f0102551:	56                   	push   %esi
f0102552:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0102558:	e8 e3 ea ff ff       	call   f0101040 <pgdir_walk>
f010255d:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

	cprintf("check_page() succeeded!\n");
f0102563:	c7 04 24 8d 72 10 f0 	movl   $0xf010728d,(%esp)
f010256a:	e8 ef 10 00 00       	call   f010365e <cprintf>
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	
	boot_map_region(kern_pgdir, UPAGES, PTSIZE, PADDR(pages), PTE_U);
f010256f:	a1 90 fe 22 f0       	mov    0xf022fe90,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102574:	83 c4 10             	add    $0x10,%esp
f0102577:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010257c:	77 15                	ja     f0102593 <mem_init+0x12ac>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010257e:	50                   	push   %eax
f010257f:	68 08 61 10 f0       	push   $0xf0106108
f0102584:	68 be 00 00 00       	push   $0xbe
f0102589:	68 b5 6f 10 f0       	push   $0xf0106fb5
f010258e:	e8 ad da ff ff       	call   f0100040 <_panic>
f0102593:	83 ec 08             	sub    $0x8,%esp
f0102596:	6a 04                	push   $0x4
f0102598:	05 00 00 00 10       	add    $0x10000000,%eax
f010259d:	50                   	push   %eax
f010259e:	b9 00 00 40 00       	mov    $0x400000,%ecx
f01025a3:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f01025a8:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
f01025ad:	e8 23 eb ff ff       	call   f01010d5 <boot_map_region>
	// (ie. perm = PTE_U | PTE_P).
	// Permissions:
	//    - the new image at UENVS  -- kernel R, user R
	//    - envs itself -- kernel RW, user NONE
	// LAB 3: Your code here.
	boot_map_region(kern_pgdir, UENVS, PTSIZE, PADDR(envs), PTE_U);
f01025b2:	a1 44 f2 22 f0       	mov    0xf022f244,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01025b7:	83 c4 10             	add    $0x10,%esp
f01025ba:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01025bf:	77 15                	ja     f01025d6 <mem_init+0x12ef>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01025c1:	50                   	push   %eax
f01025c2:	68 08 61 10 f0       	push   $0xf0106108
f01025c7:	68 c7 00 00 00       	push   $0xc7
f01025cc:	68 b5 6f 10 f0       	push   $0xf0106fb5
f01025d1:	e8 6a da ff ff       	call   f0100040 <_panic>
f01025d6:	83 ec 08             	sub    $0x8,%esp
f01025d9:	6a 04                	push   $0x4
f01025db:	05 00 00 00 10       	add    $0x10000000,%eax
f01025e0:	50                   	push   %eax
f01025e1:	b9 00 00 40 00       	mov    $0x400000,%ecx
f01025e6:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f01025eb:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
f01025f0:	e8 e0 ea ff ff       	call   f01010d5 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01025f5:	83 c4 10             	add    $0x10,%esp
f01025f8:	b8 00 60 11 f0       	mov    $0xf0116000,%eax
f01025fd:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102602:	77 15                	ja     f0102619 <mem_init+0x1332>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102604:	50                   	push   %eax
f0102605:	68 08 61 10 f0       	push   $0xf0106108
f010260a:	68 d4 00 00 00       	push   $0xd4
f010260f:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0102614:	e8 27 da ff ff       	call   f0100040 <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KSTACKTOP-KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W);
f0102619:	83 ec 08             	sub    $0x8,%esp
f010261c:	6a 02                	push   $0x2
f010261e:	68 00 60 11 00       	push   $0x116000
f0102623:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102628:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f010262d:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
f0102632:	e8 9e ea ff ff       	call   f01010d5 <boot_map_region>
	//      the PA range [0, 2^32 - KERNBASE)
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
    boot_map_region(kern_pgdir, KERNBASE, 0xffffffff - KERNBASE, 0, PTE_W);
f0102637:	83 c4 08             	add    $0x8,%esp
f010263a:	6a 02                	push   $0x2
f010263c:	6a 00                	push   $0x0
f010263e:	b9 ff ff ff 0f       	mov    $0xfffffff,%ecx
f0102643:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0102648:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
f010264d:	e8 83 ea ff ff       	call   f01010d5 <boot_map_region>
f0102652:	c7 45 c4 00 10 23 f0 	movl   $0xf0231000,-0x3c(%ebp)
f0102659:	83 c4 10             	add    $0x10,%esp
f010265c:	bb 00 10 23 f0       	mov    $0xf0231000,%ebx
f0102661:	be 00 80 ff ef       	mov    $0xefff8000,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102666:	81 fb ff ff ff ef    	cmp    $0xefffffff,%ebx
f010266c:	77 15                	ja     f0102683 <mem_init+0x139c>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010266e:	53                   	push   %ebx
f010266f:	68 08 61 10 f0       	push   $0xf0106108
f0102674:	68 16 01 00 00       	push   $0x116
f0102679:	68 b5 6f 10 f0       	push   $0xf0106fb5
f010267e:	e8 bd d9 ff ff       	call   f0100040 <_panic>
	// LAB 4: Your code here:

    uintptr_t kstacktop_i;
    for(int i = 0; i < NCPU; i++){
        kstacktop_i = KSTACKTOP - i * (KSTKSIZE + KSTKGAP);
        boot_map_region(kern_pgdir, kstacktop_i - KSTKSIZE, KSTKSIZE, PADDR(percpu_kstacks[i]), PTE_W);
f0102683:	83 ec 08             	sub    $0x8,%esp
f0102686:	6a 02                	push   $0x2
f0102688:	8d 83 00 00 00 10    	lea    0x10000000(%ebx),%eax
f010268e:	50                   	push   %eax
f010268f:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102694:	89 f2                	mov    %esi,%edx
f0102696:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
f010269b:	e8 35 ea ff ff       	call   f01010d5 <boot_map_region>
f01026a0:	81 c3 00 80 00 00    	add    $0x8000,%ebx
f01026a6:	81 ee 00 00 01 00    	sub    $0x10000,%esi
	//     Permissions: kernel RW, user NONE
	//
	// LAB 4: Your code here:

    uintptr_t kstacktop_i;
    for(int i = 0; i < NCPU; i++){
f01026ac:	83 c4 10             	add    $0x10,%esp
f01026af:	b8 00 10 27 f0       	mov    $0xf0271000,%eax
f01026b4:	39 d8                	cmp    %ebx,%eax
f01026b6:	75 ae                	jne    f0102666 <mem_init+0x137f>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f01026b8:	8b 3d 8c fe 22 f0    	mov    0xf022fe8c,%edi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f01026be:	a1 88 fe 22 f0       	mov    0xf022fe88,%eax
f01026c3:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01026c6:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f01026cd:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01026d2:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01026d5:	8b 35 90 fe 22 f0    	mov    0xf022fe90,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01026db:	89 75 d0             	mov    %esi,-0x30(%ebp)

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01026de:	bb 00 00 00 00       	mov    $0x0,%ebx
f01026e3:	eb 55                	jmp    f010273a <mem_init+0x1453>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01026e5:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
f01026eb:	89 f8                	mov    %edi,%eax
f01026ed:	e8 83 e3 ff ff       	call   f0100a75 <check_va2pa>
f01026f2:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f01026f9:	77 15                	ja     f0102710 <mem_init+0x1429>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01026fb:	56                   	push   %esi
f01026fc:	68 08 61 10 f0       	push   $0xf0106108
f0102701:	68 4c 03 00 00       	push   $0x34c
f0102706:	68 b5 6f 10 f0       	push   $0xf0106fb5
f010270b:	e8 30 d9 ff ff       	call   f0100040 <_panic>
f0102710:	8d 94 1e 00 00 00 10 	lea    0x10000000(%esi,%ebx,1),%edx
f0102717:	39 c2                	cmp    %eax,%edx
f0102719:	74 19                	je     f0102734 <mem_init+0x144d>
f010271b:	68 c4 6d 10 f0       	push   $0xf0106dc4
f0102720:	68 ea 6f 10 f0       	push   $0xf0106fea
f0102725:	68 4c 03 00 00       	push   $0x34c
f010272a:	68 b5 6f 10 f0       	push   $0xf0106fb5
f010272f:	e8 0c d9 ff ff       	call   f0100040 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102734:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f010273a:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f010273d:	77 a6                	ja     f01026e5 <mem_init+0x13fe>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f010273f:	8b 35 44 f2 22 f0    	mov    0xf022f244,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102745:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f0102748:	bb 00 00 c0 ee       	mov    $0xeec00000,%ebx
f010274d:	89 da                	mov    %ebx,%edx
f010274f:	89 f8                	mov    %edi,%eax
f0102751:	e8 1f e3 ff ff       	call   f0100a75 <check_va2pa>
f0102756:	81 7d d4 ff ff ff ef 	cmpl   $0xefffffff,-0x2c(%ebp)
f010275d:	77 15                	ja     f0102774 <mem_init+0x148d>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010275f:	56                   	push   %esi
f0102760:	68 08 61 10 f0       	push   $0xf0106108
f0102765:	68 51 03 00 00       	push   $0x351
f010276a:	68 b5 6f 10 f0       	push   $0xf0106fb5
f010276f:	e8 cc d8 ff ff       	call   f0100040 <_panic>
f0102774:	8d 94 1e 00 00 40 21 	lea    0x21400000(%esi,%ebx,1),%edx
f010277b:	39 d0                	cmp    %edx,%eax
f010277d:	74 19                	je     f0102798 <mem_init+0x14b1>
f010277f:	68 f8 6d 10 f0       	push   $0xf0106df8
f0102784:	68 ea 6f 10 f0       	push   $0xf0106fea
f0102789:	68 51 03 00 00       	push   $0x351
f010278e:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0102793:	e8 a8 d8 ff ff       	call   f0100040 <_panic>
f0102798:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f010279e:	81 fb 00 f0 c1 ee    	cmp    $0xeec1f000,%ebx
f01027a4:	75 a7                	jne    f010274d <mem_init+0x1466>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01027a6:	8b 75 cc             	mov    -0x34(%ebp),%esi
f01027a9:	c1 e6 0c             	shl    $0xc,%esi
f01027ac:	bb 00 00 00 00       	mov    $0x0,%ebx
f01027b1:	eb 30                	jmp    f01027e3 <mem_init+0x14fc>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f01027b3:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
f01027b9:	89 f8                	mov    %edi,%eax
f01027bb:	e8 b5 e2 ff ff       	call   f0100a75 <check_va2pa>
f01027c0:	39 c3                	cmp    %eax,%ebx
f01027c2:	74 19                	je     f01027dd <mem_init+0x14f6>
f01027c4:	68 2c 6e 10 f0       	push   $0xf0106e2c
f01027c9:	68 ea 6f 10 f0       	push   $0xf0106fea
f01027ce:	68 55 03 00 00       	push   $0x355
f01027d3:	68 b5 6f 10 f0       	push   $0xf0106fb5
f01027d8:	e8 63 d8 ff ff       	call   f0100040 <_panic>
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01027dd:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01027e3:	39 f3                	cmp    %esi,%ebx
f01027e5:	72 cc                	jb     f01027b3 <mem_init+0x14cc>
f01027e7:	be 00 80 ff ef       	mov    $0xefff8000,%esi
f01027ec:	89 75 cc             	mov    %esi,-0x34(%ebp)
f01027ef:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f01027f2:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01027f5:	8d 88 00 80 00 00    	lea    0x8000(%eax),%ecx
f01027fb:	89 4d d0             	mov    %ecx,-0x30(%ebp)
f01027fe:	89 c3                	mov    %eax,%ebx
	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
f0102800:	8b 45 c8             	mov    -0x38(%ebp),%eax
f0102803:	05 00 80 00 20       	add    $0x20008000,%eax
f0102808:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010280b:	89 da                	mov    %ebx,%edx
f010280d:	89 f8                	mov    %edi,%eax
f010280f:	e8 61 e2 ff ff       	call   f0100a75 <check_va2pa>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102814:	81 fe ff ff ff ef    	cmp    $0xefffffff,%esi
f010281a:	77 15                	ja     f0102831 <mem_init+0x154a>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010281c:	56                   	push   %esi
f010281d:	68 08 61 10 f0       	push   $0xf0106108
f0102822:	68 5d 03 00 00       	push   $0x35d
f0102827:	68 b5 6f 10 f0       	push   $0xf0106fb5
f010282c:	e8 0f d8 ff ff       	call   f0100040 <_panic>
f0102831:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0102834:	8d 94 0b 00 10 23 f0 	lea    -0xfdcf000(%ebx,%ecx,1),%edx
f010283b:	39 d0                	cmp    %edx,%eax
f010283d:	74 19                	je     f0102858 <mem_init+0x1571>
f010283f:	68 54 6e 10 f0       	push   $0xf0106e54
f0102844:	68 ea 6f 10 f0       	push   $0xf0106fea
f0102849:	68 5d 03 00 00       	push   $0x35d
f010284e:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0102853:	e8 e8 d7 ff ff       	call   f0100040 <_panic>
f0102858:	81 c3 00 10 00 00    	add    $0x1000,%ebx

	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
f010285e:	3b 5d d0             	cmp    -0x30(%ebp),%ebx
f0102861:	75 a8                	jne    f010280b <mem_init+0x1524>
f0102863:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102866:	8d 98 00 80 ff ff    	lea    -0x8000(%eax),%ebx
f010286c:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f010286f:	89 c6                	mov    %eax,%esi
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
				== PADDR(percpu_kstacks[n]) + i);
		for (i = 0; i < KSTKGAP; i += PGSIZE)
			assert(check_va2pa(pgdir, base + i) == ~0);
f0102871:	89 da                	mov    %ebx,%edx
f0102873:	89 f8                	mov    %edi,%eax
f0102875:	e8 fb e1 ff ff       	call   f0100a75 <check_va2pa>
f010287a:	83 f8 ff             	cmp    $0xffffffff,%eax
f010287d:	74 19                	je     f0102898 <mem_init+0x15b1>
f010287f:	68 9c 6e 10 f0       	push   $0xf0106e9c
f0102884:	68 ea 6f 10 f0       	push   $0xf0106fea
f0102889:	68 5f 03 00 00       	push   $0x35f
f010288e:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0102893:	e8 a8 d7 ff ff       	call   f0100040 <_panic>
f0102898:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
				== PADDR(percpu_kstacks[n]) + i);
		for (i = 0; i < KSTKGAP; i += PGSIZE)
f010289e:	39 f3                	cmp    %esi,%ebx
f01028a0:	75 cf                	jne    f0102871 <mem_init+0x158a>
f01028a2:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f01028a5:	81 6d cc 00 00 01 00 	subl   $0x10000,-0x34(%ebp)
f01028ac:	81 45 c8 00 80 01 00 	addl   $0x18000,-0x38(%ebp)
f01028b3:	81 c6 00 80 00 00    	add    $0x8000,%esi
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
f01028b9:	b8 00 10 27 f0       	mov    $0xf0271000,%eax
f01028be:	39 f0                	cmp    %esi,%eax
f01028c0:	0f 85 2c ff ff ff    	jne    f01027f2 <mem_init+0x150b>
f01028c6:	b8 00 00 00 00       	mov    $0x0,%eax
f01028cb:	eb 2a                	jmp    f01028f7 <mem_init+0x1610>
			assert(check_va2pa(pgdir, base + i) == ~0);
	}

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f01028cd:	8d 90 45 fc ff ff    	lea    -0x3bb(%eax),%edx
f01028d3:	83 fa 04             	cmp    $0x4,%edx
f01028d6:	77 1f                	ja     f01028f7 <mem_init+0x1610>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
		case PDX(UENVS):
		case PDX(MMIOBASE):
			assert(pgdir[i] & PTE_P);
f01028d8:	f6 04 87 01          	testb  $0x1,(%edi,%eax,4)
f01028dc:	75 7e                	jne    f010295c <mem_init+0x1675>
f01028de:	68 a6 72 10 f0       	push   $0xf01072a6
f01028e3:	68 ea 6f 10 f0       	push   $0xf0106fea
f01028e8:	68 6a 03 00 00       	push   $0x36a
f01028ed:	68 b5 6f 10 f0       	push   $0xf0106fb5
f01028f2:	e8 49 d7 ff ff       	call   f0100040 <_panic>
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f01028f7:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f01028fc:	76 3f                	jbe    f010293d <mem_init+0x1656>
				assert(pgdir[i] & PTE_P);
f01028fe:	8b 14 87             	mov    (%edi,%eax,4),%edx
f0102901:	f6 c2 01             	test   $0x1,%dl
f0102904:	75 19                	jne    f010291f <mem_init+0x1638>
f0102906:	68 a6 72 10 f0       	push   $0xf01072a6
f010290b:	68 ea 6f 10 f0       	push   $0xf0106fea
f0102910:	68 6e 03 00 00       	push   $0x36e
f0102915:	68 b5 6f 10 f0       	push   $0xf0106fb5
f010291a:	e8 21 d7 ff ff       	call   f0100040 <_panic>
				assert(pgdir[i] & PTE_W);
f010291f:	f6 c2 02             	test   $0x2,%dl
f0102922:	75 38                	jne    f010295c <mem_init+0x1675>
f0102924:	68 b7 72 10 f0       	push   $0xf01072b7
f0102929:	68 ea 6f 10 f0       	push   $0xf0106fea
f010292e:	68 6f 03 00 00       	push   $0x36f
f0102933:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0102938:	e8 03 d7 ff ff       	call   f0100040 <_panic>
			} else
				assert(pgdir[i] == 0);
f010293d:	83 3c 87 00          	cmpl   $0x0,(%edi,%eax,4)
f0102941:	74 19                	je     f010295c <mem_init+0x1675>
f0102943:	68 c8 72 10 f0       	push   $0xf01072c8
f0102948:	68 ea 6f 10 f0       	push   $0xf0106fea
f010294d:	68 71 03 00 00       	push   $0x371
f0102952:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0102957:	e8 e4 d6 ff ff       	call   f0100040 <_panic>
		for (i = 0; i < KSTKGAP; i += PGSIZE)
			assert(check_va2pa(pgdir, base + i) == ~0);
	}

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f010295c:	83 c0 01             	add    $0x1,%eax
f010295f:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f0102964:	0f 86 63 ff ff ff    	jbe    f01028cd <mem_init+0x15e6>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f010296a:	83 ec 0c             	sub    $0xc,%esp
f010296d:	68 c0 6e 10 f0       	push   $0xf0106ec0
f0102972:	e8 e7 0c 00 00       	call   f010365e <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f0102977:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010297c:	83 c4 10             	add    $0x10,%esp
f010297f:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102984:	77 15                	ja     f010299b <mem_init+0x16b4>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102986:	50                   	push   %eax
f0102987:	68 08 61 10 f0       	push   $0xf0106108
f010298c:	68 ed 00 00 00       	push   $0xed
f0102991:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0102996:	e8 a5 d6 ff ff       	call   f0100040 <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f010299b:	05 00 00 00 10       	add    $0x10000000,%eax
f01029a0:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f01029a3:	b8 00 00 00 00       	mov    $0x0,%eax
f01029a8:	e8 b3 e1 ff ff       	call   f0100b60 <check_page_free_list>

static inline uint32_t
rcr0(void)
{
	uint32_t val;
	asm volatile("movl %%cr0,%0" : "=r" (val));
f01029ad:	0f 20 c0             	mov    %cr0,%eax
f01029b0:	83 e0 f3             	and    $0xfffffff3,%eax
}

static inline void
lcr0(uint32_t val)
{
	asm volatile("movl %0,%%cr0" : : "r" (val));
f01029b3:	0d 23 00 05 80       	or     $0x80050023,%eax
f01029b8:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01029bb:	83 ec 0c             	sub    $0xc,%esp
f01029be:	6a 00                	push   $0x0
f01029c0:	e8 a2 e5 ff ff       	call   f0100f67 <page_alloc>
f01029c5:	89 c3                	mov    %eax,%ebx
f01029c7:	83 c4 10             	add    $0x10,%esp
f01029ca:	85 c0                	test   %eax,%eax
f01029cc:	75 19                	jne    f01029e7 <mem_init+0x1700>
f01029ce:	68 b2 70 10 f0       	push   $0xf01070b2
f01029d3:	68 ea 6f 10 f0       	push   $0xf0106fea
f01029d8:	68 49 04 00 00       	push   $0x449
f01029dd:	68 b5 6f 10 f0       	push   $0xf0106fb5
f01029e2:	e8 59 d6 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f01029e7:	83 ec 0c             	sub    $0xc,%esp
f01029ea:	6a 00                	push   $0x0
f01029ec:	e8 76 e5 ff ff       	call   f0100f67 <page_alloc>
f01029f1:	89 c7                	mov    %eax,%edi
f01029f3:	83 c4 10             	add    $0x10,%esp
f01029f6:	85 c0                	test   %eax,%eax
f01029f8:	75 19                	jne    f0102a13 <mem_init+0x172c>
f01029fa:	68 c8 70 10 f0       	push   $0xf01070c8
f01029ff:	68 ea 6f 10 f0       	push   $0xf0106fea
f0102a04:	68 4a 04 00 00       	push   $0x44a
f0102a09:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0102a0e:	e8 2d d6 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0102a13:	83 ec 0c             	sub    $0xc,%esp
f0102a16:	6a 00                	push   $0x0
f0102a18:	e8 4a e5 ff ff       	call   f0100f67 <page_alloc>
f0102a1d:	89 c6                	mov    %eax,%esi
f0102a1f:	83 c4 10             	add    $0x10,%esp
f0102a22:	85 c0                	test   %eax,%eax
f0102a24:	75 19                	jne    f0102a3f <mem_init+0x1758>
f0102a26:	68 de 70 10 f0       	push   $0xf01070de
f0102a2b:	68 ea 6f 10 f0       	push   $0xf0106fea
f0102a30:	68 4b 04 00 00       	push   $0x44b
f0102a35:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0102a3a:	e8 01 d6 ff ff       	call   f0100040 <_panic>
	page_free(pp0);
f0102a3f:	83 ec 0c             	sub    $0xc,%esp
f0102a42:	53                   	push   %ebx
f0102a43:	e8 96 e5 ff ff       	call   f0100fde <page_free>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102a48:	89 f8                	mov    %edi,%eax
f0102a4a:	2b 05 90 fe 22 f0    	sub    0xf022fe90,%eax
f0102a50:	c1 f8 03             	sar    $0x3,%eax
f0102a53:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102a56:	89 c2                	mov    %eax,%edx
f0102a58:	c1 ea 0c             	shr    $0xc,%edx
f0102a5b:	83 c4 10             	add    $0x10,%esp
f0102a5e:	3b 15 88 fe 22 f0    	cmp    0xf022fe88,%edx
f0102a64:	72 12                	jb     f0102a78 <mem_init+0x1791>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102a66:	50                   	push   %eax
f0102a67:	68 e4 60 10 f0       	push   $0xf01060e4
f0102a6c:	6a 58                	push   $0x58
f0102a6e:	68 d0 6f 10 f0       	push   $0xf0106fd0
f0102a73:	e8 c8 d5 ff ff       	call   f0100040 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f0102a78:	83 ec 04             	sub    $0x4,%esp
f0102a7b:	68 00 10 00 00       	push   $0x1000
f0102a80:	6a 01                	push   $0x1
f0102a82:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102a87:	50                   	push   %eax
f0102a88:	e8 77 29 00 00       	call   f0105404 <memset>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102a8d:	89 f0                	mov    %esi,%eax
f0102a8f:	2b 05 90 fe 22 f0    	sub    0xf022fe90,%eax
f0102a95:	c1 f8 03             	sar    $0x3,%eax
f0102a98:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102a9b:	89 c2                	mov    %eax,%edx
f0102a9d:	c1 ea 0c             	shr    $0xc,%edx
f0102aa0:	83 c4 10             	add    $0x10,%esp
f0102aa3:	3b 15 88 fe 22 f0    	cmp    0xf022fe88,%edx
f0102aa9:	72 12                	jb     f0102abd <mem_init+0x17d6>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102aab:	50                   	push   %eax
f0102aac:	68 e4 60 10 f0       	push   $0xf01060e4
f0102ab1:	6a 58                	push   $0x58
f0102ab3:	68 d0 6f 10 f0       	push   $0xf0106fd0
f0102ab8:	e8 83 d5 ff ff       	call   f0100040 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f0102abd:	83 ec 04             	sub    $0x4,%esp
f0102ac0:	68 00 10 00 00       	push   $0x1000
f0102ac5:	6a 02                	push   $0x2
f0102ac7:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102acc:	50                   	push   %eax
f0102acd:	e8 32 29 00 00       	call   f0105404 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102ad2:	6a 02                	push   $0x2
f0102ad4:	68 00 10 00 00       	push   $0x1000
f0102ad9:	57                   	push   %edi
f0102ada:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0102ae0:	e8 27 e7 ff ff       	call   f010120c <page_insert>
	assert(pp1->pp_ref == 1);
f0102ae5:	83 c4 20             	add    $0x20,%esp
f0102ae8:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102aed:	74 19                	je     f0102b08 <mem_init+0x1821>
f0102aef:	68 af 71 10 f0       	push   $0xf01071af
f0102af4:	68 ea 6f 10 f0       	push   $0xf0106fea
f0102af9:	68 50 04 00 00       	push   $0x450
f0102afe:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0102b03:	e8 38 d5 ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102b08:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102b0f:	01 01 01 
f0102b12:	74 19                	je     f0102b2d <mem_init+0x1846>
f0102b14:	68 e0 6e 10 f0       	push   $0xf0106ee0
f0102b19:	68 ea 6f 10 f0       	push   $0xf0106fea
f0102b1e:	68 51 04 00 00       	push   $0x451
f0102b23:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0102b28:	e8 13 d5 ff ff       	call   f0100040 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102b2d:	6a 02                	push   $0x2
f0102b2f:	68 00 10 00 00       	push   $0x1000
f0102b34:	56                   	push   %esi
f0102b35:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0102b3b:	e8 cc e6 ff ff       	call   f010120c <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102b40:	83 c4 10             	add    $0x10,%esp
f0102b43:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102b4a:	02 02 02 
f0102b4d:	74 19                	je     f0102b68 <mem_init+0x1881>
f0102b4f:	68 04 6f 10 f0       	push   $0xf0106f04
f0102b54:	68 ea 6f 10 f0       	push   $0xf0106fea
f0102b59:	68 53 04 00 00       	push   $0x453
f0102b5e:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0102b63:	e8 d8 d4 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0102b68:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102b6d:	74 19                	je     f0102b88 <mem_init+0x18a1>
f0102b6f:	68 d1 71 10 f0       	push   $0xf01071d1
f0102b74:	68 ea 6f 10 f0       	push   $0xf0106fea
f0102b79:	68 54 04 00 00       	push   $0x454
f0102b7e:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0102b83:	e8 b8 d4 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f0102b88:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102b8d:	74 19                	je     f0102ba8 <mem_init+0x18c1>
f0102b8f:	68 3b 72 10 f0       	push   $0xf010723b
f0102b94:	68 ea 6f 10 f0       	push   $0xf0106fea
f0102b99:	68 55 04 00 00       	push   $0x455
f0102b9e:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0102ba3:	e8 98 d4 ff ff       	call   f0100040 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102ba8:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102baf:	03 03 03 
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102bb2:	89 f0                	mov    %esi,%eax
f0102bb4:	2b 05 90 fe 22 f0    	sub    0xf022fe90,%eax
f0102bba:	c1 f8 03             	sar    $0x3,%eax
f0102bbd:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102bc0:	89 c2                	mov    %eax,%edx
f0102bc2:	c1 ea 0c             	shr    $0xc,%edx
f0102bc5:	3b 15 88 fe 22 f0    	cmp    0xf022fe88,%edx
f0102bcb:	72 12                	jb     f0102bdf <mem_init+0x18f8>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102bcd:	50                   	push   %eax
f0102bce:	68 e4 60 10 f0       	push   $0xf01060e4
f0102bd3:	6a 58                	push   $0x58
f0102bd5:	68 d0 6f 10 f0       	push   $0xf0106fd0
f0102bda:	e8 61 d4 ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102bdf:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102be6:	03 03 03 
f0102be9:	74 19                	je     f0102c04 <mem_init+0x191d>
f0102beb:	68 28 6f 10 f0       	push   $0xf0106f28
f0102bf0:	68 ea 6f 10 f0       	push   $0xf0106fea
f0102bf5:	68 57 04 00 00       	push   $0x457
f0102bfa:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0102bff:	e8 3c d4 ff ff       	call   f0100040 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102c04:	83 ec 08             	sub    $0x8,%esp
f0102c07:	68 00 10 00 00       	push   $0x1000
f0102c0c:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0102c12:	e8 af e5 ff ff       	call   f01011c6 <page_remove>
	assert(pp2->pp_ref == 0);
f0102c17:	83 c4 10             	add    $0x10,%esp
f0102c1a:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102c1f:	74 19                	je     f0102c3a <mem_init+0x1953>
f0102c21:	68 09 72 10 f0       	push   $0xf0107209
f0102c26:	68 ea 6f 10 f0       	push   $0xf0106fea
f0102c2b:	68 59 04 00 00       	push   $0x459
f0102c30:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0102c35:	e8 06 d4 ff ff       	call   f0100040 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102c3a:	8b 0d 8c fe 22 f0    	mov    0xf022fe8c,%ecx
f0102c40:	8b 11                	mov    (%ecx),%edx
f0102c42:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102c48:	89 d8                	mov    %ebx,%eax
f0102c4a:	2b 05 90 fe 22 f0    	sub    0xf022fe90,%eax
f0102c50:	c1 f8 03             	sar    $0x3,%eax
f0102c53:	c1 e0 0c             	shl    $0xc,%eax
f0102c56:	39 c2                	cmp    %eax,%edx
f0102c58:	74 19                	je     f0102c73 <mem_init+0x198c>
f0102c5a:	68 b0 68 10 f0       	push   $0xf01068b0
f0102c5f:	68 ea 6f 10 f0       	push   $0xf0106fea
f0102c64:	68 5c 04 00 00       	push   $0x45c
f0102c69:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0102c6e:	e8 cd d3 ff ff       	call   f0100040 <_panic>
	kern_pgdir[0] = 0;
f0102c73:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102c79:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102c7e:	74 19                	je     f0102c99 <mem_init+0x19b2>
f0102c80:	68 c0 71 10 f0       	push   $0xf01071c0
f0102c85:	68 ea 6f 10 f0       	push   $0xf0106fea
f0102c8a:	68 5e 04 00 00       	push   $0x45e
f0102c8f:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0102c94:	e8 a7 d3 ff ff       	call   f0100040 <_panic>
	pp0->pp_ref = 0;
f0102c99:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f0102c9f:	83 ec 0c             	sub    $0xc,%esp
f0102ca2:	53                   	push   %ebx
f0102ca3:	e8 36 e3 ff ff       	call   f0100fde <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102ca8:	c7 04 24 54 6f 10 f0 	movl   $0xf0106f54,(%esp)
f0102caf:	e8 aa 09 00 00       	call   f010365e <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f0102cb4:	83 c4 10             	add    $0x10,%esp
f0102cb7:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102cba:	5b                   	pop    %ebx
f0102cbb:	5e                   	pop    %esi
f0102cbc:	5f                   	pop    %edi
f0102cbd:	5d                   	pop    %ebp
f0102cbe:	c3                   	ret    

f0102cbf <user_mem_check>:
// Returns 0 if the user program can access this range of addresses,
// and -E_FAULT otherwise.
//
int
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
f0102cbf:	55                   	push   %ebp
f0102cc0:	89 e5                	mov    %esp,%ebp
f0102cc2:	57                   	push   %edi
f0102cc3:	56                   	push   %esi
f0102cc4:	53                   	push   %ebx
f0102cc5:	83 ec 2c             	sub    $0x2c,%esp
f0102cc8:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// LAB 3: Your code here.
	void *vat =(void *) va;
	void *end =(void *)va + len;
f0102ccb:	89 d8                	mov    %ebx,%eax
f0102ccd:	03 45 10             	add    0x10(%ebp),%eax
f0102cd0:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	int p = perm | PTE_P;
f0102cd3:	8b 75 14             	mov    0x14(%ebp),%esi
f0102cd6:	83 ce 01             	or     $0x1,%esi
	for (; vat < end; vat = ROUNDDOWN(vat+PGSIZE, PGSIZE)) {
		if ((uint32_t)vat > ULIM) {
			user_mem_check_addr =(uintptr_t) vat;
			return -E_FAULT;
		}
		page_lookup(env->env_pgdir, vat, &pte);
f0102cd9:	8d 7d e4             	lea    -0x1c(%ebp),%edi
	// LAB 3: Your code here.
	void *vat =(void *) va;
	void *end =(void *)va + len;
	int p = perm | PTE_P;
	pte_t *pte;
	for (; vat < end; vat = ROUNDDOWN(vat+PGSIZE, PGSIZE)) {
f0102cdc:	eb 55                	jmp    f0102d33 <user_mem_check+0x74>
		if ((uint32_t)vat > ULIM) {
f0102cde:	89 5d d0             	mov    %ebx,-0x30(%ebp)
f0102ce1:	81 fb 00 00 80 ef    	cmp    $0xef800000,%ebx
f0102ce7:	76 0d                	jbe    f0102cf6 <user_mem_check+0x37>
			user_mem_check_addr =(uintptr_t) vat;
f0102ce9:	89 1d 3c f2 22 f0    	mov    %ebx,0xf022f23c
			return -E_FAULT;
f0102cef:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0102cf4:	eb 47                	jmp    f0102d3d <user_mem_check+0x7e>
		}
		page_lookup(env->env_pgdir, vat, &pte);
f0102cf6:	83 ec 04             	sub    $0x4,%esp
f0102cf9:	57                   	push   %edi
f0102cfa:	53                   	push   %ebx
f0102cfb:	8b 45 08             	mov    0x8(%ebp),%eax
f0102cfe:	ff 70 60             	pushl  0x60(%eax)
f0102d01:	e8 31 e4 ff ff       	call   f0101137 <page_lookup>
		if (!(pte && ((*pte & p) == p))) {
f0102d06:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102d09:	83 c4 10             	add    $0x10,%esp
f0102d0c:	85 c0                	test   %eax,%eax
f0102d0e:	74 08                	je     f0102d18 <user_mem_check+0x59>
f0102d10:	89 f2                	mov    %esi,%edx
f0102d12:	23 10                	and    (%eax),%edx
f0102d14:	39 d6                	cmp    %edx,%esi
f0102d16:	74 0f                	je     f0102d27 <user_mem_check+0x68>
			user_mem_check_addr = (uintptr_t) vat;
f0102d18:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102d1b:	a3 3c f2 22 f0       	mov    %eax,0xf022f23c
			return -E_FAULT;
f0102d20:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0102d25:	eb 16                	jmp    f0102d3d <user_mem_check+0x7e>
	// LAB 3: Your code here.
	void *vat =(void *) va;
	void *end =(void *)va + len;
	int p = perm | PTE_P;
	pte_t *pte;
	for (; vat < end; vat = ROUNDDOWN(vat+PGSIZE, PGSIZE)) {
f0102d27:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102d2d:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
f0102d33:	3b 5d d4             	cmp    -0x2c(%ebp),%ebx
f0102d36:	72 a6                	jb     f0102cde <user_mem_check+0x1f>
			user_mem_check_addr = (uintptr_t) vat;
			return -E_FAULT;
		}
	}

	return 0;
f0102d38:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102d3d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102d40:	5b                   	pop    %ebx
f0102d41:	5e                   	pop    %esi
f0102d42:	5f                   	pop    %edi
f0102d43:	5d                   	pop    %ebp
f0102d44:	c3                   	ret    

f0102d45 <user_mem_assert>:
// If it cannot, 'env' is destroyed and, if env is the current
// environment, this function will not return.
//
void
user_mem_assert(struct Env *env, const void *va, size_t len, int perm)
{
f0102d45:	55                   	push   %ebp
f0102d46:	89 e5                	mov    %esp,%ebp
f0102d48:	53                   	push   %ebx
f0102d49:	83 ec 04             	sub    $0x4,%esp
f0102d4c:	8b 5d 08             	mov    0x8(%ebp),%ebx
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
f0102d4f:	8b 45 14             	mov    0x14(%ebp),%eax
f0102d52:	83 c8 04             	or     $0x4,%eax
f0102d55:	50                   	push   %eax
f0102d56:	ff 75 10             	pushl  0x10(%ebp)
f0102d59:	ff 75 0c             	pushl  0xc(%ebp)
f0102d5c:	53                   	push   %ebx
f0102d5d:	e8 5d ff ff ff       	call   f0102cbf <user_mem_check>
f0102d62:	83 c4 10             	add    $0x10,%esp
f0102d65:	85 c0                	test   %eax,%eax
f0102d67:	79 21                	jns    f0102d8a <user_mem_assert+0x45>
		cprintf("[%08x] user_mem_check assertion failure for "
f0102d69:	83 ec 04             	sub    $0x4,%esp
f0102d6c:	ff 35 3c f2 22 f0    	pushl  0xf022f23c
f0102d72:	ff 73 48             	pushl  0x48(%ebx)
f0102d75:	68 80 6f 10 f0       	push   $0xf0106f80
f0102d7a:	e8 df 08 00 00       	call   f010365e <cprintf>
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
f0102d7f:	89 1c 24             	mov    %ebx,(%esp)
f0102d82:	e8 02 06 00 00       	call   f0103389 <env_destroy>
f0102d87:	83 c4 10             	add    $0x10,%esp
	}
}
f0102d8a:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102d8d:	c9                   	leave  
f0102d8e:	c3                   	ret    

f0102d8f <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f0102d8f:	55                   	push   %ebp
f0102d90:	89 e5                	mov    %esp,%ebp
f0102d92:	57                   	push   %edi
f0102d93:	56                   	push   %esi
f0102d94:	53                   	push   %ebx
f0102d95:	83 ec 0c             	sub    $0xc,%esp
f0102d98:	89 c7                	mov    %eax,%edi
	//
	// Hint: It is easier to use region_alloc if the caller can pass
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	void *va_t = ROUNDDOWN(va, PGSIZE);
f0102d9a:	89 d3                	mov    %edx,%ebx
f0102d9c:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx

	void *end = ROUNDUP(va + len, PGSIZE);
f0102da2:	8d b4 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%esi
f0102da9:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	for(; va_t < end;va_t += PGSIZE){
f0102daf:	eb 3d                	jmp    f0102dee <region_alloc+0x5f>
		struct PageInfo *pp = page_alloc(1);	
f0102db1:	83 ec 0c             	sub    $0xc,%esp
f0102db4:	6a 01                	push   $0x1
f0102db6:	e8 ac e1 ff ff       	call   f0100f67 <page_alloc>
		if(pp == NULL){
f0102dbb:	83 c4 10             	add    $0x10,%esp
f0102dbe:	85 c0                	test   %eax,%eax
f0102dc0:	75 17                	jne    f0102dd9 <region_alloc+0x4a>
			panic("page alloc failed!\n");	
f0102dc2:	83 ec 04             	sub    $0x4,%esp
f0102dc5:	68 d6 72 10 f0       	push   $0xf01072d6
f0102dca:	68 29 01 00 00       	push   $0x129
f0102dcf:	68 ea 72 10 f0       	push   $0xf01072ea
f0102dd4:	e8 67 d2 ff ff       	call   f0100040 <_panic>
		}
		page_insert(e->env_pgdir, pp, va_t, PTE_U | PTE_W);	
f0102dd9:	6a 06                	push   $0x6
f0102ddb:	53                   	push   %ebx
f0102ddc:	50                   	push   %eax
f0102ddd:	ff 77 60             	pushl  0x60(%edi)
f0102de0:	e8 27 e4 ff ff       	call   f010120c <page_insert>
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	void *va_t = ROUNDDOWN(va, PGSIZE);

	void *end = ROUNDUP(va + len, PGSIZE);
	for(; va_t < end;va_t += PGSIZE){
f0102de5:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102deb:	83 c4 10             	add    $0x10,%esp
f0102dee:	39 f3                	cmp    %esi,%ebx
f0102df0:	72 bf                	jb     f0102db1 <region_alloc+0x22>
		if(pp == NULL){
			panic("page alloc failed!\n");	
		}
		page_insert(e->env_pgdir, pp, va_t, PTE_U | PTE_W);	
	}
}
f0102df2:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102df5:	5b                   	pop    %ebx
f0102df6:	5e                   	pop    %esi
f0102df7:	5f                   	pop    %edi
f0102df8:	5d                   	pop    %ebp
f0102df9:	c3                   	ret    

f0102dfa <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f0102dfa:	55                   	push   %ebp
f0102dfb:	89 e5                	mov    %esp,%ebp
f0102dfd:	56                   	push   %esi
f0102dfe:	53                   	push   %ebx
f0102dff:	8b 45 08             	mov    0x8(%ebp),%eax
f0102e02:	8b 55 10             	mov    0x10(%ebp),%edx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f0102e05:	85 c0                	test   %eax,%eax
f0102e07:	75 1a                	jne    f0102e23 <envid2env+0x29>
		*env_store = curenv;
f0102e09:	e8 18 2c 00 00       	call   f0105a26 <cpunum>
f0102e0e:	6b c0 74             	imul   $0x74,%eax,%eax
f0102e11:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f0102e17:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0102e1a:	89 01                	mov    %eax,(%ecx)
		return 0;
f0102e1c:	b8 00 00 00 00       	mov    $0x0,%eax
f0102e21:	eb 70                	jmp    f0102e93 <envid2env+0x99>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f0102e23:	89 c3                	mov    %eax,%ebx
f0102e25:	81 e3 ff 03 00 00    	and    $0x3ff,%ebx
f0102e2b:	6b db 7c             	imul   $0x7c,%ebx,%ebx
f0102e2e:	03 1d 44 f2 22 f0    	add    0xf022f244,%ebx
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f0102e34:	83 7b 54 00          	cmpl   $0x0,0x54(%ebx)
f0102e38:	74 05                	je     f0102e3f <envid2env+0x45>
f0102e3a:	3b 43 48             	cmp    0x48(%ebx),%eax
f0102e3d:	74 10                	je     f0102e4f <envid2env+0x55>
		*env_store = 0;
f0102e3f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102e42:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0102e48:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0102e4d:	eb 44                	jmp    f0102e93 <envid2env+0x99>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f0102e4f:	84 d2                	test   %dl,%dl
f0102e51:	74 36                	je     f0102e89 <envid2env+0x8f>
f0102e53:	e8 ce 2b 00 00       	call   f0105a26 <cpunum>
f0102e58:	6b c0 74             	imul   $0x74,%eax,%eax
f0102e5b:	3b 98 28 00 23 f0    	cmp    -0xfdcffd8(%eax),%ebx
f0102e61:	74 26                	je     f0102e89 <envid2env+0x8f>
f0102e63:	8b 73 4c             	mov    0x4c(%ebx),%esi
f0102e66:	e8 bb 2b 00 00       	call   f0105a26 <cpunum>
f0102e6b:	6b c0 74             	imul   $0x74,%eax,%eax
f0102e6e:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f0102e74:	3b 70 48             	cmp    0x48(%eax),%esi
f0102e77:	74 10                	je     f0102e89 <envid2env+0x8f>
		*env_store = 0;
f0102e79:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102e7c:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0102e82:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0102e87:	eb 0a                	jmp    f0102e93 <envid2env+0x99>
	}

	*env_store = e;
f0102e89:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102e8c:	89 18                	mov    %ebx,(%eax)
	return 0;
f0102e8e:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102e93:	5b                   	pop    %ebx
f0102e94:	5e                   	pop    %esi
f0102e95:	5d                   	pop    %ebp
f0102e96:	c3                   	ret    

f0102e97 <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f0102e97:	55                   	push   %ebp
f0102e98:	89 e5                	mov    %esp,%ebp
}

static inline void
lgdt(void *p)
{
	asm volatile("lgdt (%0)" : : "r" (p));
f0102e9a:	b8 20 03 12 f0       	mov    $0xf0120320,%eax
f0102e9f:	0f 01 10             	lgdtl  (%eax)
	lgdt(&gdt_pd);
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" : : "a" (GD_UD|3));
f0102ea2:	b8 23 00 00 00       	mov    $0x23,%eax
f0102ea7:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" : : "a" (GD_UD|3));
f0102ea9:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" : : "a" (GD_KD));
f0102eab:	b8 10 00 00 00       	mov    $0x10,%eax
f0102eb0:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" : : "a" (GD_KD));
f0102eb2:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" : : "a" (GD_KD));
f0102eb4:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" : : "i" (GD_KT));
f0102eb6:	ea bd 2e 10 f0 08 00 	ljmp   $0x8,$0xf0102ebd
}

static inline void
lldt(uint16_t sel)
{
	asm volatile("lldt %0" : : "r" (sel));
f0102ebd:	b8 00 00 00 00       	mov    $0x0,%eax
f0102ec2:	0f 00 d0             	lldt   %ax
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
}
f0102ec5:	5d                   	pop    %ebp
f0102ec6:	c3                   	ret    

f0102ec7 <env_init>:
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f0102ec7:	55                   	push   %ebp
f0102ec8:	89 e5                	mov    %esp,%ebp
f0102eca:	56                   	push   %esi
f0102ecb:	53                   	push   %ebx
	// Set up envs array
	// LAB 3: Your code here.
	for (int i = NENV - 1; i >= 0; i--) {
		envs[i].env_id = 0;
f0102ecc:	8b 35 44 f2 22 f0    	mov    0xf022f244,%esi
f0102ed2:	8b 15 48 f2 22 f0    	mov    0xf022f248,%edx
f0102ed8:	8d 86 84 ef 01 00    	lea    0x1ef84(%esi),%eax
f0102ede:	8d 5e 84             	lea    -0x7c(%esi),%ebx
f0102ee1:	89 c1                	mov    %eax,%ecx
f0102ee3:	c7 40 48 00 00 00 00 	movl   $0x0,0x48(%eax)
		envs[i].env_status = ENV_FREE;
f0102eea:	c7 40 54 00 00 00 00 	movl   $0x0,0x54(%eax)
		envs[i].env_link = env_free_list;
f0102ef1:	89 50 44             	mov    %edx,0x44(%eax)
f0102ef4:	83 e8 7c             	sub    $0x7c,%eax
		env_free_list = &envs[i];
f0102ef7:	89 ca                	mov    %ecx,%edx
void
env_init(void)
{
	// Set up envs array
	// LAB 3: Your code here.
	for (int i = NENV - 1; i >= 0; i--) {
f0102ef9:	39 d8                	cmp    %ebx,%eax
f0102efb:	75 e4                	jne    f0102ee1 <env_init+0x1a>
f0102efd:	89 35 48 f2 22 f0    	mov    %esi,0xf022f248
		envs[i].env_link = env_free_list;
		env_free_list = &envs[i];
	}

	// Per-CPU part of the initialization
	env_init_percpu();
f0102f03:	e8 8f ff ff ff       	call   f0102e97 <env_init_percpu>
}
f0102f08:	5b                   	pop    %ebx
f0102f09:	5e                   	pop    %esi
f0102f0a:	5d                   	pop    %ebp
f0102f0b:	c3                   	ret    

f0102f0c <env_alloc>:
//	-E_NO_FREE_ENV if all NENVS environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f0102f0c:	55                   	push   %ebp
f0102f0d:	89 e5                	mov    %esp,%ebp
f0102f0f:	53                   	push   %ebx
f0102f10:	83 ec 04             	sub    $0x4,%esp
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f0102f13:	8b 1d 48 f2 22 f0    	mov    0xf022f248,%ebx
f0102f19:	85 db                	test   %ebx,%ebx
f0102f1b:	0f 84 6e 01 00 00    	je     f010308f <env_alloc+0x183>
{
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
f0102f21:	83 ec 0c             	sub    $0xc,%esp
f0102f24:	6a 01                	push   $0x1
f0102f26:	e8 3c e0 ff ff       	call   f0100f67 <page_alloc>
f0102f2b:	83 c4 10             	add    $0x10,%esp
f0102f2e:	85 c0                	test   %eax,%eax
f0102f30:	0f 84 60 01 00 00    	je     f0103096 <env_alloc+0x18a>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102f36:	89 c2                	mov    %eax,%edx
f0102f38:	2b 15 90 fe 22 f0    	sub    0xf022fe90,%edx
f0102f3e:	c1 fa 03             	sar    $0x3,%edx
f0102f41:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102f44:	89 d1                	mov    %edx,%ecx
f0102f46:	c1 e9 0c             	shr    $0xc,%ecx
f0102f49:	3b 0d 88 fe 22 f0    	cmp    0xf022fe88,%ecx
f0102f4f:	72 12                	jb     f0102f63 <env_alloc+0x57>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102f51:	52                   	push   %edx
f0102f52:	68 e4 60 10 f0       	push   $0xf01060e4
f0102f57:	6a 58                	push   $0x58
f0102f59:	68 d0 6f 10 f0       	push   $0xf0106fd0
f0102f5e:	e8 dd d0 ff ff       	call   f0100040 <_panic>
	//	is an exception -- you need to increment env_pgdir's
	//	pp_ref for env_free to work correctly.
	//    - The functions in kern/pmap.h are handy.

	// LAB 3: Your code here.
	e->env_pgdir = page2kva(p);
f0102f63:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f0102f69:	89 53 60             	mov    %edx,0x60(%ebx)
	p->pp_ref++;
f0102f6c:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
	memcpy(e->env_pgdir, kern_pgdir, PGSIZE);
f0102f71:	83 ec 04             	sub    $0x4,%esp
f0102f74:	68 00 10 00 00       	push   $0x1000
f0102f79:	ff 35 8c fe 22 f0    	pushl  0xf022fe8c
f0102f7f:	ff 73 60             	pushl  0x60(%ebx)
f0102f82:	e8 32 25 00 00       	call   f01054b9 <memcpy>

	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f0102f87:	8b 43 60             	mov    0x60(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102f8a:	83 c4 10             	add    $0x10,%esp
f0102f8d:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102f92:	77 15                	ja     f0102fa9 <env_alloc+0x9d>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102f94:	50                   	push   %eax
f0102f95:	68 08 61 10 f0       	push   $0xf0106108
f0102f9a:	68 c5 00 00 00       	push   $0xc5
f0102f9f:	68 ea 72 10 f0       	push   $0xf01072ea
f0102fa4:	e8 97 d0 ff ff       	call   f0100040 <_panic>
f0102fa9:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0102faf:	83 ca 05             	or     $0x5,%edx
f0102fb2:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f0102fb8:	8b 43 48             	mov    0x48(%ebx),%eax
f0102fbb:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f0102fc0:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f0102fc5:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102fca:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f0102fcd:	89 da                	mov    %ebx,%edx
f0102fcf:	2b 15 44 f2 22 f0    	sub    0xf022f244,%edx
f0102fd5:	c1 fa 02             	sar    $0x2,%edx
f0102fd8:	69 d2 df 7b ef bd    	imul   $0xbdef7bdf,%edx,%edx
f0102fde:	09 d0                	or     %edx,%eax
f0102fe0:	89 43 48             	mov    %eax,0x48(%ebx)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f0102fe3:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102fe6:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f0102fe9:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f0102ff0:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f0102ff7:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f0102ffe:	83 ec 04             	sub    $0x4,%esp
f0103001:	6a 44                	push   $0x44
f0103003:	6a 00                	push   $0x0
f0103005:	53                   	push   %ebx
f0103006:	e8 f9 23 00 00       	call   f0105404 <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f010300b:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f0103011:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f0103017:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f010301d:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f0103024:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)
	// You will set e->env_tf.tf_eip later.

	// Enable interrupts while in user mode.
	// LAB 4: Your code here.
    e->env_tf.tf_eflags |= FL_IF;
f010302a:	81 4b 38 00 02 00 00 	orl    $0x200,0x38(%ebx)
	// Clear the page fault handler until user installs one.
	e->env_pgfault_upcall = 0;
f0103031:	c7 43 64 00 00 00 00 	movl   $0x0,0x64(%ebx)

	// Also clear the IPC receiving flag.
	e->env_ipc_recving = 0;
f0103038:	c6 43 68 00          	movb   $0x0,0x68(%ebx)

	// commit the allocation
	env_free_list = e->env_link;
f010303c:	8b 43 44             	mov    0x44(%ebx),%eax
f010303f:	a3 48 f2 22 f0       	mov    %eax,0xf022f248
	*newenv_store = e;
f0103044:	8b 45 08             	mov    0x8(%ebp),%eax
f0103047:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0103049:	8b 5b 48             	mov    0x48(%ebx),%ebx
f010304c:	e8 d5 29 00 00       	call   f0105a26 <cpunum>
f0103051:	6b c0 74             	imul   $0x74,%eax,%eax
f0103054:	83 c4 10             	add    $0x10,%esp
f0103057:	ba 00 00 00 00       	mov    $0x0,%edx
f010305c:	83 b8 28 00 23 f0 00 	cmpl   $0x0,-0xfdcffd8(%eax)
f0103063:	74 11                	je     f0103076 <env_alloc+0x16a>
f0103065:	e8 bc 29 00 00       	call   f0105a26 <cpunum>
f010306a:	6b c0 74             	imul   $0x74,%eax,%eax
f010306d:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f0103073:	8b 50 48             	mov    0x48(%eax),%edx
f0103076:	83 ec 04             	sub    $0x4,%esp
f0103079:	53                   	push   %ebx
f010307a:	52                   	push   %edx
f010307b:	68 f5 72 10 f0       	push   $0xf01072f5
f0103080:	e8 d9 05 00 00       	call   f010365e <cprintf>
	return 0;
f0103085:	83 c4 10             	add    $0x10,%esp
f0103088:	b8 00 00 00 00       	mov    $0x0,%eax
f010308d:	eb 0c                	jmp    f010309b <env_alloc+0x18f>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f010308f:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f0103094:	eb 05                	jmp    f010309b <env_alloc+0x18f>
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f0103096:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	env_free_list = e->env_link;
	*newenv_store = e;

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f010309b:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010309e:	c9                   	leave  
f010309f:	c3                   	ret    

f01030a0 <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f01030a0:	55                   	push   %ebp
f01030a1:	89 e5                	mov    %esp,%ebp
f01030a3:	57                   	push   %edi
f01030a4:	56                   	push   %esi
f01030a5:	53                   	push   %ebx
f01030a6:	83 ec 34             	sub    $0x34,%esp
f01030a9:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.
	struct Env *e;
	env_alloc(&e, 0);
f01030ac:	6a 00                	push   $0x0
f01030ae:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01030b1:	50                   	push   %eax
f01030b2:	e8 55 fe ff ff       	call   f0102f0c <env_alloc>
	load_icode(e, binary);
f01030b7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01030ba:	89 45 d4             	mov    %eax,-0x2c(%ebp)

	// LAB 3: Your code here.
	
	struct Elf *elf = (struct Elf *) binary;

	if (elf->e_magic != ELF_MAGIC)
f01030bd:	83 c4 10             	add    $0x10,%esp
f01030c0:	81 3f 7f 45 4c 46    	cmpl   $0x464c457f,(%edi)
f01030c6:	74 17                	je     f01030df <env_create+0x3f>
		panic("load_icode: not ELF executable.");
f01030c8:	83 ec 04             	sub    $0x4,%esp
f01030cb:	68 2c 73 10 f0       	push   $0xf010732c
f01030d0:	68 69 01 00 00       	push   $0x169
f01030d5:	68 ea 72 10 f0       	push   $0xf01072ea
f01030da:	e8 61 cf ff ff       	call   f0100040 <_panic>

	struct Proghdr *ph = (struct Proghdr *) (elf->e_phoff + binary);
f01030df:	89 fb                	mov    %edi,%ebx
f01030e1:	03 5f 1c             	add    0x1c(%edi),%ebx
	struct Proghdr *eph = ph + elf->e_phnum;
f01030e4:	0f b7 77 2c          	movzwl 0x2c(%edi),%esi
f01030e8:	c1 e6 05             	shl    $0x5,%esi
f01030eb:	01 de                	add    %ebx,%esi

	lcr3(PADDR(e->env_pgdir));
f01030ed:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01030f0:	8b 40 60             	mov    0x60(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01030f3:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01030f8:	77 15                	ja     f010310f <env_create+0x6f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01030fa:	50                   	push   %eax
f01030fb:	68 08 61 10 f0       	push   $0xf0106108
f0103100:	68 6e 01 00 00       	push   $0x16e
f0103105:	68 ea 72 10 f0       	push   $0xf01072ea
f010310a:	e8 31 cf ff ff       	call   f0100040 <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f010310f:	05 00 00 00 10       	add    $0x10000000,%eax
f0103114:	0f 22 d8             	mov    %eax,%cr3
f0103117:	eb 3d                	jmp    f0103156 <env_create+0xb6>
	for(; ph < eph; ph++){
		if(ph->p_type == ELF_PROG_LOAD){
f0103119:	83 3b 01             	cmpl   $0x1,(%ebx)
f010311c:	75 35                	jne    f0103153 <env_create+0xb3>
			region_alloc(e, (void *) ph->p_va, ph->p_memsz);
f010311e:	8b 4b 14             	mov    0x14(%ebx),%ecx
f0103121:	8b 53 08             	mov    0x8(%ebx),%edx
f0103124:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103127:	e8 63 fc ff ff       	call   f0102d8f <region_alloc>
			memset((void *) ph->p_va, 0, ph->p_memsz);
f010312c:	83 ec 04             	sub    $0x4,%esp
f010312f:	ff 73 14             	pushl  0x14(%ebx)
f0103132:	6a 00                	push   $0x0
f0103134:	ff 73 08             	pushl  0x8(%ebx)
f0103137:	e8 c8 22 00 00       	call   f0105404 <memset>
			memcpy((void *) ph->p_va, binary + ph->p_offset, ph->p_filesz);
f010313c:	83 c4 0c             	add    $0xc,%esp
f010313f:	ff 73 10             	pushl  0x10(%ebx)
f0103142:	89 f8                	mov    %edi,%eax
f0103144:	03 43 04             	add    0x4(%ebx),%eax
f0103147:	50                   	push   %eax
f0103148:	ff 73 08             	pushl  0x8(%ebx)
f010314b:	e8 69 23 00 00       	call   f01054b9 <memcpy>
f0103150:	83 c4 10             	add    $0x10,%esp

	struct Proghdr *ph = (struct Proghdr *) (elf->e_phoff + binary);
	struct Proghdr *eph = ph + elf->e_phnum;

	lcr3(PADDR(e->env_pgdir));
	for(; ph < eph; ph++){
f0103153:	83 c3 20             	add    $0x20,%ebx
f0103156:	39 de                	cmp    %ebx,%esi
f0103158:	77 bf                	ja     f0103119 <env_create+0x79>
			region_alloc(e, (void *) ph->p_va, ph->p_memsz);
			memset((void *) ph->p_va, 0, ph->p_memsz);
			memcpy((void *) ph->p_va, binary + ph->p_offset, ph->p_filesz);
		}
	}
	lcr3(PADDR(kern_pgdir));
f010315a:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010315f:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103164:	77 15                	ja     f010317b <env_create+0xdb>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103166:	50                   	push   %eax
f0103167:	68 08 61 10 f0       	push   $0xf0106108
f010316c:	68 76 01 00 00       	push   $0x176
f0103171:	68 ea 72 10 f0       	push   $0xf01072ea
f0103176:	e8 c5 ce ff ff       	call   f0100040 <_panic>
f010317b:	05 00 00 00 10       	add    $0x10000000,%eax
f0103180:	0f 22 d8             	mov    %eax,%cr3
	e->env_tf.tf_eip = elf->e_entry;
f0103183:	8b 47 18             	mov    0x18(%edi),%eax
f0103186:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0103189:	89 47 30             	mov    %eax,0x30(%edi)
	// Now map one page for the program's initial stack
	// at virtual address USTACKTOP - PGSIZE.

	// LAB 3: Your code here.
	region_alloc(e, (void *) (USTACKTOP - PGSIZE), PGSIZE);
f010318c:	b9 00 10 00 00       	mov    $0x1000,%ecx
f0103191:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f0103196:	89 f8                	mov    %edi,%eax
f0103198:	e8 f2 fb ff ff       	call   f0102d8f <region_alloc>
{
	// LAB 3: Your code here.
	struct Env *e;
	env_alloc(&e, 0);
	load_icode(e, binary);
	e->env_type = type;
f010319d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01031a0:	8b 55 0c             	mov    0xc(%ebp),%edx
f01031a3:	89 50 50             	mov    %edx,0x50(%eax)
}
f01031a6:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01031a9:	5b                   	pop    %ebx
f01031aa:	5e                   	pop    %esi
f01031ab:	5f                   	pop    %edi
f01031ac:	5d                   	pop    %ebp
f01031ad:	c3                   	ret    

f01031ae <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f01031ae:	55                   	push   %ebp
f01031af:	89 e5                	mov    %esp,%ebp
f01031b1:	57                   	push   %edi
f01031b2:	56                   	push   %esi
f01031b3:	53                   	push   %ebx
f01031b4:	83 ec 1c             	sub    $0x1c,%esp
f01031b7:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f01031ba:	e8 67 28 00 00       	call   f0105a26 <cpunum>
f01031bf:	6b c0 74             	imul   $0x74,%eax,%eax
f01031c2:	39 b8 28 00 23 f0    	cmp    %edi,-0xfdcffd8(%eax)
f01031c8:	75 29                	jne    f01031f3 <env_free+0x45>
		lcr3(PADDR(kern_pgdir));
f01031ca:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01031cf:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01031d4:	77 15                	ja     f01031eb <env_free+0x3d>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01031d6:	50                   	push   %eax
f01031d7:	68 08 61 10 f0       	push   $0xf0106108
f01031dc:	68 9f 01 00 00       	push   $0x19f
f01031e1:	68 ea 72 10 f0       	push   $0xf01072ea
f01031e6:	e8 55 ce ff ff       	call   f0100040 <_panic>
f01031eb:	05 00 00 00 10       	add    $0x10000000,%eax
f01031f0:	0f 22 d8             	mov    %eax,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f01031f3:	8b 5f 48             	mov    0x48(%edi),%ebx
f01031f6:	e8 2b 28 00 00       	call   f0105a26 <cpunum>
f01031fb:	6b c0 74             	imul   $0x74,%eax,%eax
f01031fe:	ba 00 00 00 00       	mov    $0x0,%edx
f0103203:	83 b8 28 00 23 f0 00 	cmpl   $0x0,-0xfdcffd8(%eax)
f010320a:	74 11                	je     f010321d <env_free+0x6f>
f010320c:	e8 15 28 00 00       	call   f0105a26 <cpunum>
f0103211:	6b c0 74             	imul   $0x74,%eax,%eax
f0103214:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f010321a:	8b 50 48             	mov    0x48(%eax),%edx
f010321d:	83 ec 04             	sub    $0x4,%esp
f0103220:	53                   	push   %ebx
f0103221:	52                   	push   %edx
f0103222:	68 0a 73 10 f0       	push   $0xf010730a
f0103227:	e8 32 04 00 00       	call   f010365e <cprintf>
f010322c:	83 c4 10             	add    $0x10,%esp

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f010322f:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0103236:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0103239:	89 d0                	mov    %edx,%eax
f010323b:	c1 e0 02             	shl    $0x2,%eax
f010323e:	89 45 dc             	mov    %eax,-0x24(%ebp)

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f0103241:	8b 47 60             	mov    0x60(%edi),%eax
f0103244:	8b 34 90             	mov    (%eax,%edx,4),%esi
f0103247:	f7 c6 01 00 00 00    	test   $0x1,%esi
f010324d:	0f 84 a8 00 00 00    	je     f01032fb <env_free+0x14d>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f0103253:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103259:	89 f0                	mov    %esi,%eax
f010325b:	c1 e8 0c             	shr    $0xc,%eax
f010325e:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103261:	39 05 88 fe 22 f0    	cmp    %eax,0xf022fe88
f0103267:	77 15                	ja     f010327e <env_free+0xd0>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0103269:	56                   	push   %esi
f010326a:	68 e4 60 10 f0       	push   $0xf01060e4
f010326f:	68 ae 01 00 00       	push   $0x1ae
f0103274:	68 ea 72 10 f0       	push   $0xf01072ea
f0103279:	e8 c2 cd ff ff       	call   f0100040 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f010327e:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103281:	c1 e0 16             	shl    $0x16,%eax
f0103284:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0103287:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f010328c:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f0103293:	01 
f0103294:	74 17                	je     f01032ad <env_free+0xff>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0103296:	83 ec 08             	sub    $0x8,%esp
f0103299:	89 d8                	mov    %ebx,%eax
f010329b:	c1 e0 0c             	shl    $0xc,%eax
f010329e:	0b 45 e4             	or     -0x1c(%ebp),%eax
f01032a1:	50                   	push   %eax
f01032a2:	ff 77 60             	pushl  0x60(%edi)
f01032a5:	e8 1c df ff ff       	call   f01011c6 <page_remove>
f01032aa:	83 c4 10             	add    $0x10,%esp
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f01032ad:	83 c3 01             	add    $0x1,%ebx
f01032b0:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f01032b6:	75 d4                	jne    f010328c <env_free+0xde>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f01032b8:	8b 47 60             	mov    0x60(%edi),%eax
f01032bb:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01032be:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01032c5:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01032c8:	3b 05 88 fe 22 f0    	cmp    0xf022fe88,%eax
f01032ce:	72 14                	jb     f01032e4 <env_free+0x136>
		panic("pa2page called with invalid pa");
f01032d0:	83 ec 04             	sub    $0x4,%esp
f01032d3:	68 50 67 10 f0       	push   $0xf0106750
f01032d8:	6a 51                	push   $0x51
f01032da:	68 d0 6f 10 f0       	push   $0xf0106fd0
f01032df:	e8 5c cd ff ff       	call   f0100040 <_panic>
		page_decref(pa2page(pa));
f01032e4:	83 ec 0c             	sub    $0xc,%esp
f01032e7:	a1 90 fe 22 f0       	mov    0xf022fe90,%eax
f01032ec:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01032ef:	8d 04 d0             	lea    (%eax,%edx,8),%eax
f01032f2:	50                   	push   %eax
f01032f3:	e8 21 dd ff ff       	call   f0101019 <page_decref>
f01032f8:	83 c4 10             	add    $0x10,%esp
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f01032fb:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f01032ff:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103302:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f0103307:	0f 85 29 ff ff ff    	jne    f0103236 <env_free+0x88>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f010330d:	8b 47 60             	mov    0x60(%edi),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103310:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103315:	77 15                	ja     f010332c <env_free+0x17e>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103317:	50                   	push   %eax
f0103318:	68 08 61 10 f0       	push   $0xf0106108
f010331d:	68 bc 01 00 00       	push   $0x1bc
f0103322:	68 ea 72 10 f0       	push   $0xf01072ea
f0103327:	e8 14 cd ff ff       	call   f0100040 <_panic>
	e->env_pgdir = 0;
f010332c:	c7 47 60 00 00 00 00 	movl   $0x0,0x60(%edi)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103333:	05 00 00 00 10       	add    $0x10000000,%eax
f0103338:	c1 e8 0c             	shr    $0xc,%eax
f010333b:	3b 05 88 fe 22 f0    	cmp    0xf022fe88,%eax
f0103341:	72 14                	jb     f0103357 <env_free+0x1a9>
		panic("pa2page called with invalid pa");
f0103343:	83 ec 04             	sub    $0x4,%esp
f0103346:	68 50 67 10 f0       	push   $0xf0106750
f010334b:	6a 51                	push   $0x51
f010334d:	68 d0 6f 10 f0       	push   $0xf0106fd0
f0103352:	e8 e9 cc ff ff       	call   f0100040 <_panic>
	page_decref(pa2page(pa));
f0103357:	83 ec 0c             	sub    $0xc,%esp
f010335a:	8b 15 90 fe 22 f0    	mov    0xf022fe90,%edx
f0103360:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f0103363:	50                   	push   %eax
f0103364:	e8 b0 dc ff ff       	call   f0101019 <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f0103369:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f0103370:	a1 48 f2 22 f0       	mov    0xf022f248,%eax
f0103375:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f0103378:	89 3d 48 f2 22 f0    	mov    %edi,0xf022f248
}
f010337e:	83 c4 10             	add    $0x10,%esp
f0103381:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103384:	5b                   	pop    %ebx
f0103385:	5e                   	pop    %esi
f0103386:	5f                   	pop    %edi
f0103387:	5d                   	pop    %ebp
f0103388:	c3                   	ret    

f0103389 <env_destroy>:
// If e was the current env, then runs a new environment (and does not return
// to the caller).
//
void
env_destroy(struct Env *e)
{
f0103389:	55                   	push   %ebp
f010338a:	89 e5                	mov    %esp,%ebp
f010338c:	53                   	push   %ebx
f010338d:	83 ec 04             	sub    $0x4,%esp
f0103390:	8b 5d 08             	mov    0x8(%ebp),%ebx
	// If e is currently running on other CPUs, we change its state to
	// ENV_DYING. A zombie environment will be freed the next time
	// it traps to the kernel.
	if (e->env_status == ENV_RUNNING && curenv != e) {
f0103393:	83 7b 54 03          	cmpl   $0x3,0x54(%ebx)
f0103397:	75 19                	jne    f01033b2 <env_destroy+0x29>
f0103399:	e8 88 26 00 00       	call   f0105a26 <cpunum>
f010339e:	6b c0 74             	imul   $0x74,%eax,%eax
f01033a1:	3b 98 28 00 23 f0    	cmp    -0xfdcffd8(%eax),%ebx
f01033a7:	74 09                	je     f01033b2 <env_destroy+0x29>
		e->env_status = ENV_DYING;
f01033a9:	c7 43 54 01 00 00 00 	movl   $0x1,0x54(%ebx)
		return;
f01033b0:	eb 33                	jmp    f01033e5 <env_destroy+0x5c>
	}

	env_free(e);
f01033b2:	83 ec 0c             	sub    $0xc,%esp
f01033b5:	53                   	push   %ebx
f01033b6:	e8 f3 fd ff ff       	call   f01031ae <env_free>

	if (curenv == e) {
f01033bb:	e8 66 26 00 00       	call   f0105a26 <cpunum>
f01033c0:	6b c0 74             	imul   $0x74,%eax,%eax
f01033c3:	83 c4 10             	add    $0x10,%esp
f01033c6:	3b 98 28 00 23 f0    	cmp    -0xfdcffd8(%eax),%ebx
f01033cc:	75 17                	jne    f01033e5 <env_destroy+0x5c>
		curenv = NULL;
f01033ce:	e8 53 26 00 00       	call   f0105a26 <cpunum>
f01033d3:	6b c0 74             	imul   $0x74,%eax,%eax
f01033d6:	c7 80 28 00 23 f0 00 	movl   $0x0,-0xfdcffd8(%eax)
f01033dd:	00 00 00 
		sched_yield();
f01033e0:	e8 56 0e 00 00       	call   f010423b <sched_yield>
	}
}
f01033e5:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01033e8:	c9                   	leave  
f01033e9:	c3                   	ret    

f01033ea <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f01033ea:	55                   	push   %ebp
f01033eb:	89 e5                	mov    %esp,%ebp
f01033ed:	53                   	push   %ebx
f01033ee:	83 ec 04             	sub    $0x4,%esp
	// Record the CPU we are running on for user-space debugging
	curenv->env_cpunum = cpunum();
f01033f1:	e8 30 26 00 00       	call   f0105a26 <cpunum>
f01033f6:	6b c0 74             	imul   $0x74,%eax,%eax
f01033f9:	8b 98 28 00 23 f0    	mov    -0xfdcffd8(%eax),%ebx
f01033ff:	e8 22 26 00 00       	call   f0105a26 <cpunum>
f0103404:	89 43 5c             	mov    %eax,0x5c(%ebx)

	asm volatile(
f0103407:	8b 65 08             	mov    0x8(%ebp),%esp
f010340a:	61                   	popa   
f010340b:	07                   	pop    %es
f010340c:	1f                   	pop    %ds
f010340d:	83 c4 08             	add    $0x8,%esp
f0103410:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret\n"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f0103411:	83 ec 04             	sub    $0x4,%esp
f0103414:	68 20 73 10 f0       	push   $0xf0107320
f0103419:	68 f3 01 00 00       	push   $0x1f3
f010341e:	68 ea 72 10 f0       	push   $0xf01072ea
f0103423:	e8 18 cc ff ff       	call   f0100040 <_panic>

f0103428 <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f0103428:	55                   	push   %ebp
f0103429:	89 e5                	mov    %esp,%ebp
f010342b:	53                   	push   %ebx
f010342c:	83 ec 04             	sub    $0x4,%esp
f010342f:	8b 5d 08             	mov    0x8(%ebp),%ebx
	//	e->env_tf.  Go back through the code you wrote above
	//	and make sure you have set the relevant parts of
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.
	if(curenv != NULL){
f0103432:	e8 ef 25 00 00       	call   f0105a26 <cpunum>
f0103437:	6b c0 74             	imul   $0x74,%eax,%eax
f010343a:	83 b8 28 00 23 f0 00 	cmpl   $0x0,-0xfdcffd8(%eax)
f0103441:	74 29                	je     f010346c <env_run+0x44>
		if(curenv->env_status == ENV_RUNNING)
f0103443:	e8 de 25 00 00       	call   f0105a26 <cpunum>
f0103448:	6b c0 74             	imul   $0x74,%eax,%eax
f010344b:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f0103451:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0103455:	75 15                	jne    f010346c <env_run+0x44>
			curenv->env_status = ENV_RUNNABLE;
f0103457:	e8 ca 25 00 00       	call   f0105a26 <cpunum>
f010345c:	6b c0 74             	imul   $0x74,%eax,%eax
f010345f:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f0103465:	c7 40 54 02 00 00 00 	movl   $0x2,0x54(%eax)
	}
	curenv = e;
f010346c:	e8 b5 25 00 00       	call   f0105a26 <cpunum>
f0103471:	6b c0 74             	imul   $0x74,%eax,%eax
f0103474:	89 98 28 00 23 f0    	mov    %ebx,-0xfdcffd8(%eax)
	curenv->env_status = ENV_RUNNING;
f010347a:	e8 a7 25 00 00       	call   f0105a26 <cpunum>
f010347f:	6b c0 74             	imul   $0x74,%eax,%eax
f0103482:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f0103488:	c7 40 54 03 00 00 00 	movl   $0x3,0x54(%eax)
	curenv->env_runs ++;
f010348f:	e8 92 25 00 00       	call   f0105a26 <cpunum>
f0103494:	6b c0 74             	imul   $0x74,%eax,%eax
f0103497:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f010349d:	83 40 58 01          	addl   $0x1,0x58(%eax)
	lcr3(PADDR(e->env_pgdir));
f01034a1:	8b 43 60             	mov    0x60(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01034a4:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01034a9:	77 15                	ja     f01034c0 <env_run+0x98>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01034ab:	50                   	push   %eax
f01034ac:	68 08 61 10 f0       	push   $0xf0106108
f01034b1:	68 18 02 00 00       	push   $0x218
f01034b6:	68 ea 72 10 f0       	push   $0xf01072ea
f01034bb:	e8 80 cb ff ff       	call   f0100040 <_panic>
f01034c0:	05 00 00 00 10       	add    $0x10000000,%eax
f01034c5:	0f 22 d8             	mov    %eax,%cr3
}

static inline void
unlock_kernel(void)
{
	spin_unlock(&kernel_lock);
f01034c8:	83 ec 0c             	sub    $0xc,%esp
f01034cb:	68 c0 03 12 f0       	push   $0xf01203c0
f01034d0:	e8 5c 28 00 00       	call   f0105d31 <spin_unlock>

	// Normally we wouldn't need to do this, but QEMU only runs
	// one CPU at a time and has a long time-slice.  Without the
	// pause, this CPU is likely to reacquire the lock before
	// another CPU has even been given a chance to acquire it.
	asm volatile("pause");
f01034d5:	f3 90                	pause  
    unlock_kernel();
	env_pop_tf(&e->env_tf);
f01034d7:	89 1c 24             	mov    %ebx,(%esp)
f01034da:	e8 0b ff ff ff       	call   f01033ea <env_pop_tf>

f01034df <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f01034df:	55                   	push   %ebp
f01034e0:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01034e2:	ba 70 00 00 00       	mov    $0x70,%edx
f01034e7:	8b 45 08             	mov    0x8(%ebp),%eax
f01034ea:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01034eb:	ba 71 00 00 00       	mov    $0x71,%edx
f01034f0:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f01034f1:	0f b6 c0             	movzbl %al,%eax
}
f01034f4:	5d                   	pop    %ebp
f01034f5:	c3                   	ret    

f01034f6 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f01034f6:	55                   	push   %ebp
f01034f7:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01034f9:	ba 70 00 00 00       	mov    $0x70,%edx
f01034fe:	8b 45 08             	mov    0x8(%ebp),%eax
f0103501:	ee                   	out    %al,(%dx)
f0103502:	ba 71 00 00 00       	mov    $0x71,%edx
f0103507:	8b 45 0c             	mov    0xc(%ebp),%eax
f010350a:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f010350b:	5d                   	pop    %ebp
f010350c:	c3                   	ret    

f010350d <irq_setmask_8259A>:
		irq_setmask_8259A(irq_mask_8259A);
}

void
irq_setmask_8259A(uint16_t mask)
{
f010350d:	55                   	push   %ebp
f010350e:	89 e5                	mov    %esp,%ebp
f0103510:	56                   	push   %esi
f0103511:	53                   	push   %ebx
f0103512:	8b 45 08             	mov    0x8(%ebp),%eax
	int i;
	irq_mask_8259A = mask;
f0103515:	66 a3 a8 03 12 f0    	mov    %ax,0xf01203a8
	if (!didinit)
f010351b:	80 3d 4c f2 22 f0 00 	cmpb   $0x0,0xf022f24c
f0103522:	74 5a                	je     f010357e <irq_setmask_8259A+0x71>
f0103524:	89 c6                	mov    %eax,%esi
f0103526:	ba 21 00 00 00       	mov    $0x21,%edx
f010352b:	ee                   	out    %al,(%dx)
f010352c:	66 c1 e8 08          	shr    $0x8,%ax
f0103530:	ba a1 00 00 00       	mov    $0xa1,%edx
f0103535:	ee                   	out    %al,(%dx)
		return;
	outb(IO_PIC1+1, (char)mask);
	outb(IO_PIC2+1, (char)(mask >> 8));
	cprintf("enabled interrupts:");
f0103536:	83 ec 0c             	sub    $0xc,%esp
f0103539:	68 4c 73 10 f0       	push   $0xf010734c
f010353e:	e8 1b 01 00 00       	call   f010365e <cprintf>
f0103543:	83 c4 10             	add    $0x10,%esp
	for (i = 0; i < 16; i++)
f0103546:	bb 00 00 00 00       	mov    $0x0,%ebx
		if (~mask & (1<<i))
f010354b:	0f b7 f6             	movzwl %si,%esi
f010354e:	f7 d6                	not    %esi
f0103550:	0f a3 de             	bt     %ebx,%esi
f0103553:	73 11                	jae    f0103566 <irq_setmask_8259A+0x59>
			cprintf(" %d", i);
f0103555:	83 ec 08             	sub    $0x8,%esp
f0103558:	53                   	push   %ebx
f0103559:	68 96 78 10 f0       	push   $0xf0107896
f010355e:	e8 fb 00 00 00       	call   f010365e <cprintf>
f0103563:	83 c4 10             	add    $0x10,%esp
	if (!didinit)
		return;
	outb(IO_PIC1+1, (char)mask);
	outb(IO_PIC2+1, (char)(mask >> 8));
	cprintf("enabled interrupts:");
	for (i = 0; i < 16; i++)
f0103566:	83 c3 01             	add    $0x1,%ebx
f0103569:	83 fb 10             	cmp    $0x10,%ebx
f010356c:	75 e2                	jne    f0103550 <irq_setmask_8259A+0x43>
		if (~mask & (1<<i))
			cprintf(" %d", i);
	cprintf("\n");
f010356e:	83 ec 0c             	sub    $0xc,%esp
f0103571:	68 a4 72 10 f0       	push   $0xf01072a4
f0103576:	e8 e3 00 00 00       	call   f010365e <cprintf>
f010357b:	83 c4 10             	add    $0x10,%esp
}
f010357e:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0103581:	5b                   	pop    %ebx
f0103582:	5e                   	pop    %esi
f0103583:	5d                   	pop    %ebp
f0103584:	c3                   	ret    

f0103585 <pic_init>:

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
	didinit = 1;
f0103585:	c6 05 4c f2 22 f0 01 	movb   $0x1,0xf022f24c
f010358c:	ba 21 00 00 00       	mov    $0x21,%edx
f0103591:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103596:	ee                   	out    %al,(%dx)
f0103597:	ba a1 00 00 00       	mov    $0xa1,%edx
f010359c:	ee                   	out    %al,(%dx)
f010359d:	ba 20 00 00 00       	mov    $0x20,%edx
f01035a2:	b8 11 00 00 00       	mov    $0x11,%eax
f01035a7:	ee                   	out    %al,(%dx)
f01035a8:	ba 21 00 00 00       	mov    $0x21,%edx
f01035ad:	b8 20 00 00 00       	mov    $0x20,%eax
f01035b2:	ee                   	out    %al,(%dx)
f01035b3:	b8 04 00 00 00       	mov    $0x4,%eax
f01035b8:	ee                   	out    %al,(%dx)
f01035b9:	b8 03 00 00 00       	mov    $0x3,%eax
f01035be:	ee                   	out    %al,(%dx)
f01035bf:	ba a0 00 00 00       	mov    $0xa0,%edx
f01035c4:	b8 11 00 00 00       	mov    $0x11,%eax
f01035c9:	ee                   	out    %al,(%dx)
f01035ca:	ba a1 00 00 00       	mov    $0xa1,%edx
f01035cf:	b8 28 00 00 00       	mov    $0x28,%eax
f01035d4:	ee                   	out    %al,(%dx)
f01035d5:	b8 02 00 00 00       	mov    $0x2,%eax
f01035da:	ee                   	out    %al,(%dx)
f01035db:	b8 01 00 00 00       	mov    $0x1,%eax
f01035e0:	ee                   	out    %al,(%dx)
f01035e1:	ba 20 00 00 00       	mov    $0x20,%edx
f01035e6:	b8 68 00 00 00       	mov    $0x68,%eax
f01035eb:	ee                   	out    %al,(%dx)
f01035ec:	b8 0a 00 00 00       	mov    $0xa,%eax
f01035f1:	ee                   	out    %al,(%dx)
f01035f2:	ba a0 00 00 00       	mov    $0xa0,%edx
f01035f7:	b8 68 00 00 00       	mov    $0x68,%eax
f01035fc:	ee                   	out    %al,(%dx)
f01035fd:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103602:	ee                   	out    %al,(%dx)
	outb(IO_PIC1, 0x0a);             /* read IRR by default */

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irq_mask_8259A != 0xFFFF)
f0103603:	0f b7 05 a8 03 12 f0 	movzwl 0xf01203a8,%eax
f010360a:	66 83 f8 ff          	cmp    $0xffff,%ax
f010360e:	74 13                	je     f0103623 <pic_init+0x9e>
static bool didinit;

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
f0103610:	55                   	push   %ebp
f0103611:	89 e5                	mov    %esp,%ebp
f0103613:	83 ec 14             	sub    $0x14,%esp

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irq_mask_8259A != 0xFFFF)
		irq_setmask_8259A(irq_mask_8259A);
f0103616:	0f b7 c0             	movzwl %ax,%eax
f0103619:	50                   	push   %eax
f010361a:	e8 ee fe ff ff       	call   f010350d <irq_setmask_8259A>
f010361f:	83 c4 10             	add    $0x10,%esp
}
f0103622:	c9                   	leave  
f0103623:	f3 c3                	repz ret 

f0103625 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0103625:	55                   	push   %ebp
f0103626:	89 e5                	mov    %esp,%ebp
f0103628:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f010362b:	ff 75 08             	pushl  0x8(%ebp)
f010362e:	e8 31 d1 ff ff       	call   f0100764 <cputchar>
	*cnt++;
}
f0103633:	83 c4 10             	add    $0x10,%esp
f0103636:	c9                   	leave  
f0103637:	c3                   	ret    

f0103638 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0103638:	55                   	push   %ebp
f0103639:	89 e5                	mov    %esp,%ebp
f010363b:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f010363e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0103645:	ff 75 0c             	pushl  0xc(%ebp)
f0103648:	ff 75 08             	pushl  0x8(%ebp)
f010364b:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010364e:	50                   	push   %eax
f010364f:	68 25 36 10 f0       	push   $0xf0103625
f0103654:	e8 3f 17 00 00       	call   f0104d98 <vprintfmt>
	return cnt;
}
f0103659:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010365c:	c9                   	leave  
f010365d:	c3                   	ret    

f010365e <cprintf>:

int
cprintf(const char *fmt, ...)
{
f010365e:	55                   	push   %ebp
f010365f:	89 e5                	mov    %esp,%ebp
f0103661:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0103664:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0103667:	50                   	push   %eax
f0103668:	ff 75 08             	pushl  0x8(%ebp)
f010366b:	e8 c8 ff ff ff       	call   f0103638 <vcprintf>
	va_end(ap);

	return cnt;
}
f0103670:	c9                   	leave  
f0103671:	c3                   	ret    

f0103672 <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f0103672:	55                   	push   %ebp
f0103673:	89 e5                	mov    %esp,%ebp
f0103675:	57                   	push   %edi
f0103676:	56                   	push   %esi
f0103677:	53                   	push   %ebx
f0103678:	83 ec 1c             	sub    $0x1c,%esp
	// get a triple fault.  If you set up an individual CPU's TSS
	// wrong, you may not get a fault until you try to return from
	// user space on that CPU.
	//
	// LAB 4: Your code here:
    int i = cpunum();
f010367b:	e8 a6 23 00 00       	call   f0105a26 <cpunum>
f0103680:	89 c6                	mov    %eax,%esi
	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.

	thiscpu->cpu_ts.ts_esp0 = (uintptr_t)percpu_kstacks[i];
f0103682:	e8 9f 23 00 00       	call   f0105a26 <cpunum>
f0103687:	6b c0 74             	imul   $0x74,%eax,%eax
f010368a:	89 f2                	mov    %esi,%edx
f010368c:	c1 e2 0f             	shl    $0xf,%edx
f010368f:	81 c2 00 10 23 f0    	add    $0xf0231000,%edx
f0103695:	89 90 30 00 23 f0    	mov    %edx,-0xfdcffd0(%eax)
	//thiscpu->cpu_ts.ts_esp0 = KSTACKTOP - i * (KSTKSIZE + KSTKGAP);
	thiscpu->cpu_ts.ts_ss0 = GD_KD;
f010369b:	e8 86 23 00 00       	call   f0105a26 <cpunum>
f01036a0:	6b c0 74             	imul   $0x74,%eax,%eax
f01036a3:	66 c7 80 34 00 23 f0 	movw   $0x10,-0xfdcffcc(%eax)
f01036aa:	10 00 
	thiscpu->cpu_ts.ts_iomb = sizeof(struct Taskstate);
f01036ac:	e8 75 23 00 00       	call   f0105a26 <cpunum>
f01036b1:	6b c0 74             	imul   $0x74,%eax,%eax
f01036b4:	66 c7 80 92 00 23 f0 	movw   $0x68,-0xfdcff6e(%eax)
f01036bb:	68 00 

	// Initialize the TSS slot of the gdt.
	gdt[(GD_TSS0 >> 3) + i] = SEG16(STS_T32A, (uint32_t) (&thiscpu->cpu_ts),
f01036bd:	8d 5e 05             	lea    0x5(%esi),%ebx
f01036c0:	e8 61 23 00 00       	call   f0105a26 <cpunum>
f01036c5:	89 c7                	mov    %eax,%edi
f01036c7:	e8 5a 23 00 00       	call   f0105a26 <cpunum>
f01036cc:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01036cf:	e8 52 23 00 00       	call   f0105a26 <cpunum>
f01036d4:	66 c7 04 dd 40 03 12 	movw   $0x67,-0xfedfcc0(,%ebx,8)
f01036db:	f0 67 00 
f01036de:	6b ff 74             	imul   $0x74,%edi,%edi
f01036e1:	81 c7 2c 00 23 f0    	add    $0xf023002c,%edi
f01036e7:	66 89 3c dd 42 03 12 	mov    %di,-0xfedfcbe(,%ebx,8)
f01036ee:	f0 
f01036ef:	6b 55 e4 74          	imul   $0x74,-0x1c(%ebp),%edx
f01036f3:	81 c2 2c 00 23 f0    	add    $0xf023002c,%edx
f01036f9:	c1 ea 10             	shr    $0x10,%edx
f01036fc:	88 14 dd 44 03 12 f0 	mov    %dl,-0xfedfcbc(,%ebx,8)
f0103703:	c6 04 dd 46 03 12 f0 	movb   $0x40,-0xfedfcba(,%ebx,8)
f010370a:	40 
f010370b:	6b c0 74             	imul   $0x74,%eax,%eax
f010370e:	05 2c 00 23 f0       	add    $0xf023002c,%eax
f0103713:	c1 e8 18             	shr    $0x18,%eax
f0103716:	88 04 dd 47 03 12 f0 	mov    %al,-0xfedfcb9(,%ebx,8)
					sizeof(struct Taskstate) - 1, 0);
	gdt[(GD_TSS0 >> 3) + i].sd_s = 0;
f010371d:	c6 04 dd 45 03 12 f0 	movb   $0x89,-0xfedfcbb(,%ebx,8)
f0103724:	89 
}

static inline void
ltr(uint16_t sel)
{
	asm volatile("ltr %0" : : "r" (sel));
f0103725:	8d 34 f5 28 00 00 00 	lea    0x28(,%esi,8),%esi
f010372c:	0f 00 de             	ltr    %si
}

static inline void
lidt(void *p)
{
	asm volatile("lidt (%0)" : : "r" (p));
f010372f:	b8 ac 03 12 f0       	mov    $0xf01203ac,%eax
f0103734:	0f 01 18             	lidtl  (%eax)
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0 + (i << 3));

	// Load the IDT
	lidt(&idt_pd);
}
f0103737:	83 c4 1c             	add    $0x1c,%esp
f010373a:	5b                   	pop    %ebx
f010373b:	5e                   	pop    %esi
f010373c:	5f                   	pop    %edi
f010373d:	5d                   	pop    %ebp
f010373e:	c3                   	ret    

f010373f <trap_init>:
}


void
trap_init(void)
{
f010373f:	55                   	push   %ebp
f0103740:	89 e5                	mov    %esp,%ebp
f0103742:	83 ec 08             	sub    $0x8,%esp
	extern struct Segdesc gdt[];

	// LAB 3: Your code here.

	SETGATE(idt[T_DIVIDE], 0, GD_KT, t_divide, 0);
f0103745:	b8 ca 40 10 f0       	mov    $0xf01040ca,%eax
f010374a:	66 a3 60 f2 22 f0    	mov    %ax,0xf022f260
f0103750:	66 c7 05 62 f2 22 f0 	movw   $0x8,0xf022f262
f0103757:	08 00 
f0103759:	c6 05 64 f2 22 f0 00 	movb   $0x0,0xf022f264
f0103760:	c6 05 65 f2 22 f0 8e 	movb   $0x8e,0xf022f265
f0103767:	c1 e8 10             	shr    $0x10,%eax
f010376a:	66 a3 66 f2 22 f0    	mov    %ax,0xf022f266
	SETGATE(idt[T_DEBUG], 0, GD_KT, t_debug, 0);
f0103770:	b8 d4 40 10 f0       	mov    $0xf01040d4,%eax
f0103775:	66 a3 68 f2 22 f0    	mov    %ax,0xf022f268
f010377b:	66 c7 05 6a f2 22 f0 	movw   $0x8,0xf022f26a
f0103782:	08 00 
f0103784:	c6 05 6c f2 22 f0 00 	movb   $0x0,0xf022f26c
f010378b:	c6 05 6d f2 22 f0 8e 	movb   $0x8e,0xf022f26d
f0103792:	c1 e8 10             	shr    $0x10,%eax
f0103795:	66 a3 6e f2 22 f0    	mov    %ax,0xf022f26e
	SETGATE(idt[T_NMI], 0, GD_KT, t_nmi, 0);
f010379b:	b8 da 40 10 f0       	mov    $0xf01040da,%eax
f01037a0:	66 a3 70 f2 22 f0    	mov    %ax,0xf022f270
f01037a6:	66 c7 05 72 f2 22 f0 	movw   $0x8,0xf022f272
f01037ad:	08 00 
f01037af:	c6 05 74 f2 22 f0 00 	movb   $0x0,0xf022f274
f01037b6:	c6 05 75 f2 22 f0 8e 	movb   $0x8e,0xf022f275
f01037bd:	c1 e8 10             	shr    $0x10,%eax
f01037c0:	66 a3 76 f2 22 f0    	mov    %ax,0xf022f276
	SETGATE(idt[T_BRKPT], 0, GD_KT, t_brkpt, 3);
f01037c6:	b8 e0 40 10 f0       	mov    $0xf01040e0,%eax
f01037cb:	66 a3 78 f2 22 f0    	mov    %ax,0xf022f278
f01037d1:	66 c7 05 7a f2 22 f0 	movw   $0x8,0xf022f27a
f01037d8:	08 00 
f01037da:	c6 05 7c f2 22 f0 00 	movb   $0x0,0xf022f27c
f01037e1:	c6 05 7d f2 22 f0 ee 	movb   $0xee,0xf022f27d
f01037e8:	c1 e8 10             	shr    $0x10,%eax
f01037eb:	66 a3 7e f2 22 f0    	mov    %ax,0xf022f27e
	SETGATE(idt[T_OFLOW], 0, GD_KT, t_oflow, 0);
f01037f1:	b8 e6 40 10 f0       	mov    $0xf01040e6,%eax
f01037f6:	66 a3 80 f2 22 f0    	mov    %ax,0xf022f280
f01037fc:	66 c7 05 82 f2 22 f0 	movw   $0x8,0xf022f282
f0103803:	08 00 
f0103805:	c6 05 84 f2 22 f0 00 	movb   $0x0,0xf022f284
f010380c:	c6 05 85 f2 22 f0 8e 	movb   $0x8e,0xf022f285
f0103813:	c1 e8 10             	shr    $0x10,%eax
f0103816:	66 a3 86 f2 22 f0    	mov    %ax,0xf022f286
	SETGATE(idt[T_BOUND], 0, GD_KT, t_bound, 0);
f010381c:	b8 ec 40 10 f0       	mov    $0xf01040ec,%eax
f0103821:	66 a3 88 f2 22 f0    	mov    %ax,0xf022f288
f0103827:	66 c7 05 8a f2 22 f0 	movw   $0x8,0xf022f28a
f010382e:	08 00 
f0103830:	c6 05 8c f2 22 f0 00 	movb   $0x0,0xf022f28c
f0103837:	c6 05 8d f2 22 f0 8e 	movb   $0x8e,0xf022f28d
f010383e:	c1 e8 10             	shr    $0x10,%eax
f0103841:	66 a3 8e f2 22 f0    	mov    %ax,0xf022f28e
	SETGATE(idt[T_ILLOP], 0, GD_KT, t_illop, 0);
f0103847:	b8 f2 40 10 f0       	mov    $0xf01040f2,%eax
f010384c:	66 a3 90 f2 22 f0    	mov    %ax,0xf022f290
f0103852:	66 c7 05 92 f2 22 f0 	movw   $0x8,0xf022f292
f0103859:	08 00 
f010385b:	c6 05 94 f2 22 f0 00 	movb   $0x0,0xf022f294
f0103862:	c6 05 95 f2 22 f0 8e 	movb   $0x8e,0xf022f295
f0103869:	c1 e8 10             	shr    $0x10,%eax
f010386c:	66 a3 96 f2 22 f0    	mov    %ax,0xf022f296
	SETGATE(idt[T_DEVICE], 0, GD_KT, t_device, 0);
f0103872:	b8 f8 40 10 f0       	mov    $0xf01040f8,%eax
f0103877:	66 a3 98 f2 22 f0    	mov    %ax,0xf022f298
f010387d:	66 c7 05 9a f2 22 f0 	movw   $0x8,0xf022f29a
f0103884:	08 00 
f0103886:	c6 05 9c f2 22 f0 00 	movb   $0x0,0xf022f29c
f010388d:	c6 05 9d f2 22 f0 8e 	movb   $0x8e,0xf022f29d
f0103894:	c1 e8 10             	shr    $0x10,%eax
f0103897:	66 a3 9e f2 22 f0    	mov    %ax,0xf022f29e
	SETGATE(idt[T_DBLFLT], 0, GD_KT, t_dblflt, 0);
f010389d:	b8 fe 40 10 f0       	mov    $0xf01040fe,%eax
f01038a2:	66 a3 a0 f2 22 f0    	mov    %ax,0xf022f2a0
f01038a8:	66 c7 05 a2 f2 22 f0 	movw   $0x8,0xf022f2a2
f01038af:	08 00 
f01038b1:	c6 05 a4 f2 22 f0 00 	movb   $0x0,0xf022f2a4
f01038b8:	c6 05 a5 f2 22 f0 8e 	movb   $0x8e,0xf022f2a5
f01038bf:	c1 e8 10             	shr    $0x10,%eax
f01038c2:	66 a3 a6 f2 22 f0    	mov    %ax,0xf022f2a6
	SETGATE(idt[T_TSS], 0, GD_KT, t_tss, 0);
f01038c8:	b8 02 41 10 f0       	mov    $0xf0104102,%eax
f01038cd:	66 a3 b0 f2 22 f0    	mov    %ax,0xf022f2b0
f01038d3:	66 c7 05 b2 f2 22 f0 	movw   $0x8,0xf022f2b2
f01038da:	08 00 
f01038dc:	c6 05 b4 f2 22 f0 00 	movb   $0x0,0xf022f2b4
f01038e3:	c6 05 b5 f2 22 f0 8e 	movb   $0x8e,0xf022f2b5
f01038ea:	c1 e8 10             	shr    $0x10,%eax
f01038ed:	66 a3 b6 f2 22 f0    	mov    %ax,0xf022f2b6
	SETGATE(idt[T_SEGNP], 0, GD_KT, t_segnp, 0);
f01038f3:	b8 06 41 10 f0       	mov    $0xf0104106,%eax
f01038f8:	66 a3 b8 f2 22 f0    	mov    %ax,0xf022f2b8
f01038fe:	66 c7 05 ba f2 22 f0 	movw   $0x8,0xf022f2ba
f0103905:	08 00 
f0103907:	c6 05 bc f2 22 f0 00 	movb   $0x0,0xf022f2bc
f010390e:	c6 05 bd f2 22 f0 8e 	movb   $0x8e,0xf022f2bd
f0103915:	c1 e8 10             	shr    $0x10,%eax
f0103918:	66 a3 be f2 22 f0    	mov    %ax,0xf022f2be
	SETGATE(idt[T_STACK], 0, GD_KT, t_stack, 0);
f010391e:	b8 0a 41 10 f0       	mov    $0xf010410a,%eax
f0103923:	66 a3 c0 f2 22 f0    	mov    %ax,0xf022f2c0
f0103929:	66 c7 05 c2 f2 22 f0 	movw   $0x8,0xf022f2c2
f0103930:	08 00 
f0103932:	c6 05 c4 f2 22 f0 00 	movb   $0x0,0xf022f2c4
f0103939:	c6 05 c5 f2 22 f0 8e 	movb   $0x8e,0xf022f2c5
f0103940:	c1 e8 10             	shr    $0x10,%eax
f0103943:	66 a3 c6 f2 22 f0    	mov    %ax,0xf022f2c6
	SETGATE(idt[T_GPFLT], 0, GD_KT, t_gpflt, 0);
f0103949:	b8 0e 41 10 f0       	mov    $0xf010410e,%eax
f010394e:	66 a3 c8 f2 22 f0    	mov    %ax,0xf022f2c8
f0103954:	66 c7 05 ca f2 22 f0 	movw   $0x8,0xf022f2ca
f010395b:	08 00 
f010395d:	c6 05 cc f2 22 f0 00 	movb   $0x0,0xf022f2cc
f0103964:	c6 05 cd f2 22 f0 8e 	movb   $0x8e,0xf022f2cd
f010396b:	c1 e8 10             	shr    $0x10,%eax
f010396e:	66 a3 ce f2 22 f0    	mov    %ax,0xf022f2ce
	SETGATE(idt[T_PGFLT], 0, GD_KT, t_pgflt, 0);
f0103974:	b8 12 41 10 f0       	mov    $0xf0104112,%eax
f0103979:	66 a3 d0 f2 22 f0    	mov    %ax,0xf022f2d0
f010397f:	66 c7 05 d2 f2 22 f0 	movw   $0x8,0xf022f2d2
f0103986:	08 00 
f0103988:	c6 05 d4 f2 22 f0 00 	movb   $0x0,0xf022f2d4
f010398f:	c6 05 d5 f2 22 f0 8e 	movb   $0x8e,0xf022f2d5
f0103996:	c1 e8 10             	shr    $0x10,%eax
f0103999:	66 a3 d6 f2 22 f0    	mov    %ax,0xf022f2d6
	SETGATE(idt[T_FPERR], 0, GD_KT, t_fperr, 0);
f010399f:	b8 16 41 10 f0       	mov    $0xf0104116,%eax
f01039a4:	66 a3 e0 f2 22 f0    	mov    %ax,0xf022f2e0
f01039aa:	66 c7 05 e2 f2 22 f0 	movw   $0x8,0xf022f2e2
f01039b1:	08 00 
f01039b3:	c6 05 e4 f2 22 f0 00 	movb   $0x0,0xf022f2e4
f01039ba:	c6 05 e5 f2 22 f0 8e 	movb   $0x8e,0xf022f2e5
f01039c1:	c1 e8 10             	shr    $0x10,%eax
f01039c4:	66 a3 e6 f2 22 f0    	mov    %ax,0xf022f2e6
	SETGATE(idt[T_ALIGN], 0, GD_KT, t_align, 0);
f01039ca:	b8 1c 41 10 f0       	mov    $0xf010411c,%eax
f01039cf:	66 a3 e8 f2 22 f0    	mov    %ax,0xf022f2e8
f01039d5:	66 c7 05 ea f2 22 f0 	movw   $0x8,0xf022f2ea
f01039dc:	08 00 
f01039de:	c6 05 ec f2 22 f0 00 	movb   $0x0,0xf022f2ec
f01039e5:	c6 05 ed f2 22 f0 8e 	movb   $0x8e,0xf022f2ed
f01039ec:	c1 e8 10             	shr    $0x10,%eax
f01039ef:	66 a3 ee f2 22 f0    	mov    %ax,0xf022f2ee
	SETGATE(idt[T_MCHK], 0, GD_KT, t_mchk, 0);
f01039f5:	b8 20 41 10 f0       	mov    $0xf0104120,%eax
f01039fa:	66 a3 f0 f2 22 f0    	mov    %ax,0xf022f2f0
f0103a00:	66 c7 05 f2 f2 22 f0 	movw   $0x8,0xf022f2f2
f0103a07:	08 00 
f0103a09:	c6 05 f4 f2 22 f0 00 	movb   $0x0,0xf022f2f4
f0103a10:	c6 05 f5 f2 22 f0 8e 	movb   $0x8e,0xf022f2f5
f0103a17:	c1 e8 10             	shr    $0x10,%eax
f0103a1a:	66 a3 f6 f2 22 f0    	mov    %ax,0xf022f2f6
	SETGATE(idt[T_SIMDERR], 0, GD_KT, t_simderr, 0);
f0103a20:	b8 26 41 10 f0       	mov    $0xf0104126,%eax
f0103a25:	66 a3 f8 f2 22 f0    	mov    %ax,0xf022f2f8
f0103a2b:	66 c7 05 fa f2 22 f0 	movw   $0x8,0xf022f2fa
f0103a32:	08 00 
f0103a34:	c6 05 fc f2 22 f0 00 	movb   $0x0,0xf022f2fc
f0103a3b:	c6 05 fd f2 22 f0 8e 	movb   $0x8e,0xf022f2fd
f0103a42:	c1 e8 10             	shr    $0x10,%eax
f0103a45:	66 a3 fe f2 22 f0    	mov    %ax,0xf022f2fe

	SETGATE(idt[T_SYSCALL], 0, GD_KT, t_syscall, 3);
f0103a4b:	b8 2c 41 10 f0       	mov    $0xf010412c,%eax
f0103a50:	66 a3 e0 f3 22 f0    	mov    %ax,0xf022f3e0
f0103a56:	66 c7 05 e2 f3 22 f0 	movw   $0x8,0xf022f3e2
f0103a5d:	08 00 
f0103a5f:	c6 05 e4 f3 22 f0 00 	movb   $0x0,0xf022f3e4
f0103a66:	c6 05 e5 f3 22 f0 ee 	movb   $0xee,0xf022f3e5
f0103a6d:	c1 e8 10             	shr    $0x10,%eax
f0103a70:	66 a3 e6 f3 22 f0    	mov    %ax,0xf022f3e6

	SETGATE(idt[IRQ_OFFSET + IRQ_TIMER], 0, GD_KT, irq_timer, 0);
f0103a76:	b8 32 41 10 f0       	mov    $0xf0104132,%eax
f0103a7b:	66 a3 60 f3 22 f0    	mov    %ax,0xf022f360
f0103a81:	66 c7 05 62 f3 22 f0 	movw   $0x8,0xf022f362
f0103a88:	08 00 
f0103a8a:	c6 05 64 f3 22 f0 00 	movb   $0x0,0xf022f364
f0103a91:	c6 05 65 f3 22 f0 8e 	movb   $0x8e,0xf022f365
f0103a98:	c1 e8 10             	shr    $0x10,%eax
f0103a9b:	66 a3 66 f3 22 f0    	mov    %ax,0xf022f366
	SETGATE(idt[IRQ_OFFSET + IRQ_KBD], 0, GD_KT, irq_kbd, 0);
f0103aa1:	b8 38 41 10 f0       	mov    $0xf0104138,%eax
f0103aa6:	66 a3 68 f3 22 f0    	mov    %ax,0xf022f368
f0103aac:	66 c7 05 6a f3 22 f0 	movw   $0x8,0xf022f36a
f0103ab3:	08 00 
f0103ab5:	c6 05 6c f3 22 f0 00 	movb   $0x0,0xf022f36c
f0103abc:	c6 05 6d f3 22 f0 8e 	movb   $0x8e,0xf022f36d
f0103ac3:	c1 e8 10             	shr    $0x10,%eax
f0103ac6:	66 a3 6e f3 22 f0    	mov    %ax,0xf022f36e
	SETGATE(idt[IRQ_OFFSET + IRQ_SERIAL], 0, GD_KT, irq_serial, 0);
f0103acc:	b8 3e 41 10 f0       	mov    $0xf010413e,%eax
f0103ad1:	66 a3 80 f3 22 f0    	mov    %ax,0xf022f380
f0103ad7:	66 c7 05 82 f3 22 f0 	movw   $0x8,0xf022f382
f0103ade:	08 00 
f0103ae0:	c6 05 84 f3 22 f0 00 	movb   $0x0,0xf022f384
f0103ae7:	c6 05 85 f3 22 f0 8e 	movb   $0x8e,0xf022f385
f0103aee:	c1 e8 10             	shr    $0x10,%eax
f0103af1:	66 a3 86 f3 22 f0    	mov    %ax,0xf022f386
	SETGATE(idt[IRQ_OFFSET + IRQ_SPURIOUS], 0, GD_KT, irq_spurious, 0);
f0103af7:	b8 44 41 10 f0       	mov    $0xf0104144,%eax
f0103afc:	66 a3 98 f3 22 f0    	mov    %ax,0xf022f398
f0103b02:	66 c7 05 9a f3 22 f0 	movw   $0x8,0xf022f39a
f0103b09:	08 00 
f0103b0b:	c6 05 9c f3 22 f0 00 	movb   $0x0,0xf022f39c
f0103b12:	c6 05 9d f3 22 f0 8e 	movb   $0x8e,0xf022f39d
f0103b19:	c1 e8 10             	shr    $0x10,%eax
f0103b1c:	66 a3 9e f3 22 f0    	mov    %ax,0xf022f39e
	SETGATE(idt[IRQ_OFFSET + IRQ_IDE], 0, GD_KT, irq_ide, 0);
f0103b22:	b8 4a 41 10 f0       	mov    $0xf010414a,%eax
f0103b27:	66 a3 d0 f3 22 f0    	mov    %ax,0xf022f3d0
f0103b2d:	66 c7 05 d2 f3 22 f0 	movw   $0x8,0xf022f3d2
f0103b34:	08 00 
f0103b36:	c6 05 d4 f3 22 f0 00 	movb   $0x0,0xf022f3d4
f0103b3d:	c6 05 d5 f3 22 f0 8e 	movb   $0x8e,0xf022f3d5
f0103b44:	c1 e8 10             	shr    $0x10,%eax
f0103b47:	66 a3 d6 f3 22 f0    	mov    %ax,0xf022f3d6
	SETGATE(idt[IRQ_OFFSET + IRQ_ERROR], 0, GD_KT, irq_error, 0);
f0103b4d:	b8 50 41 10 f0       	mov    $0xf0104150,%eax
f0103b52:	66 a3 f8 f3 22 f0    	mov    %ax,0xf022f3f8
f0103b58:	66 c7 05 fa f3 22 f0 	movw   $0x8,0xf022f3fa
f0103b5f:	08 00 
f0103b61:	c6 05 fc f3 22 f0 00 	movb   $0x0,0xf022f3fc
f0103b68:	c6 05 fd f3 22 f0 8e 	movb   $0x8e,0xf022f3fd
f0103b6f:	c1 e8 10             	shr    $0x10,%eax
f0103b72:	66 a3 fe f3 22 f0    	mov    %ax,0xf022f3fe
	// Per-CPU setup 
	trap_init_percpu();
f0103b78:	e8 f5 fa ff ff       	call   f0103672 <trap_init_percpu>
}
f0103b7d:	c9                   	leave  
f0103b7e:	c3                   	ret    

f0103b7f <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f0103b7f:	55                   	push   %ebp
f0103b80:	89 e5                	mov    %esp,%ebp
f0103b82:	53                   	push   %ebx
f0103b83:	83 ec 0c             	sub    $0xc,%esp
f0103b86:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f0103b89:	ff 33                	pushl  (%ebx)
f0103b8b:	68 60 73 10 f0       	push   $0xf0107360
f0103b90:	e8 c9 fa ff ff       	call   f010365e <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f0103b95:	83 c4 08             	add    $0x8,%esp
f0103b98:	ff 73 04             	pushl  0x4(%ebx)
f0103b9b:	68 6f 73 10 f0       	push   $0xf010736f
f0103ba0:	e8 b9 fa ff ff       	call   f010365e <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f0103ba5:	83 c4 08             	add    $0x8,%esp
f0103ba8:	ff 73 08             	pushl  0x8(%ebx)
f0103bab:	68 7e 73 10 f0       	push   $0xf010737e
f0103bb0:	e8 a9 fa ff ff       	call   f010365e <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f0103bb5:	83 c4 08             	add    $0x8,%esp
f0103bb8:	ff 73 0c             	pushl  0xc(%ebx)
f0103bbb:	68 8d 73 10 f0       	push   $0xf010738d
f0103bc0:	e8 99 fa ff ff       	call   f010365e <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f0103bc5:	83 c4 08             	add    $0x8,%esp
f0103bc8:	ff 73 10             	pushl  0x10(%ebx)
f0103bcb:	68 9c 73 10 f0       	push   $0xf010739c
f0103bd0:	e8 89 fa ff ff       	call   f010365e <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f0103bd5:	83 c4 08             	add    $0x8,%esp
f0103bd8:	ff 73 14             	pushl  0x14(%ebx)
f0103bdb:	68 ab 73 10 f0       	push   $0xf01073ab
f0103be0:	e8 79 fa ff ff       	call   f010365e <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f0103be5:	83 c4 08             	add    $0x8,%esp
f0103be8:	ff 73 18             	pushl  0x18(%ebx)
f0103beb:	68 ba 73 10 f0       	push   $0xf01073ba
f0103bf0:	e8 69 fa ff ff       	call   f010365e <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f0103bf5:	83 c4 08             	add    $0x8,%esp
f0103bf8:	ff 73 1c             	pushl  0x1c(%ebx)
f0103bfb:	68 c9 73 10 f0       	push   $0xf01073c9
f0103c00:	e8 59 fa ff ff       	call   f010365e <cprintf>
}
f0103c05:	83 c4 10             	add    $0x10,%esp
f0103c08:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103c0b:	c9                   	leave  
f0103c0c:	c3                   	ret    

f0103c0d <print_trapframe>:
	lidt(&idt_pd);
}

void
print_trapframe(struct Trapframe *tf)
{
f0103c0d:	55                   	push   %ebp
f0103c0e:	89 e5                	mov    %esp,%ebp
f0103c10:	56                   	push   %esi
f0103c11:	53                   	push   %ebx
f0103c12:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p from CPU %d\n", tf, cpunum());
f0103c15:	e8 0c 1e 00 00       	call   f0105a26 <cpunum>
f0103c1a:	83 ec 04             	sub    $0x4,%esp
f0103c1d:	50                   	push   %eax
f0103c1e:	53                   	push   %ebx
f0103c1f:	68 2d 74 10 f0       	push   $0xf010742d
f0103c24:	e8 35 fa ff ff       	call   f010365e <cprintf>
	print_regs(&tf->tf_regs);
f0103c29:	89 1c 24             	mov    %ebx,(%esp)
f0103c2c:	e8 4e ff ff ff       	call   f0103b7f <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f0103c31:	83 c4 08             	add    $0x8,%esp
f0103c34:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f0103c38:	50                   	push   %eax
f0103c39:	68 4b 74 10 f0       	push   $0xf010744b
f0103c3e:	e8 1b fa ff ff       	call   f010365e <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f0103c43:	83 c4 08             	add    $0x8,%esp
f0103c46:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f0103c4a:	50                   	push   %eax
f0103c4b:	68 5e 74 10 f0       	push   $0xf010745e
f0103c50:	e8 09 fa ff ff       	call   f010365e <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103c55:	8b 43 28             	mov    0x28(%ebx),%eax
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < ARRAY_SIZE(excnames))
f0103c58:	83 c4 10             	add    $0x10,%esp
f0103c5b:	83 f8 13             	cmp    $0x13,%eax
f0103c5e:	77 09                	ja     f0103c69 <print_trapframe+0x5c>
		return excnames[trapno];
f0103c60:	8b 14 85 00 77 10 f0 	mov    -0xfef8900(,%eax,4),%edx
f0103c67:	eb 1f                	jmp    f0103c88 <print_trapframe+0x7b>
	if (trapno == T_SYSCALL)
f0103c69:	83 f8 30             	cmp    $0x30,%eax
f0103c6c:	74 15                	je     f0103c83 <print_trapframe+0x76>
		return "System call";
	if (trapno >= IRQ_OFFSET && trapno < IRQ_OFFSET + 16)
f0103c6e:	8d 50 e0             	lea    -0x20(%eax),%edx
		return "Hardware Interrupt";
	return "(unknown trap)";
f0103c71:	83 fa 10             	cmp    $0x10,%edx
f0103c74:	b9 f7 73 10 f0       	mov    $0xf01073f7,%ecx
f0103c79:	ba e4 73 10 f0       	mov    $0xf01073e4,%edx
f0103c7e:	0f 43 d1             	cmovae %ecx,%edx
f0103c81:	eb 05                	jmp    f0103c88 <print_trapframe+0x7b>
	};

	if (trapno < ARRAY_SIZE(excnames))
		return excnames[trapno];
	if (trapno == T_SYSCALL)
		return "System call";
f0103c83:	ba d8 73 10 f0       	mov    $0xf01073d8,%edx
{
	cprintf("TRAP frame at %p from CPU %d\n", tf, cpunum());
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103c88:	83 ec 04             	sub    $0x4,%esp
f0103c8b:	52                   	push   %edx
f0103c8c:	50                   	push   %eax
f0103c8d:	68 71 74 10 f0       	push   $0xf0107471
f0103c92:	e8 c7 f9 ff ff       	call   f010365e <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0103c97:	83 c4 10             	add    $0x10,%esp
f0103c9a:	3b 1d 60 fa 22 f0    	cmp    0xf022fa60,%ebx
f0103ca0:	75 1a                	jne    f0103cbc <print_trapframe+0xaf>
f0103ca2:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103ca6:	75 14                	jne    f0103cbc <print_trapframe+0xaf>

static inline uint32_t
rcr2(void)
{
	uint32_t val;
	asm volatile("movl %%cr2,%0" : "=r" (val));
f0103ca8:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f0103cab:	83 ec 08             	sub    $0x8,%esp
f0103cae:	50                   	push   %eax
f0103caf:	68 83 74 10 f0       	push   $0xf0107483
f0103cb4:	e8 a5 f9 ff ff       	call   f010365e <cprintf>
f0103cb9:	83 c4 10             	add    $0x10,%esp
	cprintf("  err  0x%08x", tf->tf_err);
f0103cbc:	83 ec 08             	sub    $0x8,%esp
f0103cbf:	ff 73 2c             	pushl  0x2c(%ebx)
f0103cc2:	68 92 74 10 f0       	push   $0xf0107492
f0103cc7:	e8 92 f9 ff ff       	call   f010365e <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f0103ccc:	83 c4 10             	add    $0x10,%esp
f0103ccf:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103cd3:	75 49                	jne    f0103d1e <print_trapframe+0x111>
		cprintf(" [%s, %s, %s]\n",
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
f0103cd5:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f0103cd8:	89 c2                	mov    %eax,%edx
f0103cda:	83 e2 01             	and    $0x1,%edx
f0103cdd:	ba 11 74 10 f0       	mov    $0xf0107411,%edx
f0103ce2:	b9 06 74 10 f0       	mov    $0xf0107406,%ecx
f0103ce7:	0f 44 ca             	cmove  %edx,%ecx
f0103cea:	89 c2                	mov    %eax,%edx
f0103cec:	83 e2 02             	and    $0x2,%edx
f0103cef:	ba 23 74 10 f0       	mov    $0xf0107423,%edx
f0103cf4:	be 1d 74 10 f0       	mov    $0xf010741d,%esi
f0103cf9:	0f 45 d6             	cmovne %esi,%edx
f0103cfc:	83 e0 04             	and    $0x4,%eax
f0103cff:	be 5d 75 10 f0       	mov    $0xf010755d,%esi
f0103d04:	b8 28 74 10 f0       	mov    $0xf0107428,%eax
f0103d09:	0f 44 c6             	cmove  %esi,%eax
f0103d0c:	51                   	push   %ecx
f0103d0d:	52                   	push   %edx
f0103d0e:	50                   	push   %eax
f0103d0f:	68 a0 74 10 f0       	push   $0xf01074a0
f0103d14:	e8 45 f9 ff ff       	call   f010365e <cprintf>
f0103d19:	83 c4 10             	add    $0x10,%esp
f0103d1c:	eb 10                	jmp    f0103d2e <print_trapframe+0x121>
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f0103d1e:	83 ec 0c             	sub    $0xc,%esp
f0103d21:	68 a4 72 10 f0       	push   $0xf01072a4
f0103d26:	e8 33 f9 ff ff       	call   f010365e <cprintf>
f0103d2b:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f0103d2e:	83 ec 08             	sub    $0x8,%esp
f0103d31:	ff 73 30             	pushl  0x30(%ebx)
f0103d34:	68 af 74 10 f0       	push   $0xf01074af
f0103d39:	e8 20 f9 ff ff       	call   f010365e <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f0103d3e:	83 c4 08             	add    $0x8,%esp
f0103d41:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f0103d45:	50                   	push   %eax
f0103d46:	68 be 74 10 f0       	push   $0xf01074be
f0103d4b:	e8 0e f9 ff ff       	call   f010365e <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f0103d50:	83 c4 08             	add    $0x8,%esp
f0103d53:	ff 73 38             	pushl  0x38(%ebx)
f0103d56:	68 d1 74 10 f0       	push   $0xf01074d1
f0103d5b:	e8 fe f8 ff ff       	call   f010365e <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f0103d60:	83 c4 10             	add    $0x10,%esp
f0103d63:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0103d67:	74 25                	je     f0103d8e <print_trapframe+0x181>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f0103d69:	83 ec 08             	sub    $0x8,%esp
f0103d6c:	ff 73 3c             	pushl  0x3c(%ebx)
f0103d6f:	68 e0 74 10 f0       	push   $0xf01074e0
f0103d74:	e8 e5 f8 ff ff       	call   f010365e <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f0103d79:	83 c4 08             	add    $0x8,%esp
f0103d7c:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f0103d80:	50                   	push   %eax
f0103d81:	68 ef 74 10 f0       	push   $0xf01074ef
f0103d86:	e8 d3 f8 ff ff       	call   f010365e <cprintf>
f0103d8b:	83 c4 10             	add    $0x10,%esp
	}
}
f0103d8e:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0103d91:	5b                   	pop    %ebx
f0103d92:	5e                   	pop    %esi
f0103d93:	5d                   	pop    %ebp
f0103d94:	c3                   	ret    

f0103d95 <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f0103d95:	55                   	push   %ebp
f0103d96:	89 e5                	mov    %esp,%ebp
f0103d98:	57                   	push   %edi
f0103d99:	56                   	push   %esi
f0103d9a:	53                   	push   %ebx
f0103d9b:	83 ec 0c             	sub    $0xc,%esp
f0103d9e:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103da1:	0f 20 d6             	mov    %cr2,%esi
	fault_va = rcr2();

	// Handle kernel-mode page faults.

	// LAB 3: Your code here.
	if (tf->tf_cs == GD_KT) {
f0103da4:	66 83 7b 34 08       	cmpw   $0x8,0x34(%ebx)
f0103da9:	75 17                	jne    f0103dc2 <page_fault_handler+0x2d>
		// Trapped from kernel mode
		panic("page_fault_handler: page fault in kernel mode");
f0103dab:	83 ec 04             	sub    $0x4,%esp
f0103dae:	68 a8 76 10 f0       	push   $0xf01076a8
f0103db3:	68 66 01 00 00       	push   $0x166
f0103db8:	68 02 75 10 f0       	push   $0xf0107502
f0103dbd:	e8 7e c2 ff ff       	call   f0100040 <_panic>
	//   To change what the user environment runs, modify 'curenv->env_tf'
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.
    
    if(curenv->env_pgfault_upcall!=NULL){
f0103dc2:	e8 5f 1c 00 00       	call   f0105a26 <cpunum>
f0103dc7:	6b c0 74             	imul   $0x74,%eax,%eax
f0103dca:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f0103dd0:	83 78 64 00          	cmpl   $0x0,0x64(%eax)
f0103dd4:	0f 84 8b 00 00 00    	je     f0103e65 <page_fault_handler+0xd0>
        struct UTrapframe *utf;
        uintptr_t utf_addr;  
        if(tf->tf_esp >= UXSTACKTOP - PGSIZE && tf->tf_esp < UXSTACKTOP){
f0103dda:	8b 43 3c             	mov    0x3c(%ebx),%eax
f0103ddd:	8d 90 00 10 40 11    	lea    0x11401000(%eax),%edx
            utf_addr = tf->tf_esp - sizeof(struct UTrapframe) - 4;
f0103de3:	83 e8 38             	sub    $0x38,%eax
f0103de6:	81 fa ff 0f 00 00    	cmp    $0xfff,%edx
f0103dec:	ba cc ff bf ee       	mov    $0xeebfffcc,%edx
f0103df1:	0f 46 d0             	cmovbe %eax,%edx
f0103df4:	89 d7                	mov    %edx,%edi
        }
        else{
            utf_addr = UXSTACKTOP - sizeof(struct UTrapframe);
        }
        user_mem_assert(curenv, (void *) utf_addr, sizeof(struct UTrapframe), PTE_W);        
f0103df6:	e8 2b 1c 00 00       	call   f0105a26 <cpunum>
f0103dfb:	6a 02                	push   $0x2
f0103dfd:	6a 34                	push   $0x34
f0103dff:	57                   	push   %edi
f0103e00:	6b c0 74             	imul   $0x74,%eax,%eax
f0103e03:	ff b0 28 00 23 f0    	pushl  -0xfdcffd8(%eax)
f0103e09:	e8 37 ef ff ff       	call   f0102d45 <user_mem_assert>

        utf = (struct UTrapframe *) utf_addr;
        utf->utf_fault_va = fault_va;
f0103e0e:	89 fa                	mov    %edi,%edx
f0103e10:	89 37                	mov    %esi,(%edi)
        utf->utf_err = tf->tf_err;
f0103e12:	8b 43 2c             	mov    0x2c(%ebx),%eax
f0103e15:	89 47 04             	mov    %eax,0x4(%edi)
        utf->utf_regs = tf->tf_regs;
f0103e18:	8d 7f 08             	lea    0x8(%edi),%edi
f0103e1b:	b9 08 00 00 00       	mov    $0x8,%ecx
f0103e20:	89 de                	mov    %ebx,%esi
f0103e22:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
        utf->utf_eip = tf->tf_eip;
f0103e24:	8b 43 30             	mov    0x30(%ebx),%eax
f0103e27:	89 42 28             	mov    %eax,0x28(%edx)
        utf->utf_eflags = tf->tf_eflags;
f0103e2a:	8b 43 38             	mov    0x38(%ebx),%eax
f0103e2d:	89 d7                	mov    %edx,%edi
f0103e2f:	89 42 2c             	mov    %eax,0x2c(%edx)
        utf->utf_esp = tf->tf_esp;
f0103e32:	8b 43 3c             	mov    0x3c(%ebx),%eax
f0103e35:	89 42 30             	mov    %eax,0x30(%edx)

        tf->tf_eip = (uintptr_t) curenv->env_pgfault_upcall;
f0103e38:	e8 e9 1b 00 00       	call   f0105a26 <cpunum>
f0103e3d:	6b c0 74             	imul   $0x74,%eax,%eax
f0103e40:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f0103e46:	8b 40 64             	mov    0x64(%eax),%eax
f0103e49:	89 43 30             	mov    %eax,0x30(%ebx)
        tf->tf_esp = utf_addr;
f0103e4c:	89 7b 3c             	mov    %edi,0x3c(%ebx)
        env_run(curenv);
f0103e4f:	e8 d2 1b 00 00       	call   f0105a26 <cpunum>
f0103e54:	83 c4 04             	add    $0x4,%esp
f0103e57:	6b c0 74             	imul   $0x74,%eax,%eax
f0103e5a:	ff b0 28 00 23 f0    	pushl  -0xfdcffd8(%eax)
f0103e60:	e8 c3 f5 ff ff       	call   f0103428 <env_run>
    } 
    
	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103e65:	8b 7b 30             	mov    0x30(%ebx),%edi
		curenv->env_id, fault_va, tf->tf_eip);
f0103e68:	e8 b9 1b 00 00       	call   f0105a26 <cpunum>
        tf->tf_esp = utf_addr;
        env_run(curenv);
    } 
    
	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103e6d:	57                   	push   %edi
f0103e6e:	56                   	push   %esi
		curenv->env_id, fault_va, tf->tf_eip);
f0103e6f:	6b c0 74             	imul   $0x74,%eax,%eax
        tf->tf_esp = utf_addr;
        env_run(curenv);
    } 
    
	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103e72:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f0103e78:	ff 70 48             	pushl  0x48(%eax)
f0103e7b:	68 d8 76 10 f0       	push   $0xf01076d8
f0103e80:	e8 d9 f7 ff ff       	call   f010365e <cprintf>
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f0103e85:	89 1c 24             	mov    %ebx,(%esp)
f0103e88:	e8 80 fd ff ff       	call   f0103c0d <print_trapframe>
	env_destroy(curenv);
f0103e8d:	e8 94 1b 00 00       	call   f0105a26 <cpunum>
f0103e92:	83 c4 04             	add    $0x4,%esp
f0103e95:	6b c0 74             	imul   $0x74,%eax,%eax
f0103e98:	ff b0 28 00 23 f0    	pushl  -0xfdcffd8(%eax)
f0103e9e:	e8 e6 f4 ff ff       	call   f0103389 <env_destroy>
}
f0103ea3:	83 c4 10             	add    $0x10,%esp
f0103ea6:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103ea9:	5b                   	pop    %ebx
f0103eaa:	5e                   	pop    %esi
f0103eab:	5f                   	pop    %edi
f0103eac:	5d                   	pop    %ebp
f0103ead:	c3                   	ret    

f0103eae <trap>:
	}
}

void
trap(struct Trapframe *tf)
{
f0103eae:	55                   	push   %ebp
f0103eaf:	89 e5                	mov    %esp,%ebp
f0103eb1:	57                   	push   %edi
f0103eb2:	56                   	push   %esi
f0103eb3:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f0103eb6:	fc                   	cld    

	// Halt the CPU if some other CPU has called panic()
	extern char *panicstr;
	if (panicstr)
f0103eb7:	83 3d 80 fe 22 f0 00 	cmpl   $0x0,0xf022fe80
f0103ebe:	74 01                	je     f0103ec1 <trap+0x13>
		asm volatile("hlt");
f0103ec0:	f4                   	hlt    

	// Re-acqurie the big kernel lock if we were halted in
	// sched_yield()
	if (xchg(&thiscpu->cpu_status, CPU_STARTED) == CPU_HALTED)
f0103ec1:	e8 60 1b 00 00       	call   f0105a26 <cpunum>
f0103ec6:	6b d0 74             	imul   $0x74,%eax,%edx
f0103ec9:	81 c2 20 00 23 f0    	add    $0xf0230020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"
f0103ecf:	b8 01 00 00 00       	mov    $0x1,%eax
f0103ed4:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
f0103ed8:	83 f8 02             	cmp    $0x2,%eax
f0103edb:	75 10                	jne    f0103eed <trap+0x3f>
extern struct spinlock kernel_lock;

static inline void
lock_kernel(void)
{
	spin_lock(&kernel_lock);
f0103edd:	83 ec 0c             	sub    $0xc,%esp
f0103ee0:	68 c0 03 12 f0       	push   $0xf01203c0
f0103ee5:	e8 aa 1d 00 00       	call   f0105c94 <spin_lock>
f0103eea:	83 c4 10             	add    $0x10,%esp

static inline uint32_t
read_eflags(void)
{
	uint32_t eflags;
	asm volatile("pushfl; popl %0" : "=r" (eflags));
f0103eed:	9c                   	pushf  
f0103eee:	58                   	pop    %eax
		lock_kernel();
	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f0103eef:	f6 c4 02             	test   $0x2,%ah
f0103ef2:	74 19                	je     f0103f0d <trap+0x5f>
f0103ef4:	68 0e 75 10 f0       	push   $0xf010750e
f0103ef9:	68 ea 6f 10 f0       	push   $0xf0106fea
f0103efe:	68 2e 01 00 00       	push   $0x12e
f0103f03:	68 02 75 10 f0       	push   $0xf0107502
f0103f08:	e8 33 c1 ff ff       	call   f0100040 <_panic>

	if ((tf->tf_cs & 3) == 3) {
f0103f0d:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0103f11:	83 e0 03             	and    $0x3,%eax
f0103f14:	66 83 f8 03          	cmp    $0x3,%ax
f0103f18:	0f 85 a0 00 00 00    	jne    f0103fbe <trap+0x110>
f0103f1e:	83 ec 0c             	sub    $0xc,%esp
f0103f21:	68 c0 03 12 f0       	push   $0xf01203c0
f0103f26:	e8 69 1d 00 00       	call   f0105c94 <spin_lock>
		// Trapped from user mode.
		// Acquire the big kernel lock before doing any
		// serious kernel work.
		// LAB 4: Your code here.
        lock_kernel();
		assert(curenv);
f0103f2b:	e8 f6 1a 00 00       	call   f0105a26 <cpunum>
f0103f30:	6b c0 74             	imul   $0x74,%eax,%eax
f0103f33:	83 c4 10             	add    $0x10,%esp
f0103f36:	83 b8 28 00 23 f0 00 	cmpl   $0x0,-0xfdcffd8(%eax)
f0103f3d:	75 19                	jne    f0103f58 <trap+0xaa>
f0103f3f:	68 27 75 10 f0       	push   $0xf0107527
f0103f44:	68 ea 6f 10 f0       	push   $0xf0106fea
f0103f49:	68 36 01 00 00       	push   $0x136
f0103f4e:	68 02 75 10 f0       	push   $0xf0107502
f0103f53:	e8 e8 c0 ff ff       	call   f0100040 <_panic>

		// Garbage collect if current enviroment is a zombie
		if (curenv->env_status == ENV_DYING) {
f0103f58:	e8 c9 1a 00 00       	call   f0105a26 <cpunum>
f0103f5d:	6b c0 74             	imul   $0x74,%eax,%eax
f0103f60:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f0103f66:	83 78 54 01          	cmpl   $0x1,0x54(%eax)
f0103f6a:	75 2d                	jne    f0103f99 <trap+0xeb>
			env_free(curenv);
f0103f6c:	e8 b5 1a 00 00       	call   f0105a26 <cpunum>
f0103f71:	83 ec 0c             	sub    $0xc,%esp
f0103f74:	6b c0 74             	imul   $0x74,%eax,%eax
f0103f77:	ff b0 28 00 23 f0    	pushl  -0xfdcffd8(%eax)
f0103f7d:	e8 2c f2 ff ff       	call   f01031ae <env_free>
			curenv = NULL;
f0103f82:	e8 9f 1a 00 00       	call   f0105a26 <cpunum>
f0103f87:	6b c0 74             	imul   $0x74,%eax,%eax
f0103f8a:	c7 80 28 00 23 f0 00 	movl   $0x0,-0xfdcffd8(%eax)
f0103f91:	00 00 00 
			sched_yield();
f0103f94:	e8 a2 02 00 00       	call   f010423b <sched_yield>
		}

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f0103f99:	e8 88 1a 00 00       	call   f0105a26 <cpunum>
f0103f9e:	6b c0 74             	imul   $0x74,%eax,%eax
f0103fa1:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f0103fa7:	b9 11 00 00 00       	mov    $0x11,%ecx
f0103fac:	89 c7                	mov    %eax,%edi
f0103fae:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f0103fb0:	e8 71 1a 00 00       	call   f0105a26 <cpunum>
f0103fb5:	6b c0 74             	imul   $0x74,%eax,%eax
f0103fb8:	8b b0 28 00 23 f0    	mov    -0xfdcffd8(%eax),%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f0103fbe:	89 35 60 fa 22 f0    	mov    %esi,0xf022fa60
trap_dispatch(struct Trapframe *tf)
{
	// Handle processor exceptions.
	// LAB 3: Your code here.
	int r;
	switch(tf->tf_trapno){
f0103fc4:	8b 46 28             	mov    0x28(%esi),%eax
f0103fc7:	83 f8 0e             	cmp    $0xe,%eax
f0103fca:	74 30                	je     f0103ffc <trap+0x14e>
f0103fcc:	83 f8 30             	cmp    $0x30,%eax
f0103fcf:	74 07                	je     f0103fd8 <trap+0x12a>
f0103fd1:	83 f8 03             	cmp    $0x3,%eax
f0103fd4:	75 42                	jne    f0104018 <trap+0x16a>
f0103fd6:	eb 32                	jmp    f010400a <trap+0x15c>
		case T_SYSCALL:
			    tf->tf_regs.reg_eax = 
                    syscall(tf->tf_regs.reg_eax, tf->tf_regs.reg_edx, tf->tf_regs.reg_ecx,
f0103fd8:	83 ec 08             	sub    $0x8,%esp
f0103fdb:	ff 76 04             	pushl  0x4(%esi)
f0103fde:	ff 36                	pushl  (%esi)
f0103fe0:	ff 76 10             	pushl  0x10(%esi)
f0103fe3:	ff 76 18             	pushl  0x18(%esi)
f0103fe6:	ff 76 14             	pushl  0x14(%esi)
f0103fe9:	ff 76 1c             	pushl  0x1c(%esi)
f0103fec:	e8 0e 03 00 00       	call   f01042ff <syscall>
	// Handle processor exceptions.
	// LAB 3: Your code here.
	int r;
	switch(tf->tf_trapno){
		case T_SYSCALL:
			    tf->tf_regs.reg_eax = 
f0103ff1:	89 46 1c             	mov    %eax,0x1c(%esi)
f0103ff4:	83 c4 20             	add    $0x20,%esp
f0103ff7:	e9 8d 00 00 00       	jmp    f0104089 <trap+0x1db>
            if (tf->tf_regs.reg_eax < 0) {
                panic("trap_dispatch: %e", tf->tf_regs.reg_eax);
            }
			return;
		case T_PGFLT:
			page_fault_handler(tf);
f0103ffc:	83 ec 0c             	sub    $0xc,%esp
f0103fff:	56                   	push   %esi
f0104000:	e8 90 fd ff ff       	call   f0103d95 <page_fault_handler>
f0104005:	83 c4 10             	add    $0x10,%esp
f0104008:	eb 7f                	jmp    f0104089 <trap+0x1db>
			return;
		case T_BRKPT:
			monitor(tf);
f010400a:	83 ec 0c             	sub    $0xc,%esp
f010400d:	56                   	push   %esi
f010400e:	e8 de c8 ff ff       	call   f01008f1 <monitor>
f0104013:	83 c4 10             	add    $0x10,%esp
f0104016:	eb 71                	jmp    f0104089 <trap+0x1db>
	}

	// Handle spurious interrupts
	// The hardware sometimes raises these because of noise on the
	// IRQ line or other reasons. We don't care.
	if (tf->tf_trapno == IRQ_OFFSET + IRQ_SPURIOUS) {
f0104018:	83 f8 27             	cmp    $0x27,%eax
f010401b:	75 1a                	jne    f0104037 <trap+0x189>
		cprintf("Spurious interrupt on irq 7\n");
f010401d:	83 ec 0c             	sub    $0xc,%esp
f0104020:	68 2e 75 10 f0       	push   $0xf010752e
f0104025:	e8 34 f6 ff ff       	call   f010365e <cprintf>
		print_trapframe(tf);
f010402a:	89 34 24             	mov    %esi,(%esp)
f010402d:	e8 db fb ff ff       	call   f0103c0d <print_trapframe>
f0104032:	83 c4 10             	add    $0x10,%esp
f0104035:	eb 52                	jmp    f0104089 <trap+0x1db>
	}

	// Handle clock interrupts. Don't forget to acknowledge the
	// interrupt using lapic_eoi() before calling the scheduler!
	// LAB 4: Your code here.
    if (tf->tf_trapno == IRQ_OFFSET + IRQ_TIMER) {
f0104037:	83 f8 20             	cmp    $0x20,%eax
f010403a:	75 0a                	jne    f0104046 <trap+0x198>
        lapic_eoi();
f010403c:	e8 30 1b 00 00       	call   f0105b71 <lapic_eoi>
        sched_yield();
f0104041:	e8 f5 01 00 00       	call   f010423b <sched_yield>
        return;
    }
	// Unexpected trap: The user process or the kernel has a bug.
	print_trapframe(tf);
f0104046:	83 ec 0c             	sub    $0xc,%esp
f0104049:	56                   	push   %esi
f010404a:	e8 be fb ff ff       	call   f0103c0d <print_trapframe>
	if (tf->tf_cs == GD_KT)
f010404f:	83 c4 10             	add    $0x10,%esp
f0104052:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f0104057:	75 17                	jne    f0104070 <trap+0x1c2>
		panic("unhandled trap in kernel");
f0104059:	83 ec 04             	sub    $0x4,%esp
f010405c:	68 4b 75 10 f0       	push   $0xf010754b
f0104061:	68 14 01 00 00       	push   $0x114
f0104066:	68 02 75 10 f0       	push   $0xf0107502
f010406b:	e8 d0 bf ff ff       	call   f0100040 <_panic>
	else {
		env_destroy(curenv);
f0104070:	e8 b1 19 00 00       	call   f0105a26 <cpunum>
f0104075:	83 ec 0c             	sub    $0xc,%esp
f0104078:	6b c0 74             	imul   $0x74,%eax,%eax
f010407b:	ff b0 28 00 23 f0    	pushl  -0xfdcffd8(%eax)
f0104081:	e8 03 f3 ff ff       	call   f0103389 <env_destroy>
f0104086:	83 c4 10             	add    $0x10,%esp
	trap_dispatch(tf);

	// If we made it to this point, then no other environment was
	// scheduled, so we should return to the current environment
	// if doing so makes sense.
	if (curenv && curenv->env_status == ENV_RUNNING)
f0104089:	e8 98 19 00 00       	call   f0105a26 <cpunum>
f010408e:	6b c0 74             	imul   $0x74,%eax,%eax
f0104091:	83 b8 28 00 23 f0 00 	cmpl   $0x0,-0xfdcffd8(%eax)
f0104098:	74 2a                	je     f01040c4 <trap+0x216>
f010409a:	e8 87 19 00 00       	call   f0105a26 <cpunum>
f010409f:	6b c0 74             	imul   $0x74,%eax,%eax
f01040a2:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f01040a8:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f01040ac:	75 16                	jne    f01040c4 <trap+0x216>
		env_run(curenv);
f01040ae:	e8 73 19 00 00       	call   f0105a26 <cpunum>
f01040b3:	83 ec 0c             	sub    $0xc,%esp
f01040b6:	6b c0 74             	imul   $0x74,%eax,%eax
f01040b9:	ff b0 28 00 23 f0    	pushl  -0xfdcffd8(%eax)
f01040bf:	e8 64 f3 ff ff       	call   f0103428 <env_run>
	else
		sched_yield();
f01040c4:	e8 72 01 00 00       	call   f010423b <sched_yield>
f01040c9:	90                   	nop

f01040ca <t_divide>:
.text

/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */
TRAPHANDLER_NOEC(t_divide, T_DIVIDE)
f01040ca:	6a 00                	push   $0x0
f01040cc:	6a 00                	push   $0x0
f01040ce:	e9 83 00 00 00       	jmp    f0104156 <_alltraps>
f01040d3:	90                   	nop

f01040d4 <t_debug>:
TRAPHANDLER_NOEC(t_debug, T_DEBUG)
f01040d4:	6a 00                	push   $0x0
f01040d6:	6a 01                	push   $0x1
f01040d8:	eb 7c                	jmp    f0104156 <_alltraps>

f01040da <t_nmi>:
TRAPHANDLER_NOEC(t_nmi, T_NMI)
f01040da:	6a 00                	push   $0x0
f01040dc:	6a 02                	push   $0x2
f01040de:	eb 76                	jmp    f0104156 <_alltraps>

f01040e0 <t_brkpt>:
TRAPHANDLER_NOEC(t_brkpt, T_BRKPT)
f01040e0:	6a 00                	push   $0x0
f01040e2:	6a 03                	push   $0x3
f01040e4:	eb 70                	jmp    f0104156 <_alltraps>

f01040e6 <t_oflow>:
TRAPHANDLER_NOEC(t_oflow, T_OFLOW)
f01040e6:	6a 00                	push   $0x0
f01040e8:	6a 04                	push   $0x4
f01040ea:	eb 6a                	jmp    f0104156 <_alltraps>

f01040ec <t_bound>:
TRAPHANDLER_NOEC(t_bound, T_BOUND)
f01040ec:	6a 00                	push   $0x0
f01040ee:	6a 05                	push   $0x5
f01040f0:	eb 64                	jmp    f0104156 <_alltraps>

f01040f2 <t_illop>:
TRAPHANDLER_NOEC(t_illop, T_ILLOP)
f01040f2:	6a 00                	push   $0x0
f01040f4:	6a 06                	push   $0x6
f01040f6:	eb 5e                	jmp    f0104156 <_alltraps>

f01040f8 <t_device>:
TRAPHANDLER_NOEC(t_device, T_DEVICE)
f01040f8:	6a 00                	push   $0x0
f01040fa:	6a 07                	push   $0x7
f01040fc:	eb 58                	jmp    f0104156 <_alltraps>

f01040fe <t_dblflt>:
TRAPHANDLER(t_dblflt, T_DBLFLT)
f01040fe:	6a 08                	push   $0x8
f0104100:	eb 54                	jmp    f0104156 <_alltraps>

f0104102 <t_tss>:
TRAPHANDLER(t_tss, T_TSS)
f0104102:	6a 0a                	push   $0xa
f0104104:	eb 50                	jmp    f0104156 <_alltraps>

f0104106 <t_segnp>:
TRAPHANDLER(t_segnp, T_SEGNP)
f0104106:	6a 0b                	push   $0xb
f0104108:	eb 4c                	jmp    f0104156 <_alltraps>

f010410a <t_stack>:
TRAPHANDLER(t_stack, T_STACK)
f010410a:	6a 0c                	push   $0xc
f010410c:	eb 48                	jmp    f0104156 <_alltraps>

f010410e <t_gpflt>:
TRAPHANDLER(t_gpflt, T_GPFLT)
f010410e:	6a 0d                	push   $0xd
f0104110:	eb 44                	jmp    f0104156 <_alltraps>

f0104112 <t_pgflt>:
TRAPHANDLER(t_pgflt, T_PGFLT)
f0104112:	6a 0e                	push   $0xe
f0104114:	eb 40                	jmp    f0104156 <_alltraps>

f0104116 <t_fperr>:
TRAPHANDLER_NOEC(t_fperr, T_FPERR)
f0104116:	6a 00                	push   $0x0
f0104118:	6a 10                	push   $0x10
f010411a:	eb 3a                	jmp    f0104156 <_alltraps>

f010411c <t_align>:
TRAPHANDLER(t_align, T_ALIGN)
f010411c:	6a 11                	push   $0x11
f010411e:	eb 36                	jmp    f0104156 <_alltraps>

f0104120 <t_mchk>:
TRAPHANDLER_NOEC(t_mchk, T_MCHK)
f0104120:	6a 00                	push   $0x0
f0104122:	6a 12                	push   $0x12
f0104124:	eb 30                	jmp    f0104156 <_alltraps>

f0104126 <t_simderr>:
TRAPHANDLER_NOEC(t_simderr, T_SIMDERR)
f0104126:	6a 00                	push   $0x0
f0104128:	6a 13                	push   $0x13
f010412a:	eb 2a                	jmp    f0104156 <_alltraps>

f010412c <t_syscall>:
TRAPHANDLER_NOEC(t_syscall, T_SYSCALL)
f010412c:	6a 00                	push   $0x0
f010412e:	6a 30                	push   $0x30
f0104130:	eb 24                	jmp    f0104156 <_alltraps>

f0104132 <irq_timer>:
TRAPHANDLER_NOEC(irq_timer, IRQ_OFFSET + IRQ_TIMER)
f0104132:	6a 00                	push   $0x0
f0104134:	6a 20                	push   $0x20
f0104136:	eb 1e                	jmp    f0104156 <_alltraps>

f0104138 <irq_kbd>:
TRAPHANDLER_NOEC(irq_kbd, IRQ_OFFSET + IRQ_KBD)
f0104138:	6a 00                	push   $0x0
f010413a:	6a 21                	push   $0x21
f010413c:	eb 18                	jmp    f0104156 <_alltraps>

f010413e <irq_serial>:
TRAPHANDLER_NOEC(irq_serial, IRQ_OFFSET + IRQ_SERIAL)
f010413e:	6a 00                	push   $0x0
f0104140:	6a 24                	push   $0x24
f0104142:	eb 12                	jmp    f0104156 <_alltraps>

f0104144 <irq_spurious>:
TRAPHANDLER_NOEC(irq_spurious, IRQ_OFFSET + IRQ_SPURIOUS)
f0104144:	6a 00                	push   $0x0
f0104146:	6a 27                	push   $0x27
f0104148:	eb 0c                	jmp    f0104156 <_alltraps>

f010414a <irq_ide>:
TRAPHANDLER_NOEC(irq_ide, IRQ_OFFSET + IRQ_IDE)
f010414a:	6a 00                	push   $0x0
f010414c:	6a 2e                	push   $0x2e
f010414e:	eb 06                	jmp    f0104156 <_alltraps>

f0104150 <irq_error>:
TRAPHANDLER_NOEC(irq_error, IRQ_OFFSET + IRQ_ERROR)
f0104150:	6a 00                	push   $0x0
f0104152:	6a 33                	push   $0x33
f0104154:	eb 00                	jmp    f0104156 <_alltraps>

f0104156 <_alltraps>:
/*
 * Lab 3: Your code here for _alltraps
 */
_alltraps:
	# Build trap frame.
	pushl %ds
f0104156:	1e                   	push   %ds
	pushl %es
f0104157:	06                   	push   %es
	pushal	
f0104158:	60                   	pusha  

	movw $(GD_KD), %ax
f0104159:	66 b8 10 00          	mov    $0x10,%ax
	movw %ax, %ds
f010415d:	8e d8                	mov    %eax,%ds
	movw %ax, %es
f010415f:	8e c0                	mov    %eax,%es

	pushl %esp
f0104161:	54                   	push   %esp
	call trap
f0104162:	e8 47 fd ff ff       	call   f0103eae <trap>

f0104167 <sched_halt>:
// Halt this CPU when there is nothing to do. Wait until the
// timer interrupt wakes it up. This function never returns.
//
void
sched_halt(void)
{
f0104167:	55                   	push   %ebp
f0104168:	89 e5                	mov    %esp,%ebp
f010416a:	83 ec 08             	sub    $0x8,%esp
f010416d:	a1 44 f2 22 f0       	mov    0xf022f244,%eax
f0104172:	8d 50 54             	lea    0x54(%eax),%edx
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
f0104175:	b9 00 00 00 00       	mov    $0x0,%ecx
		if ((envs[i].env_status == ENV_RUNNABLE ||
f010417a:	8b 02                	mov    (%edx),%eax
f010417c:	83 e8 01             	sub    $0x1,%eax
f010417f:	83 f8 02             	cmp    $0x2,%eax
f0104182:	76 10                	jbe    f0104194 <sched_halt+0x2d>
{
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
f0104184:	83 c1 01             	add    $0x1,%ecx
f0104187:	83 c2 7c             	add    $0x7c,%edx
f010418a:	81 f9 00 04 00 00    	cmp    $0x400,%ecx
f0104190:	75 e8                	jne    f010417a <sched_halt+0x13>
f0104192:	eb 08                	jmp    f010419c <sched_halt+0x35>
		if ((envs[i].env_status == ENV_RUNNABLE ||
		     envs[i].env_status == ENV_RUNNING ||
		     envs[i].env_status == ENV_DYING))
			break;
	}
	if (i == NENV) {
f0104194:	81 f9 00 04 00 00    	cmp    $0x400,%ecx
f010419a:	75 1f                	jne    f01041bb <sched_halt+0x54>
		cprintf("No runnable environments in the system!\n");
f010419c:	83 ec 0c             	sub    $0xc,%esp
f010419f:	68 50 77 10 f0       	push   $0xf0107750
f01041a4:	e8 b5 f4 ff ff       	call   f010365e <cprintf>
f01041a9:	83 c4 10             	add    $0x10,%esp
		while (1)
			monitor(NULL);
f01041ac:	83 ec 0c             	sub    $0xc,%esp
f01041af:	6a 00                	push   $0x0
f01041b1:	e8 3b c7 ff ff       	call   f01008f1 <monitor>
f01041b6:	83 c4 10             	add    $0x10,%esp
f01041b9:	eb f1                	jmp    f01041ac <sched_halt+0x45>
	}

	// Mark that no environment is running on this CPU
	curenv = NULL;
f01041bb:	e8 66 18 00 00       	call   f0105a26 <cpunum>
f01041c0:	6b c0 74             	imul   $0x74,%eax,%eax
f01041c3:	c7 80 28 00 23 f0 00 	movl   $0x0,-0xfdcffd8(%eax)
f01041ca:	00 00 00 
	lcr3(PADDR(kern_pgdir));
f01041cd:	a1 8c fe 22 f0       	mov    0xf022fe8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01041d2:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01041d7:	77 12                	ja     f01041eb <sched_halt+0x84>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01041d9:	50                   	push   %eax
f01041da:	68 08 61 10 f0       	push   $0xf0106108
f01041df:	6a 4f                	push   $0x4f
f01041e1:	68 79 77 10 f0       	push   $0xf0107779
f01041e6:	e8 55 be ff ff       	call   f0100040 <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f01041eb:	05 00 00 00 10       	add    $0x10000000,%eax
f01041f0:	0f 22 d8             	mov    %eax,%cr3

	// Mark that this CPU is in the HALT state, so that when
	// timer interupts come in, we know we should re-acquire the
	// big kernel lock
	xchg(&thiscpu->cpu_status, CPU_HALTED);
f01041f3:	e8 2e 18 00 00       	call   f0105a26 <cpunum>
f01041f8:	6b d0 74             	imul   $0x74,%eax,%edx
f01041fb:	81 c2 20 00 23 f0    	add    $0xf0230020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"
f0104201:	b8 02 00 00 00       	mov    $0x2,%eax
f0104206:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
}

static inline void
unlock_kernel(void)
{
	spin_unlock(&kernel_lock);
f010420a:	83 ec 0c             	sub    $0xc,%esp
f010420d:	68 c0 03 12 f0       	push   $0xf01203c0
f0104212:	e8 1a 1b 00 00       	call   f0105d31 <spin_unlock>

	// Normally we wouldn't need to do this, but QEMU only runs
	// one CPU at a time and has a long time-slice.  Without the
	// pause, this CPU is likely to reacquire the lock before
	// another CPU has even been given a chance to acquire it.
	asm volatile("pause");
f0104217:	f3 90                	pause  
		"pushl $0\n"
		"sti\n"
		"1:\n"
		"hlt\n"
		"jmp 1b\n"
	: : "a" (thiscpu->cpu_ts.ts_esp0));
f0104219:	e8 08 18 00 00       	call   f0105a26 <cpunum>
f010421e:	6b c0 74             	imul   $0x74,%eax,%eax

	// Release the big kernel lock as if we were "leaving" the kernel
	unlock_kernel();

	// Reset stack pointer, enable interrupts and then halt.
	asm volatile (
f0104221:	8b 80 30 00 23 f0    	mov    -0xfdcffd0(%eax),%eax
f0104227:	bd 00 00 00 00       	mov    $0x0,%ebp
f010422c:	89 c4                	mov    %eax,%esp
f010422e:	6a 00                	push   $0x0
f0104230:	6a 00                	push   $0x0
f0104232:	fb                   	sti    
f0104233:	f4                   	hlt    
f0104234:	eb fd                	jmp    f0104233 <sched_halt+0xcc>
		"sti\n"
		"1:\n"
		"hlt\n"
		"jmp 1b\n"
	: : "a" (thiscpu->cpu_ts.ts_esp0));
}
f0104236:	83 c4 10             	add    $0x10,%esp
f0104239:	c9                   	leave  
f010423a:	c3                   	ret    

f010423b <sched_yield>:
void sched_halt(void);

// Choose a user environment to run and run it.
void
sched_yield(void)
{
f010423b:	55                   	push   %ebp
f010423c:	89 e5                	mov    %esp,%ebp
f010423e:	53                   	push   %ebx
f010423f:	83 ec 04             	sub    $0x4,%esp
	// no runnable environments, simply drop through to the code
	// below to halt the cpu.

	// LAB 4: Your code here.
    int cur_idx;
    if (curenv)
f0104242:	e8 df 17 00 00       	call   f0105a26 <cpunum>
f0104247:	6b c0 74             	imul   $0x74,%eax,%eax
        cur_idx = ENVX(curenv->env_id);
    else
        cur_idx = 0;
f010424a:	ba 00 00 00 00       	mov    $0x0,%edx
	// no runnable environments, simply drop through to the code
	// below to halt the cpu.

	// LAB 4: Your code here.
    int cur_idx;
    if (curenv)
f010424f:	83 b8 28 00 23 f0 00 	cmpl   $0x0,-0xfdcffd8(%eax)
f0104256:	74 17                	je     f010426f <sched_yield+0x34>
        cur_idx = ENVX(curenv->env_id);
f0104258:	e8 c9 17 00 00       	call   f0105a26 <cpunum>
f010425d:	6b c0 74             	imul   $0x74,%eax,%eax
f0104260:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f0104266:	8b 50 48             	mov    0x48(%eax),%edx
f0104269:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
    else
        cur_idx = 0;

    if(envs[cur_idx].env_status == ENV_RUNNABLE){
f010426f:	8b 0d 44 f2 22 f0    	mov    0xf022f244,%ecx
f0104275:	6b c2 7c             	imul   $0x7c,%edx,%eax
f0104278:	01 c8                	add    %ecx,%eax
f010427a:	83 78 54 02          	cmpl   $0x2,0x54(%eax)
f010427e:	75 09                	jne    f0104289 <sched_yield+0x4e>
        env_run(&envs[cur_idx]);
f0104280:	83 ec 0c             	sub    $0xc,%esp
f0104283:	50                   	push   %eax
f0104284:	e8 9f f1 ff ff       	call   f0103428 <env_run>
    }
    for(int i = cur_idx + 1; i != cur_idx; i = (i + 1) % NENV){
f0104289:	8d 42 01             	lea    0x1(%edx),%eax
f010428c:	eb 28                	jmp    f01042b6 <sched_yield+0x7b>
        if(envs[i].env_status == ENV_RUNNABLE){
f010428e:	6b d8 7c             	imul   $0x7c,%eax,%ebx
f0104291:	01 cb                	add    %ecx,%ebx
f0104293:	83 7b 54 02          	cmpl   $0x2,0x54(%ebx)
f0104297:	75 09                	jne    f01042a2 <sched_yield+0x67>
            env_run(&envs[i]);
f0104299:	83 ec 0c             	sub    $0xc,%esp
f010429c:	53                   	push   %ebx
f010429d:	e8 86 f1 ff ff       	call   f0103428 <env_run>
        cur_idx = 0;

    if(envs[cur_idx].env_status == ENV_RUNNABLE){
        env_run(&envs[cur_idx]);
    }
    for(int i = cur_idx + 1; i != cur_idx; i = (i + 1) % NENV){
f01042a2:	83 c0 01             	add    $0x1,%eax
f01042a5:	89 c3                	mov    %eax,%ebx
f01042a7:	c1 fb 1f             	sar    $0x1f,%ebx
f01042aa:	c1 eb 16             	shr    $0x16,%ebx
f01042ad:	01 d8                	add    %ebx,%eax
f01042af:	25 ff 03 00 00       	and    $0x3ff,%eax
f01042b4:	29 d8                	sub    %ebx,%eax
f01042b6:	39 c2                	cmp    %eax,%edx
f01042b8:	75 d4                	jne    f010428e <sched_yield+0x53>
        if(envs[i].env_status == ENV_RUNNABLE){
            env_run(&envs[i]);
            return;
        } 
    }
    if(curenv && curenv->env_status == ENV_RUNNING) {
f01042ba:	e8 67 17 00 00       	call   f0105a26 <cpunum>
f01042bf:	6b c0 74             	imul   $0x74,%eax,%eax
f01042c2:	83 b8 28 00 23 f0 00 	cmpl   $0x0,-0xfdcffd8(%eax)
f01042c9:	74 2a                	je     f01042f5 <sched_yield+0xba>
f01042cb:	e8 56 17 00 00       	call   f0105a26 <cpunum>
f01042d0:	6b c0 74             	imul   $0x74,%eax,%eax
f01042d3:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f01042d9:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f01042dd:	75 16                	jne    f01042f5 <sched_yield+0xba>
        env_run(curenv);
f01042df:	e8 42 17 00 00       	call   f0105a26 <cpunum>
f01042e4:	83 ec 0c             	sub    $0xc,%esp
f01042e7:	6b c0 74             	imul   $0x74,%eax,%eax
f01042ea:	ff b0 28 00 23 f0    	pushl  -0xfdcffd8(%eax)
f01042f0:	e8 33 f1 ff ff       	call   f0103428 <env_run>
        return;
    }

	// sched_halt never returns
	sched_halt();
f01042f5:	e8 6d fe ff ff       	call   f0104167 <sched_halt>
}
f01042fa:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01042fd:	c9                   	leave  
f01042fe:	c3                   	ret    

f01042ff <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f01042ff:	55                   	push   %ebp
f0104300:	89 e5                	mov    %esp,%ebp
f0104302:	57                   	push   %edi
f0104303:	56                   	push   %esi
f0104304:	53                   	push   %ebx
f0104305:	83 ec 1c             	sub    $0x1c,%esp
f0104308:	8b 45 08             	mov    0x8(%ebp),%eax
	// Call the function corresponding to the 'syscallno' parameter.
	// Return any appropriate return value.
	// LAB 3: Your code here.

	switch (syscallno) {
f010430b:	83 f8 0c             	cmp    $0xc,%eax
f010430e:	0f 87 36 05 00 00    	ja     f010484a <syscall+0x54b>
f0104314:	ff 24 85 c0 77 10 f0 	jmp    *-0xfef8840(,%eax,4)
{
	// Check that the user has permission to read memory [s, s+len).
	// Destroy the environment if not.

	// LAB 3: Your code here.
	user_mem_assert(curenv, s, len, PTE_U | PTE_W);
f010431b:	e8 06 17 00 00       	call   f0105a26 <cpunum>
f0104320:	6a 06                	push   $0x6
f0104322:	ff 75 10             	pushl  0x10(%ebp)
f0104325:	ff 75 0c             	pushl  0xc(%ebp)
f0104328:	6b c0 74             	imul   $0x74,%eax,%eax
f010432b:	ff b0 28 00 23 f0    	pushl  -0xfdcffd8(%eax)
f0104331:	e8 0f ea ff ff       	call   f0102d45 <user_mem_assert>

	// Print the string supplied by the user.
	cprintf("%.*s", len, s);
f0104336:	83 c4 0c             	add    $0xc,%esp
f0104339:	ff 75 0c             	pushl  0xc(%ebp)
f010433c:	ff 75 10             	pushl  0x10(%ebp)
f010433f:	68 86 77 10 f0       	push   $0xf0107786
f0104344:	e8 15 f3 ff ff       	call   f010365e <cprintf>
f0104349:	83 c4 10             	add    $0x10,%esp
	// LAB 3: Your code here.

	switch (syscallno) {
		case SYS_cputs:
			sys_cputs((const char *) a1,(size_t) a2);
			return 0;
f010434c:	b8 00 00 00 00       	mov    $0x0,%eax
f0104351:	e9 00 05 00 00       	jmp    f0104856 <syscall+0x557>
// Read a character from the system console without blocking.
// Returns the character, or 0 if there is no input waiting.
static int
sys_cgetc(void)
{
	return cons_getc();
f0104356:	e8 9a c2 ff ff       	call   f01005f5 <cons_getc>
	switch (syscallno) {
		case SYS_cputs:
			sys_cputs((const char *) a1,(size_t) a2);
			return 0;
		case SYS_cgetc:
			return sys_cgetc();
f010435b:	e9 f6 04 00 00       	jmp    f0104856 <syscall+0x557>

// Returns the current environment's envid.
static envid_t
sys_getenvid(void)
{
	return curenv->env_id;
f0104360:	e8 c1 16 00 00       	call   f0105a26 <cpunum>
f0104365:	6b c0 74             	imul   $0x74,%eax,%eax
f0104368:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f010436e:	8b 40 48             	mov    0x48(%eax),%eax
			sys_cputs((const char *) a1,(size_t) a2);
			return 0;
		case SYS_cgetc:
			return sys_cgetc();
		case SYS_getenvid:
			return sys_getenvid();
f0104371:	e9 e0 04 00 00       	jmp    f0104856 <syscall+0x557>
sys_env_destroy(envid_t envid)
{
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
f0104376:	83 ec 04             	sub    $0x4,%esp
f0104379:	6a 01                	push   $0x1
f010437b:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010437e:	50                   	push   %eax
f010437f:	ff 75 0c             	pushl  0xc(%ebp)
f0104382:	e8 73 ea ff ff       	call   f0102dfa <envid2env>
f0104387:	83 c4 10             	add    $0x10,%esp
f010438a:	85 c0                	test   %eax,%eax
f010438c:	0f 88 c4 04 00 00    	js     f0104856 <syscall+0x557>
		return r;
	if (e == curenv)
f0104392:	e8 8f 16 00 00       	call   f0105a26 <cpunum>
f0104397:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f010439a:	6b c0 74             	imul   $0x74,%eax,%eax
f010439d:	39 90 28 00 23 f0    	cmp    %edx,-0xfdcffd8(%eax)
f01043a3:	75 23                	jne    f01043c8 <syscall+0xc9>
		cprintf("[%08x] exiting gracefully\n", curenv->env_id);
f01043a5:	e8 7c 16 00 00       	call   f0105a26 <cpunum>
f01043aa:	83 ec 08             	sub    $0x8,%esp
f01043ad:	6b c0 74             	imul   $0x74,%eax,%eax
f01043b0:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f01043b6:	ff 70 48             	pushl  0x48(%eax)
f01043b9:	68 8b 77 10 f0       	push   $0xf010778b
f01043be:	e8 9b f2 ff ff       	call   f010365e <cprintf>
f01043c3:	83 c4 10             	add    $0x10,%esp
f01043c6:	eb 25                	jmp    f01043ed <syscall+0xee>
	else
		cprintf("[%08x] destroying %08x\n", curenv->env_id, e->env_id);
f01043c8:	8b 5a 48             	mov    0x48(%edx),%ebx
f01043cb:	e8 56 16 00 00       	call   f0105a26 <cpunum>
f01043d0:	83 ec 04             	sub    $0x4,%esp
f01043d3:	53                   	push   %ebx
f01043d4:	6b c0 74             	imul   $0x74,%eax,%eax
f01043d7:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f01043dd:	ff 70 48             	pushl  0x48(%eax)
f01043e0:	68 a6 77 10 f0       	push   $0xf01077a6
f01043e5:	e8 74 f2 ff ff       	call   f010365e <cprintf>
f01043ea:	83 c4 10             	add    $0x10,%esp
	env_destroy(e);
f01043ed:	83 ec 0c             	sub    $0xc,%esp
f01043f0:	ff 75 e4             	pushl  -0x1c(%ebp)
f01043f3:	e8 91 ef ff ff       	call   f0103389 <env_destroy>
f01043f8:	83 c4 10             	add    $0x10,%esp
	return 0;
f01043fb:	b8 00 00 00 00       	mov    $0x0,%eax
f0104400:	e9 51 04 00 00       	jmp    f0104856 <syscall+0x557>

// Deschedule current environment and pick a different one to run.
static void
sys_yield(void)
{
	sched_yield();
f0104405:	e8 31 fe ff ff       	call   f010423b <sched_yield>
	// status is set to ENV_NOT_RUNNABLE, and the register set is copied
	// from the current environment -- but tweaked so sys_exofork
	// will appear to return 0.
    struct Env *child_env;
    int r;
    r = env_alloc(&child_env, curenv->env_id);
f010440a:	e8 17 16 00 00       	call   f0105a26 <cpunum>
f010440f:	83 ec 08             	sub    $0x8,%esp
f0104412:	6b c0 74             	imul   $0x74,%eax,%eax
f0104415:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f010441b:	ff 70 48             	pushl  0x48(%eax)
f010441e:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104421:	50                   	push   %eax
f0104422:	e8 e5 ea ff ff       	call   f0102f0c <env_alloc>
    if(r!=0)
f0104427:	83 c4 10             	add    $0x10,%esp
f010442a:	85 c0                	test   %eax,%eax
f010442c:	0f 85 24 04 00 00    	jne    f0104856 <syscall+0x557>
        return r;
    child_env->env_status = ENV_NOT_RUNNABLE;
f0104432:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0104435:	c7 43 54 04 00 00 00 	movl   $0x4,0x54(%ebx)
    child_env->env_tf = curenv->env_tf;
f010443c:	e8 e5 15 00 00       	call   f0105a26 <cpunum>
f0104441:	6b c0 74             	imul   $0x74,%eax,%eax
f0104444:	8b b0 28 00 23 f0    	mov    -0xfdcffd8(%eax),%esi
f010444a:	b9 11 00 00 00       	mov    $0x11,%ecx
f010444f:	89 df                	mov    %ebx,%edi
f0104451:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
    child_env->env_tf.tf_regs.reg_eax = 0;
f0104453:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104456:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)
    return child_env->env_id;
f010445d:	8b 40 48             	mov    0x48(%eax),%eax
f0104460:	e9 f1 03 00 00       	jmp    f0104856 <syscall+0x557>
	//   parameters for correctness.
	//   If page_insert() fails, remember to free the page you
	//   allocated!

    struct Env *env;
    int r = envid2env(envid, &env, 1);
f0104465:	83 ec 04             	sub    $0x4,%esp
f0104468:	6a 01                	push   $0x1
f010446a:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010446d:	50                   	push   %eax
f010446e:	ff 75 0c             	pushl  0xc(%ebp)
f0104471:	e8 84 e9 ff ff       	call   f0102dfa <envid2env>
    if(r!=0)
f0104476:	83 c4 10             	add    $0x10,%esp
f0104479:	85 c0                	test   %eax,%eax
f010447b:	0f 85 d5 03 00 00    	jne    f0104856 <syscall+0x557>
        return r;
    if (va > (void *) UTOP || va != ROUNDDOWN(va, PGSIZE))
f0104481:	81 7d 10 00 00 c0 ee 	cmpl   $0xeec00000,0x10(%ebp)
f0104488:	77 67                	ja     f01044f1 <syscall+0x1f2>
f010448a:	f7 45 10 ff 0f 00 00 	testl  $0xfff,0x10(%ebp)
f0104491:	75 68                	jne    f01044fb <syscall+0x1fc>
       return -E_INVAL; 
    int flag = PTE_U | PTE_P;

    if ((perm & flag) != flag)
f0104493:	8b 45 14             	mov    0x14(%ebp),%eax
f0104496:	83 e0 05             	and    $0x5,%eax
f0104499:	83 f8 05             	cmp    $0x5,%eax
f010449c:	75 67                	jne    f0104505 <syscall+0x206>
        return -E_INVAL;

    if (perm & (~(PTE_U | PTE_P | PTE_AVAIL | PTE_W)))
f010449e:	f7 45 14 f8 f1 ff ff 	testl  $0xfffff1f8,0x14(%ebp)
f01044a5:	75 68                	jne    f010450f <syscall+0x210>
        return -E_INVAL;

    struct PageInfo *pp = page_alloc(1);
f01044a7:	83 ec 0c             	sub    $0xc,%esp
f01044aa:	6a 01                	push   $0x1
f01044ac:	e8 b6 ca ff ff       	call   f0100f67 <page_alloc>
f01044b1:	89 c3                	mov    %eax,%ebx
    if(pp == NULL)
f01044b3:	83 c4 10             	add    $0x10,%esp
f01044b6:	85 c0                	test   %eax,%eax
f01044b8:	74 5f                	je     f0104519 <syscall+0x21a>
        return -E_NO_MEM;
    pp->pp_ref ++;
f01044ba:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
    r = page_insert(env->env_pgdir, pp, va, perm);
f01044bf:	ff 75 14             	pushl  0x14(%ebp)
f01044c2:	ff 75 10             	pushl  0x10(%ebp)
f01044c5:	50                   	push   %eax
f01044c6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01044c9:	ff 70 60             	pushl  0x60(%eax)
f01044cc:	e8 3b cd ff ff       	call   f010120c <page_insert>
f01044d1:	89 c6                	mov    %eax,%esi
    if(r!=0){
f01044d3:	83 c4 10             	add    $0x10,%esp
f01044d6:	85 c0                	test   %eax,%eax
f01044d8:	0f 84 78 03 00 00    	je     f0104856 <syscall+0x557>
        page_free(pp);
f01044de:	83 ec 0c             	sub    $0xc,%esp
f01044e1:	53                   	push   %ebx
f01044e2:	e8 f7 ca ff ff       	call   f0100fde <page_free>
f01044e7:	83 c4 10             	add    $0x10,%esp
        return r;
f01044ea:	89 f0                	mov    %esi,%eax
f01044ec:	e9 65 03 00 00       	jmp    f0104856 <syscall+0x557>
    struct Env *env;
    int r = envid2env(envid, &env, 1);
    if(r!=0)
        return r;
    if (va > (void *) UTOP || va != ROUNDDOWN(va, PGSIZE))
       return -E_INVAL; 
f01044f1:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f01044f6:	e9 5b 03 00 00       	jmp    f0104856 <syscall+0x557>
f01044fb:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104500:	e9 51 03 00 00       	jmp    f0104856 <syscall+0x557>
    int flag = PTE_U | PTE_P;

    if ((perm & flag) != flag)
        return -E_INVAL;
f0104505:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f010450a:	e9 47 03 00 00       	jmp    f0104856 <syscall+0x557>

    if (perm & (~(PTE_U | PTE_P | PTE_AVAIL | PTE_W)))
        return -E_INVAL;
f010450f:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104514:	e9 3d 03 00 00       	jmp    f0104856 <syscall+0x557>

    struct PageInfo *pp = page_alloc(1);
    if(pp == NULL)
        return -E_NO_MEM;
f0104519:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f010451e:	e9 33 03 00 00       	jmp    f0104856 <syscall+0x557>
	//   parameters for correctness.
	//   Use the third argument to page_lookup() to
	//   check the current permissions on the page.

    struct Env *srcenv, *dstenv;
    int r = envid2env(srcenvid, &srcenv, 1);
f0104523:	83 ec 04             	sub    $0x4,%esp
f0104526:	6a 01                	push   $0x1
f0104528:	8d 45 dc             	lea    -0x24(%ebp),%eax
f010452b:	50                   	push   %eax
f010452c:	ff 75 0c             	pushl  0xc(%ebp)
f010452f:	e8 c6 e8 ff ff       	call   f0102dfa <envid2env>
    if(r!=0)
f0104534:	83 c4 10             	add    $0x10,%esp
f0104537:	85 c0                	test   %eax,%eax
f0104539:	0f 85 17 03 00 00    	jne    f0104856 <syscall+0x557>
        return r;
    r = envid2env(dstenvid, &dstenv, 1);
f010453f:	83 ec 04             	sub    $0x4,%esp
f0104542:	6a 01                	push   $0x1
f0104544:	8d 45 e0             	lea    -0x20(%ebp),%eax
f0104547:	50                   	push   %eax
f0104548:	ff 75 14             	pushl  0x14(%ebp)
f010454b:	e8 aa e8 ff ff       	call   f0102dfa <envid2env>
    if(r!=0)
f0104550:	83 c4 10             	add    $0x10,%esp
f0104553:	85 c0                	test   %eax,%eax
f0104555:	0f 85 fb 02 00 00    	jne    f0104856 <syscall+0x557>
        return r;

    if (srcva >= (void *) UTOP || dstva >= (void *) UTOP || 
f010455b:	81 7d 10 ff ff bf ee 	cmpl   $0xeebfffff,0x10(%ebp)
f0104562:	77 77                	ja     f01045db <syscall+0x2dc>
f0104564:	81 7d 18 ff ff bf ee 	cmpl   $0xeebfffff,0x18(%ebp)
f010456b:	77 6e                	ja     f01045db <syscall+0x2dc>
f010456d:	f7 45 10 ff 0f 00 00 	testl  $0xfff,0x10(%ebp)
f0104574:	75 6f                	jne    f01045e5 <syscall+0x2e6>
        srcva != ROUNDDOWN(srcva, PGSIZE) || dstva != ROUNDDOWN(dstva, PGSIZE))
        return -E_INVAL; 
f0104576:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
    r = envid2env(dstenvid, &dstenv, 1);
    if(r!=0)
        return r;

    if (srcva >= (void *) UTOP || dstva >= (void *) UTOP || 
        srcva != ROUNDDOWN(srcva, PGSIZE) || dstva != ROUNDDOWN(dstva, PGSIZE))
f010457b:	f7 45 18 ff 0f 00 00 	testl  $0xfff,0x18(%ebp)
f0104582:	0f 85 ce 02 00 00    	jne    f0104856 <syscall+0x557>
        return -E_INVAL; 

    pte_t *pte;
    struct PageInfo *pp = page_lookup(srcenv->env_pgdir, srcva, &pte);
f0104588:	83 ec 04             	sub    $0x4,%esp
f010458b:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010458e:	50                   	push   %eax
f010458f:	ff 75 10             	pushl  0x10(%ebp)
f0104592:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0104595:	ff 70 60             	pushl  0x60(%eax)
f0104598:	e8 9a cb ff ff       	call   f0101137 <page_lookup>
    if(pp == NULL)    
f010459d:	83 c4 10             	add    $0x10,%esp
f01045a0:	85 c0                	test   %eax,%eax
f01045a2:	74 4b                	je     f01045ef <syscall+0x2f0>
        return -E_INVAL;

    if ((!(perm & (PTE_U | PTE_P))) || (perm & (~(PTE_U | PTE_P | PTE_AVAIL | PTE_W))))
f01045a4:	f6 45 1c 05          	testb  $0x5,0x1c(%ebp)
f01045a8:	74 4f                	je     f01045f9 <syscall+0x2fa>
f01045aa:	f7 45 1c f8 f1 ff ff 	testl  $0xfffff1f8,0x1c(%ebp)
f01045b1:	75 50                	jne    f0104603 <syscall+0x304>
        return -E_INVAL;

    if ((perm & PTE_W) && !(*pte & PTE_W))
f01045b3:	f6 45 1c 02          	testb  $0x2,0x1c(%ebp)
f01045b7:	74 08                	je     f01045c1 <syscall+0x2c2>
f01045b9:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01045bc:	f6 02 02             	testb  $0x2,(%edx)
f01045bf:	74 4c                	je     f010460d <syscall+0x30e>
        return -E_INVAL;

    r = page_insert(dstenv->env_pgdir, pp, dstva, perm);
f01045c1:	ff 75 1c             	pushl  0x1c(%ebp)
f01045c4:	ff 75 18             	pushl  0x18(%ebp)
f01045c7:	50                   	push   %eax
f01045c8:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01045cb:	ff 70 60             	pushl  0x60(%eax)
f01045ce:	e8 39 cc ff ff       	call   f010120c <page_insert>
f01045d3:	83 c4 10             	add    $0x10,%esp
f01045d6:	e9 7b 02 00 00       	jmp    f0104856 <syscall+0x557>
    if(r!=0)
        return r;

    if (srcva >= (void *) UTOP || dstva >= (void *) UTOP || 
        srcva != ROUNDDOWN(srcva, PGSIZE) || dstva != ROUNDDOWN(dstva, PGSIZE))
        return -E_INVAL; 
f01045db:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f01045e0:	e9 71 02 00 00       	jmp    f0104856 <syscall+0x557>
f01045e5:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f01045ea:	e9 67 02 00 00       	jmp    f0104856 <syscall+0x557>

    pte_t *pte;
    struct PageInfo *pp = page_lookup(srcenv->env_pgdir, srcva, &pte);
    if(pp == NULL)    
        return -E_INVAL;
f01045ef:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f01045f4:	e9 5d 02 00 00       	jmp    f0104856 <syscall+0x557>

    if ((!(perm & (PTE_U | PTE_P))) || (perm & (~(PTE_U | PTE_P | PTE_AVAIL | PTE_W))))
        return -E_INVAL;
f01045f9:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f01045fe:	e9 53 02 00 00       	jmp    f0104856 <syscall+0x557>
f0104603:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104608:	e9 49 02 00 00       	jmp    f0104856 <syscall+0x557>

    if ((perm & PTE_W) && !(*pte & PTE_W))
        return -E_INVAL;
f010460d:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
        case SYS_exofork:
            return sys_exofork();
        case SYS_page_alloc:
            return sys_page_alloc(a1, (void *) a2, a3);
        case SYS_page_map:
            return sys_page_map(a1, (void *) a2, a3, (void *) a4, a5);
f0104612:	e9 3f 02 00 00       	jmp    f0104856 <syscall+0x557>
sys_page_unmap(envid_t envid, void *va)
{
	// Hint: This function is a wrapper around page_remove().

    struct Env *env;
    int r = envid2env(envid, &env, 1);
f0104617:	83 ec 04             	sub    $0x4,%esp
f010461a:	6a 01                	push   $0x1
f010461c:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010461f:	50                   	push   %eax
f0104620:	ff 75 0c             	pushl  0xc(%ebp)
f0104623:	e8 d2 e7 ff ff       	call   f0102dfa <envid2env>
    if(r!=0)
f0104628:	83 c4 10             	add    $0x10,%esp
f010462b:	85 c0                	test   %eax,%eax
f010462d:	0f 85 23 02 00 00    	jne    f0104856 <syscall+0x557>
        return r;
    if (va > (void *)UTOP || va != ROUNDDOWN(va, PGSIZE))
f0104633:	81 7d 10 00 00 c0 ee 	cmpl   $0xeec00000,0x10(%ebp)
f010463a:	77 30                	ja     f010466c <syscall+0x36d>
        return -E_INVAL; 
f010463c:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

    struct Env *env;
    int r = envid2env(envid, &env, 1);
    if(r!=0)
        return r;
    if (va > (void *)UTOP || va != ROUNDDOWN(va, PGSIZE))
f0104641:	f7 45 10 ff 0f 00 00 	testl  $0xfff,0x10(%ebp)
f0104648:	0f 85 08 02 00 00    	jne    f0104856 <syscall+0x557>
        return -E_INVAL; 
    
    page_remove(env->env_pgdir, va);
f010464e:	83 ec 08             	sub    $0x8,%esp
f0104651:	ff 75 10             	pushl  0x10(%ebp)
f0104654:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104657:	ff 70 60             	pushl  0x60(%eax)
f010465a:	e8 67 cb ff ff       	call   f01011c6 <page_remove>
f010465f:	83 c4 10             	add    $0x10,%esp
    return 0;
f0104662:	b8 00 00 00 00       	mov    $0x0,%eax
f0104667:	e9 ea 01 00 00       	jmp    f0104856 <syscall+0x557>
    struct Env *env;
    int r = envid2env(envid, &env, 1);
    if(r!=0)
        return r;
    if (va > (void *)UTOP || va != ROUNDDOWN(va, PGSIZE))
        return -E_INVAL; 
f010466c:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104671:	e9 e0 01 00 00       	jmp    f0104856 <syscall+0x557>
	// envid to a struct Env.
	// You should set envid2env's third argument to 1, which will
	// check whether the current environment has permission to set
	// envid's status.
    struct Env *env;
    int r = envid2env(envid, &env, 1);
f0104676:	83 ec 04             	sub    $0x4,%esp
f0104679:	6a 01                	push   $0x1
f010467b:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010467e:	50                   	push   %eax
f010467f:	ff 75 0c             	pushl  0xc(%ebp)
f0104682:	e8 73 e7 ff ff       	call   f0102dfa <envid2env>
    if(r!=0)
f0104687:	83 c4 10             	add    $0x10,%esp
f010468a:	85 c0                	test   %eax,%eax
f010468c:	0f 85 c4 01 00 00    	jne    f0104856 <syscall+0x557>
        return r;
    if(env->env_status == ENV_RUNNABLE || env->env_status == ENV_NOT_RUNNABLE){
f0104692:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0104695:	8b 42 54             	mov    0x54(%edx),%eax
f0104698:	83 e8 02             	sub    $0x2,%eax
f010469b:	a9 fd ff ff ff       	test   $0xfffffffd,%eax
f01046a0:	75 10                	jne    f01046b2 <syscall+0x3b3>
        env->env_status = status;
f01046a2:	8b 45 10             	mov    0x10(%ebp),%eax
f01046a5:	89 42 54             	mov    %eax,0x54(%edx)
        return 0;
f01046a8:	b8 00 00 00 00       	mov    $0x0,%eax
f01046ad:	e9 a4 01 00 00       	jmp    f0104856 <syscall+0x557>
    }
    return -E_INVAL; 
f01046b2:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
        case SYS_page_map:
            return sys_page_map(a1, (void *) a2, a3, (void *) a4, a5);
        case SYS_page_unmap:
            return sys_page_unmap(a1, (void *) a2);
        case SYS_env_set_status:
            return sys_env_set_status(a1, a2);
f01046b7:	e9 9a 01 00 00       	jmp    f0104856 <syscall+0x557>
static int
sys_env_set_pgfault_upcall(envid_t envid, void *func)
{
	// LAB 4: Your code here.
    struct Env *env;
    int r = envid2env(envid, &env, 1);
f01046bc:	83 ec 04             	sub    $0x4,%esp
f01046bf:	6a 01                	push   $0x1
f01046c1:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01046c4:	50                   	push   %eax
f01046c5:	ff 75 0c             	pushl  0xc(%ebp)
f01046c8:	e8 2d e7 ff ff       	call   f0102dfa <envid2env>
    if(r!=0)
f01046cd:	83 c4 10             	add    $0x10,%esp
f01046d0:	85 c0                	test   %eax,%eax
f01046d2:	0f 85 7e 01 00 00    	jne    f0104856 <syscall+0x557>
        return r;
    env->env_pgfault_upcall = func;
f01046d8:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01046db:	8b 7d 10             	mov    0x10(%ebp),%edi
f01046de:	89 7a 64             	mov    %edi,0x64(%edx)
        case SYS_page_unmap:
            return sys_page_unmap(a1, (void *) a2);
        case SYS_env_set_status:
            return sys_env_set_status(a1, a2);
        case SYS_env_set_pgfault_upcall:
            return sys_env_set_pgfault_upcall(a1,(void *) a2);
f01046e1:	e9 70 01 00 00       	jmp    f0104856 <syscall+0x557>
//		address space.
static int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, unsigned perm)
{
    struct Env *env;
    int r = envid2env(envid, &env, 0);
f01046e6:	83 ec 04             	sub    $0x4,%esp
f01046e9:	6a 00                	push   $0x0
f01046eb:	8d 45 e0             	lea    -0x20(%ebp),%eax
f01046ee:	50                   	push   %eax
f01046ef:	ff 75 0c             	pushl  0xc(%ebp)
f01046f2:	e8 03 e7 ff ff       	call   f0102dfa <envid2env>
    int flag = PTE_U | PTE_P;
    if(r!=0)
f01046f7:	83 c4 10             	add    $0x10,%esp
f01046fa:	85 c0                	test   %eax,%eax
f01046fc:	0f 85 54 01 00 00    	jne    f0104856 <syscall+0x557>
        return r;
    if(!env->env_ipc_recving)
f0104702:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104705:	80 78 68 00          	cmpb   $0x0,0x68(%eax)
f0104709:	0f 84 e2 00 00 00    	je     f01047f1 <syscall+0x4f2>
        return -E_IPC_NOT_RECV;
    if(srcva < (void *) UTOP){
f010470f:	81 7d 14 ff ff bf ee 	cmpl   $0xeebfffff,0x14(%ebp)
f0104716:	0f 87 9c 00 00 00    	ja     f01047b8 <syscall+0x4b9>
        if(srcva != ROUNDUP(srcva, PGSIZE)) 
f010471c:	8b 45 14             	mov    0x14(%ebp),%eax
f010471f:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0104725:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
            return -E_INVAL;
f010472b:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
    if(r!=0)
        return r;
    if(!env->env_ipc_recving)
        return -E_IPC_NOT_RECV;
    if(srcva < (void *) UTOP){
        if(srcva != ROUNDUP(srcva, PGSIZE)) 
f0104730:	39 55 14             	cmp    %edx,0x14(%ebp)
f0104733:	0f 85 1d 01 00 00    	jne    f0104856 <syscall+0x557>
            return -E_INVAL;

        pte_t *pte;
        struct PageInfo *pp = page_lookup(curenv->env_pgdir, srcva, &pte);
f0104739:	e8 e8 12 00 00       	call   f0105a26 <cpunum>
f010473e:	83 ec 04             	sub    $0x4,%esp
f0104741:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0104744:	52                   	push   %edx
f0104745:	ff 75 14             	pushl  0x14(%ebp)
f0104748:	6b c0 74             	imul   $0x74,%eax,%eax
f010474b:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f0104751:	ff 70 60             	pushl  0x60(%eax)
f0104754:	e8 de c9 ff ff       	call   f0101137 <page_lookup>
f0104759:	89 c2                	mov    %eax,%edx
        if(pp == NULL)
f010475b:	83 c4 10             	add    $0x10,%esp
f010475e:	85 c0                	test   %eax,%eax
f0104760:	74 4c                	je     f01047ae <syscall+0x4af>
            return -E_INVAL;

        if ((!(perm & (PTE_U | PTE_P))) || (perm & (~(PTE_U | PTE_P | PTE_AVAIL | PTE_W))))
            return -E_INVAL;
f0104762:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
        pte_t *pte;
        struct PageInfo *pp = page_lookup(curenv->env_pgdir, srcva, &pte);
        if(pp == NULL)
            return -E_INVAL;

        if ((!(perm & (PTE_U | PTE_P))) || (perm & (~(PTE_U | PTE_P | PTE_AVAIL | PTE_W))))
f0104767:	f6 45 18 05          	testb  $0x5,0x18(%ebp)
f010476b:	0f 84 e5 00 00 00    	je     f0104856 <syscall+0x557>
f0104771:	f7 45 18 f8 f1 ff ff 	testl  $0xfffff1f8,0x18(%ebp)
f0104778:	0f 85 d8 00 00 00    	jne    f0104856 <syscall+0x557>
            return -E_INVAL;

        if ((perm & PTE_W) && !(*pte & PTE_W))
f010477e:	f6 45 18 02          	testb  $0x2,0x18(%ebp)
f0104782:	74 0c                	je     f0104790 <syscall+0x491>
f0104784:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0104787:	f6 01 02             	testb  $0x2,(%ecx)
f010478a:	0f 84 c6 00 00 00    	je     f0104856 <syscall+0x557>
            return -E_INVAL;

        r = page_insert(env->env_pgdir, pp, env->env_ipc_dstva, perm);
f0104790:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104793:	ff 75 18             	pushl  0x18(%ebp)
f0104796:	ff 70 6c             	pushl  0x6c(%eax)
f0104799:	52                   	push   %edx
f010479a:	ff 70 60             	pushl  0x60(%eax)
f010479d:	e8 6a ca ff ff       	call   f010120c <page_insert>
        if(r!=0)
f01047a2:	83 c4 10             	add    $0x10,%esp
f01047a5:	85 c0                	test   %eax,%eax
f01047a7:	74 0f                	je     f01047b8 <syscall+0x4b9>
f01047a9:	e9 a8 00 00 00       	jmp    f0104856 <syscall+0x557>
            return -E_INVAL;

        pte_t *pte;
        struct PageInfo *pp = page_lookup(curenv->env_pgdir, srcva, &pte);
        if(pp == NULL)
            return -E_INVAL;
f01047ae:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f01047b3:	e9 9e 00 00 00       	jmp    f0104856 <syscall+0x557>

        r = page_insert(env->env_pgdir, pp, env->env_ipc_dstva, perm);
        if(r!=0)
            return r;
    }
    env->env_ipc_value = value;
f01047b8:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f01047bb:	8b 45 10             	mov    0x10(%ebp),%eax
f01047be:	89 43 70             	mov    %eax,0x70(%ebx)
    env->env_ipc_recving = false;
f01047c1:	c6 43 68 00          	movb   $0x0,0x68(%ebx)
    env->env_ipc_from = curenv->env_id;
f01047c5:	e8 5c 12 00 00       	call   f0105a26 <cpunum>
f01047ca:	6b c0 74             	imul   $0x74,%eax,%eax
f01047cd:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f01047d3:	8b 40 48             	mov    0x48(%eax),%eax
f01047d6:	89 43 74             	mov    %eax,0x74(%ebx)
    env->env_status = ENV_RUNNABLE;
f01047d9:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01047dc:	c7 40 54 02 00 00 00 	movl   $0x2,0x54(%eax)
    env->env_tf.tf_regs.reg_eax = 0;
f01047e3:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)
    return 0;
f01047ea:	b8 00 00 00 00       	mov    $0x0,%eax
f01047ef:	eb 65                	jmp    f0104856 <syscall+0x557>
    int r = envid2env(envid, &env, 0);
    int flag = PTE_U | PTE_P;
    if(r!=0)
        return r;
    if(!env->env_ipc_recving)
        return -E_IPC_NOT_RECV;
f01047f1:	b8 f9 ff ff ff       	mov    $0xfffffff9,%eax
        case SYS_env_set_status:
            return sys_env_set_status(a1, a2);
        case SYS_env_set_pgfault_upcall:
            return sys_env_set_pgfault_upcall(a1,(void *) a2);
        case SYS_ipc_try_send:
            return sys_ipc_try_send(a1, a2, (void *)a3, a4);
f01047f6:	eb 5e                	jmp    f0104856 <syscall+0x557>
//	-E_INVAL if dstva < UTOP but dstva is not page-aligned.
static int
sys_ipc_recv(void *dstva)
{
	// LAB 4: Your code here.
    if(dstva < (void *)UTOP && dstva != ROUNDDOWN(dstva, PGSIZE)){
f01047f8:	81 7d 0c ff ff bf ee 	cmpl   $0xeebfffff,0xc(%ebp)
f01047ff:	77 09                	ja     f010480a <syscall+0x50b>
f0104801:	f7 45 0c ff 0f 00 00 	testl  $0xfff,0xc(%ebp)
f0104808:	75 47                	jne    f0104851 <syscall+0x552>
        return -E_INVAL; 
    }
    curenv->env_ipc_recving =true;
f010480a:	e8 17 12 00 00       	call   f0105a26 <cpunum>
f010480f:	6b c0 74             	imul   $0x74,%eax,%eax
f0104812:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f0104818:	c6 40 68 01          	movb   $0x1,0x68(%eax)
    curenv->env_ipc_dstva = dstva;
f010481c:	e8 05 12 00 00       	call   f0105a26 <cpunum>
f0104821:	6b c0 74             	imul   $0x74,%eax,%eax
f0104824:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f010482a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010482d:	89 48 6c             	mov    %ecx,0x6c(%eax)
    curenv->env_status = ENV_NOT_RUNNABLE;
f0104830:	e8 f1 11 00 00       	call   f0105a26 <cpunum>
f0104835:	6b c0 74             	imul   $0x74,%eax,%eax
f0104838:	8b 80 28 00 23 f0    	mov    -0xfdcffd8(%eax),%eax
f010483e:	c7 40 54 04 00 00 00 	movl   $0x4,0x54(%eax)

// Deschedule current environment and pick a different one to run.
static void
sys_yield(void)
{
	sched_yield();
f0104845:	e8 f1 f9 ff ff       	call   f010423b <sched_yield>
        case SYS_ipc_try_send:
            return sys_ipc_try_send(a1, a2, (void *)a3, a4);
        case SYS_ipc_recv:
            return sys_ipc_recv((void *)a1);
		default:
			return -E_INVAL;
f010484a:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f010484f:	eb 05                	jmp    f0104856 <syscall+0x557>
        case SYS_env_set_pgfault_upcall:
            return sys_env_set_pgfault_upcall(a1,(void *) a2);
        case SYS_ipc_try_send:
            return sys_ipc_try_send(a1, a2, (void *)a3, a4);
        case SYS_ipc_recv:
            return sys_ipc_recv((void *)a1);
f0104851:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
		default:
			return -E_INVAL;
	}
}
f0104856:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104859:	5b                   	pop    %ebx
f010485a:	5e                   	pop    %esi
f010485b:	5f                   	pop    %edi
f010485c:	5d                   	pop    %ebp
f010485d:	c3                   	ret    

f010485e <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f010485e:	55                   	push   %ebp
f010485f:	89 e5                	mov    %esp,%ebp
f0104861:	57                   	push   %edi
f0104862:	56                   	push   %esi
f0104863:	53                   	push   %ebx
f0104864:	83 ec 14             	sub    $0x14,%esp
f0104867:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010486a:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f010486d:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0104870:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0104873:	8b 1a                	mov    (%edx),%ebx
f0104875:	8b 01                	mov    (%ecx),%eax
f0104877:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010487a:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0104881:	eb 7f                	jmp    f0104902 <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f0104883:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0104886:	01 d8                	add    %ebx,%eax
f0104888:	89 c6                	mov    %eax,%esi
f010488a:	c1 ee 1f             	shr    $0x1f,%esi
f010488d:	01 c6                	add    %eax,%esi
f010488f:	d1 fe                	sar    %esi
f0104891:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0104894:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0104897:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f010489a:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f010489c:	eb 03                	jmp    f01048a1 <stab_binsearch+0x43>
			m--;
f010489e:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01048a1:	39 c3                	cmp    %eax,%ebx
f01048a3:	7f 0d                	jg     f01048b2 <stab_binsearch+0x54>
f01048a5:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01048a9:	83 ea 0c             	sub    $0xc,%edx
f01048ac:	39 f9                	cmp    %edi,%ecx
f01048ae:	75 ee                	jne    f010489e <stab_binsearch+0x40>
f01048b0:	eb 05                	jmp    f01048b7 <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f01048b2:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f01048b5:	eb 4b                	jmp    f0104902 <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01048b7:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01048ba:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01048bd:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f01048c1:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01048c4:	76 11                	jbe    f01048d7 <stab_binsearch+0x79>
			*region_left = m;
f01048c6:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01048c9:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f01048cb:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01048ce:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01048d5:	eb 2b                	jmp    f0104902 <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f01048d7:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01048da:	73 14                	jae    f01048f0 <stab_binsearch+0x92>
			*region_right = m - 1;
f01048dc:	83 e8 01             	sub    $0x1,%eax
f01048df:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01048e2:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01048e5:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01048e7:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01048ee:	eb 12                	jmp    f0104902 <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01048f0:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01048f3:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f01048f5:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f01048f9:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01048fb:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0104902:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0104905:	0f 8e 78 ff ff ff    	jle    f0104883 <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f010490b:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f010490f:	75 0f                	jne    f0104920 <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f0104911:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104914:	8b 00                	mov    (%eax),%eax
f0104916:	83 e8 01             	sub    $0x1,%eax
f0104919:	8b 75 e0             	mov    -0x20(%ebp),%esi
f010491c:	89 06                	mov    %eax,(%esi)
f010491e:	eb 2c                	jmp    f010494c <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0104920:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104923:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0104925:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0104928:	8b 0e                	mov    (%esi),%ecx
f010492a:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010492d:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0104930:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0104933:	eb 03                	jmp    f0104938 <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0104935:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0104938:	39 c8                	cmp    %ecx,%eax
f010493a:	7e 0b                	jle    f0104947 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f010493c:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0104940:	83 ea 0c             	sub    $0xc,%edx
f0104943:	39 df                	cmp    %ebx,%edi
f0104945:	75 ee                	jne    f0104935 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f0104947:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010494a:	89 06                	mov    %eax,(%esi)
	}
}
f010494c:	83 c4 14             	add    $0x14,%esp
f010494f:	5b                   	pop    %ebx
f0104950:	5e                   	pop    %esi
f0104951:	5f                   	pop    %edi
f0104952:	5d                   	pop    %ebp
f0104953:	c3                   	ret    

f0104954 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0104954:	55                   	push   %ebp
f0104955:	89 e5                	mov    %esp,%ebp
f0104957:	57                   	push   %edi
f0104958:	56                   	push   %esi
f0104959:	53                   	push   %ebx
f010495a:	83 ec 3c             	sub    $0x3c,%esp
f010495d:	8b 7d 08             	mov    0x8(%ebp),%edi
f0104960:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0104963:	c7 03 f4 77 10 f0    	movl   $0xf01077f4,(%ebx)
	info->eip_line = 0;
f0104969:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0104970:	c7 43 08 f4 77 10 f0 	movl   $0xf01077f4,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0104977:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f010497e:	89 7b 10             	mov    %edi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0104981:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0104988:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f010498e:	0f 87 f6 00 00 00    	ja     f0104a8a <debuginfo_eip+0x136>
		const struct UserStabData *usd = (const struct UserStabData *) USTABDATA;

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, usd, sizeof(struct UserStabData), PTE_U) < 0) {
f0104994:	e8 8d 10 00 00       	call   f0105a26 <cpunum>
f0104999:	6a 04                	push   $0x4
f010499b:	6a 10                	push   $0x10
f010499d:	68 00 00 20 00       	push   $0x200000
f01049a2:	6b c0 74             	imul   $0x74,%eax,%eax
f01049a5:	ff b0 28 00 23 f0    	pushl  -0xfdcffd8(%eax)
f01049ab:	e8 0f e3 ff ff       	call   f0102cbf <user_mem_check>
f01049b0:	83 c4 10             	add    $0x10,%esp
f01049b3:	85 c0                	test   %eax,%eax
f01049b5:	79 1f                	jns    f01049d6 <debuginfo_eip+0x82>
			cprintf("debuginfo_eip: invalid usd addr %08x", usd);
f01049b7:	83 ec 08             	sub    $0x8,%esp
f01049ba:	68 00 00 20 00       	push   $0x200000
f01049bf:	68 00 78 10 f0       	push   $0xf0107800
f01049c4:	e8 95 ec ff ff       	call   f010365e <cprintf>
			return -1;
f01049c9:	83 c4 10             	add    $0x10,%esp
f01049cc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01049d1:	e9 97 02 00 00       	jmp    f0104c6d <debuginfo_eip+0x319>
		}

		stabs = usd->stabs;
f01049d6:	a1 00 00 20 00       	mov    0x200000,%eax
f01049db:	89 45 c0             	mov    %eax,-0x40(%ebp)
		stab_end = usd->stab_end;
f01049de:	8b 35 04 00 20 00    	mov    0x200004,%esi
		stabstr = usd->stabstr;
f01049e4:	8b 15 08 00 20 00    	mov    0x200008,%edx
f01049ea:	89 55 b8             	mov    %edx,-0x48(%ebp)
		stabstr_end = usd->stabstr_end;
f01049ed:	8b 15 0c 00 20 00    	mov    0x20000c,%edx
f01049f3:	89 55 bc             	mov    %edx,-0x44(%ebp)

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, stabs, stab_end-stabs+1, PTE_U) < 0){
f01049f6:	e8 2b 10 00 00       	call   f0105a26 <cpunum>
f01049fb:	6a 04                	push   $0x4
f01049fd:	89 f2                	mov    %esi,%edx
f01049ff:	8b 4d c0             	mov    -0x40(%ebp),%ecx
f0104a02:	29 ca                	sub    %ecx,%edx
f0104a04:	c1 fa 02             	sar    $0x2,%edx
f0104a07:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f0104a0d:	83 c2 01             	add    $0x1,%edx
f0104a10:	52                   	push   %edx
f0104a11:	51                   	push   %ecx
f0104a12:	6b c0 74             	imul   $0x74,%eax,%eax
f0104a15:	ff b0 28 00 23 f0    	pushl  -0xfdcffd8(%eax)
f0104a1b:	e8 9f e2 ff ff       	call   f0102cbf <user_mem_check>
f0104a20:	83 c4 10             	add    $0x10,%esp
f0104a23:	85 c0                	test   %eax,%eax
f0104a25:	79 1d                	jns    f0104a44 <debuginfo_eip+0xf0>
			cprintf("debuginfo_eip: invalid stabs addr %08x", stabs);
f0104a27:	83 ec 08             	sub    $0x8,%esp
f0104a2a:	ff 75 c0             	pushl  -0x40(%ebp)
f0104a2d:	68 28 78 10 f0       	push   $0xf0107828
f0104a32:	e8 27 ec ff ff       	call   f010365e <cprintf>
			return -1;
f0104a37:	83 c4 10             	add    $0x10,%esp
f0104a3a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104a3f:	e9 29 02 00 00       	jmp    f0104c6d <debuginfo_eip+0x319>
		}
		if (user_mem_check(curenv, stabstr, stabstr_end-stabstr+1, PTE_U) < 0) {
f0104a44:	e8 dd 0f 00 00       	call   f0105a26 <cpunum>
f0104a49:	6a 04                	push   $0x4
f0104a4b:	8b 55 bc             	mov    -0x44(%ebp),%edx
f0104a4e:	8b 4d b8             	mov    -0x48(%ebp),%ecx
f0104a51:	29 ca                	sub    %ecx,%edx
f0104a53:	83 c2 01             	add    $0x1,%edx
f0104a56:	52                   	push   %edx
f0104a57:	51                   	push   %ecx
f0104a58:	6b c0 74             	imul   $0x74,%eax,%eax
f0104a5b:	ff b0 28 00 23 f0    	pushl  -0xfdcffd8(%eax)
f0104a61:	e8 59 e2 ff ff       	call   f0102cbf <user_mem_check>
f0104a66:	83 c4 10             	add    $0x10,%esp
f0104a69:	85 c0                	test   %eax,%eax
f0104a6b:	79 37                	jns    f0104aa4 <debuginfo_eip+0x150>
			cprintf("debuginfo_eip: invalid stabstr addr %08x", stabstr);
f0104a6d:	83 ec 08             	sub    $0x8,%esp
f0104a70:	ff 75 b8             	pushl  -0x48(%ebp)
f0104a73:	68 50 78 10 f0       	push   $0xf0107850
f0104a78:	e8 e1 eb ff ff       	call   f010365e <cprintf>
			return -1;
f0104a7d:	83 c4 10             	add    $0x10,%esp
f0104a80:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104a85:	e9 e3 01 00 00       	jmp    f0104c6d <debuginfo_eip+0x319>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f0104a8a:	c7 45 bc 66 54 11 f0 	movl   $0xf0115466,-0x44(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f0104a91:	c7 45 b8 f9 1d 11 f0 	movl   $0xf0111df9,-0x48(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f0104a98:	be f8 1d 11 f0       	mov    $0xf0111df8,%esi
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f0104a9d:	c7 45 c0 54 7d 10 f0 	movl   $0xf0107d54,-0x40(%ebp)
			return -1;
		}
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0104aa4:	8b 45 bc             	mov    -0x44(%ebp),%eax
f0104aa7:	39 45 b8             	cmp    %eax,-0x48(%ebp)
f0104aaa:	0f 83 9c 01 00 00    	jae    f0104c4c <debuginfo_eip+0x2f8>
f0104ab0:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f0104ab4:	0f 85 99 01 00 00    	jne    f0104c53 <debuginfo_eip+0x2ff>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0104aba:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0104ac1:	2b 75 c0             	sub    -0x40(%ebp),%esi
f0104ac4:	c1 fe 02             	sar    $0x2,%esi
f0104ac7:	69 c6 ab aa aa aa    	imul   $0xaaaaaaab,%esi,%eax
f0104acd:	83 e8 01             	sub    $0x1,%eax
f0104ad0:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0104ad3:	83 ec 08             	sub    $0x8,%esp
f0104ad6:	57                   	push   %edi
f0104ad7:	6a 64                	push   $0x64
f0104ad9:	8d 55 e0             	lea    -0x20(%ebp),%edx
f0104adc:	89 d1                	mov    %edx,%ecx
f0104ade:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0104ae1:	8b 75 c0             	mov    -0x40(%ebp),%esi
f0104ae4:	89 f0                	mov    %esi,%eax
f0104ae6:	e8 73 fd ff ff       	call   f010485e <stab_binsearch>
	if (lfile == 0)
f0104aeb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104aee:	83 c4 10             	add    $0x10,%esp
f0104af1:	85 c0                	test   %eax,%eax
f0104af3:	0f 84 61 01 00 00    	je     f0104c5a <debuginfo_eip+0x306>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0104af9:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0104afc:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104aff:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0104b02:	83 ec 08             	sub    $0x8,%esp
f0104b05:	57                   	push   %edi
f0104b06:	6a 24                	push   $0x24
f0104b08:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0104b0b:	89 d1                	mov    %edx,%ecx
f0104b0d:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0104b10:	89 f0                	mov    %esi,%eax
f0104b12:	e8 47 fd ff ff       	call   f010485e <stab_binsearch>

	if (lfun <= rfun) {
f0104b17:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0104b1a:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0104b1d:	83 c4 10             	add    $0x10,%esp
f0104b20:	39 d0                	cmp    %edx,%eax
f0104b22:	7f 2e                	jg     f0104b52 <debuginfo_eip+0x1fe>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0104b24:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f0104b27:	8d 34 8e             	lea    (%esi,%ecx,4),%esi
f0104b2a:	89 75 c4             	mov    %esi,-0x3c(%ebp)
f0104b2d:	8b 36                	mov    (%esi),%esi
f0104b2f:	8b 4d bc             	mov    -0x44(%ebp),%ecx
f0104b32:	2b 4d b8             	sub    -0x48(%ebp),%ecx
f0104b35:	39 ce                	cmp    %ecx,%esi
f0104b37:	73 06                	jae    f0104b3f <debuginfo_eip+0x1eb>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0104b39:	03 75 b8             	add    -0x48(%ebp),%esi
f0104b3c:	89 73 08             	mov    %esi,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0104b3f:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f0104b42:	8b 4e 08             	mov    0x8(%esi),%ecx
f0104b45:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0104b48:	29 cf                	sub    %ecx,%edi
		// Search within the function definition for the line number.
		lline = lfun;
f0104b4a:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0104b4d:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0104b50:	eb 0f                	jmp    f0104b61 <debuginfo_eip+0x20d>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0104b52:	89 7b 10             	mov    %edi,0x10(%ebx)
		lline = lfile;
f0104b55:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104b58:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0104b5b:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104b5e:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0104b61:	83 ec 08             	sub    $0x8,%esp
f0104b64:	6a 3a                	push   $0x3a
f0104b66:	ff 73 08             	pushl  0x8(%ebx)
f0104b69:	e8 7a 08 00 00       	call   f01053e8 <strfind>
f0104b6e:	2b 43 08             	sub    0x8(%ebx),%eax
f0104b71:	89 43 0c             	mov    %eax,0xc(%ebx)
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.

	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);	
f0104b74:	83 c4 08             	add    $0x8,%esp
f0104b77:	57                   	push   %edi
f0104b78:	6a 44                	push   $0x44
f0104b7a:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0104b7d:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0104b80:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0104b83:	89 f8                	mov    %edi,%eax
f0104b85:	e8 d4 fc ff ff       	call   f010485e <stab_binsearch>
	if (lline > rline)
f0104b8a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0104b8d:	83 c4 10             	add    $0x10,%esp
f0104b90:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0104b93:	0f 8f c8 00 00 00    	jg     f0104c61 <debuginfo_eip+0x30d>
		    return -1;
	info->eip_line = stabs[lline].n_desc;
f0104b99:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0104b9c:	8d 14 97             	lea    (%edi,%edx,4),%edx
f0104b9f:	0f b7 4a 06          	movzwl 0x6(%edx),%ecx
f0104ba3:	89 4b 04             	mov    %ecx,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0104ba6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104ba9:	c6 45 c4 00          	movb   $0x0,-0x3c(%ebp)
f0104bad:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0104bb0:	eb 0a                	jmp    f0104bbc <debuginfo_eip+0x268>
f0104bb2:	83 e8 01             	sub    $0x1,%eax
f0104bb5:	83 ea 0c             	sub    $0xc,%edx
f0104bb8:	c6 45 c4 01          	movb   $0x1,-0x3c(%ebp)
f0104bbc:	39 c7                	cmp    %eax,%edi
f0104bbe:	7e 05                	jle    f0104bc5 <debuginfo_eip+0x271>
f0104bc0:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104bc3:	eb 47                	jmp    f0104c0c <debuginfo_eip+0x2b8>
	       && stabs[lline].n_type != N_SOL
f0104bc5:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0104bc9:	80 f9 84             	cmp    $0x84,%cl
f0104bcc:	75 0e                	jne    f0104bdc <debuginfo_eip+0x288>
f0104bce:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104bd1:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f0104bd5:	74 1c                	je     f0104bf3 <debuginfo_eip+0x29f>
f0104bd7:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0104bda:	eb 17                	jmp    f0104bf3 <debuginfo_eip+0x29f>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0104bdc:	80 f9 64             	cmp    $0x64,%cl
f0104bdf:	75 d1                	jne    f0104bb2 <debuginfo_eip+0x25e>
f0104be1:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f0104be5:	74 cb                	je     f0104bb2 <debuginfo_eip+0x25e>
f0104be7:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104bea:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f0104bee:	74 03                	je     f0104bf3 <debuginfo_eip+0x29f>
f0104bf0:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0104bf3:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0104bf6:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0104bf9:	8b 14 87             	mov    (%edi,%eax,4),%edx
f0104bfc:	8b 45 bc             	mov    -0x44(%ebp),%eax
f0104bff:	8b 7d b8             	mov    -0x48(%ebp),%edi
f0104c02:	29 f8                	sub    %edi,%eax
f0104c04:	39 c2                	cmp    %eax,%edx
f0104c06:	73 04                	jae    f0104c0c <debuginfo_eip+0x2b8>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0104c08:	01 fa                	add    %edi,%edx
f0104c0a:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0104c0c:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0104c0f:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0104c12:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0104c17:	39 f2                	cmp    %esi,%edx
f0104c19:	7d 52                	jge    f0104c6d <debuginfo_eip+0x319>
		for (lline = lfun + 1;
f0104c1b:	83 c2 01             	add    $0x1,%edx
f0104c1e:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0104c21:	89 d0                	mov    %edx,%eax
f0104c23:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0104c26:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0104c29:	8d 14 97             	lea    (%edi,%edx,4),%edx
f0104c2c:	eb 04                	jmp    f0104c32 <debuginfo_eip+0x2de>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0104c2e:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0104c32:	39 c6                	cmp    %eax,%esi
f0104c34:	7e 32                	jle    f0104c68 <debuginfo_eip+0x314>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0104c36:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0104c3a:	83 c0 01             	add    $0x1,%eax
f0104c3d:	83 c2 0c             	add    $0xc,%edx
f0104c40:	80 f9 a0             	cmp    $0xa0,%cl
f0104c43:	74 e9                	je     f0104c2e <debuginfo_eip+0x2da>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0104c45:	b8 00 00 00 00       	mov    $0x0,%eax
f0104c4a:	eb 21                	jmp    f0104c6d <debuginfo_eip+0x319>
		}
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0104c4c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104c51:	eb 1a                	jmp    f0104c6d <debuginfo_eip+0x319>
f0104c53:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104c58:	eb 13                	jmp    f0104c6d <debuginfo_eip+0x319>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0104c5a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104c5f:	eb 0c                	jmp    f0104c6d <debuginfo_eip+0x319>
	//	which one.
	// Your code here.

	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);	
	if (lline > rline)
		    return -1;
f0104c61:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104c66:	eb 05                	jmp    f0104c6d <debuginfo_eip+0x319>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0104c68:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104c6d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104c70:	5b                   	pop    %ebx
f0104c71:	5e                   	pop    %esi
f0104c72:	5f                   	pop    %edi
f0104c73:	5d                   	pop    %ebp
f0104c74:	c3                   	ret    

f0104c75 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0104c75:	55                   	push   %ebp
f0104c76:	89 e5                	mov    %esp,%ebp
f0104c78:	57                   	push   %edi
f0104c79:	56                   	push   %esi
f0104c7a:	53                   	push   %ebx
f0104c7b:	83 ec 1c             	sub    $0x1c,%esp
f0104c7e:	89 c7                	mov    %eax,%edi
f0104c80:	89 d6                	mov    %edx,%esi
f0104c82:	8b 45 08             	mov    0x8(%ebp),%eax
f0104c85:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104c88:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104c8b:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0104c8e:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0104c91:	bb 00 00 00 00       	mov    $0x0,%ebx
f0104c96:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0104c99:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0104c9c:	39 d3                	cmp    %edx,%ebx
f0104c9e:	72 05                	jb     f0104ca5 <printnum+0x30>
f0104ca0:	39 45 10             	cmp    %eax,0x10(%ebp)
f0104ca3:	77 45                	ja     f0104cea <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0104ca5:	83 ec 0c             	sub    $0xc,%esp
f0104ca8:	ff 75 18             	pushl  0x18(%ebp)
f0104cab:	8b 45 14             	mov    0x14(%ebp),%eax
f0104cae:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0104cb1:	53                   	push   %ebx
f0104cb2:	ff 75 10             	pushl  0x10(%ebp)
f0104cb5:	83 ec 08             	sub    $0x8,%esp
f0104cb8:	ff 75 e4             	pushl  -0x1c(%ebp)
f0104cbb:	ff 75 e0             	pushl  -0x20(%ebp)
f0104cbe:	ff 75 dc             	pushl  -0x24(%ebp)
f0104cc1:	ff 75 d8             	pushl  -0x28(%ebp)
f0104cc4:	e8 57 11 00 00       	call   f0105e20 <__udivdi3>
f0104cc9:	83 c4 18             	add    $0x18,%esp
f0104ccc:	52                   	push   %edx
f0104ccd:	50                   	push   %eax
f0104cce:	89 f2                	mov    %esi,%edx
f0104cd0:	89 f8                	mov    %edi,%eax
f0104cd2:	e8 9e ff ff ff       	call   f0104c75 <printnum>
f0104cd7:	83 c4 20             	add    $0x20,%esp
f0104cda:	eb 18                	jmp    f0104cf4 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0104cdc:	83 ec 08             	sub    $0x8,%esp
f0104cdf:	56                   	push   %esi
f0104ce0:	ff 75 18             	pushl  0x18(%ebp)
f0104ce3:	ff d7                	call   *%edi
f0104ce5:	83 c4 10             	add    $0x10,%esp
f0104ce8:	eb 03                	jmp    f0104ced <printnum+0x78>
f0104cea:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0104ced:	83 eb 01             	sub    $0x1,%ebx
f0104cf0:	85 db                	test   %ebx,%ebx
f0104cf2:	7f e8                	jg     f0104cdc <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0104cf4:	83 ec 08             	sub    $0x8,%esp
f0104cf7:	56                   	push   %esi
f0104cf8:	83 ec 04             	sub    $0x4,%esp
f0104cfb:	ff 75 e4             	pushl  -0x1c(%ebp)
f0104cfe:	ff 75 e0             	pushl  -0x20(%ebp)
f0104d01:	ff 75 dc             	pushl  -0x24(%ebp)
f0104d04:	ff 75 d8             	pushl  -0x28(%ebp)
f0104d07:	e8 44 12 00 00       	call   f0105f50 <__umoddi3>
f0104d0c:	83 c4 14             	add    $0x14,%esp
f0104d0f:	0f be 80 79 78 10 f0 	movsbl -0xfef8787(%eax),%eax
f0104d16:	50                   	push   %eax
f0104d17:	ff d7                	call   *%edi
}
f0104d19:	83 c4 10             	add    $0x10,%esp
f0104d1c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104d1f:	5b                   	pop    %ebx
f0104d20:	5e                   	pop    %esi
f0104d21:	5f                   	pop    %edi
f0104d22:	5d                   	pop    %ebp
f0104d23:	c3                   	ret    

f0104d24 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0104d24:	55                   	push   %ebp
f0104d25:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0104d27:	83 fa 01             	cmp    $0x1,%edx
f0104d2a:	7e 0e                	jle    f0104d3a <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0104d2c:	8b 10                	mov    (%eax),%edx
f0104d2e:	8d 4a 08             	lea    0x8(%edx),%ecx
f0104d31:	89 08                	mov    %ecx,(%eax)
f0104d33:	8b 02                	mov    (%edx),%eax
f0104d35:	8b 52 04             	mov    0x4(%edx),%edx
f0104d38:	eb 22                	jmp    f0104d5c <getuint+0x38>
	else if (lflag)
f0104d3a:	85 d2                	test   %edx,%edx
f0104d3c:	74 10                	je     f0104d4e <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0104d3e:	8b 10                	mov    (%eax),%edx
f0104d40:	8d 4a 04             	lea    0x4(%edx),%ecx
f0104d43:	89 08                	mov    %ecx,(%eax)
f0104d45:	8b 02                	mov    (%edx),%eax
f0104d47:	ba 00 00 00 00       	mov    $0x0,%edx
f0104d4c:	eb 0e                	jmp    f0104d5c <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0104d4e:	8b 10                	mov    (%eax),%edx
f0104d50:	8d 4a 04             	lea    0x4(%edx),%ecx
f0104d53:	89 08                	mov    %ecx,(%eax)
f0104d55:	8b 02                	mov    (%edx),%eax
f0104d57:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0104d5c:	5d                   	pop    %ebp
f0104d5d:	c3                   	ret    

f0104d5e <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0104d5e:	55                   	push   %ebp
f0104d5f:	89 e5                	mov    %esp,%ebp
f0104d61:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0104d64:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0104d68:	8b 10                	mov    (%eax),%edx
f0104d6a:	3b 50 04             	cmp    0x4(%eax),%edx
f0104d6d:	73 0a                	jae    f0104d79 <sprintputch+0x1b>
		*b->buf++ = ch;
f0104d6f:	8d 4a 01             	lea    0x1(%edx),%ecx
f0104d72:	89 08                	mov    %ecx,(%eax)
f0104d74:	8b 45 08             	mov    0x8(%ebp),%eax
f0104d77:	88 02                	mov    %al,(%edx)
}
f0104d79:	5d                   	pop    %ebp
f0104d7a:	c3                   	ret    

f0104d7b <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0104d7b:	55                   	push   %ebp
f0104d7c:	89 e5                	mov    %esp,%ebp
f0104d7e:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0104d81:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0104d84:	50                   	push   %eax
f0104d85:	ff 75 10             	pushl  0x10(%ebp)
f0104d88:	ff 75 0c             	pushl  0xc(%ebp)
f0104d8b:	ff 75 08             	pushl  0x8(%ebp)
f0104d8e:	e8 05 00 00 00       	call   f0104d98 <vprintfmt>
	va_end(ap);
}
f0104d93:	83 c4 10             	add    $0x10,%esp
f0104d96:	c9                   	leave  
f0104d97:	c3                   	ret    

f0104d98 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0104d98:	55                   	push   %ebp
f0104d99:	89 e5                	mov    %esp,%ebp
f0104d9b:	57                   	push   %edi
f0104d9c:	56                   	push   %esi
f0104d9d:	53                   	push   %ebx
f0104d9e:	83 ec 2c             	sub    $0x2c,%esp
f0104da1:	8b 75 08             	mov    0x8(%ebp),%esi
f0104da4:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104da7:	8b 7d 10             	mov    0x10(%ebp),%edi
f0104daa:	eb 12                	jmp    f0104dbe <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0104dac:	85 c0                	test   %eax,%eax
f0104dae:	0f 84 89 03 00 00    	je     f010513d <vprintfmt+0x3a5>
				return;
			putch(ch, putdat);
f0104db4:	83 ec 08             	sub    $0x8,%esp
f0104db7:	53                   	push   %ebx
f0104db8:	50                   	push   %eax
f0104db9:	ff d6                	call   *%esi
f0104dbb:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0104dbe:	83 c7 01             	add    $0x1,%edi
f0104dc1:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0104dc5:	83 f8 25             	cmp    $0x25,%eax
f0104dc8:	75 e2                	jne    f0104dac <vprintfmt+0x14>
f0104dca:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0104dce:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0104dd5:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0104ddc:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0104de3:	ba 00 00 00 00       	mov    $0x0,%edx
f0104de8:	eb 07                	jmp    f0104df1 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104dea:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0104ded:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104df1:	8d 47 01             	lea    0x1(%edi),%eax
f0104df4:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0104df7:	0f b6 07             	movzbl (%edi),%eax
f0104dfa:	0f b6 c8             	movzbl %al,%ecx
f0104dfd:	83 e8 23             	sub    $0x23,%eax
f0104e00:	3c 55                	cmp    $0x55,%al
f0104e02:	0f 87 1a 03 00 00    	ja     f0105122 <vprintfmt+0x38a>
f0104e08:	0f b6 c0             	movzbl %al,%eax
f0104e0b:	ff 24 85 40 79 10 f0 	jmp    *-0xfef86c0(,%eax,4)
f0104e12:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0104e15:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0104e19:	eb d6                	jmp    f0104df1 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104e1b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104e1e:	b8 00 00 00 00       	mov    $0x0,%eax
f0104e23:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0104e26:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0104e29:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f0104e2d:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0104e30:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0104e33:	83 fa 09             	cmp    $0x9,%edx
f0104e36:	77 39                	ja     f0104e71 <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0104e38:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0104e3b:	eb e9                	jmp    f0104e26 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0104e3d:	8b 45 14             	mov    0x14(%ebp),%eax
f0104e40:	8d 48 04             	lea    0x4(%eax),%ecx
f0104e43:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0104e46:	8b 00                	mov    (%eax),%eax
f0104e48:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104e4b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0104e4e:	eb 27                	jmp    f0104e77 <vprintfmt+0xdf>
f0104e50:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104e53:	85 c0                	test   %eax,%eax
f0104e55:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104e5a:	0f 49 c8             	cmovns %eax,%ecx
f0104e5d:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104e60:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104e63:	eb 8c                	jmp    f0104df1 <vprintfmt+0x59>
f0104e65:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0104e68:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0104e6f:	eb 80                	jmp    f0104df1 <vprintfmt+0x59>
f0104e71:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0104e74:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0104e77:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0104e7b:	0f 89 70 ff ff ff    	jns    f0104df1 <vprintfmt+0x59>
				width = precision, precision = -1;
f0104e81:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0104e84:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0104e87:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0104e8e:	e9 5e ff ff ff       	jmp    f0104df1 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0104e93:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104e96:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0104e99:	e9 53 ff ff ff       	jmp    f0104df1 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0104e9e:	8b 45 14             	mov    0x14(%ebp),%eax
f0104ea1:	8d 50 04             	lea    0x4(%eax),%edx
f0104ea4:	89 55 14             	mov    %edx,0x14(%ebp)
f0104ea7:	83 ec 08             	sub    $0x8,%esp
f0104eaa:	53                   	push   %ebx
f0104eab:	ff 30                	pushl  (%eax)
f0104ead:	ff d6                	call   *%esi
			break;
f0104eaf:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104eb2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0104eb5:	e9 04 ff ff ff       	jmp    f0104dbe <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0104eba:	8b 45 14             	mov    0x14(%ebp),%eax
f0104ebd:	8d 50 04             	lea    0x4(%eax),%edx
f0104ec0:	89 55 14             	mov    %edx,0x14(%ebp)
f0104ec3:	8b 00                	mov    (%eax),%eax
f0104ec5:	99                   	cltd   
f0104ec6:	31 d0                	xor    %edx,%eax
f0104ec8:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0104eca:	83 f8 08             	cmp    $0x8,%eax
f0104ecd:	7f 0b                	jg     f0104eda <vprintfmt+0x142>
f0104ecf:	8b 14 85 a0 7a 10 f0 	mov    -0xfef8560(,%eax,4),%edx
f0104ed6:	85 d2                	test   %edx,%edx
f0104ed8:	75 18                	jne    f0104ef2 <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f0104eda:	50                   	push   %eax
f0104edb:	68 91 78 10 f0       	push   $0xf0107891
f0104ee0:	53                   	push   %ebx
f0104ee1:	56                   	push   %esi
f0104ee2:	e8 94 fe ff ff       	call   f0104d7b <printfmt>
f0104ee7:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104eea:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0104eed:	e9 cc fe ff ff       	jmp    f0104dbe <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0104ef2:	52                   	push   %edx
f0104ef3:	68 fc 6f 10 f0       	push   $0xf0106ffc
f0104ef8:	53                   	push   %ebx
f0104ef9:	56                   	push   %esi
f0104efa:	e8 7c fe ff ff       	call   f0104d7b <printfmt>
f0104eff:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104f02:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104f05:	e9 b4 fe ff ff       	jmp    f0104dbe <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0104f0a:	8b 45 14             	mov    0x14(%ebp),%eax
f0104f0d:	8d 50 04             	lea    0x4(%eax),%edx
f0104f10:	89 55 14             	mov    %edx,0x14(%ebp)
f0104f13:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0104f15:	85 ff                	test   %edi,%edi
f0104f17:	b8 8a 78 10 f0       	mov    $0xf010788a,%eax
f0104f1c:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0104f1f:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0104f23:	0f 8e 94 00 00 00    	jle    f0104fbd <vprintfmt+0x225>
f0104f29:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0104f2d:	0f 84 98 00 00 00    	je     f0104fcb <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
f0104f33:	83 ec 08             	sub    $0x8,%esp
f0104f36:	ff 75 d0             	pushl  -0x30(%ebp)
f0104f39:	57                   	push   %edi
f0104f3a:	e8 5f 03 00 00       	call   f010529e <strnlen>
f0104f3f:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0104f42:	29 c1                	sub    %eax,%ecx
f0104f44:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0104f47:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0104f4a:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0104f4e:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0104f51:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0104f54:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0104f56:	eb 0f                	jmp    f0104f67 <vprintfmt+0x1cf>
					putch(padc, putdat);
f0104f58:	83 ec 08             	sub    $0x8,%esp
f0104f5b:	53                   	push   %ebx
f0104f5c:	ff 75 e0             	pushl  -0x20(%ebp)
f0104f5f:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0104f61:	83 ef 01             	sub    $0x1,%edi
f0104f64:	83 c4 10             	add    $0x10,%esp
f0104f67:	85 ff                	test   %edi,%edi
f0104f69:	7f ed                	jg     f0104f58 <vprintfmt+0x1c0>
f0104f6b:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0104f6e:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0104f71:	85 c9                	test   %ecx,%ecx
f0104f73:	b8 00 00 00 00       	mov    $0x0,%eax
f0104f78:	0f 49 c1             	cmovns %ecx,%eax
f0104f7b:	29 c1                	sub    %eax,%ecx
f0104f7d:	89 75 08             	mov    %esi,0x8(%ebp)
f0104f80:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0104f83:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0104f86:	89 cb                	mov    %ecx,%ebx
f0104f88:	eb 4d                	jmp    f0104fd7 <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0104f8a:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0104f8e:	74 1b                	je     f0104fab <vprintfmt+0x213>
f0104f90:	0f be c0             	movsbl %al,%eax
f0104f93:	83 e8 20             	sub    $0x20,%eax
f0104f96:	83 f8 5e             	cmp    $0x5e,%eax
f0104f99:	76 10                	jbe    f0104fab <vprintfmt+0x213>
					putch('?', putdat);
f0104f9b:	83 ec 08             	sub    $0x8,%esp
f0104f9e:	ff 75 0c             	pushl  0xc(%ebp)
f0104fa1:	6a 3f                	push   $0x3f
f0104fa3:	ff 55 08             	call   *0x8(%ebp)
f0104fa6:	83 c4 10             	add    $0x10,%esp
f0104fa9:	eb 0d                	jmp    f0104fb8 <vprintfmt+0x220>
				else
					putch(ch, putdat);
f0104fab:	83 ec 08             	sub    $0x8,%esp
f0104fae:	ff 75 0c             	pushl  0xc(%ebp)
f0104fb1:	52                   	push   %edx
f0104fb2:	ff 55 08             	call   *0x8(%ebp)
f0104fb5:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0104fb8:	83 eb 01             	sub    $0x1,%ebx
f0104fbb:	eb 1a                	jmp    f0104fd7 <vprintfmt+0x23f>
f0104fbd:	89 75 08             	mov    %esi,0x8(%ebp)
f0104fc0:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0104fc3:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0104fc6:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0104fc9:	eb 0c                	jmp    f0104fd7 <vprintfmt+0x23f>
f0104fcb:	89 75 08             	mov    %esi,0x8(%ebp)
f0104fce:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0104fd1:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0104fd4:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0104fd7:	83 c7 01             	add    $0x1,%edi
f0104fda:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0104fde:	0f be d0             	movsbl %al,%edx
f0104fe1:	85 d2                	test   %edx,%edx
f0104fe3:	74 23                	je     f0105008 <vprintfmt+0x270>
f0104fe5:	85 f6                	test   %esi,%esi
f0104fe7:	78 a1                	js     f0104f8a <vprintfmt+0x1f2>
f0104fe9:	83 ee 01             	sub    $0x1,%esi
f0104fec:	79 9c                	jns    f0104f8a <vprintfmt+0x1f2>
f0104fee:	89 df                	mov    %ebx,%edi
f0104ff0:	8b 75 08             	mov    0x8(%ebp),%esi
f0104ff3:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104ff6:	eb 18                	jmp    f0105010 <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0104ff8:	83 ec 08             	sub    $0x8,%esp
f0104ffb:	53                   	push   %ebx
f0104ffc:	6a 20                	push   $0x20
f0104ffe:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0105000:	83 ef 01             	sub    $0x1,%edi
f0105003:	83 c4 10             	add    $0x10,%esp
f0105006:	eb 08                	jmp    f0105010 <vprintfmt+0x278>
f0105008:	89 df                	mov    %ebx,%edi
f010500a:	8b 75 08             	mov    0x8(%ebp),%esi
f010500d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0105010:	85 ff                	test   %edi,%edi
f0105012:	7f e4                	jg     f0104ff8 <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0105014:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0105017:	e9 a2 fd ff ff       	jmp    f0104dbe <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f010501c:	83 fa 01             	cmp    $0x1,%edx
f010501f:	7e 16                	jle    f0105037 <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f0105021:	8b 45 14             	mov    0x14(%ebp),%eax
f0105024:	8d 50 08             	lea    0x8(%eax),%edx
f0105027:	89 55 14             	mov    %edx,0x14(%ebp)
f010502a:	8b 50 04             	mov    0x4(%eax),%edx
f010502d:	8b 00                	mov    (%eax),%eax
f010502f:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0105032:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0105035:	eb 32                	jmp    f0105069 <vprintfmt+0x2d1>
	else if (lflag)
f0105037:	85 d2                	test   %edx,%edx
f0105039:	74 18                	je     f0105053 <vprintfmt+0x2bb>
		return va_arg(*ap, long);
f010503b:	8b 45 14             	mov    0x14(%ebp),%eax
f010503e:	8d 50 04             	lea    0x4(%eax),%edx
f0105041:	89 55 14             	mov    %edx,0x14(%ebp)
f0105044:	8b 00                	mov    (%eax),%eax
f0105046:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0105049:	89 c1                	mov    %eax,%ecx
f010504b:	c1 f9 1f             	sar    $0x1f,%ecx
f010504e:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0105051:	eb 16                	jmp    f0105069 <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
f0105053:	8b 45 14             	mov    0x14(%ebp),%eax
f0105056:	8d 50 04             	lea    0x4(%eax),%edx
f0105059:	89 55 14             	mov    %edx,0x14(%ebp)
f010505c:	8b 00                	mov    (%eax),%eax
f010505e:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0105061:	89 c1                	mov    %eax,%ecx
f0105063:	c1 f9 1f             	sar    $0x1f,%ecx
f0105066:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0105069:	8b 45 d8             	mov    -0x28(%ebp),%eax
f010506c:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f010506f:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0105074:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0105078:	79 74                	jns    f01050ee <vprintfmt+0x356>
				putch('-', putdat);
f010507a:	83 ec 08             	sub    $0x8,%esp
f010507d:	53                   	push   %ebx
f010507e:	6a 2d                	push   $0x2d
f0105080:	ff d6                	call   *%esi
				num = -(long long) num;
f0105082:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0105085:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0105088:	f7 d8                	neg    %eax
f010508a:	83 d2 00             	adc    $0x0,%edx
f010508d:	f7 da                	neg    %edx
f010508f:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0105092:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0105097:	eb 55                	jmp    f01050ee <vprintfmt+0x356>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0105099:	8d 45 14             	lea    0x14(%ebp),%eax
f010509c:	e8 83 fc ff ff       	call   f0104d24 <getuint>
			base = 10;
f01050a1:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f01050a6:	eb 46                	jmp    f01050ee <vprintfmt+0x356>
		// (unsigned) octal
		case 'o':
			//putch('X', putdat);
			//putch('X', putdat);
			//putch('X', putdat);
			num = getuint(&ap, lflag);
f01050a8:	8d 45 14             	lea    0x14(%ebp),%eax
f01050ab:	e8 74 fc ff ff       	call   f0104d24 <getuint>
			base = 8;
f01050b0:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f01050b5:	eb 37                	jmp    f01050ee <vprintfmt+0x356>

		// pointer
		case 'p':
			putch('0', putdat);
f01050b7:	83 ec 08             	sub    $0x8,%esp
f01050ba:	53                   	push   %ebx
f01050bb:	6a 30                	push   $0x30
f01050bd:	ff d6                	call   *%esi
			putch('x', putdat);
f01050bf:	83 c4 08             	add    $0x8,%esp
f01050c2:	53                   	push   %ebx
f01050c3:	6a 78                	push   $0x78
f01050c5:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f01050c7:	8b 45 14             	mov    0x14(%ebp),%eax
f01050ca:	8d 50 04             	lea    0x4(%eax),%edx
f01050cd:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f01050d0:	8b 00                	mov    (%eax),%eax
f01050d2:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f01050d7:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f01050da:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f01050df:	eb 0d                	jmp    f01050ee <vprintfmt+0x356>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f01050e1:	8d 45 14             	lea    0x14(%ebp),%eax
f01050e4:	e8 3b fc ff ff       	call   f0104d24 <getuint>
			base = 16;
f01050e9:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f01050ee:	83 ec 0c             	sub    $0xc,%esp
f01050f1:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f01050f5:	57                   	push   %edi
f01050f6:	ff 75 e0             	pushl  -0x20(%ebp)
f01050f9:	51                   	push   %ecx
f01050fa:	52                   	push   %edx
f01050fb:	50                   	push   %eax
f01050fc:	89 da                	mov    %ebx,%edx
f01050fe:	89 f0                	mov    %esi,%eax
f0105100:	e8 70 fb ff ff       	call   f0104c75 <printnum>
			break;
f0105105:	83 c4 20             	add    $0x20,%esp
f0105108:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010510b:	e9 ae fc ff ff       	jmp    f0104dbe <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0105110:	83 ec 08             	sub    $0x8,%esp
f0105113:	53                   	push   %ebx
f0105114:	51                   	push   %ecx
f0105115:	ff d6                	call   *%esi
			break;
f0105117:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010511a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f010511d:	e9 9c fc ff ff       	jmp    f0104dbe <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0105122:	83 ec 08             	sub    $0x8,%esp
f0105125:	53                   	push   %ebx
f0105126:	6a 25                	push   $0x25
f0105128:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f010512a:	83 c4 10             	add    $0x10,%esp
f010512d:	eb 03                	jmp    f0105132 <vprintfmt+0x39a>
f010512f:	83 ef 01             	sub    $0x1,%edi
f0105132:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0105136:	75 f7                	jne    f010512f <vprintfmt+0x397>
f0105138:	e9 81 fc ff ff       	jmp    f0104dbe <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f010513d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0105140:	5b                   	pop    %ebx
f0105141:	5e                   	pop    %esi
f0105142:	5f                   	pop    %edi
f0105143:	5d                   	pop    %ebp
f0105144:	c3                   	ret    

f0105145 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0105145:	55                   	push   %ebp
f0105146:	89 e5                	mov    %esp,%ebp
f0105148:	83 ec 18             	sub    $0x18,%esp
f010514b:	8b 45 08             	mov    0x8(%ebp),%eax
f010514e:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0105151:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0105154:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0105158:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f010515b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0105162:	85 c0                	test   %eax,%eax
f0105164:	74 26                	je     f010518c <vsnprintf+0x47>
f0105166:	85 d2                	test   %edx,%edx
f0105168:	7e 22                	jle    f010518c <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f010516a:	ff 75 14             	pushl  0x14(%ebp)
f010516d:	ff 75 10             	pushl  0x10(%ebp)
f0105170:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0105173:	50                   	push   %eax
f0105174:	68 5e 4d 10 f0       	push   $0xf0104d5e
f0105179:	e8 1a fc ff ff       	call   f0104d98 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f010517e:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0105181:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0105184:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0105187:	83 c4 10             	add    $0x10,%esp
f010518a:	eb 05                	jmp    f0105191 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f010518c:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0105191:	c9                   	leave  
f0105192:	c3                   	ret    

f0105193 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0105193:	55                   	push   %ebp
f0105194:	89 e5                	mov    %esp,%ebp
f0105196:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0105199:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f010519c:	50                   	push   %eax
f010519d:	ff 75 10             	pushl  0x10(%ebp)
f01051a0:	ff 75 0c             	pushl  0xc(%ebp)
f01051a3:	ff 75 08             	pushl  0x8(%ebp)
f01051a6:	e8 9a ff ff ff       	call   f0105145 <vsnprintf>
	va_end(ap);

	return rc;
}
f01051ab:	c9                   	leave  
f01051ac:	c3                   	ret    

f01051ad <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01051ad:	55                   	push   %ebp
f01051ae:	89 e5                	mov    %esp,%ebp
f01051b0:	57                   	push   %edi
f01051b1:	56                   	push   %esi
f01051b2:	53                   	push   %ebx
f01051b3:	83 ec 0c             	sub    $0xc,%esp
f01051b6:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01051b9:	85 c0                	test   %eax,%eax
f01051bb:	74 11                	je     f01051ce <readline+0x21>
		cprintf("%s", prompt);
f01051bd:	83 ec 08             	sub    $0x8,%esp
f01051c0:	50                   	push   %eax
f01051c1:	68 fc 6f 10 f0       	push   $0xf0106ffc
f01051c6:	e8 93 e4 ff ff       	call   f010365e <cprintf>
f01051cb:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f01051ce:	83 ec 0c             	sub    $0xc,%esp
f01051d1:	6a 00                	push   $0x0
f01051d3:	e8 ad b5 ff ff       	call   f0100785 <iscons>
f01051d8:	89 c7                	mov    %eax,%edi
f01051da:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f01051dd:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f01051e2:	e8 8d b5 ff ff       	call   f0100774 <getchar>
f01051e7:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01051e9:	85 c0                	test   %eax,%eax
f01051eb:	79 18                	jns    f0105205 <readline+0x58>
			cprintf("read error: %e\n", c);
f01051ed:	83 ec 08             	sub    $0x8,%esp
f01051f0:	50                   	push   %eax
f01051f1:	68 c4 7a 10 f0       	push   $0xf0107ac4
f01051f6:	e8 63 e4 ff ff       	call   f010365e <cprintf>
			return NULL;
f01051fb:	83 c4 10             	add    $0x10,%esp
f01051fe:	b8 00 00 00 00       	mov    $0x0,%eax
f0105203:	eb 79                	jmp    f010527e <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0105205:	83 f8 08             	cmp    $0x8,%eax
f0105208:	0f 94 c2             	sete   %dl
f010520b:	83 f8 7f             	cmp    $0x7f,%eax
f010520e:	0f 94 c0             	sete   %al
f0105211:	08 c2                	or     %al,%dl
f0105213:	74 1a                	je     f010522f <readline+0x82>
f0105215:	85 f6                	test   %esi,%esi
f0105217:	7e 16                	jle    f010522f <readline+0x82>
			if (echoing)
f0105219:	85 ff                	test   %edi,%edi
f010521b:	74 0d                	je     f010522a <readline+0x7d>
				cputchar('\b');
f010521d:	83 ec 0c             	sub    $0xc,%esp
f0105220:	6a 08                	push   $0x8
f0105222:	e8 3d b5 ff ff       	call   f0100764 <cputchar>
f0105227:	83 c4 10             	add    $0x10,%esp
			i--;
f010522a:	83 ee 01             	sub    $0x1,%esi
f010522d:	eb b3                	jmp    f01051e2 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f010522f:	83 fb 1f             	cmp    $0x1f,%ebx
f0105232:	7e 23                	jle    f0105257 <readline+0xaa>
f0105234:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010523a:	7f 1b                	jg     f0105257 <readline+0xaa>
			if (echoing)
f010523c:	85 ff                	test   %edi,%edi
f010523e:	74 0c                	je     f010524c <readline+0x9f>
				cputchar(c);
f0105240:	83 ec 0c             	sub    $0xc,%esp
f0105243:	53                   	push   %ebx
f0105244:	e8 1b b5 ff ff       	call   f0100764 <cputchar>
f0105249:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f010524c:	88 9e 80 fa 22 f0    	mov    %bl,-0xfdd0580(%esi)
f0105252:	8d 76 01             	lea    0x1(%esi),%esi
f0105255:	eb 8b                	jmp    f01051e2 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0105257:	83 fb 0a             	cmp    $0xa,%ebx
f010525a:	74 05                	je     f0105261 <readline+0xb4>
f010525c:	83 fb 0d             	cmp    $0xd,%ebx
f010525f:	75 81                	jne    f01051e2 <readline+0x35>
			if (echoing)
f0105261:	85 ff                	test   %edi,%edi
f0105263:	74 0d                	je     f0105272 <readline+0xc5>
				cputchar('\n');
f0105265:	83 ec 0c             	sub    $0xc,%esp
f0105268:	6a 0a                	push   $0xa
f010526a:	e8 f5 b4 ff ff       	call   f0100764 <cputchar>
f010526f:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0105272:	c6 86 80 fa 22 f0 00 	movb   $0x0,-0xfdd0580(%esi)
			return buf;
f0105279:	b8 80 fa 22 f0       	mov    $0xf022fa80,%eax
		}
	}
}
f010527e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0105281:	5b                   	pop    %ebx
f0105282:	5e                   	pop    %esi
f0105283:	5f                   	pop    %edi
f0105284:	5d                   	pop    %ebp
f0105285:	c3                   	ret    

f0105286 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0105286:	55                   	push   %ebp
f0105287:	89 e5                	mov    %esp,%ebp
f0105289:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f010528c:	b8 00 00 00 00       	mov    $0x0,%eax
f0105291:	eb 03                	jmp    f0105296 <strlen+0x10>
		n++;
f0105293:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0105296:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f010529a:	75 f7                	jne    f0105293 <strlen+0xd>
		n++;
	return n;
}
f010529c:	5d                   	pop    %ebp
f010529d:	c3                   	ret    

f010529e <strnlen>:

int
strnlen(const char *s, size_t size)
{
f010529e:	55                   	push   %ebp
f010529f:	89 e5                	mov    %esp,%ebp
f01052a1:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01052a4:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01052a7:	ba 00 00 00 00       	mov    $0x0,%edx
f01052ac:	eb 03                	jmp    f01052b1 <strnlen+0x13>
		n++;
f01052ae:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01052b1:	39 c2                	cmp    %eax,%edx
f01052b3:	74 08                	je     f01052bd <strnlen+0x1f>
f01052b5:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f01052b9:	75 f3                	jne    f01052ae <strnlen+0x10>
f01052bb:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f01052bd:	5d                   	pop    %ebp
f01052be:	c3                   	ret    

f01052bf <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01052bf:	55                   	push   %ebp
f01052c0:	89 e5                	mov    %esp,%ebp
f01052c2:	53                   	push   %ebx
f01052c3:	8b 45 08             	mov    0x8(%ebp),%eax
f01052c6:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01052c9:	89 c2                	mov    %eax,%edx
f01052cb:	83 c2 01             	add    $0x1,%edx
f01052ce:	83 c1 01             	add    $0x1,%ecx
f01052d1:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f01052d5:	88 5a ff             	mov    %bl,-0x1(%edx)
f01052d8:	84 db                	test   %bl,%bl
f01052da:	75 ef                	jne    f01052cb <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f01052dc:	5b                   	pop    %ebx
f01052dd:	5d                   	pop    %ebp
f01052de:	c3                   	ret    

f01052df <strcat>:

char *
strcat(char *dst, const char *src)
{
f01052df:	55                   	push   %ebp
f01052e0:	89 e5                	mov    %esp,%ebp
f01052e2:	53                   	push   %ebx
f01052e3:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01052e6:	53                   	push   %ebx
f01052e7:	e8 9a ff ff ff       	call   f0105286 <strlen>
f01052ec:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f01052ef:	ff 75 0c             	pushl  0xc(%ebp)
f01052f2:	01 d8                	add    %ebx,%eax
f01052f4:	50                   	push   %eax
f01052f5:	e8 c5 ff ff ff       	call   f01052bf <strcpy>
	return dst;
}
f01052fa:	89 d8                	mov    %ebx,%eax
f01052fc:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01052ff:	c9                   	leave  
f0105300:	c3                   	ret    

f0105301 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0105301:	55                   	push   %ebp
f0105302:	89 e5                	mov    %esp,%ebp
f0105304:	56                   	push   %esi
f0105305:	53                   	push   %ebx
f0105306:	8b 75 08             	mov    0x8(%ebp),%esi
f0105309:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010530c:	89 f3                	mov    %esi,%ebx
f010530e:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0105311:	89 f2                	mov    %esi,%edx
f0105313:	eb 0f                	jmp    f0105324 <strncpy+0x23>
		*dst++ = *src;
f0105315:	83 c2 01             	add    $0x1,%edx
f0105318:	0f b6 01             	movzbl (%ecx),%eax
f010531b:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f010531e:	80 39 01             	cmpb   $0x1,(%ecx)
f0105321:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0105324:	39 da                	cmp    %ebx,%edx
f0105326:	75 ed                	jne    f0105315 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0105328:	89 f0                	mov    %esi,%eax
f010532a:	5b                   	pop    %ebx
f010532b:	5e                   	pop    %esi
f010532c:	5d                   	pop    %ebp
f010532d:	c3                   	ret    

f010532e <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010532e:	55                   	push   %ebp
f010532f:	89 e5                	mov    %esp,%ebp
f0105331:	56                   	push   %esi
f0105332:	53                   	push   %ebx
f0105333:	8b 75 08             	mov    0x8(%ebp),%esi
f0105336:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0105339:	8b 55 10             	mov    0x10(%ebp),%edx
f010533c:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f010533e:	85 d2                	test   %edx,%edx
f0105340:	74 21                	je     f0105363 <strlcpy+0x35>
f0105342:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0105346:	89 f2                	mov    %esi,%edx
f0105348:	eb 09                	jmp    f0105353 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f010534a:	83 c2 01             	add    $0x1,%edx
f010534d:	83 c1 01             	add    $0x1,%ecx
f0105350:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0105353:	39 c2                	cmp    %eax,%edx
f0105355:	74 09                	je     f0105360 <strlcpy+0x32>
f0105357:	0f b6 19             	movzbl (%ecx),%ebx
f010535a:	84 db                	test   %bl,%bl
f010535c:	75 ec                	jne    f010534a <strlcpy+0x1c>
f010535e:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f0105360:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0105363:	29 f0                	sub    %esi,%eax
}
f0105365:	5b                   	pop    %ebx
f0105366:	5e                   	pop    %esi
f0105367:	5d                   	pop    %ebp
f0105368:	c3                   	ret    

f0105369 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0105369:	55                   	push   %ebp
f010536a:	89 e5                	mov    %esp,%ebp
f010536c:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010536f:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0105372:	eb 06                	jmp    f010537a <strcmp+0x11>
		p++, q++;
f0105374:	83 c1 01             	add    $0x1,%ecx
f0105377:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f010537a:	0f b6 01             	movzbl (%ecx),%eax
f010537d:	84 c0                	test   %al,%al
f010537f:	74 04                	je     f0105385 <strcmp+0x1c>
f0105381:	3a 02                	cmp    (%edx),%al
f0105383:	74 ef                	je     f0105374 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0105385:	0f b6 c0             	movzbl %al,%eax
f0105388:	0f b6 12             	movzbl (%edx),%edx
f010538b:	29 d0                	sub    %edx,%eax
}
f010538d:	5d                   	pop    %ebp
f010538e:	c3                   	ret    

f010538f <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f010538f:	55                   	push   %ebp
f0105390:	89 e5                	mov    %esp,%ebp
f0105392:	53                   	push   %ebx
f0105393:	8b 45 08             	mov    0x8(%ebp),%eax
f0105396:	8b 55 0c             	mov    0xc(%ebp),%edx
f0105399:	89 c3                	mov    %eax,%ebx
f010539b:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f010539e:	eb 06                	jmp    f01053a6 <strncmp+0x17>
		n--, p++, q++;
f01053a0:	83 c0 01             	add    $0x1,%eax
f01053a3:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01053a6:	39 d8                	cmp    %ebx,%eax
f01053a8:	74 15                	je     f01053bf <strncmp+0x30>
f01053aa:	0f b6 08             	movzbl (%eax),%ecx
f01053ad:	84 c9                	test   %cl,%cl
f01053af:	74 04                	je     f01053b5 <strncmp+0x26>
f01053b1:	3a 0a                	cmp    (%edx),%cl
f01053b3:	74 eb                	je     f01053a0 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01053b5:	0f b6 00             	movzbl (%eax),%eax
f01053b8:	0f b6 12             	movzbl (%edx),%edx
f01053bb:	29 d0                	sub    %edx,%eax
f01053bd:	eb 05                	jmp    f01053c4 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f01053bf:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01053c4:	5b                   	pop    %ebx
f01053c5:	5d                   	pop    %ebp
f01053c6:	c3                   	ret    

f01053c7 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01053c7:	55                   	push   %ebp
f01053c8:	89 e5                	mov    %esp,%ebp
f01053ca:	8b 45 08             	mov    0x8(%ebp),%eax
f01053cd:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01053d1:	eb 07                	jmp    f01053da <strchr+0x13>
		if (*s == c)
f01053d3:	38 ca                	cmp    %cl,%dl
f01053d5:	74 0f                	je     f01053e6 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01053d7:	83 c0 01             	add    $0x1,%eax
f01053da:	0f b6 10             	movzbl (%eax),%edx
f01053dd:	84 d2                	test   %dl,%dl
f01053df:	75 f2                	jne    f01053d3 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f01053e1:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01053e6:	5d                   	pop    %ebp
f01053e7:	c3                   	ret    

f01053e8 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01053e8:	55                   	push   %ebp
f01053e9:	89 e5                	mov    %esp,%ebp
f01053eb:	8b 45 08             	mov    0x8(%ebp),%eax
f01053ee:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01053f2:	eb 03                	jmp    f01053f7 <strfind+0xf>
f01053f4:	83 c0 01             	add    $0x1,%eax
f01053f7:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f01053fa:	38 ca                	cmp    %cl,%dl
f01053fc:	74 04                	je     f0105402 <strfind+0x1a>
f01053fe:	84 d2                	test   %dl,%dl
f0105400:	75 f2                	jne    f01053f4 <strfind+0xc>
			break;
	return (char *) s;
}
f0105402:	5d                   	pop    %ebp
f0105403:	c3                   	ret    

f0105404 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0105404:	55                   	push   %ebp
f0105405:	89 e5                	mov    %esp,%ebp
f0105407:	57                   	push   %edi
f0105408:	56                   	push   %esi
f0105409:	53                   	push   %ebx
f010540a:	8b 7d 08             	mov    0x8(%ebp),%edi
f010540d:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0105410:	85 c9                	test   %ecx,%ecx
f0105412:	74 36                	je     f010544a <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0105414:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010541a:	75 28                	jne    f0105444 <memset+0x40>
f010541c:	f6 c1 03             	test   $0x3,%cl
f010541f:	75 23                	jne    f0105444 <memset+0x40>
		c &= 0xFF;
f0105421:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0105425:	89 d3                	mov    %edx,%ebx
f0105427:	c1 e3 08             	shl    $0x8,%ebx
f010542a:	89 d6                	mov    %edx,%esi
f010542c:	c1 e6 18             	shl    $0x18,%esi
f010542f:	89 d0                	mov    %edx,%eax
f0105431:	c1 e0 10             	shl    $0x10,%eax
f0105434:	09 f0                	or     %esi,%eax
f0105436:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f0105438:	89 d8                	mov    %ebx,%eax
f010543a:	09 d0                	or     %edx,%eax
f010543c:	c1 e9 02             	shr    $0x2,%ecx
f010543f:	fc                   	cld    
f0105440:	f3 ab                	rep stos %eax,%es:(%edi)
f0105442:	eb 06                	jmp    f010544a <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0105444:	8b 45 0c             	mov    0xc(%ebp),%eax
f0105447:	fc                   	cld    
f0105448:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f010544a:	89 f8                	mov    %edi,%eax
f010544c:	5b                   	pop    %ebx
f010544d:	5e                   	pop    %esi
f010544e:	5f                   	pop    %edi
f010544f:	5d                   	pop    %ebp
f0105450:	c3                   	ret    

f0105451 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0105451:	55                   	push   %ebp
f0105452:	89 e5                	mov    %esp,%ebp
f0105454:	57                   	push   %edi
f0105455:	56                   	push   %esi
f0105456:	8b 45 08             	mov    0x8(%ebp),%eax
f0105459:	8b 75 0c             	mov    0xc(%ebp),%esi
f010545c:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f010545f:	39 c6                	cmp    %eax,%esi
f0105461:	73 35                	jae    f0105498 <memmove+0x47>
f0105463:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0105466:	39 d0                	cmp    %edx,%eax
f0105468:	73 2e                	jae    f0105498 <memmove+0x47>
		s += n;
		d += n;
f010546a:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010546d:	89 d6                	mov    %edx,%esi
f010546f:	09 fe                	or     %edi,%esi
f0105471:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0105477:	75 13                	jne    f010548c <memmove+0x3b>
f0105479:	f6 c1 03             	test   $0x3,%cl
f010547c:	75 0e                	jne    f010548c <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f010547e:	83 ef 04             	sub    $0x4,%edi
f0105481:	8d 72 fc             	lea    -0x4(%edx),%esi
f0105484:	c1 e9 02             	shr    $0x2,%ecx
f0105487:	fd                   	std    
f0105488:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010548a:	eb 09                	jmp    f0105495 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f010548c:	83 ef 01             	sub    $0x1,%edi
f010548f:	8d 72 ff             	lea    -0x1(%edx),%esi
f0105492:	fd                   	std    
f0105493:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0105495:	fc                   	cld    
f0105496:	eb 1d                	jmp    f01054b5 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0105498:	89 f2                	mov    %esi,%edx
f010549a:	09 c2                	or     %eax,%edx
f010549c:	f6 c2 03             	test   $0x3,%dl
f010549f:	75 0f                	jne    f01054b0 <memmove+0x5f>
f01054a1:	f6 c1 03             	test   $0x3,%cl
f01054a4:	75 0a                	jne    f01054b0 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f01054a6:	c1 e9 02             	shr    $0x2,%ecx
f01054a9:	89 c7                	mov    %eax,%edi
f01054ab:	fc                   	cld    
f01054ac:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01054ae:	eb 05                	jmp    f01054b5 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01054b0:	89 c7                	mov    %eax,%edi
f01054b2:	fc                   	cld    
f01054b3:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01054b5:	5e                   	pop    %esi
f01054b6:	5f                   	pop    %edi
f01054b7:	5d                   	pop    %ebp
f01054b8:	c3                   	ret    

f01054b9 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01054b9:	55                   	push   %ebp
f01054ba:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f01054bc:	ff 75 10             	pushl  0x10(%ebp)
f01054bf:	ff 75 0c             	pushl  0xc(%ebp)
f01054c2:	ff 75 08             	pushl  0x8(%ebp)
f01054c5:	e8 87 ff ff ff       	call   f0105451 <memmove>
}
f01054ca:	c9                   	leave  
f01054cb:	c3                   	ret    

f01054cc <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01054cc:	55                   	push   %ebp
f01054cd:	89 e5                	mov    %esp,%ebp
f01054cf:	56                   	push   %esi
f01054d0:	53                   	push   %ebx
f01054d1:	8b 45 08             	mov    0x8(%ebp),%eax
f01054d4:	8b 55 0c             	mov    0xc(%ebp),%edx
f01054d7:	89 c6                	mov    %eax,%esi
f01054d9:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01054dc:	eb 1a                	jmp    f01054f8 <memcmp+0x2c>
		if (*s1 != *s2)
f01054de:	0f b6 08             	movzbl (%eax),%ecx
f01054e1:	0f b6 1a             	movzbl (%edx),%ebx
f01054e4:	38 d9                	cmp    %bl,%cl
f01054e6:	74 0a                	je     f01054f2 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f01054e8:	0f b6 c1             	movzbl %cl,%eax
f01054eb:	0f b6 db             	movzbl %bl,%ebx
f01054ee:	29 d8                	sub    %ebx,%eax
f01054f0:	eb 0f                	jmp    f0105501 <memcmp+0x35>
		s1++, s2++;
f01054f2:	83 c0 01             	add    $0x1,%eax
f01054f5:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01054f8:	39 f0                	cmp    %esi,%eax
f01054fa:	75 e2                	jne    f01054de <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01054fc:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0105501:	5b                   	pop    %ebx
f0105502:	5e                   	pop    %esi
f0105503:	5d                   	pop    %ebp
f0105504:	c3                   	ret    

f0105505 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0105505:	55                   	push   %ebp
f0105506:	89 e5                	mov    %esp,%ebp
f0105508:	53                   	push   %ebx
f0105509:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f010550c:	89 c1                	mov    %eax,%ecx
f010550e:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f0105511:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0105515:	eb 0a                	jmp    f0105521 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f0105517:	0f b6 10             	movzbl (%eax),%edx
f010551a:	39 da                	cmp    %ebx,%edx
f010551c:	74 07                	je     f0105525 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010551e:	83 c0 01             	add    $0x1,%eax
f0105521:	39 c8                	cmp    %ecx,%eax
f0105523:	72 f2                	jb     f0105517 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0105525:	5b                   	pop    %ebx
f0105526:	5d                   	pop    %ebp
f0105527:	c3                   	ret    

f0105528 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0105528:	55                   	push   %ebp
f0105529:	89 e5                	mov    %esp,%ebp
f010552b:	57                   	push   %edi
f010552c:	56                   	push   %esi
f010552d:	53                   	push   %ebx
f010552e:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0105531:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0105534:	eb 03                	jmp    f0105539 <strtol+0x11>
		s++;
f0105536:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0105539:	0f b6 01             	movzbl (%ecx),%eax
f010553c:	3c 20                	cmp    $0x20,%al
f010553e:	74 f6                	je     f0105536 <strtol+0xe>
f0105540:	3c 09                	cmp    $0x9,%al
f0105542:	74 f2                	je     f0105536 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0105544:	3c 2b                	cmp    $0x2b,%al
f0105546:	75 0a                	jne    f0105552 <strtol+0x2a>
		s++;
f0105548:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f010554b:	bf 00 00 00 00       	mov    $0x0,%edi
f0105550:	eb 11                	jmp    f0105563 <strtol+0x3b>
f0105552:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0105557:	3c 2d                	cmp    $0x2d,%al
f0105559:	75 08                	jne    f0105563 <strtol+0x3b>
		s++, neg = 1;
f010555b:	83 c1 01             	add    $0x1,%ecx
f010555e:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0105563:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0105569:	75 15                	jne    f0105580 <strtol+0x58>
f010556b:	80 39 30             	cmpb   $0x30,(%ecx)
f010556e:	75 10                	jne    f0105580 <strtol+0x58>
f0105570:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0105574:	75 7c                	jne    f01055f2 <strtol+0xca>
		s += 2, base = 16;
f0105576:	83 c1 02             	add    $0x2,%ecx
f0105579:	bb 10 00 00 00       	mov    $0x10,%ebx
f010557e:	eb 16                	jmp    f0105596 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f0105580:	85 db                	test   %ebx,%ebx
f0105582:	75 12                	jne    f0105596 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0105584:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0105589:	80 39 30             	cmpb   $0x30,(%ecx)
f010558c:	75 08                	jne    f0105596 <strtol+0x6e>
		s++, base = 8;
f010558e:	83 c1 01             	add    $0x1,%ecx
f0105591:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f0105596:	b8 00 00 00 00       	mov    $0x0,%eax
f010559b:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f010559e:	0f b6 11             	movzbl (%ecx),%edx
f01055a1:	8d 72 d0             	lea    -0x30(%edx),%esi
f01055a4:	89 f3                	mov    %esi,%ebx
f01055a6:	80 fb 09             	cmp    $0x9,%bl
f01055a9:	77 08                	ja     f01055b3 <strtol+0x8b>
			dig = *s - '0';
f01055ab:	0f be d2             	movsbl %dl,%edx
f01055ae:	83 ea 30             	sub    $0x30,%edx
f01055b1:	eb 22                	jmp    f01055d5 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f01055b3:	8d 72 9f             	lea    -0x61(%edx),%esi
f01055b6:	89 f3                	mov    %esi,%ebx
f01055b8:	80 fb 19             	cmp    $0x19,%bl
f01055bb:	77 08                	ja     f01055c5 <strtol+0x9d>
			dig = *s - 'a' + 10;
f01055bd:	0f be d2             	movsbl %dl,%edx
f01055c0:	83 ea 57             	sub    $0x57,%edx
f01055c3:	eb 10                	jmp    f01055d5 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f01055c5:	8d 72 bf             	lea    -0x41(%edx),%esi
f01055c8:	89 f3                	mov    %esi,%ebx
f01055ca:	80 fb 19             	cmp    $0x19,%bl
f01055cd:	77 16                	ja     f01055e5 <strtol+0xbd>
			dig = *s - 'A' + 10;
f01055cf:	0f be d2             	movsbl %dl,%edx
f01055d2:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f01055d5:	3b 55 10             	cmp    0x10(%ebp),%edx
f01055d8:	7d 0b                	jge    f01055e5 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f01055da:	83 c1 01             	add    $0x1,%ecx
f01055dd:	0f af 45 10          	imul   0x10(%ebp),%eax
f01055e1:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f01055e3:	eb b9                	jmp    f010559e <strtol+0x76>

	if (endptr)
f01055e5:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01055e9:	74 0d                	je     f01055f8 <strtol+0xd0>
		*endptr = (char *) s;
f01055eb:	8b 75 0c             	mov    0xc(%ebp),%esi
f01055ee:	89 0e                	mov    %ecx,(%esi)
f01055f0:	eb 06                	jmp    f01055f8 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01055f2:	85 db                	test   %ebx,%ebx
f01055f4:	74 98                	je     f010558e <strtol+0x66>
f01055f6:	eb 9e                	jmp    f0105596 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f01055f8:	89 c2                	mov    %eax,%edx
f01055fa:	f7 da                	neg    %edx
f01055fc:	85 ff                	test   %edi,%edi
f01055fe:	0f 45 c2             	cmovne %edx,%eax
}
f0105601:	5b                   	pop    %ebx
f0105602:	5e                   	pop    %esi
f0105603:	5f                   	pop    %edi
f0105604:	5d                   	pop    %ebp
f0105605:	c3                   	ret    
f0105606:	66 90                	xchg   %ax,%ax

f0105608 <mpentry_start>:
.set PROT_MODE_DSEG, 0x10	# kernel data segment selector

.code16           
.globl mpentry_start
mpentry_start:
	cli            
f0105608:	fa                   	cli    

	xorw    %ax, %ax
f0105609:	31 c0                	xor    %eax,%eax
	movw    %ax, %ds
f010560b:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f010560d:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f010560f:	8e d0                	mov    %eax,%ss

	lgdt    MPBOOTPHYS(gdtdesc)
f0105611:	0f 01 16             	lgdtl  (%esi)
f0105614:	74 70                	je     f0105686 <mpsearch1+0x3>
	movl    %cr0, %eax
f0105616:	0f 20 c0             	mov    %cr0,%eax
	orl     $CR0_PE, %eax
f0105619:	66 83 c8 01          	or     $0x1,%ax
	movl    %eax, %cr0
f010561d:	0f 22 c0             	mov    %eax,%cr0

	ljmpl   $(PROT_MODE_CSEG), $(MPBOOTPHYS(start32))
f0105620:	66 ea 20 70 00 00    	ljmpw  $0x0,$0x7020
f0105626:	08 00                	or     %al,(%eax)

f0105628 <start32>:

.code32
start32:
	movw    $(PROT_MODE_DSEG), %ax
f0105628:	66 b8 10 00          	mov    $0x10,%ax
	movw    %ax, %ds
f010562c:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f010562e:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f0105630:	8e d0                	mov    %eax,%ss
	movw    $0, %ax
f0105632:	66 b8 00 00          	mov    $0x0,%ax
	movw    %ax, %fs
f0105636:	8e e0                	mov    %eax,%fs
	movw    %ax, %gs
f0105638:	8e e8                	mov    %eax,%gs

	# Set up initial page table. We cannot use kern_pgdir yet because
	# we are still running at a low EIP.
	movl    $(RELOC(entry_pgdir)), %eax
f010563a:	b8 00 e0 11 00       	mov    $0x11e000,%eax
	movl    %eax, %cr3
f010563f:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl    %cr0, %eax
f0105642:	0f 20 c0             	mov    %cr0,%eax
	orl     $(CR0_PE|CR0_PG|CR0_WP), %eax
f0105645:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl    %eax, %cr0
f010564a:	0f 22 c0             	mov    %eax,%cr0

	# Switch to the per-cpu stack allocated in boot_aps()
	movl    mpentry_kstack, %esp
f010564d:	8b 25 84 fe 22 f0    	mov    0xf022fe84,%esp
	movl    $0x0, %ebp       # nuke frame pointer
f0105653:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Call mp_main().  (Exercise for the reader: why the indirect call?)
	movl    $mp_main, %eax
f0105658:	b8 b3 01 10 f0       	mov    $0xf01001b3,%eax
	call    *%eax
f010565d:	ff d0                	call   *%eax

f010565f <spin>:

	# If mp_main returns (it shouldn't), loop.
spin:
	jmp     spin
f010565f:	eb fe                	jmp    f010565f <spin>
f0105661:	8d 76 00             	lea    0x0(%esi),%esi

f0105664 <gdt>:
	...
f010566c:	ff                   	(bad)  
f010566d:	ff 00                	incl   (%eax)
f010566f:	00 00                	add    %al,(%eax)
f0105671:	9a cf 00 ff ff 00 00 	lcall  $0x0,$0xffff00cf
f0105678:	00                   	.byte 0x0
f0105679:	92                   	xchg   %eax,%edx
f010567a:	cf                   	iret   
	...

f010567c <gdtdesc>:
f010567c:	17                   	pop    %ss
f010567d:	00 5c 70 00          	add    %bl,0x0(%eax,%esi,2)
	...

f0105682 <mpentry_end>:
	.word   0x17				# sizeof(gdt) - 1
	.long   MPBOOTPHYS(gdt)			# address gdt

.globl mpentry_end
mpentry_end:
	nop
f0105682:	90                   	nop

f0105683 <mpsearch1>:
}

// Look for an MP structure in the len bytes at physical address addr.
static struct mp *
mpsearch1(physaddr_t a, int len)
{
f0105683:	55                   	push   %ebp
f0105684:	89 e5                	mov    %esp,%ebp
f0105686:	57                   	push   %edi
f0105687:	56                   	push   %esi
f0105688:	53                   	push   %ebx
f0105689:	83 ec 0c             	sub    $0xc,%esp
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010568c:	8b 0d 88 fe 22 f0    	mov    0xf022fe88,%ecx
f0105692:	89 c3                	mov    %eax,%ebx
f0105694:	c1 eb 0c             	shr    $0xc,%ebx
f0105697:	39 cb                	cmp    %ecx,%ebx
f0105699:	72 12                	jb     f01056ad <mpsearch1+0x2a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010569b:	50                   	push   %eax
f010569c:	68 e4 60 10 f0       	push   $0xf01060e4
f01056a1:	6a 57                	push   $0x57
f01056a3:	68 61 7c 10 f0       	push   $0xf0107c61
f01056a8:	e8 93 a9 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f01056ad:	8d 98 00 00 00 f0    	lea    -0x10000000(%eax),%ebx
	struct mp *mp = KADDR(a), *end = KADDR(a + len);
f01056b3:	01 d0                	add    %edx,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01056b5:	89 c2                	mov    %eax,%edx
f01056b7:	c1 ea 0c             	shr    $0xc,%edx
f01056ba:	39 ca                	cmp    %ecx,%edx
f01056bc:	72 12                	jb     f01056d0 <mpsearch1+0x4d>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01056be:	50                   	push   %eax
f01056bf:	68 e4 60 10 f0       	push   $0xf01060e4
f01056c4:	6a 57                	push   $0x57
f01056c6:	68 61 7c 10 f0       	push   $0xf0107c61
f01056cb:	e8 70 a9 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f01056d0:	8d b0 00 00 00 f0    	lea    -0x10000000(%eax),%esi

	for (; mp < end; mp++)
f01056d6:	eb 2f                	jmp    f0105707 <mpsearch1+0x84>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f01056d8:	83 ec 04             	sub    $0x4,%esp
f01056db:	6a 04                	push   $0x4
f01056dd:	68 71 7c 10 f0       	push   $0xf0107c71
f01056e2:	53                   	push   %ebx
f01056e3:	e8 e4 fd ff ff       	call   f01054cc <memcmp>
f01056e8:	83 c4 10             	add    $0x10,%esp
f01056eb:	85 c0                	test   %eax,%eax
f01056ed:	75 15                	jne    f0105704 <mpsearch1+0x81>
f01056ef:	89 da                	mov    %ebx,%edx
f01056f1:	8d 7b 10             	lea    0x10(%ebx),%edi
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
		sum += ((uint8_t *)addr)[i];
f01056f4:	0f b6 0a             	movzbl (%edx),%ecx
f01056f7:	01 c8                	add    %ecx,%eax
f01056f9:	83 c2 01             	add    $0x1,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f01056fc:	39 d7                	cmp    %edx,%edi
f01056fe:	75 f4                	jne    f01056f4 <mpsearch1+0x71>
mpsearch1(physaddr_t a, int len)
{
	struct mp *mp = KADDR(a), *end = KADDR(a + len);

	for (; mp < end; mp++)
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f0105700:	84 c0                	test   %al,%al
f0105702:	74 0e                	je     f0105712 <mpsearch1+0x8f>
static struct mp *
mpsearch1(physaddr_t a, int len)
{
	struct mp *mp = KADDR(a), *end = KADDR(a + len);

	for (; mp < end; mp++)
f0105704:	83 c3 10             	add    $0x10,%ebx
f0105707:	39 f3                	cmp    %esi,%ebx
f0105709:	72 cd                	jb     f01056d8 <mpsearch1+0x55>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
		    sum(mp, sizeof(*mp)) == 0)
			return mp;
	return NULL;
f010570b:	b8 00 00 00 00       	mov    $0x0,%eax
f0105710:	eb 02                	jmp    f0105714 <mpsearch1+0x91>
f0105712:	89 d8                	mov    %ebx,%eax
}
f0105714:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0105717:	5b                   	pop    %ebx
f0105718:	5e                   	pop    %esi
f0105719:	5f                   	pop    %edi
f010571a:	5d                   	pop    %ebp
f010571b:	c3                   	ret    

f010571c <mp_init>:
	return conf;
}

void
mp_init(void)
{
f010571c:	55                   	push   %ebp
f010571d:	89 e5                	mov    %esp,%ebp
f010571f:	57                   	push   %edi
f0105720:	56                   	push   %esi
f0105721:	53                   	push   %ebx
f0105722:	83 ec 1c             	sub    $0x1c,%esp
	struct mpconf *conf;
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
f0105725:	c7 05 c0 03 23 f0 20 	movl   $0xf0230020,0xf02303c0
f010572c:	00 23 f0 
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010572f:	83 3d 88 fe 22 f0 00 	cmpl   $0x0,0xf022fe88
f0105736:	75 16                	jne    f010574e <mp_init+0x32>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0105738:	68 00 04 00 00       	push   $0x400
f010573d:	68 e4 60 10 f0       	push   $0xf01060e4
f0105742:	6a 6f                	push   $0x6f
f0105744:	68 61 7c 10 f0       	push   $0xf0107c61
f0105749:	e8 f2 a8 ff ff       	call   f0100040 <_panic>
	// The BIOS data area lives in 16-bit segment 0x40.
	bda = (uint8_t *) KADDR(0x40 << 4);

	// [MP 4] The 16-bit segment of the EBDA is in the two bytes
	// starting at byte 0x0E of the BDA.  0 if not present.
	if ((p = *(uint16_t *) (bda + 0x0E))) {
f010574e:	0f b7 05 0e 04 00 f0 	movzwl 0xf000040e,%eax
f0105755:	85 c0                	test   %eax,%eax
f0105757:	74 16                	je     f010576f <mp_init+0x53>
		p <<= 4;	// Translate from segment to PA
		if ((mp = mpsearch1(p, 1024)))
f0105759:	c1 e0 04             	shl    $0x4,%eax
f010575c:	ba 00 04 00 00       	mov    $0x400,%edx
f0105761:	e8 1d ff ff ff       	call   f0105683 <mpsearch1>
f0105766:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0105769:	85 c0                	test   %eax,%eax
f010576b:	75 3c                	jne    f01057a9 <mp_init+0x8d>
f010576d:	eb 20                	jmp    f010578f <mp_init+0x73>
			return mp;
	} else {
		// The size of base memory, in KB is in the two bytes
		// starting at 0x13 of the BDA.
		p = *(uint16_t *) (bda + 0x13) * 1024;
		if ((mp = mpsearch1(p - 1024, 1024)))
f010576f:	0f b7 05 13 04 00 f0 	movzwl 0xf0000413,%eax
f0105776:	c1 e0 0a             	shl    $0xa,%eax
f0105779:	2d 00 04 00 00       	sub    $0x400,%eax
f010577e:	ba 00 04 00 00       	mov    $0x400,%edx
f0105783:	e8 fb fe ff ff       	call   f0105683 <mpsearch1>
f0105788:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010578b:	85 c0                	test   %eax,%eax
f010578d:	75 1a                	jne    f01057a9 <mp_init+0x8d>
			return mp;
	}
	return mpsearch1(0xF0000, 0x10000);
f010578f:	ba 00 00 01 00       	mov    $0x10000,%edx
f0105794:	b8 00 00 0f 00       	mov    $0xf0000,%eax
f0105799:	e8 e5 fe ff ff       	call   f0105683 <mpsearch1>
f010579e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
mpconfig(struct mp **pmp)
{
	struct mpconf *conf;
	struct mp *mp;

	if ((mp = mpsearch()) == 0)
f01057a1:	85 c0                	test   %eax,%eax
f01057a3:	0f 84 5d 02 00 00    	je     f0105a06 <mp_init+0x2ea>
		return NULL;
	if (mp->physaddr == 0 || mp->type != 0) {
f01057a9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01057ac:	8b 70 04             	mov    0x4(%eax),%esi
f01057af:	85 f6                	test   %esi,%esi
f01057b1:	74 06                	je     f01057b9 <mp_init+0x9d>
f01057b3:	80 78 0b 00          	cmpb   $0x0,0xb(%eax)
f01057b7:	74 15                	je     f01057ce <mp_init+0xb2>
		cprintf("SMP: Default configurations not implemented\n");
f01057b9:	83 ec 0c             	sub    $0xc,%esp
f01057bc:	68 d4 7a 10 f0       	push   $0xf0107ad4
f01057c1:	e8 98 de ff ff       	call   f010365e <cprintf>
f01057c6:	83 c4 10             	add    $0x10,%esp
f01057c9:	e9 38 02 00 00       	jmp    f0105a06 <mp_init+0x2ea>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01057ce:	89 f0                	mov    %esi,%eax
f01057d0:	c1 e8 0c             	shr    $0xc,%eax
f01057d3:	3b 05 88 fe 22 f0    	cmp    0xf022fe88,%eax
f01057d9:	72 15                	jb     f01057f0 <mp_init+0xd4>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01057db:	56                   	push   %esi
f01057dc:	68 e4 60 10 f0       	push   $0xf01060e4
f01057e1:	68 90 00 00 00       	push   $0x90
f01057e6:	68 61 7c 10 f0       	push   $0xf0107c61
f01057eb:	e8 50 a8 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f01057f0:	8d 9e 00 00 00 f0    	lea    -0x10000000(%esi),%ebx
		return NULL;
	}
	conf = (struct mpconf *) KADDR(mp->physaddr);
	if (memcmp(conf, "PCMP", 4) != 0) {
f01057f6:	83 ec 04             	sub    $0x4,%esp
f01057f9:	6a 04                	push   $0x4
f01057fb:	68 76 7c 10 f0       	push   $0xf0107c76
f0105800:	53                   	push   %ebx
f0105801:	e8 c6 fc ff ff       	call   f01054cc <memcmp>
f0105806:	83 c4 10             	add    $0x10,%esp
f0105809:	85 c0                	test   %eax,%eax
f010580b:	74 15                	je     f0105822 <mp_init+0x106>
		cprintf("SMP: Incorrect MP configuration table signature\n");
f010580d:	83 ec 0c             	sub    $0xc,%esp
f0105810:	68 04 7b 10 f0       	push   $0xf0107b04
f0105815:	e8 44 de ff ff       	call   f010365e <cprintf>
f010581a:	83 c4 10             	add    $0x10,%esp
f010581d:	e9 e4 01 00 00       	jmp    f0105a06 <mp_init+0x2ea>
		return NULL;
	}
	if (sum(conf, conf->length) != 0) {
f0105822:	0f b7 43 04          	movzwl 0x4(%ebx),%eax
f0105826:	66 89 45 e2          	mov    %ax,-0x1e(%ebp)
f010582a:	0f b7 f8             	movzwl %ax,%edi
static uint8_t
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
f010582d:	ba 00 00 00 00       	mov    $0x0,%edx
	for (i = 0; i < len; i++)
f0105832:	b8 00 00 00 00       	mov    $0x0,%eax
f0105837:	eb 0d                	jmp    f0105846 <mp_init+0x12a>
		sum += ((uint8_t *)addr)[i];
f0105839:	0f b6 8c 30 00 00 00 	movzbl -0x10000000(%eax,%esi,1),%ecx
f0105840:	f0 
f0105841:	01 ca                	add    %ecx,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f0105843:	83 c0 01             	add    $0x1,%eax
f0105846:	39 c7                	cmp    %eax,%edi
f0105848:	75 ef                	jne    f0105839 <mp_init+0x11d>
	conf = (struct mpconf *) KADDR(mp->physaddr);
	if (memcmp(conf, "PCMP", 4) != 0) {
		cprintf("SMP: Incorrect MP configuration table signature\n");
		return NULL;
	}
	if (sum(conf, conf->length) != 0) {
f010584a:	84 d2                	test   %dl,%dl
f010584c:	74 15                	je     f0105863 <mp_init+0x147>
		cprintf("SMP: Bad MP configuration checksum\n");
f010584e:	83 ec 0c             	sub    $0xc,%esp
f0105851:	68 38 7b 10 f0       	push   $0xf0107b38
f0105856:	e8 03 de ff ff       	call   f010365e <cprintf>
f010585b:	83 c4 10             	add    $0x10,%esp
f010585e:	e9 a3 01 00 00       	jmp    f0105a06 <mp_init+0x2ea>
		return NULL;
	}
	if (conf->version != 1 && conf->version != 4) {
f0105863:	0f b6 43 06          	movzbl 0x6(%ebx),%eax
f0105867:	3c 01                	cmp    $0x1,%al
f0105869:	74 1d                	je     f0105888 <mp_init+0x16c>
f010586b:	3c 04                	cmp    $0x4,%al
f010586d:	74 19                	je     f0105888 <mp_init+0x16c>
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
f010586f:	83 ec 08             	sub    $0x8,%esp
f0105872:	0f b6 c0             	movzbl %al,%eax
f0105875:	50                   	push   %eax
f0105876:	68 5c 7b 10 f0       	push   $0xf0107b5c
f010587b:	e8 de dd ff ff       	call   f010365e <cprintf>
f0105880:	83 c4 10             	add    $0x10,%esp
f0105883:	e9 7e 01 00 00       	jmp    f0105a06 <mp_init+0x2ea>
		return NULL;
	}
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f0105888:	0f b7 7b 28          	movzwl 0x28(%ebx),%edi
f010588c:	0f b7 4d e2          	movzwl -0x1e(%ebp),%ecx
static uint8_t
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
f0105890:	ba 00 00 00 00       	mov    $0x0,%edx
	for (i = 0; i < len; i++)
f0105895:	b8 00 00 00 00       	mov    $0x0,%eax
		sum += ((uint8_t *)addr)[i];
f010589a:	01 ce                	add    %ecx,%esi
f010589c:	eb 0d                	jmp    f01058ab <mp_init+0x18f>
f010589e:	0f b6 8c 06 00 00 00 	movzbl -0x10000000(%esi,%eax,1),%ecx
f01058a5:	f0 
f01058a6:	01 ca                	add    %ecx,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f01058a8:	83 c0 01             	add    $0x1,%eax
f01058ab:	39 c7                	cmp    %eax,%edi
f01058ad:	75 ef                	jne    f010589e <mp_init+0x182>
	}
	if (conf->version != 1 && conf->version != 4) {
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
		return NULL;
	}
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f01058af:	89 d0                	mov    %edx,%eax
f01058b1:	02 43 2a             	add    0x2a(%ebx),%al
f01058b4:	74 15                	je     f01058cb <mp_init+0x1af>
		cprintf("SMP: Bad MP configuration extended checksum\n");
f01058b6:	83 ec 0c             	sub    $0xc,%esp
f01058b9:	68 7c 7b 10 f0       	push   $0xf0107b7c
f01058be:	e8 9b dd ff ff       	call   f010365e <cprintf>
f01058c3:	83 c4 10             	add    $0x10,%esp
f01058c6:	e9 3b 01 00 00       	jmp    f0105a06 <mp_init+0x2ea>
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
	if ((conf = mpconfig(&mp)) == 0)
f01058cb:	85 db                	test   %ebx,%ebx
f01058cd:	0f 84 33 01 00 00    	je     f0105a06 <mp_init+0x2ea>
		return;
	ismp = 1;
f01058d3:	c7 05 00 00 23 f0 01 	movl   $0x1,0xf0230000
f01058da:	00 00 00 
	lapicaddr = conf->lapicaddr;
f01058dd:	8b 43 24             	mov    0x24(%ebx),%eax
f01058e0:	a3 00 10 27 f0       	mov    %eax,0xf0271000

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f01058e5:	8d 7b 2c             	lea    0x2c(%ebx),%edi
f01058e8:	be 00 00 00 00       	mov    $0x0,%esi
f01058ed:	e9 85 00 00 00       	jmp    f0105977 <mp_init+0x25b>
		switch (*p) {
f01058f2:	0f b6 07             	movzbl (%edi),%eax
f01058f5:	84 c0                	test   %al,%al
f01058f7:	74 06                	je     f01058ff <mp_init+0x1e3>
f01058f9:	3c 04                	cmp    $0x4,%al
f01058fb:	77 55                	ja     f0105952 <mp_init+0x236>
f01058fd:	eb 4e                	jmp    f010594d <mp_init+0x231>
		case MPPROC:
			proc = (struct mpproc *)p;
			if (proc->flags & MPPROC_BOOT)
f01058ff:	f6 47 03 02          	testb  $0x2,0x3(%edi)
f0105903:	74 11                	je     f0105916 <mp_init+0x1fa>
				bootcpu = &cpus[ncpu];
f0105905:	6b 05 c4 03 23 f0 74 	imul   $0x74,0xf02303c4,%eax
f010590c:	05 20 00 23 f0       	add    $0xf0230020,%eax
f0105911:	a3 c0 03 23 f0       	mov    %eax,0xf02303c0
			if (ncpu < NCPU) {
f0105916:	a1 c4 03 23 f0       	mov    0xf02303c4,%eax
f010591b:	83 f8 07             	cmp    $0x7,%eax
f010591e:	7f 13                	jg     f0105933 <mp_init+0x217>
				cpus[ncpu].cpu_id = ncpu;
f0105920:	6b d0 74             	imul   $0x74,%eax,%edx
f0105923:	88 82 20 00 23 f0    	mov    %al,-0xfdcffe0(%edx)
				ncpu++;
f0105929:	83 c0 01             	add    $0x1,%eax
f010592c:	a3 c4 03 23 f0       	mov    %eax,0xf02303c4
f0105931:	eb 15                	jmp    f0105948 <mp_init+0x22c>
			} else {
				cprintf("SMP: too many CPUs, CPU %d disabled\n",
f0105933:	83 ec 08             	sub    $0x8,%esp
f0105936:	0f b6 47 01          	movzbl 0x1(%edi),%eax
f010593a:	50                   	push   %eax
f010593b:	68 ac 7b 10 f0       	push   $0xf0107bac
f0105940:	e8 19 dd ff ff       	call   f010365e <cprintf>
f0105945:	83 c4 10             	add    $0x10,%esp
					proc->apicid);
			}
			p += sizeof(struct mpproc);
f0105948:	83 c7 14             	add    $0x14,%edi
			continue;
f010594b:	eb 27                	jmp    f0105974 <mp_init+0x258>
		case MPBUS:
		case MPIOAPIC:
		case MPIOINTR:
		case MPLINTR:
			p += 8;
f010594d:	83 c7 08             	add    $0x8,%edi
			continue;
f0105950:	eb 22                	jmp    f0105974 <mp_init+0x258>
		default:
			cprintf("mpinit: unknown config type %x\n", *p);
f0105952:	83 ec 08             	sub    $0x8,%esp
f0105955:	0f b6 c0             	movzbl %al,%eax
f0105958:	50                   	push   %eax
f0105959:	68 d4 7b 10 f0       	push   $0xf0107bd4
f010595e:	e8 fb dc ff ff       	call   f010365e <cprintf>
			ismp = 0;
f0105963:	c7 05 00 00 23 f0 00 	movl   $0x0,0xf0230000
f010596a:	00 00 00 
			i = conf->entry;
f010596d:	0f b7 73 22          	movzwl 0x22(%ebx),%esi
f0105971:	83 c4 10             	add    $0x10,%esp
	if ((conf = mpconfig(&mp)) == 0)
		return;
	ismp = 1;
	lapicaddr = conf->lapicaddr;

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f0105974:	83 c6 01             	add    $0x1,%esi
f0105977:	0f b7 43 22          	movzwl 0x22(%ebx),%eax
f010597b:	39 c6                	cmp    %eax,%esi
f010597d:	0f 82 6f ff ff ff    	jb     f01058f2 <mp_init+0x1d6>
			ismp = 0;
			i = conf->entry;
		}
	}

	bootcpu->cpu_status = CPU_STARTED;
f0105983:	a1 c0 03 23 f0       	mov    0xf02303c0,%eax
f0105988:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
	if (!ismp) {
f010598f:	83 3d 00 00 23 f0 00 	cmpl   $0x0,0xf0230000
f0105996:	75 26                	jne    f01059be <mp_init+0x2a2>
		// Didn't like what we found; fall back to no MP.
		ncpu = 1;
f0105998:	c7 05 c4 03 23 f0 01 	movl   $0x1,0xf02303c4
f010599f:	00 00 00 
		lapicaddr = 0;
f01059a2:	c7 05 00 10 27 f0 00 	movl   $0x0,0xf0271000
f01059a9:	00 00 00 
		cprintf("SMP: configuration not found, SMP disabled\n");
f01059ac:	83 ec 0c             	sub    $0xc,%esp
f01059af:	68 f4 7b 10 f0       	push   $0xf0107bf4
f01059b4:	e8 a5 dc ff ff       	call   f010365e <cprintf>
		return;
f01059b9:	83 c4 10             	add    $0x10,%esp
f01059bc:	eb 48                	jmp    f0105a06 <mp_init+0x2ea>
	}
	cprintf("SMP: CPU %d found %d CPU(s)\n", bootcpu->cpu_id,  ncpu);
f01059be:	83 ec 04             	sub    $0x4,%esp
f01059c1:	ff 35 c4 03 23 f0    	pushl  0xf02303c4
f01059c7:	0f b6 00             	movzbl (%eax),%eax
f01059ca:	50                   	push   %eax
f01059cb:	68 7b 7c 10 f0       	push   $0xf0107c7b
f01059d0:	e8 89 dc ff ff       	call   f010365e <cprintf>

	if (mp->imcrp) {
f01059d5:	83 c4 10             	add    $0x10,%esp
f01059d8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01059db:	80 78 0c 00          	cmpb   $0x0,0xc(%eax)
f01059df:	74 25                	je     f0105a06 <mp_init+0x2ea>
		// [MP 3.2.6.1] If the hardware implements PIC mode,
		// switch to getting interrupts from the LAPIC.
		cprintf("SMP: Setting IMCR to switch from PIC mode to symmetric I/O mode\n");
f01059e1:	83 ec 0c             	sub    $0xc,%esp
f01059e4:	68 20 7c 10 f0       	push   $0xf0107c20
f01059e9:	e8 70 dc ff ff       	call   f010365e <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01059ee:	ba 22 00 00 00       	mov    $0x22,%edx
f01059f3:	b8 70 00 00 00       	mov    $0x70,%eax
f01059f8:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01059f9:	ba 23 00 00 00       	mov    $0x23,%edx
f01059fe:	ec                   	in     (%dx),%al
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01059ff:	83 c8 01             	or     $0x1,%eax
f0105a02:	ee                   	out    %al,(%dx)
f0105a03:	83 c4 10             	add    $0x10,%esp
		outb(0x22, 0x70);   // Select IMCR
		outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
	}
}
f0105a06:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0105a09:	5b                   	pop    %ebx
f0105a0a:	5e                   	pop    %esi
f0105a0b:	5f                   	pop    %edi
f0105a0c:	5d                   	pop    %ebp
f0105a0d:	c3                   	ret    

f0105a0e <lapicw>:
physaddr_t lapicaddr;        // Initialized in mpconfig.c
volatile uint32_t *lapic;

static void
lapicw(int index, int value)
{
f0105a0e:	55                   	push   %ebp
f0105a0f:	89 e5                	mov    %esp,%ebp
	lapic[index] = value;
f0105a11:	8b 0d 04 10 27 f0    	mov    0xf0271004,%ecx
f0105a17:	8d 04 81             	lea    (%ecx,%eax,4),%eax
f0105a1a:	89 10                	mov    %edx,(%eax)
	lapic[ID];  // wait for write to finish, by reading
f0105a1c:	a1 04 10 27 f0       	mov    0xf0271004,%eax
f0105a21:	8b 40 20             	mov    0x20(%eax),%eax
}
f0105a24:	5d                   	pop    %ebp
f0105a25:	c3                   	ret    

f0105a26 <cpunum>:
	lapicw(TPR, 0);
}

int
cpunum(void)
{
f0105a26:	55                   	push   %ebp
f0105a27:	89 e5                	mov    %esp,%ebp
	if (lapic)
f0105a29:	a1 04 10 27 f0       	mov    0xf0271004,%eax
f0105a2e:	85 c0                	test   %eax,%eax
f0105a30:	74 08                	je     f0105a3a <cpunum+0x14>
		return lapic[ID] >> 24;
f0105a32:	8b 40 20             	mov    0x20(%eax),%eax
f0105a35:	c1 e8 18             	shr    $0x18,%eax
f0105a38:	eb 05                	jmp    f0105a3f <cpunum+0x19>
	return 0;
f0105a3a:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0105a3f:	5d                   	pop    %ebp
f0105a40:	c3                   	ret    

f0105a41 <lapic_init>:
}

void
lapic_init(void)
{
	if (!lapicaddr)
f0105a41:	a1 00 10 27 f0       	mov    0xf0271000,%eax
f0105a46:	85 c0                	test   %eax,%eax
f0105a48:	0f 84 21 01 00 00    	je     f0105b6f <lapic_init+0x12e>
	lapic[ID];  // wait for write to finish, by reading
}

void
lapic_init(void)
{
f0105a4e:	55                   	push   %ebp
f0105a4f:	89 e5                	mov    %esp,%ebp
f0105a51:	83 ec 10             	sub    $0x10,%esp
	if (!lapicaddr)
		return;

	// lapicaddr is the physical address of the LAPIC's 4K MMIO
	// region.  Map it in to virtual memory so we can access it.
	lapic = mmio_map_region(lapicaddr, 4096);
f0105a54:	68 00 10 00 00       	push   $0x1000
f0105a59:	50                   	push   %eax
f0105a5a:	e8 25 b8 ff ff       	call   f0101284 <mmio_map_region>
f0105a5f:	a3 04 10 27 f0       	mov    %eax,0xf0271004

	// Enable local APIC; set spurious interrupt vector.
	lapicw(SVR, ENABLE | (IRQ_OFFSET + IRQ_SPURIOUS));
f0105a64:	ba 27 01 00 00       	mov    $0x127,%edx
f0105a69:	b8 3c 00 00 00       	mov    $0x3c,%eax
f0105a6e:	e8 9b ff ff ff       	call   f0105a0e <lapicw>

	// The timer repeatedly counts down at bus frequency
	// from lapic[TICR] and then issues an interrupt.  
	// If we cared more about precise timekeeping,
	// TICR would be calibrated using an external time source.
	lapicw(TDCR, X1);
f0105a73:	ba 0b 00 00 00       	mov    $0xb,%edx
f0105a78:	b8 f8 00 00 00       	mov    $0xf8,%eax
f0105a7d:	e8 8c ff ff ff       	call   f0105a0e <lapicw>
	lapicw(TIMER, PERIODIC | (IRQ_OFFSET + IRQ_TIMER));
f0105a82:	ba 20 00 02 00       	mov    $0x20020,%edx
f0105a87:	b8 c8 00 00 00       	mov    $0xc8,%eax
f0105a8c:	e8 7d ff ff ff       	call   f0105a0e <lapicw>
	lapicw(TICR, 10000000); 
f0105a91:	ba 80 96 98 00       	mov    $0x989680,%edx
f0105a96:	b8 e0 00 00 00       	mov    $0xe0,%eax
f0105a9b:	e8 6e ff ff ff       	call   f0105a0e <lapicw>
	//
	// According to Intel MP Specification, the BIOS should initialize
	// BSP's local APIC in Virtual Wire Mode, in which 8259A's
	// INTR is virtually connected to BSP's LINTIN0. In this mode,
	// we do not need to program the IOAPIC.
	if (thiscpu != bootcpu)
f0105aa0:	e8 81 ff ff ff       	call   f0105a26 <cpunum>
f0105aa5:	6b c0 74             	imul   $0x74,%eax,%eax
f0105aa8:	05 20 00 23 f0       	add    $0xf0230020,%eax
f0105aad:	83 c4 10             	add    $0x10,%esp
f0105ab0:	39 05 c0 03 23 f0    	cmp    %eax,0xf02303c0
f0105ab6:	74 0f                	je     f0105ac7 <lapic_init+0x86>
		lapicw(LINT0, MASKED);
f0105ab8:	ba 00 00 01 00       	mov    $0x10000,%edx
f0105abd:	b8 d4 00 00 00       	mov    $0xd4,%eax
f0105ac2:	e8 47 ff ff ff       	call   f0105a0e <lapicw>

	// Disable NMI (LINT1) on all CPUs
	lapicw(LINT1, MASKED);
f0105ac7:	ba 00 00 01 00       	mov    $0x10000,%edx
f0105acc:	b8 d8 00 00 00       	mov    $0xd8,%eax
f0105ad1:	e8 38 ff ff ff       	call   f0105a0e <lapicw>

	// Disable performance counter overflow interrupts
	// on machines that provide that interrupt entry.
	if (((lapic[VER]>>16) & 0xFF) >= 4)
f0105ad6:	a1 04 10 27 f0       	mov    0xf0271004,%eax
f0105adb:	8b 40 30             	mov    0x30(%eax),%eax
f0105ade:	c1 e8 10             	shr    $0x10,%eax
f0105ae1:	3c 03                	cmp    $0x3,%al
f0105ae3:	76 0f                	jbe    f0105af4 <lapic_init+0xb3>
		lapicw(PCINT, MASKED);
f0105ae5:	ba 00 00 01 00       	mov    $0x10000,%edx
f0105aea:	b8 d0 00 00 00       	mov    $0xd0,%eax
f0105aef:	e8 1a ff ff ff       	call   f0105a0e <lapicw>

	// Map error interrupt to IRQ_ERROR.
	lapicw(ERROR, IRQ_OFFSET + IRQ_ERROR);
f0105af4:	ba 33 00 00 00       	mov    $0x33,%edx
f0105af9:	b8 dc 00 00 00       	mov    $0xdc,%eax
f0105afe:	e8 0b ff ff ff       	call   f0105a0e <lapicw>

	// Clear error status register (requires back-to-back writes).
	lapicw(ESR, 0);
f0105b03:	ba 00 00 00 00       	mov    $0x0,%edx
f0105b08:	b8 a0 00 00 00       	mov    $0xa0,%eax
f0105b0d:	e8 fc fe ff ff       	call   f0105a0e <lapicw>
	lapicw(ESR, 0);
f0105b12:	ba 00 00 00 00       	mov    $0x0,%edx
f0105b17:	b8 a0 00 00 00       	mov    $0xa0,%eax
f0105b1c:	e8 ed fe ff ff       	call   f0105a0e <lapicw>

	// Ack any outstanding interrupts.
	lapicw(EOI, 0);
f0105b21:	ba 00 00 00 00       	mov    $0x0,%edx
f0105b26:	b8 2c 00 00 00       	mov    $0x2c,%eax
f0105b2b:	e8 de fe ff ff       	call   f0105a0e <lapicw>

	// Send an Init Level De-Assert to synchronize arbitration ID's.
	lapicw(ICRHI, 0);
f0105b30:	ba 00 00 00 00       	mov    $0x0,%edx
f0105b35:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105b3a:	e8 cf fe ff ff       	call   f0105a0e <lapicw>
	lapicw(ICRLO, BCAST | INIT | LEVEL);
f0105b3f:	ba 00 85 08 00       	mov    $0x88500,%edx
f0105b44:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105b49:	e8 c0 fe ff ff       	call   f0105a0e <lapicw>
	while(lapic[ICRLO] & DELIVS)
f0105b4e:	8b 15 04 10 27 f0    	mov    0xf0271004,%edx
f0105b54:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f0105b5a:	f6 c4 10             	test   $0x10,%ah
f0105b5d:	75 f5                	jne    f0105b54 <lapic_init+0x113>
		;

	// Enable interrupts on the APIC (but not on the processor).
	lapicw(TPR, 0);
f0105b5f:	ba 00 00 00 00       	mov    $0x0,%edx
f0105b64:	b8 20 00 00 00       	mov    $0x20,%eax
f0105b69:	e8 a0 fe ff ff       	call   f0105a0e <lapicw>
}
f0105b6e:	c9                   	leave  
f0105b6f:	f3 c3                	repz ret 

f0105b71 <lapic_eoi>:

// Acknowledge interrupt.
void
lapic_eoi(void)
{
	if (lapic)
f0105b71:	83 3d 04 10 27 f0 00 	cmpl   $0x0,0xf0271004
f0105b78:	74 13                	je     f0105b8d <lapic_eoi+0x1c>
}

// Acknowledge interrupt.
void
lapic_eoi(void)
{
f0105b7a:	55                   	push   %ebp
f0105b7b:	89 e5                	mov    %esp,%ebp
	if (lapic)
		lapicw(EOI, 0);
f0105b7d:	ba 00 00 00 00       	mov    $0x0,%edx
f0105b82:	b8 2c 00 00 00       	mov    $0x2c,%eax
f0105b87:	e8 82 fe ff ff       	call   f0105a0e <lapicw>
}
f0105b8c:	5d                   	pop    %ebp
f0105b8d:	f3 c3                	repz ret 

f0105b8f <lapic_startap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapic_startap(uint8_t apicid, uint32_t addr)
{
f0105b8f:	55                   	push   %ebp
f0105b90:	89 e5                	mov    %esp,%ebp
f0105b92:	56                   	push   %esi
f0105b93:	53                   	push   %ebx
f0105b94:	8b 75 08             	mov    0x8(%ebp),%esi
f0105b97:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0105b9a:	ba 70 00 00 00       	mov    $0x70,%edx
f0105b9f:	b8 0f 00 00 00       	mov    $0xf,%eax
f0105ba4:	ee                   	out    %al,(%dx)
f0105ba5:	ba 71 00 00 00       	mov    $0x71,%edx
f0105baa:	b8 0a 00 00 00       	mov    $0xa,%eax
f0105baf:	ee                   	out    %al,(%dx)
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0105bb0:	83 3d 88 fe 22 f0 00 	cmpl   $0x0,0xf022fe88
f0105bb7:	75 19                	jne    f0105bd2 <lapic_startap+0x43>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0105bb9:	68 67 04 00 00       	push   $0x467
f0105bbe:	68 e4 60 10 f0       	push   $0xf01060e4
f0105bc3:	68 98 00 00 00       	push   $0x98
f0105bc8:	68 98 7c 10 f0       	push   $0xf0107c98
f0105bcd:	e8 6e a4 ff ff       	call   f0100040 <_panic>
	// and the warm reset vector (DWORD based at 40:67) to point at
	// the AP startup code prior to the [universal startup algorithm]."
	outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
	outb(IO_RTC+1, 0x0A);
	wrv = (uint16_t *)KADDR((0x40 << 4 | 0x67));  // Warm reset vector
	wrv[0] = 0;
f0105bd2:	66 c7 05 67 04 00 f0 	movw   $0x0,0xf0000467
f0105bd9:	00 00 
	wrv[1] = addr >> 4;
f0105bdb:	89 d8                	mov    %ebx,%eax
f0105bdd:	c1 e8 04             	shr    $0x4,%eax
f0105be0:	66 a3 69 04 00 f0    	mov    %ax,0xf0000469

	// "Universal startup algorithm."
	// Send INIT (level-triggered) interrupt to reset other CPU.
	lapicw(ICRHI, apicid << 24);
f0105be6:	c1 e6 18             	shl    $0x18,%esi
f0105be9:	89 f2                	mov    %esi,%edx
f0105beb:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105bf0:	e8 19 fe ff ff       	call   f0105a0e <lapicw>
	lapicw(ICRLO, INIT | LEVEL | ASSERT);
f0105bf5:	ba 00 c5 00 00       	mov    $0xc500,%edx
f0105bfa:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105bff:	e8 0a fe ff ff       	call   f0105a0e <lapicw>
	microdelay(200);
	lapicw(ICRLO, INIT | LEVEL);
f0105c04:	ba 00 85 00 00       	mov    $0x8500,%edx
f0105c09:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105c0e:	e8 fb fd ff ff       	call   f0105a0e <lapicw>
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0105c13:	c1 eb 0c             	shr    $0xc,%ebx
f0105c16:	80 cf 06             	or     $0x6,%bh
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
f0105c19:	89 f2                	mov    %esi,%edx
f0105c1b:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105c20:	e8 e9 fd ff ff       	call   f0105a0e <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0105c25:	89 da                	mov    %ebx,%edx
f0105c27:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105c2c:	e8 dd fd ff ff       	call   f0105a0e <lapicw>
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
f0105c31:	89 f2                	mov    %esi,%edx
f0105c33:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105c38:	e8 d1 fd ff ff       	call   f0105a0e <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0105c3d:	89 da                	mov    %ebx,%edx
f0105c3f:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105c44:	e8 c5 fd ff ff       	call   f0105a0e <lapicw>
		microdelay(200);
	}
}
f0105c49:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0105c4c:	5b                   	pop    %ebx
f0105c4d:	5e                   	pop    %esi
f0105c4e:	5d                   	pop    %ebp
f0105c4f:	c3                   	ret    

f0105c50 <lapic_ipi>:

void
lapic_ipi(int vector)
{
f0105c50:	55                   	push   %ebp
f0105c51:	89 e5                	mov    %esp,%ebp
	lapicw(ICRLO, OTHERS | FIXED | vector);
f0105c53:	8b 55 08             	mov    0x8(%ebp),%edx
f0105c56:	81 ca 00 00 0c 00    	or     $0xc0000,%edx
f0105c5c:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105c61:	e8 a8 fd ff ff       	call   f0105a0e <lapicw>
	while (lapic[ICRLO] & DELIVS)
f0105c66:	8b 15 04 10 27 f0    	mov    0xf0271004,%edx
f0105c6c:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f0105c72:	f6 c4 10             	test   $0x10,%ah
f0105c75:	75 f5                	jne    f0105c6c <lapic_ipi+0x1c>
		;
}
f0105c77:	5d                   	pop    %ebp
f0105c78:	c3                   	ret    

f0105c79 <__spin_initlock>:
}
#endif

void
__spin_initlock(struct spinlock *lk, char *name)
{
f0105c79:	55                   	push   %ebp
f0105c7a:	89 e5                	mov    %esp,%ebp
f0105c7c:	8b 45 08             	mov    0x8(%ebp),%eax
	lk->locked = 0;
f0105c7f:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
#ifdef DEBUG_SPINLOCK
	lk->name = name;
f0105c85:	8b 55 0c             	mov    0xc(%ebp),%edx
f0105c88:	89 50 04             	mov    %edx,0x4(%eax)
	lk->cpu = 0;
f0105c8b:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
#endif
}
f0105c92:	5d                   	pop    %ebp
f0105c93:	c3                   	ret    

f0105c94 <spin_lock>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
spin_lock(struct spinlock *lk)
{
f0105c94:	55                   	push   %ebp
f0105c95:	89 e5                	mov    %esp,%ebp
f0105c97:	56                   	push   %esi
f0105c98:	53                   	push   %ebx
f0105c99:	8b 5d 08             	mov    0x8(%ebp),%ebx

// Check whether this CPU is holding the lock.
static int
holding(struct spinlock *lock)
{
	return lock->locked && lock->cpu == thiscpu;
f0105c9c:	83 3b 00             	cmpl   $0x0,(%ebx)
f0105c9f:	74 14                	je     f0105cb5 <spin_lock+0x21>
f0105ca1:	8b 73 08             	mov    0x8(%ebx),%esi
f0105ca4:	e8 7d fd ff ff       	call   f0105a26 <cpunum>
f0105ca9:	6b c0 74             	imul   $0x74,%eax,%eax
f0105cac:	05 20 00 23 f0       	add    $0xf0230020,%eax
// other CPUs to waste time spinning to acquire it.
void
spin_lock(struct spinlock *lk)
{
#ifdef DEBUG_SPINLOCK
	if (holding(lk))
f0105cb1:	39 c6                	cmp    %eax,%esi
f0105cb3:	74 07                	je     f0105cbc <spin_lock+0x28>
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"
f0105cb5:	ba 01 00 00 00       	mov    $0x1,%edx
f0105cba:	eb 20                	jmp    f0105cdc <spin_lock+0x48>
		panic("CPU %d cannot acquire %s: already holding", cpunum(), lk->name);
f0105cbc:	8b 5b 04             	mov    0x4(%ebx),%ebx
f0105cbf:	e8 62 fd ff ff       	call   f0105a26 <cpunum>
f0105cc4:	83 ec 0c             	sub    $0xc,%esp
f0105cc7:	53                   	push   %ebx
f0105cc8:	50                   	push   %eax
f0105cc9:	68 a8 7c 10 f0       	push   $0xf0107ca8
f0105cce:	6a 41                	push   $0x41
f0105cd0:	68 0c 7d 10 f0       	push   $0xf0107d0c
f0105cd5:	e8 66 a3 ff ff       	call   f0100040 <_panic>

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
		asm volatile ("pause");
f0105cda:	f3 90                	pause  
f0105cdc:	89 d0                	mov    %edx,%eax
f0105cde:	f0 87 03             	lock xchg %eax,(%ebx)
#endif

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
f0105ce1:	85 c0                	test   %eax,%eax
f0105ce3:	75 f5                	jne    f0105cda <spin_lock+0x46>
		asm volatile ("pause");

	// Record info about lock acquisition for debugging.
#ifdef DEBUG_SPINLOCK
	lk->cpu = thiscpu;
f0105ce5:	e8 3c fd ff ff       	call   f0105a26 <cpunum>
f0105cea:	6b c0 74             	imul   $0x74,%eax,%eax
f0105ced:	05 20 00 23 f0       	add    $0xf0230020,%eax
f0105cf2:	89 43 08             	mov    %eax,0x8(%ebx)
	get_caller_pcs(lk->pcs);
f0105cf5:	83 c3 0c             	add    $0xc,%ebx

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f0105cf8:	89 ea                	mov    %ebp,%edx
{
	uint32_t *ebp;
	int i;

	ebp = (uint32_t *)read_ebp();
	for (i = 0; i < 10; i++){
f0105cfa:	b8 00 00 00 00       	mov    $0x0,%eax
f0105cff:	eb 0b                	jmp    f0105d0c <spin_lock+0x78>
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
			break;
		pcs[i] = ebp[1];          // saved %eip
f0105d01:	8b 4a 04             	mov    0x4(%edx),%ecx
f0105d04:	89 0c 83             	mov    %ecx,(%ebx,%eax,4)
		ebp = (uint32_t *)ebp[0]; // saved %ebp
f0105d07:	8b 12                	mov    (%edx),%edx
{
	uint32_t *ebp;
	int i;

	ebp = (uint32_t *)read_ebp();
	for (i = 0; i < 10; i++){
f0105d09:	83 c0 01             	add    $0x1,%eax
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
f0105d0c:	81 fa ff ff 7f ef    	cmp    $0xef7fffff,%edx
f0105d12:	76 11                	jbe    f0105d25 <spin_lock+0x91>
f0105d14:	83 f8 09             	cmp    $0x9,%eax
f0105d17:	7e e8                	jle    f0105d01 <spin_lock+0x6d>
f0105d19:	eb 0a                	jmp    f0105d25 <spin_lock+0x91>
			break;
		pcs[i] = ebp[1];          // saved %eip
		ebp = (uint32_t *)ebp[0]; // saved %ebp
	}
	for (; i < 10; i++)
		pcs[i] = 0;
f0105d1b:	c7 04 83 00 00 00 00 	movl   $0x0,(%ebx,%eax,4)
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
			break;
		pcs[i] = ebp[1];          // saved %eip
		ebp = (uint32_t *)ebp[0]; // saved %ebp
	}
	for (; i < 10; i++)
f0105d22:	83 c0 01             	add    $0x1,%eax
f0105d25:	83 f8 09             	cmp    $0x9,%eax
f0105d28:	7e f1                	jle    f0105d1b <spin_lock+0x87>
	// Record info about lock acquisition for debugging.
#ifdef DEBUG_SPINLOCK
	lk->cpu = thiscpu;
	get_caller_pcs(lk->pcs);
#endif
}
f0105d2a:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0105d2d:	5b                   	pop    %ebx
f0105d2e:	5e                   	pop    %esi
f0105d2f:	5d                   	pop    %ebp
f0105d30:	c3                   	ret    

f0105d31 <spin_unlock>:

// Release the lock.
void
spin_unlock(struct spinlock *lk)
{
f0105d31:	55                   	push   %ebp
f0105d32:	89 e5                	mov    %esp,%ebp
f0105d34:	57                   	push   %edi
f0105d35:	56                   	push   %esi
f0105d36:	53                   	push   %ebx
f0105d37:	83 ec 4c             	sub    $0x4c,%esp
f0105d3a:	8b 75 08             	mov    0x8(%ebp),%esi

// Check whether this CPU is holding the lock.
static int
holding(struct spinlock *lock)
{
	return lock->locked && lock->cpu == thiscpu;
f0105d3d:	83 3e 00             	cmpl   $0x0,(%esi)
f0105d40:	74 18                	je     f0105d5a <spin_unlock+0x29>
f0105d42:	8b 5e 08             	mov    0x8(%esi),%ebx
f0105d45:	e8 dc fc ff ff       	call   f0105a26 <cpunum>
f0105d4a:	6b c0 74             	imul   $0x74,%eax,%eax
f0105d4d:	05 20 00 23 f0       	add    $0xf0230020,%eax
// Release the lock.
void
spin_unlock(struct spinlock *lk)
{
#ifdef DEBUG_SPINLOCK
	if (!holding(lk)) {
f0105d52:	39 c3                	cmp    %eax,%ebx
f0105d54:	0f 84 a5 00 00 00    	je     f0105dff <spin_unlock+0xce>
		int i;
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
f0105d5a:	83 ec 04             	sub    $0x4,%esp
f0105d5d:	6a 28                	push   $0x28
f0105d5f:	8d 46 0c             	lea    0xc(%esi),%eax
f0105d62:	50                   	push   %eax
f0105d63:	8d 5d c0             	lea    -0x40(%ebp),%ebx
f0105d66:	53                   	push   %ebx
f0105d67:	e8 e5 f6 ff ff       	call   f0105451 <memmove>
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
f0105d6c:	8b 46 08             	mov    0x8(%esi),%eax
	if (!holding(lk)) {
		int i;
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
f0105d6f:	0f b6 38             	movzbl (%eax),%edi
f0105d72:	8b 76 04             	mov    0x4(%esi),%esi
f0105d75:	e8 ac fc ff ff       	call   f0105a26 <cpunum>
f0105d7a:	57                   	push   %edi
f0105d7b:	56                   	push   %esi
f0105d7c:	50                   	push   %eax
f0105d7d:	68 d4 7c 10 f0       	push   $0xf0107cd4
f0105d82:	e8 d7 d8 ff ff       	call   f010365e <cprintf>
f0105d87:	83 c4 20             	add    $0x20,%esp
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
			struct Eipdebuginfo info;
			if (debuginfo_eip(pcs[i], &info) >= 0)
f0105d8a:	8d 7d a8             	lea    -0x58(%ebp),%edi
f0105d8d:	eb 54                	jmp    f0105de3 <spin_unlock+0xb2>
f0105d8f:	83 ec 08             	sub    $0x8,%esp
f0105d92:	57                   	push   %edi
f0105d93:	50                   	push   %eax
f0105d94:	e8 bb eb ff ff       	call   f0104954 <debuginfo_eip>
f0105d99:	83 c4 10             	add    $0x10,%esp
f0105d9c:	85 c0                	test   %eax,%eax
f0105d9e:	78 27                	js     f0105dc7 <spin_unlock+0x96>
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
					info.eip_file, info.eip_line,
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
f0105da0:	8b 06                	mov    (%esi),%eax
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
			struct Eipdebuginfo info;
			if (debuginfo_eip(pcs[i], &info) >= 0)
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
f0105da2:	83 ec 04             	sub    $0x4,%esp
f0105da5:	89 c2                	mov    %eax,%edx
f0105da7:	2b 55 b8             	sub    -0x48(%ebp),%edx
f0105daa:	52                   	push   %edx
f0105dab:	ff 75 b0             	pushl  -0x50(%ebp)
f0105dae:	ff 75 b4             	pushl  -0x4c(%ebp)
f0105db1:	ff 75 ac             	pushl  -0x54(%ebp)
f0105db4:	ff 75 a8             	pushl  -0x58(%ebp)
f0105db7:	50                   	push   %eax
f0105db8:	68 1c 7d 10 f0       	push   $0xf0107d1c
f0105dbd:	e8 9c d8 ff ff       	call   f010365e <cprintf>
f0105dc2:	83 c4 20             	add    $0x20,%esp
f0105dc5:	eb 12                	jmp    f0105dd9 <spin_unlock+0xa8>
					info.eip_file, info.eip_line,
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
			else
				cprintf("  %08x\n", pcs[i]);
f0105dc7:	83 ec 08             	sub    $0x8,%esp
f0105dca:	ff 36                	pushl  (%esi)
f0105dcc:	68 33 7d 10 f0       	push   $0xf0107d33
f0105dd1:	e8 88 d8 ff ff       	call   f010365e <cprintf>
f0105dd6:	83 c4 10             	add    $0x10,%esp
f0105dd9:	83 c3 04             	add    $0x4,%ebx
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
f0105ddc:	8d 45 e8             	lea    -0x18(%ebp),%eax
f0105ddf:	39 c3                	cmp    %eax,%ebx
f0105de1:	74 08                	je     f0105deb <spin_unlock+0xba>
f0105de3:	89 de                	mov    %ebx,%esi
f0105de5:	8b 03                	mov    (%ebx),%eax
f0105de7:	85 c0                	test   %eax,%eax
f0105de9:	75 a4                	jne    f0105d8f <spin_unlock+0x5e>
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
			else
				cprintf("  %08x\n", pcs[i]);
		}
		panic("spin_unlock");
f0105deb:	83 ec 04             	sub    $0x4,%esp
f0105dee:	68 3b 7d 10 f0       	push   $0xf0107d3b
f0105df3:	6a 67                	push   $0x67
f0105df5:	68 0c 7d 10 f0       	push   $0xf0107d0c
f0105dfa:	e8 41 a2 ff ff       	call   f0100040 <_panic>
	}

	lk->pcs[0] = 0;
f0105dff:	c7 46 0c 00 00 00 00 	movl   $0x0,0xc(%esi)
	lk->cpu = 0;
f0105e06:	c7 46 08 00 00 00 00 	movl   $0x0,0x8(%esi)
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"
f0105e0d:	b8 00 00 00 00       	mov    $0x0,%eax
f0105e12:	f0 87 06             	lock xchg %eax,(%esi)
	// respect to any other instruction which references the same memory.
	// x86 CPUs will not reorder loads/stores across locked instructions
	// (vol 3, 8.2.2). Because xchg() is implemented using asm volatile,
	// gcc will not reorder C statements across the xchg.
	xchg(&lk->locked, 0);
}
f0105e15:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0105e18:	5b                   	pop    %ebx
f0105e19:	5e                   	pop    %esi
f0105e1a:	5f                   	pop    %edi
f0105e1b:	5d                   	pop    %ebp
f0105e1c:	c3                   	ret    
f0105e1d:	66 90                	xchg   %ax,%ax
f0105e1f:	90                   	nop

f0105e20 <__udivdi3>:
f0105e20:	55                   	push   %ebp
f0105e21:	57                   	push   %edi
f0105e22:	56                   	push   %esi
f0105e23:	53                   	push   %ebx
f0105e24:	83 ec 1c             	sub    $0x1c,%esp
f0105e27:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f0105e2b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f0105e2f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0105e33:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0105e37:	85 f6                	test   %esi,%esi
f0105e39:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0105e3d:	89 ca                	mov    %ecx,%edx
f0105e3f:	89 f8                	mov    %edi,%eax
f0105e41:	75 3d                	jne    f0105e80 <__udivdi3+0x60>
f0105e43:	39 cf                	cmp    %ecx,%edi
f0105e45:	0f 87 c5 00 00 00    	ja     f0105f10 <__udivdi3+0xf0>
f0105e4b:	85 ff                	test   %edi,%edi
f0105e4d:	89 fd                	mov    %edi,%ebp
f0105e4f:	75 0b                	jne    f0105e5c <__udivdi3+0x3c>
f0105e51:	b8 01 00 00 00       	mov    $0x1,%eax
f0105e56:	31 d2                	xor    %edx,%edx
f0105e58:	f7 f7                	div    %edi
f0105e5a:	89 c5                	mov    %eax,%ebp
f0105e5c:	89 c8                	mov    %ecx,%eax
f0105e5e:	31 d2                	xor    %edx,%edx
f0105e60:	f7 f5                	div    %ebp
f0105e62:	89 c1                	mov    %eax,%ecx
f0105e64:	89 d8                	mov    %ebx,%eax
f0105e66:	89 cf                	mov    %ecx,%edi
f0105e68:	f7 f5                	div    %ebp
f0105e6a:	89 c3                	mov    %eax,%ebx
f0105e6c:	89 d8                	mov    %ebx,%eax
f0105e6e:	89 fa                	mov    %edi,%edx
f0105e70:	83 c4 1c             	add    $0x1c,%esp
f0105e73:	5b                   	pop    %ebx
f0105e74:	5e                   	pop    %esi
f0105e75:	5f                   	pop    %edi
f0105e76:	5d                   	pop    %ebp
f0105e77:	c3                   	ret    
f0105e78:	90                   	nop
f0105e79:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0105e80:	39 ce                	cmp    %ecx,%esi
f0105e82:	77 74                	ja     f0105ef8 <__udivdi3+0xd8>
f0105e84:	0f bd fe             	bsr    %esi,%edi
f0105e87:	83 f7 1f             	xor    $0x1f,%edi
f0105e8a:	0f 84 98 00 00 00    	je     f0105f28 <__udivdi3+0x108>
f0105e90:	bb 20 00 00 00       	mov    $0x20,%ebx
f0105e95:	89 f9                	mov    %edi,%ecx
f0105e97:	89 c5                	mov    %eax,%ebp
f0105e99:	29 fb                	sub    %edi,%ebx
f0105e9b:	d3 e6                	shl    %cl,%esi
f0105e9d:	89 d9                	mov    %ebx,%ecx
f0105e9f:	d3 ed                	shr    %cl,%ebp
f0105ea1:	89 f9                	mov    %edi,%ecx
f0105ea3:	d3 e0                	shl    %cl,%eax
f0105ea5:	09 ee                	or     %ebp,%esi
f0105ea7:	89 d9                	mov    %ebx,%ecx
f0105ea9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0105ead:	89 d5                	mov    %edx,%ebp
f0105eaf:	8b 44 24 08          	mov    0x8(%esp),%eax
f0105eb3:	d3 ed                	shr    %cl,%ebp
f0105eb5:	89 f9                	mov    %edi,%ecx
f0105eb7:	d3 e2                	shl    %cl,%edx
f0105eb9:	89 d9                	mov    %ebx,%ecx
f0105ebb:	d3 e8                	shr    %cl,%eax
f0105ebd:	09 c2                	or     %eax,%edx
f0105ebf:	89 d0                	mov    %edx,%eax
f0105ec1:	89 ea                	mov    %ebp,%edx
f0105ec3:	f7 f6                	div    %esi
f0105ec5:	89 d5                	mov    %edx,%ebp
f0105ec7:	89 c3                	mov    %eax,%ebx
f0105ec9:	f7 64 24 0c          	mull   0xc(%esp)
f0105ecd:	39 d5                	cmp    %edx,%ebp
f0105ecf:	72 10                	jb     f0105ee1 <__udivdi3+0xc1>
f0105ed1:	8b 74 24 08          	mov    0x8(%esp),%esi
f0105ed5:	89 f9                	mov    %edi,%ecx
f0105ed7:	d3 e6                	shl    %cl,%esi
f0105ed9:	39 c6                	cmp    %eax,%esi
f0105edb:	73 07                	jae    f0105ee4 <__udivdi3+0xc4>
f0105edd:	39 d5                	cmp    %edx,%ebp
f0105edf:	75 03                	jne    f0105ee4 <__udivdi3+0xc4>
f0105ee1:	83 eb 01             	sub    $0x1,%ebx
f0105ee4:	31 ff                	xor    %edi,%edi
f0105ee6:	89 d8                	mov    %ebx,%eax
f0105ee8:	89 fa                	mov    %edi,%edx
f0105eea:	83 c4 1c             	add    $0x1c,%esp
f0105eed:	5b                   	pop    %ebx
f0105eee:	5e                   	pop    %esi
f0105eef:	5f                   	pop    %edi
f0105ef0:	5d                   	pop    %ebp
f0105ef1:	c3                   	ret    
f0105ef2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0105ef8:	31 ff                	xor    %edi,%edi
f0105efa:	31 db                	xor    %ebx,%ebx
f0105efc:	89 d8                	mov    %ebx,%eax
f0105efe:	89 fa                	mov    %edi,%edx
f0105f00:	83 c4 1c             	add    $0x1c,%esp
f0105f03:	5b                   	pop    %ebx
f0105f04:	5e                   	pop    %esi
f0105f05:	5f                   	pop    %edi
f0105f06:	5d                   	pop    %ebp
f0105f07:	c3                   	ret    
f0105f08:	90                   	nop
f0105f09:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0105f10:	89 d8                	mov    %ebx,%eax
f0105f12:	f7 f7                	div    %edi
f0105f14:	31 ff                	xor    %edi,%edi
f0105f16:	89 c3                	mov    %eax,%ebx
f0105f18:	89 d8                	mov    %ebx,%eax
f0105f1a:	89 fa                	mov    %edi,%edx
f0105f1c:	83 c4 1c             	add    $0x1c,%esp
f0105f1f:	5b                   	pop    %ebx
f0105f20:	5e                   	pop    %esi
f0105f21:	5f                   	pop    %edi
f0105f22:	5d                   	pop    %ebp
f0105f23:	c3                   	ret    
f0105f24:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0105f28:	39 ce                	cmp    %ecx,%esi
f0105f2a:	72 0c                	jb     f0105f38 <__udivdi3+0x118>
f0105f2c:	31 db                	xor    %ebx,%ebx
f0105f2e:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0105f32:	0f 87 34 ff ff ff    	ja     f0105e6c <__udivdi3+0x4c>
f0105f38:	bb 01 00 00 00       	mov    $0x1,%ebx
f0105f3d:	e9 2a ff ff ff       	jmp    f0105e6c <__udivdi3+0x4c>
f0105f42:	66 90                	xchg   %ax,%ax
f0105f44:	66 90                	xchg   %ax,%ax
f0105f46:	66 90                	xchg   %ax,%ax
f0105f48:	66 90                	xchg   %ax,%ax
f0105f4a:	66 90                	xchg   %ax,%ax
f0105f4c:	66 90                	xchg   %ax,%ax
f0105f4e:	66 90                	xchg   %ax,%ax

f0105f50 <__umoddi3>:
f0105f50:	55                   	push   %ebp
f0105f51:	57                   	push   %edi
f0105f52:	56                   	push   %esi
f0105f53:	53                   	push   %ebx
f0105f54:	83 ec 1c             	sub    $0x1c,%esp
f0105f57:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f0105f5b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f0105f5f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0105f63:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0105f67:	85 d2                	test   %edx,%edx
f0105f69:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0105f6d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0105f71:	89 f3                	mov    %esi,%ebx
f0105f73:	89 3c 24             	mov    %edi,(%esp)
f0105f76:	89 74 24 04          	mov    %esi,0x4(%esp)
f0105f7a:	75 1c                	jne    f0105f98 <__umoddi3+0x48>
f0105f7c:	39 f7                	cmp    %esi,%edi
f0105f7e:	76 50                	jbe    f0105fd0 <__umoddi3+0x80>
f0105f80:	89 c8                	mov    %ecx,%eax
f0105f82:	89 f2                	mov    %esi,%edx
f0105f84:	f7 f7                	div    %edi
f0105f86:	89 d0                	mov    %edx,%eax
f0105f88:	31 d2                	xor    %edx,%edx
f0105f8a:	83 c4 1c             	add    $0x1c,%esp
f0105f8d:	5b                   	pop    %ebx
f0105f8e:	5e                   	pop    %esi
f0105f8f:	5f                   	pop    %edi
f0105f90:	5d                   	pop    %ebp
f0105f91:	c3                   	ret    
f0105f92:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0105f98:	39 f2                	cmp    %esi,%edx
f0105f9a:	89 d0                	mov    %edx,%eax
f0105f9c:	77 52                	ja     f0105ff0 <__umoddi3+0xa0>
f0105f9e:	0f bd ea             	bsr    %edx,%ebp
f0105fa1:	83 f5 1f             	xor    $0x1f,%ebp
f0105fa4:	75 5a                	jne    f0106000 <__umoddi3+0xb0>
f0105fa6:	3b 54 24 04          	cmp    0x4(%esp),%edx
f0105faa:	0f 82 e0 00 00 00    	jb     f0106090 <__umoddi3+0x140>
f0105fb0:	39 0c 24             	cmp    %ecx,(%esp)
f0105fb3:	0f 86 d7 00 00 00    	jbe    f0106090 <__umoddi3+0x140>
f0105fb9:	8b 44 24 08          	mov    0x8(%esp),%eax
f0105fbd:	8b 54 24 04          	mov    0x4(%esp),%edx
f0105fc1:	83 c4 1c             	add    $0x1c,%esp
f0105fc4:	5b                   	pop    %ebx
f0105fc5:	5e                   	pop    %esi
f0105fc6:	5f                   	pop    %edi
f0105fc7:	5d                   	pop    %ebp
f0105fc8:	c3                   	ret    
f0105fc9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0105fd0:	85 ff                	test   %edi,%edi
f0105fd2:	89 fd                	mov    %edi,%ebp
f0105fd4:	75 0b                	jne    f0105fe1 <__umoddi3+0x91>
f0105fd6:	b8 01 00 00 00       	mov    $0x1,%eax
f0105fdb:	31 d2                	xor    %edx,%edx
f0105fdd:	f7 f7                	div    %edi
f0105fdf:	89 c5                	mov    %eax,%ebp
f0105fe1:	89 f0                	mov    %esi,%eax
f0105fe3:	31 d2                	xor    %edx,%edx
f0105fe5:	f7 f5                	div    %ebp
f0105fe7:	89 c8                	mov    %ecx,%eax
f0105fe9:	f7 f5                	div    %ebp
f0105feb:	89 d0                	mov    %edx,%eax
f0105fed:	eb 99                	jmp    f0105f88 <__umoddi3+0x38>
f0105fef:	90                   	nop
f0105ff0:	89 c8                	mov    %ecx,%eax
f0105ff2:	89 f2                	mov    %esi,%edx
f0105ff4:	83 c4 1c             	add    $0x1c,%esp
f0105ff7:	5b                   	pop    %ebx
f0105ff8:	5e                   	pop    %esi
f0105ff9:	5f                   	pop    %edi
f0105ffa:	5d                   	pop    %ebp
f0105ffb:	c3                   	ret    
f0105ffc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0106000:	8b 34 24             	mov    (%esp),%esi
f0106003:	bf 20 00 00 00       	mov    $0x20,%edi
f0106008:	89 e9                	mov    %ebp,%ecx
f010600a:	29 ef                	sub    %ebp,%edi
f010600c:	d3 e0                	shl    %cl,%eax
f010600e:	89 f9                	mov    %edi,%ecx
f0106010:	89 f2                	mov    %esi,%edx
f0106012:	d3 ea                	shr    %cl,%edx
f0106014:	89 e9                	mov    %ebp,%ecx
f0106016:	09 c2                	or     %eax,%edx
f0106018:	89 d8                	mov    %ebx,%eax
f010601a:	89 14 24             	mov    %edx,(%esp)
f010601d:	89 f2                	mov    %esi,%edx
f010601f:	d3 e2                	shl    %cl,%edx
f0106021:	89 f9                	mov    %edi,%ecx
f0106023:	89 54 24 04          	mov    %edx,0x4(%esp)
f0106027:	8b 54 24 0c          	mov    0xc(%esp),%edx
f010602b:	d3 e8                	shr    %cl,%eax
f010602d:	89 e9                	mov    %ebp,%ecx
f010602f:	89 c6                	mov    %eax,%esi
f0106031:	d3 e3                	shl    %cl,%ebx
f0106033:	89 f9                	mov    %edi,%ecx
f0106035:	89 d0                	mov    %edx,%eax
f0106037:	d3 e8                	shr    %cl,%eax
f0106039:	89 e9                	mov    %ebp,%ecx
f010603b:	09 d8                	or     %ebx,%eax
f010603d:	89 d3                	mov    %edx,%ebx
f010603f:	89 f2                	mov    %esi,%edx
f0106041:	f7 34 24             	divl   (%esp)
f0106044:	89 d6                	mov    %edx,%esi
f0106046:	d3 e3                	shl    %cl,%ebx
f0106048:	f7 64 24 04          	mull   0x4(%esp)
f010604c:	39 d6                	cmp    %edx,%esi
f010604e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0106052:	89 d1                	mov    %edx,%ecx
f0106054:	89 c3                	mov    %eax,%ebx
f0106056:	72 08                	jb     f0106060 <__umoddi3+0x110>
f0106058:	75 11                	jne    f010606b <__umoddi3+0x11b>
f010605a:	39 44 24 08          	cmp    %eax,0x8(%esp)
f010605e:	73 0b                	jae    f010606b <__umoddi3+0x11b>
f0106060:	2b 44 24 04          	sub    0x4(%esp),%eax
f0106064:	1b 14 24             	sbb    (%esp),%edx
f0106067:	89 d1                	mov    %edx,%ecx
f0106069:	89 c3                	mov    %eax,%ebx
f010606b:	8b 54 24 08          	mov    0x8(%esp),%edx
f010606f:	29 da                	sub    %ebx,%edx
f0106071:	19 ce                	sbb    %ecx,%esi
f0106073:	89 f9                	mov    %edi,%ecx
f0106075:	89 f0                	mov    %esi,%eax
f0106077:	d3 e0                	shl    %cl,%eax
f0106079:	89 e9                	mov    %ebp,%ecx
f010607b:	d3 ea                	shr    %cl,%edx
f010607d:	89 e9                	mov    %ebp,%ecx
f010607f:	d3 ee                	shr    %cl,%esi
f0106081:	09 d0                	or     %edx,%eax
f0106083:	89 f2                	mov    %esi,%edx
f0106085:	83 c4 1c             	add    $0x1c,%esp
f0106088:	5b                   	pop    %ebx
f0106089:	5e                   	pop    %esi
f010608a:	5f                   	pop    %edi
f010608b:	5d                   	pop    %ebp
f010608c:	c3                   	ret    
f010608d:	8d 76 00             	lea    0x0(%esi),%esi
f0106090:	29 f9                	sub    %edi,%ecx
f0106092:	19 d6                	sbb    %edx,%esi
f0106094:	89 74 24 04          	mov    %esi,0x4(%esp)
f0106098:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010609c:	e9 18 ff ff ff       	jmp    f0105fb9 <__umoddi3+0x69>
