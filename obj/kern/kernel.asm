
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
f0100015:	b8 00 00 12 00       	mov    $0x120000,%eax
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
f0100034:	bc 00 00 12 f0       	mov    $0xf0120000,%esp

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
f0100048:	83 3d 98 9e 2a f0 00 	cmpl   $0x0,0xf02a9e98
f010004f:	75 3a                	jne    f010008b <_panic+0x4b>
		goto dead;
	panicstr = fmt;
f0100051:	89 35 98 9e 2a f0    	mov    %esi,0xf02a9e98

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f0100057:	fa                   	cli    
f0100058:	fc                   	cld    

	va_start(ap, fmt);
f0100059:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic on CPU %d at %s:%d: ", cpunum(), file, line);
f010005c:	e8 c9 59 00 00       	call   f0105a2a <cpunum>
f0100061:	ff 75 0c             	pushl  0xc(%ebp)
f0100064:	ff 75 08             	pushl  0x8(%ebp)
f0100067:	50                   	push   %eax
f0100068:	68 20 66 10 f0       	push   $0xf0106620
f010006d:	e8 eb 35 00 00       	call   f010365d <cprintf>
	vcprintf(fmt, ap);
f0100072:	83 c4 08             	add    $0x8,%esp
f0100075:	53                   	push   %ebx
f0100076:	56                   	push   %esi
f0100077:	e8 bb 35 00 00       	call   f0103637 <vcprintf>
	cprintf("\n");
f010007c:	c7 04 24 04 78 10 f0 	movl   $0xf0107804,(%esp)
f0100083:	e8 d5 35 00 00       	call   f010365d <cprintf>
	va_end(ap);
f0100088:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f010008b:	83 ec 0c             	sub    $0xc,%esp
f010008e:	6a 00                	push   $0x0
f0100090:	e8 aa 08 00 00       	call   f010093f <monitor>
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
f01000a1:	b8 08 b0 2e f0       	mov    $0xf02eb008,%eax
f01000a6:	2d 2c 87 2a f0       	sub    $0xf02a872c,%eax
f01000ab:	50                   	push   %eax
f01000ac:	6a 00                	push   $0x0
f01000ae:	68 2c 87 2a f0       	push   $0xf02a872c
f01000b3:	e8 51 53 00 00       	call   f0105409 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000b8:	e8 af 05 00 00       	call   f010066c <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000bd:	83 c4 08             	add    $0x8,%esp
f01000c0:	68 ac 1a 00 00       	push   $0x1aac
f01000c5:	68 8c 66 10 f0       	push   $0xf010668c
f01000ca:	e8 8e 35 00 00       	call   f010365d <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f01000cf:	e8 61 12 00 00       	call   f0101335 <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f01000d4:	e8 3c 2e 00 00       	call   f0102f15 <env_init>
	trap_init();
f01000d9:	e8 60 36 00 00       	call   f010373e <trap_init>

	// Lab 4 multiprocessor initialization functions
	mp_init();
f01000de:	e8 3d 56 00 00       	call   f0105720 <mp_init>
	lapic_init();
f01000e3:	e8 5d 59 00 00       	call   f0105a45 <lapic_init>

	// Lab 4 multitasking initialization functions
	pic_init();
f01000e8:	e8 81 34 00 00       	call   f010356e <pic_init>

	// Lab 6 hardware initialization functions
	time_init();
f01000ed:	e8 48 62 00 00       	call   f010633a <time_init>
	pci_init();
f01000f2:	e8 23 62 00 00       	call   f010631a <pci_init>
extern struct spinlock kernel_lock;

static inline void
lock_kernel(void)
{
	spin_lock(&kernel_lock);
f01000f7:	c7 04 24 c0 23 12 f0 	movl   $0xf01223c0,(%esp)
f01000fe:	e8 95 5b 00 00       	call   f0105c98 <spin_lock>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100103:	83 c4 10             	add    $0x10,%esp
f0100106:	83 3d a0 9e 2a f0 07 	cmpl   $0x7,0xf02a9ea0
f010010d:	77 16                	ja     f0100125 <i386_init+0x8b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010010f:	68 00 70 00 00       	push   $0x7000
f0100114:	68 44 66 10 f0       	push   $0xf0106644
f0100119:	6a 64                	push   $0x64
f010011b:	68 a7 66 10 f0       	push   $0xf01066a7
f0100120:	e8 1b ff ff ff       	call   f0100040 <_panic>
	void *code;
	struct CpuInfo *c;

	// Write entry code to unused memory at MPENTRY_PADDR
	code = KADDR(MPENTRY_PADDR);
	memmove(code, mpentry_start, mpentry_end - mpentry_start);
f0100125:	83 ec 04             	sub    $0x4,%esp
f0100128:	b8 86 56 10 f0       	mov    $0xf0105686,%eax
f010012d:	2d 0c 56 10 f0       	sub    $0xf010560c,%eax
f0100132:	50                   	push   %eax
f0100133:	68 0c 56 10 f0       	push   $0xf010560c
f0100138:	68 00 70 00 f0       	push   $0xf0007000
f010013d:	e8 14 53 00 00       	call   f0105456 <memmove>
f0100142:	83 c4 10             	add    $0x10,%esp

	// Boot each AP one at a time
	for (c = cpus; c < cpus + ncpu; c++) {
f0100145:	bb 20 a0 2a f0       	mov    $0xf02aa020,%ebx
f010014a:	eb 4d                	jmp    f0100199 <i386_init+0xff>
		if (c == cpus + cpunum())  // We've started already.
f010014c:	e8 d9 58 00 00       	call   f0105a2a <cpunum>
f0100151:	6b c0 74             	imul   $0x74,%eax,%eax
f0100154:	05 20 a0 2a f0       	add    $0xf02aa020,%eax
f0100159:	39 c3                	cmp    %eax,%ebx
f010015b:	74 39                	je     f0100196 <i386_init+0xfc>
			continue;

		// Tell mpentry.S what stack to use 
		mpentry_kstack = percpu_kstacks[c - cpus] + KSTKSIZE;
f010015d:	89 d8                	mov    %ebx,%eax
f010015f:	2d 20 a0 2a f0       	sub    $0xf02aa020,%eax
f0100164:	c1 f8 02             	sar    $0x2,%eax
f0100167:	69 c0 35 c2 72 4f    	imul   $0x4f72c235,%eax,%eax
f010016d:	c1 e0 0f             	shl    $0xf,%eax
f0100170:	05 00 30 2b f0       	add    $0xf02b3000,%eax
f0100175:	a3 9c 9e 2a f0       	mov    %eax,0xf02a9e9c
		// Start the CPU at mpentry_start
		lapic_startap(c->cpu_id, PADDR(code));
f010017a:	83 ec 08             	sub    $0x8,%esp
f010017d:	68 00 70 00 00       	push   $0x7000
f0100182:	0f b6 03             	movzbl (%ebx),%eax
f0100185:	50                   	push   %eax
f0100186:	e8 08 5a 00 00       	call   f0105b93 <lapic_startap>
f010018b:	83 c4 10             	add    $0x10,%esp
		// Wait for the CPU to finish some basic setup in mp_main()
		while(c->cpu_status != CPU_STARTED)
f010018e:	8b 43 04             	mov    0x4(%ebx),%eax
f0100191:	83 f8 01             	cmp    $0x1,%eax
f0100194:	75 f8                	jne    f010018e <i386_init+0xf4>
	// Write entry code to unused memory at MPENTRY_PADDR
	code = KADDR(MPENTRY_PADDR);
	memmove(code, mpentry_start, mpentry_end - mpentry_start);

	// Boot each AP one at a time
	for (c = cpus; c < cpus + ncpu; c++) {
f0100196:	83 c3 74             	add    $0x74,%ebx
f0100199:	6b 05 c4 a3 2a f0 74 	imul   $0x74,0xf02aa3c4,%eax
f01001a0:	05 20 a0 2a f0       	add    $0xf02aa020,%eax
f01001a5:	39 c3                	cmp    %eax,%ebx
f01001a7:	72 a3                	jb     f010014c <i386_init+0xb2>
    lock_kernel();
	// Starting non-boot CPUs
	boot_aps();

	// Start fs.
	ENV_CREATE(fs_fs, ENV_TYPE_FS);
f01001a9:	83 ec 08             	sub    $0x8,%esp
f01001ac:	6a 01                	push   $0x1
f01001ae:	68 f0 a0 1d f0       	push   $0xf01da0f0
f01001b3:	e8 fa 2e 00 00       	call   f01030b2 <env_create>

#if !defined(TEST_NO_NS)
	// Start ns.
	ENV_CREATE(net_ns, ENV_TYPE_NS);
f01001b8:	83 c4 08             	add    $0x8,%esp
f01001bb:	6a 02                	push   $0x2
f01001bd:	68 b4 16 23 f0       	push   $0xf02316b4
f01001c2:	e8 eb 2e 00 00       	call   f01030b2 <env_create>
#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
#else
	// Touch all you want.
	ENV_CREATE(user_icode, ENV_TYPE_USER);
f01001c7:	83 c4 08             	add    $0x8,%esp
f01001ca:	6a 00                	push   $0x0
f01001cc:	68 b8 4f 1d f0       	push   $0xf01d4fb8
f01001d1:	e8 dc 2e 00 00       	call   f01030b2 <env_create>
#endif // TEST*

	// Should not be necessary - drains keyboard because interrupt has given up.
	kbd_intr();
f01001d6:	e8 35 04 00 00       	call   f0100610 <kbd_intr>

	// Schedule and run the first user environment!
	sched_yield();
f01001db:	e8 77 40 00 00       	call   f0104257 <sched_yield>

f01001e0 <mp_main>:
}

// Setup code for APs
void
mp_main(void)
{
f01001e0:	55                   	push   %ebp
f01001e1:	89 e5                	mov    %esp,%ebp
f01001e3:	83 ec 08             	sub    $0x8,%esp
	// We are in high EIP now, safe to switch to kern_pgdir 
	lcr3(PADDR(kern_pgdir));
f01001e6:	a1 a4 9e 2a f0       	mov    0xf02a9ea4,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01001eb:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01001f0:	77 12                	ja     f0100204 <mp_main+0x24>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01001f2:	50                   	push   %eax
f01001f3:	68 68 66 10 f0       	push   $0xf0106668
f01001f8:	6a 7b                	push   $0x7b
f01001fa:	68 a7 66 10 f0       	push   $0xf01066a7
f01001ff:	e8 3c fe ff ff       	call   f0100040 <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0100204:	05 00 00 00 10       	add    $0x10000000,%eax
f0100209:	0f 22 d8             	mov    %eax,%cr3
	cprintf("SMP: CPU %d starting\n", cpunum());
f010020c:	e8 19 58 00 00       	call   f0105a2a <cpunum>
f0100211:	83 ec 08             	sub    $0x8,%esp
f0100214:	50                   	push   %eax
f0100215:	68 b3 66 10 f0       	push   $0xf01066b3
f010021a:	e8 3e 34 00 00       	call   f010365d <cprintf>

	lapic_init();
f010021f:	e8 21 58 00 00       	call   f0105a45 <lapic_init>
	env_init_percpu();
f0100224:	e8 bc 2c 00 00       	call   f0102ee5 <env_init_percpu>
	trap_init_percpu();
f0100229:	e8 43 34 00 00       	call   f0103671 <trap_init_percpu>
	xchg(&thiscpu->cpu_status, CPU_STARTED); // tell boot_aps() we're up
f010022e:	e8 f7 57 00 00       	call   f0105a2a <cpunum>
f0100233:	6b d0 74             	imul   $0x74,%eax,%edx
f0100236:	81 c2 20 a0 2a f0    	add    $0xf02aa020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"
f010023c:	b8 01 00 00 00       	mov    $0x1,%eax
f0100241:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
f0100245:	c7 04 24 c0 23 12 f0 	movl   $0xf01223c0,(%esp)
f010024c:	e8 47 5a 00 00       	call   f0105c98 <spin_lock>
	// only one CPU can enter the scheduler at a time!
	//
	// Your code here:

    lock_kernel();
    sched_yield();
f0100251:	e8 01 40 00 00       	call   f0104257 <sched_yield>

f0100256 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100256:	55                   	push   %ebp
f0100257:	89 e5                	mov    %esp,%ebp
f0100259:	53                   	push   %ebx
f010025a:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f010025d:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100260:	ff 75 0c             	pushl  0xc(%ebp)
f0100263:	ff 75 08             	pushl  0x8(%ebp)
f0100266:	68 c9 66 10 f0       	push   $0xf01066c9
f010026b:	e8 ed 33 00 00       	call   f010365d <cprintf>
	vcprintf(fmt, ap);
f0100270:	83 c4 08             	add    $0x8,%esp
f0100273:	53                   	push   %ebx
f0100274:	ff 75 10             	pushl  0x10(%ebp)
f0100277:	e8 bb 33 00 00       	call   f0103637 <vcprintf>
	cprintf("\n");
f010027c:	c7 04 24 04 78 10 f0 	movl   $0xf0107804,(%esp)
f0100283:	e8 d5 33 00 00       	call   f010365d <cprintf>
	va_end(ap);
}
f0100288:	83 c4 10             	add    $0x10,%esp
f010028b:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010028e:	c9                   	leave  
f010028f:	c3                   	ret    

f0100290 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100290:	55                   	push   %ebp
f0100291:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100293:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100298:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100299:	a8 01                	test   $0x1,%al
f010029b:	74 0b                	je     f01002a8 <serial_proc_data+0x18>
f010029d:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01002a2:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f01002a3:	0f b6 c0             	movzbl %al,%eax
f01002a6:	eb 05                	jmp    f01002ad <serial_proc_data+0x1d>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f01002a8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f01002ad:	5d                   	pop    %ebp
f01002ae:	c3                   	ret    

f01002af <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f01002af:	55                   	push   %ebp
f01002b0:	89 e5                	mov    %esp,%ebp
f01002b2:	53                   	push   %ebx
f01002b3:	83 ec 04             	sub    $0x4,%esp
f01002b6:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f01002b8:	eb 2b                	jmp    f01002e5 <cons_intr+0x36>
		if (c == 0)
f01002ba:	85 c0                	test   %eax,%eax
f01002bc:	74 27                	je     f01002e5 <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f01002be:	8b 0d 24 92 2a f0    	mov    0xf02a9224,%ecx
f01002c4:	8d 51 01             	lea    0x1(%ecx),%edx
f01002c7:	89 15 24 92 2a f0    	mov    %edx,0xf02a9224
f01002cd:	88 81 20 90 2a f0    	mov    %al,-0xfd56fe0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f01002d3:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01002d9:	75 0a                	jne    f01002e5 <cons_intr+0x36>
			cons.wpos = 0;
f01002db:	c7 05 24 92 2a f0 00 	movl   $0x0,0xf02a9224
f01002e2:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01002e5:	ff d3                	call   *%ebx
f01002e7:	83 f8 ff             	cmp    $0xffffffff,%eax
f01002ea:	75 ce                	jne    f01002ba <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01002ec:	83 c4 04             	add    $0x4,%esp
f01002ef:	5b                   	pop    %ebx
f01002f0:	5d                   	pop    %ebp
f01002f1:	c3                   	ret    

f01002f2 <kbd_proc_data>:
f01002f2:	ba 64 00 00 00       	mov    $0x64,%edx
f01002f7:	ec                   	in     (%dx),%al
	int c;
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
f01002f8:	a8 01                	test   $0x1,%al
f01002fa:	0f 84 f8 00 00 00    	je     f01003f8 <kbd_proc_data+0x106>
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
f0100300:	a8 20                	test   $0x20,%al
f0100302:	0f 85 f6 00 00 00    	jne    f01003fe <kbd_proc_data+0x10c>
f0100308:	ba 60 00 00 00       	mov    $0x60,%edx
f010030d:	ec                   	in     (%dx),%al
f010030e:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f0100310:	3c e0                	cmp    $0xe0,%al
f0100312:	75 0d                	jne    f0100321 <kbd_proc_data+0x2f>
		// E0 escape character
		shift |= E0ESC;
f0100314:	83 0d 00 90 2a f0 40 	orl    $0x40,0xf02a9000
		return 0;
f010031b:	b8 00 00 00 00       	mov    $0x0,%eax
f0100320:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f0100321:	55                   	push   %ebp
f0100322:	89 e5                	mov    %esp,%ebp
f0100324:	53                   	push   %ebx
f0100325:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f0100328:	84 c0                	test   %al,%al
f010032a:	79 36                	jns    f0100362 <kbd_proc_data+0x70>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f010032c:	8b 0d 00 90 2a f0    	mov    0xf02a9000,%ecx
f0100332:	89 cb                	mov    %ecx,%ebx
f0100334:	83 e3 40             	and    $0x40,%ebx
f0100337:	83 e0 7f             	and    $0x7f,%eax
f010033a:	85 db                	test   %ebx,%ebx
f010033c:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f010033f:	0f b6 d2             	movzbl %dl,%edx
f0100342:	0f b6 82 40 68 10 f0 	movzbl -0xfef97c0(%edx),%eax
f0100349:	83 c8 40             	or     $0x40,%eax
f010034c:	0f b6 c0             	movzbl %al,%eax
f010034f:	f7 d0                	not    %eax
f0100351:	21 c8                	and    %ecx,%eax
f0100353:	a3 00 90 2a f0       	mov    %eax,0xf02a9000
		return 0;
f0100358:	b8 00 00 00 00       	mov    $0x0,%eax
f010035d:	e9 a4 00 00 00       	jmp    f0100406 <kbd_proc_data+0x114>
	} else if (shift & E0ESC) {
f0100362:	8b 0d 00 90 2a f0    	mov    0xf02a9000,%ecx
f0100368:	f6 c1 40             	test   $0x40,%cl
f010036b:	74 0e                	je     f010037b <kbd_proc_data+0x89>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f010036d:	83 c8 80             	or     $0xffffff80,%eax
f0100370:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100372:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100375:	89 0d 00 90 2a f0    	mov    %ecx,0xf02a9000
	}

	shift |= shiftcode[data];
f010037b:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f010037e:	0f b6 82 40 68 10 f0 	movzbl -0xfef97c0(%edx),%eax
f0100385:	0b 05 00 90 2a f0    	or     0xf02a9000,%eax
f010038b:	0f b6 8a 40 67 10 f0 	movzbl -0xfef98c0(%edx),%ecx
f0100392:	31 c8                	xor    %ecx,%eax
f0100394:	a3 00 90 2a f0       	mov    %eax,0xf02a9000

	c = charcode[shift & (CTL | SHIFT)][data];
f0100399:	89 c1                	mov    %eax,%ecx
f010039b:	83 e1 03             	and    $0x3,%ecx
f010039e:	8b 0c 8d 20 67 10 f0 	mov    -0xfef98e0(,%ecx,4),%ecx
f01003a5:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f01003a9:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f01003ac:	a8 08                	test   $0x8,%al
f01003ae:	74 1b                	je     f01003cb <kbd_proc_data+0xd9>
		if ('a' <= c && c <= 'z')
f01003b0:	89 da                	mov    %ebx,%edx
f01003b2:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f01003b5:	83 f9 19             	cmp    $0x19,%ecx
f01003b8:	77 05                	ja     f01003bf <kbd_proc_data+0xcd>
			c += 'A' - 'a';
f01003ba:	83 eb 20             	sub    $0x20,%ebx
f01003bd:	eb 0c                	jmp    f01003cb <kbd_proc_data+0xd9>
		else if ('A' <= c && c <= 'Z')
f01003bf:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f01003c2:	8d 4b 20             	lea    0x20(%ebx),%ecx
f01003c5:	83 fa 19             	cmp    $0x19,%edx
f01003c8:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01003cb:	f7 d0                	not    %eax
f01003cd:	a8 06                	test   $0x6,%al
f01003cf:	75 33                	jne    f0100404 <kbd_proc_data+0x112>
f01003d1:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01003d7:	75 2b                	jne    f0100404 <kbd_proc_data+0x112>
		cprintf("Rebooting!\n");
f01003d9:	83 ec 0c             	sub    $0xc,%esp
f01003dc:	68 e3 66 10 f0       	push   $0xf01066e3
f01003e1:	e8 77 32 00 00       	call   f010365d <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01003e6:	ba 92 00 00 00       	mov    $0x92,%edx
f01003eb:	b8 03 00 00 00       	mov    $0x3,%eax
f01003f0:	ee                   	out    %al,(%dx)
f01003f1:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01003f4:	89 d8                	mov    %ebx,%eax
f01003f6:	eb 0e                	jmp    f0100406 <kbd_proc_data+0x114>
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
f01003f8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01003fd:	c3                   	ret    
	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
		return -1;
f01003fe:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100403:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100404:	89 d8                	mov    %ebx,%eax
}
f0100406:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100409:	c9                   	leave  
f010040a:	c3                   	ret    

f010040b <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f010040b:	55                   	push   %ebp
f010040c:	89 e5                	mov    %esp,%ebp
f010040e:	57                   	push   %edi
f010040f:	56                   	push   %esi
f0100410:	53                   	push   %ebx
f0100411:	83 ec 1c             	sub    $0x1c,%esp
f0100414:	89 c7                	mov    %eax,%edi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f0100416:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010041b:	be fd 03 00 00       	mov    $0x3fd,%esi
f0100420:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100425:	eb 09                	jmp    f0100430 <cons_putc+0x25>
f0100427:	89 ca                	mov    %ecx,%edx
f0100429:	ec                   	in     (%dx),%al
f010042a:	ec                   	in     (%dx),%al
f010042b:	ec                   	in     (%dx),%al
f010042c:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f010042d:	83 c3 01             	add    $0x1,%ebx
f0100430:	89 f2                	mov    %esi,%edx
f0100432:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100433:	a8 20                	test   $0x20,%al
f0100435:	75 08                	jne    f010043f <cons_putc+0x34>
f0100437:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f010043d:	7e e8                	jle    f0100427 <cons_putc+0x1c>
f010043f:	89 f8                	mov    %edi,%eax
f0100441:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100444:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100449:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010044a:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010044f:	be 79 03 00 00       	mov    $0x379,%esi
f0100454:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100459:	eb 09                	jmp    f0100464 <cons_putc+0x59>
f010045b:	89 ca                	mov    %ecx,%edx
f010045d:	ec                   	in     (%dx),%al
f010045e:	ec                   	in     (%dx),%al
f010045f:	ec                   	in     (%dx),%al
f0100460:	ec                   	in     (%dx),%al
f0100461:	83 c3 01             	add    $0x1,%ebx
f0100464:	89 f2                	mov    %esi,%edx
f0100466:	ec                   	in     (%dx),%al
f0100467:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f010046d:	7f 04                	jg     f0100473 <cons_putc+0x68>
f010046f:	84 c0                	test   %al,%al
f0100471:	79 e8                	jns    f010045b <cons_putc+0x50>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100473:	ba 78 03 00 00       	mov    $0x378,%edx
f0100478:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f010047c:	ee                   	out    %al,(%dx)
f010047d:	ba 7a 03 00 00       	mov    $0x37a,%edx
f0100482:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100487:	ee                   	out    %al,(%dx)
f0100488:	b8 08 00 00 00       	mov    $0x8,%eax
f010048d:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f010048e:	89 fa                	mov    %edi,%edx
f0100490:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100496:	89 f8                	mov    %edi,%eax
f0100498:	80 cc 07             	or     $0x7,%ah
f010049b:	85 d2                	test   %edx,%edx
f010049d:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f01004a0:	89 f8                	mov    %edi,%eax
f01004a2:	0f b6 c0             	movzbl %al,%eax
f01004a5:	83 f8 09             	cmp    $0x9,%eax
f01004a8:	74 74                	je     f010051e <cons_putc+0x113>
f01004aa:	83 f8 09             	cmp    $0x9,%eax
f01004ad:	7f 0a                	jg     f01004b9 <cons_putc+0xae>
f01004af:	83 f8 08             	cmp    $0x8,%eax
f01004b2:	74 14                	je     f01004c8 <cons_putc+0xbd>
f01004b4:	e9 99 00 00 00       	jmp    f0100552 <cons_putc+0x147>
f01004b9:	83 f8 0a             	cmp    $0xa,%eax
f01004bc:	74 3a                	je     f01004f8 <cons_putc+0xed>
f01004be:	83 f8 0d             	cmp    $0xd,%eax
f01004c1:	74 3d                	je     f0100500 <cons_putc+0xf5>
f01004c3:	e9 8a 00 00 00       	jmp    f0100552 <cons_putc+0x147>
	case '\b':
		if (crt_pos > 0) {
f01004c8:	0f b7 05 28 92 2a f0 	movzwl 0xf02a9228,%eax
f01004cf:	66 85 c0             	test   %ax,%ax
f01004d2:	0f 84 e6 00 00 00    	je     f01005be <cons_putc+0x1b3>
			crt_pos--;
f01004d8:	83 e8 01             	sub    $0x1,%eax
f01004db:	66 a3 28 92 2a f0    	mov    %ax,0xf02a9228
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01004e1:	0f b7 c0             	movzwl %ax,%eax
f01004e4:	66 81 e7 00 ff       	and    $0xff00,%di
f01004e9:	83 cf 20             	or     $0x20,%edi
f01004ec:	8b 15 2c 92 2a f0    	mov    0xf02a922c,%edx
f01004f2:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01004f6:	eb 78                	jmp    f0100570 <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01004f8:	66 83 05 28 92 2a f0 	addw   $0x50,0xf02a9228
f01004ff:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f0100500:	0f b7 05 28 92 2a f0 	movzwl 0xf02a9228,%eax
f0100507:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f010050d:	c1 e8 16             	shr    $0x16,%eax
f0100510:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100513:	c1 e0 04             	shl    $0x4,%eax
f0100516:	66 a3 28 92 2a f0    	mov    %ax,0xf02a9228
f010051c:	eb 52                	jmp    f0100570 <cons_putc+0x165>
		break;
	case '\t':
		cons_putc(' ');
f010051e:	b8 20 00 00 00       	mov    $0x20,%eax
f0100523:	e8 e3 fe ff ff       	call   f010040b <cons_putc>
		cons_putc(' ');
f0100528:	b8 20 00 00 00       	mov    $0x20,%eax
f010052d:	e8 d9 fe ff ff       	call   f010040b <cons_putc>
		cons_putc(' ');
f0100532:	b8 20 00 00 00       	mov    $0x20,%eax
f0100537:	e8 cf fe ff ff       	call   f010040b <cons_putc>
		cons_putc(' ');
f010053c:	b8 20 00 00 00       	mov    $0x20,%eax
f0100541:	e8 c5 fe ff ff       	call   f010040b <cons_putc>
		cons_putc(' ');
f0100546:	b8 20 00 00 00       	mov    $0x20,%eax
f010054b:	e8 bb fe ff ff       	call   f010040b <cons_putc>
f0100550:	eb 1e                	jmp    f0100570 <cons_putc+0x165>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100552:	0f b7 05 28 92 2a f0 	movzwl 0xf02a9228,%eax
f0100559:	8d 50 01             	lea    0x1(%eax),%edx
f010055c:	66 89 15 28 92 2a f0 	mov    %dx,0xf02a9228
f0100563:	0f b7 c0             	movzwl %ax,%eax
f0100566:	8b 15 2c 92 2a f0    	mov    0xf02a922c,%edx
f010056c:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100570:	66 81 3d 28 92 2a f0 	cmpw   $0x7cf,0xf02a9228
f0100577:	cf 07 
f0100579:	76 43                	jbe    f01005be <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010057b:	a1 2c 92 2a f0       	mov    0xf02a922c,%eax
f0100580:	83 ec 04             	sub    $0x4,%esp
f0100583:	68 00 0f 00 00       	push   $0xf00
f0100588:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f010058e:	52                   	push   %edx
f010058f:	50                   	push   %eax
f0100590:	e8 c1 4e 00 00       	call   f0105456 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100595:	8b 15 2c 92 2a f0    	mov    0xf02a922c,%edx
f010059b:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f01005a1:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f01005a7:	83 c4 10             	add    $0x10,%esp
f01005aa:	66 c7 00 20 07       	movw   $0x720,(%eax)
f01005af:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01005b2:	39 d0                	cmp    %edx,%eax
f01005b4:	75 f4                	jne    f01005aa <cons_putc+0x19f>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f01005b6:	66 83 2d 28 92 2a f0 	subw   $0x50,0xf02a9228
f01005bd:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f01005be:	8b 0d 30 92 2a f0    	mov    0xf02a9230,%ecx
f01005c4:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005c9:	89 ca                	mov    %ecx,%edx
f01005cb:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01005cc:	0f b7 1d 28 92 2a f0 	movzwl 0xf02a9228,%ebx
f01005d3:	8d 71 01             	lea    0x1(%ecx),%esi
f01005d6:	89 d8                	mov    %ebx,%eax
f01005d8:	66 c1 e8 08          	shr    $0x8,%ax
f01005dc:	89 f2                	mov    %esi,%edx
f01005de:	ee                   	out    %al,(%dx)
f01005df:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005e4:	89 ca                	mov    %ecx,%edx
f01005e6:	ee                   	out    %al,(%dx)
f01005e7:	89 d8                	mov    %ebx,%eax
f01005e9:	89 f2                	mov    %esi,%edx
f01005eb:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01005ec:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01005ef:	5b                   	pop    %ebx
f01005f0:	5e                   	pop    %esi
f01005f1:	5f                   	pop    %edi
f01005f2:	5d                   	pop    %ebp
f01005f3:	c3                   	ret    

f01005f4 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01005f4:	80 3d 34 92 2a f0 00 	cmpb   $0x0,0xf02a9234
f01005fb:	74 11                	je     f010060e <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01005fd:	55                   	push   %ebp
f01005fe:	89 e5                	mov    %esp,%ebp
f0100600:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f0100603:	b8 90 02 10 f0       	mov    $0xf0100290,%eax
f0100608:	e8 a2 fc ff ff       	call   f01002af <cons_intr>
}
f010060d:	c9                   	leave  
f010060e:	f3 c3                	repz ret 

f0100610 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f0100610:	55                   	push   %ebp
f0100611:	89 e5                	mov    %esp,%ebp
f0100613:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f0100616:	b8 f2 02 10 f0       	mov    $0xf01002f2,%eax
f010061b:	e8 8f fc ff ff       	call   f01002af <cons_intr>
}
f0100620:	c9                   	leave  
f0100621:	c3                   	ret    

f0100622 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f0100622:	55                   	push   %ebp
f0100623:	89 e5                	mov    %esp,%ebp
f0100625:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f0100628:	e8 c7 ff ff ff       	call   f01005f4 <serial_intr>
	kbd_intr();
f010062d:	e8 de ff ff ff       	call   f0100610 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100632:	a1 20 92 2a f0       	mov    0xf02a9220,%eax
f0100637:	3b 05 24 92 2a f0    	cmp    0xf02a9224,%eax
f010063d:	74 26                	je     f0100665 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f010063f:	8d 50 01             	lea    0x1(%eax),%edx
f0100642:	89 15 20 92 2a f0    	mov    %edx,0xf02a9220
f0100648:	0f b6 88 20 90 2a f0 	movzbl -0xfd56fe0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f010064f:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f0100651:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100657:	75 11                	jne    f010066a <cons_getc+0x48>
			cons.rpos = 0;
f0100659:	c7 05 20 92 2a f0 00 	movl   $0x0,0xf02a9220
f0100660:	00 00 00 
f0100663:	eb 05                	jmp    f010066a <cons_getc+0x48>
		return c;
	}
	return 0;
f0100665:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010066a:	c9                   	leave  
f010066b:	c3                   	ret    

f010066c <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f010066c:	55                   	push   %ebp
f010066d:	89 e5                	mov    %esp,%ebp
f010066f:	57                   	push   %edi
f0100670:	56                   	push   %esi
f0100671:	53                   	push   %ebx
f0100672:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100675:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010067c:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100683:	5a a5 
	if (*cp != 0xA55A) {
f0100685:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010068c:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100690:	74 11                	je     f01006a3 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100692:	c7 05 30 92 2a f0 b4 	movl   $0x3b4,0xf02a9230
f0100699:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010069c:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f01006a1:	eb 16                	jmp    f01006b9 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f01006a3:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f01006aa:	c7 05 30 92 2a f0 d4 	movl   $0x3d4,0xf02a9230
f01006b1:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01006b4:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f01006b9:	8b 3d 30 92 2a f0    	mov    0xf02a9230,%edi
f01006bf:	b8 0e 00 00 00       	mov    $0xe,%eax
f01006c4:	89 fa                	mov    %edi,%edx
f01006c6:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01006c7:	8d 5f 01             	lea    0x1(%edi),%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01006ca:	89 da                	mov    %ebx,%edx
f01006cc:	ec                   	in     (%dx),%al
f01006cd:	0f b6 c8             	movzbl %al,%ecx
f01006d0:	c1 e1 08             	shl    $0x8,%ecx
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01006d3:	b8 0f 00 00 00       	mov    $0xf,%eax
f01006d8:	89 fa                	mov    %edi,%edx
f01006da:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01006db:	89 da                	mov    %ebx,%edx
f01006dd:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01006de:	89 35 2c 92 2a f0    	mov    %esi,0xf02a922c
	crt_pos = pos;
f01006e4:	0f b6 c0             	movzbl %al,%eax
f01006e7:	09 c8                	or     %ecx,%eax
f01006e9:	66 a3 28 92 2a f0    	mov    %ax,0xf02a9228

static void
kbd_init(void)
{
	// Drain the kbd buffer so that QEMU generates interrupts.
	kbd_intr();
f01006ef:	e8 1c ff ff ff       	call   f0100610 <kbd_intr>
	irq_setmask_8259A(irq_mask_8259A & ~(1<<IRQ_KBD));
f01006f4:	83 ec 0c             	sub    $0xc,%esp
f01006f7:	0f b7 05 a8 23 12 f0 	movzwl 0xf01223a8,%eax
f01006fe:	25 fd ff 00 00       	and    $0xfffd,%eax
f0100703:	50                   	push   %eax
f0100704:	e8 ed 2d 00 00       	call   f01034f6 <irq_setmask_8259A>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100709:	be fa 03 00 00       	mov    $0x3fa,%esi
f010070e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100713:	89 f2                	mov    %esi,%edx
f0100715:	ee                   	out    %al,(%dx)
f0100716:	ba fb 03 00 00       	mov    $0x3fb,%edx
f010071b:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100720:	ee                   	out    %al,(%dx)
f0100721:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f0100726:	b8 0c 00 00 00       	mov    $0xc,%eax
f010072b:	89 da                	mov    %ebx,%edx
f010072d:	ee                   	out    %al,(%dx)
f010072e:	ba f9 03 00 00       	mov    $0x3f9,%edx
f0100733:	b8 00 00 00 00       	mov    $0x0,%eax
f0100738:	ee                   	out    %al,(%dx)
f0100739:	ba fb 03 00 00       	mov    $0x3fb,%edx
f010073e:	b8 03 00 00 00       	mov    $0x3,%eax
f0100743:	ee                   	out    %al,(%dx)
f0100744:	ba fc 03 00 00       	mov    $0x3fc,%edx
f0100749:	b8 00 00 00 00       	mov    $0x0,%eax
f010074e:	ee                   	out    %al,(%dx)
f010074f:	ba f9 03 00 00       	mov    $0x3f9,%edx
f0100754:	b8 01 00 00 00       	mov    $0x1,%eax
f0100759:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010075a:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010075f:	ec                   	in     (%dx),%al
f0100760:	89 c1                	mov    %eax,%ecx
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100762:	83 c4 10             	add    $0x10,%esp
f0100765:	3c ff                	cmp    $0xff,%al
f0100767:	0f 95 05 34 92 2a f0 	setne  0xf02a9234
f010076e:	89 f2                	mov    %esi,%edx
f0100770:	ec                   	in     (%dx),%al
f0100771:	89 da                	mov    %ebx,%edx
f0100773:	ec                   	in     (%dx),%al
	(void) inb(COM1+COM_IIR);
	(void) inb(COM1+COM_RX);

	// Enable serial interrupts
	if (serial_exists)
f0100774:	80 f9 ff             	cmp    $0xff,%cl
f0100777:	74 21                	je     f010079a <cons_init+0x12e>
		irq_setmask_8259A(irq_mask_8259A & ~(1<<IRQ_SERIAL));
f0100779:	83 ec 0c             	sub    $0xc,%esp
f010077c:	0f b7 05 a8 23 12 f0 	movzwl 0xf01223a8,%eax
f0100783:	25 ef ff 00 00       	and    $0xffef,%eax
f0100788:	50                   	push   %eax
f0100789:	e8 68 2d 00 00       	call   f01034f6 <irq_setmask_8259A>
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f010078e:	83 c4 10             	add    $0x10,%esp
f0100791:	80 3d 34 92 2a f0 00 	cmpb   $0x0,0xf02a9234
f0100798:	75 10                	jne    f01007aa <cons_init+0x13e>
		cprintf("Serial port does not exist!\n");
f010079a:	83 ec 0c             	sub    $0xc,%esp
f010079d:	68 ef 66 10 f0       	push   $0xf01066ef
f01007a2:	e8 b6 2e 00 00       	call   f010365d <cprintf>
f01007a7:	83 c4 10             	add    $0x10,%esp
}
f01007aa:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01007ad:	5b                   	pop    %ebx
f01007ae:	5e                   	pop    %esi
f01007af:	5f                   	pop    %edi
f01007b0:	5d                   	pop    %ebp
f01007b1:	c3                   	ret    

f01007b2 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f01007b2:	55                   	push   %ebp
f01007b3:	89 e5                	mov    %esp,%ebp
f01007b5:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f01007b8:	8b 45 08             	mov    0x8(%ebp),%eax
f01007bb:	e8 4b fc ff ff       	call   f010040b <cons_putc>
}
f01007c0:	c9                   	leave  
f01007c1:	c3                   	ret    

f01007c2 <getchar>:

int
getchar(void)
{
f01007c2:	55                   	push   %ebp
f01007c3:	89 e5                	mov    %esp,%ebp
f01007c5:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f01007c8:	e8 55 fe ff ff       	call   f0100622 <cons_getc>
f01007cd:	85 c0                	test   %eax,%eax
f01007cf:	74 f7                	je     f01007c8 <getchar+0x6>
		/* do nothing */;
	return c;
}
f01007d1:	c9                   	leave  
f01007d2:	c3                   	ret    

f01007d3 <iscons>:

int
iscons(int fdnum)
{
f01007d3:	55                   	push   %ebp
f01007d4:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f01007d6:	b8 01 00 00 00       	mov    $0x1,%eax
f01007db:	5d                   	pop    %ebp
f01007dc:	c3                   	ret    

f01007dd <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f01007dd:	55                   	push   %ebp
f01007de:	89 e5                	mov    %esp,%ebp
f01007e0:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f01007e3:	68 40 69 10 f0       	push   $0xf0106940
f01007e8:	68 5e 69 10 f0       	push   $0xf010695e
f01007ed:	68 63 69 10 f0       	push   $0xf0106963
f01007f2:	e8 66 2e 00 00       	call   f010365d <cprintf>
f01007f7:	83 c4 0c             	add    $0xc,%esp
f01007fa:	68 ec 69 10 f0       	push   $0xf01069ec
f01007ff:	68 6c 69 10 f0       	push   $0xf010696c
f0100804:	68 63 69 10 f0       	push   $0xf0106963
f0100809:	e8 4f 2e 00 00       	call   f010365d <cprintf>
	return 0;
}
f010080e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100813:	c9                   	leave  
f0100814:	c3                   	ret    

f0100815 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100815:	55                   	push   %ebp
f0100816:	89 e5                	mov    %esp,%ebp
f0100818:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f010081b:	68 75 69 10 f0       	push   $0xf0106975
f0100820:	e8 38 2e 00 00       	call   f010365d <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100825:	83 c4 08             	add    $0x8,%esp
f0100828:	68 0c 00 10 00       	push   $0x10000c
f010082d:	68 14 6a 10 f0       	push   $0xf0106a14
f0100832:	e8 26 2e 00 00       	call   f010365d <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100837:	83 c4 0c             	add    $0xc,%esp
f010083a:	68 0c 00 10 00       	push   $0x10000c
f010083f:	68 0c 00 10 f0       	push   $0xf010000c
f0100844:	68 3c 6a 10 f0       	push   $0xf0106a3c
f0100849:	e8 0f 2e 00 00       	call   f010365d <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f010084e:	83 c4 0c             	add    $0xc,%esp
f0100851:	68 11 66 10 00       	push   $0x106611
f0100856:	68 11 66 10 f0       	push   $0xf0106611
f010085b:	68 60 6a 10 f0       	push   $0xf0106a60
f0100860:	e8 f8 2d 00 00       	call   f010365d <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f0100865:	83 c4 0c             	add    $0xc,%esp
f0100868:	68 2c 87 2a 00       	push   $0x2a872c
f010086d:	68 2c 87 2a f0       	push   $0xf02a872c
f0100872:	68 84 6a 10 f0       	push   $0xf0106a84
f0100877:	e8 e1 2d 00 00       	call   f010365d <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010087c:	83 c4 0c             	add    $0xc,%esp
f010087f:	68 08 b0 2e 00       	push   $0x2eb008
f0100884:	68 08 b0 2e f0       	push   $0xf02eb008
f0100889:	68 a8 6a 10 f0       	push   $0xf0106aa8
f010088e:	e8 ca 2d 00 00       	call   f010365d <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f0100893:	b8 07 b4 2e f0       	mov    $0xf02eb407,%eax
f0100898:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f010089d:	83 c4 08             	add    $0x8,%esp
f01008a0:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f01008a5:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f01008ab:	85 c0                	test   %eax,%eax
f01008ad:	0f 48 c2             	cmovs  %edx,%eax
f01008b0:	c1 f8 0a             	sar    $0xa,%eax
f01008b3:	50                   	push   %eax
f01008b4:	68 cc 6a 10 f0       	push   $0xf0106acc
f01008b9:	e8 9f 2d 00 00       	call   f010365d <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f01008be:	b8 00 00 00 00       	mov    $0x0,%eax
f01008c3:	c9                   	leave  
f01008c4:	c3                   	ret    

f01008c5 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f01008c5:	55                   	push   %ebp
f01008c6:	89 e5                	mov    %esp,%ebp
f01008c8:	56                   	push   %esi
f01008c9:	53                   	push   %ebx
f01008ca:	83 ec 2c             	sub    $0x2c,%esp

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f01008cd:	89 eb                	mov    %ebp,%ebx
	uintptr_t ebp = read_ebp();
	struct Eipdebuginfo info;
	cprintf("Stack backtrace:\n");
f01008cf:	68 8e 69 10 f0       	push   $0xf010698e
f01008d4:	e8 84 2d 00 00       	call   f010365d <cprintf>
	while(ebp != 0){
f01008d9:	83 c4 10             	add    $0x10,%esp
		cprintf("  ebp %08x  eip %08x  args %08x %08x %08x %08x %08x\n", ebp , 
				*((uintptr_t *)ebp + 1), *((uintptr_t *)ebp + 2), *((uintptr_t *)ebp + 3), 
			    *((uintptr_t *)ebp + 4), *((uintptr_t *)ebp + 5), *((uintptr_t *)ebp + 6));
		debuginfo_eip(*((uintptr_t *)ebp + 1), &info);
f01008dc:	8d 75 e0             	lea    -0x20(%ebp),%esi
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	uintptr_t ebp = read_ebp();
	struct Eipdebuginfo info;
	cprintf("Stack backtrace:\n");
	while(ebp != 0){
f01008df:	eb 4e                	jmp    f010092f <mon_backtrace+0x6a>
		cprintf("  ebp %08x  eip %08x  args %08x %08x %08x %08x %08x\n", ebp , 
f01008e1:	ff 73 18             	pushl  0x18(%ebx)
f01008e4:	ff 73 14             	pushl  0x14(%ebx)
f01008e7:	ff 73 10             	pushl  0x10(%ebx)
f01008ea:	ff 73 0c             	pushl  0xc(%ebx)
f01008ed:	ff 73 08             	pushl  0x8(%ebx)
f01008f0:	ff 73 04             	pushl  0x4(%ebx)
f01008f3:	53                   	push   %ebx
f01008f4:	68 f8 6a 10 f0       	push   $0xf0106af8
f01008f9:	e8 5f 2d 00 00       	call   f010365d <cprintf>
				*((uintptr_t *)ebp + 1), *((uintptr_t *)ebp + 2), *((uintptr_t *)ebp + 3), 
			    *((uintptr_t *)ebp + 4), *((uintptr_t *)ebp + 5), *((uintptr_t *)ebp + 6));
		debuginfo_eip(*((uintptr_t *)ebp + 1), &info);
f01008fe:	83 c4 18             	add    $0x18,%esp
f0100901:	56                   	push   %esi
f0100902:	ff 73 04             	pushl  0x4(%ebx)
f0100905:	e8 37 40 00 00       	call   f0104941 <debuginfo_eip>
		cprintf("%s:%d: %.*s+%d\n", info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, 
f010090a:	83 c4 08             	add    $0x8,%esp
f010090d:	8b 43 04             	mov    0x4(%ebx),%eax
f0100910:	2b 45 f0             	sub    -0x10(%ebp),%eax
f0100913:	50                   	push   %eax
f0100914:	ff 75 e8             	pushl  -0x18(%ebp)
f0100917:	ff 75 ec             	pushl  -0x14(%ebp)
f010091a:	ff 75 e4             	pushl  -0x1c(%ebp)
f010091d:	ff 75 e0             	pushl  -0x20(%ebp)
f0100920:	68 a0 69 10 f0       	push   $0xf01069a0
f0100925:	e8 33 2d 00 00       	call   f010365d <cprintf>
				*((uintptr_t *)ebp + 1) - info.eip_fn_addr);
		ebp = *(uintptr_t *)ebp;
f010092a:	8b 1b                	mov    (%ebx),%ebx
f010092c:	83 c4 20             	add    $0x20,%esp
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	uintptr_t ebp = read_ebp();
	struct Eipdebuginfo info;
	cprintf("Stack backtrace:\n");
	while(ebp != 0){
f010092f:	85 db                	test   %ebx,%ebx
f0100931:	75 ae                	jne    f01008e1 <mon_backtrace+0x1c>
		cprintf("%s:%d: %.*s+%d\n", info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, 
				*((uintptr_t *)ebp + 1) - info.eip_fn_addr);
		ebp = *(uintptr_t *)ebp;
	}
	return 0;
}
f0100933:	b8 00 00 00 00       	mov    $0x0,%eax
f0100938:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010093b:	5b                   	pop    %ebx
f010093c:	5e                   	pop    %esi
f010093d:	5d                   	pop    %ebp
f010093e:	c3                   	ret    

f010093f <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f010093f:	55                   	push   %ebp
f0100940:	89 e5                	mov    %esp,%ebp
f0100942:	57                   	push   %edi
f0100943:	56                   	push   %esi
f0100944:	53                   	push   %ebx
f0100945:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100948:	68 30 6b 10 f0       	push   $0xf0106b30
f010094d:	e8 0b 2d 00 00       	call   f010365d <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100952:	c7 04 24 54 6b 10 f0 	movl   $0xf0106b54,(%esp)
f0100959:	e8 ff 2c 00 00       	call   f010365d <cprintf>

	if (tf != NULL)
f010095e:	83 c4 10             	add    $0x10,%esp
f0100961:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f0100965:	74 0e                	je     f0100975 <monitor+0x36>
		print_trapframe(tf);
f0100967:	83 ec 0c             	sub    $0xc,%esp
f010096a:	ff 75 08             	pushl  0x8(%ebp)
f010096d:	e8 9a 32 00 00       	call   f0103c0c <print_trapframe>
f0100972:	83 c4 10             	add    $0x10,%esp

	while (1) {
		buf = readline("K> ");
f0100975:	83 ec 0c             	sub    $0xc,%esp
f0100978:	68 b0 69 10 f0       	push   $0xf01069b0
f010097d:	e8 18 48 00 00       	call   f010519a <readline>
f0100982:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100984:	83 c4 10             	add    $0x10,%esp
f0100987:	85 c0                	test   %eax,%eax
f0100989:	74 ea                	je     f0100975 <monitor+0x36>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f010098b:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100992:	be 00 00 00 00       	mov    $0x0,%esi
f0100997:	eb 0a                	jmp    f01009a3 <monitor+0x64>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100999:	c6 03 00             	movb   $0x0,(%ebx)
f010099c:	89 f7                	mov    %esi,%edi
f010099e:	8d 5b 01             	lea    0x1(%ebx),%ebx
f01009a1:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f01009a3:	0f b6 03             	movzbl (%ebx),%eax
f01009a6:	84 c0                	test   %al,%al
f01009a8:	74 63                	je     f0100a0d <monitor+0xce>
f01009aa:	83 ec 08             	sub    $0x8,%esp
f01009ad:	0f be c0             	movsbl %al,%eax
f01009b0:	50                   	push   %eax
f01009b1:	68 b4 69 10 f0       	push   $0xf01069b4
f01009b6:	e8 11 4a 00 00       	call   f01053cc <strchr>
f01009bb:	83 c4 10             	add    $0x10,%esp
f01009be:	85 c0                	test   %eax,%eax
f01009c0:	75 d7                	jne    f0100999 <monitor+0x5a>
			*buf++ = 0;
		if (*buf == 0)
f01009c2:	80 3b 00             	cmpb   $0x0,(%ebx)
f01009c5:	74 46                	je     f0100a0d <monitor+0xce>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f01009c7:	83 fe 0f             	cmp    $0xf,%esi
f01009ca:	75 14                	jne    f01009e0 <monitor+0xa1>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01009cc:	83 ec 08             	sub    $0x8,%esp
f01009cf:	6a 10                	push   $0x10
f01009d1:	68 b9 69 10 f0       	push   $0xf01069b9
f01009d6:	e8 82 2c 00 00       	call   f010365d <cprintf>
f01009db:	83 c4 10             	add    $0x10,%esp
f01009de:	eb 95                	jmp    f0100975 <monitor+0x36>
			return 0;
		}
		argv[argc++] = buf;
f01009e0:	8d 7e 01             	lea    0x1(%esi),%edi
f01009e3:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f01009e7:	eb 03                	jmp    f01009ec <monitor+0xad>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f01009e9:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f01009ec:	0f b6 03             	movzbl (%ebx),%eax
f01009ef:	84 c0                	test   %al,%al
f01009f1:	74 ae                	je     f01009a1 <monitor+0x62>
f01009f3:	83 ec 08             	sub    $0x8,%esp
f01009f6:	0f be c0             	movsbl %al,%eax
f01009f9:	50                   	push   %eax
f01009fa:	68 b4 69 10 f0       	push   $0xf01069b4
f01009ff:	e8 c8 49 00 00       	call   f01053cc <strchr>
f0100a04:	83 c4 10             	add    $0x10,%esp
f0100a07:	85 c0                	test   %eax,%eax
f0100a09:	74 de                	je     f01009e9 <monitor+0xaa>
f0100a0b:	eb 94                	jmp    f01009a1 <monitor+0x62>
			buf++;
	}
	argv[argc] = 0;
f0100a0d:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100a14:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100a15:	85 f6                	test   %esi,%esi
f0100a17:	0f 84 58 ff ff ff    	je     f0100975 <monitor+0x36>
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100a1d:	83 ec 08             	sub    $0x8,%esp
f0100a20:	68 5e 69 10 f0       	push   $0xf010695e
f0100a25:	ff 75 a8             	pushl  -0x58(%ebp)
f0100a28:	e8 41 49 00 00       	call   f010536e <strcmp>
f0100a2d:	83 c4 10             	add    $0x10,%esp
f0100a30:	85 c0                	test   %eax,%eax
f0100a32:	74 1e                	je     f0100a52 <monitor+0x113>
f0100a34:	83 ec 08             	sub    $0x8,%esp
f0100a37:	68 6c 69 10 f0       	push   $0xf010696c
f0100a3c:	ff 75 a8             	pushl  -0x58(%ebp)
f0100a3f:	e8 2a 49 00 00       	call   f010536e <strcmp>
f0100a44:	83 c4 10             	add    $0x10,%esp
f0100a47:	85 c0                	test   %eax,%eax
f0100a49:	75 2f                	jne    f0100a7a <monitor+0x13b>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100a4b:	b8 01 00 00 00       	mov    $0x1,%eax
f0100a50:	eb 05                	jmp    f0100a57 <monitor+0x118>
		if (strcmp(argv[0], commands[i].name) == 0)
f0100a52:	b8 00 00 00 00       	mov    $0x0,%eax
			return commands[i].func(argc, argv, tf);
f0100a57:	83 ec 04             	sub    $0x4,%esp
f0100a5a:	8d 14 00             	lea    (%eax,%eax,1),%edx
f0100a5d:	01 d0                	add    %edx,%eax
f0100a5f:	ff 75 08             	pushl  0x8(%ebp)
f0100a62:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f0100a65:	51                   	push   %ecx
f0100a66:	56                   	push   %esi
f0100a67:	ff 14 85 84 6b 10 f0 	call   *-0xfef947c(,%eax,4)
		print_trapframe(tf);

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100a6e:	83 c4 10             	add    $0x10,%esp
f0100a71:	85 c0                	test   %eax,%eax
f0100a73:	78 1d                	js     f0100a92 <monitor+0x153>
f0100a75:	e9 fb fe ff ff       	jmp    f0100975 <monitor+0x36>
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100a7a:	83 ec 08             	sub    $0x8,%esp
f0100a7d:	ff 75 a8             	pushl  -0x58(%ebp)
f0100a80:	68 d6 69 10 f0       	push   $0xf01069d6
f0100a85:	e8 d3 2b 00 00       	call   f010365d <cprintf>
f0100a8a:	83 c4 10             	add    $0x10,%esp
f0100a8d:	e9 e3 fe ff ff       	jmp    f0100975 <monitor+0x36>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100a92:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100a95:	5b                   	pop    %ebx
f0100a96:	5e                   	pop    %esi
f0100a97:	5f                   	pop    %edi
f0100a98:	5d                   	pop    %ebp
f0100a99:	c3                   	ret    

f0100a9a <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f0100a9a:	55                   	push   %ebp
f0100a9b:	89 e5                	mov    %esp,%ebp
f0100a9d:	56                   	push   %esi
f0100a9e:	53                   	push   %ebx
f0100a9f:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100aa1:	83 ec 0c             	sub    $0xc,%esp
f0100aa4:	50                   	push   %eax
f0100aa5:	e8 1e 2a 00 00       	call   f01034c8 <mc146818_read>
f0100aaa:	89 c6                	mov    %eax,%esi
f0100aac:	83 c3 01             	add    $0x1,%ebx
f0100aaf:	89 1c 24             	mov    %ebx,(%esp)
f0100ab2:	e8 11 2a 00 00       	call   f01034c8 <mc146818_read>
f0100ab7:	c1 e0 08             	shl    $0x8,%eax
f0100aba:	09 f0                	or     %esi,%eax
}
f0100abc:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100abf:	5b                   	pop    %ebx
f0100ac0:	5e                   	pop    %esi
f0100ac1:	5d                   	pop    %ebp
f0100ac2:	c3                   	ret    

f0100ac3 <check_va2pa>:
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f0100ac3:	89 d1                	mov    %edx,%ecx
f0100ac5:	c1 e9 16             	shr    $0x16,%ecx
f0100ac8:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0100acb:	a8 01                	test   $0x1,%al
f0100acd:	74 52                	je     f0100b21 <check_va2pa+0x5e>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100acf:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100ad4:	89 c1                	mov    %eax,%ecx
f0100ad6:	c1 e9 0c             	shr    $0xc,%ecx
f0100ad9:	3b 0d a0 9e 2a f0    	cmp    0xf02a9ea0,%ecx
f0100adf:	72 1b                	jb     f0100afc <check_va2pa+0x39>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100ae1:	55                   	push   %ebp
f0100ae2:	89 e5                	mov    %esp,%ebp
f0100ae4:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ae7:	50                   	push   %eax
f0100ae8:	68 44 66 10 f0       	push   $0xf0106644
f0100aed:	68 85 03 00 00       	push   $0x385
f0100af2:	68 15 75 10 f0       	push   $0xf0107515
f0100af7:	e8 44 f5 ff ff       	call   f0100040 <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f0100afc:	c1 ea 0c             	shr    $0xc,%edx
f0100aff:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100b05:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100b0c:	89 c2                	mov    %eax,%edx
f0100b0e:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100b11:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100b16:	85 d2                	test   %edx,%edx
f0100b18:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100b1d:	0f 44 c2             	cmove  %edx,%eax
f0100b20:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f0100b21:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f0100b26:	c3                   	ret    

f0100b27 <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100b27:	89 c2                	mov    %eax,%edx
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100b29:	83 3d 38 92 2a f0 00 	cmpl   $0x0,0xf02a9238
f0100b30:	75 0f                	jne    f0100b41 <boot_alloc+0x1a>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100b32:	b8 07 c0 2e f0       	mov    $0xf02ec007,%eax
f0100b37:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100b3c:	a3 38 92 2a f0       	mov    %eax,0xf02a9238
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	result = nextfree;
f0100b41:	a1 38 92 2a f0       	mov    0xf02a9238,%eax
	if(n > 0){
f0100b46:	85 d2                	test   %edx,%edx
f0100b48:	74 62                	je     f0100bac <boot_alloc+0x85>
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100b4a:	55                   	push   %ebp
f0100b4b:	89 e5                	mov    %esp,%ebp
f0100b4d:	53                   	push   %ebx
f0100b4e:	83 ec 04             	sub    $0x4,%esp
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100b51:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100b56:	77 12                	ja     f0100b6a <boot_alloc+0x43>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100b58:	50                   	push   %eax
f0100b59:	68 68 66 10 f0       	push   $0xf0106668
f0100b5e:	6a 6e                	push   $0x6e
f0100b60:	68 15 75 10 f0       	push   $0xf0107515
f0100b65:	e8 d6 f4 ff ff       	call   f0100040 <_panic>
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	result = nextfree;
	if(n > 0){
		if (PADDR(nextfree) + n > (npages + 1) * PGSIZE) {
f0100b6a:	8d 9c 10 00 00 00 10 	lea    0x10000000(%eax,%edx,1),%ebx
f0100b71:	8b 0d a0 9e 2a f0    	mov    0xf02a9ea0,%ecx
f0100b77:	83 c1 01             	add    $0x1,%ecx
f0100b7a:	c1 e1 0c             	shl    $0xc,%ecx
f0100b7d:	39 cb                	cmp    %ecx,%ebx
f0100b7f:	76 14                	jbe    f0100b95 <boot_alloc+0x6e>
			panic("out of memory\n");
f0100b81:	83 ec 04             	sub    $0x4,%esp
f0100b84:	68 21 75 10 f0       	push   $0xf0107521
f0100b89:	6a 6f                	push   $0x6f
f0100b8b:	68 15 75 10 f0       	push   $0xf0107515
f0100b90:	e8 ab f4 ff ff       	call   f0100040 <_panic>
		}
		nextfree = ROUNDUP((char *)nextfree + n, PGSIZE);
f0100b95:	8d 94 10 ff 0f 00 00 	lea    0xfff(%eax,%edx,1),%edx
f0100b9c:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100ba2:	89 15 38 92 2a f0    	mov    %edx,0xf02a9238
	}
	return result;
}
f0100ba8:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100bab:	c9                   	leave  
f0100bac:	f3 c3                	repz ret 

f0100bae <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100bae:	55                   	push   %ebp
f0100baf:	89 e5                	mov    %esp,%ebp
f0100bb1:	57                   	push   %edi
f0100bb2:	56                   	push   %esi
f0100bb3:	53                   	push   %ebx
f0100bb4:	83 ec 2c             	sub    $0x2c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100bb7:	84 c0                	test   %al,%al
f0100bb9:	0f 85 a0 02 00 00    	jne    f0100e5f <check_page_free_list+0x2b1>
f0100bbf:	e9 ad 02 00 00       	jmp    f0100e71 <check_page_free_list+0x2c3>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f0100bc4:	83 ec 04             	sub    $0x4,%esp
f0100bc7:	68 94 6b 10 f0       	push   $0xf0106b94
f0100bcc:	68 b8 02 00 00       	push   $0x2b8
f0100bd1:	68 15 75 10 f0       	push   $0xf0107515
f0100bd6:	e8 65 f4 ff ff       	call   f0100040 <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100bdb:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100bde:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100be1:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100be4:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100be7:	89 c2                	mov    %eax,%edx
f0100be9:	2b 15 a8 9e 2a f0    	sub    0xf02a9ea8,%edx
f0100bef:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100bf5:	0f 95 c2             	setne  %dl
f0100bf8:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100bfb:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100bff:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100c01:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c05:	8b 00                	mov    (%eax),%eax
f0100c07:	85 c0                	test   %eax,%eax
f0100c09:	75 dc                	jne    f0100be7 <check_page_free_list+0x39>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100c0b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100c0e:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100c14:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100c17:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100c1a:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100c1c:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100c1f:	a3 40 92 2a f0       	mov    %eax,0xf02a9240
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100c24:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100c29:	8b 1d 40 92 2a f0    	mov    0xf02a9240,%ebx
f0100c2f:	eb 53                	jmp    f0100c84 <check_page_free_list+0xd6>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100c31:	89 d8                	mov    %ebx,%eax
f0100c33:	2b 05 a8 9e 2a f0    	sub    0xf02a9ea8,%eax
f0100c39:	c1 f8 03             	sar    $0x3,%eax
f0100c3c:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100c3f:	89 c2                	mov    %eax,%edx
f0100c41:	c1 ea 16             	shr    $0x16,%edx
f0100c44:	39 f2                	cmp    %esi,%edx
f0100c46:	73 3a                	jae    f0100c82 <check_page_free_list+0xd4>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100c48:	89 c2                	mov    %eax,%edx
f0100c4a:	c1 ea 0c             	shr    $0xc,%edx
f0100c4d:	3b 15 a0 9e 2a f0    	cmp    0xf02a9ea0,%edx
f0100c53:	72 12                	jb     f0100c67 <check_page_free_list+0xb9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100c55:	50                   	push   %eax
f0100c56:	68 44 66 10 f0       	push   $0xf0106644
f0100c5b:	6a 58                	push   $0x58
f0100c5d:	68 30 75 10 f0       	push   $0xf0107530
f0100c62:	e8 d9 f3 ff ff       	call   f0100040 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100c67:	83 ec 04             	sub    $0x4,%esp
f0100c6a:	68 80 00 00 00       	push   $0x80
f0100c6f:	68 97 00 00 00       	push   $0x97
f0100c74:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100c79:	50                   	push   %eax
f0100c7a:	e8 8a 47 00 00       	call   f0105409 <memset>
f0100c7f:	83 c4 10             	add    $0x10,%esp
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100c82:	8b 1b                	mov    (%ebx),%ebx
f0100c84:	85 db                	test   %ebx,%ebx
f0100c86:	75 a9                	jne    f0100c31 <check_page_free_list+0x83>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100c88:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c8d:	e8 95 fe ff ff       	call   f0100b27 <boot_alloc>
f0100c92:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c95:	8b 15 40 92 2a f0    	mov    0xf02a9240,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100c9b:	8b 0d a8 9e 2a f0    	mov    0xf02a9ea8,%ecx
		assert(pp < pages + npages);
f0100ca1:	a1 a0 9e 2a f0       	mov    0xf02a9ea0,%eax
f0100ca6:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0100ca9:	8d 04 c1             	lea    (%ecx,%eax,8),%eax
f0100cac:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100caf:	89 4d d0             	mov    %ecx,-0x30(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100cb2:	be 00 00 00 00       	mov    $0x0,%esi
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100cb7:	e9 52 01 00 00       	jmp    f0100e0e <check_page_free_list+0x260>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100cbc:	39 ca                	cmp    %ecx,%edx
f0100cbe:	73 19                	jae    f0100cd9 <check_page_free_list+0x12b>
f0100cc0:	68 3e 75 10 f0       	push   $0xf010753e
f0100cc5:	68 4a 75 10 f0       	push   $0xf010754a
f0100cca:	68 d2 02 00 00       	push   $0x2d2
f0100ccf:	68 15 75 10 f0       	push   $0xf0107515
f0100cd4:	e8 67 f3 ff ff       	call   f0100040 <_panic>
		assert(pp < pages + npages);
f0100cd9:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100cdc:	72 19                	jb     f0100cf7 <check_page_free_list+0x149>
f0100cde:	68 5f 75 10 f0       	push   $0xf010755f
f0100ce3:	68 4a 75 10 f0       	push   $0xf010754a
f0100ce8:	68 d3 02 00 00       	push   $0x2d3
f0100ced:	68 15 75 10 f0       	push   $0xf0107515
f0100cf2:	e8 49 f3 ff ff       	call   f0100040 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100cf7:	89 d0                	mov    %edx,%eax
f0100cf9:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0100cfc:	a8 07                	test   $0x7,%al
f0100cfe:	74 19                	je     f0100d19 <check_page_free_list+0x16b>
f0100d00:	68 b8 6b 10 f0       	push   $0xf0106bb8
f0100d05:	68 4a 75 10 f0       	push   $0xf010754a
f0100d0a:	68 d4 02 00 00       	push   $0x2d4
f0100d0f:	68 15 75 10 f0       	push   $0xf0107515
f0100d14:	e8 27 f3 ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100d19:	c1 f8 03             	sar    $0x3,%eax
f0100d1c:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100d1f:	85 c0                	test   %eax,%eax
f0100d21:	75 19                	jne    f0100d3c <check_page_free_list+0x18e>
f0100d23:	68 73 75 10 f0       	push   $0xf0107573
f0100d28:	68 4a 75 10 f0       	push   $0xf010754a
f0100d2d:	68 d7 02 00 00       	push   $0x2d7
f0100d32:	68 15 75 10 f0       	push   $0xf0107515
f0100d37:	e8 04 f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100d3c:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100d41:	75 19                	jne    f0100d5c <check_page_free_list+0x1ae>
f0100d43:	68 84 75 10 f0       	push   $0xf0107584
f0100d48:	68 4a 75 10 f0       	push   $0xf010754a
f0100d4d:	68 d8 02 00 00       	push   $0x2d8
f0100d52:	68 15 75 10 f0       	push   $0xf0107515
f0100d57:	e8 e4 f2 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100d5c:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100d61:	75 19                	jne    f0100d7c <check_page_free_list+0x1ce>
f0100d63:	68 ec 6b 10 f0       	push   $0xf0106bec
f0100d68:	68 4a 75 10 f0       	push   $0xf010754a
f0100d6d:	68 d9 02 00 00       	push   $0x2d9
f0100d72:	68 15 75 10 f0       	push   $0xf0107515
f0100d77:	e8 c4 f2 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100d7c:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100d81:	75 19                	jne    f0100d9c <check_page_free_list+0x1ee>
f0100d83:	68 9d 75 10 f0       	push   $0xf010759d
f0100d88:	68 4a 75 10 f0       	push   $0xf010754a
f0100d8d:	68 da 02 00 00       	push   $0x2da
f0100d92:	68 15 75 10 f0       	push   $0xf0107515
f0100d97:	e8 a4 f2 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100d9c:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100da1:	0f 86 f1 00 00 00    	jbe    f0100e98 <check_page_free_list+0x2ea>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100da7:	89 c7                	mov    %eax,%edi
f0100da9:	c1 ef 0c             	shr    $0xc,%edi
f0100dac:	39 7d c8             	cmp    %edi,-0x38(%ebp)
f0100daf:	77 12                	ja     f0100dc3 <check_page_free_list+0x215>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100db1:	50                   	push   %eax
f0100db2:	68 44 66 10 f0       	push   $0xf0106644
f0100db7:	6a 58                	push   $0x58
f0100db9:	68 30 75 10 f0       	push   $0xf0107530
f0100dbe:	e8 7d f2 ff ff       	call   f0100040 <_panic>
f0100dc3:	8d b8 00 00 00 f0    	lea    -0x10000000(%eax),%edi
f0100dc9:	39 7d cc             	cmp    %edi,-0x34(%ebp)
f0100dcc:	0f 86 b6 00 00 00    	jbe    f0100e88 <check_page_free_list+0x2da>
f0100dd2:	68 10 6c 10 f0       	push   $0xf0106c10
f0100dd7:	68 4a 75 10 f0       	push   $0xf010754a
f0100ddc:	68 db 02 00 00       	push   $0x2db
f0100de1:	68 15 75 10 f0       	push   $0xf0107515
f0100de6:	e8 55 f2 ff ff       	call   f0100040 <_panic>
		// (new test for lab 4)
		assert(page2pa(pp) != MPENTRY_PADDR);
f0100deb:	68 b7 75 10 f0       	push   $0xf01075b7
f0100df0:	68 4a 75 10 f0       	push   $0xf010754a
f0100df5:	68 dd 02 00 00       	push   $0x2dd
f0100dfa:	68 15 75 10 f0       	push   $0xf0107515
f0100dff:	e8 3c f2 ff ff       	call   f0100040 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100e04:	83 c6 01             	add    $0x1,%esi
f0100e07:	eb 03                	jmp    f0100e0c <check_page_free_list+0x25e>
		else
			++nfree_extmem;
f0100e09:	83 c3 01             	add    $0x1,%ebx
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100e0c:	8b 12                	mov    (%edx),%edx
f0100e0e:	85 d2                	test   %edx,%edx
f0100e10:	0f 85 a6 fe ff ff    	jne    f0100cbc <check_page_free_list+0x10e>
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100e16:	85 f6                	test   %esi,%esi
f0100e18:	7f 19                	jg     f0100e33 <check_page_free_list+0x285>
f0100e1a:	68 d4 75 10 f0       	push   $0xf01075d4
f0100e1f:	68 4a 75 10 f0       	push   $0xf010754a
f0100e24:	68 e5 02 00 00       	push   $0x2e5
f0100e29:	68 15 75 10 f0       	push   $0xf0107515
f0100e2e:	e8 0d f2 ff ff       	call   f0100040 <_panic>
	assert(nfree_extmem > 0);
f0100e33:	85 db                	test   %ebx,%ebx
f0100e35:	7f 19                	jg     f0100e50 <check_page_free_list+0x2a2>
f0100e37:	68 e6 75 10 f0       	push   $0xf01075e6
f0100e3c:	68 4a 75 10 f0       	push   $0xf010754a
f0100e41:	68 e6 02 00 00       	push   $0x2e6
f0100e46:	68 15 75 10 f0       	push   $0xf0107515
f0100e4b:	e8 f0 f1 ff ff       	call   f0100040 <_panic>

	cprintf("check_page_free_list() succeeded!\n");
f0100e50:	83 ec 0c             	sub    $0xc,%esp
f0100e53:	68 58 6c 10 f0       	push   $0xf0106c58
f0100e58:	e8 00 28 00 00       	call   f010365d <cprintf>
}
f0100e5d:	eb 49                	jmp    f0100ea8 <check_page_free_list+0x2fa>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100e5f:	a1 40 92 2a f0       	mov    0xf02a9240,%eax
f0100e64:	85 c0                	test   %eax,%eax
f0100e66:	0f 85 6f fd ff ff    	jne    f0100bdb <check_page_free_list+0x2d>
f0100e6c:	e9 53 fd ff ff       	jmp    f0100bc4 <check_page_free_list+0x16>
f0100e71:	83 3d 40 92 2a f0 00 	cmpl   $0x0,0xf02a9240
f0100e78:	0f 84 46 fd ff ff    	je     f0100bc4 <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100e7e:	be 00 04 00 00       	mov    $0x400,%esi
f0100e83:	e9 a1 fd ff ff       	jmp    f0100c29 <check_page_free_list+0x7b>
		assert(page2pa(pp) != IOPHYSMEM);
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
		assert(page2pa(pp) != EXTPHYSMEM);
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
		// (new test for lab 4)
		assert(page2pa(pp) != MPENTRY_PADDR);
f0100e88:	3d 00 70 00 00       	cmp    $0x7000,%eax
f0100e8d:	0f 85 76 ff ff ff    	jne    f0100e09 <check_page_free_list+0x25b>
f0100e93:	e9 53 ff ff ff       	jmp    f0100deb <check_page_free_list+0x23d>
f0100e98:	3d 00 70 00 00       	cmp    $0x7000,%eax
f0100e9d:	0f 85 61 ff ff ff    	jne    f0100e04 <check_page_free_list+0x256>
f0100ea3:	e9 43 ff ff ff       	jmp    f0100deb <check_page_free_list+0x23d>

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);

	cprintf("check_page_free_list() succeeded!\n");
}
f0100ea8:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100eab:	5b                   	pop    %ebx
f0100eac:	5e                   	pop    %esi
f0100ead:	5f                   	pop    %edi
f0100eae:	5d                   	pop    %ebp
f0100eaf:	c3                   	ret    

f0100eb0 <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100eb0:	55                   	push   %ebp
f0100eb1:	89 e5                	mov    %esp,%ebp
f0100eb3:	53                   	push   %ebx
f0100eb4:	83 ec 04             	sub    $0x4,%esp
f0100eb7:	8b 1d 40 92 2a f0    	mov    0xf02a9240,%ebx
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	
	size_t i, io_page_i, ext_page_i, free_top, mpentry_i;
	for (i = 0; i < npages; i++) {
f0100ebd:	ba 00 00 00 00       	mov    $0x0,%edx
f0100ec2:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ec7:	eb 27                	jmp    f0100ef0 <page_init+0x40>
f0100ec9:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
		pages[i].pp_ref = 0;
f0100ed0:	89 d1                	mov    %edx,%ecx
f0100ed2:	03 0d a8 9e 2a f0    	add    0xf02a9ea8,%ecx
f0100ed8:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = page_free_list;
f0100ede:	89 19                	mov    %ebx,(%ecx)
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	
	size_t i, io_page_i, ext_page_i, free_top, mpentry_i;
	for (i = 0; i < npages; i++) {
f0100ee0:	83 c0 01             	add    $0x1,%eax
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
f0100ee3:	89 d3                	mov    %edx,%ebx
f0100ee5:	03 1d a8 9e 2a f0    	add    0xf02a9ea8,%ebx
f0100eeb:	ba 01 00 00 00       	mov    $0x1,%edx
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	
	size_t i, io_page_i, ext_page_i, free_top, mpentry_i;
	for (i = 0; i < npages; i++) {
f0100ef0:	3b 05 a0 9e 2a f0    	cmp    0xf02a9ea0,%eax
f0100ef6:	72 d1                	jb     f0100ec9 <page_init+0x19>
f0100ef8:	84 d2                	test   %dl,%dl
f0100efa:	74 06                	je     f0100f02 <page_init+0x52>
f0100efc:	89 1d 40 92 2a f0    	mov    %ebx,0xf02a9240
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
  
	pages[0].pp_link = NULL;
f0100f02:	a1 a8 9e 2a f0       	mov    0xf02a9ea8,%eax
f0100f07:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pages[1].pp_link = NULL;
f0100f0d:	a1 a8 9e 2a f0       	mov    0xf02a9ea8,%eax
f0100f12:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)

	io_page_i = PGNUM(IOPHYSMEM);
	ext_page_i = PGNUM(EXTPHYSMEM);
	free_top = PGNUM(PADDR(boot_alloc(0)));
f0100f19:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f1e:	e8 04 fc ff ff       	call   f0100b27 <boot_alloc>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100f23:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100f28:	77 15                	ja     f0100f3f <page_init+0x8f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100f2a:	50                   	push   %eax
f0100f2b:	68 68 66 10 f0       	push   $0xf0106668
f0100f30:	68 4c 01 00 00       	push   $0x14c
f0100f35:	68 15 75 10 f0       	push   $0xf0107515
f0100f3a:	e8 01 f1 ff ff       	call   f0100040 <_panic>
f0100f3f:	8d 88 00 00 00 10    	lea    0x10000000(%eax),%ecx
f0100f45:	c1 e9 0c             	shr    $0xc,%ecx

	pages[ext_page_i].pp_link = pages[io_page_i].pp_link;
f0100f48:	a1 a8 9e 2a f0       	mov    0xf02a9ea8,%eax
f0100f4d:	8b 90 00 05 00 00    	mov    0x500(%eax),%edx
f0100f53:	89 90 00 08 00 00    	mov    %edx,0x800(%eax)
f0100f59:	b8 00 05 00 00       	mov    $0x500,%eax
	for(i = io_page_i;i < ext_page_i;i++)
		pages[i].pp_link = NULL;
f0100f5e:	8b 15 a8 9e 2a f0    	mov    0xf02a9ea8,%edx
f0100f64:	c7 04 02 00 00 00 00 	movl   $0x0,(%edx,%eax,1)
f0100f6b:	83 c0 08             	add    $0x8,%eax
	io_page_i = PGNUM(IOPHYSMEM);
	ext_page_i = PGNUM(EXTPHYSMEM);
	free_top = PGNUM(PADDR(boot_alloc(0)));

	pages[ext_page_i].pp_link = pages[io_page_i].pp_link;
	for(i = io_page_i;i < ext_page_i;i++)
f0100f6e:	3d 00 08 00 00       	cmp    $0x800,%eax
f0100f73:	75 e9                	jne    f0100f5e <page_init+0xae>
		pages[i].pp_link = NULL;

	pages[free_top].pp_link = pages[ext_page_i].pp_link;
f0100f75:	a1 a8 9e 2a f0       	mov    0xf02a9ea8,%eax
f0100f7a:	8b 90 00 08 00 00    	mov    0x800(%eax),%edx
f0100f80:	89 14 c8             	mov    %edx,(%eax,%ecx,8)
	for (i = ext_page_i; i < free_top; i++)
f0100f83:	b8 00 01 00 00       	mov    $0x100,%eax
f0100f88:	eb 10                	jmp    f0100f9a <page_init+0xea>
		pages[i].pp_link = NULL;
f0100f8a:	8b 15 a8 9e 2a f0    	mov    0xf02a9ea8,%edx
f0100f90:	c7 04 c2 00 00 00 00 	movl   $0x0,(%edx,%eax,8)
	pages[ext_page_i].pp_link = pages[io_page_i].pp_link;
	for(i = io_page_i;i < ext_page_i;i++)
		pages[i].pp_link = NULL;

	pages[free_top].pp_link = pages[ext_page_i].pp_link;
	for (i = ext_page_i; i < free_top; i++)
f0100f97:	83 c0 01             	add    $0x1,%eax
f0100f9a:	39 c8                	cmp    %ecx,%eax
f0100f9c:	72 ec                	jb     f0100f8a <page_init+0xda>
		pages[i].pp_link = NULL;
        
    mpentry_i = PGNUM(MPENTRY_PADDR);
    pages[mpentry_i + 1].pp_link = pages[mpentry_i].pp_link;
f0100f9e:	a1 a8 9e 2a f0       	mov    0xf02a9ea8,%eax
f0100fa3:	8b 50 38             	mov    0x38(%eax),%edx
f0100fa6:	89 50 40             	mov    %edx,0x40(%eax)
    pages[mpentry_i].pp_link = NULL;
f0100fa9:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)
}
f0100fb0:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100fb3:	c9                   	leave  
f0100fb4:	c3                   	ret    

f0100fb5 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100fb5:	55                   	push   %ebp
f0100fb6:	89 e5                	mov    %esp,%ebp
f0100fb8:	53                   	push   %ebx
f0100fb9:	83 ec 04             	sub    $0x4,%esp
	//Fill this function in
	struct PageInfo *p = page_free_list;
f0100fbc:	8b 1d 40 92 2a f0    	mov    0xf02a9240,%ebx
	if(p){
f0100fc2:	85 db                	test   %ebx,%ebx
f0100fc4:	74 5c                	je     f0101022 <page_alloc+0x6d>
		page_free_list = p->pp_link;
f0100fc6:	8b 03                	mov    (%ebx),%eax
f0100fc8:	a3 40 92 2a f0       	mov    %eax,0xf02a9240
		p->pp_link = NULL;
f0100fcd:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
		if(alloc_flags & ALLOC_ZERO){
			memset(page2kva(p), 0, PGSIZE);
		}
	}
	else return NULL;
	return p;
f0100fd3:	89 d8                	mov    %ebx,%eax
	//Fill this function in
	struct PageInfo *p = page_free_list;
	if(p){
		page_free_list = p->pp_link;
		p->pp_link = NULL;
		if(alloc_flags & ALLOC_ZERO){
f0100fd5:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100fd9:	74 4c                	je     f0101027 <page_alloc+0x72>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100fdb:	2b 05 a8 9e 2a f0    	sub    0xf02a9ea8,%eax
f0100fe1:	c1 f8 03             	sar    $0x3,%eax
f0100fe4:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100fe7:	89 c2                	mov    %eax,%edx
f0100fe9:	c1 ea 0c             	shr    $0xc,%edx
f0100fec:	3b 15 a0 9e 2a f0    	cmp    0xf02a9ea0,%edx
f0100ff2:	72 12                	jb     f0101006 <page_alloc+0x51>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ff4:	50                   	push   %eax
f0100ff5:	68 44 66 10 f0       	push   $0xf0106644
f0100ffa:	6a 58                	push   $0x58
f0100ffc:	68 30 75 10 f0       	push   $0xf0107530
f0101001:	e8 3a f0 ff ff       	call   f0100040 <_panic>
			memset(page2kva(p), 0, PGSIZE);
f0101006:	83 ec 04             	sub    $0x4,%esp
f0101009:	68 00 10 00 00       	push   $0x1000
f010100e:	6a 00                	push   $0x0
f0101010:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101015:	50                   	push   %eax
f0101016:	e8 ee 43 00 00       	call   f0105409 <memset>
f010101b:	83 c4 10             	add    $0x10,%esp
		}
	}
	else return NULL;
	return p;
f010101e:	89 d8                	mov    %ebx,%eax
f0101020:	eb 05                	jmp    f0101027 <page_alloc+0x72>
		p->pp_link = NULL;
		if(alloc_flags & ALLOC_ZERO){
			memset(page2kva(p), 0, PGSIZE);
		}
	}
	else return NULL;
f0101022:	b8 00 00 00 00       	mov    $0x0,%eax
	return p;
}
f0101027:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010102a:	c9                   	leave  
f010102b:	c3                   	ret    

f010102c <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f010102c:	55                   	push   %ebp
f010102d:	89 e5                	mov    %esp,%ebp
f010102f:	83 ec 08             	sub    $0x8,%esp
f0101032:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
	if(pp->pp_ref != 0 || pp->pp_link!=NULL){
f0101035:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f010103a:	75 05                	jne    f0101041 <page_free+0x15>
f010103c:	83 38 00             	cmpl   $0x0,(%eax)
f010103f:	74 17                	je     f0101058 <page_free+0x2c>
		panic("pp->pp_ref is nonzero or pp->pp_link is not NULL\n");
f0101041:	83 ec 04             	sub    $0x4,%esp
f0101044:	68 7c 6c 10 f0       	push   $0xf0106c7c
f0101049:	68 82 01 00 00       	push   $0x182
f010104e:	68 15 75 10 f0       	push   $0xf0107515
f0101053:	e8 e8 ef ff ff       	call   f0100040 <_panic>
	}
	pp->pp_link = page_free_list;
f0101058:	8b 15 40 92 2a f0    	mov    0xf02a9240,%edx
f010105e:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f0101060:	a3 40 92 2a f0       	mov    %eax,0xf02a9240


}
f0101065:	c9                   	leave  
f0101066:	c3                   	ret    

f0101067 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0101067:	55                   	push   %ebp
f0101068:	89 e5                	mov    %esp,%ebp
f010106a:	83 ec 08             	sub    $0x8,%esp
f010106d:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0101070:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0101074:	83 e8 01             	sub    $0x1,%eax
f0101077:	66 89 42 04          	mov    %ax,0x4(%edx)
f010107b:	66 85 c0             	test   %ax,%ax
f010107e:	75 0c                	jne    f010108c <page_decref+0x25>
		page_free(pp);
f0101080:	83 ec 0c             	sub    $0xc,%esp
f0101083:	52                   	push   %edx
f0101084:	e8 a3 ff ff ff       	call   f010102c <page_free>
f0101089:	83 c4 10             	add    $0x10,%esp
}
f010108c:	c9                   	leave  
f010108d:	c3                   	ret    

f010108e <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f010108e:	55                   	push   %ebp
f010108f:	89 e5                	mov    %esp,%ebp
f0101091:	56                   	push   %esi
f0101092:	53                   	push   %ebx
f0101093:	8b 75 0c             	mov    0xc(%ebp),%esi
	int pdr_i = PDX(va);
	pde_t *pde = &pgdir[pdr_i];
f0101096:	89 f3                	mov    %esi,%ebx
f0101098:	c1 eb 16             	shr    $0x16,%ebx
f010109b:	c1 e3 02             	shl    $0x2,%ebx
f010109e:	03 5d 08             	add    0x8(%ebp),%ebx
	pte_t *pgt;
	if(!(*pde & PTE_P)){
f01010a1:	f6 03 01             	testb  $0x1,(%ebx)
f01010a4:	75 2f                	jne    f01010d5 <pgdir_walk+0x47>
		if(!create)	
f01010a6:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f01010aa:	74 64                	je     f0101110 <pgdir_walk+0x82>
			return NULL;
		struct PageInfo *page = page_alloc(ALLOC_ZERO);
f01010ac:	83 ec 0c             	sub    $0xc,%esp
f01010af:	6a 01                	push   $0x1
f01010b1:	e8 ff fe ff ff       	call   f0100fb5 <page_alloc>
		if(page == NULL) return NULL;
f01010b6:	83 c4 10             	add    $0x10,%esp
f01010b9:	85 c0                	test   %eax,%eax
f01010bb:	74 5a                	je     f0101117 <pgdir_walk+0x89>
		*pde = page2pa(page) | PTE_P | PTE_U | PTE_W;
f01010bd:	89 c2                	mov    %eax,%edx
f01010bf:	2b 15 a8 9e 2a f0    	sub    0xf02a9ea8,%edx
f01010c5:	c1 fa 03             	sar    $0x3,%edx
f01010c8:	c1 e2 0c             	shl    $0xc,%edx
f01010cb:	83 ca 07             	or     $0x7,%edx
f01010ce:	89 13                	mov    %edx,(%ebx)
		page->pp_ref ++;
f01010d0:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
	}
	pgt = KADDR(PTE_ADDR(*pde));
f01010d5:	8b 03                	mov    (%ebx),%eax
f01010d7:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01010dc:	89 c2                	mov    %eax,%edx
f01010de:	c1 ea 0c             	shr    $0xc,%edx
f01010e1:	3b 15 a0 9e 2a f0    	cmp    0xf02a9ea0,%edx
f01010e7:	72 15                	jb     f01010fe <pgdir_walk+0x70>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01010e9:	50                   	push   %eax
f01010ea:	68 44 66 10 f0       	push   $0xf0106644
f01010ef:	68 b9 01 00 00       	push   $0x1b9
f01010f4:	68 15 75 10 f0       	push   $0xf0107515
f01010f9:	e8 42 ef ff ff       	call   f0100040 <_panic>
	
	return &pgt[PTX(va)];
f01010fe:	c1 ee 0a             	shr    $0xa,%esi
f0101101:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f0101107:	8d 84 30 00 00 00 f0 	lea    -0x10000000(%eax,%esi,1),%eax
f010110e:	eb 0c                	jmp    f010111c <pgdir_walk+0x8e>
	int pdr_i = PDX(va);
	pde_t *pde = &pgdir[pdr_i];
	pte_t *pgt;
	if(!(*pde & PTE_P)){
		if(!create)	
			return NULL;
f0101110:	b8 00 00 00 00       	mov    $0x0,%eax
f0101115:	eb 05                	jmp    f010111c <pgdir_walk+0x8e>
		struct PageInfo *page = page_alloc(ALLOC_ZERO);
		if(page == NULL) return NULL;
f0101117:	b8 00 00 00 00       	mov    $0x0,%eax
		page->pp_ref ++;
	}
	pgt = KADDR(PTE_ADDR(*pde));
	
	return &pgt[PTX(va)];
}
f010111c:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010111f:	5b                   	pop    %ebx
f0101120:	5e                   	pop    %esi
f0101121:	5d                   	pop    %ebp
f0101122:	c3                   	ret    

f0101123 <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f0101123:	55                   	push   %ebp
f0101124:	89 e5                	mov    %esp,%ebp
f0101126:	57                   	push   %edi
f0101127:	56                   	push   %esi
f0101128:	53                   	push   %ebx
f0101129:	83 ec 1c             	sub    $0x1c,%esp
f010112c:	89 45 dc             	mov    %eax,-0x24(%ebp)
f010112f:	c1 e9 0c             	shr    $0xc,%ecx
f0101132:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	int i;
	for(i = 0; i < (size / PGSIZE); i++, va += PGSIZE, pa+=PGSIZE){
f0101135:	89 d3                	mov    %edx,%ebx
f0101137:	bf 00 00 00 00       	mov    $0x0,%edi
f010113c:	8b 45 08             	mov    0x8(%ebp),%eax
f010113f:	29 d0                	sub    %edx,%eax
f0101141:	89 45 e0             	mov    %eax,-0x20(%ebp)
		pte_t* pte = pgdir_walk(pgdir,(const void *) va, 1);	
		if(pte!=NULL){
			*pte = pa|perm|PTE_P;
f0101144:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101147:	83 c8 01             	or     $0x1,%eax
f010114a:	89 45 d8             	mov    %eax,-0x28(%ebp)
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	int i;
	for(i = 0; i < (size / PGSIZE); i++, va += PGSIZE, pa+=PGSIZE){
f010114d:	eb 23                	jmp    f0101172 <boot_map_region+0x4f>
		pte_t* pte = pgdir_walk(pgdir,(const void *) va, 1);	
f010114f:	83 ec 04             	sub    $0x4,%esp
f0101152:	6a 01                	push   $0x1
f0101154:	53                   	push   %ebx
f0101155:	ff 75 dc             	pushl  -0x24(%ebp)
f0101158:	e8 31 ff ff ff       	call   f010108e <pgdir_walk>
		if(pte!=NULL){
f010115d:	83 c4 10             	add    $0x10,%esp
f0101160:	85 c0                	test   %eax,%eax
f0101162:	74 05                	je     f0101169 <boot_map_region+0x46>
			*pte = pa|perm|PTE_P;
f0101164:	0b 75 d8             	or     -0x28(%ebp),%esi
f0101167:	89 30                	mov    %esi,(%eax)
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	int i;
	for(i = 0; i < (size / PGSIZE); i++, va += PGSIZE, pa+=PGSIZE){
f0101169:	83 c7 01             	add    $0x1,%edi
f010116c:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0101172:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101175:	8d 34 18             	lea    (%eax,%ebx,1),%esi
f0101178:	3b 7d e4             	cmp    -0x1c(%ebp),%edi
f010117b:	75 d2                	jne    f010114f <boot_map_region+0x2c>
		pte_t* pte = pgdir_walk(pgdir,(const void *) va, 1);	
		if(pte!=NULL){
			*pte = pa|perm|PTE_P;
		}
	}
}
f010117d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101180:	5b                   	pop    %ebx
f0101181:	5e                   	pop    %esi
f0101182:	5f                   	pop    %edi
f0101183:	5d                   	pop    %ebp
f0101184:	c3                   	ret    

f0101185 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0101185:	55                   	push   %ebp
f0101186:	89 e5                	mov    %esp,%ebp
f0101188:	53                   	push   %ebx
f0101189:	83 ec 08             	sub    $0x8,%esp
f010118c:	8b 5d 10             	mov    0x10(%ebp),%ebx
	pte_t *pte = pgdir_walk(pgdir, va, 0);
f010118f:	6a 00                	push   $0x0
f0101191:	ff 75 0c             	pushl  0xc(%ebp)
f0101194:	ff 75 08             	pushl  0x8(%ebp)
f0101197:	e8 f2 fe ff ff       	call   f010108e <pgdir_walk>
	if(pte == NULL)
f010119c:	83 c4 10             	add    $0x10,%esp
f010119f:	85 c0                	test   %eax,%eax
f01011a1:	74 32                	je     f01011d5 <page_lookup+0x50>
		return NULL;
	else{
		if(pte_store!=NULL)		
f01011a3:	85 db                	test   %ebx,%ebx
f01011a5:	74 02                	je     f01011a9 <page_lookup+0x24>
			*pte_store = pte;
f01011a7:	89 03                	mov    %eax,(%ebx)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01011a9:	8b 00                	mov    (%eax),%eax
f01011ab:	c1 e8 0c             	shr    $0xc,%eax
f01011ae:	3b 05 a0 9e 2a f0    	cmp    0xf02a9ea0,%eax
f01011b4:	72 14                	jb     f01011ca <page_lookup+0x45>
		panic("pa2page called with invalid pa");
f01011b6:	83 ec 04             	sub    $0x4,%esp
f01011b9:	68 b0 6c 10 f0       	push   $0xf0106cb0
f01011be:	6a 51                	push   $0x51
f01011c0:	68 30 75 10 f0       	push   $0xf0107530
f01011c5:	e8 76 ee ff ff       	call   f0100040 <_panic>
	return &pages[PGNUM(pa)];
f01011ca:	8b 15 a8 9e 2a f0    	mov    0xf02a9ea8,%edx
f01011d0:	8d 04 c2             	lea    (%edx,%eax,8),%eax
		
		return pa2page(PTE_ADDR(*pte));
f01011d3:	eb 05                	jmp    f01011da <page_lookup+0x55>
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
	pte_t *pte = pgdir_walk(pgdir, va, 0);
	if(pte == NULL)
		return NULL;
f01011d5:	b8 00 00 00 00       	mov    $0x0,%eax
			*pte_store = pte;
		
		return pa2page(PTE_ADDR(*pte));
	}

}
f01011da:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01011dd:	c9                   	leave  
f01011de:	c3                   	ret    

f01011df <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f01011df:	55                   	push   %ebp
f01011e0:	89 e5                	mov    %esp,%ebp
f01011e2:	83 ec 08             	sub    $0x8,%esp
	// Flush the entry only if we're modifying the current address space.
	if (!curenv || curenv->env_pgdir == pgdir)
f01011e5:	e8 40 48 00 00       	call   f0105a2a <cpunum>
f01011ea:	6b c0 74             	imul   $0x74,%eax,%eax
f01011ed:	83 b8 28 a0 2a f0 00 	cmpl   $0x0,-0xfd55fd8(%eax)
f01011f4:	74 16                	je     f010120c <tlb_invalidate+0x2d>
f01011f6:	e8 2f 48 00 00       	call   f0105a2a <cpunum>
f01011fb:	6b c0 74             	imul   $0x74,%eax,%eax
f01011fe:	8b 80 28 a0 2a f0    	mov    -0xfd55fd8(%eax),%eax
f0101204:	8b 55 08             	mov    0x8(%ebp),%edx
f0101207:	39 50 60             	cmp    %edx,0x60(%eax)
f010120a:	75 06                	jne    f0101212 <tlb_invalidate+0x33>
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f010120c:	8b 45 0c             	mov    0xc(%ebp),%eax
f010120f:	0f 01 38             	invlpg (%eax)
		invlpg(va);
}
f0101212:	c9                   	leave  
f0101213:	c3                   	ret    

f0101214 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0101214:	55                   	push   %ebp
f0101215:	89 e5                	mov    %esp,%ebp
f0101217:	56                   	push   %esi
f0101218:	53                   	push   %ebx
f0101219:	83 ec 14             	sub    $0x14,%esp
f010121c:	8b 5d 08             	mov    0x8(%ebp),%ebx
f010121f:	8b 75 0c             	mov    0xc(%ebp),%esi
	// Fill this function in
	pte_t *pte;
	struct PageInfo *pp = page_lookup(pgdir, va, &pte);
f0101222:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101225:	50                   	push   %eax
f0101226:	56                   	push   %esi
f0101227:	53                   	push   %ebx
f0101228:	e8 58 ff ff ff       	call   f0101185 <page_lookup>
	if(pp!=NULL){
f010122d:	83 c4 10             	add    $0x10,%esp
f0101230:	85 c0                	test   %eax,%eax
f0101232:	74 1f                	je     f0101253 <page_remove+0x3f>
		page_decref(pp);
f0101234:	83 ec 0c             	sub    $0xc,%esp
f0101237:	50                   	push   %eax
f0101238:	e8 2a fe ff ff       	call   f0101067 <page_decref>
		*pte = 0;
f010123d:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101240:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		tlb_invalidate(pgdir, va);
f0101246:	83 c4 08             	add    $0x8,%esp
f0101249:	56                   	push   %esi
f010124a:	53                   	push   %ebx
f010124b:	e8 8f ff ff ff       	call   f01011df <tlb_invalidate>
f0101250:	83 c4 10             	add    $0x10,%esp
	}
}
f0101253:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0101256:	5b                   	pop    %ebx
f0101257:	5e                   	pop    %esi
f0101258:	5d                   	pop    %ebp
f0101259:	c3                   	ret    

f010125a <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f010125a:	55                   	push   %ebp
f010125b:	89 e5                	mov    %esp,%ebp
f010125d:	57                   	push   %edi
f010125e:	56                   	push   %esi
f010125f:	53                   	push   %ebx
f0101260:	83 ec 10             	sub    $0x10,%esp
f0101263:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101266:	8b 7d 10             	mov    0x10(%ebp),%edi
	pte_t *pte = pgdir_walk(pgdir, va, 1); 
f0101269:	6a 01                	push   $0x1
f010126b:	57                   	push   %edi
f010126c:	ff 75 08             	pushl  0x8(%ebp)
f010126f:	e8 1a fe ff ff       	call   f010108e <pgdir_walk>
	if(pte){
f0101274:	83 c4 10             	add    $0x10,%esp
f0101277:	85 c0                	test   %eax,%eax
f0101279:	74 4a                	je     f01012c5 <page_insert+0x6b>
f010127b:	89 c6                	mov    %eax,%esi
		pp->pp_ref ++;
f010127d:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
		if(PTE_ADDR(*pte))
f0101282:	f7 00 00 f0 ff ff    	testl  $0xfffff000,(%eax)
f0101288:	74 0f                	je     f0101299 <page_insert+0x3f>
			page_remove(pgdir, va);
f010128a:	83 ec 08             	sub    $0x8,%esp
f010128d:	57                   	push   %edi
f010128e:	ff 75 08             	pushl  0x8(%ebp)
f0101291:	e8 7e ff ff ff       	call   f0101214 <page_remove>
f0101296:	83 c4 10             	add    $0x10,%esp
		*pte = page2pa(pp) | perm |PTE_P;
f0101299:	2b 1d a8 9e 2a f0    	sub    0xf02a9ea8,%ebx
f010129f:	c1 fb 03             	sar    $0x3,%ebx
f01012a2:	c1 e3 0c             	shl    $0xc,%ebx
f01012a5:	8b 45 14             	mov    0x14(%ebp),%eax
f01012a8:	83 c8 01             	or     $0x1,%eax
f01012ab:	09 c3                	or     %eax,%ebx
f01012ad:	89 1e                	mov    %ebx,(%esi)
		tlb_invalidate(pgdir, va);
f01012af:	83 ec 08             	sub    $0x8,%esp
f01012b2:	57                   	push   %edi
f01012b3:	ff 75 08             	pushl  0x8(%ebp)
f01012b6:	e8 24 ff ff ff       	call   f01011df <tlb_invalidate>
		return 0;
f01012bb:	83 c4 10             	add    $0x10,%esp
f01012be:	b8 00 00 00 00       	mov    $0x0,%eax
f01012c3:	eb 05                	jmp    f01012ca <page_insert+0x70>
	}
	return -E_NO_MEM;
f01012c5:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	
}
f01012ca:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01012cd:	5b                   	pop    %ebx
f01012ce:	5e                   	pop    %esi
f01012cf:	5f                   	pop    %edi
f01012d0:	5d                   	pop    %ebp
f01012d1:	c3                   	ret    

f01012d2 <mmio_map_region>:
// location.  Return the base of the reserved region.  size does *not*
// have to be multiple of PGSIZE.
//
void *
mmio_map_region(physaddr_t pa, size_t size)
{
f01012d2:	55                   	push   %ebp
f01012d3:	89 e5                	mov    %esp,%ebp
f01012d5:	53                   	push   %ebx
f01012d6:	83 ec 04             	sub    $0x4,%esp
	// okay to simply panic if this happens).
	//
	// Hint: The staff solution uses boot_map_region.
	//
	// Your code here:
    size = ROUNDUP(size, PGSIZE);
f01012d9:	8b 45 0c             	mov    0xc(%ebp),%eax
f01012dc:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
f01012e2:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
    if(base + size > MMIOLIM){
f01012e8:	8b 15 00 23 12 f0    	mov    0xf0122300,%edx
f01012ee:	8d 04 13             	lea    (%ebx,%edx,1),%eax
f01012f1:	3d 00 00 c0 ef       	cmp    $0xefc00000,%eax
f01012f6:	76 17                	jbe    f010130f <mmio_map_region+0x3d>
        panic("mmio_map_region: reservation mem overflow");
f01012f8:	83 ec 04             	sub    $0x4,%esp
f01012fb:	68 d0 6c 10 f0       	push   $0xf0106cd0
f0101300:	68 62 02 00 00       	push   $0x262
f0101305:	68 15 75 10 f0       	push   $0xf0107515
f010130a:	e8 31 ed ff ff       	call   f0100040 <_panic>
    }
    boot_map_region(kern_pgdir, base, size, pa, PTE_W | PTE_PCD | PTE_P);
f010130f:	83 ec 08             	sub    $0x8,%esp
f0101312:	6a 13                	push   $0x13
f0101314:	ff 75 08             	pushl  0x8(%ebp)
f0101317:	89 d9                	mov    %ebx,%ecx
f0101319:	a1 a4 9e 2a f0       	mov    0xf02a9ea4,%eax
f010131e:	e8 00 fe ff ff       	call   f0101123 <boot_map_region>
    uintptr_t b = base;
f0101323:	a1 00 23 12 f0       	mov    0xf0122300,%eax
    base += size;
f0101328:	01 c3                	add    %eax,%ebx
f010132a:	89 1d 00 23 12 f0    	mov    %ebx,0xf0122300
    return (void *) b;
    //panic("mmio_map_region not implemented");
}
f0101330:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101333:	c9                   	leave  
f0101334:	c3                   	ret    

f0101335 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0101335:	55                   	push   %ebp
f0101336:	89 e5                	mov    %esp,%ebp
f0101338:	57                   	push   %edi
f0101339:	56                   	push   %esi
f010133a:	53                   	push   %ebx
f010133b:	83 ec 3c             	sub    $0x3c,%esp
{
	size_t basemem, extmem, ext16mem, totalmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	basemem = nvram_read(NVRAM_BASELO);
f010133e:	b8 15 00 00 00       	mov    $0x15,%eax
f0101343:	e8 52 f7 ff ff       	call   f0100a9a <nvram_read>
f0101348:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f010134a:	b8 17 00 00 00       	mov    $0x17,%eax
f010134f:	e8 46 f7 ff ff       	call   f0100a9a <nvram_read>
f0101354:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f0101356:	b8 34 00 00 00       	mov    $0x34,%eax
f010135b:	e8 3a f7 ff ff       	call   f0100a9a <nvram_read>
f0101360:	c1 e0 06             	shl    $0x6,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (ext16mem)
f0101363:	85 c0                	test   %eax,%eax
f0101365:	74 07                	je     f010136e <mem_init+0x39>
		totalmem = 16 * 1024 + ext16mem;
f0101367:	05 00 40 00 00       	add    $0x4000,%eax
f010136c:	eb 0b                	jmp    f0101379 <mem_init+0x44>
	else if (extmem)
		totalmem = 1 * 1024 + extmem;
f010136e:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f0101374:	85 f6                	test   %esi,%esi
f0101376:	0f 44 c3             	cmove  %ebx,%eax
	else
		totalmem = basemem;

	npages = totalmem / (PGSIZE / 1024);
f0101379:	89 c2                	mov    %eax,%edx
f010137b:	c1 ea 02             	shr    $0x2,%edx
f010137e:	89 15 a0 9e 2a f0    	mov    %edx,0xf02a9ea0
	npages_basemem = basemem / (PGSIZE / 1024);

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101384:	89 c2                	mov    %eax,%edx
f0101386:	29 da                	sub    %ebx,%edx
f0101388:	52                   	push   %edx
f0101389:	53                   	push   %ebx
f010138a:	50                   	push   %eax
f010138b:	68 fc 6c 10 f0       	push   $0xf0106cfc
f0101390:	e8 c8 22 00 00       	call   f010365d <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0101395:	b8 00 10 00 00       	mov    $0x1000,%eax
f010139a:	e8 88 f7 ff ff       	call   f0100b27 <boot_alloc>
f010139f:	a3 a4 9e 2a f0       	mov    %eax,0xf02a9ea4
	memset(kern_pgdir, 0, PGSIZE);
f01013a4:	83 c4 0c             	add    $0xc,%esp
f01013a7:	68 00 10 00 00       	push   $0x1000
f01013ac:	6a 00                	push   $0x0
f01013ae:	50                   	push   %eax
f01013af:	e8 55 40 00 00       	call   f0105409 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f01013b4:	a1 a4 9e 2a f0       	mov    0xf02a9ea4,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01013b9:	83 c4 10             	add    $0x10,%esp
f01013bc:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01013c1:	77 15                	ja     f01013d8 <mem_init+0xa3>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01013c3:	50                   	push   %eax
f01013c4:	68 68 66 10 f0       	push   $0xf0106668
f01013c9:	68 96 00 00 00       	push   $0x96
f01013ce:	68 15 75 10 f0       	push   $0xf0107515
f01013d3:	e8 68 ec ff ff       	call   f0100040 <_panic>
f01013d8:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01013de:	83 ca 05             	or     $0x5,%edx
f01013e1:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	pages = (struct PageInfo *) boot_alloc(npages * sizeof(struct PageInfo));
f01013e7:	a1 a0 9e 2a f0       	mov    0xf02a9ea0,%eax
f01013ec:	c1 e0 03             	shl    $0x3,%eax
f01013ef:	e8 33 f7 ff ff       	call   f0100b27 <boot_alloc>
f01013f4:	a3 a8 9e 2a f0       	mov    %eax,0xf02a9ea8
	memset(pages, 0, npages * sizeof(struct PageInfo));
f01013f9:	83 ec 04             	sub    $0x4,%esp
f01013fc:	8b 0d a0 9e 2a f0    	mov    0xf02a9ea0,%ecx
f0101402:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f0101409:	52                   	push   %edx
f010140a:	6a 00                	push   $0x0
f010140c:	50                   	push   %eax
f010140d:	e8 f7 3f 00 00       	call   f0105409 <memset>

	//////////////////////////////////////////////////////////////////////
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.
	envs = (struct Env *) boot_alloc(NENV * sizeof(struct Env));
f0101412:	b8 00 f0 01 00       	mov    $0x1f000,%eax
f0101417:	e8 0b f7 ff ff       	call   f0100b27 <boot_alloc>
f010141c:	a3 44 92 2a f0       	mov    %eax,0xf02a9244
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f0101421:	e8 8a fa ff ff       	call   f0100eb0 <page_init>

	check_page_free_list(1);
f0101426:	b8 01 00 00 00       	mov    $0x1,%eax
f010142b:	e8 7e f7 ff ff       	call   f0100bae <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f0101430:	83 c4 10             	add    $0x10,%esp
f0101433:	83 3d a8 9e 2a f0 00 	cmpl   $0x0,0xf02a9ea8
f010143a:	75 17                	jne    f0101453 <mem_init+0x11e>
		panic("'pages' is a null pointer!");
f010143c:	83 ec 04             	sub    $0x4,%esp
f010143f:	68 f7 75 10 f0       	push   $0xf01075f7
f0101444:	68 f9 02 00 00       	push   $0x2f9
f0101449:	68 15 75 10 f0       	push   $0xf0107515
f010144e:	e8 ed eb ff ff       	call   f0100040 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101453:	a1 40 92 2a f0       	mov    0xf02a9240,%eax
f0101458:	bb 00 00 00 00       	mov    $0x0,%ebx
f010145d:	eb 05                	jmp    f0101464 <mem_init+0x12f>
		++nfree;
f010145f:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101462:	8b 00                	mov    (%eax),%eax
f0101464:	85 c0                	test   %eax,%eax
f0101466:	75 f7                	jne    f010145f <mem_init+0x12a>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101468:	83 ec 0c             	sub    $0xc,%esp
f010146b:	6a 00                	push   $0x0
f010146d:	e8 43 fb ff ff       	call   f0100fb5 <page_alloc>
f0101472:	89 c7                	mov    %eax,%edi
f0101474:	83 c4 10             	add    $0x10,%esp
f0101477:	85 c0                	test   %eax,%eax
f0101479:	75 19                	jne    f0101494 <mem_init+0x15f>
f010147b:	68 12 76 10 f0       	push   $0xf0107612
f0101480:	68 4a 75 10 f0       	push   $0xf010754a
f0101485:	68 01 03 00 00       	push   $0x301
f010148a:	68 15 75 10 f0       	push   $0xf0107515
f010148f:	e8 ac eb ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0101494:	83 ec 0c             	sub    $0xc,%esp
f0101497:	6a 00                	push   $0x0
f0101499:	e8 17 fb ff ff       	call   f0100fb5 <page_alloc>
f010149e:	89 c6                	mov    %eax,%esi
f01014a0:	83 c4 10             	add    $0x10,%esp
f01014a3:	85 c0                	test   %eax,%eax
f01014a5:	75 19                	jne    f01014c0 <mem_init+0x18b>
f01014a7:	68 28 76 10 f0       	push   $0xf0107628
f01014ac:	68 4a 75 10 f0       	push   $0xf010754a
f01014b1:	68 02 03 00 00       	push   $0x302
f01014b6:	68 15 75 10 f0       	push   $0xf0107515
f01014bb:	e8 80 eb ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f01014c0:	83 ec 0c             	sub    $0xc,%esp
f01014c3:	6a 00                	push   $0x0
f01014c5:	e8 eb fa ff ff       	call   f0100fb5 <page_alloc>
f01014ca:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01014cd:	83 c4 10             	add    $0x10,%esp
f01014d0:	85 c0                	test   %eax,%eax
f01014d2:	75 19                	jne    f01014ed <mem_init+0x1b8>
f01014d4:	68 3e 76 10 f0       	push   $0xf010763e
f01014d9:	68 4a 75 10 f0       	push   $0xf010754a
f01014de:	68 03 03 00 00       	push   $0x303
f01014e3:	68 15 75 10 f0       	push   $0xf0107515
f01014e8:	e8 53 eb ff ff       	call   f0100040 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01014ed:	39 f7                	cmp    %esi,%edi
f01014ef:	75 19                	jne    f010150a <mem_init+0x1d5>
f01014f1:	68 54 76 10 f0       	push   $0xf0107654
f01014f6:	68 4a 75 10 f0       	push   $0xf010754a
f01014fb:	68 06 03 00 00       	push   $0x306
f0101500:	68 15 75 10 f0       	push   $0xf0107515
f0101505:	e8 36 eb ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010150a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010150d:	39 c6                	cmp    %eax,%esi
f010150f:	74 04                	je     f0101515 <mem_init+0x1e0>
f0101511:	39 c7                	cmp    %eax,%edi
f0101513:	75 19                	jne    f010152e <mem_init+0x1f9>
f0101515:	68 38 6d 10 f0       	push   $0xf0106d38
f010151a:	68 4a 75 10 f0       	push   $0xf010754a
f010151f:	68 07 03 00 00       	push   $0x307
f0101524:	68 15 75 10 f0       	push   $0xf0107515
f0101529:	e8 12 eb ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010152e:	8b 0d a8 9e 2a f0    	mov    0xf02a9ea8,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101534:	8b 15 a0 9e 2a f0    	mov    0xf02a9ea0,%edx
f010153a:	c1 e2 0c             	shl    $0xc,%edx
f010153d:	89 f8                	mov    %edi,%eax
f010153f:	29 c8                	sub    %ecx,%eax
f0101541:	c1 f8 03             	sar    $0x3,%eax
f0101544:	c1 e0 0c             	shl    $0xc,%eax
f0101547:	39 d0                	cmp    %edx,%eax
f0101549:	72 19                	jb     f0101564 <mem_init+0x22f>
f010154b:	68 66 76 10 f0       	push   $0xf0107666
f0101550:	68 4a 75 10 f0       	push   $0xf010754a
f0101555:	68 08 03 00 00       	push   $0x308
f010155a:	68 15 75 10 f0       	push   $0xf0107515
f010155f:	e8 dc ea ff ff       	call   f0100040 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f0101564:	89 f0                	mov    %esi,%eax
f0101566:	29 c8                	sub    %ecx,%eax
f0101568:	c1 f8 03             	sar    $0x3,%eax
f010156b:	c1 e0 0c             	shl    $0xc,%eax
f010156e:	39 c2                	cmp    %eax,%edx
f0101570:	77 19                	ja     f010158b <mem_init+0x256>
f0101572:	68 83 76 10 f0       	push   $0xf0107683
f0101577:	68 4a 75 10 f0       	push   $0xf010754a
f010157c:	68 09 03 00 00       	push   $0x309
f0101581:	68 15 75 10 f0       	push   $0xf0107515
f0101586:	e8 b5 ea ff ff       	call   f0100040 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f010158b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010158e:	29 c8                	sub    %ecx,%eax
f0101590:	c1 f8 03             	sar    $0x3,%eax
f0101593:	c1 e0 0c             	shl    $0xc,%eax
f0101596:	39 c2                	cmp    %eax,%edx
f0101598:	77 19                	ja     f01015b3 <mem_init+0x27e>
f010159a:	68 a0 76 10 f0       	push   $0xf01076a0
f010159f:	68 4a 75 10 f0       	push   $0xf010754a
f01015a4:	68 0a 03 00 00       	push   $0x30a
f01015a9:	68 15 75 10 f0       	push   $0xf0107515
f01015ae:	e8 8d ea ff ff       	call   f0100040 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01015b3:	a1 40 92 2a f0       	mov    0xf02a9240,%eax
f01015b8:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01015bb:	c7 05 40 92 2a f0 00 	movl   $0x0,0xf02a9240
f01015c2:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01015c5:	83 ec 0c             	sub    $0xc,%esp
f01015c8:	6a 00                	push   $0x0
f01015ca:	e8 e6 f9 ff ff       	call   f0100fb5 <page_alloc>
f01015cf:	83 c4 10             	add    $0x10,%esp
f01015d2:	85 c0                	test   %eax,%eax
f01015d4:	74 19                	je     f01015ef <mem_init+0x2ba>
f01015d6:	68 bd 76 10 f0       	push   $0xf01076bd
f01015db:	68 4a 75 10 f0       	push   $0xf010754a
f01015e0:	68 11 03 00 00       	push   $0x311
f01015e5:	68 15 75 10 f0       	push   $0xf0107515
f01015ea:	e8 51 ea ff ff       	call   f0100040 <_panic>

	// free and re-allocate?
	page_free(pp0);
f01015ef:	83 ec 0c             	sub    $0xc,%esp
f01015f2:	57                   	push   %edi
f01015f3:	e8 34 fa ff ff       	call   f010102c <page_free>
	page_free(pp1);
f01015f8:	89 34 24             	mov    %esi,(%esp)
f01015fb:	e8 2c fa ff ff       	call   f010102c <page_free>
	page_free(pp2);
f0101600:	83 c4 04             	add    $0x4,%esp
f0101603:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101606:	e8 21 fa ff ff       	call   f010102c <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010160b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101612:	e8 9e f9 ff ff       	call   f0100fb5 <page_alloc>
f0101617:	89 c6                	mov    %eax,%esi
f0101619:	83 c4 10             	add    $0x10,%esp
f010161c:	85 c0                	test   %eax,%eax
f010161e:	75 19                	jne    f0101639 <mem_init+0x304>
f0101620:	68 12 76 10 f0       	push   $0xf0107612
f0101625:	68 4a 75 10 f0       	push   $0xf010754a
f010162a:	68 18 03 00 00       	push   $0x318
f010162f:	68 15 75 10 f0       	push   $0xf0107515
f0101634:	e8 07 ea ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0101639:	83 ec 0c             	sub    $0xc,%esp
f010163c:	6a 00                	push   $0x0
f010163e:	e8 72 f9 ff ff       	call   f0100fb5 <page_alloc>
f0101643:	89 c7                	mov    %eax,%edi
f0101645:	83 c4 10             	add    $0x10,%esp
f0101648:	85 c0                	test   %eax,%eax
f010164a:	75 19                	jne    f0101665 <mem_init+0x330>
f010164c:	68 28 76 10 f0       	push   $0xf0107628
f0101651:	68 4a 75 10 f0       	push   $0xf010754a
f0101656:	68 19 03 00 00       	push   $0x319
f010165b:	68 15 75 10 f0       	push   $0xf0107515
f0101660:	e8 db e9 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0101665:	83 ec 0c             	sub    $0xc,%esp
f0101668:	6a 00                	push   $0x0
f010166a:	e8 46 f9 ff ff       	call   f0100fb5 <page_alloc>
f010166f:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101672:	83 c4 10             	add    $0x10,%esp
f0101675:	85 c0                	test   %eax,%eax
f0101677:	75 19                	jne    f0101692 <mem_init+0x35d>
f0101679:	68 3e 76 10 f0       	push   $0xf010763e
f010167e:	68 4a 75 10 f0       	push   $0xf010754a
f0101683:	68 1a 03 00 00       	push   $0x31a
f0101688:	68 15 75 10 f0       	push   $0xf0107515
f010168d:	e8 ae e9 ff ff       	call   f0100040 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101692:	39 fe                	cmp    %edi,%esi
f0101694:	75 19                	jne    f01016af <mem_init+0x37a>
f0101696:	68 54 76 10 f0       	push   $0xf0107654
f010169b:	68 4a 75 10 f0       	push   $0xf010754a
f01016a0:	68 1c 03 00 00       	push   $0x31c
f01016a5:	68 15 75 10 f0       	push   $0xf0107515
f01016aa:	e8 91 e9 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01016af:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01016b2:	39 c7                	cmp    %eax,%edi
f01016b4:	74 04                	je     f01016ba <mem_init+0x385>
f01016b6:	39 c6                	cmp    %eax,%esi
f01016b8:	75 19                	jne    f01016d3 <mem_init+0x39e>
f01016ba:	68 38 6d 10 f0       	push   $0xf0106d38
f01016bf:	68 4a 75 10 f0       	push   $0xf010754a
f01016c4:	68 1d 03 00 00       	push   $0x31d
f01016c9:	68 15 75 10 f0       	push   $0xf0107515
f01016ce:	e8 6d e9 ff ff       	call   f0100040 <_panic>
	assert(!page_alloc(0));
f01016d3:	83 ec 0c             	sub    $0xc,%esp
f01016d6:	6a 00                	push   $0x0
f01016d8:	e8 d8 f8 ff ff       	call   f0100fb5 <page_alloc>
f01016dd:	83 c4 10             	add    $0x10,%esp
f01016e0:	85 c0                	test   %eax,%eax
f01016e2:	74 19                	je     f01016fd <mem_init+0x3c8>
f01016e4:	68 bd 76 10 f0       	push   $0xf01076bd
f01016e9:	68 4a 75 10 f0       	push   $0xf010754a
f01016ee:	68 1e 03 00 00       	push   $0x31e
f01016f3:	68 15 75 10 f0       	push   $0xf0107515
f01016f8:	e8 43 e9 ff ff       	call   f0100040 <_panic>
f01016fd:	89 f0                	mov    %esi,%eax
f01016ff:	2b 05 a8 9e 2a f0    	sub    0xf02a9ea8,%eax
f0101705:	c1 f8 03             	sar    $0x3,%eax
f0101708:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010170b:	89 c2                	mov    %eax,%edx
f010170d:	c1 ea 0c             	shr    $0xc,%edx
f0101710:	3b 15 a0 9e 2a f0    	cmp    0xf02a9ea0,%edx
f0101716:	72 12                	jb     f010172a <mem_init+0x3f5>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101718:	50                   	push   %eax
f0101719:	68 44 66 10 f0       	push   $0xf0106644
f010171e:	6a 58                	push   $0x58
f0101720:	68 30 75 10 f0       	push   $0xf0107530
f0101725:	e8 16 e9 ff ff       	call   f0100040 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f010172a:	83 ec 04             	sub    $0x4,%esp
f010172d:	68 00 10 00 00       	push   $0x1000
f0101732:	6a 01                	push   $0x1
f0101734:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101739:	50                   	push   %eax
f010173a:	e8 ca 3c 00 00       	call   f0105409 <memset>
	page_free(pp0);
f010173f:	89 34 24             	mov    %esi,(%esp)
f0101742:	e8 e5 f8 ff ff       	call   f010102c <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101747:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f010174e:	e8 62 f8 ff ff       	call   f0100fb5 <page_alloc>
f0101753:	83 c4 10             	add    $0x10,%esp
f0101756:	85 c0                	test   %eax,%eax
f0101758:	75 19                	jne    f0101773 <mem_init+0x43e>
f010175a:	68 cc 76 10 f0       	push   $0xf01076cc
f010175f:	68 4a 75 10 f0       	push   $0xf010754a
f0101764:	68 23 03 00 00       	push   $0x323
f0101769:	68 15 75 10 f0       	push   $0xf0107515
f010176e:	e8 cd e8 ff ff       	call   f0100040 <_panic>
	assert(pp && pp0 == pp);
f0101773:	39 c6                	cmp    %eax,%esi
f0101775:	74 19                	je     f0101790 <mem_init+0x45b>
f0101777:	68 ea 76 10 f0       	push   $0xf01076ea
f010177c:	68 4a 75 10 f0       	push   $0xf010754a
f0101781:	68 24 03 00 00       	push   $0x324
f0101786:	68 15 75 10 f0       	push   $0xf0107515
f010178b:	e8 b0 e8 ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101790:	89 f0                	mov    %esi,%eax
f0101792:	2b 05 a8 9e 2a f0    	sub    0xf02a9ea8,%eax
f0101798:	c1 f8 03             	sar    $0x3,%eax
f010179b:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010179e:	89 c2                	mov    %eax,%edx
f01017a0:	c1 ea 0c             	shr    $0xc,%edx
f01017a3:	3b 15 a0 9e 2a f0    	cmp    0xf02a9ea0,%edx
f01017a9:	72 12                	jb     f01017bd <mem_init+0x488>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01017ab:	50                   	push   %eax
f01017ac:	68 44 66 10 f0       	push   $0xf0106644
f01017b1:	6a 58                	push   $0x58
f01017b3:	68 30 75 10 f0       	push   $0xf0107530
f01017b8:	e8 83 e8 ff ff       	call   f0100040 <_panic>
f01017bd:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f01017c3:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f01017c9:	80 38 00             	cmpb   $0x0,(%eax)
f01017cc:	74 19                	je     f01017e7 <mem_init+0x4b2>
f01017ce:	68 fa 76 10 f0       	push   $0xf01076fa
f01017d3:	68 4a 75 10 f0       	push   $0xf010754a
f01017d8:	68 27 03 00 00       	push   $0x327
f01017dd:	68 15 75 10 f0       	push   $0xf0107515
f01017e2:	e8 59 e8 ff ff       	call   f0100040 <_panic>
f01017e7:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f01017ea:	39 d0                	cmp    %edx,%eax
f01017ec:	75 db                	jne    f01017c9 <mem_init+0x494>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f01017ee:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01017f1:	a3 40 92 2a f0       	mov    %eax,0xf02a9240

	// free the pages we took
	page_free(pp0);
f01017f6:	83 ec 0c             	sub    $0xc,%esp
f01017f9:	56                   	push   %esi
f01017fa:	e8 2d f8 ff ff       	call   f010102c <page_free>
	page_free(pp1);
f01017ff:	89 3c 24             	mov    %edi,(%esp)
f0101802:	e8 25 f8 ff ff       	call   f010102c <page_free>
	page_free(pp2);
f0101807:	83 c4 04             	add    $0x4,%esp
f010180a:	ff 75 d4             	pushl  -0x2c(%ebp)
f010180d:	e8 1a f8 ff ff       	call   f010102c <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101812:	a1 40 92 2a f0       	mov    0xf02a9240,%eax
f0101817:	83 c4 10             	add    $0x10,%esp
f010181a:	eb 05                	jmp    f0101821 <mem_init+0x4ec>
		--nfree;
f010181c:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010181f:	8b 00                	mov    (%eax),%eax
f0101821:	85 c0                	test   %eax,%eax
f0101823:	75 f7                	jne    f010181c <mem_init+0x4e7>
		--nfree;
	assert(nfree == 0);
f0101825:	85 db                	test   %ebx,%ebx
f0101827:	74 19                	je     f0101842 <mem_init+0x50d>
f0101829:	68 04 77 10 f0       	push   $0xf0107704
f010182e:	68 4a 75 10 f0       	push   $0xf010754a
f0101833:	68 34 03 00 00       	push   $0x334
f0101838:	68 15 75 10 f0       	push   $0xf0107515
f010183d:	e8 fe e7 ff ff       	call   f0100040 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f0101842:	83 ec 0c             	sub    $0xc,%esp
f0101845:	68 58 6d 10 f0       	push   $0xf0106d58
f010184a:	e8 0e 1e 00 00       	call   f010365d <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010184f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101856:	e8 5a f7 ff ff       	call   f0100fb5 <page_alloc>
f010185b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010185e:	83 c4 10             	add    $0x10,%esp
f0101861:	85 c0                	test   %eax,%eax
f0101863:	75 19                	jne    f010187e <mem_init+0x549>
f0101865:	68 12 76 10 f0       	push   $0xf0107612
f010186a:	68 4a 75 10 f0       	push   $0xf010754a
f010186f:	68 9a 03 00 00       	push   $0x39a
f0101874:	68 15 75 10 f0       	push   $0xf0107515
f0101879:	e8 c2 e7 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f010187e:	83 ec 0c             	sub    $0xc,%esp
f0101881:	6a 00                	push   $0x0
f0101883:	e8 2d f7 ff ff       	call   f0100fb5 <page_alloc>
f0101888:	89 c3                	mov    %eax,%ebx
f010188a:	83 c4 10             	add    $0x10,%esp
f010188d:	85 c0                	test   %eax,%eax
f010188f:	75 19                	jne    f01018aa <mem_init+0x575>
f0101891:	68 28 76 10 f0       	push   $0xf0107628
f0101896:	68 4a 75 10 f0       	push   $0xf010754a
f010189b:	68 9b 03 00 00       	push   $0x39b
f01018a0:	68 15 75 10 f0       	push   $0xf0107515
f01018a5:	e8 96 e7 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f01018aa:	83 ec 0c             	sub    $0xc,%esp
f01018ad:	6a 00                	push   $0x0
f01018af:	e8 01 f7 ff ff       	call   f0100fb5 <page_alloc>
f01018b4:	89 c6                	mov    %eax,%esi
f01018b6:	83 c4 10             	add    $0x10,%esp
f01018b9:	85 c0                	test   %eax,%eax
f01018bb:	75 19                	jne    f01018d6 <mem_init+0x5a1>
f01018bd:	68 3e 76 10 f0       	push   $0xf010763e
f01018c2:	68 4a 75 10 f0       	push   $0xf010754a
f01018c7:	68 9c 03 00 00       	push   $0x39c
f01018cc:	68 15 75 10 f0       	push   $0xf0107515
f01018d1:	e8 6a e7 ff ff       	call   f0100040 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01018d6:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f01018d9:	75 19                	jne    f01018f4 <mem_init+0x5bf>
f01018db:	68 54 76 10 f0       	push   $0xf0107654
f01018e0:	68 4a 75 10 f0       	push   $0xf010754a
f01018e5:	68 9f 03 00 00       	push   $0x39f
f01018ea:	68 15 75 10 f0       	push   $0xf0107515
f01018ef:	e8 4c e7 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01018f4:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f01018f7:	74 04                	je     f01018fd <mem_init+0x5c8>
f01018f9:	39 c3                	cmp    %eax,%ebx
f01018fb:	75 19                	jne    f0101916 <mem_init+0x5e1>
f01018fd:	68 38 6d 10 f0       	push   $0xf0106d38
f0101902:	68 4a 75 10 f0       	push   $0xf010754a
f0101907:	68 a0 03 00 00       	push   $0x3a0
f010190c:	68 15 75 10 f0       	push   $0xf0107515
f0101911:	e8 2a e7 ff ff       	call   f0100040 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101916:	a1 40 92 2a f0       	mov    0xf02a9240,%eax
f010191b:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f010191e:	c7 05 40 92 2a f0 00 	movl   $0x0,0xf02a9240
f0101925:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101928:	83 ec 0c             	sub    $0xc,%esp
f010192b:	6a 00                	push   $0x0
f010192d:	e8 83 f6 ff ff       	call   f0100fb5 <page_alloc>
f0101932:	83 c4 10             	add    $0x10,%esp
f0101935:	85 c0                	test   %eax,%eax
f0101937:	74 19                	je     f0101952 <mem_init+0x61d>
f0101939:	68 bd 76 10 f0       	push   $0xf01076bd
f010193e:	68 4a 75 10 f0       	push   $0xf010754a
f0101943:	68 a7 03 00 00       	push   $0x3a7
f0101948:	68 15 75 10 f0       	push   $0xf0107515
f010194d:	e8 ee e6 ff ff       	call   f0100040 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101952:	83 ec 04             	sub    $0x4,%esp
f0101955:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101958:	50                   	push   %eax
f0101959:	6a 00                	push   $0x0
f010195b:	ff 35 a4 9e 2a f0    	pushl  0xf02a9ea4
f0101961:	e8 1f f8 ff ff       	call   f0101185 <page_lookup>
f0101966:	83 c4 10             	add    $0x10,%esp
f0101969:	85 c0                	test   %eax,%eax
f010196b:	74 19                	je     f0101986 <mem_init+0x651>
f010196d:	68 78 6d 10 f0       	push   $0xf0106d78
f0101972:	68 4a 75 10 f0       	push   $0xf010754a
f0101977:	68 aa 03 00 00       	push   $0x3aa
f010197c:	68 15 75 10 f0       	push   $0xf0107515
f0101981:	e8 ba e6 ff ff       	call   f0100040 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101986:	6a 02                	push   $0x2
f0101988:	6a 00                	push   $0x0
f010198a:	53                   	push   %ebx
f010198b:	ff 35 a4 9e 2a f0    	pushl  0xf02a9ea4
f0101991:	e8 c4 f8 ff ff       	call   f010125a <page_insert>
f0101996:	83 c4 10             	add    $0x10,%esp
f0101999:	85 c0                	test   %eax,%eax
f010199b:	78 19                	js     f01019b6 <mem_init+0x681>
f010199d:	68 b0 6d 10 f0       	push   $0xf0106db0
f01019a2:	68 4a 75 10 f0       	push   $0xf010754a
f01019a7:	68 ad 03 00 00       	push   $0x3ad
f01019ac:	68 15 75 10 f0       	push   $0xf0107515
f01019b1:	e8 8a e6 ff ff       	call   f0100040 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f01019b6:	83 ec 0c             	sub    $0xc,%esp
f01019b9:	ff 75 d4             	pushl  -0x2c(%ebp)
f01019bc:	e8 6b f6 ff ff       	call   f010102c <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f01019c1:	6a 02                	push   $0x2
f01019c3:	6a 00                	push   $0x0
f01019c5:	53                   	push   %ebx
f01019c6:	ff 35 a4 9e 2a f0    	pushl  0xf02a9ea4
f01019cc:	e8 89 f8 ff ff       	call   f010125a <page_insert>
f01019d1:	83 c4 20             	add    $0x20,%esp
f01019d4:	85 c0                	test   %eax,%eax
f01019d6:	74 19                	je     f01019f1 <mem_init+0x6bc>
f01019d8:	68 e0 6d 10 f0       	push   $0xf0106de0
f01019dd:	68 4a 75 10 f0       	push   $0xf010754a
f01019e2:	68 b1 03 00 00       	push   $0x3b1
f01019e7:	68 15 75 10 f0       	push   $0xf0107515
f01019ec:	e8 4f e6 ff ff       	call   f0100040 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01019f1:	8b 3d a4 9e 2a f0    	mov    0xf02a9ea4,%edi
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01019f7:	a1 a8 9e 2a f0       	mov    0xf02a9ea8,%eax
f01019fc:	89 c1                	mov    %eax,%ecx
f01019fe:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101a01:	8b 17                	mov    (%edi),%edx
f0101a03:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101a09:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a0c:	29 c8                	sub    %ecx,%eax
f0101a0e:	c1 f8 03             	sar    $0x3,%eax
f0101a11:	c1 e0 0c             	shl    $0xc,%eax
f0101a14:	39 c2                	cmp    %eax,%edx
f0101a16:	74 19                	je     f0101a31 <mem_init+0x6fc>
f0101a18:	68 10 6e 10 f0       	push   $0xf0106e10
f0101a1d:	68 4a 75 10 f0       	push   $0xf010754a
f0101a22:	68 b2 03 00 00       	push   $0x3b2
f0101a27:	68 15 75 10 f0       	push   $0xf0107515
f0101a2c:	e8 0f e6 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101a31:	ba 00 00 00 00       	mov    $0x0,%edx
f0101a36:	89 f8                	mov    %edi,%eax
f0101a38:	e8 86 f0 ff ff       	call   f0100ac3 <check_va2pa>
f0101a3d:	89 da                	mov    %ebx,%edx
f0101a3f:	2b 55 cc             	sub    -0x34(%ebp),%edx
f0101a42:	c1 fa 03             	sar    $0x3,%edx
f0101a45:	c1 e2 0c             	shl    $0xc,%edx
f0101a48:	39 d0                	cmp    %edx,%eax
f0101a4a:	74 19                	je     f0101a65 <mem_init+0x730>
f0101a4c:	68 38 6e 10 f0       	push   $0xf0106e38
f0101a51:	68 4a 75 10 f0       	push   $0xf010754a
f0101a56:	68 b3 03 00 00       	push   $0x3b3
f0101a5b:	68 15 75 10 f0       	push   $0xf0107515
f0101a60:	e8 db e5 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f0101a65:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101a6a:	74 19                	je     f0101a85 <mem_init+0x750>
f0101a6c:	68 0f 77 10 f0       	push   $0xf010770f
f0101a71:	68 4a 75 10 f0       	push   $0xf010754a
f0101a76:	68 b4 03 00 00       	push   $0x3b4
f0101a7b:	68 15 75 10 f0       	push   $0xf0107515
f0101a80:	e8 bb e5 ff ff       	call   f0100040 <_panic>
	assert(pp0->pp_ref == 1);
f0101a85:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a88:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101a8d:	74 19                	je     f0101aa8 <mem_init+0x773>
f0101a8f:	68 20 77 10 f0       	push   $0xf0107720
f0101a94:	68 4a 75 10 f0       	push   $0xf010754a
f0101a99:	68 b5 03 00 00       	push   $0x3b5
f0101a9e:	68 15 75 10 f0       	push   $0xf0107515
f0101aa3:	e8 98 e5 ff ff       	call   f0100040 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101aa8:	6a 02                	push   $0x2
f0101aaa:	68 00 10 00 00       	push   $0x1000
f0101aaf:	56                   	push   %esi
f0101ab0:	57                   	push   %edi
f0101ab1:	e8 a4 f7 ff ff       	call   f010125a <page_insert>
f0101ab6:	83 c4 10             	add    $0x10,%esp
f0101ab9:	85 c0                	test   %eax,%eax
f0101abb:	74 19                	je     f0101ad6 <mem_init+0x7a1>
f0101abd:	68 68 6e 10 f0       	push   $0xf0106e68
f0101ac2:	68 4a 75 10 f0       	push   $0xf010754a
f0101ac7:	68 b8 03 00 00       	push   $0x3b8
f0101acc:	68 15 75 10 f0       	push   $0xf0107515
f0101ad1:	e8 6a e5 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101ad6:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101adb:	a1 a4 9e 2a f0       	mov    0xf02a9ea4,%eax
f0101ae0:	e8 de ef ff ff       	call   f0100ac3 <check_va2pa>
f0101ae5:	89 f2                	mov    %esi,%edx
f0101ae7:	2b 15 a8 9e 2a f0    	sub    0xf02a9ea8,%edx
f0101aed:	c1 fa 03             	sar    $0x3,%edx
f0101af0:	c1 e2 0c             	shl    $0xc,%edx
f0101af3:	39 d0                	cmp    %edx,%eax
f0101af5:	74 19                	je     f0101b10 <mem_init+0x7db>
f0101af7:	68 a4 6e 10 f0       	push   $0xf0106ea4
f0101afc:	68 4a 75 10 f0       	push   $0xf010754a
f0101b01:	68 b9 03 00 00       	push   $0x3b9
f0101b06:	68 15 75 10 f0       	push   $0xf0107515
f0101b0b:	e8 30 e5 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101b10:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101b15:	74 19                	je     f0101b30 <mem_init+0x7fb>
f0101b17:	68 31 77 10 f0       	push   $0xf0107731
f0101b1c:	68 4a 75 10 f0       	push   $0xf010754a
f0101b21:	68 ba 03 00 00       	push   $0x3ba
f0101b26:	68 15 75 10 f0       	push   $0xf0107515
f0101b2b:	e8 10 e5 ff ff       	call   f0100040 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101b30:	83 ec 0c             	sub    $0xc,%esp
f0101b33:	6a 00                	push   $0x0
f0101b35:	e8 7b f4 ff ff       	call   f0100fb5 <page_alloc>
f0101b3a:	83 c4 10             	add    $0x10,%esp
f0101b3d:	85 c0                	test   %eax,%eax
f0101b3f:	74 19                	je     f0101b5a <mem_init+0x825>
f0101b41:	68 bd 76 10 f0       	push   $0xf01076bd
f0101b46:	68 4a 75 10 f0       	push   $0xf010754a
f0101b4b:	68 bd 03 00 00       	push   $0x3bd
f0101b50:	68 15 75 10 f0       	push   $0xf0107515
f0101b55:	e8 e6 e4 ff ff       	call   f0100040 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101b5a:	6a 02                	push   $0x2
f0101b5c:	68 00 10 00 00       	push   $0x1000
f0101b61:	56                   	push   %esi
f0101b62:	ff 35 a4 9e 2a f0    	pushl  0xf02a9ea4
f0101b68:	e8 ed f6 ff ff       	call   f010125a <page_insert>
f0101b6d:	83 c4 10             	add    $0x10,%esp
f0101b70:	85 c0                	test   %eax,%eax
f0101b72:	74 19                	je     f0101b8d <mem_init+0x858>
f0101b74:	68 68 6e 10 f0       	push   $0xf0106e68
f0101b79:	68 4a 75 10 f0       	push   $0xf010754a
f0101b7e:	68 c0 03 00 00       	push   $0x3c0
f0101b83:	68 15 75 10 f0       	push   $0xf0107515
f0101b88:	e8 b3 e4 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101b8d:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101b92:	a1 a4 9e 2a f0       	mov    0xf02a9ea4,%eax
f0101b97:	e8 27 ef ff ff       	call   f0100ac3 <check_va2pa>
f0101b9c:	89 f2                	mov    %esi,%edx
f0101b9e:	2b 15 a8 9e 2a f0    	sub    0xf02a9ea8,%edx
f0101ba4:	c1 fa 03             	sar    $0x3,%edx
f0101ba7:	c1 e2 0c             	shl    $0xc,%edx
f0101baa:	39 d0                	cmp    %edx,%eax
f0101bac:	74 19                	je     f0101bc7 <mem_init+0x892>
f0101bae:	68 a4 6e 10 f0       	push   $0xf0106ea4
f0101bb3:	68 4a 75 10 f0       	push   $0xf010754a
f0101bb8:	68 c1 03 00 00       	push   $0x3c1
f0101bbd:	68 15 75 10 f0       	push   $0xf0107515
f0101bc2:	e8 79 e4 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101bc7:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101bcc:	74 19                	je     f0101be7 <mem_init+0x8b2>
f0101bce:	68 31 77 10 f0       	push   $0xf0107731
f0101bd3:	68 4a 75 10 f0       	push   $0xf010754a
f0101bd8:	68 c2 03 00 00       	push   $0x3c2
f0101bdd:	68 15 75 10 f0       	push   $0xf0107515
f0101be2:	e8 59 e4 ff ff       	call   f0100040 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101be7:	83 ec 0c             	sub    $0xc,%esp
f0101bea:	6a 00                	push   $0x0
f0101bec:	e8 c4 f3 ff ff       	call   f0100fb5 <page_alloc>
f0101bf1:	83 c4 10             	add    $0x10,%esp
f0101bf4:	85 c0                	test   %eax,%eax
f0101bf6:	74 19                	je     f0101c11 <mem_init+0x8dc>
f0101bf8:	68 bd 76 10 f0       	push   $0xf01076bd
f0101bfd:	68 4a 75 10 f0       	push   $0xf010754a
f0101c02:	68 c6 03 00 00       	push   $0x3c6
f0101c07:	68 15 75 10 f0       	push   $0xf0107515
f0101c0c:	e8 2f e4 ff ff       	call   f0100040 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101c11:	8b 15 a4 9e 2a f0    	mov    0xf02a9ea4,%edx
f0101c17:	8b 02                	mov    (%edx),%eax
f0101c19:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101c1e:	89 c1                	mov    %eax,%ecx
f0101c20:	c1 e9 0c             	shr    $0xc,%ecx
f0101c23:	3b 0d a0 9e 2a f0    	cmp    0xf02a9ea0,%ecx
f0101c29:	72 15                	jb     f0101c40 <mem_init+0x90b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101c2b:	50                   	push   %eax
f0101c2c:	68 44 66 10 f0       	push   $0xf0106644
f0101c31:	68 c9 03 00 00       	push   $0x3c9
f0101c36:	68 15 75 10 f0       	push   $0xf0107515
f0101c3b:	e8 00 e4 ff ff       	call   f0100040 <_panic>
f0101c40:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101c45:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101c48:	83 ec 04             	sub    $0x4,%esp
f0101c4b:	6a 00                	push   $0x0
f0101c4d:	68 00 10 00 00       	push   $0x1000
f0101c52:	52                   	push   %edx
f0101c53:	e8 36 f4 ff ff       	call   f010108e <pgdir_walk>
f0101c58:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101c5b:	8d 51 04             	lea    0x4(%ecx),%edx
f0101c5e:	83 c4 10             	add    $0x10,%esp
f0101c61:	39 d0                	cmp    %edx,%eax
f0101c63:	74 19                	je     f0101c7e <mem_init+0x949>
f0101c65:	68 d4 6e 10 f0       	push   $0xf0106ed4
f0101c6a:	68 4a 75 10 f0       	push   $0xf010754a
f0101c6f:	68 ca 03 00 00       	push   $0x3ca
f0101c74:	68 15 75 10 f0       	push   $0xf0107515
f0101c79:	e8 c2 e3 ff ff       	call   f0100040 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101c7e:	6a 06                	push   $0x6
f0101c80:	68 00 10 00 00       	push   $0x1000
f0101c85:	56                   	push   %esi
f0101c86:	ff 35 a4 9e 2a f0    	pushl  0xf02a9ea4
f0101c8c:	e8 c9 f5 ff ff       	call   f010125a <page_insert>
f0101c91:	83 c4 10             	add    $0x10,%esp
f0101c94:	85 c0                	test   %eax,%eax
f0101c96:	74 19                	je     f0101cb1 <mem_init+0x97c>
f0101c98:	68 14 6f 10 f0       	push   $0xf0106f14
f0101c9d:	68 4a 75 10 f0       	push   $0xf010754a
f0101ca2:	68 cd 03 00 00       	push   $0x3cd
f0101ca7:	68 15 75 10 f0       	push   $0xf0107515
f0101cac:	e8 8f e3 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101cb1:	8b 3d a4 9e 2a f0    	mov    0xf02a9ea4,%edi
f0101cb7:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101cbc:	89 f8                	mov    %edi,%eax
f0101cbe:	e8 00 ee ff ff       	call   f0100ac3 <check_va2pa>
f0101cc3:	89 f2                	mov    %esi,%edx
f0101cc5:	2b 15 a8 9e 2a f0    	sub    0xf02a9ea8,%edx
f0101ccb:	c1 fa 03             	sar    $0x3,%edx
f0101cce:	c1 e2 0c             	shl    $0xc,%edx
f0101cd1:	39 d0                	cmp    %edx,%eax
f0101cd3:	74 19                	je     f0101cee <mem_init+0x9b9>
f0101cd5:	68 a4 6e 10 f0       	push   $0xf0106ea4
f0101cda:	68 4a 75 10 f0       	push   $0xf010754a
f0101cdf:	68 ce 03 00 00       	push   $0x3ce
f0101ce4:	68 15 75 10 f0       	push   $0xf0107515
f0101ce9:	e8 52 e3 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101cee:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101cf3:	74 19                	je     f0101d0e <mem_init+0x9d9>
f0101cf5:	68 31 77 10 f0       	push   $0xf0107731
f0101cfa:	68 4a 75 10 f0       	push   $0xf010754a
f0101cff:	68 cf 03 00 00       	push   $0x3cf
f0101d04:	68 15 75 10 f0       	push   $0xf0107515
f0101d09:	e8 32 e3 ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101d0e:	83 ec 04             	sub    $0x4,%esp
f0101d11:	6a 00                	push   $0x0
f0101d13:	68 00 10 00 00       	push   $0x1000
f0101d18:	57                   	push   %edi
f0101d19:	e8 70 f3 ff ff       	call   f010108e <pgdir_walk>
f0101d1e:	83 c4 10             	add    $0x10,%esp
f0101d21:	f6 00 04             	testb  $0x4,(%eax)
f0101d24:	75 19                	jne    f0101d3f <mem_init+0xa0a>
f0101d26:	68 54 6f 10 f0       	push   $0xf0106f54
f0101d2b:	68 4a 75 10 f0       	push   $0xf010754a
f0101d30:	68 d0 03 00 00       	push   $0x3d0
f0101d35:	68 15 75 10 f0       	push   $0xf0107515
f0101d3a:	e8 01 e3 ff ff       	call   f0100040 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101d3f:	a1 a4 9e 2a f0       	mov    0xf02a9ea4,%eax
f0101d44:	f6 00 04             	testb  $0x4,(%eax)
f0101d47:	75 19                	jne    f0101d62 <mem_init+0xa2d>
f0101d49:	68 42 77 10 f0       	push   $0xf0107742
f0101d4e:	68 4a 75 10 f0       	push   $0xf010754a
f0101d53:	68 d1 03 00 00       	push   $0x3d1
f0101d58:	68 15 75 10 f0       	push   $0xf0107515
f0101d5d:	e8 de e2 ff ff       	call   f0100040 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101d62:	6a 02                	push   $0x2
f0101d64:	68 00 10 00 00       	push   $0x1000
f0101d69:	56                   	push   %esi
f0101d6a:	50                   	push   %eax
f0101d6b:	e8 ea f4 ff ff       	call   f010125a <page_insert>
f0101d70:	83 c4 10             	add    $0x10,%esp
f0101d73:	85 c0                	test   %eax,%eax
f0101d75:	74 19                	je     f0101d90 <mem_init+0xa5b>
f0101d77:	68 68 6e 10 f0       	push   $0xf0106e68
f0101d7c:	68 4a 75 10 f0       	push   $0xf010754a
f0101d81:	68 d4 03 00 00       	push   $0x3d4
f0101d86:	68 15 75 10 f0       	push   $0xf0107515
f0101d8b:	e8 b0 e2 ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101d90:	83 ec 04             	sub    $0x4,%esp
f0101d93:	6a 00                	push   $0x0
f0101d95:	68 00 10 00 00       	push   $0x1000
f0101d9a:	ff 35 a4 9e 2a f0    	pushl  0xf02a9ea4
f0101da0:	e8 e9 f2 ff ff       	call   f010108e <pgdir_walk>
f0101da5:	83 c4 10             	add    $0x10,%esp
f0101da8:	f6 00 02             	testb  $0x2,(%eax)
f0101dab:	75 19                	jne    f0101dc6 <mem_init+0xa91>
f0101dad:	68 88 6f 10 f0       	push   $0xf0106f88
f0101db2:	68 4a 75 10 f0       	push   $0xf010754a
f0101db7:	68 d5 03 00 00       	push   $0x3d5
f0101dbc:	68 15 75 10 f0       	push   $0xf0107515
f0101dc1:	e8 7a e2 ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101dc6:	83 ec 04             	sub    $0x4,%esp
f0101dc9:	6a 00                	push   $0x0
f0101dcb:	68 00 10 00 00       	push   $0x1000
f0101dd0:	ff 35 a4 9e 2a f0    	pushl  0xf02a9ea4
f0101dd6:	e8 b3 f2 ff ff       	call   f010108e <pgdir_walk>
f0101ddb:	83 c4 10             	add    $0x10,%esp
f0101dde:	f6 00 04             	testb  $0x4,(%eax)
f0101de1:	74 19                	je     f0101dfc <mem_init+0xac7>
f0101de3:	68 bc 6f 10 f0       	push   $0xf0106fbc
f0101de8:	68 4a 75 10 f0       	push   $0xf010754a
f0101ded:	68 d6 03 00 00       	push   $0x3d6
f0101df2:	68 15 75 10 f0       	push   $0xf0107515
f0101df7:	e8 44 e2 ff ff       	call   f0100040 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101dfc:	6a 02                	push   $0x2
f0101dfe:	68 00 00 40 00       	push   $0x400000
f0101e03:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101e06:	ff 35 a4 9e 2a f0    	pushl  0xf02a9ea4
f0101e0c:	e8 49 f4 ff ff       	call   f010125a <page_insert>
f0101e11:	83 c4 10             	add    $0x10,%esp
f0101e14:	85 c0                	test   %eax,%eax
f0101e16:	78 19                	js     f0101e31 <mem_init+0xafc>
f0101e18:	68 f4 6f 10 f0       	push   $0xf0106ff4
f0101e1d:	68 4a 75 10 f0       	push   $0xf010754a
f0101e22:	68 d9 03 00 00       	push   $0x3d9
f0101e27:	68 15 75 10 f0       	push   $0xf0107515
f0101e2c:	e8 0f e2 ff ff       	call   f0100040 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101e31:	6a 02                	push   $0x2
f0101e33:	68 00 10 00 00       	push   $0x1000
f0101e38:	53                   	push   %ebx
f0101e39:	ff 35 a4 9e 2a f0    	pushl  0xf02a9ea4
f0101e3f:	e8 16 f4 ff ff       	call   f010125a <page_insert>
f0101e44:	83 c4 10             	add    $0x10,%esp
f0101e47:	85 c0                	test   %eax,%eax
f0101e49:	74 19                	je     f0101e64 <mem_init+0xb2f>
f0101e4b:	68 2c 70 10 f0       	push   $0xf010702c
f0101e50:	68 4a 75 10 f0       	push   $0xf010754a
f0101e55:	68 dc 03 00 00       	push   $0x3dc
f0101e5a:	68 15 75 10 f0       	push   $0xf0107515
f0101e5f:	e8 dc e1 ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101e64:	83 ec 04             	sub    $0x4,%esp
f0101e67:	6a 00                	push   $0x0
f0101e69:	68 00 10 00 00       	push   $0x1000
f0101e6e:	ff 35 a4 9e 2a f0    	pushl  0xf02a9ea4
f0101e74:	e8 15 f2 ff ff       	call   f010108e <pgdir_walk>
f0101e79:	83 c4 10             	add    $0x10,%esp
f0101e7c:	f6 00 04             	testb  $0x4,(%eax)
f0101e7f:	74 19                	je     f0101e9a <mem_init+0xb65>
f0101e81:	68 bc 6f 10 f0       	push   $0xf0106fbc
f0101e86:	68 4a 75 10 f0       	push   $0xf010754a
f0101e8b:	68 dd 03 00 00       	push   $0x3dd
f0101e90:	68 15 75 10 f0       	push   $0xf0107515
f0101e95:	e8 a6 e1 ff ff       	call   f0100040 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101e9a:	8b 3d a4 9e 2a f0    	mov    0xf02a9ea4,%edi
f0101ea0:	ba 00 00 00 00       	mov    $0x0,%edx
f0101ea5:	89 f8                	mov    %edi,%eax
f0101ea7:	e8 17 ec ff ff       	call   f0100ac3 <check_va2pa>
f0101eac:	89 c1                	mov    %eax,%ecx
f0101eae:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101eb1:	89 d8                	mov    %ebx,%eax
f0101eb3:	2b 05 a8 9e 2a f0    	sub    0xf02a9ea8,%eax
f0101eb9:	c1 f8 03             	sar    $0x3,%eax
f0101ebc:	c1 e0 0c             	shl    $0xc,%eax
f0101ebf:	39 c1                	cmp    %eax,%ecx
f0101ec1:	74 19                	je     f0101edc <mem_init+0xba7>
f0101ec3:	68 68 70 10 f0       	push   $0xf0107068
f0101ec8:	68 4a 75 10 f0       	push   $0xf010754a
f0101ecd:	68 e0 03 00 00       	push   $0x3e0
f0101ed2:	68 15 75 10 f0       	push   $0xf0107515
f0101ed7:	e8 64 e1 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101edc:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101ee1:	89 f8                	mov    %edi,%eax
f0101ee3:	e8 db eb ff ff       	call   f0100ac3 <check_va2pa>
f0101ee8:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101eeb:	74 19                	je     f0101f06 <mem_init+0xbd1>
f0101eed:	68 94 70 10 f0       	push   $0xf0107094
f0101ef2:	68 4a 75 10 f0       	push   $0xf010754a
f0101ef7:	68 e1 03 00 00       	push   $0x3e1
f0101efc:	68 15 75 10 f0       	push   $0xf0107515
f0101f01:	e8 3a e1 ff ff       	call   f0100040 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101f06:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101f0b:	74 19                	je     f0101f26 <mem_init+0xbf1>
f0101f0d:	68 58 77 10 f0       	push   $0xf0107758
f0101f12:	68 4a 75 10 f0       	push   $0xf010754a
f0101f17:	68 e3 03 00 00       	push   $0x3e3
f0101f1c:	68 15 75 10 f0       	push   $0xf0107515
f0101f21:	e8 1a e1 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f0101f26:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101f2b:	74 19                	je     f0101f46 <mem_init+0xc11>
f0101f2d:	68 69 77 10 f0       	push   $0xf0107769
f0101f32:	68 4a 75 10 f0       	push   $0xf010754a
f0101f37:	68 e4 03 00 00       	push   $0x3e4
f0101f3c:	68 15 75 10 f0       	push   $0xf0107515
f0101f41:	e8 fa e0 ff ff       	call   f0100040 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101f46:	83 ec 0c             	sub    $0xc,%esp
f0101f49:	6a 00                	push   $0x0
f0101f4b:	e8 65 f0 ff ff       	call   f0100fb5 <page_alloc>
f0101f50:	83 c4 10             	add    $0x10,%esp
f0101f53:	39 c6                	cmp    %eax,%esi
f0101f55:	75 04                	jne    f0101f5b <mem_init+0xc26>
f0101f57:	85 c0                	test   %eax,%eax
f0101f59:	75 19                	jne    f0101f74 <mem_init+0xc3f>
f0101f5b:	68 c4 70 10 f0       	push   $0xf01070c4
f0101f60:	68 4a 75 10 f0       	push   $0xf010754a
f0101f65:	68 e7 03 00 00       	push   $0x3e7
f0101f6a:	68 15 75 10 f0       	push   $0xf0107515
f0101f6f:	e8 cc e0 ff ff       	call   f0100040 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101f74:	83 ec 08             	sub    $0x8,%esp
f0101f77:	6a 00                	push   $0x0
f0101f79:	ff 35 a4 9e 2a f0    	pushl  0xf02a9ea4
f0101f7f:	e8 90 f2 ff ff       	call   f0101214 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101f84:	8b 3d a4 9e 2a f0    	mov    0xf02a9ea4,%edi
f0101f8a:	ba 00 00 00 00       	mov    $0x0,%edx
f0101f8f:	89 f8                	mov    %edi,%eax
f0101f91:	e8 2d eb ff ff       	call   f0100ac3 <check_va2pa>
f0101f96:	83 c4 10             	add    $0x10,%esp
f0101f99:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101f9c:	74 19                	je     f0101fb7 <mem_init+0xc82>
f0101f9e:	68 e8 70 10 f0       	push   $0xf01070e8
f0101fa3:	68 4a 75 10 f0       	push   $0xf010754a
f0101fa8:	68 eb 03 00 00       	push   $0x3eb
f0101fad:	68 15 75 10 f0       	push   $0xf0107515
f0101fb2:	e8 89 e0 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101fb7:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101fbc:	89 f8                	mov    %edi,%eax
f0101fbe:	e8 00 eb ff ff       	call   f0100ac3 <check_va2pa>
f0101fc3:	89 da                	mov    %ebx,%edx
f0101fc5:	2b 15 a8 9e 2a f0    	sub    0xf02a9ea8,%edx
f0101fcb:	c1 fa 03             	sar    $0x3,%edx
f0101fce:	c1 e2 0c             	shl    $0xc,%edx
f0101fd1:	39 d0                	cmp    %edx,%eax
f0101fd3:	74 19                	je     f0101fee <mem_init+0xcb9>
f0101fd5:	68 94 70 10 f0       	push   $0xf0107094
f0101fda:	68 4a 75 10 f0       	push   $0xf010754a
f0101fdf:	68 ec 03 00 00       	push   $0x3ec
f0101fe4:	68 15 75 10 f0       	push   $0xf0107515
f0101fe9:	e8 52 e0 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f0101fee:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101ff3:	74 19                	je     f010200e <mem_init+0xcd9>
f0101ff5:	68 0f 77 10 f0       	push   $0xf010770f
f0101ffa:	68 4a 75 10 f0       	push   $0xf010754a
f0101fff:	68 ed 03 00 00       	push   $0x3ed
f0102004:	68 15 75 10 f0       	push   $0xf0107515
f0102009:	e8 32 e0 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f010200e:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102013:	74 19                	je     f010202e <mem_init+0xcf9>
f0102015:	68 69 77 10 f0       	push   $0xf0107769
f010201a:	68 4a 75 10 f0       	push   $0xf010754a
f010201f:	68 ee 03 00 00       	push   $0x3ee
f0102024:	68 15 75 10 f0       	push   $0xf0107515
f0102029:	e8 12 e0 ff ff       	call   f0100040 <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f010202e:	6a 00                	push   $0x0
f0102030:	68 00 10 00 00       	push   $0x1000
f0102035:	53                   	push   %ebx
f0102036:	57                   	push   %edi
f0102037:	e8 1e f2 ff ff       	call   f010125a <page_insert>
f010203c:	83 c4 10             	add    $0x10,%esp
f010203f:	85 c0                	test   %eax,%eax
f0102041:	74 19                	je     f010205c <mem_init+0xd27>
f0102043:	68 0c 71 10 f0       	push   $0xf010710c
f0102048:	68 4a 75 10 f0       	push   $0xf010754a
f010204d:	68 f1 03 00 00       	push   $0x3f1
f0102052:	68 15 75 10 f0       	push   $0xf0107515
f0102057:	e8 e4 df ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref);
f010205c:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102061:	75 19                	jne    f010207c <mem_init+0xd47>
f0102063:	68 7a 77 10 f0       	push   $0xf010777a
f0102068:	68 4a 75 10 f0       	push   $0xf010754a
f010206d:	68 f2 03 00 00       	push   $0x3f2
f0102072:	68 15 75 10 f0       	push   $0xf0107515
f0102077:	e8 c4 df ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_link == NULL);
f010207c:	83 3b 00             	cmpl   $0x0,(%ebx)
f010207f:	74 19                	je     f010209a <mem_init+0xd65>
f0102081:	68 86 77 10 f0       	push   $0xf0107786
f0102086:	68 4a 75 10 f0       	push   $0xf010754a
f010208b:	68 f3 03 00 00       	push   $0x3f3
f0102090:	68 15 75 10 f0       	push   $0xf0107515
f0102095:	e8 a6 df ff ff       	call   f0100040 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f010209a:	83 ec 08             	sub    $0x8,%esp
f010209d:	68 00 10 00 00       	push   $0x1000
f01020a2:	ff 35 a4 9e 2a f0    	pushl  0xf02a9ea4
f01020a8:	e8 67 f1 ff ff       	call   f0101214 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f01020ad:	8b 3d a4 9e 2a f0    	mov    0xf02a9ea4,%edi
f01020b3:	ba 00 00 00 00       	mov    $0x0,%edx
f01020b8:	89 f8                	mov    %edi,%eax
f01020ba:	e8 04 ea ff ff       	call   f0100ac3 <check_va2pa>
f01020bf:	83 c4 10             	add    $0x10,%esp
f01020c2:	83 f8 ff             	cmp    $0xffffffff,%eax
f01020c5:	74 19                	je     f01020e0 <mem_init+0xdab>
f01020c7:	68 e8 70 10 f0       	push   $0xf01070e8
f01020cc:	68 4a 75 10 f0       	push   $0xf010754a
f01020d1:	68 f7 03 00 00       	push   $0x3f7
f01020d6:	68 15 75 10 f0       	push   $0xf0107515
f01020db:	e8 60 df ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f01020e0:	ba 00 10 00 00       	mov    $0x1000,%edx
f01020e5:	89 f8                	mov    %edi,%eax
f01020e7:	e8 d7 e9 ff ff       	call   f0100ac3 <check_va2pa>
f01020ec:	83 f8 ff             	cmp    $0xffffffff,%eax
f01020ef:	74 19                	je     f010210a <mem_init+0xdd5>
f01020f1:	68 44 71 10 f0       	push   $0xf0107144
f01020f6:	68 4a 75 10 f0       	push   $0xf010754a
f01020fb:	68 f8 03 00 00       	push   $0x3f8
f0102100:	68 15 75 10 f0       	push   $0xf0107515
f0102105:	e8 36 df ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f010210a:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f010210f:	74 19                	je     f010212a <mem_init+0xdf5>
f0102111:	68 9b 77 10 f0       	push   $0xf010779b
f0102116:	68 4a 75 10 f0       	push   $0xf010754a
f010211b:	68 f9 03 00 00       	push   $0x3f9
f0102120:	68 15 75 10 f0       	push   $0xf0107515
f0102125:	e8 16 df ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f010212a:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f010212f:	74 19                	je     f010214a <mem_init+0xe15>
f0102131:	68 69 77 10 f0       	push   $0xf0107769
f0102136:	68 4a 75 10 f0       	push   $0xf010754a
f010213b:	68 fa 03 00 00       	push   $0x3fa
f0102140:	68 15 75 10 f0       	push   $0xf0107515
f0102145:	e8 f6 de ff ff       	call   f0100040 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f010214a:	83 ec 0c             	sub    $0xc,%esp
f010214d:	6a 00                	push   $0x0
f010214f:	e8 61 ee ff ff       	call   f0100fb5 <page_alloc>
f0102154:	83 c4 10             	add    $0x10,%esp
f0102157:	85 c0                	test   %eax,%eax
f0102159:	74 04                	je     f010215f <mem_init+0xe2a>
f010215b:	39 c3                	cmp    %eax,%ebx
f010215d:	74 19                	je     f0102178 <mem_init+0xe43>
f010215f:	68 6c 71 10 f0       	push   $0xf010716c
f0102164:	68 4a 75 10 f0       	push   $0xf010754a
f0102169:	68 fd 03 00 00       	push   $0x3fd
f010216e:	68 15 75 10 f0       	push   $0xf0107515
f0102173:	e8 c8 de ff ff       	call   f0100040 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0102178:	83 ec 0c             	sub    $0xc,%esp
f010217b:	6a 00                	push   $0x0
f010217d:	e8 33 ee ff ff       	call   f0100fb5 <page_alloc>
f0102182:	83 c4 10             	add    $0x10,%esp
f0102185:	85 c0                	test   %eax,%eax
f0102187:	74 19                	je     f01021a2 <mem_init+0xe6d>
f0102189:	68 bd 76 10 f0       	push   $0xf01076bd
f010218e:	68 4a 75 10 f0       	push   $0xf010754a
f0102193:	68 00 04 00 00       	push   $0x400
f0102198:	68 15 75 10 f0       	push   $0xf0107515
f010219d:	e8 9e de ff ff       	call   f0100040 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01021a2:	8b 0d a4 9e 2a f0    	mov    0xf02a9ea4,%ecx
f01021a8:	8b 11                	mov    (%ecx),%edx
f01021aa:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01021b0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01021b3:	2b 05 a8 9e 2a f0    	sub    0xf02a9ea8,%eax
f01021b9:	c1 f8 03             	sar    $0x3,%eax
f01021bc:	c1 e0 0c             	shl    $0xc,%eax
f01021bf:	39 c2                	cmp    %eax,%edx
f01021c1:	74 19                	je     f01021dc <mem_init+0xea7>
f01021c3:	68 10 6e 10 f0       	push   $0xf0106e10
f01021c8:	68 4a 75 10 f0       	push   $0xf010754a
f01021cd:	68 03 04 00 00       	push   $0x403
f01021d2:	68 15 75 10 f0       	push   $0xf0107515
f01021d7:	e8 64 de ff ff       	call   f0100040 <_panic>
	kern_pgdir[0] = 0;
f01021dc:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f01021e2:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01021e5:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f01021ea:	74 19                	je     f0102205 <mem_init+0xed0>
f01021ec:	68 20 77 10 f0       	push   $0xf0107720
f01021f1:	68 4a 75 10 f0       	push   $0xf010754a
f01021f6:	68 05 04 00 00       	push   $0x405
f01021fb:	68 15 75 10 f0       	push   $0xf0107515
f0102200:	e8 3b de ff ff       	call   f0100040 <_panic>
	pp0->pp_ref = 0;
f0102205:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102208:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f010220e:	83 ec 0c             	sub    $0xc,%esp
f0102211:	50                   	push   %eax
f0102212:	e8 15 ee ff ff       	call   f010102c <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0102217:	83 c4 0c             	add    $0xc,%esp
f010221a:	6a 01                	push   $0x1
f010221c:	68 00 10 40 00       	push   $0x401000
f0102221:	ff 35 a4 9e 2a f0    	pushl  0xf02a9ea4
f0102227:	e8 62 ee ff ff       	call   f010108e <pgdir_walk>
f010222c:	89 c7                	mov    %eax,%edi
f010222e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0102231:	a1 a4 9e 2a f0       	mov    0xf02a9ea4,%eax
f0102236:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102239:	8b 40 04             	mov    0x4(%eax),%eax
f010223c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102241:	8b 0d a0 9e 2a f0    	mov    0xf02a9ea0,%ecx
f0102247:	89 c2                	mov    %eax,%edx
f0102249:	c1 ea 0c             	shr    $0xc,%edx
f010224c:	83 c4 10             	add    $0x10,%esp
f010224f:	39 ca                	cmp    %ecx,%edx
f0102251:	72 15                	jb     f0102268 <mem_init+0xf33>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102253:	50                   	push   %eax
f0102254:	68 44 66 10 f0       	push   $0xf0106644
f0102259:	68 0c 04 00 00       	push   $0x40c
f010225e:	68 15 75 10 f0       	push   $0xf0107515
f0102263:	e8 d8 dd ff ff       	call   f0100040 <_panic>
	assert(ptep == ptep1 + PTX(va));
f0102268:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f010226d:	39 c7                	cmp    %eax,%edi
f010226f:	74 19                	je     f010228a <mem_init+0xf55>
f0102271:	68 ac 77 10 f0       	push   $0xf01077ac
f0102276:	68 4a 75 10 f0       	push   $0xf010754a
f010227b:	68 0d 04 00 00       	push   $0x40d
f0102280:	68 15 75 10 f0       	push   $0xf0107515
f0102285:	e8 b6 dd ff ff       	call   f0100040 <_panic>
	kern_pgdir[PDX(va)] = 0;
f010228a:	8b 45 cc             	mov    -0x34(%ebp),%eax
f010228d:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f0102294:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102297:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010229d:	2b 05 a8 9e 2a f0    	sub    0xf02a9ea8,%eax
f01022a3:	c1 f8 03             	sar    $0x3,%eax
f01022a6:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01022a9:	89 c2                	mov    %eax,%edx
f01022ab:	c1 ea 0c             	shr    $0xc,%edx
f01022ae:	39 d1                	cmp    %edx,%ecx
f01022b0:	77 12                	ja     f01022c4 <mem_init+0xf8f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01022b2:	50                   	push   %eax
f01022b3:	68 44 66 10 f0       	push   $0xf0106644
f01022b8:	6a 58                	push   $0x58
f01022ba:	68 30 75 10 f0       	push   $0xf0107530
f01022bf:	e8 7c dd ff ff       	call   f0100040 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f01022c4:	83 ec 04             	sub    $0x4,%esp
f01022c7:	68 00 10 00 00       	push   $0x1000
f01022cc:	68 ff 00 00 00       	push   $0xff
f01022d1:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01022d6:	50                   	push   %eax
f01022d7:	e8 2d 31 00 00       	call   f0105409 <memset>
	page_free(pp0);
f01022dc:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01022df:	89 3c 24             	mov    %edi,(%esp)
f01022e2:	e8 45 ed ff ff       	call   f010102c <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f01022e7:	83 c4 0c             	add    $0xc,%esp
f01022ea:	6a 01                	push   $0x1
f01022ec:	6a 00                	push   $0x0
f01022ee:	ff 35 a4 9e 2a f0    	pushl  0xf02a9ea4
f01022f4:	e8 95 ed ff ff       	call   f010108e <pgdir_walk>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01022f9:	89 fa                	mov    %edi,%edx
f01022fb:	2b 15 a8 9e 2a f0    	sub    0xf02a9ea8,%edx
f0102301:	c1 fa 03             	sar    $0x3,%edx
f0102304:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102307:	89 d0                	mov    %edx,%eax
f0102309:	c1 e8 0c             	shr    $0xc,%eax
f010230c:	83 c4 10             	add    $0x10,%esp
f010230f:	3b 05 a0 9e 2a f0    	cmp    0xf02a9ea0,%eax
f0102315:	72 12                	jb     f0102329 <mem_init+0xff4>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102317:	52                   	push   %edx
f0102318:	68 44 66 10 f0       	push   $0xf0106644
f010231d:	6a 58                	push   $0x58
f010231f:	68 30 75 10 f0       	push   $0xf0107530
f0102324:	e8 17 dd ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0102329:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f010232f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102332:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102338:	f6 00 01             	testb  $0x1,(%eax)
f010233b:	74 19                	je     f0102356 <mem_init+0x1021>
f010233d:	68 c4 77 10 f0       	push   $0xf01077c4
f0102342:	68 4a 75 10 f0       	push   $0xf010754a
f0102347:	68 17 04 00 00       	push   $0x417
f010234c:	68 15 75 10 f0       	push   $0xf0107515
f0102351:	e8 ea dc ff ff       	call   f0100040 <_panic>
f0102356:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f0102359:	39 d0                	cmp    %edx,%eax
f010235b:	75 db                	jne    f0102338 <mem_init+0x1003>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f010235d:	a1 a4 9e 2a f0       	mov    0xf02a9ea4,%eax
f0102362:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102368:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010236b:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f0102371:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0102374:	89 0d 40 92 2a f0    	mov    %ecx,0xf02a9240

	// free the pages we took
	page_free(pp0);
f010237a:	83 ec 0c             	sub    $0xc,%esp
f010237d:	50                   	push   %eax
f010237e:	e8 a9 ec ff ff       	call   f010102c <page_free>
	page_free(pp1);
f0102383:	89 1c 24             	mov    %ebx,(%esp)
f0102386:	e8 a1 ec ff ff       	call   f010102c <page_free>
	page_free(pp2);
f010238b:	89 34 24             	mov    %esi,(%esp)
f010238e:	e8 99 ec ff ff       	call   f010102c <page_free>

	// test mmio_map_region
	mm1 = (uintptr_t) mmio_map_region(0, 4097);
f0102393:	83 c4 08             	add    $0x8,%esp
f0102396:	68 01 10 00 00       	push   $0x1001
f010239b:	6a 00                	push   $0x0
f010239d:	e8 30 ef ff ff       	call   f01012d2 <mmio_map_region>
f01023a2:	89 c3                	mov    %eax,%ebx
	mm2 = (uintptr_t) mmio_map_region(0, 4096);
f01023a4:	83 c4 08             	add    $0x8,%esp
f01023a7:	68 00 10 00 00       	push   $0x1000
f01023ac:	6a 00                	push   $0x0
f01023ae:	e8 1f ef ff ff       	call   f01012d2 <mmio_map_region>
f01023b3:	89 c6                	mov    %eax,%esi
	// check that they're in the right region
	assert(mm1 >= MMIOBASE && mm1 + 8096 < MMIOLIM);
f01023b5:	8d 83 a0 1f 00 00    	lea    0x1fa0(%ebx),%eax
f01023bb:	83 c4 10             	add    $0x10,%esp
f01023be:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f01023c4:	76 07                	jbe    f01023cd <mem_init+0x1098>
f01023c6:	3d ff ff bf ef       	cmp    $0xefbfffff,%eax
f01023cb:	76 19                	jbe    f01023e6 <mem_init+0x10b1>
f01023cd:	68 90 71 10 f0       	push   $0xf0107190
f01023d2:	68 4a 75 10 f0       	push   $0xf010754a
f01023d7:	68 27 04 00 00       	push   $0x427
f01023dc:	68 15 75 10 f0       	push   $0xf0107515
f01023e1:	e8 5a dc ff ff       	call   f0100040 <_panic>
	assert(mm2 >= MMIOBASE && mm2 + 8096 < MMIOLIM);
f01023e6:	8d 96 a0 1f 00 00    	lea    0x1fa0(%esi),%edx
f01023ec:	81 fa ff ff bf ef    	cmp    $0xefbfffff,%edx
f01023f2:	77 08                	ja     f01023fc <mem_init+0x10c7>
f01023f4:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f01023fa:	77 19                	ja     f0102415 <mem_init+0x10e0>
f01023fc:	68 b8 71 10 f0       	push   $0xf01071b8
f0102401:	68 4a 75 10 f0       	push   $0xf010754a
f0102406:	68 28 04 00 00       	push   $0x428
f010240b:	68 15 75 10 f0       	push   $0xf0107515
f0102410:	e8 2b dc ff ff       	call   f0100040 <_panic>
	// check that they're page-aligned
	assert(mm1 % PGSIZE == 0 && mm2 % PGSIZE == 0);
f0102415:	89 da                	mov    %ebx,%edx
f0102417:	09 f2                	or     %esi,%edx
f0102419:	f7 c2 ff 0f 00 00    	test   $0xfff,%edx
f010241f:	74 19                	je     f010243a <mem_init+0x1105>
f0102421:	68 e0 71 10 f0       	push   $0xf01071e0
f0102426:	68 4a 75 10 f0       	push   $0xf010754a
f010242b:	68 2a 04 00 00       	push   $0x42a
f0102430:	68 15 75 10 f0       	push   $0xf0107515
f0102435:	e8 06 dc ff ff       	call   f0100040 <_panic>
	// check that they don't overlap
	assert(mm1 + 8096 <= mm2);
f010243a:	39 c6                	cmp    %eax,%esi
f010243c:	73 19                	jae    f0102457 <mem_init+0x1122>
f010243e:	68 db 77 10 f0       	push   $0xf01077db
f0102443:	68 4a 75 10 f0       	push   $0xf010754a
f0102448:	68 2c 04 00 00       	push   $0x42c
f010244d:	68 15 75 10 f0       	push   $0xf0107515
f0102452:	e8 e9 db ff ff       	call   f0100040 <_panic>
	// check page mappings
	assert(check_va2pa(kern_pgdir, mm1) == 0);
f0102457:	8b 3d a4 9e 2a f0    	mov    0xf02a9ea4,%edi
f010245d:	89 da                	mov    %ebx,%edx
f010245f:	89 f8                	mov    %edi,%eax
f0102461:	e8 5d e6 ff ff       	call   f0100ac3 <check_va2pa>
f0102466:	85 c0                	test   %eax,%eax
f0102468:	74 19                	je     f0102483 <mem_init+0x114e>
f010246a:	68 08 72 10 f0       	push   $0xf0107208
f010246f:	68 4a 75 10 f0       	push   $0xf010754a
f0102474:	68 2e 04 00 00       	push   $0x42e
f0102479:	68 15 75 10 f0       	push   $0xf0107515
f010247e:	e8 bd db ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm1+PGSIZE) == PGSIZE);
f0102483:	8d 83 00 10 00 00    	lea    0x1000(%ebx),%eax
f0102489:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010248c:	89 c2                	mov    %eax,%edx
f010248e:	89 f8                	mov    %edi,%eax
f0102490:	e8 2e e6 ff ff       	call   f0100ac3 <check_va2pa>
f0102495:	3d 00 10 00 00       	cmp    $0x1000,%eax
f010249a:	74 19                	je     f01024b5 <mem_init+0x1180>
f010249c:	68 2c 72 10 f0       	push   $0xf010722c
f01024a1:	68 4a 75 10 f0       	push   $0xf010754a
f01024a6:	68 2f 04 00 00       	push   $0x42f
f01024ab:	68 15 75 10 f0       	push   $0xf0107515
f01024b0:	e8 8b db ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm2) == 0);
f01024b5:	89 f2                	mov    %esi,%edx
f01024b7:	89 f8                	mov    %edi,%eax
f01024b9:	e8 05 e6 ff ff       	call   f0100ac3 <check_va2pa>
f01024be:	85 c0                	test   %eax,%eax
f01024c0:	74 19                	je     f01024db <mem_init+0x11a6>
f01024c2:	68 5c 72 10 f0       	push   $0xf010725c
f01024c7:	68 4a 75 10 f0       	push   $0xf010754a
f01024cc:	68 30 04 00 00       	push   $0x430
f01024d1:	68 15 75 10 f0       	push   $0xf0107515
f01024d6:	e8 65 db ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm2+PGSIZE) == ~0);
f01024db:	8d 96 00 10 00 00    	lea    0x1000(%esi),%edx
f01024e1:	89 f8                	mov    %edi,%eax
f01024e3:	e8 db e5 ff ff       	call   f0100ac3 <check_va2pa>
f01024e8:	83 f8 ff             	cmp    $0xffffffff,%eax
f01024eb:	74 19                	je     f0102506 <mem_init+0x11d1>
f01024ed:	68 80 72 10 f0       	push   $0xf0107280
f01024f2:	68 4a 75 10 f0       	push   $0xf010754a
f01024f7:	68 31 04 00 00       	push   $0x431
f01024fc:	68 15 75 10 f0       	push   $0xf0107515
f0102501:	e8 3a db ff ff       	call   f0100040 <_panic>
	// check permissions
	assert(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & (PTE_W|PTE_PWT|PTE_PCD));
f0102506:	83 ec 04             	sub    $0x4,%esp
f0102509:	6a 00                	push   $0x0
f010250b:	53                   	push   %ebx
f010250c:	57                   	push   %edi
f010250d:	e8 7c eb ff ff       	call   f010108e <pgdir_walk>
f0102512:	83 c4 10             	add    $0x10,%esp
f0102515:	f6 00 1a             	testb  $0x1a,(%eax)
f0102518:	75 19                	jne    f0102533 <mem_init+0x11fe>
f010251a:	68 ac 72 10 f0       	push   $0xf01072ac
f010251f:	68 4a 75 10 f0       	push   $0xf010754a
f0102524:	68 33 04 00 00       	push   $0x433
f0102529:	68 15 75 10 f0       	push   $0xf0107515
f010252e:	e8 0d db ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & PTE_U));
f0102533:	83 ec 04             	sub    $0x4,%esp
f0102536:	6a 00                	push   $0x0
f0102538:	53                   	push   %ebx
f0102539:	ff 35 a4 9e 2a f0    	pushl  0xf02a9ea4
f010253f:	e8 4a eb ff ff       	call   f010108e <pgdir_walk>
f0102544:	8b 00                	mov    (%eax),%eax
f0102546:	83 c4 10             	add    $0x10,%esp
f0102549:	83 e0 04             	and    $0x4,%eax
f010254c:	89 45 c8             	mov    %eax,-0x38(%ebp)
f010254f:	74 19                	je     f010256a <mem_init+0x1235>
f0102551:	68 f0 72 10 f0       	push   $0xf01072f0
f0102556:	68 4a 75 10 f0       	push   $0xf010754a
f010255b:	68 34 04 00 00       	push   $0x434
f0102560:	68 15 75 10 f0       	push   $0xf0107515
f0102565:	e8 d6 da ff ff       	call   f0100040 <_panic>
	// clear the mappings
	*pgdir_walk(kern_pgdir, (void*) mm1, 0) = 0;
f010256a:	83 ec 04             	sub    $0x4,%esp
f010256d:	6a 00                	push   $0x0
f010256f:	53                   	push   %ebx
f0102570:	ff 35 a4 9e 2a f0    	pushl  0xf02a9ea4
f0102576:	e8 13 eb ff ff       	call   f010108e <pgdir_walk>
f010257b:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm1 + PGSIZE, 0) = 0;
f0102581:	83 c4 0c             	add    $0xc,%esp
f0102584:	6a 00                	push   $0x0
f0102586:	ff 75 d4             	pushl  -0x2c(%ebp)
f0102589:	ff 35 a4 9e 2a f0    	pushl  0xf02a9ea4
f010258f:	e8 fa ea ff ff       	call   f010108e <pgdir_walk>
f0102594:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm2, 0) = 0;
f010259a:	83 c4 0c             	add    $0xc,%esp
f010259d:	6a 00                	push   $0x0
f010259f:	56                   	push   %esi
f01025a0:	ff 35 a4 9e 2a f0    	pushl  0xf02a9ea4
f01025a6:	e8 e3 ea ff ff       	call   f010108e <pgdir_walk>
f01025ab:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

	cprintf("check_page() succeeded!\n");
f01025b1:	c7 04 24 ed 77 10 f0 	movl   $0xf01077ed,(%esp)
f01025b8:	e8 a0 10 00 00       	call   f010365d <cprintf>
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	
	boot_map_region(kern_pgdir, UPAGES, PTSIZE, PADDR(pages), PTE_U);
f01025bd:	a1 a8 9e 2a f0       	mov    0xf02a9ea8,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01025c2:	83 c4 10             	add    $0x10,%esp
f01025c5:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01025ca:	77 15                	ja     f01025e1 <mem_init+0x12ac>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01025cc:	50                   	push   %eax
f01025cd:	68 68 66 10 f0       	push   $0xf0106668
f01025d2:	68 be 00 00 00       	push   $0xbe
f01025d7:	68 15 75 10 f0       	push   $0xf0107515
f01025dc:	e8 5f da ff ff       	call   f0100040 <_panic>
f01025e1:	83 ec 08             	sub    $0x8,%esp
f01025e4:	6a 04                	push   $0x4
f01025e6:	05 00 00 00 10       	add    $0x10000000,%eax
f01025eb:	50                   	push   %eax
f01025ec:	b9 00 00 40 00       	mov    $0x400000,%ecx
f01025f1:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f01025f6:	a1 a4 9e 2a f0       	mov    0xf02a9ea4,%eax
f01025fb:	e8 23 eb ff ff       	call   f0101123 <boot_map_region>
	// (ie. perm = PTE_U | PTE_P).
	// Permissions:
	//    - the new image at UENVS  -- kernel R, user R
	//    - envs itself -- kernel RW, user NONE
	// LAB 3: Your code here.
	boot_map_region(kern_pgdir, UENVS, PTSIZE, PADDR(envs), PTE_U);
f0102600:	a1 44 92 2a f0       	mov    0xf02a9244,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102605:	83 c4 10             	add    $0x10,%esp
f0102608:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010260d:	77 15                	ja     f0102624 <mem_init+0x12ef>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010260f:	50                   	push   %eax
f0102610:	68 68 66 10 f0       	push   $0xf0106668
f0102615:	68 c7 00 00 00       	push   $0xc7
f010261a:	68 15 75 10 f0       	push   $0xf0107515
f010261f:	e8 1c da ff ff       	call   f0100040 <_panic>
f0102624:	83 ec 08             	sub    $0x8,%esp
f0102627:	6a 04                	push   $0x4
f0102629:	05 00 00 00 10       	add    $0x10000000,%eax
f010262e:	50                   	push   %eax
f010262f:	b9 00 00 40 00       	mov    $0x400000,%ecx
f0102634:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f0102639:	a1 a4 9e 2a f0       	mov    0xf02a9ea4,%eax
f010263e:	e8 e0 ea ff ff       	call   f0101123 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102643:	83 c4 10             	add    $0x10,%esp
f0102646:	b8 00 80 11 f0       	mov    $0xf0118000,%eax
f010264b:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102650:	77 15                	ja     f0102667 <mem_init+0x1332>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102652:	50                   	push   %eax
f0102653:	68 68 66 10 f0       	push   $0xf0106668
f0102658:	68 d4 00 00 00       	push   $0xd4
f010265d:	68 15 75 10 f0       	push   $0xf0107515
f0102662:	e8 d9 d9 ff ff       	call   f0100040 <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KSTACKTOP-KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W);
f0102667:	83 ec 08             	sub    $0x8,%esp
f010266a:	6a 02                	push   $0x2
f010266c:	68 00 80 11 00       	push   $0x118000
f0102671:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102676:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f010267b:	a1 a4 9e 2a f0       	mov    0xf02a9ea4,%eax
f0102680:	e8 9e ea ff ff       	call   f0101123 <boot_map_region>
	//      the PA range [0, 2^32 - KERNBASE)
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
    boot_map_region(kern_pgdir, KERNBASE, 0xffffffff - KERNBASE, 0, PTE_W);
f0102685:	83 c4 08             	add    $0x8,%esp
f0102688:	6a 02                	push   $0x2
f010268a:	6a 00                	push   $0x0
f010268c:	b9 ff ff ff 0f       	mov    $0xfffffff,%ecx
f0102691:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0102696:	a1 a4 9e 2a f0       	mov    0xf02a9ea4,%eax
f010269b:	e8 83 ea ff ff       	call   f0101123 <boot_map_region>
f01026a0:	c7 45 c4 00 b0 2a f0 	movl   $0xf02ab000,-0x3c(%ebp)
f01026a7:	83 c4 10             	add    $0x10,%esp
f01026aa:	bb 00 b0 2a f0       	mov    $0xf02ab000,%ebx
f01026af:	be 00 80 ff ef       	mov    $0xefff8000,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01026b4:	81 fb ff ff ff ef    	cmp    $0xefffffff,%ebx
f01026ba:	77 15                	ja     f01026d1 <mem_init+0x139c>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01026bc:	53                   	push   %ebx
f01026bd:	68 68 66 10 f0       	push   $0xf0106668
f01026c2:	68 16 01 00 00       	push   $0x116
f01026c7:	68 15 75 10 f0       	push   $0xf0107515
f01026cc:	e8 6f d9 ff ff       	call   f0100040 <_panic>
	// LAB 4: Your code here:

    uintptr_t kstacktop_i;
    for(int i = 0; i < NCPU; i++){
        kstacktop_i = KSTACKTOP - i * (KSTKSIZE + KSTKGAP);
        boot_map_region(kern_pgdir, kstacktop_i - KSTKSIZE, KSTKSIZE, PADDR(percpu_kstacks[i]), PTE_W);
f01026d1:	83 ec 08             	sub    $0x8,%esp
f01026d4:	6a 02                	push   $0x2
f01026d6:	8d 83 00 00 00 10    	lea    0x10000000(%ebx),%eax
f01026dc:	50                   	push   %eax
f01026dd:	b9 00 80 00 00       	mov    $0x8000,%ecx
f01026e2:	89 f2                	mov    %esi,%edx
f01026e4:	a1 a4 9e 2a f0       	mov    0xf02a9ea4,%eax
f01026e9:	e8 35 ea ff ff       	call   f0101123 <boot_map_region>
f01026ee:	81 c3 00 80 00 00    	add    $0x8000,%ebx
f01026f4:	81 ee 00 00 01 00    	sub    $0x10000,%esi
	//     Permissions: kernel RW, user NONE
	//
	// LAB 4: Your code here:

    uintptr_t kstacktop_i;
    for(int i = 0; i < NCPU; i++){
f01026fa:	83 c4 10             	add    $0x10,%esp
f01026fd:	b8 00 b0 2e f0       	mov    $0xf02eb000,%eax
f0102702:	39 d8                	cmp    %ebx,%eax
f0102704:	75 ae                	jne    f01026b4 <mem_init+0x137f>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f0102706:	8b 3d a4 9e 2a f0    	mov    0xf02a9ea4,%edi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f010270c:	a1 a0 9e 2a f0       	mov    0xf02a9ea0,%eax
f0102711:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102714:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f010271b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102720:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102723:	8b 35 a8 9e 2a f0    	mov    0xf02a9ea8,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102729:	89 75 d0             	mov    %esi,-0x30(%ebp)

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f010272c:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102731:	eb 55                	jmp    f0102788 <mem_init+0x1453>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102733:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
f0102739:	89 f8                	mov    %edi,%eax
f010273b:	e8 83 e3 ff ff       	call   f0100ac3 <check_va2pa>
f0102740:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f0102747:	77 15                	ja     f010275e <mem_init+0x1429>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102749:	56                   	push   %esi
f010274a:	68 68 66 10 f0       	push   $0xf0106668
f010274f:	68 4c 03 00 00       	push   $0x34c
f0102754:	68 15 75 10 f0       	push   $0xf0107515
f0102759:	e8 e2 d8 ff ff       	call   f0100040 <_panic>
f010275e:	8d 94 1e 00 00 00 10 	lea    0x10000000(%esi,%ebx,1),%edx
f0102765:	39 c2                	cmp    %eax,%edx
f0102767:	74 19                	je     f0102782 <mem_init+0x144d>
f0102769:	68 24 73 10 f0       	push   $0xf0107324
f010276e:	68 4a 75 10 f0       	push   $0xf010754a
f0102773:	68 4c 03 00 00       	push   $0x34c
f0102778:	68 15 75 10 f0       	push   $0xf0107515
f010277d:	e8 be d8 ff ff       	call   f0100040 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102782:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102788:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f010278b:	77 a6                	ja     f0102733 <mem_init+0x13fe>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f010278d:	8b 35 44 92 2a f0    	mov    0xf02a9244,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102793:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f0102796:	bb 00 00 c0 ee       	mov    $0xeec00000,%ebx
f010279b:	89 da                	mov    %ebx,%edx
f010279d:	89 f8                	mov    %edi,%eax
f010279f:	e8 1f e3 ff ff       	call   f0100ac3 <check_va2pa>
f01027a4:	81 7d d4 ff ff ff ef 	cmpl   $0xefffffff,-0x2c(%ebp)
f01027ab:	77 15                	ja     f01027c2 <mem_init+0x148d>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01027ad:	56                   	push   %esi
f01027ae:	68 68 66 10 f0       	push   $0xf0106668
f01027b3:	68 51 03 00 00       	push   $0x351
f01027b8:	68 15 75 10 f0       	push   $0xf0107515
f01027bd:	e8 7e d8 ff ff       	call   f0100040 <_panic>
f01027c2:	8d 94 1e 00 00 40 21 	lea    0x21400000(%esi,%ebx,1),%edx
f01027c9:	39 d0                	cmp    %edx,%eax
f01027cb:	74 19                	je     f01027e6 <mem_init+0x14b1>
f01027cd:	68 58 73 10 f0       	push   $0xf0107358
f01027d2:	68 4a 75 10 f0       	push   $0xf010754a
f01027d7:	68 51 03 00 00       	push   $0x351
f01027dc:	68 15 75 10 f0       	push   $0xf0107515
f01027e1:	e8 5a d8 ff ff       	call   f0100040 <_panic>
f01027e6:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01027ec:	81 fb 00 f0 c1 ee    	cmp    $0xeec1f000,%ebx
f01027f2:	75 a7                	jne    f010279b <mem_init+0x1466>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01027f4:	8b 75 cc             	mov    -0x34(%ebp),%esi
f01027f7:	c1 e6 0c             	shl    $0xc,%esi
f01027fa:	bb 00 00 00 00       	mov    $0x0,%ebx
f01027ff:	eb 30                	jmp    f0102831 <mem_init+0x14fc>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102801:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
f0102807:	89 f8                	mov    %edi,%eax
f0102809:	e8 b5 e2 ff ff       	call   f0100ac3 <check_va2pa>
f010280e:	39 c3                	cmp    %eax,%ebx
f0102810:	74 19                	je     f010282b <mem_init+0x14f6>
f0102812:	68 8c 73 10 f0       	push   $0xf010738c
f0102817:	68 4a 75 10 f0       	push   $0xf010754a
f010281c:	68 55 03 00 00       	push   $0x355
f0102821:	68 15 75 10 f0       	push   $0xf0107515
f0102826:	e8 15 d8 ff ff       	call   f0100040 <_panic>
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f010282b:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102831:	39 f3                	cmp    %esi,%ebx
f0102833:	72 cc                	jb     f0102801 <mem_init+0x14cc>
f0102835:	be 00 80 ff ef       	mov    $0xefff8000,%esi
f010283a:	89 75 cc             	mov    %esi,-0x34(%ebp)
f010283d:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f0102840:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102843:	8d 88 00 80 00 00    	lea    0x8000(%eax),%ecx
f0102849:	89 4d d0             	mov    %ecx,-0x30(%ebp)
f010284c:	89 c3                	mov    %eax,%ebx
	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
f010284e:	8b 45 c8             	mov    -0x38(%ebp),%eax
f0102851:	05 00 80 00 20       	add    $0x20008000,%eax
f0102856:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102859:	89 da                	mov    %ebx,%edx
f010285b:	89 f8                	mov    %edi,%eax
f010285d:	e8 61 e2 ff ff       	call   f0100ac3 <check_va2pa>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102862:	81 fe ff ff ff ef    	cmp    $0xefffffff,%esi
f0102868:	77 15                	ja     f010287f <mem_init+0x154a>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010286a:	56                   	push   %esi
f010286b:	68 68 66 10 f0       	push   $0xf0106668
f0102870:	68 5d 03 00 00       	push   $0x35d
f0102875:	68 15 75 10 f0       	push   $0xf0107515
f010287a:	e8 c1 d7 ff ff       	call   f0100040 <_panic>
f010287f:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0102882:	8d 94 0b 00 b0 2a f0 	lea    -0xfd55000(%ebx,%ecx,1),%edx
f0102889:	39 d0                	cmp    %edx,%eax
f010288b:	74 19                	je     f01028a6 <mem_init+0x1571>
f010288d:	68 b4 73 10 f0       	push   $0xf01073b4
f0102892:	68 4a 75 10 f0       	push   $0xf010754a
f0102897:	68 5d 03 00 00       	push   $0x35d
f010289c:	68 15 75 10 f0       	push   $0xf0107515
f01028a1:	e8 9a d7 ff ff       	call   f0100040 <_panic>
f01028a6:	81 c3 00 10 00 00    	add    $0x1000,%ebx

	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
f01028ac:	3b 5d d0             	cmp    -0x30(%ebp),%ebx
f01028af:	75 a8                	jne    f0102859 <mem_init+0x1524>
f01028b1:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01028b4:	8d 98 00 80 ff ff    	lea    -0x8000(%eax),%ebx
f01028ba:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f01028bd:	89 c6                	mov    %eax,%esi
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
				== PADDR(percpu_kstacks[n]) + i);
		for (i = 0; i < KSTKGAP; i += PGSIZE)
			assert(check_va2pa(pgdir, base + i) == ~0);
f01028bf:	89 da                	mov    %ebx,%edx
f01028c1:	89 f8                	mov    %edi,%eax
f01028c3:	e8 fb e1 ff ff       	call   f0100ac3 <check_va2pa>
f01028c8:	83 f8 ff             	cmp    $0xffffffff,%eax
f01028cb:	74 19                	je     f01028e6 <mem_init+0x15b1>
f01028cd:	68 fc 73 10 f0       	push   $0xf01073fc
f01028d2:	68 4a 75 10 f0       	push   $0xf010754a
f01028d7:	68 5f 03 00 00       	push   $0x35f
f01028dc:	68 15 75 10 f0       	push   $0xf0107515
f01028e1:	e8 5a d7 ff ff       	call   f0100040 <_panic>
f01028e6:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
				== PADDR(percpu_kstacks[n]) + i);
		for (i = 0; i < KSTKGAP; i += PGSIZE)
f01028ec:	39 f3                	cmp    %esi,%ebx
f01028ee:	75 cf                	jne    f01028bf <mem_init+0x158a>
f01028f0:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f01028f3:	81 6d cc 00 00 01 00 	subl   $0x10000,-0x34(%ebp)
f01028fa:	81 45 c8 00 80 01 00 	addl   $0x18000,-0x38(%ebp)
f0102901:	81 c6 00 80 00 00    	add    $0x8000,%esi
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
f0102907:	b8 00 b0 2e f0       	mov    $0xf02eb000,%eax
f010290c:	39 f0                	cmp    %esi,%eax
f010290e:	0f 85 2c ff ff ff    	jne    f0102840 <mem_init+0x150b>
f0102914:	b8 00 00 00 00       	mov    $0x0,%eax
f0102919:	eb 2a                	jmp    f0102945 <mem_init+0x1610>
			assert(check_va2pa(pgdir, base + i) == ~0);
	}

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f010291b:	8d 90 45 fc ff ff    	lea    -0x3bb(%eax),%edx
f0102921:	83 fa 04             	cmp    $0x4,%edx
f0102924:	77 1f                	ja     f0102945 <mem_init+0x1610>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
		case PDX(UENVS):
		case PDX(MMIOBASE):
			assert(pgdir[i] & PTE_P);
f0102926:	f6 04 87 01          	testb  $0x1,(%edi,%eax,4)
f010292a:	75 7e                	jne    f01029aa <mem_init+0x1675>
f010292c:	68 06 78 10 f0       	push   $0xf0107806
f0102931:	68 4a 75 10 f0       	push   $0xf010754a
f0102936:	68 6a 03 00 00       	push   $0x36a
f010293b:	68 15 75 10 f0       	push   $0xf0107515
f0102940:	e8 fb d6 ff ff       	call   f0100040 <_panic>
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f0102945:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f010294a:	76 3f                	jbe    f010298b <mem_init+0x1656>
				assert(pgdir[i] & PTE_P);
f010294c:	8b 14 87             	mov    (%edi,%eax,4),%edx
f010294f:	f6 c2 01             	test   $0x1,%dl
f0102952:	75 19                	jne    f010296d <mem_init+0x1638>
f0102954:	68 06 78 10 f0       	push   $0xf0107806
f0102959:	68 4a 75 10 f0       	push   $0xf010754a
f010295e:	68 6e 03 00 00       	push   $0x36e
f0102963:	68 15 75 10 f0       	push   $0xf0107515
f0102968:	e8 d3 d6 ff ff       	call   f0100040 <_panic>
				assert(pgdir[i] & PTE_W);
f010296d:	f6 c2 02             	test   $0x2,%dl
f0102970:	75 38                	jne    f01029aa <mem_init+0x1675>
f0102972:	68 17 78 10 f0       	push   $0xf0107817
f0102977:	68 4a 75 10 f0       	push   $0xf010754a
f010297c:	68 6f 03 00 00       	push   $0x36f
f0102981:	68 15 75 10 f0       	push   $0xf0107515
f0102986:	e8 b5 d6 ff ff       	call   f0100040 <_panic>
			} else
				assert(pgdir[i] == 0);
f010298b:	83 3c 87 00          	cmpl   $0x0,(%edi,%eax,4)
f010298f:	74 19                	je     f01029aa <mem_init+0x1675>
f0102991:	68 28 78 10 f0       	push   $0xf0107828
f0102996:	68 4a 75 10 f0       	push   $0xf010754a
f010299b:	68 71 03 00 00       	push   $0x371
f01029a0:	68 15 75 10 f0       	push   $0xf0107515
f01029a5:	e8 96 d6 ff ff       	call   f0100040 <_panic>
		for (i = 0; i < KSTKGAP; i += PGSIZE)
			assert(check_va2pa(pgdir, base + i) == ~0);
	}

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f01029aa:	83 c0 01             	add    $0x1,%eax
f01029ad:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f01029b2:	0f 86 63 ff ff ff    	jbe    f010291b <mem_init+0x15e6>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f01029b8:	83 ec 0c             	sub    $0xc,%esp
f01029bb:	68 20 74 10 f0       	push   $0xf0107420
f01029c0:	e8 98 0c 00 00       	call   f010365d <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f01029c5:	a1 a4 9e 2a f0       	mov    0xf02a9ea4,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01029ca:	83 c4 10             	add    $0x10,%esp
f01029cd:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01029d2:	77 15                	ja     f01029e9 <mem_init+0x16b4>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01029d4:	50                   	push   %eax
f01029d5:	68 68 66 10 f0       	push   $0xf0106668
f01029da:	68 ed 00 00 00       	push   $0xed
f01029df:	68 15 75 10 f0       	push   $0xf0107515
f01029e4:	e8 57 d6 ff ff       	call   f0100040 <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f01029e9:	05 00 00 00 10       	add    $0x10000000,%eax
f01029ee:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f01029f1:	b8 00 00 00 00       	mov    $0x0,%eax
f01029f6:	e8 b3 e1 ff ff       	call   f0100bae <check_page_free_list>

static inline uint32_t
rcr0(void)
{
	uint32_t val;
	asm volatile("movl %%cr0,%0" : "=r" (val));
f01029fb:	0f 20 c0             	mov    %cr0,%eax
f01029fe:	83 e0 f3             	and    $0xfffffff3,%eax
}

static inline void
lcr0(uint32_t val)
{
	asm volatile("movl %0,%%cr0" : : "r" (val));
f0102a01:	0d 23 00 05 80       	or     $0x80050023,%eax
f0102a06:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102a09:	83 ec 0c             	sub    $0xc,%esp
f0102a0c:	6a 00                	push   $0x0
f0102a0e:	e8 a2 e5 ff ff       	call   f0100fb5 <page_alloc>
f0102a13:	89 c3                	mov    %eax,%ebx
f0102a15:	83 c4 10             	add    $0x10,%esp
f0102a18:	85 c0                	test   %eax,%eax
f0102a1a:	75 19                	jne    f0102a35 <mem_init+0x1700>
f0102a1c:	68 12 76 10 f0       	push   $0xf0107612
f0102a21:	68 4a 75 10 f0       	push   $0xf010754a
f0102a26:	68 49 04 00 00       	push   $0x449
f0102a2b:	68 15 75 10 f0       	push   $0xf0107515
f0102a30:	e8 0b d6 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0102a35:	83 ec 0c             	sub    $0xc,%esp
f0102a38:	6a 00                	push   $0x0
f0102a3a:	e8 76 e5 ff ff       	call   f0100fb5 <page_alloc>
f0102a3f:	89 c7                	mov    %eax,%edi
f0102a41:	83 c4 10             	add    $0x10,%esp
f0102a44:	85 c0                	test   %eax,%eax
f0102a46:	75 19                	jne    f0102a61 <mem_init+0x172c>
f0102a48:	68 28 76 10 f0       	push   $0xf0107628
f0102a4d:	68 4a 75 10 f0       	push   $0xf010754a
f0102a52:	68 4a 04 00 00       	push   $0x44a
f0102a57:	68 15 75 10 f0       	push   $0xf0107515
f0102a5c:	e8 df d5 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0102a61:	83 ec 0c             	sub    $0xc,%esp
f0102a64:	6a 00                	push   $0x0
f0102a66:	e8 4a e5 ff ff       	call   f0100fb5 <page_alloc>
f0102a6b:	89 c6                	mov    %eax,%esi
f0102a6d:	83 c4 10             	add    $0x10,%esp
f0102a70:	85 c0                	test   %eax,%eax
f0102a72:	75 19                	jne    f0102a8d <mem_init+0x1758>
f0102a74:	68 3e 76 10 f0       	push   $0xf010763e
f0102a79:	68 4a 75 10 f0       	push   $0xf010754a
f0102a7e:	68 4b 04 00 00       	push   $0x44b
f0102a83:	68 15 75 10 f0       	push   $0xf0107515
f0102a88:	e8 b3 d5 ff ff       	call   f0100040 <_panic>
	page_free(pp0);
f0102a8d:	83 ec 0c             	sub    $0xc,%esp
f0102a90:	53                   	push   %ebx
f0102a91:	e8 96 e5 ff ff       	call   f010102c <page_free>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102a96:	89 f8                	mov    %edi,%eax
f0102a98:	2b 05 a8 9e 2a f0    	sub    0xf02a9ea8,%eax
f0102a9e:	c1 f8 03             	sar    $0x3,%eax
f0102aa1:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102aa4:	89 c2                	mov    %eax,%edx
f0102aa6:	c1 ea 0c             	shr    $0xc,%edx
f0102aa9:	83 c4 10             	add    $0x10,%esp
f0102aac:	3b 15 a0 9e 2a f0    	cmp    0xf02a9ea0,%edx
f0102ab2:	72 12                	jb     f0102ac6 <mem_init+0x1791>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102ab4:	50                   	push   %eax
f0102ab5:	68 44 66 10 f0       	push   $0xf0106644
f0102aba:	6a 58                	push   $0x58
f0102abc:	68 30 75 10 f0       	push   $0xf0107530
f0102ac1:	e8 7a d5 ff ff       	call   f0100040 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f0102ac6:	83 ec 04             	sub    $0x4,%esp
f0102ac9:	68 00 10 00 00       	push   $0x1000
f0102ace:	6a 01                	push   $0x1
f0102ad0:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102ad5:	50                   	push   %eax
f0102ad6:	e8 2e 29 00 00       	call   f0105409 <memset>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102adb:	89 f0                	mov    %esi,%eax
f0102add:	2b 05 a8 9e 2a f0    	sub    0xf02a9ea8,%eax
f0102ae3:	c1 f8 03             	sar    $0x3,%eax
f0102ae6:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102ae9:	89 c2                	mov    %eax,%edx
f0102aeb:	c1 ea 0c             	shr    $0xc,%edx
f0102aee:	83 c4 10             	add    $0x10,%esp
f0102af1:	3b 15 a0 9e 2a f0    	cmp    0xf02a9ea0,%edx
f0102af7:	72 12                	jb     f0102b0b <mem_init+0x17d6>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102af9:	50                   	push   %eax
f0102afa:	68 44 66 10 f0       	push   $0xf0106644
f0102aff:	6a 58                	push   $0x58
f0102b01:	68 30 75 10 f0       	push   $0xf0107530
f0102b06:	e8 35 d5 ff ff       	call   f0100040 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f0102b0b:	83 ec 04             	sub    $0x4,%esp
f0102b0e:	68 00 10 00 00       	push   $0x1000
f0102b13:	6a 02                	push   $0x2
f0102b15:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102b1a:	50                   	push   %eax
f0102b1b:	e8 e9 28 00 00       	call   f0105409 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102b20:	6a 02                	push   $0x2
f0102b22:	68 00 10 00 00       	push   $0x1000
f0102b27:	57                   	push   %edi
f0102b28:	ff 35 a4 9e 2a f0    	pushl  0xf02a9ea4
f0102b2e:	e8 27 e7 ff ff       	call   f010125a <page_insert>
	assert(pp1->pp_ref == 1);
f0102b33:	83 c4 20             	add    $0x20,%esp
f0102b36:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102b3b:	74 19                	je     f0102b56 <mem_init+0x1821>
f0102b3d:	68 0f 77 10 f0       	push   $0xf010770f
f0102b42:	68 4a 75 10 f0       	push   $0xf010754a
f0102b47:	68 50 04 00 00       	push   $0x450
f0102b4c:	68 15 75 10 f0       	push   $0xf0107515
f0102b51:	e8 ea d4 ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102b56:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102b5d:	01 01 01 
f0102b60:	74 19                	je     f0102b7b <mem_init+0x1846>
f0102b62:	68 40 74 10 f0       	push   $0xf0107440
f0102b67:	68 4a 75 10 f0       	push   $0xf010754a
f0102b6c:	68 51 04 00 00       	push   $0x451
f0102b71:	68 15 75 10 f0       	push   $0xf0107515
f0102b76:	e8 c5 d4 ff ff       	call   f0100040 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102b7b:	6a 02                	push   $0x2
f0102b7d:	68 00 10 00 00       	push   $0x1000
f0102b82:	56                   	push   %esi
f0102b83:	ff 35 a4 9e 2a f0    	pushl  0xf02a9ea4
f0102b89:	e8 cc e6 ff ff       	call   f010125a <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102b8e:	83 c4 10             	add    $0x10,%esp
f0102b91:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102b98:	02 02 02 
f0102b9b:	74 19                	je     f0102bb6 <mem_init+0x1881>
f0102b9d:	68 64 74 10 f0       	push   $0xf0107464
f0102ba2:	68 4a 75 10 f0       	push   $0xf010754a
f0102ba7:	68 53 04 00 00       	push   $0x453
f0102bac:	68 15 75 10 f0       	push   $0xf0107515
f0102bb1:	e8 8a d4 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0102bb6:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102bbb:	74 19                	je     f0102bd6 <mem_init+0x18a1>
f0102bbd:	68 31 77 10 f0       	push   $0xf0107731
f0102bc2:	68 4a 75 10 f0       	push   $0xf010754a
f0102bc7:	68 54 04 00 00       	push   $0x454
f0102bcc:	68 15 75 10 f0       	push   $0xf0107515
f0102bd1:	e8 6a d4 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f0102bd6:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102bdb:	74 19                	je     f0102bf6 <mem_init+0x18c1>
f0102bdd:	68 9b 77 10 f0       	push   $0xf010779b
f0102be2:	68 4a 75 10 f0       	push   $0xf010754a
f0102be7:	68 55 04 00 00       	push   $0x455
f0102bec:	68 15 75 10 f0       	push   $0xf0107515
f0102bf1:	e8 4a d4 ff ff       	call   f0100040 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102bf6:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102bfd:	03 03 03 
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102c00:	89 f0                	mov    %esi,%eax
f0102c02:	2b 05 a8 9e 2a f0    	sub    0xf02a9ea8,%eax
f0102c08:	c1 f8 03             	sar    $0x3,%eax
f0102c0b:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102c0e:	89 c2                	mov    %eax,%edx
f0102c10:	c1 ea 0c             	shr    $0xc,%edx
f0102c13:	3b 15 a0 9e 2a f0    	cmp    0xf02a9ea0,%edx
f0102c19:	72 12                	jb     f0102c2d <mem_init+0x18f8>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102c1b:	50                   	push   %eax
f0102c1c:	68 44 66 10 f0       	push   $0xf0106644
f0102c21:	6a 58                	push   $0x58
f0102c23:	68 30 75 10 f0       	push   $0xf0107530
f0102c28:	e8 13 d4 ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102c2d:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102c34:	03 03 03 
f0102c37:	74 19                	je     f0102c52 <mem_init+0x191d>
f0102c39:	68 88 74 10 f0       	push   $0xf0107488
f0102c3e:	68 4a 75 10 f0       	push   $0xf010754a
f0102c43:	68 57 04 00 00       	push   $0x457
f0102c48:	68 15 75 10 f0       	push   $0xf0107515
f0102c4d:	e8 ee d3 ff ff       	call   f0100040 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102c52:	83 ec 08             	sub    $0x8,%esp
f0102c55:	68 00 10 00 00       	push   $0x1000
f0102c5a:	ff 35 a4 9e 2a f0    	pushl  0xf02a9ea4
f0102c60:	e8 af e5 ff ff       	call   f0101214 <page_remove>
	assert(pp2->pp_ref == 0);
f0102c65:	83 c4 10             	add    $0x10,%esp
f0102c68:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102c6d:	74 19                	je     f0102c88 <mem_init+0x1953>
f0102c6f:	68 69 77 10 f0       	push   $0xf0107769
f0102c74:	68 4a 75 10 f0       	push   $0xf010754a
f0102c79:	68 59 04 00 00       	push   $0x459
f0102c7e:	68 15 75 10 f0       	push   $0xf0107515
f0102c83:	e8 b8 d3 ff ff       	call   f0100040 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102c88:	8b 0d a4 9e 2a f0    	mov    0xf02a9ea4,%ecx
f0102c8e:	8b 11                	mov    (%ecx),%edx
f0102c90:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102c96:	89 d8                	mov    %ebx,%eax
f0102c98:	2b 05 a8 9e 2a f0    	sub    0xf02a9ea8,%eax
f0102c9e:	c1 f8 03             	sar    $0x3,%eax
f0102ca1:	c1 e0 0c             	shl    $0xc,%eax
f0102ca4:	39 c2                	cmp    %eax,%edx
f0102ca6:	74 19                	je     f0102cc1 <mem_init+0x198c>
f0102ca8:	68 10 6e 10 f0       	push   $0xf0106e10
f0102cad:	68 4a 75 10 f0       	push   $0xf010754a
f0102cb2:	68 5c 04 00 00       	push   $0x45c
f0102cb7:	68 15 75 10 f0       	push   $0xf0107515
f0102cbc:	e8 7f d3 ff ff       	call   f0100040 <_panic>
	kern_pgdir[0] = 0;
f0102cc1:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102cc7:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102ccc:	74 19                	je     f0102ce7 <mem_init+0x19b2>
f0102cce:	68 20 77 10 f0       	push   $0xf0107720
f0102cd3:	68 4a 75 10 f0       	push   $0xf010754a
f0102cd8:	68 5e 04 00 00       	push   $0x45e
f0102cdd:	68 15 75 10 f0       	push   $0xf0107515
f0102ce2:	e8 59 d3 ff ff       	call   f0100040 <_panic>
	pp0->pp_ref = 0;
f0102ce7:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f0102ced:	83 ec 0c             	sub    $0xc,%esp
f0102cf0:	53                   	push   %ebx
f0102cf1:	e8 36 e3 ff ff       	call   f010102c <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102cf6:	c7 04 24 b4 74 10 f0 	movl   $0xf01074b4,(%esp)
f0102cfd:	e8 5b 09 00 00       	call   f010365d <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f0102d02:	83 c4 10             	add    $0x10,%esp
f0102d05:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102d08:	5b                   	pop    %ebx
f0102d09:	5e                   	pop    %esi
f0102d0a:	5f                   	pop    %edi
f0102d0b:	5d                   	pop    %ebp
f0102d0c:	c3                   	ret    

f0102d0d <user_mem_check>:
// Returns 0 if the user program can access this range of addresses,
// and -E_FAULT otherwise.
//
int
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
f0102d0d:	55                   	push   %ebp
f0102d0e:	89 e5                	mov    %esp,%ebp
f0102d10:	57                   	push   %edi
f0102d11:	56                   	push   %esi
f0102d12:	53                   	push   %ebx
f0102d13:	83 ec 2c             	sub    $0x2c,%esp
f0102d16:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// LAB 3: Your code here.
	void *vat =(void *) va;
	void *end =(void *)va + len;
f0102d19:	89 d8                	mov    %ebx,%eax
f0102d1b:	03 45 10             	add    0x10(%ebp),%eax
f0102d1e:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	int p = perm | PTE_P;
f0102d21:	8b 75 14             	mov    0x14(%ebp),%esi
f0102d24:	83 ce 01             	or     $0x1,%esi
	for (; vat < end; vat = ROUNDDOWN(vat+PGSIZE, PGSIZE)) {
		if ((uint32_t)vat > ULIM) {
			user_mem_check_addr =(uintptr_t) vat;
			return -E_FAULT;
		}
		page_lookup(env->env_pgdir, vat, &pte);
f0102d27:	8d 7d e4             	lea    -0x1c(%ebp),%edi
	// LAB 3: Your code here.
	void *vat =(void *) va;
	void *end =(void *)va + len;
	int p = perm | PTE_P;
	pte_t *pte;
	for (; vat < end; vat = ROUNDDOWN(vat+PGSIZE, PGSIZE)) {
f0102d2a:	eb 55                	jmp    f0102d81 <user_mem_check+0x74>
		if ((uint32_t)vat > ULIM) {
f0102d2c:	89 5d d0             	mov    %ebx,-0x30(%ebp)
f0102d2f:	81 fb 00 00 80 ef    	cmp    $0xef800000,%ebx
f0102d35:	76 0d                	jbe    f0102d44 <user_mem_check+0x37>
			user_mem_check_addr =(uintptr_t) vat;
f0102d37:	89 1d 3c 92 2a f0    	mov    %ebx,0xf02a923c
			return -E_FAULT;
f0102d3d:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0102d42:	eb 47                	jmp    f0102d8b <user_mem_check+0x7e>
		}
		page_lookup(env->env_pgdir, vat, &pte);
f0102d44:	83 ec 04             	sub    $0x4,%esp
f0102d47:	57                   	push   %edi
f0102d48:	53                   	push   %ebx
f0102d49:	8b 45 08             	mov    0x8(%ebp),%eax
f0102d4c:	ff 70 60             	pushl  0x60(%eax)
f0102d4f:	e8 31 e4 ff ff       	call   f0101185 <page_lookup>
		if (!(pte && ((*pte & p) == p))) {
f0102d54:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102d57:	83 c4 10             	add    $0x10,%esp
f0102d5a:	85 c0                	test   %eax,%eax
f0102d5c:	74 08                	je     f0102d66 <user_mem_check+0x59>
f0102d5e:	89 f2                	mov    %esi,%edx
f0102d60:	23 10                	and    (%eax),%edx
f0102d62:	39 d6                	cmp    %edx,%esi
f0102d64:	74 0f                	je     f0102d75 <user_mem_check+0x68>
			user_mem_check_addr = (uintptr_t) vat;
f0102d66:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102d69:	a3 3c 92 2a f0       	mov    %eax,0xf02a923c
			return -E_FAULT;
f0102d6e:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0102d73:	eb 16                	jmp    f0102d8b <user_mem_check+0x7e>
	// LAB 3: Your code here.
	void *vat =(void *) va;
	void *end =(void *)va + len;
	int p = perm | PTE_P;
	pte_t *pte;
	for (; vat < end; vat = ROUNDDOWN(vat+PGSIZE, PGSIZE)) {
f0102d75:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102d7b:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
f0102d81:	3b 5d d4             	cmp    -0x2c(%ebp),%ebx
f0102d84:	72 a6                	jb     f0102d2c <user_mem_check+0x1f>
			user_mem_check_addr = (uintptr_t) vat;
			return -E_FAULT;
		}
	}

	return 0;
f0102d86:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102d8b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102d8e:	5b                   	pop    %ebx
f0102d8f:	5e                   	pop    %esi
f0102d90:	5f                   	pop    %edi
f0102d91:	5d                   	pop    %ebp
f0102d92:	c3                   	ret    

f0102d93 <user_mem_assert>:
// If it cannot, 'env' is destroyed and, if env is the current
// environment, this function will not return.
//
void
user_mem_assert(struct Env *env, const void *va, size_t len, int perm)
{
f0102d93:	55                   	push   %ebp
f0102d94:	89 e5                	mov    %esp,%ebp
f0102d96:	53                   	push   %ebx
f0102d97:	83 ec 04             	sub    $0x4,%esp
f0102d9a:	8b 5d 08             	mov    0x8(%ebp),%ebx
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
f0102d9d:	8b 45 14             	mov    0x14(%ebp),%eax
f0102da0:	83 c8 04             	or     $0x4,%eax
f0102da3:	50                   	push   %eax
f0102da4:	ff 75 10             	pushl  0x10(%ebp)
f0102da7:	ff 75 0c             	pushl  0xc(%ebp)
f0102daa:	53                   	push   %ebx
f0102dab:	e8 5d ff ff ff       	call   f0102d0d <user_mem_check>
f0102db0:	83 c4 10             	add    $0x10,%esp
f0102db3:	85 c0                	test   %eax,%eax
f0102db5:	79 21                	jns    f0102dd8 <user_mem_assert+0x45>
		cprintf("[%08x] user_mem_check assertion failure for "
f0102db7:	83 ec 04             	sub    $0x4,%esp
f0102dba:	ff 35 3c 92 2a f0    	pushl  0xf02a923c
f0102dc0:	ff 73 48             	pushl  0x48(%ebx)
f0102dc3:	68 e0 74 10 f0       	push   $0xf01074e0
f0102dc8:	e8 90 08 00 00       	call   f010365d <cprintf>
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
f0102dcd:	89 1c 24             	mov    %ebx,(%esp)
f0102dd0:	e8 9d 05 00 00       	call   f0103372 <env_destroy>
f0102dd5:	83 c4 10             	add    $0x10,%esp
	}
}
f0102dd8:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102ddb:	c9                   	leave  
f0102ddc:	c3                   	ret    

f0102ddd <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f0102ddd:	55                   	push   %ebp
f0102dde:	89 e5                	mov    %esp,%ebp
f0102de0:	57                   	push   %edi
f0102de1:	56                   	push   %esi
f0102de2:	53                   	push   %ebx
f0102de3:	83 ec 0c             	sub    $0xc,%esp
f0102de6:	89 c7                	mov    %eax,%edi
	//
	// Hint: It is easier to use region_alloc if the caller can pass
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	void *va_t = ROUNDDOWN(va, PGSIZE);
f0102de8:	89 d3                	mov    %edx,%ebx
f0102dea:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx

	void *end = ROUNDUP(va + len, PGSIZE);
f0102df0:	8d b4 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%esi
f0102df7:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	for(; va_t < end;va_t += PGSIZE){
f0102dfd:	eb 3d                	jmp    f0102e3c <region_alloc+0x5f>
		struct PageInfo *pp = page_alloc(1);	
f0102dff:	83 ec 0c             	sub    $0xc,%esp
f0102e02:	6a 01                	push   $0x1
f0102e04:	e8 ac e1 ff ff       	call   f0100fb5 <page_alloc>
		if(pp == NULL){
f0102e09:	83 c4 10             	add    $0x10,%esp
f0102e0c:	85 c0                	test   %eax,%eax
f0102e0e:	75 17                	jne    f0102e27 <region_alloc+0x4a>
			panic("page alloc failed!\n");	
f0102e10:	83 ec 04             	sub    $0x4,%esp
f0102e13:	68 36 78 10 f0       	push   $0xf0107836
f0102e18:	68 29 01 00 00       	push   $0x129
f0102e1d:	68 4a 78 10 f0       	push   $0xf010784a
f0102e22:	e8 19 d2 ff ff       	call   f0100040 <_panic>
		}
		page_insert(e->env_pgdir, pp, va_t, PTE_U | PTE_W);	
f0102e27:	6a 06                	push   $0x6
f0102e29:	53                   	push   %ebx
f0102e2a:	50                   	push   %eax
f0102e2b:	ff 77 60             	pushl  0x60(%edi)
f0102e2e:	e8 27 e4 ff ff       	call   f010125a <page_insert>
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	void *va_t = ROUNDDOWN(va, PGSIZE);

	void *end = ROUNDUP(va + len, PGSIZE);
	for(; va_t < end;va_t += PGSIZE){
f0102e33:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102e39:	83 c4 10             	add    $0x10,%esp
f0102e3c:	39 f3                	cmp    %esi,%ebx
f0102e3e:	72 bf                	jb     f0102dff <region_alloc+0x22>
		if(pp == NULL){
			panic("page alloc failed!\n");	
		}
		page_insert(e->env_pgdir, pp, va_t, PTE_U | PTE_W);	
	}
}
f0102e40:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102e43:	5b                   	pop    %ebx
f0102e44:	5e                   	pop    %esi
f0102e45:	5f                   	pop    %edi
f0102e46:	5d                   	pop    %ebp
f0102e47:	c3                   	ret    

f0102e48 <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f0102e48:	55                   	push   %ebp
f0102e49:	89 e5                	mov    %esp,%ebp
f0102e4b:	56                   	push   %esi
f0102e4c:	53                   	push   %ebx
f0102e4d:	8b 45 08             	mov    0x8(%ebp),%eax
f0102e50:	8b 55 10             	mov    0x10(%ebp),%edx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f0102e53:	85 c0                	test   %eax,%eax
f0102e55:	75 1a                	jne    f0102e71 <envid2env+0x29>
		*env_store = curenv;
f0102e57:	e8 ce 2b 00 00       	call   f0105a2a <cpunum>
f0102e5c:	6b c0 74             	imul   $0x74,%eax,%eax
f0102e5f:	8b 80 28 a0 2a f0    	mov    -0xfd55fd8(%eax),%eax
f0102e65:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0102e68:	89 01                	mov    %eax,(%ecx)
		return 0;
f0102e6a:	b8 00 00 00 00       	mov    $0x0,%eax
f0102e6f:	eb 70                	jmp    f0102ee1 <envid2env+0x99>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f0102e71:	89 c3                	mov    %eax,%ebx
f0102e73:	81 e3 ff 03 00 00    	and    $0x3ff,%ebx
f0102e79:	6b db 7c             	imul   $0x7c,%ebx,%ebx
f0102e7c:	03 1d 44 92 2a f0    	add    0xf02a9244,%ebx
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f0102e82:	83 7b 54 00          	cmpl   $0x0,0x54(%ebx)
f0102e86:	74 05                	je     f0102e8d <envid2env+0x45>
f0102e88:	3b 43 48             	cmp    0x48(%ebx),%eax
f0102e8b:	74 10                	je     f0102e9d <envid2env+0x55>
		*env_store = 0;
f0102e8d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102e90:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0102e96:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0102e9b:	eb 44                	jmp    f0102ee1 <envid2env+0x99>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f0102e9d:	84 d2                	test   %dl,%dl
f0102e9f:	74 36                	je     f0102ed7 <envid2env+0x8f>
f0102ea1:	e8 84 2b 00 00       	call   f0105a2a <cpunum>
f0102ea6:	6b c0 74             	imul   $0x74,%eax,%eax
f0102ea9:	3b 98 28 a0 2a f0    	cmp    -0xfd55fd8(%eax),%ebx
f0102eaf:	74 26                	je     f0102ed7 <envid2env+0x8f>
f0102eb1:	8b 73 4c             	mov    0x4c(%ebx),%esi
f0102eb4:	e8 71 2b 00 00       	call   f0105a2a <cpunum>
f0102eb9:	6b c0 74             	imul   $0x74,%eax,%eax
f0102ebc:	8b 80 28 a0 2a f0    	mov    -0xfd55fd8(%eax),%eax
f0102ec2:	3b 70 48             	cmp    0x48(%eax),%esi
f0102ec5:	74 10                	je     f0102ed7 <envid2env+0x8f>
		*env_store = 0;
f0102ec7:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102eca:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0102ed0:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0102ed5:	eb 0a                	jmp    f0102ee1 <envid2env+0x99>
	}

	*env_store = e;
f0102ed7:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102eda:	89 18                	mov    %ebx,(%eax)
	return 0;
f0102edc:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102ee1:	5b                   	pop    %ebx
f0102ee2:	5e                   	pop    %esi
f0102ee3:	5d                   	pop    %ebp
f0102ee4:	c3                   	ret    

f0102ee5 <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f0102ee5:	55                   	push   %ebp
f0102ee6:	89 e5                	mov    %esp,%ebp
}

static inline void
lgdt(void *p)
{
	asm volatile("lgdt (%0)" : : "r" (p));
f0102ee8:	b8 20 23 12 f0       	mov    $0xf0122320,%eax
f0102eed:	0f 01 10             	lgdtl  (%eax)
	lgdt(&gdt_pd);
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" : : "a" (GD_UD|3));
f0102ef0:	b8 23 00 00 00       	mov    $0x23,%eax
f0102ef5:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" : : "a" (GD_UD|3));
f0102ef7:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" : : "a" (GD_KD));
f0102ef9:	b8 10 00 00 00       	mov    $0x10,%eax
f0102efe:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" : : "a" (GD_KD));
f0102f00:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" : : "a" (GD_KD));
f0102f02:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" : : "i" (GD_KT));
f0102f04:	ea 0b 2f 10 f0 08 00 	ljmp   $0x8,$0xf0102f0b
}

static inline void
lldt(uint16_t sel)
{
	asm volatile("lldt %0" : : "r" (sel));
f0102f0b:	b8 00 00 00 00       	mov    $0x0,%eax
f0102f10:	0f 00 d0             	lldt   %ax
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
}
f0102f13:	5d                   	pop    %ebp
f0102f14:	c3                   	ret    

f0102f15 <env_init>:
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f0102f15:	55                   	push   %ebp
f0102f16:	89 e5                	mov    %esp,%ebp
f0102f18:	56                   	push   %esi
f0102f19:	53                   	push   %ebx
	// Set up envs array
	// LAB 3: Your code here.
	for (int i = NENV - 1; i >= 0; i--) {
		envs[i].env_id = 0;
f0102f1a:	8b 35 44 92 2a f0    	mov    0xf02a9244,%esi
f0102f20:	8b 15 48 92 2a f0    	mov    0xf02a9248,%edx
f0102f26:	8d 86 84 ef 01 00    	lea    0x1ef84(%esi),%eax
f0102f2c:	8d 5e 84             	lea    -0x7c(%esi),%ebx
f0102f2f:	89 c1                	mov    %eax,%ecx
f0102f31:	c7 40 48 00 00 00 00 	movl   $0x0,0x48(%eax)
		envs[i].env_status = ENV_FREE;
f0102f38:	c7 40 54 00 00 00 00 	movl   $0x0,0x54(%eax)
		envs[i].env_link = env_free_list;
f0102f3f:	89 50 44             	mov    %edx,0x44(%eax)
f0102f42:	83 e8 7c             	sub    $0x7c,%eax
		env_free_list = &envs[i];
f0102f45:	89 ca                	mov    %ecx,%edx
void
env_init(void)
{
	// Set up envs array
	// LAB 3: Your code here.
	for (int i = NENV - 1; i >= 0; i--) {
f0102f47:	39 d8                	cmp    %ebx,%eax
f0102f49:	75 e4                	jne    f0102f2f <env_init+0x1a>
f0102f4b:	89 35 48 92 2a f0    	mov    %esi,0xf02a9248
		envs[i].env_link = env_free_list;
		env_free_list = &envs[i];
	}

	// Per-CPU part of the initialization
	env_init_percpu();
f0102f51:	e8 8f ff ff ff       	call   f0102ee5 <env_init_percpu>
}
f0102f56:	5b                   	pop    %ebx
f0102f57:	5e                   	pop    %esi
f0102f58:	5d                   	pop    %ebp
f0102f59:	c3                   	ret    

f0102f5a <env_alloc>:
//	-E_NO_FREE_ENV if all NENVS environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f0102f5a:	55                   	push   %ebp
f0102f5b:	89 e5                	mov    %esp,%ebp
f0102f5d:	53                   	push   %ebx
f0102f5e:	83 ec 04             	sub    $0x4,%esp
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f0102f61:	8b 1d 48 92 2a f0    	mov    0xf02a9248,%ebx
f0102f67:	85 db                	test   %ebx,%ebx
f0102f69:	0f 84 32 01 00 00    	je     f01030a1 <env_alloc+0x147>
{
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
f0102f6f:	83 ec 0c             	sub    $0xc,%esp
f0102f72:	6a 01                	push   $0x1
f0102f74:	e8 3c e0 ff ff       	call   f0100fb5 <page_alloc>
f0102f79:	83 c4 10             	add    $0x10,%esp
f0102f7c:	85 c0                	test   %eax,%eax
f0102f7e:	0f 84 24 01 00 00    	je     f01030a8 <env_alloc+0x14e>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102f84:	89 c2                	mov    %eax,%edx
f0102f86:	2b 15 a8 9e 2a f0    	sub    0xf02a9ea8,%edx
f0102f8c:	c1 fa 03             	sar    $0x3,%edx
f0102f8f:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102f92:	89 d1                	mov    %edx,%ecx
f0102f94:	c1 e9 0c             	shr    $0xc,%ecx
f0102f97:	3b 0d a0 9e 2a f0    	cmp    0xf02a9ea0,%ecx
f0102f9d:	72 12                	jb     f0102fb1 <env_alloc+0x57>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102f9f:	52                   	push   %edx
f0102fa0:	68 44 66 10 f0       	push   $0xf0106644
f0102fa5:	6a 58                	push   $0x58
f0102fa7:	68 30 75 10 f0       	push   $0xf0107530
f0102fac:	e8 8f d0 ff ff       	call   f0100040 <_panic>
	//	is an exception -- you need to increment env_pgdir's
	//	pp_ref for env_free to work correctly.
	//    - The functions in kern/pmap.h are handy.

	// LAB 3: Your code here.
	e->env_pgdir = page2kva(p);
f0102fb1:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f0102fb7:	89 53 60             	mov    %edx,0x60(%ebx)
	p->pp_ref++;
f0102fba:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
	memcpy(e->env_pgdir, kern_pgdir, PGSIZE);
f0102fbf:	83 ec 04             	sub    $0x4,%esp
f0102fc2:	68 00 10 00 00       	push   $0x1000
f0102fc7:	ff 35 a4 9e 2a f0    	pushl  0xf02a9ea4
f0102fcd:	ff 73 60             	pushl  0x60(%ebx)
f0102fd0:	e8 e9 24 00 00       	call   f01054be <memcpy>

	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f0102fd5:	8b 43 60             	mov    0x60(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102fd8:	83 c4 10             	add    $0x10,%esp
f0102fdb:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102fe0:	77 15                	ja     f0102ff7 <env_alloc+0x9d>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102fe2:	50                   	push   %eax
f0102fe3:	68 68 66 10 f0       	push   $0xf0106668
f0102fe8:	68 c5 00 00 00       	push   $0xc5
f0102fed:	68 4a 78 10 f0       	push   $0xf010784a
f0102ff2:	e8 49 d0 ff ff       	call   f0100040 <_panic>
f0102ff7:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0102ffd:	83 ca 05             	or     $0x5,%edx
f0103000:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f0103006:	8b 43 48             	mov    0x48(%ebx),%eax
f0103009:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f010300e:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f0103013:	ba 00 10 00 00       	mov    $0x1000,%edx
f0103018:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f010301b:	89 da                	mov    %ebx,%edx
f010301d:	2b 15 44 92 2a f0    	sub    0xf02a9244,%edx
f0103023:	c1 fa 02             	sar    $0x2,%edx
f0103026:	69 d2 df 7b ef bd    	imul   $0xbdef7bdf,%edx,%edx
f010302c:	09 d0                	or     %edx,%eax
f010302e:	89 43 48             	mov    %eax,0x48(%ebx)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f0103031:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103034:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f0103037:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f010303e:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f0103045:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f010304c:	83 ec 04             	sub    $0x4,%esp
f010304f:	6a 44                	push   $0x44
f0103051:	6a 00                	push   $0x0
f0103053:	53                   	push   %ebx
f0103054:	e8 b0 23 00 00       	call   f0105409 <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f0103059:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f010305f:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f0103065:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f010306b:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f0103072:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)
	// You will set e->env_tf.tf_eip later.

	// Enable interrupts while in user mode.
	// LAB 4: Your code here.
    e->env_tf.tf_eflags |= FL_IF;
f0103078:	81 4b 38 00 02 00 00 	orl    $0x200,0x38(%ebx)
	// Clear the page fault handler until user installs one.
	e->env_pgfault_upcall = 0;
f010307f:	c7 43 64 00 00 00 00 	movl   $0x0,0x64(%ebx)

	// Also clear the IPC receiving flag.
	e->env_ipc_recving = 0;
f0103086:	c6 43 68 00          	movb   $0x0,0x68(%ebx)

	// commit the allocation
	env_free_list = e->env_link;
f010308a:	8b 43 44             	mov    0x44(%ebx),%eax
f010308d:	a3 48 92 2a f0       	mov    %eax,0xf02a9248
	*newenv_store = e;
f0103092:	8b 45 08             	mov    0x8(%ebp),%eax
f0103095:	89 18                	mov    %ebx,(%eax)

	// cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
f0103097:	83 c4 10             	add    $0x10,%esp
f010309a:	b8 00 00 00 00       	mov    $0x0,%eax
f010309f:	eb 0c                	jmp    f01030ad <env_alloc+0x153>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f01030a1:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f01030a6:	eb 05                	jmp    f01030ad <env_alloc+0x153>
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f01030a8:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	env_free_list = e->env_link;
	*newenv_store = e;

	// cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f01030ad:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01030b0:	c9                   	leave  
f01030b1:	c3                   	ret    

f01030b2 <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f01030b2:	55                   	push   %ebp
f01030b3:	89 e5                	mov    %esp,%ebp
f01030b5:	57                   	push   %edi
f01030b6:	56                   	push   %esi
f01030b7:	53                   	push   %ebx
f01030b8:	83 ec 34             	sub    $0x34,%esp
f01030bb:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.
	struct Env *e;
	env_alloc(&e, 0);
f01030be:	6a 00                	push   $0x0
f01030c0:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01030c3:	50                   	push   %eax
f01030c4:	e8 91 fe ff ff       	call   f0102f5a <env_alloc>
	load_icode(e, binary);
f01030c9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01030cc:	89 45 d4             	mov    %eax,-0x2c(%ebp)

	// LAB 3: Your code here.
	
	struct Elf *elf = (struct Elf *) binary;

	if (elf->e_magic != ELF_MAGIC)
f01030cf:	83 c4 10             	add    $0x10,%esp
f01030d2:	81 3f 7f 45 4c 46    	cmpl   $0x464c457f,(%edi)
f01030d8:	74 17                	je     f01030f1 <env_create+0x3f>
		panic("load_icode: not ELF executable.");
f01030da:	83 ec 04             	sub    $0x4,%esp
f01030dd:	68 64 78 10 f0       	push   $0xf0107864
f01030e2:	68 69 01 00 00       	push   $0x169
f01030e7:	68 4a 78 10 f0       	push   $0xf010784a
f01030ec:	e8 4f cf ff ff       	call   f0100040 <_panic>

	struct Proghdr *ph = (struct Proghdr *) (elf->e_phoff + binary);
f01030f1:	89 fb                	mov    %edi,%ebx
f01030f3:	03 5f 1c             	add    0x1c(%edi),%ebx
	struct Proghdr *eph = ph + elf->e_phnum;
f01030f6:	0f b7 77 2c          	movzwl 0x2c(%edi),%esi
f01030fa:	c1 e6 05             	shl    $0x5,%esi
f01030fd:	01 de                	add    %ebx,%esi

	lcr3(PADDR(e->env_pgdir));
f01030ff:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103102:	8b 40 60             	mov    0x60(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103105:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010310a:	77 15                	ja     f0103121 <env_create+0x6f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010310c:	50                   	push   %eax
f010310d:	68 68 66 10 f0       	push   $0xf0106668
f0103112:	68 6e 01 00 00       	push   $0x16e
f0103117:	68 4a 78 10 f0       	push   $0xf010784a
f010311c:	e8 1f cf ff ff       	call   f0100040 <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0103121:	05 00 00 00 10       	add    $0x10000000,%eax
f0103126:	0f 22 d8             	mov    %eax,%cr3
f0103129:	eb 3d                	jmp    f0103168 <env_create+0xb6>
	for(; ph < eph; ph++){
		if(ph->p_type == ELF_PROG_LOAD){
f010312b:	83 3b 01             	cmpl   $0x1,(%ebx)
f010312e:	75 35                	jne    f0103165 <env_create+0xb3>
			region_alloc(e, (void *) ph->p_va, ph->p_memsz);
f0103130:	8b 4b 14             	mov    0x14(%ebx),%ecx
f0103133:	8b 53 08             	mov    0x8(%ebx),%edx
f0103136:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103139:	e8 9f fc ff ff       	call   f0102ddd <region_alloc>
			memset((void *) ph->p_va, 0, ph->p_memsz);
f010313e:	83 ec 04             	sub    $0x4,%esp
f0103141:	ff 73 14             	pushl  0x14(%ebx)
f0103144:	6a 00                	push   $0x0
f0103146:	ff 73 08             	pushl  0x8(%ebx)
f0103149:	e8 bb 22 00 00       	call   f0105409 <memset>
			memcpy((void *) ph->p_va, binary + ph->p_offset, ph->p_filesz);
f010314e:	83 c4 0c             	add    $0xc,%esp
f0103151:	ff 73 10             	pushl  0x10(%ebx)
f0103154:	89 f8                	mov    %edi,%eax
f0103156:	03 43 04             	add    0x4(%ebx),%eax
f0103159:	50                   	push   %eax
f010315a:	ff 73 08             	pushl  0x8(%ebx)
f010315d:	e8 5c 23 00 00       	call   f01054be <memcpy>
f0103162:	83 c4 10             	add    $0x10,%esp

	struct Proghdr *ph = (struct Proghdr *) (elf->e_phoff + binary);
	struct Proghdr *eph = ph + elf->e_phnum;

	lcr3(PADDR(e->env_pgdir));
	for(; ph < eph; ph++){
f0103165:	83 c3 20             	add    $0x20,%ebx
f0103168:	39 de                	cmp    %ebx,%esi
f010316a:	77 bf                	ja     f010312b <env_create+0x79>
			region_alloc(e, (void *) ph->p_va, ph->p_memsz);
			memset((void *) ph->p_va, 0, ph->p_memsz);
			memcpy((void *) ph->p_va, binary + ph->p_offset, ph->p_filesz);
		}
	}
	lcr3(PADDR(kern_pgdir));
f010316c:	a1 a4 9e 2a f0       	mov    0xf02a9ea4,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103171:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103176:	77 15                	ja     f010318d <env_create+0xdb>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103178:	50                   	push   %eax
f0103179:	68 68 66 10 f0       	push   $0xf0106668
f010317e:	68 76 01 00 00       	push   $0x176
f0103183:	68 4a 78 10 f0       	push   $0xf010784a
f0103188:	e8 b3 ce ff ff       	call   f0100040 <_panic>
f010318d:	05 00 00 00 10       	add    $0x10000000,%eax
f0103192:	0f 22 d8             	mov    %eax,%cr3
	e->env_tf.tf_eip = elf->e_entry;
f0103195:	8b 47 18             	mov    0x18(%edi),%eax
f0103198:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010319b:	89 47 30             	mov    %eax,0x30(%edi)
	// Now map one page for the program's initial stack
	// at virtual address USTACKTOP - PGSIZE.

	// LAB 3: Your code here.
	region_alloc(e, (void *) (USTACKTOP - PGSIZE), PGSIZE);
f010319e:	b9 00 10 00 00       	mov    $0x1000,%ecx
f01031a3:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f01031a8:	89 f8                	mov    %edi,%eax
f01031aa:	e8 2e fc ff ff       	call   f0102ddd <region_alloc>
{
	// LAB 3: Your code here.
	struct Env *e;
	env_alloc(&e, 0);
	load_icode(e, binary);
	e->env_type = type;
f01031af:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01031b2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01031b5:	89 48 50             	mov    %ecx,0x50(%eax)

	// If this is the file server (type == ENV_TYPE_FS) give it I/O privileges.
	// LAB 5: Your code here.
    if(type == ENV_TYPE_FS){
f01031b8:	83 f9 01             	cmp    $0x1,%ecx
f01031bb:	75 07                	jne    f01031c4 <env_create+0x112>
        e->env_tf.tf_eflags |= FL_IOPL_3; 
f01031bd:	81 48 38 00 30 00 00 	orl    $0x3000,0x38(%eax)
    }
}
f01031c4:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01031c7:	5b                   	pop    %ebx
f01031c8:	5e                   	pop    %esi
f01031c9:	5f                   	pop    %edi
f01031ca:	5d                   	pop    %ebp
f01031cb:	c3                   	ret    

f01031cc <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f01031cc:	55                   	push   %ebp
f01031cd:	89 e5                	mov    %esp,%ebp
f01031cf:	57                   	push   %edi
f01031d0:	56                   	push   %esi
f01031d1:	53                   	push   %ebx
f01031d2:	83 ec 1c             	sub    $0x1c,%esp
f01031d5:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f01031d8:	e8 4d 28 00 00       	call   f0105a2a <cpunum>
f01031dd:	6b c0 74             	imul   $0x74,%eax,%eax
f01031e0:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f01031e7:	39 b8 28 a0 2a f0    	cmp    %edi,-0xfd55fd8(%eax)
f01031ed:	75 30                	jne    f010321f <env_free+0x53>
		lcr3(PADDR(kern_pgdir));
f01031ef:	a1 a4 9e 2a f0       	mov    0xf02a9ea4,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01031f4:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01031f9:	77 15                	ja     f0103210 <env_free+0x44>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01031fb:	50                   	push   %eax
f01031fc:	68 68 66 10 f0       	push   $0xf0106668
f0103201:	68 a5 01 00 00       	push   $0x1a5
f0103206:	68 4a 78 10 f0       	push   $0xf010784a
f010320b:	e8 30 ce ff ff       	call   f0100040 <_panic>
f0103210:	05 00 00 00 10       	add    $0x10000000,%eax
f0103215:	0f 22 d8             	mov    %eax,%cr3
f0103218:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f010321f:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0103222:	89 d0                	mov    %edx,%eax
f0103224:	c1 e0 02             	shl    $0x2,%eax
f0103227:	89 45 dc             	mov    %eax,-0x24(%ebp)
	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f010322a:	8b 47 60             	mov    0x60(%edi),%eax
f010322d:	8b 34 90             	mov    (%eax,%edx,4),%esi
f0103230:	f7 c6 01 00 00 00    	test   $0x1,%esi
f0103236:	0f 84 a8 00 00 00    	je     f01032e4 <env_free+0x118>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f010323c:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103242:	89 f0                	mov    %esi,%eax
f0103244:	c1 e8 0c             	shr    $0xc,%eax
f0103247:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010324a:	39 05 a0 9e 2a f0    	cmp    %eax,0xf02a9ea0
f0103250:	77 15                	ja     f0103267 <env_free+0x9b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0103252:	56                   	push   %esi
f0103253:	68 44 66 10 f0       	push   $0xf0106644
f0103258:	68 b4 01 00 00       	push   $0x1b4
f010325d:	68 4a 78 10 f0       	push   $0xf010784a
f0103262:	e8 d9 cd ff ff       	call   f0100040 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0103267:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010326a:	c1 e0 16             	shl    $0x16,%eax
f010326d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0103270:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f0103275:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f010327c:	01 
f010327d:	74 17                	je     f0103296 <env_free+0xca>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f010327f:	83 ec 08             	sub    $0x8,%esp
f0103282:	89 d8                	mov    %ebx,%eax
f0103284:	c1 e0 0c             	shl    $0xc,%eax
f0103287:	0b 45 e4             	or     -0x1c(%ebp),%eax
f010328a:	50                   	push   %eax
f010328b:	ff 77 60             	pushl  0x60(%edi)
f010328e:	e8 81 df ff ff       	call   f0101214 <page_remove>
f0103293:	83 c4 10             	add    $0x10,%esp
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0103296:	83 c3 01             	add    $0x1,%ebx
f0103299:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f010329f:	75 d4                	jne    f0103275 <env_free+0xa9>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f01032a1:	8b 47 60             	mov    0x60(%edi),%eax
f01032a4:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01032a7:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01032ae:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01032b1:	3b 05 a0 9e 2a f0    	cmp    0xf02a9ea0,%eax
f01032b7:	72 14                	jb     f01032cd <env_free+0x101>
		panic("pa2page called with invalid pa");
f01032b9:	83 ec 04             	sub    $0x4,%esp
f01032bc:	68 b0 6c 10 f0       	push   $0xf0106cb0
f01032c1:	6a 51                	push   $0x51
f01032c3:	68 30 75 10 f0       	push   $0xf0107530
f01032c8:	e8 73 cd ff ff       	call   f0100040 <_panic>
		page_decref(pa2page(pa));
f01032cd:	83 ec 0c             	sub    $0xc,%esp
f01032d0:	a1 a8 9e 2a f0       	mov    0xf02a9ea8,%eax
f01032d5:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01032d8:	8d 04 d0             	lea    (%eax,%edx,8),%eax
f01032db:	50                   	push   %eax
f01032dc:	e8 86 dd ff ff       	call   f0101067 <page_decref>
f01032e1:	83 c4 10             	add    $0x10,%esp
	// Note the environment's demise.
	// cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f01032e4:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f01032e8:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01032eb:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f01032f0:	0f 85 29 ff ff ff    	jne    f010321f <env_free+0x53>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f01032f6:	8b 47 60             	mov    0x60(%edi),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01032f9:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01032fe:	77 15                	ja     f0103315 <env_free+0x149>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103300:	50                   	push   %eax
f0103301:	68 68 66 10 f0       	push   $0xf0106668
f0103306:	68 c2 01 00 00       	push   $0x1c2
f010330b:	68 4a 78 10 f0       	push   $0xf010784a
f0103310:	e8 2b cd ff ff       	call   f0100040 <_panic>
	e->env_pgdir = 0;
f0103315:	c7 47 60 00 00 00 00 	movl   $0x0,0x60(%edi)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010331c:	05 00 00 00 10       	add    $0x10000000,%eax
f0103321:	c1 e8 0c             	shr    $0xc,%eax
f0103324:	3b 05 a0 9e 2a f0    	cmp    0xf02a9ea0,%eax
f010332a:	72 14                	jb     f0103340 <env_free+0x174>
		panic("pa2page called with invalid pa");
f010332c:	83 ec 04             	sub    $0x4,%esp
f010332f:	68 b0 6c 10 f0       	push   $0xf0106cb0
f0103334:	6a 51                	push   $0x51
f0103336:	68 30 75 10 f0       	push   $0xf0107530
f010333b:	e8 00 cd ff ff       	call   f0100040 <_panic>
	page_decref(pa2page(pa));
f0103340:	83 ec 0c             	sub    $0xc,%esp
f0103343:	8b 15 a8 9e 2a f0    	mov    0xf02a9ea8,%edx
f0103349:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f010334c:	50                   	push   %eax
f010334d:	e8 15 dd ff ff       	call   f0101067 <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f0103352:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f0103359:	a1 48 92 2a f0       	mov    0xf02a9248,%eax
f010335e:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f0103361:	89 3d 48 92 2a f0    	mov    %edi,0xf02a9248
}
f0103367:	83 c4 10             	add    $0x10,%esp
f010336a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010336d:	5b                   	pop    %ebx
f010336e:	5e                   	pop    %esi
f010336f:	5f                   	pop    %edi
f0103370:	5d                   	pop    %ebp
f0103371:	c3                   	ret    

f0103372 <env_destroy>:
// If e was the current env, then runs a new environment (and does not return
// to the caller).
//
void
env_destroy(struct Env *e)
{
f0103372:	55                   	push   %ebp
f0103373:	89 e5                	mov    %esp,%ebp
f0103375:	53                   	push   %ebx
f0103376:	83 ec 04             	sub    $0x4,%esp
f0103379:	8b 5d 08             	mov    0x8(%ebp),%ebx
	// If e is currently running on other CPUs, we change its state to
	// ENV_DYING. A zombie environment will be freed the next time
	// it traps to the kernel.
	if (e->env_status == ENV_RUNNING && curenv != e) {
f010337c:	83 7b 54 03          	cmpl   $0x3,0x54(%ebx)
f0103380:	75 19                	jne    f010339b <env_destroy+0x29>
f0103382:	e8 a3 26 00 00       	call   f0105a2a <cpunum>
f0103387:	6b c0 74             	imul   $0x74,%eax,%eax
f010338a:	3b 98 28 a0 2a f0    	cmp    -0xfd55fd8(%eax),%ebx
f0103390:	74 09                	je     f010339b <env_destroy+0x29>
		e->env_status = ENV_DYING;
f0103392:	c7 43 54 01 00 00 00 	movl   $0x1,0x54(%ebx)
		return;
f0103399:	eb 33                	jmp    f01033ce <env_destroy+0x5c>
	}

	env_free(e);
f010339b:	83 ec 0c             	sub    $0xc,%esp
f010339e:	53                   	push   %ebx
f010339f:	e8 28 fe ff ff       	call   f01031cc <env_free>

	if (curenv == e) {
f01033a4:	e8 81 26 00 00       	call   f0105a2a <cpunum>
f01033a9:	6b c0 74             	imul   $0x74,%eax,%eax
f01033ac:	83 c4 10             	add    $0x10,%esp
f01033af:	3b 98 28 a0 2a f0    	cmp    -0xfd55fd8(%eax),%ebx
f01033b5:	75 17                	jne    f01033ce <env_destroy+0x5c>
		curenv = NULL;
f01033b7:	e8 6e 26 00 00       	call   f0105a2a <cpunum>
f01033bc:	6b c0 74             	imul   $0x74,%eax,%eax
f01033bf:	c7 80 28 a0 2a f0 00 	movl   $0x0,-0xfd55fd8(%eax)
f01033c6:	00 00 00 
		sched_yield();
f01033c9:	e8 89 0e 00 00       	call   f0104257 <sched_yield>
	}
}
f01033ce:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01033d1:	c9                   	leave  
f01033d2:	c3                   	ret    

f01033d3 <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f01033d3:	55                   	push   %ebp
f01033d4:	89 e5                	mov    %esp,%ebp
f01033d6:	53                   	push   %ebx
f01033d7:	83 ec 04             	sub    $0x4,%esp
	// Record the CPU we are running on for user-space debugging
	curenv->env_cpunum = cpunum();
f01033da:	e8 4b 26 00 00       	call   f0105a2a <cpunum>
f01033df:	6b c0 74             	imul   $0x74,%eax,%eax
f01033e2:	8b 98 28 a0 2a f0    	mov    -0xfd55fd8(%eax),%ebx
f01033e8:	e8 3d 26 00 00       	call   f0105a2a <cpunum>
f01033ed:	89 43 5c             	mov    %eax,0x5c(%ebx)

	asm volatile(
f01033f0:	8b 65 08             	mov    0x8(%ebp),%esp
f01033f3:	61                   	popa   
f01033f4:	07                   	pop    %es
f01033f5:	1f                   	pop    %ds
f01033f6:	83 c4 08             	add    $0x8,%esp
f01033f9:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret\n"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f01033fa:	83 ec 04             	sub    $0x4,%esp
f01033fd:	68 55 78 10 f0       	push   $0xf0107855
f0103402:	68 f9 01 00 00       	push   $0x1f9
f0103407:	68 4a 78 10 f0       	push   $0xf010784a
f010340c:	e8 2f cc ff ff       	call   f0100040 <_panic>

f0103411 <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f0103411:	55                   	push   %ebp
f0103412:	89 e5                	mov    %esp,%ebp
f0103414:	53                   	push   %ebx
f0103415:	83 ec 04             	sub    $0x4,%esp
f0103418:	8b 5d 08             	mov    0x8(%ebp),%ebx
	//	e->env_tf.  Go back through the code you wrote above
	//	and make sure you have set the relevant parts of
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.
	if(curenv != NULL){
f010341b:	e8 0a 26 00 00       	call   f0105a2a <cpunum>
f0103420:	6b c0 74             	imul   $0x74,%eax,%eax
f0103423:	83 b8 28 a0 2a f0 00 	cmpl   $0x0,-0xfd55fd8(%eax)
f010342a:	74 29                	je     f0103455 <env_run+0x44>
		if(curenv->env_status == ENV_RUNNING)
f010342c:	e8 f9 25 00 00       	call   f0105a2a <cpunum>
f0103431:	6b c0 74             	imul   $0x74,%eax,%eax
f0103434:	8b 80 28 a0 2a f0    	mov    -0xfd55fd8(%eax),%eax
f010343a:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f010343e:	75 15                	jne    f0103455 <env_run+0x44>
			curenv->env_status = ENV_RUNNABLE;
f0103440:	e8 e5 25 00 00       	call   f0105a2a <cpunum>
f0103445:	6b c0 74             	imul   $0x74,%eax,%eax
f0103448:	8b 80 28 a0 2a f0    	mov    -0xfd55fd8(%eax),%eax
f010344e:	c7 40 54 02 00 00 00 	movl   $0x2,0x54(%eax)
	}
	curenv = e;
f0103455:	e8 d0 25 00 00       	call   f0105a2a <cpunum>
f010345a:	6b c0 74             	imul   $0x74,%eax,%eax
f010345d:	89 98 28 a0 2a f0    	mov    %ebx,-0xfd55fd8(%eax)
	curenv->env_status = ENV_RUNNING;
f0103463:	e8 c2 25 00 00       	call   f0105a2a <cpunum>
f0103468:	6b c0 74             	imul   $0x74,%eax,%eax
f010346b:	8b 80 28 a0 2a f0    	mov    -0xfd55fd8(%eax),%eax
f0103471:	c7 40 54 03 00 00 00 	movl   $0x3,0x54(%eax)
	curenv->env_runs ++;
f0103478:	e8 ad 25 00 00       	call   f0105a2a <cpunum>
f010347d:	6b c0 74             	imul   $0x74,%eax,%eax
f0103480:	8b 80 28 a0 2a f0    	mov    -0xfd55fd8(%eax),%eax
f0103486:	83 40 58 01          	addl   $0x1,0x58(%eax)
	lcr3(PADDR(e->env_pgdir));
f010348a:	8b 43 60             	mov    0x60(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010348d:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103492:	77 15                	ja     f01034a9 <env_run+0x98>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103494:	50                   	push   %eax
f0103495:	68 68 66 10 f0       	push   $0xf0106668
f010349a:	68 1e 02 00 00       	push   $0x21e
f010349f:	68 4a 78 10 f0       	push   $0xf010784a
f01034a4:	e8 97 cb ff ff       	call   f0100040 <_panic>
f01034a9:	05 00 00 00 10       	add    $0x10000000,%eax
f01034ae:	0f 22 d8             	mov    %eax,%cr3
}

static inline void
unlock_kernel(void)
{
	spin_unlock(&kernel_lock);
f01034b1:	83 ec 0c             	sub    $0xc,%esp
f01034b4:	68 c0 23 12 f0       	push   $0xf01223c0
f01034b9:	e8 77 28 00 00       	call   f0105d35 <spin_unlock>

	// Normally we wouldn't need to do this, but QEMU only runs
	// one CPU at a time and has a long time-slice.  Without the
	// pause, this CPU is likely to reacquire the lock before
	// another CPU has even been given a chance to acquire it.
	asm volatile("pause");
f01034be:	f3 90                	pause  
    unlock_kernel();
	env_pop_tf(&e->env_tf);
f01034c0:	89 1c 24             	mov    %ebx,(%esp)
f01034c3:	e8 0b ff ff ff       	call   f01033d3 <env_pop_tf>

f01034c8 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f01034c8:	55                   	push   %ebp
f01034c9:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01034cb:	ba 70 00 00 00       	mov    $0x70,%edx
f01034d0:	8b 45 08             	mov    0x8(%ebp),%eax
f01034d3:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01034d4:	ba 71 00 00 00       	mov    $0x71,%edx
f01034d9:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f01034da:	0f b6 c0             	movzbl %al,%eax
}
f01034dd:	5d                   	pop    %ebp
f01034de:	c3                   	ret    

f01034df <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
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
f01034eb:	ba 71 00 00 00       	mov    $0x71,%edx
f01034f0:	8b 45 0c             	mov    0xc(%ebp),%eax
f01034f3:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f01034f4:	5d                   	pop    %ebp
f01034f5:	c3                   	ret    

f01034f6 <irq_setmask_8259A>:
		irq_setmask_8259A(irq_mask_8259A);
}

void
irq_setmask_8259A(uint16_t mask)
{
f01034f6:	55                   	push   %ebp
f01034f7:	89 e5                	mov    %esp,%ebp
f01034f9:	56                   	push   %esi
f01034fa:	53                   	push   %ebx
f01034fb:	8b 45 08             	mov    0x8(%ebp),%eax
	int i;
	irq_mask_8259A = mask;
f01034fe:	66 a3 a8 23 12 f0    	mov    %ax,0xf01223a8
	if (!didinit)
f0103504:	80 3d 4c 92 2a f0 00 	cmpb   $0x0,0xf02a924c
f010350b:	74 5a                	je     f0103567 <irq_setmask_8259A+0x71>
f010350d:	89 c6                	mov    %eax,%esi
f010350f:	ba 21 00 00 00       	mov    $0x21,%edx
f0103514:	ee                   	out    %al,(%dx)
f0103515:	66 c1 e8 08          	shr    $0x8,%ax
f0103519:	ba a1 00 00 00       	mov    $0xa1,%edx
f010351e:	ee                   	out    %al,(%dx)
		return;
	outb(IO_PIC1+1, (char)mask);
	outb(IO_PIC2+1, (char)(mask >> 8));
	cprintf("enabled interrupts:");
f010351f:	83 ec 0c             	sub    $0xc,%esp
f0103522:	68 84 78 10 f0       	push   $0xf0107884
f0103527:	e8 31 01 00 00       	call   f010365d <cprintf>
f010352c:	83 c4 10             	add    $0x10,%esp
	for (i = 0; i < 16; i++)
f010352f:	bb 00 00 00 00       	mov    $0x0,%ebx
		if (~mask & (1<<i))
f0103534:	0f b7 f6             	movzwl %si,%esi
f0103537:	f7 d6                	not    %esi
f0103539:	0f a3 de             	bt     %ebx,%esi
f010353c:	73 11                	jae    f010354f <irq_setmask_8259A+0x59>
			cprintf(" %d", i);
f010353e:	83 ec 08             	sub    $0x8,%esp
f0103541:	53                   	push   %ebx
f0103542:	68 a6 7d 10 f0       	push   $0xf0107da6
f0103547:	e8 11 01 00 00       	call   f010365d <cprintf>
f010354c:	83 c4 10             	add    $0x10,%esp
	if (!didinit)
		return;
	outb(IO_PIC1+1, (char)mask);
	outb(IO_PIC2+1, (char)(mask >> 8));
	cprintf("enabled interrupts:");
	for (i = 0; i < 16; i++)
f010354f:	83 c3 01             	add    $0x1,%ebx
f0103552:	83 fb 10             	cmp    $0x10,%ebx
f0103555:	75 e2                	jne    f0103539 <irq_setmask_8259A+0x43>
		if (~mask & (1<<i))
			cprintf(" %d", i);
	cprintf("\n");
f0103557:	83 ec 0c             	sub    $0xc,%esp
f010355a:	68 04 78 10 f0       	push   $0xf0107804
f010355f:	e8 f9 00 00 00       	call   f010365d <cprintf>
f0103564:	83 c4 10             	add    $0x10,%esp
}
f0103567:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010356a:	5b                   	pop    %ebx
f010356b:	5e                   	pop    %esi
f010356c:	5d                   	pop    %ebp
f010356d:	c3                   	ret    

f010356e <pic_init>:

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
	didinit = 1;
f010356e:	c6 05 4c 92 2a f0 01 	movb   $0x1,0xf02a924c
f0103575:	ba 21 00 00 00       	mov    $0x21,%edx
f010357a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010357f:	ee                   	out    %al,(%dx)
f0103580:	ba a1 00 00 00       	mov    $0xa1,%edx
f0103585:	ee                   	out    %al,(%dx)
f0103586:	ba 20 00 00 00       	mov    $0x20,%edx
f010358b:	b8 11 00 00 00       	mov    $0x11,%eax
f0103590:	ee                   	out    %al,(%dx)
f0103591:	ba 21 00 00 00       	mov    $0x21,%edx
f0103596:	b8 20 00 00 00       	mov    $0x20,%eax
f010359b:	ee                   	out    %al,(%dx)
f010359c:	b8 04 00 00 00       	mov    $0x4,%eax
f01035a1:	ee                   	out    %al,(%dx)
f01035a2:	b8 03 00 00 00       	mov    $0x3,%eax
f01035a7:	ee                   	out    %al,(%dx)
f01035a8:	ba a0 00 00 00       	mov    $0xa0,%edx
f01035ad:	b8 11 00 00 00       	mov    $0x11,%eax
f01035b2:	ee                   	out    %al,(%dx)
f01035b3:	ba a1 00 00 00       	mov    $0xa1,%edx
f01035b8:	b8 28 00 00 00       	mov    $0x28,%eax
f01035bd:	ee                   	out    %al,(%dx)
f01035be:	b8 02 00 00 00       	mov    $0x2,%eax
f01035c3:	ee                   	out    %al,(%dx)
f01035c4:	b8 01 00 00 00       	mov    $0x1,%eax
f01035c9:	ee                   	out    %al,(%dx)
f01035ca:	ba 20 00 00 00       	mov    $0x20,%edx
f01035cf:	b8 68 00 00 00       	mov    $0x68,%eax
f01035d4:	ee                   	out    %al,(%dx)
f01035d5:	b8 0a 00 00 00       	mov    $0xa,%eax
f01035da:	ee                   	out    %al,(%dx)
f01035db:	ba a0 00 00 00       	mov    $0xa0,%edx
f01035e0:	b8 68 00 00 00       	mov    $0x68,%eax
f01035e5:	ee                   	out    %al,(%dx)
f01035e6:	b8 0a 00 00 00       	mov    $0xa,%eax
f01035eb:	ee                   	out    %al,(%dx)
	outb(IO_PIC1, 0x0a);             /* read IRR by default */

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irq_mask_8259A != 0xFFFF)
f01035ec:	0f b7 05 a8 23 12 f0 	movzwl 0xf01223a8,%eax
f01035f3:	66 83 f8 ff          	cmp    $0xffff,%ax
f01035f7:	74 13                	je     f010360c <pic_init+0x9e>
static bool didinit;

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
f01035f9:	55                   	push   %ebp
f01035fa:	89 e5                	mov    %esp,%ebp
f01035fc:	83 ec 14             	sub    $0x14,%esp

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irq_mask_8259A != 0xFFFF)
		irq_setmask_8259A(irq_mask_8259A);
f01035ff:	0f b7 c0             	movzwl %ax,%eax
f0103602:	50                   	push   %eax
f0103603:	e8 ee fe ff ff       	call   f01034f6 <irq_setmask_8259A>
f0103608:	83 c4 10             	add    $0x10,%esp
}
f010360b:	c9                   	leave  
f010360c:	f3 c3                	repz ret 

f010360e <irq_eoi>:
	cprintf("\n");
}

void
irq_eoi(void)
{
f010360e:	55                   	push   %ebp
f010360f:	89 e5                	mov    %esp,%ebp
f0103611:	ba 20 00 00 00       	mov    $0x20,%edx
f0103616:	b8 20 00 00 00       	mov    $0x20,%eax
f010361b:	ee                   	out    %al,(%dx)
f010361c:	ba a0 00 00 00       	mov    $0xa0,%edx
f0103621:	ee                   	out    %al,(%dx)
	//   s: specific
	//   e: end-of-interrupt
	// xxx: specific interrupt line
	outb(IO_PIC1, 0x20);
	outb(IO_PIC2, 0x20);
}
f0103622:	5d                   	pop    %ebp
f0103623:	c3                   	ret    

f0103624 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0103624:	55                   	push   %ebp
f0103625:	89 e5                	mov    %esp,%ebp
f0103627:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f010362a:	ff 75 08             	pushl  0x8(%ebp)
f010362d:	e8 80 d1 ff ff       	call   f01007b2 <cputchar>
	*cnt++;
}
f0103632:	83 c4 10             	add    $0x10,%esp
f0103635:	c9                   	leave  
f0103636:	c3                   	ret    

f0103637 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0103637:	55                   	push   %ebp
f0103638:	89 e5                	mov    %esp,%ebp
f010363a:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f010363d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0103644:	ff 75 0c             	pushl  0xc(%ebp)
f0103647:	ff 75 08             	pushl  0x8(%ebp)
f010364a:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010364d:	50                   	push   %eax
f010364e:	68 24 36 10 f0       	push   $0xf0103624
f0103653:	e8 2d 17 00 00       	call   f0104d85 <vprintfmt>
	return cnt;
}
f0103658:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010365b:	c9                   	leave  
f010365c:	c3                   	ret    

f010365d <cprintf>:

int
cprintf(const char *fmt, ...)
{
f010365d:	55                   	push   %ebp
f010365e:	89 e5                	mov    %esp,%ebp
f0103660:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0103663:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0103666:	50                   	push   %eax
f0103667:	ff 75 08             	pushl  0x8(%ebp)
f010366a:	e8 c8 ff ff ff       	call   f0103637 <vcprintf>
	va_end(ap);

	return cnt;
}
f010366f:	c9                   	leave  
f0103670:	c3                   	ret    

f0103671 <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f0103671:	55                   	push   %ebp
f0103672:	89 e5                	mov    %esp,%ebp
f0103674:	57                   	push   %edi
f0103675:	56                   	push   %esi
f0103676:	53                   	push   %ebx
f0103677:	83 ec 1c             	sub    $0x1c,%esp
	// get a triple fault.  If you set up an individual CPU's TSS
	// wrong, you may not get a fault until you try to return from
	// user space on that CPU.
	//
	// LAB 4: Your code here:
    int i = cpunum();
f010367a:	e8 ab 23 00 00       	call   f0105a2a <cpunum>
f010367f:	89 c6                	mov    %eax,%esi
	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.

	thiscpu->cpu_ts.ts_esp0 = (uintptr_t)percpu_kstacks[i];
f0103681:	e8 a4 23 00 00       	call   f0105a2a <cpunum>
f0103686:	6b c0 74             	imul   $0x74,%eax,%eax
f0103689:	89 f2                	mov    %esi,%edx
f010368b:	c1 e2 0f             	shl    $0xf,%edx
f010368e:	81 c2 00 b0 2a f0    	add    $0xf02ab000,%edx
f0103694:	89 90 30 a0 2a f0    	mov    %edx,-0xfd55fd0(%eax)
	//thiscpu->cpu_ts.ts_esp0 = KSTACKTOP - i * (KSTKSIZE + KSTKGAP);
	thiscpu->cpu_ts.ts_ss0 = GD_KD;
f010369a:	e8 8b 23 00 00       	call   f0105a2a <cpunum>
f010369f:	6b c0 74             	imul   $0x74,%eax,%eax
f01036a2:	66 c7 80 34 a0 2a f0 	movw   $0x10,-0xfd55fcc(%eax)
f01036a9:	10 00 
	thiscpu->cpu_ts.ts_iomb = sizeof(struct Taskstate);
f01036ab:	e8 7a 23 00 00       	call   f0105a2a <cpunum>
f01036b0:	6b c0 74             	imul   $0x74,%eax,%eax
f01036b3:	66 c7 80 92 a0 2a f0 	movw   $0x68,-0xfd55f6e(%eax)
f01036ba:	68 00 

	// Initialize the TSS slot of the gdt.
	gdt[(GD_TSS0 >> 3) + i] = SEG16(STS_T32A, (uint32_t) (&thiscpu->cpu_ts),
f01036bc:	8d 5e 05             	lea    0x5(%esi),%ebx
f01036bf:	e8 66 23 00 00       	call   f0105a2a <cpunum>
f01036c4:	89 c7                	mov    %eax,%edi
f01036c6:	e8 5f 23 00 00       	call   f0105a2a <cpunum>
f01036cb:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01036ce:	e8 57 23 00 00       	call   f0105a2a <cpunum>
f01036d3:	66 c7 04 dd 40 23 12 	movw   $0x67,-0xfeddcc0(,%ebx,8)
f01036da:	f0 67 00 
f01036dd:	6b ff 74             	imul   $0x74,%edi,%edi
f01036e0:	81 c7 2c a0 2a f0    	add    $0xf02aa02c,%edi
f01036e6:	66 89 3c dd 42 23 12 	mov    %di,-0xfeddcbe(,%ebx,8)
f01036ed:	f0 
f01036ee:	6b 55 e4 74          	imul   $0x74,-0x1c(%ebp),%edx
f01036f2:	81 c2 2c a0 2a f0    	add    $0xf02aa02c,%edx
f01036f8:	c1 ea 10             	shr    $0x10,%edx
f01036fb:	88 14 dd 44 23 12 f0 	mov    %dl,-0xfeddcbc(,%ebx,8)
f0103702:	c6 04 dd 46 23 12 f0 	movb   $0x40,-0xfeddcba(,%ebx,8)
f0103709:	40 
f010370a:	6b c0 74             	imul   $0x74,%eax,%eax
f010370d:	05 2c a0 2a f0       	add    $0xf02aa02c,%eax
f0103712:	c1 e8 18             	shr    $0x18,%eax
f0103715:	88 04 dd 47 23 12 f0 	mov    %al,-0xfeddcb9(,%ebx,8)
					sizeof(struct Taskstate) - 1, 0);
	gdt[(GD_TSS0 >> 3) + i].sd_s = 0;
f010371c:	c6 04 dd 45 23 12 f0 	movb   $0x89,-0xfeddcbb(,%ebx,8)
f0103723:	89 
}

static inline void
ltr(uint16_t sel)
{
	asm volatile("ltr %0" : : "r" (sel));
f0103724:	8d 34 f5 28 00 00 00 	lea    0x28(,%esi,8),%esi
f010372b:	0f 00 de             	ltr    %si
}

static inline void
lidt(void *p)
{
	asm volatile("lidt (%0)" : : "r" (p));
f010372e:	b8 ac 23 12 f0       	mov    $0xf01223ac,%eax
f0103733:	0f 01 18             	lidtl  (%eax)
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0 + (i << 3));

	// Load the IDT
	lidt(&idt_pd);
}
f0103736:	83 c4 1c             	add    $0x1c,%esp
f0103739:	5b                   	pop    %ebx
f010373a:	5e                   	pop    %esi
f010373b:	5f                   	pop    %edi
f010373c:	5d                   	pop    %ebp
f010373d:	c3                   	ret    

f010373e <trap_init>:
}


void
trap_init(void)
{
f010373e:	55                   	push   %ebp
f010373f:	89 e5                	mov    %esp,%ebp
f0103741:	83 ec 08             	sub    $0x8,%esp
	extern struct Segdesc gdt[];

	// LAB 3: Your code here.

	SETGATE(idt[T_DIVIDE], 0, GD_KT, t_divide, 0);
f0103744:	b8 e6 40 10 f0       	mov    $0xf01040e6,%eax
f0103749:	66 a3 60 92 2a f0    	mov    %ax,0xf02a9260
f010374f:	66 c7 05 62 92 2a f0 	movw   $0x8,0xf02a9262
f0103756:	08 00 
f0103758:	c6 05 64 92 2a f0 00 	movb   $0x0,0xf02a9264
f010375f:	c6 05 65 92 2a f0 8e 	movb   $0x8e,0xf02a9265
f0103766:	c1 e8 10             	shr    $0x10,%eax
f0103769:	66 a3 66 92 2a f0    	mov    %ax,0xf02a9266
	SETGATE(idt[T_DEBUG], 0, GD_KT, t_debug, 0);
f010376f:	b8 f0 40 10 f0       	mov    $0xf01040f0,%eax
f0103774:	66 a3 68 92 2a f0    	mov    %ax,0xf02a9268
f010377a:	66 c7 05 6a 92 2a f0 	movw   $0x8,0xf02a926a
f0103781:	08 00 
f0103783:	c6 05 6c 92 2a f0 00 	movb   $0x0,0xf02a926c
f010378a:	c6 05 6d 92 2a f0 8e 	movb   $0x8e,0xf02a926d
f0103791:	c1 e8 10             	shr    $0x10,%eax
f0103794:	66 a3 6e 92 2a f0    	mov    %ax,0xf02a926e
	SETGATE(idt[T_NMI], 0, GD_KT, t_nmi, 0);
f010379a:	b8 f6 40 10 f0       	mov    $0xf01040f6,%eax
f010379f:	66 a3 70 92 2a f0    	mov    %ax,0xf02a9270
f01037a5:	66 c7 05 72 92 2a f0 	movw   $0x8,0xf02a9272
f01037ac:	08 00 
f01037ae:	c6 05 74 92 2a f0 00 	movb   $0x0,0xf02a9274
f01037b5:	c6 05 75 92 2a f0 8e 	movb   $0x8e,0xf02a9275
f01037bc:	c1 e8 10             	shr    $0x10,%eax
f01037bf:	66 a3 76 92 2a f0    	mov    %ax,0xf02a9276
	SETGATE(idt[T_BRKPT], 0, GD_KT, t_brkpt, 3);
f01037c5:	b8 fc 40 10 f0       	mov    $0xf01040fc,%eax
f01037ca:	66 a3 78 92 2a f0    	mov    %ax,0xf02a9278
f01037d0:	66 c7 05 7a 92 2a f0 	movw   $0x8,0xf02a927a
f01037d7:	08 00 
f01037d9:	c6 05 7c 92 2a f0 00 	movb   $0x0,0xf02a927c
f01037e0:	c6 05 7d 92 2a f0 ee 	movb   $0xee,0xf02a927d
f01037e7:	c1 e8 10             	shr    $0x10,%eax
f01037ea:	66 a3 7e 92 2a f0    	mov    %ax,0xf02a927e
	SETGATE(idt[T_OFLOW], 0, GD_KT, t_oflow, 0);
f01037f0:	b8 02 41 10 f0       	mov    $0xf0104102,%eax
f01037f5:	66 a3 80 92 2a f0    	mov    %ax,0xf02a9280
f01037fb:	66 c7 05 82 92 2a f0 	movw   $0x8,0xf02a9282
f0103802:	08 00 
f0103804:	c6 05 84 92 2a f0 00 	movb   $0x0,0xf02a9284
f010380b:	c6 05 85 92 2a f0 8e 	movb   $0x8e,0xf02a9285
f0103812:	c1 e8 10             	shr    $0x10,%eax
f0103815:	66 a3 86 92 2a f0    	mov    %ax,0xf02a9286
	SETGATE(idt[T_BOUND], 0, GD_KT, t_bound, 0);
f010381b:	b8 08 41 10 f0       	mov    $0xf0104108,%eax
f0103820:	66 a3 88 92 2a f0    	mov    %ax,0xf02a9288
f0103826:	66 c7 05 8a 92 2a f0 	movw   $0x8,0xf02a928a
f010382d:	08 00 
f010382f:	c6 05 8c 92 2a f0 00 	movb   $0x0,0xf02a928c
f0103836:	c6 05 8d 92 2a f0 8e 	movb   $0x8e,0xf02a928d
f010383d:	c1 e8 10             	shr    $0x10,%eax
f0103840:	66 a3 8e 92 2a f0    	mov    %ax,0xf02a928e
	SETGATE(idt[T_ILLOP], 0, GD_KT, t_illop, 0);
f0103846:	b8 0e 41 10 f0       	mov    $0xf010410e,%eax
f010384b:	66 a3 90 92 2a f0    	mov    %ax,0xf02a9290
f0103851:	66 c7 05 92 92 2a f0 	movw   $0x8,0xf02a9292
f0103858:	08 00 
f010385a:	c6 05 94 92 2a f0 00 	movb   $0x0,0xf02a9294
f0103861:	c6 05 95 92 2a f0 8e 	movb   $0x8e,0xf02a9295
f0103868:	c1 e8 10             	shr    $0x10,%eax
f010386b:	66 a3 96 92 2a f0    	mov    %ax,0xf02a9296
	SETGATE(idt[T_DEVICE], 0, GD_KT, t_device, 0);
f0103871:	b8 14 41 10 f0       	mov    $0xf0104114,%eax
f0103876:	66 a3 98 92 2a f0    	mov    %ax,0xf02a9298
f010387c:	66 c7 05 9a 92 2a f0 	movw   $0x8,0xf02a929a
f0103883:	08 00 
f0103885:	c6 05 9c 92 2a f0 00 	movb   $0x0,0xf02a929c
f010388c:	c6 05 9d 92 2a f0 8e 	movb   $0x8e,0xf02a929d
f0103893:	c1 e8 10             	shr    $0x10,%eax
f0103896:	66 a3 9e 92 2a f0    	mov    %ax,0xf02a929e
	SETGATE(idt[T_DBLFLT], 0, GD_KT, t_dblflt, 0);
f010389c:	b8 1a 41 10 f0       	mov    $0xf010411a,%eax
f01038a1:	66 a3 a0 92 2a f0    	mov    %ax,0xf02a92a0
f01038a7:	66 c7 05 a2 92 2a f0 	movw   $0x8,0xf02a92a2
f01038ae:	08 00 
f01038b0:	c6 05 a4 92 2a f0 00 	movb   $0x0,0xf02a92a4
f01038b7:	c6 05 a5 92 2a f0 8e 	movb   $0x8e,0xf02a92a5
f01038be:	c1 e8 10             	shr    $0x10,%eax
f01038c1:	66 a3 a6 92 2a f0    	mov    %ax,0xf02a92a6
	SETGATE(idt[T_TSS], 0, GD_KT, t_tss, 0);
f01038c7:	b8 1e 41 10 f0       	mov    $0xf010411e,%eax
f01038cc:	66 a3 b0 92 2a f0    	mov    %ax,0xf02a92b0
f01038d2:	66 c7 05 b2 92 2a f0 	movw   $0x8,0xf02a92b2
f01038d9:	08 00 
f01038db:	c6 05 b4 92 2a f0 00 	movb   $0x0,0xf02a92b4
f01038e2:	c6 05 b5 92 2a f0 8e 	movb   $0x8e,0xf02a92b5
f01038e9:	c1 e8 10             	shr    $0x10,%eax
f01038ec:	66 a3 b6 92 2a f0    	mov    %ax,0xf02a92b6
	SETGATE(idt[T_SEGNP], 0, GD_KT, t_segnp, 0);
f01038f2:	b8 22 41 10 f0       	mov    $0xf0104122,%eax
f01038f7:	66 a3 b8 92 2a f0    	mov    %ax,0xf02a92b8
f01038fd:	66 c7 05 ba 92 2a f0 	movw   $0x8,0xf02a92ba
f0103904:	08 00 
f0103906:	c6 05 bc 92 2a f0 00 	movb   $0x0,0xf02a92bc
f010390d:	c6 05 bd 92 2a f0 8e 	movb   $0x8e,0xf02a92bd
f0103914:	c1 e8 10             	shr    $0x10,%eax
f0103917:	66 a3 be 92 2a f0    	mov    %ax,0xf02a92be
	SETGATE(idt[T_STACK], 0, GD_KT, t_stack, 0);
f010391d:	b8 26 41 10 f0       	mov    $0xf0104126,%eax
f0103922:	66 a3 c0 92 2a f0    	mov    %ax,0xf02a92c0
f0103928:	66 c7 05 c2 92 2a f0 	movw   $0x8,0xf02a92c2
f010392f:	08 00 
f0103931:	c6 05 c4 92 2a f0 00 	movb   $0x0,0xf02a92c4
f0103938:	c6 05 c5 92 2a f0 8e 	movb   $0x8e,0xf02a92c5
f010393f:	c1 e8 10             	shr    $0x10,%eax
f0103942:	66 a3 c6 92 2a f0    	mov    %ax,0xf02a92c6
	SETGATE(idt[T_GPFLT], 0, GD_KT, t_gpflt, 0);
f0103948:	b8 2a 41 10 f0       	mov    $0xf010412a,%eax
f010394d:	66 a3 c8 92 2a f0    	mov    %ax,0xf02a92c8
f0103953:	66 c7 05 ca 92 2a f0 	movw   $0x8,0xf02a92ca
f010395a:	08 00 
f010395c:	c6 05 cc 92 2a f0 00 	movb   $0x0,0xf02a92cc
f0103963:	c6 05 cd 92 2a f0 8e 	movb   $0x8e,0xf02a92cd
f010396a:	c1 e8 10             	shr    $0x10,%eax
f010396d:	66 a3 ce 92 2a f0    	mov    %ax,0xf02a92ce
	SETGATE(idt[T_PGFLT], 0, GD_KT, t_pgflt, 0);
f0103973:	b8 2e 41 10 f0       	mov    $0xf010412e,%eax
f0103978:	66 a3 d0 92 2a f0    	mov    %ax,0xf02a92d0
f010397e:	66 c7 05 d2 92 2a f0 	movw   $0x8,0xf02a92d2
f0103985:	08 00 
f0103987:	c6 05 d4 92 2a f0 00 	movb   $0x0,0xf02a92d4
f010398e:	c6 05 d5 92 2a f0 8e 	movb   $0x8e,0xf02a92d5
f0103995:	c1 e8 10             	shr    $0x10,%eax
f0103998:	66 a3 d6 92 2a f0    	mov    %ax,0xf02a92d6
	SETGATE(idt[T_FPERR], 0, GD_KT, t_fperr, 0);
f010399e:	b8 32 41 10 f0       	mov    $0xf0104132,%eax
f01039a3:	66 a3 e0 92 2a f0    	mov    %ax,0xf02a92e0
f01039a9:	66 c7 05 e2 92 2a f0 	movw   $0x8,0xf02a92e2
f01039b0:	08 00 
f01039b2:	c6 05 e4 92 2a f0 00 	movb   $0x0,0xf02a92e4
f01039b9:	c6 05 e5 92 2a f0 8e 	movb   $0x8e,0xf02a92e5
f01039c0:	c1 e8 10             	shr    $0x10,%eax
f01039c3:	66 a3 e6 92 2a f0    	mov    %ax,0xf02a92e6
	SETGATE(idt[T_ALIGN], 0, GD_KT, t_align, 0);
f01039c9:	b8 38 41 10 f0       	mov    $0xf0104138,%eax
f01039ce:	66 a3 e8 92 2a f0    	mov    %ax,0xf02a92e8
f01039d4:	66 c7 05 ea 92 2a f0 	movw   $0x8,0xf02a92ea
f01039db:	08 00 
f01039dd:	c6 05 ec 92 2a f0 00 	movb   $0x0,0xf02a92ec
f01039e4:	c6 05 ed 92 2a f0 8e 	movb   $0x8e,0xf02a92ed
f01039eb:	c1 e8 10             	shr    $0x10,%eax
f01039ee:	66 a3 ee 92 2a f0    	mov    %ax,0xf02a92ee
	SETGATE(idt[T_MCHK], 0, GD_KT, t_mchk, 0);
f01039f4:	b8 3c 41 10 f0       	mov    $0xf010413c,%eax
f01039f9:	66 a3 f0 92 2a f0    	mov    %ax,0xf02a92f0
f01039ff:	66 c7 05 f2 92 2a f0 	movw   $0x8,0xf02a92f2
f0103a06:	08 00 
f0103a08:	c6 05 f4 92 2a f0 00 	movb   $0x0,0xf02a92f4
f0103a0f:	c6 05 f5 92 2a f0 8e 	movb   $0x8e,0xf02a92f5
f0103a16:	c1 e8 10             	shr    $0x10,%eax
f0103a19:	66 a3 f6 92 2a f0    	mov    %ax,0xf02a92f6
	SETGATE(idt[T_SIMDERR], 0, GD_KT, t_simderr, 0);
f0103a1f:	b8 42 41 10 f0       	mov    $0xf0104142,%eax
f0103a24:	66 a3 f8 92 2a f0    	mov    %ax,0xf02a92f8
f0103a2a:	66 c7 05 fa 92 2a f0 	movw   $0x8,0xf02a92fa
f0103a31:	08 00 
f0103a33:	c6 05 fc 92 2a f0 00 	movb   $0x0,0xf02a92fc
f0103a3a:	c6 05 fd 92 2a f0 8e 	movb   $0x8e,0xf02a92fd
f0103a41:	c1 e8 10             	shr    $0x10,%eax
f0103a44:	66 a3 fe 92 2a f0    	mov    %ax,0xf02a92fe

	SETGATE(idt[T_SYSCALL], 0, GD_KT, t_syscall, 3);
f0103a4a:	b8 48 41 10 f0       	mov    $0xf0104148,%eax
f0103a4f:	66 a3 e0 93 2a f0    	mov    %ax,0xf02a93e0
f0103a55:	66 c7 05 e2 93 2a f0 	movw   $0x8,0xf02a93e2
f0103a5c:	08 00 
f0103a5e:	c6 05 e4 93 2a f0 00 	movb   $0x0,0xf02a93e4
f0103a65:	c6 05 e5 93 2a f0 ee 	movb   $0xee,0xf02a93e5
f0103a6c:	c1 e8 10             	shr    $0x10,%eax
f0103a6f:	66 a3 e6 93 2a f0    	mov    %ax,0xf02a93e6

	SETGATE(idt[IRQ_OFFSET + IRQ_TIMER], 0, GD_KT, irq_timer, 0);
f0103a75:	b8 4e 41 10 f0       	mov    $0xf010414e,%eax
f0103a7a:	66 a3 60 93 2a f0    	mov    %ax,0xf02a9360
f0103a80:	66 c7 05 62 93 2a f0 	movw   $0x8,0xf02a9362
f0103a87:	08 00 
f0103a89:	c6 05 64 93 2a f0 00 	movb   $0x0,0xf02a9364
f0103a90:	c6 05 65 93 2a f0 8e 	movb   $0x8e,0xf02a9365
f0103a97:	c1 e8 10             	shr    $0x10,%eax
f0103a9a:	66 a3 66 93 2a f0    	mov    %ax,0xf02a9366
	SETGATE(idt[IRQ_OFFSET + IRQ_KBD], 0, GD_KT, irq_kbd, 0);
f0103aa0:	b8 54 41 10 f0       	mov    $0xf0104154,%eax
f0103aa5:	66 a3 68 93 2a f0    	mov    %ax,0xf02a9368
f0103aab:	66 c7 05 6a 93 2a f0 	movw   $0x8,0xf02a936a
f0103ab2:	08 00 
f0103ab4:	c6 05 6c 93 2a f0 00 	movb   $0x0,0xf02a936c
f0103abb:	c6 05 6d 93 2a f0 8e 	movb   $0x8e,0xf02a936d
f0103ac2:	c1 e8 10             	shr    $0x10,%eax
f0103ac5:	66 a3 6e 93 2a f0    	mov    %ax,0xf02a936e
	SETGATE(idt[IRQ_OFFSET + IRQ_SERIAL], 0, GD_KT, irq_serial, 0);
f0103acb:	b8 5a 41 10 f0       	mov    $0xf010415a,%eax
f0103ad0:	66 a3 80 93 2a f0    	mov    %ax,0xf02a9380
f0103ad6:	66 c7 05 82 93 2a f0 	movw   $0x8,0xf02a9382
f0103add:	08 00 
f0103adf:	c6 05 84 93 2a f0 00 	movb   $0x0,0xf02a9384
f0103ae6:	c6 05 85 93 2a f0 8e 	movb   $0x8e,0xf02a9385
f0103aed:	c1 e8 10             	shr    $0x10,%eax
f0103af0:	66 a3 86 93 2a f0    	mov    %ax,0xf02a9386
	SETGATE(idt[IRQ_OFFSET + IRQ_SPURIOUS], 0, GD_KT, irq_spurious, 0);
f0103af6:	b8 60 41 10 f0       	mov    $0xf0104160,%eax
f0103afb:	66 a3 98 93 2a f0    	mov    %ax,0xf02a9398
f0103b01:	66 c7 05 9a 93 2a f0 	movw   $0x8,0xf02a939a
f0103b08:	08 00 
f0103b0a:	c6 05 9c 93 2a f0 00 	movb   $0x0,0xf02a939c
f0103b11:	c6 05 9d 93 2a f0 8e 	movb   $0x8e,0xf02a939d
f0103b18:	c1 e8 10             	shr    $0x10,%eax
f0103b1b:	66 a3 9e 93 2a f0    	mov    %ax,0xf02a939e
	SETGATE(idt[IRQ_OFFSET + IRQ_IDE], 0, GD_KT, irq_ide, 0);
f0103b21:	b8 66 41 10 f0       	mov    $0xf0104166,%eax
f0103b26:	66 a3 d0 93 2a f0    	mov    %ax,0xf02a93d0
f0103b2c:	66 c7 05 d2 93 2a f0 	movw   $0x8,0xf02a93d2
f0103b33:	08 00 
f0103b35:	c6 05 d4 93 2a f0 00 	movb   $0x0,0xf02a93d4
f0103b3c:	c6 05 d5 93 2a f0 8e 	movb   $0x8e,0xf02a93d5
f0103b43:	c1 e8 10             	shr    $0x10,%eax
f0103b46:	66 a3 d6 93 2a f0    	mov    %ax,0xf02a93d6
	SETGATE(idt[IRQ_OFFSET + IRQ_ERROR], 0, GD_KT, irq_error, 0);
f0103b4c:	b8 6c 41 10 f0       	mov    $0xf010416c,%eax
f0103b51:	66 a3 f8 93 2a f0    	mov    %ax,0xf02a93f8
f0103b57:	66 c7 05 fa 93 2a f0 	movw   $0x8,0xf02a93fa
f0103b5e:	08 00 
f0103b60:	c6 05 fc 93 2a f0 00 	movb   $0x0,0xf02a93fc
f0103b67:	c6 05 fd 93 2a f0 8e 	movb   $0x8e,0xf02a93fd
f0103b6e:	c1 e8 10             	shr    $0x10,%eax
f0103b71:	66 a3 fe 93 2a f0    	mov    %ax,0xf02a93fe
	// Per-CPU setup 
	trap_init_percpu();
f0103b77:	e8 f5 fa ff ff       	call   f0103671 <trap_init_percpu>
}
f0103b7c:	c9                   	leave  
f0103b7d:	c3                   	ret    

f0103b7e <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f0103b7e:	55                   	push   %ebp
f0103b7f:	89 e5                	mov    %esp,%ebp
f0103b81:	53                   	push   %ebx
f0103b82:	83 ec 0c             	sub    $0xc,%esp
f0103b85:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f0103b88:	ff 33                	pushl  (%ebx)
f0103b8a:	68 98 78 10 f0       	push   $0xf0107898
f0103b8f:	e8 c9 fa ff ff       	call   f010365d <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f0103b94:	83 c4 08             	add    $0x8,%esp
f0103b97:	ff 73 04             	pushl  0x4(%ebx)
f0103b9a:	68 a7 78 10 f0       	push   $0xf01078a7
f0103b9f:	e8 b9 fa ff ff       	call   f010365d <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f0103ba4:	83 c4 08             	add    $0x8,%esp
f0103ba7:	ff 73 08             	pushl  0x8(%ebx)
f0103baa:	68 b6 78 10 f0       	push   $0xf01078b6
f0103baf:	e8 a9 fa ff ff       	call   f010365d <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f0103bb4:	83 c4 08             	add    $0x8,%esp
f0103bb7:	ff 73 0c             	pushl  0xc(%ebx)
f0103bba:	68 c5 78 10 f0       	push   $0xf01078c5
f0103bbf:	e8 99 fa ff ff       	call   f010365d <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f0103bc4:	83 c4 08             	add    $0x8,%esp
f0103bc7:	ff 73 10             	pushl  0x10(%ebx)
f0103bca:	68 d4 78 10 f0       	push   $0xf01078d4
f0103bcf:	e8 89 fa ff ff       	call   f010365d <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f0103bd4:	83 c4 08             	add    $0x8,%esp
f0103bd7:	ff 73 14             	pushl  0x14(%ebx)
f0103bda:	68 e3 78 10 f0       	push   $0xf01078e3
f0103bdf:	e8 79 fa ff ff       	call   f010365d <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f0103be4:	83 c4 08             	add    $0x8,%esp
f0103be7:	ff 73 18             	pushl  0x18(%ebx)
f0103bea:	68 f2 78 10 f0       	push   $0xf01078f2
f0103bef:	e8 69 fa ff ff       	call   f010365d <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f0103bf4:	83 c4 08             	add    $0x8,%esp
f0103bf7:	ff 73 1c             	pushl  0x1c(%ebx)
f0103bfa:	68 01 79 10 f0       	push   $0xf0107901
f0103bff:	e8 59 fa ff ff       	call   f010365d <cprintf>
}
f0103c04:	83 c4 10             	add    $0x10,%esp
f0103c07:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103c0a:	c9                   	leave  
f0103c0b:	c3                   	ret    

f0103c0c <print_trapframe>:
	lidt(&idt_pd);
}

void
print_trapframe(struct Trapframe *tf)
{
f0103c0c:	55                   	push   %ebp
f0103c0d:	89 e5                	mov    %esp,%ebp
f0103c0f:	56                   	push   %esi
f0103c10:	53                   	push   %ebx
f0103c11:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p from CPU %d\n", tf, cpunum());
f0103c14:	e8 11 1e 00 00       	call   f0105a2a <cpunum>
f0103c19:	83 ec 04             	sub    $0x4,%esp
f0103c1c:	50                   	push   %eax
f0103c1d:	53                   	push   %ebx
f0103c1e:	68 65 79 10 f0       	push   $0xf0107965
f0103c23:	e8 35 fa ff ff       	call   f010365d <cprintf>
	print_regs(&tf->tf_regs);
f0103c28:	89 1c 24             	mov    %ebx,(%esp)
f0103c2b:	e8 4e ff ff ff       	call   f0103b7e <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f0103c30:	83 c4 08             	add    $0x8,%esp
f0103c33:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f0103c37:	50                   	push   %eax
f0103c38:	68 83 79 10 f0       	push   $0xf0107983
f0103c3d:	e8 1b fa ff ff       	call   f010365d <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f0103c42:	83 c4 08             	add    $0x8,%esp
f0103c45:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f0103c49:	50                   	push   %eax
f0103c4a:	68 96 79 10 f0       	push   $0xf0107996
f0103c4f:	e8 09 fa ff ff       	call   f010365d <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103c54:	8b 43 28             	mov    0x28(%ebx),%eax
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < ARRAY_SIZE(excnames))
f0103c57:	83 c4 10             	add    $0x10,%esp
f0103c5a:	83 f8 13             	cmp    $0x13,%eax
f0103c5d:	77 09                	ja     f0103c68 <print_trapframe+0x5c>
		return excnames[trapno];
f0103c5f:	8b 14 85 40 7c 10 f0 	mov    -0xfef83c0(,%eax,4),%edx
f0103c66:	eb 1f                	jmp    f0103c87 <print_trapframe+0x7b>
	if (trapno == T_SYSCALL)
f0103c68:	83 f8 30             	cmp    $0x30,%eax
f0103c6b:	74 15                	je     f0103c82 <print_trapframe+0x76>
		return "System call";
	if (trapno >= IRQ_OFFSET && trapno < IRQ_OFFSET + 16)
f0103c6d:	8d 50 e0             	lea    -0x20(%eax),%edx
		return "Hardware Interrupt";
	return "(unknown trap)";
f0103c70:	83 fa 10             	cmp    $0x10,%edx
f0103c73:	b9 2f 79 10 f0       	mov    $0xf010792f,%ecx
f0103c78:	ba 1c 79 10 f0       	mov    $0xf010791c,%edx
f0103c7d:	0f 43 d1             	cmovae %ecx,%edx
f0103c80:	eb 05                	jmp    f0103c87 <print_trapframe+0x7b>
	};

	if (trapno < ARRAY_SIZE(excnames))
		return excnames[trapno];
	if (trapno == T_SYSCALL)
		return "System call";
f0103c82:	ba 10 79 10 f0       	mov    $0xf0107910,%edx
{
	cprintf("TRAP frame at %p from CPU %d\n", tf, cpunum());
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103c87:	83 ec 04             	sub    $0x4,%esp
f0103c8a:	52                   	push   %edx
f0103c8b:	50                   	push   %eax
f0103c8c:	68 a9 79 10 f0       	push   $0xf01079a9
f0103c91:	e8 c7 f9 ff ff       	call   f010365d <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0103c96:	83 c4 10             	add    $0x10,%esp
f0103c99:	3b 1d 60 9a 2a f0    	cmp    0xf02a9a60,%ebx
f0103c9f:	75 1a                	jne    f0103cbb <print_trapframe+0xaf>
f0103ca1:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103ca5:	75 14                	jne    f0103cbb <print_trapframe+0xaf>

static inline uint32_t
rcr2(void)
{
	uint32_t val;
	asm volatile("movl %%cr2,%0" : "=r" (val));
f0103ca7:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f0103caa:	83 ec 08             	sub    $0x8,%esp
f0103cad:	50                   	push   %eax
f0103cae:	68 bb 79 10 f0       	push   $0xf01079bb
f0103cb3:	e8 a5 f9 ff ff       	call   f010365d <cprintf>
f0103cb8:	83 c4 10             	add    $0x10,%esp
	cprintf("  err  0x%08x", tf->tf_err);
f0103cbb:	83 ec 08             	sub    $0x8,%esp
f0103cbe:	ff 73 2c             	pushl  0x2c(%ebx)
f0103cc1:	68 ca 79 10 f0       	push   $0xf01079ca
f0103cc6:	e8 92 f9 ff ff       	call   f010365d <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f0103ccb:	83 c4 10             	add    $0x10,%esp
f0103cce:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103cd2:	75 49                	jne    f0103d1d <print_trapframe+0x111>
		cprintf(" [%s, %s, %s]\n",
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
f0103cd4:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f0103cd7:	89 c2                	mov    %eax,%edx
f0103cd9:	83 e2 01             	and    $0x1,%edx
f0103cdc:	ba 49 79 10 f0       	mov    $0xf0107949,%edx
f0103ce1:	b9 3e 79 10 f0       	mov    $0xf010793e,%ecx
f0103ce6:	0f 44 ca             	cmove  %edx,%ecx
f0103ce9:	89 c2                	mov    %eax,%edx
f0103ceb:	83 e2 02             	and    $0x2,%edx
f0103cee:	ba 5b 79 10 f0       	mov    $0xf010795b,%edx
f0103cf3:	be 55 79 10 f0       	mov    $0xf0107955,%esi
f0103cf8:	0f 45 d6             	cmovne %esi,%edx
f0103cfb:	83 e0 04             	and    $0x4,%eax
f0103cfe:	be 95 7a 10 f0       	mov    $0xf0107a95,%esi
f0103d03:	b8 60 79 10 f0       	mov    $0xf0107960,%eax
f0103d08:	0f 44 c6             	cmove  %esi,%eax
f0103d0b:	51                   	push   %ecx
f0103d0c:	52                   	push   %edx
f0103d0d:	50                   	push   %eax
f0103d0e:	68 d8 79 10 f0       	push   $0xf01079d8
f0103d13:	e8 45 f9 ff ff       	call   f010365d <cprintf>
f0103d18:	83 c4 10             	add    $0x10,%esp
f0103d1b:	eb 10                	jmp    f0103d2d <print_trapframe+0x121>
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f0103d1d:	83 ec 0c             	sub    $0xc,%esp
f0103d20:	68 04 78 10 f0       	push   $0xf0107804
f0103d25:	e8 33 f9 ff ff       	call   f010365d <cprintf>
f0103d2a:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f0103d2d:	83 ec 08             	sub    $0x8,%esp
f0103d30:	ff 73 30             	pushl  0x30(%ebx)
f0103d33:	68 e7 79 10 f0       	push   $0xf01079e7
f0103d38:	e8 20 f9 ff ff       	call   f010365d <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f0103d3d:	83 c4 08             	add    $0x8,%esp
f0103d40:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f0103d44:	50                   	push   %eax
f0103d45:	68 f6 79 10 f0       	push   $0xf01079f6
f0103d4a:	e8 0e f9 ff ff       	call   f010365d <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f0103d4f:	83 c4 08             	add    $0x8,%esp
f0103d52:	ff 73 38             	pushl  0x38(%ebx)
f0103d55:	68 09 7a 10 f0       	push   $0xf0107a09
f0103d5a:	e8 fe f8 ff ff       	call   f010365d <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f0103d5f:	83 c4 10             	add    $0x10,%esp
f0103d62:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0103d66:	74 25                	je     f0103d8d <print_trapframe+0x181>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f0103d68:	83 ec 08             	sub    $0x8,%esp
f0103d6b:	ff 73 3c             	pushl  0x3c(%ebx)
f0103d6e:	68 18 7a 10 f0       	push   $0xf0107a18
f0103d73:	e8 e5 f8 ff ff       	call   f010365d <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f0103d78:	83 c4 08             	add    $0x8,%esp
f0103d7b:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f0103d7f:	50                   	push   %eax
f0103d80:	68 27 7a 10 f0       	push   $0xf0107a27
f0103d85:	e8 d3 f8 ff ff       	call   f010365d <cprintf>
f0103d8a:	83 c4 10             	add    $0x10,%esp
	}
}
f0103d8d:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0103d90:	5b                   	pop    %ebx
f0103d91:	5e                   	pop    %esi
f0103d92:	5d                   	pop    %ebp
f0103d93:	c3                   	ret    

f0103d94 <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f0103d94:	55                   	push   %ebp
f0103d95:	89 e5                	mov    %esp,%ebp
f0103d97:	57                   	push   %edi
f0103d98:	56                   	push   %esi
f0103d99:	53                   	push   %ebx
f0103d9a:	83 ec 0c             	sub    $0xc,%esp
f0103d9d:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103da0:	0f 20 d6             	mov    %cr2,%esi
	fault_va = rcr2();

	// Handle kernel-mode page faults.

	// LAB 3: Your code here.
	if (tf->tf_cs == GD_KT) {
f0103da3:	66 83 7b 34 08       	cmpw   $0x8,0x34(%ebx)
f0103da8:	75 17                	jne    f0103dc1 <page_fault_handler+0x2d>
		// Trapped from kernel mode
		panic("page_fault_handler: page fault in kernel mode");
f0103daa:	83 ec 04             	sub    $0x4,%esp
f0103dad:	68 e0 7b 10 f0       	push   $0xf0107be0
f0103db2:	68 7a 01 00 00       	push   $0x17a
f0103db7:	68 3a 7a 10 f0       	push   $0xf0107a3a
f0103dbc:	e8 7f c2 ff ff       	call   f0100040 <_panic>
	//   To change what the user environment runs, modify 'curenv->env_tf'
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.
    
    if(curenv->env_pgfault_upcall!=NULL){
f0103dc1:	e8 64 1c 00 00       	call   f0105a2a <cpunum>
f0103dc6:	6b c0 74             	imul   $0x74,%eax,%eax
f0103dc9:	8b 80 28 a0 2a f0    	mov    -0xfd55fd8(%eax),%eax
f0103dcf:	83 78 64 00          	cmpl   $0x0,0x64(%eax)
f0103dd3:	0f 84 8b 00 00 00    	je     f0103e64 <page_fault_handler+0xd0>
        struct UTrapframe *utf;
        uintptr_t utf_addr;  
        if(tf->tf_esp >= UXSTACKTOP - PGSIZE && tf->tf_esp < UXSTACKTOP){
f0103dd9:	8b 43 3c             	mov    0x3c(%ebx),%eax
f0103ddc:	8d 90 00 10 40 11    	lea    0x11401000(%eax),%edx
            utf_addr = tf->tf_esp - sizeof(struct UTrapframe) - 4;
f0103de2:	83 e8 38             	sub    $0x38,%eax
f0103de5:	81 fa ff 0f 00 00    	cmp    $0xfff,%edx
f0103deb:	ba cc ff bf ee       	mov    $0xeebfffcc,%edx
f0103df0:	0f 46 d0             	cmovbe %eax,%edx
f0103df3:	89 d7                	mov    %edx,%edi
        }
        else{
            utf_addr = UXSTACKTOP - sizeof(struct UTrapframe);
        }
        user_mem_assert(curenv, (void *) utf_addr, sizeof(struct UTrapframe), PTE_W);        
f0103df5:	e8 30 1c 00 00       	call   f0105a2a <cpunum>
f0103dfa:	6a 02                	push   $0x2
f0103dfc:	6a 34                	push   $0x34
f0103dfe:	57                   	push   %edi
f0103dff:	6b c0 74             	imul   $0x74,%eax,%eax
f0103e02:	ff b0 28 a0 2a f0    	pushl  -0xfd55fd8(%eax)
f0103e08:	e8 86 ef ff ff       	call   f0102d93 <user_mem_assert>

        utf = (struct UTrapframe *) utf_addr;
        utf->utf_fault_va = fault_va;
f0103e0d:	89 fa                	mov    %edi,%edx
f0103e0f:	89 37                	mov    %esi,(%edi)
        utf->utf_err = tf->tf_err;
f0103e11:	8b 43 2c             	mov    0x2c(%ebx),%eax
f0103e14:	89 47 04             	mov    %eax,0x4(%edi)
        utf->utf_regs = tf->tf_regs;
f0103e17:	8d 7f 08             	lea    0x8(%edi),%edi
f0103e1a:	b9 08 00 00 00       	mov    $0x8,%ecx
f0103e1f:	89 de                	mov    %ebx,%esi
f0103e21:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
        utf->utf_eip = tf->tf_eip;
f0103e23:	8b 43 30             	mov    0x30(%ebx),%eax
f0103e26:	89 42 28             	mov    %eax,0x28(%edx)
        utf->utf_eflags = tf->tf_eflags;
f0103e29:	8b 43 38             	mov    0x38(%ebx),%eax
f0103e2c:	89 d7                	mov    %edx,%edi
f0103e2e:	89 42 2c             	mov    %eax,0x2c(%edx)
        utf->utf_esp = tf->tf_esp;
f0103e31:	8b 43 3c             	mov    0x3c(%ebx),%eax
f0103e34:	89 42 30             	mov    %eax,0x30(%edx)

        tf->tf_eip = (uintptr_t) curenv->env_pgfault_upcall;
f0103e37:	e8 ee 1b 00 00       	call   f0105a2a <cpunum>
f0103e3c:	6b c0 74             	imul   $0x74,%eax,%eax
f0103e3f:	8b 80 28 a0 2a f0    	mov    -0xfd55fd8(%eax),%eax
f0103e45:	8b 40 64             	mov    0x64(%eax),%eax
f0103e48:	89 43 30             	mov    %eax,0x30(%ebx)
        tf->tf_esp = utf_addr;
f0103e4b:	89 7b 3c             	mov    %edi,0x3c(%ebx)
        env_run(curenv);
f0103e4e:	e8 d7 1b 00 00       	call   f0105a2a <cpunum>
f0103e53:	83 c4 04             	add    $0x4,%esp
f0103e56:	6b c0 74             	imul   $0x74,%eax,%eax
f0103e59:	ff b0 28 a0 2a f0    	pushl  -0xfd55fd8(%eax)
f0103e5f:	e8 ad f5 ff ff       	call   f0103411 <env_run>
    } 
    
	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103e64:	8b 7b 30             	mov    0x30(%ebx),%edi
		curenv->env_id, fault_va, tf->tf_eip);
f0103e67:	e8 be 1b 00 00       	call   f0105a2a <cpunum>
        tf->tf_esp = utf_addr;
        env_run(curenv);
    } 
    
	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103e6c:	57                   	push   %edi
f0103e6d:	56                   	push   %esi
		curenv->env_id, fault_va, tf->tf_eip);
f0103e6e:	6b c0 74             	imul   $0x74,%eax,%eax
        tf->tf_esp = utf_addr;
        env_run(curenv);
    } 
    
	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103e71:	8b 80 28 a0 2a f0    	mov    -0xfd55fd8(%eax),%eax
f0103e77:	ff 70 48             	pushl  0x48(%eax)
f0103e7a:	68 10 7c 10 f0       	push   $0xf0107c10
f0103e7f:	e8 d9 f7 ff ff       	call   f010365d <cprintf>
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f0103e84:	89 1c 24             	mov    %ebx,(%esp)
f0103e87:	e8 80 fd ff ff       	call   f0103c0c <print_trapframe>
	env_destroy(curenv);
f0103e8c:	e8 99 1b 00 00       	call   f0105a2a <cpunum>
f0103e91:	83 c4 04             	add    $0x4,%esp
f0103e94:	6b c0 74             	imul   $0x74,%eax,%eax
f0103e97:	ff b0 28 a0 2a f0    	pushl  -0xfd55fd8(%eax)
f0103e9d:	e8 d0 f4 ff ff       	call   f0103372 <env_destroy>
}
f0103ea2:	83 c4 10             	add    $0x10,%esp
f0103ea5:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103ea8:	5b                   	pop    %ebx
f0103ea9:	5e                   	pop    %esi
f0103eaa:	5f                   	pop    %edi
f0103eab:	5d                   	pop    %ebp
f0103eac:	c3                   	ret    

f0103ead <trap>:
	}
}

void
trap(struct Trapframe *tf)
{
f0103ead:	55                   	push   %ebp
f0103eae:	89 e5                	mov    %esp,%ebp
f0103eb0:	57                   	push   %edi
f0103eb1:	56                   	push   %esi
f0103eb2:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f0103eb5:	fc                   	cld    

	// Halt the CPU if some other CPU has called panic()
	extern char *panicstr;
	if (panicstr)
f0103eb6:	83 3d 98 9e 2a f0 00 	cmpl   $0x0,0xf02a9e98
f0103ebd:	74 01                	je     f0103ec0 <trap+0x13>
		asm volatile("hlt");
f0103ebf:	f4                   	hlt    

	// Re-acqurie the big kernel lock if we were halted in
	// sched_yield()
	if (xchg(&thiscpu->cpu_status, CPU_STARTED) == CPU_HALTED)
f0103ec0:	e8 65 1b 00 00       	call   f0105a2a <cpunum>
f0103ec5:	6b d0 74             	imul   $0x74,%eax,%edx
f0103ec8:	81 c2 20 a0 2a f0    	add    $0xf02aa020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"
f0103ece:	b8 01 00 00 00       	mov    $0x1,%eax
f0103ed3:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
f0103ed7:	83 f8 02             	cmp    $0x2,%eax
f0103eda:	75 10                	jne    f0103eec <trap+0x3f>
extern struct spinlock kernel_lock;

static inline void
lock_kernel(void)
{
	spin_lock(&kernel_lock);
f0103edc:	83 ec 0c             	sub    $0xc,%esp
f0103edf:	68 c0 23 12 f0       	push   $0xf01223c0
f0103ee4:	e8 af 1d 00 00       	call   f0105c98 <spin_lock>
f0103ee9:	83 c4 10             	add    $0x10,%esp

static inline uint32_t
read_eflags(void)
{
	uint32_t eflags;
	asm volatile("pushfl; popl %0" : "=r" (eflags));
f0103eec:	9c                   	pushf  
f0103eed:	58                   	pop    %eax
		lock_kernel();
	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f0103eee:	f6 c4 02             	test   $0x2,%ah
f0103ef1:	74 19                	je     f0103f0c <trap+0x5f>
f0103ef3:	68 46 7a 10 f0       	push   $0xf0107a46
f0103ef8:	68 4a 75 10 f0       	push   $0xf010754a
f0103efd:	68 42 01 00 00       	push   $0x142
f0103f02:	68 3a 7a 10 f0       	push   $0xf0107a3a
f0103f07:	e8 34 c1 ff ff       	call   f0100040 <_panic>

	if ((tf->tf_cs & 3) == 3) {
f0103f0c:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0103f10:	83 e0 03             	and    $0x3,%eax
f0103f13:	66 83 f8 03          	cmp    $0x3,%ax
f0103f17:	0f 85 a0 00 00 00    	jne    f0103fbd <trap+0x110>
f0103f1d:	83 ec 0c             	sub    $0xc,%esp
f0103f20:	68 c0 23 12 f0       	push   $0xf01223c0
f0103f25:	e8 6e 1d 00 00       	call   f0105c98 <spin_lock>
		// Trapped from user mode.
		// Acquire the big kernel lock before doing any
		// serious kernel work.
		// LAB 4: Your code here.
        lock_kernel();
		assert(curenv);
f0103f2a:	e8 fb 1a 00 00       	call   f0105a2a <cpunum>
f0103f2f:	6b c0 74             	imul   $0x74,%eax,%eax
f0103f32:	83 c4 10             	add    $0x10,%esp
f0103f35:	83 b8 28 a0 2a f0 00 	cmpl   $0x0,-0xfd55fd8(%eax)
f0103f3c:	75 19                	jne    f0103f57 <trap+0xaa>
f0103f3e:	68 5f 7a 10 f0       	push   $0xf0107a5f
f0103f43:	68 4a 75 10 f0       	push   $0xf010754a
f0103f48:	68 4a 01 00 00       	push   $0x14a
f0103f4d:	68 3a 7a 10 f0       	push   $0xf0107a3a
f0103f52:	e8 e9 c0 ff ff       	call   f0100040 <_panic>

		// Garbage collect if current enviroment is a zombie
		if (curenv->env_status == ENV_DYING) {
f0103f57:	e8 ce 1a 00 00       	call   f0105a2a <cpunum>
f0103f5c:	6b c0 74             	imul   $0x74,%eax,%eax
f0103f5f:	8b 80 28 a0 2a f0    	mov    -0xfd55fd8(%eax),%eax
f0103f65:	83 78 54 01          	cmpl   $0x1,0x54(%eax)
f0103f69:	75 2d                	jne    f0103f98 <trap+0xeb>
			env_free(curenv);
f0103f6b:	e8 ba 1a 00 00       	call   f0105a2a <cpunum>
f0103f70:	83 ec 0c             	sub    $0xc,%esp
f0103f73:	6b c0 74             	imul   $0x74,%eax,%eax
f0103f76:	ff b0 28 a0 2a f0    	pushl  -0xfd55fd8(%eax)
f0103f7c:	e8 4b f2 ff ff       	call   f01031cc <env_free>
			curenv = NULL;
f0103f81:	e8 a4 1a 00 00       	call   f0105a2a <cpunum>
f0103f86:	6b c0 74             	imul   $0x74,%eax,%eax
f0103f89:	c7 80 28 a0 2a f0 00 	movl   $0x0,-0xfd55fd8(%eax)
f0103f90:	00 00 00 
			sched_yield();
f0103f93:	e8 bf 02 00 00       	call   f0104257 <sched_yield>
		}

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f0103f98:	e8 8d 1a 00 00       	call   f0105a2a <cpunum>
f0103f9d:	6b c0 74             	imul   $0x74,%eax,%eax
f0103fa0:	8b 80 28 a0 2a f0    	mov    -0xfd55fd8(%eax),%eax
f0103fa6:	b9 11 00 00 00       	mov    $0x11,%ecx
f0103fab:	89 c7                	mov    %eax,%edi
f0103fad:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f0103faf:	e8 76 1a 00 00       	call   f0105a2a <cpunum>
f0103fb4:	6b c0 74             	imul   $0x74,%eax,%eax
f0103fb7:	8b b0 28 a0 2a f0    	mov    -0xfd55fd8(%eax),%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f0103fbd:	89 35 60 9a 2a f0    	mov    %esi,0xf02a9a60
trap_dispatch(struct Trapframe *tf)
{
	// Handle processor exceptions.
	// LAB 3: Your code here.
	int r;
	switch(tf->tf_trapno){
f0103fc3:	8b 46 28             	mov    0x28(%esi),%eax
f0103fc6:	83 f8 0e             	cmp    $0xe,%eax
f0103fc9:	74 30                	je     f0103ffb <trap+0x14e>
f0103fcb:	83 f8 30             	cmp    $0x30,%eax
f0103fce:	74 07                	je     f0103fd7 <trap+0x12a>
f0103fd0:	83 f8 03             	cmp    $0x3,%eax
f0103fd3:	75 48                	jne    f010401d <trap+0x170>
f0103fd5:	eb 35                	jmp    f010400c <trap+0x15f>
		case T_SYSCALL:
            tf->tf_regs.reg_eax = 
                syscall(tf->tf_regs.reg_eax, tf->tf_regs.reg_edx, tf->tf_regs.reg_ecx,
f0103fd7:	83 ec 08             	sub    $0x8,%esp
f0103fda:	ff 76 04             	pushl  0x4(%esi)
f0103fdd:	ff 36                	pushl  (%esi)
f0103fdf:	ff 76 10             	pushl  0x10(%esi)
f0103fe2:	ff 76 18             	pushl  0x18(%esi)
f0103fe5:	ff 76 14             	pushl  0x14(%esi)
f0103fe8:	ff 76 1c             	pushl  0x1c(%esi)
f0103feb:	e8 2b 03 00 00       	call   f010431b <syscall>
	// Handle processor exceptions.
	// LAB 3: Your code here.
	int r;
	switch(tf->tf_trapno){
		case T_SYSCALL:
            tf->tf_regs.reg_eax = 
f0103ff0:	89 46 1c             	mov    %eax,0x1c(%esi)
f0103ff3:	83 c4 20             	add    $0x20,%esp
f0103ff6:	e9 ab 00 00 00       	jmp    f01040a6 <trap+0x1f9>
            if (tf->tf_regs.reg_eax < 0) {
                panic("trap_dispatch: %e", tf->tf_regs.reg_eax);
            }
			return;
		case T_PGFLT:
			page_fault_handler(tf);
f0103ffb:	83 ec 0c             	sub    $0xc,%esp
f0103ffe:	56                   	push   %esi
f0103fff:	e8 90 fd ff ff       	call   f0103d94 <page_fault_handler>
f0104004:	83 c4 10             	add    $0x10,%esp
f0104007:	e9 9a 00 00 00       	jmp    f01040a6 <trap+0x1f9>
			return;
		case T_BRKPT:
			monitor(tf);
f010400c:	83 ec 0c             	sub    $0xc,%esp
f010400f:	56                   	push   %esi
f0104010:	e8 2a c9 ff ff       	call   f010093f <monitor>
f0104015:	83 c4 10             	add    $0x10,%esp
f0104018:	e9 89 00 00 00       	jmp    f01040a6 <trap+0x1f9>
	}

	// Handle spurious interrupts
	// The hardware sometimes raises these because of noise on the
	// IRQ line or other reasons. We don't care.
	if (tf->tf_trapno == IRQ_OFFSET + IRQ_SPURIOUS) {
f010401d:	83 f8 27             	cmp    $0x27,%eax
f0104020:	75 1a                	jne    f010403c <trap+0x18f>
		cprintf("Spurious interrupt on irq 7\n");
f0104022:	83 ec 0c             	sub    $0xc,%esp
f0104025:	68 66 7a 10 f0       	push   $0xf0107a66
f010402a:	e8 2e f6 ff ff       	call   f010365d <cprintf>
		print_trapframe(tf);
f010402f:	89 34 24             	mov    %esi,(%esp)
f0104032:	e8 d5 fb ff ff       	call   f0103c0c <print_trapframe>
f0104037:	83 c4 10             	add    $0x10,%esp
f010403a:	eb 6a                	jmp    f01040a6 <trap+0x1f9>
	}

	// Handle clock interrupts. Don't forget to acknowledge the
	// interrupt using lapic_eoi() before calling the scheduler!
	// LAB 4: Your code here.
    if (tf->tf_trapno == IRQ_OFFSET + IRQ_TIMER) {
f010403c:	83 f8 20             	cmp    $0x20,%eax
f010403f:	75 0a                	jne    f010404b <trap+0x19e>
        lapic_eoi();
f0104041:	e8 2f 1b 00 00       	call   f0105b75 <lapic_eoi>
        sched_yield();
f0104046:	e8 0c 02 00 00       	call   f0104257 <sched_yield>


	// Handle keyboard and serial interrupts.
	// LAB 5: Your code here.

    if (tf->tf_trapno == IRQ_OFFSET + IRQ_KBD) {
f010404b:	83 f8 21             	cmp    $0x21,%eax
f010404e:	75 07                	jne    f0104057 <trap+0x1aa>
        kbd_intr();
f0104050:	e8 bb c5 ff ff       	call   f0100610 <kbd_intr>
f0104055:	eb 4f                	jmp    f01040a6 <trap+0x1f9>
        return;
    }

    if (tf->tf_trapno == IRQ_OFFSET + IRQ_SERIAL) {
f0104057:	83 f8 24             	cmp    $0x24,%eax
f010405a:	75 07                	jne    f0104063 <trap+0x1b6>
        serial_intr();
f010405c:	e8 93 c5 ff ff       	call   f01005f4 <serial_intr>
f0104061:	eb 43                	jmp    f01040a6 <trap+0x1f9>
        return;
    }
	// Unexpected trap: The user process or the kernel has a bug.
	print_trapframe(tf);
f0104063:	83 ec 0c             	sub    $0xc,%esp
f0104066:	56                   	push   %esi
f0104067:	e8 a0 fb ff ff       	call   f0103c0c <print_trapframe>
	if (tf->tf_cs == GD_KT)
f010406c:	83 c4 10             	add    $0x10,%esp
f010406f:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f0104074:	75 17                	jne    f010408d <trap+0x1e0>
		panic("unhandled trap in kernel");
f0104076:	83 ec 04             	sub    $0x4,%esp
f0104079:	68 83 7a 10 f0       	push   $0xf0107a83
f010407e:	68 28 01 00 00       	push   $0x128
f0104083:	68 3a 7a 10 f0       	push   $0xf0107a3a
f0104088:	e8 b3 bf ff ff       	call   f0100040 <_panic>
	else {
		env_destroy(curenv);
f010408d:	e8 98 19 00 00       	call   f0105a2a <cpunum>
f0104092:	83 ec 0c             	sub    $0xc,%esp
f0104095:	6b c0 74             	imul   $0x74,%eax,%eax
f0104098:	ff b0 28 a0 2a f0    	pushl  -0xfd55fd8(%eax)
f010409e:	e8 cf f2 ff ff       	call   f0103372 <env_destroy>
f01040a3:	83 c4 10             	add    $0x10,%esp
	trap_dispatch(tf);

	// If we made it to this point, then no other environment was
	// scheduled, so we should return to the current environment
	// if doing so makes sense.
	if (curenv && curenv->env_status == ENV_RUNNING)
f01040a6:	e8 7f 19 00 00       	call   f0105a2a <cpunum>
f01040ab:	6b c0 74             	imul   $0x74,%eax,%eax
f01040ae:	83 b8 28 a0 2a f0 00 	cmpl   $0x0,-0xfd55fd8(%eax)
f01040b5:	74 2a                	je     f01040e1 <trap+0x234>
f01040b7:	e8 6e 19 00 00       	call   f0105a2a <cpunum>
f01040bc:	6b c0 74             	imul   $0x74,%eax,%eax
f01040bf:	8b 80 28 a0 2a f0    	mov    -0xfd55fd8(%eax),%eax
f01040c5:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f01040c9:	75 16                	jne    f01040e1 <trap+0x234>
		env_run(curenv);
f01040cb:	e8 5a 19 00 00       	call   f0105a2a <cpunum>
f01040d0:	83 ec 0c             	sub    $0xc,%esp
f01040d3:	6b c0 74             	imul   $0x74,%eax,%eax
f01040d6:	ff b0 28 a0 2a f0    	pushl  -0xfd55fd8(%eax)
f01040dc:	e8 30 f3 ff ff       	call   f0103411 <env_run>
	else
		sched_yield();
f01040e1:	e8 71 01 00 00       	call   f0104257 <sched_yield>

f01040e6 <t_divide>:
.text

/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */
TRAPHANDLER_NOEC(t_divide, T_DIVIDE)
f01040e6:	6a 00                	push   $0x0
f01040e8:	6a 00                	push   $0x0
f01040ea:	e9 83 00 00 00       	jmp    f0104172 <_alltraps>
f01040ef:	90                   	nop

f01040f0 <t_debug>:
TRAPHANDLER_NOEC(t_debug, T_DEBUG)
f01040f0:	6a 00                	push   $0x0
f01040f2:	6a 01                	push   $0x1
f01040f4:	eb 7c                	jmp    f0104172 <_alltraps>

f01040f6 <t_nmi>:
TRAPHANDLER_NOEC(t_nmi, T_NMI)
f01040f6:	6a 00                	push   $0x0
f01040f8:	6a 02                	push   $0x2
f01040fa:	eb 76                	jmp    f0104172 <_alltraps>

f01040fc <t_brkpt>:
TRAPHANDLER_NOEC(t_brkpt, T_BRKPT)
f01040fc:	6a 00                	push   $0x0
f01040fe:	6a 03                	push   $0x3
f0104100:	eb 70                	jmp    f0104172 <_alltraps>

f0104102 <t_oflow>:
TRAPHANDLER_NOEC(t_oflow, T_OFLOW)
f0104102:	6a 00                	push   $0x0
f0104104:	6a 04                	push   $0x4
f0104106:	eb 6a                	jmp    f0104172 <_alltraps>

f0104108 <t_bound>:
TRAPHANDLER_NOEC(t_bound, T_BOUND)
f0104108:	6a 00                	push   $0x0
f010410a:	6a 05                	push   $0x5
f010410c:	eb 64                	jmp    f0104172 <_alltraps>

f010410e <t_illop>:
TRAPHANDLER_NOEC(t_illop, T_ILLOP)
f010410e:	6a 00                	push   $0x0
f0104110:	6a 06                	push   $0x6
f0104112:	eb 5e                	jmp    f0104172 <_alltraps>

f0104114 <t_device>:
TRAPHANDLER_NOEC(t_device, T_DEVICE)
f0104114:	6a 00                	push   $0x0
f0104116:	6a 07                	push   $0x7
f0104118:	eb 58                	jmp    f0104172 <_alltraps>

f010411a <t_dblflt>:
TRAPHANDLER(t_dblflt, T_DBLFLT)
f010411a:	6a 08                	push   $0x8
f010411c:	eb 54                	jmp    f0104172 <_alltraps>

f010411e <t_tss>:
TRAPHANDLER(t_tss, T_TSS)
f010411e:	6a 0a                	push   $0xa
f0104120:	eb 50                	jmp    f0104172 <_alltraps>

f0104122 <t_segnp>:
TRAPHANDLER(t_segnp, T_SEGNP)
f0104122:	6a 0b                	push   $0xb
f0104124:	eb 4c                	jmp    f0104172 <_alltraps>

f0104126 <t_stack>:
TRAPHANDLER(t_stack, T_STACK)
f0104126:	6a 0c                	push   $0xc
f0104128:	eb 48                	jmp    f0104172 <_alltraps>

f010412a <t_gpflt>:
TRAPHANDLER(t_gpflt, T_GPFLT)
f010412a:	6a 0d                	push   $0xd
f010412c:	eb 44                	jmp    f0104172 <_alltraps>

f010412e <t_pgflt>:
TRAPHANDLER(t_pgflt, T_PGFLT)
f010412e:	6a 0e                	push   $0xe
f0104130:	eb 40                	jmp    f0104172 <_alltraps>

f0104132 <t_fperr>:
TRAPHANDLER_NOEC(t_fperr, T_FPERR)
f0104132:	6a 00                	push   $0x0
f0104134:	6a 10                	push   $0x10
f0104136:	eb 3a                	jmp    f0104172 <_alltraps>

f0104138 <t_align>:
TRAPHANDLER(t_align, T_ALIGN)
f0104138:	6a 11                	push   $0x11
f010413a:	eb 36                	jmp    f0104172 <_alltraps>

f010413c <t_mchk>:
TRAPHANDLER_NOEC(t_mchk, T_MCHK)
f010413c:	6a 00                	push   $0x0
f010413e:	6a 12                	push   $0x12
f0104140:	eb 30                	jmp    f0104172 <_alltraps>

f0104142 <t_simderr>:
TRAPHANDLER_NOEC(t_simderr, T_SIMDERR)
f0104142:	6a 00                	push   $0x0
f0104144:	6a 13                	push   $0x13
f0104146:	eb 2a                	jmp    f0104172 <_alltraps>

f0104148 <t_syscall>:
TRAPHANDLER_NOEC(t_syscall, T_SYSCALL)
f0104148:	6a 00                	push   $0x0
f010414a:	6a 30                	push   $0x30
f010414c:	eb 24                	jmp    f0104172 <_alltraps>

f010414e <irq_timer>:
TRAPHANDLER_NOEC(irq_timer, IRQ_OFFSET + IRQ_TIMER)
f010414e:	6a 00                	push   $0x0
f0104150:	6a 20                	push   $0x20
f0104152:	eb 1e                	jmp    f0104172 <_alltraps>

f0104154 <irq_kbd>:
TRAPHANDLER_NOEC(irq_kbd, IRQ_OFFSET + IRQ_KBD)
f0104154:	6a 00                	push   $0x0
f0104156:	6a 21                	push   $0x21
f0104158:	eb 18                	jmp    f0104172 <_alltraps>

f010415a <irq_serial>:
TRAPHANDLER_NOEC(irq_serial, IRQ_OFFSET + IRQ_SERIAL)
f010415a:	6a 00                	push   $0x0
f010415c:	6a 24                	push   $0x24
f010415e:	eb 12                	jmp    f0104172 <_alltraps>

f0104160 <irq_spurious>:
TRAPHANDLER_NOEC(irq_spurious, IRQ_OFFSET + IRQ_SPURIOUS)
f0104160:	6a 00                	push   $0x0
f0104162:	6a 27                	push   $0x27
f0104164:	eb 0c                	jmp    f0104172 <_alltraps>

f0104166 <irq_ide>:
TRAPHANDLER_NOEC(irq_ide, IRQ_OFFSET + IRQ_IDE)
f0104166:	6a 00                	push   $0x0
f0104168:	6a 2e                	push   $0x2e
f010416a:	eb 06                	jmp    f0104172 <_alltraps>

f010416c <irq_error>:
TRAPHANDLER_NOEC(irq_error, IRQ_OFFSET + IRQ_ERROR)
f010416c:	6a 00                	push   $0x0
f010416e:	6a 33                	push   $0x33
f0104170:	eb 00                	jmp    f0104172 <_alltraps>

f0104172 <_alltraps>:
/*
 * Lab 3: Your code here for _alltraps
 */
_alltraps:
	# Build trap frame.
	pushl %ds
f0104172:	1e                   	push   %ds
	pushl %es
f0104173:	06                   	push   %es
	pushal	
f0104174:	60                   	pusha  

	movw $(GD_KD), %ax
f0104175:	66 b8 10 00          	mov    $0x10,%ax
	movw %ax, %ds
f0104179:	8e d8                	mov    %eax,%ds
	movw %ax, %es
f010417b:	8e c0                	mov    %eax,%es

	pushl %esp
f010417d:	54                   	push   %esp
	call trap
f010417e:	e8 2a fd ff ff       	call   f0103ead <trap>

f0104183 <sched_halt>:
// Halt this CPU when there is nothing to do. Wait until the
// timer interrupt wakes it up. This function never returns.
//
void
sched_halt(void)
{
f0104183:	55                   	push   %ebp
f0104184:	89 e5                	mov    %esp,%ebp
f0104186:	83 ec 08             	sub    $0x8,%esp
f0104189:	a1 44 92 2a f0       	mov    0xf02a9244,%eax
f010418e:	8d 50 54             	lea    0x54(%eax),%edx
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
f0104191:	b9 00 00 00 00       	mov    $0x0,%ecx
		if ((envs[i].env_status == ENV_RUNNABLE ||
f0104196:	8b 02                	mov    (%edx),%eax
f0104198:	83 e8 01             	sub    $0x1,%eax
f010419b:	83 f8 02             	cmp    $0x2,%eax
f010419e:	76 10                	jbe    f01041b0 <sched_halt+0x2d>
{
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
f01041a0:	83 c1 01             	add    $0x1,%ecx
f01041a3:	83 c2 7c             	add    $0x7c,%edx
f01041a6:	81 f9 00 04 00 00    	cmp    $0x400,%ecx
f01041ac:	75 e8                	jne    f0104196 <sched_halt+0x13>
f01041ae:	eb 08                	jmp    f01041b8 <sched_halt+0x35>
		if ((envs[i].env_status == ENV_RUNNABLE ||
		     envs[i].env_status == ENV_RUNNING ||
		     envs[i].env_status == ENV_DYING))
			break;
	}
	if (i == NENV) {
f01041b0:	81 f9 00 04 00 00    	cmp    $0x400,%ecx
f01041b6:	75 1f                	jne    f01041d7 <sched_halt+0x54>
		cprintf("No runnable environments in the system!\n");
f01041b8:	83 ec 0c             	sub    $0xc,%esp
f01041bb:	68 90 7c 10 f0       	push   $0xf0107c90
f01041c0:	e8 98 f4 ff ff       	call   f010365d <cprintf>
f01041c5:	83 c4 10             	add    $0x10,%esp
		while (1)
			monitor(NULL);
f01041c8:	83 ec 0c             	sub    $0xc,%esp
f01041cb:	6a 00                	push   $0x0
f01041cd:	e8 6d c7 ff ff       	call   f010093f <monitor>
f01041d2:	83 c4 10             	add    $0x10,%esp
f01041d5:	eb f1                	jmp    f01041c8 <sched_halt+0x45>
	}

	// Mark that no environment is running on this CPU
	curenv = NULL;
f01041d7:	e8 4e 18 00 00       	call   f0105a2a <cpunum>
f01041dc:	6b c0 74             	imul   $0x74,%eax,%eax
f01041df:	c7 80 28 a0 2a f0 00 	movl   $0x0,-0xfd55fd8(%eax)
f01041e6:	00 00 00 
	lcr3(PADDR(kern_pgdir));
f01041e9:	a1 a4 9e 2a f0       	mov    0xf02a9ea4,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01041ee:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01041f3:	77 12                	ja     f0104207 <sched_halt+0x84>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01041f5:	50                   	push   %eax
f01041f6:	68 68 66 10 f0       	push   $0xf0106668
f01041fb:	6a 4f                	push   $0x4f
f01041fd:	68 b9 7c 10 f0       	push   $0xf0107cb9
f0104202:	e8 39 be ff ff       	call   f0100040 <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0104207:	05 00 00 00 10       	add    $0x10000000,%eax
f010420c:	0f 22 d8             	mov    %eax,%cr3

	// Mark that this CPU is in the HALT state, so that when
	// timer interupts come in, we know we should re-acquire the
	// big kernel lock
	xchg(&thiscpu->cpu_status, CPU_HALTED);
f010420f:	e8 16 18 00 00       	call   f0105a2a <cpunum>
f0104214:	6b d0 74             	imul   $0x74,%eax,%edx
f0104217:	81 c2 20 a0 2a f0    	add    $0xf02aa020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"
f010421d:	b8 02 00 00 00       	mov    $0x2,%eax
f0104222:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
}

static inline void
unlock_kernel(void)
{
	spin_unlock(&kernel_lock);
f0104226:	83 ec 0c             	sub    $0xc,%esp
f0104229:	68 c0 23 12 f0       	push   $0xf01223c0
f010422e:	e8 02 1b 00 00       	call   f0105d35 <spin_unlock>

	// Normally we wouldn't need to do this, but QEMU only runs
	// one CPU at a time and has a long time-slice.  Without the
	// pause, this CPU is likely to reacquire the lock before
	// another CPU has even been given a chance to acquire it.
	asm volatile("pause");
f0104233:	f3 90                	pause  
		"pushl $0\n"
		"sti\n"
		"1:\n"
		"hlt\n"
		"jmp 1b\n"
	: : "a" (thiscpu->cpu_ts.ts_esp0));
f0104235:	e8 f0 17 00 00       	call   f0105a2a <cpunum>
f010423a:	6b c0 74             	imul   $0x74,%eax,%eax

	// Release the big kernel lock as if we were "leaving" the kernel
	unlock_kernel();

	// Reset stack pointer, enable interrupts and then halt.
	asm volatile (
f010423d:	8b 80 30 a0 2a f0    	mov    -0xfd55fd0(%eax),%eax
f0104243:	bd 00 00 00 00       	mov    $0x0,%ebp
f0104248:	89 c4                	mov    %eax,%esp
f010424a:	6a 00                	push   $0x0
f010424c:	6a 00                	push   $0x0
f010424e:	fb                   	sti    
f010424f:	f4                   	hlt    
f0104250:	eb fd                	jmp    f010424f <sched_halt+0xcc>
		"sti\n"
		"1:\n"
		"hlt\n"
		"jmp 1b\n"
	: : "a" (thiscpu->cpu_ts.ts_esp0));
}
f0104252:	83 c4 10             	add    $0x10,%esp
f0104255:	c9                   	leave  
f0104256:	c3                   	ret    

f0104257 <sched_yield>:
void sched_halt(void);

// Choose a user environment to run and run it.
void
sched_yield(void)
{
f0104257:	55                   	push   %ebp
f0104258:	89 e5                	mov    %esp,%ebp
f010425a:	53                   	push   %ebx
f010425b:	83 ec 04             	sub    $0x4,%esp
	// no runnable environments, simply drop through to the code
	// below to halt the cpu.

	// LAB 4: Your code here.
    int cur_idx;
    if (curenv)
f010425e:	e8 c7 17 00 00       	call   f0105a2a <cpunum>
f0104263:	6b c0 74             	imul   $0x74,%eax,%eax
        cur_idx = ENVX(curenv->env_id);
    else
        cur_idx = 0;
f0104266:	ba 00 00 00 00       	mov    $0x0,%edx
	// no runnable environments, simply drop through to the code
	// below to halt the cpu.

	// LAB 4: Your code here.
    int cur_idx;
    if (curenv)
f010426b:	83 b8 28 a0 2a f0 00 	cmpl   $0x0,-0xfd55fd8(%eax)
f0104272:	74 17                	je     f010428b <sched_yield+0x34>
        cur_idx = ENVX(curenv->env_id);
f0104274:	e8 b1 17 00 00       	call   f0105a2a <cpunum>
f0104279:	6b c0 74             	imul   $0x74,%eax,%eax
f010427c:	8b 80 28 a0 2a f0    	mov    -0xfd55fd8(%eax),%eax
f0104282:	8b 50 48             	mov    0x48(%eax),%edx
f0104285:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
    else
        cur_idx = 0;

    if(envs[cur_idx].env_status == ENV_RUNNABLE){
f010428b:	8b 0d 44 92 2a f0    	mov    0xf02a9244,%ecx
f0104291:	6b c2 7c             	imul   $0x7c,%edx,%eax
f0104294:	01 c8                	add    %ecx,%eax
f0104296:	83 78 54 02          	cmpl   $0x2,0x54(%eax)
f010429a:	75 09                	jne    f01042a5 <sched_yield+0x4e>
        env_run(&envs[cur_idx]);
f010429c:	83 ec 0c             	sub    $0xc,%esp
f010429f:	50                   	push   %eax
f01042a0:	e8 6c f1 ff ff       	call   f0103411 <env_run>
    }
    for(int i = cur_idx + 1; i != cur_idx; i = (i + 1) % NENV){
f01042a5:	8d 42 01             	lea    0x1(%edx),%eax
f01042a8:	eb 28                	jmp    f01042d2 <sched_yield+0x7b>
        if(envs[i].env_status == ENV_RUNNABLE){
f01042aa:	6b d8 7c             	imul   $0x7c,%eax,%ebx
f01042ad:	01 cb                	add    %ecx,%ebx
f01042af:	83 7b 54 02          	cmpl   $0x2,0x54(%ebx)
f01042b3:	75 09                	jne    f01042be <sched_yield+0x67>
            env_run(&envs[i]);
f01042b5:	83 ec 0c             	sub    $0xc,%esp
f01042b8:	53                   	push   %ebx
f01042b9:	e8 53 f1 ff ff       	call   f0103411 <env_run>
        cur_idx = 0;

    if(envs[cur_idx].env_status == ENV_RUNNABLE){
        env_run(&envs[cur_idx]);
    }
    for(int i = cur_idx + 1; i != cur_idx; i = (i + 1) % NENV){
f01042be:	83 c0 01             	add    $0x1,%eax
f01042c1:	89 c3                	mov    %eax,%ebx
f01042c3:	c1 fb 1f             	sar    $0x1f,%ebx
f01042c6:	c1 eb 16             	shr    $0x16,%ebx
f01042c9:	01 d8                	add    %ebx,%eax
f01042cb:	25 ff 03 00 00       	and    $0x3ff,%eax
f01042d0:	29 d8                	sub    %ebx,%eax
f01042d2:	39 c2                	cmp    %eax,%edx
f01042d4:	75 d4                	jne    f01042aa <sched_yield+0x53>
        if(envs[i].env_status == ENV_RUNNABLE){
            env_run(&envs[i]);
            return;
        } 
    }
    if(curenv && curenv->env_status == ENV_RUNNING) {
f01042d6:	e8 4f 17 00 00       	call   f0105a2a <cpunum>
f01042db:	6b c0 74             	imul   $0x74,%eax,%eax
f01042de:	83 b8 28 a0 2a f0 00 	cmpl   $0x0,-0xfd55fd8(%eax)
f01042e5:	74 2a                	je     f0104311 <sched_yield+0xba>
f01042e7:	e8 3e 17 00 00       	call   f0105a2a <cpunum>
f01042ec:	6b c0 74             	imul   $0x74,%eax,%eax
f01042ef:	8b 80 28 a0 2a f0    	mov    -0xfd55fd8(%eax),%eax
f01042f5:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f01042f9:	75 16                	jne    f0104311 <sched_yield+0xba>
        env_run(curenv);
f01042fb:	e8 2a 17 00 00       	call   f0105a2a <cpunum>
f0104300:	83 ec 0c             	sub    $0xc,%esp
f0104303:	6b c0 74             	imul   $0x74,%eax,%eax
f0104306:	ff b0 28 a0 2a f0    	pushl  -0xfd55fd8(%eax)
f010430c:	e8 00 f1 ff ff       	call   f0103411 <env_run>
        return;
    }

	// sched_halt never returns
	sched_halt();
f0104311:	e8 6d fe ff ff       	call   f0104183 <sched_halt>
}
f0104316:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0104319:	c9                   	leave  
f010431a:	c3                   	ret    

f010431b <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f010431b:	55                   	push   %ebp
f010431c:	89 e5                	mov    %esp,%ebp
f010431e:	57                   	push   %edi
f010431f:	56                   	push   %esi
f0104320:	53                   	push   %ebx
f0104321:	83 ec 1c             	sub    $0x1c,%esp
f0104324:	8b 45 08             	mov    0x8(%ebp),%eax
	// Call the function corresponding to the 'syscallno' parameter.
	// Return any appropriate return value.
	// LAB 3: Your code here.

	switch (syscallno) {
f0104327:	83 f8 0d             	cmp    $0xd,%eax
f010432a:	0f 87 07 05 00 00    	ja     f0104837 <syscall+0x51c>
f0104330:	ff 24 85 cc 7c 10 f0 	jmp    *-0xfef8334(,%eax,4)
{
	// Check that the user has permission to read memory [s, s+len).
	// Destroy the environment if not.

	// LAB 3: Your code here.
	user_mem_assert(curenv, s, len, PTE_U | PTE_W);
f0104337:	e8 ee 16 00 00       	call   f0105a2a <cpunum>
f010433c:	6a 06                	push   $0x6
f010433e:	ff 75 10             	pushl  0x10(%ebp)
f0104341:	ff 75 0c             	pushl  0xc(%ebp)
f0104344:	6b c0 74             	imul   $0x74,%eax,%eax
f0104347:	ff b0 28 a0 2a f0    	pushl  -0xfd55fd8(%eax)
f010434d:	e8 41 ea ff ff       	call   f0102d93 <user_mem_assert>

	// Print the string supplied by the user.
	cprintf("%.*s", len, s);
f0104352:	83 c4 0c             	add    $0xc,%esp
f0104355:	ff 75 0c             	pushl  0xc(%ebp)
f0104358:	ff 75 10             	pushl  0x10(%ebp)
f010435b:	68 c6 7c 10 f0       	push   $0xf0107cc6
f0104360:	e8 f8 f2 ff ff       	call   f010365d <cprintf>
f0104365:	83 c4 10             	add    $0x10,%esp
	// LAB 3: Your code here.

	switch (syscallno) {
		case SYS_cputs:
			sys_cputs((const char *) a1,(size_t) a2);
			return 0;
f0104368:	b8 00 00 00 00       	mov    $0x0,%eax
f010436d:	e9 d1 04 00 00       	jmp    f0104843 <syscall+0x528>
// Read a character from the system console without blocking.
// Returns the character, or 0 if there is no input waiting.
static int
sys_cgetc(void)
{
	return cons_getc();
f0104372:	e8 ab c2 ff ff       	call   f0100622 <cons_getc>
	switch (syscallno) {
		case SYS_cputs:
			sys_cputs((const char *) a1,(size_t) a2);
			return 0;
		case SYS_cgetc:
			return sys_cgetc();
f0104377:	e9 c7 04 00 00       	jmp    f0104843 <syscall+0x528>

// Returns the current environment's envid.
static envid_t
sys_getenvid(void)
{
	return curenv->env_id;
f010437c:	e8 a9 16 00 00       	call   f0105a2a <cpunum>
f0104381:	6b c0 74             	imul   $0x74,%eax,%eax
f0104384:	8b 80 28 a0 2a f0    	mov    -0xfd55fd8(%eax),%eax
f010438a:	8b 40 48             	mov    0x48(%eax),%eax
			sys_cputs((const char *) a1,(size_t) a2);
			return 0;
		case SYS_cgetc:
			return sys_cgetc();
		case SYS_getenvid:
			return sys_getenvid();
f010438d:	e9 b1 04 00 00       	jmp    f0104843 <syscall+0x528>
sys_env_destroy(envid_t envid)
{
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
f0104392:	83 ec 04             	sub    $0x4,%esp
f0104395:	6a 01                	push   $0x1
f0104397:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010439a:	50                   	push   %eax
f010439b:	ff 75 0c             	pushl  0xc(%ebp)
f010439e:	e8 a5 ea ff ff       	call   f0102e48 <envid2env>
f01043a3:	83 c4 10             	add    $0x10,%esp
f01043a6:	85 c0                	test   %eax,%eax
f01043a8:	0f 88 95 04 00 00    	js     f0104843 <syscall+0x528>
		return r;
	env_destroy(e);
f01043ae:	83 ec 0c             	sub    $0xc,%esp
f01043b1:	ff 75 e4             	pushl  -0x1c(%ebp)
f01043b4:	e8 b9 ef ff ff       	call   f0103372 <env_destroy>
f01043b9:	83 c4 10             	add    $0x10,%esp
	return 0;
f01043bc:	b8 00 00 00 00       	mov    $0x0,%eax
f01043c1:	e9 7d 04 00 00       	jmp    f0104843 <syscall+0x528>

// Deschedule current environment and pick a different one to run.
static void
sys_yield(void)
{
	sched_yield();
f01043c6:	e8 8c fe ff ff       	call   f0104257 <sched_yield>
	// status is set to ENV_NOT_RUNNABLE, and the register set is copied
	// from the current environment -- but tweaked so sys_exofork
	// will appear to return 0.
    struct Env *child_env;
    int r;
    r = env_alloc(&child_env, curenv->env_id);
f01043cb:	e8 5a 16 00 00       	call   f0105a2a <cpunum>
f01043d0:	83 ec 08             	sub    $0x8,%esp
f01043d3:	6b c0 74             	imul   $0x74,%eax,%eax
f01043d6:	8b 80 28 a0 2a f0    	mov    -0xfd55fd8(%eax),%eax
f01043dc:	ff 70 48             	pushl  0x48(%eax)
f01043df:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01043e2:	50                   	push   %eax
f01043e3:	e8 72 eb ff ff       	call   f0102f5a <env_alloc>
    if(r!=0)
f01043e8:	83 c4 10             	add    $0x10,%esp
f01043eb:	85 c0                	test   %eax,%eax
f01043ed:	0f 85 50 04 00 00    	jne    f0104843 <syscall+0x528>
        return r;
    child_env->env_status = ENV_NOT_RUNNABLE;
f01043f3:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01043f6:	c7 43 54 04 00 00 00 	movl   $0x4,0x54(%ebx)
    child_env->env_tf = curenv->env_tf;
f01043fd:	e8 28 16 00 00       	call   f0105a2a <cpunum>
f0104402:	6b c0 74             	imul   $0x74,%eax,%eax
f0104405:	8b b0 28 a0 2a f0    	mov    -0xfd55fd8(%eax),%esi
f010440b:	b9 11 00 00 00       	mov    $0x11,%ecx
f0104410:	89 df                	mov    %ebx,%edi
f0104412:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
    child_env->env_tf.tf_regs.reg_eax = 0;
f0104414:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104417:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)
    return child_env->env_id;
f010441e:	8b 40 48             	mov    0x48(%eax),%eax
f0104421:	e9 1d 04 00 00       	jmp    f0104843 <syscall+0x528>
	//   parameters for correctness.
	//   If page_insert() fails, remember to free the page you
	//   allocated!

    struct Env *env;
    int r = envid2env(envid, &env, 1);
f0104426:	83 ec 04             	sub    $0x4,%esp
f0104429:	6a 01                	push   $0x1
f010442b:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010442e:	50                   	push   %eax
f010442f:	ff 75 0c             	pushl  0xc(%ebp)
f0104432:	e8 11 ea ff ff       	call   f0102e48 <envid2env>
    if(r!=0)
f0104437:	83 c4 10             	add    $0x10,%esp
f010443a:	85 c0                	test   %eax,%eax
f010443c:	0f 85 01 04 00 00    	jne    f0104843 <syscall+0x528>
        return r;
    if (va > (void *) UTOP || va != ROUNDDOWN(va, PGSIZE))
f0104442:	81 7d 10 00 00 c0 ee 	cmpl   $0xeec00000,0x10(%ebp)
f0104449:	77 62                	ja     f01044ad <syscall+0x192>
f010444b:	f7 45 10 ff 0f 00 00 	testl  $0xfff,0x10(%ebp)
f0104452:	75 63                	jne    f01044b7 <syscall+0x19c>
       return -E_INVAL; 
    int flag = PTE_U | PTE_P;

    if ((perm & flag) != flag)
f0104454:	8b 45 14             	mov    0x14(%ebp),%eax
f0104457:	83 e0 05             	and    $0x5,%eax
f010445a:	83 f8 05             	cmp    $0x5,%eax
f010445d:	75 62                	jne    f01044c1 <syscall+0x1a6>
        return -E_INVAL;

    if (perm & (~(PTE_U | PTE_P | PTE_AVAIL | PTE_W)))
f010445f:	f7 45 14 f8 f1 ff ff 	testl  $0xfffff1f8,0x14(%ebp)
f0104466:	75 63                	jne    f01044cb <syscall+0x1b0>
        return -E_INVAL;

    struct PageInfo *pp = page_alloc(1);
f0104468:	83 ec 0c             	sub    $0xc,%esp
f010446b:	6a 01                	push   $0x1
f010446d:	e8 43 cb ff ff       	call   f0100fb5 <page_alloc>
f0104472:	89 c6                	mov    %eax,%esi
    if(pp == NULL)
f0104474:	83 c4 10             	add    $0x10,%esp
f0104477:	85 c0                	test   %eax,%eax
f0104479:	74 5a                	je     f01044d5 <syscall+0x1ba>
        return -E_NO_MEM;
    r = page_insert(env->env_pgdir, pp, va, perm);
f010447b:	ff 75 14             	pushl  0x14(%ebp)
f010447e:	ff 75 10             	pushl  0x10(%ebp)
f0104481:	50                   	push   %eax
f0104482:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104485:	ff 70 60             	pushl  0x60(%eax)
f0104488:	e8 cd cd ff ff       	call   f010125a <page_insert>
f010448d:	89 c3                	mov    %eax,%ebx
    if(r!=0){
f010448f:	83 c4 10             	add    $0x10,%esp
f0104492:	85 c0                	test   %eax,%eax
f0104494:	0f 84 a9 03 00 00    	je     f0104843 <syscall+0x528>
        page_free(pp);
f010449a:	83 ec 0c             	sub    $0xc,%esp
f010449d:	56                   	push   %esi
f010449e:	e8 89 cb ff ff       	call   f010102c <page_free>
f01044a3:	83 c4 10             	add    $0x10,%esp
        return r;
f01044a6:	89 d8                	mov    %ebx,%eax
f01044a8:	e9 96 03 00 00       	jmp    f0104843 <syscall+0x528>
    struct Env *env;
    int r = envid2env(envid, &env, 1);
    if(r!=0)
        return r;
    if (va > (void *) UTOP || va != ROUNDDOWN(va, PGSIZE))
       return -E_INVAL; 
f01044ad:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f01044b2:	e9 8c 03 00 00       	jmp    f0104843 <syscall+0x528>
f01044b7:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f01044bc:	e9 82 03 00 00       	jmp    f0104843 <syscall+0x528>
    int flag = PTE_U | PTE_P;

    if ((perm & flag) != flag)
        return -E_INVAL;
f01044c1:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f01044c6:	e9 78 03 00 00       	jmp    f0104843 <syscall+0x528>

    if (perm & (~(PTE_U | PTE_P | PTE_AVAIL | PTE_W)))
        return -E_INVAL;
f01044cb:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f01044d0:	e9 6e 03 00 00       	jmp    f0104843 <syscall+0x528>

    struct PageInfo *pp = page_alloc(1);
    if(pp == NULL)
        return -E_NO_MEM;
f01044d5:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f01044da:	e9 64 03 00 00       	jmp    f0104843 <syscall+0x528>
	//   parameters for correctness.
	//   Use the third argument to page_lookup() to
	//   check the current permissions on the page.

    struct Env *srcenv, *dstenv;
    int r = envid2env(srcenvid, &srcenv, 1);
f01044df:	83 ec 04             	sub    $0x4,%esp
f01044e2:	6a 01                	push   $0x1
f01044e4:	8d 45 dc             	lea    -0x24(%ebp),%eax
f01044e7:	50                   	push   %eax
f01044e8:	ff 75 0c             	pushl  0xc(%ebp)
f01044eb:	e8 58 e9 ff ff       	call   f0102e48 <envid2env>
    if(r!=0)
f01044f0:	83 c4 10             	add    $0x10,%esp
f01044f3:	85 c0                	test   %eax,%eax
f01044f5:	0f 85 48 03 00 00    	jne    f0104843 <syscall+0x528>
        return r;
    r = envid2env(dstenvid, &dstenv, 1);
f01044fb:	83 ec 04             	sub    $0x4,%esp
f01044fe:	6a 01                	push   $0x1
f0104500:	8d 45 e0             	lea    -0x20(%ebp),%eax
f0104503:	50                   	push   %eax
f0104504:	ff 75 14             	pushl  0x14(%ebp)
f0104507:	e8 3c e9 ff ff       	call   f0102e48 <envid2env>
    if(r!=0)
f010450c:	83 c4 10             	add    $0x10,%esp
f010450f:	85 c0                	test   %eax,%eax
f0104511:	0f 85 2c 03 00 00    	jne    f0104843 <syscall+0x528>
        return r;

    if (srcva >= (void *) UTOP || dstva >= (void *) UTOP || 
f0104517:	81 7d 10 ff ff bf ee 	cmpl   $0xeebfffff,0x10(%ebp)
f010451e:	77 77                	ja     f0104597 <syscall+0x27c>
f0104520:	81 7d 18 ff ff bf ee 	cmpl   $0xeebfffff,0x18(%ebp)
f0104527:	77 6e                	ja     f0104597 <syscall+0x27c>
f0104529:	f7 45 10 ff 0f 00 00 	testl  $0xfff,0x10(%ebp)
f0104530:	75 6f                	jne    f01045a1 <syscall+0x286>
        srcva != ROUNDDOWN(srcva, PGSIZE) || dstva != ROUNDDOWN(dstva, PGSIZE))
        return -E_INVAL; 
f0104532:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
    r = envid2env(dstenvid, &dstenv, 1);
    if(r!=0)
        return r;

    if (srcva >= (void *) UTOP || dstva >= (void *) UTOP || 
        srcva != ROUNDDOWN(srcva, PGSIZE) || dstva != ROUNDDOWN(dstva, PGSIZE))
f0104537:	f7 45 18 ff 0f 00 00 	testl  $0xfff,0x18(%ebp)
f010453e:	0f 85 ff 02 00 00    	jne    f0104843 <syscall+0x528>
        return -E_INVAL; 

    pte_t *pte;
    struct PageInfo *pp = page_lookup(srcenv->env_pgdir, srcva, &pte);
f0104544:	83 ec 04             	sub    $0x4,%esp
f0104547:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010454a:	50                   	push   %eax
f010454b:	ff 75 10             	pushl  0x10(%ebp)
f010454e:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0104551:	ff 70 60             	pushl  0x60(%eax)
f0104554:	e8 2c cc ff ff       	call   f0101185 <page_lookup>
    if(pp == NULL)    
f0104559:	83 c4 10             	add    $0x10,%esp
f010455c:	85 c0                	test   %eax,%eax
f010455e:	74 4b                	je     f01045ab <syscall+0x290>
        return -E_INVAL;

    if ((!(perm & (PTE_U | PTE_P))) || (perm & (~(PTE_U | PTE_P | PTE_AVAIL | PTE_W))))
f0104560:	f6 45 1c 05          	testb  $0x5,0x1c(%ebp)
f0104564:	74 4f                	je     f01045b5 <syscall+0x29a>
f0104566:	f7 45 1c f8 f1 ff ff 	testl  $0xfffff1f8,0x1c(%ebp)
f010456d:	75 50                	jne    f01045bf <syscall+0x2a4>
        return -E_INVAL;

    if ((perm & PTE_W) && !(*pte & PTE_W))
f010456f:	f6 45 1c 02          	testb  $0x2,0x1c(%ebp)
f0104573:	74 08                	je     f010457d <syscall+0x262>
f0104575:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0104578:	f6 02 02             	testb  $0x2,(%edx)
f010457b:	74 4c                	je     f01045c9 <syscall+0x2ae>
        return -E_INVAL;

    r = page_insert(dstenv->env_pgdir, pp, dstva, perm);
f010457d:	ff 75 1c             	pushl  0x1c(%ebp)
f0104580:	ff 75 18             	pushl  0x18(%ebp)
f0104583:	50                   	push   %eax
f0104584:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104587:	ff 70 60             	pushl  0x60(%eax)
f010458a:	e8 cb cc ff ff       	call   f010125a <page_insert>
f010458f:	83 c4 10             	add    $0x10,%esp
f0104592:	e9 ac 02 00 00       	jmp    f0104843 <syscall+0x528>
    if(r!=0)
        return r;

    if (srcva >= (void *) UTOP || dstva >= (void *) UTOP || 
        srcva != ROUNDDOWN(srcva, PGSIZE) || dstva != ROUNDDOWN(dstva, PGSIZE))
        return -E_INVAL; 
f0104597:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f010459c:	e9 a2 02 00 00       	jmp    f0104843 <syscall+0x528>
f01045a1:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f01045a6:	e9 98 02 00 00       	jmp    f0104843 <syscall+0x528>

    pte_t *pte;
    struct PageInfo *pp = page_lookup(srcenv->env_pgdir, srcva, &pte);
    if(pp == NULL)    
        return -E_INVAL;
f01045ab:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f01045b0:	e9 8e 02 00 00       	jmp    f0104843 <syscall+0x528>

    if ((!(perm & (PTE_U | PTE_P))) || (perm & (~(PTE_U | PTE_P | PTE_AVAIL | PTE_W))))
        return -E_INVAL;
f01045b5:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f01045ba:	e9 84 02 00 00       	jmp    f0104843 <syscall+0x528>
f01045bf:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f01045c4:	e9 7a 02 00 00       	jmp    f0104843 <syscall+0x528>

    if ((perm & PTE_W) && !(*pte & PTE_W))
        return -E_INVAL;
f01045c9:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
        case SYS_exofork:
            return sys_exofork();
        case SYS_page_alloc:
            return sys_page_alloc(a1, (void *) a2, a3);
        case SYS_page_map:
            return sys_page_map(a1, (void *) a2, a3, (void *) a4, a5);
f01045ce:	e9 70 02 00 00       	jmp    f0104843 <syscall+0x528>
sys_page_unmap(envid_t envid, void *va)
{
	// Hint: This function is a wrapper around page_remove().

    struct Env *env;
    int r = envid2env(envid, &env, 1);
f01045d3:	83 ec 04             	sub    $0x4,%esp
f01045d6:	6a 01                	push   $0x1
f01045d8:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01045db:	50                   	push   %eax
f01045dc:	ff 75 0c             	pushl  0xc(%ebp)
f01045df:	e8 64 e8 ff ff       	call   f0102e48 <envid2env>
    if(r!=0)
f01045e4:	83 c4 10             	add    $0x10,%esp
f01045e7:	85 c0                	test   %eax,%eax
f01045e9:	0f 85 54 02 00 00    	jne    f0104843 <syscall+0x528>
        return r;
    if (va > (void *)UTOP || va != ROUNDDOWN(va, PGSIZE))
f01045ef:	81 7d 10 00 00 c0 ee 	cmpl   $0xeec00000,0x10(%ebp)
f01045f6:	77 30                	ja     f0104628 <syscall+0x30d>
        return -E_INVAL; 
f01045f8:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

    struct Env *env;
    int r = envid2env(envid, &env, 1);
    if(r!=0)
        return r;
    if (va > (void *)UTOP || va != ROUNDDOWN(va, PGSIZE))
f01045fd:	f7 45 10 ff 0f 00 00 	testl  $0xfff,0x10(%ebp)
f0104604:	0f 85 39 02 00 00    	jne    f0104843 <syscall+0x528>
        return -E_INVAL; 
    
    page_remove(env->env_pgdir, va);
f010460a:	83 ec 08             	sub    $0x8,%esp
f010460d:	ff 75 10             	pushl  0x10(%ebp)
f0104610:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104613:	ff 70 60             	pushl  0x60(%eax)
f0104616:	e8 f9 cb ff ff       	call   f0101214 <page_remove>
f010461b:	83 c4 10             	add    $0x10,%esp
    return 0;
f010461e:	b8 00 00 00 00       	mov    $0x0,%eax
f0104623:	e9 1b 02 00 00       	jmp    f0104843 <syscall+0x528>
    struct Env *env;
    int r = envid2env(envid, &env, 1);
    if(r!=0)
        return r;
    if (va > (void *)UTOP || va != ROUNDDOWN(va, PGSIZE))
        return -E_INVAL; 
f0104628:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f010462d:	e9 11 02 00 00       	jmp    f0104843 <syscall+0x528>
	// envid to a struct Env.
	// You should set envid2env's third argument to 1, which will
	// check whether the current environment has permission to set
	// envid's status.
    struct Env *env;
    int r = envid2env(envid, &env, 1);
f0104632:	83 ec 04             	sub    $0x4,%esp
f0104635:	6a 01                	push   $0x1
f0104637:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010463a:	50                   	push   %eax
f010463b:	ff 75 0c             	pushl  0xc(%ebp)
f010463e:	e8 05 e8 ff ff       	call   f0102e48 <envid2env>
    if(r!=0)
f0104643:	83 c4 10             	add    $0x10,%esp
f0104646:	85 c0                	test   %eax,%eax
f0104648:	0f 85 f5 01 00 00    	jne    f0104843 <syscall+0x528>
        return r;
    if(env->env_status == ENV_RUNNABLE || env->env_status == ENV_NOT_RUNNABLE){
f010464e:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0104651:	8b 42 54             	mov    0x54(%edx),%eax
f0104654:	83 e8 02             	sub    $0x2,%eax
f0104657:	a9 fd ff ff ff       	test   $0xfffffffd,%eax
f010465c:	75 10                	jne    f010466e <syscall+0x353>
        env->env_status = status;
f010465e:	8b 45 10             	mov    0x10(%ebp),%eax
f0104661:	89 42 54             	mov    %eax,0x54(%edx)
        return 0;
f0104664:	b8 00 00 00 00       	mov    $0x0,%eax
f0104669:	e9 d5 01 00 00       	jmp    f0104843 <syscall+0x528>
    }
    return -E_INVAL; 
f010466e:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
        case SYS_page_map:
            return sys_page_map(a1, (void *) a2, a3, (void *) a4, a5);
        case SYS_page_unmap:
            return sys_page_unmap(a1, (void *) a2);
        case SYS_env_set_status:
            return sys_env_set_status(a1, a2);
f0104673:	e9 cb 01 00 00       	jmp    f0104843 <syscall+0x528>
static int
sys_env_set_pgfault_upcall(envid_t envid, void *func)
{
	// LAB 4: Your code here.
    struct Env *env;
    int r = envid2env(envid, &env, 1);
f0104678:	83 ec 04             	sub    $0x4,%esp
f010467b:	6a 01                	push   $0x1
f010467d:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104680:	50                   	push   %eax
f0104681:	ff 75 0c             	pushl  0xc(%ebp)
f0104684:	e8 bf e7 ff ff       	call   f0102e48 <envid2env>
    if(r!=0)
f0104689:	83 c4 10             	add    $0x10,%esp
f010468c:	85 c0                	test   %eax,%eax
f010468e:	0f 85 af 01 00 00    	jne    f0104843 <syscall+0x528>
        return r;
    env->env_pgfault_upcall = func;
f0104694:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0104697:	8b 7d 10             	mov    0x10(%ebp),%edi
f010469a:	89 7a 64             	mov    %edi,0x64(%edx)
        case SYS_page_unmap:
            return sys_page_unmap(a1, (void *) a2);
        case SYS_env_set_status:
            return sys_env_set_status(a1, a2);
        case SYS_env_set_pgfault_upcall:
            return sys_env_set_pgfault_upcall(a1,(void *) a2);
f010469d:	e9 a1 01 00 00       	jmp    f0104843 <syscall+0x528>
//		address space.
static int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, unsigned perm)
{
    struct Env *env;
    int r = envid2env(envid, &env, 0);
f01046a2:	83 ec 04             	sub    $0x4,%esp
f01046a5:	6a 00                	push   $0x0
f01046a7:	8d 45 e0             	lea    -0x20(%ebp),%eax
f01046aa:	50                   	push   %eax
f01046ab:	ff 75 0c             	pushl  0xc(%ebp)
f01046ae:	e8 95 e7 ff ff       	call   f0102e48 <envid2env>
    if(r!=0)
f01046b3:	83 c4 10             	add    $0x10,%esp
f01046b6:	85 c0                	test   %eax,%eax
f01046b8:	0f 85 85 01 00 00    	jne    f0104843 <syscall+0x528>
        return r;
    if(!env->env_ipc_recving)
f01046be:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01046c1:	80 78 68 00          	cmpb   $0x0,0x68(%eax)
f01046c5:	0f 84 df 00 00 00    	je     f01047aa <syscall+0x48f>
        return -E_IPC_NOT_RECV;
    if(srcva < (void *) UTOP){
f01046cb:	81 7d 14 ff ff bf ee 	cmpl   $0xeebfffff,0x14(%ebp)
f01046d2:	0f 87 96 00 00 00    	ja     f010476e <syscall+0x453>
        if(srcva != ROUNDDOWN(srcva, PGSIZE)) 
            return -E_INVAL;
f01046d8:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
    if(r!=0)
        return r;
    if(!env->env_ipc_recving)
        return -E_IPC_NOT_RECV;
    if(srcva < (void *) UTOP){
        if(srcva != ROUNDDOWN(srcva, PGSIZE)) 
f01046dd:	f7 45 14 ff 0f 00 00 	testl  $0xfff,0x14(%ebp)
f01046e4:	0f 85 59 01 00 00    	jne    f0104843 <syscall+0x528>
            return -E_INVAL;

        pte_t *pte;
        struct PageInfo *pp = page_lookup(curenv->env_pgdir, srcva, &pte);
f01046ea:	e8 3b 13 00 00       	call   f0105a2a <cpunum>
f01046ef:	83 ec 04             	sub    $0x4,%esp
f01046f2:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01046f5:	52                   	push   %edx
f01046f6:	ff 75 14             	pushl  0x14(%ebp)
f01046f9:	6b c0 74             	imul   $0x74,%eax,%eax
f01046fc:	8b 80 28 a0 2a f0    	mov    -0xfd55fd8(%eax),%eax
f0104702:	ff 70 60             	pushl  0x60(%eax)
f0104705:	e8 7b ca ff ff       	call   f0101185 <page_lookup>
f010470a:	89 c2                	mov    %eax,%edx
        if(pp == NULL)
f010470c:	83 c4 10             	add    $0x10,%esp
f010470f:	85 c0                	test   %eax,%eax
f0104711:	74 51                	je     f0104764 <syscall+0x449>
            return -E_INVAL;

        if((perm & PTE_U) == 0 || (perm & PTE_P) == 0 || (perm & ~PTE_SYSCALL) != 0)
f0104713:	8b 4d 18             	mov    0x18(%ebp),%ecx
f0104716:	81 e1 fd f1 ff ff    	and    $0xfffff1fd,%ecx
            return -E_INVAL;
f010471c:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
        pte_t *pte;
        struct PageInfo *pp = page_lookup(curenv->env_pgdir, srcva, &pte);
        if(pp == NULL)
            return -E_INVAL;

        if((perm & PTE_U) == 0 || (perm & PTE_P) == 0 || (perm & ~PTE_SYSCALL) != 0)
f0104721:	83 f9 05             	cmp    $0x5,%ecx
f0104724:	0f 85 19 01 00 00    	jne    f0104843 <syscall+0x528>
            return -E_INVAL;

        if ((perm & PTE_W) && !(*pte & PTE_W))
f010472a:	f6 45 18 02          	testb  $0x2,0x18(%ebp)
f010472e:	74 0c                	je     f010473c <syscall+0x421>
f0104730:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0104733:	f6 01 02             	testb  $0x2,(%ecx)
f0104736:	0f 84 07 01 00 00    	je     f0104843 <syscall+0x528>
            return -E_INVAL;


        r = page_insert(env->env_pgdir, pp, env->env_ipc_dstva, perm);
f010473c:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010473f:	ff 75 18             	pushl  0x18(%ebp)
f0104742:	ff 70 6c             	pushl  0x6c(%eax)
f0104745:	52                   	push   %edx
f0104746:	ff 70 60             	pushl  0x60(%eax)
f0104749:	e8 0c cb ff ff       	call   f010125a <page_insert>
        if(r!=0)
f010474e:	83 c4 10             	add    $0x10,%esp
f0104751:	85 c0                	test   %eax,%eax
f0104753:	0f 85 ea 00 00 00    	jne    f0104843 <syscall+0x528>
            return r;
        env->env_ipc_perm = perm;
f0104759:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010475c:	8b 4d 18             	mov    0x18(%ebp),%ecx
f010475f:	89 48 78             	mov    %ecx,0x78(%eax)
f0104762:	eb 0a                	jmp    f010476e <syscall+0x453>
            return -E_INVAL;

        pte_t *pte;
        struct PageInfo *pp = page_lookup(curenv->env_pgdir, srcva, &pte);
        if(pp == NULL)
            return -E_INVAL;
f0104764:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104769:	e9 d5 00 00 00       	jmp    f0104843 <syscall+0x528>
        r = page_insert(env->env_pgdir, pp, env->env_ipc_dstva, perm);
        if(r!=0)
            return r;
        env->env_ipc_perm = perm;
    }
    env->env_ipc_value = value;
f010476e:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0104771:	8b 45 10             	mov    0x10(%ebp),%eax
f0104774:	89 43 70             	mov    %eax,0x70(%ebx)
    env->env_ipc_recving = false;
f0104777:	c6 43 68 00          	movb   $0x0,0x68(%ebx)
    env->env_ipc_from = curenv->env_id;
f010477b:	e8 aa 12 00 00       	call   f0105a2a <cpunum>
f0104780:	6b c0 74             	imul   $0x74,%eax,%eax
f0104783:	8b 80 28 a0 2a f0    	mov    -0xfd55fd8(%eax),%eax
f0104789:	8b 40 48             	mov    0x48(%eax),%eax
f010478c:	89 43 74             	mov    %eax,0x74(%ebx)
    env->env_status = ENV_RUNNABLE;
f010478f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104792:	c7 40 54 02 00 00 00 	movl   $0x2,0x54(%eax)
    env->env_tf.tf_regs.reg_eax = 0;
f0104799:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)
    return 0;
f01047a0:	b8 00 00 00 00       	mov    $0x0,%eax
f01047a5:	e9 99 00 00 00       	jmp    f0104843 <syscall+0x528>
    struct Env *env;
    int r = envid2env(envid, &env, 0);
    if(r!=0)
        return r;
    if(!env->env_ipc_recving)
        return -E_IPC_NOT_RECV;
f01047aa:	b8 f9 ff ff ff       	mov    $0xfffffff9,%eax
        case SYS_env_set_status:
            return sys_env_set_status(a1, a2);
        case SYS_env_set_pgfault_upcall:
            return sys_env_set_pgfault_upcall(a1,(void *) a2);
        case SYS_ipc_try_send:
            return sys_ipc_try_send(a1, a2, (void *)a3, a4);
f01047af:	e9 8f 00 00 00       	jmp    f0104843 <syscall+0x528>
//	-E_INVAL if dstva < UTOP but dstva is not page-aligned.
static int
sys_ipc_recv(void *dstva)
{
	// LAB 4: Your code here.
    if(dstva < (void *)UTOP && dstva != ROUNDDOWN(dstva, PGSIZE)){
f01047b4:	81 7d 0c ff ff bf ee 	cmpl   $0xeebfffff,0xc(%ebp)
f01047bb:	77 09                	ja     f01047c6 <syscall+0x4ab>
f01047bd:	f7 45 0c ff 0f 00 00 	testl  $0xfff,0xc(%ebp)
f01047c4:	75 78                	jne    f010483e <syscall+0x523>
        return -E_INVAL; 
    }
    curenv->env_ipc_recving =true;
f01047c6:	e8 5f 12 00 00       	call   f0105a2a <cpunum>
f01047cb:	6b c0 74             	imul   $0x74,%eax,%eax
f01047ce:	8b 80 28 a0 2a f0    	mov    -0xfd55fd8(%eax),%eax
f01047d4:	c6 40 68 01          	movb   $0x1,0x68(%eax)
    curenv->env_ipc_dstva = dstva;
f01047d8:	e8 4d 12 00 00       	call   f0105a2a <cpunum>
f01047dd:	6b c0 74             	imul   $0x74,%eax,%eax
f01047e0:	8b 80 28 a0 2a f0    	mov    -0xfd55fd8(%eax),%eax
f01047e6:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01047e9:	89 48 6c             	mov    %ecx,0x6c(%eax)
    curenv->env_status = ENV_NOT_RUNNABLE;
f01047ec:	e8 39 12 00 00       	call   f0105a2a <cpunum>
f01047f1:	6b c0 74             	imul   $0x74,%eax,%eax
f01047f4:	8b 80 28 a0 2a f0    	mov    -0xfd55fd8(%eax),%eax
f01047fa:	c7 40 54 04 00 00 00 	movl   $0x4,0x54(%eax)

// Deschedule current environment and pick a different one to run.
static void
sys_yield(void)
{
	sched_yield();
f0104801:	e8 51 fa ff ff       	call   f0104257 <sched_yield>
{
	// LAB 5: Your code here.
	// Remember to check whether the user has supplied us with a good
	// address!
    struct Env *env;
    int r = envid2env(envid, &env, 1);
f0104806:	83 ec 04             	sub    $0x4,%esp
f0104809:	6a 01                	push   $0x1
f010480b:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010480e:	50                   	push   %eax
f010480f:	ff 75 0c             	pushl  0xc(%ebp)
f0104812:	e8 31 e6 ff ff       	call   f0102e48 <envid2env>
    if(r!=0)
f0104817:	83 c4 10             	add    $0x10,%esp
f010481a:	85 c0                	test   %eax,%eax
f010481c:	75 25                	jne    f0104843 <syscall+0x528>
        return r;
    env->env_tf = *tf;
f010481e:	b9 11 00 00 00       	mov    $0x11,%ecx
f0104823:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104826:	8b 75 10             	mov    0x10(%ebp),%esi
f0104829:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
    env->env_tf.tf_eflags |= FL_IF;
f010482b:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f010482e:	81 4a 38 00 02 00 00 	orl    $0x200,0x38(%edx)
        case SYS_ipc_try_send:
            return sys_ipc_try_send(a1, a2, (void *)a3, a4);
        case SYS_ipc_recv:
            return sys_ipc_recv((void *)a1);
        case SYS_env_set_trapframe:
            return sys_env_set_trapframe(a1, (struct Trapframe *)a2);
f0104835:	eb 0c                	jmp    f0104843 <syscall+0x528>
		default:
			return -E_INVAL;
f0104837:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f010483c:	eb 05                	jmp    f0104843 <syscall+0x528>
        case SYS_env_set_pgfault_upcall:
            return sys_env_set_pgfault_upcall(a1,(void *) a2);
        case SYS_ipc_try_send:
            return sys_ipc_try_send(a1, a2, (void *)a3, a4);
        case SYS_ipc_recv:
            return sys_ipc_recv((void *)a1);
f010483e:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
        case SYS_env_set_trapframe:
            return sys_env_set_trapframe(a1, (struct Trapframe *)a2);
		default:
			return -E_INVAL;
	}
}
f0104843:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104846:	5b                   	pop    %ebx
f0104847:	5e                   	pop    %esi
f0104848:	5f                   	pop    %edi
f0104849:	5d                   	pop    %ebp
f010484a:	c3                   	ret    

f010484b <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f010484b:	55                   	push   %ebp
f010484c:	89 e5                	mov    %esp,%ebp
f010484e:	57                   	push   %edi
f010484f:	56                   	push   %esi
f0104850:	53                   	push   %ebx
f0104851:	83 ec 14             	sub    $0x14,%esp
f0104854:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0104857:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f010485a:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f010485d:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0104860:	8b 1a                	mov    (%edx),%ebx
f0104862:	8b 01                	mov    (%ecx),%eax
f0104864:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0104867:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f010486e:	eb 7f                	jmp    f01048ef <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f0104870:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0104873:	01 d8                	add    %ebx,%eax
f0104875:	89 c6                	mov    %eax,%esi
f0104877:	c1 ee 1f             	shr    $0x1f,%esi
f010487a:	01 c6                	add    %eax,%esi
f010487c:	d1 fe                	sar    %esi
f010487e:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0104881:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0104884:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f0104887:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0104889:	eb 03                	jmp    f010488e <stab_binsearch+0x43>
			m--;
f010488b:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f010488e:	39 c3                	cmp    %eax,%ebx
f0104890:	7f 0d                	jg     f010489f <stab_binsearch+0x54>
f0104892:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0104896:	83 ea 0c             	sub    $0xc,%edx
f0104899:	39 f9                	cmp    %edi,%ecx
f010489b:	75 ee                	jne    f010488b <stab_binsearch+0x40>
f010489d:	eb 05                	jmp    f01048a4 <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f010489f:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f01048a2:	eb 4b                	jmp    f01048ef <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01048a4:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01048a7:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01048aa:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f01048ae:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01048b1:	76 11                	jbe    f01048c4 <stab_binsearch+0x79>
			*region_left = m;
f01048b3:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01048b6:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f01048b8:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01048bb:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01048c2:	eb 2b                	jmp    f01048ef <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f01048c4:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01048c7:	73 14                	jae    f01048dd <stab_binsearch+0x92>
			*region_right = m - 1;
f01048c9:	83 e8 01             	sub    $0x1,%eax
f01048cc:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01048cf:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01048d2:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01048d4:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01048db:	eb 12                	jmp    f01048ef <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01048dd:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01048e0:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f01048e2:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f01048e6:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01048e8:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f01048ef:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f01048f2:	0f 8e 78 ff ff ff    	jle    f0104870 <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f01048f8:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f01048fc:	75 0f                	jne    f010490d <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f01048fe:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104901:	8b 00                	mov    (%eax),%eax
f0104903:	83 e8 01             	sub    $0x1,%eax
f0104906:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0104909:	89 06                	mov    %eax,(%esi)
f010490b:	eb 2c                	jmp    f0104939 <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010490d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104910:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0104912:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0104915:	8b 0e                	mov    (%esi),%ecx
f0104917:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010491a:	8b 75 ec             	mov    -0x14(%ebp),%esi
f010491d:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0104920:	eb 03                	jmp    f0104925 <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0104922:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0104925:	39 c8                	cmp    %ecx,%eax
f0104927:	7e 0b                	jle    f0104934 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f0104929:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f010492d:	83 ea 0c             	sub    $0xc,%edx
f0104930:	39 df                	cmp    %ebx,%edi
f0104932:	75 ee                	jne    f0104922 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f0104934:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0104937:	89 06                	mov    %eax,(%esi)
	}
}
f0104939:	83 c4 14             	add    $0x14,%esp
f010493c:	5b                   	pop    %ebx
f010493d:	5e                   	pop    %esi
f010493e:	5f                   	pop    %edi
f010493f:	5d                   	pop    %ebp
f0104940:	c3                   	ret    

f0104941 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0104941:	55                   	push   %ebp
f0104942:	89 e5                	mov    %esp,%ebp
f0104944:	57                   	push   %edi
f0104945:	56                   	push   %esi
f0104946:	53                   	push   %ebx
f0104947:	83 ec 3c             	sub    $0x3c,%esp
f010494a:	8b 7d 08             	mov    0x8(%ebp),%edi
f010494d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0104950:	c7 03 04 7d 10 f0    	movl   $0xf0107d04,(%ebx)
	info->eip_line = 0;
f0104956:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f010495d:	c7 43 08 04 7d 10 f0 	movl   $0xf0107d04,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0104964:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f010496b:	89 7b 10             	mov    %edi,0x10(%ebx)
	info->eip_fn_narg = 0;
f010496e:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0104975:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f010497b:	0f 87 f6 00 00 00    	ja     f0104a77 <debuginfo_eip+0x136>
		const struct UserStabData *usd = (const struct UserStabData *) USTABDATA;

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, usd, sizeof(struct UserStabData), PTE_U) < 0) {
f0104981:	e8 a4 10 00 00       	call   f0105a2a <cpunum>
f0104986:	6a 04                	push   $0x4
f0104988:	6a 10                	push   $0x10
f010498a:	68 00 00 20 00       	push   $0x200000
f010498f:	6b c0 74             	imul   $0x74,%eax,%eax
f0104992:	ff b0 28 a0 2a f0    	pushl  -0xfd55fd8(%eax)
f0104998:	e8 70 e3 ff ff       	call   f0102d0d <user_mem_check>
f010499d:	83 c4 10             	add    $0x10,%esp
f01049a0:	85 c0                	test   %eax,%eax
f01049a2:	79 1f                	jns    f01049c3 <debuginfo_eip+0x82>
			cprintf("debuginfo_eip: invalid usd addr %08x", usd);
f01049a4:	83 ec 08             	sub    $0x8,%esp
f01049a7:	68 00 00 20 00       	push   $0x200000
f01049ac:	68 10 7d 10 f0       	push   $0xf0107d10
f01049b1:	e8 a7 ec ff ff       	call   f010365d <cprintf>
			return -1;
f01049b6:	83 c4 10             	add    $0x10,%esp
f01049b9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01049be:	e9 97 02 00 00       	jmp    f0104c5a <debuginfo_eip+0x319>
		}

		stabs = usd->stabs;
f01049c3:	a1 00 00 20 00       	mov    0x200000,%eax
f01049c8:	89 45 c0             	mov    %eax,-0x40(%ebp)
		stab_end = usd->stab_end;
f01049cb:	8b 35 04 00 20 00    	mov    0x200004,%esi
		stabstr = usd->stabstr;
f01049d1:	8b 15 08 00 20 00    	mov    0x200008,%edx
f01049d7:	89 55 b8             	mov    %edx,-0x48(%ebp)
		stabstr_end = usd->stabstr_end;
f01049da:	8b 15 0c 00 20 00    	mov    0x20000c,%edx
f01049e0:	89 55 bc             	mov    %edx,-0x44(%ebp)

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, stabs, stab_end-stabs+1, PTE_U) < 0){
f01049e3:	e8 42 10 00 00       	call   f0105a2a <cpunum>
f01049e8:	6a 04                	push   $0x4
f01049ea:	89 f2                	mov    %esi,%edx
f01049ec:	8b 4d c0             	mov    -0x40(%ebp),%ecx
f01049ef:	29 ca                	sub    %ecx,%edx
f01049f1:	c1 fa 02             	sar    $0x2,%edx
f01049f4:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f01049fa:	83 c2 01             	add    $0x1,%edx
f01049fd:	52                   	push   %edx
f01049fe:	51                   	push   %ecx
f01049ff:	6b c0 74             	imul   $0x74,%eax,%eax
f0104a02:	ff b0 28 a0 2a f0    	pushl  -0xfd55fd8(%eax)
f0104a08:	e8 00 e3 ff ff       	call   f0102d0d <user_mem_check>
f0104a0d:	83 c4 10             	add    $0x10,%esp
f0104a10:	85 c0                	test   %eax,%eax
f0104a12:	79 1d                	jns    f0104a31 <debuginfo_eip+0xf0>
			cprintf("debuginfo_eip: invalid stabs addr %08x", stabs);
f0104a14:	83 ec 08             	sub    $0x8,%esp
f0104a17:	ff 75 c0             	pushl  -0x40(%ebp)
f0104a1a:	68 38 7d 10 f0       	push   $0xf0107d38
f0104a1f:	e8 39 ec ff ff       	call   f010365d <cprintf>
			return -1;
f0104a24:	83 c4 10             	add    $0x10,%esp
f0104a27:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104a2c:	e9 29 02 00 00       	jmp    f0104c5a <debuginfo_eip+0x319>
		}
		if (user_mem_check(curenv, stabstr, stabstr_end-stabstr+1, PTE_U) < 0) {
f0104a31:	e8 f4 0f 00 00       	call   f0105a2a <cpunum>
f0104a36:	6a 04                	push   $0x4
f0104a38:	8b 55 bc             	mov    -0x44(%ebp),%edx
f0104a3b:	8b 4d b8             	mov    -0x48(%ebp),%ecx
f0104a3e:	29 ca                	sub    %ecx,%edx
f0104a40:	83 c2 01             	add    $0x1,%edx
f0104a43:	52                   	push   %edx
f0104a44:	51                   	push   %ecx
f0104a45:	6b c0 74             	imul   $0x74,%eax,%eax
f0104a48:	ff b0 28 a0 2a f0    	pushl  -0xfd55fd8(%eax)
f0104a4e:	e8 ba e2 ff ff       	call   f0102d0d <user_mem_check>
f0104a53:	83 c4 10             	add    $0x10,%esp
f0104a56:	85 c0                	test   %eax,%eax
f0104a58:	79 37                	jns    f0104a91 <debuginfo_eip+0x150>
			cprintf("debuginfo_eip: invalid stabstr addr %08x", stabstr);
f0104a5a:	83 ec 08             	sub    $0x8,%esp
f0104a5d:	ff 75 b8             	pushl  -0x48(%ebp)
f0104a60:	68 60 7d 10 f0       	push   $0xf0107d60
f0104a65:	e8 f3 eb ff ff       	call   f010365d <cprintf>
			return -1;
f0104a6a:	83 c4 10             	add    $0x10,%esp
f0104a6d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104a72:	e9 e3 01 00 00       	jmp    f0104c5a <debuginfo_eip+0x319>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f0104a77:	c7 45 bc ef 74 11 f0 	movl   $0xf01174ef,-0x44(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f0104a7e:	c7 45 b8 0d 35 11 f0 	movl   $0xf011350d,-0x48(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f0104a85:	be 0c 35 11 f0       	mov    $0xf011350c,%esi
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f0104a8a:	c7 45 c0 68 85 10 f0 	movl   $0xf0108568,-0x40(%ebp)
			return -1;
		}
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0104a91:	8b 45 bc             	mov    -0x44(%ebp),%eax
f0104a94:	39 45 b8             	cmp    %eax,-0x48(%ebp)
f0104a97:	0f 83 9c 01 00 00    	jae    f0104c39 <debuginfo_eip+0x2f8>
f0104a9d:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f0104aa1:	0f 85 99 01 00 00    	jne    f0104c40 <debuginfo_eip+0x2ff>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0104aa7:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0104aae:	2b 75 c0             	sub    -0x40(%ebp),%esi
f0104ab1:	c1 fe 02             	sar    $0x2,%esi
f0104ab4:	69 c6 ab aa aa aa    	imul   $0xaaaaaaab,%esi,%eax
f0104aba:	83 e8 01             	sub    $0x1,%eax
f0104abd:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0104ac0:	83 ec 08             	sub    $0x8,%esp
f0104ac3:	57                   	push   %edi
f0104ac4:	6a 64                	push   $0x64
f0104ac6:	8d 55 e0             	lea    -0x20(%ebp),%edx
f0104ac9:	89 d1                	mov    %edx,%ecx
f0104acb:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0104ace:	8b 75 c0             	mov    -0x40(%ebp),%esi
f0104ad1:	89 f0                	mov    %esi,%eax
f0104ad3:	e8 73 fd ff ff       	call   f010484b <stab_binsearch>
	if (lfile == 0)
f0104ad8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104adb:	83 c4 10             	add    $0x10,%esp
f0104ade:	85 c0                	test   %eax,%eax
f0104ae0:	0f 84 61 01 00 00    	je     f0104c47 <debuginfo_eip+0x306>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0104ae6:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0104ae9:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104aec:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0104aef:	83 ec 08             	sub    $0x8,%esp
f0104af2:	57                   	push   %edi
f0104af3:	6a 24                	push   $0x24
f0104af5:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0104af8:	89 d1                	mov    %edx,%ecx
f0104afa:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0104afd:	89 f0                	mov    %esi,%eax
f0104aff:	e8 47 fd ff ff       	call   f010484b <stab_binsearch>

	if (lfun <= rfun) {
f0104b04:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0104b07:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0104b0a:	83 c4 10             	add    $0x10,%esp
f0104b0d:	39 d0                	cmp    %edx,%eax
f0104b0f:	7f 2e                	jg     f0104b3f <debuginfo_eip+0x1fe>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0104b11:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f0104b14:	8d 34 8e             	lea    (%esi,%ecx,4),%esi
f0104b17:	89 75 c4             	mov    %esi,-0x3c(%ebp)
f0104b1a:	8b 36                	mov    (%esi),%esi
f0104b1c:	8b 4d bc             	mov    -0x44(%ebp),%ecx
f0104b1f:	2b 4d b8             	sub    -0x48(%ebp),%ecx
f0104b22:	39 ce                	cmp    %ecx,%esi
f0104b24:	73 06                	jae    f0104b2c <debuginfo_eip+0x1eb>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0104b26:	03 75 b8             	add    -0x48(%ebp),%esi
f0104b29:	89 73 08             	mov    %esi,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0104b2c:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f0104b2f:	8b 4e 08             	mov    0x8(%esi),%ecx
f0104b32:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0104b35:	29 cf                	sub    %ecx,%edi
		// Search within the function definition for the line number.
		lline = lfun;
f0104b37:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0104b3a:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0104b3d:	eb 0f                	jmp    f0104b4e <debuginfo_eip+0x20d>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0104b3f:	89 7b 10             	mov    %edi,0x10(%ebx)
		lline = lfile;
f0104b42:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104b45:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0104b48:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104b4b:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0104b4e:	83 ec 08             	sub    $0x8,%esp
f0104b51:	6a 3a                	push   $0x3a
f0104b53:	ff 73 08             	pushl  0x8(%ebx)
f0104b56:	e8 92 08 00 00       	call   f01053ed <strfind>
f0104b5b:	2b 43 08             	sub    0x8(%ebx),%eax
f0104b5e:	89 43 0c             	mov    %eax,0xc(%ebx)
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.

	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);	
f0104b61:	83 c4 08             	add    $0x8,%esp
f0104b64:	57                   	push   %edi
f0104b65:	6a 44                	push   $0x44
f0104b67:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0104b6a:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0104b6d:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0104b70:	89 f8                	mov    %edi,%eax
f0104b72:	e8 d4 fc ff ff       	call   f010484b <stab_binsearch>
	if (lline > rline)
f0104b77:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0104b7a:	83 c4 10             	add    $0x10,%esp
f0104b7d:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0104b80:	0f 8f c8 00 00 00    	jg     f0104c4e <debuginfo_eip+0x30d>
		    return -1;
	info->eip_line = stabs[lline].n_desc;
f0104b86:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0104b89:	8d 14 97             	lea    (%edi,%edx,4),%edx
f0104b8c:	0f b7 4a 06          	movzwl 0x6(%edx),%ecx
f0104b90:	89 4b 04             	mov    %ecx,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0104b93:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104b96:	c6 45 c4 00          	movb   $0x0,-0x3c(%ebp)
f0104b9a:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0104b9d:	eb 0a                	jmp    f0104ba9 <debuginfo_eip+0x268>
f0104b9f:	83 e8 01             	sub    $0x1,%eax
f0104ba2:	83 ea 0c             	sub    $0xc,%edx
f0104ba5:	c6 45 c4 01          	movb   $0x1,-0x3c(%ebp)
f0104ba9:	39 c7                	cmp    %eax,%edi
f0104bab:	7e 05                	jle    f0104bb2 <debuginfo_eip+0x271>
f0104bad:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104bb0:	eb 47                	jmp    f0104bf9 <debuginfo_eip+0x2b8>
	       && stabs[lline].n_type != N_SOL
f0104bb2:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0104bb6:	80 f9 84             	cmp    $0x84,%cl
f0104bb9:	75 0e                	jne    f0104bc9 <debuginfo_eip+0x288>
f0104bbb:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104bbe:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f0104bc2:	74 1c                	je     f0104be0 <debuginfo_eip+0x29f>
f0104bc4:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0104bc7:	eb 17                	jmp    f0104be0 <debuginfo_eip+0x29f>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0104bc9:	80 f9 64             	cmp    $0x64,%cl
f0104bcc:	75 d1                	jne    f0104b9f <debuginfo_eip+0x25e>
f0104bce:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f0104bd2:	74 cb                	je     f0104b9f <debuginfo_eip+0x25e>
f0104bd4:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104bd7:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f0104bdb:	74 03                	je     f0104be0 <debuginfo_eip+0x29f>
f0104bdd:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0104be0:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0104be3:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0104be6:	8b 14 87             	mov    (%edi,%eax,4),%edx
f0104be9:	8b 45 bc             	mov    -0x44(%ebp),%eax
f0104bec:	8b 7d b8             	mov    -0x48(%ebp),%edi
f0104bef:	29 f8                	sub    %edi,%eax
f0104bf1:	39 c2                	cmp    %eax,%edx
f0104bf3:	73 04                	jae    f0104bf9 <debuginfo_eip+0x2b8>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0104bf5:	01 fa                	add    %edi,%edx
f0104bf7:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0104bf9:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0104bfc:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0104bff:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0104c04:	39 f2                	cmp    %esi,%edx
f0104c06:	7d 52                	jge    f0104c5a <debuginfo_eip+0x319>
		for (lline = lfun + 1;
f0104c08:	83 c2 01             	add    $0x1,%edx
f0104c0b:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0104c0e:	89 d0                	mov    %edx,%eax
f0104c10:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0104c13:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0104c16:	8d 14 97             	lea    (%edi,%edx,4),%edx
f0104c19:	eb 04                	jmp    f0104c1f <debuginfo_eip+0x2de>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0104c1b:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0104c1f:	39 c6                	cmp    %eax,%esi
f0104c21:	7e 32                	jle    f0104c55 <debuginfo_eip+0x314>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0104c23:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0104c27:	83 c0 01             	add    $0x1,%eax
f0104c2a:	83 c2 0c             	add    $0xc,%edx
f0104c2d:	80 f9 a0             	cmp    $0xa0,%cl
f0104c30:	74 e9                	je     f0104c1b <debuginfo_eip+0x2da>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0104c32:	b8 00 00 00 00       	mov    $0x0,%eax
f0104c37:	eb 21                	jmp    f0104c5a <debuginfo_eip+0x319>
		}
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0104c39:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104c3e:	eb 1a                	jmp    f0104c5a <debuginfo_eip+0x319>
f0104c40:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104c45:	eb 13                	jmp    f0104c5a <debuginfo_eip+0x319>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0104c47:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104c4c:	eb 0c                	jmp    f0104c5a <debuginfo_eip+0x319>
	//	which one.
	// Your code here.

	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);	
	if (lline > rline)
		    return -1;
f0104c4e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104c53:	eb 05                	jmp    f0104c5a <debuginfo_eip+0x319>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0104c55:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104c5a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104c5d:	5b                   	pop    %ebx
f0104c5e:	5e                   	pop    %esi
f0104c5f:	5f                   	pop    %edi
f0104c60:	5d                   	pop    %ebp
f0104c61:	c3                   	ret    

f0104c62 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0104c62:	55                   	push   %ebp
f0104c63:	89 e5                	mov    %esp,%ebp
f0104c65:	57                   	push   %edi
f0104c66:	56                   	push   %esi
f0104c67:	53                   	push   %ebx
f0104c68:	83 ec 1c             	sub    $0x1c,%esp
f0104c6b:	89 c7                	mov    %eax,%edi
f0104c6d:	89 d6                	mov    %edx,%esi
f0104c6f:	8b 45 08             	mov    0x8(%ebp),%eax
f0104c72:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104c75:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104c78:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0104c7b:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0104c7e:	bb 00 00 00 00       	mov    $0x0,%ebx
f0104c83:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0104c86:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0104c89:	39 d3                	cmp    %edx,%ebx
f0104c8b:	72 05                	jb     f0104c92 <printnum+0x30>
f0104c8d:	39 45 10             	cmp    %eax,0x10(%ebp)
f0104c90:	77 45                	ja     f0104cd7 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0104c92:	83 ec 0c             	sub    $0xc,%esp
f0104c95:	ff 75 18             	pushl  0x18(%ebp)
f0104c98:	8b 45 14             	mov    0x14(%ebp),%eax
f0104c9b:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0104c9e:	53                   	push   %ebx
f0104c9f:	ff 75 10             	pushl  0x10(%ebp)
f0104ca2:	83 ec 08             	sub    $0x8,%esp
f0104ca5:	ff 75 e4             	pushl  -0x1c(%ebp)
f0104ca8:	ff 75 e0             	pushl  -0x20(%ebp)
f0104cab:	ff 75 dc             	pushl  -0x24(%ebp)
f0104cae:	ff 75 d8             	pushl  -0x28(%ebp)
f0104cb1:	e8 da 16 00 00       	call   f0106390 <__udivdi3>
f0104cb6:	83 c4 18             	add    $0x18,%esp
f0104cb9:	52                   	push   %edx
f0104cba:	50                   	push   %eax
f0104cbb:	89 f2                	mov    %esi,%edx
f0104cbd:	89 f8                	mov    %edi,%eax
f0104cbf:	e8 9e ff ff ff       	call   f0104c62 <printnum>
f0104cc4:	83 c4 20             	add    $0x20,%esp
f0104cc7:	eb 18                	jmp    f0104ce1 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0104cc9:	83 ec 08             	sub    $0x8,%esp
f0104ccc:	56                   	push   %esi
f0104ccd:	ff 75 18             	pushl  0x18(%ebp)
f0104cd0:	ff d7                	call   *%edi
f0104cd2:	83 c4 10             	add    $0x10,%esp
f0104cd5:	eb 03                	jmp    f0104cda <printnum+0x78>
f0104cd7:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0104cda:	83 eb 01             	sub    $0x1,%ebx
f0104cdd:	85 db                	test   %ebx,%ebx
f0104cdf:	7f e8                	jg     f0104cc9 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0104ce1:	83 ec 08             	sub    $0x8,%esp
f0104ce4:	56                   	push   %esi
f0104ce5:	83 ec 04             	sub    $0x4,%esp
f0104ce8:	ff 75 e4             	pushl  -0x1c(%ebp)
f0104ceb:	ff 75 e0             	pushl  -0x20(%ebp)
f0104cee:	ff 75 dc             	pushl  -0x24(%ebp)
f0104cf1:	ff 75 d8             	pushl  -0x28(%ebp)
f0104cf4:	e8 c7 17 00 00       	call   f01064c0 <__umoddi3>
f0104cf9:	83 c4 14             	add    $0x14,%esp
f0104cfc:	0f be 80 89 7d 10 f0 	movsbl -0xfef8277(%eax),%eax
f0104d03:	50                   	push   %eax
f0104d04:	ff d7                	call   *%edi
}
f0104d06:	83 c4 10             	add    $0x10,%esp
f0104d09:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104d0c:	5b                   	pop    %ebx
f0104d0d:	5e                   	pop    %esi
f0104d0e:	5f                   	pop    %edi
f0104d0f:	5d                   	pop    %ebp
f0104d10:	c3                   	ret    

f0104d11 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0104d11:	55                   	push   %ebp
f0104d12:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0104d14:	83 fa 01             	cmp    $0x1,%edx
f0104d17:	7e 0e                	jle    f0104d27 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0104d19:	8b 10                	mov    (%eax),%edx
f0104d1b:	8d 4a 08             	lea    0x8(%edx),%ecx
f0104d1e:	89 08                	mov    %ecx,(%eax)
f0104d20:	8b 02                	mov    (%edx),%eax
f0104d22:	8b 52 04             	mov    0x4(%edx),%edx
f0104d25:	eb 22                	jmp    f0104d49 <getuint+0x38>
	else if (lflag)
f0104d27:	85 d2                	test   %edx,%edx
f0104d29:	74 10                	je     f0104d3b <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0104d2b:	8b 10                	mov    (%eax),%edx
f0104d2d:	8d 4a 04             	lea    0x4(%edx),%ecx
f0104d30:	89 08                	mov    %ecx,(%eax)
f0104d32:	8b 02                	mov    (%edx),%eax
f0104d34:	ba 00 00 00 00       	mov    $0x0,%edx
f0104d39:	eb 0e                	jmp    f0104d49 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0104d3b:	8b 10                	mov    (%eax),%edx
f0104d3d:	8d 4a 04             	lea    0x4(%edx),%ecx
f0104d40:	89 08                	mov    %ecx,(%eax)
f0104d42:	8b 02                	mov    (%edx),%eax
f0104d44:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0104d49:	5d                   	pop    %ebp
f0104d4a:	c3                   	ret    

f0104d4b <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0104d4b:	55                   	push   %ebp
f0104d4c:	89 e5                	mov    %esp,%ebp
f0104d4e:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0104d51:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0104d55:	8b 10                	mov    (%eax),%edx
f0104d57:	3b 50 04             	cmp    0x4(%eax),%edx
f0104d5a:	73 0a                	jae    f0104d66 <sprintputch+0x1b>
		*b->buf++ = ch;
f0104d5c:	8d 4a 01             	lea    0x1(%edx),%ecx
f0104d5f:	89 08                	mov    %ecx,(%eax)
f0104d61:	8b 45 08             	mov    0x8(%ebp),%eax
f0104d64:	88 02                	mov    %al,(%edx)
}
f0104d66:	5d                   	pop    %ebp
f0104d67:	c3                   	ret    

f0104d68 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0104d68:	55                   	push   %ebp
f0104d69:	89 e5                	mov    %esp,%ebp
f0104d6b:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0104d6e:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0104d71:	50                   	push   %eax
f0104d72:	ff 75 10             	pushl  0x10(%ebp)
f0104d75:	ff 75 0c             	pushl  0xc(%ebp)
f0104d78:	ff 75 08             	pushl  0x8(%ebp)
f0104d7b:	e8 05 00 00 00       	call   f0104d85 <vprintfmt>
	va_end(ap);
}
f0104d80:	83 c4 10             	add    $0x10,%esp
f0104d83:	c9                   	leave  
f0104d84:	c3                   	ret    

f0104d85 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0104d85:	55                   	push   %ebp
f0104d86:	89 e5                	mov    %esp,%ebp
f0104d88:	57                   	push   %edi
f0104d89:	56                   	push   %esi
f0104d8a:	53                   	push   %ebx
f0104d8b:	83 ec 2c             	sub    $0x2c,%esp
f0104d8e:	8b 75 08             	mov    0x8(%ebp),%esi
f0104d91:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104d94:	8b 7d 10             	mov    0x10(%ebp),%edi
f0104d97:	eb 12                	jmp    f0104dab <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0104d99:	85 c0                	test   %eax,%eax
f0104d9b:	0f 84 89 03 00 00    	je     f010512a <vprintfmt+0x3a5>
				return;
			putch(ch, putdat);
f0104da1:	83 ec 08             	sub    $0x8,%esp
f0104da4:	53                   	push   %ebx
f0104da5:	50                   	push   %eax
f0104da6:	ff d6                	call   *%esi
f0104da8:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0104dab:	83 c7 01             	add    $0x1,%edi
f0104dae:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0104db2:	83 f8 25             	cmp    $0x25,%eax
f0104db5:	75 e2                	jne    f0104d99 <vprintfmt+0x14>
f0104db7:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0104dbb:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0104dc2:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0104dc9:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0104dd0:	ba 00 00 00 00       	mov    $0x0,%edx
f0104dd5:	eb 07                	jmp    f0104dde <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104dd7:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0104dda:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104dde:	8d 47 01             	lea    0x1(%edi),%eax
f0104de1:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0104de4:	0f b6 07             	movzbl (%edi),%eax
f0104de7:	0f b6 c8             	movzbl %al,%ecx
f0104dea:	83 e8 23             	sub    $0x23,%eax
f0104ded:	3c 55                	cmp    $0x55,%al
f0104def:	0f 87 1a 03 00 00    	ja     f010510f <vprintfmt+0x38a>
f0104df5:	0f b6 c0             	movzbl %al,%eax
f0104df8:	ff 24 85 c0 7e 10 f0 	jmp    *-0xfef8140(,%eax,4)
f0104dff:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0104e02:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0104e06:	eb d6                	jmp    f0104dde <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104e08:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104e0b:	b8 00 00 00 00       	mov    $0x0,%eax
f0104e10:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0104e13:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0104e16:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f0104e1a:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0104e1d:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0104e20:	83 fa 09             	cmp    $0x9,%edx
f0104e23:	77 39                	ja     f0104e5e <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0104e25:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0104e28:	eb e9                	jmp    f0104e13 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0104e2a:	8b 45 14             	mov    0x14(%ebp),%eax
f0104e2d:	8d 48 04             	lea    0x4(%eax),%ecx
f0104e30:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0104e33:	8b 00                	mov    (%eax),%eax
f0104e35:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104e38:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0104e3b:	eb 27                	jmp    f0104e64 <vprintfmt+0xdf>
f0104e3d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104e40:	85 c0                	test   %eax,%eax
f0104e42:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104e47:	0f 49 c8             	cmovns %eax,%ecx
f0104e4a:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104e4d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104e50:	eb 8c                	jmp    f0104dde <vprintfmt+0x59>
f0104e52:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0104e55:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0104e5c:	eb 80                	jmp    f0104dde <vprintfmt+0x59>
f0104e5e:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0104e61:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0104e64:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0104e68:	0f 89 70 ff ff ff    	jns    f0104dde <vprintfmt+0x59>
				width = precision, precision = -1;
f0104e6e:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0104e71:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0104e74:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0104e7b:	e9 5e ff ff ff       	jmp    f0104dde <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0104e80:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104e83:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0104e86:	e9 53 ff ff ff       	jmp    f0104dde <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0104e8b:	8b 45 14             	mov    0x14(%ebp),%eax
f0104e8e:	8d 50 04             	lea    0x4(%eax),%edx
f0104e91:	89 55 14             	mov    %edx,0x14(%ebp)
f0104e94:	83 ec 08             	sub    $0x8,%esp
f0104e97:	53                   	push   %ebx
f0104e98:	ff 30                	pushl  (%eax)
f0104e9a:	ff d6                	call   *%esi
			break;
f0104e9c:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104e9f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0104ea2:	e9 04 ff ff ff       	jmp    f0104dab <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0104ea7:	8b 45 14             	mov    0x14(%ebp),%eax
f0104eaa:	8d 50 04             	lea    0x4(%eax),%edx
f0104ead:	89 55 14             	mov    %edx,0x14(%ebp)
f0104eb0:	8b 00                	mov    (%eax),%eax
f0104eb2:	99                   	cltd   
f0104eb3:	31 d0                	xor    %edx,%eax
f0104eb5:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0104eb7:	83 f8 0f             	cmp    $0xf,%eax
f0104eba:	7f 0b                	jg     f0104ec7 <vprintfmt+0x142>
f0104ebc:	8b 14 85 20 80 10 f0 	mov    -0xfef7fe0(,%eax,4),%edx
f0104ec3:	85 d2                	test   %edx,%edx
f0104ec5:	75 18                	jne    f0104edf <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f0104ec7:	50                   	push   %eax
f0104ec8:	68 a1 7d 10 f0       	push   $0xf0107da1
f0104ecd:	53                   	push   %ebx
f0104ece:	56                   	push   %esi
f0104ecf:	e8 94 fe ff ff       	call   f0104d68 <printfmt>
f0104ed4:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104ed7:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0104eda:	e9 cc fe ff ff       	jmp    f0104dab <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0104edf:	52                   	push   %edx
f0104ee0:	68 5c 75 10 f0       	push   $0xf010755c
f0104ee5:	53                   	push   %ebx
f0104ee6:	56                   	push   %esi
f0104ee7:	e8 7c fe ff ff       	call   f0104d68 <printfmt>
f0104eec:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104eef:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104ef2:	e9 b4 fe ff ff       	jmp    f0104dab <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0104ef7:	8b 45 14             	mov    0x14(%ebp),%eax
f0104efa:	8d 50 04             	lea    0x4(%eax),%edx
f0104efd:	89 55 14             	mov    %edx,0x14(%ebp)
f0104f00:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0104f02:	85 ff                	test   %edi,%edi
f0104f04:	b8 9a 7d 10 f0       	mov    $0xf0107d9a,%eax
f0104f09:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0104f0c:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0104f10:	0f 8e 94 00 00 00    	jle    f0104faa <vprintfmt+0x225>
f0104f16:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0104f1a:	0f 84 98 00 00 00    	je     f0104fb8 <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
f0104f20:	83 ec 08             	sub    $0x8,%esp
f0104f23:	ff 75 d0             	pushl  -0x30(%ebp)
f0104f26:	57                   	push   %edi
f0104f27:	e8 77 03 00 00       	call   f01052a3 <strnlen>
f0104f2c:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0104f2f:	29 c1                	sub    %eax,%ecx
f0104f31:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0104f34:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0104f37:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0104f3b:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0104f3e:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0104f41:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0104f43:	eb 0f                	jmp    f0104f54 <vprintfmt+0x1cf>
					putch(padc, putdat);
f0104f45:	83 ec 08             	sub    $0x8,%esp
f0104f48:	53                   	push   %ebx
f0104f49:	ff 75 e0             	pushl  -0x20(%ebp)
f0104f4c:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0104f4e:	83 ef 01             	sub    $0x1,%edi
f0104f51:	83 c4 10             	add    $0x10,%esp
f0104f54:	85 ff                	test   %edi,%edi
f0104f56:	7f ed                	jg     f0104f45 <vprintfmt+0x1c0>
f0104f58:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0104f5b:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0104f5e:	85 c9                	test   %ecx,%ecx
f0104f60:	b8 00 00 00 00       	mov    $0x0,%eax
f0104f65:	0f 49 c1             	cmovns %ecx,%eax
f0104f68:	29 c1                	sub    %eax,%ecx
f0104f6a:	89 75 08             	mov    %esi,0x8(%ebp)
f0104f6d:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0104f70:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0104f73:	89 cb                	mov    %ecx,%ebx
f0104f75:	eb 4d                	jmp    f0104fc4 <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0104f77:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0104f7b:	74 1b                	je     f0104f98 <vprintfmt+0x213>
f0104f7d:	0f be c0             	movsbl %al,%eax
f0104f80:	83 e8 20             	sub    $0x20,%eax
f0104f83:	83 f8 5e             	cmp    $0x5e,%eax
f0104f86:	76 10                	jbe    f0104f98 <vprintfmt+0x213>
					putch('?', putdat);
f0104f88:	83 ec 08             	sub    $0x8,%esp
f0104f8b:	ff 75 0c             	pushl  0xc(%ebp)
f0104f8e:	6a 3f                	push   $0x3f
f0104f90:	ff 55 08             	call   *0x8(%ebp)
f0104f93:	83 c4 10             	add    $0x10,%esp
f0104f96:	eb 0d                	jmp    f0104fa5 <vprintfmt+0x220>
				else
					putch(ch, putdat);
f0104f98:	83 ec 08             	sub    $0x8,%esp
f0104f9b:	ff 75 0c             	pushl  0xc(%ebp)
f0104f9e:	52                   	push   %edx
f0104f9f:	ff 55 08             	call   *0x8(%ebp)
f0104fa2:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0104fa5:	83 eb 01             	sub    $0x1,%ebx
f0104fa8:	eb 1a                	jmp    f0104fc4 <vprintfmt+0x23f>
f0104faa:	89 75 08             	mov    %esi,0x8(%ebp)
f0104fad:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0104fb0:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0104fb3:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0104fb6:	eb 0c                	jmp    f0104fc4 <vprintfmt+0x23f>
f0104fb8:	89 75 08             	mov    %esi,0x8(%ebp)
f0104fbb:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0104fbe:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0104fc1:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0104fc4:	83 c7 01             	add    $0x1,%edi
f0104fc7:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0104fcb:	0f be d0             	movsbl %al,%edx
f0104fce:	85 d2                	test   %edx,%edx
f0104fd0:	74 23                	je     f0104ff5 <vprintfmt+0x270>
f0104fd2:	85 f6                	test   %esi,%esi
f0104fd4:	78 a1                	js     f0104f77 <vprintfmt+0x1f2>
f0104fd6:	83 ee 01             	sub    $0x1,%esi
f0104fd9:	79 9c                	jns    f0104f77 <vprintfmt+0x1f2>
f0104fdb:	89 df                	mov    %ebx,%edi
f0104fdd:	8b 75 08             	mov    0x8(%ebp),%esi
f0104fe0:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104fe3:	eb 18                	jmp    f0104ffd <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0104fe5:	83 ec 08             	sub    $0x8,%esp
f0104fe8:	53                   	push   %ebx
f0104fe9:	6a 20                	push   $0x20
f0104feb:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0104fed:	83 ef 01             	sub    $0x1,%edi
f0104ff0:	83 c4 10             	add    $0x10,%esp
f0104ff3:	eb 08                	jmp    f0104ffd <vprintfmt+0x278>
f0104ff5:	89 df                	mov    %ebx,%edi
f0104ff7:	8b 75 08             	mov    0x8(%ebp),%esi
f0104ffa:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104ffd:	85 ff                	test   %edi,%edi
f0104fff:	7f e4                	jg     f0104fe5 <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0105001:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0105004:	e9 a2 fd ff ff       	jmp    f0104dab <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0105009:	83 fa 01             	cmp    $0x1,%edx
f010500c:	7e 16                	jle    f0105024 <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f010500e:	8b 45 14             	mov    0x14(%ebp),%eax
f0105011:	8d 50 08             	lea    0x8(%eax),%edx
f0105014:	89 55 14             	mov    %edx,0x14(%ebp)
f0105017:	8b 50 04             	mov    0x4(%eax),%edx
f010501a:	8b 00                	mov    (%eax),%eax
f010501c:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010501f:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0105022:	eb 32                	jmp    f0105056 <vprintfmt+0x2d1>
	else if (lflag)
f0105024:	85 d2                	test   %edx,%edx
f0105026:	74 18                	je     f0105040 <vprintfmt+0x2bb>
		return va_arg(*ap, long);
f0105028:	8b 45 14             	mov    0x14(%ebp),%eax
f010502b:	8d 50 04             	lea    0x4(%eax),%edx
f010502e:	89 55 14             	mov    %edx,0x14(%ebp)
f0105031:	8b 00                	mov    (%eax),%eax
f0105033:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0105036:	89 c1                	mov    %eax,%ecx
f0105038:	c1 f9 1f             	sar    $0x1f,%ecx
f010503b:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f010503e:	eb 16                	jmp    f0105056 <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
f0105040:	8b 45 14             	mov    0x14(%ebp),%eax
f0105043:	8d 50 04             	lea    0x4(%eax),%edx
f0105046:	89 55 14             	mov    %edx,0x14(%ebp)
f0105049:	8b 00                	mov    (%eax),%eax
f010504b:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010504e:	89 c1                	mov    %eax,%ecx
f0105050:	c1 f9 1f             	sar    $0x1f,%ecx
f0105053:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0105056:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0105059:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f010505c:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0105061:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0105065:	79 74                	jns    f01050db <vprintfmt+0x356>
				putch('-', putdat);
f0105067:	83 ec 08             	sub    $0x8,%esp
f010506a:	53                   	push   %ebx
f010506b:	6a 2d                	push   $0x2d
f010506d:	ff d6                	call   *%esi
				num = -(long long) num;
f010506f:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0105072:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0105075:	f7 d8                	neg    %eax
f0105077:	83 d2 00             	adc    $0x0,%edx
f010507a:	f7 da                	neg    %edx
f010507c:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f010507f:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0105084:	eb 55                	jmp    f01050db <vprintfmt+0x356>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0105086:	8d 45 14             	lea    0x14(%ebp),%eax
f0105089:	e8 83 fc ff ff       	call   f0104d11 <getuint>
			base = 10;
f010508e:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0105093:	eb 46                	jmp    f01050db <vprintfmt+0x356>
		// (unsigned) octal
		case 'o':
			//putch('X', putdat);
			//putch('X', putdat);
			//putch('X', putdat);
			num = getuint(&ap, lflag);
f0105095:	8d 45 14             	lea    0x14(%ebp),%eax
f0105098:	e8 74 fc ff ff       	call   f0104d11 <getuint>
			base = 8;
f010509d:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f01050a2:	eb 37                	jmp    f01050db <vprintfmt+0x356>

		// pointer
		case 'p':
			putch('0', putdat);
f01050a4:	83 ec 08             	sub    $0x8,%esp
f01050a7:	53                   	push   %ebx
f01050a8:	6a 30                	push   $0x30
f01050aa:	ff d6                	call   *%esi
			putch('x', putdat);
f01050ac:	83 c4 08             	add    $0x8,%esp
f01050af:	53                   	push   %ebx
f01050b0:	6a 78                	push   $0x78
f01050b2:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f01050b4:	8b 45 14             	mov    0x14(%ebp),%eax
f01050b7:	8d 50 04             	lea    0x4(%eax),%edx
f01050ba:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f01050bd:	8b 00                	mov    (%eax),%eax
f01050bf:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f01050c4:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f01050c7:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f01050cc:	eb 0d                	jmp    f01050db <vprintfmt+0x356>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f01050ce:	8d 45 14             	lea    0x14(%ebp),%eax
f01050d1:	e8 3b fc ff ff       	call   f0104d11 <getuint>
			base = 16;
f01050d6:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f01050db:	83 ec 0c             	sub    $0xc,%esp
f01050de:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f01050e2:	57                   	push   %edi
f01050e3:	ff 75 e0             	pushl  -0x20(%ebp)
f01050e6:	51                   	push   %ecx
f01050e7:	52                   	push   %edx
f01050e8:	50                   	push   %eax
f01050e9:	89 da                	mov    %ebx,%edx
f01050eb:	89 f0                	mov    %esi,%eax
f01050ed:	e8 70 fb ff ff       	call   f0104c62 <printnum>
			break;
f01050f2:	83 c4 20             	add    $0x20,%esp
f01050f5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01050f8:	e9 ae fc ff ff       	jmp    f0104dab <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f01050fd:	83 ec 08             	sub    $0x8,%esp
f0105100:	53                   	push   %ebx
f0105101:	51                   	push   %ecx
f0105102:	ff d6                	call   *%esi
			break;
f0105104:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0105107:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f010510a:	e9 9c fc ff ff       	jmp    f0104dab <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f010510f:	83 ec 08             	sub    $0x8,%esp
f0105112:	53                   	push   %ebx
f0105113:	6a 25                	push   $0x25
f0105115:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0105117:	83 c4 10             	add    $0x10,%esp
f010511a:	eb 03                	jmp    f010511f <vprintfmt+0x39a>
f010511c:	83 ef 01             	sub    $0x1,%edi
f010511f:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0105123:	75 f7                	jne    f010511c <vprintfmt+0x397>
f0105125:	e9 81 fc ff ff       	jmp    f0104dab <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f010512a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010512d:	5b                   	pop    %ebx
f010512e:	5e                   	pop    %esi
f010512f:	5f                   	pop    %edi
f0105130:	5d                   	pop    %ebp
f0105131:	c3                   	ret    

f0105132 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0105132:	55                   	push   %ebp
f0105133:	89 e5                	mov    %esp,%ebp
f0105135:	83 ec 18             	sub    $0x18,%esp
f0105138:	8b 45 08             	mov    0x8(%ebp),%eax
f010513b:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f010513e:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0105141:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0105145:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0105148:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f010514f:	85 c0                	test   %eax,%eax
f0105151:	74 26                	je     f0105179 <vsnprintf+0x47>
f0105153:	85 d2                	test   %edx,%edx
f0105155:	7e 22                	jle    f0105179 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0105157:	ff 75 14             	pushl  0x14(%ebp)
f010515a:	ff 75 10             	pushl  0x10(%ebp)
f010515d:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0105160:	50                   	push   %eax
f0105161:	68 4b 4d 10 f0       	push   $0xf0104d4b
f0105166:	e8 1a fc ff ff       	call   f0104d85 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f010516b:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010516e:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0105171:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0105174:	83 c4 10             	add    $0x10,%esp
f0105177:	eb 05                	jmp    f010517e <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0105179:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f010517e:	c9                   	leave  
f010517f:	c3                   	ret    

f0105180 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0105180:	55                   	push   %ebp
f0105181:	89 e5                	mov    %esp,%ebp
f0105183:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0105186:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0105189:	50                   	push   %eax
f010518a:	ff 75 10             	pushl  0x10(%ebp)
f010518d:	ff 75 0c             	pushl  0xc(%ebp)
f0105190:	ff 75 08             	pushl  0x8(%ebp)
f0105193:	e8 9a ff ff ff       	call   f0105132 <vsnprintf>
	va_end(ap);

	return rc;
}
f0105198:	c9                   	leave  
f0105199:	c3                   	ret    

f010519a <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f010519a:	55                   	push   %ebp
f010519b:	89 e5                	mov    %esp,%ebp
f010519d:	57                   	push   %edi
f010519e:	56                   	push   %esi
f010519f:	53                   	push   %ebx
f01051a0:	83 ec 0c             	sub    $0xc,%esp
f01051a3:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

#if JOS_KERNEL
	if (prompt != NULL)
f01051a6:	85 c0                	test   %eax,%eax
f01051a8:	74 11                	je     f01051bb <readline+0x21>
		cprintf("%s", prompt);
f01051aa:	83 ec 08             	sub    $0x8,%esp
f01051ad:	50                   	push   %eax
f01051ae:	68 5c 75 10 f0       	push   $0xf010755c
f01051b3:	e8 a5 e4 ff ff       	call   f010365d <cprintf>
f01051b8:	83 c4 10             	add    $0x10,%esp
	if (prompt != NULL)
		fprintf(1, "%s", prompt);
#endif

	i = 0;
	echoing = iscons(0);
f01051bb:	83 ec 0c             	sub    $0xc,%esp
f01051be:	6a 00                	push   $0x0
f01051c0:	e8 0e b6 ff ff       	call   f01007d3 <iscons>
f01051c5:	89 c7                	mov    %eax,%edi
f01051c7:	83 c4 10             	add    $0x10,%esp
#else
	if (prompt != NULL)
		fprintf(1, "%s", prompt);
#endif

	i = 0;
f01051ca:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f01051cf:	e8 ee b5 ff ff       	call   f01007c2 <getchar>
f01051d4:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01051d6:	85 c0                	test   %eax,%eax
f01051d8:	79 29                	jns    f0105203 <readline+0x69>
			if (c != -E_EOF)
				cprintf("read error: %e\n", c);
			return NULL;
f01051da:	b8 00 00 00 00       	mov    $0x0,%eax
	i = 0;
	echoing = iscons(0);
	while (1) {
		c = getchar();
		if (c < 0) {
			if (c != -E_EOF)
f01051df:	83 fb f8             	cmp    $0xfffffff8,%ebx
f01051e2:	0f 84 9b 00 00 00    	je     f0105283 <readline+0xe9>
				cprintf("read error: %e\n", c);
f01051e8:	83 ec 08             	sub    $0x8,%esp
f01051eb:	53                   	push   %ebx
f01051ec:	68 7f 80 10 f0       	push   $0xf010807f
f01051f1:	e8 67 e4 ff ff       	call   f010365d <cprintf>
f01051f6:	83 c4 10             	add    $0x10,%esp
			return NULL;
f01051f9:	b8 00 00 00 00       	mov    $0x0,%eax
f01051fe:	e9 80 00 00 00       	jmp    f0105283 <readline+0xe9>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0105203:	83 f8 08             	cmp    $0x8,%eax
f0105206:	0f 94 c2             	sete   %dl
f0105209:	83 f8 7f             	cmp    $0x7f,%eax
f010520c:	0f 94 c0             	sete   %al
f010520f:	08 c2                	or     %al,%dl
f0105211:	74 1a                	je     f010522d <readline+0x93>
f0105213:	85 f6                	test   %esi,%esi
f0105215:	7e 16                	jle    f010522d <readline+0x93>
			if (echoing)
f0105217:	85 ff                	test   %edi,%edi
f0105219:	74 0d                	je     f0105228 <readline+0x8e>
				cputchar('\b');
f010521b:	83 ec 0c             	sub    $0xc,%esp
f010521e:	6a 08                	push   $0x8
f0105220:	e8 8d b5 ff ff       	call   f01007b2 <cputchar>
f0105225:	83 c4 10             	add    $0x10,%esp
			i--;
f0105228:	83 ee 01             	sub    $0x1,%esi
f010522b:	eb a2                	jmp    f01051cf <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f010522d:	83 fb 1f             	cmp    $0x1f,%ebx
f0105230:	7e 26                	jle    f0105258 <readline+0xbe>
f0105232:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0105238:	7f 1e                	jg     f0105258 <readline+0xbe>
			if (echoing)
f010523a:	85 ff                	test   %edi,%edi
f010523c:	74 0c                	je     f010524a <readline+0xb0>
				cputchar(c);
f010523e:	83 ec 0c             	sub    $0xc,%esp
f0105241:	53                   	push   %ebx
f0105242:	e8 6b b5 ff ff       	call   f01007b2 <cputchar>
f0105247:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f010524a:	88 9e 80 9a 2a f0    	mov    %bl,-0xfd56580(%esi)
f0105250:	8d 76 01             	lea    0x1(%esi),%esi
f0105253:	e9 77 ff ff ff       	jmp    f01051cf <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0105258:	83 fb 0a             	cmp    $0xa,%ebx
f010525b:	74 09                	je     f0105266 <readline+0xcc>
f010525d:	83 fb 0d             	cmp    $0xd,%ebx
f0105260:	0f 85 69 ff ff ff    	jne    f01051cf <readline+0x35>
			if (echoing)
f0105266:	85 ff                	test   %edi,%edi
f0105268:	74 0d                	je     f0105277 <readline+0xdd>
				cputchar('\n');
f010526a:	83 ec 0c             	sub    $0xc,%esp
f010526d:	6a 0a                	push   $0xa
f010526f:	e8 3e b5 ff ff       	call   f01007b2 <cputchar>
f0105274:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0105277:	c6 86 80 9a 2a f0 00 	movb   $0x0,-0xfd56580(%esi)
			return buf;
f010527e:	b8 80 9a 2a f0       	mov    $0xf02a9a80,%eax
		}
	}
}
f0105283:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0105286:	5b                   	pop    %ebx
f0105287:	5e                   	pop    %esi
f0105288:	5f                   	pop    %edi
f0105289:	5d                   	pop    %ebp
f010528a:	c3                   	ret    

f010528b <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f010528b:	55                   	push   %ebp
f010528c:	89 e5                	mov    %esp,%ebp
f010528e:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0105291:	b8 00 00 00 00       	mov    $0x0,%eax
f0105296:	eb 03                	jmp    f010529b <strlen+0x10>
		n++;
f0105298:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f010529b:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f010529f:	75 f7                	jne    f0105298 <strlen+0xd>
		n++;
	return n;
}
f01052a1:	5d                   	pop    %ebp
f01052a2:	c3                   	ret    

f01052a3 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01052a3:	55                   	push   %ebp
f01052a4:	89 e5                	mov    %esp,%ebp
f01052a6:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01052a9:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01052ac:	ba 00 00 00 00       	mov    $0x0,%edx
f01052b1:	eb 03                	jmp    f01052b6 <strnlen+0x13>
		n++;
f01052b3:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01052b6:	39 c2                	cmp    %eax,%edx
f01052b8:	74 08                	je     f01052c2 <strnlen+0x1f>
f01052ba:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f01052be:	75 f3                	jne    f01052b3 <strnlen+0x10>
f01052c0:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f01052c2:	5d                   	pop    %ebp
f01052c3:	c3                   	ret    

f01052c4 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01052c4:	55                   	push   %ebp
f01052c5:	89 e5                	mov    %esp,%ebp
f01052c7:	53                   	push   %ebx
f01052c8:	8b 45 08             	mov    0x8(%ebp),%eax
f01052cb:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01052ce:	89 c2                	mov    %eax,%edx
f01052d0:	83 c2 01             	add    $0x1,%edx
f01052d3:	83 c1 01             	add    $0x1,%ecx
f01052d6:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f01052da:	88 5a ff             	mov    %bl,-0x1(%edx)
f01052dd:	84 db                	test   %bl,%bl
f01052df:	75 ef                	jne    f01052d0 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f01052e1:	5b                   	pop    %ebx
f01052e2:	5d                   	pop    %ebp
f01052e3:	c3                   	ret    

f01052e4 <strcat>:

char *
strcat(char *dst, const char *src)
{
f01052e4:	55                   	push   %ebp
f01052e5:	89 e5                	mov    %esp,%ebp
f01052e7:	53                   	push   %ebx
f01052e8:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01052eb:	53                   	push   %ebx
f01052ec:	e8 9a ff ff ff       	call   f010528b <strlen>
f01052f1:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f01052f4:	ff 75 0c             	pushl  0xc(%ebp)
f01052f7:	01 d8                	add    %ebx,%eax
f01052f9:	50                   	push   %eax
f01052fa:	e8 c5 ff ff ff       	call   f01052c4 <strcpy>
	return dst;
}
f01052ff:	89 d8                	mov    %ebx,%eax
f0105301:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0105304:	c9                   	leave  
f0105305:	c3                   	ret    

f0105306 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0105306:	55                   	push   %ebp
f0105307:	89 e5                	mov    %esp,%ebp
f0105309:	56                   	push   %esi
f010530a:	53                   	push   %ebx
f010530b:	8b 75 08             	mov    0x8(%ebp),%esi
f010530e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0105311:	89 f3                	mov    %esi,%ebx
f0105313:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0105316:	89 f2                	mov    %esi,%edx
f0105318:	eb 0f                	jmp    f0105329 <strncpy+0x23>
		*dst++ = *src;
f010531a:	83 c2 01             	add    $0x1,%edx
f010531d:	0f b6 01             	movzbl (%ecx),%eax
f0105320:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0105323:	80 39 01             	cmpb   $0x1,(%ecx)
f0105326:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0105329:	39 da                	cmp    %ebx,%edx
f010532b:	75 ed                	jne    f010531a <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f010532d:	89 f0                	mov    %esi,%eax
f010532f:	5b                   	pop    %ebx
f0105330:	5e                   	pop    %esi
f0105331:	5d                   	pop    %ebp
f0105332:	c3                   	ret    

f0105333 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0105333:	55                   	push   %ebp
f0105334:	89 e5                	mov    %esp,%ebp
f0105336:	56                   	push   %esi
f0105337:	53                   	push   %ebx
f0105338:	8b 75 08             	mov    0x8(%ebp),%esi
f010533b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010533e:	8b 55 10             	mov    0x10(%ebp),%edx
f0105341:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0105343:	85 d2                	test   %edx,%edx
f0105345:	74 21                	je     f0105368 <strlcpy+0x35>
f0105347:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f010534b:	89 f2                	mov    %esi,%edx
f010534d:	eb 09                	jmp    f0105358 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f010534f:	83 c2 01             	add    $0x1,%edx
f0105352:	83 c1 01             	add    $0x1,%ecx
f0105355:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0105358:	39 c2                	cmp    %eax,%edx
f010535a:	74 09                	je     f0105365 <strlcpy+0x32>
f010535c:	0f b6 19             	movzbl (%ecx),%ebx
f010535f:	84 db                	test   %bl,%bl
f0105361:	75 ec                	jne    f010534f <strlcpy+0x1c>
f0105363:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f0105365:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0105368:	29 f0                	sub    %esi,%eax
}
f010536a:	5b                   	pop    %ebx
f010536b:	5e                   	pop    %esi
f010536c:	5d                   	pop    %ebp
f010536d:	c3                   	ret    

f010536e <strcmp>:

int
strcmp(const char *p, const char *q)
{
f010536e:	55                   	push   %ebp
f010536f:	89 e5                	mov    %esp,%ebp
f0105371:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0105374:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0105377:	eb 06                	jmp    f010537f <strcmp+0x11>
		p++, q++;
f0105379:	83 c1 01             	add    $0x1,%ecx
f010537c:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f010537f:	0f b6 01             	movzbl (%ecx),%eax
f0105382:	84 c0                	test   %al,%al
f0105384:	74 04                	je     f010538a <strcmp+0x1c>
f0105386:	3a 02                	cmp    (%edx),%al
f0105388:	74 ef                	je     f0105379 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f010538a:	0f b6 c0             	movzbl %al,%eax
f010538d:	0f b6 12             	movzbl (%edx),%edx
f0105390:	29 d0                	sub    %edx,%eax
}
f0105392:	5d                   	pop    %ebp
f0105393:	c3                   	ret    

f0105394 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0105394:	55                   	push   %ebp
f0105395:	89 e5                	mov    %esp,%ebp
f0105397:	53                   	push   %ebx
f0105398:	8b 45 08             	mov    0x8(%ebp),%eax
f010539b:	8b 55 0c             	mov    0xc(%ebp),%edx
f010539e:	89 c3                	mov    %eax,%ebx
f01053a0:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01053a3:	eb 06                	jmp    f01053ab <strncmp+0x17>
		n--, p++, q++;
f01053a5:	83 c0 01             	add    $0x1,%eax
f01053a8:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01053ab:	39 d8                	cmp    %ebx,%eax
f01053ad:	74 15                	je     f01053c4 <strncmp+0x30>
f01053af:	0f b6 08             	movzbl (%eax),%ecx
f01053b2:	84 c9                	test   %cl,%cl
f01053b4:	74 04                	je     f01053ba <strncmp+0x26>
f01053b6:	3a 0a                	cmp    (%edx),%cl
f01053b8:	74 eb                	je     f01053a5 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01053ba:	0f b6 00             	movzbl (%eax),%eax
f01053bd:	0f b6 12             	movzbl (%edx),%edx
f01053c0:	29 d0                	sub    %edx,%eax
f01053c2:	eb 05                	jmp    f01053c9 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f01053c4:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01053c9:	5b                   	pop    %ebx
f01053ca:	5d                   	pop    %ebp
f01053cb:	c3                   	ret    

f01053cc <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01053cc:	55                   	push   %ebp
f01053cd:	89 e5                	mov    %esp,%ebp
f01053cf:	8b 45 08             	mov    0x8(%ebp),%eax
f01053d2:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01053d6:	eb 07                	jmp    f01053df <strchr+0x13>
		if (*s == c)
f01053d8:	38 ca                	cmp    %cl,%dl
f01053da:	74 0f                	je     f01053eb <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01053dc:	83 c0 01             	add    $0x1,%eax
f01053df:	0f b6 10             	movzbl (%eax),%edx
f01053e2:	84 d2                	test   %dl,%dl
f01053e4:	75 f2                	jne    f01053d8 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f01053e6:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01053eb:	5d                   	pop    %ebp
f01053ec:	c3                   	ret    

f01053ed <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01053ed:	55                   	push   %ebp
f01053ee:	89 e5                	mov    %esp,%ebp
f01053f0:	8b 45 08             	mov    0x8(%ebp),%eax
f01053f3:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01053f7:	eb 03                	jmp    f01053fc <strfind+0xf>
f01053f9:	83 c0 01             	add    $0x1,%eax
f01053fc:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f01053ff:	38 ca                	cmp    %cl,%dl
f0105401:	74 04                	je     f0105407 <strfind+0x1a>
f0105403:	84 d2                	test   %dl,%dl
f0105405:	75 f2                	jne    f01053f9 <strfind+0xc>
			break;
	return (char *) s;
}
f0105407:	5d                   	pop    %ebp
f0105408:	c3                   	ret    

f0105409 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0105409:	55                   	push   %ebp
f010540a:	89 e5                	mov    %esp,%ebp
f010540c:	57                   	push   %edi
f010540d:	56                   	push   %esi
f010540e:	53                   	push   %ebx
f010540f:	8b 7d 08             	mov    0x8(%ebp),%edi
f0105412:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0105415:	85 c9                	test   %ecx,%ecx
f0105417:	74 36                	je     f010544f <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0105419:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010541f:	75 28                	jne    f0105449 <memset+0x40>
f0105421:	f6 c1 03             	test   $0x3,%cl
f0105424:	75 23                	jne    f0105449 <memset+0x40>
		c &= 0xFF;
f0105426:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f010542a:	89 d3                	mov    %edx,%ebx
f010542c:	c1 e3 08             	shl    $0x8,%ebx
f010542f:	89 d6                	mov    %edx,%esi
f0105431:	c1 e6 18             	shl    $0x18,%esi
f0105434:	89 d0                	mov    %edx,%eax
f0105436:	c1 e0 10             	shl    $0x10,%eax
f0105439:	09 f0                	or     %esi,%eax
f010543b:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f010543d:	89 d8                	mov    %ebx,%eax
f010543f:	09 d0                	or     %edx,%eax
f0105441:	c1 e9 02             	shr    $0x2,%ecx
f0105444:	fc                   	cld    
f0105445:	f3 ab                	rep stos %eax,%es:(%edi)
f0105447:	eb 06                	jmp    f010544f <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0105449:	8b 45 0c             	mov    0xc(%ebp),%eax
f010544c:	fc                   	cld    
f010544d:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f010544f:	89 f8                	mov    %edi,%eax
f0105451:	5b                   	pop    %ebx
f0105452:	5e                   	pop    %esi
f0105453:	5f                   	pop    %edi
f0105454:	5d                   	pop    %ebp
f0105455:	c3                   	ret    

f0105456 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0105456:	55                   	push   %ebp
f0105457:	89 e5                	mov    %esp,%ebp
f0105459:	57                   	push   %edi
f010545a:	56                   	push   %esi
f010545b:	8b 45 08             	mov    0x8(%ebp),%eax
f010545e:	8b 75 0c             	mov    0xc(%ebp),%esi
f0105461:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0105464:	39 c6                	cmp    %eax,%esi
f0105466:	73 35                	jae    f010549d <memmove+0x47>
f0105468:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f010546b:	39 d0                	cmp    %edx,%eax
f010546d:	73 2e                	jae    f010549d <memmove+0x47>
		s += n;
		d += n;
f010546f:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0105472:	89 d6                	mov    %edx,%esi
f0105474:	09 fe                	or     %edi,%esi
f0105476:	f7 c6 03 00 00 00    	test   $0x3,%esi
f010547c:	75 13                	jne    f0105491 <memmove+0x3b>
f010547e:	f6 c1 03             	test   $0x3,%cl
f0105481:	75 0e                	jne    f0105491 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f0105483:	83 ef 04             	sub    $0x4,%edi
f0105486:	8d 72 fc             	lea    -0x4(%edx),%esi
f0105489:	c1 e9 02             	shr    $0x2,%ecx
f010548c:	fd                   	std    
f010548d:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010548f:	eb 09                	jmp    f010549a <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0105491:	83 ef 01             	sub    $0x1,%edi
f0105494:	8d 72 ff             	lea    -0x1(%edx),%esi
f0105497:	fd                   	std    
f0105498:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f010549a:	fc                   	cld    
f010549b:	eb 1d                	jmp    f01054ba <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010549d:	89 f2                	mov    %esi,%edx
f010549f:	09 c2                	or     %eax,%edx
f01054a1:	f6 c2 03             	test   $0x3,%dl
f01054a4:	75 0f                	jne    f01054b5 <memmove+0x5f>
f01054a6:	f6 c1 03             	test   $0x3,%cl
f01054a9:	75 0a                	jne    f01054b5 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f01054ab:	c1 e9 02             	shr    $0x2,%ecx
f01054ae:	89 c7                	mov    %eax,%edi
f01054b0:	fc                   	cld    
f01054b1:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01054b3:	eb 05                	jmp    f01054ba <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01054b5:	89 c7                	mov    %eax,%edi
f01054b7:	fc                   	cld    
f01054b8:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01054ba:	5e                   	pop    %esi
f01054bb:	5f                   	pop    %edi
f01054bc:	5d                   	pop    %ebp
f01054bd:	c3                   	ret    

f01054be <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01054be:	55                   	push   %ebp
f01054bf:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f01054c1:	ff 75 10             	pushl  0x10(%ebp)
f01054c4:	ff 75 0c             	pushl  0xc(%ebp)
f01054c7:	ff 75 08             	pushl  0x8(%ebp)
f01054ca:	e8 87 ff ff ff       	call   f0105456 <memmove>
}
f01054cf:	c9                   	leave  
f01054d0:	c3                   	ret    

f01054d1 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01054d1:	55                   	push   %ebp
f01054d2:	89 e5                	mov    %esp,%ebp
f01054d4:	56                   	push   %esi
f01054d5:	53                   	push   %ebx
f01054d6:	8b 45 08             	mov    0x8(%ebp),%eax
f01054d9:	8b 55 0c             	mov    0xc(%ebp),%edx
f01054dc:	89 c6                	mov    %eax,%esi
f01054de:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01054e1:	eb 1a                	jmp    f01054fd <memcmp+0x2c>
		if (*s1 != *s2)
f01054e3:	0f b6 08             	movzbl (%eax),%ecx
f01054e6:	0f b6 1a             	movzbl (%edx),%ebx
f01054e9:	38 d9                	cmp    %bl,%cl
f01054eb:	74 0a                	je     f01054f7 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f01054ed:	0f b6 c1             	movzbl %cl,%eax
f01054f0:	0f b6 db             	movzbl %bl,%ebx
f01054f3:	29 d8                	sub    %ebx,%eax
f01054f5:	eb 0f                	jmp    f0105506 <memcmp+0x35>
		s1++, s2++;
f01054f7:	83 c0 01             	add    $0x1,%eax
f01054fa:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01054fd:	39 f0                	cmp    %esi,%eax
f01054ff:	75 e2                	jne    f01054e3 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0105501:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0105506:	5b                   	pop    %ebx
f0105507:	5e                   	pop    %esi
f0105508:	5d                   	pop    %ebp
f0105509:	c3                   	ret    

f010550a <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f010550a:	55                   	push   %ebp
f010550b:	89 e5                	mov    %esp,%ebp
f010550d:	53                   	push   %ebx
f010550e:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0105511:	89 c1                	mov    %eax,%ecx
f0105513:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f0105516:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010551a:	eb 0a                	jmp    f0105526 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f010551c:	0f b6 10             	movzbl (%eax),%edx
f010551f:	39 da                	cmp    %ebx,%edx
f0105521:	74 07                	je     f010552a <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0105523:	83 c0 01             	add    $0x1,%eax
f0105526:	39 c8                	cmp    %ecx,%eax
f0105528:	72 f2                	jb     f010551c <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f010552a:	5b                   	pop    %ebx
f010552b:	5d                   	pop    %ebp
f010552c:	c3                   	ret    

f010552d <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f010552d:	55                   	push   %ebp
f010552e:	89 e5                	mov    %esp,%ebp
f0105530:	57                   	push   %edi
f0105531:	56                   	push   %esi
f0105532:	53                   	push   %ebx
f0105533:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0105536:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0105539:	eb 03                	jmp    f010553e <strtol+0x11>
		s++;
f010553b:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010553e:	0f b6 01             	movzbl (%ecx),%eax
f0105541:	3c 20                	cmp    $0x20,%al
f0105543:	74 f6                	je     f010553b <strtol+0xe>
f0105545:	3c 09                	cmp    $0x9,%al
f0105547:	74 f2                	je     f010553b <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0105549:	3c 2b                	cmp    $0x2b,%al
f010554b:	75 0a                	jne    f0105557 <strtol+0x2a>
		s++;
f010554d:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0105550:	bf 00 00 00 00       	mov    $0x0,%edi
f0105555:	eb 11                	jmp    f0105568 <strtol+0x3b>
f0105557:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f010555c:	3c 2d                	cmp    $0x2d,%al
f010555e:	75 08                	jne    f0105568 <strtol+0x3b>
		s++, neg = 1;
f0105560:	83 c1 01             	add    $0x1,%ecx
f0105563:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0105568:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f010556e:	75 15                	jne    f0105585 <strtol+0x58>
f0105570:	80 39 30             	cmpb   $0x30,(%ecx)
f0105573:	75 10                	jne    f0105585 <strtol+0x58>
f0105575:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0105579:	75 7c                	jne    f01055f7 <strtol+0xca>
		s += 2, base = 16;
f010557b:	83 c1 02             	add    $0x2,%ecx
f010557e:	bb 10 00 00 00       	mov    $0x10,%ebx
f0105583:	eb 16                	jmp    f010559b <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f0105585:	85 db                	test   %ebx,%ebx
f0105587:	75 12                	jne    f010559b <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0105589:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f010558e:	80 39 30             	cmpb   $0x30,(%ecx)
f0105591:	75 08                	jne    f010559b <strtol+0x6e>
		s++, base = 8;
f0105593:	83 c1 01             	add    $0x1,%ecx
f0105596:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f010559b:	b8 00 00 00 00       	mov    $0x0,%eax
f01055a0:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f01055a3:	0f b6 11             	movzbl (%ecx),%edx
f01055a6:	8d 72 d0             	lea    -0x30(%edx),%esi
f01055a9:	89 f3                	mov    %esi,%ebx
f01055ab:	80 fb 09             	cmp    $0x9,%bl
f01055ae:	77 08                	ja     f01055b8 <strtol+0x8b>
			dig = *s - '0';
f01055b0:	0f be d2             	movsbl %dl,%edx
f01055b3:	83 ea 30             	sub    $0x30,%edx
f01055b6:	eb 22                	jmp    f01055da <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f01055b8:	8d 72 9f             	lea    -0x61(%edx),%esi
f01055bb:	89 f3                	mov    %esi,%ebx
f01055bd:	80 fb 19             	cmp    $0x19,%bl
f01055c0:	77 08                	ja     f01055ca <strtol+0x9d>
			dig = *s - 'a' + 10;
f01055c2:	0f be d2             	movsbl %dl,%edx
f01055c5:	83 ea 57             	sub    $0x57,%edx
f01055c8:	eb 10                	jmp    f01055da <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f01055ca:	8d 72 bf             	lea    -0x41(%edx),%esi
f01055cd:	89 f3                	mov    %esi,%ebx
f01055cf:	80 fb 19             	cmp    $0x19,%bl
f01055d2:	77 16                	ja     f01055ea <strtol+0xbd>
			dig = *s - 'A' + 10;
f01055d4:	0f be d2             	movsbl %dl,%edx
f01055d7:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f01055da:	3b 55 10             	cmp    0x10(%ebp),%edx
f01055dd:	7d 0b                	jge    f01055ea <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f01055df:	83 c1 01             	add    $0x1,%ecx
f01055e2:	0f af 45 10          	imul   0x10(%ebp),%eax
f01055e6:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f01055e8:	eb b9                	jmp    f01055a3 <strtol+0x76>

	if (endptr)
f01055ea:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01055ee:	74 0d                	je     f01055fd <strtol+0xd0>
		*endptr = (char *) s;
f01055f0:	8b 75 0c             	mov    0xc(%ebp),%esi
f01055f3:	89 0e                	mov    %ecx,(%esi)
f01055f5:	eb 06                	jmp    f01055fd <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01055f7:	85 db                	test   %ebx,%ebx
f01055f9:	74 98                	je     f0105593 <strtol+0x66>
f01055fb:	eb 9e                	jmp    f010559b <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f01055fd:	89 c2                	mov    %eax,%edx
f01055ff:	f7 da                	neg    %edx
f0105601:	85 ff                	test   %edi,%edi
f0105603:	0f 45 c2             	cmovne %edx,%eax
}
f0105606:	5b                   	pop    %ebx
f0105607:	5e                   	pop    %esi
f0105608:	5f                   	pop    %edi
f0105609:	5d                   	pop    %ebp
f010560a:	c3                   	ret    
f010560b:	90                   	nop

f010560c <mpentry_start>:
.set PROT_MODE_DSEG, 0x10	# kernel data segment selector

.code16           
.globl mpentry_start
mpentry_start:
	cli            
f010560c:	fa                   	cli    

	xorw    %ax, %ax
f010560d:	31 c0                	xor    %eax,%eax
	movw    %ax, %ds
f010560f:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f0105611:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f0105613:	8e d0                	mov    %eax,%ss

	lgdt    MPBOOTPHYS(gdtdesc)
f0105615:	0f 01 16             	lgdtl  (%esi)
f0105618:	74 70                	je     f010568a <mpsearch1+0x3>
	movl    %cr0, %eax
f010561a:	0f 20 c0             	mov    %cr0,%eax
	orl     $CR0_PE, %eax
f010561d:	66 83 c8 01          	or     $0x1,%ax
	movl    %eax, %cr0
f0105621:	0f 22 c0             	mov    %eax,%cr0

	ljmpl   $(PROT_MODE_CSEG), $(MPBOOTPHYS(start32))
f0105624:	66 ea 20 70 00 00    	ljmpw  $0x0,$0x7020
f010562a:	08 00                	or     %al,(%eax)

f010562c <start32>:

.code32
start32:
	movw    $(PROT_MODE_DSEG), %ax
f010562c:	66 b8 10 00          	mov    $0x10,%ax
	movw    %ax, %ds
f0105630:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f0105632:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f0105634:	8e d0                	mov    %eax,%ss
	movw    $0, %ax
f0105636:	66 b8 00 00          	mov    $0x0,%ax
	movw    %ax, %fs
f010563a:	8e e0                	mov    %eax,%fs
	movw    %ax, %gs
f010563c:	8e e8                	mov    %eax,%gs

	# Set up initial page table. We cannot use kern_pgdir yet because
	# we are still running at a low EIP.
	movl    $(RELOC(entry_pgdir)), %eax
f010563e:	b8 00 00 12 00       	mov    $0x120000,%eax
	movl    %eax, %cr3
f0105643:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl    %cr0, %eax
f0105646:	0f 20 c0             	mov    %cr0,%eax
	orl     $(CR0_PE|CR0_PG|CR0_WP), %eax
f0105649:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl    %eax, %cr0
f010564e:	0f 22 c0             	mov    %eax,%cr0

	# Switch to the per-cpu stack allocated in boot_aps()
	movl    mpentry_kstack, %esp
f0105651:	8b 25 9c 9e 2a f0    	mov    0xf02a9e9c,%esp
	movl    $0x0, %ebp       # nuke frame pointer
f0105657:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Call mp_main().  (Exercise for the reader: why the indirect call?)
	movl    $mp_main, %eax
f010565c:	b8 e0 01 10 f0       	mov    $0xf01001e0,%eax
	call    *%eax
f0105661:	ff d0                	call   *%eax

f0105663 <spin>:

	# If mp_main returns (it shouldn't), loop.
spin:
	jmp     spin
f0105663:	eb fe                	jmp    f0105663 <spin>
f0105665:	8d 76 00             	lea    0x0(%esi),%esi

f0105668 <gdt>:
	...
f0105670:	ff                   	(bad)  
f0105671:	ff 00                	incl   (%eax)
f0105673:	00 00                	add    %al,(%eax)
f0105675:	9a cf 00 ff ff 00 00 	lcall  $0x0,$0xffff00cf
f010567c:	00                   	.byte 0x0
f010567d:	92                   	xchg   %eax,%edx
f010567e:	cf                   	iret   
	...

f0105680 <gdtdesc>:
f0105680:	17                   	pop    %ss
f0105681:	00 5c 70 00          	add    %bl,0x0(%eax,%esi,2)
	...

f0105686 <mpentry_end>:
	.word   0x17				# sizeof(gdt) - 1
	.long   MPBOOTPHYS(gdt)			# address gdt

.globl mpentry_end
mpentry_end:
	nop
f0105686:	90                   	nop

f0105687 <mpsearch1>:
}

// Look for an MP structure in the len bytes at physical address addr.
static struct mp *
mpsearch1(physaddr_t a, int len)
{
f0105687:	55                   	push   %ebp
f0105688:	89 e5                	mov    %esp,%ebp
f010568a:	57                   	push   %edi
f010568b:	56                   	push   %esi
f010568c:	53                   	push   %ebx
f010568d:	83 ec 0c             	sub    $0xc,%esp
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0105690:	8b 0d a0 9e 2a f0    	mov    0xf02a9ea0,%ecx
f0105696:	89 c3                	mov    %eax,%ebx
f0105698:	c1 eb 0c             	shr    $0xc,%ebx
f010569b:	39 cb                	cmp    %ecx,%ebx
f010569d:	72 12                	jb     f01056b1 <mpsearch1+0x2a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010569f:	50                   	push   %eax
f01056a0:	68 44 66 10 f0       	push   $0xf0106644
f01056a5:	6a 57                	push   $0x57
f01056a7:	68 1d 82 10 f0       	push   $0xf010821d
f01056ac:	e8 8f a9 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f01056b1:	8d 98 00 00 00 f0    	lea    -0x10000000(%eax),%ebx
	struct mp *mp = KADDR(a), *end = KADDR(a + len);
f01056b7:	01 d0                	add    %edx,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01056b9:	89 c2                	mov    %eax,%edx
f01056bb:	c1 ea 0c             	shr    $0xc,%edx
f01056be:	39 ca                	cmp    %ecx,%edx
f01056c0:	72 12                	jb     f01056d4 <mpsearch1+0x4d>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01056c2:	50                   	push   %eax
f01056c3:	68 44 66 10 f0       	push   $0xf0106644
f01056c8:	6a 57                	push   $0x57
f01056ca:	68 1d 82 10 f0       	push   $0xf010821d
f01056cf:	e8 6c a9 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f01056d4:	8d b0 00 00 00 f0    	lea    -0x10000000(%eax),%esi

	for (; mp < end; mp++)
f01056da:	eb 2f                	jmp    f010570b <mpsearch1+0x84>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f01056dc:	83 ec 04             	sub    $0x4,%esp
f01056df:	6a 04                	push   $0x4
f01056e1:	68 2d 82 10 f0       	push   $0xf010822d
f01056e6:	53                   	push   %ebx
f01056e7:	e8 e5 fd ff ff       	call   f01054d1 <memcmp>
f01056ec:	83 c4 10             	add    $0x10,%esp
f01056ef:	85 c0                	test   %eax,%eax
f01056f1:	75 15                	jne    f0105708 <mpsearch1+0x81>
f01056f3:	89 da                	mov    %ebx,%edx
f01056f5:	8d 7b 10             	lea    0x10(%ebx),%edi
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
		sum += ((uint8_t *)addr)[i];
f01056f8:	0f b6 0a             	movzbl (%edx),%ecx
f01056fb:	01 c8                	add    %ecx,%eax
f01056fd:	83 c2 01             	add    $0x1,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f0105700:	39 d7                	cmp    %edx,%edi
f0105702:	75 f4                	jne    f01056f8 <mpsearch1+0x71>
mpsearch1(physaddr_t a, int len)
{
	struct mp *mp = KADDR(a), *end = KADDR(a + len);

	for (; mp < end; mp++)
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f0105704:	84 c0                	test   %al,%al
f0105706:	74 0e                	je     f0105716 <mpsearch1+0x8f>
static struct mp *
mpsearch1(physaddr_t a, int len)
{
	struct mp *mp = KADDR(a), *end = KADDR(a + len);

	for (; mp < end; mp++)
f0105708:	83 c3 10             	add    $0x10,%ebx
f010570b:	39 f3                	cmp    %esi,%ebx
f010570d:	72 cd                	jb     f01056dc <mpsearch1+0x55>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
		    sum(mp, sizeof(*mp)) == 0)
			return mp;
	return NULL;
f010570f:	b8 00 00 00 00       	mov    $0x0,%eax
f0105714:	eb 02                	jmp    f0105718 <mpsearch1+0x91>
f0105716:	89 d8                	mov    %ebx,%eax
}
f0105718:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010571b:	5b                   	pop    %ebx
f010571c:	5e                   	pop    %esi
f010571d:	5f                   	pop    %edi
f010571e:	5d                   	pop    %ebp
f010571f:	c3                   	ret    

f0105720 <mp_init>:
	return conf;
}

void
mp_init(void)
{
f0105720:	55                   	push   %ebp
f0105721:	89 e5                	mov    %esp,%ebp
f0105723:	57                   	push   %edi
f0105724:	56                   	push   %esi
f0105725:	53                   	push   %ebx
f0105726:	83 ec 1c             	sub    $0x1c,%esp
	struct mpconf *conf;
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
f0105729:	c7 05 c0 a3 2a f0 20 	movl   $0xf02aa020,0xf02aa3c0
f0105730:	a0 2a f0 
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0105733:	83 3d a0 9e 2a f0 00 	cmpl   $0x0,0xf02a9ea0
f010573a:	75 16                	jne    f0105752 <mp_init+0x32>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010573c:	68 00 04 00 00       	push   $0x400
f0105741:	68 44 66 10 f0       	push   $0xf0106644
f0105746:	6a 6f                	push   $0x6f
f0105748:	68 1d 82 10 f0       	push   $0xf010821d
f010574d:	e8 ee a8 ff ff       	call   f0100040 <_panic>
	// The BIOS data area lives in 16-bit segment 0x40.
	bda = (uint8_t *) KADDR(0x40 << 4);

	// [MP 4] The 16-bit segment of the EBDA is in the two bytes
	// starting at byte 0x0E of the BDA.  0 if not present.
	if ((p = *(uint16_t *) (bda + 0x0E))) {
f0105752:	0f b7 05 0e 04 00 f0 	movzwl 0xf000040e,%eax
f0105759:	85 c0                	test   %eax,%eax
f010575b:	74 16                	je     f0105773 <mp_init+0x53>
		p <<= 4;	// Translate from segment to PA
		if ((mp = mpsearch1(p, 1024)))
f010575d:	c1 e0 04             	shl    $0x4,%eax
f0105760:	ba 00 04 00 00       	mov    $0x400,%edx
f0105765:	e8 1d ff ff ff       	call   f0105687 <mpsearch1>
f010576a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010576d:	85 c0                	test   %eax,%eax
f010576f:	75 3c                	jne    f01057ad <mp_init+0x8d>
f0105771:	eb 20                	jmp    f0105793 <mp_init+0x73>
			return mp;
	} else {
		// The size of base memory, in KB is in the two bytes
		// starting at 0x13 of the BDA.
		p = *(uint16_t *) (bda + 0x13) * 1024;
		if ((mp = mpsearch1(p - 1024, 1024)))
f0105773:	0f b7 05 13 04 00 f0 	movzwl 0xf0000413,%eax
f010577a:	c1 e0 0a             	shl    $0xa,%eax
f010577d:	2d 00 04 00 00       	sub    $0x400,%eax
f0105782:	ba 00 04 00 00       	mov    $0x400,%edx
f0105787:	e8 fb fe ff ff       	call   f0105687 <mpsearch1>
f010578c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010578f:	85 c0                	test   %eax,%eax
f0105791:	75 1a                	jne    f01057ad <mp_init+0x8d>
			return mp;
	}
	return mpsearch1(0xF0000, 0x10000);
f0105793:	ba 00 00 01 00       	mov    $0x10000,%edx
f0105798:	b8 00 00 0f 00       	mov    $0xf0000,%eax
f010579d:	e8 e5 fe ff ff       	call   f0105687 <mpsearch1>
f01057a2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
mpconfig(struct mp **pmp)
{
	struct mpconf *conf;
	struct mp *mp;

	if ((mp = mpsearch()) == 0)
f01057a5:	85 c0                	test   %eax,%eax
f01057a7:	0f 84 5d 02 00 00    	je     f0105a0a <mp_init+0x2ea>
		return NULL;
	if (mp->physaddr == 0 || mp->type != 0) {
f01057ad:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01057b0:	8b 70 04             	mov    0x4(%eax),%esi
f01057b3:	85 f6                	test   %esi,%esi
f01057b5:	74 06                	je     f01057bd <mp_init+0x9d>
f01057b7:	80 78 0b 00          	cmpb   $0x0,0xb(%eax)
f01057bb:	74 15                	je     f01057d2 <mp_init+0xb2>
		cprintf("SMP: Default configurations not implemented\n");
f01057bd:	83 ec 0c             	sub    $0xc,%esp
f01057c0:	68 90 80 10 f0       	push   $0xf0108090
f01057c5:	e8 93 de ff ff       	call   f010365d <cprintf>
f01057ca:	83 c4 10             	add    $0x10,%esp
f01057cd:	e9 38 02 00 00       	jmp    f0105a0a <mp_init+0x2ea>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01057d2:	89 f0                	mov    %esi,%eax
f01057d4:	c1 e8 0c             	shr    $0xc,%eax
f01057d7:	3b 05 a0 9e 2a f0    	cmp    0xf02a9ea0,%eax
f01057dd:	72 15                	jb     f01057f4 <mp_init+0xd4>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01057df:	56                   	push   %esi
f01057e0:	68 44 66 10 f0       	push   $0xf0106644
f01057e5:	68 90 00 00 00       	push   $0x90
f01057ea:	68 1d 82 10 f0       	push   $0xf010821d
f01057ef:	e8 4c a8 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f01057f4:	8d 9e 00 00 00 f0    	lea    -0x10000000(%esi),%ebx
		return NULL;
	}
	conf = (struct mpconf *) KADDR(mp->physaddr);
	if (memcmp(conf, "PCMP", 4) != 0) {
f01057fa:	83 ec 04             	sub    $0x4,%esp
f01057fd:	6a 04                	push   $0x4
f01057ff:	68 32 82 10 f0       	push   $0xf0108232
f0105804:	53                   	push   %ebx
f0105805:	e8 c7 fc ff ff       	call   f01054d1 <memcmp>
f010580a:	83 c4 10             	add    $0x10,%esp
f010580d:	85 c0                	test   %eax,%eax
f010580f:	74 15                	je     f0105826 <mp_init+0x106>
		cprintf("SMP: Incorrect MP configuration table signature\n");
f0105811:	83 ec 0c             	sub    $0xc,%esp
f0105814:	68 c0 80 10 f0       	push   $0xf01080c0
f0105819:	e8 3f de ff ff       	call   f010365d <cprintf>
f010581e:	83 c4 10             	add    $0x10,%esp
f0105821:	e9 e4 01 00 00       	jmp    f0105a0a <mp_init+0x2ea>
		return NULL;
	}
	if (sum(conf, conf->length) != 0) {
f0105826:	0f b7 43 04          	movzwl 0x4(%ebx),%eax
f010582a:	66 89 45 e2          	mov    %ax,-0x1e(%ebp)
f010582e:	0f b7 f8             	movzwl %ax,%edi
static uint8_t
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
f0105831:	ba 00 00 00 00       	mov    $0x0,%edx
	for (i = 0; i < len; i++)
f0105836:	b8 00 00 00 00       	mov    $0x0,%eax
f010583b:	eb 0d                	jmp    f010584a <mp_init+0x12a>
		sum += ((uint8_t *)addr)[i];
f010583d:	0f b6 8c 30 00 00 00 	movzbl -0x10000000(%eax,%esi,1),%ecx
f0105844:	f0 
f0105845:	01 ca                	add    %ecx,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f0105847:	83 c0 01             	add    $0x1,%eax
f010584a:	39 c7                	cmp    %eax,%edi
f010584c:	75 ef                	jne    f010583d <mp_init+0x11d>
	conf = (struct mpconf *) KADDR(mp->physaddr);
	if (memcmp(conf, "PCMP", 4) != 0) {
		cprintf("SMP: Incorrect MP configuration table signature\n");
		return NULL;
	}
	if (sum(conf, conf->length) != 0) {
f010584e:	84 d2                	test   %dl,%dl
f0105850:	74 15                	je     f0105867 <mp_init+0x147>
		cprintf("SMP: Bad MP configuration checksum\n");
f0105852:	83 ec 0c             	sub    $0xc,%esp
f0105855:	68 f4 80 10 f0       	push   $0xf01080f4
f010585a:	e8 fe dd ff ff       	call   f010365d <cprintf>
f010585f:	83 c4 10             	add    $0x10,%esp
f0105862:	e9 a3 01 00 00       	jmp    f0105a0a <mp_init+0x2ea>
		return NULL;
	}
	if (conf->version != 1 && conf->version != 4) {
f0105867:	0f b6 43 06          	movzbl 0x6(%ebx),%eax
f010586b:	3c 01                	cmp    $0x1,%al
f010586d:	74 1d                	je     f010588c <mp_init+0x16c>
f010586f:	3c 04                	cmp    $0x4,%al
f0105871:	74 19                	je     f010588c <mp_init+0x16c>
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
f0105873:	83 ec 08             	sub    $0x8,%esp
f0105876:	0f b6 c0             	movzbl %al,%eax
f0105879:	50                   	push   %eax
f010587a:	68 18 81 10 f0       	push   $0xf0108118
f010587f:	e8 d9 dd ff ff       	call   f010365d <cprintf>
f0105884:	83 c4 10             	add    $0x10,%esp
f0105887:	e9 7e 01 00 00       	jmp    f0105a0a <mp_init+0x2ea>
		return NULL;
	}
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f010588c:	0f b7 7b 28          	movzwl 0x28(%ebx),%edi
f0105890:	0f b7 4d e2          	movzwl -0x1e(%ebp),%ecx
static uint8_t
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
f0105894:	ba 00 00 00 00       	mov    $0x0,%edx
	for (i = 0; i < len; i++)
f0105899:	b8 00 00 00 00       	mov    $0x0,%eax
		sum += ((uint8_t *)addr)[i];
f010589e:	01 ce                	add    %ecx,%esi
f01058a0:	eb 0d                	jmp    f01058af <mp_init+0x18f>
f01058a2:	0f b6 8c 06 00 00 00 	movzbl -0x10000000(%esi,%eax,1),%ecx
f01058a9:	f0 
f01058aa:	01 ca                	add    %ecx,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f01058ac:	83 c0 01             	add    $0x1,%eax
f01058af:	39 c7                	cmp    %eax,%edi
f01058b1:	75 ef                	jne    f01058a2 <mp_init+0x182>
	}
	if (conf->version != 1 && conf->version != 4) {
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
		return NULL;
	}
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f01058b3:	89 d0                	mov    %edx,%eax
f01058b5:	02 43 2a             	add    0x2a(%ebx),%al
f01058b8:	74 15                	je     f01058cf <mp_init+0x1af>
		cprintf("SMP: Bad MP configuration extended checksum\n");
f01058ba:	83 ec 0c             	sub    $0xc,%esp
f01058bd:	68 38 81 10 f0       	push   $0xf0108138
f01058c2:	e8 96 dd ff ff       	call   f010365d <cprintf>
f01058c7:	83 c4 10             	add    $0x10,%esp
f01058ca:	e9 3b 01 00 00       	jmp    f0105a0a <mp_init+0x2ea>
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
	if ((conf = mpconfig(&mp)) == 0)
f01058cf:	85 db                	test   %ebx,%ebx
f01058d1:	0f 84 33 01 00 00    	je     f0105a0a <mp_init+0x2ea>
		return;
	ismp = 1;
f01058d7:	c7 05 00 a0 2a f0 01 	movl   $0x1,0xf02aa000
f01058de:	00 00 00 
	lapicaddr = conf->lapicaddr;
f01058e1:	8b 43 24             	mov    0x24(%ebx),%eax
f01058e4:	a3 00 b0 2e f0       	mov    %eax,0xf02eb000

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f01058e9:	8d 7b 2c             	lea    0x2c(%ebx),%edi
f01058ec:	be 00 00 00 00       	mov    $0x0,%esi
f01058f1:	e9 85 00 00 00       	jmp    f010597b <mp_init+0x25b>
		switch (*p) {
f01058f6:	0f b6 07             	movzbl (%edi),%eax
f01058f9:	84 c0                	test   %al,%al
f01058fb:	74 06                	je     f0105903 <mp_init+0x1e3>
f01058fd:	3c 04                	cmp    $0x4,%al
f01058ff:	77 55                	ja     f0105956 <mp_init+0x236>
f0105901:	eb 4e                	jmp    f0105951 <mp_init+0x231>
		case MPPROC:
			proc = (struct mpproc *)p;
			if (proc->flags & MPPROC_BOOT)
f0105903:	f6 47 03 02          	testb  $0x2,0x3(%edi)
f0105907:	74 11                	je     f010591a <mp_init+0x1fa>
				bootcpu = &cpus[ncpu];
f0105909:	6b 05 c4 a3 2a f0 74 	imul   $0x74,0xf02aa3c4,%eax
f0105910:	05 20 a0 2a f0       	add    $0xf02aa020,%eax
f0105915:	a3 c0 a3 2a f0       	mov    %eax,0xf02aa3c0
			if (ncpu < NCPU) {
f010591a:	a1 c4 a3 2a f0       	mov    0xf02aa3c4,%eax
f010591f:	83 f8 07             	cmp    $0x7,%eax
f0105922:	7f 13                	jg     f0105937 <mp_init+0x217>
				cpus[ncpu].cpu_id = ncpu;
f0105924:	6b d0 74             	imul   $0x74,%eax,%edx
f0105927:	88 82 20 a0 2a f0    	mov    %al,-0xfd55fe0(%edx)
				ncpu++;
f010592d:	83 c0 01             	add    $0x1,%eax
f0105930:	a3 c4 a3 2a f0       	mov    %eax,0xf02aa3c4
f0105935:	eb 15                	jmp    f010594c <mp_init+0x22c>
			} else {
				cprintf("SMP: too many CPUs, CPU %d disabled\n",
f0105937:	83 ec 08             	sub    $0x8,%esp
f010593a:	0f b6 47 01          	movzbl 0x1(%edi),%eax
f010593e:	50                   	push   %eax
f010593f:	68 68 81 10 f0       	push   $0xf0108168
f0105944:	e8 14 dd ff ff       	call   f010365d <cprintf>
f0105949:	83 c4 10             	add    $0x10,%esp
					proc->apicid);
			}
			p += sizeof(struct mpproc);
f010594c:	83 c7 14             	add    $0x14,%edi
			continue;
f010594f:	eb 27                	jmp    f0105978 <mp_init+0x258>
		case MPBUS:
		case MPIOAPIC:
		case MPIOINTR:
		case MPLINTR:
			p += 8;
f0105951:	83 c7 08             	add    $0x8,%edi
			continue;
f0105954:	eb 22                	jmp    f0105978 <mp_init+0x258>
		default:
			cprintf("mpinit: unknown config type %x\n", *p);
f0105956:	83 ec 08             	sub    $0x8,%esp
f0105959:	0f b6 c0             	movzbl %al,%eax
f010595c:	50                   	push   %eax
f010595d:	68 90 81 10 f0       	push   $0xf0108190
f0105962:	e8 f6 dc ff ff       	call   f010365d <cprintf>
			ismp = 0;
f0105967:	c7 05 00 a0 2a f0 00 	movl   $0x0,0xf02aa000
f010596e:	00 00 00 
			i = conf->entry;
f0105971:	0f b7 73 22          	movzwl 0x22(%ebx),%esi
f0105975:	83 c4 10             	add    $0x10,%esp
	if ((conf = mpconfig(&mp)) == 0)
		return;
	ismp = 1;
	lapicaddr = conf->lapicaddr;

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f0105978:	83 c6 01             	add    $0x1,%esi
f010597b:	0f b7 43 22          	movzwl 0x22(%ebx),%eax
f010597f:	39 c6                	cmp    %eax,%esi
f0105981:	0f 82 6f ff ff ff    	jb     f01058f6 <mp_init+0x1d6>
			ismp = 0;
			i = conf->entry;
		}
	}

	bootcpu->cpu_status = CPU_STARTED;
f0105987:	a1 c0 a3 2a f0       	mov    0xf02aa3c0,%eax
f010598c:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
	if (!ismp) {
f0105993:	83 3d 00 a0 2a f0 00 	cmpl   $0x0,0xf02aa000
f010599a:	75 26                	jne    f01059c2 <mp_init+0x2a2>
		// Didn't like what we found; fall back to no MP.
		ncpu = 1;
f010599c:	c7 05 c4 a3 2a f0 01 	movl   $0x1,0xf02aa3c4
f01059a3:	00 00 00 
		lapicaddr = 0;
f01059a6:	c7 05 00 b0 2e f0 00 	movl   $0x0,0xf02eb000
f01059ad:	00 00 00 
		cprintf("SMP: configuration not found, SMP disabled\n");
f01059b0:	83 ec 0c             	sub    $0xc,%esp
f01059b3:	68 b0 81 10 f0       	push   $0xf01081b0
f01059b8:	e8 a0 dc ff ff       	call   f010365d <cprintf>
		return;
f01059bd:	83 c4 10             	add    $0x10,%esp
f01059c0:	eb 48                	jmp    f0105a0a <mp_init+0x2ea>
	}
	cprintf("SMP: CPU %d found %d CPU(s)\n", bootcpu->cpu_id,  ncpu);
f01059c2:	83 ec 04             	sub    $0x4,%esp
f01059c5:	ff 35 c4 a3 2a f0    	pushl  0xf02aa3c4
f01059cb:	0f b6 00             	movzbl (%eax),%eax
f01059ce:	50                   	push   %eax
f01059cf:	68 37 82 10 f0       	push   $0xf0108237
f01059d4:	e8 84 dc ff ff       	call   f010365d <cprintf>

	if (mp->imcrp) {
f01059d9:	83 c4 10             	add    $0x10,%esp
f01059dc:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01059df:	80 78 0c 00          	cmpb   $0x0,0xc(%eax)
f01059e3:	74 25                	je     f0105a0a <mp_init+0x2ea>
		// [MP 3.2.6.1] If the hardware implements PIC mode,
		// switch to getting interrupts from the LAPIC.
		cprintf("SMP: Setting IMCR to switch from PIC mode to symmetric I/O mode\n");
f01059e5:	83 ec 0c             	sub    $0xc,%esp
f01059e8:	68 dc 81 10 f0       	push   $0xf01081dc
f01059ed:	e8 6b dc ff ff       	call   f010365d <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01059f2:	ba 22 00 00 00       	mov    $0x22,%edx
f01059f7:	b8 70 00 00 00       	mov    $0x70,%eax
f01059fc:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01059fd:	ba 23 00 00 00       	mov    $0x23,%edx
f0105a02:	ec                   	in     (%dx),%al
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0105a03:	83 c8 01             	or     $0x1,%eax
f0105a06:	ee                   	out    %al,(%dx)
f0105a07:	83 c4 10             	add    $0x10,%esp
		outb(0x22, 0x70);   // Select IMCR
		outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
	}
}
f0105a0a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0105a0d:	5b                   	pop    %ebx
f0105a0e:	5e                   	pop    %esi
f0105a0f:	5f                   	pop    %edi
f0105a10:	5d                   	pop    %ebp
f0105a11:	c3                   	ret    

f0105a12 <lapicw>:
physaddr_t lapicaddr;        // Initialized in mpconfig.c
volatile uint32_t *lapic;

static void
lapicw(int index, int value)
{
f0105a12:	55                   	push   %ebp
f0105a13:	89 e5                	mov    %esp,%ebp
	lapic[index] = value;
f0105a15:	8b 0d 04 b0 2e f0    	mov    0xf02eb004,%ecx
f0105a1b:	8d 04 81             	lea    (%ecx,%eax,4),%eax
f0105a1e:	89 10                	mov    %edx,(%eax)
	lapic[ID];  // wait for write to finish, by reading
f0105a20:	a1 04 b0 2e f0       	mov    0xf02eb004,%eax
f0105a25:	8b 40 20             	mov    0x20(%eax),%eax
}
f0105a28:	5d                   	pop    %ebp
f0105a29:	c3                   	ret    

f0105a2a <cpunum>:
	lapicw(TPR, 0);
}

int
cpunum(void)
{
f0105a2a:	55                   	push   %ebp
f0105a2b:	89 e5                	mov    %esp,%ebp
	if (lapic)
f0105a2d:	a1 04 b0 2e f0       	mov    0xf02eb004,%eax
f0105a32:	85 c0                	test   %eax,%eax
f0105a34:	74 08                	je     f0105a3e <cpunum+0x14>
		return lapic[ID] >> 24;
f0105a36:	8b 40 20             	mov    0x20(%eax),%eax
f0105a39:	c1 e8 18             	shr    $0x18,%eax
f0105a3c:	eb 05                	jmp    f0105a43 <cpunum+0x19>
	return 0;
f0105a3e:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0105a43:	5d                   	pop    %ebp
f0105a44:	c3                   	ret    

f0105a45 <lapic_init>:
}

void
lapic_init(void)
{
	if (!lapicaddr)
f0105a45:	a1 00 b0 2e f0       	mov    0xf02eb000,%eax
f0105a4a:	85 c0                	test   %eax,%eax
f0105a4c:	0f 84 21 01 00 00    	je     f0105b73 <lapic_init+0x12e>
	lapic[ID];  // wait for write to finish, by reading
}

void
lapic_init(void)
{
f0105a52:	55                   	push   %ebp
f0105a53:	89 e5                	mov    %esp,%ebp
f0105a55:	83 ec 10             	sub    $0x10,%esp
	if (!lapicaddr)
		return;

	// lapicaddr is the physical address of the LAPIC's 4K MMIO
	// region.  Map it in to virtual memory so we can access it.
	lapic = mmio_map_region(lapicaddr, 4096);
f0105a58:	68 00 10 00 00       	push   $0x1000
f0105a5d:	50                   	push   %eax
f0105a5e:	e8 6f b8 ff ff       	call   f01012d2 <mmio_map_region>
f0105a63:	a3 04 b0 2e f0       	mov    %eax,0xf02eb004

	// Enable local APIC; set spurious interrupt vector.
	lapicw(SVR, ENABLE | (IRQ_OFFSET + IRQ_SPURIOUS));
f0105a68:	ba 27 01 00 00       	mov    $0x127,%edx
f0105a6d:	b8 3c 00 00 00       	mov    $0x3c,%eax
f0105a72:	e8 9b ff ff ff       	call   f0105a12 <lapicw>

	// The timer repeatedly counts down at bus frequency
	// from lapic[TICR] and then issues an interrupt.  
	// If we cared more about precise timekeeping,
	// TICR would be calibrated using an external time source.
	lapicw(TDCR, X1);
f0105a77:	ba 0b 00 00 00       	mov    $0xb,%edx
f0105a7c:	b8 f8 00 00 00       	mov    $0xf8,%eax
f0105a81:	e8 8c ff ff ff       	call   f0105a12 <lapicw>
	lapicw(TIMER, PERIODIC | (IRQ_OFFSET + IRQ_TIMER));
f0105a86:	ba 20 00 02 00       	mov    $0x20020,%edx
f0105a8b:	b8 c8 00 00 00       	mov    $0xc8,%eax
f0105a90:	e8 7d ff ff ff       	call   f0105a12 <lapicw>
	lapicw(TICR, 10000000); 
f0105a95:	ba 80 96 98 00       	mov    $0x989680,%edx
f0105a9a:	b8 e0 00 00 00       	mov    $0xe0,%eax
f0105a9f:	e8 6e ff ff ff       	call   f0105a12 <lapicw>
	//
	// According to Intel MP Specification, the BIOS should initialize
	// BSP's local APIC in Virtual Wire Mode, in which 8259A's
	// INTR is virtually connected to BSP's LINTIN0. In this mode,
	// we do not need to program the IOAPIC.
	if (thiscpu != bootcpu)
f0105aa4:	e8 81 ff ff ff       	call   f0105a2a <cpunum>
f0105aa9:	6b c0 74             	imul   $0x74,%eax,%eax
f0105aac:	05 20 a0 2a f0       	add    $0xf02aa020,%eax
f0105ab1:	83 c4 10             	add    $0x10,%esp
f0105ab4:	39 05 c0 a3 2a f0    	cmp    %eax,0xf02aa3c0
f0105aba:	74 0f                	je     f0105acb <lapic_init+0x86>
		lapicw(LINT0, MASKED);
f0105abc:	ba 00 00 01 00       	mov    $0x10000,%edx
f0105ac1:	b8 d4 00 00 00       	mov    $0xd4,%eax
f0105ac6:	e8 47 ff ff ff       	call   f0105a12 <lapicw>

	// Disable NMI (LINT1) on all CPUs
	lapicw(LINT1, MASKED);
f0105acb:	ba 00 00 01 00       	mov    $0x10000,%edx
f0105ad0:	b8 d8 00 00 00       	mov    $0xd8,%eax
f0105ad5:	e8 38 ff ff ff       	call   f0105a12 <lapicw>

	// Disable performance counter overflow interrupts
	// on machines that provide that interrupt entry.
	if (((lapic[VER]>>16) & 0xFF) >= 4)
f0105ada:	a1 04 b0 2e f0       	mov    0xf02eb004,%eax
f0105adf:	8b 40 30             	mov    0x30(%eax),%eax
f0105ae2:	c1 e8 10             	shr    $0x10,%eax
f0105ae5:	3c 03                	cmp    $0x3,%al
f0105ae7:	76 0f                	jbe    f0105af8 <lapic_init+0xb3>
		lapicw(PCINT, MASKED);
f0105ae9:	ba 00 00 01 00       	mov    $0x10000,%edx
f0105aee:	b8 d0 00 00 00       	mov    $0xd0,%eax
f0105af3:	e8 1a ff ff ff       	call   f0105a12 <lapicw>

	// Map error interrupt to IRQ_ERROR.
	lapicw(ERROR, IRQ_OFFSET + IRQ_ERROR);
f0105af8:	ba 33 00 00 00       	mov    $0x33,%edx
f0105afd:	b8 dc 00 00 00       	mov    $0xdc,%eax
f0105b02:	e8 0b ff ff ff       	call   f0105a12 <lapicw>

	// Clear error status register (requires back-to-back writes).
	lapicw(ESR, 0);
f0105b07:	ba 00 00 00 00       	mov    $0x0,%edx
f0105b0c:	b8 a0 00 00 00       	mov    $0xa0,%eax
f0105b11:	e8 fc fe ff ff       	call   f0105a12 <lapicw>
	lapicw(ESR, 0);
f0105b16:	ba 00 00 00 00       	mov    $0x0,%edx
f0105b1b:	b8 a0 00 00 00       	mov    $0xa0,%eax
f0105b20:	e8 ed fe ff ff       	call   f0105a12 <lapicw>

	// Ack any outstanding interrupts.
	lapicw(EOI, 0);
f0105b25:	ba 00 00 00 00       	mov    $0x0,%edx
f0105b2a:	b8 2c 00 00 00       	mov    $0x2c,%eax
f0105b2f:	e8 de fe ff ff       	call   f0105a12 <lapicw>

	// Send an Init Level De-Assert to synchronize arbitration ID's.
	lapicw(ICRHI, 0);
f0105b34:	ba 00 00 00 00       	mov    $0x0,%edx
f0105b39:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105b3e:	e8 cf fe ff ff       	call   f0105a12 <lapicw>
	lapicw(ICRLO, BCAST | INIT | LEVEL);
f0105b43:	ba 00 85 08 00       	mov    $0x88500,%edx
f0105b48:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105b4d:	e8 c0 fe ff ff       	call   f0105a12 <lapicw>
	while(lapic[ICRLO] & DELIVS)
f0105b52:	8b 15 04 b0 2e f0    	mov    0xf02eb004,%edx
f0105b58:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f0105b5e:	f6 c4 10             	test   $0x10,%ah
f0105b61:	75 f5                	jne    f0105b58 <lapic_init+0x113>
		;

	// Enable interrupts on the APIC (but not on the processor).
	lapicw(TPR, 0);
f0105b63:	ba 00 00 00 00       	mov    $0x0,%edx
f0105b68:	b8 20 00 00 00       	mov    $0x20,%eax
f0105b6d:	e8 a0 fe ff ff       	call   f0105a12 <lapicw>
}
f0105b72:	c9                   	leave  
f0105b73:	f3 c3                	repz ret 

f0105b75 <lapic_eoi>:

// Acknowledge interrupt.
void
lapic_eoi(void)
{
	if (lapic)
f0105b75:	83 3d 04 b0 2e f0 00 	cmpl   $0x0,0xf02eb004
f0105b7c:	74 13                	je     f0105b91 <lapic_eoi+0x1c>
}

// Acknowledge interrupt.
void
lapic_eoi(void)
{
f0105b7e:	55                   	push   %ebp
f0105b7f:	89 e5                	mov    %esp,%ebp
	if (lapic)
		lapicw(EOI, 0);
f0105b81:	ba 00 00 00 00       	mov    $0x0,%edx
f0105b86:	b8 2c 00 00 00       	mov    $0x2c,%eax
f0105b8b:	e8 82 fe ff ff       	call   f0105a12 <lapicw>
}
f0105b90:	5d                   	pop    %ebp
f0105b91:	f3 c3                	repz ret 

f0105b93 <lapic_startap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapic_startap(uint8_t apicid, uint32_t addr)
{
f0105b93:	55                   	push   %ebp
f0105b94:	89 e5                	mov    %esp,%ebp
f0105b96:	56                   	push   %esi
f0105b97:	53                   	push   %ebx
f0105b98:	8b 75 08             	mov    0x8(%ebp),%esi
f0105b9b:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0105b9e:	ba 70 00 00 00       	mov    $0x70,%edx
f0105ba3:	b8 0f 00 00 00       	mov    $0xf,%eax
f0105ba8:	ee                   	out    %al,(%dx)
f0105ba9:	ba 71 00 00 00       	mov    $0x71,%edx
f0105bae:	b8 0a 00 00 00       	mov    $0xa,%eax
f0105bb3:	ee                   	out    %al,(%dx)
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0105bb4:	83 3d a0 9e 2a f0 00 	cmpl   $0x0,0xf02a9ea0
f0105bbb:	75 19                	jne    f0105bd6 <lapic_startap+0x43>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0105bbd:	68 67 04 00 00       	push   $0x467
f0105bc2:	68 44 66 10 f0       	push   $0xf0106644
f0105bc7:	68 98 00 00 00       	push   $0x98
f0105bcc:	68 54 82 10 f0       	push   $0xf0108254
f0105bd1:	e8 6a a4 ff ff       	call   f0100040 <_panic>
	// and the warm reset vector (DWORD based at 40:67) to point at
	// the AP startup code prior to the [universal startup algorithm]."
	outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
	outb(IO_RTC+1, 0x0A);
	wrv = (uint16_t *)KADDR((0x40 << 4 | 0x67));  // Warm reset vector
	wrv[0] = 0;
f0105bd6:	66 c7 05 67 04 00 f0 	movw   $0x0,0xf0000467
f0105bdd:	00 00 
	wrv[1] = addr >> 4;
f0105bdf:	89 d8                	mov    %ebx,%eax
f0105be1:	c1 e8 04             	shr    $0x4,%eax
f0105be4:	66 a3 69 04 00 f0    	mov    %ax,0xf0000469

	// "Universal startup algorithm."
	// Send INIT (level-triggered) interrupt to reset other CPU.
	lapicw(ICRHI, apicid << 24);
f0105bea:	c1 e6 18             	shl    $0x18,%esi
f0105bed:	89 f2                	mov    %esi,%edx
f0105bef:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105bf4:	e8 19 fe ff ff       	call   f0105a12 <lapicw>
	lapicw(ICRLO, INIT | LEVEL | ASSERT);
f0105bf9:	ba 00 c5 00 00       	mov    $0xc500,%edx
f0105bfe:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105c03:	e8 0a fe ff ff       	call   f0105a12 <lapicw>
	microdelay(200);
	lapicw(ICRLO, INIT | LEVEL);
f0105c08:	ba 00 85 00 00       	mov    $0x8500,%edx
f0105c0d:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105c12:	e8 fb fd ff ff       	call   f0105a12 <lapicw>
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0105c17:	c1 eb 0c             	shr    $0xc,%ebx
f0105c1a:	80 cf 06             	or     $0x6,%bh
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
f0105c1d:	89 f2                	mov    %esi,%edx
f0105c1f:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105c24:	e8 e9 fd ff ff       	call   f0105a12 <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0105c29:	89 da                	mov    %ebx,%edx
f0105c2b:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105c30:	e8 dd fd ff ff       	call   f0105a12 <lapicw>
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
f0105c35:	89 f2                	mov    %esi,%edx
f0105c37:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105c3c:	e8 d1 fd ff ff       	call   f0105a12 <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0105c41:	89 da                	mov    %ebx,%edx
f0105c43:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105c48:	e8 c5 fd ff ff       	call   f0105a12 <lapicw>
		microdelay(200);
	}
}
f0105c4d:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0105c50:	5b                   	pop    %ebx
f0105c51:	5e                   	pop    %esi
f0105c52:	5d                   	pop    %ebp
f0105c53:	c3                   	ret    

f0105c54 <lapic_ipi>:

void
lapic_ipi(int vector)
{
f0105c54:	55                   	push   %ebp
f0105c55:	89 e5                	mov    %esp,%ebp
	lapicw(ICRLO, OTHERS | FIXED | vector);
f0105c57:	8b 55 08             	mov    0x8(%ebp),%edx
f0105c5a:	81 ca 00 00 0c 00    	or     $0xc0000,%edx
f0105c60:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105c65:	e8 a8 fd ff ff       	call   f0105a12 <lapicw>
	while (lapic[ICRLO] & DELIVS)
f0105c6a:	8b 15 04 b0 2e f0    	mov    0xf02eb004,%edx
f0105c70:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f0105c76:	f6 c4 10             	test   $0x10,%ah
f0105c79:	75 f5                	jne    f0105c70 <lapic_ipi+0x1c>
		;
}
f0105c7b:	5d                   	pop    %ebp
f0105c7c:	c3                   	ret    

f0105c7d <__spin_initlock>:
}
#endif

void
__spin_initlock(struct spinlock *lk, char *name)
{
f0105c7d:	55                   	push   %ebp
f0105c7e:	89 e5                	mov    %esp,%ebp
f0105c80:	8b 45 08             	mov    0x8(%ebp),%eax
	lk->locked = 0;
f0105c83:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
#ifdef DEBUG_SPINLOCK
	lk->name = name;
f0105c89:	8b 55 0c             	mov    0xc(%ebp),%edx
f0105c8c:	89 50 04             	mov    %edx,0x4(%eax)
	lk->cpu = 0;
f0105c8f:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
#endif
}
f0105c96:	5d                   	pop    %ebp
f0105c97:	c3                   	ret    

f0105c98 <spin_lock>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
spin_lock(struct spinlock *lk)
{
f0105c98:	55                   	push   %ebp
f0105c99:	89 e5                	mov    %esp,%ebp
f0105c9b:	56                   	push   %esi
f0105c9c:	53                   	push   %ebx
f0105c9d:	8b 5d 08             	mov    0x8(%ebp),%ebx

// Check whether this CPU is holding the lock.
static int
holding(struct spinlock *lock)
{
	return lock->locked && lock->cpu == thiscpu;
f0105ca0:	83 3b 00             	cmpl   $0x0,(%ebx)
f0105ca3:	74 14                	je     f0105cb9 <spin_lock+0x21>
f0105ca5:	8b 73 08             	mov    0x8(%ebx),%esi
f0105ca8:	e8 7d fd ff ff       	call   f0105a2a <cpunum>
f0105cad:	6b c0 74             	imul   $0x74,%eax,%eax
f0105cb0:	05 20 a0 2a f0       	add    $0xf02aa020,%eax
// other CPUs to waste time spinning to acquire it.
void
spin_lock(struct spinlock *lk)
{
#ifdef DEBUG_SPINLOCK
	if (holding(lk))
f0105cb5:	39 c6                	cmp    %eax,%esi
f0105cb7:	74 07                	je     f0105cc0 <spin_lock+0x28>
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"
f0105cb9:	ba 01 00 00 00       	mov    $0x1,%edx
f0105cbe:	eb 20                	jmp    f0105ce0 <spin_lock+0x48>
		panic("CPU %d cannot acquire %s: already holding", cpunum(), lk->name);
f0105cc0:	8b 5b 04             	mov    0x4(%ebx),%ebx
f0105cc3:	e8 62 fd ff ff       	call   f0105a2a <cpunum>
f0105cc8:	83 ec 0c             	sub    $0xc,%esp
f0105ccb:	53                   	push   %ebx
f0105ccc:	50                   	push   %eax
f0105ccd:	68 64 82 10 f0       	push   $0xf0108264
f0105cd2:	6a 41                	push   $0x41
f0105cd4:	68 c6 82 10 f0       	push   $0xf01082c6
f0105cd9:	e8 62 a3 ff ff       	call   f0100040 <_panic>

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
		asm volatile ("pause");
f0105cde:	f3 90                	pause  
f0105ce0:	89 d0                	mov    %edx,%eax
f0105ce2:	f0 87 03             	lock xchg %eax,(%ebx)
#endif

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
f0105ce5:	85 c0                	test   %eax,%eax
f0105ce7:	75 f5                	jne    f0105cde <spin_lock+0x46>
		asm volatile ("pause");

	// Record info about lock acquisition for debugging.
#ifdef DEBUG_SPINLOCK
	lk->cpu = thiscpu;
f0105ce9:	e8 3c fd ff ff       	call   f0105a2a <cpunum>
f0105cee:	6b c0 74             	imul   $0x74,%eax,%eax
f0105cf1:	05 20 a0 2a f0       	add    $0xf02aa020,%eax
f0105cf6:	89 43 08             	mov    %eax,0x8(%ebx)
	get_caller_pcs(lk->pcs);
f0105cf9:	83 c3 0c             	add    $0xc,%ebx

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f0105cfc:	89 ea                	mov    %ebp,%edx
{
	uint32_t *ebp;
	int i;

	ebp = (uint32_t *)read_ebp();
	for (i = 0; i < 10; i++){
f0105cfe:	b8 00 00 00 00       	mov    $0x0,%eax
f0105d03:	eb 0b                	jmp    f0105d10 <spin_lock+0x78>
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
			break;
		pcs[i] = ebp[1];          // saved %eip
f0105d05:	8b 4a 04             	mov    0x4(%edx),%ecx
f0105d08:	89 0c 83             	mov    %ecx,(%ebx,%eax,4)
		ebp = (uint32_t *)ebp[0]; // saved %ebp
f0105d0b:	8b 12                	mov    (%edx),%edx
{
	uint32_t *ebp;
	int i;

	ebp = (uint32_t *)read_ebp();
	for (i = 0; i < 10; i++){
f0105d0d:	83 c0 01             	add    $0x1,%eax
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
f0105d10:	81 fa ff ff 7f ef    	cmp    $0xef7fffff,%edx
f0105d16:	76 11                	jbe    f0105d29 <spin_lock+0x91>
f0105d18:	83 f8 09             	cmp    $0x9,%eax
f0105d1b:	7e e8                	jle    f0105d05 <spin_lock+0x6d>
f0105d1d:	eb 0a                	jmp    f0105d29 <spin_lock+0x91>
			break;
		pcs[i] = ebp[1];          // saved %eip
		ebp = (uint32_t *)ebp[0]; // saved %ebp
	}
	for (; i < 10; i++)
		pcs[i] = 0;
f0105d1f:	c7 04 83 00 00 00 00 	movl   $0x0,(%ebx,%eax,4)
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
			break;
		pcs[i] = ebp[1];          // saved %eip
		ebp = (uint32_t *)ebp[0]; // saved %ebp
	}
	for (; i < 10; i++)
f0105d26:	83 c0 01             	add    $0x1,%eax
f0105d29:	83 f8 09             	cmp    $0x9,%eax
f0105d2c:	7e f1                	jle    f0105d1f <spin_lock+0x87>
	// Record info about lock acquisition for debugging.
#ifdef DEBUG_SPINLOCK
	lk->cpu = thiscpu;
	get_caller_pcs(lk->pcs);
#endif
}
f0105d2e:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0105d31:	5b                   	pop    %ebx
f0105d32:	5e                   	pop    %esi
f0105d33:	5d                   	pop    %ebp
f0105d34:	c3                   	ret    

f0105d35 <spin_unlock>:

// Release the lock.
void
spin_unlock(struct spinlock *lk)
{
f0105d35:	55                   	push   %ebp
f0105d36:	89 e5                	mov    %esp,%ebp
f0105d38:	57                   	push   %edi
f0105d39:	56                   	push   %esi
f0105d3a:	53                   	push   %ebx
f0105d3b:	83 ec 4c             	sub    $0x4c,%esp
f0105d3e:	8b 75 08             	mov    0x8(%ebp),%esi

// Check whether this CPU is holding the lock.
static int
holding(struct spinlock *lock)
{
	return lock->locked && lock->cpu == thiscpu;
f0105d41:	83 3e 00             	cmpl   $0x0,(%esi)
f0105d44:	74 18                	je     f0105d5e <spin_unlock+0x29>
f0105d46:	8b 5e 08             	mov    0x8(%esi),%ebx
f0105d49:	e8 dc fc ff ff       	call   f0105a2a <cpunum>
f0105d4e:	6b c0 74             	imul   $0x74,%eax,%eax
f0105d51:	05 20 a0 2a f0       	add    $0xf02aa020,%eax
// Release the lock.
void
spin_unlock(struct spinlock *lk)
{
#ifdef DEBUG_SPINLOCK
	if (!holding(lk)) {
f0105d56:	39 c3                	cmp    %eax,%ebx
f0105d58:	0f 84 a5 00 00 00    	je     f0105e03 <spin_unlock+0xce>
		int i;
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
f0105d5e:	83 ec 04             	sub    $0x4,%esp
f0105d61:	6a 28                	push   $0x28
f0105d63:	8d 46 0c             	lea    0xc(%esi),%eax
f0105d66:	50                   	push   %eax
f0105d67:	8d 5d c0             	lea    -0x40(%ebp),%ebx
f0105d6a:	53                   	push   %ebx
f0105d6b:	e8 e6 f6 ff ff       	call   f0105456 <memmove>
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
f0105d70:	8b 46 08             	mov    0x8(%esi),%eax
	if (!holding(lk)) {
		int i;
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
f0105d73:	0f b6 38             	movzbl (%eax),%edi
f0105d76:	8b 76 04             	mov    0x4(%esi),%esi
f0105d79:	e8 ac fc ff ff       	call   f0105a2a <cpunum>
f0105d7e:	57                   	push   %edi
f0105d7f:	56                   	push   %esi
f0105d80:	50                   	push   %eax
f0105d81:	68 90 82 10 f0       	push   $0xf0108290
f0105d86:	e8 d2 d8 ff ff       	call   f010365d <cprintf>
f0105d8b:	83 c4 20             	add    $0x20,%esp
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
			struct Eipdebuginfo info;
			if (debuginfo_eip(pcs[i], &info) >= 0)
f0105d8e:	8d 7d a8             	lea    -0x58(%ebp),%edi
f0105d91:	eb 54                	jmp    f0105de7 <spin_unlock+0xb2>
f0105d93:	83 ec 08             	sub    $0x8,%esp
f0105d96:	57                   	push   %edi
f0105d97:	50                   	push   %eax
f0105d98:	e8 a4 eb ff ff       	call   f0104941 <debuginfo_eip>
f0105d9d:	83 c4 10             	add    $0x10,%esp
f0105da0:	85 c0                	test   %eax,%eax
f0105da2:	78 27                	js     f0105dcb <spin_unlock+0x96>
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
					info.eip_file, info.eip_line,
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
f0105da4:	8b 06                	mov    (%esi),%eax
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
			struct Eipdebuginfo info;
			if (debuginfo_eip(pcs[i], &info) >= 0)
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
f0105da6:	83 ec 04             	sub    $0x4,%esp
f0105da9:	89 c2                	mov    %eax,%edx
f0105dab:	2b 55 b8             	sub    -0x48(%ebp),%edx
f0105dae:	52                   	push   %edx
f0105daf:	ff 75 b0             	pushl  -0x50(%ebp)
f0105db2:	ff 75 b4             	pushl  -0x4c(%ebp)
f0105db5:	ff 75 ac             	pushl  -0x54(%ebp)
f0105db8:	ff 75 a8             	pushl  -0x58(%ebp)
f0105dbb:	50                   	push   %eax
f0105dbc:	68 d6 82 10 f0       	push   $0xf01082d6
f0105dc1:	e8 97 d8 ff ff       	call   f010365d <cprintf>
f0105dc6:	83 c4 20             	add    $0x20,%esp
f0105dc9:	eb 12                	jmp    f0105ddd <spin_unlock+0xa8>
					info.eip_file, info.eip_line,
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
			else
				cprintf("  %08x\n", pcs[i]);
f0105dcb:	83 ec 08             	sub    $0x8,%esp
f0105dce:	ff 36                	pushl  (%esi)
f0105dd0:	68 ed 82 10 f0       	push   $0xf01082ed
f0105dd5:	e8 83 d8 ff ff       	call   f010365d <cprintf>
f0105dda:	83 c4 10             	add    $0x10,%esp
f0105ddd:	83 c3 04             	add    $0x4,%ebx
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
f0105de0:	8d 45 e8             	lea    -0x18(%ebp),%eax
f0105de3:	39 c3                	cmp    %eax,%ebx
f0105de5:	74 08                	je     f0105def <spin_unlock+0xba>
f0105de7:	89 de                	mov    %ebx,%esi
f0105de9:	8b 03                	mov    (%ebx),%eax
f0105deb:	85 c0                	test   %eax,%eax
f0105ded:	75 a4                	jne    f0105d93 <spin_unlock+0x5e>
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
			else
				cprintf("  %08x\n", pcs[i]);
		}
		panic("spin_unlock");
f0105def:	83 ec 04             	sub    $0x4,%esp
f0105df2:	68 f5 82 10 f0       	push   $0xf01082f5
f0105df7:	6a 67                	push   $0x67
f0105df9:	68 c6 82 10 f0       	push   $0xf01082c6
f0105dfe:	e8 3d a2 ff ff       	call   f0100040 <_panic>
	}

	lk->pcs[0] = 0;
f0105e03:	c7 46 0c 00 00 00 00 	movl   $0x0,0xc(%esi)
	lk->cpu = 0;
f0105e0a:	c7 46 08 00 00 00 00 	movl   $0x0,0x8(%esi)
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"
f0105e11:	b8 00 00 00 00       	mov    $0x0,%eax
f0105e16:	f0 87 06             	lock xchg %eax,(%esi)
	// respect to any other instruction which references the same memory.
	// x86 CPUs will not reorder loads/stores across locked instructions
	// (vol 3, 8.2.2). Because xchg() is implemented using asm volatile,
	// gcc will not reorder C statements across the xchg.
	xchg(&lk->locked, 0);
}
f0105e19:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0105e1c:	5b                   	pop    %ebx
f0105e1d:	5e                   	pop    %esi
f0105e1e:	5f                   	pop    %edi
f0105e1f:	5d                   	pop    %ebp
f0105e20:	c3                   	ret    

f0105e21 <pci_attach_match>:
}

static int __attribute__((warn_unused_result))
pci_attach_match(uint32_t key1, uint32_t key2,
		 struct pci_driver *list, struct pci_func *pcif)
{
f0105e21:	55                   	push   %ebp
f0105e22:	89 e5                	mov    %esp,%ebp
f0105e24:	57                   	push   %edi
f0105e25:	56                   	push   %esi
f0105e26:	53                   	push   %ebx
f0105e27:	83 ec 0c             	sub    $0xc,%esp
f0105e2a:	8b 7d 08             	mov    0x8(%ebp),%edi
f0105e2d:	8b 45 10             	mov    0x10(%ebp),%eax
f0105e30:	8d 58 08             	lea    0x8(%eax),%ebx
	uint32_t i;

	for (i = 0; list[i].attachfn; i++) {
f0105e33:	eb 3a                	jmp    f0105e6f <pci_attach_match+0x4e>
		if (list[i].key1 == key1 && list[i].key2 == key2) {
f0105e35:	39 7b f8             	cmp    %edi,-0x8(%ebx)
f0105e38:	75 32                	jne    f0105e6c <pci_attach_match+0x4b>
f0105e3a:	8b 55 0c             	mov    0xc(%ebp),%edx
f0105e3d:	39 56 fc             	cmp    %edx,-0x4(%esi)
f0105e40:	75 2a                	jne    f0105e6c <pci_attach_match+0x4b>
			int r = list[i].attachfn(pcif);
f0105e42:	83 ec 0c             	sub    $0xc,%esp
f0105e45:	ff 75 14             	pushl  0x14(%ebp)
f0105e48:	ff d0                	call   *%eax
			if (r > 0)
f0105e4a:	83 c4 10             	add    $0x10,%esp
f0105e4d:	85 c0                	test   %eax,%eax
f0105e4f:	7f 26                	jg     f0105e77 <pci_attach_match+0x56>
				return r;
			if (r < 0)
f0105e51:	85 c0                	test   %eax,%eax
f0105e53:	79 17                	jns    f0105e6c <pci_attach_match+0x4b>
				cprintf("pci_attach_match: attaching "
f0105e55:	83 ec 0c             	sub    $0xc,%esp
f0105e58:	50                   	push   %eax
f0105e59:	ff 36                	pushl  (%esi)
f0105e5b:	ff 75 0c             	pushl  0xc(%ebp)
f0105e5e:	57                   	push   %edi
f0105e5f:	68 10 83 10 f0       	push   $0xf0108310
f0105e64:	e8 f4 d7 ff ff       	call   f010365d <cprintf>
f0105e69:	83 c4 20             	add    $0x20,%esp
f0105e6c:	83 c3 0c             	add    $0xc,%ebx
f0105e6f:	89 de                	mov    %ebx,%esi
pci_attach_match(uint32_t key1, uint32_t key2,
		 struct pci_driver *list, struct pci_func *pcif)
{
	uint32_t i;

	for (i = 0; list[i].attachfn; i++) {
f0105e71:	8b 03                	mov    (%ebx),%eax
f0105e73:	85 c0                	test   %eax,%eax
f0105e75:	75 be                	jne    f0105e35 <pci_attach_match+0x14>
					"%x.%x (%p): e\n",
					key1, key2, list[i].attachfn, r);
		}
	}
	return 0;
}
f0105e77:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0105e7a:	5b                   	pop    %ebx
f0105e7b:	5e                   	pop    %esi
f0105e7c:	5f                   	pop    %edi
f0105e7d:	5d                   	pop    %ebp
f0105e7e:	c3                   	ret    

f0105e7f <pci_conf1_set_addr>:
static void
pci_conf1_set_addr(uint32_t bus,
		   uint32_t dev,
		   uint32_t func,
		   uint32_t offset)
{
f0105e7f:	55                   	push   %ebp
f0105e80:	89 e5                	mov    %esp,%ebp
f0105e82:	53                   	push   %ebx
f0105e83:	83 ec 04             	sub    $0x4,%esp
f0105e86:	8b 5d 08             	mov    0x8(%ebp),%ebx
	assert(bus < 256);
f0105e89:	3d ff 00 00 00       	cmp    $0xff,%eax
f0105e8e:	76 16                	jbe    f0105ea6 <pci_conf1_set_addr+0x27>
f0105e90:	68 68 84 10 f0       	push   $0xf0108468
f0105e95:	68 4a 75 10 f0       	push   $0xf010754a
f0105e9a:	6a 2b                	push   $0x2b
f0105e9c:	68 72 84 10 f0       	push   $0xf0108472
f0105ea1:	e8 9a a1 ff ff       	call   f0100040 <_panic>
	assert(dev < 32);
f0105ea6:	83 fa 1f             	cmp    $0x1f,%edx
f0105ea9:	76 16                	jbe    f0105ec1 <pci_conf1_set_addr+0x42>
f0105eab:	68 7d 84 10 f0       	push   $0xf010847d
f0105eb0:	68 4a 75 10 f0       	push   $0xf010754a
f0105eb5:	6a 2c                	push   $0x2c
f0105eb7:	68 72 84 10 f0       	push   $0xf0108472
f0105ebc:	e8 7f a1 ff ff       	call   f0100040 <_panic>
	assert(func < 8);
f0105ec1:	83 f9 07             	cmp    $0x7,%ecx
f0105ec4:	76 16                	jbe    f0105edc <pci_conf1_set_addr+0x5d>
f0105ec6:	68 86 84 10 f0       	push   $0xf0108486
f0105ecb:	68 4a 75 10 f0       	push   $0xf010754a
f0105ed0:	6a 2d                	push   $0x2d
f0105ed2:	68 72 84 10 f0       	push   $0xf0108472
f0105ed7:	e8 64 a1 ff ff       	call   f0100040 <_panic>
	assert(offset < 256);
f0105edc:	81 fb ff 00 00 00    	cmp    $0xff,%ebx
f0105ee2:	76 16                	jbe    f0105efa <pci_conf1_set_addr+0x7b>
f0105ee4:	68 8f 84 10 f0       	push   $0xf010848f
f0105ee9:	68 4a 75 10 f0       	push   $0xf010754a
f0105eee:	6a 2e                	push   $0x2e
f0105ef0:	68 72 84 10 f0       	push   $0xf0108472
f0105ef5:	e8 46 a1 ff ff       	call   f0100040 <_panic>
	assert((offset & 0x3) == 0);
f0105efa:	f6 c3 03             	test   $0x3,%bl
f0105efd:	74 16                	je     f0105f15 <pci_conf1_set_addr+0x96>
f0105eff:	68 9c 84 10 f0       	push   $0xf010849c
f0105f04:	68 4a 75 10 f0       	push   $0xf010754a
f0105f09:	6a 2f                	push   $0x2f
f0105f0b:	68 72 84 10 f0       	push   $0xf0108472
f0105f10:	e8 2b a1 ff ff       	call   f0100040 <_panic>
}

static inline void
outl(int port, uint32_t data)
{
	asm volatile("outl %0,%w1" : : "a" (data), "d" (port));
f0105f15:	c1 e1 08             	shl    $0x8,%ecx
f0105f18:	81 cb 00 00 00 80    	or     $0x80000000,%ebx
f0105f1e:	09 cb                	or     %ecx,%ebx
f0105f20:	c1 e2 0b             	shl    $0xb,%edx
f0105f23:	09 d3                	or     %edx,%ebx
f0105f25:	c1 e0 10             	shl    $0x10,%eax
f0105f28:	09 d8                	or     %ebx,%eax
f0105f2a:	ba f8 0c 00 00       	mov    $0xcf8,%edx
f0105f2f:	ef                   	out    %eax,(%dx)

	uint32_t v = (1 << 31) |		// config-space
		(bus << 16) | (dev << 11) | (func << 8) | (offset);
	outl(pci_conf1_addr_ioport, v);
}
f0105f30:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0105f33:	c9                   	leave  
f0105f34:	c3                   	ret    

f0105f35 <pci_conf_read>:

static uint32_t
pci_conf_read(struct pci_func *f, uint32_t off)
{
f0105f35:	55                   	push   %ebp
f0105f36:	89 e5                	mov    %esp,%ebp
f0105f38:	53                   	push   %ebx
f0105f39:	83 ec 10             	sub    $0x10,%esp
	pci_conf1_set_addr(f->bus->busno, f->dev, f->func, off);
f0105f3c:	8b 48 08             	mov    0x8(%eax),%ecx
f0105f3f:	8b 58 04             	mov    0x4(%eax),%ebx
f0105f42:	8b 00                	mov    (%eax),%eax
f0105f44:	8b 40 04             	mov    0x4(%eax),%eax
f0105f47:	52                   	push   %edx
f0105f48:	89 da                	mov    %ebx,%edx
f0105f4a:	e8 30 ff ff ff       	call   f0105e7f <pci_conf1_set_addr>

static inline uint32_t
inl(int port)
{
	uint32_t data;
	asm volatile("inl %w1,%0" : "=a" (data) : "d" (port));
f0105f4f:	ba fc 0c 00 00       	mov    $0xcfc,%edx
f0105f54:	ed                   	in     (%dx),%eax
	return inl(pci_conf1_data_ioport);
}
f0105f55:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0105f58:	c9                   	leave  
f0105f59:	c3                   	ret    

f0105f5a <pci_scan_bus>:
		f->irq_line);
}

static int
pci_scan_bus(struct pci_bus *bus)
{
f0105f5a:	55                   	push   %ebp
f0105f5b:	89 e5                	mov    %esp,%ebp
f0105f5d:	57                   	push   %edi
f0105f5e:	56                   	push   %esi
f0105f5f:	53                   	push   %ebx
f0105f60:	81 ec 00 01 00 00    	sub    $0x100,%esp
f0105f66:	89 c3                	mov    %eax,%ebx
	int totaldev = 0;
	struct pci_func df;
	memset(&df, 0, sizeof(df));
f0105f68:	6a 48                	push   $0x48
f0105f6a:	6a 00                	push   $0x0
f0105f6c:	8d 45 a0             	lea    -0x60(%ebp),%eax
f0105f6f:	50                   	push   %eax
f0105f70:	e8 94 f4 ff ff       	call   f0105409 <memset>
	df.bus = bus;
f0105f75:	89 5d a0             	mov    %ebx,-0x60(%ebp)

	for (df.dev = 0; df.dev < 32; df.dev++) {
f0105f78:	c7 45 a4 00 00 00 00 	movl   $0x0,-0x5c(%ebp)
f0105f7f:	83 c4 10             	add    $0x10,%esp
}

static int
pci_scan_bus(struct pci_bus *bus)
{
	int totaldev = 0;
f0105f82:	c7 85 00 ff ff ff 00 	movl   $0x0,-0x100(%ebp)
f0105f89:	00 00 00 
	struct pci_func df;
	memset(&df, 0, sizeof(df));
	df.bus = bus;

	for (df.dev = 0; df.dev < 32; df.dev++) {
		uint32_t bhlc = pci_conf_read(&df, PCI_BHLC_REG);
f0105f8c:	ba 0c 00 00 00       	mov    $0xc,%edx
f0105f91:	8d 45 a0             	lea    -0x60(%ebp),%eax
f0105f94:	e8 9c ff ff ff       	call   f0105f35 <pci_conf_read>
		if (PCI_HDRTYPE_TYPE(bhlc) > 1)	    // Unsupported or no device
f0105f99:	89 c2                	mov    %eax,%edx
f0105f9b:	c1 ea 10             	shr    $0x10,%edx
f0105f9e:	83 e2 7f             	and    $0x7f,%edx
f0105fa1:	83 fa 01             	cmp    $0x1,%edx
f0105fa4:	0f 87 4b 01 00 00    	ja     f01060f5 <pci_scan_bus+0x19b>
			continue;

		totaldev++;
f0105faa:	83 85 00 ff ff ff 01 	addl   $0x1,-0x100(%ebp)

		struct pci_func f = df;
f0105fb1:	8d bd 10 ff ff ff    	lea    -0xf0(%ebp),%edi
f0105fb7:	8d 75 a0             	lea    -0x60(%ebp),%esi
f0105fba:	b9 12 00 00 00       	mov    $0x12,%ecx
f0105fbf:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		for (f.func = 0; f.func < (PCI_HDRTYPE_MULTIFN(bhlc) ? 8 : 1);
f0105fc1:	c7 85 18 ff ff ff 00 	movl   $0x0,-0xe8(%ebp)
f0105fc8:	00 00 00 
f0105fcb:	25 00 00 80 00       	and    $0x800000,%eax
f0105fd0:	83 f8 01             	cmp    $0x1,%eax
f0105fd3:	19 c0                	sbb    %eax,%eax
f0105fd5:	83 e0 f9             	and    $0xfffffff9,%eax
f0105fd8:	83 c0 08             	add    $0x8,%eax
f0105fdb:	89 85 04 ff ff ff    	mov    %eax,-0xfc(%ebp)

			af.dev_id = pci_conf_read(&f, PCI_ID_REG);
			if (PCI_VENDOR(af.dev_id) == 0xffff)
				continue;

			uint32_t intr = pci_conf_read(&af, PCI_INTERRUPT_REG);
f0105fe1:	8d 9d 58 ff ff ff    	lea    -0xa8(%ebp),%ebx
			continue;

		totaldev++;

		struct pci_func f = df;
		for (f.func = 0; f.func < (PCI_HDRTYPE_MULTIFN(bhlc) ? 8 : 1);
f0105fe7:	e9 f7 00 00 00       	jmp    f01060e3 <pci_scan_bus+0x189>
		     f.func++) {
			struct pci_func af = f;
f0105fec:	8d bd 58 ff ff ff    	lea    -0xa8(%ebp),%edi
f0105ff2:	8d b5 10 ff ff ff    	lea    -0xf0(%ebp),%esi
f0105ff8:	b9 12 00 00 00       	mov    $0x12,%ecx
f0105ffd:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)

			af.dev_id = pci_conf_read(&f, PCI_ID_REG);
f0105fff:	ba 00 00 00 00       	mov    $0x0,%edx
f0106004:	8d 85 10 ff ff ff    	lea    -0xf0(%ebp),%eax
f010600a:	e8 26 ff ff ff       	call   f0105f35 <pci_conf_read>
f010600f:	89 85 64 ff ff ff    	mov    %eax,-0x9c(%ebp)
			if (PCI_VENDOR(af.dev_id) == 0xffff)
f0106015:	66 83 f8 ff          	cmp    $0xffff,%ax
f0106019:	0f 84 bd 00 00 00    	je     f01060dc <pci_scan_bus+0x182>
				continue;

			uint32_t intr = pci_conf_read(&af, PCI_INTERRUPT_REG);
f010601f:	ba 3c 00 00 00       	mov    $0x3c,%edx
f0106024:	89 d8                	mov    %ebx,%eax
f0106026:	e8 0a ff ff ff       	call   f0105f35 <pci_conf_read>
			af.irq_line = PCI_INTERRUPT_LINE(intr);
f010602b:	88 45 9c             	mov    %al,-0x64(%ebp)

			af.dev_class = pci_conf_read(&af, PCI_CLASS_REG);
f010602e:	ba 08 00 00 00       	mov    $0x8,%edx
f0106033:	89 d8                	mov    %ebx,%eax
f0106035:	e8 fb fe ff ff       	call   f0105f35 <pci_conf_read>
f010603a:	89 85 68 ff ff ff    	mov    %eax,-0x98(%ebp)

static void
pci_print_func(struct pci_func *f)
{
	const char *class = pci_class[0];
	if (PCI_CLASS(f->dev_class) < ARRAY_SIZE(pci_class))
f0106040:	89 c1                	mov    %eax,%ecx
f0106042:	c1 e9 18             	shr    $0x18,%ecx
};

static void
pci_print_func(struct pci_func *f)
{
	const char *class = pci_class[0];
f0106045:	be b0 84 10 f0       	mov    $0xf01084b0,%esi
	if (PCI_CLASS(f->dev_class) < ARRAY_SIZE(pci_class))
f010604a:	83 f9 06             	cmp    $0x6,%ecx
f010604d:	77 07                	ja     f0106056 <pci_scan_bus+0xfc>
		class = pci_class[PCI_CLASS(f->dev_class)];
f010604f:	8b 34 8d 24 85 10 f0 	mov    -0xfef7adc(,%ecx,4),%esi

	cprintf("PCI: %02x:%02x.%d: %04x:%04x: class: %x.%x (%s) irq: %d\n",
		f->bus->busno, f->dev, f->func,
		PCI_VENDOR(f->dev_id), PCI_PRODUCT(f->dev_id),
f0106056:	8b 95 64 ff ff ff    	mov    -0x9c(%ebp),%edx
{
	const char *class = pci_class[0];
	if (PCI_CLASS(f->dev_class) < ARRAY_SIZE(pci_class))
		class = pci_class[PCI_CLASS(f->dev_class)];

	cprintf("PCI: %02x:%02x.%d: %04x:%04x: class: %x.%x (%s) irq: %d\n",
f010605c:	83 ec 08             	sub    $0x8,%esp
f010605f:	0f b6 7d 9c          	movzbl -0x64(%ebp),%edi
f0106063:	57                   	push   %edi
f0106064:	56                   	push   %esi
f0106065:	c1 e8 10             	shr    $0x10,%eax
f0106068:	0f b6 c0             	movzbl %al,%eax
f010606b:	50                   	push   %eax
f010606c:	51                   	push   %ecx
f010606d:	89 d0                	mov    %edx,%eax
f010606f:	c1 e8 10             	shr    $0x10,%eax
f0106072:	50                   	push   %eax
f0106073:	0f b7 d2             	movzwl %dx,%edx
f0106076:	52                   	push   %edx
f0106077:	ff b5 60 ff ff ff    	pushl  -0xa0(%ebp)
f010607d:	ff b5 5c ff ff ff    	pushl  -0xa4(%ebp)
f0106083:	8b 85 58 ff ff ff    	mov    -0xa8(%ebp),%eax
f0106089:	ff 70 04             	pushl  0x4(%eax)
f010608c:	68 3c 83 10 f0       	push   $0xf010833c
f0106091:	e8 c7 d5 ff ff       	call   f010365d <cprintf>
static int
pci_attach(struct pci_func *f)
{
	return
		pci_attach_match(PCI_CLASS(f->dev_class),
				 PCI_SUBCLASS(f->dev_class),
f0106096:	8b 85 68 ff ff ff    	mov    -0x98(%ebp),%eax

static int
pci_attach(struct pci_func *f)
{
	return
		pci_attach_match(PCI_CLASS(f->dev_class),
f010609c:	83 c4 30             	add    $0x30,%esp
f010609f:	53                   	push   %ebx
f01060a0:	68 f4 23 12 f0       	push   $0xf01223f4
f01060a5:	89 c2                	mov    %eax,%edx
f01060a7:	c1 ea 10             	shr    $0x10,%edx
f01060aa:	0f b6 d2             	movzbl %dl,%edx
f01060ad:	52                   	push   %edx
f01060ae:	c1 e8 18             	shr    $0x18,%eax
f01060b1:	50                   	push   %eax
f01060b2:	e8 6a fd ff ff       	call   f0105e21 <pci_attach_match>
				 PCI_SUBCLASS(f->dev_class),
				 &pci_attach_class[0], f) ||
f01060b7:	83 c4 10             	add    $0x10,%esp
f01060ba:	85 c0                	test   %eax,%eax
f01060bc:	75 1e                	jne    f01060dc <pci_scan_bus+0x182>
		pci_attach_match(PCI_VENDOR(f->dev_id),
				 PCI_PRODUCT(f->dev_id),
f01060be:	8b 85 64 ff ff ff    	mov    -0x9c(%ebp),%eax
{
	return
		pci_attach_match(PCI_CLASS(f->dev_class),
				 PCI_SUBCLASS(f->dev_class),
				 &pci_attach_class[0], f) ||
		pci_attach_match(PCI_VENDOR(f->dev_id),
f01060c4:	53                   	push   %ebx
f01060c5:	68 80 9e 2a f0       	push   $0xf02a9e80
f01060ca:	89 c2                	mov    %eax,%edx
f01060cc:	c1 ea 10             	shr    $0x10,%edx
f01060cf:	52                   	push   %edx
f01060d0:	0f b7 c0             	movzwl %ax,%eax
f01060d3:	50                   	push   %eax
f01060d4:	e8 48 fd ff ff       	call   f0105e21 <pci_attach_match>
f01060d9:	83 c4 10             	add    $0x10,%esp

		totaldev++;

		struct pci_func f = df;
		for (f.func = 0; f.func < (PCI_HDRTYPE_MULTIFN(bhlc) ? 8 : 1);
		     f.func++) {
f01060dc:	83 85 18 ff ff ff 01 	addl   $0x1,-0xe8(%ebp)
			continue;

		totaldev++;

		struct pci_func f = df;
		for (f.func = 0; f.func < (PCI_HDRTYPE_MULTIFN(bhlc) ? 8 : 1);
f01060e3:	8b 85 04 ff ff ff    	mov    -0xfc(%ebp),%eax
f01060e9:	3b 85 18 ff ff ff    	cmp    -0xe8(%ebp),%eax
f01060ef:	0f 87 f7 fe ff ff    	ja     f0105fec <pci_scan_bus+0x92>
	int totaldev = 0;
	struct pci_func df;
	memset(&df, 0, sizeof(df));
	df.bus = bus;

	for (df.dev = 0; df.dev < 32; df.dev++) {
f01060f5:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f01060f8:	83 c0 01             	add    $0x1,%eax
f01060fb:	89 45 a4             	mov    %eax,-0x5c(%ebp)
f01060fe:	83 f8 1f             	cmp    $0x1f,%eax
f0106101:	0f 86 85 fe ff ff    	jbe    f0105f8c <pci_scan_bus+0x32>
			pci_attach(&af);
		}
	}

	return totaldev;
}
f0106107:	8b 85 00 ff ff ff    	mov    -0x100(%ebp),%eax
f010610d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0106110:	5b                   	pop    %ebx
f0106111:	5e                   	pop    %esi
f0106112:	5f                   	pop    %edi
f0106113:	5d                   	pop    %ebp
f0106114:	c3                   	ret    

f0106115 <pci_bridge_attach>:

static int
pci_bridge_attach(struct pci_func *pcif)
{
f0106115:	55                   	push   %ebp
f0106116:	89 e5                	mov    %esp,%ebp
f0106118:	57                   	push   %edi
f0106119:	56                   	push   %esi
f010611a:	53                   	push   %ebx
f010611b:	83 ec 1c             	sub    $0x1c,%esp
f010611e:	8b 5d 08             	mov    0x8(%ebp),%ebx
	uint32_t ioreg  = pci_conf_read(pcif, PCI_BRIDGE_STATIO_REG);
f0106121:	ba 1c 00 00 00       	mov    $0x1c,%edx
f0106126:	89 d8                	mov    %ebx,%eax
f0106128:	e8 08 fe ff ff       	call   f0105f35 <pci_conf_read>
f010612d:	89 c7                	mov    %eax,%edi
	uint32_t busreg = pci_conf_read(pcif, PCI_BRIDGE_BUS_REG);
f010612f:	ba 18 00 00 00       	mov    $0x18,%edx
f0106134:	89 d8                	mov    %ebx,%eax
f0106136:	e8 fa fd ff ff       	call   f0105f35 <pci_conf_read>

	if (PCI_BRIDGE_IO_32BITS(ioreg)) {
f010613b:	83 e7 0f             	and    $0xf,%edi
f010613e:	83 ff 01             	cmp    $0x1,%edi
f0106141:	75 1f                	jne    f0106162 <pci_bridge_attach+0x4d>
		cprintf("PCI: %02x:%02x.%d: 32-bit bridge IO not supported.\n",
f0106143:	ff 73 08             	pushl  0x8(%ebx)
f0106146:	ff 73 04             	pushl  0x4(%ebx)
f0106149:	8b 03                	mov    (%ebx),%eax
f010614b:	ff 70 04             	pushl  0x4(%eax)
f010614e:	68 78 83 10 f0       	push   $0xf0108378
f0106153:	e8 05 d5 ff ff       	call   f010365d <cprintf>
			pcif->bus->busno, pcif->dev, pcif->func);
		return 0;
f0106158:	83 c4 10             	add    $0x10,%esp
f010615b:	b8 00 00 00 00       	mov    $0x0,%eax
f0106160:	eb 4e                	jmp    f01061b0 <pci_bridge_attach+0x9b>
f0106162:	89 c6                	mov    %eax,%esi
	}

	struct pci_bus nbus;
	memset(&nbus, 0, sizeof(nbus));
f0106164:	83 ec 04             	sub    $0x4,%esp
f0106167:	6a 08                	push   $0x8
f0106169:	6a 00                	push   $0x0
f010616b:	8d 7d e0             	lea    -0x20(%ebp),%edi
f010616e:	57                   	push   %edi
f010616f:	e8 95 f2 ff ff       	call   f0105409 <memset>
	nbus.parent_bridge = pcif;
f0106174:	89 5d e0             	mov    %ebx,-0x20(%ebp)
	nbus.busno = (busreg >> PCI_BRIDGE_BUS_SECONDARY_SHIFT) & 0xff;
f0106177:	89 f0                	mov    %esi,%eax
f0106179:	0f b6 c4             	movzbl %ah,%eax
f010617c:	89 45 e4             	mov    %eax,-0x1c(%ebp)

	if (pci_show_devs)
		cprintf("PCI: %02x:%02x.%d: bridge to PCI bus %d--%d\n",
f010617f:	83 c4 08             	add    $0x8,%esp
f0106182:	89 f2                	mov    %esi,%edx
f0106184:	c1 ea 10             	shr    $0x10,%edx
f0106187:	0f b6 f2             	movzbl %dl,%esi
f010618a:	56                   	push   %esi
f010618b:	50                   	push   %eax
f010618c:	ff 73 08             	pushl  0x8(%ebx)
f010618f:	ff 73 04             	pushl  0x4(%ebx)
f0106192:	8b 03                	mov    (%ebx),%eax
f0106194:	ff 70 04             	pushl  0x4(%eax)
f0106197:	68 ac 83 10 f0       	push   $0xf01083ac
f010619c:	e8 bc d4 ff ff       	call   f010365d <cprintf>
			pcif->bus->busno, pcif->dev, pcif->func,
			nbus.busno,
			(busreg >> PCI_BRIDGE_BUS_SUBORDINATE_SHIFT) & 0xff);

	pci_scan_bus(&nbus);
f01061a1:	83 c4 20             	add    $0x20,%esp
f01061a4:	89 f8                	mov    %edi,%eax
f01061a6:	e8 af fd ff ff       	call   f0105f5a <pci_scan_bus>
	return 1;
f01061ab:	b8 01 00 00 00       	mov    $0x1,%eax
}
f01061b0:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01061b3:	5b                   	pop    %ebx
f01061b4:	5e                   	pop    %esi
f01061b5:	5f                   	pop    %edi
f01061b6:	5d                   	pop    %ebp
f01061b7:	c3                   	ret    

f01061b8 <pci_conf_write>:
	return inl(pci_conf1_data_ioport);
}

static void
pci_conf_write(struct pci_func *f, uint32_t off, uint32_t v)
{
f01061b8:	55                   	push   %ebp
f01061b9:	89 e5                	mov    %esp,%ebp
f01061bb:	56                   	push   %esi
f01061bc:	53                   	push   %ebx
f01061bd:	89 cb                	mov    %ecx,%ebx
	pci_conf1_set_addr(f->bus->busno, f->dev, f->func, off);
f01061bf:	8b 48 08             	mov    0x8(%eax),%ecx
f01061c2:	8b 70 04             	mov    0x4(%eax),%esi
f01061c5:	8b 00                	mov    (%eax),%eax
f01061c7:	8b 40 04             	mov    0x4(%eax),%eax
f01061ca:	83 ec 0c             	sub    $0xc,%esp
f01061cd:	52                   	push   %edx
f01061ce:	89 f2                	mov    %esi,%edx
f01061d0:	e8 aa fc ff ff       	call   f0105e7f <pci_conf1_set_addr>
}

static inline void
outl(int port, uint32_t data)
{
	asm volatile("outl %0,%w1" : : "a" (data), "d" (port));
f01061d5:	ba fc 0c 00 00       	mov    $0xcfc,%edx
f01061da:	89 d8                	mov    %ebx,%eax
f01061dc:	ef                   	out    %eax,(%dx)
	outl(pci_conf1_data_ioport, v);
}
f01061dd:	83 c4 10             	add    $0x10,%esp
f01061e0:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01061e3:	5b                   	pop    %ebx
f01061e4:	5e                   	pop    %esi
f01061e5:	5d                   	pop    %ebp
f01061e6:	c3                   	ret    

f01061e7 <pci_func_enable>:

// External PCI subsystem interface

void
pci_func_enable(struct pci_func *f)
{
f01061e7:	55                   	push   %ebp
f01061e8:	89 e5                	mov    %esp,%ebp
f01061ea:	57                   	push   %edi
f01061eb:	56                   	push   %esi
f01061ec:	53                   	push   %ebx
f01061ed:	83 ec 1c             	sub    $0x1c,%esp
f01061f0:	8b 7d 08             	mov    0x8(%ebp),%edi
	pci_conf_write(f, PCI_COMMAND_STATUS_REG,
f01061f3:	b9 07 00 00 00       	mov    $0x7,%ecx
f01061f8:	ba 04 00 00 00       	mov    $0x4,%edx
f01061fd:	89 f8                	mov    %edi,%eax
f01061ff:	e8 b4 ff ff ff       	call   f01061b8 <pci_conf_write>
		       PCI_COMMAND_MEM_ENABLE |
		       PCI_COMMAND_MASTER_ENABLE);

	uint32_t bar_width;
	uint32_t bar;
	for (bar = PCI_MAPREG_START; bar < PCI_MAPREG_END;
f0106204:	be 10 00 00 00       	mov    $0x10,%esi
	     bar += bar_width)
	{
		uint32_t oldv = pci_conf_read(f, bar);
f0106209:	89 f2                	mov    %esi,%edx
f010620b:	89 f8                	mov    %edi,%eax
f010620d:	e8 23 fd ff ff       	call   f0105f35 <pci_conf_read>
f0106212:	89 45 e4             	mov    %eax,-0x1c(%ebp)

		bar_width = 4;
		pci_conf_write(f, bar, 0xffffffff);
f0106215:	b9 ff ff ff ff       	mov    $0xffffffff,%ecx
f010621a:	89 f2                	mov    %esi,%edx
f010621c:	89 f8                	mov    %edi,%eax
f010621e:	e8 95 ff ff ff       	call   f01061b8 <pci_conf_write>
		uint32_t rv = pci_conf_read(f, bar);
f0106223:	89 f2                	mov    %esi,%edx
f0106225:	89 f8                	mov    %edi,%eax
f0106227:	e8 09 fd ff ff       	call   f0105f35 <pci_conf_read>
	for (bar = PCI_MAPREG_START; bar < PCI_MAPREG_END;
	     bar += bar_width)
	{
		uint32_t oldv = pci_conf_read(f, bar);

		bar_width = 4;
f010622c:	bb 04 00 00 00       	mov    $0x4,%ebx
		pci_conf_write(f, bar, 0xffffffff);
		uint32_t rv = pci_conf_read(f, bar);

		if (rv == 0)
f0106231:	85 c0                	test   %eax,%eax
f0106233:	0f 84 a6 00 00 00    	je     f01062df <pci_func_enable+0xf8>
			continue;

		int regnum = PCI_MAPREG_NUM(bar);
f0106239:	8d 56 f0             	lea    -0x10(%esi),%edx
f010623c:	c1 ea 02             	shr    $0x2,%edx
f010623f:	89 55 e0             	mov    %edx,-0x20(%ebp)
		uint32_t base, size;
		if (PCI_MAPREG_TYPE(rv) == PCI_MAPREG_TYPE_MEM) {
f0106242:	a8 01                	test   $0x1,%al
f0106244:	75 2c                	jne    f0106272 <pci_func_enable+0x8b>
			if (PCI_MAPREG_MEM_TYPE(rv) == PCI_MAPREG_MEM_TYPE_64BIT)
f0106246:	89 c2                	mov    %eax,%edx
f0106248:	83 e2 06             	and    $0x6,%edx
				bar_width = 8;
f010624b:	83 fa 04             	cmp    $0x4,%edx
f010624e:	0f 94 c3             	sete   %bl
f0106251:	0f b6 db             	movzbl %bl,%ebx
f0106254:	8d 1c 9d 04 00 00 00 	lea    0x4(,%ebx,4),%ebx

			size = PCI_MAPREG_MEM_SIZE(rv);
f010625b:	83 e0 f0             	and    $0xfffffff0,%eax
f010625e:	89 c2                	mov    %eax,%edx
f0106260:	f7 da                	neg    %edx
f0106262:	21 c2                	and    %eax,%edx
f0106264:	89 55 d8             	mov    %edx,-0x28(%ebp)
			base = PCI_MAPREG_MEM_ADDR(oldv);
f0106267:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010626a:	83 e0 f0             	and    $0xfffffff0,%eax
f010626d:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0106270:	eb 1a                	jmp    f010628c <pci_func_enable+0xa5>
			if (pci_show_addrs)
				cprintf("  mem region %d: %d bytes at 0x%x\n",
					regnum, size, base);
		} else {
			size = PCI_MAPREG_IO_SIZE(rv);
f0106272:	83 e0 fc             	and    $0xfffffffc,%eax
f0106275:	89 c2                	mov    %eax,%edx
f0106277:	f7 da                	neg    %edx
f0106279:	21 c2                	and    %eax,%edx
f010627b:	89 55 d8             	mov    %edx,-0x28(%ebp)
			base = PCI_MAPREG_IO_ADDR(oldv);
f010627e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0106281:	83 e0 fc             	and    $0xfffffffc,%eax
f0106284:	89 45 dc             	mov    %eax,-0x24(%ebp)
	for (bar = PCI_MAPREG_START; bar < PCI_MAPREG_END;
	     bar += bar_width)
	{
		uint32_t oldv = pci_conf_read(f, bar);

		bar_width = 4;
f0106287:	bb 04 00 00 00       	mov    $0x4,%ebx
			if (pci_show_addrs)
				cprintf("  io region %d: %d bytes at 0x%x\n",
					regnum, size, base);
		}

		pci_conf_write(f, bar, oldv);
f010628c:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f010628f:	89 f2                	mov    %esi,%edx
f0106291:	89 f8                	mov    %edi,%eax
f0106293:	e8 20 ff ff ff       	call   f01061b8 <pci_conf_write>
f0106298:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010629b:	8d 04 87             	lea    (%edi,%eax,4),%eax
		f->reg_base[regnum] = base;
f010629e:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01062a1:	89 50 14             	mov    %edx,0x14(%eax)
		f->reg_size[regnum] = size;
f01062a4:	8b 4d d8             	mov    -0x28(%ebp),%ecx
f01062a7:	89 48 2c             	mov    %ecx,0x2c(%eax)

		if (size && !base)
f01062aa:	85 c9                	test   %ecx,%ecx
f01062ac:	74 31                	je     f01062df <pci_func_enable+0xf8>
f01062ae:	85 d2                	test   %edx,%edx
f01062b0:	75 2d                	jne    f01062df <pci_func_enable+0xf8>
			cprintf("PCI device %02x:%02x.%d (%04x:%04x) "
				"may be misconfigured: "
				"region %d: base 0x%x, size %d\n",
				f->bus->busno, f->dev, f->func,
				PCI_VENDOR(f->dev_id), PCI_PRODUCT(f->dev_id),
f01062b2:	8b 47 0c             	mov    0xc(%edi),%eax
		pci_conf_write(f, bar, oldv);
		f->reg_base[regnum] = base;
		f->reg_size[regnum] = size;

		if (size && !base)
			cprintf("PCI device %02x:%02x.%d (%04x:%04x) "
f01062b5:	83 ec 0c             	sub    $0xc,%esp
f01062b8:	51                   	push   %ecx
f01062b9:	52                   	push   %edx
f01062ba:	ff 75 e0             	pushl  -0x20(%ebp)
f01062bd:	89 c2                	mov    %eax,%edx
f01062bf:	c1 ea 10             	shr    $0x10,%edx
f01062c2:	52                   	push   %edx
f01062c3:	0f b7 c0             	movzwl %ax,%eax
f01062c6:	50                   	push   %eax
f01062c7:	ff 77 08             	pushl  0x8(%edi)
f01062ca:	ff 77 04             	pushl  0x4(%edi)
f01062cd:	8b 07                	mov    (%edi),%eax
f01062cf:	ff 70 04             	pushl  0x4(%eax)
f01062d2:	68 dc 83 10 f0       	push   $0xf01083dc
f01062d7:	e8 81 d3 ff ff       	call   f010365d <cprintf>
f01062dc:	83 c4 30             	add    $0x30,%esp
		       PCI_COMMAND_MASTER_ENABLE);

	uint32_t bar_width;
	uint32_t bar;
	for (bar = PCI_MAPREG_START; bar < PCI_MAPREG_END;
	     bar += bar_width)
f01062df:	01 de                	add    %ebx,%esi
		       PCI_COMMAND_MEM_ENABLE |
		       PCI_COMMAND_MASTER_ENABLE);

	uint32_t bar_width;
	uint32_t bar;
	for (bar = PCI_MAPREG_START; bar < PCI_MAPREG_END;
f01062e1:	83 fe 27             	cmp    $0x27,%esi
f01062e4:	0f 86 1f ff ff ff    	jbe    f0106209 <pci_func_enable+0x22>
				regnum, base, size);
	}

	cprintf("PCI function %02x:%02x.%d (%04x:%04x) enabled\n",
		f->bus->busno, f->dev, f->func,
		PCI_VENDOR(f->dev_id), PCI_PRODUCT(f->dev_id));
f01062ea:	8b 47 0c             	mov    0xc(%edi),%eax
				f->bus->busno, f->dev, f->func,
				PCI_VENDOR(f->dev_id), PCI_PRODUCT(f->dev_id),
				regnum, base, size);
	}

	cprintf("PCI function %02x:%02x.%d (%04x:%04x) enabled\n",
f01062ed:	83 ec 08             	sub    $0x8,%esp
f01062f0:	89 c2                	mov    %eax,%edx
f01062f2:	c1 ea 10             	shr    $0x10,%edx
f01062f5:	52                   	push   %edx
f01062f6:	0f b7 c0             	movzwl %ax,%eax
f01062f9:	50                   	push   %eax
f01062fa:	ff 77 08             	pushl  0x8(%edi)
f01062fd:	ff 77 04             	pushl  0x4(%edi)
f0106300:	8b 07                	mov    (%edi),%eax
f0106302:	ff 70 04             	pushl  0x4(%eax)
f0106305:	68 38 84 10 f0       	push   $0xf0108438
f010630a:	e8 4e d3 ff ff       	call   f010365d <cprintf>
		f->bus->busno, f->dev, f->func,
		PCI_VENDOR(f->dev_id), PCI_PRODUCT(f->dev_id));
}
f010630f:	83 c4 20             	add    $0x20,%esp
f0106312:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0106315:	5b                   	pop    %ebx
f0106316:	5e                   	pop    %esi
f0106317:	5f                   	pop    %edi
f0106318:	5d                   	pop    %ebp
f0106319:	c3                   	ret    

f010631a <pci_init>:

int
pci_init(void)
{
f010631a:	55                   	push   %ebp
f010631b:	89 e5                	mov    %esp,%ebp
f010631d:	83 ec 0c             	sub    $0xc,%esp
	static struct pci_bus root_bus;
	memset(&root_bus, 0, sizeof(root_bus));
f0106320:	6a 08                	push   $0x8
f0106322:	6a 00                	push   $0x0
f0106324:	68 8c 9e 2a f0       	push   $0xf02a9e8c
f0106329:	e8 db f0 ff ff       	call   f0105409 <memset>

	return pci_scan_bus(&root_bus);
f010632e:	b8 8c 9e 2a f0       	mov    $0xf02a9e8c,%eax
f0106333:	e8 22 fc ff ff       	call   f0105f5a <pci_scan_bus>
}
f0106338:	c9                   	leave  
f0106339:	c3                   	ret    

f010633a <time_init>:

static unsigned int ticks;

void
time_init(void)
{
f010633a:	55                   	push   %ebp
f010633b:	89 e5                	mov    %esp,%ebp
	ticks = 0;
f010633d:	c7 05 94 9e 2a f0 00 	movl   $0x0,0xf02a9e94
f0106344:	00 00 00 
}
f0106347:	5d                   	pop    %ebp
f0106348:	c3                   	ret    

f0106349 <time_tick>:
// This should be called once per timer interrupt.  A timer interrupt
// fires every 10 ms.
void
time_tick(void)
{
	ticks++;
f0106349:	a1 94 9e 2a f0       	mov    0xf02a9e94,%eax
f010634e:	83 c0 01             	add    $0x1,%eax
f0106351:	a3 94 9e 2a f0       	mov    %eax,0xf02a9e94
	if (ticks * 10 < ticks)
f0106356:	8d 14 80             	lea    (%eax,%eax,4),%edx
f0106359:	01 d2                	add    %edx,%edx
f010635b:	39 d0                	cmp    %edx,%eax
f010635d:	76 17                	jbe    f0106376 <time_tick+0x2d>

// This should be called once per timer interrupt.  A timer interrupt
// fires every 10 ms.
void
time_tick(void)
{
f010635f:	55                   	push   %ebp
f0106360:	89 e5                	mov    %esp,%ebp
f0106362:	83 ec 0c             	sub    $0xc,%esp
	ticks++;
	if (ticks * 10 < ticks)
		panic("time_tick: time overflowed");
f0106365:	68 40 85 10 f0       	push   $0xf0108540
f010636a:	6a 13                	push   $0x13
f010636c:	68 5b 85 10 f0       	push   $0xf010855b
f0106371:	e8 ca 9c ff ff       	call   f0100040 <_panic>
f0106376:	f3 c3                	repz ret 

f0106378 <time_msec>:
}

unsigned int
time_msec(void)
{
f0106378:	55                   	push   %ebp
f0106379:	89 e5                	mov    %esp,%ebp
	return ticks * 10;
f010637b:	a1 94 9e 2a f0       	mov    0xf02a9e94,%eax
f0106380:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0106383:	01 c0                	add    %eax,%eax
}
f0106385:	5d                   	pop    %ebp
f0106386:	c3                   	ret    
f0106387:	66 90                	xchg   %ax,%ax
f0106389:	66 90                	xchg   %ax,%ax
f010638b:	66 90                	xchg   %ax,%ax
f010638d:	66 90                	xchg   %ax,%ax
f010638f:	90                   	nop

f0106390 <__udivdi3>:
f0106390:	55                   	push   %ebp
f0106391:	57                   	push   %edi
f0106392:	56                   	push   %esi
f0106393:	53                   	push   %ebx
f0106394:	83 ec 1c             	sub    $0x1c,%esp
f0106397:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f010639b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f010639f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f01063a3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01063a7:	85 f6                	test   %esi,%esi
f01063a9:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01063ad:	89 ca                	mov    %ecx,%edx
f01063af:	89 f8                	mov    %edi,%eax
f01063b1:	75 3d                	jne    f01063f0 <__udivdi3+0x60>
f01063b3:	39 cf                	cmp    %ecx,%edi
f01063b5:	0f 87 c5 00 00 00    	ja     f0106480 <__udivdi3+0xf0>
f01063bb:	85 ff                	test   %edi,%edi
f01063bd:	89 fd                	mov    %edi,%ebp
f01063bf:	75 0b                	jne    f01063cc <__udivdi3+0x3c>
f01063c1:	b8 01 00 00 00       	mov    $0x1,%eax
f01063c6:	31 d2                	xor    %edx,%edx
f01063c8:	f7 f7                	div    %edi
f01063ca:	89 c5                	mov    %eax,%ebp
f01063cc:	89 c8                	mov    %ecx,%eax
f01063ce:	31 d2                	xor    %edx,%edx
f01063d0:	f7 f5                	div    %ebp
f01063d2:	89 c1                	mov    %eax,%ecx
f01063d4:	89 d8                	mov    %ebx,%eax
f01063d6:	89 cf                	mov    %ecx,%edi
f01063d8:	f7 f5                	div    %ebp
f01063da:	89 c3                	mov    %eax,%ebx
f01063dc:	89 d8                	mov    %ebx,%eax
f01063de:	89 fa                	mov    %edi,%edx
f01063e0:	83 c4 1c             	add    $0x1c,%esp
f01063e3:	5b                   	pop    %ebx
f01063e4:	5e                   	pop    %esi
f01063e5:	5f                   	pop    %edi
f01063e6:	5d                   	pop    %ebp
f01063e7:	c3                   	ret    
f01063e8:	90                   	nop
f01063e9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01063f0:	39 ce                	cmp    %ecx,%esi
f01063f2:	77 74                	ja     f0106468 <__udivdi3+0xd8>
f01063f4:	0f bd fe             	bsr    %esi,%edi
f01063f7:	83 f7 1f             	xor    $0x1f,%edi
f01063fa:	0f 84 98 00 00 00    	je     f0106498 <__udivdi3+0x108>
f0106400:	bb 20 00 00 00       	mov    $0x20,%ebx
f0106405:	89 f9                	mov    %edi,%ecx
f0106407:	89 c5                	mov    %eax,%ebp
f0106409:	29 fb                	sub    %edi,%ebx
f010640b:	d3 e6                	shl    %cl,%esi
f010640d:	89 d9                	mov    %ebx,%ecx
f010640f:	d3 ed                	shr    %cl,%ebp
f0106411:	89 f9                	mov    %edi,%ecx
f0106413:	d3 e0                	shl    %cl,%eax
f0106415:	09 ee                	or     %ebp,%esi
f0106417:	89 d9                	mov    %ebx,%ecx
f0106419:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010641d:	89 d5                	mov    %edx,%ebp
f010641f:	8b 44 24 08          	mov    0x8(%esp),%eax
f0106423:	d3 ed                	shr    %cl,%ebp
f0106425:	89 f9                	mov    %edi,%ecx
f0106427:	d3 e2                	shl    %cl,%edx
f0106429:	89 d9                	mov    %ebx,%ecx
f010642b:	d3 e8                	shr    %cl,%eax
f010642d:	09 c2                	or     %eax,%edx
f010642f:	89 d0                	mov    %edx,%eax
f0106431:	89 ea                	mov    %ebp,%edx
f0106433:	f7 f6                	div    %esi
f0106435:	89 d5                	mov    %edx,%ebp
f0106437:	89 c3                	mov    %eax,%ebx
f0106439:	f7 64 24 0c          	mull   0xc(%esp)
f010643d:	39 d5                	cmp    %edx,%ebp
f010643f:	72 10                	jb     f0106451 <__udivdi3+0xc1>
f0106441:	8b 74 24 08          	mov    0x8(%esp),%esi
f0106445:	89 f9                	mov    %edi,%ecx
f0106447:	d3 e6                	shl    %cl,%esi
f0106449:	39 c6                	cmp    %eax,%esi
f010644b:	73 07                	jae    f0106454 <__udivdi3+0xc4>
f010644d:	39 d5                	cmp    %edx,%ebp
f010644f:	75 03                	jne    f0106454 <__udivdi3+0xc4>
f0106451:	83 eb 01             	sub    $0x1,%ebx
f0106454:	31 ff                	xor    %edi,%edi
f0106456:	89 d8                	mov    %ebx,%eax
f0106458:	89 fa                	mov    %edi,%edx
f010645a:	83 c4 1c             	add    $0x1c,%esp
f010645d:	5b                   	pop    %ebx
f010645e:	5e                   	pop    %esi
f010645f:	5f                   	pop    %edi
f0106460:	5d                   	pop    %ebp
f0106461:	c3                   	ret    
f0106462:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0106468:	31 ff                	xor    %edi,%edi
f010646a:	31 db                	xor    %ebx,%ebx
f010646c:	89 d8                	mov    %ebx,%eax
f010646e:	89 fa                	mov    %edi,%edx
f0106470:	83 c4 1c             	add    $0x1c,%esp
f0106473:	5b                   	pop    %ebx
f0106474:	5e                   	pop    %esi
f0106475:	5f                   	pop    %edi
f0106476:	5d                   	pop    %ebp
f0106477:	c3                   	ret    
f0106478:	90                   	nop
f0106479:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0106480:	89 d8                	mov    %ebx,%eax
f0106482:	f7 f7                	div    %edi
f0106484:	31 ff                	xor    %edi,%edi
f0106486:	89 c3                	mov    %eax,%ebx
f0106488:	89 d8                	mov    %ebx,%eax
f010648a:	89 fa                	mov    %edi,%edx
f010648c:	83 c4 1c             	add    $0x1c,%esp
f010648f:	5b                   	pop    %ebx
f0106490:	5e                   	pop    %esi
f0106491:	5f                   	pop    %edi
f0106492:	5d                   	pop    %ebp
f0106493:	c3                   	ret    
f0106494:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0106498:	39 ce                	cmp    %ecx,%esi
f010649a:	72 0c                	jb     f01064a8 <__udivdi3+0x118>
f010649c:	31 db                	xor    %ebx,%ebx
f010649e:	3b 44 24 08          	cmp    0x8(%esp),%eax
f01064a2:	0f 87 34 ff ff ff    	ja     f01063dc <__udivdi3+0x4c>
f01064a8:	bb 01 00 00 00       	mov    $0x1,%ebx
f01064ad:	e9 2a ff ff ff       	jmp    f01063dc <__udivdi3+0x4c>
f01064b2:	66 90                	xchg   %ax,%ax
f01064b4:	66 90                	xchg   %ax,%ax
f01064b6:	66 90                	xchg   %ax,%ax
f01064b8:	66 90                	xchg   %ax,%ax
f01064ba:	66 90                	xchg   %ax,%ax
f01064bc:	66 90                	xchg   %ax,%ax
f01064be:	66 90                	xchg   %ax,%ax

f01064c0 <__umoddi3>:
f01064c0:	55                   	push   %ebp
f01064c1:	57                   	push   %edi
f01064c2:	56                   	push   %esi
f01064c3:	53                   	push   %ebx
f01064c4:	83 ec 1c             	sub    $0x1c,%esp
f01064c7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f01064cb:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f01064cf:	8b 74 24 34          	mov    0x34(%esp),%esi
f01064d3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01064d7:	85 d2                	test   %edx,%edx
f01064d9:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01064dd:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01064e1:	89 f3                	mov    %esi,%ebx
f01064e3:	89 3c 24             	mov    %edi,(%esp)
f01064e6:	89 74 24 04          	mov    %esi,0x4(%esp)
f01064ea:	75 1c                	jne    f0106508 <__umoddi3+0x48>
f01064ec:	39 f7                	cmp    %esi,%edi
f01064ee:	76 50                	jbe    f0106540 <__umoddi3+0x80>
f01064f0:	89 c8                	mov    %ecx,%eax
f01064f2:	89 f2                	mov    %esi,%edx
f01064f4:	f7 f7                	div    %edi
f01064f6:	89 d0                	mov    %edx,%eax
f01064f8:	31 d2                	xor    %edx,%edx
f01064fa:	83 c4 1c             	add    $0x1c,%esp
f01064fd:	5b                   	pop    %ebx
f01064fe:	5e                   	pop    %esi
f01064ff:	5f                   	pop    %edi
f0106500:	5d                   	pop    %ebp
f0106501:	c3                   	ret    
f0106502:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0106508:	39 f2                	cmp    %esi,%edx
f010650a:	89 d0                	mov    %edx,%eax
f010650c:	77 52                	ja     f0106560 <__umoddi3+0xa0>
f010650e:	0f bd ea             	bsr    %edx,%ebp
f0106511:	83 f5 1f             	xor    $0x1f,%ebp
f0106514:	75 5a                	jne    f0106570 <__umoddi3+0xb0>
f0106516:	3b 54 24 04          	cmp    0x4(%esp),%edx
f010651a:	0f 82 e0 00 00 00    	jb     f0106600 <__umoddi3+0x140>
f0106520:	39 0c 24             	cmp    %ecx,(%esp)
f0106523:	0f 86 d7 00 00 00    	jbe    f0106600 <__umoddi3+0x140>
f0106529:	8b 44 24 08          	mov    0x8(%esp),%eax
f010652d:	8b 54 24 04          	mov    0x4(%esp),%edx
f0106531:	83 c4 1c             	add    $0x1c,%esp
f0106534:	5b                   	pop    %ebx
f0106535:	5e                   	pop    %esi
f0106536:	5f                   	pop    %edi
f0106537:	5d                   	pop    %ebp
f0106538:	c3                   	ret    
f0106539:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0106540:	85 ff                	test   %edi,%edi
f0106542:	89 fd                	mov    %edi,%ebp
f0106544:	75 0b                	jne    f0106551 <__umoddi3+0x91>
f0106546:	b8 01 00 00 00       	mov    $0x1,%eax
f010654b:	31 d2                	xor    %edx,%edx
f010654d:	f7 f7                	div    %edi
f010654f:	89 c5                	mov    %eax,%ebp
f0106551:	89 f0                	mov    %esi,%eax
f0106553:	31 d2                	xor    %edx,%edx
f0106555:	f7 f5                	div    %ebp
f0106557:	89 c8                	mov    %ecx,%eax
f0106559:	f7 f5                	div    %ebp
f010655b:	89 d0                	mov    %edx,%eax
f010655d:	eb 99                	jmp    f01064f8 <__umoddi3+0x38>
f010655f:	90                   	nop
f0106560:	89 c8                	mov    %ecx,%eax
f0106562:	89 f2                	mov    %esi,%edx
f0106564:	83 c4 1c             	add    $0x1c,%esp
f0106567:	5b                   	pop    %ebx
f0106568:	5e                   	pop    %esi
f0106569:	5f                   	pop    %edi
f010656a:	5d                   	pop    %ebp
f010656b:	c3                   	ret    
f010656c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0106570:	8b 34 24             	mov    (%esp),%esi
f0106573:	bf 20 00 00 00       	mov    $0x20,%edi
f0106578:	89 e9                	mov    %ebp,%ecx
f010657a:	29 ef                	sub    %ebp,%edi
f010657c:	d3 e0                	shl    %cl,%eax
f010657e:	89 f9                	mov    %edi,%ecx
f0106580:	89 f2                	mov    %esi,%edx
f0106582:	d3 ea                	shr    %cl,%edx
f0106584:	89 e9                	mov    %ebp,%ecx
f0106586:	09 c2                	or     %eax,%edx
f0106588:	89 d8                	mov    %ebx,%eax
f010658a:	89 14 24             	mov    %edx,(%esp)
f010658d:	89 f2                	mov    %esi,%edx
f010658f:	d3 e2                	shl    %cl,%edx
f0106591:	89 f9                	mov    %edi,%ecx
f0106593:	89 54 24 04          	mov    %edx,0x4(%esp)
f0106597:	8b 54 24 0c          	mov    0xc(%esp),%edx
f010659b:	d3 e8                	shr    %cl,%eax
f010659d:	89 e9                	mov    %ebp,%ecx
f010659f:	89 c6                	mov    %eax,%esi
f01065a1:	d3 e3                	shl    %cl,%ebx
f01065a3:	89 f9                	mov    %edi,%ecx
f01065a5:	89 d0                	mov    %edx,%eax
f01065a7:	d3 e8                	shr    %cl,%eax
f01065a9:	89 e9                	mov    %ebp,%ecx
f01065ab:	09 d8                	or     %ebx,%eax
f01065ad:	89 d3                	mov    %edx,%ebx
f01065af:	89 f2                	mov    %esi,%edx
f01065b1:	f7 34 24             	divl   (%esp)
f01065b4:	89 d6                	mov    %edx,%esi
f01065b6:	d3 e3                	shl    %cl,%ebx
f01065b8:	f7 64 24 04          	mull   0x4(%esp)
f01065bc:	39 d6                	cmp    %edx,%esi
f01065be:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01065c2:	89 d1                	mov    %edx,%ecx
f01065c4:	89 c3                	mov    %eax,%ebx
f01065c6:	72 08                	jb     f01065d0 <__umoddi3+0x110>
f01065c8:	75 11                	jne    f01065db <__umoddi3+0x11b>
f01065ca:	39 44 24 08          	cmp    %eax,0x8(%esp)
f01065ce:	73 0b                	jae    f01065db <__umoddi3+0x11b>
f01065d0:	2b 44 24 04          	sub    0x4(%esp),%eax
f01065d4:	1b 14 24             	sbb    (%esp),%edx
f01065d7:	89 d1                	mov    %edx,%ecx
f01065d9:	89 c3                	mov    %eax,%ebx
f01065db:	8b 54 24 08          	mov    0x8(%esp),%edx
f01065df:	29 da                	sub    %ebx,%edx
f01065e1:	19 ce                	sbb    %ecx,%esi
f01065e3:	89 f9                	mov    %edi,%ecx
f01065e5:	89 f0                	mov    %esi,%eax
f01065e7:	d3 e0                	shl    %cl,%eax
f01065e9:	89 e9                	mov    %ebp,%ecx
f01065eb:	d3 ea                	shr    %cl,%edx
f01065ed:	89 e9                	mov    %ebp,%ecx
f01065ef:	d3 ee                	shr    %cl,%esi
f01065f1:	09 d0                	or     %edx,%eax
f01065f3:	89 f2                	mov    %esi,%edx
f01065f5:	83 c4 1c             	add    $0x1c,%esp
f01065f8:	5b                   	pop    %ebx
f01065f9:	5e                   	pop    %esi
f01065fa:	5f                   	pop    %edi
f01065fb:	5d                   	pop    %ebp
f01065fc:	c3                   	ret    
f01065fd:	8d 76 00             	lea    0x0(%esi),%esi
f0106600:	29 f9                	sub    %edi,%ecx
f0106602:	19 d6                	sbb    %edx,%esi
f0106604:	89 74 24 04          	mov    %esi,0x4(%esp)
f0106608:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010660c:	e9 18 ff ff ff       	jmp    f0106529 <__umoddi3+0x69>
