
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
f0100015:	b8 00 50 11 00       	mov    $0x115000,%eax
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
f0100034:	bc 00 50 11 f0       	mov    $0xf0115000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
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
f0100046:	b8 50 79 11 f0       	mov    $0xf0117950,%eax
f010004b:	2d 00 73 11 f0       	sub    $0xf0117300,%eax
f0100050:	50                   	push   %eax
f0100051:	6a 00                	push   $0x0
f0100053:	68 00 73 11 f0       	push   $0xf0117300
f0100058:	e8 a8 31 00 00       	call   f0103205 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 96 04 00 00       	call   f01004f8 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 a0 36 10 f0       	push   $0xf01036a0
f010006f:	e8 e8 26 00 00       	call   f010275c <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 3d 10 00 00       	call   f01010b6 <mem_init>
f0100079:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f010007c:	83 ec 0c             	sub    $0xc,%esp
f010007f:	6a 00                	push   $0x0
f0100081:	e8 52 07 00 00       	call   f01007d8 <monitor>
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
f0100093:	83 3d 40 79 11 f0 00 	cmpl   $0x0,0xf0117940
f010009a:	75 37                	jne    f01000d3 <_panic+0x48>
		goto dead;
	panicstr = fmt;
f010009c:	89 35 40 79 11 f0    	mov    %esi,0xf0117940

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
f01000b0:	68 bb 36 10 f0       	push   $0xf01036bb
f01000b5:	e8 a2 26 00 00       	call   f010275c <cprintf>
	vcprintf(fmt, ap);
f01000ba:	83 c4 08             	add    $0x8,%esp
f01000bd:	53                   	push   %ebx
f01000be:	56                   	push   %esi
f01000bf:	e8 72 26 00 00       	call   f0102736 <vcprintf>
	cprintf("\n");
f01000c4:	c7 04 24 c9 46 10 f0 	movl   $0xf01046c9,(%esp)
f01000cb:	e8 8c 26 00 00       	call   f010275c <cprintf>
	va_end(ap);
f01000d0:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000d3:	83 ec 0c             	sub    $0xc,%esp
f01000d6:	6a 00                	push   $0x0
f01000d8:	e8 fb 06 00 00       	call   f01007d8 <monitor>
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
f01000f2:	68 d3 36 10 f0       	push   $0xf01036d3
f01000f7:	e8 60 26 00 00       	call   f010275c <cprintf>
	vcprintf(fmt, ap);
f01000fc:	83 c4 08             	add    $0x8,%esp
f01000ff:	53                   	push   %ebx
f0100100:	ff 75 10             	pushl  0x10(%ebp)
f0100103:	e8 2e 26 00 00       	call   f0102736 <vcprintf>
	cprintf("\n");
f0100108:	c7 04 24 c9 46 10 f0 	movl   $0xf01046c9,(%esp)
f010010f:	e8 48 26 00 00       	call   f010275c <cprintf>
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
f010014a:	8b 0d 24 75 11 f0    	mov    0xf0117524,%ecx
f0100150:	8d 51 01             	lea    0x1(%ecx),%edx
f0100153:	89 15 24 75 11 f0    	mov    %edx,0xf0117524
f0100159:	88 81 20 73 11 f0    	mov    %al,-0xfee8ce0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f010015f:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100165:	75 0a                	jne    f0100171 <cons_intr+0x36>
			cons.wpos = 0;
f0100167:	c7 05 24 75 11 f0 00 	movl   $0x0,0xf0117524
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
f01001a0:	83 0d 00 73 11 f0 40 	orl    $0x40,0xf0117300
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
f01001b8:	8b 0d 00 73 11 f0    	mov    0xf0117300,%ecx
f01001be:	89 cb                	mov    %ecx,%ebx
f01001c0:	83 e3 40             	and    $0x40,%ebx
f01001c3:	83 e0 7f             	and    $0x7f,%eax
f01001c6:	85 db                	test   %ebx,%ebx
f01001c8:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01001cb:	0f b6 d2             	movzbl %dl,%edx
f01001ce:	0f b6 82 40 38 10 f0 	movzbl -0xfefc7c0(%edx),%eax
f01001d5:	83 c8 40             	or     $0x40,%eax
f01001d8:	0f b6 c0             	movzbl %al,%eax
f01001db:	f7 d0                	not    %eax
f01001dd:	21 c8                	and    %ecx,%eax
f01001df:	a3 00 73 11 f0       	mov    %eax,0xf0117300
		return 0;
f01001e4:	b8 00 00 00 00       	mov    $0x0,%eax
f01001e9:	e9 a4 00 00 00       	jmp    f0100292 <kbd_proc_data+0x114>
	} else if (shift & E0ESC) {
f01001ee:	8b 0d 00 73 11 f0    	mov    0xf0117300,%ecx
f01001f4:	f6 c1 40             	test   $0x40,%cl
f01001f7:	74 0e                	je     f0100207 <kbd_proc_data+0x89>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f01001f9:	83 c8 80             	or     $0xffffff80,%eax
f01001fc:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f01001fe:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100201:	89 0d 00 73 11 f0    	mov    %ecx,0xf0117300
	}

	shift |= shiftcode[data];
f0100207:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f010020a:	0f b6 82 40 38 10 f0 	movzbl -0xfefc7c0(%edx),%eax
f0100211:	0b 05 00 73 11 f0    	or     0xf0117300,%eax
f0100217:	0f b6 8a 40 37 10 f0 	movzbl -0xfefc8c0(%edx),%ecx
f010021e:	31 c8                	xor    %ecx,%eax
f0100220:	a3 00 73 11 f0       	mov    %eax,0xf0117300

	c = charcode[shift & (CTL | SHIFT)][data];
f0100225:	89 c1                	mov    %eax,%ecx
f0100227:	83 e1 03             	and    $0x3,%ecx
f010022a:	8b 0c 8d 20 37 10 f0 	mov    -0xfefc8e0(,%ecx,4),%ecx
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
f0100268:	68 ed 36 10 f0       	push   $0xf01036ed
f010026d:	e8 ea 24 00 00       	call   f010275c <cprintf>
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
f0100354:	0f b7 05 28 75 11 f0 	movzwl 0xf0117528,%eax
f010035b:	66 85 c0             	test   %ax,%ax
f010035e:	0f 84 e6 00 00 00    	je     f010044a <cons_putc+0x1b3>
			crt_pos--;
f0100364:	83 e8 01             	sub    $0x1,%eax
f0100367:	66 a3 28 75 11 f0    	mov    %ax,0xf0117528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f010036d:	0f b7 c0             	movzwl %ax,%eax
f0100370:	66 81 e7 00 ff       	and    $0xff00,%di
f0100375:	83 cf 20             	or     $0x20,%edi
f0100378:	8b 15 2c 75 11 f0    	mov    0xf011752c,%edx
f010037e:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100382:	eb 78                	jmp    f01003fc <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100384:	66 83 05 28 75 11 f0 	addw   $0x50,0xf0117528
f010038b:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f010038c:	0f b7 05 28 75 11 f0 	movzwl 0xf0117528,%eax
f0100393:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100399:	c1 e8 16             	shr    $0x16,%eax
f010039c:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010039f:	c1 e0 04             	shl    $0x4,%eax
f01003a2:	66 a3 28 75 11 f0    	mov    %ax,0xf0117528
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
f01003de:	0f b7 05 28 75 11 f0 	movzwl 0xf0117528,%eax
f01003e5:	8d 50 01             	lea    0x1(%eax),%edx
f01003e8:	66 89 15 28 75 11 f0 	mov    %dx,0xf0117528
f01003ef:	0f b7 c0             	movzwl %ax,%eax
f01003f2:	8b 15 2c 75 11 f0    	mov    0xf011752c,%edx
f01003f8:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f01003fc:	66 81 3d 28 75 11 f0 	cmpw   $0x7cf,0xf0117528
f0100403:	cf 07 
f0100405:	76 43                	jbe    f010044a <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100407:	a1 2c 75 11 f0       	mov    0xf011752c,%eax
f010040c:	83 ec 04             	sub    $0x4,%esp
f010040f:	68 00 0f 00 00       	push   $0xf00
f0100414:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f010041a:	52                   	push   %edx
f010041b:	50                   	push   %eax
f010041c:	e8 31 2e 00 00       	call   f0103252 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100421:	8b 15 2c 75 11 f0    	mov    0xf011752c,%edx
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
f0100442:	66 83 2d 28 75 11 f0 	subw   $0x50,0xf0117528
f0100449:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f010044a:	8b 0d 30 75 11 f0    	mov    0xf0117530,%ecx
f0100450:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100455:	89 ca                	mov    %ecx,%edx
f0100457:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100458:	0f b7 1d 28 75 11 f0 	movzwl 0xf0117528,%ebx
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
f0100480:	80 3d 34 75 11 f0 00 	cmpb   $0x0,0xf0117534
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
f01004be:	a1 20 75 11 f0       	mov    0xf0117520,%eax
f01004c3:	3b 05 24 75 11 f0    	cmp    0xf0117524,%eax
f01004c9:	74 26                	je     f01004f1 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01004cb:	8d 50 01             	lea    0x1(%eax),%edx
f01004ce:	89 15 20 75 11 f0    	mov    %edx,0xf0117520
f01004d4:	0f b6 88 20 73 11 f0 	movzbl -0xfee8ce0(%eax),%ecx
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
f01004e5:	c7 05 20 75 11 f0 00 	movl   $0x0,0xf0117520
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
f010051e:	c7 05 30 75 11 f0 b4 	movl   $0x3b4,0xf0117530
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
f0100536:	c7 05 30 75 11 f0 d4 	movl   $0x3d4,0xf0117530
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
f0100545:	8b 3d 30 75 11 f0    	mov    0xf0117530,%edi
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
f010056a:	89 35 2c 75 11 f0    	mov    %esi,0xf011752c
	crt_pos = pos;
f0100570:	0f b6 c0             	movzbl %al,%eax
f0100573:	09 c8                	or     %ecx,%eax
f0100575:	66 a3 28 75 11 f0    	mov    %ax,0xf0117528
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
f01005d6:	0f 95 05 34 75 11 f0 	setne  0xf0117534
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
f01005eb:	68 f9 36 10 f0       	push   $0xf01036f9
f01005f0:	e8 67 21 00 00       	call   f010275c <cprintf>
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
f0100631:	68 40 39 10 f0       	push   $0xf0103940
f0100636:	68 5e 39 10 f0       	push   $0xf010395e
f010063b:	68 63 39 10 f0       	push   $0xf0103963
f0100640:	e8 17 21 00 00       	call   f010275c <cprintf>
f0100645:	83 c4 0c             	add    $0xc,%esp
f0100648:	68 5c 3a 10 f0       	push   $0xf0103a5c
f010064d:	68 6c 39 10 f0       	push   $0xf010396c
f0100652:	68 63 39 10 f0       	push   $0xf0103963
f0100657:	e8 00 21 00 00       	call   f010275c <cprintf>
f010065c:	83 c4 0c             	add    $0xc,%esp
f010065f:	68 75 39 10 f0       	push   $0xf0103975
f0100664:	68 89 39 10 f0       	push   $0xf0103989
f0100669:	68 63 39 10 f0       	push   $0xf0103963
f010066e:	e8 e9 20 00 00       	call   f010275c <cprintf>
	return 0;
}
f0100673:	b8 00 00 00 00       	mov    $0x0,%eax
f0100678:	c9                   	leave  
f0100679:	c3                   	ret    

f010067a <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f010067a:	55                   	push   %ebp
f010067b:	89 e5                	mov    %esp,%ebp
f010067d:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100680:	68 93 39 10 f0       	push   $0xf0103993
f0100685:	e8 d2 20 00 00       	call   f010275c <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f010068a:	83 c4 08             	add    $0x8,%esp
f010068d:	68 0c 00 10 00       	push   $0x10000c
f0100692:	68 84 3a 10 f0       	push   $0xf0103a84
f0100697:	e8 c0 20 00 00       	call   f010275c <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f010069c:	83 c4 0c             	add    $0xc,%esp
f010069f:	68 0c 00 10 00       	push   $0x10000c
f01006a4:	68 0c 00 10 f0       	push   $0xf010000c
f01006a9:	68 ac 3a 10 f0       	push   $0xf0103aac
f01006ae:	e8 a9 20 00 00       	call   f010275c <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006b3:	83 c4 0c             	add    $0xc,%esp
f01006b6:	68 91 36 10 00       	push   $0x103691
f01006bb:	68 91 36 10 f0       	push   $0xf0103691
f01006c0:	68 d0 3a 10 f0       	push   $0xf0103ad0
f01006c5:	e8 92 20 00 00       	call   f010275c <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006ca:	83 c4 0c             	add    $0xc,%esp
f01006cd:	68 00 73 11 00       	push   $0x117300
f01006d2:	68 00 73 11 f0       	push   $0xf0117300
f01006d7:	68 f4 3a 10 f0       	push   $0xf0103af4
f01006dc:	e8 7b 20 00 00       	call   f010275c <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006e1:	83 c4 0c             	add    $0xc,%esp
f01006e4:	68 50 79 11 00       	push   $0x117950
f01006e9:	68 50 79 11 f0       	push   $0xf0117950
f01006ee:	68 18 3b 10 f0       	push   $0xf0103b18
f01006f3:	e8 64 20 00 00       	call   f010275c <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f01006f8:	b8 4f 7d 11 f0       	mov    $0xf0117d4f,%eax
f01006fd:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100702:	83 c4 08             	add    $0x8,%esp
f0100705:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f010070a:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100710:	85 c0                	test   %eax,%eax
f0100712:	0f 48 c2             	cmovs  %edx,%eax
f0100715:	c1 f8 0a             	sar    $0xa,%eax
f0100718:	50                   	push   %eax
f0100719:	68 3c 3b 10 f0       	push   $0xf0103b3c
f010071e:	e8 39 20 00 00       	call   f010275c <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100723:	b8 00 00 00 00       	mov    $0x0,%eax
f0100728:	c9                   	leave  
f0100729:	c3                   	ret    

f010072a <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f010072a:	55                   	push   %ebp
f010072b:	89 e5                	mov    %esp,%ebp
f010072d:	57                   	push   %edi
f010072e:	56                   	push   %esi
f010072f:	53                   	push   %ebx
f0100730:	83 ec 38             	sub    $0x38,%esp

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f0100733:	89 ee                	mov    %ebp,%esi
	// Your code here.
	unsigned int *ebp = ((unsigned int*)read_ebp());
	cprintf("Stack backtrace:\n");
f0100735:	68 ac 39 10 f0       	push   $0xf01039ac
f010073a:	e8 1d 20 00 00       	call   f010275c <cprintf>
	while(ebp) {
f010073f:	83 c4 10             	add    $0x10,%esp
f0100742:	eb 7f                	jmp    f01007c3 <mon_backtrace+0x99>
		cprintf("ebp %08x ", ebp);
f0100744:	83 ec 08             	sub    $0x8,%esp
f0100747:	56                   	push   %esi
f0100748:	68 be 39 10 f0       	push   $0xf01039be
f010074d:	e8 0a 20 00 00       	call   f010275c <cprintf>
		cprintf("eip %08x args", ebp[1]);
f0100752:	83 c4 08             	add    $0x8,%esp
f0100755:	ff 76 04             	pushl  0x4(%esi)
f0100758:	68 c8 39 10 f0       	push   $0xf01039c8
f010075d:	e8 fa 1f 00 00       	call   f010275c <cprintf>
f0100762:	8d 5e 08             	lea    0x8(%esi),%ebx
f0100765:	8d 7e 1c             	lea    0x1c(%esi),%edi
f0100768:	83 c4 10             	add    $0x10,%esp
		for(int i = 2; i <= 6; i++)
			cprintf(" %08x", ebp[i]);
f010076b:	83 ec 08             	sub    $0x8,%esp
f010076e:	ff 33                	pushl  (%ebx)
f0100770:	68 d6 39 10 f0       	push   $0xf01039d6
f0100775:	e8 e2 1f 00 00       	call   f010275c <cprintf>
f010077a:	83 c3 04             	add    $0x4,%ebx
	unsigned int *ebp = ((unsigned int*)read_ebp());
	cprintf("Stack backtrace:\n");
	while(ebp) {
		cprintf("ebp %08x ", ebp);
		cprintf("eip %08x args", ebp[1]);
		for(int i = 2; i <= 6; i++)
f010077d:	83 c4 10             	add    $0x10,%esp
f0100780:	39 fb                	cmp    %edi,%ebx
f0100782:	75 e7                	jne    f010076b <mon_backtrace+0x41>
			cprintf(" %08x", ebp[i]);
		cprintf("\n");
f0100784:	83 ec 0c             	sub    $0xc,%esp
f0100787:	68 c9 46 10 f0       	push   $0xf01046c9
f010078c:	e8 cb 1f 00 00       	call   f010275c <cprintf>

		unsigned int eip = ebp[1];
f0100791:	8b 5e 04             	mov    0x4(%esi),%ebx
		struct Eipdebuginfo info;
		debuginfo_eip(eip, &info);
f0100794:	83 c4 08             	add    $0x8,%esp
f0100797:	8d 45 d0             	lea    -0x30(%ebp),%eax
f010079a:	50                   	push   %eax
f010079b:	53                   	push   %ebx
f010079c:	e8 c5 20 00 00       	call   f0102866 <debuginfo_eip>
		cprintf("\t%s:%d: %.*s+%d\n",
f01007a1:	83 c4 08             	add    $0x8,%esp
f01007a4:	2b 5d e0             	sub    -0x20(%ebp),%ebx
f01007a7:	53                   	push   %ebx
f01007a8:	ff 75 d8             	pushl  -0x28(%ebp)
f01007ab:	ff 75 dc             	pushl  -0x24(%ebp)
f01007ae:	ff 75 d4             	pushl  -0x2c(%ebp)
f01007b1:	ff 75 d0             	pushl  -0x30(%ebp)
f01007b4:	68 dc 39 10 f0       	push   $0xf01039dc
f01007b9:	e8 9e 1f 00 00       	call   f010275c <cprintf>
		info.eip_file, info.eip_line,
		info.eip_fn_namelen, info.eip_fn_name,
		eip-info.eip_fn_addr);

		ebp = (unsigned int*)(*ebp);
f01007be:	8b 36                	mov    (%esi),%esi
f01007c0:	83 c4 20             	add    $0x20,%esp
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	// Your code here.
	unsigned int *ebp = ((unsigned int*)read_ebp());
	cprintf("Stack backtrace:\n");
	while(ebp) {
f01007c3:	85 f6                	test   %esi,%esi
f01007c5:	0f 85 79 ff ff ff    	jne    f0100744 <mon_backtrace+0x1a>
		eip-info.eip_fn_addr);

		ebp = (unsigned int*)(*ebp);
	}
	return 0;
}
f01007cb:	b8 00 00 00 00       	mov    $0x0,%eax
f01007d0:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01007d3:	5b                   	pop    %ebx
f01007d4:	5e                   	pop    %esi
f01007d5:	5f                   	pop    %edi
f01007d6:	5d                   	pop    %ebp
f01007d7:	c3                   	ret    

f01007d8 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01007d8:	55                   	push   %ebp
f01007d9:	89 e5                	mov    %esp,%ebp
f01007db:	57                   	push   %edi
f01007dc:	56                   	push   %esi
f01007dd:	53                   	push   %ebx
f01007de:	83 ec 68             	sub    $0x68,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01007e1:	68 68 3b 10 f0       	push   $0xf0103b68
f01007e6:	e8 71 1f 00 00       	call   f010275c <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01007eb:	c7 04 24 8c 3b 10 f0 	movl   $0xf0103b8c,(%esp)
f01007f2:	e8 65 1f 00 00       	call   f010275c <cprintf>
	cprintf("6828 decimal is 15254 octal!\n");
f01007f7:	c7 04 24 ed 39 10 f0 	movl   $0xf01039ed,(%esp)
f01007fe:	e8 59 1f 00 00       	call   f010275c <cprintf>

   	unsigned int i = 0x00646c72;
f0100803:	c7 45 e4 72 6c 64 00 	movl   $0x646c72,-0x1c(%ebp)
    	cprintf("H%x Wo%s\n", 57616, &i);
f010080a:	83 c4 0c             	add    $0xc,%esp
f010080d:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0100810:	50                   	push   %eax
f0100811:	68 10 e1 00 00       	push   $0xe110
f0100816:	68 0b 3a 10 f0       	push   $0xf0103a0b
f010081b:	e8 3c 1f 00 00       	call   f010275c <cprintf>
	cprintf("x=%d y=%d\n", 3);
f0100820:	83 c4 08             	add    $0x8,%esp
f0100823:	6a 03                	push   $0x3
f0100825:	68 15 3a 10 f0       	push   $0xf0103a15
f010082a:	e8 2d 1f 00 00       	call   f010275c <cprintf>
f010082f:	83 c4 10             	add    $0x10,%esp

	while (1) {
		buf = readline("K> ");
f0100832:	83 ec 0c             	sub    $0xc,%esp
f0100835:	68 20 3a 10 f0       	push   $0xf0103a20
f010083a:	e8 6f 27 00 00       	call   f0102fae <readline>
f010083f:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100841:	83 c4 10             	add    $0x10,%esp
f0100844:	85 c0                	test   %eax,%eax
f0100846:	74 ea                	je     f0100832 <monitor+0x5a>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100848:	c7 45 a4 00 00 00 00 	movl   $0x0,-0x5c(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f010084f:	be 00 00 00 00       	mov    $0x0,%esi
f0100854:	eb 0a                	jmp    f0100860 <monitor+0x88>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100856:	c6 03 00             	movb   $0x0,(%ebx)
f0100859:	89 f7                	mov    %esi,%edi
f010085b:	8d 5b 01             	lea    0x1(%ebx),%ebx
f010085e:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100860:	0f b6 03             	movzbl (%ebx),%eax
f0100863:	84 c0                	test   %al,%al
f0100865:	74 63                	je     f01008ca <monitor+0xf2>
f0100867:	83 ec 08             	sub    $0x8,%esp
f010086a:	0f be c0             	movsbl %al,%eax
f010086d:	50                   	push   %eax
f010086e:	68 24 3a 10 f0       	push   $0xf0103a24
f0100873:	e8 50 29 00 00       	call   f01031c8 <strchr>
f0100878:	83 c4 10             	add    $0x10,%esp
f010087b:	85 c0                	test   %eax,%eax
f010087d:	75 d7                	jne    f0100856 <monitor+0x7e>
			*buf++ = 0;
		if (*buf == 0)
f010087f:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100882:	74 46                	je     f01008ca <monitor+0xf2>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100884:	83 fe 0f             	cmp    $0xf,%esi
f0100887:	75 14                	jne    f010089d <monitor+0xc5>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100889:	83 ec 08             	sub    $0x8,%esp
f010088c:	6a 10                	push   $0x10
f010088e:	68 29 3a 10 f0       	push   $0xf0103a29
f0100893:	e8 c4 1e 00 00       	call   f010275c <cprintf>
f0100898:	83 c4 10             	add    $0x10,%esp
f010089b:	eb 95                	jmp    f0100832 <monitor+0x5a>
			return 0;
		}
		argv[argc++] = buf;
f010089d:	8d 7e 01             	lea    0x1(%esi),%edi
f01008a0:	89 5c b5 a4          	mov    %ebx,-0x5c(%ebp,%esi,4)
f01008a4:	eb 03                	jmp    f01008a9 <monitor+0xd1>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f01008a6:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f01008a9:	0f b6 03             	movzbl (%ebx),%eax
f01008ac:	84 c0                	test   %al,%al
f01008ae:	74 ae                	je     f010085e <monitor+0x86>
f01008b0:	83 ec 08             	sub    $0x8,%esp
f01008b3:	0f be c0             	movsbl %al,%eax
f01008b6:	50                   	push   %eax
f01008b7:	68 24 3a 10 f0       	push   $0xf0103a24
f01008bc:	e8 07 29 00 00       	call   f01031c8 <strchr>
f01008c1:	83 c4 10             	add    $0x10,%esp
f01008c4:	85 c0                	test   %eax,%eax
f01008c6:	74 de                	je     f01008a6 <monitor+0xce>
f01008c8:	eb 94                	jmp    f010085e <monitor+0x86>
			buf++;
	}
	argv[argc] = 0;
f01008ca:	c7 44 b5 a4 00 00 00 	movl   $0x0,-0x5c(%ebp,%esi,4)
f01008d1:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01008d2:	85 f6                	test   %esi,%esi
f01008d4:	0f 84 58 ff ff ff    	je     f0100832 <monitor+0x5a>
f01008da:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01008df:	83 ec 08             	sub    $0x8,%esp
f01008e2:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01008e5:	ff 34 85 c0 3b 10 f0 	pushl  -0xfefc440(,%eax,4)
f01008ec:	ff 75 a4             	pushl  -0x5c(%ebp)
f01008ef:	e8 76 28 00 00       	call   f010316a <strcmp>
f01008f4:	83 c4 10             	add    $0x10,%esp
f01008f7:	85 c0                	test   %eax,%eax
f01008f9:	75 21                	jne    f010091c <monitor+0x144>
			return commands[i].func(argc, argv, tf);
f01008fb:	83 ec 04             	sub    $0x4,%esp
f01008fe:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100901:	ff 75 08             	pushl  0x8(%ebp)
f0100904:	8d 55 a4             	lea    -0x5c(%ebp),%edx
f0100907:	52                   	push   %edx
f0100908:	56                   	push   %esi
f0100909:	ff 14 85 c8 3b 10 f0 	call   *-0xfefc438(,%eax,4)
	cprintf("x=%d y=%d\n", 3);

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100910:	83 c4 10             	add    $0x10,%esp
f0100913:	85 c0                	test   %eax,%eax
f0100915:	78 25                	js     f010093c <monitor+0x164>
f0100917:	e9 16 ff ff ff       	jmp    f0100832 <monitor+0x5a>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f010091c:	83 c3 01             	add    $0x1,%ebx
f010091f:	83 fb 03             	cmp    $0x3,%ebx
f0100922:	75 bb                	jne    f01008df <monitor+0x107>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100924:	83 ec 08             	sub    $0x8,%esp
f0100927:	ff 75 a4             	pushl  -0x5c(%ebp)
f010092a:	68 46 3a 10 f0       	push   $0xf0103a46
f010092f:	e8 28 1e 00 00       	call   f010275c <cprintf>
f0100934:	83 c4 10             	add    $0x10,%esp
f0100937:	e9 f6 fe ff ff       	jmp    f0100832 <monitor+0x5a>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f010093c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010093f:	5b                   	pop    %ebx
f0100940:	5e                   	pop    %esi
f0100941:	5f                   	pop    %edi
f0100942:	5d                   	pop    %ebp
f0100943:	c3                   	ret    

f0100944 <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100944:	55                   	push   %ebp
f0100945:	89 e5                	mov    %esp,%ebp
f0100947:	53                   	push   %ebx
f0100948:	83 ec 04             	sub    $0x4,%esp
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f010094b:	83 3d 38 75 11 f0 00 	cmpl   $0x0,0xf0117538
f0100952:	75 11                	jne    f0100965 <boot_alloc+0x21>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100954:	ba 4f 89 11 f0       	mov    $0xf011894f,%edx
f0100959:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010095f:	89 15 38 75 11 f0    	mov    %edx,0xf0117538
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.

	result = nextfree;
f0100965:	8b 1d 38 75 11 f0    	mov    0xf0117538,%ebx
	nextfree = ROUNDUP((char *)result + n, PGSIZE);
f010096b:	8d 84 03 ff 0f 00 00 	lea    0xfff(%ebx,%eax,1),%eax
f0100972:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100977:	a3 38 75 11 f0       	mov    %eax,0xf0117538
	cprintf("boot_alloc memory at %x, next memory allocate at %x\n", result, nextfree);
f010097c:	83 ec 04             	sub    $0x4,%esp
f010097f:	50                   	push   %eax
f0100980:	53                   	push   %ebx
f0100981:	68 e4 3b 10 f0       	push   $0xf0103be4
f0100986:	e8 d1 1d 00 00       	call   f010275c <cprintf>
	return result;

}
f010098b:	89 d8                	mov    %ebx,%eax
f010098d:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100990:	c9                   	leave  
f0100991:	c3                   	ret    

f0100992 <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f0100992:	55                   	push   %ebp
f0100993:	89 e5                	mov    %esp,%ebp
f0100995:	56                   	push   %esi
f0100996:	53                   	push   %ebx
f0100997:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100999:	83 ec 0c             	sub    $0xc,%esp
f010099c:	50                   	push   %eax
f010099d:	e8 53 1d 00 00       	call   f01026f5 <mc146818_read>
f01009a2:	89 c6                	mov    %eax,%esi
f01009a4:	83 c3 01             	add    $0x1,%ebx
f01009a7:	89 1c 24             	mov    %ebx,(%esp)
f01009aa:	e8 46 1d 00 00       	call   f01026f5 <mc146818_read>
f01009af:	c1 e0 08             	shl    $0x8,%eax
f01009b2:	09 f0                	or     %esi,%eax
}
f01009b4:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01009b7:	5b                   	pop    %ebx
f01009b8:	5e                   	pop    %esi
f01009b9:	5d                   	pop    %ebp
f01009ba:	c3                   	ret    

f01009bb <check_va2pa>:
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f01009bb:	89 d1                	mov    %edx,%ecx
f01009bd:	c1 e9 16             	shr    $0x16,%ecx
f01009c0:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f01009c3:	a8 01                	test   $0x1,%al
f01009c5:	74 52                	je     f0100a19 <check_va2pa+0x5e>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f01009c7:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01009cc:	89 c1                	mov    %eax,%ecx
f01009ce:	c1 e9 0c             	shr    $0xc,%ecx
f01009d1:	3b 0d 44 79 11 f0    	cmp    0xf0117944,%ecx
f01009d7:	72 1b                	jb     f01009f4 <check_va2pa+0x39>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f01009d9:	55                   	push   %ebp
f01009da:	89 e5                	mov    %esp,%ebp
f01009dc:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01009df:	50                   	push   %eax
f01009e0:	68 1c 3c 10 f0       	push   $0xf0103c1c
f01009e5:	68 df 02 00 00       	push   $0x2df
f01009ea:	68 18 44 10 f0       	push   $0xf0104418
f01009ef:	e8 97 f6 ff ff       	call   f010008b <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f01009f4:	c1 ea 0c             	shr    $0xc,%edx
f01009f7:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f01009fd:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100a04:	89 c2                	mov    %eax,%edx
f0100a06:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100a09:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100a0e:	85 d2                	test   %edx,%edx
f0100a10:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100a15:	0f 44 c2             	cmove  %edx,%eax
f0100a18:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f0100a19:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f0100a1e:	c3                   	ret    

