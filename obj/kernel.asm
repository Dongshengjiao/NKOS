
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:

    .section .text,"ax",%progbits
    .globl kern_entry
kern_entry:
    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200000:	c02052b7          	lui	t0,0xc0205
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc0200004:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200008:	01e31313          	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc020000c:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12
ffffffffc0200010:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc0200014:	fff0031b          	addiw	t1,zero,-1
ffffffffc0200018:	03f31313          	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc020001c:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc0200020:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200024:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc0200028:	c0205137          	lui	sp,0xc0205

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc020002c:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200030:	03628293          	addi	t0,t0,54 # ffffffffc0200036 <kern_init>
    jr t0
ffffffffc0200034:	8282                	jr	t0

ffffffffc0200036 <kern_init>:
void grade_backtrace(void);


int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc0200036:	00006517          	auipc	a0,0x6
ffffffffc020003a:	fda50513          	addi	a0,a0,-38 # ffffffffc0206010 <edata>
ffffffffc020003e:	00006617          	auipc	a2,0x6
ffffffffc0200042:	43260613          	addi	a2,a2,1074 # ffffffffc0206470 <end>
int kern_init(void) {
ffffffffc0200046:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc0200048:	8e09                	sub	a2,a2,a0
ffffffffc020004a:	4581                	li	a1,0
int kern_init(void) {
ffffffffc020004c:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc020004e:	301010ef          	jal	ra,ffffffffc0201b4e <memset>
    cons_init();  // init the console
ffffffffc0200052:	3fa000ef          	jal	ra,ffffffffc020044c <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc0200056:	00002517          	auipc	a0,0x2
ffffffffc020005a:	b0a50513          	addi	a0,a0,-1270 # ffffffffc0201b60 <etext>
ffffffffc020005e:	08c000ef          	jal	ra,ffffffffc02000ea <cputs>

    print_kerninfo();
ffffffffc0200062:	0d8000ef          	jal	ra,ffffffffc020013a <print_kerninfo>

    // grade_backtrace();
    idt_init();  // init interrupt descriptor table
ffffffffc0200066:	400000ef          	jal	ra,ffffffffc0200466 <idt_init>
    pmm_init();  // init physical memory management
ffffffffc020006a:	3bc010ef          	jal	ra,ffffffffc0201426 <pmm_init>

    clock_init();   // init clock interrupt
ffffffffc020006e:	39a000ef          	jal	ra,ffffffffc0200408 <clock_init>
    intr_enable();  // enable irq interrupt
ffffffffc0200072:	3e8000ef          	jal	ra,ffffffffc020045a <intr_enable>


    /* do nothing */
    while (1)
        ;
ffffffffc0200076:	a001                	j	ffffffffc0200076 <kern_init+0x40>

ffffffffc0200078 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc0200078:	1141                	addi	sp,sp,-16
ffffffffc020007a:	e022                	sd	s0,0(sp)
ffffffffc020007c:	e406                	sd	ra,8(sp)
ffffffffc020007e:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc0200080:	3ce000ef          	jal	ra,ffffffffc020044e <cons_putc>
    (*cnt) ++;
ffffffffc0200084:	401c                	lw	a5,0(s0)
}
ffffffffc0200086:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc0200088:	2785                	addiw	a5,a5,1
ffffffffc020008a:	c01c                	sw	a5,0(s0)
}
ffffffffc020008c:	6402                	ld	s0,0(sp)
ffffffffc020008e:	0141                	addi	sp,sp,16
ffffffffc0200090:	8082                	ret

ffffffffc0200092 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc0200092:	1101                	addi	sp,sp,-32
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200094:	86ae                	mv	a3,a1
ffffffffc0200096:	862a                	mv	a2,a0
ffffffffc0200098:	006c                	addi	a1,sp,12
ffffffffc020009a:	00000517          	auipc	a0,0x0
ffffffffc020009e:	fde50513          	addi	a0,a0,-34 # ffffffffc0200078 <cputch>
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000a2:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc02000a4:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000a6:	59a010ef          	jal	ra,ffffffffc0201640 <vprintfmt>
    return cnt;
}
ffffffffc02000aa:	60e2                	ld	ra,24(sp)
ffffffffc02000ac:	4532                	lw	a0,12(sp)
ffffffffc02000ae:	6105                	addi	sp,sp,32
ffffffffc02000b0:	8082                	ret

