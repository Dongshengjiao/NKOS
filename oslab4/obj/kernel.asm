
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:

    .section .text,"ax",%progbits
    .globl kern_entry
kern_entry:
    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200000:	c020a2b7          	lui	t0,0xc020a
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc0200004:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200008:	037a                	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc020000a:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12
ffffffffc020000e:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc0200012:	fff0031b          	addiw	t1,zero,-1
ffffffffc0200016:	137e                	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc0200018:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc020001c:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200020:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc0200024:	c020a137          	lui	sp,0xc020a

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200028:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc020002c:	03228293          	addi	t0,t0,50 # ffffffffc0200032 <kern_init>
    jr t0
ffffffffc0200030:	8282                	jr	t0

ffffffffc0200032 <kern_init>:
void grade_backtrace(void);

int
kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc0200032:	0000b517          	auipc	a0,0xb
ffffffffc0200036:	02e50513          	addi	a0,a0,46 # ffffffffc020b060 <buf>
ffffffffc020003a:	00016617          	auipc	a2,0x16
ffffffffc020003e:	59260613          	addi	a2,a2,1426 # ffffffffc02165cc <end>
kern_init(void) {
ffffffffc0200042:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc0200044:	8e09                	sub	a2,a2,a0
ffffffffc0200046:	4581                	li	a1,0
kern_init(void) {
ffffffffc0200048:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc020004a:	283040ef          	jal	ra,ffffffffc0204acc <memset>

    cons_init();                // init the console
ffffffffc020004e:	4fc000ef          	jal	ra,ffffffffc020054a <cons_init>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc0200052:	00005597          	auipc	a1,0x5
ffffffffc0200056:	ece58593          	addi	a1,a1,-306 # ffffffffc0204f20 <etext+0x2>
ffffffffc020005a:	00005517          	auipc	a0,0x5
ffffffffc020005e:	ee650513          	addi	a0,a0,-282 # ffffffffc0204f40 <etext+0x22>
ffffffffc0200062:	06a000ef          	jal	ra,ffffffffc02000cc <cprintf>

    print_kerninfo();
ffffffffc0200066:	1be000ef          	jal	ra,ffffffffc0200224 <print_kerninfo>

    // grade_backtrace();

    pmm_init();                 // init physical memory management
ffffffffc020006a:	422030ef          	jal	ra,ffffffffc020348c <pmm_init>

    pic_init();                 // init interrupt controller
ffffffffc020006e:	54e000ef          	jal	ra,ffffffffc02005bc <pic_init>
    idt_init();                 // init interrupt descriptor table
ffffffffc0200072:	5c8000ef          	jal	ra,ffffffffc020063a <idt_init>

    vmm_init();                 // init virtual memory management
ffffffffc0200076:	4d5000ef          	jal	ra,ffffffffc0200d4a <vmm_init>
    proc_init();                // init process table
ffffffffc020007a:	6a6040ef          	jal	ra,ffffffffc0204720 <proc_init>
    
    ide_init();                 // init ide devices
ffffffffc020007e:	424000ef          	jal	ra,ffffffffc02004a2 <ide_init>
    swap_init();                // init swap
ffffffffc0200082:	381010ef          	jal	ra,ffffffffc0201c02 <swap_init>

    clock_init();               // init clock interrupt
ffffffffc0200086:	472000ef          	jal	ra,ffffffffc02004f8 <clock_init>
    intr_enable();              // enable irq interrupt
ffffffffc020008a:	534000ef          	jal	ra,ffffffffc02005be <intr_enable>

    cpu_idle();                 // run idle process
ffffffffc020008e:	0e1040ef          	jal	ra,ffffffffc020496e <cpu_idle>

ffffffffc0200092 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc0200092:	1141                	addi	sp,sp,-16
ffffffffc0200094:	e022                	sd	s0,0(sp)
ffffffffc0200096:	e406                	sd	ra,8(sp)
ffffffffc0200098:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc020009a:	4b2000ef          	jal	ra,ffffffffc020054c <cons_putc>
    (*cnt) ++;
ffffffffc020009e:	401c                	lw	a5,0(s0)
}
ffffffffc02000a0:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc02000a2:	2785                	addiw	a5,a5,1
ffffffffc02000a4:	c01c                	sw	a5,0(s0)
}
ffffffffc02000a6:	6402                	ld	s0,0(sp)
ffffffffc02000a8:	0141                	addi	sp,sp,16
ffffffffc02000aa:	8082                	ret

ffffffffc02000ac <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000ac:	1101                	addi	sp,sp,-32
ffffffffc02000ae:	862a                	mv	a2,a0
ffffffffc02000b0:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000b2:	00000517          	auipc	a0,0x0
ffffffffc02000b6:	fe050513          	addi	a0,a0,-32 # ffffffffc0200092 <cputch>
ffffffffc02000ba:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000bc:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc02000be:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000c0:	2c7040ef          	jal	ra,ffffffffc0204b86 <vprintfmt>
    return cnt;
}
ffffffffc02000c4:	60e2                	ld	ra,24(sp)
ffffffffc02000c6:	4532                	lw	a0,12(sp)
ffffffffc02000c8:	6105                	addi	sp,sp,32
ffffffffc02000ca:	8082                	ret

ffffffffc02000cc <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc02000cc:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc02000ce:	02810313          	addi	t1,sp,40 # ffffffffc020a028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc02000d2:	8e2a                	mv	t3,a0
ffffffffc02000d4:	f42e                	sd	a1,40(sp)
ffffffffc02000d6:	f832                	sd	a2,48(sp)
ffffffffc02000d8:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000da:	00000517          	auipc	a0,0x0
ffffffffc02000de:	fb850513          	addi	a0,a0,-72 # ffffffffc0200092 <cputch>
ffffffffc02000e2:	004c                	addi	a1,sp,4
ffffffffc02000e4:	869a                	mv	a3,t1
ffffffffc02000e6:	8672                	mv	a2,t3
cprintf(const char *fmt, ...) {
ffffffffc02000e8:	ec06                	sd	ra,24(sp)
ffffffffc02000ea:	e0ba                	sd	a4,64(sp)
ffffffffc02000ec:	e4be                	sd	a5,72(sp)
ffffffffc02000ee:	e8c2                	sd	a6,80(sp)
ffffffffc02000f0:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc02000f2:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc02000f4:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000f6:	291040ef          	jal	ra,ffffffffc0204b86 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc02000fa:	60e2                	ld	ra,24(sp)
ffffffffc02000fc:	4512                	lw	a0,4(sp)
ffffffffc02000fe:	6125                	addi	sp,sp,96
ffffffffc0200100:	8082                	ret

ffffffffc0200102 <cputchar>:

/* cputchar - writes a single character to stdout */
void
cputchar(int c) {
    cons_putc(c);
ffffffffc0200102:	a1a9                	j	ffffffffc020054c <cons_putc>

ffffffffc0200104 <getchar>:
    return cnt;
}

/* getchar - reads a single non-zero character from stdin */
int
getchar(void) {
ffffffffc0200104:	1141                	addi	sp,sp,-16
ffffffffc0200106:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc0200108:	478000ef          	jal	ra,ffffffffc0200580 <cons_getc>
ffffffffc020010c:	dd75                	beqz	a0,ffffffffc0200108 <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc020010e:	60a2                	ld	ra,8(sp)
ffffffffc0200110:	0141                	addi	sp,sp,16
ffffffffc0200112:	8082                	ret

ffffffffc0200114 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {//接受一个 prompt 字符串作为提示信息
ffffffffc0200114:	715d                	addi	sp,sp,-80
ffffffffc0200116:	e486                	sd	ra,72(sp)
ffffffffc0200118:	e0a6                	sd	s1,64(sp)
ffffffffc020011a:	fc4a                	sd	s2,56(sp)
ffffffffc020011c:	f84e                	sd	s3,48(sp)
ffffffffc020011e:	f452                	sd	s4,40(sp)
ffffffffc0200120:	f056                	sd	s5,32(sp)
ffffffffc0200122:	ec5a                	sd	s6,24(sp)
ffffffffc0200124:	e85e                	sd	s7,16(sp)
    if (prompt != NULL) {
ffffffffc0200126:	c901                	beqz	a0,ffffffffc0200136 <readline+0x22>
ffffffffc0200128:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc020012a:	00005517          	auipc	a0,0x5
ffffffffc020012e:	e1e50513          	addi	a0,a0,-482 # ffffffffc0204f48 <etext+0x2a>
ffffffffc0200132:	f9bff0ef          	jal	ra,ffffffffc02000cc <cprintf>
readline(const char *prompt) {//接受一个 prompt 字符串作为提示信息
ffffffffc0200136:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {// 处理有效字符
ffffffffc0200138:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {//处理回退
ffffffffc020013a:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {//结束符
ffffffffc020013c:	4aa9                	li	s5,10
ffffffffc020013e:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc0200140:	0000bb97          	auipc	s7,0xb
ffffffffc0200144:	f20b8b93          	addi	s7,s7,-224 # ffffffffc020b060 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {// 处理有效字符
ffffffffc0200148:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc020014c:	fb9ff0ef          	jal	ra,ffffffffc0200104 <getchar>
        if (c < 0) {
ffffffffc0200150:	00054a63          	bltz	a0,ffffffffc0200164 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {// 处理有效字符
ffffffffc0200154:	00a95a63          	bge	s2,a0,ffffffffc0200168 <readline+0x54>
ffffffffc0200158:	029a5263          	bge	s4,s1,ffffffffc020017c <readline+0x68>
        c = getchar();
ffffffffc020015c:	fa9ff0ef          	jal	ra,ffffffffc0200104 <getchar>
        if (c < 0) {
ffffffffc0200160:	fe055ae3          	bgez	a0,ffffffffc0200154 <readline+0x40>
            return NULL;
ffffffffc0200164:	4501                	li	a0,0
ffffffffc0200166:	a091                	j	ffffffffc02001aa <readline+0x96>
        else if (c == '\b' && i > 0) {//处理回退
ffffffffc0200168:	03351463          	bne	a0,s3,ffffffffc0200190 <readline+0x7c>
ffffffffc020016c:	e8a9                	bnez	s1,ffffffffc02001be <readline+0xaa>
        c = getchar();
ffffffffc020016e:	f97ff0ef          	jal	ra,ffffffffc0200104 <getchar>
        if (c < 0) {
ffffffffc0200172:	fe0549e3          	bltz	a0,ffffffffc0200164 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {// 处理有效字符
ffffffffc0200176:	fea959e3          	bge	s2,a0,ffffffffc0200168 <readline+0x54>
ffffffffc020017a:	4481                	li	s1,0
            cputchar(c);
ffffffffc020017c:	e42a                	sd	a0,8(sp)
ffffffffc020017e:	f85ff0ef          	jal	ra,ffffffffc0200102 <cputchar>
            buf[i ++] = c;
ffffffffc0200182:	6522                	ld	a0,8(sp)
ffffffffc0200184:	009b87b3          	add	a5,s7,s1
ffffffffc0200188:	2485                	addiw	s1,s1,1
ffffffffc020018a:	00a78023          	sb	a0,0(a5)
ffffffffc020018e:	bf7d                	j	ffffffffc020014c <readline+0x38>
        else if (c == '\n' || c == '\r') {//结束符
ffffffffc0200190:	01550463          	beq	a0,s5,ffffffffc0200198 <readline+0x84>
ffffffffc0200194:	fb651ce3          	bne	a0,s6,ffffffffc020014c <readline+0x38>
            cputchar(c);
ffffffffc0200198:	f6bff0ef          	jal	ra,ffffffffc0200102 <cputchar>
            buf[i] = '\0';
ffffffffc020019c:	0000b517          	auipc	a0,0xb
ffffffffc02001a0:	ec450513          	addi	a0,a0,-316 # ffffffffc020b060 <buf>
ffffffffc02001a4:	94aa                	add	s1,s1,a0
ffffffffc02001a6:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc02001aa:	60a6                	ld	ra,72(sp)
ffffffffc02001ac:	6486                	ld	s1,64(sp)
ffffffffc02001ae:	7962                	ld	s2,56(sp)
ffffffffc02001b0:	79c2                	ld	s3,48(sp)
ffffffffc02001b2:	7a22                	ld	s4,40(sp)
ffffffffc02001b4:	7a82                	ld	s5,32(sp)
ffffffffc02001b6:	6b62                	ld	s6,24(sp)
ffffffffc02001b8:	6bc2                	ld	s7,16(sp)
ffffffffc02001ba:	6161                	addi	sp,sp,80
ffffffffc02001bc:	8082                	ret
            cputchar(c);
ffffffffc02001be:	4521                	li	a0,8
ffffffffc02001c0:	f43ff0ef          	jal	ra,ffffffffc0200102 <cputchar>
            i --;
ffffffffc02001c4:	34fd                	addiw	s1,s1,-1
ffffffffc02001c6:	b759                	j	ffffffffc020014c <readline+0x38>

ffffffffc02001c8 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02001c8:	00016317          	auipc	t1,0x16
ffffffffc02001cc:	37030313          	addi	t1,t1,880 # ffffffffc0216538 <is_panic>
ffffffffc02001d0:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc02001d4:	715d                	addi	sp,sp,-80
ffffffffc02001d6:	ec06                	sd	ra,24(sp)
ffffffffc02001d8:	e822                	sd	s0,16(sp)
ffffffffc02001da:	f436                	sd	a3,40(sp)
ffffffffc02001dc:	f83a                	sd	a4,48(sp)
ffffffffc02001de:	fc3e                	sd	a5,56(sp)
ffffffffc02001e0:	e0c2                	sd	a6,64(sp)
ffffffffc02001e2:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02001e4:	020e1a63          	bnez	t3,ffffffffc0200218 <__panic+0x50>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc02001e8:	4785                	li	a5,1
ffffffffc02001ea:	00f32023          	sw	a5,0(t1)

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc02001ee:	8432                	mv	s0,a2
ffffffffc02001f0:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02001f2:	862e                	mv	a2,a1
ffffffffc02001f4:	85aa                	mv	a1,a0
ffffffffc02001f6:	00005517          	auipc	a0,0x5
ffffffffc02001fa:	d5a50513          	addi	a0,a0,-678 # ffffffffc0204f50 <etext+0x32>
    va_start(ap, fmt);
ffffffffc02001fe:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200200:	ecdff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200204:	65a2                	ld	a1,8(sp)
ffffffffc0200206:	8522                	mv	a0,s0
ffffffffc0200208:	ea5ff0ef          	jal	ra,ffffffffc02000ac <vcprintf>
    cprintf("\n");
ffffffffc020020c:	00006517          	auipc	a0,0x6
ffffffffc0200210:	7f450513          	addi	a0,a0,2036 # ffffffffc0206a00 <default_pmm_manager+0x3b8>
ffffffffc0200214:	eb9ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc0200218:	3ac000ef          	jal	ra,ffffffffc02005c4 <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc020021c:	4501                	li	a0,0
ffffffffc020021e:	130000ef          	jal	ra,ffffffffc020034e <kmonitor>
    while (1) {
ffffffffc0200222:	bfed                	j	ffffffffc020021c <__panic+0x54>

ffffffffc0200224 <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc0200224:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc0200226:	00005517          	auipc	a0,0x5
ffffffffc020022a:	d4a50513          	addi	a0,a0,-694 # ffffffffc0204f70 <etext+0x52>
void print_kerninfo(void) {
ffffffffc020022e:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200230:	e9dff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc0200234:	00000597          	auipc	a1,0x0
ffffffffc0200238:	dfe58593          	addi	a1,a1,-514 # ffffffffc0200032 <kern_init>
ffffffffc020023c:	00005517          	auipc	a0,0x5
ffffffffc0200240:	d5450513          	addi	a0,a0,-684 # ffffffffc0204f90 <etext+0x72>
ffffffffc0200244:	e89ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc0200248:	00005597          	auipc	a1,0x5
ffffffffc020024c:	cd658593          	addi	a1,a1,-810 # ffffffffc0204f1e <etext>
ffffffffc0200250:	00005517          	auipc	a0,0x5
ffffffffc0200254:	d6050513          	addi	a0,a0,-672 # ffffffffc0204fb0 <etext+0x92>
ffffffffc0200258:	e75ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc020025c:	0000b597          	auipc	a1,0xb
ffffffffc0200260:	e0458593          	addi	a1,a1,-508 # ffffffffc020b060 <buf>
ffffffffc0200264:	00005517          	auipc	a0,0x5
ffffffffc0200268:	d6c50513          	addi	a0,a0,-660 # ffffffffc0204fd0 <etext+0xb2>
ffffffffc020026c:	e61ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc0200270:	00016597          	auipc	a1,0x16
ffffffffc0200274:	35c58593          	addi	a1,a1,860 # ffffffffc02165cc <end>
ffffffffc0200278:	00005517          	auipc	a0,0x5
ffffffffc020027c:	d7850513          	addi	a0,a0,-648 # ffffffffc0204ff0 <etext+0xd2>
ffffffffc0200280:	e4dff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc0200284:	00016597          	auipc	a1,0x16
ffffffffc0200288:	74758593          	addi	a1,a1,1863 # ffffffffc02169cb <end+0x3ff>
ffffffffc020028c:	00000797          	auipc	a5,0x0
ffffffffc0200290:	da678793          	addi	a5,a5,-602 # ffffffffc0200032 <kern_init>
ffffffffc0200294:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200298:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc020029c:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc020029e:	3ff5f593          	andi	a1,a1,1023
ffffffffc02002a2:	95be                	add	a1,a1,a5
ffffffffc02002a4:	85a9                	srai	a1,a1,0xa
ffffffffc02002a6:	00005517          	auipc	a0,0x5
ffffffffc02002aa:	d6a50513          	addi	a0,a0,-662 # ffffffffc0205010 <etext+0xf2>
}
ffffffffc02002ae:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02002b0:	bd31                	j	ffffffffc02000cc <cprintf>

ffffffffc02002b2 <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc02002b2:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc02002b4:	00005617          	auipc	a2,0x5
ffffffffc02002b8:	d8c60613          	addi	a2,a2,-628 # ffffffffc0205040 <etext+0x122>
ffffffffc02002bc:	04d00593          	li	a1,77
ffffffffc02002c0:	00005517          	auipc	a0,0x5
ffffffffc02002c4:	d9850513          	addi	a0,a0,-616 # ffffffffc0205058 <etext+0x13a>
void print_stackframe(void) {
ffffffffc02002c8:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc02002ca:	effff0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc02002ce <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002ce:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002d0:	00005617          	auipc	a2,0x5
ffffffffc02002d4:	da060613          	addi	a2,a2,-608 # ffffffffc0205070 <etext+0x152>
ffffffffc02002d8:	00005597          	auipc	a1,0x5
ffffffffc02002dc:	db858593          	addi	a1,a1,-584 # ffffffffc0205090 <etext+0x172>
ffffffffc02002e0:	00005517          	auipc	a0,0x5
ffffffffc02002e4:	db850513          	addi	a0,a0,-584 # ffffffffc0205098 <etext+0x17a>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002e8:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002ea:	de3ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
ffffffffc02002ee:	00005617          	auipc	a2,0x5
ffffffffc02002f2:	dba60613          	addi	a2,a2,-582 # ffffffffc02050a8 <etext+0x18a>
ffffffffc02002f6:	00005597          	auipc	a1,0x5
ffffffffc02002fa:	dda58593          	addi	a1,a1,-550 # ffffffffc02050d0 <etext+0x1b2>
ffffffffc02002fe:	00005517          	auipc	a0,0x5
ffffffffc0200302:	d9a50513          	addi	a0,a0,-614 # ffffffffc0205098 <etext+0x17a>
ffffffffc0200306:	dc7ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
ffffffffc020030a:	00005617          	auipc	a2,0x5
ffffffffc020030e:	dd660613          	addi	a2,a2,-554 # ffffffffc02050e0 <etext+0x1c2>
ffffffffc0200312:	00005597          	auipc	a1,0x5
ffffffffc0200316:	dee58593          	addi	a1,a1,-530 # ffffffffc0205100 <etext+0x1e2>
ffffffffc020031a:	00005517          	auipc	a0,0x5
ffffffffc020031e:	d7e50513          	addi	a0,a0,-642 # ffffffffc0205098 <etext+0x17a>
ffffffffc0200322:	dabff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    }
    return 0;
}
ffffffffc0200326:	60a2                	ld	ra,8(sp)
ffffffffc0200328:	4501                	li	a0,0
ffffffffc020032a:	0141                	addi	sp,sp,16
ffffffffc020032c:	8082                	ret

ffffffffc020032e <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc020032e:	1141                	addi	sp,sp,-16
ffffffffc0200330:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc0200332:	ef3ff0ef          	jal	ra,ffffffffc0200224 <print_kerninfo>
    return 0;
}
ffffffffc0200336:	60a2                	ld	ra,8(sp)
ffffffffc0200338:	4501                	li	a0,0
ffffffffc020033a:	0141                	addi	sp,sp,16
ffffffffc020033c:	8082                	ret

ffffffffc020033e <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc020033e:	1141                	addi	sp,sp,-16
ffffffffc0200340:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc0200342:	f71ff0ef          	jal	ra,ffffffffc02002b2 <print_stackframe>
    return 0;
}
ffffffffc0200346:	60a2                	ld	ra,8(sp)
ffffffffc0200348:	4501                	li	a0,0
ffffffffc020034a:	0141                	addi	sp,sp,16
ffffffffc020034c:	8082                	ret

ffffffffc020034e <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc020034e:	7115                	addi	sp,sp,-224
ffffffffc0200350:	ed5e                	sd	s7,152(sp)
ffffffffc0200352:	8baa                	mv	s7,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200354:	00005517          	auipc	a0,0x5
ffffffffc0200358:	dbc50513          	addi	a0,a0,-580 # ffffffffc0205110 <etext+0x1f2>
kmonitor(struct trapframe *tf) {
ffffffffc020035c:	ed86                	sd	ra,216(sp)
ffffffffc020035e:	e9a2                	sd	s0,208(sp)
ffffffffc0200360:	e5a6                	sd	s1,200(sp)
ffffffffc0200362:	e1ca                	sd	s2,192(sp)
ffffffffc0200364:	fd4e                	sd	s3,184(sp)
ffffffffc0200366:	f952                	sd	s4,176(sp)
ffffffffc0200368:	f556                	sd	s5,168(sp)
ffffffffc020036a:	f15a                	sd	s6,160(sp)
ffffffffc020036c:	e962                	sd	s8,144(sp)
ffffffffc020036e:	e566                	sd	s9,136(sp)
ffffffffc0200370:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200372:	d5bff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc0200376:	00005517          	auipc	a0,0x5
ffffffffc020037a:	dc250513          	addi	a0,a0,-574 # ffffffffc0205138 <etext+0x21a>
ffffffffc020037e:	d4fff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    if (tf != NULL) {
ffffffffc0200382:	000b8563          	beqz	s7,ffffffffc020038c <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc0200386:	855e                	mv	a0,s7
ffffffffc0200388:	49a000ef          	jal	ra,ffffffffc0200822 <print_trapframe>
#endif
}

static inline void sbi_shutdown(void)
{
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc020038c:	4501                	li	a0,0
ffffffffc020038e:	4581                	li	a1,0
ffffffffc0200390:	4601                	li	a2,0
ffffffffc0200392:	48a1                	li	a7,8
ffffffffc0200394:	00000073          	ecall
ffffffffc0200398:	00005c17          	auipc	s8,0x5
ffffffffc020039c:	e10c0c13          	addi	s8,s8,-496 # ffffffffc02051a8 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02003a0:	00005917          	auipc	s2,0x5
ffffffffc02003a4:	dc090913          	addi	s2,s2,-576 # ffffffffc0205160 <etext+0x242>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003a8:	00005497          	auipc	s1,0x5
ffffffffc02003ac:	dc048493          	addi	s1,s1,-576 # ffffffffc0205168 <etext+0x24a>
        if (argc == MAXARGS - 1) {
ffffffffc02003b0:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02003b2:	00005b17          	auipc	s6,0x5
ffffffffc02003b6:	dbeb0b13          	addi	s6,s6,-578 # ffffffffc0205170 <etext+0x252>
        argv[argc ++] = buf;
ffffffffc02003ba:	00005a17          	auipc	s4,0x5
ffffffffc02003be:	cd6a0a13          	addi	s4,s4,-810 # ffffffffc0205090 <etext+0x172>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003c2:	4a8d                	li	s5,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02003c4:	854a                	mv	a0,s2
ffffffffc02003c6:	d4fff0ef          	jal	ra,ffffffffc0200114 <readline>
ffffffffc02003ca:	842a                	mv	s0,a0
ffffffffc02003cc:	dd65                	beqz	a0,ffffffffc02003c4 <kmonitor+0x76>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003ce:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc02003d2:	4c81                	li	s9,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003d4:	e1bd                	bnez	a1,ffffffffc020043a <kmonitor+0xec>
    if (argc == 0) {
ffffffffc02003d6:	fe0c87e3          	beqz	s9,ffffffffc02003c4 <kmonitor+0x76>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003da:	6582                	ld	a1,0(sp)
ffffffffc02003dc:	00005d17          	auipc	s10,0x5
ffffffffc02003e0:	dccd0d13          	addi	s10,s10,-564 # ffffffffc02051a8 <commands>
        argv[argc ++] = buf;
ffffffffc02003e4:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003e6:	4401                	li	s0,0
ffffffffc02003e8:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003ea:	6ae040ef          	jal	ra,ffffffffc0204a98 <strcmp>
ffffffffc02003ee:	c919                	beqz	a0,ffffffffc0200404 <kmonitor+0xb6>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003f0:	2405                	addiw	s0,s0,1
ffffffffc02003f2:	0b540063          	beq	s0,s5,ffffffffc0200492 <kmonitor+0x144>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003f6:	000d3503          	ld	a0,0(s10)
ffffffffc02003fa:	6582                	ld	a1,0(sp)
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003fc:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003fe:	69a040ef          	jal	ra,ffffffffc0204a98 <strcmp>
ffffffffc0200402:	f57d                	bnez	a0,ffffffffc02003f0 <kmonitor+0xa2>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc0200404:	00141793          	slli	a5,s0,0x1
ffffffffc0200408:	97a2                	add	a5,a5,s0
ffffffffc020040a:	078e                	slli	a5,a5,0x3
ffffffffc020040c:	97e2                	add	a5,a5,s8
ffffffffc020040e:	6b9c                	ld	a5,16(a5)
ffffffffc0200410:	865e                	mv	a2,s7
ffffffffc0200412:	002c                	addi	a1,sp,8
ffffffffc0200414:	fffc851b          	addiw	a0,s9,-1
ffffffffc0200418:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc020041a:	fa0555e3          	bgez	a0,ffffffffc02003c4 <kmonitor+0x76>
}
ffffffffc020041e:	60ee                	ld	ra,216(sp)
ffffffffc0200420:	644e                	ld	s0,208(sp)
ffffffffc0200422:	64ae                	ld	s1,200(sp)
ffffffffc0200424:	690e                	ld	s2,192(sp)
ffffffffc0200426:	79ea                	ld	s3,184(sp)
ffffffffc0200428:	7a4a                	ld	s4,176(sp)
ffffffffc020042a:	7aaa                	ld	s5,168(sp)
ffffffffc020042c:	7b0a                	ld	s6,160(sp)
ffffffffc020042e:	6bea                	ld	s7,152(sp)
ffffffffc0200430:	6c4a                	ld	s8,144(sp)
ffffffffc0200432:	6caa                	ld	s9,136(sp)
ffffffffc0200434:	6d0a                	ld	s10,128(sp)
ffffffffc0200436:	612d                	addi	sp,sp,224
ffffffffc0200438:	8082                	ret
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020043a:	8526                	mv	a0,s1
ffffffffc020043c:	67a040ef          	jal	ra,ffffffffc0204ab6 <strchr>
ffffffffc0200440:	c901                	beqz	a0,ffffffffc0200450 <kmonitor+0x102>
ffffffffc0200442:	00144583          	lbu	a1,1(s0)
            *buf ++ = '\0';
ffffffffc0200446:	00040023          	sb	zero,0(s0)
ffffffffc020044a:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020044c:	d5c9                	beqz	a1,ffffffffc02003d6 <kmonitor+0x88>
ffffffffc020044e:	b7f5                	j	ffffffffc020043a <kmonitor+0xec>
        if (*buf == '\0') {
ffffffffc0200450:	00044783          	lbu	a5,0(s0)
ffffffffc0200454:	d3c9                	beqz	a5,ffffffffc02003d6 <kmonitor+0x88>
        if (argc == MAXARGS - 1) {
ffffffffc0200456:	033c8963          	beq	s9,s3,ffffffffc0200488 <kmonitor+0x13a>
        argv[argc ++] = buf;
ffffffffc020045a:	003c9793          	slli	a5,s9,0x3
ffffffffc020045e:	0118                	addi	a4,sp,128
ffffffffc0200460:	97ba                	add	a5,a5,a4
ffffffffc0200462:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200466:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc020046a:	2c85                	addiw	s9,s9,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc020046c:	e591                	bnez	a1,ffffffffc0200478 <kmonitor+0x12a>
ffffffffc020046e:	b7b5                	j	ffffffffc02003da <kmonitor+0x8c>
ffffffffc0200470:	00144583          	lbu	a1,1(s0)
            buf ++;
ffffffffc0200474:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200476:	d1a5                	beqz	a1,ffffffffc02003d6 <kmonitor+0x88>
ffffffffc0200478:	8526                	mv	a0,s1
ffffffffc020047a:	63c040ef          	jal	ra,ffffffffc0204ab6 <strchr>
ffffffffc020047e:	d96d                	beqz	a0,ffffffffc0200470 <kmonitor+0x122>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200480:	00044583          	lbu	a1,0(s0)
ffffffffc0200484:	d9a9                	beqz	a1,ffffffffc02003d6 <kmonitor+0x88>
ffffffffc0200486:	bf55                	j	ffffffffc020043a <kmonitor+0xec>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200488:	45c1                	li	a1,16
ffffffffc020048a:	855a                	mv	a0,s6
ffffffffc020048c:	c41ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
ffffffffc0200490:	b7e9                	j	ffffffffc020045a <kmonitor+0x10c>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc0200492:	6582                	ld	a1,0(sp)
ffffffffc0200494:	00005517          	auipc	a0,0x5
ffffffffc0200498:	cfc50513          	addi	a0,a0,-772 # ffffffffc0205190 <etext+0x272>
ffffffffc020049c:	c31ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    return 0;
ffffffffc02004a0:	b715                	j	ffffffffc02003c4 <kmonitor+0x76>

ffffffffc02004a2 <ide_init>:
#include <stdio.h>
#include <string.h>
#include <trap.h>
#include <riscv.h>

void ide_init(void) {}
ffffffffc02004a2:	8082                	ret

ffffffffc02004a4 <ide_device_valid>:

#define MAX_IDE 2
#define MAX_DISK_NSECS 56
static char ide[MAX_DISK_NSECS * SECTSIZE];

bool ide_device_valid(unsigned short ideno) { return ideno < MAX_IDE; }
ffffffffc02004a4:	00253513          	sltiu	a0,a0,2
ffffffffc02004a8:	8082                	ret

ffffffffc02004aa <ide_device_size>:

size_t ide_device_size(unsigned short ideno) { return MAX_DISK_NSECS; }
ffffffffc02004aa:	03800513          	li	a0,56
ffffffffc02004ae:	8082                	ret

ffffffffc02004b0 <ide_read_secs>:

int ide_read_secs(unsigned short ideno, uint32_t secno, void *dst,
                  size_t nsecs) {
    int iobase = secno * SECTSIZE;
    memcpy(dst, &ide[iobase], nsecs * SECTSIZE);
ffffffffc02004b0:	0000b797          	auipc	a5,0xb
ffffffffc02004b4:	fb078793          	addi	a5,a5,-80 # ffffffffc020b460 <ide>
    int iobase = secno * SECTSIZE;
ffffffffc02004b8:	0095959b          	slliw	a1,a1,0x9
                  size_t nsecs) {
ffffffffc02004bc:	1141                	addi	sp,sp,-16
ffffffffc02004be:	8532                	mv	a0,a2
    memcpy(dst, &ide[iobase], nsecs * SECTSIZE);
ffffffffc02004c0:	95be                	add	a1,a1,a5
ffffffffc02004c2:	00969613          	slli	a2,a3,0x9
                  size_t nsecs) {
ffffffffc02004c6:	e406                	sd	ra,8(sp)
    memcpy(dst, &ide[iobase], nsecs * SECTSIZE);
ffffffffc02004c8:	616040ef          	jal	ra,ffffffffc0204ade <memcpy>
    return 0;
}
ffffffffc02004cc:	60a2                	ld	ra,8(sp)
ffffffffc02004ce:	4501                	li	a0,0
ffffffffc02004d0:	0141                	addi	sp,sp,16
ffffffffc02004d2:	8082                	ret

ffffffffc02004d4 <ide_write_secs>:

int ide_write_secs(unsigned short ideno, uint32_t secno, const void *src,
                   size_t nsecs) {
    int iobase = secno * SECTSIZE;
ffffffffc02004d4:	0095979b          	slliw	a5,a1,0x9
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc02004d8:	0000b517          	auipc	a0,0xb
ffffffffc02004dc:	f8850513          	addi	a0,a0,-120 # ffffffffc020b460 <ide>
                   size_t nsecs) {
ffffffffc02004e0:	1141                	addi	sp,sp,-16
ffffffffc02004e2:	85b2                	mv	a1,a2
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc02004e4:	953e                	add	a0,a0,a5
ffffffffc02004e6:	00969613          	slli	a2,a3,0x9
                   size_t nsecs) {
ffffffffc02004ea:	e406                	sd	ra,8(sp)
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc02004ec:	5f2040ef          	jal	ra,ffffffffc0204ade <memcpy>
    return 0;
}
ffffffffc02004f0:	60a2                	ld	ra,8(sp)
ffffffffc02004f2:	4501                	li	a0,0
ffffffffc02004f4:	0141                	addi	sp,sp,16
ffffffffc02004f6:	8082                	ret

ffffffffc02004f8 <clock_init>:
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
    // divided by 500 when using Spike(2MHz)
    // divided by 100 when using QEMU(10MHz)
    timebase = 1e7 / 100;
ffffffffc02004f8:	67e1                	lui	a5,0x18
ffffffffc02004fa:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc02004fe:	00016717          	auipc	a4,0x16
ffffffffc0200502:	04f73523          	sd	a5,74(a4) # ffffffffc0216548 <timebase>
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200506:	c0102573          	rdtime	a0
	SBI_CALL_1(SBI_SET_TIMER, stime_value);
ffffffffc020050a:	4581                	li	a1,0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc020050c:	953e                	add	a0,a0,a5
ffffffffc020050e:	4601                	li	a2,0
ffffffffc0200510:	4881                	li	a7,0
ffffffffc0200512:	00000073          	ecall
    set_csr(sie, MIP_STIP);
ffffffffc0200516:	02000793          	li	a5,32
ffffffffc020051a:	1047a7f3          	csrrs	a5,sie,a5
    cprintf("++ setup timer interrupts\n");
ffffffffc020051e:	00005517          	auipc	a0,0x5
ffffffffc0200522:	cd250513          	addi	a0,a0,-814 # ffffffffc02051f0 <commands+0x48>
    ticks = 0;
ffffffffc0200526:	00016797          	auipc	a5,0x16
ffffffffc020052a:	0007bd23          	sd	zero,26(a5) # ffffffffc0216540 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc020052e:	be79                	j	ffffffffc02000cc <cprintf>

ffffffffc0200530 <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200530:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200534:	00016797          	auipc	a5,0x16
ffffffffc0200538:	0147b783          	ld	a5,20(a5) # ffffffffc0216548 <timebase>
ffffffffc020053c:	953e                	add	a0,a0,a5
ffffffffc020053e:	4581                	li	a1,0
ffffffffc0200540:	4601                	li	a2,0
ffffffffc0200542:	4881                	li	a7,0
ffffffffc0200544:	00000073          	ecall
ffffffffc0200548:	8082                	ret

ffffffffc020054a <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc020054a:	8082                	ret

ffffffffc020054c <cons_putc>:
#include <defs.h>
#include <intr.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020054c:	100027f3          	csrr	a5,sstatus
ffffffffc0200550:	8b89                	andi	a5,a5,2
	SBI_CALL_1(SBI_CONSOLE_PUTCHAR, ch);
ffffffffc0200552:	0ff57513          	zext.b	a0,a0
ffffffffc0200556:	e799                	bnez	a5,ffffffffc0200564 <cons_putc+0x18>
ffffffffc0200558:	4581                	li	a1,0
ffffffffc020055a:	4601                	li	a2,0
ffffffffc020055c:	4885                	li	a7,1
ffffffffc020055e:	00000073          	ecall
    }
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
ffffffffc0200562:	8082                	ret

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) {
ffffffffc0200564:	1101                	addi	sp,sp,-32
ffffffffc0200566:	ec06                	sd	ra,24(sp)
ffffffffc0200568:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc020056a:	05a000ef          	jal	ra,ffffffffc02005c4 <intr_disable>
ffffffffc020056e:	6522                	ld	a0,8(sp)
ffffffffc0200570:	4581                	li	a1,0
ffffffffc0200572:	4601                	li	a2,0
ffffffffc0200574:	4885                	li	a7,1
ffffffffc0200576:	00000073          	ecall
    local_intr_save(intr_flag);
    {
        sbi_console_putchar((unsigned char)c);
    }
    local_intr_restore(intr_flag);
}
ffffffffc020057a:	60e2                	ld	ra,24(sp)
ffffffffc020057c:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc020057e:	a081                	j	ffffffffc02005be <intr_enable>

ffffffffc0200580 <cons_getc>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200580:	100027f3          	csrr	a5,sstatus
ffffffffc0200584:	8b89                	andi	a5,a5,2
ffffffffc0200586:	eb89                	bnez	a5,ffffffffc0200598 <cons_getc+0x18>
	return SBI_CALL_0(SBI_CONSOLE_GETCHAR);
ffffffffc0200588:	4501                	li	a0,0
ffffffffc020058a:	4581                	li	a1,0
ffffffffc020058c:	4601                	li	a2,0
ffffffffc020058e:	4889                	li	a7,2
ffffffffc0200590:	00000073          	ecall
ffffffffc0200594:	2501                	sext.w	a0,a0
    {
        c = sbi_console_getchar();
    }
    local_intr_restore(intr_flag);
    return c;
}
ffffffffc0200596:	8082                	ret
int cons_getc(void) {
ffffffffc0200598:	1101                	addi	sp,sp,-32
ffffffffc020059a:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc020059c:	028000ef          	jal	ra,ffffffffc02005c4 <intr_disable>
ffffffffc02005a0:	4501                	li	a0,0
ffffffffc02005a2:	4581                	li	a1,0
ffffffffc02005a4:	4601                	li	a2,0
ffffffffc02005a6:	4889                	li	a7,2
ffffffffc02005a8:	00000073          	ecall
ffffffffc02005ac:	2501                	sext.w	a0,a0
ffffffffc02005ae:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc02005b0:	00e000ef          	jal	ra,ffffffffc02005be <intr_enable>
}
ffffffffc02005b4:	60e2                	ld	ra,24(sp)
ffffffffc02005b6:	6522                	ld	a0,8(sp)
ffffffffc02005b8:	6105                	addi	sp,sp,32
ffffffffc02005ba:	8082                	ret

ffffffffc02005bc <pic_init>:
#include <picirq.h>

void pic_enable(unsigned int irq) {}

/* pic_init - initialize the 8259A interrupt controllers */
void pic_init(void) {}
ffffffffc02005bc:	8082                	ret

ffffffffc02005be <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc02005be:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc02005c2:	8082                	ret

ffffffffc02005c4 <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc02005c4:	100177f3          	csrrci	a5,sstatus,2
ffffffffc02005c8:	8082                	ret

ffffffffc02005ca <pgfault_handler>:
    set_csr(sstatus, SSTATUS_SUM);
}

/* trap_in_kernel - test if trap happened in kernel */
bool trap_in_kernel(struct trapframe *tf) {
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc02005ca:	10053783          	ld	a5,256(a0)
    cprintf("page falut at 0x%08x: %c/%c\n", tf->badvaddr,
            trap_in_kernel(tf) ? 'K' : 'U',
            tf->cause == CAUSE_STORE_PAGE_FAULT ? 'W' : 'R');
}

static int pgfault_handler(struct trapframe *tf) {
ffffffffc02005ce:	1141                	addi	sp,sp,-16
ffffffffc02005d0:	e022                	sd	s0,0(sp)
ffffffffc02005d2:	e406                	sd	ra,8(sp)
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc02005d4:	1007f793          	andi	a5,a5,256
    cprintf("page falut at 0x%08x: %c/%c\n", tf->badvaddr,
ffffffffc02005d8:	11053583          	ld	a1,272(a0)
static int pgfault_handler(struct trapframe *tf) {
ffffffffc02005dc:	842a                	mv	s0,a0
    cprintf("page falut at 0x%08x: %c/%c\n", tf->badvaddr,
ffffffffc02005de:	05500613          	li	a2,85
ffffffffc02005e2:	c399                	beqz	a5,ffffffffc02005e8 <pgfault_handler+0x1e>
ffffffffc02005e4:	04b00613          	li	a2,75
ffffffffc02005e8:	11843703          	ld	a4,280(s0)
ffffffffc02005ec:	47bd                	li	a5,15
ffffffffc02005ee:	05700693          	li	a3,87
ffffffffc02005f2:	00f70463          	beq	a4,a5,ffffffffc02005fa <pgfault_handler+0x30>
ffffffffc02005f6:	05200693          	li	a3,82
ffffffffc02005fa:	00005517          	auipc	a0,0x5
ffffffffc02005fe:	c1650513          	addi	a0,a0,-1002 # ffffffffc0205210 <commands+0x68>
ffffffffc0200602:	acbff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    extern struct mm_struct *check_mm_struct;
    print_pgfault(tf);
    if (check_mm_struct != NULL) {
ffffffffc0200606:	00016517          	auipc	a0,0x16
ffffffffc020060a:	f4a53503          	ld	a0,-182(a0) # ffffffffc0216550 <check_mm_struct>
ffffffffc020060e:	c911                	beqz	a0,ffffffffc0200622 <pgfault_handler+0x58>
        return do_pgfault(check_mm_struct, tf->cause, tf->badvaddr);
ffffffffc0200610:	11043603          	ld	a2,272(s0)
ffffffffc0200614:	11842583          	lw	a1,280(s0)
    }
    panic("unhandled page fault.\n");
}
ffffffffc0200618:	6402                	ld	s0,0(sp)
ffffffffc020061a:	60a2                	ld	ra,8(sp)
ffffffffc020061c:	0141                	addi	sp,sp,16
        return do_pgfault(check_mm_struct, tf->cause, tf->badvaddr);
ffffffffc020061e:	5010006f          	j	ffffffffc020131e <do_pgfault>
    panic("unhandled page fault.\n");
ffffffffc0200622:	00005617          	auipc	a2,0x5
ffffffffc0200626:	c0e60613          	addi	a2,a2,-1010 # ffffffffc0205230 <commands+0x88>
ffffffffc020062a:	06200593          	li	a1,98
ffffffffc020062e:	00005517          	auipc	a0,0x5
ffffffffc0200632:	c1a50513          	addi	a0,a0,-998 # ffffffffc0205248 <commands+0xa0>
ffffffffc0200636:	b93ff0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc020063a <idt_init>:
    write_csr(sscratch, 0);
ffffffffc020063a:	14005073          	csrwi	sscratch,0
    write_csr(stvec, &__alltraps);
ffffffffc020063e:	00000797          	auipc	a5,0x0
ffffffffc0200642:	47a78793          	addi	a5,a5,1146 # ffffffffc0200ab8 <__alltraps>
ffffffffc0200646:	10579073          	csrw	stvec,a5
    set_csr(sstatus, SSTATUS_SUM);
ffffffffc020064a:	000407b7          	lui	a5,0x40
ffffffffc020064e:	1007a7f3          	csrrs	a5,sstatus,a5
}
ffffffffc0200652:	8082                	ret

ffffffffc0200654 <print_regs>:
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200654:	610c                	ld	a1,0(a0)
void print_regs(struct pushregs *gpr) {
ffffffffc0200656:	1141                	addi	sp,sp,-16
ffffffffc0200658:	e022                	sd	s0,0(sp)
ffffffffc020065a:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020065c:	00005517          	auipc	a0,0x5
ffffffffc0200660:	c0450513          	addi	a0,a0,-1020 # ffffffffc0205260 <commands+0xb8>
void print_regs(struct pushregs *gpr) {
ffffffffc0200664:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200666:	a67ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc020066a:	640c                	ld	a1,8(s0)
ffffffffc020066c:	00005517          	auipc	a0,0x5
ffffffffc0200670:	c0c50513          	addi	a0,a0,-1012 # ffffffffc0205278 <commands+0xd0>
ffffffffc0200674:	a59ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc0200678:	680c                	ld	a1,16(s0)
ffffffffc020067a:	00005517          	auipc	a0,0x5
ffffffffc020067e:	c1650513          	addi	a0,a0,-1002 # ffffffffc0205290 <commands+0xe8>
ffffffffc0200682:	a4bff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc0200686:	6c0c                	ld	a1,24(s0)
ffffffffc0200688:	00005517          	auipc	a0,0x5
ffffffffc020068c:	c2050513          	addi	a0,a0,-992 # ffffffffc02052a8 <commands+0x100>
ffffffffc0200690:	a3dff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc0200694:	700c                	ld	a1,32(s0)
ffffffffc0200696:	00005517          	auipc	a0,0x5
ffffffffc020069a:	c2a50513          	addi	a0,a0,-982 # ffffffffc02052c0 <commands+0x118>
ffffffffc020069e:	a2fff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc02006a2:	740c                	ld	a1,40(s0)
ffffffffc02006a4:	00005517          	auipc	a0,0x5
ffffffffc02006a8:	c3450513          	addi	a0,a0,-972 # ffffffffc02052d8 <commands+0x130>
ffffffffc02006ac:	a21ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02006b0:	780c                	ld	a1,48(s0)
ffffffffc02006b2:	00005517          	auipc	a0,0x5
ffffffffc02006b6:	c3e50513          	addi	a0,a0,-962 # ffffffffc02052f0 <commands+0x148>
ffffffffc02006ba:	a13ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02006be:	7c0c                	ld	a1,56(s0)
ffffffffc02006c0:	00005517          	auipc	a0,0x5
ffffffffc02006c4:	c4850513          	addi	a0,a0,-952 # ffffffffc0205308 <commands+0x160>
ffffffffc02006c8:	a05ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc02006cc:	602c                	ld	a1,64(s0)
ffffffffc02006ce:	00005517          	auipc	a0,0x5
ffffffffc02006d2:	c5250513          	addi	a0,a0,-942 # ffffffffc0205320 <commands+0x178>
ffffffffc02006d6:	9f7ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc02006da:	642c                	ld	a1,72(s0)
ffffffffc02006dc:	00005517          	auipc	a0,0x5
ffffffffc02006e0:	c5c50513          	addi	a0,a0,-932 # ffffffffc0205338 <commands+0x190>
ffffffffc02006e4:	9e9ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc02006e8:	682c                	ld	a1,80(s0)
ffffffffc02006ea:	00005517          	auipc	a0,0x5
ffffffffc02006ee:	c6650513          	addi	a0,a0,-922 # ffffffffc0205350 <commands+0x1a8>
ffffffffc02006f2:	9dbff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc02006f6:	6c2c                	ld	a1,88(s0)
ffffffffc02006f8:	00005517          	auipc	a0,0x5
ffffffffc02006fc:	c7050513          	addi	a0,a0,-912 # ffffffffc0205368 <commands+0x1c0>
ffffffffc0200700:	9cdff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200704:	702c                	ld	a1,96(s0)
ffffffffc0200706:	00005517          	auipc	a0,0x5
ffffffffc020070a:	c7a50513          	addi	a0,a0,-902 # ffffffffc0205380 <commands+0x1d8>
ffffffffc020070e:	9bfff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200712:	742c                	ld	a1,104(s0)
ffffffffc0200714:	00005517          	auipc	a0,0x5
ffffffffc0200718:	c8450513          	addi	a0,a0,-892 # ffffffffc0205398 <commands+0x1f0>
ffffffffc020071c:	9b1ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200720:	782c                	ld	a1,112(s0)
ffffffffc0200722:	00005517          	auipc	a0,0x5
ffffffffc0200726:	c8e50513          	addi	a0,a0,-882 # ffffffffc02053b0 <commands+0x208>
ffffffffc020072a:	9a3ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc020072e:	7c2c                	ld	a1,120(s0)
ffffffffc0200730:	00005517          	auipc	a0,0x5
ffffffffc0200734:	c9850513          	addi	a0,a0,-872 # ffffffffc02053c8 <commands+0x220>
ffffffffc0200738:	995ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc020073c:	604c                	ld	a1,128(s0)
ffffffffc020073e:	00005517          	auipc	a0,0x5
ffffffffc0200742:	ca250513          	addi	a0,a0,-862 # ffffffffc02053e0 <commands+0x238>
ffffffffc0200746:	987ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc020074a:	644c                	ld	a1,136(s0)
ffffffffc020074c:	00005517          	auipc	a0,0x5
ffffffffc0200750:	cac50513          	addi	a0,a0,-852 # ffffffffc02053f8 <commands+0x250>
ffffffffc0200754:	979ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200758:	684c                	ld	a1,144(s0)
ffffffffc020075a:	00005517          	auipc	a0,0x5
ffffffffc020075e:	cb650513          	addi	a0,a0,-842 # ffffffffc0205410 <commands+0x268>
ffffffffc0200762:	96bff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200766:	6c4c                	ld	a1,152(s0)
ffffffffc0200768:	00005517          	auipc	a0,0x5
ffffffffc020076c:	cc050513          	addi	a0,a0,-832 # ffffffffc0205428 <commands+0x280>
ffffffffc0200770:	95dff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200774:	704c                	ld	a1,160(s0)
ffffffffc0200776:	00005517          	auipc	a0,0x5
ffffffffc020077a:	cca50513          	addi	a0,a0,-822 # ffffffffc0205440 <commands+0x298>
ffffffffc020077e:	94fff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc0200782:	744c                	ld	a1,168(s0)
ffffffffc0200784:	00005517          	auipc	a0,0x5
ffffffffc0200788:	cd450513          	addi	a0,a0,-812 # ffffffffc0205458 <commands+0x2b0>
ffffffffc020078c:	941ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc0200790:	784c                	ld	a1,176(s0)
ffffffffc0200792:	00005517          	auipc	a0,0x5
ffffffffc0200796:	cde50513          	addi	a0,a0,-802 # ffffffffc0205470 <commands+0x2c8>
ffffffffc020079a:	933ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc020079e:	7c4c                	ld	a1,184(s0)
ffffffffc02007a0:	00005517          	auipc	a0,0x5
ffffffffc02007a4:	ce850513          	addi	a0,a0,-792 # ffffffffc0205488 <commands+0x2e0>
ffffffffc02007a8:	925ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc02007ac:	606c                	ld	a1,192(s0)
ffffffffc02007ae:	00005517          	auipc	a0,0x5
ffffffffc02007b2:	cf250513          	addi	a0,a0,-782 # ffffffffc02054a0 <commands+0x2f8>
ffffffffc02007b6:	917ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc02007ba:	646c                	ld	a1,200(s0)
ffffffffc02007bc:	00005517          	auipc	a0,0x5
ffffffffc02007c0:	cfc50513          	addi	a0,a0,-772 # ffffffffc02054b8 <commands+0x310>
ffffffffc02007c4:	909ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc02007c8:	686c                	ld	a1,208(s0)
ffffffffc02007ca:	00005517          	auipc	a0,0x5
ffffffffc02007ce:	d0650513          	addi	a0,a0,-762 # ffffffffc02054d0 <commands+0x328>
ffffffffc02007d2:	8fbff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc02007d6:	6c6c                	ld	a1,216(s0)
ffffffffc02007d8:	00005517          	auipc	a0,0x5
ffffffffc02007dc:	d1050513          	addi	a0,a0,-752 # ffffffffc02054e8 <commands+0x340>
ffffffffc02007e0:	8edff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc02007e4:	706c                	ld	a1,224(s0)
ffffffffc02007e6:	00005517          	auipc	a0,0x5
ffffffffc02007ea:	d1a50513          	addi	a0,a0,-742 # ffffffffc0205500 <commands+0x358>
ffffffffc02007ee:	8dfff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc02007f2:	746c                	ld	a1,232(s0)
ffffffffc02007f4:	00005517          	auipc	a0,0x5
ffffffffc02007f8:	d2450513          	addi	a0,a0,-732 # ffffffffc0205518 <commands+0x370>
ffffffffc02007fc:	8d1ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200800:	786c                	ld	a1,240(s0)
ffffffffc0200802:	00005517          	auipc	a0,0x5
ffffffffc0200806:	d2e50513          	addi	a0,a0,-722 # ffffffffc0205530 <commands+0x388>
ffffffffc020080a:	8c3ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc020080e:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200810:	6402                	ld	s0,0(sp)
ffffffffc0200812:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200814:	00005517          	auipc	a0,0x5
ffffffffc0200818:	d3450513          	addi	a0,a0,-716 # ffffffffc0205548 <commands+0x3a0>
}
ffffffffc020081c:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc020081e:	8afff06f          	j	ffffffffc02000cc <cprintf>

ffffffffc0200822 <print_trapframe>:
void print_trapframe(struct trapframe *tf) {
ffffffffc0200822:	1141                	addi	sp,sp,-16
ffffffffc0200824:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200826:	85aa                	mv	a1,a0
void print_trapframe(struct trapframe *tf) {
ffffffffc0200828:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc020082a:	00005517          	auipc	a0,0x5
ffffffffc020082e:	d3650513          	addi	a0,a0,-714 # ffffffffc0205560 <commands+0x3b8>
void print_trapframe(struct trapframe *tf) {
ffffffffc0200832:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200834:	899ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200838:	8522                	mv	a0,s0
ffffffffc020083a:	e1bff0ef          	jal	ra,ffffffffc0200654 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc020083e:	10043583          	ld	a1,256(s0)
ffffffffc0200842:	00005517          	auipc	a0,0x5
ffffffffc0200846:	d3650513          	addi	a0,a0,-714 # ffffffffc0205578 <commands+0x3d0>
ffffffffc020084a:	883ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc020084e:	10843583          	ld	a1,264(s0)
ffffffffc0200852:	00005517          	auipc	a0,0x5
ffffffffc0200856:	d3e50513          	addi	a0,a0,-706 # ffffffffc0205590 <commands+0x3e8>
ffffffffc020085a:	873ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc020085e:	11043583          	ld	a1,272(s0)
ffffffffc0200862:	00005517          	auipc	a0,0x5
ffffffffc0200866:	d4650513          	addi	a0,a0,-698 # ffffffffc02055a8 <commands+0x400>
ffffffffc020086a:	863ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc020086e:	11843583          	ld	a1,280(s0)
}
ffffffffc0200872:	6402                	ld	s0,0(sp)
ffffffffc0200874:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200876:	00005517          	auipc	a0,0x5
ffffffffc020087a:	d4a50513          	addi	a0,a0,-694 # ffffffffc02055c0 <commands+0x418>
}
ffffffffc020087e:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200880:	84dff06f          	j	ffffffffc02000cc <cprintf>

ffffffffc0200884 <interrupt_handler>:

static volatile int in_swap_tick_event = 0;
extern struct mm_struct *check_mm_struct;

void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc0200884:	11853783          	ld	a5,280(a0)
ffffffffc0200888:	472d                	li	a4,11
ffffffffc020088a:	0786                	slli	a5,a5,0x1
ffffffffc020088c:	8385                	srli	a5,a5,0x1
ffffffffc020088e:	06f76c63          	bltu	a4,a5,ffffffffc0200906 <interrupt_handler+0x82>
ffffffffc0200892:	00005717          	auipc	a4,0x5
ffffffffc0200896:	df670713          	addi	a4,a4,-522 # ffffffffc0205688 <commands+0x4e0>
ffffffffc020089a:	078a                	slli	a5,a5,0x2
ffffffffc020089c:	97ba                	add	a5,a5,a4
ffffffffc020089e:	439c                	lw	a5,0(a5)
ffffffffc02008a0:	97ba                	add	a5,a5,a4
ffffffffc02008a2:	8782                	jr	a5
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
ffffffffc02008a4:	00005517          	auipc	a0,0x5
ffffffffc02008a8:	d9450513          	addi	a0,a0,-620 # ffffffffc0205638 <commands+0x490>
ffffffffc02008ac:	821ff06f          	j	ffffffffc02000cc <cprintf>
            cprintf("Hypervisor software interrupt\n");
ffffffffc02008b0:	00005517          	auipc	a0,0x5
ffffffffc02008b4:	d6850513          	addi	a0,a0,-664 # ffffffffc0205618 <commands+0x470>
ffffffffc02008b8:	815ff06f          	j	ffffffffc02000cc <cprintf>
            cprintf("User software interrupt\n");
ffffffffc02008bc:	00005517          	auipc	a0,0x5
ffffffffc02008c0:	d1c50513          	addi	a0,a0,-740 # ffffffffc02055d8 <commands+0x430>
ffffffffc02008c4:	809ff06f          	j	ffffffffc02000cc <cprintf>
            cprintf("Supervisor software interrupt\n");
ffffffffc02008c8:	00005517          	auipc	a0,0x5
ffffffffc02008cc:	d3050513          	addi	a0,a0,-720 # ffffffffc02055f8 <commands+0x450>
ffffffffc02008d0:	ffcff06f          	j	ffffffffc02000cc <cprintf>
void interrupt_handler(struct trapframe *tf) {
ffffffffc02008d4:	1141                	addi	sp,sp,-16
ffffffffc02008d6:	e406                	sd	ra,8(sp)
            // "All bits besides SSIP and USIP in the sip register are
            // read-only." -- privileged spec1.9.1, 4.1.4, p59
            // In fact, Call sbi_set_timer will clear STIP, or you can clear it
            // directly.
            // clear_csr(sip, SIP_STIP);
            clock_set_next_event();
ffffffffc02008d8:	c59ff0ef          	jal	ra,ffffffffc0200530 <clock_set_next_event>
            if (++ticks % TICK_NUM == 0) {
ffffffffc02008dc:	00016697          	auipc	a3,0x16
ffffffffc02008e0:	c6468693          	addi	a3,a3,-924 # ffffffffc0216540 <ticks>
ffffffffc02008e4:	629c                	ld	a5,0(a3)
ffffffffc02008e6:	06400713          	li	a4,100
ffffffffc02008ea:	0785                	addi	a5,a5,1
ffffffffc02008ec:	02e7f733          	remu	a4,a5,a4
ffffffffc02008f0:	e29c                	sd	a5,0(a3)
ffffffffc02008f2:	cb19                	beqz	a4,ffffffffc0200908 <interrupt_handler+0x84>
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc02008f4:	60a2                	ld	ra,8(sp)
ffffffffc02008f6:	0141                	addi	sp,sp,16
ffffffffc02008f8:	8082                	ret
            cprintf("Supervisor external interrupt\n");
ffffffffc02008fa:	00005517          	auipc	a0,0x5
ffffffffc02008fe:	d6e50513          	addi	a0,a0,-658 # ffffffffc0205668 <commands+0x4c0>
ffffffffc0200902:	fcaff06f          	j	ffffffffc02000cc <cprintf>
            print_trapframe(tf);
ffffffffc0200906:	bf31                	j	ffffffffc0200822 <print_trapframe>
}
ffffffffc0200908:	60a2                	ld	ra,8(sp)
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc020090a:	06400593          	li	a1,100
ffffffffc020090e:	00005517          	auipc	a0,0x5
ffffffffc0200912:	d4a50513          	addi	a0,a0,-694 # ffffffffc0205658 <commands+0x4b0>
}
ffffffffc0200916:	0141                	addi	sp,sp,16
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200918:	fb4ff06f          	j	ffffffffc02000cc <cprintf>

ffffffffc020091c <exception_handler>:

void exception_handler(struct trapframe *tf) {
    int ret;
    switch (tf->cause) {
ffffffffc020091c:	11853783          	ld	a5,280(a0)
void exception_handler(struct trapframe *tf) {
ffffffffc0200920:	1101                	addi	sp,sp,-32
ffffffffc0200922:	e822                	sd	s0,16(sp)
ffffffffc0200924:	ec06                	sd	ra,24(sp)
ffffffffc0200926:	e426                	sd	s1,8(sp)
ffffffffc0200928:	473d                	li	a4,15
ffffffffc020092a:	842a                	mv	s0,a0
ffffffffc020092c:	14f76a63          	bltu	a4,a5,ffffffffc0200a80 <exception_handler+0x164>
ffffffffc0200930:	00005717          	auipc	a4,0x5
ffffffffc0200934:	f4070713          	addi	a4,a4,-192 # ffffffffc0205870 <commands+0x6c8>
ffffffffc0200938:	078a                	slli	a5,a5,0x2
ffffffffc020093a:	97ba                	add	a5,a5,a4
ffffffffc020093c:	439c                	lw	a5,0(a5)
ffffffffc020093e:	97ba                	add	a5,a5,a4
ffffffffc0200940:	8782                	jr	a5
                print_trapframe(tf);
                panic("handle pgfault failed. %e\n", ret);
            }
            break;
        case CAUSE_STORE_PAGE_FAULT:
            cprintf("Store/AMO page fault\n");
ffffffffc0200942:	00005517          	auipc	a0,0x5
ffffffffc0200946:	f1650513          	addi	a0,a0,-234 # ffffffffc0205858 <commands+0x6b0>
ffffffffc020094a:	f82ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc020094e:	8522                	mv	a0,s0
ffffffffc0200950:	c7bff0ef          	jal	ra,ffffffffc02005ca <pgfault_handler>
ffffffffc0200954:	84aa                	mv	s1,a0
ffffffffc0200956:	12051b63          	bnez	a0,ffffffffc0200a8c <exception_handler+0x170>
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc020095a:	60e2                	ld	ra,24(sp)
ffffffffc020095c:	6442                	ld	s0,16(sp)
ffffffffc020095e:	64a2                	ld	s1,8(sp)
ffffffffc0200960:	6105                	addi	sp,sp,32
ffffffffc0200962:	8082                	ret
            cprintf("Instruction address misaligned\n");
ffffffffc0200964:	00005517          	auipc	a0,0x5
ffffffffc0200968:	d5450513          	addi	a0,a0,-684 # ffffffffc02056b8 <commands+0x510>
}
ffffffffc020096c:	6442                	ld	s0,16(sp)
ffffffffc020096e:	60e2                	ld	ra,24(sp)
ffffffffc0200970:	64a2                	ld	s1,8(sp)
ffffffffc0200972:	6105                	addi	sp,sp,32
            cprintf("Instruction access fault\n");
ffffffffc0200974:	f58ff06f          	j	ffffffffc02000cc <cprintf>
ffffffffc0200978:	00005517          	auipc	a0,0x5
ffffffffc020097c:	d6050513          	addi	a0,a0,-672 # ffffffffc02056d8 <commands+0x530>
ffffffffc0200980:	b7f5                	j	ffffffffc020096c <exception_handler+0x50>
            cprintf("Illegal instruction\n");
ffffffffc0200982:	00005517          	auipc	a0,0x5
ffffffffc0200986:	d7650513          	addi	a0,a0,-650 # ffffffffc02056f8 <commands+0x550>
ffffffffc020098a:	b7cd                	j	ffffffffc020096c <exception_handler+0x50>
            cprintf("Breakpoint\n");
ffffffffc020098c:	00005517          	auipc	a0,0x5
ffffffffc0200990:	d8450513          	addi	a0,a0,-636 # ffffffffc0205710 <commands+0x568>
ffffffffc0200994:	bfe1                	j	ffffffffc020096c <exception_handler+0x50>
            cprintf("Load address misaligned\n");
ffffffffc0200996:	00005517          	auipc	a0,0x5
ffffffffc020099a:	d8a50513          	addi	a0,a0,-630 # ffffffffc0205720 <commands+0x578>
ffffffffc020099e:	b7f9                	j	ffffffffc020096c <exception_handler+0x50>
            cprintf("Load access fault\n");
ffffffffc02009a0:	00005517          	auipc	a0,0x5
ffffffffc02009a4:	da050513          	addi	a0,a0,-608 # ffffffffc0205740 <commands+0x598>
ffffffffc02009a8:	f24ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc02009ac:	8522                	mv	a0,s0
ffffffffc02009ae:	c1dff0ef          	jal	ra,ffffffffc02005ca <pgfault_handler>
ffffffffc02009b2:	84aa                	mv	s1,a0
ffffffffc02009b4:	d15d                	beqz	a0,ffffffffc020095a <exception_handler+0x3e>
                print_trapframe(tf);
ffffffffc02009b6:	8522                	mv	a0,s0
ffffffffc02009b8:	e6bff0ef          	jal	ra,ffffffffc0200822 <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc02009bc:	86a6                	mv	a3,s1
ffffffffc02009be:	00005617          	auipc	a2,0x5
ffffffffc02009c2:	d9a60613          	addi	a2,a2,-614 # ffffffffc0205758 <commands+0x5b0>
ffffffffc02009c6:	0b300593          	li	a1,179
ffffffffc02009ca:	00005517          	auipc	a0,0x5
ffffffffc02009ce:	87e50513          	addi	a0,a0,-1922 # ffffffffc0205248 <commands+0xa0>
ffffffffc02009d2:	ff6ff0ef          	jal	ra,ffffffffc02001c8 <__panic>
            cprintf("AMO address misaligned\n");
ffffffffc02009d6:	00005517          	auipc	a0,0x5
ffffffffc02009da:	da250513          	addi	a0,a0,-606 # ffffffffc0205778 <commands+0x5d0>
ffffffffc02009de:	b779                	j	ffffffffc020096c <exception_handler+0x50>
            cprintf("Store/AMO access fault\n");
ffffffffc02009e0:	00005517          	auipc	a0,0x5
ffffffffc02009e4:	db050513          	addi	a0,a0,-592 # ffffffffc0205790 <commands+0x5e8>
ffffffffc02009e8:	ee4ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc02009ec:	8522                	mv	a0,s0
ffffffffc02009ee:	bddff0ef          	jal	ra,ffffffffc02005ca <pgfault_handler>
ffffffffc02009f2:	84aa                	mv	s1,a0
ffffffffc02009f4:	d13d                	beqz	a0,ffffffffc020095a <exception_handler+0x3e>
                print_trapframe(tf);
ffffffffc02009f6:	8522                	mv	a0,s0
ffffffffc02009f8:	e2bff0ef          	jal	ra,ffffffffc0200822 <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc02009fc:	86a6                	mv	a3,s1
ffffffffc02009fe:	00005617          	auipc	a2,0x5
ffffffffc0200a02:	d5a60613          	addi	a2,a2,-678 # ffffffffc0205758 <commands+0x5b0>
ffffffffc0200a06:	0bd00593          	li	a1,189
ffffffffc0200a0a:	00005517          	auipc	a0,0x5
ffffffffc0200a0e:	83e50513          	addi	a0,a0,-1986 # ffffffffc0205248 <commands+0xa0>
ffffffffc0200a12:	fb6ff0ef          	jal	ra,ffffffffc02001c8 <__panic>
            cprintf("Environment call from U-mode\n");
ffffffffc0200a16:	00005517          	auipc	a0,0x5
ffffffffc0200a1a:	d9250513          	addi	a0,a0,-622 # ffffffffc02057a8 <commands+0x600>
ffffffffc0200a1e:	b7b9                	j	ffffffffc020096c <exception_handler+0x50>
            cprintf("Environment call from S-mode\n");
ffffffffc0200a20:	00005517          	auipc	a0,0x5
ffffffffc0200a24:	da850513          	addi	a0,a0,-600 # ffffffffc02057c8 <commands+0x620>
ffffffffc0200a28:	b791                	j	ffffffffc020096c <exception_handler+0x50>
            cprintf("Environment call from H-mode\n");
ffffffffc0200a2a:	00005517          	auipc	a0,0x5
ffffffffc0200a2e:	dbe50513          	addi	a0,a0,-578 # ffffffffc02057e8 <commands+0x640>
ffffffffc0200a32:	bf2d                	j	ffffffffc020096c <exception_handler+0x50>
            cprintf("Environment call from M-mode\n");
ffffffffc0200a34:	00005517          	auipc	a0,0x5
ffffffffc0200a38:	dd450513          	addi	a0,a0,-556 # ffffffffc0205808 <commands+0x660>
ffffffffc0200a3c:	bf05                	j	ffffffffc020096c <exception_handler+0x50>
            cprintf("Instruction page fault\n");
ffffffffc0200a3e:	00005517          	auipc	a0,0x5
ffffffffc0200a42:	dea50513          	addi	a0,a0,-534 # ffffffffc0205828 <commands+0x680>
ffffffffc0200a46:	b71d                	j	ffffffffc020096c <exception_handler+0x50>
            cprintf("Load page fault\n");
ffffffffc0200a48:	00005517          	auipc	a0,0x5
ffffffffc0200a4c:	df850513          	addi	a0,a0,-520 # ffffffffc0205840 <commands+0x698>
ffffffffc0200a50:	e7cff0ef          	jal	ra,ffffffffc02000cc <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc0200a54:	8522                	mv	a0,s0
ffffffffc0200a56:	b75ff0ef          	jal	ra,ffffffffc02005ca <pgfault_handler>
ffffffffc0200a5a:	84aa                	mv	s1,a0
ffffffffc0200a5c:	ee050fe3          	beqz	a0,ffffffffc020095a <exception_handler+0x3e>
                print_trapframe(tf);
ffffffffc0200a60:	8522                	mv	a0,s0
ffffffffc0200a62:	dc1ff0ef          	jal	ra,ffffffffc0200822 <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc0200a66:	86a6                	mv	a3,s1
ffffffffc0200a68:	00005617          	auipc	a2,0x5
ffffffffc0200a6c:	cf060613          	addi	a2,a2,-784 # ffffffffc0205758 <commands+0x5b0>
ffffffffc0200a70:	0d300593          	li	a1,211
ffffffffc0200a74:	00004517          	auipc	a0,0x4
ffffffffc0200a78:	7d450513          	addi	a0,a0,2004 # ffffffffc0205248 <commands+0xa0>
ffffffffc0200a7c:	f4cff0ef          	jal	ra,ffffffffc02001c8 <__panic>
            print_trapframe(tf);
ffffffffc0200a80:	8522                	mv	a0,s0
}
ffffffffc0200a82:	6442                	ld	s0,16(sp)
ffffffffc0200a84:	60e2                	ld	ra,24(sp)
ffffffffc0200a86:	64a2                	ld	s1,8(sp)
ffffffffc0200a88:	6105                	addi	sp,sp,32
            print_trapframe(tf);
ffffffffc0200a8a:	bb61                	j	ffffffffc0200822 <print_trapframe>
                print_trapframe(tf);
ffffffffc0200a8c:	8522                	mv	a0,s0
ffffffffc0200a8e:	d95ff0ef          	jal	ra,ffffffffc0200822 <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc0200a92:	86a6                	mv	a3,s1
ffffffffc0200a94:	00005617          	auipc	a2,0x5
ffffffffc0200a98:	cc460613          	addi	a2,a2,-828 # ffffffffc0205758 <commands+0x5b0>
ffffffffc0200a9c:	0da00593          	li	a1,218
ffffffffc0200aa0:	00004517          	auipc	a0,0x4
ffffffffc0200aa4:	7a850513          	addi	a0,a0,1960 # ffffffffc0205248 <commands+0xa0>
ffffffffc0200aa8:	f20ff0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc0200aac <trap>:
 * the code in kern/trap/trapentry.S restores the old CPU state saved in the
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf) {
    // dispatch based on what type of trap occurred
    if ((intptr_t)tf->cause < 0) {
ffffffffc0200aac:	11853783          	ld	a5,280(a0)
ffffffffc0200ab0:	0007c363          	bltz	a5,ffffffffc0200ab6 <trap+0xa>
        // interrupts
        interrupt_handler(tf);
    } else {
        // exceptions
        exception_handler(tf);
ffffffffc0200ab4:	b5a5                	j	ffffffffc020091c <exception_handler>
        interrupt_handler(tf);
ffffffffc0200ab6:	b3f9                	j	ffffffffc0200884 <interrupt_handler>

ffffffffc0200ab8 <__alltraps>:
    LOAD  x2,2*REGBYTES(sp)
    .endm

    .globl __alltraps
__alltraps:
    SAVE_ALL
ffffffffc0200ab8:	14011073          	csrw	sscratch,sp
ffffffffc0200abc:	712d                	addi	sp,sp,-288
ffffffffc0200abe:	e406                	sd	ra,8(sp)
ffffffffc0200ac0:	ec0e                	sd	gp,24(sp)
ffffffffc0200ac2:	f012                	sd	tp,32(sp)
ffffffffc0200ac4:	f416                	sd	t0,40(sp)
ffffffffc0200ac6:	f81a                	sd	t1,48(sp)
ffffffffc0200ac8:	fc1e                	sd	t2,56(sp)
ffffffffc0200aca:	e0a2                	sd	s0,64(sp)
ffffffffc0200acc:	e4a6                	sd	s1,72(sp)
ffffffffc0200ace:	e8aa                	sd	a0,80(sp)
ffffffffc0200ad0:	ecae                	sd	a1,88(sp)
ffffffffc0200ad2:	f0b2                	sd	a2,96(sp)
ffffffffc0200ad4:	f4b6                	sd	a3,104(sp)
ffffffffc0200ad6:	f8ba                	sd	a4,112(sp)
ffffffffc0200ad8:	fcbe                	sd	a5,120(sp)
ffffffffc0200ada:	e142                	sd	a6,128(sp)
ffffffffc0200adc:	e546                	sd	a7,136(sp)
ffffffffc0200ade:	e94a                	sd	s2,144(sp)
ffffffffc0200ae0:	ed4e                	sd	s3,152(sp)
ffffffffc0200ae2:	f152                	sd	s4,160(sp)
ffffffffc0200ae4:	f556                	sd	s5,168(sp)
ffffffffc0200ae6:	f95a                	sd	s6,176(sp)
ffffffffc0200ae8:	fd5e                	sd	s7,184(sp)
ffffffffc0200aea:	e1e2                	sd	s8,192(sp)
ffffffffc0200aec:	e5e6                	sd	s9,200(sp)
ffffffffc0200aee:	e9ea                	sd	s10,208(sp)
ffffffffc0200af0:	edee                	sd	s11,216(sp)
ffffffffc0200af2:	f1f2                	sd	t3,224(sp)
ffffffffc0200af4:	f5f6                	sd	t4,232(sp)
ffffffffc0200af6:	f9fa                	sd	t5,240(sp)
ffffffffc0200af8:	fdfe                	sd	t6,248(sp)
ffffffffc0200afa:	14002473          	csrr	s0,sscratch
ffffffffc0200afe:	100024f3          	csrr	s1,sstatus
ffffffffc0200b02:	14102973          	csrr	s2,sepc
ffffffffc0200b06:	143029f3          	csrr	s3,stval
ffffffffc0200b0a:	14202a73          	csrr	s4,scause
ffffffffc0200b0e:	e822                	sd	s0,16(sp)
ffffffffc0200b10:	e226                	sd	s1,256(sp)
ffffffffc0200b12:	e64a                	sd	s2,264(sp)
ffffffffc0200b14:	ea4e                	sd	s3,272(sp)
ffffffffc0200b16:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200b18:	850a                	mv	a0,sp
    jal trap
ffffffffc0200b1a:	f93ff0ef          	jal	ra,ffffffffc0200aac <trap>

ffffffffc0200b1e <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200b1e:	6492                	ld	s1,256(sp)
ffffffffc0200b20:	6932                	ld	s2,264(sp)
ffffffffc0200b22:	10049073          	csrw	sstatus,s1
ffffffffc0200b26:	14191073          	csrw	sepc,s2
ffffffffc0200b2a:	60a2                	ld	ra,8(sp)
ffffffffc0200b2c:	61e2                	ld	gp,24(sp)
ffffffffc0200b2e:	7202                	ld	tp,32(sp)
ffffffffc0200b30:	72a2                	ld	t0,40(sp)
ffffffffc0200b32:	7342                	ld	t1,48(sp)
ffffffffc0200b34:	73e2                	ld	t2,56(sp)
ffffffffc0200b36:	6406                	ld	s0,64(sp)
ffffffffc0200b38:	64a6                	ld	s1,72(sp)
ffffffffc0200b3a:	6546                	ld	a0,80(sp)
ffffffffc0200b3c:	65e6                	ld	a1,88(sp)
ffffffffc0200b3e:	7606                	ld	a2,96(sp)
ffffffffc0200b40:	76a6                	ld	a3,104(sp)
ffffffffc0200b42:	7746                	ld	a4,112(sp)
ffffffffc0200b44:	77e6                	ld	a5,120(sp)
ffffffffc0200b46:	680a                	ld	a6,128(sp)
ffffffffc0200b48:	68aa                	ld	a7,136(sp)
ffffffffc0200b4a:	694a                	ld	s2,144(sp)
ffffffffc0200b4c:	69ea                	ld	s3,152(sp)
ffffffffc0200b4e:	7a0a                	ld	s4,160(sp)
ffffffffc0200b50:	7aaa                	ld	s5,168(sp)
ffffffffc0200b52:	7b4a                	ld	s6,176(sp)
ffffffffc0200b54:	7bea                	ld	s7,184(sp)
ffffffffc0200b56:	6c0e                	ld	s8,192(sp)
ffffffffc0200b58:	6cae                	ld	s9,200(sp)
ffffffffc0200b5a:	6d4e                	ld	s10,208(sp)
ffffffffc0200b5c:	6dee                	ld	s11,216(sp)
ffffffffc0200b5e:	7e0e                	ld	t3,224(sp)
ffffffffc0200b60:	7eae                	ld	t4,232(sp)
ffffffffc0200b62:	7f4e                	ld	t5,240(sp)
ffffffffc0200b64:	7fee                	ld	t6,248(sp)
ffffffffc0200b66:	6142                	ld	sp,16(sp)
    # go back from supervisor call
    sret
ffffffffc0200b68:	10200073          	sret

ffffffffc0200b6c <forkrets>:
 
    .globl forkrets
forkrets:
    # set stack to this new process's trapframe
    move sp, a0
ffffffffc0200b6c:	812a                	mv	sp,a0
    j __trapret
ffffffffc0200b6e:	bf45                	j	ffffffffc0200b1e <__trapret>
	...

ffffffffc0200b72 <check_vma_overlap.part.0>:
}


// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next) {
ffffffffc0200b72:	1141                	addi	sp,sp,-16
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
ffffffffc0200b74:	00005697          	auipc	a3,0x5
ffffffffc0200b78:	d3c68693          	addi	a3,a3,-708 # ffffffffc02058b0 <commands+0x708>
ffffffffc0200b7c:	00005617          	auipc	a2,0x5
ffffffffc0200b80:	d5460613          	addi	a2,a2,-684 # ffffffffc02058d0 <commands+0x728>
ffffffffc0200b84:	07e00593          	li	a1,126
ffffffffc0200b88:	00005517          	auipc	a0,0x5
ffffffffc0200b8c:	d6050513          	addi	a0,a0,-672 # ffffffffc02058e8 <commands+0x740>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next) {
ffffffffc0200b90:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end);
ffffffffc0200b92:	e36ff0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc0200b96 <mm_create>:
mm_create(void) {
ffffffffc0200b96:	1141                	addi	sp,sp,-16
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0200b98:	03000513          	li	a0,48
mm_create(void) {
ffffffffc0200b9c:	e022                	sd	s0,0(sp)
ffffffffc0200b9e:	e406                	sd	ra,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0200ba0:	6a1000ef          	jal	ra,ffffffffc0201a40 <kmalloc>
ffffffffc0200ba4:	842a                	mv	s0,a0
    if (mm != NULL) {
ffffffffc0200ba6:	c105                	beqz	a0,ffffffffc0200bc6 <mm_create+0x30>
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200ba8:	e408                	sd	a0,8(s0)
ffffffffc0200baa:	e008                	sd	a0,0(s0)
        mm->mmap_cache = NULL;
ffffffffc0200bac:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0200bb0:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0200bb4:	02052023          	sw	zero,32(a0)
        if (swap_init_ok) swap_init_mm(mm);
ffffffffc0200bb8:	00016797          	auipc	a5,0x16
ffffffffc0200bbc:	9c07a783          	lw	a5,-1600(a5) # ffffffffc0216578 <swap_init_ok>
ffffffffc0200bc0:	eb81                	bnez	a5,ffffffffc0200bd0 <mm_create+0x3a>
        else mm->sm_priv = NULL;
ffffffffc0200bc2:	02053423          	sd	zero,40(a0)
}
ffffffffc0200bc6:	60a2                	ld	ra,8(sp)
ffffffffc0200bc8:	8522                	mv	a0,s0
ffffffffc0200bca:	6402                	ld	s0,0(sp)
ffffffffc0200bcc:	0141                	addi	sp,sp,16
ffffffffc0200bce:	8082                	ret
        if (swap_init_ok) swap_init_mm(mm);
ffffffffc0200bd0:	76c010ef          	jal	ra,ffffffffc020233c <swap_init_mm>
}
ffffffffc0200bd4:	60a2                	ld	ra,8(sp)
ffffffffc0200bd6:	8522                	mv	a0,s0
ffffffffc0200bd8:	6402                	ld	s0,0(sp)
ffffffffc0200bda:	0141                	addi	sp,sp,16
ffffffffc0200bdc:	8082                	ret

ffffffffc0200bde <vma_create>:
vma_create(uintptr_t vm_start, uintptr_t vm_end, uint32_t vm_flags) {
ffffffffc0200bde:	1101                	addi	sp,sp,-32
ffffffffc0200be0:	e04a                	sd	s2,0(sp)
ffffffffc0200be2:	892a                	mv	s2,a0
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0200be4:	03000513          	li	a0,48
vma_create(uintptr_t vm_start, uintptr_t vm_end, uint32_t vm_flags) {
ffffffffc0200be8:	e822                	sd	s0,16(sp)
ffffffffc0200bea:	e426                	sd	s1,8(sp)
ffffffffc0200bec:	ec06                	sd	ra,24(sp)
ffffffffc0200bee:	84ae                	mv	s1,a1
ffffffffc0200bf0:	8432                	mv	s0,a2
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0200bf2:	64f000ef          	jal	ra,ffffffffc0201a40 <kmalloc>
    if (vma != NULL) {
ffffffffc0200bf6:	c509                	beqz	a0,ffffffffc0200c00 <vma_create+0x22>
        vma->vm_start = vm_start;
ffffffffc0200bf8:	01253423          	sd	s2,8(a0)
        vma->vm_end = vm_end;
ffffffffc0200bfc:	e904                	sd	s1,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0200bfe:	cd00                	sw	s0,24(a0)
}
ffffffffc0200c00:	60e2                	ld	ra,24(sp)
ffffffffc0200c02:	6442                	ld	s0,16(sp)
ffffffffc0200c04:	64a2                	ld	s1,8(sp)
ffffffffc0200c06:	6902                	ld	s2,0(sp)
ffffffffc0200c08:	6105                	addi	sp,sp,32
ffffffffc0200c0a:	8082                	ret

ffffffffc0200c0c <find_vma>:
find_vma(struct mm_struct *mm, uintptr_t addr) {
ffffffffc0200c0c:	86aa                	mv	a3,a0
    if (mm != NULL) {
ffffffffc0200c0e:	c505                	beqz	a0,ffffffffc0200c36 <find_vma+0x2a>
        vma = mm->mmap_cache;
ffffffffc0200c10:	6908                	ld	a0,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr)) {
ffffffffc0200c12:	c501                	beqz	a0,ffffffffc0200c1a <find_vma+0xe>
ffffffffc0200c14:	651c                	ld	a5,8(a0)
ffffffffc0200c16:	02f5f263          	bgeu	a1,a5,ffffffffc0200c3a <find_vma+0x2e>
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200c1a:	669c                	ld	a5,8(a3)
                while ((le = list_next(le)) != list) {
ffffffffc0200c1c:	00f68d63          	beq	a3,a5,ffffffffc0200c36 <find_vma+0x2a>
                    if (vma->vm_start<=addr && addr < vma->vm_end) {
ffffffffc0200c20:	fe87b703          	ld	a4,-24(a5)
ffffffffc0200c24:	00e5e663          	bltu	a1,a4,ffffffffc0200c30 <find_vma+0x24>
ffffffffc0200c28:	ff07b703          	ld	a4,-16(a5)
ffffffffc0200c2c:	00e5ec63          	bltu	a1,a4,ffffffffc0200c44 <find_vma+0x38>
ffffffffc0200c30:	679c                	ld	a5,8(a5)
                while ((le = list_next(le)) != list) {
ffffffffc0200c32:	fef697e3          	bne	a3,a5,ffffffffc0200c20 <find_vma+0x14>
    struct vma_struct *vma = NULL;
ffffffffc0200c36:	4501                	li	a0,0
}
ffffffffc0200c38:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr)) {
ffffffffc0200c3a:	691c                	ld	a5,16(a0)
ffffffffc0200c3c:	fcf5ffe3          	bgeu	a1,a5,ffffffffc0200c1a <find_vma+0xe>
            mm->mmap_cache = vma;
ffffffffc0200c40:	ea88                	sd	a0,16(a3)
ffffffffc0200c42:	8082                	ret
                    vma = le2vma(le, list_link);
ffffffffc0200c44:	fe078513          	addi	a0,a5,-32
            mm->mmap_cache = vma;
ffffffffc0200c48:	ea88                	sd	a0,16(a3)
ffffffffc0200c4a:	8082                	ret

ffffffffc0200c4c <insert_vma_struct>:


// insert_vma_struct -insert vma in mm's list link
void
insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma) {
    assert(vma->vm_start < vma->vm_end);
ffffffffc0200c4c:	6590                	ld	a2,8(a1)
ffffffffc0200c4e:	0105b803          	ld	a6,16(a1)
insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma) {
ffffffffc0200c52:	1141                	addi	sp,sp,-16
ffffffffc0200c54:	e406                	sd	ra,8(sp)
ffffffffc0200c56:	87aa                	mv	a5,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc0200c58:	01066763          	bltu	a2,a6,ffffffffc0200c66 <insert_vma_struct+0x1a>
ffffffffc0200c5c:	a085                	j	ffffffffc0200cbc <insert_vma_struct+0x70>
    list_entry_t *le_prev = list, *le_next;

        list_entry_t *le = list;
        while ((le = list_next(le)) != list) {
            struct vma_struct *mmap_prev = le2vma(le, list_link);
            if (mmap_prev->vm_start > vma->vm_start) {
ffffffffc0200c5e:	fe87b703          	ld	a4,-24(a5)
ffffffffc0200c62:	04e66863          	bltu	a2,a4,ffffffffc0200cb2 <insert_vma_struct+0x66>
ffffffffc0200c66:	86be                	mv	a3,a5
ffffffffc0200c68:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list) {
ffffffffc0200c6a:	fef51ae3          	bne	a0,a5,ffffffffc0200c5e <insert_vma_struct+0x12>
        }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list) {
ffffffffc0200c6e:	02a68463          	beq	a3,a0,ffffffffc0200c96 <insert_vma_struct+0x4a>
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc0200c72:	ff06b703          	ld	a4,-16(a3)
    assert(prev->vm_start < prev->vm_end);
ffffffffc0200c76:	fe86b883          	ld	a7,-24(a3)
ffffffffc0200c7a:	08e8f163          	bgeu	a7,a4,ffffffffc0200cfc <insert_vma_struct+0xb0>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0200c7e:	04e66f63          	bltu	a2,a4,ffffffffc0200cdc <insert_vma_struct+0x90>
    }
    if (le_next != list) {
ffffffffc0200c82:	00f50a63          	beq	a0,a5,ffffffffc0200c96 <insert_vma_struct+0x4a>
            if (mmap_prev->vm_start > vma->vm_start) {
ffffffffc0200c86:	fe87b703          	ld	a4,-24(a5)
    assert(prev->vm_end <= next->vm_start);
ffffffffc0200c8a:	05076963          	bltu	a4,a6,ffffffffc0200cdc <insert_vma_struct+0x90>
    assert(next->vm_start < next->vm_end);
ffffffffc0200c8e:	ff07b603          	ld	a2,-16(a5)
ffffffffc0200c92:	02c77363          	bgeu	a4,a2,ffffffffc0200cb8 <insert_vma_struct+0x6c>
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count ++;
ffffffffc0200c96:	5118                	lw	a4,32(a0)
    vma->vm_mm = mm;
ffffffffc0200c98:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc0200c9a:	02058613          	addi	a2,a1,32
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc0200c9e:	e390                	sd	a2,0(a5)
ffffffffc0200ca0:	e690                	sd	a2,8(a3)
}
ffffffffc0200ca2:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc0200ca4:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc0200ca6:	f194                	sd	a3,32(a1)
    mm->map_count ++;
ffffffffc0200ca8:	0017079b          	addiw	a5,a4,1
ffffffffc0200cac:	d11c                	sw	a5,32(a0)
}
ffffffffc0200cae:	0141                	addi	sp,sp,16
ffffffffc0200cb0:	8082                	ret
    if (le_prev != list) {
ffffffffc0200cb2:	fca690e3          	bne	a3,a0,ffffffffc0200c72 <insert_vma_struct+0x26>
ffffffffc0200cb6:	bfd1                	j	ffffffffc0200c8a <insert_vma_struct+0x3e>
ffffffffc0200cb8:	ebbff0ef          	jal	ra,ffffffffc0200b72 <check_vma_overlap.part.0>
    assert(vma->vm_start < vma->vm_end);
ffffffffc0200cbc:	00005697          	auipc	a3,0x5
ffffffffc0200cc0:	c3c68693          	addi	a3,a3,-964 # ffffffffc02058f8 <commands+0x750>
ffffffffc0200cc4:	00005617          	auipc	a2,0x5
ffffffffc0200cc8:	c0c60613          	addi	a2,a2,-1012 # ffffffffc02058d0 <commands+0x728>
ffffffffc0200ccc:	08500593          	li	a1,133
ffffffffc0200cd0:	00005517          	auipc	a0,0x5
ffffffffc0200cd4:	c1850513          	addi	a0,a0,-1000 # ffffffffc02058e8 <commands+0x740>
ffffffffc0200cd8:	cf0ff0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0200cdc:	00005697          	auipc	a3,0x5
ffffffffc0200ce0:	c5c68693          	addi	a3,a3,-932 # ffffffffc0205938 <commands+0x790>
ffffffffc0200ce4:	00005617          	auipc	a2,0x5
ffffffffc0200ce8:	bec60613          	addi	a2,a2,-1044 # ffffffffc02058d0 <commands+0x728>
ffffffffc0200cec:	07d00593          	li	a1,125
ffffffffc0200cf0:	00005517          	auipc	a0,0x5
ffffffffc0200cf4:	bf850513          	addi	a0,a0,-1032 # ffffffffc02058e8 <commands+0x740>
ffffffffc0200cf8:	cd0ff0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(prev->vm_start < prev->vm_end);
ffffffffc0200cfc:	00005697          	auipc	a3,0x5
ffffffffc0200d00:	c1c68693          	addi	a3,a3,-996 # ffffffffc0205918 <commands+0x770>
ffffffffc0200d04:	00005617          	auipc	a2,0x5
ffffffffc0200d08:	bcc60613          	addi	a2,a2,-1076 # ffffffffc02058d0 <commands+0x728>
ffffffffc0200d0c:	07c00593          	li	a1,124
ffffffffc0200d10:	00005517          	auipc	a0,0x5
ffffffffc0200d14:	bd850513          	addi	a0,a0,-1064 # ffffffffc02058e8 <commands+0x740>
ffffffffc0200d18:	cb0ff0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc0200d1c <mm_destroy>:

// mm_destroy - free mm and mm internal fields
void
mm_destroy(struct mm_struct *mm) {
ffffffffc0200d1c:	1141                	addi	sp,sp,-16
ffffffffc0200d1e:	e022                	sd	s0,0(sp)
ffffffffc0200d20:	842a                	mv	s0,a0
    return listelm->next;
ffffffffc0200d22:	6508                	ld	a0,8(a0)
ffffffffc0200d24:	e406                	sd	ra,8(sp)

    list_entry_t *list = &(mm->mmap_list), *le;
    while ((le = list_next(list)) != list) {
ffffffffc0200d26:	00a40c63          	beq	s0,a0,ffffffffc0200d3e <mm_destroy+0x22>
    __list_del(listelm->prev, listelm->next);
ffffffffc0200d2a:	6118                	ld	a4,0(a0)
ffffffffc0200d2c:	651c                	ld	a5,8(a0)
        list_del(le);
        kfree(le2vma(le, list_link));  //kfree vma        
ffffffffc0200d2e:	1501                	addi	a0,a0,-32
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0200d30:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0200d32:	e398                	sd	a4,0(a5)
ffffffffc0200d34:	5bd000ef          	jal	ra,ffffffffc0201af0 <kfree>
    return listelm->next;
ffffffffc0200d38:	6408                	ld	a0,8(s0)
    while ((le = list_next(list)) != list) {
ffffffffc0200d3a:	fea418e3          	bne	s0,a0,ffffffffc0200d2a <mm_destroy+0xe>
    }
    kfree(mm); //kfree mm
ffffffffc0200d3e:	8522                	mv	a0,s0
    mm=NULL;
}
ffffffffc0200d40:	6402                	ld	s0,0(sp)
ffffffffc0200d42:	60a2                	ld	ra,8(sp)
ffffffffc0200d44:	0141                	addi	sp,sp,16
    kfree(mm); //kfree mm
ffffffffc0200d46:	5ab0006f          	j	ffffffffc0201af0 <kfree>

ffffffffc0200d4a <vmm_init>:

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void
vmm_init(void) {
ffffffffc0200d4a:	7139                	addi	sp,sp,-64
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0200d4c:	03000513          	li	a0,48
vmm_init(void) {
ffffffffc0200d50:	fc06                	sd	ra,56(sp)
ffffffffc0200d52:	f822                	sd	s0,48(sp)
ffffffffc0200d54:	f426                	sd	s1,40(sp)
ffffffffc0200d56:	f04a                	sd	s2,32(sp)
ffffffffc0200d58:	ec4e                	sd	s3,24(sp)
ffffffffc0200d5a:	e852                	sd	s4,16(sp)
ffffffffc0200d5c:	e456                	sd	s5,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0200d5e:	4e3000ef          	jal	ra,ffffffffc0201a40 <kmalloc>
    if (mm != NULL) {
ffffffffc0200d62:	58050e63          	beqz	a0,ffffffffc02012fe <vmm_init+0x5b4>
    elm->prev = elm->next = elm;
ffffffffc0200d66:	e508                	sd	a0,8(a0)
ffffffffc0200d68:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc0200d6a:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0200d6e:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0200d72:	02052023          	sw	zero,32(a0)
        if (swap_init_ok) swap_init_mm(mm);
ffffffffc0200d76:	00016797          	auipc	a5,0x16
ffffffffc0200d7a:	8027a783          	lw	a5,-2046(a5) # ffffffffc0216578 <swap_init_ok>
ffffffffc0200d7e:	84aa                	mv	s1,a0
ffffffffc0200d80:	e7b9                	bnez	a5,ffffffffc0200dce <vmm_init+0x84>
        else mm->sm_priv = NULL;
ffffffffc0200d82:	02053423          	sd	zero,40(a0)
vmm_init(void) {
ffffffffc0200d86:	03200413          	li	s0,50
ffffffffc0200d8a:	a811                	j	ffffffffc0200d9e <vmm_init+0x54>
        vma->vm_start = vm_start;
ffffffffc0200d8c:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc0200d8e:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0200d90:	00052c23          	sw	zero,24(a0)
    assert(mm != NULL);

    int step1 = 10, step2 = step1 * 10;

    int i;
    for (i = step1; i >= 1; i --) {
ffffffffc0200d94:	146d                	addi	s0,s0,-5
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0200d96:	8526                	mv	a0,s1
ffffffffc0200d98:	eb5ff0ef          	jal	ra,ffffffffc0200c4c <insert_vma_struct>
    for (i = step1; i >= 1; i --) {
ffffffffc0200d9c:	cc05                	beqz	s0,ffffffffc0200dd4 <vmm_init+0x8a>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0200d9e:	03000513          	li	a0,48
ffffffffc0200da2:	49f000ef          	jal	ra,ffffffffc0201a40 <kmalloc>
ffffffffc0200da6:	85aa                	mv	a1,a0
ffffffffc0200da8:	00240793          	addi	a5,s0,2
    if (vma != NULL) {
ffffffffc0200dac:	f165                	bnez	a0,ffffffffc0200d8c <vmm_init+0x42>
        assert(vma != NULL);
ffffffffc0200dae:	00005697          	auipc	a3,0x5
ffffffffc0200db2:	e0268693          	addi	a3,a3,-510 # ffffffffc0205bb0 <commands+0xa08>
ffffffffc0200db6:	00005617          	auipc	a2,0x5
ffffffffc0200dba:	b1a60613          	addi	a2,a2,-1254 # ffffffffc02058d0 <commands+0x728>
ffffffffc0200dbe:	0c900593          	li	a1,201
ffffffffc0200dc2:	00005517          	auipc	a0,0x5
ffffffffc0200dc6:	b2650513          	addi	a0,a0,-1242 # ffffffffc02058e8 <commands+0x740>
ffffffffc0200dca:	bfeff0ef          	jal	ra,ffffffffc02001c8 <__panic>
        if (swap_init_ok) swap_init_mm(mm);
ffffffffc0200dce:	56e010ef          	jal	ra,ffffffffc020233c <swap_init_mm>
ffffffffc0200dd2:	bf55                	j	ffffffffc0200d86 <vmm_init+0x3c>
ffffffffc0200dd4:	03700413          	li	s0,55
    }

    for (i = step1 + 1; i <= step2; i ++) {
ffffffffc0200dd8:	1f900913          	li	s2,505
ffffffffc0200ddc:	a819                	j	ffffffffc0200df2 <vmm_init+0xa8>
        vma->vm_start = vm_start;
ffffffffc0200dde:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc0200de0:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0200de2:	00052c23          	sw	zero,24(a0)
    for (i = step1 + 1; i <= step2; i ++) {
ffffffffc0200de6:	0415                	addi	s0,s0,5
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0200de8:	8526                	mv	a0,s1
ffffffffc0200dea:	e63ff0ef          	jal	ra,ffffffffc0200c4c <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i ++) {
ffffffffc0200dee:	03240a63          	beq	s0,s2,ffffffffc0200e22 <vmm_init+0xd8>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0200df2:	03000513          	li	a0,48
ffffffffc0200df6:	44b000ef          	jal	ra,ffffffffc0201a40 <kmalloc>
ffffffffc0200dfa:	85aa                	mv	a1,a0
ffffffffc0200dfc:	00240793          	addi	a5,s0,2
    if (vma != NULL) {
ffffffffc0200e00:	fd79                	bnez	a0,ffffffffc0200dde <vmm_init+0x94>
        assert(vma != NULL);
ffffffffc0200e02:	00005697          	auipc	a3,0x5
ffffffffc0200e06:	dae68693          	addi	a3,a3,-594 # ffffffffc0205bb0 <commands+0xa08>
ffffffffc0200e0a:	00005617          	auipc	a2,0x5
ffffffffc0200e0e:	ac660613          	addi	a2,a2,-1338 # ffffffffc02058d0 <commands+0x728>
ffffffffc0200e12:	0cf00593          	li	a1,207
ffffffffc0200e16:	00005517          	auipc	a0,0x5
ffffffffc0200e1a:	ad250513          	addi	a0,a0,-1326 # ffffffffc02058e8 <commands+0x740>
ffffffffc0200e1e:	baaff0ef          	jal	ra,ffffffffc02001c8 <__panic>
    return listelm->next;
ffffffffc0200e22:	649c                	ld	a5,8(s1)
ffffffffc0200e24:	471d                	li	a4,7
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i ++) {
ffffffffc0200e26:	1fb00593          	li	a1,507
        assert(le != &(mm->mmap_list));
ffffffffc0200e2a:	30f48e63          	beq	s1,a5,ffffffffc0201146 <vmm_init+0x3fc>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0200e2e:	fe87b683          	ld	a3,-24(a5)
ffffffffc0200e32:	ffe70613          	addi	a2,a4,-2
ffffffffc0200e36:	2ad61863          	bne	a2,a3,ffffffffc02010e6 <vmm_init+0x39c>
ffffffffc0200e3a:	ff07b683          	ld	a3,-16(a5)
ffffffffc0200e3e:	2ae69463          	bne	a3,a4,ffffffffc02010e6 <vmm_init+0x39c>
    for (i = 1; i <= step2; i ++) {
ffffffffc0200e42:	0715                	addi	a4,a4,5
ffffffffc0200e44:	679c                	ld	a5,8(a5)
ffffffffc0200e46:	feb712e3          	bne	a4,a1,ffffffffc0200e2a <vmm_init+0xe0>
ffffffffc0200e4a:	4a1d                	li	s4,7
ffffffffc0200e4c:	4415                	li	s0,5
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i +=5) {
ffffffffc0200e4e:	1f900a93          	li	s5,505
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc0200e52:	85a2                	mv	a1,s0
ffffffffc0200e54:	8526                	mv	a0,s1
ffffffffc0200e56:	db7ff0ef          	jal	ra,ffffffffc0200c0c <find_vma>
ffffffffc0200e5a:	892a                	mv	s2,a0
        assert(vma1 != NULL);
ffffffffc0200e5c:	34050563          	beqz	a0,ffffffffc02011a6 <vmm_init+0x45c>
        struct vma_struct *vma2 = find_vma(mm, i+1);
ffffffffc0200e60:	00140593          	addi	a1,s0,1
ffffffffc0200e64:	8526                	mv	a0,s1
ffffffffc0200e66:	da7ff0ef          	jal	ra,ffffffffc0200c0c <find_vma>
ffffffffc0200e6a:	89aa                	mv	s3,a0
        assert(vma2 != NULL);
ffffffffc0200e6c:	34050d63          	beqz	a0,ffffffffc02011c6 <vmm_init+0x47c>
        struct vma_struct *vma3 = find_vma(mm, i+2);
ffffffffc0200e70:	85d2                	mv	a1,s4
ffffffffc0200e72:	8526                	mv	a0,s1
ffffffffc0200e74:	d99ff0ef          	jal	ra,ffffffffc0200c0c <find_vma>
        assert(vma3 == NULL);
ffffffffc0200e78:	36051763          	bnez	a0,ffffffffc02011e6 <vmm_init+0x49c>
        struct vma_struct *vma4 = find_vma(mm, i+3);
ffffffffc0200e7c:	00340593          	addi	a1,s0,3
ffffffffc0200e80:	8526                	mv	a0,s1
ffffffffc0200e82:	d8bff0ef          	jal	ra,ffffffffc0200c0c <find_vma>
        assert(vma4 == NULL);
ffffffffc0200e86:	2e051063          	bnez	a0,ffffffffc0201166 <vmm_init+0x41c>
        struct vma_struct *vma5 = find_vma(mm, i+4);
ffffffffc0200e8a:	00440593          	addi	a1,s0,4
ffffffffc0200e8e:	8526                	mv	a0,s1
ffffffffc0200e90:	d7dff0ef          	jal	ra,ffffffffc0200c0c <find_vma>
        assert(vma5 == NULL);
ffffffffc0200e94:	2e051963          	bnez	a0,ffffffffc0201186 <vmm_init+0x43c>

        assert(vma1->vm_start == i  && vma1->vm_end == i  + 2);
ffffffffc0200e98:	00893783          	ld	a5,8(s2)
ffffffffc0200e9c:	26879563          	bne	a5,s0,ffffffffc0201106 <vmm_init+0x3bc>
ffffffffc0200ea0:	01093783          	ld	a5,16(s2)
ffffffffc0200ea4:	27479163          	bne	a5,s4,ffffffffc0201106 <vmm_init+0x3bc>
        assert(vma2->vm_start == i  && vma2->vm_end == i  + 2);
ffffffffc0200ea8:	0089b783          	ld	a5,8(s3)
ffffffffc0200eac:	26879d63          	bne	a5,s0,ffffffffc0201126 <vmm_init+0x3dc>
ffffffffc0200eb0:	0109b783          	ld	a5,16(s3)
ffffffffc0200eb4:	27479963          	bne	a5,s4,ffffffffc0201126 <vmm_init+0x3dc>
    for (i = 5; i <= 5 * step2; i +=5) {
ffffffffc0200eb8:	0415                	addi	s0,s0,5
ffffffffc0200eba:	0a15                	addi	s4,s4,5
ffffffffc0200ebc:	f9541be3          	bne	s0,s5,ffffffffc0200e52 <vmm_init+0x108>
ffffffffc0200ec0:	4411                	li	s0,4
    }

    for (i =4; i>=0; i--) {
ffffffffc0200ec2:	597d                	li	s2,-1
        struct vma_struct *vma_below_5= find_vma(mm,i);
ffffffffc0200ec4:	85a2                	mv	a1,s0
ffffffffc0200ec6:	8526                	mv	a0,s1
ffffffffc0200ec8:	d45ff0ef          	jal	ra,ffffffffc0200c0c <find_vma>
ffffffffc0200ecc:	0004059b          	sext.w	a1,s0
        if (vma_below_5 != NULL ) {
ffffffffc0200ed0:	c90d                	beqz	a0,ffffffffc0200f02 <vmm_init+0x1b8>
           cprintf("vma_below_5: i %x, start %x, end %x\n",i, vma_below_5->vm_start, vma_below_5->vm_end); 
ffffffffc0200ed2:	6914                	ld	a3,16(a0)
ffffffffc0200ed4:	6510                	ld	a2,8(a0)
ffffffffc0200ed6:	00005517          	auipc	a0,0x5
ffffffffc0200eda:	b8250513          	addi	a0,a0,-1150 # ffffffffc0205a58 <commands+0x8b0>
ffffffffc0200ede:	9eeff0ef          	jal	ra,ffffffffc02000cc <cprintf>
        }
        assert(vma_below_5 == NULL);
ffffffffc0200ee2:	00005697          	auipc	a3,0x5
ffffffffc0200ee6:	b9e68693          	addi	a3,a3,-1122 # ffffffffc0205a80 <commands+0x8d8>
ffffffffc0200eea:	00005617          	auipc	a2,0x5
ffffffffc0200eee:	9e660613          	addi	a2,a2,-1562 # ffffffffc02058d0 <commands+0x728>
ffffffffc0200ef2:	0f100593          	li	a1,241
ffffffffc0200ef6:	00005517          	auipc	a0,0x5
ffffffffc0200efa:	9f250513          	addi	a0,a0,-1550 # ffffffffc02058e8 <commands+0x740>
ffffffffc0200efe:	acaff0ef          	jal	ra,ffffffffc02001c8 <__panic>
    for (i =4; i>=0; i--) {
ffffffffc0200f02:	147d                	addi	s0,s0,-1
ffffffffc0200f04:	fd2410e3          	bne	s0,s2,ffffffffc0200ec4 <vmm_init+0x17a>
ffffffffc0200f08:	a801                	j	ffffffffc0200f18 <vmm_init+0x1ce>
    __list_del(listelm->prev, listelm->next);
ffffffffc0200f0a:	6118                	ld	a4,0(a0)
ffffffffc0200f0c:	651c                	ld	a5,8(a0)
        kfree(le2vma(le, list_link));  //kfree vma        
ffffffffc0200f0e:	1501                	addi	a0,a0,-32
    prev->next = next;
ffffffffc0200f10:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0200f12:	e398                	sd	a4,0(a5)
ffffffffc0200f14:	3dd000ef          	jal	ra,ffffffffc0201af0 <kfree>
    return listelm->next;
ffffffffc0200f18:	6488                	ld	a0,8(s1)
    while ((le = list_next(list)) != list) {
ffffffffc0200f1a:	fea498e3          	bne	s1,a0,ffffffffc0200f0a <vmm_init+0x1c0>
    kfree(mm); //kfree mm
ffffffffc0200f1e:	8526                	mv	a0,s1
ffffffffc0200f20:	3d1000ef          	jal	ra,ffffffffc0201af0 <kfree>
    }

    mm_destroy(mm);

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc0200f24:	00005517          	auipc	a0,0x5
ffffffffc0200f28:	b7450513          	addi	a0,a0,-1164 # ffffffffc0205a98 <commands+0x8f0>
ffffffffc0200f2c:	9a0ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
struct mm_struct *check_mm_struct;

// check_pgfault - check correctness of pgfault handler
static void
check_pgfault(void) {
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc0200f30:	16a020ef          	jal	ra,ffffffffc020309a <nr_free_pages>
ffffffffc0200f34:	84aa                	mv	s1,a0
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0200f36:	03000513          	li	a0,48
ffffffffc0200f3a:	307000ef          	jal	ra,ffffffffc0201a40 <kmalloc>
ffffffffc0200f3e:	842a                	mv	s0,a0
    if (mm != NULL) {
ffffffffc0200f40:	2c050363          	beqz	a0,ffffffffc0201206 <vmm_init+0x4bc>
        if (swap_init_ok) swap_init_mm(mm);
ffffffffc0200f44:	00015797          	auipc	a5,0x15
ffffffffc0200f48:	6347a783          	lw	a5,1588(a5) # ffffffffc0216578 <swap_init_ok>
    elm->prev = elm->next = elm;
ffffffffc0200f4c:	e508                	sd	a0,8(a0)
ffffffffc0200f4e:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc0200f50:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0200f54:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0200f58:	02052023          	sw	zero,32(a0)
        if (swap_init_ok) swap_init_mm(mm);
ffffffffc0200f5c:	18079263          	bnez	a5,ffffffffc02010e0 <vmm_init+0x396>
        else mm->sm_priv = NULL;
ffffffffc0200f60:	02053423          	sd	zero,40(a0)

    check_mm_struct = mm_create();
    assert(check_mm_struct != NULL);

    struct mm_struct *mm = check_mm_struct;
    pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc0200f64:	00015917          	auipc	s2,0x15
ffffffffc0200f68:	62493903          	ld	s2,1572(s2) # ffffffffc0216588 <boot_pgdir>
    assert(pgdir[0] == 0);
ffffffffc0200f6c:	00093783          	ld	a5,0(s2)
    check_mm_struct = mm_create();
ffffffffc0200f70:	00015717          	auipc	a4,0x15
ffffffffc0200f74:	5e873023          	sd	s0,1504(a4) # ffffffffc0216550 <check_mm_struct>
    pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc0200f78:	01243c23          	sd	s2,24(s0)
    assert(pgdir[0] == 0);
ffffffffc0200f7c:	36079163          	bnez	a5,ffffffffc02012de <vmm_init+0x594>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0200f80:	03000513          	li	a0,48
ffffffffc0200f84:	2bd000ef          	jal	ra,ffffffffc0201a40 <kmalloc>
ffffffffc0200f88:	89aa                	mv	s3,a0
    if (vma != NULL) {
ffffffffc0200f8a:	2a050263          	beqz	a0,ffffffffc020122e <vmm_init+0x4e4>
        vma->vm_end = vm_end;
ffffffffc0200f8e:	002007b7          	lui	a5,0x200
ffffffffc0200f92:	00f9b823          	sd	a5,16(s3)
        vma->vm_flags = vm_flags;
ffffffffc0200f96:	4789                	li	a5,2

    struct vma_struct *vma = vma_create(0, PTSIZE, VM_WRITE);
    assert(vma != NULL);

    insert_vma_struct(mm, vma);
ffffffffc0200f98:	85aa                	mv	a1,a0
        vma->vm_flags = vm_flags;
ffffffffc0200f9a:	00f9ac23          	sw	a5,24(s3)
    insert_vma_struct(mm, vma);
ffffffffc0200f9e:	8522                	mv	a0,s0
        vma->vm_start = vm_start;
ffffffffc0200fa0:	0009b423          	sd	zero,8(s3)
    insert_vma_struct(mm, vma);
ffffffffc0200fa4:	ca9ff0ef          	jal	ra,ffffffffc0200c4c <insert_vma_struct>

    uintptr_t addr = 0x100;
    assert(find_vma(mm, addr) == vma);
ffffffffc0200fa8:	10000593          	li	a1,256
ffffffffc0200fac:	8522                	mv	a0,s0
ffffffffc0200fae:	c5fff0ef          	jal	ra,ffffffffc0200c0c <find_vma>
ffffffffc0200fb2:	10000793          	li	a5,256

    int i, sum = 0;
    for (i = 0; i < 100; i ++) {
ffffffffc0200fb6:	16400713          	li	a4,356
    assert(find_vma(mm, addr) == vma);
ffffffffc0200fba:	28a99a63          	bne	s3,a0,ffffffffc020124e <vmm_init+0x504>
        *(char *)(addr + i) = i;
ffffffffc0200fbe:	00f78023          	sb	a5,0(a5) # 200000 <kern_entry-0xffffffffc0000000>
    for (i = 0; i < 100; i ++) {
ffffffffc0200fc2:	0785                	addi	a5,a5,1
ffffffffc0200fc4:	fee79de3          	bne	a5,a4,ffffffffc0200fbe <vmm_init+0x274>
        sum += i;
ffffffffc0200fc8:	6705                	lui	a4,0x1
ffffffffc0200fca:	10000793          	li	a5,256
ffffffffc0200fce:	35670713          	addi	a4,a4,854 # 1356 <kern_entry-0xffffffffc01fecaa>
    }
    for (i = 0; i < 100; i ++) {
ffffffffc0200fd2:	16400613          	li	a2,356
        sum -= *(char *)(addr + i);
ffffffffc0200fd6:	0007c683          	lbu	a3,0(a5)
    for (i = 0; i < 100; i ++) {
ffffffffc0200fda:	0785                	addi	a5,a5,1
        sum -= *(char *)(addr + i);
ffffffffc0200fdc:	9f15                	subw	a4,a4,a3
    for (i = 0; i < 100; i ++) {
ffffffffc0200fde:	fec79ce3          	bne	a5,a2,ffffffffc0200fd6 <vmm_init+0x28c>
    }
    assert(sum == 0);
ffffffffc0200fe2:	28071663          	bnez	a4,ffffffffc020126e <vmm_init+0x524>
    return pa2page(PTE_ADDR(pte));
}

static inline struct Page *
pde2page(pde_t pde) {
    return pa2page(PDE_ADDR(pde));
ffffffffc0200fe6:	00093783          	ld	a5,0(s2)
    if (PPN(pa) >= npage) {
ffffffffc0200fea:	00015a97          	auipc	s5,0x15
ffffffffc0200fee:	5a6a8a93          	addi	s5,s5,1446 # ffffffffc0216590 <npage>
ffffffffc0200ff2:	000ab603          	ld	a2,0(s5)
    return pa2page(PDE_ADDR(pde));
ffffffffc0200ff6:	078a                	slli	a5,a5,0x2
ffffffffc0200ff8:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0200ffa:	28c7fa63          	bgeu	a5,a2,ffffffffc020128e <vmm_init+0x544>
    return &pages[PPN(pa) - nbase];
ffffffffc0200ffe:	00006a17          	auipc	s4,0x6
ffffffffc0201002:	022a3a03          	ld	s4,34(s4) # ffffffffc0207020 <nbase>
ffffffffc0201006:	414787b3          	sub	a5,a5,s4
ffffffffc020100a:	079a                	slli	a5,a5,0x6
    return page - pages + nbase;
ffffffffc020100c:	8799                	srai	a5,a5,0x6
ffffffffc020100e:	97d2                	add	a5,a5,s4
    return KADDR(page2pa(page));
ffffffffc0201010:	00c79713          	slli	a4,a5,0xc
ffffffffc0201014:	8331                	srli	a4,a4,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0201016:	00c79693          	slli	a3,a5,0xc
    return KADDR(page2pa(page));
ffffffffc020101a:	28c77663          	bgeu	a4,a2,ffffffffc02012a6 <vmm_init+0x55c>
ffffffffc020101e:	00015997          	auipc	s3,0x15
ffffffffc0201022:	58a9b983          	ld	s3,1418(s3) # ffffffffc02165a8 <va_pa_offset>

    pde_t *pd1=pgdir,*pd0=page2kva(pde2page(pgdir[0]));
    page_remove(pgdir, ROUNDDOWN(addr, PGSIZE));
ffffffffc0201026:	4581                	li	a1,0
ffffffffc0201028:	854a                	mv	a0,s2
ffffffffc020102a:	99b6                	add	s3,s3,a3
ffffffffc020102c:	2ce020ef          	jal	ra,ffffffffc02032fa <page_remove>
    return pa2page(PDE_ADDR(pde));
ffffffffc0201030:	0009b783          	ld	a5,0(s3)
    if (PPN(pa) >= npage) {
ffffffffc0201034:	000ab703          	ld	a4,0(s5)
    return pa2page(PDE_ADDR(pde));
ffffffffc0201038:	078a                	slli	a5,a5,0x2
ffffffffc020103a:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc020103c:	24e7f963          	bgeu	a5,a4,ffffffffc020128e <vmm_init+0x544>
    return &pages[PPN(pa) - nbase];
ffffffffc0201040:	00015997          	auipc	s3,0x15
ffffffffc0201044:	55898993          	addi	s3,s3,1368 # ffffffffc0216598 <pages>
ffffffffc0201048:	0009b503          	ld	a0,0(s3)
ffffffffc020104c:	414787b3          	sub	a5,a5,s4
ffffffffc0201050:	079a                	slli	a5,a5,0x6
    free_page(pde2page(pd0[0]));
ffffffffc0201052:	953e                	add	a0,a0,a5
ffffffffc0201054:	4585                	li	a1,1
ffffffffc0201056:	004020ef          	jal	ra,ffffffffc020305a <free_pages>
    return pa2page(PDE_ADDR(pde));
ffffffffc020105a:	00093783          	ld	a5,0(s2)
    if (PPN(pa) >= npage) {
ffffffffc020105e:	000ab703          	ld	a4,0(s5)
    return pa2page(PDE_ADDR(pde));
ffffffffc0201062:	078a                	slli	a5,a5,0x2
ffffffffc0201064:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201066:	22e7f463          	bgeu	a5,a4,ffffffffc020128e <vmm_init+0x544>
    return &pages[PPN(pa) - nbase];
ffffffffc020106a:	0009b503          	ld	a0,0(s3)
ffffffffc020106e:	414787b3          	sub	a5,a5,s4
ffffffffc0201072:	079a                	slli	a5,a5,0x6
    free_page(pde2page(pd1[0]));
ffffffffc0201074:	4585                	li	a1,1
ffffffffc0201076:	953e                	add	a0,a0,a5
ffffffffc0201078:	7e3010ef          	jal	ra,ffffffffc020305a <free_pages>
    pgdir[0] = 0;
ffffffffc020107c:	00093023          	sd	zero,0(s2)
    page->ref -= 1;
    return page->ref;
}

static inline void flush_tlb() {
  asm volatile("sfence.vma");
ffffffffc0201080:	12000073          	sfence.vma
    return listelm->next;
ffffffffc0201084:	6408                	ld	a0,8(s0)
    flush_tlb();

    mm->pgdir = NULL;
ffffffffc0201086:	00043c23          	sd	zero,24(s0)
    while ((le = list_next(list)) != list) {
ffffffffc020108a:	00a40c63          	beq	s0,a0,ffffffffc02010a2 <vmm_init+0x358>
    __list_del(listelm->prev, listelm->next);
ffffffffc020108e:	6118                	ld	a4,0(a0)
ffffffffc0201090:	651c                	ld	a5,8(a0)
        kfree(le2vma(le, list_link));  //kfree vma        
ffffffffc0201092:	1501                	addi	a0,a0,-32
    prev->next = next;
ffffffffc0201094:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0201096:	e398                	sd	a4,0(a5)
ffffffffc0201098:	259000ef          	jal	ra,ffffffffc0201af0 <kfree>
    return listelm->next;
ffffffffc020109c:	6408                	ld	a0,8(s0)
    while ((le = list_next(list)) != list) {
ffffffffc020109e:	fea418e3          	bne	s0,a0,ffffffffc020108e <vmm_init+0x344>
    kfree(mm); //kfree mm
ffffffffc02010a2:	8522                	mv	a0,s0
ffffffffc02010a4:	24d000ef          	jal	ra,ffffffffc0201af0 <kfree>
    mm_destroy(mm);
    check_mm_struct = NULL;
ffffffffc02010a8:	00015797          	auipc	a5,0x15
ffffffffc02010ac:	4a07b423          	sd	zero,1192(a5) # ffffffffc0216550 <check_mm_struct>

    assert(nr_free_pages_store == nr_free_pages());
ffffffffc02010b0:	7eb010ef          	jal	ra,ffffffffc020309a <nr_free_pages>
ffffffffc02010b4:	20a49563          	bne	s1,a0,ffffffffc02012be <vmm_init+0x574>

    cprintf("check_pgfault() succeeded!\n");
ffffffffc02010b8:	00005517          	auipc	a0,0x5
ffffffffc02010bc:	ac050513          	addi	a0,a0,-1344 # ffffffffc0205b78 <commands+0x9d0>
ffffffffc02010c0:	80cff0ef          	jal	ra,ffffffffc02000cc <cprintf>
}
ffffffffc02010c4:	7442                	ld	s0,48(sp)
ffffffffc02010c6:	70e2                	ld	ra,56(sp)
ffffffffc02010c8:	74a2                	ld	s1,40(sp)
ffffffffc02010ca:	7902                	ld	s2,32(sp)
ffffffffc02010cc:	69e2                	ld	s3,24(sp)
ffffffffc02010ce:	6a42                	ld	s4,16(sp)
ffffffffc02010d0:	6aa2                	ld	s5,8(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc02010d2:	00005517          	auipc	a0,0x5
ffffffffc02010d6:	ac650513          	addi	a0,a0,-1338 # ffffffffc0205b98 <commands+0x9f0>
}
ffffffffc02010da:	6121                	addi	sp,sp,64
    cprintf("check_vmm() succeeded.\n");
ffffffffc02010dc:	ff1fe06f          	j	ffffffffc02000cc <cprintf>
        if (swap_init_ok) swap_init_mm(mm);
ffffffffc02010e0:	25c010ef          	jal	ra,ffffffffc020233c <swap_init_mm>
ffffffffc02010e4:	b541                	j	ffffffffc0200f64 <vmm_init+0x21a>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc02010e6:	00005697          	auipc	a3,0x5
ffffffffc02010ea:	88a68693          	addi	a3,a3,-1910 # ffffffffc0205970 <commands+0x7c8>
ffffffffc02010ee:	00004617          	auipc	a2,0x4
ffffffffc02010f2:	7e260613          	addi	a2,a2,2018 # ffffffffc02058d0 <commands+0x728>
ffffffffc02010f6:	0d800593          	li	a1,216
ffffffffc02010fa:	00004517          	auipc	a0,0x4
ffffffffc02010fe:	7ee50513          	addi	a0,a0,2030 # ffffffffc02058e8 <commands+0x740>
ffffffffc0201102:	8c6ff0ef          	jal	ra,ffffffffc02001c8 <__panic>
        assert(vma1->vm_start == i  && vma1->vm_end == i  + 2);
ffffffffc0201106:	00005697          	auipc	a3,0x5
ffffffffc020110a:	8f268693          	addi	a3,a3,-1806 # ffffffffc02059f8 <commands+0x850>
ffffffffc020110e:	00004617          	auipc	a2,0x4
ffffffffc0201112:	7c260613          	addi	a2,a2,1986 # ffffffffc02058d0 <commands+0x728>
ffffffffc0201116:	0e800593          	li	a1,232
ffffffffc020111a:	00004517          	auipc	a0,0x4
ffffffffc020111e:	7ce50513          	addi	a0,a0,1998 # ffffffffc02058e8 <commands+0x740>
ffffffffc0201122:	8a6ff0ef          	jal	ra,ffffffffc02001c8 <__panic>
        assert(vma2->vm_start == i  && vma2->vm_end == i  + 2);
ffffffffc0201126:	00005697          	auipc	a3,0x5
ffffffffc020112a:	90268693          	addi	a3,a3,-1790 # ffffffffc0205a28 <commands+0x880>
ffffffffc020112e:	00004617          	auipc	a2,0x4
ffffffffc0201132:	7a260613          	addi	a2,a2,1954 # ffffffffc02058d0 <commands+0x728>
ffffffffc0201136:	0e900593          	li	a1,233
ffffffffc020113a:	00004517          	auipc	a0,0x4
ffffffffc020113e:	7ae50513          	addi	a0,a0,1966 # ffffffffc02058e8 <commands+0x740>
ffffffffc0201142:	886ff0ef          	jal	ra,ffffffffc02001c8 <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc0201146:	00005697          	auipc	a3,0x5
ffffffffc020114a:	81268693          	addi	a3,a3,-2030 # ffffffffc0205958 <commands+0x7b0>
ffffffffc020114e:	00004617          	auipc	a2,0x4
ffffffffc0201152:	78260613          	addi	a2,a2,1922 # ffffffffc02058d0 <commands+0x728>
ffffffffc0201156:	0d600593          	li	a1,214
ffffffffc020115a:	00004517          	auipc	a0,0x4
ffffffffc020115e:	78e50513          	addi	a0,a0,1934 # ffffffffc02058e8 <commands+0x740>
ffffffffc0201162:	866ff0ef          	jal	ra,ffffffffc02001c8 <__panic>
        assert(vma4 == NULL);
ffffffffc0201166:	00005697          	auipc	a3,0x5
ffffffffc020116a:	87268693          	addi	a3,a3,-1934 # ffffffffc02059d8 <commands+0x830>
ffffffffc020116e:	00004617          	auipc	a2,0x4
ffffffffc0201172:	76260613          	addi	a2,a2,1890 # ffffffffc02058d0 <commands+0x728>
ffffffffc0201176:	0e400593          	li	a1,228
ffffffffc020117a:	00004517          	auipc	a0,0x4
ffffffffc020117e:	76e50513          	addi	a0,a0,1902 # ffffffffc02058e8 <commands+0x740>
ffffffffc0201182:	846ff0ef          	jal	ra,ffffffffc02001c8 <__panic>
        assert(vma5 == NULL);
ffffffffc0201186:	00005697          	auipc	a3,0x5
ffffffffc020118a:	86268693          	addi	a3,a3,-1950 # ffffffffc02059e8 <commands+0x840>
ffffffffc020118e:	00004617          	auipc	a2,0x4
ffffffffc0201192:	74260613          	addi	a2,a2,1858 # ffffffffc02058d0 <commands+0x728>
ffffffffc0201196:	0e600593          	li	a1,230
ffffffffc020119a:	00004517          	auipc	a0,0x4
ffffffffc020119e:	74e50513          	addi	a0,a0,1870 # ffffffffc02058e8 <commands+0x740>
ffffffffc02011a2:	826ff0ef          	jal	ra,ffffffffc02001c8 <__panic>
        assert(vma1 != NULL);
ffffffffc02011a6:	00005697          	auipc	a3,0x5
ffffffffc02011aa:	80268693          	addi	a3,a3,-2046 # ffffffffc02059a8 <commands+0x800>
ffffffffc02011ae:	00004617          	auipc	a2,0x4
ffffffffc02011b2:	72260613          	addi	a2,a2,1826 # ffffffffc02058d0 <commands+0x728>
ffffffffc02011b6:	0de00593          	li	a1,222
ffffffffc02011ba:	00004517          	auipc	a0,0x4
ffffffffc02011be:	72e50513          	addi	a0,a0,1838 # ffffffffc02058e8 <commands+0x740>
ffffffffc02011c2:	806ff0ef          	jal	ra,ffffffffc02001c8 <__panic>
        assert(vma2 != NULL);
ffffffffc02011c6:	00004697          	auipc	a3,0x4
ffffffffc02011ca:	7f268693          	addi	a3,a3,2034 # ffffffffc02059b8 <commands+0x810>
ffffffffc02011ce:	00004617          	auipc	a2,0x4
ffffffffc02011d2:	70260613          	addi	a2,a2,1794 # ffffffffc02058d0 <commands+0x728>
ffffffffc02011d6:	0e000593          	li	a1,224
ffffffffc02011da:	00004517          	auipc	a0,0x4
ffffffffc02011de:	70e50513          	addi	a0,a0,1806 # ffffffffc02058e8 <commands+0x740>
ffffffffc02011e2:	fe7fe0ef          	jal	ra,ffffffffc02001c8 <__panic>
        assert(vma3 == NULL);
ffffffffc02011e6:	00004697          	auipc	a3,0x4
ffffffffc02011ea:	7e268693          	addi	a3,a3,2018 # ffffffffc02059c8 <commands+0x820>
ffffffffc02011ee:	00004617          	auipc	a2,0x4
ffffffffc02011f2:	6e260613          	addi	a2,a2,1762 # ffffffffc02058d0 <commands+0x728>
ffffffffc02011f6:	0e200593          	li	a1,226
ffffffffc02011fa:	00004517          	auipc	a0,0x4
ffffffffc02011fe:	6ee50513          	addi	a0,a0,1774 # ffffffffc02058e8 <commands+0x740>
ffffffffc0201202:	fc7fe0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(check_mm_struct != NULL);
ffffffffc0201206:	00005697          	auipc	a3,0x5
ffffffffc020120a:	9ba68693          	addi	a3,a3,-1606 # ffffffffc0205bc0 <commands+0xa18>
ffffffffc020120e:	00004617          	auipc	a2,0x4
ffffffffc0201212:	6c260613          	addi	a2,a2,1730 # ffffffffc02058d0 <commands+0x728>
ffffffffc0201216:	10100593          	li	a1,257
ffffffffc020121a:	00004517          	auipc	a0,0x4
ffffffffc020121e:	6ce50513          	addi	a0,a0,1742 # ffffffffc02058e8 <commands+0x740>
    check_mm_struct = mm_create();
ffffffffc0201222:	00015797          	auipc	a5,0x15
ffffffffc0201226:	3207b723          	sd	zero,814(a5) # ffffffffc0216550 <check_mm_struct>
    assert(check_mm_struct != NULL);
ffffffffc020122a:	f9ffe0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(vma != NULL);
ffffffffc020122e:	00005697          	auipc	a3,0x5
ffffffffc0201232:	98268693          	addi	a3,a3,-1662 # ffffffffc0205bb0 <commands+0xa08>
ffffffffc0201236:	00004617          	auipc	a2,0x4
ffffffffc020123a:	69a60613          	addi	a2,a2,1690 # ffffffffc02058d0 <commands+0x728>
ffffffffc020123e:	10800593          	li	a1,264
ffffffffc0201242:	00004517          	auipc	a0,0x4
ffffffffc0201246:	6a650513          	addi	a0,a0,1702 # ffffffffc02058e8 <commands+0x740>
ffffffffc020124a:	f7ffe0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(find_vma(mm, addr) == vma);
ffffffffc020124e:	00005697          	auipc	a3,0x5
ffffffffc0201252:	87a68693          	addi	a3,a3,-1926 # ffffffffc0205ac8 <commands+0x920>
ffffffffc0201256:	00004617          	auipc	a2,0x4
ffffffffc020125a:	67a60613          	addi	a2,a2,1658 # ffffffffc02058d0 <commands+0x728>
ffffffffc020125e:	10d00593          	li	a1,269
ffffffffc0201262:	00004517          	auipc	a0,0x4
ffffffffc0201266:	68650513          	addi	a0,a0,1670 # ffffffffc02058e8 <commands+0x740>
ffffffffc020126a:	f5ffe0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(sum == 0);
ffffffffc020126e:	00005697          	auipc	a3,0x5
ffffffffc0201272:	87a68693          	addi	a3,a3,-1926 # ffffffffc0205ae8 <commands+0x940>
ffffffffc0201276:	00004617          	auipc	a2,0x4
ffffffffc020127a:	65a60613          	addi	a2,a2,1626 # ffffffffc02058d0 <commands+0x728>
ffffffffc020127e:	11700593          	li	a1,279
ffffffffc0201282:	00004517          	auipc	a0,0x4
ffffffffc0201286:	66650513          	addi	a0,a0,1638 # ffffffffc02058e8 <commands+0x740>
ffffffffc020128a:	f3ffe0ef          	jal	ra,ffffffffc02001c8 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc020128e:	00005617          	auipc	a2,0x5
ffffffffc0201292:	86a60613          	addi	a2,a2,-1942 # ffffffffc0205af8 <commands+0x950>
ffffffffc0201296:	06200593          	li	a1,98
ffffffffc020129a:	00005517          	auipc	a0,0x5
ffffffffc020129e:	87e50513          	addi	a0,a0,-1922 # ffffffffc0205b18 <commands+0x970>
ffffffffc02012a2:	f27fe0ef          	jal	ra,ffffffffc02001c8 <__panic>
    return KADDR(page2pa(page));
ffffffffc02012a6:	00005617          	auipc	a2,0x5
ffffffffc02012aa:	88260613          	addi	a2,a2,-1918 # ffffffffc0205b28 <commands+0x980>
ffffffffc02012ae:	06900593          	li	a1,105
ffffffffc02012b2:	00005517          	auipc	a0,0x5
ffffffffc02012b6:	86650513          	addi	a0,a0,-1946 # ffffffffc0205b18 <commands+0x970>
ffffffffc02012ba:	f0ffe0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(nr_free_pages_store == nr_free_pages());
ffffffffc02012be:	00005697          	auipc	a3,0x5
ffffffffc02012c2:	89268693          	addi	a3,a3,-1902 # ffffffffc0205b50 <commands+0x9a8>
ffffffffc02012c6:	00004617          	auipc	a2,0x4
ffffffffc02012ca:	60a60613          	addi	a2,a2,1546 # ffffffffc02058d0 <commands+0x728>
ffffffffc02012ce:	12400593          	li	a1,292
ffffffffc02012d2:	00004517          	auipc	a0,0x4
ffffffffc02012d6:	61650513          	addi	a0,a0,1558 # ffffffffc02058e8 <commands+0x740>
ffffffffc02012da:	eeffe0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(pgdir[0] == 0);
ffffffffc02012de:	00004697          	auipc	a3,0x4
ffffffffc02012e2:	7da68693          	addi	a3,a3,2010 # ffffffffc0205ab8 <commands+0x910>
ffffffffc02012e6:	00004617          	auipc	a2,0x4
ffffffffc02012ea:	5ea60613          	addi	a2,a2,1514 # ffffffffc02058d0 <commands+0x728>
ffffffffc02012ee:	10500593          	li	a1,261
ffffffffc02012f2:	00004517          	auipc	a0,0x4
ffffffffc02012f6:	5f650513          	addi	a0,a0,1526 # ffffffffc02058e8 <commands+0x740>
ffffffffc02012fa:	ecffe0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(mm != NULL);
ffffffffc02012fe:	00005697          	auipc	a3,0x5
ffffffffc0201302:	8da68693          	addi	a3,a3,-1830 # ffffffffc0205bd8 <commands+0xa30>
ffffffffc0201306:	00004617          	auipc	a2,0x4
ffffffffc020130a:	5ca60613          	addi	a2,a2,1482 # ffffffffc02058d0 <commands+0x728>
ffffffffc020130e:	0c200593          	li	a1,194
ffffffffc0201312:	00004517          	auipc	a0,0x4
ffffffffc0201316:	5d650513          	addi	a0,a0,1494 # ffffffffc02058e8 <commands+0x740>
ffffffffc020131a:	eaffe0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc020131e <do_pgfault>:
 *            was a read (0) or write (1).
 *         -- The U/S flag (bit 2) indicates whether the processor was executing at user mode (1)
 *            or supervisor mode (0) at the time of the exception.
 */
int
do_pgfault(struct mm_struct *mm, uint32_t error_code, uintptr_t addr) {
ffffffffc020131e:	7139                	addi	sp,sp,-64
    int ret = -E_INVAL;
    //try to find a vma which include addr
    struct vma_struct *vma = find_vma(mm, addr);
ffffffffc0201320:	85b2                	mv	a1,a2
do_pgfault(struct mm_struct *mm, uint32_t error_code, uintptr_t addr) {
ffffffffc0201322:	f822                	sd	s0,48(sp)
ffffffffc0201324:	f426                	sd	s1,40(sp)
ffffffffc0201326:	fc06                	sd	ra,56(sp)
ffffffffc0201328:	f04a                	sd	s2,32(sp)
ffffffffc020132a:	ec4e                	sd	s3,24(sp)
ffffffffc020132c:	8432                	mv	s0,a2
ffffffffc020132e:	84aa                	mv	s1,a0
    struct vma_struct *vma = find_vma(mm, addr);
ffffffffc0201330:	8ddff0ef          	jal	ra,ffffffffc0200c0c <find_vma>

    pgfault_num++;
ffffffffc0201334:	00015797          	auipc	a5,0x15
ffffffffc0201338:	2247a783          	lw	a5,548(a5) # ffffffffc0216558 <pgfault_num>
ffffffffc020133c:	2785                	addiw	a5,a5,1
ffffffffc020133e:	00015717          	auipc	a4,0x15
ffffffffc0201342:	20f72d23          	sw	a5,538(a4) # ffffffffc0216558 <pgfault_num>
    //If the addr is in the range of a mm's vma?
    if (vma == NULL || vma->vm_start > addr) {
ffffffffc0201346:	c551                	beqz	a0,ffffffffc02013d2 <do_pgfault+0xb4>
ffffffffc0201348:	651c                	ld	a5,8(a0)
ffffffffc020134a:	08f46463          	bltu	s0,a5,ffffffffc02013d2 <do_pgfault+0xb4>
     *    (read  an non_existed addr && addr is readable)
     * THEN
     *    continue process
     */
    uint32_t perm = PTE_U;
    if (vma->vm_flags & VM_WRITE) {
ffffffffc020134e:	4d1c                	lw	a5,24(a0)
    uint32_t perm = PTE_U;
ffffffffc0201350:	49c1                	li	s3,16
    if (vma->vm_flags & VM_WRITE) {
ffffffffc0201352:	8b89                	andi	a5,a5,2
ffffffffc0201354:	efb1                	bnez	a5,ffffffffc02013b0 <do_pgfault+0x92>
        perm |= READ_WRITE;
    }
    addr = ROUNDDOWN(addr, PGSIZE);
ffffffffc0201356:	75fd                	lui	a1,0xfffff

    pte_t *ptep=NULL;
  
    // try to find a pte, if pte's PT(Page Table) isn't existed, then create a PT.
    // (notice the 3th parameter '1')
    if ((ptep = get_pte(mm->pgdir, addr, 1)) == NULL) {
ffffffffc0201358:	6c88                	ld	a0,24(s1)
    addr = ROUNDDOWN(addr, PGSIZE);
ffffffffc020135a:	8c6d                	and	s0,s0,a1
    if ((ptep = get_pte(mm->pgdir, addr, 1)) == NULL) {
ffffffffc020135c:	4605                	li	a2,1
ffffffffc020135e:	85a2                	mv	a1,s0
ffffffffc0201360:	575010ef          	jal	ra,ffffffffc02030d4 <get_pte>
ffffffffc0201364:	c145                	beqz	a0,ffffffffc0201404 <do_pgfault+0xe6>
        cprintf("get_pte in do_pgfault failed\n");
        goto failed;
    }
    if (*ptep == 0) { // if the phy addr isn't exist, then alloc a page & map the phy addr with logical addr
ffffffffc0201366:	610c                	ld	a1,0(a0)
ffffffffc0201368:	c5b1                	beqz	a1,ffffffffc02013b4 <do_pgfault+0x96>
        *    swap_in(mm, addr, &page) : 分配一个内存页，然后根据
        *    PTE中的swap条目的addr，找到磁盘页的地址，将磁盘页的内容读入这个内存页
        *    page_insert ： 建立一个Page的phy addr与线性addr la的映射
        *    swap_map_swappable ： 设置页面可交换
        */
        if (swap_init_ok) {
ffffffffc020136a:	00015797          	auipc	a5,0x15
ffffffffc020136e:	20e7a783          	lw	a5,526(a5) # ffffffffc0216578 <swap_init_ok>
ffffffffc0201372:	cbad                	beqz	a5,ffffffffc02013e4 <do_pgfault+0xc6>
            //(2) According to the mm,
            //addr AND page, setup the
            //map of phy addr <--->
            //logical addr
            //(3) make the page swappable.
             if(swap_in(mm,addr,&page)){
ffffffffc0201374:	0030                	addi	a2,sp,8
ffffffffc0201376:	85a2                	mv	a1,s0
ffffffffc0201378:	8526                	mv	a0,s1
            struct Page *page = NULL;
ffffffffc020137a:	e402                	sd	zero,8(sp)
             if(swap_in(mm,addr,&page)){
ffffffffc020137c:	0ec010ef          	jal	ra,ffffffffc0202468 <swap_in>
ffffffffc0201380:	892a                	mv	s2,a0
ffffffffc0201382:	e92d                	bnez	a0,ffffffffc02013f4 <do_pgfault+0xd6>
                cprintf("swap page in do_pgfault failed\n");
                goto failed;
            }
            //交换成功
            page_insert(mm->pgdir,page,addr,perm);
ffffffffc0201384:	65a2                	ld	a1,8(sp)
ffffffffc0201386:	6c88                	ld	a0,24(s1)
ffffffffc0201388:	86ce                	mv	a3,s3
ffffffffc020138a:	8622                	mv	a2,s0
ffffffffc020138c:	00a020ef          	jal	ra,ffffffffc0203396 <page_insert>
            swap_map_swappable(mm,addr,page,1);
ffffffffc0201390:	6622                	ld	a2,8(sp)
ffffffffc0201392:	4685                	li	a3,1
ffffffffc0201394:	85a2                	mv	a1,s0
ffffffffc0201396:	8526                	mv	a0,s1
ffffffffc0201398:	7b1000ef          	jal	ra,ffffffffc0202348 <swap_map_swappable>
            page->pra_vaddr = addr;
ffffffffc020139c:	67a2                	ld	a5,8(sp)
ffffffffc020139e:	ff80                	sd	s0,56(a5)
   }

   ret = 0;
failed:
    return ret;
}
ffffffffc02013a0:	70e2                	ld	ra,56(sp)
ffffffffc02013a2:	7442                	ld	s0,48(sp)
ffffffffc02013a4:	74a2                	ld	s1,40(sp)
ffffffffc02013a6:	69e2                	ld	s3,24(sp)
ffffffffc02013a8:	854a                	mv	a0,s2
ffffffffc02013aa:	7902                	ld	s2,32(sp)
ffffffffc02013ac:	6121                	addi	sp,sp,64
ffffffffc02013ae:	8082                	ret
        perm |= READ_WRITE;
ffffffffc02013b0:	49dd                	li	s3,23
ffffffffc02013b2:	b755                	j	ffffffffc0201356 <do_pgfault+0x38>
        if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL) {
ffffffffc02013b4:	6c88                	ld	a0,24(s1)
ffffffffc02013b6:	864e                	mv	a2,s3
ffffffffc02013b8:	85a2                	mv	a1,s0
ffffffffc02013ba:	473020ef          	jal	ra,ffffffffc020402c <pgdir_alloc_page>
   ret = 0;
ffffffffc02013be:	4901                	li	s2,0
        if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL) {
ffffffffc02013c0:	f165                	bnez	a0,ffffffffc02013a0 <do_pgfault+0x82>
            cprintf("pgdir_alloc_page in do_pgfault failed\n");
ffffffffc02013c2:	00005517          	auipc	a0,0x5
ffffffffc02013c6:	87650513          	addi	a0,a0,-1930 # ffffffffc0205c38 <commands+0xa90>
ffffffffc02013ca:	d03fe0ef          	jal	ra,ffffffffc02000cc <cprintf>
    ret = -E_NO_MEM;
ffffffffc02013ce:	5971                	li	s2,-4
            goto failed;
ffffffffc02013d0:	bfc1                	j	ffffffffc02013a0 <do_pgfault+0x82>
        cprintf("not valid addr %x, and  can not find it in vma\n", addr);
ffffffffc02013d2:	85a2                	mv	a1,s0
ffffffffc02013d4:	00005517          	auipc	a0,0x5
ffffffffc02013d8:	81450513          	addi	a0,a0,-2028 # ffffffffc0205be8 <commands+0xa40>
ffffffffc02013dc:	cf1fe0ef          	jal	ra,ffffffffc02000cc <cprintf>
    int ret = -E_INVAL;
ffffffffc02013e0:	5975                	li	s2,-3
        goto failed;
ffffffffc02013e2:	bf7d                	j	ffffffffc02013a0 <do_pgfault+0x82>
            cprintf("no swap_init_ok but ptep is %x, failed\n", *ptep);
ffffffffc02013e4:	00005517          	auipc	a0,0x5
ffffffffc02013e8:	89c50513          	addi	a0,a0,-1892 # ffffffffc0205c80 <commands+0xad8>
ffffffffc02013ec:	ce1fe0ef          	jal	ra,ffffffffc02000cc <cprintf>
    ret = -E_NO_MEM;
ffffffffc02013f0:	5971                	li	s2,-4
            goto failed;
ffffffffc02013f2:	b77d                	j	ffffffffc02013a0 <do_pgfault+0x82>
                cprintf("swap page in do_pgfault failed\n");
ffffffffc02013f4:	00005517          	auipc	a0,0x5
ffffffffc02013f8:	86c50513          	addi	a0,a0,-1940 # ffffffffc0205c60 <commands+0xab8>
ffffffffc02013fc:	cd1fe0ef          	jal	ra,ffffffffc02000cc <cprintf>
    ret = -E_NO_MEM;
ffffffffc0201400:	5971                	li	s2,-4
ffffffffc0201402:	bf79                	j	ffffffffc02013a0 <do_pgfault+0x82>
        cprintf("get_pte in do_pgfault failed\n");
ffffffffc0201404:	00005517          	auipc	a0,0x5
ffffffffc0201408:	81450513          	addi	a0,a0,-2028 # ffffffffc0205c18 <commands+0xa70>
ffffffffc020140c:	cc1fe0ef          	jal	ra,ffffffffc02000cc <cprintf>
    ret = -E_NO_MEM;
ffffffffc0201410:	5971                	li	s2,-4
        goto failed;
ffffffffc0201412:	b779                	j	ffffffffc02013a0 <do_pgfault+0x82>

ffffffffc0201414 <_fifo_init_mm>:
    elm->prev = elm->next = elm;
ffffffffc0201414:	00011797          	auipc	a5,0x11
ffffffffc0201418:	04c78793          	addi	a5,a5,76 # ffffffffc0212460 <pra_list_head>
 */
static int
_fifo_init_mm(struct mm_struct *mm)
{     
     list_init(&pra_list_head);
     mm->sm_priv = &pra_list_head;
ffffffffc020141c:	f51c                	sd	a5,40(a0)
ffffffffc020141e:	e79c                	sd	a5,8(a5)
ffffffffc0201420:	e39c                	sd	a5,0(a5)
     //cprintf(" mm->sm_priv %x in fifo_init_mm\n",mm->sm_priv);
     return 0;
}
ffffffffc0201422:	4501                	li	a0,0
ffffffffc0201424:	8082                	ret

ffffffffc0201426 <_fifo_init>:

static int
_fifo_init(void)
{
    return 0;
}
ffffffffc0201426:	4501                	li	a0,0
ffffffffc0201428:	8082                	ret

ffffffffc020142a <_fifo_set_unswappable>:

static int
_fifo_set_unswappable(struct mm_struct *mm, uintptr_t addr)
{
    return 0;
}
ffffffffc020142a:	4501                	li	a0,0
ffffffffc020142c:	8082                	ret

ffffffffc020142e <_fifo_tick_event>:

static int
_fifo_tick_event(struct mm_struct *mm)
{ return 0; }
ffffffffc020142e:	4501                	li	a0,0
ffffffffc0201430:	8082                	ret

ffffffffc0201432 <_fifo_check_swap>:
_fifo_check_swap(void) {
ffffffffc0201432:	711d                	addi	sp,sp,-96
ffffffffc0201434:	fc4e                	sd	s3,56(sp)
ffffffffc0201436:	f852                	sd	s4,48(sp)
    cprintf("write Virt Page c in fifo_check_swap\n");
ffffffffc0201438:	00005517          	auipc	a0,0x5
ffffffffc020143c:	87050513          	addi	a0,a0,-1936 # ffffffffc0205ca8 <commands+0xb00>
    *(unsigned char *)0x3000 = 0x0c;
ffffffffc0201440:	698d                	lui	s3,0x3
ffffffffc0201442:	4a31                	li	s4,12
_fifo_check_swap(void) {
ffffffffc0201444:	e0ca                	sd	s2,64(sp)
ffffffffc0201446:	ec86                	sd	ra,88(sp)
ffffffffc0201448:	e8a2                	sd	s0,80(sp)
ffffffffc020144a:	e4a6                	sd	s1,72(sp)
ffffffffc020144c:	f456                	sd	s5,40(sp)
ffffffffc020144e:	f05a                	sd	s6,32(sp)
ffffffffc0201450:	ec5e                	sd	s7,24(sp)
ffffffffc0201452:	e862                	sd	s8,16(sp)
ffffffffc0201454:	e466                	sd	s9,8(sp)
ffffffffc0201456:	e06a                	sd	s10,0(sp)
    cprintf("write Virt Page c in fifo_check_swap\n");
ffffffffc0201458:	c75fe0ef          	jal	ra,ffffffffc02000cc <cprintf>
    *(unsigned char *)0x3000 = 0x0c;
ffffffffc020145c:	01498023          	sb	s4,0(s3) # 3000 <kern_entry-0xffffffffc01fd000>
    assert(pgfault_num==4);
ffffffffc0201460:	00015917          	auipc	s2,0x15
ffffffffc0201464:	0f892903          	lw	s2,248(s2) # ffffffffc0216558 <pgfault_num>
ffffffffc0201468:	4791                	li	a5,4
ffffffffc020146a:	14f91e63          	bne	s2,a5,ffffffffc02015c6 <_fifo_check_swap+0x194>
    cprintf("write Virt Page a in fifo_check_swap\n");
ffffffffc020146e:	00005517          	auipc	a0,0x5
ffffffffc0201472:	88a50513          	addi	a0,a0,-1910 # ffffffffc0205cf8 <commands+0xb50>
    *(unsigned char *)0x1000 = 0x0a;
ffffffffc0201476:	6a85                	lui	s5,0x1
ffffffffc0201478:	4b29                	li	s6,10
    cprintf("write Virt Page a in fifo_check_swap\n");
ffffffffc020147a:	c53fe0ef          	jal	ra,ffffffffc02000cc <cprintf>
ffffffffc020147e:	00015417          	auipc	s0,0x15
ffffffffc0201482:	0da40413          	addi	s0,s0,218 # ffffffffc0216558 <pgfault_num>
    *(unsigned char *)0x1000 = 0x0a;
ffffffffc0201486:	016a8023          	sb	s6,0(s5) # 1000 <kern_entry-0xffffffffc01ff000>
    assert(pgfault_num==4);
ffffffffc020148a:	4004                	lw	s1,0(s0)
ffffffffc020148c:	2481                	sext.w	s1,s1
ffffffffc020148e:	2b249c63          	bne	s1,s2,ffffffffc0201746 <_fifo_check_swap+0x314>
    cprintf("write Virt Page d in fifo_check_swap\n");
ffffffffc0201492:	00005517          	auipc	a0,0x5
ffffffffc0201496:	88e50513          	addi	a0,a0,-1906 # ffffffffc0205d20 <commands+0xb78>
    *(unsigned char *)0x4000 = 0x0d;
ffffffffc020149a:	6b91                	lui	s7,0x4
ffffffffc020149c:	4c35                	li	s8,13
    cprintf("write Virt Page d in fifo_check_swap\n");
ffffffffc020149e:	c2ffe0ef          	jal	ra,ffffffffc02000cc <cprintf>
    *(unsigned char *)0x4000 = 0x0d;
ffffffffc02014a2:	018b8023          	sb	s8,0(s7) # 4000 <kern_entry-0xffffffffc01fc000>
    assert(pgfault_num==4);
ffffffffc02014a6:	00042903          	lw	s2,0(s0)
ffffffffc02014aa:	2901                	sext.w	s2,s2
ffffffffc02014ac:	26991d63          	bne	s2,s1,ffffffffc0201726 <_fifo_check_swap+0x2f4>
    cprintf("write Virt Page b in fifo_check_swap\n");
ffffffffc02014b0:	00005517          	auipc	a0,0x5
ffffffffc02014b4:	89850513          	addi	a0,a0,-1896 # ffffffffc0205d48 <commands+0xba0>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc02014b8:	6c89                	lui	s9,0x2
ffffffffc02014ba:	4d2d                	li	s10,11
    cprintf("write Virt Page b in fifo_check_swap\n");
ffffffffc02014bc:	c11fe0ef          	jal	ra,ffffffffc02000cc <cprintf>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc02014c0:	01ac8023          	sb	s10,0(s9) # 2000 <kern_entry-0xffffffffc01fe000>
    assert(pgfault_num==4);
ffffffffc02014c4:	401c                	lw	a5,0(s0)
ffffffffc02014c6:	2781                	sext.w	a5,a5
ffffffffc02014c8:	23279f63          	bne	a5,s2,ffffffffc0201706 <_fifo_check_swap+0x2d4>
    cprintf("write Virt Page e in fifo_check_swap\n");
ffffffffc02014cc:	00005517          	auipc	a0,0x5
ffffffffc02014d0:	8a450513          	addi	a0,a0,-1884 # ffffffffc0205d70 <commands+0xbc8>
ffffffffc02014d4:	bf9fe0ef          	jal	ra,ffffffffc02000cc <cprintf>
    *(unsigned char *)0x5000 = 0x0e;
ffffffffc02014d8:	6795                	lui	a5,0x5
ffffffffc02014da:	4739                	li	a4,14
ffffffffc02014dc:	00e78023          	sb	a4,0(a5) # 5000 <kern_entry-0xffffffffc01fb000>
    assert(pgfault_num==5);
ffffffffc02014e0:	4004                	lw	s1,0(s0)
ffffffffc02014e2:	4795                	li	a5,5
ffffffffc02014e4:	2481                	sext.w	s1,s1
ffffffffc02014e6:	20f49063          	bne	s1,a5,ffffffffc02016e6 <_fifo_check_swap+0x2b4>
    cprintf("write Virt Page b in fifo_check_swap\n");
ffffffffc02014ea:	00005517          	auipc	a0,0x5
ffffffffc02014ee:	85e50513          	addi	a0,a0,-1954 # ffffffffc0205d48 <commands+0xba0>
ffffffffc02014f2:	bdbfe0ef          	jal	ra,ffffffffc02000cc <cprintf>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc02014f6:	01ac8023          	sb	s10,0(s9)
    assert(pgfault_num==5);
ffffffffc02014fa:	401c                	lw	a5,0(s0)
ffffffffc02014fc:	2781                	sext.w	a5,a5
ffffffffc02014fe:	1c979463          	bne	a5,s1,ffffffffc02016c6 <_fifo_check_swap+0x294>
    cprintf("write Virt Page a in fifo_check_swap\n");
ffffffffc0201502:	00004517          	auipc	a0,0x4
ffffffffc0201506:	7f650513          	addi	a0,a0,2038 # ffffffffc0205cf8 <commands+0xb50>
ffffffffc020150a:	bc3fe0ef          	jal	ra,ffffffffc02000cc <cprintf>
    *(unsigned char *)0x1000 = 0x0a;
ffffffffc020150e:	016a8023          	sb	s6,0(s5)
    assert(pgfault_num==6);
ffffffffc0201512:	401c                	lw	a5,0(s0)
ffffffffc0201514:	4719                	li	a4,6
ffffffffc0201516:	2781                	sext.w	a5,a5
ffffffffc0201518:	18e79763          	bne	a5,a4,ffffffffc02016a6 <_fifo_check_swap+0x274>
    cprintf("write Virt Page b in fifo_check_swap\n");
ffffffffc020151c:	00005517          	auipc	a0,0x5
ffffffffc0201520:	82c50513          	addi	a0,a0,-2004 # ffffffffc0205d48 <commands+0xba0>
ffffffffc0201524:	ba9fe0ef          	jal	ra,ffffffffc02000cc <cprintf>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc0201528:	01ac8023          	sb	s10,0(s9)
    assert(pgfault_num==7);
ffffffffc020152c:	401c                	lw	a5,0(s0)
ffffffffc020152e:	471d                	li	a4,7
ffffffffc0201530:	2781                	sext.w	a5,a5
ffffffffc0201532:	14e79a63          	bne	a5,a4,ffffffffc0201686 <_fifo_check_swap+0x254>
    cprintf("write Virt Page c in fifo_check_swap\n");
ffffffffc0201536:	00004517          	auipc	a0,0x4
ffffffffc020153a:	77250513          	addi	a0,a0,1906 # ffffffffc0205ca8 <commands+0xb00>
ffffffffc020153e:	b8ffe0ef          	jal	ra,ffffffffc02000cc <cprintf>
    *(unsigned char *)0x3000 = 0x0c;
ffffffffc0201542:	01498023          	sb	s4,0(s3)
    assert(pgfault_num==8);
ffffffffc0201546:	401c                	lw	a5,0(s0)
ffffffffc0201548:	4721                	li	a4,8
ffffffffc020154a:	2781                	sext.w	a5,a5
ffffffffc020154c:	10e79d63          	bne	a5,a4,ffffffffc0201666 <_fifo_check_swap+0x234>
    cprintf("write Virt Page d in fifo_check_swap\n");
ffffffffc0201550:	00004517          	auipc	a0,0x4
ffffffffc0201554:	7d050513          	addi	a0,a0,2000 # ffffffffc0205d20 <commands+0xb78>
ffffffffc0201558:	b75fe0ef          	jal	ra,ffffffffc02000cc <cprintf>
    *(unsigned char *)0x4000 = 0x0d;
ffffffffc020155c:	018b8023          	sb	s8,0(s7)
    assert(pgfault_num==9);
ffffffffc0201560:	401c                	lw	a5,0(s0)
ffffffffc0201562:	4725                	li	a4,9
ffffffffc0201564:	2781                	sext.w	a5,a5
ffffffffc0201566:	0ee79063          	bne	a5,a4,ffffffffc0201646 <_fifo_check_swap+0x214>
    cprintf("write Virt Page e in fifo_check_swap\n");
ffffffffc020156a:	00005517          	auipc	a0,0x5
ffffffffc020156e:	80650513          	addi	a0,a0,-2042 # ffffffffc0205d70 <commands+0xbc8>
ffffffffc0201572:	b5bfe0ef          	jal	ra,ffffffffc02000cc <cprintf>
    *(unsigned char *)0x5000 = 0x0e;
ffffffffc0201576:	6795                	lui	a5,0x5
ffffffffc0201578:	4739                	li	a4,14
ffffffffc020157a:	00e78023          	sb	a4,0(a5) # 5000 <kern_entry-0xffffffffc01fb000>
    assert(pgfault_num==10);
ffffffffc020157e:	4004                	lw	s1,0(s0)
ffffffffc0201580:	47a9                	li	a5,10
ffffffffc0201582:	2481                	sext.w	s1,s1
ffffffffc0201584:	0af49163          	bne	s1,a5,ffffffffc0201626 <_fifo_check_swap+0x1f4>
    cprintf("write Virt Page a in fifo_check_swap\n");
ffffffffc0201588:	00004517          	auipc	a0,0x4
ffffffffc020158c:	77050513          	addi	a0,a0,1904 # ffffffffc0205cf8 <commands+0xb50>
ffffffffc0201590:	b3dfe0ef          	jal	ra,ffffffffc02000cc <cprintf>
    assert(*(unsigned char *)0x1000 == 0x0a);
ffffffffc0201594:	6785                	lui	a5,0x1
ffffffffc0201596:	0007c783          	lbu	a5,0(a5) # 1000 <kern_entry-0xffffffffc01ff000>
ffffffffc020159a:	06979663          	bne	a5,s1,ffffffffc0201606 <_fifo_check_swap+0x1d4>
    assert(pgfault_num==11);
ffffffffc020159e:	401c                	lw	a5,0(s0)
ffffffffc02015a0:	472d                	li	a4,11
ffffffffc02015a2:	2781                	sext.w	a5,a5
ffffffffc02015a4:	04e79163          	bne	a5,a4,ffffffffc02015e6 <_fifo_check_swap+0x1b4>
}
ffffffffc02015a8:	60e6                	ld	ra,88(sp)
ffffffffc02015aa:	6446                	ld	s0,80(sp)
ffffffffc02015ac:	64a6                	ld	s1,72(sp)
ffffffffc02015ae:	6906                	ld	s2,64(sp)
ffffffffc02015b0:	79e2                	ld	s3,56(sp)
ffffffffc02015b2:	7a42                	ld	s4,48(sp)
ffffffffc02015b4:	7aa2                	ld	s5,40(sp)
ffffffffc02015b6:	7b02                	ld	s6,32(sp)
ffffffffc02015b8:	6be2                	ld	s7,24(sp)
ffffffffc02015ba:	6c42                	ld	s8,16(sp)
ffffffffc02015bc:	6ca2                	ld	s9,8(sp)
ffffffffc02015be:	6d02                	ld	s10,0(sp)
ffffffffc02015c0:	4501                	li	a0,0
ffffffffc02015c2:	6125                	addi	sp,sp,96
ffffffffc02015c4:	8082                	ret
    assert(pgfault_num==4);
ffffffffc02015c6:	00004697          	auipc	a3,0x4
ffffffffc02015ca:	70a68693          	addi	a3,a3,1802 # ffffffffc0205cd0 <commands+0xb28>
ffffffffc02015ce:	00004617          	auipc	a2,0x4
ffffffffc02015d2:	30260613          	addi	a2,a2,770 # ffffffffc02058d0 <commands+0x728>
ffffffffc02015d6:	05500593          	li	a1,85
ffffffffc02015da:	00004517          	auipc	a0,0x4
ffffffffc02015de:	70650513          	addi	a0,a0,1798 # ffffffffc0205ce0 <commands+0xb38>
ffffffffc02015e2:	be7fe0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(pgfault_num==11);
ffffffffc02015e6:	00005697          	auipc	a3,0x5
ffffffffc02015ea:	83a68693          	addi	a3,a3,-1990 # ffffffffc0205e20 <commands+0xc78>
ffffffffc02015ee:	00004617          	auipc	a2,0x4
ffffffffc02015f2:	2e260613          	addi	a2,a2,738 # ffffffffc02058d0 <commands+0x728>
ffffffffc02015f6:	07700593          	li	a1,119
ffffffffc02015fa:	00004517          	auipc	a0,0x4
ffffffffc02015fe:	6e650513          	addi	a0,a0,1766 # ffffffffc0205ce0 <commands+0xb38>
ffffffffc0201602:	bc7fe0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(*(unsigned char *)0x1000 == 0x0a);
ffffffffc0201606:	00004697          	auipc	a3,0x4
ffffffffc020160a:	7f268693          	addi	a3,a3,2034 # ffffffffc0205df8 <commands+0xc50>
ffffffffc020160e:	00004617          	auipc	a2,0x4
ffffffffc0201612:	2c260613          	addi	a2,a2,706 # ffffffffc02058d0 <commands+0x728>
ffffffffc0201616:	07500593          	li	a1,117
ffffffffc020161a:	00004517          	auipc	a0,0x4
ffffffffc020161e:	6c650513          	addi	a0,a0,1734 # ffffffffc0205ce0 <commands+0xb38>
ffffffffc0201622:	ba7fe0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(pgfault_num==10);
ffffffffc0201626:	00004697          	auipc	a3,0x4
ffffffffc020162a:	7c268693          	addi	a3,a3,1986 # ffffffffc0205de8 <commands+0xc40>
ffffffffc020162e:	00004617          	auipc	a2,0x4
ffffffffc0201632:	2a260613          	addi	a2,a2,674 # ffffffffc02058d0 <commands+0x728>
ffffffffc0201636:	07300593          	li	a1,115
ffffffffc020163a:	00004517          	auipc	a0,0x4
ffffffffc020163e:	6a650513          	addi	a0,a0,1702 # ffffffffc0205ce0 <commands+0xb38>
ffffffffc0201642:	b87fe0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(pgfault_num==9);
ffffffffc0201646:	00004697          	auipc	a3,0x4
ffffffffc020164a:	79268693          	addi	a3,a3,1938 # ffffffffc0205dd8 <commands+0xc30>
ffffffffc020164e:	00004617          	auipc	a2,0x4
ffffffffc0201652:	28260613          	addi	a2,a2,642 # ffffffffc02058d0 <commands+0x728>
ffffffffc0201656:	07000593          	li	a1,112
ffffffffc020165a:	00004517          	auipc	a0,0x4
ffffffffc020165e:	68650513          	addi	a0,a0,1670 # ffffffffc0205ce0 <commands+0xb38>
ffffffffc0201662:	b67fe0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(pgfault_num==8);
ffffffffc0201666:	00004697          	auipc	a3,0x4
ffffffffc020166a:	76268693          	addi	a3,a3,1890 # ffffffffc0205dc8 <commands+0xc20>
ffffffffc020166e:	00004617          	auipc	a2,0x4
ffffffffc0201672:	26260613          	addi	a2,a2,610 # ffffffffc02058d0 <commands+0x728>
ffffffffc0201676:	06d00593          	li	a1,109
ffffffffc020167a:	00004517          	auipc	a0,0x4
ffffffffc020167e:	66650513          	addi	a0,a0,1638 # ffffffffc0205ce0 <commands+0xb38>
ffffffffc0201682:	b47fe0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(pgfault_num==7);
ffffffffc0201686:	00004697          	auipc	a3,0x4
ffffffffc020168a:	73268693          	addi	a3,a3,1842 # ffffffffc0205db8 <commands+0xc10>
ffffffffc020168e:	00004617          	auipc	a2,0x4
ffffffffc0201692:	24260613          	addi	a2,a2,578 # ffffffffc02058d0 <commands+0x728>
ffffffffc0201696:	06a00593          	li	a1,106
ffffffffc020169a:	00004517          	auipc	a0,0x4
ffffffffc020169e:	64650513          	addi	a0,a0,1606 # ffffffffc0205ce0 <commands+0xb38>
ffffffffc02016a2:	b27fe0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(pgfault_num==6);
ffffffffc02016a6:	00004697          	auipc	a3,0x4
ffffffffc02016aa:	70268693          	addi	a3,a3,1794 # ffffffffc0205da8 <commands+0xc00>
ffffffffc02016ae:	00004617          	auipc	a2,0x4
ffffffffc02016b2:	22260613          	addi	a2,a2,546 # ffffffffc02058d0 <commands+0x728>
ffffffffc02016b6:	06700593          	li	a1,103
ffffffffc02016ba:	00004517          	auipc	a0,0x4
ffffffffc02016be:	62650513          	addi	a0,a0,1574 # ffffffffc0205ce0 <commands+0xb38>
ffffffffc02016c2:	b07fe0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(pgfault_num==5);
ffffffffc02016c6:	00004697          	auipc	a3,0x4
ffffffffc02016ca:	6d268693          	addi	a3,a3,1746 # ffffffffc0205d98 <commands+0xbf0>
ffffffffc02016ce:	00004617          	auipc	a2,0x4
ffffffffc02016d2:	20260613          	addi	a2,a2,514 # ffffffffc02058d0 <commands+0x728>
ffffffffc02016d6:	06400593          	li	a1,100
ffffffffc02016da:	00004517          	auipc	a0,0x4
ffffffffc02016de:	60650513          	addi	a0,a0,1542 # ffffffffc0205ce0 <commands+0xb38>
ffffffffc02016e2:	ae7fe0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(pgfault_num==5);
ffffffffc02016e6:	00004697          	auipc	a3,0x4
ffffffffc02016ea:	6b268693          	addi	a3,a3,1714 # ffffffffc0205d98 <commands+0xbf0>
ffffffffc02016ee:	00004617          	auipc	a2,0x4
ffffffffc02016f2:	1e260613          	addi	a2,a2,482 # ffffffffc02058d0 <commands+0x728>
ffffffffc02016f6:	06100593          	li	a1,97
ffffffffc02016fa:	00004517          	auipc	a0,0x4
ffffffffc02016fe:	5e650513          	addi	a0,a0,1510 # ffffffffc0205ce0 <commands+0xb38>
ffffffffc0201702:	ac7fe0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(pgfault_num==4);
ffffffffc0201706:	00004697          	auipc	a3,0x4
ffffffffc020170a:	5ca68693          	addi	a3,a3,1482 # ffffffffc0205cd0 <commands+0xb28>
ffffffffc020170e:	00004617          	auipc	a2,0x4
ffffffffc0201712:	1c260613          	addi	a2,a2,450 # ffffffffc02058d0 <commands+0x728>
ffffffffc0201716:	05e00593          	li	a1,94
ffffffffc020171a:	00004517          	auipc	a0,0x4
ffffffffc020171e:	5c650513          	addi	a0,a0,1478 # ffffffffc0205ce0 <commands+0xb38>
ffffffffc0201722:	aa7fe0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(pgfault_num==4);
ffffffffc0201726:	00004697          	auipc	a3,0x4
ffffffffc020172a:	5aa68693          	addi	a3,a3,1450 # ffffffffc0205cd0 <commands+0xb28>
ffffffffc020172e:	00004617          	auipc	a2,0x4
ffffffffc0201732:	1a260613          	addi	a2,a2,418 # ffffffffc02058d0 <commands+0x728>
ffffffffc0201736:	05b00593          	li	a1,91
ffffffffc020173a:	00004517          	auipc	a0,0x4
ffffffffc020173e:	5a650513          	addi	a0,a0,1446 # ffffffffc0205ce0 <commands+0xb38>
ffffffffc0201742:	a87fe0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(pgfault_num==4);
ffffffffc0201746:	00004697          	auipc	a3,0x4
ffffffffc020174a:	58a68693          	addi	a3,a3,1418 # ffffffffc0205cd0 <commands+0xb28>
ffffffffc020174e:	00004617          	auipc	a2,0x4
ffffffffc0201752:	18260613          	addi	a2,a2,386 # ffffffffc02058d0 <commands+0x728>
ffffffffc0201756:	05800593          	li	a1,88
ffffffffc020175a:	00004517          	auipc	a0,0x4
ffffffffc020175e:	58650513          	addi	a0,a0,1414 # ffffffffc0205ce0 <commands+0xb38>
ffffffffc0201762:	a67fe0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc0201766 <_fifo_swap_out_victim>:
     list_entry_t *head=(list_entry_t*) mm->sm_priv;
ffffffffc0201766:	7518                	ld	a4,40(a0)
{
ffffffffc0201768:	1141                	addi	sp,sp,-16
ffffffffc020176a:	e406                	sd	ra,8(sp)
         assert(head != NULL);
ffffffffc020176c:	c731                	beqz	a4,ffffffffc02017b8 <_fifo_swap_out_victim+0x52>
     assert(in_tick==0);
ffffffffc020176e:	e60d                	bnez	a2,ffffffffc0201798 <_fifo_swap_out_victim+0x32>
    return listelm->next;
ffffffffc0201770:	671c                	ld	a5,8(a4)
     if (entry != head) {
ffffffffc0201772:	00f70d63          	beq	a4,a5,ffffffffc020178c <_fifo_swap_out_victim+0x26>
    __list_del(listelm->prev, listelm->next);
ffffffffc0201776:	6394                	ld	a3,0(a5)
ffffffffc0201778:	6798                	ld	a4,8(a5)
}
ffffffffc020177a:	60a2                	ld	ra,8(sp)
        *ptr_page = le2page(entry, pra_page_link);
ffffffffc020177c:	fd878793          	addi	a5,a5,-40
    prev->next = next;
ffffffffc0201780:	e698                	sd	a4,8(a3)
    next->prev = prev;
ffffffffc0201782:	e314                	sd	a3,0(a4)
ffffffffc0201784:	e19c                	sd	a5,0(a1)
}
ffffffffc0201786:	4501                	li	a0,0
ffffffffc0201788:	0141                	addi	sp,sp,16
ffffffffc020178a:	8082                	ret
ffffffffc020178c:	60a2                	ld	ra,8(sp)
        *ptr_page = NULL;
ffffffffc020178e:	0005b023          	sd	zero,0(a1) # fffffffffffff000 <end+0x3fde8a34>
}
ffffffffc0201792:	4501                	li	a0,0
ffffffffc0201794:	0141                	addi	sp,sp,16
ffffffffc0201796:	8082                	ret
     assert(in_tick==0);
ffffffffc0201798:	00004697          	auipc	a3,0x4
ffffffffc020179c:	6a868693          	addi	a3,a3,1704 # ffffffffc0205e40 <commands+0xc98>
ffffffffc02017a0:	00004617          	auipc	a2,0x4
ffffffffc02017a4:	13060613          	addi	a2,a2,304 # ffffffffc02058d0 <commands+0x728>
ffffffffc02017a8:	04200593          	li	a1,66
ffffffffc02017ac:	00004517          	auipc	a0,0x4
ffffffffc02017b0:	53450513          	addi	a0,a0,1332 # ffffffffc0205ce0 <commands+0xb38>
ffffffffc02017b4:	a15fe0ef          	jal	ra,ffffffffc02001c8 <__panic>
         assert(head != NULL);
ffffffffc02017b8:	00004697          	auipc	a3,0x4
ffffffffc02017bc:	67868693          	addi	a3,a3,1656 # ffffffffc0205e30 <commands+0xc88>
ffffffffc02017c0:	00004617          	auipc	a2,0x4
ffffffffc02017c4:	11060613          	addi	a2,a2,272 # ffffffffc02058d0 <commands+0x728>
ffffffffc02017c8:	04100593          	li	a1,65
ffffffffc02017cc:	00004517          	auipc	a0,0x4
ffffffffc02017d0:	51450513          	addi	a0,a0,1300 # ffffffffc0205ce0 <commands+0xb38>
ffffffffc02017d4:	9f5fe0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc02017d8 <_fifo_map_swappable>:
    list_entry_t *head=(list_entry_t*) mm->sm_priv;
ffffffffc02017d8:	751c                	ld	a5,40(a0)
    assert(entry != NULL && head != NULL);
ffffffffc02017da:	cb91                	beqz	a5,ffffffffc02017ee <_fifo_map_swappable+0x16>
    __list_add(elm, listelm->prev, listelm);
ffffffffc02017dc:	6394                	ld	a3,0(a5)
ffffffffc02017de:	02860713          	addi	a4,a2,40
    prev->next = next->prev = elm;
ffffffffc02017e2:	e398                	sd	a4,0(a5)
ffffffffc02017e4:	e698                	sd	a4,8(a3)
}
ffffffffc02017e6:	4501                	li	a0,0
    elm->next = next;
ffffffffc02017e8:	fa1c                	sd	a5,48(a2)
    elm->prev = prev;
ffffffffc02017ea:	f614                	sd	a3,40(a2)
ffffffffc02017ec:	8082                	ret
{
ffffffffc02017ee:	1141                	addi	sp,sp,-16
    assert(entry != NULL && head != NULL);
ffffffffc02017f0:	00004697          	auipc	a3,0x4
ffffffffc02017f4:	66068693          	addi	a3,a3,1632 # ffffffffc0205e50 <commands+0xca8>
ffffffffc02017f8:	00004617          	auipc	a2,0x4
ffffffffc02017fc:	0d860613          	addi	a2,a2,216 # ffffffffc02058d0 <commands+0x728>
ffffffffc0201800:	03200593          	li	a1,50
ffffffffc0201804:	00004517          	auipc	a0,0x4
ffffffffc0201808:	4dc50513          	addi	a0,a0,1244 # ffffffffc0205ce0 <commands+0xb38>
{
ffffffffc020180c:	e406                	sd	ra,8(sp)
    assert(entry != NULL && head != NULL);
ffffffffc020180e:	9bbfe0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc0201812 <slob_free>:
static void slob_free(void *block, int size)
{
	slob_t *cur, *b = (slob_t *)block;
	unsigned long flags;

	if (!block)
ffffffffc0201812:	c94d                	beqz	a0,ffffffffc02018c4 <slob_free+0xb2>
{
ffffffffc0201814:	1141                	addi	sp,sp,-16
ffffffffc0201816:	e022                	sd	s0,0(sp)
ffffffffc0201818:	e406                	sd	ra,8(sp)
ffffffffc020181a:	842a                	mv	s0,a0
		return;

	if (size)
ffffffffc020181c:	e9c1                	bnez	a1,ffffffffc02018ac <slob_free+0x9a>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020181e:	100027f3          	csrr	a5,sstatus
ffffffffc0201822:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201824:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201826:	ebd9                	bnez	a5,ffffffffc02018bc <slob_free+0xaa>
		b->units = SLOB_UNITS(size);

	/* Find reinsertion point */
	spin_lock_irqsave(&slob_lock, flags);
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201828:	0000a617          	auipc	a2,0xa
ffffffffc020182c:	82860613          	addi	a2,a2,-2008 # ffffffffc020b050 <slobfree>
ffffffffc0201830:	621c                	ld	a5,0(a2)
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201832:	873e                	mv	a4,a5
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201834:	679c                	ld	a5,8(a5)
ffffffffc0201836:	02877a63          	bgeu	a4,s0,ffffffffc020186a <slob_free+0x58>
ffffffffc020183a:	00f46463          	bltu	s0,a5,ffffffffc0201842 <slob_free+0x30>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc020183e:	fef76ae3          	bltu	a4,a5,ffffffffc0201832 <slob_free+0x20>
			break;

	if (b + b->units == cur->next) {
ffffffffc0201842:	400c                	lw	a1,0(s0)
ffffffffc0201844:	00459693          	slli	a3,a1,0x4
ffffffffc0201848:	96a2                	add	a3,a3,s0
ffffffffc020184a:	02d78a63          	beq	a5,a3,ffffffffc020187e <slob_free+0x6c>
		b->units += cur->next->units;
		b->next = cur->next->next;
	} else
		b->next = cur->next;

	if (cur + cur->units == b) {
ffffffffc020184e:	4314                	lw	a3,0(a4)
		b->next = cur->next;
ffffffffc0201850:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b) {
ffffffffc0201852:	00469793          	slli	a5,a3,0x4
ffffffffc0201856:	97ba                	add	a5,a5,a4
ffffffffc0201858:	02f40e63          	beq	s0,a5,ffffffffc0201894 <slob_free+0x82>
		cur->units += b->units;
		cur->next = b->next;
	} else
		cur->next = b;
ffffffffc020185c:	e700                	sd	s0,8(a4)

	slobfree = cur;
ffffffffc020185e:	e218                	sd	a4,0(a2)
    if (flag) {
ffffffffc0201860:	e129                	bnez	a0,ffffffffc02018a2 <slob_free+0x90>

	spin_unlock_irqrestore(&slob_lock, flags);
}
ffffffffc0201862:	60a2                	ld	ra,8(sp)
ffffffffc0201864:	6402                	ld	s0,0(sp)
ffffffffc0201866:	0141                	addi	sp,sp,16
ffffffffc0201868:	8082                	ret
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc020186a:	fcf764e3          	bltu	a4,a5,ffffffffc0201832 <slob_free+0x20>
ffffffffc020186e:	fcf472e3          	bgeu	s0,a5,ffffffffc0201832 <slob_free+0x20>
	if (b + b->units == cur->next) {
ffffffffc0201872:	400c                	lw	a1,0(s0)
ffffffffc0201874:	00459693          	slli	a3,a1,0x4
ffffffffc0201878:	96a2                	add	a3,a3,s0
ffffffffc020187a:	fcd79ae3          	bne	a5,a3,ffffffffc020184e <slob_free+0x3c>
		b->units += cur->next->units;
ffffffffc020187e:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc0201880:	679c                	ld	a5,8(a5)
		b->units += cur->next->units;
ffffffffc0201882:	9db5                	addw	a1,a1,a3
ffffffffc0201884:	c00c                	sw	a1,0(s0)
	if (cur + cur->units == b) {
ffffffffc0201886:	4314                	lw	a3,0(a4)
		b->next = cur->next->next;
ffffffffc0201888:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b) {
ffffffffc020188a:	00469793          	slli	a5,a3,0x4
ffffffffc020188e:	97ba                	add	a5,a5,a4
ffffffffc0201890:	fcf416e3          	bne	s0,a5,ffffffffc020185c <slob_free+0x4a>
		cur->units += b->units;
ffffffffc0201894:	401c                	lw	a5,0(s0)
		cur->next = b->next;
ffffffffc0201896:	640c                	ld	a1,8(s0)
	slobfree = cur;
ffffffffc0201898:	e218                	sd	a4,0(a2)
		cur->units += b->units;
ffffffffc020189a:	9ebd                	addw	a3,a3,a5
ffffffffc020189c:	c314                	sw	a3,0(a4)
		cur->next = b->next;
ffffffffc020189e:	e70c                	sd	a1,8(a4)
ffffffffc02018a0:	d169                	beqz	a0,ffffffffc0201862 <slob_free+0x50>
}
ffffffffc02018a2:	6402                	ld	s0,0(sp)
ffffffffc02018a4:	60a2                	ld	ra,8(sp)
ffffffffc02018a6:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc02018a8:	d17fe06f          	j	ffffffffc02005be <intr_enable>
		b->units = SLOB_UNITS(size);
ffffffffc02018ac:	25bd                	addiw	a1,a1,15
ffffffffc02018ae:	8191                	srli	a1,a1,0x4
ffffffffc02018b0:	c10c                	sw	a1,0(a0)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02018b2:	100027f3          	csrr	a5,sstatus
ffffffffc02018b6:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02018b8:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02018ba:	d7bd                	beqz	a5,ffffffffc0201828 <slob_free+0x16>
        intr_disable();
ffffffffc02018bc:	d09fe0ef          	jal	ra,ffffffffc02005c4 <intr_disable>
        return 1;
ffffffffc02018c0:	4505                	li	a0,1
ffffffffc02018c2:	b79d                	j	ffffffffc0201828 <slob_free+0x16>
ffffffffc02018c4:	8082                	ret

ffffffffc02018c6 <__slob_get_free_pages.constprop.0>:
  struct Page * page = alloc_pages(1 << order);
ffffffffc02018c6:	4785                	li	a5,1
static void* __slob_get_free_pages(gfp_t gfp, int order)
ffffffffc02018c8:	1141                	addi	sp,sp,-16
  struct Page * page = alloc_pages(1 << order);
ffffffffc02018ca:	00a7953b          	sllw	a0,a5,a0
static void* __slob_get_free_pages(gfp_t gfp, int order)
ffffffffc02018ce:	e406                	sd	ra,8(sp)
  struct Page * page = alloc_pages(1 << order);
ffffffffc02018d0:	6f8010ef          	jal	ra,ffffffffc0202fc8 <alloc_pages>
  if(!page)
ffffffffc02018d4:	c91d                	beqz	a0,ffffffffc020190a <__slob_get_free_pages.constprop.0+0x44>
    return page - pages + nbase;
ffffffffc02018d6:	00015697          	auipc	a3,0x15
ffffffffc02018da:	cc26b683          	ld	a3,-830(a3) # ffffffffc0216598 <pages>
ffffffffc02018de:	8d15                	sub	a0,a0,a3
ffffffffc02018e0:	8519                	srai	a0,a0,0x6
ffffffffc02018e2:	00005697          	auipc	a3,0x5
ffffffffc02018e6:	73e6b683          	ld	a3,1854(a3) # ffffffffc0207020 <nbase>
ffffffffc02018ea:	9536                	add	a0,a0,a3
    return KADDR(page2pa(page));
ffffffffc02018ec:	00c51793          	slli	a5,a0,0xc
ffffffffc02018f0:	83b1                	srli	a5,a5,0xc
ffffffffc02018f2:	00015717          	auipc	a4,0x15
ffffffffc02018f6:	c9e73703          	ld	a4,-866(a4) # ffffffffc0216590 <npage>
    return page2ppn(page) << PGSHIFT;
ffffffffc02018fa:	0532                	slli	a0,a0,0xc
    return KADDR(page2pa(page));
ffffffffc02018fc:	00e7fa63          	bgeu	a5,a4,ffffffffc0201910 <__slob_get_free_pages.constprop.0+0x4a>
ffffffffc0201900:	00015697          	auipc	a3,0x15
ffffffffc0201904:	ca86b683          	ld	a3,-856(a3) # ffffffffc02165a8 <va_pa_offset>
ffffffffc0201908:	9536                	add	a0,a0,a3
}
ffffffffc020190a:	60a2                	ld	ra,8(sp)
ffffffffc020190c:	0141                	addi	sp,sp,16
ffffffffc020190e:	8082                	ret
ffffffffc0201910:	86aa                	mv	a3,a0
ffffffffc0201912:	00004617          	auipc	a2,0x4
ffffffffc0201916:	21660613          	addi	a2,a2,534 # ffffffffc0205b28 <commands+0x980>
ffffffffc020191a:	06900593          	li	a1,105
ffffffffc020191e:	00004517          	auipc	a0,0x4
ffffffffc0201922:	1fa50513          	addi	a0,a0,506 # ffffffffc0205b18 <commands+0x970>
ffffffffc0201926:	8a3fe0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc020192a <slob_alloc.constprop.0>:
static void *slob_alloc(size_t size, gfp_t gfp, int align)
ffffffffc020192a:	1101                	addi	sp,sp,-32
ffffffffc020192c:	ec06                	sd	ra,24(sp)
ffffffffc020192e:	e822                	sd	s0,16(sp)
ffffffffc0201930:	e426                	sd	s1,8(sp)
ffffffffc0201932:	e04a                	sd	s2,0(sp)
	assert( (size + SLOB_UNIT) < PAGE_SIZE );
ffffffffc0201934:	01050713          	addi	a4,a0,16
ffffffffc0201938:	6785                	lui	a5,0x1
ffffffffc020193a:	0cf77363          	bgeu	a4,a5,ffffffffc0201a00 <slob_alloc.constprop.0+0xd6>
	int delta = 0, units = SLOB_UNITS(size);
ffffffffc020193e:	00f50493          	addi	s1,a0,15
ffffffffc0201942:	8091                	srli	s1,s1,0x4
ffffffffc0201944:	2481                	sext.w	s1,s1
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201946:	10002673          	csrr	a2,sstatus
ffffffffc020194a:	8a09                	andi	a2,a2,2
ffffffffc020194c:	e25d                	bnez	a2,ffffffffc02019f2 <slob_alloc.constprop.0+0xc8>
	prev = slobfree;
ffffffffc020194e:	00009917          	auipc	s2,0x9
ffffffffc0201952:	70290913          	addi	s2,s2,1794 # ffffffffc020b050 <slobfree>
ffffffffc0201956:	00093683          	ld	a3,0(s2)
	for (cur = prev->next; ; prev = cur, cur = cur->next) {
ffffffffc020195a:	669c                	ld	a5,8(a3)
		if (cur->units >= units + delta) { /* room enough? */
ffffffffc020195c:	4398                	lw	a4,0(a5)
ffffffffc020195e:	08975e63          	bge	a4,s1,ffffffffc02019fa <slob_alloc.constprop.0+0xd0>
		if (cur == slobfree) {
ffffffffc0201962:	00d78b63          	beq	a5,a3,ffffffffc0201978 <slob_alloc.constprop.0+0x4e>
	for (cur = prev->next; ; prev = cur, cur = cur->next) {
ffffffffc0201966:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta) { /* room enough? */
ffffffffc0201968:	4018                	lw	a4,0(s0)
ffffffffc020196a:	02975a63          	bge	a4,s1,ffffffffc020199e <slob_alloc.constprop.0+0x74>
		if (cur == slobfree) {
ffffffffc020196e:	00093683          	ld	a3,0(s2)
ffffffffc0201972:	87a2                	mv	a5,s0
ffffffffc0201974:	fed799e3          	bne	a5,a3,ffffffffc0201966 <slob_alloc.constprop.0+0x3c>
    if (flag) {
ffffffffc0201978:	ee31                	bnez	a2,ffffffffc02019d4 <slob_alloc.constprop.0+0xaa>
			cur = (slob_t *)__slob_get_free_page(gfp);
ffffffffc020197a:	4501                	li	a0,0
ffffffffc020197c:	f4bff0ef          	jal	ra,ffffffffc02018c6 <__slob_get_free_pages.constprop.0>
ffffffffc0201980:	842a                	mv	s0,a0
			if (!cur)
ffffffffc0201982:	cd05                	beqz	a0,ffffffffc02019ba <slob_alloc.constprop.0+0x90>
			slob_free(cur, PAGE_SIZE);
ffffffffc0201984:	6585                	lui	a1,0x1
ffffffffc0201986:	e8dff0ef          	jal	ra,ffffffffc0201812 <slob_free>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020198a:	10002673          	csrr	a2,sstatus
ffffffffc020198e:	8a09                	andi	a2,a2,2
ffffffffc0201990:	ee05                	bnez	a2,ffffffffc02019c8 <slob_alloc.constprop.0+0x9e>
			cur = slobfree;
ffffffffc0201992:	00093783          	ld	a5,0(s2)
	for (cur = prev->next; ; prev = cur, cur = cur->next) {
ffffffffc0201996:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta) { /* room enough? */
ffffffffc0201998:	4018                	lw	a4,0(s0)
ffffffffc020199a:	fc974ae3          	blt	a4,s1,ffffffffc020196e <slob_alloc.constprop.0+0x44>
			if (cur->units == units) /* exact fit? */
ffffffffc020199e:	04e48763          	beq	s1,a4,ffffffffc02019ec <slob_alloc.constprop.0+0xc2>
				prev->next = cur + units;
ffffffffc02019a2:	00449693          	slli	a3,s1,0x4
ffffffffc02019a6:	96a2                	add	a3,a3,s0
ffffffffc02019a8:	e794                	sd	a3,8(a5)
				prev->next->next = cur->next;
ffffffffc02019aa:	640c                	ld	a1,8(s0)
				prev->next->units = cur->units - units;
ffffffffc02019ac:	9f05                	subw	a4,a4,s1
ffffffffc02019ae:	c298                	sw	a4,0(a3)
				prev->next->next = cur->next;
ffffffffc02019b0:	e68c                	sd	a1,8(a3)
				cur->units = units;
ffffffffc02019b2:	c004                	sw	s1,0(s0)
			slobfree = prev;
ffffffffc02019b4:	00f93023          	sd	a5,0(s2)
    if (flag) {
ffffffffc02019b8:	e20d                	bnez	a2,ffffffffc02019da <slob_alloc.constprop.0+0xb0>
}
ffffffffc02019ba:	60e2                	ld	ra,24(sp)
ffffffffc02019bc:	8522                	mv	a0,s0
ffffffffc02019be:	6442                	ld	s0,16(sp)
ffffffffc02019c0:	64a2                	ld	s1,8(sp)
ffffffffc02019c2:	6902                	ld	s2,0(sp)
ffffffffc02019c4:	6105                	addi	sp,sp,32
ffffffffc02019c6:	8082                	ret
        intr_disable();
ffffffffc02019c8:	bfdfe0ef          	jal	ra,ffffffffc02005c4 <intr_disable>
			cur = slobfree;
ffffffffc02019cc:	00093783          	ld	a5,0(s2)
        return 1;
ffffffffc02019d0:	4605                	li	a2,1
ffffffffc02019d2:	b7d1                	j	ffffffffc0201996 <slob_alloc.constprop.0+0x6c>
        intr_enable();
ffffffffc02019d4:	bebfe0ef          	jal	ra,ffffffffc02005be <intr_enable>
ffffffffc02019d8:	b74d                	j	ffffffffc020197a <slob_alloc.constprop.0+0x50>
ffffffffc02019da:	be5fe0ef          	jal	ra,ffffffffc02005be <intr_enable>
}
ffffffffc02019de:	60e2                	ld	ra,24(sp)
ffffffffc02019e0:	8522                	mv	a0,s0
ffffffffc02019e2:	6442                	ld	s0,16(sp)
ffffffffc02019e4:	64a2                	ld	s1,8(sp)
ffffffffc02019e6:	6902                	ld	s2,0(sp)
ffffffffc02019e8:	6105                	addi	sp,sp,32
ffffffffc02019ea:	8082                	ret
				prev->next = cur->next; /* unlink */
ffffffffc02019ec:	6418                	ld	a4,8(s0)
ffffffffc02019ee:	e798                	sd	a4,8(a5)
ffffffffc02019f0:	b7d1                	j	ffffffffc02019b4 <slob_alloc.constprop.0+0x8a>
        intr_disable();
ffffffffc02019f2:	bd3fe0ef          	jal	ra,ffffffffc02005c4 <intr_disable>
        return 1;
ffffffffc02019f6:	4605                	li	a2,1
ffffffffc02019f8:	bf99                	j	ffffffffc020194e <slob_alloc.constprop.0+0x24>
		if (cur->units >= units + delta) { /* room enough? */
ffffffffc02019fa:	843e                	mv	s0,a5
ffffffffc02019fc:	87b6                	mv	a5,a3
ffffffffc02019fe:	b745                	j	ffffffffc020199e <slob_alloc.constprop.0+0x74>
	assert( (size + SLOB_UNIT) < PAGE_SIZE );
ffffffffc0201a00:	00004697          	auipc	a3,0x4
ffffffffc0201a04:	48868693          	addi	a3,a3,1160 # ffffffffc0205e88 <commands+0xce0>
ffffffffc0201a08:	00004617          	auipc	a2,0x4
ffffffffc0201a0c:	ec860613          	addi	a2,a2,-312 # ffffffffc02058d0 <commands+0x728>
ffffffffc0201a10:	06300593          	li	a1,99
ffffffffc0201a14:	00004517          	auipc	a0,0x4
ffffffffc0201a18:	49450513          	addi	a0,a0,1172 # ffffffffc0205ea8 <commands+0xd00>
ffffffffc0201a1c:	facfe0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc0201a20 <kmalloc_init>:
slob_init(void) {
  cprintf("use SLOB allocator\n");
}

inline void 
kmalloc_init(void) {
ffffffffc0201a20:	1141                	addi	sp,sp,-16
  cprintf("use SLOB allocator\n");
ffffffffc0201a22:	00004517          	auipc	a0,0x4
ffffffffc0201a26:	49e50513          	addi	a0,a0,1182 # ffffffffc0205ec0 <commands+0xd18>
kmalloc_init(void) {
ffffffffc0201a2a:	e406                	sd	ra,8(sp)
  cprintf("use SLOB allocator\n");
ffffffffc0201a2c:	ea0fe0ef          	jal	ra,ffffffffc02000cc <cprintf>
    slob_init();
    cprintf("kmalloc_init() succeeded!\n");
}
ffffffffc0201a30:	60a2                	ld	ra,8(sp)
    cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201a32:	00004517          	auipc	a0,0x4
ffffffffc0201a36:	4a650513          	addi	a0,a0,1190 # ffffffffc0205ed8 <commands+0xd30>
}
ffffffffc0201a3a:	0141                	addi	sp,sp,16
    cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201a3c:	e90fe06f          	j	ffffffffc02000cc <cprintf>

ffffffffc0201a40 <kmalloc>:
	return 0;
}

void *
kmalloc(size_t size)
{
ffffffffc0201a40:	1101                	addi	sp,sp,-32
ffffffffc0201a42:	e04a                	sd	s2,0(sp)
	if (size < PAGE_SIZE - SLOB_UNIT) {
ffffffffc0201a44:	6905                	lui	s2,0x1
{
ffffffffc0201a46:	e822                	sd	s0,16(sp)
ffffffffc0201a48:	ec06                	sd	ra,24(sp)
ffffffffc0201a4a:	e426                	sd	s1,8(sp)
	if (size < PAGE_SIZE - SLOB_UNIT) {
ffffffffc0201a4c:	fef90793          	addi	a5,s2,-17 # fef <kern_entry-0xffffffffc01ff011>
{
ffffffffc0201a50:	842a                	mv	s0,a0
	if (size < PAGE_SIZE - SLOB_UNIT) {
ffffffffc0201a52:	04a7f963          	bgeu	a5,a0,ffffffffc0201aa4 <kmalloc+0x64>
	bb = slob_alloc(sizeof(bigblock_t), gfp, 0);
ffffffffc0201a56:	4561                	li	a0,24
ffffffffc0201a58:	ed3ff0ef          	jal	ra,ffffffffc020192a <slob_alloc.constprop.0>
ffffffffc0201a5c:	84aa                	mv	s1,a0
	if (!bb)
ffffffffc0201a5e:	c929                	beqz	a0,ffffffffc0201ab0 <kmalloc+0x70>
	bb->order = find_order(size);
ffffffffc0201a60:	0004079b          	sext.w	a5,s0
	int order = 0;
ffffffffc0201a64:	4501                	li	a0,0
	for ( ; size > 4096 ; size >>=1)
ffffffffc0201a66:	00f95763          	bge	s2,a5,ffffffffc0201a74 <kmalloc+0x34>
ffffffffc0201a6a:	6705                	lui	a4,0x1
ffffffffc0201a6c:	8785                	srai	a5,a5,0x1
		order++;
ffffffffc0201a6e:	2505                	addiw	a0,a0,1
	for ( ; size > 4096 ; size >>=1)
ffffffffc0201a70:	fef74ee3          	blt	a4,a5,ffffffffc0201a6c <kmalloc+0x2c>
	bb->order = find_order(size);
ffffffffc0201a74:	c088                	sw	a0,0(s1)
	bb->pages = (void *)__slob_get_free_pages(gfp, bb->order);
ffffffffc0201a76:	e51ff0ef          	jal	ra,ffffffffc02018c6 <__slob_get_free_pages.constprop.0>
ffffffffc0201a7a:	e488                	sd	a0,8(s1)
ffffffffc0201a7c:	842a                	mv	s0,a0
	if (bb->pages) {
ffffffffc0201a7e:	c525                	beqz	a0,ffffffffc0201ae6 <kmalloc+0xa6>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201a80:	100027f3          	csrr	a5,sstatus
ffffffffc0201a84:	8b89                	andi	a5,a5,2
ffffffffc0201a86:	ef8d                	bnez	a5,ffffffffc0201ac0 <kmalloc+0x80>
		bb->next = bigblocks;
ffffffffc0201a88:	00015797          	auipc	a5,0x15
ffffffffc0201a8c:	ad878793          	addi	a5,a5,-1320 # ffffffffc0216560 <bigblocks>
ffffffffc0201a90:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0201a92:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0201a94:	e898                	sd	a4,16(s1)
  return __kmalloc(size, 0);
}
ffffffffc0201a96:	60e2                	ld	ra,24(sp)
ffffffffc0201a98:	8522                	mv	a0,s0
ffffffffc0201a9a:	6442                	ld	s0,16(sp)
ffffffffc0201a9c:	64a2                	ld	s1,8(sp)
ffffffffc0201a9e:	6902                	ld	s2,0(sp)
ffffffffc0201aa0:	6105                	addi	sp,sp,32
ffffffffc0201aa2:	8082                	ret
		m = slob_alloc(size + SLOB_UNIT, gfp, 0);
ffffffffc0201aa4:	0541                	addi	a0,a0,16
ffffffffc0201aa6:	e85ff0ef          	jal	ra,ffffffffc020192a <slob_alloc.constprop.0>
		return m ? (void *)(m + 1) : 0;
ffffffffc0201aaa:	01050413          	addi	s0,a0,16
ffffffffc0201aae:	f565                	bnez	a0,ffffffffc0201a96 <kmalloc+0x56>
ffffffffc0201ab0:	4401                	li	s0,0
}
ffffffffc0201ab2:	60e2                	ld	ra,24(sp)
ffffffffc0201ab4:	8522                	mv	a0,s0
ffffffffc0201ab6:	6442                	ld	s0,16(sp)
ffffffffc0201ab8:	64a2                	ld	s1,8(sp)
ffffffffc0201aba:	6902                	ld	s2,0(sp)
ffffffffc0201abc:	6105                	addi	sp,sp,32
ffffffffc0201abe:	8082                	ret
        intr_disable();
ffffffffc0201ac0:	b05fe0ef          	jal	ra,ffffffffc02005c4 <intr_disable>
		bb->next = bigblocks;
ffffffffc0201ac4:	00015797          	auipc	a5,0x15
ffffffffc0201ac8:	a9c78793          	addi	a5,a5,-1380 # ffffffffc0216560 <bigblocks>
ffffffffc0201acc:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0201ace:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0201ad0:	e898                	sd	a4,16(s1)
        intr_enable();
ffffffffc0201ad2:	aedfe0ef          	jal	ra,ffffffffc02005be <intr_enable>
		return bb->pages;
ffffffffc0201ad6:	6480                	ld	s0,8(s1)
}
ffffffffc0201ad8:	60e2                	ld	ra,24(sp)
ffffffffc0201ada:	64a2                	ld	s1,8(sp)
ffffffffc0201adc:	8522                	mv	a0,s0
ffffffffc0201ade:	6442                	ld	s0,16(sp)
ffffffffc0201ae0:	6902                	ld	s2,0(sp)
ffffffffc0201ae2:	6105                	addi	sp,sp,32
ffffffffc0201ae4:	8082                	ret
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0201ae6:	45e1                	li	a1,24
ffffffffc0201ae8:	8526                	mv	a0,s1
ffffffffc0201aea:	d29ff0ef          	jal	ra,ffffffffc0201812 <slob_free>
  return __kmalloc(size, 0);
ffffffffc0201aee:	b765                	j	ffffffffc0201a96 <kmalloc+0x56>

ffffffffc0201af0 <kfree>:
void kfree(void *block)
{
	bigblock_t *bb, **last = &bigblocks;
	unsigned long flags;

	if (!block)
ffffffffc0201af0:	c169                	beqz	a0,ffffffffc0201bb2 <kfree+0xc2>
{
ffffffffc0201af2:	1101                	addi	sp,sp,-32
ffffffffc0201af4:	e822                	sd	s0,16(sp)
ffffffffc0201af6:	ec06                	sd	ra,24(sp)
ffffffffc0201af8:	e426                	sd	s1,8(sp)
		return;

	if (!((unsigned long)block & (PAGE_SIZE-1))) {
ffffffffc0201afa:	03451793          	slli	a5,a0,0x34
ffffffffc0201afe:	842a                	mv	s0,a0
ffffffffc0201b00:	e3d9                	bnez	a5,ffffffffc0201b86 <kfree+0x96>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201b02:	100027f3          	csrr	a5,sstatus
ffffffffc0201b06:	8b89                	andi	a5,a5,2
ffffffffc0201b08:	e7d9                	bnez	a5,ffffffffc0201b96 <kfree+0xa6>
		/* might be on the big block list */
		spin_lock_irqsave(&block_lock, flags);
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next) {
ffffffffc0201b0a:	00015797          	auipc	a5,0x15
ffffffffc0201b0e:	a567b783          	ld	a5,-1450(a5) # ffffffffc0216560 <bigblocks>
    return 0;
ffffffffc0201b12:	4601                	li	a2,0
ffffffffc0201b14:	cbad                	beqz	a5,ffffffffc0201b86 <kfree+0x96>
	bigblock_t *bb, **last = &bigblocks;
ffffffffc0201b16:	00015697          	auipc	a3,0x15
ffffffffc0201b1a:	a4a68693          	addi	a3,a3,-1462 # ffffffffc0216560 <bigblocks>
ffffffffc0201b1e:	a021                	j	ffffffffc0201b26 <kfree+0x36>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next) {
ffffffffc0201b20:	01048693          	addi	a3,s1,16
ffffffffc0201b24:	c3a5                	beqz	a5,ffffffffc0201b84 <kfree+0x94>
			if (bb->pages == block) {
ffffffffc0201b26:	6798                	ld	a4,8(a5)
ffffffffc0201b28:	84be                	mv	s1,a5
				*last = bb->next;
ffffffffc0201b2a:	6b9c                	ld	a5,16(a5)
			if (bb->pages == block) {
ffffffffc0201b2c:	fe871ae3          	bne	a4,s0,ffffffffc0201b20 <kfree+0x30>
				*last = bb->next;
ffffffffc0201b30:	e29c                	sd	a5,0(a3)
    if (flag) {
ffffffffc0201b32:	ee2d                	bnez	a2,ffffffffc0201bac <kfree+0xbc>
    return pa2page(PADDR(kva));
ffffffffc0201b34:	c02007b7          	lui	a5,0xc0200
				spin_unlock_irqrestore(&block_lock, flags);
				__slob_free_pages((unsigned long)block, bb->order);
ffffffffc0201b38:	4098                	lw	a4,0(s1)
ffffffffc0201b3a:	08f46963          	bltu	s0,a5,ffffffffc0201bcc <kfree+0xdc>
ffffffffc0201b3e:	00015697          	auipc	a3,0x15
ffffffffc0201b42:	a6a6b683          	ld	a3,-1430(a3) # ffffffffc02165a8 <va_pa_offset>
ffffffffc0201b46:	8c15                	sub	s0,s0,a3
    if (PPN(pa) >= npage) {
ffffffffc0201b48:	8031                	srli	s0,s0,0xc
ffffffffc0201b4a:	00015797          	auipc	a5,0x15
ffffffffc0201b4e:	a467b783          	ld	a5,-1466(a5) # ffffffffc0216590 <npage>
ffffffffc0201b52:	06f47163          	bgeu	s0,a5,ffffffffc0201bb4 <kfree+0xc4>
    return &pages[PPN(pa) - nbase];
ffffffffc0201b56:	00005517          	auipc	a0,0x5
ffffffffc0201b5a:	4ca53503          	ld	a0,1226(a0) # ffffffffc0207020 <nbase>
ffffffffc0201b5e:	8c09                	sub	s0,s0,a0
ffffffffc0201b60:	041a                	slli	s0,s0,0x6
  free_pages(kva2page(kva), 1 << order);
ffffffffc0201b62:	00015517          	auipc	a0,0x15
ffffffffc0201b66:	a3653503          	ld	a0,-1482(a0) # ffffffffc0216598 <pages>
ffffffffc0201b6a:	4585                	li	a1,1
ffffffffc0201b6c:	9522                	add	a0,a0,s0
ffffffffc0201b6e:	00e595bb          	sllw	a1,a1,a4
ffffffffc0201b72:	4e8010ef          	jal	ra,ffffffffc020305a <free_pages>
		spin_unlock_irqrestore(&block_lock, flags);
	}

	slob_free((slob_t *)block - 1, 0);
	return;
}
ffffffffc0201b76:	6442                	ld	s0,16(sp)
ffffffffc0201b78:	60e2                	ld	ra,24(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201b7a:	8526                	mv	a0,s1
}
ffffffffc0201b7c:	64a2                	ld	s1,8(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201b7e:	45e1                	li	a1,24
}
ffffffffc0201b80:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201b82:	b941                	j	ffffffffc0201812 <slob_free>
ffffffffc0201b84:	e20d                	bnez	a2,ffffffffc0201ba6 <kfree+0xb6>
ffffffffc0201b86:	ff040513          	addi	a0,s0,-16
}
ffffffffc0201b8a:	6442                	ld	s0,16(sp)
ffffffffc0201b8c:	60e2                	ld	ra,24(sp)
ffffffffc0201b8e:	64a2                	ld	s1,8(sp)
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201b90:	4581                	li	a1,0
}
ffffffffc0201b92:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201b94:	b9bd                	j	ffffffffc0201812 <slob_free>
        intr_disable();
ffffffffc0201b96:	a2ffe0ef          	jal	ra,ffffffffc02005c4 <intr_disable>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next) {
ffffffffc0201b9a:	00015797          	auipc	a5,0x15
ffffffffc0201b9e:	9c67b783          	ld	a5,-1594(a5) # ffffffffc0216560 <bigblocks>
        return 1;
ffffffffc0201ba2:	4605                	li	a2,1
ffffffffc0201ba4:	fbad                	bnez	a5,ffffffffc0201b16 <kfree+0x26>
        intr_enable();
ffffffffc0201ba6:	a19fe0ef          	jal	ra,ffffffffc02005be <intr_enable>
ffffffffc0201baa:	bff1                	j	ffffffffc0201b86 <kfree+0x96>
ffffffffc0201bac:	a13fe0ef          	jal	ra,ffffffffc02005be <intr_enable>
ffffffffc0201bb0:	b751                	j	ffffffffc0201b34 <kfree+0x44>
ffffffffc0201bb2:	8082                	ret
        panic("pa2page called with invalid pa");
ffffffffc0201bb4:	00004617          	auipc	a2,0x4
ffffffffc0201bb8:	f4460613          	addi	a2,a2,-188 # ffffffffc0205af8 <commands+0x950>
ffffffffc0201bbc:	06200593          	li	a1,98
ffffffffc0201bc0:	00004517          	auipc	a0,0x4
ffffffffc0201bc4:	f5850513          	addi	a0,a0,-168 # ffffffffc0205b18 <commands+0x970>
ffffffffc0201bc8:	e00fe0ef          	jal	ra,ffffffffc02001c8 <__panic>
    return pa2page(PADDR(kva));
ffffffffc0201bcc:	86a2                	mv	a3,s0
ffffffffc0201bce:	00004617          	auipc	a2,0x4
ffffffffc0201bd2:	32a60613          	addi	a2,a2,810 # ffffffffc0205ef8 <commands+0xd50>
ffffffffc0201bd6:	06e00593          	li	a1,110
ffffffffc0201bda:	00004517          	auipc	a0,0x4
ffffffffc0201bde:	f3e50513          	addi	a0,a0,-194 # ffffffffc0205b18 <commands+0x970>
ffffffffc0201be2:	de6fe0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc0201be6 <pa2page.part.0>:
pa2page(uintptr_t pa) {
ffffffffc0201be6:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc0201be8:	00004617          	auipc	a2,0x4
ffffffffc0201bec:	f1060613          	addi	a2,a2,-240 # ffffffffc0205af8 <commands+0x950>
ffffffffc0201bf0:	06200593          	li	a1,98
ffffffffc0201bf4:	00004517          	auipc	a0,0x4
ffffffffc0201bf8:	f2450513          	addi	a0,a0,-220 # ffffffffc0205b18 <commands+0x970>
pa2page(uintptr_t pa) {
ffffffffc0201bfc:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc0201bfe:	dcafe0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc0201c02 <swap_init>:

static void check_swap(void);

int
swap_init(void)
{
ffffffffc0201c02:	7135                	addi	sp,sp,-160
ffffffffc0201c04:	ed06                	sd	ra,152(sp)
ffffffffc0201c06:	e922                	sd	s0,144(sp)
ffffffffc0201c08:	e526                	sd	s1,136(sp)
ffffffffc0201c0a:	e14a                	sd	s2,128(sp)
ffffffffc0201c0c:	fcce                	sd	s3,120(sp)
ffffffffc0201c0e:	f8d2                	sd	s4,112(sp)
ffffffffc0201c10:	f4d6                	sd	s5,104(sp)
ffffffffc0201c12:	f0da                	sd	s6,96(sp)
ffffffffc0201c14:	ecde                	sd	s7,88(sp)
ffffffffc0201c16:	e8e2                	sd	s8,80(sp)
ffffffffc0201c18:	e4e6                	sd	s9,72(sp)
ffffffffc0201c1a:	e0ea                	sd	s10,64(sp)
ffffffffc0201c1c:	fc6e                	sd	s11,56(sp)
     swapfs_init();
ffffffffc0201c1e:	4c6020ef          	jal	ra,ffffffffc02040e4 <swapfs_init>
     // if (!(1024 <= max_swap_offset && max_swap_offset < MAX_SWAP_OFFSET_LIMIT))
     // {
     //      panic("bad max_swap_offset %08x.\n", max_swap_offset);
     // }
     // Since the IDE is faked, it can only store 7 pages at most to pass the test
     if (!(7 <= max_swap_offset &&
ffffffffc0201c22:	00015697          	auipc	a3,0x15
ffffffffc0201c26:	9466b683          	ld	a3,-1722(a3) # ffffffffc0216568 <max_swap_offset>
ffffffffc0201c2a:	010007b7          	lui	a5,0x1000
ffffffffc0201c2e:	ff968713          	addi	a4,a3,-7
ffffffffc0201c32:	17e1                	addi	a5,a5,-8
ffffffffc0201c34:	42e7e063          	bltu	a5,a4,ffffffffc0202054 <swap_init+0x452>
        max_swap_offset < MAX_SWAP_OFFSET_LIMIT)) {
        panic("bad max_swap_offset %08x.\n", max_swap_offset);
     }

     sm = &swap_manager_fifo;
ffffffffc0201c38:	00009797          	auipc	a5,0x9
ffffffffc0201c3c:	3c878793          	addi	a5,a5,968 # ffffffffc020b000 <swap_manager_fifo>
     int r = sm->init();
ffffffffc0201c40:	6798                	ld	a4,8(a5)
     sm = &swap_manager_fifo;
ffffffffc0201c42:	00015b97          	auipc	s7,0x15
ffffffffc0201c46:	92eb8b93          	addi	s7,s7,-1746 # ffffffffc0216570 <sm>
ffffffffc0201c4a:	00fbb023          	sd	a5,0(s7)
     int r = sm->init();
ffffffffc0201c4e:	9702                	jalr	a4
ffffffffc0201c50:	892a                	mv	s2,a0
     
     if (r == 0)
ffffffffc0201c52:	c10d                	beqz	a0,ffffffffc0201c74 <swap_init+0x72>
          cprintf("SWAP: manager = %s\n", sm->name);
          check_swap();
     }

     return r;
}
ffffffffc0201c54:	60ea                	ld	ra,152(sp)
ffffffffc0201c56:	644a                	ld	s0,144(sp)
ffffffffc0201c58:	64aa                	ld	s1,136(sp)
ffffffffc0201c5a:	79e6                	ld	s3,120(sp)
ffffffffc0201c5c:	7a46                	ld	s4,112(sp)
ffffffffc0201c5e:	7aa6                	ld	s5,104(sp)
ffffffffc0201c60:	7b06                	ld	s6,96(sp)
ffffffffc0201c62:	6be6                	ld	s7,88(sp)
ffffffffc0201c64:	6c46                	ld	s8,80(sp)
ffffffffc0201c66:	6ca6                	ld	s9,72(sp)
ffffffffc0201c68:	6d06                	ld	s10,64(sp)
ffffffffc0201c6a:	7de2                	ld	s11,56(sp)
ffffffffc0201c6c:	854a                	mv	a0,s2
ffffffffc0201c6e:	690a                	ld	s2,128(sp)
ffffffffc0201c70:	610d                	addi	sp,sp,160
ffffffffc0201c72:	8082                	ret
          cprintf("SWAP: manager = %s\n", sm->name);
ffffffffc0201c74:	000bb783          	ld	a5,0(s7)
ffffffffc0201c78:	00004517          	auipc	a0,0x4
ffffffffc0201c7c:	2d850513          	addi	a0,a0,728 # ffffffffc0205f50 <commands+0xda8>
    return listelm->next;
ffffffffc0201c80:	00011417          	auipc	s0,0x11
ffffffffc0201c84:	88040413          	addi	s0,s0,-1920 # ffffffffc0212500 <free_area>
ffffffffc0201c88:	638c                	ld	a1,0(a5)
          swap_init_ok = 1;
ffffffffc0201c8a:	4785                	li	a5,1
ffffffffc0201c8c:	00015717          	auipc	a4,0x15
ffffffffc0201c90:	8ef72623          	sw	a5,-1812(a4) # ffffffffc0216578 <swap_init_ok>
          cprintf("SWAP: manager = %s\n", sm->name);
ffffffffc0201c94:	c38fe0ef          	jal	ra,ffffffffc02000cc <cprintf>
ffffffffc0201c98:	641c                	ld	a5,8(s0)

static void
check_swap(void)
{
    //backup mem env
     int ret, count = 0, total = 0, i;
ffffffffc0201c9a:	4d01                	li	s10,0
ffffffffc0201c9c:	4d81                	li	s11,0
     list_entry_t *le = &free_list;
     while ((le = list_next(le)) != &free_list) {
ffffffffc0201c9e:	32878b63          	beq	a5,s0,ffffffffc0201fd4 <swap_init+0x3d2>
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0201ca2:	ff07b703          	ld	a4,-16(a5)
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0201ca6:	8b09                	andi	a4,a4,2
ffffffffc0201ca8:	32070863          	beqz	a4,ffffffffc0201fd8 <swap_init+0x3d6>
        count ++, total += p->property;
ffffffffc0201cac:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201cb0:	679c                	ld	a5,8(a5)
ffffffffc0201cb2:	2d85                	addiw	s11,s11,1
ffffffffc0201cb4:	01a70d3b          	addw	s10,a4,s10
     while ((le = list_next(le)) != &free_list) {
ffffffffc0201cb8:	fe8795e3          	bne	a5,s0,ffffffffc0201ca2 <swap_init+0xa0>
     }
     assert(total == nr_free_pages());
ffffffffc0201cbc:	84ea                	mv	s1,s10
ffffffffc0201cbe:	3dc010ef          	jal	ra,ffffffffc020309a <nr_free_pages>
ffffffffc0201cc2:	42951163          	bne	a0,s1,ffffffffc02020e4 <swap_init+0x4e2>
     cprintf("BEGIN check_swap: count %d, total %d\n",count,total);
ffffffffc0201cc6:	866a                	mv	a2,s10
ffffffffc0201cc8:	85ee                	mv	a1,s11
ffffffffc0201cca:	00004517          	auipc	a0,0x4
ffffffffc0201cce:	2ce50513          	addi	a0,a0,718 # ffffffffc0205f98 <commands+0xdf0>
ffffffffc0201cd2:	bfafe0ef          	jal	ra,ffffffffc02000cc <cprintf>
     
     //now we set the phy pages env     
     struct mm_struct *mm = mm_create();
ffffffffc0201cd6:	ec1fe0ef          	jal	ra,ffffffffc0200b96 <mm_create>
ffffffffc0201cda:	8aaa                	mv	s5,a0
     assert(mm != NULL);
ffffffffc0201cdc:	46050463          	beqz	a0,ffffffffc0202144 <swap_init+0x542>

     extern struct mm_struct *check_mm_struct;
     assert(check_mm_struct == NULL);
ffffffffc0201ce0:	00015797          	auipc	a5,0x15
ffffffffc0201ce4:	87078793          	addi	a5,a5,-1936 # ffffffffc0216550 <check_mm_struct>
ffffffffc0201ce8:	6398                	ld	a4,0(a5)
ffffffffc0201cea:	3c071d63          	bnez	a4,ffffffffc02020c4 <swap_init+0x4c2>

     check_mm_struct = mm;

     pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc0201cee:	00015717          	auipc	a4,0x15
ffffffffc0201cf2:	89a70713          	addi	a4,a4,-1894 # ffffffffc0216588 <boot_pgdir>
ffffffffc0201cf6:	00073b03          	ld	s6,0(a4)
     check_mm_struct = mm;
ffffffffc0201cfa:	e388                	sd	a0,0(a5)
     assert(pgdir[0] == 0);
ffffffffc0201cfc:	000b3783          	ld	a5,0(s6)
     pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc0201d00:	01653c23          	sd	s6,24(a0)
     assert(pgdir[0] == 0);
ffffffffc0201d04:	42079063          	bnez	a5,ffffffffc0202124 <swap_init+0x522>

     struct vma_struct *vma = vma_create(BEING_CHECK_VALID_VADDR, CHECK_VALID_VADDR, VM_WRITE | VM_READ);
ffffffffc0201d08:	6599                	lui	a1,0x6
ffffffffc0201d0a:	460d                	li	a2,3
ffffffffc0201d0c:	6505                	lui	a0,0x1
ffffffffc0201d0e:	ed1fe0ef          	jal	ra,ffffffffc0200bde <vma_create>
ffffffffc0201d12:	85aa                	mv	a1,a0
     assert(vma != NULL);
ffffffffc0201d14:	52050463          	beqz	a0,ffffffffc020223c <swap_init+0x63a>

     insert_vma_struct(mm, vma);
ffffffffc0201d18:	8556                	mv	a0,s5
ffffffffc0201d1a:	f33fe0ef          	jal	ra,ffffffffc0200c4c <insert_vma_struct>

     //setup the temp Page Table vaddr 0~4MB
     cprintf("setup Page Table for vaddr 0X1000, so alloc a page\n");
ffffffffc0201d1e:	00004517          	auipc	a0,0x4
ffffffffc0201d22:	2ba50513          	addi	a0,a0,698 # ffffffffc0205fd8 <commands+0xe30>
ffffffffc0201d26:	ba6fe0ef          	jal	ra,ffffffffc02000cc <cprintf>
     pte_t *temp_ptep=NULL;
     temp_ptep = get_pte(mm->pgdir, BEING_CHECK_VALID_VADDR, 1);
ffffffffc0201d2a:	018ab503          	ld	a0,24(s5)
ffffffffc0201d2e:	4605                	li	a2,1
ffffffffc0201d30:	6585                	lui	a1,0x1
ffffffffc0201d32:	3a2010ef          	jal	ra,ffffffffc02030d4 <get_pte>
     assert(temp_ptep!= NULL);
ffffffffc0201d36:	4c050363          	beqz	a0,ffffffffc02021fc <swap_init+0x5fa>
     cprintf("setup Page Table vaddr 0~4MB OVER!\n");
ffffffffc0201d3a:	00004517          	auipc	a0,0x4
ffffffffc0201d3e:	2ee50513          	addi	a0,a0,750 # ffffffffc0206028 <commands+0xe80>
ffffffffc0201d42:	00010497          	auipc	s1,0x10
ffffffffc0201d46:	74e48493          	addi	s1,s1,1870 # ffffffffc0212490 <check_rp>
ffffffffc0201d4a:	b82fe0ef          	jal	ra,ffffffffc02000cc <cprintf>
     
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0201d4e:	00010997          	auipc	s3,0x10
ffffffffc0201d52:	76298993          	addi	s3,s3,1890 # ffffffffc02124b0 <swap_in_seq_no>
     cprintf("setup Page Table vaddr 0~4MB OVER!\n");
ffffffffc0201d56:	8a26                	mv	s4,s1
          check_rp[i] = alloc_page();
ffffffffc0201d58:	4505                	li	a0,1
ffffffffc0201d5a:	26e010ef          	jal	ra,ffffffffc0202fc8 <alloc_pages>
ffffffffc0201d5e:	00aa3023          	sd	a0,0(s4)
          assert(check_rp[i] != NULL );
ffffffffc0201d62:	2c050963          	beqz	a0,ffffffffc0202034 <swap_init+0x432>
ffffffffc0201d66:	651c                	ld	a5,8(a0)
          assert(!PageProperty(check_rp[i]));
ffffffffc0201d68:	8b89                	andi	a5,a5,2
ffffffffc0201d6a:	32079d63          	bnez	a5,ffffffffc02020a4 <swap_init+0x4a2>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0201d6e:	0a21                	addi	s4,s4,8
ffffffffc0201d70:	ff3a14e3          	bne	s4,s3,ffffffffc0201d58 <swap_init+0x156>
     }
     list_entry_t free_list_store = free_list;
ffffffffc0201d74:	601c                	ld	a5,0(s0)
     assert(list_empty(&free_list));
     
     //assert(alloc_page() == NULL);
     
     unsigned int nr_free_store = nr_free;
     nr_free = 0;
ffffffffc0201d76:	00010a17          	auipc	s4,0x10
ffffffffc0201d7a:	71aa0a13          	addi	s4,s4,1818 # ffffffffc0212490 <check_rp>
    elm->prev = elm->next = elm;
ffffffffc0201d7e:	e000                	sd	s0,0(s0)
     list_entry_t free_list_store = free_list;
ffffffffc0201d80:	ec3e                	sd	a5,24(sp)
ffffffffc0201d82:	641c                	ld	a5,8(s0)
ffffffffc0201d84:	e400                	sd	s0,8(s0)
ffffffffc0201d86:	f03e                	sd	a5,32(sp)
     unsigned int nr_free_store = nr_free;
ffffffffc0201d88:	481c                	lw	a5,16(s0)
ffffffffc0201d8a:	f43e                	sd	a5,40(sp)
     nr_free = 0;
ffffffffc0201d8c:	00010797          	auipc	a5,0x10
ffffffffc0201d90:	7807a223          	sw	zero,1924(a5) # ffffffffc0212510 <free_area+0x10>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
        free_pages(check_rp[i],1);
ffffffffc0201d94:	000a3503          	ld	a0,0(s4)
ffffffffc0201d98:	4585                	li	a1,1
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0201d9a:	0a21                	addi	s4,s4,8
        free_pages(check_rp[i],1);
ffffffffc0201d9c:	2be010ef          	jal	ra,ffffffffc020305a <free_pages>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0201da0:	ff3a1ae3          	bne	s4,s3,ffffffffc0201d94 <swap_init+0x192>
     }
     assert(nr_free==CHECK_VALID_PHY_PAGE_NUM);
ffffffffc0201da4:	01042a03          	lw	s4,16(s0)
ffffffffc0201da8:	4791                	li	a5,4
ffffffffc0201daa:	42fa1963          	bne	s4,a5,ffffffffc02021dc <swap_init+0x5da>
     
     cprintf("set up init env for check_swap begin!\n");
ffffffffc0201dae:	00004517          	auipc	a0,0x4
ffffffffc0201db2:	30250513          	addi	a0,a0,770 # ffffffffc02060b0 <commands+0xf08>
ffffffffc0201db6:	b16fe0ef          	jal	ra,ffffffffc02000cc <cprintf>
     *(unsigned char *)0x1000 = 0x0a;
ffffffffc0201dba:	6705                	lui	a4,0x1
     //setup initial vir_page<->phy_page environment for page relpacement algorithm 

     
     pgfault_num=0;
ffffffffc0201dbc:	00014797          	auipc	a5,0x14
ffffffffc0201dc0:	7807ae23          	sw	zero,1948(a5) # ffffffffc0216558 <pgfault_num>
     *(unsigned char *)0x1000 = 0x0a;
ffffffffc0201dc4:	4629                	li	a2,10
ffffffffc0201dc6:	00c70023          	sb	a2,0(a4) # 1000 <kern_entry-0xffffffffc01ff000>
     assert(pgfault_num==1);
ffffffffc0201dca:	00014697          	auipc	a3,0x14
ffffffffc0201dce:	78e6a683          	lw	a3,1934(a3) # ffffffffc0216558 <pgfault_num>
ffffffffc0201dd2:	4585                	li	a1,1
ffffffffc0201dd4:	00014797          	auipc	a5,0x14
ffffffffc0201dd8:	78478793          	addi	a5,a5,1924 # ffffffffc0216558 <pgfault_num>
ffffffffc0201ddc:	54b69063          	bne	a3,a1,ffffffffc020231c <swap_init+0x71a>
     *(unsigned char *)0x1010 = 0x0a;
ffffffffc0201de0:	00c70823          	sb	a2,16(a4)
     assert(pgfault_num==1);
ffffffffc0201de4:	4398                	lw	a4,0(a5)
ffffffffc0201de6:	2701                	sext.w	a4,a4
ffffffffc0201de8:	3cd71a63          	bne	a4,a3,ffffffffc02021bc <swap_init+0x5ba>
     *(unsigned char *)0x2000 = 0x0b;
ffffffffc0201dec:	6689                	lui	a3,0x2
ffffffffc0201dee:	462d                	li	a2,11
ffffffffc0201df0:	00c68023          	sb	a2,0(a3) # 2000 <kern_entry-0xffffffffc01fe000>
     assert(pgfault_num==2);
ffffffffc0201df4:	4398                	lw	a4,0(a5)
ffffffffc0201df6:	4589                	li	a1,2
ffffffffc0201df8:	2701                	sext.w	a4,a4
ffffffffc0201dfa:	4ab71163          	bne	a4,a1,ffffffffc020229c <swap_init+0x69a>
     *(unsigned char *)0x2010 = 0x0b;
ffffffffc0201dfe:	00c68823          	sb	a2,16(a3)
     assert(pgfault_num==2);
ffffffffc0201e02:	4394                	lw	a3,0(a5)
ffffffffc0201e04:	2681                	sext.w	a3,a3
ffffffffc0201e06:	4ae69b63          	bne	a3,a4,ffffffffc02022bc <swap_init+0x6ba>
     *(unsigned char *)0x3000 = 0x0c;
ffffffffc0201e0a:	668d                	lui	a3,0x3
ffffffffc0201e0c:	4631                	li	a2,12
ffffffffc0201e0e:	00c68023          	sb	a2,0(a3) # 3000 <kern_entry-0xffffffffc01fd000>
     assert(pgfault_num==3);
ffffffffc0201e12:	4398                	lw	a4,0(a5)
ffffffffc0201e14:	458d                	li	a1,3
ffffffffc0201e16:	2701                	sext.w	a4,a4
ffffffffc0201e18:	4cb71263          	bne	a4,a1,ffffffffc02022dc <swap_init+0x6da>
     *(unsigned char *)0x3010 = 0x0c;
ffffffffc0201e1c:	00c68823          	sb	a2,16(a3)
     assert(pgfault_num==3);
ffffffffc0201e20:	4394                	lw	a3,0(a5)
ffffffffc0201e22:	2681                	sext.w	a3,a3
ffffffffc0201e24:	4ce69c63          	bne	a3,a4,ffffffffc02022fc <swap_init+0x6fa>
     *(unsigned char *)0x4000 = 0x0d;
ffffffffc0201e28:	6691                	lui	a3,0x4
ffffffffc0201e2a:	4635                	li	a2,13
ffffffffc0201e2c:	00c68023          	sb	a2,0(a3) # 4000 <kern_entry-0xffffffffc01fc000>
     assert(pgfault_num==4);
ffffffffc0201e30:	4398                	lw	a4,0(a5)
ffffffffc0201e32:	2701                	sext.w	a4,a4
ffffffffc0201e34:	43471463          	bne	a4,s4,ffffffffc020225c <swap_init+0x65a>
     *(unsigned char *)0x4010 = 0x0d;
ffffffffc0201e38:	00c68823          	sb	a2,16(a3)
     assert(pgfault_num==4);
ffffffffc0201e3c:	439c                	lw	a5,0(a5)
ffffffffc0201e3e:	2781                	sext.w	a5,a5
ffffffffc0201e40:	42e79e63          	bne	a5,a4,ffffffffc020227c <swap_init+0x67a>
     
     check_content_set();
     assert( nr_free == 0);         
ffffffffc0201e44:	481c                	lw	a5,16(s0)
ffffffffc0201e46:	2a079f63          	bnez	a5,ffffffffc0202104 <swap_init+0x502>
ffffffffc0201e4a:	00010797          	auipc	a5,0x10
ffffffffc0201e4e:	66678793          	addi	a5,a5,1638 # ffffffffc02124b0 <swap_in_seq_no>
ffffffffc0201e52:	00010717          	auipc	a4,0x10
ffffffffc0201e56:	68670713          	addi	a4,a4,1670 # ffffffffc02124d8 <swap_out_seq_no>
ffffffffc0201e5a:	00010617          	auipc	a2,0x10
ffffffffc0201e5e:	67e60613          	addi	a2,a2,1662 # ffffffffc02124d8 <swap_out_seq_no>
     for(i = 0; i<MAX_SEQ_NO ; i++) 
         swap_out_seq_no[i]=swap_in_seq_no[i]=-1;
ffffffffc0201e62:	56fd                	li	a3,-1
ffffffffc0201e64:	c394                	sw	a3,0(a5)
ffffffffc0201e66:	c314                	sw	a3,0(a4)
     for(i = 0; i<MAX_SEQ_NO ; i++) 
ffffffffc0201e68:	0791                	addi	a5,a5,4
ffffffffc0201e6a:	0711                	addi	a4,a4,4
ffffffffc0201e6c:	fec79ce3          	bne	a5,a2,ffffffffc0201e64 <swap_init+0x262>
ffffffffc0201e70:	00010717          	auipc	a4,0x10
ffffffffc0201e74:	60070713          	addi	a4,a4,1536 # ffffffffc0212470 <check_ptep>
ffffffffc0201e78:	00010697          	auipc	a3,0x10
ffffffffc0201e7c:	61868693          	addi	a3,a3,1560 # ffffffffc0212490 <check_rp>
ffffffffc0201e80:	6585                	lui	a1,0x1
    if (PPN(pa) >= npage) {
ffffffffc0201e82:	00014c17          	auipc	s8,0x14
ffffffffc0201e86:	70ec0c13          	addi	s8,s8,1806 # ffffffffc0216590 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc0201e8a:	00014c97          	auipc	s9,0x14
ffffffffc0201e8e:	70ec8c93          	addi	s9,s9,1806 # ffffffffc0216598 <pages>
     
     for (i= 0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
         check_ptep[i]=0;
ffffffffc0201e92:	00073023          	sd	zero,0(a4)
         check_ptep[i] = get_pte(pgdir, (i+1)*0x1000, 0);
ffffffffc0201e96:	4601                	li	a2,0
ffffffffc0201e98:	855a                	mv	a0,s6
ffffffffc0201e9a:	e836                	sd	a3,16(sp)
ffffffffc0201e9c:	e42e                	sd	a1,8(sp)
         check_ptep[i]=0;
ffffffffc0201e9e:	e03a                	sd	a4,0(sp)
         check_ptep[i] = get_pte(pgdir, (i+1)*0x1000, 0);
ffffffffc0201ea0:	234010ef          	jal	ra,ffffffffc02030d4 <get_pte>
ffffffffc0201ea4:	6702                	ld	a4,0(sp)
         //cprintf("i %d, check_ptep addr %x, value %x\n", i, check_ptep[i], *check_ptep[i]);
         assert(check_ptep[i] != NULL);
ffffffffc0201ea6:	65a2                	ld	a1,8(sp)
ffffffffc0201ea8:	66c2                	ld	a3,16(sp)
         check_ptep[i] = get_pte(pgdir, (i+1)*0x1000, 0);
ffffffffc0201eaa:	e308                	sd	a0,0(a4)
         assert(check_ptep[i] != NULL);
ffffffffc0201eac:	1c050063          	beqz	a0,ffffffffc020206c <swap_init+0x46a>
         assert(pte2page(*check_ptep[i]) == check_rp[i]);
ffffffffc0201eb0:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V)) {
ffffffffc0201eb2:	0017f613          	andi	a2,a5,1
ffffffffc0201eb6:	1c060b63          	beqz	a2,ffffffffc020208c <swap_init+0x48a>
    if (PPN(pa) >= npage) {
ffffffffc0201eba:	000c3603          	ld	a2,0(s8)
    return pa2page(PTE_ADDR(pte));
ffffffffc0201ebe:	078a                	slli	a5,a5,0x2
ffffffffc0201ec0:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201ec2:	12c7fd63          	bgeu	a5,a2,ffffffffc0201ffc <swap_init+0x3fa>
    return &pages[PPN(pa) - nbase];
ffffffffc0201ec6:	00005617          	auipc	a2,0x5
ffffffffc0201eca:	15a60613          	addi	a2,a2,346 # ffffffffc0207020 <nbase>
ffffffffc0201ece:	00063a03          	ld	s4,0(a2)
ffffffffc0201ed2:	000cb603          	ld	a2,0(s9)
ffffffffc0201ed6:	6288                	ld	a0,0(a3)
ffffffffc0201ed8:	414787b3          	sub	a5,a5,s4
ffffffffc0201edc:	079a                	slli	a5,a5,0x6
ffffffffc0201ede:	97b2                	add	a5,a5,a2
ffffffffc0201ee0:	12f51a63          	bne	a0,a5,ffffffffc0202014 <swap_init+0x412>
     for (i= 0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0201ee4:	6785                	lui	a5,0x1
ffffffffc0201ee6:	95be                	add	a1,a1,a5
ffffffffc0201ee8:	6795                	lui	a5,0x5
ffffffffc0201eea:	0721                	addi	a4,a4,8
ffffffffc0201eec:	06a1                	addi	a3,a3,8
ffffffffc0201eee:	faf592e3          	bne	a1,a5,ffffffffc0201e92 <swap_init+0x290>
         assert((*check_ptep[i] & PTE_V));          
     }
     cprintf("set up init env for check_swap over!\n");
ffffffffc0201ef2:	00004517          	auipc	a0,0x4
ffffffffc0201ef6:	28e50513          	addi	a0,a0,654 # ffffffffc0206180 <commands+0xfd8>
ffffffffc0201efa:	9d2fe0ef          	jal	ra,ffffffffc02000cc <cprintf>
    int ret = sm->check_swap();
ffffffffc0201efe:	000bb783          	ld	a5,0(s7)
ffffffffc0201f02:	7f9c                	ld	a5,56(a5)
ffffffffc0201f04:	9782                	jalr	a5
     // now access the virt pages to test  page relpacement algorithm 
     ret=check_content_access();
     assert(ret==0);
ffffffffc0201f06:	30051b63          	bnez	a0,ffffffffc020221c <swap_init+0x61a>

     nr_free = nr_free_store;
ffffffffc0201f0a:	77a2                	ld	a5,40(sp)
ffffffffc0201f0c:	c81c                	sw	a5,16(s0)
     free_list = free_list_store;
ffffffffc0201f0e:	67e2                	ld	a5,24(sp)
ffffffffc0201f10:	e01c                	sd	a5,0(s0)
ffffffffc0201f12:	7782                	ld	a5,32(sp)
ffffffffc0201f14:	e41c                	sd	a5,8(s0)

     //restore kernel mem env
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
         free_pages(check_rp[i],1);
ffffffffc0201f16:	6088                	ld	a0,0(s1)
ffffffffc0201f18:	4585                	li	a1,1
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0201f1a:	04a1                	addi	s1,s1,8
         free_pages(check_rp[i],1);
ffffffffc0201f1c:	13e010ef          	jal	ra,ffffffffc020305a <free_pages>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0201f20:	ff349be3          	bne	s1,s3,ffffffffc0201f16 <swap_init+0x314>
     } 

     //free_page(pte2page(*temp_ptep));
     
     mm_destroy(mm);
ffffffffc0201f24:	8556                	mv	a0,s5
ffffffffc0201f26:	df7fe0ef          	jal	ra,ffffffffc0200d1c <mm_destroy>

     pde_t *pd1=pgdir,*pd0=page2kva(pde2page(boot_pgdir[0]));
ffffffffc0201f2a:	00014797          	auipc	a5,0x14
ffffffffc0201f2e:	65e78793          	addi	a5,a5,1630 # ffffffffc0216588 <boot_pgdir>
ffffffffc0201f32:	639c                	ld	a5,0(a5)
    if (PPN(pa) >= npage) {
ffffffffc0201f34:	000c3703          	ld	a4,0(s8)
    return pa2page(PDE_ADDR(pde));
ffffffffc0201f38:	639c                	ld	a5,0(a5)
ffffffffc0201f3a:	078a                	slli	a5,a5,0x2
ffffffffc0201f3c:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201f3e:	0ae7fd63          	bgeu	a5,a4,ffffffffc0201ff8 <swap_init+0x3f6>
    return &pages[PPN(pa) - nbase];
ffffffffc0201f42:	414786b3          	sub	a3,a5,s4
ffffffffc0201f46:	069a                	slli	a3,a3,0x6
    return page - pages + nbase;
ffffffffc0201f48:	8699                	srai	a3,a3,0x6
ffffffffc0201f4a:	96d2                	add	a3,a3,s4
    return KADDR(page2pa(page));
ffffffffc0201f4c:	00c69793          	slli	a5,a3,0xc
ffffffffc0201f50:	83b1                	srli	a5,a5,0xc
    return &pages[PPN(pa) - nbase];
ffffffffc0201f52:	000cb503          	ld	a0,0(s9)
    return page2ppn(page) << PGSHIFT;
ffffffffc0201f56:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0201f58:	22e7f663          	bgeu	a5,a4,ffffffffc0202184 <swap_init+0x582>
     free_page(pde2page(pd0[0]));
ffffffffc0201f5c:	00014797          	auipc	a5,0x14
ffffffffc0201f60:	64c7b783          	ld	a5,1612(a5) # ffffffffc02165a8 <va_pa_offset>
ffffffffc0201f64:	96be                	add	a3,a3,a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0201f66:	629c                	ld	a5,0(a3)
ffffffffc0201f68:	078a                	slli	a5,a5,0x2
ffffffffc0201f6a:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201f6c:	08e7f663          	bgeu	a5,a4,ffffffffc0201ff8 <swap_init+0x3f6>
    return &pages[PPN(pa) - nbase];
ffffffffc0201f70:	414787b3          	sub	a5,a5,s4
ffffffffc0201f74:	079a                	slli	a5,a5,0x6
ffffffffc0201f76:	953e                	add	a0,a0,a5
ffffffffc0201f78:	4585                	li	a1,1
ffffffffc0201f7a:	0e0010ef          	jal	ra,ffffffffc020305a <free_pages>
    return pa2page(PDE_ADDR(pde));
ffffffffc0201f7e:	000b3783          	ld	a5,0(s6)
    if (PPN(pa) >= npage) {
ffffffffc0201f82:	000c3703          	ld	a4,0(s8)
    return pa2page(PDE_ADDR(pde));
ffffffffc0201f86:	078a                	slli	a5,a5,0x2
ffffffffc0201f88:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201f8a:	06e7f763          	bgeu	a5,a4,ffffffffc0201ff8 <swap_init+0x3f6>
    return &pages[PPN(pa) - nbase];
ffffffffc0201f8e:	000cb503          	ld	a0,0(s9)
ffffffffc0201f92:	414787b3          	sub	a5,a5,s4
ffffffffc0201f96:	079a                	slli	a5,a5,0x6
     free_page(pde2page(pd1[0]));
ffffffffc0201f98:	4585                	li	a1,1
ffffffffc0201f9a:	953e                	add	a0,a0,a5
ffffffffc0201f9c:	0be010ef          	jal	ra,ffffffffc020305a <free_pages>
     pgdir[0] = 0;
ffffffffc0201fa0:	000b3023          	sd	zero,0(s6)
  asm volatile("sfence.vma");
ffffffffc0201fa4:	12000073          	sfence.vma
    return listelm->next;
ffffffffc0201fa8:	641c                	ld	a5,8(s0)
     flush_tlb();

     le = &free_list;
     while ((le = list_next(le)) != &free_list) {
ffffffffc0201faa:	00878a63          	beq	a5,s0,ffffffffc0201fbe <swap_init+0x3bc>
         struct Page *p = le2page(le, page_link);
         count --, total -= p->property;
ffffffffc0201fae:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201fb2:	679c                	ld	a5,8(a5)
ffffffffc0201fb4:	3dfd                	addiw	s11,s11,-1
ffffffffc0201fb6:	40ed0d3b          	subw	s10,s10,a4
     while ((le = list_next(le)) != &free_list) {
ffffffffc0201fba:	fe879ae3          	bne	a5,s0,ffffffffc0201fae <swap_init+0x3ac>
     }
     assert(count==0);
ffffffffc0201fbe:	1c0d9f63          	bnez	s11,ffffffffc020219c <swap_init+0x59a>
     assert(total==0);
ffffffffc0201fc2:	1a0d1163          	bnez	s10,ffffffffc0202164 <swap_init+0x562>

     cprintf("check_swap() succeeded!\n");
ffffffffc0201fc6:	00004517          	auipc	a0,0x4
ffffffffc0201fca:	20a50513          	addi	a0,a0,522 # ffffffffc02061d0 <commands+0x1028>
ffffffffc0201fce:	8fefe0ef          	jal	ra,ffffffffc02000cc <cprintf>
}
ffffffffc0201fd2:	b149                	j	ffffffffc0201c54 <swap_init+0x52>
     while ((le = list_next(le)) != &free_list) {
ffffffffc0201fd4:	4481                	li	s1,0
ffffffffc0201fd6:	b1e5                	j	ffffffffc0201cbe <swap_init+0xbc>
        assert(PageProperty(p));
ffffffffc0201fd8:	00004697          	auipc	a3,0x4
ffffffffc0201fdc:	f9068693          	addi	a3,a3,-112 # ffffffffc0205f68 <commands+0xdc0>
ffffffffc0201fe0:	00004617          	auipc	a2,0x4
ffffffffc0201fe4:	8f060613          	addi	a2,a2,-1808 # ffffffffc02058d0 <commands+0x728>
ffffffffc0201fe8:	0bd00593          	li	a1,189
ffffffffc0201fec:	00004517          	auipc	a0,0x4
ffffffffc0201ff0:	f5450513          	addi	a0,a0,-172 # ffffffffc0205f40 <commands+0xd98>
ffffffffc0201ff4:	9d4fe0ef          	jal	ra,ffffffffc02001c8 <__panic>
ffffffffc0201ff8:	befff0ef          	jal	ra,ffffffffc0201be6 <pa2page.part.0>
        panic("pa2page called with invalid pa");
ffffffffc0201ffc:	00004617          	auipc	a2,0x4
ffffffffc0202000:	afc60613          	addi	a2,a2,-1284 # ffffffffc0205af8 <commands+0x950>
ffffffffc0202004:	06200593          	li	a1,98
ffffffffc0202008:	00004517          	auipc	a0,0x4
ffffffffc020200c:	b1050513          	addi	a0,a0,-1264 # ffffffffc0205b18 <commands+0x970>
ffffffffc0202010:	9b8fe0ef          	jal	ra,ffffffffc02001c8 <__panic>
         assert(pte2page(*check_ptep[i]) == check_rp[i]);
ffffffffc0202014:	00004697          	auipc	a3,0x4
ffffffffc0202018:	14468693          	addi	a3,a3,324 # ffffffffc0206158 <commands+0xfb0>
ffffffffc020201c:	00004617          	auipc	a2,0x4
ffffffffc0202020:	8b460613          	addi	a2,a2,-1868 # ffffffffc02058d0 <commands+0x728>
ffffffffc0202024:	0fd00593          	li	a1,253
ffffffffc0202028:	00004517          	auipc	a0,0x4
ffffffffc020202c:	f1850513          	addi	a0,a0,-232 # ffffffffc0205f40 <commands+0xd98>
ffffffffc0202030:	998fe0ef          	jal	ra,ffffffffc02001c8 <__panic>
          assert(check_rp[i] != NULL );
ffffffffc0202034:	00004697          	auipc	a3,0x4
ffffffffc0202038:	01c68693          	addi	a3,a3,28 # ffffffffc0206050 <commands+0xea8>
ffffffffc020203c:	00004617          	auipc	a2,0x4
ffffffffc0202040:	89460613          	addi	a2,a2,-1900 # ffffffffc02058d0 <commands+0x728>
ffffffffc0202044:	0dd00593          	li	a1,221
ffffffffc0202048:	00004517          	auipc	a0,0x4
ffffffffc020204c:	ef850513          	addi	a0,a0,-264 # ffffffffc0205f40 <commands+0xd98>
ffffffffc0202050:	978fe0ef          	jal	ra,ffffffffc02001c8 <__panic>
        panic("bad max_swap_offset %08x.\n", max_swap_offset);
ffffffffc0202054:	00004617          	auipc	a2,0x4
ffffffffc0202058:	ecc60613          	addi	a2,a2,-308 # ffffffffc0205f20 <commands+0xd78>
ffffffffc020205c:	02a00593          	li	a1,42
ffffffffc0202060:	00004517          	auipc	a0,0x4
ffffffffc0202064:	ee050513          	addi	a0,a0,-288 # ffffffffc0205f40 <commands+0xd98>
ffffffffc0202068:	960fe0ef          	jal	ra,ffffffffc02001c8 <__panic>
         assert(check_ptep[i] != NULL);
ffffffffc020206c:	00004697          	auipc	a3,0x4
ffffffffc0202070:	0ac68693          	addi	a3,a3,172 # ffffffffc0206118 <commands+0xf70>
ffffffffc0202074:	00004617          	auipc	a2,0x4
ffffffffc0202078:	85c60613          	addi	a2,a2,-1956 # ffffffffc02058d0 <commands+0x728>
ffffffffc020207c:	0fc00593          	li	a1,252
ffffffffc0202080:	00004517          	auipc	a0,0x4
ffffffffc0202084:	ec050513          	addi	a0,a0,-320 # ffffffffc0205f40 <commands+0xd98>
ffffffffc0202088:	940fe0ef          	jal	ra,ffffffffc02001c8 <__panic>
        panic("pte2page called with invalid pte");
ffffffffc020208c:	00004617          	auipc	a2,0x4
ffffffffc0202090:	0a460613          	addi	a2,a2,164 # ffffffffc0206130 <commands+0xf88>
ffffffffc0202094:	07400593          	li	a1,116
ffffffffc0202098:	00004517          	auipc	a0,0x4
ffffffffc020209c:	a8050513          	addi	a0,a0,-1408 # ffffffffc0205b18 <commands+0x970>
ffffffffc02020a0:	928fe0ef          	jal	ra,ffffffffc02001c8 <__panic>
          assert(!PageProperty(check_rp[i]));
ffffffffc02020a4:	00004697          	auipc	a3,0x4
ffffffffc02020a8:	fc468693          	addi	a3,a3,-60 # ffffffffc0206068 <commands+0xec0>
ffffffffc02020ac:	00004617          	auipc	a2,0x4
ffffffffc02020b0:	82460613          	addi	a2,a2,-2012 # ffffffffc02058d0 <commands+0x728>
ffffffffc02020b4:	0de00593          	li	a1,222
ffffffffc02020b8:	00004517          	auipc	a0,0x4
ffffffffc02020bc:	e8850513          	addi	a0,a0,-376 # ffffffffc0205f40 <commands+0xd98>
ffffffffc02020c0:	908fe0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert(check_mm_struct == NULL);
ffffffffc02020c4:	00004697          	auipc	a3,0x4
ffffffffc02020c8:	efc68693          	addi	a3,a3,-260 # ffffffffc0205fc0 <commands+0xe18>
ffffffffc02020cc:	00004617          	auipc	a2,0x4
ffffffffc02020d0:	80460613          	addi	a2,a2,-2044 # ffffffffc02058d0 <commands+0x728>
ffffffffc02020d4:	0c800593          	li	a1,200
ffffffffc02020d8:	00004517          	auipc	a0,0x4
ffffffffc02020dc:	e6850513          	addi	a0,a0,-408 # ffffffffc0205f40 <commands+0xd98>
ffffffffc02020e0:	8e8fe0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert(total == nr_free_pages());
ffffffffc02020e4:	00004697          	auipc	a3,0x4
ffffffffc02020e8:	e9468693          	addi	a3,a3,-364 # ffffffffc0205f78 <commands+0xdd0>
ffffffffc02020ec:	00003617          	auipc	a2,0x3
ffffffffc02020f0:	7e460613          	addi	a2,a2,2020 # ffffffffc02058d0 <commands+0x728>
ffffffffc02020f4:	0c000593          	li	a1,192
ffffffffc02020f8:	00004517          	auipc	a0,0x4
ffffffffc02020fc:	e4850513          	addi	a0,a0,-440 # ffffffffc0205f40 <commands+0xd98>
ffffffffc0202100:	8c8fe0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert( nr_free == 0);         
ffffffffc0202104:	00004697          	auipc	a3,0x4
ffffffffc0202108:	00468693          	addi	a3,a3,4 # ffffffffc0206108 <commands+0xf60>
ffffffffc020210c:	00003617          	auipc	a2,0x3
ffffffffc0202110:	7c460613          	addi	a2,a2,1988 # ffffffffc02058d0 <commands+0x728>
ffffffffc0202114:	0f400593          	li	a1,244
ffffffffc0202118:	00004517          	auipc	a0,0x4
ffffffffc020211c:	e2850513          	addi	a0,a0,-472 # ffffffffc0205f40 <commands+0xd98>
ffffffffc0202120:	8a8fe0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert(pgdir[0] == 0);
ffffffffc0202124:	00004697          	auipc	a3,0x4
ffffffffc0202128:	99468693          	addi	a3,a3,-1644 # ffffffffc0205ab8 <commands+0x910>
ffffffffc020212c:	00003617          	auipc	a2,0x3
ffffffffc0202130:	7a460613          	addi	a2,a2,1956 # ffffffffc02058d0 <commands+0x728>
ffffffffc0202134:	0cd00593          	li	a1,205
ffffffffc0202138:	00004517          	auipc	a0,0x4
ffffffffc020213c:	e0850513          	addi	a0,a0,-504 # ffffffffc0205f40 <commands+0xd98>
ffffffffc0202140:	888fe0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert(mm != NULL);
ffffffffc0202144:	00004697          	auipc	a3,0x4
ffffffffc0202148:	a9468693          	addi	a3,a3,-1388 # ffffffffc0205bd8 <commands+0xa30>
ffffffffc020214c:	00003617          	auipc	a2,0x3
ffffffffc0202150:	78460613          	addi	a2,a2,1924 # ffffffffc02058d0 <commands+0x728>
ffffffffc0202154:	0c500593          	li	a1,197
ffffffffc0202158:	00004517          	auipc	a0,0x4
ffffffffc020215c:	de850513          	addi	a0,a0,-536 # ffffffffc0205f40 <commands+0xd98>
ffffffffc0202160:	868fe0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert(total==0);
ffffffffc0202164:	00004697          	auipc	a3,0x4
ffffffffc0202168:	05c68693          	addi	a3,a3,92 # ffffffffc02061c0 <commands+0x1018>
ffffffffc020216c:	00003617          	auipc	a2,0x3
ffffffffc0202170:	76460613          	addi	a2,a2,1892 # ffffffffc02058d0 <commands+0x728>
ffffffffc0202174:	11d00593          	li	a1,285
ffffffffc0202178:	00004517          	auipc	a0,0x4
ffffffffc020217c:	dc850513          	addi	a0,a0,-568 # ffffffffc0205f40 <commands+0xd98>
ffffffffc0202180:	848fe0ef          	jal	ra,ffffffffc02001c8 <__panic>
    return KADDR(page2pa(page));
ffffffffc0202184:	00004617          	auipc	a2,0x4
ffffffffc0202188:	9a460613          	addi	a2,a2,-1628 # ffffffffc0205b28 <commands+0x980>
ffffffffc020218c:	06900593          	li	a1,105
ffffffffc0202190:	00004517          	auipc	a0,0x4
ffffffffc0202194:	98850513          	addi	a0,a0,-1656 # ffffffffc0205b18 <commands+0x970>
ffffffffc0202198:	830fe0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert(count==0);
ffffffffc020219c:	00004697          	auipc	a3,0x4
ffffffffc02021a0:	01468693          	addi	a3,a3,20 # ffffffffc02061b0 <commands+0x1008>
ffffffffc02021a4:	00003617          	auipc	a2,0x3
ffffffffc02021a8:	72c60613          	addi	a2,a2,1836 # ffffffffc02058d0 <commands+0x728>
ffffffffc02021ac:	11c00593          	li	a1,284
ffffffffc02021b0:	00004517          	auipc	a0,0x4
ffffffffc02021b4:	d9050513          	addi	a0,a0,-624 # ffffffffc0205f40 <commands+0xd98>
ffffffffc02021b8:	810fe0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert(pgfault_num==1);
ffffffffc02021bc:	00004697          	auipc	a3,0x4
ffffffffc02021c0:	f1c68693          	addi	a3,a3,-228 # ffffffffc02060d8 <commands+0xf30>
ffffffffc02021c4:	00003617          	auipc	a2,0x3
ffffffffc02021c8:	70c60613          	addi	a2,a2,1804 # ffffffffc02058d0 <commands+0x728>
ffffffffc02021cc:	09600593          	li	a1,150
ffffffffc02021d0:	00004517          	auipc	a0,0x4
ffffffffc02021d4:	d7050513          	addi	a0,a0,-656 # ffffffffc0205f40 <commands+0xd98>
ffffffffc02021d8:	ff1fd0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert(nr_free==CHECK_VALID_PHY_PAGE_NUM);
ffffffffc02021dc:	00004697          	auipc	a3,0x4
ffffffffc02021e0:	eac68693          	addi	a3,a3,-340 # ffffffffc0206088 <commands+0xee0>
ffffffffc02021e4:	00003617          	auipc	a2,0x3
ffffffffc02021e8:	6ec60613          	addi	a2,a2,1772 # ffffffffc02058d0 <commands+0x728>
ffffffffc02021ec:	0eb00593          	li	a1,235
ffffffffc02021f0:	00004517          	auipc	a0,0x4
ffffffffc02021f4:	d5050513          	addi	a0,a0,-688 # ffffffffc0205f40 <commands+0xd98>
ffffffffc02021f8:	fd1fd0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert(temp_ptep!= NULL);
ffffffffc02021fc:	00004697          	auipc	a3,0x4
ffffffffc0202200:	e1468693          	addi	a3,a3,-492 # ffffffffc0206010 <commands+0xe68>
ffffffffc0202204:	00003617          	auipc	a2,0x3
ffffffffc0202208:	6cc60613          	addi	a2,a2,1740 # ffffffffc02058d0 <commands+0x728>
ffffffffc020220c:	0d800593          	li	a1,216
ffffffffc0202210:	00004517          	auipc	a0,0x4
ffffffffc0202214:	d3050513          	addi	a0,a0,-720 # ffffffffc0205f40 <commands+0xd98>
ffffffffc0202218:	fb1fd0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert(ret==0);
ffffffffc020221c:	00004697          	auipc	a3,0x4
ffffffffc0202220:	f8c68693          	addi	a3,a3,-116 # ffffffffc02061a8 <commands+0x1000>
ffffffffc0202224:	00003617          	auipc	a2,0x3
ffffffffc0202228:	6ac60613          	addi	a2,a2,1708 # ffffffffc02058d0 <commands+0x728>
ffffffffc020222c:	10300593          	li	a1,259
ffffffffc0202230:	00004517          	auipc	a0,0x4
ffffffffc0202234:	d1050513          	addi	a0,a0,-752 # ffffffffc0205f40 <commands+0xd98>
ffffffffc0202238:	f91fd0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert(vma != NULL);
ffffffffc020223c:	00004697          	auipc	a3,0x4
ffffffffc0202240:	97468693          	addi	a3,a3,-1676 # ffffffffc0205bb0 <commands+0xa08>
ffffffffc0202244:	00003617          	auipc	a2,0x3
ffffffffc0202248:	68c60613          	addi	a2,a2,1676 # ffffffffc02058d0 <commands+0x728>
ffffffffc020224c:	0d000593          	li	a1,208
ffffffffc0202250:	00004517          	auipc	a0,0x4
ffffffffc0202254:	cf050513          	addi	a0,a0,-784 # ffffffffc0205f40 <commands+0xd98>
ffffffffc0202258:	f71fd0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert(pgfault_num==4);
ffffffffc020225c:	00004697          	auipc	a3,0x4
ffffffffc0202260:	a7468693          	addi	a3,a3,-1420 # ffffffffc0205cd0 <commands+0xb28>
ffffffffc0202264:	00003617          	auipc	a2,0x3
ffffffffc0202268:	66c60613          	addi	a2,a2,1644 # ffffffffc02058d0 <commands+0x728>
ffffffffc020226c:	0a000593          	li	a1,160
ffffffffc0202270:	00004517          	auipc	a0,0x4
ffffffffc0202274:	cd050513          	addi	a0,a0,-816 # ffffffffc0205f40 <commands+0xd98>
ffffffffc0202278:	f51fd0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert(pgfault_num==4);
ffffffffc020227c:	00004697          	auipc	a3,0x4
ffffffffc0202280:	a5468693          	addi	a3,a3,-1452 # ffffffffc0205cd0 <commands+0xb28>
ffffffffc0202284:	00003617          	auipc	a2,0x3
ffffffffc0202288:	64c60613          	addi	a2,a2,1612 # ffffffffc02058d0 <commands+0x728>
ffffffffc020228c:	0a200593          	li	a1,162
ffffffffc0202290:	00004517          	auipc	a0,0x4
ffffffffc0202294:	cb050513          	addi	a0,a0,-848 # ffffffffc0205f40 <commands+0xd98>
ffffffffc0202298:	f31fd0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert(pgfault_num==2);
ffffffffc020229c:	00004697          	auipc	a3,0x4
ffffffffc02022a0:	e4c68693          	addi	a3,a3,-436 # ffffffffc02060e8 <commands+0xf40>
ffffffffc02022a4:	00003617          	auipc	a2,0x3
ffffffffc02022a8:	62c60613          	addi	a2,a2,1580 # ffffffffc02058d0 <commands+0x728>
ffffffffc02022ac:	09800593          	li	a1,152
ffffffffc02022b0:	00004517          	auipc	a0,0x4
ffffffffc02022b4:	c9050513          	addi	a0,a0,-880 # ffffffffc0205f40 <commands+0xd98>
ffffffffc02022b8:	f11fd0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert(pgfault_num==2);
ffffffffc02022bc:	00004697          	auipc	a3,0x4
ffffffffc02022c0:	e2c68693          	addi	a3,a3,-468 # ffffffffc02060e8 <commands+0xf40>
ffffffffc02022c4:	00003617          	auipc	a2,0x3
ffffffffc02022c8:	60c60613          	addi	a2,a2,1548 # ffffffffc02058d0 <commands+0x728>
ffffffffc02022cc:	09a00593          	li	a1,154
ffffffffc02022d0:	00004517          	auipc	a0,0x4
ffffffffc02022d4:	c7050513          	addi	a0,a0,-912 # ffffffffc0205f40 <commands+0xd98>
ffffffffc02022d8:	ef1fd0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert(pgfault_num==3);
ffffffffc02022dc:	00004697          	auipc	a3,0x4
ffffffffc02022e0:	e1c68693          	addi	a3,a3,-484 # ffffffffc02060f8 <commands+0xf50>
ffffffffc02022e4:	00003617          	auipc	a2,0x3
ffffffffc02022e8:	5ec60613          	addi	a2,a2,1516 # ffffffffc02058d0 <commands+0x728>
ffffffffc02022ec:	09c00593          	li	a1,156
ffffffffc02022f0:	00004517          	auipc	a0,0x4
ffffffffc02022f4:	c5050513          	addi	a0,a0,-944 # ffffffffc0205f40 <commands+0xd98>
ffffffffc02022f8:	ed1fd0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert(pgfault_num==3);
ffffffffc02022fc:	00004697          	auipc	a3,0x4
ffffffffc0202300:	dfc68693          	addi	a3,a3,-516 # ffffffffc02060f8 <commands+0xf50>
ffffffffc0202304:	00003617          	auipc	a2,0x3
ffffffffc0202308:	5cc60613          	addi	a2,a2,1484 # ffffffffc02058d0 <commands+0x728>
ffffffffc020230c:	09e00593          	li	a1,158
ffffffffc0202310:	00004517          	auipc	a0,0x4
ffffffffc0202314:	c3050513          	addi	a0,a0,-976 # ffffffffc0205f40 <commands+0xd98>
ffffffffc0202318:	eb1fd0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert(pgfault_num==1);
ffffffffc020231c:	00004697          	auipc	a3,0x4
ffffffffc0202320:	dbc68693          	addi	a3,a3,-580 # ffffffffc02060d8 <commands+0xf30>
ffffffffc0202324:	00003617          	auipc	a2,0x3
ffffffffc0202328:	5ac60613          	addi	a2,a2,1452 # ffffffffc02058d0 <commands+0x728>
ffffffffc020232c:	09400593          	li	a1,148
ffffffffc0202330:	00004517          	auipc	a0,0x4
ffffffffc0202334:	c1050513          	addi	a0,a0,-1008 # ffffffffc0205f40 <commands+0xd98>
ffffffffc0202338:	e91fd0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc020233c <swap_init_mm>:
     return sm->init_mm(mm);
ffffffffc020233c:	00014797          	auipc	a5,0x14
ffffffffc0202340:	2347b783          	ld	a5,564(a5) # ffffffffc0216570 <sm>
ffffffffc0202344:	6b9c                	ld	a5,16(a5)
ffffffffc0202346:	8782                	jr	a5

ffffffffc0202348 <swap_map_swappable>:
     return sm->map_swappable(mm, addr, page, swap_in);
ffffffffc0202348:	00014797          	auipc	a5,0x14
ffffffffc020234c:	2287b783          	ld	a5,552(a5) # ffffffffc0216570 <sm>
ffffffffc0202350:	739c                	ld	a5,32(a5)
ffffffffc0202352:	8782                	jr	a5

ffffffffc0202354 <swap_out>:
{
ffffffffc0202354:	711d                	addi	sp,sp,-96
ffffffffc0202356:	ec86                	sd	ra,88(sp)
ffffffffc0202358:	e8a2                	sd	s0,80(sp)
ffffffffc020235a:	e4a6                	sd	s1,72(sp)
ffffffffc020235c:	e0ca                	sd	s2,64(sp)
ffffffffc020235e:	fc4e                	sd	s3,56(sp)
ffffffffc0202360:	f852                	sd	s4,48(sp)
ffffffffc0202362:	f456                	sd	s5,40(sp)
ffffffffc0202364:	f05a                	sd	s6,32(sp)
ffffffffc0202366:	ec5e                	sd	s7,24(sp)
ffffffffc0202368:	e862                	sd	s8,16(sp)
     for (i = 0; i != n; ++ i)
ffffffffc020236a:	cde9                	beqz	a1,ffffffffc0202444 <swap_out+0xf0>
ffffffffc020236c:	8a2e                	mv	s4,a1
ffffffffc020236e:	892a                	mv	s2,a0
ffffffffc0202370:	8ab2                	mv	s5,a2
ffffffffc0202372:	4401                	li	s0,0
ffffffffc0202374:	00014997          	auipc	s3,0x14
ffffffffc0202378:	1fc98993          	addi	s3,s3,508 # ffffffffc0216570 <sm>
                    cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr/PGSIZE+1);
ffffffffc020237c:	00004b17          	auipc	s6,0x4
ffffffffc0202380:	ed4b0b13          	addi	s6,s6,-300 # ffffffffc0206250 <commands+0x10a8>
                    cprintf("SWAP: failed to save\n");
ffffffffc0202384:	00004b97          	auipc	s7,0x4
ffffffffc0202388:	eb4b8b93          	addi	s7,s7,-332 # ffffffffc0206238 <commands+0x1090>
ffffffffc020238c:	a825                	j	ffffffffc02023c4 <swap_out+0x70>
                    cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr/PGSIZE+1);
ffffffffc020238e:	67a2                	ld	a5,8(sp)
ffffffffc0202390:	8626                	mv	a2,s1
ffffffffc0202392:	85a2                	mv	a1,s0
ffffffffc0202394:	7f94                	ld	a3,56(a5)
ffffffffc0202396:	855a                	mv	a0,s6
     for (i = 0; i != n; ++ i)
ffffffffc0202398:	2405                	addiw	s0,s0,1
                    cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr/PGSIZE+1);
ffffffffc020239a:	82b1                	srli	a3,a3,0xc
ffffffffc020239c:	0685                	addi	a3,a3,1
ffffffffc020239e:	d2ffd0ef          	jal	ra,ffffffffc02000cc <cprintf>
                    *ptep = (page->pra_vaddr/PGSIZE+1)<<8;
ffffffffc02023a2:	6522                	ld	a0,8(sp)
                    free_page(page);
ffffffffc02023a4:	4585                	li	a1,1
                    *ptep = (page->pra_vaddr/PGSIZE+1)<<8;
ffffffffc02023a6:	7d1c                	ld	a5,56(a0)
ffffffffc02023a8:	83b1                	srli	a5,a5,0xc
ffffffffc02023aa:	0785                	addi	a5,a5,1
ffffffffc02023ac:	07a2                	slli	a5,a5,0x8
ffffffffc02023ae:	00fc3023          	sd	a5,0(s8)
                    free_page(page);
ffffffffc02023b2:	4a9000ef          	jal	ra,ffffffffc020305a <free_pages>
          tlb_invalidate(mm->pgdir, v);
ffffffffc02023b6:	01893503          	ld	a0,24(s2)
ffffffffc02023ba:	85a6                	mv	a1,s1
ffffffffc02023bc:	46b010ef          	jal	ra,ffffffffc0204026 <tlb_invalidate>
     for (i = 0; i != n; ++ i)
ffffffffc02023c0:	048a0d63          	beq	s4,s0,ffffffffc020241a <swap_out+0xc6>
          int r = sm->swap_out_victim(mm, &page, in_tick);
ffffffffc02023c4:	0009b783          	ld	a5,0(s3)
ffffffffc02023c8:	8656                	mv	a2,s5
ffffffffc02023ca:	002c                	addi	a1,sp,8
ffffffffc02023cc:	7b9c                	ld	a5,48(a5)
ffffffffc02023ce:	854a                	mv	a0,s2
ffffffffc02023d0:	9782                	jalr	a5
          if (r != 0) {
ffffffffc02023d2:	e12d                	bnez	a0,ffffffffc0202434 <swap_out+0xe0>
          v=page->pra_vaddr; 
ffffffffc02023d4:	67a2                	ld	a5,8(sp)
          pte_t *ptep = get_pte(mm->pgdir, v, 0);
ffffffffc02023d6:	01893503          	ld	a0,24(s2)
ffffffffc02023da:	4601                	li	a2,0
          v=page->pra_vaddr; 
ffffffffc02023dc:	7f84                	ld	s1,56(a5)
          pte_t *ptep = get_pte(mm->pgdir, v, 0);
ffffffffc02023de:	85a6                	mv	a1,s1
ffffffffc02023e0:	4f5000ef          	jal	ra,ffffffffc02030d4 <get_pte>
          assert((*ptep & PTE_V) != 0);
ffffffffc02023e4:	611c                	ld	a5,0(a0)
          pte_t *ptep = get_pte(mm->pgdir, v, 0);
ffffffffc02023e6:	8c2a                	mv	s8,a0
          assert((*ptep & PTE_V) != 0);
ffffffffc02023e8:	8b85                	andi	a5,a5,1
ffffffffc02023ea:	cfb9                	beqz	a5,ffffffffc0202448 <swap_out+0xf4>
          if (swapfs_write( (page->pra_vaddr/PGSIZE+1)<<8, page) != 0) {
ffffffffc02023ec:	65a2                	ld	a1,8(sp)
ffffffffc02023ee:	7d9c                	ld	a5,56(a1)
ffffffffc02023f0:	83b1                	srli	a5,a5,0xc
ffffffffc02023f2:	0785                	addi	a5,a5,1
ffffffffc02023f4:	00879513          	slli	a0,a5,0x8
ffffffffc02023f8:	5b3010ef          	jal	ra,ffffffffc02041aa <swapfs_write>
ffffffffc02023fc:	d949                	beqz	a0,ffffffffc020238e <swap_out+0x3a>
                    cprintf("SWAP: failed to save\n");
ffffffffc02023fe:	855e                	mv	a0,s7
ffffffffc0202400:	ccdfd0ef          	jal	ra,ffffffffc02000cc <cprintf>
                    sm->map_swappable(mm, v, page, 0);
ffffffffc0202404:	0009b783          	ld	a5,0(s3)
ffffffffc0202408:	6622                	ld	a2,8(sp)
ffffffffc020240a:	4681                	li	a3,0
ffffffffc020240c:	739c                	ld	a5,32(a5)
ffffffffc020240e:	85a6                	mv	a1,s1
ffffffffc0202410:	854a                	mv	a0,s2
     for (i = 0; i != n; ++ i)
ffffffffc0202412:	2405                	addiw	s0,s0,1
                    sm->map_swappable(mm, v, page, 0);
ffffffffc0202414:	9782                	jalr	a5
     for (i = 0; i != n; ++ i)
ffffffffc0202416:	fa8a17e3          	bne	s4,s0,ffffffffc02023c4 <swap_out+0x70>
}
ffffffffc020241a:	60e6                	ld	ra,88(sp)
ffffffffc020241c:	8522                	mv	a0,s0
ffffffffc020241e:	6446                	ld	s0,80(sp)
ffffffffc0202420:	64a6                	ld	s1,72(sp)
ffffffffc0202422:	6906                	ld	s2,64(sp)
ffffffffc0202424:	79e2                	ld	s3,56(sp)
ffffffffc0202426:	7a42                	ld	s4,48(sp)
ffffffffc0202428:	7aa2                	ld	s5,40(sp)
ffffffffc020242a:	7b02                	ld	s6,32(sp)
ffffffffc020242c:	6be2                	ld	s7,24(sp)
ffffffffc020242e:	6c42                	ld	s8,16(sp)
ffffffffc0202430:	6125                	addi	sp,sp,96
ffffffffc0202432:	8082                	ret
                    cprintf("i %d, swap_out: call swap_out_victim failed\n",i);
ffffffffc0202434:	85a2                	mv	a1,s0
ffffffffc0202436:	00004517          	auipc	a0,0x4
ffffffffc020243a:	dba50513          	addi	a0,a0,-582 # ffffffffc02061f0 <commands+0x1048>
ffffffffc020243e:	c8ffd0ef          	jal	ra,ffffffffc02000cc <cprintf>
                  break;
ffffffffc0202442:	bfe1                	j	ffffffffc020241a <swap_out+0xc6>
     for (i = 0; i != n; ++ i)
ffffffffc0202444:	4401                	li	s0,0
ffffffffc0202446:	bfd1                	j	ffffffffc020241a <swap_out+0xc6>
          assert((*ptep & PTE_V) != 0);
ffffffffc0202448:	00004697          	auipc	a3,0x4
ffffffffc020244c:	dd868693          	addi	a3,a3,-552 # ffffffffc0206220 <commands+0x1078>
ffffffffc0202450:	00003617          	auipc	a2,0x3
ffffffffc0202454:	48060613          	addi	a2,a2,1152 # ffffffffc02058d0 <commands+0x728>
ffffffffc0202458:	06900593          	li	a1,105
ffffffffc020245c:	00004517          	auipc	a0,0x4
ffffffffc0202460:	ae450513          	addi	a0,a0,-1308 # ffffffffc0205f40 <commands+0xd98>
ffffffffc0202464:	d65fd0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc0202468 <swap_in>:
{
ffffffffc0202468:	7179                	addi	sp,sp,-48
ffffffffc020246a:	e84a                	sd	s2,16(sp)
ffffffffc020246c:	892a                	mv	s2,a0
     struct Page *result = alloc_page();
ffffffffc020246e:	4505                	li	a0,1
{
ffffffffc0202470:	ec26                	sd	s1,24(sp)
ffffffffc0202472:	e44e                	sd	s3,8(sp)
ffffffffc0202474:	f406                	sd	ra,40(sp)
ffffffffc0202476:	f022                	sd	s0,32(sp)
ffffffffc0202478:	84ae                	mv	s1,a1
ffffffffc020247a:	89b2                	mv	s3,a2
     struct Page *result = alloc_page();
ffffffffc020247c:	34d000ef          	jal	ra,ffffffffc0202fc8 <alloc_pages>
     assert(result!=NULL);
ffffffffc0202480:	c129                	beqz	a0,ffffffffc02024c2 <swap_in+0x5a>
     pte_t *ptep = get_pte(mm->pgdir, addr, 0);
ffffffffc0202482:	842a                	mv	s0,a0
ffffffffc0202484:	01893503          	ld	a0,24(s2)
ffffffffc0202488:	4601                	li	a2,0
ffffffffc020248a:	85a6                	mv	a1,s1
ffffffffc020248c:	449000ef          	jal	ra,ffffffffc02030d4 <get_pte>
ffffffffc0202490:	892a                	mv	s2,a0
     if ((r = swapfs_read((*ptep), result)) != 0)
ffffffffc0202492:	6108                	ld	a0,0(a0)
ffffffffc0202494:	85a2                	mv	a1,s0
ffffffffc0202496:	487010ef          	jal	ra,ffffffffc020411c <swapfs_read>
     cprintf("swap_in: load disk swap entry %d with swap_page in vadr 0x%x\n", (*ptep)>>8, addr);
ffffffffc020249a:	00093583          	ld	a1,0(s2)
ffffffffc020249e:	8626                	mv	a2,s1
ffffffffc02024a0:	00004517          	auipc	a0,0x4
ffffffffc02024a4:	e0050513          	addi	a0,a0,-512 # ffffffffc02062a0 <commands+0x10f8>
ffffffffc02024a8:	81a1                	srli	a1,a1,0x8
ffffffffc02024aa:	c23fd0ef          	jal	ra,ffffffffc02000cc <cprintf>
}
ffffffffc02024ae:	70a2                	ld	ra,40(sp)
     *ptr_result=result;
ffffffffc02024b0:	0089b023          	sd	s0,0(s3)
}
ffffffffc02024b4:	7402                	ld	s0,32(sp)
ffffffffc02024b6:	64e2                	ld	s1,24(sp)
ffffffffc02024b8:	6942                	ld	s2,16(sp)
ffffffffc02024ba:	69a2                	ld	s3,8(sp)
ffffffffc02024bc:	4501                	li	a0,0
ffffffffc02024be:	6145                	addi	sp,sp,48
ffffffffc02024c0:	8082                	ret
     assert(result!=NULL);
ffffffffc02024c2:	00004697          	auipc	a3,0x4
ffffffffc02024c6:	dce68693          	addi	a3,a3,-562 # ffffffffc0206290 <commands+0x10e8>
ffffffffc02024ca:	00003617          	auipc	a2,0x3
ffffffffc02024ce:	40660613          	addi	a2,a2,1030 # ffffffffc02058d0 <commands+0x728>
ffffffffc02024d2:	07f00593          	li	a1,127
ffffffffc02024d6:	00004517          	auipc	a0,0x4
ffffffffc02024da:	a6a50513          	addi	a0,a0,-1430 # ffffffffc0205f40 <commands+0xd98>
ffffffffc02024de:	cebfd0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc02024e2 <default_init>:
    elm->prev = elm->next = elm;
ffffffffc02024e2:	00010797          	auipc	a5,0x10
ffffffffc02024e6:	01e78793          	addi	a5,a5,30 # ffffffffc0212500 <free_area>
ffffffffc02024ea:	e79c                	sd	a5,8(a5)
ffffffffc02024ec:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
default_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc02024ee:	0007a823          	sw	zero,16(a5)
}
ffffffffc02024f2:	8082                	ret

ffffffffc02024f4 <default_nr_free_pages>:
}

static size_t
default_nr_free_pages(void) {
    return nr_free;
}
ffffffffc02024f4:	00010517          	auipc	a0,0x10
ffffffffc02024f8:	01c56503          	lwu	a0,28(a0) # ffffffffc0212510 <free_area+0x10>
ffffffffc02024fc:	8082                	ret

ffffffffc02024fe <default_check>:
}

// LAB2: below code is used to check the first fit allocation algorithm
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
ffffffffc02024fe:	715d                	addi	sp,sp,-80
ffffffffc0202500:	e0a2                	sd	s0,64(sp)
    return listelm->next;
ffffffffc0202502:	00010417          	auipc	s0,0x10
ffffffffc0202506:	ffe40413          	addi	s0,s0,-2 # ffffffffc0212500 <free_area>
ffffffffc020250a:	641c                	ld	a5,8(s0)
ffffffffc020250c:	e486                	sd	ra,72(sp)
ffffffffc020250e:	fc26                	sd	s1,56(sp)
ffffffffc0202510:	f84a                	sd	s2,48(sp)
ffffffffc0202512:	f44e                	sd	s3,40(sp)
ffffffffc0202514:	f052                	sd	s4,32(sp)
ffffffffc0202516:	ec56                	sd	s5,24(sp)
ffffffffc0202518:	e85a                	sd	s6,16(sp)
ffffffffc020251a:	e45e                	sd	s7,8(sp)
ffffffffc020251c:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc020251e:	2a878d63          	beq	a5,s0,ffffffffc02027d8 <default_check+0x2da>
    int count = 0, total = 0;
ffffffffc0202522:	4481                	li	s1,0
ffffffffc0202524:	4901                	li	s2,0
ffffffffc0202526:	ff07b703          	ld	a4,-16(a5)
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc020252a:	8b09                	andi	a4,a4,2
ffffffffc020252c:	2a070a63          	beqz	a4,ffffffffc02027e0 <default_check+0x2e2>
        count ++, total += p->property;
ffffffffc0202530:	ff87a703          	lw	a4,-8(a5)
ffffffffc0202534:	679c                	ld	a5,8(a5)
ffffffffc0202536:	2905                	addiw	s2,s2,1
ffffffffc0202538:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc020253a:	fe8796e3          	bne	a5,s0,ffffffffc0202526 <default_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc020253e:	89a6                	mv	s3,s1
ffffffffc0202540:	35b000ef          	jal	ra,ffffffffc020309a <nr_free_pages>
ffffffffc0202544:	6f351e63          	bne	a0,s3,ffffffffc0202c40 <default_check+0x742>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0202548:	4505                	li	a0,1
ffffffffc020254a:	27f000ef          	jal	ra,ffffffffc0202fc8 <alloc_pages>
ffffffffc020254e:	8aaa                	mv	s5,a0
ffffffffc0202550:	42050863          	beqz	a0,ffffffffc0202980 <default_check+0x482>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0202554:	4505                	li	a0,1
ffffffffc0202556:	273000ef          	jal	ra,ffffffffc0202fc8 <alloc_pages>
ffffffffc020255a:	89aa                	mv	s3,a0
ffffffffc020255c:	70050263          	beqz	a0,ffffffffc0202c60 <default_check+0x762>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0202560:	4505                	li	a0,1
ffffffffc0202562:	267000ef          	jal	ra,ffffffffc0202fc8 <alloc_pages>
ffffffffc0202566:	8a2a                	mv	s4,a0
ffffffffc0202568:	48050c63          	beqz	a0,ffffffffc0202a00 <default_check+0x502>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc020256c:	293a8a63          	beq	s5,s3,ffffffffc0202800 <default_check+0x302>
ffffffffc0202570:	28aa8863          	beq	s5,a0,ffffffffc0202800 <default_check+0x302>
ffffffffc0202574:	28a98663          	beq	s3,a0,ffffffffc0202800 <default_check+0x302>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0202578:	000aa783          	lw	a5,0(s5)
ffffffffc020257c:	2a079263          	bnez	a5,ffffffffc0202820 <default_check+0x322>
ffffffffc0202580:	0009a783          	lw	a5,0(s3)
ffffffffc0202584:	28079e63          	bnez	a5,ffffffffc0202820 <default_check+0x322>
ffffffffc0202588:	411c                	lw	a5,0(a0)
ffffffffc020258a:	28079b63          	bnez	a5,ffffffffc0202820 <default_check+0x322>
    return page - pages + nbase;
ffffffffc020258e:	00014797          	auipc	a5,0x14
ffffffffc0202592:	00a7b783          	ld	a5,10(a5) # ffffffffc0216598 <pages>
ffffffffc0202596:	40fa8733          	sub	a4,s5,a5
ffffffffc020259a:	00005617          	auipc	a2,0x5
ffffffffc020259e:	a8663603          	ld	a2,-1402(a2) # ffffffffc0207020 <nbase>
ffffffffc02025a2:	8719                	srai	a4,a4,0x6
ffffffffc02025a4:	9732                	add	a4,a4,a2
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc02025a6:	00014697          	auipc	a3,0x14
ffffffffc02025aa:	fea6b683          	ld	a3,-22(a3) # ffffffffc0216590 <npage>
ffffffffc02025ae:	06b2                	slli	a3,a3,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc02025b0:	0732                	slli	a4,a4,0xc
ffffffffc02025b2:	28d77763          	bgeu	a4,a3,ffffffffc0202840 <default_check+0x342>
    return page - pages + nbase;
ffffffffc02025b6:	40f98733          	sub	a4,s3,a5
ffffffffc02025ba:	8719                	srai	a4,a4,0x6
ffffffffc02025bc:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc02025be:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc02025c0:	4cd77063          	bgeu	a4,a3,ffffffffc0202a80 <default_check+0x582>
    return page - pages + nbase;
ffffffffc02025c4:	40f507b3          	sub	a5,a0,a5
ffffffffc02025c8:	8799                	srai	a5,a5,0x6
ffffffffc02025ca:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc02025cc:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc02025ce:	30d7f963          	bgeu	a5,a3,ffffffffc02028e0 <default_check+0x3e2>
    assert(alloc_page() == NULL);
ffffffffc02025d2:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc02025d4:	00043c03          	ld	s8,0(s0)
ffffffffc02025d8:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc02025dc:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc02025e0:	e400                	sd	s0,8(s0)
ffffffffc02025e2:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc02025e4:	00010797          	auipc	a5,0x10
ffffffffc02025e8:	f207a623          	sw	zero,-212(a5) # ffffffffc0212510 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc02025ec:	1dd000ef          	jal	ra,ffffffffc0202fc8 <alloc_pages>
ffffffffc02025f0:	2c051863          	bnez	a0,ffffffffc02028c0 <default_check+0x3c2>
    free_page(p0);
ffffffffc02025f4:	4585                	li	a1,1
ffffffffc02025f6:	8556                	mv	a0,s5
ffffffffc02025f8:	263000ef          	jal	ra,ffffffffc020305a <free_pages>
    free_page(p1);
ffffffffc02025fc:	4585                	li	a1,1
ffffffffc02025fe:	854e                	mv	a0,s3
ffffffffc0202600:	25b000ef          	jal	ra,ffffffffc020305a <free_pages>
    free_page(p2);
ffffffffc0202604:	4585                	li	a1,1
ffffffffc0202606:	8552                	mv	a0,s4
ffffffffc0202608:	253000ef          	jal	ra,ffffffffc020305a <free_pages>
    assert(nr_free == 3);
ffffffffc020260c:	4818                	lw	a4,16(s0)
ffffffffc020260e:	478d                	li	a5,3
ffffffffc0202610:	28f71863          	bne	a4,a5,ffffffffc02028a0 <default_check+0x3a2>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0202614:	4505                	li	a0,1
ffffffffc0202616:	1b3000ef          	jal	ra,ffffffffc0202fc8 <alloc_pages>
ffffffffc020261a:	89aa                	mv	s3,a0
ffffffffc020261c:	26050263          	beqz	a0,ffffffffc0202880 <default_check+0x382>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0202620:	4505                	li	a0,1
ffffffffc0202622:	1a7000ef          	jal	ra,ffffffffc0202fc8 <alloc_pages>
ffffffffc0202626:	8aaa                	mv	s5,a0
ffffffffc0202628:	3a050c63          	beqz	a0,ffffffffc02029e0 <default_check+0x4e2>
    assert((p2 = alloc_page()) != NULL);
ffffffffc020262c:	4505                	li	a0,1
ffffffffc020262e:	19b000ef          	jal	ra,ffffffffc0202fc8 <alloc_pages>
ffffffffc0202632:	8a2a                	mv	s4,a0
ffffffffc0202634:	38050663          	beqz	a0,ffffffffc02029c0 <default_check+0x4c2>
    assert(alloc_page() == NULL);
ffffffffc0202638:	4505                	li	a0,1
ffffffffc020263a:	18f000ef          	jal	ra,ffffffffc0202fc8 <alloc_pages>
ffffffffc020263e:	36051163          	bnez	a0,ffffffffc02029a0 <default_check+0x4a2>
    free_page(p0);
ffffffffc0202642:	4585                	li	a1,1
ffffffffc0202644:	854e                	mv	a0,s3
ffffffffc0202646:	215000ef          	jal	ra,ffffffffc020305a <free_pages>
    assert(!list_empty(&free_list));
ffffffffc020264a:	641c                	ld	a5,8(s0)
ffffffffc020264c:	20878a63          	beq	a5,s0,ffffffffc0202860 <default_check+0x362>
    assert((p = alloc_page()) == p0);
ffffffffc0202650:	4505                	li	a0,1
ffffffffc0202652:	177000ef          	jal	ra,ffffffffc0202fc8 <alloc_pages>
ffffffffc0202656:	30a99563          	bne	s3,a0,ffffffffc0202960 <default_check+0x462>
    assert(alloc_page() == NULL);
ffffffffc020265a:	4505                	li	a0,1
ffffffffc020265c:	16d000ef          	jal	ra,ffffffffc0202fc8 <alloc_pages>
ffffffffc0202660:	2e051063          	bnez	a0,ffffffffc0202940 <default_check+0x442>
    assert(nr_free == 0);
ffffffffc0202664:	481c                	lw	a5,16(s0)
ffffffffc0202666:	2a079d63          	bnez	a5,ffffffffc0202920 <default_check+0x422>
    free_page(p);
ffffffffc020266a:	854e                	mv	a0,s3
ffffffffc020266c:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc020266e:	01843023          	sd	s8,0(s0)
ffffffffc0202672:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc0202676:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc020267a:	1e1000ef          	jal	ra,ffffffffc020305a <free_pages>
    free_page(p1);
ffffffffc020267e:	4585                	li	a1,1
ffffffffc0202680:	8556                	mv	a0,s5
ffffffffc0202682:	1d9000ef          	jal	ra,ffffffffc020305a <free_pages>
    free_page(p2);
ffffffffc0202686:	4585                	li	a1,1
ffffffffc0202688:	8552                	mv	a0,s4
ffffffffc020268a:	1d1000ef          	jal	ra,ffffffffc020305a <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc020268e:	4515                	li	a0,5
ffffffffc0202690:	139000ef          	jal	ra,ffffffffc0202fc8 <alloc_pages>
ffffffffc0202694:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0202696:	26050563          	beqz	a0,ffffffffc0202900 <default_check+0x402>
ffffffffc020269a:	651c                	ld	a5,8(a0)
ffffffffc020269c:	8385                	srli	a5,a5,0x1
    assert(!PageProperty(p0));
ffffffffc020269e:	8b85                	andi	a5,a5,1
ffffffffc02026a0:	54079063          	bnez	a5,ffffffffc0202be0 <default_check+0x6e2>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc02026a4:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc02026a6:	00043b03          	ld	s6,0(s0)
ffffffffc02026aa:	00843a83          	ld	s5,8(s0)
ffffffffc02026ae:	e000                	sd	s0,0(s0)
ffffffffc02026b0:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc02026b2:	117000ef          	jal	ra,ffffffffc0202fc8 <alloc_pages>
ffffffffc02026b6:	50051563          	bnez	a0,ffffffffc0202bc0 <default_check+0x6c2>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc02026ba:	08098a13          	addi	s4,s3,128
ffffffffc02026be:	8552                	mv	a0,s4
ffffffffc02026c0:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc02026c2:	01042b83          	lw	s7,16(s0)
    nr_free = 0;
ffffffffc02026c6:	00010797          	auipc	a5,0x10
ffffffffc02026ca:	e407a523          	sw	zero,-438(a5) # ffffffffc0212510 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc02026ce:	18d000ef          	jal	ra,ffffffffc020305a <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc02026d2:	4511                	li	a0,4
ffffffffc02026d4:	0f5000ef          	jal	ra,ffffffffc0202fc8 <alloc_pages>
ffffffffc02026d8:	4c051463          	bnez	a0,ffffffffc0202ba0 <default_check+0x6a2>
ffffffffc02026dc:	0889b783          	ld	a5,136(s3)
ffffffffc02026e0:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc02026e2:	8b85                	andi	a5,a5,1
ffffffffc02026e4:	48078e63          	beqz	a5,ffffffffc0202b80 <default_check+0x682>
ffffffffc02026e8:	0909a703          	lw	a4,144(s3)
ffffffffc02026ec:	478d                	li	a5,3
ffffffffc02026ee:	48f71963          	bne	a4,a5,ffffffffc0202b80 <default_check+0x682>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc02026f2:	450d                	li	a0,3
ffffffffc02026f4:	0d5000ef          	jal	ra,ffffffffc0202fc8 <alloc_pages>
ffffffffc02026f8:	8c2a                	mv	s8,a0
ffffffffc02026fa:	46050363          	beqz	a0,ffffffffc0202b60 <default_check+0x662>
    assert(alloc_page() == NULL);
ffffffffc02026fe:	4505                	li	a0,1
ffffffffc0202700:	0c9000ef          	jal	ra,ffffffffc0202fc8 <alloc_pages>
ffffffffc0202704:	42051e63          	bnez	a0,ffffffffc0202b40 <default_check+0x642>
    assert(p0 + 2 == p1);
ffffffffc0202708:	418a1c63          	bne	s4,s8,ffffffffc0202b20 <default_check+0x622>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc020270c:	4585                	li	a1,1
ffffffffc020270e:	854e                	mv	a0,s3
ffffffffc0202710:	14b000ef          	jal	ra,ffffffffc020305a <free_pages>
    free_pages(p1, 3);
ffffffffc0202714:	458d                	li	a1,3
ffffffffc0202716:	8552                	mv	a0,s4
ffffffffc0202718:	143000ef          	jal	ra,ffffffffc020305a <free_pages>
ffffffffc020271c:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc0202720:	04098c13          	addi	s8,s3,64
ffffffffc0202724:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0202726:	8b85                	andi	a5,a5,1
ffffffffc0202728:	3c078c63          	beqz	a5,ffffffffc0202b00 <default_check+0x602>
ffffffffc020272c:	0109a703          	lw	a4,16(s3)
ffffffffc0202730:	4785                	li	a5,1
ffffffffc0202732:	3cf71763          	bne	a4,a5,ffffffffc0202b00 <default_check+0x602>
ffffffffc0202736:	008a3783          	ld	a5,8(s4)
ffffffffc020273a:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc020273c:	8b85                	andi	a5,a5,1
ffffffffc020273e:	3a078163          	beqz	a5,ffffffffc0202ae0 <default_check+0x5e2>
ffffffffc0202742:	010a2703          	lw	a4,16(s4)
ffffffffc0202746:	478d                	li	a5,3
ffffffffc0202748:	38f71c63          	bne	a4,a5,ffffffffc0202ae0 <default_check+0x5e2>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc020274c:	4505                	li	a0,1
ffffffffc020274e:	07b000ef          	jal	ra,ffffffffc0202fc8 <alloc_pages>
ffffffffc0202752:	36a99763          	bne	s3,a0,ffffffffc0202ac0 <default_check+0x5c2>
    free_page(p0);
ffffffffc0202756:	4585                	li	a1,1
ffffffffc0202758:	103000ef          	jal	ra,ffffffffc020305a <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc020275c:	4509                	li	a0,2
ffffffffc020275e:	06b000ef          	jal	ra,ffffffffc0202fc8 <alloc_pages>
ffffffffc0202762:	32aa1f63          	bne	s4,a0,ffffffffc0202aa0 <default_check+0x5a2>

    free_pages(p0, 2);
ffffffffc0202766:	4589                	li	a1,2
ffffffffc0202768:	0f3000ef          	jal	ra,ffffffffc020305a <free_pages>
    free_page(p2);
ffffffffc020276c:	4585                	li	a1,1
ffffffffc020276e:	8562                	mv	a0,s8
ffffffffc0202770:	0eb000ef          	jal	ra,ffffffffc020305a <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0202774:	4515                	li	a0,5
ffffffffc0202776:	053000ef          	jal	ra,ffffffffc0202fc8 <alloc_pages>
ffffffffc020277a:	89aa                	mv	s3,a0
ffffffffc020277c:	48050263          	beqz	a0,ffffffffc0202c00 <default_check+0x702>
    assert(alloc_page() == NULL);
ffffffffc0202780:	4505                	li	a0,1
ffffffffc0202782:	047000ef          	jal	ra,ffffffffc0202fc8 <alloc_pages>
ffffffffc0202786:	2c051d63          	bnez	a0,ffffffffc0202a60 <default_check+0x562>

    assert(nr_free == 0);
ffffffffc020278a:	481c                	lw	a5,16(s0)
ffffffffc020278c:	2a079a63          	bnez	a5,ffffffffc0202a40 <default_check+0x542>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0202790:	4595                	li	a1,5
ffffffffc0202792:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0202794:	01742823          	sw	s7,16(s0)
    free_list = free_list_store;
ffffffffc0202798:	01643023          	sd	s6,0(s0)
ffffffffc020279c:	01543423          	sd	s5,8(s0)
    free_pages(p0, 5);
ffffffffc02027a0:	0bb000ef          	jal	ra,ffffffffc020305a <free_pages>
    return listelm->next;
ffffffffc02027a4:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc02027a6:	00878963          	beq	a5,s0,ffffffffc02027b8 <default_check+0x2ba>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc02027aa:	ff87a703          	lw	a4,-8(a5)
ffffffffc02027ae:	679c                	ld	a5,8(a5)
ffffffffc02027b0:	397d                	addiw	s2,s2,-1
ffffffffc02027b2:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc02027b4:	fe879be3          	bne	a5,s0,ffffffffc02027aa <default_check+0x2ac>
    }
    assert(count == 0);
ffffffffc02027b8:	26091463          	bnez	s2,ffffffffc0202a20 <default_check+0x522>
    assert(total == 0);
ffffffffc02027bc:	46049263          	bnez	s1,ffffffffc0202c20 <default_check+0x722>
}
ffffffffc02027c0:	60a6                	ld	ra,72(sp)
ffffffffc02027c2:	6406                	ld	s0,64(sp)
ffffffffc02027c4:	74e2                	ld	s1,56(sp)
ffffffffc02027c6:	7942                	ld	s2,48(sp)
ffffffffc02027c8:	79a2                	ld	s3,40(sp)
ffffffffc02027ca:	7a02                	ld	s4,32(sp)
ffffffffc02027cc:	6ae2                	ld	s5,24(sp)
ffffffffc02027ce:	6b42                	ld	s6,16(sp)
ffffffffc02027d0:	6ba2                	ld	s7,8(sp)
ffffffffc02027d2:	6c02                	ld	s8,0(sp)
ffffffffc02027d4:	6161                	addi	sp,sp,80
ffffffffc02027d6:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc02027d8:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc02027da:	4481                	li	s1,0
ffffffffc02027dc:	4901                	li	s2,0
ffffffffc02027de:	b38d                	j	ffffffffc0202540 <default_check+0x42>
        assert(PageProperty(p));
ffffffffc02027e0:	00003697          	auipc	a3,0x3
ffffffffc02027e4:	78868693          	addi	a3,a3,1928 # ffffffffc0205f68 <commands+0xdc0>
ffffffffc02027e8:	00003617          	auipc	a2,0x3
ffffffffc02027ec:	0e860613          	addi	a2,a2,232 # ffffffffc02058d0 <commands+0x728>
ffffffffc02027f0:	0f000593          	li	a1,240
ffffffffc02027f4:	00004517          	auipc	a0,0x4
ffffffffc02027f8:	aec50513          	addi	a0,a0,-1300 # ffffffffc02062e0 <commands+0x1138>
ffffffffc02027fc:	9cdfd0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0202800:	00004697          	auipc	a3,0x4
ffffffffc0202804:	b5868693          	addi	a3,a3,-1192 # ffffffffc0206358 <commands+0x11b0>
ffffffffc0202808:	00003617          	auipc	a2,0x3
ffffffffc020280c:	0c860613          	addi	a2,a2,200 # ffffffffc02058d0 <commands+0x728>
ffffffffc0202810:	0bd00593          	li	a1,189
ffffffffc0202814:	00004517          	auipc	a0,0x4
ffffffffc0202818:	acc50513          	addi	a0,a0,-1332 # ffffffffc02062e0 <commands+0x1138>
ffffffffc020281c:	9adfd0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0202820:	00004697          	auipc	a3,0x4
ffffffffc0202824:	b6068693          	addi	a3,a3,-1184 # ffffffffc0206380 <commands+0x11d8>
ffffffffc0202828:	00003617          	auipc	a2,0x3
ffffffffc020282c:	0a860613          	addi	a2,a2,168 # ffffffffc02058d0 <commands+0x728>
ffffffffc0202830:	0be00593          	li	a1,190
ffffffffc0202834:	00004517          	auipc	a0,0x4
ffffffffc0202838:	aac50513          	addi	a0,a0,-1364 # ffffffffc02062e0 <commands+0x1138>
ffffffffc020283c:	98dfd0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0202840:	00004697          	auipc	a3,0x4
ffffffffc0202844:	b8068693          	addi	a3,a3,-1152 # ffffffffc02063c0 <commands+0x1218>
ffffffffc0202848:	00003617          	auipc	a2,0x3
ffffffffc020284c:	08860613          	addi	a2,a2,136 # ffffffffc02058d0 <commands+0x728>
ffffffffc0202850:	0c000593          	li	a1,192
ffffffffc0202854:	00004517          	auipc	a0,0x4
ffffffffc0202858:	a8c50513          	addi	a0,a0,-1396 # ffffffffc02062e0 <commands+0x1138>
ffffffffc020285c:	96dfd0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(!list_empty(&free_list));
ffffffffc0202860:	00004697          	auipc	a3,0x4
ffffffffc0202864:	be868693          	addi	a3,a3,-1048 # ffffffffc0206448 <commands+0x12a0>
ffffffffc0202868:	00003617          	auipc	a2,0x3
ffffffffc020286c:	06860613          	addi	a2,a2,104 # ffffffffc02058d0 <commands+0x728>
ffffffffc0202870:	0d900593          	li	a1,217
ffffffffc0202874:	00004517          	auipc	a0,0x4
ffffffffc0202878:	a6c50513          	addi	a0,a0,-1428 # ffffffffc02062e0 <commands+0x1138>
ffffffffc020287c:	94dfd0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0202880:	00004697          	auipc	a3,0x4
ffffffffc0202884:	a7868693          	addi	a3,a3,-1416 # ffffffffc02062f8 <commands+0x1150>
ffffffffc0202888:	00003617          	auipc	a2,0x3
ffffffffc020288c:	04860613          	addi	a2,a2,72 # ffffffffc02058d0 <commands+0x728>
ffffffffc0202890:	0d200593          	li	a1,210
ffffffffc0202894:	00004517          	auipc	a0,0x4
ffffffffc0202898:	a4c50513          	addi	a0,a0,-1460 # ffffffffc02062e0 <commands+0x1138>
ffffffffc020289c:	92dfd0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(nr_free == 3);
ffffffffc02028a0:	00004697          	auipc	a3,0x4
ffffffffc02028a4:	b9868693          	addi	a3,a3,-1128 # ffffffffc0206438 <commands+0x1290>
ffffffffc02028a8:	00003617          	auipc	a2,0x3
ffffffffc02028ac:	02860613          	addi	a2,a2,40 # ffffffffc02058d0 <commands+0x728>
ffffffffc02028b0:	0d000593          	li	a1,208
ffffffffc02028b4:	00004517          	auipc	a0,0x4
ffffffffc02028b8:	a2c50513          	addi	a0,a0,-1492 # ffffffffc02062e0 <commands+0x1138>
ffffffffc02028bc:	90dfd0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02028c0:	00004697          	auipc	a3,0x4
ffffffffc02028c4:	b6068693          	addi	a3,a3,-1184 # ffffffffc0206420 <commands+0x1278>
ffffffffc02028c8:	00003617          	auipc	a2,0x3
ffffffffc02028cc:	00860613          	addi	a2,a2,8 # ffffffffc02058d0 <commands+0x728>
ffffffffc02028d0:	0cb00593          	li	a1,203
ffffffffc02028d4:	00004517          	auipc	a0,0x4
ffffffffc02028d8:	a0c50513          	addi	a0,a0,-1524 # ffffffffc02062e0 <commands+0x1138>
ffffffffc02028dc:	8edfd0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc02028e0:	00004697          	auipc	a3,0x4
ffffffffc02028e4:	b2068693          	addi	a3,a3,-1248 # ffffffffc0206400 <commands+0x1258>
ffffffffc02028e8:	00003617          	auipc	a2,0x3
ffffffffc02028ec:	fe860613          	addi	a2,a2,-24 # ffffffffc02058d0 <commands+0x728>
ffffffffc02028f0:	0c200593          	li	a1,194
ffffffffc02028f4:	00004517          	auipc	a0,0x4
ffffffffc02028f8:	9ec50513          	addi	a0,a0,-1556 # ffffffffc02062e0 <commands+0x1138>
ffffffffc02028fc:	8cdfd0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(p0 != NULL);
ffffffffc0202900:	00004697          	auipc	a3,0x4
ffffffffc0202904:	b8068693          	addi	a3,a3,-1152 # ffffffffc0206480 <commands+0x12d8>
ffffffffc0202908:	00003617          	auipc	a2,0x3
ffffffffc020290c:	fc860613          	addi	a2,a2,-56 # ffffffffc02058d0 <commands+0x728>
ffffffffc0202910:	0f800593          	li	a1,248
ffffffffc0202914:	00004517          	auipc	a0,0x4
ffffffffc0202918:	9cc50513          	addi	a0,a0,-1588 # ffffffffc02062e0 <commands+0x1138>
ffffffffc020291c:	8adfd0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(nr_free == 0);
ffffffffc0202920:	00003697          	auipc	a3,0x3
ffffffffc0202924:	7e868693          	addi	a3,a3,2024 # ffffffffc0206108 <commands+0xf60>
ffffffffc0202928:	00003617          	auipc	a2,0x3
ffffffffc020292c:	fa860613          	addi	a2,a2,-88 # ffffffffc02058d0 <commands+0x728>
ffffffffc0202930:	0df00593          	li	a1,223
ffffffffc0202934:	00004517          	auipc	a0,0x4
ffffffffc0202938:	9ac50513          	addi	a0,a0,-1620 # ffffffffc02062e0 <commands+0x1138>
ffffffffc020293c:	88dfd0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0202940:	00004697          	auipc	a3,0x4
ffffffffc0202944:	ae068693          	addi	a3,a3,-1312 # ffffffffc0206420 <commands+0x1278>
ffffffffc0202948:	00003617          	auipc	a2,0x3
ffffffffc020294c:	f8860613          	addi	a2,a2,-120 # ffffffffc02058d0 <commands+0x728>
ffffffffc0202950:	0dd00593          	li	a1,221
ffffffffc0202954:	00004517          	auipc	a0,0x4
ffffffffc0202958:	98c50513          	addi	a0,a0,-1652 # ffffffffc02062e0 <commands+0x1138>
ffffffffc020295c:	86dfd0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0202960:	00004697          	auipc	a3,0x4
ffffffffc0202964:	b0068693          	addi	a3,a3,-1280 # ffffffffc0206460 <commands+0x12b8>
ffffffffc0202968:	00003617          	auipc	a2,0x3
ffffffffc020296c:	f6860613          	addi	a2,a2,-152 # ffffffffc02058d0 <commands+0x728>
ffffffffc0202970:	0dc00593          	li	a1,220
ffffffffc0202974:	00004517          	auipc	a0,0x4
ffffffffc0202978:	96c50513          	addi	a0,a0,-1684 # ffffffffc02062e0 <commands+0x1138>
ffffffffc020297c:	84dfd0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0202980:	00004697          	auipc	a3,0x4
ffffffffc0202984:	97868693          	addi	a3,a3,-1672 # ffffffffc02062f8 <commands+0x1150>
ffffffffc0202988:	00003617          	auipc	a2,0x3
ffffffffc020298c:	f4860613          	addi	a2,a2,-184 # ffffffffc02058d0 <commands+0x728>
ffffffffc0202990:	0b900593          	li	a1,185
ffffffffc0202994:	00004517          	auipc	a0,0x4
ffffffffc0202998:	94c50513          	addi	a0,a0,-1716 # ffffffffc02062e0 <commands+0x1138>
ffffffffc020299c:	82dfd0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02029a0:	00004697          	auipc	a3,0x4
ffffffffc02029a4:	a8068693          	addi	a3,a3,-1408 # ffffffffc0206420 <commands+0x1278>
ffffffffc02029a8:	00003617          	auipc	a2,0x3
ffffffffc02029ac:	f2860613          	addi	a2,a2,-216 # ffffffffc02058d0 <commands+0x728>
ffffffffc02029b0:	0d600593          	li	a1,214
ffffffffc02029b4:	00004517          	auipc	a0,0x4
ffffffffc02029b8:	92c50513          	addi	a0,a0,-1748 # ffffffffc02062e0 <commands+0x1138>
ffffffffc02029bc:	80dfd0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02029c0:	00004697          	auipc	a3,0x4
ffffffffc02029c4:	97868693          	addi	a3,a3,-1672 # ffffffffc0206338 <commands+0x1190>
ffffffffc02029c8:	00003617          	auipc	a2,0x3
ffffffffc02029cc:	f0860613          	addi	a2,a2,-248 # ffffffffc02058d0 <commands+0x728>
ffffffffc02029d0:	0d400593          	li	a1,212
ffffffffc02029d4:	00004517          	auipc	a0,0x4
ffffffffc02029d8:	90c50513          	addi	a0,a0,-1780 # ffffffffc02062e0 <commands+0x1138>
ffffffffc02029dc:	fecfd0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02029e0:	00004697          	auipc	a3,0x4
ffffffffc02029e4:	93868693          	addi	a3,a3,-1736 # ffffffffc0206318 <commands+0x1170>
ffffffffc02029e8:	00003617          	auipc	a2,0x3
ffffffffc02029ec:	ee860613          	addi	a2,a2,-280 # ffffffffc02058d0 <commands+0x728>
ffffffffc02029f0:	0d300593          	li	a1,211
ffffffffc02029f4:	00004517          	auipc	a0,0x4
ffffffffc02029f8:	8ec50513          	addi	a0,a0,-1812 # ffffffffc02062e0 <commands+0x1138>
ffffffffc02029fc:	fccfd0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0202a00:	00004697          	auipc	a3,0x4
ffffffffc0202a04:	93868693          	addi	a3,a3,-1736 # ffffffffc0206338 <commands+0x1190>
ffffffffc0202a08:	00003617          	auipc	a2,0x3
ffffffffc0202a0c:	ec860613          	addi	a2,a2,-312 # ffffffffc02058d0 <commands+0x728>
ffffffffc0202a10:	0bb00593          	li	a1,187
ffffffffc0202a14:	00004517          	auipc	a0,0x4
ffffffffc0202a18:	8cc50513          	addi	a0,a0,-1844 # ffffffffc02062e0 <commands+0x1138>
ffffffffc0202a1c:	facfd0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(count == 0);
ffffffffc0202a20:	00004697          	auipc	a3,0x4
ffffffffc0202a24:	bb068693          	addi	a3,a3,-1104 # ffffffffc02065d0 <commands+0x1428>
ffffffffc0202a28:	00003617          	auipc	a2,0x3
ffffffffc0202a2c:	ea860613          	addi	a2,a2,-344 # ffffffffc02058d0 <commands+0x728>
ffffffffc0202a30:	12500593          	li	a1,293
ffffffffc0202a34:	00004517          	auipc	a0,0x4
ffffffffc0202a38:	8ac50513          	addi	a0,a0,-1876 # ffffffffc02062e0 <commands+0x1138>
ffffffffc0202a3c:	f8cfd0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(nr_free == 0);
ffffffffc0202a40:	00003697          	auipc	a3,0x3
ffffffffc0202a44:	6c868693          	addi	a3,a3,1736 # ffffffffc0206108 <commands+0xf60>
ffffffffc0202a48:	00003617          	auipc	a2,0x3
ffffffffc0202a4c:	e8860613          	addi	a2,a2,-376 # ffffffffc02058d0 <commands+0x728>
ffffffffc0202a50:	11a00593          	li	a1,282
ffffffffc0202a54:	00004517          	auipc	a0,0x4
ffffffffc0202a58:	88c50513          	addi	a0,a0,-1908 # ffffffffc02062e0 <commands+0x1138>
ffffffffc0202a5c:	f6cfd0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0202a60:	00004697          	auipc	a3,0x4
ffffffffc0202a64:	9c068693          	addi	a3,a3,-1600 # ffffffffc0206420 <commands+0x1278>
ffffffffc0202a68:	00003617          	auipc	a2,0x3
ffffffffc0202a6c:	e6860613          	addi	a2,a2,-408 # ffffffffc02058d0 <commands+0x728>
ffffffffc0202a70:	11800593          	li	a1,280
ffffffffc0202a74:	00004517          	auipc	a0,0x4
ffffffffc0202a78:	86c50513          	addi	a0,a0,-1940 # ffffffffc02062e0 <commands+0x1138>
ffffffffc0202a7c:	f4cfd0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0202a80:	00004697          	auipc	a3,0x4
ffffffffc0202a84:	96068693          	addi	a3,a3,-1696 # ffffffffc02063e0 <commands+0x1238>
ffffffffc0202a88:	00003617          	auipc	a2,0x3
ffffffffc0202a8c:	e4860613          	addi	a2,a2,-440 # ffffffffc02058d0 <commands+0x728>
ffffffffc0202a90:	0c100593          	li	a1,193
ffffffffc0202a94:	00004517          	auipc	a0,0x4
ffffffffc0202a98:	84c50513          	addi	a0,a0,-1972 # ffffffffc02062e0 <commands+0x1138>
ffffffffc0202a9c:	f2cfd0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0202aa0:	00004697          	auipc	a3,0x4
ffffffffc0202aa4:	af068693          	addi	a3,a3,-1296 # ffffffffc0206590 <commands+0x13e8>
ffffffffc0202aa8:	00003617          	auipc	a2,0x3
ffffffffc0202aac:	e2860613          	addi	a2,a2,-472 # ffffffffc02058d0 <commands+0x728>
ffffffffc0202ab0:	11200593          	li	a1,274
ffffffffc0202ab4:	00004517          	auipc	a0,0x4
ffffffffc0202ab8:	82c50513          	addi	a0,a0,-2004 # ffffffffc02062e0 <commands+0x1138>
ffffffffc0202abc:	f0cfd0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0202ac0:	00004697          	auipc	a3,0x4
ffffffffc0202ac4:	ab068693          	addi	a3,a3,-1360 # ffffffffc0206570 <commands+0x13c8>
ffffffffc0202ac8:	00003617          	auipc	a2,0x3
ffffffffc0202acc:	e0860613          	addi	a2,a2,-504 # ffffffffc02058d0 <commands+0x728>
ffffffffc0202ad0:	11000593          	li	a1,272
ffffffffc0202ad4:	00004517          	auipc	a0,0x4
ffffffffc0202ad8:	80c50513          	addi	a0,a0,-2036 # ffffffffc02062e0 <commands+0x1138>
ffffffffc0202adc:	eecfd0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0202ae0:	00004697          	auipc	a3,0x4
ffffffffc0202ae4:	a6868693          	addi	a3,a3,-1432 # ffffffffc0206548 <commands+0x13a0>
ffffffffc0202ae8:	00003617          	auipc	a2,0x3
ffffffffc0202aec:	de860613          	addi	a2,a2,-536 # ffffffffc02058d0 <commands+0x728>
ffffffffc0202af0:	10e00593          	li	a1,270
ffffffffc0202af4:	00003517          	auipc	a0,0x3
ffffffffc0202af8:	7ec50513          	addi	a0,a0,2028 # ffffffffc02062e0 <commands+0x1138>
ffffffffc0202afc:	eccfd0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0202b00:	00004697          	auipc	a3,0x4
ffffffffc0202b04:	a2068693          	addi	a3,a3,-1504 # ffffffffc0206520 <commands+0x1378>
ffffffffc0202b08:	00003617          	auipc	a2,0x3
ffffffffc0202b0c:	dc860613          	addi	a2,a2,-568 # ffffffffc02058d0 <commands+0x728>
ffffffffc0202b10:	10d00593          	li	a1,269
ffffffffc0202b14:	00003517          	auipc	a0,0x3
ffffffffc0202b18:	7cc50513          	addi	a0,a0,1996 # ffffffffc02062e0 <commands+0x1138>
ffffffffc0202b1c:	eacfd0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(p0 + 2 == p1);
ffffffffc0202b20:	00004697          	auipc	a3,0x4
ffffffffc0202b24:	9f068693          	addi	a3,a3,-1552 # ffffffffc0206510 <commands+0x1368>
ffffffffc0202b28:	00003617          	auipc	a2,0x3
ffffffffc0202b2c:	da860613          	addi	a2,a2,-600 # ffffffffc02058d0 <commands+0x728>
ffffffffc0202b30:	10800593          	li	a1,264
ffffffffc0202b34:	00003517          	auipc	a0,0x3
ffffffffc0202b38:	7ac50513          	addi	a0,a0,1964 # ffffffffc02062e0 <commands+0x1138>
ffffffffc0202b3c:	e8cfd0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0202b40:	00004697          	auipc	a3,0x4
ffffffffc0202b44:	8e068693          	addi	a3,a3,-1824 # ffffffffc0206420 <commands+0x1278>
ffffffffc0202b48:	00003617          	auipc	a2,0x3
ffffffffc0202b4c:	d8860613          	addi	a2,a2,-632 # ffffffffc02058d0 <commands+0x728>
ffffffffc0202b50:	10700593          	li	a1,263
ffffffffc0202b54:	00003517          	auipc	a0,0x3
ffffffffc0202b58:	78c50513          	addi	a0,a0,1932 # ffffffffc02062e0 <commands+0x1138>
ffffffffc0202b5c:	e6cfd0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0202b60:	00004697          	auipc	a3,0x4
ffffffffc0202b64:	99068693          	addi	a3,a3,-1648 # ffffffffc02064f0 <commands+0x1348>
ffffffffc0202b68:	00003617          	auipc	a2,0x3
ffffffffc0202b6c:	d6860613          	addi	a2,a2,-664 # ffffffffc02058d0 <commands+0x728>
ffffffffc0202b70:	10600593          	li	a1,262
ffffffffc0202b74:	00003517          	auipc	a0,0x3
ffffffffc0202b78:	76c50513          	addi	a0,a0,1900 # ffffffffc02062e0 <commands+0x1138>
ffffffffc0202b7c:	e4cfd0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0202b80:	00004697          	auipc	a3,0x4
ffffffffc0202b84:	94068693          	addi	a3,a3,-1728 # ffffffffc02064c0 <commands+0x1318>
ffffffffc0202b88:	00003617          	auipc	a2,0x3
ffffffffc0202b8c:	d4860613          	addi	a2,a2,-696 # ffffffffc02058d0 <commands+0x728>
ffffffffc0202b90:	10500593          	li	a1,261
ffffffffc0202b94:	00003517          	auipc	a0,0x3
ffffffffc0202b98:	74c50513          	addi	a0,a0,1868 # ffffffffc02062e0 <commands+0x1138>
ffffffffc0202b9c:	e2cfd0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0202ba0:	00004697          	auipc	a3,0x4
ffffffffc0202ba4:	90868693          	addi	a3,a3,-1784 # ffffffffc02064a8 <commands+0x1300>
ffffffffc0202ba8:	00003617          	auipc	a2,0x3
ffffffffc0202bac:	d2860613          	addi	a2,a2,-728 # ffffffffc02058d0 <commands+0x728>
ffffffffc0202bb0:	10400593          	li	a1,260
ffffffffc0202bb4:	00003517          	auipc	a0,0x3
ffffffffc0202bb8:	72c50513          	addi	a0,a0,1836 # ffffffffc02062e0 <commands+0x1138>
ffffffffc0202bbc:	e0cfd0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0202bc0:	00004697          	auipc	a3,0x4
ffffffffc0202bc4:	86068693          	addi	a3,a3,-1952 # ffffffffc0206420 <commands+0x1278>
ffffffffc0202bc8:	00003617          	auipc	a2,0x3
ffffffffc0202bcc:	d0860613          	addi	a2,a2,-760 # ffffffffc02058d0 <commands+0x728>
ffffffffc0202bd0:	0fe00593          	li	a1,254
ffffffffc0202bd4:	00003517          	auipc	a0,0x3
ffffffffc0202bd8:	70c50513          	addi	a0,a0,1804 # ffffffffc02062e0 <commands+0x1138>
ffffffffc0202bdc:	decfd0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(!PageProperty(p0));
ffffffffc0202be0:	00004697          	auipc	a3,0x4
ffffffffc0202be4:	8b068693          	addi	a3,a3,-1872 # ffffffffc0206490 <commands+0x12e8>
ffffffffc0202be8:	00003617          	auipc	a2,0x3
ffffffffc0202bec:	ce860613          	addi	a2,a2,-792 # ffffffffc02058d0 <commands+0x728>
ffffffffc0202bf0:	0f900593          	li	a1,249
ffffffffc0202bf4:	00003517          	auipc	a0,0x3
ffffffffc0202bf8:	6ec50513          	addi	a0,a0,1772 # ffffffffc02062e0 <commands+0x1138>
ffffffffc0202bfc:	dccfd0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0202c00:	00004697          	auipc	a3,0x4
ffffffffc0202c04:	9b068693          	addi	a3,a3,-1616 # ffffffffc02065b0 <commands+0x1408>
ffffffffc0202c08:	00003617          	auipc	a2,0x3
ffffffffc0202c0c:	cc860613          	addi	a2,a2,-824 # ffffffffc02058d0 <commands+0x728>
ffffffffc0202c10:	11700593          	li	a1,279
ffffffffc0202c14:	00003517          	auipc	a0,0x3
ffffffffc0202c18:	6cc50513          	addi	a0,a0,1740 # ffffffffc02062e0 <commands+0x1138>
ffffffffc0202c1c:	dacfd0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(total == 0);
ffffffffc0202c20:	00004697          	auipc	a3,0x4
ffffffffc0202c24:	9c068693          	addi	a3,a3,-1600 # ffffffffc02065e0 <commands+0x1438>
ffffffffc0202c28:	00003617          	auipc	a2,0x3
ffffffffc0202c2c:	ca860613          	addi	a2,a2,-856 # ffffffffc02058d0 <commands+0x728>
ffffffffc0202c30:	12600593          	li	a1,294
ffffffffc0202c34:	00003517          	auipc	a0,0x3
ffffffffc0202c38:	6ac50513          	addi	a0,a0,1708 # ffffffffc02062e0 <commands+0x1138>
ffffffffc0202c3c:	d8cfd0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(total == nr_free_pages());
ffffffffc0202c40:	00003697          	auipc	a3,0x3
ffffffffc0202c44:	33868693          	addi	a3,a3,824 # ffffffffc0205f78 <commands+0xdd0>
ffffffffc0202c48:	00003617          	auipc	a2,0x3
ffffffffc0202c4c:	c8860613          	addi	a2,a2,-888 # ffffffffc02058d0 <commands+0x728>
ffffffffc0202c50:	0f300593          	li	a1,243
ffffffffc0202c54:	00003517          	auipc	a0,0x3
ffffffffc0202c58:	68c50513          	addi	a0,a0,1676 # ffffffffc02062e0 <commands+0x1138>
ffffffffc0202c5c:	d6cfd0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0202c60:	00003697          	auipc	a3,0x3
ffffffffc0202c64:	6b868693          	addi	a3,a3,1720 # ffffffffc0206318 <commands+0x1170>
ffffffffc0202c68:	00003617          	auipc	a2,0x3
ffffffffc0202c6c:	c6860613          	addi	a2,a2,-920 # ffffffffc02058d0 <commands+0x728>
ffffffffc0202c70:	0ba00593          	li	a1,186
ffffffffc0202c74:	00003517          	auipc	a0,0x3
ffffffffc0202c78:	66c50513          	addi	a0,a0,1644 # ffffffffc02062e0 <commands+0x1138>
ffffffffc0202c7c:	d4cfd0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc0202c80 <default_free_pages>:
default_free_pages(struct Page *base, size_t n) {
ffffffffc0202c80:	1141                	addi	sp,sp,-16
ffffffffc0202c82:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0202c84:	14058463          	beqz	a1,ffffffffc0202dcc <default_free_pages+0x14c>
    for (; p != base + n; p ++) {
ffffffffc0202c88:	00659693          	slli	a3,a1,0x6
ffffffffc0202c8c:	96aa                	add	a3,a3,a0
ffffffffc0202c8e:	87aa                	mv	a5,a0
ffffffffc0202c90:	02d50263          	beq	a0,a3,ffffffffc0202cb4 <default_free_pages+0x34>
ffffffffc0202c94:	6798                	ld	a4,8(a5)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0202c96:	8b05                	andi	a4,a4,1
ffffffffc0202c98:	10071a63          	bnez	a4,ffffffffc0202dac <default_free_pages+0x12c>
ffffffffc0202c9c:	6798                	ld	a4,8(a5)
ffffffffc0202c9e:	8b09                	andi	a4,a4,2
ffffffffc0202ca0:	10071663          	bnez	a4,ffffffffc0202dac <default_free_pages+0x12c>
        p->flags = 0;
ffffffffc0202ca4:	0007b423          	sd	zero,8(a5)
    page->ref = val;
ffffffffc0202ca8:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0202cac:	04078793          	addi	a5,a5,64
ffffffffc0202cb0:	fed792e3          	bne	a5,a3,ffffffffc0202c94 <default_free_pages+0x14>
    base->property = n;
ffffffffc0202cb4:	2581                	sext.w	a1,a1
ffffffffc0202cb6:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0202cb8:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0202cbc:	4789                	li	a5,2
ffffffffc0202cbe:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc0202cc2:	00010697          	auipc	a3,0x10
ffffffffc0202cc6:	83e68693          	addi	a3,a3,-1986 # ffffffffc0212500 <free_area>
ffffffffc0202cca:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0202ccc:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc0202cce:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc0202cd2:	9db9                	addw	a1,a1,a4
ffffffffc0202cd4:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc0202cd6:	0ad78463          	beq	a5,a3,ffffffffc0202d7e <default_free_pages+0xfe>
            struct Page* page = le2page(le, page_link);
ffffffffc0202cda:	fe878713          	addi	a4,a5,-24
ffffffffc0202cde:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc0202ce2:	4581                	li	a1,0
            if (base < page) {
ffffffffc0202ce4:	00e56a63          	bltu	a0,a4,ffffffffc0202cf8 <default_free_pages+0x78>
    return listelm->next;
ffffffffc0202ce8:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0202cea:	04d70c63          	beq	a4,a3,ffffffffc0202d42 <default_free_pages+0xc2>
    for (; p != base + n; p ++) {
ffffffffc0202cee:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0202cf0:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc0202cf4:	fee57ae3          	bgeu	a0,a4,ffffffffc0202ce8 <default_free_pages+0x68>
ffffffffc0202cf8:	c199                	beqz	a1,ffffffffc0202cfe <default_free_pages+0x7e>
ffffffffc0202cfa:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0202cfe:	6398                	ld	a4,0(a5)
    prev->next = next->prev = elm;
ffffffffc0202d00:	e390                	sd	a2,0(a5)
ffffffffc0202d02:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0202d04:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0202d06:	ed18                	sd	a4,24(a0)
    if (le != &free_list) {
ffffffffc0202d08:	00d70d63          	beq	a4,a3,ffffffffc0202d22 <default_free_pages+0xa2>
        if (p + p->property == base) {
ffffffffc0202d0c:	ff872583          	lw	a1,-8(a4)
        p = le2page(le, page_link);
ffffffffc0202d10:	fe870613          	addi	a2,a4,-24
        if (p + p->property == base) {
ffffffffc0202d14:	02059813          	slli	a6,a1,0x20
ffffffffc0202d18:	01a85793          	srli	a5,a6,0x1a
ffffffffc0202d1c:	97b2                	add	a5,a5,a2
ffffffffc0202d1e:	02f50c63          	beq	a0,a5,ffffffffc0202d56 <default_free_pages+0xd6>
    return listelm->next;
ffffffffc0202d22:	711c                	ld	a5,32(a0)
    if (le != &free_list) {
ffffffffc0202d24:	00d78c63          	beq	a5,a3,ffffffffc0202d3c <default_free_pages+0xbc>
        if (base + base->property == p) {
ffffffffc0202d28:	4910                	lw	a2,16(a0)
        p = le2page(le, page_link);
ffffffffc0202d2a:	fe878693          	addi	a3,a5,-24
        if (base + base->property == p) {
ffffffffc0202d2e:	02061593          	slli	a1,a2,0x20
ffffffffc0202d32:	01a5d713          	srli	a4,a1,0x1a
ffffffffc0202d36:	972a                	add	a4,a4,a0
ffffffffc0202d38:	04e68a63          	beq	a3,a4,ffffffffc0202d8c <default_free_pages+0x10c>
}
ffffffffc0202d3c:	60a2                	ld	ra,8(sp)
ffffffffc0202d3e:	0141                	addi	sp,sp,16
ffffffffc0202d40:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0202d42:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0202d44:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0202d46:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0202d48:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc0202d4a:	02d70763          	beq	a4,a3,ffffffffc0202d78 <default_free_pages+0xf8>
    prev->next = next->prev = elm;
ffffffffc0202d4e:	8832                	mv	a6,a2
ffffffffc0202d50:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc0202d52:	87ba                	mv	a5,a4
ffffffffc0202d54:	bf71                	j	ffffffffc0202cf0 <default_free_pages+0x70>
            p->property += base->property;
ffffffffc0202d56:	491c                	lw	a5,16(a0)
ffffffffc0202d58:	9dbd                	addw	a1,a1,a5
ffffffffc0202d5a:	feb72c23          	sw	a1,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0202d5e:	57f5                	li	a5,-3
ffffffffc0202d60:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc0202d64:	01853803          	ld	a6,24(a0)
ffffffffc0202d68:	710c                	ld	a1,32(a0)
            base = p;
ffffffffc0202d6a:	8532                	mv	a0,a2
    prev->next = next;
ffffffffc0202d6c:	00b83423          	sd	a1,8(a6)
    return listelm->next;
ffffffffc0202d70:	671c                	ld	a5,8(a4)
    next->prev = prev;
ffffffffc0202d72:	0105b023          	sd	a6,0(a1) # 1000 <kern_entry-0xffffffffc01ff000>
ffffffffc0202d76:	b77d                	j	ffffffffc0202d24 <default_free_pages+0xa4>
ffffffffc0202d78:	e290                	sd	a2,0(a3)
        while ((le = list_next(le)) != &free_list) {
ffffffffc0202d7a:	873e                	mv	a4,a5
ffffffffc0202d7c:	bf41                	j	ffffffffc0202d0c <default_free_pages+0x8c>
}
ffffffffc0202d7e:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0202d80:	e390                	sd	a2,0(a5)
ffffffffc0202d82:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0202d84:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0202d86:	ed1c                	sd	a5,24(a0)
ffffffffc0202d88:	0141                	addi	sp,sp,16
ffffffffc0202d8a:	8082                	ret
            base->property += p->property;
ffffffffc0202d8c:	ff87a703          	lw	a4,-8(a5)
ffffffffc0202d90:	ff078693          	addi	a3,a5,-16
ffffffffc0202d94:	9e39                	addw	a2,a2,a4
ffffffffc0202d96:	c910                	sw	a2,16(a0)
ffffffffc0202d98:	5775                	li	a4,-3
ffffffffc0202d9a:	60e6b02f          	amoand.d	zero,a4,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc0202d9e:	6398                	ld	a4,0(a5)
ffffffffc0202da0:	679c                	ld	a5,8(a5)
}
ffffffffc0202da2:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0202da4:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0202da6:	e398                	sd	a4,0(a5)
ffffffffc0202da8:	0141                	addi	sp,sp,16
ffffffffc0202daa:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0202dac:	00004697          	auipc	a3,0x4
ffffffffc0202db0:	84c68693          	addi	a3,a3,-1972 # ffffffffc02065f8 <commands+0x1450>
ffffffffc0202db4:	00003617          	auipc	a2,0x3
ffffffffc0202db8:	b1c60613          	addi	a2,a2,-1252 # ffffffffc02058d0 <commands+0x728>
ffffffffc0202dbc:	08300593          	li	a1,131
ffffffffc0202dc0:	00003517          	auipc	a0,0x3
ffffffffc0202dc4:	52050513          	addi	a0,a0,1312 # ffffffffc02062e0 <commands+0x1138>
ffffffffc0202dc8:	c00fd0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(n > 0);
ffffffffc0202dcc:	00004697          	auipc	a3,0x4
ffffffffc0202dd0:	82468693          	addi	a3,a3,-2012 # ffffffffc02065f0 <commands+0x1448>
ffffffffc0202dd4:	00003617          	auipc	a2,0x3
ffffffffc0202dd8:	afc60613          	addi	a2,a2,-1284 # ffffffffc02058d0 <commands+0x728>
ffffffffc0202ddc:	08000593          	li	a1,128
ffffffffc0202de0:	00003517          	auipc	a0,0x3
ffffffffc0202de4:	50050513          	addi	a0,a0,1280 # ffffffffc02062e0 <commands+0x1138>
ffffffffc0202de8:	be0fd0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc0202dec <default_alloc_pages>:
    assert(n > 0);
ffffffffc0202dec:	c941                	beqz	a0,ffffffffc0202e7c <default_alloc_pages+0x90>
    if (n > nr_free) {
ffffffffc0202dee:	0000f597          	auipc	a1,0xf
ffffffffc0202df2:	71258593          	addi	a1,a1,1810 # ffffffffc0212500 <free_area>
ffffffffc0202df6:	0105a803          	lw	a6,16(a1)
ffffffffc0202dfa:	872a                	mv	a4,a0
ffffffffc0202dfc:	02081793          	slli	a5,a6,0x20
ffffffffc0202e00:	9381                	srli	a5,a5,0x20
ffffffffc0202e02:	00a7ee63          	bltu	a5,a0,ffffffffc0202e1e <default_alloc_pages+0x32>
    list_entry_t *le = &free_list;
ffffffffc0202e06:	87ae                	mv	a5,a1
ffffffffc0202e08:	a801                	j	ffffffffc0202e18 <default_alloc_pages+0x2c>
        if (p->property >= n) {
ffffffffc0202e0a:	ff87a683          	lw	a3,-8(a5)
ffffffffc0202e0e:	02069613          	slli	a2,a3,0x20
ffffffffc0202e12:	9201                	srli	a2,a2,0x20
ffffffffc0202e14:	00e67763          	bgeu	a2,a4,ffffffffc0202e22 <default_alloc_pages+0x36>
    return listelm->next;
ffffffffc0202e18:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc0202e1a:	feb798e3          	bne	a5,a1,ffffffffc0202e0a <default_alloc_pages+0x1e>
        return NULL;
ffffffffc0202e1e:	4501                	li	a0,0
}
ffffffffc0202e20:	8082                	ret
    return listelm->prev;
ffffffffc0202e22:	0007b883          	ld	a7,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc0202e26:	0087b303          	ld	t1,8(a5)
        struct Page *p = le2page(le, page_link);
ffffffffc0202e2a:	fe878513          	addi	a0,a5,-24
            p->property = page->property - n;
ffffffffc0202e2e:	00070e1b          	sext.w	t3,a4
    prev->next = next;
ffffffffc0202e32:	0068b423          	sd	t1,8(a7)
    next->prev = prev;
ffffffffc0202e36:	01133023          	sd	a7,0(t1)
        if (page->property > n) {
ffffffffc0202e3a:	02c77863          	bgeu	a4,a2,ffffffffc0202e6a <default_alloc_pages+0x7e>
            struct Page *p = page + n;
ffffffffc0202e3e:	071a                	slli	a4,a4,0x6
ffffffffc0202e40:	972a                	add	a4,a4,a0
            p->property = page->property - n;
ffffffffc0202e42:	41c686bb          	subw	a3,a3,t3
ffffffffc0202e46:	cb14                	sw	a3,16(a4)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0202e48:	00870613          	addi	a2,a4,8
ffffffffc0202e4c:	4689                	li	a3,2
ffffffffc0202e4e:	40d6302f          	amoor.d	zero,a3,(a2)
    __list_add(elm, listelm, listelm->next);
ffffffffc0202e52:	0088b683          	ld	a3,8(a7)
            list_add(prev, &(p->page_link));
ffffffffc0202e56:	01870613          	addi	a2,a4,24
        nr_free -= n;
ffffffffc0202e5a:	0105a803          	lw	a6,16(a1)
    prev->next = next->prev = elm;
ffffffffc0202e5e:	e290                	sd	a2,0(a3)
ffffffffc0202e60:	00c8b423          	sd	a2,8(a7)
    elm->next = next;
ffffffffc0202e64:	f314                	sd	a3,32(a4)
    elm->prev = prev;
ffffffffc0202e66:	01173c23          	sd	a7,24(a4)
ffffffffc0202e6a:	41c8083b          	subw	a6,a6,t3
ffffffffc0202e6e:	0105a823          	sw	a6,16(a1)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0202e72:	5775                	li	a4,-3
ffffffffc0202e74:	17c1                	addi	a5,a5,-16
ffffffffc0202e76:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc0202e7a:	8082                	ret
default_alloc_pages(size_t n) {
ffffffffc0202e7c:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0202e7e:	00003697          	auipc	a3,0x3
ffffffffc0202e82:	77268693          	addi	a3,a3,1906 # ffffffffc02065f0 <commands+0x1448>
ffffffffc0202e86:	00003617          	auipc	a2,0x3
ffffffffc0202e8a:	a4a60613          	addi	a2,a2,-1462 # ffffffffc02058d0 <commands+0x728>
ffffffffc0202e8e:	06200593          	li	a1,98
ffffffffc0202e92:	00003517          	auipc	a0,0x3
ffffffffc0202e96:	44e50513          	addi	a0,a0,1102 # ffffffffc02062e0 <commands+0x1138>
default_alloc_pages(size_t n) {
ffffffffc0202e9a:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0202e9c:	b2cfd0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc0202ea0 <default_init_memmap>:
default_init_memmap(struct Page *base, size_t n) {
ffffffffc0202ea0:	1141                	addi	sp,sp,-16
ffffffffc0202ea2:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0202ea4:	c5f1                	beqz	a1,ffffffffc0202f70 <default_init_memmap+0xd0>
    for (; p != base + n; p ++) {
ffffffffc0202ea6:	00659693          	slli	a3,a1,0x6
ffffffffc0202eaa:	96aa                	add	a3,a3,a0
ffffffffc0202eac:	87aa                	mv	a5,a0
ffffffffc0202eae:	00d50f63          	beq	a0,a3,ffffffffc0202ecc <default_init_memmap+0x2c>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0202eb2:	6798                	ld	a4,8(a5)
        assert(PageReserved(p));
ffffffffc0202eb4:	8b05                	andi	a4,a4,1
ffffffffc0202eb6:	cf49                	beqz	a4,ffffffffc0202f50 <default_init_memmap+0xb0>
        p->flags = p->property = 0;
ffffffffc0202eb8:	0007a823          	sw	zero,16(a5)
ffffffffc0202ebc:	0007b423          	sd	zero,8(a5)
ffffffffc0202ec0:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0202ec4:	04078793          	addi	a5,a5,64
ffffffffc0202ec8:	fed795e3          	bne	a5,a3,ffffffffc0202eb2 <default_init_memmap+0x12>
    base->property = n;
ffffffffc0202ecc:	2581                	sext.w	a1,a1
ffffffffc0202ece:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0202ed0:	4789                	li	a5,2
ffffffffc0202ed2:	00850713          	addi	a4,a0,8
ffffffffc0202ed6:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc0202eda:	0000f697          	auipc	a3,0xf
ffffffffc0202ede:	62668693          	addi	a3,a3,1574 # ffffffffc0212500 <free_area>
ffffffffc0202ee2:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0202ee4:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc0202ee6:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc0202eea:	9db9                	addw	a1,a1,a4
ffffffffc0202eec:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc0202eee:	04d78a63          	beq	a5,a3,ffffffffc0202f42 <default_init_memmap+0xa2>
            struct Page* page = le2page(le, page_link);
ffffffffc0202ef2:	fe878713          	addi	a4,a5,-24
ffffffffc0202ef6:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc0202efa:	4581                	li	a1,0
            if (base < page) {
ffffffffc0202efc:	00e56a63          	bltu	a0,a4,ffffffffc0202f10 <default_init_memmap+0x70>
    return listelm->next;
ffffffffc0202f00:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0202f02:	02d70263          	beq	a4,a3,ffffffffc0202f26 <default_init_memmap+0x86>
    for (; p != base + n; p ++) {
ffffffffc0202f06:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0202f08:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc0202f0c:	fee57ae3          	bgeu	a0,a4,ffffffffc0202f00 <default_init_memmap+0x60>
ffffffffc0202f10:	c199                	beqz	a1,ffffffffc0202f16 <default_init_memmap+0x76>
ffffffffc0202f12:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0202f16:	6398                	ld	a4,0(a5)
}
ffffffffc0202f18:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0202f1a:	e390                	sd	a2,0(a5)
ffffffffc0202f1c:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0202f1e:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0202f20:	ed18                	sd	a4,24(a0)
ffffffffc0202f22:	0141                	addi	sp,sp,16
ffffffffc0202f24:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0202f26:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0202f28:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0202f2a:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0202f2c:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc0202f2e:	00d70663          	beq	a4,a3,ffffffffc0202f3a <default_init_memmap+0x9a>
    prev->next = next->prev = elm;
ffffffffc0202f32:	8832                	mv	a6,a2
ffffffffc0202f34:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc0202f36:	87ba                	mv	a5,a4
ffffffffc0202f38:	bfc1                	j	ffffffffc0202f08 <default_init_memmap+0x68>
}
ffffffffc0202f3a:	60a2                	ld	ra,8(sp)
ffffffffc0202f3c:	e290                	sd	a2,0(a3)
ffffffffc0202f3e:	0141                	addi	sp,sp,16
ffffffffc0202f40:	8082                	ret
ffffffffc0202f42:	60a2                	ld	ra,8(sp)
ffffffffc0202f44:	e390                	sd	a2,0(a5)
ffffffffc0202f46:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0202f48:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0202f4a:	ed1c                	sd	a5,24(a0)
ffffffffc0202f4c:	0141                	addi	sp,sp,16
ffffffffc0202f4e:	8082                	ret
        assert(PageReserved(p));
ffffffffc0202f50:	00003697          	auipc	a3,0x3
ffffffffc0202f54:	6d068693          	addi	a3,a3,1744 # ffffffffc0206620 <commands+0x1478>
ffffffffc0202f58:	00003617          	auipc	a2,0x3
ffffffffc0202f5c:	97860613          	addi	a2,a2,-1672 # ffffffffc02058d0 <commands+0x728>
ffffffffc0202f60:	04900593          	li	a1,73
ffffffffc0202f64:	00003517          	auipc	a0,0x3
ffffffffc0202f68:	37c50513          	addi	a0,a0,892 # ffffffffc02062e0 <commands+0x1138>
ffffffffc0202f6c:	a5cfd0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(n > 0);
ffffffffc0202f70:	00003697          	auipc	a3,0x3
ffffffffc0202f74:	68068693          	addi	a3,a3,1664 # ffffffffc02065f0 <commands+0x1448>
ffffffffc0202f78:	00003617          	auipc	a2,0x3
ffffffffc0202f7c:	95860613          	addi	a2,a2,-1704 # ffffffffc02058d0 <commands+0x728>
ffffffffc0202f80:	04600593          	li	a1,70
ffffffffc0202f84:	00003517          	auipc	a0,0x3
ffffffffc0202f88:	35c50513          	addi	a0,a0,860 # ffffffffc02062e0 <commands+0x1138>
ffffffffc0202f8c:	a3cfd0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc0202f90 <pa2page.part.0>:
pa2page(uintptr_t pa) {
ffffffffc0202f90:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc0202f92:	00003617          	auipc	a2,0x3
ffffffffc0202f96:	b6660613          	addi	a2,a2,-1178 # ffffffffc0205af8 <commands+0x950>
ffffffffc0202f9a:	06200593          	li	a1,98
ffffffffc0202f9e:	00003517          	auipc	a0,0x3
ffffffffc0202fa2:	b7a50513          	addi	a0,a0,-1158 # ffffffffc0205b18 <commands+0x970>
pa2page(uintptr_t pa) {
ffffffffc0202fa6:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc0202fa8:	a20fd0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc0202fac <pte2page.part.0>:
pte2page(pte_t pte) {
ffffffffc0202fac:	1141                	addi	sp,sp,-16
        panic("pte2page called with invalid pte");
ffffffffc0202fae:	00003617          	auipc	a2,0x3
ffffffffc0202fb2:	18260613          	addi	a2,a2,386 # ffffffffc0206130 <commands+0xf88>
ffffffffc0202fb6:	07400593          	li	a1,116
ffffffffc0202fba:	00003517          	auipc	a0,0x3
ffffffffc0202fbe:	b5e50513          	addi	a0,a0,-1186 # ffffffffc0205b18 <commands+0x970>
pte2page(pte_t pte) {
ffffffffc0202fc2:	e406                	sd	ra,8(sp)
        panic("pte2page called with invalid pte");
ffffffffc0202fc4:	a04fd0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc0202fc8 <alloc_pages>:
    pmm_manager->init_memmap(base, n);
}

// alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE
// memory
struct Page *alloc_pages(size_t n) {
ffffffffc0202fc8:	7139                	addi	sp,sp,-64
ffffffffc0202fca:	f426                	sd	s1,40(sp)
ffffffffc0202fcc:	f04a                	sd	s2,32(sp)
ffffffffc0202fce:	ec4e                	sd	s3,24(sp)
ffffffffc0202fd0:	e852                	sd	s4,16(sp)
ffffffffc0202fd2:	e456                	sd	s5,8(sp)
ffffffffc0202fd4:	e05a                	sd	s6,0(sp)
ffffffffc0202fd6:	fc06                	sd	ra,56(sp)
ffffffffc0202fd8:	f822                	sd	s0,48(sp)
ffffffffc0202fda:	84aa                	mv	s1,a0
ffffffffc0202fdc:	00013917          	auipc	s2,0x13
ffffffffc0202fe0:	5c490913          	addi	s2,s2,1476 # ffffffffc02165a0 <pmm_manager>
        {
            page = pmm_manager->alloc_pages(n);
        }
        local_intr_restore(intr_flag);

        if (page != NULL || n > 1 || swap_init_ok == 0) break;
ffffffffc0202fe4:	4a05                	li	s4,1
ffffffffc0202fe6:	00013a97          	auipc	s5,0x13
ffffffffc0202fea:	592a8a93          	addi	s5,s5,1426 # ffffffffc0216578 <swap_init_ok>

        extern struct mm_struct *check_mm_struct;
        // cprintf("page %x, call swap_out in alloc_pages %d\n",page, n);
        swap_out(check_mm_struct, n, 0);
ffffffffc0202fee:	0005099b          	sext.w	s3,a0
ffffffffc0202ff2:	00013b17          	auipc	s6,0x13
ffffffffc0202ff6:	55eb0b13          	addi	s6,s6,1374 # ffffffffc0216550 <check_mm_struct>
ffffffffc0202ffa:	a01d                	j	ffffffffc0203020 <alloc_pages+0x58>
            page = pmm_manager->alloc_pages(n);
ffffffffc0202ffc:	00093783          	ld	a5,0(s2)
ffffffffc0203000:	6f9c                	ld	a5,24(a5)
ffffffffc0203002:	9782                	jalr	a5
ffffffffc0203004:	842a                	mv	s0,a0
        swap_out(check_mm_struct, n, 0);
ffffffffc0203006:	4601                	li	a2,0
ffffffffc0203008:	85ce                	mv	a1,s3
        if (page != NULL || n > 1 || swap_init_ok == 0) break;
ffffffffc020300a:	ec0d                	bnez	s0,ffffffffc0203044 <alloc_pages+0x7c>
ffffffffc020300c:	029a6c63          	bltu	s4,s1,ffffffffc0203044 <alloc_pages+0x7c>
ffffffffc0203010:	000aa783          	lw	a5,0(s5)
ffffffffc0203014:	2781                	sext.w	a5,a5
ffffffffc0203016:	c79d                	beqz	a5,ffffffffc0203044 <alloc_pages+0x7c>
        swap_out(check_mm_struct, n, 0);
ffffffffc0203018:	000b3503          	ld	a0,0(s6)
ffffffffc020301c:	b38ff0ef          	jal	ra,ffffffffc0202354 <swap_out>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0203020:	100027f3          	csrr	a5,sstatus
ffffffffc0203024:	8b89                	andi	a5,a5,2
            page = pmm_manager->alloc_pages(n);
ffffffffc0203026:	8526                	mv	a0,s1
ffffffffc0203028:	dbf1                	beqz	a5,ffffffffc0202ffc <alloc_pages+0x34>
        intr_disable();
ffffffffc020302a:	d9afd0ef          	jal	ra,ffffffffc02005c4 <intr_disable>
ffffffffc020302e:	00093783          	ld	a5,0(s2)
ffffffffc0203032:	8526                	mv	a0,s1
ffffffffc0203034:	6f9c                	ld	a5,24(a5)
ffffffffc0203036:	9782                	jalr	a5
ffffffffc0203038:	842a                	mv	s0,a0
        intr_enable();
ffffffffc020303a:	d84fd0ef          	jal	ra,ffffffffc02005be <intr_enable>
        swap_out(check_mm_struct, n, 0);
ffffffffc020303e:	4601                	li	a2,0
ffffffffc0203040:	85ce                	mv	a1,s3
        if (page != NULL || n > 1 || swap_init_ok == 0) break;
ffffffffc0203042:	d469                	beqz	s0,ffffffffc020300c <alloc_pages+0x44>
    }
    // cprintf("n %d,get page %x, No %d in alloc_pages\n",n,page,(page-pages));
    return page;
}
ffffffffc0203044:	70e2                	ld	ra,56(sp)
ffffffffc0203046:	8522                	mv	a0,s0
ffffffffc0203048:	7442                	ld	s0,48(sp)
ffffffffc020304a:	74a2                	ld	s1,40(sp)
ffffffffc020304c:	7902                	ld	s2,32(sp)
ffffffffc020304e:	69e2                	ld	s3,24(sp)
ffffffffc0203050:	6a42                	ld	s4,16(sp)
ffffffffc0203052:	6aa2                	ld	s5,8(sp)
ffffffffc0203054:	6b02                	ld	s6,0(sp)
ffffffffc0203056:	6121                	addi	sp,sp,64
ffffffffc0203058:	8082                	ret

ffffffffc020305a <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020305a:	100027f3          	csrr	a5,sstatus
ffffffffc020305e:	8b89                	andi	a5,a5,2
ffffffffc0203060:	e799                	bnez	a5,ffffffffc020306e <free_pages+0x14>
// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0203062:	00013797          	auipc	a5,0x13
ffffffffc0203066:	53e7b783          	ld	a5,1342(a5) # ffffffffc02165a0 <pmm_manager>
ffffffffc020306a:	739c                	ld	a5,32(a5)
ffffffffc020306c:	8782                	jr	a5
void free_pages(struct Page *base, size_t n) {
ffffffffc020306e:	1101                	addi	sp,sp,-32
ffffffffc0203070:	ec06                	sd	ra,24(sp)
ffffffffc0203072:	e822                	sd	s0,16(sp)
ffffffffc0203074:	e426                	sd	s1,8(sp)
ffffffffc0203076:	842a                	mv	s0,a0
ffffffffc0203078:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc020307a:	d4afd0ef          	jal	ra,ffffffffc02005c4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc020307e:	00013797          	auipc	a5,0x13
ffffffffc0203082:	5227b783          	ld	a5,1314(a5) # ffffffffc02165a0 <pmm_manager>
ffffffffc0203086:	739c                	ld	a5,32(a5)
ffffffffc0203088:	85a6                	mv	a1,s1
ffffffffc020308a:	8522                	mv	a0,s0
ffffffffc020308c:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc020308e:	6442                	ld	s0,16(sp)
ffffffffc0203090:	60e2                	ld	ra,24(sp)
ffffffffc0203092:	64a2                	ld	s1,8(sp)
ffffffffc0203094:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0203096:	d28fd06f          	j	ffffffffc02005be <intr_enable>

ffffffffc020309a <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020309a:	100027f3          	csrr	a5,sstatus
ffffffffc020309e:	8b89                	andi	a5,a5,2
ffffffffc02030a0:	e799                	bnez	a5,ffffffffc02030ae <nr_free_pages+0x14>
size_t nr_free_pages(void) {
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc02030a2:	00013797          	auipc	a5,0x13
ffffffffc02030a6:	4fe7b783          	ld	a5,1278(a5) # ffffffffc02165a0 <pmm_manager>
ffffffffc02030aa:	779c                	ld	a5,40(a5)
ffffffffc02030ac:	8782                	jr	a5
size_t nr_free_pages(void) {
ffffffffc02030ae:	1141                	addi	sp,sp,-16
ffffffffc02030b0:	e406                	sd	ra,8(sp)
ffffffffc02030b2:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc02030b4:	d10fd0ef          	jal	ra,ffffffffc02005c4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc02030b8:	00013797          	auipc	a5,0x13
ffffffffc02030bc:	4e87b783          	ld	a5,1256(a5) # ffffffffc02165a0 <pmm_manager>
ffffffffc02030c0:	779c                	ld	a5,40(a5)
ffffffffc02030c2:	9782                	jalr	a5
ffffffffc02030c4:	842a                	mv	s0,a0
        intr_enable();
ffffffffc02030c6:	cf8fd0ef          	jal	ra,ffffffffc02005be <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc02030ca:	60a2                	ld	ra,8(sp)
ffffffffc02030cc:	8522                	mv	a0,s0
ffffffffc02030ce:	6402                	ld	s0,0(sp)
ffffffffc02030d0:	0141                	addi	sp,sp,16
ffffffffc02030d2:	8082                	ret

ffffffffc02030d4 <get_pte>:
//  pgdir:  the kernel virtual base address of PDT
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc02030d4:	01e5d793          	srli	a5,a1,0x1e
ffffffffc02030d8:	1ff7f793          	andi	a5,a5,511
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc02030dc:	7139                	addi	sp,sp,-64
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc02030de:	078e                	slli	a5,a5,0x3
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc02030e0:	f426                	sd	s1,40(sp)
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc02030e2:	00f504b3          	add	s1,a0,a5
    if (!(*pdep1 & PTE_V)) {
ffffffffc02030e6:	6094                	ld	a3,0(s1)
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc02030e8:	f04a                	sd	s2,32(sp)
ffffffffc02030ea:	ec4e                	sd	s3,24(sp)
ffffffffc02030ec:	e852                	sd	s4,16(sp)
ffffffffc02030ee:	fc06                	sd	ra,56(sp)
ffffffffc02030f0:	f822                	sd	s0,48(sp)
ffffffffc02030f2:	e456                	sd	s5,8(sp)
ffffffffc02030f4:	e05a                	sd	s6,0(sp)
    if (!(*pdep1 & PTE_V)) {
ffffffffc02030f6:	0016f793          	andi	a5,a3,1
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc02030fa:	892e                	mv	s2,a1
ffffffffc02030fc:	89b2                	mv	s3,a2
ffffffffc02030fe:	00013a17          	auipc	s4,0x13
ffffffffc0203102:	492a0a13          	addi	s4,s4,1170 # ffffffffc0216590 <npage>
    if (!(*pdep1 & PTE_V)) {
ffffffffc0203106:	e7b5                	bnez	a5,ffffffffc0203172 <get_pte+0x9e>
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL) {
ffffffffc0203108:	12060b63          	beqz	a2,ffffffffc020323e <get_pte+0x16a>
ffffffffc020310c:	4505                	li	a0,1
ffffffffc020310e:	ebbff0ef          	jal	ra,ffffffffc0202fc8 <alloc_pages>
ffffffffc0203112:	842a                	mv	s0,a0
ffffffffc0203114:	12050563          	beqz	a0,ffffffffc020323e <get_pte+0x16a>
    return page - pages + nbase;
ffffffffc0203118:	00013b17          	auipc	s6,0x13
ffffffffc020311c:	480b0b13          	addi	s6,s6,1152 # ffffffffc0216598 <pages>
ffffffffc0203120:	000b3503          	ld	a0,0(s6)
ffffffffc0203124:	00080ab7          	lui	s5,0x80
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0203128:	00013a17          	auipc	s4,0x13
ffffffffc020312c:	468a0a13          	addi	s4,s4,1128 # ffffffffc0216590 <npage>
ffffffffc0203130:	40a40533          	sub	a0,s0,a0
ffffffffc0203134:	8519                	srai	a0,a0,0x6
ffffffffc0203136:	9556                	add	a0,a0,s5
ffffffffc0203138:	000a3703          	ld	a4,0(s4)
ffffffffc020313c:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc0203140:	4685                	li	a3,1
ffffffffc0203142:	c014                	sw	a3,0(s0)
ffffffffc0203144:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0203146:	0532                	slli	a0,a0,0xc
ffffffffc0203148:	14e7f263          	bgeu	a5,a4,ffffffffc020328c <get_pte+0x1b8>
ffffffffc020314c:	00013797          	auipc	a5,0x13
ffffffffc0203150:	45c7b783          	ld	a5,1116(a5) # ffffffffc02165a8 <va_pa_offset>
ffffffffc0203154:	6605                	lui	a2,0x1
ffffffffc0203156:	4581                	li	a1,0
ffffffffc0203158:	953e                	add	a0,a0,a5
ffffffffc020315a:	173010ef          	jal	ra,ffffffffc0204acc <memset>
    return page - pages + nbase;
ffffffffc020315e:	000b3683          	ld	a3,0(s6)
ffffffffc0203162:	40d406b3          	sub	a3,s0,a3
ffffffffc0203166:	8699                	srai	a3,a3,0x6
ffffffffc0203168:	96d6                	add	a3,a3,s5
}

// construct PTE from a page and permission bits
static inline pte_t pte_create(uintptr_t ppn, int type) {
  return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc020316a:	06aa                	slli	a3,a3,0xa
ffffffffc020316c:	0116e693          	ori	a3,a3,17
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0203170:	e094                	sd	a3,0(s1)
    }
    pde_t *pdep0 = &((pte_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0203172:	77fd                	lui	a5,0xfffff
ffffffffc0203174:	068a                	slli	a3,a3,0x2
ffffffffc0203176:	000a3703          	ld	a4,0(s4)
ffffffffc020317a:	8efd                	and	a3,a3,a5
ffffffffc020317c:	00c6d793          	srli	a5,a3,0xc
ffffffffc0203180:	0ce7f163          	bgeu	a5,a4,ffffffffc0203242 <get_pte+0x16e>
ffffffffc0203184:	00013a97          	auipc	s5,0x13
ffffffffc0203188:	424a8a93          	addi	s5,s5,1060 # ffffffffc02165a8 <va_pa_offset>
ffffffffc020318c:	000ab403          	ld	s0,0(s5)
ffffffffc0203190:	01595793          	srli	a5,s2,0x15
ffffffffc0203194:	1ff7f793          	andi	a5,a5,511
ffffffffc0203198:	96a2                	add	a3,a3,s0
ffffffffc020319a:	00379413          	slli	s0,a5,0x3
ffffffffc020319e:	9436                	add	s0,s0,a3
    if (!(*pdep0 & PTE_V)) {
ffffffffc02031a0:	6014                	ld	a3,0(s0)
ffffffffc02031a2:	0016f793          	andi	a5,a3,1
ffffffffc02031a6:	e3ad                	bnez	a5,ffffffffc0203208 <get_pte+0x134>
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL) {
ffffffffc02031a8:	08098b63          	beqz	s3,ffffffffc020323e <get_pte+0x16a>
ffffffffc02031ac:	4505                	li	a0,1
ffffffffc02031ae:	e1bff0ef          	jal	ra,ffffffffc0202fc8 <alloc_pages>
ffffffffc02031b2:	84aa                	mv	s1,a0
ffffffffc02031b4:	c549                	beqz	a0,ffffffffc020323e <get_pte+0x16a>
    return page - pages + nbase;
ffffffffc02031b6:	00013b17          	auipc	s6,0x13
ffffffffc02031ba:	3e2b0b13          	addi	s6,s6,994 # ffffffffc0216598 <pages>
ffffffffc02031be:	000b3503          	ld	a0,0(s6)
ffffffffc02031c2:	000809b7          	lui	s3,0x80
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc02031c6:	000a3703          	ld	a4,0(s4)
ffffffffc02031ca:	40a48533          	sub	a0,s1,a0
ffffffffc02031ce:	8519                	srai	a0,a0,0x6
ffffffffc02031d0:	954e                	add	a0,a0,s3
ffffffffc02031d2:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc02031d6:	4685                	li	a3,1
ffffffffc02031d8:	c094                	sw	a3,0(s1)
ffffffffc02031da:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc02031dc:	0532                	slli	a0,a0,0xc
ffffffffc02031de:	08e7fa63          	bgeu	a5,a4,ffffffffc0203272 <get_pte+0x19e>
ffffffffc02031e2:	000ab783          	ld	a5,0(s5)
ffffffffc02031e6:	6605                	lui	a2,0x1
ffffffffc02031e8:	4581                	li	a1,0
ffffffffc02031ea:	953e                	add	a0,a0,a5
ffffffffc02031ec:	0e1010ef          	jal	ra,ffffffffc0204acc <memset>
    return page - pages + nbase;
ffffffffc02031f0:	000b3683          	ld	a3,0(s6)
ffffffffc02031f4:	40d486b3          	sub	a3,s1,a3
ffffffffc02031f8:	8699                	srai	a3,a3,0x6
ffffffffc02031fa:	96ce                	add	a3,a3,s3
  return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc02031fc:	06aa                	slli	a3,a3,0xa
ffffffffc02031fe:	0116e693          	ori	a3,a3,17
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0203202:	e014                	sd	a3,0(s0)
    }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0203204:	000a3703          	ld	a4,0(s4)
ffffffffc0203208:	068a                	slli	a3,a3,0x2
ffffffffc020320a:	757d                	lui	a0,0xfffff
ffffffffc020320c:	8ee9                	and	a3,a3,a0
ffffffffc020320e:	00c6d793          	srli	a5,a3,0xc
ffffffffc0203212:	04e7f463          	bgeu	a5,a4,ffffffffc020325a <get_pte+0x186>
ffffffffc0203216:	000ab503          	ld	a0,0(s5)
ffffffffc020321a:	00c95913          	srli	s2,s2,0xc
ffffffffc020321e:	1ff97913          	andi	s2,s2,511
ffffffffc0203222:	96aa                	add	a3,a3,a0
ffffffffc0203224:	00391513          	slli	a0,s2,0x3
ffffffffc0203228:	9536                	add	a0,a0,a3
}
ffffffffc020322a:	70e2                	ld	ra,56(sp)
ffffffffc020322c:	7442                	ld	s0,48(sp)
ffffffffc020322e:	74a2                	ld	s1,40(sp)
ffffffffc0203230:	7902                	ld	s2,32(sp)
ffffffffc0203232:	69e2                	ld	s3,24(sp)
ffffffffc0203234:	6a42                	ld	s4,16(sp)
ffffffffc0203236:	6aa2                	ld	s5,8(sp)
ffffffffc0203238:	6b02                	ld	s6,0(sp)
ffffffffc020323a:	6121                	addi	sp,sp,64
ffffffffc020323c:	8082                	ret
            return NULL;
ffffffffc020323e:	4501                	li	a0,0
ffffffffc0203240:	b7ed                	j	ffffffffc020322a <get_pte+0x156>
    pde_t *pdep0 = &((pte_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0203242:	00003617          	auipc	a2,0x3
ffffffffc0203246:	8e660613          	addi	a2,a2,-1818 # ffffffffc0205b28 <commands+0x980>
ffffffffc020324a:	0e400593          	li	a1,228
ffffffffc020324e:	00003517          	auipc	a0,0x3
ffffffffc0203252:	43250513          	addi	a0,a0,1074 # ffffffffc0206680 <default_pmm_manager+0x38>
ffffffffc0203256:	f73fc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc020325a:	00003617          	auipc	a2,0x3
ffffffffc020325e:	8ce60613          	addi	a2,a2,-1842 # ffffffffc0205b28 <commands+0x980>
ffffffffc0203262:	0ef00593          	li	a1,239
ffffffffc0203266:	00003517          	auipc	a0,0x3
ffffffffc020326a:	41a50513          	addi	a0,a0,1050 # ffffffffc0206680 <default_pmm_manager+0x38>
ffffffffc020326e:	f5bfc0ef          	jal	ra,ffffffffc02001c8 <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0203272:	86aa                	mv	a3,a0
ffffffffc0203274:	00003617          	auipc	a2,0x3
ffffffffc0203278:	8b460613          	addi	a2,a2,-1868 # ffffffffc0205b28 <commands+0x980>
ffffffffc020327c:	0ec00593          	li	a1,236
ffffffffc0203280:	00003517          	auipc	a0,0x3
ffffffffc0203284:	40050513          	addi	a0,a0,1024 # ffffffffc0206680 <default_pmm_manager+0x38>
ffffffffc0203288:	f41fc0ef          	jal	ra,ffffffffc02001c8 <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc020328c:	86aa                	mv	a3,a0
ffffffffc020328e:	00003617          	auipc	a2,0x3
ffffffffc0203292:	89a60613          	addi	a2,a2,-1894 # ffffffffc0205b28 <commands+0x980>
ffffffffc0203296:	0e100593          	li	a1,225
ffffffffc020329a:	00003517          	auipc	a0,0x3
ffffffffc020329e:	3e650513          	addi	a0,a0,998 # ffffffffc0206680 <default_pmm_manager+0x38>
ffffffffc02032a2:	f27fc0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc02032a6 <get_page>:

// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store) {
ffffffffc02032a6:	1141                	addi	sp,sp,-16
ffffffffc02032a8:	e022                	sd	s0,0(sp)
ffffffffc02032aa:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02032ac:	4601                	li	a2,0
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store) {
ffffffffc02032ae:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02032b0:	e25ff0ef          	jal	ra,ffffffffc02030d4 <get_pte>
    if (ptep_store != NULL) {
ffffffffc02032b4:	c011                	beqz	s0,ffffffffc02032b8 <get_page+0x12>
        *ptep_store = ptep;
ffffffffc02032b6:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V) {
ffffffffc02032b8:	c511                	beqz	a0,ffffffffc02032c4 <get_page+0x1e>
ffffffffc02032ba:	611c                	ld	a5,0(a0)
        return pte2page(*ptep);
    }
    return NULL;
ffffffffc02032bc:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V) {
ffffffffc02032be:	0017f713          	andi	a4,a5,1
ffffffffc02032c2:	e709                	bnez	a4,ffffffffc02032cc <get_page+0x26>
}
ffffffffc02032c4:	60a2                	ld	ra,8(sp)
ffffffffc02032c6:	6402                	ld	s0,0(sp)
ffffffffc02032c8:	0141                	addi	sp,sp,16
ffffffffc02032ca:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc02032cc:	078a                	slli	a5,a5,0x2
ffffffffc02032ce:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02032d0:	00013717          	auipc	a4,0x13
ffffffffc02032d4:	2c073703          	ld	a4,704(a4) # ffffffffc0216590 <npage>
ffffffffc02032d8:	00e7ff63          	bgeu	a5,a4,ffffffffc02032f6 <get_page+0x50>
ffffffffc02032dc:	60a2                	ld	ra,8(sp)
ffffffffc02032de:	6402                	ld	s0,0(sp)
    return &pages[PPN(pa) - nbase];
ffffffffc02032e0:	fff80537          	lui	a0,0xfff80
ffffffffc02032e4:	97aa                	add	a5,a5,a0
ffffffffc02032e6:	079a                	slli	a5,a5,0x6
ffffffffc02032e8:	00013517          	auipc	a0,0x13
ffffffffc02032ec:	2b053503          	ld	a0,688(a0) # ffffffffc0216598 <pages>
ffffffffc02032f0:	953e                	add	a0,a0,a5
ffffffffc02032f2:	0141                	addi	sp,sp,16
ffffffffc02032f4:	8082                	ret
ffffffffc02032f6:	c9bff0ef          	jal	ra,ffffffffc0202f90 <pa2page.part.0>

ffffffffc02032fa <page_remove>:
    }
}

// page_remove - free an Page which is related linear address la and has an
// validated pte
void page_remove(pde_t *pgdir, uintptr_t la) {
ffffffffc02032fa:	7179                	addi	sp,sp,-48
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02032fc:	4601                	li	a2,0
void page_remove(pde_t *pgdir, uintptr_t la) {
ffffffffc02032fe:	ec26                	sd	s1,24(sp)
ffffffffc0203300:	f406                	sd	ra,40(sp)
ffffffffc0203302:	f022                	sd	s0,32(sp)
ffffffffc0203304:	84ae                	mv	s1,a1
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0203306:	dcfff0ef          	jal	ra,ffffffffc02030d4 <get_pte>
    if (ptep != NULL) {
ffffffffc020330a:	c511                	beqz	a0,ffffffffc0203316 <page_remove+0x1c>
    if (*ptep & PTE_V) {  //(1) check if this page table entry is
ffffffffc020330c:	611c                	ld	a5,0(a0)
ffffffffc020330e:	842a                	mv	s0,a0
ffffffffc0203310:	0017f713          	andi	a4,a5,1
ffffffffc0203314:	e711                	bnez	a4,ffffffffc0203320 <page_remove+0x26>
        page_remove_pte(pgdir, la, ptep);
    }
}
ffffffffc0203316:	70a2                	ld	ra,40(sp)
ffffffffc0203318:	7402                	ld	s0,32(sp)
ffffffffc020331a:	64e2                	ld	s1,24(sp)
ffffffffc020331c:	6145                	addi	sp,sp,48
ffffffffc020331e:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc0203320:	078a                	slli	a5,a5,0x2
ffffffffc0203322:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0203324:	00013717          	auipc	a4,0x13
ffffffffc0203328:	26c73703          	ld	a4,620(a4) # ffffffffc0216590 <npage>
ffffffffc020332c:	06e7f363          	bgeu	a5,a4,ffffffffc0203392 <page_remove+0x98>
    return &pages[PPN(pa) - nbase];
ffffffffc0203330:	fff80537          	lui	a0,0xfff80
ffffffffc0203334:	97aa                	add	a5,a5,a0
ffffffffc0203336:	079a                	slli	a5,a5,0x6
ffffffffc0203338:	00013517          	auipc	a0,0x13
ffffffffc020333c:	26053503          	ld	a0,608(a0) # ffffffffc0216598 <pages>
ffffffffc0203340:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc0203342:	411c                	lw	a5,0(a0)
ffffffffc0203344:	fff7871b          	addiw	a4,a5,-1
ffffffffc0203348:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc020334a:	cb11                	beqz	a4,ffffffffc020335e <page_remove+0x64>
        *ptep = 0;                  //(5) clear second page table entry
ffffffffc020334c:	00043023          	sd	zero,0(s0)
// invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
void tlb_invalidate(pde_t *pgdir, uintptr_t la) {
    // flush_tlb();
    // The flush_tlb flush the entire TLB, is there any better way?
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0203350:	12048073          	sfence.vma	s1
}
ffffffffc0203354:	70a2                	ld	ra,40(sp)
ffffffffc0203356:	7402                	ld	s0,32(sp)
ffffffffc0203358:	64e2                	ld	s1,24(sp)
ffffffffc020335a:	6145                	addi	sp,sp,48
ffffffffc020335c:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020335e:	100027f3          	csrr	a5,sstatus
ffffffffc0203362:	8b89                	andi	a5,a5,2
ffffffffc0203364:	eb89                	bnez	a5,ffffffffc0203376 <page_remove+0x7c>
        pmm_manager->free_pages(base, n);
ffffffffc0203366:	00013797          	auipc	a5,0x13
ffffffffc020336a:	23a7b783          	ld	a5,570(a5) # ffffffffc02165a0 <pmm_manager>
ffffffffc020336e:	739c                	ld	a5,32(a5)
ffffffffc0203370:	4585                	li	a1,1
ffffffffc0203372:	9782                	jalr	a5
    if (flag) {
ffffffffc0203374:	bfe1                	j	ffffffffc020334c <page_remove+0x52>
        intr_disable();
ffffffffc0203376:	e42a                	sd	a0,8(sp)
ffffffffc0203378:	a4cfd0ef          	jal	ra,ffffffffc02005c4 <intr_disable>
ffffffffc020337c:	00013797          	auipc	a5,0x13
ffffffffc0203380:	2247b783          	ld	a5,548(a5) # ffffffffc02165a0 <pmm_manager>
ffffffffc0203384:	739c                	ld	a5,32(a5)
ffffffffc0203386:	6522                	ld	a0,8(sp)
ffffffffc0203388:	4585                	li	a1,1
ffffffffc020338a:	9782                	jalr	a5
        intr_enable();
ffffffffc020338c:	a32fd0ef          	jal	ra,ffffffffc02005be <intr_enable>
ffffffffc0203390:	bf75                	j	ffffffffc020334c <page_remove+0x52>
ffffffffc0203392:	bffff0ef          	jal	ra,ffffffffc0202f90 <pa2page.part.0>

ffffffffc0203396 <page_insert>:
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
ffffffffc0203396:	7139                	addi	sp,sp,-64
ffffffffc0203398:	e852                	sd	s4,16(sp)
ffffffffc020339a:	8a32                	mv	s4,a2
ffffffffc020339c:	f822                	sd	s0,48(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc020339e:	4605                	li	a2,1
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
ffffffffc02033a0:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc02033a2:	85d2                	mv	a1,s4
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
ffffffffc02033a4:	f426                	sd	s1,40(sp)
ffffffffc02033a6:	fc06                	sd	ra,56(sp)
ffffffffc02033a8:	f04a                	sd	s2,32(sp)
ffffffffc02033aa:	ec4e                	sd	s3,24(sp)
ffffffffc02033ac:	e456                	sd	s5,8(sp)
ffffffffc02033ae:	84b6                	mv	s1,a3
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc02033b0:	d25ff0ef          	jal	ra,ffffffffc02030d4 <get_pte>
    if (ptep == NULL) {
ffffffffc02033b4:	c961                	beqz	a0,ffffffffc0203484 <page_insert+0xee>
    page->ref += 1;
ffffffffc02033b6:	4014                	lw	a3,0(s0)
    if (*ptep & PTE_V) {
ffffffffc02033b8:	611c                	ld	a5,0(a0)
ffffffffc02033ba:	89aa                	mv	s3,a0
ffffffffc02033bc:	0016871b          	addiw	a4,a3,1
ffffffffc02033c0:	c018                	sw	a4,0(s0)
ffffffffc02033c2:	0017f713          	andi	a4,a5,1
ffffffffc02033c6:	ef05                	bnez	a4,ffffffffc02033fe <page_insert+0x68>
    return page - pages + nbase;
ffffffffc02033c8:	00013717          	auipc	a4,0x13
ffffffffc02033cc:	1d073703          	ld	a4,464(a4) # ffffffffc0216598 <pages>
ffffffffc02033d0:	8c19                	sub	s0,s0,a4
ffffffffc02033d2:	000807b7          	lui	a5,0x80
ffffffffc02033d6:	8419                	srai	s0,s0,0x6
ffffffffc02033d8:	943e                	add	s0,s0,a5
  return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc02033da:	042a                	slli	s0,s0,0xa
ffffffffc02033dc:	8cc1                	or	s1,s1,s0
ffffffffc02033de:	0014e493          	ori	s1,s1,1
    *ptep = pte_create(page2ppn(page), PTE_V | perm);
ffffffffc02033e2:	0099b023          	sd	s1,0(s3) # 80000 <kern_entry-0xffffffffc0180000>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02033e6:	120a0073          	sfence.vma	s4
    return 0;
ffffffffc02033ea:	4501                	li	a0,0
}
ffffffffc02033ec:	70e2                	ld	ra,56(sp)
ffffffffc02033ee:	7442                	ld	s0,48(sp)
ffffffffc02033f0:	74a2                	ld	s1,40(sp)
ffffffffc02033f2:	7902                	ld	s2,32(sp)
ffffffffc02033f4:	69e2                	ld	s3,24(sp)
ffffffffc02033f6:	6a42                	ld	s4,16(sp)
ffffffffc02033f8:	6aa2                	ld	s5,8(sp)
ffffffffc02033fa:	6121                	addi	sp,sp,64
ffffffffc02033fc:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc02033fe:	078a                	slli	a5,a5,0x2
ffffffffc0203400:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0203402:	00013717          	auipc	a4,0x13
ffffffffc0203406:	18e73703          	ld	a4,398(a4) # ffffffffc0216590 <npage>
ffffffffc020340a:	06e7ff63          	bgeu	a5,a4,ffffffffc0203488 <page_insert+0xf2>
    return &pages[PPN(pa) - nbase];
ffffffffc020340e:	00013a97          	auipc	s5,0x13
ffffffffc0203412:	18aa8a93          	addi	s5,s5,394 # ffffffffc0216598 <pages>
ffffffffc0203416:	000ab703          	ld	a4,0(s5)
ffffffffc020341a:	fff80937          	lui	s2,0xfff80
ffffffffc020341e:	993e                	add	s2,s2,a5
ffffffffc0203420:	091a                	slli	s2,s2,0x6
ffffffffc0203422:	993a                	add	s2,s2,a4
        if (p == page) {
ffffffffc0203424:	01240c63          	beq	s0,s2,ffffffffc020343c <page_insert+0xa6>
    page->ref -= 1;
ffffffffc0203428:	00092783          	lw	a5,0(s2) # fffffffffff80000 <end+0x3fd69a34>
ffffffffc020342c:	fff7869b          	addiw	a3,a5,-1
ffffffffc0203430:	00d92023          	sw	a3,0(s2)
        if (page_ref(page) ==
ffffffffc0203434:	c691                	beqz	a3,ffffffffc0203440 <page_insert+0xaa>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0203436:	120a0073          	sfence.vma	s4
}
ffffffffc020343a:	bf59                	j	ffffffffc02033d0 <page_insert+0x3a>
ffffffffc020343c:	c014                	sw	a3,0(s0)
    return page->ref;
ffffffffc020343e:	bf49                	j	ffffffffc02033d0 <page_insert+0x3a>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0203440:	100027f3          	csrr	a5,sstatus
ffffffffc0203444:	8b89                	andi	a5,a5,2
ffffffffc0203446:	ef91                	bnez	a5,ffffffffc0203462 <page_insert+0xcc>
        pmm_manager->free_pages(base, n);
ffffffffc0203448:	00013797          	auipc	a5,0x13
ffffffffc020344c:	1587b783          	ld	a5,344(a5) # ffffffffc02165a0 <pmm_manager>
ffffffffc0203450:	739c                	ld	a5,32(a5)
ffffffffc0203452:	4585                	li	a1,1
ffffffffc0203454:	854a                	mv	a0,s2
ffffffffc0203456:	9782                	jalr	a5
    return page - pages + nbase;
ffffffffc0203458:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc020345c:	120a0073          	sfence.vma	s4
ffffffffc0203460:	bf85                	j	ffffffffc02033d0 <page_insert+0x3a>
        intr_disable();
ffffffffc0203462:	962fd0ef          	jal	ra,ffffffffc02005c4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0203466:	00013797          	auipc	a5,0x13
ffffffffc020346a:	13a7b783          	ld	a5,314(a5) # ffffffffc02165a0 <pmm_manager>
ffffffffc020346e:	739c                	ld	a5,32(a5)
ffffffffc0203470:	4585                	li	a1,1
ffffffffc0203472:	854a                	mv	a0,s2
ffffffffc0203474:	9782                	jalr	a5
        intr_enable();
ffffffffc0203476:	948fd0ef          	jal	ra,ffffffffc02005be <intr_enable>
ffffffffc020347a:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc020347e:	120a0073          	sfence.vma	s4
ffffffffc0203482:	b7b9                	j	ffffffffc02033d0 <page_insert+0x3a>
        return -E_NO_MEM;
ffffffffc0203484:	5571                	li	a0,-4
ffffffffc0203486:	b79d                	j	ffffffffc02033ec <page_insert+0x56>
ffffffffc0203488:	b09ff0ef          	jal	ra,ffffffffc0202f90 <pa2page.part.0>

ffffffffc020348c <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc020348c:	00003797          	auipc	a5,0x3
ffffffffc0203490:	1bc78793          	addi	a5,a5,444 # ffffffffc0206648 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0203494:	638c                	ld	a1,0(a5)
void pmm_init(void) {
ffffffffc0203496:	711d                	addi	sp,sp,-96
ffffffffc0203498:	ec5e                	sd	s7,24(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020349a:	00003517          	auipc	a0,0x3
ffffffffc020349e:	1f650513          	addi	a0,a0,502 # ffffffffc0206690 <default_pmm_manager+0x48>
    pmm_manager = &default_pmm_manager;
ffffffffc02034a2:	00013b97          	auipc	s7,0x13
ffffffffc02034a6:	0feb8b93          	addi	s7,s7,254 # ffffffffc02165a0 <pmm_manager>
void pmm_init(void) {
ffffffffc02034aa:	ec86                	sd	ra,88(sp)
ffffffffc02034ac:	e4a6                	sd	s1,72(sp)
ffffffffc02034ae:	fc4e                	sd	s3,56(sp)
ffffffffc02034b0:	f05a                	sd	s6,32(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc02034b2:	00fbb023          	sd	a5,0(s7)
void pmm_init(void) {
ffffffffc02034b6:	e8a2                	sd	s0,80(sp)
ffffffffc02034b8:	e0ca                	sd	s2,64(sp)
ffffffffc02034ba:	f852                	sd	s4,48(sp)
ffffffffc02034bc:	f456                	sd	s5,40(sp)
ffffffffc02034be:	e862                	sd	s8,16(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02034c0:	c0dfc0ef          	jal	ra,ffffffffc02000cc <cprintf>
    pmm_manager->init();
ffffffffc02034c4:	000bb783          	ld	a5,0(s7)
    va_pa_offset = KERNBASE - 0x80200000;
ffffffffc02034c8:	00013997          	auipc	s3,0x13
ffffffffc02034cc:	0e098993          	addi	s3,s3,224 # ffffffffc02165a8 <va_pa_offset>
    npage = maxpa / PGSIZE;
ffffffffc02034d0:	00013497          	auipc	s1,0x13
ffffffffc02034d4:	0c048493          	addi	s1,s1,192 # ffffffffc0216590 <npage>
    pmm_manager->init();
ffffffffc02034d8:	679c                	ld	a5,8(a5)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02034da:	00013b17          	auipc	s6,0x13
ffffffffc02034de:	0beb0b13          	addi	s6,s6,190 # ffffffffc0216598 <pages>
    pmm_manager->init();
ffffffffc02034e2:	9782                	jalr	a5
    va_pa_offset = KERNBASE - 0x80200000;
ffffffffc02034e4:	57f5                	li	a5,-3
ffffffffc02034e6:	07fa                	slli	a5,a5,0x1e
    cprintf("physcial memory map:\n");
ffffffffc02034e8:	00003517          	auipc	a0,0x3
ffffffffc02034ec:	1c050513          	addi	a0,a0,448 # ffffffffc02066a8 <default_pmm_manager+0x60>
    va_pa_offset = KERNBASE - 0x80200000;
ffffffffc02034f0:	00f9b023          	sd	a5,0(s3)
    cprintf("physcial memory map:\n");
ffffffffc02034f4:	bd9fc0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc02034f8:	46c5                	li	a3,17
ffffffffc02034fa:	06ee                	slli	a3,a3,0x1b
ffffffffc02034fc:	40100613          	li	a2,1025
ffffffffc0203500:	07e005b7          	lui	a1,0x7e00
ffffffffc0203504:	16fd                	addi	a3,a3,-1
ffffffffc0203506:	0656                	slli	a2,a2,0x15
ffffffffc0203508:	00003517          	auipc	a0,0x3
ffffffffc020350c:	1b850513          	addi	a0,a0,440 # ffffffffc02066c0 <default_pmm_manager+0x78>
ffffffffc0203510:	bbdfc0ef          	jal	ra,ffffffffc02000cc <cprintf>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0203514:	777d                	lui	a4,0xfffff
ffffffffc0203516:	00014797          	auipc	a5,0x14
ffffffffc020351a:	0b578793          	addi	a5,a5,181 # ffffffffc02175cb <end+0xfff>
ffffffffc020351e:	8ff9                	and	a5,a5,a4
    npage = maxpa / PGSIZE;
ffffffffc0203520:	00088737          	lui	a4,0x88
ffffffffc0203524:	e098                	sd	a4,0(s1)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0203526:	00fb3023          	sd	a5,0(s6)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc020352a:	4701                	li	a4,0
ffffffffc020352c:	4585                	li	a1,1
ffffffffc020352e:	fff80837          	lui	a6,0xfff80
ffffffffc0203532:	a019                	j	ffffffffc0203538 <pmm_init+0xac>
        SetPageReserved(pages + i);
ffffffffc0203534:	000b3783          	ld	a5,0(s6)
ffffffffc0203538:	00671693          	slli	a3,a4,0x6
ffffffffc020353c:	97b6                	add	a5,a5,a3
ffffffffc020353e:	07a1                	addi	a5,a5,8
ffffffffc0203540:	40b7b02f          	amoor.d	zero,a1,(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0203544:	6090                	ld	a2,0(s1)
ffffffffc0203546:	0705                	addi	a4,a4,1
ffffffffc0203548:	010607b3          	add	a5,a2,a6
ffffffffc020354c:	fef764e3          	bltu	a4,a5,ffffffffc0203534 <pmm_init+0xa8>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0203550:	000b3503          	ld	a0,0(s6)
ffffffffc0203554:	079a                	slli	a5,a5,0x6
ffffffffc0203556:	c0200737          	lui	a4,0xc0200
ffffffffc020355a:	00f506b3          	add	a3,a0,a5
ffffffffc020355e:	60e6e563          	bltu	a3,a4,ffffffffc0203b68 <pmm_init+0x6dc>
ffffffffc0203562:	0009b583          	ld	a1,0(s3)
    if (freemem < mem_end) {
ffffffffc0203566:	4745                	li	a4,17
ffffffffc0203568:	076e                	slli	a4,a4,0x1b
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020356a:	8e8d                	sub	a3,a3,a1
    if (freemem < mem_end) {
ffffffffc020356c:	4ae6e563          	bltu	a3,a4,ffffffffc0203a16 <pmm_init+0x58a>
    cprintf("vapaofset is %llu\n",va_pa_offset);
ffffffffc0203570:	00003517          	auipc	a0,0x3
ffffffffc0203574:	17850513          	addi	a0,a0,376 # ffffffffc02066e8 <default_pmm_manager+0xa0>
ffffffffc0203578:	b55fc0ef          	jal	ra,ffffffffc02000cc <cprintf>

    return page;
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc020357c:	000bb783          	ld	a5,0(s7)
    boot_pgdir = (pte_t*)boot_page_table_sv39;
ffffffffc0203580:	00013917          	auipc	s2,0x13
ffffffffc0203584:	00890913          	addi	s2,s2,8 # ffffffffc0216588 <boot_pgdir>
    pmm_manager->check();
ffffffffc0203588:	7b9c                	ld	a5,48(a5)
ffffffffc020358a:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc020358c:	00003517          	auipc	a0,0x3
ffffffffc0203590:	17450513          	addi	a0,a0,372 # ffffffffc0206700 <default_pmm_manager+0xb8>
ffffffffc0203594:	b39fc0ef          	jal	ra,ffffffffc02000cc <cprintf>
    boot_pgdir = (pte_t*)boot_page_table_sv39;
ffffffffc0203598:	00007697          	auipc	a3,0x7
ffffffffc020359c:	a6868693          	addi	a3,a3,-1432 # ffffffffc020a000 <boot_page_table_sv39>
ffffffffc02035a0:	00d93023          	sd	a3,0(s2)
    boot_cr3 = PADDR(boot_pgdir);
ffffffffc02035a4:	c02007b7          	lui	a5,0xc0200
ffffffffc02035a8:	5cf6ec63          	bltu	a3,a5,ffffffffc0203b80 <pmm_init+0x6f4>
ffffffffc02035ac:	0009b783          	ld	a5,0(s3)
ffffffffc02035b0:	8e9d                	sub	a3,a3,a5
ffffffffc02035b2:	00013797          	auipc	a5,0x13
ffffffffc02035b6:	fcd7b723          	sd	a3,-50(a5) # ffffffffc0216580 <boot_cr3>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02035ba:	100027f3          	csrr	a5,sstatus
ffffffffc02035be:	8b89                	andi	a5,a5,2
ffffffffc02035c0:	48079263          	bnez	a5,ffffffffc0203a44 <pmm_init+0x5b8>
        ret = pmm_manager->nr_free_pages();
ffffffffc02035c4:	000bb783          	ld	a5,0(s7)
ffffffffc02035c8:	779c                	ld	a5,40(a5)
ffffffffc02035ca:	9782                	jalr	a5
ffffffffc02035cc:	842a                	mv	s0,a0
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store=nr_free_pages();

    assert(npage <= KERNTOP / PGSIZE);
ffffffffc02035ce:	6098                	ld	a4,0(s1)
ffffffffc02035d0:	c80007b7          	lui	a5,0xc8000
ffffffffc02035d4:	83b1                	srli	a5,a5,0xc
ffffffffc02035d6:	5ee7e163          	bltu	a5,a4,ffffffffc0203bb8 <pmm_init+0x72c>
    assert(boot_pgdir != NULL && (uint32_t)PGOFF(boot_pgdir) == 0);
ffffffffc02035da:	00093503          	ld	a0,0(s2)
ffffffffc02035de:	5a050d63          	beqz	a0,ffffffffc0203b98 <pmm_init+0x70c>
ffffffffc02035e2:	03451793          	slli	a5,a0,0x34
ffffffffc02035e6:	5a079963          	bnez	a5,ffffffffc0203b98 <pmm_init+0x70c>
    assert(get_page(boot_pgdir, 0x0, NULL) == NULL);
ffffffffc02035ea:	4601                	li	a2,0
ffffffffc02035ec:	4581                	li	a1,0
ffffffffc02035ee:	cb9ff0ef          	jal	ra,ffffffffc02032a6 <get_page>
ffffffffc02035f2:	62051563          	bnez	a0,ffffffffc0203c1c <pmm_init+0x790>

    struct Page *p1, *p2;
    p1 = alloc_page();
ffffffffc02035f6:	4505                	li	a0,1
ffffffffc02035f8:	9d1ff0ef          	jal	ra,ffffffffc0202fc8 <alloc_pages>
ffffffffc02035fc:	8a2a                	mv	s4,a0
    assert(page_insert(boot_pgdir, p1, 0x0, 0) == 0);
ffffffffc02035fe:	00093503          	ld	a0,0(s2)
ffffffffc0203602:	4681                	li	a3,0
ffffffffc0203604:	4601                	li	a2,0
ffffffffc0203606:	85d2                	mv	a1,s4
ffffffffc0203608:	d8fff0ef          	jal	ra,ffffffffc0203396 <page_insert>
ffffffffc020360c:	5e051863          	bnez	a0,ffffffffc0203bfc <pmm_init+0x770>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir, 0x0, 0)) != NULL);
ffffffffc0203610:	00093503          	ld	a0,0(s2)
ffffffffc0203614:	4601                	li	a2,0
ffffffffc0203616:	4581                	li	a1,0
ffffffffc0203618:	abdff0ef          	jal	ra,ffffffffc02030d4 <get_pte>
ffffffffc020361c:	5c050063          	beqz	a0,ffffffffc0203bdc <pmm_init+0x750>
    assert(pte2page(*ptep) == p1);
ffffffffc0203620:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V)) {
ffffffffc0203622:	0017f713          	andi	a4,a5,1
ffffffffc0203626:	5a070963          	beqz	a4,ffffffffc0203bd8 <pmm_init+0x74c>
    if (PPN(pa) >= npage) {
ffffffffc020362a:	6098                	ld	a4,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc020362c:	078a                	slli	a5,a5,0x2
ffffffffc020362e:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0203630:	52e7fa63          	bgeu	a5,a4,ffffffffc0203b64 <pmm_init+0x6d8>
    return &pages[PPN(pa) - nbase];
ffffffffc0203634:	000b3683          	ld	a3,0(s6)
ffffffffc0203638:	fff80637          	lui	a2,0xfff80
ffffffffc020363c:	97b2                	add	a5,a5,a2
ffffffffc020363e:	079a                	slli	a5,a5,0x6
ffffffffc0203640:	97b6                	add	a5,a5,a3
ffffffffc0203642:	10fa16e3          	bne	s4,a5,ffffffffc0203f4e <pmm_init+0xac2>
    assert(page_ref(p1) == 1);
ffffffffc0203646:	000a2683          	lw	a3,0(s4)
ffffffffc020364a:	4785                	li	a5,1
ffffffffc020364c:	12f69de3          	bne	a3,a5,ffffffffc0203f86 <pmm_init+0xafa>

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir[0]));
ffffffffc0203650:	00093503          	ld	a0,0(s2)
ffffffffc0203654:	77fd                	lui	a5,0xfffff
ffffffffc0203656:	6114                	ld	a3,0(a0)
ffffffffc0203658:	068a                	slli	a3,a3,0x2
ffffffffc020365a:	8efd                	and	a3,a3,a5
ffffffffc020365c:	00c6d613          	srli	a2,a3,0xc
ffffffffc0203660:	10e677e3          	bgeu	a2,a4,ffffffffc0203f6e <pmm_init+0xae2>
ffffffffc0203664:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0203668:	96e2                	add	a3,a3,s8
ffffffffc020366a:	0006ba83          	ld	s5,0(a3)
ffffffffc020366e:	0a8a                	slli	s5,s5,0x2
ffffffffc0203670:	00fafab3          	and	s5,s5,a5
ffffffffc0203674:	00cad793          	srli	a5,s5,0xc
ffffffffc0203678:	62e7f263          	bgeu	a5,a4,ffffffffc0203c9c <pmm_init+0x810>
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc020367c:	4601                	li	a2,0
ffffffffc020367e:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0203680:	9ae2                	add	s5,s5,s8
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc0203682:	a53ff0ef          	jal	ra,ffffffffc02030d4 <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0203686:	0aa1                	addi	s5,s5,8
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc0203688:	5f551a63          	bne	a0,s5,ffffffffc0203c7c <pmm_init+0x7f0>

    p2 = alloc_page();
ffffffffc020368c:	4505                	li	a0,1
ffffffffc020368e:	93bff0ef          	jal	ra,ffffffffc0202fc8 <alloc_pages>
ffffffffc0203692:	8aaa                	mv	s5,a0
    assert(page_insert(boot_pgdir, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0203694:	00093503          	ld	a0,0(s2)
ffffffffc0203698:	46d1                	li	a3,20
ffffffffc020369a:	6605                	lui	a2,0x1
ffffffffc020369c:	85d6                	mv	a1,s5
ffffffffc020369e:	cf9ff0ef          	jal	ra,ffffffffc0203396 <page_insert>
ffffffffc02036a2:	58051d63          	bnez	a0,ffffffffc0203c3c <pmm_init+0x7b0>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc02036a6:	00093503          	ld	a0,0(s2)
ffffffffc02036aa:	4601                	li	a2,0
ffffffffc02036ac:	6585                	lui	a1,0x1
ffffffffc02036ae:	a27ff0ef          	jal	ra,ffffffffc02030d4 <get_pte>
ffffffffc02036b2:	0e050ae3          	beqz	a0,ffffffffc0203fa6 <pmm_init+0xb1a>
    assert(*ptep & PTE_U);
ffffffffc02036b6:	611c                	ld	a5,0(a0)
ffffffffc02036b8:	0107f713          	andi	a4,a5,16
ffffffffc02036bc:	6e070d63          	beqz	a4,ffffffffc0203db6 <pmm_init+0x92a>
    assert(*ptep & PTE_W);
ffffffffc02036c0:	8b91                	andi	a5,a5,4
ffffffffc02036c2:	6a078a63          	beqz	a5,ffffffffc0203d76 <pmm_init+0x8ea>
    assert(boot_pgdir[0] & PTE_U);
ffffffffc02036c6:	00093503          	ld	a0,0(s2)
ffffffffc02036ca:	611c                	ld	a5,0(a0)
ffffffffc02036cc:	8bc1                	andi	a5,a5,16
ffffffffc02036ce:	68078463          	beqz	a5,ffffffffc0203d56 <pmm_init+0x8ca>
    assert(page_ref(p2) == 1);
ffffffffc02036d2:	000aa703          	lw	a4,0(s5)
ffffffffc02036d6:	4785                	li	a5,1
ffffffffc02036d8:	58f71263          	bne	a4,a5,ffffffffc0203c5c <pmm_init+0x7d0>

    assert(page_insert(boot_pgdir, p1, PGSIZE, 0) == 0);
ffffffffc02036dc:	4681                	li	a3,0
ffffffffc02036de:	6605                	lui	a2,0x1
ffffffffc02036e0:	85d2                	mv	a1,s4
ffffffffc02036e2:	cb5ff0ef          	jal	ra,ffffffffc0203396 <page_insert>
ffffffffc02036e6:	62051863          	bnez	a0,ffffffffc0203d16 <pmm_init+0x88a>
    assert(page_ref(p1) == 2);
ffffffffc02036ea:	000a2703          	lw	a4,0(s4)
ffffffffc02036ee:	4789                	li	a5,2
ffffffffc02036f0:	60f71363          	bne	a4,a5,ffffffffc0203cf6 <pmm_init+0x86a>
    assert(page_ref(p2) == 0);
ffffffffc02036f4:	000aa783          	lw	a5,0(s5)
ffffffffc02036f8:	5c079f63          	bnez	a5,ffffffffc0203cd6 <pmm_init+0x84a>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc02036fc:	00093503          	ld	a0,0(s2)
ffffffffc0203700:	4601                	li	a2,0
ffffffffc0203702:	6585                	lui	a1,0x1
ffffffffc0203704:	9d1ff0ef          	jal	ra,ffffffffc02030d4 <get_pte>
ffffffffc0203708:	5a050763          	beqz	a0,ffffffffc0203cb6 <pmm_init+0x82a>
    assert(pte2page(*ptep) == p1);
ffffffffc020370c:	6118                	ld	a4,0(a0)
    if (!(pte & PTE_V)) {
ffffffffc020370e:	00177793          	andi	a5,a4,1
ffffffffc0203712:	4c078363          	beqz	a5,ffffffffc0203bd8 <pmm_init+0x74c>
    if (PPN(pa) >= npage) {
ffffffffc0203716:	6094                	ld	a3,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0203718:	00271793          	slli	a5,a4,0x2
ffffffffc020371c:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc020371e:	44d7f363          	bgeu	a5,a3,ffffffffc0203b64 <pmm_init+0x6d8>
    return &pages[PPN(pa) - nbase];
ffffffffc0203722:	000b3683          	ld	a3,0(s6)
ffffffffc0203726:	fff80637          	lui	a2,0xfff80
ffffffffc020372a:	97b2                	add	a5,a5,a2
ffffffffc020372c:	079a                	slli	a5,a5,0x6
ffffffffc020372e:	97b6                	add	a5,a5,a3
ffffffffc0203730:	6efa1363          	bne	s4,a5,ffffffffc0203e16 <pmm_init+0x98a>
    assert((*ptep & PTE_U) == 0);
ffffffffc0203734:	8b41                	andi	a4,a4,16
ffffffffc0203736:	6c071063          	bnez	a4,ffffffffc0203df6 <pmm_init+0x96a>

    page_remove(boot_pgdir, 0x0);
ffffffffc020373a:	00093503          	ld	a0,0(s2)
ffffffffc020373e:	4581                	li	a1,0
ffffffffc0203740:	bbbff0ef          	jal	ra,ffffffffc02032fa <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc0203744:	000a2703          	lw	a4,0(s4)
ffffffffc0203748:	4785                	li	a5,1
ffffffffc020374a:	68f71663          	bne	a4,a5,ffffffffc0203dd6 <pmm_init+0x94a>
    assert(page_ref(p2) == 0);
ffffffffc020374e:	000aa783          	lw	a5,0(s5)
ffffffffc0203752:	74079e63          	bnez	a5,ffffffffc0203eae <pmm_init+0xa22>

    page_remove(boot_pgdir, PGSIZE);
ffffffffc0203756:	00093503          	ld	a0,0(s2)
ffffffffc020375a:	6585                	lui	a1,0x1
ffffffffc020375c:	b9fff0ef          	jal	ra,ffffffffc02032fa <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc0203760:	000a2783          	lw	a5,0(s4)
ffffffffc0203764:	72079563          	bnez	a5,ffffffffc0203e8e <pmm_init+0xa02>
    assert(page_ref(p2) == 0);
ffffffffc0203768:	000aa783          	lw	a5,0(s5)
ffffffffc020376c:	70079163          	bnez	a5,ffffffffc0203e6e <pmm_init+0x9e2>

    assert(page_ref(pde2page(boot_pgdir[0])) == 1);
ffffffffc0203770:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage) {
ffffffffc0203774:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0203776:	000a3683          	ld	a3,0(s4)
ffffffffc020377a:	068a                	slli	a3,a3,0x2
ffffffffc020377c:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage) {
ffffffffc020377e:	3ee6f363          	bgeu	a3,a4,ffffffffc0203b64 <pmm_init+0x6d8>
    return &pages[PPN(pa) - nbase];
ffffffffc0203782:	fff807b7          	lui	a5,0xfff80
ffffffffc0203786:	000b3503          	ld	a0,0(s6)
ffffffffc020378a:	96be                	add	a3,a3,a5
ffffffffc020378c:	069a                	slli	a3,a3,0x6
    return page->ref;
ffffffffc020378e:	00d507b3          	add	a5,a0,a3
ffffffffc0203792:	4390                	lw	a2,0(a5)
ffffffffc0203794:	4785                	li	a5,1
ffffffffc0203796:	6af61c63          	bne	a2,a5,ffffffffc0203e4e <pmm_init+0x9c2>
    return page - pages + nbase;
ffffffffc020379a:	8699                	srai	a3,a3,0x6
ffffffffc020379c:	000805b7          	lui	a1,0x80
ffffffffc02037a0:	96ae                	add	a3,a3,a1
    return KADDR(page2pa(page));
ffffffffc02037a2:	00c69613          	slli	a2,a3,0xc
ffffffffc02037a6:	8231                	srli	a2,a2,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc02037a8:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02037aa:	68e67663          	bgeu	a2,a4,ffffffffc0203e36 <pmm_init+0x9aa>

    pde_t *pd1=boot_pgdir,*pd0=page2kva(pde2page(boot_pgdir[0]));
    free_page(pde2page(pd0[0]));
ffffffffc02037ae:	0009b603          	ld	a2,0(s3)
ffffffffc02037b2:	96b2                	add	a3,a3,a2
    return pa2page(PDE_ADDR(pde));
ffffffffc02037b4:	629c                	ld	a5,0(a3)
ffffffffc02037b6:	078a                	slli	a5,a5,0x2
ffffffffc02037b8:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02037ba:	3ae7f563          	bgeu	a5,a4,ffffffffc0203b64 <pmm_init+0x6d8>
    return &pages[PPN(pa) - nbase];
ffffffffc02037be:	8f8d                	sub	a5,a5,a1
ffffffffc02037c0:	079a                	slli	a5,a5,0x6
ffffffffc02037c2:	953e                	add	a0,a0,a5
ffffffffc02037c4:	100027f3          	csrr	a5,sstatus
ffffffffc02037c8:	8b89                	andi	a5,a5,2
ffffffffc02037ca:	2c079763          	bnez	a5,ffffffffc0203a98 <pmm_init+0x60c>
        pmm_manager->free_pages(base, n);
ffffffffc02037ce:	000bb783          	ld	a5,0(s7)
ffffffffc02037d2:	4585                	li	a1,1
ffffffffc02037d4:	739c                	ld	a5,32(a5)
ffffffffc02037d6:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc02037d8:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage) {
ffffffffc02037dc:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc02037de:	078a                	slli	a5,a5,0x2
ffffffffc02037e0:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02037e2:	38e7f163          	bgeu	a5,a4,ffffffffc0203b64 <pmm_init+0x6d8>
    return &pages[PPN(pa) - nbase];
ffffffffc02037e6:	000b3503          	ld	a0,0(s6)
ffffffffc02037ea:	fff80737          	lui	a4,0xfff80
ffffffffc02037ee:	97ba                	add	a5,a5,a4
ffffffffc02037f0:	079a                	slli	a5,a5,0x6
ffffffffc02037f2:	953e                	add	a0,a0,a5
ffffffffc02037f4:	100027f3          	csrr	a5,sstatus
ffffffffc02037f8:	8b89                	andi	a5,a5,2
ffffffffc02037fa:	28079363          	bnez	a5,ffffffffc0203a80 <pmm_init+0x5f4>
ffffffffc02037fe:	000bb783          	ld	a5,0(s7)
ffffffffc0203802:	4585                	li	a1,1
ffffffffc0203804:	739c                	ld	a5,32(a5)
ffffffffc0203806:	9782                	jalr	a5
    free_page(pde2page(pd1[0]));
    boot_pgdir[0] = 0;
ffffffffc0203808:	00093783          	ld	a5,0(s2)
ffffffffc020380c:	0007b023          	sd	zero,0(a5) # fffffffffff80000 <end+0x3fd69a34>
  asm volatile("sfence.vma");
ffffffffc0203810:	12000073          	sfence.vma
ffffffffc0203814:	100027f3          	csrr	a5,sstatus
ffffffffc0203818:	8b89                	andi	a5,a5,2
ffffffffc020381a:	24079963          	bnez	a5,ffffffffc0203a6c <pmm_init+0x5e0>
        ret = pmm_manager->nr_free_pages();
ffffffffc020381e:	000bb783          	ld	a5,0(s7)
ffffffffc0203822:	779c                	ld	a5,40(a5)
ffffffffc0203824:	9782                	jalr	a5
ffffffffc0203826:	8a2a                	mv	s4,a0
    flush_tlb();

    assert(nr_free_store==nr_free_pages());
ffffffffc0203828:	71441363          	bne	s0,s4,ffffffffc0203f2e <pmm_init+0xaa2>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc020382c:	00003517          	auipc	a0,0x3
ffffffffc0203830:	1bc50513          	addi	a0,a0,444 # ffffffffc02069e8 <default_pmm_manager+0x3a0>
ffffffffc0203834:	899fc0ef          	jal	ra,ffffffffc02000cc <cprintf>
ffffffffc0203838:	100027f3          	csrr	a5,sstatus
ffffffffc020383c:	8b89                	andi	a5,a5,2
ffffffffc020383e:	20079d63          	bnez	a5,ffffffffc0203a58 <pmm_init+0x5cc>
        ret = pmm_manager->nr_free_pages();
ffffffffc0203842:	000bb783          	ld	a5,0(s7)
ffffffffc0203846:	779c                	ld	a5,40(a5)
ffffffffc0203848:	9782                	jalr	a5
ffffffffc020384a:	8c2a                	mv	s8,a0
    pte_t *ptep;
    int i;

    nr_free_store=nr_free_pages();

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc020384c:	6098                	ld	a4,0(s1)
ffffffffc020384e:	c0200437          	lui	s0,0xc0200
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0203852:	7afd                	lui	s5,0xfffff
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc0203854:	00c71793          	slli	a5,a4,0xc
ffffffffc0203858:	6a05                	lui	s4,0x1
ffffffffc020385a:	02f47c63          	bgeu	s0,a5,ffffffffc0203892 <pmm_init+0x406>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc020385e:	00c45793          	srli	a5,s0,0xc
ffffffffc0203862:	00093503          	ld	a0,0(s2)
ffffffffc0203866:	2ee7f263          	bgeu	a5,a4,ffffffffc0203b4a <pmm_init+0x6be>
ffffffffc020386a:	0009b583          	ld	a1,0(s3)
ffffffffc020386e:	4601                	li	a2,0
ffffffffc0203870:	95a2                	add	a1,a1,s0
ffffffffc0203872:	863ff0ef          	jal	ra,ffffffffc02030d4 <get_pte>
ffffffffc0203876:	2a050a63          	beqz	a0,ffffffffc0203b2a <pmm_init+0x69e>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc020387a:	611c                	ld	a5,0(a0)
ffffffffc020387c:	078a                	slli	a5,a5,0x2
ffffffffc020387e:	0157f7b3          	and	a5,a5,s5
ffffffffc0203882:	28879463          	bne	a5,s0,ffffffffc0203b0a <pmm_init+0x67e>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc0203886:	6098                	ld	a4,0(s1)
ffffffffc0203888:	9452                	add	s0,s0,s4
ffffffffc020388a:	00c71793          	slli	a5,a4,0xc
ffffffffc020388e:	fcf468e3          	bltu	s0,a5,ffffffffc020385e <pmm_init+0x3d2>
    }

    assert(boot_pgdir[0] == 0);
ffffffffc0203892:	00093783          	ld	a5,0(s2)
ffffffffc0203896:	639c                	ld	a5,0(a5)
ffffffffc0203898:	66079b63          	bnez	a5,ffffffffc0203f0e <pmm_init+0xa82>

    struct Page *p;
    p = alloc_page();
ffffffffc020389c:	4505                	li	a0,1
ffffffffc020389e:	f2aff0ef          	jal	ra,ffffffffc0202fc8 <alloc_pages>
ffffffffc02038a2:	8aaa                	mv	s5,a0
    assert(page_insert(boot_pgdir, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc02038a4:	00093503          	ld	a0,0(s2)
ffffffffc02038a8:	4699                	li	a3,6
ffffffffc02038aa:	10000613          	li	a2,256
ffffffffc02038ae:	85d6                	mv	a1,s5
ffffffffc02038b0:	ae7ff0ef          	jal	ra,ffffffffc0203396 <page_insert>
ffffffffc02038b4:	62051d63          	bnez	a0,ffffffffc0203eee <pmm_init+0xa62>
    assert(page_ref(p) == 1);
ffffffffc02038b8:	000aa703          	lw	a4,0(s5) # fffffffffffff000 <end+0x3fde8a34>
ffffffffc02038bc:	4785                	li	a5,1
ffffffffc02038be:	60f71863          	bne	a4,a5,ffffffffc0203ece <pmm_init+0xa42>
    assert(page_insert(boot_pgdir, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc02038c2:	00093503          	ld	a0,0(s2)
ffffffffc02038c6:	6405                	lui	s0,0x1
ffffffffc02038c8:	4699                	li	a3,6
ffffffffc02038ca:	10040613          	addi	a2,s0,256 # 1100 <kern_entry-0xffffffffc01fef00>
ffffffffc02038ce:	85d6                	mv	a1,s5
ffffffffc02038d0:	ac7ff0ef          	jal	ra,ffffffffc0203396 <page_insert>
ffffffffc02038d4:	46051163          	bnez	a0,ffffffffc0203d36 <pmm_init+0x8aa>
    assert(page_ref(p) == 2);
ffffffffc02038d8:	000aa703          	lw	a4,0(s5)
ffffffffc02038dc:	4789                	li	a5,2
ffffffffc02038de:	72f71463          	bne	a4,a5,ffffffffc0204006 <pmm_init+0xb7a>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc02038e2:	00003597          	auipc	a1,0x3
ffffffffc02038e6:	23e58593          	addi	a1,a1,574 # ffffffffc0206b20 <default_pmm_manager+0x4d8>
ffffffffc02038ea:	10000513          	li	a0,256
ffffffffc02038ee:	198010ef          	jal	ra,ffffffffc0204a86 <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc02038f2:	10040593          	addi	a1,s0,256
ffffffffc02038f6:	10000513          	li	a0,256
ffffffffc02038fa:	19e010ef          	jal	ra,ffffffffc0204a98 <strcmp>
ffffffffc02038fe:	6e051463          	bnez	a0,ffffffffc0203fe6 <pmm_init+0xb5a>
    return page - pages + nbase;
ffffffffc0203902:	000b3683          	ld	a3,0(s6)
ffffffffc0203906:	00080737          	lui	a4,0x80
    return KADDR(page2pa(page));
ffffffffc020390a:	547d                	li	s0,-1
    return page - pages + nbase;
ffffffffc020390c:	40da86b3          	sub	a3,s5,a3
ffffffffc0203910:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0203912:	609c                	ld	a5,0(s1)
    return page - pages + nbase;
ffffffffc0203914:	96ba                	add	a3,a3,a4
    return KADDR(page2pa(page));
ffffffffc0203916:	8031                	srli	s0,s0,0xc
ffffffffc0203918:	0086f733          	and	a4,a3,s0
    return page2ppn(page) << PGSHIFT;
ffffffffc020391c:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc020391e:	50f77c63          	bgeu	a4,a5,ffffffffc0203e36 <pmm_init+0x9aa>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0203922:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0203926:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc020392a:	96be                	add	a3,a3,a5
ffffffffc020392c:	10068023          	sb	zero,256(a3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0203930:	120010ef          	jal	ra,ffffffffc0204a50 <strlen>
ffffffffc0203934:	68051963          	bnez	a0,ffffffffc0203fc6 <pmm_init+0xb3a>

    pde_t *pd1=boot_pgdir,*pd0=page2kva(pde2page(boot_pgdir[0]));
ffffffffc0203938:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage) {
ffffffffc020393c:	609c                	ld	a5,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc020393e:	000a3683          	ld	a3,0(s4) # 1000 <kern_entry-0xffffffffc01ff000>
ffffffffc0203942:	068a                	slli	a3,a3,0x2
ffffffffc0203944:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage) {
ffffffffc0203946:	20f6ff63          	bgeu	a3,a5,ffffffffc0203b64 <pmm_init+0x6d8>
    return KADDR(page2pa(page));
ffffffffc020394a:	8c75                	and	s0,s0,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc020394c:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc020394e:	4ef47463          	bgeu	s0,a5,ffffffffc0203e36 <pmm_init+0x9aa>
ffffffffc0203952:	0009b403          	ld	s0,0(s3)
ffffffffc0203956:	9436                	add	s0,s0,a3
ffffffffc0203958:	100027f3          	csrr	a5,sstatus
ffffffffc020395c:	8b89                	andi	a5,a5,2
ffffffffc020395e:	18079b63          	bnez	a5,ffffffffc0203af4 <pmm_init+0x668>
        pmm_manager->free_pages(base, n);
ffffffffc0203962:	000bb783          	ld	a5,0(s7)
ffffffffc0203966:	4585                	li	a1,1
ffffffffc0203968:	8556                	mv	a0,s5
ffffffffc020396a:	739c                	ld	a5,32(a5)
ffffffffc020396c:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc020396e:	601c                	ld	a5,0(s0)
    if (PPN(pa) >= npage) {
ffffffffc0203970:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0203972:	078a                	slli	a5,a5,0x2
ffffffffc0203974:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0203976:	1ee7f763          	bgeu	a5,a4,ffffffffc0203b64 <pmm_init+0x6d8>
    return &pages[PPN(pa) - nbase];
ffffffffc020397a:	000b3503          	ld	a0,0(s6)
ffffffffc020397e:	fff80737          	lui	a4,0xfff80
ffffffffc0203982:	97ba                	add	a5,a5,a4
ffffffffc0203984:	079a                	slli	a5,a5,0x6
ffffffffc0203986:	953e                	add	a0,a0,a5
ffffffffc0203988:	100027f3          	csrr	a5,sstatus
ffffffffc020398c:	8b89                	andi	a5,a5,2
ffffffffc020398e:	14079763          	bnez	a5,ffffffffc0203adc <pmm_init+0x650>
ffffffffc0203992:	000bb783          	ld	a5,0(s7)
ffffffffc0203996:	4585                	li	a1,1
ffffffffc0203998:	739c                	ld	a5,32(a5)
ffffffffc020399a:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc020399c:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage) {
ffffffffc02039a0:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc02039a2:	078a                	slli	a5,a5,0x2
ffffffffc02039a4:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02039a6:	1ae7ff63          	bgeu	a5,a4,ffffffffc0203b64 <pmm_init+0x6d8>
    return &pages[PPN(pa) - nbase];
ffffffffc02039aa:	000b3503          	ld	a0,0(s6)
ffffffffc02039ae:	fff80737          	lui	a4,0xfff80
ffffffffc02039b2:	97ba                	add	a5,a5,a4
ffffffffc02039b4:	079a                	slli	a5,a5,0x6
ffffffffc02039b6:	953e                	add	a0,a0,a5
ffffffffc02039b8:	100027f3          	csrr	a5,sstatus
ffffffffc02039bc:	8b89                	andi	a5,a5,2
ffffffffc02039be:	10079363          	bnez	a5,ffffffffc0203ac4 <pmm_init+0x638>
ffffffffc02039c2:	000bb783          	ld	a5,0(s7)
ffffffffc02039c6:	4585                	li	a1,1
ffffffffc02039c8:	739c                	ld	a5,32(a5)
ffffffffc02039ca:	9782                	jalr	a5
    free_page(p);
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir[0] = 0;
ffffffffc02039cc:	00093783          	ld	a5,0(s2)
ffffffffc02039d0:	0007b023          	sd	zero,0(a5)
  asm volatile("sfence.vma");
ffffffffc02039d4:	12000073          	sfence.vma
ffffffffc02039d8:	100027f3          	csrr	a5,sstatus
ffffffffc02039dc:	8b89                	andi	a5,a5,2
ffffffffc02039de:	0c079963          	bnez	a5,ffffffffc0203ab0 <pmm_init+0x624>
        ret = pmm_manager->nr_free_pages();
ffffffffc02039e2:	000bb783          	ld	a5,0(s7)
ffffffffc02039e6:	779c                	ld	a5,40(a5)
ffffffffc02039e8:	9782                	jalr	a5
ffffffffc02039ea:	842a                	mv	s0,a0
    flush_tlb();

    assert(nr_free_store==nr_free_pages());
ffffffffc02039ec:	3a8c1563          	bne	s8,s0,ffffffffc0203d96 <pmm_init+0x90a>

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc02039f0:	00003517          	auipc	a0,0x3
ffffffffc02039f4:	1a850513          	addi	a0,a0,424 # ffffffffc0206b98 <default_pmm_manager+0x550>
ffffffffc02039f8:	ed4fc0ef          	jal	ra,ffffffffc02000cc <cprintf>
}
ffffffffc02039fc:	6446                	ld	s0,80(sp)
ffffffffc02039fe:	60e6                	ld	ra,88(sp)
ffffffffc0203a00:	64a6                	ld	s1,72(sp)
ffffffffc0203a02:	6906                	ld	s2,64(sp)
ffffffffc0203a04:	79e2                	ld	s3,56(sp)
ffffffffc0203a06:	7a42                	ld	s4,48(sp)
ffffffffc0203a08:	7aa2                	ld	s5,40(sp)
ffffffffc0203a0a:	7b02                	ld	s6,32(sp)
ffffffffc0203a0c:	6be2                	ld	s7,24(sp)
ffffffffc0203a0e:	6c42                	ld	s8,16(sp)
ffffffffc0203a10:	6125                	addi	sp,sp,96
    kmalloc_init();
ffffffffc0203a12:	80efe06f          	j	ffffffffc0201a20 <kmalloc_init>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0203a16:	6785                	lui	a5,0x1
ffffffffc0203a18:	17fd                	addi	a5,a5,-1
ffffffffc0203a1a:	96be                	add	a3,a3,a5
ffffffffc0203a1c:	77fd                	lui	a5,0xfffff
ffffffffc0203a1e:	8ff5                	and	a5,a5,a3
    if (PPN(pa) >= npage) {
ffffffffc0203a20:	00c7d693          	srli	a3,a5,0xc
ffffffffc0203a24:	14c6f063          	bgeu	a3,a2,ffffffffc0203b64 <pmm_init+0x6d8>
    pmm_manager->init_memmap(base, n);
ffffffffc0203a28:	000bb603          	ld	a2,0(s7)
    return &pages[PPN(pa) - nbase];
ffffffffc0203a2c:	96c2                	add	a3,a3,a6
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0203a2e:	40f707b3          	sub	a5,a4,a5
    pmm_manager->init_memmap(base, n);
ffffffffc0203a32:	6a10                	ld	a2,16(a2)
ffffffffc0203a34:	069a                	slli	a3,a3,0x6
ffffffffc0203a36:	00c7d593          	srli	a1,a5,0xc
ffffffffc0203a3a:	9536                	add	a0,a0,a3
ffffffffc0203a3c:	9602                	jalr	a2
    cprintf("vapaofset is %llu\n",va_pa_offset);
ffffffffc0203a3e:	0009b583          	ld	a1,0(s3)
}
ffffffffc0203a42:	b63d                	j	ffffffffc0203570 <pmm_init+0xe4>
        intr_disable();
ffffffffc0203a44:	b81fc0ef          	jal	ra,ffffffffc02005c4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0203a48:	000bb783          	ld	a5,0(s7)
ffffffffc0203a4c:	779c                	ld	a5,40(a5)
ffffffffc0203a4e:	9782                	jalr	a5
ffffffffc0203a50:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0203a52:	b6dfc0ef          	jal	ra,ffffffffc02005be <intr_enable>
ffffffffc0203a56:	bea5                	j	ffffffffc02035ce <pmm_init+0x142>
        intr_disable();
ffffffffc0203a58:	b6dfc0ef          	jal	ra,ffffffffc02005c4 <intr_disable>
ffffffffc0203a5c:	000bb783          	ld	a5,0(s7)
ffffffffc0203a60:	779c                	ld	a5,40(a5)
ffffffffc0203a62:	9782                	jalr	a5
ffffffffc0203a64:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0203a66:	b59fc0ef          	jal	ra,ffffffffc02005be <intr_enable>
ffffffffc0203a6a:	b3cd                	j	ffffffffc020384c <pmm_init+0x3c0>
        intr_disable();
ffffffffc0203a6c:	b59fc0ef          	jal	ra,ffffffffc02005c4 <intr_disable>
ffffffffc0203a70:	000bb783          	ld	a5,0(s7)
ffffffffc0203a74:	779c                	ld	a5,40(a5)
ffffffffc0203a76:	9782                	jalr	a5
ffffffffc0203a78:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0203a7a:	b45fc0ef          	jal	ra,ffffffffc02005be <intr_enable>
ffffffffc0203a7e:	b36d                	j	ffffffffc0203828 <pmm_init+0x39c>
ffffffffc0203a80:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0203a82:	b43fc0ef          	jal	ra,ffffffffc02005c4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0203a86:	000bb783          	ld	a5,0(s7)
ffffffffc0203a8a:	6522                	ld	a0,8(sp)
ffffffffc0203a8c:	4585                	li	a1,1
ffffffffc0203a8e:	739c                	ld	a5,32(a5)
ffffffffc0203a90:	9782                	jalr	a5
        intr_enable();
ffffffffc0203a92:	b2dfc0ef          	jal	ra,ffffffffc02005be <intr_enable>
ffffffffc0203a96:	bb8d                	j	ffffffffc0203808 <pmm_init+0x37c>
ffffffffc0203a98:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0203a9a:	b2bfc0ef          	jal	ra,ffffffffc02005c4 <intr_disable>
ffffffffc0203a9e:	000bb783          	ld	a5,0(s7)
ffffffffc0203aa2:	6522                	ld	a0,8(sp)
ffffffffc0203aa4:	4585                	li	a1,1
ffffffffc0203aa6:	739c                	ld	a5,32(a5)
ffffffffc0203aa8:	9782                	jalr	a5
        intr_enable();
ffffffffc0203aaa:	b15fc0ef          	jal	ra,ffffffffc02005be <intr_enable>
ffffffffc0203aae:	b32d                	j	ffffffffc02037d8 <pmm_init+0x34c>
        intr_disable();
ffffffffc0203ab0:	b15fc0ef          	jal	ra,ffffffffc02005c4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0203ab4:	000bb783          	ld	a5,0(s7)
ffffffffc0203ab8:	779c                	ld	a5,40(a5)
ffffffffc0203aba:	9782                	jalr	a5
ffffffffc0203abc:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0203abe:	b01fc0ef          	jal	ra,ffffffffc02005be <intr_enable>
ffffffffc0203ac2:	b72d                	j	ffffffffc02039ec <pmm_init+0x560>
ffffffffc0203ac4:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0203ac6:	afffc0ef          	jal	ra,ffffffffc02005c4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0203aca:	000bb783          	ld	a5,0(s7)
ffffffffc0203ace:	6522                	ld	a0,8(sp)
ffffffffc0203ad0:	4585                	li	a1,1
ffffffffc0203ad2:	739c                	ld	a5,32(a5)
ffffffffc0203ad4:	9782                	jalr	a5
        intr_enable();
ffffffffc0203ad6:	ae9fc0ef          	jal	ra,ffffffffc02005be <intr_enable>
ffffffffc0203ada:	bdcd                	j	ffffffffc02039cc <pmm_init+0x540>
ffffffffc0203adc:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0203ade:	ae7fc0ef          	jal	ra,ffffffffc02005c4 <intr_disable>
ffffffffc0203ae2:	000bb783          	ld	a5,0(s7)
ffffffffc0203ae6:	6522                	ld	a0,8(sp)
ffffffffc0203ae8:	4585                	li	a1,1
ffffffffc0203aea:	739c                	ld	a5,32(a5)
ffffffffc0203aec:	9782                	jalr	a5
        intr_enable();
ffffffffc0203aee:	ad1fc0ef          	jal	ra,ffffffffc02005be <intr_enable>
ffffffffc0203af2:	b56d                	j	ffffffffc020399c <pmm_init+0x510>
        intr_disable();
ffffffffc0203af4:	ad1fc0ef          	jal	ra,ffffffffc02005c4 <intr_disable>
ffffffffc0203af8:	000bb783          	ld	a5,0(s7)
ffffffffc0203afc:	4585                	li	a1,1
ffffffffc0203afe:	8556                	mv	a0,s5
ffffffffc0203b00:	739c                	ld	a5,32(a5)
ffffffffc0203b02:	9782                	jalr	a5
        intr_enable();
ffffffffc0203b04:	abbfc0ef          	jal	ra,ffffffffc02005be <intr_enable>
ffffffffc0203b08:	b59d                	j	ffffffffc020396e <pmm_init+0x4e2>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0203b0a:	00003697          	auipc	a3,0x3
ffffffffc0203b0e:	f3e68693          	addi	a3,a3,-194 # ffffffffc0206a48 <default_pmm_manager+0x400>
ffffffffc0203b12:	00002617          	auipc	a2,0x2
ffffffffc0203b16:	dbe60613          	addi	a2,a2,-578 # ffffffffc02058d0 <commands+0x728>
ffffffffc0203b1a:	19e00593          	li	a1,414
ffffffffc0203b1e:	00003517          	auipc	a0,0x3
ffffffffc0203b22:	b6250513          	addi	a0,a0,-1182 # ffffffffc0206680 <default_pmm_manager+0x38>
ffffffffc0203b26:	ea2fc0ef          	jal	ra,ffffffffc02001c8 <__panic>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0203b2a:	00003697          	auipc	a3,0x3
ffffffffc0203b2e:	ede68693          	addi	a3,a3,-290 # ffffffffc0206a08 <default_pmm_manager+0x3c0>
ffffffffc0203b32:	00002617          	auipc	a2,0x2
ffffffffc0203b36:	d9e60613          	addi	a2,a2,-610 # ffffffffc02058d0 <commands+0x728>
ffffffffc0203b3a:	19d00593          	li	a1,413
ffffffffc0203b3e:	00003517          	auipc	a0,0x3
ffffffffc0203b42:	b4250513          	addi	a0,a0,-1214 # ffffffffc0206680 <default_pmm_manager+0x38>
ffffffffc0203b46:	e82fc0ef          	jal	ra,ffffffffc02001c8 <__panic>
ffffffffc0203b4a:	86a2                	mv	a3,s0
ffffffffc0203b4c:	00002617          	auipc	a2,0x2
ffffffffc0203b50:	fdc60613          	addi	a2,a2,-36 # ffffffffc0205b28 <commands+0x980>
ffffffffc0203b54:	19d00593          	li	a1,413
ffffffffc0203b58:	00003517          	auipc	a0,0x3
ffffffffc0203b5c:	b2850513          	addi	a0,a0,-1240 # ffffffffc0206680 <default_pmm_manager+0x38>
ffffffffc0203b60:	e68fc0ef          	jal	ra,ffffffffc02001c8 <__panic>
ffffffffc0203b64:	c2cff0ef          	jal	ra,ffffffffc0202f90 <pa2page.part.0>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0203b68:	00002617          	auipc	a2,0x2
ffffffffc0203b6c:	39060613          	addi	a2,a2,912 # ffffffffc0205ef8 <commands+0xd50>
ffffffffc0203b70:	07f00593          	li	a1,127
ffffffffc0203b74:	00003517          	auipc	a0,0x3
ffffffffc0203b78:	b0c50513          	addi	a0,a0,-1268 # ffffffffc0206680 <default_pmm_manager+0x38>
ffffffffc0203b7c:	e4cfc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    boot_cr3 = PADDR(boot_pgdir);
ffffffffc0203b80:	00002617          	auipc	a2,0x2
ffffffffc0203b84:	37860613          	addi	a2,a2,888 # ffffffffc0205ef8 <commands+0xd50>
ffffffffc0203b88:	0c300593          	li	a1,195
ffffffffc0203b8c:	00003517          	auipc	a0,0x3
ffffffffc0203b90:	af450513          	addi	a0,a0,-1292 # ffffffffc0206680 <default_pmm_manager+0x38>
ffffffffc0203b94:	e34fc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(boot_pgdir != NULL && (uint32_t)PGOFF(boot_pgdir) == 0);
ffffffffc0203b98:	00003697          	auipc	a3,0x3
ffffffffc0203b9c:	ba868693          	addi	a3,a3,-1112 # ffffffffc0206740 <default_pmm_manager+0xf8>
ffffffffc0203ba0:	00002617          	auipc	a2,0x2
ffffffffc0203ba4:	d3060613          	addi	a2,a2,-720 # ffffffffc02058d0 <commands+0x728>
ffffffffc0203ba8:	16100593          	li	a1,353
ffffffffc0203bac:	00003517          	auipc	a0,0x3
ffffffffc0203bb0:	ad450513          	addi	a0,a0,-1324 # ffffffffc0206680 <default_pmm_manager+0x38>
ffffffffc0203bb4:	e14fc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0203bb8:	00003697          	auipc	a3,0x3
ffffffffc0203bbc:	b6868693          	addi	a3,a3,-1176 # ffffffffc0206720 <default_pmm_manager+0xd8>
ffffffffc0203bc0:	00002617          	auipc	a2,0x2
ffffffffc0203bc4:	d1060613          	addi	a2,a2,-752 # ffffffffc02058d0 <commands+0x728>
ffffffffc0203bc8:	16000593          	li	a1,352
ffffffffc0203bcc:	00003517          	auipc	a0,0x3
ffffffffc0203bd0:	ab450513          	addi	a0,a0,-1356 # ffffffffc0206680 <default_pmm_manager+0x38>
ffffffffc0203bd4:	df4fc0ef          	jal	ra,ffffffffc02001c8 <__panic>
ffffffffc0203bd8:	bd4ff0ef          	jal	ra,ffffffffc0202fac <pte2page.part.0>
    assert((ptep = get_pte(boot_pgdir, 0x0, 0)) != NULL);
ffffffffc0203bdc:	00003697          	auipc	a3,0x3
ffffffffc0203be0:	bf468693          	addi	a3,a3,-1036 # ffffffffc02067d0 <default_pmm_manager+0x188>
ffffffffc0203be4:	00002617          	auipc	a2,0x2
ffffffffc0203be8:	cec60613          	addi	a2,a2,-788 # ffffffffc02058d0 <commands+0x728>
ffffffffc0203bec:	16900593          	li	a1,361
ffffffffc0203bf0:	00003517          	auipc	a0,0x3
ffffffffc0203bf4:	a9050513          	addi	a0,a0,-1392 # ffffffffc0206680 <default_pmm_manager+0x38>
ffffffffc0203bf8:	dd0fc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(page_insert(boot_pgdir, p1, 0x0, 0) == 0);
ffffffffc0203bfc:	00003697          	auipc	a3,0x3
ffffffffc0203c00:	ba468693          	addi	a3,a3,-1116 # ffffffffc02067a0 <default_pmm_manager+0x158>
ffffffffc0203c04:	00002617          	auipc	a2,0x2
ffffffffc0203c08:	ccc60613          	addi	a2,a2,-820 # ffffffffc02058d0 <commands+0x728>
ffffffffc0203c0c:	16600593          	li	a1,358
ffffffffc0203c10:	00003517          	auipc	a0,0x3
ffffffffc0203c14:	a7050513          	addi	a0,a0,-1424 # ffffffffc0206680 <default_pmm_manager+0x38>
ffffffffc0203c18:	db0fc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(get_page(boot_pgdir, 0x0, NULL) == NULL);
ffffffffc0203c1c:	00003697          	auipc	a3,0x3
ffffffffc0203c20:	b5c68693          	addi	a3,a3,-1188 # ffffffffc0206778 <default_pmm_manager+0x130>
ffffffffc0203c24:	00002617          	auipc	a2,0x2
ffffffffc0203c28:	cac60613          	addi	a2,a2,-852 # ffffffffc02058d0 <commands+0x728>
ffffffffc0203c2c:	16200593          	li	a1,354
ffffffffc0203c30:	00003517          	auipc	a0,0x3
ffffffffc0203c34:	a5050513          	addi	a0,a0,-1456 # ffffffffc0206680 <default_pmm_manager+0x38>
ffffffffc0203c38:	d90fc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(page_insert(boot_pgdir, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0203c3c:	00003697          	auipc	a3,0x3
ffffffffc0203c40:	c1c68693          	addi	a3,a3,-996 # ffffffffc0206858 <default_pmm_manager+0x210>
ffffffffc0203c44:	00002617          	auipc	a2,0x2
ffffffffc0203c48:	c8c60613          	addi	a2,a2,-884 # ffffffffc02058d0 <commands+0x728>
ffffffffc0203c4c:	17200593          	li	a1,370
ffffffffc0203c50:	00003517          	auipc	a0,0x3
ffffffffc0203c54:	a3050513          	addi	a0,a0,-1488 # ffffffffc0206680 <default_pmm_manager+0x38>
ffffffffc0203c58:	d70fc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(page_ref(p2) == 1);
ffffffffc0203c5c:	00003697          	auipc	a3,0x3
ffffffffc0203c60:	c9c68693          	addi	a3,a3,-868 # ffffffffc02068f8 <default_pmm_manager+0x2b0>
ffffffffc0203c64:	00002617          	auipc	a2,0x2
ffffffffc0203c68:	c6c60613          	addi	a2,a2,-916 # ffffffffc02058d0 <commands+0x728>
ffffffffc0203c6c:	17700593          	li	a1,375
ffffffffc0203c70:	00003517          	auipc	a0,0x3
ffffffffc0203c74:	a1050513          	addi	a0,a0,-1520 # ffffffffc0206680 <default_pmm_manager+0x38>
ffffffffc0203c78:	d50fc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc0203c7c:	00003697          	auipc	a3,0x3
ffffffffc0203c80:	bb468693          	addi	a3,a3,-1100 # ffffffffc0206830 <default_pmm_manager+0x1e8>
ffffffffc0203c84:	00002617          	auipc	a2,0x2
ffffffffc0203c88:	c4c60613          	addi	a2,a2,-948 # ffffffffc02058d0 <commands+0x728>
ffffffffc0203c8c:	16f00593          	li	a1,367
ffffffffc0203c90:	00003517          	auipc	a0,0x3
ffffffffc0203c94:	9f050513          	addi	a0,a0,-1552 # ffffffffc0206680 <default_pmm_manager+0x38>
ffffffffc0203c98:	d30fc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0203c9c:	86d6                	mv	a3,s5
ffffffffc0203c9e:	00002617          	auipc	a2,0x2
ffffffffc0203ca2:	e8a60613          	addi	a2,a2,-374 # ffffffffc0205b28 <commands+0x980>
ffffffffc0203ca6:	16e00593          	li	a1,366
ffffffffc0203caa:	00003517          	auipc	a0,0x3
ffffffffc0203cae:	9d650513          	addi	a0,a0,-1578 # ffffffffc0206680 <default_pmm_manager+0x38>
ffffffffc0203cb2:	d16fc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc0203cb6:	00003697          	auipc	a3,0x3
ffffffffc0203cba:	bda68693          	addi	a3,a3,-1062 # ffffffffc0206890 <default_pmm_manager+0x248>
ffffffffc0203cbe:	00002617          	auipc	a2,0x2
ffffffffc0203cc2:	c1260613          	addi	a2,a2,-1006 # ffffffffc02058d0 <commands+0x728>
ffffffffc0203cc6:	17c00593          	li	a1,380
ffffffffc0203cca:	00003517          	auipc	a0,0x3
ffffffffc0203cce:	9b650513          	addi	a0,a0,-1610 # ffffffffc0206680 <default_pmm_manager+0x38>
ffffffffc0203cd2:	cf6fc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0203cd6:	00003697          	auipc	a3,0x3
ffffffffc0203cda:	c8268693          	addi	a3,a3,-894 # ffffffffc0206958 <default_pmm_manager+0x310>
ffffffffc0203cde:	00002617          	auipc	a2,0x2
ffffffffc0203ce2:	bf260613          	addi	a2,a2,-1038 # ffffffffc02058d0 <commands+0x728>
ffffffffc0203ce6:	17b00593          	li	a1,379
ffffffffc0203cea:	00003517          	auipc	a0,0x3
ffffffffc0203cee:	99650513          	addi	a0,a0,-1642 # ffffffffc0206680 <default_pmm_manager+0x38>
ffffffffc0203cf2:	cd6fc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(page_ref(p1) == 2);
ffffffffc0203cf6:	00003697          	auipc	a3,0x3
ffffffffc0203cfa:	c4a68693          	addi	a3,a3,-950 # ffffffffc0206940 <default_pmm_manager+0x2f8>
ffffffffc0203cfe:	00002617          	auipc	a2,0x2
ffffffffc0203d02:	bd260613          	addi	a2,a2,-1070 # ffffffffc02058d0 <commands+0x728>
ffffffffc0203d06:	17a00593          	li	a1,378
ffffffffc0203d0a:	00003517          	auipc	a0,0x3
ffffffffc0203d0e:	97650513          	addi	a0,a0,-1674 # ffffffffc0206680 <default_pmm_manager+0x38>
ffffffffc0203d12:	cb6fc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(page_insert(boot_pgdir, p1, PGSIZE, 0) == 0);
ffffffffc0203d16:	00003697          	auipc	a3,0x3
ffffffffc0203d1a:	bfa68693          	addi	a3,a3,-1030 # ffffffffc0206910 <default_pmm_manager+0x2c8>
ffffffffc0203d1e:	00002617          	auipc	a2,0x2
ffffffffc0203d22:	bb260613          	addi	a2,a2,-1102 # ffffffffc02058d0 <commands+0x728>
ffffffffc0203d26:	17900593          	li	a1,377
ffffffffc0203d2a:	00003517          	auipc	a0,0x3
ffffffffc0203d2e:	95650513          	addi	a0,a0,-1706 # ffffffffc0206680 <default_pmm_manager+0x38>
ffffffffc0203d32:	c96fc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(page_insert(boot_pgdir, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0203d36:	00003697          	auipc	a3,0x3
ffffffffc0203d3a:	d9268693          	addi	a3,a3,-622 # ffffffffc0206ac8 <default_pmm_manager+0x480>
ffffffffc0203d3e:	00002617          	auipc	a2,0x2
ffffffffc0203d42:	b9260613          	addi	a2,a2,-1134 # ffffffffc02058d0 <commands+0x728>
ffffffffc0203d46:	1a700593          	li	a1,423
ffffffffc0203d4a:	00003517          	auipc	a0,0x3
ffffffffc0203d4e:	93650513          	addi	a0,a0,-1738 # ffffffffc0206680 <default_pmm_manager+0x38>
ffffffffc0203d52:	c76fc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(boot_pgdir[0] & PTE_U);
ffffffffc0203d56:	00003697          	auipc	a3,0x3
ffffffffc0203d5a:	b8a68693          	addi	a3,a3,-1142 # ffffffffc02068e0 <default_pmm_manager+0x298>
ffffffffc0203d5e:	00002617          	auipc	a2,0x2
ffffffffc0203d62:	b7260613          	addi	a2,a2,-1166 # ffffffffc02058d0 <commands+0x728>
ffffffffc0203d66:	17600593          	li	a1,374
ffffffffc0203d6a:	00003517          	auipc	a0,0x3
ffffffffc0203d6e:	91650513          	addi	a0,a0,-1770 # ffffffffc0206680 <default_pmm_manager+0x38>
ffffffffc0203d72:	c56fc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(*ptep & PTE_W);
ffffffffc0203d76:	00003697          	auipc	a3,0x3
ffffffffc0203d7a:	b5a68693          	addi	a3,a3,-1190 # ffffffffc02068d0 <default_pmm_manager+0x288>
ffffffffc0203d7e:	00002617          	auipc	a2,0x2
ffffffffc0203d82:	b5260613          	addi	a2,a2,-1198 # ffffffffc02058d0 <commands+0x728>
ffffffffc0203d86:	17500593          	li	a1,373
ffffffffc0203d8a:	00003517          	auipc	a0,0x3
ffffffffc0203d8e:	8f650513          	addi	a0,a0,-1802 # ffffffffc0206680 <default_pmm_manager+0x38>
ffffffffc0203d92:	c36fc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(nr_free_store==nr_free_pages());
ffffffffc0203d96:	00003697          	auipc	a3,0x3
ffffffffc0203d9a:	c3268693          	addi	a3,a3,-974 # ffffffffc02069c8 <default_pmm_manager+0x380>
ffffffffc0203d9e:	00002617          	auipc	a2,0x2
ffffffffc0203da2:	b3260613          	addi	a2,a2,-1230 # ffffffffc02058d0 <commands+0x728>
ffffffffc0203da6:	1b800593          	li	a1,440
ffffffffc0203daa:	00003517          	auipc	a0,0x3
ffffffffc0203dae:	8d650513          	addi	a0,a0,-1834 # ffffffffc0206680 <default_pmm_manager+0x38>
ffffffffc0203db2:	c16fc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(*ptep & PTE_U);
ffffffffc0203db6:	00003697          	auipc	a3,0x3
ffffffffc0203dba:	b0a68693          	addi	a3,a3,-1270 # ffffffffc02068c0 <default_pmm_manager+0x278>
ffffffffc0203dbe:	00002617          	auipc	a2,0x2
ffffffffc0203dc2:	b1260613          	addi	a2,a2,-1262 # ffffffffc02058d0 <commands+0x728>
ffffffffc0203dc6:	17400593          	li	a1,372
ffffffffc0203dca:	00003517          	auipc	a0,0x3
ffffffffc0203dce:	8b650513          	addi	a0,a0,-1866 # ffffffffc0206680 <default_pmm_manager+0x38>
ffffffffc0203dd2:	bf6fc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0203dd6:	00003697          	auipc	a3,0x3
ffffffffc0203dda:	a4268693          	addi	a3,a3,-1470 # ffffffffc0206818 <default_pmm_manager+0x1d0>
ffffffffc0203dde:	00002617          	auipc	a2,0x2
ffffffffc0203de2:	af260613          	addi	a2,a2,-1294 # ffffffffc02058d0 <commands+0x728>
ffffffffc0203de6:	18100593          	li	a1,385
ffffffffc0203dea:	00003517          	auipc	a0,0x3
ffffffffc0203dee:	89650513          	addi	a0,a0,-1898 # ffffffffc0206680 <default_pmm_manager+0x38>
ffffffffc0203df2:	bd6fc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc0203df6:	00003697          	auipc	a3,0x3
ffffffffc0203dfa:	b7a68693          	addi	a3,a3,-1158 # ffffffffc0206970 <default_pmm_manager+0x328>
ffffffffc0203dfe:	00002617          	auipc	a2,0x2
ffffffffc0203e02:	ad260613          	addi	a2,a2,-1326 # ffffffffc02058d0 <commands+0x728>
ffffffffc0203e06:	17e00593          	li	a1,382
ffffffffc0203e0a:	00003517          	auipc	a0,0x3
ffffffffc0203e0e:	87650513          	addi	a0,a0,-1930 # ffffffffc0206680 <default_pmm_manager+0x38>
ffffffffc0203e12:	bb6fc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0203e16:	00003697          	auipc	a3,0x3
ffffffffc0203e1a:	9ea68693          	addi	a3,a3,-1558 # ffffffffc0206800 <default_pmm_manager+0x1b8>
ffffffffc0203e1e:	00002617          	auipc	a2,0x2
ffffffffc0203e22:	ab260613          	addi	a2,a2,-1358 # ffffffffc02058d0 <commands+0x728>
ffffffffc0203e26:	17d00593          	li	a1,381
ffffffffc0203e2a:	00003517          	auipc	a0,0x3
ffffffffc0203e2e:	85650513          	addi	a0,a0,-1962 # ffffffffc0206680 <default_pmm_manager+0x38>
ffffffffc0203e32:	b96fc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    return KADDR(page2pa(page));
ffffffffc0203e36:	00002617          	auipc	a2,0x2
ffffffffc0203e3a:	cf260613          	addi	a2,a2,-782 # ffffffffc0205b28 <commands+0x980>
ffffffffc0203e3e:	06900593          	li	a1,105
ffffffffc0203e42:	00002517          	auipc	a0,0x2
ffffffffc0203e46:	cd650513          	addi	a0,a0,-810 # ffffffffc0205b18 <commands+0x970>
ffffffffc0203e4a:	b7efc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(page_ref(pde2page(boot_pgdir[0])) == 1);
ffffffffc0203e4e:	00003697          	auipc	a3,0x3
ffffffffc0203e52:	b5268693          	addi	a3,a3,-1198 # ffffffffc02069a0 <default_pmm_manager+0x358>
ffffffffc0203e56:	00002617          	auipc	a2,0x2
ffffffffc0203e5a:	a7a60613          	addi	a2,a2,-1414 # ffffffffc02058d0 <commands+0x728>
ffffffffc0203e5e:	18800593          	li	a1,392
ffffffffc0203e62:	00003517          	auipc	a0,0x3
ffffffffc0203e66:	81e50513          	addi	a0,a0,-2018 # ffffffffc0206680 <default_pmm_manager+0x38>
ffffffffc0203e6a:	b5efc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0203e6e:	00003697          	auipc	a3,0x3
ffffffffc0203e72:	aea68693          	addi	a3,a3,-1302 # ffffffffc0206958 <default_pmm_manager+0x310>
ffffffffc0203e76:	00002617          	auipc	a2,0x2
ffffffffc0203e7a:	a5a60613          	addi	a2,a2,-1446 # ffffffffc02058d0 <commands+0x728>
ffffffffc0203e7e:	18600593          	li	a1,390
ffffffffc0203e82:	00002517          	auipc	a0,0x2
ffffffffc0203e86:	7fe50513          	addi	a0,a0,2046 # ffffffffc0206680 <default_pmm_manager+0x38>
ffffffffc0203e8a:	b3efc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(page_ref(p1) == 0);
ffffffffc0203e8e:	00003697          	auipc	a3,0x3
ffffffffc0203e92:	afa68693          	addi	a3,a3,-1286 # ffffffffc0206988 <default_pmm_manager+0x340>
ffffffffc0203e96:	00002617          	auipc	a2,0x2
ffffffffc0203e9a:	a3a60613          	addi	a2,a2,-1478 # ffffffffc02058d0 <commands+0x728>
ffffffffc0203e9e:	18500593          	li	a1,389
ffffffffc0203ea2:	00002517          	auipc	a0,0x2
ffffffffc0203ea6:	7de50513          	addi	a0,a0,2014 # ffffffffc0206680 <default_pmm_manager+0x38>
ffffffffc0203eaa:	b1efc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0203eae:	00003697          	auipc	a3,0x3
ffffffffc0203eb2:	aaa68693          	addi	a3,a3,-1366 # ffffffffc0206958 <default_pmm_manager+0x310>
ffffffffc0203eb6:	00002617          	auipc	a2,0x2
ffffffffc0203eba:	a1a60613          	addi	a2,a2,-1510 # ffffffffc02058d0 <commands+0x728>
ffffffffc0203ebe:	18200593          	li	a1,386
ffffffffc0203ec2:	00002517          	auipc	a0,0x2
ffffffffc0203ec6:	7be50513          	addi	a0,a0,1982 # ffffffffc0206680 <default_pmm_manager+0x38>
ffffffffc0203eca:	afefc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(page_ref(p) == 1);
ffffffffc0203ece:	00003697          	auipc	a3,0x3
ffffffffc0203ed2:	be268693          	addi	a3,a3,-1054 # ffffffffc0206ab0 <default_pmm_manager+0x468>
ffffffffc0203ed6:	00002617          	auipc	a2,0x2
ffffffffc0203eda:	9fa60613          	addi	a2,a2,-1542 # ffffffffc02058d0 <commands+0x728>
ffffffffc0203ede:	1a600593          	li	a1,422
ffffffffc0203ee2:	00002517          	auipc	a0,0x2
ffffffffc0203ee6:	79e50513          	addi	a0,a0,1950 # ffffffffc0206680 <default_pmm_manager+0x38>
ffffffffc0203eea:	adefc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(page_insert(boot_pgdir, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0203eee:	00003697          	auipc	a3,0x3
ffffffffc0203ef2:	b8a68693          	addi	a3,a3,-1142 # ffffffffc0206a78 <default_pmm_manager+0x430>
ffffffffc0203ef6:	00002617          	auipc	a2,0x2
ffffffffc0203efa:	9da60613          	addi	a2,a2,-1574 # ffffffffc02058d0 <commands+0x728>
ffffffffc0203efe:	1a500593          	li	a1,421
ffffffffc0203f02:	00002517          	auipc	a0,0x2
ffffffffc0203f06:	77e50513          	addi	a0,a0,1918 # ffffffffc0206680 <default_pmm_manager+0x38>
ffffffffc0203f0a:	abefc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(boot_pgdir[0] == 0);
ffffffffc0203f0e:	00003697          	auipc	a3,0x3
ffffffffc0203f12:	b5268693          	addi	a3,a3,-1198 # ffffffffc0206a60 <default_pmm_manager+0x418>
ffffffffc0203f16:	00002617          	auipc	a2,0x2
ffffffffc0203f1a:	9ba60613          	addi	a2,a2,-1606 # ffffffffc02058d0 <commands+0x728>
ffffffffc0203f1e:	1a100593          	li	a1,417
ffffffffc0203f22:	00002517          	auipc	a0,0x2
ffffffffc0203f26:	75e50513          	addi	a0,a0,1886 # ffffffffc0206680 <default_pmm_manager+0x38>
ffffffffc0203f2a:	a9efc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(nr_free_store==nr_free_pages());
ffffffffc0203f2e:	00003697          	auipc	a3,0x3
ffffffffc0203f32:	a9a68693          	addi	a3,a3,-1382 # ffffffffc02069c8 <default_pmm_manager+0x380>
ffffffffc0203f36:	00002617          	auipc	a2,0x2
ffffffffc0203f3a:	99a60613          	addi	a2,a2,-1638 # ffffffffc02058d0 <commands+0x728>
ffffffffc0203f3e:	19000593          	li	a1,400
ffffffffc0203f42:	00002517          	auipc	a0,0x2
ffffffffc0203f46:	73e50513          	addi	a0,a0,1854 # ffffffffc0206680 <default_pmm_manager+0x38>
ffffffffc0203f4a:	a7efc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0203f4e:	00003697          	auipc	a3,0x3
ffffffffc0203f52:	8b268693          	addi	a3,a3,-1870 # ffffffffc0206800 <default_pmm_manager+0x1b8>
ffffffffc0203f56:	00002617          	auipc	a2,0x2
ffffffffc0203f5a:	97a60613          	addi	a2,a2,-1670 # ffffffffc02058d0 <commands+0x728>
ffffffffc0203f5e:	16a00593          	li	a1,362
ffffffffc0203f62:	00002517          	auipc	a0,0x2
ffffffffc0203f66:	71e50513          	addi	a0,a0,1822 # ffffffffc0206680 <default_pmm_manager+0x38>
ffffffffc0203f6a:	a5efc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir[0]));
ffffffffc0203f6e:	00002617          	auipc	a2,0x2
ffffffffc0203f72:	bba60613          	addi	a2,a2,-1094 # ffffffffc0205b28 <commands+0x980>
ffffffffc0203f76:	16d00593          	li	a1,365
ffffffffc0203f7a:	00002517          	auipc	a0,0x2
ffffffffc0203f7e:	70650513          	addi	a0,a0,1798 # ffffffffc0206680 <default_pmm_manager+0x38>
ffffffffc0203f82:	a46fc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0203f86:	00003697          	auipc	a3,0x3
ffffffffc0203f8a:	89268693          	addi	a3,a3,-1902 # ffffffffc0206818 <default_pmm_manager+0x1d0>
ffffffffc0203f8e:	00002617          	auipc	a2,0x2
ffffffffc0203f92:	94260613          	addi	a2,a2,-1726 # ffffffffc02058d0 <commands+0x728>
ffffffffc0203f96:	16b00593          	li	a1,363
ffffffffc0203f9a:	00002517          	auipc	a0,0x2
ffffffffc0203f9e:	6e650513          	addi	a0,a0,1766 # ffffffffc0206680 <default_pmm_manager+0x38>
ffffffffc0203fa2:	a26fc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc0203fa6:	00003697          	auipc	a3,0x3
ffffffffc0203faa:	8ea68693          	addi	a3,a3,-1814 # ffffffffc0206890 <default_pmm_manager+0x248>
ffffffffc0203fae:	00002617          	auipc	a2,0x2
ffffffffc0203fb2:	92260613          	addi	a2,a2,-1758 # ffffffffc02058d0 <commands+0x728>
ffffffffc0203fb6:	17300593          	li	a1,371
ffffffffc0203fba:	00002517          	auipc	a0,0x2
ffffffffc0203fbe:	6c650513          	addi	a0,a0,1734 # ffffffffc0206680 <default_pmm_manager+0x38>
ffffffffc0203fc2:	a06fc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc0203fc6:	00003697          	auipc	a3,0x3
ffffffffc0203fca:	baa68693          	addi	a3,a3,-1110 # ffffffffc0206b70 <default_pmm_manager+0x528>
ffffffffc0203fce:	00002617          	auipc	a2,0x2
ffffffffc0203fd2:	90260613          	addi	a2,a2,-1790 # ffffffffc02058d0 <commands+0x728>
ffffffffc0203fd6:	1af00593          	li	a1,431
ffffffffc0203fda:	00002517          	auipc	a0,0x2
ffffffffc0203fde:	6a650513          	addi	a0,a0,1702 # ffffffffc0206680 <default_pmm_manager+0x38>
ffffffffc0203fe2:	9e6fc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0203fe6:	00003697          	auipc	a3,0x3
ffffffffc0203fea:	b5268693          	addi	a3,a3,-1198 # ffffffffc0206b38 <default_pmm_manager+0x4f0>
ffffffffc0203fee:	00002617          	auipc	a2,0x2
ffffffffc0203ff2:	8e260613          	addi	a2,a2,-1822 # ffffffffc02058d0 <commands+0x728>
ffffffffc0203ff6:	1ac00593          	li	a1,428
ffffffffc0203ffa:	00002517          	auipc	a0,0x2
ffffffffc0203ffe:	68650513          	addi	a0,a0,1670 # ffffffffc0206680 <default_pmm_manager+0x38>
ffffffffc0204002:	9c6fc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(page_ref(p) == 2);
ffffffffc0204006:	00003697          	auipc	a3,0x3
ffffffffc020400a:	b0268693          	addi	a3,a3,-1278 # ffffffffc0206b08 <default_pmm_manager+0x4c0>
ffffffffc020400e:	00002617          	auipc	a2,0x2
ffffffffc0204012:	8c260613          	addi	a2,a2,-1854 # ffffffffc02058d0 <commands+0x728>
ffffffffc0204016:	1a800593          	li	a1,424
ffffffffc020401a:	00002517          	auipc	a0,0x2
ffffffffc020401e:	66650513          	addi	a0,a0,1638 # ffffffffc0206680 <default_pmm_manager+0x38>
ffffffffc0204022:	9a6fc0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc0204026 <tlb_invalidate>:
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0204026:	12058073          	sfence.vma	a1
}
ffffffffc020402a:	8082                	ret

ffffffffc020402c <pgdir_alloc_page>:
struct Page *pgdir_alloc_page(pde_t *pgdir, uintptr_t la, uint32_t perm) {
ffffffffc020402c:	7179                	addi	sp,sp,-48
ffffffffc020402e:	e84a                	sd	s2,16(sp)
ffffffffc0204030:	892a                	mv	s2,a0
    struct Page *page = alloc_page();
ffffffffc0204032:	4505                	li	a0,1
struct Page *pgdir_alloc_page(pde_t *pgdir, uintptr_t la, uint32_t perm) {
ffffffffc0204034:	f022                	sd	s0,32(sp)
ffffffffc0204036:	ec26                	sd	s1,24(sp)
ffffffffc0204038:	e44e                	sd	s3,8(sp)
ffffffffc020403a:	f406                	sd	ra,40(sp)
ffffffffc020403c:	84ae                	mv	s1,a1
ffffffffc020403e:	89b2                	mv	s3,a2
    struct Page *page = alloc_page();
ffffffffc0204040:	f89fe0ef          	jal	ra,ffffffffc0202fc8 <alloc_pages>
ffffffffc0204044:	842a                	mv	s0,a0
    if (page != NULL) {
ffffffffc0204046:	cd09                	beqz	a0,ffffffffc0204060 <pgdir_alloc_page+0x34>
        if (page_insert(pgdir, page, la, perm) != 0) {
ffffffffc0204048:	85aa                	mv	a1,a0
ffffffffc020404a:	86ce                	mv	a3,s3
ffffffffc020404c:	8626                	mv	a2,s1
ffffffffc020404e:	854a                	mv	a0,s2
ffffffffc0204050:	b46ff0ef          	jal	ra,ffffffffc0203396 <page_insert>
ffffffffc0204054:	ed21                	bnez	a0,ffffffffc02040ac <pgdir_alloc_page+0x80>
        if (swap_init_ok) {
ffffffffc0204056:	00012797          	auipc	a5,0x12
ffffffffc020405a:	5227a783          	lw	a5,1314(a5) # ffffffffc0216578 <swap_init_ok>
ffffffffc020405e:	eb89                	bnez	a5,ffffffffc0204070 <pgdir_alloc_page+0x44>
}
ffffffffc0204060:	70a2                	ld	ra,40(sp)
ffffffffc0204062:	8522                	mv	a0,s0
ffffffffc0204064:	7402                	ld	s0,32(sp)
ffffffffc0204066:	64e2                	ld	s1,24(sp)
ffffffffc0204068:	6942                	ld	s2,16(sp)
ffffffffc020406a:	69a2                	ld	s3,8(sp)
ffffffffc020406c:	6145                	addi	sp,sp,48
ffffffffc020406e:	8082                	ret
            swap_map_swappable(check_mm_struct, la, page, 0);
ffffffffc0204070:	4681                	li	a3,0
ffffffffc0204072:	8622                	mv	a2,s0
ffffffffc0204074:	85a6                	mv	a1,s1
ffffffffc0204076:	00012517          	auipc	a0,0x12
ffffffffc020407a:	4da53503          	ld	a0,1242(a0) # ffffffffc0216550 <check_mm_struct>
ffffffffc020407e:	acafe0ef          	jal	ra,ffffffffc0202348 <swap_map_swappable>
            assert(page_ref(page) == 1);
ffffffffc0204082:	4018                	lw	a4,0(s0)
            page->pra_vaddr = la;
ffffffffc0204084:	fc04                	sd	s1,56(s0)
            assert(page_ref(page) == 1);
ffffffffc0204086:	4785                	li	a5,1
ffffffffc0204088:	fcf70ce3          	beq	a4,a5,ffffffffc0204060 <pgdir_alloc_page+0x34>
ffffffffc020408c:	00003697          	auipc	a3,0x3
ffffffffc0204090:	b2c68693          	addi	a3,a3,-1236 # ffffffffc0206bb8 <default_pmm_manager+0x570>
ffffffffc0204094:	00002617          	auipc	a2,0x2
ffffffffc0204098:	83c60613          	addi	a2,a2,-1988 # ffffffffc02058d0 <commands+0x728>
ffffffffc020409c:	14800593          	li	a1,328
ffffffffc02040a0:	00002517          	auipc	a0,0x2
ffffffffc02040a4:	5e050513          	addi	a0,a0,1504 # ffffffffc0206680 <default_pmm_manager+0x38>
ffffffffc02040a8:	920fc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02040ac:	100027f3          	csrr	a5,sstatus
ffffffffc02040b0:	8b89                	andi	a5,a5,2
ffffffffc02040b2:	eb99                	bnez	a5,ffffffffc02040c8 <pgdir_alloc_page+0x9c>
        pmm_manager->free_pages(base, n);
ffffffffc02040b4:	00012797          	auipc	a5,0x12
ffffffffc02040b8:	4ec7b783          	ld	a5,1260(a5) # ffffffffc02165a0 <pmm_manager>
ffffffffc02040bc:	739c                	ld	a5,32(a5)
ffffffffc02040be:	8522                	mv	a0,s0
ffffffffc02040c0:	4585                	li	a1,1
ffffffffc02040c2:	9782                	jalr	a5
            return NULL;
ffffffffc02040c4:	4401                	li	s0,0
ffffffffc02040c6:	bf69                	j	ffffffffc0204060 <pgdir_alloc_page+0x34>
        intr_disable();
ffffffffc02040c8:	cfcfc0ef          	jal	ra,ffffffffc02005c4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02040cc:	00012797          	auipc	a5,0x12
ffffffffc02040d0:	4d47b783          	ld	a5,1236(a5) # ffffffffc02165a0 <pmm_manager>
ffffffffc02040d4:	739c                	ld	a5,32(a5)
ffffffffc02040d6:	8522                	mv	a0,s0
ffffffffc02040d8:	4585                	li	a1,1
ffffffffc02040da:	9782                	jalr	a5
            return NULL;
ffffffffc02040dc:	4401                	li	s0,0
        intr_enable();
ffffffffc02040de:	ce0fc0ef          	jal	ra,ffffffffc02005be <intr_enable>
ffffffffc02040e2:	bfbd                	j	ffffffffc0204060 <pgdir_alloc_page+0x34>

ffffffffc02040e4 <swapfs_init>:
#include <ide.h>
#include <pmm.h>
#include <assert.h>

void
swapfs_init(void) {
ffffffffc02040e4:	1141                	addi	sp,sp,-16
    static_assert((PGSIZE % SECTSIZE) == 0);
    if (!ide_device_valid(SWAP_DEV_NO)) {
ffffffffc02040e6:	4505                	li	a0,1
swapfs_init(void) {
ffffffffc02040e8:	e406                	sd	ra,8(sp)
    if (!ide_device_valid(SWAP_DEV_NO)) {
ffffffffc02040ea:	bbafc0ef          	jal	ra,ffffffffc02004a4 <ide_device_valid>
ffffffffc02040ee:	cd01                	beqz	a0,ffffffffc0204106 <swapfs_init+0x22>
        panic("swap fs isn't available.\n");
    }
    max_swap_offset = ide_device_size(SWAP_DEV_NO) / (PGSIZE / SECTSIZE);
ffffffffc02040f0:	4505                	li	a0,1
ffffffffc02040f2:	bb8fc0ef          	jal	ra,ffffffffc02004aa <ide_device_size>
}
ffffffffc02040f6:	60a2                	ld	ra,8(sp)
    max_swap_offset = ide_device_size(SWAP_DEV_NO) / (PGSIZE / SECTSIZE);
ffffffffc02040f8:	810d                	srli	a0,a0,0x3
ffffffffc02040fa:	00012797          	auipc	a5,0x12
ffffffffc02040fe:	46a7b723          	sd	a0,1134(a5) # ffffffffc0216568 <max_swap_offset>
}
ffffffffc0204102:	0141                	addi	sp,sp,16
ffffffffc0204104:	8082                	ret
        panic("swap fs isn't available.\n");
ffffffffc0204106:	00003617          	auipc	a2,0x3
ffffffffc020410a:	aca60613          	addi	a2,a2,-1334 # ffffffffc0206bd0 <default_pmm_manager+0x588>
ffffffffc020410e:	45b5                	li	a1,13
ffffffffc0204110:	00003517          	auipc	a0,0x3
ffffffffc0204114:	ae050513          	addi	a0,a0,-1312 # ffffffffc0206bf0 <default_pmm_manager+0x5a8>
ffffffffc0204118:	8b0fc0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc020411c <swapfs_read>:

int
swapfs_read(swap_entry_t entry, struct Page *page) {
ffffffffc020411c:	1141                	addi	sp,sp,-16
ffffffffc020411e:	e406                	sd	ra,8(sp)
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204120:	00855793          	srli	a5,a0,0x8
ffffffffc0204124:	cbb1                	beqz	a5,ffffffffc0204178 <swapfs_read+0x5c>
ffffffffc0204126:	00012717          	auipc	a4,0x12
ffffffffc020412a:	44273703          	ld	a4,1090(a4) # ffffffffc0216568 <max_swap_offset>
ffffffffc020412e:	04e7f563          	bgeu	a5,a4,ffffffffc0204178 <swapfs_read+0x5c>
    return page - pages + nbase;
ffffffffc0204132:	00012617          	auipc	a2,0x12
ffffffffc0204136:	46663603          	ld	a2,1126(a2) # ffffffffc0216598 <pages>
ffffffffc020413a:	8d91                	sub	a1,a1,a2
ffffffffc020413c:	4065d613          	srai	a2,a1,0x6
ffffffffc0204140:	00003717          	auipc	a4,0x3
ffffffffc0204144:	ee073703          	ld	a4,-288(a4) # ffffffffc0207020 <nbase>
ffffffffc0204148:	963a                	add	a2,a2,a4
    return KADDR(page2pa(page));
ffffffffc020414a:	00c61713          	slli	a4,a2,0xc
ffffffffc020414e:	8331                	srli	a4,a4,0xc
ffffffffc0204150:	00012697          	auipc	a3,0x12
ffffffffc0204154:	4406b683          	ld	a3,1088(a3) # ffffffffc0216590 <npage>
ffffffffc0204158:	0037959b          	slliw	a1,a5,0x3
    return page2ppn(page) << PGSHIFT;
ffffffffc020415c:	0632                	slli	a2,a2,0xc
    return KADDR(page2pa(page));
ffffffffc020415e:	02d77963          	bgeu	a4,a3,ffffffffc0204190 <swapfs_read+0x74>
}
ffffffffc0204162:	60a2                	ld	ra,8(sp)
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204164:	00012797          	auipc	a5,0x12
ffffffffc0204168:	4447b783          	ld	a5,1092(a5) # ffffffffc02165a8 <va_pa_offset>
ffffffffc020416c:	46a1                	li	a3,8
ffffffffc020416e:	963e                	add	a2,a2,a5
ffffffffc0204170:	4505                	li	a0,1
}
ffffffffc0204172:	0141                	addi	sp,sp,16
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204174:	b3cfc06f          	j	ffffffffc02004b0 <ide_read_secs>
ffffffffc0204178:	86aa                	mv	a3,a0
ffffffffc020417a:	00003617          	auipc	a2,0x3
ffffffffc020417e:	a8e60613          	addi	a2,a2,-1394 # ffffffffc0206c08 <default_pmm_manager+0x5c0>
ffffffffc0204182:	45d1                	li	a1,20
ffffffffc0204184:	00003517          	auipc	a0,0x3
ffffffffc0204188:	a6c50513          	addi	a0,a0,-1428 # ffffffffc0206bf0 <default_pmm_manager+0x5a8>
ffffffffc020418c:	83cfc0ef          	jal	ra,ffffffffc02001c8 <__panic>
ffffffffc0204190:	86b2                	mv	a3,a2
ffffffffc0204192:	06900593          	li	a1,105
ffffffffc0204196:	00002617          	auipc	a2,0x2
ffffffffc020419a:	99260613          	addi	a2,a2,-1646 # ffffffffc0205b28 <commands+0x980>
ffffffffc020419e:	00002517          	auipc	a0,0x2
ffffffffc02041a2:	97a50513          	addi	a0,a0,-1670 # ffffffffc0205b18 <commands+0x970>
ffffffffc02041a6:	822fc0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc02041aa <swapfs_write>:

int
swapfs_write(swap_entry_t entry, struct Page *page) {
ffffffffc02041aa:	1141                	addi	sp,sp,-16
ffffffffc02041ac:	e406                	sd	ra,8(sp)
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc02041ae:	00855793          	srli	a5,a0,0x8
ffffffffc02041b2:	cbb1                	beqz	a5,ffffffffc0204206 <swapfs_write+0x5c>
ffffffffc02041b4:	00012717          	auipc	a4,0x12
ffffffffc02041b8:	3b473703          	ld	a4,948(a4) # ffffffffc0216568 <max_swap_offset>
ffffffffc02041bc:	04e7f563          	bgeu	a5,a4,ffffffffc0204206 <swapfs_write+0x5c>
    return page - pages + nbase;
ffffffffc02041c0:	00012617          	auipc	a2,0x12
ffffffffc02041c4:	3d863603          	ld	a2,984(a2) # ffffffffc0216598 <pages>
ffffffffc02041c8:	8d91                	sub	a1,a1,a2
ffffffffc02041ca:	4065d613          	srai	a2,a1,0x6
ffffffffc02041ce:	00003717          	auipc	a4,0x3
ffffffffc02041d2:	e5273703          	ld	a4,-430(a4) # ffffffffc0207020 <nbase>
ffffffffc02041d6:	963a                	add	a2,a2,a4
    return KADDR(page2pa(page));
ffffffffc02041d8:	00c61713          	slli	a4,a2,0xc
ffffffffc02041dc:	8331                	srli	a4,a4,0xc
ffffffffc02041de:	00012697          	auipc	a3,0x12
ffffffffc02041e2:	3b26b683          	ld	a3,946(a3) # ffffffffc0216590 <npage>
ffffffffc02041e6:	0037959b          	slliw	a1,a5,0x3
    return page2ppn(page) << PGSHIFT;
ffffffffc02041ea:	0632                	slli	a2,a2,0xc
    return KADDR(page2pa(page));
ffffffffc02041ec:	02d77963          	bgeu	a4,a3,ffffffffc020421e <swapfs_write+0x74>
}
ffffffffc02041f0:	60a2                	ld	ra,8(sp)
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc02041f2:	00012797          	auipc	a5,0x12
ffffffffc02041f6:	3b67b783          	ld	a5,950(a5) # ffffffffc02165a8 <va_pa_offset>
ffffffffc02041fa:	46a1                	li	a3,8
ffffffffc02041fc:	963e                	add	a2,a2,a5
ffffffffc02041fe:	4505                	li	a0,1
}
ffffffffc0204200:	0141                	addi	sp,sp,16
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204202:	ad2fc06f          	j	ffffffffc02004d4 <ide_write_secs>
ffffffffc0204206:	86aa                	mv	a3,a0
ffffffffc0204208:	00003617          	auipc	a2,0x3
ffffffffc020420c:	a0060613          	addi	a2,a2,-1536 # ffffffffc0206c08 <default_pmm_manager+0x5c0>
ffffffffc0204210:	45e5                	li	a1,25
ffffffffc0204212:	00003517          	auipc	a0,0x3
ffffffffc0204216:	9de50513          	addi	a0,a0,-1570 # ffffffffc0206bf0 <default_pmm_manager+0x5a8>
ffffffffc020421a:	faffb0ef          	jal	ra,ffffffffc02001c8 <__panic>
ffffffffc020421e:	86b2                	mv	a3,a2
ffffffffc0204220:	06900593          	li	a1,105
ffffffffc0204224:	00002617          	auipc	a2,0x2
ffffffffc0204228:	90460613          	addi	a2,a2,-1788 # ffffffffc0205b28 <commands+0x980>
ffffffffc020422c:	00002517          	auipc	a0,0x2
ffffffffc0204230:	8ec50513          	addi	a0,a0,-1812 # ffffffffc0205b18 <commands+0x970>
ffffffffc0204234:	f95fb0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc0204238 <kernel_thread_entry>:
.text
.globl kernel_thread_entry
kernel_thread_entry:        # void kernel_thread(void)
	move a0, s1
ffffffffc0204238:	8526                	mv	a0,s1
	jalr s0
ffffffffc020423a:	9402                	jalr	s0

	jal do_exit
ffffffffc020423c:	4c8000ef          	jal	ra,ffffffffc0204704 <do_exit>

ffffffffc0204240 <switch_to>:
.text
# void switch_to(struct proc_struct* from, struct proc_struct* to)
.globl switch_to
switch_to:
    # save from's registers
    STORE ra, 0*REGBYTES(a0)
ffffffffc0204240:	00153023          	sd	ra,0(a0)
    STORE sp, 1*REGBYTES(a0)
ffffffffc0204244:	00253423          	sd	sp,8(a0)
    STORE s0, 2*REGBYTES(a0)
ffffffffc0204248:	e900                	sd	s0,16(a0)
    STORE s1, 3*REGBYTES(a0)
ffffffffc020424a:	ed04                	sd	s1,24(a0)
    STORE s2, 4*REGBYTES(a0)
ffffffffc020424c:	03253023          	sd	s2,32(a0)
    STORE s3, 5*REGBYTES(a0)
ffffffffc0204250:	03353423          	sd	s3,40(a0)
    STORE s4, 6*REGBYTES(a0)
ffffffffc0204254:	03453823          	sd	s4,48(a0)
    STORE s5, 7*REGBYTES(a0)
ffffffffc0204258:	03553c23          	sd	s5,56(a0)
    STORE s6, 8*REGBYTES(a0)
ffffffffc020425c:	05653023          	sd	s6,64(a0)
    STORE s7, 9*REGBYTES(a0)
ffffffffc0204260:	05753423          	sd	s7,72(a0)
    STORE s8, 10*REGBYTES(a0)
ffffffffc0204264:	05853823          	sd	s8,80(a0)
    STORE s9, 11*REGBYTES(a0)
ffffffffc0204268:	05953c23          	sd	s9,88(a0)
    STORE s10, 12*REGBYTES(a0)
ffffffffc020426c:	07a53023          	sd	s10,96(a0)
    STORE s11, 13*REGBYTES(a0)
ffffffffc0204270:	07b53423          	sd	s11,104(a0)

    # restore to's registers
    LOAD ra, 0*REGBYTES(a1)
ffffffffc0204274:	0005b083          	ld	ra,0(a1)
    LOAD sp, 1*REGBYTES(a1)
ffffffffc0204278:	0085b103          	ld	sp,8(a1)
    LOAD s0, 2*REGBYTES(a1)
ffffffffc020427c:	6980                	ld	s0,16(a1)
    LOAD s1, 3*REGBYTES(a1)
ffffffffc020427e:	6d84                	ld	s1,24(a1)
    LOAD s2, 4*REGBYTES(a1)
ffffffffc0204280:	0205b903          	ld	s2,32(a1)
    LOAD s3, 5*REGBYTES(a1)
ffffffffc0204284:	0285b983          	ld	s3,40(a1)
    LOAD s4, 6*REGBYTES(a1)
ffffffffc0204288:	0305ba03          	ld	s4,48(a1)
    LOAD s5, 7*REGBYTES(a1)
ffffffffc020428c:	0385ba83          	ld	s5,56(a1)
    LOAD s6, 8*REGBYTES(a1)
ffffffffc0204290:	0405bb03          	ld	s6,64(a1)
    LOAD s7, 9*REGBYTES(a1)
ffffffffc0204294:	0485bb83          	ld	s7,72(a1)
    LOAD s8, 10*REGBYTES(a1)
ffffffffc0204298:	0505bc03          	ld	s8,80(a1)
    LOAD s9, 11*REGBYTES(a1)
ffffffffc020429c:	0585bc83          	ld	s9,88(a1)
    LOAD s10, 12*REGBYTES(a1)
ffffffffc02042a0:	0605bd03          	ld	s10,96(a1)
    LOAD s11, 13*REGBYTES(a1)
ffffffffc02042a4:	0685bd83          	ld	s11,104(a1)

    ret
ffffffffc02042a8:	8082                	ret

ffffffffc02042aa <alloc_proc>:
void forkrets(struct trapframe *tf);
void switch_to(struct context *from, struct context *to);

// alloc_proc - alloc a proc_struct and init all fields of proc_struct
static struct proc_struct *
alloc_proc(void) {
ffffffffc02042aa:	1141                	addi	sp,sp,-16
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc02042ac:	0e800513          	li	a0,232
alloc_proc(void) {
ffffffffc02042b0:	e022                	sd	s0,0(sp)
ffffffffc02042b2:	e406                	sd	ra,8(sp)
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc02042b4:	f8cfd0ef          	jal	ra,ffffffffc0201a40 <kmalloc>
ffffffffc02042b8:	842a                	mv	s0,a0
    if (proc != NULL) {
ffffffffc02042ba:	c521                	beqz	a0,ffffffffc0204302 <alloc_proc+0x58>
    //LAB4:EXERCISE1 YOUR CODE 2212824 2211581 2212481
    
     //* below fields in proc_struct need to be initialized
            proc->state=PROC_UNINIT;                      // Process state进程的状态
ffffffffc02042bc:	57fd                	li	a5,-1
ffffffffc02042be:	1782                	slli	a5,a5,0x20
ffffffffc02042c0:	e11c                	sd	a5,0(a0)
            proc->runs = 0;                                 // the running times of Proces进程运行的次数
           proc->kstack = 0;                           // Process kernel stack进程的内核栈
            proc->need_resched = 0;                // 进程是否需要被调度bool value: need to be rescheduled to release CPU?
            proc->parent = NULL;                // 父进程the parent process
             proc->mm = NULL;                      // 进程的内存管理Process's memory management field
            memset(&(proc->context), 0, sizeof(struct context));                    // 进程的上下文Switch here to run process
ffffffffc02042c2:	07000613          	li	a2,112
ffffffffc02042c6:	4581                	li	a1,0
            proc->runs = 0;                                 // the running times of Proces进程运行的次数
ffffffffc02042c8:	00052423          	sw	zero,8(a0)
           proc->kstack = 0;                           // Process kernel stack进程的内核栈
ffffffffc02042cc:	00053823          	sd	zero,16(a0)
            proc->need_resched = 0;                // 进程是否需要被调度bool value: need to be rescheduled to release CPU?
ffffffffc02042d0:	00052c23          	sw	zero,24(a0)
            proc->parent = NULL;                // 父进程the parent process
ffffffffc02042d4:	02053023          	sd	zero,32(a0)
             proc->mm = NULL;                      // 进程的内存管理Process's memory management field
ffffffffc02042d8:	02053423          	sd	zero,40(a0)
            memset(&(proc->context), 0, sizeof(struct context));                    // 进程的上下文Switch here to run process
ffffffffc02042dc:	03050513          	addi	a0,a0,48
ffffffffc02042e0:	7ec000ef          	jal	ra,ffffffffc0204acc <memset>
            proc->tf = NULL;                      // 进程的trapframeTrap frame for current interrupt
            proc->cr3 = boot_cr3;                             // 进程的CR3寄存器CR3 register: the base addr of Page Directroy Table(PDT)
ffffffffc02042e4:	00012797          	auipc	a5,0x12
ffffffffc02042e8:	29c7b783          	ld	a5,668(a5) # ffffffffc0216580 <boot_cr3>
            proc->tf = NULL;                      // 进程的trapframeTrap frame for current interrupt
ffffffffc02042ec:	0a043023          	sd	zero,160(s0)
            proc->cr3 = boot_cr3;                             // 进程的CR3寄存器CR3 register: the base addr of Page Directroy Table(PDT)
ffffffffc02042f0:	f45c                	sd	a5,168(s0)
            proc->flags = 0;                            // 进程的标志Process flag
ffffffffc02042f2:	0a042823          	sw	zero,176(s0)
             memset(proc->name, 0, PROC_NAME_LEN);              // 进程的名称Process name
ffffffffc02042f6:	463d                	li	a2,15
ffffffffc02042f8:	4581                	li	a1,0
ffffffffc02042fa:	0b440513          	addi	a0,s0,180
ffffffffc02042fe:	7ce000ef          	jal	ra,ffffffffc0204acc <memset>
     


    }
    return proc;
}
ffffffffc0204302:	60a2                	ld	ra,8(sp)
ffffffffc0204304:	8522                	mv	a0,s0
ffffffffc0204306:	6402                	ld	s0,0(sp)
ffffffffc0204308:	0141                	addi	sp,sp,16
ffffffffc020430a:	8082                	ret

ffffffffc020430c <forkret>:
// forkret -- the first kernel entry point of a new thread/process
// NOTE: the addr of forkret is setted in copy_thread function
//       after switch_to, the current proc will execute here.
static void
forkret(void) {
    forkrets(current->tf);
ffffffffc020430c:	00012797          	auipc	a5,0x12
ffffffffc0204310:	2a47b783          	ld	a5,676(a5) # ffffffffc02165b0 <current>
ffffffffc0204314:	73c8                	ld	a0,160(a5)
ffffffffc0204316:	857fc06f          	j	ffffffffc0200b6c <forkrets>

ffffffffc020431a <init_main>:
    panic("process exit!!.\n");
}

// init_main - the second kernel thread used to create user_main kernel threads
static int
init_main(void *arg) {
ffffffffc020431a:	7179                	addi	sp,sp,-48
ffffffffc020431c:	ec26                	sd	s1,24(sp)
    memset(name, 0, sizeof(name));
ffffffffc020431e:	00012497          	auipc	s1,0x12
ffffffffc0204322:	1fa48493          	addi	s1,s1,506 # ffffffffc0216518 <name.2>
init_main(void *arg) {
ffffffffc0204326:	f022                	sd	s0,32(sp)
ffffffffc0204328:	e84a                	sd	s2,16(sp)
ffffffffc020432a:	842a                	mv	s0,a0
    cprintf("this initproc, pid = %d, name = \"%s\"\n", current->pid, get_proc_name(current));
ffffffffc020432c:	00012917          	auipc	s2,0x12
ffffffffc0204330:	28493903          	ld	s2,644(s2) # ffffffffc02165b0 <current>
    memset(name, 0, sizeof(name));
ffffffffc0204334:	4641                	li	a2,16
ffffffffc0204336:	4581                	li	a1,0
ffffffffc0204338:	8526                	mv	a0,s1
init_main(void *arg) {
ffffffffc020433a:	f406                	sd	ra,40(sp)
ffffffffc020433c:	e44e                	sd	s3,8(sp)
    cprintf("this initproc, pid = %d, name = \"%s\"\n", current->pid, get_proc_name(current));
ffffffffc020433e:	00492983          	lw	s3,4(s2)
    memset(name, 0, sizeof(name));
ffffffffc0204342:	78a000ef          	jal	ra,ffffffffc0204acc <memset>
    return memcpy(name, proc->name, PROC_NAME_LEN);
ffffffffc0204346:	0b490593          	addi	a1,s2,180
ffffffffc020434a:	463d                	li	a2,15
ffffffffc020434c:	8526                	mv	a0,s1
ffffffffc020434e:	790000ef          	jal	ra,ffffffffc0204ade <memcpy>
ffffffffc0204352:	862a                	mv	a2,a0
    cprintf("this initproc, pid = %d, name = \"%s\"\n", current->pid, get_proc_name(current));
ffffffffc0204354:	85ce                	mv	a1,s3
ffffffffc0204356:	00003517          	auipc	a0,0x3
ffffffffc020435a:	8d250513          	addi	a0,a0,-1838 # ffffffffc0206c28 <default_pmm_manager+0x5e0>
ffffffffc020435e:	d6ffb0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("To U: \"%s\".\n", (const char *)arg);
ffffffffc0204362:	85a2                	mv	a1,s0
ffffffffc0204364:	00003517          	auipc	a0,0x3
ffffffffc0204368:	8ec50513          	addi	a0,a0,-1812 # ffffffffc0206c50 <default_pmm_manager+0x608>
ffffffffc020436c:	d61fb0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("To U: \"en.., Bye, Bye. :)\"\n");
ffffffffc0204370:	00003517          	auipc	a0,0x3
ffffffffc0204374:	8f050513          	addi	a0,a0,-1808 # ffffffffc0206c60 <default_pmm_manager+0x618>
ffffffffc0204378:	d55fb0ef          	jal	ra,ffffffffc02000cc <cprintf>
    return 0;
}
ffffffffc020437c:	70a2                	ld	ra,40(sp)
ffffffffc020437e:	7402                	ld	s0,32(sp)
ffffffffc0204380:	64e2                	ld	s1,24(sp)
ffffffffc0204382:	6942                	ld	s2,16(sp)
ffffffffc0204384:	69a2                	ld	s3,8(sp)
ffffffffc0204386:	4501                	li	a0,0
ffffffffc0204388:	6145                	addi	sp,sp,48
ffffffffc020438a:	8082                	ret

ffffffffc020438c <proc_run>:
proc_run(struct proc_struct *proc) {
ffffffffc020438c:	7179                	addi	sp,sp,-48
ffffffffc020438e:	ec4a                	sd	s2,24(sp)
    if (proc != current) {//检查要切换的进程是否与当前正在运行的进程相同，如果相同则不需要切换。
ffffffffc0204390:	00012917          	auipc	s2,0x12
ffffffffc0204394:	22090913          	addi	s2,s2,544 # ffffffffc02165b0 <current>
proc_run(struct proc_struct *proc) {
ffffffffc0204398:	f026                	sd	s1,32(sp)
    if (proc != current) {//检查要切换的进程是否与当前正在运行的进程相同，如果相同则不需要切换。
ffffffffc020439a:	00093483          	ld	s1,0(s2)
proc_run(struct proc_struct *proc) {
ffffffffc020439e:	f406                	sd	ra,40(sp)
ffffffffc02043a0:	e84e                	sd	s3,16(sp)
    if (proc != current) {//检查要切换的进程是否与当前正在运行的进程相同，如果相同则不需要切换。
ffffffffc02043a2:	02a48963          	beq	s1,a0,ffffffffc02043d4 <proc_run+0x48>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02043a6:	100027f3          	csrr	a5,sstatus
ffffffffc02043aa:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02043ac:	4981                	li	s3,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02043ae:	e3a1                	bnez	a5,ffffffffc02043ee <proc_run+0x62>
        lcr3(next->cr3);
ffffffffc02043b0:	755c                	ld	a5,168(a0)

#define barrier() __asm__ __volatile__ ("fence" ::: "memory")

static inline void
lcr3(unsigned int cr3) {
    write_csr(sptbr, SATP32_MODE | (cr3 >> RISCV_PGSHIFT));
ffffffffc02043b2:	80000737          	lui	a4,0x80000
        current = proc;
ffffffffc02043b6:	00a93023          	sd	a0,0(s2)
ffffffffc02043ba:	00c7d79b          	srliw	a5,a5,0xc
ffffffffc02043be:	8fd9                	or	a5,a5,a4
ffffffffc02043c0:	18079073          	csrw	satp,a5
        switch_to(&(prev->context), &(next->context));
ffffffffc02043c4:	03050593          	addi	a1,a0,48
ffffffffc02043c8:	03048513          	addi	a0,s1,48
ffffffffc02043cc:	e75ff0ef          	jal	ra,ffffffffc0204240 <switch_to>
    if (flag) {
ffffffffc02043d0:	00099863          	bnez	s3,ffffffffc02043e0 <proc_run+0x54>
}
ffffffffc02043d4:	70a2                	ld	ra,40(sp)
ffffffffc02043d6:	7482                	ld	s1,32(sp)
ffffffffc02043d8:	6962                	ld	s2,24(sp)
ffffffffc02043da:	69c2                	ld	s3,16(sp)
ffffffffc02043dc:	6145                	addi	sp,sp,48
ffffffffc02043de:	8082                	ret
ffffffffc02043e0:	70a2                	ld	ra,40(sp)
ffffffffc02043e2:	7482                	ld	s1,32(sp)
ffffffffc02043e4:	6962                	ld	s2,24(sp)
ffffffffc02043e6:	69c2                	ld	s3,16(sp)
ffffffffc02043e8:	6145                	addi	sp,sp,48
        intr_enable();
ffffffffc02043ea:	9d4fc06f          	j	ffffffffc02005be <intr_enable>
ffffffffc02043ee:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02043f0:	9d4fc0ef          	jal	ra,ffffffffc02005c4 <intr_disable>
        return 1;
ffffffffc02043f4:	6522                	ld	a0,8(sp)
ffffffffc02043f6:	4985                	li	s3,1
ffffffffc02043f8:	bf65                	j	ffffffffc02043b0 <proc_run+0x24>

ffffffffc02043fa <do_fork>:
do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf) {
ffffffffc02043fa:	7179                	addi	sp,sp,-48
ffffffffc02043fc:	ec26                	sd	s1,24(sp)
    if (nr_process >= MAX_PROCESS) {//检查是否有足够的进程空间
ffffffffc02043fe:	00012497          	auipc	s1,0x12
ffffffffc0204402:	1ca48493          	addi	s1,s1,458 # ffffffffc02165c8 <nr_process>
ffffffffc0204406:	4098                	lw	a4,0(s1)
do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf) {
ffffffffc0204408:	f406                	sd	ra,40(sp)
ffffffffc020440a:	f022                	sd	s0,32(sp)
ffffffffc020440c:	e84a                	sd	s2,16(sp)
ffffffffc020440e:	e44e                	sd	s3,8(sp)
ffffffffc0204410:	e052                	sd	s4,0(sp)
    if (nr_process >= MAX_PROCESS) {//检查是否有足够的进程空间
ffffffffc0204412:	6785                	lui	a5,0x1
ffffffffc0204414:	22f75263          	bge	a4,a5,ffffffffc0204638 <do_fork+0x23e>
ffffffffc0204418:	892e                	mv	s2,a1
ffffffffc020441a:	89b2                	mv	s3,a2
    proc = alloc_proc();
ffffffffc020441c:	e8fff0ef          	jal	ra,ffffffffc02042aa <alloc_proc>
ffffffffc0204420:	842a                	mv	s0,a0
    if (proc == NULL) {
ffffffffc0204422:	1e050163          	beqz	a0,ffffffffc0204604 <do_fork+0x20a>
proc->parent = current;    
ffffffffc0204426:	00012a17          	auipc	s4,0x12
ffffffffc020442a:	18aa0a13          	addi	s4,s4,394 # ffffffffc02165b0 <current>
ffffffffc020442e:	000a3783          	ld	a5,0(s4)
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc0204432:	4509                	li	a0,2
proc->parent = current;    
ffffffffc0204434:	f01c                	sd	a5,32(s0)
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc0204436:	b93fe0ef          	jal	ra,ffffffffc0202fc8 <alloc_pages>
    if (page != NULL) {
ffffffffc020443a:	18050363          	beqz	a0,ffffffffc02045c0 <do_fork+0x1c6>
    return page - pages + nbase;
ffffffffc020443e:	00012697          	auipc	a3,0x12
ffffffffc0204442:	15a6b683          	ld	a3,346(a3) # ffffffffc0216598 <pages>
ffffffffc0204446:	40d506b3          	sub	a3,a0,a3
ffffffffc020444a:	8699                	srai	a3,a3,0x6
ffffffffc020444c:	00003517          	auipc	a0,0x3
ffffffffc0204450:	bd453503          	ld	a0,-1068(a0) # ffffffffc0207020 <nbase>
ffffffffc0204454:	96aa                	add	a3,a3,a0
    return KADDR(page2pa(page));
ffffffffc0204456:	00c69793          	slli	a5,a3,0xc
ffffffffc020445a:	83b1                	srli	a5,a5,0xc
ffffffffc020445c:	00012717          	auipc	a4,0x12
ffffffffc0204460:	13473703          	ld	a4,308(a4) # ffffffffc0216590 <npage>
    return page2ppn(page) << PGSHIFT;
ffffffffc0204464:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204466:	1ee7ff63          	bgeu	a5,a4,ffffffffc0204664 <do_fork+0x26a>
    assert(current->mm == NULL);
ffffffffc020446a:	000a3783          	ld	a5,0(s4)
ffffffffc020446e:	00012717          	auipc	a4,0x12
ffffffffc0204472:	13a73703          	ld	a4,314(a4) # ffffffffc02165a8 <va_pa_offset>
ffffffffc0204476:	96ba                	add	a3,a3,a4
ffffffffc0204478:	779c                	ld	a5,40(a5)
        proc->kstack = (uintptr_t)page2kva(page);
ffffffffc020447a:	e814                	sd	a3,16(s0)
    assert(current->mm == NULL);
ffffffffc020447c:	20079c63          	bnez	a5,ffffffffc0204694 <do_fork+0x29a>
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE - sizeof(struct trapframe));
ffffffffc0204480:	6789                	lui	a5,0x2
ffffffffc0204482:	ee078793          	addi	a5,a5,-288 # 1ee0 <kern_entry-0xffffffffc01fe120>
ffffffffc0204486:	96be                	add	a3,a3,a5
    *(proc->tf) = *tf;
ffffffffc0204488:	864e                	mv	a2,s3
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE - sizeof(struct trapframe));
ffffffffc020448a:	f054                	sd	a3,160(s0)
    *(proc->tf) = *tf;
ffffffffc020448c:	87b6                	mv	a5,a3
ffffffffc020448e:	12098893          	addi	a7,s3,288
ffffffffc0204492:	00063803          	ld	a6,0(a2)
ffffffffc0204496:	6608                	ld	a0,8(a2)
ffffffffc0204498:	6a0c                	ld	a1,16(a2)
ffffffffc020449a:	6e18                	ld	a4,24(a2)
ffffffffc020449c:	0107b023          	sd	a6,0(a5)
ffffffffc02044a0:	e788                	sd	a0,8(a5)
ffffffffc02044a2:	eb8c                	sd	a1,16(a5)
ffffffffc02044a4:	ef98                	sd	a4,24(a5)
ffffffffc02044a6:	02060613          	addi	a2,a2,32
ffffffffc02044aa:	02078793          	addi	a5,a5,32
ffffffffc02044ae:	ff1612e3          	bne	a2,a7,ffffffffc0204492 <do_fork+0x98>
    proc->tf->gpr.a0 = 0;
ffffffffc02044b2:	0406b823          	sd	zero,80(a3)
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc02044b6:	00091363          	bnez	s2,ffffffffc02044bc <do_fork+0xc2>
ffffffffc02044ba:	8936                	mv	s2,a3
ffffffffc02044bc:	0126b823          	sd	s2,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc02044c0:	00000797          	auipc	a5,0x0
ffffffffc02044c4:	e4c78793          	addi	a5,a5,-436 # ffffffffc020430c <forkret>
ffffffffc02044c8:	f81c                	sd	a5,48(s0)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc02044ca:	fc14                	sd	a3,56(s0)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02044cc:	100027f3          	csrr	a5,sstatus
ffffffffc02044d0:	8b89                	andi	a5,a5,2
ffffffffc02044d2:	14079b63          	bnez	a5,ffffffffc0204628 <do_fork+0x22e>
    if (++ last_pid >= MAX_PID) {
ffffffffc02044d6:	00007817          	auipc	a6,0x7
ffffffffc02044da:	b8280813          	addi	a6,a6,-1150 # ffffffffc020b058 <last_pid.1>
ffffffffc02044de:	00082783          	lw	a5,0(a6)
ffffffffc02044e2:	6709                	lui	a4,0x2
ffffffffc02044e4:	0017851b          	addiw	a0,a5,1
ffffffffc02044e8:	00a82023          	sw	a0,0(a6)
ffffffffc02044ec:	12e55563          	bge	a0,a4,ffffffffc0204616 <do_fork+0x21c>
    if (last_pid >= next_safe) {
ffffffffc02044f0:	00007317          	auipc	t1,0x7
ffffffffc02044f4:	b6c30313          	addi	t1,t1,-1172 # ffffffffc020b05c <next_safe.0>
ffffffffc02044f8:	00032783          	lw	a5,0(t1)
ffffffffc02044fc:	00012917          	auipc	s2,0x12
ffffffffc0204500:	02c90913          	addi	s2,s2,44 # ffffffffc0216528 <proc_list>
ffffffffc0204504:	06f54063          	blt	a0,a5,ffffffffc0204564 <do_fork+0x16a>
    return listelm->next;
ffffffffc0204508:	00012917          	auipc	s2,0x12
ffffffffc020450c:	02090913          	addi	s2,s2,32 # ffffffffc0216528 <proc_list>
ffffffffc0204510:	00893e03          	ld	t3,8(s2)
        next_safe = MAX_PID;
ffffffffc0204514:	6789                	lui	a5,0x2
ffffffffc0204516:	00f32023          	sw	a5,0(t1)
ffffffffc020451a:	86aa                	mv	a3,a0
ffffffffc020451c:	4581                	li	a1,0
        while ((le = list_next(le)) != list) {
ffffffffc020451e:	6e89                	lui	t4,0x2
ffffffffc0204520:	112e0e63          	beq	t3,s2,ffffffffc020463c <do_fork+0x242>
ffffffffc0204524:	88ae                	mv	a7,a1
ffffffffc0204526:	87f2                	mv	a5,t3
ffffffffc0204528:	6609                	lui	a2,0x2
ffffffffc020452a:	a811                	j	ffffffffc020453e <do_fork+0x144>
            else if (proc->pid > last_pid && next_safe > proc->pid) {
ffffffffc020452c:	00e6d663          	bge	a3,a4,ffffffffc0204538 <do_fork+0x13e>
ffffffffc0204530:	00c75463          	bge	a4,a2,ffffffffc0204538 <do_fork+0x13e>
ffffffffc0204534:	863a                	mv	a2,a4
ffffffffc0204536:	4885                	li	a7,1
ffffffffc0204538:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list) {
ffffffffc020453a:	01278d63          	beq	a5,s2,ffffffffc0204554 <do_fork+0x15a>
            if (proc->pid == last_pid) {
ffffffffc020453e:	f3c7a703          	lw	a4,-196(a5) # 1f3c <kern_entry-0xffffffffc01fe0c4>
ffffffffc0204542:	fed715e3          	bne	a4,a3,ffffffffc020452c <do_fork+0x132>
                if (++ last_pid >= next_safe) {
ffffffffc0204546:	2685                	addiw	a3,a3,1
ffffffffc0204548:	0ec6d363          	bge	a3,a2,ffffffffc020462e <do_fork+0x234>
ffffffffc020454c:	679c                	ld	a5,8(a5)
ffffffffc020454e:	4585                	li	a1,1
        while ((le = list_next(le)) != list) {
ffffffffc0204550:	ff2797e3          	bne	a5,s2,ffffffffc020453e <do_fork+0x144>
ffffffffc0204554:	c581                	beqz	a1,ffffffffc020455c <do_fork+0x162>
ffffffffc0204556:	00d82023          	sw	a3,0(a6)
ffffffffc020455a:	8536                	mv	a0,a3
ffffffffc020455c:	00088463          	beqz	a7,ffffffffc0204564 <do_fork+0x16a>
ffffffffc0204560:	00c32023          	sw	a2,0(t1)
        proc->pid = get_pid(); //设置返回码为子进程的id号
ffffffffc0204564:	c048                	sw	a0,4(s0)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc0204566:	45a9                	li	a1,10
ffffffffc0204568:	2501                	sext.w	a0,a0
ffffffffc020456a:	19f000ef          	jal	ra,ffffffffc0204f08 <hash32>
ffffffffc020456e:	02051793          	slli	a5,a0,0x20
ffffffffc0204572:	01c7d513          	srli	a0,a5,0x1c
ffffffffc0204576:	0000e797          	auipc	a5,0xe
ffffffffc020457a:	fa278793          	addi	a5,a5,-94 # ffffffffc0212518 <hash_list>
ffffffffc020457e:	953e                	add	a0,a0,a5
    __list_add(elm, listelm, listelm->next);
ffffffffc0204580:	6518                	ld	a4,8(a0)
ffffffffc0204582:	0d840793          	addi	a5,s0,216
ffffffffc0204586:	00893683          	ld	a3,8(s2)
    prev->next = next->prev = elm;
ffffffffc020458a:	e31c                	sd	a5,0(a4)
ffffffffc020458c:	e51c                	sd	a5,8(a0)
        nr_process ++;
ffffffffc020458e:	409c                	lw	a5,0(s1)
    elm->next = next;
ffffffffc0204590:	f078                	sd	a4,224(s0)
    elm->prev = prev;
ffffffffc0204592:	ec68                	sd	a0,216(s0)
        list_add(&proc_list, &(proc->list_link));
ffffffffc0204594:	0c840713          	addi	a4,s0,200
    prev->next = next->prev = elm;
ffffffffc0204598:	e298                	sd	a4,0(a3)
    elm->prev = prev;
ffffffffc020459a:	0d243423          	sd	s2,200(s0)
    wakeup_proc(proc);
ffffffffc020459e:	8522                	mv	a0,s0
        nr_process ++;
ffffffffc02045a0:	2785                	addiw	a5,a5,1
    elm->next = next;
ffffffffc02045a2:	e874                	sd	a3,208(s0)
    prev->next = next->prev = elm;
ffffffffc02045a4:	00e93423          	sd	a4,8(s2)
ffffffffc02045a8:	c09c                	sw	a5,0(s1)
    wakeup_proc(proc);
ffffffffc02045aa:	3e0000ef          	jal	ra,ffffffffc020498a <wakeup_proc>
ret = proc->pid;
ffffffffc02045ae:	4048                	lw	a0,4(s0)
}
ffffffffc02045b0:	70a2                	ld	ra,40(sp)
ffffffffc02045b2:	7402                	ld	s0,32(sp)
ffffffffc02045b4:	64e2                	ld	s1,24(sp)
ffffffffc02045b6:	6942                	ld	s2,16(sp)
ffffffffc02045b8:	69a2                	ld	s3,8(sp)
ffffffffc02045ba:	6a02                	ld	s4,0(sp)
ffffffffc02045bc:	6145                	addi	sp,sp,48
ffffffffc02045be:	8082                	ret
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc02045c0:	6814                	ld	a3,16(s0)
    return pa2page(PADDR(kva));
ffffffffc02045c2:	c02007b7          	lui	a5,0xc0200
ffffffffc02045c6:	08f6e363          	bltu	a3,a5,ffffffffc020464c <do_fork+0x252>
ffffffffc02045ca:	00012517          	auipc	a0,0x12
ffffffffc02045ce:	fde53503          	ld	a0,-34(a0) # ffffffffc02165a8 <va_pa_offset>
ffffffffc02045d2:	8e89                	sub	a3,a3,a0
    if (PPN(pa) >= npage) {
ffffffffc02045d4:	82b1                	srli	a3,a3,0xc
ffffffffc02045d6:	00012797          	auipc	a5,0x12
ffffffffc02045da:	fba7b783          	ld	a5,-70(a5) # ffffffffc0216590 <npage>
ffffffffc02045de:	08f6ff63          	bgeu	a3,a5,ffffffffc020467c <do_fork+0x282>
    return &pages[PPN(pa) - nbase];
ffffffffc02045e2:	00003517          	auipc	a0,0x3
ffffffffc02045e6:	a3e53503          	ld	a0,-1474(a0) # ffffffffc0207020 <nbase>
ffffffffc02045ea:	8e89                	sub	a3,a3,a0
ffffffffc02045ec:	069a                	slli	a3,a3,0x6
ffffffffc02045ee:	00012517          	auipc	a0,0x12
ffffffffc02045f2:	faa53503          	ld	a0,-86(a0) # ffffffffc0216598 <pages>
ffffffffc02045f6:	9536                	add	a0,a0,a3
ffffffffc02045f8:	4589                	li	a1,2
ffffffffc02045fa:	a61fe0ef          	jal	ra,ffffffffc020305a <free_pages>
    kfree(proc);
ffffffffc02045fe:	8522                	mv	a0,s0
ffffffffc0204600:	cf0fd0ef          	jal	ra,ffffffffc0201af0 <kfree>
    return -E_NO_MEM;
ffffffffc0204604:	5571                	li	a0,-4
}
ffffffffc0204606:	70a2                	ld	ra,40(sp)
ffffffffc0204608:	7402                	ld	s0,32(sp)
ffffffffc020460a:	64e2                	ld	s1,24(sp)
ffffffffc020460c:	6942                	ld	s2,16(sp)
ffffffffc020460e:	69a2                	ld	s3,8(sp)
ffffffffc0204610:	6a02                	ld	s4,0(sp)
ffffffffc0204612:	6145                	addi	sp,sp,48
ffffffffc0204614:	8082                	ret
        last_pid = 1;
ffffffffc0204616:	4785                	li	a5,1
ffffffffc0204618:	00f82023          	sw	a5,0(a6)
        goto inside;
ffffffffc020461c:	4505                	li	a0,1
ffffffffc020461e:	00007317          	auipc	t1,0x7
ffffffffc0204622:	a3e30313          	addi	t1,t1,-1474 # ffffffffc020b05c <next_safe.0>
ffffffffc0204626:	b5cd                	j	ffffffffc0204508 <do_fork+0x10e>
        intr_disable();
ffffffffc0204628:	f9dfb0ef          	jal	ra,ffffffffc02005c4 <intr_disable>
        return 1;
ffffffffc020462c:	b56d                	j	ffffffffc02044d6 <do_fork+0xdc>
                    if (last_pid >= MAX_PID) {
ffffffffc020462e:	01d6c363          	blt	a3,t4,ffffffffc0204634 <do_fork+0x23a>
                        last_pid = 1;
ffffffffc0204632:	4685                	li	a3,1
                    goto repeat;
ffffffffc0204634:	4585                	li	a1,1
ffffffffc0204636:	b5ed                	j	ffffffffc0204520 <do_fork+0x126>
    int ret = -E_NO_FREE_PROC;
ffffffffc0204638:	556d                	li	a0,-5
ffffffffc020463a:	b7f1                	j	ffffffffc0204606 <do_fork+0x20c>
ffffffffc020463c:	c589                	beqz	a1,ffffffffc0204646 <do_fork+0x24c>
ffffffffc020463e:	00d82023          	sw	a3,0(a6)
    return last_pid;
ffffffffc0204642:	8536                	mv	a0,a3
ffffffffc0204644:	b705                	j	ffffffffc0204564 <do_fork+0x16a>
ffffffffc0204646:	00082503          	lw	a0,0(a6)
ffffffffc020464a:	bf29                	j	ffffffffc0204564 <do_fork+0x16a>
    return pa2page(PADDR(kva));
ffffffffc020464c:	00002617          	auipc	a2,0x2
ffffffffc0204650:	8ac60613          	addi	a2,a2,-1876 # ffffffffc0205ef8 <commands+0xd50>
ffffffffc0204654:	06e00593          	li	a1,110
ffffffffc0204658:	00001517          	auipc	a0,0x1
ffffffffc020465c:	4c050513          	addi	a0,a0,1216 # ffffffffc0205b18 <commands+0x970>
ffffffffc0204660:	b69fb0ef          	jal	ra,ffffffffc02001c8 <__panic>
    return KADDR(page2pa(page));
ffffffffc0204664:	00001617          	auipc	a2,0x1
ffffffffc0204668:	4c460613          	addi	a2,a2,1220 # ffffffffc0205b28 <commands+0x980>
ffffffffc020466c:	06900593          	li	a1,105
ffffffffc0204670:	00001517          	auipc	a0,0x1
ffffffffc0204674:	4a850513          	addi	a0,a0,1192 # ffffffffc0205b18 <commands+0x970>
ffffffffc0204678:	b51fb0ef          	jal	ra,ffffffffc02001c8 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc020467c:	00001617          	auipc	a2,0x1
ffffffffc0204680:	47c60613          	addi	a2,a2,1148 # ffffffffc0205af8 <commands+0x950>
ffffffffc0204684:	06200593          	li	a1,98
ffffffffc0204688:	00001517          	auipc	a0,0x1
ffffffffc020468c:	49050513          	addi	a0,a0,1168 # ffffffffc0205b18 <commands+0x970>
ffffffffc0204690:	b39fb0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(current->mm == NULL);
ffffffffc0204694:	00002697          	auipc	a3,0x2
ffffffffc0204698:	5ec68693          	addi	a3,a3,1516 # ffffffffc0206c80 <default_pmm_manager+0x638>
ffffffffc020469c:	00001617          	auipc	a2,0x1
ffffffffc02046a0:	23460613          	addi	a2,a2,564 # ffffffffc02058d0 <commands+0x728>
ffffffffc02046a4:	10300593          	li	a1,259
ffffffffc02046a8:	00002517          	auipc	a0,0x2
ffffffffc02046ac:	5f050513          	addi	a0,a0,1520 # ffffffffc0206c98 <default_pmm_manager+0x650>
ffffffffc02046b0:	b19fb0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc02046b4 <kernel_thread>:
kernel_thread(int (*fn)(void *), void *arg, uint32_t clone_flags) {
ffffffffc02046b4:	7129                	addi	sp,sp,-320
ffffffffc02046b6:	fa22                	sd	s0,304(sp)
ffffffffc02046b8:	f626                	sd	s1,296(sp)
ffffffffc02046ba:	f24a                	sd	s2,288(sp)
ffffffffc02046bc:	84ae                	mv	s1,a1
ffffffffc02046be:	892a                	mv	s2,a0
ffffffffc02046c0:	8432                	mv	s0,a2
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc02046c2:	4581                	li	a1,0
ffffffffc02046c4:	12000613          	li	a2,288
ffffffffc02046c8:	850a                	mv	a0,sp
kernel_thread(int (*fn)(void *), void *arg, uint32_t clone_flags) {
ffffffffc02046ca:	fe06                	sd	ra,312(sp)
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc02046cc:	400000ef          	jal	ra,ffffffffc0204acc <memset>
    tf.gpr.s0 = (uintptr_t)fn;
ffffffffc02046d0:	e0ca                	sd	s2,64(sp)
    tf.gpr.s1 = (uintptr_t)arg;
ffffffffc02046d2:	e4a6                	sd	s1,72(sp)
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc02046d4:	100027f3          	csrr	a5,sstatus
ffffffffc02046d8:	edd7f793          	andi	a5,a5,-291
ffffffffc02046dc:	1207e793          	ori	a5,a5,288
ffffffffc02046e0:	e23e                	sd	a5,256(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02046e2:	860a                	mv	a2,sp
ffffffffc02046e4:	10046513          	ori	a0,s0,256
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc02046e8:	00000797          	auipc	a5,0x0
ffffffffc02046ec:	b5078793          	addi	a5,a5,-1200 # ffffffffc0204238 <kernel_thread_entry>
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02046f0:	4581                	li	a1,0
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc02046f2:	e63e                	sd	a5,264(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02046f4:	d07ff0ef          	jal	ra,ffffffffc02043fa <do_fork>
}
ffffffffc02046f8:	70f2                	ld	ra,312(sp)
ffffffffc02046fa:	7452                	ld	s0,304(sp)
ffffffffc02046fc:	74b2                	ld	s1,296(sp)
ffffffffc02046fe:	7912                	ld	s2,288(sp)
ffffffffc0204700:	6131                	addi	sp,sp,320
ffffffffc0204702:	8082                	ret

ffffffffc0204704 <do_exit>:
do_exit(int error_code) {
ffffffffc0204704:	1141                	addi	sp,sp,-16
    panic("process exit!!.\n");
ffffffffc0204706:	00002617          	auipc	a2,0x2
ffffffffc020470a:	5aa60613          	addi	a2,a2,1450 # ffffffffc0206cb0 <default_pmm_manager+0x668>
ffffffffc020470e:	17500593          	li	a1,373
ffffffffc0204712:	00002517          	auipc	a0,0x2
ffffffffc0204716:	58650513          	addi	a0,a0,1414 # ffffffffc0206c98 <default_pmm_manager+0x650>
do_exit(int error_code) {
ffffffffc020471a:	e406                	sd	ra,8(sp)
    panic("process exit!!.\n");
ffffffffc020471c:	aadfb0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc0204720 <proc_init>:

// proc_init - set up the first kernel thread idleproc "idle" by itself and 
//           - create the second kernel thread init_main
void
proc_init(void) {
ffffffffc0204720:	7179                	addi	sp,sp,-48
ffffffffc0204722:	ec26                	sd	s1,24(sp)
    elm->prev = elm->next = elm;
ffffffffc0204724:	00012797          	auipc	a5,0x12
ffffffffc0204728:	e0478793          	addi	a5,a5,-508 # ffffffffc0216528 <proc_list>
ffffffffc020472c:	f406                	sd	ra,40(sp)
ffffffffc020472e:	f022                	sd	s0,32(sp)
ffffffffc0204730:	e84a                	sd	s2,16(sp)
ffffffffc0204732:	e44e                	sd	s3,8(sp)
ffffffffc0204734:	0000e497          	auipc	s1,0xe
ffffffffc0204738:	de448493          	addi	s1,s1,-540 # ffffffffc0212518 <hash_list>
ffffffffc020473c:	e79c                	sd	a5,8(a5)
ffffffffc020473e:	e39c                	sd	a5,0(a5)
    int i;

    list_init(&proc_list);
    for (i = 0; i < HASH_LIST_SIZE; i ++) {
ffffffffc0204740:	00012717          	auipc	a4,0x12
ffffffffc0204744:	dd870713          	addi	a4,a4,-552 # ffffffffc0216518 <name.2>
ffffffffc0204748:	87a6                	mv	a5,s1
ffffffffc020474a:	e79c                	sd	a5,8(a5)
ffffffffc020474c:	e39c                	sd	a5,0(a5)
ffffffffc020474e:	07c1                	addi	a5,a5,16
ffffffffc0204750:	fef71de3          	bne	a4,a5,ffffffffc020474a <proc_init+0x2a>
        list_init(hash_list + i);
    }

    if ((idleproc = alloc_proc()) == NULL) {
ffffffffc0204754:	b57ff0ef          	jal	ra,ffffffffc02042aa <alloc_proc>
ffffffffc0204758:	00012917          	auipc	s2,0x12
ffffffffc020475c:	e6090913          	addi	s2,s2,-416 # ffffffffc02165b8 <idleproc>
ffffffffc0204760:	00a93023          	sd	a0,0(s2)
ffffffffc0204764:	18050d63          	beqz	a0,ffffffffc02048fe <proc_init+0x1de>
        panic("cannot alloc idleproc.\n");
    }

    // check the proc structure
    int *context_mem = (int*) kmalloc(sizeof(struct context));
ffffffffc0204768:	07000513          	li	a0,112
ffffffffc020476c:	ad4fd0ef          	jal	ra,ffffffffc0201a40 <kmalloc>
    memset(context_mem, 0, sizeof(struct context));
ffffffffc0204770:	07000613          	li	a2,112
ffffffffc0204774:	4581                	li	a1,0
    int *context_mem = (int*) kmalloc(sizeof(struct context));
ffffffffc0204776:	842a                	mv	s0,a0
    memset(context_mem, 0, sizeof(struct context));
ffffffffc0204778:	354000ef          	jal	ra,ffffffffc0204acc <memset>
    int context_init_flag = memcmp(&(idleproc->context), context_mem, sizeof(struct context));
ffffffffc020477c:	00093503          	ld	a0,0(s2)
ffffffffc0204780:	85a2                	mv	a1,s0
ffffffffc0204782:	07000613          	li	a2,112
ffffffffc0204786:	03050513          	addi	a0,a0,48
ffffffffc020478a:	36c000ef          	jal	ra,ffffffffc0204af6 <memcmp>
ffffffffc020478e:	89aa                	mv	s3,a0

    int *proc_name_mem = (int*) kmalloc(PROC_NAME_LEN);
ffffffffc0204790:	453d                	li	a0,15
ffffffffc0204792:	aaefd0ef          	jal	ra,ffffffffc0201a40 <kmalloc>
    memset(proc_name_mem, 0, PROC_NAME_LEN);
ffffffffc0204796:	463d                	li	a2,15
ffffffffc0204798:	4581                	li	a1,0
    int *proc_name_mem = (int*) kmalloc(PROC_NAME_LEN);
ffffffffc020479a:	842a                	mv	s0,a0
    memset(proc_name_mem, 0, PROC_NAME_LEN);
ffffffffc020479c:	330000ef          	jal	ra,ffffffffc0204acc <memset>
    int proc_name_flag = memcmp(&(idleproc->name), proc_name_mem, PROC_NAME_LEN);
ffffffffc02047a0:	00093503          	ld	a0,0(s2)
ffffffffc02047a4:	463d                	li	a2,15
ffffffffc02047a6:	85a2                	mv	a1,s0
ffffffffc02047a8:	0b450513          	addi	a0,a0,180
ffffffffc02047ac:	34a000ef          	jal	ra,ffffffffc0204af6 <memcmp>

    if(idleproc->cr3 == boot_cr3 && idleproc->tf == NULL && !context_init_flag
ffffffffc02047b0:	00093783          	ld	a5,0(s2)
ffffffffc02047b4:	00012717          	auipc	a4,0x12
ffffffffc02047b8:	dcc73703          	ld	a4,-564(a4) # ffffffffc0216580 <boot_cr3>
ffffffffc02047bc:	77d4                	ld	a3,168(a5)
ffffffffc02047be:	0ee68463          	beq	a3,a4,ffffffffc02048a6 <proc_init+0x186>
        cprintf("alloc_proc() correct!\n");

    }
    
    idleproc->pid = 0;
    idleproc->state = PROC_RUNNABLE;
ffffffffc02047c2:	4709                	li	a4,2
ffffffffc02047c4:	e398                	sd	a4,0(a5)
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc02047c6:	00004717          	auipc	a4,0x4
ffffffffc02047ca:	83a70713          	addi	a4,a4,-1990 # ffffffffc0208000 <bootstack>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02047ce:	0b478413          	addi	s0,a5,180
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc02047d2:	eb98                	sd	a4,16(a5)
    idleproc->need_resched = 1;
ffffffffc02047d4:	4705                	li	a4,1
ffffffffc02047d6:	cf98                	sw	a4,24(a5)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02047d8:	4641                	li	a2,16
ffffffffc02047da:	4581                	li	a1,0
ffffffffc02047dc:	8522                	mv	a0,s0
ffffffffc02047de:	2ee000ef          	jal	ra,ffffffffc0204acc <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc02047e2:	463d                	li	a2,15
ffffffffc02047e4:	00002597          	auipc	a1,0x2
ffffffffc02047e8:	51458593          	addi	a1,a1,1300 # ffffffffc0206cf8 <default_pmm_manager+0x6b0>
ffffffffc02047ec:	8522                	mv	a0,s0
ffffffffc02047ee:	2f0000ef          	jal	ra,ffffffffc0204ade <memcpy>
    set_proc_name(idleproc, "idle");
    nr_process ++;
ffffffffc02047f2:	00012717          	auipc	a4,0x12
ffffffffc02047f6:	dd670713          	addi	a4,a4,-554 # ffffffffc02165c8 <nr_process>
ffffffffc02047fa:	431c                	lw	a5,0(a4)

    current = idleproc;
ffffffffc02047fc:	00093683          	ld	a3,0(s2)

    int pid = kernel_thread(init_main, "Hello world!!", 0);
ffffffffc0204800:	4601                	li	a2,0
    nr_process ++;
ffffffffc0204802:	2785                	addiw	a5,a5,1
    int pid = kernel_thread(init_main, "Hello world!!", 0);
ffffffffc0204804:	00002597          	auipc	a1,0x2
ffffffffc0204808:	4fc58593          	addi	a1,a1,1276 # ffffffffc0206d00 <default_pmm_manager+0x6b8>
ffffffffc020480c:	00000517          	auipc	a0,0x0
ffffffffc0204810:	b0e50513          	addi	a0,a0,-1266 # ffffffffc020431a <init_main>
    nr_process ++;
ffffffffc0204814:	c31c                	sw	a5,0(a4)
    current = idleproc;
ffffffffc0204816:	00012797          	auipc	a5,0x12
ffffffffc020481a:	d8d7bd23          	sd	a3,-614(a5) # ffffffffc02165b0 <current>
    int pid = kernel_thread(init_main, "Hello world!!", 0);
ffffffffc020481e:	e97ff0ef          	jal	ra,ffffffffc02046b4 <kernel_thread>
ffffffffc0204822:	842a                	mv	s0,a0
    if (pid <= 0) {
ffffffffc0204824:	0ea05963          	blez	a0,ffffffffc0204916 <proc_init+0x1f6>
    if (0 < pid && pid < MAX_PID) {
ffffffffc0204828:	6789                	lui	a5,0x2
ffffffffc020482a:	fff5071b          	addiw	a4,a0,-1
ffffffffc020482e:	17f9                	addi	a5,a5,-2
ffffffffc0204830:	2501                	sext.w	a0,a0
ffffffffc0204832:	02e7e363          	bltu	a5,a4,ffffffffc0204858 <proc_init+0x138>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204836:	45a9                	li	a1,10
ffffffffc0204838:	6d0000ef          	jal	ra,ffffffffc0204f08 <hash32>
ffffffffc020483c:	02051793          	slli	a5,a0,0x20
ffffffffc0204840:	01c7d693          	srli	a3,a5,0x1c
ffffffffc0204844:	96a6                	add	a3,a3,s1
ffffffffc0204846:	87b6                	mv	a5,a3
        while ((le = list_next(le)) != list) {
ffffffffc0204848:	a029                	j	ffffffffc0204852 <proc_init+0x132>
            if (proc->pid == pid) {
ffffffffc020484a:	f2c7a703          	lw	a4,-212(a5) # 1f2c <kern_entry-0xffffffffc01fe0d4>
ffffffffc020484e:	0a870563          	beq	a4,s0,ffffffffc02048f8 <proc_init+0x1d8>
    return listelm->next;
ffffffffc0204852:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list) {
ffffffffc0204854:	fef69be3          	bne	a3,a5,ffffffffc020484a <proc_init+0x12a>
    return NULL;
ffffffffc0204858:	4781                	li	a5,0
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc020485a:	0b478493          	addi	s1,a5,180
ffffffffc020485e:	4641                	li	a2,16
ffffffffc0204860:	4581                	li	a1,0
        panic("create init_main failed.\n");
    }

    initproc = find_proc(pid);
ffffffffc0204862:	00012417          	auipc	s0,0x12
ffffffffc0204866:	d5e40413          	addi	s0,s0,-674 # ffffffffc02165c0 <initproc>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc020486a:	8526                	mv	a0,s1
    initproc = find_proc(pid);
ffffffffc020486c:	e01c                	sd	a5,0(s0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc020486e:	25e000ef          	jal	ra,ffffffffc0204acc <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204872:	463d                	li	a2,15
ffffffffc0204874:	00002597          	auipc	a1,0x2
ffffffffc0204878:	4bc58593          	addi	a1,a1,1212 # ffffffffc0206d30 <default_pmm_manager+0x6e8>
ffffffffc020487c:	8526                	mv	a0,s1
ffffffffc020487e:	260000ef          	jal	ra,ffffffffc0204ade <memcpy>
    set_proc_name(initproc, "init");

    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0204882:	00093783          	ld	a5,0(s2)
ffffffffc0204886:	c7e1                	beqz	a5,ffffffffc020494e <proc_init+0x22e>
ffffffffc0204888:	43dc                	lw	a5,4(a5)
ffffffffc020488a:	e3f1                	bnez	a5,ffffffffc020494e <proc_init+0x22e>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc020488c:	601c                	ld	a5,0(s0)
ffffffffc020488e:	c3c5                	beqz	a5,ffffffffc020492e <proc_init+0x20e>
ffffffffc0204890:	43d8                	lw	a4,4(a5)
ffffffffc0204892:	4785                	li	a5,1
ffffffffc0204894:	08f71d63          	bne	a4,a5,ffffffffc020492e <proc_init+0x20e>
}
ffffffffc0204898:	70a2                	ld	ra,40(sp)
ffffffffc020489a:	7402                	ld	s0,32(sp)
ffffffffc020489c:	64e2                	ld	s1,24(sp)
ffffffffc020489e:	6942                	ld	s2,16(sp)
ffffffffc02048a0:	69a2                	ld	s3,8(sp)
ffffffffc02048a2:	6145                	addi	sp,sp,48
ffffffffc02048a4:	8082                	ret
    if(idleproc->cr3 == boot_cr3 && idleproc->tf == NULL && !context_init_flag
ffffffffc02048a6:	73d8                	ld	a4,160(a5)
ffffffffc02048a8:	ff09                	bnez	a4,ffffffffc02047c2 <proc_init+0xa2>
ffffffffc02048aa:	f0099ce3          	bnez	s3,ffffffffc02047c2 <proc_init+0xa2>
        && idleproc->state == PROC_UNINIT && idleproc->pid == -1 && idleproc->runs == 0
ffffffffc02048ae:	6394                	ld	a3,0(a5)
ffffffffc02048b0:	577d                	li	a4,-1
ffffffffc02048b2:	1702                	slli	a4,a4,0x20
ffffffffc02048b4:	f0e697e3          	bne	a3,a4,ffffffffc02047c2 <proc_init+0xa2>
ffffffffc02048b8:	4798                	lw	a4,8(a5)
ffffffffc02048ba:	f00714e3          	bnez	a4,ffffffffc02047c2 <proc_init+0xa2>
        && idleproc->kstack == 0 && idleproc->need_resched == 0 && idleproc->parent == NULL
ffffffffc02048be:	6b98                	ld	a4,16(a5)
ffffffffc02048c0:	f00711e3          	bnez	a4,ffffffffc02047c2 <proc_init+0xa2>
ffffffffc02048c4:	4f98                	lw	a4,24(a5)
ffffffffc02048c6:	2701                	sext.w	a4,a4
ffffffffc02048c8:	ee071de3          	bnez	a4,ffffffffc02047c2 <proc_init+0xa2>
ffffffffc02048cc:	7398                	ld	a4,32(a5)
ffffffffc02048ce:	ee071ae3          	bnez	a4,ffffffffc02047c2 <proc_init+0xa2>
        && idleproc->mm == NULL && idleproc->flags == 0 && !proc_name_flag
ffffffffc02048d2:	7798                	ld	a4,40(a5)
ffffffffc02048d4:	ee0717e3          	bnez	a4,ffffffffc02047c2 <proc_init+0xa2>
ffffffffc02048d8:	0b07a703          	lw	a4,176(a5)
ffffffffc02048dc:	8d59                	or	a0,a0,a4
ffffffffc02048de:	0005071b          	sext.w	a4,a0
ffffffffc02048e2:	ee0710e3          	bnez	a4,ffffffffc02047c2 <proc_init+0xa2>
        cprintf("alloc_proc() correct!\n");
ffffffffc02048e6:	00002517          	auipc	a0,0x2
ffffffffc02048ea:	3fa50513          	addi	a0,a0,1018 # ffffffffc0206ce0 <default_pmm_manager+0x698>
ffffffffc02048ee:	fdefb0ef          	jal	ra,ffffffffc02000cc <cprintf>
    idleproc->pid = 0;
ffffffffc02048f2:	00093783          	ld	a5,0(s2)
ffffffffc02048f6:	b5f1                	j	ffffffffc02047c2 <proc_init+0xa2>
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc02048f8:	f2878793          	addi	a5,a5,-216
ffffffffc02048fc:	bfb9                	j	ffffffffc020485a <proc_init+0x13a>
        panic("cannot alloc idleproc.\n");
ffffffffc02048fe:	00002617          	auipc	a2,0x2
ffffffffc0204902:	3ca60613          	addi	a2,a2,970 # ffffffffc0206cc8 <default_pmm_manager+0x680>
ffffffffc0204906:	18d00593          	li	a1,397
ffffffffc020490a:	00002517          	auipc	a0,0x2
ffffffffc020490e:	38e50513          	addi	a0,a0,910 # ffffffffc0206c98 <default_pmm_manager+0x650>
ffffffffc0204912:	8b7fb0ef          	jal	ra,ffffffffc02001c8 <__panic>
        panic("create init_main failed.\n");
ffffffffc0204916:	00002617          	auipc	a2,0x2
ffffffffc020491a:	3fa60613          	addi	a2,a2,1018 # ffffffffc0206d10 <default_pmm_manager+0x6c8>
ffffffffc020491e:	1ad00593          	li	a1,429
ffffffffc0204922:	00002517          	auipc	a0,0x2
ffffffffc0204926:	37650513          	addi	a0,a0,886 # ffffffffc0206c98 <default_pmm_manager+0x650>
ffffffffc020492a:	89ffb0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc020492e:	00002697          	auipc	a3,0x2
ffffffffc0204932:	43268693          	addi	a3,a3,1074 # ffffffffc0206d60 <default_pmm_manager+0x718>
ffffffffc0204936:	00001617          	auipc	a2,0x1
ffffffffc020493a:	f9a60613          	addi	a2,a2,-102 # ffffffffc02058d0 <commands+0x728>
ffffffffc020493e:	1b400593          	li	a1,436
ffffffffc0204942:	00002517          	auipc	a0,0x2
ffffffffc0204946:	35650513          	addi	a0,a0,854 # ffffffffc0206c98 <default_pmm_manager+0x650>
ffffffffc020494a:	87ffb0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc020494e:	00002697          	auipc	a3,0x2
ffffffffc0204952:	3ea68693          	addi	a3,a3,1002 # ffffffffc0206d38 <default_pmm_manager+0x6f0>
ffffffffc0204956:	00001617          	auipc	a2,0x1
ffffffffc020495a:	f7a60613          	addi	a2,a2,-134 # ffffffffc02058d0 <commands+0x728>
ffffffffc020495e:	1b300593          	li	a1,435
ffffffffc0204962:	00002517          	auipc	a0,0x2
ffffffffc0204966:	33650513          	addi	a0,a0,822 # ffffffffc0206c98 <default_pmm_manager+0x650>
ffffffffc020496a:	85ffb0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc020496e <cpu_idle>:

// cpu_idle - at the end of kern_init, the first kernel thread idleproc will do below works
void
cpu_idle(void) {
ffffffffc020496e:	1141                	addi	sp,sp,-16
ffffffffc0204970:	e022                	sd	s0,0(sp)
ffffffffc0204972:	e406                	sd	ra,8(sp)
ffffffffc0204974:	00012417          	auipc	s0,0x12
ffffffffc0204978:	c3c40413          	addi	s0,s0,-964 # ffffffffc02165b0 <current>
    while (1) {
        if (current->need_resched) {
ffffffffc020497c:	6018                	ld	a4,0(s0)
ffffffffc020497e:	4f1c                	lw	a5,24(a4)
ffffffffc0204980:	2781                	sext.w	a5,a5
ffffffffc0204982:	dff5                	beqz	a5,ffffffffc020497e <cpu_idle+0x10>
            schedule();
ffffffffc0204984:	038000ef          	jal	ra,ffffffffc02049bc <schedule>
ffffffffc0204988:	bfd5                	j	ffffffffc020497c <cpu_idle+0xe>

ffffffffc020498a <wakeup_proc>:
#include <sched.h>
#include <assert.h>

void
wakeup_proc(struct proc_struct *proc) {
    assert(proc->state != PROC_ZOMBIE && proc->state != PROC_RUNNABLE);
ffffffffc020498a:	411c                	lw	a5,0(a0)
ffffffffc020498c:	4705                	li	a4,1
ffffffffc020498e:	37f9                	addiw	a5,a5,-2
ffffffffc0204990:	00f77563          	bgeu	a4,a5,ffffffffc020499a <wakeup_proc+0x10>
    proc->state = PROC_RUNNABLE;
ffffffffc0204994:	4789                	li	a5,2
ffffffffc0204996:	c11c                	sw	a5,0(a0)
ffffffffc0204998:	8082                	ret
wakeup_proc(struct proc_struct *proc) {
ffffffffc020499a:	1141                	addi	sp,sp,-16
    assert(proc->state != PROC_ZOMBIE && proc->state != PROC_RUNNABLE);
ffffffffc020499c:	00002697          	auipc	a3,0x2
ffffffffc02049a0:	3ec68693          	addi	a3,a3,1004 # ffffffffc0206d88 <default_pmm_manager+0x740>
ffffffffc02049a4:	00001617          	auipc	a2,0x1
ffffffffc02049a8:	f2c60613          	addi	a2,a2,-212 # ffffffffc02058d0 <commands+0x728>
ffffffffc02049ac:	45a5                	li	a1,9
ffffffffc02049ae:	00002517          	auipc	a0,0x2
ffffffffc02049b2:	41a50513          	addi	a0,a0,1050 # ffffffffc0206dc8 <default_pmm_manager+0x780>
wakeup_proc(struct proc_struct *proc) {
ffffffffc02049b6:	e406                	sd	ra,8(sp)
    assert(proc->state != PROC_ZOMBIE && proc->state != PROC_RUNNABLE);
ffffffffc02049b8:	811fb0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc02049bc <schedule>:
}

void
schedule(void) {
ffffffffc02049bc:	1141                	addi	sp,sp,-16
ffffffffc02049be:	e406                	sd	ra,8(sp)
ffffffffc02049c0:	e022                	sd	s0,0(sp)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02049c2:	100027f3          	csrr	a5,sstatus
ffffffffc02049c6:	8b89                	andi	a5,a5,2
ffffffffc02049c8:	4401                	li	s0,0
ffffffffc02049ca:	efbd                	bnez	a5,ffffffffc0204a48 <schedule+0x8c>
    bool intr_flag;
    list_entry_t *le, *last;
    struct proc_struct *next = NULL;
    local_intr_save(intr_flag);
    {
        current->need_resched = 0;
ffffffffc02049cc:	00012897          	auipc	a7,0x12
ffffffffc02049d0:	be48b883          	ld	a7,-1052(a7) # ffffffffc02165b0 <current>
ffffffffc02049d4:	0008ac23          	sw	zero,24(a7)
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc02049d8:	00012517          	auipc	a0,0x12
ffffffffc02049dc:	be053503          	ld	a0,-1056(a0) # ffffffffc02165b8 <idleproc>
ffffffffc02049e0:	04a88e63          	beq	a7,a0,ffffffffc0204a3c <schedule+0x80>
ffffffffc02049e4:	0c888693          	addi	a3,a7,200
ffffffffc02049e8:	00012617          	auipc	a2,0x12
ffffffffc02049ec:	b4060613          	addi	a2,a2,-1216 # ffffffffc0216528 <proc_list>
        le = last;
ffffffffc02049f0:	87b6                	mv	a5,a3
    struct proc_struct *next = NULL;
ffffffffc02049f2:	4581                	li	a1,0
        do {
            if ((le = list_next(le)) != &proc_list) {
                next = le2proc(le, list_link);
                if (next->state == PROC_RUNNABLE) {
ffffffffc02049f4:	4809                	li	a6,2
ffffffffc02049f6:	679c                	ld	a5,8(a5)
            if ((le = list_next(le)) != &proc_list) {
ffffffffc02049f8:	00c78863          	beq	a5,a2,ffffffffc0204a08 <schedule+0x4c>
                if (next->state == PROC_RUNNABLE) {
ffffffffc02049fc:	f387a703          	lw	a4,-200(a5)
                next = le2proc(le, list_link);
ffffffffc0204a00:	f3878593          	addi	a1,a5,-200
                if (next->state == PROC_RUNNABLE) {
ffffffffc0204a04:	03070163          	beq	a4,a6,ffffffffc0204a26 <schedule+0x6a>
                    break;
                }
            }
        } while (le != last);
ffffffffc0204a08:	fef697e3          	bne	a3,a5,ffffffffc02049f6 <schedule+0x3a>
        if (next == NULL || next->state != PROC_RUNNABLE) {
ffffffffc0204a0c:	ed89                	bnez	a1,ffffffffc0204a26 <schedule+0x6a>
            next = idleproc;
        }
        next->runs ++;
ffffffffc0204a0e:	451c                	lw	a5,8(a0)
ffffffffc0204a10:	2785                	addiw	a5,a5,1
ffffffffc0204a12:	c51c                	sw	a5,8(a0)
        if (next != current) {
ffffffffc0204a14:	00a88463          	beq	a7,a0,ffffffffc0204a1c <schedule+0x60>
            proc_run(next);
ffffffffc0204a18:	975ff0ef          	jal	ra,ffffffffc020438c <proc_run>
    if (flag) {
ffffffffc0204a1c:	e819                	bnez	s0,ffffffffc0204a32 <schedule+0x76>
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc0204a1e:	60a2                	ld	ra,8(sp)
ffffffffc0204a20:	6402                	ld	s0,0(sp)
ffffffffc0204a22:	0141                	addi	sp,sp,16
ffffffffc0204a24:	8082                	ret
        if (next == NULL || next->state != PROC_RUNNABLE) {
ffffffffc0204a26:	4198                	lw	a4,0(a1)
ffffffffc0204a28:	4789                	li	a5,2
ffffffffc0204a2a:	fef712e3          	bne	a4,a5,ffffffffc0204a0e <schedule+0x52>
ffffffffc0204a2e:	852e                	mv	a0,a1
ffffffffc0204a30:	bff9                	j	ffffffffc0204a0e <schedule+0x52>
}
ffffffffc0204a32:	6402                	ld	s0,0(sp)
ffffffffc0204a34:	60a2                	ld	ra,8(sp)
ffffffffc0204a36:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc0204a38:	b87fb06f          	j	ffffffffc02005be <intr_enable>
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc0204a3c:	00012617          	auipc	a2,0x12
ffffffffc0204a40:	aec60613          	addi	a2,a2,-1300 # ffffffffc0216528 <proc_list>
ffffffffc0204a44:	86b2                	mv	a3,a2
ffffffffc0204a46:	b76d                	j	ffffffffc02049f0 <schedule+0x34>
        intr_disable();
ffffffffc0204a48:	b7dfb0ef          	jal	ra,ffffffffc02005c4 <intr_disable>
        return 1;
ffffffffc0204a4c:	4405                	li	s0,1
ffffffffc0204a4e:	bfbd                	j	ffffffffc02049cc <schedule+0x10>

ffffffffc0204a50 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0204a50:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc0204a54:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc0204a56:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc0204a58:	cb81                	beqz	a5,ffffffffc0204a68 <strlen+0x18>
        cnt ++;
ffffffffc0204a5a:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc0204a5c:	00a707b3          	add	a5,a4,a0
ffffffffc0204a60:	0007c783          	lbu	a5,0(a5)
ffffffffc0204a64:	fbfd                	bnez	a5,ffffffffc0204a5a <strlen+0xa>
ffffffffc0204a66:	8082                	ret
    }
    return cnt;
}
ffffffffc0204a68:	8082                	ret

ffffffffc0204a6a <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0204a6a:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0204a6c:	e589                	bnez	a1,ffffffffc0204a76 <strnlen+0xc>
ffffffffc0204a6e:	a811                	j	ffffffffc0204a82 <strnlen+0x18>
        cnt ++;
ffffffffc0204a70:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0204a72:	00f58863          	beq	a1,a5,ffffffffc0204a82 <strnlen+0x18>
ffffffffc0204a76:	00f50733          	add	a4,a0,a5
ffffffffc0204a7a:	00074703          	lbu	a4,0(a4)
ffffffffc0204a7e:	fb6d                	bnez	a4,ffffffffc0204a70 <strnlen+0x6>
ffffffffc0204a80:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0204a82:	852e                	mv	a0,a1
ffffffffc0204a84:	8082                	ret

ffffffffc0204a86 <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc0204a86:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc0204a88:	0005c703          	lbu	a4,0(a1)
ffffffffc0204a8c:	0785                	addi	a5,a5,1
ffffffffc0204a8e:	0585                	addi	a1,a1,1
ffffffffc0204a90:	fee78fa3          	sb	a4,-1(a5)
ffffffffc0204a94:	fb75                	bnez	a4,ffffffffc0204a88 <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc0204a96:	8082                	ret

ffffffffc0204a98 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0204a98:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0204a9c:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0204aa0:	cb89                	beqz	a5,ffffffffc0204ab2 <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc0204aa2:	0505                	addi	a0,a0,1
ffffffffc0204aa4:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0204aa6:	fee789e3          	beq	a5,a4,ffffffffc0204a98 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0204aaa:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0204aae:	9d19                	subw	a0,a0,a4
ffffffffc0204ab0:	8082                	ret
ffffffffc0204ab2:	4501                	li	a0,0
ffffffffc0204ab4:	bfed                	j	ffffffffc0204aae <strcmp+0x16>

ffffffffc0204ab6 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0204ab6:	00054783          	lbu	a5,0(a0)
ffffffffc0204aba:	c799                	beqz	a5,ffffffffc0204ac8 <strchr+0x12>
        if (*s == c) {
ffffffffc0204abc:	00f58763          	beq	a1,a5,ffffffffc0204aca <strchr+0x14>
    while (*s != '\0') {
ffffffffc0204ac0:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc0204ac4:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0204ac6:	fbfd                	bnez	a5,ffffffffc0204abc <strchr+0x6>
    }
    return NULL;
ffffffffc0204ac8:	4501                	li	a0,0
}
ffffffffc0204aca:	8082                	ret

ffffffffc0204acc <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0204acc:	ca01                	beqz	a2,ffffffffc0204adc <memset+0x10>
ffffffffc0204ace:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0204ad0:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0204ad2:	0785                	addi	a5,a5,1
ffffffffc0204ad4:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0204ad8:	fec79de3          	bne	a5,a2,ffffffffc0204ad2 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0204adc:	8082                	ret

ffffffffc0204ade <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc0204ade:	ca19                	beqz	a2,ffffffffc0204af4 <memcpy+0x16>
ffffffffc0204ae0:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc0204ae2:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc0204ae4:	0005c703          	lbu	a4,0(a1)
ffffffffc0204ae8:	0585                	addi	a1,a1,1
ffffffffc0204aea:	0785                	addi	a5,a5,1
ffffffffc0204aec:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc0204af0:	fec59ae3          	bne	a1,a2,ffffffffc0204ae4 <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc0204af4:	8082                	ret

ffffffffc0204af6 <memcmp>:
 * */
int
memcmp(const void *v1, const void *v2, size_t n) {
    const char *s1 = (const char *)v1;
    const char *s2 = (const char *)v2;
    while (n -- > 0) {
ffffffffc0204af6:	c205                	beqz	a2,ffffffffc0204b16 <memcmp+0x20>
ffffffffc0204af8:	962e                	add	a2,a2,a1
ffffffffc0204afa:	a019                	j	ffffffffc0204b00 <memcmp+0xa>
ffffffffc0204afc:	00c58d63          	beq	a1,a2,ffffffffc0204b16 <memcmp+0x20>
        if (*s1 != *s2) {
ffffffffc0204b00:	00054783          	lbu	a5,0(a0)
ffffffffc0204b04:	0005c703          	lbu	a4,0(a1)
            return (int)((unsigned char)*s1 - (unsigned char)*s2);
        }
        s1 ++, s2 ++;
ffffffffc0204b08:	0505                	addi	a0,a0,1
ffffffffc0204b0a:	0585                	addi	a1,a1,1
        if (*s1 != *s2) {
ffffffffc0204b0c:	fee788e3          	beq	a5,a4,ffffffffc0204afc <memcmp+0x6>
            return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0204b10:	40e7853b          	subw	a0,a5,a4
ffffffffc0204b14:	8082                	ret
    }
    return 0;
ffffffffc0204b16:	4501                	li	a0,0
}
ffffffffc0204b18:	8082                	ret

ffffffffc0204b1a <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0204b1a:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0204b1e:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0204b20:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0204b24:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0204b26:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0204b2a:	f022                	sd	s0,32(sp)
ffffffffc0204b2c:	ec26                	sd	s1,24(sp)
ffffffffc0204b2e:	e84a                	sd	s2,16(sp)
ffffffffc0204b30:	f406                	sd	ra,40(sp)
ffffffffc0204b32:	e44e                	sd	s3,8(sp)
ffffffffc0204b34:	84aa                	mv	s1,a0
ffffffffc0204b36:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0204b38:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0204b3c:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc0204b3e:	03067e63          	bgeu	a2,a6,ffffffffc0204b7a <printnum+0x60>
ffffffffc0204b42:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0204b44:	00805763          	blez	s0,ffffffffc0204b52 <printnum+0x38>
ffffffffc0204b48:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0204b4a:	85ca                	mv	a1,s2
ffffffffc0204b4c:	854e                	mv	a0,s3
ffffffffc0204b4e:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0204b50:	fc65                	bnez	s0,ffffffffc0204b48 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0204b52:	1a02                	slli	s4,s4,0x20
ffffffffc0204b54:	00002797          	auipc	a5,0x2
ffffffffc0204b58:	28c78793          	addi	a5,a5,652 # ffffffffc0206de0 <default_pmm_manager+0x798>
ffffffffc0204b5c:	020a5a13          	srli	s4,s4,0x20
ffffffffc0204b60:	9a3e                	add	s4,s4,a5
}
ffffffffc0204b62:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0204b64:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0204b68:	70a2                	ld	ra,40(sp)
ffffffffc0204b6a:	69a2                	ld	s3,8(sp)
ffffffffc0204b6c:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0204b6e:	85ca                	mv	a1,s2
ffffffffc0204b70:	87a6                	mv	a5,s1
}
ffffffffc0204b72:	6942                	ld	s2,16(sp)
ffffffffc0204b74:	64e2                	ld	s1,24(sp)
ffffffffc0204b76:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0204b78:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0204b7a:	03065633          	divu	a2,a2,a6
ffffffffc0204b7e:	8722                	mv	a4,s0
ffffffffc0204b80:	f9bff0ef          	jal	ra,ffffffffc0204b1a <printnum>
ffffffffc0204b84:	b7f9                	j	ffffffffc0204b52 <printnum+0x38>

ffffffffc0204b86 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0204b86:	7119                	addi	sp,sp,-128
ffffffffc0204b88:	f4a6                	sd	s1,104(sp)
ffffffffc0204b8a:	f0ca                	sd	s2,96(sp)
ffffffffc0204b8c:	ecce                	sd	s3,88(sp)
ffffffffc0204b8e:	e8d2                	sd	s4,80(sp)
ffffffffc0204b90:	e4d6                	sd	s5,72(sp)
ffffffffc0204b92:	e0da                	sd	s6,64(sp)
ffffffffc0204b94:	fc5e                	sd	s7,56(sp)
ffffffffc0204b96:	f06a                	sd	s10,32(sp)
ffffffffc0204b98:	fc86                	sd	ra,120(sp)
ffffffffc0204b9a:	f8a2                	sd	s0,112(sp)
ffffffffc0204b9c:	f862                	sd	s8,48(sp)
ffffffffc0204b9e:	f466                	sd	s9,40(sp)
ffffffffc0204ba0:	ec6e                	sd	s11,24(sp)
ffffffffc0204ba2:	892a                	mv	s2,a0
ffffffffc0204ba4:	84ae                	mv	s1,a1
ffffffffc0204ba6:	8d32                	mv	s10,a2
ffffffffc0204ba8:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0204baa:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0204bae:	5b7d                	li	s6,-1
ffffffffc0204bb0:	00002a97          	auipc	s5,0x2
ffffffffc0204bb4:	25ca8a93          	addi	s5,s5,604 # ffffffffc0206e0c <default_pmm_manager+0x7c4>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0204bb8:	00002b97          	auipc	s7,0x2
ffffffffc0204bbc:	430b8b93          	addi	s7,s7,1072 # ffffffffc0206fe8 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0204bc0:	000d4503          	lbu	a0,0(s10)
ffffffffc0204bc4:	001d0413          	addi	s0,s10,1
ffffffffc0204bc8:	01350a63          	beq	a0,s3,ffffffffc0204bdc <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc0204bcc:	c121                	beqz	a0,ffffffffc0204c0c <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc0204bce:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0204bd0:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0204bd2:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0204bd4:	fff44503          	lbu	a0,-1(s0)
ffffffffc0204bd8:	ff351ae3          	bne	a0,s3,ffffffffc0204bcc <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204bdc:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0204be0:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0204be4:	4c81                	li	s9,0
ffffffffc0204be6:	4881                	li	a7,0
        width = precision = -1;
ffffffffc0204be8:	5c7d                	li	s8,-1
ffffffffc0204bea:	5dfd                	li	s11,-1
ffffffffc0204bec:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc0204bf0:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204bf2:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0204bf6:	0ff5f593          	zext.b	a1,a1
ffffffffc0204bfa:	00140d13          	addi	s10,s0,1
ffffffffc0204bfe:	04b56263          	bltu	a0,a1,ffffffffc0204c42 <vprintfmt+0xbc>
ffffffffc0204c02:	058a                	slli	a1,a1,0x2
ffffffffc0204c04:	95d6                	add	a1,a1,s5
ffffffffc0204c06:	4194                	lw	a3,0(a1)
ffffffffc0204c08:	96d6                	add	a3,a3,s5
ffffffffc0204c0a:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0204c0c:	70e6                	ld	ra,120(sp)
ffffffffc0204c0e:	7446                	ld	s0,112(sp)
ffffffffc0204c10:	74a6                	ld	s1,104(sp)
ffffffffc0204c12:	7906                	ld	s2,96(sp)
ffffffffc0204c14:	69e6                	ld	s3,88(sp)
ffffffffc0204c16:	6a46                	ld	s4,80(sp)
ffffffffc0204c18:	6aa6                	ld	s5,72(sp)
ffffffffc0204c1a:	6b06                	ld	s6,64(sp)
ffffffffc0204c1c:	7be2                	ld	s7,56(sp)
ffffffffc0204c1e:	7c42                	ld	s8,48(sp)
ffffffffc0204c20:	7ca2                	ld	s9,40(sp)
ffffffffc0204c22:	7d02                	ld	s10,32(sp)
ffffffffc0204c24:	6de2                	ld	s11,24(sp)
ffffffffc0204c26:	6109                	addi	sp,sp,128
ffffffffc0204c28:	8082                	ret
            padc = '0';
ffffffffc0204c2a:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc0204c2c:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204c30:	846a                	mv	s0,s10
ffffffffc0204c32:	00140d13          	addi	s10,s0,1
ffffffffc0204c36:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0204c3a:	0ff5f593          	zext.b	a1,a1
ffffffffc0204c3e:	fcb572e3          	bgeu	a0,a1,ffffffffc0204c02 <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc0204c42:	85a6                	mv	a1,s1
ffffffffc0204c44:	02500513          	li	a0,37
ffffffffc0204c48:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0204c4a:	fff44783          	lbu	a5,-1(s0)
ffffffffc0204c4e:	8d22                	mv	s10,s0
ffffffffc0204c50:	f73788e3          	beq	a5,s3,ffffffffc0204bc0 <vprintfmt+0x3a>
ffffffffc0204c54:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0204c58:	1d7d                	addi	s10,s10,-1
ffffffffc0204c5a:	ff379de3          	bne	a5,s3,ffffffffc0204c54 <vprintfmt+0xce>
ffffffffc0204c5e:	b78d                	j	ffffffffc0204bc0 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc0204c60:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc0204c64:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204c68:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0204c6a:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0204c6e:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0204c72:	02d86463          	bltu	a6,a3,ffffffffc0204c9a <vprintfmt+0x114>
                ch = *fmt;
ffffffffc0204c76:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0204c7a:	002c169b          	slliw	a3,s8,0x2
ffffffffc0204c7e:	0186873b          	addw	a4,a3,s8
ffffffffc0204c82:	0017171b          	slliw	a4,a4,0x1
ffffffffc0204c86:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc0204c88:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0204c8c:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0204c8e:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc0204c92:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0204c96:	fed870e3          	bgeu	a6,a3,ffffffffc0204c76 <vprintfmt+0xf0>
            if (width < 0)
ffffffffc0204c9a:	f40ddce3          	bgez	s11,ffffffffc0204bf2 <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc0204c9e:	8de2                	mv	s11,s8
ffffffffc0204ca0:	5c7d                	li	s8,-1
ffffffffc0204ca2:	bf81                	j	ffffffffc0204bf2 <vprintfmt+0x6c>
            if (width < 0)
ffffffffc0204ca4:	fffdc693          	not	a3,s11
ffffffffc0204ca8:	96fd                	srai	a3,a3,0x3f
ffffffffc0204caa:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204cae:	00144603          	lbu	a2,1(s0)
ffffffffc0204cb2:	2d81                	sext.w	s11,s11
ffffffffc0204cb4:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0204cb6:	bf35                	j	ffffffffc0204bf2 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc0204cb8:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204cbc:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0204cc0:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204cc2:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc0204cc4:	bfd9                	j	ffffffffc0204c9a <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc0204cc6:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0204cc8:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0204ccc:	01174463          	blt	a4,a7,ffffffffc0204cd4 <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc0204cd0:	1a088e63          	beqz	a7,ffffffffc0204e8c <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc0204cd4:	000a3603          	ld	a2,0(s4)
ffffffffc0204cd8:	46c1                	li	a3,16
ffffffffc0204cda:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0204cdc:	2781                	sext.w	a5,a5
ffffffffc0204cde:	876e                	mv	a4,s11
ffffffffc0204ce0:	85a6                	mv	a1,s1
ffffffffc0204ce2:	854a                	mv	a0,s2
ffffffffc0204ce4:	e37ff0ef          	jal	ra,ffffffffc0204b1a <printnum>
            break;
ffffffffc0204ce8:	bde1                	j	ffffffffc0204bc0 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc0204cea:	000a2503          	lw	a0,0(s4)
ffffffffc0204cee:	85a6                	mv	a1,s1
ffffffffc0204cf0:	0a21                	addi	s4,s4,8
ffffffffc0204cf2:	9902                	jalr	s2
            break;
ffffffffc0204cf4:	b5f1                	j	ffffffffc0204bc0 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0204cf6:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0204cf8:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0204cfc:	01174463          	blt	a4,a7,ffffffffc0204d04 <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc0204d00:	18088163          	beqz	a7,ffffffffc0204e82 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc0204d04:	000a3603          	ld	a2,0(s4)
ffffffffc0204d08:	46a9                	li	a3,10
ffffffffc0204d0a:	8a2e                	mv	s4,a1
ffffffffc0204d0c:	bfc1                	j	ffffffffc0204cdc <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204d0e:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0204d12:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204d14:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0204d16:	bdf1                	j	ffffffffc0204bf2 <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc0204d18:	85a6                	mv	a1,s1
ffffffffc0204d1a:	02500513          	li	a0,37
ffffffffc0204d1e:	9902                	jalr	s2
            break;
ffffffffc0204d20:	b545                	j	ffffffffc0204bc0 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204d22:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc0204d26:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204d28:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0204d2a:	b5e1                	j	ffffffffc0204bf2 <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc0204d2c:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0204d2e:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0204d32:	01174463          	blt	a4,a7,ffffffffc0204d3a <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc0204d36:	14088163          	beqz	a7,ffffffffc0204e78 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc0204d3a:	000a3603          	ld	a2,0(s4)
ffffffffc0204d3e:	46a1                	li	a3,8
ffffffffc0204d40:	8a2e                	mv	s4,a1
ffffffffc0204d42:	bf69                	j	ffffffffc0204cdc <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc0204d44:	03000513          	li	a0,48
ffffffffc0204d48:	85a6                	mv	a1,s1
ffffffffc0204d4a:	e03e                	sd	a5,0(sp)
ffffffffc0204d4c:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0204d4e:	85a6                	mv	a1,s1
ffffffffc0204d50:	07800513          	li	a0,120
ffffffffc0204d54:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0204d56:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0204d58:	6782                	ld	a5,0(sp)
ffffffffc0204d5a:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0204d5c:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc0204d60:	bfb5                	j	ffffffffc0204cdc <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0204d62:	000a3403          	ld	s0,0(s4)
ffffffffc0204d66:	008a0713          	addi	a4,s4,8
ffffffffc0204d6a:	e03a                	sd	a4,0(sp)
ffffffffc0204d6c:	14040263          	beqz	s0,ffffffffc0204eb0 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc0204d70:	0fb05763          	blez	s11,ffffffffc0204e5e <vprintfmt+0x2d8>
ffffffffc0204d74:	02d00693          	li	a3,45
ffffffffc0204d78:	0cd79163          	bne	a5,a3,ffffffffc0204e3a <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0204d7c:	00044783          	lbu	a5,0(s0)
ffffffffc0204d80:	0007851b          	sext.w	a0,a5
ffffffffc0204d84:	cf85                	beqz	a5,ffffffffc0204dbc <vprintfmt+0x236>
ffffffffc0204d86:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0204d8a:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0204d8e:	000c4563          	bltz	s8,ffffffffc0204d98 <vprintfmt+0x212>
ffffffffc0204d92:	3c7d                	addiw	s8,s8,-1
ffffffffc0204d94:	036c0263          	beq	s8,s6,ffffffffc0204db8 <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc0204d98:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0204d9a:	0e0c8e63          	beqz	s9,ffffffffc0204e96 <vprintfmt+0x310>
ffffffffc0204d9e:	3781                	addiw	a5,a5,-32
ffffffffc0204da0:	0ef47b63          	bgeu	s0,a5,ffffffffc0204e96 <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc0204da4:	03f00513          	li	a0,63
ffffffffc0204da8:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0204daa:	000a4783          	lbu	a5,0(s4)
ffffffffc0204dae:	3dfd                	addiw	s11,s11,-1
ffffffffc0204db0:	0a05                	addi	s4,s4,1
ffffffffc0204db2:	0007851b          	sext.w	a0,a5
ffffffffc0204db6:	ffe1                	bnez	a5,ffffffffc0204d8e <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc0204db8:	01b05963          	blez	s11,ffffffffc0204dca <vprintfmt+0x244>
ffffffffc0204dbc:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0204dbe:	85a6                	mv	a1,s1
ffffffffc0204dc0:	02000513          	li	a0,32
ffffffffc0204dc4:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0204dc6:	fe0d9be3          	bnez	s11,ffffffffc0204dbc <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0204dca:	6a02                	ld	s4,0(sp)
ffffffffc0204dcc:	bbd5                	j	ffffffffc0204bc0 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0204dce:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0204dd0:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc0204dd4:	01174463          	blt	a4,a7,ffffffffc0204ddc <vprintfmt+0x256>
    else if (lflag) {
ffffffffc0204dd8:	08088d63          	beqz	a7,ffffffffc0204e72 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc0204ddc:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0204de0:	0a044d63          	bltz	s0,ffffffffc0204e9a <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc0204de4:	8622                	mv	a2,s0
ffffffffc0204de6:	8a66                	mv	s4,s9
ffffffffc0204de8:	46a9                	li	a3,10
ffffffffc0204dea:	bdcd                	j	ffffffffc0204cdc <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc0204dec:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0204df0:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc0204df2:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0204df4:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0204df8:	8fb5                	xor	a5,a5,a3
ffffffffc0204dfa:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0204dfe:	02d74163          	blt	a4,a3,ffffffffc0204e20 <vprintfmt+0x29a>
ffffffffc0204e02:	00369793          	slli	a5,a3,0x3
ffffffffc0204e06:	97de                	add	a5,a5,s7
ffffffffc0204e08:	639c                	ld	a5,0(a5)
ffffffffc0204e0a:	cb99                	beqz	a5,ffffffffc0204e20 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0204e0c:	86be                	mv	a3,a5
ffffffffc0204e0e:	00000617          	auipc	a2,0x0
ffffffffc0204e12:	13a60613          	addi	a2,a2,314 # ffffffffc0204f48 <etext+0x2a>
ffffffffc0204e16:	85a6                	mv	a1,s1
ffffffffc0204e18:	854a                	mv	a0,s2
ffffffffc0204e1a:	0ce000ef          	jal	ra,ffffffffc0204ee8 <printfmt>
ffffffffc0204e1e:	b34d                	j	ffffffffc0204bc0 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0204e20:	00002617          	auipc	a2,0x2
ffffffffc0204e24:	fe060613          	addi	a2,a2,-32 # ffffffffc0206e00 <default_pmm_manager+0x7b8>
ffffffffc0204e28:	85a6                	mv	a1,s1
ffffffffc0204e2a:	854a                	mv	a0,s2
ffffffffc0204e2c:	0bc000ef          	jal	ra,ffffffffc0204ee8 <printfmt>
ffffffffc0204e30:	bb41                	j	ffffffffc0204bc0 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0204e32:	00002417          	auipc	s0,0x2
ffffffffc0204e36:	fc640413          	addi	s0,s0,-58 # ffffffffc0206df8 <default_pmm_manager+0x7b0>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0204e3a:	85e2                	mv	a1,s8
ffffffffc0204e3c:	8522                	mv	a0,s0
ffffffffc0204e3e:	e43e                	sd	a5,8(sp)
ffffffffc0204e40:	c2bff0ef          	jal	ra,ffffffffc0204a6a <strnlen>
ffffffffc0204e44:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0204e48:	01b05b63          	blez	s11,ffffffffc0204e5e <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc0204e4c:	67a2                	ld	a5,8(sp)
ffffffffc0204e4e:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0204e52:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0204e54:	85a6                	mv	a1,s1
ffffffffc0204e56:	8552                	mv	a0,s4
ffffffffc0204e58:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0204e5a:	fe0d9ce3          	bnez	s11,ffffffffc0204e52 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0204e5e:	00044783          	lbu	a5,0(s0)
ffffffffc0204e62:	00140a13          	addi	s4,s0,1
ffffffffc0204e66:	0007851b          	sext.w	a0,a5
ffffffffc0204e6a:	d3a5                	beqz	a5,ffffffffc0204dca <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0204e6c:	05e00413          	li	s0,94
ffffffffc0204e70:	bf39                	j	ffffffffc0204d8e <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc0204e72:	000a2403          	lw	s0,0(s4)
ffffffffc0204e76:	b7ad                	j	ffffffffc0204de0 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc0204e78:	000a6603          	lwu	a2,0(s4)
ffffffffc0204e7c:	46a1                	li	a3,8
ffffffffc0204e7e:	8a2e                	mv	s4,a1
ffffffffc0204e80:	bdb1                	j	ffffffffc0204cdc <vprintfmt+0x156>
ffffffffc0204e82:	000a6603          	lwu	a2,0(s4)
ffffffffc0204e86:	46a9                	li	a3,10
ffffffffc0204e88:	8a2e                	mv	s4,a1
ffffffffc0204e8a:	bd89                	j	ffffffffc0204cdc <vprintfmt+0x156>
ffffffffc0204e8c:	000a6603          	lwu	a2,0(s4)
ffffffffc0204e90:	46c1                	li	a3,16
ffffffffc0204e92:	8a2e                	mv	s4,a1
ffffffffc0204e94:	b5a1                	j	ffffffffc0204cdc <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc0204e96:	9902                	jalr	s2
ffffffffc0204e98:	bf09                	j	ffffffffc0204daa <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc0204e9a:	85a6                	mv	a1,s1
ffffffffc0204e9c:	02d00513          	li	a0,45
ffffffffc0204ea0:	e03e                	sd	a5,0(sp)
ffffffffc0204ea2:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0204ea4:	6782                	ld	a5,0(sp)
ffffffffc0204ea6:	8a66                	mv	s4,s9
ffffffffc0204ea8:	40800633          	neg	a2,s0
ffffffffc0204eac:	46a9                	li	a3,10
ffffffffc0204eae:	b53d                	j	ffffffffc0204cdc <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc0204eb0:	03b05163          	blez	s11,ffffffffc0204ed2 <vprintfmt+0x34c>
ffffffffc0204eb4:	02d00693          	li	a3,45
ffffffffc0204eb8:	f6d79de3          	bne	a5,a3,ffffffffc0204e32 <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc0204ebc:	00002417          	auipc	s0,0x2
ffffffffc0204ec0:	f3c40413          	addi	s0,s0,-196 # ffffffffc0206df8 <default_pmm_manager+0x7b0>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0204ec4:	02800793          	li	a5,40
ffffffffc0204ec8:	02800513          	li	a0,40
ffffffffc0204ecc:	00140a13          	addi	s4,s0,1
ffffffffc0204ed0:	bd6d                	j	ffffffffc0204d8a <vprintfmt+0x204>
ffffffffc0204ed2:	00002a17          	auipc	s4,0x2
ffffffffc0204ed6:	f27a0a13          	addi	s4,s4,-217 # ffffffffc0206df9 <default_pmm_manager+0x7b1>
ffffffffc0204eda:	02800513          	li	a0,40
ffffffffc0204ede:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0204ee2:	05e00413          	li	s0,94
ffffffffc0204ee6:	b565                	j	ffffffffc0204d8e <vprintfmt+0x208>

ffffffffc0204ee8 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0204ee8:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0204eea:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0204eee:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0204ef0:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0204ef2:	ec06                	sd	ra,24(sp)
ffffffffc0204ef4:	f83a                	sd	a4,48(sp)
ffffffffc0204ef6:	fc3e                	sd	a5,56(sp)
ffffffffc0204ef8:	e0c2                	sd	a6,64(sp)
ffffffffc0204efa:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0204efc:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0204efe:	c89ff0ef          	jal	ra,ffffffffc0204b86 <vprintfmt>
}
ffffffffc0204f02:	60e2                	ld	ra,24(sp)
ffffffffc0204f04:	6161                	addi	sp,sp,80
ffffffffc0204f06:	8082                	ret

ffffffffc0204f08 <hash32>:
 *
 * High bits are more random, so we use them.
 * */
uint32_t
hash32(uint32_t val, unsigned int bits) {
    uint32_t hash = val * GOLDEN_RATIO_PRIME_32;
ffffffffc0204f08:	9e3707b7          	lui	a5,0x9e370
ffffffffc0204f0c:	2785                	addiw	a5,a5,1
ffffffffc0204f0e:	02a7853b          	mulw	a0,a5,a0
    return (hash >> (32 - bits));
ffffffffc0204f12:	02000793          	li	a5,32
ffffffffc0204f16:	9f8d                	subw	a5,a5,a1
}
ffffffffc0204f18:	00f5553b          	srlw	a0,a0,a5
ffffffffc0204f1c:	8082                	ret