f0100a1f <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100a1f:	55                   	push   %ebp
f0100a20:	89 e5                	mov    %esp,%ebp
f0100a22:	57                   	push   %edi
f0100a23:	56                   	push   %esi
f0100a24:	53                   	push   %ebx
f0100a25:	83 ec 2c             	sub    $0x2c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100a28:	84 c0                	test   %al,%al
f0100a2a:	0f 85 81 02 00 00    	jne    f0100cb1 <check_page_free_list+0x292>
f0100a30:	e9 8e 02 00 00       	jmp    f0100cc3 <check_page_free_list+0x2a4>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f0100a35:	83 ec 04             	sub    $0x4,%esp
f0100a38:	68 40 3c 10 f0       	push   $0xf0103c40
f0100a3d:	68 20 02 00 00       	push   $0x220
f0100a42:	68 18 44 10 f0       	push   $0xf0104418
f0100a47:	e8 3f f6 ff ff       	call   f010008b <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100a4c:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100a4f:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100a52:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100a55:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100a58:	89 c2                	mov    %eax,%edx
f0100a5a:	2b 15 4c 79 11 f0    	sub    0xf011794c,%edx
f0100a60:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100a66:	0f 95 c2             	setne  %dl
f0100a69:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100a6c:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100a70:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100a72:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100a76:	8b 00                	mov    (%eax),%eax
f0100a78:	85 c0                	test   %eax,%eax
f0100a7a:	75 dc                	jne    f0100a58 <check_page_free_list+0x39>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100a7c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a7f:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100a85:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100a88:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100a8b:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100a8d:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100a90:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100a95:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100a9a:	8b 1d 3c 75 11 f0    	mov    0xf011753c,%ebx
f0100aa0:	eb 53                	jmp    f0100af5 <check_page_free_list+0xd6>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100aa2:	89 d8                	mov    %ebx,%eax
f0100aa4:	2b 05 4c 79 11 f0    	sub    0xf011794c,%eax
f0100aaa:	c1 f8 03             	sar    $0x3,%eax
f0100aad:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100ab0:	89 c2                	mov    %eax,%edx
f0100ab2:	c1 ea 16             	shr    $0x16,%edx
f0100ab5:	39 f2                	cmp    %esi,%edx
f0100ab7:	73 3a                	jae    f0100af3 <check_page_free_list+0xd4>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100ab9:	89 c2                	mov    %eax,%edx
f0100abb:	c1 ea 0c             	shr    $0xc,%edx
f0100abe:	3b 15 44 79 11 f0    	cmp    0xf0117944,%edx
f0100ac4:	72 12                	jb     f0100ad8 <check_page_free_list+0xb9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ac6:	50                   	push   %eax
f0100ac7:	68 1c 3c 10 f0       	push   $0xf0103c1c
f0100acc:	6a 52                	push   $0x52
f0100ace:	68 24 44 10 f0       	push   $0xf0104424
f0100ad3:	e8 b3 f5 ff ff       	call   f010008b <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100ad8:	83 ec 04             	sub    $0x4,%esp
f0100adb:	68 80 00 00 00       	push   $0x80
f0100ae0:	68 97 00 00 00       	push   $0x97
f0100ae5:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100aea:	50                   	push   %eax
f0100aeb:	e8 15 27 00 00       	call   f0103205 <memset>
f0100af0:	83 c4 10             	add    $0x10,%esp
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100af3:	8b 1b                	mov    (%ebx),%ebx
f0100af5:	85 db                	test   %ebx,%ebx
f0100af7:	75 a9                	jne    f0100aa2 <check_page_free_list+0x83>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100af9:	b8 00 00 00 00       	mov    $0x0,%eax
f0100afe:	e8 41 fe ff ff       	call   f0100944 <boot_alloc>
f0100b03:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b06:	8b 15 3c 75 11 f0    	mov    0xf011753c,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100b0c:	8b 0d 4c 79 11 f0    	mov    0xf011794c,%ecx
		assert(pp < pages + npages);
f0100b12:	a1 44 79 11 f0       	mov    0xf0117944,%eax
f0100b17:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0100b1a:	8d 3c c1             	lea    (%ecx,%eax,8),%edi
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100b1d:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100b20:	be 00 00 00 00       	mov    $0x0,%esi
f0100b25:	89 5d d0             	mov    %ebx,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b28:	e9 30 01 00 00       	jmp    f0100c5d <check_page_free_list+0x23e>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100b2d:	39 ca                	cmp    %ecx,%edx
f0100b2f:	73 19                	jae    f0100b4a <check_page_free_list+0x12b>
f0100b31:	68 32 44 10 f0       	push   $0xf0104432
f0100b36:	68 3e 44 10 f0       	push   $0xf010443e
f0100b3b:	68 3a 02 00 00       	push   $0x23a
f0100b40:	68 18 44 10 f0       	push   $0xf0104418
f0100b45:	e8 41 f5 ff ff       	call   f010008b <_panic>
		assert(pp < pages + npages);
f0100b4a:	39 fa                	cmp    %edi,%edx
f0100b4c:	72 19                	jb     f0100b67 <check_page_free_list+0x148>
f0100b4e:	68 53 44 10 f0       	push   $0xf0104453
f0100b53:	68 3e 44 10 f0       	push   $0xf010443e
f0100b58:	68 3b 02 00 00       	push   $0x23b
f0100b5d:	68 18 44 10 f0       	push   $0xf0104418
f0100b62:	e8 24 f5 ff ff       	call   f010008b <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100b67:	89 d0                	mov    %edx,%eax
f0100b69:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100b6c:	a8 07                	test   $0x7,%al
f0100b6e:	74 19                	je     f0100b89 <check_page_free_list+0x16a>
f0100b70:	68 64 3c 10 f0       	push   $0xf0103c64
f0100b75:	68 3e 44 10 f0       	push   $0xf010443e
f0100b7a:	68 3c 02 00 00       	push   $0x23c
f0100b7f:	68 18 44 10 f0       	push   $0xf0104418
f0100b84:	e8 02 f5 ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100b89:	c1 f8 03             	sar    $0x3,%eax
f0100b8c:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100b8f:	85 c0                	test   %eax,%eax
f0100b91:	75 19                	jne    f0100bac <check_page_free_list+0x18d>
f0100b93:	68 67 44 10 f0       	push   $0xf0104467
f0100b98:	68 3e 44 10 f0       	push   $0xf010443e
f0100b9d:	68 3f 02 00 00       	push   $0x23f
f0100ba2:	68 18 44 10 f0       	push   $0xf0104418
f0100ba7:	e8 df f4 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100bac:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100bb1:	75 19                	jne    f0100bcc <check_page_free_list+0x1ad>
f0100bb3:	68 78 44 10 f0       	push   $0xf0104478
f0100bb8:	68 3e 44 10 f0       	push   $0xf010443e
f0100bbd:	68 40 02 00 00       	push   $0x240
f0100bc2:	68 18 44 10 f0       	push   $0xf0104418
f0100bc7:	e8 bf f4 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100bcc:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100bd1:	75 19                	jne    f0100bec <check_page_free_list+0x1cd>
f0100bd3:	68 98 3c 10 f0       	push   $0xf0103c98
f0100bd8:	68 3e 44 10 f0       	push   $0xf010443e
f0100bdd:	68 41 02 00 00       	push   $0x241
f0100be2:	68 18 44 10 f0       	push   $0xf0104418
f0100be7:	e8 9f f4 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100bec:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100bf1:	75 19                	jne    f0100c0c <check_page_free_list+0x1ed>
f0100bf3:	68 91 44 10 f0       	push   $0xf0104491
f0100bf8:	68 3e 44 10 f0       	push   $0xf010443e
f0100bfd:	68 42 02 00 00       	push   $0x242
f0100c02:	68 18 44 10 f0       	push   $0xf0104418
f0100c07:	e8 7f f4 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100c0c:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100c11:	76 3f                	jbe    f0100c52 <check_page_free_list+0x233>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100c13:	89 c3                	mov    %eax,%ebx
f0100c15:	c1 eb 0c             	shr    $0xc,%ebx
f0100c18:	39 5d c8             	cmp    %ebx,-0x38(%ebp)
f0100c1b:	77 12                	ja     f0100c2f <check_page_free_list+0x210>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100c1d:	50                   	push   %eax
f0100c1e:	68 1c 3c 10 f0       	push   $0xf0103c1c
f0100c23:	6a 52                	push   $0x52
f0100c25:	68 24 44 10 f0       	push   $0xf0104424
f0100c2a:	e8 5c f4 ff ff       	call   f010008b <_panic>
f0100c2f:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100c34:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100c37:	76 1e                	jbe    f0100c57 <check_page_free_list+0x238>
f0100c39:	68 bc 3c 10 f0       	push   $0xf0103cbc
f0100c3e:	68 3e 44 10 f0       	push   $0xf010443e
f0100c43:	68 43 02 00 00       	push   $0x243
f0100c48:	68 18 44 10 f0       	push   $0xf0104418
f0100c4d:	e8 39 f4 ff ff       	call   f010008b <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100c52:	83 c6 01             	add    $0x1,%esi
f0100c55:	eb 04                	jmp    f0100c5b <check_page_free_list+0x23c>
		else
			++nfree_extmem;
f0100c57:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c5b:	8b 12                	mov    (%edx),%edx
f0100c5d:	85 d2                	test   %edx,%edx
f0100c5f:	0f 85 c8 fe ff ff    	jne    f0100b2d <check_page_free_list+0x10e>
f0100c65:	8b 5d d0             	mov    -0x30(%ebp),%ebx
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100c68:	85 f6                	test   %esi,%esi
f0100c6a:	7f 19                	jg     f0100c85 <check_page_free_list+0x266>
f0100c6c:	68 ab 44 10 f0       	push   $0xf01044ab
f0100c71:	68 3e 44 10 f0       	push   $0xf010443e
f0100c76:	68 4b 02 00 00       	push   $0x24b
f0100c7b:	68 18 44 10 f0       	push   $0xf0104418
f0100c80:	e8 06 f4 ff ff       	call   f010008b <_panic>
	assert(nfree_extmem > 0);
f0100c85:	85 db                	test   %ebx,%ebx
f0100c87:	7f 19                	jg     f0100ca2 <check_page_free_list+0x283>
f0100c89:	68 bd 44 10 f0       	push   $0xf01044bd
f0100c8e:	68 3e 44 10 f0       	push   $0xf010443e
f0100c93:	68 4c 02 00 00       	push   $0x24c
f0100c98:	68 18 44 10 f0       	push   $0xf0104418
f0100c9d:	e8 e9 f3 ff ff       	call   f010008b <_panic>

	cprintf("check_page_free_list() succeeded!\n");
f0100ca2:	83 ec 0c             	sub    $0xc,%esp
f0100ca5:	68 04 3d 10 f0       	push   $0xf0103d04
f0100caa:	e8 ad 1a 00 00       	call   f010275c <cprintf>
}
f0100caf:	eb 29                	jmp    f0100cda <check_page_free_list+0x2bb>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100cb1:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f0100cb6:	85 c0                	test   %eax,%eax
f0100cb8:	0f 85 8e fd ff ff    	jne    f0100a4c <check_page_free_list+0x2d>
f0100cbe:	e9 72 fd ff ff       	jmp    f0100a35 <check_page_free_list+0x16>
f0100cc3:	83 3d 3c 75 11 f0 00 	cmpl   $0x0,0xf011753c
f0100cca:	0f 84 65 fd ff ff    	je     f0100a35 <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100cd0:	be 00 04 00 00       	mov    $0x400,%esi
f0100cd5:	e9 c0 fd ff ff       	jmp    f0100a9a <check_page_free_list+0x7b>

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);

	cprintf("check_page_free_list() succeeded!\n");
}
f0100cda:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100cdd:	5b                   	pop    %ebx
f0100cde:	5e                   	pop    %esi
f0100cdf:	5f                   	pop    %edi
f0100ce0:	5d                   	pop    %ebp
f0100ce1:	c3                   	ret    

f0100ce2 <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100ce2:	55                   	push   %ebp
f0100ce3:	89 e5                	mov    %esp,%ebp
f0100ce5:	56                   	push   %esi
f0100ce6:	53                   	push   %ebx
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
    	size_t io_hole_start_page = (size_t)IOPHYSMEM / PGSIZE;
    	size_t kernel_end_page = PADDR(boot_alloc(0)) / PGSIZE;
f0100ce7:	b8 00 00 00 00       	mov    $0x0,%eax
f0100cec:	e8 53 fc ff ff       	call   f0100944 <boot_alloc>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100cf1:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100cf6:	77 15                	ja     f0100d0d <page_init+0x2b>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100cf8:	50                   	push   %eax
f0100cf9:	68 28 3d 10 f0       	push   $0xf0103d28
f0100cfe:	68 06 01 00 00       	push   $0x106
f0100d03:	68 18 44 10 f0       	push   $0xf0104418
f0100d08:	e8 7e f3 ff ff       	call   f010008b <_panic>
f0100d0d:	05 00 00 00 10       	add    $0x10000000,%eax
f0100d12:	c1 e8 0c             	shr    $0xc,%eax
f0100d15:	8b 35 3c 75 11 f0    	mov    0xf011753c,%esi
    	for (i = 0; i < npages; i++) {
f0100d1b:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100d20:	ba 00 00 00 00       	mov    $0x0,%edx
f0100d25:	eb 62                	jmp    f0100d89 <page_init+0xa7>
		if (i == 0) {
f0100d27:	85 d2                	test   %edx,%edx
f0100d29:	75 14                	jne    f0100d3f <page_init+0x5d>
			pages[i].pp_ref = 1;
f0100d2b:	8b 0d 4c 79 11 f0    	mov    0xf011794c,%ecx
f0100d31:	66 c7 41 04 01 00    	movw   $0x1,0x4(%ecx)
			pages[i].pp_link = NULL;
f0100d37:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
f0100d3d:	eb 47                	jmp    f0100d86 <page_init+0xa4>
        	} else if (i >= io_hole_start_page && i < kernel_end_page) {
f0100d3f:	81 fa 9f 00 00 00    	cmp    $0x9f,%edx
f0100d45:	76 1b                	jbe    f0100d62 <page_init+0x80>
f0100d47:	39 c2                	cmp    %eax,%edx
f0100d49:	73 17                	jae    f0100d62 <page_init+0x80>
            		pages[i].pp_ref = 1;
f0100d4b:	8b 0d 4c 79 11 f0    	mov    0xf011794c,%ecx
f0100d51:	8d 0c d1             	lea    (%ecx,%edx,8),%ecx
f0100d54:	66 c7 41 04 01 00    	movw   $0x1,0x4(%ecx)
            		pages[i].pp_link = NULL;
f0100d5a:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
f0100d60:	eb 24                	jmp    f0100d86 <page_init+0xa4>
f0100d62:	8d 0c d5 00 00 00 00 	lea    0x0(,%edx,8),%ecx
        	} else {
            		pages[i].pp_ref = 0;
f0100d69:	89 cb                	mov    %ecx,%ebx
f0100d6b:	03 1d 4c 79 11 f0    	add    0xf011794c,%ebx
f0100d71:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
            		pages[i].pp_link = page_free_list;
f0100d77:	89 33                	mov    %esi,(%ebx)
            		page_free_list = &pages[i];
f0100d79:	89 ce                	mov    %ecx,%esi
f0100d7b:	03 35 4c 79 11 f0    	add    0xf011794c,%esi
f0100d81:	bb 01 00 00 00       	mov    $0x1,%ebx
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
    	size_t io_hole_start_page = (size_t)IOPHYSMEM / PGSIZE;
    	size_t kernel_end_page = PADDR(boot_alloc(0)) / PGSIZE;
    	for (i = 0; i < npages; i++) {
f0100d86:	83 c2 01             	add    $0x1,%edx
f0100d89:	3b 15 44 79 11 f0    	cmp    0xf0117944,%edx
f0100d8f:	72 96                	jb     f0100d27 <page_init+0x45>
f0100d91:	84 db                	test   %bl,%bl
f0100d93:	74 06                	je     f0100d9b <page_init+0xb9>
f0100d95:	89 35 3c 75 11 f0    	mov    %esi,0xf011753c
            		pages[i].pp_ref = 0;
            		pages[i].pp_link = page_free_list;
            		page_free_list = &pages[i];
        	}
    	}
}
f0100d9b:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100d9e:	5b                   	pop    %ebx
f0100d9f:	5e                   	pop    %esi
f0100da0:	5d                   	pop    %ebp
f0100da1:	c3                   	ret    

f0100da2 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100da2:	55                   	push   %ebp
f0100da3:	89 e5                	mov    %esp,%ebp
f0100da5:	53                   	push   %ebx
f0100da6:	83 ec 04             	sub    $0x4,%esp
	// Fill this function in
	struct PageInfo *ret = page_free_list;
f0100da9:	8b 1d 3c 75 11 f0    	mov    0xf011753c,%ebx
	if (ret == NULL) {
f0100daf:	85 db                	test   %ebx,%ebx
f0100db1:	75 17                	jne    f0100dca <page_alloc+0x28>
		cprintf("page_alloc: out of free memory\n");
f0100db3:	83 ec 0c             	sub    $0xc,%esp
f0100db6:	68 4c 3d 10 f0       	push   $0xf0103d4c
f0100dbb:	e8 9c 19 00 00       	call   f010275c <cprintf>
		return NULL;
f0100dc0:	83 c4 10             	add    $0x10,%esp
f0100dc3:	b8 00 00 00 00       	mov    $0x0,%eax
f0100dc8:	eb 5a                	jmp    f0100e24 <page_alloc+0x82>
	}
	page_free_list = ret->pp_link;
f0100dca:	8b 03                	mov    (%ebx),%eax
f0100dcc:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
	ret->pp_link = NULL;
f0100dd1:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	if (alloc_flags & ALLOC_ZERO) {
		memset(page2kva(ret), 0, PGSIZE);
	}
	return ret;
f0100dd7:	89 d8                	mov    %ebx,%eax
		cprintf("page_alloc: out of free memory\n");
		return NULL;
	}
	page_free_list = ret->pp_link;
	ret->pp_link = NULL;
	if (alloc_flags & ALLOC_ZERO) {
f0100dd9:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100ddd:	74 45                	je     f0100e24 <page_alloc+0x82>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100ddf:	2b 05 4c 79 11 f0    	sub    0xf011794c,%eax
f0100de5:	c1 f8 03             	sar    $0x3,%eax
f0100de8:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100deb:	89 c2                	mov    %eax,%edx
f0100ded:	c1 ea 0c             	shr    $0xc,%edx
f0100df0:	3b 15 44 79 11 f0    	cmp    0xf0117944,%edx
f0100df6:	72 12                	jb     f0100e0a <page_alloc+0x68>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100df8:	50                   	push   %eax
f0100df9:	68 1c 3c 10 f0       	push   $0xf0103c1c
f0100dfe:	6a 52                	push   $0x52
f0100e00:	68 24 44 10 f0       	push   $0xf0104424
f0100e05:	e8 81 f2 ff ff       	call   f010008b <_panic>
		memset(page2kva(ret), 0, PGSIZE);
f0100e0a:	83 ec 04             	sub    $0x4,%esp
f0100e0d:	68 00 10 00 00       	push   $0x1000
f0100e12:	6a 00                	push   $0x0
f0100e14:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100e19:	50                   	push   %eax
f0100e1a:	e8 e6 23 00 00       	call   f0103205 <memset>
f0100e1f:	83 c4 10             	add    $0x10,%esp
	}
	return ret;
f0100e22:	89 d8                	mov    %ebx,%eax

}
f0100e24:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100e27:	c9                   	leave  
f0100e28:	c3                   	ret    

f0100e29 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100e29:	55                   	push   %ebp
f0100e2a:	89 e5                	mov    %esp,%ebp
f0100e2c:	83 ec 08             	sub    $0x8,%esp
f0100e2f:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
	if (pp->pp_ref != 0 || pp->pp_link != NULL) {
f0100e32:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100e37:	75 05                	jne    f0100e3e <page_free+0x15>
f0100e39:	83 38 00             	cmpl   $0x0,(%eax)
f0100e3c:	74 17                	je     f0100e55 <page_free+0x2c>
        	panic("page_free: pp->pp_ref is nonzero or pp->pp_link is not NULL\n");
f0100e3e:	83 ec 04             	sub    $0x4,%esp
f0100e41:	68 6c 3d 10 f0       	push   $0xf0103d6c
f0100e46:	68 3f 01 00 00       	push   $0x13f
f0100e4b:	68 18 44 10 f0       	push   $0xf0104418
f0100e50:	e8 36 f2 ff ff       	call   f010008b <_panic>
    	}
    	pp->pp_link = page_free_list;
f0100e55:	8b 15 3c 75 11 f0    	mov    0xf011753c,%edx
f0100e5b:	89 10                	mov    %edx,(%eax)
    	page_free_list = pp;
f0100e5d:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
}
f0100e62:	c9                   	leave  
f0100e63:	c3                   	ret    

f0100e64 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0100e64:	55                   	push   %ebp
f0100e65:	89 e5                	mov    %esp,%ebp
f0100e67:	83 ec 08             	sub    $0x8,%esp
f0100e6a:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0100e6d:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0100e71:	83 e8 01             	sub    $0x1,%eax
f0100e74:	66 89 42 04          	mov    %ax,0x4(%edx)
f0100e78:	66 85 c0             	test   %ax,%ax
f0100e7b:	75 0c                	jne    f0100e89 <page_decref+0x25>
		page_free(pp);
f0100e7d:	83 ec 0c             	sub    $0xc,%esp
f0100e80:	52                   	push   %edx
f0100e81:	e8 a3 ff ff ff       	call   f0100e29 <page_free>
f0100e86:	83 c4 10             	add    $0x10,%esp
}
f0100e89:	c9                   	leave  
f0100e8a:	c3                   	ret    

f0100e8b <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100e8b:	55                   	push   %ebp
f0100e8c:	89 e5                	mov    %esp,%ebp
f0100e8e:	56                   	push   %esi
f0100e8f:	53                   	push   %ebx
f0100e90:	8b 75 0c             	mov    0xc(%ebp),%esi
	// Fill this function in
	pde_t* pde_ptr = pgdir + PDX(va);
f0100e93:	89 f3                	mov    %esi,%ebx
f0100e95:	c1 eb 16             	shr    $0x16,%ebx
f0100e98:	c1 e3 02             	shl    $0x2,%ebx
f0100e9b:	03 5d 08             	add    0x8(%ebp),%ebx
    	if (!(*pde_ptr & PTE_P)) {                              //页表还没有分配
f0100e9e:	f6 03 01             	testb  $0x1,(%ebx)
f0100ea1:	75 2d                	jne    f0100ed0 <pgdir_walk+0x45>
        if (create) {
f0100ea3:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100ea7:	74 62                	je     f0100f0b <pgdir_walk+0x80>
            //分配一个页作为页表
            struct PageInfo *pp = page_alloc(1);
f0100ea9:	83 ec 0c             	sub    $0xc,%esp
f0100eac:	6a 01                	push   $0x1
f0100eae:	e8 ef fe ff ff       	call   f0100da2 <page_alloc>
            if (pp == NULL) {
f0100eb3:	83 c4 10             	add    $0x10,%esp
f0100eb6:	85 c0                	test   %eax,%eax
f0100eb8:	74 58                	je     f0100f12 <pgdir_walk+0x87>
                return NULL;
            }
            pp->pp_ref++;
f0100eba:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
            *pde_ptr = (page2pa(pp)) | PTE_P | PTE_U | PTE_W;   //更新页目录项
f0100ebf:	2b 05 4c 79 11 f0    	sub    0xf011794c,%eax
f0100ec5:	c1 f8 03             	sar    $0x3,%eax
f0100ec8:	c1 e0 0c             	shl    $0xc,%eax
f0100ecb:	83 c8 07             	or     $0x7,%eax
f0100ece:	89 03                	mov    %eax,(%ebx)
        } else {
            return NULL;
        }
    }
    return (pte_t *)KADDR(PTE_ADDR(*pde_ptr)) + PTX(va);