ffffffffc02000b2 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc02000b2:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc02000b4:	02810313          	addi	t1,sp,40 # ffffffffc0205028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc02000b8:	f42e                	sd	a1,40(sp)
ffffffffc02000ba:	f832                	sd	a2,48(sp)
ffffffffc02000bc:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000be:	862a                	mv	a2,a0
ffffffffc02000c0:	004c                	addi	a1,sp,4
ffffffffc02000c2:	00000517          	auipc	a0,0x0
ffffffffc02000c6:	fb650513          	addi	a0,a0,-74 # ffffffffc0200078 <cputch>
ffffffffc02000ca:	869a                	mv	a3,t1
cprintf(const char *fmt, ...) {
ffffffffc02000cc:	ec06                	sd	ra,24(sp)
ffffffffc02000ce:	e0ba                	sd	a4,64(sp)
ffffffffc02000d0:	e4be                	sd	a5,72(sp)
ffffffffc02000d2:	e8c2                	sd	a6,80(sp)
ffffffffc02000d4:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc02000d6:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc02000d8:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000da:	566010ef          	jal	ra,ffffffffc0201640 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc02000de:	60e2                	ld	ra,24(sp)
ffffffffc02000e0:	4512                	lw	a0,4(sp)
ffffffffc02000e2:	6125                	addi	sp,sp,96
ffffffffc02000e4:	8082                	ret

ffffffffc02000e6 <cputchar>:

/* cputchar - writes a single character to stdout */
void
cputchar(int c) {
    cons_putc(c);
ffffffffc02000e6:	3680006f          	j	ffffffffc020044e <cons_putc>

ffffffffc02000ea <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc02000ea:	1101                	addi	sp,sp,-32
ffffffffc02000ec:	e822                	sd	s0,16(sp)
ffffffffc02000ee:	ec06                	sd	ra,24(sp)
ffffffffc02000f0:	e426                	sd	s1,8(sp)
ffffffffc02000f2:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc02000f4:	00054503          	lbu	a0,0(a0)
ffffffffc02000f8:	c51d                	beqz	a0,ffffffffc0200126 <cputs+0x3c>
ffffffffc02000fa:	0405                	addi	s0,s0,1
ffffffffc02000fc:	4485                	li	s1,1
ffffffffc02000fe:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc0200100:	34e000ef          	jal	ra,ffffffffc020044e <cons_putc>
    (*cnt) ++;
ffffffffc0200104:	008487bb          	addw	a5,s1,s0
    while ((c = *str ++) != '\0') {
ffffffffc0200108:	0405                	addi	s0,s0,1
ffffffffc020010a:	fff44503          	lbu	a0,-1(s0)
ffffffffc020010e:	f96d                	bnez	a0,ffffffffc0200100 <cputs+0x16>
ffffffffc0200110:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc0200114:	4529                	li	a0,10
ffffffffc0200116:	338000ef          	jal	ra,ffffffffc020044e <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc020011a:	8522                	mv	a0,s0
ffffffffc020011c:	60e2                	ld	ra,24(sp)
ffffffffc020011e:	6442                	ld	s0,16(sp)
ffffffffc0200120:	64a2                	ld	s1,8(sp)
ffffffffc0200122:	6105                	addi	sp,sp,32
ffffffffc0200124:	8082                	ret
    while ((c = *str ++) != '\0') {
ffffffffc0200126:	4405                	li	s0,1
ffffffffc0200128:	b7f5                	j	ffffffffc0200114 <cputs+0x2a>

ffffffffc020012a <getchar>:

/* getchar - reads a single non-zero character from stdin */
int
getchar(void) {
ffffffffc020012a:	1141                	addi	sp,sp,-16
ffffffffc020012c:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc020012e:	328000ef          	jal	ra,ffffffffc0200456 <cons_getc>
ffffffffc0200132:	dd75                	beqz	a0,ffffffffc020012e <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc0200134:	60a2                	ld	ra,8(sp)
ffffffffc0200136:	0141                	addi	sp,sp,16
ffffffffc0200138:	8082                	ret

ffffffffc020013a <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc020013a:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc020013c:	00002517          	auipc	a0,0x2
ffffffffc0200140:	a7450513          	addi	a0,a0,-1420 # ffffffffc0201bb0 <etext+0x50>
void print_kerninfo(void) {
ffffffffc0200144:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200146:	f6dff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", kern_init);
ffffffffc020014a:	00000597          	auipc	a1,0x0
ffffffffc020014e:	eec58593          	addi	a1,a1,-276 # ffffffffc0200036 <kern_init>
ffffffffc0200152:	00002517          	auipc	a0,0x2
ffffffffc0200156:	a7e50513          	addi	a0,a0,-1410 # ffffffffc0201bd0 <etext+0x70>
ffffffffc020015a:	f59ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc020015e:	00002597          	auipc	a1,0x2
ffffffffc0200162:	a0258593          	addi	a1,a1,-1534 # ffffffffc0201b60 <etext>
ffffffffc0200166:	00002517          	auipc	a0,0x2
ffffffffc020016a:	a8a50513          	addi	a0,a0,-1398 # ffffffffc0201bf0 <etext+0x90>
ffffffffc020016e:	f45ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc0200172:	00006597          	auipc	a1,0x6
ffffffffc0200176:	e9e58593          	addi	a1,a1,-354 # ffffffffc0206010 <edata>
ffffffffc020017a:	00002517          	auipc	a0,0x2
ffffffffc020017e:	a9650513          	addi	a0,a0,-1386 # ffffffffc0201c10 <etext+0xb0>
ffffffffc0200182:	f31ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc0200186:	00006597          	auipc	a1,0x6
ffffffffc020018a:	2ea58593          	addi	a1,a1,746 # ffffffffc0206470 <end>
ffffffffc020018e:	00002517          	auipc	a0,0x2
ffffffffc0200192:	aa250513          	addi	a0,a0,-1374 # ffffffffc0201c30 <etext+0xd0>
ffffffffc0200196:	f1dff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc020019a:	00006597          	auipc	a1,0x6
ffffffffc020019e:	6d558593          	addi	a1,a1,1749 # ffffffffc020686f <end+0x3ff>
ffffffffc02001a2:	00000797          	auipc	a5,0x0
ffffffffc02001a6:	e9478793          	addi	a5,a5,-364 # ffffffffc0200036 <kern_init>
ffffffffc02001aa:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001ae:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02001b2:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001b4:	3ff5f593          	andi	a1,a1,1023
ffffffffc02001b8:	95be                	add	a1,a1,a5
ffffffffc02001ba:	85a9                	srai	a1,a1,0xa
ffffffffc02001bc:	00002517          	auipc	a0,0x2
ffffffffc02001c0:	a9450513          	addi	a0,a0,-1388 # ffffffffc0201c50 <etext+0xf0>
}
ffffffffc02001c4:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001c6:	eedff06f          	j	ffffffffc02000b2 <cprintf>

ffffffffc02001ca <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc02001ca:	1141                	addi	sp,sp,-16

    panic("Not Implemented!");
ffffffffc02001cc:	00002617          	auipc	a2,0x2
ffffffffc02001d0:	9b460613          	addi	a2,a2,-1612 # ffffffffc0201b80 <etext+0x20>
ffffffffc02001d4:	04e00593          	li	a1,78
ffffffffc02001d8:	00002517          	auipc	a0,0x2
ffffffffc02001dc:	9c050513          	addi	a0,a0,-1600 # ffffffffc0201b98 <etext+0x38>
void print_stackframe(void) {
ffffffffc02001e0:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc02001e2:	1c6000ef          	jal	ra,ffffffffc02003a8 <__panic>

ffffffffc02001e6 <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02001e6:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02001e8:	00002617          	auipc	a2,0x2
ffffffffc02001ec:	b7860613          	addi	a2,a2,-1160 # ffffffffc0201d60 <commands+0xe0>
ffffffffc02001f0:	00002597          	auipc	a1,0x2
ffffffffc02001f4:	b9058593          	addi	a1,a1,-1136 # ffffffffc0201d80 <commands+0x100>
ffffffffc02001f8:	00002517          	auipc	a0,0x2
ffffffffc02001fc:	b9050513          	addi	a0,a0,-1136 # ffffffffc0201d88 <commands+0x108>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200200:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200202:	eb1ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc0200206:	00002617          	auipc	a2,0x2
ffffffffc020020a:	b9260613          	addi	a2,a2,-1134 # ffffffffc0201d98 <commands+0x118>
ffffffffc020020e:	00002597          	auipc	a1,0x2
ffffffffc0200212:	bb258593          	addi	a1,a1,-1102 # ffffffffc0201dc0 <commands+0x140>
ffffffffc0200216:	00002517          	auipc	a0,0x2
ffffffffc020021a:	b7250513          	addi	a0,a0,-1166 # ffffffffc0201d88 <commands+0x108>
ffffffffc020021e:	e95ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc0200222:	00002617          	auipc	a2,0x2
ffffffffc0200226:	bae60613          	addi	a2,a2,-1106 # ffffffffc0201dd0 <commands+0x150>
ffffffffc020022a:	00002597          	auipc	a1,0x2
ffffffffc020022e:	bc658593          	addi	a1,a1,-1082 # ffffffffc0201df0 <commands+0x170>
ffffffffc0200232:	00002517          	auipc	a0,0x2
ffffffffc0200236:	b5650513          	addi	a0,a0,-1194 # ffffffffc0201d88 <commands+0x108>
ffffffffc020023a:	e79ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    }
    return 0;
}
ffffffffc020023e:	60a2                	ld	ra,8(sp)
ffffffffc0200240:	4501                	li	a0,0
ffffffffc0200242:	0141                	addi	sp,sp,16
ffffffffc0200244:	8082                	ret

ffffffffc0200246 <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200246:	1141                	addi	sp,sp,-16
ffffffffc0200248:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc020024a:	ef1ff0ef          	jal	ra,ffffffffc020013a <print_kerninfo>
    return 0;
}
ffffffffc020024e:	60a2                	ld	ra,8(sp)
ffffffffc0200250:	4501                	li	a0,0
ffffffffc0200252:	0141                	addi	sp,sp,16
ffffffffc0200254:	8082                	ret

ffffffffc0200256 <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200256:	1141                	addi	sp,sp,-16
ffffffffc0200258:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc020025a:	f71ff0ef          	jal	ra,ffffffffc02001ca <print_stackframe>
    return 0;
}
ffffffffc020025e:	60a2                	ld	ra,8(sp)
ffffffffc0200260:	4501                	li	a0,0
ffffffffc0200262:	0141                	addi	sp,sp,16
ffffffffc0200264:	8082                	ret

ffffffffc0200266 <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc0200266:	7115                	addi	sp,sp,-224
ffffffffc0200268:	e962                	sd	s8,144(sp)
ffffffffc020026a:	8c2a                	mv	s8,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020026c:	00002517          	auipc	a0,0x2
ffffffffc0200270:	a5c50513          	addi	a0,a0,-1444 # ffffffffc0201cc8 <commands+0x48>
kmonitor(struct trapframe *tf) {
ffffffffc0200274:	ed86                	sd	ra,216(sp)
ffffffffc0200276:	e9a2                	sd	s0,208(sp)
ffffffffc0200278:	e5a6                	sd	s1,200(sp)
ffffffffc020027a:	e1ca                	sd	s2,192(sp)
ffffffffc020027c:	fd4e                	sd	s3,184(sp)
ffffffffc020027e:	f952                	sd	s4,176(sp)
ffffffffc0200280:	f556                	sd	s5,168(sp)
ffffffffc0200282:	f15a                	sd	s6,160(sp)
ffffffffc0200284:	ed5e                	sd	s7,152(sp)
ffffffffc0200286:	e566                	sd	s9,136(sp)
ffffffffc0200288:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020028a:	e29ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc020028e:	00002517          	auipc	a0,0x2
ffffffffc0200292:	a6250513          	addi	a0,a0,-1438 # ffffffffc0201cf0 <commands+0x70>
ffffffffc0200296:	e1dff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    if (tf != NULL) {
ffffffffc020029a:	000c0563          	beqz	s8,ffffffffc02002a4 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc020029e:	8562                	mv	a0,s8
ffffffffc02002a0:	3a6000ef          	jal	ra,ffffffffc0200646 <print_trapframe>
ffffffffc02002a4:	00002c97          	auipc	s9,0x2
ffffffffc02002a8:	9dcc8c93          	addi	s9,s9,-1572 # ffffffffc0201c80 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002ac:	00002997          	auipc	s3,0x2
ffffffffc02002b0:	a6c98993          	addi	s3,s3,-1428 # ffffffffc0201d18 <commands+0x98>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002b4:	00002917          	auipc	s2,0x2
ffffffffc02002b8:	a6c90913          	addi	s2,s2,-1428 # ffffffffc0201d20 <commands+0xa0>
        if (argc == MAXARGS - 1) {
ffffffffc02002bc:	4a3d                	li	s4,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02002be:	00002b17          	auipc	s6,0x2
ffffffffc02002c2:	a6ab0b13          	addi	s6,s6,-1430 # ffffffffc0201d28 <commands+0xa8>
    if (argc == 0) {
ffffffffc02002c6:	00002a97          	auipc	s5,0x2
ffffffffc02002ca:	abaa8a93          	addi	s5,s5,-1350 # ffffffffc0201d80 <commands+0x100>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002ce:	4b8d                	li	s7,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002d0:	854e                	mv	a0,s3
ffffffffc02002d2:	6fa010ef          	jal	ra,ffffffffc02019cc <readline>
ffffffffc02002d6:	842a                	mv	s0,a0
ffffffffc02002d8:	dd65                	beqz	a0,ffffffffc02002d0 <kmonitor+0x6a>
ffffffffc02002da:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc02002de:	4481                	li	s1,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002e0:	c999                	beqz	a1,ffffffffc02002f6 <kmonitor+0x90>
ffffffffc02002e2:	854a                	mv	a0,s2
ffffffffc02002e4:	04d010ef          	jal	ra,ffffffffc0201b30 <strchr>
ffffffffc02002e8:	c925                	beqz	a0,ffffffffc0200358 <kmonitor+0xf2>
            *buf ++ = '\0';
ffffffffc02002ea:	00144583          	lbu	a1,1(s0)
ffffffffc02002ee:	00040023          	sb	zero,0(s0)
ffffffffc02002f2:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002f4:	f5fd                	bnez	a1,ffffffffc02002e2 <kmonitor+0x7c>
    if (argc == 0) {
ffffffffc02002f6:	dce9                	beqz	s1,ffffffffc02002d0 <kmonitor+0x6a>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02002f8:	6582                	ld	a1,0(sp)
ffffffffc02002fa:	00002d17          	auipc	s10,0x2
ffffffffc02002fe:	986d0d13          	addi	s10,s10,-1658 # ffffffffc0201c80 <commands>
    if (argc == 0) {
ffffffffc0200302:	8556                	mv	a0,s5
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200304:	4401                	li	s0,0
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200306:	0d61                	addi	s10,s10,24
ffffffffc0200308:	7fe010ef          	jal	ra,ffffffffc0201b06 <strcmp>
ffffffffc020030c:	c919                	beqz	a0,ffffffffc0200322 <kmonitor+0xbc>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020030e:	2405                	addiw	s0,s0,1
ffffffffc0200310:	09740463          	beq	s0,s7,ffffffffc0200398 <kmonitor+0x132>
ffffffffc0200314:	000d3503          	ld	a0,0(s10)
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200318:	6582                	ld	a1,0(sp)
ffffffffc020031a:	0d61                	addi	s10,s10,24
ffffffffc020031c:	7ea010ef          	jal	ra,ffffffffc0201b06 <strcmp>
ffffffffc0200320:	f57d                	bnez	a0,ffffffffc020030e <kmonitor+0xa8>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc0200322:	00141793          	slli	a5,s0,0x1
ffffffffc0200326:	97a2                	add	a5,a5,s0
ffffffffc0200328:	078e                	slli	a5,a5,0x3
ffffffffc020032a:	97e6                	add	a5,a5,s9
ffffffffc020032c:	6b9c                	ld	a5,16(a5)
ffffffffc020032e:	8662                	mv	a2,s8
ffffffffc0200330:	002c                	addi	a1,sp,8
ffffffffc0200332:	fff4851b          	addiw	a0,s1,-1
ffffffffc0200336:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc0200338:	f8055ce3          	bgez	a0,ffffffffc02002d0 <kmonitor+0x6a>
}
ffffffffc020033c:	60ee                	ld	ra,216(sp)
ffffffffc020033e:	644e                	ld	s0,208(sp)
ffffffffc0200340:	64ae                	ld	s1,200(sp)
ffffffffc0200342:	690e                	ld	s2,192(sp)
ffffffffc0200344:	79ea                	ld	s3,184(sp)
ffffffffc0200346:	7a4a                	ld	s4,176(sp)
ffffffffc0200348:	7aaa                	ld	s5,168(sp)
ffffffffc020034a:	7b0a                	ld	s6,160(sp)
ffffffffc020034c:	6bea                	ld	s7,152(sp)
ffffffffc020034e:	6c4a                	ld	s8,144(sp)
ffffffffc0200350:	6caa                	ld	s9,136(sp)
ffffffffc0200352:	6d0a                	ld	s10,128(sp)
ffffffffc0200354:	612d                	addi	sp,sp,224
ffffffffc0200356:	8082                	ret
        if (*buf == '\0') {
ffffffffc0200358:	00044783          	lbu	a5,0(s0)
ffffffffc020035c:	dfc9                	beqz	a5,ffffffffc02002f6 <kmonitor+0x90>
        if (argc == MAXARGS - 1) {
ffffffffc020035e:	03448863          	beq	s1,s4,ffffffffc020038e <kmonitor+0x128>
        argv[argc ++] = buf;
ffffffffc0200362:	00349793          	slli	a5,s1,0x3
ffffffffc0200366:	0118                	addi	a4,sp,128
ffffffffc0200368:	97ba                	add	a5,a5,a4
ffffffffc020036a:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc020036e:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc0200372:	2485                	addiw	s1,s1,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200374:	e591                	bnez	a1,ffffffffc0200380 <kmonitor+0x11a>
ffffffffc0200376:	b749                	j	ffffffffc02002f8 <kmonitor+0x92>
            buf ++;
ffffffffc0200378:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc020037a:	00044583          	lbu	a1,0(s0)
ffffffffc020037e:	ddad                	beqz	a1,ffffffffc02002f8 <kmonitor+0x92>
ffffffffc0200380:	854a                	mv	a0,s2
ffffffffc0200382:	7ae010ef          	jal	ra,ffffffffc0201b30 <strchr>
ffffffffc0200386:	d96d                	beqz	a0,ffffffffc0200378 <kmonitor+0x112>
ffffffffc0200388:	00044583          	lbu	a1,0(s0)
ffffffffc020038c:	bf91                	j	ffffffffc02002e0 <kmonitor+0x7a>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc020038e:	45c1                	li	a1,16
ffffffffc0200390:	855a                	mv	a0,s6
ffffffffc0200392:	d21ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc0200396:	b7f1                	j	ffffffffc0200362 <kmonitor+0xfc>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc0200398:	6582                	ld	a1,0(sp)
ffffffffc020039a:	00002517          	auipc	a0,0x2
ffffffffc020039e:	9ae50513          	addi	a0,a0,-1618 # ffffffffc0201d48 <commands+0xc8>
ffffffffc02003a2:	d11ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    return 0;
ffffffffc02003a6:	b72d                	j	ffffffffc02002d0 <kmonitor+0x6a>

ffffffffc02003a8 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02003a8:	00006317          	auipc	t1,0x6
ffffffffc02003ac:	06830313          	addi	t1,t1,104 # ffffffffc0206410 <is_panic>
ffffffffc02003b0:	00032303          	lw	t1,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc02003b4:	715d                	addi	sp,sp,-80
ffffffffc02003b6:	ec06                	sd	ra,24(sp)
ffffffffc02003b8:	e822                	sd	s0,16(sp)
ffffffffc02003ba:	f436                	sd	a3,40(sp)
ffffffffc02003bc:	f83a                	sd	a4,48(sp)
ffffffffc02003be:	fc3e                	sd	a5,56(sp)
ffffffffc02003c0:	e0c2                	sd	a6,64(sp)
ffffffffc02003c2:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02003c4:	02031c63          	bnez	t1,ffffffffc02003fc <__panic+0x54>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc02003c8:	4785                	li	a5,1
ffffffffc02003ca:	8432                	mv	s0,a2
ffffffffc02003cc:	00006717          	auipc	a4,0x6
ffffffffc02003d0:	04f72223          	sw	a5,68(a4) # ffffffffc0206410 <is_panic>

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02003d4:	862e                	mv	a2,a1
    va_start(ap, fmt);
ffffffffc02003d6:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02003d8:	85aa                	mv	a1,a0
ffffffffc02003da:	00002517          	auipc	a0,0x2
ffffffffc02003de:	a2650513          	addi	a0,a0,-1498 # ffffffffc0201e00 <commands+0x180>
    va_start(ap, fmt);
ffffffffc02003e2:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02003e4:	ccfff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    vcprintf(fmt, ap);
ffffffffc02003e8:	65a2                	ld	a1,8(sp)
ffffffffc02003ea:	8522                	mv	a0,s0
ffffffffc02003ec:	ca7ff0ef          	jal	ra,ffffffffc0200092 <vcprintf>
    cprintf("\n");
ffffffffc02003f0:	00002517          	auipc	a0,0x2
ffffffffc02003f4:	88850513          	addi	a0,a0,-1912 # ffffffffc0201c78 <etext+0x118>
ffffffffc02003f8:	cbbff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc02003fc:	064000ef          	jal	ra,ffffffffc0200460 <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc0200400:	4501                	li	a0,0
ffffffffc0200402:	e65ff0ef          	jal	ra,ffffffffc0200266 <kmonitor>
ffffffffc0200406:	bfed                	j	ffffffffc0200400 <__panic+0x58>

ffffffffc0200408 <clock_init>:

/* *
 * clock_init - initialize 8253 clock to interrupt 100 times per second,
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
ffffffffc0200408:	1141                	addi	sp,sp,-16
ffffffffc020040a:	e406                	sd	ra,8(sp)
    // enable timer interrupt in sie
    set_csr(sie, MIP_STIP);
ffffffffc020040c:	02000793          	li	a5,32
ffffffffc0200410:	1047a7f3          	csrrs	a5,sie,a5
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200414:	c0102573          	rdtime	a0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200418:	67e1                	lui	a5,0x18
ffffffffc020041a:	6a078793          	addi	a5,a5,1696 # 186a0 <BASE_ADDRESS-0xffffffffc01e7960>
ffffffffc020041e:	953e                	add	a0,a0,a5
ffffffffc0200420:	686010ef          	jal	ra,ffffffffc0201aa6 <sbi_set_timer>
}
ffffffffc0200424:	60a2                	ld	ra,8(sp)
    ticks = 0;
ffffffffc0200426:	00006797          	auipc	a5,0x6
ffffffffc020042a:	0007b523          	sd	zero,10(a5) # ffffffffc0206430 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc020042e:	00002517          	auipc	a0,0x2
ffffffffc0200432:	9f250513          	addi	a0,a0,-1550 # ffffffffc0201e20 <commands+0x1a0>
}
ffffffffc0200436:	0141                	addi	sp,sp,16
    cprintf("++ setup timer interrupts\n");
ffffffffc0200438:	c7bff06f          	j	ffffffffc02000b2 <cprintf>

ffffffffc020043c <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc020043c:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200440:	67e1                	lui	a5,0x18
ffffffffc0200442:	6a078793          	addi	a5,a5,1696 # 186a0 <BASE_ADDRESS-0xffffffffc01e7960>
ffffffffc0200446:	953e                	add	a0,a0,a5
ffffffffc0200448:	65e0106f          	j	ffffffffc0201aa6 <sbi_set_timer>

ffffffffc020044c <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc020044c:	8082                	ret

ffffffffc020044e <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc020044e:	0ff57513          	andi	a0,a0,255
ffffffffc0200452:	6380106f          	j	ffffffffc0201a8a <sbi_console_putchar>

ffffffffc0200456 <cons_getc>:
 * cons_getc - return the next input character from console,
 * or 0 if none waiting.
 * */
int cons_getc(void) {
    int c = 0;
    c = sbi_console_getchar();
ffffffffc0200456:	66c0106f          	j	ffffffffc0201ac2 <sbi_console_getchar>

ffffffffc020045a <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc020045a:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc020045e:	8082                	ret

ffffffffc0200460 <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200460:	100177f3          	csrrci	a5,sstatus,2
ffffffffc0200464:	8082                	ret

ffffffffc0200466 <idt_init>:
     */

    extern void __alltraps(void);
    /* Set sup0 scratch register to 0, indicating to exception vector
       that we are presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc0200466:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc020046a:	00000797          	auipc	a5,0x0
ffffffffc020046e:	39278793          	addi	a5,a5,914 # ffffffffc02007fc <__alltraps>
ffffffffc0200472:	10579073          	csrw	stvec,a5
}
ffffffffc0200476:	8082                	ret

ffffffffc0200478 <print_regs>:
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr) {
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200478:	610c                	ld	a1,0(a0)
void print_regs(struct pushregs *gpr) {
ffffffffc020047a:	1141                	addi	sp,sp,-16
ffffffffc020047c:	e022                	sd	s0,0(sp)
ffffffffc020047e:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200480:	00002517          	auipc	a0,0x2
ffffffffc0200484:	b4850513          	addi	a0,a0,-1208 # ffffffffc0201fc8 <commands+0x348>
void print_regs(struct pushregs *gpr) {
ffffffffc0200488:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020048a:	c29ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc020048e:	640c                	ld	a1,8(s0)
ffffffffc0200490:	00002517          	auipc	a0,0x2
ffffffffc0200494:	b5050513          	addi	a0,a0,-1200 # ffffffffc0201fe0 <commands+0x360>
ffffffffc0200498:	c1bff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc020049c:	680c                	ld	a1,16(s0)
ffffffffc020049e:	00002517          	auipc	a0,0x2
ffffffffc02004a2:	b5a50513          	addi	a0,a0,-1190 # ffffffffc0201ff8 <commands+0x378>
ffffffffc02004a6:	c0dff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc02004aa:	6c0c                	ld	a1,24(s0)
ffffffffc02004ac:	00002517          	auipc	a0,0x2
ffffffffc02004b0:	b6450513          	addi	a0,a0,-1180 # ffffffffc0202010 <commands+0x390>
ffffffffc02004b4:	bffff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc02004b8:	700c                	ld	a1,32(s0)
ffffffffc02004ba:	00002517          	auipc	a0,0x2
ffffffffc02004be:	b6e50513          	addi	a0,a0,-1170 # ffffffffc0202028 <commands+0x3a8>
ffffffffc02004c2:	bf1ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc02004c6:	740c                	ld	a1,40(s0)
ffffffffc02004c8:	00002517          	auipc	a0,0x2
ffffffffc02004cc:	b7850513          	addi	a0,a0,-1160 # ffffffffc0202040 <commands+0x3c0>
ffffffffc02004d0:	be3ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02004d4:	780c                	ld	a1,48(s0)
ffffffffc02004d6:	00002517          	auipc	a0,0x2
ffffffffc02004da:	b8250513          	addi	a0,a0,-1150 # ffffffffc0202058 <commands+0x3d8>
ffffffffc02004de:	bd5ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02004e2:	7c0c                	ld	a1,56(s0)
ffffffffc02004e4:	00002517          	auipc	a0,0x2
ffffffffc02004e8:	b8c50513          	addi	a0,a0,-1140 # ffffffffc0202070 <commands+0x3f0>
ffffffffc02004ec:	bc7ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc02004f0:	602c                	ld	a1,64(s0)
ffffffffc02004f2:	00002517          	auipc	a0,0x2
ffffffffc02004f6:	b9650513          	addi	a0,a0,-1130 # ffffffffc0202088 <commands+0x408>
ffffffffc02004fa:	bb9ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc02004fe:	642c                	ld	a1,72(s0)
ffffffffc0200500:	00002517          	auipc	a0,0x2
ffffffffc0200504:	ba050513          	addi	a0,a0,-1120 # ffffffffc02020a0 <commands+0x420>
ffffffffc0200508:	babff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc020050c:	682c                	ld	a1,80(s0)
ffffffffc020050e:	00002517          	auipc	a0,0x2
ffffffffc0200512:	baa50513          	addi	a0,a0,-1110 # ffffffffc02020b8 <commands+0x438>
ffffffffc0200516:	b9dff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc020051a:	6c2c                	ld	a1,88(s0)
ffffffffc020051c:	00002517          	auipc	a0,0x2
ffffffffc0200520:	bb450513          	addi	a0,a0,-1100 # ffffffffc02020d0 <commands+0x450>
ffffffffc0200524:	b8fff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200528:	702c                	ld	a1,96(s0)
ffffffffc020052a:	00002517          	auipc	a0,0x2
ffffffffc020052e:	bbe50513          	addi	a0,a0,-1090 # ffffffffc02020e8 <commands+0x468>
ffffffffc0200532:	b81ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200536:	742c                	ld	a1,104(s0)
ffffffffc0200538:	00002517          	auipc	a0,0x2
ffffffffc020053c:	bc850513          	addi	a0,a0,-1080 # ffffffffc0202100 <commands+0x480>
ffffffffc0200540:	b73ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200544:	782c                	ld	a1,112(s0)
ffffffffc0200546:	00002517          	auipc	a0,0x2
ffffffffc020054a:	bd250513          	addi	a0,a0,-1070 # ffffffffc0202118 <commands+0x498>
ffffffffc020054e:	b65ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200552:	7c2c                	ld	a1,120(s0)
ffffffffc0200554:	00002517          	auipc	a0,0x2
ffffffffc0200558:	bdc50513          	addi	a0,a0,-1060 # ffffffffc0202130 <commands+0x4b0>
ffffffffc020055c:	b57ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200560:	604c                	ld	a1,128(s0)
ffffffffc0200562:	00002517          	auipc	a0,0x2
ffffffffc0200566:	be650513          	addi	a0,a0,-1050 # ffffffffc0202148 <commands+0x4c8>
ffffffffc020056a:	b49ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc020056e:	644c                	ld	a1,136(s0)
ffffffffc0200570:	00002517          	auipc	a0,0x2
ffffffffc0200574:	bf050513          	addi	a0,a0,-1040 # ffffffffc0202160 <commands+0x4e0>
ffffffffc0200578:	b3bff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc020057c:	684c                	ld	a1,144(s0)
ffffffffc020057e:	00002517          	auipc	a0,0x2
ffffffffc0200582:	bfa50513          	addi	a0,a0,-1030 # ffffffffc0202178 <commands+0x4f8>
ffffffffc0200586:	b2dff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc020058a:	6c4c                	ld	a1,152(s0)
ffffffffc020058c:	00002517          	auipc	a0,0x2
ffffffffc0200590:	c0450513          	addi	a0,a0,-1020 # ffffffffc0202190 <commands+0x510>
ffffffffc0200594:	b1fff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200598:	704c                	ld	a1,160(s0)
ffffffffc020059a:	00002517          	auipc	a0,0x2
ffffffffc020059e:	c0e50513          	addi	a0,a0,-1010 # ffffffffc02021a8 <commands+0x528>
ffffffffc02005a2:	b11ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc02005a6:	744c                	ld	a1,168(s0)
ffffffffc02005a8:	00002517          	auipc	a0,0x2
ffffffffc02005ac:	c1850513          	addi	a0,a0,-1000 # ffffffffc02021c0 <commands+0x540>
ffffffffc02005b0:	b03ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc02005b4:	784c                	ld	a1,176(s0)
ffffffffc02005b6:	00002517          	auipc	a0,0x2
ffffffffc02005ba:	c2250513          	addi	a0,a0,-990 # ffffffffc02021d8 <commands+0x558>
ffffffffc02005be:	af5ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc02005c2:	7c4c                	ld	a1,184(s0)
ffffffffc02005c4:	00002517          	auipc	a0,0x2
ffffffffc02005c8:	c2c50513          	addi	a0,a0,-980 # ffffffffc02021f0 <commands+0x570>
ffffffffc02005cc:	ae7ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc02005d0:	606c                	ld	a1,192(s0)
ffffffffc02005d2:	00002517          	auipc	a0,0x2
ffffffffc02005d6:	c3650513          	addi	a0,a0,-970 # ffffffffc0202208 <commands+0x588>
ffffffffc02005da:	ad9ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc02005de:	646c                	ld	a1,200(s0)
ffffffffc02005e0:	00002517          	auipc	a0,0x2
ffffffffc02005e4:	c4050513          	addi	a0,a0,-960 # ffffffffc0202220 <commands+0x5a0>
ffffffffc02005e8:	acbff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc02005ec:	686c                	ld	a1,208(s0)
ffffffffc02005ee:	00002517          	auipc	a0,0x2
ffffffffc02005f2:	c4a50513          	addi	a0,a0,-950 # ffffffffc0202238 <commands+0x5b8>
ffffffffc02005f6:	abdff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc02005fa:	6c6c                	ld	a1,216(s0)
ffffffffc02005fc:	00002517          	auipc	a0,0x2
ffffffffc0200600:	c5450513          	addi	a0,a0,-940 # ffffffffc0202250 <commands+0x5d0>
ffffffffc0200604:	aafff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200608:	706c                	ld	a1,224(s0)
ffffffffc020060a:	00002517          	auipc	a0,0x2
ffffffffc020060e:	c5e50513          	addi	a0,a0,-930 # ffffffffc0202268 <commands+0x5e8>
ffffffffc0200612:	aa1ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200616:	746c                	ld	a1,232(s0)
ffffffffc0200618:	00002517          	auipc	a0,0x2
ffffffffc020061c:	c6850513          	addi	a0,a0,-920 # ffffffffc0202280 <commands+0x600>
ffffffffc0200620:	a93ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200624:	786c                	ld	a1,240(s0)
ffffffffc0200626:	00002517          	auipc	a0,0x2
ffffffffc020062a:	c7250513          	addi	a0,a0,-910 # ffffffffc0202298 <commands+0x618>
ffffffffc020062e:	a85ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200632:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200634:	6402                	ld	s0,0(sp)
ffffffffc0200636:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200638:	00002517          	auipc	a0,0x2
ffffffffc020063c:	c7850513          	addi	a0,a0,-904 # ffffffffc02022b0 <commands+0x630>
}
ffffffffc0200640:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200642:	a71ff06f          	j	ffffffffc02000b2 <cprintf>

ffffffffc0200646 <print_trapframe>:
void print_trapframe(struct trapframe *tf) {
ffffffffc0200646:	1141                	addi	sp,sp,-16
ffffffffc0200648:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc020064a:	85aa                	mv	a1,a0
void print_trapframe(struct trapframe *tf) {
ffffffffc020064c:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc020064e:	00002517          	auipc	a0,0x2
ffffffffc0200652:	c7a50513          	addi	a0,a0,-902 # ffffffffc02022c8 <commands+0x648>
void print_trapframe(struct trapframe *tf) {
ffffffffc0200656:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200658:	a5bff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    print_regs(&tf->gpr);
ffffffffc020065c:	8522                	mv	a0,s0
ffffffffc020065e:	e1bff0ef          	jal	ra,ffffffffc0200478 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200662:	10043583          	ld	a1,256(s0)
ffffffffc0200666:	00002517          	auipc	a0,0x2
ffffffffc020066a:	c7a50513          	addi	a0,a0,-902 # ffffffffc02022e0 <commands+0x660>
ffffffffc020066e:	a45ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200672:	10843583          	ld	a1,264(s0)
ffffffffc0200676:	00002517          	auipc	a0,0x2
ffffffffc020067a:	c8250513          	addi	a0,a0,-894 # ffffffffc02022f8 <commands+0x678>
ffffffffc020067e:	a35ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc0200682:	11043583          	ld	a1,272(s0)
ffffffffc0200686:	00002517          	auipc	a0,0x2
ffffffffc020068a:	c8a50513          	addi	a0,a0,-886 # ffffffffc0202310 <commands+0x690>
ffffffffc020068e:	a25ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200692:	11843583          	ld	a1,280(s0)
}
ffffffffc0200696:	6402                	ld	s0,0(sp)
ffffffffc0200698:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc020069a:	00002517          	auipc	a0,0x2
ffffffffc020069e:	c8e50513          	addi	a0,a0,-882 # ffffffffc0202328 <commands+0x6a8>
}
ffffffffc02006a2:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc02006a4:	a0fff06f          	j	ffffffffc02000b2 <cprintf>

ffffffffc02006a8 <interrupt_handler>:

void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc02006a8:	11853783          	ld	a5,280(a0)
ffffffffc02006ac:	577d                	li	a4,-1
ffffffffc02006ae:	8305                	srli	a4,a4,0x1
ffffffffc02006b0:	8ff9                	and	a5,a5,a4
    switch (cause) {
ffffffffc02006b2:	472d                	li	a4,11
ffffffffc02006b4:	08f76563          	bltu	a4,a5,ffffffffc020073e <interrupt_handler+0x96>
ffffffffc02006b8:	00001717          	auipc	a4,0x1
ffffffffc02006bc:	78470713          	addi	a4,a4,1924 # ffffffffc0201e3c <commands+0x1bc>
ffffffffc02006c0:	078a                	slli	a5,a5,0x2
ffffffffc02006c2:	97ba                	add	a5,a5,a4
ffffffffc02006c4:	439c                	lw	a5,0(a5)
ffffffffc02006c6:	97ba                	add	a5,a5,a4
ffffffffc02006c8:	8782                	jr	a5
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
ffffffffc02006ca:	00002517          	auipc	a0,0x2
ffffffffc02006ce:	89650513          	addi	a0,a0,-1898 # ffffffffc0201f60 <commands+0x2e0>
ffffffffc02006d2:	9e1ff06f          	j	ffffffffc02000b2 <cprintf>
            cprintf("Hypervisor software interrupt\n");
ffffffffc02006d6:	00002517          	auipc	a0,0x2
ffffffffc02006da:	86a50513          	addi	a0,a0,-1942 # ffffffffc0201f40 <commands+0x2c0>
ffffffffc02006de:	9d5ff06f          	j	ffffffffc02000b2 <cprintf>
            cprintf("User software interrupt\n");
ffffffffc02006e2:	00002517          	auipc	a0,0x2
ffffffffc02006e6:	81e50513          	addi	a0,a0,-2018 # ffffffffc0201f00 <commands+0x280>
ffffffffc02006ea:	9c9ff06f          	j	ffffffffc02000b2 <cprintf>
            break;
        case IRQ_U_TIMER:
            cprintf("User Timer interrupt\n");
ffffffffc02006ee:	00002517          	auipc	a0,0x2
ffffffffc02006f2:	89250513          	addi	a0,a0,-1902 # ffffffffc0201f80 <commands+0x300>
ffffffffc02006f6:	9bdff06f          	j	ffffffffc02000b2 <cprintf>
void interrupt_handler(struct trapframe *tf) {
ffffffffc02006fa:	1141                	addi	sp,sp,-16
ffffffffc02006fc:	e406                	sd	ra,8(sp)
            // In fact, Call sbi_set_timer will clear STIP, or you can clear it
            // directly.
            // cprintf("Supervisor timer interrupt\n");
            // clear_csr(sip, SIP_STIP);
            
            clock_set_next_event();//发生这次时钟中断的时候，我们要设置下一次时钟中断
ffffffffc02006fe:	d3fff0ef          	jal	ra,ffffffffc020043c <clock_set_next_event>
            if (++ticks % TICK_NUM == 0) {
ffffffffc0200702:	00006797          	auipc	a5,0x6
ffffffffc0200706:	d2e78793          	addi	a5,a5,-722 # ffffffffc0206430 <ticks>
ffffffffc020070a:	639c                	ld	a5,0(a5)
ffffffffc020070c:	06400713          	li	a4,100
ffffffffc0200710:	0785                	addi	a5,a5,1
ffffffffc0200712:	02e7f733          	remu	a4,a5,a4
ffffffffc0200716:	00006697          	auipc	a3,0x6
ffffffffc020071a:	d0f6bd23          	sd	a5,-742(a3) # ffffffffc0206430 <ticks>
ffffffffc020071e:	c315                	beqz	a4,ffffffffc0200742 <interrupt_handler+0x9a>
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200720:	60a2                	ld	ra,8(sp)
ffffffffc0200722:	0141                	addi	sp,sp,16
ffffffffc0200724:	8082                	ret
            cprintf("Supervisor external interrupt\n");
ffffffffc0200726:	00002517          	auipc	a0,0x2
ffffffffc020072a:	88250513          	addi	a0,a0,-1918 # ffffffffc0201fa8 <commands+0x328>
ffffffffc020072e:	985ff06f          	j	ffffffffc02000b2 <cprintf>
            cprintf("Supervisor software interrupt\n");
ffffffffc0200732:	00001517          	auipc	a0,0x1
ffffffffc0200736:	7ee50513          	addi	a0,a0,2030 # ffffffffc0201f20 <commands+0x2a0>
ffffffffc020073a:	979ff06f          	j	ffffffffc02000b2 <cprintf>
            print_trapframe(tf);
ffffffffc020073e:	f09ff06f          	j	ffffffffc0200646 <print_trapframe>
}
ffffffffc0200742:	60a2                	ld	ra,8(sp)
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200744:	06400593          	li	a1,100
ffffffffc0200748:	00002517          	auipc	a0,0x2
ffffffffc020074c:	85050513          	addi	a0,a0,-1968 # ffffffffc0201f98 <commands+0x318>
}
ffffffffc0200750:	0141                	addi	sp,sp,16
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200752:	961ff06f          	j	ffffffffc02000b2 <cprintf>

ffffffffc0200756 <exception_handler>:

void exception_handler(struct trapframe *tf) {
    switch (tf->cause) {
ffffffffc0200756:	11853783          	ld	a5,280(a0)
ffffffffc020075a:	472d                	li	a4,11
ffffffffc020075c:	02f76863          	bltu	a4,a5,ffffffffc020078c <exception_handler+0x36>
ffffffffc0200760:	4705                	li	a4,1
ffffffffc0200762:	00f71733          	sll	a4,a4,a5
ffffffffc0200766:	6785                	lui	a5,0x1
ffffffffc0200768:	17cd                	addi	a5,a5,-13
ffffffffc020076a:	8ff9                	and	a5,a5,a4
ffffffffc020076c:	ef99                	bnez	a5,ffffffffc020078a <exception_handler+0x34>
void exception_handler(struct trapframe *tf) {
ffffffffc020076e:	1141                	addi	sp,sp,-16
ffffffffc0200770:	e022                	sd	s0,0(sp)
ffffffffc0200772:	e406                	sd	ra,8(sp)
ffffffffc0200774:	00877793          	andi	a5,a4,8
ffffffffc0200778:	842a                	mv	s0,a0
ffffffffc020077a:	e3b1                	bnez	a5,ffffffffc02007be <exception_handler+0x68>
ffffffffc020077c:	8b11                	andi	a4,a4,4
ffffffffc020077e:	eb09                	bnez	a4,ffffffffc0200790 <exception_handler+0x3a>
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200780:	6402                	ld	s0,0(sp)
ffffffffc0200782:	60a2                	ld	ra,8(sp)
ffffffffc0200784:	0141                	addi	sp,sp,16
            print_trapframe(tf);
ffffffffc0200786:	ec1ff06f          	j	ffffffffc0200646 <print_trapframe>
ffffffffc020078a:	8082                	ret
ffffffffc020078c:	ebbff06f          	j	ffffffffc0200646 <print_trapframe>
            cprintf("Exception type:Illegal instruction\n");
ffffffffc0200790:	00001517          	auipc	a0,0x1
ffffffffc0200794:	6e050513          	addi	a0,a0,1760 # ffffffffc0201e70 <commands+0x1f0>
ffffffffc0200798:	91bff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
            cprintf("Illegal instruction caught at 0x%08x\n", tf->epc);
ffffffffc020079c:	10843583          	ld	a1,264(s0)
ffffffffc02007a0:	00001517          	auipc	a0,0x1
ffffffffc02007a4:	6f850513          	addi	a0,a0,1784 # ffffffffc0201e98 <commands+0x218>
ffffffffc02007a8:	90bff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
            tf->epc += 4;
ffffffffc02007ac:	10843783          	ld	a5,264(s0)
}
ffffffffc02007b0:	60a2                	ld	ra,8(sp)
            tf->epc += 4;
ffffffffc02007b2:	0791                	addi	a5,a5,4
ffffffffc02007b4:	10f43423          	sd	a5,264(s0)
}
ffffffffc02007b8:	6402                	ld	s0,0(sp)
ffffffffc02007ba:	0141                	addi	sp,sp,16
ffffffffc02007bc:	8082                	ret
            cprintf("Exception type: breakpoint\n");
ffffffffc02007be:	00001517          	auipc	a0,0x1
ffffffffc02007c2:	70250513          	addi	a0,a0,1794 # ffffffffc0201ec0 <commands+0x240>
ffffffffc02007c6:	8edff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
            cprintf("Breakpoint caught at 0x%08x\n", tf->epc);
ffffffffc02007ca:	10843583          	ld	a1,264(s0)
ffffffffc02007ce:	00001517          	auipc	a0,0x1
ffffffffc02007d2:	71250513          	addi	a0,a0,1810 # ffffffffc0201ee0 <commands+0x260>
ffffffffc02007d6:	8ddff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
            tf->epc += 4;
ffffffffc02007da:	10843783          	ld	a5,264(s0)
}
ffffffffc02007de:	60a2                	ld	ra,8(sp)
            tf->epc += 4;
ffffffffc02007e0:	0791                	addi	a5,a5,4
ffffffffc02007e2:	10f43423          	sd	a5,264(s0)
}
ffffffffc02007e6:	6402                	ld	s0,0(sp)
ffffffffc02007e8:	0141                	addi	sp,sp,16
ffffffffc02007ea:	8082                	ret

ffffffffc02007ec <trap>:

static inline void trap_dispatch(struct trapframe *tf) {
    if ((intptr_t)tf->cause < 0) {
ffffffffc02007ec:	11853783          	ld	a5,280(a0)
ffffffffc02007f0:	0007c463          	bltz	a5,ffffffffc02007f8 <trap+0xc>
        // interrupts
        interrupt_handler(tf);
    } else {
        // exceptions
        exception_handler(tf);
ffffffffc02007f4:	f63ff06f          	j	ffffffffc0200756 <exception_handler>
        interrupt_handler(tf);
ffffffffc02007f8:	eb1ff06f          	j	ffffffffc02006a8 <interrupt_handler>

ffffffffc02007fc <__alltraps>:
    .endm

    .globl __alltraps
    .align(2)
__alltraps:
    SAVE_ALL
ffffffffc02007fc:	14011073          	csrw	sscratch,sp
ffffffffc0200800:	712d                	addi	sp,sp,-288
ffffffffc0200802:	e002                	sd	zero,0(sp)
ffffffffc0200804:	e406                	sd	ra,8(sp)
ffffffffc0200806:	ec0e                	sd	gp,24(sp)
ffffffffc0200808:	f012                	sd	tp,32(sp)
ffffffffc020080a:	f416                	sd	t0,40(sp)
ffffffffc020080c:	f81a                	sd	t1,48(sp)
ffffffffc020080e:	fc1e                	sd	t2,56(sp)
ffffffffc0200810:	e0a2                	sd	s0,64(sp)
ffffffffc0200812:	e4a6                	sd	s1,72(sp)
ffffffffc0200814:	e8aa                	sd	a0,80(sp)
ffffffffc0200816:	ecae                	sd	a1,88(sp)
ffffffffc0200818:	f0b2                	sd	a2,96(sp)
ffffffffc020081a:	f4b6                	sd	a3,104(sp)
ffffffffc020081c:	f8ba                	sd	a4,112(sp)
ffffffffc020081e:	fcbe                	sd	a5,120(sp)
ffffffffc0200820:	e142                	sd	a6,128(sp)
ffffffffc0200822:	e546                	sd	a7,136(sp)
ffffffffc0200824:	e94a                	sd	s2,144(sp)
ffffffffc0200826:	ed4e                	sd	s3,152(sp)
ffffffffc0200828:	f152                	sd	s4,160(sp)
ffffffffc020082a:	f556                	sd	s5,168(sp)
ffffffffc020082c:	f95a                	sd	s6,176(sp)
ffffffffc020082e:	fd5e                	sd	s7,184(sp)
ffffffffc0200830:	e1e2                	sd	s8,192(sp)
ffffffffc0200832:	e5e6                	sd	s9,200(sp)
ffffffffc0200834:	e9ea                	sd	s10,208(sp)
ffffffffc0200836:	edee                	sd	s11,216(sp)
ffffffffc0200838:	f1f2                	sd	t3,224(sp)
ffffffffc020083a:	f5f6                	sd	t4,232(sp)
ffffffffc020083c:	f9fa                	sd	t5,240(sp)
ffffffffc020083e:	fdfe                	sd	t6,248(sp)
ffffffffc0200840:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200844:	100024f3          	csrr	s1,sstatus
ffffffffc0200848:	14102973          	csrr	s2,sepc
ffffffffc020084c:	143029f3          	csrr	s3,stval
ffffffffc0200850:	14202a73          	csrr	s4,scause
ffffffffc0200854:	e822                	sd	s0,16(sp)
ffffffffc0200856:	e226                	sd	s1,256(sp)
ffffffffc0200858:	e64a                	sd	s2,264(sp)
ffffffffc020085a:	ea4e                	sd	s3,272(sp)
ffffffffc020085c:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc020085e:	850a                	mv	a0,sp
    jal trap
ffffffffc0200860:	f8dff0ef          	jal	ra,ffffffffc02007ec <trap>

ffffffffc0200864 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200864:	6492                	ld	s1,256(sp)
ffffffffc0200866:	6932                	ld	s2,264(sp)
ffffffffc0200868:	10049073          	csrw	sstatus,s1
ffffffffc020086c:	14191073          	csrw	sepc,s2
ffffffffc0200870:	60a2                	ld	ra,8(sp)
ffffffffc0200872:	61e2                	ld	gp,24(sp)
ffffffffc0200874:	7202                	ld	tp,32(sp)
ffffffffc0200876:	72a2                	ld	t0,40(sp)
ffffffffc0200878:	7342                	ld	t1,48(sp)
ffffffffc020087a:	73e2                	ld	t2,56(sp)
ffffffffc020087c:	6406                	ld	s0,64(sp)
ffffffffc020087e:	64a6                	ld	s1,72(sp)
ffffffffc0200880:	6546                	ld	a0,80(sp)
ffffffffc0200882:	65e6                	ld	a1,88(sp)
ffffffffc0200884:	7606                	ld	a2,96(sp)
ffffffffc0200886:	76a6                	ld	a3,104(sp)
ffffffffc0200888:	7746                	ld	a4,112(sp)
ffffffffc020088a:	77e6                	ld	a5,120(sp)
ffffffffc020088c:	680a                	ld	a6,128(sp)
ffffffffc020088e:	68aa                	ld	a7,136(sp)
ffffffffc0200890:	694a                	ld	s2,144(sp)
ffffffffc0200892:	69ea                	ld	s3,152(sp)
ffffffffc0200894:	7a0a                	ld	s4,160(sp)
ffffffffc0200896:	7aaa                	ld	s5,168(sp)
ffffffffc0200898:	7b4a                	ld	s6,176(sp)
ffffffffc020089a:	7bea                	ld	s7,184(sp)
ffffffffc020089c:	6c0e                	ld	s8,192(sp)
ffffffffc020089e:	6cae                	ld	s9,200(sp)
ffffffffc02008a0:	6d4e                	ld	s10,208(sp)
ffffffffc02008a2:	6dee                	ld	s11,216(sp)
ffffffffc02008a4:	7e0e                	ld	t3,224(sp)
ffffffffc02008a6:	7eae                	ld	t4,232(sp)
ffffffffc02008a8:	7f4e                	ld	t5,240(sp)
ffffffffc02008aa:	7fee                	ld	t6,248(sp)
ffffffffc02008ac:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc02008ae:	10200073          	sret

ffffffffc02008b2 <best_fit_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc02008b2:	00006797          	auipc	a5,0x6
ffffffffc02008b6:	b8678793          	addi	a5,a5,-1146 # ffffffffc0206438 <free_area>
ffffffffc02008ba:	e79c                	sd	a5,8(a5)
ffffffffc02008bc:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
best_fit_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc02008be:	0007a823          	sw	zero,16(a5)
}
ffffffffc02008c2:	8082                	ret

ffffffffc02008c4 <best_fit_nr_free_pages>:
}

static size_t
best_fit_nr_free_pages(void) {
    return nr_free;
}
ffffffffc02008c4:	00006517          	auipc	a0,0x6
ffffffffc02008c8:	b8456503          	lwu	a0,-1148(a0) # ffffffffc0206448 <free_area+0x10>
ffffffffc02008cc:	8082                	ret

ffffffffc02008ce <best_fit_alloc_pages>:
    assert(n > 0);
ffffffffc02008ce:	c15d                	beqz	a0,ffffffffc0200974 <best_fit_alloc_pages+0xa6>
    if (n > nr_free) {
ffffffffc02008d0:	00006617          	auipc	a2,0x6
ffffffffc02008d4:	b6860613          	addi	a2,a2,-1176 # ffffffffc0206438 <free_area>
ffffffffc02008d8:	01062803          	lw	a6,16(a2)
ffffffffc02008dc:	86aa                	mv	a3,a0
ffffffffc02008de:	02081793          	slli	a5,a6,0x20
ffffffffc02008e2:	9381                	srli	a5,a5,0x20
ffffffffc02008e4:	08a7e663          	bltu	a5,a0,ffffffffc0200970 <best_fit_alloc_pages+0xa2>
    size_t min_size = nr_free + 1;
ffffffffc02008e8:	0018059b          	addiw	a1,a6,1
ffffffffc02008ec:	1582                	slli	a1,a1,0x20
ffffffffc02008ee:	9181                	srli	a1,a1,0x20
    list_entry_t *le = &free_list;
ffffffffc02008f0:	87b2                	mv	a5,a2
    struct Page *page = NULL;
ffffffffc02008f2:	4501                	li	a0,0
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc02008f4:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc02008f6:	00c78e63          	beq	a5,a2,ffffffffc0200912 <best_fit_alloc_pages+0x44>
        if (p->property >= n && p->property < min_size) {
ffffffffc02008fa:	ff87e703          	lwu	a4,-8(a5)
ffffffffc02008fe:	fed76be3          	bltu	a4,a3,ffffffffc02008f4 <best_fit_alloc_pages+0x26>
ffffffffc0200902:	feb779e3          	bleu	a1,a4,ffffffffc02008f4 <best_fit_alloc_pages+0x26>
        struct Page *p = le2page(le, page_link);
ffffffffc0200906:	fe878513          	addi	a0,a5,-24
ffffffffc020090a:	679c                	ld	a5,8(a5)
ffffffffc020090c:	85ba                	mv	a1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc020090e:	fec796e3          	bne	a5,a2,ffffffffc02008fa <best_fit_alloc_pages+0x2c>
    if (page != NULL) {
ffffffffc0200912:	c125                	beqz	a0,ffffffffc0200972 <best_fit_alloc_pages+0xa4>
    __list_del(listelm->prev, listelm->next);
ffffffffc0200914:	7118                	ld	a4,32(a0)
 * list_prev - get the previous entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_prev(list_entry_t *listelm) {
    return listelm->prev;
ffffffffc0200916:	6d10                	ld	a2,24(a0)
        if (page->property > n) {
ffffffffc0200918:	490c                	lw	a1,16(a0)
ffffffffc020091a:	0006889b          	sext.w	a7,a3
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc020091e:	e618                	sd	a4,8(a2)
    next->prev = prev;
ffffffffc0200920:	e310                	sd	a2,0(a4)
ffffffffc0200922:	02059713          	slli	a4,a1,0x20
ffffffffc0200926:	9301                	srli	a4,a4,0x20
ffffffffc0200928:	02e6f863          	bleu	a4,a3,ffffffffc0200958 <best_fit_alloc_pages+0x8a>
            struct Page *p = page + n;
ffffffffc020092c:	00269713          	slli	a4,a3,0x2
ffffffffc0200930:	9736                	add	a4,a4,a3
ffffffffc0200932:	070e                	slli	a4,a4,0x3
ffffffffc0200934:	972a                	add	a4,a4,a0
            p->property = page->property - n;
ffffffffc0200936:	411585bb          	subw	a1,a1,a7
ffffffffc020093a:	cb0c                	sw	a1,16(a4)
 *
 * Note that @nr may be almost arbitrarily large; this function is not
 * restricted to acting on a single-word quantity.
 * */
static inline void set_bit(int nr, volatile void *addr) {
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020093c:	4689                	li	a3,2
ffffffffc020093e:	00870593          	addi	a1,a4,8
ffffffffc0200942:	40d5b02f          	amoor.d	zero,a3,(a1)
    __list_add(elm, listelm, listelm->next);
ffffffffc0200946:	6614                	ld	a3,8(a2)
            list_add(prev, &(p->page_link));
ffffffffc0200948:	01870593          	addi	a1,a4,24
    prev->next = next->prev = elm;
ffffffffc020094c:	0107a803          	lw	a6,16(a5)
ffffffffc0200950:	e28c                	sd	a1,0(a3)
ffffffffc0200952:	e60c                	sd	a1,8(a2)
    elm->next = next;
ffffffffc0200954:	f314                	sd	a3,32(a4)
    elm->prev = prev;
ffffffffc0200956:	ef10                	sd	a2,24(a4)
        nr_free -= n;
ffffffffc0200958:	4118083b          	subw	a6,a6,a7
ffffffffc020095c:	00006797          	auipc	a5,0x6
ffffffffc0200960:	af07a623          	sw	a6,-1300(a5) # ffffffffc0206448 <free_area+0x10>
 * clear_bit - Atomically clears a bit in memory
 * @nr:     the bit to clear
 * @addr:   the address to start counting from
 * */
static inline void clear_bit(int nr, volatile void *addr) {
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0200964:	57f5                	li	a5,-3
ffffffffc0200966:	00850713          	addi	a4,a0,8
ffffffffc020096a:	60f7302f          	amoand.d	zero,a5,(a4)
ffffffffc020096e:	8082                	ret
        return NULL;
ffffffffc0200970:	4501                	li	a0,0
}
ffffffffc0200972:	8082                	ret
best_fit_alloc_pages(size_t n) {
ffffffffc0200974:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0200976:	00002697          	auipc	a3,0x2
ffffffffc020097a:	9ca68693          	addi	a3,a3,-1590 # ffffffffc0202340 <commands+0x6c0>
ffffffffc020097e:	00002617          	auipc	a2,0x2
ffffffffc0200982:	9ca60613          	addi	a2,a2,-1590 # ffffffffc0202348 <commands+0x6c8>
ffffffffc0200986:	06b00593          	li	a1,107
ffffffffc020098a:	00002517          	auipc	a0,0x2
ffffffffc020098e:	9d650513          	addi	a0,a0,-1578 # ffffffffc0202360 <commands+0x6e0>
best_fit_alloc_pages(size_t n) {
ffffffffc0200992:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200994:	a15ff0ef          	jal	ra,ffffffffc02003a8 <__panic>

ffffffffc0200998 <best_fit_check>:
}

// LAB2: below code is used to check the best fit allocation algorithm 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
best_fit_check(void) {
ffffffffc0200998:	715d                	addi	sp,sp,-80
ffffffffc020099a:	f84a                	sd	s2,48(sp)
    return listelm->next;
ffffffffc020099c:	00006917          	auipc	s2,0x6
ffffffffc02009a0:	a9c90913          	addi	s2,s2,-1380 # ffffffffc0206438 <free_area>
ffffffffc02009a4:	00893783          	ld	a5,8(s2)
ffffffffc02009a8:	e486                	sd	ra,72(sp)
ffffffffc02009aa:	e0a2                	sd	s0,64(sp)
ffffffffc02009ac:	fc26                	sd	s1,56(sp)
ffffffffc02009ae:	f44e                	sd	s3,40(sp)
ffffffffc02009b0:	f052                	sd	s4,32(sp)
ffffffffc02009b2:	ec56                	sd	s5,24(sp)
ffffffffc02009b4:	e85a                	sd	s6,16(sp)
ffffffffc02009b6:	e45e                	sd	s7,8(sp)
ffffffffc02009b8:	e062                	sd	s8,0(sp)
    int score = 0 ,sumscore = 6;
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc02009ba:	2d278363          	beq	a5,s2,ffffffffc0200c80 <best_fit_check+0x2e8>
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc02009be:	ff07b703          	ld	a4,-16(a5)
ffffffffc02009c2:	8305                	srli	a4,a4,0x1
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc02009c4:	8b05                	andi	a4,a4,1
ffffffffc02009c6:	2c070163          	beqz	a4,ffffffffc0200c88 <best_fit_check+0x2f0>
    int count = 0, total = 0;
ffffffffc02009ca:	4401                	li	s0,0
ffffffffc02009cc:	4481                	li	s1,0
ffffffffc02009ce:	a031                	j	ffffffffc02009da <best_fit_check+0x42>
ffffffffc02009d0:	ff07b703          	ld	a4,-16(a5)
        assert(PageProperty(p));
ffffffffc02009d4:	8b09                	andi	a4,a4,2
ffffffffc02009d6:	2a070963          	beqz	a4,ffffffffc0200c88 <best_fit_check+0x2f0>
        count ++, total += p->property;
ffffffffc02009da:	ff87a703          	lw	a4,-8(a5)
ffffffffc02009de:	679c                	ld	a5,8(a5)
ffffffffc02009e0:	2485                	addiw	s1,s1,1
ffffffffc02009e2:	9c39                	addw	s0,s0,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc02009e4:	ff2796e3          	bne	a5,s2,ffffffffc02009d0 <best_fit_check+0x38>
ffffffffc02009e8:	89a2                	mv	s3,s0
    }
    assert(total == nr_free_pages());
ffffffffc02009ea:	1fd000ef          	jal	ra,ffffffffc02013e6 <nr_free_pages>
ffffffffc02009ee:	37351d63          	bne	a0,s3,ffffffffc0200d68 <best_fit_check+0x3d0>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02009f2:	4505                	li	a0,1
ffffffffc02009f4:	169000ef          	jal	ra,ffffffffc020135c <alloc_pages>
ffffffffc02009f8:	8a2a                	mv	s4,a0
ffffffffc02009fa:	3a050763          	beqz	a0,ffffffffc0200da8 <best_fit_check+0x410>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02009fe:	4505                	li	a0,1
ffffffffc0200a00:	15d000ef          	jal	ra,ffffffffc020135c <alloc_pages>
ffffffffc0200a04:	89aa                	mv	s3,a0
ffffffffc0200a06:	38050163          	beqz	a0,ffffffffc0200d88 <best_fit_check+0x3f0>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200a0a:	4505                	li	a0,1
ffffffffc0200a0c:	151000ef          	jal	ra,ffffffffc020135c <alloc_pages>
ffffffffc0200a10:	8aaa                	mv	s5,a0
ffffffffc0200a12:	30050b63          	beqz	a0,ffffffffc0200d28 <best_fit_check+0x390>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200a16:	293a0963          	beq	s4,s3,ffffffffc0200ca8 <best_fit_check+0x310>
ffffffffc0200a1a:	28aa0763          	beq	s4,a0,ffffffffc0200ca8 <best_fit_check+0x310>
ffffffffc0200a1e:	28a98563          	beq	s3,a0,ffffffffc0200ca8 <best_fit_check+0x310>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200a22:	000a2783          	lw	a5,0(s4)
ffffffffc0200a26:	2a079163          	bnez	a5,ffffffffc0200cc8 <best_fit_check+0x330>
ffffffffc0200a2a:	0009a783          	lw	a5,0(s3)
ffffffffc0200a2e:	28079d63          	bnez	a5,ffffffffc0200cc8 <best_fit_check+0x330>
ffffffffc0200a32:	411c                	lw	a5,0(a0)
ffffffffc0200a34:	28079a63          	bnez	a5,ffffffffc0200cc8 <best_fit_check+0x330>
extern struct Page *pages;
extern size_t npage;
extern const size_t nbase;
extern uint64_t va_pa_offset;

static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200a38:	00006797          	auipc	a5,0x6
ffffffffc0200a3c:	a3078793          	addi	a5,a5,-1488 # ffffffffc0206468 <pages>
ffffffffc0200a40:	639c                	ld	a5,0(a5)
ffffffffc0200a42:	00002717          	auipc	a4,0x2
ffffffffc0200a46:	93670713          	addi	a4,a4,-1738 # ffffffffc0202378 <commands+0x6f8>
ffffffffc0200a4a:	630c                	ld	a1,0(a4)
ffffffffc0200a4c:	40fa0733          	sub	a4,s4,a5
ffffffffc0200a50:	870d                	srai	a4,a4,0x3
ffffffffc0200a52:	02b70733          	mul	a4,a4,a1
ffffffffc0200a56:	00002697          	auipc	a3,0x2
ffffffffc0200a5a:	fe268693          	addi	a3,a3,-30 # ffffffffc0202a38 <nbase>
ffffffffc0200a5e:	6290                	ld	a2,0(a3)
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200a60:	00006697          	auipc	a3,0x6
ffffffffc0200a64:	9b868693          	addi	a3,a3,-1608 # ffffffffc0206418 <npage>
ffffffffc0200a68:	6294                	ld	a3,0(a3)
ffffffffc0200a6a:	06b2                	slli	a3,a3,0xc
ffffffffc0200a6c:	9732                	add	a4,a4,a2

static inline uintptr_t page2pa(struct Page *page) {
    return page2ppn(page) << PGSHIFT;
ffffffffc0200a6e:	0732                	slli	a4,a4,0xc
ffffffffc0200a70:	26d77c63          	bleu	a3,a4,ffffffffc0200ce8 <best_fit_check+0x350>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200a74:	40f98733          	sub	a4,s3,a5
ffffffffc0200a78:	870d                	srai	a4,a4,0x3
ffffffffc0200a7a:	02b70733          	mul	a4,a4,a1
ffffffffc0200a7e:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200a80:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200a82:	42d77363          	bleu	a3,a4,ffffffffc0200ea8 <best_fit_check+0x510>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200a86:	40f507b3          	sub	a5,a0,a5
ffffffffc0200a8a:	878d                	srai	a5,a5,0x3
ffffffffc0200a8c:	02b787b3          	mul	a5,a5,a1
ffffffffc0200a90:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200a92:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200a94:	3ed7fa63          	bleu	a3,a5,ffffffffc0200e88 <best_fit_check+0x4f0>
    assert(alloc_page() == NULL);
ffffffffc0200a98:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200a9a:	00093c03          	ld	s8,0(s2)
ffffffffc0200a9e:	00893b83          	ld	s7,8(s2)
    unsigned int nr_free_store = nr_free;
ffffffffc0200aa2:	01092b03          	lw	s6,16(s2)
    elm->prev = elm->next = elm;
ffffffffc0200aa6:	00006797          	auipc	a5,0x6
ffffffffc0200aaa:	9927bd23          	sd	s2,-1638(a5) # ffffffffc0206440 <free_area+0x8>
ffffffffc0200aae:	00006797          	auipc	a5,0x6
ffffffffc0200ab2:	9927b523          	sd	s2,-1654(a5) # ffffffffc0206438 <free_area>
    nr_free = 0;
ffffffffc0200ab6:	00006797          	auipc	a5,0x6
ffffffffc0200aba:	9807a923          	sw	zero,-1646(a5) # ffffffffc0206448 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0200abe:	09f000ef          	jal	ra,ffffffffc020135c <alloc_pages>
ffffffffc0200ac2:	3a051363          	bnez	a0,ffffffffc0200e68 <best_fit_check+0x4d0>
    free_page(p0);
ffffffffc0200ac6:	4585                	li	a1,1
ffffffffc0200ac8:	8552                	mv	a0,s4
ffffffffc0200aca:	0d7000ef          	jal	ra,ffffffffc02013a0 <free_pages>
    free_page(p1);
ffffffffc0200ace:	4585                	li	a1,1
ffffffffc0200ad0:	854e                	mv	a0,s3
ffffffffc0200ad2:	0cf000ef          	jal	ra,ffffffffc02013a0 <free_pages>
    free_page(p2);
ffffffffc0200ad6:	4585                	li	a1,1
ffffffffc0200ad8:	8556                	mv	a0,s5
ffffffffc0200ada:	0c7000ef          	jal	ra,ffffffffc02013a0 <free_pages>
    assert(nr_free == 3);
ffffffffc0200ade:	01092703          	lw	a4,16(s2)
ffffffffc0200ae2:	478d                	li	a5,3
ffffffffc0200ae4:	36f71263          	bne	a4,a5,ffffffffc0200e48 <best_fit_check+0x4b0>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200ae8:	4505                	li	a0,1
ffffffffc0200aea:	073000ef          	jal	ra,ffffffffc020135c <alloc_pages>
ffffffffc0200aee:	89aa                	mv	s3,a0
ffffffffc0200af0:	32050c63          	beqz	a0,ffffffffc0200e28 <best_fit_check+0x490>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200af4:	4505                	li	a0,1
ffffffffc0200af6:	067000ef          	jal	ra,ffffffffc020135c <alloc_pages>
ffffffffc0200afa:	8aaa                	mv	s5,a0
ffffffffc0200afc:	30050663          	beqz	a0,ffffffffc0200e08 <best_fit_check+0x470>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200b00:	4505                	li	a0,1
ffffffffc0200b02:	05b000ef          	jal	ra,ffffffffc020135c <alloc_pages>
ffffffffc0200b06:	8a2a                	mv	s4,a0
ffffffffc0200b08:	2e050063          	beqz	a0,ffffffffc0200de8 <best_fit_check+0x450>
    assert(alloc_page() == NULL);
ffffffffc0200b0c:	4505                	li	a0,1
ffffffffc0200b0e:	04f000ef          	jal	ra,ffffffffc020135c <alloc_pages>
ffffffffc0200b12:	2a051b63          	bnez	a0,ffffffffc0200dc8 <best_fit_check+0x430>
    free_page(p0);
ffffffffc0200b16:	4585                	li	a1,1
ffffffffc0200b18:	854e                	mv	a0,s3
ffffffffc0200b1a:	087000ef          	jal	ra,ffffffffc02013a0 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0200b1e:	00893783          	ld	a5,8(s2)
ffffffffc0200b22:	1f278363          	beq	a5,s2,ffffffffc0200d08 <best_fit_check+0x370>
    assert((p = alloc_page()) == p0);
ffffffffc0200b26:	4505                	li	a0,1
ffffffffc0200b28:	035000ef          	jal	ra,ffffffffc020135c <alloc_pages>
ffffffffc0200b2c:	54a99e63          	bne	s3,a0,ffffffffc0201088 <best_fit_check+0x6f0>
    assert(alloc_page() == NULL);
ffffffffc0200b30:	4505                	li	a0,1
ffffffffc0200b32:	02b000ef          	jal	ra,ffffffffc020135c <alloc_pages>
ffffffffc0200b36:	52051963          	bnez	a0,ffffffffc0201068 <best_fit_check+0x6d0>
    assert(nr_free == 0);
ffffffffc0200b3a:	01092783          	lw	a5,16(s2)
ffffffffc0200b3e:	50079563          	bnez	a5,ffffffffc0201048 <best_fit_check+0x6b0>
    free_page(p);
ffffffffc0200b42:	854e                	mv	a0,s3
ffffffffc0200b44:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0200b46:	00006797          	auipc	a5,0x6
ffffffffc0200b4a:	8f87b923          	sd	s8,-1806(a5) # ffffffffc0206438 <free_area>
ffffffffc0200b4e:	00006797          	auipc	a5,0x6
ffffffffc0200b52:	8f77b923          	sd	s7,-1806(a5) # ffffffffc0206440 <free_area+0x8>
    nr_free = nr_free_store;
ffffffffc0200b56:	00006797          	auipc	a5,0x6
ffffffffc0200b5a:	8f67a923          	sw	s6,-1806(a5) # ffffffffc0206448 <free_area+0x10>
    free_page(p);
ffffffffc0200b5e:	043000ef          	jal	ra,ffffffffc02013a0 <free_pages>
    free_page(p1);
ffffffffc0200b62:	4585                	li	a1,1
ffffffffc0200b64:	8556                	mv	a0,s5
ffffffffc0200b66:	03b000ef          	jal	ra,ffffffffc02013a0 <free_pages>
    free_page(p2);
ffffffffc0200b6a:	4585                	li	a1,1
ffffffffc0200b6c:	8552                	mv	a0,s4
ffffffffc0200b6e:	033000ef          	jal	ra,ffffffffc02013a0 <free_pages>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0200b72:	4515                	li	a0,5
ffffffffc0200b74:	7e8000ef          	jal	ra,ffffffffc020135c <alloc_pages>
ffffffffc0200b78:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0200b7a:	4a050763          	beqz	a0,ffffffffc0201028 <best_fit_check+0x690>
ffffffffc0200b7e:	651c                	ld	a5,8(a0)
ffffffffc0200b80:	8385                	srli	a5,a5,0x1
    assert(!PageProperty(p0));
ffffffffc0200b82:	8b85                	andi	a5,a5,1
ffffffffc0200b84:	48079263          	bnez	a5,ffffffffc0201008 <best_fit_check+0x670>
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0200b88:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200b8a:	00093b03          	ld	s6,0(s2)
ffffffffc0200b8e:	00893a83          	ld	s5,8(s2)
ffffffffc0200b92:	00006797          	auipc	a5,0x6
ffffffffc0200b96:	8b27b323          	sd	s2,-1882(a5) # ffffffffc0206438 <free_area>
ffffffffc0200b9a:	00006797          	auipc	a5,0x6
ffffffffc0200b9e:	8b27b323          	sd	s2,-1882(a5) # ffffffffc0206440 <free_area+0x8>
    assert(alloc_page() == NULL);
ffffffffc0200ba2:	7ba000ef          	jal	ra,ffffffffc020135c <alloc_pages>
ffffffffc0200ba6:	44051163          	bnez	a0,ffffffffc0200fe8 <best_fit_check+0x650>
    #endif
    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    // * - - * -
    free_pages(p0 + 1, 2);
ffffffffc0200baa:	4589                	li	a1,2
ffffffffc0200bac:	02898513          	addi	a0,s3,40
    unsigned int nr_free_store = nr_free;
ffffffffc0200bb0:	01092b83          	lw	s7,16(s2)
    free_pages(p0 + 4, 1);
ffffffffc0200bb4:	0a098c13          	addi	s8,s3,160
    nr_free = 0;
ffffffffc0200bb8:	00006797          	auipc	a5,0x6
ffffffffc0200bbc:	8807a823          	sw	zero,-1904(a5) # ffffffffc0206448 <free_area+0x10>
    free_pages(p0 + 1, 2);
ffffffffc0200bc0:	7e0000ef          	jal	ra,ffffffffc02013a0 <free_pages>
    free_pages(p0 + 4, 1);
ffffffffc0200bc4:	8562                	mv	a0,s8
ffffffffc0200bc6:	4585                	li	a1,1
ffffffffc0200bc8:	7d8000ef          	jal	ra,ffffffffc02013a0 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0200bcc:	4511                	li	a0,4
ffffffffc0200bce:	78e000ef          	jal	ra,ffffffffc020135c <alloc_pages>
ffffffffc0200bd2:	3e051b63          	bnez	a0,ffffffffc0200fc8 <best_fit_check+0x630>
ffffffffc0200bd6:	0309b783          	ld	a5,48(s3)
ffffffffc0200bda:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc0200bdc:	8b85                	andi	a5,a5,1
ffffffffc0200bde:	3c078563          	beqz	a5,ffffffffc0200fa8 <best_fit_check+0x610>
ffffffffc0200be2:	0389a703          	lw	a4,56(s3)
ffffffffc0200be6:	4789                	li	a5,2
ffffffffc0200be8:	3cf71063          	bne	a4,a5,ffffffffc0200fa8 <best_fit_check+0x610>
    // * - - * *
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc0200bec:	4505                	li	a0,1
ffffffffc0200bee:	76e000ef          	jal	ra,ffffffffc020135c <alloc_pages>
ffffffffc0200bf2:	8a2a                	mv	s4,a0
ffffffffc0200bf4:	38050a63          	beqz	a0,ffffffffc0200f88 <best_fit_check+0x5f0>
    assert(alloc_pages(2) != NULL);      // best fit feature
ffffffffc0200bf8:	4509                	li	a0,2
ffffffffc0200bfa:	762000ef          	jal	ra,ffffffffc020135c <alloc_pages>
ffffffffc0200bfe:	36050563          	beqz	a0,ffffffffc0200f68 <best_fit_check+0x5d0>
    assert(p0 + 4 == p1);
ffffffffc0200c02:	354c1363          	bne	s8,s4,ffffffffc0200f48 <best_fit_check+0x5b0>
    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    p2 = p0 + 1;
    free_pages(p0, 5);
ffffffffc0200c06:	854e                	mv	a0,s3
ffffffffc0200c08:	4595                	li	a1,5
ffffffffc0200c0a:	796000ef          	jal	ra,ffffffffc02013a0 <free_pages>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200c0e:	4515                	li	a0,5
ffffffffc0200c10:	74c000ef          	jal	ra,ffffffffc020135c <alloc_pages>
ffffffffc0200c14:	89aa                	mv	s3,a0
ffffffffc0200c16:	30050963          	beqz	a0,ffffffffc0200f28 <best_fit_check+0x590>
    assert(alloc_page() == NULL);
ffffffffc0200c1a:	4505                	li	a0,1
ffffffffc0200c1c:	740000ef          	jal	ra,ffffffffc020135c <alloc_pages>
ffffffffc0200c20:	2e051463          	bnez	a0,ffffffffc0200f08 <best_fit_check+0x570>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    assert(nr_free == 0);
ffffffffc0200c24:	01092783          	lw	a5,16(s2)
ffffffffc0200c28:	2c079063          	bnez	a5,ffffffffc0200ee8 <best_fit_check+0x550>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0200c2c:	4595                	li	a1,5
ffffffffc0200c2e:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0200c30:	00006797          	auipc	a5,0x6
ffffffffc0200c34:	8177ac23          	sw	s7,-2024(a5) # ffffffffc0206448 <free_area+0x10>
    free_list = free_list_store;
ffffffffc0200c38:	00006797          	auipc	a5,0x6
ffffffffc0200c3c:	8167b023          	sd	s6,-2048(a5) # ffffffffc0206438 <free_area>
ffffffffc0200c40:	00006797          	auipc	a5,0x6
ffffffffc0200c44:	8157b023          	sd	s5,-2048(a5) # ffffffffc0206440 <free_area+0x8>
    free_pages(p0, 5);
ffffffffc0200c48:	758000ef          	jal	ra,ffffffffc02013a0 <free_pages>
    return listelm->next;
ffffffffc0200c4c:	00893783          	ld	a5,8(s2)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200c50:	01278963          	beq	a5,s2,ffffffffc0200c62 <best_fit_check+0x2ca>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc0200c54:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200c58:	679c                	ld	a5,8(a5)
ffffffffc0200c5a:	34fd                	addiw	s1,s1,-1
ffffffffc0200c5c:	9c19                	subw	s0,s0,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200c5e:	ff279be3          	bne	a5,s2,ffffffffc0200c54 <best_fit_check+0x2bc>
    }
    assert(count == 0);
ffffffffc0200c62:	26049363          	bnez	s1,ffffffffc0200ec8 <best_fit_check+0x530>
    assert(total == 0);
ffffffffc0200c66:	e06d                	bnez	s0,ffffffffc0200d48 <best_fit_check+0x3b0>
    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
}
ffffffffc0200c68:	60a6                	ld	ra,72(sp)
ffffffffc0200c6a:	6406                	ld	s0,64(sp)
ffffffffc0200c6c:	74e2                	ld	s1,56(sp)
ffffffffc0200c6e:	7942                	ld	s2,48(sp)
ffffffffc0200c70:	79a2                	ld	s3,40(sp)
ffffffffc0200c72:	7a02                	ld	s4,32(sp)
ffffffffc0200c74:	6ae2                	ld	s5,24(sp)
ffffffffc0200c76:	6b42                	ld	s6,16(sp)
ffffffffc0200c78:	6ba2                	ld	s7,8(sp)
ffffffffc0200c7a:	6c02                	ld	s8,0(sp)
ffffffffc0200c7c:	6161                	addi	sp,sp,80
ffffffffc0200c7e:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200c80:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0200c82:	4401                	li	s0,0
ffffffffc0200c84:	4481                	li	s1,0
ffffffffc0200c86:	b395                	j	ffffffffc02009ea <best_fit_check+0x52>
        assert(PageProperty(p));
ffffffffc0200c88:	00001697          	auipc	a3,0x1
ffffffffc0200c8c:	6f868693          	addi	a3,a3,1784 # ffffffffc0202380 <commands+0x700>
ffffffffc0200c90:	00001617          	auipc	a2,0x1
ffffffffc0200c94:	6b860613          	addi	a2,a2,1720 # ffffffffc0202348 <commands+0x6c8>
ffffffffc0200c98:	11000593          	li	a1,272
ffffffffc0200c9c:	00001517          	auipc	a0,0x1
ffffffffc0200ca0:	6c450513          	addi	a0,a0,1732 # ffffffffc0202360 <commands+0x6e0>
ffffffffc0200ca4:	f04ff0ef          	jal	ra,ffffffffc02003a8 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200ca8:	00001697          	auipc	a3,0x1
ffffffffc0200cac:	76868693          	addi	a3,a3,1896 # ffffffffc0202410 <commands+0x790>
ffffffffc0200cb0:	00001617          	auipc	a2,0x1
ffffffffc0200cb4:	69860613          	addi	a2,a2,1688 # ffffffffc0202348 <commands+0x6c8>
ffffffffc0200cb8:	0dc00593          	li	a1,220
ffffffffc0200cbc:	00001517          	auipc	a0,0x1
ffffffffc0200cc0:	6a450513          	addi	a0,a0,1700 # ffffffffc0202360 <commands+0x6e0>
ffffffffc0200cc4:	ee4ff0ef          	jal	ra,ffffffffc02003a8 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200cc8:	00001697          	auipc	a3,0x1
ffffffffc0200ccc:	77068693          	addi	a3,a3,1904 # ffffffffc0202438 <commands+0x7b8>
ffffffffc0200cd0:	00001617          	auipc	a2,0x1
ffffffffc0200cd4:	67860613          	addi	a2,a2,1656 # ffffffffc0202348 <commands+0x6c8>
ffffffffc0200cd8:	0dd00593          	li	a1,221
ffffffffc0200cdc:	00001517          	auipc	a0,0x1
ffffffffc0200ce0:	68450513          	addi	a0,a0,1668 # ffffffffc0202360 <commands+0x6e0>
ffffffffc0200ce4:	ec4ff0ef          	jal	ra,ffffffffc02003a8 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200ce8:	00001697          	auipc	a3,0x1
ffffffffc0200cec:	79068693          	addi	a3,a3,1936 # ffffffffc0202478 <commands+0x7f8>
ffffffffc0200cf0:	00001617          	auipc	a2,0x1
ffffffffc0200cf4:	65860613          	addi	a2,a2,1624 # ffffffffc0202348 <commands+0x6c8>
ffffffffc0200cf8:	0df00593          	li	a1,223
ffffffffc0200cfc:	00001517          	auipc	a0,0x1
ffffffffc0200d00:	66450513          	addi	a0,a0,1636 # ffffffffc0202360 <commands+0x6e0>
ffffffffc0200d04:	ea4ff0ef          	jal	ra,ffffffffc02003a8 <__panic>
    assert(!list_empty(&free_list));
ffffffffc0200d08:	00001697          	auipc	a3,0x1
ffffffffc0200d0c:	7f868693          	addi	a3,a3,2040 # ffffffffc0202500 <commands+0x880>
ffffffffc0200d10:	00001617          	auipc	a2,0x1
ffffffffc0200d14:	63860613          	addi	a2,a2,1592 # ffffffffc0202348 <commands+0x6c8>
ffffffffc0200d18:	0f800593          	li	a1,248
ffffffffc0200d1c:	00001517          	auipc	a0,0x1
ffffffffc0200d20:	64450513          	addi	a0,a0,1604 # ffffffffc0202360 <commands+0x6e0>
ffffffffc0200d24:	e84ff0ef          	jal	ra,ffffffffc02003a8 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200d28:	00001697          	auipc	a3,0x1
ffffffffc0200d2c:	6c868693          	addi	a3,a3,1736 # ffffffffc02023f0 <commands+0x770>
ffffffffc0200d30:	00001617          	auipc	a2,0x1
ffffffffc0200d34:	61860613          	addi	a2,a2,1560 # ffffffffc0202348 <commands+0x6c8>
ffffffffc0200d38:	0da00593          	li	a1,218
ffffffffc0200d3c:	00001517          	auipc	a0,0x1
ffffffffc0200d40:	62450513          	addi	a0,a0,1572 # ffffffffc0202360 <commands+0x6e0>
ffffffffc0200d44:	e64ff0ef          	jal	ra,ffffffffc02003a8 <__panic>
    assert(total == 0);
ffffffffc0200d48:	00002697          	auipc	a3,0x2
ffffffffc0200d4c:	8e868693          	addi	a3,a3,-1816 # ffffffffc0202630 <commands+0x9b0>
ffffffffc0200d50:	00001617          	auipc	a2,0x1
ffffffffc0200d54:	5f860613          	addi	a2,a2,1528 # ffffffffc0202348 <commands+0x6c8>
ffffffffc0200d58:	15200593          	li	a1,338
ffffffffc0200d5c:	00001517          	auipc	a0,0x1
ffffffffc0200d60:	60450513          	addi	a0,a0,1540 # ffffffffc0202360 <commands+0x6e0>
ffffffffc0200d64:	e44ff0ef          	jal	ra,ffffffffc02003a8 <__panic>
    assert(total == nr_free_pages());
ffffffffc0200d68:	00001697          	auipc	a3,0x1
ffffffffc0200d6c:	62868693          	addi	a3,a3,1576 # ffffffffc0202390 <commands+0x710>
ffffffffc0200d70:	00001617          	auipc	a2,0x1
ffffffffc0200d74:	5d860613          	addi	a2,a2,1496 # ffffffffc0202348 <commands+0x6c8>
ffffffffc0200d78:	11300593          	li	a1,275
ffffffffc0200d7c:	00001517          	auipc	a0,0x1
ffffffffc0200d80:	5e450513          	addi	a0,a0,1508 # ffffffffc0202360 <commands+0x6e0>
ffffffffc0200d84:	e24ff0ef          	jal	ra,ffffffffc02003a8 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200d88:	00001697          	auipc	a3,0x1
ffffffffc0200d8c:	64868693          	addi	a3,a3,1608 # ffffffffc02023d0 <commands+0x750>
ffffffffc0200d90:	00001617          	auipc	a2,0x1
ffffffffc0200d94:	5b860613          	addi	a2,a2,1464 # ffffffffc0202348 <commands+0x6c8>
ffffffffc0200d98:	0d900593          	li	a1,217
ffffffffc0200d9c:	00001517          	auipc	a0,0x1
ffffffffc0200da0:	5c450513          	addi	a0,a0,1476 # ffffffffc0202360 <commands+0x6e0>
ffffffffc0200da4:	e04ff0ef          	jal	ra,ffffffffc02003a8 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200da8:	00001697          	auipc	a3,0x1
ffffffffc0200dac:	60868693          	addi	a3,a3,1544 # ffffffffc02023b0 <commands+0x730>
ffffffffc0200db0:	00001617          	auipc	a2,0x1
ffffffffc0200db4:	59860613          	addi	a2,a2,1432 # ffffffffc0202348 <commands+0x6c8>
ffffffffc0200db8:	0d800593          	li	a1,216
ffffffffc0200dbc:	00001517          	auipc	a0,0x1
ffffffffc0200dc0:	5a450513          	addi	a0,a0,1444 # ffffffffc0202360 <commands+0x6e0>
ffffffffc0200dc4:	de4ff0ef          	jal	ra,ffffffffc02003a8 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200dc8:	00001697          	auipc	a3,0x1
ffffffffc0200dcc:	71068693          	addi	a3,a3,1808 # ffffffffc02024d8 <commands+0x858>
ffffffffc0200dd0:	00001617          	auipc	a2,0x1
ffffffffc0200dd4:	57860613          	addi	a2,a2,1400 # ffffffffc0202348 <commands+0x6c8>
ffffffffc0200dd8:	0f500593          	li	a1,245
ffffffffc0200ddc:	00001517          	auipc	a0,0x1
ffffffffc0200de0:	58450513          	addi	a0,a0,1412 # ffffffffc0202360 <commands+0x6e0>
ffffffffc0200de4:	dc4ff0ef          	jal	ra,ffffffffc02003a8 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200de8:	00001697          	auipc	a3,0x1
ffffffffc0200dec:	60868693          	addi	a3,a3,1544 # ffffffffc02023f0 <commands+0x770>
ffffffffc0200df0:	00001617          	auipc	a2,0x1
ffffffffc0200df4:	55860613          	addi	a2,a2,1368 # ffffffffc0202348 <commands+0x6c8>
ffffffffc0200df8:	0f300593          	li	a1,243
ffffffffc0200dfc:	00001517          	auipc	a0,0x1
ffffffffc0200e00:	56450513          	addi	a0,a0,1380 # ffffffffc0202360 <commands+0x6e0>
ffffffffc0200e04:	da4ff0ef          	jal	ra,ffffffffc02003a8 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200e08:	00001697          	auipc	a3,0x1
ffffffffc0200e0c:	5c868693          	addi	a3,a3,1480 # ffffffffc02023d0 <commands+0x750>
ffffffffc0200e10:	00001617          	auipc	a2,0x1
ffffffffc0200e14:	53860613          	addi	a2,a2,1336 # ffffffffc0202348 <commands+0x6c8>
ffffffffc0200e18:	0f200593          	li	a1,242
ffffffffc0200e1c:	00001517          	auipc	a0,0x1
ffffffffc0200e20:	54450513          	addi	a0,a0,1348 # ffffffffc0202360 <commands+0x6e0>
ffffffffc0200e24:	d84ff0ef          	jal	ra,ffffffffc02003a8 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200e28:	00001697          	auipc	a3,0x1
ffffffffc0200e2c:	58868693          	addi	a3,a3,1416 # ffffffffc02023b0 <commands+0x730>
ffffffffc0200e30:	00001617          	auipc	a2,0x1
ffffffffc0200e34:	51860613          	addi	a2,a2,1304 # ffffffffc0202348 <commands+0x6c8>
ffffffffc0200e38:	0f100593          	li	a1,241
ffffffffc0200e3c:	00001517          	auipc	a0,0x1
ffffffffc0200e40:	52450513          	addi	a0,a0,1316 # ffffffffc0202360 <commands+0x6e0>
ffffffffc0200e44:	d64ff0ef          	jal	ra,ffffffffc02003a8 <__panic>
    assert(nr_free == 3);
ffffffffc0200e48:	00001697          	auipc	a3,0x1
ffffffffc0200e4c:	6a868693          	addi	a3,a3,1704 # ffffffffc02024f0 <commands+0x870>
ffffffffc0200e50:	00001617          	auipc	a2,0x1
ffffffffc0200e54:	4f860613          	addi	a2,a2,1272 # ffffffffc0202348 <commands+0x6c8>
ffffffffc0200e58:	0ef00593          	li	a1,239
ffffffffc0200e5c:	00001517          	auipc	a0,0x1
ffffffffc0200e60:	50450513          	addi	a0,a0,1284 # ffffffffc0202360 <commands+0x6e0>
ffffffffc0200e64:	d44ff0ef          	jal	ra,ffffffffc02003a8 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200e68:	00001697          	auipc	a3,0x1
ffffffffc0200e6c:	67068693          	addi	a3,a3,1648 # ffffffffc02024d8 <commands+0x858>
ffffffffc0200e70:	00001617          	auipc	a2,0x1
ffffffffc0200e74:	4d860613          	addi	a2,a2,1240 # ffffffffc0202348 <commands+0x6c8>
ffffffffc0200e78:	0ea00593          	li	a1,234
ffffffffc0200e7c:	00001517          	auipc	a0,0x1
ffffffffc0200e80:	4e450513          	addi	a0,a0,1252 # ffffffffc0202360 <commands+0x6e0>
ffffffffc0200e84:	d24ff0ef          	jal	ra,ffffffffc02003a8 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200e88:	00001697          	auipc	a3,0x1
ffffffffc0200e8c:	63068693          	addi	a3,a3,1584 # ffffffffc02024b8 <commands+0x838>
ffffffffc0200e90:	00001617          	auipc	a2,0x1
ffffffffc0200e94:	4b860613          	addi	a2,a2,1208 # ffffffffc0202348 <commands+0x6c8>
ffffffffc0200e98:	0e100593          	li	a1,225
ffffffffc0200e9c:	00001517          	auipc	a0,0x1
ffffffffc0200ea0:	4c450513          	addi	a0,a0,1220 # ffffffffc0202360 <commands+0x6e0>
ffffffffc0200ea4:	d04ff0ef          	jal	ra,ffffffffc02003a8 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200ea8:	00001697          	auipc	a3,0x1
ffffffffc0200eac:	5f068693          	addi	a3,a3,1520 # ffffffffc0202498 <commands+0x818>
ffffffffc0200eb0:	00001617          	auipc	a2,0x1
ffffffffc0200eb4:	49860613          	addi	a2,a2,1176 # ffffffffc0202348 <commands+0x6c8>
ffffffffc0200eb8:	0e000593          	li	a1,224
ffffffffc0200ebc:	00001517          	auipc	a0,0x1
ffffffffc0200ec0:	4a450513          	addi	a0,a0,1188 # ffffffffc0202360 <commands+0x6e0>
ffffffffc0200ec4:	ce4ff0ef          	jal	ra,ffffffffc02003a8 <__panic>
    assert(count == 0);
ffffffffc0200ec8:	00001697          	auipc	a3,0x1
ffffffffc0200ecc:	75868693          	addi	a3,a3,1880 # ffffffffc0202620 <commands+0x9a0>
ffffffffc0200ed0:	00001617          	auipc	a2,0x1
ffffffffc0200ed4:	47860613          	addi	a2,a2,1144 # ffffffffc0202348 <commands+0x6c8>
ffffffffc0200ed8:	15100593          	li	a1,337
ffffffffc0200edc:	00001517          	auipc	a0,0x1
ffffffffc0200ee0:	48450513          	addi	a0,a0,1156 # ffffffffc0202360 <commands+0x6e0>
ffffffffc0200ee4:	cc4ff0ef          	jal	ra,ffffffffc02003a8 <__panic>
    assert(nr_free == 0);
ffffffffc0200ee8:	00001697          	auipc	a3,0x1
ffffffffc0200eec:	65068693          	addi	a3,a3,1616 # ffffffffc0202538 <commands+0x8b8>
ffffffffc0200ef0:	00001617          	auipc	a2,0x1
ffffffffc0200ef4:	45860613          	addi	a2,a2,1112 # ffffffffc0202348 <commands+0x6c8>
ffffffffc0200ef8:	14600593          	li	a1,326
ffffffffc0200efc:	00001517          	auipc	a0,0x1
ffffffffc0200f00:	46450513          	addi	a0,a0,1124 # ffffffffc0202360 <commands+0x6e0>
ffffffffc0200f04:	ca4ff0ef          	jal	ra,ffffffffc02003a8 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200f08:	00001697          	auipc	a3,0x1
ffffffffc0200f0c:	5d068693          	addi	a3,a3,1488 # ffffffffc02024d8 <commands+0x858>
ffffffffc0200f10:	00001617          	auipc	a2,0x1
ffffffffc0200f14:	43860613          	addi	a2,a2,1080 # ffffffffc0202348 <commands+0x6c8>
ffffffffc0200f18:	14000593          	li	a1,320
ffffffffc0200f1c:	00001517          	auipc	a0,0x1
ffffffffc0200f20:	44450513          	addi	a0,a0,1092 # ffffffffc0202360 <commands+0x6e0>
ffffffffc0200f24:	c84ff0ef          	jal	ra,ffffffffc02003a8 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200f28:	00001697          	auipc	a3,0x1
ffffffffc0200f2c:	6d868693          	addi	a3,a3,1752 # ffffffffc0202600 <commands+0x980>
ffffffffc0200f30:	00001617          	auipc	a2,0x1
ffffffffc0200f34:	41860613          	addi	a2,a2,1048 # ffffffffc0202348 <commands+0x6c8>
ffffffffc0200f38:	13f00593          	li	a1,319
ffffffffc0200f3c:	00001517          	auipc	a0,0x1
ffffffffc0200f40:	42450513          	addi	a0,a0,1060 # ffffffffc0202360 <commands+0x6e0>
ffffffffc0200f44:	c64ff0ef          	jal	ra,ffffffffc02003a8 <__panic>
    assert(p0 + 4 == p1);
ffffffffc0200f48:	00001697          	auipc	a3,0x1
ffffffffc0200f4c:	6a868693          	addi	a3,a3,1704 # ffffffffc02025f0 <commands+0x970>
ffffffffc0200f50:	00001617          	auipc	a2,0x1
ffffffffc0200f54:	3f860613          	addi	a2,a2,1016 # ffffffffc0202348 <commands+0x6c8>
ffffffffc0200f58:	13700593          	li	a1,311
ffffffffc0200f5c:	00001517          	auipc	a0,0x1
ffffffffc0200f60:	40450513          	addi	a0,a0,1028 # ffffffffc0202360 <commands+0x6e0>
ffffffffc0200f64:	c44ff0ef          	jal	ra,ffffffffc02003a8 <__panic>
    assert(alloc_pages(2) != NULL);      // best fit feature
ffffffffc0200f68:	00001697          	auipc	a3,0x1
ffffffffc0200f6c:	67068693          	addi	a3,a3,1648 # ffffffffc02025d8 <commands+0x958>
ffffffffc0200f70:	00001617          	auipc	a2,0x1
ffffffffc0200f74:	3d860613          	addi	a2,a2,984 # ffffffffc0202348 <commands+0x6c8>
ffffffffc0200f78:	13600593          	li	a1,310
ffffffffc0200f7c:	00001517          	auipc	a0,0x1
ffffffffc0200f80:	3e450513          	addi	a0,a0,996 # ffffffffc0202360 <commands+0x6e0>
ffffffffc0200f84:	c24ff0ef          	jal	ra,ffffffffc02003a8 <__panic>
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc0200f88:	00001697          	auipc	a3,0x1
ffffffffc0200f8c:	63068693          	addi	a3,a3,1584 # ffffffffc02025b8 <commands+0x938>
ffffffffc0200f90:	00001617          	auipc	a2,0x1
ffffffffc0200f94:	3b860613          	addi	a2,a2,952 # ffffffffc0202348 <commands+0x6c8>
ffffffffc0200f98:	13500593          	li	a1,309
ffffffffc0200f9c:	00001517          	auipc	a0,0x1
ffffffffc0200fa0:	3c450513          	addi	a0,a0,964 # ffffffffc0202360 <commands+0x6e0>
ffffffffc0200fa4:	c04ff0ef          	jal	ra,ffffffffc02003a8 <__panic>
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc0200fa8:	00001697          	auipc	a3,0x1
ffffffffc0200fac:	5e068693          	addi	a3,a3,1504 # ffffffffc0202588 <commands+0x908>
ffffffffc0200fb0:	00001617          	auipc	a2,0x1
ffffffffc0200fb4:	39860613          	addi	a2,a2,920 # ffffffffc0202348 <commands+0x6c8>
ffffffffc0200fb8:	13300593          	li	a1,307
ffffffffc0200fbc:	00001517          	auipc	a0,0x1
ffffffffc0200fc0:	3a450513          	addi	a0,a0,932 # ffffffffc0202360 <commands+0x6e0>
ffffffffc0200fc4:	be4ff0ef          	jal	ra,ffffffffc02003a8 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0200fc8:	00001697          	auipc	a3,0x1
ffffffffc0200fcc:	5a868693          	addi	a3,a3,1448 # ffffffffc0202570 <commands+0x8f0>
ffffffffc0200fd0:	00001617          	auipc	a2,0x1
ffffffffc0200fd4:	37860613          	addi	a2,a2,888 # ffffffffc0202348 <commands+0x6c8>
ffffffffc0200fd8:	13200593          	li	a1,306
ffffffffc0200fdc:	00001517          	auipc	a0,0x1
ffffffffc0200fe0:	38450513          	addi	a0,a0,900 # ffffffffc0202360 <commands+0x6e0>
ffffffffc0200fe4:	bc4ff0ef          	jal	ra,ffffffffc02003a8 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200fe8:	00001697          	auipc	a3,0x1
ffffffffc0200fec:	4f068693          	addi	a3,a3,1264 # ffffffffc02024d8 <commands+0x858>
ffffffffc0200ff0:	00001617          	auipc	a2,0x1
ffffffffc0200ff4:	35860613          	addi	a2,a2,856 # ffffffffc0202348 <commands+0x6c8>
ffffffffc0200ff8:	12600593          	li	a1,294
ffffffffc0200ffc:	00001517          	auipc	a0,0x1
ffffffffc0201000:	36450513          	addi	a0,a0,868 # ffffffffc0202360 <commands+0x6e0>
ffffffffc0201004:	ba4ff0ef          	jal	ra,ffffffffc02003a8 <__panic>
    assert(!PageProperty(p0));
ffffffffc0201008:	00001697          	auipc	a3,0x1
ffffffffc020100c:	55068693          	addi	a3,a3,1360 # ffffffffc0202558 <commands+0x8d8>
ffffffffc0201010:	00001617          	auipc	a2,0x1
ffffffffc0201014:	33860613          	addi	a2,a2,824 # ffffffffc0202348 <commands+0x6c8>
ffffffffc0201018:	11d00593          	li	a1,285
ffffffffc020101c:	00001517          	auipc	a0,0x1
ffffffffc0201020:	34450513          	addi	a0,a0,836 # ffffffffc0202360 <commands+0x6e0>
ffffffffc0201024:	b84ff0ef          	jal	ra,ffffffffc02003a8 <__panic>
    assert(p0 != NULL);
ffffffffc0201028:	00001697          	auipc	a3,0x1
ffffffffc020102c:	52068693          	addi	a3,a3,1312 # ffffffffc0202548 <commands+0x8c8>
ffffffffc0201030:	00001617          	auipc	a2,0x1
ffffffffc0201034:	31860613          	addi	a2,a2,792 # ffffffffc0202348 <commands+0x6c8>
ffffffffc0201038:	11c00593          	li	a1,284
ffffffffc020103c:	00001517          	auipc	a0,0x1
ffffffffc0201040:	32450513          	addi	a0,a0,804 # ffffffffc0202360 <commands+0x6e0>
ffffffffc0201044:	b64ff0ef          	jal	ra,ffffffffc02003a8 <__panic>
    assert(nr_free == 0);
ffffffffc0201048:	00001697          	auipc	a3,0x1
ffffffffc020104c:	4f068693          	addi	a3,a3,1264 # ffffffffc0202538 <commands+0x8b8>
ffffffffc0201050:	00001617          	auipc	a2,0x1
ffffffffc0201054:	2f860613          	addi	a2,a2,760 # ffffffffc0202348 <commands+0x6c8>
ffffffffc0201058:	0fe00593          	li	a1,254
ffffffffc020105c:	00001517          	auipc	a0,0x1
ffffffffc0201060:	30450513          	addi	a0,a0,772 # ffffffffc0202360 <commands+0x6e0>
ffffffffc0201064:	b44ff0ef          	jal	ra,ffffffffc02003a8 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201068:	00001697          	auipc	a3,0x1
ffffffffc020106c:	47068693          	addi	a3,a3,1136 # ffffffffc02024d8 <commands+0x858>
ffffffffc0201070:	00001617          	auipc	a2,0x1
ffffffffc0201074:	2d860613          	addi	a2,a2,728 # ffffffffc0202348 <commands+0x6c8>
ffffffffc0201078:	0fc00593          	li	a1,252
ffffffffc020107c:	00001517          	auipc	a0,0x1
ffffffffc0201080:	2e450513          	addi	a0,a0,740 # ffffffffc0202360 <commands+0x6e0>
ffffffffc0201084:	b24ff0ef          	jal	ra,ffffffffc02003a8 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0201088:	00001697          	auipc	a3,0x1
ffffffffc020108c:	49068693          	addi	a3,a3,1168 # ffffffffc0202518 <commands+0x898>
ffffffffc0201090:	00001617          	auipc	a2,0x1
ffffffffc0201094:	2b860613          	addi	a2,a2,696 # ffffffffc0202348 <commands+0x6c8>
ffffffffc0201098:	0fb00593          	li	a1,251
ffffffffc020109c:	00001517          	auipc	a0,0x1
ffffffffc02010a0:	2c450513          	addi	a0,a0,708 # ffffffffc0202360 <commands+0x6e0>
ffffffffc02010a4:	b04ff0ef          	jal	ra,ffffffffc02003a8 <__panic>

ffffffffc02010a8 <best_fit_free_pages>:
best_fit_free_pages(struct Page *base, size_t n) {
ffffffffc02010a8:	1141                	addi	sp,sp,-16
ffffffffc02010aa:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02010ac:	18058063          	beqz	a1,ffffffffc020122c <best_fit_free_pages+0x184>
    for (; p != base + n; p ++) {
ffffffffc02010b0:	00259693          	slli	a3,a1,0x2
ffffffffc02010b4:	96ae                	add	a3,a3,a1
ffffffffc02010b6:	068e                	slli	a3,a3,0x3
ffffffffc02010b8:	96aa                	add	a3,a3,a0
ffffffffc02010ba:	02d50d63          	beq	a0,a3,ffffffffc02010f4 <best_fit_free_pages+0x4c>
ffffffffc02010be:	651c                	ld	a5,8(a0)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02010c0:	8b85                	andi	a5,a5,1
ffffffffc02010c2:	14079563          	bnez	a5,ffffffffc020120c <best_fit_free_pages+0x164>
ffffffffc02010c6:	651c                	ld	a5,8(a0)
ffffffffc02010c8:	8385                	srli	a5,a5,0x1
ffffffffc02010ca:	8b85                	andi	a5,a5,1
ffffffffc02010cc:	14079063          	bnez	a5,ffffffffc020120c <best_fit_free_pages+0x164>
ffffffffc02010d0:	87aa                	mv	a5,a0
ffffffffc02010d2:	a809                	j	ffffffffc02010e4 <best_fit_free_pages+0x3c>
ffffffffc02010d4:	6798                	ld	a4,8(a5)
ffffffffc02010d6:	8b05                	andi	a4,a4,1
ffffffffc02010d8:	12071a63          	bnez	a4,ffffffffc020120c <best_fit_free_pages+0x164>
ffffffffc02010dc:	6798                	ld	a4,8(a5)
ffffffffc02010de:	8b09                	andi	a4,a4,2
ffffffffc02010e0:	12071663          	bnez	a4,ffffffffc020120c <best_fit_free_pages+0x164>
        p->flags = 0;
ffffffffc02010e4:	0007b423          	sd	zero,8(a5)



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc02010e8:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc02010ec:	02878793          	addi	a5,a5,40
ffffffffc02010f0:	fed792e3          	bne	a5,a3,ffffffffc02010d4 <best_fit_free_pages+0x2c>
    base->property = n;
ffffffffc02010f4:	2581                	sext.w	a1,a1
ffffffffc02010f6:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc02010f8:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02010fc:	4789                	li	a5,2
ffffffffc02010fe:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free+=n;
ffffffffc0201102:	00005697          	auipc	a3,0x5
ffffffffc0201106:	33668693          	addi	a3,a3,822 # ffffffffc0206438 <free_area>
ffffffffc020110a:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc020110c:	669c                	ld	a5,8(a3)
ffffffffc020110e:	9db9                	addw	a1,a1,a4
ffffffffc0201110:	00005717          	auipc	a4,0x5
ffffffffc0201114:	32b72c23          	sw	a1,824(a4) # ffffffffc0206448 <free_area+0x10>
    if (list_empty(&free_list)) {
ffffffffc0201118:	08d78f63          	beq	a5,a3,ffffffffc02011b6 <best_fit_free_pages+0x10e>
            struct Page* page = le2page(le, page_link);
ffffffffc020111c:	fe878713          	addi	a4,a5,-24
ffffffffc0201120:	628c                	ld	a1,0(a3)
    if (list_empty(&free_list)) {
ffffffffc0201122:	4801                	li	a6,0
ffffffffc0201124:	01850613          	addi	a2,a0,24
            if (base < page) {
ffffffffc0201128:	00e56a63          	bltu	a0,a4,ffffffffc020113c <best_fit_free_pages+0x94>
    return listelm->next;
ffffffffc020112c:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc020112e:	02d70563          	beq	a4,a3,ffffffffc0201158 <best_fit_free_pages+0xb0>
        while ((le = list_next(le)) != &free_list) {
ffffffffc0201132:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0201134:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc0201138:	fee57ae3          	bleu	a4,a0,ffffffffc020112c <best_fit_free_pages+0x84>
ffffffffc020113c:	00080663          	beqz	a6,ffffffffc0201148 <best_fit_free_pages+0xa0>
ffffffffc0201140:	00005817          	auipc	a6,0x5
ffffffffc0201144:	2eb83c23          	sd	a1,760(a6) # ffffffffc0206438 <free_area>
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201148:	638c                	ld	a1,0(a5)
    prev->next = next->prev = elm;
ffffffffc020114a:	e390                	sd	a2,0(a5)
ffffffffc020114c:	e590                	sd	a2,8(a1)
    elm->next = next;
ffffffffc020114e:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201150:	ed0c                	sd	a1,24(a0)
    if (le != &free_list) {
ffffffffc0201152:	02d59163          	bne	a1,a3,ffffffffc0201174 <best_fit_free_pages+0xcc>
ffffffffc0201156:	a091                	j	ffffffffc020119a <best_fit_free_pages+0xf2>
    prev->next = next->prev = elm;
ffffffffc0201158:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc020115a:	f114                	sd	a3,32(a0)
ffffffffc020115c:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc020115e:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc0201160:	85b2                	mv	a1,a2
        while ((le = list_next(le)) != &free_list) {
ffffffffc0201162:	00d70563          	beq	a4,a3,ffffffffc020116c <best_fit_free_pages+0xc4>
ffffffffc0201166:	4805                	li	a6,1
ffffffffc0201168:	87ba                	mv	a5,a4
ffffffffc020116a:	b7e9                	j	ffffffffc0201134 <best_fit_free_pages+0x8c>
ffffffffc020116c:	e290                	sd	a2,0(a3)
    return listelm->prev;
ffffffffc020116e:	85be                	mv	a1,a5
    if (le != &free_list) {
ffffffffc0201170:	02d78163          	beq	a5,a3,ffffffffc0201192 <best_fit_free_pages+0xea>
        if (p + p->property == base) {
ffffffffc0201174:	ff85a803          	lw	a6,-8(a1)
        p = le2page(le, page_link);
ffffffffc0201178:	fe858613          	addi	a2,a1,-24
        if (p + p->property == base) {
ffffffffc020117c:	02081713          	slli	a4,a6,0x20
ffffffffc0201180:	9301                	srli	a4,a4,0x20
ffffffffc0201182:	00271793          	slli	a5,a4,0x2
ffffffffc0201186:	97ba                	add	a5,a5,a4
ffffffffc0201188:	078e                	slli	a5,a5,0x3
ffffffffc020118a:	97b2                	add	a5,a5,a2
ffffffffc020118c:	02f50e63          	beq	a0,a5,ffffffffc02011c8 <best_fit_free_pages+0x120>
ffffffffc0201190:	711c                	ld	a5,32(a0)
    if (le != &free_list) {
ffffffffc0201192:	fe878713          	addi	a4,a5,-24
ffffffffc0201196:	00d78d63          	beq	a5,a3,ffffffffc02011b0 <best_fit_free_pages+0x108>
        if (base + base->property == p) {
ffffffffc020119a:	490c                	lw	a1,16(a0)
ffffffffc020119c:	02059613          	slli	a2,a1,0x20
ffffffffc02011a0:	9201                	srli	a2,a2,0x20
ffffffffc02011a2:	00261693          	slli	a3,a2,0x2
ffffffffc02011a6:	96b2                	add	a3,a3,a2
ffffffffc02011a8:	068e                	slli	a3,a3,0x3
ffffffffc02011aa:	96aa                	add	a3,a3,a0
ffffffffc02011ac:	04d70063          	beq	a4,a3,ffffffffc02011ec <best_fit_free_pages+0x144>
}
ffffffffc02011b0:	60a2                	ld	ra,8(sp)
ffffffffc02011b2:	0141                	addi	sp,sp,16
ffffffffc02011b4:	8082                	ret
ffffffffc02011b6:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc02011b8:	01850713          	addi	a4,a0,24
    prev->next = next->prev = elm;
ffffffffc02011bc:	e398                	sd	a4,0(a5)
ffffffffc02011be:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc02011c0:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02011c2:	ed1c                	sd	a5,24(a0)
}
ffffffffc02011c4:	0141                	addi	sp,sp,16
ffffffffc02011c6:	8082                	ret
            p->property += base->property;
ffffffffc02011c8:	491c                	lw	a5,16(a0)
ffffffffc02011ca:	0107883b          	addw	a6,a5,a6
ffffffffc02011ce:	ff05ac23          	sw	a6,-8(a1)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02011d2:	57f5                	li	a5,-3
ffffffffc02011d4:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc02011d8:	01853803          	ld	a6,24(a0)
ffffffffc02011dc:	7118                	ld	a4,32(a0)
            base = p;
ffffffffc02011de:	8532                	mv	a0,a2
    prev->next = next;
ffffffffc02011e0:	00e83423          	sd	a4,8(a6)
    next->prev = prev;
ffffffffc02011e4:	659c                	ld	a5,8(a1)
ffffffffc02011e6:	01073023          	sd	a6,0(a4)
ffffffffc02011ea:	b765                	j	ffffffffc0201192 <best_fit_free_pages+0xea>
            base->property += p->property;
ffffffffc02011ec:	ff87a703          	lw	a4,-8(a5)
ffffffffc02011f0:	ff078693          	addi	a3,a5,-16
ffffffffc02011f4:	9db9                	addw	a1,a1,a4
ffffffffc02011f6:	c90c                	sw	a1,16(a0)
ffffffffc02011f8:	5775                	li	a4,-3
ffffffffc02011fa:	60e6b02f          	amoand.d	zero,a4,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc02011fe:	6398                	ld	a4,0(a5)
ffffffffc0201200:	679c                	ld	a5,8(a5)
}
ffffffffc0201202:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0201204:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0201206:	e398                	sd	a4,0(a5)
ffffffffc0201208:	0141                	addi	sp,sp,16
ffffffffc020120a:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc020120c:	00001697          	auipc	a3,0x1
ffffffffc0201210:	43468693          	addi	a3,a3,1076 # ffffffffc0202640 <commands+0x9c0>
ffffffffc0201214:	00001617          	auipc	a2,0x1
ffffffffc0201218:	13460613          	addi	a2,a2,308 # ffffffffc0202348 <commands+0x6c8>
ffffffffc020121c:	09300593          	li	a1,147
ffffffffc0201220:	00001517          	auipc	a0,0x1
ffffffffc0201224:	14050513          	addi	a0,a0,320 # ffffffffc0202360 <commands+0x6e0>
ffffffffc0201228:	980ff0ef          	jal	ra,ffffffffc02003a8 <__panic>
    assert(n > 0);
ffffffffc020122c:	00001697          	auipc	a3,0x1
ffffffffc0201230:	11468693          	addi	a3,a3,276 # ffffffffc0202340 <commands+0x6c0>
ffffffffc0201234:	00001617          	auipc	a2,0x1
ffffffffc0201238:	11460613          	addi	a2,a2,276 # ffffffffc0202348 <commands+0x6c8>
ffffffffc020123c:	09000593          	li	a1,144
ffffffffc0201240:	00001517          	auipc	a0,0x1
ffffffffc0201244:	12050513          	addi	a0,a0,288 # ffffffffc0202360 <commands+0x6e0>
ffffffffc0201248:	960ff0ef          	jal	ra,ffffffffc02003a8 <__panic>

ffffffffc020124c <best_fit_init_memmap>:
best_fit_init_memmap(struct Page *base, size_t n) {
ffffffffc020124c:	1141                	addi	sp,sp,-16
ffffffffc020124e:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201250:	c5f5                	beqz	a1,ffffffffc020133c <best_fit_init_memmap+0xf0>
    for (; p != base + n; p ++) {
ffffffffc0201252:	00259693          	slli	a3,a1,0x2
ffffffffc0201256:	96ae                	add	a3,a3,a1
ffffffffc0201258:	068e                	slli	a3,a3,0x3
ffffffffc020125a:	96aa                	add	a3,a3,a0
ffffffffc020125c:	02d50463          	beq	a0,a3,ffffffffc0201284 <best_fit_init_memmap+0x38>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0201260:	6518                	ld	a4,8(a0)
        assert(PageReserved(p));
ffffffffc0201262:	87aa                	mv	a5,a0
ffffffffc0201264:	8b05                	andi	a4,a4,1
ffffffffc0201266:	e709                	bnez	a4,ffffffffc0201270 <best_fit_init_memmap+0x24>
ffffffffc0201268:	a855                	j	ffffffffc020131c <best_fit_init_memmap+0xd0>
ffffffffc020126a:	6798                	ld	a4,8(a5)
ffffffffc020126c:	8b05                	andi	a4,a4,1
ffffffffc020126e:	c75d                	beqz	a4,ffffffffc020131c <best_fit_init_memmap+0xd0>
        p->flags = p->property = 0;
ffffffffc0201270:	0007a823          	sw	zero,16(a5)
ffffffffc0201274:	0007b423          	sd	zero,8(a5)
ffffffffc0201278:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc020127c:	02878793          	addi	a5,a5,40
ffffffffc0201280:	fed795e3          	bne	a5,a3,ffffffffc020126a <best_fit_init_memmap+0x1e>
    base->property = n;
ffffffffc0201284:	2581                	sext.w	a1,a1
ffffffffc0201286:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201288:	4789                	li	a5,2
ffffffffc020128a:	00850713          	addi	a4,a0,8
ffffffffc020128e:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc0201292:	00005617          	auipc	a2,0x5
ffffffffc0201296:	1a660613          	addi	a2,a2,422 # ffffffffc0206438 <free_area>
ffffffffc020129a:	4a18                	lw	a4,16(a2)
    return list->next == list;
ffffffffc020129c:	661c                	ld	a5,8(a2)
ffffffffc020129e:	9db9                	addw	a1,a1,a4
ffffffffc02012a0:	00005717          	auipc	a4,0x5
ffffffffc02012a4:	1ab72423          	sw	a1,424(a4) # ffffffffc0206448 <free_area+0x10>
    if (list_empty(&free_list)) {
ffffffffc02012a8:	04c78d63          	beq	a5,a2,ffffffffc0201302 <best_fit_init_memmap+0xb6>
            struct Page* page = le2page(le, page_link);
ffffffffc02012ac:	fe878713          	addi	a4,a5,-24
ffffffffc02012b0:	00063803          	ld	a6,0(a2)
    if (list_empty(&free_list)) {
ffffffffc02012b4:	4881                	li	a7,0
                list_add(le, &(p->page_link));
ffffffffc02012b6:	01868593          	addi	a1,a3,24
            if (base < page) {
ffffffffc02012ba:	00e56a63          	bltu	a0,a4,ffffffffc02012ce <best_fit_init_memmap+0x82>
    return listelm->next;
ffffffffc02012be:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc02012c0:	02c70763          	beq	a4,a2,ffffffffc02012ee <best_fit_init_memmap+0xa2>
        while ((le = list_next(le)) != &free_list) {
ffffffffc02012c4:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc02012c6:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc02012ca:	fee57ae3          	bleu	a4,a0,ffffffffc02012be <best_fit_init_memmap+0x72>
ffffffffc02012ce:	00088663          	beqz	a7,ffffffffc02012da <best_fit_init_memmap+0x8e>
ffffffffc02012d2:	00005717          	auipc	a4,0x5
ffffffffc02012d6:	17073323          	sd	a6,358(a4) # ffffffffc0206438 <free_area>
    __list_add(elm, listelm->prev, listelm);
ffffffffc02012da:	6398                	ld	a4,0(a5)
                list_add_before(le, &(base->page_link));
ffffffffc02012dc:	01850693          	addi	a3,a0,24
    prev->next = next->prev = elm;
ffffffffc02012e0:	e394                	sd	a3,0(a5)
}
ffffffffc02012e2:	60a2                	ld	ra,8(sp)
ffffffffc02012e4:	e714                	sd	a3,8(a4)
    elm->next = next;
ffffffffc02012e6:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02012e8:	ed18                	sd	a4,24(a0)
ffffffffc02012ea:	0141                	addi	sp,sp,16
ffffffffc02012ec:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc02012ee:	e78c                	sd	a1,8(a5)
    elm->next = next;
ffffffffc02012f0:	f290                	sd	a2,32(a3)
ffffffffc02012f2:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc02012f4:	ee9c                	sd	a5,24(a3)
                list_add(le, &(p->page_link));
ffffffffc02012f6:	882e                	mv	a6,a1
        while ((le = list_next(le)) != &free_list) {
ffffffffc02012f8:	00c70e63          	beq	a4,a2,ffffffffc0201314 <best_fit_init_memmap+0xc8>
ffffffffc02012fc:	4885                	li	a7,1
ffffffffc02012fe:	87ba                	mv	a5,a4
ffffffffc0201300:	b7d9                	j	ffffffffc02012c6 <best_fit_init_memmap+0x7a>
}
ffffffffc0201302:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc0201304:	01850713          	addi	a4,a0,24
    prev->next = next->prev = elm;
ffffffffc0201308:	e398                	sd	a4,0(a5)
ffffffffc020130a:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc020130c:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020130e:	ed1c                	sd	a5,24(a0)
}
ffffffffc0201310:	0141                	addi	sp,sp,16
ffffffffc0201312:	8082                	ret
ffffffffc0201314:	60a2                	ld	ra,8(sp)
ffffffffc0201316:	e20c                	sd	a1,0(a2)
ffffffffc0201318:	0141                	addi	sp,sp,16
ffffffffc020131a:	8082                	ret
        assert(PageReserved(p));
ffffffffc020131c:	00001697          	auipc	a3,0x1
ffffffffc0201320:	34c68693          	addi	a3,a3,844 # ffffffffc0202668 <commands+0x9e8>
ffffffffc0201324:	00001617          	auipc	a2,0x1
ffffffffc0201328:	02460613          	addi	a2,a2,36 # ffffffffc0202348 <commands+0x6c8>
ffffffffc020132c:	04a00593          	li	a1,74
ffffffffc0201330:	00001517          	auipc	a0,0x1
ffffffffc0201334:	03050513          	addi	a0,a0,48 # ffffffffc0202360 <commands+0x6e0>
ffffffffc0201338:	870ff0ef          	jal	ra,ffffffffc02003a8 <__panic>
    assert(n > 0);
ffffffffc020133c:	00001697          	auipc	a3,0x1
ffffffffc0201340:	00468693          	addi	a3,a3,4 # ffffffffc0202340 <commands+0x6c0>
ffffffffc0201344:	00001617          	auipc	a2,0x1
ffffffffc0201348:	00460613          	addi	a2,a2,4 # ffffffffc0202348 <commands+0x6c8>
ffffffffc020134c:	04700593          	li	a1,71
ffffffffc0201350:	00001517          	auipc	a0,0x1
ffffffffc0201354:	01050513          	addi	a0,a0,16 # ffffffffc0202360 <commands+0x6e0>
ffffffffc0201358:	850ff0ef          	jal	ra,ffffffffc02003a8 <__panic>

ffffffffc020135c <alloc_pages>:
#include <defs.h>
#include <intr.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020135c:	100027f3          	csrr	a5,sstatus
ffffffffc0201360:	8b89                	andi	a5,a5,2
ffffffffc0201362:	eb89                	bnez	a5,ffffffffc0201374 <alloc_pages+0x18>
struct Page *alloc_pages(size_t n) {
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc0201364:	00005797          	auipc	a5,0x5
ffffffffc0201368:	0f478793          	addi	a5,a5,244 # ffffffffc0206458 <pmm_manager>
ffffffffc020136c:	639c                	ld	a5,0(a5)
ffffffffc020136e:	0187b303          	ld	t1,24(a5)
ffffffffc0201372:	8302                	jr	t1
struct Page *alloc_pages(size_t n) {
ffffffffc0201374:	1141                	addi	sp,sp,-16
ffffffffc0201376:	e406                	sd	ra,8(sp)
ffffffffc0201378:	e022                	sd	s0,0(sp)
ffffffffc020137a:	842a                	mv	s0,a0
        intr_disable();
ffffffffc020137c:	8e4ff0ef          	jal	ra,ffffffffc0200460 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201380:	00005797          	auipc	a5,0x5
ffffffffc0201384:	0d878793          	addi	a5,a5,216 # ffffffffc0206458 <pmm_manager>
ffffffffc0201388:	639c                	ld	a5,0(a5)
ffffffffc020138a:	8522                	mv	a0,s0
ffffffffc020138c:	6f9c                	ld	a5,24(a5)
ffffffffc020138e:	9782                	jalr	a5
ffffffffc0201390:	842a                	mv	s0,a0
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
        intr_enable();
ffffffffc0201392:	8c8ff0ef          	jal	ra,ffffffffc020045a <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc0201396:	8522                	mv	a0,s0
ffffffffc0201398:	60a2                	ld	ra,8(sp)
ffffffffc020139a:	6402                	ld	s0,0(sp)
ffffffffc020139c:	0141                	addi	sp,sp,16
ffffffffc020139e:	8082                	ret

ffffffffc02013a0 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02013a0:	100027f3          	csrr	a5,sstatus
ffffffffc02013a4:	8b89                	andi	a5,a5,2
ffffffffc02013a6:	eb89                	bnez	a5,ffffffffc02013b8 <free_pages+0x18>
// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc02013a8:	00005797          	auipc	a5,0x5
ffffffffc02013ac:	0b078793          	addi	a5,a5,176 # ffffffffc0206458 <pmm_manager>
ffffffffc02013b0:	639c                	ld	a5,0(a5)
ffffffffc02013b2:	0207b303          	ld	t1,32(a5)
ffffffffc02013b6:	8302                	jr	t1
void free_pages(struct Page *base, size_t n) {
ffffffffc02013b8:	1101                	addi	sp,sp,-32
ffffffffc02013ba:	ec06                	sd	ra,24(sp)
ffffffffc02013bc:	e822                	sd	s0,16(sp)
ffffffffc02013be:	e426                	sd	s1,8(sp)
ffffffffc02013c0:	842a                	mv	s0,a0
ffffffffc02013c2:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc02013c4:	89cff0ef          	jal	ra,ffffffffc0200460 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02013c8:	00005797          	auipc	a5,0x5
ffffffffc02013cc:	09078793          	addi	a5,a5,144 # ffffffffc0206458 <pmm_manager>
ffffffffc02013d0:	639c                	ld	a5,0(a5)
ffffffffc02013d2:	85a6                	mv	a1,s1
ffffffffc02013d4:	8522                	mv	a0,s0
ffffffffc02013d6:	739c                	ld	a5,32(a5)
ffffffffc02013d8:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc02013da:	6442                	ld	s0,16(sp)
ffffffffc02013dc:	60e2                	ld	ra,24(sp)
ffffffffc02013de:	64a2                	ld	s1,8(sp)
ffffffffc02013e0:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc02013e2:	878ff06f          	j	ffffffffc020045a <intr_enable>

ffffffffc02013e6 <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02013e6:	100027f3          	csrr	a5,sstatus
ffffffffc02013ea:	8b89                	andi	a5,a5,2
ffffffffc02013ec:	eb89                	bnez	a5,ffffffffc02013fe <nr_free_pages+0x18>
size_t nr_free_pages(void) {
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc02013ee:	00005797          	auipc	a5,0x5
ffffffffc02013f2:	06a78793          	addi	a5,a5,106 # ffffffffc0206458 <pmm_manager>
ffffffffc02013f6:	639c                	ld	a5,0(a5)
ffffffffc02013f8:	0287b303          	ld	t1,40(a5)
ffffffffc02013fc:	8302                	jr	t1
size_t nr_free_pages(void) {
ffffffffc02013fe:	1141                	addi	sp,sp,-16
ffffffffc0201400:	e406                	sd	ra,8(sp)
ffffffffc0201402:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc0201404:	85cff0ef          	jal	ra,ffffffffc0200460 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201408:	00005797          	auipc	a5,0x5
ffffffffc020140c:	05078793          	addi	a5,a5,80 # ffffffffc0206458 <pmm_manager>
ffffffffc0201410:	639c                	ld	a5,0(a5)
ffffffffc0201412:	779c                	ld	a5,40(a5)
ffffffffc0201414:	9782                	jalr	a5
ffffffffc0201416:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201418:	842ff0ef          	jal	ra,ffffffffc020045a <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc020141c:	8522                	mv	a0,s0
ffffffffc020141e:	60a2                	ld	ra,8(sp)
ffffffffc0201420:	6402                	ld	s0,0(sp)
ffffffffc0201422:	0141                	addi	sp,sp,16
ffffffffc0201424:	8082                	ret

ffffffffc0201426 <pmm_init>:
    pmm_manager = &best_fit_pmm_manager;
ffffffffc0201426:	00001797          	auipc	a5,0x1
ffffffffc020142a:	25278793          	addi	a5,a5,594 # ffffffffc0202678 <best_fit_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020142e:	638c                	ld	a1,0(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc0201430:	1101                	addi	sp,sp,-32
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201432:	00001517          	auipc	a0,0x1
ffffffffc0201436:	29650513          	addi	a0,a0,662 # ffffffffc02026c8 <best_fit_pmm_manager+0x50>
void pmm_init(void) {
ffffffffc020143a:	ec06                	sd	ra,24(sp)
    pmm_manager = &best_fit_pmm_manager;
ffffffffc020143c:	00005717          	auipc	a4,0x5
ffffffffc0201440:	00f73e23          	sd	a5,28(a4) # ffffffffc0206458 <pmm_manager>
void pmm_init(void) {
ffffffffc0201444:	e822                	sd	s0,16(sp)
ffffffffc0201446:	e426                	sd	s1,8(sp)
    pmm_manager = &best_fit_pmm_manager;
ffffffffc0201448:	00005417          	auipc	s0,0x5
ffffffffc020144c:	01040413          	addi	s0,s0,16 # ffffffffc0206458 <pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201450:	c63fe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    pmm_manager->init();
ffffffffc0201454:	601c                	ld	a5,0(s0)
ffffffffc0201456:	679c                	ld	a5,8(a5)
ffffffffc0201458:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc020145a:	57f5                	li	a5,-3
ffffffffc020145c:	07fa                	slli	a5,a5,0x1e
    cprintf("physcial memory map:\n");
ffffffffc020145e:	00001517          	auipc	a0,0x1
ffffffffc0201462:	28250513          	addi	a0,a0,642 # ffffffffc02026e0 <best_fit_pmm_manager+0x68>
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0201466:	00005717          	auipc	a4,0x5
ffffffffc020146a:	fef73d23          	sd	a5,-6(a4) # ffffffffc0206460 <va_pa_offset>
    cprintf("physcial memory map:\n");
ffffffffc020146e:	c45fe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc0201472:	46c5                	li	a3,17
ffffffffc0201474:	06ee                	slli	a3,a3,0x1b
ffffffffc0201476:	40100613          	li	a2,1025
ffffffffc020147a:	16fd                	addi	a3,a3,-1
ffffffffc020147c:	0656                	slli	a2,a2,0x15
ffffffffc020147e:	07e005b7          	lui	a1,0x7e00
ffffffffc0201482:	00001517          	auipc	a0,0x1
ffffffffc0201486:	27650513          	addi	a0,a0,630 # ffffffffc02026f8 <best_fit_pmm_manager+0x80>
ffffffffc020148a:	c29fe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc020148e:	777d                	lui	a4,0xfffff
ffffffffc0201490:	00006797          	auipc	a5,0x6
ffffffffc0201494:	fdf78793          	addi	a5,a5,-33 # ffffffffc020746f <end+0xfff>
ffffffffc0201498:	8ff9                	and	a5,a5,a4
    npage = maxpa / PGSIZE;
ffffffffc020149a:	00088737          	lui	a4,0x88
ffffffffc020149e:	00005697          	auipc	a3,0x5
ffffffffc02014a2:	f6e6bd23          	sd	a4,-134(a3) # ffffffffc0206418 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02014a6:	4601                	li	a2,0
ffffffffc02014a8:	00005717          	auipc	a4,0x5
ffffffffc02014ac:	fcf73023          	sd	a5,-64(a4) # ffffffffc0206468 <pages>
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc02014b0:	4681                	li	a3,0
ffffffffc02014b2:	00005897          	auipc	a7,0x5
ffffffffc02014b6:	f6688893          	addi	a7,a7,-154 # ffffffffc0206418 <npage>
ffffffffc02014ba:	00005597          	auipc	a1,0x5
ffffffffc02014be:	fae58593          	addi	a1,a1,-82 # ffffffffc0206468 <pages>
ffffffffc02014c2:	4805                	li	a6,1
ffffffffc02014c4:	fff80537          	lui	a0,0xfff80
ffffffffc02014c8:	a011                	j	ffffffffc02014cc <pmm_init+0xa6>
ffffffffc02014ca:	619c                	ld	a5,0(a1)
        SetPageReserved(pages + i);
ffffffffc02014cc:	97b2                	add	a5,a5,a2
ffffffffc02014ce:	07a1                	addi	a5,a5,8
ffffffffc02014d0:	4107b02f          	amoor.d	zero,a6,(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc02014d4:	0008b703          	ld	a4,0(a7)
ffffffffc02014d8:	0685                	addi	a3,a3,1
ffffffffc02014da:	02860613          	addi	a2,a2,40
ffffffffc02014de:	00a707b3          	add	a5,a4,a0
ffffffffc02014e2:	fef6e4e3          	bltu	a3,a5,ffffffffc02014ca <pmm_init+0xa4>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02014e6:	6190                	ld	a2,0(a1)
ffffffffc02014e8:	00271793          	slli	a5,a4,0x2
ffffffffc02014ec:	97ba                	add	a5,a5,a4
ffffffffc02014ee:	fec006b7          	lui	a3,0xfec00
ffffffffc02014f2:	078e                	slli	a5,a5,0x3
ffffffffc02014f4:	96b2                	add	a3,a3,a2
ffffffffc02014f6:	96be                	add	a3,a3,a5
ffffffffc02014f8:	c02007b7          	lui	a5,0xc0200
ffffffffc02014fc:	08f6e863          	bltu	a3,a5,ffffffffc020158c <pmm_init+0x166>
ffffffffc0201500:	00005497          	auipc	s1,0x5
ffffffffc0201504:	f6048493          	addi	s1,s1,-160 # ffffffffc0206460 <va_pa_offset>
ffffffffc0201508:	609c                	ld	a5,0(s1)
    if (freemem < mem_end) {
ffffffffc020150a:	45c5                	li	a1,17
ffffffffc020150c:	05ee                	slli	a1,a1,0x1b
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020150e:	8e9d                	sub	a3,a3,a5
    if (freemem < mem_end) {
ffffffffc0201510:	04b6e963          	bltu	a3,a1,ffffffffc0201562 <pmm_init+0x13c>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc0201514:	601c                	ld	a5,0(s0)
ffffffffc0201516:	7b9c                	ld	a5,48(a5)
ffffffffc0201518:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc020151a:	00001517          	auipc	a0,0x1
ffffffffc020151e:	27650513          	addi	a0,a0,630 # ffffffffc0202790 <best_fit_pmm_manager+0x118>
ffffffffc0201522:	b91fe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc0201526:	00004697          	auipc	a3,0x4
ffffffffc020152a:	ada68693          	addi	a3,a3,-1318 # ffffffffc0205000 <boot_page_table_sv39>
ffffffffc020152e:	00005797          	auipc	a5,0x5
ffffffffc0201532:	eed7b923          	sd	a3,-270(a5) # ffffffffc0206420 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc0201536:	c02007b7          	lui	a5,0xc0200
ffffffffc020153a:	06f6e563          	bltu	a3,a5,ffffffffc02015a4 <pmm_init+0x17e>
ffffffffc020153e:	609c                	ld	a5,0(s1)
}
ffffffffc0201540:	6442                	ld	s0,16(sp)
ffffffffc0201542:	60e2                	ld	ra,24(sp)
ffffffffc0201544:	64a2                	ld	s1,8(sp)
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0201546:	85b6                	mv	a1,a3
    satp_physical = PADDR(satp_virtual);
ffffffffc0201548:	8e9d                	sub	a3,a3,a5
ffffffffc020154a:	00005797          	auipc	a5,0x5
ffffffffc020154e:	f0d7b323          	sd	a3,-250(a5) # ffffffffc0206450 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0201552:	00001517          	auipc	a0,0x1
ffffffffc0201556:	25e50513          	addi	a0,a0,606 # ffffffffc02027b0 <best_fit_pmm_manager+0x138>
ffffffffc020155a:	8636                	mv	a2,a3
}
ffffffffc020155c:	6105                	addi	sp,sp,32
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc020155e:	b55fe06f          	j	ffffffffc02000b2 <cprintf>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0201562:	6785                	lui	a5,0x1
ffffffffc0201564:	17fd                	addi	a5,a5,-1
ffffffffc0201566:	96be                	add	a3,a3,a5
ffffffffc0201568:	77fd                	lui	a5,0xfffff
ffffffffc020156a:	8efd                	and	a3,a3,a5
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc020156c:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201570:	04e7f663          	bleu	a4,a5,ffffffffc02015bc <pmm_init+0x196>
    pmm_manager->init_memmap(base, n);
ffffffffc0201574:	6018                	ld	a4,0(s0)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc0201576:	97aa                	add	a5,a5,a0
ffffffffc0201578:	00279513          	slli	a0,a5,0x2
ffffffffc020157c:	953e                	add	a0,a0,a5
ffffffffc020157e:	6b1c                	ld	a5,16(a4)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0201580:	8d95                	sub	a1,a1,a3
ffffffffc0201582:	050e                	slli	a0,a0,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc0201584:	81b1                	srli	a1,a1,0xc
ffffffffc0201586:	9532                	add	a0,a0,a2
ffffffffc0201588:	9782                	jalr	a5
ffffffffc020158a:	b769                	j	ffffffffc0201514 <pmm_init+0xee>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020158c:	00001617          	auipc	a2,0x1
ffffffffc0201590:	19c60613          	addi	a2,a2,412 # ffffffffc0202728 <best_fit_pmm_manager+0xb0>
ffffffffc0201594:	07000593          	li	a1,112
ffffffffc0201598:	00001517          	auipc	a0,0x1
ffffffffc020159c:	1b850513          	addi	a0,a0,440 # ffffffffc0202750 <best_fit_pmm_manager+0xd8>
ffffffffc02015a0:	e09fe0ef          	jal	ra,ffffffffc02003a8 <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc02015a4:	00001617          	auipc	a2,0x1
ffffffffc02015a8:	18460613          	addi	a2,a2,388 # ffffffffc0202728 <best_fit_pmm_manager+0xb0>
ffffffffc02015ac:	08b00593          	li	a1,139
ffffffffc02015b0:	00001517          	auipc	a0,0x1
ffffffffc02015b4:	1a050513          	addi	a0,a0,416 # ffffffffc0202750 <best_fit_pmm_manager+0xd8>
ffffffffc02015b8:	df1fe0ef          	jal	ra,ffffffffc02003a8 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02015bc:	00001617          	auipc	a2,0x1
ffffffffc02015c0:	1a460613          	addi	a2,a2,420 # ffffffffc0202760 <best_fit_pmm_manager+0xe8>
ffffffffc02015c4:	06b00593          	li	a1,107
ffffffffc02015c8:	00001517          	auipc	a0,0x1
ffffffffc02015cc:	1b850513          	addi	a0,a0,440 # ffffffffc0202780 <best_fit_pmm_manager+0x108>
ffffffffc02015d0:	dd9fe0ef          	jal	ra,ffffffffc02003a8 <__panic>

ffffffffc02015d4 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc02015d4:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02015d8:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc02015da:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02015de:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc02015e0:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02015e4:	f022                	sd	s0,32(sp)
ffffffffc02015e6:	ec26                	sd	s1,24(sp)
ffffffffc02015e8:	e84a                	sd	s2,16(sp)
ffffffffc02015ea:	f406                	sd	ra,40(sp)
ffffffffc02015ec:	e44e                	sd	s3,8(sp)
ffffffffc02015ee:	84aa                	mv	s1,a0
ffffffffc02015f0:	892e                	mv	s2,a1
ffffffffc02015f2:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc02015f6:	2a01                	sext.w	s4,s4

    // first recursively print all preceding (more significant) digits
    if (num >= base) {
ffffffffc02015f8:	03067e63          	bleu	a6,a2,ffffffffc0201634 <printnum+0x60>
ffffffffc02015fc:	89be                	mv	s3,a5
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc02015fe:	00805763          	blez	s0,ffffffffc020160c <printnum+0x38>
ffffffffc0201602:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0201604:	85ca                	mv	a1,s2
ffffffffc0201606:	854e                	mv	a0,s3
ffffffffc0201608:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc020160a:	fc65                	bnez	s0,ffffffffc0201602 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020160c:	1a02                	slli	s4,s4,0x20
ffffffffc020160e:	020a5a13          	srli	s4,s4,0x20
ffffffffc0201612:	00001797          	auipc	a5,0x1
ffffffffc0201616:	36e78793          	addi	a5,a5,878 # ffffffffc0202980 <error_string+0x38>
ffffffffc020161a:	9a3e                	add	s4,s4,a5
}
ffffffffc020161c:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020161e:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0201622:	70a2                	ld	ra,40(sp)
ffffffffc0201624:	69a2                	ld	s3,8(sp)
ffffffffc0201626:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201628:	85ca                	mv	a1,s2
ffffffffc020162a:	8326                	mv	t1,s1
}
ffffffffc020162c:	6942                	ld	s2,16(sp)
ffffffffc020162e:	64e2                	ld	s1,24(sp)
ffffffffc0201630:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201632:	8302                	jr	t1
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0201634:	03065633          	divu	a2,a2,a6
ffffffffc0201638:	8722                	mv	a4,s0
ffffffffc020163a:	f9bff0ef          	jal	ra,ffffffffc02015d4 <printnum>
ffffffffc020163e:	b7f9                	j	ffffffffc020160c <printnum+0x38>

ffffffffc0201640 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0201640:	7119                	addi	sp,sp,-128
ffffffffc0201642:	f4a6                	sd	s1,104(sp)
ffffffffc0201644:	f0ca                	sd	s2,96(sp)
ffffffffc0201646:	e8d2                	sd	s4,80(sp)
ffffffffc0201648:	e4d6                	sd	s5,72(sp)
ffffffffc020164a:	e0da                	sd	s6,64(sp)
ffffffffc020164c:	fc5e                	sd	s7,56(sp)
ffffffffc020164e:	f862                	sd	s8,48(sp)
ffffffffc0201650:	f06a                	sd	s10,32(sp)
ffffffffc0201652:	fc86                	sd	ra,120(sp)
ffffffffc0201654:	f8a2                	sd	s0,112(sp)
ffffffffc0201656:	ecce                	sd	s3,88(sp)
ffffffffc0201658:	f466                	sd	s9,40(sp)
ffffffffc020165a:	ec6e                	sd	s11,24(sp)
ffffffffc020165c:	892a                	mv	s2,a0
ffffffffc020165e:	84ae                	mv	s1,a1
ffffffffc0201660:	8d32                	mv	s10,a2
ffffffffc0201662:	8ab6                	mv	s5,a3
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0201664:	5b7d                	li	s6,-1
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201666:	00001a17          	auipc	s4,0x1
ffffffffc020166a:	18aa0a13          	addi	s4,s4,394 # ffffffffc02027f0 <best_fit_pmm_manager+0x178>
                for (width -= strnlen(p, precision); width > 0; width --) {
                    putch(padc, putdat);
                }
            }
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020166e:	05e00b93          	li	s7,94
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201672:	00001c17          	auipc	s8,0x1
ffffffffc0201676:	2d6c0c13          	addi	s8,s8,726 # ffffffffc0202948 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020167a:	000d4503          	lbu	a0,0(s10)
ffffffffc020167e:	02500793          	li	a5,37
ffffffffc0201682:	001d0413          	addi	s0,s10,1
ffffffffc0201686:	00f50e63          	beq	a0,a5,ffffffffc02016a2 <vprintfmt+0x62>
            if (ch == '\0') {
ffffffffc020168a:	c521                	beqz	a0,ffffffffc02016d2 <vprintfmt+0x92>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020168c:	02500993          	li	s3,37
ffffffffc0201690:	a011                	j	ffffffffc0201694 <vprintfmt+0x54>
            if (ch == '\0') {
ffffffffc0201692:	c121                	beqz	a0,ffffffffc02016d2 <vprintfmt+0x92>
            putch(ch, putdat);
ffffffffc0201694:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201696:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0201698:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020169a:	fff44503          	lbu	a0,-1(s0)
ffffffffc020169e:	ff351ae3          	bne	a0,s3,ffffffffc0201692 <vprintfmt+0x52>
ffffffffc02016a2:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc02016a6:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc02016aa:	4981                	li	s3,0
ffffffffc02016ac:	4801                	li	a6,0
        width = precision = -1;
ffffffffc02016ae:	5cfd                	li	s9,-1
ffffffffc02016b0:	5dfd                	li	s11,-1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02016b2:	05500593          	li	a1,85
                if (ch < '0' || ch > '9') {
ffffffffc02016b6:	4525                	li	a0,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02016b8:	fdd6069b          	addiw	a3,a2,-35
ffffffffc02016bc:	0ff6f693          	andi	a3,a3,255
ffffffffc02016c0:	00140d13          	addi	s10,s0,1
ffffffffc02016c4:	20d5e563          	bltu	a1,a3,ffffffffc02018ce <vprintfmt+0x28e>
ffffffffc02016c8:	068a                	slli	a3,a3,0x2
ffffffffc02016ca:	96d2                	add	a3,a3,s4
ffffffffc02016cc:	4294                	lw	a3,0(a3)
ffffffffc02016ce:	96d2                	add	a3,a3,s4
ffffffffc02016d0:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc02016d2:	70e6                	ld	ra,120(sp)
ffffffffc02016d4:	7446                	ld	s0,112(sp)
ffffffffc02016d6:	74a6                	ld	s1,104(sp)
ffffffffc02016d8:	7906                	ld	s2,96(sp)
ffffffffc02016da:	69e6                	ld	s3,88(sp)
ffffffffc02016dc:	6a46                	ld	s4,80(sp)
ffffffffc02016de:	6aa6                	ld	s5,72(sp)
ffffffffc02016e0:	6b06                	ld	s6,64(sp)
ffffffffc02016e2:	7be2                	ld	s7,56(sp)
ffffffffc02016e4:	7c42                	ld	s8,48(sp)
ffffffffc02016e6:	7ca2                	ld	s9,40(sp)
ffffffffc02016e8:	7d02                	ld	s10,32(sp)
ffffffffc02016ea:	6de2                	ld	s11,24(sp)
ffffffffc02016ec:	6109                	addi	sp,sp,128
ffffffffc02016ee:	8082                	ret
    if (lflag >= 2) {
ffffffffc02016f0:	4705                	li	a4,1
ffffffffc02016f2:	008a8593          	addi	a1,s5,8
ffffffffc02016f6:	01074463          	blt	a4,a6,ffffffffc02016fe <vprintfmt+0xbe>
    else if (lflag) {
ffffffffc02016fa:	26080363          	beqz	a6,ffffffffc0201960 <vprintfmt+0x320>
        return va_arg(*ap, unsigned long);
ffffffffc02016fe:	000ab603          	ld	a2,0(s5)
ffffffffc0201702:	46c1                	li	a3,16
ffffffffc0201704:	8aae                	mv	s5,a1
ffffffffc0201706:	a06d                	j	ffffffffc02017b0 <vprintfmt+0x170>
            goto reswitch;
ffffffffc0201708:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc020170c:	4985                	li	s3,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020170e:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201710:	b765                	j	ffffffffc02016b8 <vprintfmt+0x78>
            putch(va_arg(ap, int), putdat);
ffffffffc0201712:	000aa503          	lw	a0,0(s5)
ffffffffc0201716:	85a6                	mv	a1,s1
ffffffffc0201718:	0aa1                	addi	s5,s5,8
ffffffffc020171a:	9902                	jalr	s2
            break;
ffffffffc020171c:	bfb9                	j	ffffffffc020167a <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc020171e:	4705                	li	a4,1
ffffffffc0201720:	008a8993          	addi	s3,s5,8
ffffffffc0201724:	01074463          	blt	a4,a6,ffffffffc020172c <vprintfmt+0xec>
    else if (lflag) {
ffffffffc0201728:	22080463          	beqz	a6,ffffffffc0201950 <vprintfmt+0x310>
        return va_arg(*ap, long);
ffffffffc020172c:	000ab403          	ld	s0,0(s5)
            if ((long long)num < 0) {
ffffffffc0201730:	24044463          	bltz	s0,ffffffffc0201978 <vprintfmt+0x338>
            num = getint(&ap, lflag);
ffffffffc0201734:	8622                	mv	a2,s0
ffffffffc0201736:	8ace                	mv	s5,s3
ffffffffc0201738:	46a9                	li	a3,10
ffffffffc020173a:	a89d                	j	ffffffffc02017b0 <vprintfmt+0x170>
            err = va_arg(ap, int);
ffffffffc020173c:	000aa783          	lw	a5,0(s5)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201740:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc0201742:	0aa1                	addi	s5,s5,8
            if (err < 0) {
ffffffffc0201744:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0201748:	8fb5                	xor	a5,a5,a3
ffffffffc020174a:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc020174e:	1ad74363          	blt	a4,a3,ffffffffc02018f4 <vprintfmt+0x2b4>
ffffffffc0201752:	00369793          	slli	a5,a3,0x3
ffffffffc0201756:	97e2                	add	a5,a5,s8
ffffffffc0201758:	639c                	ld	a5,0(a5)
ffffffffc020175a:	18078d63          	beqz	a5,ffffffffc02018f4 <vprintfmt+0x2b4>
                printfmt(putch, putdat, "%s", p);
ffffffffc020175e:	86be                	mv	a3,a5
ffffffffc0201760:	00001617          	auipc	a2,0x1
ffffffffc0201764:	2d060613          	addi	a2,a2,720 # ffffffffc0202a30 <error_string+0xe8>
ffffffffc0201768:	85a6                	mv	a1,s1
ffffffffc020176a:	854a                	mv	a0,s2
ffffffffc020176c:	240000ef          	jal	ra,ffffffffc02019ac <printfmt>
ffffffffc0201770:	b729                	j	ffffffffc020167a <vprintfmt+0x3a>
            lflag ++;
ffffffffc0201772:	00144603          	lbu	a2,1(s0)
ffffffffc0201776:	2805                	addiw	a6,a6,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201778:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc020177a:	bf3d                	j	ffffffffc02016b8 <vprintfmt+0x78>
    if (lflag >= 2) {
ffffffffc020177c:	4705                	li	a4,1
ffffffffc020177e:	008a8593          	addi	a1,s5,8
ffffffffc0201782:	01074463          	blt	a4,a6,ffffffffc020178a <vprintfmt+0x14a>
    else if (lflag) {
ffffffffc0201786:	1e080263          	beqz	a6,ffffffffc020196a <vprintfmt+0x32a>
        return va_arg(*ap, unsigned long);
ffffffffc020178a:	000ab603          	ld	a2,0(s5)
ffffffffc020178e:	46a1                	li	a3,8
ffffffffc0201790:	8aae                	mv	s5,a1
ffffffffc0201792:	a839                	j	ffffffffc02017b0 <vprintfmt+0x170>
            putch('0', putdat);
ffffffffc0201794:	03000513          	li	a0,48
ffffffffc0201798:	85a6                	mv	a1,s1
ffffffffc020179a:	e03e                	sd	a5,0(sp)
ffffffffc020179c:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc020179e:	85a6                	mv	a1,s1
ffffffffc02017a0:	07800513          	li	a0,120
ffffffffc02017a4:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc02017a6:	0aa1                	addi	s5,s5,8
ffffffffc02017a8:	ff8ab603          	ld	a2,-8(s5)
            goto number;
ffffffffc02017ac:	6782                	ld	a5,0(sp)
ffffffffc02017ae:	46c1                	li	a3,16
            printnum(putch, putdat, num, base, width, padc);
ffffffffc02017b0:	876e                	mv	a4,s11
ffffffffc02017b2:	85a6                	mv	a1,s1
ffffffffc02017b4:	854a                	mv	a0,s2
ffffffffc02017b6:	e1fff0ef          	jal	ra,ffffffffc02015d4 <printnum>
            break;
ffffffffc02017ba:	b5c1                	j	ffffffffc020167a <vprintfmt+0x3a>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02017bc:	000ab603          	ld	a2,0(s5)
ffffffffc02017c0:	0aa1                	addi	s5,s5,8
ffffffffc02017c2:	1c060663          	beqz	a2,ffffffffc020198e <vprintfmt+0x34e>
            if (width > 0 && padc != '-') {
ffffffffc02017c6:	00160413          	addi	s0,a2,1
ffffffffc02017ca:	17b05c63          	blez	s11,ffffffffc0201942 <vprintfmt+0x302>
ffffffffc02017ce:	02d00593          	li	a1,45
ffffffffc02017d2:	14b79263          	bne	a5,a1,ffffffffc0201916 <vprintfmt+0x2d6>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02017d6:	00064783          	lbu	a5,0(a2)
ffffffffc02017da:	0007851b          	sext.w	a0,a5
ffffffffc02017de:	c905                	beqz	a0,ffffffffc020180e <vprintfmt+0x1ce>
ffffffffc02017e0:	000cc563          	bltz	s9,ffffffffc02017ea <vprintfmt+0x1aa>
ffffffffc02017e4:	3cfd                	addiw	s9,s9,-1
ffffffffc02017e6:	036c8263          	beq	s9,s6,ffffffffc020180a <vprintfmt+0x1ca>
                    putch('?', putdat);
ffffffffc02017ea:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02017ec:	18098463          	beqz	s3,ffffffffc0201974 <vprintfmt+0x334>
ffffffffc02017f0:	3781                	addiw	a5,a5,-32
ffffffffc02017f2:	18fbf163          	bleu	a5,s7,ffffffffc0201974 <vprintfmt+0x334>
                    putch('?', putdat);
ffffffffc02017f6:	03f00513          	li	a0,63
ffffffffc02017fa:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02017fc:	0405                	addi	s0,s0,1
ffffffffc02017fe:	fff44783          	lbu	a5,-1(s0)
ffffffffc0201802:	3dfd                	addiw	s11,s11,-1
ffffffffc0201804:	0007851b          	sext.w	a0,a5
ffffffffc0201808:	fd61                	bnez	a0,ffffffffc02017e0 <vprintfmt+0x1a0>
            for (; width > 0; width --) {
ffffffffc020180a:	e7b058e3          	blez	s11,ffffffffc020167a <vprintfmt+0x3a>
ffffffffc020180e:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0201810:	85a6                	mv	a1,s1
ffffffffc0201812:	02000513          	li	a0,32
ffffffffc0201816:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0201818:	e60d81e3          	beqz	s11,ffffffffc020167a <vprintfmt+0x3a>
ffffffffc020181c:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc020181e:	85a6                	mv	a1,s1
ffffffffc0201820:	02000513          	li	a0,32
ffffffffc0201824:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0201826:	fe0d94e3          	bnez	s11,ffffffffc020180e <vprintfmt+0x1ce>
ffffffffc020182a:	bd81                	j	ffffffffc020167a <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc020182c:	4705                	li	a4,1
ffffffffc020182e:	008a8593          	addi	a1,s5,8
ffffffffc0201832:	01074463          	blt	a4,a6,ffffffffc020183a <vprintfmt+0x1fa>
    else if (lflag) {
ffffffffc0201836:	12080063          	beqz	a6,ffffffffc0201956 <vprintfmt+0x316>
        return va_arg(*ap, unsigned long);
ffffffffc020183a:	000ab603          	ld	a2,0(s5)
ffffffffc020183e:	46a9                	li	a3,10
ffffffffc0201840:	8aae                	mv	s5,a1
ffffffffc0201842:	b7bd                	j	ffffffffc02017b0 <vprintfmt+0x170>
ffffffffc0201844:	00144603          	lbu	a2,1(s0)
            padc = '-';
ffffffffc0201848:	02d00793          	li	a5,45
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020184c:	846a                	mv	s0,s10
ffffffffc020184e:	b5ad                	j	ffffffffc02016b8 <vprintfmt+0x78>
            putch(ch, putdat);
ffffffffc0201850:	85a6                	mv	a1,s1
ffffffffc0201852:	02500513          	li	a0,37
ffffffffc0201856:	9902                	jalr	s2
            break;
ffffffffc0201858:	b50d                	j	ffffffffc020167a <vprintfmt+0x3a>
            precision = va_arg(ap, int);
ffffffffc020185a:	000aac83          	lw	s9,0(s5)
            goto process_precision;
ffffffffc020185e:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0201862:	0aa1                	addi	s5,s5,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201864:	846a                	mv	s0,s10
            if (width < 0)
ffffffffc0201866:	e40dd9e3          	bgez	s11,ffffffffc02016b8 <vprintfmt+0x78>
                width = precision, precision = -1;
ffffffffc020186a:	8de6                	mv	s11,s9
ffffffffc020186c:	5cfd                	li	s9,-1
ffffffffc020186e:	b5a9                	j	ffffffffc02016b8 <vprintfmt+0x78>
            goto reswitch;
ffffffffc0201870:	00144603          	lbu	a2,1(s0)
            padc = '0';
ffffffffc0201874:	03000793          	li	a5,48
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201878:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc020187a:	bd3d                	j	ffffffffc02016b8 <vprintfmt+0x78>
                precision = precision * 10 + ch - '0';
ffffffffc020187c:	fd060c9b          	addiw	s9,a2,-48
                ch = *fmt;
ffffffffc0201880:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201884:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0201886:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc020188a:	0006089b          	sext.w	a7,a2
                if (ch < '0' || ch > '9') {
ffffffffc020188e:	fcd56ce3          	bltu	a0,a3,ffffffffc0201866 <vprintfmt+0x226>
            for (precision = 0; ; ++ fmt) {
ffffffffc0201892:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0201894:	002c969b          	slliw	a3,s9,0x2
                ch = *fmt;
ffffffffc0201898:	00044603          	lbu	a2,0(s0)
                precision = precision * 10 + ch - '0';
ffffffffc020189c:	0196873b          	addw	a4,a3,s9
ffffffffc02018a0:	0017171b          	slliw	a4,a4,0x1
ffffffffc02018a4:	0117073b          	addw	a4,a4,a7
                if (ch < '0' || ch > '9') {
ffffffffc02018a8:	fd06069b          	addiw	a3,a2,-48
                precision = precision * 10 + ch - '0';
ffffffffc02018ac:	fd070c9b          	addiw	s9,a4,-48
                ch = *fmt;
ffffffffc02018b0:	0006089b          	sext.w	a7,a2
                if (ch < '0' || ch > '9') {
ffffffffc02018b4:	fcd57fe3          	bleu	a3,a0,ffffffffc0201892 <vprintfmt+0x252>
ffffffffc02018b8:	b77d                	j	ffffffffc0201866 <vprintfmt+0x226>
            if (width < 0)
ffffffffc02018ba:	fffdc693          	not	a3,s11
ffffffffc02018be:	96fd                	srai	a3,a3,0x3f
ffffffffc02018c0:	00ddfdb3          	and	s11,s11,a3
ffffffffc02018c4:	00144603          	lbu	a2,1(s0)
ffffffffc02018c8:	2d81                	sext.w	s11,s11
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02018ca:	846a                	mv	s0,s10
ffffffffc02018cc:	b3f5                	j	ffffffffc02016b8 <vprintfmt+0x78>
            putch('%', putdat);
ffffffffc02018ce:	85a6                	mv	a1,s1
ffffffffc02018d0:	02500513          	li	a0,37
ffffffffc02018d4:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc02018d6:	fff44703          	lbu	a4,-1(s0)
ffffffffc02018da:	02500793          	li	a5,37
ffffffffc02018de:	8d22                	mv	s10,s0
ffffffffc02018e0:	d8f70de3          	beq	a4,a5,ffffffffc020167a <vprintfmt+0x3a>
ffffffffc02018e4:	02500713          	li	a4,37
ffffffffc02018e8:	1d7d                	addi	s10,s10,-1
ffffffffc02018ea:	fffd4783          	lbu	a5,-1(s10)
ffffffffc02018ee:	fee79de3          	bne	a5,a4,ffffffffc02018e8 <vprintfmt+0x2a8>
ffffffffc02018f2:	b361                	j	ffffffffc020167a <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc02018f4:	00001617          	auipc	a2,0x1
ffffffffc02018f8:	12c60613          	addi	a2,a2,300 # ffffffffc0202a20 <error_string+0xd8>
ffffffffc02018fc:	85a6                	mv	a1,s1
ffffffffc02018fe:	854a                	mv	a0,s2
ffffffffc0201900:	0ac000ef          	jal	ra,ffffffffc02019ac <printfmt>
ffffffffc0201904:	bb9d                	j	ffffffffc020167a <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0201906:	00001617          	auipc	a2,0x1
ffffffffc020190a:	11260613          	addi	a2,a2,274 # ffffffffc0202a18 <error_string+0xd0>
            if (width > 0 && padc != '-') {
ffffffffc020190e:	00001417          	auipc	s0,0x1
ffffffffc0201912:	10b40413          	addi	s0,s0,267 # ffffffffc0202a19 <error_string+0xd1>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201916:	8532                	mv	a0,a2
ffffffffc0201918:	85e6                	mv	a1,s9
ffffffffc020191a:	e032                	sd	a2,0(sp)
ffffffffc020191c:	e43e                	sd	a5,8(sp)
ffffffffc020191e:	1c2000ef          	jal	ra,ffffffffc0201ae0 <strnlen>
ffffffffc0201922:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0201926:	6602                	ld	a2,0(sp)
ffffffffc0201928:	01b05d63          	blez	s11,ffffffffc0201942 <vprintfmt+0x302>
ffffffffc020192c:	67a2                	ld	a5,8(sp)
ffffffffc020192e:	2781                	sext.w	a5,a5
ffffffffc0201930:	e43e                	sd	a5,8(sp)
                    putch(padc, putdat);
ffffffffc0201932:	6522                	ld	a0,8(sp)
ffffffffc0201934:	85a6                	mv	a1,s1
ffffffffc0201936:	e032                	sd	a2,0(sp)
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201938:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc020193a:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020193c:	6602                	ld	a2,0(sp)
ffffffffc020193e:	fe0d9ae3          	bnez	s11,ffffffffc0201932 <vprintfmt+0x2f2>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201942:	00064783          	lbu	a5,0(a2)
ffffffffc0201946:	0007851b          	sext.w	a0,a5
ffffffffc020194a:	e8051be3          	bnez	a0,ffffffffc02017e0 <vprintfmt+0x1a0>
ffffffffc020194e:	b335                	j	ffffffffc020167a <vprintfmt+0x3a>
        return va_arg(*ap, int);
ffffffffc0201950:	000aa403          	lw	s0,0(s5)
ffffffffc0201954:	bbf1                	j	ffffffffc0201730 <vprintfmt+0xf0>
        return va_arg(*ap, unsigned int);
ffffffffc0201956:	000ae603          	lwu	a2,0(s5)
ffffffffc020195a:	46a9                	li	a3,10
ffffffffc020195c:	8aae                	mv	s5,a1
ffffffffc020195e:	bd89                	j	ffffffffc02017b0 <vprintfmt+0x170>
ffffffffc0201960:	000ae603          	lwu	a2,0(s5)
ffffffffc0201964:	46c1                	li	a3,16
ffffffffc0201966:	8aae                	mv	s5,a1
ffffffffc0201968:	b5a1                	j	ffffffffc02017b0 <vprintfmt+0x170>
ffffffffc020196a:	000ae603          	lwu	a2,0(s5)
ffffffffc020196e:	46a1                	li	a3,8
ffffffffc0201970:	8aae                	mv	s5,a1
ffffffffc0201972:	bd3d                	j	ffffffffc02017b0 <vprintfmt+0x170>
                    putch(ch, putdat);
ffffffffc0201974:	9902                	jalr	s2
ffffffffc0201976:	b559                	j	ffffffffc02017fc <vprintfmt+0x1bc>
                putch('-', putdat);
ffffffffc0201978:	85a6                	mv	a1,s1
ffffffffc020197a:	02d00513          	li	a0,45
ffffffffc020197e:	e03e                	sd	a5,0(sp)
ffffffffc0201980:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0201982:	8ace                	mv	s5,s3
ffffffffc0201984:	40800633          	neg	a2,s0
ffffffffc0201988:	46a9                	li	a3,10
ffffffffc020198a:	6782                	ld	a5,0(sp)
ffffffffc020198c:	b515                	j	ffffffffc02017b0 <vprintfmt+0x170>
            if (width > 0 && padc != '-') {
ffffffffc020198e:	01b05663          	blez	s11,ffffffffc020199a <vprintfmt+0x35a>
ffffffffc0201992:	02d00693          	li	a3,45
ffffffffc0201996:	f6d798e3          	bne	a5,a3,ffffffffc0201906 <vprintfmt+0x2c6>
ffffffffc020199a:	00001417          	auipc	s0,0x1
ffffffffc020199e:	07f40413          	addi	s0,s0,127 # ffffffffc0202a19 <error_string+0xd1>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02019a2:	02800513          	li	a0,40
ffffffffc02019a6:	02800793          	li	a5,40
ffffffffc02019aa:	bd1d                	j	ffffffffc02017e0 <vprintfmt+0x1a0>

ffffffffc02019ac <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02019ac:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc02019ae:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02019b2:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02019b4:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02019b6:	ec06                	sd	ra,24(sp)
ffffffffc02019b8:	f83a                	sd	a4,48(sp)
ffffffffc02019ba:	fc3e                	sd	a5,56(sp)
ffffffffc02019bc:	e0c2                	sd	a6,64(sp)
ffffffffc02019be:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc02019c0:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02019c2:	c7fff0ef          	jal	ra,ffffffffc0201640 <vprintfmt>
}
ffffffffc02019c6:	60e2                	ld	ra,24(sp)
ffffffffc02019c8:	6161                	addi	sp,sp,80
ffffffffc02019ca:	8082                	ret

ffffffffc02019cc <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc02019cc:	715d                	addi	sp,sp,-80
ffffffffc02019ce:	e486                	sd	ra,72(sp)
ffffffffc02019d0:	e0a2                	sd	s0,64(sp)
ffffffffc02019d2:	fc26                	sd	s1,56(sp)
ffffffffc02019d4:	f84a                	sd	s2,48(sp)
ffffffffc02019d6:	f44e                	sd	s3,40(sp)
ffffffffc02019d8:	f052                	sd	s4,32(sp)
ffffffffc02019da:	ec56                	sd	s5,24(sp)
ffffffffc02019dc:	e85a                	sd	s6,16(sp)
ffffffffc02019de:	e45e                	sd	s7,8(sp)
    if (prompt != NULL) {
ffffffffc02019e0:	c901                	beqz	a0,ffffffffc02019f0 <readline+0x24>
        cprintf("%s", prompt);
ffffffffc02019e2:	85aa                	mv	a1,a0
ffffffffc02019e4:	00001517          	auipc	a0,0x1
ffffffffc02019e8:	04c50513          	addi	a0,a0,76 # ffffffffc0202a30 <error_string+0xe8>
ffffffffc02019ec:	ec6fe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
readline(const char *prompt) {
ffffffffc02019f0:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02019f2:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc02019f4:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc02019f6:	4aa9                	li	s5,10
ffffffffc02019f8:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc02019fa:	00004b97          	auipc	s7,0x4
ffffffffc02019fe:	616b8b93          	addi	s7,s7,1558 # ffffffffc0206010 <edata>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201a02:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc0201a06:	f24fe0ef          	jal	ra,ffffffffc020012a <getchar>
ffffffffc0201a0a:	842a                	mv	s0,a0
        if (c < 0) {
ffffffffc0201a0c:	00054b63          	bltz	a0,ffffffffc0201a22 <readline+0x56>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201a10:	00a95b63          	ble	a0,s2,ffffffffc0201a26 <readline+0x5a>
ffffffffc0201a14:	029a5463          	ble	s1,s4,ffffffffc0201a3c <readline+0x70>
        c = getchar();
ffffffffc0201a18:	f12fe0ef          	jal	ra,ffffffffc020012a <getchar>
ffffffffc0201a1c:	842a                	mv	s0,a0
        if (c < 0) {
ffffffffc0201a1e:	fe0559e3          	bgez	a0,ffffffffc0201a10 <readline+0x44>
            return NULL;
ffffffffc0201a22:	4501                	li	a0,0
ffffffffc0201a24:	a099                	j	ffffffffc0201a6a <readline+0x9e>
        else if (c == '\b' && i > 0) {
ffffffffc0201a26:	03341463          	bne	s0,s3,ffffffffc0201a4e <readline+0x82>
ffffffffc0201a2a:	e8b9                	bnez	s1,ffffffffc0201a80 <readline+0xb4>
        c = getchar();
ffffffffc0201a2c:	efefe0ef          	jal	ra,ffffffffc020012a <getchar>
ffffffffc0201a30:	842a                	mv	s0,a0
        if (c < 0) {
ffffffffc0201a32:	fe0548e3          	bltz	a0,ffffffffc0201a22 <readline+0x56>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201a36:	fea958e3          	ble	a0,s2,ffffffffc0201a26 <readline+0x5a>
ffffffffc0201a3a:	4481                	li	s1,0
            cputchar(c);
ffffffffc0201a3c:	8522                	mv	a0,s0
ffffffffc0201a3e:	ea8fe0ef          	jal	ra,ffffffffc02000e6 <cputchar>
            buf[i ++] = c;
ffffffffc0201a42:	009b87b3          	add	a5,s7,s1
ffffffffc0201a46:	00878023          	sb	s0,0(a5)
ffffffffc0201a4a:	2485                	addiw	s1,s1,1
ffffffffc0201a4c:	bf6d                	j	ffffffffc0201a06 <readline+0x3a>
        else if (c == '\n' || c == '\r') {
ffffffffc0201a4e:	01540463          	beq	s0,s5,ffffffffc0201a56 <readline+0x8a>
ffffffffc0201a52:	fb641ae3          	bne	s0,s6,ffffffffc0201a06 <readline+0x3a>
            cputchar(c);
ffffffffc0201a56:	8522                	mv	a0,s0
ffffffffc0201a58:	e8efe0ef          	jal	ra,ffffffffc02000e6 <cputchar>
            buf[i] = '\0';
ffffffffc0201a5c:	00004517          	auipc	a0,0x4
ffffffffc0201a60:	5b450513          	addi	a0,a0,1460 # ffffffffc0206010 <edata>
ffffffffc0201a64:	94aa                	add	s1,s1,a0
ffffffffc0201a66:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc0201a6a:	60a6                	ld	ra,72(sp)
ffffffffc0201a6c:	6406                	ld	s0,64(sp)
ffffffffc0201a6e:	74e2                	ld	s1,56(sp)
ffffffffc0201a70:	7942                	ld	s2,48(sp)
ffffffffc0201a72:	79a2                	ld	s3,40(sp)
ffffffffc0201a74:	7a02                	ld	s4,32(sp)
ffffffffc0201a76:	6ae2                	ld	s5,24(sp)
ffffffffc0201a78:	6b42                	ld	s6,16(sp)
ffffffffc0201a7a:	6ba2                	ld	s7,8(sp)
ffffffffc0201a7c:	6161                	addi	sp,sp,80
ffffffffc0201a7e:	8082                	ret
            cputchar(c);
ffffffffc0201a80:	4521                	li	a0,8
ffffffffc0201a82:	e64fe0ef          	jal	ra,ffffffffc02000e6 <cputchar>
            i --;
ffffffffc0201a86:	34fd                	addiw	s1,s1,-1
ffffffffc0201a88:	bfbd                	j	ffffffffc0201a06 <readline+0x3a>

ffffffffc0201a8a <sbi_console_putchar>:
    );
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
ffffffffc0201a8a:	00004797          	auipc	a5,0x4
ffffffffc0201a8e:	57e78793          	addi	a5,a5,1406 # ffffffffc0206008 <SBI_CONSOLE_PUTCHAR>
    __asm__ volatile (
ffffffffc0201a92:	6398                	ld	a4,0(a5)
ffffffffc0201a94:	4781                	li	a5,0
ffffffffc0201a96:	88ba                	mv	a7,a4
ffffffffc0201a98:	852a                	mv	a0,a0
ffffffffc0201a9a:	85be                	mv	a1,a5
ffffffffc0201a9c:	863e                	mv	a2,a5
ffffffffc0201a9e:	00000073          	ecall
ffffffffc0201aa2:	87aa                	mv	a5,a0
}
ffffffffc0201aa4:	8082                	ret

ffffffffc0201aa6 <sbi_set_timer>:

void sbi_set_timer(unsigned long long stime_value) {
    sbi_call(SBI_SET_TIMER, stime_value, 0, 0);
ffffffffc0201aa6:	00005797          	auipc	a5,0x5
ffffffffc0201aaa:	98278793          	addi	a5,a5,-1662 # ffffffffc0206428 <SBI_SET_TIMER>
    __asm__ volatile (
ffffffffc0201aae:	6398                	ld	a4,0(a5)
ffffffffc0201ab0:	4781                	li	a5,0
ffffffffc0201ab2:	88ba                	mv	a7,a4
ffffffffc0201ab4:	852a                	mv	a0,a0
ffffffffc0201ab6:	85be                	mv	a1,a5
ffffffffc0201ab8:	863e                	mv	a2,a5
ffffffffc0201aba:	00000073          	ecall
ffffffffc0201abe:	87aa                	mv	a5,a0
}
ffffffffc0201ac0:	8082                	ret

ffffffffc0201ac2 <sbi_console_getchar>:

int sbi_console_getchar(void) {
    return sbi_call(SBI_CONSOLE_GETCHAR, 0, 0, 0);
ffffffffc0201ac2:	00004797          	auipc	a5,0x4
ffffffffc0201ac6:	53e78793          	addi	a5,a5,1342 # ffffffffc0206000 <SBI_CONSOLE_GETCHAR>
    __asm__ volatile (
ffffffffc0201aca:	639c                	ld	a5,0(a5)
ffffffffc0201acc:	4501                	li	a0,0
ffffffffc0201ace:	88be                	mv	a7,a5
ffffffffc0201ad0:	852a                	mv	a0,a0
ffffffffc0201ad2:	85aa                	mv	a1,a0
ffffffffc0201ad4:	862a                	mv	a2,a0
ffffffffc0201ad6:	00000073          	ecall
ffffffffc0201ada:	852a                	mv	a0,a0
ffffffffc0201adc:	2501                	sext.w	a0,a0
ffffffffc0201ade:	8082                	ret

ffffffffc0201ae0 <strnlen>:
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201ae0:	c185                	beqz	a1,ffffffffc0201b00 <strnlen+0x20>
ffffffffc0201ae2:	00054783          	lbu	a5,0(a0)
ffffffffc0201ae6:	cf89                	beqz	a5,ffffffffc0201b00 <strnlen+0x20>
    size_t cnt = 0;
ffffffffc0201ae8:	4781                	li	a5,0
ffffffffc0201aea:	a021                	j	ffffffffc0201af2 <strnlen+0x12>
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201aec:	00074703          	lbu	a4,0(a4)
ffffffffc0201af0:	c711                	beqz	a4,ffffffffc0201afc <strnlen+0x1c>
        cnt ++;
ffffffffc0201af2:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201af4:	00f50733          	add	a4,a0,a5
ffffffffc0201af8:	fef59ae3          	bne	a1,a5,ffffffffc0201aec <strnlen+0xc>
    }
    return cnt;
}
ffffffffc0201afc:	853e                	mv	a0,a5
ffffffffc0201afe:	8082                	ret
    size_t cnt = 0;
ffffffffc0201b00:	4781                	li	a5,0
}
ffffffffc0201b02:	853e                	mv	a0,a5
ffffffffc0201b04:	8082                	ret

ffffffffc0201b06 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201b06:	00054783          	lbu	a5,0(a0)
ffffffffc0201b0a:	0005c703          	lbu	a4,0(a1)
ffffffffc0201b0e:	cb91                	beqz	a5,ffffffffc0201b22 <strcmp+0x1c>
ffffffffc0201b10:	00e79c63          	bne	a5,a4,ffffffffc0201b28 <strcmp+0x22>
        s1 ++, s2 ++;
ffffffffc0201b14:	0505                	addi	a0,a0,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201b16:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
ffffffffc0201b1a:	0585                	addi	a1,a1,1
ffffffffc0201b1c:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201b20:	fbe5                	bnez	a5,ffffffffc0201b10 <strcmp+0xa>
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201b22:	4501                	li	a0,0
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0201b24:	9d19                	subw	a0,a0,a4
ffffffffc0201b26:	8082                	ret
ffffffffc0201b28:	0007851b          	sext.w	a0,a5
ffffffffc0201b2c:	9d19                	subw	a0,a0,a4
ffffffffc0201b2e:	8082                	ret

ffffffffc0201b30 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0201b30:	00054783          	lbu	a5,0(a0)
ffffffffc0201b34:	cb91                	beqz	a5,ffffffffc0201b48 <strchr+0x18>
        if (*s == c) {
ffffffffc0201b36:	00b79563          	bne	a5,a1,ffffffffc0201b40 <strchr+0x10>
ffffffffc0201b3a:	a809                	j	ffffffffc0201b4c <strchr+0x1c>
ffffffffc0201b3c:	00b78763          	beq	a5,a1,ffffffffc0201b4a <strchr+0x1a>
            return (char *)s;
        }
        s ++;
ffffffffc0201b40:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0201b42:	00054783          	lbu	a5,0(a0)
ffffffffc0201b46:	fbfd                	bnez	a5,ffffffffc0201b3c <strchr+0xc>
    }
    return NULL;
ffffffffc0201b48:	4501                	li	a0,0
}
ffffffffc0201b4a:	8082                	ret
ffffffffc0201b4c:	8082                	ret

ffffffffc0201b4e <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0201b4e:	ca01                	beqz	a2,ffffffffc0201b5e <memset+0x10>
ffffffffc0201b50:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0201b52:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0201b54:	0785                	addi	a5,a5,1
ffffffffc0201b56:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0201b5a:	fec79de3          	bne	a5,a2,ffffffffc0201b54 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0201b5e:	8082                	ret
