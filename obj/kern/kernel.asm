
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
f0100015:	b8 00 d0 11 00       	mov    $0x11d000,%eax
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
f0100034:	bc 00 d0 11 f0       	mov    $0xf011d000,%esp

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
f0100048:	83 3d 80 ae 22 f0 00 	cmpl   $0x0,0xf022ae80
f010004f:	75 3a                	jne    f010008b <_panic+0x4b>
		goto dead;
	panicstr = fmt;
f0100051:	89 35 80 ae 22 f0    	mov    %esi,0xf022ae80

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f0100057:	fa                   	cli    
f0100058:	fc                   	cld    

	va_start(ap, fmt);
f0100059:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic on CPU %d at %s:%d: ", cpunum(), file, line);
f010005c:	e8 75 57 00 00       	call   f01057d6 <cpunum>
f0100061:	ff 75 0c             	pushl  0xc(%ebp)
f0100064:	ff 75 08             	pushl  0x8(%ebp)
f0100067:	50                   	push   %eax
f0100068:	68 60 5e 10 f0       	push   $0xf0105e60
f010006d:	e8 e5 35 00 00       	call   f0103657 <cprintf>
	vcprintf(fmt, ap);
f0100072:	83 c4 08             	add    $0x8,%esp
f0100075:	53                   	push   %ebx
f0100076:	56                   	push   %esi
f0100077:	e8 b5 35 00 00       	call   f0103631 <vcprintf>
	cprintf("\n");
f010007c:	c7 04 24 44 70 10 f0 	movl   $0xf0107044,(%esp)
f0100083:	e8 cf 35 00 00       	call   f0103657 <cprintf>
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
f01000a1:	b8 08 c0 26 f0       	mov    $0xf026c008,%eax
f01000a6:	2d 98 95 22 f0       	sub    $0xf0229598,%eax
f01000ab:	50                   	push   %eax
f01000ac:	6a 00                	push   $0x0
f01000ae:	68 98 95 22 f0       	push   $0xf0229598
f01000b3:	e8 fb 50 00 00       	call   f01051b3 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000b8:	e8 82 05 00 00       	call   f010063f <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000bd:	83 c4 08             	add    $0x8,%esp
f01000c0:	68 ac 1a 00 00       	push   $0x1aac
f01000c5:	68 cc 5e 10 f0       	push   $0xf0105ecc
f01000ca:	e8 88 35 00 00       	call   f0103657 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f01000cf:	e8 13 12 00 00       	call   f01012e7 <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f01000d4:	e8 ee 2d 00 00       	call   f0102ec7 <env_init>
	trap_init();
f01000d9:	e8 5a 36 00 00       	call   f0103738 <trap_init>

	// Lab 4 multiprocessor initialization functions
	mp_init();
f01000de:	e8 e9 53 00 00       	call   f01054cc <mp_init>
	lapic_init();
f01000e3:	e8 09 57 00 00       	call   f01057f1 <lapic_init>

	// Lab 4 multitasking initialization functions
	pic_init();
f01000e8:	e8 91 34 00 00       	call   f010357e <pic_init>
extern struct spinlock kernel_lock;

static inline void
lock_kernel(void)
{
	spin_lock(&kernel_lock);
f01000ed:	c7 04 24 c0 f3 11 f0 	movl   $0xf011f3c0,(%esp)
f01000f4:	e8 4b 59 00 00       	call   f0105a44 <spin_lock>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01000f9:	83 c4 10             	add    $0x10,%esp
f01000fc:	83 3d 88 ae 22 f0 07 	cmpl   $0x7,0xf022ae88
f0100103:	77 16                	ja     f010011b <i386_init+0x81>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100105:	68 00 70 00 00       	push   $0x7000
f010010a:	68 84 5e 10 f0       	push   $0xf0105e84
f010010f:	6a 56                	push   $0x56
f0100111:	68 e7 5e 10 f0       	push   $0xf0105ee7
f0100116:	e8 25 ff ff ff       	call   f0100040 <_panic>
	void *code;
	struct CpuInfo *c;

	// Write entry code to unused memory at MPENTRY_PADDR
	code = KADDR(MPENTRY_PADDR);
	memmove(code, mpentry_start, mpentry_end - mpentry_start);
f010011b:	83 ec 04             	sub    $0x4,%esp
f010011e:	b8 32 54 10 f0       	mov    $0xf0105432,%eax
f0100123:	2d b8 53 10 f0       	sub    $0xf01053b8,%eax
f0100128:	50                   	push   %eax
f0100129:	68 b8 53 10 f0       	push   $0xf01053b8
f010012e:	68 00 70 00 f0       	push   $0xf0007000
f0100133:	e8 c8 50 00 00       	call   f0105200 <memmove>
f0100138:	83 c4 10             	add    $0x10,%esp

	// Boot each AP one at a time
	for (c = cpus; c < cpus + ncpu; c++) {
f010013b:	bb 20 b0 22 f0       	mov    $0xf022b020,%ebx
f0100140:	eb 4d                	jmp    f010018f <i386_init+0xf5>
		if (c == cpus + cpunum())  // We've started already.
f0100142:	e8 8f 56 00 00       	call   f01057d6 <cpunum>
f0100147:	6b c0 74             	imul   $0x74,%eax,%eax
f010014a:	05 20 b0 22 f0       	add    $0xf022b020,%eax
f010014f:	39 c3                	cmp    %eax,%ebx
f0100151:	74 39                	je     f010018c <i386_init+0xf2>
			continue;

		// Tell mpentry.S what stack to use 
		mpentry_kstack = percpu_kstacks[c - cpus] + KSTKSIZE;
f0100153:	89 d8                	mov    %ebx,%eax
f0100155:	2d 20 b0 22 f0       	sub    $0xf022b020,%eax
f010015a:	c1 f8 02             	sar    $0x2,%eax
f010015d:	69 c0 35 c2 72 4f    	imul   $0x4f72c235,%eax,%eax
f0100163:	c1 e0 0f             	shl    $0xf,%eax
f0100166:	05 00 40 23 f0       	add    $0xf0234000,%eax
f010016b:	a3 84 ae 22 f0       	mov    %eax,0xf022ae84
		// Start the CPU at mpentry_start
		lapic_startap(c->cpu_id, PADDR(code));
f0100170:	83 ec 08             	sub    $0x8,%esp
f0100173:	68 00 70 00 00       	push   $0x7000
f0100178:	0f b6 03             	movzbl (%ebx),%eax
f010017b:	50                   	push   %eax
f010017c:	e8 be 57 00 00       	call   f010593f <lapic_startap>
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
f010018f:	6b 05 c4 b3 22 f0 74 	imul   $0x74,0xf022b3c4,%eax
f0100196:	05 20 b0 22 f0       	add    $0xf022b020,%eax
f010019b:	39 c3                	cmp    %eax,%ebx
f010019d:	72 a3                	jb     f0100142 <i386_init+0xa8>
	// Starting non-boot CPUs
	boot_aps();

#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
f010019f:	83 ec 08             	sub    $0x8,%esp
f01001a2:	6a 00                	push   $0x0
f01001a4:	68 58 99 1b f0       	push   $0xf01b9958
f01001a9:	e8 eb 2e 00 00       	call   f0103099 <env_create>
	ENV_CREATE(user_yield, ENV_TYPE_USER);
	ENV_CREATE(user_yield, ENV_TYPE_USER);
#endif // TEST*

	// Schedule and run the first user environment!
	sched_yield();
f01001ae:	e8 e4 3f 00 00       	call   f0104197 <sched_yield>

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
f01001b9:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01001be:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01001c3:	77 12                	ja     f01001d7 <mp_main+0x24>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01001c5:	50                   	push   %eax
f01001c6:	68 a8 5e 10 f0       	push   $0xf0105ea8
f01001cb:	6a 6d                	push   $0x6d
f01001cd:	68 e7 5e 10 f0       	push   $0xf0105ee7
f01001d2:	e8 69 fe ff ff       	call   f0100040 <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f01001d7:	05 00 00 00 10       	add    $0x10000000,%eax
f01001dc:	0f 22 d8             	mov    %eax,%cr3
	cprintf("SMP: CPU %d starting\n", cpunum());
f01001df:	e8 f2 55 00 00       	call   f01057d6 <cpunum>
f01001e4:	83 ec 08             	sub    $0x8,%esp
f01001e7:	50                   	push   %eax
f01001e8:	68 f3 5e 10 f0       	push   $0xf0105ef3
f01001ed:	e8 65 34 00 00       	call   f0103657 <cprintf>

	lapic_init();
f01001f2:	e8 fa 55 00 00       	call   f01057f1 <lapic_init>
	env_init_percpu();
f01001f7:	e8 9b 2c 00 00       	call   f0102e97 <env_init_percpu>
	trap_init_percpu();
f01001fc:	e8 6a 34 00 00       	call   f010366b <trap_init_percpu>
	xchg(&thiscpu->cpu_status, CPU_STARTED); // tell boot_aps() we're up
f0100201:	e8 d0 55 00 00       	call   f01057d6 <cpunum>
f0100206:	6b d0 74             	imul   $0x74,%eax,%edx
f0100209:	81 c2 20 b0 22 f0    	add    $0xf022b020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"
f010020f:	b8 01 00 00 00       	mov    $0x1,%eax
f0100214:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
f0100218:	c7 04 24 c0 f3 11 f0 	movl   $0xf011f3c0,(%esp)
f010021f:	e8 20 58 00 00       	call   f0105a44 <spin_lock>
	// only one CPU can enter the scheduler at a time!
	//
	// Your code here:

    lock_kernel();
    sched_yield();
f0100224:	e8 6e 3f 00 00       	call   f0104197 <sched_yield>

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
f0100239:	68 09 5f 10 f0       	push   $0xf0105f09
f010023e:	e8 14 34 00 00       	call   f0103657 <cprintf>
	vcprintf(fmt, ap);
f0100243:	83 c4 08             	add    $0x8,%esp
f0100246:	53                   	push   %ebx
f0100247:	ff 75 10             	pushl  0x10(%ebp)
f010024a:	e8 e2 33 00 00       	call   f0103631 <vcprintf>
	cprintf("\n");
f010024f:	c7 04 24 44 70 10 f0 	movl   $0xf0107044,(%esp)
f0100256:	e8 fc 33 00 00       	call   f0103657 <cprintf>
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
f0100291:	8b 0d 24 a2 22 f0    	mov    0xf022a224,%ecx
f0100297:	8d 51 01             	lea    0x1(%ecx),%edx
f010029a:	89 15 24 a2 22 f0    	mov    %edx,0xf022a224
f01002a0:	88 81 20 a0 22 f0    	mov    %al,-0xfdd5fe0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f01002a6:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01002ac:	75 0a                	jne    f01002b8 <cons_intr+0x36>
			cons.wpos = 0;
f01002ae:	c7 05 24 a2 22 f0 00 	movl   $0x0,0xf022a224
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
f01002e7:	83 0d 00 a0 22 f0 40 	orl    $0x40,0xf022a000
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
f01002ff:	8b 0d 00 a0 22 f0    	mov    0xf022a000,%ecx
f0100305:	89 cb                	mov    %ecx,%ebx
f0100307:	83 e3 40             	and    $0x40,%ebx
f010030a:	83 e0 7f             	and    $0x7f,%eax
f010030d:	85 db                	test   %ebx,%ebx
f010030f:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100312:	0f b6 d2             	movzbl %dl,%edx
f0100315:	0f b6 82 80 60 10 f0 	movzbl -0xfef9f80(%edx),%eax
f010031c:	83 c8 40             	or     $0x40,%eax
f010031f:	0f b6 c0             	movzbl %al,%eax
f0100322:	f7 d0                	not    %eax
f0100324:	21 c8                	and    %ecx,%eax
f0100326:	a3 00 a0 22 f0       	mov    %eax,0xf022a000
		return 0;
f010032b:	b8 00 00 00 00       	mov    $0x0,%eax
f0100330:	e9 a4 00 00 00       	jmp    f01003d9 <kbd_proc_data+0x114>
	} else if (shift & E0ESC) {
f0100335:	8b 0d 00 a0 22 f0    	mov    0xf022a000,%ecx
f010033b:	f6 c1 40             	test   $0x40,%cl
f010033e:	74 0e                	je     f010034e <kbd_proc_data+0x89>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100340:	83 c8 80             	or     $0xffffff80,%eax
f0100343:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100345:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100348:	89 0d 00 a0 22 f0    	mov    %ecx,0xf022a000
	}

	shift |= shiftcode[data];
f010034e:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f0100351:	0f b6 82 80 60 10 f0 	movzbl -0xfef9f80(%edx),%eax
f0100358:	0b 05 00 a0 22 f0    	or     0xf022a000,%eax
f010035e:	0f b6 8a 80 5f 10 f0 	movzbl -0xfefa080(%edx),%ecx
f0100365:	31 c8                	xor    %ecx,%eax
f0100367:	a3 00 a0 22 f0       	mov    %eax,0xf022a000

	c = charcode[shift & (CTL | SHIFT)][data];
f010036c:	89 c1                	mov    %eax,%ecx
f010036e:	83 e1 03             	and    $0x3,%ecx
f0100371:	8b 0c 8d 60 5f 10 f0 	mov    -0xfefa0a0(,%ecx,4),%ecx
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
f01003af:	68 23 5f 10 f0       	push   $0xf0105f23
f01003b4:	e8 9e 32 00 00       	call   f0103657 <cprintf>
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
f010049b:	0f b7 05 28 a2 22 f0 	movzwl 0xf022a228,%eax
f01004a2:	66 85 c0             	test   %ax,%ax
f01004a5:	0f 84 e6 00 00 00    	je     f0100591 <cons_putc+0x1b3>
			crt_pos--;
f01004ab:	83 e8 01             	sub    $0x1,%eax
f01004ae:	66 a3 28 a2 22 f0    	mov    %ax,0xf022a228
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01004b4:	0f b7 c0             	movzwl %ax,%eax
f01004b7:	66 81 e7 00 ff       	and    $0xff00,%di
f01004bc:	83 cf 20             	or     $0x20,%edi
f01004bf:	8b 15 2c a2 22 f0    	mov    0xf022a22c,%edx
f01004c5:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01004c9:	eb 78                	jmp    f0100543 <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01004cb:	66 83 05 28 a2 22 f0 	addw   $0x50,0xf022a228
f01004d2:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01004d3:	0f b7 05 28 a2 22 f0 	movzwl 0xf022a228,%eax
f01004da:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01004e0:	c1 e8 16             	shr    $0x16,%eax
f01004e3:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01004e6:	c1 e0 04             	shl    $0x4,%eax
f01004e9:	66 a3 28 a2 22 f0    	mov    %ax,0xf022a228
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
f0100525:	0f b7 05 28 a2 22 f0 	movzwl 0xf022a228,%eax
f010052c:	8d 50 01             	lea    0x1(%eax),%edx
f010052f:	66 89 15 28 a2 22 f0 	mov    %dx,0xf022a228
f0100536:	0f b7 c0             	movzwl %ax,%eax
f0100539:	8b 15 2c a2 22 f0    	mov    0xf022a22c,%edx
f010053f:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100543:	66 81 3d 28 a2 22 f0 	cmpw   $0x7cf,0xf022a228
f010054a:	cf 07 
f010054c:	76 43                	jbe    f0100591 <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010054e:	a1 2c a2 22 f0       	mov    0xf022a22c,%eax
f0100553:	83 ec 04             	sub    $0x4,%esp
f0100556:	68 00 0f 00 00       	push   $0xf00
f010055b:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100561:	52                   	push   %edx
f0100562:	50                   	push   %eax
f0100563:	e8 98 4c 00 00       	call   f0105200 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100568:	8b 15 2c a2 22 f0    	mov    0xf022a22c,%edx
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
f0100589:	66 83 2d 28 a2 22 f0 	subw   $0x50,0xf022a228
f0100590:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100591:	8b 0d 30 a2 22 f0    	mov    0xf022a230,%ecx
f0100597:	b8 0e 00 00 00       	mov    $0xe,%eax
f010059c:	89 ca                	mov    %ecx,%edx
f010059e:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010059f:	0f b7 1d 28 a2 22 f0 	movzwl 0xf022a228,%ebx
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
f01005c7:	80 3d 34 a2 22 f0 00 	cmpb   $0x0,0xf022a234
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
f0100605:	a1 20 a2 22 f0       	mov    0xf022a220,%eax
f010060a:	3b 05 24 a2 22 f0    	cmp    0xf022a224,%eax
f0100610:	74 26                	je     f0100638 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f0100612:	8d 50 01             	lea    0x1(%eax),%edx
f0100615:	89 15 20 a2 22 f0    	mov    %edx,0xf022a220
f010061b:	0f b6 88 20 a0 22 f0 	movzbl -0xfdd5fe0(%eax),%ecx
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
f010062c:	c7 05 20 a2 22 f0 00 	movl   $0x0,0xf022a220
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
f0100665:	c7 05 30 a2 22 f0 b4 	movl   $0x3b4,0xf022a230
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
f010067d:	c7 05 30 a2 22 f0 d4 	movl   $0x3d4,0xf022a230
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
f010068c:	8b 3d 30 a2 22 f0    	mov    0xf022a230,%edi
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
f01006b1:	89 35 2c a2 22 f0    	mov    %esi,0xf022a22c
	crt_pos = pos;
f01006b7:	0f b6 c0             	movzbl %al,%eax
f01006ba:	09 c8                	or     %ecx,%eax
f01006bc:	66 a3 28 a2 22 f0    	mov    %ax,0xf022a228

static void
kbd_init(void)
{
	// Drain the kbd buffer so that QEMU generates interrupts.
	kbd_intr();
f01006c2:	e8 1c ff ff ff       	call   f01005e3 <kbd_intr>
	irq_setmask_8259A(irq_mask_8259A & ~(1<<IRQ_KBD));
f01006c7:	83 ec 0c             	sub    $0xc,%esp
f01006ca:	0f b7 05 a8 f3 11 f0 	movzwl 0xf011f3a8,%eax
f01006d1:	25 fd ff 00 00       	and    $0xfffd,%eax
f01006d6:	50                   	push   %eax
f01006d7:	e8 2a 2e 00 00       	call   f0103506 <irq_setmask_8259A>
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
f010073a:	0f 95 05 34 a2 22 f0 	setne  0xf022a234
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
f010074f:	68 2f 5f 10 f0       	push   $0xf0105f2f
f0100754:	e8 fe 2e 00 00       	call   f0103657 <cprintf>
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
f0100795:	68 80 61 10 f0       	push   $0xf0106180
f010079a:	68 9e 61 10 f0       	push   $0xf010619e
f010079f:	68 a3 61 10 f0       	push   $0xf01061a3
f01007a4:	e8 ae 2e 00 00       	call   f0103657 <cprintf>
f01007a9:	83 c4 0c             	add    $0xc,%esp
f01007ac:	68 2c 62 10 f0       	push   $0xf010622c
f01007b1:	68 ac 61 10 f0       	push   $0xf01061ac
f01007b6:	68 a3 61 10 f0       	push   $0xf01061a3
f01007bb:	e8 97 2e 00 00       	call   f0103657 <cprintf>
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
f01007cd:	68 b5 61 10 f0       	push   $0xf01061b5
f01007d2:	e8 80 2e 00 00       	call   f0103657 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01007d7:	83 c4 08             	add    $0x8,%esp
f01007da:	68 0c 00 10 00       	push   $0x10000c
f01007df:	68 54 62 10 f0       	push   $0xf0106254
f01007e4:	e8 6e 2e 00 00       	call   f0103657 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01007e9:	83 c4 0c             	add    $0xc,%esp
f01007ec:	68 0c 00 10 00       	push   $0x10000c
f01007f1:	68 0c 00 10 f0       	push   $0xf010000c
f01007f6:	68 7c 62 10 f0       	push   $0xf010627c
f01007fb:	e8 57 2e 00 00       	call   f0103657 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100800:	83 c4 0c             	add    $0xc,%esp
f0100803:	68 51 5e 10 00       	push   $0x105e51
f0100808:	68 51 5e 10 f0       	push   $0xf0105e51
f010080d:	68 a0 62 10 f0       	push   $0xf01062a0
f0100812:	e8 40 2e 00 00       	call   f0103657 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f0100817:	83 c4 0c             	add    $0xc,%esp
f010081a:	68 98 95 22 00       	push   $0x229598
f010081f:	68 98 95 22 f0       	push   $0xf0229598
f0100824:	68 c4 62 10 f0       	push   $0xf01062c4
f0100829:	e8 29 2e 00 00       	call   f0103657 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010082e:	83 c4 0c             	add    $0xc,%esp
f0100831:	68 08 c0 26 00       	push   $0x26c008
f0100836:	68 08 c0 26 f0       	push   $0xf026c008
f010083b:	68 e8 62 10 f0       	push   $0xf01062e8
f0100840:	e8 12 2e 00 00       	call   f0103657 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f0100845:	b8 07 c4 26 f0       	mov    $0xf026c407,%eax
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
f0100866:	68 0c 63 10 f0       	push   $0xf010630c
f010086b:	e8 e7 2d 00 00       	call   f0103657 <cprintf>
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
f0100881:	68 ce 61 10 f0       	push   $0xf01061ce
f0100886:	e8 cc 2d 00 00       	call   f0103657 <cprintf>
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
f01008a6:	68 38 63 10 f0       	push   $0xf0106338
f01008ab:	e8 a7 2d 00 00       	call   f0103657 <cprintf>
				*((uintptr_t *)ebp + 1), *((uintptr_t *)ebp + 2), *((uintptr_t *)ebp + 3), 
			    *((uintptr_t *)ebp + 4), *((uintptr_t *)ebp + 5), *((uintptr_t *)ebp + 6));
		debuginfo_eip(*((uintptr_t *)ebp + 1), &info);
f01008b0:	83 c4 18             	add    $0x18,%esp
f01008b3:	56                   	push   %esi
f01008b4:	ff 73 04             	pushl  0x4(%ebx)
f01008b7:	e8 47 3e 00 00       	call   f0104703 <debuginfo_eip>
		cprintf("%s:%d: %.*s+%d\n", info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, 
f01008bc:	83 c4 08             	add    $0x8,%esp
f01008bf:	8b 43 04             	mov    0x4(%ebx),%eax
f01008c2:	2b 45 f0             	sub    -0x10(%ebp),%eax
f01008c5:	50                   	push   %eax
f01008c6:	ff 75 e8             	pushl  -0x18(%ebp)
f01008c9:	ff 75 ec             	pushl  -0x14(%ebp)
f01008cc:	ff 75 e4             	pushl  -0x1c(%ebp)
f01008cf:	ff 75 e0             	pushl  -0x20(%ebp)
f01008d2:	68 e0 61 10 f0       	push   $0xf01061e0
f01008d7:	e8 7b 2d 00 00       	call   f0103657 <cprintf>
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
f01008fa:	68 70 63 10 f0       	push   $0xf0106370
f01008ff:	e8 53 2d 00 00       	call   f0103657 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100904:	c7 04 24 94 63 10 f0 	movl   $0xf0106394,(%esp)
f010090b:	e8 47 2d 00 00       	call   f0103657 <cprintf>

	if (tf != NULL)
f0100910:	83 c4 10             	add    $0x10,%esp
f0100913:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f0100917:	74 0e                	je     f0100927 <monitor+0x36>
		print_trapframe(tf);
f0100919:	83 ec 0c             	sub    $0xc,%esp
f010091c:	ff 75 08             	pushl  0x8(%ebp)
f010091f:	e8 e2 32 00 00       	call   f0103c06 <print_trapframe>
f0100924:	83 c4 10             	add    $0x10,%esp

	while (1) {
		buf = readline("K> ");
f0100927:	83 ec 0c             	sub    $0xc,%esp
f010092a:	68 f0 61 10 f0       	push   $0xf01061f0
f010092f:	e8 28 46 00 00       	call   f0104f5c <readline>
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
f0100963:	68 f4 61 10 f0       	push   $0xf01061f4
f0100968:	e8 09 48 00 00       	call   f0105176 <strchr>
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
f0100983:	68 f9 61 10 f0       	push   $0xf01061f9
f0100988:	e8 ca 2c 00 00       	call   f0103657 <cprintf>
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
f01009ac:	68 f4 61 10 f0       	push   $0xf01061f4
f01009b1:	e8 c0 47 00 00       	call   f0105176 <strchr>
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
f01009d2:	68 9e 61 10 f0       	push   $0xf010619e
f01009d7:	ff 75 a8             	pushl  -0x58(%ebp)
f01009da:	e8 39 47 00 00       	call   f0105118 <strcmp>
f01009df:	83 c4 10             	add    $0x10,%esp
f01009e2:	85 c0                	test   %eax,%eax
f01009e4:	74 1e                	je     f0100a04 <monitor+0x113>
f01009e6:	83 ec 08             	sub    $0x8,%esp
f01009e9:	68 ac 61 10 f0       	push   $0xf01061ac
f01009ee:	ff 75 a8             	pushl  -0x58(%ebp)
f01009f1:	e8 22 47 00 00       	call   f0105118 <strcmp>
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
f0100a19:	ff 14 85 c4 63 10 f0 	call   *-0xfef9c3c(,%eax,4)
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
f0100a32:	68 16 62 10 f0       	push   $0xf0106216
f0100a37:	e8 1b 2c 00 00       	call   f0103657 <cprintf>
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
f0100a57:	e8 7c 2a 00 00       	call   f01034d8 <mc146818_read>
f0100a5c:	89 c6                	mov    %eax,%esi
f0100a5e:	83 c3 01             	add    $0x1,%ebx
f0100a61:	89 1c 24             	mov    %ebx,(%esp)
f0100a64:	e8 6f 2a 00 00       	call   f01034d8 <mc146818_read>
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
f0100a8b:	3b 0d 88 ae 22 f0    	cmp    0xf022ae88,%ecx
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
f0100a9a:	68 84 5e 10 f0       	push   $0xf0105e84
f0100a9f:	68 85 03 00 00       	push   $0x385
f0100aa4:	68 55 6d 10 f0       	push   $0xf0106d55
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
f0100adb:	83 3d 38 a2 22 f0 00 	cmpl   $0x0,0xf022a238
f0100ae2:	75 0f                	jne    f0100af3 <boot_alloc+0x1a>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100ae4:	b8 07 d0 26 f0       	mov    $0xf026d007,%eax
f0100ae9:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100aee:	a3 38 a2 22 f0       	mov    %eax,0xf022a238
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	result = nextfree;
f0100af3:	a1 38 a2 22 f0       	mov    0xf022a238,%eax
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
f0100b0b:	68 a8 5e 10 f0       	push   $0xf0105ea8
f0100b10:	6a 6e                	push   $0x6e
f0100b12:	68 55 6d 10 f0       	push   $0xf0106d55
f0100b17:	e8 24 f5 ff ff       	call   f0100040 <_panic>
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	result = nextfree;
	if(n > 0){
		if (PADDR(nextfree) + n > (npages + 1) * PGSIZE) {
f0100b1c:	8d 9c 10 00 00 00 10 	lea    0x10000000(%eax,%edx,1),%ebx
f0100b23:	8b 0d 88 ae 22 f0    	mov    0xf022ae88,%ecx
f0100b29:	83 c1 01             	add    $0x1,%ecx
f0100b2c:	c1 e1 0c             	shl    $0xc,%ecx
f0100b2f:	39 cb                	cmp    %ecx,%ebx
f0100b31:	76 14                	jbe    f0100b47 <boot_alloc+0x6e>
			panic("out of memory\n");
f0100b33:	83 ec 04             	sub    $0x4,%esp
f0100b36:	68 61 6d 10 f0       	push   $0xf0106d61
f0100b3b:	6a 6f                	push   $0x6f
f0100b3d:	68 55 6d 10 f0       	push   $0xf0106d55
f0100b42:	e8 f9 f4 ff ff       	call   f0100040 <_panic>
		}
		nextfree = ROUNDUP((char *)nextfree + n, PGSIZE);
f0100b47:	8d 94 10 ff 0f 00 00 	lea    0xfff(%eax,%edx,1),%edx
f0100b4e:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100b54:	89 15 38 a2 22 f0    	mov    %edx,0xf022a238
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
f0100b79:	68 d4 63 10 f0       	push   $0xf01063d4
f0100b7e:	68 b8 02 00 00       	push   $0x2b8
f0100b83:	68 55 6d 10 f0       	push   $0xf0106d55
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
f0100b9b:	2b 15 90 ae 22 f0    	sub    0xf022ae90,%edx
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
f0100bd1:	a3 40 a2 22 f0       	mov    %eax,0xf022a240
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
f0100bdb:	8b 1d 40 a2 22 f0    	mov    0xf022a240,%ebx
f0100be1:	eb 53                	jmp    f0100c36 <check_page_free_list+0xd6>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100be3:	89 d8                	mov    %ebx,%eax
f0100be5:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
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
f0100bff:	3b 15 88 ae 22 f0    	cmp    0xf022ae88,%edx
f0100c05:	72 12                	jb     f0100c19 <check_page_free_list+0xb9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100c07:	50                   	push   %eax
f0100c08:	68 84 5e 10 f0       	push   $0xf0105e84
f0100c0d:	6a 58                	push   $0x58
f0100c0f:	68 70 6d 10 f0       	push   $0xf0106d70
f0100c14:	e8 27 f4 ff ff       	call   f0100040 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100c19:	83 ec 04             	sub    $0x4,%esp
f0100c1c:	68 80 00 00 00       	push   $0x80
f0100c21:	68 97 00 00 00       	push   $0x97
f0100c26:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100c2b:	50                   	push   %eax
f0100c2c:	e8 82 45 00 00       	call   f01051b3 <memset>
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
f0100c47:	8b 15 40 a2 22 f0    	mov    0xf022a240,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100c4d:	8b 0d 90 ae 22 f0    	mov    0xf022ae90,%ecx
		assert(pp < pages + npages);
f0100c53:	a1 88 ae 22 f0       	mov    0xf022ae88,%eax
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
f0100c72:	68 7e 6d 10 f0       	push   $0xf0106d7e
f0100c77:	68 8a 6d 10 f0       	push   $0xf0106d8a
f0100c7c:	68 d2 02 00 00       	push   $0x2d2
f0100c81:	68 55 6d 10 f0       	push   $0xf0106d55
f0100c86:	e8 b5 f3 ff ff       	call   f0100040 <_panic>
		assert(pp < pages + npages);
f0100c8b:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100c8e:	72 19                	jb     f0100ca9 <check_page_free_list+0x149>
f0100c90:	68 9f 6d 10 f0       	push   $0xf0106d9f
f0100c95:	68 8a 6d 10 f0       	push   $0xf0106d8a
f0100c9a:	68 d3 02 00 00       	push   $0x2d3
f0100c9f:	68 55 6d 10 f0       	push   $0xf0106d55
f0100ca4:	e8 97 f3 ff ff       	call   f0100040 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100ca9:	89 d0                	mov    %edx,%eax
f0100cab:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0100cae:	a8 07                	test   $0x7,%al
f0100cb0:	74 19                	je     f0100ccb <check_page_free_list+0x16b>
f0100cb2:	68 f8 63 10 f0       	push   $0xf01063f8
f0100cb7:	68 8a 6d 10 f0       	push   $0xf0106d8a
f0100cbc:	68 d4 02 00 00       	push   $0x2d4
f0100cc1:	68 55 6d 10 f0       	push   $0xf0106d55
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
f0100cd5:	68 b3 6d 10 f0       	push   $0xf0106db3
f0100cda:	68 8a 6d 10 f0       	push   $0xf0106d8a
f0100cdf:	68 d7 02 00 00       	push   $0x2d7
f0100ce4:	68 55 6d 10 f0       	push   $0xf0106d55
f0100ce9:	e8 52 f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100cee:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100cf3:	75 19                	jne    f0100d0e <check_page_free_list+0x1ae>
f0100cf5:	68 c4 6d 10 f0       	push   $0xf0106dc4
f0100cfa:	68 8a 6d 10 f0       	push   $0xf0106d8a
f0100cff:	68 d8 02 00 00       	push   $0x2d8
f0100d04:	68 55 6d 10 f0       	push   $0xf0106d55
f0100d09:	e8 32 f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100d0e:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100d13:	75 19                	jne    f0100d2e <check_page_free_list+0x1ce>
f0100d15:	68 2c 64 10 f0       	push   $0xf010642c
f0100d1a:	68 8a 6d 10 f0       	push   $0xf0106d8a
f0100d1f:	68 d9 02 00 00       	push   $0x2d9
f0100d24:	68 55 6d 10 f0       	push   $0xf0106d55
f0100d29:	e8 12 f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100d2e:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100d33:	75 19                	jne    f0100d4e <check_page_free_list+0x1ee>
f0100d35:	68 dd 6d 10 f0       	push   $0xf0106ddd
f0100d3a:	68 8a 6d 10 f0       	push   $0xf0106d8a
f0100d3f:	68 da 02 00 00       	push   $0x2da
f0100d44:	68 55 6d 10 f0       	push   $0xf0106d55
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
f0100d64:	68 84 5e 10 f0       	push   $0xf0105e84
f0100d69:	6a 58                	push   $0x58
f0100d6b:	68 70 6d 10 f0       	push   $0xf0106d70
f0100d70:	e8 cb f2 ff ff       	call   f0100040 <_panic>
f0100d75:	8d b8 00 00 00 f0    	lea    -0x10000000(%eax),%edi
f0100d7b:	39 7d cc             	cmp    %edi,-0x34(%ebp)
f0100d7e:	0f 86 b6 00 00 00    	jbe    f0100e3a <check_page_free_list+0x2da>
f0100d84:	68 50 64 10 f0       	push   $0xf0106450
f0100d89:	68 8a 6d 10 f0       	push   $0xf0106d8a
f0100d8e:	68 db 02 00 00       	push   $0x2db
f0100d93:	68 55 6d 10 f0       	push   $0xf0106d55
f0100d98:	e8 a3 f2 ff ff       	call   f0100040 <_panic>
		// (new test for lab 4)
		assert(page2pa(pp) != MPENTRY_PADDR);
f0100d9d:	68 f7 6d 10 f0       	push   $0xf0106df7
f0100da2:	68 8a 6d 10 f0       	push   $0xf0106d8a
f0100da7:	68 dd 02 00 00       	push   $0x2dd
f0100dac:	68 55 6d 10 f0       	push   $0xf0106d55
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
f0100dcc:	68 14 6e 10 f0       	push   $0xf0106e14
f0100dd1:	68 8a 6d 10 f0       	push   $0xf0106d8a
f0100dd6:	68 e5 02 00 00       	push   $0x2e5
f0100ddb:	68 55 6d 10 f0       	push   $0xf0106d55
f0100de0:	e8 5b f2 ff ff       	call   f0100040 <_panic>
	assert(nfree_extmem > 0);
f0100de5:	85 db                	test   %ebx,%ebx
f0100de7:	7f 19                	jg     f0100e02 <check_page_free_list+0x2a2>
f0100de9:	68 26 6e 10 f0       	push   $0xf0106e26
f0100dee:	68 8a 6d 10 f0       	push   $0xf0106d8a
f0100df3:	68 e6 02 00 00       	push   $0x2e6
f0100df8:	68 55 6d 10 f0       	push   $0xf0106d55
f0100dfd:	e8 3e f2 ff ff       	call   f0100040 <_panic>

	cprintf("check_page_free_list() succeeded!\n");
f0100e02:	83 ec 0c             	sub    $0xc,%esp
f0100e05:	68 98 64 10 f0       	push   $0xf0106498
f0100e0a:	e8 48 28 00 00       	call   f0103657 <cprintf>
}
f0100e0f:	eb 49                	jmp    f0100e5a <check_page_free_list+0x2fa>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100e11:	a1 40 a2 22 f0       	mov    0xf022a240,%eax
f0100e16:	85 c0                	test   %eax,%eax
f0100e18:	0f 85 6f fd ff ff    	jne    f0100b8d <check_page_free_list+0x2d>
f0100e1e:	e9 53 fd ff ff       	jmp    f0100b76 <check_page_free_list+0x16>
f0100e23:	83 3d 40 a2 22 f0 00 	cmpl   $0x0,0xf022a240
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
f0100e69:	8b 1d 40 a2 22 f0    	mov    0xf022a240,%ebx
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
f0100e84:	03 0d 90 ae 22 f0    	add    0xf022ae90,%ecx
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
f0100e97:	03 1d 90 ae 22 f0    	add    0xf022ae90,%ebx
f0100e9d:	ba 01 00 00 00       	mov    $0x1,%edx
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	
	size_t i, io_page_i, ext_page_i, free_top, mpentry_i;
	for (i = 0; i < npages; i++) {
f0100ea2:	3b 05 88 ae 22 f0    	cmp    0xf022ae88,%eax
f0100ea8:	72 d1                	jb     f0100e7b <page_init+0x19>
f0100eaa:	84 d2                	test   %dl,%dl
f0100eac:	74 06                	je     f0100eb4 <page_init+0x52>
f0100eae:	89 1d 40 a2 22 f0    	mov    %ebx,0xf022a240
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
  
	pages[0].pp_link = NULL;
f0100eb4:	a1 90 ae 22 f0       	mov    0xf022ae90,%eax
f0100eb9:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pages[1].pp_link = NULL;
f0100ebf:	a1 90 ae 22 f0       	mov    0xf022ae90,%eax
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
f0100edd:	68 a8 5e 10 f0       	push   $0xf0105ea8
f0100ee2:	68 4c 01 00 00       	push   $0x14c
f0100ee7:	68 55 6d 10 f0       	push   $0xf0106d55
f0100eec:	e8 4f f1 ff ff       	call   f0100040 <_panic>
f0100ef1:	8d 88 00 00 00 10    	lea    0x10000000(%eax),%ecx
f0100ef7:	c1 e9 0c             	shr    $0xc,%ecx

	pages[ext_page_i].pp_link = pages[io_page_i].pp_link;
f0100efa:	a1 90 ae 22 f0       	mov    0xf022ae90,%eax
f0100eff:	8b 90 00 05 00 00    	mov    0x500(%eax),%edx
f0100f05:	89 90 00 08 00 00    	mov    %edx,0x800(%eax)
f0100f0b:	b8 00 05 00 00       	mov    $0x500,%eax
	for(i = io_page_i;i < ext_page_i;i++)
		pages[i].pp_link = NULL;
f0100f10:	8b 15 90 ae 22 f0    	mov    0xf022ae90,%edx
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
f0100f27:	a1 90 ae 22 f0       	mov    0xf022ae90,%eax
f0100f2c:	8b 90 00 08 00 00    	mov    0x800(%eax),%edx
f0100f32:	89 14 c8             	mov    %edx,(%eax,%ecx,8)
	for (i = ext_page_i; i < free_top; i++)
f0100f35:	b8 00 01 00 00       	mov    $0x100,%eax
f0100f3a:	eb 10                	jmp    f0100f4c <page_init+0xea>
		pages[i].pp_link = NULL;
f0100f3c:	8b 15 90 ae 22 f0    	mov    0xf022ae90,%edx
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
f0100f50:	a1 90 ae 22 f0       	mov    0xf022ae90,%eax
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
f0100f6e:	8b 1d 40 a2 22 f0    	mov    0xf022a240,%ebx
	if(p){
f0100f74:	85 db                	test   %ebx,%ebx
f0100f76:	74 5c                	je     f0100fd4 <page_alloc+0x6d>
		page_free_list = p->pp_link;
f0100f78:	8b 03                	mov    (%ebx),%eax
f0100f7a:	a3 40 a2 22 f0       	mov    %eax,0xf022a240
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
f0100f8d:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f0100f93:	c1 f8 03             	sar    $0x3,%eax
f0100f96:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100f99:	89 c2                	mov    %eax,%edx
f0100f9b:	c1 ea 0c             	shr    $0xc,%edx
f0100f9e:	3b 15 88 ae 22 f0    	cmp    0xf022ae88,%edx
f0100fa4:	72 12                	jb     f0100fb8 <page_alloc+0x51>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100fa6:	50                   	push   %eax
f0100fa7:	68 84 5e 10 f0       	push   $0xf0105e84
f0100fac:	6a 58                	push   $0x58
f0100fae:	68 70 6d 10 f0       	push   $0xf0106d70
f0100fb3:	e8 88 f0 ff ff       	call   f0100040 <_panic>
			memset(page2kva(p), 0, PGSIZE);
f0100fb8:	83 ec 04             	sub    $0x4,%esp
f0100fbb:	68 00 10 00 00       	push   $0x1000
f0100fc0:	6a 00                	push   $0x0
f0100fc2:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100fc7:	50                   	push   %eax
f0100fc8:	e8 e6 41 00 00       	call   f01051b3 <memset>
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
f0100ff6:	68 bc 64 10 f0       	push   $0xf01064bc
f0100ffb:	68 82 01 00 00       	push   $0x182
f0101000:	68 55 6d 10 f0       	push   $0xf0106d55
f0101005:	e8 36 f0 ff ff       	call   f0100040 <_panic>
	}
	pp->pp_link = page_free_list;
f010100a:	8b 15 40 a2 22 f0    	mov    0xf022a240,%edx
f0101010:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f0101012:	a3 40 a2 22 f0       	mov    %eax,0xf022a240


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
f0101071:	2b 15 90 ae 22 f0    	sub    0xf022ae90,%edx
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
f0101093:	3b 15 88 ae 22 f0    	cmp    0xf022ae88,%edx
f0101099:	72 15                	jb     f01010b0 <pgdir_walk+0x70>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010109b:	50                   	push   %eax
f010109c:	68 84 5e 10 f0       	push   $0xf0105e84
f01010a1:	68 b9 01 00 00       	push   $0x1b9
f01010a6:	68 55 6d 10 f0       	push   $0xf0106d55
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
f0101160:	3b 05 88 ae 22 f0    	cmp    0xf022ae88,%eax
f0101166:	72 14                	jb     f010117c <page_lookup+0x45>
		panic("pa2page called with invalid pa");
f0101168:	83 ec 04             	sub    $0x4,%esp
f010116b:	68 f0 64 10 f0       	push   $0xf01064f0
f0101170:	6a 51                	push   $0x51
f0101172:	68 70 6d 10 f0       	push   $0xf0106d70
f0101177:	e8 c4 ee ff ff       	call   f0100040 <_panic>
	return &pages[PGNUM(pa)];
f010117c:	8b 15 90 ae 22 f0    	mov    0xf022ae90,%edx
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
f0101197:	e8 3a 46 00 00       	call   f01057d6 <cpunum>
f010119c:	6b c0 74             	imul   $0x74,%eax,%eax
f010119f:	83 b8 28 b0 22 f0 00 	cmpl   $0x0,-0xfdd4fd8(%eax)
f01011a6:	74 16                	je     f01011be <tlb_invalidate+0x2d>
f01011a8:	e8 29 46 00 00       	call   f01057d6 <cpunum>
f01011ad:	6b c0 74             	imul   $0x74,%eax,%eax
f01011b0:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
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
f010124b:	2b 1d 90 ae 22 f0    	sub    0xf022ae90,%ebx
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
f010129a:	8b 15 00 f3 11 f0    	mov    0xf011f300,%edx
f01012a0:	8d 04 13             	lea    (%ebx,%edx,1),%eax
f01012a3:	3d 00 00 c0 ef       	cmp    $0xefc00000,%eax
f01012a8:	76 17                	jbe    f01012c1 <mmio_map_region+0x3d>
        panic("mmio_map_region: reservation mem overflow");
f01012aa:	83 ec 04             	sub    $0x4,%esp
f01012ad:	68 10 65 10 f0       	push   $0xf0106510
f01012b2:	68 62 02 00 00       	push   $0x262
f01012b7:	68 55 6d 10 f0       	push   $0xf0106d55
f01012bc:	e8 7f ed ff ff       	call   f0100040 <_panic>
    }
    boot_map_region(kern_pgdir, base, size, pa, PTE_W | PTE_PCD | PTE_P);
f01012c1:	83 ec 08             	sub    $0x8,%esp
f01012c4:	6a 13                	push   $0x13
f01012c6:	ff 75 08             	pushl  0x8(%ebp)
f01012c9:	89 d9                	mov    %ebx,%ecx
f01012cb:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f01012d0:	e8 00 fe ff ff       	call   f01010d5 <boot_map_region>
    uintptr_t b = base;
f01012d5:	a1 00 f3 11 f0       	mov    0xf011f300,%eax
    base += size;
f01012da:	01 c3                	add    %eax,%ebx
f01012dc:	89 1d 00 f3 11 f0    	mov    %ebx,0xf011f300
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
f0101330:	89 15 88 ae 22 f0    	mov    %edx,0xf022ae88
	npages_basemem = basemem / (PGSIZE / 1024);

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101336:	89 c2                	mov    %eax,%edx
f0101338:	29 da                	sub    %ebx,%edx
f010133a:	52                   	push   %edx
f010133b:	53                   	push   %ebx
f010133c:	50                   	push   %eax
f010133d:	68 3c 65 10 f0       	push   $0xf010653c
f0101342:	e8 10 23 00 00       	call   f0103657 <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0101347:	b8 00 10 00 00       	mov    $0x1000,%eax
f010134c:	e8 88 f7 ff ff       	call   f0100ad9 <boot_alloc>
f0101351:	a3 8c ae 22 f0       	mov    %eax,0xf022ae8c
	memset(kern_pgdir, 0, PGSIZE);
f0101356:	83 c4 0c             	add    $0xc,%esp
f0101359:	68 00 10 00 00       	push   $0x1000
f010135e:	6a 00                	push   $0x0
f0101360:	50                   	push   %eax
f0101361:	e8 4d 3e 00 00       	call   f01051b3 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0101366:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
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
f0101376:	68 a8 5e 10 f0       	push   $0xf0105ea8
f010137b:	68 96 00 00 00       	push   $0x96
f0101380:	68 55 6d 10 f0       	push   $0xf0106d55
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
f0101399:	a1 88 ae 22 f0       	mov    0xf022ae88,%eax
f010139e:	c1 e0 03             	shl    $0x3,%eax
f01013a1:	e8 33 f7 ff ff       	call   f0100ad9 <boot_alloc>
f01013a6:	a3 90 ae 22 f0       	mov    %eax,0xf022ae90
	memset(pages, 0, npages * sizeof(struct PageInfo));
f01013ab:	83 ec 04             	sub    $0x4,%esp
f01013ae:	8b 0d 88 ae 22 f0    	mov    0xf022ae88,%ecx
f01013b4:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f01013bb:	52                   	push   %edx
f01013bc:	6a 00                	push   $0x0
f01013be:	50                   	push   %eax
f01013bf:	e8 ef 3d 00 00       	call   f01051b3 <memset>

	//////////////////////////////////////////////////////////////////////
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.
	envs = (struct Env *) boot_alloc(NENV * sizeof(struct Env));
f01013c4:	b8 00 f0 01 00       	mov    $0x1f000,%eax
f01013c9:	e8 0b f7 ff ff       	call   f0100ad9 <boot_alloc>
f01013ce:	a3 44 a2 22 f0       	mov    %eax,0xf022a244
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
f01013e5:	83 3d 90 ae 22 f0 00 	cmpl   $0x0,0xf022ae90
f01013ec:	75 17                	jne    f0101405 <mem_init+0x11e>
		panic("'pages' is a null pointer!");
f01013ee:	83 ec 04             	sub    $0x4,%esp
f01013f1:	68 37 6e 10 f0       	push   $0xf0106e37
f01013f6:	68 f9 02 00 00       	push   $0x2f9
f01013fb:	68 55 6d 10 f0       	push   $0xf0106d55
f0101400:	e8 3b ec ff ff       	call   f0100040 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101405:	a1 40 a2 22 f0       	mov    0xf022a240,%eax
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
f010142d:	68 52 6e 10 f0       	push   $0xf0106e52
f0101432:	68 8a 6d 10 f0       	push   $0xf0106d8a
f0101437:	68 01 03 00 00       	push   $0x301
f010143c:	68 55 6d 10 f0       	push   $0xf0106d55
f0101441:	e8 fa eb ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0101446:	83 ec 0c             	sub    $0xc,%esp
f0101449:	6a 00                	push   $0x0
f010144b:	e8 17 fb ff ff       	call   f0100f67 <page_alloc>
f0101450:	89 c6                	mov    %eax,%esi
f0101452:	83 c4 10             	add    $0x10,%esp
f0101455:	85 c0                	test   %eax,%eax
f0101457:	75 19                	jne    f0101472 <mem_init+0x18b>
f0101459:	68 68 6e 10 f0       	push   $0xf0106e68
f010145e:	68 8a 6d 10 f0       	push   $0xf0106d8a
f0101463:	68 02 03 00 00       	push   $0x302
f0101468:	68 55 6d 10 f0       	push   $0xf0106d55
f010146d:	e8 ce eb ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0101472:	83 ec 0c             	sub    $0xc,%esp
f0101475:	6a 00                	push   $0x0
f0101477:	e8 eb fa ff ff       	call   f0100f67 <page_alloc>
f010147c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010147f:	83 c4 10             	add    $0x10,%esp
f0101482:	85 c0                	test   %eax,%eax
f0101484:	75 19                	jne    f010149f <mem_init+0x1b8>
f0101486:	68 7e 6e 10 f0       	push   $0xf0106e7e
f010148b:	68 8a 6d 10 f0       	push   $0xf0106d8a
f0101490:	68 03 03 00 00       	push   $0x303
f0101495:	68 55 6d 10 f0       	push   $0xf0106d55
f010149a:	e8 a1 eb ff ff       	call   f0100040 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010149f:	39 f7                	cmp    %esi,%edi
f01014a1:	75 19                	jne    f01014bc <mem_init+0x1d5>
f01014a3:	68 94 6e 10 f0       	push   $0xf0106e94
f01014a8:	68 8a 6d 10 f0       	push   $0xf0106d8a
f01014ad:	68 06 03 00 00       	push   $0x306
f01014b2:	68 55 6d 10 f0       	push   $0xf0106d55
f01014b7:	e8 84 eb ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01014bc:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01014bf:	39 c6                	cmp    %eax,%esi
f01014c1:	74 04                	je     f01014c7 <mem_init+0x1e0>
f01014c3:	39 c7                	cmp    %eax,%edi
f01014c5:	75 19                	jne    f01014e0 <mem_init+0x1f9>
f01014c7:	68 78 65 10 f0       	push   $0xf0106578
f01014cc:	68 8a 6d 10 f0       	push   $0xf0106d8a
f01014d1:	68 07 03 00 00       	push   $0x307
f01014d6:	68 55 6d 10 f0       	push   $0xf0106d55
f01014db:	e8 60 eb ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01014e0:	8b 0d 90 ae 22 f0    	mov    0xf022ae90,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f01014e6:	8b 15 88 ae 22 f0    	mov    0xf022ae88,%edx
f01014ec:	c1 e2 0c             	shl    $0xc,%edx
f01014ef:	89 f8                	mov    %edi,%eax
f01014f1:	29 c8                	sub    %ecx,%eax
f01014f3:	c1 f8 03             	sar    $0x3,%eax
f01014f6:	c1 e0 0c             	shl    $0xc,%eax
f01014f9:	39 d0                	cmp    %edx,%eax
f01014fb:	72 19                	jb     f0101516 <mem_init+0x22f>
f01014fd:	68 a6 6e 10 f0       	push   $0xf0106ea6
f0101502:	68 8a 6d 10 f0       	push   $0xf0106d8a
f0101507:	68 08 03 00 00       	push   $0x308
f010150c:	68 55 6d 10 f0       	push   $0xf0106d55
f0101511:	e8 2a eb ff ff       	call   f0100040 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f0101516:	89 f0                	mov    %esi,%eax
f0101518:	29 c8                	sub    %ecx,%eax
f010151a:	c1 f8 03             	sar    $0x3,%eax
f010151d:	c1 e0 0c             	shl    $0xc,%eax
f0101520:	39 c2                	cmp    %eax,%edx
f0101522:	77 19                	ja     f010153d <mem_init+0x256>
f0101524:	68 c3 6e 10 f0       	push   $0xf0106ec3
f0101529:	68 8a 6d 10 f0       	push   $0xf0106d8a
f010152e:	68 09 03 00 00       	push   $0x309
f0101533:	68 55 6d 10 f0       	push   $0xf0106d55
f0101538:	e8 03 eb ff ff       	call   f0100040 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f010153d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101540:	29 c8                	sub    %ecx,%eax
f0101542:	c1 f8 03             	sar    $0x3,%eax
f0101545:	c1 e0 0c             	shl    $0xc,%eax
f0101548:	39 c2                	cmp    %eax,%edx
f010154a:	77 19                	ja     f0101565 <mem_init+0x27e>
f010154c:	68 e0 6e 10 f0       	push   $0xf0106ee0
f0101551:	68 8a 6d 10 f0       	push   $0xf0106d8a
f0101556:	68 0a 03 00 00       	push   $0x30a
f010155b:	68 55 6d 10 f0       	push   $0xf0106d55
f0101560:	e8 db ea ff ff       	call   f0100040 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101565:	a1 40 a2 22 f0       	mov    0xf022a240,%eax
f010156a:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f010156d:	c7 05 40 a2 22 f0 00 	movl   $0x0,0xf022a240
f0101574:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101577:	83 ec 0c             	sub    $0xc,%esp
f010157a:	6a 00                	push   $0x0
f010157c:	e8 e6 f9 ff ff       	call   f0100f67 <page_alloc>
f0101581:	83 c4 10             	add    $0x10,%esp
f0101584:	85 c0                	test   %eax,%eax
f0101586:	74 19                	je     f01015a1 <mem_init+0x2ba>
f0101588:	68 fd 6e 10 f0       	push   $0xf0106efd
f010158d:	68 8a 6d 10 f0       	push   $0xf0106d8a
f0101592:	68 11 03 00 00       	push   $0x311
f0101597:	68 55 6d 10 f0       	push   $0xf0106d55
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
f01015d2:	68 52 6e 10 f0       	push   $0xf0106e52
f01015d7:	68 8a 6d 10 f0       	push   $0xf0106d8a
f01015dc:	68 18 03 00 00       	push   $0x318
f01015e1:	68 55 6d 10 f0       	push   $0xf0106d55
f01015e6:	e8 55 ea ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f01015eb:	83 ec 0c             	sub    $0xc,%esp
f01015ee:	6a 00                	push   $0x0
f01015f0:	e8 72 f9 ff ff       	call   f0100f67 <page_alloc>
f01015f5:	89 c7                	mov    %eax,%edi
f01015f7:	83 c4 10             	add    $0x10,%esp
f01015fa:	85 c0                	test   %eax,%eax
f01015fc:	75 19                	jne    f0101617 <mem_init+0x330>
f01015fe:	68 68 6e 10 f0       	push   $0xf0106e68
f0101603:	68 8a 6d 10 f0       	push   $0xf0106d8a
f0101608:	68 19 03 00 00       	push   $0x319
f010160d:	68 55 6d 10 f0       	push   $0xf0106d55
f0101612:	e8 29 ea ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0101617:	83 ec 0c             	sub    $0xc,%esp
f010161a:	6a 00                	push   $0x0
f010161c:	e8 46 f9 ff ff       	call   f0100f67 <page_alloc>
f0101621:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101624:	83 c4 10             	add    $0x10,%esp
f0101627:	85 c0                	test   %eax,%eax
f0101629:	75 19                	jne    f0101644 <mem_init+0x35d>
f010162b:	68 7e 6e 10 f0       	push   $0xf0106e7e
f0101630:	68 8a 6d 10 f0       	push   $0xf0106d8a
f0101635:	68 1a 03 00 00       	push   $0x31a
f010163a:	68 55 6d 10 f0       	push   $0xf0106d55
f010163f:	e8 fc e9 ff ff       	call   f0100040 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101644:	39 fe                	cmp    %edi,%esi
f0101646:	75 19                	jne    f0101661 <mem_init+0x37a>
f0101648:	68 94 6e 10 f0       	push   $0xf0106e94
f010164d:	68 8a 6d 10 f0       	push   $0xf0106d8a
f0101652:	68 1c 03 00 00       	push   $0x31c
f0101657:	68 55 6d 10 f0       	push   $0xf0106d55
f010165c:	e8 df e9 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101661:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101664:	39 c7                	cmp    %eax,%edi
f0101666:	74 04                	je     f010166c <mem_init+0x385>
f0101668:	39 c6                	cmp    %eax,%esi
f010166a:	75 19                	jne    f0101685 <mem_init+0x39e>
f010166c:	68 78 65 10 f0       	push   $0xf0106578
f0101671:	68 8a 6d 10 f0       	push   $0xf0106d8a
f0101676:	68 1d 03 00 00       	push   $0x31d
f010167b:	68 55 6d 10 f0       	push   $0xf0106d55
f0101680:	e8 bb e9 ff ff       	call   f0100040 <_panic>
	assert(!page_alloc(0));
f0101685:	83 ec 0c             	sub    $0xc,%esp
f0101688:	6a 00                	push   $0x0
f010168a:	e8 d8 f8 ff ff       	call   f0100f67 <page_alloc>
f010168f:	83 c4 10             	add    $0x10,%esp
f0101692:	85 c0                	test   %eax,%eax
f0101694:	74 19                	je     f01016af <mem_init+0x3c8>
f0101696:	68 fd 6e 10 f0       	push   $0xf0106efd
f010169b:	68 8a 6d 10 f0       	push   $0xf0106d8a
f01016a0:	68 1e 03 00 00       	push   $0x31e
f01016a5:	68 55 6d 10 f0       	push   $0xf0106d55
f01016aa:	e8 91 e9 ff ff       	call   f0100040 <_panic>
f01016af:	89 f0                	mov    %esi,%eax
f01016b1:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f01016b7:	c1 f8 03             	sar    $0x3,%eax
f01016ba:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01016bd:	89 c2                	mov    %eax,%edx
f01016bf:	c1 ea 0c             	shr    $0xc,%edx
f01016c2:	3b 15 88 ae 22 f0    	cmp    0xf022ae88,%edx
f01016c8:	72 12                	jb     f01016dc <mem_init+0x3f5>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01016ca:	50                   	push   %eax
f01016cb:	68 84 5e 10 f0       	push   $0xf0105e84
f01016d0:	6a 58                	push   $0x58
f01016d2:	68 70 6d 10 f0       	push   $0xf0106d70
f01016d7:	e8 64 e9 ff ff       	call   f0100040 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f01016dc:	83 ec 04             	sub    $0x4,%esp
f01016df:	68 00 10 00 00       	push   $0x1000
f01016e4:	6a 01                	push   $0x1
f01016e6:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01016eb:	50                   	push   %eax
f01016ec:	e8 c2 3a 00 00       	call   f01051b3 <memset>
	page_free(pp0);
f01016f1:	89 34 24             	mov    %esi,(%esp)
f01016f4:	e8 e5 f8 ff ff       	call   f0100fde <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01016f9:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101700:	e8 62 f8 ff ff       	call   f0100f67 <page_alloc>
f0101705:	83 c4 10             	add    $0x10,%esp
f0101708:	85 c0                	test   %eax,%eax
f010170a:	75 19                	jne    f0101725 <mem_init+0x43e>
f010170c:	68 0c 6f 10 f0       	push   $0xf0106f0c
f0101711:	68 8a 6d 10 f0       	push   $0xf0106d8a
f0101716:	68 23 03 00 00       	push   $0x323
f010171b:	68 55 6d 10 f0       	push   $0xf0106d55
f0101720:	e8 1b e9 ff ff       	call   f0100040 <_panic>
	assert(pp && pp0 == pp);
f0101725:	39 c6                	cmp    %eax,%esi
f0101727:	74 19                	je     f0101742 <mem_init+0x45b>
f0101729:	68 2a 6f 10 f0       	push   $0xf0106f2a
f010172e:	68 8a 6d 10 f0       	push   $0xf0106d8a
f0101733:	68 24 03 00 00       	push   $0x324
f0101738:	68 55 6d 10 f0       	push   $0xf0106d55
f010173d:	e8 fe e8 ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101742:	89 f0                	mov    %esi,%eax
f0101744:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f010174a:	c1 f8 03             	sar    $0x3,%eax
f010174d:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101750:	89 c2                	mov    %eax,%edx
f0101752:	c1 ea 0c             	shr    $0xc,%edx
f0101755:	3b 15 88 ae 22 f0    	cmp    0xf022ae88,%edx
f010175b:	72 12                	jb     f010176f <mem_init+0x488>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010175d:	50                   	push   %eax
f010175e:	68 84 5e 10 f0       	push   $0xf0105e84
f0101763:	6a 58                	push   $0x58
f0101765:	68 70 6d 10 f0       	push   $0xf0106d70
f010176a:	e8 d1 e8 ff ff       	call   f0100040 <_panic>
f010176f:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f0101775:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f010177b:	80 38 00             	cmpb   $0x0,(%eax)
f010177e:	74 19                	je     f0101799 <mem_init+0x4b2>
f0101780:	68 3a 6f 10 f0       	push   $0xf0106f3a
f0101785:	68 8a 6d 10 f0       	push   $0xf0106d8a
f010178a:	68 27 03 00 00       	push   $0x327
f010178f:	68 55 6d 10 f0       	push   $0xf0106d55
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
f01017a3:	a3 40 a2 22 f0       	mov    %eax,0xf022a240

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
f01017c4:	a1 40 a2 22 f0       	mov    0xf022a240,%eax
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
f01017db:	68 44 6f 10 f0       	push   $0xf0106f44
f01017e0:	68 8a 6d 10 f0       	push   $0xf0106d8a
f01017e5:	68 34 03 00 00       	push   $0x334
f01017ea:	68 55 6d 10 f0       	push   $0xf0106d55
f01017ef:	e8 4c e8 ff ff       	call   f0100040 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f01017f4:	83 ec 0c             	sub    $0xc,%esp
f01017f7:	68 98 65 10 f0       	push   $0xf0106598
f01017fc:	e8 56 1e 00 00       	call   f0103657 <cprintf>
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
f0101817:	68 52 6e 10 f0       	push   $0xf0106e52
f010181c:	68 8a 6d 10 f0       	push   $0xf0106d8a
f0101821:	68 9a 03 00 00       	push   $0x39a
f0101826:	68 55 6d 10 f0       	push   $0xf0106d55
f010182b:	e8 10 e8 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0101830:	83 ec 0c             	sub    $0xc,%esp
f0101833:	6a 00                	push   $0x0
f0101835:	e8 2d f7 ff ff       	call   f0100f67 <page_alloc>
f010183a:	89 c3                	mov    %eax,%ebx
f010183c:	83 c4 10             	add    $0x10,%esp
f010183f:	85 c0                	test   %eax,%eax
f0101841:	75 19                	jne    f010185c <mem_init+0x575>
f0101843:	68 68 6e 10 f0       	push   $0xf0106e68
f0101848:	68 8a 6d 10 f0       	push   $0xf0106d8a
f010184d:	68 9b 03 00 00       	push   $0x39b
f0101852:	68 55 6d 10 f0       	push   $0xf0106d55
f0101857:	e8 e4 e7 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f010185c:	83 ec 0c             	sub    $0xc,%esp
f010185f:	6a 00                	push   $0x0
f0101861:	e8 01 f7 ff ff       	call   f0100f67 <page_alloc>
f0101866:	89 c6                	mov    %eax,%esi
f0101868:	83 c4 10             	add    $0x10,%esp
f010186b:	85 c0                	test   %eax,%eax
f010186d:	75 19                	jne    f0101888 <mem_init+0x5a1>
f010186f:	68 7e 6e 10 f0       	push   $0xf0106e7e
f0101874:	68 8a 6d 10 f0       	push   $0xf0106d8a
f0101879:	68 9c 03 00 00       	push   $0x39c
f010187e:	68 55 6d 10 f0       	push   $0xf0106d55
f0101883:	e8 b8 e7 ff ff       	call   f0100040 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101888:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f010188b:	75 19                	jne    f01018a6 <mem_init+0x5bf>
f010188d:	68 94 6e 10 f0       	push   $0xf0106e94
f0101892:	68 8a 6d 10 f0       	push   $0xf0106d8a
f0101897:	68 9f 03 00 00       	push   $0x39f
f010189c:	68 55 6d 10 f0       	push   $0xf0106d55
f01018a1:	e8 9a e7 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01018a6:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f01018a9:	74 04                	je     f01018af <mem_init+0x5c8>
f01018ab:	39 c3                	cmp    %eax,%ebx
f01018ad:	75 19                	jne    f01018c8 <mem_init+0x5e1>
f01018af:	68 78 65 10 f0       	push   $0xf0106578
f01018b4:	68 8a 6d 10 f0       	push   $0xf0106d8a
f01018b9:	68 a0 03 00 00       	push   $0x3a0
f01018be:	68 55 6d 10 f0       	push   $0xf0106d55
f01018c3:	e8 78 e7 ff ff       	call   f0100040 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01018c8:	a1 40 a2 22 f0       	mov    0xf022a240,%eax
f01018cd:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01018d0:	c7 05 40 a2 22 f0 00 	movl   $0x0,0xf022a240
f01018d7:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01018da:	83 ec 0c             	sub    $0xc,%esp
f01018dd:	6a 00                	push   $0x0
f01018df:	e8 83 f6 ff ff       	call   f0100f67 <page_alloc>
f01018e4:	83 c4 10             	add    $0x10,%esp
f01018e7:	85 c0                	test   %eax,%eax
f01018e9:	74 19                	je     f0101904 <mem_init+0x61d>
f01018eb:	68 fd 6e 10 f0       	push   $0xf0106efd
f01018f0:	68 8a 6d 10 f0       	push   $0xf0106d8a
f01018f5:	68 a7 03 00 00       	push   $0x3a7
f01018fa:	68 55 6d 10 f0       	push   $0xf0106d55
f01018ff:	e8 3c e7 ff ff       	call   f0100040 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101904:	83 ec 04             	sub    $0x4,%esp
f0101907:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010190a:	50                   	push   %eax
f010190b:	6a 00                	push   $0x0
f010190d:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0101913:	e8 1f f8 ff ff       	call   f0101137 <page_lookup>
f0101918:	83 c4 10             	add    $0x10,%esp
f010191b:	85 c0                	test   %eax,%eax
f010191d:	74 19                	je     f0101938 <mem_init+0x651>
f010191f:	68 b8 65 10 f0       	push   $0xf01065b8
f0101924:	68 8a 6d 10 f0       	push   $0xf0106d8a
f0101929:	68 aa 03 00 00       	push   $0x3aa
f010192e:	68 55 6d 10 f0       	push   $0xf0106d55
f0101933:	e8 08 e7 ff ff       	call   f0100040 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101938:	6a 02                	push   $0x2
f010193a:	6a 00                	push   $0x0
f010193c:	53                   	push   %ebx
f010193d:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0101943:	e8 c4 f8 ff ff       	call   f010120c <page_insert>
f0101948:	83 c4 10             	add    $0x10,%esp
f010194b:	85 c0                	test   %eax,%eax
f010194d:	78 19                	js     f0101968 <mem_init+0x681>
f010194f:	68 f0 65 10 f0       	push   $0xf01065f0
f0101954:	68 8a 6d 10 f0       	push   $0xf0106d8a
f0101959:	68 ad 03 00 00       	push   $0x3ad
f010195e:	68 55 6d 10 f0       	push   $0xf0106d55
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
f0101978:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f010197e:	e8 89 f8 ff ff       	call   f010120c <page_insert>
f0101983:	83 c4 20             	add    $0x20,%esp
f0101986:	85 c0                	test   %eax,%eax
f0101988:	74 19                	je     f01019a3 <mem_init+0x6bc>
f010198a:	68 20 66 10 f0       	push   $0xf0106620
f010198f:	68 8a 6d 10 f0       	push   $0xf0106d8a
f0101994:	68 b1 03 00 00       	push   $0x3b1
f0101999:	68 55 6d 10 f0       	push   $0xf0106d55
f010199e:	e8 9d e6 ff ff       	call   f0100040 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01019a3:	8b 3d 8c ae 22 f0    	mov    0xf022ae8c,%edi
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01019a9:	a1 90 ae 22 f0       	mov    0xf022ae90,%eax
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
f01019ca:	68 50 66 10 f0       	push   $0xf0106650
f01019cf:	68 8a 6d 10 f0       	push   $0xf0106d8a
f01019d4:	68 b2 03 00 00       	push   $0x3b2
f01019d9:	68 55 6d 10 f0       	push   $0xf0106d55
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
f01019fe:	68 78 66 10 f0       	push   $0xf0106678
f0101a03:	68 8a 6d 10 f0       	push   $0xf0106d8a
f0101a08:	68 b3 03 00 00       	push   $0x3b3
f0101a0d:	68 55 6d 10 f0       	push   $0xf0106d55
f0101a12:	e8 29 e6 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f0101a17:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101a1c:	74 19                	je     f0101a37 <mem_init+0x750>
f0101a1e:	68 4f 6f 10 f0       	push   $0xf0106f4f
f0101a23:	68 8a 6d 10 f0       	push   $0xf0106d8a
f0101a28:	68 b4 03 00 00       	push   $0x3b4
f0101a2d:	68 55 6d 10 f0       	push   $0xf0106d55
f0101a32:	e8 09 e6 ff ff       	call   f0100040 <_panic>
	assert(pp0->pp_ref == 1);
f0101a37:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a3a:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101a3f:	74 19                	je     f0101a5a <mem_init+0x773>
f0101a41:	68 60 6f 10 f0       	push   $0xf0106f60
f0101a46:	68 8a 6d 10 f0       	push   $0xf0106d8a
f0101a4b:	68 b5 03 00 00       	push   $0x3b5
f0101a50:	68 55 6d 10 f0       	push   $0xf0106d55
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
f0101a6f:	68 a8 66 10 f0       	push   $0xf01066a8
f0101a74:	68 8a 6d 10 f0       	push   $0xf0106d8a
f0101a79:	68 b8 03 00 00       	push   $0x3b8
f0101a7e:	68 55 6d 10 f0       	push   $0xf0106d55
f0101a83:	e8 b8 e5 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101a88:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101a8d:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f0101a92:	e8 de ef ff ff       	call   f0100a75 <check_va2pa>
f0101a97:	89 f2                	mov    %esi,%edx
f0101a99:	2b 15 90 ae 22 f0    	sub    0xf022ae90,%edx
f0101a9f:	c1 fa 03             	sar    $0x3,%edx
f0101aa2:	c1 e2 0c             	shl    $0xc,%edx
f0101aa5:	39 d0                	cmp    %edx,%eax
f0101aa7:	74 19                	je     f0101ac2 <mem_init+0x7db>
f0101aa9:	68 e4 66 10 f0       	push   $0xf01066e4
f0101aae:	68 8a 6d 10 f0       	push   $0xf0106d8a
f0101ab3:	68 b9 03 00 00       	push   $0x3b9
f0101ab8:	68 55 6d 10 f0       	push   $0xf0106d55
f0101abd:	e8 7e e5 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101ac2:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101ac7:	74 19                	je     f0101ae2 <mem_init+0x7fb>
f0101ac9:	68 71 6f 10 f0       	push   $0xf0106f71
f0101ace:	68 8a 6d 10 f0       	push   $0xf0106d8a
f0101ad3:	68 ba 03 00 00       	push   $0x3ba
f0101ad8:	68 55 6d 10 f0       	push   $0xf0106d55
f0101add:	e8 5e e5 ff ff       	call   f0100040 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101ae2:	83 ec 0c             	sub    $0xc,%esp
f0101ae5:	6a 00                	push   $0x0
f0101ae7:	e8 7b f4 ff ff       	call   f0100f67 <page_alloc>
f0101aec:	83 c4 10             	add    $0x10,%esp
f0101aef:	85 c0                	test   %eax,%eax
f0101af1:	74 19                	je     f0101b0c <mem_init+0x825>
f0101af3:	68 fd 6e 10 f0       	push   $0xf0106efd
f0101af8:	68 8a 6d 10 f0       	push   $0xf0106d8a
f0101afd:	68 bd 03 00 00       	push   $0x3bd
f0101b02:	68 55 6d 10 f0       	push   $0xf0106d55
f0101b07:	e8 34 e5 ff ff       	call   f0100040 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101b0c:	6a 02                	push   $0x2
f0101b0e:	68 00 10 00 00       	push   $0x1000
f0101b13:	56                   	push   %esi
f0101b14:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0101b1a:	e8 ed f6 ff ff       	call   f010120c <page_insert>
f0101b1f:	83 c4 10             	add    $0x10,%esp
f0101b22:	85 c0                	test   %eax,%eax
f0101b24:	74 19                	je     f0101b3f <mem_init+0x858>
f0101b26:	68 a8 66 10 f0       	push   $0xf01066a8
f0101b2b:	68 8a 6d 10 f0       	push   $0xf0106d8a
f0101b30:	68 c0 03 00 00       	push   $0x3c0
f0101b35:	68 55 6d 10 f0       	push   $0xf0106d55
f0101b3a:	e8 01 e5 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101b3f:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101b44:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f0101b49:	e8 27 ef ff ff       	call   f0100a75 <check_va2pa>
f0101b4e:	89 f2                	mov    %esi,%edx
f0101b50:	2b 15 90 ae 22 f0    	sub    0xf022ae90,%edx
f0101b56:	c1 fa 03             	sar    $0x3,%edx
f0101b59:	c1 e2 0c             	shl    $0xc,%edx
f0101b5c:	39 d0                	cmp    %edx,%eax
f0101b5e:	74 19                	je     f0101b79 <mem_init+0x892>
f0101b60:	68 e4 66 10 f0       	push   $0xf01066e4
f0101b65:	68 8a 6d 10 f0       	push   $0xf0106d8a
f0101b6a:	68 c1 03 00 00       	push   $0x3c1
f0101b6f:	68 55 6d 10 f0       	push   $0xf0106d55
f0101b74:	e8 c7 e4 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101b79:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101b7e:	74 19                	je     f0101b99 <mem_init+0x8b2>
f0101b80:	68 71 6f 10 f0       	push   $0xf0106f71
f0101b85:	68 8a 6d 10 f0       	push   $0xf0106d8a
f0101b8a:	68 c2 03 00 00       	push   $0x3c2
f0101b8f:	68 55 6d 10 f0       	push   $0xf0106d55
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
f0101baa:	68 fd 6e 10 f0       	push   $0xf0106efd
f0101baf:	68 8a 6d 10 f0       	push   $0xf0106d8a
f0101bb4:	68 c6 03 00 00       	push   $0x3c6
f0101bb9:	68 55 6d 10 f0       	push   $0xf0106d55
f0101bbe:	e8 7d e4 ff ff       	call   f0100040 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101bc3:	8b 15 8c ae 22 f0    	mov    0xf022ae8c,%edx
f0101bc9:	8b 02                	mov    (%edx),%eax
f0101bcb:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101bd0:	89 c1                	mov    %eax,%ecx
f0101bd2:	c1 e9 0c             	shr    $0xc,%ecx
f0101bd5:	3b 0d 88 ae 22 f0    	cmp    0xf022ae88,%ecx
f0101bdb:	72 15                	jb     f0101bf2 <mem_init+0x90b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101bdd:	50                   	push   %eax
f0101bde:	68 84 5e 10 f0       	push   $0xf0105e84
f0101be3:	68 c9 03 00 00       	push   $0x3c9
f0101be8:	68 55 6d 10 f0       	push   $0xf0106d55
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
f0101c17:	68 14 67 10 f0       	push   $0xf0106714
f0101c1c:	68 8a 6d 10 f0       	push   $0xf0106d8a
f0101c21:	68 ca 03 00 00       	push   $0x3ca
f0101c26:	68 55 6d 10 f0       	push   $0xf0106d55
f0101c2b:	e8 10 e4 ff ff       	call   f0100040 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101c30:	6a 06                	push   $0x6
f0101c32:	68 00 10 00 00       	push   $0x1000
f0101c37:	56                   	push   %esi
f0101c38:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0101c3e:	e8 c9 f5 ff ff       	call   f010120c <page_insert>
f0101c43:	83 c4 10             	add    $0x10,%esp
f0101c46:	85 c0                	test   %eax,%eax
f0101c48:	74 19                	je     f0101c63 <mem_init+0x97c>
f0101c4a:	68 54 67 10 f0       	push   $0xf0106754
f0101c4f:	68 8a 6d 10 f0       	push   $0xf0106d8a
f0101c54:	68 cd 03 00 00       	push   $0x3cd
f0101c59:	68 55 6d 10 f0       	push   $0xf0106d55
f0101c5e:	e8 dd e3 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101c63:	8b 3d 8c ae 22 f0    	mov    0xf022ae8c,%edi
f0101c69:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c6e:	89 f8                	mov    %edi,%eax
f0101c70:	e8 00 ee ff ff       	call   f0100a75 <check_va2pa>
f0101c75:	89 f2                	mov    %esi,%edx
f0101c77:	2b 15 90 ae 22 f0    	sub    0xf022ae90,%edx
f0101c7d:	c1 fa 03             	sar    $0x3,%edx
f0101c80:	c1 e2 0c             	shl    $0xc,%edx
f0101c83:	39 d0                	cmp    %edx,%eax
f0101c85:	74 19                	je     f0101ca0 <mem_init+0x9b9>
f0101c87:	68 e4 66 10 f0       	push   $0xf01066e4
f0101c8c:	68 8a 6d 10 f0       	push   $0xf0106d8a
f0101c91:	68 ce 03 00 00       	push   $0x3ce
f0101c96:	68 55 6d 10 f0       	push   $0xf0106d55
f0101c9b:	e8 a0 e3 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101ca0:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101ca5:	74 19                	je     f0101cc0 <mem_init+0x9d9>
f0101ca7:	68 71 6f 10 f0       	push   $0xf0106f71
f0101cac:	68 8a 6d 10 f0       	push   $0xf0106d8a
f0101cb1:	68 cf 03 00 00       	push   $0x3cf
f0101cb6:	68 55 6d 10 f0       	push   $0xf0106d55
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
f0101cd8:	68 94 67 10 f0       	push   $0xf0106794
f0101cdd:	68 8a 6d 10 f0       	push   $0xf0106d8a
f0101ce2:	68 d0 03 00 00       	push   $0x3d0
f0101ce7:	68 55 6d 10 f0       	push   $0xf0106d55
f0101cec:	e8 4f e3 ff ff       	call   f0100040 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101cf1:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f0101cf6:	f6 00 04             	testb  $0x4,(%eax)
f0101cf9:	75 19                	jne    f0101d14 <mem_init+0xa2d>
f0101cfb:	68 82 6f 10 f0       	push   $0xf0106f82
f0101d00:	68 8a 6d 10 f0       	push   $0xf0106d8a
f0101d05:	68 d1 03 00 00       	push   $0x3d1
f0101d0a:	68 55 6d 10 f0       	push   $0xf0106d55
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
f0101d29:	68 a8 66 10 f0       	push   $0xf01066a8
f0101d2e:	68 8a 6d 10 f0       	push   $0xf0106d8a
f0101d33:	68 d4 03 00 00       	push   $0x3d4
f0101d38:	68 55 6d 10 f0       	push   $0xf0106d55
f0101d3d:	e8 fe e2 ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101d42:	83 ec 04             	sub    $0x4,%esp
f0101d45:	6a 00                	push   $0x0
f0101d47:	68 00 10 00 00       	push   $0x1000
f0101d4c:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0101d52:	e8 e9 f2 ff ff       	call   f0101040 <pgdir_walk>
f0101d57:	83 c4 10             	add    $0x10,%esp
f0101d5a:	f6 00 02             	testb  $0x2,(%eax)
f0101d5d:	75 19                	jne    f0101d78 <mem_init+0xa91>
f0101d5f:	68 c8 67 10 f0       	push   $0xf01067c8
f0101d64:	68 8a 6d 10 f0       	push   $0xf0106d8a
f0101d69:	68 d5 03 00 00       	push   $0x3d5
f0101d6e:	68 55 6d 10 f0       	push   $0xf0106d55
f0101d73:	e8 c8 e2 ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101d78:	83 ec 04             	sub    $0x4,%esp
f0101d7b:	6a 00                	push   $0x0
f0101d7d:	68 00 10 00 00       	push   $0x1000
f0101d82:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0101d88:	e8 b3 f2 ff ff       	call   f0101040 <pgdir_walk>
f0101d8d:	83 c4 10             	add    $0x10,%esp
f0101d90:	f6 00 04             	testb  $0x4,(%eax)
f0101d93:	74 19                	je     f0101dae <mem_init+0xac7>
f0101d95:	68 fc 67 10 f0       	push   $0xf01067fc
f0101d9a:	68 8a 6d 10 f0       	push   $0xf0106d8a
f0101d9f:	68 d6 03 00 00       	push   $0x3d6
f0101da4:	68 55 6d 10 f0       	push   $0xf0106d55
f0101da9:	e8 92 e2 ff ff       	call   f0100040 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101dae:	6a 02                	push   $0x2
f0101db0:	68 00 00 40 00       	push   $0x400000
f0101db5:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101db8:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0101dbe:	e8 49 f4 ff ff       	call   f010120c <page_insert>
f0101dc3:	83 c4 10             	add    $0x10,%esp
f0101dc6:	85 c0                	test   %eax,%eax
f0101dc8:	78 19                	js     f0101de3 <mem_init+0xafc>
f0101dca:	68 34 68 10 f0       	push   $0xf0106834
f0101dcf:	68 8a 6d 10 f0       	push   $0xf0106d8a
f0101dd4:	68 d9 03 00 00       	push   $0x3d9
f0101dd9:	68 55 6d 10 f0       	push   $0xf0106d55
f0101dde:	e8 5d e2 ff ff       	call   f0100040 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101de3:	6a 02                	push   $0x2
f0101de5:	68 00 10 00 00       	push   $0x1000
f0101dea:	53                   	push   %ebx
f0101deb:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0101df1:	e8 16 f4 ff ff       	call   f010120c <page_insert>
f0101df6:	83 c4 10             	add    $0x10,%esp
f0101df9:	85 c0                	test   %eax,%eax
f0101dfb:	74 19                	je     f0101e16 <mem_init+0xb2f>
f0101dfd:	68 6c 68 10 f0       	push   $0xf010686c
f0101e02:	68 8a 6d 10 f0       	push   $0xf0106d8a
f0101e07:	68 dc 03 00 00       	push   $0x3dc
f0101e0c:	68 55 6d 10 f0       	push   $0xf0106d55
f0101e11:	e8 2a e2 ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101e16:	83 ec 04             	sub    $0x4,%esp
f0101e19:	6a 00                	push   $0x0
f0101e1b:	68 00 10 00 00       	push   $0x1000
f0101e20:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0101e26:	e8 15 f2 ff ff       	call   f0101040 <pgdir_walk>
f0101e2b:	83 c4 10             	add    $0x10,%esp
f0101e2e:	f6 00 04             	testb  $0x4,(%eax)
f0101e31:	74 19                	je     f0101e4c <mem_init+0xb65>
f0101e33:	68 fc 67 10 f0       	push   $0xf01067fc
f0101e38:	68 8a 6d 10 f0       	push   $0xf0106d8a
f0101e3d:	68 dd 03 00 00       	push   $0x3dd
f0101e42:	68 55 6d 10 f0       	push   $0xf0106d55
f0101e47:	e8 f4 e1 ff ff       	call   f0100040 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101e4c:	8b 3d 8c ae 22 f0    	mov    0xf022ae8c,%edi
f0101e52:	ba 00 00 00 00       	mov    $0x0,%edx
f0101e57:	89 f8                	mov    %edi,%eax
f0101e59:	e8 17 ec ff ff       	call   f0100a75 <check_va2pa>
f0101e5e:	89 c1                	mov    %eax,%ecx
f0101e60:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101e63:	89 d8                	mov    %ebx,%eax
f0101e65:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f0101e6b:	c1 f8 03             	sar    $0x3,%eax
f0101e6e:	c1 e0 0c             	shl    $0xc,%eax
f0101e71:	39 c1                	cmp    %eax,%ecx
f0101e73:	74 19                	je     f0101e8e <mem_init+0xba7>
f0101e75:	68 a8 68 10 f0       	push   $0xf01068a8
f0101e7a:	68 8a 6d 10 f0       	push   $0xf0106d8a
f0101e7f:	68 e0 03 00 00       	push   $0x3e0
f0101e84:	68 55 6d 10 f0       	push   $0xf0106d55
f0101e89:	e8 b2 e1 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101e8e:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e93:	89 f8                	mov    %edi,%eax
f0101e95:	e8 db eb ff ff       	call   f0100a75 <check_va2pa>
f0101e9a:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101e9d:	74 19                	je     f0101eb8 <mem_init+0xbd1>
f0101e9f:	68 d4 68 10 f0       	push   $0xf01068d4
f0101ea4:	68 8a 6d 10 f0       	push   $0xf0106d8a
f0101ea9:	68 e1 03 00 00       	push   $0x3e1
f0101eae:	68 55 6d 10 f0       	push   $0xf0106d55
f0101eb3:	e8 88 e1 ff ff       	call   f0100040 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101eb8:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101ebd:	74 19                	je     f0101ed8 <mem_init+0xbf1>
f0101ebf:	68 98 6f 10 f0       	push   $0xf0106f98
f0101ec4:	68 8a 6d 10 f0       	push   $0xf0106d8a
f0101ec9:	68 e3 03 00 00       	push   $0x3e3
f0101ece:	68 55 6d 10 f0       	push   $0xf0106d55
f0101ed3:	e8 68 e1 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f0101ed8:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101edd:	74 19                	je     f0101ef8 <mem_init+0xc11>
f0101edf:	68 a9 6f 10 f0       	push   $0xf0106fa9
f0101ee4:	68 8a 6d 10 f0       	push   $0xf0106d8a
f0101ee9:	68 e4 03 00 00       	push   $0x3e4
f0101eee:	68 55 6d 10 f0       	push   $0xf0106d55
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
f0101f0d:	68 04 69 10 f0       	push   $0xf0106904
f0101f12:	68 8a 6d 10 f0       	push   $0xf0106d8a
f0101f17:	68 e7 03 00 00       	push   $0x3e7
f0101f1c:	68 55 6d 10 f0       	push   $0xf0106d55
f0101f21:	e8 1a e1 ff ff       	call   f0100040 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101f26:	83 ec 08             	sub    $0x8,%esp
f0101f29:	6a 00                	push   $0x0
f0101f2b:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0101f31:	e8 90 f2 ff ff       	call   f01011c6 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101f36:	8b 3d 8c ae 22 f0    	mov    0xf022ae8c,%edi
f0101f3c:	ba 00 00 00 00       	mov    $0x0,%edx
f0101f41:	89 f8                	mov    %edi,%eax
f0101f43:	e8 2d eb ff ff       	call   f0100a75 <check_va2pa>
f0101f48:	83 c4 10             	add    $0x10,%esp
f0101f4b:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101f4e:	74 19                	je     f0101f69 <mem_init+0xc82>
f0101f50:	68 28 69 10 f0       	push   $0xf0106928
f0101f55:	68 8a 6d 10 f0       	push   $0xf0106d8a
f0101f5a:	68 eb 03 00 00       	push   $0x3eb
f0101f5f:	68 55 6d 10 f0       	push   $0xf0106d55
f0101f64:	e8 d7 e0 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101f69:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101f6e:	89 f8                	mov    %edi,%eax
f0101f70:	e8 00 eb ff ff       	call   f0100a75 <check_va2pa>
f0101f75:	89 da                	mov    %ebx,%edx
f0101f77:	2b 15 90 ae 22 f0    	sub    0xf022ae90,%edx
f0101f7d:	c1 fa 03             	sar    $0x3,%edx
f0101f80:	c1 e2 0c             	shl    $0xc,%edx
f0101f83:	39 d0                	cmp    %edx,%eax
f0101f85:	74 19                	je     f0101fa0 <mem_init+0xcb9>
f0101f87:	68 d4 68 10 f0       	push   $0xf01068d4
f0101f8c:	68 8a 6d 10 f0       	push   $0xf0106d8a
f0101f91:	68 ec 03 00 00       	push   $0x3ec
f0101f96:	68 55 6d 10 f0       	push   $0xf0106d55
f0101f9b:	e8 a0 e0 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f0101fa0:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101fa5:	74 19                	je     f0101fc0 <mem_init+0xcd9>
f0101fa7:	68 4f 6f 10 f0       	push   $0xf0106f4f
f0101fac:	68 8a 6d 10 f0       	push   $0xf0106d8a
f0101fb1:	68 ed 03 00 00       	push   $0x3ed
f0101fb6:	68 55 6d 10 f0       	push   $0xf0106d55
f0101fbb:	e8 80 e0 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f0101fc0:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101fc5:	74 19                	je     f0101fe0 <mem_init+0xcf9>
f0101fc7:	68 a9 6f 10 f0       	push   $0xf0106fa9
f0101fcc:	68 8a 6d 10 f0       	push   $0xf0106d8a
f0101fd1:	68 ee 03 00 00       	push   $0x3ee
f0101fd6:	68 55 6d 10 f0       	push   $0xf0106d55
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
f0101ff5:	68 4c 69 10 f0       	push   $0xf010694c
f0101ffa:	68 8a 6d 10 f0       	push   $0xf0106d8a
f0101fff:	68 f1 03 00 00       	push   $0x3f1
f0102004:	68 55 6d 10 f0       	push   $0xf0106d55
f0102009:	e8 32 e0 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref);
f010200e:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102013:	75 19                	jne    f010202e <mem_init+0xd47>
f0102015:	68 ba 6f 10 f0       	push   $0xf0106fba
f010201a:	68 8a 6d 10 f0       	push   $0xf0106d8a
f010201f:	68 f2 03 00 00       	push   $0x3f2
f0102024:	68 55 6d 10 f0       	push   $0xf0106d55
f0102029:	e8 12 e0 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_link == NULL);
f010202e:	83 3b 00             	cmpl   $0x0,(%ebx)
f0102031:	74 19                	je     f010204c <mem_init+0xd65>
f0102033:	68 c6 6f 10 f0       	push   $0xf0106fc6
f0102038:	68 8a 6d 10 f0       	push   $0xf0106d8a
f010203d:	68 f3 03 00 00       	push   $0x3f3
f0102042:	68 55 6d 10 f0       	push   $0xf0106d55
f0102047:	e8 f4 df ff ff       	call   f0100040 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f010204c:	83 ec 08             	sub    $0x8,%esp
f010204f:	68 00 10 00 00       	push   $0x1000
f0102054:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f010205a:	e8 67 f1 ff ff       	call   f01011c6 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f010205f:	8b 3d 8c ae 22 f0    	mov    0xf022ae8c,%edi
f0102065:	ba 00 00 00 00       	mov    $0x0,%edx
f010206a:	89 f8                	mov    %edi,%eax
f010206c:	e8 04 ea ff ff       	call   f0100a75 <check_va2pa>
f0102071:	83 c4 10             	add    $0x10,%esp
f0102074:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102077:	74 19                	je     f0102092 <mem_init+0xdab>
f0102079:	68 28 69 10 f0       	push   $0xf0106928
f010207e:	68 8a 6d 10 f0       	push   $0xf0106d8a
f0102083:	68 f7 03 00 00       	push   $0x3f7
f0102088:	68 55 6d 10 f0       	push   $0xf0106d55
f010208d:	e8 ae df ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0102092:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102097:	89 f8                	mov    %edi,%eax
f0102099:	e8 d7 e9 ff ff       	call   f0100a75 <check_va2pa>
f010209e:	83 f8 ff             	cmp    $0xffffffff,%eax
f01020a1:	74 19                	je     f01020bc <mem_init+0xdd5>
f01020a3:	68 84 69 10 f0       	push   $0xf0106984
f01020a8:	68 8a 6d 10 f0       	push   $0xf0106d8a
f01020ad:	68 f8 03 00 00       	push   $0x3f8
f01020b2:	68 55 6d 10 f0       	push   $0xf0106d55
f01020b7:	e8 84 df ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f01020bc:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f01020c1:	74 19                	je     f01020dc <mem_init+0xdf5>
f01020c3:	68 db 6f 10 f0       	push   $0xf0106fdb
f01020c8:	68 8a 6d 10 f0       	push   $0xf0106d8a
f01020cd:	68 f9 03 00 00       	push   $0x3f9
f01020d2:	68 55 6d 10 f0       	push   $0xf0106d55
f01020d7:	e8 64 df ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f01020dc:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01020e1:	74 19                	je     f01020fc <mem_init+0xe15>
f01020e3:	68 a9 6f 10 f0       	push   $0xf0106fa9
f01020e8:	68 8a 6d 10 f0       	push   $0xf0106d8a
f01020ed:	68 fa 03 00 00       	push   $0x3fa
f01020f2:	68 55 6d 10 f0       	push   $0xf0106d55
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
f0102111:	68 ac 69 10 f0       	push   $0xf01069ac
f0102116:	68 8a 6d 10 f0       	push   $0xf0106d8a
f010211b:	68 fd 03 00 00       	push   $0x3fd
f0102120:	68 55 6d 10 f0       	push   $0xf0106d55
f0102125:	e8 16 df ff ff       	call   f0100040 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f010212a:	83 ec 0c             	sub    $0xc,%esp
f010212d:	6a 00                	push   $0x0
f010212f:	e8 33 ee ff ff       	call   f0100f67 <page_alloc>
f0102134:	83 c4 10             	add    $0x10,%esp
f0102137:	85 c0                	test   %eax,%eax
f0102139:	74 19                	je     f0102154 <mem_init+0xe6d>
f010213b:	68 fd 6e 10 f0       	push   $0xf0106efd
f0102140:	68 8a 6d 10 f0       	push   $0xf0106d8a
f0102145:	68 00 04 00 00       	push   $0x400
f010214a:	68 55 6d 10 f0       	push   $0xf0106d55
f010214f:	e8 ec de ff ff       	call   f0100040 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102154:	8b 0d 8c ae 22 f0    	mov    0xf022ae8c,%ecx
f010215a:	8b 11                	mov    (%ecx),%edx
f010215c:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102162:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102165:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f010216b:	c1 f8 03             	sar    $0x3,%eax
f010216e:	c1 e0 0c             	shl    $0xc,%eax
f0102171:	39 c2                	cmp    %eax,%edx
f0102173:	74 19                	je     f010218e <mem_init+0xea7>
f0102175:	68 50 66 10 f0       	push   $0xf0106650
f010217a:	68 8a 6d 10 f0       	push   $0xf0106d8a
f010217f:	68 03 04 00 00       	push   $0x403
f0102184:	68 55 6d 10 f0       	push   $0xf0106d55
f0102189:	e8 b2 de ff ff       	call   f0100040 <_panic>
	kern_pgdir[0] = 0;
f010218e:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102194:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102197:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f010219c:	74 19                	je     f01021b7 <mem_init+0xed0>
f010219e:	68 60 6f 10 f0       	push   $0xf0106f60
f01021a3:	68 8a 6d 10 f0       	push   $0xf0106d8a
f01021a8:	68 05 04 00 00       	push   $0x405
f01021ad:	68 55 6d 10 f0       	push   $0xf0106d55
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
f01021d3:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f01021d9:	e8 62 ee ff ff       	call   f0101040 <pgdir_walk>
f01021de:	89 c7                	mov    %eax,%edi
f01021e0:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f01021e3:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f01021e8:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01021eb:	8b 40 04             	mov    0x4(%eax),%eax
f01021ee:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01021f3:	8b 0d 88 ae 22 f0    	mov    0xf022ae88,%ecx
f01021f9:	89 c2                	mov    %eax,%edx
f01021fb:	c1 ea 0c             	shr    $0xc,%edx
f01021fe:	83 c4 10             	add    $0x10,%esp
f0102201:	39 ca                	cmp    %ecx,%edx
f0102203:	72 15                	jb     f010221a <mem_init+0xf33>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102205:	50                   	push   %eax
f0102206:	68 84 5e 10 f0       	push   $0xf0105e84
f010220b:	68 0c 04 00 00       	push   $0x40c
f0102210:	68 55 6d 10 f0       	push   $0xf0106d55
f0102215:	e8 26 de ff ff       	call   f0100040 <_panic>
	assert(ptep == ptep1 + PTX(va));
f010221a:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f010221f:	39 c7                	cmp    %eax,%edi
f0102221:	74 19                	je     f010223c <mem_init+0xf55>
f0102223:	68 ec 6f 10 f0       	push   $0xf0106fec
f0102228:	68 8a 6d 10 f0       	push   $0xf0106d8a
f010222d:	68 0d 04 00 00       	push   $0x40d
f0102232:	68 55 6d 10 f0       	push   $0xf0106d55
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
f010224f:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
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
f0102265:	68 84 5e 10 f0       	push   $0xf0105e84
f010226a:	6a 58                	push   $0x58
f010226c:	68 70 6d 10 f0       	push   $0xf0106d70
f0102271:	e8 ca dd ff ff       	call   f0100040 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0102276:	83 ec 04             	sub    $0x4,%esp
f0102279:	68 00 10 00 00       	push   $0x1000
f010227e:	68 ff 00 00 00       	push   $0xff
f0102283:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102288:	50                   	push   %eax
f0102289:	e8 25 2f 00 00       	call   f01051b3 <memset>
	page_free(pp0);
f010228e:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102291:	89 3c 24             	mov    %edi,(%esp)
f0102294:	e8 45 ed ff ff       	call   f0100fde <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0102299:	83 c4 0c             	add    $0xc,%esp
f010229c:	6a 01                	push   $0x1
f010229e:	6a 00                	push   $0x0
f01022a0:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f01022a6:	e8 95 ed ff ff       	call   f0101040 <pgdir_walk>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01022ab:	89 fa                	mov    %edi,%edx
f01022ad:	2b 15 90 ae 22 f0    	sub    0xf022ae90,%edx
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
f01022c1:	3b 05 88 ae 22 f0    	cmp    0xf022ae88,%eax
f01022c7:	72 12                	jb     f01022db <mem_init+0xff4>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01022c9:	52                   	push   %edx
f01022ca:	68 84 5e 10 f0       	push   $0xf0105e84
f01022cf:	6a 58                	push   $0x58
f01022d1:	68 70 6d 10 f0       	push   $0xf0106d70
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
f01022ef:	68 04 70 10 f0       	push   $0xf0107004
f01022f4:	68 8a 6d 10 f0       	push   $0xf0106d8a
f01022f9:	68 17 04 00 00       	push   $0x417
f01022fe:	68 55 6d 10 f0       	push   $0xf0106d55
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
f010230f:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f0102314:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f010231a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010231d:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f0102323:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0102326:	89 0d 40 a2 22 f0    	mov    %ecx,0xf022a240

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
f010237f:	68 d0 69 10 f0       	push   $0xf01069d0
f0102384:	68 8a 6d 10 f0       	push   $0xf0106d8a
f0102389:	68 27 04 00 00       	push   $0x427
f010238e:	68 55 6d 10 f0       	push   $0xf0106d55
f0102393:	e8 a8 dc ff ff       	call   f0100040 <_panic>
	assert(mm2 >= MMIOBASE && mm2 + 8096 < MMIOLIM);
f0102398:	8d 96 a0 1f 00 00    	lea    0x1fa0(%esi),%edx
f010239e:	81 fa ff ff bf ef    	cmp    $0xefbfffff,%edx
f01023a4:	77 08                	ja     f01023ae <mem_init+0x10c7>
f01023a6:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f01023ac:	77 19                	ja     f01023c7 <mem_init+0x10e0>
f01023ae:	68 f8 69 10 f0       	push   $0xf01069f8
f01023b3:	68 8a 6d 10 f0       	push   $0xf0106d8a
f01023b8:	68 28 04 00 00       	push   $0x428
f01023bd:	68 55 6d 10 f0       	push   $0xf0106d55
f01023c2:	e8 79 dc ff ff       	call   f0100040 <_panic>
	// check that they're page-aligned
	assert(mm1 % PGSIZE == 0 && mm2 % PGSIZE == 0);
f01023c7:	89 da                	mov    %ebx,%edx
f01023c9:	09 f2                	or     %esi,%edx
f01023cb:	f7 c2 ff 0f 00 00    	test   $0xfff,%edx
f01023d1:	74 19                	je     f01023ec <mem_init+0x1105>
f01023d3:	68 20 6a 10 f0       	push   $0xf0106a20
f01023d8:	68 8a 6d 10 f0       	push   $0xf0106d8a
f01023dd:	68 2a 04 00 00       	push   $0x42a
f01023e2:	68 55 6d 10 f0       	push   $0xf0106d55
f01023e7:	e8 54 dc ff ff       	call   f0100040 <_panic>
	// check that they don't overlap
	assert(mm1 + 8096 <= mm2);
f01023ec:	39 c6                	cmp    %eax,%esi
f01023ee:	73 19                	jae    f0102409 <mem_init+0x1122>
f01023f0:	68 1b 70 10 f0       	push   $0xf010701b
f01023f5:	68 8a 6d 10 f0       	push   $0xf0106d8a
f01023fa:	68 2c 04 00 00       	push   $0x42c
f01023ff:	68 55 6d 10 f0       	push   $0xf0106d55
f0102404:	e8 37 dc ff ff       	call   f0100040 <_panic>
	// check page mappings
	assert(check_va2pa(kern_pgdir, mm1) == 0);
f0102409:	8b 3d 8c ae 22 f0    	mov    0xf022ae8c,%edi
f010240f:	89 da                	mov    %ebx,%edx
f0102411:	89 f8                	mov    %edi,%eax
f0102413:	e8 5d e6 ff ff       	call   f0100a75 <check_va2pa>
f0102418:	85 c0                	test   %eax,%eax
f010241a:	74 19                	je     f0102435 <mem_init+0x114e>
f010241c:	68 48 6a 10 f0       	push   $0xf0106a48
f0102421:	68 8a 6d 10 f0       	push   $0xf0106d8a
f0102426:	68 2e 04 00 00       	push   $0x42e
f010242b:	68 55 6d 10 f0       	push   $0xf0106d55
f0102430:	e8 0b dc ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm1+PGSIZE) == PGSIZE);
f0102435:	8d 83 00 10 00 00    	lea    0x1000(%ebx),%eax
f010243b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010243e:	89 c2                	mov    %eax,%edx
f0102440:	89 f8                	mov    %edi,%eax
f0102442:	e8 2e e6 ff ff       	call   f0100a75 <check_va2pa>
f0102447:	3d 00 10 00 00       	cmp    $0x1000,%eax
f010244c:	74 19                	je     f0102467 <mem_init+0x1180>
f010244e:	68 6c 6a 10 f0       	push   $0xf0106a6c
f0102453:	68 8a 6d 10 f0       	push   $0xf0106d8a
f0102458:	68 2f 04 00 00       	push   $0x42f
f010245d:	68 55 6d 10 f0       	push   $0xf0106d55
f0102462:	e8 d9 db ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm2) == 0);
f0102467:	89 f2                	mov    %esi,%edx
f0102469:	89 f8                	mov    %edi,%eax
f010246b:	e8 05 e6 ff ff       	call   f0100a75 <check_va2pa>
f0102470:	85 c0                	test   %eax,%eax
f0102472:	74 19                	je     f010248d <mem_init+0x11a6>
f0102474:	68 9c 6a 10 f0       	push   $0xf0106a9c
f0102479:	68 8a 6d 10 f0       	push   $0xf0106d8a
f010247e:	68 30 04 00 00       	push   $0x430
f0102483:	68 55 6d 10 f0       	push   $0xf0106d55
f0102488:	e8 b3 db ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm2+PGSIZE) == ~0);
f010248d:	8d 96 00 10 00 00    	lea    0x1000(%esi),%edx
f0102493:	89 f8                	mov    %edi,%eax
f0102495:	e8 db e5 ff ff       	call   f0100a75 <check_va2pa>
f010249a:	83 f8 ff             	cmp    $0xffffffff,%eax
f010249d:	74 19                	je     f01024b8 <mem_init+0x11d1>
f010249f:	68 c0 6a 10 f0       	push   $0xf0106ac0
f01024a4:	68 8a 6d 10 f0       	push   $0xf0106d8a
f01024a9:	68 31 04 00 00       	push   $0x431
f01024ae:	68 55 6d 10 f0       	push   $0xf0106d55
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
f01024cc:	68 ec 6a 10 f0       	push   $0xf0106aec
f01024d1:	68 8a 6d 10 f0       	push   $0xf0106d8a
f01024d6:	68 33 04 00 00       	push   $0x433
f01024db:	68 55 6d 10 f0       	push   $0xf0106d55
f01024e0:	e8 5b db ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & PTE_U));
f01024e5:	83 ec 04             	sub    $0x4,%esp
f01024e8:	6a 00                	push   $0x0
f01024ea:	53                   	push   %ebx
f01024eb:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f01024f1:	e8 4a eb ff ff       	call   f0101040 <pgdir_walk>
f01024f6:	8b 00                	mov    (%eax),%eax
f01024f8:	83 c4 10             	add    $0x10,%esp
f01024fb:	83 e0 04             	and    $0x4,%eax
f01024fe:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0102501:	74 19                	je     f010251c <mem_init+0x1235>
f0102503:	68 30 6b 10 f0       	push   $0xf0106b30
f0102508:	68 8a 6d 10 f0       	push   $0xf0106d8a
f010250d:	68 34 04 00 00       	push   $0x434
f0102512:	68 55 6d 10 f0       	push   $0xf0106d55
f0102517:	e8 24 db ff ff       	call   f0100040 <_panic>
	// clear the mappings
	*pgdir_walk(kern_pgdir, (void*) mm1, 0) = 0;
f010251c:	83 ec 04             	sub    $0x4,%esp
f010251f:	6a 00                	push   $0x0
f0102521:	53                   	push   %ebx
f0102522:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0102528:	e8 13 eb ff ff       	call   f0101040 <pgdir_walk>
f010252d:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm1 + PGSIZE, 0) = 0;
f0102533:	83 c4 0c             	add    $0xc,%esp
f0102536:	6a 00                	push   $0x0
f0102538:	ff 75 d4             	pushl  -0x2c(%ebp)
f010253b:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0102541:	e8 fa ea ff ff       	call   f0101040 <pgdir_walk>
f0102546:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm2, 0) = 0;
f010254c:	83 c4 0c             	add    $0xc,%esp
f010254f:	6a 00                	push   $0x0
f0102551:	56                   	push   %esi
f0102552:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0102558:	e8 e3 ea ff ff       	call   f0101040 <pgdir_walk>
f010255d:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

	cprintf("check_page() succeeded!\n");
f0102563:	c7 04 24 2d 70 10 f0 	movl   $0xf010702d,(%esp)
f010256a:	e8 e8 10 00 00       	call   f0103657 <cprintf>
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	
	boot_map_region(kern_pgdir, UPAGES, PTSIZE, PADDR(pages), PTE_U);
f010256f:	a1 90 ae 22 f0       	mov    0xf022ae90,%eax
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
f010257f:	68 a8 5e 10 f0       	push   $0xf0105ea8
f0102584:	68 be 00 00 00       	push   $0xbe
f0102589:	68 55 6d 10 f0       	push   $0xf0106d55
f010258e:	e8 ad da ff ff       	call   f0100040 <_panic>
f0102593:	83 ec 08             	sub    $0x8,%esp
f0102596:	6a 04                	push   $0x4
f0102598:	05 00 00 00 10       	add    $0x10000000,%eax
f010259d:	50                   	push   %eax
f010259e:	b9 00 00 40 00       	mov    $0x400000,%ecx
f01025a3:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f01025a8:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f01025ad:	e8 23 eb ff ff       	call   f01010d5 <boot_map_region>
	// (ie. perm = PTE_U | PTE_P).
	// Permissions:
	//    - the new image at UENVS  -- kernel R, user R
	//    - envs itself -- kernel RW, user NONE
	// LAB 3: Your code here.
	boot_map_region(kern_pgdir, UENVS, PTSIZE, PADDR(envs), PTE_U);
f01025b2:	a1 44 a2 22 f0       	mov    0xf022a244,%eax
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
f01025c2:	68 a8 5e 10 f0       	push   $0xf0105ea8
f01025c7:	68 c7 00 00 00       	push   $0xc7
f01025cc:	68 55 6d 10 f0       	push   $0xf0106d55
f01025d1:	e8 6a da ff ff       	call   f0100040 <_panic>
f01025d6:	83 ec 08             	sub    $0x8,%esp
f01025d9:	6a 04                	push   $0x4
f01025db:	05 00 00 00 10       	add    $0x10000000,%eax
f01025e0:	50                   	push   %eax
f01025e1:	b9 00 00 40 00       	mov    $0x400000,%ecx
f01025e6:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f01025eb:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f01025f0:	e8 e0 ea ff ff       	call   f01010d5 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01025f5:	83 c4 10             	add    $0x10,%esp
f01025f8:	b8 00 50 11 f0       	mov    $0xf0115000,%eax
f01025fd:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102602:	77 15                	ja     f0102619 <mem_init+0x1332>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102604:	50                   	push   %eax
f0102605:	68 a8 5e 10 f0       	push   $0xf0105ea8
f010260a:	68 d4 00 00 00       	push   $0xd4
f010260f:	68 55 6d 10 f0       	push   $0xf0106d55
f0102614:	e8 27 da ff ff       	call   f0100040 <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KSTACKTOP-KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W);
f0102619:	83 ec 08             	sub    $0x8,%esp
f010261c:	6a 02                	push   $0x2
f010261e:	68 00 50 11 00       	push   $0x115000
f0102623:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102628:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f010262d:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
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
f0102648:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f010264d:	e8 83 ea ff ff       	call   f01010d5 <boot_map_region>
f0102652:	c7 45 c4 00 c0 22 f0 	movl   $0xf022c000,-0x3c(%ebp)
f0102659:	83 c4 10             	add    $0x10,%esp
f010265c:	bb 00 c0 22 f0       	mov    $0xf022c000,%ebx
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
f010266f:	68 a8 5e 10 f0       	push   $0xf0105ea8
f0102674:	68 16 01 00 00       	push   $0x116
f0102679:	68 55 6d 10 f0       	push   $0xf0106d55
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
f0102696:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f010269b:	e8 35 ea ff ff       	call   f01010d5 <boot_map_region>
f01026a0:	81 c3 00 80 00 00    	add    $0x8000,%ebx
f01026a6:	81 ee 00 00 01 00    	sub    $0x10000,%esi
	//     Permissions: kernel RW, user NONE
	//
	// LAB 4: Your code here:

    uintptr_t kstacktop_i;
    for(int i = 0; i < NCPU; i++){
f01026ac:	83 c4 10             	add    $0x10,%esp
f01026af:	b8 00 c0 26 f0       	mov    $0xf026c000,%eax
f01026b4:	39 d8                	cmp    %ebx,%eax
f01026b6:	75 ae                	jne    f0102666 <mem_init+0x137f>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f01026b8:	8b 3d 8c ae 22 f0    	mov    0xf022ae8c,%edi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f01026be:	a1 88 ae 22 f0       	mov    0xf022ae88,%eax
f01026c3:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01026c6:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f01026cd:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01026d2:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01026d5:	8b 35 90 ae 22 f0    	mov    0xf022ae90,%esi
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
f01026fc:	68 a8 5e 10 f0       	push   $0xf0105ea8
f0102701:	68 4c 03 00 00       	push   $0x34c
f0102706:	68 55 6d 10 f0       	push   $0xf0106d55
f010270b:	e8 30 d9 ff ff       	call   f0100040 <_panic>
f0102710:	8d 94 1e 00 00 00 10 	lea    0x10000000(%esi,%ebx,1),%edx
f0102717:	39 c2                	cmp    %eax,%edx
f0102719:	74 19                	je     f0102734 <mem_init+0x144d>
f010271b:	68 64 6b 10 f0       	push   $0xf0106b64
f0102720:	68 8a 6d 10 f0       	push   $0xf0106d8a
f0102725:	68 4c 03 00 00       	push   $0x34c
f010272a:	68 55 6d 10 f0       	push   $0xf0106d55
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
f010273f:	8b 35 44 a2 22 f0    	mov    0xf022a244,%esi
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
f0102760:	68 a8 5e 10 f0       	push   $0xf0105ea8
f0102765:	68 51 03 00 00       	push   $0x351
f010276a:	68 55 6d 10 f0       	push   $0xf0106d55
f010276f:	e8 cc d8 ff ff       	call   f0100040 <_panic>
f0102774:	8d 94 1e 00 00 40 21 	lea    0x21400000(%esi,%ebx,1),%edx
f010277b:	39 d0                	cmp    %edx,%eax
f010277d:	74 19                	je     f0102798 <mem_init+0x14b1>
f010277f:	68 98 6b 10 f0       	push   $0xf0106b98
f0102784:	68 8a 6d 10 f0       	push   $0xf0106d8a
f0102789:	68 51 03 00 00       	push   $0x351
f010278e:	68 55 6d 10 f0       	push   $0xf0106d55
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
f01027c4:	68 cc 6b 10 f0       	push   $0xf0106bcc
f01027c9:	68 8a 6d 10 f0       	push   $0xf0106d8a
f01027ce:	68 55 03 00 00       	push   $0x355
f01027d3:	68 55 6d 10 f0       	push   $0xf0106d55
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
f010281d:	68 a8 5e 10 f0       	push   $0xf0105ea8
f0102822:	68 5d 03 00 00       	push   $0x35d
f0102827:	68 55 6d 10 f0       	push   $0xf0106d55
f010282c:	e8 0f d8 ff ff       	call   f0100040 <_panic>
f0102831:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0102834:	8d 94 0b 00 c0 22 f0 	lea    -0xfdd4000(%ebx,%ecx,1),%edx
f010283b:	39 d0                	cmp    %edx,%eax
f010283d:	74 19                	je     f0102858 <mem_init+0x1571>
f010283f:	68 f4 6b 10 f0       	push   $0xf0106bf4
f0102844:	68 8a 6d 10 f0       	push   $0xf0106d8a
f0102849:	68 5d 03 00 00       	push   $0x35d
f010284e:	68 55 6d 10 f0       	push   $0xf0106d55
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
f010287f:	68 3c 6c 10 f0       	push   $0xf0106c3c
f0102884:	68 8a 6d 10 f0       	push   $0xf0106d8a
f0102889:	68 5f 03 00 00       	push   $0x35f
f010288e:	68 55 6d 10 f0       	push   $0xf0106d55
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
f01028b9:	b8 00 c0 26 f0       	mov    $0xf026c000,%eax
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
f01028de:	68 46 70 10 f0       	push   $0xf0107046
f01028e3:	68 8a 6d 10 f0       	push   $0xf0106d8a
f01028e8:	68 6a 03 00 00       	push   $0x36a
f01028ed:	68 55 6d 10 f0       	push   $0xf0106d55
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
f0102906:	68 46 70 10 f0       	push   $0xf0107046
f010290b:	68 8a 6d 10 f0       	push   $0xf0106d8a
f0102910:	68 6e 03 00 00       	push   $0x36e
f0102915:	68 55 6d 10 f0       	push   $0xf0106d55
f010291a:	e8 21 d7 ff ff       	call   f0100040 <_panic>
				assert(pgdir[i] & PTE_W);
f010291f:	f6 c2 02             	test   $0x2,%dl
f0102922:	75 38                	jne    f010295c <mem_init+0x1675>
f0102924:	68 57 70 10 f0       	push   $0xf0107057
f0102929:	68 8a 6d 10 f0       	push   $0xf0106d8a
f010292e:	68 6f 03 00 00       	push   $0x36f
f0102933:	68 55 6d 10 f0       	push   $0xf0106d55
f0102938:	e8 03 d7 ff ff       	call   f0100040 <_panic>
			} else
				assert(pgdir[i] == 0);
f010293d:	83 3c 87 00          	cmpl   $0x0,(%edi,%eax,4)
f0102941:	74 19                	je     f010295c <mem_init+0x1675>
f0102943:	68 68 70 10 f0       	push   $0xf0107068
f0102948:	68 8a 6d 10 f0       	push   $0xf0106d8a
f010294d:	68 71 03 00 00       	push   $0x371
f0102952:	68 55 6d 10 f0       	push   $0xf0106d55
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
f010296d:	68 60 6c 10 f0       	push   $0xf0106c60
f0102972:	e8 e0 0c 00 00       	call   f0103657 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f0102977:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
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
f0102987:	68 a8 5e 10 f0       	push   $0xf0105ea8
f010298c:	68 ed 00 00 00       	push   $0xed
f0102991:	68 55 6d 10 f0       	push   $0xf0106d55
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
f01029ce:	68 52 6e 10 f0       	push   $0xf0106e52
f01029d3:	68 8a 6d 10 f0       	push   $0xf0106d8a
f01029d8:	68 49 04 00 00       	push   $0x449
f01029dd:	68 55 6d 10 f0       	push   $0xf0106d55
f01029e2:	e8 59 d6 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f01029e7:	83 ec 0c             	sub    $0xc,%esp
f01029ea:	6a 00                	push   $0x0
f01029ec:	e8 76 e5 ff ff       	call   f0100f67 <page_alloc>
f01029f1:	89 c7                	mov    %eax,%edi
f01029f3:	83 c4 10             	add    $0x10,%esp
f01029f6:	85 c0                	test   %eax,%eax
f01029f8:	75 19                	jne    f0102a13 <mem_init+0x172c>
f01029fa:	68 68 6e 10 f0       	push   $0xf0106e68
f01029ff:	68 8a 6d 10 f0       	push   $0xf0106d8a
f0102a04:	68 4a 04 00 00       	push   $0x44a
f0102a09:	68 55 6d 10 f0       	push   $0xf0106d55
f0102a0e:	e8 2d d6 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0102a13:	83 ec 0c             	sub    $0xc,%esp
f0102a16:	6a 00                	push   $0x0
f0102a18:	e8 4a e5 ff ff       	call   f0100f67 <page_alloc>
f0102a1d:	89 c6                	mov    %eax,%esi
f0102a1f:	83 c4 10             	add    $0x10,%esp
f0102a22:	85 c0                	test   %eax,%eax
f0102a24:	75 19                	jne    f0102a3f <mem_init+0x1758>
f0102a26:	68 7e 6e 10 f0       	push   $0xf0106e7e
f0102a2b:	68 8a 6d 10 f0       	push   $0xf0106d8a
f0102a30:	68 4b 04 00 00       	push   $0x44b
f0102a35:	68 55 6d 10 f0       	push   $0xf0106d55
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
f0102a4a:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
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
f0102a5e:	3b 15 88 ae 22 f0    	cmp    0xf022ae88,%edx
f0102a64:	72 12                	jb     f0102a78 <mem_init+0x1791>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102a66:	50                   	push   %eax
f0102a67:	68 84 5e 10 f0       	push   $0xf0105e84
f0102a6c:	6a 58                	push   $0x58
f0102a6e:	68 70 6d 10 f0       	push   $0xf0106d70
f0102a73:	e8 c8 d5 ff ff       	call   f0100040 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f0102a78:	83 ec 04             	sub    $0x4,%esp
f0102a7b:	68 00 10 00 00       	push   $0x1000
f0102a80:	6a 01                	push   $0x1
f0102a82:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102a87:	50                   	push   %eax
f0102a88:	e8 26 27 00 00       	call   f01051b3 <memset>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102a8d:	89 f0                	mov    %esi,%eax
f0102a8f:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
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
f0102aa3:	3b 15 88 ae 22 f0    	cmp    0xf022ae88,%edx
f0102aa9:	72 12                	jb     f0102abd <mem_init+0x17d6>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102aab:	50                   	push   %eax
f0102aac:	68 84 5e 10 f0       	push   $0xf0105e84
f0102ab1:	6a 58                	push   $0x58
f0102ab3:	68 70 6d 10 f0       	push   $0xf0106d70
f0102ab8:	e8 83 d5 ff ff       	call   f0100040 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f0102abd:	83 ec 04             	sub    $0x4,%esp
f0102ac0:	68 00 10 00 00       	push   $0x1000
f0102ac5:	6a 02                	push   $0x2
f0102ac7:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102acc:	50                   	push   %eax
f0102acd:	e8 e1 26 00 00       	call   f01051b3 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102ad2:	6a 02                	push   $0x2
f0102ad4:	68 00 10 00 00       	push   $0x1000
f0102ad9:	57                   	push   %edi
f0102ada:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0102ae0:	e8 27 e7 ff ff       	call   f010120c <page_insert>
	assert(pp1->pp_ref == 1);
f0102ae5:	83 c4 20             	add    $0x20,%esp
f0102ae8:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102aed:	74 19                	je     f0102b08 <mem_init+0x1821>
f0102aef:	68 4f 6f 10 f0       	push   $0xf0106f4f
f0102af4:	68 8a 6d 10 f0       	push   $0xf0106d8a
f0102af9:	68 50 04 00 00       	push   $0x450
f0102afe:	68 55 6d 10 f0       	push   $0xf0106d55
f0102b03:	e8 38 d5 ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102b08:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102b0f:	01 01 01 
f0102b12:	74 19                	je     f0102b2d <mem_init+0x1846>
f0102b14:	68 80 6c 10 f0       	push   $0xf0106c80
f0102b19:	68 8a 6d 10 f0       	push   $0xf0106d8a
f0102b1e:	68 51 04 00 00       	push   $0x451
f0102b23:	68 55 6d 10 f0       	push   $0xf0106d55
f0102b28:	e8 13 d5 ff ff       	call   f0100040 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102b2d:	6a 02                	push   $0x2
f0102b2f:	68 00 10 00 00       	push   $0x1000
f0102b34:	56                   	push   %esi
f0102b35:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0102b3b:	e8 cc e6 ff ff       	call   f010120c <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102b40:	83 c4 10             	add    $0x10,%esp
f0102b43:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102b4a:	02 02 02 
f0102b4d:	74 19                	je     f0102b68 <mem_init+0x1881>
f0102b4f:	68 a4 6c 10 f0       	push   $0xf0106ca4
f0102b54:	68 8a 6d 10 f0       	push   $0xf0106d8a
f0102b59:	68 53 04 00 00       	push   $0x453
f0102b5e:	68 55 6d 10 f0       	push   $0xf0106d55
f0102b63:	e8 d8 d4 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0102b68:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102b6d:	74 19                	je     f0102b88 <mem_init+0x18a1>
f0102b6f:	68 71 6f 10 f0       	push   $0xf0106f71
f0102b74:	68 8a 6d 10 f0       	push   $0xf0106d8a
f0102b79:	68 54 04 00 00       	push   $0x454
f0102b7e:	68 55 6d 10 f0       	push   $0xf0106d55
f0102b83:	e8 b8 d4 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f0102b88:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102b8d:	74 19                	je     f0102ba8 <mem_init+0x18c1>
f0102b8f:	68 db 6f 10 f0       	push   $0xf0106fdb
f0102b94:	68 8a 6d 10 f0       	push   $0xf0106d8a
f0102b99:	68 55 04 00 00       	push   $0x455
f0102b9e:	68 55 6d 10 f0       	push   $0xf0106d55
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
f0102bb4:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f0102bba:	c1 f8 03             	sar    $0x3,%eax
f0102bbd:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102bc0:	89 c2                	mov    %eax,%edx
f0102bc2:	c1 ea 0c             	shr    $0xc,%edx
f0102bc5:	3b 15 88 ae 22 f0    	cmp    0xf022ae88,%edx
f0102bcb:	72 12                	jb     f0102bdf <mem_init+0x18f8>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102bcd:	50                   	push   %eax
f0102bce:	68 84 5e 10 f0       	push   $0xf0105e84
f0102bd3:	6a 58                	push   $0x58
f0102bd5:	68 70 6d 10 f0       	push   $0xf0106d70
f0102bda:	e8 61 d4 ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102bdf:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102be6:	03 03 03 
f0102be9:	74 19                	je     f0102c04 <mem_init+0x191d>
f0102beb:	68 c8 6c 10 f0       	push   $0xf0106cc8
f0102bf0:	68 8a 6d 10 f0       	push   $0xf0106d8a
f0102bf5:	68 57 04 00 00       	push   $0x457
f0102bfa:	68 55 6d 10 f0       	push   $0xf0106d55
f0102bff:	e8 3c d4 ff ff       	call   f0100040 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102c04:	83 ec 08             	sub    $0x8,%esp
f0102c07:	68 00 10 00 00       	push   $0x1000
f0102c0c:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0102c12:	e8 af e5 ff ff       	call   f01011c6 <page_remove>
	assert(pp2->pp_ref == 0);
f0102c17:	83 c4 10             	add    $0x10,%esp
f0102c1a:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102c1f:	74 19                	je     f0102c3a <mem_init+0x1953>
f0102c21:	68 a9 6f 10 f0       	push   $0xf0106fa9
f0102c26:	68 8a 6d 10 f0       	push   $0xf0106d8a
f0102c2b:	68 59 04 00 00       	push   $0x459
f0102c30:	68 55 6d 10 f0       	push   $0xf0106d55
f0102c35:	e8 06 d4 ff ff       	call   f0100040 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102c3a:	8b 0d 8c ae 22 f0    	mov    0xf022ae8c,%ecx
f0102c40:	8b 11                	mov    (%ecx),%edx
f0102c42:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102c48:	89 d8                	mov    %ebx,%eax
f0102c4a:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f0102c50:	c1 f8 03             	sar    $0x3,%eax
f0102c53:	c1 e0 0c             	shl    $0xc,%eax
f0102c56:	39 c2                	cmp    %eax,%edx
f0102c58:	74 19                	je     f0102c73 <mem_init+0x198c>
f0102c5a:	68 50 66 10 f0       	push   $0xf0106650
f0102c5f:	68 8a 6d 10 f0       	push   $0xf0106d8a
f0102c64:	68 5c 04 00 00       	push   $0x45c
f0102c69:	68 55 6d 10 f0       	push   $0xf0106d55
f0102c6e:	e8 cd d3 ff ff       	call   f0100040 <_panic>
	kern_pgdir[0] = 0;
f0102c73:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102c79:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102c7e:	74 19                	je     f0102c99 <mem_init+0x19b2>
f0102c80:	68 60 6f 10 f0       	push   $0xf0106f60
f0102c85:	68 8a 6d 10 f0       	push   $0xf0106d8a
f0102c8a:	68 5e 04 00 00       	push   $0x45e
f0102c8f:	68 55 6d 10 f0       	push   $0xf0106d55
f0102c94:	e8 a7 d3 ff ff       	call   f0100040 <_panic>
	pp0->pp_ref = 0;
f0102c99:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f0102c9f:	83 ec 0c             	sub    $0xc,%esp
f0102ca2:	53                   	push   %ebx
f0102ca3:	e8 36 e3 ff ff       	call   f0100fde <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102ca8:	c7 04 24 f4 6c 10 f0 	movl   $0xf0106cf4,(%esp)
f0102caf:	e8 a3 09 00 00       	call   f0103657 <cprintf>
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
f0102ce9:	89 1d 3c a2 22 f0    	mov    %ebx,0xf022a23c
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
f0102d1b:	a3 3c a2 22 f0       	mov    %eax,0xf022a23c
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
f0102d6c:	ff 35 3c a2 22 f0    	pushl  0xf022a23c
f0102d72:	ff 73 48             	pushl  0x48(%ebx)
f0102d75:	68 20 6d 10 f0       	push   $0xf0106d20
f0102d7a:	e8 d8 08 00 00       	call   f0103657 <cprintf>
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
f0102d7f:	89 1c 24             	mov    %ebx,(%esp)
f0102d82:	e8 fb 05 00 00       	call   f0103382 <env_destroy>
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
f0102dc5:	68 76 70 10 f0       	push   $0xf0107076
f0102dca:	68 29 01 00 00       	push   $0x129
f0102dcf:	68 8a 70 10 f0       	push   $0xf010708a
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
f0102e09:	e8 c8 29 00 00       	call   f01057d6 <cpunum>
f0102e0e:	6b c0 74             	imul   $0x74,%eax,%eax
f0102e11:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
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
f0102e2e:	03 1d 44 a2 22 f0    	add    0xf022a244,%ebx
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
f0102e53:	e8 7e 29 00 00       	call   f01057d6 <cpunum>
f0102e58:	6b c0 74             	imul   $0x74,%eax,%eax
f0102e5b:	3b 98 28 b0 22 f0    	cmp    -0xfdd4fd8(%eax),%ebx
f0102e61:	74 26                	je     f0102e89 <envid2env+0x8f>
f0102e63:	8b 73 4c             	mov    0x4c(%ebx),%esi
f0102e66:	e8 6b 29 00 00       	call   f01057d6 <cpunum>
f0102e6b:	6b c0 74             	imul   $0x74,%eax,%eax
f0102e6e:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
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
f0102e9a:	b8 20 f3 11 f0       	mov    $0xf011f320,%eax
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
f0102ecc:	8b 35 44 a2 22 f0    	mov    0xf022a244,%esi
f0102ed2:	8b 15 48 a2 22 f0    	mov    0xf022a248,%edx
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
f0102efd:	89 35 48 a2 22 f0    	mov    %esi,0xf022a248
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
f0102f13:	8b 1d 48 a2 22 f0    	mov    0xf022a248,%ebx
f0102f19:	85 db                	test   %ebx,%ebx
f0102f1b:	0f 84 67 01 00 00    	je     f0103088 <env_alloc+0x17c>
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
f0102f30:	0f 84 59 01 00 00    	je     f010308f <env_alloc+0x183>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102f36:	89 c2                	mov    %eax,%edx
f0102f38:	2b 15 90 ae 22 f0    	sub    0xf022ae90,%edx
f0102f3e:	c1 fa 03             	sar    $0x3,%edx
f0102f41:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102f44:	89 d1                	mov    %edx,%ecx
f0102f46:	c1 e9 0c             	shr    $0xc,%ecx
f0102f49:	3b 0d 88 ae 22 f0    	cmp    0xf022ae88,%ecx
f0102f4f:	72 12                	jb     f0102f63 <env_alloc+0x57>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102f51:	52                   	push   %edx
f0102f52:	68 84 5e 10 f0       	push   $0xf0105e84
f0102f57:	6a 58                	push   $0x58
f0102f59:	68 70 6d 10 f0       	push   $0xf0106d70
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
f0102f79:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0102f7f:	ff 73 60             	pushl  0x60(%ebx)
f0102f82:	e8 e1 22 00 00       	call   f0105268 <memcpy>

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
f0102f95:	68 a8 5e 10 f0       	push   $0xf0105ea8
f0102f9a:	68 c5 00 00 00       	push   $0xc5
f0102f9f:	68 8a 70 10 f0       	push   $0xf010708a
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
f0102fcf:	2b 15 44 a2 22 f0    	sub    0xf022a244,%edx
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
f0103006:	e8 a8 21 00 00       	call   f01051b3 <memset>
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

	// Enable interrupts while in user mode.
	// LAB 4: Your code here.

	// Clear the page fault handler until user installs one.
	e->env_pgfault_upcall = 0;
f010302a:	c7 43 64 00 00 00 00 	movl   $0x0,0x64(%ebx)

	// Also clear the IPC receiving flag.
	e->env_ipc_recving = 0;
f0103031:	c6 43 68 00          	movb   $0x0,0x68(%ebx)

	// commit the allocation
	env_free_list = e->env_link;
f0103035:	8b 43 44             	mov    0x44(%ebx),%eax
f0103038:	a3 48 a2 22 f0       	mov    %eax,0xf022a248
	*newenv_store = e;
f010303d:	8b 45 08             	mov    0x8(%ebp),%eax
f0103040:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0103042:	8b 5b 48             	mov    0x48(%ebx),%ebx
f0103045:	e8 8c 27 00 00       	call   f01057d6 <cpunum>
f010304a:	6b c0 74             	imul   $0x74,%eax,%eax
f010304d:	83 c4 10             	add    $0x10,%esp
f0103050:	ba 00 00 00 00       	mov    $0x0,%edx
f0103055:	83 b8 28 b0 22 f0 00 	cmpl   $0x0,-0xfdd4fd8(%eax)
f010305c:	74 11                	je     f010306f <env_alloc+0x163>
f010305e:	e8 73 27 00 00       	call   f01057d6 <cpunum>
f0103063:	6b c0 74             	imul   $0x74,%eax,%eax
f0103066:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f010306c:	8b 50 48             	mov    0x48(%eax),%edx
f010306f:	83 ec 04             	sub    $0x4,%esp
f0103072:	53                   	push   %ebx
f0103073:	52                   	push   %edx
f0103074:	68 95 70 10 f0       	push   $0xf0107095
f0103079:	e8 d9 05 00 00       	call   f0103657 <cprintf>
	return 0;
f010307e:	83 c4 10             	add    $0x10,%esp
f0103081:	b8 00 00 00 00       	mov    $0x0,%eax
f0103086:	eb 0c                	jmp    f0103094 <env_alloc+0x188>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f0103088:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f010308d:	eb 05                	jmp    f0103094 <env_alloc+0x188>
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f010308f:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	env_free_list = e->env_link;
	*newenv_store = e;

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f0103094:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103097:	c9                   	leave  
f0103098:	c3                   	ret    

f0103099 <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f0103099:	55                   	push   %ebp
f010309a:	89 e5                	mov    %esp,%ebp
f010309c:	57                   	push   %edi
f010309d:	56                   	push   %esi
f010309e:	53                   	push   %ebx
f010309f:	83 ec 34             	sub    $0x34,%esp
f01030a2:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.
	struct Env *e;
	env_alloc(&e, 0);
f01030a5:	6a 00                	push   $0x0
f01030a7:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01030aa:	50                   	push   %eax
f01030ab:	e8 5c fe ff ff       	call   f0102f0c <env_alloc>
	load_icode(e, binary);
f01030b0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01030b3:	89 45 d4             	mov    %eax,-0x2c(%ebp)

	// LAB 3: Your code here.
	
	struct Elf *elf = (struct Elf *) binary;

	if (elf->e_magic != ELF_MAGIC)
f01030b6:	83 c4 10             	add    $0x10,%esp
f01030b9:	81 3f 7f 45 4c 46    	cmpl   $0x464c457f,(%edi)
f01030bf:	74 17                	je     f01030d8 <env_create+0x3f>
		panic("load_icode: not ELF executable.");
f01030c1:	83 ec 04             	sub    $0x4,%esp
f01030c4:	68 cc 70 10 f0       	push   $0xf01070cc
f01030c9:	68 69 01 00 00       	push   $0x169
f01030ce:	68 8a 70 10 f0       	push   $0xf010708a
f01030d3:	e8 68 cf ff ff       	call   f0100040 <_panic>

	struct Proghdr *ph = (struct Proghdr *) (elf->e_phoff + binary);
f01030d8:	89 fb                	mov    %edi,%ebx
f01030da:	03 5f 1c             	add    0x1c(%edi),%ebx
	struct Proghdr *eph = ph + elf->e_phnum;
f01030dd:	0f b7 77 2c          	movzwl 0x2c(%edi),%esi
f01030e1:	c1 e6 05             	shl    $0x5,%esi
f01030e4:	01 de                	add    %ebx,%esi

	lcr3(PADDR(e->env_pgdir));
f01030e6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01030e9:	8b 40 60             	mov    0x60(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01030ec:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01030f1:	77 15                	ja     f0103108 <env_create+0x6f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01030f3:	50                   	push   %eax
f01030f4:	68 a8 5e 10 f0       	push   $0xf0105ea8
f01030f9:	68 6e 01 00 00       	push   $0x16e
f01030fe:	68 8a 70 10 f0       	push   $0xf010708a
f0103103:	e8 38 cf ff ff       	call   f0100040 <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0103108:	05 00 00 00 10       	add    $0x10000000,%eax
f010310d:	0f 22 d8             	mov    %eax,%cr3
f0103110:	eb 3d                	jmp    f010314f <env_create+0xb6>
	for(; ph < eph; ph++){
		if(ph->p_type == ELF_PROG_LOAD){
f0103112:	83 3b 01             	cmpl   $0x1,(%ebx)
f0103115:	75 35                	jne    f010314c <env_create+0xb3>
			region_alloc(e, (void *) ph->p_va, ph->p_memsz);
f0103117:	8b 4b 14             	mov    0x14(%ebx),%ecx
f010311a:	8b 53 08             	mov    0x8(%ebx),%edx
f010311d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103120:	e8 6a fc ff ff       	call   f0102d8f <region_alloc>
			memset((void *) ph->p_va, 0, ph->p_memsz);
f0103125:	83 ec 04             	sub    $0x4,%esp
f0103128:	ff 73 14             	pushl  0x14(%ebx)
f010312b:	6a 00                	push   $0x0
f010312d:	ff 73 08             	pushl  0x8(%ebx)
f0103130:	e8 7e 20 00 00       	call   f01051b3 <memset>
			memcpy((void *) ph->p_va, binary + ph->p_offset, ph->p_filesz);
f0103135:	83 c4 0c             	add    $0xc,%esp
f0103138:	ff 73 10             	pushl  0x10(%ebx)
f010313b:	89 f8                	mov    %edi,%eax
f010313d:	03 43 04             	add    0x4(%ebx),%eax
f0103140:	50                   	push   %eax
f0103141:	ff 73 08             	pushl  0x8(%ebx)
f0103144:	e8 1f 21 00 00       	call   f0105268 <memcpy>
f0103149:	83 c4 10             	add    $0x10,%esp

	struct Proghdr *ph = (struct Proghdr *) (elf->e_phoff + binary);
	struct Proghdr *eph = ph + elf->e_phnum;

	lcr3(PADDR(e->env_pgdir));
	for(; ph < eph; ph++){
f010314c:	83 c3 20             	add    $0x20,%ebx
f010314f:	39 de                	cmp    %ebx,%esi
f0103151:	77 bf                	ja     f0103112 <env_create+0x79>
			region_alloc(e, (void *) ph->p_va, ph->p_memsz);
			memset((void *) ph->p_va, 0, ph->p_memsz);
			memcpy((void *) ph->p_va, binary + ph->p_offset, ph->p_filesz);
		}
	}
	lcr3(PADDR(kern_pgdir));
f0103153:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103158:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010315d:	77 15                	ja     f0103174 <env_create+0xdb>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010315f:	50                   	push   %eax
f0103160:	68 a8 5e 10 f0       	push   $0xf0105ea8
f0103165:	68 76 01 00 00       	push   $0x176
f010316a:	68 8a 70 10 f0       	push   $0xf010708a
f010316f:	e8 cc ce ff ff       	call   f0100040 <_panic>
f0103174:	05 00 00 00 10       	add    $0x10000000,%eax
f0103179:	0f 22 d8             	mov    %eax,%cr3
	e->env_tf.tf_eip = elf->e_entry;
f010317c:	8b 47 18             	mov    0x18(%edi),%eax
f010317f:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0103182:	89 47 30             	mov    %eax,0x30(%edi)
	// Now map one page for the program's initial stack
	// at virtual address USTACKTOP - PGSIZE.

	// LAB 3: Your code here.
	region_alloc(e, (void *) (USTACKTOP - PGSIZE), PGSIZE);
f0103185:	b9 00 10 00 00       	mov    $0x1000,%ecx
f010318a:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f010318f:	89 f8                	mov    %edi,%eax
f0103191:	e8 f9 fb ff ff       	call   f0102d8f <region_alloc>
{
	// LAB 3: Your code here.
	struct Env *e;
	env_alloc(&e, 0);
	load_icode(e, binary);
	e->env_type = type;
f0103196:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103199:	8b 55 0c             	mov    0xc(%ebp),%edx
f010319c:	89 50 50             	mov    %edx,0x50(%eax)
}
f010319f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01031a2:	5b                   	pop    %ebx
f01031a3:	5e                   	pop    %esi
f01031a4:	5f                   	pop    %edi
f01031a5:	5d                   	pop    %ebp
f01031a6:	c3                   	ret    

f01031a7 <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f01031a7:	55                   	push   %ebp
f01031a8:	89 e5                	mov    %esp,%ebp
f01031aa:	57                   	push   %edi
f01031ab:	56                   	push   %esi
f01031ac:	53                   	push   %ebx
f01031ad:	83 ec 1c             	sub    $0x1c,%esp
f01031b0:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f01031b3:	e8 1e 26 00 00       	call   f01057d6 <cpunum>
f01031b8:	6b c0 74             	imul   $0x74,%eax,%eax
f01031bb:	39 b8 28 b0 22 f0    	cmp    %edi,-0xfdd4fd8(%eax)
f01031c1:	75 29                	jne    f01031ec <env_free+0x45>
		lcr3(PADDR(kern_pgdir));
f01031c3:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01031c8:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01031cd:	77 15                	ja     f01031e4 <env_free+0x3d>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01031cf:	50                   	push   %eax
f01031d0:	68 a8 5e 10 f0       	push   $0xf0105ea8
f01031d5:	68 9f 01 00 00       	push   $0x19f
f01031da:	68 8a 70 10 f0       	push   $0xf010708a
f01031df:	e8 5c ce ff ff       	call   f0100040 <_panic>
f01031e4:	05 00 00 00 10       	add    $0x10000000,%eax
f01031e9:	0f 22 d8             	mov    %eax,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f01031ec:	8b 5f 48             	mov    0x48(%edi),%ebx
f01031ef:	e8 e2 25 00 00       	call   f01057d6 <cpunum>
f01031f4:	6b c0 74             	imul   $0x74,%eax,%eax
f01031f7:	ba 00 00 00 00       	mov    $0x0,%edx
f01031fc:	83 b8 28 b0 22 f0 00 	cmpl   $0x0,-0xfdd4fd8(%eax)
f0103203:	74 11                	je     f0103216 <env_free+0x6f>
f0103205:	e8 cc 25 00 00       	call   f01057d6 <cpunum>
f010320a:	6b c0 74             	imul   $0x74,%eax,%eax
f010320d:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0103213:	8b 50 48             	mov    0x48(%eax),%edx
f0103216:	83 ec 04             	sub    $0x4,%esp
f0103219:	53                   	push   %ebx
f010321a:	52                   	push   %edx
f010321b:	68 aa 70 10 f0       	push   $0xf01070aa
f0103220:	e8 32 04 00 00       	call   f0103657 <cprintf>
f0103225:	83 c4 10             	add    $0x10,%esp

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0103228:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f010322f:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0103232:	89 d0                	mov    %edx,%eax
f0103234:	c1 e0 02             	shl    $0x2,%eax
f0103237:	89 45 dc             	mov    %eax,-0x24(%ebp)

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f010323a:	8b 47 60             	mov    0x60(%edi),%eax
f010323d:	8b 34 90             	mov    (%eax,%edx,4),%esi
f0103240:	f7 c6 01 00 00 00    	test   $0x1,%esi
f0103246:	0f 84 a8 00 00 00    	je     f01032f4 <env_free+0x14d>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f010324c:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103252:	89 f0                	mov    %esi,%eax
f0103254:	c1 e8 0c             	shr    $0xc,%eax
f0103257:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010325a:	39 05 88 ae 22 f0    	cmp    %eax,0xf022ae88
f0103260:	77 15                	ja     f0103277 <env_free+0xd0>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0103262:	56                   	push   %esi
f0103263:	68 84 5e 10 f0       	push   $0xf0105e84
f0103268:	68 ae 01 00 00       	push   $0x1ae
f010326d:	68 8a 70 10 f0       	push   $0xf010708a
f0103272:	e8 c9 cd ff ff       	call   f0100040 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0103277:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010327a:	c1 e0 16             	shl    $0x16,%eax
f010327d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0103280:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f0103285:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f010328c:	01 
f010328d:	74 17                	je     f01032a6 <env_free+0xff>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f010328f:	83 ec 08             	sub    $0x8,%esp
f0103292:	89 d8                	mov    %ebx,%eax
f0103294:	c1 e0 0c             	shl    $0xc,%eax
f0103297:	0b 45 e4             	or     -0x1c(%ebp),%eax
f010329a:	50                   	push   %eax
f010329b:	ff 77 60             	pushl  0x60(%edi)
f010329e:	e8 23 df ff ff       	call   f01011c6 <page_remove>
f01032a3:	83 c4 10             	add    $0x10,%esp
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f01032a6:	83 c3 01             	add    $0x1,%ebx
f01032a9:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f01032af:	75 d4                	jne    f0103285 <env_free+0xde>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f01032b1:	8b 47 60             	mov    0x60(%edi),%eax
f01032b4:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01032b7:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01032be:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01032c1:	3b 05 88 ae 22 f0    	cmp    0xf022ae88,%eax
f01032c7:	72 14                	jb     f01032dd <env_free+0x136>
		panic("pa2page called with invalid pa");
f01032c9:	83 ec 04             	sub    $0x4,%esp
f01032cc:	68 f0 64 10 f0       	push   $0xf01064f0
f01032d1:	6a 51                	push   $0x51
f01032d3:	68 70 6d 10 f0       	push   $0xf0106d70
f01032d8:	e8 63 cd ff ff       	call   f0100040 <_panic>
		page_decref(pa2page(pa));
f01032dd:	83 ec 0c             	sub    $0xc,%esp
f01032e0:	a1 90 ae 22 f0       	mov    0xf022ae90,%eax
f01032e5:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01032e8:	8d 04 d0             	lea    (%eax,%edx,8),%eax
f01032eb:	50                   	push   %eax
f01032ec:	e8 28 dd ff ff       	call   f0101019 <page_decref>
f01032f1:	83 c4 10             	add    $0x10,%esp
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f01032f4:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f01032f8:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01032fb:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f0103300:	0f 85 29 ff ff ff    	jne    f010322f <env_free+0x88>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f0103306:	8b 47 60             	mov    0x60(%edi),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103309:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010330e:	77 15                	ja     f0103325 <env_free+0x17e>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103310:	50                   	push   %eax
f0103311:	68 a8 5e 10 f0       	push   $0xf0105ea8
f0103316:	68 bc 01 00 00       	push   $0x1bc
f010331b:	68 8a 70 10 f0       	push   $0xf010708a
f0103320:	e8 1b cd ff ff       	call   f0100040 <_panic>
	e->env_pgdir = 0;
f0103325:	c7 47 60 00 00 00 00 	movl   $0x0,0x60(%edi)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010332c:	05 00 00 00 10       	add    $0x10000000,%eax
f0103331:	c1 e8 0c             	shr    $0xc,%eax
f0103334:	3b 05 88 ae 22 f0    	cmp    0xf022ae88,%eax
f010333a:	72 14                	jb     f0103350 <env_free+0x1a9>
		panic("pa2page called with invalid pa");
f010333c:	83 ec 04             	sub    $0x4,%esp
f010333f:	68 f0 64 10 f0       	push   $0xf01064f0
f0103344:	6a 51                	push   $0x51
f0103346:	68 70 6d 10 f0       	push   $0xf0106d70
f010334b:	e8 f0 cc ff ff       	call   f0100040 <_panic>
	page_decref(pa2page(pa));
f0103350:	83 ec 0c             	sub    $0xc,%esp
f0103353:	8b 15 90 ae 22 f0    	mov    0xf022ae90,%edx
f0103359:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f010335c:	50                   	push   %eax
f010335d:	e8 b7 dc ff ff       	call   f0101019 <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f0103362:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f0103369:	a1 48 a2 22 f0       	mov    0xf022a248,%eax
f010336e:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f0103371:	89 3d 48 a2 22 f0    	mov    %edi,0xf022a248
}
f0103377:	83 c4 10             	add    $0x10,%esp
f010337a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010337d:	5b                   	pop    %ebx
f010337e:	5e                   	pop    %esi
f010337f:	5f                   	pop    %edi
f0103380:	5d                   	pop    %ebp
f0103381:	c3                   	ret    

f0103382 <env_destroy>:
// If e was the current env, then runs a new environment (and does not return
// to the caller).
//
void
env_destroy(struct Env *e)
{
f0103382:	55                   	push   %ebp
f0103383:	89 e5                	mov    %esp,%ebp
f0103385:	53                   	push   %ebx
f0103386:	83 ec 04             	sub    $0x4,%esp
f0103389:	8b 5d 08             	mov    0x8(%ebp),%ebx
	// If e is currently running on other CPUs, we change its state to
	// ENV_DYING. A zombie environment will be freed the next time
	// it traps to the kernel.
	if (e->env_status == ENV_RUNNING && curenv != e) {
f010338c:	83 7b 54 03          	cmpl   $0x3,0x54(%ebx)
f0103390:	75 19                	jne    f01033ab <env_destroy+0x29>
f0103392:	e8 3f 24 00 00       	call   f01057d6 <cpunum>
f0103397:	6b c0 74             	imul   $0x74,%eax,%eax
f010339a:	3b 98 28 b0 22 f0    	cmp    -0xfdd4fd8(%eax),%ebx
f01033a0:	74 09                	je     f01033ab <env_destroy+0x29>
		e->env_status = ENV_DYING;
f01033a2:	c7 43 54 01 00 00 00 	movl   $0x1,0x54(%ebx)
		return;
f01033a9:	eb 33                	jmp    f01033de <env_destroy+0x5c>
	}

	env_free(e);
f01033ab:	83 ec 0c             	sub    $0xc,%esp
f01033ae:	53                   	push   %ebx
f01033af:	e8 f3 fd ff ff       	call   f01031a7 <env_free>

	if (curenv == e) {
f01033b4:	e8 1d 24 00 00       	call   f01057d6 <cpunum>
f01033b9:	6b c0 74             	imul   $0x74,%eax,%eax
f01033bc:	83 c4 10             	add    $0x10,%esp
f01033bf:	3b 98 28 b0 22 f0    	cmp    -0xfdd4fd8(%eax),%ebx
f01033c5:	75 17                	jne    f01033de <env_destroy+0x5c>
		curenv = NULL;
f01033c7:	e8 0a 24 00 00       	call   f01057d6 <cpunum>
f01033cc:	6b c0 74             	imul   $0x74,%eax,%eax
f01033cf:	c7 80 28 b0 22 f0 00 	movl   $0x0,-0xfdd4fd8(%eax)
f01033d6:	00 00 00 
		sched_yield();
f01033d9:	e8 b9 0d 00 00       	call   f0104197 <sched_yield>
	}
}
f01033de:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01033e1:	c9                   	leave  
f01033e2:	c3                   	ret    

f01033e3 <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f01033e3:	55                   	push   %ebp
f01033e4:	89 e5                	mov    %esp,%ebp
f01033e6:	53                   	push   %ebx
f01033e7:	83 ec 04             	sub    $0x4,%esp
	// Record the CPU we are running on for user-space debugging
	curenv->env_cpunum = cpunum();
f01033ea:	e8 e7 23 00 00       	call   f01057d6 <cpunum>
f01033ef:	6b c0 74             	imul   $0x74,%eax,%eax
f01033f2:	8b 98 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%ebx
f01033f8:	e8 d9 23 00 00       	call   f01057d6 <cpunum>
f01033fd:	89 43 5c             	mov    %eax,0x5c(%ebx)

	asm volatile(
f0103400:	8b 65 08             	mov    0x8(%ebp),%esp
f0103403:	61                   	popa   
f0103404:	07                   	pop    %es
f0103405:	1f                   	pop    %ds
f0103406:	83 c4 08             	add    $0x8,%esp
f0103409:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret\n"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f010340a:	83 ec 04             	sub    $0x4,%esp
f010340d:	68 c0 70 10 f0       	push   $0xf01070c0
f0103412:	68 f3 01 00 00       	push   $0x1f3
f0103417:	68 8a 70 10 f0       	push   $0xf010708a
f010341c:	e8 1f cc ff ff       	call   f0100040 <_panic>

f0103421 <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f0103421:	55                   	push   %ebp
f0103422:	89 e5                	mov    %esp,%ebp
f0103424:	53                   	push   %ebx
f0103425:	83 ec 04             	sub    $0x4,%esp
f0103428:	8b 5d 08             	mov    0x8(%ebp),%ebx
	//	e->env_tf.  Go back through the code you wrote above
	//	and make sure you have set the relevant parts of
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.
	if(curenv != NULL){
f010342b:	e8 a6 23 00 00       	call   f01057d6 <cpunum>
f0103430:	6b c0 74             	imul   $0x74,%eax,%eax
f0103433:	83 b8 28 b0 22 f0 00 	cmpl   $0x0,-0xfdd4fd8(%eax)
f010343a:	74 29                	je     f0103465 <env_run+0x44>
		if(curenv->env_status == ENV_RUNNING)
f010343c:	e8 95 23 00 00       	call   f01057d6 <cpunum>
f0103441:	6b c0 74             	imul   $0x74,%eax,%eax
f0103444:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f010344a:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f010344e:	75 15                	jne    f0103465 <env_run+0x44>
			curenv->env_status = ENV_RUNNABLE;
f0103450:	e8 81 23 00 00       	call   f01057d6 <cpunum>
f0103455:	6b c0 74             	imul   $0x74,%eax,%eax
f0103458:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f010345e:	c7 40 54 02 00 00 00 	movl   $0x2,0x54(%eax)
	}
	curenv = e;
f0103465:	e8 6c 23 00 00       	call   f01057d6 <cpunum>
f010346a:	6b c0 74             	imul   $0x74,%eax,%eax
f010346d:	89 98 28 b0 22 f0    	mov    %ebx,-0xfdd4fd8(%eax)
	curenv->env_status = ENV_RUNNING;
f0103473:	e8 5e 23 00 00       	call   f01057d6 <cpunum>
f0103478:	6b c0 74             	imul   $0x74,%eax,%eax
f010347b:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0103481:	c7 40 54 03 00 00 00 	movl   $0x3,0x54(%eax)
	curenv->env_runs ++;
f0103488:	e8 49 23 00 00       	call   f01057d6 <cpunum>
f010348d:	6b c0 74             	imul   $0x74,%eax,%eax
f0103490:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0103496:	83 40 58 01          	addl   $0x1,0x58(%eax)
	lcr3(PADDR(e->env_pgdir));
f010349a:	8b 43 60             	mov    0x60(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010349d:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01034a2:	77 15                	ja     f01034b9 <env_run+0x98>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01034a4:	50                   	push   %eax
f01034a5:	68 a8 5e 10 f0       	push   $0xf0105ea8
f01034aa:	68 18 02 00 00       	push   $0x218
f01034af:	68 8a 70 10 f0       	push   $0xf010708a
f01034b4:	e8 87 cb ff ff       	call   f0100040 <_panic>
f01034b9:	05 00 00 00 10       	add    $0x10000000,%eax
f01034be:	0f 22 d8             	mov    %eax,%cr3
}

static inline void
unlock_kernel(void)
{
	spin_unlock(&kernel_lock);
f01034c1:	83 ec 0c             	sub    $0xc,%esp
f01034c4:	68 c0 f3 11 f0       	push   $0xf011f3c0
f01034c9:	e8 13 26 00 00       	call   f0105ae1 <spin_unlock>

	// Normally we wouldn't need to do this, but QEMU only runs
	// one CPU at a time and has a long time-slice.  Without the
	// pause, this CPU is likely to reacquire the lock before
	// another CPU has even been given a chance to acquire it.
	asm volatile("pause");
f01034ce:	f3 90                	pause  
    unlock_kernel();
	env_pop_tf(&e->env_tf);
f01034d0:	89 1c 24             	mov    %ebx,(%esp)
f01034d3:	e8 0b ff ff ff       	call   f01033e3 <env_pop_tf>

f01034d8 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f01034d8:	55                   	push   %ebp
f01034d9:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01034db:	ba 70 00 00 00       	mov    $0x70,%edx
f01034e0:	8b 45 08             	mov    0x8(%ebp),%eax
f01034e3:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01034e4:	ba 71 00 00 00       	mov    $0x71,%edx
f01034e9:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f01034ea:	0f b6 c0             	movzbl %al,%eax
}
f01034ed:	5d                   	pop    %ebp
f01034ee:	c3                   	ret    

f01034ef <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f01034ef:	55                   	push   %ebp
f01034f0:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01034f2:	ba 70 00 00 00       	mov    $0x70,%edx
f01034f7:	8b 45 08             	mov    0x8(%ebp),%eax
f01034fa:	ee                   	out    %al,(%dx)
f01034fb:	ba 71 00 00 00       	mov    $0x71,%edx
f0103500:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103503:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0103504:	5d                   	pop    %ebp
f0103505:	c3                   	ret    

f0103506 <irq_setmask_8259A>:
		irq_setmask_8259A(irq_mask_8259A);
}

void
irq_setmask_8259A(uint16_t mask)
{
f0103506:	55                   	push   %ebp
f0103507:	89 e5                	mov    %esp,%ebp
f0103509:	56                   	push   %esi
f010350a:	53                   	push   %ebx
f010350b:	8b 45 08             	mov    0x8(%ebp),%eax
	int i;
	irq_mask_8259A = mask;
f010350e:	66 a3 a8 f3 11 f0    	mov    %ax,0xf011f3a8
	if (!didinit)
f0103514:	80 3d 4c a2 22 f0 00 	cmpb   $0x0,0xf022a24c
f010351b:	74 5a                	je     f0103577 <irq_setmask_8259A+0x71>
f010351d:	89 c6                	mov    %eax,%esi
f010351f:	ba 21 00 00 00       	mov    $0x21,%edx
f0103524:	ee                   	out    %al,(%dx)
f0103525:	66 c1 e8 08          	shr    $0x8,%ax
f0103529:	ba a1 00 00 00       	mov    $0xa1,%edx
f010352e:	ee                   	out    %al,(%dx)
		return;
	outb(IO_PIC1+1, (char)mask);
	outb(IO_PIC2+1, (char)(mask >> 8));
	cprintf("enabled interrupts:");
f010352f:	83 ec 0c             	sub    $0xc,%esp
f0103532:	68 ec 70 10 f0       	push   $0xf01070ec
f0103537:	e8 1b 01 00 00       	call   f0103657 <cprintf>
f010353c:	83 c4 10             	add    $0x10,%esp
	for (i = 0; i < 16; i++)
f010353f:	bb 00 00 00 00       	mov    $0x0,%ebx
		if (~mask & (1<<i))
f0103544:	0f b7 f6             	movzwl %si,%esi
f0103547:	f7 d6                	not    %esi
f0103549:	0f a3 de             	bt     %ebx,%esi
f010354c:	73 11                	jae    f010355f <irq_setmask_8259A+0x59>
			cprintf(" %d", i);
f010354e:	83 ec 08             	sub    $0x8,%esp
f0103551:	53                   	push   %ebx
f0103552:	68 4e 76 10 f0       	push   $0xf010764e
f0103557:	e8 fb 00 00 00       	call   f0103657 <cprintf>
f010355c:	83 c4 10             	add    $0x10,%esp
	if (!didinit)
		return;
	outb(IO_PIC1+1, (char)mask);
	outb(IO_PIC2+1, (char)(mask >> 8));
	cprintf("enabled interrupts:");
	for (i = 0; i < 16; i++)
f010355f:	83 c3 01             	add    $0x1,%ebx
f0103562:	83 fb 10             	cmp    $0x10,%ebx
f0103565:	75 e2                	jne    f0103549 <irq_setmask_8259A+0x43>
		if (~mask & (1<<i))
			cprintf(" %d", i);
	cprintf("\n");
f0103567:	83 ec 0c             	sub    $0xc,%esp
f010356a:	68 44 70 10 f0       	push   $0xf0107044
f010356f:	e8 e3 00 00 00       	call   f0103657 <cprintf>
f0103574:	83 c4 10             	add    $0x10,%esp
}
f0103577:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010357a:	5b                   	pop    %ebx
f010357b:	5e                   	pop    %esi
f010357c:	5d                   	pop    %ebp
f010357d:	c3                   	ret    

f010357e <pic_init>:

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
	didinit = 1;
f010357e:	c6 05 4c a2 22 f0 01 	movb   $0x1,0xf022a24c
f0103585:	ba 21 00 00 00       	mov    $0x21,%edx
f010358a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010358f:	ee                   	out    %al,(%dx)
f0103590:	ba a1 00 00 00       	mov    $0xa1,%edx
f0103595:	ee                   	out    %al,(%dx)
f0103596:	ba 20 00 00 00       	mov    $0x20,%edx
f010359b:	b8 11 00 00 00       	mov    $0x11,%eax
f01035a0:	ee                   	out    %al,(%dx)
f01035a1:	ba 21 00 00 00       	mov    $0x21,%edx
f01035a6:	b8 20 00 00 00       	mov    $0x20,%eax
f01035ab:	ee                   	out    %al,(%dx)
f01035ac:	b8 04 00 00 00       	mov    $0x4,%eax
f01035b1:	ee                   	out    %al,(%dx)
f01035b2:	b8 03 00 00 00       	mov    $0x3,%eax
f01035b7:	ee                   	out    %al,(%dx)
f01035b8:	ba a0 00 00 00       	mov    $0xa0,%edx
f01035bd:	b8 11 00 00 00       	mov    $0x11,%eax
f01035c2:	ee                   	out    %al,(%dx)
f01035c3:	ba a1 00 00 00       	mov    $0xa1,%edx
f01035c8:	b8 28 00 00 00       	mov    $0x28,%eax
f01035cd:	ee                   	out    %al,(%dx)
f01035ce:	b8 02 00 00 00       	mov    $0x2,%eax
f01035d3:	ee                   	out    %al,(%dx)
f01035d4:	b8 01 00 00 00       	mov    $0x1,%eax
f01035d9:	ee                   	out    %al,(%dx)
f01035da:	ba 20 00 00 00       	mov    $0x20,%edx
f01035df:	b8 68 00 00 00       	mov    $0x68,%eax
f01035e4:	ee                   	out    %al,(%dx)
f01035e5:	b8 0a 00 00 00       	mov    $0xa,%eax
f01035ea:	ee                   	out    %al,(%dx)
f01035eb:	ba a0 00 00 00       	mov    $0xa0,%edx
f01035f0:	b8 68 00 00 00       	mov    $0x68,%eax
f01035f5:	ee                   	out    %al,(%dx)
f01035f6:	b8 0a 00 00 00       	mov    $0xa,%eax
f01035fb:	ee                   	out    %al,(%dx)
	outb(IO_PIC1, 0x0a);             /* read IRR by default */

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irq_mask_8259A != 0xFFFF)
f01035fc:	0f b7 05 a8 f3 11 f0 	movzwl 0xf011f3a8,%eax
f0103603:	66 83 f8 ff          	cmp    $0xffff,%ax
f0103607:	74 13                	je     f010361c <pic_init+0x9e>
static bool didinit;

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
f0103609:	55                   	push   %ebp
f010360a:	89 e5                	mov    %esp,%ebp
f010360c:	83 ec 14             	sub    $0x14,%esp

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irq_mask_8259A != 0xFFFF)
		irq_setmask_8259A(irq_mask_8259A);
f010360f:	0f b7 c0             	movzwl %ax,%eax
f0103612:	50                   	push   %eax
f0103613:	e8 ee fe ff ff       	call   f0103506 <irq_setmask_8259A>
f0103618:	83 c4 10             	add    $0x10,%esp
}
f010361b:	c9                   	leave  
f010361c:	f3 c3                	repz ret 

f010361e <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f010361e:	55                   	push   %ebp
f010361f:	89 e5                	mov    %esp,%ebp
f0103621:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0103624:	ff 75 08             	pushl  0x8(%ebp)
f0103627:	e8 38 d1 ff ff       	call   f0100764 <cputchar>
	*cnt++;
}
f010362c:	83 c4 10             	add    $0x10,%esp
f010362f:	c9                   	leave  
f0103630:	c3                   	ret    

f0103631 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0103631:	55                   	push   %ebp
f0103632:	89 e5                	mov    %esp,%ebp
f0103634:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0103637:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f010363e:	ff 75 0c             	pushl  0xc(%ebp)
f0103641:	ff 75 08             	pushl  0x8(%ebp)
f0103644:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0103647:	50                   	push   %eax
f0103648:	68 1e 36 10 f0       	push   $0xf010361e
f010364d:	e8 f5 14 00 00       	call   f0104b47 <vprintfmt>
	return cnt;
}
f0103652:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103655:	c9                   	leave  
f0103656:	c3                   	ret    

f0103657 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0103657:	55                   	push   %ebp
f0103658:	89 e5                	mov    %esp,%ebp
f010365a:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f010365d:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0103660:	50                   	push   %eax
f0103661:	ff 75 08             	pushl  0x8(%ebp)
f0103664:	e8 c8 ff ff ff       	call   f0103631 <vcprintf>
	va_end(ap);

	return cnt;
}
f0103669:	c9                   	leave  
f010366a:	c3                   	ret    

f010366b <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f010366b:	55                   	push   %ebp
f010366c:	89 e5                	mov    %esp,%ebp
f010366e:	57                   	push   %edi
f010366f:	56                   	push   %esi
f0103670:	53                   	push   %ebx
f0103671:	83 ec 1c             	sub    $0x1c,%esp
	// get a triple fault.  If you set up an individual CPU's TSS
	// wrong, you may not get a fault until you try to return from
	// user space on that CPU.
	//
	// LAB 4: Your code here:
    int i = cpunum();
f0103674:	e8 5d 21 00 00       	call   f01057d6 <cpunum>
f0103679:	89 c6                	mov    %eax,%esi
	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.

	thiscpu->cpu_ts.ts_esp0 = (uintptr_t)percpu_kstacks[i];
f010367b:	e8 56 21 00 00       	call   f01057d6 <cpunum>
f0103680:	6b c0 74             	imul   $0x74,%eax,%eax
f0103683:	89 f2                	mov    %esi,%edx
f0103685:	c1 e2 0f             	shl    $0xf,%edx
f0103688:	81 c2 00 c0 22 f0    	add    $0xf022c000,%edx
f010368e:	89 90 30 b0 22 f0    	mov    %edx,-0xfdd4fd0(%eax)
	//thiscpu->cpu_ts.ts_esp0 = KSTACKTOP - i * (KSTKSIZE + KSTKGAP);
	thiscpu->cpu_ts.ts_ss0 = GD_KD;
f0103694:	e8 3d 21 00 00       	call   f01057d6 <cpunum>
f0103699:	6b c0 74             	imul   $0x74,%eax,%eax
f010369c:	66 c7 80 34 b0 22 f0 	movw   $0x10,-0xfdd4fcc(%eax)
f01036a3:	10 00 
	thiscpu->cpu_ts.ts_iomb = sizeof(struct Taskstate);
f01036a5:	e8 2c 21 00 00       	call   f01057d6 <cpunum>
f01036aa:	6b c0 74             	imul   $0x74,%eax,%eax
f01036ad:	66 c7 80 92 b0 22 f0 	movw   $0x68,-0xfdd4f6e(%eax)
f01036b4:	68 00 

	// Initialize the TSS slot of the gdt.
	gdt[(GD_TSS0 >> 3) + i] = SEG16(STS_T32A, (uint32_t) (&thiscpu->cpu_ts),
f01036b6:	8d 5e 05             	lea    0x5(%esi),%ebx
f01036b9:	e8 18 21 00 00       	call   f01057d6 <cpunum>
f01036be:	89 c7                	mov    %eax,%edi
f01036c0:	e8 11 21 00 00       	call   f01057d6 <cpunum>
f01036c5:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01036c8:	e8 09 21 00 00       	call   f01057d6 <cpunum>
f01036cd:	66 c7 04 dd 40 f3 11 	movw   $0x67,-0xfee0cc0(,%ebx,8)
f01036d4:	f0 67 00 
f01036d7:	6b ff 74             	imul   $0x74,%edi,%edi
f01036da:	81 c7 2c b0 22 f0    	add    $0xf022b02c,%edi
f01036e0:	66 89 3c dd 42 f3 11 	mov    %di,-0xfee0cbe(,%ebx,8)
f01036e7:	f0 
f01036e8:	6b 55 e4 74          	imul   $0x74,-0x1c(%ebp),%edx
f01036ec:	81 c2 2c b0 22 f0    	add    $0xf022b02c,%edx
f01036f2:	c1 ea 10             	shr    $0x10,%edx
f01036f5:	88 14 dd 44 f3 11 f0 	mov    %dl,-0xfee0cbc(,%ebx,8)
f01036fc:	c6 04 dd 46 f3 11 f0 	movb   $0x40,-0xfee0cba(,%ebx,8)
f0103703:	40 
f0103704:	6b c0 74             	imul   $0x74,%eax,%eax
f0103707:	05 2c b0 22 f0       	add    $0xf022b02c,%eax
f010370c:	c1 e8 18             	shr    $0x18,%eax
f010370f:	88 04 dd 47 f3 11 f0 	mov    %al,-0xfee0cb9(,%ebx,8)
					sizeof(struct Taskstate) - 1, 0);
	gdt[(GD_TSS0 >> 3) + i].sd_s = 0;
f0103716:	c6 04 dd 45 f3 11 f0 	movb   $0x89,-0xfee0cbb(,%ebx,8)
f010371d:	89 
}

static inline void
ltr(uint16_t sel)
{
	asm volatile("ltr %0" : : "r" (sel));
f010371e:	8d 34 f5 28 00 00 00 	lea    0x28(,%esi,8),%esi
f0103725:	0f 00 de             	ltr    %si
}

static inline void
lidt(void *p)
{
	asm volatile("lidt (%0)" : : "r" (p));
f0103728:	b8 ac f3 11 f0       	mov    $0xf011f3ac,%eax
f010372d:	0f 01 18             	lidtl  (%eax)
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0 + (i << 3));

	// Load the IDT
	lidt(&idt_pd);
}
f0103730:	83 c4 1c             	add    $0x1c,%esp
f0103733:	5b                   	pop    %ebx
f0103734:	5e                   	pop    %esi
f0103735:	5f                   	pop    %edi
f0103736:	5d                   	pop    %ebp
f0103737:	c3                   	ret    

f0103738 <trap_init>:
}


void
trap_init(void)
{
f0103738:	55                   	push   %ebp
f0103739:	89 e5                	mov    %esp,%ebp
f010373b:	83 ec 08             	sub    $0x8,%esp
	extern struct Segdesc gdt[];

	// LAB 3: Your code here.

	SETGATE(idt[T_DIVIDE], 0, GD_KT, t_divide, 0);
f010373e:	b8 26 40 10 f0       	mov    $0xf0104026,%eax
f0103743:	66 a3 60 a2 22 f0    	mov    %ax,0xf022a260
f0103749:	66 c7 05 62 a2 22 f0 	movw   $0x8,0xf022a262
f0103750:	08 00 
f0103752:	c6 05 64 a2 22 f0 00 	movb   $0x0,0xf022a264
f0103759:	c6 05 65 a2 22 f0 8e 	movb   $0x8e,0xf022a265
f0103760:	c1 e8 10             	shr    $0x10,%eax
f0103763:	66 a3 66 a2 22 f0    	mov    %ax,0xf022a266
	SETGATE(idt[T_DEBUG], 0, GD_KT, t_debug, 0);
f0103769:	b8 30 40 10 f0       	mov    $0xf0104030,%eax
f010376e:	66 a3 68 a2 22 f0    	mov    %ax,0xf022a268
f0103774:	66 c7 05 6a a2 22 f0 	movw   $0x8,0xf022a26a
f010377b:	08 00 
f010377d:	c6 05 6c a2 22 f0 00 	movb   $0x0,0xf022a26c
f0103784:	c6 05 6d a2 22 f0 8e 	movb   $0x8e,0xf022a26d
f010378b:	c1 e8 10             	shr    $0x10,%eax
f010378e:	66 a3 6e a2 22 f0    	mov    %ax,0xf022a26e
	SETGATE(idt[T_NMI], 0, GD_KT, t_nmi, 0);
f0103794:	b8 36 40 10 f0       	mov    $0xf0104036,%eax
f0103799:	66 a3 70 a2 22 f0    	mov    %ax,0xf022a270
f010379f:	66 c7 05 72 a2 22 f0 	movw   $0x8,0xf022a272
f01037a6:	08 00 
f01037a8:	c6 05 74 a2 22 f0 00 	movb   $0x0,0xf022a274
f01037af:	c6 05 75 a2 22 f0 8e 	movb   $0x8e,0xf022a275
f01037b6:	c1 e8 10             	shr    $0x10,%eax
f01037b9:	66 a3 76 a2 22 f0    	mov    %ax,0xf022a276
	SETGATE(idt[T_BRKPT], 0, GD_KT, t_brkpt, 3);
f01037bf:	b8 3c 40 10 f0       	mov    $0xf010403c,%eax
f01037c4:	66 a3 78 a2 22 f0    	mov    %ax,0xf022a278
f01037ca:	66 c7 05 7a a2 22 f0 	movw   $0x8,0xf022a27a
f01037d1:	08 00 
f01037d3:	c6 05 7c a2 22 f0 00 	movb   $0x0,0xf022a27c
f01037da:	c6 05 7d a2 22 f0 ee 	movb   $0xee,0xf022a27d
f01037e1:	c1 e8 10             	shr    $0x10,%eax
f01037e4:	66 a3 7e a2 22 f0    	mov    %ax,0xf022a27e
	SETGATE(idt[T_OFLOW], 0, GD_KT, t_oflow, 0);
f01037ea:	b8 42 40 10 f0       	mov    $0xf0104042,%eax
f01037ef:	66 a3 80 a2 22 f0    	mov    %ax,0xf022a280
f01037f5:	66 c7 05 82 a2 22 f0 	movw   $0x8,0xf022a282
f01037fc:	08 00 
f01037fe:	c6 05 84 a2 22 f0 00 	movb   $0x0,0xf022a284
f0103805:	c6 05 85 a2 22 f0 8e 	movb   $0x8e,0xf022a285
f010380c:	c1 e8 10             	shr    $0x10,%eax
f010380f:	66 a3 86 a2 22 f0    	mov    %ax,0xf022a286
	SETGATE(idt[T_BOUND], 0, GD_KT, t_bound, 0);
f0103815:	b8 48 40 10 f0       	mov    $0xf0104048,%eax
f010381a:	66 a3 88 a2 22 f0    	mov    %ax,0xf022a288
f0103820:	66 c7 05 8a a2 22 f0 	movw   $0x8,0xf022a28a
f0103827:	08 00 
f0103829:	c6 05 8c a2 22 f0 00 	movb   $0x0,0xf022a28c
f0103830:	c6 05 8d a2 22 f0 8e 	movb   $0x8e,0xf022a28d
f0103837:	c1 e8 10             	shr    $0x10,%eax
f010383a:	66 a3 8e a2 22 f0    	mov    %ax,0xf022a28e
	SETGATE(idt[T_ILLOP], 0, GD_KT, t_illop, 0);
f0103840:	b8 4e 40 10 f0       	mov    $0xf010404e,%eax
f0103845:	66 a3 90 a2 22 f0    	mov    %ax,0xf022a290
f010384b:	66 c7 05 92 a2 22 f0 	movw   $0x8,0xf022a292
f0103852:	08 00 
f0103854:	c6 05 94 a2 22 f0 00 	movb   $0x0,0xf022a294
f010385b:	c6 05 95 a2 22 f0 8e 	movb   $0x8e,0xf022a295
f0103862:	c1 e8 10             	shr    $0x10,%eax
f0103865:	66 a3 96 a2 22 f0    	mov    %ax,0xf022a296
	SETGATE(idt[T_DEVICE], 0, GD_KT, t_device, 0);
f010386b:	b8 54 40 10 f0       	mov    $0xf0104054,%eax
f0103870:	66 a3 98 a2 22 f0    	mov    %ax,0xf022a298
f0103876:	66 c7 05 9a a2 22 f0 	movw   $0x8,0xf022a29a
f010387d:	08 00 
f010387f:	c6 05 9c a2 22 f0 00 	movb   $0x0,0xf022a29c
f0103886:	c6 05 9d a2 22 f0 8e 	movb   $0x8e,0xf022a29d
f010388d:	c1 e8 10             	shr    $0x10,%eax
f0103890:	66 a3 9e a2 22 f0    	mov    %ax,0xf022a29e
	SETGATE(idt[T_DBLFLT], 0, GD_KT, t_dblflt, 0);
f0103896:	b8 5a 40 10 f0       	mov    $0xf010405a,%eax
f010389b:	66 a3 a0 a2 22 f0    	mov    %ax,0xf022a2a0
f01038a1:	66 c7 05 a2 a2 22 f0 	movw   $0x8,0xf022a2a2
f01038a8:	08 00 
f01038aa:	c6 05 a4 a2 22 f0 00 	movb   $0x0,0xf022a2a4
f01038b1:	c6 05 a5 a2 22 f0 8e 	movb   $0x8e,0xf022a2a5
f01038b8:	c1 e8 10             	shr    $0x10,%eax
f01038bb:	66 a3 a6 a2 22 f0    	mov    %ax,0xf022a2a6
	SETGATE(idt[T_TSS], 0, GD_KT, t_tss, 0);
f01038c1:	b8 5e 40 10 f0       	mov    $0xf010405e,%eax
f01038c6:	66 a3 b0 a2 22 f0    	mov    %ax,0xf022a2b0
f01038cc:	66 c7 05 b2 a2 22 f0 	movw   $0x8,0xf022a2b2
f01038d3:	08 00 
f01038d5:	c6 05 b4 a2 22 f0 00 	movb   $0x0,0xf022a2b4
f01038dc:	c6 05 b5 a2 22 f0 8e 	movb   $0x8e,0xf022a2b5
f01038e3:	c1 e8 10             	shr    $0x10,%eax
f01038e6:	66 a3 b6 a2 22 f0    	mov    %ax,0xf022a2b6
	SETGATE(idt[T_SEGNP], 0, GD_KT, t_segnp, 0);
f01038ec:	b8 62 40 10 f0       	mov    $0xf0104062,%eax
f01038f1:	66 a3 b8 a2 22 f0    	mov    %ax,0xf022a2b8
f01038f7:	66 c7 05 ba a2 22 f0 	movw   $0x8,0xf022a2ba
f01038fe:	08 00 
f0103900:	c6 05 bc a2 22 f0 00 	movb   $0x0,0xf022a2bc
f0103907:	c6 05 bd a2 22 f0 8e 	movb   $0x8e,0xf022a2bd
f010390e:	c1 e8 10             	shr    $0x10,%eax
f0103911:	66 a3 be a2 22 f0    	mov    %ax,0xf022a2be
	SETGATE(idt[T_STACK], 0, GD_KT, t_stack, 0);
f0103917:	b8 66 40 10 f0       	mov    $0xf0104066,%eax
f010391c:	66 a3 c0 a2 22 f0    	mov    %ax,0xf022a2c0
f0103922:	66 c7 05 c2 a2 22 f0 	movw   $0x8,0xf022a2c2
f0103929:	08 00 
f010392b:	c6 05 c4 a2 22 f0 00 	movb   $0x0,0xf022a2c4
f0103932:	c6 05 c5 a2 22 f0 8e 	movb   $0x8e,0xf022a2c5
f0103939:	c1 e8 10             	shr    $0x10,%eax
f010393c:	66 a3 c6 a2 22 f0    	mov    %ax,0xf022a2c6
	SETGATE(idt[T_GPFLT], 0, GD_KT, t_gpflt, 0);
f0103942:	b8 6a 40 10 f0       	mov    $0xf010406a,%eax
f0103947:	66 a3 c8 a2 22 f0    	mov    %ax,0xf022a2c8
f010394d:	66 c7 05 ca a2 22 f0 	movw   $0x8,0xf022a2ca
f0103954:	08 00 
f0103956:	c6 05 cc a2 22 f0 00 	movb   $0x0,0xf022a2cc
f010395d:	c6 05 cd a2 22 f0 8e 	movb   $0x8e,0xf022a2cd
f0103964:	c1 e8 10             	shr    $0x10,%eax
f0103967:	66 a3 ce a2 22 f0    	mov    %ax,0xf022a2ce
	SETGATE(idt[T_PGFLT], 0, GD_KT, t_pgflt, 0);
f010396d:	b8 6e 40 10 f0       	mov    $0xf010406e,%eax
f0103972:	66 a3 d0 a2 22 f0    	mov    %ax,0xf022a2d0
f0103978:	66 c7 05 d2 a2 22 f0 	movw   $0x8,0xf022a2d2
f010397f:	08 00 
f0103981:	c6 05 d4 a2 22 f0 00 	movb   $0x0,0xf022a2d4
f0103988:	c6 05 d5 a2 22 f0 8e 	movb   $0x8e,0xf022a2d5
f010398f:	c1 e8 10             	shr    $0x10,%eax
f0103992:	66 a3 d6 a2 22 f0    	mov    %ax,0xf022a2d6
	SETGATE(idt[T_FPERR], 0, GD_KT, t_fperr, 0);
f0103998:	b8 72 40 10 f0       	mov    $0xf0104072,%eax
f010399d:	66 a3 e0 a2 22 f0    	mov    %ax,0xf022a2e0
f01039a3:	66 c7 05 e2 a2 22 f0 	movw   $0x8,0xf022a2e2
f01039aa:	08 00 
f01039ac:	c6 05 e4 a2 22 f0 00 	movb   $0x0,0xf022a2e4
f01039b3:	c6 05 e5 a2 22 f0 8e 	movb   $0x8e,0xf022a2e5
f01039ba:	c1 e8 10             	shr    $0x10,%eax
f01039bd:	66 a3 e6 a2 22 f0    	mov    %ax,0xf022a2e6
	SETGATE(idt[T_ALIGN], 0, GD_KT, t_align, 0);
f01039c3:	b8 78 40 10 f0       	mov    $0xf0104078,%eax
f01039c8:	66 a3 e8 a2 22 f0    	mov    %ax,0xf022a2e8
f01039ce:	66 c7 05 ea a2 22 f0 	movw   $0x8,0xf022a2ea
f01039d5:	08 00 
f01039d7:	c6 05 ec a2 22 f0 00 	movb   $0x0,0xf022a2ec
f01039de:	c6 05 ed a2 22 f0 8e 	movb   $0x8e,0xf022a2ed
f01039e5:	c1 e8 10             	shr    $0x10,%eax
f01039e8:	66 a3 ee a2 22 f0    	mov    %ax,0xf022a2ee
	SETGATE(idt[T_MCHK], 0, GD_KT, t_mchk, 0);
f01039ee:	b8 7c 40 10 f0       	mov    $0xf010407c,%eax
f01039f3:	66 a3 f0 a2 22 f0    	mov    %ax,0xf022a2f0
f01039f9:	66 c7 05 f2 a2 22 f0 	movw   $0x8,0xf022a2f2
f0103a00:	08 00 
f0103a02:	c6 05 f4 a2 22 f0 00 	movb   $0x0,0xf022a2f4
f0103a09:	c6 05 f5 a2 22 f0 8e 	movb   $0x8e,0xf022a2f5
f0103a10:	c1 e8 10             	shr    $0x10,%eax
f0103a13:	66 a3 f6 a2 22 f0    	mov    %ax,0xf022a2f6
	SETGATE(idt[T_SIMDERR], 0, GD_KT, t_simderr, 0);
f0103a19:	b8 82 40 10 f0       	mov    $0xf0104082,%eax
f0103a1e:	66 a3 f8 a2 22 f0    	mov    %ax,0xf022a2f8
f0103a24:	66 c7 05 fa a2 22 f0 	movw   $0x8,0xf022a2fa
f0103a2b:	08 00 
f0103a2d:	c6 05 fc a2 22 f0 00 	movb   $0x0,0xf022a2fc
f0103a34:	c6 05 fd a2 22 f0 8e 	movb   $0x8e,0xf022a2fd
f0103a3b:	c1 e8 10             	shr    $0x10,%eax
f0103a3e:	66 a3 fe a2 22 f0    	mov    %ax,0xf022a2fe

	SETGATE(idt[T_SYSCALL], 0, GD_KT, t_syscall, 3);
f0103a44:	b8 88 40 10 f0       	mov    $0xf0104088,%eax
f0103a49:	66 a3 e0 a3 22 f0    	mov    %ax,0xf022a3e0
f0103a4f:	66 c7 05 e2 a3 22 f0 	movw   $0x8,0xf022a3e2
f0103a56:	08 00 
f0103a58:	c6 05 e4 a3 22 f0 00 	movb   $0x0,0xf022a3e4
f0103a5f:	c6 05 e5 a3 22 f0 ee 	movb   $0xee,0xf022a3e5
f0103a66:	c1 e8 10             	shr    $0x10,%eax
f0103a69:	66 a3 e6 a3 22 f0    	mov    %ax,0xf022a3e6

	SETGATE(idt[IRQ_OFFSET + IRQ_TIMER], 0, GD_KT, irq_timer, 0);
f0103a6f:	b8 8e 40 10 f0       	mov    $0xf010408e,%eax
f0103a74:	66 a3 60 a3 22 f0    	mov    %ax,0xf022a360
f0103a7a:	66 c7 05 62 a3 22 f0 	movw   $0x8,0xf022a362
f0103a81:	08 00 
f0103a83:	c6 05 64 a3 22 f0 00 	movb   $0x0,0xf022a364
f0103a8a:	c6 05 65 a3 22 f0 8e 	movb   $0x8e,0xf022a365
f0103a91:	c1 e8 10             	shr    $0x10,%eax
f0103a94:	66 a3 66 a3 22 f0    	mov    %ax,0xf022a366
	SETGATE(idt[IRQ_OFFSET + IRQ_KBD], 0, GD_KT, irq_kbd, 0);
f0103a9a:	b8 94 40 10 f0       	mov    $0xf0104094,%eax
f0103a9f:	66 a3 68 a3 22 f0    	mov    %ax,0xf022a368
f0103aa5:	66 c7 05 6a a3 22 f0 	movw   $0x8,0xf022a36a
f0103aac:	08 00 
f0103aae:	c6 05 6c a3 22 f0 00 	movb   $0x0,0xf022a36c
f0103ab5:	c6 05 6d a3 22 f0 8e 	movb   $0x8e,0xf022a36d
f0103abc:	c1 e8 10             	shr    $0x10,%eax
f0103abf:	66 a3 6e a3 22 f0    	mov    %ax,0xf022a36e
	SETGATE(idt[IRQ_OFFSET + IRQ_SERIAL], 0, GD_KT, irq_serial, 0);
f0103ac5:	b8 9a 40 10 f0       	mov    $0xf010409a,%eax
f0103aca:	66 a3 80 a3 22 f0    	mov    %ax,0xf022a380
f0103ad0:	66 c7 05 82 a3 22 f0 	movw   $0x8,0xf022a382
f0103ad7:	08 00 
f0103ad9:	c6 05 84 a3 22 f0 00 	movb   $0x0,0xf022a384
f0103ae0:	c6 05 85 a3 22 f0 8e 	movb   $0x8e,0xf022a385
f0103ae7:	c1 e8 10             	shr    $0x10,%eax
f0103aea:	66 a3 86 a3 22 f0    	mov    %ax,0xf022a386
	SETGATE(idt[IRQ_OFFSET + IRQ_SPURIOUS], 0, GD_KT, irq_spurious, 0);
f0103af0:	b8 a0 40 10 f0       	mov    $0xf01040a0,%eax
f0103af5:	66 a3 98 a3 22 f0    	mov    %ax,0xf022a398
f0103afb:	66 c7 05 9a a3 22 f0 	movw   $0x8,0xf022a39a
f0103b02:	08 00 
f0103b04:	c6 05 9c a3 22 f0 00 	movb   $0x0,0xf022a39c
f0103b0b:	c6 05 9d a3 22 f0 8e 	movb   $0x8e,0xf022a39d
f0103b12:	c1 e8 10             	shr    $0x10,%eax
f0103b15:	66 a3 9e a3 22 f0    	mov    %ax,0xf022a39e
	SETGATE(idt[IRQ_OFFSET + IRQ_IDE], 0, GD_KT, irq_ide, 0);
f0103b1b:	b8 a6 40 10 f0       	mov    $0xf01040a6,%eax
f0103b20:	66 a3 d0 a3 22 f0    	mov    %ax,0xf022a3d0
f0103b26:	66 c7 05 d2 a3 22 f0 	movw   $0x8,0xf022a3d2
f0103b2d:	08 00 
f0103b2f:	c6 05 d4 a3 22 f0 00 	movb   $0x0,0xf022a3d4
f0103b36:	c6 05 d5 a3 22 f0 8e 	movb   $0x8e,0xf022a3d5
f0103b3d:	c1 e8 10             	shr    $0x10,%eax
f0103b40:	66 a3 d6 a3 22 f0    	mov    %ax,0xf022a3d6
	SETGATE(idt[IRQ_OFFSET + IRQ_ERROR], 0, GD_KT, irq_error, 0);
f0103b46:	b8 ac 40 10 f0       	mov    $0xf01040ac,%eax
f0103b4b:	66 a3 f8 a3 22 f0    	mov    %ax,0xf022a3f8
f0103b51:	66 c7 05 fa a3 22 f0 	movw   $0x8,0xf022a3fa
f0103b58:	08 00 
f0103b5a:	c6 05 fc a3 22 f0 00 	movb   $0x0,0xf022a3fc
f0103b61:	c6 05 fd a3 22 f0 8e 	movb   $0x8e,0xf022a3fd
f0103b68:	c1 e8 10             	shr    $0x10,%eax
f0103b6b:	66 a3 fe a3 22 f0    	mov    %ax,0xf022a3fe
	// Per-CPU setup 
	trap_init_percpu();
f0103b71:	e8 f5 fa ff ff       	call   f010366b <trap_init_percpu>
}
f0103b76:	c9                   	leave  
f0103b77:	c3                   	ret    

f0103b78 <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f0103b78:	55                   	push   %ebp
f0103b79:	89 e5                	mov    %esp,%ebp
f0103b7b:	53                   	push   %ebx
f0103b7c:	83 ec 0c             	sub    $0xc,%esp
f0103b7f:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f0103b82:	ff 33                	pushl  (%ebx)
f0103b84:	68 00 71 10 f0       	push   $0xf0107100
f0103b89:	e8 c9 fa ff ff       	call   f0103657 <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f0103b8e:	83 c4 08             	add    $0x8,%esp
f0103b91:	ff 73 04             	pushl  0x4(%ebx)
f0103b94:	68 0f 71 10 f0       	push   $0xf010710f
f0103b99:	e8 b9 fa ff ff       	call   f0103657 <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f0103b9e:	83 c4 08             	add    $0x8,%esp
f0103ba1:	ff 73 08             	pushl  0x8(%ebx)
f0103ba4:	68 1e 71 10 f0       	push   $0xf010711e
f0103ba9:	e8 a9 fa ff ff       	call   f0103657 <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f0103bae:	83 c4 08             	add    $0x8,%esp
f0103bb1:	ff 73 0c             	pushl  0xc(%ebx)
f0103bb4:	68 2d 71 10 f0       	push   $0xf010712d
f0103bb9:	e8 99 fa ff ff       	call   f0103657 <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f0103bbe:	83 c4 08             	add    $0x8,%esp
f0103bc1:	ff 73 10             	pushl  0x10(%ebx)
f0103bc4:	68 3c 71 10 f0       	push   $0xf010713c
f0103bc9:	e8 89 fa ff ff       	call   f0103657 <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f0103bce:	83 c4 08             	add    $0x8,%esp
f0103bd1:	ff 73 14             	pushl  0x14(%ebx)
f0103bd4:	68 4b 71 10 f0       	push   $0xf010714b
f0103bd9:	e8 79 fa ff ff       	call   f0103657 <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f0103bde:	83 c4 08             	add    $0x8,%esp
f0103be1:	ff 73 18             	pushl  0x18(%ebx)
f0103be4:	68 5a 71 10 f0       	push   $0xf010715a
f0103be9:	e8 69 fa ff ff       	call   f0103657 <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f0103bee:	83 c4 08             	add    $0x8,%esp
f0103bf1:	ff 73 1c             	pushl  0x1c(%ebx)
f0103bf4:	68 69 71 10 f0       	push   $0xf0107169
f0103bf9:	e8 59 fa ff ff       	call   f0103657 <cprintf>
}
f0103bfe:	83 c4 10             	add    $0x10,%esp
f0103c01:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103c04:	c9                   	leave  
f0103c05:	c3                   	ret    

f0103c06 <print_trapframe>:
	lidt(&idt_pd);
}

void
print_trapframe(struct Trapframe *tf)
{
f0103c06:	55                   	push   %ebp
f0103c07:	89 e5                	mov    %esp,%ebp
f0103c09:	56                   	push   %esi
f0103c0a:	53                   	push   %ebx
f0103c0b:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p from CPU %d\n", tf, cpunum());
f0103c0e:	e8 c3 1b 00 00       	call   f01057d6 <cpunum>
f0103c13:	83 ec 04             	sub    $0x4,%esp
f0103c16:	50                   	push   %eax
f0103c17:	53                   	push   %ebx
f0103c18:	68 cd 71 10 f0       	push   $0xf01071cd
f0103c1d:	e8 35 fa ff ff       	call   f0103657 <cprintf>
	print_regs(&tf->tf_regs);
f0103c22:	89 1c 24             	mov    %ebx,(%esp)
f0103c25:	e8 4e ff ff ff       	call   f0103b78 <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f0103c2a:	83 c4 08             	add    $0x8,%esp
f0103c2d:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f0103c31:	50                   	push   %eax
f0103c32:	68 eb 71 10 f0       	push   $0xf01071eb
f0103c37:	e8 1b fa ff ff       	call   f0103657 <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f0103c3c:	83 c4 08             	add    $0x8,%esp
f0103c3f:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f0103c43:	50                   	push   %eax
f0103c44:	68 fe 71 10 f0       	push   $0xf01071fe
f0103c49:	e8 09 fa ff ff       	call   f0103657 <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103c4e:	8b 43 28             	mov    0x28(%ebx),%eax
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < ARRAY_SIZE(excnames))
f0103c51:	83 c4 10             	add    $0x10,%esp
f0103c54:	83 f8 13             	cmp    $0x13,%eax
f0103c57:	77 09                	ja     f0103c62 <print_trapframe+0x5c>
		return excnames[trapno];
f0103c59:	8b 14 85 c0 74 10 f0 	mov    -0xfef8b40(,%eax,4),%edx
f0103c60:	eb 1f                	jmp    f0103c81 <print_trapframe+0x7b>
	if (trapno == T_SYSCALL)
f0103c62:	83 f8 30             	cmp    $0x30,%eax
f0103c65:	74 15                	je     f0103c7c <print_trapframe+0x76>
		return "System call";
	if (trapno >= IRQ_OFFSET && trapno < IRQ_OFFSET + 16)
f0103c67:	8d 50 e0             	lea    -0x20(%eax),%edx
		return "Hardware Interrupt";
	return "(unknown trap)";
f0103c6a:	83 fa 10             	cmp    $0x10,%edx
f0103c6d:	b9 97 71 10 f0       	mov    $0xf0107197,%ecx
f0103c72:	ba 84 71 10 f0       	mov    $0xf0107184,%edx
f0103c77:	0f 43 d1             	cmovae %ecx,%edx
f0103c7a:	eb 05                	jmp    f0103c81 <print_trapframe+0x7b>
	};

	if (trapno < ARRAY_SIZE(excnames))
		return excnames[trapno];
	if (trapno == T_SYSCALL)
		return "System call";
f0103c7c:	ba 78 71 10 f0       	mov    $0xf0107178,%edx
{
	cprintf("TRAP frame at %p from CPU %d\n", tf, cpunum());
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103c81:	83 ec 04             	sub    $0x4,%esp
f0103c84:	52                   	push   %edx
f0103c85:	50                   	push   %eax
f0103c86:	68 11 72 10 f0       	push   $0xf0107211
f0103c8b:	e8 c7 f9 ff ff       	call   f0103657 <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0103c90:	83 c4 10             	add    $0x10,%esp
f0103c93:	3b 1d 60 aa 22 f0    	cmp    0xf022aa60,%ebx
f0103c99:	75 1a                	jne    f0103cb5 <print_trapframe+0xaf>
f0103c9b:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103c9f:	75 14                	jne    f0103cb5 <print_trapframe+0xaf>

static inline uint32_t
rcr2(void)
{
	uint32_t val;
	asm volatile("movl %%cr2,%0" : "=r" (val));
f0103ca1:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f0103ca4:	83 ec 08             	sub    $0x8,%esp
f0103ca7:	50                   	push   %eax
f0103ca8:	68 23 72 10 f0       	push   $0xf0107223
f0103cad:	e8 a5 f9 ff ff       	call   f0103657 <cprintf>
f0103cb2:	83 c4 10             	add    $0x10,%esp
	cprintf("  err  0x%08x", tf->tf_err);
f0103cb5:	83 ec 08             	sub    $0x8,%esp
f0103cb8:	ff 73 2c             	pushl  0x2c(%ebx)
f0103cbb:	68 32 72 10 f0       	push   $0xf0107232
f0103cc0:	e8 92 f9 ff ff       	call   f0103657 <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f0103cc5:	83 c4 10             	add    $0x10,%esp
f0103cc8:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103ccc:	75 49                	jne    f0103d17 <print_trapframe+0x111>
		cprintf(" [%s, %s, %s]\n",
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
f0103cce:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f0103cd1:	89 c2                	mov    %eax,%edx
f0103cd3:	83 e2 01             	and    $0x1,%edx
f0103cd6:	ba b1 71 10 f0       	mov    $0xf01071b1,%edx
f0103cdb:	b9 a6 71 10 f0       	mov    $0xf01071a6,%ecx
f0103ce0:	0f 44 ca             	cmove  %edx,%ecx
f0103ce3:	89 c2                	mov    %eax,%edx
f0103ce5:	83 e2 02             	and    $0x2,%edx
f0103ce8:	ba c3 71 10 f0       	mov    $0xf01071c3,%edx
f0103ced:	be bd 71 10 f0       	mov    $0xf01071bd,%esi
f0103cf2:	0f 45 d6             	cmovne %esi,%edx
f0103cf5:	83 e0 04             	and    $0x4,%eax
f0103cf8:	be 0f 73 10 f0       	mov    $0xf010730f,%esi
f0103cfd:	b8 c8 71 10 f0       	mov    $0xf01071c8,%eax
f0103d02:	0f 44 c6             	cmove  %esi,%eax
f0103d05:	51                   	push   %ecx
f0103d06:	52                   	push   %edx
f0103d07:	50                   	push   %eax
f0103d08:	68 40 72 10 f0       	push   $0xf0107240
f0103d0d:	e8 45 f9 ff ff       	call   f0103657 <cprintf>
f0103d12:	83 c4 10             	add    $0x10,%esp
f0103d15:	eb 10                	jmp    f0103d27 <print_trapframe+0x121>
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f0103d17:	83 ec 0c             	sub    $0xc,%esp
f0103d1a:	68 44 70 10 f0       	push   $0xf0107044
f0103d1f:	e8 33 f9 ff ff       	call   f0103657 <cprintf>
f0103d24:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f0103d27:	83 ec 08             	sub    $0x8,%esp
f0103d2a:	ff 73 30             	pushl  0x30(%ebx)
f0103d2d:	68 4f 72 10 f0       	push   $0xf010724f
f0103d32:	e8 20 f9 ff ff       	call   f0103657 <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f0103d37:	83 c4 08             	add    $0x8,%esp
f0103d3a:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f0103d3e:	50                   	push   %eax
f0103d3f:	68 5e 72 10 f0       	push   $0xf010725e
f0103d44:	e8 0e f9 ff ff       	call   f0103657 <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f0103d49:	83 c4 08             	add    $0x8,%esp
f0103d4c:	ff 73 38             	pushl  0x38(%ebx)
f0103d4f:	68 71 72 10 f0       	push   $0xf0107271
f0103d54:	e8 fe f8 ff ff       	call   f0103657 <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f0103d59:	83 c4 10             	add    $0x10,%esp
f0103d5c:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0103d60:	74 25                	je     f0103d87 <print_trapframe+0x181>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f0103d62:	83 ec 08             	sub    $0x8,%esp
f0103d65:	ff 73 3c             	pushl  0x3c(%ebx)
f0103d68:	68 80 72 10 f0       	push   $0xf0107280
f0103d6d:	e8 e5 f8 ff ff       	call   f0103657 <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f0103d72:	83 c4 08             	add    $0x8,%esp
f0103d75:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f0103d79:	50                   	push   %eax
f0103d7a:	68 8f 72 10 f0       	push   $0xf010728f
f0103d7f:	e8 d3 f8 ff ff       	call   f0103657 <cprintf>
f0103d84:	83 c4 10             	add    $0x10,%esp
	}
}
f0103d87:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0103d8a:	5b                   	pop    %ebx
f0103d8b:	5e                   	pop    %esi
f0103d8c:	5d                   	pop    %ebp
f0103d8d:	c3                   	ret    

f0103d8e <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f0103d8e:	55                   	push   %ebp
f0103d8f:	89 e5                	mov    %esp,%ebp
f0103d91:	57                   	push   %edi
f0103d92:	56                   	push   %esi
f0103d93:	53                   	push   %ebx
f0103d94:	83 ec 0c             	sub    $0xc,%esp
f0103d97:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103d9a:	0f 20 d6             	mov    %cr2,%esi
	fault_va = rcr2();

	// Handle kernel-mode page faults.

	// LAB 3: Your code here.
	if (tf->tf_cs == GD_KT) {
f0103d9d:	66 83 7b 34 08       	cmpw   $0x8,0x34(%ebx)
f0103da2:	75 17                	jne    f0103dbb <page_fault_handler+0x2d>
		// Trapped from kernel mode
		panic("page_fault_handler: page fault in kernel mode");
f0103da4:	83 ec 04             	sub    $0x4,%esp
f0103da7:	68 5c 74 10 f0       	push   $0xf010745c
f0103dac:	68 67 01 00 00       	push   $0x167
f0103db1:	68 a2 72 10 f0       	push   $0xf01072a2
f0103db6:	e8 85 c2 ff ff       	call   f0100040 <_panic>
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103dbb:	8b 7b 30             	mov    0x30(%ebx),%edi
		curenv->env_id, fault_va, tf->tf_eip);
f0103dbe:	e8 13 1a 00 00       	call   f01057d6 <cpunum>
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103dc3:	57                   	push   %edi
f0103dc4:	56                   	push   %esi
		curenv->env_id, fault_va, tf->tf_eip);
f0103dc5:	6b c0 74             	imul   $0x74,%eax,%eax
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103dc8:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0103dce:	ff 70 48             	pushl  0x48(%eax)
f0103dd1:	68 8c 74 10 f0       	push   $0xf010748c
f0103dd6:	e8 7c f8 ff ff       	call   f0103657 <cprintf>
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f0103ddb:	89 1c 24             	mov    %ebx,(%esp)
f0103dde:	e8 23 fe ff ff       	call   f0103c06 <print_trapframe>
	env_destroy(curenv);
f0103de3:	e8 ee 19 00 00       	call   f01057d6 <cpunum>
f0103de8:	83 c4 04             	add    $0x4,%esp
f0103deb:	6b c0 74             	imul   $0x74,%eax,%eax
f0103dee:	ff b0 28 b0 22 f0    	pushl  -0xfdd4fd8(%eax)
f0103df4:	e8 89 f5 ff ff       	call   f0103382 <env_destroy>
}
f0103df9:	83 c4 10             	add    $0x10,%esp
f0103dfc:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103dff:	5b                   	pop    %ebx
f0103e00:	5e                   	pop    %esi
f0103e01:	5f                   	pop    %edi
f0103e02:	5d                   	pop    %ebp
f0103e03:	c3                   	ret    

f0103e04 <trap>:
	}
}

void
trap(struct Trapframe *tf)
{
f0103e04:	55                   	push   %ebp
f0103e05:	89 e5                	mov    %esp,%ebp
f0103e07:	57                   	push   %edi
f0103e08:	56                   	push   %esi
f0103e09:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f0103e0c:	fc                   	cld    

	// Halt the CPU if some other CPU has called panic()
	extern char *panicstr;
	if (panicstr)
f0103e0d:	83 3d 80 ae 22 f0 00 	cmpl   $0x0,0xf022ae80
f0103e14:	74 01                	je     f0103e17 <trap+0x13>
		asm volatile("hlt");
f0103e16:	f4                   	hlt    

	// Re-acqurie the big kernel lock if we were halted in
	// sched_yield()
	if (xchg(&thiscpu->cpu_status, CPU_STARTED) == CPU_HALTED)
f0103e17:	e8 ba 19 00 00       	call   f01057d6 <cpunum>
f0103e1c:	6b d0 74             	imul   $0x74,%eax,%edx
f0103e1f:	81 c2 20 b0 22 f0    	add    $0xf022b020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"
f0103e25:	b8 01 00 00 00       	mov    $0x1,%eax
f0103e2a:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
f0103e2e:	83 f8 02             	cmp    $0x2,%eax
f0103e31:	75 10                	jne    f0103e43 <trap+0x3f>
extern struct spinlock kernel_lock;

static inline void
lock_kernel(void)
{
	spin_lock(&kernel_lock);
f0103e33:	83 ec 0c             	sub    $0xc,%esp
f0103e36:	68 c0 f3 11 f0       	push   $0xf011f3c0
f0103e3b:	e8 04 1c 00 00       	call   f0105a44 <spin_lock>
f0103e40:	83 c4 10             	add    $0x10,%esp

static inline uint32_t
read_eflags(void)
{
	uint32_t eflags;
	asm volatile("pushfl; popl %0" : "=r" (eflags));
f0103e43:	9c                   	pushf  
f0103e44:	58                   	pop    %eax
		lock_kernel();
	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f0103e45:	f6 c4 02             	test   $0x2,%ah
f0103e48:	74 19                	je     f0103e63 <trap+0x5f>
f0103e4a:	68 ae 72 10 f0       	push   $0xf01072ae
f0103e4f:	68 8a 6d 10 f0       	push   $0xf0106d8a
f0103e54:	68 2f 01 00 00       	push   $0x12f
f0103e59:	68 a2 72 10 f0       	push   $0xf01072a2
f0103e5e:	e8 dd c1 ff ff       	call   f0100040 <_panic>

	if ((tf->tf_cs & 3) == 3) {
f0103e63:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0103e67:	83 e0 03             	and    $0x3,%eax
f0103e6a:	66 83 f8 03          	cmp    $0x3,%ax
f0103e6e:	0f 85 a0 00 00 00    	jne    f0103f14 <trap+0x110>
f0103e74:	83 ec 0c             	sub    $0xc,%esp
f0103e77:	68 c0 f3 11 f0       	push   $0xf011f3c0
f0103e7c:	e8 c3 1b 00 00       	call   f0105a44 <spin_lock>
		// Trapped from user mode.
		// Acquire the big kernel lock before doing any
		// serious kernel work.
		// LAB 4: Your code here.
        lock_kernel();
		assert(curenv);
f0103e81:	e8 50 19 00 00       	call   f01057d6 <cpunum>
f0103e86:	6b c0 74             	imul   $0x74,%eax,%eax
f0103e89:	83 c4 10             	add    $0x10,%esp
f0103e8c:	83 b8 28 b0 22 f0 00 	cmpl   $0x0,-0xfdd4fd8(%eax)
f0103e93:	75 19                	jne    f0103eae <trap+0xaa>
f0103e95:	68 c7 72 10 f0       	push   $0xf01072c7
f0103e9a:	68 8a 6d 10 f0       	push   $0xf0106d8a
f0103e9f:	68 37 01 00 00       	push   $0x137
f0103ea4:	68 a2 72 10 f0       	push   $0xf01072a2
f0103ea9:	e8 92 c1 ff ff       	call   f0100040 <_panic>

		// Garbage collect if current enviroment is a zombie
		if (curenv->env_status == ENV_DYING) {
f0103eae:	e8 23 19 00 00       	call   f01057d6 <cpunum>
f0103eb3:	6b c0 74             	imul   $0x74,%eax,%eax
f0103eb6:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0103ebc:	83 78 54 01          	cmpl   $0x1,0x54(%eax)
f0103ec0:	75 2d                	jne    f0103eef <trap+0xeb>
			env_free(curenv);
f0103ec2:	e8 0f 19 00 00       	call   f01057d6 <cpunum>
f0103ec7:	83 ec 0c             	sub    $0xc,%esp
f0103eca:	6b c0 74             	imul   $0x74,%eax,%eax
f0103ecd:	ff b0 28 b0 22 f0    	pushl  -0xfdd4fd8(%eax)
f0103ed3:	e8 cf f2 ff ff       	call   f01031a7 <env_free>
			curenv = NULL;
f0103ed8:	e8 f9 18 00 00       	call   f01057d6 <cpunum>
f0103edd:	6b c0 74             	imul   $0x74,%eax,%eax
f0103ee0:	c7 80 28 b0 22 f0 00 	movl   $0x0,-0xfdd4fd8(%eax)
f0103ee7:	00 00 00 
			sched_yield();
f0103eea:	e8 a8 02 00 00       	call   f0104197 <sched_yield>
		}

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f0103eef:	e8 e2 18 00 00       	call   f01057d6 <cpunum>
f0103ef4:	6b c0 74             	imul   $0x74,%eax,%eax
f0103ef7:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0103efd:	b9 11 00 00 00       	mov    $0x11,%ecx
f0103f02:	89 c7                	mov    %eax,%edi
f0103f04:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f0103f06:	e8 cb 18 00 00       	call   f01057d6 <cpunum>
f0103f0b:	6b c0 74             	imul   $0x74,%eax,%eax
f0103f0e:	8b b0 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f0103f14:	89 35 60 aa 22 f0    	mov    %esi,0xf022aa60
trap_dispatch(struct Trapframe *tf)
{
	// Handle processor exceptions.
	// LAB 3: Your code here.
	int r;
	switch(tf->tf_trapno){
f0103f1a:	8b 46 28             	mov    0x28(%esi),%eax
f0103f1d:	83 f8 0e             	cmp    $0xe,%eax
f0103f20:	74 46                	je     f0103f68 <trap+0x164>
f0103f22:	83 f8 30             	cmp    $0x30,%eax
f0103f25:	74 07                	je     f0103f2e <trap+0x12a>
f0103f27:	83 f8 03             	cmp    $0x3,%eax
f0103f2a:	75 58                	jne    f0103f84 <trap+0x180>
f0103f2c:	eb 48                	jmp    f0103f76 <trap+0x172>
		case T_SYSCALL:
			r = syscall(
f0103f2e:	83 ec 08             	sub    $0x8,%esp
f0103f31:	ff 76 04             	pushl  0x4(%esi)
f0103f34:	ff 36                	pushl  (%esi)
f0103f36:	ff 76 10             	pushl  0x10(%esi)
f0103f39:	ff 76 18             	pushl  0x18(%esi)
f0103f3c:	ff 76 14             	pushl  0x14(%esi)
f0103f3f:	ff 76 1c             	pushl  0x1c(%esi)
f0103f42:	e8 14 03 00 00       	call   f010425b <syscall>
					tf->tf_regs.reg_ecx, 
					tf->tf_regs.reg_ebx, 
					tf->tf_regs.reg_edi, 
					tf->tf_regs.reg_esi);

			if (r < 0) {
f0103f47:	83 c4 20             	add    $0x20,%esp
f0103f4a:	85 c0                	test   %eax,%eax
f0103f4c:	79 15                	jns    f0103f63 <trap+0x15f>
				panic("trap_dispatch: %e", r);
f0103f4e:	50                   	push   %eax
f0103f4f:	68 ce 72 10 f0       	push   $0xf01072ce
f0103f54:	68 f9 00 00 00       	push   $0xf9
f0103f59:	68 a2 72 10 f0       	push   $0xf01072a2
f0103f5e:	e8 dd c0 ff ff       	call   f0100040 <_panic>
			}
			tf->tf_regs.reg_eax = r; 
f0103f63:	89 46 1c             	mov    %eax,0x1c(%esi)
f0103f66:	eb 7e                	jmp    f0103fe6 <trap+0x1e2>
			return;
		case T_PGFLT:
			page_fault_handler(tf);
f0103f68:	83 ec 0c             	sub    $0xc,%esp
f0103f6b:	56                   	push   %esi
f0103f6c:	e8 1d fe ff ff       	call   f0103d8e <page_fault_handler>
f0103f71:	83 c4 10             	add    $0x10,%esp
f0103f74:	eb 70                	jmp    f0103fe6 <trap+0x1e2>
			return;
		case T_BRKPT:
			monitor(tf);
f0103f76:	83 ec 0c             	sub    $0xc,%esp
f0103f79:	56                   	push   %esi
f0103f7a:	e8 72 c9 ff ff       	call   f01008f1 <monitor>
f0103f7f:	83 c4 10             	add    $0x10,%esp
f0103f82:	eb 62                	jmp    f0103fe6 <trap+0x1e2>
	}

	// Handle spurious interrupts
	// The hardware sometimes raises these because of noise on the
	// IRQ line or other reasons. We don't care.
	if (tf->tf_trapno == IRQ_OFFSET + IRQ_SPURIOUS) {
f0103f84:	83 f8 27             	cmp    $0x27,%eax
f0103f87:	75 1a                	jne    f0103fa3 <trap+0x19f>
		cprintf("Spurious interrupt on irq 7\n");
f0103f89:	83 ec 0c             	sub    $0xc,%esp
f0103f8c:	68 e0 72 10 f0       	push   $0xf01072e0
f0103f91:	e8 c1 f6 ff ff       	call   f0103657 <cprintf>
		print_trapframe(tf);
f0103f96:	89 34 24             	mov    %esi,(%esp)
f0103f99:	e8 68 fc ff ff       	call   f0103c06 <print_trapframe>
f0103f9e:	83 c4 10             	add    $0x10,%esp
f0103fa1:	eb 43                	jmp    f0103fe6 <trap+0x1e2>
	// Handle clock interrupts. Don't forget to acknowledge the
	// interrupt using lapic_eoi() before calling the scheduler!
	// LAB 4: Your code here.

	// Unexpected trap: The user process or the kernel has a bug.
	print_trapframe(tf);
f0103fa3:	83 ec 0c             	sub    $0xc,%esp
f0103fa6:	56                   	push   %esi
f0103fa7:	e8 5a fc ff ff       	call   f0103c06 <print_trapframe>
	if (tf->tf_cs == GD_KT)
f0103fac:	83 c4 10             	add    $0x10,%esp
f0103faf:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f0103fb4:	75 17                	jne    f0103fcd <trap+0x1c9>
		panic("unhandled trap in kernel");
f0103fb6:	83 ec 04             	sub    $0x4,%esp
f0103fb9:	68 fd 72 10 f0       	push   $0xf01072fd
f0103fbe:	68 15 01 00 00       	push   $0x115
f0103fc3:	68 a2 72 10 f0       	push   $0xf01072a2
f0103fc8:	e8 73 c0 ff ff       	call   f0100040 <_panic>
	else {
		env_destroy(curenv);
f0103fcd:	e8 04 18 00 00       	call   f01057d6 <cpunum>
f0103fd2:	83 ec 0c             	sub    $0xc,%esp
f0103fd5:	6b c0 74             	imul   $0x74,%eax,%eax
f0103fd8:	ff b0 28 b0 22 f0    	pushl  -0xfdd4fd8(%eax)
f0103fde:	e8 9f f3 ff ff       	call   f0103382 <env_destroy>
f0103fe3:	83 c4 10             	add    $0x10,%esp
	trap_dispatch(tf);

	// If we made it to this point, then no other environment was
	// scheduled, so we should return to the current environment
	// if doing so makes sense.
	if (curenv && curenv->env_status == ENV_RUNNING)
f0103fe6:	e8 eb 17 00 00       	call   f01057d6 <cpunum>
f0103feb:	6b c0 74             	imul   $0x74,%eax,%eax
f0103fee:	83 b8 28 b0 22 f0 00 	cmpl   $0x0,-0xfdd4fd8(%eax)
f0103ff5:	74 2a                	je     f0104021 <trap+0x21d>
f0103ff7:	e8 da 17 00 00       	call   f01057d6 <cpunum>
f0103ffc:	6b c0 74             	imul   $0x74,%eax,%eax
f0103fff:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0104005:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0104009:	75 16                	jne    f0104021 <trap+0x21d>
		env_run(curenv);
f010400b:	e8 c6 17 00 00       	call   f01057d6 <cpunum>
f0104010:	83 ec 0c             	sub    $0xc,%esp
f0104013:	6b c0 74             	imul   $0x74,%eax,%eax
f0104016:	ff b0 28 b0 22 f0    	pushl  -0xfdd4fd8(%eax)
f010401c:	e8 00 f4 ff ff       	call   f0103421 <env_run>
	else
		sched_yield();
f0104021:	e8 71 01 00 00       	call   f0104197 <sched_yield>

f0104026 <t_divide>:
.text

/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */
TRAPHANDLER_NOEC(t_divide, T_DIVIDE)
f0104026:	6a 00                	push   $0x0
f0104028:	6a 00                	push   $0x0
f010402a:	e9 83 00 00 00       	jmp    f01040b2 <_alltraps>
f010402f:	90                   	nop

f0104030 <t_debug>:
TRAPHANDLER_NOEC(t_debug, T_DEBUG)
f0104030:	6a 00                	push   $0x0
f0104032:	6a 01                	push   $0x1
f0104034:	eb 7c                	jmp    f01040b2 <_alltraps>

f0104036 <t_nmi>:
TRAPHANDLER_NOEC(t_nmi, T_NMI)
f0104036:	6a 00                	push   $0x0
f0104038:	6a 02                	push   $0x2
f010403a:	eb 76                	jmp    f01040b2 <_alltraps>

f010403c <t_brkpt>:
TRAPHANDLER_NOEC(t_brkpt, T_BRKPT)
f010403c:	6a 00                	push   $0x0
f010403e:	6a 03                	push   $0x3
f0104040:	eb 70                	jmp    f01040b2 <_alltraps>

f0104042 <t_oflow>:
TRAPHANDLER_NOEC(t_oflow, T_OFLOW)
f0104042:	6a 00                	push   $0x0
f0104044:	6a 04                	push   $0x4
f0104046:	eb 6a                	jmp    f01040b2 <_alltraps>

f0104048 <t_bound>:
TRAPHANDLER_NOEC(t_bound, T_BOUND)
f0104048:	6a 00                	push   $0x0
f010404a:	6a 05                	push   $0x5
f010404c:	eb 64                	jmp    f01040b2 <_alltraps>

f010404e <t_illop>:
TRAPHANDLER_NOEC(t_illop, T_ILLOP)
f010404e:	6a 00                	push   $0x0
f0104050:	6a 06                	push   $0x6
f0104052:	eb 5e                	jmp    f01040b2 <_alltraps>

f0104054 <t_device>:
TRAPHANDLER_NOEC(t_device, T_DEVICE)
f0104054:	6a 00                	push   $0x0
f0104056:	6a 07                	push   $0x7
f0104058:	eb 58                	jmp    f01040b2 <_alltraps>

f010405a <t_dblflt>:
TRAPHANDLER(t_dblflt, T_DBLFLT)
f010405a:	6a 08                	push   $0x8
f010405c:	eb 54                	jmp    f01040b2 <_alltraps>

f010405e <t_tss>:
TRAPHANDLER(t_tss, T_TSS)
f010405e:	6a 0a                	push   $0xa
f0104060:	eb 50                	jmp    f01040b2 <_alltraps>

f0104062 <t_segnp>:
TRAPHANDLER(t_segnp, T_SEGNP)
f0104062:	6a 0b                	push   $0xb
f0104064:	eb 4c                	jmp    f01040b2 <_alltraps>

f0104066 <t_stack>:
TRAPHANDLER(t_stack, T_STACK)
f0104066:	6a 0c                	push   $0xc
f0104068:	eb 48                	jmp    f01040b2 <_alltraps>

f010406a <t_gpflt>:
TRAPHANDLER(t_gpflt, T_GPFLT)
f010406a:	6a 0d                	push   $0xd
f010406c:	eb 44                	jmp    f01040b2 <_alltraps>

f010406e <t_pgflt>:
TRAPHANDLER(t_pgflt, T_PGFLT)
f010406e:	6a 0e                	push   $0xe
f0104070:	eb 40                	jmp    f01040b2 <_alltraps>

f0104072 <t_fperr>:
TRAPHANDLER_NOEC(t_fperr, T_FPERR)
f0104072:	6a 00                	push   $0x0
f0104074:	6a 10                	push   $0x10
f0104076:	eb 3a                	jmp    f01040b2 <_alltraps>

f0104078 <t_align>:
TRAPHANDLER(t_align, T_ALIGN)
f0104078:	6a 11                	push   $0x11
f010407a:	eb 36                	jmp    f01040b2 <_alltraps>

f010407c <t_mchk>:
TRAPHANDLER_NOEC(t_mchk, T_MCHK)
f010407c:	6a 00                	push   $0x0
f010407e:	6a 12                	push   $0x12
f0104080:	eb 30                	jmp    f01040b2 <_alltraps>

f0104082 <t_simderr>:
TRAPHANDLER_NOEC(t_simderr, T_SIMDERR)
f0104082:	6a 00                	push   $0x0
f0104084:	6a 13                	push   $0x13
f0104086:	eb 2a                	jmp    f01040b2 <_alltraps>

f0104088 <t_syscall>:
TRAPHANDLER_NOEC(t_syscall, T_SYSCALL)
f0104088:	6a 00                	push   $0x0
f010408a:	6a 30                	push   $0x30
f010408c:	eb 24                	jmp    f01040b2 <_alltraps>

f010408e <irq_timer>:
TRAPHANDLER_NOEC(irq_timer, IRQ_OFFSET + IRQ_TIMER)
f010408e:	6a 00                	push   $0x0
f0104090:	6a 20                	push   $0x20
f0104092:	eb 1e                	jmp    f01040b2 <_alltraps>

f0104094 <irq_kbd>:
TRAPHANDLER_NOEC(irq_kbd, IRQ_OFFSET + IRQ_KBD)
f0104094:	6a 00                	push   $0x0
f0104096:	6a 21                	push   $0x21
f0104098:	eb 18                	jmp    f01040b2 <_alltraps>

f010409a <irq_serial>:
TRAPHANDLER_NOEC(irq_serial, IRQ_OFFSET + IRQ_SERIAL)
f010409a:	6a 00                	push   $0x0
f010409c:	6a 24                	push   $0x24
f010409e:	eb 12                	jmp    f01040b2 <_alltraps>

f01040a0 <irq_spurious>:
TRAPHANDLER_NOEC(irq_spurious, IRQ_OFFSET + IRQ_SPURIOUS)
f01040a0:	6a 00                	push   $0x0
f01040a2:	6a 27                	push   $0x27
f01040a4:	eb 0c                	jmp    f01040b2 <_alltraps>

f01040a6 <irq_ide>:
TRAPHANDLER_NOEC(irq_ide, IRQ_OFFSET + IRQ_IDE)
f01040a6:	6a 00                	push   $0x0
f01040a8:	6a 2e                	push   $0x2e
f01040aa:	eb 06                	jmp    f01040b2 <_alltraps>

f01040ac <irq_error>:
TRAPHANDLER_NOEC(irq_error, IRQ_OFFSET + IRQ_ERROR)
f01040ac:	6a 00                	push   $0x0
f01040ae:	6a 33                	push   $0x33
f01040b0:	eb 00                	jmp    f01040b2 <_alltraps>

f01040b2 <_alltraps>:
/*
 * Lab 3: Your code here for _alltraps
 */
_alltraps:
	# Build trap frame.
	pushl %ds
f01040b2:	1e                   	push   %ds
	pushl %es
f01040b3:	06                   	push   %es
	pushal	
f01040b4:	60                   	pusha  

	movw $(GD_KD), %ax
f01040b5:	66 b8 10 00          	mov    $0x10,%ax
	movw %ax, %ds
f01040b9:	8e d8                	mov    %eax,%ds
	movw %ax, %es
f01040bb:	8e c0                	mov    %eax,%es

	pushl %esp
f01040bd:	54                   	push   %esp
	call trap
f01040be:	e8 41 fd ff ff       	call   f0103e04 <trap>

f01040c3 <sched_halt>:
// Halt this CPU when there is nothing to do. Wait until the
// timer interrupt wakes it up. This function never returns.
//
void
sched_halt(void)
{
f01040c3:	55                   	push   %ebp
f01040c4:	89 e5                	mov    %esp,%ebp
f01040c6:	83 ec 08             	sub    $0x8,%esp
f01040c9:	a1 44 a2 22 f0       	mov    0xf022a244,%eax
f01040ce:	8d 50 54             	lea    0x54(%eax),%edx
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
f01040d1:	b9 00 00 00 00       	mov    $0x0,%ecx
		if ((envs[i].env_status == ENV_RUNNABLE ||
f01040d6:	8b 02                	mov    (%edx),%eax
f01040d8:	83 e8 01             	sub    $0x1,%eax
f01040db:	83 f8 02             	cmp    $0x2,%eax
f01040de:	76 10                	jbe    f01040f0 <sched_halt+0x2d>
{
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
f01040e0:	83 c1 01             	add    $0x1,%ecx
f01040e3:	83 c2 7c             	add    $0x7c,%edx
f01040e6:	81 f9 00 04 00 00    	cmp    $0x400,%ecx
f01040ec:	75 e8                	jne    f01040d6 <sched_halt+0x13>
f01040ee:	eb 08                	jmp    f01040f8 <sched_halt+0x35>
		if ((envs[i].env_status == ENV_RUNNABLE ||
		     envs[i].env_status == ENV_RUNNING ||
		     envs[i].env_status == ENV_DYING))
			break;
	}
	if (i == NENV) {
f01040f0:	81 f9 00 04 00 00    	cmp    $0x400,%ecx
f01040f6:	75 1f                	jne    f0104117 <sched_halt+0x54>
		cprintf("No runnable environments in the system!\n");
f01040f8:	83 ec 0c             	sub    $0xc,%esp
f01040fb:	68 10 75 10 f0       	push   $0xf0107510
f0104100:	e8 52 f5 ff ff       	call   f0103657 <cprintf>
f0104105:	83 c4 10             	add    $0x10,%esp
		while (1)
			monitor(NULL);
f0104108:	83 ec 0c             	sub    $0xc,%esp
f010410b:	6a 00                	push   $0x0
f010410d:	e8 df c7 ff ff       	call   f01008f1 <monitor>
f0104112:	83 c4 10             	add    $0x10,%esp
f0104115:	eb f1                	jmp    f0104108 <sched_halt+0x45>
	}

	// Mark that no environment is running on this CPU
	curenv = NULL;
f0104117:	e8 ba 16 00 00       	call   f01057d6 <cpunum>
f010411c:	6b c0 74             	imul   $0x74,%eax,%eax
f010411f:	c7 80 28 b0 22 f0 00 	movl   $0x0,-0xfdd4fd8(%eax)
f0104126:	00 00 00 
	lcr3(PADDR(kern_pgdir));
f0104129:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010412e:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0104133:	77 12                	ja     f0104147 <sched_halt+0x84>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0104135:	50                   	push   %eax
f0104136:	68 a8 5e 10 f0       	push   $0xf0105ea8
f010413b:	6a 4f                	push   $0x4f
f010413d:	68 39 75 10 f0       	push   $0xf0107539
f0104142:	e8 f9 be ff ff       	call   f0100040 <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0104147:	05 00 00 00 10       	add    $0x10000000,%eax
f010414c:	0f 22 d8             	mov    %eax,%cr3

	// Mark that this CPU is in the HALT state, so that when
	// timer interupts come in, we know we should re-acquire the
	// big kernel lock
	xchg(&thiscpu->cpu_status, CPU_HALTED);
f010414f:	e8 82 16 00 00       	call   f01057d6 <cpunum>
f0104154:	6b d0 74             	imul   $0x74,%eax,%edx
f0104157:	81 c2 20 b0 22 f0    	add    $0xf022b020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"
f010415d:	b8 02 00 00 00       	mov    $0x2,%eax
f0104162:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
}

static inline void
unlock_kernel(void)
{
	spin_unlock(&kernel_lock);
f0104166:	83 ec 0c             	sub    $0xc,%esp
f0104169:	68 c0 f3 11 f0       	push   $0xf011f3c0
f010416e:	e8 6e 19 00 00       	call   f0105ae1 <spin_unlock>

	// Normally we wouldn't need to do this, but QEMU only runs
	// one CPU at a time and has a long time-slice.  Without the
	// pause, this CPU is likely to reacquire the lock before
	// another CPU has even been given a chance to acquire it.
	asm volatile("pause");
f0104173:	f3 90                	pause  
		"pushl $0\n"
		"sti\n"
		"1:\n"
		"hlt\n"
		"jmp 1b\n"
	: : "a" (thiscpu->cpu_ts.ts_esp0));
f0104175:	e8 5c 16 00 00       	call   f01057d6 <cpunum>
f010417a:	6b c0 74             	imul   $0x74,%eax,%eax

	// Release the big kernel lock as if we were "leaving" the kernel
	unlock_kernel();

	// Reset stack pointer, enable interrupts and then halt.
	asm volatile (
f010417d:	8b 80 30 b0 22 f0    	mov    -0xfdd4fd0(%eax),%eax
f0104183:	bd 00 00 00 00       	mov    $0x0,%ebp
f0104188:	89 c4                	mov    %eax,%esp
f010418a:	6a 00                	push   $0x0
f010418c:	6a 00                	push   $0x0
f010418e:	fb                   	sti    
f010418f:	f4                   	hlt    
f0104190:	eb fd                	jmp    f010418f <sched_halt+0xcc>
		"sti\n"
		"1:\n"
		"hlt\n"
		"jmp 1b\n"
	: : "a" (thiscpu->cpu_ts.ts_esp0));
}
f0104192:	83 c4 10             	add    $0x10,%esp
f0104195:	c9                   	leave  
f0104196:	c3                   	ret    

f0104197 <sched_yield>:
void sched_halt(void);

// Choose a user environment to run and run it.
void
sched_yield(void)
{
f0104197:	55                   	push   %ebp
f0104198:	89 e5                	mov    %esp,%ebp
f010419a:	53                   	push   %ebx
f010419b:	83 ec 04             	sub    $0x4,%esp
	// no runnable environments, simply drop through to the code
	// below to halt the cpu.

	// LAB 4: Your code here.
    int cur_idx;
    if (curenv)
f010419e:	e8 33 16 00 00       	call   f01057d6 <cpunum>
f01041a3:	6b c0 74             	imul   $0x74,%eax,%eax
        cur_idx = ENVX(curenv->env_id);
    else
        cur_idx = 0;
f01041a6:	ba 00 00 00 00       	mov    $0x0,%edx
	// no runnable environments, simply drop through to the code
	// below to halt the cpu.

	// LAB 4: Your code here.
    int cur_idx;
    if (curenv)
f01041ab:	83 b8 28 b0 22 f0 00 	cmpl   $0x0,-0xfdd4fd8(%eax)
f01041b2:	74 17                	je     f01041cb <sched_yield+0x34>
        cur_idx = ENVX(curenv->env_id);
f01041b4:	e8 1d 16 00 00       	call   f01057d6 <cpunum>
f01041b9:	6b c0 74             	imul   $0x74,%eax,%eax
f01041bc:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f01041c2:	8b 50 48             	mov    0x48(%eax),%edx
f01041c5:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
    else
        cur_idx = 0;

    if(envs[cur_idx].env_status == ENV_RUNNABLE){
f01041cb:	8b 0d 44 a2 22 f0    	mov    0xf022a244,%ecx
f01041d1:	6b c2 7c             	imul   $0x7c,%edx,%eax
f01041d4:	01 c8                	add    %ecx,%eax
f01041d6:	83 78 54 02          	cmpl   $0x2,0x54(%eax)
f01041da:	75 09                	jne    f01041e5 <sched_yield+0x4e>
        env_run(&envs[cur_idx]);
f01041dc:	83 ec 0c             	sub    $0xc,%esp
f01041df:	50                   	push   %eax
f01041e0:	e8 3c f2 ff ff       	call   f0103421 <env_run>
    }
    for(int i = cur_idx + 1; i != cur_idx; i = (i + 1) % NENV){
f01041e5:	8d 42 01             	lea    0x1(%edx),%eax
f01041e8:	eb 28                	jmp    f0104212 <sched_yield+0x7b>
        if(envs[i].env_status == ENV_RUNNABLE){
f01041ea:	6b d8 7c             	imul   $0x7c,%eax,%ebx
f01041ed:	01 cb                	add    %ecx,%ebx
f01041ef:	83 7b 54 02          	cmpl   $0x2,0x54(%ebx)
f01041f3:	75 09                	jne    f01041fe <sched_yield+0x67>
            env_run(&envs[i]);
f01041f5:	83 ec 0c             	sub    $0xc,%esp
f01041f8:	53                   	push   %ebx
f01041f9:	e8 23 f2 ff ff       	call   f0103421 <env_run>
        cur_idx = 0;

    if(envs[cur_idx].env_status == ENV_RUNNABLE){
        env_run(&envs[cur_idx]);
    }
    for(int i = cur_idx + 1; i != cur_idx; i = (i + 1) % NENV){
f01041fe:	83 c0 01             	add    $0x1,%eax
f0104201:	89 c3                	mov    %eax,%ebx
f0104203:	c1 fb 1f             	sar    $0x1f,%ebx
f0104206:	c1 eb 16             	shr    $0x16,%ebx
f0104209:	01 d8                	add    %ebx,%eax
f010420b:	25 ff 03 00 00       	and    $0x3ff,%eax
f0104210:	29 d8                	sub    %ebx,%eax
f0104212:	39 c2                	cmp    %eax,%edx
f0104214:	75 d4                	jne    f01041ea <sched_yield+0x53>
        if(envs[i].env_status == ENV_RUNNABLE){
            env_run(&envs[i]);
            return;
        } 
    }
    if(curenv && curenv->env_status == ENV_RUNNING) {
f0104216:	e8 bb 15 00 00       	call   f01057d6 <cpunum>
f010421b:	6b c0 74             	imul   $0x74,%eax,%eax
f010421e:	83 b8 28 b0 22 f0 00 	cmpl   $0x0,-0xfdd4fd8(%eax)
f0104225:	74 2a                	je     f0104251 <sched_yield+0xba>
f0104227:	e8 aa 15 00 00       	call   f01057d6 <cpunum>
f010422c:	6b c0 74             	imul   $0x74,%eax,%eax
f010422f:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0104235:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0104239:	75 16                	jne    f0104251 <sched_yield+0xba>
        env_run(curenv);
f010423b:	e8 96 15 00 00       	call   f01057d6 <cpunum>
f0104240:	83 ec 0c             	sub    $0xc,%esp
f0104243:	6b c0 74             	imul   $0x74,%eax,%eax
f0104246:	ff b0 28 b0 22 f0    	pushl  -0xfdd4fd8(%eax)
f010424c:	e8 d0 f1 ff ff       	call   f0103421 <env_run>
        return;
    }

	// sched_halt never returns
	sched_halt();
f0104251:	e8 6d fe ff ff       	call   f01040c3 <sched_halt>
}
f0104256:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0104259:	c9                   	leave  
f010425a:	c3                   	ret    

f010425b <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f010425b:	55                   	push   %ebp
f010425c:	89 e5                	mov    %esp,%ebp
f010425e:	57                   	push   %edi
f010425f:	56                   	push   %esi
f0104260:	53                   	push   %ebx
f0104261:	83 ec 1c             	sub    $0x1c,%esp
f0104264:	8b 45 08             	mov    0x8(%ebp),%eax
	// Return any appropriate return value.
	// LAB 3: Your code here.

	//panic("syscall not implemented");

	switch (syscallno) {
f0104267:	83 f8 0a             	cmp    $0xa,%eax
f010426a:	0f 87 90 03 00 00    	ja     f0104600 <syscall+0x3a5>
f0104270:	ff 24 85 80 75 10 f0 	jmp    *-0xfef8a80(,%eax,4)
{
	// Check that the user has permission to read memory [s, s+len).
	// Destroy the environment if not.

	// LAB 3: Your code here.
	user_mem_assert(curenv, s, len, PTE_U | PTE_W);
f0104277:	e8 5a 15 00 00       	call   f01057d6 <cpunum>
f010427c:	6a 06                	push   $0x6
f010427e:	ff 75 10             	pushl  0x10(%ebp)
f0104281:	ff 75 0c             	pushl  0xc(%ebp)
f0104284:	6b c0 74             	imul   $0x74,%eax,%eax
f0104287:	ff b0 28 b0 22 f0    	pushl  -0xfdd4fd8(%eax)
f010428d:	e8 b3 ea ff ff       	call   f0102d45 <user_mem_assert>

	// Print the string supplied by the user.
	cprintf("%.*s", len, s);
f0104292:	83 c4 0c             	add    $0xc,%esp
f0104295:	ff 75 0c             	pushl  0xc(%ebp)
f0104298:	ff 75 10             	pushl  0x10(%ebp)
f010429b:	68 46 75 10 f0       	push   $0xf0107546
f01042a0:	e8 b2 f3 ff ff       	call   f0103657 <cprintf>
f01042a5:	83 c4 10             	add    $0x10,%esp
	//panic("syscall not implemented");

	switch (syscallno) {
		case SYS_cputs:
			sys_cputs((const char *) a1,(size_t) a2);
			return 0;
f01042a8:	b8 00 00 00 00       	mov    $0x0,%eax
f01042ad:	e9 53 03 00 00       	jmp    f0104605 <syscall+0x3aa>
// Read a character from the system console without blocking.
// Returns the character, or 0 if there is no input waiting.
static int
sys_cgetc(void)
{
	return cons_getc();
f01042b2:	e8 3e c3 ff ff       	call   f01005f5 <cons_getc>
	switch (syscallno) {
		case SYS_cputs:
			sys_cputs((const char *) a1,(size_t) a2);
			return 0;
		case SYS_cgetc:
			return sys_cgetc();
f01042b7:	e9 49 03 00 00       	jmp    f0104605 <syscall+0x3aa>

// Returns the current environment's envid.
static envid_t
sys_getenvid(void)
{
	return curenv->env_id;
f01042bc:	e8 15 15 00 00       	call   f01057d6 <cpunum>
f01042c1:	6b c0 74             	imul   $0x74,%eax,%eax
f01042c4:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f01042ca:	8b 40 48             	mov    0x48(%eax),%eax
			sys_cputs((const char *) a1,(size_t) a2);
			return 0;
		case SYS_cgetc:
			return sys_cgetc();
		case SYS_getenvid:
			return sys_getenvid();
f01042cd:	e9 33 03 00 00       	jmp    f0104605 <syscall+0x3aa>
sys_env_destroy(envid_t envid)
{
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
f01042d2:	83 ec 04             	sub    $0x4,%esp
f01042d5:	6a 01                	push   $0x1
f01042d7:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01042da:	50                   	push   %eax
f01042db:	ff 75 0c             	pushl  0xc(%ebp)
f01042de:	e8 17 eb ff ff       	call   f0102dfa <envid2env>
f01042e3:	83 c4 10             	add    $0x10,%esp
f01042e6:	85 c0                	test   %eax,%eax
f01042e8:	0f 88 17 03 00 00    	js     f0104605 <syscall+0x3aa>
		return r;
	if (e == curenv)
f01042ee:	e8 e3 14 00 00       	call   f01057d6 <cpunum>
f01042f3:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01042f6:	6b c0 74             	imul   $0x74,%eax,%eax
f01042f9:	39 90 28 b0 22 f0    	cmp    %edx,-0xfdd4fd8(%eax)
f01042ff:	75 23                	jne    f0104324 <syscall+0xc9>
		cprintf("[%08x] exiting gracefully\n", curenv->env_id);
f0104301:	e8 d0 14 00 00       	call   f01057d6 <cpunum>
f0104306:	83 ec 08             	sub    $0x8,%esp
f0104309:	6b c0 74             	imul   $0x74,%eax,%eax
f010430c:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0104312:	ff 70 48             	pushl  0x48(%eax)
f0104315:	68 4b 75 10 f0       	push   $0xf010754b
f010431a:	e8 38 f3 ff ff       	call   f0103657 <cprintf>
f010431f:	83 c4 10             	add    $0x10,%esp
f0104322:	eb 25                	jmp    f0104349 <syscall+0xee>
	else
		cprintf("[%08x] destroying %08x\n", curenv->env_id, e->env_id);
f0104324:	8b 5a 48             	mov    0x48(%edx),%ebx
f0104327:	e8 aa 14 00 00       	call   f01057d6 <cpunum>
f010432c:	83 ec 04             	sub    $0x4,%esp
f010432f:	53                   	push   %ebx
f0104330:	6b c0 74             	imul   $0x74,%eax,%eax
f0104333:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0104339:	ff 70 48             	pushl  0x48(%eax)
f010433c:	68 66 75 10 f0       	push   $0xf0107566
f0104341:	e8 11 f3 ff ff       	call   f0103657 <cprintf>
f0104346:	83 c4 10             	add    $0x10,%esp
	env_destroy(e);
f0104349:	83 ec 0c             	sub    $0xc,%esp
f010434c:	ff 75 e4             	pushl  -0x1c(%ebp)
f010434f:	e8 2e f0 ff ff       	call   f0103382 <env_destroy>
f0104354:	83 c4 10             	add    $0x10,%esp
	return 0;
f0104357:	b8 00 00 00 00       	mov    $0x0,%eax
f010435c:	e9 a4 02 00 00       	jmp    f0104605 <syscall+0x3aa>

// Deschedule current environment and pick a different one to run.
static void
sys_yield(void)
{
	sched_yield();
f0104361:	e8 31 fe ff ff       	call   f0104197 <sched_yield>
	// status is set to ENV_NOT_RUNNABLE, and the register set is copied
	// from the current environment -- but tweaked so sys_exofork
	// will appear to return 0.
    struct Env *child_env;
    int r;
    r = env_alloc(&child_env, curenv->env_id);
f0104366:	e8 6b 14 00 00       	call   f01057d6 <cpunum>
f010436b:	83 ec 08             	sub    $0x8,%esp
f010436e:	6b c0 74             	imul   $0x74,%eax,%eax
f0104371:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0104377:	ff 70 48             	pushl  0x48(%eax)
f010437a:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010437d:	50                   	push   %eax
f010437e:	e8 89 eb ff ff       	call   f0102f0c <env_alloc>
    if(r!=0)
f0104383:	83 c4 10             	add    $0x10,%esp
f0104386:	85 c0                	test   %eax,%eax
f0104388:	0f 85 77 02 00 00    	jne    f0104605 <syscall+0x3aa>
        return r;
    child_env->env_status = ENV_NOT_RUNNABLE;
f010438e:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0104391:	c7 43 54 04 00 00 00 	movl   $0x4,0x54(%ebx)
    child_env->env_tf = curenv->env_tf;
f0104398:	e8 39 14 00 00       	call   f01057d6 <cpunum>
f010439d:	6b c0 74             	imul   $0x74,%eax,%eax
f01043a0:	8b b0 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%esi
f01043a6:	b9 11 00 00 00       	mov    $0x11,%ecx
f01043ab:	89 df                	mov    %ebx,%edi
f01043ad:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
    child_env->env_tf.tf_regs.reg_eax = 0;
f01043af:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01043b2:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)
    return child_env->env_id;
f01043b9:	8b 40 48             	mov    0x48(%eax),%eax
f01043bc:	e9 44 02 00 00       	jmp    f0104605 <syscall+0x3aa>
	//   parameters for correctness.
	//   If page_insert() fails, remember to free the page you
	//   allocated!

    struct Env *env;
    int r = envid2env(envid, &env, 1);
f01043c1:	83 ec 04             	sub    $0x4,%esp
f01043c4:	6a 01                	push   $0x1
f01043c6:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01043c9:	50                   	push   %eax
f01043ca:	ff 75 0c             	pushl  0xc(%ebp)
f01043cd:	e8 28 ea ff ff       	call   f0102dfa <envid2env>
    if(r!=0)
f01043d2:	83 c4 10             	add    $0x10,%esp
f01043d5:	85 c0                	test   %eax,%eax
f01043d7:	0f 85 28 02 00 00    	jne    f0104605 <syscall+0x3aa>
        return r;
    if (va > (void *) UTOP || va != ROUNDDOWN(va, PGSIZE))
f01043dd:	81 7d 10 00 00 c0 ee 	cmpl   $0xeec00000,0x10(%ebp)
f01043e4:	77 67                	ja     f010444d <syscall+0x1f2>
f01043e6:	f7 45 10 ff 0f 00 00 	testl  $0xfff,0x10(%ebp)
f01043ed:	75 68                	jne    f0104457 <syscall+0x1fc>
       return -E_INVAL; 
    int flag = PTE_U | PTE_P;

    if ((perm & flag) != flag)
f01043ef:	8b 45 14             	mov    0x14(%ebp),%eax
f01043f2:	83 e0 05             	and    $0x5,%eax
f01043f5:	83 f8 05             	cmp    $0x5,%eax
f01043f8:	75 67                	jne    f0104461 <syscall+0x206>
        return -E_INVAL;

    if (perm & (~(PTE_U | PTE_P | PTE_AVAIL | PTE_W)))
f01043fa:	f7 45 14 f8 f1 ff ff 	testl  $0xfffff1f8,0x14(%ebp)
f0104401:	75 68                	jne    f010446b <syscall+0x210>
        return -E_INVAL;

    struct PageInfo *pp = page_alloc(1);
f0104403:	83 ec 0c             	sub    $0xc,%esp
f0104406:	6a 01                	push   $0x1
f0104408:	e8 5a cb ff ff       	call   f0100f67 <page_alloc>
f010440d:	89 c3                	mov    %eax,%ebx
    if(pp == NULL)
f010440f:	83 c4 10             	add    $0x10,%esp
f0104412:	85 c0                	test   %eax,%eax
f0104414:	74 5f                	je     f0104475 <syscall+0x21a>
        return -E_NO_MEM;
    pp->pp_ref ++;
f0104416:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
    r = page_insert(env->env_pgdir, pp, va, perm);
f010441b:	ff 75 14             	pushl  0x14(%ebp)
f010441e:	ff 75 10             	pushl  0x10(%ebp)
f0104421:	50                   	push   %eax
f0104422:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104425:	ff 70 60             	pushl  0x60(%eax)
f0104428:	e8 df cd ff ff       	call   f010120c <page_insert>
f010442d:	89 c6                	mov    %eax,%esi
    if(r!=0){
f010442f:	83 c4 10             	add    $0x10,%esp
f0104432:	85 c0                	test   %eax,%eax
f0104434:	0f 84 cb 01 00 00    	je     f0104605 <syscall+0x3aa>
        page_free(pp);
f010443a:	83 ec 0c             	sub    $0xc,%esp
f010443d:	53                   	push   %ebx
f010443e:	e8 9b cb ff ff       	call   f0100fde <page_free>
f0104443:	83 c4 10             	add    $0x10,%esp
        return r;
f0104446:	89 f0                	mov    %esi,%eax
f0104448:	e9 b8 01 00 00       	jmp    f0104605 <syscall+0x3aa>
    struct Env *env;
    int r = envid2env(envid, &env, 1);
    if(r!=0)
        return r;
    if (va > (void *) UTOP || va != ROUNDDOWN(va, PGSIZE))
       return -E_INVAL; 
f010444d:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104452:	e9 ae 01 00 00       	jmp    f0104605 <syscall+0x3aa>
f0104457:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f010445c:	e9 a4 01 00 00       	jmp    f0104605 <syscall+0x3aa>
    int flag = PTE_U | PTE_P;

    if ((perm & flag) != flag)
        return -E_INVAL;
f0104461:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104466:	e9 9a 01 00 00       	jmp    f0104605 <syscall+0x3aa>

    if (perm & (~(PTE_U | PTE_P | PTE_AVAIL | PTE_W)))
        return -E_INVAL;
f010446b:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104470:	e9 90 01 00 00       	jmp    f0104605 <syscall+0x3aa>

    struct PageInfo *pp = page_alloc(1);
    if(pp == NULL)
        return -E_NO_MEM;
f0104475:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f010447a:	e9 86 01 00 00       	jmp    f0104605 <syscall+0x3aa>
	//   parameters for correctness.
	//   Use the third argument to page_lookup() to
	//   check the current permissions on the page.

    struct Env *srcenv, *dstenv;
    int r = envid2env(srcenvid, &srcenv, 1);
f010447f:	83 ec 04             	sub    $0x4,%esp
f0104482:	6a 01                	push   $0x1
f0104484:	8d 45 dc             	lea    -0x24(%ebp),%eax
f0104487:	50                   	push   %eax
f0104488:	ff 75 0c             	pushl  0xc(%ebp)
f010448b:	e8 6a e9 ff ff       	call   f0102dfa <envid2env>
    if(r!=0)
f0104490:	83 c4 10             	add    $0x10,%esp
f0104493:	85 c0                	test   %eax,%eax
f0104495:	0f 85 6a 01 00 00    	jne    f0104605 <syscall+0x3aa>
        return r;
    r = envid2env(dstenvid, &dstenv, 1);
f010449b:	83 ec 04             	sub    $0x4,%esp
f010449e:	6a 01                	push   $0x1
f01044a0:	8d 45 e0             	lea    -0x20(%ebp),%eax
f01044a3:	50                   	push   %eax
f01044a4:	ff 75 14             	pushl  0x14(%ebp)
f01044a7:	e8 4e e9 ff ff       	call   f0102dfa <envid2env>
    if(r!=0)
f01044ac:	83 c4 10             	add    $0x10,%esp
f01044af:	85 c0                	test   %eax,%eax
f01044b1:	0f 85 4e 01 00 00    	jne    f0104605 <syscall+0x3aa>
        return r;

    if (srcva >= (void *) UTOP || dstva >= (void *) UTOP || 
f01044b7:	81 7d 10 ff ff bf ee 	cmpl   $0xeebfffff,0x10(%ebp)
f01044be:	77 77                	ja     f0104537 <syscall+0x2dc>
f01044c0:	81 7d 18 ff ff bf ee 	cmpl   $0xeebfffff,0x18(%ebp)
f01044c7:	77 6e                	ja     f0104537 <syscall+0x2dc>
f01044c9:	f7 45 10 ff 0f 00 00 	testl  $0xfff,0x10(%ebp)
f01044d0:	75 6f                	jne    f0104541 <syscall+0x2e6>
        srcva != ROUNDDOWN(srcva, PGSIZE) || dstva != ROUNDDOWN(dstva, PGSIZE))
        return -E_INVAL; 
f01044d2:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
    r = envid2env(dstenvid, &dstenv, 1);
    if(r!=0)
        return r;

    if (srcva >= (void *) UTOP || dstva >= (void *) UTOP || 
        srcva != ROUNDDOWN(srcva, PGSIZE) || dstva != ROUNDDOWN(dstva, PGSIZE))
f01044d7:	f7 45 18 ff 0f 00 00 	testl  $0xfff,0x18(%ebp)
f01044de:	0f 85 21 01 00 00    	jne    f0104605 <syscall+0x3aa>
        return -E_INVAL; 

    pte_t *pte;
    struct PageInfo *pp = page_lookup(srcenv->env_pgdir, srcva, &pte);
f01044e4:	83 ec 04             	sub    $0x4,%esp
f01044e7:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01044ea:	50                   	push   %eax
f01044eb:	ff 75 10             	pushl  0x10(%ebp)
f01044ee:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01044f1:	ff 70 60             	pushl  0x60(%eax)
f01044f4:	e8 3e cc ff ff       	call   f0101137 <page_lookup>
    if(pp == NULL)    
f01044f9:	83 c4 10             	add    $0x10,%esp
f01044fc:	85 c0                	test   %eax,%eax
f01044fe:	74 4b                	je     f010454b <syscall+0x2f0>
        return -E_INVAL;

    if ((!(perm & (PTE_U | PTE_P))) || (perm & (~(PTE_U | PTE_P | PTE_AVAIL | PTE_W))))
f0104500:	f6 45 1c 05          	testb  $0x5,0x1c(%ebp)
f0104504:	74 4f                	je     f0104555 <syscall+0x2fa>
f0104506:	f7 45 1c f8 f1 ff ff 	testl  $0xfffff1f8,0x1c(%ebp)
f010450d:	75 50                	jne    f010455f <syscall+0x304>
        return -E_INVAL;

    if ((perm & PTE_W) && !(*pte & PTE_W))
f010450f:	f6 45 1c 02          	testb  $0x2,0x1c(%ebp)
f0104513:	74 08                	je     f010451d <syscall+0x2c2>
f0104515:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0104518:	f6 02 02             	testb  $0x2,(%edx)
f010451b:	74 4c                	je     f0104569 <syscall+0x30e>
        return -E_INVAL;

    r = page_insert(dstenv->env_pgdir, pp, dstva, perm);
f010451d:	ff 75 1c             	pushl  0x1c(%ebp)
f0104520:	ff 75 18             	pushl  0x18(%ebp)
f0104523:	50                   	push   %eax
f0104524:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104527:	ff 70 60             	pushl  0x60(%eax)
f010452a:	e8 dd cc ff ff       	call   f010120c <page_insert>
f010452f:	83 c4 10             	add    $0x10,%esp
f0104532:	e9 ce 00 00 00       	jmp    f0104605 <syscall+0x3aa>
    if(r!=0)
        return r;

    if (srcva >= (void *) UTOP || dstva >= (void *) UTOP || 
        srcva != ROUNDDOWN(srcva, PGSIZE) || dstva != ROUNDDOWN(dstva, PGSIZE))
        return -E_INVAL; 
f0104537:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f010453c:	e9 c4 00 00 00       	jmp    f0104605 <syscall+0x3aa>
f0104541:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104546:	e9 ba 00 00 00       	jmp    f0104605 <syscall+0x3aa>

    pte_t *pte;
    struct PageInfo *pp = page_lookup(srcenv->env_pgdir, srcva, &pte);
    if(pp == NULL)    
        return -E_INVAL;
f010454b:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104550:	e9 b0 00 00 00       	jmp    f0104605 <syscall+0x3aa>

    if ((!(perm & (PTE_U | PTE_P))) || (perm & (~(PTE_U | PTE_P | PTE_AVAIL | PTE_W))))
        return -E_INVAL;
f0104555:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f010455a:	e9 a6 00 00 00       	jmp    f0104605 <syscall+0x3aa>
f010455f:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104564:	e9 9c 00 00 00       	jmp    f0104605 <syscall+0x3aa>

    if ((perm & PTE_W) && !(*pte & PTE_W))
        return -E_INVAL;
f0104569:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
        case SYS_exofork:
            return sys_exofork();
        case SYS_page_alloc:
            return sys_page_alloc(a1, (void *) a2, a3);
        case SYS_page_map:
            return sys_page_map(a1, (void *) a2, a3, (void *) a4, a5);
f010456e:	e9 92 00 00 00       	jmp    f0104605 <syscall+0x3aa>
sys_page_unmap(envid_t envid, void *va)
{
	// Hint: This function is a wrapper around page_remove().

    struct Env *env;
    int r = envid2env(envid, &env, 1);
f0104573:	83 ec 04             	sub    $0x4,%esp
f0104576:	6a 01                	push   $0x1
f0104578:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010457b:	50                   	push   %eax
f010457c:	ff 75 0c             	pushl  0xc(%ebp)
f010457f:	e8 76 e8 ff ff       	call   f0102dfa <envid2env>
    if(r!=0)
f0104584:	83 c4 10             	add    $0x10,%esp
f0104587:	85 c0                	test   %eax,%eax
f0104589:	75 7a                	jne    f0104605 <syscall+0x3aa>
        return r;
    if (va > (void *)UTOP || va != ROUNDDOWN(va, PGSIZE))
f010458b:	81 7d 10 00 00 c0 ee 	cmpl   $0xeec00000,0x10(%ebp)
f0104592:	77 29                	ja     f01045bd <syscall+0x362>
        return -E_INVAL; 
f0104594:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

    struct Env *env;
    int r = envid2env(envid, &env, 1);
    if(r!=0)
        return r;
    if (va > (void *)UTOP || va != ROUNDDOWN(va, PGSIZE))
f0104599:	f7 45 10 ff 0f 00 00 	testl  $0xfff,0x10(%ebp)
f01045a0:	75 63                	jne    f0104605 <syscall+0x3aa>
        return -E_INVAL; 
    
    page_remove(env->env_pgdir, va);
f01045a2:	83 ec 08             	sub    $0x8,%esp
f01045a5:	ff 75 10             	pushl  0x10(%ebp)
f01045a8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01045ab:	ff 70 60             	pushl  0x60(%eax)
f01045ae:	e8 13 cc ff ff       	call   f01011c6 <page_remove>
f01045b3:	83 c4 10             	add    $0x10,%esp
    return 0;
f01045b6:	b8 00 00 00 00       	mov    $0x0,%eax
f01045bb:	eb 48                	jmp    f0104605 <syscall+0x3aa>
    struct Env *env;
    int r = envid2env(envid, &env, 1);
    if(r!=0)
        return r;
    if (va > (void *)UTOP || va != ROUNDDOWN(va, PGSIZE))
        return -E_INVAL; 
f01045bd:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f01045c2:	eb 41                	jmp    f0104605 <syscall+0x3aa>
	// envid to a struct Env.
	// You should set envid2env's third argument to 1, which will
	// check whether the current environment has permission to set
	// envid's status.
    struct Env *env;
    int r = envid2env(envid, &env, 1);
f01045c4:	83 ec 04             	sub    $0x4,%esp
f01045c7:	6a 01                	push   $0x1
f01045c9:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01045cc:	50                   	push   %eax
f01045cd:	ff 75 0c             	pushl  0xc(%ebp)
f01045d0:	e8 25 e8 ff ff       	call   f0102dfa <envid2env>
    if(r!=0)
f01045d5:	83 c4 10             	add    $0x10,%esp
f01045d8:	85 c0                	test   %eax,%eax
f01045da:	75 29                	jne    f0104605 <syscall+0x3aa>
        return r;
    if(env->env_status == ENV_RUNNABLE || env->env_status == ENV_NOT_RUNNABLE){
f01045dc:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01045df:	8b 42 54             	mov    0x54(%edx),%eax
f01045e2:	83 e8 02             	sub    $0x2,%eax
f01045e5:	a9 fd ff ff ff       	test   $0xfffffffd,%eax
f01045ea:	75 0d                	jne    f01045f9 <syscall+0x39e>
        env->env_status = status;
f01045ec:	8b 45 10             	mov    0x10(%ebp),%eax
f01045ef:	89 42 54             	mov    %eax,0x54(%edx)
        return 0;
f01045f2:	b8 00 00 00 00       	mov    $0x0,%eax
f01045f7:	eb 0c                	jmp    f0104605 <syscall+0x3aa>
    }
    return -E_INVAL; 
f01045f9:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
        case SYS_page_map:
            return sys_page_map(a1, (void *) a2, a3, (void *) a4, a5);
        case SYS_page_unmap:
            return sys_page_unmap(a1, (void *) a2);
        case SYS_env_set_status:
            return sys_env_set_status(a1, a2);
f01045fe:	eb 05                	jmp    f0104605 <syscall+0x3aa>
		default:
			return -E_INVAL;
f0104600:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
	}
}
f0104605:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104608:	5b                   	pop    %ebx
f0104609:	5e                   	pop    %esi
f010460a:	5f                   	pop    %edi
f010460b:	5d                   	pop    %ebp
f010460c:	c3                   	ret    

f010460d <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f010460d:	55                   	push   %ebp
f010460e:	89 e5                	mov    %esp,%ebp
f0104610:	57                   	push   %edi
f0104611:	56                   	push   %esi
f0104612:	53                   	push   %ebx
f0104613:	83 ec 14             	sub    $0x14,%esp
f0104616:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0104619:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f010461c:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f010461f:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0104622:	8b 1a                	mov    (%edx),%ebx
f0104624:	8b 01                	mov    (%ecx),%eax
f0104626:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0104629:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0104630:	eb 7f                	jmp    f01046b1 <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f0104632:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0104635:	01 d8                	add    %ebx,%eax
f0104637:	89 c6                	mov    %eax,%esi
f0104639:	c1 ee 1f             	shr    $0x1f,%esi
f010463c:	01 c6                	add    %eax,%esi
f010463e:	d1 fe                	sar    %esi
f0104640:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0104643:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0104646:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f0104649:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f010464b:	eb 03                	jmp    f0104650 <stab_binsearch+0x43>
			m--;
f010464d:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0104650:	39 c3                	cmp    %eax,%ebx
f0104652:	7f 0d                	jg     f0104661 <stab_binsearch+0x54>
f0104654:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0104658:	83 ea 0c             	sub    $0xc,%edx
f010465b:	39 f9                	cmp    %edi,%ecx
f010465d:	75 ee                	jne    f010464d <stab_binsearch+0x40>
f010465f:	eb 05                	jmp    f0104666 <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0104661:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f0104664:	eb 4b                	jmp    f01046b1 <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0104666:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0104669:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010466c:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0104670:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0104673:	76 11                	jbe    f0104686 <stab_binsearch+0x79>
			*region_left = m;
f0104675:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0104678:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f010467a:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010467d:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0104684:	eb 2b                	jmp    f01046b1 <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0104686:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0104689:	73 14                	jae    f010469f <stab_binsearch+0x92>
			*region_right = m - 1;
f010468b:	83 e8 01             	sub    $0x1,%eax
f010468e:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0104691:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0104694:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0104696:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f010469d:	eb 12                	jmp    f01046b1 <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f010469f:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01046a2:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f01046a4:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f01046a8:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01046aa:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f01046b1:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f01046b4:	0f 8e 78 ff ff ff    	jle    f0104632 <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f01046ba:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f01046be:	75 0f                	jne    f01046cf <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f01046c0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01046c3:	8b 00                	mov    (%eax),%eax
f01046c5:	83 e8 01             	sub    $0x1,%eax
f01046c8:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01046cb:	89 06                	mov    %eax,(%esi)
f01046cd:	eb 2c                	jmp    f01046fb <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01046cf:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01046d2:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f01046d4:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01046d7:	8b 0e                	mov    (%esi),%ecx
f01046d9:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01046dc:	8b 75 ec             	mov    -0x14(%ebp),%esi
f01046df:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01046e2:	eb 03                	jmp    f01046e7 <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f01046e4:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01046e7:	39 c8                	cmp    %ecx,%eax
f01046e9:	7e 0b                	jle    f01046f6 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f01046eb:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f01046ef:	83 ea 0c             	sub    $0xc,%edx
f01046f2:	39 df                	cmp    %ebx,%edi
f01046f4:	75 ee                	jne    f01046e4 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f01046f6:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01046f9:	89 06                	mov    %eax,(%esi)
	}
}
f01046fb:	83 c4 14             	add    $0x14,%esp
f01046fe:	5b                   	pop    %ebx
f01046ff:	5e                   	pop    %esi
f0104700:	5f                   	pop    %edi
f0104701:	5d                   	pop    %ebp
f0104702:	c3                   	ret    

f0104703 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0104703:	55                   	push   %ebp
f0104704:	89 e5                	mov    %esp,%ebp
f0104706:	57                   	push   %edi
f0104707:	56                   	push   %esi
f0104708:	53                   	push   %ebx
f0104709:	83 ec 3c             	sub    $0x3c,%esp
f010470c:	8b 7d 08             	mov    0x8(%ebp),%edi
f010470f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0104712:	c7 03 ac 75 10 f0    	movl   $0xf01075ac,(%ebx)
	info->eip_line = 0;
f0104718:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f010471f:	c7 43 08 ac 75 10 f0 	movl   $0xf01075ac,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0104726:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f010472d:	89 7b 10             	mov    %edi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0104730:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0104737:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f010473d:	0f 87 f6 00 00 00    	ja     f0104839 <debuginfo_eip+0x136>
		const struct UserStabData *usd = (const struct UserStabData *) USTABDATA;

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, usd, sizeof(struct UserStabData), PTE_U) < 0) {
f0104743:	e8 8e 10 00 00       	call   f01057d6 <cpunum>
f0104748:	6a 04                	push   $0x4
f010474a:	6a 10                	push   $0x10
f010474c:	68 00 00 20 00       	push   $0x200000
f0104751:	6b c0 74             	imul   $0x74,%eax,%eax
f0104754:	ff b0 28 b0 22 f0    	pushl  -0xfdd4fd8(%eax)
f010475a:	e8 60 e5 ff ff       	call   f0102cbf <user_mem_check>
f010475f:	83 c4 10             	add    $0x10,%esp
f0104762:	85 c0                	test   %eax,%eax
f0104764:	79 1f                	jns    f0104785 <debuginfo_eip+0x82>
			cprintf("debuginfo_eip: invalid usd addr %08x", usd);
f0104766:	83 ec 08             	sub    $0x8,%esp
f0104769:	68 00 00 20 00       	push   $0x200000
f010476e:	68 b8 75 10 f0       	push   $0xf01075b8
f0104773:	e8 df ee ff ff       	call   f0103657 <cprintf>
			return -1;
f0104778:	83 c4 10             	add    $0x10,%esp
f010477b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104780:	e9 97 02 00 00       	jmp    f0104a1c <debuginfo_eip+0x319>
		}

		stabs = usd->stabs;
f0104785:	a1 00 00 20 00       	mov    0x200000,%eax
f010478a:	89 45 c0             	mov    %eax,-0x40(%ebp)
		stab_end = usd->stab_end;
f010478d:	8b 35 04 00 20 00    	mov    0x200004,%esi
		stabstr = usd->stabstr;
f0104793:	8b 15 08 00 20 00    	mov    0x200008,%edx
f0104799:	89 55 b8             	mov    %edx,-0x48(%ebp)
		stabstr_end = usd->stabstr_end;
f010479c:	8b 15 0c 00 20 00    	mov    0x20000c,%edx
f01047a2:	89 55 bc             	mov    %edx,-0x44(%ebp)

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, stabs, stab_end-stabs+1, PTE_U) < 0){
f01047a5:	e8 2c 10 00 00       	call   f01057d6 <cpunum>
f01047aa:	6a 04                	push   $0x4
f01047ac:	89 f2                	mov    %esi,%edx
f01047ae:	8b 4d c0             	mov    -0x40(%ebp),%ecx
f01047b1:	29 ca                	sub    %ecx,%edx
f01047b3:	c1 fa 02             	sar    $0x2,%edx
f01047b6:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f01047bc:	83 c2 01             	add    $0x1,%edx
f01047bf:	52                   	push   %edx
f01047c0:	51                   	push   %ecx
f01047c1:	6b c0 74             	imul   $0x74,%eax,%eax
f01047c4:	ff b0 28 b0 22 f0    	pushl  -0xfdd4fd8(%eax)
f01047ca:	e8 f0 e4 ff ff       	call   f0102cbf <user_mem_check>
f01047cf:	83 c4 10             	add    $0x10,%esp
f01047d2:	85 c0                	test   %eax,%eax
f01047d4:	79 1d                	jns    f01047f3 <debuginfo_eip+0xf0>
			cprintf("debuginfo_eip: invalid stabs addr %08x", stabs);
f01047d6:	83 ec 08             	sub    $0x8,%esp
f01047d9:	ff 75 c0             	pushl  -0x40(%ebp)
f01047dc:	68 e0 75 10 f0       	push   $0xf01075e0
f01047e1:	e8 71 ee ff ff       	call   f0103657 <cprintf>
			return -1;
f01047e6:	83 c4 10             	add    $0x10,%esp
f01047e9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01047ee:	e9 29 02 00 00       	jmp    f0104a1c <debuginfo_eip+0x319>
		}
		if (user_mem_check(curenv, stabstr, stabstr_end-stabstr+1, PTE_U) < 0) {
f01047f3:	e8 de 0f 00 00       	call   f01057d6 <cpunum>
f01047f8:	6a 04                	push   $0x4
f01047fa:	8b 55 bc             	mov    -0x44(%ebp),%edx
f01047fd:	8b 4d b8             	mov    -0x48(%ebp),%ecx
f0104800:	29 ca                	sub    %ecx,%edx
f0104802:	83 c2 01             	add    $0x1,%edx
f0104805:	52                   	push   %edx
f0104806:	51                   	push   %ecx
f0104807:	6b c0 74             	imul   $0x74,%eax,%eax
f010480a:	ff b0 28 b0 22 f0    	pushl  -0xfdd4fd8(%eax)
f0104810:	e8 aa e4 ff ff       	call   f0102cbf <user_mem_check>
f0104815:	83 c4 10             	add    $0x10,%esp
f0104818:	85 c0                	test   %eax,%eax
f010481a:	79 37                	jns    f0104853 <debuginfo_eip+0x150>
			cprintf("debuginfo_eip: invalid stabstr addr %08x", stabstr);
f010481c:	83 ec 08             	sub    $0x8,%esp
f010481f:	ff 75 b8             	pushl  -0x48(%ebp)
f0104822:	68 08 76 10 f0       	push   $0xf0107608
f0104827:	e8 2b ee ff ff       	call   f0103657 <cprintf>
			return -1;
f010482c:	83 c4 10             	add    $0x10,%esp
f010482f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104834:	e9 e3 01 00 00       	jmp    f0104a1c <debuginfo_eip+0x319>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f0104839:	c7 45 bc 57 4f 11 f0 	movl   $0xf0114f57,-0x44(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f0104840:	c7 45 b8 f5 18 11 f0 	movl   $0xf01118f5,-0x48(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f0104847:	be f4 18 11 f0       	mov    $0xf01118f4,%esi
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f010484c:	c7 45 c0 14 7b 10 f0 	movl   $0xf0107b14,-0x40(%ebp)
			return -1;
		}
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0104853:	8b 45 bc             	mov    -0x44(%ebp),%eax
f0104856:	39 45 b8             	cmp    %eax,-0x48(%ebp)
f0104859:	0f 83 9c 01 00 00    	jae    f01049fb <debuginfo_eip+0x2f8>
f010485f:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f0104863:	0f 85 99 01 00 00    	jne    f0104a02 <debuginfo_eip+0x2ff>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0104869:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0104870:	2b 75 c0             	sub    -0x40(%ebp),%esi
f0104873:	c1 fe 02             	sar    $0x2,%esi
f0104876:	69 c6 ab aa aa aa    	imul   $0xaaaaaaab,%esi,%eax
f010487c:	83 e8 01             	sub    $0x1,%eax
f010487f:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0104882:	83 ec 08             	sub    $0x8,%esp
f0104885:	57                   	push   %edi
f0104886:	6a 64                	push   $0x64
f0104888:	8d 55 e0             	lea    -0x20(%ebp),%edx
f010488b:	89 d1                	mov    %edx,%ecx
f010488d:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0104890:	8b 75 c0             	mov    -0x40(%ebp),%esi
f0104893:	89 f0                	mov    %esi,%eax
f0104895:	e8 73 fd ff ff       	call   f010460d <stab_binsearch>
	if (lfile == 0)
f010489a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010489d:	83 c4 10             	add    $0x10,%esp
f01048a0:	85 c0                	test   %eax,%eax
f01048a2:	0f 84 61 01 00 00    	je     f0104a09 <debuginfo_eip+0x306>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f01048a8:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f01048ab:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01048ae:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f01048b1:	83 ec 08             	sub    $0x8,%esp
f01048b4:	57                   	push   %edi
f01048b5:	6a 24                	push   $0x24
f01048b7:	8d 55 d8             	lea    -0x28(%ebp),%edx
f01048ba:	89 d1                	mov    %edx,%ecx
f01048bc:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01048bf:	89 f0                	mov    %esi,%eax
f01048c1:	e8 47 fd ff ff       	call   f010460d <stab_binsearch>

	if (lfun <= rfun) {
f01048c6:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01048c9:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01048cc:	83 c4 10             	add    $0x10,%esp
f01048cf:	39 d0                	cmp    %edx,%eax
f01048d1:	7f 2e                	jg     f0104901 <debuginfo_eip+0x1fe>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f01048d3:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f01048d6:	8d 34 8e             	lea    (%esi,%ecx,4),%esi
f01048d9:	89 75 c4             	mov    %esi,-0x3c(%ebp)
f01048dc:	8b 36                	mov    (%esi),%esi
f01048de:	8b 4d bc             	mov    -0x44(%ebp),%ecx
f01048e1:	2b 4d b8             	sub    -0x48(%ebp),%ecx
f01048e4:	39 ce                	cmp    %ecx,%esi
f01048e6:	73 06                	jae    f01048ee <debuginfo_eip+0x1eb>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f01048e8:	03 75 b8             	add    -0x48(%ebp),%esi
f01048eb:	89 73 08             	mov    %esi,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f01048ee:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f01048f1:	8b 4e 08             	mov    0x8(%esi),%ecx
f01048f4:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f01048f7:	29 cf                	sub    %ecx,%edi
		// Search within the function definition for the line number.
		lline = lfun;
f01048f9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f01048fc:	89 55 d0             	mov    %edx,-0x30(%ebp)
f01048ff:	eb 0f                	jmp    f0104910 <debuginfo_eip+0x20d>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0104901:	89 7b 10             	mov    %edi,0x10(%ebx)
		lline = lfile;
f0104904:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104907:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f010490a:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010490d:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0104910:	83 ec 08             	sub    $0x8,%esp
f0104913:	6a 3a                	push   $0x3a
f0104915:	ff 73 08             	pushl  0x8(%ebx)
f0104918:	e8 7a 08 00 00       	call   f0105197 <strfind>
f010491d:	2b 43 08             	sub    0x8(%ebx),%eax
f0104920:	89 43 0c             	mov    %eax,0xc(%ebx)
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.

	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);	
f0104923:	83 c4 08             	add    $0x8,%esp
f0104926:	57                   	push   %edi
f0104927:	6a 44                	push   $0x44
f0104929:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f010492c:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f010492f:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0104932:	89 f8                	mov    %edi,%eax
f0104934:	e8 d4 fc ff ff       	call   f010460d <stab_binsearch>
	if (lline > rline)
f0104939:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010493c:	83 c4 10             	add    $0x10,%esp
f010493f:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0104942:	0f 8f c8 00 00 00    	jg     f0104a10 <debuginfo_eip+0x30d>
		    return -1;
	info->eip_line = stabs[lline].n_desc;
f0104948:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010494b:	8d 14 97             	lea    (%edi,%edx,4),%edx
f010494e:	0f b7 4a 06          	movzwl 0x6(%edx),%ecx
f0104952:	89 4b 04             	mov    %ecx,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0104955:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104958:	c6 45 c4 00          	movb   $0x0,-0x3c(%ebp)
f010495c:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f010495f:	eb 0a                	jmp    f010496b <debuginfo_eip+0x268>
f0104961:	83 e8 01             	sub    $0x1,%eax
f0104964:	83 ea 0c             	sub    $0xc,%edx
f0104967:	c6 45 c4 01          	movb   $0x1,-0x3c(%ebp)
f010496b:	39 c7                	cmp    %eax,%edi
f010496d:	7e 05                	jle    f0104974 <debuginfo_eip+0x271>
f010496f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104972:	eb 47                	jmp    f01049bb <debuginfo_eip+0x2b8>
	       && stabs[lline].n_type != N_SOL
f0104974:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0104978:	80 f9 84             	cmp    $0x84,%cl
f010497b:	75 0e                	jne    f010498b <debuginfo_eip+0x288>
f010497d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104980:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f0104984:	74 1c                	je     f01049a2 <debuginfo_eip+0x29f>
f0104986:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0104989:	eb 17                	jmp    f01049a2 <debuginfo_eip+0x29f>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f010498b:	80 f9 64             	cmp    $0x64,%cl
f010498e:	75 d1                	jne    f0104961 <debuginfo_eip+0x25e>
f0104990:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f0104994:	74 cb                	je     f0104961 <debuginfo_eip+0x25e>
f0104996:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104999:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f010499d:	74 03                	je     f01049a2 <debuginfo_eip+0x29f>
f010499f:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f01049a2:	8d 04 40             	lea    (%eax,%eax,2),%eax
f01049a5:	8b 7d c0             	mov    -0x40(%ebp),%edi
f01049a8:	8b 14 87             	mov    (%edi,%eax,4),%edx
f01049ab:	8b 45 bc             	mov    -0x44(%ebp),%eax
f01049ae:	8b 7d b8             	mov    -0x48(%ebp),%edi
f01049b1:	29 f8                	sub    %edi,%eax
f01049b3:	39 c2                	cmp    %eax,%edx
f01049b5:	73 04                	jae    f01049bb <debuginfo_eip+0x2b8>
		info->eip_file = stabstr + stabs[lline].n_strx;
f01049b7:	01 fa                	add    %edi,%edx
f01049b9:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01049bb:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01049be:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01049c1:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01049c6:	39 f2                	cmp    %esi,%edx
f01049c8:	7d 52                	jge    f0104a1c <debuginfo_eip+0x319>
		for (lline = lfun + 1;
f01049ca:	83 c2 01             	add    $0x1,%edx
f01049cd:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f01049d0:	89 d0                	mov    %edx,%eax
f01049d2:	8d 14 52             	lea    (%edx,%edx,2),%edx
f01049d5:	8b 7d c0             	mov    -0x40(%ebp),%edi
f01049d8:	8d 14 97             	lea    (%edi,%edx,4),%edx
f01049db:	eb 04                	jmp    f01049e1 <debuginfo_eip+0x2de>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f01049dd:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f01049e1:	39 c6                	cmp    %eax,%esi
f01049e3:	7e 32                	jle    f0104a17 <debuginfo_eip+0x314>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f01049e5:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01049e9:	83 c0 01             	add    $0x1,%eax
f01049ec:	83 c2 0c             	add    $0xc,%edx
f01049ef:	80 f9 a0             	cmp    $0xa0,%cl
f01049f2:	74 e9                	je     f01049dd <debuginfo_eip+0x2da>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01049f4:	b8 00 00 00 00       	mov    $0x0,%eax
f01049f9:	eb 21                	jmp    f0104a1c <debuginfo_eip+0x319>
		}
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f01049fb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104a00:	eb 1a                	jmp    f0104a1c <debuginfo_eip+0x319>
f0104a02:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104a07:	eb 13                	jmp    f0104a1c <debuginfo_eip+0x319>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0104a09:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104a0e:	eb 0c                	jmp    f0104a1c <debuginfo_eip+0x319>
	//	which one.
	// Your code here.

	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);	
	if (lline > rline)
		    return -1;
f0104a10:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104a15:	eb 05                	jmp    f0104a1c <debuginfo_eip+0x319>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0104a17:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104a1c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104a1f:	5b                   	pop    %ebx
f0104a20:	5e                   	pop    %esi
f0104a21:	5f                   	pop    %edi
f0104a22:	5d                   	pop    %ebp
f0104a23:	c3                   	ret    

f0104a24 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0104a24:	55                   	push   %ebp
f0104a25:	89 e5                	mov    %esp,%ebp
f0104a27:	57                   	push   %edi
f0104a28:	56                   	push   %esi
f0104a29:	53                   	push   %ebx
f0104a2a:	83 ec 1c             	sub    $0x1c,%esp
f0104a2d:	89 c7                	mov    %eax,%edi
f0104a2f:	89 d6                	mov    %edx,%esi
f0104a31:	8b 45 08             	mov    0x8(%ebp),%eax
f0104a34:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104a37:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104a3a:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0104a3d:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0104a40:	bb 00 00 00 00       	mov    $0x0,%ebx
f0104a45:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0104a48:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0104a4b:	39 d3                	cmp    %edx,%ebx
f0104a4d:	72 05                	jb     f0104a54 <printnum+0x30>
f0104a4f:	39 45 10             	cmp    %eax,0x10(%ebp)
f0104a52:	77 45                	ja     f0104a99 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0104a54:	83 ec 0c             	sub    $0xc,%esp
f0104a57:	ff 75 18             	pushl  0x18(%ebp)
f0104a5a:	8b 45 14             	mov    0x14(%ebp),%eax
f0104a5d:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0104a60:	53                   	push   %ebx
f0104a61:	ff 75 10             	pushl  0x10(%ebp)
f0104a64:	83 ec 08             	sub    $0x8,%esp
f0104a67:	ff 75 e4             	pushl  -0x1c(%ebp)
f0104a6a:	ff 75 e0             	pushl  -0x20(%ebp)
f0104a6d:	ff 75 dc             	pushl  -0x24(%ebp)
f0104a70:	ff 75 d8             	pushl  -0x28(%ebp)
f0104a73:	e8 58 11 00 00       	call   f0105bd0 <__udivdi3>
f0104a78:	83 c4 18             	add    $0x18,%esp
f0104a7b:	52                   	push   %edx
f0104a7c:	50                   	push   %eax
f0104a7d:	89 f2                	mov    %esi,%edx
f0104a7f:	89 f8                	mov    %edi,%eax
f0104a81:	e8 9e ff ff ff       	call   f0104a24 <printnum>
f0104a86:	83 c4 20             	add    $0x20,%esp
f0104a89:	eb 18                	jmp    f0104aa3 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0104a8b:	83 ec 08             	sub    $0x8,%esp
f0104a8e:	56                   	push   %esi
f0104a8f:	ff 75 18             	pushl  0x18(%ebp)
f0104a92:	ff d7                	call   *%edi
f0104a94:	83 c4 10             	add    $0x10,%esp
f0104a97:	eb 03                	jmp    f0104a9c <printnum+0x78>
f0104a99:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0104a9c:	83 eb 01             	sub    $0x1,%ebx
f0104a9f:	85 db                	test   %ebx,%ebx
f0104aa1:	7f e8                	jg     f0104a8b <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0104aa3:	83 ec 08             	sub    $0x8,%esp
f0104aa6:	56                   	push   %esi
f0104aa7:	83 ec 04             	sub    $0x4,%esp
f0104aaa:	ff 75 e4             	pushl  -0x1c(%ebp)
f0104aad:	ff 75 e0             	pushl  -0x20(%ebp)
f0104ab0:	ff 75 dc             	pushl  -0x24(%ebp)
f0104ab3:	ff 75 d8             	pushl  -0x28(%ebp)
f0104ab6:	e8 45 12 00 00       	call   f0105d00 <__umoddi3>
f0104abb:	83 c4 14             	add    $0x14,%esp
f0104abe:	0f be 80 31 76 10 f0 	movsbl -0xfef89cf(%eax),%eax
f0104ac5:	50                   	push   %eax
f0104ac6:	ff d7                	call   *%edi
}
f0104ac8:	83 c4 10             	add    $0x10,%esp
f0104acb:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104ace:	5b                   	pop    %ebx
f0104acf:	5e                   	pop    %esi
f0104ad0:	5f                   	pop    %edi
f0104ad1:	5d                   	pop    %ebp
f0104ad2:	c3                   	ret    

f0104ad3 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0104ad3:	55                   	push   %ebp
f0104ad4:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0104ad6:	83 fa 01             	cmp    $0x1,%edx
f0104ad9:	7e 0e                	jle    f0104ae9 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0104adb:	8b 10                	mov    (%eax),%edx
f0104add:	8d 4a 08             	lea    0x8(%edx),%ecx
f0104ae0:	89 08                	mov    %ecx,(%eax)
f0104ae2:	8b 02                	mov    (%edx),%eax
f0104ae4:	8b 52 04             	mov    0x4(%edx),%edx
f0104ae7:	eb 22                	jmp    f0104b0b <getuint+0x38>
	else if (lflag)
f0104ae9:	85 d2                	test   %edx,%edx
f0104aeb:	74 10                	je     f0104afd <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0104aed:	8b 10                	mov    (%eax),%edx
f0104aef:	8d 4a 04             	lea    0x4(%edx),%ecx
f0104af2:	89 08                	mov    %ecx,(%eax)
f0104af4:	8b 02                	mov    (%edx),%eax
f0104af6:	ba 00 00 00 00       	mov    $0x0,%edx
f0104afb:	eb 0e                	jmp    f0104b0b <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0104afd:	8b 10                	mov    (%eax),%edx
f0104aff:	8d 4a 04             	lea    0x4(%edx),%ecx
f0104b02:	89 08                	mov    %ecx,(%eax)
f0104b04:	8b 02                	mov    (%edx),%eax
f0104b06:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0104b0b:	5d                   	pop    %ebp
f0104b0c:	c3                   	ret    

f0104b0d <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0104b0d:	55                   	push   %ebp
f0104b0e:	89 e5                	mov    %esp,%ebp
f0104b10:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0104b13:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0104b17:	8b 10                	mov    (%eax),%edx
f0104b19:	3b 50 04             	cmp    0x4(%eax),%edx
f0104b1c:	73 0a                	jae    f0104b28 <sprintputch+0x1b>
		*b->buf++ = ch;
f0104b1e:	8d 4a 01             	lea    0x1(%edx),%ecx
f0104b21:	89 08                	mov    %ecx,(%eax)
f0104b23:	8b 45 08             	mov    0x8(%ebp),%eax
f0104b26:	88 02                	mov    %al,(%edx)
}
f0104b28:	5d                   	pop    %ebp
f0104b29:	c3                   	ret    

f0104b2a <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0104b2a:	55                   	push   %ebp
f0104b2b:	89 e5                	mov    %esp,%ebp
f0104b2d:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0104b30:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0104b33:	50                   	push   %eax
f0104b34:	ff 75 10             	pushl  0x10(%ebp)
f0104b37:	ff 75 0c             	pushl  0xc(%ebp)
f0104b3a:	ff 75 08             	pushl  0x8(%ebp)
f0104b3d:	e8 05 00 00 00       	call   f0104b47 <vprintfmt>
	va_end(ap);
}
f0104b42:	83 c4 10             	add    $0x10,%esp
f0104b45:	c9                   	leave  
f0104b46:	c3                   	ret    

f0104b47 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0104b47:	55                   	push   %ebp
f0104b48:	89 e5                	mov    %esp,%ebp
f0104b4a:	57                   	push   %edi
f0104b4b:	56                   	push   %esi
f0104b4c:	53                   	push   %ebx
f0104b4d:	83 ec 2c             	sub    $0x2c,%esp
f0104b50:	8b 75 08             	mov    0x8(%ebp),%esi
f0104b53:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104b56:	8b 7d 10             	mov    0x10(%ebp),%edi
f0104b59:	eb 12                	jmp    f0104b6d <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0104b5b:	85 c0                	test   %eax,%eax
f0104b5d:	0f 84 89 03 00 00    	je     f0104eec <vprintfmt+0x3a5>
				return;
			putch(ch, putdat);
f0104b63:	83 ec 08             	sub    $0x8,%esp
f0104b66:	53                   	push   %ebx
f0104b67:	50                   	push   %eax
f0104b68:	ff d6                	call   *%esi
f0104b6a:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0104b6d:	83 c7 01             	add    $0x1,%edi
f0104b70:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0104b74:	83 f8 25             	cmp    $0x25,%eax
f0104b77:	75 e2                	jne    f0104b5b <vprintfmt+0x14>
f0104b79:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0104b7d:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0104b84:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0104b8b:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0104b92:	ba 00 00 00 00       	mov    $0x0,%edx
f0104b97:	eb 07                	jmp    f0104ba0 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104b99:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0104b9c:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104ba0:	8d 47 01             	lea    0x1(%edi),%eax
f0104ba3:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0104ba6:	0f b6 07             	movzbl (%edi),%eax
f0104ba9:	0f b6 c8             	movzbl %al,%ecx
f0104bac:	83 e8 23             	sub    $0x23,%eax
f0104baf:	3c 55                	cmp    $0x55,%al
f0104bb1:	0f 87 1a 03 00 00    	ja     f0104ed1 <vprintfmt+0x38a>
f0104bb7:	0f b6 c0             	movzbl %al,%eax
f0104bba:	ff 24 85 00 77 10 f0 	jmp    *-0xfef8900(,%eax,4)
f0104bc1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0104bc4:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0104bc8:	eb d6                	jmp    f0104ba0 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104bca:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104bcd:	b8 00 00 00 00       	mov    $0x0,%eax
f0104bd2:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0104bd5:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0104bd8:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f0104bdc:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0104bdf:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0104be2:	83 fa 09             	cmp    $0x9,%edx
f0104be5:	77 39                	ja     f0104c20 <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0104be7:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0104bea:	eb e9                	jmp    f0104bd5 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0104bec:	8b 45 14             	mov    0x14(%ebp),%eax
f0104bef:	8d 48 04             	lea    0x4(%eax),%ecx
f0104bf2:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0104bf5:	8b 00                	mov    (%eax),%eax
f0104bf7:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104bfa:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0104bfd:	eb 27                	jmp    f0104c26 <vprintfmt+0xdf>
f0104bff:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104c02:	85 c0                	test   %eax,%eax
f0104c04:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104c09:	0f 49 c8             	cmovns %eax,%ecx
f0104c0c:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104c0f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104c12:	eb 8c                	jmp    f0104ba0 <vprintfmt+0x59>
f0104c14:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0104c17:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0104c1e:	eb 80                	jmp    f0104ba0 <vprintfmt+0x59>
f0104c20:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0104c23:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0104c26:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0104c2a:	0f 89 70 ff ff ff    	jns    f0104ba0 <vprintfmt+0x59>
				width = precision, precision = -1;
f0104c30:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0104c33:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0104c36:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0104c3d:	e9 5e ff ff ff       	jmp    f0104ba0 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0104c42:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104c45:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0104c48:	e9 53 ff ff ff       	jmp    f0104ba0 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0104c4d:	8b 45 14             	mov    0x14(%ebp),%eax
f0104c50:	8d 50 04             	lea    0x4(%eax),%edx
f0104c53:	89 55 14             	mov    %edx,0x14(%ebp)
f0104c56:	83 ec 08             	sub    $0x8,%esp
f0104c59:	53                   	push   %ebx
f0104c5a:	ff 30                	pushl  (%eax)
f0104c5c:	ff d6                	call   *%esi
			break;
f0104c5e:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104c61:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0104c64:	e9 04 ff ff ff       	jmp    f0104b6d <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0104c69:	8b 45 14             	mov    0x14(%ebp),%eax
f0104c6c:	8d 50 04             	lea    0x4(%eax),%edx
f0104c6f:	89 55 14             	mov    %edx,0x14(%ebp)
f0104c72:	8b 00                	mov    (%eax),%eax
f0104c74:	99                   	cltd   
f0104c75:	31 d0                	xor    %edx,%eax
f0104c77:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0104c79:	83 f8 08             	cmp    $0x8,%eax
f0104c7c:	7f 0b                	jg     f0104c89 <vprintfmt+0x142>
f0104c7e:	8b 14 85 60 78 10 f0 	mov    -0xfef87a0(,%eax,4),%edx
f0104c85:	85 d2                	test   %edx,%edx
f0104c87:	75 18                	jne    f0104ca1 <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f0104c89:	50                   	push   %eax
f0104c8a:	68 49 76 10 f0       	push   $0xf0107649
f0104c8f:	53                   	push   %ebx
f0104c90:	56                   	push   %esi
f0104c91:	e8 94 fe ff ff       	call   f0104b2a <printfmt>
f0104c96:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104c99:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0104c9c:	e9 cc fe ff ff       	jmp    f0104b6d <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0104ca1:	52                   	push   %edx
f0104ca2:	68 9c 6d 10 f0       	push   $0xf0106d9c
f0104ca7:	53                   	push   %ebx
f0104ca8:	56                   	push   %esi
f0104ca9:	e8 7c fe ff ff       	call   f0104b2a <printfmt>
f0104cae:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104cb1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104cb4:	e9 b4 fe ff ff       	jmp    f0104b6d <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0104cb9:	8b 45 14             	mov    0x14(%ebp),%eax
f0104cbc:	8d 50 04             	lea    0x4(%eax),%edx
f0104cbf:	89 55 14             	mov    %edx,0x14(%ebp)
f0104cc2:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0104cc4:	85 ff                	test   %edi,%edi
f0104cc6:	b8 42 76 10 f0       	mov    $0xf0107642,%eax
f0104ccb:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0104cce:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0104cd2:	0f 8e 94 00 00 00    	jle    f0104d6c <vprintfmt+0x225>
f0104cd8:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0104cdc:	0f 84 98 00 00 00    	je     f0104d7a <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
f0104ce2:	83 ec 08             	sub    $0x8,%esp
f0104ce5:	ff 75 d0             	pushl  -0x30(%ebp)
f0104ce8:	57                   	push   %edi
f0104ce9:	e8 5f 03 00 00       	call   f010504d <strnlen>
f0104cee:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0104cf1:	29 c1                	sub    %eax,%ecx
f0104cf3:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0104cf6:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0104cf9:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0104cfd:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0104d00:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0104d03:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0104d05:	eb 0f                	jmp    f0104d16 <vprintfmt+0x1cf>
					putch(padc, putdat);
f0104d07:	83 ec 08             	sub    $0x8,%esp
f0104d0a:	53                   	push   %ebx
f0104d0b:	ff 75 e0             	pushl  -0x20(%ebp)
f0104d0e:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0104d10:	83 ef 01             	sub    $0x1,%edi
f0104d13:	83 c4 10             	add    $0x10,%esp
f0104d16:	85 ff                	test   %edi,%edi
f0104d18:	7f ed                	jg     f0104d07 <vprintfmt+0x1c0>
f0104d1a:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0104d1d:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0104d20:	85 c9                	test   %ecx,%ecx
f0104d22:	b8 00 00 00 00       	mov    $0x0,%eax
f0104d27:	0f 49 c1             	cmovns %ecx,%eax
f0104d2a:	29 c1                	sub    %eax,%ecx
f0104d2c:	89 75 08             	mov    %esi,0x8(%ebp)
f0104d2f:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0104d32:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0104d35:	89 cb                	mov    %ecx,%ebx
f0104d37:	eb 4d                	jmp    f0104d86 <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0104d39:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0104d3d:	74 1b                	je     f0104d5a <vprintfmt+0x213>
f0104d3f:	0f be c0             	movsbl %al,%eax
f0104d42:	83 e8 20             	sub    $0x20,%eax
f0104d45:	83 f8 5e             	cmp    $0x5e,%eax
f0104d48:	76 10                	jbe    f0104d5a <vprintfmt+0x213>
					putch('?', putdat);
f0104d4a:	83 ec 08             	sub    $0x8,%esp
f0104d4d:	ff 75 0c             	pushl  0xc(%ebp)
f0104d50:	6a 3f                	push   $0x3f
f0104d52:	ff 55 08             	call   *0x8(%ebp)
f0104d55:	83 c4 10             	add    $0x10,%esp
f0104d58:	eb 0d                	jmp    f0104d67 <vprintfmt+0x220>
				else
					putch(ch, putdat);
f0104d5a:	83 ec 08             	sub    $0x8,%esp
f0104d5d:	ff 75 0c             	pushl  0xc(%ebp)
f0104d60:	52                   	push   %edx
f0104d61:	ff 55 08             	call   *0x8(%ebp)
f0104d64:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0104d67:	83 eb 01             	sub    $0x1,%ebx
f0104d6a:	eb 1a                	jmp    f0104d86 <vprintfmt+0x23f>
f0104d6c:	89 75 08             	mov    %esi,0x8(%ebp)
f0104d6f:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0104d72:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0104d75:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0104d78:	eb 0c                	jmp    f0104d86 <vprintfmt+0x23f>
f0104d7a:	89 75 08             	mov    %esi,0x8(%ebp)
f0104d7d:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0104d80:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0104d83:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0104d86:	83 c7 01             	add    $0x1,%edi
f0104d89:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0104d8d:	0f be d0             	movsbl %al,%edx
f0104d90:	85 d2                	test   %edx,%edx
f0104d92:	74 23                	je     f0104db7 <vprintfmt+0x270>
f0104d94:	85 f6                	test   %esi,%esi
f0104d96:	78 a1                	js     f0104d39 <vprintfmt+0x1f2>
f0104d98:	83 ee 01             	sub    $0x1,%esi
f0104d9b:	79 9c                	jns    f0104d39 <vprintfmt+0x1f2>
f0104d9d:	89 df                	mov    %ebx,%edi
f0104d9f:	8b 75 08             	mov    0x8(%ebp),%esi
f0104da2:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104da5:	eb 18                	jmp    f0104dbf <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0104da7:	83 ec 08             	sub    $0x8,%esp
f0104daa:	53                   	push   %ebx
f0104dab:	6a 20                	push   $0x20
f0104dad:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0104daf:	83 ef 01             	sub    $0x1,%edi
f0104db2:	83 c4 10             	add    $0x10,%esp
f0104db5:	eb 08                	jmp    f0104dbf <vprintfmt+0x278>
f0104db7:	89 df                	mov    %ebx,%edi
f0104db9:	8b 75 08             	mov    0x8(%ebp),%esi
f0104dbc:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104dbf:	85 ff                	test   %edi,%edi
f0104dc1:	7f e4                	jg     f0104da7 <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104dc3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104dc6:	e9 a2 fd ff ff       	jmp    f0104b6d <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0104dcb:	83 fa 01             	cmp    $0x1,%edx
f0104dce:	7e 16                	jle    f0104de6 <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f0104dd0:	8b 45 14             	mov    0x14(%ebp),%eax
f0104dd3:	8d 50 08             	lea    0x8(%eax),%edx
f0104dd6:	89 55 14             	mov    %edx,0x14(%ebp)
f0104dd9:	8b 50 04             	mov    0x4(%eax),%edx
f0104ddc:	8b 00                	mov    (%eax),%eax
f0104dde:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104de1:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0104de4:	eb 32                	jmp    f0104e18 <vprintfmt+0x2d1>
	else if (lflag)
f0104de6:	85 d2                	test   %edx,%edx
f0104de8:	74 18                	je     f0104e02 <vprintfmt+0x2bb>
		return va_arg(*ap, long);
f0104dea:	8b 45 14             	mov    0x14(%ebp),%eax
f0104ded:	8d 50 04             	lea    0x4(%eax),%edx
f0104df0:	89 55 14             	mov    %edx,0x14(%ebp)
f0104df3:	8b 00                	mov    (%eax),%eax
f0104df5:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104df8:	89 c1                	mov    %eax,%ecx
f0104dfa:	c1 f9 1f             	sar    $0x1f,%ecx
f0104dfd:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0104e00:	eb 16                	jmp    f0104e18 <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
f0104e02:	8b 45 14             	mov    0x14(%ebp),%eax
f0104e05:	8d 50 04             	lea    0x4(%eax),%edx
f0104e08:	89 55 14             	mov    %edx,0x14(%ebp)
f0104e0b:	8b 00                	mov    (%eax),%eax
f0104e0d:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104e10:	89 c1                	mov    %eax,%ecx
f0104e12:	c1 f9 1f             	sar    $0x1f,%ecx
f0104e15:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0104e18:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0104e1b:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0104e1e:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0104e23:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0104e27:	79 74                	jns    f0104e9d <vprintfmt+0x356>
				putch('-', putdat);
f0104e29:	83 ec 08             	sub    $0x8,%esp
f0104e2c:	53                   	push   %ebx
f0104e2d:	6a 2d                	push   $0x2d
f0104e2f:	ff d6                	call   *%esi
				num = -(long long) num;
f0104e31:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0104e34:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0104e37:	f7 d8                	neg    %eax
f0104e39:	83 d2 00             	adc    $0x0,%edx
f0104e3c:	f7 da                	neg    %edx
f0104e3e:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0104e41:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0104e46:	eb 55                	jmp    f0104e9d <vprintfmt+0x356>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0104e48:	8d 45 14             	lea    0x14(%ebp),%eax
f0104e4b:	e8 83 fc ff ff       	call   f0104ad3 <getuint>
			base = 10;
f0104e50:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0104e55:	eb 46                	jmp    f0104e9d <vprintfmt+0x356>
		// (unsigned) octal
		case 'o':
			//putch('X', putdat);
			//putch('X', putdat);
			//putch('X', putdat);
			num = getuint(&ap, lflag);
f0104e57:	8d 45 14             	lea    0x14(%ebp),%eax
f0104e5a:	e8 74 fc ff ff       	call   f0104ad3 <getuint>
			base = 8;
f0104e5f:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0104e64:	eb 37                	jmp    f0104e9d <vprintfmt+0x356>

		// pointer
		case 'p':
			putch('0', putdat);
f0104e66:	83 ec 08             	sub    $0x8,%esp
f0104e69:	53                   	push   %ebx
f0104e6a:	6a 30                	push   $0x30
f0104e6c:	ff d6                	call   *%esi
			putch('x', putdat);
f0104e6e:	83 c4 08             	add    $0x8,%esp
f0104e71:	53                   	push   %ebx
f0104e72:	6a 78                	push   $0x78
f0104e74:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0104e76:	8b 45 14             	mov    0x14(%ebp),%eax
f0104e79:	8d 50 04             	lea    0x4(%eax),%edx
f0104e7c:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0104e7f:	8b 00                	mov    (%eax),%eax
f0104e81:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0104e86:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0104e89:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0104e8e:	eb 0d                	jmp    f0104e9d <vprintfmt+0x356>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0104e90:	8d 45 14             	lea    0x14(%ebp),%eax
f0104e93:	e8 3b fc ff ff       	call   f0104ad3 <getuint>
			base = 16;
f0104e98:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0104e9d:	83 ec 0c             	sub    $0xc,%esp
f0104ea0:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0104ea4:	57                   	push   %edi
f0104ea5:	ff 75 e0             	pushl  -0x20(%ebp)
f0104ea8:	51                   	push   %ecx
f0104ea9:	52                   	push   %edx
f0104eaa:	50                   	push   %eax
f0104eab:	89 da                	mov    %ebx,%edx
f0104ead:	89 f0                	mov    %esi,%eax
f0104eaf:	e8 70 fb ff ff       	call   f0104a24 <printnum>
			break;
f0104eb4:	83 c4 20             	add    $0x20,%esp
f0104eb7:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104eba:	e9 ae fc ff ff       	jmp    f0104b6d <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0104ebf:	83 ec 08             	sub    $0x8,%esp
f0104ec2:	53                   	push   %ebx
f0104ec3:	51                   	push   %ecx
f0104ec4:	ff d6                	call   *%esi
			break;
f0104ec6:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104ec9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0104ecc:	e9 9c fc ff ff       	jmp    f0104b6d <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0104ed1:	83 ec 08             	sub    $0x8,%esp
f0104ed4:	53                   	push   %ebx
f0104ed5:	6a 25                	push   $0x25
f0104ed7:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0104ed9:	83 c4 10             	add    $0x10,%esp
f0104edc:	eb 03                	jmp    f0104ee1 <vprintfmt+0x39a>
f0104ede:	83 ef 01             	sub    $0x1,%edi
f0104ee1:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0104ee5:	75 f7                	jne    f0104ede <vprintfmt+0x397>
f0104ee7:	e9 81 fc ff ff       	jmp    f0104b6d <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0104eec:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104eef:	5b                   	pop    %ebx
f0104ef0:	5e                   	pop    %esi
f0104ef1:	5f                   	pop    %edi
f0104ef2:	5d                   	pop    %ebp
f0104ef3:	c3                   	ret    

f0104ef4 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0104ef4:	55                   	push   %ebp
f0104ef5:	89 e5                	mov    %esp,%ebp
f0104ef7:	83 ec 18             	sub    $0x18,%esp
f0104efa:	8b 45 08             	mov    0x8(%ebp),%eax
f0104efd:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0104f00:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0104f03:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0104f07:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0104f0a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0104f11:	85 c0                	test   %eax,%eax
f0104f13:	74 26                	je     f0104f3b <vsnprintf+0x47>
f0104f15:	85 d2                	test   %edx,%edx
f0104f17:	7e 22                	jle    f0104f3b <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0104f19:	ff 75 14             	pushl  0x14(%ebp)
f0104f1c:	ff 75 10             	pushl  0x10(%ebp)
f0104f1f:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0104f22:	50                   	push   %eax
f0104f23:	68 0d 4b 10 f0       	push   $0xf0104b0d
f0104f28:	e8 1a fc ff ff       	call   f0104b47 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0104f2d:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0104f30:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0104f33:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104f36:	83 c4 10             	add    $0x10,%esp
f0104f39:	eb 05                	jmp    f0104f40 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0104f3b:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0104f40:	c9                   	leave  
f0104f41:	c3                   	ret    

f0104f42 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0104f42:	55                   	push   %ebp
f0104f43:	89 e5                	mov    %esp,%ebp
f0104f45:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0104f48:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0104f4b:	50                   	push   %eax
f0104f4c:	ff 75 10             	pushl  0x10(%ebp)
f0104f4f:	ff 75 0c             	pushl  0xc(%ebp)
f0104f52:	ff 75 08             	pushl  0x8(%ebp)
f0104f55:	e8 9a ff ff ff       	call   f0104ef4 <vsnprintf>
	va_end(ap);

	return rc;
}
f0104f5a:	c9                   	leave  
f0104f5b:	c3                   	ret    

f0104f5c <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0104f5c:	55                   	push   %ebp
f0104f5d:	89 e5                	mov    %esp,%ebp
f0104f5f:	57                   	push   %edi
f0104f60:	56                   	push   %esi
f0104f61:	53                   	push   %ebx
f0104f62:	83 ec 0c             	sub    $0xc,%esp
f0104f65:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0104f68:	85 c0                	test   %eax,%eax
f0104f6a:	74 11                	je     f0104f7d <readline+0x21>
		cprintf("%s", prompt);
f0104f6c:	83 ec 08             	sub    $0x8,%esp
f0104f6f:	50                   	push   %eax
f0104f70:	68 9c 6d 10 f0       	push   $0xf0106d9c
f0104f75:	e8 dd e6 ff ff       	call   f0103657 <cprintf>
f0104f7a:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0104f7d:	83 ec 0c             	sub    $0xc,%esp
f0104f80:	6a 00                	push   $0x0
f0104f82:	e8 fe b7 ff ff       	call   f0100785 <iscons>
f0104f87:	89 c7                	mov    %eax,%edi
f0104f89:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0104f8c:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0104f91:	e8 de b7 ff ff       	call   f0100774 <getchar>
f0104f96:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0104f98:	85 c0                	test   %eax,%eax
f0104f9a:	79 18                	jns    f0104fb4 <readline+0x58>
			cprintf("read error: %e\n", c);
f0104f9c:	83 ec 08             	sub    $0x8,%esp
f0104f9f:	50                   	push   %eax
f0104fa0:	68 84 78 10 f0       	push   $0xf0107884
f0104fa5:	e8 ad e6 ff ff       	call   f0103657 <cprintf>
			return NULL;
f0104faa:	83 c4 10             	add    $0x10,%esp
f0104fad:	b8 00 00 00 00       	mov    $0x0,%eax
f0104fb2:	eb 79                	jmp    f010502d <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0104fb4:	83 f8 08             	cmp    $0x8,%eax
f0104fb7:	0f 94 c2             	sete   %dl
f0104fba:	83 f8 7f             	cmp    $0x7f,%eax
f0104fbd:	0f 94 c0             	sete   %al
f0104fc0:	08 c2                	or     %al,%dl
f0104fc2:	74 1a                	je     f0104fde <readline+0x82>
f0104fc4:	85 f6                	test   %esi,%esi
f0104fc6:	7e 16                	jle    f0104fde <readline+0x82>
			if (echoing)
f0104fc8:	85 ff                	test   %edi,%edi
f0104fca:	74 0d                	je     f0104fd9 <readline+0x7d>
				cputchar('\b');
f0104fcc:	83 ec 0c             	sub    $0xc,%esp
f0104fcf:	6a 08                	push   $0x8
f0104fd1:	e8 8e b7 ff ff       	call   f0100764 <cputchar>
f0104fd6:	83 c4 10             	add    $0x10,%esp
			i--;
f0104fd9:	83 ee 01             	sub    $0x1,%esi
f0104fdc:	eb b3                	jmp    f0104f91 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0104fde:	83 fb 1f             	cmp    $0x1f,%ebx
f0104fe1:	7e 23                	jle    f0105006 <readline+0xaa>
f0104fe3:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0104fe9:	7f 1b                	jg     f0105006 <readline+0xaa>
			if (echoing)
f0104feb:	85 ff                	test   %edi,%edi
f0104fed:	74 0c                	je     f0104ffb <readline+0x9f>
				cputchar(c);
f0104fef:	83 ec 0c             	sub    $0xc,%esp
f0104ff2:	53                   	push   %ebx
f0104ff3:	e8 6c b7 ff ff       	call   f0100764 <cputchar>
f0104ff8:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0104ffb:	88 9e 80 aa 22 f0    	mov    %bl,-0xfdd5580(%esi)
f0105001:	8d 76 01             	lea    0x1(%esi),%esi
f0105004:	eb 8b                	jmp    f0104f91 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0105006:	83 fb 0a             	cmp    $0xa,%ebx
f0105009:	74 05                	je     f0105010 <readline+0xb4>
f010500b:	83 fb 0d             	cmp    $0xd,%ebx
f010500e:	75 81                	jne    f0104f91 <readline+0x35>
			if (echoing)
f0105010:	85 ff                	test   %edi,%edi
f0105012:	74 0d                	je     f0105021 <readline+0xc5>
				cputchar('\n');
f0105014:	83 ec 0c             	sub    $0xc,%esp
f0105017:	6a 0a                	push   $0xa
f0105019:	e8 46 b7 ff ff       	call   f0100764 <cputchar>
f010501e:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0105021:	c6 86 80 aa 22 f0 00 	movb   $0x0,-0xfdd5580(%esi)
			return buf;
f0105028:	b8 80 aa 22 f0       	mov    $0xf022aa80,%eax
		}
	}
}
f010502d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0105030:	5b                   	pop    %ebx
f0105031:	5e                   	pop    %esi
f0105032:	5f                   	pop    %edi
f0105033:	5d                   	pop    %ebp
f0105034:	c3                   	ret    

f0105035 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0105035:	55                   	push   %ebp
f0105036:	89 e5                	mov    %esp,%ebp
f0105038:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f010503b:	b8 00 00 00 00       	mov    $0x0,%eax
f0105040:	eb 03                	jmp    f0105045 <strlen+0x10>
		n++;
f0105042:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0105045:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0105049:	75 f7                	jne    f0105042 <strlen+0xd>
		n++;
	return n;
}
f010504b:	5d                   	pop    %ebp
f010504c:	c3                   	ret    

f010504d <strnlen>:

int
strnlen(const char *s, size_t size)
{
f010504d:	55                   	push   %ebp
f010504e:	89 e5                	mov    %esp,%ebp
f0105050:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0105053:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0105056:	ba 00 00 00 00       	mov    $0x0,%edx
f010505b:	eb 03                	jmp    f0105060 <strnlen+0x13>
		n++;
f010505d:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0105060:	39 c2                	cmp    %eax,%edx
f0105062:	74 08                	je     f010506c <strnlen+0x1f>
f0105064:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f0105068:	75 f3                	jne    f010505d <strnlen+0x10>
f010506a:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f010506c:	5d                   	pop    %ebp
f010506d:	c3                   	ret    

f010506e <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f010506e:	55                   	push   %ebp
f010506f:	89 e5                	mov    %esp,%ebp
f0105071:	53                   	push   %ebx
f0105072:	8b 45 08             	mov    0x8(%ebp),%eax
f0105075:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0105078:	89 c2                	mov    %eax,%edx
f010507a:	83 c2 01             	add    $0x1,%edx
f010507d:	83 c1 01             	add    $0x1,%ecx
f0105080:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0105084:	88 5a ff             	mov    %bl,-0x1(%edx)
f0105087:	84 db                	test   %bl,%bl
f0105089:	75 ef                	jne    f010507a <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f010508b:	5b                   	pop    %ebx
f010508c:	5d                   	pop    %ebp
f010508d:	c3                   	ret    

f010508e <strcat>:

char *
strcat(char *dst, const char *src)
{
f010508e:	55                   	push   %ebp
f010508f:	89 e5                	mov    %esp,%ebp
f0105091:	53                   	push   %ebx
f0105092:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0105095:	53                   	push   %ebx
f0105096:	e8 9a ff ff ff       	call   f0105035 <strlen>
f010509b:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f010509e:	ff 75 0c             	pushl  0xc(%ebp)
f01050a1:	01 d8                	add    %ebx,%eax
f01050a3:	50                   	push   %eax
f01050a4:	e8 c5 ff ff ff       	call   f010506e <strcpy>
	return dst;
}
f01050a9:	89 d8                	mov    %ebx,%eax
f01050ab:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01050ae:	c9                   	leave  
f01050af:	c3                   	ret    

f01050b0 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01050b0:	55                   	push   %ebp
f01050b1:	89 e5                	mov    %esp,%ebp
f01050b3:	56                   	push   %esi
f01050b4:	53                   	push   %ebx
f01050b5:	8b 75 08             	mov    0x8(%ebp),%esi
f01050b8:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01050bb:	89 f3                	mov    %esi,%ebx
f01050bd:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01050c0:	89 f2                	mov    %esi,%edx
f01050c2:	eb 0f                	jmp    f01050d3 <strncpy+0x23>
		*dst++ = *src;
f01050c4:	83 c2 01             	add    $0x1,%edx
f01050c7:	0f b6 01             	movzbl (%ecx),%eax
f01050ca:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01050cd:	80 39 01             	cmpb   $0x1,(%ecx)
f01050d0:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01050d3:	39 da                	cmp    %ebx,%edx
f01050d5:	75 ed                	jne    f01050c4 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01050d7:	89 f0                	mov    %esi,%eax
f01050d9:	5b                   	pop    %ebx
f01050da:	5e                   	pop    %esi
f01050db:	5d                   	pop    %ebp
f01050dc:	c3                   	ret    

f01050dd <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01050dd:	55                   	push   %ebp
f01050de:	89 e5                	mov    %esp,%ebp
f01050e0:	56                   	push   %esi
f01050e1:	53                   	push   %ebx
f01050e2:	8b 75 08             	mov    0x8(%ebp),%esi
f01050e5:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01050e8:	8b 55 10             	mov    0x10(%ebp),%edx
f01050eb:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01050ed:	85 d2                	test   %edx,%edx
f01050ef:	74 21                	je     f0105112 <strlcpy+0x35>
f01050f1:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f01050f5:	89 f2                	mov    %esi,%edx
f01050f7:	eb 09                	jmp    f0105102 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01050f9:	83 c2 01             	add    $0x1,%edx
f01050fc:	83 c1 01             	add    $0x1,%ecx
f01050ff:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0105102:	39 c2                	cmp    %eax,%edx
f0105104:	74 09                	je     f010510f <strlcpy+0x32>
f0105106:	0f b6 19             	movzbl (%ecx),%ebx
f0105109:	84 db                	test   %bl,%bl
f010510b:	75 ec                	jne    f01050f9 <strlcpy+0x1c>
f010510d:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f010510f:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0105112:	29 f0                	sub    %esi,%eax
}
f0105114:	5b                   	pop    %ebx
f0105115:	5e                   	pop    %esi
f0105116:	5d                   	pop    %ebp
f0105117:	c3                   	ret    

f0105118 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0105118:	55                   	push   %ebp
f0105119:	89 e5                	mov    %esp,%ebp
f010511b:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010511e:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0105121:	eb 06                	jmp    f0105129 <strcmp+0x11>
		p++, q++;
f0105123:	83 c1 01             	add    $0x1,%ecx
f0105126:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0105129:	0f b6 01             	movzbl (%ecx),%eax
f010512c:	84 c0                	test   %al,%al
f010512e:	74 04                	je     f0105134 <strcmp+0x1c>
f0105130:	3a 02                	cmp    (%edx),%al
f0105132:	74 ef                	je     f0105123 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0105134:	0f b6 c0             	movzbl %al,%eax
f0105137:	0f b6 12             	movzbl (%edx),%edx
f010513a:	29 d0                	sub    %edx,%eax
}
f010513c:	5d                   	pop    %ebp
f010513d:	c3                   	ret    

f010513e <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f010513e:	55                   	push   %ebp
f010513f:	89 e5                	mov    %esp,%ebp
f0105141:	53                   	push   %ebx
f0105142:	8b 45 08             	mov    0x8(%ebp),%eax
f0105145:	8b 55 0c             	mov    0xc(%ebp),%edx
f0105148:	89 c3                	mov    %eax,%ebx
f010514a:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f010514d:	eb 06                	jmp    f0105155 <strncmp+0x17>
		n--, p++, q++;
f010514f:	83 c0 01             	add    $0x1,%eax
f0105152:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0105155:	39 d8                	cmp    %ebx,%eax
f0105157:	74 15                	je     f010516e <strncmp+0x30>
f0105159:	0f b6 08             	movzbl (%eax),%ecx
f010515c:	84 c9                	test   %cl,%cl
f010515e:	74 04                	je     f0105164 <strncmp+0x26>
f0105160:	3a 0a                	cmp    (%edx),%cl
f0105162:	74 eb                	je     f010514f <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0105164:	0f b6 00             	movzbl (%eax),%eax
f0105167:	0f b6 12             	movzbl (%edx),%edx
f010516a:	29 d0                	sub    %edx,%eax
f010516c:	eb 05                	jmp    f0105173 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f010516e:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0105173:	5b                   	pop    %ebx
f0105174:	5d                   	pop    %ebp
f0105175:	c3                   	ret    

f0105176 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0105176:	55                   	push   %ebp
f0105177:	89 e5                	mov    %esp,%ebp
f0105179:	8b 45 08             	mov    0x8(%ebp),%eax
f010517c:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0105180:	eb 07                	jmp    f0105189 <strchr+0x13>
		if (*s == c)
f0105182:	38 ca                	cmp    %cl,%dl
f0105184:	74 0f                	je     f0105195 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0105186:	83 c0 01             	add    $0x1,%eax
f0105189:	0f b6 10             	movzbl (%eax),%edx
f010518c:	84 d2                	test   %dl,%dl
f010518e:	75 f2                	jne    f0105182 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0105190:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0105195:	5d                   	pop    %ebp
f0105196:	c3                   	ret    

f0105197 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0105197:	55                   	push   %ebp
f0105198:	89 e5                	mov    %esp,%ebp
f010519a:	8b 45 08             	mov    0x8(%ebp),%eax
f010519d:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01051a1:	eb 03                	jmp    f01051a6 <strfind+0xf>
f01051a3:	83 c0 01             	add    $0x1,%eax
f01051a6:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f01051a9:	38 ca                	cmp    %cl,%dl
f01051ab:	74 04                	je     f01051b1 <strfind+0x1a>
f01051ad:	84 d2                	test   %dl,%dl
f01051af:	75 f2                	jne    f01051a3 <strfind+0xc>
			break;
	return (char *) s;
}
f01051b1:	5d                   	pop    %ebp
f01051b2:	c3                   	ret    

f01051b3 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01051b3:	55                   	push   %ebp
f01051b4:	89 e5                	mov    %esp,%ebp
f01051b6:	57                   	push   %edi
f01051b7:	56                   	push   %esi
f01051b8:	53                   	push   %ebx
f01051b9:	8b 7d 08             	mov    0x8(%ebp),%edi
f01051bc:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01051bf:	85 c9                	test   %ecx,%ecx
f01051c1:	74 36                	je     f01051f9 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01051c3:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01051c9:	75 28                	jne    f01051f3 <memset+0x40>
f01051cb:	f6 c1 03             	test   $0x3,%cl
f01051ce:	75 23                	jne    f01051f3 <memset+0x40>
		c &= 0xFF;
f01051d0:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01051d4:	89 d3                	mov    %edx,%ebx
f01051d6:	c1 e3 08             	shl    $0x8,%ebx
f01051d9:	89 d6                	mov    %edx,%esi
f01051db:	c1 e6 18             	shl    $0x18,%esi
f01051de:	89 d0                	mov    %edx,%eax
f01051e0:	c1 e0 10             	shl    $0x10,%eax
f01051e3:	09 f0                	or     %esi,%eax
f01051e5:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f01051e7:	89 d8                	mov    %ebx,%eax
f01051e9:	09 d0                	or     %edx,%eax
f01051eb:	c1 e9 02             	shr    $0x2,%ecx
f01051ee:	fc                   	cld    
f01051ef:	f3 ab                	rep stos %eax,%es:(%edi)
f01051f1:	eb 06                	jmp    f01051f9 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01051f3:	8b 45 0c             	mov    0xc(%ebp),%eax
f01051f6:	fc                   	cld    
f01051f7:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01051f9:	89 f8                	mov    %edi,%eax
f01051fb:	5b                   	pop    %ebx
f01051fc:	5e                   	pop    %esi
f01051fd:	5f                   	pop    %edi
f01051fe:	5d                   	pop    %ebp
f01051ff:	c3                   	ret    

f0105200 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0105200:	55                   	push   %ebp
f0105201:	89 e5                	mov    %esp,%ebp
f0105203:	57                   	push   %edi
f0105204:	56                   	push   %esi
f0105205:	8b 45 08             	mov    0x8(%ebp),%eax
f0105208:	8b 75 0c             	mov    0xc(%ebp),%esi
f010520b:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f010520e:	39 c6                	cmp    %eax,%esi
f0105210:	73 35                	jae    f0105247 <memmove+0x47>
f0105212:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0105215:	39 d0                	cmp    %edx,%eax
f0105217:	73 2e                	jae    f0105247 <memmove+0x47>
		s += n;
		d += n;
f0105219:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010521c:	89 d6                	mov    %edx,%esi
f010521e:	09 fe                	or     %edi,%esi
f0105220:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0105226:	75 13                	jne    f010523b <memmove+0x3b>
f0105228:	f6 c1 03             	test   $0x3,%cl
f010522b:	75 0e                	jne    f010523b <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f010522d:	83 ef 04             	sub    $0x4,%edi
f0105230:	8d 72 fc             	lea    -0x4(%edx),%esi
f0105233:	c1 e9 02             	shr    $0x2,%ecx
f0105236:	fd                   	std    
f0105237:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0105239:	eb 09                	jmp    f0105244 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f010523b:	83 ef 01             	sub    $0x1,%edi
f010523e:	8d 72 ff             	lea    -0x1(%edx),%esi
f0105241:	fd                   	std    
f0105242:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0105244:	fc                   	cld    
f0105245:	eb 1d                	jmp    f0105264 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0105247:	89 f2                	mov    %esi,%edx
f0105249:	09 c2                	or     %eax,%edx
f010524b:	f6 c2 03             	test   $0x3,%dl
f010524e:	75 0f                	jne    f010525f <memmove+0x5f>
f0105250:	f6 c1 03             	test   $0x3,%cl
f0105253:	75 0a                	jne    f010525f <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f0105255:	c1 e9 02             	shr    $0x2,%ecx
f0105258:	89 c7                	mov    %eax,%edi
f010525a:	fc                   	cld    
f010525b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010525d:	eb 05                	jmp    f0105264 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f010525f:	89 c7                	mov    %eax,%edi
f0105261:	fc                   	cld    
f0105262:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0105264:	5e                   	pop    %esi
f0105265:	5f                   	pop    %edi
f0105266:	5d                   	pop    %ebp
f0105267:	c3                   	ret    

f0105268 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0105268:	55                   	push   %ebp
f0105269:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f010526b:	ff 75 10             	pushl  0x10(%ebp)
f010526e:	ff 75 0c             	pushl  0xc(%ebp)
f0105271:	ff 75 08             	pushl  0x8(%ebp)
f0105274:	e8 87 ff ff ff       	call   f0105200 <memmove>
}
f0105279:	c9                   	leave  
f010527a:	c3                   	ret    

f010527b <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f010527b:	55                   	push   %ebp
f010527c:	89 e5                	mov    %esp,%ebp
f010527e:	56                   	push   %esi
f010527f:	53                   	push   %ebx
f0105280:	8b 45 08             	mov    0x8(%ebp),%eax
f0105283:	8b 55 0c             	mov    0xc(%ebp),%edx
f0105286:	89 c6                	mov    %eax,%esi
f0105288:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010528b:	eb 1a                	jmp    f01052a7 <memcmp+0x2c>
		if (*s1 != *s2)
f010528d:	0f b6 08             	movzbl (%eax),%ecx
f0105290:	0f b6 1a             	movzbl (%edx),%ebx
f0105293:	38 d9                	cmp    %bl,%cl
f0105295:	74 0a                	je     f01052a1 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0105297:	0f b6 c1             	movzbl %cl,%eax
f010529a:	0f b6 db             	movzbl %bl,%ebx
f010529d:	29 d8                	sub    %ebx,%eax
f010529f:	eb 0f                	jmp    f01052b0 <memcmp+0x35>
		s1++, s2++;
f01052a1:	83 c0 01             	add    $0x1,%eax
f01052a4:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01052a7:	39 f0                	cmp    %esi,%eax
f01052a9:	75 e2                	jne    f010528d <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01052ab:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01052b0:	5b                   	pop    %ebx
f01052b1:	5e                   	pop    %esi
f01052b2:	5d                   	pop    %ebp
f01052b3:	c3                   	ret    

f01052b4 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01052b4:	55                   	push   %ebp
f01052b5:	89 e5                	mov    %esp,%ebp
f01052b7:	53                   	push   %ebx
f01052b8:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f01052bb:	89 c1                	mov    %eax,%ecx
f01052bd:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f01052c0:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01052c4:	eb 0a                	jmp    f01052d0 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f01052c6:	0f b6 10             	movzbl (%eax),%edx
f01052c9:	39 da                	cmp    %ebx,%edx
f01052cb:	74 07                	je     f01052d4 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01052cd:	83 c0 01             	add    $0x1,%eax
f01052d0:	39 c8                	cmp    %ecx,%eax
f01052d2:	72 f2                	jb     f01052c6 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01052d4:	5b                   	pop    %ebx
f01052d5:	5d                   	pop    %ebp
f01052d6:	c3                   	ret    

f01052d7 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01052d7:	55                   	push   %ebp
f01052d8:	89 e5                	mov    %esp,%ebp
f01052da:	57                   	push   %edi
f01052db:	56                   	push   %esi
f01052dc:	53                   	push   %ebx
f01052dd:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01052e0:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01052e3:	eb 03                	jmp    f01052e8 <strtol+0x11>
		s++;
f01052e5:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01052e8:	0f b6 01             	movzbl (%ecx),%eax
f01052eb:	3c 20                	cmp    $0x20,%al
f01052ed:	74 f6                	je     f01052e5 <strtol+0xe>
f01052ef:	3c 09                	cmp    $0x9,%al
f01052f1:	74 f2                	je     f01052e5 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f01052f3:	3c 2b                	cmp    $0x2b,%al
f01052f5:	75 0a                	jne    f0105301 <strtol+0x2a>
		s++;
f01052f7:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01052fa:	bf 00 00 00 00       	mov    $0x0,%edi
f01052ff:	eb 11                	jmp    f0105312 <strtol+0x3b>
f0105301:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0105306:	3c 2d                	cmp    $0x2d,%al
f0105308:	75 08                	jne    f0105312 <strtol+0x3b>
		s++, neg = 1;
f010530a:	83 c1 01             	add    $0x1,%ecx
f010530d:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0105312:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0105318:	75 15                	jne    f010532f <strtol+0x58>
f010531a:	80 39 30             	cmpb   $0x30,(%ecx)
f010531d:	75 10                	jne    f010532f <strtol+0x58>
f010531f:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0105323:	75 7c                	jne    f01053a1 <strtol+0xca>
		s += 2, base = 16;
f0105325:	83 c1 02             	add    $0x2,%ecx
f0105328:	bb 10 00 00 00       	mov    $0x10,%ebx
f010532d:	eb 16                	jmp    f0105345 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f010532f:	85 db                	test   %ebx,%ebx
f0105331:	75 12                	jne    f0105345 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0105333:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0105338:	80 39 30             	cmpb   $0x30,(%ecx)
f010533b:	75 08                	jne    f0105345 <strtol+0x6e>
		s++, base = 8;
f010533d:	83 c1 01             	add    $0x1,%ecx
f0105340:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f0105345:	b8 00 00 00 00       	mov    $0x0,%eax
f010534a:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f010534d:	0f b6 11             	movzbl (%ecx),%edx
f0105350:	8d 72 d0             	lea    -0x30(%edx),%esi
f0105353:	89 f3                	mov    %esi,%ebx
f0105355:	80 fb 09             	cmp    $0x9,%bl
f0105358:	77 08                	ja     f0105362 <strtol+0x8b>
			dig = *s - '0';
f010535a:	0f be d2             	movsbl %dl,%edx
f010535d:	83 ea 30             	sub    $0x30,%edx
f0105360:	eb 22                	jmp    f0105384 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f0105362:	8d 72 9f             	lea    -0x61(%edx),%esi
f0105365:	89 f3                	mov    %esi,%ebx
f0105367:	80 fb 19             	cmp    $0x19,%bl
f010536a:	77 08                	ja     f0105374 <strtol+0x9d>
			dig = *s - 'a' + 10;
f010536c:	0f be d2             	movsbl %dl,%edx
f010536f:	83 ea 57             	sub    $0x57,%edx
f0105372:	eb 10                	jmp    f0105384 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f0105374:	8d 72 bf             	lea    -0x41(%edx),%esi
f0105377:	89 f3                	mov    %esi,%ebx
f0105379:	80 fb 19             	cmp    $0x19,%bl
f010537c:	77 16                	ja     f0105394 <strtol+0xbd>
			dig = *s - 'A' + 10;
f010537e:	0f be d2             	movsbl %dl,%edx
f0105381:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f0105384:	3b 55 10             	cmp    0x10(%ebp),%edx
f0105387:	7d 0b                	jge    f0105394 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f0105389:	83 c1 01             	add    $0x1,%ecx
f010538c:	0f af 45 10          	imul   0x10(%ebp),%eax
f0105390:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f0105392:	eb b9                	jmp    f010534d <strtol+0x76>

	if (endptr)
f0105394:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0105398:	74 0d                	je     f01053a7 <strtol+0xd0>
		*endptr = (char *) s;
f010539a:	8b 75 0c             	mov    0xc(%ebp),%esi
f010539d:	89 0e                	mov    %ecx,(%esi)
f010539f:	eb 06                	jmp    f01053a7 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01053a1:	85 db                	test   %ebx,%ebx
f01053a3:	74 98                	je     f010533d <strtol+0x66>
f01053a5:	eb 9e                	jmp    f0105345 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f01053a7:	89 c2                	mov    %eax,%edx
f01053a9:	f7 da                	neg    %edx
f01053ab:	85 ff                	test   %edi,%edi
f01053ad:	0f 45 c2             	cmovne %edx,%eax
}
f01053b0:	5b                   	pop    %ebx
f01053b1:	5e                   	pop    %esi
f01053b2:	5f                   	pop    %edi
f01053b3:	5d                   	pop    %ebp
f01053b4:	c3                   	ret    
f01053b5:	66 90                	xchg   %ax,%ax
f01053b7:	90                   	nop

f01053b8 <mpentry_start>:
.set PROT_MODE_DSEG, 0x10	# kernel data segment selector

.code16           
.globl mpentry_start
mpentry_start:
	cli            
f01053b8:	fa                   	cli    

	xorw    %ax, %ax
f01053b9:	31 c0                	xor    %eax,%eax
	movw    %ax, %ds
f01053bb:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f01053bd:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f01053bf:	8e d0                	mov    %eax,%ss

	lgdt    MPBOOTPHYS(gdtdesc)
f01053c1:	0f 01 16             	lgdtl  (%esi)
f01053c4:	74 70                	je     f0105436 <mpsearch1+0x3>
	movl    %cr0, %eax
f01053c6:	0f 20 c0             	mov    %cr0,%eax
	orl     $CR0_PE, %eax
f01053c9:	66 83 c8 01          	or     $0x1,%ax
	movl    %eax, %cr0
f01053cd:	0f 22 c0             	mov    %eax,%cr0

	ljmpl   $(PROT_MODE_CSEG), $(MPBOOTPHYS(start32))
f01053d0:	66 ea 20 70 00 00    	ljmpw  $0x0,$0x7020
f01053d6:	08 00                	or     %al,(%eax)

f01053d8 <start32>:

.code32
start32:
	movw    $(PROT_MODE_DSEG), %ax
f01053d8:	66 b8 10 00          	mov    $0x10,%ax
	movw    %ax, %ds
f01053dc:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f01053de:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f01053e0:	8e d0                	mov    %eax,%ss
	movw    $0, %ax
f01053e2:	66 b8 00 00          	mov    $0x0,%ax
	movw    %ax, %fs
f01053e6:	8e e0                	mov    %eax,%fs
	movw    %ax, %gs
f01053e8:	8e e8                	mov    %eax,%gs

	# Set up initial page table. We cannot use kern_pgdir yet because
	# we are still running at a low EIP.
	movl    $(RELOC(entry_pgdir)), %eax
f01053ea:	b8 00 d0 11 00       	mov    $0x11d000,%eax
	movl    %eax, %cr3
f01053ef:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl    %cr0, %eax
f01053f2:	0f 20 c0             	mov    %cr0,%eax
	orl     $(CR0_PE|CR0_PG|CR0_WP), %eax
f01053f5:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl    %eax, %cr0
f01053fa:	0f 22 c0             	mov    %eax,%cr0

	# Switch to the per-cpu stack allocated in boot_aps()
	movl    mpentry_kstack, %esp
f01053fd:	8b 25 84 ae 22 f0    	mov    0xf022ae84,%esp
	movl    $0x0, %ebp       # nuke frame pointer
f0105403:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Call mp_main().  (Exercise for the reader: why the indirect call?)
	movl    $mp_main, %eax
f0105408:	b8 b3 01 10 f0       	mov    $0xf01001b3,%eax
	call    *%eax
f010540d:	ff d0                	call   *%eax

f010540f <spin>:

	# If mp_main returns (it shouldn't), loop.
spin:
	jmp     spin
f010540f:	eb fe                	jmp    f010540f <spin>
f0105411:	8d 76 00             	lea    0x0(%esi),%esi

f0105414 <gdt>:
	...
f010541c:	ff                   	(bad)  
f010541d:	ff 00                	incl   (%eax)
f010541f:	00 00                	add    %al,(%eax)
f0105421:	9a cf 00 ff ff 00 00 	lcall  $0x0,$0xffff00cf
f0105428:	00                   	.byte 0x0
f0105429:	92                   	xchg   %eax,%edx
f010542a:	cf                   	iret   
	...

f010542c <gdtdesc>:
f010542c:	17                   	pop    %ss
f010542d:	00 5c 70 00          	add    %bl,0x0(%eax,%esi,2)
	...

f0105432 <mpentry_end>:
	.word   0x17				# sizeof(gdt) - 1
	.long   MPBOOTPHYS(gdt)			# address gdt

.globl mpentry_end
mpentry_end:
	nop
f0105432:	90                   	nop

f0105433 <mpsearch1>:
}

// Look for an MP structure in the len bytes at physical address addr.
static struct mp *
mpsearch1(physaddr_t a, int len)
{
f0105433:	55                   	push   %ebp
f0105434:	89 e5                	mov    %esp,%ebp
f0105436:	57                   	push   %edi
f0105437:	56                   	push   %esi
f0105438:	53                   	push   %ebx
f0105439:	83 ec 0c             	sub    $0xc,%esp
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010543c:	8b 0d 88 ae 22 f0    	mov    0xf022ae88,%ecx
f0105442:	89 c3                	mov    %eax,%ebx
f0105444:	c1 eb 0c             	shr    $0xc,%ebx
f0105447:	39 cb                	cmp    %ecx,%ebx
f0105449:	72 12                	jb     f010545d <mpsearch1+0x2a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010544b:	50                   	push   %eax
f010544c:	68 84 5e 10 f0       	push   $0xf0105e84
f0105451:	6a 57                	push   $0x57
f0105453:	68 21 7a 10 f0       	push   $0xf0107a21
f0105458:	e8 e3 ab ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f010545d:	8d 98 00 00 00 f0    	lea    -0x10000000(%eax),%ebx
	struct mp *mp = KADDR(a), *end = KADDR(a + len);
f0105463:	01 d0                	add    %edx,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0105465:	89 c2                	mov    %eax,%edx
f0105467:	c1 ea 0c             	shr    $0xc,%edx
f010546a:	39 ca                	cmp    %ecx,%edx
f010546c:	72 12                	jb     f0105480 <mpsearch1+0x4d>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010546e:	50                   	push   %eax
f010546f:	68 84 5e 10 f0       	push   $0xf0105e84
f0105474:	6a 57                	push   $0x57
f0105476:	68 21 7a 10 f0       	push   $0xf0107a21
f010547b:	e8 c0 ab ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0105480:	8d b0 00 00 00 f0    	lea    -0x10000000(%eax),%esi

	for (; mp < end; mp++)
f0105486:	eb 2f                	jmp    f01054b7 <mpsearch1+0x84>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f0105488:	83 ec 04             	sub    $0x4,%esp
f010548b:	6a 04                	push   $0x4
f010548d:	68 31 7a 10 f0       	push   $0xf0107a31
f0105492:	53                   	push   %ebx
f0105493:	e8 e3 fd ff ff       	call   f010527b <memcmp>
f0105498:	83 c4 10             	add    $0x10,%esp
f010549b:	85 c0                	test   %eax,%eax
f010549d:	75 15                	jne    f01054b4 <mpsearch1+0x81>
f010549f:	89 da                	mov    %ebx,%edx
f01054a1:	8d 7b 10             	lea    0x10(%ebx),%edi
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
		sum += ((uint8_t *)addr)[i];
f01054a4:	0f b6 0a             	movzbl (%edx),%ecx
f01054a7:	01 c8                	add    %ecx,%eax
f01054a9:	83 c2 01             	add    $0x1,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f01054ac:	39 d7                	cmp    %edx,%edi
f01054ae:	75 f4                	jne    f01054a4 <mpsearch1+0x71>
mpsearch1(physaddr_t a, int len)
{
	struct mp *mp = KADDR(a), *end = KADDR(a + len);

	for (; mp < end; mp++)
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f01054b0:	84 c0                	test   %al,%al
f01054b2:	74 0e                	je     f01054c2 <mpsearch1+0x8f>
static struct mp *
mpsearch1(physaddr_t a, int len)
{
	struct mp *mp = KADDR(a), *end = KADDR(a + len);

	for (; mp < end; mp++)
f01054b4:	83 c3 10             	add    $0x10,%ebx
f01054b7:	39 f3                	cmp    %esi,%ebx
f01054b9:	72 cd                	jb     f0105488 <mpsearch1+0x55>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
		    sum(mp, sizeof(*mp)) == 0)
			return mp;
	return NULL;
f01054bb:	b8 00 00 00 00       	mov    $0x0,%eax
f01054c0:	eb 02                	jmp    f01054c4 <mpsearch1+0x91>
f01054c2:	89 d8                	mov    %ebx,%eax
}
f01054c4:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01054c7:	5b                   	pop    %ebx
f01054c8:	5e                   	pop    %esi
f01054c9:	5f                   	pop    %edi
f01054ca:	5d                   	pop    %ebp
f01054cb:	c3                   	ret    

f01054cc <mp_init>:
	return conf;
}

void
mp_init(void)
{
f01054cc:	55                   	push   %ebp
f01054cd:	89 e5                	mov    %esp,%ebp
f01054cf:	57                   	push   %edi
f01054d0:	56                   	push   %esi
f01054d1:	53                   	push   %ebx
f01054d2:	83 ec 1c             	sub    $0x1c,%esp
	struct mpconf *conf;
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
f01054d5:	c7 05 c0 b3 22 f0 20 	movl   $0xf022b020,0xf022b3c0
f01054dc:	b0 22 f0 
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01054df:	83 3d 88 ae 22 f0 00 	cmpl   $0x0,0xf022ae88
f01054e6:	75 16                	jne    f01054fe <mp_init+0x32>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01054e8:	68 00 04 00 00       	push   $0x400
f01054ed:	68 84 5e 10 f0       	push   $0xf0105e84
f01054f2:	6a 6f                	push   $0x6f
f01054f4:	68 21 7a 10 f0       	push   $0xf0107a21
f01054f9:	e8 42 ab ff ff       	call   f0100040 <_panic>
	// The BIOS data area lives in 16-bit segment 0x40.
	bda = (uint8_t *) KADDR(0x40 << 4);

	// [MP 4] The 16-bit segment of the EBDA is in the two bytes
	// starting at byte 0x0E of the BDA.  0 if not present.
	if ((p = *(uint16_t *) (bda + 0x0E))) {
f01054fe:	0f b7 05 0e 04 00 f0 	movzwl 0xf000040e,%eax
f0105505:	85 c0                	test   %eax,%eax
f0105507:	74 16                	je     f010551f <mp_init+0x53>
		p <<= 4;	// Translate from segment to PA
		if ((mp = mpsearch1(p, 1024)))
f0105509:	c1 e0 04             	shl    $0x4,%eax
f010550c:	ba 00 04 00 00       	mov    $0x400,%edx
f0105511:	e8 1d ff ff ff       	call   f0105433 <mpsearch1>
f0105516:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0105519:	85 c0                	test   %eax,%eax
f010551b:	75 3c                	jne    f0105559 <mp_init+0x8d>
f010551d:	eb 20                	jmp    f010553f <mp_init+0x73>
			return mp;
	} else {
		// The size of base memory, in KB is in the two bytes
		// starting at 0x13 of the BDA.
		p = *(uint16_t *) (bda + 0x13) * 1024;
		if ((mp = mpsearch1(p - 1024, 1024)))
f010551f:	0f b7 05 13 04 00 f0 	movzwl 0xf0000413,%eax
f0105526:	c1 e0 0a             	shl    $0xa,%eax
f0105529:	2d 00 04 00 00       	sub    $0x400,%eax
f010552e:	ba 00 04 00 00       	mov    $0x400,%edx
f0105533:	e8 fb fe ff ff       	call   f0105433 <mpsearch1>
f0105538:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010553b:	85 c0                	test   %eax,%eax
f010553d:	75 1a                	jne    f0105559 <mp_init+0x8d>
			return mp;
	}
	return mpsearch1(0xF0000, 0x10000);
f010553f:	ba 00 00 01 00       	mov    $0x10000,%edx
f0105544:	b8 00 00 0f 00       	mov    $0xf0000,%eax
f0105549:	e8 e5 fe ff ff       	call   f0105433 <mpsearch1>
f010554e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
mpconfig(struct mp **pmp)
{
	struct mpconf *conf;
	struct mp *mp;

	if ((mp = mpsearch()) == 0)
f0105551:	85 c0                	test   %eax,%eax
f0105553:	0f 84 5d 02 00 00    	je     f01057b6 <mp_init+0x2ea>
		return NULL;
	if (mp->physaddr == 0 || mp->type != 0) {
f0105559:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010555c:	8b 70 04             	mov    0x4(%eax),%esi
f010555f:	85 f6                	test   %esi,%esi
f0105561:	74 06                	je     f0105569 <mp_init+0x9d>
f0105563:	80 78 0b 00          	cmpb   $0x0,0xb(%eax)
f0105567:	74 15                	je     f010557e <mp_init+0xb2>
		cprintf("SMP: Default configurations not implemented\n");
f0105569:	83 ec 0c             	sub    $0xc,%esp
f010556c:	68 94 78 10 f0       	push   $0xf0107894
f0105571:	e8 e1 e0 ff ff       	call   f0103657 <cprintf>
f0105576:	83 c4 10             	add    $0x10,%esp
f0105579:	e9 38 02 00 00       	jmp    f01057b6 <mp_init+0x2ea>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010557e:	89 f0                	mov    %esi,%eax
f0105580:	c1 e8 0c             	shr    $0xc,%eax
f0105583:	3b 05 88 ae 22 f0    	cmp    0xf022ae88,%eax
f0105589:	72 15                	jb     f01055a0 <mp_init+0xd4>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010558b:	56                   	push   %esi
f010558c:	68 84 5e 10 f0       	push   $0xf0105e84
f0105591:	68 90 00 00 00       	push   $0x90
f0105596:	68 21 7a 10 f0       	push   $0xf0107a21
f010559b:	e8 a0 aa ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f01055a0:	8d 9e 00 00 00 f0    	lea    -0x10000000(%esi),%ebx
		return NULL;
	}
	conf = (struct mpconf *) KADDR(mp->physaddr);
	if (memcmp(conf, "PCMP", 4) != 0) {
f01055a6:	83 ec 04             	sub    $0x4,%esp
f01055a9:	6a 04                	push   $0x4
f01055ab:	68 36 7a 10 f0       	push   $0xf0107a36
f01055b0:	53                   	push   %ebx
f01055b1:	e8 c5 fc ff ff       	call   f010527b <memcmp>
f01055b6:	83 c4 10             	add    $0x10,%esp
f01055b9:	85 c0                	test   %eax,%eax
f01055bb:	74 15                	je     f01055d2 <mp_init+0x106>
		cprintf("SMP: Incorrect MP configuration table signature\n");
f01055bd:	83 ec 0c             	sub    $0xc,%esp
f01055c0:	68 c4 78 10 f0       	push   $0xf01078c4
f01055c5:	e8 8d e0 ff ff       	call   f0103657 <cprintf>
f01055ca:	83 c4 10             	add    $0x10,%esp
f01055cd:	e9 e4 01 00 00       	jmp    f01057b6 <mp_init+0x2ea>
		return NULL;
	}
	if (sum(conf, conf->length) != 0) {
f01055d2:	0f b7 43 04          	movzwl 0x4(%ebx),%eax
f01055d6:	66 89 45 e2          	mov    %ax,-0x1e(%ebp)
f01055da:	0f b7 f8             	movzwl %ax,%edi
static uint8_t
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
f01055dd:	ba 00 00 00 00       	mov    $0x0,%edx
	for (i = 0; i < len; i++)
f01055e2:	b8 00 00 00 00       	mov    $0x0,%eax
f01055e7:	eb 0d                	jmp    f01055f6 <mp_init+0x12a>
		sum += ((uint8_t *)addr)[i];
f01055e9:	0f b6 8c 30 00 00 00 	movzbl -0x10000000(%eax,%esi,1),%ecx
f01055f0:	f0 
f01055f1:	01 ca                	add    %ecx,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f01055f3:	83 c0 01             	add    $0x1,%eax
f01055f6:	39 c7                	cmp    %eax,%edi
f01055f8:	75 ef                	jne    f01055e9 <mp_init+0x11d>
	conf = (struct mpconf *) KADDR(mp->physaddr);
	if (memcmp(conf, "PCMP", 4) != 0) {
		cprintf("SMP: Incorrect MP configuration table signature\n");
		return NULL;
	}
	if (sum(conf, conf->length) != 0) {
f01055fa:	84 d2                	test   %dl,%dl
f01055fc:	74 15                	je     f0105613 <mp_init+0x147>
		cprintf("SMP: Bad MP configuration checksum\n");
f01055fe:	83 ec 0c             	sub    $0xc,%esp
f0105601:	68 f8 78 10 f0       	push   $0xf01078f8
f0105606:	e8 4c e0 ff ff       	call   f0103657 <cprintf>
f010560b:	83 c4 10             	add    $0x10,%esp
f010560e:	e9 a3 01 00 00       	jmp    f01057b6 <mp_init+0x2ea>
		return NULL;
	}
	if (conf->version != 1 && conf->version != 4) {
f0105613:	0f b6 43 06          	movzbl 0x6(%ebx),%eax
f0105617:	3c 01                	cmp    $0x1,%al
f0105619:	74 1d                	je     f0105638 <mp_init+0x16c>
f010561b:	3c 04                	cmp    $0x4,%al
f010561d:	74 19                	je     f0105638 <mp_init+0x16c>
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
f010561f:	83 ec 08             	sub    $0x8,%esp
f0105622:	0f b6 c0             	movzbl %al,%eax
f0105625:	50                   	push   %eax
f0105626:	68 1c 79 10 f0       	push   $0xf010791c
f010562b:	e8 27 e0 ff ff       	call   f0103657 <cprintf>
f0105630:	83 c4 10             	add    $0x10,%esp
f0105633:	e9 7e 01 00 00       	jmp    f01057b6 <mp_init+0x2ea>
		return NULL;
	}
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f0105638:	0f b7 7b 28          	movzwl 0x28(%ebx),%edi
f010563c:	0f b7 4d e2          	movzwl -0x1e(%ebp),%ecx
static uint8_t
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
f0105640:	ba 00 00 00 00       	mov    $0x0,%edx
	for (i = 0; i < len; i++)
f0105645:	b8 00 00 00 00       	mov    $0x0,%eax
		sum += ((uint8_t *)addr)[i];
f010564a:	01 ce                	add    %ecx,%esi
f010564c:	eb 0d                	jmp    f010565b <mp_init+0x18f>
f010564e:	0f b6 8c 06 00 00 00 	movzbl -0x10000000(%esi,%eax,1),%ecx
f0105655:	f0 
f0105656:	01 ca                	add    %ecx,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f0105658:	83 c0 01             	add    $0x1,%eax
f010565b:	39 c7                	cmp    %eax,%edi
f010565d:	75 ef                	jne    f010564e <mp_init+0x182>
	}
	if (conf->version != 1 && conf->version != 4) {
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
		return NULL;
	}
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f010565f:	89 d0                	mov    %edx,%eax
f0105661:	02 43 2a             	add    0x2a(%ebx),%al
f0105664:	74 15                	je     f010567b <mp_init+0x1af>
		cprintf("SMP: Bad MP configuration extended checksum\n");
f0105666:	83 ec 0c             	sub    $0xc,%esp
f0105669:	68 3c 79 10 f0       	push   $0xf010793c
f010566e:	e8 e4 df ff ff       	call   f0103657 <cprintf>
f0105673:	83 c4 10             	add    $0x10,%esp
f0105676:	e9 3b 01 00 00       	jmp    f01057b6 <mp_init+0x2ea>
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
	if ((conf = mpconfig(&mp)) == 0)
f010567b:	85 db                	test   %ebx,%ebx
f010567d:	0f 84 33 01 00 00    	je     f01057b6 <mp_init+0x2ea>
		return;
	ismp = 1;
f0105683:	c7 05 00 b0 22 f0 01 	movl   $0x1,0xf022b000
f010568a:	00 00 00 
	lapicaddr = conf->lapicaddr;
f010568d:	8b 43 24             	mov    0x24(%ebx),%eax
f0105690:	a3 00 c0 26 f0       	mov    %eax,0xf026c000

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f0105695:	8d 7b 2c             	lea    0x2c(%ebx),%edi
f0105698:	be 00 00 00 00       	mov    $0x0,%esi
f010569d:	e9 85 00 00 00       	jmp    f0105727 <mp_init+0x25b>
		switch (*p) {
f01056a2:	0f b6 07             	movzbl (%edi),%eax
f01056a5:	84 c0                	test   %al,%al
f01056a7:	74 06                	je     f01056af <mp_init+0x1e3>
f01056a9:	3c 04                	cmp    $0x4,%al
f01056ab:	77 55                	ja     f0105702 <mp_init+0x236>
f01056ad:	eb 4e                	jmp    f01056fd <mp_init+0x231>
		case MPPROC:
			proc = (struct mpproc *)p;
			if (proc->flags & MPPROC_BOOT)
f01056af:	f6 47 03 02          	testb  $0x2,0x3(%edi)
f01056b3:	74 11                	je     f01056c6 <mp_init+0x1fa>
				bootcpu = &cpus[ncpu];
f01056b5:	6b 05 c4 b3 22 f0 74 	imul   $0x74,0xf022b3c4,%eax
f01056bc:	05 20 b0 22 f0       	add    $0xf022b020,%eax
f01056c1:	a3 c0 b3 22 f0       	mov    %eax,0xf022b3c0
			if (ncpu < NCPU) {
f01056c6:	a1 c4 b3 22 f0       	mov    0xf022b3c4,%eax
f01056cb:	83 f8 07             	cmp    $0x7,%eax
f01056ce:	7f 13                	jg     f01056e3 <mp_init+0x217>
				cpus[ncpu].cpu_id = ncpu;
f01056d0:	6b d0 74             	imul   $0x74,%eax,%edx
f01056d3:	88 82 20 b0 22 f0    	mov    %al,-0xfdd4fe0(%edx)
				ncpu++;
f01056d9:	83 c0 01             	add    $0x1,%eax
f01056dc:	a3 c4 b3 22 f0       	mov    %eax,0xf022b3c4
f01056e1:	eb 15                	jmp    f01056f8 <mp_init+0x22c>
			} else {
				cprintf("SMP: too many CPUs, CPU %d disabled\n",
f01056e3:	83 ec 08             	sub    $0x8,%esp
f01056e6:	0f b6 47 01          	movzbl 0x1(%edi),%eax
f01056ea:	50                   	push   %eax
f01056eb:	68 6c 79 10 f0       	push   $0xf010796c
f01056f0:	e8 62 df ff ff       	call   f0103657 <cprintf>
f01056f5:	83 c4 10             	add    $0x10,%esp
					proc->apicid);
			}
			p += sizeof(struct mpproc);
f01056f8:	83 c7 14             	add    $0x14,%edi
			continue;
f01056fb:	eb 27                	jmp    f0105724 <mp_init+0x258>
		case MPBUS:
		case MPIOAPIC:
		case MPIOINTR:
		case MPLINTR:
			p += 8;
f01056fd:	83 c7 08             	add    $0x8,%edi
			continue;
f0105700:	eb 22                	jmp    f0105724 <mp_init+0x258>
		default:
			cprintf("mpinit: unknown config type %x\n", *p);
f0105702:	83 ec 08             	sub    $0x8,%esp
f0105705:	0f b6 c0             	movzbl %al,%eax
f0105708:	50                   	push   %eax
f0105709:	68 94 79 10 f0       	push   $0xf0107994
f010570e:	e8 44 df ff ff       	call   f0103657 <cprintf>
			ismp = 0;
f0105713:	c7 05 00 b0 22 f0 00 	movl   $0x0,0xf022b000
f010571a:	00 00 00 
			i = conf->entry;
f010571d:	0f b7 73 22          	movzwl 0x22(%ebx),%esi
f0105721:	83 c4 10             	add    $0x10,%esp
	if ((conf = mpconfig(&mp)) == 0)
		return;
	ismp = 1;
	lapicaddr = conf->lapicaddr;

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f0105724:	83 c6 01             	add    $0x1,%esi
f0105727:	0f b7 43 22          	movzwl 0x22(%ebx),%eax
f010572b:	39 c6                	cmp    %eax,%esi
f010572d:	0f 82 6f ff ff ff    	jb     f01056a2 <mp_init+0x1d6>
			ismp = 0;
			i = conf->entry;
		}
	}

	bootcpu->cpu_status = CPU_STARTED;
f0105733:	a1 c0 b3 22 f0       	mov    0xf022b3c0,%eax
f0105738:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
	if (!ismp) {
f010573f:	83 3d 00 b0 22 f0 00 	cmpl   $0x0,0xf022b000
f0105746:	75 26                	jne    f010576e <mp_init+0x2a2>
		// Didn't like what we found; fall back to no MP.
		ncpu = 1;
f0105748:	c7 05 c4 b3 22 f0 01 	movl   $0x1,0xf022b3c4
f010574f:	00 00 00 
		lapicaddr = 0;
f0105752:	c7 05 00 c0 26 f0 00 	movl   $0x0,0xf026c000
f0105759:	00 00 00 
		cprintf("SMP: configuration not found, SMP disabled\n");
f010575c:	83 ec 0c             	sub    $0xc,%esp
f010575f:	68 b4 79 10 f0       	push   $0xf01079b4
f0105764:	e8 ee de ff ff       	call   f0103657 <cprintf>
		return;
f0105769:	83 c4 10             	add    $0x10,%esp
f010576c:	eb 48                	jmp    f01057b6 <mp_init+0x2ea>
	}
	cprintf("SMP: CPU %d found %d CPU(s)\n", bootcpu->cpu_id,  ncpu);
f010576e:	83 ec 04             	sub    $0x4,%esp
f0105771:	ff 35 c4 b3 22 f0    	pushl  0xf022b3c4
f0105777:	0f b6 00             	movzbl (%eax),%eax
f010577a:	50                   	push   %eax
f010577b:	68 3b 7a 10 f0       	push   $0xf0107a3b
f0105780:	e8 d2 de ff ff       	call   f0103657 <cprintf>

	if (mp->imcrp) {
f0105785:	83 c4 10             	add    $0x10,%esp
f0105788:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010578b:	80 78 0c 00          	cmpb   $0x0,0xc(%eax)
f010578f:	74 25                	je     f01057b6 <mp_init+0x2ea>
		// [MP 3.2.6.1] If the hardware implements PIC mode,
		// switch to getting interrupts from the LAPIC.
		cprintf("SMP: Setting IMCR to switch from PIC mode to symmetric I/O mode\n");
f0105791:	83 ec 0c             	sub    $0xc,%esp
f0105794:	68 e0 79 10 f0       	push   $0xf01079e0
f0105799:	e8 b9 de ff ff       	call   f0103657 <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010579e:	ba 22 00 00 00       	mov    $0x22,%edx
f01057a3:	b8 70 00 00 00       	mov    $0x70,%eax
f01057a8:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01057a9:	ba 23 00 00 00       	mov    $0x23,%edx
f01057ae:	ec                   	in     (%dx),%al
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01057af:	83 c8 01             	or     $0x1,%eax
f01057b2:	ee                   	out    %al,(%dx)
f01057b3:	83 c4 10             	add    $0x10,%esp
		outb(0x22, 0x70);   // Select IMCR
		outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
	}
}
f01057b6:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01057b9:	5b                   	pop    %ebx
f01057ba:	5e                   	pop    %esi
f01057bb:	5f                   	pop    %edi
f01057bc:	5d                   	pop    %ebp
f01057bd:	c3                   	ret    

f01057be <lapicw>:
physaddr_t lapicaddr;        // Initialized in mpconfig.c
volatile uint32_t *lapic;

static void
lapicw(int index, int value)
{
f01057be:	55                   	push   %ebp
f01057bf:	89 e5                	mov    %esp,%ebp
	lapic[index] = value;
f01057c1:	8b 0d 04 c0 26 f0    	mov    0xf026c004,%ecx
f01057c7:	8d 04 81             	lea    (%ecx,%eax,4),%eax
f01057ca:	89 10                	mov    %edx,(%eax)
	lapic[ID];  // wait for write to finish, by reading
f01057cc:	a1 04 c0 26 f0       	mov    0xf026c004,%eax
f01057d1:	8b 40 20             	mov    0x20(%eax),%eax
}
f01057d4:	5d                   	pop    %ebp
f01057d5:	c3                   	ret    

f01057d6 <cpunum>:
	lapicw(TPR, 0);
}

int
cpunum(void)
{
f01057d6:	55                   	push   %ebp
f01057d7:	89 e5                	mov    %esp,%ebp
	if (lapic)
f01057d9:	a1 04 c0 26 f0       	mov    0xf026c004,%eax
f01057de:	85 c0                	test   %eax,%eax
f01057e0:	74 08                	je     f01057ea <cpunum+0x14>
		return lapic[ID] >> 24;
f01057e2:	8b 40 20             	mov    0x20(%eax),%eax
f01057e5:	c1 e8 18             	shr    $0x18,%eax
f01057e8:	eb 05                	jmp    f01057ef <cpunum+0x19>
	return 0;
f01057ea:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01057ef:	5d                   	pop    %ebp
f01057f0:	c3                   	ret    

f01057f1 <lapic_init>:
}

void
lapic_init(void)
{
	if (!lapicaddr)
f01057f1:	a1 00 c0 26 f0       	mov    0xf026c000,%eax
f01057f6:	85 c0                	test   %eax,%eax
f01057f8:	0f 84 21 01 00 00    	je     f010591f <lapic_init+0x12e>
	lapic[ID];  // wait for write to finish, by reading
}

void
lapic_init(void)
{
f01057fe:	55                   	push   %ebp
f01057ff:	89 e5                	mov    %esp,%ebp
f0105801:	83 ec 10             	sub    $0x10,%esp
	if (!lapicaddr)
		return;

	// lapicaddr is the physical address of the LAPIC's 4K MMIO
	// region.  Map it in to virtual memory so we can access it.
	lapic = mmio_map_region(lapicaddr, 4096);
f0105804:	68 00 10 00 00       	push   $0x1000
f0105809:	50                   	push   %eax
f010580a:	e8 75 ba ff ff       	call   f0101284 <mmio_map_region>
f010580f:	a3 04 c0 26 f0       	mov    %eax,0xf026c004

	// Enable local APIC; set spurious interrupt vector.
	lapicw(SVR, ENABLE | (IRQ_OFFSET + IRQ_SPURIOUS));
f0105814:	ba 27 01 00 00       	mov    $0x127,%edx
f0105819:	b8 3c 00 00 00       	mov    $0x3c,%eax
f010581e:	e8 9b ff ff ff       	call   f01057be <lapicw>

	// The timer repeatedly counts down at bus frequency
	// from lapic[TICR] and then issues an interrupt.  
	// If we cared more about precise timekeeping,
	// TICR would be calibrated using an external time source.
	lapicw(TDCR, X1);
f0105823:	ba 0b 00 00 00       	mov    $0xb,%edx
f0105828:	b8 f8 00 00 00       	mov    $0xf8,%eax
f010582d:	e8 8c ff ff ff       	call   f01057be <lapicw>
	lapicw(TIMER, PERIODIC | (IRQ_OFFSET + IRQ_TIMER));
f0105832:	ba 20 00 02 00       	mov    $0x20020,%edx
f0105837:	b8 c8 00 00 00       	mov    $0xc8,%eax
f010583c:	e8 7d ff ff ff       	call   f01057be <lapicw>
	lapicw(TICR, 10000000); 
f0105841:	ba 80 96 98 00       	mov    $0x989680,%edx
f0105846:	b8 e0 00 00 00       	mov    $0xe0,%eax
f010584b:	e8 6e ff ff ff       	call   f01057be <lapicw>
	//
	// According to Intel MP Specification, the BIOS should initialize
	// BSP's local APIC in Virtual Wire Mode, in which 8259A's
	// INTR is virtually connected to BSP's LINTIN0. In this mode,
	// we do not need to program the IOAPIC.
	if (thiscpu != bootcpu)
f0105850:	e8 81 ff ff ff       	call   f01057d6 <cpunum>
f0105855:	6b c0 74             	imul   $0x74,%eax,%eax
f0105858:	05 20 b0 22 f0       	add    $0xf022b020,%eax
f010585d:	83 c4 10             	add    $0x10,%esp
f0105860:	39 05 c0 b3 22 f0    	cmp    %eax,0xf022b3c0
f0105866:	74 0f                	je     f0105877 <lapic_init+0x86>
		lapicw(LINT0, MASKED);
f0105868:	ba 00 00 01 00       	mov    $0x10000,%edx
f010586d:	b8 d4 00 00 00       	mov    $0xd4,%eax
f0105872:	e8 47 ff ff ff       	call   f01057be <lapicw>

	// Disable NMI (LINT1) on all CPUs
	lapicw(LINT1, MASKED);
f0105877:	ba 00 00 01 00       	mov    $0x10000,%edx
f010587c:	b8 d8 00 00 00       	mov    $0xd8,%eax
f0105881:	e8 38 ff ff ff       	call   f01057be <lapicw>

	// Disable performance counter overflow interrupts
	// on machines that provide that interrupt entry.
	if (((lapic[VER]>>16) & 0xFF) >= 4)
f0105886:	a1 04 c0 26 f0       	mov    0xf026c004,%eax
f010588b:	8b 40 30             	mov    0x30(%eax),%eax
f010588e:	c1 e8 10             	shr    $0x10,%eax
f0105891:	3c 03                	cmp    $0x3,%al
f0105893:	76 0f                	jbe    f01058a4 <lapic_init+0xb3>
		lapicw(PCINT, MASKED);
f0105895:	ba 00 00 01 00       	mov    $0x10000,%edx
f010589a:	b8 d0 00 00 00       	mov    $0xd0,%eax
f010589f:	e8 1a ff ff ff       	call   f01057be <lapicw>

	// Map error interrupt to IRQ_ERROR.
	lapicw(ERROR, IRQ_OFFSET + IRQ_ERROR);
f01058a4:	ba 33 00 00 00       	mov    $0x33,%edx
f01058a9:	b8 dc 00 00 00       	mov    $0xdc,%eax
f01058ae:	e8 0b ff ff ff       	call   f01057be <lapicw>

	// Clear error status register (requires back-to-back writes).
	lapicw(ESR, 0);
f01058b3:	ba 00 00 00 00       	mov    $0x0,%edx
f01058b8:	b8 a0 00 00 00       	mov    $0xa0,%eax
f01058bd:	e8 fc fe ff ff       	call   f01057be <lapicw>
	lapicw(ESR, 0);
f01058c2:	ba 00 00 00 00       	mov    $0x0,%edx
f01058c7:	b8 a0 00 00 00       	mov    $0xa0,%eax
f01058cc:	e8 ed fe ff ff       	call   f01057be <lapicw>

	// Ack any outstanding interrupts.
	lapicw(EOI, 0);
f01058d1:	ba 00 00 00 00       	mov    $0x0,%edx
f01058d6:	b8 2c 00 00 00       	mov    $0x2c,%eax
f01058db:	e8 de fe ff ff       	call   f01057be <lapicw>

	// Send an Init Level De-Assert to synchronize arbitration ID's.
	lapicw(ICRHI, 0);
f01058e0:	ba 00 00 00 00       	mov    $0x0,%edx
f01058e5:	b8 c4 00 00 00       	mov    $0xc4,%eax
f01058ea:	e8 cf fe ff ff       	call   f01057be <lapicw>
	lapicw(ICRLO, BCAST | INIT | LEVEL);
f01058ef:	ba 00 85 08 00       	mov    $0x88500,%edx
f01058f4:	b8 c0 00 00 00       	mov    $0xc0,%eax
f01058f9:	e8 c0 fe ff ff       	call   f01057be <lapicw>
	while(lapic[ICRLO] & DELIVS)
f01058fe:	8b 15 04 c0 26 f0    	mov    0xf026c004,%edx
f0105904:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f010590a:	f6 c4 10             	test   $0x10,%ah
f010590d:	75 f5                	jne    f0105904 <lapic_init+0x113>
		;

	// Enable interrupts on the APIC (but not on the processor).
	lapicw(TPR, 0);
f010590f:	ba 00 00 00 00       	mov    $0x0,%edx
f0105914:	b8 20 00 00 00       	mov    $0x20,%eax
f0105919:	e8 a0 fe ff ff       	call   f01057be <lapicw>
}
f010591e:	c9                   	leave  
f010591f:	f3 c3                	repz ret 

f0105921 <lapic_eoi>:

// Acknowledge interrupt.
void
lapic_eoi(void)
{
	if (lapic)
f0105921:	83 3d 04 c0 26 f0 00 	cmpl   $0x0,0xf026c004
f0105928:	74 13                	je     f010593d <lapic_eoi+0x1c>
}

// Acknowledge interrupt.
void
lapic_eoi(void)
{
f010592a:	55                   	push   %ebp
f010592b:	89 e5                	mov    %esp,%ebp
	if (lapic)
		lapicw(EOI, 0);
f010592d:	ba 00 00 00 00       	mov    $0x0,%edx
f0105932:	b8 2c 00 00 00       	mov    $0x2c,%eax
f0105937:	e8 82 fe ff ff       	call   f01057be <lapicw>
}
f010593c:	5d                   	pop    %ebp
f010593d:	f3 c3                	repz ret 

f010593f <lapic_startap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapic_startap(uint8_t apicid, uint32_t addr)
{
f010593f:	55                   	push   %ebp
f0105940:	89 e5                	mov    %esp,%ebp
f0105942:	56                   	push   %esi
f0105943:	53                   	push   %ebx
f0105944:	8b 75 08             	mov    0x8(%ebp),%esi
f0105947:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010594a:	ba 70 00 00 00       	mov    $0x70,%edx
f010594f:	b8 0f 00 00 00       	mov    $0xf,%eax
f0105954:	ee                   	out    %al,(%dx)
f0105955:	ba 71 00 00 00       	mov    $0x71,%edx
f010595a:	b8 0a 00 00 00       	mov    $0xa,%eax
f010595f:	ee                   	out    %al,(%dx)
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0105960:	83 3d 88 ae 22 f0 00 	cmpl   $0x0,0xf022ae88
f0105967:	75 19                	jne    f0105982 <lapic_startap+0x43>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0105969:	68 67 04 00 00       	push   $0x467
f010596e:	68 84 5e 10 f0       	push   $0xf0105e84
f0105973:	68 98 00 00 00       	push   $0x98
f0105978:	68 58 7a 10 f0       	push   $0xf0107a58
f010597d:	e8 be a6 ff ff       	call   f0100040 <_panic>
	// and the warm reset vector (DWORD based at 40:67) to point at
	// the AP startup code prior to the [universal startup algorithm]."
	outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
	outb(IO_RTC+1, 0x0A);
	wrv = (uint16_t *)KADDR((0x40 << 4 | 0x67));  // Warm reset vector
	wrv[0] = 0;
f0105982:	66 c7 05 67 04 00 f0 	movw   $0x0,0xf0000467
f0105989:	00 00 
	wrv[1] = addr >> 4;
f010598b:	89 d8                	mov    %ebx,%eax
f010598d:	c1 e8 04             	shr    $0x4,%eax
f0105990:	66 a3 69 04 00 f0    	mov    %ax,0xf0000469

	// "Universal startup algorithm."
	// Send INIT (level-triggered) interrupt to reset other CPU.
	lapicw(ICRHI, apicid << 24);
f0105996:	c1 e6 18             	shl    $0x18,%esi
f0105999:	89 f2                	mov    %esi,%edx
f010599b:	b8 c4 00 00 00       	mov    $0xc4,%eax
f01059a0:	e8 19 fe ff ff       	call   f01057be <lapicw>
	lapicw(ICRLO, INIT | LEVEL | ASSERT);
f01059a5:	ba 00 c5 00 00       	mov    $0xc500,%edx
f01059aa:	b8 c0 00 00 00       	mov    $0xc0,%eax
f01059af:	e8 0a fe ff ff       	call   f01057be <lapicw>
	microdelay(200);
	lapicw(ICRLO, INIT | LEVEL);
f01059b4:	ba 00 85 00 00       	mov    $0x8500,%edx
f01059b9:	b8 c0 00 00 00       	mov    $0xc0,%eax
f01059be:	e8 fb fd ff ff       	call   f01057be <lapicw>
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
		lapicw(ICRLO, STARTUP | (addr >> 12));
f01059c3:	c1 eb 0c             	shr    $0xc,%ebx
f01059c6:	80 cf 06             	or     $0x6,%bh
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
f01059c9:	89 f2                	mov    %esi,%edx
f01059cb:	b8 c4 00 00 00       	mov    $0xc4,%eax
f01059d0:	e8 e9 fd ff ff       	call   f01057be <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f01059d5:	89 da                	mov    %ebx,%edx
f01059d7:	b8 c0 00 00 00       	mov    $0xc0,%eax
f01059dc:	e8 dd fd ff ff       	call   f01057be <lapicw>
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
f01059e1:	89 f2                	mov    %esi,%edx
f01059e3:	b8 c4 00 00 00       	mov    $0xc4,%eax
f01059e8:	e8 d1 fd ff ff       	call   f01057be <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f01059ed:	89 da                	mov    %ebx,%edx
f01059ef:	b8 c0 00 00 00       	mov    $0xc0,%eax
f01059f4:	e8 c5 fd ff ff       	call   f01057be <lapicw>
		microdelay(200);
	}
}
f01059f9:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01059fc:	5b                   	pop    %ebx
f01059fd:	5e                   	pop    %esi
f01059fe:	5d                   	pop    %ebp
f01059ff:	c3                   	ret    

f0105a00 <lapic_ipi>:

void
lapic_ipi(int vector)
{
f0105a00:	55                   	push   %ebp
f0105a01:	89 e5                	mov    %esp,%ebp
	lapicw(ICRLO, OTHERS | FIXED | vector);
f0105a03:	8b 55 08             	mov    0x8(%ebp),%edx
f0105a06:	81 ca 00 00 0c 00    	or     $0xc0000,%edx
f0105a0c:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105a11:	e8 a8 fd ff ff       	call   f01057be <lapicw>
	while (lapic[ICRLO] & DELIVS)
f0105a16:	8b 15 04 c0 26 f0    	mov    0xf026c004,%edx
f0105a1c:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f0105a22:	f6 c4 10             	test   $0x10,%ah
f0105a25:	75 f5                	jne    f0105a1c <lapic_ipi+0x1c>
		;
}
f0105a27:	5d                   	pop    %ebp
f0105a28:	c3                   	ret    

f0105a29 <__spin_initlock>:
}
#endif

void
__spin_initlock(struct spinlock *lk, char *name)
{
f0105a29:	55                   	push   %ebp
f0105a2a:	89 e5                	mov    %esp,%ebp
f0105a2c:	8b 45 08             	mov    0x8(%ebp),%eax
	lk->locked = 0;
f0105a2f:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
#ifdef DEBUG_SPINLOCK
	lk->name = name;
f0105a35:	8b 55 0c             	mov    0xc(%ebp),%edx
f0105a38:	89 50 04             	mov    %edx,0x4(%eax)
	lk->cpu = 0;
f0105a3b:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
#endif
}
f0105a42:	5d                   	pop    %ebp
f0105a43:	c3                   	ret    

f0105a44 <spin_lock>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
spin_lock(struct spinlock *lk)
{
f0105a44:	55                   	push   %ebp
f0105a45:	89 e5                	mov    %esp,%ebp
f0105a47:	56                   	push   %esi
f0105a48:	53                   	push   %ebx
f0105a49:	8b 5d 08             	mov    0x8(%ebp),%ebx

// Check whether this CPU is holding the lock.
static int
holding(struct spinlock *lock)
{
	return lock->locked && lock->cpu == thiscpu;
f0105a4c:	83 3b 00             	cmpl   $0x0,(%ebx)
f0105a4f:	74 14                	je     f0105a65 <spin_lock+0x21>
f0105a51:	8b 73 08             	mov    0x8(%ebx),%esi
f0105a54:	e8 7d fd ff ff       	call   f01057d6 <cpunum>
f0105a59:	6b c0 74             	imul   $0x74,%eax,%eax
f0105a5c:	05 20 b0 22 f0       	add    $0xf022b020,%eax
// other CPUs to waste time spinning to acquire it.
void
spin_lock(struct spinlock *lk)
{
#ifdef DEBUG_SPINLOCK
	if (holding(lk))
f0105a61:	39 c6                	cmp    %eax,%esi
f0105a63:	74 07                	je     f0105a6c <spin_lock+0x28>
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"
f0105a65:	ba 01 00 00 00       	mov    $0x1,%edx
f0105a6a:	eb 20                	jmp    f0105a8c <spin_lock+0x48>
		panic("CPU %d cannot acquire %s: already holding", cpunum(), lk->name);
f0105a6c:	8b 5b 04             	mov    0x4(%ebx),%ebx
f0105a6f:	e8 62 fd ff ff       	call   f01057d6 <cpunum>
f0105a74:	83 ec 0c             	sub    $0xc,%esp
f0105a77:	53                   	push   %ebx
f0105a78:	50                   	push   %eax
f0105a79:	68 68 7a 10 f0       	push   $0xf0107a68
f0105a7e:	6a 41                	push   $0x41
f0105a80:	68 cc 7a 10 f0       	push   $0xf0107acc
f0105a85:	e8 b6 a5 ff ff       	call   f0100040 <_panic>

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
		asm volatile ("pause");
f0105a8a:	f3 90                	pause  
f0105a8c:	89 d0                	mov    %edx,%eax
f0105a8e:	f0 87 03             	lock xchg %eax,(%ebx)
#endif

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
f0105a91:	85 c0                	test   %eax,%eax
f0105a93:	75 f5                	jne    f0105a8a <spin_lock+0x46>
		asm volatile ("pause");

	// Record info about lock acquisition for debugging.
#ifdef DEBUG_SPINLOCK
	lk->cpu = thiscpu;
f0105a95:	e8 3c fd ff ff       	call   f01057d6 <cpunum>
f0105a9a:	6b c0 74             	imul   $0x74,%eax,%eax
f0105a9d:	05 20 b0 22 f0       	add    $0xf022b020,%eax
f0105aa2:	89 43 08             	mov    %eax,0x8(%ebx)
	get_caller_pcs(lk->pcs);
f0105aa5:	83 c3 0c             	add    $0xc,%ebx

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f0105aa8:	89 ea                	mov    %ebp,%edx
{
	uint32_t *ebp;
	int i;

	ebp = (uint32_t *)read_ebp();
	for (i = 0; i < 10; i++){
f0105aaa:	b8 00 00 00 00       	mov    $0x0,%eax
f0105aaf:	eb 0b                	jmp    f0105abc <spin_lock+0x78>
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
			break;
		pcs[i] = ebp[1];          // saved %eip
f0105ab1:	8b 4a 04             	mov    0x4(%edx),%ecx
f0105ab4:	89 0c 83             	mov    %ecx,(%ebx,%eax,4)
		ebp = (uint32_t *)ebp[0]; // saved %ebp
f0105ab7:	8b 12                	mov    (%edx),%edx
{
	uint32_t *ebp;
	int i;

	ebp = (uint32_t *)read_ebp();
	for (i = 0; i < 10; i++){
f0105ab9:	83 c0 01             	add    $0x1,%eax
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
f0105abc:	81 fa ff ff 7f ef    	cmp    $0xef7fffff,%edx
f0105ac2:	76 11                	jbe    f0105ad5 <spin_lock+0x91>
f0105ac4:	83 f8 09             	cmp    $0x9,%eax
f0105ac7:	7e e8                	jle    f0105ab1 <spin_lock+0x6d>
f0105ac9:	eb 0a                	jmp    f0105ad5 <spin_lock+0x91>
			break;
		pcs[i] = ebp[1];          // saved %eip
		ebp = (uint32_t *)ebp[0]; // saved %ebp
	}
	for (; i < 10; i++)
		pcs[i] = 0;
f0105acb:	c7 04 83 00 00 00 00 	movl   $0x0,(%ebx,%eax,4)
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
			break;
		pcs[i] = ebp[1];          // saved %eip
		ebp = (uint32_t *)ebp[0]; // saved %ebp
	}
	for (; i < 10; i++)
f0105ad2:	83 c0 01             	add    $0x1,%eax
f0105ad5:	83 f8 09             	cmp    $0x9,%eax
f0105ad8:	7e f1                	jle    f0105acb <spin_lock+0x87>
	// Record info about lock acquisition for debugging.
#ifdef DEBUG_SPINLOCK
	lk->cpu = thiscpu;
	get_caller_pcs(lk->pcs);
#endif
}
f0105ada:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0105add:	5b                   	pop    %ebx
f0105ade:	5e                   	pop    %esi
f0105adf:	5d                   	pop    %ebp
f0105ae0:	c3                   	ret    

f0105ae1 <spin_unlock>:

// Release the lock.
void
spin_unlock(struct spinlock *lk)
{
f0105ae1:	55                   	push   %ebp
f0105ae2:	89 e5                	mov    %esp,%ebp
f0105ae4:	57                   	push   %edi
f0105ae5:	56                   	push   %esi
f0105ae6:	53                   	push   %ebx
f0105ae7:	83 ec 4c             	sub    $0x4c,%esp
f0105aea:	8b 75 08             	mov    0x8(%ebp),%esi

// Check whether this CPU is holding the lock.
static int
holding(struct spinlock *lock)
{
	return lock->locked && lock->cpu == thiscpu;
f0105aed:	83 3e 00             	cmpl   $0x0,(%esi)
f0105af0:	74 18                	je     f0105b0a <spin_unlock+0x29>
f0105af2:	8b 5e 08             	mov    0x8(%esi),%ebx
f0105af5:	e8 dc fc ff ff       	call   f01057d6 <cpunum>
f0105afa:	6b c0 74             	imul   $0x74,%eax,%eax
f0105afd:	05 20 b0 22 f0       	add    $0xf022b020,%eax
// Release the lock.
void
spin_unlock(struct spinlock *lk)
{
#ifdef DEBUG_SPINLOCK
	if (!holding(lk)) {
f0105b02:	39 c3                	cmp    %eax,%ebx
f0105b04:	0f 84 a5 00 00 00    	je     f0105baf <spin_unlock+0xce>
		int i;
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
f0105b0a:	83 ec 04             	sub    $0x4,%esp
f0105b0d:	6a 28                	push   $0x28
f0105b0f:	8d 46 0c             	lea    0xc(%esi),%eax
f0105b12:	50                   	push   %eax
f0105b13:	8d 5d c0             	lea    -0x40(%ebp),%ebx
f0105b16:	53                   	push   %ebx
f0105b17:	e8 e4 f6 ff ff       	call   f0105200 <memmove>
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
f0105b1c:	8b 46 08             	mov    0x8(%esi),%eax
	if (!holding(lk)) {
		int i;
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
f0105b1f:	0f b6 38             	movzbl (%eax),%edi
f0105b22:	8b 76 04             	mov    0x4(%esi),%esi
f0105b25:	e8 ac fc ff ff       	call   f01057d6 <cpunum>
f0105b2a:	57                   	push   %edi
f0105b2b:	56                   	push   %esi
f0105b2c:	50                   	push   %eax
f0105b2d:	68 94 7a 10 f0       	push   $0xf0107a94
f0105b32:	e8 20 db ff ff       	call   f0103657 <cprintf>
f0105b37:	83 c4 20             	add    $0x20,%esp
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
			struct Eipdebuginfo info;
			if (debuginfo_eip(pcs[i], &info) >= 0)
f0105b3a:	8d 7d a8             	lea    -0x58(%ebp),%edi
f0105b3d:	eb 54                	jmp    f0105b93 <spin_unlock+0xb2>
f0105b3f:	83 ec 08             	sub    $0x8,%esp
f0105b42:	57                   	push   %edi
f0105b43:	50                   	push   %eax
f0105b44:	e8 ba eb ff ff       	call   f0104703 <debuginfo_eip>
f0105b49:	83 c4 10             	add    $0x10,%esp
f0105b4c:	85 c0                	test   %eax,%eax
f0105b4e:	78 27                	js     f0105b77 <spin_unlock+0x96>
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
					info.eip_file, info.eip_line,
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
f0105b50:	8b 06                	mov    (%esi),%eax
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
			struct Eipdebuginfo info;
			if (debuginfo_eip(pcs[i], &info) >= 0)
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
f0105b52:	83 ec 04             	sub    $0x4,%esp
f0105b55:	89 c2                	mov    %eax,%edx
f0105b57:	2b 55 b8             	sub    -0x48(%ebp),%edx
f0105b5a:	52                   	push   %edx
f0105b5b:	ff 75 b0             	pushl  -0x50(%ebp)
f0105b5e:	ff 75 b4             	pushl  -0x4c(%ebp)
f0105b61:	ff 75 ac             	pushl  -0x54(%ebp)
f0105b64:	ff 75 a8             	pushl  -0x58(%ebp)
f0105b67:	50                   	push   %eax
f0105b68:	68 dc 7a 10 f0       	push   $0xf0107adc
f0105b6d:	e8 e5 da ff ff       	call   f0103657 <cprintf>
f0105b72:	83 c4 20             	add    $0x20,%esp
f0105b75:	eb 12                	jmp    f0105b89 <spin_unlock+0xa8>
					info.eip_file, info.eip_line,
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
			else
				cprintf("  %08x\n", pcs[i]);
f0105b77:	83 ec 08             	sub    $0x8,%esp
f0105b7a:	ff 36                	pushl  (%esi)
f0105b7c:	68 f3 7a 10 f0       	push   $0xf0107af3
f0105b81:	e8 d1 da ff ff       	call   f0103657 <cprintf>
f0105b86:	83 c4 10             	add    $0x10,%esp
f0105b89:	83 c3 04             	add    $0x4,%ebx
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
f0105b8c:	8d 45 e8             	lea    -0x18(%ebp),%eax
f0105b8f:	39 c3                	cmp    %eax,%ebx
f0105b91:	74 08                	je     f0105b9b <spin_unlock+0xba>
f0105b93:	89 de                	mov    %ebx,%esi
f0105b95:	8b 03                	mov    (%ebx),%eax
f0105b97:	85 c0                	test   %eax,%eax
f0105b99:	75 a4                	jne    f0105b3f <spin_unlock+0x5e>
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
			else
				cprintf("  %08x\n", pcs[i]);
		}
		panic("spin_unlock");
f0105b9b:	83 ec 04             	sub    $0x4,%esp
f0105b9e:	68 fb 7a 10 f0       	push   $0xf0107afb
f0105ba3:	6a 67                	push   $0x67
f0105ba5:	68 cc 7a 10 f0       	push   $0xf0107acc
f0105baa:	e8 91 a4 ff ff       	call   f0100040 <_panic>
	}

	lk->pcs[0] = 0;
f0105baf:	c7 46 0c 00 00 00 00 	movl   $0x0,0xc(%esi)
	lk->cpu = 0;
f0105bb6:	c7 46 08 00 00 00 00 	movl   $0x0,0x8(%esi)
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"
f0105bbd:	b8 00 00 00 00       	mov    $0x0,%eax
f0105bc2:	f0 87 06             	lock xchg %eax,(%esi)
	// respect to any other instruction which references the same memory.
	// x86 CPUs will not reorder loads/stores across locked instructions
	// (vol 3, 8.2.2). Because xchg() is implemented using asm volatile,
	// gcc will not reorder C statements across the xchg.
	xchg(&lk->locked, 0);
}
f0105bc5:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0105bc8:	5b                   	pop    %ebx
f0105bc9:	5e                   	pop    %esi
f0105bca:	5f                   	pop    %edi
f0105bcb:	5d                   	pop    %ebp
f0105bcc:	c3                   	ret    
f0105bcd:	66 90                	xchg   %ax,%ax
f0105bcf:	90                   	nop

f0105bd0 <__udivdi3>:
f0105bd0:	55                   	push   %ebp
f0105bd1:	57                   	push   %edi
f0105bd2:	56                   	push   %esi
f0105bd3:	53                   	push   %ebx
f0105bd4:	83 ec 1c             	sub    $0x1c,%esp
f0105bd7:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f0105bdb:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f0105bdf:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0105be3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0105be7:	85 f6                	test   %esi,%esi
f0105be9:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0105bed:	89 ca                	mov    %ecx,%edx
f0105bef:	89 f8                	mov    %edi,%eax
f0105bf1:	75 3d                	jne    f0105c30 <__udivdi3+0x60>
f0105bf3:	39 cf                	cmp    %ecx,%edi
f0105bf5:	0f 87 c5 00 00 00    	ja     f0105cc0 <__udivdi3+0xf0>
f0105bfb:	85 ff                	test   %edi,%edi
f0105bfd:	89 fd                	mov    %edi,%ebp
f0105bff:	75 0b                	jne    f0105c0c <__udivdi3+0x3c>
f0105c01:	b8 01 00 00 00       	mov    $0x1,%eax
f0105c06:	31 d2                	xor    %edx,%edx
f0105c08:	f7 f7                	div    %edi
f0105c0a:	89 c5                	mov    %eax,%ebp
f0105c0c:	89 c8                	mov    %ecx,%eax
f0105c0e:	31 d2                	xor    %edx,%edx
f0105c10:	f7 f5                	div    %ebp
f0105c12:	89 c1                	mov    %eax,%ecx
f0105c14:	89 d8                	mov    %ebx,%eax
f0105c16:	89 cf                	mov    %ecx,%edi
f0105c18:	f7 f5                	div    %ebp
f0105c1a:	89 c3                	mov    %eax,%ebx
f0105c1c:	89 d8                	mov    %ebx,%eax
f0105c1e:	89 fa                	mov    %edi,%edx
f0105c20:	83 c4 1c             	add    $0x1c,%esp
f0105c23:	5b                   	pop    %ebx
f0105c24:	5e                   	pop    %esi
f0105c25:	5f                   	pop    %edi
f0105c26:	5d                   	pop    %ebp
f0105c27:	c3                   	ret    
f0105c28:	90                   	nop
f0105c29:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0105c30:	39 ce                	cmp    %ecx,%esi
f0105c32:	77 74                	ja     f0105ca8 <__udivdi3+0xd8>
f0105c34:	0f bd fe             	bsr    %esi,%edi
f0105c37:	83 f7 1f             	xor    $0x1f,%edi
f0105c3a:	0f 84 98 00 00 00    	je     f0105cd8 <__udivdi3+0x108>
f0105c40:	bb 20 00 00 00       	mov    $0x20,%ebx
f0105c45:	89 f9                	mov    %edi,%ecx
f0105c47:	89 c5                	mov    %eax,%ebp
f0105c49:	29 fb                	sub    %edi,%ebx
f0105c4b:	d3 e6                	shl    %cl,%esi
f0105c4d:	89 d9                	mov    %ebx,%ecx
f0105c4f:	d3 ed                	shr    %cl,%ebp
f0105c51:	89 f9                	mov    %edi,%ecx
f0105c53:	d3 e0                	shl    %cl,%eax
f0105c55:	09 ee                	or     %ebp,%esi
f0105c57:	89 d9                	mov    %ebx,%ecx
f0105c59:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0105c5d:	89 d5                	mov    %edx,%ebp
f0105c5f:	8b 44 24 08          	mov    0x8(%esp),%eax
f0105c63:	d3 ed                	shr    %cl,%ebp
f0105c65:	89 f9                	mov    %edi,%ecx
f0105c67:	d3 e2                	shl    %cl,%edx
f0105c69:	89 d9                	mov    %ebx,%ecx
f0105c6b:	d3 e8                	shr    %cl,%eax
f0105c6d:	09 c2                	or     %eax,%edx
f0105c6f:	89 d0                	mov    %edx,%eax
f0105c71:	89 ea                	mov    %ebp,%edx
f0105c73:	f7 f6                	div    %esi
f0105c75:	89 d5                	mov    %edx,%ebp
f0105c77:	89 c3                	mov    %eax,%ebx
f0105c79:	f7 64 24 0c          	mull   0xc(%esp)
f0105c7d:	39 d5                	cmp    %edx,%ebp
f0105c7f:	72 10                	jb     f0105c91 <__udivdi3+0xc1>
f0105c81:	8b 74 24 08          	mov    0x8(%esp),%esi
f0105c85:	89 f9                	mov    %edi,%ecx
f0105c87:	d3 e6                	shl    %cl,%esi
f0105c89:	39 c6                	cmp    %eax,%esi
f0105c8b:	73 07                	jae    f0105c94 <__udivdi3+0xc4>
f0105c8d:	39 d5                	cmp    %edx,%ebp
f0105c8f:	75 03                	jne    f0105c94 <__udivdi3+0xc4>
f0105c91:	83 eb 01             	sub    $0x1,%ebx
f0105c94:	31 ff                	xor    %edi,%edi
f0105c96:	89 d8                	mov    %ebx,%eax
f0105c98:	89 fa                	mov    %edi,%edx
f0105c9a:	83 c4 1c             	add    $0x1c,%esp
f0105c9d:	5b                   	pop    %ebx
f0105c9e:	5e                   	pop    %esi
f0105c9f:	5f                   	pop    %edi
f0105ca0:	5d                   	pop    %ebp
f0105ca1:	c3                   	ret    
f0105ca2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0105ca8:	31 ff                	xor    %edi,%edi
f0105caa:	31 db                	xor    %ebx,%ebx
f0105cac:	89 d8                	mov    %ebx,%eax
f0105cae:	89 fa                	mov    %edi,%edx
f0105cb0:	83 c4 1c             	add    $0x1c,%esp
f0105cb3:	5b                   	pop    %ebx
f0105cb4:	5e                   	pop    %esi
f0105cb5:	5f                   	pop    %edi
f0105cb6:	5d                   	pop    %ebp
f0105cb7:	c3                   	ret    
f0105cb8:	90                   	nop
f0105cb9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0105cc0:	89 d8                	mov    %ebx,%eax
f0105cc2:	f7 f7                	div    %edi
f0105cc4:	31 ff                	xor    %edi,%edi
f0105cc6:	89 c3                	mov    %eax,%ebx
f0105cc8:	89 d8                	mov    %ebx,%eax
f0105cca:	89 fa                	mov    %edi,%edx
f0105ccc:	83 c4 1c             	add    $0x1c,%esp
f0105ccf:	5b                   	pop    %ebx
f0105cd0:	5e                   	pop    %esi
f0105cd1:	5f                   	pop    %edi
f0105cd2:	5d                   	pop    %ebp
f0105cd3:	c3                   	ret    
f0105cd4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0105cd8:	39 ce                	cmp    %ecx,%esi
f0105cda:	72 0c                	jb     f0105ce8 <__udivdi3+0x118>
f0105cdc:	31 db                	xor    %ebx,%ebx
f0105cde:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0105ce2:	0f 87 34 ff ff ff    	ja     f0105c1c <__udivdi3+0x4c>
f0105ce8:	bb 01 00 00 00       	mov    $0x1,%ebx
f0105ced:	e9 2a ff ff ff       	jmp    f0105c1c <__udivdi3+0x4c>
f0105cf2:	66 90                	xchg   %ax,%ax
f0105cf4:	66 90                	xchg   %ax,%ax
f0105cf6:	66 90                	xchg   %ax,%ax
f0105cf8:	66 90                	xchg   %ax,%ax
f0105cfa:	66 90                	xchg   %ax,%ax
f0105cfc:	66 90                	xchg   %ax,%ax
f0105cfe:	66 90                	xchg   %ax,%ax

f0105d00 <__umoddi3>:
f0105d00:	55                   	push   %ebp
f0105d01:	57                   	push   %edi
f0105d02:	56                   	push   %esi
f0105d03:	53                   	push   %ebx
f0105d04:	83 ec 1c             	sub    $0x1c,%esp
f0105d07:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f0105d0b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f0105d0f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0105d13:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0105d17:	85 d2                	test   %edx,%edx
f0105d19:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0105d1d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0105d21:	89 f3                	mov    %esi,%ebx
f0105d23:	89 3c 24             	mov    %edi,(%esp)
f0105d26:	89 74 24 04          	mov    %esi,0x4(%esp)
f0105d2a:	75 1c                	jne    f0105d48 <__umoddi3+0x48>
f0105d2c:	39 f7                	cmp    %esi,%edi
f0105d2e:	76 50                	jbe    f0105d80 <__umoddi3+0x80>
f0105d30:	89 c8                	mov    %ecx,%eax
f0105d32:	89 f2                	mov    %esi,%edx
f0105d34:	f7 f7                	div    %edi
f0105d36:	89 d0                	mov    %edx,%eax
f0105d38:	31 d2                	xor    %edx,%edx
f0105d3a:	83 c4 1c             	add    $0x1c,%esp
f0105d3d:	5b                   	pop    %ebx
f0105d3e:	5e                   	pop    %esi
f0105d3f:	5f                   	pop    %edi
f0105d40:	5d                   	pop    %ebp
f0105d41:	c3                   	ret    
f0105d42:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0105d48:	39 f2                	cmp    %esi,%edx
f0105d4a:	89 d0                	mov    %edx,%eax
f0105d4c:	77 52                	ja     f0105da0 <__umoddi3+0xa0>
f0105d4e:	0f bd ea             	bsr    %edx,%ebp
f0105d51:	83 f5 1f             	xor    $0x1f,%ebp
f0105d54:	75 5a                	jne    f0105db0 <__umoddi3+0xb0>
f0105d56:	3b 54 24 04          	cmp    0x4(%esp),%edx
f0105d5a:	0f 82 e0 00 00 00    	jb     f0105e40 <__umoddi3+0x140>
f0105d60:	39 0c 24             	cmp    %ecx,(%esp)
f0105d63:	0f 86 d7 00 00 00    	jbe    f0105e40 <__umoddi3+0x140>
f0105d69:	8b 44 24 08          	mov    0x8(%esp),%eax
f0105d6d:	8b 54 24 04          	mov    0x4(%esp),%edx
f0105d71:	83 c4 1c             	add    $0x1c,%esp
f0105d74:	5b                   	pop    %ebx
f0105d75:	5e                   	pop    %esi
f0105d76:	5f                   	pop    %edi
f0105d77:	5d                   	pop    %ebp
f0105d78:	c3                   	ret    
f0105d79:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0105d80:	85 ff                	test   %edi,%edi
f0105d82:	89 fd                	mov    %edi,%ebp
f0105d84:	75 0b                	jne    f0105d91 <__umoddi3+0x91>
f0105d86:	b8 01 00 00 00       	mov    $0x1,%eax
f0105d8b:	31 d2                	xor    %edx,%edx
f0105d8d:	f7 f7                	div    %edi
f0105d8f:	89 c5                	mov    %eax,%ebp
f0105d91:	89 f0                	mov    %esi,%eax
f0105d93:	31 d2                	xor    %edx,%edx
f0105d95:	f7 f5                	div    %ebp
f0105d97:	89 c8                	mov    %ecx,%eax
f0105d99:	f7 f5                	div    %ebp
f0105d9b:	89 d0                	mov    %edx,%eax
f0105d9d:	eb 99                	jmp    f0105d38 <__umoddi3+0x38>
f0105d9f:	90                   	nop
f0105da0:	89 c8                	mov    %ecx,%eax
f0105da2:	89 f2                	mov    %esi,%edx
f0105da4:	83 c4 1c             	add    $0x1c,%esp
f0105da7:	5b                   	pop    %ebx
f0105da8:	5e                   	pop    %esi
f0105da9:	5f                   	pop    %edi
f0105daa:	5d                   	pop    %ebp
f0105dab:	c3                   	ret    
f0105dac:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0105db0:	8b 34 24             	mov    (%esp),%esi
f0105db3:	bf 20 00 00 00       	mov    $0x20,%edi
f0105db8:	89 e9                	mov    %ebp,%ecx
f0105dba:	29 ef                	sub    %ebp,%edi
f0105dbc:	d3 e0                	shl    %cl,%eax
f0105dbe:	89 f9                	mov    %edi,%ecx
f0105dc0:	89 f2                	mov    %esi,%edx
f0105dc2:	d3 ea                	shr    %cl,%edx
f0105dc4:	89 e9                	mov    %ebp,%ecx
f0105dc6:	09 c2                	or     %eax,%edx
f0105dc8:	89 d8                	mov    %ebx,%eax
f0105dca:	89 14 24             	mov    %edx,(%esp)
f0105dcd:	89 f2                	mov    %esi,%edx
f0105dcf:	d3 e2                	shl    %cl,%edx
f0105dd1:	89 f9                	mov    %edi,%ecx
f0105dd3:	89 54 24 04          	mov    %edx,0x4(%esp)
f0105dd7:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0105ddb:	d3 e8                	shr    %cl,%eax
f0105ddd:	89 e9                	mov    %ebp,%ecx
f0105ddf:	89 c6                	mov    %eax,%esi
f0105de1:	d3 e3                	shl    %cl,%ebx
f0105de3:	89 f9                	mov    %edi,%ecx
f0105de5:	89 d0                	mov    %edx,%eax
f0105de7:	d3 e8                	shr    %cl,%eax
f0105de9:	89 e9                	mov    %ebp,%ecx
f0105deb:	09 d8                	or     %ebx,%eax
f0105ded:	89 d3                	mov    %edx,%ebx
f0105def:	89 f2                	mov    %esi,%edx
f0105df1:	f7 34 24             	divl   (%esp)
f0105df4:	89 d6                	mov    %edx,%esi
f0105df6:	d3 e3                	shl    %cl,%ebx
f0105df8:	f7 64 24 04          	mull   0x4(%esp)
f0105dfc:	39 d6                	cmp    %edx,%esi
f0105dfe:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0105e02:	89 d1                	mov    %edx,%ecx
f0105e04:	89 c3                	mov    %eax,%ebx
f0105e06:	72 08                	jb     f0105e10 <__umoddi3+0x110>
f0105e08:	75 11                	jne    f0105e1b <__umoddi3+0x11b>
f0105e0a:	39 44 24 08          	cmp    %eax,0x8(%esp)
f0105e0e:	73 0b                	jae    f0105e1b <__umoddi3+0x11b>
f0105e10:	2b 44 24 04          	sub    0x4(%esp),%eax
f0105e14:	1b 14 24             	sbb    (%esp),%edx
f0105e17:	89 d1                	mov    %edx,%ecx
f0105e19:	89 c3                	mov    %eax,%ebx
f0105e1b:	8b 54 24 08          	mov    0x8(%esp),%edx
f0105e1f:	29 da                	sub    %ebx,%edx
f0105e21:	19 ce                	sbb    %ecx,%esi
f0105e23:	89 f9                	mov    %edi,%ecx
f0105e25:	89 f0                	mov    %esi,%eax
f0105e27:	d3 e0                	shl    %cl,%eax
f0105e29:	89 e9                	mov    %ebp,%ecx
f0105e2b:	d3 ea                	shr    %cl,%edx
f0105e2d:	89 e9                	mov    %ebp,%ecx
f0105e2f:	d3 ee                	shr    %cl,%esi
f0105e31:	09 d0                	or     %edx,%eax
f0105e33:	89 f2                	mov    %esi,%edx
f0105e35:	83 c4 1c             	add    $0x1c,%esp
f0105e38:	5b                   	pop    %ebx
f0105e39:	5e                   	pop    %esi
f0105e3a:	5f                   	pop    %edi
f0105e3b:	5d                   	pop    %ebp
f0105e3c:	c3                   	ret    
f0105e3d:	8d 76 00             	lea    0x0(%esi),%esi
f0105e40:	29 f9                	sub    %edi,%ecx
f0105e42:	19 d6                	sbb    %edx,%esi
f0105e44:	89 74 24 04          	mov    %esi,0x4(%esp)
f0105e48:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0105e4c:	e9 18 ff ff ff       	jmp    f0105d69 <__umoddi3+0x69>