f0100ed0:	8b 03                	mov    (%ebx),%eax
f0100ed2:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100ed7:	89 c2                	mov    %eax,%edx
f0100ed9:	c1 ea 0c             	shr    $0xc,%edx
f0100edc:	3b 15 44 79 11 f0    	cmp    0xf0117944,%edx
f0100ee2:	72 15                	jb     f0100ef9 <pgdir_walk+0x6e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ee4:	50                   	push   %eax
f0100ee5:	68 1c 3c 10 f0       	push   $0xf0103c1c
f0100eea:	68 78 01 00 00       	push   $0x178
f0100eef:	68 18 44 10 f0       	push   $0xf0104418
f0100ef4:	e8 92 f1 ff ff       	call   f010008b <_panic>
f0100ef9:	c1 ee 0a             	shr    $0xa,%esi
f0100efc:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f0100f02:	8d 84 30 00 00 00 f0 	lea    -0x10000000(%eax,%esi,1),%eax
f0100f09:	eb 0c                	jmp    f0100f17 <pgdir_walk+0x8c>
                return NULL;
            }
            pp->pp_ref++;
            *pde_ptr = (page2pa(pp)) | PTE_P | PTE_U | PTE_W;   //更新页目录项
        } else {
            return NULL;
f0100f0b:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f10:	eb 05                	jmp    f0100f17 <pgdir_walk+0x8c>
    	if (!(*pde_ptr & PTE_P)) {                              //页表还没有分配
        if (create) {
            //分配一个页作为页表
            struct PageInfo *pp = page_alloc(1);
            if (pp == NULL) {
                return NULL;
f0100f12:	b8 00 00 00 00       	mov    $0x0,%eax
        } else {
            return NULL;
        }
    }
    return (pte_t *)KADDR(PTE_ADDR(*pde_ptr)) + PTX(va);
}
f0100f17:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100f1a:	5b                   	pop    %ebx
f0100f1b:	5e                   	pop    %esi
f0100f1c:	5d                   	pop    %ebp
f0100f1d:	c3                   	ret    

f0100f1e <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f0100f1e:	55                   	push   %ebp
f0100f1f:	89 e5                	mov    %esp,%ebp
f0100f21:	57                   	push   %edi
f0100f22:	56                   	push   %esi
f0100f23:	53                   	push   %ebx
f0100f24:	83 ec 1c             	sub    $0x1c,%esp
f0100f27:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100f2a:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	size_t pgs = size / PGSIZE;    
f0100f2d:	89 cb                	mov    %ecx,%ebx
f0100f2f:	c1 eb 0c             	shr    $0xc,%ebx
    	if (size % PGSIZE != 0) {
f0100f32:	81 e1 ff 0f 00 00    	and    $0xfff,%ecx
        	pgs++;
f0100f38:	83 f9 01             	cmp    $0x1,%ecx
f0100f3b:	83 db ff             	sbb    $0xffffffff,%ebx
f0100f3e:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
    	}                            //计算总共有多少页
    	for (int i = 0; i < pgs; i++) {
f0100f41:	89 c3                	mov    %eax,%ebx
f0100f43:	be 00 00 00 00       	mov    $0x0,%esi
        	pte_t *pte = pgdir_walk(pgdir, (void *)va, 1);//获取va对应的PTE的地址
f0100f48:	89 d7                	mov    %edx,%edi
f0100f4a:	29 c7                	sub    %eax,%edi
        	if (pte == NULL) {
            		panic("boot_map_region(): out of memory\n");
        	}
        	*pte = pa | PTE_P | perm; //修改va对应的PTE的值
f0100f4c:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100f4f:	83 c8 01             	or     $0x1,%eax
f0100f52:	89 45 dc             	mov    %eax,-0x24(%ebp)
	// Fill this function in
	size_t pgs = size / PGSIZE;    
    	if (size % PGSIZE != 0) {
        	pgs++;
    	}                            //计算总共有多少页
    	for (int i = 0; i < pgs; i++) {
f0100f55:	eb 3f                	jmp    f0100f96 <boot_map_region+0x78>
        	pte_t *pte = pgdir_walk(pgdir, (void *)va, 1);//获取va对应的PTE的地址
f0100f57:	83 ec 04             	sub    $0x4,%esp
f0100f5a:	6a 01                	push   $0x1
f0100f5c:	8d 04 1f             	lea    (%edi,%ebx,1),%eax
f0100f5f:	50                   	push   %eax
f0100f60:	ff 75 e0             	pushl  -0x20(%ebp)
f0100f63:	e8 23 ff ff ff       	call   f0100e8b <pgdir_walk>
        	if (pte == NULL) {
f0100f68:	83 c4 10             	add    $0x10,%esp
f0100f6b:	85 c0                	test   %eax,%eax
f0100f6d:	75 17                	jne    f0100f86 <boot_map_region+0x68>
            		panic("boot_map_region(): out of memory\n");
f0100f6f:	83 ec 04             	sub    $0x4,%esp
f0100f72:	68 ac 3d 10 f0       	push   $0xf0103dac
f0100f77:	68 91 01 00 00       	push   $0x191
f0100f7c:	68 18 44 10 f0       	push   $0xf0104418
f0100f81:	e8 05 f1 ff ff       	call   f010008b <_panic>
        	}
        	*pte = pa | PTE_P | perm; //修改va对应的PTE的值
f0100f86:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100f89:	09 da                	or     %ebx,%edx
f0100f8b:	89 10                	mov    %edx,(%eax)
        	pa += PGSIZE;             //更新pa和va，进行下一轮循环
f0100f8d:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	// Fill this function in
	size_t pgs = size / PGSIZE;    
    	if (size % PGSIZE != 0) {
        	pgs++;
    	}                            //计算总共有多少页
    	for (int i = 0; i < pgs; i++) {
f0100f93:	83 c6 01             	add    $0x1,%esi
f0100f96:	3b 75 e4             	cmp    -0x1c(%ebp),%esi
f0100f99:	75 bc                	jne    f0100f57 <boot_map_region+0x39>
        	*pte = pa | PTE_P | perm; //修改va对应的PTE的值
        	pa += PGSIZE;             //更新pa和va，进行下一轮循环
        	va += PGSIZE;
    	}

}
f0100f9b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100f9e:	5b                   	pop    %ebx
f0100f9f:	5e                   	pop    %esi
f0100fa0:	5f                   	pop    %edi
f0100fa1:	5d                   	pop    %ebp
f0100fa2:	c3                   	ret    

f0100fa3 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0100fa3:	55                   	push   %ebp
f0100fa4:	89 e5                	mov    %esp,%ebp
f0100fa6:	53                   	push   %ebx
f0100fa7:	83 ec 08             	sub    $0x8,%esp
f0100faa:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// Fill this function in
	struct PageInfo *pp;
    	pte_t *pte =  pgdir_walk(pgdir, va, 0);         //如果对应的页表不存在，不进行创建
f0100fad:	6a 00                	push   $0x0
f0100faf:	ff 75 0c             	pushl  0xc(%ebp)
f0100fb2:	ff 75 08             	pushl  0x8(%ebp)
f0100fb5:	e8 d1 fe ff ff       	call   f0100e8b <pgdir_walk>
    	if (pte == NULL) {
f0100fba:	83 c4 10             	add    $0x10,%esp
f0100fbd:	85 c0                	test   %eax,%eax
f0100fbf:	74 37                	je     f0100ff8 <page_lookup+0x55>
f0100fc1:	89 c1                	mov    %eax,%ecx
        	return NULL;
    	}
    	if (!(*pte) & PTE_P) {
f0100fc3:	8b 10                	mov    (%eax),%edx
f0100fc5:	85 d2                	test   %edx,%edx
f0100fc7:	74 36                	je     f0100fff <page_lookup+0x5c>
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100fc9:	c1 ea 0c             	shr    $0xc,%edx
f0100fcc:	3b 15 44 79 11 f0    	cmp    0xf0117944,%edx
f0100fd2:	72 14                	jb     f0100fe8 <page_lookup+0x45>
		panic("pa2page called with invalid pa");
f0100fd4:	83 ec 04             	sub    $0x4,%esp
f0100fd7:	68 d0 3d 10 f0       	push   $0xf0103dd0
f0100fdc:	6a 4b                	push   $0x4b
f0100fde:	68 24 44 10 f0       	push   $0xf0104424
f0100fe3:	e8 a3 f0 ff ff       	call   f010008b <_panic>
	return &pages[PGNUM(pa)];
f0100fe8:	a1 4c 79 11 f0       	mov    0xf011794c,%eax
f0100fed:	8d 04 d0             	lea    (%eax,%edx,8),%eax
      		return NULL;
    	}
    	physaddr_t pa = PTE_ADDR(*pte);                 //va对应的物理
    	pp = pa2page(pa);                               //物理地址对应的PageInfo结构地址
    	if (pte_store != NULL) {
f0100ff0:	85 db                	test   %ebx,%ebx
f0100ff2:	74 10                	je     f0101004 <page_lookup+0x61>
        	*pte_store = pte;
f0100ff4:	89 0b                	mov    %ecx,(%ebx)
f0100ff6:	eb 0c                	jmp    f0101004 <page_lookup+0x61>
{
	// Fill this function in
	struct PageInfo *pp;
    	pte_t *pte =  pgdir_walk(pgdir, va, 0);         //如果对应的页表不存在，不进行创建
    	if (pte == NULL) {
        	return NULL;
f0100ff8:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ffd:	eb 05                	jmp    f0101004 <page_lookup+0x61>
    	}
    	if (!(*pte) & PTE_P) {
      		return NULL;
f0100fff:	b8 00 00 00 00       	mov    $0x0,%eax
    	pp = pa2page(pa);                               //物理地址对应的PageInfo结构地址
    	if (pte_store != NULL) {
        	*pte_store = pte;
    	}
    	return pp;
}
f0101004:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101007:	c9                   	leave  
f0101008:	c3                   	ret    

f0101009 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0101009:	55                   	push   %ebp
f010100a:	89 e5                	mov    %esp,%ebp
f010100c:	53                   	push   %ebx
f010100d:	83 ec 18             	sub    $0x18,%esp
f0101010:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
 	pte_t *pte_store;
    	struct PageInfo *pp = page_lookup(pgdir, va, &pte_store); //获取va对应的PTE的地址以及pp结构
f0101013:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101016:	50                   	push   %eax
f0101017:	53                   	push   %ebx
f0101018:	ff 75 08             	pushl  0x8(%ebp)
f010101b:	e8 83 ff ff ff       	call   f0100fa3 <page_lookup>
    	if (pp == NULL) {    //va可能还没有映射，那就什么都不用做
f0101020:	83 c4 10             	add    $0x10,%esp
f0101023:	85 c0                	test   %eax,%eax
f0101025:	74 18                	je     f010103f <page_remove+0x36>
        	return;
    	}
   	page_decref(pp);    //将pp->pp_ref减1，如果pp->pp_ref为0，需要释放该PageInfo结构（将其放入page_free_list链表中）
f0101027:	83 ec 0c             	sub    $0xc,%esp
f010102a:	50                   	push   %eax
f010102b:	e8 34 fe ff ff       	call   f0100e64 <page_decref>
   	*pte_store = 0;    //将PTE清空
f0101030:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101033:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0101039:	0f 01 3b             	invlpg (%ebx)
f010103c:	83 c4 10             	add    $0x10,%esp
    	tlb_invalidate(pgdir, va); //失效化TLB缓存
}
f010103f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101042:	c9                   	leave  
f0101043:	c3                   	ret    

f0101044 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f0101044:	55                   	push   %ebp
f0101045:	89 e5                	mov    %esp,%ebp
f0101047:	57                   	push   %edi
f0101048:	56                   	push   %esi
f0101049:	53                   	push   %ebx
f010104a:	83 ec 10             	sub    $0x10,%esp
f010104d:	8b 75 08             	mov    0x8(%ebp),%esi
f0101050:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
	pte_t *pte = pgdir_walk(pgdir, va, 1);    //拿到va对应的PTE地址，如果va对应的页表还没有分配，则分配一个物理页作为页表
f0101053:	6a 01                	push   $0x1
f0101055:	ff 75 10             	pushl  0x10(%ebp)
f0101058:	56                   	push   %esi
f0101059:	e8 2d fe ff ff       	call   f0100e8b <pgdir_walk>
	if (pte == NULL) {
f010105e:	83 c4 10             	add    $0x10,%esp
f0101061:	85 c0                	test   %eax,%eax
f0101063:	74 44                	je     f01010a9 <page_insert+0x65>
f0101065:	89 c7                	mov    %eax,%edi
		return -E_NO_MEM;
	}
	pp->pp_ref++;                                       //引用加1
f0101067:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
	if ((*pte) & PTE_P) {                               //当前虚拟地址va已经被映射过，需要先释放
f010106c:	f6 00 01             	testb  $0x1,(%eax)
f010106f:	74 0f                	je     f0101080 <page_insert+0x3c>
		page_remove(pgdir, va); //这个函数目前还没实现
f0101071:	83 ec 08             	sub    $0x8,%esp
f0101074:	ff 75 10             	pushl  0x10(%ebp)
f0101077:	56                   	push   %esi
f0101078:	e8 8c ff ff ff       	call   f0101009 <page_remove>
f010107d:	83 c4 10             	add    $0x10,%esp
	}
	physaddr_t pa = page2pa(pp); //将PageInfo结构转换为对应物理页的首地址
	*pte = pa | perm | PTE_P;    //修改PTE
f0101080:	2b 1d 4c 79 11 f0    	sub    0xf011794c,%ebx
f0101086:	c1 fb 03             	sar    $0x3,%ebx
f0101089:	c1 e3 0c             	shl    $0xc,%ebx
f010108c:	8b 45 14             	mov    0x14(%ebp),%eax
f010108f:	83 c8 01             	or     $0x1,%eax
f0101092:	09 c3                	or     %eax,%ebx
f0101094:	89 1f                	mov    %ebx,(%edi)
	pgdir[PDX(va)] |= perm;
f0101096:	8b 45 10             	mov    0x10(%ebp),%eax
f0101099:	c1 e8 16             	shr    $0x16,%eax
f010109c:	8b 55 14             	mov    0x14(%ebp),%edx
f010109f:	09 14 86             	or     %edx,(%esi,%eax,4)

	return 0;
f01010a2:	b8 00 00 00 00       	mov    $0x0,%eax
f01010a7:	eb 05                	jmp    f01010ae <page_insert+0x6a>
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
	// Fill this function in
	pte_t *pte = pgdir_walk(pgdir, va, 1);    //拿到va对应的PTE地址，如果va对应的页表还没有分配，则分配一个物理页作为页表
	if (pte == NULL) {
		return -E_NO_MEM;
f01010a9:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	*pte = pa | perm | PTE_P;    //修改PTE
	pgdir[PDX(va)] |= perm;

	return 0;

}
f01010ae:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01010b1:	5b                   	pop    %ebx
f01010b2:	5e                   	pop    %esi
f01010b3:	5f                   	pop    %edi
f01010b4:	5d                   	pop    %ebp
f01010b5:	c3                   	ret    

f01010b6 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f01010b6:	55                   	push   %ebp
f01010b7:	89 e5                	mov    %esp,%ebp
f01010b9:	57                   	push   %edi
f01010ba:	56                   	push   %esi
f01010bb:	53                   	push   %ebx
f01010bc:	83 ec 2c             	sub    $0x2c,%esp
{
	size_t basemem, extmem, ext16mem, totalmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	basemem = nvram_read(NVRAM_BASELO);
f01010bf:	b8 15 00 00 00       	mov    $0x15,%eax
f01010c4:	e8 c9 f8 ff ff       	call   f0100992 <nvram_read>
f01010c9:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f01010cb:	b8 17 00 00 00       	mov    $0x17,%eax
f01010d0:	e8 bd f8 ff ff       	call   f0100992 <nvram_read>
f01010d5:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f01010d7:	b8 34 00 00 00       	mov    $0x34,%eax
f01010dc:	e8 b1 f8 ff ff       	call   f0100992 <nvram_read>
f01010e1:	c1 e0 06             	shl    $0x6,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (ext16mem)
f01010e4:	85 c0                	test   %eax,%eax
f01010e6:	74 07                	je     f01010ef <mem_init+0x39>
		totalmem = 16 * 1024 + ext16mem;
f01010e8:	05 00 40 00 00       	add    $0x4000,%eax
f01010ed:	eb 0b                	jmp    f01010fa <mem_init+0x44>
	else if (extmem)
		totalmem = 1 * 1024 + extmem;
f01010ef:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f01010f5:	85 f6                	test   %esi,%esi
f01010f7:	0f 44 c3             	cmove  %ebx,%eax
	else
		totalmem = basemem;

	npages = totalmem / (PGSIZE / 1024);
f01010fa:	89 c2                	mov    %eax,%edx
f01010fc:	c1 ea 02             	shr    $0x2,%edx
f01010ff:	89 15 44 79 11 f0    	mov    %edx,0xf0117944
	npages_basemem = basemem / (PGSIZE / 1024);

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101105:	89 c2                	mov    %eax,%edx
f0101107:	29 da                	sub    %ebx,%edx
f0101109:	52                   	push   %edx
f010110a:	53                   	push   %ebx
f010110b:	50                   	push   %eax
f010110c:	68 f0 3d 10 f0       	push   $0xf0103df0
f0101111:	e8 46 16 00 00       	call   f010275c <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0101116:	b8 00 10 00 00       	mov    $0x1000,%eax
f010111b:	e8 24 f8 ff ff       	call   f0100944 <boot_alloc>
f0101120:	a3 48 79 11 f0       	mov    %eax,0xf0117948
	memset(kern_pgdir, 0, PGSIZE);
f0101125:	83 c4 0c             	add    $0xc,%esp
f0101128:	68 00 10 00 00       	push   $0x1000
f010112d:	6a 00                	push   $0x0
f010112f:	50                   	push   %eax
f0101130:	e8 d0 20 00 00       	call   f0103205 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0101135:	a1 48 79 11 f0       	mov    0xf0117948,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010113a:	83 c4 10             	add    $0x10,%esp
f010113d:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101142:	77 15                	ja     f0101159 <mem_init+0xa3>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101144:	50                   	push   %eax
f0101145:	68 28 3d 10 f0       	push   $0xf0103d28
f010114a:	68 92 00 00 00       	push   $0x92
f010114f:	68 18 44 10 f0       	push   $0xf0104418
f0101154:	e8 32 ef ff ff       	call   f010008b <_panic>
f0101159:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f010115f:	83 ca 05             	or     $0x5,%edx
f0101162:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	pages = (struct PageInfo*)boot_alloc(sizeof(struct PageInfo) * npages); 
f0101168:	a1 44 79 11 f0       	mov    0xf0117944,%eax
f010116d:	c1 e0 03             	shl    $0x3,%eax
f0101170:	e8 cf f7 ff ff       	call   f0100944 <boot_alloc>
f0101175:	a3 4c 79 11 f0       	mov    %eax,0xf011794c
	memset(pages, 0, sizeof(struct PageInfo) * npages);
f010117a:	83 ec 04             	sub    $0x4,%esp
f010117d:	8b 0d 44 79 11 f0    	mov    0xf0117944,%ecx
f0101183:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f010118a:	52                   	push   %edx
f010118b:	6a 00                	push   $0x0
f010118d:	50                   	push   %eax
f010118e:	e8 72 20 00 00       	call   f0103205 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f0101193:	e8 4a fb ff ff       	call   f0100ce2 <page_init>

	check_page_free_list(1);
f0101198:	b8 01 00 00 00       	mov    $0x1,%eax
f010119d:	e8 7d f8 ff ff       	call   f0100a1f <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f01011a2:	83 c4 10             	add    $0x10,%esp
f01011a5:	83 3d 4c 79 11 f0 00 	cmpl   $0x0,0xf011794c
f01011ac:	75 17                	jne    f01011c5 <mem_init+0x10f>
		panic("'pages' is a null pointer!");
f01011ae:	83 ec 04             	sub    $0x4,%esp
f01011b1:	68 ce 44 10 f0       	push   $0xf01044ce
f01011b6:	68 5f 02 00 00       	push   $0x25f
f01011bb:	68 18 44 10 f0       	push   $0xf0104418
f01011c0:	e8 c6 ee ff ff       	call   f010008b <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01011c5:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f01011ca:	bb 00 00 00 00       	mov    $0x0,%ebx
f01011cf:	eb 05                	jmp    f01011d6 <mem_init+0x120>
		++nfree;
f01011d1:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01011d4:	8b 00                	mov    (%eax),%eax
f01011d6:	85 c0                	test   %eax,%eax
f01011d8:	75 f7                	jne    f01011d1 <mem_init+0x11b>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01011da:	83 ec 0c             	sub    $0xc,%esp
f01011dd:	6a 00                	push   $0x0
f01011df:	e8 be fb ff ff       	call   f0100da2 <page_alloc>
f01011e4:	89 c7                	mov    %eax,%edi
f01011e6:	83 c4 10             	add    $0x10,%esp
f01011e9:	85 c0                	test   %eax,%eax
f01011eb:	75 19                	jne    f0101206 <mem_init+0x150>
f01011ed:	68 e9 44 10 f0       	push   $0xf01044e9
f01011f2:	68 3e 44 10 f0       	push   $0xf010443e
f01011f7:	68 67 02 00 00       	push   $0x267
f01011fc:	68 18 44 10 f0       	push   $0xf0104418
f0101201:	e8 85 ee ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f0101206:	83 ec 0c             	sub    $0xc,%esp
f0101209:	6a 00                	push   $0x0
f010120b:	e8 92 fb ff ff       	call   f0100da2 <page_alloc>
f0101210:	89 c6                	mov    %eax,%esi
f0101212:	83 c4 10             	add    $0x10,%esp
f0101215:	85 c0                	test   %eax,%eax
f0101217:	75 19                	jne    f0101232 <mem_init+0x17c>
f0101219:	68 ff 44 10 f0       	push   $0xf01044ff
f010121e:	68 3e 44 10 f0       	push   $0xf010443e
f0101223:	68 68 02 00 00       	push   $0x268
f0101228:	68 18 44 10 f0       	push   $0xf0104418
f010122d:	e8 59 ee ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0101232:	83 ec 0c             	sub    $0xc,%esp
f0101235:	6a 00                	push   $0x0
f0101237:	e8 66 fb ff ff       	call   f0100da2 <page_alloc>
f010123c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010123f:	83 c4 10             	add    $0x10,%esp
f0101242:	85 c0                	test   %eax,%eax
f0101244:	75 19                	jne    f010125f <mem_init+0x1a9>
f0101246:	68 15 45 10 f0       	push   $0xf0104515
f010124b:	68 3e 44 10 f0       	push   $0xf010443e
f0101250:	68 69 02 00 00       	push   $0x269
f0101255:	68 18 44 10 f0       	push   $0xf0104418
f010125a:	e8 2c ee ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010125f:	39 f7                	cmp    %esi,%edi
f0101261:	75 19                	jne    f010127c <mem_init+0x1c6>
f0101263:	68 2b 45 10 f0       	push   $0xf010452b
f0101268:	68 3e 44 10 f0       	push   $0xf010443e
f010126d:	68 6c 02 00 00       	push   $0x26c
f0101272:	68 18 44 10 f0       	push   $0xf0104418
f0101277:	e8 0f ee ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010127c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010127f:	39 c6                	cmp    %eax,%esi
f0101281:	74 04                	je     f0101287 <mem_init+0x1d1>
f0101283:	39 c7                	cmp    %eax,%edi
f0101285:	75 19                	jne    f01012a0 <mem_init+0x1ea>
f0101287:	68 2c 3e 10 f0       	push   $0xf0103e2c
f010128c:	68 3e 44 10 f0       	push   $0xf010443e
f0101291:	68 6d 02 00 00       	push   $0x26d
f0101296:	68 18 44 10 f0       	push   $0xf0104418
f010129b:	e8 eb ed ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01012a0:	8b 0d 4c 79 11 f0    	mov    0xf011794c,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f01012a6:	8b 15 44 79 11 f0    	mov    0xf0117944,%edx
f01012ac:	c1 e2 0c             	shl    $0xc,%edx
f01012af:	89 f8                	mov    %edi,%eax
f01012b1:	29 c8                	sub    %ecx,%eax
f01012b3:	c1 f8 03             	sar    $0x3,%eax
f01012b6:	c1 e0 0c             	shl    $0xc,%eax
f01012b9:	39 d0                	cmp    %edx,%eax
f01012bb:	72 19                	jb     f01012d6 <mem_init+0x220>
f01012bd:	68 3d 45 10 f0       	push   $0xf010453d
f01012c2:	68 3e 44 10 f0       	push   $0xf010443e
f01012c7:	68 6e 02 00 00       	push   $0x26e
f01012cc:	68 18 44 10 f0       	push   $0xf0104418
f01012d1:	e8 b5 ed ff ff       	call   f010008b <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f01012d6:	89 f0                	mov    %esi,%eax
f01012d8:	29 c8                	sub    %ecx,%eax
f01012da:	c1 f8 03             	sar    $0x3,%eax
f01012dd:	c1 e0 0c             	shl    $0xc,%eax
f01012e0:	39 c2                	cmp    %eax,%edx
f01012e2:	77 19                	ja     f01012fd <mem_init+0x247>
f01012e4:	68 5a 45 10 f0       	push   $0xf010455a
f01012e9:	68 3e 44 10 f0       	push   $0xf010443e
f01012ee:	68 6f 02 00 00       	push   $0x26f
f01012f3:	68 18 44 10 f0       	push   $0xf0104418
f01012f8:	e8 8e ed ff ff       	call   f010008b <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f01012fd:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101300:	29 c8                	sub    %ecx,%eax
f0101302:	c1 f8 03             	sar    $0x3,%eax
f0101305:	c1 e0 0c             	shl    $0xc,%eax
f0101308:	39 c2                	cmp    %eax,%edx
f010130a:	77 19                	ja     f0101325 <mem_init+0x26f>
f010130c:	68 77 45 10 f0       	push   $0xf0104577
f0101311:	68 3e 44 10 f0       	push   $0xf010443e
f0101316:	68 70 02 00 00       	push   $0x270
f010131b:	68 18 44 10 f0       	push   $0xf0104418
f0101320:	e8 66 ed ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101325:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f010132a:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f010132d:	c7 05 3c 75 11 f0 00 	movl   $0x0,0xf011753c
f0101334:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101337:	83 ec 0c             	sub    $0xc,%esp
f010133a:	6a 00                	push   $0x0
f010133c:	e8 61 fa ff ff       	call   f0100da2 <page_alloc>
f0101341:	83 c4 10             	add    $0x10,%esp
f0101344:	85 c0                	test   %eax,%eax
f0101346:	74 19                	je     f0101361 <mem_init+0x2ab>
f0101348:	68 94 45 10 f0       	push   $0xf0104594
f010134d:	68 3e 44 10 f0       	push   $0xf010443e
f0101352:	68 77 02 00 00       	push   $0x277
f0101357:	68 18 44 10 f0       	push   $0xf0104418
f010135c:	e8 2a ed ff ff       	call   f010008b <_panic>

	// free and re-allocate?
	page_free(pp0);
f0101361:	83 ec 0c             	sub    $0xc,%esp
f0101364:	57                   	push   %edi
f0101365:	e8 bf fa ff ff       	call   f0100e29 <page_free>
	page_free(pp1);
f010136a:	89 34 24             	mov    %esi,(%esp)
f010136d:	e8 b7 fa ff ff       	call   f0100e29 <page_free>
	page_free(pp2);
f0101372:	83 c4 04             	add    $0x4,%esp
f0101375:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101378:	e8 ac fa ff ff       	call   f0100e29 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010137d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101384:	e8 19 fa ff ff       	call   f0100da2 <page_alloc>
f0101389:	89 c6                	mov    %eax,%esi
f010138b:	83 c4 10             	add    $0x10,%esp
f010138e:	85 c0                	test   %eax,%eax
f0101390:	75 19                	jne    f01013ab <mem_init+0x2f5>
f0101392:	68 e9 44 10 f0       	push   $0xf01044e9
f0101397:	68 3e 44 10 f0       	push   $0xf010443e
f010139c:	68 7e 02 00 00       	push   $0x27e
f01013a1:	68 18 44 10 f0       	push   $0xf0104418
f01013a6:	e8 e0 ec ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f01013ab:	83 ec 0c             	sub    $0xc,%esp
f01013ae:	6a 00                	push   $0x0
f01013b0:	e8 ed f9 ff ff       	call   f0100da2 <page_alloc>
f01013b5:	89 c7                	mov    %eax,%edi
f01013b7:	83 c4 10             	add    $0x10,%esp
f01013ba:	85 c0                	test   %eax,%eax
f01013bc:	75 19                	jne    f01013d7 <mem_init+0x321>
f01013be:	68 ff 44 10 f0       	push   $0xf01044ff
f01013c3:	68 3e 44 10 f0       	push   $0xf010443e
f01013c8:	68 7f 02 00 00       	push   $0x27f
f01013cd:	68 18 44 10 f0       	push   $0xf0104418
f01013d2:	e8 b4 ec ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f01013d7:	83 ec 0c             	sub    $0xc,%esp
f01013da:	6a 00                	push   $0x0
f01013dc:	e8 c1 f9 ff ff       	call   f0100da2 <page_alloc>
f01013e1:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01013e4:	83 c4 10             	add    $0x10,%esp
f01013e7:	85 c0                	test   %eax,%eax
f01013e9:	75 19                	jne    f0101404 <mem_init+0x34e>
f01013eb:	68 15 45 10 f0       	push   $0xf0104515
f01013f0:	68 3e 44 10 f0       	push   $0xf010443e
f01013f5:	68 80 02 00 00       	push   $0x280
f01013fa:	68 18 44 10 f0       	push   $0xf0104418
f01013ff:	e8 87 ec ff ff       	call   f010008b <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101404:	39 fe                	cmp    %edi,%esi
f0101406:	75 19                	jne    f0101421 <mem_init+0x36b>
f0101408:	68 2b 45 10 f0       	push   $0xf010452b
f010140d:	68 3e 44 10 f0       	push   $0xf010443e
f0101412:	68 82 02 00 00       	push   $0x282
f0101417:	68 18 44 10 f0       	push   $0xf0104418
f010141c:	e8 6a ec ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101421:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101424:	39 c6                	cmp    %eax,%esi
f0101426:	74 04                	je     f010142c <mem_init+0x376>
f0101428:	39 c7                	cmp    %eax,%edi
f010142a:	75 19                	jne    f0101445 <mem_init+0x38f>
f010142c:	68 2c 3e 10 f0       	push   $0xf0103e2c
f0101431:	68 3e 44 10 f0       	push   $0xf010443e
f0101436:	68 83 02 00 00       	push   $0x283
f010143b:	68 18 44 10 f0       	push   $0xf0104418
f0101440:	e8 46 ec ff ff       	call   f010008b <_panic>
	assert(!page_alloc(0));
f0101445:	83 ec 0c             	sub    $0xc,%esp
f0101448:	6a 00                	push   $0x0
f010144a:	e8 53 f9 ff ff       	call   f0100da2 <page_alloc>
f010144f:	83 c4 10             	add    $0x10,%esp
f0101452:	85 c0                	test   %eax,%eax
f0101454:	74 19                	je     f010146f <mem_init+0x3b9>
f0101456:	68 94 45 10 f0       	push   $0xf0104594
f010145b:	68 3e 44 10 f0       	push   $0xf010443e
f0101460:	68 84 02 00 00       	push   $0x284
f0101465:	68 18 44 10 f0       	push   $0xf0104418
f010146a:	e8 1c ec ff ff       	call   f010008b <_panic>
f010146f:	89 f0                	mov    %esi,%eax
f0101471:	2b 05 4c 79 11 f0    	sub    0xf011794c,%eax
f0101477:	c1 f8 03             	sar    $0x3,%eax
f010147a:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010147d:	89 c2                	mov    %eax,%edx
f010147f:	c1 ea 0c             	shr    $0xc,%edx
f0101482:	3b 15 44 79 11 f0    	cmp    0xf0117944,%edx
f0101488:	72 12                	jb     f010149c <mem_init+0x3e6>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010148a:	50                   	push   %eax
f010148b:	68 1c 3c 10 f0       	push   $0xf0103c1c
f0101490:	6a 52                	push   $0x52
f0101492:	68 24 44 10 f0       	push   $0xf0104424
f0101497:	e8 ef eb ff ff       	call   f010008b <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f010149c:	83 ec 04             	sub    $0x4,%esp
f010149f:	68 00 10 00 00       	push   $0x1000
f01014a4:	6a 01                	push   $0x1
f01014a6:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01014ab:	50                   	push   %eax
f01014ac:	e8 54 1d 00 00       	call   f0103205 <memset>
	page_free(pp0);
f01014b1:	89 34 24             	mov    %esi,(%esp)
f01014b4:	e8 70 f9 ff ff       	call   f0100e29 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01014b9:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01014c0:	e8 dd f8 ff ff       	call   f0100da2 <page_alloc>
f01014c5:	83 c4 10             	add    $0x10,%esp
f01014c8:	85 c0                	test   %eax,%eax
f01014ca:	75 19                	jne    f01014e5 <mem_init+0x42f>
f01014cc:	68 a3 45 10 f0       	push   $0xf01045a3
f01014d1:	68 3e 44 10 f0       	push   $0xf010443e
f01014d6:	68 89 02 00 00       	push   $0x289
f01014db:	68 18 44 10 f0       	push   $0xf0104418
f01014e0:	e8 a6 eb ff ff       	call   f010008b <_panic>
	assert(pp && pp0 == pp);
f01014e5:	39 c6                	cmp    %eax,%esi
f01014e7:	74 19                	je     f0101502 <mem_init+0x44c>
f01014e9:	68 c1 45 10 f0       	push   $0xf01045c1
f01014ee:	68 3e 44 10 f0       	push   $0xf010443e
f01014f3:	68 8a 02 00 00       	push   $0x28a
f01014f8:	68 18 44 10 f0       	push   $0xf0104418
f01014fd:	e8 89 eb ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101502:	89 f0                	mov    %esi,%eax
f0101504:	2b 05 4c 79 11 f0    	sub    0xf011794c,%eax
f010150a:	c1 f8 03             	sar    $0x3,%eax
f010150d:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101510:	89 c2                	mov    %eax,%edx
f0101512:	c1 ea 0c             	shr    $0xc,%edx
f0101515:	3b 15 44 79 11 f0    	cmp    0xf0117944,%edx
f010151b:	72 12                	jb     f010152f <mem_init+0x479>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010151d:	50                   	push   %eax
f010151e:	68 1c 3c 10 f0       	push   $0xf0103c1c
f0101523:	6a 52                	push   $0x52
f0101525:	68 24 44 10 f0       	push   $0xf0104424
f010152a:	e8 5c eb ff ff       	call   f010008b <_panic>
f010152f:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f0101535:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f010153b:	80 38 00             	cmpb   $0x0,(%eax)
f010153e:	74 19                	je     f0101559 <mem_init+0x4a3>
f0101540:	68 d1 45 10 f0       	push   $0xf01045d1
f0101545:	68 3e 44 10 f0       	push   $0xf010443e
f010154a:	68 8d 02 00 00       	push   $0x28d
f010154f:	68 18 44 10 f0       	push   $0xf0104418
f0101554:	e8 32 eb ff ff       	call   f010008b <_panic>
f0101559:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f010155c:	39 d0                	cmp    %edx,%eax
f010155e:	75 db                	jne    f010153b <mem_init+0x485>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101560:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101563:	a3 3c 75 11 f0       	mov    %eax,0xf011753c

	// free the pages we took
	page_free(pp0);
f0101568:	83 ec 0c             	sub    $0xc,%esp
f010156b:	56                   	push   %esi
f010156c:	e8 b8 f8 ff ff       	call   f0100e29 <page_free>
	page_free(pp1);
f0101571:	89 3c 24             	mov    %edi,(%esp)
f0101574:	e8 b0 f8 ff ff       	call   f0100e29 <page_free>
	page_free(pp2);
f0101579:	83 c4 04             	add    $0x4,%esp
f010157c:	ff 75 d4             	pushl  -0x2c(%ebp)
f010157f:	e8 a5 f8 ff ff       	call   f0100e29 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101584:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f0101589:	83 c4 10             	add    $0x10,%esp
f010158c:	eb 05                	jmp    f0101593 <mem_init+0x4dd>
		--nfree;
f010158e:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101591:	8b 00                	mov    (%eax),%eax
f0101593:	85 c0                	test   %eax,%eax
f0101595:	75 f7                	jne    f010158e <mem_init+0x4d8>
		--nfree;
	assert(nfree == 0);
f0101597:	85 db                	test   %ebx,%ebx
f0101599:	74 19                	je     f01015b4 <mem_init+0x4fe>
f010159b:	68 db 45 10 f0       	push   $0xf01045db
f01015a0:	68 3e 44 10 f0       	push   $0xf010443e
f01015a5:	68 9a 02 00 00       	push   $0x29a
f01015aa:	68 18 44 10 f0       	push   $0xf0104418
f01015af:	e8 d7 ea ff ff       	call   f010008b <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f01015b4:	83 ec 0c             	sub    $0xc,%esp
f01015b7:	68 4c 3e 10 f0       	push   $0xf0103e4c
f01015bc:	e8 9b 11 00 00       	call   f010275c <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01015c1:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01015c8:	e8 d5 f7 ff ff       	call   f0100da2 <page_alloc>
f01015cd:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01015d0:	83 c4 10             	add    $0x10,%esp
f01015d3:	85 c0                	test   %eax,%eax
f01015d5:	75 19                	jne    f01015f0 <mem_init+0x53a>
f01015d7:	68 e9 44 10 f0       	push   $0xf01044e9
f01015dc:	68 3e 44 10 f0       	push   $0xf010443e
f01015e1:	68 f3 02 00 00       	push   $0x2f3
f01015e6:	68 18 44 10 f0       	push   $0xf0104418
f01015eb:	e8 9b ea ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f01015f0:	83 ec 0c             	sub    $0xc,%esp
f01015f3:	6a 00                	push   $0x0
f01015f5:	e8 a8 f7 ff ff       	call   f0100da2 <page_alloc>
f01015fa:	89 c3                	mov    %eax,%ebx
f01015fc:	83 c4 10             	add    $0x10,%esp
f01015ff:	85 c0                	test   %eax,%eax
f0101601:	75 19                	jne    f010161c <mem_init+0x566>
f0101603:	68 ff 44 10 f0       	push   $0xf01044ff
f0101608:	68 3e 44 10 f0       	push   $0xf010443e
f010160d:	68 f4 02 00 00       	push   $0x2f4
f0101612:	68 18 44 10 f0       	push   $0xf0104418
f0101617:	e8 6f ea ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f010161c:	83 ec 0c             	sub    $0xc,%esp
f010161f:	6a 00                	push   $0x0
f0101621:	e8 7c f7 ff ff       	call   f0100da2 <page_alloc>
f0101626:	89 c6                	mov    %eax,%esi
f0101628:	83 c4 10             	add    $0x10,%esp
f010162b:	85 c0                	test   %eax,%eax
f010162d:	75 19                	jne    f0101648 <mem_init+0x592>
f010162f:	68 15 45 10 f0       	push   $0xf0104515
f0101634:	68 3e 44 10 f0       	push   $0xf010443e
f0101639:	68 f5 02 00 00       	push   $0x2f5
f010163e:	68 18 44 10 f0       	push   $0xf0104418
f0101643:	e8 43 ea ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101648:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f010164b:	75 19                	jne    f0101666 <mem_init+0x5b0>
f010164d:	68 2b 45 10 f0       	push   $0xf010452b
f0101652:	68 3e 44 10 f0       	push   $0xf010443e
f0101657:	68 f8 02 00 00       	push   $0x2f8
f010165c:	68 18 44 10 f0       	push   $0xf0104418
f0101661:	e8 25 ea ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101666:	39 c3                	cmp    %eax,%ebx
f0101668:	74 05                	je     f010166f <mem_init+0x5b9>
f010166a:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f010166d:	75 19                	jne    f0101688 <mem_init+0x5d2>
f010166f:	68 2c 3e 10 f0       	push   $0xf0103e2c
f0101674:	68 3e 44 10 f0       	push   $0xf010443e
f0101679:	68 f9 02 00 00       	push   $0x2f9
f010167e:	68 18 44 10 f0       	push   $0xf0104418
f0101683:	e8 03 ea ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101688:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f010168d:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101690:	c7 05 3c 75 11 f0 00 	movl   $0x0,0xf011753c
f0101697:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f010169a:	83 ec 0c             	sub    $0xc,%esp
f010169d:	6a 00                	push   $0x0
f010169f:	e8 fe f6 ff ff       	call   f0100da2 <page_alloc>
f01016a4:	83 c4 10             	add    $0x10,%esp
f01016a7:	85 c0                	test   %eax,%eax
f01016a9:	74 19                	je     f01016c4 <mem_init+0x60e>
f01016ab:	68 94 45 10 f0       	push   $0xf0104594
f01016b0:	68 3e 44 10 f0       	push   $0xf010443e
f01016b5:	68 00 03 00 00       	push   $0x300
f01016ba:	68 18 44 10 f0       	push   $0xf0104418
f01016bf:	e8 c7 e9 ff ff       	call   f010008b <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f01016c4:	83 ec 04             	sub    $0x4,%esp
f01016c7:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01016ca:	50                   	push   %eax
f01016cb:	6a 00                	push   $0x0
f01016cd:	ff 35 48 79 11 f0    	pushl  0xf0117948
f01016d3:	e8 cb f8 ff ff       	call   f0100fa3 <page_lookup>
f01016d8:	83 c4 10             	add    $0x10,%esp
f01016db:	85 c0                	test   %eax,%eax
f01016dd:	74 19                	je     f01016f8 <mem_init+0x642>
f01016df:	68 6c 3e 10 f0       	push   $0xf0103e6c
f01016e4:	68 3e 44 10 f0       	push   $0xf010443e
f01016e9:	68 03 03 00 00       	push   $0x303
f01016ee:	68 18 44 10 f0       	push   $0xf0104418
f01016f3:	e8 93 e9 ff ff       	call   f010008b <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f01016f8:	6a 02                	push   $0x2
f01016fa:	6a 00                	push   $0x0
f01016fc:	53                   	push   %ebx
f01016fd:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0101703:	e8 3c f9 ff ff       	call   f0101044 <page_insert>
f0101708:	83 c4 10             	add    $0x10,%esp
f010170b:	85 c0                	test   %eax,%eax
f010170d:	78 19                	js     f0101728 <mem_init+0x672>
f010170f:	68 a4 3e 10 f0       	push   $0xf0103ea4
f0101714:	68 3e 44 10 f0       	push   $0xf010443e
f0101719:	68 06 03 00 00       	push   $0x306
f010171e:	68 18 44 10 f0       	push   $0xf0104418
f0101723:	e8 63 e9 ff ff       	call   f010008b <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101728:	83 ec 0c             	sub    $0xc,%esp
f010172b:	ff 75 d4             	pushl  -0x2c(%ebp)
f010172e:	e8 f6 f6 ff ff       	call   f0100e29 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101733:	6a 02                	push   $0x2
f0101735:	6a 00                	push   $0x0
f0101737:	53                   	push   %ebx
f0101738:	ff 35 48 79 11 f0    	pushl  0xf0117948
f010173e:	e8 01 f9 ff ff       	call   f0101044 <page_insert>
f0101743:	83 c4 20             	add    $0x20,%esp
f0101746:	85 c0                	test   %eax,%eax
f0101748:	74 19                	je     f0101763 <mem_init+0x6ad>
f010174a:	68 d4 3e 10 f0       	push   $0xf0103ed4
f010174f:	68 3e 44 10 f0       	push   $0xf010443e
f0101754:	68 0a 03 00 00       	push   $0x30a
f0101759:	68 18 44 10 f0       	push   $0xf0104418
f010175e:	e8 28 e9 ff ff       	call   f010008b <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101763:	8b 3d 48 79 11 f0    	mov    0xf0117948,%edi
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101769:	a1 4c 79 11 f0       	mov    0xf011794c,%eax
f010176e:	89 c1                	mov    %eax,%ecx
f0101770:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101773:	8b 17                	mov    (%edi),%edx
f0101775:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010177b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010177e:	29 c8                	sub    %ecx,%eax
f0101780:	c1 f8 03             	sar    $0x3,%eax
f0101783:	c1 e0 0c             	shl    $0xc,%eax
f0101786:	39 c2                	cmp    %eax,%edx
f0101788:	74 19                	je     f01017a3 <mem_init+0x6ed>
f010178a:	68 04 3f 10 f0       	push   $0xf0103f04
f010178f:	68 3e 44 10 f0       	push   $0xf010443e
f0101794:	68 0b 03 00 00       	push   $0x30b
f0101799:	68 18 44 10 f0       	push   $0xf0104418
f010179e:	e8 e8 e8 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f01017a3:	ba 00 00 00 00       	mov    $0x0,%edx
f01017a8:	89 f8                	mov    %edi,%eax
f01017aa:	e8 0c f2 ff ff       	call   f01009bb <check_va2pa>
f01017af:	89 da                	mov    %ebx,%edx
f01017b1:	2b 55 cc             	sub    -0x34(%ebp),%edx
f01017b4:	c1 fa 03             	sar    $0x3,%edx
f01017b7:	c1 e2 0c             	shl    $0xc,%edx
f01017ba:	39 d0                	cmp    %edx,%eax
f01017bc:	74 19                	je     f01017d7 <mem_init+0x721>
f01017be:	68 2c 3f 10 f0       	push   $0xf0103f2c
f01017c3:	68 3e 44 10 f0       	push   $0xf010443e
f01017c8:	68 0c 03 00 00       	push   $0x30c
f01017cd:	68 18 44 10 f0       	push   $0xf0104418
f01017d2:	e8 b4 e8 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 1);
f01017d7:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01017dc:	74 19                	je     f01017f7 <mem_init+0x741>
f01017de:	68 e6 45 10 f0       	push   $0xf01045e6
f01017e3:	68 3e 44 10 f0       	push   $0xf010443e
f01017e8:	68 0d 03 00 00       	push   $0x30d
f01017ed:	68 18 44 10 f0       	push   $0xf0104418
f01017f2:	e8 94 e8 ff ff       	call   f010008b <_panic>
	assert(pp0->pp_ref == 1);
f01017f7:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01017fa:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f01017ff:	74 19                	je     f010181a <mem_init+0x764>
f0101801:	68 f7 45 10 f0       	push   $0xf01045f7
f0101806:	68 3e 44 10 f0       	push   $0xf010443e
f010180b:	68 0e 03 00 00       	push   $0x30e
f0101810:	68 18 44 10 f0       	push   $0xf0104418
f0101815:	e8 71 e8 ff ff       	call   f010008b <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f010181a:	6a 02                	push   $0x2
f010181c:	68 00 10 00 00       	push   $0x1000
f0101821:	56                   	push   %esi
f0101822:	57                   	push   %edi
f0101823:	e8 1c f8 ff ff       	call   f0101044 <page_insert>
f0101828:	83 c4 10             	add    $0x10,%esp
f010182b:	85 c0                	test   %eax,%eax
f010182d:	74 19                	je     f0101848 <mem_init+0x792>
f010182f:	68 5c 3f 10 f0       	push   $0xf0103f5c
f0101834:	68 3e 44 10 f0       	push   $0xf010443e
f0101839:	68 11 03 00 00       	push   $0x311
f010183e:	68 18 44 10 f0       	push   $0xf0104418
f0101843:	e8 43 e8 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101848:	ba 00 10 00 00       	mov    $0x1000,%edx
f010184d:	a1 48 79 11 f0       	mov    0xf0117948,%eax
f0101852:	e8 64 f1 ff ff       	call   f01009bb <check_va2pa>
f0101857:	89 f2                	mov    %esi,%edx
f0101859:	2b 15 4c 79 11 f0    	sub    0xf011794c,%edx
f010185f:	c1 fa 03             	sar    $0x3,%edx
f0101862:	c1 e2 0c             	shl    $0xc,%edx
f0101865:	39 d0                	cmp    %edx,%eax
f0101867:	74 19                	je     f0101882 <mem_init+0x7cc>
f0101869:	68 98 3f 10 f0       	push   $0xf0103f98
f010186e:	68 3e 44 10 f0       	push   $0xf010443e
f0101873:	68 12 03 00 00       	push   $0x312
f0101878:	68 18 44 10 f0       	push   $0xf0104418
f010187d:	e8 09 e8 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f0101882:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101887:	74 19                	je     f01018a2 <mem_init+0x7ec>
f0101889:	68 08 46 10 f0       	push   $0xf0104608
f010188e:	68 3e 44 10 f0       	push   $0xf010443e
f0101893:	68 13 03 00 00       	push   $0x313
f0101898:	68 18 44 10 f0       	push   $0xf0104418
f010189d:	e8 e9 e7 ff ff       	call   f010008b <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f01018a2:	83 ec 0c             	sub    $0xc,%esp
f01018a5:	6a 00                	push   $0x0
f01018a7:	e8 f6 f4 ff ff       	call   f0100da2 <page_alloc>
f01018ac:	83 c4 10             	add    $0x10,%esp
f01018af:	85 c0                	test   %eax,%eax
f01018b1:	74 19                	je     f01018cc <mem_init+0x816>
f01018b3:	68 94 45 10 f0       	push   $0xf0104594
f01018b8:	68 3e 44 10 f0       	push   $0xf010443e
f01018bd:	68 16 03 00 00       	push   $0x316
f01018c2:	68 18 44 10 f0       	push   $0xf0104418
f01018c7:	e8 bf e7 ff ff       	call   f010008b <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01018cc:	6a 02                	push   $0x2
f01018ce:	68 00 10 00 00       	push   $0x1000
f01018d3:	56                   	push   %esi
f01018d4:	ff 35 48 79 11 f0    	pushl  0xf0117948
f01018da:	e8 65 f7 ff ff       	call   f0101044 <page_insert>
f01018df:	83 c4 10             	add    $0x10,%esp
f01018e2:	85 c0                	test   %eax,%eax
f01018e4:	74 19                	je     f01018ff <mem_init+0x849>
f01018e6:	68 5c 3f 10 f0       	push   $0xf0103f5c
f01018eb:	68 3e 44 10 f0       	push   $0xf010443e
f01018f0:	68 19 03 00 00       	push   $0x319
f01018f5:	68 18 44 10 f0       	push   $0xf0104418
f01018fa:	e8 8c e7 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01018ff:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101904:	a1 48 79 11 f0       	mov    0xf0117948,%eax
f0101909:	e8 ad f0 ff ff       	call   f01009bb <check_va2pa>
f010190e:	89 f2                	mov    %esi,%edx
f0101910:	2b 15 4c 79 11 f0    	sub    0xf011794c,%edx
f0101916:	c1 fa 03             	sar    $0x3,%edx
f0101919:	c1 e2 0c             	shl    $0xc,%edx
f010191c:	39 d0                	cmp    %edx,%eax
f010191e:	74 19                	je     f0101939 <mem_init+0x883>
f0101920:	68 98 3f 10 f0       	push   $0xf0103f98
f0101925:	68 3e 44 10 f0       	push   $0xf010443e
f010192a:	68 1a 03 00 00       	push   $0x31a
f010192f:	68 18 44 10 f0       	push   $0xf0104418
f0101934:	e8 52 e7 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f0101939:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f010193e:	74 19                	je     f0101959 <mem_init+0x8a3>
f0101940:	68 08 46 10 f0       	push   $0xf0104608
f0101945:	68 3e 44 10 f0       	push   $0xf010443e
f010194a:	68 1b 03 00 00       	push   $0x31b
f010194f:	68 18 44 10 f0       	push   $0xf0104418
f0101954:	e8 32 e7 ff ff       	call   f010008b <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101959:	83 ec 0c             	sub    $0xc,%esp
f010195c:	6a 00                	push   $0x0
f010195e:	e8 3f f4 ff ff       	call   f0100da2 <page_alloc>
f0101963:	83 c4 10             	add    $0x10,%esp
f0101966:	85 c0                	test   %eax,%eax
f0101968:	74 19                	je     f0101983 <mem_init+0x8cd>
f010196a:	68 94 45 10 f0       	push   $0xf0104594
f010196f:	68 3e 44 10 f0       	push   $0xf010443e
f0101974:	68 1f 03 00 00       	push   $0x31f
f0101979:	68 18 44 10 f0       	push   $0xf0104418
f010197e:	e8 08 e7 ff ff       	call   f010008b <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101983:	8b 15 48 79 11 f0    	mov    0xf0117948,%edx
f0101989:	8b 02                	mov    (%edx),%eax
f010198b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101990:	89 c1                	mov    %eax,%ecx
f0101992:	c1 e9 0c             	shr    $0xc,%ecx
f0101995:	3b 0d 44 79 11 f0    	cmp    0xf0117944,%ecx
f010199b:	72 15                	jb     f01019b2 <mem_init+0x8fc>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010199d:	50                   	push   %eax
f010199e:	68 1c 3c 10 f0       	push   $0xf0103c1c
f01019a3:	68 22 03 00 00       	push   $0x322
f01019a8:	68 18 44 10 f0       	push   $0xf0104418
f01019ad:	e8 d9 e6 ff ff       	call   f010008b <_panic>
f01019b2:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01019b7:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f01019ba:	83 ec 04             	sub    $0x4,%esp
f01019bd:	6a 00                	push   $0x0
f01019bf:	68 00 10 00 00       	push   $0x1000
f01019c4:	52                   	push   %edx
f01019c5:	e8 c1 f4 ff ff       	call   f0100e8b <pgdir_walk>
f01019ca:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f01019cd:	8d 51 04             	lea    0x4(%ecx),%edx
f01019d0:	83 c4 10             	add    $0x10,%esp
f01019d3:	39 d0                	cmp    %edx,%eax
f01019d5:	74 19                	je     f01019f0 <mem_init+0x93a>
f01019d7:	68 c8 3f 10 f0       	push   $0xf0103fc8
f01019dc:	68 3e 44 10 f0       	push   $0xf010443e
f01019e1:	68 23 03 00 00       	push   $0x323
f01019e6:	68 18 44 10 f0       	push   $0xf0104418
f01019eb:	e8 9b e6 ff ff       	call   f010008b <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f01019f0:	6a 06                	push   $0x6
f01019f2:	68 00 10 00 00       	push   $0x1000
f01019f7:	56                   	push   %esi
f01019f8:	ff 35 48 79 11 f0    	pushl  0xf0117948
f01019fe:	e8 41 f6 ff ff       	call   f0101044 <page_insert>
f0101a03:	83 c4 10             	add    $0x10,%esp
f0101a06:	85 c0                	test   %eax,%eax
f0101a08:	74 19                	je     f0101a23 <mem_init+0x96d>
f0101a0a:	68 08 40 10 f0       	push   $0xf0104008
f0101a0f:	68 3e 44 10 f0       	push   $0xf010443e
f0101a14:	68 26 03 00 00       	push   $0x326
f0101a19:	68 18 44 10 f0       	push   $0xf0104418
f0101a1e:	e8 68 e6 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101a23:	8b 3d 48 79 11 f0    	mov    0xf0117948,%edi
f0101a29:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101a2e:	89 f8                	mov    %edi,%eax
f0101a30:	e8 86 ef ff ff       	call   f01009bb <check_va2pa>
f0101a35:	89 f2                	mov    %esi,%edx
f0101a37:	2b 15 4c 79 11 f0    	sub    0xf011794c,%edx
f0101a3d:	c1 fa 03             	sar    $0x3,%edx
f0101a40:	c1 e2 0c             	shl    $0xc,%edx
f0101a43:	39 d0                	cmp    %edx,%eax
f0101a45:	74 19                	je     f0101a60 <mem_init+0x9aa>
f0101a47:	68 98 3f 10 f0       	push   $0xf0103f98
f0101a4c:	68 3e 44 10 f0       	push   $0xf010443e
f0101a51:	68 27 03 00 00       	push   $0x327
f0101a56:	68 18 44 10 f0       	push   $0xf0104418
f0101a5b:	e8 2b e6 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f0101a60:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101a65:	74 19                	je     f0101a80 <mem_init+0x9ca>
f0101a67:	68 08 46 10 f0       	push   $0xf0104608
f0101a6c:	68 3e 44 10 f0       	push   $0xf010443e
f0101a71:	68 28 03 00 00       	push   $0x328
f0101a76:	68 18 44 10 f0       	push   $0xf0104418
f0101a7b:	e8 0b e6 ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101a80:	83 ec 04             	sub    $0x4,%esp
f0101a83:	6a 00                	push   $0x0
f0101a85:	68 00 10 00 00       	push   $0x1000
f0101a8a:	57                   	push   %edi
f0101a8b:	e8 fb f3 ff ff       	call   f0100e8b <pgdir_walk>
f0101a90:	83 c4 10             	add    $0x10,%esp
f0101a93:	f6 00 04             	testb  $0x4,(%eax)
f0101a96:	75 19                	jne    f0101ab1 <mem_init+0x9fb>
f0101a98:	68 48 40 10 f0       	push   $0xf0104048
f0101a9d:	68 3e 44 10 f0       	push   $0xf010443e
f0101aa2:	68 29 03 00 00       	push   $0x329
f0101aa7:	68 18 44 10 f0       	push   $0xf0104418
f0101aac:	e8 da e5 ff ff       	call   f010008b <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101ab1:	a1 48 79 11 f0       	mov    0xf0117948,%eax
f0101ab6:	f6 00 04             	testb  $0x4,(%eax)
f0101ab9:	75 19                	jne    f0101ad4 <mem_init+0xa1e>
f0101abb:	68 19 46 10 f0       	push   $0xf0104619
f0101ac0:	68 3e 44 10 f0       	push   $0xf010443e
f0101ac5:	68 2a 03 00 00       	push   $0x32a
f0101aca:	68 18 44 10 f0       	push   $0xf0104418
f0101acf:	e8 b7 e5 ff ff       	call   f010008b <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101ad4:	6a 02                	push   $0x2
f0101ad6:	68 00 10 00 00       	push   $0x1000
f0101adb:	56                   	push   %esi
f0101adc:	50                   	push   %eax
f0101add:	e8 62 f5 ff ff       	call   f0101044 <page_insert>
f0101ae2:	83 c4 10             	add    $0x10,%esp
f0101ae5:	85 c0                	test   %eax,%eax
f0101ae7:	74 19                	je     f0101b02 <mem_init+0xa4c>
f0101ae9:	68 5c 3f 10 f0       	push   $0xf0103f5c
f0101aee:	68 3e 44 10 f0       	push   $0xf010443e
f0101af3:	68 2d 03 00 00       	push   $0x32d
f0101af8:	68 18 44 10 f0       	push   $0xf0104418
f0101afd:	e8 89 e5 ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101b02:	83 ec 04             	sub    $0x4,%esp
f0101b05:	6a 00                	push   $0x0
f0101b07:	68 00 10 00 00       	push   $0x1000
f0101b0c:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0101b12:	e8 74 f3 ff ff       	call   f0100e8b <pgdir_walk>
f0101b17:	83 c4 10             	add    $0x10,%esp
f0101b1a:	f6 00 02             	testb  $0x2,(%eax)
f0101b1d:	75 19                	jne    f0101b38 <mem_init+0xa82>
f0101b1f:	68 7c 40 10 f0       	push   $0xf010407c
f0101b24:	68 3e 44 10 f0       	push   $0xf010443e
f0101b29:	68 2e 03 00 00       	push   $0x32e
f0101b2e:	68 18 44 10 f0       	push   $0xf0104418
f0101b33:	e8 53 e5 ff ff       	call   f010008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101b38:	83 ec 04             	sub    $0x4,%esp
f0101b3b:	6a 00                	push   $0x0
f0101b3d:	68 00 10 00 00       	push   $0x1000
f0101b42:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0101b48:	e8 3e f3 ff ff       	call   f0100e8b <pgdir_walk>
f0101b4d:	83 c4 10             	add    $0x10,%esp
f0101b50:	f6 00 04             	testb  $0x4,(%eax)
f0101b53:	74 19                	je     f0101b6e <mem_init+0xab8>
f0101b55:	68 b0 40 10 f0       	push   $0xf01040b0
f0101b5a:	68 3e 44 10 f0       	push   $0xf010443e
f0101b5f:	68 2f 03 00 00       	push   $0x32f
f0101b64:	68 18 44 10 f0       	push   $0xf0104418
f0101b69:	e8 1d e5 ff ff       	call   f010008b <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101b6e:	6a 02                	push   $0x2
f0101b70:	68 00 00 40 00       	push   $0x400000
f0101b75:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101b78:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0101b7e:	e8 c1 f4 ff ff       	call   f0101044 <page_insert>
f0101b83:	83 c4 10             	add    $0x10,%esp
f0101b86:	85 c0                	test   %eax,%eax
f0101b88:	78 19                	js     f0101ba3 <mem_init+0xaed>
f0101b8a:	68 e8 40 10 f0       	push   $0xf01040e8
f0101b8f:	68 3e 44 10 f0       	push   $0xf010443e
f0101b94:	68 32 03 00 00       	push   $0x332
f0101b99:	68 18 44 10 f0       	push   $0xf0104418
f0101b9e:	e8 e8 e4 ff ff       	call   f010008b <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101ba3:	6a 02                	push   $0x2
f0101ba5:	68 00 10 00 00       	push   $0x1000
f0101baa:	53                   	push   %ebx
f0101bab:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0101bb1:	e8 8e f4 ff ff       	call   f0101044 <page_insert>
f0101bb6:	83 c4 10             	add    $0x10,%esp
f0101bb9:	85 c0                	test   %eax,%eax
f0101bbb:	74 19                	je     f0101bd6 <mem_init+0xb20>
f0101bbd:	68 20 41 10 f0       	push   $0xf0104120
f0101bc2:	68 3e 44 10 f0       	push   $0xf010443e
f0101bc7:	68 35 03 00 00       	push   $0x335
f0101bcc:	68 18 44 10 f0       	push   $0xf0104418
f0101bd1:	e8 b5 e4 ff ff       	call   f010008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101bd6:	83 ec 04             	sub    $0x4,%esp
f0101bd9:	6a 00                	push   $0x0
f0101bdb:	68 00 10 00 00       	push   $0x1000
f0101be0:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0101be6:	e8 a0 f2 ff ff       	call   f0100e8b <pgdir_walk>
f0101beb:	83 c4 10             	add    $0x10,%esp
f0101bee:	f6 00 04             	testb  $0x4,(%eax)
f0101bf1:	74 19                	je     f0101c0c <mem_init+0xb56>
f0101bf3:	68 b0 40 10 f0       	push   $0xf01040b0
f0101bf8:	68 3e 44 10 f0       	push   $0xf010443e
f0101bfd:	68 36 03 00 00       	push   $0x336
f0101c02:	68 18 44 10 f0       	push   $0xf0104418
f0101c07:	e8 7f e4 ff ff       	call   f010008b <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101c0c:	8b 3d 48 79 11 f0    	mov    0xf0117948,%edi
f0101c12:	ba 00 00 00 00       	mov    $0x0,%edx
f0101c17:	89 f8                	mov    %edi,%eax
f0101c19:	e8 9d ed ff ff       	call   f01009bb <check_va2pa>
f0101c1e:	89 c1                	mov    %eax,%ecx
f0101c20:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101c23:	89 d8                	mov    %ebx,%eax
f0101c25:	2b 05 4c 79 11 f0    	sub    0xf011794c,%eax
f0101c2b:	c1 f8 03             	sar    $0x3,%eax
f0101c2e:	c1 e0 0c             	shl    $0xc,%eax
f0101c31:	39 c1                	cmp    %eax,%ecx
f0101c33:	74 19                	je     f0101c4e <mem_init+0xb98>
f0101c35:	68 5c 41 10 f0       	push   $0xf010415c
f0101c3a:	68 3e 44 10 f0       	push   $0xf010443e
f0101c3f:	68 39 03 00 00       	push   $0x339
f0101c44:	68 18 44 10 f0       	push   $0xf0104418
f0101c49:	e8 3d e4 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101c4e:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c53:	89 f8                	mov    %edi,%eax
f0101c55:	e8 61 ed ff ff       	call   f01009bb <check_va2pa>
f0101c5a:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101c5d:	74 19                	je     f0101c78 <mem_init+0xbc2>
f0101c5f:	68 88 41 10 f0       	push   $0xf0104188
f0101c64:	68 3e 44 10 f0       	push   $0xf010443e
f0101c69:	68 3a 03 00 00       	push   $0x33a
f0101c6e:	68 18 44 10 f0       	push   $0xf0104418
f0101c73:	e8 13 e4 ff ff       	call   f010008b <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101c78:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101c7d:	74 19                	je     f0101c98 <mem_init+0xbe2>
f0101c7f:	68 2f 46 10 f0       	push   $0xf010462f
f0101c84:	68 3e 44 10 f0       	push   $0xf010443e
f0101c89:	68 3c 03 00 00       	push   $0x33c
f0101c8e:	68 18 44 10 f0       	push   $0xf0104418
f0101c93:	e8 f3 e3 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101c98:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101c9d:	74 19                	je     f0101cb8 <mem_init+0xc02>
f0101c9f:	68 40 46 10 f0       	push   $0xf0104640
f0101ca4:	68 3e 44 10 f0       	push   $0xf010443e
f0101ca9:	68 3d 03 00 00       	push   $0x33d
f0101cae:	68 18 44 10 f0       	push   $0xf0104418
f0101cb3:	e8 d3 e3 ff ff       	call   f010008b <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101cb8:	83 ec 0c             	sub    $0xc,%esp
f0101cbb:	6a 00                	push   $0x0
f0101cbd:	e8 e0 f0 ff ff       	call   f0100da2 <page_alloc>
f0101cc2:	83 c4 10             	add    $0x10,%esp
f0101cc5:	39 c6                	cmp    %eax,%esi
f0101cc7:	75 04                	jne    f0101ccd <mem_init+0xc17>
f0101cc9:	85 c0                	test   %eax,%eax
f0101ccb:	75 19                	jne    f0101ce6 <mem_init+0xc30>
f0101ccd:	68 b8 41 10 f0       	push   $0xf01041b8
f0101cd2:	68 3e 44 10 f0       	push   $0xf010443e
f0101cd7:	68 40 03 00 00       	push   $0x340
f0101cdc:	68 18 44 10 f0       	push   $0xf0104418
f0101ce1:	e8 a5 e3 ff ff       	call   f010008b <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101ce6:	83 ec 08             	sub    $0x8,%esp
f0101ce9:	6a 00                	push   $0x0
f0101ceb:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0101cf1:	e8 13 f3 ff ff       	call   f0101009 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101cf6:	8b 3d 48 79 11 f0    	mov    0xf0117948,%edi
f0101cfc:	ba 00 00 00 00       	mov    $0x0,%edx
f0101d01:	89 f8                	mov    %edi,%eax
f0101d03:	e8 b3 ec ff ff       	call   f01009bb <check_va2pa>
f0101d08:	83 c4 10             	add    $0x10,%esp
f0101d0b:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101d0e:	74 19                	je     f0101d29 <mem_init+0xc73>
f0101d10:	68 dc 41 10 f0       	push   $0xf01041dc
f0101d15:	68 3e 44 10 f0       	push   $0xf010443e
f0101d1a:	68 44 03 00 00       	push   $0x344
f0101d1f:	68 18 44 10 f0       	push   $0xf0104418
f0101d24:	e8 62 e3 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101d29:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101d2e:	89 f8                	mov    %edi,%eax
f0101d30:	e8 86 ec ff ff       	call   f01009bb <check_va2pa>
f0101d35:	89 da                	mov    %ebx,%edx
f0101d37:	2b 15 4c 79 11 f0    	sub    0xf011794c,%edx
f0101d3d:	c1 fa 03             	sar    $0x3,%edx
f0101d40:	c1 e2 0c             	shl    $0xc,%edx
f0101d43:	39 d0                	cmp    %edx,%eax
f0101d45:	74 19                	je     f0101d60 <mem_init+0xcaa>
f0101d47:	68 88 41 10 f0       	push   $0xf0104188
f0101d4c:	68 3e 44 10 f0       	push   $0xf010443e
f0101d51:	68 45 03 00 00       	push   $0x345
f0101d56:	68 18 44 10 f0       	push   $0xf0104418
f0101d5b:	e8 2b e3 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 1);
f0101d60:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101d65:	74 19                	je     f0101d80 <mem_init+0xcca>
f0101d67:	68 e6 45 10 f0       	push   $0xf01045e6
f0101d6c:	68 3e 44 10 f0       	push   $0xf010443e
f0101d71:	68 46 03 00 00       	push   $0x346
f0101d76:	68 18 44 10 f0       	push   $0xf0104418
f0101d7b:	e8 0b e3 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101d80:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101d85:	74 19                	je     f0101da0 <mem_init+0xcea>
f0101d87:	68 40 46 10 f0       	push   $0xf0104640
f0101d8c:	68 3e 44 10 f0       	push   $0xf010443e
f0101d91:	68 47 03 00 00       	push   $0x347
f0101d96:	68 18 44 10 f0       	push   $0xf0104418
f0101d9b:	e8 eb e2 ff ff       	call   f010008b <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101da0:	6a 00                	push   $0x0
f0101da2:	68 00 10 00 00       	push   $0x1000
f0101da7:	53                   	push   %ebx
f0101da8:	57                   	push   %edi
f0101da9:	e8 96 f2 ff ff       	call   f0101044 <page_insert>
f0101dae:	83 c4 10             	add    $0x10,%esp
f0101db1:	85 c0                	test   %eax,%eax
f0101db3:	74 19                	je     f0101dce <mem_init+0xd18>
f0101db5:	68 00 42 10 f0       	push   $0xf0104200
f0101dba:	68 3e 44 10 f0       	push   $0xf010443e
f0101dbf:	68 4a 03 00 00       	push   $0x34a
f0101dc4:	68 18 44 10 f0       	push   $0xf0104418
f0101dc9:	e8 bd e2 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref);
f0101dce:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101dd3:	75 19                	jne    f0101dee <mem_init+0xd38>
f0101dd5:	68 51 46 10 f0       	push   $0xf0104651
f0101dda:	68 3e 44 10 f0       	push   $0xf010443e
f0101ddf:	68 4b 03 00 00       	push   $0x34b
f0101de4:	68 18 44 10 f0       	push   $0xf0104418
f0101de9:	e8 9d e2 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_link == NULL);
f0101dee:	83 3b 00             	cmpl   $0x0,(%ebx)
f0101df1:	74 19                	je     f0101e0c <mem_init+0xd56>
f0101df3:	68 5d 46 10 f0       	push   $0xf010465d
f0101df8:	68 3e 44 10 f0       	push   $0xf010443e
f0101dfd:	68 4c 03 00 00       	push   $0x34c
f0101e02:	68 18 44 10 f0       	push   $0xf0104418
f0101e07:	e8 7f e2 ff ff       	call   f010008b <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101e0c:	83 ec 08             	sub    $0x8,%esp
f0101e0f:	68 00 10 00 00       	push   $0x1000
f0101e14:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0101e1a:	e8 ea f1 ff ff       	call   f0101009 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101e1f:	8b 3d 48 79 11 f0    	mov    0xf0117948,%edi
f0101e25:	ba 00 00 00 00       	mov    $0x0,%edx
f0101e2a:	89 f8                	mov    %edi,%eax
f0101e2c:	e8 8a eb ff ff       	call   f01009bb <check_va2pa>
f0101e31:	83 c4 10             	add    $0x10,%esp
f0101e34:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e37:	74 19                	je     f0101e52 <mem_init+0xd9c>
f0101e39:	68 dc 41 10 f0       	push   $0xf01041dc
f0101e3e:	68 3e 44 10 f0       	push   $0xf010443e
f0101e43:	68 50 03 00 00       	push   $0x350
f0101e48:	68 18 44 10 f0       	push   $0xf0104418
f0101e4d:	e8 39 e2 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101e52:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e57:	89 f8                	mov    %edi,%eax
f0101e59:	e8 5d eb ff ff       	call   f01009bb <check_va2pa>
f0101e5e:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e61:	74 19                	je     f0101e7c <mem_init+0xdc6>
f0101e63:	68 38 42 10 f0       	push   $0xf0104238
f0101e68:	68 3e 44 10 f0       	push   $0xf010443e
f0101e6d:	68 51 03 00 00       	push   $0x351
f0101e72:	68 18 44 10 f0       	push   $0xf0104418
f0101e77:	e8 0f e2 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 0);
f0101e7c:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101e81:	74 19                	je     f0101e9c <mem_init+0xde6>
f0101e83:	68 72 46 10 f0       	push   $0xf0104672
f0101e88:	68 3e 44 10 f0       	push   $0xf010443e
f0101e8d:	68 52 03 00 00       	push   $0x352
f0101e92:	68 18 44 10 f0       	push   $0xf0104418
f0101e97:	e8 ef e1 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101e9c:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101ea1:	74 19                	je     f0101ebc <mem_init+0xe06>
f0101ea3:	68 40 46 10 f0       	push   $0xf0104640
f0101ea8:	68 3e 44 10 f0       	push   $0xf010443e
f0101ead:	68 53 03 00 00       	push   $0x353
f0101eb2:	68 18 44 10 f0       	push   $0xf0104418
f0101eb7:	e8 cf e1 ff ff       	call   f010008b <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101ebc:	83 ec 0c             	sub    $0xc,%esp
f0101ebf:	6a 00                	push   $0x0
f0101ec1:	e8 dc ee ff ff       	call   f0100da2 <page_alloc>
f0101ec6:	83 c4 10             	add    $0x10,%esp
f0101ec9:	85 c0                	test   %eax,%eax
f0101ecb:	74 04                	je     f0101ed1 <mem_init+0xe1b>
f0101ecd:	39 c3                	cmp    %eax,%ebx
f0101ecf:	74 19                	je     f0101eea <mem_init+0xe34>
f0101ed1:	68 60 42 10 f0       	push   $0xf0104260
f0101ed6:	68 3e 44 10 f0       	push   $0xf010443e
f0101edb:	68 56 03 00 00       	push   $0x356
f0101ee0:	68 18 44 10 f0       	push   $0xf0104418
f0101ee5:	e8 a1 e1 ff ff       	call   f010008b <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101eea:	83 ec 0c             	sub    $0xc,%esp
f0101eed:	6a 00                	push   $0x0
f0101eef:	e8 ae ee ff ff       	call   f0100da2 <page_alloc>
f0101ef4:	83 c4 10             	add    $0x10,%esp
f0101ef7:	85 c0                	test   %eax,%eax
f0101ef9:	74 19                	je     f0101f14 <mem_init+0xe5e>
f0101efb:	68 94 45 10 f0       	push   $0xf0104594
f0101f00:	68 3e 44 10 f0       	push   $0xf010443e
f0101f05:	68 59 03 00 00       	push   $0x359
f0101f0a:	68 18 44 10 f0       	push   $0xf0104418
f0101f0f:	e8 77 e1 ff ff       	call   f010008b <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101f14:	8b 0d 48 79 11 f0    	mov    0xf0117948,%ecx
f0101f1a:	8b 11                	mov    (%ecx),%edx
f0101f1c:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101f22:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f25:	2b 05 4c 79 11 f0    	sub    0xf011794c,%eax
f0101f2b:	c1 f8 03             	sar    $0x3,%eax
f0101f2e:	c1 e0 0c             	shl    $0xc,%eax
f0101f31:	39 c2                	cmp    %eax,%edx
f0101f33:	74 19                	je     f0101f4e <mem_init+0xe98>
f0101f35:	68 04 3f 10 f0       	push   $0xf0103f04
f0101f3a:	68 3e 44 10 f0       	push   $0xf010443e
f0101f3f:	68 5c 03 00 00       	push   $0x35c
f0101f44:	68 18 44 10 f0       	push   $0xf0104418
f0101f49:	e8 3d e1 ff ff       	call   f010008b <_panic>
	kern_pgdir[0] = 0;
