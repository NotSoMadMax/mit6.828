
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
f0100048:	83 3d 80 1e 21 f0 00 	cmpl   $0x0,0xf0211e80
f010004f:	75 3a                	jne    f010008b <_panic+0x4b>
		goto dead;
	panicstr = fmt;
f0100051:	89 35 80 1e 21 f0    	mov    %esi,0xf0211e80

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f0100057:	fa                   	cli    
f0100058:	fc                   	cld    

	va_start(ap, fmt);
f0100059:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic on CPU %d at %s:%d: ", cpunum(), file, line);
f010005c:	e8 75 59 00 00       	call   f01059d6 <cpunum>
f0100061:	ff 75 0c             	pushl  0xc(%ebp)
f0100064:	ff 75 08             	pushl  0x8(%ebp)
f0100067:	50                   	push   %eax
f0100068:	68 60 60 10 f0       	push   $0xf0106060
f010006d:	e8 bc 35 00 00       	call   f010362e <cprintf>
	vcprintf(fmt, ap);
f0100072:	83 c4 08             	add    $0x8,%esp
f0100075:	53                   	push   %ebx
f0100076:	56                   	push   %esi
f0100077:	e8 8c 35 00 00       	call   f0103608 <vcprintf>
	cprintf("\n");
f010007c:	c7 04 24 44 72 10 f0 	movl   $0xf0107244,(%esp)
f0100083:	e8 a6 35 00 00       	call   f010362e <cprintf>
	va_end(ap);
f0100088:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f010008b:	83 ec 0c             	sub    $0xc,%esp
f010008e:	6a 00                	push   $0x0
f0100090:	e8 91 08 00 00       	call   f0100926 <monitor>
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
f01000a1:	b8 08 30 25 f0       	mov    $0xf0253008,%eax
f01000a6:	2d 7c 09 21 f0       	sub    $0xf021097c,%eax
f01000ab:	50                   	push   %eax
f01000ac:	6a 00                	push   $0x0
f01000ae:	68 7c 09 21 f0       	push   $0xf021097c
f01000b3:	e8 fb 52 00 00       	call   f01053b3 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000b8:	e8 96 05 00 00       	call   f0100653 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000bd:	83 c4 08             	add    $0x8,%esp
f01000c0:	68 ac 1a 00 00       	push   $0x1aac
f01000c5:	68 cc 60 10 f0       	push   $0xf01060cc
f01000ca:	e8 5f 35 00 00       	call   f010362e <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f01000cf:	e8 48 12 00 00       	call   f010131c <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f01000d4:	e8 23 2e 00 00       	call   f0102efc <env_init>
	trap_init();
f01000d9:	e8 31 36 00 00       	call   f010370f <trap_init>

	// Lab 4 multiprocessor initialization functions
	mp_init();
f01000de:	e8 e9 55 00 00       	call   f01056cc <mp_init>
	lapic_init();
f01000e3:	e8 09 59 00 00       	call   f01059f1 <lapic_init>

	// Lab 4 multitasking initialization functions
	pic_init();
f01000e8:	e8 68 34 00 00       	call   f0103555 <pic_init>
extern struct spinlock kernel_lock;

static inline void
lock_kernel(void)
{
	spin_lock(&kernel_lock);
f01000ed:	c7 04 24 c0 03 12 f0 	movl   $0xf01203c0,(%esp)
f01000f4:	e8 4b 5b 00 00       	call   f0105c44 <spin_lock>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01000f9:	83 c4 10             	add    $0x10,%esp
f01000fc:	83 3d 88 1e 21 f0 07 	cmpl   $0x7,0xf0211e88
f0100103:	77 16                	ja     f010011b <i386_init+0x81>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100105:	68 00 70 00 00       	push   $0x7000
f010010a:	68 84 60 10 f0       	push   $0xf0106084
f010010f:	6a 59                	push   $0x59
f0100111:	68 e7 60 10 f0       	push   $0xf01060e7
f0100116:	e8 25 ff ff ff       	call   f0100040 <_panic>
	void *code;
	struct CpuInfo *c;

	// Write entry code to unused memory at MPENTRY_PADDR
	code = KADDR(MPENTRY_PADDR);
	memmove(code, mpentry_start, mpentry_end - mpentry_start);
f010011b:	83 ec 04             	sub    $0x4,%esp
f010011e:	b8 32 56 10 f0       	mov    $0xf0105632,%eax
f0100123:	2d b8 55 10 f0       	sub    $0xf01055b8,%eax
f0100128:	50                   	push   %eax
f0100129:	68 b8 55 10 f0       	push   $0xf01055b8
f010012e:	68 00 70 00 f0       	push   $0xf0007000
f0100133:	e8 c8 52 00 00       	call   f0105400 <memmove>
f0100138:	83 c4 10             	add    $0x10,%esp

	// Boot each AP one at a time
	for (c = cpus; c < cpus + ncpu; c++) {
f010013b:	bb 20 20 21 f0       	mov    $0xf0212020,%ebx
f0100140:	eb 4d                	jmp    f010018f <i386_init+0xf5>
		if (c == cpus + cpunum())  // We've started already.
f0100142:	e8 8f 58 00 00       	call   f01059d6 <cpunum>
f0100147:	6b c0 74             	imul   $0x74,%eax,%eax
f010014a:	05 20 20 21 f0       	add    $0xf0212020,%eax
f010014f:	39 c3                	cmp    %eax,%ebx
f0100151:	74 39                	je     f010018c <i386_init+0xf2>
			continue;

		// Tell mpentry.S what stack to use 
		mpentry_kstack = percpu_kstacks[c - cpus] + KSTKSIZE;
f0100153:	89 d8                	mov    %ebx,%eax
f0100155:	2d 20 20 21 f0       	sub    $0xf0212020,%eax
f010015a:	c1 f8 02             	sar    $0x2,%eax
f010015d:	69 c0 35 c2 72 4f    	imul   $0x4f72c235,%eax,%eax
f0100163:	c1 e0 0f             	shl    $0xf,%eax
f0100166:	05 00 b0 21 f0       	add    $0xf021b000,%eax
f010016b:	a3 84 1e 21 f0       	mov    %eax,0xf0211e84
		// Start the CPU at mpentry_start
		lapic_startap(c->cpu_id, PADDR(code));
f0100170:	83 ec 08             	sub    $0x8,%esp
f0100173:	68 00 70 00 00       	push   $0x7000
f0100178:	0f b6 03             	movzbl (%ebx),%eax
f010017b:	50                   	push   %eax
f010017c:	e8 be 59 00 00       	call   f0105b3f <lapic_startap>
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
f010018f:	6b 05 c4 23 21 f0 74 	imul   $0x74,0xf02123c4,%eax
f0100196:	05 20 20 21 f0       	add    $0xf0212020,%eax
f010019b:	39 c3                	cmp    %eax,%ebx
f010019d:	72 a3                	jb     f0100142 <i386_init+0xa8>
    lock_kernel();
	// Starting non-boot CPUs
	boot_aps();

	// Start fs.
	ENV_CREATE(fs_fs, ENV_TYPE_FS);
f010019f:	83 ec 08             	sub    $0x8,%esp
f01001a2:	6a 01                	push   $0x1
f01001a4:	68 08 0c 1d f0       	push   $0xf01d0c08
f01001a9:	e8 eb 2e 00 00       	call   f0103099 <env_create>

#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
f01001ae:	83 c4 08             	add    $0x8,%esp
f01001b1:	6a 00                	push   $0x0
f01001b3:	68 28 6f 1c f0       	push   $0xf01c6f28
f01001b8:	e8 dc 2e 00 00       	call   f0103099 <env_create>
	// Touch all you want.
	ENV_CREATE(user_icode, ENV_TYPE_USER);
#endif // TEST*

	// Should not be necessary - drains keyboard because interrupt has given up.
	kbd_intr();
f01001bd:	e8 35 04 00 00       	call   f01005f7 <kbd_intr>

	// Schedule and run the first user environment!
	sched_yield();
f01001c2:	e8 44 40 00 00       	call   f010420b <sched_yield>

f01001c7 <mp_main>:
}

// Setup code for APs
void
mp_main(void)
{
f01001c7:	55                   	push   %ebp
f01001c8:	89 e5                	mov    %esp,%ebp
f01001ca:	83 ec 08             	sub    $0x8,%esp
	// We are in high EIP now, safe to switch to kern_pgdir 
	lcr3(PADDR(kern_pgdir));
f01001cd:	a1 8c 1e 21 f0       	mov    0xf0211e8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01001d2:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01001d7:	77 12                	ja     f01001eb <mp_main+0x24>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01001d9:	50                   	push   %eax
f01001da:	68 a8 60 10 f0       	push   $0xf01060a8
f01001df:	6a 70                	push   $0x70
f01001e1:	68 e7 60 10 f0       	push   $0xf01060e7
f01001e6:	e8 55 fe ff ff       	call   f0100040 <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f01001eb:	05 00 00 00 10       	add    $0x10000000,%eax
f01001f0:	0f 22 d8             	mov    %eax,%cr3
	cprintf("SMP: CPU %d starting\n", cpunum());
f01001f3:	e8 de 57 00 00       	call   f01059d6 <cpunum>
f01001f8:	83 ec 08             	sub    $0x8,%esp
f01001fb:	50                   	push   %eax
f01001fc:	68 f3 60 10 f0       	push   $0xf01060f3
f0100201:	e8 28 34 00 00       	call   f010362e <cprintf>

	lapic_init();
f0100206:	e8 e6 57 00 00       	call   f01059f1 <lapic_init>
	env_init_percpu();
f010020b:	e8 bc 2c 00 00       	call   f0102ecc <env_init_percpu>
	trap_init_percpu();
f0100210:	e8 2d 34 00 00       	call   f0103642 <trap_init_percpu>
	xchg(&thiscpu->cpu_status, CPU_STARTED); // tell boot_aps() we're up
f0100215:	e8 bc 57 00 00       	call   f01059d6 <cpunum>
f010021a:	6b d0 74             	imul   $0x74,%eax,%edx
f010021d:	81 c2 20 20 21 f0    	add    $0xf0212020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"
f0100223:	b8 01 00 00 00       	mov    $0x1,%eax
f0100228:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
f010022c:	c7 04 24 c0 03 12 f0 	movl   $0xf01203c0,(%esp)
f0100233:	e8 0c 5a 00 00       	call   f0105c44 <spin_lock>
	// only one CPU can enter the scheduler at a time!
	//
	// Your code here:

    lock_kernel();
    sched_yield();
f0100238:	e8 ce 3f 00 00       	call   f010420b <sched_yield>

f010023d <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f010023d:	55                   	push   %ebp
f010023e:	89 e5                	mov    %esp,%ebp
f0100240:	53                   	push   %ebx
f0100241:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100244:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100247:	ff 75 0c             	pushl  0xc(%ebp)
f010024a:	ff 75 08             	pushl  0x8(%ebp)
f010024d:	68 09 61 10 f0       	push   $0xf0106109
f0100252:	e8 d7 33 00 00       	call   f010362e <cprintf>
	vcprintf(fmt, ap);
f0100257:	83 c4 08             	add    $0x8,%esp
f010025a:	53                   	push   %ebx
f010025b:	ff 75 10             	pushl  0x10(%ebp)
f010025e:	e8 a5 33 00 00       	call   f0103608 <vcprintf>
	cprintf("\n");
f0100263:	c7 04 24 44 72 10 f0 	movl   $0xf0107244,(%esp)
f010026a:	e8 bf 33 00 00       	call   f010362e <cprintf>
	va_end(ap);
}
f010026f:	83 c4 10             	add    $0x10,%esp
f0100272:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100275:	c9                   	leave  
f0100276:	c3                   	ret    

f0100277 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100277:	55                   	push   %ebp
f0100278:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010027a:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010027f:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100280:	a8 01                	test   $0x1,%al
f0100282:	74 0b                	je     f010028f <serial_proc_data+0x18>
f0100284:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100289:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f010028a:	0f b6 c0             	movzbl %al,%eax
f010028d:	eb 05                	jmp    f0100294 <serial_proc_data+0x1d>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f010028f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f0100294:	5d                   	pop    %ebp
f0100295:	c3                   	ret    

f0100296 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f0100296:	55                   	push   %ebp
f0100297:	89 e5                	mov    %esp,%ebp
f0100299:	53                   	push   %ebx
f010029a:	83 ec 04             	sub    $0x4,%esp
f010029d:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f010029f:	eb 2b                	jmp    f01002cc <cons_intr+0x36>
		if (c == 0)
f01002a1:	85 c0                	test   %eax,%eax
f01002a3:	74 27                	je     f01002cc <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f01002a5:	8b 0d 24 12 21 f0    	mov    0xf0211224,%ecx
f01002ab:	8d 51 01             	lea    0x1(%ecx),%edx
f01002ae:	89 15 24 12 21 f0    	mov    %edx,0xf0211224
f01002b4:	88 81 20 10 21 f0    	mov    %al,-0xfdeefe0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f01002ba:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01002c0:	75 0a                	jne    f01002cc <cons_intr+0x36>
			cons.wpos = 0;
f01002c2:	c7 05 24 12 21 f0 00 	movl   $0x0,0xf0211224
f01002c9:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01002cc:	ff d3                	call   *%ebx
f01002ce:	83 f8 ff             	cmp    $0xffffffff,%eax
f01002d1:	75 ce                	jne    f01002a1 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01002d3:	83 c4 04             	add    $0x4,%esp
f01002d6:	5b                   	pop    %ebx
f01002d7:	5d                   	pop    %ebp
f01002d8:	c3                   	ret    

f01002d9 <kbd_proc_data>:
f01002d9:	ba 64 00 00 00       	mov    $0x64,%edx
f01002de:	ec                   	in     (%dx),%al
	int c;
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
f01002df:	a8 01                	test   $0x1,%al
f01002e1:	0f 84 f8 00 00 00    	je     f01003df <kbd_proc_data+0x106>
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
f01002e7:	a8 20                	test   $0x20,%al
f01002e9:	0f 85 f6 00 00 00    	jne    f01003e5 <kbd_proc_data+0x10c>
f01002ef:	ba 60 00 00 00       	mov    $0x60,%edx
f01002f4:	ec                   	in     (%dx),%al
f01002f5:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01002f7:	3c e0                	cmp    $0xe0,%al
f01002f9:	75 0d                	jne    f0100308 <kbd_proc_data+0x2f>
		// E0 escape character
		shift |= E0ESC;
f01002fb:	83 0d 00 10 21 f0 40 	orl    $0x40,0xf0211000
		return 0;
f0100302:	b8 00 00 00 00       	mov    $0x0,%eax
f0100307:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f0100308:	55                   	push   %ebp
f0100309:	89 e5                	mov    %esp,%ebp
f010030b:	53                   	push   %ebx
f010030c:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f010030f:	84 c0                	test   %al,%al
f0100311:	79 36                	jns    f0100349 <kbd_proc_data+0x70>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f0100313:	8b 0d 00 10 21 f0    	mov    0xf0211000,%ecx
f0100319:	89 cb                	mov    %ecx,%ebx
f010031b:	83 e3 40             	and    $0x40,%ebx
f010031e:	83 e0 7f             	and    $0x7f,%eax
f0100321:	85 db                	test   %ebx,%ebx
f0100323:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100326:	0f b6 d2             	movzbl %dl,%edx
f0100329:	0f b6 82 80 62 10 f0 	movzbl -0xfef9d80(%edx),%eax
f0100330:	83 c8 40             	or     $0x40,%eax
f0100333:	0f b6 c0             	movzbl %al,%eax
f0100336:	f7 d0                	not    %eax
f0100338:	21 c8                	and    %ecx,%eax
f010033a:	a3 00 10 21 f0       	mov    %eax,0xf0211000
		return 0;
f010033f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100344:	e9 a4 00 00 00       	jmp    f01003ed <kbd_proc_data+0x114>
	} else if (shift & E0ESC) {
f0100349:	8b 0d 00 10 21 f0    	mov    0xf0211000,%ecx
f010034f:	f6 c1 40             	test   $0x40,%cl
f0100352:	74 0e                	je     f0100362 <kbd_proc_data+0x89>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100354:	83 c8 80             	or     $0xffffff80,%eax
f0100357:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100359:	83 e1 bf             	and    $0xffffffbf,%ecx
f010035c:	89 0d 00 10 21 f0    	mov    %ecx,0xf0211000
	}

	shift |= shiftcode[data];
f0100362:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f0100365:	0f b6 82 80 62 10 f0 	movzbl -0xfef9d80(%edx),%eax
f010036c:	0b 05 00 10 21 f0    	or     0xf0211000,%eax
f0100372:	0f b6 8a 80 61 10 f0 	movzbl -0xfef9e80(%edx),%ecx
f0100379:	31 c8                	xor    %ecx,%eax
f010037b:	a3 00 10 21 f0       	mov    %eax,0xf0211000

	c = charcode[shift & (CTL | SHIFT)][data];
f0100380:	89 c1                	mov    %eax,%ecx
f0100382:	83 e1 03             	and    $0x3,%ecx
f0100385:	8b 0c 8d 60 61 10 f0 	mov    -0xfef9ea0(,%ecx,4),%ecx
f010038c:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0100390:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100393:	a8 08                	test   $0x8,%al
f0100395:	74 1b                	je     f01003b2 <kbd_proc_data+0xd9>
		if ('a' <= c && c <= 'z')
f0100397:	89 da                	mov    %ebx,%edx
f0100399:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f010039c:	83 f9 19             	cmp    $0x19,%ecx
f010039f:	77 05                	ja     f01003a6 <kbd_proc_data+0xcd>
			c += 'A' - 'a';
f01003a1:	83 eb 20             	sub    $0x20,%ebx
f01003a4:	eb 0c                	jmp    f01003b2 <kbd_proc_data+0xd9>
		else if ('A' <= c && c <= 'Z')
f01003a6:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f01003a9:	8d 4b 20             	lea    0x20(%ebx),%ecx
f01003ac:	83 fa 19             	cmp    $0x19,%edx
f01003af:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01003b2:	f7 d0                	not    %eax
f01003b4:	a8 06                	test   $0x6,%al
f01003b6:	75 33                	jne    f01003eb <kbd_proc_data+0x112>
f01003b8:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01003be:	75 2b                	jne    f01003eb <kbd_proc_data+0x112>
		cprintf("Rebooting!\n");
f01003c0:	83 ec 0c             	sub    $0xc,%esp
f01003c3:	68 23 61 10 f0       	push   $0xf0106123
f01003c8:	e8 61 32 00 00       	call   f010362e <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01003cd:	ba 92 00 00 00       	mov    $0x92,%edx
f01003d2:	b8 03 00 00 00       	mov    $0x3,%eax
f01003d7:	ee                   	out    %al,(%dx)
f01003d8:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01003db:	89 d8                	mov    %ebx,%eax
f01003dd:	eb 0e                	jmp    f01003ed <kbd_proc_data+0x114>
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
f01003df:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01003e4:	c3                   	ret    
	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
		return -1;
f01003e5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01003ea:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01003eb:	89 d8                	mov    %ebx,%eax
}
f01003ed:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01003f0:	c9                   	leave  
f01003f1:	c3                   	ret    

f01003f2 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01003f2:	55                   	push   %ebp
f01003f3:	89 e5                	mov    %esp,%ebp
f01003f5:	57                   	push   %edi
f01003f6:	56                   	push   %esi
f01003f7:	53                   	push   %ebx
f01003f8:	83 ec 1c             	sub    $0x1c,%esp
f01003fb:	89 c7                	mov    %eax,%edi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01003fd:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100402:	be fd 03 00 00       	mov    $0x3fd,%esi
f0100407:	b9 84 00 00 00       	mov    $0x84,%ecx
f010040c:	eb 09                	jmp    f0100417 <cons_putc+0x25>
f010040e:	89 ca                	mov    %ecx,%edx
f0100410:	ec                   	in     (%dx),%al
f0100411:	ec                   	in     (%dx),%al
f0100412:	ec                   	in     (%dx),%al
f0100413:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f0100414:	83 c3 01             	add    $0x1,%ebx
f0100417:	89 f2                	mov    %esi,%edx
f0100419:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f010041a:	a8 20                	test   $0x20,%al
f010041c:	75 08                	jne    f0100426 <cons_putc+0x34>
f010041e:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100424:	7e e8                	jle    f010040e <cons_putc+0x1c>
f0100426:	89 f8                	mov    %edi,%eax
f0100428:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010042b:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100430:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100431:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100436:	be 79 03 00 00       	mov    $0x379,%esi
f010043b:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100440:	eb 09                	jmp    f010044b <cons_putc+0x59>
f0100442:	89 ca                	mov    %ecx,%edx
f0100444:	ec                   	in     (%dx),%al
f0100445:	ec                   	in     (%dx),%al
f0100446:	ec                   	in     (%dx),%al
f0100447:	ec                   	in     (%dx),%al
f0100448:	83 c3 01             	add    $0x1,%ebx
f010044b:	89 f2                	mov    %esi,%edx
f010044d:	ec                   	in     (%dx),%al
f010044e:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100454:	7f 04                	jg     f010045a <cons_putc+0x68>
f0100456:	84 c0                	test   %al,%al
f0100458:	79 e8                	jns    f0100442 <cons_putc+0x50>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010045a:	ba 78 03 00 00       	mov    $0x378,%edx
f010045f:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f0100463:	ee                   	out    %al,(%dx)
f0100464:	ba 7a 03 00 00       	mov    $0x37a,%edx
f0100469:	b8 0d 00 00 00       	mov    $0xd,%eax
f010046e:	ee                   	out    %al,(%dx)
f010046f:	b8 08 00 00 00       	mov    $0x8,%eax
f0100474:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100475:	89 fa                	mov    %edi,%edx
f0100477:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f010047d:	89 f8                	mov    %edi,%eax
f010047f:	80 cc 07             	or     $0x7,%ah
f0100482:	85 d2                	test   %edx,%edx
f0100484:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100487:	89 f8                	mov    %edi,%eax
f0100489:	0f b6 c0             	movzbl %al,%eax
f010048c:	83 f8 09             	cmp    $0x9,%eax
f010048f:	74 74                	je     f0100505 <cons_putc+0x113>
f0100491:	83 f8 09             	cmp    $0x9,%eax
f0100494:	7f 0a                	jg     f01004a0 <cons_putc+0xae>
f0100496:	83 f8 08             	cmp    $0x8,%eax
f0100499:	74 14                	je     f01004af <cons_putc+0xbd>
f010049b:	e9 99 00 00 00       	jmp    f0100539 <cons_putc+0x147>
f01004a0:	83 f8 0a             	cmp    $0xa,%eax
f01004a3:	74 3a                	je     f01004df <cons_putc+0xed>
f01004a5:	83 f8 0d             	cmp    $0xd,%eax
f01004a8:	74 3d                	je     f01004e7 <cons_putc+0xf5>
f01004aa:	e9 8a 00 00 00       	jmp    f0100539 <cons_putc+0x147>
	case '\b':
		if (crt_pos > 0) {
f01004af:	0f b7 05 28 12 21 f0 	movzwl 0xf0211228,%eax
f01004b6:	66 85 c0             	test   %ax,%ax
f01004b9:	0f 84 e6 00 00 00    	je     f01005a5 <cons_putc+0x1b3>
			crt_pos--;
f01004bf:	83 e8 01             	sub    $0x1,%eax
f01004c2:	66 a3 28 12 21 f0    	mov    %ax,0xf0211228
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01004c8:	0f b7 c0             	movzwl %ax,%eax
f01004cb:	66 81 e7 00 ff       	and    $0xff00,%di
f01004d0:	83 cf 20             	or     $0x20,%edi
f01004d3:	8b 15 2c 12 21 f0    	mov    0xf021122c,%edx
f01004d9:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01004dd:	eb 78                	jmp    f0100557 <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01004df:	66 83 05 28 12 21 f0 	addw   $0x50,0xf0211228
f01004e6:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01004e7:	0f b7 05 28 12 21 f0 	movzwl 0xf0211228,%eax
f01004ee:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01004f4:	c1 e8 16             	shr    $0x16,%eax
f01004f7:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01004fa:	c1 e0 04             	shl    $0x4,%eax
f01004fd:	66 a3 28 12 21 f0    	mov    %ax,0xf0211228
f0100503:	eb 52                	jmp    f0100557 <cons_putc+0x165>
		break;
	case '\t':
		cons_putc(' ');
f0100505:	b8 20 00 00 00       	mov    $0x20,%eax
f010050a:	e8 e3 fe ff ff       	call   f01003f2 <cons_putc>
		cons_putc(' ');
f010050f:	b8 20 00 00 00       	mov    $0x20,%eax
f0100514:	e8 d9 fe ff ff       	call   f01003f2 <cons_putc>
		cons_putc(' ');
f0100519:	b8 20 00 00 00       	mov    $0x20,%eax
f010051e:	e8 cf fe ff ff       	call   f01003f2 <cons_putc>
		cons_putc(' ');
f0100523:	b8 20 00 00 00       	mov    $0x20,%eax
f0100528:	e8 c5 fe ff ff       	call   f01003f2 <cons_putc>
		cons_putc(' ');
f010052d:	b8 20 00 00 00       	mov    $0x20,%eax
f0100532:	e8 bb fe ff ff       	call   f01003f2 <cons_putc>
f0100537:	eb 1e                	jmp    f0100557 <cons_putc+0x165>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100539:	0f b7 05 28 12 21 f0 	movzwl 0xf0211228,%eax
f0100540:	8d 50 01             	lea    0x1(%eax),%edx
f0100543:	66 89 15 28 12 21 f0 	mov    %dx,0xf0211228
f010054a:	0f b7 c0             	movzwl %ax,%eax
f010054d:	8b 15 2c 12 21 f0    	mov    0xf021122c,%edx
f0100553:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100557:	66 81 3d 28 12 21 f0 	cmpw   $0x7cf,0xf0211228
f010055e:	cf 07 
f0100560:	76 43                	jbe    f01005a5 <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100562:	a1 2c 12 21 f0       	mov    0xf021122c,%eax
f0100567:	83 ec 04             	sub    $0x4,%esp
f010056a:	68 00 0f 00 00       	push   $0xf00
f010056f:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100575:	52                   	push   %edx
f0100576:	50                   	push   %eax
f0100577:	e8 84 4e 00 00       	call   f0105400 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f010057c:	8b 15 2c 12 21 f0    	mov    0xf021122c,%edx
f0100582:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f0100588:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f010058e:	83 c4 10             	add    $0x10,%esp
f0100591:	66 c7 00 20 07       	movw   $0x720,(%eax)
f0100596:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100599:	39 d0                	cmp    %edx,%eax
f010059b:	75 f4                	jne    f0100591 <cons_putc+0x19f>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f010059d:	66 83 2d 28 12 21 f0 	subw   $0x50,0xf0211228
f01005a4:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f01005a5:	8b 0d 30 12 21 f0    	mov    0xf0211230,%ecx
f01005ab:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005b0:	89 ca                	mov    %ecx,%edx
f01005b2:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01005b3:	0f b7 1d 28 12 21 f0 	movzwl 0xf0211228,%ebx
f01005ba:	8d 71 01             	lea    0x1(%ecx),%esi
f01005bd:	89 d8                	mov    %ebx,%eax
f01005bf:	66 c1 e8 08          	shr    $0x8,%ax
f01005c3:	89 f2                	mov    %esi,%edx
f01005c5:	ee                   	out    %al,(%dx)
f01005c6:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005cb:	89 ca                	mov    %ecx,%edx
f01005cd:	ee                   	out    %al,(%dx)
f01005ce:	89 d8                	mov    %ebx,%eax
f01005d0:	89 f2                	mov    %esi,%edx
f01005d2:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01005d3:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01005d6:	5b                   	pop    %ebx
f01005d7:	5e                   	pop    %esi
f01005d8:	5f                   	pop    %edi
f01005d9:	5d                   	pop    %ebp
f01005da:	c3                   	ret    

f01005db <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01005db:	80 3d 34 12 21 f0 00 	cmpb   $0x0,0xf0211234
f01005e2:	74 11                	je     f01005f5 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01005e4:	55                   	push   %ebp
f01005e5:	89 e5                	mov    %esp,%ebp
f01005e7:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f01005ea:	b8 77 02 10 f0       	mov    $0xf0100277,%eax
f01005ef:	e8 a2 fc ff ff       	call   f0100296 <cons_intr>
}
f01005f4:	c9                   	leave  
f01005f5:	f3 c3                	repz ret 

f01005f7 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01005f7:	55                   	push   %ebp
f01005f8:	89 e5                	mov    %esp,%ebp
f01005fa:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01005fd:	b8 d9 02 10 f0       	mov    $0xf01002d9,%eax
f0100602:	e8 8f fc ff ff       	call   f0100296 <cons_intr>
}
f0100607:	c9                   	leave  
f0100608:	c3                   	ret    

f0100609 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f0100609:	55                   	push   %ebp
f010060a:	89 e5                	mov    %esp,%ebp
f010060c:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f010060f:	e8 c7 ff ff ff       	call   f01005db <serial_intr>
	kbd_intr();
f0100614:	e8 de ff ff ff       	call   f01005f7 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100619:	a1 20 12 21 f0       	mov    0xf0211220,%eax
f010061e:	3b 05 24 12 21 f0    	cmp    0xf0211224,%eax
f0100624:	74 26                	je     f010064c <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f0100626:	8d 50 01             	lea    0x1(%eax),%edx
f0100629:	89 15 20 12 21 f0    	mov    %edx,0xf0211220
f010062f:	0f b6 88 20 10 21 f0 	movzbl -0xfdeefe0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f0100636:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f0100638:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010063e:	75 11                	jne    f0100651 <cons_getc+0x48>
			cons.rpos = 0;
f0100640:	c7 05 20 12 21 f0 00 	movl   $0x0,0xf0211220
f0100647:	00 00 00 
f010064a:	eb 05                	jmp    f0100651 <cons_getc+0x48>
		return c;
	}
	return 0;
f010064c:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100651:	c9                   	leave  
f0100652:	c3                   	ret    

f0100653 <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f0100653:	55                   	push   %ebp
f0100654:	89 e5                	mov    %esp,%ebp
f0100656:	57                   	push   %edi
f0100657:	56                   	push   %esi
f0100658:	53                   	push   %ebx
f0100659:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f010065c:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f0100663:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f010066a:	5a a5 
	if (*cp != 0xA55A) {
f010066c:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f0100673:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100677:	74 11                	je     f010068a <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100679:	c7 05 30 12 21 f0 b4 	movl   $0x3b4,0xf0211230
f0100680:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100683:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f0100688:	eb 16                	jmp    f01006a0 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f010068a:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100691:	c7 05 30 12 21 f0 d4 	movl   $0x3d4,0xf0211230
f0100698:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f010069b:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f01006a0:	8b 3d 30 12 21 f0    	mov    0xf0211230,%edi
f01006a6:	b8 0e 00 00 00       	mov    $0xe,%eax
f01006ab:	89 fa                	mov    %edi,%edx
f01006ad:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01006ae:	8d 5f 01             	lea    0x1(%edi),%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01006b1:	89 da                	mov    %ebx,%edx
f01006b3:	ec                   	in     (%dx),%al
f01006b4:	0f b6 c8             	movzbl %al,%ecx
f01006b7:	c1 e1 08             	shl    $0x8,%ecx
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01006ba:	b8 0f 00 00 00       	mov    $0xf,%eax
f01006bf:	89 fa                	mov    %edi,%edx
f01006c1:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01006c2:	89 da                	mov    %ebx,%edx
f01006c4:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01006c5:	89 35 2c 12 21 f0    	mov    %esi,0xf021122c
	crt_pos = pos;
f01006cb:	0f b6 c0             	movzbl %al,%eax
f01006ce:	09 c8                	or     %ecx,%eax
f01006d0:	66 a3 28 12 21 f0    	mov    %ax,0xf0211228

static void
kbd_init(void)
{
	// Drain the kbd buffer so that QEMU generates interrupts.
	kbd_intr();
f01006d6:	e8 1c ff ff ff       	call   f01005f7 <kbd_intr>
	irq_setmask_8259A(irq_mask_8259A & ~(1<<IRQ_KBD));
f01006db:	83 ec 0c             	sub    $0xc,%esp
f01006de:	0f b7 05 a8 03 12 f0 	movzwl 0xf01203a8,%eax
f01006e5:	25 fd ff 00 00       	and    $0xfffd,%eax
f01006ea:	50                   	push   %eax
f01006eb:	e8 ed 2d 00 00       	call   f01034dd <irq_setmask_8259A>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01006f0:	be fa 03 00 00       	mov    $0x3fa,%esi
f01006f5:	b8 00 00 00 00       	mov    $0x0,%eax
f01006fa:	89 f2                	mov    %esi,%edx
f01006fc:	ee                   	out    %al,(%dx)
f01006fd:	ba fb 03 00 00       	mov    $0x3fb,%edx
f0100702:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100707:	ee                   	out    %al,(%dx)
f0100708:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f010070d:	b8 0c 00 00 00       	mov    $0xc,%eax
f0100712:	89 da                	mov    %ebx,%edx
f0100714:	ee                   	out    %al,(%dx)
f0100715:	ba f9 03 00 00       	mov    $0x3f9,%edx
f010071a:	b8 00 00 00 00       	mov    $0x0,%eax
f010071f:	ee                   	out    %al,(%dx)
f0100720:	ba fb 03 00 00       	mov    $0x3fb,%edx
f0100725:	b8 03 00 00 00       	mov    $0x3,%eax
f010072a:	ee                   	out    %al,(%dx)
f010072b:	ba fc 03 00 00       	mov    $0x3fc,%edx
f0100730:	b8 00 00 00 00       	mov    $0x0,%eax
f0100735:	ee                   	out    %al,(%dx)
f0100736:	ba f9 03 00 00       	mov    $0x3f9,%edx
f010073b:	b8 01 00 00 00       	mov    $0x1,%eax
f0100740:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100741:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100746:	ec                   	in     (%dx),%al
f0100747:	89 c1                	mov    %eax,%ecx
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100749:	83 c4 10             	add    $0x10,%esp
f010074c:	3c ff                	cmp    $0xff,%al
f010074e:	0f 95 05 34 12 21 f0 	setne  0xf0211234
f0100755:	89 f2                	mov    %esi,%edx
f0100757:	ec                   	in     (%dx),%al
f0100758:	89 da                	mov    %ebx,%edx
f010075a:	ec                   	in     (%dx),%al
	(void) inb(COM1+COM_IIR);
	(void) inb(COM1+COM_RX);

	// Enable serial interrupts
	if (serial_exists)
f010075b:	80 f9 ff             	cmp    $0xff,%cl
f010075e:	74 21                	je     f0100781 <cons_init+0x12e>
		irq_setmask_8259A(irq_mask_8259A & ~(1<<IRQ_SERIAL));
f0100760:	83 ec 0c             	sub    $0xc,%esp
f0100763:	0f b7 05 a8 03 12 f0 	movzwl 0xf01203a8,%eax
f010076a:	25 ef ff 00 00       	and    $0xffef,%eax
f010076f:	50                   	push   %eax
f0100770:	e8 68 2d 00 00       	call   f01034dd <irq_setmask_8259A>
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100775:	83 c4 10             	add    $0x10,%esp
f0100778:	80 3d 34 12 21 f0 00 	cmpb   $0x0,0xf0211234
f010077f:	75 10                	jne    f0100791 <cons_init+0x13e>
		cprintf("Serial port does not exist!\n");
f0100781:	83 ec 0c             	sub    $0xc,%esp
f0100784:	68 2f 61 10 f0       	push   $0xf010612f
f0100789:	e8 a0 2e 00 00       	call   f010362e <cprintf>
f010078e:	83 c4 10             	add    $0x10,%esp
}
f0100791:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100794:	5b                   	pop    %ebx
f0100795:	5e                   	pop    %esi
f0100796:	5f                   	pop    %edi
f0100797:	5d                   	pop    %ebp
f0100798:	c3                   	ret    

f0100799 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100799:	55                   	push   %ebp
f010079a:	89 e5                	mov    %esp,%ebp
f010079c:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f010079f:	8b 45 08             	mov    0x8(%ebp),%eax
f01007a2:	e8 4b fc ff ff       	call   f01003f2 <cons_putc>
}
f01007a7:	c9                   	leave  
f01007a8:	c3                   	ret    

f01007a9 <getchar>:

int
getchar(void)
{
f01007a9:	55                   	push   %ebp
f01007aa:	89 e5                	mov    %esp,%ebp
f01007ac:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f01007af:	e8 55 fe ff ff       	call   f0100609 <cons_getc>
f01007b4:	85 c0                	test   %eax,%eax
f01007b6:	74 f7                	je     f01007af <getchar+0x6>
		/* do nothing */;
	return c;
}
f01007b8:	c9                   	leave  
f01007b9:	c3                   	ret    

f01007ba <iscons>:

int
iscons(int fdnum)
{
f01007ba:	55                   	push   %ebp
f01007bb:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f01007bd:	b8 01 00 00 00       	mov    $0x1,%eax
f01007c2:	5d                   	pop    %ebp
f01007c3:	c3                   	ret    

f01007c4 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f01007c4:	55                   	push   %ebp
f01007c5:	89 e5                	mov    %esp,%ebp
f01007c7:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f01007ca:	68 80 63 10 f0       	push   $0xf0106380
f01007cf:	68 9e 63 10 f0       	push   $0xf010639e
f01007d4:	68 a3 63 10 f0       	push   $0xf01063a3
f01007d9:	e8 50 2e 00 00       	call   f010362e <cprintf>
f01007de:	83 c4 0c             	add    $0xc,%esp
f01007e1:	68 2c 64 10 f0       	push   $0xf010642c
f01007e6:	68 ac 63 10 f0       	push   $0xf01063ac
f01007eb:	68 a3 63 10 f0       	push   $0xf01063a3
f01007f0:	e8 39 2e 00 00       	call   f010362e <cprintf>
	return 0;
}
f01007f5:	b8 00 00 00 00       	mov    $0x0,%eax
f01007fa:	c9                   	leave  
f01007fb:	c3                   	ret    

f01007fc <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01007fc:	55                   	push   %ebp
f01007fd:	89 e5                	mov    %esp,%ebp
f01007ff:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100802:	68 b5 63 10 f0       	push   $0xf01063b5
f0100807:	e8 22 2e 00 00       	call   f010362e <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f010080c:	83 c4 08             	add    $0x8,%esp
f010080f:	68 0c 00 10 00       	push   $0x10000c
f0100814:	68 54 64 10 f0       	push   $0xf0106454
f0100819:	e8 10 2e 00 00       	call   f010362e <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f010081e:	83 c4 0c             	add    $0xc,%esp
f0100821:	68 0c 00 10 00       	push   $0x10000c
f0100826:	68 0c 00 10 f0       	push   $0xf010000c
f010082b:	68 7c 64 10 f0       	push   $0xf010647c
f0100830:	e8 f9 2d 00 00       	call   f010362e <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100835:	83 c4 0c             	add    $0xc,%esp
f0100838:	68 51 60 10 00       	push   $0x106051
f010083d:	68 51 60 10 f0       	push   $0xf0106051
f0100842:	68 a0 64 10 f0       	push   $0xf01064a0
f0100847:	e8 e2 2d 00 00       	call   f010362e <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010084c:	83 c4 0c             	add    $0xc,%esp
f010084f:	68 7c 09 21 00       	push   $0x21097c
f0100854:	68 7c 09 21 f0       	push   $0xf021097c
f0100859:	68 c4 64 10 f0       	push   $0xf01064c4
f010085e:	e8 cb 2d 00 00       	call   f010362e <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100863:	83 c4 0c             	add    $0xc,%esp
f0100866:	68 08 30 25 00       	push   $0x253008
f010086b:	68 08 30 25 f0       	push   $0xf0253008
f0100870:	68 e8 64 10 f0       	push   $0xf01064e8
f0100875:	e8 b4 2d 00 00       	call   f010362e <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f010087a:	b8 07 34 25 f0       	mov    $0xf0253407,%eax
f010087f:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100884:	83 c4 08             	add    $0x8,%esp
f0100887:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f010088c:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100892:	85 c0                	test   %eax,%eax
f0100894:	0f 48 c2             	cmovs  %edx,%eax
f0100897:	c1 f8 0a             	sar    $0xa,%eax
f010089a:	50                   	push   %eax
f010089b:	68 0c 65 10 f0       	push   $0xf010650c
f01008a0:	e8 89 2d 00 00       	call   f010362e <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f01008a5:	b8 00 00 00 00       	mov    $0x0,%eax
f01008aa:	c9                   	leave  
f01008ab:	c3                   	ret    

f01008ac <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f01008ac:	55                   	push   %ebp
f01008ad:	89 e5                	mov    %esp,%ebp
f01008af:	56                   	push   %esi
f01008b0:	53                   	push   %ebx
f01008b1:	83 ec 2c             	sub    $0x2c,%esp

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f01008b4:	89 eb                	mov    %ebp,%ebx
	uintptr_t ebp = read_ebp();
	struct Eipdebuginfo info;
	cprintf("Stack backtrace:\n");
f01008b6:	68 ce 63 10 f0       	push   $0xf01063ce
f01008bb:	e8 6e 2d 00 00       	call   f010362e <cprintf>
	while(ebp != 0){
f01008c0:	83 c4 10             	add    $0x10,%esp
		cprintf("  ebp %08x  eip %08x  args %08x %08x %08x %08x %08x\n", ebp , 
				*((uintptr_t *)ebp + 1), *((uintptr_t *)ebp + 2), *((uintptr_t *)ebp + 3), 
			    *((uintptr_t *)ebp + 4), *((uintptr_t *)ebp + 5), *((uintptr_t *)ebp + 6));
		debuginfo_eip(*((uintptr_t *)ebp + 1), &info);
f01008c3:	8d 75 e0             	lea    -0x20(%ebp),%esi
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	uintptr_t ebp = read_ebp();
	struct Eipdebuginfo info;
	cprintf("Stack backtrace:\n");
	while(ebp != 0){
f01008c6:	eb 4e                	jmp    f0100916 <mon_backtrace+0x6a>
		cprintf("  ebp %08x  eip %08x  args %08x %08x %08x %08x %08x\n", ebp , 
f01008c8:	ff 73 18             	pushl  0x18(%ebx)
f01008cb:	ff 73 14             	pushl  0x14(%ebx)
f01008ce:	ff 73 10             	pushl  0x10(%ebx)
f01008d1:	ff 73 0c             	pushl  0xc(%ebx)
f01008d4:	ff 73 08             	pushl  0x8(%ebx)
f01008d7:	ff 73 04             	pushl  0x4(%ebx)
f01008da:	53                   	push   %ebx
f01008db:	68 38 65 10 f0       	push   $0xf0106538
f01008e0:	e8 49 2d 00 00       	call   f010362e <cprintf>
				*((uintptr_t *)ebp + 1), *((uintptr_t *)ebp + 2), *((uintptr_t *)ebp + 3), 
			    *((uintptr_t *)ebp + 4), *((uintptr_t *)ebp + 5), *((uintptr_t *)ebp + 6));
		debuginfo_eip(*((uintptr_t *)ebp + 1), &info);
f01008e5:	83 c4 18             	add    $0x18,%esp
f01008e8:	56                   	push   %esi
f01008e9:	ff 73 04             	pushl  0x4(%ebx)
f01008ec:	e8 fa 3f 00 00       	call   f01048eb <debuginfo_eip>
		cprintf("%s:%d: %.*s+%d\n", info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, 
f01008f1:	83 c4 08             	add    $0x8,%esp
f01008f4:	8b 43 04             	mov    0x4(%ebx),%eax
f01008f7:	2b 45 f0             	sub    -0x10(%ebp),%eax
f01008fa:	50                   	push   %eax
f01008fb:	ff 75 e8             	pushl  -0x18(%ebp)
f01008fe:	ff 75 ec             	pushl  -0x14(%ebp)
f0100901:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100904:	ff 75 e0             	pushl  -0x20(%ebp)
f0100907:	68 e0 63 10 f0       	push   $0xf01063e0
f010090c:	e8 1d 2d 00 00       	call   f010362e <cprintf>
				*((uintptr_t *)ebp + 1) - info.eip_fn_addr);
		ebp = *(uintptr_t *)ebp;
f0100911:	8b 1b                	mov    (%ebx),%ebx
f0100913:	83 c4 20             	add    $0x20,%esp
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	uintptr_t ebp = read_ebp();
	struct Eipdebuginfo info;
	cprintf("Stack backtrace:\n");
	while(ebp != 0){
f0100916:	85 db                	test   %ebx,%ebx
f0100918:	75 ae                	jne    f01008c8 <mon_backtrace+0x1c>
		cprintf("%s:%d: %.*s+%d\n", info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, 
				*((uintptr_t *)ebp + 1) - info.eip_fn_addr);
		ebp = *(uintptr_t *)ebp;
	}
	return 0;
}
f010091a:	b8 00 00 00 00       	mov    $0x0,%eax
f010091f:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100922:	5b                   	pop    %ebx
f0100923:	5e                   	pop    %esi
f0100924:	5d                   	pop    %ebp
f0100925:	c3                   	ret    

f0100926 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100926:	55                   	push   %ebp
f0100927:	89 e5                	mov    %esp,%ebp
f0100929:	57                   	push   %edi
f010092a:	56                   	push   %esi
f010092b:	53                   	push   %ebx
f010092c:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f010092f:	68 70 65 10 f0       	push   $0xf0106570
f0100934:	e8 f5 2c 00 00       	call   f010362e <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100939:	c7 04 24 94 65 10 f0 	movl   $0xf0106594,(%esp)
f0100940:	e8 e9 2c 00 00       	call   f010362e <cprintf>

	if (tf != NULL)
f0100945:	83 c4 10             	add    $0x10,%esp
f0100948:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f010094c:	74 0e                	je     f010095c <monitor+0x36>
		print_trapframe(tf);
f010094e:	83 ec 0c             	sub    $0xc,%esp
f0100951:	ff 75 08             	pushl  0x8(%ebp)
f0100954:	e8 84 32 00 00       	call   f0103bdd <print_trapframe>
f0100959:	83 c4 10             	add    $0x10,%esp

	while (1) {
		buf = readline("K> ");
f010095c:	83 ec 0c             	sub    $0xc,%esp
f010095f:	68 f0 63 10 f0       	push   $0xf01063f0
f0100964:	e8 db 47 00 00       	call   f0105144 <readline>
f0100969:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f010096b:	83 c4 10             	add    $0x10,%esp
f010096e:	85 c0                	test   %eax,%eax
f0100970:	74 ea                	je     f010095c <monitor+0x36>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100972:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100979:	be 00 00 00 00       	mov    $0x0,%esi
f010097e:	eb 0a                	jmp    f010098a <monitor+0x64>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100980:	c6 03 00             	movb   $0x0,(%ebx)
f0100983:	89 f7                	mov    %esi,%edi
f0100985:	8d 5b 01             	lea    0x1(%ebx),%ebx
f0100988:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f010098a:	0f b6 03             	movzbl (%ebx),%eax
f010098d:	84 c0                	test   %al,%al
f010098f:	74 63                	je     f01009f4 <monitor+0xce>
f0100991:	83 ec 08             	sub    $0x8,%esp
f0100994:	0f be c0             	movsbl %al,%eax
f0100997:	50                   	push   %eax
f0100998:	68 f4 63 10 f0       	push   $0xf01063f4
f010099d:	e8 d4 49 00 00       	call   f0105376 <strchr>
f01009a2:	83 c4 10             	add    $0x10,%esp
f01009a5:	85 c0                	test   %eax,%eax
f01009a7:	75 d7                	jne    f0100980 <monitor+0x5a>
			*buf++ = 0;
		if (*buf == 0)
f01009a9:	80 3b 00             	cmpb   $0x0,(%ebx)
f01009ac:	74 46                	je     f01009f4 <monitor+0xce>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f01009ae:	83 fe 0f             	cmp    $0xf,%esi
f01009b1:	75 14                	jne    f01009c7 <monitor+0xa1>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01009b3:	83 ec 08             	sub    $0x8,%esp
f01009b6:	6a 10                	push   $0x10
f01009b8:	68 f9 63 10 f0       	push   $0xf01063f9
f01009bd:	e8 6c 2c 00 00       	call   f010362e <cprintf>
f01009c2:	83 c4 10             	add    $0x10,%esp
f01009c5:	eb 95                	jmp    f010095c <monitor+0x36>
			return 0;
		}
		argv[argc++] = buf;
f01009c7:	8d 7e 01             	lea    0x1(%esi),%edi
f01009ca:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f01009ce:	eb 03                	jmp    f01009d3 <monitor+0xad>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f01009d0:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f01009d3:	0f b6 03             	movzbl (%ebx),%eax
f01009d6:	84 c0                	test   %al,%al
f01009d8:	74 ae                	je     f0100988 <monitor+0x62>
f01009da:	83 ec 08             	sub    $0x8,%esp
f01009dd:	0f be c0             	movsbl %al,%eax
f01009e0:	50                   	push   %eax
f01009e1:	68 f4 63 10 f0       	push   $0xf01063f4
f01009e6:	e8 8b 49 00 00       	call   f0105376 <strchr>
f01009eb:	83 c4 10             	add    $0x10,%esp
f01009ee:	85 c0                	test   %eax,%eax
f01009f0:	74 de                	je     f01009d0 <monitor+0xaa>
f01009f2:	eb 94                	jmp    f0100988 <monitor+0x62>
			buf++;
	}
	argv[argc] = 0;
f01009f4:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01009fb:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01009fc:	85 f6                	test   %esi,%esi
f01009fe:	0f 84 58 ff ff ff    	je     f010095c <monitor+0x36>
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100a04:	83 ec 08             	sub    $0x8,%esp
f0100a07:	68 9e 63 10 f0       	push   $0xf010639e
f0100a0c:	ff 75 a8             	pushl  -0x58(%ebp)
f0100a0f:	e8 04 49 00 00       	call   f0105318 <strcmp>
f0100a14:	83 c4 10             	add    $0x10,%esp
f0100a17:	85 c0                	test   %eax,%eax
f0100a19:	74 1e                	je     f0100a39 <monitor+0x113>
f0100a1b:	83 ec 08             	sub    $0x8,%esp
f0100a1e:	68 ac 63 10 f0       	push   $0xf01063ac
f0100a23:	ff 75 a8             	pushl  -0x58(%ebp)
f0100a26:	e8 ed 48 00 00       	call   f0105318 <strcmp>
f0100a2b:	83 c4 10             	add    $0x10,%esp
f0100a2e:	85 c0                	test   %eax,%eax
f0100a30:	75 2f                	jne    f0100a61 <monitor+0x13b>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100a32:	b8 01 00 00 00       	mov    $0x1,%eax
f0100a37:	eb 05                	jmp    f0100a3e <monitor+0x118>
		if (strcmp(argv[0], commands[i].name) == 0)
f0100a39:	b8 00 00 00 00       	mov    $0x0,%eax
			return commands[i].func(argc, argv, tf);
f0100a3e:	83 ec 04             	sub    $0x4,%esp
f0100a41:	8d 14 00             	lea    (%eax,%eax,1),%edx
f0100a44:	01 d0                	add    %edx,%eax
f0100a46:	ff 75 08             	pushl  0x8(%ebp)
f0100a49:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f0100a4c:	51                   	push   %ecx
f0100a4d:	56                   	push   %esi
f0100a4e:	ff 14 85 c4 65 10 f0 	call   *-0xfef9a3c(,%eax,4)
		print_trapframe(tf);

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100a55:	83 c4 10             	add    $0x10,%esp
f0100a58:	85 c0                	test   %eax,%eax
f0100a5a:	78 1d                	js     f0100a79 <monitor+0x153>
f0100a5c:	e9 fb fe ff ff       	jmp    f010095c <monitor+0x36>
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100a61:	83 ec 08             	sub    $0x8,%esp
f0100a64:	ff 75 a8             	pushl  -0x58(%ebp)
f0100a67:	68 16 64 10 f0       	push   $0xf0106416
f0100a6c:	e8 bd 2b 00 00       	call   f010362e <cprintf>
f0100a71:	83 c4 10             	add    $0x10,%esp
f0100a74:	e9 e3 fe ff ff       	jmp    f010095c <monitor+0x36>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100a79:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100a7c:	5b                   	pop    %ebx
f0100a7d:	5e                   	pop    %esi
f0100a7e:	5f                   	pop    %edi
f0100a7f:	5d                   	pop    %ebp
f0100a80:	c3                   	ret    

f0100a81 <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f0100a81:	55                   	push   %ebp
f0100a82:	89 e5                	mov    %esp,%ebp
f0100a84:	56                   	push   %esi
f0100a85:	53                   	push   %ebx
f0100a86:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100a88:	83 ec 0c             	sub    $0xc,%esp
f0100a8b:	50                   	push   %eax
f0100a8c:	e8 1e 2a 00 00       	call   f01034af <mc146818_read>
f0100a91:	89 c6                	mov    %eax,%esi
f0100a93:	83 c3 01             	add    $0x1,%ebx
f0100a96:	89 1c 24             	mov    %ebx,(%esp)
f0100a99:	e8 11 2a 00 00       	call   f01034af <mc146818_read>
f0100a9e:	c1 e0 08             	shl    $0x8,%eax
f0100aa1:	09 f0                	or     %esi,%eax
}
f0100aa3:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100aa6:	5b                   	pop    %ebx
f0100aa7:	5e                   	pop    %esi
f0100aa8:	5d                   	pop    %ebp
f0100aa9:	c3                   	ret    

f0100aaa <check_va2pa>:
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f0100aaa:	89 d1                	mov    %edx,%ecx
f0100aac:	c1 e9 16             	shr    $0x16,%ecx
f0100aaf:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0100ab2:	a8 01                	test   $0x1,%al
f0100ab4:	74 52                	je     f0100b08 <check_va2pa+0x5e>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100ab6:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100abb:	89 c1                	mov    %eax,%ecx
f0100abd:	c1 e9 0c             	shr    $0xc,%ecx
f0100ac0:	3b 0d 88 1e 21 f0    	cmp    0xf0211e88,%ecx
f0100ac6:	72 1b                	jb     f0100ae3 <check_va2pa+0x39>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100ac8:	55                   	push   %ebp
f0100ac9:	89 e5                	mov    %esp,%ebp
f0100acb:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ace:	50                   	push   %eax
f0100acf:	68 84 60 10 f0       	push   $0xf0106084
f0100ad4:	68 85 03 00 00       	push   $0x385
f0100ad9:	68 55 6f 10 f0       	push   $0xf0106f55
f0100ade:	e8 5d f5 ff ff       	call   f0100040 <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f0100ae3:	c1 ea 0c             	shr    $0xc,%edx
f0100ae6:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100aec:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100af3:	89 c2                	mov    %eax,%edx
f0100af5:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100af8:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100afd:	85 d2                	test   %edx,%edx
f0100aff:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100b04:	0f 44 c2             	cmove  %edx,%eax
f0100b07:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f0100b08:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f0100b0d:	c3                   	ret    

f0100b0e <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100b0e:	89 c2                	mov    %eax,%edx
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100b10:	83 3d 38 12 21 f0 00 	cmpl   $0x0,0xf0211238
f0100b17:	75 0f                	jne    f0100b28 <boot_alloc+0x1a>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100b19:	b8 07 40 25 f0       	mov    $0xf0254007,%eax
f0100b1e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100b23:	a3 38 12 21 f0       	mov    %eax,0xf0211238
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	result = nextfree;
f0100b28:	a1 38 12 21 f0       	mov    0xf0211238,%eax
	if(n > 0){
f0100b2d:	85 d2                	test   %edx,%edx
f0100b2f:	74 62                	je     f0100b93 <boot_alloc+0x85>
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100b31:	55                   	push   %ebp
f0100b32:	89 e5                	mov    %esp,%ebp
f0100b34:	53                   	push   %ebx
f0100b35:	83 ec 04             	sub    $0x4,%esp
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100b38:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100b3d:	77 12                	ja     f0100b51 <boot_alloc+0x43>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100b3f:	50                   	push   %eax
f0100b40:	68 a8 60 10 f0       	push   $0xf01060a8
f0100b45:	6a 6e                	push   $0x6e
f0100b47:	68 55 6f 10 f0       	push   $0xf0106f55
f0100b4c:	e8 ef f4 ff ff       	call   f0100040 <_panic>
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	result = nextfree;
	if(n > 0){
		if (PADDR(nextfree) + n > (npages + 1) * PGSIZE) {
f0100b51:	8d 9c 10 00 00 00 10 	lea    0x10000000(%eax,%edx,1),%ebx
f0100b58:	8b 0d 88 1e 21 f0    	mov    0xf0211e88,%ecx
f0100b5e:	83 c1 01             	add    $0x1,%ecx
f0100b61:	c1 e1 0c             	shl    $0xc,%ecx
f0100b64:	39 cb                	cmp    %ecx,%ebx
f0100b66:	76 14                	jbe    f0100b7c <boot_alloc+0x6e>
			panic("out of memory\n");
f0100b68:	83 ec 04             	sub    $0x4,%esp
f0100b6b:	68 61 6f 10 f0       	push   $0xf0106f61
f0100b70:	6a 6f                	push   $0x6f
f0100b72:	68 55 6f 10 f0       	push   $0xf0106f55
f0100b77:	e8 c4 f4 ff ff       	call   f0100040 <_panic>
		}
		nextfree = ROUNDUP((char *)nextfree + n, PGSIZE);
f0100b7c:	8d 94 10 ff 0f 00 00 	lea    0xfff(%eax,%edx,1),%edx
f0100b83:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100b89:	89 15 38 12 21 f0    	mov    %edx,0xf0211238
	}
	return result;
}
f0100b8f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100b92:	c9                   	leave  
f0100b93:	f3 c3                	repz ret 

f0100b95 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100b95:	55                   	push   %ebp
f0100b96:	89 e5                	mov    %esp,%ebp
f0100b98:	57                   	push   %edi
f0100b99:	56                   	push   %esi
f0100b9a:	53                   	push   %ebx
f0100b9b:	83 ec 2c             	sub    $0x2c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100b9e:	84 c0                	test   %al,%al
f0100ba0:	0f 85 a0 02 00 00    	jne    f0100e46 <check_page_free_list+0x2b1>
f0100ba6:	e9 ad 02 00 00       	jmp    f0100e58 <check_page_free_list+0x2c3>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f0100bab:	83 ec 04             	sub    $0x4,%esp
f0100bae:	68 d4 65 10 f0       	push   $0xf01065d4
f0100bb3:	68 b8 02 00 00       	push   $0x2b8
f0100bb8:	68 55 6f 10 f0       	push   $0xf0106f55
f0100bbd:	e8 7e f4 ff ff       	call   f0100040 <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100bc2:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100bc5:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100bc8:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100bcb:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100bce:	89 c2                	mov    %eax,%edx
f0100bd0:	2b 15 90 1e 21 f0    	sub    0xf0211e90,%edx
f0100bd6:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100bdc:	0f 95 c2             	setne  %dl
f0100bdf:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100be2:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100be6:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100be8:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100bec:	8b 00                	mov    (%eax),%eax
f0100bee:	85 c0                	test   %eax,%eax
f0100bf0:	75 dc                	jne    f0100bce <check_page_free_list+0x39>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100bf2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100bf5:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100bfb:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100bfe:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100c01:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100c03:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100c06:	a3 40 12 21 f0       	mov    %eax,0xf0211240
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100c0b:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100c10:	8b 1d 40 12 21 f0    	mov    0xf0211240,%ebx
f0100c16:	eb 53                	jmp    f0100c6b <check_page_free_list+0xd6>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100c18:	89 d8                	mov    %ebx,%eax
f0100c1a:	2b 05 90 1e 21 f0    	sub    0xf0211e90,%eax
f0100c20:	c1 f8 03             	sar    $0x3,%eax
f0100c23:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100c26:	89 c2                	mov    %eax,%edx
f0100c28:	c1 ea 16             	shr    $0x16,%edx
f0100c2b:	39 f2                	cmp    %esi,%edx
f0100c2d:	73 3a                	jae    f0100c69 <check_page_free_list+0xd4>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100c2f:	89 c2                	mov    %eax,%edx
f0100c31:	c1 ea 0c             	shr    $0xc,%edx
f0100c34:	3b 15 88 1e 21 f0    	cmp    0xf0211e88,%edx
f0100c3a:	72 12                	jb     f0100c4e <check_page_free_list+0xb9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100c3c:	50                   	push   %eax
f0100c3d:	68 84 60 10 f0       	push   $0xf0106084
f0100c42:	6a 58                	push   $0x58
f0100c44:	68 70 6f 10 f0       	push   $0xf0106f70
f0100c49:	e8 f2 f3 ff ff       	call   f0100040 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100c4e:	83 ec 04             	sub    $0x4,%esp
f0100c51:	68 80 00 00 00       	push   $0x80
f0100c56:	68 97 00 00 00       	push   $0x97
f0100c5b:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100c60:	50                   	push   %eax
f0100c61:	e8 4d 47 00 00       	call   f01053b3 <memset>
f0100c66:	83 c4 10             	add    $0x10,%esp
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100c69:	8b 1b                	mov    (%ebx),%ebx
f0100c6b:	85 db                	test   %ebx,%ebx
f0100c6d:	75 a9                	jne    f0100c18 <check_page_free_list+0x83>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100c6f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c74:	e8 95 fe ff ff       	call   f0100b0e <boot_alloc>
f0100c79:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c7c:	8b 15 40 12 21 f0    	mov    0xf0211240,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100c82:	8b 0d 90 1e 21 f0    	mov    0xf0211e90,%ecx
		assert(pp < pages + npages);
f0100c88:	a1 88 1e 21 f0       	mov    0xf0211e88,%eax
f0100c8d:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0100c90:	8d 04 c1             	lea    (%ecx,%eax,8),%eax
f0100c93:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100c96:	89 4d d0             	mov    %ecx,-0x30(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100c99:	be 00 00 00 00       	mov    $0x0,%esi
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c9e:	e9 52 01 00 00       	jmp    f0100df5 <check_page_free_list+0x260>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100ca3:	39 ca                	cmp    %ecx,%edx
f0100ca5:	73 19                	jae    f0100cc0 <check_page_free_list+0x12b>
f0100ca7:	68 7e 6f 10 f0       	push   $0xf0106f7e
f0100cac:	68 8a 6f 10 f0       	push   $0xf0106f8a
f0100cb1:	68 d2 02 00 00       	push   $0x2d2
f0100cb6:	68 55 6f 10 f0       	push   $0xf0106f55
f0100cbb:	e8 80 f3 ff ff       	call   f0100040 <_panic>
		assert(pp < pages + npages);
f0100cc0:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100cc3:	72 19                	jb     f0100cde <check_page_free_list+0x149>
f0100cc5:	68 9f 6f 10 f0       	push   $0xf0106f9f
f0100cca:	68 8a 6f 10 f0       	push   $0xf0106f8a
f0100ccf:	68 d3 02 00 00       	push   $0x2d3
f0100cd4:	68 55 6f 10 f0       	push   $0xf0106f55
f0100cd9:	e8 62 f3 ff ff       	call   f0100040 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100cde:	89 d0                	mov    %edx,%eax
f0100ce0:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0100ce3:	a8 07                	test   $0x7,%al
f0100ce5:	74 19                	je     f0100d00 <check_page_free_list+0x16b>
f0100ce7:	68 f8 65 10 f0       	push   $0xf01065f8
f0100cec:	68 8a 6f 10 f0       	push   $0xf0106f8a
f0100cf1:	68 d4 02 00 00       	push   $0x2d4
f0100cf6:	68 55 6f 10 f0       	push   $0xf0106f55
f0100cfb:	e8 40 f3 ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100d00:	c1 f8 03             	sar    $0x3,%eax
f0100d03:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100d06:	85 c0                	test   %eax,%eax
f0100d08:	75 19                	jne    f0100d23 <check_page_free_list+0x18e>
f0100d0a:	68 b3 6f 10 f0       	push   $0xf0106fb3
f0100d0f:	68 8a 6f 10 f0       	push   $0xf0106f8a
f0100d14:	68 d7 02 00 00       	push   $0x2d7
f0100d19:	68 55 6f 10 f0       	push   $0xf0106f55
f0100d1e:	e8 1d f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100d23:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100d28:	75 19                	jne    f0100d43 <check_page_free_list+0x1ae>
f0100d2a:	68 c4 6f 10 f0       	push   $0xf0106fc4
f0100d2f:	68 8a 6f 10 f0       	push   $0xf0106f8a
f0100d34:	68 d8 02 00 00       	push   $0x2d8
f0100d39:	68 55 6f 10 f0       	push   $0xf0106f55
f0100d3e:	e8 fd f2 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100d43:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100d48:	75 19                	jne    f0100d63 <check_page_free_list+0x1ce>
f0100d4a:	68 2c 66 10 f0       	push   $0xf010662c
f0100d4f:	68 8a 6f 10 f0       	push   $0xf0106f8a
f0100d54:	68 d9 02 00 00       	push   $0x2d9
f0100d59:	68 55 6f 10 f0       	push   $0xf0106f55
f0100d5e:	e8 dd f2 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100d63:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100d68:	75 19                	jne    f0100d83 <check_page_free_list+0x1ee>
f0100d6a:	68 dd 6f 10 f0       	push   $0xf0106fdd
f0100d6f:	68 8a 6f 10 f0       	push   $0xf0106f8a
f0100d74:	68 da 02 00 00       	push   $0x2da
f0100d79:	68 55 6f 10 f0       	push   $0xf0106f55
f0100d7e:	e8 bd f2 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100d83:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100d88:	0f 86 f1 00 00 00    	jbe    f0100e7f <check_page_free_list+0x2ea>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100d8e:	89 c7                	mov    %eax,%edi
f0100d90:	c1 ef 0c             	shr    $0xc,%edi
f0100d93:	39 7d c8             	cmp    %edi,-0x38(%ebp)
f0100d96:	77 12                	ja     f0100daa <check_page_free_list+0x215>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100d98:	50                   	push   %eax
f0100d99:	68 84 60 10 f0       	push   $0xf0106084
f0100d9e:	6a 58                	push   $0x58
f0100da0:	68 70 6f 10 f0       	push   $0xf0106f70
f0100da5:	e8 96 f2 ff ff       	call   f0100040 <_panic>
f0100daa:	8d b8 00 00 00 f0    	lea    -0x10000000(%eax),%edi
f0100db0:	39 7d cc             	cmp    %edi,-0x34(%ebp)
f0100db3:	0f 86 b6 00 00 00    	jbe    f0100e6f <check_page_free_list+0x2da>
f0100db9:	68 50 66 10 f0       	push   $0xf0106650
f0100dbe:	68 8a 6f 10 f0       	push   $0xf0106f8a
f0100dc3:	68 db 02 00 00       	push   $0x2db
f0100dc8:	68 55 6f 10 f0       	push   $0xf0106f55
f0100dcd:	e8 6e f2 ff ff       	call   f0100040 <_panic>
		// (new test for lab 4)
		assert(page2pa(pp) != MPENTRY_PADDR);
f0100dd2:	68 f7 6f 10 f0       	push   $0xf0106ff7
f0100dd7:	68 8a 6f 10 f0       	push   $0xf0106f8a
f0100ddc:	68 dd 02 00 00       	push   $0x2dd
f0100de1:	68 55 6f 10 f0       	push   $0xf0106f55
f0100de6:	e8 55 f2 ff ff       	call   f0100040 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100deb:	83 c6 01             	add    $0x1,%esi
f0100dee:	eb 03                	jmp    f0100df3 <check_page_free_list+0x25e>
		else
			++nfree_extmem;
f0100df0:	83 c3 01             	add    $0x1,%ebx
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100df3:	8b 12                	mov    (%edx),%edx
f0100df5:	85 d2                	test   %edx,%edx
f0100df7:	0f 85 a6 fe ff ff    	jne    f0100ca3 <check_page_free_list+0x10e>
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100dfd:	85 f6                	test   %esi,%esi
f0100dff:	7f 19                	jg     f0100e1a <check_page_free_list+0x285>
f0100e01:	68 14 70 10 f0       	push   $0xf0107014
f0100e06:	68 8a 6f 10 f0       	push   $0xf0106f8a
f0100e0b:	68 e5 02 00 00       	push   $0x2e5
f0100e10:	68 55 6f 10 f0       	push   $0xf0106f55
f0100e15:	e8 26 f2 ff ff       	call   f0100040 <_panic>
	assert(nfree_extmem > 0);
f0100e1a:	85 db                	test   %ebx,%ebx
f0100e1c:	7f 19                	jg     f0100e37 <check_page_free_list+0x2a2>
f0100e1e:	68 26 70 10 f0       	push   $0xf0107026
f0100e23:	68 8a 6f 10 f0       	push   $0xf0106f8a
f0100e28:	68 e6 02 00 00       	push   $0x2e6
f0100e2d:	68 55 6f 10 f0       	push   $0xf0106f55
f0100e32:	e8 09 f2 ff ff       	call   f0100040 <_panic>

	cprintf("check_page_free_list() succeeded!\n");
f0100e37:	83 ec 0c             	sub    $0xc,%esp
f0100e3a:	68 98 66 10 f0       	push   $0xf0106698
f0100e3f:	e8 ea 27 00 00       	call   f010362e <cprintf>
}
f0100e44:	eb 49                	jmp    f0100e8f <check_page_free_list+0x2fa>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100e46:	a1 40 12 21 f0       	mov    0xf0211240,%eax
f0100e4b:	85 c0                	test   %eax,%eax
f0100e4d:	0f 85 6f fd ff ff    	jne    f0100bc2 <check_page_free_list+0x2d>
f0100e53:	e9 53 fd ff ff       	jmp    f0100bab <check_page_free_list+0x16>
f0100e58:	83 3d 40 12 21 f0 00 	cmpl   $0x0,0xf0211240
f0100e5f:	0f 84 46 fd ff ff    	je     f0100bab <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100e65:	be 00 04 00 00       	mov    $0x400,%esi
f0100e6a:	e9 a1 fd ff ff       	jmp    f0100c10 <check_page_free_list+0x7b>
		assert(page2pa(pp) != IOPHYSMEM);
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
		assert(page2pa(pp) != EXTPHYSMEM);
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
		// (new test for lab 4)
		assert(page2pa(pp) != MPENTRY_PADDR);
f0100e6f:	3d 00 70 00 00       	cmp    $0x7000,%eax
f0100e74:	0f 85 76 ff ff ff    	jne    f0100df0 <check_page_free_list+0x25b>
f0100e7a:	e9 53 ff ff ff       	jmp    f0100dd2 <check_page_free_list+0x23d>
f0100e7f:	3d 00 70 00 00       	cmp    $0x7000,%eax
f0100e84:	0f 85 61 ff ff ff    	jne    f0100deb <check_page_free_list+0x256>
f0100e8a:	e9 43 ff ff ff       	jmp    f0100dd2 <check_page_free_list+0x23d>

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);

	cprintf("check_page_free_list() succeeded!\n");
}
f0100e8f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100e92:	5b                   	pop    %ebx
f0100e93:	5e                   	pop    %esi
f0100e94:	5f                   	pop    %edi
f0100e95:	5d                   	pop    %ebp
f0100e96:	c3                   	ret    

f0100e97 <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100e97:	55                   	push   %ebp
f0100e98:	89 e5                	mov    %esp,%ebp
f0100e9a:	53                   	push   %ebx
f0100e9b:	83 ec 04             	sub    $0x4,%esp
f0100e9e:	8b 1d 40 12 21 f0    	mov    0xf0211240,%ebx
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	
	size_t i, io_page_i, ext_page_i, free_top, mpentry_i;
	for (i = 0; i < npages; i++) {
f0100ea4:	ba 00 00 00 00       	mov    $0x0,%edx
f0100ea9:	b8 00 00 00 00       	mov    $0x0,%eax
f0100eae:	eb 27                	jmp    f0100ed7 <page_init+0x40>
f0100eb0:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
		pages[i].pp_ref = 0;
f0100eb7:	89 d1                	mov    %edx,%ecx
f0100eb9:	03 0d 90 1e 21 f0    	add    0xf0211e90,%ecx
f0100ebf:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = page_free_list;
f0100ec5:	89 19                	mov    %ebx,(%ecx)
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	
	size_t i, io_page_i, ext_page_i, free_top, mpentry_i;
	for (i = 0; i < npages; i++) {
f0100ec7:	83 c0 01             	add    $0x1,%eax
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
f0100eca:	89 d3                	mov    %edx,%ebx
f0100ecc:	03 1d 90 1e 21 f0    	add    0xf0211e90,%ebx
f0100ed2:	ba 01 00 00 00       	mov    $0x1,%edx
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	
	size_t i, io_page_i, ext_page_i, free_top, mpentry_i;
	for (i = 0; i < npages; i++) {
f0100ed7:	3b 05 88 1e 21 f0    	cmp    0xf0211e88,%eax
f0100edd:	72 d1                	jb     f0100eb0 <page_init+0x19>
f0100edf:	84 d2                	test   %dl,%dl
f0100ee1:	74 06                	je     f0100ee9 <page_init+0x52>
f0100ee3:	89 1d 40 12 21 f0    	mov    %ebx,0xf0211240
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
  
	pages[0].pp_link = NULL;
f0100ee9:	a1 90 1e 21 f0       	mov    0xf0211e90,%eax
f0100eee:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pages[1].pp_link = NULL;
f0100ef4:	a1 90 1e 21 f0       	mov    0xf0211e90,%eax
f0100ef9:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)

	io_page_i = PGNUM(IOPHYSMEM);
	ext_page_i = PGNUM(EXTPHYSMEM);
	free_top = PGNUM(PADDR(boot_alloc(0)));
f0100f00:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f05:	e8 04 fc ff ff       	call   f0100b0e <boot_alloc>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100f0a:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100f0f:	77 15                	ja     f0100f26 <page_init+0x8f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100f11:	50                   	push   %eax
f0100f12:	68 a8 60 10 f0       	push   $0xf01060a8
f0100f17:	68 4c 01 00 00       	push   $0x14c
f0100f1c:	68 55 6f 10 f0       	push   $0xf0106f55
f0100f21:	e8 1a f1 ff ff       	call   f0100040 <_panic>
f0100f26:	8d 88 00 00 00 10    	lea    0x10000000(%eax),%ecx
f0100f2c:	c1 e9 0c             	shr    $0xc,%ecx

	pages[ext_page_i].pp_link = pages[io_page_i].pp_link;
f0100f2f:	a1 90 1e 21 f0       	mov    0xf0211e90,%eax
f0100f34:	8b 90 00 05 00 00    	mov    0x500(%eax),%edx
f0100f3a:	89 90 00 08 00 00    	mov    %edx,0x800(%eax)
f0100f40:	b8 00 05 00 00       	mov    $0x500,%eax
	for(i = io_page_i;i < ext_page_i;i++)
		pages[i].pp_link = NULL;
f0100f45:	8b 15 90 1e 21 f0    	mov    0xf0211e90,%edx
f0100f4b:	c7 04 02 00 00 00 00 	movl   $0x0,(%edx,%eax,1)
f0100f52:	83 c0 08             	add    $0x8,%eax
	io_page_i = PGNUM(IOPHYSMEM);
	ext_page_i = PGNUM(EXTPHYSMEM);
	free_top = PGNUM(PADDR(boot_alloc(0)));

	pages[ext_page_i].pp_link = pages[io_page_i].pp_link;
	for(i = io_page_i;i < ext_page_i;i++)
f0100f55:	3d 00 08 00 00       	cmp    $0x800,%eax
f0100f5a:	75 e9                	jne    f0100f45 <page_init+0xae>
		pages[i].pp_link = NULL;

	pages[free_top].pp_link = pages[ext_page_i].pp_link;
f0100f5c:	a1 90 1e 21 f0       	mov    0xf0211e90,%eax
f0100f61:	8b 90 00 08 00 00    	mov    0x800(%eax),%edx
f0100f67:	89 14 c8             	mov    %edx,(%eax,%ecx,8)
	for (i = ext_page_i; i < free_top; i++)
f0100f6a:	b8 00 01 00 00       	mov    $0x100,%eax
f0100f6f:	eb 10                	jmp    f0100f81 <page_init+0xea>
		pages[i].pp_link = NULL;
f0100f71:	8b 15 90 1e 21 f0    	mov    0xf0211e90,%edx
f0100f77:	c7 04 c2 00 00 00 00 	movl   $0x0,(%edx,%eax,8)
	pages[ext_page_i].pp_link = pages[io_page_i].pp_link;
	for(i = io_page_i;i < ext_page_i;i++)
		pages[i].pp_link = NULL;

	pages[free_top].pp_link = pages[ext_page_i].pp_link;
	for (i = ext_page_i; i < free_top; i++)
f0100f7e:	83 c0 01             	add    $0x1,%eax
f0100f81:	39 c8                	cmp    %ecx,%eax
f0100f83:	72 ec                	jb     f0100f71 <page_init+0xda>
		pages[i].pp_link = NULL;
        
    mpentry_i = PGNUM(MPENTRY_PADDR);
    pages[mpentry_i + 1].pp_link = pages[mpentry_i].pp_link;
f0100f85:	a1 90 1e 21 f0       	mov    0xf0211e90,%eax
f0100f8a:	8b 50 38             	mov    0x38(%eax),%edx
f0100f8d:	89 50 40             	mov    %edx,0x40(%eax)
    pages[mpentry_i].pp_link = NULL;
f0100f90:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)
}
f0100f97:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100f9a:	c9                   	leave  
f0100f9b:	c3                   	ret    

f0100f9c <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100f9c:	55                   	push   %ebp
f0100f9d:	89 e5                	mov    %esp,%ebp
f0100f9f:	53                   	push   %ebx
f0100fa0:	83 ec 04             	sub    $0x4,%esp
	//Fill this function in
	struct PageInfo *p = page_free_list;
f0100fa3:	8b 1d 40 12 21 f0    	mov    0xf0211240,%ebx
	if(p){
f0100fa9:	85 db                	test   %ebx,%ebx
f0100fab:	74 5c                	je     f0101009 <page_alloc+0x6d>
		page_free_list = p->pp_link;
f0100fad:	8b 03                	mov    (%ebx),%eax
f0100faf:	a3 40 12 21 f0       	mov    %eax,0xf0211240
		p->pp_link = NULL;
f0100fb4:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
		if(alloc_flags & ALLOC_ZERO){
			memset(page2kva(p), 0, PGSIZE);
		}
	}
	else return NULL;
	return p;
f0100fba:	89 d8                	mov    %ebx,%eax
	//Fill this function in
	struct PageInfo *p = page_free_list;
	if(p){
		page_free_list = p->pp_link;
		p->pp_link = NULL;
		if(alloc_flags & ALLOC_ZERO){
f0100fbc:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100fc0:	74 4c                	je     f010100e <page_alloc+0x72>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100fc2:	2b 05 90 1e 21 f0    	sub    0xf0211e90,%eax
f0100fc8:	c1 f8 03             	sar    $0x3,%eax
f0100fcb:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100fce:	89 c2                	mov    %eax,%edx
f0100fd0:	c1 ea 0c             	shr    $0xc,%edx
f0100fd3:	3b 15 88 1e 21 f0    	cmp    0xf0211e88,%edx
f0100fd9:	72 12                	jb     f0100fed <page_alloc+0x51>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100fdb:	50                   	push   %eax
f0100fdc:	68 84 60 10 f0       	push   $0xf0106084
f0100fe1:	6a 58                	push   $0x58
f0100fe3:	68 70 6f 10 f0       	push   $0xf0106f70
f0100fe8:	e8 53 f0 ff ff       	call   f0100040 <_panic>
			memset(page2kva(p), 0, PGSIZE);
f0100fed:	83 ec 04             	sub    $0x4,%esp
f0100ff0:	68 00 10 00 00       	push   $0x1000
f0100ff5:	6a 00                	push   $0x0
f0100ff7:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100ffc:	50                   	push   %eax
f0100ffd:	e8 b1 43 00 00       	call   f01053b3 <memset>
f0101002:	83 c4 10             	add    $0x10,%esp
		}
	}
	else return NULL;
	return p;
f0101005:	89 d8                	mov    %ebx,%eax
f0101007:	eb 05                	jmp    f010100e <page_alloc+0x72>
		p->pp_link = NULL;
		if(alloc_flags & ALLOC_ZERO){
			memset(page2kva(p), 0, PGSIZE);
		}
	}
	else return NULL;
f0101009:	b8 00 00 00 00       	mov    $0x0,%eax
	return p;
}
f010100e:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101011:	c9                   	leave  
f0101012:	c3                   	ret    

f0101013 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0101013:	55                   	push   %ebp
f0101014:	89 e5                	mov    %esp,%ebp
f0101016:	83 ec 08             	sub    $0x8,%esp
f0101019:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
	if(pp->pp_ref != 0 || pp->pp_link!=NULL){
f010101c:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0101021:	75 05                	jne    f0101028 <page_free+0x15>
f0101023:	83 38 00             	cmpl   $0x0,(%eax)
f0101026:	74 17                	je     f010103f <page_free+0x2c>
		panic("pp->pp_ref is nonzero or pp->pp_link is not NULL\n");
f0101028:	83 ec 04             	sub    $0x4,%esp
f010102b:	68 bc 66 10 f0       	push   $0xf01066bc
f0101030:	68 82 01 00 00       	push   $0x182
f0101035:	68 55 6f 10 f0       	push   $0xf0106f55
f010103a:	e8 01 f0 ff ff       	call   f0100040 <_panic>
	}
	pp->pp_link = page_free_list;
f010103f:	8b 15 40 12 21 f0    	mov    0xf0211240,%edx
f0101045:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f0101047:	a3 40 12 21 f0       	mov    %eax,0xf0211240


}
f010104c:	c9                   	leave  
f010104d:	c3                   	ret    

f010104e <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f010104e:	55                   	push   %ebp
f010104f:	89 e5                	mov    %esp,%ebp
f0101051:	83 ec 08             	sub    $0x8,%esp
f0101054:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0101057:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f010105b:	83 e8 01             	sub    $0x1,%eax
f010105e:	66 89 42 04          	mov    %ax,0x4(%edx)
f0101062:	66 85 c0             	test   %ax,%ax
f0101065:	75 0c                	jne    f0101073 <page_decref+0x25>
		page_free(pp);
f0101067:	83 ec 0c             	sub    $0xc,%esp
f010106a:	52                   	push   %edx
f010106b:	e8 a3 ff ff ff       	call   f0101013 <page_free>
f0101070:	83 c4 10             	add    $0x10,%esp
}
f0101073:	c9                   	leave  
f0101074:	c3                   	ret    

f0101075 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0101075:	55                   	push   %ebp
f0101076:	89 e5                	mov    %esp,%ebp
f0101078:	56                   	push   %esi
f0101079:	53                   	push   %ebx
f010107a:	8b 75 0c             	mov    0xc(%ebp),%esi
	int pdr_i = PDX(va);
	pde_t *pde = &pgdir[pdr_i];
f010107d:	89 f3                	mov    %esi,%ebx
f010107f:	c1 eb 16             	shr    $0x16,%ebx
f0101082:	c1 e3 02             	shl    $0x2,%ebx
f0101085:	03 5d 08             	add    0x8(%ebp),%ebx
	pte_t *pgt;
	if(!(*pde & PTE_P)){
f0101088:	f6 03 01             	testb  $0x1,(%ebx)
f010108b:	75 2f                	jne    f01010bc <pgdir_walk+0x47>
		if(!create)	
f010108d:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0101091:	74 64                	je     f01010f7 <pgdir_walk+0x82>
			return NULL;
		struct PageInfo *page = page_alloc(ALLOC_ZERO);
f0101093:	83 ec 0c             	sub    $0xc,%esp
f0101096:	6a 01                	push   $0x1
f0101098:	e8 ff fe ff ff       	call   f0100f9c <page_alloc>
		if(page == NULL) return NULL;
f010109d:	83 c4 10             	add    $0x10,%esp
f01010a0:	85 c0                	test   %eax,%eax
f01010a2:	74 5a                	je     f01010fe <pgdir_walk+0x89>
		*pde = page2pa(page) | PTE_P | PTE_U | PTE_W;
f01010a4:	89 c2                	mov    %eax,%edx
f01010a6:	2b 15 90 1e 21 f0    	sub    0xf0211e90,%edx
f01010ac:	c1 fa 03             	sar    $0x3,%edx
f01010af:	c1 e2 0c             	shl    $0xc,%edx
f01010b2:	83 ca 07             	or     $0x7,%edx
f01010b5:	89 13                	mov    %edx,(%ebx)
		page->pp_ref ++;
f01010b7:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
	}
	pgt = KADDR(PTE_ADDR(*pde));
f01010bc:	8b 03                	mov    (%ebx),%eax
f01010be:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01010c3:	89 c2                	mov    %eax,%edx
f01010c5:	c1 ea 0c             	shr    $0xc,%edx
f01010c8:	3b 15 88 1e 21 f0    	cmp    0xf0211e88,%edx
f01010ce:	72 15                	jb     f01010e5 <pgdir_walk+0x70>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01010d0:	50                   	push   %eax
f01010d1:	68 84 60 10 f0       	push   $0xf0106084
f01010d6:	68 b9 01 00 00       	push   $0x1b9
f01010db:	68 55 6f 10 f0       	push   $0xf0106f55
f01010e0:	e8 5b ef ff ff       	call   f0100040 <_panic>
	
	return &pgt[PTX(va)];
f01010e5:	c1 ee 0a             	shr    $0xa,%esi
f01010e8:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f01010ee:	8d 84 30 00 00 00 f0 	lea    -0x10000000(%eax,%esi,1),%eax
f01010f5:	eb 0c                	jmp    f0101103 <pgdir_walk+0x8e>
	int pdr_i = PDX(va);
	pde_t *pde = &pgdir[pdr_i];
	pte_t *pgt;
	if(!(*pde & PTE_P)){
		if(!create)	
			return NULL;
f01010f7:	b8 00 00 00 00       	mov    $0x0,%eax
f01010fc:	eb 05                	jmp    f0101103 <pgdir_walk+0x8e>
		struct PageInfo *page = page_alloc(ALLOC_ZERO);
		if(page == NULL) return NULL;
f01010fe:	b8 00 00 00 00       	mov    $0x0,%eax
		page->pp_ref ++;
	}
	pgt = KADDR(PTE_ADDR(*pde));
	
	return &pgt[PTX(va)];
}
f0101103:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0101106:	5b                   	pop    %ebx
f0101107:	5e                   	pop    %esi
f0101108:	5d                   	pop    %ebp
f0101109:	c3                   	ret    

f010110a <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f010110a:	55                   	push   %ebp
f010110b:	89 e5                	mov    %esp,%ebp
f010110d:	57                   	push   %edi
f010110e:	56                   	push   %esi
f010110f:	53                   	push   %ebx
f0101110:	83 ec 1c             	sub    $0x1c,%esp
f0101113:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0101116:	c1 e9 0c             	shr    $0xc,%ecx
f0101119:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	int i;
	for(i = 0; i < (size / PGSIZE); i++, va += PGSIZE, pa+=PGSIZE){
f010111c:	89 d3                	mov    %edx,%ebx
f010111e:	bf 00 00 00 00       	mov    $0x0,%edi
f0101123:	8b 45 08             	mov    0x8(%ebp),%eax
f0101126:	29 d0                	sub    %edx,%eax
f0101128:	89 45 e0             	mov    %eax,-0x20(%ebp)
		pte_t* pte = pgdir_walk(pgdir,(const void *) va, 1);	
		if(pte!=NULL){
			*pte = pa|perm|PTE_P;
f010112b:	8b 45 0c             	mov    0xc(%ebp),%eax
f010112e:	83 c8 01             	or     $0x1,%eax
f0101131:	89 45 d8             	mov    %eax,-0x28(%ebp)
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	int i;
	for(i = 0; i < (size / PGSIZE); i++, va += PGSIZE, pa+=PGSIZE){
f0101134:	eb 23                	jmp    f0101159 <boot_map_region+0x4f>
		pte_t* pte = pgdir_walk(pgdir,(const void *) va, 1);	
f0101136:	83 ec 04             	sub    $0x4,%esp
f0101139:	6a 01                	push   $0x1
f010113b:	53                   	push   %ebx
f010113c:	ff 75 dc             	pushl  -0x24(%ebp)
f010113f:	e8 31 ff ff ff       	call   f0101075 <pgdir_walk>
		if(pte!=NULL){
f0101144:	83 c4 10             	add    $0x10,%esp
f0101147:	85 c0                	test   %eax,%eax
f0101149:	74 05                	je     f0101150 <boot_map_region+0x46>
			*pte = pa|perm|PTE_P;
f010114b:	0b 75 d8             	or     -0x28(%ebp),%esi
f010114e:	89 30                	mov    %esi,(%eax)
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	int i;
	for(i = 0; i < (size / PGSIZE); i++, va += PGSIZE, pa+=PGSIZE){
f0101150:	83 c7 01             	add    $0x1,%edi
f0101153:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0101159:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010115c:	8d 34 18             	lea    (%eax,%ebx,1),%esi
f010115f:	3b 7d e4             	cmp    -0x1c(%ebp),%edi
f0101162:	75 d2                	jne    f0101136 <boot_map_region+0x2c>
		pte_t* pte = pgdir_walk(pgdir,(const void *) va, 1);	
		if(pte!=NULL){
			*pte = pa|perm|PTE_P;
		}
	}
}
f0101164:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101167:	5b                   	pop    %ebx
f0101168:	5e                   	pop    %esi
f0101169:	5f                   	pop    %edi
f010116a:	5d                   	pop    %ebp
f010116b:	c3                   	ret    

f010116c <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f010116c:	55                   	push   %ebp
f010116d:	89 e5                	mov    %esp,%ebp
f010116f:	53                   	push   %ebx
f0101170:	83 ec 08             	sub    $0x8,%esp
f0101173:	8b 5d 10             	mov    0x10(%ebp),%ebx
	pte_t *pte = pgdir_walk(pgdir, va, 0);
f0101176:	6a 00                	push   $0x0
f0101178:	ff 75 0c             	pushl  0xc(%ebp)
f010117b:	ff 75 08             	pushl  0x8(%ebp)
f010117e:	e8 f2 fe ff ff       	call   f0101075 <pgdir_walk>
	if(pte == NULL)
f0101183:	83 c4 10             	add    $0x10,%esp
f0101186:	85 c0                	test   %eax,%eax
f0101188:	74 32                	je     f01011bc <page_lookup+0x50>
		return NULL;
	else{
		if(pte_store!=NULL)		
f010118a:	85 db                	test   %ebx,%ebx
f010118c:	74 02                	je     f0101190 <page_lookup+0x24>
			*pte_store = pte;
f010118e:	89 03                	mov    %eax,(%ebx)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101190:	8b 00                	mov    (%eax),%eax
f0101192:	c1 e8 0c             	shr    $0xc,%eax
f0101195:	3b 05 88 1e 21 f0    	cmp    0xf0211e88,%eax
f010119b:	72 14                	jb     f01011b1 <page_lookup+0x45>
		panic("pa2page called with invalid pa");
f010119d:	83 ec 04             	sub    $0x4,%esp
f01011a0:	68 f0 66 10 f0       	push   $0xf01066f0
f01011a5:	6a 51                	push   $0x51
f01011a7:	68 70 6f 10 f0       	push   $0xf0106f70
f01011ac:	e8 8f ee ff ff       	call   f0100040 <_panic>
	return &pages[PGNUM(pa)];
f01011b1:	8b 15 90 1e 21 f0    	mov    0xf0211e90,%edx
f01011b7:	8d 04 c2             	lea    (%edx,%eax,8),%eax
		
		return pa2page(PTE_ADDR(*pte));
f01011ba:	eb 05                	jmp    f01011c1 <page_lookup+0x55>
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
	pte_t *pte = pgdir_walk(pgdir, va, 0);
	if(pte == NULL)
		return NULL;
f01011bc:	b8 00 00 00 00       	mov    $0x0,%eax
			*pte_store = pte;
		
		return pa2page(PTE_ADDR(*pte));
	}

}
f01011c1:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01011c4:	c9                   	leave  
f01011c5:	c3                   	ret    

f01011c6 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f01011c6:	55                   	push   %ebp
f01011c7:	89 e5                	mov    %esp,%ebp
f01011c9:	83 ec 08             	sub    $0x8,%esp
	// Flush the entry only if we're modifying the current address space.
	if (!curenv || curenv->env_pgdir == pgdir)
f01011cc:	e8 05 48 00 00       	call   f01059d6 <cpunum>
f01011d1:	6b c0 74             	imul   $0x74,%eax,%eax
f01011d4:	83 b8 28 20 21 f0 00 	cmpl   $0x0,-0xfdedfd8(%eax)
f01011db:	74 16                	je     f01011f3 <tlb_invalidate+0x2d>
f01011dd:	e8 f4 47 00 00       	call   f01059d6 <cpunum>
f01011e2:	6b c0 74             	imul   $0x74,%eax,%eax
f01011e5:	8b 80 28 20 21 f0    	mov    -0xfdedfd8(%eax),%eax
f01011eb:	8b 55 08             	mov    0x8(%ebp),%edx
f01011ee:	39 50 60             	cmp    %edx,0x60(%eax)
f01011f1:	75 06                	jne    f01011f9 <tlb_invalidate+0x33>
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01011f3:	8b 45 0c             	mov    0xc(%ebp),%eax
f01011f6:	0f 01 38             	invlpg (%eax)
		invlpg(va);
}
f01011f9:	c9                   	leave  
f01011fa:	c3                   	ret    

f01011fb <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f01011fb:	55                   	push   %ebp
f01011fc:	89 e5                	mov    %esp,%ebp
f01011fe:	56                   	push   %esi
f01011ff:	53                   	push   %ebx
f0101200:	83 ec 14             	sub    $0x14,%esp
f0101203:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0101206:	8b 75 0c             	mov    0xc(%ebp),%esi
	// Fill this function in
	pte_t *pte;
	struct PageInfo *pp = page_lookup(pgdir, va, &pte);
f0101209:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010120c:	50                   	push   %eax
f010120d:	56                   	push   %esi
f010120e:	53                   	push   %ebx
f010120f:	e8 58 ff ff ff       	call   f010116c <page_lookup>
	if(pp!=NULL){
f0101214:	83 c4 10             	add    $0x10,%esp
f0101217:	85 c0                	test   %eax,%eax
f0101219:	74 1f                	je     f010123a <page_remove+0x3f>
		page_decref(pp);
f010121b:	83 ec 0c             	sub    $0xc,%esp
f010121e:	50                   	push   %eax
f010121f:	e8 2a fe ff ff       	call   f010104e <page_decref>
		*pte = 0;
f0101224:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101227:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		tlb_invalidate(pgdir, va);
f010122d:	83 c4 08             	add    $0x8,%esp
f0101230:	56                   	push   %esi
f0101231:	53                   	push   %ebx
f0101232:	e8 8f ff ff ff       	call   f01011c6 <tlb_invalidate>
f0101237:	83 c4 10             	add    $0x10,%esp
	}
}
f010123a:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010123d:	5b                   	pop    %ebx
f010123e:	5e                   	pop    %esi
f010123f:	5d                   	pop    %ebp
f0101240:	c3                   	ret    

f0101241 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f0101241:	55                   	push   %ebp
f0101242:	89 e5                	mov    %esp,%ebp
f0101244:	57                   	push   %edi
f0101245:	56                   	push   %esi
f0101246:	53                   	push   %ebx
f0101247:	83 ec 10             	sub    $0x10,%esp
f010124a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010124d:	8b 7d 10             	mov    0x10(%ebp),%edi
	pte_t *pte = pgdir_walk(pgdir, va, 1); 
f0101250:	6a 01                	push   $0x1
f0101252:	57                   	push   %edi
f0101253:	ff 75 08             	pushl  0x8(%ebp)
f0101256:	e8 1a fe ff ff       	call   f0101075 <pgdir_walk>
	if(pte){
f010125b:	83 c4 10             	add    $0x10,%esp
f010125e:	85 c0                	test   %eax,%eax
f0101260:	74 4a                	je     f01012ac <page_insert+0x6b>
f0101262:	89 c6                	mov    %eax,%esi
		pp->pp_ref ++;
f0101264:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
		if(PTE_ADDR(*pte))
f0101269:	f7 00 00 f0 ff ff    	testl  $0xfffff000,(%eax)
f010126f:	74 0f                	je     f0101280 <page_insert+0x3f>
			page_remove(pgdir, va);
f0101271:	83 ec 08             	sub    $0x8,%esp
f0101274:	57                   	push   %edi
f0101275:	ff 75 08             	pushl  0x8(%ebp)
f0101278:	e8 7e ff ff ff       	call   f01011fb <page_remove>
f010127d:	83 c4 10             	add    $0x10,%esp
		*pte = page2pa(pp) | perm |PTE_P;
f0101280:	2b 1d 90 1e 21 f0    	sub    0xf0211e90,%ebx
f0101286:	c1 fb 03             	sar    $0x3,%ebx
f0101289:	c1 e3 0c             	shl    $0xc,%ebx
f010128c:	8b 45 14             	mov    0x14(%ebp),%eax
f010128f:	83 c8 01             	or     $0x1,%eax
f0101292:	09 c3                	or     %eax,%ebx
f0101294:	89 1e                	mov    %ebx,(%esi)
		tlb_invalidate(pgdir, va);
f0101296:	83 ec 08             	sub    $0x8,%esp
f0101299:	57                   	push   %edi
f010129a:	ff 75 08             	pushl  0x8(%ebp)
f010129d:	e8 24 ff ff ff       	call   f01011c6 <tlb_invalidate>
		return 0;
f01012a2:	83 c4 10             	add    $0x10,%esp
f01012a5:	b8 00 00 00 00       	mov    $0x0,%eax
f01012aa:	eb 05                	jmp    f01012b1 <page_insert+0x70>
	}
	return -E_NO_MEM;
f01012ac:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	
}
f01012b1:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01012b4:	5b                   	pop    %ebx
f01012b5:	5e                   	pop    %esi
f01012b6:	5f                   	pop    %edi
f01012b7:	5d                   	pop    %ebp
f01012b8:	c3                   	ret    

f01012b9 <mmio_map_region>:
// location.  Return the base of the reserved region.  size does *not*
// have to be multiple of PGSIZE.
//
void *
mmio_map_region(physaddr_t pa, size_t size)
{
f01012b9:	55                   	push   %ebp
f01012ba:	89 e5                	mov    %esp,%ebp
f01012bc:	53                   	push   %ebx
f01012bd:	83 ec 04             	sub    $0x4,%esp
	// okay to simply panic if this happens).
	//
	// Hint: The staff solution uses boot_map_region.
	//
	// Your code here:
    size = ROUNDUP(size, PGSIZE);
f01012c0:	8b 45 0c             	mov    0xc(%ebp),%eax
f01012c3:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
f01012c9:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
    if(base + size > MMIOLIM){
f01012cf:	8b 15 00 03 12 f0    	mov    0xf0120300,%edx
f01012d5:	8d 04 13             	lea    (%ebx,%edx,1),%eax
f01012d8:	3d 00 00 c0 ef       	cmp    $0xefc00000,%eax
f01012dd:	76 17                	jbe    f01012f6 <mmio_map_region+0x3d>
        panic("mmio_map_region: reservation mem overflow");
f01012df:	83 ec 04             	sub    $0x4,%esp
f01012e2:	68 10 67 10 f0       	push   $0xf0106710
f01012e7:	68 62 02 00 00       	push   $0x262
f01012ec:	68 55 6f 10 f0       	push   $0xf0106f55
f01012f1:	e8 4a ed ff ff       	call   f0100040 <_panic>
    }
    boot_map_region(kern_pgdir, base, size, pa, PTE_W | PTE_PCD | PTE_P);
f01012f6:	83 ec 08             	sub    $0x8,%esp
f01012f9:	6a 13                	push   $0x13
f01012fb:	ff 75 08             	pushl  0x8(%ebp)
f01012fe:	89 d9                	mov    %ebx,%ecx
f0101300:	a1 8c 1e 21 f0       	mov    0xf0211e8c,%eax
f0101305:	e8 00 fe ff ff       	call   f010110a <boot_map_region>
    uintptr_t b = base;
f010130a:	a1 00 03 12 f0       	mov    0xf0120300,%eax
    base += size;
f010130f:	01 c3                	add    %eax,%ebx
f0101311:	89 1d 00 03 12 f0    	mov    %ebx,0xf0120300
    return (void *) b;
    //panic("mmio_map_region not implemented");
}
f0101317:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010131a:	c9                   	leave  
f010131b:	c3                   	ret    

f010131c <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f010131c:	55                   	push   %ebp
f010131d:	89 e5                	mov    %esp,%ebp
f010131f:	57                   	push   %edi
f0101320:	56                   	push   %esi
f0101321:	53                   	push   %ebx
f0101322:	83 ec 3c             	sub    $0x3c,%esp
{
	size_t basemem, extmem, ext16mem, totalmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	basemem = nvram_read(NVRAM_BASELO);
f0101325:	b8 15 00 00 00       	mov    $0x15,%eax
f010132a:	e8 52 f7 ff ff       	call   f0100a81 <nvram_read>
f010132f:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f0101331:	b8 17 00 00 00       	mov    $0x17,%eax
f0101336:	e8 46 f7 ff ff       	call   f0100a81 <nvram_read>
f010133b:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f010133d:	b8 34 00 00 00       	mov    $0x34,%eax
f0101342:	e8 3a f7 ff ff       	call   f0100a81 <nvram_read>
f0101347:	c1 e0 06             	shl    $0x6,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (ext16mem)
f010134a:	85 c0                	test   %eax,%eax
f010134c:	74 07                	je     f0101355 <mem_init+0x39>
		totalmem = 16 * 1024 + ext16mem;
f010134e:	05 00 40 00 00       	add    $0x4000,%eax
f0101353:	eb 0b                	jmp    f0101360 <mem_init+0x44>
	else if (extmem)
		totalmem = 1 * 1024 + extmem;
f0101355:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f010135b:	85 f6                	test   %esi,%esi
f010135d:	0f 44 c3             	cmove  %ebx,%eax
	else
		totalmem = basemem;

	npages = totalmem / (PGSIZE / 1024);
f0101360:	89 c2                	mov    %eax,%edx
f0101362:	c1 ea 02             	shr    $0x2,%edx
f0101365:	89 15 88 1e 21 f0    	mov    %edx,0xf0211e88
	npages_basemem = basemem / (PGSIZE / 1024);

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f010136b:	89 c2                	mov    %eax,%edx
f010136d:	29 da                	sub    %ebx,%edx
f010136f:	52                   	push   %edx
f0101370:	53                   	push   %ebx
f0101371:	50                   	push   %eax
f0101372:	68 3c 67 10 f0       	push   $0xf010673c
f0101377:	e8 b2 22 00 00       	call   f010362e <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f010137c:	b8 00 10 00 00       	mov    $0x1000,%eax
f0101381:	e8 88 f7 ff ff       	call   f0100b0e <boot_alloc>
f0101386:	a3 8c 1e 21 f0       	mov    %eax,0xf0211e8c
	memset(kern_pgdir, 0, PGSIZE);
f010138b:	83 c4 0c             	add    $0xc,%esp
f010138e:	68 00 10 00 00       	push   $0x1000
f0101393:	6a 00                	push   $0x0
f0101395:	50                   	push   %eax
f0101396:	e8 18 40 00 00       	call   f01053b3 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f010139b:	a1 8c 1e 21 f0       	mov    0xf0211e8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01013a0:	83 c4 10             	add    $0x10,%esp
f01013a3:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01013a8:	77 15                	ja     f01013bf <mem_init+0xa3>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01013aa:	50                   	push   %eax
f01013ab:	68 a8 60 10 f0       	push   $0xf01060a8
f01013b0:	68 96 00 00 00       	push   $0x96
f01013b5:	68 55 6f 10 f0       	push   $0xf0106f55
f01013ba:	e8 81 ec ff ff       	call   f0100040 <_panic>
f01013bf:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01013c5:	83 ca 05             	or     $0x5,%edx
f01013c8:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	pages = (struct PageInfo *) boot_alloc(npages * sizeof(struct PageInfo));
f01013ce:	a1 88 1e 21 f0       	mov    0xf0211e88,%eax
f01013d3:	c1 e0 03             	shl    $0x3,%eax
f01013d6:	e8 33 f7 ff ff       	call   f0100b0e <boot_alloc>
f01013db:	a3 90 1e 21 f0       	mov    %eax,0xf0211e90
	memset(pages, 0, npages * sizeof(struct PageInfo));
f01013e0:	83 ec 04             	sub    $0x4,%esp
f01013e3:	8b 0d 88 1e 21 f0    	mov    0xf0211e88,%ecx
f01013e9:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f01013f0:	52                   	push   %edx
f01013f1:	6a 00                	push   $0x0
f01013f3:	50                   	push   %eax
f01013f4:	e8 ba 3f 00 00       	call   f01053b3 <memset>

	//////////////////////////////////////////////////////////////////////
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.
	envs = (struct Env *) boot_alloc(NENV * sizeof(struct Env));
f01013f9:	b8 00 f0 01 00       	mov    $0x1f000,%eax
f01013fe:	e8 0b f7 ff ff       	call   f0100b0e <boot_alloc>
f0101403:	a3 44 12 21 f0       	mov    %eax,0xf0211244
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f0101408:	e8 8a fa ff ff       	call   f0100e97 <page_init>

	check_page_free_list(1);
f010140d:	b8 01 00 00 00       	mov    $0x1,%eax
f0101412:	e8 7e f7 ff ff       	call   f0100b95 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f0101417:	83 c4 10             	add    $0x10,%esp
f010141a:	83 3d 90 1e 21 f0 00 	cmpl   $0x0,0xf0211e90
f0101421:	75 17                	jne    f010143a <mem_init+0x11e>
		panic("'pages' is a null pointer!");
f0101423:	83 ec 04             	sub    $0x4,%esp
f0101426:	68 37 70 10 f0       	push   $0xf0107037
f010142b:	68 f9 02 00 00       	push   $0x2f9
f0101430:	68 55 6f 10 f0       	push   $0xf0106f55
f0101435:	e8 06 ec ff ff       	call   f0100040 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010143a:	a1 40 12 21 f0       	mov    0xf0211240,%eax
f010143f:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101444:	eb 05                	jmp    f010144b <mem_init+0x12f>
		++nfree;
f0101446:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101449:	8b 00                	mov    (%eax),%eax
f010144b:	85 c0                	test   %eax,%eax
f010144d:	75 f7                	jne    f0101446 <mem_init+0x12a>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010144f:	83 ec 0c             	sub    $0xc,%esp
f0101452:	6a 00                	push   $0x0
f0101454:	e8 43 fb ff ff       	call   f0100f9c <page_alloc>
f0101459:	89 c7                	mov    %eax,%edi
f010145b:	83 c4 10             	add    $0x10,%esp
f010145e:	85 c0                	test   %eax,%eax
f0101460:	75 19                	jne    f010147b <mem_init+0x15f>
f0101462:	68 52 70 10 f0       	push   $0xf0107052
f0101467:	68 8a 6f 10 f0       	push   $0xf0106f8a
f010146c:	68 01 03 00 00       	push   $0x301
f0101471:	68 55 6f 10 f0       	push   $0xf0106f55
f0101476:	e8 c5 eb ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f010147b:	83 ec 0c             	sub    $0xc,%esp
f010147e:	6a 00                	push   $0x0
f0101480:	e8 17 fb ff ff       	call   f0100f9c <page_alloc>
f0101485:	89 c6                	mov    %eax,%esi
f0101487:	83 c4 10             	add    $0x10,%esp
f010148a:	85 c0                	test   %eax,%eax
f010148c:	75 19                	jne    f01014a7 <mem_init+0x18b>
f010148e:	68 68 70 10 f0       	push   $0xf0107068
f0101493:	68 8a 6f 10 f0       	push   $0xf0106f8a
f0101498:	68 02 03 00 00       	push   $0x302
f010149d:	68 55 6f 10 f0       	push   $0xf0106f55
f01014a2:	e8 99 eb ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f01014a7:	83 ec 0c             	sub    $0xc,%esp
f01014aa:	6a 00                	push   $0x0
f01014ac:	e8 eb fa ff ff       	call   f0100f9c <page_alloc>
f01014b1:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01014b4:	83 c4 10             	add    $0x10,%esp
f01014b7:	85 c0                	test   %eax,%eax
f01014b9:	75 19                	jne    f01014d4 <mem_init+0x1b8>
f01014bb:	68 7e 70 10 f0       	push   $0xf010707e
f01014c0:	68 8a 6f 10 f0       	push   $0xf0106f8a
f01014c5:	68 03 03 00 00       	push   $0x303
f01014ca:	68 55 6f 10 f0       	push   $0xf0106f55
f01014cf:	e8 6c eb ff ff       	call   f0100040 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01014d4:	39 f7                	cmp    %esi,%edi
f01014d6:	75 19                	jne    f01014f1 <mem_init+0x1d5>
f01014d8:	68 94 70 10 f0       	push   $0xf0107094
f01014dd:	68 8a 6f 10 f0       	push   $0xf0106f8a
f01014e2:	68 06 03 00 00       	push   $0x306
f01014e7:	68 55 6f 10 f0       	push   $0xf0106f55
f01014ec:	e8 4f eb ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01014f1:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01014f4:	39 c6                	cmp    %eax,%esi
f01014f6:	74 04                	je     f01014fc <mem_init+0x1e0>
f01014f8:	39 c7                	cmp    %eax,%edi
f01014fa:	75 19                	jne    f0101515 <mem_init+0x1f9>
f01014fc:	68 78 67 10 f0       	push   $0xf0106778
f0101501:	68 8a 6f 10 f0       	push   $0xf0106f8a
f0101506:	68 07 03 00 00       	push   $0x307
f010150b:	68 55 6f 10 f0       	push   $0xf0106f55
f0101510:	e8 2b eb ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101515:	8b 0d 90 1e 21 f0    	mov    0xf0211e90,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f010151b:	8b 15 88 1e 21 f0    	mov    0xf0211e88,%edx
f0101521:	c1 e2 0c             	shl    $0xc,%edx
f0101524:	89 f8                	mov    %edi,%eax
f0101526:	29 c8                	sub    %ecx,%eax
f0101528:	c1 f8 03             	sar    $0x3,%eax
f010152b:	c1 e0 0c             	shl    $0xc,%eax
f010152e:	39 d0                	cmp    %edx,%eax
f0101530:	72 19                	jb     f010154b <mem_init+0x22f>
f0101532:	68 a6 70 10 f0       	push   $0xf01070a6
f0101537:	68 8a 6f 10 f0       	push   $0xf0106f8a
f010153c:	68 08 03 00 00       	push   $0x308
f0101541:	68 55 6f 10 f0       	push   $0xf0106f55
f0101546:	e8 f5 ea ff ff       	call   f0100040 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f010154b:	89 f0                	mov    %esi,%eax
f010154d:	29 c8                	sub    %ecx,%eax
f010154f:	c1 f8 03             	sar    $0x3,%eax
f0101552:	c1 e0 0c             	shl    $0xc,%eax
f0101555:	39 c2                	cmp    %eax,%edx
f0101557:	77 19                	ja     f0101572 <mem_init+0x256>
f0101559:	68 c3 70 10 f0       	push   $0xf01070c3
f010155e:	68 8a 6f 10 f0       	push   $0xf0106f8a
f0101563:	68 09 03 00 00       	push   $0x309
f0101568:	68 55 6f 10 f0       	push   $0xf0106f55
f010156d:	e8 ce ea ff ff       	call   f0100040 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f0101572:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101575:	29 c8                	sub    %ecx,%eax
f0101577:	c1 f8 03             	sar    $0x3,%eax
f010157a:	c1 e0 0c             	shl    $0xc,%eax
f010157d:	39 c2                	cmp    %eax,%edx
f010157f:	77 19                	ja     f010159a <mem_init+0x27e>
f0101581:	68 e0 70 10 f0       	push   $0xf01070e0
f0101586:	68 8a 6f 10 f0       	push   $0xf0106f8a
f010158b:	68 0a 03 00 00       	push   $0x30a
f0101590:	68 55 6f 10 f0       	push   $0xf0106f55
f0101595:	e8 a6 ea ff ff       	call   f0100040 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f010159a:	a1 40 12 21 f0       	mov    0xf0211240,%eax
f010159f:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01015a2:	c7 05 40 12 21 f0 00 	movl   $0x0,0xf0211240
f01015a9:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01015ac:	83 ec 0c             	sub    $0xc,%esp
f01015af:	6a 00                	push   $0x0
f01015b1:	e8 e6 f9 ff ff       	call   f0100f9c <page_alloc>
f01015b6:	83 c4 10             	add    $0x10,%esp
f01015b9:	85 c0                	test   %eax,%eax
f01015bb:	74 19                	je     f01015d6 <mem_init+0x2ba>
f01015bd:	68 fd 70 10 f0       	push   $0xf01070fd
f01015c2:	68 8a 6f 10 f0       	push   $0xf0106f8a
f01015c7:	68 11 03 00 00       	push   $0x311
f01015cc:	68 55 6f 10 f0       	push   $0xf0106f55
f01015d1:	e8 6a ea ff ff       	call   f0100040 <_panic>

	// free and re-allocate?
	page_free(pp0);
f01015d6:	83 ec 0c             	sub    $0xc,%esp
f01015d9:	57                   	push   %edi
f01015da:	e8 34 fa ff ff       	call   f0101013 <page_free>
	page_free(pp1);
f01015df:	89 34 24             	mov    %esi,(%esp)
f01015e2:	e8 2c fa ff ff       	call   f0101013 <page_free>
	page_free(pp2);
f01015e7:	83 c4 04             	add    $0x4,%esp
f01015ea:	ff 75 d4             	pushl  -0x2c(%ebp)
f01015ed:	e8 21 fa ff ff       	call   f0101013 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01015f2:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01015f9:	e8 9e f9 ff ff       	call   f0100f9c <page_alloc>
f01015fe:	89 c6                	mov    %eax,%esi
f0101600:	83 c4 10             	add    $0x10,%esp
f0101603:	85 c0                	test   %eax,%eax
f0101605:	75 19                	jne    f0101620 <mem_init+0x304>
f0101607:	68 52 70 10 f0       	push   $0xf0107052
f010160c:	68 8a 6f 10 f0       	push   $0xf0106f8a
f0101611:	68 18 03 00 00       	push   $0x318
f0101616:	68 55 6f 10 f0       	push   $0xf0106f55
f010161b:	e8 20 ea ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0101620:	83 ec 0c             	sub    $0xc,%esp
f0101623:	6a 00                	push   $0x0
f0101625:	e8 72 f9 ff ff       	call   f0100f9c <page_alloc>
f010162a:	89 c7                	mov    %eax,%edi
f010162c:	83 c4 10             	add    $0x10,%esp
f010162f:	85 c0                	test   %eax,%eax
f0101631:	75 19                	jne    f010164c <mem_init+0x330>
f0101633:	68 68 70 10 f0       	push   $0xf0107068
f0101638:	68 8a 6f 10 f0       	push   $0xf0106f8a
f010163d:	68 19 03 00 00       	push   $0x319
f0101642:	68 55 6f 10 f0       	push   $0xf0106f55
f0101647:	e8 f4 e9 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f010164c:	83 ec 0c             	sub    $0xc,%esp
f010164f:	6a 00                	push   $0x0
f0101651:	e8 46 f9 ff ff       	call   f0100f9c <page_alloc>
f0101656:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101659:	83 c4 10             	add    $0x10,%esp
f010165c:	85 c0                	test   %eax,%eax
f010165e:	75 19                	jne    f0101679 <mem_init+0x35d>
f0101660:	68 7e 70 10 f0       	push   $0xf010707e
f0101665:	68 8a 6f 10 f0       	push   $0xf0106f8a
f010166a:	68 1a 03 00 00       	push   $0x31a
f010166f:	68 55 6f 10 f0       	push   $0xf0106f55
f0101674:	e8 c7 e9 ff ff       	call   f0100040 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101679:	39 fe                	cmp    %edi,%esi
f010167b:	75 19                	jne    f0101696 <mem_init+0x37a>
f010167d:	68 94 70 10 f0       	push   $0xf0107094
f0101682:	68 8a 6f 10 f0       	push   $0xf0106f8a
f0101687:	68 1c 03 00 00       	push   $0x31c
f010168c:	68 55 6f 10 f0       	push   $0xf0106f55
f0101691:	e8 aa e9 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101696:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101699:	39 c7                	cmp    %eax,%edi
f010169b:	74 04                	je     f01016a1 <mem_init+0x385>
f010169d:	39 c6                	cmp    %eax,%esi
f010169f:	75 19                	jne    f01016ba <mem_init+0x39e>
f01016a1:	68 78 67 10 f0       	push   $0xf0106778
f01016a6:	68 8a 6f 10 f0       	push   $0xf0106f8a
f01016ab:	68 1d 03 00 00       	push   $0x31d
f01016b0:	68 55 6f 10 f0       	push   $0xf0106f55
f01016b5:	e8 86 e9 ff ff       	call   f0100040 <_panic>
	assert(!page_alloc(0));
f01016ba:	83 ec 0c             	sub    $0xc,%esp
f01016bd:	6a 00                	push   $0x0
f01016bf:	e8 d8 f8 ff ff       	call   f0100f9c <page_alloc>
f01016c4:	83 c4 10             	add    $0x10,%esp
f01016c7:	85 c0                	test   %eax,%eax
f01016c9:	74 19                	je     f01016e4 <mem_init+0x3c8>
f01016cb:	68 fd 70 10 f0       	push   $0xf01070fd
f01016d0:	68 8a 6f 10 f0       	push   $0xf0106f8a
f01016d5:	68 1e 03 00 00       	push   $0x31e
f01016da:	68 55 6f 10 f0       	push   $0xf0106f55
f01016df:	e8 5c e9 ff ff       	call   f0100040 <_panic>
f01016e4:	89 f0                	mov    %esi,%eax
f01016e6:	2b 05 90 1e 21 f0    	sub    0xf0211e90,%eax
f01016ec:	c1 f8 03             	sar    $0x3,%eax
f01016ef:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01016f2:	89 c2                	mov    %eax,%edx
f01016f4:	c1 ea 0c             	shr    $0xc,%edx
f01016f7:	3b 15 88 1e 21 f0    	cmp    0xf0211e88,%edx
f01016fd:	72 12                	jb     f0101711 <mem_init+0x3f5>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01016ff:	50                   	push   %eax
f0101700:	68 84 60 10 f0       	push   $0xf0106084
f0101705:	6a 58                	push   $0x58
f0101707:	68 70 6f 10 f0       	push   $0xf0106f70
f010170c:	e8 2f e9 ff ff       	call   f0100040 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f0101711:	83 ec 04             	sub    $0x4,%esp
f0101714:	68 00 10 00 00       	push   $0x1000
f0101719:	6a 01                	push   $0x1
f010171b:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101720:	50                   	push   %eax
f0101721:	e8 8d 3c 00 00       	call   f01053b3 <memset>
	page_free(pp0);
f0101726:	89 34 24             	mov    %esi,(%esp)
f0101729:	e8 e5 f8 ff ff       	call   f0101013 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f010172e:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101735:	e8 62 f8 ff ff       	call   f0100f9c <page_alloc>
f010173a:	83 c4 10             	add    $0x10,%esp
f010173d:	85 c0                	test   %eax,%eax
f010173f:	75 19                	jne    f010175a <mem_init+0x43e>
f0101741:	68 0c 71 10 f0       	push   $0xf010710c
f0101746:	68 8a 6f 10 f0       	push   $0xf0106f8a
f010174b:	68 23 03 00 00       	push   $0x323
f0101750:	68 55 6f 10 f0       	push   $0xf0106f55
f0101755:	e8 e6 e8 ff ff       	call   f0100040 <_panic>
	assert(pp && pp0 == pp);
f010175a:	39 c6                	cmp    %eax,%esi
f010175c:	74 19                	je     f0101777 <mem_init+0x45b>
f010175e:	68 2a 71 10 f0       	push   $0xf010712a
f0101763:	68 8a 6f 10 f0       	push   $0xf0106f8a
f0101768:	68 24 03 00 00       	push   $0x324
f010176d:	68 55 6f 10 f0       	push   $0xf0106f55
f0101772:	e8 c9 e8 ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101777:	89 f0                	mov    %esi,%eax
f0101779:	2b 05 90 1e 21 f0    	sub    0xf0211e90,%eax
f010177f:	c1 f8 03             	sar    $0x3,%eax
f0101782:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101785:	89 c2                	mov    %eax,%edx
f0101787:	c1 ea 0c             	shr    $0xc,%edx
f010178a:	3b 15 88 1e 21 f0    	cmp    0xf0211e88,%edx
f0101790:	72 12                	jb     f01017a4 <mem_init+0x488>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101792:	50                   	push   %eax
f0101793:	68 84 60 10 f0       	push   $0xf0106084
f0101798:	6a 58                	push   $0x58
f010179a:	68 70 6f 10 f0       	push   $0xf0106f70
f010179f:	e8 9c e8 ff ff       	call   f0100040 <_panic>
f01017a4:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f01017aa:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f01017b0:	80 38 00             	cmpb   $0x0,(%eax)
f01017b3:	74 19                	je     f01017ce <mem_init+0x4b2>
f01017b5:	68 3a 71 10 f0       	push   $0xf010713a
f01017ba:	68 8a 6f 10 f0       	push   $0xf0106f8a
f01017bf:	68 27 03 00 00       	push   $0x327
f01017c4:	68 55 6f 10 f0       	push   $0xf0106f55
f01017c9:	e8 72 e8 ff ff       	call   f0100040 <_panic>
f01017ce:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f01017d1:	39 d0                	cmp    %edx,%eax
f01017d3:	75 db                	jne    f01017b0 <mem_init+0x494>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f01017d5:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01017d8:	a3 40 12 21 f0       	mov    %eax,0xf0211240

	// free the pages we took
	page_free(pp0);
f01017dd:	83 ec 0c             	sub    $0xc,%esp
f01017e0:	56                   	push   %esi
f01017e1:	e8 2d f8 ff ff       	call   f0101013 <page_free>
	page_free(pp1);
f01017e6:	89 3c 24             	mov    %edi,(%esp)
f01017e9:	e8 25 f8 ff ff       	call   f0101013 <page_free>
	page_free(pp2);
f01017ee:	83 c4 04             	add    $0x4,%esp
f01017f1:	ff 75 d4             	pushl  -0x2c(%ebp)
f01017f4:	e8 1a f8 ff ff       	call   f0101013 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01017f9:	a1 40 12 21 f0       	mov    0xf0211240,%eax
f01017fe:	83 c4 10             	add    $0x10,%esp
f0101801:	eb 05                	jmp    f0101808 <mem_init+0x4ec>
		--nfree;
f0101803:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101806:	8b 00                	mov    (%eax),%eax
f0101808:	85 c0                	test   %eax,%eax
f010180a:	75 f7                	jne    f0101803 <mem_init+0x4e7>
		--nfree;
	assert(nfree == 0);
f010180c:	85 db                	test   %ebx,%ebx
f010180e:	74 19                	je     f0101829 <mem_init+0x50d>
f0101810:	68 44 71 10 f0       	push   $0xf0107144
f0101815:	68 8a 6f 10 f0       	push   $0xf0106f8a
f010181a:	68 34 03 00 00       	push   $0x334
f010181f:	68 55 6f 10 f0       	push   $0xf0106f55
f0101824:	e8 17 e8 ff ff       	call   f0100040 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f0101829:	83 ec 0c             	sub    $0xc,%esp
f010182c:	68 98 67 10 f0       	push   $0xf0106798
f0101831:	e8 f8 1d 00 00       	call   f010362e <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101836:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010183d:	e8 5a f7 ff ff       	call   f0100f9c <page_alloc>
f0101842:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101845:	83 c4 10             	add    $0x10,%esp
f0101848:	85 c0                	test   %eax,%eax
f010184a:	75 19                	jne    f0101865 <mem_init+0x549>
f010184c:	68 52 70 10 f0       	push   $0xf0107052
f0101851:	68 8a 6f 10 f0       	push   $0xf0106f8a
f0101856:	68 9a 03 00 00       	push   $0x39a
f010185b:	68 55 6f 10 f0       	push   $0xf0106f55
f0101860:	e8 db e7 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0101865:	83 ec 0c             	sub    $0xc,%esp
f0101868:	6a 00                	push   $0x0
f010186a:	e8 2d f7 ff ff       	call   f0100f9c <page_alloc>
f010186f:	89 c3                	mov    %eax,%ebx
f0101871:	83 c4 10             	add    $0x10,%esp
f0101874:	85 c0                	test   %eax,%eax
f0101876:	75 19                	jne    f0101891 <mem_init+0x575>
f0101878:	68 68 70 10 f0       	push   $0xf0107068
f010187d:	68 8a 6f 10 f0       	push   $0xf0106f8a
f0101882:	68 9b 03 00 00       	push   $0x39b
f0101887:	68 55 6f 10 f0       	push   $0xf0106f55
f010188c:	e8 af e7 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0101891:	83 ec 0c             	sub    $0xc,%esp
f0101894:	6a 00                	push   $0x0
f0101896:	e8 01 f7 ff ff       	call   f0100f9c <page_alloc>
f010189b:	89 c6                	mov    %eax,%esi
f010189d:	83 c4 10             	add    $0x10,%esp
f01018a0:	85 c0                	test   %eax,%eax
f01018a2:	75 19                	jne    f01018bd <mem_init+0x5a1>
f01018a4:	68 7e 70 10 f0       	push   $0xf010707e
f01018a9:	68 8a 6f 10 f0       	push   $0xf0106f8a
f01018ae:	68 9c 03 00 00       	push   $0x39c
f01018b3:	68 55 6f 10 f0       	push   $0xf0106f55
f01018b8:	e8 83 e7 ff ff       	call   f0100040 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01018bd:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f01018c0:	75 19                	jne    f01018db <mem_init+0x5bf>
f01018c2:	68 94 70 10 f0       	push   $0xf0107094
f01018c7:	68 8a 6f 10 f0       	push   $0xf0106f8a
f01018cc:	68 9f 03 00 00       	push   $0x39f
f01018d1:	68 55 6f 10 f0       	push   $0xf0106f55
f01018d6:	e8 65 e7 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01018db:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f01018de:	74 04                	je     f01018e4 <mem_init+0x5c8>
f01018e0:	39 c3                	cmp    %eax,%ebx
f01018e2:	75 19                	jne    f01018fd <mem_init+0x5e1>
f01018e4:	68 78 67 10 f0       	push   $0xf0106778
f01018e9:	68 8a 6f 10 f0       	push   $0xf0106f8a
f01018ee:	68 a0 03 00 00       	push   $0x3a0
f01018f3:	68 55 6f 10 f0       	push   $0xf0106f55
f01018f8:	e8 43 e7 ff ff       	call   f0100040 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01018fd:	a1 40 12 21 f0       	mov    0xf0211240,%eax
f0101902:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101905:	c7 05 40 12 21 f0 00 	movl   $0x0,0xf0211240
f010190c:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f010190f:	83 ec 0c             	sub    $0xc,%esp
f0101912:	6a 00                	push   $0x0
f0101914:	e8 83 f6 ff ff       	call   f0100f9c <page_alloc>
f0101919:	83 c4 10             	add    $0x10,%esp
f010191c:	85 c0                	test   %eax,%eax
f010191e:	74 19                	je     f0101939 <mem_init+0x61d>
f0101920:	68 fd 70 10 f0       	push   $0xf01070fd
f0101925:	68 8a 6f 10 f0       	push   $0xf0106f8a
f010192a:	68 a7 03 00 00       	push   $0x3a7
f010192f:	68 55 6f 10 f0       	push   $0xf0106f55
f0101934:	e8 07 e7 ff ff       	call   f0100040 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101939:	83 ec 04             	sub    $0x4,%esp
f010193c:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010193f:	50                   	push   %eax
f0101940:	6a 00                	push   $0x0
f0101942:	ff 35 8c 1e 21 f0    	pushl  0xf0211e8c
f0101948:	e8 1f f8 ff ff       	call   f010116c <page_lookup>
f010194d:	83 c4 10             	add    $0x10,%esp
f0101950:	85 c0                	test   %eax,%eax
f0101952:	74 19                	je     f010196d <mem_init+0x651>
f0101954:	68 b8 67 10 f0       	push   $0xf01067b8
f0101959:	68 8a 6f 10 f0       	push   $0xf0106f8a
f010195e:	68 aa 03 00 00       	push   $0x3aa
f0101963:	68 55 6f 10 f0       	push   $0xf0106f55
f0101968:	e8 d3 e6 ff ff       	call   f0100040 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f010196d:	6a 02                	push   $0x2
f010196f:	6a 00                	push   $0x0
f0101971:	53                   	push   %ebx
f0101972:	ff 35 8c 1e 21 f0    	pushl  0xf0211e8c
f0101978:	e8 c4 f8 ff ff       	call   f0101241 <page_insert>
f010197d:	83 c4 10             	add    $0x10,%esp
f0101980:	85 c0                	test   %eax,%eax
f0101982:	78 19                	js     f010199d <mem_init+0x681>
f0101984:	68 f0 67 10 f0       	push   $0xf01067f0
f0101989:	68 8a 6f 10 f0       	push   $0xf0106f8a
f010198e:	68 ad 03 00 00       	push   $0x3ad
f0101993:	68 55 6f 10 f0       	push   $0xf0106f55
f0101998:	e8 a3 e6 ff ff       	call   f0100040 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f010199d:	83 ec 0c             	sub    $0xc,%esp
f01019a0:	ff 75 d4             	pushl  -0x2c(%ebp)
f01019a3:	e8 6b f6 ff ff       	call   f0101013 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f01019a8:	6a 02                	push   $0x2
f01019aa:	6a 00                	push   $0x0
f01019ac:	53                   	push   %ebx
f01019ad:	ff 35 8c 1e 21 f0    	pushl  0xf0211e8c
f01019b3:	e8 89 f8 ff ff       	call   f0101241 <page_insert>
f01019b8:	83 c4 20             	add    $0x20,%esp
f01019bb:	85 c0                	test   %eax,%eax
f01019bd:	74 19                	je     f01019d8 <mem_init+0x6bc>
f01019bf:	68 20 68 10 f0       	push   $0xf0106820
f01019c4:	68 8a 6f 10 f0       	push   $0xf0106f8a
f01019c9:	68 b1 03 00 00       	push   $0x3b1
f01019ce:	68 55 6f 10 f0       	push   $0xf0106f55
f01019d3:	e8 68 e6 ff ff       	call   f0100040 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01019d8:	8b 3d 8c 1e 21 f0    	mov    0xf0211e8c,%edi
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01019de:	a1 90 1e 21 f0       	mov    0xf0211e90,%eax
f01019e3:	89 c1                	mov    %eax,%ecx
f01019e5:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01019e8:	8b 17                	mov    (%edi),%edx
f01019ea:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01019f0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01019f3:	29 c8                	sub    %ecx,%eax
f01019f5:	c1 f8 03             	sar    $0x3,%eax
f01019f8:	c1 e0 0c             	shl    $0xc,%eax
f01019fb:	39 c2                	cmp    %eax,%edx
f01019fd:	74 19                	je     f0101a18 <mem_init+0x6fc>
f01019ff:	68 50 68 10 f0       	push   $0xf0106850
f0101a04:	68 8a 6f 10 f0       	push   $0xf0106f8a
f0101a09:	68 b2 03 00 00       	push   $0x3b2
f0101a0e:	68 55 6f 10 f0       	push   $0xf0106f55
f0101a13:	e8 28 e6 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101a18:	ba 00 00 00 00       	mov    $0x0,%edx
f0101a1d:	89 f8                	mov    %edi,%eax
f0101a1f:	e8 86 f0 ff ff       	call   f0100aaa <check_va2pa>
f0101a24:	89 da                	mov    %ebx,%edx
f0101a26:	2b 55 cc             	sub    -0x34(%ebp),%edx
f0101a29:	c1 fa 03             	sar    $0x3,%edx
f0101a2c:	c1 e2 0c             	shl    $0xc,%edx
f0101a2f:	39 d0                	cmp    %edx,%eax
f0101a31:	74 19                	je     f0101a4c <mem_init+0x730>
f0101a33:	68 78 68 10 f0       	push   $0xf0106878
f0101a38:	68 8a 6f 10 f0       	push   $0xf0106f8a
f0101a3d:	68 b3 03 00 00       	push   $0x3b3
f0101a42:	68 55 6f 10 f0       	push   $0xf0106f55
f0101a47:	e8 f4 e5 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f0101a4c:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101a51:	74 19                	je     f0101a6c <mem_init+0x750>
f0101a53:	68 4f 71 10 f0       	push   $0xf010714f
f0101a58:	68 8a 6f 10 f0       	push   $0xf0106f8a
f0101a5d:	68 b4 03 00 00       	push   $0x3b4
f0101a62:	68 55 6f 10 f0       	push   $0xf0106f55
f0101a67:	e8 d4 e5 ff ff       	call   f0100040 <_panic>
	assert(pp0->pp_ref == 1);
f0101a6c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a6f:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101a74:	74 19                	je     f0101a8f <mem_init+0x773>
f0101a76:	68 60 71 10 f0       	push   $0xf0107160
f0101a7b:	68 8a 6f 10 f0       	push   $0xf0106f8a
f0101a80:	68 b5 03 00 00       	push   $0x3b5
f0101a85:	68 55 6f 10 f0       	push   $0xf0106f55
f0101a8a:	e8 b1 e5 ff ff       	call   f0100040 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101a8f:	6a 02                	push   $0x2
f0101a91:	68 00 10 00 00       	push   $0x1000
f0101a96:	56                   	push   %esi
f0101a97:	57                   	push   %edi
f0101a98:	e8 a4 f7 ff ff       	call   f0101241 <page_insert>
f0101a9d:	83 c4 10             	add    $0x10,%esp
f0101aa0:	85 c0                	test   %eax,%eax
f0101aa2:	74 19                	je     f0101abd <mem_init+0x7a1>
f0101aa4:	68 a8 68 10 f0       	push   $0xf01068a8
f0101aa9:	68 8a 6f 10 f0       	push   $0xf0106f8a
f0101aae:	68 b8 03 00 00       	push   $0x3b8
f0101ab3:	68 55 6f 10 f0       	push   $0xf0106f55
f0101ab8:	e8 83 e5 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101abd:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101ac2:	a1 8c 1e 21 f0       	mov    0xf0211e8c,%eax
f0101ac7:	e8 de ef ff ff       	call   f0100aaa <check_va2pa>
f0101acc:	89 f2                	mov    %esi,%edx
f0101ace:	2b 15 90 1e 21 f0    	sub    0xf0211e90,%edx
f0101ad4:	c1 fa 03             	sar    $0x3,%edx
f0101ad7:	c1 e2 0c             	shl    $0xc,%edx
f0101ada:	39 d0                	cmp    %edx,%eax
f0101adc:	74 19                	je     f0101af7 <mem_init+0x7db>
f0101ade:	68 e4 68 10 f0       	push   $0xf01068e4
f0101ae3:	68 8a 6f 10 f0       	push   $0xf0106f8a
f0101ae8:	68 b9 03 00 00       	push   $0x3b9
f0101aed:	68 55 6f 10 f0       	push   $0xf0106f55
f0101af2:	e8 49 e5 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101af7:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101afc:	74 19                	je     f0101b17 <mem_init+0x7fb>
f0101afe:	68 71 71 10 f0       	push   $0xf0107171
f0101b03:	68 8a 6f 10 f0       	push   $0xf0106f8a
f0101b08:	68 ba 03 00 00       	push   $0x3ba
f0101b0d:	68 55 6f 10 f0       	push   $0xf0106f55
f0101b12:	e8 29 e5 ff ff       	call   f0100040 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101b17:	83 ec 0c             	sub    $0xc,%esp
f0101b1a:	6a 00                	push   $0x0
f0101b1c:	e8 7b f4 ff ff       	call   f0100f9c <page_alloc>
f0101b21:	83 c4 10             	add    $0x10,%esp
f0101b24:	85 c0                	test   %eax,%eax
f0101b26:	74 19                	je     f0101b41 <mem_init+0x825>
f0101b28:	68 fd 70 10 f0       	push   $0xf01070fd
f0101b2d:	68 8a 6f 10 f0       	push   $0xf0106f8a
f0101b32:	68 bd 03 00 00       	push   $0x3bd
f0101b37:	68 55 6f 10 f0       	push   $0xf0106f55
f0101b3c:	e8 ff e4 ff ff       	call   f0100040 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101b41:	6a 02                	push   $0x2
f0101b43:	68 00 10 00 00       	push   $0x1000
f0101b48:	56                   	push   %esi
f0101b49:	ff 35 8c 1e 21 f0    	pushl  0xf0211e8c
f0101b4f:	e8 ed f6 ff ff       	call   f0101241 <page_insert>
f0101b54:	83 c4 10             	add    $0x10,%esp
f0101b57:	85 c0                	test   %eax,%eax
f0101b59:	74 19                	je     f0101b74 <mem_init+0x858>
f0101b5b:	68 a8 68 10 f0       	push   $0xf01068a8
f0101b60:	68 8a 6f 10 f0       	push   $0xf0106f8a
f0101b65:	68 c0 03 00 00       	push   $0x3c0
f0101b6a:	68 55 6f 10 f0       	push   $0xf0106f55
f0101b6f:	e8 cc e4 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101b74:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101b79:	a1 8c 1e 21 f0       	mov    0xf0211e8c,%eax
f0101b7e:	e8 27 ef ff ff       	call   f0100aaa <check_va2pa>
f0101b83:	89 f2                	mov    %esi,%edx
f0101b85:	2b 15 90 1e 21 f0    	sub    0xf0211e90,%edx
f0101b8b:	c1 fa 03             	sar    $0x3,%edx
f0101b8e:	c1 e2 0c             	shl    $0xc,%edx
f0101b91:	39 d0                	cmp    %edx,%eax
f0101b93:	74 19                	je     f0101bae <mem_init+0x892>
f0101b95:	68 e4 68 10 f0       	push   $0xf01068e4
f0101b9a:	68 8a 6f 10 f0       	push   $0xf0106f8a
f0101b9f:	68 c1 03 00 00       	push   $0x3c1
f0101ba4:	68 55 6f 10 f0       	push   $0xf0106f55
f0101ba9:	e8 92 e4 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101bae:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101bb3:	74 19                	je     f0101bce <mem_init+0x8b2>
f0101bb5:	68 71 71 10 f0       	push   $0xf0107171
f0101bba:	68 8a 6f 10 f0       	push   $0xf0106f8a
f0101bbf:	68 c2 03 00 00       	push   $0x3c2
f0101bc4:	68 55 6f 10 f0       	push   $0xf0106f55
f0101bc9:	e8 72 e4 ff ff       	call   f0100040 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101bce:	83 ec 0c             	sub    $0xc,%esp
f0101bd1:	6a 00                	push   $0x0
f0101bd3:	e8 c4 f3 ff ff       	call   f0100f9c <page_alloc>
f0101bd8:	83 c4 10             	add    $0x10,%esp
f0101bdb:	85 c0                	test   %eax,%eax
f0101bdd:	74 19                	je     f0101bf8 <mem_init+0x8dc>
f0101bdf:	68 fd 70 10 f0       	push   $0xf01070fd
f0101be4:	68 8a 6f 10 f0       	push   $0xf0106f8a
f0101be9:	68 c6 03 00 00       	push   $0x3c6
f0101bee:	68 55 6f 10 f0       	push   $0xf0106f55
f0101bf3:	e8 48 e4 ff ff       	call   f0100040 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101bf8:	8b 15 8c 1e 21 f0    	mov    0xf0211e8c,%edx
f0101bfe:	8b 02                	mov    (%edx),%eax
f0101c00:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101c05:	89 c1                	mov    %eax,%ecx
f0101c07:	c1 e9 0c             	shr    $0xc,%ecx
f0101c0a:	3b 0d 88 1e 21 f0    	cmp    0xf0211e88,%ecx
f0101c10:	72 15                	jb     f0101c27 <mem_init+0x90b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101c12:	50                   	push   %eax
f0101c13:	68 84 60 10 f0       	push   $0xf0106084
f0101c18:	68 c9 03 00 00       	push   $0x3c9
f0101c1d:	68 55 6f 10 f0       	push   $0xf0106f55
f0101c22:	e8 19 e4 ff ff       	call   f0100040 <_panic>
f0101c27:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101c2c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101c2f:	83 ec 04             	sub    $0x4,%esp
f0101c32:	6a 00                	push   $0x0
f0101c34:	68 00 10 00 00       	push   $0x1000
f0101c39:	52                   	push   %edx
f0101c3a:	e8 36 f4 ff ff       	call   f0101075 <pgdir_walk>
f0101c3f:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101c42:	8d 51 04             	lea    0x4(%ecx),%edx
f0101c45:	83 c4 10             	add    $0x10,%esp
f0101c48:	39 d0                	cmp    %edx,%eax
f0101c4a:	74 19                	je     f0101c65 <mem_init+0x949>
f0101c4c:	68 14 69 10 f0       	push   $0xf0106914
f0101c51:	68 8a 6f 10 f0       	push   $0xf0106f8a
f0101c56:	68 ca 03 00 00       	push   $0x3ca
f0101c5b:	68 55 6f 10 f0       	push   $0xf0106f55
f0101c60:	e8 db e3 ff ff       	call   f0100040 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101c65:	6a 06                	push   $0x6
f0101c67:	68 00 10 00 00       	push   $0x1000
f0101c6c:	56                   	push   %esi
f0101c6d:	ff 35 8c 1e 21 f0    	pushl  0xf0211e8c
f0101c73:	e8 c9 f5 ff ff       	call   f0101241 <page_insert>
f0101c78:	83 c4 10             	add    $0x10,%esp
f0101c7b:	85 c0                	test   %eax,%eax
f0101c7d:	74 19                	je     f0101c98 <mem_init+0x97c>
f0101c7f:	68 54 69 10 f0       	push   $0xf0106954
f0101c84:	68 8a 6f 10 f0       	push   $0xf0106f8a
f0101c89:	68 cd 03 00 00       	push   $0x3cd
f0101c8e:	68 55 6f 10 f0       	push   $0xf0106f55
f0101c93:	e8 a8 e3 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101c98:	8b 3d 8c 1e 21 f0    	mov    0xf0211e8c,%edi
f0101c9e:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101ca3:	89 f8                	mov    %edi,%eax
f0101ca5:	e8 00 ee ff ff       	call   f0100aaa <check_va2pa>
f0101caa:	89 f2                	mov    %esi,%edx
f0101cac:	2b 15 90 1e 21 f0    	sub    0xf0211e90,%edx
f0101cb2:	c1 fa 03             	sar    $0x3,%edx
f0101cb5:	c1 e2 0c             	shl    $0xc,%edx
f0101cb8:	39 d0                	cmp    %edx,%eax
f0101cba:	74 19                	je     f0101cd5 <mem_init+0x9b9>
f0101cbc:	68 e4 68 10 f0       	push   $0xf01068e4
f0101cc1:	68 8a 6f 10 f0       	push   $0xf0106f8a
f0101cc6:	68 ce 03 00 00       	push   $0x3ce
f0101ccb:	68 55 6f 10 f0       	push   $0xf0106f55
f0101cd0:	e8 6b e3 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101cd5:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101cda:	74 19                	je     f0101cf5 <mem_init+0x9d9>
f0101cdc:	68 71 71 10 f0       	push   $0xf0107171
f0101ce1:	68 8a 6f 10 f0       	push   $0xf0106f8a
f0101ce6:	68 cf 03 00 00       	push   $0x3cf
f0101ceb:	68 55 6f 10 f0       	push   $0xf0106f55
f0101cf0:	e8 4b e3 ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101cf5:	83 ec 04             	sub    $0x4,%esp
f0101cf8:	6a 00                	push   $0x0
f0101cfa:	68 00 10 00 00       	push   $0x1000
f0101cff:	57                   	push   %edi
f0101d00:	e8 70 f3 ff ff       	call   f0101075 <pgdir_walk>
f0101d05:	83 c4 10             	add    $0x10,%esp
f0101d08:	f6 00 04             	testb  $0x4,(%eax)
f0101d0b:	75 19                	jne    f0101d26 <mem_init+0xa0a>
f0101d0d:	68 94 69 10 f0       	push   $0xf0106994
f0101d12:	68 8a 6f 10 f0       	push   $0xf0106f8a
f0101d17:	68 d0 03 00 00       	push   $0x3d0
f0101d1c:	68 55 6f 10 f0       	push   $0xf0106f55
f0101d21:	e8 1a e3 ff ff       	call   f0100040 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101d26:	a1 8c 1e 21 f0       	mov    0xf0211e8c,%eax
f0101d2b:	f6 00 04             	testb  $0x4,(%eax)
f0101d2e:	75 19                	jne    f0101d49 <mem_init+0xa2d>
f0101d30:	68 82 71 10 f0       	push   $0xf0107182
f0101d35:	68 8a 6f 10 f0       	push   $0xf0106f8a
f0101d3a:	68 d1 03 00 00       	push   $0x3d1
f0101d3f:	68 55 6f 10 f0       	push   $0xf0106f55
f0101d44:	e8 f7 e2 ff ff       	call   f0100040 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101d49:	6a 02                	push   $0x2
f0101d4b:	68 00 10 00 00       	push   $0x1000
f0101d50:	56                   	push   %esi
f0101d51:	50                   	push   %eax
f0101d52:	e8 ea f4 ff ff       	call   f0101241 <page_insert>
f0101d57:	83 c4 10             	add    $0x10,%esp
f0101d5a:	85 c0                	test   %eax,%eax
f0101d5c:	74 19                	je     f0101d77 <mem_init+0xa5b>
f0101d5e:	68 a8 68 10 f0       	push   $0xf01068a8
f0101d63:	68 8a 6f 10 f0       	push   $0xf0106f8a
f0101d68:	68 d4 03 00 00       	push   $0x3d4
f0101d6d:	68 55 6f 10 f0       	push   $0xf0106f55
f0101d72:	e8 c9 e2 ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101d77:	83 ec 04             	sub    $0x4,%esp
f0101d7a:	6a 00                	push   $0x0
f0101d7c:	68 00 10 00 00       	push   $0x1000
f0101d81:	ff 35 8c 1e 21 f0    	pushl  0xf0211e8c
f0101d87:	e8 e9 f2 ff ff       	call   f0101075 <pgdir_walk>
f0101d8c:	83 c4 10             	add    $0x10,%esp
f0101d8f:	f6 00 02             	testb  $0x2,(%eax)
f0101d92:	75 19                	jne    f0101dad <mem_init+0xa91>
f0101d94:	68 c8 69 10 f0       	push   $0xf01069c8
f0101d99:	68 8a 6f 10 f0       	push   $0xf0106f8a
f0101d9e:	68 d5 03 00 00       	push   $0x3d5
f0101da3:	68 55 6f 10 f0       	push   $0xf0106f55
f0101da8:	e8 93 e2 ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101dad:	83 ec 04             	sub    $0x4,%esp
f0101db0:	6a 00                	push   $0x0
f0101db2:	68 00 10 00 00       	push   $0x1000
f0101db7:	ff 35 8c 1e 21 f0    	pushl  0xf0211e8c
f0101dbd:	e8 b3 f2 ff ff       	call   f0101075 <pgdir_walk>
f0101dc2:	83 c4 10             	add    $0x10,%esp
f0101dc5:	f6 00 04             	testb  $0x4,(%eax)
f0101dc8:	74 19                	je     f0101de3 <mem_init+0xac7>
f0101dca:	68 fc 69 10 f0       	push   $0xf01069fc
f0101dcf:	68 8a 6f 10 f0       	push   $0xf0106f8a
f0101dd4:	68 d6 03 00 00       	push   $0x3d6
f0101dd9:	68 55 6f 10 f0       	push   $0xf0106f55
f0101dde:	e8 5d e2 ff ff       	call   f0100040 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101de3:	6a 02                	push   $0x2
f0101de5:	68 00 00 40 00       	push   $0x400000
f0101dea:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101ded:	ff 35 8c 1e 21 f0    	pushl  0xf0211e8c
f0101df3:	e8 49 f4 ff ff       	call   f0101241 <page_insert>
f0101df8:	83 c4 10             	add    $0x10,%esp
f0101dfb:	85 c0                	test   %eax,%eax
f0101dfd:	78 19                	js     f0101e18 <mem_init+0xafc>
f0101dff:	68 34 6a 10 f0       	push   $0xf0106a34
f0101e04:	68 8a 6f 10 f0       	push   $0xf0106f8a
f0101e09:	68 d9 03 00 00       	push   $0x3d9
f0101e0e:	68 55 6f 10 f0       	push   $0xf0106f55
f0101e13:	e8 28 e2 ff ff       	call   f0100040 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101e18:	6a 02                	push   $0x2
f0101e1a:	68 00 10 00 00       	push   $0x1000
f0101e1f:	53                   	push   %ebx
f0101e20:	ff 35 8c 1e 21 f0    	pushl  0xf0211e8c
f0101e26:	e8 16 f4 ff ff       	call   f0101241 <page_insert>
f0101e2b:	83 c4 10             	add    $0x10,%esp
f0101e2e:	85 c0                	test   %eax,%eax
f0101e30:	74 19                	je     f0101e4b <mem_init+0xb2f>
f0101e32:	68 6c 6a 10 f0       	push   $0xf0106a6c
f0101e37:	68 8a 6f 10 f0       	push   $0xf0106f8a
f0101e3c:	68 dc 03 00 00       	push   $0x3dc
f0101e41:	68 55 6f 10 f0       	push   $0xf0106f55
f0101e46:	e8 f5 e1 ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101e4b:	83 ec 04             	sub    $0x4,%esp
f0101e4e:	6a 00                	push   $0x0
f0101e50:	68 00 10 00 00       	push   $0x1000
f0101e55:	ff 35 8c 1e 21 f0    	pushl  0xf0211e8c
f0101e5b:	e8 15 f2 ff ff       	call   f0101075 <pgdir_walk>
f0101e60:	83 c4 10             	add    $0x10,%esp
f0101e63:	f6 00 04             	testb  $0x4,(%eax)
f0101e66:	74 19                	je     f0101e81 <mem_init+0xb65>
f0101e68:	68 fc 69 10 f0       	push   $0xf01069fc
f0101e6d:	68 8a 6f 10 f0       	push   $0xf0106f8a
f0101e72:	68 dd 03 00 00       	push   $0x3dd
f0101e77:	68 55 6f 10 f0       	push   $0xf0106f55
f0101e7c:	e8 bf e1 ff ff       	call   f0100040 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101e81:	8b 3d 8c 1e 21 f0    	mov    0xf0211e8c,%edi
f0101e87:	ba 00 00 00 00       	mov    $0x0,%edx
f0101e8c:	89 f8                	mov    %edi,%eax
f0101e8e:	e8 17 ec ff ff       	call   f0100aaa <check_va2pa>
f0101e93:	89 c1                	mov    %eax,%ecx
f0101e95:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101e98:	89 d8                	mov    %ebx,%eax
f0101e9a:	2b 05 90 1e 21 f0    	sub    0xf0211e90,%eax
f0101ea0:	c1 f8 03             	sar    $0x3,%eax
f0101ea3:	c1 e0 0c             	shl    $0xc,%eax
f0101ea6:	39 c1                	cmp    %eax,%ecx
f0101ea8:	74 19                	je     f0101ec3 <mem_init+0xba7>
f0101eaa:	68 a8 6a 10 f0       	push   $0xf0106aa8
f0101eaf:	68 8a 6f 10 f0       	push   $0xf0106f8a
f0101eb4:	68 e0 03 00 00       	push   $0x3e0
f0101eb9:	68 55 6f 10 f0       	push   $0xf0106f55
f0101ebe:	e8 7d e1 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101ec3:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101ec8:	89 f8                	mov    %edi,%eax
f0101eca:	e8 db eb ff ff       	call   f0100aaa <check_va2pa>
f0101ecf:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101ed2:	74 19                	je     f0101eed <mem_init+0xbd1>
f0101ed4:	68 d4 6a 10 f0       	push   $0xf0106ad4
f0101ed9:	68 8a 6f 10 f0       	push   $0xf0106f8a
f0101ede:	68 e1 03 00 00       	push   $0x3e1
f0101ee3:	68 55 6f 10 f0       	push   $0xf0106f55
f0101ee8:	e8 53 e1 ff ff       	call   f0100040 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101eed:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101ef2:	74 19                	je     f0101f0d <mem_init+0xbf1>
f0101ef4:	68 98 71 10 f0       	push   $0xf0107198
f0101ef9:	68 8a 6f 10 f0       	push   $0xf0106f8a
f0101efe:	68 e3 03 00 00       	push   $0x3e3
f0101f03:	68 55 6f 10 f0       	push   $0xf0106f55
f0101f08:	e8 33 e1 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f0101f0d:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101f12:	74 19                	je     f0101f2d <mem_init+0xc11>
f0101f14:	68 a9 71 10 f0       	push   $0xf01071a9
f0101f19:	68 8a 6f 10 f0       	push   $0xf0106f8a
f0101f1e:	68 e4 03 00 00       	push   $0x3e4
f0101f23:	68 55 6f 10 f0       	push   $0xf0106f55
f0101f28:	e8 13 e1 ff ff       	call   f0100040 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101f2d:	83 ec 0c             	sub    $0xc,%esp
f0101f30:	6a 00                	push   $0x0
f0101f32:	e8 65 f0 ff ff       	call   f0100f9c <page_alloc>
f0101f37:	83 c4 10             	add    $0x10,%esp
f0101f3a:	39 c6                	cmp    %eax,%esi
f0101f3c:	75 04                	jne    f0101f42 <mem_init+0xc26>
f0101f3e:	85 c0                	test   %eax,%eax
f0101f40:	75 19                	jne    f0101f5b <mem_init+0xc3f>
f0101f42:	68 04 6b 10 f0       	push   $0xf0106b04
f0101f47:	68 8a 6f 10 f0       	push   $0xf0106f8a
f0101f4c:	68 e7 03 00 00       	push   $0x3e7
f0101f51:	68 55 6f 10 f0       	push   $0xf0106f55
f0101f56:	e8 e5 e0 ff ff       	call   f0100040 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101f5b:	83 ec 08             	sub    $0x8,%esp
f0101f5e:	6a 00                	push   $0x0
f0101f60:	ff 35 8c 1e 21 f0    	pushl  0xf0211e8c
f0101f66:	e8 90 f2 ff ff       	call   f01011fb <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101f6b:	8b 3d 8c 1e 21 f0    	mov    0xf0211e8c,%edi
f0101f71:	ba 00 00 00 00       	mov    $0x0,%edx
f0101f76:	89 f8                	mov    %edi,%eax
f0101f78:	e8 2d eb ff ff       	call   f0100aaa <check_va2pa>
f0101f7d:	83 c4 10             	add    $0x10,%esp
f0101f80:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101f83:	74 19                	je     f0101f9e <mem_init+0xc82>
f0101f85:	68 28 6b 10 f0       	push   $0xf0106b28
f0101f8a:	68 8a 6f 10 f0       	push   $0xf0106f8a
f0101f8f:	68 eb 03 00 00       	push   $0x3eb
f0101f94:	68 55 6f 10 f0       	push   $0xf0106f55
f0101f99:	e8 a2 e0 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101f9e:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101fa3:	89 f8                	mov    %edi,%eax
f0101fa5:	e8 00 eb ff ff       	call   f0100aaa <check_va2pa>
f0101faa:	89 da                	mov    %ebx,%edx
f0101fac:	2b 15 90 1e 21 f0    	sub    0xf0211e90,%edx
f0101fb2:	c1 fa 03             	sar    $0x3,%edx
f0101fb5:	c1 e2 0c             	shl    $0xc,%edx
f0101fb8:	39 d0                	cmp    %edx,%eax
f0101fba:	74 19                	je     f0101fd5 <mem_init+0xcb9>
f0101fbc:	68 d4 6a 10 f0       	push   $0xf0106ad4
f0101fc1:	68 8a 6f 10 f0       	push   $0xf0106f8a
f0101fc6:	68 ec 03 00 00       	push   $0x3ec
f0101fcb:	68 55 6f 10 f0       	push   $0xf0106f55
f0101fd0:	e8 6b e0 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f0101fd5:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101fda:	74 19                	je     f0101ff5 <mem_init+0xcd9>
f0101fdc:	68 4f 71 10 f0       	push   $0xf010714f
f0101fe1:	68 8a 6f 10 f0       	push   $0xf0106f8a
f0101fe6:	68 ed 03 00 00       	push   $0x3ed
f0101feb:	68 55 6f 10 f0       	push   $0xf0106f55
f0101ff0:	e8 4b e0 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f0101ff5:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101ffa:	74 19                	je     f0102015 <mem_init+0xcf9>
f0101ffc:	68 a9 71 10 f0       	push   $0xf01071a9
f0102001:	68 8a 6f 10 f0       	push   $0xf0106f8a
f0102006:	68 ee 03 00 00       	push   $0x3ee
f010200b:	68 55 6f 10 f0       	push   $0xf0106f55
f0102010:	e8 2b e0 ff ff       	call   f0100040 <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0102015:	6a 00                	push   $0x0
f0102017:	68 00 10 00 00       	push   $0x1000
f010201c:	53                   	push   %ebx
f010201d:	57                   	push   %edi
f010201e:	e8 1e f2 ff ff       	call   f0101241 <page_insert>
f0102023:	83 c4 10             	add    $0x10,%esp
f0102026:	85 c0                	test   %eax,%eax
f0102028:	74 19                	je     f0102043 <mem_init+0xd27>
f010202a:	68 4c 6b 10 f0       	push   $0xf0106b4c
f010202f:	68 8a 6f 10 f0       	push   $0xf0106f8a
f0102034:	68 f1 03 00 00       	push   $0x3f1
f0102039:	68 55 6f 10 f0       	push   $0xf0106f55
f010203e:	e8 fd df ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref);
f0102043:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102048:	75 19                	jne    f0102063 <mem_init+0xd47>
f010204a:	68 ba 71 10 f0       	push   $0xf01071ba
f010204f:	68 8a 6f 10 f0       	push   $0xf0106f8a
f0102054:	68 f2 03 00 00       	push   $0x3f2
f0102059:	68 55 6f 10 f0       	push   $0xf0106f55
f010205e:	e8 dd df ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_link == NULL);
f0102063:	83 3b 00             	cmpl   $0x0,(%ebx)
f0102066:	74 19                	je     f0102081 <mem_init+0xd65>
f0102068:	68 c6 71 10 f0       	push   $0xf01071c6
f010206d:	68 8a 6f 10 f0       	push   $0xf0106f8a
f0102072:	68 f3 03 00 00       	push   $0x3f3
f0102077:	68 55 6f 10 f0       	push   $0xf0106f55
f010207c:	e8 bf df ff ff       	call   f0100040 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102081:	83 ec 08             	sub    $0x8,%esp
f0102084:	68 00 10 00 00       	push   $0x1000
f0102089:	ff 35 8c 1e 21 f0    	pushl  0xf0211e8c
f010208f:	e8 67 f1 ff ff       	call   f01011fb <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102094:	8b 3d 8c 1e 21 f0    	mov    0xf0211e8c,%edi
f010209a:	ba 00 00 00 00       	mov    $0x0,%edx
f010209f:	89 f8                	mov    %edi,%eax
f01020a1:	e8 04 ea ff ff       	call   f0100aaa <check_va2pa>
f01020a6:	83 c4 10             	add    $0x10,%esp
f01020a9:	83 f8 ff             	cmp    $0xffffffff,%eax
f01020ac:	74 19                	je     f01020c7 <mem_init+0xdab>
f01020ae:	68 28 6b 10 f0       	push   $0xf0106b28
f01020b3:	68 8a 6f 10 f0       	push   $0xf0106f8a
f01020b8:	68 f7 03 00 00       	push   $0x3f7
f01020bd:	68 55 6f 10 f0       	push   $0xf0106f55
f01020c2:	e8 79 df ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f01020c7:	ba 00 10 00 00       	mov    $0x1000,%edx
f01020cc:	89 f8                	mov    %edi,%eax
f01020ce:	e8 d7 e9 ff ff       	call   f0100aaa <check_va2pa>
f01020d3:	83 f8 ff             	cmp    $0xffffffff,%eax
f01020d6:	74 19                	je     f01020f1 <mem_init+0xdd5>
f01020d8:	68 84 6b 10 f0       	push   $0xf0106b84
f01020dd:	68 8a 6f 10 f0       	push   $0xf0106f8a
f01020e2:	68 f8 03 00 00       	push   $0x3f8
f01020e7:	68 55 6f 10 f0       	push   $0xf0106f55
f01020ec:	e8 4f df ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f01020f1:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f01020f6:	74 19                	je     f0102111 <mem_init+0xdf5>
f01020f8:	68 db 71 10 f0       	push   $0xf01071db
f01020fd:	68 8a 6f 10 f0       	push   $0xf0106f8a
f0102102:	68 f9 03 00 00       	push   $0x3f9
f0102107:	68 55 6f 10 f0       	push   $0xf0106f55
f010210c:	e8 2f df ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f0102111:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102116:	74 19                	je     f0102131 <mem_init+0xe15>
f0102118:	68 a9 71 10 f0       	push   $0xf01071a9
f010211d:	68 8a 6f 10 f0       	push   $0xf0106f8a
f0102122:	68 fa 03 00 00       	push   $0x3fa
f0102127:	68 55 6f 10 f0       	push   $0xf0106f55
f010212c:	e8 0f df ff ff       	call   f0100040 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0102131:	83 ec 0c             	sub    $0xc,%esp
f0102134:	6a 00                	push   $0x0
f0102136:	e8 61 ee ff ff       	call   f0100f9c <page_alloc>
f010213b:	83 c4 10             	add    $0x10,%esp
f010213e:	85 c0                	test   %eax,%eax
f0102140:	74 04                	je     f0102146 <mem_init+0xe2a>
f0102142:	39 c3                	cmp    %eax,%ebx
f0102144:	74 19                	je     f010215f <mem_init+0xe43>
f0102146:	68 ac 6b 10 f0       	push   $0xf0106bac
f010214b:	68 8a 6f 10 f0       	push   $0xf0106f8a
f0102150:	68 fd 03 00 00       	push   $0x3fd
f0102155:	68 55 6f 10 f0       	push   $0xf0106f55
f010215a:	e8 e1 de ff ff       	call   f0100040 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f010215f:	83 ec 0c             	sub    $0xc,%esp
f0102162:	6a 00                	push   $0x0
f0102164:	e8 33 ee ff ff       	call   f0100f9c <page_alloc>
f0102169:	83 c4 10             	add    $0x10,%esp
f010216c:	85 c0                	test   %eax,%eax
f010216e:	74 19                	je     f0102189 <mem_init+0xe6d>
f0102170:	68 fd 70 10 f0       	push   $0xf01070fd
f0102175:	68 8a 6f 10 f0       	push   $0xf0106f8a
f010217a:	68 00 04 00 00       	push   $0x400
f010217f:	68 55 6f 10 f0       	push   $0xf0106f55
f0102184:	e8 b7 de ff ff       	call   f0100040 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102189:	8b 0d 8c 1e 21 f0    	mov    0xf0211e8c,%ecx
f010218f:	8b 11                	mov    (%ecx),%edx
f0102191:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102197:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010219a:	2b 05 90 1e 21 f0    	sub    0xf0211e90,%eax
f01021a0:	c1 f8 03             	sar    $0x3,%eax
f01021a3:	c1 e0 0c             	shl    $0xc,%eax
f01021a6:	39 c2                	cmp    %eax,%edx
f01021a8:	74 19                	je     f01021c3 <mem_init+0xea7>
f01021aa:	68 50 68 10 f0       	push   $0xf0106850
f01021af:	68 8a 6f 10 f0       	push   $0xf0106f8a
f01021b4:	68 03 04 00 00       	push   $0x403
f01021b9:	68 55 6f 10 f0       	push   $0xf0106f55
f01021be:	e8 7d de ff ff       	call   f0100040 <_panic>
	kern_pgdir[0] = 0;
f01021c3:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f01021c9:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01021cc:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f01021d1:	74 19                	je     f01021ec <mem_init+0xed0>
f01021d3:	68 60 71 10 f0       	push   $0xf0107160
f01021d8:	68 8a 6f 10 f0       	push   $0xf0106f8a
f01021dd:	68 05 04 00 00       	push   $0x405
f01021e2:	68 55 6f 10 f0       	push   $0xf0106f55
f01021e7:	e8 54 de ff ff       	call   f0100040 <_panic>
	pp0->pp_ref = 0;
f01021ec:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01021ef:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f01021f5:	83 ec 0c             	sub    $0xc,%esp
f01021f8:	50                   	push   %eax
f01021f9:	e8 15 ee ff ff       	call   f0101013 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f01021fe:	83 c4 0c             	add    $0xc,%esp
f0102201:	6a 01                	push   $0x1
f0102203:	68 00 10 40 00       	push   $0x401000
f0102208:	ff 35 8c 1e 21 f0    	pushl  0xf0211e8c
f010220e:	e8 62 ee ff ff       	call   f0101075 <pgdir_walk>
f0102213:	89 c7                	mov    %eax,%edi
f0102215:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0102218:	a1 8c 1e 21 f0       	mov    0xf0211e8c,%eax
f010221d:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102220:	8b 40 04             	mov    0x4(%eax),%eax
f0102223:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102228:	8b 0d 88 1e 21 f0    	mov    0xf0211e88,%ecx
f010222e:	89 c2                	mov    %eax,%edx
f0102230:	c1 ea 0c             	shr    $0xc,%edx
f0102233:	83 c4 10             	add    $0x10,%esp
f0102236:	39 ca                	cmp    %ecx,%edx
f0102238:	72 15                	jb     f010224f <mem_init+0xf33>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010223a:	50                   	push   %eax
f010223b:	68 84 60 10 f0       	push   $0xf0106084
f0102240:	68 0c 04 00 00       	push   $0x40c
f0102245:	68 55 6f 10 f0       	push   $0xf0106f55
f010224a:	e8 f1 dd ff ff       	call   f0100040 <_panic>
	assert(ptep == ptep1 + PTX(va));
f010224f:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f0102254:	39 c7                	cmp    %eax,%edi
f0102256:	74 19                	je     f0102271 <mem_init+0xf55>
f0102258:	68 ec 71 10 f0       	push   $0xf01071ec
f010225d:	68 8a 6f 10 f0       	push   $0xf0106f8a
f0102262:	68 0d 04 00 00       	push   $0x40d
f0102267:	68 55 6f 10 f0       	push   $0xf0106f55
f010226c:	e8 cf dd ff ff       	call   f0100040 <_panic>
	kern_pgdir[PDX(va)] = 0;
f0102271:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102274:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f010227b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010227e:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102284:	2b 05 90 1e 21 f0    	sub    0xf0211e90,%eax
f010228a:	c1 f8 03             	sar    $0x3,%eax
f010228d:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102290:	89 c2                	mov    %eax,%edx
f0102292:	c1 ea 0c             	shr    $0xc,%edx
f0102295:	39 d1                	cmp    %edx,%ecx
f0102297:	77 12                	ja     f01022ab <mem_init+0xf8f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102299:	50                   	push   %eax
f010229a:	68 84 60 10 f0       	push   $0xf0106084
f010229f:	6a 58                	push   $0x58
f01022a1:	68 70 6f 10 f0       	push   $0xf0106f70
f01022a6:	e8 95 dd ff ff       	call   f0100040 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f01022ab:	83 ec 04             	sub    $0x4,%esp
f01022ae:	68 00 10 00 00       	push   $0x1000
f01022b3:	68 ff 00 00 00       	push   $0xff
f01022b8:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01022bd:	50                   	push   %eax
f01022be:	e8 f0 30 00 00       	call   f01053b3 <memset>
	page_free(pp0);
f01022c3:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01022c6:	89 3c 24             	mov    %edi,(%esp)
f01022c9:	e8 45 ed ff ff       	call   f0101013 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f01022ce:	83 c4 0c             	add    $0xc,%esp
f01022d1:	6a 01                	push   $0x1
f01022d3:	6a 00                	push   $0x0
f01022d5:	ff 35 8c 1e 21 f0    	pushl  0xf0211e8c
f01022db:	e8 95 ed ff ff       	call   f0101075 <pgdir_walk>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01022e0:	89 fa                	mov    %edi,%edx
f01022e2:	2b 15 90 1e 21 f0    	sub    0xf0211e90,%edx
f01022e8:	c1 fa 03             	sar    $0x3,%edx
f01022eb:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01022ee:	89 d0                	mov    %edx,%eax
f01022f0:	c1 e8 0c             	shr    $0xc,%eax
f01022f3:	83 c4 10             	add    $0x10,%esp
f01022f6:	3b 05 88 1e 21 f0    	cmp    0xf0211e88,%eax
f01022fc:	72 12                	jb     f0102310 <mem_init+0xff4>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01022fe:	52                   	push   %edx
f01022ff:	68 84 60 10 f0       	push   $0xf0106084
f0102304:	6a 58                	push   $0x58
f0102306:	68 70 6f 10 f0       	push   $0xf0106f70
f010230b:	e8 30 dd ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0102310:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f0102316:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102319:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f010231f:	f6 00 01             	testb  $0x1,(%eax)
f0102322:	74 19                	je     f010233d <mem_init+0x1021>
f0102324:	68 04 72 10 f0       	push   $0xf0107204
f0102329:	68 8a 6f 10 f0       	push   $0xf0106f8a
f010232e:	68 17 04 00 00       	push   $0x417
f0102333:	68 55 6f 10 f0       	push   $0xf0106f55
f0102338:	e8 03 dd ff ff       	call   f0100040 <_panic>
f010233d:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f0102340:	39 d0                	cmp    %edx,%eax
f0102342:	75 db                	jne    f010231f <mem_init+0x1003>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f0102344:	a1 8c 1e 21 f0       	mov    0xf0211e8c,%eax
f0102349:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f010234f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102352:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f0102358:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f010235b:	89 0d 40 12 21 f0    	mov    %ecx,0xf0211240

	// free the pages we took
	page_free(pp0);
f0102361:	83 ec 0c             	sub    $0xc,%esp
f0102364:	50                   	push   %eax
f0102365:	e8 a9 ec ff ff       	call   f0101013 <page_free>
	page_free(pp1);
f010236a:	89 1c 24             	mov    %ebx,(%esp)
f010236d:	e8 a1 ec ff ff       	call   f0101013 <page_free>
	page_free(pp2);
f0102372:	89 34 24             	mov    %esi,(%esp)
f0102375:	e8 99 ec ff ff       	call   f0101013 <page_free>

	// test mmio_map_region
	mm1 = (uintptr_t) mmio_map_region(0, 4097);
f010237a:	83 c4 08             	add    $0x8,%esp
f010237d:	68 01 10 00 00       	push   $0x1001
f0102382:	6a 00                	push   $0x0
f0102384:	e8 30 ef ff ff       	call   f01012b9 <mmio_map_region>
f0102389:	89 c3                	mov    %eax,%ebx
	mm2 = (uintptr_t) mmio_map_region(0, 4096);
f010238b:	83 c4 08             	add    $0x8,%esp
f010238e:	68 00 10 00 00       	push   $0x1000
f0102393:	6a 00                	push   $0x0
f0102395:	e8 1f ef ff ff       	call   f01012b9 <mmio_map_region>
f010239a:	89 c6                	mov    %eax,%esi
	// check that they're in the right region
	assert(mm1 >= MMIOBASE && mm1 + 8096 < MMIOLIM);
f010239c:	8d 83 a0 1f 00 00    	lea    0x1fa0(%ebx),%eax
f01023a2:	83 c4 10             	add    $0x10,%esp
f01023a5:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f01023ab:	76 07                	jbe    f01023b4 <mem_init+0x1098>
f01023ad:	3d ff ff bf ef       	cmp    $0xefbfffff,%eax
f01023b2:	76 19                	jbe    f01023cd <mem_init+0x10b1>
f01023b4:	68 d0 6b 10 f0       	push   $0xf0106bd0
f01023b9:	68 8a 6f 10 f0       	push   $0xf0106f8a
f01023be:	68 27 04 00 00       	push   $0x427
f01023c3:	68 55 6f 10 f0       	push   $0xf0106f55
f01023c8:	e8 73 dc ff ff       	call   f0100040 <_panic>
	assert(mm2 >= MMIOBASE && mm2 + 8096 < MMIOLIM);
f01023cd:	8d 96 a0 1f 00 00    	lea    0x1fa0(%esi),%edx
f01023d3:	81 fa ff ff bf ef    	cmp    $0xefbfffff,%edx
f01023d9:	77 08                	ja     f01023e3 <mem_init+0x10c7>
f01023db:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f01023e1:	77 19                	ja     f01023fc <mem_init+0x10e0>
f01023e3:	68 f8 6b 10 f0       	push   $0xf0106bf8
f01023e8:	68 8a 6f 10 f0       	push   $0xf0106f8a
f01023ed:	68 28 04 00 00       	push   $0x428
f01023f2:	68 55 6f 10 f0       	push   $0xf0106f55
f01023f7:	e8 44 dc ff ff       	call   f0100040 <_panic>
	// check that they're page-aligned
	assert(mm1 % PGSIZE == 0 && mm2 % PGSIZE == 0);
f01023fc:	89 da                	mov    %ebx,%edx
f01023fe:	09 f2                	or     %esi,%edx
f0102400:	f7 c2 ff 0f 00 00    	test   $0xfff,%edx
f0102406:	74 19                	je     f0102421 <mem_init+0x1105>
f0102408:	68 20 6c 10 f0       	push   $0xf0106c20
f010240d:	68 8a 6f 10 f0       	push   $0xf0106f8a
f0102412:	68 2a 04 00 00       	push   $0x42a
f0102417:	68 55 6f 10 f0       	push   $0xf0106f55
f010241c:	e8 1f dc ff ff       	call   f0100040 <_panic>
	// check that they don't overlap
	assert(mm1 + 8096 <= mm2);
f0102421:	39 c6                	cmp    %eax,%esi
f0102423:	73 19                	jae    f010243e <mem_init+0x1122>
f0102425:	68 1b 72 10 f0       	push   $0xf010721b
f010242a:	68 8a 6f 10 f0       	push   $0xf0106f8a
f010242f:	68 2c 04 00 00       	push   $0x42c
f0102434:	68 55 6f 10 f0       	push   $0xf0106f55
f0102439:	e8 02 dc ff ff       	call   f0100040 <_panic>
	// check page mappings
	assert(check_va2pa(kern_pgdir, mm1) == 0);
f010243e:	8b 3d 8c 1e 21 f0    	mov    0xf0211e8c,%edi
f0102444:	89 da                	mov    %ebx,%edx
f0102446:	89 f8                	mov    %edi,%eax
f0102448:	e8 5d e6 ff ff       	call   f0100aaa <check_va2pa>
f010244d:	85 c0                	test   %eax,%eax
f010244f:	74 19                	je     f010246a <mem_init+0x114e>
f0102451:	68 48 6c 10 f0       	push   $0xf0106c48
f0102456:	68 8a 6f 10 f0       	push   $0xf0106f8a
f010245b:	68 2e 04 00 00       	push   $0x42e
f0102460:	68 55 6f 10 f0       	push   $0xf0106f55
f0102465:	e8 d6 db ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm1+PGSIZE) == PGSIZE);
f010246a:	8d 83 00 10 00 00    	lea    0x1000(%ebx),%eax
f0102470:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102473:	89 c2                	mov    %eax,%edx
f0102475:	89 f8                	mov    %edi,%eax
f0102477:	e8 2e e6 ff ff       	call   f0100aaa <check_va2pa>
f010247c:	3d 00 10 00 00       	cmp    $0x1000,%eax
f0102481:	74 19                	je     f010249c <mem_init+0x1180>
f0102483:	68 6c 6c 10 f0       	push   $0xf0106c6c
f0102488:	68 8a 6f 10 f0       	push   $0xf0106f8a
f010248d:	68 2f 04 00 00       	push   $0x42f
f0102492:	68 55 6f 10 f0       	push   $0xf0106f55
f0102497:	e8 a4 db ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm2) == 0);
f010249c:	89 f2                	mov    %esi,%edx
f010249e:	89 f8                	mov    %edi,%eax
f01024a0:	e8 05 e6 ff ff       	call   f0100aaa <check_va2pa>
f01024a5:	85 c0                	test   %eax,%eax
f01024a7:	74 19                	je     f01024c2 <mem_init+0x11a6>
f01024a9:	68 9c 6c 10 f0       	push   $0xf0106c9c
f01024ae:	68 8a 6f 10 f0       	push   $0xf0106f8a
f01024b3:	68 30 04 00 00       	push   $0x430
f01024b8:	68 55 6f 10 f0       	push   $0xf0106f55
f01024bd:	e8 7e db ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm2+PGSIZE) == ~0);
f01024c2:	8d 96 00 10 00 00    	lea    0x1000(%esi),%edx
f01024c8:	89 f8                	mov    %edi,%eax
f01024ca:	e8 db e5 ff ff       	call   f0100aaa <check_va2pa>
f01024cf:	83 f8 ff             	cmp    $0xffffffff,%eax
f01024d2:	74 19                	je     f01024ed <mem_init+0x11d1>
f01024d4:	68 c0 6c 10 f0       	push   $0xf0106cc0
f01024d9:	68 8a 6f 10 f0       	push   $0xf0106f8a
f01024de:	68 31 04 00 00       	push   $0x431
f01024e3:	68 55 6f 10 f0       	push   $0xf0106f55
f01024e8:	e8 53 db ff ff       	call   f0100040 <_panic>
	// check permissions
	assert(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & (PTE_W|PTE_PWT|PTE_PCD));
f01024ed:	83 ec 04             	sub    $0x4,%esp
f01024f0:	6a 00                	push   $0x0
f01024f2:	53                   	push   %ebx
f01024f3:	57                   	push   %edi
f01024f4:	e8 7c eb ff ff       	call   f0101075 <pgdir_walk>
f01024f9:	83 c4 10             	add    $0x10,%esp
f01024fc:	f6 00 1a             	testb  $0x1a,(%eax)
f01024ff:	75 19                	jne    f010251a <mem_init+0x11fe>
f0102501:	68 ec 6c 10 f0       	push   $0xf0106cec
f0102506:	68 8a 6f 10 f0       	push   $0xf0106f8a
f010250b:	68 33 04 00 00       	push   $0x433
f0102510:	68 55 6f 10 f0       	push   $0xf0106f55
f0102515:	e8 26 db ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & PTE_U));
f010251a:	83 ec 04             	sub    $0x4,%esp
f010251d:	6a 00                	push   $0x0
f010251f:	53                   	push   %ebx
f0102520:	ff 35 8c 1e 21 f0    	pushl  0xf0211e8c
f0102526:	e8 4a eb ff ff       	call   f0101075 <pgdir_walk>
f010252b:	8b 00                	mov    (%eax),%eax
f010252d:	83 c4 10             	add    $0x10,%esp
f0102530:	83 e0 04             	and    $0x4,%eax
f0102533:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0102536:	74 19                	je     f0102551 <mem_init+0x1235>
f0102538:	68 30 6d 10 f0       	push   $0xf0106d30
f010253d:	68 8a 6f 10 f0       	push   $0xf0106f8a
f0102542:	68 34 04 00 00       	push   $0x434
f0102547:	68 55 6f 10 f0       	push   $0xf0106f55
f010254c:	e8 ef da ff ff       	call   f0100040 <_panic>
	// clear the mappings
	*pgdir_walk(kern_pgdir, (void*) mm1, 0) = 0;
f0102551:	83 ec 04             	sub    $0x4,%esp
f0102554:	6a 00                	push   $0x0
f0102556:	53                   	push   %ebx
f0102557:	ff 35 8c 1e 21 f0    	pushl  0xf0211e8c
f010255d:	e8 13 eb ff ff       	call   f0101075 <pgdir_walk>
f0102562:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm1 + PGSIZE, 0) = 0;
f0102568:	83 c4 0c             	add    $0xc,%esp
f010256b:	6a 00                	push   $0x0
f010256d:	ff 75 d4             	pushl  -0x2c(%ebp)
f0102570:	ff 35 8c 1e 21 f0    	pushl  0xf0211e8c
f0102576:	e8 fa ea ff ff       	call   f0101075 <pgdir_walk>
f010257b:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm2, 0) = 0;
f0102581:	83 c4 0c             	add    $0xc,%esp
f0102584:	6a 00                	push   $0x0
f0102586:	56                   	push   %esi
f0102587:	ff 35 8c 1e 21 f0    	pushl  0xf0211e8c
f010258d:	e8 e3 ea ff ff       	call   f0101075 <pgdir_walk>
f0102592:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

	cprintf("check_page() succeeded!\n");
f0102598:	c7 04 24 2d 72 10 f0 	movl   $0xf010722d,(%esp)
f010259f:	e8 8a 10 00 00       	call   f010362e <cprintf>
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	
	boot_map_region(kern_pgdir, UPAGES, PTSIZE, PADDR(pages), PTE_U);
f01025a4:	a1 90 1e 21 f0       	mov    0xf0211e90,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01025a9:	83 c4 10             	add    $0x10,%esp
f01025ac:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01025b1:	77 15                	ja     f01025c8 <mem_init+0x12ac>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01025b3:	50                   	push   %eax
f01025b4:	68 a8 60 10 f0       	push   $0xf01060a8
f01025b9:	68 be 00 00 00       	push   $0xbe
f01025be:	68 55 6f 10 f0       	push   $0xf0106f55
f01025c3:	e8 78 da ff ff       	call   f0100040 <_panic>
f01025c8:	83 ec 08             	sub    $0x8,%esp
f01025cb:	6a 04                	push   $0x4
f01025cd:	05 00 00 00 10       	add    $0x10000000,%eax
f01025d2:	50                   	push   %eax
f01025d3:	b9 00 00 40 00       	mov    $0x400000,%ecx
f01025d8:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f01025dd:	a1 8c 1e 21 f0       	mov    0xf0211e8c,%eax
f01025e2:	e8 23 eb ff ff       	call   f010110a <boot_map_region>
	// (ie. perm = PTE_U | PTE_P).
	// Permissions:
	//    - the new image at UENVS  -- kernel R, user R
	//    - envs itself -- kernel RW, user NONE
	// LAB 3: Your code here.
	boot_map_region(kern_pgdir, UENVS, PTSIZE, PADDR(envs), PTE_U);
f01025e7:	a1 44 12 21 f0       	mov    0xf0211244,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01025ec:	83 c4 10             	add    $0x10,%esp
f01025ef:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01025f4:	77 15                	ja     f010260b <mem_init+0x12ef>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01025f6:	50                   	push   %eax
f01025f7:	68 a8 60 10 f0       	push   $0xf01060a8
f01025fc:	68 c7 00 00 00       	push   $0xc7
f0102601:	68 55 6f 10 f0       	push   $0xf0106f55
f0102606:	e8 35 da ff ff       	call   f0100040 <_panic>
f010260b:	83 ec 08             	sub    $0x8,%esp
f010260e:	6a 04                	push   $0x4
f0102610:	05 00 00 00 10       	add    $0x10000000,%eax
f0102615:	50                   	push   %eax
f0102616:	b9 00 00 40 00       	mov    $0x400000,%ecx
f010261b:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f0102620:	a1 8c 1e 21 f0       	mov    0xf0211e8c,%eax
f0102625:	e8 e0 ea ff ff       	call   f010110a <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010262a:	83 c4 10             	add    $0x10,%esp
f010262d:	b8 00 60 11 f0       	mov    $0xf0116000,%eax
f0102632:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102637:	77 15                	ja     f010264e <mem_init+0x1332>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102639:	50                   	push   %eax
f010263a:	68 a8 60 10 f0       	push   $0xf01060a8
f010263f:	68 d4 00 00 00       	push   $0xd4
f0102644:	68 55 6f 10 f0       	push   $0xf0106f55
f0102649:	e8 f2 d9 ff ff       	call   f0100040 <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KSTACKTOP-KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W);
f010264e:	83 ec 08             	sub    $0x8,%esp
f0102651:	6a 02                	push   $0x2
f0102653:	68 00 60 11 00       	push   $0x116000
f0102658:	b9 00 80 00 00       	mov    $0x8000,%ecx
f010265d:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f0102662:	a1 8c 1e 21 f0       	mov    0xf0211e8c,%eax
f0102667:	e8 9e ea ff ff       	call   f010110a <boot_map_region>
	//      the PA range [0, 2^32 - KERNBASE)
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
    boot_map_region(kern_pgdir, KERNBASE, 0xffffffff - KERNBASE, 0, PTE_W);
f010266c:	83 c4 08             	add    $0x8,%esp
f010266f:	6a 02                	push   $0x2
f0102671:	6a 00                	push   $0x0
f0102673:	b9 ff ff ff 0f       	mov    $0xfffffff,%ecx
f0102678:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f010267d:	a1 8c 1e 21 f0       	mov    0xf0211e8c,%eax
f0102682:	e8 83 ea ff ff       	call   f010110a <boot_map_region>
f0102687:	c7 45 c4 00 30 21 f0 	movl   $0xf0213000,-0x3c(%ebp)
f010268e:	83 c4 10             	add    $0x10,%esp
f0102691:	bb 00 30 21 f0       	mov    $0xf0213000,%ebx
f0102696:	be 00 80 ff ef       	mov    $0xefff8000,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010269b:	81 fb ff ff ff ef    	cmp    $0xefffffff,%ebx
f01026a1:	77 15                	ja     f01026b8 <mem_init+0x139c>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01026a3:	53                   	push   %ebx
f01026a4:	68 a8 60 10 f0       	push   $0xf01060a8
f01026a9:	68 16 01 00 00       	push   $0x116
f01026ae:	68 55 6f 10 f0       	push   $0xf0106f55
f01026b3:	e8 88 d9 ff ff       	call   f0100040 <_panic>
	// LAB 4: Your code here:

    uintptr_t kstacktop_i;
    for(int i = 0; i < NCPU; i++){
        kstacktop_i = KSTACKTOP - i * (KSTKSIZE + KSTKGAP);
        boot_map_region(kern_pgdir, kstacktop_i - KSTKSIZE, KSTKSIZE, PADDR(percpu_kstacks[i]), PTE_W);
f01026b8:	83 ec 08             	sub    $0x8,%esp
f01026bb:	6a 02                	push   $0x2
f01026bd:	8d 83 00 00 00 10    	lea    0x10000000(%ebx),%eax
f01026c3:	50                   	push   %eax
f01026c4:	b9 00 80 00 00       	mov    $0x8000,%ecx
f01026c9:	89 f2                	mov    %esi,%edx
f01026cb:	a1 8c 1e 21 f0       	mov    0xf0211e8c,%eax
f01026d0:	e8 35 ea ff ff       	call   f010110a <boot_map_region>
f01026d5:	81 c3 00 80 00 00    	add    $0x8000,%ebx
f01026db:	81 ee 00 00 01 00    	sub    $0x10000,%esi
	//     Permissions: kernel RW, user NONE
	//
	// LAB 4: Your code here:

    uintptr_t kstacktop_i;
    for(int i = 0; i < NCPU; i++){
f01026e1:	83 c4 10             	add    $0x10,%esp
f01026e4:	b8 00 30 25 f0       	mov    $0xf0253000,%eax
f01026e9:	39 d8                	cmp    %ebx,%eax
f01026eb:	75 ae                	jne    f010269b <mem_init+0x137f>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f01026ed:	8b 3d 8c 1e 21 f0    	mov    0xf0211e8c,%edi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f01026f3:	a1 88 1e 21 f0       	mov    0xf0211e88,%eax
f01026f8:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01026fb:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0102702:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102707:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f010270a:	8b 35 90 1e 21 f0    	mov    0xf0211e90,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102710:	89 75 d0             	mov    %esi,-0x30(%ebp)

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102713:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102718:	eb 55                	jmp    f010276f <mem_init+0x1453>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f010271a:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
f0102720:	89 f8                	mov    %edi,%eax
f0102722:	e8 83 e3 ff ff       	call   f0100aaa <check_va2pa>
f0102727:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f010272e:	77 15                	ja     f0102745 <mem_init+0x1429>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102730:	56                   	push   %esi
f0102731:	68 a8 60 10 f0       	push   $0xf01060a8
f0102736:	68 4c 03 00 00       	push   $0x34c
f010273b:	68 55 6f 10 f0       	push   $0xf0106f55
f0102740:	e8 fb d8 ff ff       	call   f0100040 <_panic>
f0102745:	8d 94 1e 00 00 00 10 	lea    0x10000000(%esi,%ebx,1),%edx
f010274c:	39 c2                	cmp    %eax,%edx
f010274e:	74 19                	je     f0102769 <mem_init+0x144d>
f0102750:	68 64 6d 10 f0       	push   $0xf0106d64
f0102755:	68 8a 6f 10 f0       	push   $0xf0106f8a
f010275a:	68 4c 03 00 00       	push   $0x34c
f010275f:	68 55 6f 10 f0       	push   $0xf0106f55
f0102764:	e8 d7 d8 ff ff       	call   f0100040 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102769:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f010276f:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0102772:	77 a6                	ja     f010271a <mem_init+0x13fe>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f0102774:	8b 35 44 12 21 f0    	mov    0xf0211244,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010277a:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f010277d:	bb 00 00 c0 ee       	mov    $0xeec00000,%ebx
f0102782:	89 da                	mov    %ebx,%edx
f0102784:	89 f8                	mov    %edi,%eax
f0102786:	e8 1f e3 ff ff       	call   f0100aaa <check_va2pa>
f010278b:	81 7d d4 ff ff ff ef 	cmpl   $0xefffffff,-0x2c(%ebp)
f0102792:	77 15                	ja     f01027a9 <mem_init+0x148d>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102794:	56                   	push   %esi
f0102795:	68 a8 60 10 f0       	push   $0xf01060a8
f010279a:	68 51 03 00 00       	push   $0x351
f010279f:	68 55 6f 10 f0       	push   $0xf0106f55
f01027a4:	e8 97 d8 ff ff       	call   f0100040 <_panic>
f01027a9:	8d 94 1e 00 00 40 21 	lea    0x21400000(%esi,%ebx,1),%edx
f01027b0:	39 d0                	cmp    %edx,%eax
f01027b2:	74 19                	je     f01027cd <mem_init+0x14b1>
f01027b4:	68 98 6d 10 f0       	push   $0xf0106d98
f01027b9:	68 8a 6f 10 f0       	push   $0xf0106f8a
f01027be:	68 51 03 00 00       	push   $0x351
f01027c3:	68 55 6f 10 f0       	push   $0xf0106f55
f01027c8:	e8 73 d8 ff ff       	call   f0100040 <_panic>
f01027cd:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01027d3:	81 fb 00 f0 c1 ee    	cmp    $0xeec1f000,%ebx
f01027d9:	75 a7                	jne    f0102782 <mem_init+0x1466>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01027db:	8b 75 cc             	mov    -0x34(%ebp),%esi
f01027de:	c1 e6 0c             	shl    $0xc,%esi
f01027e1:	bb 00 00 00 00       	mov    $0x0,%ebx
f01027e6:	eb 30                	jmp    f0102818 <mem_init+0x14fc>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f01027e8:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
f01027ee:	89 f8                	mov    %edi,%eax
f01027f0:	e8 b5 e2 ff ff       	call   f0100aaa <check_va2pa>
f01027f5:	39 c3                	cmp    %eax,%ebx
f01027f7:	74 19                	je     f0102812 <mem_init+0x14f6>
f01027f9:	68 cc 6d 10 f0       	push   $0xf0106dcc
f01027fe:	68 8a 6f 10 f0       	push   $0xf0106f8a
f0102803:	68 55 03 00 00       	push   $0x355
f0102808:	68 55 6f 10 f0       	push   $0xf0106f55
f010280d:	e8 2e d8 ff ff       	call   f0100040 <_panic>
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102812:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102818:	39 f3                	cmp    %esi,%ebx
f010281a:	72 cc                	jb     f01027e8 <mem_init+0x14cc>
f010281c:	be 00 80 ff ef       	mov    $0xefff8000,%esi
f0102821:	89 75 cc             	mov    %esi,-0x34(%ebp)
f0102824:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f0102827:	8b 45 cc             	mov    -0x34(%ebp),%eax
f010282a:	8d 88 00 80 00 00    	lea    0x8000(%eax),%ecx
f0102830:	89 4d d0             	mov    %ecx,-0x30(%ebp)
f0102833:	89 c3                	mov    %eax,%ebx
	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
f0102835:	8b 45 c8             	mov    -0x38(%ebp),%eax
f0102838:	05 00 80 00 20       	add    $0x20008000,%eax
f010283d:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102840:	89 da                	mov    %ebx,%edx
f0102842:	89 f8                	mov    %edi,%eax
f0102844:	e8 61 e2 ff ff       	call   f0100aaa <check_va2pa>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102849:	81 fe ff ff ff ef    	cmp    $0xefffffff,%esi
f010284f:	77 15                	ja     f0102866 <mem_init+0x154a>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102851:	56                   	push   %esi
f0102852:	68 a8 60 10 f0       	push   $0xf01060a8
f0102857:	68 5d 03 00 00       	push   $0x35d
f010285c:	68 55 6f 10 f0       	push   $0xf0106f55
f0102861:	e8 da d7 ff ff       	call   f0100040 <_panic>
f0102866:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0102869:	8d 94 0b 00 30 21 f0 	lea    -0xfded000(%ebx,%ecx,1),%edx
f0102870:	39 d0                	cmp    %edx,%eax
f0102872:	74 19                	je     f010288d <mem_init+0x1571>
f0102874:	68 f4 6d 10 f0       	push   $0xf0106df4
f0102879:	68 8a 6f 10 f0       	push   $0xf0106f8a
f010287e:	68 5d 03 00 00       	push   $0x35d
f0102883:	68 55 6f 10 f0       	push   $0xf0106f55
f0102888:	e8 b3 d7 ff ff       	call   f0100040 <_panic>
f010288d:	81 c3 00 10 00 00    	add    $0x1000,%ebx

	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0102893:	3b 5d d0             	cmp    -0x30(%ebp),%ebx
f0102896:	75 a8                	jne    f0102840 <mem_init+0x1524>
f0102898:	8b 45 cc             	mov    -0x34(%ebp),%eax
f010289b:	8d 98 00 80 ff ff    	lea    -0x8000(%eax),%ebx
f01028a1:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f01028a4:	89 c6                	mov    %eax,%esi
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
				== PADDR(percpu_kstacks[n]) + i);
		for (i = 0; i < KSTKGAP; i += PGSIZE)
			assert(check_va2pa(pgdir, base + i) == ~0);
f01028a6:	89 da                	mov    %ebx,%edx
f01028a8:	89 f8                	mov    %edi,%eax
f01028aa:	e8 fb e1 ff ff       	call   f0100aaa <check_va2pa>
f01028af:	83 f8 ff             	cmp    $0xffffffff,%eax
f01028b2:	74 19                	je     f01028cd <mem_init+0x15b1>
f01028b4:	68 3c 6e 10 f0       	push   $0xf0106e3c
f01028b9:	68 8a 6f 10 f0       	push   $0xf0106f8a
f01028be:	68 5f 03 00 00       	push   $0x35f
f01028c3:	68 55 6f 10 f0       	push   $0xf0106f55
f01028c8:	e8 73 d7 ff ff       	call   f0100040 <_panic>
f01028cd:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
				== PADDR(percpu_kstacks[n]) + i);
		for (i = 0; i < KSTKGAP; i += PGSIZE)
f01028d3:	39 f3                	cmp    %esi,%ebx
f01028d5:	75 cf                	jne    f01028a6 <mem_init+0x158a>
f01028d7:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f01028da:	81 6d cc 00 00 01 00 	subl   $0x10000,-0x34(%ebp)
f01028e1:	81 45 c8 00 80 01 00 	addl   $0x18000,-0x38(%ebp)
f01028e8:	81 c6 00 80 00 00    	add    $0x8000,%esi
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
f01028ee:	b8 00 30 25 f0       	mov    $0xf0253000,%eax
f01028f3:	39 f0                	cmp    %esi,%eax
f01028f5:	0f 85 2c ff ff ff    	jne    f0102827 <mem_init+0x150b>
f01028fb:	b8 00 00 00 00       	mov    $0x0,%eax
f0102900:	eb 2a                	jmp    f010292c <mem_init+0x1610>
			assert(check_va2pa(pgdir, base + i) == ~0);
	}

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f0102902:	8d 90 45 fc ff ff    	lea    -0x3bb(%eax),%edx
f0102908:	83 fa 04             	cmp    $0x4,%edx
f010290b:	77 1f                	ja     f010292c <mem_init+0x1610>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
		case PDX(UENVS):
		case PDX(MMIOBASE):
			assert(pgdir[i] & PTE_P);
f010290d:	f6 04 87 01          	testb  $0x1,(%edi,%eax,4)
f0102911:	75 7e                	jne    f0102991 <mem_init+0x1675>
f0102913:	68 46 72 10 f0       	push   $0xf0107246
f0102918:	68 8a 6f 10 f0       	push   $0xf0106f8a
f010291d:	68 6a 03 00 00       	push   $0x36a
f0102922:	68 55 6f 10 f0       	push   $0xf0106f55
f0102927:	e8 14 d7 ff ff       	call   f0100040 <_panic>
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f010292c:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102931:	76 3f                	jbe    f0102972 <mem_init+0x1656>
				assert(pgdir[i] & PTE_P);
f0102933:	8b 14 87             	mov    (%edi,%eax,4),%edx
f0102936:	f6 c2 01             	test   $0x1,%dl
f0102939:	75 19                	jne    f0102954 <mem_init+0x1638>
f010293b:	68 46 72 10 f0       	push   $0xf0107246
f0102940:	68 8a 6f 10 f0       	push   $0xf0106f8a
f0102945:	68 6e 03 00 00       	push   $0x36e
f010294a:	68 55 6f 10 f0       	push   $0xf0106f55
f010294f:	e8 ec d6 ff ff       	call   f0100040 <_panic>
				assert(pgdir[i] & PTE_W);
f0102954:	f6 c2 02             	test   $0x2,%dl
f0102957:	75 38                	jne    f0102991 <mem_init+0x1675>
f0102959:	68 57 72 10 f0       	push   $0xf0107257
f010295e:	68 8a 6f 10 f0       	push   $0xf0106f8a
f0102963:	68 6f 03 00 00       	push   $0x36f
f0102968:	68 55 6f 10 f0       	push   $0xf0106f55
f010296d:	e8 ce d6 ff ff       	call   f0100040 <_panic>
			} else
				assert(pgdir[i] == 0);
f0102972:	83 3c 87 00          	cmpl   $0x0,(%edi,%eax,4)
f0102976:	74 19                	je     f0102991 <mem_init+0x1675>
f0102978:	68 68 72 10 f0       	push   $0xf0107268
f010297d:	68 8a 6f 10 f0       	push   $0xf0106f8a
f0102982:	68 71 03 00 00       	push   $0x371
f0102987:	68 55 6f 10 f0       	push   $0xf0106f55
f010298c:	e8 af d6 ff ff       	call   f0100040 <_panic>
		for (i = 0; i < KSTKGAP; i += PGSIZE)
			assert(check_va2pa(pgdir, base + i) == ~0);
	}

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0102991:	83 c0 01             	add    $0x1,%eax
f0102994:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f0102999:	0f 86 63 ff ff ff    	jbe    f0102902 <mem_init+0x15e6>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f010299f:	83 ec 0c             	sub    $0xc,%esp
f01029a2:	68 60 6e 10 f0       	push   $0xf0106e60
f01029a7:	e8 82 0c 00 00       	call   f010362e <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f01029ac:	a1 8c 1e 21 f0       	mov    0xf0211e8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01029b1:	83 c4 10             	add    $0x10,%esp
f01029b4:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01029b9:	77 15                	ja     f01029d0 <mem_init+0x16b4>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01029bb:	50                   	push   %eax
f01029bc:	68 a8 60 10 f0       	push   $0xf01060a8
f01029c1:	68 ed 00 00 00       	push   $0xed
f01029c6:	68 55 6f 10 f0       	push   $0xf0106f55
f01029cb:	e8 70 d6 ff ff       	call   f0100040 <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f01029d0:	05 00 00 00 10       	add    $0x10000000,%eax
f01029d5:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f01029d8:	b8 00 00 00 00       	mov    $0x0,%eax
f01029dd:	e8 b3 e1 ff ff       	call   f0100b95 <check_page_free_list>

static inline uint32_t
rcr0(void)
{
	uint32_t val;
	asm volatile("movl %%cr0,%0" : "=r" (val));
f01029e2:	0f 20 c0             	mov    %cr0,%eax
f01029e5:	83 e0 f3             	and    $0xfffffff3,%eax
}

static inline void
lcr0(uint32_t val)
{
	asm volatile("movl %0,%%cr0" : : "r" (val));
f01029e8:	0d 23 00 05 80       	or     $0x80050023,%eax
f01029ed:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01029f0:	83 ec 0c             	sub    $0xc,%esp
f01029f3:	6a 00                	push   $0x0
f01029f5:	e8 a2 e5 ff ff       	call   f0100f9c <page_alloc>
f01029fa:	89 c3                	mov    %eax,%ebx
f01029fc:	83 c4 10             	add    $0x10,%esp
f01029ff:	85 c0                	test   %eax,%eax
f0102a01:	75 19                	jne    f0102a1c <mem_init+0x1700>
f0102a03:	68 52 70 10 f0       	push   $0xf0107052
f0102a08:	68 8a 6f 10 f0       	push   $0xf0106f8a
f0102a0d:	68 49 04 00 00       	push   $0x449
f0102a12:	68 55 6f 10 f0       	push   $0xf0106f55
f0102a17:	e8 24 d6 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0102a1c:	83 ec 0c             	sub    $0xc,%esp
f0102a1f:	6a 00                	push   $0x0
f0102a21:	e8 76 e5 ff ff       	call   f0100f9c <page_alloc>
f0102a26:	89 c7                	mov    %eax,%edi
f0102a28:	83 c4 10             	add    $0x10,%esp
f0102a2b:	85 c0                	test   %eax,%eax
f0102a2d:	75 19                	jne    f0102a48 <mem_init+0x172c>
f0102a2f:	68 68 70 10 f0       	push   $0xf0107068
f0102a34:	68 8a 6f 10 f0       	push   $0xf0106f8a
f0102a39:	68 4a 04 00 00       	push   $0x44a
f0102a3e:	68 55 6f 10 f0       	push   $0xf0106f55
f0102a43:	e8 f8 d5 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0102a48:	83 ec 0c             	sub    $0xc,%esp
f0102a4b:	6a 00                	push   $0x0
f0102a4d:	e8 4a e5 ff ff       	call   f0100f9c <page_alloc>
f0102a52:	89 c6                	mov    %eax,%esi
f0102a54:	83 c4 10             	add    $0x10,%esp
f0102a57:	85 c0                	test   %eax,%eax
f0102a59:	75 19                	jne    f0102a74 <mem_init+0x1758>
f0102a5b:	68 7e 70 10 f0       	push   $0xf010707e
f0102a60:	68 8a 6f 10 f0       	push   $0xf0106f8a
f0102a65:	68 4b 04 00 00       	push   $0x44b
f0102a6a:	68 55 6f 10 f0       	push   $0xf0106f55
f0102a6f:	e8 cc d5 ff ff       	call   f0100040 <_panic>
	page_free(pp0);
f0102a74:	83 ec 0c             	sub    $0xc,%esp
f0102a77:	53                   	push   %ebx
f0102a78:	e8 96 e5 ff ff       	call   f0101013 <page_free>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102a7d:	89 f8                	mov    %edi,%eax
f0102a7f:	2b 05 90 1e 21 f0    	sub    0xf0211e90,%eax
f0102a85:	c1 f8 03             	sar    $0x3,%eax
f0102a88:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102a8b:	89 c2                	mov    %eax,%edx
f0102a8d:	c1 ea 0c             	shr    $0xc,%edx
f0102a90:	83 c4 10             	add    $0x10,%esp
f0102a93:	3b 15 88 1e 21 f0    	cmp    0xf0211e88,%edx
f0102a99:	72 12                	jb     f0102aad <mem_init+0x1791>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102a9b:	50                   	push   %eax
f0102a9c:	68 84 60 10 f0       	push   $0xf0106084
f0102aa1:	6a 58                	push   $0x58
f0102aa3:	68 70 6f 10 f0       	push   $0xf0106f70
f0102aa8:	e8 93 d5 ff ff       	call   f0100040 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f0102aad:	83 ec 04             	sub    $0x4,%esp
f0102ab0:	68 00 10 00 00       	push   $0x1000
f0102ab5:	6a 01                	push   $0x1
f0102ab7:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102abc:	50                   	push   %eax
f0102abd:	e8 f1 28 00 00       	call   f01053b3 <memset>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102ac2:	89 f0                	mov    %esi,%eax
f0102ac4:	2b 05 90 1e 21 f0    	sub    0xf0211e90,%eax
f0102aca:	c1 f8 03             	sar    $0x3,%eax
f0102acd:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102ad0:	89 c2                	mov    %eax,%edx
f0102ad2:	c1 ea 0c             	shr    $0xc,%edx
f0102ad5:	83 c4 10             	add    $0x10,%esp
f0102ad8:	3b 15 88 1e 21 f0    	cmp    0xf0211e88,%edx
f0102ade:	72 12                	jb     f0102af2 <mem_init+0x17d6>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102ae0:	50                   	push   %eax
f0102ae1:	68 84 60 10 f0       	push   $0xf0106084
f0102ae6:	6a 58                	push   $0x58
f0102ae8:	68 70 6f 10 f0       	push   $0xf0106f70
f0102aed:	e8 4e d5 ff ff       	call   f0100040 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f0102af2:	83 ec 04             	sub    $0x4,%esp
f0102af5:	68 00 10 00 00       	push   $0x1000
f0102afa:	6a 02                	push   $0x2
f0102afc:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102b01:	50                   	push   %eax
f0102b02:	e8 ac 28 00 00       	call   f01053b3 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102b07:	6a 02                	push   $0x2
f0102b09:	68 00 10 00 00       	push   $0x1000
f0102b0e:	57                   	push   %edi
f0102b0f:	ff 35 8c 1e 21 f0    	pushl  0xf0211e8c
f0102b15:	e8 27 e7 ff ff       	call   f0101241 <page_insert>
	assert(pp1->pp_ref == 1);
f0102b1a:	83 c4 20             	add    $0x20,%esp
f0102b1d:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102b22:	74 19                	je     f0102b3d <mem_init+0x1821>
f0102b24:	68 4f 71 10 f0       	push   $0xf010714f
f0102b29:	68 8a 6f 10 f0       	push   $0xf0106f8a
f0102b2e:	68 50 04 00 00       	push   $0x450
f0102b33:	68 55 6f 10 f0       	push   $0xf0106f55
f0102b38:	e8 03 d5 ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102b3d:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102b44:	01 01 01 
f0102b47:	74 19                	je     f0102b62 <mem_init+0x1846>
f0102b49:	68 80 6e 10 f0       	push   $0xf0106e80
f0102b4e:	68 8a 6f 10 f0       	push   $0xf0106f8a
f0102b53:	68 51 04 00 00       	push   $0x451
f0102b58:	68 55 6f 10 f0       	push   $0xf0106f55
f0102b5d:	e8 de d4 ff ff       	call   f0100040 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102b62:	6a 02                	push   $0x2
f0102b64:	68 00 10 00 00       	push   $0x1000
f0102b69:	56                   	push   %esi
f0102b6a:	ff 35 8c 1e 21 f0    	pushl  0xf0211e8c
f0102b70:	e8 cc e6 ff ff       	call   f0101241 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102b75:	83 c4 10             	add    $0x10,%esp
f0102b78:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102b7f:	02 02 02 
f0102b82:	74 19                	je     f0102b9d <mem_init+0x1881>
f0102b84:	68 a4 6e 10 f0       	push   $0xf0106ea4
f0102b89:	68 8a 6f 10 f0       	push   $0xf0106f8a
f0102b8e:	68 53 04 00 00       	push   $0x453
f0102b93:	68 55 6f 10 f0       	push   $0xf0106f55
f0102b98:	e8 a3 d4 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0102b9d:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102ba2:	74 19                	je     f0102bbd <mem_init+0x18a1>
f0102ba4:	68 71 71 10 f0       	push   $0xf0107171
f0102ba9:	68 8a 6f 10 f0       	push   $0xf0106f8a
f0102bae:	68 54 04 00 00       	push   $0x454
f0102bb3:	68 55 6f 10 f0       	push   $0xf0106f55
f0102bb8:	e8 83 d4 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f0102bbd:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102bc2:	74 19                	je     f0102bdd <mem_init+0x18c1>
f0102bc4:	68 db 71 10 f0       	push   $0xf01071db
f0102bc9:	68 8a 6f 10 f0       	push   $0xf0106f8a
f0102bce:	68 55 04 00 00       	push   $0x455
f0102bd3:	68 55 6f 10 f0       	push   $0xf0106f55
f0102bd8:	e8 63 d4 ff ff       	call   f0100040 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102bdd:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102be4:	03 03 03 
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102be7:	89 f0                	mov    %esi,%eax
f0102be9:	2b 05 90 1e 21 f0    	sub    0xf0211e90,%eax
f0102bef:	c1 f8 03             	sar    $0x3,%eax
f0102bf2:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102bf5:	89 c2                	mov    %eax,%edx
f0102bf7:	c1 ea 0c             	shr    $0xc,%edx
f0102bfa:	3b 15 88 1e 21 f0    	cmp    0xf0211e88,%edx
f0102c00:	72 12                	jb     f0102c14 <mem_init+0x18f8>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102c02:	50                   	push   %eax
f0102c03:	68 84 60 10 f0       	push   $0xf0106084
f0102c08:	6a 58                	push   $0x58
f0102c0a:	68 70 6f 10 f0       	push   $0xf0106f70
f0102c0f:	e8 2c d4 ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102c14:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102c1b:	03 03 03 
f0102c1e:	74 19                	je     f0102c39 <mem_init+0x191d>
f0102c20:	68 c8 6e 10 f0       	push   $0xf0106ec8
f0102c25:	68 8a 6f 10 f0       	push   $0xf0106f8a
f0102c2a:	68 57 04 00 00       	push   $0x457
f0102c2f:	68 55 6f 10 f0       	push   $0xf0106f55
f0102c34:	e8 07 d4 ff ff       	call   f0100040 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102c39:	83 ec 08             	sub    $0x8,%esp
f0102c3c:	68 00 10 00 00       	push   $0x1000
f0102c41:	ff 35 8c 1e 21 f0    	pushl  0xf0211e8c
f0102c47:	e8 af e5 ff ff       	call   f01011fb <page_remove>
	assert(pp2->pp_ref == 0);
f0102c4c:	83 c4 10             	add    $0x10,%esp
f0102c4f:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102c54:	74 19                	je     f0102c6f <mem_init+0x1953>
f0102c56:	68 a9 71 10 f0       	push   $0xf01071a9
f0102c5b:	68 8a 6f 10 f0       	push   $0xf0106f8a
f0102c60:	68 59 04 00 00       	push   $0x459
f0102c65:	68 55 6f 10 f0       	push   $0xf0106f55
f0102c6a:	e8 d1 d3 ff ff       	call   f0100040 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102c6f:	8b 0d 8c 1e 21 f0    	mov    0xf0211e8c,%ecx
f0102c75:	8b 11                	mov    (%ecx),%edx
f0102c77:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102c7d:	89 d8                	mov    %ebx,%eax
f0102c7f:	2b 05 90 1e 21 f0    	sub    0xf0211e90,%eax
f0102c85:	c1 f8 03             	sar    $0x3,%eax
f0102c88:	c1 e0 0c             	shl    $0xc,%eax
f0102c8b:	39 c2                	cmp    %eax,%edx
f0102c8d:	74 19                	je     f0102ca8 <mem_init+0x198c>
f0102c8f:	68 50 68 10 f0       	push   $0xf0106850
f0102c94:	68 8a 6f 10 f0       	push   $0xf0106f8a
f0102c99:	68 5c 04 00 00       	push   $0x45c
f0102c9e:	68 55 6f 10 f0       	push   $0xf0106f55
f0102ca3:	e8 98 d3 ff ff       	call   f0100040 <_panic>
	kern_pgdir[0] = 0;
f0102ca8:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102cae:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102cb3:	74 19                	je     f0102cce <mem_init+0x19b2>
f0102cb5:	68 60 71 10 f0       	push   $0xf0107160
f0102cba:	68 8a 6f 10 f0       	push   $0xf0106f8a
f0102cbf:	68 5e 04 00 00       	push   $0x45e
f0102cc4:	68 55 6f 10 f0       	push   $0xf0106f55
f0102cc9:	e8 72 d3 ff ff       	call   f0100040 <_panic>
	pp0->pp_ref = 0;
f0102cce:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f0102cd4:	83 ec 0c             	sub    $0xc,%esp
f0102cd7:	53                   	push   %ebx
f0102cd8:	e8 36 e3 ff ff       	call   f0101013 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102cdd:	c7 04 24 f4 6e 10 f0 	movl   $0xf0106ef4,(%esp)
f0102ce4:	e8 45 09 00 00       	call   f010362e <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f0102ce9:	83 c4 10             	add    $0x10,%esp
f0102cec:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102cef:	5b                   	pop    %ebx
f0102cf0:	5e                   	pop    %esi
f0102cf1:	5f                   	pop    %edi
f0102cf2:	5d                   	pop    %ebp
f0102cf3:	c3                   	ret    

f0102cf4 <user_mem_check>:
// Returns 0 if the user program can access this range of addresses,
// and -E_FAULT otherwise.
//
int
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
f0102cf4:	55                   	push   %ebp
f0102cf5:	89 e5                	mov    %esp,%ebp
f0102cf7:	57                   	push   %edi
f0102cf8:	56                   	push   %esi
f0102cf9:	53                   	push   %ebx
f0102cfa:	83 ec 2c             	sub    $0x2c,%esp
f0102cfd:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// LAB 3: Your code here.
	void *vat =(void *) va;
	void *end =(void *)va + len;
f0102d00:	89 d8                	mov    %ebx,%eax
f0102d02:	03 45 10             	add    0x10(%ebp),%eax
f0102d05:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	int p = perm | PTE_P;
f0102d08:	8b 75 14             	mov    0x14(%ebp),%esi
f0102d0b:	83 ce 01             	or     $0x1,%esi
	for (; vat < end; vat = ROUNDDOWN(vat+PGSIZE, PGSIZE)) {
		if ((uint32_t)vat > ULIM) {
			user_mem_check_addr =(uintptr_t) vat;
			return -E_FAULT;
		}
		page_lookup(env->env_pgdir, vat, &pte);
f0102d0e:	8d 7d e4             	lea    -0x1c(%ebp),%edi
	// LAB 3: Your code here.
	void *vat =(void *) va;
	void *end =(void *)va + len;
	int p = perm | PTE_P;
	pte_t *pte;
	for (; vat < end; vat = ROUNDDOWN(vat+PGSIZE, PGSIZE)) {
f0102d11:	eb 55                	jmp    f0102d68 <user_mem_check+0x74>
		if ((uint32_t)vat > ULIM) {
f0102d13:	89 5d d0             	mov    %ebx,-0x30(%ebp)
f0102d16:	81 fb 00 00 80 ef    	cmp    $0xef800000,%ebx
f0102d1c:	76 0d                	jbe    f0102d2b <user_mem_check+0x37>
			user_mem_check_addr =(uintptr_t) vat;
f0102d1e:	89 1d 3c 12 21 f0    	mov    %ebx,0xf021123c
			return -E_FAULT;
f0102d24:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0102d29:	eb 47                	jmp    f0102d72 <user_mem_check+0x7e>
		}
		page_lookup(env->env_pgdir, vat, &pte);
f0102d2b:	83 ec 04             	sub    $0x4,%esp
f0102d2e:	57                   	push   %edi
f0102d2f:	53                   	push   %ebx
f0102d30:	8b 45 08             	mov    0x8(%ebp),%eax
f0102d33:	ff 70 60             	pushl  0x60(%eax)
f0102d36:	e8 31 e4 ff ff       	call   f010116c <page_lookup>
		if (!(pte && ((*pte & p) == p))) {
f0102d3b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102d3e:	83 c4 10             	add    $0x10,%esp
f0102d41:	85 c0                	test   %eax,%eax
f0102d43:	74 08                	je     f0102d4d <user_mem_check+0x59>
f0102d45:	89 f2                	mov    %esi,%edx
f0102d47:	23 10                	and    (%eax),%edx
f0102d49:	39 d6                	cmp    %edx,%esi
f0102d4b:	74 0f                	je     f0102d5c <user_mem_check+0x68>
			user_mem_check_addr = (uintptr_t) vat;
f0102d4d:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102d50:	a3 3c 12 21 f0       	mov    %eax,0xf021123c
			return -E_FAULT;
f0102d55:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0102d5a:	eb 16                	jmp    f0102d72 <user_mem_check+0x7e>
	// LAB 3: Your code here.
	void *vat =(void *) va;
	void *end =(void *)va + len;
	int p = perm | PTE_P;
	pte_t *pte;
	for (; vat < end; vat = ROUNDDOWN(vat+PGSIZE, PGSIZE)) {
f0102d5c:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102d62:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
f0102d68:	3b 5d d4             	cmp    -0x2c(%ebp),%ebx
f0102d6b:	72 a6                	jb     f0102d13 <user_mem_check+0x1f>
			user_mem_check_addr = (uintptr_t) vat;
			return -E_FAULT;
		}
	}

	return 0;
f0102d6d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102d72:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102d75:	5b                   	pop    %ebx
f0102d76:	5e                   	pop    %esi
f0102d77:	5f                   	pop    %edi
f0102d78:	5d                   	pop    %ebp
f0102d79:	c3                   	ret    

f0102d7a <user_mem_assert>:
// If it cannot, 'env' is destroyed and, if env is the current
// environment, this function will not return.
//
void
user_mem_assert(struct Env *env, const void *va, size_t len, int perm)
{
f0102d7a:	55                   	push   %ebp
f0102d7b:	89 e5                	mov    %esp,%ebp
f0102d7d:	53                   	push   %ebx
f0102d7e:	83 ec 04             	sub    $0x4,%esp
f0102d81:	8b 5d 08             	mov    0x8(%ebp),%ebx
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
f0102d84:	8b 45 14             	mov    0x14(%ebp),%eax
f0102d87:	83 c8 04             	or     $0x4,%eax
f0102d8a:	50                   	push   %eax
f0102d8b:	ff 75 10             	pushl  0x10(%ebp)
f0102d8e:	ff 75 0c             	pushl  0xc(%ebp)
f0102d91:	53                   	push   %ebx
f0102d92:	e8 5d ff ff ff       	call   f0102cf4 <user_mem_check>
f0102d97:	83 c4 10             	add    $0x10,%esp
f0102d9a:	85 c0                	test   %eax,%eax
f0102d9c:	79 21                	jns    f0102dbf <user_mem_assert+0x45>
		cprintf("[%08x] user_mem_check assertion failure for "
f0102d9e:	83 ec 04             	sub    $0x4,%esp
f0102da1:	ff 35 3c 12 21 f0    	pushl  0xf021123c
f0102da7:	ff 73 48             	pushl  0x48(%ebx)
f0102daa:	68 20 6f 10 f0       	push   $0xf0106f20
f0102daf:	e8 7a 08 00 00       	call   f010362e <cprintf>
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
f0102db4:	89 1c 24             	mov    %ebx,(%esp)
f0102db7:	e8 9d 05 00 00       	call   f0103359 <env_destroy>
f0102dbc:	83 c4 10             	add    $0x10,%esp
	}
}
f0102dbf:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102dc2:	c9                   	leave  
f0102dc3:	c3                   	ret    

f0102dc4 <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f0102dc4:	55                   	push   %ebp
f0102dc5:	89 e5                	mov    %esp,%ebp
f0102dc7:	57                   	push   %edi
f0102dc8:	56                   	push   %esi
f0102dc9:	53                   	push   %ebx
f0102dca:	83 ec 0c             	sub    $0xc,%esp
f0102dcd:	89 c7                	mov    %eax,%edi
	//
	// Hint: It is easier to use region_alloc if the caller can pass
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	void *va_t = ROUNDDOWN(va, PGSIZE);
f0102dcf:	89 d3                	mov    %edx,%ebx
f0102dd1:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx

	void *end = ROUNDUP(va + len, PGSIZE);
f0102dd7:	8d b4 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%esi
f0102dde:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	for(; va_t < end;va_t += PGSIZE){
f0102de4:	eb 3d                	jmp    f0102e23 <region_alloc+0x5f>
		struct PageInfo *pp = page_alloc(1);	
f0102de6:	83 ec 0c             	sub    $0xc,%esp
f0102de9:	6a 01                	push   $0x1
f0102deb:	e8 ac e1 ff ff       	call   f0100f9c <page_alloc>
		if(pp == NULL){
f0102df0:	83 c4 10             	add    $0x10,%esp
f0102df3:	85 c0                	test   %eax,%eax
f0102df5:	75 17                	jne    f0102e0e <region_alloc+0x4a>
			panic("page alloc failed!\n");	
f0102df7:	83 ec 04             	sub    $0x4,%esp
f0102dfa:	68 76 72 10 f0       	push   $0xf0107276
f0102dff:	68 29 01 00 00       	push   $0x129
f0102e04:	68 8a 72 10 f0       	push   $0xf010728a
f0102e09:	e8 32 d2 ff ff       	call   f0100040 <_panic>
		}
		page_insert(e->env_pgdir, pp, va_t, PTE_U | PTE_W);	
f0102e0e:	6a 06                	push   $0x6
f0102e10:	53                   	push   %ebx
f0102e11:	50                   	push   %eax
f0102e12:	ff 77 60             	pushl  0x60(%edi)
f0102e15:	e8 27 e4 ff ff       	call   f0101241 <page_insert>
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	void *va_t = ROUNDDOWN(va, PGSIZE);

	void *end = ROUNDUP(va + len, PGSIZE);
	for(; va_t < end;va_t += PGSIZE){
f0102e1a:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102e20:	83 c4 10             	add    $0x10,%esp
f0102e23:	39 f3                	cmp    %esi,%ebx
f0102e25:	72 bf                	jb     f0102de6 <region_alloc+0x22>
		if(pp == NULL){
			panic("page alloc failed!\n");	
		}
		page_insert(e->env_pgdir, pp, va_t, PTE_U | PTE_W);	
	}
}
f0102e27:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102e2a:	5b                   	pop    %ebx
f0102e2b:	5e                   	pop    %esi
f0102e2c:	5f                   	pop    %edi
f0102e2d:	5d                   	pop    %ebp
f0102e2e:	c3                   	ret    

f0102e2f <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f0102e2f:	55                   	push   %ebp
f0102e30:	89 e5                	mov    %esp,%ebp
f0102e32:	56                   	push   %esi
f0102e33:	53                   	push   %ebx
f0102e34:	8b 45 08             	mov    0x8(%ebp),%eax
f0102e37:	8b 55 10             	mov    0x10(%ebp),%edx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f0102e3a:	85 c0                	test   %eax,%eax
f0102e3c:	75 1a                	jne    f0102e58 <envid2env+0x29>
		*env_store = curenv;
f0102e3e:	e8 93 2b 00 00       	call   f01059d6 <cpunum>
f0102e43:	6b c0 74             	imul   $0x74,%eax,%eax
f0102e46:	8b 80 28 20 21 f0    	mov    -0xfdedfd8(%eax),%eax
f0102e4c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0102e4f:	89 01                	mov    %eax,(%ecx)
		return 0;
f0102e51:	b8 00 00 00 00       	mov    $0x0,%eax
f0102e56:	eb 70                	jmp    f0102ec8 <envid2env+0x99>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f0102e58:	89 c3                	mov    %eax,%ebx
f0102e5a:	81 e3 ff 03 00 00    	and    $0x3ff,%ebx
f0102e60:	6b db 7c             	imul   $0x7c,%ebx,%ebx
f0102e63:	03 1d 44 12 21 f0    	add    0xf0211244,%ebx
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f0102e69:	83 7b 54 00          	cmpl   $0x0,0x54(%ebx)
f0102e6d:	74 05                	je     f0102e74 <envid2env+0x45>
f0102e6f:	3b 43 48             	cmp    0x48(%ebx),%eax
f0102e72:	74 10                	je     f0102e84 <envid2env+0x55>
		*env_store = 0;
f0102e74:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102e77:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0102e7d:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0102e82:	eb 44                	jmp    f0102ec8 <envid2env+0x99>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f0102e84:	84 d2                	test   %dl,%dl
f0102e86:	74 36                	je     f0102ebe <envid2env+0x8f>
f0102e88:	e8 49 2b 00 00       	call   f01059d6 <cpunum>
f0102e8d:	6b c0 74             	imul   $0x74,%eax,%eax
f0102e90:	3b 98 28 20 21 f0    	cmp    -0xfdedfd8(%eax),%ebx
f0102e96:	74 26                	je     f0102ebe <envid2env+0x8f>
f0102e98:	8b 73 4c             	mov    0x4c(%ebx),%esi
f0102e9b:	e8 36 2b 00 00       	call   f01059d6 <cpunum>
f0102ea0:	6b c0 74             	imul   $0x74,%eax,%eax
f0102ea3:	8b 80 28 20 21 f0    	mov    -0xfdedfd8(%eax),%eax
f0102ea9:	3b 70 48             	cmp    0x48(%eax),%esi
f0102eac:	74 10                	je     f0102ebe <envid2env+0x8f>
		*env_store = 0;
f0102eae:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102eb1:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0102eb7:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0102ebc:	eb 0a                	jmp    f0102ec8 <envid2env+0x99>
	}

	*env_store = e;
f0102ebe:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102ec1:	89 18                	mov    %ebx,(%eax)
	return 0;
f0102ec3:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102ec8:	5b                   	pop    %ebx
f0102ec9:	5e                   	pop    %esi
f0102eca:	5d                   	pop    %ebp
f0102ecb:	c3                   	ret    

f0102ecc <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f0102ecc:	55                   	push   %ebp
f0102ecd:	89 e5                	mov    %esp,%ebp
}

static inline void
lgdt(void *p)
{
	asm volatile("lgdt (%0)" : : "r" (p));
f0102ecf:	b8 20 03 12 f0       	mov    $0xf0120320,%eax
f0102ed4:	0f 01 10             	lgdtl  (%eax)
	lgdt(&gdt_pd);
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" : : "a" (GD_UD|3));
f0102ed7:	b8 23 00 00 00       	mov    $0x23,%eax
f0102edc:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" : : "a" (GD_UD|3));
f0102ede:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" : : "a" (GD_KD));
f0102ee0:	b8 10 00 00 00       	mov    $0x10,%eax
f0102ee5:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" : : "a" (GD_KD));
f0102ee7:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" : : "a" (GD_KD));
f0102ee9:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" : : "i" (GD_KT));
f0102eeb:	ea f2 2e 10 f0 08 00 	ljmp   $0x8,$0xf0102ef2
}

static inline void
lldt(uint16_t sel)
{
	asm volatile("lldt %0" : : "r" (sel));
f0102ef2:	b8 00 00 00 00       	mov    $0x0,%eax
f0102ef7:	0f 00 d0             	lldt   %ax
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
}
f0102efa:	5d                   	pop    %ebp
f0102efb:	c3                   	ret    

f0102efc <env_init>:
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f0102efc:	55                   	push   %ebp
f0102efd:	89 e5                	mov    %esp,%ebp
f0102eff:	56                   	push   %esi
f0102f00:	53                   	push   %ebx
	// Set up envs array
	// LAB 3: Your code here.
	for (int i = NENV - 1; i >= 0; i--) {
		envs[i].env_id = 0;
f0102f01:	8b 35 44 12 21 f0    	mov    0xf0211244,%esi
f0102f07:	8b 15 48 12 21 f0    	mov    0xf0211248,%edx
f0102f0d:	8d 86 84 ef 01 00    	lea    0x1ef84(%esi),%eax
f0102f13:	8d 5e 84             	lea    -0x7c(%esi),%ebx
f0102f16:	89 c1                	mov    %eax,%ecx
f0102f18:	c7 40 48 00 00 00 00 	movl   $0x0,0x48(%eax)
		envs[i].env_status = ENV_FREE;
f0102f1f:	c7 40 54 00 00 00 00 	movl   $0x0,0x54(%eax)
		envs[i].env_link = env_free_list;
f0102f26:	89 50 44             	mov    %edx,0x44(%eax)
f0102f29:	83 e8 7c             	sub    $0x7c,%eax
		env_free_list = &envs[i];
f0102f2c:	89 ca                	mov    %ecx,%edx
void
env_init(void)
{
	// Set up envs array
	// LAB 3: Your code here.
	for (int i = NENV - 1; i >= 0; i--) {
f0102f2e:	39 d8                	cmp    %ebx,%eax
f0102f30:	75 e4                	jne    f0102f16 <env_init+0x1a>
f0102f32:	89 35 48 12 21 f0    	mov    %esi,0xf0211248
		envs[i].env_link = env_free_list;
		env_free_list = &envs[i];
	}

	// Per-CPU part of the initialization
	env_init_percpu();
f0102f38:	e8 8f ff ff ff       	call   f0102ecc <env_init_percpu>
}
f0102f3d:	5b                   	pop    %ebx
f0102f3e:	5e                   	pop    %esi
f0102f3f:	5d                   	pop    %ebp
f0102f40:	c3                   	ret    

f0102f41 <env_alloc>:
//	-E_NO_FREE_ENV if all NENVS environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f0102f41:	55                   	push   %ebp
f0102f42:	89 e5                	mov    %esp,%ebp
f0102f44:	53                   	push   %ebx
f0102f45:	83 ec 04             	sub    $0x4,%esp
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f0102f48:	8b 1d 48 12 21 f0    	mov    0xf0211248,%ebx
f0102f4e:	85 db                	test   %ebx,%ebx
f0102f50:	0f 84 32 01 00 00    	je     f0103088 <env_alloc+0x147>
{
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
f0102f56:	83 ec 0c             	sub    $0xc,%esp
f0102f59:	6a 01                	push   $0x1
f0102f5b:	e8 3c e0 ff ff       	call   f0100f9c <page_alloc>
f0102f60:	83 c4 10             	add    $0x10,%esp
f0102f63:	85 c0                	test   %eax,%eax
f0102f65:	0f 84 24 01 00 00    	je     f010308f <env_alloc+0x14e>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102f6b:	89 c2                	mov    %eax,%edx
f0102f6d:	2b 15 90 1e 21 f0    	sub    0xf0211e90,%edx
f0102f73:	c1 fa 03             	sar    $0x3,%edx
f0102f76:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102f79:	89 d1                	mov    %edx,%ecx
f0102f7b:	c1 e9 0c             	shr    $0xc,%ecx
f0102f7e:	3b 0d 88 1e 21 f0    	cmp    0xf0211e88,%ecx
f0102f84:	72 12                	jb     f0102f98 <env_alloc+0x57>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102f86:	52                   	push   %edx
f0102f87:	68 84 60 10 f0       	push   $0xf0106084
f0102f8c:	6a 58                	push   $0x58
f0102f8e:	68 70 6f 10 f0       	push   $0xf0106f70
f0102f93:	e8 a8 d0 ff ff       	call   f0100040 <_panic>
	//	is an exception -- you need to increment env_pgdir's
	//	pp_ref for env_free to work correctly.
	//    - The functions in kern/pmap.h are handy.

	// LAB 3: Your code here.
	e->env_pgdir = page2kva(p);
f0102f98:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f0102f9e:	89 53 60             	mov    %edx,0x60(%ebx)
	p->pp_ref++;
f0102fa1:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
	memcpy(e->env_pgdir, kern_pgdir, PGSIZE);
f0102fa6:	83 ec 04             	sub    $0x4,%esp
f0102fa9:	68 00 10 00 00       	push   $0x1000
f0102fae:	ff 35 8c 1e 21 f0    	pushl  0xf0211e8c
f0102fb4:	ff 73 60             	pushl  0x60(%ebx)
f0102fb7:	e8 ac 24 00 00       	call   f0105468 <memcpy>

	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f0102fbc:	8b 43 60             	mov    0x60(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102fbf:	83 c4 10             	add    $0x10,%esp
f0102fc2:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102fc7:	77 15                	ja     f0102fde <env_alloc+0x9d>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102fc9:	50                   	push   %eax
f0102fca:	68 a8 60 10 f0       	push   $0xf01060a8
f0102fcf:	68 c5 00 00 00       	push   $0xc5
f0102fd4:	68 8a 72 10 f0       	push   $0xf010728a
f0102fd9:	e8 62 d0 ff ff       	call   f0100040 <_panic>
f0102fde:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0102fe4:	83 ca 05             	or     $0x5,%edx
f0102fe7:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f0102fed:	8b 43 48             	mov    0x48(%ebx),%eax
f0102ff0:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f0102ff5:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f0102ffa:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102fff:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f0103002:	89 da                	mov    %ebx,%edx
f0103004:	2b 15 44 12 21 f0    	sub    0xf0211244,%edx
f010300a:	c1 fa 02             	sar    $0x2,%edx
f010300d:	69 d2 df 7b ef bd    	imul   $0xbdef7bdf,%edx,%edx
f0103013:	09 d0                	or     %edx,%eax
f0103015:	89 43 48             	mov    %eax,0x48(%ebx)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f0103018:	8b 45 0c             	mov    0xc(%ebp),%eax
f010301b:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f010301e:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f0103025:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f010302c:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f0103033:	83 ec 04             	sub    $0x4,%esp
f0103036:	6a 44                	push   $0x44
f0103038:	6a 00                	push   $0x0
f010303a:	53                   	push   %ebx
f010303b:	e8 73 23 00 00       	call   f01053b3 <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f0103040:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f0103046:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f010304c:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f0103052:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f0103059:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)
	// You will set e->env_tf.tf_eip later.

	// Enable interrupts while in user mode.
	// LAB 4: Your code here.
    e->env_tf.tf_eflags |= FL_IF;
f010305f:	81 4b 38 00 02 00 00 	orl    $0x200,0x38(%ebx)
	// Clear the page fault handler until user installs one.
	e->env_pgfault_upcall = 0;
f0103066:	c7 43 64 00 00 00 00 	movl   $0x0,0x64(%ebx)

	// Also clear the IPC receiving flag.
	e->env_ipc_recving = 0;
f010306d:	c6 43 68 00          	movb   $0x0,0x68(%ebx)

	// commit the allocation
	env_free_list = e->env_link;
f0103071:	8b 43 44             	mov    0x44(%ebx),%eax
f0103074:	a3 48 12 21 f0       	mov    %eax,0xf0211248
	*newenv_store = e;
f0103079:	8b 45 08             	mov    0x8(%ebp),%eax
f010307c:	89 18                	mov    %ebx,(%eax)

	// cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
f010307e:	83 c4 10             	add    $0x10,%esp
f0103081:	b8 00 00 00 00       	mov    $0x0,%eax
f0103086:	eb 0c                	jmp    f0103094 <env_alloc+0x153>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f0103088:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f010308d:	eb 05                	jmp    f0103094 <env_alloc+0x153>
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f010308f:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	env_free_list = e->env_link;
	*newenv_store = e;

	// cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
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
f01030ab:	e8 91 fe ff ff       	call   f0102f41 <env_alloc>
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
f01030c4:	68 a4 72 10 f0       	push   $0xf01072a4
f01030c9:	68 69 01 00 00       	push   $0x169
f01030ce:	68 8a 72 10 f0       	push   $0xf010728a
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
f01030f4:	68 a8 60 10 f0       	push   $0xf01060a8
f01030f9:	68 6e 01 00 00       	push   $0x16e
f01030fe:	68 8a 72 10 f0       	push   $0xf010728a
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
f0103120:	e8 9f fc ff ff       	call   f0102dc4 <region_alloc>
			memset((void *) ph->p_va, 0, ph->p_memsz);
f0103125:	83 ec 04             	sub    $0x4,%esp
f0103128:	ff 73 14             	pushl  0x14(%ebx)
f010312b:	6a 00                	push   $0x0
f010312d:	ff 73 08             	pushl  0x8(%ebx)
f0103130:	e8 7e 22 00 00       	call   f01053b3 <memset>
			memcpy((void *) ph->p_va, binary + ph->p_offset, ph->p_filesz);
f0103135:	83 c4 0c             	add    $0xc,%esp
f0103138:	ff 73 10             	pushl  0x10(%ebx)
f010313b:	89 f8                	mov    %edi,%eax
f010313d:	03 43 04             	add    0x4(%ebx),%eax
f0103140:	50                   	push   %eax
f0103141:	ff 73 08             	pushl  0x8(%ebx)
f0103144:	e8 1f 23 00 00       	call   f0105468 <memcpy>
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
f0103153:	a1 8c 1e 21 f0       	mov    0xf0211e8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103158:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010315d:	77 15                	ja     f0103174 <env_create+0xdb>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010315f:	50                   	push   %eax
f0103160:	68 a8 60 10 f0       	push   $0xf01060a8
f0103165:	68 76 01 00 00       	push   $0x176
f010316a:	68 8a 72 10 f0       	push   $0xf010728a
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
f0103191:	e8 2e fc ff ff       	call   f0102dc4 <region_alloc>
{
	// LAB 3: Your code here.
	struct Env *e;
	env_alloc(&e, 0);
	load_icode(e, binary);
	e->env_type = type;
f0103196:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103199:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010319c:	89 48 50             	mov    %ecx,0x50(%eax)

	// If this is the file server (type == ENV_TYPE_FS) give it I/O privileges.
	// LAB 5: Your code here.
    if(type == ENV_TYPE_FS){
f010319f:	83 f9 01             	cmp    $0x1,%ecx
f01031a2:	75 07                	jne    f01031ab <env_create+0x112>
        e->env_tf.tf_eflags |= FL_IOPL_3; 
f01031a4:	81 48 38 00 30 00 00 	orl    $0x3000,0x38(%eax)
    }
}
f01031ab:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01031ae:	5b                   	pop    %ebx
f01031af:	5e                   	pop    %esi
f01031b0:	5f                   	pop    %edi
f01031b1:	5d                   	pop    %ebp
f01031b2:	c3                   	ret    

f01031b3 <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f01031b3:	55                   	push   %ebp
f01031b4:	89 e5                	mov    %esp,%ebp
f01031b6:	57                   	push   %edi
f01031b7:	56                   	push   %esi
f01031b8:	53                   	push   %ebx
f01031b9:	83 ec 1c             	sub    $0x1c,%esp
f01031bc:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f01031bf:	e8 12 28 00 00       	call   f01059d6 <cpunum>
f01031c4:	6b c0 74             	imul   $0x74,%eax,%eax
f01031c7:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f01031ce:	39 b8 28 20 21 f0    	cmp    %edi,-0xfdedfd8(%eax)
f01031d4:	75 30                	jne    f0103206 <env_free+0x53>
		lcr3(PADDR(kern_pgdir));
f01031d6:	a1 8c 1e 21 f0       	mov    0xf0211e8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01031db:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01031e0:	77 15                	ja     f01031f7 <env_free+0x44>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01031e2:	50                   	push   %eax
f01031e3:	68 a8 60 10 f0       	push   $0xf01060a8
f01031e8:	68 a5 01 00 00       	push   $0x1a5
f01031ed:	68 8a 72 10 f0       	push   $0xf010728a
f01031f2:	e8 49 ce ff ff       	call   f0100040 <_panic>
f01031f7:	05 00 00 00 10       	add    $0x10000000,%eax
f01031fc:	0f 22 d8             	mov    %eax,%cr3
f01031ff:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0103206:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0103209:	89 d0                	mov    %edx,%eax
f010320b:	c1 e0 02             	shl    $0x2,%eax
f010320e:	89 45 dc             	mov    %eax,-0x24(%ebp)
	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f0103211:	8b 47 60             	mov    0x60(%edi),%eax
f0103214:	8b 34 90             	mov    (%eax,%edx,4),%esi
f0103217:	f7 c6 01 00 00 00    	test   $0x1,%esi
f010321d:	0f 84 a8 00 00 00    	je     f01032cb <env_free+0x118>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f0103223:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103229:	89 f0                	mov    %esi,%eax
f010322b:	c1 e8 0c             	shr    $0xc,%eax
f010322e:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103231:	39 05 88 1e 21 f0    	cmp    %eax,0xf0211e88
f0103237:	77 15                	ja     f010324e <env_free+0x9b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0103239:	56                   	push   %esi
f010323a:	68 84 60 10 f0       	push   $0xf0106084
f010323f:	68 b4 01 00 00       	push   $0x1b4
f0103244:	68 8a 72 10 f0       	push   $0xf010728a
f0103249:	e8 f2 cd ff ff       	call   f0100040 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f010324e:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103251:	c1 e0 16             	shl    $0x16,%eax
f0103254:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0103257:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f010325c:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f0103263:	01 
f0103264:	74 17                	je     f010327d <env_free+0xca>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0103266:	83 ec 08             	sub    $0x8,%esp
f0103269:	89 d8                	mov    %ebx,%eax
f010326b:	c1 e0 0c             	shl    $0xc,%eax
f010326e:	0b 45 e4             	or     -0x1c(%ebp),%eax
f0103271:	50                   	push   %eax
f0103272:	ff 77 60             	pushl  0x60(%edi)
f0103275:	e8 81 df ff ff       	call   f01011fb <page_remove>
f010327a:	83 c4 10             	add    $0x10,%esp
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f010327d:	83 c3 01             	add    $0x1,%ebx
f0103280:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f0103286:	75 d4                	jne    f010325c <env_free+0xa9>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f0103288:	8b 47 60             	mov    0x60(%edi),%eax
f010328b:	8b 55 dc             	mov    -0x24(%ebp),%edx
f010328e:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103295:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0103298:	3b 05 88 1e 21 f0    	cmp    0xf0211e88,%eax
f010329e:	72 14                	jb     f01032b4 <env_free+0x101>
		panic("pa2page called with invalid pa");
f01032a0:	83 ec 04             	sub    $0x4,%esp
f01032a3:	68 f0 66 10 f0       	push   $0xf01066f0
f01032a8:	6a 51                	push   $0x51
f01032aa:	68 70 6f 10 f0       	push   $0xf0106f70
f01032af:	e8 8c cd ff ff       	call   f0100040 <_panic>
		page_decref(pa2page(pa));
f01032b4:	83 ec 0c             	sub    $0xc,%esp
f01032b7:	a1 90 1e 21 f0       	mov    0xf0211e90,%eax
f01032bc:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01032bf:	8d 04 d0             	lea    (%eax,%edx,8),%eax
f01032c2:	50                   	push   %eax
f01032c3:	e8 86 dd ff ff       	call   f010104e <page_decref>
f01032c8:	83 c4 10             	add    $0x10,%esp
	// Note the environment's demise.
	// cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f01032cb:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f01032cf:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01032d2:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f01032d7:	0f 85 29 ff ff ff    	jne    f0103206 <env_free+0x53>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f01032dd:	8b 47 60             	mov    0x60(%edi),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01032e0:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01032e5:	77 15                	ja     f01032fc <env_free+0x149>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01032e7:	50                   	push   %eax
f01032e8:	68 a8 60 10 f0       	push   $0xf01060a8
f01032ed:	68 c2 01 00 00       	push   $0x1c2
f01032f2:	68 8a 72 10 f0       	push   $0xf010728a
f01032f7:	e8 44 cd ff ff       	call   f0100040 <_panic>
	e->env_pgdir = 0;
f01032fc:	c7 47 60 00 00 00 00 	movl   $0x0,0x60(%edi)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103303:	05 00 00 00 10       	add    $0x10000000,%eax
f0103308:	c1 e8 0c             	shr    $0xc,%eax
f010330b:	3b 05 88 1e 21 f0    	cmp    0xf0211e88,%eax
f0103311:	72 14                	jb     f0103327 <env_free+0x174>
		panic("pa2page called with invalid pa");
f0103313:	83 ec 04             	sub    $0x4,%esp
f0103316:	68 f0 66 10 f0       	push   $0xf01066f0
f010331b:	6a 51                	push   $0x51
f010331d:	68 70 6f 10 f0       	push   $0xf0106f70
f0103322:	e8 19 cd ff ff       	call   f0100040 <_panic>
	page_decref(pa2page(pa));
f0103327:	83 ec 0c             	sub    $0xc,%esp
f010332a:	8b 15 90 1e 21 f0    	mov    0xf0211e90,%edx
f0103330:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f0103333:	50                   	push   %eax
f0103334:	e8 15 dd ff ff       	call   f010104e <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f0103339:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f0103340:	a1 48 12 21 f0       	mov    0xf0211248,%eax
f0103345:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f0103348:	89 3d 48 12 21 f0    	mov    %edi,0xf0211248
}
f010334e:	83 c4 10             	add    $0x10,%esp
f0103351:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103354:	5b                   	pop    %ebx
f0103355:	5e                   	pop    %esi
f0103356:	5f                   	pop    %edi
f0103357:	5d                   	pop    %ebp
f0103358:	c3                   	ret    

f0103359 <env_destroy>:
// If e was the current env, then runs a new environment (and does not return
// to the caller).
//
void
env_destroy(struct Env *e)
{
f0103359:	55                   	push   %ebp
f010335a:	89 e5                	mov    %esp,%ebp
f010335c:	53                   	push   %ebx
f010335d:	83 ec 04             	sub    $0x4,%esp
f0103360:	8b 5d 08             	mov    0x8(%ebp),%ebx
	// If e is currently running on other CPUs, we change its state to
	// ENV_DYING. A zombie environment will be freed the next time
	// it traps to the kernel.
	if (e->env_status == ENV_RUNNING && curenv != e) {
f0103363:	83 7b 54 03          	cmpl   $0x3,0x54(%ebx)
f0103367:	75 19                	jne    f0103382 <env_destroy+0x29>
f0103369:	e8 68 26 00 00       	call   f01059d6 <cpunum>
f010336e:	6b c0 74             	imul   $0x74,%eax,%eax
f0103371:	3b 98 28 20 21 f0    	cmp    -0xfdedfd8(%eax),%ebx
f0103377:	74 09                	je     f0103382 <env_destroy+0x29>
		e->env_status = ENV_DYING;
f0103379:	c7 43 54 01 00 00 00 	movl   $0x1,0x54(%ebx)
		return;
f0103380:	eb 33                	jmp    f01033b5 <env_destroy+0x5c>
	}

	env_free(e);
f0103382:	83 ec 0c             	sub    $0xc,%esp
f0103385:	53                   	push   %ebx
f0103386:	e8 28 fe ff ff       	call   f01031b3 <env_free>

	if (curenv == e) {
f010338b:	e8 46 26 00 00       	call   f01059d6 <cpunum>
f0103390:	6b c0 74             	imul   $0x74,%eax,%eax
f0103393:	83 c4 10             	add    $0x10,%esp
f0103396:	3b 98 28 20 21 f0    	cmp    -0xfdedfd8(%eax),%ebx
f010339c:	75 17                	jne    f01033b5 <env_destroy+0x5c>
		curenv = NULL;
f010339e:	e8 33 26 00 00       	call   f01059d6 <cpunum>
f01033a3:	6b c0 74             	imul   $0x74,%eax,%eax
f01033a6:	c7 80 28 20 21 f0 00 	movl   $0x0,-0xfdedfd8(%eax)
f01033ad:	00 00 00 
		sched_yield();
f01033b0:	e8 56 0e 00 00       	call   f010420b <sched_yield>
	}
}
f01033b5:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01033b8:	c9                   	leave  
f01033b9:	c3                   	ret    

f01033ba <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f01033ba:	55                   	push   %ebp
f01033bb:	89 e5                	mov    %esp,%ebp
f01033bd:	53                   	push   %ebx
f01033be:	83 ec 04             	sub    $0x4,%esp
	// Record the CPU we are running on for user-space debugging
	curenv->env_cpunum = cpunum();
f01033c1:	e8 10 26 00 00       	call   f01059d6 <cpunum>
f01033c6:	6b c0 74             	imul   $0x74,%eax,%eax
f01033c9:	8b 98 28 20 21 f0    	mov    -0xfdedfd8(%eax),%ebx
f01033cf:	e8 02 26 00 00       	call   f01059d6 <cpunum>
f01033d4:	89 43 5c             	mov    %eax,0x5c(%ebx)

	asm volatile(
f01033d7:	8b 65 08             	mov    0x8(%ebp),%esp
f01033da:	61                   	popa   
f01033db:	07                   	pop    %es
f01033dc:	1f                   	pop    %ds
f01033dd:	83 c4 08             	add    $0x8,%esp
f01033e0:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret\n"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f01033e1:	83 ec 04             	sub    $0x4,%esp
f01033e4:	68 95 72 10 f0       	push   $0xf0107295
f01033e9:	68 f9 01 00 00       	push   $0x1f9
f01033ee:	68 8a 72 10 f0       	push   $0xf010728a
f01033f3:	e8 48 cc ff ff       	call   f0100040 <_panic>

f01033f8 <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f01033f8:	55                   	push   %ebp
f01033f9:	89 e5                	mov    %esp,%ebp
f01033fb:	53                   	push   %ebx
f01033fc:	83 ec 04             	sub    $0x4,%esp
f01033ff:	8b 5d 08             	mov    0x8(%ebp),%ebx
	//	e->env_tf.  Go back through the code you wrote above
	//	and make sure you have set the relevant parts of
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.
	if(curenv != NULL){
f0103402:	e8 cf 25 00 00       	call   f01059d6 <cpunum>
f0103407:	6b c0 74             	imul   $0x74,%eax,%eax
f010340a:	83 b8 28 20 21 f0 00 	cmpl   $0x0,-0xfdedfd8(%eax)
f0103411:	74 29                	je     f010343c <env_run+0x44>
		if(curenv->env_status == ENV_RUNNING)
f0103413:	e8 be 25 00 00       	call   f01059d6 <cpunum>
f0103418:	6b c0 74             	imul   $0x74,%eax,%eax
f010341b:	8b 80 28 20 21 f0    	mov    -0xfdedfd8(%eax),%eax
f0103421:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0103425:	75 15                	jne    f010343c <env_run+0x44>
			curenv->env_status = ENV_RUNNABLE;
f0103427:	e8 aa 25 00 00       	call   f01059d6 <cpunum>
f010342c:	6b c0 74             	imul   $0x74,%eax,%eax
f010342f:	8b 80 28 20 21 f0    	mov    -0xfdedfd8(%eax),%eax
f0103435:	c7 40 54 02 00 00 00 	movl   $0x2,0x54(%eax)
	}
	curenv = e;
f010343c:	e8 95 25 00 00       	call   f01059d6 <cpunum>
f0103441:	6b c0 74             	imul   $0x74,%eax,%eax
f0103444:	89 98 28 20 21 f0    	mov    %ebx,-0xfdedfd8(%eax)
	curenv->env_status = ENV_RUNNING;
f010344a:	e8 87 25 00 00       	call   f01059d6 <cpunum>
f010344f:	6b c0 74             	imul   $0x74,%eax,%eax
f0103452:	8b 80 28 20 21 f0    	mov    -0xfdedfd8(%eax),%eax
f0103458:	c7 40 54 03 00 00 00 	movl   $0x3,0x54(%eax)
	curenv->env_runs ++;
f010345f:	e8 72 25 00 00       	call   f01059d6 <cpunum>
f0103464:	6b c0 74             	imul   $0x74,%eax,%eax
f0103467:	8b 80 28 20 21 f0    	mov    -0xfdedfd8(%eax),%eax
f010346d:	83 40 58 01          	addl   $0x1,0x58(%eax)
	lcr3(PADDR(e->env_pgdir));
f0103471:	8b 43 60             	mov    0x60(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103474:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103479:	77 15                	ja     f0103490 <env_run+0x98>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010347b:	50                   	push   %eax
f010347c:	68 a8 60 10 f0       	push   $0xf01060a8
f0103481:	68 1e 02 00 00       	push   $0x21e
f0103486:	68 8a 72 10 f0       	push   $0xf010728a
f010348b:	e8 b0 cb ff ff       	call   f0100040 <_panic>
f0103490:	05 00 00 00 10       	add    $0x10000000,%eax
f0103495:	0f 22 d8             	mov    %eax,%cr3
}

static inline void
unlock_kernel(void)
{
	spin_unlock(&kernel_lock);
f0103498:	83 ec 0c             	sub    $0xc,%esp
f010349b:	68 c0 03 12 f0       	push   $0xf01203c0
f01034a0:	e8 3c 28 00 00       	call   f0105ce1 <spin_unlock>

	// Normally we wouldn't need to do this, but QEMU only runs
	// one CPU at a time and has a long time-slice.  Without the
	// pause, this CPU is likely to reacquire the lock before
	// another CPU has even been given a chance to acquire it.
	asm volatile("pause");
f01034a5:	f3 90                	pause  
    unlock_kernel();
	env_pop_tf(&e->env_tf);
f01034a7:	89 1c 24             	mov    %ebx,(%esp)
f01034aa:	e8 0b ff ff ff       	call   f01033ba <env_pop_tf>

f01034af <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f01034af:	55                   	push   %ebp
f01034b0:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01034b2:	ba 70 00 00 00       	mov    $0x70,%edx
f01034b7:	8b 45 08             	mov    0x8(%ebp),%eax
f01034ba:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01034bb:	ba 71 00 00 00       	mov    $0x71,%edx
f01034c0:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f01034c1:	0f b6 c0             	movzbl %al,%eax
}
f01034c4:	5d                   	pop    %ebp
f01034c5:	c3                   	ret    

f01034c6 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f01034c6:	55                   	push   %ebp
f01034c7:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01034c9:	ba 70 00 00 00       	mov    $0x70,%edx
f01034ce:	8b 45 08             	mov    0x8(%ebp),%eax
f01034d1:	ee                   	out    %al,(%dx)
f01034d2:	ba 71 00 00 00       	mov    $0x71,%edx
f01034d7:	8b 45 0c             	mov    0xc(%ebp),%eax
f01034da:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f01034db:	5d                   	pop    %ebp
f01034dc:	c3                   	ret    

f01034dd <irq_setmask_8259A>:
		irq_setmask_8259A(irq_mask_8259A);
}

void
irq_setmask_8259A(uint16_t mask)
{
f01034dd:	55                   	push   %ebp
f01034de:	89 e5                	mov    %esp,%ebp
f01034e0:	56                   	push   %esi
f01034e1:	53                   	push   %ebx
f01034e2:	8b 45 08             	mov    0x8(%ebp),%eax
	int i;
	irq_mask_8259A = mask;
f01034e5:	66 a3 a8 03 12 f0    	mov    %ax,0xf01203a8
	if (!didinit)
f01034eb:	80 3d 4c 12 21 f0 00 	cmpb   $0x0,0xf021124c
f01034f2:	74 5a                	je     f010354e <irq_setmask_8259A+0x71>
f01034f4:	89 c6                	mov    %eax,%esi
f01034f6:	ba 21 00 00 00       	mov    $0x21,%edx
f01034fb:	ee                   	out    %al,(%dx)
f01034fc:	66 c1 e8 08          	shr    $0x8,%ax
f0103500:	ba a1 00 00 00       	mov    $0xa1,%edx
f0103505:	ee                   	out    %al,(%dx)
		return;
	outb(IO_PIC1+1, (char)mask);
	outb(IO_PIC2+1, (char)(mask >> 8));
	cprintf("enabled interrupts:");
f0103506:	83 ec 0c             	sub    $0xc,%esp
f0103509:	68 c4 72 10 f0       	push   $0xf01072c4
f010350e:	e8 1b 01 00 00       	call   f010362e <cprintf>
f0103513:	83 c4 10             	add    $0x10,%esp
	for (i = 0; i < 16; i++)
f0103516:	bb 00 00 00 00       	mov    $0x0,%ebx
		if (~mask & (1<<i))
f010351b:	0f b7 f6             	movzwl %si,%esi
f010351e:	f7 d6                	not    %esi
f0103520:	0f a3 de             	bt     %ebx,%esi
f0103523:	73 11                	jae    f0103536 <irq_setmask_8259A+0x59>
			cprintf(" %d", i);
f0103525:	83 ec 08             	sub    $0x8,%esp
f0103528:	53                   	push   %ebx
f0103529:	68 e6 77 10 f0       	push   $0xf01077e6
f010352e:	e8 fb 00 00 00       	call   f010362e <cprintf>
f0103533:	83 c4 10             	add    $0x10,%esp
	if (!didinit)
		return;
	outb(IO_PIC1+1, (char)mask);
	outb(IO_PIC2+1, (char)(mask >> 8));
	cprintf("enabled interrupts:");
	for (i = 0; i < 16; i++)
f0103536:	83 c3 01             	add    $0x1,%ebx
f0103539:	83 fb 10             	cmp    $0x10,%ebx
f010353c:	75 e2                	jne    f0103520 <irq_setmask_8259A+0x43>
		if (~mask & (1<<i))
			cprintf(" %d", i);
	cprintf("\n");
f010353e:	83 ec 0c             	sub    $0xc,%esp
f0103541:	68 44 72 10 f0       	push   $0xf0107244
f0103546:	e8 e3 00 00 00       	call   f010362e <cprintf>
f010354b:	83 c4 10             	add    $0x10,%esp
}
f010354e:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0103551:	5b                   	pop    %ebx
f0103552:	5e                   	pop    %esi
f0103553:	5d                   	pop    %ebp
f0103554:	c3                   	ret    

f0103555 <pic_init>:

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
	didinit = 1;
f0103555:	c6 05 4c 12 21 f0 01 	movb   $0x1,0xf021124c
f010355c:	ba 21 00 00 00       	mov    $0x21,%edx
f0103561:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103566:	ee                   	out    %al,(%dx)
f0103567:	ba a1 00 00 00       	mov    $0xa1,%edx
f010356c:	ee                   	out    %al,(%dx)
f010356d:	ba 20 00 00 00       	mov    $0x20,%edx
f0103572:	b8 11 00 00 00       	mov    $0x11,%eax
f0103577:	ee                   	out    %al,(%dx)
f0103578:	ba 21 00 00 00       	mov    $0x21,%edx
f010357d:	b8 20 00 00 00       	mov    $0x20,%eax
f0103582:	ee                   	out    %al,(%dx)
f0103583:	b8 04 00 00 00       	mov    $0x4,%eax
f0103588:	ee                   	out    %al,(%dx)
f0103589:	b8 03 00 00 00       	mov    $0x3,%eax
f010358e:	ee                   	out    %al,(%dx)
f010358f:	ba a0 00 00 00       	mov    $0xa0,%edx
f0103594:	b8 11 00 00 00       	mov    $0x11,%eax
f0103599:	ee                   	out    %al,(%dx)
f010359a:	ba a1 00 00 00       	mov    $0xa1,%edx
f010359f:	b8 28 00 00 00       	mov    $0x28,%eax
f01035a4:	ee                   	out    %al,(%dx)
f01035a5:	b8 02 00 00 00       	mov    $0x2,%eax
f01035aa:	ee                   	out    %al,(%dx)
f01035ab:	b8 01 00 00 00       	mov    $0x1,%eax
f01035b0:	ee                   	out    %al,(%dx)
f01035b1:	ba 20 00 00 00       	mov    $0x20,%edx
f01035b6:	b8 68 00 00 00       	mov    $0x68,%eax
f01035bb:	ee                   	out    %al,(%dx)
f01035bc:	b8 0a 00 00 00       	mov    $0xa,%eax
f01035c1:	ee                   	out    %al,(%dx)
f01035c2:	ba a0 00 00 00       	mov    $0xa0,%edx
f01035c7:	b8 68 00 00 00       	mov    $0x68,%eax
f01035cc:	ee                   	out    %al,(%dx)
f01035cd:	b8 0a 00 00 00       	mov    $0xa,%eax
f01035d2:	ee                   	out    %al,(%dx)
	outb(IO_PIC1, 0x0a);             /* read IRR by default */

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irq_mask_8259A != 0xFFFF)
f01035d3:	0f b7 05 a8 03 12 f0 	movzwl 0xf01203a8,%eax
f01035da:	66 83 f8 ff          	cmp    $0xffff,%ax
f01035de:	74 13                	je     f01035f3 <pic_init+0x9e>
static bool didinit;

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
f01035e0:	55                   	push   %ebp
f01035e1:	89 e5                	mov    %esp,%ebp
f01035e3:	83 ec 14             	sub    $0x14,%esp

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irq_mask_8259A != 0xFFFF)
		irq_setmask_8259A(irq_mask_8259A);
f01035e6:	0f b7 c0             	movzwl %ax,%eax
f01035e9:	50                   	push   %eax
f01035ea:	e8 ee fe ff ff       	call   f01034dd <irq_setmask_8259A>
f01035ef:	83 c4 10             	add    $0x10,%esp
}
f01035f2:	c9                   	leave  
f01035f3:	f3 c3                	repz ret 

f01035f5 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01035f5:	55                   	push   %ebp
f01035f6:	89 e5                	mov    %esp,%ebp
f01035f8:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f01035fb:	ff 75 08             	pushl  0x8(%ebp)
f01035fe:	e8 96 d1 ff ff       	call   f0100799 <cputchar>
	*cnt++;
}
f0103603:	83 c4 10             	add    $0x10,%esp
f0103606:	c9                   	leave  
f0103607:	c3                   	ret    

f0103608 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0103608:	55                   	push   %ebp
f0103609:	89 e5                	mov    %esp,%ebp
f010360b:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f010360e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0103615:	ff 75 0c             	pushl  0xc(%ebp)
f0103618:	ff 75 08             	pushl  0x8(%ebp)
f010361b:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010361e:	50                   	push   %eax
f010361f:	68 f5 35 10 f0       	push   $0xf01035f5
f0103624:	e8 06 17 00 00       	call   f0104d2f <vprintfmt>
	return cnt;
}
f0103629:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010362c:	c9                   	leave  
f010362d:	c3                   	ret    

f010362e <cprintf>:

int
cprintf(const char *fmt, ...)
{
f010362e:	55                   	push   %ebp
f010362f:	89 e5                	mov    %esp,%ebp
f0103631:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0103634:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0103637:	50                   	push   %eax
f0103638:	ff 75 08             	pushl  0x8(%ebp)
f010363b:	e8 c8 ff ff ff       	call   f0103608 <vcprintf>
	va_end(ap);

	return cnt;
}
f0103640:	c9                   	leave  
f0103641:	c3                   	ret    

f0103642 <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f0103642:	55                   	push   %ebp
f0103643:	89 e5                	mov    %esp,%ebp
f0103645:	57                   	push   %edi
f0103646:	56                   	push   %esi
f0103647:	53                   	push   %ebx
f0103648:	83 ec 1c             	sub    $0x1c,%esp
	// get a triple fault.  If you set up an individual CPU's TSS
	// wrong, you may not get a fault until you try to return from
	// user space on that CPU.
	//
	// LAB 4: Your code here:
    int i = cpunum();
f010364b:	e8 86 23 00 00       	call   f01059d6 <cpunum>
f0103650:	89 c6                	mov    %eax,%esi
	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.

	thiscpu->cpu_ts.ts_esp0 = (uintptr_t)percpu_kstacks[i];
f0103652:	e8 7f 23 00 00       	call   f01059d6 <cpunum>
f0103657:	6b c0 74             	imul   $0x74,%eax,%eax
f010365a:	89 f2                	mov    %esi,%edx
f010365c:	c1 e2 0f             	shl    $0xf,%edx
f010365f:	81 c2 00 30 21 f0    	add    $0xf0213000,%edx
f0103665:	89 90 30 20 21 f0    	mov    %edx,-0xfdedfd0(%eax)
	//thiscpu->cpu_ts.ts_esp0 = KSTACKTOP - i * (KSTKSIZE + KSTKGAP);
	thiscpu->cpu_ts.ts_ss0 = GD_KD;
f010366b:	e8 66 23 00 00       	call   f01059d6 <cpunum>
f0103670:	6b c0 74             	imul   $0x74,%eax,%eax
f0103673:	66 c7 80 34 20 21 f0 	movw   $0x10,-0xfdedfcc(%eax)
f010367a:	10 00 
	thiscpu->cpu_ts.ts_iomb = sizeof(struct Taskstate);
f010367c:	e8 55 23 00 00       	call   f01059d6 <cpunum>
f0103681:	6b c0 74             	imul   $0x74,%eax,%eax
f0103684:	66 c7 80 92 20 21 f0 	movw   $0x68,-0xfdedf6e(%eax)
f010368b:	68 00 

	// Initialize the TSS slot of the gdt.
	gdt[(GD_TSS0 >> 3) + i] = SEG16(STS_T32A, (uint32_t) (&thiscpu->cpu_ts),
f010368d:	8d 5e 05             	lea    0x5(%esi),%ebx
f0103690:	e8 41 23 00 00       	call   f01059d6 <cpunum>
f0103695:	89 c7                	mov    %eax,%edi
f0103697:	e8 3a 23 00 00       	call   f01059d6 <cpunum>
f010369c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010369f:	e8 32 23 00 00       	call   f01059d6 <cpunum>
f01036a4:	66 c7 04 dd 40 03 12 	movw   $0x67,-0xfedfcc0(,%ebx,8)
f01036ab:	f0 67 00 
f01036ae:	6b ff 74             	imul   $0x74,%edi,%edi
f01036b1:	81 c7 2c 20 21 f0    	add    $0xf021202c,%edi
f01036b7:	66 89 3c dd 42 03 12 	mov    %di,-0xfedfcbe(,%ebx,8)
f01036be:	f0 
f01036bf:	6b 55 e4 74          	imul   $0x74,-0x1c(%ebp),%edx
f01036c3:	81 c2 2c 20 21 f0    	add    $0xf021202c,%edx
f01036c9:	c1 ea 10             	shr    $0x10,%edx
f01036cc:	88 14 dd 44 03 12 f0 	mov    %dl,-0xfedfcbc(,%ebx,8)
f01036d3:	c6 04 dd 46 03 12 f0 	movb   $0x40,-0xfedfcba(,%ebx,8)
f01036da:	40 
f01036db:	6b c0 74             	imul   $0x74,%eax,%eax
f01036de:	05 2c 20 21 f0       	add    $0xf021202c,%eax
f01036e3:	c1 e8 18             	shr    $0x18,%eax
f01036e6:	88 04 dd 47 03 12 f0 	mov    %al,-0xfedfcb9(,%ebx,8)
					sizeof(struct Taskstate) - 1, 0);
	gdt[(GD_TSS0 >> 3) + i].sd_s = 0;
f01036ed:	c6 04 dd 45 03 12 f0 	movb   $0x89,-0xfedfcbb(,%ebx,8)
f01036f4:	89 
}

static inline void
ltr(uint16_t sel)
{
	asm volatile("ltr %0" : : "r" (sel));
f01036f5:	8d 34 f5 28 00 00 00 	lea    0x28(,%esi,8),%esi
f01036fc:	0f 00 de             	ltr    %si
}

static inline void
lidt(void *p)
{
	asm volatile("lidt (%0)" : : "r" (p));
f01036ff:	b8 ac 03 12 f0       	mov    $0xf01203ac,%eax
f0103704:	0f 01 18             	lidtl  (%eax)
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0 + (i << 3));

	// Load the IDT
	lidt(&idt_pd);
}
f0103707:	83 c4 1c             	add    $0x1c,%esp
f010370a:	5b                   	pop    %ebx
f010370b:	5e                   	pop    %esi
f010370c:	5f                   	pop    %edi
f010370d:	5d                   	pop    %ebp
f010370e:	c3                   	ret    

f010370f <trap_init>:
}


void
trap_init(void)
{
f010370f:	55                   	push   %ebp
f0103710:	89 e5                	mov    %esp,%ebp
f0103712:	83 ec 08             	sub    $0x8,%esp
	extern struct Segdesc gdt[];

	// LAB 3: Your code here.

	SETGATE(idt[T_DIVIDE], 0, GD_KT, t_divide, 0);
f0103715:	b8 9a 40 10 f0       	mov    $0xf010409a,%eax
f010371a:	66 a3 60 12 21 f0    	mov    %ax,0xf0211260
f0103720:	66 c7 05 62 12 21 f0 	movw   $0x8,0xf0211262
f0103727:	08 00 
f0103729:	c6 05 64 12 21 f0 00 	movb   $0x0,0xf0211264
f0103730:	c6 05 65 12 21 f0 8e 	movb   $0x8e,0xf0211265
f0103737:	c1 e8 10             	shr    $0x10,%eax
f010373a:	66 a3 66 12 21 f0    	mov    %ax,0xf0211266
	SETGATE(idt[T_DEBUG], 0, GD_KT, t_debug, 0);
f0103740:	b8 a4 40 10 f0       	mov    $0xf01040a4,%eax
f0103745:	66 a3 68 12 21 f0    	mov    %ax,0xf0211268
f010374b:	66 c7 05 6a 12 21 f0 	movw   $0x8,0xf021126a
f0103752:	08 00 
f0103754:	c6 05 6c 12 21 f0 00 	movb   $0x0,0xf021126c
f010375b:	c6 05 6d 12 21 f0 8e 	movb   $0x8e,0xf021126d
f0103762:	c1 e8 10             	shr    $0x10,%eax
f0103765:	66 a3 6e 12 21 f0    	mov    %ax,0xf021126e
	SETGATE(idt[T_NMI], 0, GD_KT, t_nmi, 0);
f010376b:	b8 aa 40 10 f0       	mov    $0xf01040aa,%eax
f0103770:	66 a3 70 12 21 f0    	mov    %ax,0xf0211270
f0103776:	66 c7 05 72 12 21 f0 	movw   $0x8,0xf0211272
f010377d:	08 00 
f010377f:	c6 05 74 12 21 f0 00 	movb   $0x0,0xf0211274
f0103786:	c6 05 75 12 21 f0 8e 	movb   $0x8e,0xf0211275
f010378d:	c1 e8 10             	shr    $0x10,%eax
f0103790:	66 a3 76 12 21 f0    	mov    %ax,0xf0211276
	SETGATE(idt[T_BRKPT], 0, GD_KT, t_brkpt, 3);
f0103796:	b8 b0 40 10 f0       	mov    $0xf01040b0,%eax
f010379b:	66 a3 78 12 21 f0    	mov    %ax,0xf0211278
f01037a1:	66 c7 05 7a 12 21 f0 	movw   $0x8,0xf021127a
f01037a8:	08 00 
f01037aa:	c6 05 7c 12 21 f0 00 	movb   $0x0,0xf021127c
f01037b1:	c6 05 7d 12 21 f0 ee 	movb   $0xee,0xf021127d
f01037b8:	c1 e8 10             	shr    $0x10,%eax
f01037bb:	66 a3 7e 12 21 f0    	mov    %ax,0xf021127e
	SETGATE(idt[T_OFLOW], 0, GD_KT, t_oflow, 0);
f01037c1:	b8 b6 40 10 f0       	mov    $0xf01040b6,%eax
f01037c6:	66 a3 80 12 21 f0    	mov    %ax,0xf0211280
f01037cc:	66 c7 05 82 12 21 f0 	movw   $0x8,0xf0211282
f01037d3:	08 00 
f01037d5:	c6 05 84 12 21 f0 00 	movb   $0x0,0xf0211284
f01037dc:	c6 05 85 12 21 f0 8e 	movb   $0x8e,0xf0211285
f01037e3:	c1 e8 10             	shr    $0x10,%eax
f01037e6:	66 a3 86 12 21 f0    	mov    %ax,0xf0211286
	SETGATE(idt[T_BOUND], 0, GD_KT, t_bound, 0);
f01037ec:	b8 bc 40 10 f0       	mov    $0xf01040bc,%eax
f01037f1:	66 a3 88 12 21 f0    	mov    %ax,0xf0211288
f01037f7:	66 c7 05 8a 12 21 f0 	movw   $0x8,0xf021128a
f01037fe:	08 00 
f0103800:	c6 05 8c 12 21 f0 00 	movb   $0x0,0xf021128c
f0103807:	c6 05 8d 12 21 f0 8e 	movb   $0x8e,0xf021128d
f010380e:	c1 e8 10             	shr    $0x10,%eax
f0103811:	66 a3 8e 12 21 f0    	mov    %ax,0xf021128e
	SETGATE(idt[T_ILLOP], 0, GD_KT, t_illop, 0);
f0103817:	b8 c2 40 10 f0       	mov    $0xf01040c2,%eax
f010381c:	66 a3 90 12 21 f0    	mov    %ax,0xf0211290
f0103822:	66 c7 05 92 12 21 f0 	movw   $0x8,0xf0211292
f0103829:	08 00 
f010382b:	c6 05 94 12 21 f0 00 	movb   $0x0,0xf0211294
f0103832:	c6 05 95 12 21 f0 8e 	movb   $0x8e,0xf0211295
f0103839:	c1 e8 10             	shr    $0x10,%eax
f010383c:	66 a3 96 12 21 f0    	mov    %ax,0xf0211296
	SETGATE(idt[T_DEVICE], 0, GD_KT, t_device, 0);
f0103842:	b8 c8 40 10 f0       	mov    $0xf01040c8,%eax
f0103847:	66 a3 98 12 21 f0    	mov    %ax,0xf0211298
f010384d:	66 c7 05 9a 12 21 f0 	movw   $0x8,0xf021129a
f0103854:	08 00 
f0103856:	c6 05 9c 12 21 f0 00 	movb   $0x0,0xf021129c
f010385d:	c6 05 9d 12 21 f0 8e 	movb   $0x8e,0xf021129d
f0103864:	c1 e8 10             	shr    $0x10,%eax
f0103867:	66 a3 9e 12 21 f0    	mov    %ax,0xf021129e
	SETGATE(idt[T_DBLFLT], 0, GD_KT, t_dblflt, 0);
f010386d:	b8 ce 40 10 f0       	mov    $0xf01040ce,%eax
f0103872:	66 a3 a0 12 21 f0    	mov    %ax,0xf02112a0
f0103878:	66 c7 05 a2 12 21 f0 	movw   $0x8,0xf02112a2
f010387f:	08 00 
f0103881:	c6 05 a4 12 21 f0 00 	movb   $0x0,0xf02112a4
f0103888:	c6 05 a5 12 21 f0 8e 	movb   $0x8e,0xf02112a5
f010388f:	c1 e8 10             	shr    $0x10,%eax
f0103892:	66 a3 a6 12 21 f0    	mov    %ax,0xf02112a6
	SETGATE(idt[T_TSS], 0, GD_KT, t_tss, 0);
f0103898:	b8 d2 40 10 f0       	mov    $0xf01040d2,%eax
f010389d:	66 a3 b0 12 21 f0    	mov    %ax,0xf02112b0
f01038a3:	66 c7 05 b2 12 21 f0 	movw   $0x8,0xf02112b2
f01038aa:	08 00 
f01038ac:	c6 05 b4 12 21 f0 00 	movb   $0x0,0xf02112b4
f01038b3:	c6 05 b5 12 21 f0 8e 	movb   $0x8e,0xf02112b5
f01038ba:	c1 e8 10             	shr    $0x10,%eax
f01038bd:	66 a3 b6 12 21 f0    	mov    %ax,0xf02112b6
	SETGATE(idt[T_SEGNP], 0, GD_KT, t_segnp, 0);
f01038c3:	b8 d6 40 10 f0       	mov    $0xf01040d6,%eax
f01038c8:	66 a3 b8 12 21 f0    	mov    %ax,0xf02112b8
f01038ce:	66 c7 05 ba 12 21 f0 	movw   $0x8,0xf02112ba
f01038d5:	08 00 
f01038d7:	c6 05 bc 12 21 f0 00 	movb   $0x0,0xf02112bc
f01038de:	c6 05 bd 12 21 f0 8e 	movb   $0x8e,0xf02112bd
f01038e5:	c1 e8 10             	shr    $0x10,%eax
f01038e8:	66 a3 be 12 21 f0    	mov    %ax,0xf02112be
	SETGATE(idt[T_STACK], 0, GD_KT, t_stack, 0);
f01038ee:	b8 da 40 10 f0       	mov    $0xf01040da,%eax
f01038f3:	66 a3 c0 12 21 f0    	mov    %ax,0xf02112c0
f01038f9:	66 c7 05 c2 12 21 f0 	movw   $0x8,0xf02112c2
f0103900:	08 00 
f0103902:	c6 05 c4 12 21 f0 00 	movb   $0x0,0xf02112c4
f0103909:	c6 05 c5 12 21 f0 8e 	movb   $0x8e,0xf02112c5
f0103910:	c1 e8 10             	shr    $0x10,%eax
f0103913:	66 a3 c6 12 21 f0    	mov    %ax,0xf02112c6
	SETGATE(idt[T_GPFLT], 0, GD_KT, t_gpflt, 0);
f0103919:	b8 de 40 10 f0       	mov    $0xf01040de,%eax
f010391e:	66 a3 c8 12 21 f0    	mov    %ax,0xf02112c8
f0103924:	66 c7 05 ca 12 21 f0 	movw   $0x8,0xf02112ca
f010392b:	08 00 
f010392d:	c6 05 cc 12 21 f0 00 	movb   $0x0,0xf02112cc
f0103934:	c6 05 cd 12 21 f0 8e 	movb   $0x8e,0xf02112cd
f010393b:	c1 e8 10             	shr    $0x10,%eax
f010393e:	66 a3 ce 12 21 f0    	mov    %ax,0xf02112ce
	SETGATE(idt[T_PGFLT], 0, GD_KT, t_pgflt, 0);
f0103944:	b8 e2 40 10 f0       	mov    $0xf01040e2,%eax
f0103949:	66 a3 d0 12 21 f0    	mov    %ax,0xf02112d0
f010394f:	66 c7 05 d2 12 21 f0 	movw   $0x8,0xf02112d2
f0103956:	08 00 
f0103958:	c6 05 d4 12 21 f0 00 	movb   $0x0,0xf02112d4
f010395f:	c6 05 d5 12 21 f0 8e 	movb   $0x8e,0xf02112d5
f0103966:	c1 e8 10             	shr    $0x10,%eax
f0103969:	66 a3 d6 12 21 f0    	mov    %ax,0xf02112d6
	SETGATE(idt[T_FPERR], 0, GD_KT, t_fperr, 0);
f010396f:	b8 e6 40 10 f0       	mov    $0xf01040e6,%eax
f0103974:	66 a3 e0 12 21 f0    	mov    %ax,0xf02112e0
f010397a:	66 c7 05 e2 12 21 f0 	movw   $0x8,0xf02112e2
f0103981:	08 00 
f0103983:	c6 05 e4 12 21 f0 00 	movb   $0x0,0xf02112e4
f010398a:	c6 05 e5 12 21 f0 8e 	movb   $0x8e,0xf02112e5
f0103991:	c1 e8 10             	shr    $0x10,%eax
f0103994:	66 a3 e6 12 21 f0    	mov    %ax,0xf02112e6
	SETGATE(idt[T_ALIGN], 0, GD_KT, t_align, 0);
f010399a:	b8 ec 40 10 f0       	mov    $0xf01040ec,%eax
f010399f:	66 a3 e8 12 21 f0    	mov    %ax,0xf02112e8
f01039a5:	66 c7 05 ea 12 21 f0 	movw   $0x8,0xf02112ea
f01039ac:	08 00 
f01039ae:	c6 05 ec 12 21 f0 00 	movb   $0x0,0xf02112ec
f01039b5:	c6 05 ed 12 21 f0 8e 	movb   $0x8e,0xf02112ed
f01039bc:	c1 e8 10             	shr    $0x10,%eax
f01039bf:	66 a3 ee 12 21 f0    	mov    %ax,0xf02112ee
	SETGATE(idt[T_MCHK], 0, GD_KT, t_mchk, 0);
f01039c5:	b8 f0 40 10 f0       	mov    $0xf01040f0,%eax
f01039ca:	66 a3 f0 12 21 f0    	mov    %ax,0xf02112f0
f01039d0:	66 c7 05 f2 12 21 f0 	movw   $0x8,0xf02112f2
f01039d7:	08 00 
f01039d9:	c6 05 f4 12 21 f0 00 	movb   $0x0,0xf02112f4
f01039e0:	c6 05 f5 12 21 f0 8e 	movb   $0x8e,0xf02112f5
f01039e7:	c1 e8 10             	shr    $0x10,%eax
f01039ea:	66 a3 f6 12 21 f0    	mov    %ax,0xf02112f6
	SETGATE(idt[T_SIMDERR], 0, GD_KT, t_simderr, 0);
f01039f0:	b8 f6 40 10 f0       	mov    $0xf01040f6,%eax
f01039f5:	66 a3 f8 12 21 f0    	mov    %ax,0xf02112f8
f01039fb:	66 c7 05 fa 12 21 f0 	movw   $0x8,0xf02112fa
f0103a02:	08 00 
f0103a04:	c6 05 fc 12 21 f0 00 	movb   $0x0,0xf02112fc
f0103a0b:	c6 05 fd 12 21 f0 8e 	movb   $0x8e,0xf02112fd
f0103a12:	c1 e8 10             	shr    $0x10,%eax
f0103a15:	66 a3 fe 12 21 f0    	mov    %ax,0xf02112fe

	SETGATE(idt[T_SYSCALL], 0, GD_KT, t_syscall, 3);
f0103a1b:	b8 fc 40 10 f0       	mov    $0xf01040fc,%eax
f0103a20:	66 a3 e0 13 21 f0    	mov    %ax,0xf02113e0
f0103a26:	66 c7 05 e2 13 21 f0 	movw   $0x8,0xf02113e2
f0103a2d:	08 00 
f0103a2f:	c6 05 e4 13 21 f0 00 	movb   $0x0,0xf02113e4
f0103a36:	c6 05 e5 13 21 f0 ee 	movb   $0xee,0xf02113e5
f0103a3d:	c1 e8 10             	shr    $0x10,%eax
f0103a40:	66 a3 e6 13 21 f0    	mov    %ax,0xf02113e6

	SETGATE(idt[IRQ_OFFSET + IRQ_TIMER], 0, GD_KT, irq_timer, 0);
f0103a46:	b8 02 41 10 f0       	mov    $0xf0104102,%eax
f0103a4b:	66 a3 60 13 21 f0    	mov    %ax,0xf0211360
f0103a51:	66 c7 05 62 13 21 f0 	movw   $0x8,0xf0211362
f0103a58:	08 00 
f0103a5a:	c6 05 64 13 21 f0 00 	movb   $0x0,0xf0211364
f0103a61:	c6 05 65 13 21 f0 8e 	movb   $0x8e,0xf0211365
f0103a68:	c1 e8 10             	shr    $0x10,%eax
f0103a6b:	66 a3 66 13 21 f0    	mov    %ax,0xf0211366
	SETGATE(idt[IRQ_OFFSET + IRQ_KBD], 0, GD_KT, irq_kbd, 0);
f0103a71:	b8 08 41 10 f0       	mov    $0xf0104108,%eax
f0103a76:	66 a3 68 13 21 f0    	mov    %ax,0xf0211368
f0103a7c:	66 c7 05 6a 13 21 f0 	movw   $0x8,0xf021136a
f0103a83:	08 00 
f0103a85:	c6 05 6c 13 21 f0 00 	movb   $0x0,0xf021136c
f0103a8c:	c6 05 6d 13 21 f0 8e 	movb   $0x8e,0xf021136d
f0103a93:	c1 e8 10             	shr    $0x10,%eax
f0103a96:	66 a3 6e 13 21 f0    	mov    %ax,0xf021136e
	SETGATE(idt[IRQ_OFFSET + IRQ_SERIAL], 0, GD_KT, irq_serial, 0);
f0103a9c:	b8 0e 41 10 f0       	mov    $0xf010410e,%eax
f0103aa1:	66 a3 80 13 21 f0    	mov    %ax,0xf0211380
f0103aa7:	66 c7 05 82 13 21 f0 	movw   $0x8,0xf0211382
f0103aae:	08 00 
f0103ab0:	c6 05 84 13 21 f0 00 	movb   $0x0,0xf0211384
f0103ab7:	c6 05 85 13 21 f0 8e 	movb   $0x8e,0xf0211385
f0103abe:	c1 e8 10             	shr    $0x10,%eax
f0103ac1:	66 a3 86 13 21 f0    	mov    %ax,0xf0211386
	SETGATE(idt[IRQ_OFFSET + IRQ_SPURIOUS], 0, GD_KT, irq_spurious, 0);
f0103ac7:	b8 14 41 10 f0       	mov    $0xf0104114,%eax
f0103acc:	66 a3 98 13 21 f0    	mov    %ax,0xf0211398
f0103ad2:	66 c7 05 9a 13 21 f0 	movw   $0x8,0xf021139a
f0103ad9:	08 00 
f0103adb:	c6 05 9c 13 21 f0 00 	movb   $0x0,0xf021139c
f0103ae2:	c6 05 9d 13 21 f0 8e 	movb   $0x8e,0xf021139d
f0103ae9:	c1 e8 10             	shr    $0x10,%eax
f0103aec:	66 a3 9e 13 21 f0    	mov    %ax,0xf021139e
	SETGATE(idt[IRQ_OFFSET + IRQ_IDE], 0, GD_KT, irq_ide, 0);
f0103af2:	b8 1a 41 10 f0       	mov    $0xf010411a,%eax
f0103af7:	66 a3 d0 13 21 f0    	mov    %ax,0xf02113d0
f0103afd:	66 c7 05 d2 13 21 f0 	movw   $0x8,0xf02113d2
f0103b04:	08 00 
f0103b06:	c6 05 d4 13 21 f0 00 	movb   $0x0,0xf02113d4
f0103b0d:	c6 05 d5 13 21 f0 8e 	movb   $0x8e,0xf02113d5
f0103b14:	c1 e8 10             	shr    $0x10,%eax
f0103b17:	66 a3 d6 13 21 f0    	mov    %ax,0xf02113d6
	SETGATE(idt[IRQ_OFFSET + IRQ_ERROR], 0, GD_KT, irq_error, 0);
f0103b1d:	b8 20 41 10 f0       	mov    $0xf0104120,%eax
f0103b22:	66 a3 f8 13 21 f0    	mov    %ax,0xf02113f8
f0103b28:	66 c7 05 fa 13 21 f0 	movw   $0x8,0xf02113fa
f0103b2f:	08 00 
f0103b31:	c6 05 fc 13 21 f0 00 	movb   $0x0,0xf02113fc
f0103b38:	c6 05 fd 13 21 f0 8e 	movb   $0x8e,0xf02113fd
f0103b3f:	c1 e8 10             	shr    $0x10,%eax
f0103b42:	66 a3 fe 13 21 f0    	mov    %ax,0xf02113fe
	// Per-CPU setup 
	trap_init_percpu();
f0103b48:	e8 f5 fa ff ff       	call   f0103642 <trap_init_percpu>
}
f0103b4d:	c9                   	leave  
f0103b4e:	c3                   	ret    

f0103b4f <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f0103b4f:	55                   	push   %ebp
f0103b50:	89 e5                	mov    %esp,%ebp
f0103b52:	53                   	push   %ebx
f0103b53:	83 ec 0c             	sub    $0xc,%esp
f0103b56:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f0103b59:	ff 33                	pushl  (%ebx)
f0103b5b:	68 d8 72 10 f0       	push   $0xf01072d8
f0103b60:	e8 c9 fa ff ff       	call   f010362e <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f0103b65:	83 c4 08             	add    $0x8,%esp
f0103b68:	ff 73 04             	pushl  0x4(%ebx)
f0103b6b:	68 e7 72 10 f0       	push   $0xf01072e7
f0103b70:	e8 b9 fa ff ff       	call   f010362e <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f0103b75:	83 c4 08             	add    $0x8,%esp
f0103b78:	ff 73 08             	pushl  0x8(%ebx)
f0103b7b:	68 f6 72 10 f0       	push   $0xf01072f6
f0103b80:	e8 a9 fa ff ff       	call   f010362e <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f0103b85:	83 c4 08             	add    $0x8,%esp
f0103b88:	ff 73 0c             	pushl  0xc(%ebx)
f0103b8b:	68 05 73 10 f0       	push   $0xf0107305
f0103b90:	e8 99 fa ff ff       	call   f010362e <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f0103b95:	83 c4 08             	add    $0x8,%esp
f0103b98:	ff 73 10             	pushl  0x10(%ebx)
f0103b9b:	68 14 73 10 f0       	push   $0xf0107314
f0103ba0:	e8 89 fa ff ff       	call   f010362e <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f0103ba5:	83 c4 08             	add    $0x8,%esp
f0103ba8:	ff 73 14             	pushl  0x14(%ebx)
f0103bab:	68 23 73 10 f0       	push   $0xf0107323
f0103bb0:	e8 79 fa ff ff       	call   f010362e <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f0103bb5:	83 c4 08             	add    $0x8,%esp
f0103bb8:	ff 73 18             	pushl  0x18(%ebx)
f0103bbb:	68 32 73 10 f0       	push   $0xf0107332
f0103bc0:	e8 69 fa ff ff       	call   f010362e <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f0103bc5:	83 c4 08             	add    $0x8,%esp
f0103bc8:	ff 73 1c             	pushl  0x1c(%ebx)
f0103bcb:	68 41 73 10 f0       	push   $0xf0107341
f0103bd0:	e8 59 fa ff ff       	call   f010362e <cprintf>
}
f0103bd5:	83 c4 10             	add    $0x10,%esp
f0103bd8:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103bdb:	c9                   	leave  
f0103bdc:	c3                   	ret    

f0103bdd <print_trapframe>:
	lidt(&idt_pd);
}

void
print_trapframe(struct Trapframe *tf)
{
f0103bdd:	55                   	push   %ebp
f0103bde:	89 e5                	mov    %esp,%ebp
f0103be0:	56                   	push   %esi
f0103be1:	53                   	push   %ebx
f0103be2:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p from CPU %d\n", tf, cpunum());
f0103be5:	e8 ec 1d 00 00       	call   f01059d6 <cpunum>
f0103bea:	83 ec 04             	sub    $0x4,%esp
f0103bed:	50                   	push   %eax
f0103bee:	53                   	push   %ebx
f0103bef:	68 a5 73 10 f0       	push   $0xf01073a5
f0103bf4:	e8 35 fa ff ff       	call   f010362e <cprintf>
	print_regs(&tf->tf_regs);
f0103bf9:	89 1c 24             	mov    %ebx,(%esp)
f0103bfc:	e8 4e ff ff ff       	call   f0103b4f <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f0103c01:	83 c4 08             	add    $0x8,%esp
f0103c04:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f0103c08:	50                   	push   %eax
f0103c09:	68 c3 73 10 f0       	push   $0xf01073c3
f0103c0e:	e8 1b fa ff ff       	call   f010362e <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f0103c13:	83 c4 08             	add    $0x8,%esp
f0103c16:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f0103c1a:	50                   	push   %eax
f0103c1b:	68 d6 73 10 f0       	push   $0xf01073d6
f0103c20:	e8 09 fa ff ff       	call   f010362e <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103c25:	8b 43 28             	mov    0x28(%ebx),%eax
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < ARRAY_SIZE(excnames))
f0103c28:	83 c4 10             	add    $0x10,%esp
f0103c2b:	83 f8 13             	cmp    $0x13,%eax
f0103c2e:	77 09                	ja     f0103c39 <print_trapframe+0x5c>
		return excnames[trapno];
f0103c30:	8b 14 85 80 76 10 f0 	mov    -0xfef8980(,%eax,4),%edx
f0103c37:	eb 1f                	jmp    f0103c58 <print_trapframe+0x7b>
	if (trapno == T_SYSCALL)
f0103c39:	83 f8 30             	cmp    $0x30,%eax
f0103c3c:	74 15                	je     f0103c53 <print_trapframe+0x76>
		return "System call";
	if (trapno >= IRQ_OFFSET && trapno < IRQ_OFFSET + 16)
f0103c3e:	8d 50 e0             	lea    -0x20(%eax),%edx
		return "Hardware Interrupt";
	return "(unknown trap)";
f0103c41:	83 fa 10             	cmp    $0x10,%edx
f0103c44:	b9 6f 73 10 f0       	mov    $0xf010736f,%ecx
f0103c49:	ba 5c 73 10 f0       	mov    $0xf010735c,%edx
f0103c4e:	0f 43 d1             	cmovae %ecx,%edx
f0103c51:	eb 05                	jmp    f0103c58 <print_trapframe+0x7b>
	};

	if (trapno < ARRAY_SIZE(excnames))
		return excnames[trapno];
	if (trapno == T_SYSCALL)
		return "System call";
f0103c53:	ba 50 73 10 f0       	mov    $0xf0107350,%edx
{
	cprintf("TRAP frame at %p from CPU %d\n", tf, cpunum());
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103c58:	83 ec 04             	sub    $0x4,%esp
f0103c5b:	52                   	push   %edx
f0103c5c:	50                   	push   %eax
f0103c5d:	68 e9 73 10 f0       	push   $0xf01073e9
f0103c62:	e8 c7 f9 ff ff       	call   f010362e <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0103c67:	83 c4 10             	add    $0x10,%esp
f0103c6a:	3b 1d 60 1a 21 f0    	cmp    0xf0211a60,%ebx
f0103c70:	75 1a                	jne    f0103c8c <print_trapframe+0xaf>
f0103c72:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103c76:	75 14                	jne    f0103c8c <print_trapframe+0xaf>

static inline uint32_t
rcr2(void)
{
	uint32_t val;
	asm volatile("movl %%cr2,%0" : "=r" (val));
f0103c78:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f0103c7b:	83 ec 08             	sub    $0x8,%esp
f0103c7e:	50                   	push   %eax
f0103c7f:	68 fb 73 10 f0       	push   $0xf01073fb
f0103c84:	e8 a5 f9 ff ff       	call   f010362e <cprintf>
f0103c89:	83 c4 10             	add    $0x10,%esp
	cprintf("  err  0x%08x", tf->tf_err);
f0103c8c:	83 ec 08             	sub    $0x8,%esp
f0103c8f:	ff 73 2c             	pushl  0x2c(%ebx)
f0103c92:	68 0a 74 10 f0       	push   $0xf010740a
f0103c97:	e8 92 f9 ff ff       	call   f010362e <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f0103c9c:	83 c4 10             	add    $0x10,%esp
f0103c9f:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103ca3:	75 49                	jne    f0103cee <print_trapframe+0x111>
		cprintf(" [%s, %s, %s]\n",
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
f0103ca5:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f0103ca8:	89 c2                	mov    %eax,%edx
f0103caa:	83 e2 01             	and    $0x1,%edx
f0103cad:	ba 89 73 10 f0       	mov    $0xf0107389,%edx
f0103cb2:	b9 7e 73 10 f0       	mov    $0xf010737e,%ecx
f0103cb7:	0f 44 ca             	cmove  %edx,%ecx
f0103cba:	89 c2                	mov    %eax,%edx
f0103cbc:	83 e2 02             	and    $0x2,%edx
f0103cbf:	ba 9b 73 10 f0       	mov    $0xf010739b,%edx
f0103cc4:	be 95 73 10 f0       	mov    $0xf0107395,%esi
f0103cc9:	0f 45 d6             	cmovne %esi,%edx
f0103ccc:	83 e0 04             	and    $0x4,%eax
f0103ccf:	be d5 74 10 f0       	mov    $0xf01074d5,%esi
f0103cd4:	b8 a0 73 10 f0       	mov    $0xf01073a0,%eax
f0103cd9:	0f 44 c6             	cmove  %esi,%eax
f0103cdc:	51                   	push   %ecx
f0103cdd:	52                   	push   %edx
f0103cde:	50                   	push   %eax
f0103cdf:	68 18 74 10 f0       	push   $0xf0107418
f0103ce4:	e8 45 f9 ff ff       	call   f010362e <cprintf>
f0103ce9:	83 c4 10             	add    $0x10,%esp
f0103cec:	eb 10                	jmp    f0103cfe <print_trapframe+0x121>
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f0103cee:	83 ec 0c             	sub    $0xc,%esp
f0103cf1:	68 44 72 10 f0       	push   $0xf0107244
f0103cf6:	e8 33 f9 ff ff       	call   f010362e <cprintf>
f0103cfb:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f0103cfe:	83 ec 08             	sub    $0x8,%esp
f0103d01:	ff 73 30             	pushl  0x30(%ebx)
f0103d04:	68 27 74 10 f0       	push   $0xf0107427
f0103d09:	e8 20 f9 ff ff       	call   f010362e <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f0103d0e:	83 c4 08             	add    $0x8,%esp
f0103d11:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f0103d15:	50                   	push   %eax
f0103d16:	68 36 74 10 f0       	push   $0xf0107436
f0103d1b:	e8 0e f9 ff ff       	call   f010362e <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f0103d20:	83 c4 08             	add    $0x8,%esp
f0103d23:	ff 73 38             	pushl  0x38(%ebx)
f0103d26:	68 49 74 10 f0       	push   $0xf0107449
f0103d2b:	e8 fe f8 ff ff       	call   f010362e <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f0103d30:	83 c4 10             	add    $0x10,%esp
f0103d33:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0103d37:	74 25                	je     f0103d5e <print_trapframe+0x181>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f0103d39:	83 ec 08             	sub    $0x8,%esp
f0103d3c:	ff 73 3c             	pushl  0x3c(%ebx)
f0103d3f:	68 58 74 10 f0       	push   $0xf0107458
f0103d44:	e8 e5 f8 ff ff       	call   f010362e <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f0103d49:	83 c4 08             	add    $0x8,%esp
f0103d4c:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f0103d50:	50                   	push   %eax
f0103d51:	68 67 74 10 f0       	push   $0xf0107467
f0103d56:	e8 d3 f8 ff ff       	call   f010362e <cprintf>
f0103d5b:	83 c4 10             	add    $0x10,%esp
	}
}
f0103d5e:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0103d61:	5b                   	pop    %ebx
f0103d62:	5e                   	pop    %esi
f0103d63:	5d                   	pop    %ebp
f0103d64:	c3                   	ret    

f0103d65 <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f0103d65:	55                   	push   %ebp
f0103d66:	89 e5                	mov    %esp,%ebp
f0103d68:	57                   	push   %edi
f0103d69:	56                   	push   %esi
f0103d6a:	53                   	push   %ebx
f0103d6b:	83 ec 0c             	sub    $0xc,%esp
f0103d6e:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103d71:	0f 20 d6             	mov    %cr2,%esi
	fault_va = rcr2();

	// Handle kernel-mode page faults.

	// LAB 3: Your code here.
	if (tf->tf_cs == GD_KT) {
f0103d74:	66 83 7b 34 08       	cmpw   $0x8,0x34(%ebx)
f0103d79:	75 17                	jne    f0103d92 <page_fault_handler+0x2d>
		// Trapped from kernel mode
		panic("page_fault_handler: page fault in kernel mode");
f0103d7b:	83 ec 04             	sub    $0x4,%esp
f0103d7e:	68 20 76 10 f0       	push   $0xf0107620
f0103d83:	68 6a 01 00 00       	push   $0x16a
f0103d88:	68 7a 74 10 f0       	push   $0xf010747a
f0103d8d:	e8 ae c2 ff ff       	call   f0100040 <_panic>
	//   To change what the user environment runs, modify 'curenv->env_tf'
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.
    
    if(curenv->env_pgfault_upcall!=NULL){
f0103d92:	e8 3f 1c 00 00       	call   f01059d6 <cpunum>
f0103d97:	6b c0 74             	imul   $0x74,%eax,%eax
f0103d9a:	8b 80 28 20 21 f0    	mov    -0xfdedfd8(%eax),%eax
f0103da0:	83 78 64 00          	cmpl   $0x0,0x64(%eax)
f0103da4:	0f 84 8b 00 00 00    	je     f0103e35 <page_fault_handler+0xd0>
        struct UTrapframe *utf;
        uintptr_t utf_addr;  
        if(tf->tf_esp >= UXSTACKTOP - PGSIZE && tf->tf_esp < UXSTACKTOP){
f0103daa:	8b 43 3c             	mov    0x3c(%ebx),%eax
f0103dad:	8d 90 00 10 40 11    	lea    0x11401000(%eax),%edx
            utf_addr = tf->tf_esp - sizeof(struct UTrapframe) - 4;
f0103db3:	83 e8 38             	sub    $0x38,%eax
f0103db6:	81 fa ff 0f 00 00    	cmp    $0xfff,%edx
f0103dbc:	ba cc ff bf ee       	mov    $0xeebfffcc,%edx
f0103dc1:	0f 46 d0             	cmovbe %eax,%edx
f0103dc4:	89 d7                	mov    %edx,%edi
        }
        else{
            utf_addr = UXSTACKTOP - sizeof(struct UTrapframe);
        }
        user_mem_assert(curenv, (void *) utf_addr, sizeof(struct UTrapframe), PTE_W);        
f0103dc6:	e8 0b 1c 00 00       	call   f01059d6 <cpunum>
f0103dcb:	6a 02                	push   $0x2
f0103dcd:	6a 34                	push   $0x34
f0103dcf:	57                   	push   %edi
f0103dd0:	6b c0 74             	imul   $0x74,%eax,%eax
f0103dd3:	ff b0 28 20 21 f0    	pushl  -0xfdedfd8(%eax)
f0103dd9:	e8 9c ef ff ff       	call   f0102d7a <user_mem_assert>

        utf = (struct UTrapframe *) utf_addr;
        utf->utf_fault_va = fault_va;
f0103dde:	89 fa                	mov    %edi,%edx
f0103de0:	89 37                	mov    %esi,(%edi)
        utf->utf_err = tf->tf_err;
f0103de2:	8b 43 2c             	mov    0x2c(%ebx),%eax
f0103de5:	89 47 04             	mov    %eax,0x4(%edi)
        utf->utf_regs = tf->tf_regs;
f0103de8:	8d 7f 08             	lea    0x8(%edi),%edi
f0103deb:	b9 08 00 00 00       	mov    $0x8,%ecx
f0103df0:	89 de                	mov    %ebx,%esi
f0103df2:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
        utf->utf_eip = tf->tf_eip;
f0103df4:	8b 43 30             	mov    0x30(%ebx),%eax
f0103df7:	89 42 28             	mov    %eax,0x28(%edx)
        utf->utf_eflags = tf->tf_eflags;
f0103dfa:	8b 43 38             	mov    0x38(%ebx),%eax
f0103dfd:	89 d7                	mov    %edx,%edi
f0103dff:	89 42 2c             	mov    %eax,0x2c(%edx)
        utf->utf_esp = tf->tf_esp;
f0103e02:	8b 43 3c             	mov    0x3c(%ebx),%eax
f0103e05:	89 42 30             	mov    %eax,0x30(%edx)

        tf->tf_eip = (uintptr_t) curenv->env_pgfault_upcall;
f0103e08:	e8 c9 1b 00 00       	call   f01059d6 <cpunum>
f0103e0d:	6b c0 74             	imul   $0x74,%eax,%eax
f0103e10:	8b 80 28 20 21 f0    	mov    -0xfdedfd8(%eax),%eax
f0103e16:	8b 40 64             	mov    0x64(%eax),%eax
f0103e19:	89 43 30             	mov    %eax,0x30(%ebx)
        tf->tf_esp = utf_addr;
f0103e1c:	89 7b 3c             	mov    %edi,0x3c(%ebx)
        env_run(curenv);
f0103e1f:	e8 b2 1b 00 00       	call   f01059d6 <cpunum>
f0103e24:	83 c4 04             	add    $0x4,%esp
f0103e27:	6b c0 74             	imul   $0x74,%eax,%eax
f0103e2a:	ff b0 28 20 21 f0    	pushl  -0xfdedfd8(%eax)
f0103e30:	e8 c3 f5 ff ff       	call   f01033f8 <env_run>
    } 
    
	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103e35:	8b 7b 30             	mov    0x30(%ebx),%edi
		curenv->env_id, fault_va, tf->tf_eip);
f0103e38:	e8 99 1b 00 00       	call   f01059d6 <cpunum>
        tf->tf_esp = utf_addr;
        env_run(curenv);
    } 
    
	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103e3d:	57                   	push   %edi
f0103e3e:	56                   	push   %esi
		curenv->env_id, fault_va, tf->tf_eip);
f0103e3f:	6b c0 74             	imul   $0x74,%eax,%eax
        tf->tf_esp = utf_addr;
        env_run(curenv);
    } 
    
	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103e42:	8b 80 28 20 21 f0    	mov    -0xfdedfd8(%eax),%eax
f0103e48:	ff 70 48             	pushl  0x48(%eax)
f0103e4b:	68 50 76 10 f0       	push   $0xf0107650
f0103e50:	e8 d9 f7 ff ff       	call   f010362e <cprintf>
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f0103e55:	89 1c 24             	mov    %ebx,(%esp)
f0103e58:	e8 80 fd ff ff       	call   f0103bdd <print_trapframe>
	env_destroy(curenv);
f0103e5d:	e8 74 1b 00 00       	call   f01059d6 <cpunum>
f0103e62:	83 c4 04             	add    $0x4,%esp
f0103e65:	6b c0 74             	imul   $0x74,%eax,%eax
f0103e68:	ff b0 28 20 21 f0    	pushl  -0xfdedfd8(%eax)
f0103e6e:	e8 e6 f4 ff ff       	call   f0103359 <env_destroy>
}
f0103e73:	83 c4 10             	add    $0x10,%esp
f0103e76:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103e79:	5b                   	pop    %ebx
f0103e7a:	5e                   	pop    %esi
f0103e7b:	5f                   	pop    %edi
f0103e7c:	5d                   	pop    %ebp
f0103e7d:	c3                   	ret    

f0103e7e <trap>:
	}
}

void
trap(struct Trapframe *tf)
{
f0103e7e:	55                   	push   %ebp
f0103e7f:	89 e5                	mov    %esp,%ebp
f0103e81:	57                   	push   %edi
f0103e82:	56                   	push   %esi
f0103e83:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f0103e86:	fc                   	cld    

	// Halt the CPU if some other CPU has called panic()
	extern char *panicstr;
	if (panicstr)
f0103e87:	83 3d 80 1e 21 f0 00 	cmpl   $0x0,0xf0211e80
f0103e8e:	74 01                	je     f0103e91 <trap+0x13>
		asm volatile("hlt");
f0103e90:	f4                   	hlt    

	// Re-acqurie the big kernel lock if we were halted in
	// sched_yield()
	if (xchg(&thiscpu->cpu_status, CPU_STARTED) == CPU_HALTED)
f0103e91:	e8 40 1b 00 00       	call   f01059d6 <cpunum>
f0103e96:	6b d0 74             	imul   $0x74,%eax,%edx
f0103e99:	81 c2 20 20 21 f0    	add    $0xf0212020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"
f0103e9f:	b8 01 00 00 00       	mov    $0x1,%eax
f0103ea4:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
f0103ea8:	83 f8 02             	cmp    $0x2,%eax
f0103eab:	75 10                	jne    f0103ebd <trap+0x3f>
extern struct spinlock kernel_lock;

static inline void
lock_kernel(void)
{
	spin_lock(&kernel_lock);
f0103ead:	83 ec 0c             	sub    $0xc,%esp
f0103eb0:	68 c0 03 12 f0       	push   $0xf01203c0
f0103eb5:	e8 8a 1d 00 00       	call   f0105c44 <spin_lock>
f0103eba:	83 c4 10             	add    $0x10,%esp

static inline uint32_t
read_eflags(void)
{
	uint32_t eflags;
	asm volatile("pushfl; popl %0" : "=r" (eflags));
f0103ebd:	9c                   	pushf  
f0103ebe:	58                   	pop    %eax
		lock_kernel();
	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f0103ebf:	f6 c4 02             	test   $0x2,%ah
f0103ec2:	74 19                	je     f0103edd <trap+0x5f>
f0103ec4:	68 86 74 10 f0       	push   $0xf0107486
f0103ec9:	68 8a 6f 10 f0       	push   $0xf0106f8a
f0103ece:	68 32 01 00 00       	push   $0x132
f0103ed3:	68 7a 74 10 f0       	push   $0xf010747a
f0103ed8:	e8 63 c1 ff ff       	call   f0100040 <_panic>

	if ((tf->tf_cs & 3) == 3) {
f0103edd:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0103ee1:	83 e0 03             	and    $0x3,%eax
f0103ee4:	66 83 f8 03          	cmp    $0x3,%ax
f0103ee8:	0f 85 a0 00 00 00    	jne    f0103f8e <trap+0x110>
f0103eee:	83 ec 0c             	sub    $0xc,%esp
f0103ef1:	68 c0 03 12 f0       	push   $0xf01203c0
f0103ef6:	e8 49 1d 00 00       	call   f0105c44 <spin_lock>
		// Trapped from user mode.
		// Acquire the big kernel lock before doing any
		// serious kernel work.
		// LAB 4: Your code here.
        lock_kernel();
		assert(curenv);
f0103efb:	e8 d6 1a 00 00       	call   f01059d6 <cpunum>
f0103f00:	6b c0 74             	imul   $0x74,%eax,%eax
f0103f03:	83 c4 10             	add    $0x10,%esp
f0103f06:	83 b8 28 20 21 f0 00 	cmpl   $0x0,-0xfdedfd8(%eax)
f0103f0d:	75 19                	jne    f0103f28 <trap+0xaa>
f0103f0f:	68 9f 74 10 f0       	push   $0xf010749f
f0103f14:	68 8a 6f 10 f0       	push   $0xf0106f8a
f0103f19:	68 3a 01 00 00       	push   $0x13a
f0103f1e:	68 7a 74 10 f0       	push   $0xf010747a
f0103f23:	e8 18 c1 ff ff       	call   f0100040 <_panic>

		// Garbage collect if current enviroment is a zombie
		if (curenv->env_status == ENV_DYING) {
f0103f28:	e8 a9 1a 00 00       	call   f01059d6 <cpunum>
f0103f2d:	6b c0 74             	imul   $0x74,%eax,%eax
f0103f30:	8b 80 28 20 21 f0    	mov    -0xfdedfd8(%eax),%eax
f0103f36:	83 78 54 01          	cmpl   $0x1,0x54(%eax)
f0103f3a:	75 2d                	jne    f0103f69 <trap+0xeb>
			env_free(curenv);
f0103f3c:	e8 95 1a 00 00       	call   f01059d6 <cpunum>
f0103f41:	83 ec 0c             	sub    $0xc,%esp
f0103f44:	6b c0 74             	imul   $0x74,%eax,%eax
f0103f47:	ff b0 28 20 21 f0    	pushl  -0xfdedfd8(%eax)
f0103f4d:	e8 61 f2 ff ff       	call   f01031b3 <env_free>
			curenv = NULL;
f0103f52:	e8 7f 1a 00 00       	call   f01059d6 <cpunum>
f0103f57:	6b c0 74             	imul   $0x74,%eax,%eax
f0103f5a:	c7 80 28 20 21 f0 00 	movl   $0x0,-0xfdedfd8(%eax)
f0103f61:	00 00 00 
			sched_yield();
f0103f64:	e8 a2 02 00 00       	call   f010420b <sched_yield>
		}

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f0103f69:	e8 68 1a 00 00       	call   f01059d6 <cpunum>
f0103f6e:	6b c0 74             	imul   $0x74,%eax,%eax
f0103f71:	8b 80 28 20 21 f0    	mov    -0xfdedfd8(%eax),%eax
f0103f77:	b9 11 00 00 00       	mov    $0x11,%ecx
f0103f7c:	89 c7                	mov    %eax,%edi
f0103f7e:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f0103f80:	e8 51 1a 00 00       	call   f01059d6 <cpunum>
f0103f85:	6b c0 74             	imul   $0x74,%eax,%eax
f0103f88:	8b b0 28 20 21 f0    	mov    -0xfdedfd8(%eax),%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f0103f8e:	89 35 60 1a 21 f0    	mov    %esi,0xf0211a60
trap_dispatch(struct Trapframe *tf)
{
	// Handle processor exceptions.
	// LAB 3: Your code here.
	int r;
	switch(tf->tf_trapno){
f0103f94:	8b 46 28             	mov    0x28(%esi),%eax
f0103f97:	83 f8 0e             	cmp    $0xe,%eax
f0103f9a:	74 30                	je     f0103fcc <trap+0x14e>
f0103f9c:	83 f8 30             	cmp    $0x30,%eax
f0103f9f:	74 07                	je     f0103fa8 <trap+0x12a>
f0103fa1:	83 f8 03             	cmp    $0x3,%eax
f0103fa4:	75 42                	jne    f0103fe8 <trap+0x16a>
f0103fa6:	eb 32                	jmp    f0103fda <trap+0x15c>
		case T_SYSCALL:
			    tf->tf_regs.reg_eax = 
                    syscall(tf->tf_regs.reg_eax, tf->tf_regs.reg_edx, tf->tf_regs.reg_ecx,
f0103fa8:	83 ec 08             	sub    $0x8,%esp
f0103fab:	ff 76 04             	pushl  0x4(%esi)
f0103fae:	ff 36                	pushl  (%esi)
f0103fb0:	ff 76 10             	pushl  0x10(%esi)
f0103fb3:	ff 76 18             	pushl  0x18(%esi)
f0103fb6:	ff 76 14             	pushl  0x14(%esi)
f0103fb9:	ff 76 1c             	pushl  0x1c(%esi)
f0103fbc:	e8 0e 03 00 00       	call   f01042cf <syscall>
	// Handle processor exceptions.
	// LAB 3: Your code here.
	int r;
	switch(tf->tf_trapno){
		case T_SYSCALL:
			    tf->tf_regs.reg_eax = 
f0103fc1:	89 46 1c             	mov    %eax,0x1c(%esi)
f0103fc4:	83 c4 20             	add    $0x20,%esp
f0103fc7:	e9 8d 00 00 00       	jmp    f0104059 <trap+0x1db>
            if (tf->tf_regs.reg_eax < 0) {
                panic("trap_dispatch: %e", tf->tf_regs.reg_eax);
            }
			return;
		case T_PGFLT:
			page_fault_handler(tf);
f0103fcc:	83 ec 0c             	sub    $0xc,%esp
f0103fcf:	56                   	push   %esi
f0103fd0:	e8 90 fd ff ff       	call   f0103d65 <page_fault_handler>
f0103fd5:	83 c4 10             	add    $0x10,%esp
f0103fd8:	eb 7f                	jmp    f0104059 <trap+0x1db>
			return;
		case T_BRKPT:
			monitor(tf);
f0103fda:	83 ec 0c             	sub    $0xc,%esp
f0103fdd:	56                   	push   %esi
f0103fde:	e8 43 c9 ff ff       	call   f0100926 <monitor>
f0103fe3:	83 c4 10             	add    $0x10,%esp
f0103fe6:	eb 71                	jmp    f0104059 <trap+0x1db>
	}

	// Handle spurious interrupts
	// The hardware sometimes raises these because of noise on the
	// IRQ line or other reasons. We don't care.
	if (tf->tf_trapno == IRQ_OFFSET + IRQ_SPURIOUS) {
f0103fe8:	83 f8 27             	cmp    $0x27,%eax
f0103feb:	75 1a                	jne    f0104007 <trap+0x189>
		cprintf("Spurious interrupt on irq 7\n");
f0103fed:	83 ec 0c             	sub    $0xc,%esp
f0103ff0:	68 a6 74 10 f0       	push   $0xf01074a6
f0103ff5:	e8 34 f6 ff ff       	call   f010362e <cprintf>
		print_trapframe(tf);
f0103ffa:	89 34 24             	mov    %esi,(%esp)
f0103ffd:	e8 db fb ff ff       	call   f0103bdd <print_trapframe>
f0104002:	83 c4 10             	add    $0x10,%esp
f0104005:	eb 52                	jmp    f0104059 <trap+0x1db>
	}

	// Handle clock interrupts. Don't forget to acknowledge the
	// interrupt using lapic_eoi() before calling the scheduler!
	// LAB 4: Your code here.
    if (tf->tf_trapno == IRQ_OFFSET + IRQ_TIMER) {
f0104007:	83 f8 20             	cmp    $0x20,%eax
f010400a:	75 0a                	jne    f0104016 <trap+0x198>
        lapic_eoi();
f010400c:	e8 10 1b 00 00       	call   f0105b21 <lapic_eoi>
        sched_yield();
f0104011:	e8 f5 01 00 00       	call   f010420b <sched_yield>

	// Handle keyboard and serial interrupts.
	// LAB 5: Your code here.

	// Unexpected trap: The user process or the kernel has a bug.
	print_trapframe(tf);
f0104016:	83 ec 0c             	sub    $0xc,%esp
f0104019:	56                   	push   %esi
f010401a:	e8 be fb ff ff       	call   f0103bdd <print_trapframe>
	if (tf->tf_cs == GD_KT)
f010401f:	83 c4 10             	add    $0x10,%esp
f0104022:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f0104027:	75 17                	jne    f0104040 <trap+0x1c2>
		panic("unhandled trap in kernel");
f0104029:	83 ec 04             	sub    $0x4,%esp
f010402c:	68 c3 74 10 f0       	push   $0xf01074c3
f0104031:	68 18 01 00 00       	push   $0x118
f0104036:	68 7a 74 10 f0       	push   $0xf010747a
f010403b:	e8 00 c0 ff ff       	call   f0100040 <_panic>
	else {
		env_destroy(curenv);
f0104040:	e8 91 19 00 00       	call   f01059d6 <cpunum>
f0104045:	83 ec 0c             	sub    $0xc,%esp
f0104048:	6b c0 74             	imul   $0x74,%eax,%eax
f010404b:	ff b0 28 20 21 f0    	pushl  -0xfdedfd8(%eax)
f0104051:	e8 03 f3 ff ff       	call   f0103359 <env_destroy>
f0104056:	83 c4 10             	add    $0x10,%esp
	trap_dispatch(tf);

	// If we made it to this point, then no other environment was
	// scheduled, so we should return to the current environment
	// if doing so makes sense.
	if (curenv && curenv->env_status == ENV_RUNNING)
f0104059:	e8 78 19 00 00       	call   f01059d6 <cpunum>
f010405e:	6b c0 74             	imul   $0x74,%eax,%eax
f0104061:	83 b8 28 20 21 f0 00 	cmpl   $0x0,-0xfdedfd8(%eax)
f0104068:	74 2a                	je     f0104094 <trap+0x216>
f010406a:	e8 67 19 00 00       	call   f01059d6 <cpunum>
f010406f:	6b c0 74             	imul   $0x74,%eax,%eax
f0104072:	8b 80 28 20 21 f0    	mov    -0xfdedfd8(%eax),%eax
f0104078:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f010407c:	75 16                	jne    f0104094 <trap+0x216>
		env_run(curenv);
f010407e:	e8 53 19 00 00       	call   f01059d6 <cpunum>
f0104083:	83 ec 0c             	sub    $0xc,%esp
f0104086:	6b c0 74             	imul   $0x74,%eax,%eax
f0104089:	ff b0 28 20 21 f0    	pushl  -0xfdedfd8(%eax)
f010408f:	e8 64 f3 ff ff       	call   f01033f8 <env_run>
	else
		sched_yield();
f0104094:	e8 72 01 00 00       	call   f010420b <sched_yield>
f0104099:	90                   	nop

f010409a <t_divide>:
.text

/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */
TRAPHANDLER_NOEC(t_divide, T_DIVIDE)
f010409a:	6a 00                	push   $0x0
f010409c:	6a 00                	push   $0x0
f010409e:	e9 83 00 00 00       	jmp    f0104126 <_alltraps>
f01040a3:	90                   	nop

f01040a4 <t_debug>:
TRAPHANDLER_NOEC(t_debug, T_DEBUG)
f01040a4:	6a 00                	push   $0x0
f01040a6:	6a 01                	push   $0x1
f01040a8:	eb 7c                	jmp    f0104126 <_alltraps>

f01040aa <t_nmi>:
TRAPHANDLER_NOEC(t_nmi, T_NMI)
f01040aa:	6a 00                	push   $0x0
f01040ac:	6a 02                	push   $0x2
f01040ae:	eb 76                	jmp    f0104126 <_alltraps>

f01040b0 <t_brkpt>:
TRAPHANDLER_NOEC(t_brkpt, T_BRKPT)
f01040b0:	6a 00                	push   $0x0
f01040b2:	6a 03                	push   $0x3
f01040b4:	eb 70                	jmp    f0104126 <_alltraps>

f01040b6 <t_oflow>:
TRAPHANDLER_NOEC(t_oflow, T_OFLOW)
f01040b6:	6a 00                	push   $0x0
f01040b8:	6a 04                	push   $0x4
f01040ba:	eb 6a                	jmp    f0104126 <_alltraps>

f01040bc <t_bound>:
TRAPHANDLER_NOEC(t_bound, T_BOUND)
f01040bc:	6a 00                	push   $0x0
f01040be:	6a 05                	push   $0x5
f01040c0:	eb 64                	jmp    f0104126 <_alltraps>

f01040c2 <t_illop>:
TRAPHANDLER_NOEC(t_illop, T_ILLOP)
f01040c2:	6a 00                	push   $0x0
f01040c4:	6a 06                	push   $0x6
f01040c6:	eb 5e                	jmp    f0104126 <_alltraps>

f01040c8 <t_device>:
TRAPHANDLER_NOEC(t_device, T_DEVICE)
f01040c8:	6a 00                	push   $0x0
f01040ca:	6a 07                	push   $0x7
f01040cc:	eb 58                	jmp    f0104126 <_alltraps>

f01040ce <t_dblflt>:
TRAPHANDLER(t_dblflt, T_DBLFLT)
f01040ce:	6a 08                	push   $0x8
f01040d0:	eb 54                	jmp    f0104126 <_alltraps>

f01040d2 <t_tss>:
TRAPHANDLER(t_tss, T_TSS)
f01040d2:	6a 0a                	push   $0xa
f01040d4:	eb 50                	jmp    f0104126 <_alltraps>

f01040d6 <t_segnp>:
TRAPHANDLER(t_segnp, T_SEGNP)
f01040d6:	6a 0b                	push   $0xb
f01040d8:	eb 4c                	jmp    f0104126 <_alltraps>

f01040da <t_stack>:
TRAPHANDLER(t_stack, T_STACK)
f01040da:	6a 0c                	push   $0xc
f01040dc:	eb 48                	jmp    f0104126 <_alltraps>

f01040de <t_gpflt>:
TRAPHANDLER(t_gpflt, T_GPFLT)
f01040de:	6a 0d                	push   $0xd
f01040e0:	eb 44                	jmp    f0104126 <_alltraps>

f01040e2 <t_pgflt>:
TRAPHANDLER(t_pgflt, T_PGFLT)
f01040e2:	6a 0e                	push   $0xe
f01040e4:	eb 40                	jmp    f0104126 <_alltraps>

f01040e6 <t_fperr>:
TRAPHANDLER_NOEC(t_fperr, T_FPERR)
f01040e6:	6a 00                	push   $0x0
f01040e8:	6a 10                	push   $0x10
f01040ea:	eb 3a                	jmp    f0104126 <_alltraps>

f01040ec <t_align>:
TRAPHANDLER(t_align, T_ALIGN)
f01040ec:	6a 11                	push   $0x11
f01040ee:	eb 36                	jmp    f0104126 <_alltraps>

f01040f0 <t_mchk>:
TRAPHANDLER_NOEC(t_mchk, T_MCHK)
f01040f0:	6a 00                	push   $0x0
f01040f2:	6a 12                	push   $0x12
f01040f4:	eb 30                	jmp    f0104126 <_alltraps>

f01040f6 <t_simderr>:
TRAPHANDLER_NOEC(t_simderr, T_SIMDERR)
f01040f6:	6a 00                	push   $0x0
f01040f8:	6a 13                	push   $0x13
f01040fa:	eb 2a                	jmp    f0104126 <_alltraps>

f01040fc <t_syscall>:
TRAPHANDLER_NOEC(t_syscall, T_SYSCALL)
f01040fc:	6a 00                	push   $0x0
f01040fe:	6a 30                	push   $0x30
f0104100:	eb 24                	jmp    f0104126 <_alltraps>

f0104102 <irq_timer>:
TRAPHANDLER_NOEC(irq_timer, IRQ_OFFSET + IRQ_TIMER)
f0104102:	6a 00                	push   $0x0
f0104104:	6a 20                	push   $0x20
f0104106:	eb 1e                	jmp    f0104126 <_alltraps>

f0104108 <irq_kbd>:
TRAPHANDLER_NOEC(irq_kbd, IRQ_OFFSET + IRQ_KBD)
f0104108:	6a 00                	push   $0x0
f010410a:	6a 21                	push   $0x21
f010410c:	eb 18                	jmp    f0104126 <_alltraps>

f010410e <irq_serial>:
TRAPHANDLER_NOEC(irq_serial, IRQ_OFFSET + IRQ_SERIAL)
f010410e:	6a 00                	push   $0x0
f0104110:	6a 24                	push   $0x24
f0104112:	eb 12                	jmp    f0104126 <_alltraps>

f0104114 <irq_spurious>:
TRAPHANDLER_NOEC(irq_spurious, IRQ_OFFSET + IRQ_SPURIOUS)
f0104114:	6a 00                	push   $0x0
f0104116:	6a 27                	push   $0x27
f0104118:	eb 0c                	jmp    f0104126 <_alltraps>

f010411a <irq_ide>:
TRAPHANDLER_NOEC(irq_ide, IRQ_OFFSET + IRQ_IDE)
f010411a:	6a 00                	push   $0x0
f010411c:	6a 2e                	push   $0x2e
f010411e:	eb 06                	jmp    f0104126 <_alltraps>

f0104120 <irq_error>:
TRAPHANDLER_NOEC(irq_error, IRQ_OFFSET + IRQ_ERROR)
f0104120:	6a 00                	push   $0x0
f0104122:	6a 33                	push   $0x33
f0104124:	eb 00                	jmp    f0104126 <_alltraps>

f0104126 <_alltraps>:
/*
 * Lab 3: Your code here for _alltraps
 */
_alltraps:
	# Build trap frame.
	pushl %ds
f0104126:	1e                   	push   %ds
	pushl %es
f0104127:	06                   	push   %es
	pushal	
f0104128:	60                   	pusha  

	movw $(GD_KD), %ax
f0104129:	66 b8 10 00          	mov    $0x10,%ax
	movw %ax, %ds
f010412d:	8e d8                	mov    %eax,%ds
	movw %ax, %es
f010412f:	8e c0                	mov    %eax,%es

	pushl %esp
f0104131:	54                   	push   %esp
	call trap
f0104132:	e8 47 fd ff ff       	call   f0103e7e <trap>

f0104137 <sched_halt>:
// Halt this CPU when there is nothing to do. Wait until the
// timer interrupt wakes it up. This function never returns.
//
void
sched_halt(void)
{
f0104137:	55                   	push   %ebp
f0104138:	89 e5                	mov    %esp,%ebp
f010413a:	83 ec 08             	sub    $0x8,%esp
f010413d:	a1 44 12 21 f0       	mov    0xf0211244,%eax
f0104142:	8d 50 54             	lea    0x54(%eax),%edx
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
f0104145:	b9 00 00 00 00       	mov    $0x0,%ecx
		if ((envs[i].env_status == ENV_RUNNABLE ||
f010414a:	8b 02                	mov    (%edx),%eax
f010414c:	83 e8 01             	sub    $0x1,%eax
f010414f:	83 f8 02             	cmp    $0x2,%eax
f0104152:	76 10                	jbe    f0104164 <sched_halt+0x2d>
{
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
f0104154:	83 c1 01             	add    $0x1,%ecx
f0104157:	83 c2 7c             	add    $0x7c,%edx
f010415a:	81 f9 00 04 00 00    	cmp    $0x400,%ecx
f0104160:	75 e8                	jne    f010414a <sched_halt+0x13>
f0104162:	eb 08                	jmp    f010416c <sched_halt+0x35>
		if ((envs[i].env_status == ENV_RUNNABLE ||
		     envs[i].env_status == ENV_RUNNING ||
		     envs[i].env_status == ENV_DYING))
			break;
	}
	if (i == NENV) {
f0104164:	81 f9 00 04 00 00    	cmp    $0x400,%ecx
f010416a:	75 1f                	jne    f010418b <sched_halt+0x54>
		cprintf("No runnable environments in the system!\n");
f010416c:	83 ec 0c             	sub    $0xc,%esp
f010416f:	68 d0 76 10 f0       	push   $0xf01076d0
f0104174:	e8 b5 f4 ff ff       	call   f010362e <cprintf>
f0104179:	83 c4 10             	add    $0x10,%esp
		while (1)
			monitor(NULL);
f010417c:	83 ec 0c             	sub    $0xc,%esp
f010417f:	6a 00                	push   $0x0
f0104181:	e8 a0 c7 ff ff       	call   f0100926 <monitor>
f0104186:	83 c4 10             	add    $0x10,%esp
f0104189:	eb f1                	jmp    f010417c <sched_halt+0x45>
	}

	// Mark that no environment is running on this CPU
	curenv = NULL;
f010418b:	e8 46 18 00 00       	call   f01059d6 <cpunum>
f0104190:	6b c0 74             	imul   $0x74,%eax,%eax
f0104193:	c7 80 28 20 21 f0 00 	movl   $0x0,-0xfdedfd8(%eax)
f010419a:	00 00 00 
	lcr3(PADDR(kern_pgdir));
f010419d:	a1 8c 1e 21 f0       	mov    0xf0211e8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01041a2:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01041a7:	77 12                	ja     f01041bb <sched_halt+0x84>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01041a9:	50                   	push   %eax
f01041aa:	68 a8 60 10 f0       	push   $0xf01060a8
f01041af:	6a 4f                	push   $0x4f
f01041b1:	68 f9 76 10 f0       	push   $0xf01076f9
f01041b6:	e8 85 be ff ff       	call   f0100040 <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f01041bb:	05 00 00 00 10       	add    $0x10000000,%eax
f01041c0:	0f 22 d8             	mov    %eax,%cr3

	// Mark that this CPU is in the HALT state, so that when
	// timer interupts come in, we know we should re-acquire the
	// big kernel lock
	xchg(&thiscpu->cpu_status, CPU_HALTED);
f01041c3:	e8 0e 18 00 00       	call   f01059d6 <cpunum>
f01041c8:	6b d0 74             	imul   $0x74,%eax,%edx
f01041cb:	81 c2 20 20 21 f0    	add    $0xf0212020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"
f01041d1:	b8 02 00 00 00       	mov    $0x2,%eax
f01041d6:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
}

static inline void
unlock_kernel(void)
{
	spin_unlock(&kernel_lock);
f01041da:	83 ec 0c             	sub    $0xc,%esp
f01041dd:	68 c0 03 12 f0       	push   $0xf01203c0
f01041e2:	e8 fa 1a 00 00       	call   f0105ce1 <spin_unlock>

	// Normally we wouldn't need to do this, but QEMU only runs
	// one CPU at a time and has a long time-slice.  Without the
	// pause, this CPU is likely to reacquire the lock before
	// another CPU has even been given a chance to acquire it.
	asm volatile("pause");
f01041e7:	f3 90                	pause  
		"pushl $0\n"
		"sti\n"
		"1:\n"
		"hlt\n"
		"jmp 1b\n"
	: : "a" (thiscpu->cpu_ts.ts_esp0));
f01041e9:	e8 e8 17 00 00       	call   f01059d6 <cpunum>
f01041ee:	6b c0 74             	imul   $0x74,%eax,%eax

	// Release the big kernel lock as if we were "leaving" the kernel
	unlock_kernel();

	// Reset stack pointer, enable interrupts and then halt.
	asm volatile (
f01041f1:	8b 80 30 20 21 f0    	mov    -0xfdedfd0(%eax),%eax
f01041f7:	bd 00 00 00 00       	mov    $0x0,%ebp
f01041fc:	89 c4                	mov    %eax,%esp
f01041fe:	6a 00                	push   $0x0
f0104200:	6a 00                	push   $0x0
f0104202:	fb                   	sti    
f0104203:	f4                   	hlt    
f0104204:	eb fd                	jmp    f0104203 <sched_halt+0xcc>
		"sti\n"
		"1:\n"
		"hlt\n"
		"jmp 1b\n"
	: : "a" (thiscpu->cpu_ts.ts_esp0));
}
f0104206:	83 c4 10             	add    $0x10,%esp
f0104209:	c9                   	leave  
f010420a:	c3                   	ret    

f010420b <sched_yield>:
void sched_halt(void);

// Choose a user environment to run and run it.
void
sched_yield(void)
{
f010420b:	55                   	push   %ebp
f010420c:	89 e5                	mov    %esp,%ebp
f010420e:	53                   	push   %ebx
f010420f:	83 ec 04             	sub    $0x4,%esp
	// no runnable environments, simply drop through to the code
	// below to halt the cpu.

	// LAB 4: Your code here.
    int cur_idx;
    if (curenv)
f0104212:	e8 bf 17 00 00       	call   f01059d6 <cpunum>
f0104217:	6b c0 74             	imul   $0x74,%eax,%eax
        cur_idx = ENVX(curenv->env_id);
    else
        cur_idx = 0;
f010421a:	ba 00 00 00 00       	mov    $0x0,%edx
	// no runnable environments, simply drop through to the code
	// below to halt the cpu.

	// LAB 4: Your code here.
    int cur_idx;
    if (curenv)
f010421f:	83 b8 28 20 21 f0 00 	cmpl   $0x0,-0xfdedfd8(%eax)
f0104226:	74 17                	je     f010423f <sched_yield+0x34>
        cur_idx = ENVX(curenv->env_id);
f0104228:	e8 a9 17 00 00       	call   f01059d6 <cpunum>
f010422d:	6b c0 74             	imul   $0x74,%eax,%eax
f0104230:	8b 80 28 20 21 f0    	mov    -0xfdedfd8(%eax),%eax
f0104236:	8b 50 48             	mov    0x48(%eax),%edx
f0104239:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
    else
        cur_idx = 0;

    if(envs[cur_idx].env_status == ENV_RUNNABLE){
f010423f:	8b 0d 44 12 21 f0    	mov    0xf0211244,%ecx
f0104245:	6b c2 7c             	imul   $0x7c,%edx,%eax
f0104248:	01 c8                	add    %ecx,%eax
f010424a:	83 78 54 02          	cmpl   $0x2,0x54(%eax)
f010424e:	75 09                	jne    f0104259 <sched_yield+0x4e>
        env_run(&envs[cur_idx]);
f0104250:	83 ec 0c             	sub    $0xc,%esp
f0104253:	50                   	push   %eax
f0104254:	e8 9f f1 ff ff       	call   f01033f8 <env_run>
    }
    for(int i = cur_idx + 1; i != cur_idx; i = (i + 1) % NENV){
f0104259:	8d 42 01             	lea    0x1(%edx),%eax
f010425c:	eb 28                	jmp    f0104286 <sched_yield+0x7b>
        if(envs[i].env_status == ENV_RUNNABLE){
f010425e:	6b d8 7c             	imul   $0x7c,%eax,%ebx
f0104261:	01 cb                	add    %ecx,%ebx
f0104263:	83 7b 54 02          	cmpl   $0x2,0x54(%ebx)
f0104267:	75 09                	jne    f0104272 <sched_yield+0x67>
            env_run(&envs[i]);
f0104269:	83 ec 0c             	sub    $0xc,%esp
f010426c:	53                   	push   %ebx
f010426d:	e8 86 f1 ff ff       	call   f01033f8 <env_run>
        cur_idx = 0;

    if(envs[cur_idx].env_status == ENV_RUNNABLE){
        env_run(&envs[cur_idx]);
    }
    for(int i = cur_idx + 1; i != cur_idx; i = (i + 1) % NENV){
f0104272:	83 c0 01             	add    $0x1,%eax
f0104275:	89 c3                	mov    %eax,%ebx
f0104277:	c1 fb 1f             	sar    $0x1f,%ebx
f010427a:	c1 eb 16             	shr    $0x16,%ebx
f010427d:	01 d8                	add    %ebx,%eax
f010427f:	25 ff 03 00 00       	and    $0x3ff,%eax
f0104284:	29 d8                	sub    %ebx,%eax
f0104286:	39 c2                	cmp    %eax,%edx
f0104288:	75 d4                	jne    f010425e <sched_yield+0x53>
        if(envs[i].env_status == ENV_RUNNABLE){
            env_run(&envs[i]);
            return;
        } 
    }
    if(curenv && curenv->env_status == ENV_RUNNING) {
f010428a:	e8 47 17 00 00       	call   f01059d6 <cpunum>
f010428f:	6b c0 74             	imul   $0x74,%eax,%eax
f0104292:	83 b8 28 20 21 f0 00 	cmpl   $0x0,-0xfdedfd8(%eax)
f0104299:	74 2a                	je     f01042c5 <sched_yield+0xba>
f010429b:	e8 36 17 00 00       	call   f01059d6 <cpunum>
f01042a0:	6b c0 74             	imul   $0x74,%eax,%eax
f01042a3:	8b 80 28 20 21 f0    	mov    -0xfdedfd8(%eax),%eax
f01042a9:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f01042ad:	75 16                	jne    f01042c5 <sched_yield+0xba>
        env_run(curenv);
f01042af:	e8 22 17 00 00       	call   f01059d6 <cpunum>
f01042b4:	83 ec 0c             	sub    $0xc,%esp
f01042b7:	6b c0 74             	imul   $0x74,%eax,%eax
f01042ba:	ff b0 28 20 21 f0    	pushl  -0xfdedfd8(%eax)
f01042c0:	e8 33 f1 ff ff       	call   f01033f8 <env_run>
        return;
    }

	// sched_halt never returns
	sched_halt();
f01042c5:	e8 6d fe ff ff       	call   f0104137 <sched_halt>
}
f01042ca:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01042cd:	c9                   	leave  
f01042ce:	c3                   	ret    

f01042cf <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f01042cf:	55                   	push   %ebp
f01042d0:	89 e5                	mov    %esp,%ebp
f01042d2:	57                   	push   %edi
f01042d3:	56                   	push   %esi
f01042d4:	53                   	push   %ebx
f01042d5:	83 ec 1c             	sub    $0x1c,%esp
f01042d8:	8b 45 08             	mov    0x8(%ebp),%eax
	// Call the function corresponding to the 'syscallno' parameter.
	// Return any appropriate return value.
	// LAB 3: Your code here.

	switch (syscallno) {
f01042db:	83 f8 0d             	cmp    $0xd,%eax
f01042de:	0f 87 fd 04 00 00    	ja     f01047e1 <syscall+0x512>
f01042e4:	ff 24 85 0c 77 10 f0 	jmp    *-0xfef88f4(,%eax,4)
{
	// Check that the user has permission to read memory [s, s+len).
	// Destroy the environment if not.

	// LAB 3: Your code here.
	user_mem_assert(curenv, s, len, PTE_U | PTE_W);
f01042eb:	e8 e6 16 00 00       	call   f01059d6 <cpunum>
f01042f0:	6a 06                	push   $0x6
f01042f2:	ff 75 10             	pushl  0x10(%ebp)
f01042f5:	ff 75 0c             	pushl  0xc(%ebp)
f01042f8:	6b c0 74             	imul   $0x74,%eax,%eax
f01042fb:	ff b0 28 20 21 f0    	pushl  -0xfdedfd8(%eax)
f0104301:	e8 74 ea ff ff       	call   f0102d7a <user_mem_assert>

	// Print the string supplied by the user.
	cprintf("%.*s", len, s);
f0104306:	83 c4 0c             	add    $0xc,%esp
f0104309:	ff 75 0c             	pushl  0xc(%ebp)
f010430c:	ff 75 10             	pushl  0x10(%ebp)
f010430f:	68 06 77 10 f0       	push   $0xf0107706
f0104314:	e8 15 f3 ff ff       	call   f010362e <cprintf>
f0104319:	83 c4 10             	add    $0x10,%esp
	// LAB 3: Your code here.

	switch (syscallno) {
		case SYS_cputs:
			sys_cputs((const char *) a1,(size_t) a2);
			return 0;
f010431c:	b8 00 00 00 00       	mov    $0x0,%eax
f0104321:	e9 c7 04 00 00       	jmp    f01047ed <syscall+0x51e>
// Read a character from the system console without blocking.
// Returns the character, or 0 if there is no input waiting.
static int
sys_cgetc(void)
{
	return cons_getc();
f0104326:	e8 de c2 ff ff       	call   f0100609 <cons_getc>
	switch (syscallno) {
		case SYS_cputs:
			sys_cputs((const char *) a1,(size_t) a2);
			return 0;
		case SYS_cgetc:
			return sys_cgetc();
f010432b:	e9 bd 04 00 00       	jmp    f01047ed <syscall+0x51e>

// Returns the current environment's envid.
static envid_t
sys_getenvid(void)
{
	return curenv->env_id;
f0104330:	e8 a1 16 00 00       	call   f01059d6 <cpunum>
f0104335:	6b c0 74             	imul   $0x74,%eax,%eax
f0104338:	8b 80 28 20 21 f0    	mov    -0xfdedfd8(%eax),%eax
f010433e:	8b 40 48             	mov    0x48(%eax),%eax
			sys_cputs((const char *) a1,(size_t) a2);
			return 0;
		case SYS_cgetc:
			return sys_cgetc();
		case SYS_getenvid:
			return sys_getenvid();
f0104341:	e9 a7 04 00 00       	jmp    f01047ed <syscall+0x51e>
sys_env_destroy(envid_t envid)
{
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
f0104346:	83 ec 04             	sub    $0x4,%esp
f0104349:	6a 01                	push   $0x1
f010434b:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010434e:	50                   	push   %eax
f010434f:	ff 75 0c             	pushl  0xc(%ebp)
f0104352:	e8 d8 ea ff ff       	call   f0102e2f <envid2env>
f0104357:	83 c4 10             	add    $0x10,%esp
f010435a:	85 c0                	test   %eax,%eax
f010435c:	0f 88 8b 04 00 00    	js     f01047ed <syscall+0x51e>
		return r;
	env_destroy(e);
f0104362:	83 ec 0c             	sub    $0xc,%esp
f0104365:	ff 75 e4             	pushl  -0x1c(%ebp)
f0104368:	e8 ec ef ff ff       	call   f0103359 <env_destroy>
f010436d:	83 c4 10             	add    $0x10,%esp
	return 0;
f0104370:	b8 00 00 00 00       	mov    $0x0,%eax
f0104375:	e9 73 04 00 00       	jmp    f01047ed <syscall+0x51e>

// Deschedule current environment and pick a different one to run.
static void
sys_yield(void)
{
	sched_yield();
f010437a:	e8 8c fe ff ff       	call   f010420b <sched_yield>
	// status is set to ENV_NOT_RUNNABLE, and the register set is copied
	// from the current environment -- but tweaked so sys_exofork
	// will appear to return 0.
    struct Env *child_env;
    int r;
    r = env_alloc(&child_env, curenv->env_id);
f010437f:	e8 52 16 00 00       	call   f01059d6 <cpunum>
f0104384:	83 ec 08             	sub    $0x8,%esp
f0104387:	6b c0 74             	imul   $0x74,%eax,%eax
f010438a:	8b 80 28 20 21 f0    	mov    -0xfdedfd8(%eax),%eax
f0104390:	ff 70 48             	pushl  0x48(%eax)
f0104393:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104396:	50                   	push   %eax
f0104397:	e8 a5 eb ff ff       	call   f0102f41 <env_alloc>
    if(r!=0)
f010439c:	83 c4 10             	add    $0x10,%esp
f010439f:	85 c0                	test   %eax,%eax
f01043a1:	0f 85 46 04 00 00    	jne    f01047ed <syscall+0x51e>
        return r;
    child_env->env_status = ENV_NOT_RUNNABLE;
f01043a7:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01043aa:	c7 43 54 04 00 00 00 	movl   $0x4,0x54(%ebx)
    child_env->env_tf = curenv->env_tf;
f01043b1:	e8 20 16 00 00       	call   f01059d6 <cpunum>
f01043b6:	6b c0 74             	imul   $0x74,%eax,%eax
f01043b9:	8b b0 28 20 21 f0    	mov    -0xfdedfd8(%eax),%esi
f01043bf:	b9 11 00 00 00       	mov    $0x11,%ecx
f01043c4:	89 df                	mov    %ebx,%edi
f01043c6:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
    child_env->env_tf.tf_regs.reg_eax = 0;
f01043c8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01043cb:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)
    return child_env->env_id;
f01043d2:	8b 40 48             	mov    0x48(%eax),%eax
f01043d5:	e9 13 04 00 00       	jmp    f01047ed <syscall+0x51e>
	//   parameters for correctness.
	//   If page_insert() fails, remember to free the page you
	//   allocated!

    struct Env *env;
    int r = envid2env(envid, &env, 1);
f01043da:	83 ec 04             	sub    $0x4,%esp
f01043dd:	6a 01                	push   $0x1
f01043df:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01043e2:	50                   	push   %eax
f01043e3:	ff 75 0c             	pushl  0xc(%ebp)
f01043e6:	e8 44 ea ff ff       	call   f0102e2f <envid2env>
    if(r!=0)
f01043eb:	83 c4 10             	add    $0x10,%esp
f01043ee:	85 c0                	test   %eax,%eax
f01043f0:	0f 85 f7 03 00 00    	jne    f01047ed <syscall+0x51e>
        return r;
    if (va > (void *) UTOP || va != ROUNDDOWN(va, PGSIZE))
f01043f6:	81 7d 10 00 00 c0 ee 	cmpl   $0xeec00000,0x10(%ebp)
f01043fd:	77 62                	ja     f0104461 <syscall+0x192>
f01043ff:	f7 45 10 ff 0f 00 00 	testl  $0xfff,0x10(%ebp)
f0104406:	75 63                	jne    f010446b <syscall+0x19c>
       return -E_INVAL; 
    int flag = PTE_U | PTE_P;

    if ((perm & flag) != flag)
f0104408:	8b 45 14             	mov    0x14(%ebp),%eax
f010440b:	83 e0 05             	and    $0x5,%eax
f010440e:	83 f8 05             	cmp    $0x5,%eax
f0104411:	75 62                	jne    f0104475 <syscall+0x1a6>
        return -E_INVAL;

    if (perm & (~(PTE_U | PTE_P | PTE_AVAIL | PTE_W)))
f0104413:	f7 45 14 f8 f1 ff ff 	testl  $0xfffff1f8,0x14(%ebp)
f010441a:	75 63                	jne    f010447f <syscall+0x1b0>
        return -E_INVAL;

    struct PageInfo *pp = page_alloc(1);
f010441c:	83 ec 0c             	sub    $0xc,%esp
f010441f:	6a 01                	push   $0x1
f0104421:	e8 76 cb ff ff       	call   f0100f9c <page_alloc>
f0104426:	89 c6                	mov    %eax,%esi
    if(pp == NULL)
f0104428:	83 c4 10             	add    $0x10,%esp
f010442b:	85 c0                	test   %eax,%eax
f010442d:	74 5a                	je     f0104489 <syscall+0x1ba>
        return -E_NO_MEM;
    r = page_insert(env->env_pgdir, pp, va, perm);
f010442f:	ff 75 14             	pushl  0x14(%ebp)
f0104432:	ff 75 10             	pushl  0x10(%ebp)
f0104435:	50                   	push   %eax
f0104436:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104439:	ff 70 60             	pushl  0x60(%eax)
f010443c:	e8 00 ce ff ff       	call   f0101241 <page_insert>
f0104441:	89 c3                	mov    %eax,%ebx
    if(r!=0){
f0104443:	83 c4 10             	add    $0x10,%esp
f0104446:	85 c0                	test   %eax,%eax
f0104448:	0f 84 9f 03 00 00    	je     f01047ed <syscall+0x51e>
        page_free(pp);
f010444e:	83 ec 0c             	sub    $0xc,%esp
f0104451:	56                   	push   %esi
f0104452:	e8 bc cb ff ff       	call   f0101013 <page_free>
f0104457:	83 c4 10             	add    $0x10,%esp
        return r;
f010445a:	89 d8                	mov    %ebx,%eax
f010445c:	e9 8c 03 00 00       	jmp    f01047ed <syscall+0x51e>
    struct Env *env;
    int r = envid2env(envid, &env, 1);
    if(r!=0)
        return r;
    if (va > (void *) UTOP || va != ROUNDDOWN(va, PGSIZE))
       return -E_INVAL; 
f0104461:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104466:	e9 82 03 00 00       	jmp    f01047ed <syscall+0x51e>
f010446b:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104470:	e9 78 03 00 00       	jmp    f01047ed <syscall+0x51e>
    int flag = PTE_U | PTE_P;

    if ((perm & flag) != flag)
        return -E_INVAL;
f0104475:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f010447a:	e9 6e 03 00 00       	jmp    f01047ed <syscall+0x51e>

    if (perm & (~(PTE_U | PTE_P | PTE_AVAIL | PTE_W)))
        return -E_INVAL;
f010447f:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104484:	e9 64 03 00 00       	jmp    f01047ed <syscall+0x51e>

    struct PageInfo *pp = page_alloc(1);
    if(pp == NULL)
        return -E_NO_MEM;
f0104489:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f010448e:	e9 5a 03 00 00       	jmp    f01047ed <syscall+0x51e>
	//   parameters for correctness.
	//   Use the third argument to page_lookup() to
	//   check the current permissions on the page.

    struct Env *srcenv, *dstenv;
    int r = envid2env(srcenvid, &srcenv, 1);
f0104493:	83 ec 04             	sub    $0x4,%esp
f0104496:	6a 01                	push   $0x1
f0104498:	8d 45 dc             	lea    -0x24(%ebp),%eax
f010449b:	50                   	push   %eax
f010449c:	ff 75 0c             	pushl  0xc(%ebp)
f010449f:	e8 8b e9 ff ff       	call   f0102e2f <envid2env>
    if(r!=0)
f01044a4:	83 c4 10             	add    $0x10,%esp
f01044a7:	85 c0                	test   %eax,%eax
f01044a9:	0f 85 3e 03 00 00    	jne    f01047ed <syscall+0x51e>
        return r;
    r = envid2env(dstenvid, &dstenv, 1);
f01044af:	83 ec 04             	sub    $0x4,%esp
f01044b2:	6a 01                	push   $0x1
f01044b4:	8d 45 e0             	lea    -0x20(%ebp),%eax
f01044b7:	50                   	push   %eax
f01044b8:	ff 75 14             	pushl  0x14(%ebp)
f01044bb:	e8 6f e9 ff ff       	call   f0102e2f <envid2env>
    if(r!=0)
f01044c0:	83 c4 10             	add    $0x10,%esp
f01044c3:	85 c0                	test   %eax,%eax
f01044c5:	0f 85 22 03 00 00    	jne    f01047ed <syscall+0x51e>
        return r;

    if (srcva >= (void *) UTOP || dstva >= (void *) UTOP || 
f01044cb:	81 7d 10 ff ff bf ee 	cmpl   $0xeebfffff,0x10(%ebp)
f01044d2:	77 77                	ja     f010454b <syscall+0x27c>
f01044d4:	81 7d 18 ff ff bf ee 	cmpl   $0xeebfffff,0x18(%ebp)
f01044db:	77 6e                	ja     f010454b <syscall+0x27c>
f01044dd:	f7 45 10 ff 0f 00 00 	testl  $0xfff,0x10(%ebp)
f01044e4:	75 6f                	jne    f0104555 <syscall+0x286>
        srcva != ROUNDDOWN(srcva, PGSIZE) || dstva != ROUNDDOWN(dstva, PGSIZE))
        return -E_INVAL; 
f01044e6:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
    r = envid2env(dstenvid, &dstenv, 1);
    if(r!=0)
        return r;

    if (srcva >= (void *) UTOP || dstva >= (void *) UTOP || 
        srcva != ROUNDDOWN(srcva, PGSIZE) || dstva != ROUNDDOWN(dstva, PGSIZE))
f01044eb:	f7 45 18 ff 0f 00 00 	testl  $0xfff,0x18(%ebp)
f01044f2:	0f 85 f5 02 00 00    	jne    f01047ed <syscall+0x51e>
        return -E_INVAL; 

    pte_t *pte;
    struct PageInfo *pp = page_lookup(srcenv->env_pgdir, srcva, &pte);
f01044f8:	83 ec 04             	sub    $0x4,%esp
f01044fb:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01044fe:	50                   	push   %eax
f01044ff:	ff 75 10             	pushl  0x10(%ebp)
f0104502:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0104505:	ff 70 60             	pushl  0x60(%eax)
f0104508:	e8 5f cc ff ff       	call   f010116c <page_lookup>
    if(pp == NULL)    
f010450d:	83 c4 10             	add    $0x10,%esp
f0104510:	85 c0                	test   %eax,%eax
f0104512:	74 4b                	je     f010455f <syscall+0x290>
        return -E_INVAL;

    if ((!(perm & (PTE_U | PTE_P))) || (perm & (~(PTE_U | PTE_P | PTE_AVAIL | PTE_W))))
f0104514:	f6 45 1c 05          	testb  $0x5,0x1c(%ebp)
f0104518:	74 4f                	je     f0104569 <syscall+0x29a>
f010451a:	f7 45 1c f8 f1 ff ff 	testl  $0xfffff1f8,0x1c(%ebp)
f0104521:	75 50                	jne    f0104573 <syscall+0x2a4>
        return -E_INVAL;

    if ((perm & PTE_W) && !(*pte & PTE_W))
f0104523:	f6 45 1c 02          	testb  $0x2,0x1c(%ebp)
f0104527:	74 08                	je     f0104531 <syscall+0x262>
f0104529:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f010452c:	f6 02 02             	testb  $0x2,(%edx)
f010452f:	74 4c                	je     f010457d <syscall+0x2ae>
        return -E_INVAL;

    r = page_insert(dstenv->env_pgdir, pp, dstva, perm);
f0104531:	ff 75 1c             	pushl  0x1c(%ebp)
f0104534:	ff 75 18             	pushl  0x18(%ebp)
f0104537:	50                   	push   %eax
f0104538:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010453b:	ff 70 60             	pushl  0x60(%eax)
f010453e:	e8 fe cc ff ff       	call   f0101241 <page_insert>
f0104543:	83 c4 10             	add    $0x10,%esp
f0104546:	e9 a2 02 00 00       	jmp    f01047ed <syscall+0x51e>
    if(r!=0)
        return r;

    if (srcva >= (void *) UTOP || dstva >= (void *) UTOP || 
        srcva != ROUNDDOWN(srcva, PGSIZE) || dstva != ROUNDDOWN(dstva, PGSIZE))
        return -E_INVAL; 
f010454b:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104550:	e9 98 02 00 00       	jmp    f01047ed <syscall+0x51e>
f0104555:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f010455a:	e9 8e 02 00 00       	jmp    f01047ed <syscall+0x51e>

    pte_t *pte;
    struct PageInfo *pp = page_lookup(srcenv->env_pgdir, srcva, &pte);
    if(pp == NULL)    
        return -E_INVAL;
f010455f:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104564:	e9 84 02 00 00       	jmp    f01047ed <syscall+0x51e>

    if ((!(perm & (PTE_U | PTE_P))) || (perm & (~(PTE_U | PTE_P | PTE_AVAIL | PTE_W))))
        return -E_INVAL;
f0104569:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f010456e:	e9 7a 02 00 00       	jmp    f01047ed <syscall+0x51e>
f0104573:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104578:	e9 70 02 00 00       	jmp    f01047ed <syscall+0x51e>

    if ((perm & PTE_W) && !(*pte & PTE_W))
        return -E_INVAL;
f010457d:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
        case SYS_exofork:
            return sys_exofork();
        case SYS_page_alloc:
            return sys_page_alloc(a1, (void *) a2, a3);
        case SYS_page_map:
            return sys_page_map(a1, (void *) a2, a3, (void *) a4, a5);
f0104582:	e9 66 02 00 00       	jmp    f01047ed <syscall+0x51e>
sys_page_unmap(envid_t envid, void *va)
{
	// Hint: This function is a wrapper around page_remove().

    struct Env *env;
    int r = envid2env(envid, &env, 1);
f0104587:	83 ec 04             	sub    $0x4,%esp
f010458a:	6a 01                	push   $0x1
f010458c:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010458f:	50                   	push   %eax
f0104590:	ff 75 0c             	pushl  0xc(%ebp)
f0104593:	e8 97 e8 ff ff       	call   f0102e2f <envid2env>
    if(r!=0)
f0104598:	83 c4 10             	add    $0x10,%esp
f010459b:	85 c0                	test   %eax,%eax
f010459d:	0f 85 4a 02 00 00    	jne    f01047ed <syscall+0x51e>
        return r;
    if (va > (void *)UTOP || va != ROUNDDOWN(va, PGSIZE))
f01045a3:	81 7d 10 00 00 c0 ee 	cmpl   $0xeec00000,0x10(%ebp)
f01045aa:	77 30                	ja     f01045dc <syscall+0x30d>
        return -E_INVAL; 
f01045ac:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

    struct Env *env;
    int r = envid2env(envid, &env, 1);
    if(r!=0)
        return r;
    if (va > (void *)UTOP || va != ROUNDDOWN(va, PGSIZE))
f01045b1:	f7 45 10 ff 0f 00 00 	testl  $0xfff,0x10(%ebp)
f01045b8:	0f 85 2f 02 00 00    	jne    f01047ed <syscall+0x51e>
        return -E_INVAL; 
    
    page_remove(env->env_pgdir, va);
f01045be:	83 ec 08             	sub    $0x8,%esp
f01045c1:	ff 75 10             	pushl  0x10(%ebp)
f01045c4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01045c7:	ff 70 60             	pushl  0x60(%eax)
f01045ca:	e8 2c cc ff ff       	call   f01011fb <page_remove>
f01045cf:	83 c4 10             	add    $0x10,%esp
    return 0;
f01045d2:	b8 00 00 00 00       	mov    $0x0,%eax
f01045d7:	e9 11 02 00 00       	jmp    f01047ed <syscall+0x51e>
    struct Env *env;
    int r = envid2env(envid, &env, 1);
    if(r!=0)
        return r;
    if (va > (void *)UTOP || va != ROUNDDOWN(va, PGSIZE))
        return -E_INVAL; 
f01045dc:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f01045e1:	e9 07 02 00 00       	jmp    f01047ed <syscall+0x51e>
	// envid to a struct Env.
	// You should set envid2env's third argument to 1, which will
	// check whether the current environment has permission to set
	// envid's status.
    struct Env *env;
    int r = envid2env(envid, &env, 1);
f01045e6:	83 ec 04             	sub    $0x4,%esp
f01045e9:	6a 01                	push   $0x1
f01045eb:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01045ee:	50                   	push   %eax
f01045ef:	ff 75 0c             	pushl  0xc(%ebp)
f01045f2:	e8 38 e8 ff ff       	call   f0102e2f <envid2env>
    if(r!=0)
f01045f7:	83 c4 10             	add    $0x10,%esp
f01045fa:	85 c0                	test   %eax,%eax
f01045fc:	0f 85 eb 01 00 00    	jne    f01047ed <syscall+0x51e>
        return r;
    if(env->env_status == ENV_RUNNABLE || env->env_status == ENV_NOT_RUNNABLE){
f0104602:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0104605:	8b 42 54             	mov    0x54(%edx),%eax
f0104608:	83 e8 02             	sub    $0x2,%eax
f010460b:	a9 fd ff ff ff       	test   $0xfffffffd,%eax
f0104610:	75 10                	jne    f0104622 <syscall+0x353>
        env->env_status = status;
f0104612:	8b 45 10             	mov    0x10(%ebp),%eax
f0104615:	89 42 54             	mov    %eax,0x54(%edx)
        return 0;
f0104618:	b8 00 00 00 00       	mov    $0x0,%eax
f010461d:	e9 cb 01 00 00       	jmp    f01047ed <syscall+0x51e>
    }
    return -E_INVAL; 
f0104622:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
        case SYS_page_map:
            return sys_page_map(a1, (void *) a2, a3, (void *) a4, a5);
        case SYS_page_unmap:
            return sys_page_unmap(a1, (void *) a2);
        case SYS_env_set_status:
            return sys_env_set_status(a1, a2);
f0104627:	e9 c1 01 00 00       	jmp    f01047ed <syscall+0x51e>
static int
sys_env_set_pgfault_upcall(envid_t envid, void *func)
{
	// LAB 4: Your code here.
    struct Env *env;
    int r = envid2env(envid, &env, 1);
f010462c:	83 ec 04             	sub    $0x4,%esp
f010462f:	6a 01                	push   $0x1
f0104631:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104634:	50                   	push   %eax
f0104635:	ff 75 0c             	pushl  0xc(%ebp)
f0104638:	e8 f2 e7 ff ff       	call   f0102e2f <envid2env>
    if(r!=0)
f010463d:	83 c4 10             	add    $0x10,%esp
f0104640:	85 c0                	test   %eax,%eax
f0104642:	0f 85 a5 01 00 00    	jne    f01047ed <syscall+0x51e>
        return r;
    env->env_pgfault_upcall = func;
f0104648:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f010464b:	8b 7d 10             	mov    0x10(%ebp),%edi
f010464e:	89 7a 64             	mov    %edi,0x64(%edx)
        case SYS_page_unmap:
            return sys_page_unmap(a1, (void *) a2);
        case SYS_env_set_status:
            return sys_env_set_status(a1, a2);
        case SYS_env_set_pgfault_upcall:
            return sys_env_set_pgfault_upcall(a1,(void *) a2);
f0104651:	e9 97 01 00 00       	jmp    f01047ed <syscall+0x51e>
//		address space.
static int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, unsigned perm)
{
    struct Env *env;
    int r = envid2env(envid, &env, 0);
f0104656:	83 ec 04             	sub    $0x4,%esp
f0104659:	6a 00                	push   $0x0
f010465b:	8d 45 e0             	lea    -0x20(%ebp),%eax
f010465e:	50                   	push   %eax
f010465f:	ff 75 0c             	pushl  0xc(%ebp)
f0104662:	e8 c8 e7 ff ff       	call   f0102e2f <envid2env>
    if(r!=0)
f0104667:	83 c4 10             	add    $0x10,%esp
f010466a:	85 c0                	test   %eax,%eax
f010466c:	0f 85 7b 01 00 00    	jne    f01047ed <syscall+0x51e>
        return r;
    if(!env->env_ipc_recving)
f0104672:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104675:	80 78 68 00          	cmpb   $0x0,0x68(%eax)
f0104679:	0f 84 df 00 00 00    	je     f010475e <syscall+0x48f>
        return -E_IPC_NOT_RECV;
    if(srcva < (void *) UTOP){
f010467f:	81 7d 14 ff ff bf ee 	cmpl   $0xeebfffff,0x14(%ebp)
f0104686:	0f 87 96 00 00 00    	ja     f0104722 <syscall+0x453>
        if(srcva != ROUNDDOWN(srcva, PGSIZE)) 
            return -E_INVAL;
f010468c:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
    if(r!=0)
        return r;
    if(!env->env_ipc_recving)
        return -E_IPC_NOT_RECV;
    if(srcva < (void *) UTOP){
        if(srcva != ROUNDDOWN(srcva, PGSIZE)) 
f0104691:	f7 45 14 ff 0f 00 00 	testl  $0xfff,0x14(%ebp)
f0104698:	0f 85 4f 01 00 00    	jne    f01047ed <syscall+0x51e>
            return -E_INVAL;

        pte_t *pte;
        struct PageInfo *pp = page_lookup(curenv->env_pgdir, srcva, &pte);
f010469e:	e8 33 13 00 00       	call   f01059d6 <cpunum>
f01046a3:	83 ec 04             	sub    $0x4,%esp
f01046a6:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01046a9:	52                   	push   %edx
f01046aa:	ff 75 14             	pushl  0x14(%ebp)
f01046ad:	6b c0 74             	imul   $0x74,%eax,%eax
f01046b0:	8b 80 28 20 21 f0    	mov    -0xfdedfd8(%eax),%eax
f01046b6:	ff 70 60             	pushl  0x60(%eax)
f01046b9:	e8 ae ca ff ff       	call   f010116c <page_lookup>
f01046be:	89 c2                	mov    %eax,%edx
        if(pp == NULL)
f01046c0:	83 c4 10             	add    $0x10,%esp
f01046c3:	85 c0                	test   %eax,%eax
f01046c5:	74 51                	je     f0104718 <syscall+0x449>
            return -E_INVAL;

        if((perm & PTE_U) == 0 || (perm & PTE_P) == 0 || (perm & ~PTE_SYSCALL) != 0)
f01046c7:	8b 4d 18             	mov    0x18(%ebp),%ecx
f01046ca:	81 e1 fd f1 ff ff    	and    $0xfffff1fd,%ecx
            return -E_INVAL;
f01046d0:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
        pte_t *pte;
        struct PageInfo *pp = page_lookup(curenv->env_pgdir, srcva, &pte);
        if(pp == NULL)
            return -E_INVAL;

        if((perm & PTE_U) == 0 || (perm & PTE_P) == 0 || (perm & ~PTE_SYSCALL) != 0)
f01046d5:	83 f9 05             	cmp    $0x5,%ecx
f01046d8:	0f 85 0f 01 00 00    	jne    f01047ed <syscall+0x51e>
            return -E_INVAL;

        if ((perm & PTE_W) && !(*pte & PTE_W))
f01046de:	f6 45 18 02          	testb  $0x2,0x18(%ebp)
f01046e2:	74 0c                	je     f01046f0 <syscall+0x421>
f01046e4:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f01046e7:	f6 01 02             	testb  $0x2,(%ecx)
f01046ea:	0f 84 fd 00 00 00    	je     f01047ed <syscall+0x51e>
            return -E_INVAL;


        r = page_insert(env->env_pgdir, pp, env->env_ipc_dstva, perm);
f01046f0:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01046f3:	ff 75 18             	pushl  0x18(%ebp)
f01046f6:	ff 70 6c             	pushl  0x6c(%eax)
f01046f9:	52                   	push   %edx
f01046fa:	ff 70 60             	pushl  0x60(%eax)
f01046fd:	e8 3f cb ff ff       	call   f0101241 <page_insert>
        if(r!=0)
f0104702:	83 c4 10             	add    $0x10,%esp
f0104705:	85 c0                	test   %eax,%eax
f0104707:	0f 85 e0 00 00 00    	jne    f01047ed <syscall+0x51e>
            return r;
        env->env_ipc_perm = perm;
f010470d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104710:	8b 4d 18             	mov    0x18(%ebp),%ecx
f0104713:	89 48 78             	mov    %ecx,0x78(%eax)
f0104716:	eb 0a                	jmp    f0104722 <syscall+0x453>
            return -E_INVAL;

        pte_t *pte;
        struct PageInfo *pp = page_lookup(curenv->env_pgdir, srcva, &pte);
        if(pp == NULL)
            return -E_INVAL;
f0104718:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f010471d:	e9 cb 00 00 00       	jmp    f01047ed <syscall+0x51e>
        r = page_insert(env->env_pgdir, pp, env->env_ipc_dstva, perm);
        if(r!=0)
            return r;
        env->env_ipc_perm = perm;
    }
    env->env_ipc_value = value;
f0104722:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0104725:	8b 45 10             	mov    0x10(%ebp),%eax
f0104728:	89 43 70             	mov    %eax,0x70(%ebx)
    env->env_ipc_recving = false;
f010472b:	c6 43 68 00          	movb   $0x0,0x68(%ebx)
    env->env_ipc_from = curenv->env_id;
f010472f:	e8 a2 12 00 00       	call   f01059d6 <cpunum>
f0104734:	6b c0 74             	imul   $0x74,%eax,%eax
f0104737:	8b 80 28 20 21 f0    	mov    -0xfdedfd8(%eax),%eax
f010473d:	8b 40 48             	mov    0x48(%eax),%eax
f0104740:	89 43 74             	mov    %eax,0x74(%ebx)
    env->env_status = ENV_RUNNABLE;
f0104743:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104746:	c7 40 54 02 00 00 00 	movl   $0x2,0x54(%eax)
    env->env_tf.tf_regs.reg_eax = 0;
f010474d:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)
    return 0;
f0104754:	b8 00 00 00 00       	mov    $0x0,%eax
f0104759:	e9 8f 00 00 00       	jmp    f01047ed <syscall+0x51e>
    struct Env *env;
    int r = envid2env(envid, &env, 0);
    if(r!=0)
        return r;
    if(!env->env_ipc_recving)
        return -E_IPC_NOT_RECV;
f010475e:	b8 f9 ff ff ff       	mov    $0xfffffff9,%eax
        case SYS_env_set_status:
            return sys_env_set_status(a1, a2);
        case SYS_env_set_pgfault_upcall:
            return sys_env_set_pgfault_upcall(a1,(void *) a2);
        case SYS_ipc_try_send:
            return sys_ipc_try_send(a1, a2, (void *)a3, a4);
f0104763:	e9 85 00 00 00       	jmp    f01047ed <syscall+0x51e>
//	-E_INVAL if dstva < UTOP but dstva is not page-aligned.
static int
sys_ipc_recv(void *dstva)
{
	// LAB 4: Your code here.
    if(dstva < (void *)UTOP && dstva != ROUNDDOWN(dstva, PGSIZE)){
f0104768:	81 7d 0c ff ff bf ee 	cmpl   $0xeebfffff,0xc(%ebp)
f010476f:	77 09                	ja     f010477a <syscall+0x4ab>
f0104771:	f7 45 0c ff 0f 00 00 	testl  $0xfff,0xc(%ebp)
f0104778:	75 6e                	jne    f01047e8 <syscall+0x519>
        return -E_INVAL; 
    }
    curenv->env_ipc_recving =true;
f010477a:	e8 57 12 00 00       	call   f01059d6 <cpunum>
f010477f:	6b c0 74             	imul   $0x74,%eax,%eax
f0104782:	8b 80 28 20 21 f0    	mov    -0xfdedfd8(%eax),%eax
f0104788:	c6 40 68 01          	movb   $0x1,0x68(%eax)
    curenv->env_ipc_dstva = dstva;
f010478c:	e8 45 12 00 00       	call   f01059d6 <cpunum>
f0104791:	6b c0 74             	imul   $0x74,%eax,%eax
f0104794:	8b 80 28 20 21 f0    	mov    -0xfdedfd8(%eax),%eax
f010479a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010479d:	89 48 6c             	mov    %ecx,0x6c(%eax)
    curenv->env_status = ENV_NOT_RUNNABLE;
f01047a0:	e8 31 12 00 00       	call   f01059d6 <cpunum>
f01047a5:	6b c0 74             	imul   $0x74,%eax,%eax
f01047a8:	8b 80 28 20 21 f0    	mov    -0xfdedfd8(%eax),%eax
f01047ae:	c7 40 54 04 00 00 00 	movl   $0x4,0x54(%eax)

// Deschedule current environment and pick a different one to run.
static void
sys_yield(void)
{
	sched_yield();
f01047b5:	e8 51 fa ff ff       	call   f010420b <sched_yield>
{
	// LAB 5: Your code here.
	// Remember to check whether the user has supplied us with a good
	// address!
    struct Env *env;
    int r = envid2env(envid, &env, 1);
f01047ba:	83 ec 04             	sub    $0x4,%esp
f01047bd:	6a 01                	push   $0x1
f01047bf:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01047c2:	50                   	push   %eax
f01047c3:	ff 75 0c             	pushl  0xc(%ebp)
f01047c6:	e8 64 e6 ff ff       	call   f0102e2f <envid2env>
    if(r!=0)
f01047cb:	83 c4 10             	add    $0x10,%esp
f01047ce:	85 c0                	test   %eax,%eax
f01047d0:	75 1b                	jne    f01047ed <syscall+0x51e>
        return r;
    env->env_tf = *tf;
f01047d2:	b9 11 00 00 00       	mov    $0x11,%ecx
f01047d7:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01047da:	8b 75 10             	mov    0x10(%ebp),%esi
f01047dd:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
        case SYS_ipc_try_send:
            return sys_ipc_try_send(a1, a2, (void *)a3, a4);
        case SYS_ipc_recv:
            return sys_ipc_recv((void *)a1);
        case SYS_env_set_trapframe:
            return sys_env_set_trapframe(a1, (struct Trapframe *)a2);
f01047df:	eb 0c                	jmp    f01047ed <syscall+0x51e>
		default:
			return -E_INVAL;
f01047e1:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f01047e6:	eb 05                	jmp    f01047ed <syscall+0x51e>
        case SYS_env_set_pgfault_upcall:
            return sys_env_set_pgfault_upcall(a1,(void *) a2);
        case SYS_ipc_try_send:
            return sys_ipc_try_send(a1, a2, (void *)a3, a4);
        case SYS_ipc_recv:
            return sys_ipc_recv((void *)a1);
f01047e8:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
        case SYS_env_set_trapframe:
            return sys_env_set_trapframe(a1, (struct Trapframe *)a2);
		default:
			return -E_INVAL;
	}
}
f01047ed:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01047f0:	5b                   	pop    %ebx
f01047f1:	5e                   	pop    %esi
f01047f2:	5f                   	pop    %edi
f01047f3:	5d                   	pop    %ebp
f01047f4:	c3                   	ret    

f01047f5 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01047f5:	55                   	push   %ebp
f01047f6:	89 e5                	mov    %esp,%ebp
f01047f8:	57                   	push   %edi
f01047f9:	56                   	push   %esi
f01047fa:	53                   	push   %ebx
f01047fb:	83 ec 14             	sub    $0x14,%esp
f01047fe:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0104801:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0104804:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0104807:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f010480a:	8b 1a                	mov    (%edx),%ebx
f010480c:	8b 01                	mov    (%ecx),%eax
f010480e:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0104811:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0104818:	eb 7f                	jmp    f0104899 <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f010481a:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010481d:	01 d8                	add    %ebx,%eax
f010481f:	89 c6                	mov    %eax,%esi
f0104821:	c1 ee 1f             	shr    $0x1f,%esi
f0104824:	01 c6                	add    %eax,%esi
f0104826:	d1 fe                	sar    %esi
f0104828:	8d 04 76             	lea    (%esi,%esi,2),%eax
f010482b:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010482e:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f0104831:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0104833:	eb 03                	jmp    f0104838 <stab_binsearch+0x43>
			m--;
f0104835:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0104838:	39 c3                	cmp    %eax,%ebx
f010483a:	7f 0d                	jg     f0104849 <stab_binsearch+0x54>
f010483c:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0104840:	83 ea 0c             	sub    $0xc,%edx
f0104843:	39 f9                	cmp    %edi,%ecx
f0104845:	75 ee                	jne    f0104835 <stab_binsearch+0x40>
f0104847:	eb 05                	jmp    f010484e <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0104849:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f010484c:	eb 4b                	jmp    f0104899 <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f010484e:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0104851:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0104854:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0104858:	39 55 0c             	cmp    %edx,0xc(%ebp)
f010485b:	76 11                	jbe    f010486e <stab_binsearch+0x79>
			*region_left = m;
f010485d:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0104860:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0104862:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0104865:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f010486c:	eb 2b                	jmp    f0104899 <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f010486e:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0104871:	73 14                	jae    f0104887 <stab_binsearch+0x92>
			*region_right = m - 1;
f0104873:	83 e8 01             	sub    $0x1,%eax
f0104876:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0104879:	8b 75 e0             	mov    -0x20(%ebp),%esi
f010487c:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010487e:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0104885:	eb 12                	jmp    f0104899 <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0104887:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010488a:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f010488c:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0104890:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0104892:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0104899:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f010489c:	0f 8e 78 ff ff ff    	jle    f010481a <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f01048a2:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f01048a6:	75 0f                	jne    f01048b7 <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f01048a8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01048ab:	8b 00                	mov    (%eax),%eax
f01048ad:	83 e8 01             	sub    $0x1,%eax
f01048b0:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01048b3:	89 06                	mov    %eax,(%esi)
f01048b5:	eb 2c                	jmp    f01048e3 <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01048b7:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01048ba:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f01048bc:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01048bf:	8b 0e                	mov    (%esi),%ecx
f01048c1:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01048c4:	8b 75 ec             	mov    -0x14(%ebp),%esi
f01048c7:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01048ca:	eb 03                	jmp    f01048cf <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f01048cc:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01048cf:	39 c8                	cmp    %ecx,%eax
f01048d1:	7e 0b                	jle    f01048de <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f01048d3:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f01048d7:	83 ea 0c             	sub    $0xc,%edx
f01048da:	39 df                	cmp    %ebx,%edi
f01048dc:	75 ee                	jne    f01048cc <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f01048de:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01048e1:	89 06                	mov    %eax,(%esi)
	}
}
f01048e3:	83 c4 14             	add    $0x14,%esp
f01048e6:	5b                   	pop    %ebx
f01048e7:	5e                   	pop    %esi
f01048e8:	5f                   	pop    %edi
f01048e9:	5d                   	pop    %ebp
f01048ea:	c3                   	ret    

f01048eb <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f01048eb:	55                   	push   %ebp
f01048ec:	89 e5                	mov    %esp,%ebp
f01048ee:	57                   	push   %edi
f01048ef:	56                   	push   %esi
f01048f0:	53                   	push   %ebx
f01048f1:	83 ec 3c             	sub    $0x3c,%esp
f01048f4:	8b 7d 08             	mov    0x8(%ebp),%edi
f01048f7:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f01048fa:	c7 03 44 77 10 f0    	movl   $0xf0107744,(%ebx)
	info->eip_line = 0;
f0104900:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0104907:	c7 43 08 44 77 10 f0 	movl   $0xf0107744,0x8(%ebx)
	info->eip_fn_namelen = 9;
f010490e:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0104915:	89 7b 10             	mov    %edi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0104918:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f010491f:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f0104925:	0f 87 f6 00 00 00    	ja     f0104a21 <debuginfo_eip+0x136>
		const struct UserStabData *usd = (const struct UserStabData *) USTABDATA;

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, usd, sizeof(struct UserStabData), PTE_U) < 0) {
f010492b:	e8 a6 10 00 00       	call   f01059d6 <cpunum>
f0104930:	6a 04                	push   $0x4
f0104932:	6a 10                	push   $0x10
f0104934:	68 00 00 20 00       	push   $0x200000
f0104939:	6b c0 74             	imul   $0x74,%eax,%eax
f010493c:	ff b0 28 20 21 f0    	pushl  -0xfdedfd8(%eax)
f0104942:	e8 ad e3 ff ff       	call   f0102cf4 <user_mem_check>
f0104947:	83 c4 10             	add    $0x10,%esp
f010494a:	85 c0                	test   %eax,%eax
f010494c:	79 1f                	jns    f010496d <debuginfo_eip+0x82>
			cprintf("debuginfo_eip: invalid usd addr %08x", usd);
f010494e:	83 ec 08             	sub    $0x8,%esp
f0104951:	68 00 00 20 00       	push   $0x200000
f0104956:	68 50 77 10 f0       	push   $0xf0107750
f010495b:	e8 ce ec ff ff       	call   f010362e <cprintf>
			return -1;
f0104960:	83 c4 10             	add    $0x10,%esp
f0104963:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104968:	e9 97 02 00 00       	jmp    f0104c04 <debuginfo_eip+0x319>
		}

		stabs = usd->stabs;
f010496d:	a1 00 00 20 00       	mov    0x200000,%eax
f0104972:	89 45 c0             	mov    %eax,-0x40(%ebp)
		stab_end = usd->stab_end;
f0104975:	8b 35 04 00 20 00    	mov    0x200004,%esi
		stabstr = usd->stabstr;
f010497b:	8b 15 08 00 20 00    	mov    0x200008,%edx
f0104981:	89 55 b8             	mov    %edx,-0x48(%ebp)
		stabstr_end = usd->stabstr_end;
f0104984:	8b 15 0c 00 20 00    	mov    0x20000c,%edx
f010498a:	89 55 bc             	mov    %edx,-0x44(%ebp)

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, stabs, stab_end-stabs+1, PTE_U) < 0){
f010498d:	e8 44 10 00 00       	call   f01059d6 <cpunum>
f0104992:	6a 04                	push   $0x4
f0104994:	89 f2                	mov    %esi,%edx
f0104996:	8b 4d c0             	mov    -0x40(%ebp),%ecx
f0104999:	29 ca                	sub    %ecx,%edx
f010499b:	c1 fa 02             	sar    $0x2,%edx
f010499e:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f01049a4:	83 c2 01             	add    $0x1,%edx
f01049a7:	52                   	push   %edx
f01049a8:	51                   	push   %ecx
f01049a9:	6b c0 74             	imul   $0x74,%eax,%eax
f01049ac:	ff b0 28 20 21 f0    	pushl  -0xfdedfd8(%eax)
f01049b2:	e8 3d e3 ff ff       	call   f0102cf4 <user_mem_check>
f01049b7:	83 c4 10             	add    $0x10,%esp
f01049ba:	85 c0                	test   %eax,%eax
f01049bc:	79 1d                	jns    f01049db <debuginfo_eip+0xf0>
			cprintf("debuginfo_eip: invalid stabs addr %08x", stabs);
f01049be:	83 ec 08             	sub    $0x8,%esp
f01049c1:	ff 75 c0             	pushl  -0x40(%ebp)
f01049c4:	68 78 77 10 f0       	push   $0xf0107778
f01049c9:	e8 60 ec ff ff       	call   f010362e <cprintf>
			return -1;
f01049ce:	83 c4 10             	add    $0x10,%esp
f01049d1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01049d6:	e9 29 02 00 00       	jmp    f0104c04 <debuginfo_eip+0x319>
		}
		if (user_mem_check(curenv, stabstr, stabstr_end-stabstr+1, PTE_U) < 0) {
f01049db:	e8 f6 0f 00 00       	call   f01059d6 <cpunum>
f01049e0:	6a 04                	push   $0x4
f01049e2:	8b 55 bc             	mov    -0x44(%ebp),%edx
f01049e5:	8b 4d b8             	mov    -0x48(%ebp),%ecx
f01049e8:	29 ca                	sub    %ecx,%edx
f01049ea:	83 c2 01             	add    $0x1,%edx
f01049ed:	52                   	push   %edx
f01049ee:	51                   	push   %ecx
f01049ef:	6b c0 74             	imul   $0x74,%eax,%eax
f01049f2:	ff b0 28 20 21 f0    	pushl  -0xfdedfd8(%eax)
f01049f8:	e8 f7 e2 ff ff       	call   f0102cf4 <user_mem_check>
f01049fd:	83 c4 10             	add    $0x10,%esp
f0104a00:	85 c0                	test   %eax,%eax
f0104a02:	79 37                	jns    f0104a3b <debuginfo_eip+0x150>
			cprintf("debuginfo_eip: invalid stabstr addr %08x", stabstr);
f0104a04:	83 ec 08             	sub    $0x8,%esp
f0104a07:	ff 75 b8             	pushl  -0x48(%ebp)
f0104a0a:	68 a0 77 10 f0       	push   $0xf01077a0
f0104a0f:	e8 1a ec ff ff       	call   f010362e <cprintf>
			return -1;
f0104a14:	83 c4 10             	add    $0x10,%esp
f0104a17:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104a1c:	e9 e3 01 00 00       	jmp    f0104c04 <debuginfo_eip+0x319>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f0104a21:	c7 45 bc fa 54 11 f0 	movl   $0xf01154fa,-0x44(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f0104a28:	c7 45 b8 0d 1e 11 f0 	movl   $0xf0111e0d,-0x48(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f0104a2f:	be 0c 1e 11 f0       	mov    $0xf0111e0c,%esi
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f0104a34:	c7 45 c0 50 7d 10 f0 	movl   $0xf0107d50,-0x40(%ebp)
			return -1;
		}
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0104a3b:	8b 45 bc             	mov    -0x44(%ebp),%eax
f0104a3e:	39 45 b8             	cmp    %eax,-0x48(%ebp)
f0104a41:	0f 83 9c 01 00 00    	jae    f0104be3 <debuginfo_eip+0x2f8>
f0104a47:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f0104a4b:	0f 85 99 01 00 00    	jne    f0104bea <debuginfo_eip+0x2ff>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0104a51:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0104a58:	2b 75 c0             	sub    -0x40(%ebp),%esi
f0104a5b:	c1 fe 02             	sar    $0x2,%esi
f0104a5e:	69 c6 ab aa aa aa    	imul   $0xaaaaaaab,%esi,%eax
f0104a64:	83 e8 01             	sub    $0x1,%eax
f0104a67:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0104a6a:	83 ec 08             	sub    $0x8,%esp
f0104a6d:	57                   	push   %edi
f0104a6e:	6a 64                	push   $0x64
f0104a70:	8d 55 e0             	lea    -0x20(%ebp),%edx
f0104a73:	89 d1                	mov    %edx,%ecx
f0104a75:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0104a78:	8b 75 c0             	mov    -0x40(%ebp),%esi
f0104a7b:	89 f0                	mov    %esi,%eax
f0104a7d:	e8 73 fd ff ff       	call   f01047f5 <stab_binsearch>
	if (lfile == 0)
f0104a82:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104a85:	83 c4 10             	add    $0x10,%esp
f0104a88:	85 c0                	test   %eax,%eax
f0104a8a:	0f 84 61 01 00 00    	je     f0104bf1 <debuginfo_eip+0x306>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0104a90:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0104a93:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104a96:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0104a99:	83 ec 08             	sub    $0x8,%esp
f0104a9c:	57                   	push   %edi
f0104a9d:	6a 24                	push   $0x24
f0104a9f:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0104aa2:	89 d1                	mov    %edx,%ecx
f0104aa4:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0104aa7:	89 f0                	mov    %esi,%eax
f0104aa9:	e8 47 fd ff ff       	call   f01047f5 <stab_binsearch>

	if (lfun <= rfun) {
f0104aae:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0104ab1:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0104ab4:	83 c4 10             	add    $0x10,%esp
f0104ab7:	39 d0                	cmp    %edx,%eax
f0104ab9:	7f 2e                	jg     f0104ae9 <debuginfo_eip+0x1fe>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0104abb:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f0104abe:	8d 34 8e             	lea    (%esi,%ecx,4),%esi
f0104ac1:	89 75 c4             	mov    %esi,-0x3c(%ebp)
f0104ac4:	8b 36                	mov    (%esi),%esi
f0104ac6:	8b 4d bc             	mov    -0x44(%ebp),%ecx
f0104ac9:	2b 4d b8             	sub    -0x48(%ebp),%ecx
f0104acc:	39 ce                	cmp    %ecx,%esi
f0104ace:	73 06                	jae    f0104ad6 <debuginfo_eip+0x1eb>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0104ad0:	03 75 b8             	add    -0x48(%ebp),%esi
f0104ad3:	89 73 08             	mov    %esi,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0104ad6:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f0104ad9:	8b 4e 08             	mov    0x8(%esi),%ecx
f0104adc:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0104adf:	29 cf                	sub    %ecx,%edi
		// Search within the function definition for the line number.
		lline = lfun;
f0104ae1:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0104ae4:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0104ae7:	eb 0f                	jmp    f0104af8 <debuginfo_eip+0x20d>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0104ae9:	89 7b 10             	mov    %edi,0x10(%ebx)
		lline = lfile;
f0104aec:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104aef:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0104af2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104af5:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0104af8:	83 ec 08             	sub    $0x8,%esp
f0104afb:	6a 3a                	push   $0x3a
f0104afd:	ff 73 08             	pushl  0x8(%ebx)
f0104b00:	e8 92 08 00 00       	call   f0105397 <strfind>
f0104b05:	2b 43 08             	sub    0x8(%ebx),%eax
f0104b08:	89 43 0c             	mov    %eax,0xc(%ebx)
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.

	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);	
f0104b0b:	83 c4 08             	add    $0x8,%esp
f0104b0e:	57                   	push   %edi
f0104b0f:	6a 44                	push   $0x44
f0104b11:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0104b14:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0104b17:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0104b1a:	89 f8                	mov    %edi,%eax
f0104b1c:	e8 d4 fc ff ff       	call   f01047f5 <stab_binsearch>
	if (lline > rline)
f0104b21:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0104b24:	83 c4 10             	add    $0x10,%esp
f0104b27:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0104b2a:	0f 8f c8 00 00 00    	jg     f0104bf8 <debuginfo_eip+0x30d>
		    return -1;
	info->eip_line = stabs[lline].n_desc;
f0104b30:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0104b33:	8d 14 97             	lea    (%edi,%edx,4),%edx
f0104b36:	0f b7 4a 06          	movzwl 0x6(%edx),%ecx
f0104b3a:	89 4b 04             	mov    %ecx,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0104b3d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104b40:	c6 45 c4 00          	movb   $0x0,-0x3c(%ebp)
f0104b44:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0104b47:	eb 0a                	jmp    f0104b53 <debuginfo_eip+0x268>
f0104b49:	83 e8 01             	sub    $0x1,%eax
f0104b4c:	83 ea 0c             	sub    $0xc,%edx
f0104b4f:	c6 45 c4 01          	movb   $0x1,-0x3c(%ebp)
f0104b53:	39 c7                	cmp    %eax,%edi
f0104b55:	7e 05                	jle    f0104b5c <debuginfo_eip+0x271>
f0104b57:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104b5a:	eb 47                	jmp    f0104ba3 <debuginfo_eip+0x2b8>
	       && stabs[lline].n_type != N_SOL
f0104b5c:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0104b60:	80 f9 84             	cmp    $0x84,%cl
f0104b63:	75 0e                	jne    f0104b73 <debuginfo_eip+0x288>
f0104b65:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104b68:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f0104b6c:	74 1c                	je     f0104b8a <debuginfo_eip+0x29f>
f0104b6e:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0104b71:	eb 17                	jmp    f0104b8a <debuginfo_eip+0x29f>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0104b73:	80 f9 64             	cmp    $0x64,%cl
f0104b76:	75 d1                	jne    f0104b49 <debuginfo_eip+0x25e>
f0104b78:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f0104b7c:	74 cb                	je     f0104b49 <debuginfo_eip+0x25e>
f0104b7e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104b81:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f0104b85:	74 03                	je     f0104b8a <debuginfo_eip+0x29f>
f0104b87:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0104b8a:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0104b8d:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0104b90:	8b 14 87             	mov    (%edi,%eax,4),%edx
f0104b93:	8b 45 bc             	mov    -0x44(%ebp),%eax
f0104b96:	8b 7d b8             	mov    -0x48(%ebp),%edi
f0104b99:	29 f8                	sub    %edi,%eax
f0104b9b:	39 c2                	cmp    %eax,%edx
f0104b9d:	73 04                	jae    f0104ba3 <debuginfo_eip+0x2b8>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0104b9f:	01 fa                	add    %edi,%edx
f0104ba1:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0104ba3:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0104ba6:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0104ba9:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0104bae:	39 f2                	cmp    %esi,%edx
f0104bb0:	7d 52                	jge    f0104c04 <debuginfo_eip+0x319>
		for (lline = lfun + 1;
f0104bb2:	83 c2 01             	add    $0x1,%edx
f0104bb5:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0104bb8:	89 d0                	mov    %edx,%eax
f0104bba:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0104bbd:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0104bc0:	8d 14 97             	lea    (%edi,%edx,4),%edx
f0104bc3:	eb 04                	jmp    f0104bc9 <debuginfo_eip+0x2de>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0104bc5:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0104bc9:	39 c6                	cmp    %eax,%esi
f0104bcb:	7e 32                	jle    f0104bff <debuginfo_eip+0x314>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0104bcd:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0104bd1:	83 c0 01             	add    $0x1,%eax
f0104bd4:	83 c2 0c             	add    $0xc,%edx
f0104bd7:	80 f9 a0             	cmp    $0xa0,%cl
f0104bda:	74 e9                	je     f0104bc5 <debuginfo_eip+0x2da>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0104bdc:	b8 00 00 00 00       	mov    $0x0,%eax
f0104be1:	eb 21                	jmp    f0104c04 <debuginfo_eip+0x319>
		}
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0104be3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104be8:	eb 1a                	jmp    f0104c04 <debuginfo_eip+0x319>
f0104bea:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104bef:	eb 13                	jmp    f0104c04 <debuginfo_eip+0x319>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0104bf1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104bf6:	eb 0c                	jmp    f0104c04 <debuginfo_eip+0x319>
	//	which one.
	// Your code here.

	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);	
	if (lline > rline)
		    return -1;
f0104bf8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104bfd:	eb 05                	jmp    f0104c04 <debuginfo_eip+0x319>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0104bff:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104c04:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104c07:	5b                   	pop    %ebx
f0104c08:	5e                   	pop    %esi
f0104c09:	5f                   	pop    %edi
f0104c0a:	5d                   	pop    %ebp
f0104c0b:	c3                   	ret    

f0104c0c <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0104c0c:	55                   	push   %ebp
f0104c0d:	89 e5                	mov    %esp,%ebp
f0104c0f:	57                   	push   %edi
f0104c10:	56                   	push   %esi
f0104c11:	53                   	push   %ebx
f0104c12:	83 ec 1c             	sub    $0x1c,%esp
f0104c15:	89 c7                	mov    %eax,%edi
f0104c17:	89 d6                	mov    %edx,%esi
f0104c19:	8b 45 08             	mov    0x8(%ebp),%eax
f0104c1c:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104c1f:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104c22:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0104c25:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0104c28:	bb 00 00 00 00       	mov    $0x0,%ebx
f0104c2d:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0104c30:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0104c33:	39 d3                	cmp    %edx,%ebx
f0104c35:	72 05                	jb     f0104c3c <printnum+0x30>
f0104c37:	39 45 10             	cmp    %eax,0x10(%ebp)
f0104c3a:	77 45                	ja     f0104c81 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0104c3c:	83 ec 0c             	sub    $0xc,%esp
f0104c3f:	ff 75 18             	pushl  0x18(%ebp)
f0104c42:	8b 45 14             	mov    0x14(%ebp),%eax
f0104c45:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0104c48:	53                   	push   %ebx
f0104c49:	ff 75 10             	pushl  0x10(%ebp)
f0104c4c:	83 ec 08             	sub    $0x8,%esp
f0104c4f:	ff 75 e4             	pushl  -0x1c(%ebp)
f0104c52:	ff 75 e0             	pushl  -0x20(%ebp)
f0104c55:	ff 75 dc             	pushl  -0x24(%ebp)
f0104c58:	ff 75 d8             	pushl  -0x28(%ebp)
f0104c5b:	e8 70 11 00 00       	call   f0105dd0 <__udivdi3>
f0104c60:	83 c4 18             	add    $0x18,%esp
f0104c63:	52                   	push   %edx
f0104c64:	50                   	push   %eax
f0104c65:	89 f2                	mov    %esi,%edx
f0104c67:	89 f8                	mov    %edi,%eax
f0104c69:	e8 9e ff ff ff       	call   f0104c0c <printnum>
f0104c6e:	83 c4 20             	add    $0x20,%esp
f0104c71:	eb 18                	jmp    f0104c8b <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0104c73:	83 ec 08             	sub    $0x8,%esp
f0104c76:	56                   	push   %esi
f0104c77:	ff 75 18             	pushl  0x18(%ebp)
f0104c7a:	ff d7                	call   *%edi
f0104c7c:	83 c4 10             	add    $0x10,%esp
f0104c7f:	eb 03                	jmp    f0104c84 <printnum+0x78>
f0104c81:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0104c84:	83 eb 01             	sub    $0x1,%ebx
f0104c87:	85 db                	test   %ebx,%ebx
f0104c89:	7f e8                	jg     f0104c73 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0104c8b:	83 ec 08             	sub    $0x8,%esp
f0104c8e:	56                   	push   %esi
f0104c8f:	83 ec 04             	sub    $0x4,%esp
f0104c92:	ff 75 e4             	pushl  -0x1c(%ebp)
f0104c95:	ff 75 e0             	pushl  -0x20(%ebp)
f0104c98:	ff 75 dc             	pushl  -0x24(%ebp)
f0104c9b:	ff 75 d8             	pushl  -0x28(%ebp)
f0104c9e:	e8 5d 12 00 00       	call   f0105f00 <__umoddi3>
f0104ca3:	83 c4 14             	add    $0x14,%esp
f0104ca6:	0f be 80 c9 77 10 f0 	movsbl -0xfef8837(%eax),%eax
f0104cad:	50                   	push   %eax
f0104cae:	ff d7                	call   *%edi
}
f0104cb0:	83 c4 10             	add    $0x10,%esp
f0104cb3:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104cb6:	5b                   	pop    %ebx
f0104cb7:	5e                   	pop    %esi
f0104cb8:	5f                   	pop    %edi
f0104cb9:	5d                   	pop    %ebp
f0104cba:	c3                   	ret    

f0104cbb <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0104cbb:	55                   	push   %ebp
f0104cbc:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0104cbe:	83 fa 01             	cmp    $0x1,%edx
f0104cc1:	7e 0e                	jle    f0104cd1 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0104cc3:	8b 10                	mov    (%eax),%edx
f0104cc5:	8d 4a 08             	lea    0x8(%edx),%ecx
f0104cc8:	89 08                	mov    %ecx,(%eax)
f0104cca:	8b 02                	mov    (%edx),%eax
f0104ccc:	8b 52 04             	mov    0x4(%edx),%edx
f0104ccf:	eb 22                	jmp    f0104cf3 <getuint+0x38>
	else if (lflag)
f0104cd1:	85 d2                	test   %edx,%edx
f0104cd3:	74 10                	je     f0104ce5 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0104cd5:	8b 10                	mov    (%eax),%edx
f0104cd7:	8d 4a 04             	lea    0x4(%edx),%ecx
f0104cda:	89 08                	mov    %ecx,(%eax)
f0104cdc:	8b 02                	mov    (%edx),%eax
f0104cde:	ba 00 00 00 00       	mov    $0x0,%edx
f0104ce3:	eb 0e                	jmp    f0104cf3 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0104ce5:	8b 10                	mov    (%eax),%edx
f0104ce7:	8d 4a 04             	lea    0x4(%edx),%ecx
f0104cea:	89 08                	mov    %ecx,(%eax)
f0104cec:	8b 02                	mov    (%edx),%eax
f0104cee:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0104cf3:	5d                   	pop    %ebp
f0104cf4:	c3                   	ret    

f0104cf5 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0104cf5:	55                   	push   %ebp
f0104cf6:	89 e5                	mov    %esp,%ebp
f0104cf8:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0104cfb:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0104cff:	8b 10                	mov    (%eax),%edx
f0104d01:	3b 50 04             	cmp    0x4(%eax),%edx
f0104d04:	73 0a                	jae    f0104d10 <sprintputch+0x1b>
		*b->buf++ = ch;
f0104d06:	8d 4a 01             	lea    0x1(%edx),%ecx
f0104d09:	89 08                	mov    %ecx,(%eax)
f0104d0b:	8b 45 08             	mov    0x8(%ebp),%eax
f0104d0e:	88 02                	mov    %al,(%edx)
}
f0104d10:	5d                   	pop    %ebp
f0104d11:	c3                   	ret    

f0104d12 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0104d12:	55                   	push   %ebp
f0104d13:	89 e5                	mov    %esp,%ebp
f0104d15:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0104d18:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0104d1b:	50                   	push   %eax
f0104d1c:	ff 75 10             	pushl  0x10(%ebp)
f0104d1f:	ff 75 0c             	pushl  0xc(%ebp)
f0104d22:	ff 75 08             	pushl  0x8(%ebp)
f0104d25:	e8 05 00 00 00       	call   f0104d2f <vprintfmt>
	va_end(ap);
}
f0104d2a:	83 c4 10             	add    $0x10,%esp
f0104d2d:	c9                   	leave  
f0104d2e:	c3                   	ret    

f0104d2f <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0104d2f:	55                   	push   %ebp
f0104d30:	89 e5                	mov    %esp,%ebp
f0104d32:	57                   	push   %edi
f0104d33:	56                   	push   %esi
f0104d34:	53                   	push   %ebx
f0104d35:	83 ec 2c             	sub    $0x2c,%esp
f0104d38:	8b 75 08             	mov    0x8(%ebp),%esi
f0104d3b:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104d3e:	8b 7d 10             	mov    0x10(%ebp),%edi
f0104d41:	eb 12                	jmp    f0104d55 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0104d43:	85 c0                	test   %eax,%eax
f0104d45:	0f 84 89 03 00 00    	je     f01050d4 <vprintfmt+0x3a5>
				return;
			putch(ch, putdat);
f0104d4b:	83 ec 08             	sub    $0x8,%esp
f0104d4e:	53                   	push   %ebx
f0104d4f:	50                   	push   %eax
f0104d50:	ff d6                	call   *%esi
f0104d52:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0104d55:	83 c7 01             	add    $0x1,%edi
f0104d58:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0104d5c:	83 f8 25             	cmp    $0x25,%eax
f0104d5f:	75 e2                	jne    f0104d43 <vprintfmt+0x14>
f0104d61:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0104d65:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0104d6c:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0104d73:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0104d7a:	ba 00 00 00 00       	mov    $0x0,%edx
f0104d7f:	eb 07                	jmp    f0104d88 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104d81:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0104d84:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104d88:	8d 47 01             	lea    0x1(%edi),%eax
f0104d8b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0104d8e:	0f b6 07             	movzbl (%edi),%eax
f0104d91:	0f b6 c8             	movzbl %al,%ecx
f0104d94:	83 e8 23             	sub    $0x23,%eax
f0104d97:	3c 55                	cmp    $0x55,%al
f0104d99:	0f 87 1a 03 00 00    	ja     f01050b9 <vprintfmt+0x38a>
f0104d9f:	0f b6 c0             	movzbl %al,%eax
f0104da2:	ff 24 85 00 79 10 f0 	jmp    *-0xfef8700(,%eax,4)
f0104da9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0104dac:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0104db0:	eb d6                	jmp    f0104d88 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104db2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104db5:	b8 00 00 00 00       	mov    $0x0,%eax
f0104dba:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0104dbd:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0104dc0:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f0104dc4:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0104dc7:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0104dca:	83 fa 09             	cmp    $0x9,%edx
f0104dcd:	77 39                	ja     f0104e08 <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0104dcf:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0104dd2:	eb e9                	jmp    f0104dbd <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0104dd4:	8b 45 14             	mov    0x14(%ebp),%eax
f0104dd7:	8d 48 04             	lea    0x4(%eax),%ecx
f0104dda:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0104ddd:	8b 00                	mov    (%eax),%eax
f0104ddf:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104de2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0104de5:	eb 27                	jmp    f0104e0e <vprintfmt+0xdf>
f0104de7:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104dea:	85 c0                	test   %eax,%eax
f0104dec:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104df1:	0f 49 c8             	cmovns %eax,%ecx
f0104df4:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104df7:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104dfa:	eb 8c                	jmp    f0104d88 <vprintfmt+0x59>
f0104dfc:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0104dff:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0104e06:	eb 80                	jmp    f0104d88 <vprintfmt+0x59>
f0104e08:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0104e0b:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0104e0e:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0104e12:	0f 89 70 ff ff ff    	jns    f0104d88 <vprintfmt+0x59>
				width = precision, precision = -1;
f0104e18:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0104e1b:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0104e1e:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0104e25:	e9 5e ff ff ff       	jmp    f0104d88 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0104e2a:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104e2d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0104e30:	e9 53 ff ff ff       	jmp    f0104d88 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0104e35:	8b 45 14             	mov    0x14(%ebp),%eax
f0104e38:	8d 50 04             	lea    0x4(%eax),%edx
f0104e3b:	89 55 14             	mov    %edx,0x14(%ebp)
f0104e3e:	83 ec 08             	sub    $0x8,%esp
f0104e41:	53                   	push   %ebx
f0104e42:	ff 30                	pushl  (%eax)
f0104e44:	ff d6                	call   *%esi
			break;
f0104e46:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104e49:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0104e4c:	e9 04 ff ff ff       	jmp    f0104d55 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0104e51:	8b 45 14             	mov    0x14(%ebp),%eax
f0104e54:	8d 50 04             	lea    0x4(%eax),%edx
f0104e57:	89 55 14             	mov    %edx,0x14(%ebp)
f0104e5a:	8b 00                	mov    (%eax),%eax
f0104e5c:	99                   	cltd   
f0104e5d:	31 d0                	xor    %edx,%eax
f0104e5f:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0104e61:	83 f8 0f             	cmp    $0xf,%eax
f0104e64:	7f 0b                	jg     f0104e71 <vprintfmt+0x142>
f0104e66:	8b 14 85 60 7a 10 f0 	mov    -0xfef85a0(,%eax,4),%edx
f0104e6d:	85 d2                	test   %edx,%edx
f0104e6f:	75 18                	jne    f0104e89 <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f0104e71:	50                   	push   %eax
f0104e72:	68 e1 77 10 f0       	push   $0xf01077e1
f0104e77:	53                   	push   %ebx
f0104e78:	56                   	push   %esi
f0104e79:	e8 94 fe ff ff       	call   f0104d12 <printfmt>
f0104e7e:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104e81:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0104e84:	e9 cc fe ff ff       	jmp    f0104d55 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0104e89:	52                   	push   %edx
f0104e8a:	68 9c 6f 10 f0       	push   $0xf0106f9c
f0104e8f:	53                   	push   %ebx
f0104e90:	56                   	push   %esi
f0104e91:	e8 7c fe ff ff       	call   f0104d12 <printfmt>
f0104e96:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104e99:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104e9c:	e9 b4 fe ff ff       	jmp    f0104d55 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0104ea1:	8b 45 14             	mov    0x14(%ebp),%eax
f0104ea4:	8d 50 04             	lea    0x4(%eax),%edx
f0104ea7:	89 55 14             	mov    %edx,0x14(%ebp)
f0104eaa:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0104eac:	85 ff                	test   %edi,%edi
f0104eae:	b8 da 77 10 f0       	mov    $0xf01077da,%eax
f0104eb3:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0104eb6:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0104eba:	0f 8e 94 00 00 00    	jle    f0104f54 <vprintfmt+0x225>
f0104ec0:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0104ec4:	0f 84 98 00 00 00    	je     f0104f62 <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
f0104eca:	83 ec 08             	sub    $0x8,%esp
f0104ecd:	ff 75 d0             	pushl  -0x30(%ebp)
f0104ed0:	57                   	push   %edi
f0104ed1:	e8 77 03 00 00       	call   f010524d <strnlen>
f0104ed6:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0104ed9:	29 c1                	sub    %eax,%ecx
f0104edb:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0104ede:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0104ee1:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0104ee5:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0104ee8:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0104eeb:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0104eed:	eb 0f                	jmp    f0104efe <vprintfmt+0x1cf>
					putch(padc, putdat);
f0104eef:	83 ec 08             	sub    $0x8,%esp
f0104ef2:	53                   	push   %ebx
f0104ef3:	ff 75 e0             	pushl  -0x20(%ebp)
f0104ef6:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0104ef8:	83 ef 01             	sub    $0x1,%edi
f0104efb:	83 c4 10             	add    $0x10,%esp
f0104efe:	85 ff                	test   %edi,%edi
f0104f00:	7f ed                	jg     f0104eef <vprintfmt+0x1c0>
f0104f02:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0104f05:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0104f08:	85 c9                	test   %ecx,%ecx
f0104f0a:	b8 00 00 00 00       	mov    $0x0,%eax
f0104f0f:	0f 49 c1             	cmovns %ecx,%eax
f0104f12:	29 c1                	sub    %eax,%ecx
f0104f14:	89 75 08             	mov    %esi,0x8(%ebp)
f0104f17:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0104f1a:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0104f1d:	89 cb                	mov    %ecx,%ebx
f0104f1f:	eb 4d                	jmp    f0104f6e <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0104f21:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0104f25:	74 1b                	je     f0104f42 <vprintfmt+0x213>
f0104f27:	0f be c0             	movsbl %al,%eax
f0104f2a:	83 e8 20             	sub    $0x20,%eax
f0104f2d:	83 f8 5e             	cmp    $0x5e,%eax
f0104f30:	76 10                	jbe    f0104f42 <vprintfmt+0x213>
					putch('?', putdat);
f0104f32:	83 ec 08             	sub    $0x8,%esp
f0104f35:	ff 75 0c             	pushl  0xc(%ebp)
f0104f38:	6a 3f                	push   $0x3f
f0104f3a:	ff 55 08             	call   *0x8(%ebp)
f0104f3d:	83 c4 10             	add    $0x10,%esp
f0104f40:	eb 0d                	jmp    f0104f4f <vprintfmt+0x220>
				else
					putch(ch, putdat);
f0104f42:	83 ec 08             	sub    $0x8,%esp
f0104f45:	ff 75 0c             	pushl  0xc(%ebp)
f0104f48:	52                   	push   %edx
f0104f49:	ff 55 08             	call   *0x8(%ebp)
f0104f4c:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0104f4f:	83 eb 01             	sub    $0x1,%ebx
f0104f52:	eb 1a                	jmp    f0104f6e <vprintfmt+0x23f>
f0104f54:	89 75 08             	mov    %esi,0x8(%ebp)
f0104f57:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0104f5a:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0104f5d:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0104f60:	eb 0c                	jmp    f0104f6e <vprintfmt+0x23f>
f0104f62:	89 75 08             	mov    %esi,0x8(%ebp)
f0104f65:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0104f68:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0104f6b:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0104f6e:	83 c7 01             	add    $0x1,%edi
f0104f71:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0104f75:	0f be d0             	movsbl %al,%edx
f0104f78:	85 d2                	test   %edx,%edx
f0104f7a:	74 23                	je     f0104f9f <vprintfmt+0x270>
f0104f7c:	85 f6                	test   %esi,%esi
f0104f7e:	78 a1                	js     f0104f21 <vprintfmt+0x1f2>
f0104f80:	83 ee 01             	sub    $0x1,%esi
f0104f83:	79 9c                	jns    f0104f21 <vprintfmt+0x1f2>
f0104f85:	89 df                	mov    %ebx,%edi
f0104f87:	8b 75 08             	mov    0x8(%ebp),%esi
f0104f8a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104f8d:	eb 18                	jmp    f0104fa7 <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0104f8f:	83 ec 08             	sub    $0x8,%esp
f0104f92:	53                   	push   %ebx
f0104f93:	6a 20                	push   $0x20
f0104f95:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0104f97:	83 ef 01             	sub    $0x1,%edi
f0104f9a:	83 c4 10             	add    $0x10,%esp
f0104f9d:	eb 08                	jmp    f0104fa7 <vprintfmt+0x278>
f0104f9f:	89 df                	mov    %ebx,%edi
f0104fa1:	8b 75 08             	mov    0x8(%ebp),%esi
f0104fa4:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104fa7:	85 ff                	test   %edi,%edi
f0104fa9:	7f e4                	jg     f0104f8f <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104fab:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104fae:	e9 a2 fd ff ff       	jmp    f0104d55 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0104fb3:	83 fa 01             	cmp    $0x1,%edx
f0104fb6:	7e 16                	jle    f0104fce <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f0104fb8:	8b 45 14             	mov    0x14(%ebp),%eax
f0104fbb:	8d 50 08             	lea    0x8(%eax),%edx
f0104fbe:	89 55 14             	mov    %edx,0x14(%ebp)
f0104fc1:	8b 50 04             	mov    0x4(%eax),%edx
f0104fc4:	8b 00                	mov    (%eax),%eax
f0104fc6:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104fc9:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0104fcc:	eb 32                	jmp    f0105000 <vprintfmt+0x2d1>
	else if (lflag)
f0104fce:	85 d2                	test   %edx,%edx
f0104fd0:	74 18                	je     f0104fea <vprintfmt+0x2bb>
		return va_arg(*ap, long);
f0104fd2:	8b 45 14             	mov    0x14(%ebp),%eax
f0104fd5:	8d 50 04             	lea    0x4(%eax),%edx
f0104fd8:	89 55 14             	mov    %edx,0x14(%ebp)
f0104fdb:	8b 00                	mov    (%eax),%eax
f0104fdd:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104fe0:	89 c1                	mov    %eax,%ecx
f0104fe2:	c1 f9 1f             	sar    $0x1f,%ecx
f0104fe5:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0104fe8:	eb 16                	jmp    f0105000 <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
f0104fea:	8b 45 14             	mov    0x14(%ebp),%eax
f0104fed:	8d 50 04             	lea    0x4(%eax),%edx
f0104ff0:	89 55 14             	mov    %edx,0x14(%ebp)
f0104ff3:	8b 00                	mov    (%eax),%eax
f0104ff5:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104ff8:	89 c1                	mov    %eax,%ecx
f0104ffa:	c1 f9 1f             	sar    $0x1f,%ecx
f0104ffd:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0105000:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0105003:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0105006:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f010500b:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f010500f:	79 74                	jns    f0105085 <vprintfmt+0x356>
				putch('-', putdat);
f0105011:	83 ec 08             	sub    $0x8,%esp
f0105014:	53                   	push   %ebx
f0105015:	6a 2d                	push   $0x2d
f0105017:	ff d6                	call   *%esi
				num = -(long long) num;
f0105019:	8b 45 d8             	mov    -0x28(%ebp),%eax
f010501c:	8b 55 dc             	mov    -0x24(%ebp),%edx
f010501f:	f7 d8                	neg    %eax
f0105021:	83 d2 00             	adc    $0x0,%edx
f0105024:	f7 da                	neg    %edx
f0105026:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0105029:	b9 0a 00 00 00       	mov    $0xa,%ecx
f010502e:	eb 55                	jmp    f0105085 <vprintfmt+0x356>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0105030:	8d 45 14             	lea    0x14(%ebp),%eax
f0105033:	e8 83 fc ff ff       	call   f0104cbb <getuint>
			base = 10;
f0105038:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f010503d:	eb 46                	jmp    f0105085 <vprintfmt+0x356>
		// (unsigned) octal
		case 'o':
			//putch('X', putdat);
			//putch('X', putdat);
			//putch('X', putdat);
			num = getuint(&ap, lflag);
f010503f:	8d 45 14             	lea    0x14(%ebp),%eax
f0105042:	e8 74 fc ff ff       	call   f0104cbb <getuint>
			base = 8;
f0105047:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f010504c:	eb 37                	jmp    f0105085 <vprintfmt+0x356>

		// pointer
		case 'p':
			putch('0', putdat);
f010504e:	83 ec 08             	sub    $0x8,%esp
f0105051:	53                   	push   %ebx
f0105052:	6a 30                	push   $0x30
f0105054:	ff d6                	call   *%esi
			putch('x', putdat);
f0105056:	83 c4 08             	add    $0x8,%esp
f0105059:	53                   	push   %ebx
f010505a:	6a 78                	push   $0x78
f010505c:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f010505e:	8b 45 14             	mov    0x14(%ebp),%eax
f0105061:	8d 50 04             	lea    0x4(%eax),%edx
f0105064:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0105067:	8b 00                	mov    (%eax),%eax
f0105069:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f010506e:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0105071:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0105076:	eb 0d                	jmp    f0105085 <vprintfmt+0x356>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0105078:	8d 45 14             	lea    0x14(%ebp),%eax
f010507b:	e8 3b fc ff ff       	call   f0104cbb <getuint>
			base = 16;
f0105080:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0105085:	83 ec 0c             	sub    $0xc,%esp
f0105088:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f010508c:	57                   	push   %edi
f010508d:	ff 75 e0             	pushl  -0x20(%ebp)
f0105090:	51                   	push   %ecx
f0105091:	52                   	push   %edx
f0105092:	50                   	push   %eax
f0105093:	89 da                	mov    %ebx,%edx
f0105095:	89 f0                	mov    %esi,%eax
f0105097:	e8 70 fb ff ff       	call   f0104c0c <printnum>
			break;
f010509c:	83 c4 20             	add    $0x20,%esp
f010509f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01050a2:	e9 ae fc ff ff       	jmp    f0104d55 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f01050a7:	83 ec 08             	sub    $0x8,%esp
f01050aa:	53                   	push   %ebx
f01050ab:	51                   	push   %ecx
f01050ac:	ff d6                	call   *%esi
			break;
f01050ae:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01050b1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f01050b4:	e9 9c fc ff ff       	jmp    f0104d55 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f01050b9:	83 ec 08             	sub    $0x8,%esp
f01050bc:	53                   	push   %ebx
f01050bd:	6a 25                	push   $0x25
f01050bf:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f01050c1:	83 c4 10             	add    $0x10,%esp
f01050c4:	eb 03                	jmp    f01050c9 <vprintfmt+0x39a>
f01050c6:	83 ef 01             	sub    $0x1,%edi
f01050c9:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f01050cd:	75 f7                	jne    f01050c6 <vprintfmt+0x397>
f01050cf:	e9 81 fc ff ff       	jmp    f0104d55 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f01050d4:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01050d7:	5b                   	pop    %ebx
f01050d8:	5e                   	pop    %esi
f01050d9:	5f                   	pop    %edi
f01050da:	5d                   	pop    %ebp
f01050db:	c3                   	ret    

f01050dc <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01050dc:	55                   	push   %ebp
f01050dd:	89 e5                	mov    %esp,%ebp
f01050df:	83 ec 18             	sub    $0x18,%esp
f01050e2:	8b 45 08             	mov    0x8(%ebp),%eax
f01050e5:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01050e8:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01050eb:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01050ef:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01050f2:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01050f9:	85 c0                	test   %eax,%eax
f01050fb:	74 26                	je     f0105123 <vsnprintf+0x47>
f01050fd:	85 d2                	test   %edx,%edx
f01050ff:	7e 22                	jle    f0105123 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0105101:	ff 75 14             	pushl  0x14(%ebp)
f0105104:	ff 75 10             	pushl  0x10(%ebp)
f0105107:	8d 45 ec             	lea    -0x14(%ebp),%eax
f010510a:	50                   	push   %eax
f010510b:	68 f5 4c 10 f0       	push   $0xf0104cf5
f0105110:	e8 1a fc ff ff       	call   f0104d2f <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0105115:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0105118:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f010511b:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010511e:	83 c4 10             	add    $0x10,%esp
f0105121:	eb 05                	jmp    f0105128 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0105123:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0105128:	c9                   	leave  
f0105129:	c3                   	ret    

f010512a <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f010512a:	55                   	push   %ebp
f010512b:	89 e5                	mov    %esp,%ebp
f010512d:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0105130:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0105133:	50                   	push   %eax
f0105134:	ff 75 10             	pushl  0x10(%ebp)
f0105137:	ff 75 0c             	pushl  0xc(%ebp)
f010513a:	ff 75 08             	pushl  0x8(%ebp)
f010513d:	e8 9a ff ff ff       	call   f01050dc <vsnprintf>
	va_end(ap);

	return rc;
}
f0105142:	c9                   	leave  
f0105143:	c3                   	ret    

f0105144 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0105144:	55                   	push   %ebp
f0105145:	89 e5                	mov    %esp,%ebp
f0105147:	57                   	push   %edi
f0105148:	56                   	push   %esi
f0105149:	53                   	push   %ebx
f010514a:	83 ec 0c             	sub    $0xc,%esp
f010514d:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

#if JOS_KERNEL
	if (prompt != NULL)
f0105150:	85 c0                	test   %eax,%eax
f0105152:	74 11                	je     f0105165 <readline+0x21>
		cprintf("%s", prompt);
f0105154:	83 ec 08             	sub    $0x8,%esp
f0105157:	50                   	push   %eax
f0105158:	68 9c 6f 10 f0       	push   $0xf0106f9c
f010515d:	e8 cc e4 ff ff       	call   f010362e <cprintf>
f0105162:	83 c4 10             	add    $0x10,%esp
	if (prompt != NULL)
		fprintf(1, "%s", prompt);
#endif

	i = 0;
	echoing = iscons(0);
f0105165:	83 ec 0c             	sub    $0xc,%esp
f0105168:	6a 00                	push   $0x0
f010516a:	e8 4b b6 ff ff       	call   f01007ba <iscons>
f010516f:	89 c7                	mov    %eax,%edi
f0105171:	83 c4 10             	add    $0x10,%esp
#else
	if (prompt != NULL)
		fprintf(1, "%s", prompt);
#endif

	i = 0;
f0105174:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0105179:	e8 2b b6 ff ff       	call   f01007a9 <getchar>
f010517e:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0105180:	85 c0                	test   %eax,%eax
f0105182:	79 29                	jns    f01051ad <readline+0x69>
			if (c != -E_EOF)
				cprintf("read error: %e\n", c);
			return NULL;
f0105184:	b8 00 00 00 00       	mov    $0x0,%eax
	i = 0;
	echoing = iscons(0);
	while (1) {
		c = getchar();
		if (c < 0) {
			if (c != -E_EOF)
f0105189:	83 fb f8             	cmp    $0xfffffff8,%ebx
f010518c:	0f 84 9b 00 00 00    	je     f010522d <readline+0xe9>
				cprintf("read error: %e\n", c);
f0105192:	83 ec 08             	sub    $0x8,%esp
f0105195:	53                   	push   %ebx
f0105196:	68 bf 7a 10 f0       	push   $0xf0107abf
f010519b:	e8 8e e4 ff ff       	call   f010362e <cprintf>
f01051a0:	83 c4 10             	add    $0x10,%esp
			return NULL;
f01051a3:	b8 00 00 00 00       	mov    $0x0,%eax
f01051a8:	e9 80 00 00 00       	jmp    f010522d <readline+0xe9>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01051ad:	83 f8 08             	cmp    $0x8,%eax
f01051b0:	0f 94 c2             	sete   %dl
f01051b3:	83 f8 7f             	cmp    $0x7f,%eax
f01051b6:	0f 94 c0             	sete   %al
f01051b9:	08 c2                	or     %al,%dl
f01051bb:	74 1a                	je     f01051d7 <readline+0x93>
f01051bd:	85 f6                	test   %esi,%esi
f01051bf:	7e 16                	jle    f01051d7 <readline+0x93>
			if (echoing)
f01051c1:	85 ff                	test   %edi,%edi
f01051c3:	74 0d                	je     f01051d2 <readline+0x8e>
				cputchar('\b');
f01051c5:	83 ec 0c             	sub    $0xc,%esp
f01051c8:	6a 08                	push   $0x8
f01051ca:	e8 ca b5 ff ff       	call   f0100799 <cputchar>
f01051cf:	83 c4 10             	add    $0x10,%esp
			i--;
f01051d2:	83 ee 01             	sub    $0x1,%esi
f01051d5:	eb a2                	jmp    f0105179 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01051d7:	83 fb 1f             	cmp    $0x1f,%ebx
f01051da:	7e 26                	jle    f0105202 <readline+0xbe>
f01051dc:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01051e2:	7f 1e                	jg     f0105202 <readline+0xbe>
			if (echoing)
f01051e4:	85 ff                	test   %edi,%edi
f01051e6:	74 0c                	je     f01051f4 <readline+0xb0>
				cputchar(c);
f01051e8:	83 ec 0c             	sub    $0xc,%esp
f01051eb:	53                   	push   %ebx
f01051ec:	e8 a8 b5 ff ff       	call   f0100799 <cputchar>
f01051f1:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f01051f4:	88 9e 80 1a 21 f0    	mov    %bl,-0xfdee580(%esi)
f01051fa:	8d 76 01             	lea    0x1(%esi),%esi
f01051fd:	e9 77 ff ff ff       	jmp    f0105179 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0105202:	83 fb 0a             	cmp    $0xa,%ebx
f0105205:	74 09                	je     f0105210 <readline+0xcc>
f0105207:	83 fb 0d             	cmp    $0xd,%ebx
f010520a:	0f 85 69 ff ff ff    	jne    f0105179 <readline+0x35>
			if (echoing)
f0105210:	85 ff                	test   %edi,%edi
f0105212:	74 0d                	je     f0105221 <readline+0xdd>
				cputchar('\n');
f0105214:	83 ec 0c             	sub    $0xc,%esp
f0105217:	6a 0a                	push   $0xa
f0105219:	e8 7b b5 ff ff       	call   f0100799 <cputchar>
f010521e:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0105221:	c6 86 80 1a 21 f0 00 	movb   $0x0,-0xfdee580(%esi)
			return buf;
f0105228:	b8 80 1a 21 f0       	mov    $0xf0211a80,%eax
		}
	}
}
f010522d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0105230:	5b                   	pop    %ebx
f0105231:	5e                   	pop    %esi
f0105232:	5f                   	pop    %edi
f0105233:	5d                   	pop    %ebp
f0105234:	c3                   	ret    

f0105235 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0105235:	55                   	push   %ebp
f0105236:	89 e5                	mov    %esp,%ebp
f0105238:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f010523b:	b8 00 00 00 00       	mov    $0x0,%eax
f0105240:	eb 03                	jmp    f0105245 <strlen+0x10>
		n++;
f0105242:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0105245:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0105249:	75 f7                	jne    f0105242 <strlen+0xd>
		n++;
	return n;
}
f010524b:	5d                   	pop    %ebp
f010524c:	c3                   	ret    

f010524d <strnlen>:

int
strnlen(const char *s, size_t size)
{
f010524d:	55                   	push   %ebp
f010524e:	89 e5                	mov    %esp,%ebp
f0105250:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0105253:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0105256:	ba 00 00 00 00       	mov    $0x0,%edx
f010525b:	eb 03                	jmp    f0105260 <strnlen+0x13>
		n++;
f010525d:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0105260:	39 c2                	cmp    %eax,%edx
f0105262:	74 08                	je     f010526c <strnlen+0x1f>
f0105264:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f0105268:	75 f3                	jne    f010525d <strnlen+0x10>
f010526a:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f010526c:	5d                   	pop    %ebp
f010526d:	c3                   	ret    

f010526e <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f010526e:	55                   	push   %ebp
f010526f:	89 e5                	mov    %esp,%ebp
f0105271:	53                   	push   %ebx
f0105272:	8b 45 08             	mov    0x8(%ebp),%eax
f0105275:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0105278:	89 c2                	mov    %eax,%edx
f010527a:	83 c2 01             	add    $0x1,%edx
f010527d:	83 c1 01             	add    $0x1,%ecx
f0105280:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0105284:	88 5a ff             	mov    %bl,-0x1(%edx)
f0105287:	84 db                	test   %bl,%bl
f0105289:	75 ef                	jne    f010527a <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f010528b:	5b                   	pop    %ebx
f010528c:	5d                   	pop    %ebp
f010528d:	c3                   	ret    

f010528e <strcat>:

char *
strcat(char *dst, const char *src)
{
f010528e:	55                   	push   %ebp
f010528f:	89 e5                	mov    %esp,%ebp
f0105291:	53                   	push   %ebx
f0105292:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0105295:	53                   	push   %ebx
f0105296:	e8 9a ff ff ff       	call   f0105235 <strlen>
f010529b:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f010529e:	ff 75 0c             	pushl  0xc(%ebp)
f01052a1:	01 d8                	add    %ebx,%eax
f01052a3:	50                   	push   %eax
f01052a4:	e8 c5 ff ff ff       	call   f010526e <strcpy>
	return dst;
}
f01052a9:	89 d8                	mov    %ebx,%eax
f01052ab:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01052ae:	c9                   	leave  
f01052af:	c3                   	ret    

f01052b0 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01052b0:	55                   	push   %ebp
f01052b1:	89 e5                	mov    %esp,%ebp
f01052b3:	56                   	push   %esi
f01052b4:	53                   	push   %ebx
f01052b5:	8b 75 08             	mov    0x8(%ebp),%esi
f01052b8:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01052bb:	89 f3                	mov    %esi,%ebx
f01052bd:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01052c0:	89 f2                	mov    %esi,%edx
f01052c2:	eb 0f                	jmp    f01052d3 <strncpy+0x23>
		*dst++ = *src;
f01052c4:	83 c2 01             	add    $0x1,%edx
f01052c7:	0f b6 01             	movzbl (%ecx),%eax
f01052ca:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01052cd:	80 39 01             	cmpb   $0x1,(%ecx)
f01052d0:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01052d3:	39 da                	cmp    %ebx,%edx
f01052d5:	75 ed                	jne    f01052c4 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01052d7:	89 f0                	mov    %esi,%eax
f01052d9:	5b                   	pop    %ebx
f01052da:	5e                   	pop    %esi
f01052db:	5d                   	pop    %ebp
f01052dc:	c3                   	ret    

f01052dd <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01052dd:	55                   	push   %ebp
f01052de:	89 e5                	mov    %esp,%ebp
f01052e0:	56                   	push   %esi
f01052e1:	53                   	push   %ebx
f01052e2:	8b 75 08             	mov    0x8(%ebp),%esi
f01052e5:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01052e8:	8b 55 10             	mov    0x10(%ebp),%edx
f01052eb:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01052ed:	85 d2                	test   %edx,%edx
f01052ef:	74 21                	je     f0105312 <strlcpy+0x35>
f01052f1:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f01052f5:	89 f2                	mov    %esi,%edx
f01052f7:	eb 09                	jmp    f0105302 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01052f9:	83 c2 01             	add    $0x1,%edx
f01052fc:	83 c1 01             	add    $0x1,%ecx
f01052ff:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0105302:	39 c2                	cmp    %eax,%edx
f0105304:	74 09                	je     f010530f <strlcpy+0x32>
f0105306:	0f b6 19             	movzbl (%ecx),%ebx
f0105309:	84 db                	test   %bl,%bl
f010530b:	75 ec                	jne    f01052f9 <strlcpy+0x1c>
f010530d:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f010530f:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0105312:	29 f0                	sub    %esi,%eax
}
f0105314:	5b                   	pop    %ebx
f0105315:	5e                   	pop    %esi
f0105316:	5d                   	pop    %ebp
f0105317:	c3                   	ret    

f0105318 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0105318:	55                   	push   %ebp
f0105319:	89 e5                	mov    %esp,%ebp
f010531b:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010531e:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0105321:	eb 06                	jmp    f0105329 <strcmp+0x11>
		p++, q++;
f0105323:	83 c1 01             	add    $0x1,%ecx
f0105326:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0105329:	0f b6 01             	movzbl (%ecx),%eax
f010532c:	84 c0                	test   %al,%al
f010532e:	74 04                	je     f0105334 <strcmp+0x1c>
f0105330:	3a 02                	cmp    (%edx),%al
f0105332:	74 ef                	je     f0105323 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0105334:	0f b6 c0             	movzbl %al,%eax
f0105337:	0f b6 12             	movzbl (%edx),%edx
f010533a:	29 d0                	sub    %edx,%eax
}
f010533c:	5d                   	pop    %ebp
f010533d:	c3                   	ret    

f010533e <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f010533e:	55                   	push   %ebp
f010533f:	89 e5                	mov    %esp,%ebp
f0105341:	53                   	push   %ebx
f0105342:	8b 45 08             	mov    0x8(%ebp),%eax
f0105345:	8b 55 0c             	mov    0xc(%ebp),%edx
f0105348:	89 c3                	mov    %eax,%ebx
f010534a:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f010534d:	eb 06                	jmp    f0105355 <strncmp+0x17>
		n--, p++, q++;
f010534f:	83 c0 01             	add    $0x1,%eax
f0105352:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0105355:	39 d8                	cmp    %ebx,%eax
f0105357:	74 15                	je     f010536e <strncmp+0x30>
f0105359:	0f b6 08             	movzbl (%eax),%ecx
f010535c:	84 c9                	test   %cl,%cl
f010535e:	74 04                	je     f0105364 <strncmp+0x26>
f0105360:	3a 0a                	cmp    (%edx),%cl
f0105362:	74 eb                	je     f010534f <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0105364:	0f b6 00             	movzbl (%eax),%eax
f0105367:	0f b6 12             	movzbl (%edx),%edx
f010536a:	29 d0                	sub    %edx,%eax
f010536c:	eb 05                	jmp    f0105373 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f010536e:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0105373:	5b                   	pop    %ebx
f0105374:	5d                   	pop    %ebp
f0105375:	c3                   	ret    

f0105376 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0105376:	55                   	push   %ebp
f0105377:	89 e5                	mov    %esp,%ebp
f0105379:	8b 45 08             	mov    0x8(%ebp),%eax
f010537c:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0105380:	eb 07                	jmp    f0105389 <strchr+0x13>
		if (*s == c)
f0105382:	38 ca                	cmp    %cl,%dl
f0105384:	74 0f                	je     f0105395 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0105386:	83 c0 01             	add    $0x1,%eax
f0105389:	0f b6 10             	movzbl (%eax),%edx
f010538c:	84 d2                	test   %dl,%dl
f010538e:	75 f2                	jne    f0105382 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0105390:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0105395:	5d                   	pop    %ebp
f0105396:	c3                   	ret    

f0105397 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0105397:	55                   	push   %ebp
f0105398:	89 e5                	mov    %esp,%ebp
f010539a:	8b 45 08             	mov    0x8(%ebp),%eax
f010539d:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01053a1:	eb 03                	jmp    f01053a6 <strfind+0xf>
f01053a3:	83 c0 01             	add    $0x1,%eax
f01053a6:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f01053a9:	38 ca                	cmp    %cl,%dl
f01053ab:	74 04                	je     f01053b1 <strfind+0x1a>
f01053ad:	84 d2                	test   %dl,%dl
f01053af:	75 f2                	jne    f01053a3 <strfind+0xc>
			break;
	return (char *) s;
}
f01053b1:	5d                   	pop    %ebp
f01053b2:	c3                   	ret    

f01053b3 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01053b3:	55                   	push   %ebp
f01053b4:	89 e5                	mov    %esp,%ebp
f01053b6:	57                   	push   %edi
f01053b7:	56                   	push   %esi
f01053b8:	53                   	push   %ebx
f01053b9:	8b 7d 08             	mov    0x8(%ebp),%edi
f01053bc:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01053bf:	85 c9                	test   %ecx,%ecx
f01053c1:	74 36                	je     f01053f9 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01053c3:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01053c9:	75 28                	jne    f01053f3 <memset+0x40>
f01053cb:	f6 c1 03             	test   $0x3,%cl
f01053ce:	75 23                	jne    f01053f3 <memset+0x40>
		c &= 0xFF;
f01053d0:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01053d4:	89 d3                	mov    %edx,%ebx
f01053d6:	c1 e3 08             	shl    $0x8,%ebx
f01053d9:	89 d6                	mov    %edx,%esi
f01053db:	c1 e6 18             	shl    $0x18,%esi
f01053de:	89 d0                	mov    %edx,%eax
f01053e0:	c1 e0 10             	shl    $0x10,%eax
f01053e3:	09 f0                	or     %esi,%eax
f01053e5:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f01053e7:	89 d8                	mov    %ebx,%eax
f01053e9:	09 d0                	or     %edx,%eax
f01053eb:	c1 e9 02             	shr    $0x2,%ecx
f01053ee:	fc                   	cld    
f01053ef:	f3 ab                	rep stos %eax,%es:(%edi)
f01053f1:	eb 06                	jmp    f01053f9 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01053f3:	8b 45 0c             	mov    0xc(%ebp),%eax
f01053f6:	fc                   	cld    
f01053f7:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01053f9:	89 f8                	mov    %edi,%eax
f01053fb:	5b                   	pop    %ebx
f01053fc:	5e                   	pop    %esi
f01053fd:	5f                   	pop    %edi
f01053fe:	5d                   	pop    %ebp
f01053ff:	c3                   	ret    

f0105400 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0105400:	55                   	push   %ebp
f0105401:	89 e5                	mov    %esp,%ebp
f0105403:	57                   	push   %edi
f0105404:	56                   	push   %esi
f0105405:	8b 45 08             	mov    0x8(%ebp),%eax
f0105408:	8b 75 0c             	mov    0xc(%ebp),%esi
f010540b:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f010540e:	39 c6                	cmp    %eax,%esi
f0105410:	73 35                	jae    f0105447 <memmove+0x47>
f0105412:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0105415:	39 d0                	cmp    %edx,%eax
f0105417:	73 2e                	jae    f0105447 <memmove+0x47>
		s += n;
		d += n;
f0105419:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010541c:	89 d6                	mov    %edx,%esi
f010541e:	09 fe                	or     %edi,%esi
f0105420:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0105426:	75 13                	jne    f010543b <memmove+0x3b>
f0105428:	f6 c1 03             	test   $0x3,%cl
f010542b:	75 0e                	jne    f010543b <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f010542d:	83 ef 04             	sub    $0x4,%edi
f0105430:	8d 72 fc             	lea    -0x4(%edx),%esi
f0105433:	c1 e9 02             	shr    $0x2,%ecx
f0105436:	fd                   	std    
f0105437:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0105439:	eb 09                	jmp    f0105444 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f010543b:	83 ef 01             	sub    $0x1,%edi
f010543e:	8d 72 ff             	lea    -0x1(%edx),%esi
f0105441:	fd                   	std    
f0105442:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0105444:	fc                   	cld    
f0105445:	eb 1d                	jmp    f0105464 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0105447:	89 f2                	mov    %esi,%edx
f0105449:	09 c2                	or     %eax,%edx
f010544b:	f6 c2 03             	test   $0x3,%dl
f010544e:	75 0f                	jne    f010545f <memmove+0x5f>
f0105450:	f6 c1 03             	test   $0x3,%cl
f0105453:	75 0a                	jne    f010545f <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f0105455:	c1 e9 02             	shr    $0x2,%ecx
f0105458:	89 c7                	mov    %eax,%edi
f010545a:	fc                   	cld    
f010545b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010545d:	eb 05                	jmp    f0105464 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f010545f:	89 c7                	mov    %eax,%edi
f0105461:	fc                   	cld    
f0105462:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0105464:	5e                   	pop    %esi
f0105465:	5f                   	pop    %edi
f0105466:	5d                   	pop    %ebp
f0105467:	c3                   	ret    

f0105468 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0105468:	55                   	push   %ebp
f0105469:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f010546b:	ff 75 10             	pushl  0x10(%ebp)
f010546e:	ff 75 0c             	pushl  0xc(%ebp)
f0105471:	ff 75 08             	pushl  0x8(%ebp)
f0105474:	e8 87 ff ff ff       	call   f0105400 <memmove>
}
f0105479:	c9                   	leave  
f010547a:	c3                   	ret    

f010547b <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f010547b:	55                   	push   %ebp
f010547c:	89 e5                	mov    %esp,%ebp
f010547e:	56                   	push   %esi
f010547f:	53                   	push   %ebx
f0105480:	8b 45 08             	mov    0x8(%ebp),%eax
f0105483:	8b 55 0c             	mov    0xc(%ebp),%edx
f0105486:	89 c6                	mov    %eax,%esi
f0105488:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010548b:	eb 1a                	jmp    f01054a7 <memcmp+0x2c>
		if (*s1 != *s2)
f010548d:	0f b6 08             	movzbl (%eax),%ecx
f0105490:	0f b6 1a             	movzbl (%edx),%ebx
f0105493:	38 d9                	cmp    %bl,%cl
f0105495:	74 0a                	je     f01054a1 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0105497:	0f b6 c1             	movzbl %cl,%eax
f010549a:	0f b6 db             	movzbl %bl,%ebx
f010549d:	29 d8                	sub    %ebx,%eax
f010549f:	eb 0f                	jmp    f01054b0 <memcmp+0x35>
		s1++, s2++;
f01054a1:	83 c0 01             	add    $0x1,%eax
f01054a4:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01054a7:	39 f0                	cmp    %esi,%eax
f01054a9:	75 e2                	jne    f010548d <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01054ab:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01054b0:	5b                   	pop    %ebx
f01054b1:	5e                   	pop    %esi
f01054b2:	5d                   	pop    %ebp
f01054b3:	c3                   	ret    

f01054b4 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01054b4:	55                   	push   %ebp
f01054b5:	89 e5                	mov    %esp,%ebp
f01054b7:	53                   	push   %ebx
f01054b8:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f01054bb:	89 c1                	mov    %eax,%ecx
f01054bd:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f01054c0:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01054c4:	eb 0a                	jmp    f01054d0 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f01054c6:	0f b6 10             	movzbl (%eax),%edx
f01054c9:	39 da                	cmp    %ebx,%edx
f01054cb:	74 07                	je     f01054d4 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01054cd:	83 c0 01             	add    $0x1,%eax
f01054d0:	39 c8                	cmp    %ecx,%eax
f01054d2:	72 f2                	jb     f01054c6 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01054d4:	5b                   	pop    %ebx
f01054d5:	5d                   	pop    %ebp
f01054d6:	c3                   	ret    

f01054d7 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01054d7:	55                   	push   %ebp
f01054d8:	89 e5                	mov    %esp,%ebp
f01054da:	57                   	push   %edi
f01054db:	56                   	push   %esi
f01054dc:	53                   	push   %ebx
f01054dd:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01054e0:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01054e3:	eb 03                	jmp    f01054e8 <strtol+0x11>
		s++;
f01054e5:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01054e8:	0f b6 01             	movzbl (%ecx),%eax
f01054eb:	3c 20                	cmp    $0x20,%al
f01054ed:	74 f6                	je     f01054e5 <strtol+0xe>
f01054ef:	3c 09                	cmp    $0x9,%al
f01054f1:	74 f2                	je     f01054e5 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f01054f3:	3c 2b                	cmp    $0x2b,%al
f01054f5:	75 0a                	jne    f0105501 <strtol+0x2a>
		s++;
f01054f7:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01054fa:	bf 00 00 00 00       	mov    $0x0,%edi
f01054ff:	eb 11                	jmp    f0105512 <strtol+0x3b>
f0105501:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0105506:	3c 2d                	cmp    $0x2d,%al
f0105508:	75 08                	jne    f0105512 <strtol+0x3b>
		s++, neg = 1;
f010550a:	83 c1 01             	add    $0x1,%ecx
f010550d:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0105512:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0105518:	75 15                	jne    f010552f <strtol+0x58>
f010551a:	80 39 30             	cmpb   $0x30,(%ecx)
f010551d:	75 10                	jne    f010552f <strtol+0x58>
f010551f:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0105523:	75 7c                	jne    f01055a1 <strtol+0xca>
		s += 2, base = 16;
f0105525:	83 c1 02             	add    $0x2,%ecx
f0105528:	bb 10 00 00 00       	mov    $0x10,%ebx
f010552d:	eb 16                	jmp    f0105545 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f010552f:	85 db                	test   %ebx,%ebx
f0105531:	75 12                	jne    f0105545 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0105533:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0105538:	80 39 30             	cmpb   $0x30,(%ecx)
f010553b:	75 08                	jne    f0105545 <strtol+0x6e>
		s++, base = 8;
f010553d:	83 c1 01             	add    $0x1,%ecx
f0105540:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f0105545:	b8 00 00 00 00       	mov    $0x0,%eax
f010554a:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f010554d:	0f b6 11             	movzbl (%ecx),%edx
f0105550:	8d 72 d0             	lea    -0x30(%edx),%esi
f0105553:	89 f3                	mov    %esi,%ebx
f0105555:	80 fb 09             	cmp    $0x9,%bl
f0105558:	77 08                	ja     f0105562 <strtol+0x8b>
			dig = *s - '0';
f010555a:	0f be d2             	movsbl %dl,%edx
f010555d:	83 ea 30             	sub    $0x30,%edx
f0105560:	eb 22                	jmp    f0105584 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f0105562:	8d 72 9f             	lea    -0x61(%edx),%esi
f0105565:	89 f3                	mov    %esi,%ebx
f0105567:	80 fb 19             	cmp    $0x19,%bl
f010556a:	77 08                	ja     f0105574 <strtol+0x9d>
			dig = *s - 'a' + 10;
f010556c:	0f be d2             	movsbl %dl,%edx
f010556f:	83 ea 57             	sub    $0x57,%edx
f0105572:	eb 10                	jmp    f0105584 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f0105574:	8d 72 bf             	lea    -0x41(%edx),%esi
f0105577:	89 f3                	mov    %esi,%ebx
f0105579:	80 fb 19             	cmp    $0x19,%bl
f010557c:	77 16                	ja     f0105594 <strtol+0xbd>
			dig = *s - 'A' + 10;
f010557e:	0f be d2             	movsbl %dl,%edx
f0105581:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f0105584:	3b 55 10             	cmp    0x10(%ebp),%edx
f0105587:	7d 0b                	jge    f0105594 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f0105589:	83 c1 01             	add    $0x1,%ecx
f010558c:	0f af 45 10          	imul   0x10(%ebp),%eax
f0105590:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f0105592:	eb b9                	jmp    f010554d <strtol+0x76>

	if (endptr)
f0105594:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0105598:	74 0d                	je     f01055a7 <strtol+0xd0>
		*endptr = (char *) s;
f010559a:	8b 75 0c             	mov    0xc(%ebp),%esi
f010559d:	89 0e                	mov    %ecx,(%esi)
f010559f:	eb 06                	jmp    f01055a7 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01055a1:	85 db                	test   %ebx,%ebx
f01055a3:	74 98                	je     f010553d <strtol+0x66>
f01055a5:	eb 9e                	jmp    f0105545 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f01055a7:	89 c2                	mov    %eax,%edx
f01055a9:	f7 da                	neg    %edx
f01055ab:	85 ff                	test   %edi,%edi
f01055ad:	0f 45 c2             	cmovne %edx,%eax
}
f01055b0:	5b                   	pop    %ebx
f01055b1:	5e                   	pop    %esi
f01055b2:	5f                   	pop    %edi
f01055b3:	5d                   	pop    %ebp
f01055b4:	c3                   	ret    
f01055b5:	66 90                	xchg   %ax,%ax
f01055b7:	90                   	nop

f01055b8 <mpentry_start>:
.set PROT_MODE_DSEG, 0x10	# kernel data segment selector

.code16           
.globl mpentry_start
mpentry_start:
	cli            
f01055b8:	fa                   	cli    

	xorw    %ax, %ax
f01055b9:	31 c0                	xor    %eax,%eax
	movw    %ax, %ds
f01055bb:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f01055bd:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f01055bf:	8e d0                	mov    %eax,%ss

	lgdt    MPBOOTPHYS(gdtdesc)
f01055c1:	0f 01 16             	lgdtl  (%esi)
f01055c4:	74 70                	je     f0105636 <mpsearch1+0x3>
	movl    %cr0, %eax
f01055c6:	0f 20 c0             	mov    %cr0,%eax
	orl     $CR0_PE, %eax
f01055c9:	66 83 c8 01          	or     $0x1,%ax
	movl    %eax, %cr0
f01055cd:	0f 22 c0             	mov    %eax,%cr0

	ljmpl   $(PROT_MODE_CSEG), $(MPBOOTPHYS(start32))
f01055d0:	66 ea 20 70 00 00    	ljmpw  $0x0,$0x7020
f01055d6:	08 00                	or     %al,(%eax)

f01055d8 <start32>:

.code32
start32:
	movw    $(PROT_MODE_DSEG), %ax
f01055d8:	66 b8 10 00          	mov    $0x10,%ax
	movw    %ax, %ds
f01055dc:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f01055de:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f01055e0:	8e d0                	mov    %eax,%ss
	movw    $0, %ax
f01055e2:	66 b8 00 00          	mov    $0x0,%ax
	movw    %ax, %fs
f01055e6:	8e e0                	mov    %eax,%fs
	movw    %ax, %gs
f01055e8:	8e e8                	mov    %eax,%gs

	# Set up initial page table. We cannot use kern_pgdir yet because
	# we are still running at a low EIP.
	movl    $(RELOC(entry_pgdir)), %eax
f01055ea:	b8 00 e0 11 00       	mov    $0x11e000,%eax
	movl    %eax, %cr3
f01055ef:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl    %cr0, %eax
f01055f2:	0f 20 c0             	mov    %cr0,%eax
	orl     $(CR0_PE|CR0_PG|CR0_WP), %eax
f01055f5:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl    %eax, %cr0
f01055fa:	0f 22 c0             	mov    %eax,%cr0

	# Switch to the per-cpu stack allocated in boot_aps()
	movl    mpentry_kstack, %esp
f01055fd:	8b 25 84 1e 21 f0    	mov    0xf0211e84,%esp
	movl    $0x0, %ebp       # nuke frame pointer
f0105603:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Call mp_main().  (Exercise for the reader: why the indirect call?)
	movl    $mp_main, %eax
f0105608:	b8 c7 01 10 f0       	mov    $0xf01001c7,%eax
	call    *%eax
f010560d:	ff d0                	call   *%eax

f010560f <spin>:

	# If mp_main returns (it shouldn't), loop.
spin:
	jmp     spin
f010560f:	eb fe                	jmp    f010560f <spin>
f0105611:	8d 76 00             	lea    0x0(%esi),%esi

f0105614 <gdt>:
	...
f010561c:	ff                   	(bad)  
f010561d:	ff 00                	incl   (%eax)
f010561f:	00 00                	add    %al,(%eax)
f0105621:	9a cf 00 ff ff 00 00 	lcall  $0x0,$0xffff00cf
f0105628:	00                   	.byte 0x0
f0105629:	92                   	xchg   %eax,%edx
f010562a:	cf                   	iret   
	...

f010562c <gdtdesc>:
f010562c:	17                   	pop    %ss
f010562d:	00 5c 70 00          	add    %bl,0x0(%eax,%esi,2)
	...

f0105632 <mpentry_end>:
	.word   0x17				# sizeof(gdt) - 1
	.long   MPBOOTPHYS(gdt)			# address gdt

.globl mpentry_end
mpentry_end:
	nop
f0105632:	90                   	nop

f0105633 <mpsearch1>:
}

// Look for an MP structure in the len bytes at physical address addr.
static struct mp *
mpsearch1(physaddr_t a, int len)
{
f0105633:	55                   	push   %ebp
f0105634:	89 e5                	mov    %esp,%ebp
f0105636:	57                   	push   %edi
f0105637:	56                   	push   %esi
f0105638:	53                   	push   %ebx
f0105639:	83 ec 0c             	sub    $0xc,%esp
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010563c:	8b 0d 88 1e 21 f0    	mov    0xf0211e88,%ecx
f0105642:	89 c3                	mov    %eax,%ebx
f0105644:	c1 eb 0c             	shr    $0xc,%ebx
f0105647:	39 cb                	cmp    %ecx,%ebx
f0105649:	72 12                	jb     f010565d <mpsearch1+0x2a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010564b:	50                   	push   %eax
f010564c:	68 84 60 10 f0       	push   $0xf0106084
f0105651:	6a 57                	push   $0x57
f0105653:	68 5d 7c 10 f0       	push   $0xf0107c5d
f0105658:	e8 e3 a9 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f010565d:	8d 98 00 00 00 f0    	lea    -0x10000000(%eax),%ebx
	struct mp *mp = KADDR(a), *end = KADDR(a + len);
f0105663:	01 d0                	add    %edx,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0105665:	89 c2                	mov    %eax,%edx
f0105667:	c1 ea 0c             	shr    $0xc,%edx
f010566a:	39 ca                	cmp    %ecx,%edx
f010566c:	72 12                	jb     f0105680 <mpsearch1+0x4d>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010566e:	50                   	push   %eax
f010566f:	68 84 60 10 f0       	push   $0xf0106084
f0105674:	6a 57                	push   $0x57
f0105676:	68 5d 7c 10 f0       	push   $0xf0107c5d
f010567b:	e8 c0 a9 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0105680:	8d b0 00 00 00 f0    	lea    -0x10000000(%eax),%esi

	for (; mp < end; mp++)
f0105686:	eb 2f                	jmp    f01056b7 <mpsearch1+0x84>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f0105688:	83 ec 04             	sub    $0x4,%esp
f010568b:	6a 04                	push   $0x4
f010568d:	68 6d 7c 10 f0       	push   $0xf0107c6d
f0105692:	53                   	push   %ebx
f0105693:	e8 e3 fd ff ff       	call   f010547b <memcmp>
f0105698:	83 c4 10             	add    $0x10,%esp
f010569b:	85 c0                	test   %eax,%eax
f010569d:	75 15                	jne    f01056b4 <mpsearch1+0x81>
f010569f:	89 da                	mov    %ebx,%edx
f01056a1:	8d 7b 10             	lea    0x10(%ebx),%edi
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
		sum += ((uint8_t *)addr)[i];
f01056a4:	0f b6 0a             	movzbl (%edx),%ecx
f01056a7:	01 c8                	add    %ecx,%eax
f01056a9:	83 c2 01             	add    $0x1,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f01056ac:	39 d7                	cmp    %edx,%edi
f01056ae:	75 f4                	jne    f01056a4 <mpsearch1+0x71>
mpsearch1(physaddr_t a, int len)
{
	struct mp *mp = KADDR(a), *end = KADDR(a + len);

	for (; mp < end; mp++)
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f01056b0:	84 c0                	test   %al,%al
f01056b2:	74 0e                	je     f01056c2 <mpsearch1+0x8f>
static struct mp *
mpsearch1(physaddr_t a, int len)
{
	struct mp *mp = KADDR(a), *end = KADDR(a + len);

	for (; mp < end; mp++)
f01056b4:	83 c3 10             	add    $0x10,%ebx
f01056b7:	39 f3                	cmp    %esi,%ebx
f01056b9:	72 cd                	jb     f0105688 <mpsearch1+0x55>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
		    sum(mp, sizeof(*mp)) == 0)
			return mp;
	return NULL;
f01056bb:	b8 00 00 00 00       	mov    $0x0,%eax
f01056c0:	eb 02                	jmp    f01056c4 <mpsearch1+0x91>
f01056c2:	89 d8                	mov    %ebx,%eax
}
f01056c4:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01056c7:	5b                   	pop    %ebx
f01056c8:	5e                   	pop    %esi
f01056c9:	5f                   	pop    %edi
f01056ca:	5d                   	pop    %ebp
f01056cb:	c3                   	ret    

f01056cc <mp_init>:
	return conf;
}

void
mp_init(void)
{
f01056cc:	55                   	push   %ebp
f01056cd:	89 e5                	mov    %esp,%ebp
f01056cf:	57                   	push   %edi
f01056d0:	56                   	push   %esi
f01056d1:	53                   	push   %ebx
f01056d2:	83 ec 1c             	sub    $0x1c,%esp
	struct mpconf *conf;
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
f01056d5:	c7 05 c0 23 21 f0 20 	movl   $0xf0212020,0xf02123c0
f01056dc:	20 21 f0 
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01056df:	83 3d 88 1e 21 f0 00 	cmpl   $0x0,0xf0211e88
f01056e6:	75 16                	jne    f01056fe <mp_init+0x32>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01056e8:	68 00 04 00 00       	push   $0x400
f01056ed:	68 84 60 10 f0       	push   $0xf0106084
f01056f2:	6a 6f                	push   $0x6f
f01056f4:	68 5d 7c 10 f0       	push   $0xf0107c5d
f01056f9:	e8 42 a9 ff ff       	call   f0100040 <_panic>
	// The BIOS data area lives in 16-bit segment 0x40.
	bda = (uint8_t *) KADDR(0x40 << 4);

	// [MP 4] The 16-bit segment of the EBDA is in the two bytes
	// starting at byte 0x0E of the BDA.  0 if not present.
	if ((p = *(uint16_t *) (bda + 0x0E))) {
f01056fe:	0f b7 05 0e 04 00 f0 	movzwl 0xf000040e,%eax
f0105705:	85 c0                	test   %eax,%eax
f0105707:	74 16                	je     f010571f <mp_init+0x53>
		p <<= 4;	// Translate from segment to PA
		if ((mp = mpsearch1(p, 1024)))
f0105709:	c1 e0 04             	shl    $0x4,%eax
f010570c:	ba 00 04 00 00       	mov    $0x400,%edx
f0105711:	e8 1d ff ff ff       	call   f0105633 <mpsearch1>
f0105716:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0105719:	85 c0                	test   %eax,%eax
f010571b:	75 3c                	jne    f0105759 <mp_init+0x8d>
f010571d:	eb 20                	jmp    f010573f <mp_init+0x73>
			return mp;
	} else {
		// The size of base memory, in KB is in the two bytes
		// starting at 0x13 of the BDA.
		p = *(uint16_t *) (bda + 0x13) * 1024;
		if ((mp = mpsearch1(p - 1024, 1024)))
f010571f:	0f b7 05 13 04 00 f0 	movzwl 0xf0000413,%eax
f0105726:	c1 e0 0a             	shl    $0xa,%eax
f0105729:	2d 00 04 00 00       	sub    $0x400,%eax
f010572e:	ba 00 04 00 00       	mov    $0x400,%edx
f0105733:	e8 fb fe ff ff       	call   f0105633 <mpsearch1>
f0105738:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010573b:	85 c0                	test   %eax,%eax
f010573d:	75 1a                	jne    f0105759 <mp_init+0x8d>
			return mp;
	}
	return mpsearch1(0xF0000, 0x10000);
f010573f:	ba 00 00 01 00       	mov    $0x10000,%edx
f0105744:	b8 00 00 0f 00       	mov    $0xf0000,%eax
f0105749:	e8 e5 fe ff ff       	call   f0105633 <mpsearch1>
f010574e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
mpconfig(struct mp **pmp)
{
	struct mpconf *conf;
	struct mp *mp;

	if ((mp = mpsearch()) == 0)
f0105751:	85 c0                	test   %eax,%eax
f0105753:	0f 84 5d 02 00 00    	je     f01059b6 <mp_init+0x2ea>
		return NULL;
	if (mp->physaddr == 0 || mp->type != 0) {
f0105759:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010575c:	8b 70 04             	mov    0x4(%eax),%esi
f010575f:	85 f6                	test   %esi,%esi
f0105761:	74 06                	je     f0105769 <mp_init+0x9d>
f0105763:	80 78 0b 00          	cmpb   $0x0,0xb(%eax)
f0105767:	74 15                	je     f010577e <mp_init+0xb2>
		cprintf("SMP: Default configurations not implemented\n");
f0105769:	83 ec 0c             	sub    $0xc,%esp
f010576c:	68 d0 7a 10 f0       	push   $0xf0107ad0
f0105771:	e8 b8 de ff ff       	call   f010362e <cprintf>
f0105776:	83 c4 10             	add    $0x10,%esp
f0105779:	e9 38 02 00 00       	jmp    f01059b6 <mp_init+0x2ea>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010577e:	89 f0                	mov    %esi,%eax
f0105780:	c1 e8 0c             	shr    $0xc,%eax
f0105783:	3b 05 88 1e 21 f0    	cmp    0xf0211e88,%eax
f0105789:	72 15                	jb     f01057a0 <mp_init+0xd4>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010578b:	56                   	push   %esi
f010578c:	68 84 60 10 f0       	push   $0xf0106084
f0105791:	68 90 00 00 00       	push   $0x90
f0105796:	68 5d 7c 10 f0       	push   $0xf0107c5d
f010579b:	e8 a0 a8 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f01057a0:	8d 9e 00 00 00 f0    	lea    -0x10000000(%esi),%ebx
		return NULL;
	}
	conf = (struct mpconf *) KADDR(mp->physaddr);
	if (memcmp(conf, "PCMP", 4) != 0) {
f01057a6:	83 ec 04             	sub    $0x4,%esp
f01057a9:	6a 04                	push   $0x4
f01057ab:	68 72 7c 10 f0       	push   $0xf0107c72
f01057b0:	53                   	push   %ebx
f01057b1:	e8 c5 fc ff ff       	call   f010547b <memcmp>
f01057b6:	83 c4 10             	add    $0x10,%esp
f01057b9:	85 c0                	test   %eax,%eax
f01057bb:	74 15                	je     f01057d2 <mp_init+0x106>
		cprintf("SMP: Incorrect MP configuration table signature\n");
f01057bd:	83 ec 0c             	sub    $0xc,%esp
f01057c0:	68 00 7b 10 f0       	push   $0xf0107b00
f01057c5:	e8 64 de ff ff       	call   f010362e <cprintf>
f01057ca:	83 c4 10             	add    $0x10,%esp
f01057cd:	e9 e4 01 00 00       	jmp    f01059b6 <mp_init+0x2ea>
		return NULL;
	}
	if (sum(conf, conf->length) != 0) {
f01057d2:	0f b7 43 04          	movzwl 0x4(%ebx),%eax
f01057d6:	66 89 45 e2          	mov    %ax,-0x1e(%ebp)
f01057da:	0f b7 f8             	movzwl %ax,%edi
static uint8_t
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
f01057dd:	ba 00 00 00 00       	mov    $0x0,%edx
	for (i = 0; i < len; i++)
f01057e2:	b8 00 00 00 00       	mov    $0x0,%eax
f01057e7:	eb 0d                	jmp    f01057f6 <mp_init+0x12a>
		sum += ((uint8_t *)addr)[i];
f01057e9:	0f b6 8c 30 00 00 00 	movzbl -0x10000000(%eax,%esi,1),%ecx
f01057f0:	f0 
f01057f1:	01 ca                	add    %ecx,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f01057f3:	83 c0 01             	add    $0x1,%eax
f01057f6:	39 c7                	cmp    %eax,%edi
f01057f8:	75 ef                	jne    f01057e9 <mp_init+0x11d>
	conf = (struct mpconf *) KADDR(mp->physaddr);
	if (memcmp(conf, "PCMP", 4) != 0) {
		cprintf("SMP: Incorrect MP configuration table signature\n");
		return NULL;
	}
	if (sum(conf, conf->length) != 0) {
f01057fa:	84 d2                	test   %dl,%dl
f01057fc:	74 15                	je     f0105813 <mp_init+0x147>
		cprintf("SMP: Bad MP configuration checksum\n");
f01057fe:	83 ec 0c             	sub    $0xc,%esp
f0105801:	68 34 7b 10 f0       	push   $0xf0107b34
f0105806:	e8 23 de ff ff       	call   f010362e <cprintf>
f010580b:	83 c4 10             	add    $0x10,%esp
f010580e:	e9 a3 01 00 00       	jmp    f01059b6 <mp_init+0x2ea>
		return NULL;
	}
	if (conf->version != 1 && conf->version != 4) {
f0105813:	0f b6 43 06          	movzbl 0x6(%ebx),%eax
f0105817:	3c 01                	cmp    $0x1,%al
f0105819:	74 1d                	je     f0105838 <mp_init+0x16c>
f010581b:	3c 04                	cmp    $0x4,%al
f010581d:	74 19                	je     f0105838 <mp_init+0x16c>
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
f010581f:	83 ec 08             	sub    $0x8,%esp
f0105822:	0f b6 c0             	movzbl %al,%eax
f0105825:	50                   	push   %eax
f0105826:	68 58 7b 10 f0       	push   $0xf0107b58
f010582b:	e8 fe dd ff ff       	call   f010362e <cprintf>
f0105830:	83 c4 10             	add    $0x10,%esp
f0105833:	e9 7e 01 00 00       	jmp    f01059b6 <mp_init+0x2ea>
		return NULL;
	}
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f0105838:	0f b7 7b 28          	movzwl 0x28(%ebx),%edi
f010583c:	0f b7 4d e2          	movzwl -0x1e(%ebp),%ecx
static uint8_t
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
f0105840:	ba 00 00 00 00       	mov    $0x0,%edx
	for (i = 0; i < len; i++)
f0105845:	b8 00 00 00 00       	mov    $0x0,%eax
		sum += ((uint8_t *)addr)[i];
f010584a:	01 ce                	add    %ecx,%esi
f010584c:	eb 0d                	jmp    f010585b <mp_init+0x18f>
f010584e:	0f b6 8c 06 00 00 00 	movzbl -0x10000000(%esi,%eax,1),%ecx
f0105855:	f0 
f0105856:	01 ca                	add    %ecx,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f0105858:	83 c0 01             	add    $0x1,%eax
f010585b:	39 c7                	cmp    %eax,%edi
f010585d:	75 ef                	jne    f010584e <mp_init+0x182>
	}
	if (conf->version != 1 && conf->version != 4) {
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
		return NULL;
	}
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f010585f:	89 d0                	mov    %edx,%eax
f0105861:	02 43 2a             	add    0x2a(%ebx),%al
f0105864:	74 15                	je     f010587b <mp_init+0x1af>
		cprintf("SMP: Bad MP configuration extended checksum\n");
f0105866:	83 ec 0c             	sub    $0xc,%esp
f0105869:	68 78 7b 10 f0       	push   $0xf0107b78
f010586e:	e8 bb dd ff ff       	call   f010362e <cprintf>
f0105873:	83 c4 10             	add    $0x10,%esp
f0105876:	e9 3b 01 00 00       	jmp    f01059b6 <mp_init+0x2ea>
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
	if ((conf = mpconfig(&mp)) == 0)
f010587b:	85 db                	test   %ebx,%ebx
f010587d:	0f 84 33 01 00 00    	je     f01059b6 <mp_init+0x2ea>
		return;
	ismp = 1;
f0105883:	c7 05 00 20 21 f0 01 	movl   $0x1,0xf0212000
f010588a:	00 00 00 
	lapicaddr = conf->lapicaddr;
f010588d:	8b 43 24             	mov    0x24(%ebx),%eax
f0105890:	a3 00 30 25 f0       	mov    %eax,0xf0253000

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f0105895:	8d 7b 2c             	lea    0x2c(%ebx),%edi
f0105898:	be 00 00 00 00       	mov    $0x0,%esi
f010589d:	e9 85 00 00 00       	jmp    f0105927 <mp_init+0x25b>
		switch (*p) {
f01058a2:	0f b6 07             	movzbl (%edi),%eax
f01058a5:	84 c0                	test   %al,%al
f01058a7:	74 06                	je     f01058af <mp_init+0x1e3>
f01058a9:	3c 04                	cmp    $0x4,%al
f01058ab:	77 55                	ja     f0105902 <mp_init+0x236>
f01058ad:	eb 4e                	jmp    f01058fd <mp_init+0x231>
		case MPPROC:
			proc = (struct mpproc *)p;
			if (proc->flags & MPPROC_BOOT)
f01058af:	f6 47 03 02          	testb  $0x2,0x3(%edi)
f01058b3:	74 11                	je     f01058c6 <mp_init+0x1fa>
				bootcpu = &cpus[ncpu];
f01058b5:	6b 05 c4 23 21 f0 74 	imul   $0x74,0xf02123c4,%eax
f01058bc:	05 20 20 21 f0       	add    $0xf0212020,%eax
f01058c1:	a3 c0 23 21 f0       	mov    %eax,0xf02123c0
			if (ncpu < NCPU) {
f01058c6:	a1 c4 23 21 f0       	mov    0xf02123c4,%eax
f01058cb:	83 f8 07             	cmp    $0x7,%eax
f01058ce:	7f 13                	jg     f01058e3 <mp_init+0x217>
				cpus[ncpu].cpu_id = ncpu;
f01058d0:	6b d0 74             	imul   $0x74,%eax,%edx
f01058d3:	88 82 20 20 21 f0    	mov    %al,-0xfdedfe0(%edx)
				ncpu++;
f01058d9:	83 c0 01             	add    $0x1,%eax
f01058dc:	a3 c4 23 21 f0       	mov    %eax,0xf02123c4
f01058e1:	eb 15                	jmp    f01058f8 <mp_init+0x22c>
			} else {
				cprintf("SMP: too many CPUs, CPU %d disabled\n",
f01058e3:	83 ec 08             	sub    $0x8,%esp
f01058e6:	0f b6 47 01          	movzbl 0x1(%edi),%eax
f01058ea:	50                   	push   %eax
f01058eb:	68 a8 7b 10 f0       	push   $0xf0107ba8
f01058f0:	e8 39 dd ff ff       	call   f010362e <cprintf>
f01058f5:	83 c4 10             	add    $0x10,%esp
					proc->apicid);
			}
			p += sizeof(struct mpproc);
f01058f8:	83 c7 14             	add    $0x14,%edi
			continue;
f01058fb:	eb 27                	jmp    f0105924 <mp_init+0x258>
		case MPBUS:
		case MPIOAPIC:
		case MPIOINTR:
		case MPLINTR:
			p += 8;
f01058fd:	83 c7 08             	add    $0x8,%edi
			continue;
f0105900:	eb 22                	jmp    f0105924 <mp_init+0x258>
		default:
			cprintf("mpinit: unknown config type %x\n", *p);
f0105902:	83 ec 08             	sub    $0x8,%esp
f0105905:	0f b6 c0             	movzbl %al,%eax
f0105908:	50                   	push   %eax
f0105909:	68 d0 7b 10 f0       	push   $0xf0107bd0
f010590e:	e8 1b dd ff ff       	call   f010362e <cprintf>
			ismp = 0;
f0105913:	c7 05 00 20 21 f0 00 	movl   $0x0,0xf0212000
f010591a:	00 00 00 
			i = conf->entry;
f010591d:	0f b7 73 22          	movzwl 0x22(%ebx),%esi
f0105921:	83 c4 10             	add    $0x10,%esp
	if ((conf = mpconfig(&mp)) == 0)
		return;
	ismp = 1;
	lapicaddr = conf->lapicaddr;

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f0105924:	83 c6 01             	add    $0x1,%esi
f0105927:	0f b7 43 22          	movzwl 0x22(%ebx),%eax
f010592b:	39 c6                	cmp    %eax,%esi
f010592d:	0f 82 6f ff ff ff    	jb     f01058a2 <mp_init+0x1d6>
			ismp = 0;
			i = conf->entry;
		}
	}

	bootcpu->cpu_status = CPU_STARTED;
f0105933:	a1 c0 23 21 f0       	mov    0xf02123c0,%eax
f0105938:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
	if (!ismp) {
f010593f:	83 3d 00 20 21 f0 00 	cmpl   $0x0,0xf0212000
f0105946:	75 26                	jne    f010596e <mp_init+0x2a2>
		// Didn't like what we found; fall back to no MP.
		ncpu = 1;
f0105948:	c7 05 c4 23 21 f0 01 	movl   $0x1,0xf02123c4
f010594f:	00 00 00 
		lapicaddr = 0;
f0105952:	c7 05 00 30 25 f0 00 	movl   $0x0,0xf0253000
f0105959:	00 00 00 
		cprintf("SMP: configuration not found, SMP disabled\n");
f010595c:	83 ec 0c             	sub    $0xc,%esp
f010595f:	68 f0 7b 10 f0       	push   $0xf0107bf0
f0105964:	e8 c5 dc ff ff       	call   f010362e <cprintf>
		return;
f0105969:	83 c4 10             	add    $0x10,%esp
f010596c:	eb 48                	jmp    f01059b6 <mp_init+0x2ea>
	}
	cprintf("SMP: CPU %d found %d CPU(s)\n", bootcpu->cpu_id,  ncpu);
f010596e:	83 ec 04             	sub    $0x4,%esp
f0105971:	ff 35 c4 23 21 f0    	pushl  0xf02123c4
f0105977:	0f b6 00             	movzbl (%eax),%eax
f010597a:	50                   	push   %eax
f010597b:	68 77 7c 10 f0       	push   $0xf0107c77
f0105980:	e8 a9 dc ff ff       	call   f010362e <cprintf>

	if (mp->imcrp) {
f0105985:	83 c4 10             	add    $0x10,%esp
f0105988:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010598b:	80 78 0c 00          	cmpb   $0x0,0xc(%eax)
f010598f:	74 25                	je     f01059b6 <mp_init+0x2ea>
		// [MP 3.2.6.1] If the hardware implements PIC mode,
		// switch to getting interrupts from the LAPIC.
		cprintf("SMP: Setting IMCR to switch from PIC mode to symmetric I/O mode\n");
f0105991:	83 ec 0c             	sub    $0xc,%esp
f0105994:	68 1c 7c 10 f0       	push   $0xf0107c1c
f0105999:	e8 90 dc ff ff       	call   f010362e <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010599e:	ba 22 00 00 00       	mov    $0x22,%edx
f01059a3:	b8 70 00 00 00       	mov    $0x70,%eax
f01059a8:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01059a9:	ba 23 00 00 00       	mov    $0x23,%edx
f01059ae:	ec                   	in     (%dx),%al
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01059af:	83 c8 01             	or     $0x1,%eax
f01059b2:	ee                   	out    %al,(%dx)
f01059b3:	83 c4 10             	add    $0x10,%esp
		outb(0x22, 0x70);   // Select IMCR
		outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
	}
}
f01059b6:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01059b9:	5b                   	pop    %ebx
f01059ba:	5e                   	pop    %esi
f01059bb:	5f                   	pop    %edi
f01059bc:	5d                   	pop    %ebp
f01059bd:	c3                   	ret    

f01059be <lapicw>:
physaddr_t lapicaddr;        // Initialized in mpconfig.c
volatile uint32_t *lapic;

static void
lapicw(int index, int value)
{
f01059be:	55                   	push   %ebp
f01059bf:	89 e5                	mov    %esp,%ebp
	lapic[index] = value;
f01059c1:	8b 0d 04 30 25 f0    	mov    0xf0253004,%ecx
f01059c7:	8d 04 81             	lea    (%ecx,%eax,4),%eax
f01059ca:	89 10                	mov    %edx,(%eax)
	lapic[ID];  // wait for write to finish, by reading
f01059cc:	a1 04 30 25 f0       	mov    0xf0253004,%eax
f01059d1:	8b 40 20             	mov    0x20(%eax),%eax
}
f01059d4:	5d                   	pop    %ebp
f01059d5:	c3                   	ret    

f01059d6 <cpunum>:
	lapicw(TPR, 0);
}

int
cpunum(void)
{
f01059d6:	55                   	push   %ebp
f01059d7:	89 e5                	mov    %esp,%ebp
	if (lapic)
f01059d9:	a1 04 30 25 f0       	mov    0xf0253004,%eax
f01059de:	85 c0                	test   %eax,%eax
f01059e0:	74 08                	je     f01059ea <cpunum+0x14>
		return lapic[ID] >> 24;
f01059e2:	8b 40 20             	mov    0x20(%eax),%eax
f01059e5:	c1 e8 18             	shr    $0x18,%eax
f01059e8:	eb 05                	jmp    f01059ef <cpunum+0x19>
	return 0;
f01059ea:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01059ef:	5d                   	pop    %ebp
f01059f0:	c3                   	ret    

f01059f1 <lapic_init>:
}

void
lapic_init(void)
{
	if (!lapicaddr)
f01059f1:	a1 00 30 25 f0       	mov    0xf0253000,%eax
f01059f6:	85 c0                	test   %eax,%eax
f01059f8:	0f 84 21 01 00 00    	je     f0105b1f <lapic_init+0x12e>
	lapic[ID];  // wait for write to finish, by reading
}

void
lapic_init(void)
{
f01059fe:	55                   	push   %ebp
f01059ff:	89 e5                	mov    %esp,%ebp
f0105a01:	83 ec 10             	sub    $0x10,%esp
	if (!lapicaddr)
		return;

	// lapicaddr is the physical address of the LAPIC's 4K MMIO
	// region.  Map it in to virtual memory so we can access it.
	lapic = mmio_map_region(lapicaddr, 4096);
f0105a04:	68 00 10 00 00       	push   $0x1000
f0105a09:	50                   	push   %eax
f0105a0a:	e8 aa b8 ff ff       	call   f01012b9 <mmio_map_region>
f0105a0f:	a3 04 30 25 f0       	mov    %eax,0xf0253004

	// Enable local APIC; set spurious interrupt vector.
	lapicw(SVR, ENABLE | (IRQ_OFFSET + IRQ_SPURIOUS));
f0105a14:	ba 27 01 00 00       	mov    $0x127,%edx
f0105a19:	b8 3c 00 00 00       	mov    $0x3c,%eax
f0105a1e:	e8 9b ff ff ff       	call   f01059be <lapicw>

	// The timer repeatedly counts down at bus frequency
	// from lapic[TICR] and then issues an interrupt.  
	// If we cared more about precise timekeeping,
	// TICR would be calibrated using an external time source.
	lapicw(TDCR, X1);
f0105a23:	ba 0b 00 00 00       	mov    $0xb,%edx
f0105a28:	b8 f8 00 00 00       	mov    $0xf8,%eax
f0105a2d:	e8 8c ff ff ff       	call   f01059be <lapicw>
	lapicw(TIMER, PERIODIC | (IRQ_OFFSET + IRQ_TIMER));
f0105a32:	ba 20 00 02 00       	mov    $0x20020,%edx
f0105a37:	b8 c8 00 00 00       	mov    $0xc8,%eax
f0105a3c:	e8 7d ff ff ff       	call   f01059be <lapicw>
	lapicw(TICR, 10000000); 
f0105a41:	ba 80 96 98 00       	mov    $0x989680,%edx
f0105a46:	b8 e0 00 00 00       	mov    $0xe0,%eax
f0105a4b:	e8 6e ff ff ff       	call   f01059be <lapicw>
	//
	// According to Intel MP Specification, the BIOS should initialize
	// BSP's local APIC in Virtual Wire Mode, in which 8259A's
	// INTR is virtually connected to BSP's LINTIN0. In this mode,
	// we do not need to program the IOAPIC.
	if (thiscpu != bootcpu)
f0105a50:	e8 81 ff ff ff       	call   f01059d6 <cpunum>
f0105a55:	6b c0 74             	imul   $0x74,%eax,%eax
f0105a58:	05 20 20 21 f0       	add    $0xf0212020,%eax
f0105a5d:	83 c4 10             	add    $0x10,%esp
f0105a60:	39 05 c0 23 21 f0    	cmp    %eax,0xf02123c0
f0105a66:	74 0f                	je     f0105a77 <lapic_init+0x86>
		lapicw(LINT0, MASKED);
f0105a68:	ba 00 00 01 00       	mov    $0x10000,%edx
f0105a6d:	b8 d4 00 00 00       	mov    $0xd4,%eax
f0105a72:	e8 47 ff ff ff       	call   f01059be <lapicw>

	// Disable NMI (LINT1) on all CPUs
	lapicw(LINT1, MASKED);
f0105a77:	ba 00 00 01 00       	mov    $0x10000,%edx
f0105a7c:	b8 d8 00 00 00       	mov    $0xd8,%eax
f0105a81:	e8 38 ff ff ff       	call   f01059be <lapicw>

	// Disable performance counter overflow interrupts
	// on machines that provide that interrupt entry.
	if (((lapic[VER]>>16) & 0xFF) >= 4)
f0105a86:	a1 04 30 25 f0       	mov    0xf0253004,%eax
f0105a8b:	8b 40 30             	mov    0x30(%eax),%eax
f0105a8e:	c1 e8 10             	shr    $0x10,%eax
f0105a91:	3c 03                	cmp    $0x3,%al
f0105a93:	76 0f                	jbe    f0105aa4 <lapic_init+0xb3>
		lapicw(PCINT, MASKED);
f0105a95:	ba 00 00 01 00       	mov    $0x10000,%edx
f0105a9a:	b8 d0 00 00 00       	mov    $0xd0,%eax
f0105a9f:	e8 1a ff ff ff       	call   f01059be <lapicw>

	// Map error interrupt to IRQ_ERROR.
	lapicw(ERROR, IRQ_OFFSET + IRQ_ERROR);
f0105aa4:	ba 33 00 00 00       	mov    $0x33,%edx
f0105aa9:	b8 dc 00 00 00       	mov    $0xdc,%eax
f0105aae:	e8 0b ff ff ff       	call   f01059be <lapicw>

	// Clear error status register (requires back-to-back writes).
	lapicw(ESR, 0);
f0105ab3:	ba 00 00 00 00       	mov    $0x0,%edx
f0105ab8:	b8 a0 00 00 00       	mov    $0xa0,%eax
f0105abd:	e8 fc fe ff ff       	call   f01059be <lapicw>
	lapicw(ESR, 0);
f0105ac2:	ba 00 00 00 00       	mov    $0x0,%edx
f0105ac7:	b8 a0 00 00 00       	mov    $0xa0,%eax
f0105acc:	e8 ed fe ff ff       	call   f01059be <lapicw>

	// Ack any outstanding interrupts.
	lapicw(EOI, 0);
f0105ad1:	ba 00 00 00 00       	mov    $0x0,%edx
f0105ad6:	b8 2c 00 00 00       	mov    $0x2c,%eax
f0105adb:	e8 de fe ff ff       	call   f01059be <lapicw>

	// Send an Init Level De-Assert to synchronize arbitration ID's.
	lapicw(ICRHI, 0);
f0105ae0:	ba 00 00 00 00       	mov    $0x0,%edx
f0105ae5:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105aea:	e8 cf fe ff ff       	call   f01059be <lapicw>
	lapicw(ICRLO, BCAST | INIT | LEVEL);
f0105aef:	ba 00 85 08 00       	mov    $0x88500,%edx
f0105af4:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105af9:	e8 c0 fe ff ff       	call   f01059be <lapicw>
	while(lapic[ICRLO] & DELIVS)
f0105afe:	8b 15 04 30 25 f0    	mov    0xf0253004,%edx
f0105b04:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f0105b0a:	f6 c4 10             	test   $0x10,%ah
f0105b0d:	75 f5                	jne    f0105b04 <lapic_init+0x113>
		;

	// Enable interrupts on the APIC (but not on the processor).
	lapicw(TPR, 0);
f0105b0f:	ba 00 00 00 00       	mov    $0x0,%edx
f0105b14:	b8 20 00 00 00       	mov    $0x20,%eax
f0105b19:	e8 a0 fe ff ff       	call   f01059be <lapicw>
}
f0105b1e:	c9                   	leave  
f0105b1f:	f3 c3                	repz ret 

f0105b21 <lapic_eoi>:

// Acknowledge interrupt.
void
lapic_eoi(void)
{
	if (lapic)
f0105b21:	83 3d 04 30 25 f0 00 	cmpl   $0x0,0xf0253004
f0105b28:	74 13                	je     f0105b3d <lapic_eoi+0x1c>
}

// Acknowledge interrupt.
void
lapic_eoi(void)
{
f0105b2a:	55                   	push   %ebp
f0105b2b:	89 e5                	mov    %esp,%ebp
	if (lapic)
		lapicw(EOI, 0);
f0105b2d:	ba 00 00 00 00       	mov    $0x0,%edx
f0105b32:	b8 2c 00 00 00       	mov    $0x2c,%eax
f0105b37:	e8 82 fe ff ff       	call   f01059be <lapicw>
}
f0105b3c:	5d                   	pop    %ebp
f0105b3d:	f3 c3                	repz ret 

f0105b3f <lapic_startap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapic_startap(uint8_t apicid, uint32_t addr)
{
f0105b3f:	55                   	push   %ebp
f0105b40:	89 e5                	mov    %esp,%ebp
f0105b42:	56                   	push   %esi
f0105b43:	53                   	push   %ebx
f0105b44:	8b 75 08             	mov    0x8(%ebp),%esi
f0105b47:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0105b4a:	ba 70 00 00 00       	mov    $0x70,%edx
f0105b4f:	b8 0f 00 00 00       	mov    $0xf,%eax
f0105b54:	ee                   	out    %al,(%dx)
f0105b55:	ba 71 00 00 00       	mov    $0x71,%edx
f0105b5a:	b8 0a 00 00 00       	mov    $0xa,%eax
f0105b5f:	ee                   	out    %al,(%dx)
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0105b60:	83 3d 88 1e 21 f0 00 	cmpl   $0x0,0xf0211e88
f0105b67:	75 19                	jne    f0105b82 <lapic_startap+0x43>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0105b69:	68 67 04 00 00       	push   $0x467
f0105b6e:	68 84 60 10 f0       	push   $0xf0106084
f0105b73:	68 98 00 00 00       	push   $0x98
f0105b78:	68 94 7c 10 f0       	push   $0xf0107c94
f0105b7d:	e8 be a4 ff ff       	call   f0100040 <_panic>
	// and the warm reset vector (DWORD based at 40:67) to point at
	// the AP startup code prior to the [universal startup algorithm]."
	outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
	outb(IO_RTC+1, 0x0A);
	wrv = (uint16_t *)KADDR((0x40 << 4 | 0x67));  // Warm reset vector
	wrv[0] = 0;
f0105b82:	66 c7 05 67 04 00 f0 	movw   $0x0,0xf0000467
f0105b89:	00 00 
	wrv[1] = addr >> 4;
f0105b8b:	89 d8                	mov    %ebx,%eax
f0105b8d:	c1 e8 04             	shr    $0x4,%eax
f0105b90:	66 a3 69 04 00 f0    	mov    %ax,0xf0000469

	// "Universal startup algorithm."
	// Send INIT (level-triggered) interrupt to reset other CPU.
	lapicw(ICRHI, apicid << 24);
f0105b96:	c1 e6 18             	shl    $0x18,%esi
f0105b99:	89 f2                	mov    %esi,%edx
f0105b9b:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105ba0:	e8 19 fe ff ff       	call   f01059be <lapicw>
	lapicw(ICRLO, INIT | LEVEL | ASSERT);
f0105ba5:	ba 00 c5 00 00       	mov    $0xc500,%edx
f0105baa:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105baf:	e8 0a fe ff ff       	call   f01059be <lapicw>
	microdelay(200);
	lapicw(ICRLO, INIT | LEVEL);
f0105bb4:	ba 00 85 00 00       	mov    $0x8500,%edx
f0105bb9:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105bbe:	e8 fb fd ff ff       	call   f01059be <lapicw>
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0105bc3:	c1 eb 0c             	shr    $0xc,%ebx
f0105bc6:	80 cf 06             	or     $0x6,%bh
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
f0105bc9:	89 f2                	mov    %esi,%edx
f0105bcb:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105bd0:	e8 e9 fd ff ff       	call   f01059be <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0105bd5:	89 da                	mov    %ebx,%edx
f0105bd7:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105bdc:	e8 dd fd ff ff       	call   f01059be <lapicw>
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
f0105be1:	89 f2                	mov    %esi,%edx
f0105be3:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105be8:	e8 d1 fd ff ff       	call   f01059be <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0105bed:	89 da                	mov    %ebx,%edx
f0105bef:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105bf4:	e8 c5 fd ff ff       	call   f01059be <lapicw>
		microdelay(200);
	}
}
f0105bf9:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0105bfc:	5b                   	pop    %ebx
f0105bfd:	5e                   	pop    %esi
f0105bfe:	5d                   	pop    %ebp
f0105bff:	c3                   	ret    

f0105c00 <lapic_ipi>:

void
lapic_ipi(int vector)
{
f0105c00:	55                   	push   %ebp
f0105c01:	89 e5                	mov    %esp,%ebp
	lapicw(ICRLO, OTHERS | FIXED | vector);
f0105c03:	8b 55 08             	mov    0x8(%ebp),%edx
f0105c06:	81 ca 00 00 0c 00    	or     $0xc0000,%edx
f0105c0c:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105c11:	e8 a8 fd ff ff       	call   f01059be <lapicw>
	while (lapic[ICRLO] & DELIVS)
f0105c16:	8b 15 04 30 25 f0    	mov    0xf0253004,%edx
f0105c1c:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f0105c22:	f6 c4 10             	test   $0x10,%ah
f0105c25:	75 f5                	jne    f0105c1c <lapic_ipi+0x1c>
		;
}
f0105c27:	5d                   	pop    %ebp
f0105c28:	c3                   	ret    

f0105c29 <__spin_initlock>:
}
#endif

void
__spin_initlock(struct spinlock *lk, char *name)
{
f0105c29:	55                   	push   %ebp
f0105c2a:	89 e5                	mov    %esp,%ebp
f0105c2c:	8b 45 08             	mov    0x8(%ebp),%eax
	lk->locked = 0;
f0105c2f:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
#ifdef DEBUG_SPINLOCK
	lk->name = name;
f0105c35:	8b 55 0c             	mov    0xc(%ebp),%edx
f0105c38:	89 50 04             	mov    %edx,0x4(%eax)
	lk->cpu = 0;
f0105c3b:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
#endif
}
f0105c42:	5d                   	pop    %ebp
f0105c43:	c3                   	ret    

f0105c44 <spin_lock>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
spin_lock(struct spinlock *lk)
{
f0105c44:	55                   	push   %ebp
f0105c45:	89 e5                	mov    %esp,%ebp
f0105c47:	56                   	push   %esi
f0105c48:	53                   	push   %ebx
f0105c49:	8b 5d 08             	mov    0x8(%ebp),%ebx

// Check whether this CPU is holding the lock.
static int
holding(struct spinlock *lock)
{
	return lock->locked && lock->cpu == thiscpu;
f0105c4c:	83 3b 00             	cmpl   $0x0,(%ebx)
f0105c4f:	74 14                	je     f0105c65 <spin_lock+0x21>
f0105c51:	8b 73 08             	mov    0x8(%ebx),%esi
f0105c54:	e8 7d fd ff ff       	call   f01059d6 <cpunum>
f0105c59:	6b c0 74             	imul   $0x74,%eax,%eax
f0105c5c:	05 20 20 21 f0       	add    $0xf0212020,%eax
// other CPUs to waste time spinning to acquire it.
void
spin_lock(struct spinlock *lk)
{
#ifdef DEBUG_SPINLOCK
	if (holding(lk))
f0105c61:	39 c6                	cmp    %eax,%esi
f0105c63:	74 07                	je     f0105c6c <spin_lock+0x28>
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"
f0105c65:	ba 01 00 00 00       	mov    $0x1,%edx
f0105c6a:	eb 20                	jmp    f0105c8c <spin_lock+0x48>
		panic("CPU %d cannot acquire %s: already holding", cpunum(), lk->name);
f0105c6c:	8b 5b 04             	mov    0x4(%ebx),%ebx
f0105c6f:	e8 62 fd ff ff       	call   f01059d6 <cpunum>
f0105c74:	83 ec 0c             	sub    $0xc,%esp
f0105c77:	53                   	push   %ebx
f0105c78:	50                   	push   %eax
f0105c79:	68 a4 7c 10 f0       	push   $0xf0107ca4
f0105c7e:	6a 41                	push   $0x41
f0105c80:	68 08 7d 10 f0       	push   $0xf0107d08
f0105c85:	e8 b6 a3 ff ff       	call   f0100040 <_panic>

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
		asm volatile ("pause");
f0105c8a:	f3 90                	pause  
f0105c8c:	89 d0                	mov    %edx,%eax
f0105c8e:	f0 87 03             	lock xchg %eax,(%ebx)
#endif

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
f0105c91:	85 c0                	test   %eax,%eax
f0105c93:	75 f5                	jne    f0105c8a <spin_lock+0x46>
		asm volatile ("pause");

	// Record info about lock acquisition for debugging.
#ifdef DEBUG_SPINLOCK
	lk->cpu = thiscpu;
f0105c95:	e8 3c fd ff ff       	call   f01059d6 <cpunum>
f0105c9a:	6b c0 74             	imul   $0x74,%eax,%eax
f0105c9d:	05 20 20 21 f0       	add    $0xf0212020,%eax
f0105ca2:	89 43 08             	mov    %eax,0x8(%ebx)
	get_caller_pcs(lk->pcs);
f0105ca5:	83 c3 0c             	add    $0xc,%ebx

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f0105ca8:	89 ea                	mov    %ebp,%edx
{
	uint32_t *ebp;
	int i;

	ebp = (uint32_t *)read_ebp();
	for (i = 0; i < 10; i++){
f0105caa:	b8 00 00 00 00       	mov    $0x0,%eax
f0105caf:	eb 0b                	jmp    f0105cbc <spin_lock+0x78>
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
			break;
		pcs[i] = ebp[1];          // saved %eip
f0105cb1:	8b 4a 04             	mov    0x4(%edx),%ecx
f0105cb4:	89 0c 83             	mov    %ecx,(%ebx,%eax,4)
		ebp = (uint32_t *)ebp[0]; // saved %ebp
f0105cb7:	8b 12                	mov    (%edx),%edx
{
	uint32_t *ebp;
	int i;

	ebp = (uint32_t *)read_ebp();
	for (i = 0; i < 10; i++){
f0105cb9:	83 c0 01             	add    $0x1,%eax
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
f0105cbc:	81 fa ff ff 7f ef    	cmp    $0xef7fffff,%edx
f0105cc2:	76 11                	jbe    f0105cd5 <spin_lock+0x91>
f0105cc4:	83 f8 09             	cmp    $0x9,%eax
f0105cc7:	7e e8                	jle    f0105cb1 <spin_lock+0x6d>
f0105cc9:	eb 0a                	jmp    f0105cd5 <spin_lock+0x91>
			break;
		pcs[i] = ebp[1];          // saved %eip
		ebp = (uint32_t *)ebp[0]; // saved %ebp
	}
	for (; i < 10; i++)
		pcs[i] = 0;
f0105ccb:	c7 04 83 00 00 00 00 	movl   $0x0,(%ebx,%eax,4)
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
			break;
		pcs[i] = ebp[1];          // saved %eip
		ebp = (uint32_t *)ebp[0]; // saved %ebp
	}
	for (; i < 10; i++)
f0105cd2:	83 c0 01             	add    $0x1,%eax
f0105cd5:	83 f8 09             	cmp    $0x9,%eax
f0105cd8:	7e f1                	jle    f0105ccb <spin_lock+0x87>
	// Record info about lock acquisition for debugging.
#ifdef DEBUG_SPINLOCK
	lk->cpu = thiscpu;
	get_caller_pcs(lk->pcs);
#endif
}
f0105cda:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0105cdd:	5b                   	pop    %ebx
f0105cde:	5e                   	pop    %esi
f0105cdf:	5d                   	pop    %ebp
f0105ce0:	c3                   	ret    

f0105ce1 <spin_unlock>:

// Release the lock.
void
spin_unlock(struct spinlock *lk)
{
f0105ce1:	55                   	push   %ebp
f0105ce2:	89 e5                	mov    %esp,%ebp
f0105ce4:	57                   	push   %edi
f0105ce5:	56                   	push   %esi
f0105ce6:	53                   	push   %ebx
f0105ce7:	83 ec 4c             	sub    $0x4c,%esp
f0105cea:	8b 75 08             	mov    0x8(%ebp),%esi

// Check whether this CPU is holding the lock.
static int
holding(struct spinlock *lock)
{
	return lock->locked && lock->cpu == thiscpu;
f0105ced:	83 3e 00             	cmpl   $0x0,(%esi)
f0105cf0:	74 18                	je     f0105d0a <spin_unlock+0x29>
f0105cf2:	8b 5e 08             	mov    0x8(%esi),%ebx
f0105cf5:	e8 dc fc ff ff       	call   f01059d6 <cpunum>
f0105cfa:	6b c0 74             	imul   $0x74,%eax,%eax
f0105cfd:	05 20 20 21 f0       	add    $0xf0212020,%eax
// Release the lock.
void
spin_unlock(struct spinlock *lk)
{
#ifdef DEBUG_SPINLOCK
	if (!holding(lk)) {
f0105d02:	39 c3                	cmp    %eax,%ebx
f0105d04:	0f 84 a5 00 00 00    	je     f0105daf <spin_unlock+0xce>
		int i;
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
f0105d0a:	83 ec 04             	sub    $0x4,%esp
f0105d0d:	6a 28                	push   $0x28
f0105d0f:	8d 46 0c             	lea    0xc(%esi),%eax
f0105d12:	50                   	push   %eax
f0105d13:	8d 5d c0             	lea    -0x40(%ebp),%ebx
f0105d16:	53                   	push   %ebx
f0105d17:	e8 e4 f6 ff ff       	call   f0105400 <memmove>
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
f0105d1c:	8b 46 08             	mov    0x8(%esi),%eax
	if (!holding(lk)) {
		int i;
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
f0105d1f:	0f b6 38             	movzbl (%eax),%edi
f0105d22:	8b 76 04             	mov    0x4(%esi),%esi
f0105d25:	e8 ac fc ff ff       	call   f01059d6 <cpunum>
f0105d2a:	57                   	push   %edi
f0105d2b:	56                   	push   %esi
f0105d2c:	50                   	push   %eax
f0105d2d:	68 d0 7c 10 f0       	push   $0xf0107cd0
f0105d32:	e8 f7 d8 ff ff       	call   f010362e <cprintf>
f0105d37:	83 c4 20             	add    $0x20,%esp
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
			struct Eipdebuginfo info;
			if (debuginfo_eip(pcs[i], &info) >= 0)
f0105d3a:	8d 7d a8             	lea    -0x58(%ebp),%edi
f0105d3d:	eb 54                	jmp    f0105d93 <spin_unlock+0xb2>
f0105d3f:	83 ec 08             	sub    $0x8,%esp
f0105d42:	57                   	push   %edi
f0105d43:	50                   	push   %eax
f0105d44:	e8 a2 eb ff ff       	call   f01048eb <debuginfo_eip>
f0105d49:	83 c4 10             	add    $0x10,%esp
f0105d4c:	85 c0                	test   %eax,%eax
f0105d4e:	78 27                	js     f0105d77 <spin_unlock+0x96>
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
					info.eip_file, info.eip_line,
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
f0105d50:	8b 06                	mov    (%esi),%eax
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
			struct Eipdebuginfo info;
			if (debuginfo_eip(pcs[i], &info) >= 0)
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
f0105d52:	83 ec 04             	sub    $0x4,%esp
f0105d55:	89 c2                	mov    %eax,%edx
f0105d57:	2b 55 b8             	sub    -0x48(%ebp),%edx
f0105d5a:	52                   	push   %edx
f0105d5b:	ff 75 b0             	pushl  -0x50(%ebp)
f0105d5e:	ff 75 b4             	pushl  -0x4c(%ebp)
f0105d61:	ff 75 ac             	pushl  -0x54(%ebp)
f0105d64:	ff 75 a8             	pushl  -0x58(%ebp)
f0105d67:	50                   	push   %eax
f0105d68:	68 18 7d 10 f0       	push   $0xf0107d18
f0105d6d:	e8 bc d8 ff ff       	call   f010362e <cprintf>
f0105d72:	83 c4 20             	add    $0x20,%esp
f0105d75:	eb 12                	jmp    f0105d89 <spin_unlock+0xa8>
					info.eip_file, info.eip_line,
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
			else
				cprintf("  %08x\n", pcs[i]);
f0105d77:	83 ec 08             	sub    $0x8,%esp
f0105d7a:	ff 36                	pushl  (%esi)
f0105d7c:	68 2f 7d 10 f0       	push   $0xf0107d2f
f0105d81:	e8 a8 d8 ff ff       	call   f010362e <cprintf>
f0105d86:	83 c4 10             	add    $0x10,%esp
f0105d89:	83 c3 04             	add    $0x4,%ebx
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
f0105d8c:	8d 45 e8             	lea    -0x18(%ebp),%eax
f0105d8f:	39 c3                	cmp    %eax,%ebx
f0105d91:	74 08                	je     f0105d9b <spin_unlock+0xba>
f0105d93:	89 de                	mov    %ebx,%esi
f0105d95:	8b 03                	mov    (%ebx),%eax
f0105d97:	85 c0                	test   %eax,%eax
f0105d99:	75 a4                	jne    f0105d3f <spin_unlock+0x5e>
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
			else
				cprintf("  %08x\n", pcs[i]);
		}
		panic("spin_unlock");
f0105d9b:	83 ec 04             	sub    $0x4,%esp
f0105d9e:	68 37 7d 10 f0       	push   $0xf0107d37
f0105da3:	6a 67                	push   $0x67
f0105da5:	68 08 7d 10 f0       	push   $0xf0107d08
f0105daa:	e8 91 a2 ff ff       	call   f0100040 <_panic>
	}

	lk->pcs[0] = 0;
f0105daf:	c7 46 0c 00 00 00 00 	movl   $0x0,0xc(%esi)
	lk->cpu = 0;
f0105db6:	c7 46 08 00 00 00 00 	movl   $0x0,0x8(%esi)
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"
f0105dbd:	b8 00 00 00 00       	mov    $0x0,%eax
f0105dc2:	f0 87 06             	lock xchg %eax,(%esi)
	// respect to any other instruction which references the same memory.
	// x86 CPUs will not reorder loads/stores across locked instructions
	// (vol 3, 8.2.2). Because xchg() is implemented using asm volatile,
	// gcc will not reorder C statements across the xchg.
	xchg(&lk->locked, 0);
}
f0105dc5:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0105dc8:	5b                   	pop    %ebx
f0105dc9:	5e                   	pop    %esi
f0105dca:	5f                   	pop    %edi
f0105dcb:	5d                   	pop    %ebp
f0105dcc:	c3                   	ret    
f0105dcd:	66 90                	xchg   %ax,%ax
f0105dcf:	90                   	nop

f0105dd0 <__udivdi3>:
f0105dd0:	55                   	push   %ebp
f0105dd1:	57                   	push   %edi
f0105dd2:	56                   	push   %esi
f0105dd3:	53                   	push   %ebx
f0105dd4:	83 ec 1c             	sub    $0x1c,%esp
f0105dd7:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f0105ddb:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f0105ddf:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0105de3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0105de7:	85 f6                	test   %esi,%esi
f0105de9:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0105ded:	89 ca                	mov    %ecx,%edx
f0105def:	89 f8                	mov    %edi,%eax
f0105df1:	75 3d                	jne    f0105e30 <__udivdi3+0x60>
f0105df3:	39 cf                	cmp    %ecx,%edi
f0105df5:	0f 87 c5 00 00 00    	ja     f0105ec0 <__udivdi3+0xf0>
f0105dfb:	85 ff                	test   %edi,%edi
f0105dfd:	89 fd                	mov    %edi,%ebp
f0105dff:	75 0b                	jne    f0105e0c <__udivdi3+0x3c>
f0105e01:	b8 01 00 00 00       	mov    $0x1,%eax
f0105e06:	31 d2                	xor    %edx,%edx
f0105e08:	f7 f7                	div    %edi
f0105e0a:	89 c5                	mov    %eax,%ebp
f0105e0c:	89 c8                	mov    %ecx,%eax
f0105e0e:	31 d2                	xor    %edx,%edx
f0105e10:	f7 f5                	div    %ebp
f0105e12:	89 c1                	mov    %eax,%ecx
f0105e14:	89 d8                	mov    %ebx,%eax
f0105e16:	89 cf                	mov    %ecx,%edi
f0105e18:	f7 f5                	div    %ebp
f0105e1a:	89 c3                	mov    %eax,%ebx
f0105e1c:	89 d8                	mov    %ebx,%eax
f0105e1e:	89 fa                	mov    %edi,%edx
f0105e20:	83 c4 1c             	add    $0x1c,%esp
f0105e23:	5b                   	pop    %ebx
f0105e24:	5e                   	pop    %esi
f0105e25:	5f                   	pop    %edi
f0105e26:	5d                   	pop    %ebp
f0105e27:	c3                   	ret    
f0105e28:	90                   	nop
f0105e29:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0105e30:	39 ce                	cmp    %ecx,%esi
f0105e32:	77 74                	ja     f0105ea8 <__udivdi3+0xd8>
f0105e34:	0f bd fe             	bsr    %esi,%edi
f0105e37:	83 f7 1f             	xor    $0x1f,%edi
f0105e3a:	0f 84 98 00 00 00    	je     f0105ed8 <__udivdi3+0x108>
f0105e40:	bb 20 00 00 00       	mov    $0x20,%ebx
f0105e45:	89 f9                	mov    %edi,%ecx
f0105e47:	89 c5                	mov    %eax,%ebp
f0105e49:	29 fb                	sub    %edi,%ebx
f0105e4b:	d3 e6                	shl    %cl,%esi
f0105e4d:	89 d9                	mov    %ebx,%ecx
f0105e4f:	d3 ed                	shr    %cl,%ebp
f0105e51:	89 f9                	mov    %edi,%ecx
f0105e53:	d3 e0                	shl    %cl,%eax
f0105e55:	09 ee                	or     %ebp,%esi
f0105e57:	89 d9                	mov    %ebx,%ecx
f0105e59:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0105e5d:	89 d5                	mov    %edx,%ebp
f0105e5f:	8b 44 24 08          	mov    0x8(%esp),%eax
f0105e63:	d3 ed                	shr    %cl,%ebp
f0105e65:	89 f9                	mov    %edi,%ecx
f0105e67:	d3 e2                	shl    %cl,%edx
f0105e69:	89 d9                	mov    %ebx,%ecx
f0105e6b:	d3 e8                	shr    %cl,%eax
f0105e6d:	09 c2                	or     %eax,%edx
f0105e6f:	89 d0                	mov    %edx,%eax
f0105e71:	89 ea                	mov    %ebp,%edx
f0105e73:	f7 f6                	div    %esi
f0105e75:	89 d5                	mov    %edx,%ebp
f0105e77:	89 c3                	mov    %eax,%ebx
f0105e79:	f7 64 24 0c          	mull   0xc(%esp)
f0105e7d:	39 d5                	cmp    %edx,%ebp
f0105e7f:	72 10                	jb     f0105e91 <__udivdi3+0xc1>
f0105e81:	8b 74 24 08          	mov    0x8(%esp),%esi
f0105e85:	89 f9                	mov    %edi,%ecx
f0105e87:	d3 e6                	shl    %cl,%esi
f0105e89:	39 c6                	cmp    %eax,%esi
f0105e8b:	73 07                	jae    f0105e94 <__udivdi3+0xc4>
f0105e8d:	39 d5                	cmp    %edx,%ebp
f0105e8f:	75 03                	jne    f0105e94 <__udivdi3+0xc4>
f0105e91:	83 eb 01             	sub    $0x1,%ebx
f0105e94:	31 ff                	xor    %edi,%edi
f0105e96:	89 d8                	mov    %ebx,%eax
f0105e98:	89 fa                	mov    %edi,%edx
f0105e9a:	83 c4 1c             	add    $0x1c,%esp
f0105e9d:	5b                   	pop    %ebx
f0105e9e:	5e                   	pop    %esi
f0105e9f:	5f                   	pop    %edi
f0105ea0:	5d                   	pop    %ebp
f0105ea1:	c3                   	ret    
f0105ea2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0105ea8:	31 ff                	xor    %edi,%edi
f0105eaa:	31 db                	xor    %ebx,%ebx
f0105eac:	89 d8                	mov    %ebx,%eax
f0105eae:	89 fa                	mov    %edi,%edx
f0105eb0:	83 c4 1c             	add    $0x1c,%esp
f0105eb3:	5b                   	pop    %ebx
f0105eb4:	5e                   	pop    %esi
f0105eb5:	5f                   	pop    %edi
f0105eb6:	5d                   	pop    %ebp
f0105eb7:	c3                   	ret    
f0105eb8:	90                   	nop
f0105eb9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0105ec0:	89 d8                	mov    %ebx,%eax
f0105ec2:	f7 f7                	div    %edi
f0105ec4:	31 ff                	xor    %edi,%edi
f0105ec6:	89 c3                	mov    %eax,%ebx
f0105ec8:	89 d8                	mov    %ebx,%eax
f0105eca:	89 fa                	mov    %edi,%edx
f0105ecc:	83 c4 1c             	add    $0x1c,%esp
f0105ecf:	5b                   	pop    %ebx
f0105ed0:	5e                   	pop    %esi
f0105ed1:	5f                   	pop    %edi
f0105ed2:	5d                   	pop    %ebp
f0105ed3:	c3                   	ret    
f0105ed4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0105ed8:	39 ce                	cmp    %ecx,%esi
f0105eda:	72 0c                	jb     f0105ee8 <__udivdi3+0x118>
f0105edc:	31 db                	xor    %ebx,%ebx
f0105ede:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0105ee2:	0f 87 34 ff ff ff    	ja     f0105e1c <__udivdi3+0x4c>
f0105ee8:	bb 01 00 00 00       	mov    $0x1,%ebx
f0105eed:	e9 2a ff ff ff       	jmp    f0105e1c <__udivdi3+0x4c>
f0105ef2:	66 90                	xchg   %ax,%ax
f0105ef4:	66 90                	xchg   %ax,%ax
f0105ef6:	66 90                	xchg   %ax,%ax
f0105ef8:	66 90                	xchg   %ax,%ax
f0105efa:	66 90                	xchg   %ax,%ax
f0105efc:	66 90                	xchg   %ax,%ax
f0105efe:	66 90                	xchg   %ax,%ax

f0105f00 <__umoddi3>:
f0105f00:	55                   	push   %ebp
f0105f01:	57                   	push   %edi
f0105f02:	56                   	push   %esi
f0105f03:	53                   	push   %ebx
f0105f04:	83 ec 1c             	sub    $0x1c,%esp
f0105f07:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f0105f0b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f0105f0f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0105f13:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0105f17:	85 d2                	test   %edx,%edx
f0105f19:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0105f1d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0105f21:	89 f3                	mov    %esi,%ebx
f0105f23:	89 3c 24             	mov    %edi,(%esp)
f0105f26:	89 74 24 04          	mov    %esi,0x4(%esp)
f0105f2a:	75 1c                	jne    f0105f48 <__umoddi3+0x48>
f0105f2c:	39 f7                	cmp    %esi,%edi
f0105f2e:	76 50                	jbe    f0105f80 <__umoddi3+0x80>
f0105f30:	89 c8                	mov    %ecx,%eax
f0105f32:	89 f2                	mov    %esi,%edx
f0105f34:	f7 f7                	div    %edi
f0105f36:	89 d0                	mov    %edx,%eax
f0105f38:	31 d2                	xor    %edx,%edx
f0105f3a:	83 c4 1c             	add    $0x1c,%esp
f0105f3d:	5b                   	pop    %ebx
f0105f3e:	5e                   	pop    %esi
f0105f3f:	5f                   	pop    %edi
f0105f40:	5d                   	pop    %ebp
f0105f41:	c3                   	ret    
f0105f42:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0105f48:	39 f2                	cmp    %esi,%edx
f0105f4a:	89 d0                	mov    %edx,%eax
f0105f4c:	77 52                	ja     f0105fa0 <__umoddi3+0xa0>
f0105f4e:	0f bd ea             	bsr    %edx,%ebp
f0105f51:	83 f5 1f             	xor    $0x1f,%ebp
f0105f54:	75 5a                	jne    f0105fb0 <__umoddi3+0xb0>
f0105f56:	3b 54 24 04          	cmp    0x4(%esp),%edx
f0105f5a:	0f 82 e0 00 00 00    	jb     f0106040 <__umoddi3+0x140>
f0105f60:	39 0c 24             	cmp    %ecx,(%esp)
f0105f63:	0f 86 d7 00 00 00    	jbe    f0106040 <__umoddi3+0x140>
f0105f69:	8b 44 24 08          	mov    0x8(%esp),%eax
f0105f6d:	8b 54 24 04          	mov    0x4(%esp),%edx
f0105f71:	83 c4 1c             	add    $0x1c,%esp
f0105f74:	5b                   	pop    %ebx
f0105f75:	5e                   	pop    %esi
f0105f76:	5f                   	pop    %edi
f0105f77:	5d                   	pop    %ebp
f0105f78:	c3                   	ret    
f0105f79:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0105f80:	85 ff                	test   %edi,%edi
f0105f82:	89 fd                	mov    %edi,%ebp
f0105f84:	75 0b                	jne    f0105f91 <__umoddi3+0x91>
f0105f86:	b8 01 00 00 00       	mov    $0x1,%eax
f0105f8b:	31 d2                	xor    %edx,%edx
f0105f8d:	f7 f7                	div    %edi
f0105f8f:	89 c5                	mov    %eax,%ebp
f0105f91:	89 f0                	mov    %esi,%eax
f0105f93:	31 d2                	xor    %edx,%edx
f0105f95:	f7 f5                	div    %ebp
f0105f97:	89 c8                	mov    %ecx,%eax
f0105f99:	f7 f5                	div    %ebp
f0105f9b:	89 d0                	mov    %edx,%eax
f0105f9d:	eb 99                	jmp    f0105f38 <__umoddi3+0x38>
f0105f9f:	90                   	nop
f0105fa0:	89 c8                	mov    %ecx,%eax
f0105fa2:	89 f2                	mov    %esi,%edx
f0105fa4:	83 c4 1c             	add    $0x1c,%esp
f0105fa7:	5b                   	pop    %ebx
f0105fa8:	5e                   	pop    %esi
f0105fa9:	5f                   	pop    %edi
f0105faa:	5d                   	pop    %ebp
f0105fab:	c3                   	ret    
f0105fac:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0105fb0:	8b 34 24             	mov    (%esp),%esi
f0105fb3:	bf 20 00 00 00       	mov    $0x20,%edi
f0105fb8:	89 e9                	mov    %ebp,%ecx
f0105fba:	29 ef                	sub    %ebp,%edi
f0105fbc:	d3 e0                	shl    %cl,%eax
f0105fbe:	89 f9                	mov    %edi,%ecx
f0105fc0:	89 f2                	mov    %esi,%edx
f0105fc2:	d3 ea                	shr    %cl,%edx
f0105fc4:	89 e9                	mov    %ebp,%ecx
f0105fc6:	09 c2                	or     %eax,%edx
f0105fc8:	89 d8                	mov    %ebx,%eax
f0105fca:	89 14 24             	mov    %edx,(%esp)
f0105fcd:	89 f2                	mov    %esi,%edx
f0105fcf:	d3 e2                	shl    %cl,%edx
f0105fd1:	89 f9                	mov    %edi,%ecx
f0105fd3:	89 54 24 04          	mov    %edx,0x4(%esp)
f0105fd7:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0105fdb:	d3 e8                	shr    %cl,%eax
f0105fdd:	89 e9                	mov    %ebp,%ecx
f0105fdf:	89 c6                	mov    %eax,%esi
f0105fe1:	d3 e3                	shl    %cl,%ebx
f0105fe3:	89 f9                	mov    %edi,%ecx
f0105fe5:	89 d0                	mov    %edx,%eax
f0105fe7:	d3 e8                	shr    %cl,%eax
f0105fe9:	89 e9                	mov    %ebp,%ecx
f0105feb:	09 d8                	or     %ebx,%eax
f0105fed:	89 d3                	mov    %edx,%ebx
f0105fef:	89 f2                	mov    %esi,%edx
f0105ff1:	f7 34 24             	divl   (%esp)
f0105ff4:	89 d6                	mov    %edx,%esi
f0105ff6:	d3 e3                	shl    %cl,%ebx
f0105ff8:	f7 64 24 04          	mull   0x4(%esp)
f0105ffc:	39 d6                	cmp    %edx,%esi
f0105ffe:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0106002:	89 d1                	mov    %edx,%ecx
f0106004:	89 c3                	mov    %eax,%ebx
f0106006:	72 08                	jb     f0106010 <__umoddi3+0x110>
f0106008:	75 11                	jne    f010601b <__umoddi3+0x11b>
f010600a:	39 44 24 08          	cmp    %eax,0x8(%esp)
f010600e:	73 0b                	jae    f010601b <__umoddi3+0x11b>
f0106010:	2b 44 24 04          	sub    0x4(%esp),%eax
f0106014:	1b 14 24             	sbb    (%esp),%edx
f0106017:	89 d1                	mov    %edx,%ecx
f0106019:	89 c3                	mov    %eax,%ebx
f010601b:	8b 54 24 08          	mov    0x8(%esp),%edx
f010601f:	29 da                	sub    %ebx,%edx
f0106021:	19 ce                	sbb    %ecx,%esi
f0106023:	89 f9                	mov    %edi,%ecx
f0106025:	89 f0                	mov    %esi,%eax
f0106027:	d3 e0                	shl    %cl,%eax
f0106029:	89 e9                	mov    %ebp,%ecx
f010602b:	d3 ea                	shr    %cl,%edx
f010602d:	89 e9                	mov    %ebp,%ecx
f010602f:	d3 ee                	shr    %cl,%esi
f0106031:	09 d0                	or     %edx,%eax
f0106033:	89 f2                	mov    %esi,%edx
f0106035:	83 c4 1c             	add    $0x1c,%esp
f0106038:	5b                   	pop    %ebx
f0106039:	5e                   	pop    %esi
f010603a:	5f                   	pop    %edi
f010603b:	5d                   	pop    %ebp
f010603c:	c3                   	ret    
f010603d:	8d 76 00             	lea    0x0(%esi),%esi
f0106040:	29 f9                	sub    %edi,%ecx
f0106042:	19 d6                	sbb    %edx,%esi
f0106044:	89 74 24 04          	mov    %esi,0x4(%esp)
f0106048:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010604c:	e9 18 ff ff ff       	jmp    f0105f69 <__umoddi3+0x69>