f0101f4e:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0101f54:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f57:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101f5c:	74 19                	je     f0101f77 <mem_init+0xec1>
f0101f5e:	68 f7 45 10 f0       	push   $0xf01045f7
f0101f63:	68 3e 44 10 f0       	push   $0xf010443e
f0101f68:	68 5e 03 00 00       	push   $0x35e
f0101f6d:	68 18 44 10 f0       	push   $0xf0104418
f0101f72:	e8 14 e1 ff ff       	call   f010008b <_panic>
	pp0->pp_ref = 0;
f0101f77:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f7a:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0101f80:	83 ec 0c             	sub    $0xc,%esp
f0101f83:	50                   	push   %eax
f0101f84:	e8 a0 ee ff ff       	call   f0100e29 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0101f89:	83 c4 0c             	add    $0xc,%esp
f0101f8c:	6a 01                	push   $0x1
f0101f8e:	68 00 10 40 00       	push   $0x401000
f0101f93:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0101f99:	e8 ed ee ff ff       	call   f0100e8b <pgdir_walk>
f0101f9e:	89 c7                	mov    %eax,%edi
f0101fa0:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0101fa3:	a1 48 79 11 f0       	mov    0xf0117948,%eax
f0101fa8:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101fab:	8b 40 04             	mov    0x4(%eax),%eax
f0101fae:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101fb3:	8b 0d 44 79 11 f0    	mov    0xf0117944,%ecx
f0101fb9:	89 c2                	mov    %eax,%edx
f0101fbb:	c1 ea 0c             	shr    $0xc,%edx
f0101fbe:	83 c4 10             	add    $0x10,%esp
f0101fc1:	39 ca                	cmp    %ecx,%edx
f0101fc3:	72 15                	jb     f0101fda <mem_init+0xf24>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101fc5:	50                   	push   %eax
f0101fc6:	68 1c 3c 10 f0       	push   $0xf0103c1c
f0101fcb:	68 65 03 00 00       	push   $0x365
f0101fd0:	68 18 44 10 f0       	push   $0xf0104418
f0101fd5:	e8 b1 e0 ff ff       	call   f010008b <_panic>
	assert(ptep == ptep1 + PTX(va));
f0101fda:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f0101fdf:	39 c7                	cmp    %eax,%edi
f0101fe1:	74 19                	je     f0101ffc <mem_init+0xf46>
f0101fe3:	68 83 46 10 f0       	push   $0xf0104683
f0101fe8:	68 3e 44 10 f0       	push   $0xf010443e
f0101fed:	68 66 03 00 00       	push   $0x366
f0101ff2:	68 18 44 10 f0       	push   $0xf0104418
f0101ff7:	e8 8f e0 ff ff       	call   f010008b <_panic>
	kern_pgdir[PDX(va)] = 0;
f0101ffc:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101fff:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f0102006:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102009:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010200f:	2b 05 4c 79 11 f0    	sub    0xf011794c,%eax
f0102015:	c1 f8 03             	sar    $0x3,%eax
f0102018:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010201b:	89 c2                	mov    %eax,%edx
f010201d:	c1 ea 0c             	shr    $0xc,%edx
f0102020:	39 d1                	cmp    %edx,%ecx
f0102022:	77 12                	ja     f0102036 <mem_init+0xf80>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102024:	50                   	push   %eax
f0102025:	68 1c 3c 10 f0       	push   $0xf0103c1c
f010202a:	6a 52                	push   $0x52
f010202c:	68 24 44 10 f0       	push   $0xf0104424
f0102031:	e8 55 e0 ff ff       	call   f010008b <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0102036:	83 ec 04             	sub    $0x4,%esp
f0102039:	68 00 10 00 00       	push   $0x1000
f010203e:	68 ff 00 00 00       	push   $0xff
f0102043:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102048:	50                   	push   %eax
f0102049:	e8 b7 11 00 00       	call   f0103205 <memset>
	page_free(pp0);
f010204e:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102051:	89 3c 24             	mov    %edi,(%esp)
f0102054:	e8 d0 ed ff ff       	call   f0100e29 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0102059:	83 c4 0c             	add    $0xc,%esp
f010205c:	6a 01                	push   $0x1
f010205e:	6a 00                	push   $0x0
f0102060:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0102066:	e8 20 ee ff ff       	call   f0100e8b <pgdir_walk>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010206b:	89 fa                	mov    %edi,%edx
f010206d:	2b 15 4c 79 11 f0    	sub    0xf011794c,%edx
f0102073:	c1 fa 03             	sar    $0x3,%edx
f0102076:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102079:	89 d0                	mov    %edx,%eax
f010207b:	c1 e8 0c             	shr    $0xc,%eax
f010207e:	83 c4 10             	add    $0x10,%esp
f0102081:	3b 05 44 79 11 f0    	cmp    0xf0117944,%eax
f0102087:	72 12                	jb     f010209b <mem_init+0xfe5>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102089:	52                   	push   %edx
f010208a:	68 1c 3c 10 f0       	push   $0xf0103c1c
f010208f:	6a 52                	push   $0x52
f0102091:	68 24 44 10 f0       	push   $0xf0104424
f0102096:	e8 f0 df ff ff       	call   f010008b <_panic>
	return (void *)(pa + KERNBASE);
f010209b:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f01020a1:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01020a4:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f01020aa:	f6 00 01             	testb  $0x1,(%eax)
f01020ad:	74 19                	je     f01020c8 <mem_init+0x1012>
f01020af:	68 9b 46 10 f0       	push   $0xf010469b
f01020b4:	68 3e 44 10 f0       	push   $0xf010443e
f01020b9:	68 70 03 00 00       	push   $0x370
f01020be:	68 18 44 10 f0       	push   $0xf0104418
f01020c3:	e8 c3 df ff ff       	call   f010008b <_panic>
f01020c8:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f01020cb:	39 d0                	cmp    %edx,%eax
f01020cd:	75 db                	jne    f01020aa <mem_init+0xff4>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f01020cf:	a1 48 79 11 f0       	mov    0xf0117948,%eax
f01020d4:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f01020da:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01020dd:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f01020e3:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f01020e6:	89 0d 3c 75 11 f0    	mov    %ecx,0xf011753c

	// free the pages we took
	page_free(pp0);
f01020ec:	83 ec 0c             	sub    $0xc,%esp
f01020ef:	50                   	push   %eax
f01020f0:	e8 34 ed ff ff       	call   f0100e29 <page_free>
	page_free(pp1);
f01020f5:	89 1c 24             	mov    %ebx,(%esp)
f01020f8:	e8 2c ed ff ff       	call   f0100e29 <page_free>
	page_free(pp2);
f01020fd:	89 34 24             	mov    %esi,(%esp)
f0102100:	e8 24 ed ff ff       	call   f0100e29 <page_free>

	cprintf("check_page() succeeded!\n");
f0102105:	c7 04 24 b2 46 10 f0 	movl   $0xf01046b2,(%esp)
f010210c:	e8 4b 06 00 00       	call   f010275c <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, UPAGES, PTSIZE, PADDR(pages), PTE_U);
f0102111:	a1 4c 79 11 f0       	mov    0xf011794c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102116:	83 c4 10             	add    $0x10,%esp
f0102119:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010211e:	77 15                	ja     f0102135 <mem_init+0x107f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102120:	50                   	push   %eax
f0102121:	68 28 3d 10 f0       	push   $0xf0103d28
f0102126:	68 b5 00 00 00       	push   $0xb5
f010212b:	68 18 44 10 f0       	push   $0xf0104418
f0102130:	e8 56 df ff ff       	call   f010008b <_panic>
f0102135:	83 ec 08             	sub    $0x8,%esp
f0102138:	6a 04                	push   $0x4
f010213a:	05 00 00 00 10       	add    $0x10000000,%eax
f010213f:	50                   	push   %eax
f0102140:	b9 00 00 40 00       	mov    $0x400000,%ecx
f0102145:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f010214a:	a1 48 79 11 f0       	mov    0xf0117948,%eax
f010214f:	e8 ca ed ff ff       	call   f0100f1e <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102154:	83 c4 10             	add    $0x10,%esp
f0102157:	b8 00 d0 10 f0       	mov    $0xf010d000,%eax
f010215c:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102161:	77 15                	ja     f0102178 <mem_init+0x10c2>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102163:	50                   	push   %eax
f0102164:	68 28 3d 10 f0       	push   $0xf0103d28
f0102169:	68 c1 00 00 00       	push   $0xc1
f010216e:	68 18 44 10 f0       	push   $0xf0104418
f0102173:	e8 13 df ff ff       	call   f010008b <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KSTACKTOP-KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W);
f0102178:	83 ec 08             	sub    $0x8,%esp
f010217b:	6a 02                	push   $0x2
f010217d:	68 00 d0 10 00       	push   $0x10d000
f0102182:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102187:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f010218c:	a1 48 79 11 f0       	mov    0xf0117948,%eax
f0102191:	e8 88 ed ff ff       	call   f0100f1e <boot_map_region>
	//      the PA range [0, 2^32 - KERNBASE)
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KERNBASE, 0xffffffff - KERNBASE, 0, PTE_W);
f0102196:	83 c4 08             	add    $0x8,%esp
f0102199:	6a 02                	push   $0x2
f010219b:	6a 00                	push   $0x0
f010219d:	b9 ff ff ff 0f       	mov    $0xfffffff,%ecx
f01021a2:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f01021a7:	a1 48 79 11 f0       	mov    0xf0117948,%eax
f01021ac:	e8 6d ed ff ff       	call   f0100f1e <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f01021b1:	8b 35 48 79 11 f0    	mov    0xf0117948,%esi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f01021b7:	a1 44 79 11 f0       	mov    0xf0117944,%eax
f01021bc:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01021bf:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f01021c6:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01021cb:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01021ce:	8b 3d 4c 79 11 f0    	mov    0xf011794c,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01021d4:	89 7d d0             	mov    %edi,-0x30(%ebp)
f01021d7:	83 c4 10             	add    $0x10,%esp

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01021da:	bb 00 00 00 00       	mov    $0x0,%ebx
f01021df:	eb 55                	jmp    f0102236 <mem_init+0x1180>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01021e1:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
f01021e7:	89 f0                	mov    %esi,%eax
f01021e9:	e8 cd e7 ff ff       	call   f01009bb <check_va2pa>
f01021ee:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f01021f5:	77 15                	ja     f010220c <mem_init+0x1156>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01021f7:	57                   	push   %edi
f01021f8:	68 28 3d 10 f0       	push   $0xf0103d28
f01021fd:	68 b2 02 00 00       	push   $0x2b2
f0102202:	68 18 44 10 f0       	push   $0xf0104418
f0102207:	e8 7f de ff ff       	call   f010008b <_panic>
f010220c:	8d 94 1f 00 00 00 10 	lea    0x10000000(%edi,%ebx,1),%edx
f0102213:	39 c2                	cmp    %eax,%edx
f0102215:	74 19                	je     f0102230 <mem_init+0x117a>
f0102217:	68 84 42 10 f0       	push   $0xf0104284
f010221c:	68 3e 44 10 f0       	push   $0xf010443e
f0102221:	68 b2 02 00 00       	push   $0x2b2
f0102226:	68 18 44 10 f0       	push   $0xf0104418
f010222b:	e8 5b de ff ff       	call   f010008b <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102230:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102236:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0102239:	77 a6                	ja     f01021e1 <mem_init+0x112b>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f010223b:	8b 7d cc             	mov    -0x34(%ebp),%edi
f010223e:	c1 e7 0c             	shl    $0xc,%edi
f0102241:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102246:	eb 30                	jmp    f0102278 <mem_init+0x11c2>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102248:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
f010224e:	89 f0                	mov    %esi,%eax
f0102250:	e8 66 e7 ff ff       	call   f01009bb <check_va2pa>
f0102255:	39 c3                	cmp    %eax,%ebx
f0102257:	74 19                	je     f0102272 <mem_init+0x11bc>
f0102259:	68 b8 42 10 f0       	push   $0xf01042b8
f010225e:	68 3e 44 10 f0       	push   $0xf010443e
f0102263:	68 b7 02 00 00       	push   $0x2b7
f0102268:	68 18 44 10 f0       	push   $0xf0104418
f010226d:	e8 19 de ff ff       	call   f010008b <_panic>
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102272:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102278:	39 fb                	cmp    %edi,%ebx
f010227a:	72 cc                	jb     f0102248 <mem_init+0x1192>
f010227c:	bb 00 80 ff ef       	mov    $0xefff8000,%ebx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102281:	89 da                	mov    %ebx,%edx
f0102283:	89 f0                	mov    %esi,%eax
f0102285:	e8 31 e7 ff ff       	call   f01009bb <check_va2pa>
f010228a:	8d 93 00 50 11 10    	lea    0x10115000(%ebx),%edx
f0102290:	39 c2                	cmp    %eax,%edx
f0102292:	74 19                	je     f01022ad <mem_init+0x11f7>
f0102294:	68 e0 42 10 f0       	push   $0xf01042e0
f0102299:	68 3e 44 10 f0       	push   $0xf010443e
f010229e:	68 bb 02 00 00       	push   $0x2bb
f01022a3:	68 18 44 10 f0       	push   $0xf0104418
f01022a8:	e8 de dd ff ff       	call   f010008b <_panic>
f01022ad:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f01022b3:	81 fb 00 00 00 f0    	cmp    $0xf0000000,%ebx
f01022b9:	75 c6                	jne    f0102281 <mem_init+0x11cb>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f01022bb:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f01022c0:	89 f0                	mov    %esi,%eax
f01022c2:	e8 f4 e6 ff ff       	call   f01009bb <check_va2pa>
f01022c7:	83 f8 ff             	cmp    $0xffffffff,%eax
f01022ca:	74 51                	je     f010231d <mem_init+0x1267>
f01022cc:	68 28 43 10 f0       	push   $0xf0104328
f01022d1:	68 3e 44 10 f0       	push   $0xf010443e
f01022d6:	68 bc 02 00 00       	push   $0x2bc
f01022db:	68 18 44 10 f0       	push   $0xf0104418
f01022e0:	e8 a6 dd ff ff       	call   f010008b <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f01022e5:	3d bc 03 00 00       	cmp    $0x3bc,%eax
f01022ea:	72 36                	jb     f0102322 <mem_init+0x126c>
f01022ec:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f01022f1:	76 07                	jbe    f01022fa <mem_init+0x1244>
f01022f3:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f01022f8:	75 28                	jne    f0102322 <mem_init+0x126c>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
f01022fa:	f6 04 86 01          	testb  $0x1,(%esi,%eax,4)
f01022fe:	0f 85 83 00 00 00    	jne    f0102387 <mem_init+0x12d1>
f0102304:	68 cb 46 10 f0       	push   $0xf01046cb
f0102309:	68 3e 44 10 f0       	push   $0xf010443e
f010230e:	68 c4 02 00 00       	push   $0x2c4
f0102313:	68 18 44 10 f0       	push   $0xf0104418
f0102318:	e8 6e dd ff ff       	call   f010008b <_panic>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f010231d:	b8 00 00 00 00       	mov    $0x0,%eax
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f0102322:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102327:	76 3f                	jbe    f0102368 <mem_init+0x12b2>
				assert(pgdir[i] & PTE_P);
f0102329:	8b 14 86             	mov    (%esi,%eax,4),%edx
f010232c:	f6 c2 01             	test   $0x1,%dl
f010232f:	75 19                	jne    f010234a <mem_init+0x1294>
f0102331:	68 cb 46 10 f0       	push   $0xf01046cb
f0102336:	68 3e 44 10 f0       	push   $0xf010443e
f010233b:	68 c8 02 00 00       	push   $0x2c8
f0102340:	68 18 44 10 f0       	push   $0xf0104418
f0102345:	e8 41 dd ff ff       	call   f010008b <_panic>
				assert(pgdir[i] & PTE_W);
f010234a:	f6 c2 02             	test   $0x2,%dl
f010234d:	75 38                	jne    f0102387 <mem_init+0x12d1>
f010234f:	68 dc 46 10 f0       	push   $0xf01046dc
f0102354:	68 3e 44 10 f0       	push   $0xf010443e
f0102359:	68 c9 02 00 00       	push   $0x2c9
f010235e:	68 18 44 10 f0       	push   $0xf0104418
f0102363:	e8 23 dd ff ff       	call   f010008b <_panic>
			} else
				assert(pgdir[i] == 0);
f0102368:	83 3c 86 00          	cmpl   $0x0,(%esi,%eax,4)
f010236c:	74 19                	je     f0102387 <mem_init+0x12d1>
f010236e:	68 ed 46 10 f0       	push   $0xf01046ed
f0102373:	68 3e 44 10 f0       	push   $0xf010443e
f0102378:	68 cb 02 00 00       	push   $0x2cb
f010237d:	68 18 44 10 f0       	push   $0xf0104418
f0102382:	e8 04 dd ff ff       	call   f010008b <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0102387:	83 c0 01             	add    $0x1,%eax
f010238a:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f010238f:	0f 86 50 ff ff ff    	jbe    f01022e5 <mem_init+0x122f>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f0102395:	83 ec 0c             	sub    $0xc,%esp
f0102398:	68 58 43 10 f0       	push   $0xf0104358
f010239d:	e8 ba 03 00 00       	call   f010275c <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f01023a2:	a1 48 79 11 f0       	mov    0xf0117948,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01023a7:	83 c4 10             	add    $0x10,%esp
f01023aa:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01023af:	77 15                	ja     f01023c6 <mem_init+0x1310>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01023b1:	50                   	push   %eax
f01023b2:	68 28 3d 10 f0       	push   $0xf0103d28
f01023b7:	68 d5 00 00 00       	push   $0xd5
f01023bc:	68 18 44 10 f0       	push   $0xf0104418
f01023c1:	e8 c5 dc ff ff       	call   f010008b <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f01023c6:	05 00 00 00 10       	add    $0x10000000,%eax
f01023cb:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f01023ce:	b8 00 00 00 00       	mov    $0x0,%eax
f01023d3:	e8 47 e6 ff ff       	call   f0100a1f <check_page_free_list>

static inline uint32_t
rcr0(void)
{
	uint32_t val;
	asm volatile("movl %%cr0,%0" : "=r" (val));
f01023d8:	0f 20 c0             	mov    %cr0,%eax
f01023db:	83 e0 f3             	and    $0xfffffff3,%eax
}

static inline void
lcr0(uint32_t val)
{
	asm volatile("movl %0,%%cr0" : : "r" (val));
f01023de:	0d 23 00 05 80       	or     $0x80050023,%eax
f01023e3:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01023e6:	83 ec 0c             	sub    $0xc,%esp
f01023e9:	6a 00                	push   $0x0
f01023eb:	e8 b2 e9 ff ff       	call   f0100da2 <page_alloc>
f01023f0:	89 c3                	mov    %eax,%ebx
f01023f2:	83 c4 10             	add    $0x10,%esp
f01023f5:	85 c0                	test   %eax,%eax
f01023f7:	75 19                	jne    f0102412 <mem_init+0x135c>
f01023f9:	68 e9 44 10 f0       	push   $0xf01044e9
f01023fe:	68 3e 44 10 f0       	push   $0xf010443e
f0102403:	68 8b 03 00 00       	push   $0x38b
f0102408:	68 18 44 10 f0       	push   $0xf0104418
f010240d:	e8 79 dc ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f0102412:	83 ec 0c             	sub    $0xc,%esp
f0102415:	6a 00                	push   $0x0
f0102417:	e8 86 e9 ff ff       	call   f0100da2 <page_alloc>
f010241c:	89 c7                	mov    %eax,%edi
f010241e:	83 c4 10             	add    $0x10,%esp
f0102421:	85 c0                	test   %eax,%eax
f0102423:	75 19                	jne    f010243e <mem_init+0x1388>
f0102425:	68 ff 44 10 f0       	push   $0xf01044ff
f010242a:	68 3e 44 10 f0       	push   $0xf010443e
f010242f:	68 8c 03 00 00       	push   $0x38c
f0102434:	68 18 44 10 f0       	push   $0xf0104418
f0102439:	e8 4d dc ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f010243e:	83 ec 0c             	sub    $0xc,%esp
f0102441:	6a 00                	push   $0x0
f0102443:	e8 5a e9 ff ff       	call   f0100da2 <page_alloc>
f0102448:	89 c6                	mov    %eax,%esi
f010244a:	83 c4 10             	add    $0x10,%esp
f010244d:	85 c0                	test   %eax,%eax
f010244f:	75 19                	jne    f010246a <mem_init+0x13b4>
f0102451:	68 15 45 10 f0       	push   $0xf0104515
f0102456:	68 3e 44 10 f0       	push   $0xf010443e
f010245b:	68 8d 03 00 00       	push   $0x38d
f0102460:	68 18 44 10 f0       	push   $0xf0104418
f0102465:	e8 21 dc ff ff       	call   f010008b <_panic>
	page_free(pp0);
f010246a:	83 ec 0c             	sub    $0xc,%esp
f010246d:	53                   	push   %ebx
f010246e:	e8 b6 e9 ff ff       	call   f0100e29 <page_free>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102473:	89 f8                	mov    %edi,%eax
f0102475:	2b 05 4c 79 11 f0    	sub    0xf011794c,%eax
f010247b:	c1 f8 03             	sar    $0x3,%eax
f010247e:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102481:	89 c2                	mov    %eax,%edx
f0102483:	c1 ea 0c             	shr    $0xc,%edx
f0102486:	83 c4 10             	add    $0x10,%esp
f0102489:	3b 15 44 79 11 f0    	cmp    0xf0117944,%edx
f010248f:	72 12                	jb     f01024a3 <mem_init+0x13ed>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102491:	50                   	push   %eax
f0102492:	68 1c 3c 10 f0       	push   $0xf0103c1c
f0102497:	6a 52                	push   $0x52
f0102499:	68 24 44 10 f0       	push   $0xf0104424
f010249e:	e8 e8 db ff ff       	call   f010008b <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f01024a3:	83 ec 04             	sub    $0x4,%esp
f01024a6:	68 00 10 00 00       	push   $0x1000
f01024ab:	6a 01                	push   $0x1
f01024ad:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01024b2:	50                   	push   %eax
f01024b3:	e8 4d 0d 00 00       	call   f0103205 <memset>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01024b8:	89 f0                	mov    %esi,%eax
f01024ba:	2b 05 4c 79 11 f0    	sub    0xf011794c,%eax
f01024c0:	c1 f8 03             	sar    $0x3,%eax
f01024c3:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01024c6:	89 c2                	mov    %eax,%edx
f01024c8:	c1 ea 0c             	shr    $0xc,%edx
f01024cb:	83 c4 10             	add    $0x10,%esp
f01024ce:	3b 15 44 79 11 f0    	cmp    0xf0117944,%edx
f01024d4:	72 12                	jb     f01024e8 <mem_init+0x1432>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01024d6:	50                   	push   %eax
f01024d7:	68 1c 3c 10 f0       	push   $0xf0103c1c
f01024dc:	6a 52                	push   $0x52
f01024de:	68 24 44 10 f0       	push   $0xf0104424
f01024e3:	e8 a3 db ff ff       	call   f010008b <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f01024e8:	83 ec 04             	sub    $0x4,%esp
f01024eb:	68 00 10 00 00       	push   $0x1000
f01024f0:	6a 02                	push   $0x2
f01024f2:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01024f7:	50                   	push   %eax
f01024f8:	e8 08 0d 00 00       	call   f0103205 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f01024fd:	6a 02                	push   $0x2
f01024ff:	68 00 10 00 00       	push   $0x1000
f0102504:	57                   	push   %edi
f0102505:	ff 35 48 79 11 f0    	pushl  0xf0117948
f010250b:	e8 34 eb ff ff       	call   f0101044 <page_insert>
	assert(pp1->pp_ref == 1);
f0102510:	83 c4 20             	add    $0x20,%esp
f0102513:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102518:	74 19                	je     f0102533 <mem_init+0x147d>
f010251a:	68 e6 45 10 f0       	push   $0xf01045e6
f010251f:	68 3e 44 10 f0       	push   $0xf010443e
f0102524:	68 92 03 00 00       	push   $0x392
f0102529:	68 18 44 10 f0       	push   $0xf0104418
f010252e:	e8 58 db ff ff       	call   f010008b <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102533:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f010253a:	01 01 01 
f010253d:	74 19                	je     f0102558 <mem_init+0x14a2>
f010253f:	68 78 43 10 f0       	push   $0xf0104378
f0102544:	68 3e 44 10 f0       	push   $0xf010443e
f0102549:	68 93 03 00 00       	push   $0x393
f010254e:	68 18 44 10 f0       	push   $0xf0104418
f0102553:	e8 33 db ff ff       	call   f010008b <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102558:	6a 02                	push   $0x2
f010255a:	68 00 10 00 00       	push   $0x1000
f010255f:	56                   	push   %esi
f0102560:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0102566:	e8 d9 ea ff ff       	call   f0101044 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f010256b:	83 c4 10             	add    $0x10,%esp
f010256e:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102575:	02 02 02 
f0102578:	74 19                	je     f0102593 <mem_init+0x14dd>
f010257a:	68 9c 43 10 f0       	push   $0xf010439c
f010257f:	68 3e 44 10 f0       	push   $0xf010443e
f0102584:	68 95 03 00 00       	push   $0x395
f0102589:	68 18 44 10 f0       	push   $0xf0104418
f010258e:	e8 f8 da ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f0102593:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102598:	74 19                	je     f01025b3 <mem_init+0x14fd>
f010259a:	68 08 46 10 f0       	push   $0xf0104608
f010259f:	68 3e 44 10 f0       	push   $0xf010443e
f01025a4:	68 96 03 00 00       	push   $0x396
f01025a9:	68 18 44 10 f0       	push   $0xf0104418
f01025ae:	e8 d8 da ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 0);
f01025b3:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f01025b8:	74 19                	je     f01025d3 <mem_init+0x151d>
f01025ba:	68 72 46 10 f0       	push   $0xf0104672
f01025bf:	68 3e 44 10 f0       	push   $0xf010443e
f01025c4:	68 97 03 00 00       	push   $0x397
f01025c9:	68 18 44 10 f0       	push   $0xf0104418
f01025ce:	e8 b8 da ff ff       	call   f010008b <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f01025d3:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f01025da:	03 03 03 
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01025dd:	89 f0                	mov    %esi,%eax
f01025df:	2b 05 4c 79 11 f0    	sub    0xf011794c,%eax
f01025e5:	c1 f8 03             	sar    $0x3,%eax
f01025e8:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01025eb:	89 c2                	mov    %eax,%edx
f01025ed:	c1 ea 0c             	shr    $0xc,%edx
f01025f0:	3b 15 44 79 11 f0    	cmp    0xf0117944,%edx
f01025f6:	72 12                	jb     f010260a <mem_init+0x1554>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01025f8:	50                   	push   %eax
f01025f9:	68 1c 3c 10 f0       	push   $0xf0103c1c
f01025fe:	6a 52                	push   $0x52
f0102600:	68 24 44 10 f0       	push   $0xf0104424
f0102605:	e8 81 da ff ff       	call   f010008b <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f010260a:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102611:	03 03 03 
f0102614:	74 19                	je     f010262f <mem_init+0x1579>
f0102616:	68 c0 43 10 f0       	push   $0xf01043c0
f010261b:	68 3e 44 10 f0       	push   $0xf010443e
f0102620:	68 99 03 00 00       	push   $0x399
f0102625:	68 18 44 10 f0       	push   $0xf0104418
f010262a:	e8 5c da ff ff       	call   f010008b <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f010262f:	83 ec 08             	sub    $0x8,%esp
f0102632:	68 00 10 00 00       	push   $0x1000
f0102637:	ff 35 48 79 11 f0    	pushl  0xf0117948
f010263d:	e8 c7 e9 ff ff       	call   f0101009 <page_remove>
	assert(pp2->pp_ref == 0);
f0102642:	83 c4 10             	add    $0x10,%esp
f0102645:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f010264a:	74 19                	je     f0102665 <mem_init+0x15af>
f010264c:	68 40 46 10 f0       	push   $0xf0104640
f0102651:	68 3e 44 10 f0       	push   $0xf010443e
f0102656:	68 9b 03 00 00       	push   $0x39b
f010265b:	68 18 44 10 f0       	push   $0xf0104418
f0102660:	e8 26 da ff ff       	call   f010008b <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102665:	8b 0d 48 79 11 f0    	mov    0xf0117948,%ecx
f010266b:	8b 11                	mov    (%ecx),%edx
f010266d:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102673:	89 d8                	mov    %ebx,%eax
f0102675:	2b 05 4c 79 11 f0    	sub    0xf011794c,%eax
f010267b:	c1 f8 03             	sar    $0x3,%eax
f010267e:	c1 e0 0c             	shl    $0xc,%eax
f0102681:	39 c2                	cmp    %eax,%edx
f0102683:	74 19                	je     f010269e <mem_init+0x15e8>
f0102685:	68 04 3f 10 f0       	push   $0xf0103f04
f010268a:	68 3e 44 10 f0       	push   $0xf010443e
f010268f:	68 9e 03 00 00       	push   $0x39e
f0102694:	68 18 44 10 f0       	push   $0xf0104418
f0102699:	e8 ed d9 ff ff       	call   f010008b <_panic>
	kern_pgdir[0] = 0;
f010269e:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f01026a4:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01026a9:	74 19                	je     f01026c4 <mem_init+0x160e>
f01026ab:	68 f7 45 10 f0       	push   $0xf01045f7
f01026b0:	68 3e 44 10 f0       	push   $0xf010443e
f01026b5:	68 a0 03 00 00       	push   $0x3a0
f01026ba:	68 18 44 10 f0       	push   $0xf0104418
f01026bf:	e8 c7 d9 ff ff       	call   f010008b <_panic>
	pp0->pp_ref = 0;
f01026c4:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f01026ca:	83 ec 0c             	sub    $0xc,%esp
f01026cd:	53                   	push   %ebx
f01026ce:	e8 56 e7 ff ff       	call   f0100e29 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f01026d3:	c7 04 24 ec 43 10 f0 	movl   $0xf01043ec,(%esp)
f01026da:	e8 7d 00 00 00       	call   f010275c <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f01026df:	83 c4 10             	add    $0x10,%esp
f01026e2:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01026e5:	5b                   	pop    %ebx
f01026e6:	5e                   	pop    %esi
f01026e7:	5f                   	pop    %edi
f01026e8:	5d                   	pop    %ebp
f01026e9:	c3                   	ret    

f01026ea <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f01026ea:	55                   	push   %ebp
f01026eb:	89 e5                	mov    %esp,%ebp
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01026ed:	8b 45 0c             	mov    0xc(%ebp),%eax
f01026f0:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f01026f3:	5d                   	pop    %ebp
f01026f4:	c3                   	ret    

f01026f5 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f01026f5:	55                   	push   %ebp
f01026f6:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01026f8:	ba 70 00 00 00       	mov    $0x70,%edx
f01026fd:	8b 45 08             	mov    0x8(%ebp),%eax
f0102700:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102701:	ba 71 00 00 00       	mov    $0x71,%edx
f0102706:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0102707:	0f b6 c0             	movzbl %al,%eax
}
f010270a:	5d                   	pop    %ebp
f010270b:	c3                   	ret    

f010270c <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f010270c:	55                   	push   %ebp
f010270d:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010270f:	ba 70 00 00 00       	mov    $0x70,%edx
f0102714:	8b 45 08             	mov    0x8(%ebp),%eax
f0102717:	ee                   	out    %al,(%dx)
f0102718:	ba 71 00 00 00       	mov    $0x71,%edx
f010271d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102720:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0102721:	5d                   	pop    %ebp
f0102722:	c3                   	ret    

f0102723 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0102723:	55                   	push   %ebp
f0102724:	89 e5                	mov    %esp,%ebp
f0102726:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0102729:	ff 75 08             	pushl  0x8(%ebp)
f010272c:	e8 cf de ff ff       	call   f0100600 <cputchar>
	*cnt++;
}
f0102731:	83 c4 10             	add    $0x10,%esp
f0102734:	c9                   	leave  
f0102735:	c3                   	ret    

f0102736 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0102736:	55                   	push   %ebp
f0102737:	89 e5                	mov    %esp,%ebp
f0102739:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f010273c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0102743:	ff 75 0c             	pushl  0xc(%ebp)
f0102746:	ff 75 08             	pushl  0x8(%ebp)
f0102749:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010274c:	50                   	push   %eax
f010274d:	68 23 27 10 f0       	push   $0xf0102723
f0102752:	e8 42 04 00 00       	call   f0102b99 <vprintfmt>
	return cnt;
}
f0102757:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010275a:	c9                   	leave  
f010275b:	c3                   	ret    

f010275c <cprintf>:

int
cprintf(const char *fmt, ...)
{
f010275c:	55                   	push   %ebp
f010275d:	89 e5                	mov    %esp,%ebp
f010275f:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0102762:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102765:	50                   	push   %eax
f0102766:	ff 75 08             	pushl  0x8(%ebp)
f0102769:	e8 c8 ff ff ff       	call   f0102736 <vcprintf>
	va_end(ap);

	return cnt;
}
f010276e:	c9                   	leave  
f010276f:	c3                   	ret    

f0102770 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0102770:	55                   	push   %ebp
f0102771:	89 e5                	mov    %esp,%ebp
f0102773:	57                   	push   %edi
f0102774:	56                   	push   %esi
f0102775:	53                   	push   %ebx
f0102776:	83 ec 14             	sub    $0x14,%esp
f0102779:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010277c:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f010277f:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0102782:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0102785:	8b 1a                	mov    (%edx),%ebx
f0102787:	8b 01                	mov    (%ecx),%eax
f0102789:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010278c:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0102793:	eb 7f                	jmp    f0102814 <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f0102795:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102798:	01 d8                	add    %ebx,%eax
f010279a:	89 c6                	mov    %eax,%esi
f010279c:	c1 ee 1f             	shr    $0x1f,%esi
f010279f:	01 c6                	add    %eax,%esi
f01027a1:	d1 fe                	sar    %esi
f01027a3:	8d 04 76             	lea    (%esi,%esi,2),%eax
f01027a6:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01027a9:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f01027ac:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01027ae:	eb 03                	jmp    f01027b3 <stab_binsearch+0x43>
			m--;
f01027b0:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01027b3:	39 c3                	cmp    %eax,%ebx
f01027b5:	7f 0d                	jg     f01027c4 <stab_binsearch+0x54>
f01027b7:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01027bb:	83 ea 0c             	sub    $0xc,%edx
f01027be:	39 f9                	cmp    %edi,%ecx
f01027c0:	75 ee                	jne    f01027b0 <stab_binsearch+0x40>
f01027c2:	eb 05                	jmp    f01027c9 <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f01027c4:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f01027c7:	eb 4b                	jmp    f0102814 <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01027c9:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01027cc:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01027cf:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f01027d3:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01027d6:	76 11                	jbe    f01027e9 <stab_binsearch+0x79>
			*region_left = m;
f01027d8:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01027db:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f01027dd:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01027e0:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01027e7:	eb 2b                	jmp    f0102814 <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f01027e9:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01027ec:	73 14                	jae    f0102802 <stab_binsearch+0x92>
			*region_right = m - 1;
f01027ee:	83 e8 01             	sub    $0x1,%eax
f01027f1:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01027f4:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01027f7:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01027f9:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0102800:	eb 12                	jmp    f0102814 <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0102802:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0102805:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0102807:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f010280b:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010280d:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0102814:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0102817:	0f 8e 78 ff ff ff    	jle    f0102795 <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f010281d:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0102821:	75 0f                	jne    f0102832 <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f0102823:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102826:	8b 00                	mov    (%eax),%eax
f0102828:	83 e8 01             	sub    $0x1,%eax
f010282b:	8b 75 e0             	mov    -0x20(%ebp),%esi
f010282e:	89 06                	mov    %eax,(%esi)
f0102830:	eb 2c                	jmp    f010285e <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102832:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102835:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0102837:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010283a:	8b 0e                	mov    (%esi),%ecx
f010283c:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010283f:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0102842:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102845:	eb 03                	jmp    f010284a <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0102847:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010284a:	39 c8                	cmp    %ecx,%eax
f010284c:	7e 0b                	jle    f0102859 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f010284e:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0102852:	83 ea 0c             	sub    $0xc,%edx
f0102855:	39 df                	cmp    %ebx,%edi
f0102857:	75 ee                	jne    f0102847 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f0102859:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010285c:	89 06                	mov    %eax,(%esi)
	}
}
f010285e:	83 c4 14             	add    $0x14,%esp
f0102861:	5b                   	pop    %ebx
f0102862:	5e                   	pop    %esi
f0102863:	5f                   	pop    %edi
f0102864:	5d                   	pop    %ebp
f0102865:	c3                   	ret    

f0102866 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0102866:	55                   	push   %ebp
f0102867:	89 e5                	mov    %esp,%ebp
f0102869:	57                   	push   %edi
f010286a:	56                   	push   %esi
f010286b:	53                   	push   %ebx
f010286c:	83 ec 3c             	sub    $0x3c,%esp
f010286f:	8b 75 08             	mov    0x8(%ebp),%esi
f0102872:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0102875:	c7 03 fb 46 10 f0    	movl   $0xf01046fb,(%ebx)
	info->eip_line = 0;
f010287b:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0102882:	c7 43 08 fb 46 10 f0 	movl   $0xf01046fb,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0102889:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0102890:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0102893:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f010289a:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f01028a0:	76 11                	jbe    f01028b3 <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01028a2:	b8 6e c1 10 f0       	mov    $0xf010c16e,%eax
f01028a7:	3d 6d a3 10 f0       	cmp    $0xf010a36d,%eax
f01028ac:	77 19                	ja     f01028c7 <debuginfo_eip+0x61>
f01028ae:	e9 a1 01 00 00       	jmp    f0102a54 <debuginfo_eip+0x1ee>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f01028b3:	83 ec 04             	sub    $0x4,%esp
f01028b6:	68 05 47 10 f0       	push   $0xf0104705
f01028bb:	6a 7f                	push   $0x7f
f01028bd:	68 12 47 10 f0       	push   $0xf0104712
f01028c2:	e8 c4 d7 ff ff       	call   f010008b <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01028c7:	80 3d 6d c1 10 f0 00 	cmpb   $0x0,0xf010c16d
f01028ce:	0f 85 87 01 00 00    	jne    f0102a5b <debuginfo_eip+0x1f5>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f01028d4:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f01028db:	b8 6c a3 10 f0       	mov    $0xf010a36c,%eax
f01028e0:	2d 30 49 10 f0       	sub    $0xf0104930,%eax
f01028e5:	c1 f8 02             	sar    $0x2,%eax
f01028e8:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f01028ee:	83 e8 01             	sub    $0x1,%eax
f01028f1:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f01028f4:	83 ec 08             	sub    $0x8,%esp
f01028f7:	56                   	push   %esi
f01028f8:	6a 64                	push   $0x64
f01028fa:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f01028fd:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0102900:	b8 30 49 10 f0       	mov    $0xf0104930,%eax
f0102905:	e8 66 fe ff ff       	call   f0102770 <stab_binsearch>
	if (lfile == 0)
f010290a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010290d:	83 c4 10             	add    $0x10,%esp
f0102910:	85 c0                	test   %eax,%eax
f0102912:	0f 84 4a 01 00 00    	je     f0102a62 <debuginfo_eip+0x1fc>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0102918:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f010291b:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010291e:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0102921:	83 ec 08             	sub    $0x8,%esp
f0102924:	56                   	push   %esi
f0102925:	6a 24                	push   $0x24
f0102927:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f010292a:	8d 55 dc             	lea    -0x24(%ebp),%edx
f010292d:	b8 30 49 10 f0       	mov    $0xf0104930,%eax
f0102932:	e8 39 fe ff ff       	call   f0102770 <stab_binsearch>

	if (lfun <= rfun) {
f0102937:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010293a:	8b 55 d8             	mov    -0x28(%ebp),%edx
f010293d:	83 c4 10             	add    $0x10,%esp
f0102940:	39 d0                	cmp    %edx,%eax
f0102942:	7f 40                	jg     f0102984 <debuginfo_eip+0x11e>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0102944:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f0102947:	c1 e1 02             	shl    $0x2,%ecx
f010294a:	8d b9 30 49 10 f0    	lea    -0xfefb6d0(%ecx),%edi
f0102950:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f0102953:	8b b9 30 49 10 f0    	mov    -0xfefb6d0(%ecx),%edi
f0102959:	b9 6e c1 10 f0       	mov    $0xf010c16e,%ecx
f010295e:	81 e9 6d a3 10 f0    	sub    $0xf010a36d,%ecx
f0102964:	39 cf                	cmp    %ecx,%edi
f0102966:	73 09                	jae    f0102971 <debuginfo_eip+0x10b>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0102968:	81 c7 6d a3 10 f0    	add    $0xf010a36d,%edi
f010296e:	89 7b 08             	mov    %edi,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0102971:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0102974:	8b 4f 08             	mov    0x8(%edi),%ecx
f0102977:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f010297a:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f010297c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f010297f:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0102982:	eb 0f                	jmp    f0102993 <debuginfo_eip+0x12d>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0102984:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0102987:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010298a:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f010298d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102990:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0102993:	83 ec 08             	sub    $0x8,%esp
f0102996:	6a 3a                	push   $0x3a
f0102998:	ff 73 08             	pushl  0x8(%ebx)
f010299b:	e8 49 08 00 00       	call   f01031e9 <strfind>
f01029a0:	2b 43 08             	sub    0x8(%ebx),%eax
f01029a3:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f01029a6:	83 c4 08             	add    $0x8,%esp
f01029a9:	56                   	push   %esi
f01029aa:	6a 44                	push   $0x44
f01029ac:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f01029af:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f01029b2:	b8 30 49 10 f0       	mov    $0xf0104930,%eax
f01029b7:	e8 b4 fd ff ff       	call   f0102770 <stab_binsearch>
	    info->eip_line = stabs[lline].n_desc;
f01029bc:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01029bf:	8d 04 52             	lea    (%edx,%edx,2),%eax
f01029c2:	8d 04 85 30 49 10 f0 	lea    -0xfefb6d0(,%eax,4),%eax
f01029c9:	0f b7 48 06          	movzwl 0x6(%eax),%ecx
f01029cd:	89 4b 04             	mov    %ecx,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01029d0:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01029d3:	83 c4 10             	add    $0x10,%esp
f01029d6:	eb 06                	jmp    f01029de <debuginfo_eip+0x178>
f01029d8:	83 ea 01             	sub    $0x1,%edx
f01029db:	83 e8 0c             	sub    $0xc,%eax
f01029de:	39 d6                	cmp    %edx,%esi
f01029e0:	7f 34                	jg     f0102a16 <debuginfo_eip+0x1b0>
	       && stabs[lline].n_type != N_SOL
f01029e2:	0f b6 48 04          	movzbl 0x4(%eax),%ecx
f01029e6:	80 f9 84             	cmp    $0x84,%cl
f01029e9:	74 0b                	je     f01029f6 <debuginfo_eip+0x190>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f01029eb:	80 f9 64             	cmp    $0x64,%cl
f01029ee:	75 e8                	jne    f01029d8 <debuginfo_eip+0x172>
f01029f0:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f01029f4:	74 e2                	je     f01029d8 <debuginfo_eip+0x172>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f01029f6:	8d 04 52             	lea    (%edx,%edx,2),%eax
f01029f9:	8b 14 85 30 49 10 f0 	mov    -0xfefb6d0(,%eax,4),%edx
f0102a00:	b8 6e c1 10 f0       	mov    $0xf010c16e,%eax
f0102a05:	2d 6d a3 10 f0       	sub    $0xf010a36d,%eax
f0102a0a:	39 c2                	cmp    %eax,%edx
f0102a0c:	73 08                	jae    f0102a16 <debuginfo_eip+0x1b0>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0102a0e:	81 c2 6d a3 10 f0    	add    $0xf010a36d,%edx
f0102a14:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0102a16:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102a19:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102a1c:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0102a21:	39 f2                	cmp    %esi,%edx
f0102a23:	7d 49                	jge    f0102a6e <debuginfo_eip+0x208>
		for (lline = lfun + 1;
f0102a25:	83 c2 01             	add    $0x1,%edx
f0102a28:	89 d0                	mov    %edx,%eax
f0102a2a:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0102a2d:	8d 14 95 30 49 10 f0 	lea    -0xfefb6d0(,%edx,4),%edx
f0102a34:	eb 04                	jmp    f0102a3a <debuginfo_eip+0x1d4>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0102a36:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0102a3a:	39 c6                	cmp    %eax,%esi
f0102a3c:	7e 2b                	jle    f0102a69 <debuginfo_eip+0x203>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0102a3e:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0102a42:	83 c0 01             	add    $0x1,%eax
f0102a45:	83 c2 0c             	add    $0xc,%edx
f0102a48:	80 f9 a0             	cmp    $0xa0,%cl
f0102a4b:	74 e9                	je     f0102a36 <debuginfo_eip+0x1d0>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102a4d:	b8 00 00 00 00       	mov    $0x0,%eax
f0102a52:	eb 1a                	jmp    f0102a6e <debuginfo_eip+0x208>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0102a54:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102a59:	eb 13                	jmp    f0102a6e <debuginfo_eip+0x208>
f0102a5b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102a60:	eb 0c                	jmp    f0102a6e <debuginfo_eip+0x208>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0102a62:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102a67:	eb 05                	jmp    f0102a6e <debuginfo_eip+0x208>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102a69:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102a6e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102a71:	5b                   	pop    %ebx
f0102a72:	5e                   	pop    %esi
f0102a73:	5f                   	pop    %edi
f0102a74:	5d                   	pop    %ebp
f0102a75:	c3                   	ret    

f0102a76 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0102a76:	55                   	push   %ebp
f0102a77:	89 e5                	mov    %esp,%ebp
f0102a79:	57                   	push   %edi
f0102a7a:	56                   	push   %esi
f0102a7b:	53                   	push   %ebx
f0102a7c:	83 ec 1c             	sub    $0x1c,%esp
f0102a7f:	89 c7                	mov    %eax,%edi
f0102a81:	89 d6                	mov    %edx,%esi
f0102a83:	8b 45 08             	mov    0x8(%ebp),%eax
f0102a86:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102a89:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102a8c:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0102a8f:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0102a92:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102a97:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0102a9a:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0102a9d:	39 d3                	cmp    %edx,%ebx
f0102a9f:	72 05                	jb     f0102aa6 <printnum+0x30>
f0102aa1:	39 45 10             	cmp    %eax,0x10(%ebp)
f0102aa4:	77 45                	ja     f0102aeb <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0102aa6:	83 ec 0c             	sub    $0xc,%esp
f0102aa9:	ff 75 18             	pushl  0x18(%ebp)
f0102aac:	8b 45 14             	mov    0x14(%ebp),%eax
f0102aaf:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0102ab2:	53                   	push   %ebx
f0102ab3:	ff 75 10             	pushl  0x10(%ebp)
f0102ab6:	83 ec 08             	sub    $0x8,%esp
f0102ab9:	ff 75 e4             	pushl  -0x1c(%ebp)
f0102abc:	ff 75 e0             	pushl  -0x20(%ebp)
f0102abf:	ff 75 dc             	pushl  -0x24(%ebp)
f0102ac2:	ff 75 d8             	pushl  -0x28(%ebp)
f0102ac5:	e8 46 09 00 00       	call   f0103410 <__udivdi3>
f0102aca:	83 c4 18             	add    $0x18,%esp
f0102acd:	52                   	push   %edx
f0102ace:	50                   	push   %eax
f0102acf:	89 f2                	mov    %esi,%edx
f0102ad1:	89 f8                	mov    %edi,%eax
f0102ad3:	e8 9e ff ff ff       	call   f0102a76 <printnum>
f0102ad8:	83 c4 20             	add    $0x20,%esp
f0102adb:	eb 18                	jmp    f0102af5 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0102add:	83 ec 08             	sub    $0x8,%esp
f0102ae0:	56                   	push   %esi
f0102ae1:	ff 75 18             	pushl  0x18(%ebp)
f0102ae4:	ff d7                	call   *%edi
f0102ae6:	83 c4 10             	add    $0x10,%esp
f0102ae9:	eb 03                	jmp    f0102aee <printnum+0x78>
f0102aeb:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0102aee:	83 eb 01             	sub    $0x1,%ebx
f0102af1:	85 db                	test   %ebx,%ebx
f0102af3:	7f e8                	jg     f0102add <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0102af5:	83 ec 08             	sub    $0x8,%esp
f0102af8:	56                   	push   %esi
f0102af9:	83 ec 04             	sub    $0x4,%esp
f0102afc:	ff 75 e4             	pushl  -0x1c(%ebp)
f0102aff:	ff 75 e0             	pushl  -0x20(%ebp)
f0102b02:	ff 75 dc             	pushl  -0x24(%ebp)
f0102b05:	ff 75 d8             	pushl  -0x28(%ebp)
f0102b08:	e8 33 0a 00 00       	call   f0103540 <__umoddi3>
f0102b0d:	83 c4 14             	add    $0x14,%esp
f0102b10:	0f be 80 20 47 10 f0 	movsbl -0xfefb8e0(%eax),%eax
f0102b17:	50                   	push   %eax
f0102b18:	ff d7                	call   *%edi
}
f0102b1a:	83 c4 10             	add    $0x10,%esp
f0102b1d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102b20:	5b                   	pop    %ebx
f0102b21:	5e                   	pop    %esi
f0102b22:	5f                   	pop    %edi
f0102b23:	5d                   	pop    %ebp
f0102b24:	c3                   	ret    

f0102b25 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0102b25:	55                   	push   %ebp
f0102b26:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0102b28:	83 fa 01             	cmp    $0x1,%edx
f0102b2b:	7e 0e                	jle    f0102b3b <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0102b2d:	8b 10                	mov    (%eax),%edx
f0102b2f:	8d 4a 08             	lea    0x8(%edx),%ecx
f0102b32:	89 08                	mov    %ecx,(%eax)
f0102b34:	8b 02                	mov    (%edx),%eax
f0102b36:	8b 52 04             	mov    0x4(%edx),%edx
f0102b39:	eb 22                	jmp    f0102b5d <getuint+0x38>
	else if (lflag)
f0102b3b:	85 d2                	test   %edx,%edx
f0102b3d:	74 10                	je     f0102b4f <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0102b3f:	8b 10                	mov    (%eax),%edx
f0102b41:	8d 4a 04             	lea    0x4(%edx),%ecx
f0102b44:	89 08                	mov    %ecx,(%eax)
f0102b46:	8b 02                	mov    (%edx),%eax
f0102b48:	ba 00 00 00 00       	mov    $0x0,%edx
f0102b4d:	eb 0e                	jmp    f0102b5d <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0102b4f:	8b 10                	mov    (%eax),%edx
f0102b51:	8d 4a 04             	lea    0x4(%edx),%ecx
f0102b54:	89 08                	mov    %ecx,(%eax)
f0102b56:	8b 02                	mov    (%edx),%eax
f0102b58:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0102b5d:	5d                   	pop    %ebp
f0102b5e:	c3                   	ret    

f0102b5f <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0102b5f:	55                   	push   %ebp
f0102b60:	89 e5                	mov    %esp,%ebp
f0102b62:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0102b65:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0102b69:	8b 10                	mov    (%eax),%edx
f0102b6b:	3b 50 04             	cmp    0x4(%eax),%edx
f0102b6e:	73 0a                	jae    f0102b7a <sprintputch+0x1b>
		*b->buf++ = ch;
f0102b70:	8d 4a 01             	lea    0x1(%edx),%ecx
f0102b73:	89 08                	mov    %ecx,(%eax)
f0102b75:	8b 45 08             	mov    0x8(%ebp),%eax
f0102b78:	88 02                	mov    %al,(%edx)
}
f0102b7a:	5d                   	pop    %ebp
f0102b7b:	c3                   	ret    

f0102b7c <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0102b7c:	55                   	push   %ebp
f0102b7d:	89 e5                	mov    %esp,%ebp
f0102b7f:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0102b82:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0102b85:	50                   	push   %eax
f0102b86:	ff 75 10             	pushl  0x10(%ebp)
f0102b89:	ff 75 0c             	pushl  0xc(%ebp)
f0102b8c:	ff 75 08             	pushl  0x8(%ebp)
f0102b8f:	e8 05 00 00 00       	call   f0102b99 <vprintfmt>
	va_end(ap);
}
f0102b94:	83 c4 10             	add    $0x10,%esp
f0102b97:	c9                   	leave  
f0102b98:	c3                   	ret    

f0102b99 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0102b99:	55                   	push   %ebp
f0102b9a:	89 e5                	mov    %esp,%ebp
f0102b9c:	57                   	push   %edi
f0102b9d:	56                   	push   %esi
f0102b9e:	53                   	push   %ebx
f0102b9f:	83 ec 2c             	sub    $0x2c,%esp
f0102ba2:	8b 75 08             	mov    0x8(%ebp),%esi
f0102ba5:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102ba8:	8b 7d 10             	mov    0x10(%ebp),%edi
f0102bab:	eb 12                	jmp    f0102bbf <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0102bad:	85 c0                	test   %eax,%eax
f0102baf:	0f 84 89 03 00 00    	je     f0102f3e <vprintfmt+0x3a5>
				return;
			putch(ch, putdat);
f0102bb5:	83 ec 08             	sub    $0x8,%esp
f0102bb8:	53                   	push   %ebx
f0102bb9:	50                   	push   %eax
f0102bba:	ff d6                	call   *%esi
f0102bbc:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0102bbf:	83 c7 01             	add    $0x1,%edi
f0102bc2:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0102bc6:	83 f8 25             	cmp    $0x25,%eax
f0102bc9:	75 e2                	jne    f0102bad <vprintfmt+0x14>
f0102bcb:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0102bcf:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0102bd6:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102bdd:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0102be4:	ba 00 00 00 00       	mov    $0x0,%edx
f0102be9:	eb 07                	jmp    f0102bf2 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102beb:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0102bee:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102bf2:	8d 47 01             	lea    0x1(%edi),%eax
f0102bf5:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102bf8:	0f b6 07             	movzbl (%edi),%eax
f0102bfb:	0f b6 c8             	movzbl %al,%ecx
f0102bfe:	83 e8 23             	sub    $0x23,%eax
f0102c01:	3c 55                	cmp    $0x55,%al
f0102c03:	0f 87 1a 03 00 00    	ja     f0102f23 <vprintfmt+0x38a>
f0102c09:	0f b6 c0             	movzbl %al,%eax
f0102c0c:	ff 24 85 ac 47 10 f0 	jmp    *-0xfefb854(,%eax,4)
f0102c13:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0102c16:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0102c1a:	eb d6                	jmp    f0102bf2 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c1c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102c1f:	b8 00 00 00 00       	mov    $0x0,%eax
f0102c24:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0102c27:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0102c2a:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f0102c2e:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0102c31:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0102c34:	83 fa 09             	cmp    $0x9,%edx
f0102c37:	77 39                	ja     f0102c72 <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0102c39:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0102c3c:	eb e9                	jmp    f0102c27 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0102c3e:	8b 45 14             	mov    0x14(%ebp),%eax
f0102c41:	8d 48 04             	lea    0x4(%eax),%ecx
f0102c44:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0102c47:	8b 00                	mov    (%eax),%eax
f0102c49:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c4c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0102c4f:	eb 27                	jmp    f0102c78 <vprintfmt+0xdf>
f0102c51:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102c54:	85 c0                	test   %eax,%eax
f0102c56:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102c5b:	0f 49 c8             	cmovns %eax,%ecx
f0102c5e:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c61:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102c64:	eb 8c                	jmp    f0102bf2 <vprintfmt+0x59>
f0102c66:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0102c69:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0102c70:	eb 80                	jmp    f0102bf2 <vprintfmt+0x59>
f0102c72:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0102c75:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0102c78:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102c7c:	0f 89 70 ff ff ff    	jns    f0102bf2 <vprintfmt+0x59>
				width = precision, precision = -1;
f0102c82:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102c85:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102c88:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102c8f:	e9 5e ff ff ff       	jmp    f0102bf2 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0102c94:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c97:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0102c9a:	e9 53 ff ff ff       	jmp    f0102bf2 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0102c9f:	8b 45 14             	mov    0x14(%ebp),%eax
f0102ca2:	8d 50 04             	lea    0x4(%eax),%edx
f0102ca5:	89 55 14             	mov    %edx,0x14(%ebp)
f0102ca8:	83 ec 08             	sub    $0x8,%esp
f0102cab:	53                   	push   %ebx
f0102cac:	ff 30                	pushl  (%eax)
f0102cae:	ff d6                	call   *%esi
			break;
f0102cb0:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102cb3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0102cb6:	e9 04 ff ff ff       	jmp    f0102bbf <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0102cbb:	8b 45 14             	mov    0x14(%ebp),%eax
f0102cbe:	8d 50 04             	lea    0x4(%eax),%edx
f0102cc1:	89 55 14             	mov    %edx,0x14(%ebp)
f0102cc4:	8b 00                	mov    (%eax),%eax
f0102cc6:	99                   	cltd   
f0102cc7:	31 d0                	xor    %edx,%eax
f0102cc9:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0102ccb:	83 f8 06             	cmp    $0x6,%eax
f0102cce:	7f 0b                	jg     f0102cdb <vprintfmt+0x142>
f0102cd0:	8b 14 85 04 49 10 f0 	mov    -0xfefb6fc(,%eax,4),%edx
f0102cd7:	85 d2                	test   %edx,%edx
f0102cd9:	75 18                	jne    f0102cf3 <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f0102cdb:	50                   	push   %eax
f0102cdc:	68 38 47 10 f0       	push   $0xf0104738
f0102ce1:	53                   	push   %ebx
f0102ce2:	56                   	push   %esi
f0102ce3:	e8 94 fe ff ff       	call   f0102b7c <printfmt>
f0102ce8:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102ceb:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0102cee:	e9 cc fe ff ff       	jmp    f0102bbf <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0102cf3:	52                   	push   %edx
f0102cf4:	68 50 44 10 f0       	push   $0xf0104450
f0102cf9:	53                   	push   %ebx
f0102cfa:	56                   	push   %esi
f0102cfb:	e8 7c fe ff ff       	call   f0102b7c <printfmt>
f0102d00:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102d03:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102d06:	e9 b4 fe ff ff       	jmp    f0102bbf <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0102d0b:	8b 45 14             	mov    0x14(%ebp),%eax
f0102d0e:	8d 50 04             	lea    0x4(%eax),%edx
f0102d11:	89 55 14             	mov    %edx,0x14(%ebp)
f0102d14:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0102d16:	85 ff                	test   %edi,%edi
f0102d18:	b8 31 47 10 f0       	mov    $0xf0104731,%eax
f0102d1d:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0102d20:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102d24:	0f 8e 94 00 00 00    	jle    f0102dbe <vprintfmt+0x225>
f0102d2a:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0102d2e:	0f 84 98 00 00 00    	je     f0102dcc <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
f0102d34:	83 ec 08             	sub    $0x8,%esp
f0102d37:	ff 75 d0             	pushl  -0x30(%ebp)
f0102d3a:	57                   	push   %edi
f0102d3b:	e8 5f 03 00 00       	call   f010309f <strnlen>
f0102d40:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0102d43:	29 c1                	sub    %eax,%ecx
f0102d45:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0102d48:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0102d4b:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0102d4f:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102d52:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0102d55:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102d57:	eb 0f                	jmp    f0102d68 <vprintfmt+0x1cf>
					putch(padc, putdat);
f0102d59:	83 ec 08             	sub    $0x8,%esp
f0102d5c:	53                   	push   %ebx
f0102d5d:	ff 75 e0             	pushl  -0x20(%ebp)
f0102d60:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102d62:	83 ef 01             	sub    $0x1,%edi
f0102d65:	83 c4 10             	add    $0x10,%esp
f0102d68:	85 ff                	test   %edi,%edi
f0102d6a:	7f ed                	jg     f0102d59 <vprintfmt+0x1c0>
f0102d6c:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102d6f:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0102d72:	85 c9                	test   %ecx,%ecx
f0102d74:	b8 00 00 00 00       	mov    $0x0,%eax
f0102d79:	0f 49 c1             	cmovns %ecx,%eax
f0102d7c:	29 c1                	sub    %eax,%ecx
f0102d7e:	89 75 08             	mov    %esi,0x8(%ebp)
f0102d81:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102d84:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102d87:	89 cb                	mov    %ecx,%ebx
f0102d89:	eb 4d                	jmp    f0102dd8 <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0102d8b:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0102d8f:	74 1b                	je     f0102dac <vprintfmt+0x213>
f0102d91:	0f be c0             	movsbl %al,%eax
f0102d94:	83 e8 20             	sub    $0x20,%eax
f0102d97:	83 f8 5e             	cmp    $0x5e,%eax
f0102d9a:	76 10                	jbe    f0102dac <vprintfmt+0x213>
					putch('?', putdat);
f0102d9c:	83 ec 08             	sub    $0x8,%esp
f0102d9f:	ff 75 0c             	pushl  0xc(%ebp)
f0102da2:	6a 3f                	push   $0x3f
f0102da4:	ff 55 08             	call   *0x8(%ebp)
f0102da7:	83 c4 10             	add    $0x10,%esp
f0102daa:	eb 0d                	jmp    f0102db9 <vprintfmt+0x220>
				else
					putch(ch, putdat);
f0102dac:	83 ec 08             	sub    $0x8,%esp
f0102daf:	ff 75 0c             	pushl  0xc(%ebp)
f0102db2:	52                   	push   %edx
f0102db3:	ff 55 08             	call   *0x8(%ebp)
f0102db6:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0102db9:	83 eb 01             	sub    $0x1,%ebx
f0102dbc:	eb 1a                	jmp    f0102dd8 <vprintfmt+0x23f>
f0102dbe:	89 75 08             	mov    %esi,0x8(%ebp)
f0102dc1:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102dc4:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102dc7:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0102dca:	eb 0c                	jmp    f0102dd8 <vprintfmt+0x23f>
f0102dcc:	89 75 08             	mov    %esi,0x8(%ebp)
f0102dcf:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102dd2:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102dd5:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0102dd8:	83 c7 01             	add    $0x1,%edi
f0102ddb:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0102ddf:	0f be d0             	movsbl %al,%edx
f0102de2:	85 d2                	test   %edx,%edx
f0102de4:	74 23                	je     f0102e09 <vprintfmt+0x270>
f0102de6:	85 f6                	test   %esi,%esi
f0102de8:	78 a1                	js     f0102d8b <vprintfmt+0x1f2>
f0102dea:	83 ee 01             	sub    $0x1,%esi
f0102ded:	79 9c                	jns    f0102d8b <vprintfmt+0x1f2>
f0102def:	89 df                	mov    %ebx,%edi
f0102df1:	8b 75 08             	mov    0x8(%ebp),%esi
f0102df4:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102df7:	eb 18                	jmp    f0102e11 <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0102df9:	83 ec 08             	sub    $0x8,%esp
f0102dfc:	53                   	push   %ebx
f0102dfd:	6a 20                	push   $0x20
f0102dff:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0102e01:	83 ef 01             	sub    $0x1,%edi
f0102e04:	83 c4 10             	add    $0x10,%esp
f0102e07:	eb 08                	jmp    f0102e11 <vprintfmt+0x278>
f0102e09:	89 df                	mov    %ebx,%edi
f0102e0b:	8b 75 08             	mov    0x8(%ebp),%esi
f0102e0e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102e11:	85 ff                	test   %edi,%edi
f0102e13:	7f e4                	jg     f0102df9 <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102e15:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102e18:	e9 a2 fd ff ff       	jmp    f0102bbf <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0102e1d:	83 fa 01             	cmp    $0x1,%edx
f0102e20:	7e 16                	jle    f0102e38 <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f0102e22:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e25:	8d 50 08             	lea    0x8(%eax),%edx
f0102e28:	89 55 14             	mov    %edx,0x14(%ebp)
f0102e2b:	8b 50 04             	mov    0x4(%eax),%edx
f0102e2e:	8b 00                	mov    (%eax),%eax
f0102e30:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102e33:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0102e36:	eb 32                	jmp    f0102e6a <vprintfmt+0x2d1>
	else if (lflag)
f0102e38:	85 d2                	test   %edx,%edx
f0102e3a:	74 18                	je     f0102e54 <vprintfmt+0x2bb>
		return va_arg(*ap, long);
f0102e3c:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e3f:	8d 50 04             	lea    0x4(%eax),%edx
f0102e42:	89 55 14             	mov    %edx,0x14(%ebp)
f0102e45:	8b 00                	mov    (%eax),%eax
f0102e47:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102e4a:	89 c1                	mov    %eax,%ecx
f0102e4c:	c1 f9 1f             	sar    $0x1f,%ecx
f0102e4f:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0102e52:	eb 16                	jmp    f0102e6a <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
f0102e54:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e57:	8d 50 04             	lea    0x4(%eax),%edx
f0102e5a:	89 55 14             	mov    %edx,0x14(%ebp)
f0102e5d:	8b 00                	mov    (%eax),%eax
f0102e5f:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102e62:	89 c1                	mov    %eax,%ecx
f0102e64:	c1 f9 1f             	sar    $0x1f,%ecx
f0102e67:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0102e6a:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102e6d:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0102e70:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0102e75:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0102e79:	79 74                	jns    f0102eef <vprintfmt+0x356>
				putch('-', putdat);
f0102e7b:	83 ec 08             	sub    $0x8,%esp
f0102e7e:	53                   	push   %ebx
f0102e7f:	6a 2d                	push   $0x2d
f0102e81:	ff d6                	call   *%esi
				num = -(long long) num;
f0102e83:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102e86:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102e89:	f7 d8                	neg    %eax
f0102e8b:	83 d2 00             	adc    $0x0,%edx
f0102e8e:	f7 da                	neg    %edx
f0102e90:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0102e93:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0102e98:	eb 55                	jmp    f0102eef <vprintfmt+0x356>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0102e9a:	8d 45 14             	lea    0x14(%ebp),%eax
f0102e9d:	e8 83 fc ff ff       	call   f0102b25 <getuint>
			base = 10;
f0102ea2:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0102ea7:	eb 46                	jmp    f0102eef <vprintfmt+0x356>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f0102ea9:	8d 45 14             	lea    0x14(%ebp),%eax
f0102eac:	e8 74 fc ff ff       	call   f0102b25 <getuint>
			base = 8;
f0102eb1:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0102eb6:	eb 37                	jmp    f0102eef <vprintfmt+0x356>

		// pointer
		case 'p':
			putch('0', putdat);
f0102eb8:	83 ec 08             	sub    $0x8,%esp
f0102ebb:	53                   	push   %ebx
f0102ebc:	6a 30                	push   $0x30
f0102ebe:	ff d6                	call   *%esi
			putch('x', putdat);
f0102ec0:	83 c4 08             	add    $0x8,%esp
f0102ec3:	53                   	push   %ebx
f0102ec4:	6a 78                	push   $0x78
f0102ec6:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0102ec8:	8b 45 14             	mov    0x14(%ebp),%eax
f0102ecb:	8d 50 04             	lea    0x4(%eax),%edx
f0102ece:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0102ed1:	8b 00                	mov    (%eax),%eax
f0102ed3:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0102ed8:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0102edb:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0102ee0:	eb 0d                	jmp    f0102eef <vprintfmt+0x356>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0102ee2:	8d 45 14             	lea    0x14(%ebp),%eax
f0102ee5:	e8 3b fc ff ff       	call   f0102b25 <getuint>
			base = 16;
f0102eea:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0102eef:	83 ec 0c             	sub    $0xc,%esp
f0102ef2:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0102ef6:	57                   	push   %edi
f0102ef7:	ff 75 e0             	pushl  -0x20(%ebp)
f0102efa:	51                   	push   %ecx
f0102efb:	52                   	push   %edx
f0102efc:	50                   	push   %eax
f0102efd:	89 da                	mov    %ebx,%edx
f0102eff:	89 f0                	mov    %esi,%eax
f0102f01:	e8 70 fb ff ff       	call   f0102a76 <printnum>
			break;
f0102f06:	83 c4 20             	add    $0x20,%esp
f0102f09:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102f0c:	e9 ae fc ff ff       	jmp    f0102bbf <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0102f11:	83 ec 08             	sub    $0x8,%esp
f0102f14:	53                   	push   %ebx
f0102f15:	51                   	push   %ecx
f0102f16:	ff d6                	call   *%esi
			break;
f0102f18:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102f1b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0102f1e:	e9 9c fc ff ff       	jmp    f0102bbf <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0102f23:	83 ec 08             	sub    $0x8,%esp
f0102f26:	53                   	push   %ebx
f0102f27:	6a 25                	push   $0x25
f0102f29:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0102f2b:	83 c4 10             	add    $0x10,%esp
f0102f2e:	eb 03                	jmp    f0102f33 <vprintfmt+0x39a>
f0102f30:	83 ef 01             	sub    $0x1,%edi
f0102f33:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0102f37:	75 f7                	jne    f0102f30 <vprintfmt+0x397>
f0102f39:	e9 81 fc ff ff       	jmp    f0102bbf <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0102f3e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102f41:	5b                   	pop    %ebx
f0102f42:	5e                   	pop    %esi
f0102f43:	5f                   	pop    %edi
f0102f44:	5d                   	pop    %ebp
f0102f45:	c3                   	ret    

f0102f46 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0102f46:	55                   	push   %ebp
f0102f47:	89 e5                	mov    %esp,%ebp
f0102f49:	83 ec 18             	sub    $0x18,%esp
f0102f4c:	8b 45 08             	mov    0x8(%ebp),%eax
f0102f4f:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0102f52:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0102f55:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0102f59:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0102f5c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0102f63:	85 c0                	test   %eax,%eax
f0102f65:	74 26                	je     f0102f8d <vsnprintf+0x47>
f0102f67:	85 d2                	test   %edx,%edx
f0102f69:	7e 22                	jle    f0102f8d <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0102f6b:	ff 75 14             	pushl  0x14(%ebp)
f0102f6e:	ff 75 10             	pushl  0x10(%ebp)
f0102f71:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0102f74:	50                   	push   %eax
f0102f75:	68 5f 2b 10 f0       	push   $0xf0102b5f
f0102f7a:	e8 1a fc ff ff       	call   f0102b99 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0102f7f:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0102f82:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0102f85:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102f88:	83 c4 10             	add    $0x10,%esp
f0102f8b:	eb 05                	jmp    f0102f92 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0102f8d:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0102f92:	c9                   	leave  
f0102f93:	c3                   	ret    

f0102f94 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0102f94:	55                   	push   %ebp
f0102f95:	89 e5                	mov    %esp,%ebp
f0102f97:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0102f9a:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0102f9d:	50                   	push   %eax
f0102f9e:	ff 75 10             	pushl  0x10(%ebp)
f0102fa1:	ff 75 0c             	pushl  0xc(%ebp)
f0102fa4:	ff 75 08             	pushl  0x8(%ebp)
f0102fa7:	e8 9a ff ff ff       	call   f0102f46 <vsnprintf>
	va_end(ap);

	return rc;
}
f0102fac:	c9                   	leave  
f0102fad:	c3                   	ret    

f0102fae <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0102fae:	55                   	push   %ebp
f0102faf:	89 e5                	mov    %esp,%ebp
f0102fb1:	57                   	push   %edi
f0102fb2:	56                   	push   %esi
f0102fb3:	53                   	push   %ebx
f0102fb4:	83 ec 0c             	sub    $0xc,%esp
f0102fb7:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0102fba:	85 c0                	test   %eax,%eax
f0102fbc:	74 11                	je     f0102fcf <readline+0x21>
		cprintf("%s", prompt);
f0102fbe:	83 ec 08             	sub    $0x8,%esp
f0102fc1:	50                   	push   %eax
f0102fc2:	68 50 44 10 f0       	push   $0xf0104450
f0102fc7:	e8 90 f7 ff ff       	call   f010275c <cprintf>
f0102fcc:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0102fcf:	83 ec 0c             	sub    $0xc,%esp
f0102fd2:	6a 00                	push   $0x0
f0102fd4:	e8 48 d6 ff ff       	call   f0100621 <iscons>
f0102fd9:	89 c7                	mov    %eax,%edi
f0102fdb:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0102fde:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0102fe3:	e8 28 d6 ff ff       	call   f0100610 <getchar>
f0102fe8:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0102fea:	85 c0                	test   %eax,%eax
f0102fec:	79 18                	jns    f0103006 <readline+0x58>
			cprintf("read error: %e\n", c);
f0102fee:	83 ec 08             	sub    $0x8,%esp
f0102ff1:	50                   	push   %eax
f0102ff2:	68 20 49 10 f0       	push   $0xf0104920
f0102ff7:	e8 60 f7 ff ff       	call   f010275c <cprintf>
			return NULL;
f0102ffc:	83 c4 10             	add    $0x10,%esp
f0102fff:	b8 00 00 00 00       	mov    $0x0,%eax
f0103004:	eb 79                	jmp    f010307f <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0103006:	83 f8 08             	cmp    $0x8,%eax
f0103009:	0f 94 c2             	sete   %dl
f010300c:	83 f8 7f             	cmp    $0x7f,%eax
f010300f:	0f 94 c0             	sete   %al
f0103012:	08 c2                	or     %al,%dl
f0103014:	74 1a                	je     f0103030 <readline+0x82>
f0103016:	85 f6                	test   %esi,%esi
f0103018:	7e 16                	jle    f0103030 <readline+0x82>
			if (echoing)
f010301a:	85 ff                	test   %edi,%edi
f010301c:	74 0d                	je     f010302b <readline+0x7d>
				cputchar('\b');
f010301e:	83 ec 0c             	sub    $0xc,%esp
f0103021:	6a 08                	push   $0x8
f0103023:	e8 d8 d5 ff ff       	call   f0100600 <cputchar>
f0103028:	83 c4 10             	add    $0x10,%esp
			i--;
f010302b:	83 ee 01             	sub    $0x1,%esi
f010302e:	eb b3                	jmp    f0102fe3 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0103030:	83 fb 1f             	cmp    $0x1f,%ebx
f0103033:	7e 23                	jle    f0103058 <readline+0xaa>
f0103035:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010303b:	7f 1b                	jg     f0103058 <readline+0xaa>
			if (echoing)
f010303d:	85 ff                	test   %edi,%edi
f010303f:	74 0c                	je     f010304d <readline+0x9f>
				cputchar(c);
f0103041:	83 ec 0c             	sub    $0xc,%esp
f0103044:	53                   	push   %ebx
f0103045:	e8 b6 d5 ff ff       	call   f0100600 <cputchar>
f010304a:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f010304d:	88 9e 40 75 11 f0    	mov    %bl,-0xfee8ac0(%esi)
f0103053:	8d 76 01             	lea    0x1(%esi),%esi
f0103056:	eb 8b                	jmp    f0102fe3 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0103058:	83 fb 0a             	cmp    $0xa,%ebx
f010305b:	74 05                	je     f0103062 <readline+0xb4>
f010305d:	83 fb 0d             	cmp    $0xd,%ebx
f0103060:	75 81                	jne    f0102fe3 <readline+0x35>
			if (echoing)
f0103062:	85 ff                	test   %edi,%edi
f0103064:	74 0d                	je     f0103073 <readline+0xc5>
				cputchar('\n');
f0103066:	83 ec 0c             	sub    $0xc,%esp
f0103069:	6a 0a                	push   $0xa
f010306b:	e8 90 d5 ff ff       	call   f0100600 <cputchar>
f0103070:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0103073:	c6 86 40 75 11 f0 00 	movb   $0x0,-0xfee8ac0(%esi)
			return buf;
f010307a:	b8 40 75 11 f0       	mov    $0xf0117540,%eax
		}
	}
}
f010307f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103082:	5b                   	pop    %ebx
f0103083:	5e                   	pop    %esi
f0103084:	5f                   	pop    %edi
f0103085:	5d                   	pop    %ebp
f0103086:	c3                   	ret    

f0103087 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0103087:	55                   	push   %ebp
f0103088:	89 e5                	mov    %esp,%ebp
f010308a:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f010308d:	b8 00 00 00 00       	mov    $0x0,%eax
f0103092:	eb 03                	jmp    f0103097 <strlen+0x10>
		n++;
f0103094:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0103097:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f010309b:	75 f7                	jne    f0103094 <strlen+0xd>
		n++;
	return n;
}
f010309d:	5d                   	pop    %ebp
f010309e:	c3                   	ret    

f010309f <strnlen>:

int
strnlen(const char *s, size_t size)
{
f010309f:	55                   	push   %ebp
f01030a0:	89 e5                	mov    %esp,%ebp
f01030a2:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01030a5:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01030a8:	ba 00 00 00 00       	mov    $0x0,%edx
f01030ad:	eb 03                	jmp    f01030b2 <strnlen+0x13>
		n++;
f01030af:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01030b2:	39 c2                	cmp    %eax,%edx
f01030b4:	74 08                	je     f01030be <strnlen+0x1f>
f01030b6:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f01030ba:	75 f3                	jne    f01030af <strnlen+0x10>
f01030bc:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f01030be:	5d                   	pop    %ebp
f01030bf:	c3                   	ret    

f01030c0 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01030c0:	55                   	push   %ebp
f01030c1:	89 e5                	mov    %esp,%ebp
f01030c3:	53                   	push   %ebx
f01030c4:	8b 45 08             	mov    0x8(%ebp),%eax
f01030c7:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01030ca:	89 c2                	mov    %eax,%edx
f01030cc:	83 c2 01             	add    $0x1,%edx
f01030cf:	83 c1 01             	add    $0x1,%ecx
f01030d2:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f01030d6:	88 5a ff             	mov    %bl,-0x1(%edx)
f01030d9:	84 db                	test   %bl,%bl
f01030db:	75 ef                	jne    f01030cc <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f01030dd:	5b                   	pop    %ebx
f01030de:	5d                   	pop    %ebp
f01030df:	c3                   	ret    

f01030e0 <strcat>:

char *
strcat(char *dst, const char *src)
{
f01030e0:	55                   	push   %ebp
f01030e1:	89 e5                	mov    %esp,%ebp
f01030e3:	53                   	push   %ebx
f01030e4:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01030e7:	53                   	push   %ebx
f01030e8:	e8 9a ff ff ff       	call   f0103087 <strlen>
f01030ed:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f01030f0:	ff 75 0c             	pushl  0xc(%ebp)
f01030f3:	01 d8                	add    %ebx,%eax
f01030f5:	50                   	push   %eax
f01030f6:	e8 c5 ff ff ff       	call   f01030c0 <strcpy>
	return dst;
}
f01030fb:	89 d8                	mov    %ebx,%eax
f01030fd:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103100:	c9                   	leave  
f0103101:	c3                   	ret    

f0103102 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0103102:	55                   	push   %ebp
f0103103:	89 e5                	mov    %esp,%ebp
f0103105:	56                   	push   %esi
f0103106:	53                   	push   %ebx
f0103107:	8b 75 08             	mov    0x8(%ebp),%esi
f010310a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010310d:	89 f3                	mov    %esi,%ebx
f010310f:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103112:	89 f2                	mov    %esi,%edx
f0103114:	eb 0f                	jmp    f0103125 <strncpy+0x23>
		*dst++ = *src;
f0103116:	83 c2 01             	add    $0x1,%edx
f0103119:	0f b6 01             	movzbl (%ecx),%eax
f010311c:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f010311f:	80 39 01             	cmpb   $0x1,(%ecx)
f0103122:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103125:	39 da                	cmp    %ebx,%edx
f0103127:	75 ed                	jne    f0103116 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0103129:	89 f0                	mov    %esi,%eax
f010312b:	5b                   	pop    %ebx
f010312c:	5e                   	pop    %esi
f010312d:	5d                   	pop    %ebp
f010312e:	c3                   	ret    

f010312f <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010312f:	55                   	push   %ebp
f0103130:	89 e5                	mov    %esp,%ebp
f0103132:	56                   	push   %esi
f0103133:	53                   	push   %ebx
f0103134:	8b 75 08             	mov    0x8(%ebp),%esi
f0103137:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010313a:	8b 55 10             	mov    0x10(%ebp),%edx
f010313d:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f010313f:	85 d2                	test   %edx,%edx
f0103141:	74 21                	je     f0103164 <strlcpy+0x35>
f0103143:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0103147:	89 f2                	mov    %esi,%edx
f0103149:	eb 09                	jmp    f0103154 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f010314b:	83 c2 01             	add    $0x1,%edx
f010314e:	83 c1 01             	add    $0x1,%ecx
f0103151:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0103154:	39 c2                	cmp    %eax,%edx
f0103156:	74 09                	je     f0103161 <strlcpy+0x32>
f0103158:	0f b6 19             	movzbl (%ecx),%ebx
f010315b:	84 db                	test   %bl,%bl
f010315d:	75 ec                	jne    f010314b <strlcpy+0x1c>
f010315f:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f0103161:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0103164:	29 f0                	sub    %esi,%eax
}
f0103166:	5b                   	pop    %ebx
f0103167:	5e                   	pop    %esi
f0103168:	5d                   	pop    %ebp
f0103169:	c3                   	ret    

f010316a <strcmp>:

int
strcmp(const char *p, const char *q)
{
f010316a:	55                   	push   %ebp
f010316b:	89 e5                	mov    %esp,%ebp
f010316d:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103170:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0103173:	eb 06                	jmp    f010317b <strcmp+0x11>
		p++, q++;
f0103175:	83 c1 01             	add    $0x1,%ecx
f0103178:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f010317b:	0f b6 01             	movzbl (%ecx),%eax
f010317e:	84 c0                	test   %al,%al
f0103180:	74 04                	je     f0103186 <strcmp+0x1c>
f0103182:	3a 02                	cmp    (%edx),%al
f0103184:	74 ef                	je     f0103175 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0103186:	0f b6 c0             	movzbl %al,%eax
f0103189:	0f b6 12             	movzbl (%edx),%edx
f010318c:	29 d0                	sub    %edx,%eax
}
f010318e:	5d                   	pop    %ebp
f010318f:	c3                   	ret    

f0103190 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0103190:	55                   	push   %ebp
f0103191:	89 e5                	mov    %esp,%ebp
f0103193:	53                   	push   %ebx
f0103194:	8b 45 08             	mov    0x8(%ebp),%eax
f0103197:	8b 55 0c             	mov    0xc(%ebp),%edx
f010319a:	89 c3                	mov    %eax,%ebx
f010319c:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f010319f:	eb 06                	jmp    f01031a7 <strncmp+0x17>
		n--, p++, q++;
f01031a1:	83 c0 01             	add    $0x1,%eax
f01031a4:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01031a7:	39 d8                	cmp    %ebx,%eax
f01031a9:	74 15                	je     f01031c0 <strncmp+0x30>
f01031ab:	0f b6 08             	movzbl (%eax),%ecx
f01031ae:	84 c9                	test   %cl,%cl
f01031b0:	74 04                	je     f01031b6 <strncmp+0x26>
f01031b2:	3a 0a                	cmp    (%edx),%cl
f01031b4:	74 eb                	je     f01031a1 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01031b6:	0f b6 00             	movzbl (%eax),%eax
f01031b9:	0f b6 12             	movzbl (%edx),%edx
f01031bc:	29 d0                	sub    %edx,%eax
f01031be:	eb 05                	jmp    f01031c5 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f01031c0:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01031c5:	5b                   	pop    %ebx
f01031c6:	5d                   	pop    %ebp
f01031c7:	c3                   	ret    

f01031c8 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01031c8:	55                   	push   %ebp
f01031c9:	89 e5                	mov    %esp,%ebp
f01031cb:	8b 45 08             	mov    0x8(%ebp),%eax
f01031ce:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01031d2:	eb 07                	jmp    f01031db <strchr+0x13>
		if (*s == c)
f01031d4:	38 ca                	cmp    %cl,%dl
f01031d6:	74 0f                	je     f01031e7 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01031d8:	83 c0 01             	add    $0x1,%eax
f01031db:	0f b6 10             	movzbl (%eax),%edx
f01031de:	84 d2                	test   %dl,%dl
f01031e0:	75 f2                	jne    f01031d4 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f01031e2:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01031e7:	5d                   	pop    %ebp
f01031e8:	c3                   	ret    

f01031e9 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01031e9:	55                   	push   %ebp
f01031ea:	89 e5                	mov    %esp,%ebp
f01031ec:	8b 45 08             	mov    0x8(%ebp),%eax
f01031ef:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01031f3:	eb 03                	jmp    f01031f8 <strfind+0xf>
f01031f5:	83 c0 01             	add    $0x1,%eax
f01031f8:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f01031fb:	38 ca                	cmp    %cl,%dl
f01031fd:	74 04                	je     f0103203 <strfind+0x1a>
f01031ff:	84 d2                	test   %dl,%dl
f0103201:	75 f2                	jne    f01031f5 <strfind+0xc>
			break;
	return (char *) s;
}
f0103203:	5d                   	pop    %ebp
f0103204:	c3                   	ret    

f0103205 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0103205:	55                   	push   %ebp
f0103206:	89 e5                	mov    %esp,%ebp
f0103208:	57                   	push   %edi
f0103209:	56                   	push   %esi
f010320a:	53                   	push   %ebx
f010320b:	8b 7d 08             	mov    0x8(%ebp),%edi
f010320e:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0103211:	85 c9                	test   %ecx,%ecx
f0103213:	74 36                	je     f010324b <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0103215:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010321b:	75 28                	jne    f0103245 <memset+0x40>
f010321d:	f6 c1 03             	test   $0x3,%cl
f0103220:	75 23                	jne    f0103245 <memset+0x40>
		c &= 0xFF;
f0103222:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0103226:	89 d3                	mov    %edx,%ebx
f0103228:	c1 e3 08             	shl    $0x8,%ebx
f010322b:	89 d6                	mov    %edx,%esi
f010322d:	c1 e6 18             	shl    $0x18,%esi
f0103230:	89 d0                	mov    %edx,%eax
f0103232:	c1 e0 10             	shl    $0x10,%eax
f0103235:	09 f0                	or     %esi,%eax
f0103237:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f0103239:	89 d8                	mov    %ebx,%eax
f010323b:	09 d0                	or     %edx,%eax
f010323d:	c1 e9 02             	shr    $0x2,%ecx
f0103240:	fc                   	cld    
f0103241:	f3 ab                	rep stos %eax,%es:(%edi)
f0103243:	eb 06                	jmp    f010324b <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0103245:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103248:	fc                   	cld    
f0103249:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f010324b:	89 f8                	mov    %edi,%eax
f010324d:	5b                   	pop    %ebx
f010324e:	5e                   	pop    %esi
f010324f:	5f                   	pop    %edi
f0103250:	5d                   	pop    %ebp
f0103251:	c3                   	ret    

f0103252 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0103252:	55                   	push   %ebp
f0103253:	89 e5                	mov    %esp,%ebp
f0103255:	57                   	push   %edi
f0103256:	56                   	push   %esi
f0103257:	8b 45 08             	mov    0x8(%ebp),%eax
f010325a:	8b 75 0c             	mov    0xc(%ebp),%esi
f010325d:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0103260:	39 c6                	cmp    %eax,%esi
f0103262:	73 35                	jae    f0103299 <memmove+0x47>
f0103264:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0103267:	39 d0                	cmp    %edx,%eax
f0103269:	73 2e                	jae    f0103299 <memmove+0x47>
		s += n;
		d += n;
f010326b:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010326e:	89 d6                	mov    %edx,%esi
f0103270:	09 fe                	or     %edi,%esi
f0103272:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0103278:	75 13                	jne    f010328d <memmove+0x3b>
f010327a:	f6 c1 03             	test   $0x3,%cl
f010327d:	75 0e                	jne    f010328d <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f010327f:	83 ef 04             	sub    $0x4,%edi
f0103282:	8d 72 fc             	lea    -0x4(%edx),%esi
f0103285:	c1 e9 02             	shr    $0x2,%ecx
f0103288:	fd                   	std    
f0103289:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010328b:	eb 09                	jmp    f0103296 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f010328d:	83 ef 01             	sub    $0x1,%edi
f0103290:	8d 72 ff             	lea    -0x1(%edx),%esi
f0103293:	fd                   	std    
f0103294:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0103296:	fc                   	cld    
f0103297:	eb 1d                	jmp    f01032b6 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103299:	89 f2                	mov    %esi,%edx
f010329b:	09 c2                	or     %eax,%edx
f010329d:	f6 c2 03             	test   $0x3,%dl
f01032a0:	75 0f                	jne    f01032b1 <memmove+0x5f>
f01032a2:	f6 c1 03             	test   $0x3,%cl
f01032a5:	75 0a                	jne    f01032b1 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f01032a7:	c1 e9 02             	shr    $0x2,%ecx
f01032aa:	89 c7                	mov    %eax,%edi
f01032ac:	fc                   	cld    
f01032ad:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01032af:	eb 05                	jmp    f01032b6 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01032b1:	89 c7                	mov    %eax,%edi
f01032b3:	fc                   	cld    
f01032b4:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01032b6:	5e                   	pop    %esi
f01032b7:	5f                   	pop    %edi
f01032b8:	5d                   	pop    %ebp
f01032b9:	c3                   	ret    

f01032ba <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01032ba:	55                   	push   %ebp
f01032bb:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f01032bd:	ff 75 10             	pushl  0x10(%ebp)
f01032c0:	ff 75 0c             	pushl  0xc(%ebp)
f01032c3:	ff 75 08             	pushl  0x8(%ebp)
f01032c6:	e8 87 ff ff ff       	call   f0103252 <memmove>
}
f01032cb:	c9                   	leave  
f01032cc:	c3                   	ret    

f01032cd <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01032cd:	55                   	push   %ebp
f01032ce:	89 e5                	mov    %esp,%ebp
f01032d0:	56                   	push   %esi
f01032d1:	53                   	push   %ebx
f01032d2:	8b 45 08             	mov    0x8(%ebp),%eax
f01032d5:	8b 55 0c             	mov    0xc(%ebp),%edx
f01032d8:	89 c6                	mov    %eax,%esi
f01032da:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01032dd:	eb 1a                	jmp    f01032f9 <memcmp+0x2c>
		if (*s1 != *s2)
f01032df:	0f b6 08             	movzbl (%eax),%ecx
f01032e2:	0f b6 1a             	movzbl (%edx),%ebx
f01032e5:	38 d9                	cmp    %bl,%cl
f01032e7:	74 0a                	je     f01032f3 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f01032e9:	0f b6 c1             	movzbl %cl,%eax
f01032ec:	0f b6 db             	movzbl %bl,%ebx
f01032ef:	29 d8                	sub    %ebx,%eax
f01032f1:	eb 0f                	jmp    f0103302 <memcmp+0x35>
		s1++, s2++;
f01032f3:	83 c0 01             	add    $0x1,%eax
f01032f6:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01032f9:	39 f0                	cmp    %esi,%eax
f01032fb:	75 e2                	jne    f01032df <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01032fd:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103302:	5b                   	pop    %ebx
f0103303:	5e                   	pop    %esi
f0103304:	5d                   	pop    %ebp
f0103305:	c3                   	ret    

f0103306 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0103306:	55                   	push   %ebp
f0103307:	89 e5                	mov    %esp,%ebp
f0103309:	53                   	push   %ebx
f010330a:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f010330d:	89 c1                	mov    %eax,%ecx
f010330f:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f0103312:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0103316:	eb 0a                	jmp    f0103322 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f0103318:	0f b6 10             	movzbl (%eax),%edx
f010331b:	39 da                	cmp    %ebx,%edx
f010331d:	74 07                	je     f0103326 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010331f:	83 c0 01             	add    $0x1,%eax
f0103322:	39 c8                	cmp    %ecx,%eax
f0103324:	72 f2                	jb     f0103318 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0103326:	5b                   	pop    %ebx
f0103327:	5d                   	pop    %ebp
f0103328:	c3                   	ret    

f0103329 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0103329:	55                   	push   %ebp
f010332a:	89 e5                	mov    %esp,%ebp
f010332c:	57                   	push   %edi
f010332d:	56                   	push   %esi
f010332e:	53                   	push   %ebx
f010332f:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103332:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103335:	eb 03                	jmp    f010333a <strtol+0x11>
		s++;
f0103337:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010333a:	0f b6 01             	movzbl (%ecx),%eax
f010333d:	3c 20                	cmp    $0x20,%al
f010333f:	74 f6                	je     f0103337 <strtol+0xe>
f0103341:	3c 09                	cmp    $0x9,%al
f0103343:	74 f2                	je     f0103337 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0103345:	3c 2b                	cmp    $0x2b,%al
f0103347:	75 0a                	jne    f0103353 <strtol+0x2a>
		s++;
f0103349:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f010334c:	bf 00 00 00 00       	mov    $0x0,%edi
f0103351:	eb 11                	jmp    f0103364 <strtol+0x3b>
f0103353:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0103358:	3c 2d                	cmp    $0x2d,%al
f010335a:	75 08                	jne    f0103364 <strtol+0x3b>
		s++, neg = 1;
f010335c:	83 c1 01             	add    $0x1,%ecx
f010335f:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0103364:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f010336a:	75 15                	jne    f0103381 <strtol+0x58>
f010336c:	80 39 30             	cmpb   $0x30,(%ecx)
f010336f:	75 10                	jne    f0103381 <strtol+0x58>
f0103371:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0103375:	75 7c                	jne    f01033f3 <strtol+0xca>
		s += 2, base = 16;
f0103377:	83 c1 02             	add    $0x2,%ecx
f010337a:	bb 10 00 00 00       	mov    $0x10,%ebx
f010337f:	eb 16                	jmp    f0103397 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f0103381:	85 db                	test   %ebx,%ebx
f0103383:	75 12                	jne    f0103397 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0103385:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f010338a:	80 39 30             	cmpb   $0x30,(%ecx)
f010338d:	75 08                	jne    f0103397 <strtol+0x6e>
		s++, base = 8;
f010338f:	83 c1 01             	add    $0x1,%ecx
f0103392:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f0103397:	b8 00 00 00 00       	mov    $0x0,%eax
f010339c:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f010339f:	0f b6 11             	movzbl (%ecx),%edx
f01033a2:	8d 72 d0             	lea    -0x30(%edx),%esi
f01033a5:	89 f3                	mov    %esi,%ebx
f01033a7:	80 fb 09             	cmp    $0x9,%bl
f01033aa:	77 08                	ja     f01033b4 <strtol+0x8b>
			dig = *s - '0';
f01033ac:	0f be d2             	movsbl %dl,%edx
f01033af:	83 ea 30             	sub    $0x30,%edx
f01033b2:	eb 22                	jmp    f01033d6 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f01033b4:	8d 72 9f             	lea    -0x61(%edx),%esi
f01033b7:	89 f3                	mov    %esi,%ebx
f01033b9:	80 fb 19             	cmp    $0x19,%bl
f01033bc:	77 08                	ja     f01033c6 <strtol+0x9d>
			dig = *s - 'a' + 10;
f01033be:	0f be d2             	movsbl %dl,%edx
f01033c1:	83 ea 57             	sub    $0x57,%edx
f01033c4:	eb 10                	jmp    f01033d6 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f01033c6:	8d 72 bf             	lea    -0x41(%edx),%esi
f01033c9:	89 f3                	mov    %esi,%ebx
f01033cb:	80 fb 19             	cmp    $0x19,%bl
f01033ce:	77 16                	ja     f01033e6 <strtol+0xbd>
			dig = *s - 'A' + 10;
f01033d0:	0f be d2             	movsbl %dl,%edx
f01033d3:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f01033d6:	3b 55 10             	cmp    0x10(%ebp),%edx
f01033d9:	7d 0b                	jge    f01033e6 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f01033db:	83 c1 01             	add    $0x1,%ecx
f01033de:	0f af 45 10          	imul   0x10(%ebp),%eax
f01033e2:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f01033e4:	eb b9                	jmp    f010339f <strtol+0x76>

	if (endptr)
f01033e6:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01033ea:	74 0d                	je     f01033f9 <strtol+0xd0>
		*endptr = (char *) s;
f01033ec:	8b 75 0c             	mov    0xc(%ebp),%esi
f01033ef:	89 0e                	mov    %ecx,(%esi)
f01033f1:	eb 06                	jmp    f01033f9 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01033f3:	85 db                	test   %ebx,%ebx
f01033f5:	74 98                	je     f010338f <strtol+0x66>
f01033f7:	eb 9e                	jmp    f0103397 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f01033f9:	89 c2                	mov    %eax,%edx
f01033fb:	f7 da                	neg    %edx
f01033fd:	85 ff                	test   %edi,%edi
f01033ff:	0f 45 c2             	cmovne %edx,%eax
}
f0103402:	5b                   	pop    %ebx
f0103403:	5e                   	pop    %esi
f0103404:	5f                   	pop    %edi
f0103405:	5d                   	pop    %ebp
f0103406:	c3                   	ret    
f0103407:	66 90                	xchg   %ax,%ax
f0103409:	66 90                	xchg   %ax,%ax
f010340b:	66 90                	xchg   %ax,%ax
f010340d:	66 90                	xchg   %ax,%ax
f010340f:	90                   	nop

f0103410 <__udivdi3>:
f0103410:	55                   	push   %ebp
f0103411:	57                   	push   %edi
f0103412:	56                   	push   %esi
f0103413:	53                   	push   %ebx
f0103414:	83 ec 1c             	sub    $0x1c,%esp
f0103417:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f010341b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f010341f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0103423:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0103427:	85 f6                	test   %esi,%esi
f0103429:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010342d:	89 ca                	mov    %ecx,%edx
f010342f:	89 f8                	mov    %edi,%eax
f0103431:	75 3d                	jne    f0103470 <__udivdi3+0x60>
f0103433:	39 cf                	cmp    %ecx,%edi
f0103435:	0f 87 c5 00 00 00    	ja     f0103500 <__udivdi3+0xf0>
f010343b:	85 ff                	test   %edi,%edi
f010343d:	89 fd                	mov    %edi,%ebp
f010343f:	75 0b                	jne    f010344c <__udivdi3+0x3c>
f0103441:	b8 01 00 00 00       	mov    $0x1,%eax
f0103446:	31 d2                	xor    %edx,%edx
f0103448:	f7 f7                	div    %edi
f010344a:	89 c5                	mov    %eax,%ebp
f010344c:	89 c8                	mov    %ecx,%eax
f010344e:	31 d2                	xor    %edx,%edx
f0103450:	f7 f5                	div    %ebp
f0103452:	89 c1                	mov    %eax,%ecx
f0103454:	89 d8                	mov    %ebx,%eax
f0103456:	89 cf                	mov    %ecx,%edi
f0103458:	f7 f5                	div    %ebp
f010345a:	89 c3                	mov    %eax,%ebx
f010345c:	89 d8                	mov    %ebx,%eax
f010345e:	89 fa                	mov    %edi,%edx
f0103460:	83 c4 1c             	add    $0x1c,%esp
f0103463:	5b                   	pop    %ebx
f0103464:	5e                   	pop    %esi
f0103465:	5f                   	pop    %edi
f0103466:	5d                   	pop    %ebp
f0103467:	c3                   	ret    
f0103468:	90                   	nop
f0103469:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103470:	39 ce                	cmp    %ecx,%esi
f0103472:	77 74                	ja     f01034e8 <__udivdi3+0xd8>
f0103474:	0f bd fe             	bsr    %esi,%edi
f0103477:	83 f7 1f             	xor    $0x1f,%edi
f010347a:	0f 84 98 00 00 00    	je     f0103518 <__udivdi3+0x108>
f0103480:	bb 20 00 00 00       	mov    $0x20,%ebx
f0103485:	89 f9                	mov    %edi,%ecx
f0103487:	89 c5                	mov    %eax,%ebp
f0103489:	29 fb                	sub    %edi,%ebx
f010348b:	d3 e6                	shl    %cl,%esi
f010348d:	89 d9                	mov    %ebx,%ecx
f010348f:	d3 ed                	shr    %cl,%ebp
f0103491:	89 f9                	mov    %edi,%ecx
f0103493:	d3 e0                	shl    %cl,%eax
f0103495:	09 ee                	or     %ebp,%esi
f0103497:	89 d9                	mov    %ebx,%ecx
f0103499:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010349d:	89 d5                	mov    %edx,%ebp
f010349f:	8b 44 24 08          	mov    0x8(%esp),%eax
f01034a3:	d3 ed                	shr    %cl,%ebp
f01034a5:	89 f9                	mov    %edi,%ecx
f01034a7:	d3 e2                	shl    %cl,%edx
f01034a9:	89 d9                	mov    %ebx,%ecx
f01034ab:	d3 e8                	shr    %cl,%eax
f01034ad:	09 c2                	or     %eax,%edx
f01034af:	89 d0                	mov    %edx,%eax
f01034b1:	89 ea                	mov    %ebp,%edx
f01034b3:	f7 f6                	div    %esi
f01034b5:	89 d5                	mov    %edx,%ebp
f01034b7:	89 c3                	mov    %eax,%ebx
f01034b9:	f7 64 24 0c          	mull   0xc(%esp)
f01034bd:	39 d5                	cmp    %edx,%ebp
f01034bf:	72 10                	jb     f01034d1 <__udivdi3+0xc1>
f01034c1:	8b 74 24 08          	mov    0x8(%esp),%esi
f01034c5:	89 f9                	mov    %edi,%ecx
f01034c7:	d3 e6                	shl    %cl,%esi
f01034c9:	39 c6                	cmp    %eax,%esi
f01034cb:	73 07                	jae    f01034d4 <__udivdi3+0xc4>
f01034cd:	39 d5                	cmp    %edx,%ebp
f01034cf:	75 03                	jne    f01034d4 <__udivdi3+0xc4>
f01034d1:	83 eb 01             	sub    $0x1,%ebx
f01034d4:	31 ff                	xor    %edi,%edi
f01034d6:	89 d8                	mov    %ebx,%eax
f01034d8:	89 fa                	mov    %edi,%edx
f01034da:	83 c4 1c             	add    $0x1c,%esp
f01034dd:	5b                   	pop    %ebx
f01034de:	5e                   	pop    %esi
f01034df:	5f                   	pop    %edi
f01034e0:	5d                   	pop    %ebp
f01034e1:	c3                   	ret    
f01034e2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01034e8:	31 ff                	xor    %edi,%edi
f01034ea:	31 db                	xor    %ebx,%ebx
f01034ec:	89 d8                	mov    %ebx,%eax
f01034ee:	89 fa                	mov    %edi,%edx
f01034f0:	83 c4 1c             	add    $0x1c,%esp
f01034f3:	5b                   	pop    %ebx
f01034f4:	5e                   	pop    %esi
f01034f5:	5f                   	pop    %edi
f01034f6:	5d                   	pop    %ebp
f01034f7:	c3                   	ret    
f01034f8:	90                   	nop
f01034f9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103500:	89 d8                	mov    %ebx,%eax
f0103502:	f7 f7                	div    %edi
f0103504:	31 ff                	xor    %edi,%edi
f0103506:	89 c3                	mov    %eax,%ebx
f0103508:	89 d8                	mov    %ebx,%eax
f010350a:	89 fa                	mov    %edi,%edx
f010350c:	83 c4 1c             	add    $0x1c,%esp
f010350f:	5b                   	pop    %ebx
f0103510:	5e                   	pop    %esi
f0103511:	5f                   	pop    %edi
f0103512:	5d                   	pop    %ebp
f0103513:	c3                   	ret    
f0103514:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103518:	39 ce                	cmp    %ecx,%esi
f010351a:	72 0c                	jb     f0103528 <__udivdi3+0x118>
f010351c:	31 db                	xor    %ebx,%ebx
f010351e:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0103522:	0f 87 34 ff ff ff    	ja     f010345c <__udivdi3+0x4c>
f0103528:	bb 01 00 00 00       	mov    $0x1,%ebx
f010352d:	e9 2a ff ff ff       	jmp    f010345c <__udivdi3+0x4c>
f0103532:	66 90                	xchg   %ax,%ax
f0103534:	66 90                	xchg   %ax,%ax
f0103536:	66 90                	xchg   %ax,%ax
f0103538:	66 90                	xchg   %ax,%ax
f010353a:	66 90                	xchg   %ax,%ax
f010353c:	66 90                	xchg   %ax,%ax
f010353e:	66 90                	xchg   %ax,%ax

f0103540 <__umoddi3>:
f0103540:	55                   	push   %ebp
f0103541:	57                   	push   %edi
f0103542:	56                   	push   %esi
f0103543:	53                   	push   %ebx
f0103544:	83 ec 1c             	sub    $0x1c,%esp
f0103547:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010354b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f010354f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0103553:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0103557:	85 d2                	test   %edx,%edx
f0103559:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010355d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103561:	89 f3                	mov    %esi,%ebx
f0103563:	89 3c 24             	mov    %edi,(%esp)
f0103566:	89 74 24 04          	mov    %esi,0x4(%esp)
f010356a:	75 1c                	jne    f0103588 <__umoddi3+0x48>
f010356c:	39 f7                	cmp    %esi,%edi
f010356e:	76 50                	jbe    f01035c0 <__umoddi3+0x80>
f0103570:	89 c8                	mov    %ecx,%eax
f0103572:	89 f2                	mov    %esi,%edx
f0103574:	f7 f7                	div    %edi
f0103576:	89 d0                	mov    %edx,%eax
f0103578:	31 d2                	xor    %edx,%edx
f010357a:	83 c4 1c             	add    $0x1c,%esp
f010357d:	5b                   	pop    %ebx
f010357e:	5e                   	pop    %esi
f010357f:	5f                   	pop    %edi
f0103580:	5d                   	pop    %ebp
f0103581:	c3                   	ret    
f0103582:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103588:	39 f2                	cmp    %esi,%edx
f010358a:	89 d0                	mov    %edx,%eax
f010358c:	77 52                	ja     f01035e0 <__umoddi3+0xa0>
f010358e:	0f bd ea             	bsr    %edx,%ebp
f0103591:	83 f5 1f             	xor    $0x1f,%ebp
f0103594:	75 5a                	jne    f01035f0 <__umoddi3+0xb0>
f0103596:	3b 54 24 04          	cmp    0x4(%esp),%edx
f010359a:	0f 82 e0 00 00 00    	jb     f0103680 <__umoddi3+0x140>
f01035a0:	39 0c 24             	cmp    %ecx,(%esp)
f01035a3:	0f 86 d7 00 00 00    	jbe    f0103680 <__umoddi3+0x140>
f01035a9:	8b 44 24 08          	mov    0x8(%esp),%eax
f01035ad:	8b 54 24 04          	mov    0x4(%esp),%edx
f01035b1:	83 c4 1c             	add    $0x1c,%esp
f01035b4:	5b                   	pop    %ebx
f01035b5:	5e                   	pop    %esi
f01035b6:	5f                   	pop    %edi
f01035b7:	5d                   	pop    %ebp
f01035b8:	c3                   	ret    
f01035b9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01035c0:	85 ff                	test   %edi,%edi
f01035c2:	89 fd                	mov    %edi,%ebp
f01035c4:	75 0b                	jne    f01035d1 <__umoddi3+0x91>
f01035c6:	b8 01 00 00 00       	mov    $0x1,%eax
f01035cb:	31 d2                	xor    %edx,%edx
f01035cd:	f7 f7                	div    %edi
f01035cf:	89 c5                	mov    %eax,%ebp
f01035d1:	89 f0                	mov    %esi,%eax
f01035d3:	31 d2                	xor    %edx,%edx
f01035d5:	f7 f5                	div    %ebp
f01035d7:	89 c8                	mov    %ecx,%eax
f01035d9:	f7 f5                	div    %ebp
f01035db:	89 d0                	mov    %edx,%eax
f01035dd:	eb 99                	jmp    f0103578 <__umoddi3+0x38>
f01035df:	90                   	nop
f01035e0:	89 c8                	mov    %ecx,%eax
f01035e2:	89 f2                	mov    %esi,%edx
f01035e4:	83 c4 1c             	add    $0x1c,%esp
f01035e7:	5b                   	pop    %ebx
f01035e8:	5e                   	pop    %esi
f01035e9:	5f                   	pop    %edi
f01035ea:	5d                   	pop    %ebp
f01035eb:	c3                   	ret    
f01035ec:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01035f0:	8b 34 24             	mov    (%esp),%esi
f01035f3:	bf 20 00 00 00       	mov    $0x20,%edi
f01035f8:	89 e9                	mov    %ebp,%ecx
f01035fa:	29 ef                	sub    %ebp,%edi
f01035fc:	d3 e0                	shl    %cl,%eax
f01035fe:	89 f9                	mov    %edi,%ecx
f0103600:	89 f2                	mov    %esi,%edx
f0103602:	d3 ea                	shr    %cl,%edx
f0103604:	89 e9                	mov    %ebp,%ecx
f0103606:	09 c2                	or     %eax,%edx
f0103608:	89 d8                	mov    %ebx,%eax
f010360a:	89 14 24             	mov    %edx,(%esp)
f010360d:	89 f2                	mov    %esi,%edx
f010360f:	d3 e2                	shl    %cl,%edx
f0103611:	89 f9                	mov    %edi,%ecx
f0103613:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103617:	8b 54 24 0c          	mov    0xc(%esp),%edx
f010361b:	d3 e8                	shr    %cl,%eax
f010361d:	89 e9                	mov    %ebp,%ecx
f010361f:	89 c6                	mov    %eax,%esi
f0103621:	d3 e3                	shl    %cl,%ebx
f0103623:	89 f9                	mov    %edi,%ecx
f0103625:	89 d0                	mov    %edx,%eax
f0103627:	d3 e8                	shr    %cl,%eax
f0103629:	89 e9                	mov    %ebp,%ecx
f010362b:	09 d8                	or     %ebx,%eax
f010362d:	89 d3                	mov    %edx,%ebx
f010362f:	89 f2                	mov    %esi,%edx
f0103631:	f7 34 24             	divl   (%esp)
f0103634:	89 d6                	mov    %edx,%esi
f0103636:	d3 e3                	shl    %cl,%ebx
f0103638:	f7 64 24 04          	mull   0x4(%esp)
f010363c:	39 d6                	cmp    %edx,%esi
f010363e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0103642:	89 d1                	mov    %edx,%ecx
f0103644:	89 c3                	mov    %eax,%ebx
f0103646:	72 08                	jb     f0103650 <__umoddi3+0x110>
f0103648:	75 11                	jne    f010365b <__umoddi3+0x11b>
f010364a:	39 44 24 08          	cmp    %eax,0x8(%esp)
f010364e:	73 0b                	jae    f010365b <__umoddi3+0x11b>
f0103650:	2b 44 24 04          	sub    0x4(%esp),%eax
f0103654:	1b 14 24             	sbb    (%esp),%edx
f0103657:	89 d1                	mov    %edx,%ecx
f0103659:	89 c3                	mov    %eax,%ebx
f010365b:	8b 54 24 08          	mov    0x8(%esp),%edx
f010365f:	29 da                	sub    %ebx,%edx
f0103661:	19 ce                	sbb    %ecx,%esi
f0103663:	89 f9                	mov    %edi,%ecx
f0103665:	89 f0                	mov    %esi,%eax
f0103667:	d3 e0                	shl    %cl,%eax
f0103669:	89 e9                	mov    %ebp,%ecx
f010366b:	d3 ea                	shr    %cl,%edx
f010366d:	89 e9                	mov    %ebp,%ecx
f010366f:	d3 ee                	shr    %cl,%esi
f0103671:	09 d0                	or     %edx,%eax
f0103673:	89 f2                	mov    %esi,%edx
f0103675:	83 c4 1c             	add    $0x1c,%esp
f0103678:	5b                   	pop    %ebx
f0103679:	5e                   	pop    %esi
f010367a:	5f                   	pop    %edi
f010367b:	5d                   	pop    %ebp
f010367c:	c3                   	ret    
f010367d:	8d 76 00             	lea    0x0(%esi),%esi
f0103680:	29 f9                	sub    %edi,%ecx
f0103682:	19 d6                	sbb    %edx,%esi
f0103684:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103688:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010368c:	e9 18 ff ff ff       	jmp    f01035a9 <__umoddi3+0x69>
