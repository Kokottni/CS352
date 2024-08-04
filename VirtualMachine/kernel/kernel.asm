
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	90013103          	ld	sp,-1792(sp) # 80008900 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	90e70713          	addi	a4,a4,-1778 # 80008960 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	17c78793          	addi	a5,a5,380 # 800061e0 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdb357>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	dc478793          	addi	a5,a5,-572 # 80000e72 <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	5dc080e7          	jalr	1500(ra) # 80002708 <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	77a080e7          	jalr	1914(ra) # 800008b6 <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7159                	addi	sp,sp,-112
    80000166:	f486                	sd	ra,104(sp)
    80000168:	f0a2                	sd	s0,96(sp)
    8000016a:	eca6                	sd	s1,88(sp)
    8000016c:	e8ca                	sd	s2,80(sp)
    8000016e:	e4ce                	sd	s3,72(sp)
    80000170:	e0d2                	sd	s4,64(sp)
    80000172:	fc56                	sd	s5,56(sp)
    80000174:	f85a                	sd	s6,48(sp)
    80000176:	f45e                	sd	s7,40(sp)
    80000178:	f062                	sd	s8,32(sp)
    8000017a:	ec66                	sd	s9,24(sp)
    8000017c:	e86a                	sd	s10,16(sp)
    8000017e:	1880                	addi	s0,sp,112
    80000180:	8aaa                	mv	s5,a0
    80000182:	8a2e                	mv	s4,a1
    80000184:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000186:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018a:	00011517          	auipc	a0,0x11
    8000018e:	91650513          	addi	a0,a0,-1770 # 80010aa0 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a3e080e7          	jalr	-1474(ra) # 80000bd0 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	90648493          	addi	s1,s1,-1786 # 80010aa0 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	99690913          	addi	s2,s2,-1642 # 80010b38 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001aa:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ac:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001ae:	4ca9                	li	s9,10
  while(n > 0){
    800001b0:	07305863          	blez	s3,80000220 <consoleread+0xbc>
    while(cons.r == cons.w){
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71463          	bne	a4,a5,800001e4 <consoleread+0x80>
      if(myproc()->killed){
    800001c0:	00001097          	auipc	ra,0x1
    800001c4:	7d6080e7          	jalr	2006(ra) # 80001996 <myproc>
    800001c8:	551c                	lw	a5,40(a0)
    800001ca:	e7b5                	bnez	a5,80000236 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001cc:	85a6                	mv	a1,s1
    800001ce:	854a                	mv	a0,s2
    800001d0:	00002097          	auipc	ra,0x2
    800001d4:	138080e7          	jalr	312(ra) # 80002308 <sleep>
    while(cons.r == cons.w){
    800001d8:	0984a783          	lw	a5,152(s1)
    800001dc:	09c4a703          	lw	a4,156(s1)
    800001e0:	fef700e3          	beq	a4,a5,800001c0 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001e4:	0017871b          	addiw	a4,a5,1
    800001e8:	08e4ac23          	sw	a4,152(s1)
    800001ec:	07f7f713          	andi	a4,a5,127
    800001f0:	9726                	add	a4,a4,s1
    800001f2:	01874703          	lbu	a4,24(a4)
    800001f6:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    800001fa:	077d0563          	beq	s10,s7,80000264 <consoleread+0x100>
    cbuf = c;
    800001fe:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000202:	4685                	li	a3,1
    80000204:	f9f40613          	addi	a2,s0,-97
    80000208:	85d2                	mv	a1,s4
    8000020a:	8556                	mv	a0,s5
    8000020c:	00002097          	auipc	ra,0x2
    80000210:	4a6080e7          	jalr	1190(ra) # 800026b2 <either_copyout>
    80000214:	01850663          	beq	a0,s8,80000220 <consoleread+0xbc>
    dst++;
    80000218:	0a05                	addi	s4,s4,1
    --n;
    8000021a:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    8000021c:	f99d1ae3          	bne	s10,s9,800001b0 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000220:	00011517          	auipc	a0,0x11
    80000224:	88050513          	addi	a0,a0,-1920 # 80010aa0 <cons>
    80000228:	00001097          	auipc	ra,0x1
    8000022c:	a5c080e7          	jalr	-1444(ra) # 80000c84 <release>

  return target - n;
    80000230:	413b053b          	subw	a0,s6,s3
    80000234:	a811                	j	80000248 <consoleread+0xe4>
        release(&cons.lock);
    80000236:	00011517          	auipc	a0,0x11
    8000023a:	86a50513          	addi	a0,a0,-1942 # 80010aa0 <cons>
    8000023e:	00001097          	auipc	ra,0x1
    80000242:	a46080e7          	jalr	-1466(ra) # 80000c84 <release>
        return -1;
    80000246:	557d                	li	a0,-1
}
    80000248:	70a6                	ld	ra,104(sp)
    8000024a:	7406                	ld	s0,96(sp)
    8000024c:	64e6                	ld	s1,88(sp)
    8000024e:	6946                	ld	s2,80(sp)
    80000250:	69a6                	ld	s3,72(sp)
    80000252:	6a06                	ld	s4,64(sp)
    80000254:	7ae2                	ld	s5,56(sp)
    80000256:	7b42                	ld	s6,48(sp)
    80000258:	7ba2                	ld	s7,40(sp)
    8000025a:	7c02                	ld	s8,32(sp)
    8000025c:	6ce2                	ld	s9,24(sp)
    8000025e:	6d42                	ld	s10,16(sp)
    80000260:	6165                	addi	sp,sp,112
    80000262:	8082                	ret
      if(n < target){
    80000264:	0009871b          	sext.w	a4,s3
    80000268:	fb677ce3          	bgeu	a4,s6,80000220 <consoleread+0xbc>
        cons.r--;
    8000026c:	00011717          	auipc	a4,0x11
    80000270:	8cf72623          	sw	a5,-1844(a4) # 80010b38 <cons+0x98>
    80000274:	b775                	j	80000220 <consoleread+0xbc>

0000000080000276 <consputc>:
{
    80000276:	1141                	addi	sp,sp,-16
    80000278:	e406                	sd	ra,8(sp)
    8000027a:	e022                	sd	s0,0(sp)
    8000027c:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    8000027e:	10000793          	li	a5,256
    80000282:	00f50a63          	beq	a0,a5,80000296 <consputc+0x20>
    uartputc_sync(c);
    80000286:	00000097          	auipc	ra,0x0
    8000028a:	55e080e7          	jalr	1374(ra) # 800007e4 <uartputc_sync>
}
    8000028e:	60a2                	ld	ra,8(sp)
    80000290:	6402                	ld	s0,0(sp)
    80000292:	0141                	addi	sp,sp,16
    80000294:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    80000296:	4521                	li	a0,8
    80000298:	00000097          	auipc	ra,0x0
    8000029c:	54c080e7          	jalr	1356(ra) # 800007e4 <uartputc_sync>
    800002a0:	02000513          	li	a0,32
    800002a4:	00000097          	auipc	ra,0x0
    800002a8:	540080e7          	jalr	1344(ra) # 800007e4 <uartputc_sync>
    800002ac:	4521                	li	a0,8
    800002ae:	00000097          	auipc	ra,0x0
    800002b2:	536080e7          	jalr	1334(ra) # 800007e4 <uartputc_sync>
    800002b6:	bfe1                	j	8000028e <consputc+0x18>

00000000800002b8 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002b8:	1101                	addi	sp,sp,-32
    800002ba:	ec06                	sd	ra,24(sp)
    800002bc:	e822                	sd	s0,16(sp)
    800002be:	e426                	sd	s1,8(sp)
    800002c0:	e04a                	sd	s2,0(sp)
    800002c2:	1000                	addi	s0,sp,32
    800002c4:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002c6:	00010517          	auipc	a0,0x10
    800002ca:	7da50513          	addi	a0,a0,2010 # 80010aa0 <cons>
    800002ce:	00001097          	auipc	ra,0x1
    800002d2:	902080e7          	jalr	-1790(ra) # 80000bd0 <acquire>

  switch(c){
    800002d6:	47d5                	li	a5,21
    800002d8:	0af48663          	beq	s1,a5,80000384 <consoleintr+0xcc>
    800002dc:	0297ca63          	blt	a5,s1,80000310 <consoleintr+0x58>
    800002e0:	47a1                	li	a5,8
    800002e2:	0ef48763          	beq	s1,a5,800003d0 <consoleintr+0x118>
    800002e6:	47c1                	li	a5,16
    800002e8:	10f49a63          	bne	s1,a5,800003fc <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002ec:	00002097          	auipc	ra,0x2
    800002f0:	472080e7          	jalr	1138(ra) # 8000275e <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002f4:	00010517          	auipc	a0,0x10
    800002f8:	7ac50513          	addi	a0,a0,1964 # 80010aa0 <cons>
    800002fc:	00001097          	auipc	ra,0x1
    80000300:	988080e7          	jalr	-1656(ra) # 80000c84 <release>
}
    80000304:	60e2                	ld	ra,24(sp)
    80000306:	6442                	ld	s0,16(sp)
    80000308:	64a2                	ld	s1,8(sp)
    8000030a:	6902                	ld	s2,0(sp)
    8000030c:	6105                	addi	sp,sp,32
    8000030e:	8082                	ret
  switch(c){
    80000310:	07f00793          	li	a5,127
    80000314:	0af48e63          	beq	s1,a5,800003d0 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000318:	00010717          	auipc	a4,0x10
    8000031c:	78870713          	addi	a4,a4,1928 # 80010aa0 <cons>
    80000320:	0a072783          	lw	a5,160(a4)
    80000324:	09872703          	lw	a4,152(a4)
    80000328:	9f99                	subw	a5,a5,a4
    8000032a:	07f00713          	li	a4,127
    8000032e:	fcf763e3          	bltu	a4,a5,800002f4 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000332:	47b5                	li	a5,13
    80000334:	0cf48763          	beq	s1,a5,80000402 <consoleintr+0x14a>
      consputc(c);
    80000338:	8526                	mv	a0,s1
    8000033a:	00000097          	auipc	ra,0x0
    8000033e:	f3c080e7          	jalr	-196(ra) # 80000276 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000342:	00010797          	auipc	a5,0x10
    80000346:	75e78793          	addi	a5,a5,1886 # 80010aa0 <cons>
    8000034a:	0a07a703          	lw	a4,160(a5)
    8000034e:	0017069b          	addiw	a3,a4,1
    80000352:	0006861b          	sext.w	a2,a3
    80000356:	0ad7a023          	sw	a3,160(a5)
    8000035a:	07f77713          	andi	a4,a4,127
    8000035e:	97ba                	add	a5,a5,a4
    80000360:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    80000364:	47a9                	li	a5,10
    80000366:	0cf48563          	beq	s1,a5,80000430 <consoleintr+0x178>
    8000036a:	4791                	li	a5,4
    8000036c:	0cf48263          	beq	s1,a5,80000430 <consoleintr+0x178>
    80000370:	00010797          	auipc	a5,0x10
    80000374:	7c87a783          	lw	a5,1992(a5) # 80010b38 <cons+0x98>
    80000378:	0807879b          	addiw	a5,a5,128
    8000037c:	f6f61ce3          	bne	a2,a5,800002f4 <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000380:	863e                	mv	a2,a5
    80000382:	a07d                	j	80000430 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000384:	00010717          	auipc	a4,0x10
    80000388:	71c70713          	addi	a4,a4,1820 # 80010aa0 <cons>
    8000038c:	0a072783          	lw	a5,160(a4)
    80000390:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    80000394:	00010497          	auipc	s1,0x10
    80000398:	70c48493          	addi	s1,s1,1804 # 80010aa0 <cons>
    while(cons.e != cons.w &&
    8000039c:	4929                	li	s2,10
    8000039e:	f4f70be3          	beq	a4,a5,800002f4 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a2:	37fd                	addiw	a5,a5,-1
    800003a4:	07f7f713          	andi	a4,a5,127
    800003a8:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003aa:	01874703          	lbu	a4,24(a4)
    800003ae:	f52703e3          	beq	a4,s2,800002f4 <consoleintr+0x3c>
      cons.e--;
    800003b2:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003b6:	10000513          	li	a0,256
    800003ba:	00000097          	auipc	ra,0x0
    800003be:	ebc080e7          	jalr	-324(ra) # 80000276 <consputc>
    while(cons.e != cons.w &&
    800003c2:	0a04a783          	lw	a5,160(s1)
    800003c6:	09c4a703          	lw	a4,156(s1)
    800003ca:	fcf71ce3          	bne	a4,a5,800003a2 <consoleintr+0xea>
    800003ce:	b71d                	j	800002f4 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d0:	00010717          	auipc	a4,0x10
    800003d4:	6d070713          	addi	a4,a4,1744 # 80010aa0 <cons>
    800003d8:	0a072783          	lw	a5,160(a4)
    800003dc:	09c72703          	lw	a4,156(a4)
    800003e0:	f0f70ae3          	beq	a4,a5,800002f4 <consoleintr+0x3c>
      cons.e--;
    800003e4:	37fd                	addiw	a5,a5,-1
    800003e6:	00010717          	auipc	a4,0x10
    800003ea:	74f72d23          	sw	a5,1882(a4) # 80010b40 <cons+0xa0>
      consputc(BACKSPACE);
    800003ee:	10000513          	li	a0,256
    800003f2:	00000097          	auipc	ra,0x0
    800003f6:	e84080e7          	jalr	-380(ra) # 80000276 <consputc>
    800003fa:	bded                	j	800002f4 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    800003fc:	ee048ce3          	beqz	s1,800002f4 <consoleintr+0x3c>
    80000400:	bf21                	j	80000318 <consoleintr+0x60>
      consputc(c);
    80000402:	4529                	li	a0,10
    80000404:	00000097          	auipc	ra,0x0
    80000408:	e72080e7          	jalr	-398(ra) # 80000276 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000040c:	00010797          	auipc	a5,0x10
    80000410:	69478793          	addi	a5,a5,1684 # 80010aa0 <cons>
    80000414:	0a07a703          	lw	a4,160(a5)
    80000418:	0017069b          	addiw	a3,a4,1
    8000041c:	0006861b          	sext.w	a2,a3
    80000420:	0ad7a023          	sw	a3,160(a5)
    80000424:	07f77713          	andi	a4,a4,127
    80000428:	97ba                	add	a5,a5,a4
    8000042a:	4729                	li	a4,10
    8000042c:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000430:	00010797          	auipc	a5,0x10
    80000434:	70c7a623          	sw	a2,1804(a5) # 80010b3c <cons+0x9c>
        wakeup(&cons.r);
    80000438:	00010517          	auipc	a0,0x10
    8000043c:	70050513          	addi	a0,a0,1792 # 80010b38 <cons+0x98>
    80000440:	00002097          	auipc	ra,0x2
    80000444:	05a080e7          	jalr	90(ra) # 8000249a <wakeup>
    80000448:	b575                	j	800002f4 <consoleintr+0x3c>

000000008000044a <consoleinit>:

void
consoleinit(void)
{
    8000044a:	1141                	addi	sp,sp,-16
    8000044c:	e406                	sd	ra,8(sp)
    8000044e:	e022                	sd	s0,0(sp)
    80000450:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000452:	00008597          	auipc	a1,0x8
    80000456:	bbe58593          	addi	a1,a1,-1090 # 80008010 <etext+0x10>
    8000045a:	00010517          	auipc	a0,0x10
    8000045e:	64650513          	addi	a0,a0,1606 # 80010aa0 <cons>
    80000462:	00000097          	auipc	ra,0x0
    80000466:	6de080e7          	jalr	1758(ra) # 80000b40 <initlock>

  uartinit();
    8000046a:	00000097          	auipc	ra,0x0
    8000046e:	32a080e7          	jalr	810(ra) # 80000794 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000472:	00022797          	auipc	a5,0x22
    80000476:	e9e78793          	addi	a5,a5,-354 # 80022310 <devsw>
    8000047a:	00000717          	auipc	a4,0x0
    8000047e:	cea70713          	addi	a4,a4,-790 # 80000164 <consoleread>
    80000482:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000484:	00000717          	auipc	a4,0x0
    80000488:	c7e70713          	addi	a4,a4,-898 # 80000102 <consolewrite>
    8000048c:	ef98                	sd	a4,24(a5)
}
    8000048e:	60a2                	ld	ra,8(sp)
    80000490:	6402                	ld	s0,0(sp)
    80000492:	0141                	addi	sp,sp,16
    80000494:	8082                	ret

0000000080000496 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    80000496:	7179                	addi	sp,sp,-48
    80000498:	f406                	sd	ra,40(sp)
    8000049a:	f022                	sd	s0,32(sp)
    8000049c:	ec26                	sd	s1,24(sp)
    8000049e:	e84a                	sd	s2,16(sp)
    800004a0:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a2:	c219                	beqz	a2,800004a8 <printint+0x12>
    800004a4:	08054663          	bltz	a0,80000530 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004a8:	2501                	sext.w	a0,a0
    800004aa:	4881                	li	a7,0
    800004ac:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b0:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b2:	2581                	sext.w	a1,a1
    800004b4:	00008617          	auipc	a2,0x8
    800004b8:	b8c60613          	addi	a2,a2,-1140 # 80008040 <digits>
    800004bc:	883a                	mv	a6,a4
    800004be:	2705                	addiw	a4,a4,1
    800004c0:	02b577bb          	remuw	a5,a0,a1
    800004c4:	1782                	slli	a5,a5,0x20
    800004c6:	9381                	srli	a5,a5,0x20
    800004c8:	97b2                	add	a5,a5,a2
    800004ca:	0007c783          	lbu	a5,0(a5)
    800004ce:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d2:	0005079b          	sext.w	a5,a0
    800004d6:	02b5553b          	divuw	a0,a0,a1
    800004da:	0685                	addi	a3,a3,1
    800004dc:	feb7f0e3          	bgeu	a5,a1,800004bc <printint+0x26>

  if(sign)
    800004e0:	00088b63          	beqz	a7,800004f6 <printint+0x60>
    buf[i++] = '-';
    800004e4:	fe040793          	addi	a5,s0,-32
    800004e8:	973e                	add	a4,a4,a5
    800004ea:	02d00793          	li	a5,45
    800004ee:	fef70823          	sb	a5,-16(a4)
    800004f2:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004f6:	02e05763          	blez	a4,80000524 <printint+0x8e>
    800004fa:	fd040793          	addi	a5,s0,-48
    800004fe:	00e784b3          	add	s1,a5,a4
    80000502:	fff78913          	addi	s2,a5,-1
    80000506:	993a                	add	s2,s2,a4
    80000508:	377d                	addiw	a4,a4,-1
    8000050a:	1702                	slli	a4,a4,0x20
    8000050c:	9301                	srli	a4,a4,0x20
    8000050e:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000512:	fff4c503          	lbu	a0,-1(s1)
    80000516:	00000097          	auipc	ra,0x0
    8000051a:	d60080e7          	jalr	-672(ra) # 80000276 <consputc>
  while(--i >= 0)
    8000051e:	14fd                	addi	s1,s1,-1
    80000520:	ff2499e3          	bne	s1,s2,80000512 <printint+0x7c>
}
    80000524:	70a2                	ld	ra,40(sp)
    80000526:	7402                	ld	s0,32(sp)
    80000528:	64e2                	ld	s1,24(sp)
    8000052a:	6942                	ld	s2,16(sp)
    8000052c:	6145                	addi	sp,sp,48
    8000052e:	8082                	ret
    x = -xx;
    80000530:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000534:	4885                	li	a7,1
    x = -xx;
    80000536:	bf9d                	j	800004ac <printint+0x16>

0000000080000538 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000538:	1101                	addi	sp,sp,-32
    8000053a:	ec06                	sd	ra,24(sp)
    8000053c:	e822                	sd	s0,16(sp)
    8000053e:	e426                	sd	s1,8(sp)
    80000540:	1000                	addi	s0,sp,32
    80000542:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000544:	00010797          	auipc	a5,0x10
    80000548:	6007ae23          	sw	zero,1564(a5) # 80010b60 <pr+0x18>
  printf("panic: ");
    8000054c:	00008517          	auipc	a0,0x8
    80000550:	acc50513          	addi	a0,a0,-1332 # 80008018 <etext+0x18>
    80000554:	00000097          	auipc	ra,0x0
    80000558:	02e080e7          	jalr	46(ra) # 80000582 <printf>
  printf(s);
    8000055c:	8526                	mv	a0,s1
    8000055e:	00000097          	auipc	ra,0x0
    80000562:	024080e7          	jalr	36(ra) # 80000582 <printf>
  printf("\n");
    80000566:	00008517          	auipc	a0,0x8
    8000056a:	b6250513          	addi	a0,a0,-1182 # 800080c8 <digits+0x88>
    8000056e:	00000097          	auipc	ra,0x0
    80000572:	014080e7          	jalr	20(ra) # 80000582 <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000576:	4785                	li	a5,1
    80000578:	00008717          	auipc	a4,0x8
    8000057c:	3af72423          	sw	a5,936(a4) # 80008920 <panicked>
  for(;;)
    80000580:	a001                	j	80000580 <panic+0x48>

0000000080000582 <printf>:
{
    80000582:	7131                	addi	sp,sp,-192
    80000584:	fc86                	sd	ra,120(sp)
    80000586:	f8a2                	sd	s0,112(sp)
    80000588:	f4a6                	sd	s1,104(sp)
    8000058a:	f0ca                	sd	s2,96(sp)
    8000058c:	ecce                	sd	s3,88(sp)
    8000058e:	e8d2                	sd	s4,80(sp)
    80000590:	e4d6                	sd	s5,72(sp)
    80000592:	e0da                	sd	s6,64(sp)
    80000594:	fc5e                	sd	s7,56(sp)
    80000596:	f862                	sd	s8,48(sp)
    80000598:	f466                	sd	s9,40(sp)
    8000059a:	f06a                	sd	s10,32(sp)
    8000059c:	ec6e                	sd	s11,24(sp)
    8000059e:	0100                	addi	s0,sp,128
    800005a0:	8a2a                	mv	s4,a0
    800005a2:	e40c                	sd	a1,8(s0)
    800005a4:	e810                	sd	a2,16(s0)
    800005a6:	ec14                	sd	a3,24(s0)
    800005a8:	f018                	sd	a4,32(s0)
    800005aa:	f41c                	sd	a5,40(s0)
    800005ac:	03043823          	sd	a6,48(s0)
    800005b0:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005b4:	00010d97          	auipc	s11,0x10
    800005b8:	5acdad83          	lw	s11,1452(s11) # 80010b60 <pr+0x18>
  if(locking)
    800005bc:	020d9b63          	bnez	s11,800005f2 <printf+0x70>
  if (fmt == 0)
    800005c0:	040a0263          	beqz	s4,80000604 <printf+0x82>
  va_start(ap, fmt);
    800005c4:	00840793          	addi	a5,s0,8
    800005c8:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005cc:	000a4503          	lbu	a0,0(s4)
    800005d0:	14050f63          	beqz	a0,8000072e <printf+0x1ac>
    800005d4:	4981                	li	s3,0
    if(c != '%'){
    800005d6:	02500a93          	li	s5,37
    switch(c){
    800005da:	07000b93          	li	s7,112
  consputc('x');
    800005de:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e0:	00008b17          	auipc	s6,0x8
    800005e4:	a60b0b13          	addi	s6,s6,-1440 # 80008040 <digits>
    switch(c){
    800005e8:	07300c93          	li	s9,115
    800005ec:	06400c13          	li	s8,100
    800005f0:	a82d                	j	8000062a <printf+0xa8>
    acquire(&pr.lock);
    800005f2:	00010517          	auipc	a0,0x10
    800005f6:	55650513          	addi	a0,a0,1366 # 80010b48 <pr>
    800005fa:	00000097          	auipc	ra,0x0
    800005fe:	5d6080e7          	jalr	1494(ra) # 80000bd0 <acquire>
    80000602:	bf7d                	j	800005c0 <printf+0x3e>
    panic("null fmt");
    80000604:	00008517          	auipc	a0,0x8
    80000608:	a2450513          	addi	a0,a0,-1500 # 80008028 <etext+0x28>
    8000060c:	00000097          	auipc	ra,0x0
    80000610:	f2c080e7          	jalr	-212(ra) # 80000538 <panic>
      consputc(c);
    80000614:	00000097          	auipc	ra,0x0
    80000618:	c62080e7          	jalr	-926(ra) # 80000276 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    8000061c:	2985                	addiw	s3,s3,1
    8000061e:	013a07b3          	add	a5,s4,s3
    80000622:	0007c503          	lbu	a0,0(a5)
    80000626:	10050463          	beqz	a0,8000072e <printf+0x1ac>
    if(c != '%'){
    8000062a:	ff5515e3          	bne	a0,s5,80000614 <printf+0x92>
    c = fmt[++i] & 0xff;
    8000062e:	2985                	addiw	s3,s3,1
    80000630:	013a07b3          	add	a5,s4,s3
    80000634:	0007c783          	lbu	a5,0(a5)
    80000638:	0007849b          	sext.w	s1,a5
    if(c == 0)
    8000063c:	cbed                	beqz	a5,8000072e <printf+0x1ac>
    switch(c){
    8000063e:	05778a63          	beq	a5,s7,80000692 <printf+0x110>
    80000642:	02fbf663          	bgeu	s7,a5,8000066e <printf+0xec>
    80000646:	09978863          	beq	a5,s9,800006d6 <printf+0x154>
    8000064a:	07800713          	li	a4,120
    8000064e:	0ce79563          	bne	a5,a4,80000718 <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000652:	f8843783          	ld	a5,-120(s0)
    80000656:	00878713          	addi	a4,a5,8
    8000065a:	f8e43423          	sd	a4,-120(s0)
    8000065e:	4605                	li	a2,1
    80000660:	85ea                	mv	a1,s10
    80000662:	4388                	lw	a0,0(a5)
    80000664:	00000097          	auipc	ra,0x0
    80000668:	e32080e7          	jalr	-462(ra) # 80000496 <printint>
      break;
    8000066c:	bf45                	j	8000061c <printf+0x9a>
    switch(c){
    8000066e:	09578f63          	beq	a5,s5,8000070c <printf+0x18a>
    80000672:	0b879363          	bne	a5,s8,80000718 <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    80000676:	f8843783          	ld	a5,-120(s0)
    8000067a:	00878713          	addi	a4,a5,8
    8000067e:	f8e43423          	sd	a4,-120(s0)
    80000682:	4605                	li	a2,1
    80000684:	45a9                	li	a1,10
    80000686:	4388                	lw	a0,0(a5)
    80000688:	00000097          	auipc	ra,0x0
    8000068c:	e0e080e7          	jalr	-498(ra) # 80000496 <printint>
      break;
    80000690:	b771                	j	8000061c <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000692:	f8843783          	ld	a5,-120(s0)
    80000696:	00878713          	addi	a4,a5,8
    8000069a:	f8e43423          	sd	a4,-120(s0)
    8000069e:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006a2:	03000513          	li	a0,48
    800006a6:	00000097          	auipc	ra,0x0
    800006aa:	bd0080e7          	jalr	-1072(ra) # 80000276 <consputc>
  consputc('x');
    800006ae:	07800513          	li	a0,120
    800006b2:	00000097          	auipc	ra,0x0
    800006b6:	bc4080e7          	jalr	-1084(ra) # 80000276 <consputc>
    800006ba:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006bc:	03c95793          	srli	a5,s2,0x3c
    800006c0:	97da                	add	a5,a5,s6
    800006c2:	0007c503          	lbu	a0,0(a5)
    800006c6:	00000097          	auipc	ra,0x0
    800006ca:	bb0080e7          	jalr	-1104(ra) # 80000276 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006ce:	0912                	slli	s2,s2,0x4
    800006d0:	34fd                	addiw	s1,s1,-1
    800006d2:	f4ed                	bnez	s1,800006bc <printf+0x13a>
    800006d4:	b7a1                	j	8000061c <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006d6:	f8843783          	ld	a5,-120(s0)
    800006da:	00878713          	addi	a4,a5,8
    800006de:	f8e43423          	sd	a4,-120(s0)
    800006e2:	6384                	ld	s1,0(a5)
    800006e4:	cc89                	beqz	s1,800006fe <printf+0x17c>
      for(; *s; s++)
    800006e6:	0004c503          	lbu	a0,0(s1)
    800006ea:	d90d                	beqz	a0,8000061c <printf+0x9a>
        consputc(*s);
    800006ec:	00000097          	auipc	ra,0x0
    800006f0:	b8a080e7          	jalr	-1142(ra) # 80000276 <consputc>
      for(; *s; s++)
    800006f4:	0485                	addi	s1,s1,1
    800006f6:	0004c503          	lbu	a0,0(s1)
    800006fa:	f96d                	bnez	a0,800006ec <printf+0x16a>
    800006fc:	b705                	j	8000061c <printf+0x9a>
        s = "(null)";
    800006fe:	00008497          	auipc	s1,0x8
    80000702:	92248493          	addi	s1,s1,-1758 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000706:	02800513          	li	a0,40
    8000070a:	b7cd                	j	800006ec <printf+0x16a>
      consputc('%');
    8000070c:	8556                	mv	a0,s5
    8000070e:	00000097          	auipc	ra,0x0
    80000712:	b68080e7          	jalr	-1176(ra) # 80000276 <consputc>
      break;
    80000716:	b719                	j	8000061c <printf+0x9a>
      consputc('%');
    80000718:	8556                	mv	a0,s5
    8000071a:	00000097          	auipc	ra,0x0
    8000071e:	b5c080e7          	jalr	-1188(ra) # 80000276 <consputc>
      consputc(c);
    80000722:	8526                	mv	a0,s1
    80000724:	00000097          	auipc	ra,0x0
    80000728:	b52080e7          	jalr	-1198(ra) # 80000276 <consputc>
      break;
    8000072c:	bdc5                	j	8000061c <printf+0x9a>
  if(locking)
    8000072e:	020d9163          	bnez	s11,80000750 <printf+0x1ce>
}
    80000732:	70e6                	ld	ra,120(sp)
    80000734:	7446                	ld	s0,112(sp)
    80000736:	74a6                	ld	s1,104(sp)
    80000738:	7906                	ld	s2,96(sp)
    8000073a:	69e6                	ld	s3,88(sp)
    8000073c:	6a46                	ld	s4,80(sp)
    8000073e:	6aa6                	ld	s5,72(sp)
    80000740:	6b06                	ld	s6,64(sp)
    80000742:	7be2                	ld	s7,56(sp)
    80000744:	7c42                	ld	s8,48(sp)
    80000746:	7ca2                	ld	s9,40(sp)
    80000748:	7d02                	ld	s10,32(sp)
    8000074a:	6de2                	ld	s11,24(sp)
    8000074c:	6129                	addi	sp,sp,192
    8000074e:	8082                	ret
    release(&pr.lock);
    80000750:	00010517          	auipc	a0,0x10
    80000754:	3f850513          	addi	a0,a0,1016 # 80010b48 <pr>
    80000758:	00000097          	auipc	ra,0x0
    8000075c:	52c080e7          	jalr	1324(ra) # 80000c84 <release>
}
    80000760:	bfc9                	j	80000732 <printf+0x1b0>

0000000080000762 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000762:	1101                	addi	sp,sp,-32
    80000764:	ec06                	sd	ra,24(sp)
    80000766:	e822                	sd	s0,16(sp)
    80000768:	e426                	sd	s1,8(sp)
    8000076a:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    8000076c:	00010497          	auipc	s1,0x10
    80000770:	3dc48493          	addi	s1,s1,988 # 80010b48 <pr>
    80000774:	00008597          	auipc	a1,0x8
    80000778:	8c458593          	addi	a1,a1,-1852 # 80008038 <etext+0x38>
    8000077c:	8526                	mv	a0,s1
    8000077e:	00000097          	auipc	ra,0x0
    80000782:	3c2080e7          	jalr	962(ra) # 80000b40 <initlock>
  pr.locking = 1;
    80000786:	4785                	li	a5,1
    80000788:	cc9c                	sw	a5,24(s1)
}
    8000078a:	60e2                	ld	ra,24(sp)
    8000078c:	6442                	ld	s0,16(sp)
    8000078e:	64a2                	ld	s1,8(sp)
    80000790:	6105                	addi	sp,sp,32
    80000792:	8082                	ret

0000000080000794 <uartinit>:

void uartstart();

void
uartinit(void)
{
    80000794:	1141                	addi	sp,sp,-16
    80000796:	e406                	sd	ra,8(sp)
    80000798:	e022                	sd	s0,0(sp)
    8000079a:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    8000079c:	100007b7          	lui	a5,0x10000
    800007a0:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007a4:	f8000713          	li	a4,-128
    800007a8:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007ac:	470d                	li	a4,3
    800007ae:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007b2:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007b6:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007ba:	469d                	li	a3,7
    800007bc:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c0:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007c4:	00008597          	auipc	a1,0x8
    800007c8:	89458593          	addi	a1,a1,-1900 # 80008058 <digits+0x18>
    800007cc:	00010517          	auipc	a0,0x10
    800007d0:	39c50513          	addi	a0,a0,924 # 80010b68 <uart_tx_lock>
    800007d4:	00000097          	auipc	ra,0x0
    800007d8:	36c080e7          	jalr	876(ra) # 80000b40 <initlock>
}
    800007dc:	60a2                	ld	ra,8(sp)
    800007de:	6402                	ld	s0,0(sp)
    800007e0:	0141                	addi	sp,sp,16
    800007e2:	8082                	ret

00000000800007e4 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007e4:	1101                	addi	sp,sp,-32
    800007e6:	ec06                	sd	ra,24(sp)
    800007e8:	e822                	sd	s0,16(sp)
    800007ea:	e426                	sd	s1,8(sp)
    800007ec:	1000                	addi	s0,sp,32
    800007ee:	84aa                	mv	s1,a0
  push_off();
    800007f0:	00000097          	auipc	ra,0x0
    800007f4:	394080e7          	jalr	916(ra) # 80000b84 <push_off>

  if(panicked){
    800007f8:	00008797          	auipc	a5,0x8
    800007fc:	1287a783          	lw	a5,296(a5) # 80008920 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000800:	10000737          	lui	a4,0x10000
  if(panicked){
    80000804:	c391                	beqz	a5,80000808 <uartputc_sync+0x24>
    for(;;)
    80000806:	a001                	j	80000806 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000808:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    8000080c:	0207f793          	andi	a5,a5,32
    80000810:	dfe5                	beqz	a5,80000808 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000812:	0ff4f513          	andi	a0,s1,255
    80000816:	100007b7          	lui	a5,0x10000
    8000081a:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    8000081e:	00000097          	auipc	ra,0x0
    80000822:	406080e7          	jalr	1030(ra) # 80000c24 <pop_off>
}
    80000826:	60e2                	ld	ra,24(sp)
    80000828:	6442                	ld	s0,16(sp)
    8000082a:	64a2                	ld	s1,8(sp)
    8000082c:	6105                	addi	sp,sp,32
    8000082e:	8082                	ret

0000000080000830 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000830:	00008797          	auipc	a5,0x8
    80000834:	0f87b783          	ld	a5,248(a5) # 80008928 <uart_tx_r>
    80000838:	00008717          	auipc	a4,0x8
    8000083c:	0f873703          	ld	a4,248(a4) # 80008930 <uart_tx_w>
    80000840:	06f70a63          	beq	a4,a5,800008b4 <uartstart+0x84>
{
    80000844:	7139                	addi	sp,sp,-64
    80000846:	fc06                	sd	ra,56(sp)
    80000848:	f822                	sd	s0,48(sp)
    8000084a:	f426                	sd	s1,40(sp)
    8000084c:	f04a                	sd	s2,32(sp)
    8000084e:	ec4e                	sd	s3,24(sp)
    80000850:	e852                	sd	s4,16(sp)
    80000852:	e456                	sd	s5,8(sp)
    80000854:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000856:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000085a:	00010a17          	auipc	s4,0x10
    8000085e:	30ea0a13          	addi	s4,s4,782 # 80010b68 <uart_tx_lock>
    uart_tx_r += 1;
    80000862:	00008497          	auipc	s1,0x8
    80000866:	0c648493          	addi	s1,s1,198 # 80008928 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000086a:	00008997          	auipc	s3,0x8
    8000086e:	0c698993          	addi	s3,s3,198 # 80008930 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000872:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000876:	02077713          	andi	a4,a4,32
    8000087a:	c705                	beqz	a4,800008a2 <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000087c:	01f7f713          	andi	a4,a5,31
    80000880:	9752                	add	a4,a4,s4
    80000882:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    80000886:	0785                	addi	a5,a5,1
    80000888:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000088a:	8526                	mv	a0,s1
    8000088c:	00002097          	auipc	ra,0x2
    80000890:	c0e080e7          	jalr	-1010(ra) # 8000249a <wakeup>
    
    WriteReg(THR, c);
    80000894:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    80000898:	609c                	ld	a5,0(s1)
    8000089a:	0009b703          	ld	a4,0(s3)
    8000089e:	fcf71ae3          	bne	a4,a5,80000872 <uartstart+0x42>
  }
}
    800008a2:	70e2                	ld	ra,56(sp)
    800008a4:	7442                	ld	s0,48(sp)
    800008a6:	74a2                	ld	s1,40(sp)
    800008a8:	7902                	ld	s2,32(sp)
    800008aa:	69e2                	ld	s3,24(sp)
    800008ac:	6a42                	ld	s4,16(sp)
    800008ae:	6aa2                	ld	s5,8(sp)
    800008b0:	6121                	addi	sp,sp,64
    800008b2:	8082                	ret
    800008b4:	8082                	ret

00000000800008b6 <uartputc>:
{
    800008b6:	7179                	addi	sp,sp,-48
    800008b8:	f406                	sd	ra,40(sp)
    800008ba:	f022                	sd	s0,32(sp)
    800008bc:	ec26                	sd	s1,24(sp)
    800008be:	e84a                	sd	s2,16(sp)
    800008c0:	e44e                	sd	s3,8(sp)
    800008c2:	e052                	sd	s4,0(sp)
    800008c4:	1800                	addi	s0,sp,48
    800008c6:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008c8:	00010517          	auipc	a0,0x10
    800008cc:	2a050513          	addi	a0,a0,672 # 80010b68 <uart_tx_lock>
    800008d0:	00000097          	auipc	ra,0x0
    800008d4:	300080e7          	jalr	768(ra) # 80000bd0 <acquire>
  if(panicked){
    800008d8:	00008797          	auipc	a5,0x8
    800008dc:	0487a783          	lw	a5,72(a5) # 80008920 <panicked>
    800008e0:	c391                	beqz	a5,800008e4 <uartputc+0x2e>
    for(;;)
    800008e2:	a001                	j	800008e2 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008e4:	00008717          	auipc	a4,0x8
    800008e8:	04c73703          	ld	a4,76(a4) # 80008930 <uart_tx_w>
    800008ec:	00008797          	auipc	a5,0x8
    800008f0:	03c7b783          	ld	a5,60(a5) # 80008928 <uart_tx_r>
    800008f4:	02078793          	addi	a5,a5,32
    800008f8:	02e79b63          	bne	a5,a4,8000092e <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    800008fc:	00010997          	auipc	s3,0x10
    80000900:	26c98993          	addi	s3,s3,620 # 80010b68 <uart_tx_lock>
    80000904:	00008497          	auipc	s1,0x8
    80000908:	02448493          	addi	s1,s1,36 # 80008928 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090c:	00008917          	auipc	s2,0x8
    80000910:	02490913          	addi	s2,s2,36 # 80008930 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000914:	85ce                	mv	a1,s3
    80000916:	8526                	mv	a0,s1
    80000918:	00002097          	auipc	ra,0x2
    8000091c:	9f0080e7          	jalr	-1552(ra) # 80002308 <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00093703          	ld	a4,0(s2)
    80000924:	609c                	ld	a5,0(s1)
    80000926:	02078793          	addi	a5,a5,32
    8000092a:	fee785e3          	beq	a5,a4,80000914 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    8000092e:	00010497          	auipc	s1,0x10
    80000932:	23a48493          	addi	s1,s1,570 # 80010b68 <uart_tx_lock>
    80000936:	01f77793          	andi	a5,a4,31
    8000093a:	97a6                	add	a5,a5,s1
    8000093c:	01478c23          	sb	s4,24(a5)
      uart_tx_w += 1;
    80000940:	0705                	addi	a4,a4,1
    80000942:	00008797          	auipc	a5,0x8
    80000946:	fee7b723          	sd	a4,-18(a5) # 80008930 <uart_tx_w>
      uartstart();
    8000094a:	00000097          	auipc	ra,0x0
    8000094e:	ee6080e7          	jalr	-282(ra) # 80000830 <uartstart>
      release(&uart_tx_lock);
    80000952:	8526                	mv	a0,s1
    80000954:	00000097          	auipc	ra,0x0
    80000958:	330080e7          	jalr	816(ra) # 80000c84 <release>
}
    8000095c:	70a2                	ld	ra,40(sp)
    8000095e:	7402                	ld	s0,32(sp)
    80000960:	64e2                	ld	s1,24(sp)
    80000962:	6942                	ld	s2,16(sp)
    80000964:	69a2                	ld	s3,8(sp)
    80000966:	6a02                	ld	s4,0(sp)
    80000968:	6145                	addi	sp,sp,48
    8000096a:	8082                	ret

000000008000096c <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    8000096c:	1141                	addi	sp,sp,-16
    8000096e:	e422                	sd	s0,8(sp)
    80000970:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000972:	100007b7          	lui	a5,0x10000
    80000976:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000097a:	8b85                	andi	a5,a5,1
    8000097c:	cb91                	beqz	a5,80000990 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    8000097e:	100007b7          	lui	a5,0x10000
    80000982:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    80000986:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    8000098a:	6422                	ld	s0,8(sp)
    8000098c:	0141                	addi	sp,sp,16
    8000098e:	8082                	ret
    return -1;
    80000990:	557d                	li	a0,-1
    80000992:	bfe5                	j	8000098a <uartgetc+0x1e>

0000000080000994 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    80000994:	1101                	addi	sp,sp,-32
    80000996:	ec06                	sd	ra,24(sp)
    80000998:	e822                	sd	s0,16(sp)
    8000099a:	e426                	sd	s1,8(sp)
    8000099c:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    8000099e:	54fd                	li	s1,-1
    800009a0:	a029                	j	800009aa <uartintr+0x16>
      break;
    consoleintr(c);
    800009a2:	00000097          	auipc	ra,0x0
    800009a6:	916080e7          	jalr	-1770(ra) # 800002b8 <consoleintr>
    int c = uartgetc();
    800009aa:	00000097          	auipc	ra,0x0
    800009ae:	fc2080e7          	jalr	-62(ra) # 8000096c <uartgetc>
    if(c == -1)
    800009b2:	fe9518e3          	bne	a0,s1,800009a2 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009b6:	00010497          	auipc	s1,0x10
    800009ba:	1b248493          	addi	s1,s1,434 # 80010b68 <uart_tx_lock>
    800009be:	8526                	mv	a0,s1
    800009c0:	00000097          	auipc	ra,0x0
    800009c4:	210080e7          	jalr	528(ra) # 80000bd0 <acquire>
  uartstart();
    800009c8:	00000097          	auipc	ra,0x0
    800009cc:	e68080e7          	jalr	-408(ra) # 80000830 <uartstart>
  release(&uart_tx_lock);
    800009d0:	8526                	mv	a0,s1
    800009d2:	00000097          	auipc	ra,0x0
    800009d6:	2b2080e7          	jalr	690(ra) # 80000c84 <release>
}
    800009da:	60e2                	ld	ra,24(sp)
    800009dc:	6442                	ld	s0,16(sp)
    800009de:	64a2                	ld	s1,8(sp)
    800009e0:	6105                	addi	sp,sp,32
    800009e2:	8082                	ret

00000000800009e4 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009e4:	1101                	addi	sp,sp,-32
    800009e6:	ec06                	sd	ra,24(sp)
    800009e8:	e822                	sd	s0,16(sp)
    800009ea:	e426                	sd	s1,8(sp)
    800009ec:	e04a                	sd	s2,0(sp)
    800009ee:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009f0:	03451793          	slli	a5,a0,0x34
    800009f4:	ebb9                	bnez	a5,80000a4a <kfree+0x66>
    800009f6:	84aa                	mv	s1,a0
    800009f8:	00023797          	auipc	a5,0x23
    800009fc:	ab078793          	addi	a5,a5,-1360 # 800234a8 <end>
    80000a00:	04f56563          	bltu	a0,a5,80000a4a <kfree+0x66>
    80000a04:	47c5                	li	a5,17
    80000a06:	07ee                	slli	a5,a5,0x1b
    80000a08:	04f57163          	bgeu	a0,a5,80000a4a <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a0c:	6605                	lui	a2,0x1
    80000a0e:	4585                	li	a1,1
    80000a10:	00000097          	auipc	ra,0x0
    80000a14:	2bc080e7          	jalr	700(ra) # 80000ccc <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a18:	00010917          	auipc	s2,0x10
    80000a1c:	18890913          	addi	s2,s2,392 # 80010ba0 <kmem>
    80000a20:	854a                	mv	a0,s2
    80000a22:	00000097          	auipc	ra,0x0
    80000a26:	1ae080e7          	jalr	430(ra) # 80000bd0 <acquire>
  r->next = kmem.freelist;
    80000a2a:	01893783          	ld	a5,24(s2)
    80000a2e:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a30:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a34:	854a                	mv	a0,s2
    80000a36:	00000097          	auipc	ra,0x0
    80000a3a:	24e080e7          	jalr	590(ra) # 80000c84 <release>
}
    80000a3e:	60e2                	ld	ra,24(sp)
    80000a40:	6442                	ld	s0,16(sp)
    80000a42:	64a2                	ld	s1,8(sp)
    80000a44:	6902                	ld	s2,0(sp)
    80000a46:	6105                	addi	sp,sp,32
    80000a48:	8082                	ret
    panic("kfree");
    80000a4a:	00007517          	auipc	a0,0x7
    80000a4e:	61650513          	addi	a0,a0,1558 # 80008060 <digits+0x20>
    80000a52:	00000097          	auipc	ra,0x0
    80000a56:	ae6080e7          	jalr	-1306(ra) # 80000538 <panic>

0000000080000a5a <freerange>:
{
    80000a5a:	7179                	addi	sp,sp,-48
    80000a5c:	f406                	sd	ra,40(sp)
    80000a5e:	f022                	sd	s0,32(sp)
    80000a60:	ec26                	sd	s1,24(sp)
    80000a62:	e84a                	sd	s2,16(sp)
    80000a64:	e44e                	sd	s3,8(sp)
    80000a66:	e052                	sd	s4,0(sp)
    80000a68:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a6a:	6785                	lui	a5,0x1
    80000a6c:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a70:	94aa                	add	s1,s1,a0
    80000a72:	757d                	lui	a0,0xfffff
    80000a74:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a76:	94be                	add	s1,s1,a5
    80000a78:	0095ee63          	bltu	a1,s1,80000a94 <freerange+0x3a>
    80000a7c:	892e                	mv	s2,a1
    kfree(p);
    80000a7e:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a80:	6985                	lui	s3,0x1
    kfree(p);
    80000a82:	01448533          	add	a0,s1,s4
    80000a86:	00000097          	auipc	ra,0x0
    80000a8a:	f5e080e7          	jalr	-162(ra) # 800009e4 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a8e:	94ce                	add	s1,s1,s3
    80000a90:	fe9979e3          	bgeu	s2,s1,80000a82 <freerange+0x28>
}
    80000a94:	70a2                	ld	ra,40(sp)
    80000a96:	7402                	ld	s0,32(sp)
    80000a98:	64e2                	ld	s1,24(sp)
    80000a9a:	6942                	ld	s2,16(sp)
    80000a9c:	69a2                	ld	s3,8(sp)
    80000a9e:	6a02                	ld	s4,0(sp)
    80000aa0:	6145                	addi	sp,sp,48
    80000aa2:	8082                	ret

0000000080000aa4 <kinit>:
{
    80000aa4:	1141                	addi	sp,sp,-16
    80000aa6:	e406                	sd	ra,8(sp)
    80000aa8:	e022                	sd	s0,0(sp)
    80000aaa:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000aac:	00007597          	auipc	a1,0x7
    80000ab0:	5bc58593          	addi	a1,a1,1468 # 80008068 <digits+0x28>
    80000ab4:	00010517          	auipc	a0,0x10
    80000ab8:	0ec50513          	addi	a0,a0,236 # 80010ba0 <kmem>
    80000abc:	00000097          	auipc	ra,0x0
    80000ac0:	084080e7          	jalr	132(ra) # 80000b40 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ac4:	45c5                	li	a1,17
    80000ac6:	05ee                	slli	a1,a1,0x1b
    80000ac8:	00023517          	auipc	a0,0x23
    80000acc:	9e050513          	addi	a0,a0,-1568 # 800234a8 <end>
    80000ad0:	00000097          	auipc	ra,0x0
    80000ad4:	f8a080e7          	jalr	-118(ra) # 80000a5a <freerange>
}
    80000ad8:	60a2                	ld	ra,8(sp)
    80000ada:	6402                	ld	s0,0(sp)
    80000adc:	0141                	addi	sp,sp,16
    80000ade:	8082                	ret

0000000080000ae0 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae0:	1101                	addi	sp,sp,-32
    80000ae2:	ec06                	sd	ra,24(sp)
    80000ae4:	e822                	sd	s0,16(sp)
    80000ae6:	e426                	sd	s1,8(sp)
    80000ae8:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000aea:	00010497          	auipc	s1,0x10
    80000aee:	0b648493          	addi	s1,s1,182 # 80010ba0 <kmem>
    80000af2:	8526                	mv	a0,s1
    80000af4:	00000097          	auipc	ra,0x0
    80000af8:	0dc080e7          	jalr	220(ra) # 80000bd0 <acquire>
  r = kmem.freelist;
    80000afc:	6c84                	ld	s1,24(s1)
  if(r)
    80000afe:	c885                	beqz	s1,80000b2e <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b00:	609c                	ld	a5,0(s1)
    80000b02:	00010517          	auipc	a0,0x10
    80000b06:	09e50513          	addi	a0,a0,158 # 80010ba0 <kmem>
    80000b0a:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b0c:	00000097          	auipc	ra,0x0
    80000b10:	178080e7          	jalr	376(ra) # 80000c84 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b14:	6605                	lui	a2,0x1
    80000b16:	4595                	li	a1,5
    80000b18:	8526                	mv	a0,s1
    80000b1a:	00000097          	auipc	ra,0x0
    80000b1e:	1b2080e7          	jalr	434(ra) # 80000ccc <memset>
  return (void*)r;
}
    80000b22:	8526                	mv	a0,s1
    80000b24:	60e2                	ld	ra,24(sp)
    80000b26:	6442                	ld	s0,16(sp)
    80000b28:	64a2                	ld	s1,8(sp)
    80000b2a:	6105                	addi	sp,sp,32
    80000b2c:	8082                	ret
  release(&kmem.lock);
    80000b2e:	00010517          	auipc	a0,0x10
    80000b32:	07250513          	addi	a0,a0,114 # 80010ba0 <kmem>
    80000b36:	00000097          	auipc	ra,0x0
    80000b3a:	14e080e7          	jalr	334(ra) # 80000c84 <release>
  if(r)
    80000b3e:	b7d5                	j	80000b22 <kalloc+0x42>

0000000080000b40 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b40:	1141                	addi	sp,sp,-16
    80000b42:	e422                	sd	s0,8(sp)
    80000b44:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b46:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b48:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b4c:	00053823          	sd	zero,16(a0)
}
    80000b50:	6422                	ld	s0,8(sp)
    80000b52:	0141                	addi	sp,sp,16
    80000b54:	8082                	ret

0000000080000b56 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b56:	411c                	lw	a5,0(a0)
    80000b58:	e399                	bnez	a5,80000b5e <holding+0x8>
    80000b5a:	4501                	li	a0,0
  return r;
}
    80000b5c:	8082                	ret
{
    80000b5e:	1101                	addi	sp,sp,-32
    80000b60:	ec06                	sd	ra,24(sp)
    80000b62:	e822                	sd	s0,16(sp)
    80000b64:	e426                	sd	s1,8(sp)
    80000b66:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b68:	6904                	ld	s1,16(a0)
    80000b6a:	00001097          	auipc	ra,0x1
    80000b6e:	e10080e7          	jalr	-496(ra) # 8000197a <mycpu>
    80000b72:	40a48533          	sub	a0,s1,a0
    80000b76:	00153513          	seqz	a0,a0
}
    80000b7a:	60e2                	ld	ra,24(sp)
    80000b7c:	6442                	ld	s0,16(sp)
    80000b7e:	64a2                	ld	s1,8(sp)
    80000b80:	6105                	addi	sp,sp,32
    80000b82:	8082                	ret

0000000080000b84 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b84:	1101                	addi	sp,sp,-32
    80000b86:	ec06                	sd	ra,24(sp)
    80000b88:	e822                	sd	s0,16(sp)
    80000b8a:	e426                	sd	s1,8(sp)
    80000b8c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b8e:	100024f3          	csrr	s1,sstatus
    80000b92:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b96:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b98:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000b9c:	00001097          	auipc	ra,0x1
    80000ba0:	dde080e7          	jalr	-546(ra) # 8000197a <mycpu>
    80000ba4:	5d3c                	lw	a5,120(a0)
    80000ba6:	cf89                	beqz	a5,80000bc0 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000ba8:	00001097          	auipc	ra,0x1
    80000bac:	dd2080e7          	jalr	-558(ra) # 8000197a <mycpu>
    80000bb0:	5d3c                	lw	a5,120(a0)
    80000bb2:	2785                	addiw	a5,a5,1
    80000bb4:	dd3c                	sw	a5,120(a0)
}
    80000bb6:	60e2                	ld	ra,24(sp)
    80000bb8:	6442                	ld	s0,16(sp)
    80000bba:	64a2                	ld	s1,8(sp)
    80000bbc:	6105                	addi	sp,sp,32
    80000bbe:	8082                	ret
    mycpu()->intena = old;
    80000bc0:	00001097          	auipc	ra,0x1
    80000bc4:	dba080e7          	jalr	-582(ra) # 8000197a <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bc8:	8085                	srli	s1,s1,0x1
    80000bca:	8885                	andi	s1,s1,1
    80000bcc:	dd64                	sw	s1,124(a0)
    80000bce:	bfe9                	j	80000ba8 <push_off+0x24>

0000000080000bd0 <acquire>:
{
    80000bd0:	1101                	addi	sp,sp,-32
    80000bd2:	ec06                	sd	ra,24(sp)
    80000bd4:	e822                	sd	s0,16(sp)
    80000bd6:	e426                	sd	s1,8(sp)
    80000bd8:	1000                	addi	s0,sp,32
    80000bda:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bdc:	00000097          	auipc	ra,0x0
    80000be0:	fa8080e7          	jalr	-88(ra) # 80000b84 <push_off>
  if(holding(lk))
    80000be4:	8526                	mv	a0,s1
    80000be6:	00000097          	auipc	ra,0x0
    80000bea:	f70080e7          	jalr	-144(ra) # 80000b56 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bee:	4705                	li	a4,1
  if(holding(lk))
    80000bf0:	e115                	bnez	a0,80000c14 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf2:	87ba                	mv	a5,a4
    80000bf4:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bf8:	2781                	sext.w	a5,a5
    80000bfa:	ffe5                	bnez	a5,80000bf2 <acquire+0x22>
  __sync_synchronize();
    80000bfc:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c00:	00001097          	auipc	ra,0x1
    80000c04:	d7a080e7          	jalr	-646(ra) # 8000197a <mycpu>
    80000c08:	e888                	sd	a0,16(s1)
}
    80000c0a:	60e2                	ld	ra,24(sp)
    80000c0c:	6442                	ld	s0,16(sp)
    80000c0e:	64a2                	ld	s1,8(sp)
    80000c10:	6105                	addi	sp,sp,32
    80000c12:	8082                	ret
    panic("acquire");
    80000c14:	00007517          	auipc	a0,0x7
    80000c18:	45c50513          	addi	a0,a0,1116 # 80008070 <digits+0x30>
    80000c1c:	00000097          	auipc	ra,0x0
    80000c20:	91c080e7          	jalr	-1764(ra) # 80000538 <panic>

0000000080000c24 <pop_off>:

void
pop_off(void)
{
    80000c24:	1141                	addi	sp,sp,-16
    80000c26:	e406                	sd	ra,8(sp)
    80000c28:	e022                	sd	s0,0(sp)
    80000c2a:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c2c:	00001097          	auipc	ra,0x1
    80000c30:	d4e080e7          	jalr	-690(ra) # 8000197a <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c34:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c38:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c3a:	e78d                	bnez	a5,80000c64 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c3c:	5d3c                	lw	a5,120(a0)
    80000c3e:	02f05b63          	blez	a5,80000c74 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c42:	37fd                	addiw	a5,a5,-1
    80000c44:	0007871b          	sext.w	a4,a5
    80000c48:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c4a:	eb09                	bnez	a4,80000c5c <pop_off+0x38>
    80000c4c:	5d7c                	lw	a5,124(a0)
    80000c4e:	c799                	beqz	a5,80000c5c <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c50:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c54:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c58:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c5c:	60a2                	ld	ra,8(sp)
    80000c5e:	6402                	ld	s0,0(sp)
    80000c60:	0141                	addi	sp,sp,16
    80000c62:	8082                	ret
    panic("pop_off - interruptible");
    80000c64:	00007517          	auipc	a0,0x7
    80000c68:	41450513          	addi	a0,a0,1044 # 80008078 <digits+0x38>
    80000c6c:	00000097          	auipc	ra,0x0
    80000c70:	8cc080e7          	jalr	-1844(ra) # 80000538 <panic>
    panic("pop_off");
    80000c74:	00007517          	auipc	a0,0x7
    80000c78:	41c50513          	addi	a0,a0,1052 # 80008090 <digits+0x50>
    80000c7c:	00000097          	auipc	ra,0x0
    80000c80:	8bc080e7          	jalr	-1860(ra) # 80000538 <panic>

0000000080000c84 <release>:
{
    80000c84:	1101                	addi	sp,sp,-32
    80000c86:	ec06                	sd	ra,24(sp)
    80000c88:	e822                	sd	s0,16(sp)
    80000c8a:	e426                	sd	s1,8(sp)
    80000c8c:	1000                	addi	s0,sp,32
    80000c8e:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c90:	00000097          	auipc	ra,0x0
    80000c94:	ec6080e7          	jalr	-314(ra) # 80000b56 <holding>
    80000c98:	c115                	beqz	a0,80000cbc <release+0x38>
  lk->cpu = 0;
    80000c9a:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000c9e:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ca2:	0f50000f          	fence	iorw,ow
    80000ca6:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000caa:	00000097          	auipc	ra,0x0
    80000cae:	f7a080e7          	jalr	-134(ra) # 80000c24 <pop_off>
}
    80000cb2:	60e2                	ld	ra,24(sp)
    80000cb4:	6442                	ld	s0,16(sp)
    80000cb6:	64a2                	ld	s1,8(sp)
    80000cb8:	6105                	addi	sp,sp,32
    80000cba:	8082                	ret
    panic("release");
    80000cbc:	00007517          	auipc	a0,0x7
    80000cc0:	3dc50513          	addi	a0,a0,988 # 80008098 <digits+0x58>
    80000cc4:	00000097          	auipc	ra,0x0
    80000cc8:	874080e7          	jalr	-1932(ra) # 80000538 <panic>

0000000080000ccc <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ccc:	1141                	addi	sp,sp,-16
    80000cce:	e422                	sd	s0,8(sp)
    80000cd0:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cd2:	ca19                	beqz	a2,80000ce8 <memset+0x1c>
    80000cd4:	87aa                	mv	a5,a0
    80000cd6:	1602                	slli	a2,a2,0x20
    80000cd8:	9201                	srli	a2,a2,0x20
    80000cda:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000cde:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000ce2:	0785                	addi	a5,a5,1
    80000ce4:	fee79de3          	bne	a5,a4,80000cde <memset+0x12>
  }
  return dst;
}
    80000ce8:	6422                	ld	s0,8(sp)
    80000cea:	0141                	addi	sp,sp,16
    80000cec:	8082                	ret

0000000080000cee <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cee:	1141                	addi	sp,sp,-16
    80000cf0:	e422                	sd	s0,8(sp)
    80000cf2:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cf4:	ca05                	beqz	a2,80000d24 <memcmp+0x36>
    80000cf6:	fff6069b          	addiw	a3,a2,-1
    80000cfa:	1682                	slli	a3,a3,0x20
    80000cfc:	9281                	srli	a3,a3,0x20
    80000cfe:	0685                	addi	a3,a3,1
    80000d00:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d02:	00054783          	lbu	a5,0(a0)
    80000d06:	0005c703          	lbu	a4,0(a1)
    80000d0a:	00e79863          	bne	a5,a4,80000d1a <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d0e:	0505                	addi	a0,a0,1
    80000d10:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d12:	fed518e3          	bne	a0,a3,80000d02 <memcmp+0x14>
  }

  return 0;
    80000d16:	4501                	li	a0,0
    80000d18:	a019                	j	80000d1e <memcmp+0x30>
      return *s1 - *s2;
    80000d1a:	40e7853b          	subw	a0,a5,a4
}
    80000d1e:	6422                	ld	s0,8(sp)
    80000d20:	0141                	addi	sp,sp,16
    80000d22:	8082                	ret
  return 0;
    80000d24:	4501                	li	a0,0
    80000d26:	bfe5                	j	80000d1e <memcmp+0x30>

0000000080000d28 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d28:	1141                	addi	sp,sp,-16
    80000d2a:	e422                	sd	s0,8(sp)
    80000d2c:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d2e:	c205                	beqz	a2,80000d4e <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d30:	02a5e263          	bltu	a1,a0,80000d54 <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d34:	1602                	slli	a2,a2,0x20
    80000d36:	9201                	srli	a2,a2,0x20
    80000d38:	00c587b3          	add	a5,a1,a2
{
    80000d3c:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d3e:	0585                	addi	a1,a1,1
    80000d40:	0705                	addi	a4,a4,1
    80000d42:	fff5c683          	lbu	a3,-1(a1)
    80000d46:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d4a:	fef59ae3          	bne	a1,a5,80000d3e <memmove+0x16>

  return dst;
}
    80000d4e:	6422                	ld	s0,8(sp)
    80000d50:	0141                	addi	sp,sp,16
    80000d52:	8082                	ret
  if(s < d && s + n > d){
    80000d54:	02061693          	slli	a3,a2,0x20
    80000d58:	9281                	srli	a3,a3,0x20
    80000d5a:	00d58733          	add	a4,a1,a3
    80000d5e:	fce57be3          	bgeu	a0,a4,80000d34 <memmove+0xc>
    d += n;
    80000d62:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d64:	fff6079b          	addiw	a5,a2,-1
    80000d68:	1782                	slli	a5,a5,0x20
    80000d6a:	9381                	srli	a5,a5,0x20
    80000d6c:	fff7c793          	not	a5,a5
    80000d70:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d72:	177d                	addi	a4,a4,-1
    80000d74:	16fd                	addi	a3,a3,-1
    80000d76:	00074603          	lbu	a2,0(a4)
    80000d7a:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d7e:	fee79ae3          	bne	a5,a4,80000d72 <memmove+0x4a>
    80000d82:	b7f1                	j	80000d4e <memmove+0x26>

0000000080000d84 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d84:	1141                	addi	sp,sp,-16
    80000d86:	e406                	sd	ra,8(sp)
    80000d88:	e022                	sd	s0,0(sp)
    80000d8a:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d8c:	00000097          	auipc	ra,0x0
    80000d90:	f9c080e7          	jalr	-100(ra) # 80000d28 <memmove>
}
    80000d94:	60a2                	ld	ra,8(sp)
    80000d96:	6402                	ld	s0,0(sp)
    80000d98:	0141                	addi	sp,sp,16
    80000d9a:	8082                	ret

0000000080000d9c <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000d9c:	1141                	addi	sp,sp,-16
    80000d9e:	e422                	sd	s0,8(sp)
    80000da0:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000da2:	ce11                	beqz	a2,80000dbe <strncmp+0x22>
    80000da4:	00054783          	lbu	a5,0(a0)
    80000da8:	cf89                	beqz	a5,80000dc2 <strncmp+0x26>
    80000daa:	0005c703          	lbu	a4,0(a1)
    80000dae:	00f71a63          	bne	a4,a5,80000dc2 <strncmp+0x26>
    n--, p++, q++;
    80000db2:	367d                	addiw	a2,a2,-1
    80000db4:	0505                	addi	a0,a0,1
    80000db6:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000db8:	f675                	bnez	a2,80000da4 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dba:	4501                	li	a0,0
    80000dbc:	a809                	j	80000dce <strncmp+0x32>
    80000dbe:	4501                	li	a0,0
    80000dc0:	a039                	j	80000dce <strncmp+0x32>
  if(n == 0)
    80000dc2:	ca09                	beqz	a2,80000dd4 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dc4:	00054503          	lbu	a0,0(a0)
    80000dc8:	0005c783          	lbu	a5,0(a1)
    80000dcc:	9d1d                	subw	a0,a0,a5
}
    80000dce:	6422                	ld	s0,8(sp)
    80000dd0:	0141                	addi	sp,sp,16
    80000dd2:	8082                	ret
    return 0;
    80000dd4:	4501                	li	a0,0
    80000dd6:	bfe5                	j	80000dce <strncmp+0x32>

0000000080000dd8 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dd8:	1141                	addi	sp,sp,-16
    80000dda:	e422                	sd	s0,8(sp)
    80000ddc:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000dde:	872a                	mv	a4,a0
    80000de0:	8832                	mv	a6,a2
    80000de2:	367d                	addiw	a2,a2,-1
    80000de4:	01005963          	blez	a6,80000df6 <strncpy+0x1e>
    80000de8:	0705                	addi	a4,a4,1
    80000dea:	0005c783          	lbu	a5,0(a1)
    80000dee:	fef70fa3          	sb	a5,-1(a4)
    80000df2:	0585                	addi	a1,a1,1
    80000df4:	f7f5                	bnez	a5,80000de0 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000df6:	86ba                	mv	a3,a4
    80000df8:	00c05c63          	blez	a2,80000e10 <strncpy+0x38>
    *s++ = 0;
    80000dfc:	0685                	addi	a3,a3,1
    80000dfe:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e02:	fff6c793          	not	a5,a3
    80000e06:	9fb9                	addw	a5,a5,a4
    80000e08:	010787bb          	addw	a5,a5,a6
    80000e0c:	fef048e3          	bgtz	a5,80000dfc <strncpy+0x24>
  return os;
}
    80000e10:	6422                	ld	s0,8(sp)
    80000e12:	0141                	addi	sp,sp,16
    80000e14:	8082                	ret

0000000080000e16 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e16:	1141                	addi	sp,sp,-16
    80000e18:	e422                	sd	s0,8(sp)
    80000e1a:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e1c:	02c05363          	blez	a2,80000e42 <safestrcpy+0x2c>
    80000e20:	fff6069b          	addiw	a3,a2,-1
    80000e24:	1682                	slli	a3,a3,0x20
    80000e26:	9281                	srli	a3,a3,0x20
    80000e28:	96ae                	add	a3,a3,a1
    80000e2a:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e2c:	00d58963          	beq	a1,a3,80000e3e <safestrcpy+0x28>
    80000e30:	0585                	addi	a1,a1,1
    80000e32:	0785                	addi	a5,a5,1
    80000e34:	fff5c703          	lbu	a4,-1(a1)
    80000e38:	fee78fa3          	sb	a4,-1(a5)
    80000e3c:	fb65                	bnez	a4,80000e2c <safestrcpy+0x16>
    ;
  *s = 0;
    80000e3e:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e42:	6422                	ld	s0,8(sp)
    80000e44:	0141                	addi	sp,sp,16
    80000e46:	8082                	ret

0000000080000e48 <strlen>:

int
strlen(const char *s)
{
    80000e48:	1141                	addi	sp,sp,-16
    80000e4a:	e422                	sd	s0,8(sp)
    80000e4c:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e4e:	00054783          	lbu	a5,0(a0)
    80000e52:	cf91                	beqz	a5,80000e6e <strlen+0x26>
    80000e54:	0505                	addi	a0,a0,1
    80000e56:	87aa                	mv	a5,a0
    80000e58:	4685                	li	a3,1
    80000e5a:	9e89                	subw	a3,a3,a0
    80000e5c:	00f6853b          	addw	a0,a3,a5
    80000e60:	0785                	addi	a5,a5,1
    80000e62:	fff7c703          	lbu	a4,-1(a5)
    80000e66:	fb7d                	bnez	a4,80000e5c <strlen+0x14>
    ;
  return n;
}
    80000e68:	6422                	ld	s0,8(sp)
    80000e6a:	0141                	addi	sp,sp,16
    80000e6c:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e6e:	4501                	li	a0,0
    80000e70:	bfe5                	j	80000e68 <strlen+0x20>

0000000080000e72 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e72:	1141                	addi	sp,sp,-16
    80000e74:	e406                	sd	ra,8(sp)
    80000e76:	e022                	sd	s0,0(sp)
    80000e78:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e7a:	00001097          	auipc	ra,0x1
    80000e7e:	af0080e7          	jalr	-1296(ra) # 8000196a <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e82:	00008717          	auipc	a4,0x8
    80000e86:	ab670713          	addi	a4,a4,-1354 # 80008938 <started>
  if(cpuid() == 0){
    80000e8a:	c139                	beqz	a0,80000ed0 <main+0x5e>
    while(started == 0)
    80000e8c:	431c                	lw	a5,0(a4)
    80000e8e:	2781                	sext.w	a5,a5
    80000e90:	dff5                	beqz	a5,80000e8c <main+0x1a>
      ;
    __sync_synchronize();
    80000e92:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e96:	00001097          	auipc	ra,0x1
    80000e9a:	ad4080e7          	jalr	-1324(ra) # 8000196a <cpuid>
    80000e9e:	85aa                	mv	a1,a0
    80000ea0:	00007517          	auipc	a0,0x7
    80000ea4:	21850513          	addi	a0,a0,536 # 800080b8 <digits+0x78>
    80000ea8:	fffff097          	auipc	ra,0xfffff
    80000eac:	6da080e7          	jalr	1754(ra) # 80000582 <printf>
    kvminithart();    // turn on paging
    80000eb0:	00000097          	auipc	ra,0x0
    80000eb4:	0d8080e7          	jalr	216(ra) # 80000f88 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000eb8:	00002097          	auipc	ra,0x2
    80000ebc:	9e6080e7          	jalr	-1562(ra) # 8000289e <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec0:	00005097          	auipc	ra,0x5
    80000ec4:	360080e7          	jalr	864(ra) # 80006220 <plicinithart>
  }

  scheduler();        
    80000ec8:	00001097          	auipc	ra,0x1
    80000ecc:	2ca080e7          	jalr	714(ra) # 80002192 <scheduler>
    consoleinit();
    80000ed0:	fffff097          	auipc	ra,0xfffff
    80000ed4:	57a080e7          	jalr	1402(ra) # 8000044a <consoleinit>
    printfinit();
    80000ed8:	00000097          	auipc	ra,0x0
    80000edc:	88a080e7          	jalr	-1910(ra) # 80000762 <printfinit>
    printf("\n");
    80000ee0:	00007517          	auipc	a0,0x7
    80000ee4:	1e850513          	addi	a0,a0,488 # 800080c8 <digits+0x88>
    80000ee8:	fffff097          	auipc	ra,0xfffff
    80000eec:	69a080e7          	jalr	1690(ra) # 80000582 <printf>
    printf("xv6 kernel is booting\n");
    80000ef0:	00007517          	auipc	a0,0x7
    80000ef4:	1b050513          	addi	a0,a0,432 # 800080a0 <digits+0x60>
    80000ef8:	fffff097          	auipc	ra,0xfffff
    80000efc:	68a080e7          	jalr	1674(ra) # 80000582 <printf>
    printf("\n");
    80000f00:	00007517          	auipc	a0,0x7
    80000f04:	1c850513          	addi	a0,a0,456 # 800080c8 <digits+0x88>
    80000f08:	fffff097          	auipc	ra,0xfffff
    80000f0c:	67a080e7          	jalr	1658(ra) # 80000582 <printf>
    kinit();         // physical page allocator
    80000f10:	00000097          	auipc	ra,0x0
    80000f14:	b94080e7          	jalr	-1132(ra) # 80000aa4 <kinit>
    kvminit();       // create kernel page table
    80000f18:	00000097          	auipc	ra,0x0
    80000f1c:	322080e7          	jalr	802(ra) # 8000123a <kvminit>
    kvminithart();   // turn on paging
    80000f20:	00000097          	auipc	ra,0x0
    80000f24:	068080e7          	jalr	104(ra) # 80000f88 <kvminithart>
    procinit();      // process table
    80000f28:	00001097          	auipc	ra,0x1
    80000f2c:	992080e7          	jalr	-1646(ra) # 800018ba <procinit>
    trapinit();      // trap vectors
    80000f30:	00002097          	auipc	ra,0x2
    80000f34:	946080e7          	jalr	-1722(ra) # 80002876 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f38:	00002097          	auipc	ra,0x2
    80000f3c:	966080e7          	jalr	-1690(ra) # 8000289e <trapinithart>
    plicinit();      // set up interrupt controller
    80000f40:	00005097          	auipc	ra,0x5
    80000f44:	2ca080e7          	jalr	714(ra) # 8000620a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f48:	00005097          	auipc	ra,0x5
    80000f4c:	2d8080e7          	jalr	728(ra) # 80006220 <plicinithart>
    binit();         // buffer cache
    80000f50:	00002097          	auipc	ra,0x2
    80000f54:	490080e7          	jalr	1168(ra) # 800033e0 <binit>
    iinit();         // inode table
    80000f58:	00003097          	auipc	ra,0x3
    80000f5c:	b34080e7          	jalr	-1228(ra) # 80003a8c <iinit>
    fileinit();      // file table
    80000f60:	00004097          	auipc	ra,0x4
    80000f64:	ade080e7          	jalr	-1314(ra) # 80004a3e <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f68:	00005097          	auipc	ra,0x5
    80000f6c:	3c0080e7          	jalr	960(ra) # 80006328 <virtio_disk_init>
    userinit();      // first user process
    80000f70:	00001097          	auipc	ra,0x1
    80000f74:	d3c080e7          	jalr	-708(ra) # 80001cac <userinit>
    __sync_synchronize();
    80000f78:	0ff0000f          	fence
    started = 1;
    80000f7c:	4785                	li	a5,1
    80000f7e:	00008717          	auipc	a4,0x8
    80000f82:	9af72d23          	sw	a5,-1606(a4) # 80008938 <started>
    80000f86:	b789                	j	80000ec8 <main+0x56>

0000000080000f88 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f88:	1141                	addi	sp,sp,-16
    80000f8a:	e422                	sd	s0,8(sp)
    80000f8c:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000f8e:	00008797          	auipc	a5,0x8
    80000f92:	9b27b783          	ld	a5,-1614(a5) # 80008940 <kernel_pagetable>
    80000f96:	83b1                	srli	a5,a5,0xc
    80000f98:	577d                	li	a4,-1
    80000f9a:	177e                	slli	a4,a4,0x3f
    80000f9c:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000f9e:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fa2:	12000073          	sfence.vma
  sfence_vma();
}
    80000fa6:	6422                	ld	s0,8(sp)
    80000fa8:	0141                	addi	sp,sp,16
    80000faa:	8082                	ret

0000000080000fac <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fac:	7139                	addi	sp,sp,-64
    80000fae:	fc06                	sd	ra,56(sp)
    80000fb0:	f822                	sd	s0,48(sp)
    80000fb2:	f426                	sd	s1,40(sp)
    80000fb4:	f04a                	sd	s2,32(sp)
    80000fb6:	ec4e                	sd	s3,24(sp)
    80000fb8:	e852                	sd	s4,16(sp)
    80000fba:	e456                	sd	s5,8(sp)
    80000fbc:	e05a                	sd	s6,0(sp)
    80000fbe:	0080                	addi	s0,sp,64
    80000fc0:	84aa                	mv	s1,a0
    80000fc2:	89ae                	mv	s3,a1
    80000fc4:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fc6:	57fd                	li	a5,-1
    80000fc8:	83e9                	srli	a5,a5,0x1a
    80000fca:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fcc:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fce:	04b7f263          	bgeu	a5,a1,80001012 <walk+0x66>
    panic("walk");
    80000fd2:	00007517          	auipc	a0,0x7
    80000fd6:	0fe50513          	addi	a0,a0,254 # 800080d0 <digits+0x90>
    80000fda:	fffff097          	auipc	ra,0xfffff
    80000fde:	55e080e7          	jalr	1374(ra) # 80000538 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fe2:	060a8663          	beqz	s5,8000104e <walk+0xa2>
    80000fe6:	00000097          	auipc	ra,0x0
    80000fea:	afa080e7          	jalr	-1286(ra) # 80000ae0 <kalloc>
    80000fee:	84aa                	mv	s1,a0
    80000ff0:	c529                	beqz	a0,8000103a <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000ff2:	6605                	lui	a2,0x1
    80000ff4:	4581                	li	a1,0
    80000ff6:	00000097          	auipc	ra,0x0
    80000ffa:	cd6080e7          	jalr	-810(ra) # 80000ccc <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80000ffe:	00c4d793          	srli	a5,s1,0xc
    80001002:	07aa                	slli	a5,a5,0xa
    80001004:	0017e793          	ori	a5,a5,1
    80001008:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    8000100c:	3a5d                	addiw	s4,s4,-9
    8000100e:	036a0063          	beq	s4,s6,8000102e <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001012:	0149d933          	srl	s2,s3,s4
    80001016:	1ff97913          	andi	s2,s2,511
    8000101a:	090e                	slli	s2,s2,0x3
    8000101c:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000101e:	00093483          	ld	s1,0(s2)
    80001022:	0014f793          	andi	a5,s1,1
    80001026:	dfd5                	beqz	a5,80000fe2 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001028:	80a9                	srli	s1,s1,0xa
    8000102a:	04b2                	slli	s1,s1,0xc
    8000102c:	b7c5                	j	8000100c <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000102e:	00c9d513          	srli	a0,s3,0xc
    80001032:	1ff57513          	andi	a0,a0,511
    80001036:	050e                	slli	a0,a0,0x3
    80001038:	9526                	add	a0,a0,s1
}
    8000103a:	70e2                	ld	ra,56(sp)
    8000103c:	7442                	ld	s0,48(sp)
    8000103e:	74a2                	ld	s1,40(sp)
    80001040:	7902                	ld	s2,32(sp)
    80001042:	69e2                	ld	s3,24(sp)
    80001044:	6a42                	ld	s4,16(sp)
    80001046:	6aa2                	ld	s5,8(sp)
    80001048:	6b02                	ld	s6,0(sp)
    8000104a:	6121                	addi	sp,sp,64
    8000104c:	8082                	ret
        return 0;
    8000104e:	4501                	li	a0,0
    80001050:	b7ed                	j	8000103a <walk+0x8e>

0000000080001052 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001052:	57fd                	li	a5,-1
    80001054:	83e9                	srli	a5,a5,0x1a
    80001056:	00b7f463          	bgeu	a5,a1,8000105e <walkaddr+0xc>
    return 0;
    8000105a:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    8000105c:	8082                	ret
{
    8000105e:	1141                	addi	sp,sp,-16
    80001060:	e406                	sd	ra,8(sp)
    80001062:	e022                	sd	s0,0(sp)
    80001064:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001066:	4601                	li	a2,0
    80001068:	00000097          	auipc	ra,0x0
    8000106c:	f44080e7          	jalr	-188(ra) # 80000fac <walk>
  if(pte == 0)
    80001070:	c105                	beqz	a0,80001090 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001072:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001074:	0117f693          	andi	a3,a5,17
    80001078:	4745                	li	a4,17
    return 0;
    8000107a:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    8000107c:	00e68663          	beq	a3,a4,80001088 <walkaddr+0x36>
}
    80001080:	60a2                	ld	ra,8(sp)
    80001082:	6402                	ld	s0,0(sp)
    80001084:	0141                	addi	sp,sp,16
    80001086:	8082                	ret
  pa = PTE2PA(*pte);
    80001088:	00a7d513          	srli	a0,a5,0xa
    8000108c:	0532                	slli	a0,a0,0xc
  return pa;
    8000108e:	bfcd                	j	80001080 <walkaddr+0x2e>
    return 0;
    80001090:	4501                	li	a0,0
    80001092:	b7fd                	j	80001080 <walkaddr+0x2e>

0000000080001094 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001094:	715d                	addi	sp,sp,-80
    80001096:	e486                	sd	ra,72(sp)
    80001098:	e0a2                	sd	s0,64(sp)
    8000109a:	fc26                	sd	s1,56(sp)
    8000109c:	f84a                	sd	s2,48(sp)
    8000109e:	f44e                	sd	s3,40(sp)
    800010a0:	f052                	sd	s4,32(sp)
    800010a2:	ec56                	sd	s5,24(sp)
    800010a4:	e85a                	sd	s6,16(sp)
    800010a6:	e45e                	sd	s7,8(sp)
    800010a8:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010aa:	c639                	beqz	a2,800010f8 <mappages+0x64>
    800010ac:	8aaa                	mv	s5,a0
    800010ae:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010b0:	77fd                	lui	a5,0xfffff
    800010b2:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010b6:	15fd                	addi	a1,a1,-1
    800010b8:	00c589b3          	add	s3,a1,a2
    800010bc:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010c0:	8952                	mv	s2,s4
    800010c2:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010c6:	6b85                	lui	s7,0x1
    800010c8:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010cc:	4605                	li	a2,1
    800010ce:	85ca                	mv	a1,s2
    800010d0:	8556                	mv	a0,s5
    800010d2:	00000097          	auipc	ra,0x0
    800010d6:	eda080e7          	jalr	-294(ra) # 80000fac <walk>
    800010da:	cd1d                	beqz	a0,80001118 <mappages+0x84>
    if(*pte & PTE_V)
    800010dc:	611c                	ld	a5,0(a0)
    800010de:	8b85                	andi	a5,a5,1
    800010e0:	e785                	bnez	a5,80001108 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010e2:	80b1                	srli	s1,s1,0xc
    800010e4:	04aa                	slli	s1,s1,0xa
    800010e6:	0164e4b3          	or	s1,s1,s6
    800010ea:	0014e493          	ori	s1,s1,1
    800010ee:	e104                	sd	s1,0(a0)
    if(a == last)
    800010f0:	05390063          	beq	s2,s3,80001130 <mappages+0x9c>
    a += PGSIZE;
    800010f4:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800010f6:	bfc9                	j	800010c8 <mappages+0x34>
    panic("mappages: size");
    800010f8:	00007517          	auipc	a0,0x7
    800010fc:	fe050513          	addi	a0,a0,-32 # 800080d8 <digits+0x98>
    80001100:	fffff097          	auipc	ra,0xfffff
    80001104:	438080e7          	jalr	1080(ra) # 80000538 <panic>
      panic("mappages: remap");
    80001108:	00007517          	auipc	a0,0x7
    8000110c:	fe050513          	addi	a0,a0,-32 # 800080e8 <digits+0xa8>
    80001110:	fffff097          	auipc	ra,0xfffff
    80001114:	428080e7          	jalr	1064(ra) # 80000538 <panic>
      return -1;
    80001118:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    8000111a:	60a6                	ld	ra,72(sp)
    8000111c:	6406                	ld	s0,64(sp)
    8000111e:	74e2                	ld	s1,56(sp)
    80001120:	7942                	ld	s2,48(sp)
    80001122:	79a2                	ld	s3,40(sp)
    80001124:	7a02                	ld	s4,32(sp)
    80001126:	6ae2                	ld	s5,24(sp)
    80001128:	6b42                	ld	s6,16(sp)
    8000112a:	6ba2                	ld	s7,8(sp)
    8000112c:	6161                	addi	sp,sp,80
    8000112e:	8082                	ret
  return 0;
    80001130:	4501                	li	a0,0
    80001132:	b7e5                	j	8000111a <mappages+0x86>

0000000080001134 <kvmmap>:
{
    80001134:	1141                	addi	sp,sp,-16
    80001136:	e406                	sd	ra,8(sp)
    80001138:	e022                	sd	s0,0(sp)
    8000113a:	0800                	addi	s0,sp,16
    8000113c:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000113e:	86b2                	mv	a3,a2
    80001140:	863e                	mv	a2,a5
    80001142:	00000097          	auipc	ra,0x0
    80001146:	f52080e7          	jalr	-174(ra) # 80001094 <mappages>
    8000114a:	e509                	bnez	a0,80001154 <kvmmap+0x20>
}
    8000114c:	60a2                	ld	ra,8(sp)
    8000114e:	6402                	ld	s0,0(sp)
    80001150:	0141                	addi	sp,sp,16
    80001152:	8082                	ret
    panic("kvmmap");
    80001154:	00007517          	auipc	a0,0x7
    80001158:	fa450513          	addi	a0,a0,-92 # 800080f8 <digits+0xb8>
    8000115c:	fffff097          	auipc	ra,0xfffff
    80001160:	3dc080e7          	jalr	988(ra) # 80000538 <panic>

0000000080001164 <kvmmake>:
{
    80001164:	1101                	addi	sp,sp,-32
    80001166:	ec06                	sd	ra,24(sp)
    80001168:	e822                	sd	s0,16(sp)
    8000116a:	e426                	sd	s1,8(sp)
    8000116c:	e04a                	sd	s2,0(sp)
    8000116e:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001170:	00000097          	auipc	ra,0x0
    80001174:	970080e7          	jalr	-1680(ra) # 80000ae0 <kalloc>
    80001178:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    8000117a:	6605                	lui	a2,0x1
    8000117c:	4581                	li	a1,0
    8000117e:	00000097          	auipc	ra,0x0
    80001182:	b4e080e7          	jalr	-1202(ra) # 80000ccc <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001186:	4719                	li	a4,6
    80001188:	6685                	lui	a3,0x1
    8000118a:	10000637          	lui	a2,0x10000
    8000118e:	100005b7          	lui	a1,0x10000
    80001192:	8526                	mv	a0,s1
    80001194:	00000097          	auipc	ra,0x0
    80001198:	fa0080e7          	jalr	-96(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    8000119c:	4719                	li	a4,6
    8000119e:	6685                	lui	a3,0x1
    800011a0:	10001637          	lui	a2,0x10001
    800011a4:	100015b7          	lui	a1,0x10001
    800011a8:	8526                	mv	a0,s1
    800011aa:	00000097          	auipc	ra,0x0
    800011ae:	f8a080e7          	jalr	-118(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011b2:	4719                	li	a4,6
    800011b4:	004006b7          	lui	a3,0x400
    800011b8:	0c000637          	lui	a2,0xc000
    800011bc:	0c0005b7          	lui	a1,0xc000
    800011c0:	8526                	mv	a0,s1
    800011c2:	00000097          	auipc	ra,0x0
    800011c6:	f72080e7          	jalr	-142(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011ca:	00007917          	auipc	s2,0x7
    800011ce:	e3690913          	addi	s2,s2,-458 # 80008000 <etext>
    800011d2:	4729                	li	a4,10
    800011d4:	80007697          	auipc	a3,0x80007
    800011d8:	e2c68693          	addi	a3,a3,-468 # 8000 <_entry-0x7fff8000>
    800011dc:	4605                	li	a2,1
    800011de:	067e                	slli	a2,a2,0x1f
    800011e0:	85b2                	mv	a1,a2
    800011e2:	8526                	mv	a0,s1
    800011e4:	00000097          	auipc	ra,0x0
    800011e8:	f50080e7          	jalr	-176(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011ec:	4719                	li	a4,6
    800011ee:	46c5                	li	a3,17
    800011f0:	06ee                	slli	a3,a3,0x1b
    800011f2:	412686b3          	sub	a3,a3,s2
    800011f6:	864a                	mv	a2,s2
    800011f8:	85ca                	mv	a1,s2
    800011fa:	8526                	mv	a0,s1
    800011fc:	00000097          	auipc	ra,0x0
    80001200:	f38080e7          	jalr	-200(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001204:	4729                	li	a4,10
    80001206:	6685                	lui	a3,0x1
    80001208:	00006617          	auipc	a2,0x6
    8000120c:	df860613          	addi	a2,a2,-520 # 80007000 <_trampoline>
    80001210:	040005b7          	lui	a1,0x4000
    80001214:	15fd                	addi	a1,a1,-1
    80001216:	05b2                	slli	a1,a1,0xc
    80001218:	8526                	mv	a0,s1
    8000121a:	00000097          	auipc	ra,0x0
    8000121e:	f1a080e7          	jalr	-230(ra) # 80001134 <kvmmap>
  proc_mapstacks(kpgtbl);
    80001222:	8526                	mv	a0,s1
    80001224:	00000097          	auipc	ra,0x0
    80001228:	600080e7          	jalr	1536(ra) # 80001824 <proc_mapstacks>
}
    8000122c:	8526                	mv	a0,s1
    8000122e:	60e2                	ld	ra,24(sp)
    80001230:	6442                	ld	s0,16(sp)
    80001232:	64a2                	ld	s1,8(sp)
    80001234:	6902                	ld	s2,0(sp)
    80001236:	6105                	addi	sp,sp,32
    80001238:	8082                	ret

000000008000123a <kvminit>:
{
    8000123a:	1141                	addi	sp,sp,-16
    8000123c:	e406                	sd	ra,8(sp)
    8000123e:	e022                	sd	s0,0(sp)
    80001240:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001242:	00000097          	auipc	ra,0x0
    80001246:	f22080e7          	jalr	-222(ra) # 80001164 <kvmmake>
    8000124a:	00007797          	auipc	a5,0x7
    8000124e:	6ea7bb23          	sd	a0,1782(a5) # 80008940 <kernel_pagetable>
}
    80001252:	60a2                	ld	ra,8(sp)
    80001254:	6402                	ld	s0,0(sp)
    80001256:	0141                	addi	sp,sp,16
    80001258:	8082                	ret

000000008000125a <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    8000125a:	715d                	addi	sp,sp,-80
    8000125c:	e486                	sd	ra,72(sp)
    8000125e:	e0a2                	sd	s0,64(sp)
    80001260:	fc26                	sd	s1,56(sp)
    80001262:	f84a                	sd	s2,48(sp)
    80001264:	f44e                	sd	s3,40(sp)
    80001266:	f052                	sd	s4,32(sp)
    80001268:	ec56                	sd	s5,24(sp)
    8000126a:	e85a                	sd	s6,16(sp)
    8000126c:	e45e                	sd	s7,8(sp)
    8000126e:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001270:	03459793          	slli	a5,a1,0x34
    80001274:	e795                	bnez	a5,800012a0 <uvmunmap+0x46>
    80001276:	8a2a                	mv	s4,a0
    80001278:	892e                	mv	s2,a1
    8000127a:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000127c:	0632                	slli	a2,a2,0xc
    8000127e:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001282:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001284:	6b05                	lui	s6,0x1
    80001286:	0735e263          	bltu	a1,s3,800012ea <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    8000128a:	60a6                	ld	ra,72(sp)
    8000128c:	6406                	ld	s0,64(sp)
    8000128e:	74e2                	ld	s1,56(sp)
    80001290:	7942                	ld	s2,48(sp)
    80001292:	79a2                	ld	s3,40(sp)
    80001294:	7a02                	ld	s4,32(sp)
    80001296:	6ae2                	ld	s5,24(sp)
    80001298:	6b42                	ld	s6,16(sp)
    8000129a:	6ba2                	ld	s7,8(sp)
    8000129c:	6161                	addi	sp,sp,80
    8000129e:	8082                	ret
    panic("uvmunmap: not aligned");
    800012a0:	00007517          	auipc	a0,0x7
    800012a4:	e6050513          	addi	a0,a0,-416 # 80008100 <digits+0xc0>
    800012a8:	fffff097          	auipc	ra,0xfffff
    800012ac:	290080e7          	jalr	656(ra) # 80000538 <panic>
      panic("uvmunmap: walk");
    800012b0:	00007517          	auipc	a0,0x7
    800012b4:	e6850513          	addi	a0,a0,-408 # 80008118 <digits+0xd8>
    800012b8:	fffff097          	auipc	ra,0xfffff
    800012bc:	280080e7          	jalr	640(ra) # 80000538 <panic>
      panic("uvmunmap: not mapped");
    800012c0:	00007517          	auipc	a0,0x7
    800012c4:	e6850513          	addi	a0,a0,-408 # 80008128 <digits+0xe8>
    800012c8:	fffff097          	auipc	ra,0xfffff
    800012cc:	270080e7          	jalr	624(ra) # 80000538 <panic>
      panic("uvmunmap: not a leaf");
    800012d0:	00007517          	auipc	a0,0x7
    800012d4:	e7050513          	addi	a0,a0,-400 # 80008140 <digits+0x100>
    800012d8:	fffff097          	auipc	ra,0xfffff
    800012dc:	260080e7          	jalr	608(ra) # 80000538 <panic>
    *pte = 0;
    800012e0:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012e4:	995a                	add	s2,s2,s6
    800012e6:	fb3972e3          	bgeu	s2,s3,8000128a <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012ea:	4601                	li	a2,0
    800012ec:	85ca                	mv	a1,s2
    800012ee:	8552                	mv	a0,s4
    800012f0:	00000097          	auipc	ra,0x0
    800012f4:	cbc080e7          	jalr	-836(ra) # 80000fac <walk>
    800012f8:	84aa                	mv	s1,a0
    800012fa:	d95d                	beqz	a0,800012b0 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800012fc:	6108                	ld	a0,0(a0)
    800012fe:	00157793          	andi	a5,a0,1
    80001302:	dfdd                	beqz	a5,800012c0 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001304:	3ff57793          	andi	a5,a0,1023
    80001308:	fd7784e3          	beq	a5,s7,800012d0 <uvmunmap+0x76>
    if(do_free){
    8000130c:	fc0a8ae3          	beqz	s5,800012e0 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    80001310:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001312:	0532                	slli	a0,a0,0xc
    80001314:	fffff097          	auipc	ra,0xfffff
    80001318:	6d0080e7          	jalr	1744(ra) # 800009e4 <kfree>
    8000131c:	b7d1                	j	800012e0 <uvmunmap+0x86>

000000008000131e <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000131e:	1101                	addi	sp,sp,-32
    80001320:	ec06                	sd	ra,24(sp)
    80001322:	e822                	sd	s0,16(sp)
    80001324:	e426                	sd	s1,8(sp)
    80001326:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001328:	fffff097          	auipc	ra,0xfffff
    8000132c:	7b8080e7          	jalr	1976(ra) # 80000ae0 <kalloc>
    80001330:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001332:	c519                	beqz	a0,80001340 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001334:	6605                	lui	a2,0x1
    80001336:	4581                	li	a1,0
    80001338:	00000097          	auipc	ra,0x0
    8000133c:	994080e7          	jalr	-1644(ra) # 80000ccc <memset>
  return pagetable;
}
    80001340:	8526                	mv	a0,s1
    80001342:	60e2                	ld	ra,24(sp)
    80001344:	6442                	ld	s0,16(sp)
    80001346:	64a2                	ld	s1,8(sp)
    80001348:	6105                	addi	sp,sp,32
    8000134a:	8082                	ret

000000008000134c <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    8000134c:	7179                	addi	sp,sp,-48
    8000134e:	f406                	sd	ra,40(sp)
    80001350:	f022                	sd	s0,32(sp)
    80001352:	ec26                	sd	s1,24(sp)
    80001354:	e84a                	sd	s2,16(sp)
    80001356:	e44e                	sd	s3,8(sp)
    80001358:	e052                	sd	s4,0(sp)
    8000135a:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    8000135c:	6785                	lui	a5,0x1
    8000135e:	04f67863          	bgeu	a2,a5,800013ae <uvmfirst+0x62>
    80001362:	8a2a                	mv	s4,a0
    80001364:	89ae                	mv	s3,a1
    80001366:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    80001368:	fffff097          	auipc	ra,0xfffff
    8000136c:	778080e7          	jalr	1912(ra) # 80000ae0 <kalloc>
    80001370:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001372:	6605                	lui	a2,0x1
    80001374:	4581                	li	a1,0
    80001376:	00000097          	auipc	ra,0x0
    8000137a:	956080e7          	jalr	-1706(ra) # 80000ccc <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000137e:	4779                	li	a4,30
    80001380:	86ca                	mv	a3,s2
    80001382:	6605                	lui	a2,0x1
    80001384:	4581                	li	a1,0
    80001386:	8552                	mv	a0,s4
    80001388:	00000097          	auipc	ra,0x0
    8000138c:	d0c080e7          	jalr	-756(ra) # 80001094 <mappages>
  memmove(mem, src, sz);
    80001390:	8626                	mv	a2,s1
    80001392:	85ce                	mv	a1,s3
    80001394:	854a                	mv	a0,s2
    80001396:	00000097          	auipc	ra,0x0
    8000139a:	992080e7          	jalr	-1646(ra) # 80000d28 <memmove>
}
    8000139e:	70a2                	ld	ra,40(sp)
    800013a0:	7402                	ld	s0,32(sp)
    800013a2:	64e2                	ld	s1,24(sp)
    800013a4:	6942                	ld	s2,16(sp)
    800013a6:	69a2                	ld	s3,8(sp)
    800013a8:	6a02                	ld	s4,0(sp)
    800013aa:	6145                	addi	sp,sp,48
    800013ac:	8082                	ret
    panic("uvmfirst: more than a page");
    800013ae:	00007517          	auipc	a0,0x7
    800013b2:	daa50513          	addi	a0,a0,-598 # 80008158 <digits+0x118>
    800013b6:	fffff097          	auipc	ra,0xfffff
    800013ba:	182080e7          	jalr	386(ra) # 80000538 <panic>

00000000800013be <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013be:	1101                	addi	sp,sp,-32
    800013c0:	ec06                	sd	ra,24(sp)
    800013c2:	e822                	sd	s0,16(sp)
    800013c4:	e426                	sd	s1,8(sp)
    800013c6:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013c8:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013ca:	00b67d63          	bgeu	a2,a1,800013e4 <uvmdealloc+0x26>
    800013ce:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013d0:	6785                	lui	a5,0x1
    800013d2:	17fd                	addi	a5,a5,-1
    800013d4:	00f60733          	add	a4,a2,a5
    800013d8:	767d                	lui	a2,0xfffff
    800013da:	8f71                	and	a4,a4,a2
    800013dc:	97ae                	add	a5,a5,a1
    800013de:	8ff1                	and	a5,a5,a2
    800013e0:	00f76863          	bltu	a4,a5,800013f0 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013e4:	8526                	mv	a0,s1
    800013e6:	60e2                	ld	ra,24(sp)
    800013e8:	6442                	ld	s0,16(sp)
    800013ea:	64a2                	ld	s1,8(sp)
    800013ec:	6105                	addi	sp,sp,32
    800013ee:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013f0:	8f99                	sub	a5,a5,a4
    800013f2:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013f4:	4685                	li	a3,1
    800013f6:	0007861b          	sext.w	a2,a5
    800013fa:	85ba                	mv	a1,a4
    800013fc:	00000097          	auipc	ra,0x0
    80001400:	e5e080e7          	jalr	-418(ra) # 8000125a <uvmunmap>
    80001404:	b7c5                	j	800013e4 <uvmdealloc+0x26>

0000000080001406 <uvmalloc>:
  if(newsz < oldsz)
    80001406:	0ab66163          	bltu	a2,a1,800014a8 <uvmalloc+0xa2>
{
    8000140a:	7139                	addi	sp,sp,-64
    8000140c:	fc06                	sd	ra,56(sp)
    8000140e:	f822                	sd	s0,48(sp)
    80001410:	f426                	sd	s1,40(sp)
    80001412:	f04a                	sd	s2,32(sp)
    80001414:	ec4e                	sd	s3,24(sp)
    80001416:	e852                	sd	s4,16(sp)
    80001418:	e456                	sd	s5,8(sp)
    8000141a:	0080                	addi	s0,sp,64
    8000141c:	8aaa                	mv	s5,a0
    8000141e:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001420:	6985                	lui	s3,0x1
    80001422:	19fd                	addi	s3,s3,-1
    80001424:	95ce                	add	a1,a1,s3
    80001426:	79fd                	lui	s3,0xfffff
    80001428:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000142c:	08c9f063          	bgeu	s3,a2,800014ac <uvmalloc+0xa6>
    80001430:	894e                	mv	s2,s3
    mem = kalloc();
    80001432:	fffff097          	auipc	ra,0xfffff
    80001436:	6ae080e7          	jalr	1710(ra) # 80000ae0 <kalloc>
    8000143a:	84aa                	mv	s1,a0
    if(mem == 0){
    8000143c:	c51d                	beqz	a0,8000146a <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000143e:	6605                	lui	a2,0x1
    80001440:	4581                	li	a1,0
    80001442:	00000097          	auipc	ra,0x0
    80001446:	88a080e7          	jalr	-1910(ra) # 80000ccc <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    8000144a:	4779                	li	a4,30
    8000144c:	86a6                	mv	a3,s1
    8000144e:	6605                	lui	a2,0x1
    80001450:	85ca                	mv	a1,s2
    80001452:	8556                	mv	a0,s5
    80001454:	00000097          	auipc	ra,0x0
    80001458:	c40080e7          	jalr	-960(ra) # 80001094 <mappages>
    8000145c:	e905                	bnez	a0,8000148c <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000145e:	6785                	lui	a5,0x1
    80001460:	993e                	add	s2,s2,a5
    80001462:	fd4968e3          	bltu	s2,s4,80001432 <uvmalloc+0x2c>
  return newsz;
    80001466:	8552                	mv	a0,s4
    80001468:	a809                	j	8000147a <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    8000146a:	864e                	mv	a2,s3
    8000146c:	85ca                	mv	a1,s2
    8000146e:	8556                	mv	a0,s5
    80001470:	00000097          	auipc	ra,0x0
    80001474:	f4e080e7          	jalr	-178(ra) # 800013be <uvmdealloc>
      return 0;
    80001478:	4501                	li	a0,0
}
    8000147a:	70e2                	ld	ra,56(sp)
    8000147c:	7442                	ld	s0,48(sp)
    8000147e:	74a2                	ld	s1,40(sp)
    80001480:	7902                	ld	s2,32(sp)
    80001482:	69e2                	ld	s3,24(sp)
    80001484:	6a42                	ld	s4,16(sp)
    80001486:	6aa2                	ld	s5,8(sp)
    80001488:	6121                	addi	sp,sp,64
    8000148a:	8082                	ret
      kfree(mem);
    8000148c:	8526                	mv	a0,s1
    8000148e:	fffff097          	auipc	ra,0xfffff
    80001492:	556080e7          	jalr	1366(ra) # 800009e4 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001496:	864e                	mv	a2,s3
    80001498:	85ca                	mv	a1,s2
    8000149a:	8556                	mv	a0,s5
    8000149c:	00000097          	auipc	ra,0x0
    800014a0:	f22080e7          	jalr	-222(ra) # 800013be <uvmdealloc>
      return 0;
    800014a4:	4501                	li	a0,0
    800014a6:	bfd1                	j	8000147a <uvmalloc+0x74>
    return oldsz;
    800014a8:	852e                	mv	a0,a1
}
    800014aa:	8082                	ret
  return newsz;
    800014ac:	8532                	mv	a0,a2
    800014ae:	b7f1                	j	8000147a <uvmalloc+0x74>

00000000800014b0 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014b0:	7179                	addi	sp,sp,-48
    800014b2:	f406                	sd	ra,40(sp)
    800014b4:	f022                	sd	s0,32(sp)
    800014b6:	ec26                	sd	s1,24(sp)
    800014b8:	e84a                	sd	s2,16(sp)
    800014ba:	e44e                	sd	s3,8(sp)
    800014bc:	e052                	sd	s4,0(sp)
    800014be:	1800                	addi	s0,sp,48
    800014c0:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014c2:	84aa                	mv	s1,a0
    800014c4:	6905                	lui	s2,0x1
    800014c6:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014c8:	4985                	li	s3,1
    800014ca:	a821                	j	800014e2 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014cc:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014ce:	0532                	slli	a0,a0,0xc
    800014d0:	00000097          	auipc	ra,0x0
    800014d4:	fe0080e7          	jalr	-32(ra) # 800014b0 <freewalk>
      pagetable[i] = 0;
    800014d8:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014dc:	04a1                	addi	s1,s1,8
    800014de:	03248163          	beq	s1,s2,80001500 <freewalk+0x50>
    pte_t pte = pagetable[i];
    800014e2:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014e4:	00f57793          	andi	a5,a0,15
    800014e8:	ff3782e3          	beq	a5,s3,800014cc <freewalk+0x1c>
    } else if(pte & PTE_V){
    800014ec:	8905                	andi	a0,a0,1
    800014ee:	d57d                	beqz	a0,800014dc <freewalk+0x2c>
      panic("freewalk: leaf");
    800014f0:	00007517          	auipc	a0,0x7
    800014f4:	c8850513          	addi	a0,a0,-888 # 80008178 <digits+0x138>
    800014f8:	fffff097          	auipc	ra,0xfffff
    800014fc:	040080e7          	jalr	64(ra) # 80000538 <panic>
    }
  }
  kfree((void*)pagetable);
    80001500:	8552                	mv	a0,s4
    80001502:	fffff097          	auipc	ra,0xfffff
    80001506:	4e2080e7          	jalr	1250(ra) # 800009e4 <kfree>
}
    8000150a:	70a2                	ld	ra,40(sp)
    8000150c:	7402                	ld	s0,32(sp)
    8000150e:	64e2                	ld	s1,24(sp)
    80001510:	6942                	ld	s2,16(sp)
    80001512:	69a2                	ld	s3,8(sp)
    80001514:	6a02                	ld	s4,0(sp)
    80001516:	6145                	addi	sp,sp,48
    80001518:	8082                	ret

000000008000151a <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000151a:	1101                	addi	sp,sp,-32
    8000151c:	ec06                	sd	ra,24(sp)
    8000151e:	e822                	sd	s0,16(sp)
    80001520:	e426                	sd	s1,8(sp)
    80001522:	1000                	addi	s0,sp,32
    80001524:	84aa                	mv	s1,a0
  if(sz > 0)
    80001526:	e999                	bnez	a1,8000153c <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001528:	8526                	mv	a0,s1
    8000152a:	00000097          	auipc	ra,0x0
    8000152e:	f86080e7          	jalr	-122(ra) # 800014b0 <freewalk>
}
    80001532:	60e2                	ld	ra,24(sp)
    80001534:	6442                	ld	s0,16(sp)
    80001536:	64a2                	ld	s1,8(sp)
    80001538:	6105                	addi	sp,sp,32
    8000153a:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000153c:	6605                	lui	a2,0x1
    8000153e:	167d                	addi	a2,a2,-1
    80001540:	962e                	add	a2,a2,a1
    80001542:	4685                	li	a3,1
    80001544:	8231                	srli	a2,a2,0xc
    80001546:	4581                	li	a1,0
    80001548:	00000097          	auipc	ra,0x0
    8000154c:	d12080e7          	jalr	-750(ra) # 8000125a <uvmunmap>
    80001550:	bfe1                	j	80001528 <uvmfree+0xe>

0000000080001552 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001552:	c679                	beqz	a2,80001620 <uvmcopy+0xce>
{
    80001554:	715d                	addi	sp,sp,-80
    80001556:	e486                	sd	ra,72(sp)
    80001558:	e0a2                	sd	s0,64(sp)
    8000155a:	fc26                	sd	s1,56(sp)
    8000155c:	f84a                	sd	s2,48(sp)
    8000155e:	f44e                	sd	s3,40(sp)
    80001560:	f052                	sd	s4,32(sp)
    80001562:	ec56                	sd	s5,24(sp)
    80001564:	e85a                	sd	s6,16(sp)
    80001566:	e45e                	sd	s7,8(sp)
    80001568:	0880                	addi	s0,sp,80
    8000156a:	8b2a                	mv	s6,a0
    8000156c:	8aae                	mv	s5,a1
    8000156e:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001570:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001572:	4601                	li	a2,0
    80001574:	85ce                	mv	a1,s3
    80001576:	855a                	mv	a0,s6
    80001578:	00000097          	auipc	ra,0x0
    8000157c:	a34080e7          	jalr	-1484(ra) # 80000fac <walk>
    80001580:	c531                	beqz	a0,800015cc <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001582:	6118                	ld	a4,0(a0)
    80001584:	00177793          	andi	a5,a4,1
    80001588:	cbb1                	beqz	a5,800015dc <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    8000158a:	00a75593          	srli	a1,a4,0xa
    8000158e:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001592:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    80001596:	fffff097          	auipc	ra,0xfffff
    8000159a:	54a080e7          	jalr	1354(ra) # 80000ae0 <kalloc>
    8000159e:	892a                	mv	s2,a0
    800015a0:	c939                	beqz	a0,800015f6 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015a2:	6605                	lui	a2,0x1
    800015a4:	85de                	mv	a1,s7
    800015a6:	fffff097          	auipc	ra,0xfffff
    800015aa:	782080e7          	jalr	1922(ra) # 80000d28 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015ae:	8726                	mv	a4,s1
    800015b0:	86ca                	mv	a3,s2
    800015b2:	6605                	lui	a2,0x1
    800015b4:	85ce                	mv	a1,s3
    800015b6:	8556                	mv	a0,s5
    800015b8:	00000097          	auipc	ra,0x0
    800015bc:	adc080e7          	jalr	-1316(ra) # 80001094 <mappages>
    800015c0:	e515                	bnez	a0,800015ec <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015c2:	6785                	lui	a5,0x1
    800015c4:	99be                	add	s3,s3,a5
    800015c6:	fb49e6e3          	bltu	s3,s4,80001572 <uvmcopy+0x20>
    800015ca:	a081                	j	8000160a <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015cc:	00007517          	auipc	a0,0x7
    800015d0:	bbc50513          	addi	a0,a0,-1092 # 80008188 <digits+0x148>
    800015d4:	fffff097          	auipc	ra,0xfffff
    800015d8:	f64080e7          	jalr	-156(ra) # 80000538 <panic>
      panic("uvmcopy: page not present");
    800015dc:	00007517          	auipc	a0,0x7
    800015e0:	bcc50513          	addi	a0,a0,-1076 # 800081a8 <digits+0x168>
    800015e4:	fffff097          	auipc	ra,0xfffff
    800015e8:	f54080e7          	jalr	-172(ra) # 80000538 <panic>
      kfree(mem);
    800015ec:	854a                	mv	a0,s2
    800015ee:	fffff097          	auipc	ra,0xfffff
    800015f2:	3f6080e7          	jalr	1014(ra) # 800009e4 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800015f6:	4685                	li	a3,1
    800015f8:	00c9d613          	srli	a2,s3,0xc
    800015fc:	4581                	li	a1,0
    800015fe:	8556                	mv	a0,s5
    80001600:	00000097          	auipc	ra,0x0
    80001604:	c5a080e7          	jalr	-934(ra) # 8000125a <uvmunmap>
  return -1;
    80001608:	557d                	li	a0,-1
}
    8000160a:	60a6                	ld	ra,72(sp)
    8000160c:	6406                	ld	s0,64(sp)
    8000160e:	74e2                	ld	s1,56(sp)
    80001610:	7942                	ld	s2,48(sp)
    80001612:	79a2                	ld	s3,40(sp)
    80001614:	7a02                	ld	s4,32(sp)
    80001616:	6ae2                	ld	s5,24(sp)
    80001618:	6b42                	ld	s6,16(sp)
    8000161a:	6ba2                	ld	s7,8(sp)
    8000161c:	6161                	addi	sp,sp,80
    8000161e:	8082                	ret
  return 0;
    80001620:	4501                	li	a0,0
}
    80001622:	8082                	ret

0000000080001624 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001624:	1141                	addi	sp,sp,-16
    80001626:	e406                	sd	ra,8(sp)
    80001628:	e022                	sd	s0,0(sp)
    8000162a:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000162c:	4601                	li	a2,0
    8000162e:	00000097          	auipc	ra,0x0
    80001632:	97e080e7          	jalr	-1666(ra) # 80000fac <walk>
  if(pte == 0)
    80001636:	c901                	beqz	a0,80001646 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001638:	611c                	ld	a5,0(a0)
    8000163a:	9bbd                	andi	a5,a5,-17
    8000163c:	e11c                	sd	a5,0(a0)
}
    8000163e:	60a2                	ld	ra,8(sp)
    80001640:	6402                	ld	s0,0(sp)
    80001642:	0141                	addi	sp,sp,16
    80001644:	8082                	ret
    panic("uvmclear");
    80001646:	00007517          	auipc	a0,0x7
    8000164a:	b8250513          	addi	a0,a0,-1150 # 800081c8 <digits+0x188>
    8000164e:	fffff097          	auipc	ra,0xfffff
    80001652:	eea080e7          	jalr	-278(ra) # 80000538 <panic>

0000000080001656 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001656:	c6bd                	beqz	a3,800016c4 <copyout+0x6e>
{
    80001658:	715d                	addi	sp,sp,-80
    8000165a:	e486                	sd	ra,72(sp)
    8000165c:	e0a2                	sd	s0,64(sp)
    8000165e:	fc26                	sd	s1,56(sp)
    80001660:	f84a                	sd	s2,48(sp)
    80001662:	f44e                	sd	s3,40(sp)
    80001664:	f052                	sd	s4,32(sp)
    80001666:	ec56                	sd	s5,24(sp)
    80001668:	e85a                	sd	s6,16(sp)
    8000166a:	e45e                	sd	s7,8(sp)
    8000166c:	e062                	sd	s8,0(sp)
    8000166e:	0880                	addi	s0,sp,80
    80001670:	8b2a                	mv	s6,a0
    80001672:	8c2e                	mv	s8,a1
    80001674:	8a32                	mv	s4,a2
    80001676:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001678:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    8000167a:	6a85                	lui	s5,0x1
    8000167c:	a015                	j	800016a0 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000167e:	9562                	add	a0,a0,s8
    80001680:	0004861b          	sext.w	a2,s1
    80001684:	85d2                	mv	a1,s4
    80001686:	41250533          	sub	a0,a0,s2
    8000168a:	fffff097          	auipc	ra,0xfffff
    8000168e:	69e080e7          	jalr	1694(ra) # 80000d28 <memmove>

    len -= n;
    80001692:	409989b3          	sub	s3,s3,s1
    src += n;
    80001696:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001698:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000169c:	02098263          	beqz	s3,800016c0 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016a0:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016a4:	85ca                	mv	a1,s2
    800016a6:	855a                	mv	a0,s6
    800016a8:	00000097          	auipc	ra,0x0
    800016ac:	9aa080e7          	jalr	-1622(ra) # 80001052 <walkaddr>
    if(pa0 == 0)
    800016b0:	cd01                	beqz	a0,800016c8 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016b2:	418904b3          	sub	s1,s2,s8
    800016b6:	94d6                	add	s1,s1,s5
    if(n > len)
    800016b8:	fc99f3e3          	bgeu	s3,s1,8000167e <copyout+0x28>
    800016bc:	84ce                	mv	s1,s3
    800016be:	b7c1                	j	8000167e <copyout+0x28>
  }
  return 0;
    800016c0:	4501                	li	a0,0
    800016c2:	a021                	j	800016ca <copyout+0x74>
    800016c4:	4501                	li	a0,0
}
    800016c6:	8082                	ret
      return -1;
    800016c8:	557d                	li	a0,-1
}
    800016ca:	60a6                	ld	ra,72(sp)
    800016cc:	6406                	ld	s0,64(sp)
    800016ce:	74e2                	ld	s1,56(sp)
    800016d0:	7942                	ld	s2,48(sp)
    800016d2:	79a2                	ld	s3,40(sp)
    800016d4:	7a02                	ld	s4,32(sp)
    800016d6:	6ae2                	ld	s5,24(sp)
    800016d8:	6b42                	ld	s6,16(sp)
    800016da:	6ba2                	ld	s7,8(sp)
    800016dc:	6c02                	ld	s8,0(sp)
    800016de:	6161                	addi	sp,sp,80
    800016e0:	8082                	ret

00000000800016e2 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016e2:	caa5                	beqz	a3,80001752 <copyin+0x70>
{
    800016e4:	715d                	addi	sp,sp,-80
    800016e6:	e486                	sd	ra,72(sp)
    800016e8:	e0a2                	sd	s0,64(sp)
    800016ea:	fc26                	sd	s1,56(sp)
    800016ec:	f84a                	sd	s2,48(sp)
    800016ee:	f44e                	sd	s3,40(sp)
    800016f0:	f052                	sd	s4,32(sp)
    800016f2:	ec56                	sd	s5,24(sp)
    800016f4:	e85a                	sd	s6,16(sp)
    800016f6:	e45e                	sd	s7,8(sp)
    800016f8:	e062                	sd	s8,0(sp)
    800016fa:	0880                	addi	s0,sp,80
    800016fc:	8b2a                	mv	s6,a0
    800016fe:	8a2e                	mv	s4,a1
    80001700:	8c32                	mv	s8,a2
    80001702:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001704:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001706:	6a85                	lui	s5,0x1
    80001708:	a01d                	j	8000172e <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000170a:	018505b3          	add	a1,a0,s8
    8000170e:	0004861b          	sext.w	a2,s1
    80001712:	412585b3          	sub	a1,a1,s2
    80001716:	8552                	mv	a0,s4
    80001718:	fffff097          	auipc	ra,0xfffff
    8000171c:	610080e7          	jalr	1552(ra) # 80000d28 <memmove>

    len -= n;
    80001720:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001724:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001726:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000172a:	02098263          	beqz	s3,8000174e <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    8000172e:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001732:	85ca                	mv	a1,s2
    80001734:	855a                	mv	a0,s6
    80001736:	00000097          	auipc	ra,0x0
    8000173a:	91c080e7          	jalr	-1764(ra) # 80001052 <walkaddr>
    if(pa0 == 0)
    8000173e:	cd01                	beqz	a0,80001756 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001740:	418904b3          	sub	s1,s2,s8
    80001744:	94d6                	add	s1,s1,s5
    if(n > len)
    80001746:	fc99f2e3          	bgeu	s3,s1,8000170a <copyin+0x28>
    8000174a:	84ce                	mv	s1,s3
    8000174c:	bf7d                	j	8000170a <copyin+0x28>
  }
  return 0;
    8000174e:	4501                	li	a0,0
    80001750:	a021                	j	80001758 <copyin+0x76>
    80001752:	4501                	li	a0,0
}
    80001754:	8082                	ret
      return -1;
    80001756:	557d                	li	a0,-1
}
    80001758:	60a6                	ld	ra,72(sp)
    8000175a:	6406                	ld	s0,64(sp)
    8000175c:	74e2                	ld	s1,56(sp)
    8000175e:	7942                	ld	s2,48(sp)
    80001760:	79a2                	ld	s3,40(sp)
    80001762:	7a02                	ld	s4,32(sp)
    80001764:	6ae2                	ld	s5,24(sp)
    80001766:	6b42                	ld	s6,16(sp)
    80001768:	6ba2                	ld	s7,8(sp)
    8000176a:	6c02                	ld	s8,0(sp)
    8000176c:	6161                	addi	sp,sp,80
    8000176e:	8082                	ret

0000000080001770 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001770:	c6c5                	beqz	a3,80001818 <copyinstr+0xa8>
{
    80001772:	715d                	addi	sp,sp,-80
    80001774:	e486                	sd	ra,72(sp)
    80001776:	e0a2                	sd	s0,64(sp)
    80001778:	fc26                	sd	s1,56(sp)
    8000177a:	f84a                	sd	s2,48(sp)
    8000177c:	f44e                	sd	s3,40(sp)
    8000177e:	f052                	sd	s4,32(sp)
    80001780:	ec56                	sd	s5,24(sp)
    80001782:	e85a                	sd	s6,16(sp)
    80001784:	e45e                	sd	s7,8(sp)
    80001786:	0880                	addi	s0,sp,80
    80001788:	8a2a                	mv	s4,a0
    8000178a:	8b2e                	mv	s6,a1
    8000178c:	8bb2                	mv	s7,a2
    8000178e:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001790:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001792:	6985                	lui	s3,0x1
    80001794:	a035                	j	800017c0 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001796:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    8000179a:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    8000179c:	0017b793          	seqz	a5,a5
    800017a0:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017a4:	60a6                	ld	ra,72(sp)
    800017a6:	6406                	ld	s0,64(sp)
    800017a8:	74e2                	ld	s1,56(sp)
    800017aa:	7942                	ld	s2,48(sp)
    800017ac:	79a2                	ld	s3,40(sp)
    800017ae:	7a02                	ld	s4,32(sp)
    800017b0:	6ae2                	ld	s5,24(sp)
    800017b2:	6b42                	ld	s6,16(sp)
    800017b4:	6ba2                	ld	s7,8(sp)
    800017b6:	6161                	addi	sp,sp,80
    800017b8:	8082                	ret
    srcva = va0 + PGSIZE;
    800017ba:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017be:	c8a9                	beqz	s1,80001810 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017c0:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017c4:	85ca                	mv	a1,s2
    800017c6:	8552                	mv	a0,s4
    800017c8:	00000097          	auipc	ra,0x0
    800017cc:	88a080e7          	jalr	-1910(ra) # 80001052 <walkaddr>
    if(pa0 == 0)
    800017d0:	c131                	beqz	a0,80001814 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017d2:	41790833          	sub	a6,s2,s7
    800017d6:	984e                	add	a6,a6,s3
    if(n > max)
    800017d8:	0104f363          	bgeu	s1,a6,800017de <copyinstr+0x6e>
    800017dc:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017de:	955e                	add	a0,a0,s7
    800017e0:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017e4:	fc080be3          	beqz	a6,800017ba <copyinstr+0x4a>
    800017e8:	985a                	add	a6,a6,s6
    800017ea:	87da                	mv	a5,s6
      if(*p == '\0'){
    800017ec:	41650633          	sub	a2,a0,s6
    800017f0:	14fd                	addi	s1,s1,-1
    800017f2:	9b26                	add	s6,s6,s1
    800017f4:	00f60733          	add	a4,a2,a5
    800017f8:	00074703          	lbu	a4,0(a4)
    800017fc:	df49                	beqz	a4,80001796 <copyinstr+0x26>
        *dst = *p;
    800017fe:	00e78023          	sb	a4,0(a5)
      --max;
    80001802:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001806:	0785                	addi	a5,a5,1
    while(n > 0){
    80001808:	ff0796e3          	bne	a5,a6,800017f4 <copyinstr+0x84>
      dst++;
    8000180c:	8b42                	mv	s6,a6
    8000180e:	b775                	j	800017ba <copyinstr+0x4a>
    80001810:	4781                	li	a5,0
    80001812:	b769                	j	8000179c <copyinstr+0x2c>
      return -1;
    80001814:	557d                	li	a0,-1
    80001816:	b779                	j	800017a4 <copyinstr+0x34>
  int got_null = 0;
    80001818:	4781                	li	a5,0
  if(got_null){
    8000181a:	0017b793          	seqz	a5,a5
    8000181e:	40f00533          	neg	a0,a5
}
    80001822:	8082                	ret

0000000080001824 <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
    80001824:	7139                	addi	sp,sp,-64
    80001826:	fc06                	sd	ra,56(sp)
    80001828:	f822                	sd	s0,48(sp)
    8000182a:	f426                	sd	s1,40(sp)
    8000182c:	f04a                	sd	s2,32(sp)
    8000182e:	ec4e                	sd	s3,24(sp)
    80001830:	e852                	sd	s4,16(sp)
    80001832:	e456                	sd	s5,8(sp)
    80001834:	e05a                	sd	s6,0(sp)
    80001836:	0080                	addi	s0,sp,64
    80001838:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    8000183a:	00010497          	auipc	s1,0x10
    8000183e:	88e48493          	addi	s1,s1,-1906 # 800110c8 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001842:	8b26                	mv	s6,s1
    80001844:	00006a97          	auipc	s5,0x6
    80001848:	7bca8a93          	addi	s5,s5,1980 # 80008000 <etext>
    8000184c:	04000937          	lui	s2,0x4000
    80001850:	197d                	addi	s2,s2,-1
    80001852:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001854:	00017a17          	auipc	s4,0x17
    80001858:	874a0a13          	addi	s4,s4,-1932 # 800180c8 <tickslock>
    char *pa = kalloc();
    8000185c:	fffff097          	auipc	ra,0xfffff
    80001860:	284080e7          	jalr	644(ra) # 80000ae0 <kalloc>
    80001864:	862a                	mv	a2,a0
    if(pa == 0)
    80001866:	c131                	beqz	a0,800018aa <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001868:	416485b3          	sub	a1,s1,s6
    8000186c:	8599                	srai	a1,a1,0x6
    8000186e:	000ab783          	ld	a5,0(s5)
    80001872:	02f585b3          	mul	a1,a1,a5
    80001876:	2585                	addiw	a1,a1,1
    80001878:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    8000187c:	4719                	li	a4,6
    8000187e:	6685                	lui	a3,0x1
    80001880:	40b905b3          	sub	a1,s2,a1
    80001884:	854e                	mv	a0,s3
    80001886:	00000097          	auipc	ra,0x0
    8000188a:	8ae080e7          	jalr	-1874(ra) # 80001134 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000188e:	1c048493          	addi	s1,s1,448
    80001892:	fd4495e3          	bne	s1,s4,8000185c <proc_mapstacks+0x38>
  }
}
    80001896:	70e2                	ld	ra,56(sp)
    80001898:	7442                	ld	s0,48(sp)
    8000189a:	74a2                	ld	s1,40(sp)
    8000189c:	7902                	ld	s2,32(sp)
    8000189e:	69e2                	ld	s3,24(sp)
    800018a0:	6a42                	ld	s4,16(sp)
    800018a2:	6aa2                	ld	s5,8(sp)
    800018a4:	6b02                	ld	s6,0(sp)
    800018a6:	6121                	addi	sp,sp,64
    800018a8:	8082                	ret
      panic("kalloc");
    800018aa:	00007517          	auipc	a0,0x7
    800018ae:	92e50513          	addi	a0,a0,-1746 # 800081d8 <digits+0x198>
    800018b2:	fffff097          	auipc	ra,0xfffff
    800018b6:	c86080e7          	jalr	-890(ra) # 80000538 <panic>

00000000800018ba <procinit>:

// initialize the proc table.
void
procinit(void)
{
    800018ba:	7139                	addi	sp,sp,-64
    800018bc:	fc06                	sd	ra,56(sp)
    800018be:	f822                	sd	s0,48(sp)
    800018c0:	f426                	sd	s1,40(sp)
    800018c2:	f04a                	sd	s2,32(sp)
    800018c4:	ec4e                	sd	s3,24(sp)
    800018c6:	e852                	sd	s4,16(sp)
    800018c8:	e456                	sd	s5,8(sp)
    800018ca:	e05a                	sd	s6,0(sp)
    800018cc:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800018ce:	00007597          	auipc	a1,0x7
    800018d2:	91258593          	addi	a1,a1,-1774 # 800081e0 <digits+0x1a0>
    800018d6:	0000f517          	auipc	a0,0xf
    800018da:	2ea50513          	addi	a0,a0,746 # 80010bc0 <pid_lock>
    800018de:	fffff097          	auipc	ra,0xfffff
    800018e2:	262080e7          	jalr	610(ra) # 80000b40 <initlock>
  initlock(&wait_lock, "wait_lock");
    800018e6:	00007597          	auipc	a1,0x7
    800018ea:	90258593          	addi	a1,a1,-1790 # 800081e8 <digits+0x1a8>
    800018ee:	0000f517          	auipc	a0,0xf
    800018f2:	2ea50513          	addi	a0,a0,746 # 80010bd8 <wait_lock>
    800018f6:	fffff097          	auipc	ra,0xfffff
    800018fa:	24a080e7          	jalr	586(ra) # 80000b40 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018fe:	0000f497          	auipc	s1,0xf
    80001902:	7ca48493          	addi	s1,s1,1994 # 800110c8 <proc>
      initlock(&p->lock, "proc");
    80001906:	00007b17          	auipc	s6,0x7
    8000190a:	8f2b0b13          	addi	s6,s6,-1806 # 800081f8 <digits+0x1b8>
      p->kstack = KSTACK((int) (p - proc));
    8000190e:	8aa6                	mv	s5,s1
    80001910:	00006a17          	auipc	s4,0x6
    80001914:	6f0a0a13          	addi	s4,s4,1776 # 80008000 <etext>
    80001918:	04000937          	lui	s2,0x4000
    8000191c:	197d                	addi	s2,s2,-1
    8000191e:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001920:	00016997          	auipc	s3,0x16
    80001924:	7a898993          	addi	s3,s3,1960 # 800180c8 <tickslock>
      initlock(&p->lock, "proc");
    80001928:	85da                	mv	a1,s6
    8000192a:	8526                	mv	a0,s1
    8000192c:	fffff097          	auipc	ra,0xfffff
    80001930:	214080e7          	jalr	532(ra) # 80000b40 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001934:	415487b3          	sub	a5,s1,s5
    80001938:	8799                	srai	a5,a5,0x6
    8000193a:	000a3703          	ld	a4,0(s4)
    8000193e:	02e787b3          	mul	a5,a5,a4
    80001942:	2785                	addiw	a5,a5,1
    80001944:	00d7979b          	slliw	a5,a5,0xd
    80001948:	40f907b3          	sub	a5,s2,a5
    8000194c:	f0bc                	sd	a5,96(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    8000194e:	1c048493          	addi	s1,s1,448
    80001952:	fd349be3          	bne	s1,s3,80001928 <procinit+0x6e>
  }
}
    80001956:	70e2                	ld	ra,56(sp)
    80001958:	7442                	ld	s0,48(sp)
    8000195a:	74a2                	ld	s1,40(sp)
    8000195c:	7902                	ld	s2,32(sp)
    8000195e:	69e2                	ld	s3,24(sp)
    80001960:	6a42                	ld	s4,16(sp)
    80001962:	6aa2                	ld	s5,8(sp)
    80001964:	6b02                	ld	s6,0(sp)
    80001966:	6121                	addi	sp,sp,64
    80001968:	8082                	ret

000000008000196a <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    8000196a:	1141                	addi	sp,sp,-16
    8000196c:	e422                	sd	s0,8(sp)
    8000196e:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001970:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001972:	2501                	sext.w	a0,a0
    80001974:	6422                	ld	s0,8(sp)
    80001976:	0141                	addi	sp,sp,16
    80001978:	8082                	ret

000000008000197a <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    8000197a:	1141                	addi	sp,sp,-16
    8000197c:	e422                	sd	s0,8(sp)
    8000197e:	0800                	addi	s0,sp,16
    80001980:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001982:	2781                	sext.w	a5,a5
    80001984:	079e                	slli	a5,a5,0x7
  return c;
}
    80001986:	0000f517          	auipc	a0,0xf
    8000198a:	26a50513          	addi	a0,a0,618 # 80010bf0 <cpus>
    8000198e:	953e                	add	a0,a0,a5
    80001990:	6422                	ld	s0,8(sp)
    80001992:	0141                	addi	sp,sp,16
    80001994:	8082                	ret

0000000080001996 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    80001996:	1101                	addi	sp,sp,-32
    80001998:	ec06                	sd	ra,24(sp)
    8000199a:	e822                	sd	s0,16(sp)
    8000199c:	e426                	sd	s1,8(sp)
    8000199e:	1000                	addi	s0,sp,32
  push_off();
    800019a0:	fffff097          	auipc	ra,0xfffff
    800019a4:	1e4080e7          	jalr	484(ra) # 80000b84 <push_off>
    800019a8:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019aa:	2781                	sext.w	a5,a5
    800019ac:	079e                	slli	a5,a5,0x7
    800019ae:	0000f717          	auipc	a4,0xf
    800019b2:	21270713          	addi	a4,a4,530 # 80010bc0 <pid_lock>
    800019b6:	97ba                	add	a5,a5,a4
    800019b8:	7b84                	ld	s1,48(a5)
  pop_off();
    800019ba:	fffff097          	auipc	ra,0xfffff
    800019be:	26a080e7          	jalr	618(ra) # 80000c24 <pop_off>
  return p;
}
    800019c2:	8526                	mv	a0,s1
    800019c4:	60e2                	ld	ra,24(sp)
    800019c6:	6442                	ld	s0,16(sp)
    800019c8:	64a2                	ld	s1,8(sp)
    800019ca:	6105                	addi	sp,sp,32
    800019cc:	8082                	ret

00000000800019ce <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    800019ce:	1141                	addi	sp,sp,-16
    800019d0:	e406                	sd	ra,8(sp)
    800019d2:	e022                	sd	s0,0(sp)
    800019d4:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019d6:	00000097          	auipc	ra,0x0
    800019da:	fc0080e7          	jalr	-64(ra) # 80001996 <myproc>
    800019de:	fffff097          	auipc	ra,0xfffff
    800019e2:	2a6080e7          	jalr	678(ra) # 80000c84 <release>

  if (first) {
    800019e6:	00007797          	auipc	a5,0x7
    800019ea:	eca7a783          	lw	a5,-310(a5) # 800088b0 <first.1>
    800019ee:	eb89                	bnez	a5,80001a00 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    800019f0:	00001097          	auipc	ra,0x1
    800019f4:	ec6080e7          	jalr	-314(ra) # 800028b6 <usertrapret>
}
    800019f8:	60a2                	ld	ra,8(sp)
    800019fa:	6402                	ld	s0,0(sp)
    800019fc:	0141                	addi	sp,sp,16
    800019fe:	8082                	ret
    first = 0;
    80001a00:	00007797          	auipc	a5,0x7
    80001a04:	ea07a823          	sw	zero,-336(a5) # 800088b0 <first.1>
    fsinit(ROOTDEV);
    80001a08:	4505                	li	a0,1
    80001a0a:	00002097          	auipc	ra,0x2
    80001a0e:	002080e7          	jalr	2(ra) # 80003a0c <fsinit>
    80001a12:	bff9                	j	800019f0 <forkret+0x22>

0000000080001a14 <allocpid>:
{
    80001a14:	1101                	addi	sp,sp,-32
    80001a16:	ec06                	sd	ra,24(sp)
    80001a18:	e822                	sd	s0,16(sp)
    80001a1a:	e426                	sd	s1,8(sp)
    80001a1c:	e04a                	sd	s2,0(sp)
    80001a1e:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a20:	0000f917          	auipc	s2,0xf
    80001a24:	1a090913          	addi	s2,s2,416 # 80010bc0 <pid_lock>
    80001a28:	854a                	mv	a0,s2
    80001a2a:	fffff097          	auipc	ra,0xfffff
    80001a2e:	1a6080e7          	jalr	422(ra) # 80000bd0 <acquire>
  pid = nextpid;
    80001a32:	00007797          	auipc	a5,0x7
    80001a36:	e8278793          	addi	a5,a5,-382 # 800088b4 <nextpid>
    80001a3a:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a3c:	0014871b          	addiw	a4,s1,1
    80001a40:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a42:	854a                	mv	a0,s2
    80001a44:	fffff097          	auipc	ra,0xfffff
    80001a48:	240080e7          	jalr	576(ra) # 80000c84 <release>
}
    80001a4c:	8526                	mv	a0,s1
    80001a4e:	60e2                	ld	ra,24(sp)
    80001a50:	6442                	ld	s0,16(sp)
    80001a52:	64a2                	ld	s1,8(sp)
    80001a54:	6902                	ld	s2,0(sp)
    80001a56:	6105                	addi	sp,sp,32
    80001a58:	8082                	ret

0000000080001a5a <proc_pagetable>:
{
    80001a5a:	1101                	addi	sp,sp,-32
    80001a5c:	ec06                	sd	ra,24(sp)
    80001a5e:	e822                	sd	s0,16(sp)
    80001a60:	e426                	sd	s1,8(sp)
    80001a62:	e04a                	sd	s2,0(sp)
    80001a64:	1000                	addi	s0,sp,32
    80001a66:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a68:	00000097          	auipc	ra,0x0
    80001a6c:	8b6080e7          	jalr	-1866(ra) # 8000131e <uvmcreate>
    80001a70:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001a72:	c121                	beqz	a0,80001ab2 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a74:	4729                	li	a4,10
    80001a76:	00005697          	auipc	a3,0x5
    80001a7a:	58a68693          	addi	a3,a3,1418 # 80007000 <_trampoline>
    80001a7e:	6605                	lui	a2,0x1
    80001a80:	040005b7          	lui	a1,0x4000
    80001a84:	15fd                	addi	a1,a1,-1
    80001a86:	05b2                	slli	a1,a1,0xc
    80001a88:	fffff097          	auipc	ra,0xfffff
    80001a8c:	60c080e7          	jalr	1548(ra) # 80001094 <mappages>
    80001a90:	02054863          	bltz	a0,80001ac0 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001a94:	4719                	li	a4,6
    80001a96:	07893683          	ld	a3,120(s2)
    80001a9a:	6605                	lui	a2,0x1
    80001a9c:	020005b7          	lui	a1,0x2000
    80001aa0:	15fd                	addi	a1,a1,-1
    80001aa2:	05b6                	slli	a1,a1,0xd
    80001aa4:	8526                	mv	a0,s1
    80001aa6:	fffff097          	auipc	ra,0xfffff
    80001aaa:	5ee080e7          	jalr	1518(ra) # 80001094 <mappages>
    80001aae:	02054163          	bltz	a0,80001ad0 <proc_pagetable+0x76>
}
    80001ab2:	8526                	mv	a0,s1
    80001ab4:	60e2                	ld	ra,24(sp)
    80001ab6:	6442                	ld	s0,16(sp)
    80001ab8:	64a2                	ld	s1,8(sp)
    80001aba:	6902                	ld	s2,0(sp)
    80001abc:	6105                	addi	sp,sp,32
    80001abe:	8082                	ret
    uvmfree(pagetable, 0);
    80001ac0:	4581                	li	a1,0
    80001ac2:	8526                	mv	a0,s1
    80001ac4:	00000097          	auipc	ra,0x0
    80001ac8:	a56080e7          	jalr	-1450(ra) # 8000151a <uvmfree>
    return 0;
    80001acc:	4481                	li	s1,0
    80001ace:	b7d5                	j	80001ab2 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ad0:	4681                	li	a3,0
    80001ad2:	4605                	li	a2,1
    80001ad4:	040005b7          	lui	a1,0x4000
    80001ad8:	15fd                	addi	a1,a1,-1
    80001ada:	05b2                	slli	a1,a1,0xc
    80001adc:	8526                	mv	a0,s1
    80001ade:	fffff097          	auipc	ra,0xfffff
    80001ae2:	77c080e7          	jalr	1916(ra) # 8000125a <uvmunmap>
    uvmfree(pagetable, 0);
    80001ae6:	4581                	li	a1,0
    80001ae8:	8526                	mv	a0,s1
    80001aea:	00000097          	auipc	ra,0x0
    80001aee:	a30080e7          	jalr	-1488(ra) # 8000151a <uvmfree>
    return 0;
    80001af2:	4481                	li	s1,0
    80001af4:	bf7d                	j	80001ab2 <proc_pagetable+0x58>

0000000080001af6 <proc_freepagetable>:
{
    80001af6:	1101                	addi	sp,sp,-32
    80001af8:	ec06                	sd	ra,24(sp)
    80001afa:	e822                	sd	s0,16(sp)
    80001afc:	e426                	sd	s1,8(sp)
    80001afe:	e04a                	sd	s2,0(sp)
    80001b00:	1000                	addi	s0,sp,32
    80001b02:	84aa                	mv	s1,a0
    80001b04:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b06:	4681                	li	a3,0
    80001b08:	4605                	li	a2,1
    80001b0a:	040005b7          	lui	a1,0x4000
    80001b0e:	15fd                	addi	a1,a1,-1
    80001b10:	05b2                	slli	a1,a1,0xc
    80001b12:	fffff097          	auipc	ra,0xfffff
    80001b16:	748080e7          	jalr	1864(ra) # 8000125a <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b1a:	4681                	li	a3,0
    80001b1c:	4605                	li	a2,1
    80001b1e:	020005b7          	lui	a1,0x2000
    80001b22:	15fd                	addi	a1,a1,-1
    80001b24:	05b6                	slli	a1,a1,0xd
    80001b26:	8526                	mv	a0,s1
    80001b28:	fffff097          	auipc	ra,0xfffff
    80001b2c:	732080e7          	jalr	1842(ra) # 8000125a <uvmunmap>
  uvmfree(pagetable, sz);
    80001b30:	85ca                	mv	a1,s2
    80001b32:	8526                	mv	a0,s1
    80001b34:	00000097          	auipc	ra,0x0
    80001b38:	9e6080e7          	jalr	-1562(ra) # 8000151a <uvmfree>
}
    80001b3c:	60e2                	ld	ra,24(sp)
    80001b3e:	6442                	ld	s0,16(sp)
    80001b40:	64a2                	ld	s1,8(sp)
    80001b42:	6902                	ld	s2,0(sp)
    80001b44:	6105                	addi	sp,sp,32
    80001b46:	8082                	ret

0000000080001b48 <freeproc>:
{
    80001b48:	1101                	addi	sp,sp,-32
    80001b4a:	ec06                	sd	ra,24(sp)
    80001b4c:	e822                	sd	s0,16(sp)
    80001b4e:	e426                	sd	s1,8(sp)
    80001b50:	1000                	addi	s0,sp,32
    80001b52:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b54:	7d28                	ld	a0,120(a0)
    80001b56:	c509                	beqz	a0,80001b60 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b58:	fffff097          	auipc	ra,0xfffff
    80001b5c:	e8c080e7          	jalr	-372(ra) # 800009e4 <kfree>
  p->trapframe = 0;
    80001b60:	0604bc23          	sd	zero,120(s1)
  if(p->pagetable)
    80001b64:	78a8                	ld	a0,112(s1)
    80001b66:	c511                	beqz	a0,80001b72 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b68:	74ac                	ld	a1,104(s1)
    80001b6a:	00000097          	auipc	ra,0x0
    80001b6e:	f8c080e7          	jalr	-116(ra) # 80001af6 <proc_freepagetable>
  p->pagetable = 0;
    80001b72:	0604b823          	sd	zero,112(s1)
  p->sz = 0;
    80001b76:	0604b423          	sd	zero,104(s1)
  p->pid = 0;
    80001b7a:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b7e:	0404bc23          	sd	zero,88(s1)
  p->name[0] = 0;
    80001b82:	1a048823          	sb	zero,432(s1)
  p->chan = 0;
    80001b86:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001b8a:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001b8e:	0204a623          	sw	zero,44(s1)
  p->runCount = 0;
    80001b92:	0204aa23          	sw	zero,52(s1)
  p->systemcallCount = 0;
    80001b96:	0204ac23          	sw	zero,56(s1)
  p->interruptCount = 0;
    80001b9a:	0204ae23          	sw	zero,60(s1)
  p->preemptCount = 0;
    80001b9e:	0404a023          	sw	zero,64(s1)
  p->trapCount = 0;
    80001ba2:	0404a223          	sw	zero,68(s1)
  p->sleepCount = 0;
    80001ba6:	0404a423          	sw	zero,72(s1)
  p->state = UNUSED;
    80001baa:	0004ac23          	sw	zero,24(s1)
  p->added = 0;
    80001bae:	0404a623          	sw	zero,76(s1)
  p->priority = 0;
    80001bb2:	0404a823          	sw	zero,80(s1)
  p->runningTicks = 0;
    80001bb6:	0404aa23          	sw	zero,84(s1)
  for(int i = 0; i < 10; ++i){
    80001bba:	17848793          	addi	a5,s1,376
    80001bbe:	1a048713          	addi	a4,s1,416
    p->report.tickCounts[i] = 0;
    80001bc2:	0007a023          	sw	zero,0(a5)
  for(int i = 0; i < 10; ++i){
    80001bc6:	0791                	addi	a5,a5,4
    80001bc8:	fee79de3          	bne	a5,a4,80001bc2 <freeproc+0x7a>
  p->next = 0;
    80001bcc:	1a04b023          	sd	zero,416(s1)
  p->prev = 0;
    80001bd0:	1a04b423          	sd	zero,424(s1)
}
    80001bd4:	60e2                	ld	ra,24(sp)
    80001bd6:	6442                	ld	s0,16(sp)
    80001bd8:	64a2                	ld	s1,8(sp)
    80001bda:	6105                	addi	sp,sp,32
    80001bdc:	8082                	ret

0000000080001bde <allocproc>:
{
    80001bde:	1101                	addi	sp,sp,-32
    80001be0:	ec06                	sd	ra,24(sp)
    80001be2:	e822                	sd	s0,16(sp)
    80001be4:	e426                	sd	s1,8(sp)
    80001be6:	e04a                	sd	s2,0(sp)
    80001be8:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bea:	0000f497          	auipc	s1,0xf
    80001bee:	4de48493          	addi	s1,s1,1246 # 800110c8 <proc>
    80001bf2:	00016917          	auipc	s2,0x16
    80001bf6:	4d690913          	addi	s2,s2,1238 # 800180c8 <tickslock>
    acquire(&p->lock);
    80001bfa:	8526                	mv	a0,s1
    80001bfc:	fffff097          	auipc	ra,0xfffff
    80001c00:	fd4080e7          	jalr	-44(ra) # 80000bd0 <acquire>
    if(p->state == UNUSED) {
    80001c04:	4c9c                	lw	a5,24(s1)
    80001c06:	cf81                	beqz	a5,80001c1e <allocproc+0x40>
      release(&p->lock);
    80001c08:	8526                	mv	a0,s1
    80001c0a:	fffff097          	auipc	ra,0xfffff
    80001c0e:	07a080e7          	jalr	122(ra) # 80000c84 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c12:	1c048493          	addi	s1,s1,448
    80001c16:	ff2492e3          	bne	s1,s2,80001bfa <allocproc+0x1c>
  return 0;
    80001c1a:	4481                	li	s1,0
    80001c1c:	a889                	j	80001c6e <allocproc+0x90>
  p->pid = allocpid();
    80001c1e:	00000097          	auipc	ra,0x0
    80001c22:	df6080e7          	jalr	-522(ra) # 80001a14 <allocpid>
    80001c26:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c28:	4785                	li	a5,1
    80001c2a:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c2c:	fffff097          	auipc	ra,0xfffff
    80001c30:	eb4080e7          	jalr	-332(ra) # 80000ae0 <kalloc>
    80001c34:	892a                	mv	s2,a0
    80001c36:	fca8                	sd	a0,120(s1)
    80001c38:	c131                	beqz	a0,80001c7c <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001c3a:	8526                	mv	a0,s1
    80001c3c:	00000097          	auipc	ra,0x0
    80001c40:	e1e080e7          	jalr	-482(ra) # 80001a5a <proc_pagetable>
    80001c44:	892a                	mv	s2,a0
    80001c46:	f8a8                	sd	a0,112(s1)
  if(p->pagetable == 0){
    80001c48:	c531                	beqz	a0,80001c94 <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001c4a:	07000613          	li	a2,112
    80001c4e:	4581                	li	a1,0
    80001c50:	08048513          	addi	a0,s1,128
    80001c54:	fffff097          	auipc	ra,0xfffff
    80001c58:	078080e7          	jalr	120(ra) # 80000ccc <memset>
  p->context.ra = (uint64)forkret;
    80001c5c:	00000797          	auipc	a5,0x0
    80001c60:	d7278793          	addi	a5,a5,-654 # 800019ce <forkret>
    80001c64:	e0dc                	sd	a5,128(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c66:	70bc                	ld	a5,96(s1)
    80001c68:	6705                	lui	a4,0x1
    80001c6a:	97ba                	add	a5,a5,a4
    80001c6c:	e4dc                	sd	a5,136(s1)
}
    80001c6e:	8526                	mv	a0,s1
    80001c70:	60e2                	ld	ra,24(sp)
    80001c72:	6442                	ld	s0,16(sp)
    80001c74:	64a2                	ld	s1,8(sp)
    80001c76:	6902                	ld	s2,0(sp)
    80001c78:	6105                	addi	sp,sp,32
    80001c7a:	8082                	ret
    freeproc(p);
    80001c7c:	8526                	mv	a0,s1
    80001c7e:	00000097          	auipc	ra,0x0
    80001c82:	eca080e7          	jalr	-310(ra) # 80001b48 <freeproc>
    release(&p->lock);
    80001c86:	8526                	mv	a0,s1
    80001c88:	fffff097          	auipc	ra,0xfffff
    80001c8c:	ffc080e7          	jalr	-4(ra) # 80000c84 <release>
    return 0;
    80001c90:	84ca                	mv	s1,s2
    80001c92:	bff1                	j	80001c6e <allocproc+0x90>
    freeproc(p);
    80001c94:	8526                	mv	a0,s1
    80001c96:	00000097          	auipc	ra,0x0
    80001c9a:	eb2080e7          	jalr	-334(ra) # 80001b48 <freeproc>
    release(&p->lock);
    80001c9e:	8526                	mv	a0,s1
    80001ca0:	fffff097          	auipc	ra,0xfffff
    80001ca4:	fe4080e7          	jalr	-28(ra) # 80000c84 <release>
    return 0;
    80001ca8:	84ca                	mv	s1,s2
    80001caa:	b7d1                	j	80001c6e <allocproc+0x90>

0000000080001cac <userinit>:
{
    80001cac:	1101                	addi	sp,sp,-32
    80001cae:	ec06                	sd	ra,24(sp)
    80001cb0:	e822                	sd	s0,16(sp)
    80001cb2:	e426                	sd	s1,8(sp)
    80001cb4:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cb6:	00000097          	auipc	ra,0x0
    80001cba:	f28080e7          	jalr	-216(ra) # 80001bde <allocproc>
    80001cbe:	84aa                	mv	s1,a0
  initproc = p;
    80001cc0:	00007797          	auipc	a5,0x7
    80001cc4:	c8a7b423          	sd	a0,-888(a5) # 80008948 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001cc8:	03400613          	li	a2,52
    80001ccc:	00007597          	auipc	a1,0x7
    80001cd0:	bf458593          	addi	a1,a1,-1036 # 800088c0 <initcode>
    80001cd4:	7928                	ld	a0,112(a0)
    80001cd6:	fffff097          	auipc	ra,0xfffff
    80001cda:	676080e7          	jalr	1654(ra) # 8000134c <uvmfirst>
  p->sz = PGSIZE;
    80001cde:	6785                	lui	a5,0x1
    80001ce0:	f4bc                	sd	a5,104(s1)
  p->trapframe->epc = 0;      // user program counter
    80001ce2:	7cb8                	ld	a4,120(s1)
    80001ce4:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001ce8:	7cb8                	ld	a4,120(s1)
    80001cea:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cec:	4641                	li	a2,16
    80001cee:	00006597          	auipc	a1,0x6
    80001cf2:	51258593          	addi	a1,a1,1298 # 80008200 <digits+0x1c0>
    80001cf6:	1b048513          	addi	a0,s1,432
    80001cfa:	fffff097          	auipc	ra,0xfffff
    80001cfe:	11c080e7          	jalr	284(ra) # 80000e16 <safestrcpy>
  p->cwd = namei("/");
    80001d02:	00006517          	auipc	a0,0x6
    80001d06:	50e50513          	addi	a0,a0,1294 # 80008210 <digits+0x1d0>
    80001d0a:	00002097          	auipc	ra,0x2
    80001d0e:	730080e7          	jalr	1840(ra) # 8000443a <namei>
    80001d12:	16a4b823          	sd	a0,368(s1)
  p->state = RUNNABLE;
    80001d16:	478d                	li	a5,3
    80001d18:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d1a:	8526                	mv	a0,s1
    80001d1c:	fffff097          	auipc	ra,0xfffff
    80001d20:	f68080e7          	jalr	-152(ra) # 80000c84 <release>
}
    80001d24:	60e2                	ld	ra,24(sp)
    80001d26:	6442                	ld	s0,16(sp)
    80001d28:	64a2                	ld	s1,8(sp)
    80001d2a:	6105                	addi	sp,sp,32
    80001d2c:	8082                	ret

0000000080001d2e <growproc>:
{
    80001d2e:	1101                	addi	sp,sp,-32
    80001d30:	ec06                	sd	ra,24(sp)
    80001d32:	e822                	sd	s0,16(sp)
    80001d34:	e426                	sd	s1,8(sp)
    80001d36:	e04a                	sd	s2,0(sp)
    80001d38:	1000                	addi	s0,sp,32
    80001d3a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d3c:	00000097          	auipc	ra,0x0
    80001d40:	c5a080e7          	jalr	-934(ra) # 80001996 <myproc>
    80001d44:	892a                	mv	s2,a0
  sz = p->sz;
    80001d46:	752c                	ld	a1,104(a0)
    80001d48:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001d4c:	00904f63          	bgtz	s1,80001d6a <growproc+0x3c>
  } else if(n < 0){
    80001d50:	0204cc63          	bltz	s1,80001d88 <growproc+0x5a>
  p->sz = sz;
    80001d54:	1602                	slli	a2,a2,0x20
    80001d56:	9201                	srli	a2,a2,0x20
    80001d58:	06c93423          	sd	a2,104(s2)
  return 0;
    80001d5c:	4501                	li	a0,0
}
    80001d5e:	60e2                	ld	ra,24(sp)
    80001d60:	6442                	ld	s0,16(sp)
    80001d62:	64a2                	ld	s1,8(sp)
    80001d64:	6902                	ld	s2,0(sp)
    80001d66:	6105                	addi	sp,sp,32
    80001d68:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d6a:	9e25                	addw	a2,a2,s1
    80001d6c:	1602                	slli	a2,a2,0x20
    80001d6e:	9201                	srli	a2,a2,0x20
    80001d70:	1582                	slli	a1,a1,0x20
    80001d72:	9181                	srli	a1,a1,0x20
    80001d74:	7928                	ld	a0,112(a0)
    80001d76:	fffff097          	auipc	ra,0xfffff
    80001d7a:	690080e7          	jalr	1680(ra) # 80001406 <uvmalloc>
    80001d7e:	0005061b          	sext.w	a2,a0
    80001d82:	fa69                	bnez	a2,80001d54 <growproc+0x26>
      return -1;
    80001d84:	557d                	li	a0,-1
    80001d86:	bfe1                	j	80001d5e <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d88:	9e25                	addw	a2,a2,s1
    80001d8a:	1602                	slli	a2,a2,0x20
    80001d8c:	9201                	srli	a2,a2,0x20
    80001d8e:	1582                	slli	a1,a1,0x20
    80001d90:	9181                	srli	a1,a1,0x20
    80001d92:	7928                	ld	a0,112(a0)
    80001d94:	fffff097          	auipc	ra,0xfffff
    80001d98:	62a080e7          	jalr	1578(ra) # 800013be <uvmdealloc>
    80001d9c:	0005061b          	sext.w	a2,a0
    80001da0:	bf55                	j	80001d54 <growproc+0x26>

0000000080001da2 <fork>:
{
    80001da2:	7139                	addi	sp,sp,-64
    80001da4:	fc06                	sd	ra,56(sp)
    80001da6:	f822                	sd	s0,48(sp)
    80001da8:	f426                	sd	s1,40(sp)
    80001daa:	f04a                	sd	s2,32(sp)
    80001dac:	ec4e                	sd	s3,24(sp)
    80001dae:	e852                	sd	s4,16(sp)
    80001db0:	e456                	sd	s5,8(sp)
    80001db2:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001db4:	00000097          	auipc	ra,0x0
    80001db8:	be2080e7          	jalr	-1054(ra) # 80001996 <myproc>
    80001dbc:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001dbe:	00000097          	auipc	ra,0x0
    80001dc2:	e20080e7          	jalr	-480(ra) # 80001bde <allocproc>
    80001dc6:	10050c63          	beqz	a0,80001ede <fork+0x13c>
    80001dca:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001dcc:	068ab603          	ld	a2,104(s5)
    80001dd0:	792c                	ld	a1,112(a0)
    80001dd2:	070ab503          	ld	a0,112(s5)
    80001dd6:	fffff097          	auipc	ra,0xfffff
    80001dda:	77c080e7          	jalr	1916(ra) # 80001552 <uvmcopy>
    80001dde:	04054863          	bltz	a0,80001e2e <fork+0x8c>
  np->sz = p->sz;
    80001de2:	068ab783          	ld	a5,104(s5)
    80001de6:	06fa3423          	sd	a5,104(s4)
  *(np->trapframe) = *(p->trapframe);
    80001dea:	078ab683          	ld	a3,120(s5)
    80001dee:	87b6                	mv	a5,a3
    80001df0:	078a3703          	ld	a4,120(s4)
    80001df4:	12068693          	addi	a3,a3,288
    80001df8:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001dfc:	6788                	ld	a0,8(a5)
    80001dfe:	6b8c                	ld	a1,16(a5)
    80001e00:	6f90                	ld	a2,24(a5)
    80001e02:	01073023          	sd	a6,0(a4)
    80001e06:	e708                	sd	a0,8(a4)
    80001e08:	eb0c                	sd	a1,16(a4)
    80001e0a:	ef10                	sd	a2,24(a4)
    80001e0c:	02078793          	addi	a5,a5,32
    80001e10:	02070713          	addi	a4,a4,32
    80001e14:	fed792e3          	bne	a5,a3,80001df8 <fork+0x56>
  np->trapframe->a0 = 0;
    80001e18:	078a3783          	ld	a5,120(s4)
    80001e1c:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001e20:	0f0a8493          	addi	s1,s5,240
    80001e24:	0f0a0913          	addi	s2,s4,240
    80001e28:	170a8993          	addi	s3,s5,368
    80001e2c:	a00d                	j	80001e4e <fork+0xac>
    freeproc(np);
    80001e2e:	8552                	mv	a0,s4
    80001e30:	00000097          	auipc	ra,0x0
    80001e34:	d18080e7          	jalr	-744(ra) # 80001b48 <freeproc>
    release(&np->lock);
    80001e38:	8552                	mv	a0,s4
    80001e3a:	fffff097          	auipc	ra,0xfffff
    80001e3e:	e4a080e7          	jalr	-438(ra) # 80000c84 <release>
    return -1;
    80001e42:	597d                	li	s2,-1
    80001e44:	a059                	j	80001eca <fork+0x128>
  for(i = 0; i < NOFILE; i++)
    80001e46:	04a1                	addi	s1,s1,8
    80001e48:	0921                	addi	s2,s2,8
    80001e4a:	01348b63          	beq	s1,s3,80001e60 <fork+0xbe>
    if(p->ofile[i])
    80001e4e:	6088                	ld	a0,0(s1)
    80001e50:	d97d                	beqz	a0,80001e46 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e52:	00003097          	auipc	ra,0x3
    80001e56:	c7e080e7          	jalr	-898(ra) # 80004ad0 <filedup>
    80001e5a:	00a93023          	sd	a0,0(s2)
    80001e5e:	b7e5                	j	80001e46 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e60:	170ab503          	ld	a0,368(s5)
    80001e64:	00002097          	auipc	ra,0x2
    80001e68:	de2080e7          	jalr	-542(ra) # 80003c46 <idup>
    80001e6c:	16aa3823          	sd	a0,368(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e70:	4641                	li	a2,16
    80001e72:	1b0a8593          	addi	a1,s5,432
    80001e76:	1b0a0513          	addi	a0,s4,432
    80001e7a:	fffff097          	auipc	ra,0xfffff
    80001e7e:	f9c080e7          	jalr	-100(ra) # 80000e16 <safestrcpy>
  pid = np->pid;
    80001e82:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001e86:	8552                	mv	a0,s4
    80001e88:	fffff097          	auipc	ra,0xfffff
    80001e8c:	dfc080e7          	jalr	-516(ra) # 80000c84 <release>
  acquire(&wait_lock);
    80001e90:	0000f497          	auipc	s1,0xf
    80001e94:	d4848493          	addi	s1,s1,-696 # 80010bd8 <wait_lock>
    80001e98:	8526                	mv	a0,s1
    80001e9a:	fffff097          	auipc	ra,0xfffff
    80001e9e:	d36080e7          	jalr	-714(ra) # 80000bd0 <acquire>
  np->parent = p;
    80001ea2:	055a3c23          	sd	s5,88(s4)
  release(&wait_lock);
    80001ea6:	8526                	mv	a0,s1
    80001ea8:	fffff097          	auipc	ra,0xfffff
    80001eac:	ddc080e7          	jalr	-548(ra) # 80000c84 <release>
  acquire(&np->lock);
    80001eb0:	8552                	mv	a0,s4
    80001eb2:	fffff097          	auipc	ra,0xfffff
    80001eb6:	d1e080e7          	jalr	-738(ra) # 80000bd0 <acquire>
  np->state = RUNNABLE;
    80001eba:	478d                	li	a5,3
    80001ebc:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001ec0:	8552                	mv	a0,s4
    80001ec2:	fffff097          	auipc	ra,0xfffff
    80001ec6:	dc2080e7          	jalr	-574(ra) # 80000c84 <release>
}
    80001eca:	854a                	mv	a0,s2
    80001ecc:	70e2                	ld	ra,56(sp)
    80001ece:	7442                	ld	s0,48(sp)
    80001ed0:	74a2                	ld	s1,40(sp)
    80001ed2:	7902                	ld	s2,32(sp)
    80001ed4:	69e2                	ld	s3,24(sp)
    80001ed6:	6a42                	ld	s4,16(sp)
    80001ed8:	6aa2                	ld	s5,8(sp)
    80001eda:	6121                	addi	sp,sp,64
    80001edc:	8082                	ret
    return -1;
    80001ede:	597d                	li	s2,-1
    80001ee0:	b7ed                	j	80001eca <fork+0x128>

0000000080001ee2 <RR_scheduler>:
RR_scheduler(struct cpu *c){
    80001ee2:	7139                	addi	sp,sp,-64
    80001ee4:	fc06                	sd	ra,56(sp)
    80001ee6:	f822                	sd	s0,48(sp)
    80001ee8:	f426                	sd	s1,40(sp)
    80001eea:	f04a                	sd	s2,32(sp)
    80001eec:	ec4e                	sd	s3,24(sp)
    80001eee:	e852                	sd	s4,16(sp)
    80001ef0:	e456                	sd	s5,8(sp)
    80001ef2:	e05a                	sd	s6,0(sp)
    80001ef4:	0080                	addi	s0,sp,64
    80001ef6:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; ++p){
    80001ef8:	0000f497          	auipc	s1,0xf
    80001efc:	1d048493          	addi	s1,s1,464 # 800110c8 <proc>
    if(p->state == RUNNABLE){
    80001f00:	498d                	li	s3,3
      p->state = RUNNING;
    80001f02:	4b11                	li	s6,4
      swtch(&c->context, &p->context);
    80001f04:	00850a93          	addi	s5,a0,8
  for(p = proc; p < &proc[NPROC]; ++p){
    80001f08:	00016917          	auipc	s2,0x16
    80001f0c:	1c090913          	addi	s2,s2,448 # 800180c8 <tickslock>
    80001f10:	a811                	j	80001f24 <RR_scheduler+0x42>
    release(&p->lock);
    80001f12:	8526                	mv	a0,s1
    80001f14:	fffff097          	auipc	ra,0xfffff
    80001f18:	d70080e7          	jalr	-656(ra) # 80000c84 <release>
  for(p = proc; p < &proc[NPROC]; ++p){
    80001f1c:	1c048493          	addi	s1,s1,448
    80001f20:	03248863          	beq	s1,s2,80001f50 <RR_scheduler+0x6e>
    acquire(&p->lock);
    80001f24:	8526                	mv	a0,s1
    80001f26:	fffff097          	auipc	ra,0xfffff
    80001f2a:	caa080e7          	jalr	-854(ra) # 80000bd0 <acquire>
    if(p->state == RUNNABLE){
    80001f2e:	4c9c                	lw	a5,24(s1)
    80001f30:	ff3791e3          	bne	a5,s3,80001f12 <RR_scheduler+0x30>
      p->state = RUNNING;
    80001f34:	0164ac23          	sw	s6,24(s1)
      c->proc = p;
    80001f38:	009a3023          	sd	s1,0(s4)
      swtch(&c->context, &p->context);
    80001f3c:	08048593          	addi	a1,s1,128
    80001f40:	8556                	mv	a0,s5
    80001f42:	00001097          	auipc	ra,0x1
    80001f46:	8ca080e7          	jalr	-1846(ra) # 8000280c <swtch>
      c->proc = 0;
    80001f4a:	000a3023          	sd	zero,0(s4)
    80001f4e:	b7d1                	j	80001f12 <RR_scheduler+0x30>
}
    80001f50:	70e2                	ld	ra,56(sp)
    80001f52:	7442                	ld	s0,48(sp)
    80001f54:	74a2                	ld	s1,40(sp)
    80001f56:	7902                	ld	s2,32(sp)
    80001f58:	69e2                	ld	s3,24(sp)
    80001f5a:	6a42                	ld	s4,16(sp)
    80001f5c:	6aa2                	ld	s5,8(sp)
    80001f5e:	6b02                	ld	s6,0(sp)
    80001f60:	6121                	addi	sp,sp,64
    80001f62:	8082                	ret

0000000080001f64 <mlfqEnque>:
mlfqEnque(int level, struct proc *proc){
    80001f64:	1141                	addi	sp,sp,-16
    80001f66:	e422                	sd	s0,8(sp)
    80001f68:	0800                	addi	s0,sp,16
  if(mlfq.pqueue[level].head == 0){
    80001f6a:	00150793          	addi	a5,a0,1
    80001f6e:	00479713          	slli	a4,a5,0x4
    80001f72:	0000f797          	auipc	a5,0xf
    80001f76:	c4e78793          	addi	a5,a5,-946 # 80010bc0 <pid_lock>
    80001f7a:	97ba                	add	a5,a5,a4
    80001f7c:	4307b783          	ld	a5,1072(a5)
    80001f80:	c78d                	beqz	a5,80001faa <mlfqEnque+0x46>
    mlfq.pqueue[level].tail->next = proc;
    80001f82:	0505                	addi	a0,a0,1
    80001f84:	0512                	slli	a0,a0,0x4
    80001f86:	0000f797          	auipc	a5,0xf
    80001f8a:	c3a78793          	addi	a5,a5,-966 # 80010bc0 <pid_lock>
    80001f8e:	953e                	add	a0,a0,a5
    80001f90:	43853783          	ld	a5,1080(a0)
    80001f94:	1ab7b023          	sd	a1,416(a5)
    proc->prev = mlfq.pqueue[level].tail;
    80001f98:	1af5b423          	sd	a5,424(a1)
    proc->next = 0;
    80001f9c:	1a05b023          	sd	zero,416(a1)
    mlfq.pqueue[level].tail = proc;
    80001fa0:	42b53c23          	sd	a1,1080(a0)
}
    80001fa4:	6422                	ld	s0,8(sp)
    80001fa6:	0141                	addi	sp,sp,16
    80001fa8:	8082                	ret
    mlfq.pqueue[level].head = proc;
    80001faa:	0000f797          	auipc	a5,0xf
    80001fae:	c1678793          	addi	a5,a5,-1002 # 80010bc0 <pid_lock>
    80001fb2:	00e78533          	add	a0,a5,a4
    80001fb6:	42b53823          	sd	a1,1072(a0)
    mlfq.pqueue[level].tail = proc;
    80001fba:	42b53c23          	sd	a1,1080(a0)
    proc->next = 0;
    80001fbe:	1a05b023          	sd	zero,416(a1)
    proc->prev = 0;
    80001fc2:	1a05b423          	sd	zero,424(a1)
    80001fc6:	bff9                	j	80001fa4 <mlfqEnque+0x40>

0000000080001fc8 <mlfqDeque>:
mlfqDeque(int level){
    80001fc8:	1141                	addi	sp,sp,-16
    80001fca:	e422                	sd	s0,8(sp)
    80001fcc:	0800                	addi	s0,sp,16
    80001fce:	87aa                	mv	a5,a0
  struct proc *end = mlfq.pqueue[level].head;
    80001fd0:	00150713          	addi	a4,a0,1
    80001fd4:	00471693          	slli	a3,a4,0x4
    80001fd8:	0000f717          	auipc	a4,0xf
    80001fdc:	be870713          	addi	a4,a4,-1048 # 80010bc0 <pid_lock>
    80001fe0:	9736                	add	a4,a4,a3
    80001fe2:	43073503          	ld	a0,1072(a4)
  if(end){
    80001fe6:	c10d                	beqz	a0,80002008 <mlfqDeque+0x40>
    mlfq.pqueue[level].head = end->next;
    80001fe8:	1a053603          	ld	a2,416(a0)
    80001fec:	0000f717          	auipc	a4,0xf
    80001ff0:	bd470713          	addi	a4,a4,-1068 # 80010bc0 <pid_lock>
    80001ff4:	9736                	add	a4,a4,a3
    80001ff6:	42c73823          	sd	a2,1072(a4)
  if(end->next){
    80001ffa:	ca11                	beqz	a2,8000200e <mlfqDeque+0x46>
    end->next->prev = 0;
    80001ffc:	1a063423          	sd	zero,424(a2) # 11a8 <_entry-0x7fffee58>
  end->next = 0;
    80002000:	1a053023          	sd	zero,416(a0)
  end->prev = 0;
    80002004:	1a053423          	sd	zero,424(a0)
}
    80002008:	6422                	ld	s0,8(sp)
    8000200a:	0141                	addi	sp,sp,16
    8000200c:	8082                	ret
    mlfq.pqueue[level].tail = 0;
    8000200e:	0785                	addi	a5,a5,1
    80002010:	0792                	slli	a5,a5,0x4
    80002012:	0000f717          	auipc	a4,0xf
    80002016:	bae70713          	addi	a4,a4,-1106 # 80010bc0 <pid_lock>
    8000201a:	97ba                	add	a5,a5,a4
    8000201c:	4207bc23          	sd	zero,1080(a5)
    80002020:	b7c5                	j	80002000 <mlfqDeque+0x38>

0000000080002022 <MLFQ_scheduler>:
  while(mlfq.flag){
    80002022:	0000f797          	auipc	a5,0xf
    80002026:	fce7a783          	lw	a5,-50(a5) # 80010ff0 <mlfq>
    8000202a:	16078363          	beqz	a5,80002190 <MLFQ_scheduler+0x16e>
MLFQ_scheduler(struct cpu *c){
    8000202e:	711d                	addi	sp,sp,-96
    80002030:	ec86                	sd	ra,88(sp)
    80002032:	e8a2                	sd	s0,80(sp)
    80002034:	e4a6                	sd	s1,72(sp)
    80002036:	e0ca                	sd	s2,64(sp)
    80002038:	fc4e                	sd	s3,56(sp)
    8000203a:	f852                	sd	s4,48(sp)
    8000203c:	f456                	sd	s5,40(sp)
    8000203e:	f05a                	sd	s6,32(sp)
    80002040:	ec5e                	sd	s7,24(sp)
    80002042:	e862                	sd	s8,16(sp)
    80002044:	e466                	sd	s9,8(sp)
    80002046:	1080                	addi	s0,sp,96
    80002048:	8b2a                	mv	s6,a0
    8000204a:	4a01                	li	s4,0
    8000204c:	00016997          	auipc	s3,0x16
    80002050:	07c98993          	addi	s3,s3,124 # 800180c8 <tickslock>
      if(proc[i].state == RUNNABLE){
    80002054:	490d                	li	s2,3
        proc[i].added = 1;
    80002056:	4a85                	li	s5,1
      swtch(&c->context, &p->context);
    80002058:	00850c13          	addi	s8,a0,8
  while(mlfq.flag){
    8000205c:	0000fb97          	auipc	s7,0xf
    80002060:	b64b8b93          	addi	s7,s7,-1180 # 80010bc0 <pid_lock>
    80002064:	0000fc97          	auipc	s9,0xf
    80002068:	facc8c93          	addi	s9,s9,-84 # 80011010 <mlfq+0x20>
    8000206c:	a0c1                	j	8000212c <MLFQ_scheduler+0x10a>
      p->runningTicks += 1;
    8000206e:	054a2783          	lw	a5,84(s4)
    80002072:	0017871b          	addiw	a4,a5,1
    80002076:	04ea2a23          	sw	a4,84(s4)
      if(p->runningTicks > (2 * p->priority + 1)){
    8000207a:	050a2503          	lw	a0,80(s4)
    8000207e:	0015169b          	slliw	a3,a0,0x1
    80002082:	0af6d563          	bge	a3,a5,8000212c <MLFQ_scheduler+0x10a>
        p->report.tickCounts[p->priority] += p->runningTicks;
    80002086:	00251793          	slli	a5,a0,0x2
    8000208a:	9a3e                	add	s4,s4,a5
    8000208c:	178a2783          	lw	a5,376(s4)
    80002090:	9f3d                	addw	a4,a4,a5
    80002092:	16ea2c23          	sw	a4,376(s4)
        p = mlfqDeque(p->priority);
    80002096:	00000097          	auipc	ra,0x0
    8000209a:	f32080e7          	jalr	-206(ra) # 80001fc8 <mlfqDeque>
    8000209e:	85aa                	mv	a1,a0
        if(p->priority != mlfq.levels){
    800020a0:	493c                	lw	a5,80(a0)
    800020a2:	434ba703          	lw	a4,1076(s7)
    800020a6:	00f70463          	beq	a4,a5,800020ae <MLFQ_scheduler+0x8c>
          p->priority += 1;
    800020aa:	2785                	addiw	a5,a5,1
    800020ac:	c93c                	sw	a5,80(a0)
        p->runningTicks = 0;
    800020ae:	0405aa23          	sw	zero,84(a1)
        p->state = RUNNABLE;
    800020b2:	0125ac23          	sw	s2,24(a1)
        mlfqEnque(p->priority, p);
    800020b6:	49a8                	lw	a0,80(a1)
    800020b8:	00000097          	auipc	ra,0x0
    800020bc:	eac080e7          	jalr	-340(ra) # 80001f64 <mlfqEnque>
        p = 0;
    800020c0:	4a01                	li	s4,0
    800020c2:	a0ad                	j	8000212c <MLFQ_scheduler+0x10a>
    for(i = 0; i < NPROC && proc[i].added == 0; ++i){
    800020c4:	1c048493          	addi	s1,s1,448
    800020c8:	03348063          	beq	s1,s3,800020e8 <MLFQ_scheduler+0xc6>
    800020cc:	85a6                	mv	a1,s1
    800020ce:	44fc                	lw	a5,76(s1)
    800020d0:	ef81                	bnez	a5,800020e8 <MLFQ_scheduler+0xc6>
      if(proc[i].state == RUNNABLE){
    800020d2:	4c9c                	lw	a5,24(s1)
    800020d4:	ff2798e3          	bne	a5,s2,800020c4 <MLFQ_scheduler+0xa2>
        proc[i].added = 1;
    800020d8:	0555a623          	sw	s5,76(a1)
        mlfqEnque(0, &proc[i]);
    800020dc:	4501                	li	a0,0
    800020de:	00000097          	auipc	ra,0x0
    800020e2:	e86080e7          	jalr	-378(ra) # 80001f64 <mlfqEnque>
    800020e6:	bff9                	j	800020c4 <MLFQ_scheduler+0xa2>
    if(p==0){ //Adds a new p to be ran
    800020e8:	040a0763          	beqz	s4,80002136 <MLFQ_scheduler+0x114>
      acquire(&p->lock);
    800020ec:	8552                	mv	a0,s4
    800020ee:	fffff097          	auipc	ra,0xfffff
    800020f2:	ae2080e7          	jalr	-1310(ra) # 80000bd0 <acquire>
      p->state=RUNNING;
    800020f6:	4791                	li	a5,4
    800020f8:	00fa2c23          	sw	a5,24(s4)
      c->proc = p;
    800020fc:	014b3023          	sd	s4,0(s6)
      swtch(&c->context, &p->context);
    80002100:	080a0593          	addi	a1,s4,128
    80002104:	8562                	mv	a0,s8
    80002106:	00000097          	auipc	ra,0x0
    8000210a:	706080e7          	jalr	1798(ra) # 8000280c <swtch>
      c->proc = 0;
    8000210e:	000b3023          	sd	zero,0(s6)
      release(&p->lock);
    80002112:	8552                	mv	a0,s4
    80002114:	fffff097          	auipc	ra,0xfffff
    80002118:	b70080e7          	jalr	-1168(ra) # 80000c84 <release>
  while(mlfq.flag){
    8000211c:	430ba783          	lw	a5,1072(s7)
    80002120:	cbb9                	beqz	a5,80002176 <MLFQ_scheduler+0x154>
    if(p>0 && (p->state == RUNNABLE || p->state == RUNNING)){
    80002122:	018a2783          	lw	a5,24(s4)
    80002126:	37f5                	addiw	a5,a5,-3
    80002128:	f4faf3e3          	bgeu	s5,a5,8000206e <MLFQ_scheduler+0x4c>
    for(i = 0; i < NPROC && proc[i].added == 0; ++i){
    8000212c:	0000f497          	auipc	s1,0xf
    80002130:	f9c48493          	addi	s1,s1,-100 # 800110c8 <proc>
    80002134:	bf61                	j	800020cc <MLFQ_scheduler+0xaa>
      for(i = 0; i < mlfq.levels; ++i){
    80002136:	434ba783          	lw	a5,1076(s7)
    8000213a:	02f05b63          	blez	a5,80002170 <MLFQ_scheduler+0x14e>
    8000213e:	0000f697          	auipc	a3,0xf
    80002142:	ec268693          	addi	a3,a3,-318 # 80011000 <mlfq+0x10>
    80002146:	fff7861b          	addiw	a2,a5,-1
    8000214a:	1602                	slli	a2,a2,0x20
    8000214c:	9201                	srli	a2,a2,0x20
    8000214e:	0612                	slli	a2,a2,0x4
    80002150:	9666                	add	a2,a2,s9
    80002152:	a031                	j	8000215e <MLFQ_scheduler+0x13c>
    80002154:	8a3e                	mv	s4,a5
    80002156:	bf59                	j	800020ec <MLFQ_scheduler+0xca>
    80002158:	06c1                	addi	a3,a3,16
    8000215a:	00c68b63          	beq	a3,a2,80002170 <MLFQ_scheduler+0x14e>
        for(p = mlfq.pqueue[i].head; p != 0; p = p->next){
    8000215e:	629c                	ld	a5,0(a3)
    80002160:	dfe5                	beqz	a5,80002158 <MLFQ_scheduler+0x136>
          if(p->state == RUNNABLE){
    80002162:	4f98                	lw	a4,24(a5)
    80002164:	ff2708e3          	beq	a4,s2,80002154 <MLFQ_scheduler+0x132>
        for(p = mlfq.pqueue[i].head; p != 0; p = p->next){
    80002168:	1a07b783          	ld	a5,416(a5)
    8000216c:	fbfd                	bnez	a5,80002162 <MLFQ_scheduler+0x140>
    8000216e:	b7ed                	j	80002158 <MLFQ_scheduler+0x136>
  while(mlfq.flag){
    80002170:	430ba783          	lw	a5,1072(s7)
    80002174:	ffc5                	bnez	a5,8000212c <MLFQ_scheduler+0x10a>
}
    80002176:	60e6                	ld	ra,88(sp)
    80002178:	6446                	ld	s0,80(sp)
    8000217a:	64a6                	ld	s1,72(sp)
    8000217c:	6906                	ld	s2,64(sp)
    8000217e:	79e2                	ld	s3,56(sp)
    80002180:	7a42                	ld	s4,48(sp)
    80002182:	7aa2                	ld	s5,40(sp)
    80002184:	7b02                	ld	s6,32(sp)
    80002186:	6be2                	ld	s7,24(sp)
    80002188:	6c42                	ld	s8,16(sp)
    8000218a:	6ca2                	ld	s9,8(sp)
    8000218c:	6125                	addi	sp,sp,96
    8000218e:	8082                	ret
    80002190:	8082                	ret

0000000080002192 <scheduler>:
{
    80002192:	7179                	addi	sp,sp,-48
    80002194:	f406                	sd	ra,40(sp)
    80002196:	f022                	sd	s0,32(sp)
    80002198:	ec26                	sd	s1,24(sp)
    8000219a:	e84a                	sd	s2,16(sp)
    8000219c:	e44e                	sd	s3,8(sp)
    8000219e:	1800                	addi	s0,sp,48
    800021a0:	8792                	mv	a5,tp
  int id = r_tp();
    800021a2:	2781                	sext.w	a5,a5
  struct cpu *c = &cpus[id];
    800021a4:	079e                	slli	a5,a5,0x7
    800021a6:	0000f997          	auipc	s3,0xf
    800021aa:	a4a98993          	addi	s3,s3,-1462 # 80010bf0 <cpus>
    800021ae:	99be                	add	s3,s3,a5
  c->proc = 0;
    800021b0:	0000f717          	auipc	a4,0xf
    800021b4:	a1070713          	addi	a4,a4,-1520 # 80010bc0 <pid_lock>
    800021b8:	97ba                	add	a5,a5,a4
    800021ba:	0207b823          	sd	zero,48(a5)
    if(mlfq.flag == 0){
    800021be:	84ba                	mv	s1,a4
    if(mlfq.flag == 1){
    800021c0:	4905                	li	s2,1
    800021c2:	a029                	j	800021cc <scheduler+0x3a>
    800021c4:	4304a783          	lw	a5,1072(s1)
    800021c8:	03278163          	beq	a5,s2,800021ea <scheduler+0x58>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800021cc:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800021d0:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800021d4:	10079073          	csrw	sstatus,a5
    if(mlfq.flag == 0){
    800021d8:	4304a783          	lw	a5,1072(s1)
    800021dc:	f7e5                	bnez	a5,800021c4 <scheduler+0x32>
        RR_scheduler(c);
    800021de:	854e                	mv	a0,s3
    800021e0:	00000097          	auipc	ra,0x0
    800021e4:	d02080e7          	jalr	-766(ra) # 80001ee2 <RR_scheduler>
    800021e8:	bff1                	j	800021c4 <scheduler+0x32>
      MLFQ_scheduler(c);
    800021ea:	854e                	mv	a0,s3
    800021ec:	00000097          	auipc	ra,0x0
    800021f0:	e36080e7          	jalr	-458(ra) # 80002022 <MLFQ_scheduler>
    800021f4:	bfe1                	j	800021cc <scheduler+0x3a>

00000000800021f6 <sched>:
{
    800021f6:	7179                	addi	sp,sp,-48
    800021f8:	f406                	sd	ra,40(sp)
    800021fa:	f022                	sd	s0,32(sp)
    800021fc:	ec26                	sd	s1,24(sp)
    800021fe:	e84a                	sd	s2,16(sp)
    80002200:	e44e                	sd	s3,8(sp)
    80002202:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002204:	fffff097          	auipc	ra,0xfffff
    80002208:	792080e7          	jalr	1938(ra) # 80001996 <myproc>
    8000220c:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000220e:	fffff097          	auipc	ra,0xfffff
    80002212:	948080e7          	jalr	-1720(ra) # 80000b56 <holding>
    80002216:	c93d                	beqz	a0,8000228c <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002218:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    8000221a:	2781                	sext.w	a5,a5
    8000221c:	079e                	slli	a5,a5,0x7
    8000221e:	0000f717          	auipc	a4,0xf
    80002222:	9a270713          	addi	a4,a4,-1630 # 80010bc0 <pid_lock>
    80002226:	97ba                	add	a5,a5,a4
    80002228:	0a87a703          	lw	a4,168(a5)
    8000222c:	4785                	li	a5,1
    8000222e:	06f71763          	bne	a4,a5,8000229c <sched+0xa6>
  if(p->state == RUNNING)
    80002232:	4c98                	lw	a4,24(s1)
    80002234:	4791                	li	a5,4
    80002236:	06f70b63          	beq	a4,a5,800022ac <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000223a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000223e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002240:	efb5                	bnez	a5,800022bc <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002242:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002244:	0000f917          	auipc	s2,0xf
    80002248:	97c90913          	addi	s2,s2,-1668 # 80010bc0 <pid_lock>
    8000224c:	2781                	sext.w	a5,a5
    8000224e:	079e                	slli	a5,a5,0x7
    80002250:	97ca                	add	a5,a5,s2
    80002252:	0ac7a983          	lw	s3,172(a5)
    80002256:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002258:	2781                	sext.w	a5,a5
    8000225a:	079e                	slli	a5,a5,0x7
    8000225c:	0000f597          	auipc	a1,0xf
    80002260:	99c58593          	addi	a1,a1,-1636 # 80010bf8 <cpus+0x8>
    80002264:	95be                	add	a1,a1,a5
    80002266:	08048513          	addi	a0,s1,128
    8000226a:	00000097          	auipc	ra,0x0
    8000226e:	5a2080e7          	jalr	1442(ra) # 8000280c <swtch>
    80002272:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002274:	2781                	sext.w	a5,a5
    80002276:	079e                	slli	a5,a5,0x7
    80002278:	97ca                	add	a5,a5,s2
    8000227a:	0b37a623          	sw	s3,172(a5)
}
    8000227e:	70a2                	ld	ra,40(sp)
    80002280:	7402                	ld	s0,32(sp)
    80002282:	64e2                	ld	s1,24(sp)
    80002284:	6942                	ld	s2,16(sp)
    80002286:	69a2                	ld	s3,8(sp)
    80002288:	6145                	addi	sp,sp,48
    8000228a:	8082                	ret
    panic("sched p->lock");
    8000228c:	00006517          	auipc	a0,0x6
    80002290:	f8c50513          	addi	a0,a0,-116 # 80008218 <digits+0x1d8>
    80002294:	ffffe097          	auipc	ra,0xffffe
    80002298:	2a4080e7          	jalr	676(ra) # 80000538 <panic>
    panic("sched locks");
    8000229c:	00006517          	auipc	a0,0x6
    800022a0:	f8c50513          	addi	a0,a0,-116 # 80008228 <digits+0x1e8>
    800022a4:	ffffe097          	auipc	ra,0xffffe
    800022a8:	294080e7          	jalr	660(ra) # 80000538 <panic>
    panic("sched running");
    800022ac:	00006517          	auipc	a0,0x6
    800022b0:	f8c50513          	addi	a0,a0,-116 # 80008238 <digits+0x1f8>
    800022b4:	ffffe097          	auipc	ra,0xffffe
    800022b8:	284080e7          	jalr	644(ra) # 80000538 <panic>
    panic("sched interruptible");
    800022bc:	00006517          	auipc	a0,0x6
    800022c0:	f8c50513          	addi	a0,a0,-116 # 80008248 <digits+0x208>
    800022c4:	ffffe097          	auipc	ra,0xffffe
    800022c8:	274080e7          	jalr	628(ra) # 80000538 <panic>

00000000800022cc <yield>:
{
    800022cc:	1101                	addi	sp,sp,-32
    800022ce:	ec06                	sd	ra,24(sp)
    800022d0:	e822                	sd	s0,16(sp)
    800022d2:	e426                	sd	s1,8(sp)
    800022d4:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800022d6:	fffff097          	auipc	ra,0xfffff
    800022da:	6c0080e7          	jalr	1728(ra) # 80001996 <myproc>
    800022de:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800022e0:	fffff097          	auipc	ra,0xfffff
    800022e4:	8f0080e7          	jalr	-1808(ra) # 80000bd0 <acquire>
  p->state = RUNNABLE;
    800022e8:	478d                	li	a5,3
    800022ea:	cc9c                	sw	a5,24(s1)
  sched();
    800022ec:	00000097          	auipc	ra,0x0
    800022f0:	f0a080e7          	jalr	-246(ra) # 800021f6 <sched>
  release(&p->lock);
    800022f4:	8526                	mv	a0,s1
    800022f6:	fffff097          	auipc	ra,0xfffff
    800022fa:	98e080e7          	jalr	-1650(ra) # 80000c84 <release>
}
    800022fe:	60e2                	ld	ra,24(sp)
    80002300:	6442                	ld	s0,16(sp)
    80002302:	64a2                	ld	s1,8(sp)
    80002304:	6105                	addi	sp,sp,32
    80002306:	8082                	ret

0000000080002308 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002308:	7179                	addi	sp,sp,-48
    8000230a:	f406                	sd	ra,40(sp)
    8000230c:	f022                	sd	s0,32(sp)
    8000230e:	ec26                	sd	s1,24(sp)
    80002310:	e84a                	sd	s2,16(sp)
    80002312:	e44e                	sd	s3,8(sp)
    80002314:	1800                	addi	s0,sp,48
    80002316:	89aa                	mv	s3,a0
    80002318:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000231a:	fffff097          	auipc	ra,0xfffff
    8000231e:	67c080e7          	jalr	1660(ra) # 80001996 <myproc>
    80002322:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002324:	fffff097          	auipc	ra,0xfffff
    80002328:	8ac080e7          	jalr	-1876(ra) # 80000bd0 <acquire>
  release(lk);
    8000232c:	854a                	mv	a0,s2
    8000232e:	fffff097          	auipc	ra,0xfffff
    80002332:	956080e7          	jalr	-1706(ra) # 80000c84 <release>

  // Go to sleep.
  p->chan = chan;
    80002336:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    8000233a:	4789                	li	a5,2
    8000233c:	cc9c                	sw	a5,24(s1)
  //increment sleep count as it is now sleeping
  p->sleepCount += 1;
    8000233e:	44bc                	lw	a5,72(s1)
    80002340:	2785                	addiw	a5,a5,1
    80002342:	c4bc                	sw	a5,72(s1)
  sched();
    80002344:	00000097          	auipc	ra,0x0
    80002348:	eb2080e7          	jalr	-334(ra) # 800021f6 <sched>

  // Tidy up.
  p->chan = 0;
    8000234c:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002350:	8526                	mv	a0,s1
    80002352:	fffff097          	auipc	ra,0xfffff
    80002356:	932080e7          	jalr	-1742(ra) # 80000c84 <release>
  acquire(lk);
    8000235a:	854a                	mv	a0,s2
    8000235c:	fffff097          	auipc	ra,0xfffff
    80002360:	874080e7          	jalr	-1932(ra) # 80000bd0 <acquire>
}
    80002364:	70a2                	ld	ra,40(sp)
    80002366:	7402                	ld	s0,32(sp)
    80002368:	64e2                	ld	s1,24(sp)
    8000236a:	6942                	ld	s2,16(sp)
    8000236c:	69a2                	ld	s3,8(sp)
    8000236e:	6145                	addi	sp,sp,48
    80002370:	8082                	ret

0000000080002372 <wait>:
{
    80002372:	715d                	addi	sp,sp,-80
    80002374:	e486                	sd	ra,72(sp)
    80002376:	e0a2                	sd	s0,64(sp)
    80002378:	fc26                	sd	s1,56(sp)
    8000237a:	f84a                	sd	s2,48(sp)
    8000237c:	f44e                	sd	s3,40(sp)
    8000237e:	f052                	sd	s4,32(sp)
    80002380:	ec56                	sd	s5,24(sp)
    80002382:	e85a                	sd	s6,16(sp)
    80002384:	e45e                	sd	s7,8(sp)
    80002386:	e062                	sd	s8,0(sp)
    80002388:	0880                	addi	s0,sp,80
    8000238a:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000238c:	fffff097          	auipc	ra,0xfffff
    80002390:	60a080e7          	jalr	1546(ra) # 80001996 <myproc>
    80002394:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002396:	0000f517          	auipc	a0,0xf
    8000239a:	84250513          	addi	a0,a0,-1982 # 80010bd8 <wait_lock>
    8000239e:	fffff097          	auipc	ra,0xfffff
    800023a2:	832080e7          	jalr	-1998(ra) # 80000bd0 <acquire>
    havekids = 0;
    800023a6:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800023a8:	4a15                	li	s4,5
        havekids = 1;
    800023aa:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    800023ac:	00016997          	auipc	s3,0x16
    800023b0:	d1c98993          	addi	s3,s3,-740 # 800180c8 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800023b4:	0000fc17          	auipc	s8,0xf
    800023b8:	824c0c13          	addi	s8,s8,-2012 # 80010bd8 <wait_lock>
    havekids = 0;
    800023bc:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800023be:	0000f497          	auipc	s1,0xf
    800023c2:	d0a48493          	addi	s1,s1,-758 # 800110c8 <proc>
    800023c6:	a0bd                	j	80002434 <wait+0xc2>
          pid = np->pid;
    800023c8:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800023cc:	000b0e63          	beqz	s6,800023e8 <wait+0x76>
    800023d0:	4691                	li	a3,4
    800023d2:	02c48613          	addi	a2,s1,44
    800023d6:	85da                	mv	a1,s6
    800023d8:	07093503          	ld	a0,112(s2)
    800023dc:	fffff097          	auipc	ra,0xfffff
    800023e0:	27a080e7          	jalr	634(ra) # 80001656 <copyout>
    800023e4:	02054563          	bltz	a0,8000240e <wait+0x9c>
          freeproc(np);
    800023e8:	8526                	mv	a0,s1
    800023ea:	fffff097          	auipc	ra,0xfffff
    800023ee:	75e080e7          	jalr	1886(ra) # 80001b48 <freeproc>
          release(&np->lock);
    800023f2:	8526                	mv	a0,s1
    800023f4:	fffff097          	auipc	ra,0xfffff
    800023f8:	890080e7          	jalr	-1904(ra) # 80000c84 <release>
          release(&wait_lock);
    800023fc:	0000e517          	auipc	a0,0xe
    80002400:	7dc50513          	addi	a0,a0,2012 # 80010bd8 <wait_lock>
    80002404:	fffff097          	auipc	ra,0xfffff
    80002408:	880080e7          	jalr	-1920(ra) # 80000c84 <release>
          return pid;
    8000240c:	a09d                	j	80002472 <wait+0x100>
            release(&np->lock);
    8000240e:	8526                	mv	a0,s1
    80002410:	fffff097          	auipc	ra,0xfffff
    80002414:	874080e7          	jalr	-1932(ra) # 80000c84 <release>
            release(&wait_lock);
    80002418:	0000e517          	auipc	a0,0xe
    8000241c:	7c050513          	addi	a0,a0,1984 # 80010bd8 <wait_lock>
    80002420:	fffff097          	auipc	ra,0xfffff
    80002424:	864080e7          	jalr	-1948(ra) # 80000c84 <release>
            return -1;
    80002428:	59fd                	li	s3,-1
    8000242a:	a0a1                	j	80002472 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    8000242c:	1c048493          	addi	s1,s1,448
    80002430:	03348463          	beq	s1,s3,80002458 <wait+0xe6>
      if(np->parent == p){
    80002434:	6cbc                	ld	a5,88(s1)
    80002436:	ff279be3          	bne	a5,s2,8000242c <wait+0xba>
        acquire(&np->lock);
    8000243a:	8526                	mv	a0,s1
    8000243c:	ffffe097          	auipc	ra,0xffffe
    80002440:	794080e7          	jalr	1940(ra) # 80000bd0 <acquire>
        if(np->state == ZOMBIE){
    80002444:	4c9c                	lw	a5,24(s1)
    80002446:	f94781e3          	beq	a5,s4,800023c8 <wait+0x56>
        release(&np->lock);
    8000244a:	8526                	mv	a0,s1
    8000244c:	fffff097          	auipc	ra,0xfffff
    80002450:	838080e7          	jalr	-1992(ra) # 80000c84 <release>
        havekids = 1;
    80002454:	8756                	mv	a4,s5
    80002456:	bfd9                	j	8000242c <wait+0xba>
    if(!havekids || p->killed){
    80002458:	c701                	beqz	a4,80002460 <wait+0xee>
    8000245a:	02892783          	lw	a5,40(s2)
    8000245e:	c79d                	beqz	a5,8000248c <wait+0x11a>
      release(&wait_lock);
    80002460:	0000e517          	auipc	a0,0xe
    80002464:	77850513          	addi	a0,a0,1912 # 80010bd8 <wait_lock>
    80002468:	fffff097          	auipc	ra,0xfffff
    8000246c:	81c080e7          	jalr	-2020(ra) # 80000c84 <release>
      return -1;
    80002470:	59fd                	li	s3,-1
}
    80002472:	854e                	mv	a0,s3
    80002474:	60a6                	ld	ra,72(sp)
    80002476:	6406                	ld	s0,64(sp)
    80002478:	74e2                	ld	s1,56(sp)
    8000247a:	7942                	ld	s2,48(sp)
    8000247c:	79a2                	ld	s3,40(sp)
    8000247e:	7a02                	ld	s4,32(sp)
    80002480:	6ae2                	ld	s5,24(sp)
    80002482:	6b42                	ld	s6,16(sp)
    80002484:	6ba2                	ld	s7,8(sp)
    80002486:	6c02                	ld	s8,0(sp)
    80002488:	6161                	addi	sp,sp,80
    8000248a:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000248c:	85e2                	mv	a1,s8
    8000248e:	854a                	mv	a0,s2
    80002490:	00000097          	auipc	ra,0x0
    80002494:	e78080e7          	jalr	-392(ra) # 80002308 <sleep>
    havekids = 0;
    80002498:	b715                	j	800023bc <wait+0x4a>

000000008000249a <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    8000249a:	7139                	addi	sp,sp,-64
    8000249c:	fc06                	sd	ra,56(sp)
    8000249e:	f822                	sd	s0,48(sp)
    800024a0:	f426                	sd	s1,40(sp)
    800024a2:	f04a                	sd	s2,32(sp)
    800024a4:	ec4e                	sd	s3,24(sp)
    800024a6:	e852                	sd	s4,16(sp)
    800024a8:	e456                	sd	s5,8(sp)
    800024aa:	0080                	addi	s0,sp,64
    800024ac:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800024ae:	0000f497          	auipc	s1,0xf
    800024b2:	c1a48493          	addi	s1,s1,-998 # 800110c8 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800024b6:	4989                	li	s3,2
        p->state = RUNNABLE;
    800024b8:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800024ba:	00016917          	auipc	s2,0x16
    800024be:	c0e90913          	addi	s2,s2,-1010 # 800180c8 <tickslock>
    800024c2:	a811                	j	800024d6 <wakeup+0x3c>
      }
      release(&p->lock);
    800024c4:	8526                	mv	a0,s1
    800024c6:	ffffe097          	auipc	ra,0xffffe
    800024ca:	7be080e7          	jalr	1982(ra) # 80000c84 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800024ce:	1c048493          	addi	s1,s1,448
    800024d2:	03248663          	beq	s1,s2,800024fe <wakeup+0x64>
    if(p != myproc()){
    800024d6:	fffff097          	auipc	ra,0xfffff
    800024da:	4c0080e7          	jalr	1216(ra) # 80001996 <myproc>
    800024de:	fea488e3          	beq	s1,a0,800024ce <wakeup+0x34>
      acquire(&p->lock);
    800024e2:	8526                	mv	a0,s1
    800024e4:	ffffe097          	auipc	ra,0xffffe
    800024e8:	6ec080e7          	jalr	1772(ra) # 80000bd0 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    800024ec:	4c9c                	lw	a5,24(s1)
    800024ee:	fd379be3          	bne	a5,s3,800024c4 <wakeup+0x2a>
    800024f2:	709c                	ld	a5,32(s1)
    800024f4:	fd4798e3          	bne	a5,s4,800024c4 <wakeup+0x2a>
        p->state = RUNNABLE;
    800024f8:	0154ac23          	sw	s5,24(s1)
    800024fc:	b7e1                	j	800024c4 <wakeup+0x2a>
    }
  }
}
    800024fe:	70e2                	ld	ra,56(sp)
    80002500:	7442                	ld	s0,48(sp)
    80002502:	74a2                	ld	s1,40(sp)
    80002504:	7902                	ld	s2,32(sp)
    80002506:	69e2                	ld	s3,24(sp)
    80002508:	6a42                	ld	s4,16(sp)
    8000250a:	6aa2                	ld	s5,8(sp)
    8000250c:	6121                	addi	sp,sp,64
    8000250e:	8082                	ret

0000000080002510 <reparent>:
{
    80002510:	7179                	addi	sp,sp,-48
    80002512:	f406                	sd	ra,40(sp)
    80002514:	f022                	sd	s0,32(sp)
    80002516:	ec26                	sd	s1,24(sp)
    80002518:	e84a                	sd	s2,16(sp)
    8000251a:	e44e                	sd	s3,8(sp)
    8000251c:	e052                	sd	s4,0(sp)
    8000251e:	1800                	addi	s0,sp,48
    80002520:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002522:	0000f497          	auipc	s1,0xf
    80002526:	ba648493          	addi	s1,s1,-1114 # 800110c8 <proc>
      pp->parent = initproc;
    8000252a:	00006a17          	auipc	s4,0x6
    8000252e:	41ea0a13          	addi	s4,s4,1054 # 80008948 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002532:	00016997          	auipc	s3,0x16
    80002536:	b9698993          	addi	s3,s3,-1130 # 800180c8 <tickslock>
    8000253a:	a029                	j	80002544 <reparent+0x34>
    8000253c:	1c048493          	addi	s1,s1,448
    80002540:	01348d63          	beq	s1,s3,8000255a <reparent+0x4a>
    if(pp->parent == p){
    80002544:	6cbc                	ld	a5,88(s1)
    80002546:	ff279be3          	bne	a5,s2,8000253c <reparent+0x2c>
      pp->parent = initproc;
    8000254a:	000a3503          	ld	a0,0(s4)
    8000254e:	eca8                	sd	a0,88(s1)
      wakeup(initproc);
    80002550:	00000097          	auipc	ra,0x0
    80002554:	f4a080e7          	jalr	-182(ra) # 8000249a <wakeup>
    80002558:	b7d5                	j	8000253c <reparent+0x2c>
}
    8000255a:	70a2                	ld	ra,40(sp)
    8000255c:	7402                	ld	s0,32(sp)
    8000255e:	64e2                	ld	s1,24(sp)
    80002560:	6942                	ld	s2,16(sp)
    80002562:	69a2                	ld	s3,8(sp)
    80002564:	6a02                	ld	s4,0(sp)
    80002566:	6145                	addi	sp,sp,48
    80002568:	8082                	ret

000000008000256a <exit>:
{
    8000256a:	7179                	addi	sp,sp,-48
    8000256c:	f406                	sd	ra,40(sp)
    8000256e:	f022                	sd	s0,32(sp)
    80002570:	ec26                	sd	s1,24(sp)
    80002572:	e84a                	sd	s2,16(sp)
    80002574:	e44e                	sd	s3,8(sp)
    80002576:	e052                	sd	s4,0(sp)
    80002578:	1800                	addi	s0,sp,48
    8000257a:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000257c:	fffff097          	auipc	ra,0xfffff
    80002580:	41a080e7          	jalr	1050(ra) # 80001996 <myproc>
    80002584:	89aa                	mv	s3,a0
  if(p == initproc)
    80002586:	00006797          	auipc	a5,0x6
    8000258a:	3c27b783          	ld	a5,962(a5) # 80008948 <initproc>
    8000258e:	0f050493          	addi	s1,a0,240
    80002592:	17050913          	addi	s2,a0,368
    80002596:	02a79363          	bne	a5,a0,800025bc <exit+0x52>
    panic("init exiting");
    8000259a:	00006517          	auipc	a0,0x6
    8000259e:	cc650513          	addi	a0,a0,-826 # 80008260 <digits+0x220>
    800025a2:	ffffe097          	auipc	ra,0xffffe
    800025a6:	f96080e7          	jalr	-106(ra) # 80000538 <panic>
      fileclose(f);
    800025aa:	00002097          	auipc	ra,0x2
    800025ae:	578080e7          	jalr	1400(ra) # 80004b22 <fileclose>
      p->ofile[fd] = 0;
    800025b2:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800025b6:	04a1                	addi	s1,s1,8
    800025b8:	01248563          	beq	s1,s2,800025c2 <exit+0x58>
    if(p->ofile[fd]){
    800025bc:	6088                	ld	a0,0(s1)
    800025be:	f575                	bnez	a0,800025aa <exit+0x40>
    800025c0:	bfdd                	j	800025b6 <exit+0x4c>
  begin_op();
    800025c2:	00002097          	auipc	ra,0x2
    800025c6:	094080e7          	jalr	148(ra) # 80004656 <begin_op>
  iput(p->cwd);
    800025ca:	1709b503          	ld	a0,368(s3)
    800025ce:	00002097          	auipc	ra,0x2
    800025d2:	870080e7          	jalr	-1936(ra) # 80003e3e <iput>
  end_op();
    800025d6:	00002097          	auipc	ra,0x2
    800025da:	100080e7          	jalr	256(ra) # 800046d6 <end_op>
  p->cwd = 0;
    800025de:	1609b823          	sd	zero,368(s3)
  acquire(&wait_lock);
    800025e2:	0000e497          	auipc	s1,0xe
    800025e6:	5f648493          	addi	s1,s1,1526 # 80010bd8 <wait_lock>
    800025ea:	8526                	mv	a0,s1
    800025ec:	ffffe097          	auipc	ra,0xffffe
    800025f0:	5e4080e7          	jalr	1508(ra) # 80000bd0 <acquire>
  reparent(p);
    800025f4:	854e                	mv	a0,s3
    800025f6:	00000097          	auipc	ra,0x0
    800025fa:	f1a080e7          	jalr	-230(ra) # 80002510 <reparent>
  wakeup(p->parent);
    800025fe:	0589b503          	ld	a0,88(s3)
    80002602:	00000097          	auipc	ra,0x0
    80002606:	e98080e7          	jalr	-360(ra) # 8000249a <wakeup>
  acquire(&p->lock);
    8000260a:	854e                	mv	a0,s3
    8000260c:	ffffe097          	auipc	ra,0xffffe
    80002610:	5c4080e7          	jalr	1476(ra) # 80000bd0 <acquire>
  p->xstate = status;
    80002614:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002618:	4795                	li	a5,5
    8000261a:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    8000261e:	8526                	mv	a0,s1
    80002620:	ffffe097          	auipc	ra,0xffffe
    80002624:	664080e7          	jalr	1636(ra) # 80000c84 <release>
  sched();
    80002628:	00000097          	auipc	ra,0x0
    8000262c:	bce080e7          	jalr	-1074(ra) # 800021f6 <sched>
  panic("zombie exit");
    80002630:	00006517          	auipc	a0,0x6
    80002634:	c4050513          	addi	a0,a0,-960 # 80008270 <digits+0x230>
    80002638:	ffffe097          	auipc	ra,0xffffe
    8000263c:	f00080e7          	jalr	-256(ra) # 80000538 <panic>

0000000080002640 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002640:	7179                	addi	sp,sp,-48
    80002642:	f406                	sd	ra,40(sp)
    80002644:	f022                	sd	s0,32(sp)
    80002646:	ec26                	sd	s1,24(sp)
    80002648:	e84a                	sd	s2,16(sp)
    8000264a:	e44e                	sd	s3,8(sp)
    8000264c:	1800                	addi	s0,sp,48
    8000264e:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002650:	0000f497          	auipc	s1,0xf
    80002654:	a7848493          	addi	s1,s1,-1416 # 800110c8 <proc>
    80002658:	00016997          	auipc	s3,0x16
    8000265c:	a7098993          	addi	s3,s3,-1424 # 800180c8 <tickslock>
    acquire(&p->lock);
    80002660:	8526                	mv	a0,s1
    80002662:	ffffe097          	auipc	ra,0xffffe
    80002666:	56e080e7          	jalr	1390(ra) # 80000bd0 <acquire>
    if(p->pid == pid){
    8000266a:	589c                	lw	a5,48(s1)
    8000266c:	01278d63          	beq	a5,s2,80002686 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002670:	8526                	mv	a0,s1
    80002672:	ffffe097          	auipc	ra,0xffffe
    80002676:	612080e7          	jalr	1554(ra) # 80000c84 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000267a:	1c048493          	addi	s1,s1,448
    8000267e:	ff3491e3          	bne	s1,s3,80002660 <kill+0x20>
  }
  return -1;
    80002682:	557d                	li	a0,-1
    80002684:	a829                	j	8000269e <kill+0x5e>
      p->killed = 1;
    80002686:	4785                	li	a5,1
    80002688:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    8000268a:	4c98                	lw	a4,24(s1)
    8000268c:	4789                	li	a5,2
    8000268e:	00f70f63          	beq	a4,a5,800026ac <kill+0x6c>
      release(&p->lock);
    80002692:	8526                	mv	a0,s1
    80002694:	ffffe097          	auipc	ra,0xffffe
    80002698:	5f0080e7          	jalr	1520(ra) # 80000c84 <release>
      return 0;
    8000269c:	4501                	li	a0,0
}
    8000269e:	70a2                	ld	ra,40(sp)
    800026a0:	7402                	ld	s0,32(sp)
    800026a2:	64e2                	ld	s1,24(sp)
    800026a4:	6942                	ld	s2,16(sp)
    800026a6:	69a2                	ld	s3,8(sp)
    800026a8:	6145                	addi	sp,sp,48
    800026aa:	8082                	ret
        p->state = RUNNABLE;
    800026ac:	478d                	li	a5,3
    800026ae:	cc9c                	sw	a5,24(s1)
    800026b0:	b7cd                	j	80002692 <kill+0x52>

00000000800026b2 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800026b2:	7179                	addi	sp,sp,-48
    800026b4:	f406                	sd	ra,40(sp)
    800026b6:	f022                	sd	s0,32(sp)
    800026b8:	ec26                	sd	s1,24(sp)
    800026ba:	e84a                	sd	s2,16(sp)
    800026bc:	e44e                	sd	s3,8(sp)
    800026be:	e052                	sd	s4,0(sp)
    800026c0:	1800                	addi	s0,sp,48
    800026c2:	84aa                	mv	s1,a0
    800026c4:	892e                	mv	s2,a1
    800026c6:	89b2                	mv	s3,a2
    800026c8:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800026ca:	fffff097          	auipc	ra,0xfffff
    800026ce:	2cc080e7          	jalr	716(ra) # 80001996 <myproc>
  if(user_dst){
    800026d2:	c08d                	beqz	s1,800026f4 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800026d4:	86d2                	mv	a3,s4
    800026d6:	864e                	mv	a2,s3
    800026d8:	85ca                	mv	a1,s2
    800026da:	7928                	ld	a0,112(a0)
    800026dc:	fffff097          	auipc	ra,0xfffff
    800026e0:	f7a080e7          	jalr	-134(ra) # 80001656 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800026e4:	70a2                	ld	ra,40(sp)
    800026e6:	7402                	ld	s0,32(sp)
    800026e8:	64e2                	ld	s1,24(sp)
    800026ea:	6942                	ld	s2,16(sp)
    800026ec:	69a2                	ld	s3,8(sp)
    800026ee:	6a02                	ld	s4,0(sp)
    800026f0:	6145                	addi	sp,sp,48
    800026f2:	8082                	ret
    memmove((char *)dst, src, len);
    800026f4:	000a061b          	sext.w	a2,s4
    800026f8:	85ce                	mv	a1,s3
    800026fa:	854a                	mv	a0,s2
    800026fc:	ffffe097          	auipc	ra,0xffffe
    80002700:	62c080e7          	jalr	1580(ra) # 80000d28 <memmove>
    return 0;
    80002704:	8526                	mv	a0,s1
    80002706:	bff9                	j	800026e4 <either_copyout+0x32>

0000000080002708 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002708:	7179                	addi	sp,sp,-48
    8000270a:	f406                	sd	ra,40(sp)
    8000270c:	f022                	sd	s0,32(sp)
    8000270e:	ec26                	sd	s1,24(sp)
    80002710:	e84a                	sd	s2,16(sp)
    80002712:	e44e                	sd	s3,8(sp)
    80002714:	e052                	sd	s4,0(sp)
    80002716:	1800                	addi	s0,sp,48
    80002718:	892a                	mv	s2,a0
    8000271a:	84ae                	mv	s1,a1
    8000271c:	89b2                	mv	s3,a2
    8000271e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002720:	fffff097          	auipc	ra,0xfffff
    80002724:	276080e7          	jalr	630(ra) # 80001996 <myproc>
  if(user_src){
    80002728:	c08d                	beqz	s1,8000274a <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    8000272a:	86d2                	mv	a3,s4
    8000272c:	864e                	mv	a2,s3
    8000272e:	85ca                	mv	a1,s2
    80002730:	7928                	ld	a0,112(a0)
    80002732:	fffff097          	auipc	ra,0xfffff
    80002736:	fb0080e7          	jalr	-80(ra) # 800016e2 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    8000273a:	70a2                	ld	ra,40(sp)
    8000273c:	7402                	ld	s0,32(sp)
    8000273e:	64e2                	ld	s1,24(sp)
    80002740:	6942                	ld	s2,16(sp)
    80002742:	69a2                	ld	s3,8(sp)
    80002744:	6a02                	ld	s4,0(sp)
    80002746:	6145                	addi	sp,sp,48
    80002748:	8082                	ret
    memmove(dst, (char*)src, len);
    8000274a:	000a061b          	sext.w	a2,s4
    8000274e:	85ce                	mv	a1,s3
    80002750:	854a                	mv	a0,s2
    80002752:	ffffe097          	auipc	ra,0xffffe
    80002756:	5d6080e7          	jalr	1494(ra) # 80000d28 <memmove>
    return 0;
    8000275a:	8526                	mv	a0,s1
    8000275c:	bff9                	j	8000273a <either_copyin+0x32>

000000008000275e <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    8000275e:	715d                	addi	sp,sp,-80
    80002760:	e486                	sd	ra,72(sp)
    80002762:	e0a2                	sd	s0,64(sp)
    80002764:	fc26                	sd	s1,56(sp)
    80002766:	f84a                	sd	s2,48(sp)
    80002768:	f44e                	sd	s3,40(sp)
    8000276a:	f052                	sd	s4,32(sp)
    8000276c:	ec56                	sd	s5,24(sp)
    8000276e:	e85a                	sd	s6,16(sp)
    80002770:	e45e                	sd	s7,8(sp)
    80002772:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002774:	00006517          	auipc	a0,0x6
    80002778:	95450513          	addi	a0,a0,-1708 # 800080c8 <digits+0x88>
    8000277c:	ffffe097          	auipc	ra,0xffffe
    80002780:	e06080e7          	jalr	-506(ra) # 80000582 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002784:	0000f497          	auipc	s1,0xf
    80002788:	af448493          	addi	s1,s1,-1292 # 80011278 <proc+0x1b0>
    8000278c:	00016917          	auipc	s2,0x16
    80002790:	aec90913          	addi	s2,s2,-1300 # 80018278 <bcache+0x198>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002794:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002796:	00006997          	auipc	s3,0x6
    8000279a:	aea98993          	addi	s3,s3,-1302 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    8000279e:	00006a97          	auipc	s5,0x6
    800027a2:	aeaa8a93          	addi	s5,s5,-1302 # 80008288 <digits+0x248>
    printf("\n");
    800027a6:	00006a17          	auipc	s4,0x6
    800027aa:	922a0a13          	addi	s4,s4,-1758 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800027ae:	00006b97          	auipc	s7,0x6
    800027b2:	b12b8b93          	addi	s7,s7,-1262 # 800082c0 <states.0>
    800027b6:	a00d                	j	800027d8 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800027b8:	e806a583          	lw	a1,-384(a3)
    800027bc:	8556                	mv	a0,s5
    800027be:	ffffe097          	auipc	ra,0xffffe
    800027c2:	dc4080e7          	jalr	-572(ra) # 80000582 <printf>
    printf("\n");
    800027c6:	8552                	mv	a0,s4
    800027c8:	ffffe097          	auipc	ra,0xffffe
    800027cc:	dba080e7          	jalr	-582(ra) # 80000582 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800027d0:	1c048493          	addi	s1,s1,448
    800027d4:	03248163          	beq	s1,s2,800027f6 <procdump+0x98>
    if(p->state == UNUSED)
    800027d8:	86a6                	mv	a3,s1
    800027da:	e684a783          	lw	a5,-408(s1)
    800027de:	dbed                	beqz	a5,800027d0 <procdump+0x72>
      state = "???";
    800027e0:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800027e2:	fcfb6be3          	bltu	s6,a5,800027b8 <procdump+0x5a>
    800027e6:	1782                	slli	a5,a5,0x20
    800027e8:	9381                	srli	a5,a5,0x20
    800027ea:	078e                	slli	a5,a5,0x3
    800027ec:	97de                	add	a5,a5,s7
    800027ee:	6390                	ld	a2,0(a5)
    800027f0:	f661                	bnez	a2,800027b8 <procdump+0x5a>
      state = "???";
    800027f2:	864e                	mv	a2,s3
    800027f4:	b7d1                	j	800027b8 <procdump+0x5a>
  }
}
    800027f6:	60a6                	ld	ra,72(sp)
    800027f8:	6406                	ld	s0,64(sp)
    800027fa:	74e2                	ld	s1,56(sp)
    800027fc:	7942                	ld	s2,48(sp)
    800027fe:	79a2                	ld	s3,40(sp)
    80002800:	7a02                	ld	s4,32(sp)
    80002802:	6ae2                	ld	s5,24(sp)
    80002804:	6b42                	ld	s6,16(sp)
    80002806:	6ba2                	ld	s7,8(sp)
    80002808:	6161                	addi	sp,sp,80
    8000280a:	8082                	ret

000000008000280c <swtch>:
    8000280c:	00153023          	sd	ra,0(a0)
    80002810:	00253423          	sd	sp,8(a0)
    80002814:	e900                	sd	s0,16(a0)
    80002816:	ed04                	sd	s1,24(a0)
    80002818:	03253023          	sd	s2,32(a0)
    8000281c:	03353423          	sd	s3,40(a0)
    80002820:	03453823          	sd	s4,48(a0)
    80002824:	03553c23          	sd	s5,56(a0)
    80002828:	05653023          	sd	s6,64(a0)
    8000282c:	05753423          	sd	s7,72(a0)
    80002830:	05853823          	sd	s8,80(a0)
    80002834:	05953c23          	sd	s9,88(a0)
    80002838:	07a53023          	sd	s10,96(a0)
    8000283c:	07b53423          	sd	s11,104(a0)
    80002840:	0005b083          	ld	ra,0(a1)
    80002844:	0085b103          	ld	sp,8(a1)
    80002848:	6980                	ld	s0,16(a1)
    8000284a:	6d84                	ld	s1,24(a1)
    8000284c:	0205b903          	ld	s2,32(a1)
    80002850:	0285b983          	ld	s3,40(a1)
    80002854:	0305ba03          	ld	s4,48(a1)
    80002858:	0385ba83          	ld	s5,56(a1)
    8000285c:	0405bb03          	ld	s6,64(a1)
    80002860:	0485bb83          	ld	s7,72(a1)
    80002864:	0505bc03          	ld	s8,80(a1)
    80002868:	0585bc83          	ld	s9,88(a1)
    8000286c:	0605bd03          	ld	s10,96(a1)
    80002870:	0685bd83          	ld	s11,104(a1)
    80002874:	8082                	ret

0000000080002876 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002876:	1141                	addi	sp,sp,-16
    80002878:	e406                	sd	ra,8(sp)
    8000287a:	e022                	sd	s0,0(sp)
    8000287c:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000287e:	00006597          	auipc	a1,0x6
    80002882:	a7258593          	addi	a1,a1,-1422 # 800082f0 <states.0+0x30>
    80002886:	00016517          	auipc	a0,0x16
    8000288a:	84250513          	addi	a0,a0,-1982 # 800180c8 <tickslock>
    8000288e:	ffffe097          	auipc	ra,0xffffe
    80002892:	2b2080e7          	jalr	690(ra) # 80000b40 <initlock>
}
    80002896:	60a2                	ld	ra,8(sp)
    80002898:	6402                	ld	s0,0(sp)
    8000289a:	0141                	addi	sp,sp,16
    8000289c:	8082                	ret

000000008000289e <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000289e:	1141                	addi	sp,sp,-16
    800028a0:	e422                	sd	s0,8(sp)
    800028a2:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028a4:	00004797          	auipc	a5,0x4
    800028a8:	8ac78793          	addi	a5,a5,-1876 # 80006150 <kernelvec>
    800028ac:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800028b0:	6422                	ld	s0,8(sp)
    800028b2:	0141                	addi	sp,sp,16
    800028b4:	8082                	ret

00000000800028b6 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800028b6:	1141                	addi	sp,sp,-16
    800028b8:	e406                	sd	ra,8(sp)
    800028ba:	e022                	sd	s0,0(sp)
    800028bc:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800028be:	fffff097          	auipc	ra,0xfffff
    800028c2:	0d8080e7          	jalr	216(ra) # 80001996 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028c6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800028ca:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028cc:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    800028d0:	00004617          	auipc	a2,0x4
    800028d4:	73060613          	addi	a2,a2,1840 # 80007000 <_trampoline>
    800028d8:	00004697          	auipc	a3,0x4
    800028dc:	72868693          	addi	a3,a3,1832 # 80007000 <_trampoline>
    800028e0:	8e91                	sub	a3,a3,a2
    800028e2:	040007b7          	lui	a5,0x4000
    800028e6:	17fd                	addi	a5,a5,-1
    800028e8:	07b2                	slli	a5,a5,0xc
    800028ea:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028ec:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800028f0:	7d38                	ld	a4,120(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800028f2:	180026f3          	csrr	a3,satp
    800028f6:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800028f8:	7d38                	ld	a4,120(a0)
    800028fa:	7134                	ld	a3,96(a0)
    800028fc:	6585                	lui	a1,0x1
    800028fe:	96ae                	add	a3,a3,a1
    80002900:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002902:	7d38                	ld	a4,120(a0)
    80002904:	00000697          	auipc	a3,0x0
    80002908:	13068693          	addi	a3,a3,304 # 80002a34 <usertrap>
    8000290c:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    8000290e:	7d38                	ld	a4,120(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002910:	8692                	mv	a3,tp
    80002912:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002914:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002918:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000291c:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002920:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002924:	7d38                	ld	a4,120(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002926:	6f18                	ld	a4,24(a4)
    80002928:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    8000292c:	7928                	ld	a0,112(a0)
    8000292e:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002930:	00004717          	auipc	a4,0x4
    80002934:	76870713          	addi	a4,a4,1896 # 80007098 <userret>
    80002938:	8f11                	sub	a4,a4,a2
    8000293a:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    8000293c:	577d                	li	a4,-1
    8000293e:	177e                	slli	a4,a4,0x3f
    80002940:	8d59                	or	a0,a0,a4
    80002942:	9782                	jalr	a5
}
    80002944:	60a2                	ld	ra,8(sp)
    80002946:	6402                	ld	s0,0(sp)
    80002948:	0141                	addi	sp,sp,16
    8000294a:	8082                	ret

000000008000294c <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    8000294c:	1101                	addi	sp,sp,-32
    8000294e:	ec06                	sd	ra,24(sp)
    80002950:	e822                	sd	s0,16(sp)
    80002952:	e426                	sd	s1,8(sp)
    80002954:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002956:	00015497          	auipc	s1,0x15
    8000295a:	77248493          	addi	s1,s1,1906 # 800180c8 <tickslock>
    8000295e:	8526                	mv	a0,s1
    80002960:	ffffe097          	auipc	ra,0xffffe
    80002964:	270080e7          	jalr	624(ra) # 80000bd0 <acquire>
  ticks++;
    80002968:	00006517          	auipc	a0,0x6
    8000296c:	fe850513          	addi	a0,a0,-24 # 80008950 <ticks>
    80002970:	411c                	lw	a5,0(a0)
    80002972:	2785                	addiw	a5,a5,1
    80002974:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002976:	00000097          	auipc	ra,0x0
    8000297a:	b24080e7          	jalr	-1244(ra) # 8000249a <wakeup>
  release(&tickslock);
    8000297e:	8526                	mv	a0,s1
    80002980:	ffffe097          	auipc	ra,0xffffe
    80002984:	304080e7          	jalr	772(ra) # 80000c84 <release>
}
    80002988:	60e2                	ld	ra,24(sp)
    8000298a:	6442                	ld	s0,16(sp)
    8000298c:	64a2                	ld	s1,8(sp)
    8000298e:	6105                	addi	sp,sp,32
    80002990:	8082                	ret

0000000080002992 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002992:	1101                	addi	sp,sp,-32
    80002994:	ec06                	sd	ra,24(sp)
    80002996:	e822                	sd	s0,16(sp)
    80002998:	e426                	sd	s1,8(sp)
    8000299a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000299c:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800029a0:	00074d63          	bltz	a4,800029ba <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800029a4:	57fd                	li	a5,-1
    800029a6:	17fe                	slli	a5,a5,0x3f
    800029a8:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800029aa:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800029ac:	06f70363          	beq	a4,a5,80002a12 <devintr+0x80>
  }
}
    800029b0:	60e2                	ld	ra,24(sp)
    800029b2:	6442                	ld	s0,16(sp)
    800029b4:	64a2                	ld	s1,8(sp)
    800029b6:	6105                	addi	sp,sp,32
    800029b8:	8082                	ret
     (scause & 0xff) == 9){
    800029ba:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    800029be:	46a5                	li	a3,9
    800029c0:	fed792e3          	bne	a5,a3,800029a4 <devintr+0x12>
    int irq = plic_claim();
    800029c4:	00004097          	auipc	ra,0x4
    800029c8:	894080e7          	jalr	-1900(ra) # 80006258 <plic_claim>
    800029cc:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800029ce:	47a9                	li	a5,10
    800029d0:	02f50763          	beq	a0,a5,800029fe <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800029d4:	4785                	li	a5,1
    800029d6:	02f50963          	beq	a0,a5,80002a08 <devintr+0x76>
    return 1;
    800029da:	4505                	li	a0,1
    } else if(irq){
    800029dc:	d8f1                	beqz	s1,800029b0 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800029de:	85a6                	mv	a1,s1
    800029e0:	00006517          	auipc	a0,0x6
    800029e4:	91850513          	addi	a0,a0,-1768 # 800082f8 <states.0+0x38>
    800029e8:	ffffe097          	auipc	ra,0xffffe
    800029ec:	b9a080e7          	jalr	-1126(ra) # 80000582 <printf>
      plic_complete(irq);
    800029f0:	8526                	mv	a0,s1
    800029f2:	00004097          	auipc	ra,0x4
    800029f6:	88a080e7          	jalr	-1910(ra) # 8000627c <plic_complete>
    return 1;
    800029fa:	4505                	li	a0,1
    800029fc:	bf55                	j	800029b0 <devintr+0x1e>
      uartintr();
    800029fe:	ffffe097          	auipc	ra,0xffffe
    80002a02:	f96080e7          	jalr	-106(ra) # 80000994 <uartintr>
    80002a06:	b7ed                	j	800029f0 <devintr+0x5e>
      virtio_disk_intr();
    80002a08:	00004097          	auipc	ra,0x4
    80002a0c:	d40080e7          	jalr	-704(ra) # 80006748 <virtio_disk_intr>
    80002a10:	b7c5                	j	800029f0 <devintr+0x5e>
    if(cpuid() == 0){
    80002a12:	fffff097          	auipc	ra,0xfffff
    80002a16:	f58080e7          	jalr	-168(ra) # 8000196a <cpuid>
    80002a1a:	c901                	beqz	a0,80002a2a <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002a1c:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002a20:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002a22:	14479073          	csrw	sip,a5
    return 2;
    80002a26:	4509                	li	a0,2
    80002a28:	b761                	j	800029b0 <devintr+0x1e>
      clockintr();
    80002a2a:	00000097          	auipc	ra,0x0
    80002a2e:	f22080e7          	jalr	-222(ra) # 8000294c <clockintr>
    80002a32:	b7ed                	j	80002a1c <devintr+0x8a>

0000000080002a34 <usertrap>:
{
    80002a34:	1101                	addi	sp,sp,-32
    80002a36:	ec06                	sd	ra,24(sp)
    80002a38:	e822                	sd	s0,16(sp)
    80002a3a:	e426                	sd	s1,8(sp)
    80002a3c:	e04a                	sd	s2,0(sp)
    80002a3e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a40:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002a44:	1007f793          	andi	a5,a5,256
    80002a48:	e7bd                	bnez	a5,80002ab6 <usertrap+0x82>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a4a:	00003797          	auipc	a5,0x3
    80002a4e:	70678793          	addi	a5,a5,1798 # 80006150 <kernelvec>
    80002a52:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002a56:	fffff097          	auipc	ra,0xfffff
    80002a5a:	f40080e7          	jalr	-192(ra) # 80001996 <myproc>
    80002a5e:	84aa                	mv	s1,a0
  p->trapCount += 1;
    80002a60:	417c                	lw	a5,68(a0)
    80002a62:	2785                	addiw	a5,a5,1
    80002a64:	c17c                	sw	a5,68(a0)
  p->trapframe->epc = r_sepc();
    80002a66:	7d3c                	ld	a5,120(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a68:	14102773          	csrr	a4,sepc
    80002a6c:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a6e:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002a72:	47a1                	li	a5,8
    80002a74:	04f71f63          	bne	a4,a5,80002ad2 <usertrap+0x9e>
    p->systemcallCount += 1;
    80002a78:	5d1c                	lw	a5,56(a0)
    80002a7a:	2785                	addiw	a5,a5,1
    80002a7c:	dd1c                	sw	a5,56(a0)
    if(p->killed)
    80002a7e:	551c                	lw	a5,40(a0)
    80002a80:	e3b9                	bnez	a5,80002ac6 <usertrap+0x92>
    p->trapframe->epc += 4;
    80002a82:	7cb8                	ld	a4,120(s1)
    80002a84:	6f1c                	ld	a5,24(a4)
    80002a86:	0791                	addi	a5,a5,4
    80002a88:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a8a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002a8e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a92:	10079073          	csrw	sstatus,a5
    syscall();
    80002a96:	00000097          	auipc	ra,0x0
    80002a9a:	2fa080e7          	jalr	762(ra) # 80002d90 <syscall>
  if(p->killed)
    80002a9e:	549c                	lw	a5,40(s1)
    80002aa0:	efd1                	bnez	a5,80002b3c <usertrap+0x108>
  usertrapret();
    80002aa2:	00000097          	auipc	ra,0x0
    80002aa6:	e14080e7          	jalr	-492(ra) # 800028b6 <usertrapret>
}
    80002aaa:	60e2                	ld	ra,24(sp)
    80002aac:	6442                	ld	s0,16(sp)
    80002aae:	64a2                	ld	s1,8(sp)
    80002ab0:	6902                	ld	s2,0(sp)
    80002ab2:	6105                	addi	sp,sp,32
    80002ab4:	8082                	ret
    panic("usertrap: not from user mode");
    80002ab6:	00006517          	auipc	a0,0x6
    80002aba:	86250513          	addi	a0,a0,-1950 # 80008318 <states.0+0x58>
    80002abe:	ffffe097          	auipc	ra,0xffffe
    80002ac2:	a7a080e7          	jalr	-1414(ra) # 80000538 <panic>
      exit(-1);
    80002ac6:	557d                	li	a0,-1
    80002ac8:	00000097          	auipc	ra,0x0
    80002acc:	aa2080e7          	jalr	-1374(ra) # 8000256a <exit>
    80002ad0:	bf4d                	j	80002a82 <usertrap+0x4e>
  } else if((which_dev = devintr()) != 0){
    80002ad2:	00000097          	auipc	ra,0x0
    80002ad6:	ec0080e7          	jalr	-320(ra) # 80002992 <devintr>
    80002ada:	892a                	mv	s2,a0
    80002adc:	c501                	beqz	a0,80002ae4 <usertrap+0xb0>
  if(p->killed)
    80002ade:	549c                	lw	a5,40(s1)
    80002ae0:	c3a1                	beqz	a5,80002b20 <usertrap+0xec>
    80002ae2:	a815                	j	80002b16 <usertrap+0xe2>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ae4:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002ae8:	5890                	lw	a2,48(s1)
    80002aea:	00006517          	auipc	a0,0x6
    80002aee:	84e50513          	addi	a0,a0,-1970 # 80008338 <states.0+0x78>
    80002af2:	ffffe097          	auipc	ra,0xffffe
    80002af6:	a90080e7          	jalr	-1392(ra) # 80000582 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002afa:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002afe:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b02:	00006517          	auipc	a0,0x6
    80002b06:	86650513          	addi	a0,a0,-1946 # 80008368 <states.0+0xa8>
    80002b0a:	ffffe097          	auipc	ra,0xffffe
    80002b0e:	a78080e7          	jalr	-1416(ra) # 80000582 <printf>
    p->killed = 1;
    80002b12:	4785                	li	a5,1
    80002b14:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002b16:	557d                	li	a0,-1
    80002b18:	00000097          	auipc	ra,0x0
    80002b1c:	a52080e7          	jalr	-1454(ra) # 8000256a <exit>
  if(which_dev == 2){
    80002b20:	4789                	li	a5,2
    80002b22:	f8f910e3          	bne	s2,a5,80002aa2 <usertrap+0x6e>
    p->interruptCount += 1;
    80002b26:	5cdc                	lw	a5,60(s1)
    80002b28:	2785                	addiw	a5,a5,1
    80002b2a:	dcdc                	sw	a5,60(s1)
    p->preemptCount += 1;
    80002b2c:	40bc                	lw	a5,64(s1)
    80002b2e:	2785                	addiw	a5,a5,1
    80002b30:	c0bc                	sw	a5,64(s1)
    yield();
    80002b32:	fffff097          	auipc	ra,0xfffff
    80002b36:	79a080e7          	jalr	1946(ra) # 800022cc <yield>
    80002b3a:	b7a5                	j	80002aa2 <usertrap+0x6e>
  int which_dev = 0;
    80002b3c:	4901                	li	s2,0
    80002b3e:	bfe1                	j	80002b16 <usertrap+0xe2>

0000000080002b40 <kerneltrap>:
{
    80002b40:	7179                	addi	sp,sp,-48
    80002b42:	f406                	sd	ra,40(sp)
    80002b44:	f022                	sd	s0,32(sp)
    80002b46:	ec26                	sd	s1,24(sp)
    80002b48:	e84a                	sd	s2,16(sp)
    80002b4a:	e44e                	sd	s3,8(sp)
    80002b4c:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b4e:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b52:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b56:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002b5a:	1004f793          	andi	a5,s1,256
    80002b5e:	cb85                	beqz	a5,80002b8e <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b60:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002b64:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002b66:	ef85                	bnez	a5,80002b9e <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002b68:	00000097          	auipc	ra,0x0
    80002b6c:	e2a080e7          	jalr	-470(ra) # 80002992 <devintr>
    80002b70:	cd1d                	beqz	a0,80002bae <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING){
    80002b72:	4789                	li	a5,2
    80002b74:	06f50a63          	beq	a0,a5,80002be8 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002b78:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b7c:	10049073          	csrw	sstatus,s1
}
    80002b80:	70a2                	ld	ra,40(sp)
    80002b82:	7402                	ld	s0,32(sp)
    80002b84:	64e2                	ld	s1,24(sp)
    80002b86:	6942                	ld	s2,16(sp)
    80002b88:	69a2                	ld	s3,8(sp)
    80002b8a:	6145                	addi	sp,sp,48
    80002b8c:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002b8e:	00005517          	auipc	a0,0x5
    80002b92:	7fa50513          	addi	a0,a0,2042 # 80008388 <states.0+0xc8>
    80002b96:	ffffe097          	auipc	ra,0xffffe
    80002b9a:	9a2080e7          	jalr	-1630(ra) # 80000538 <panic>
    panic("kerneltrap: interrupts enabled");
    80002b9e:	00006517          	auipc	a0,0x6
    80002ba2:	81250513          	addi	a0,a0,-2030 # 800083b0 <states.0+0xf0>
    80002ba6:	ffffe097          	auipc	ra,0xffffe
    80002baa:	992080e7          	jalr	-1646(ra) # 80000538 <panic>
    printf("scause %p\n", scause);
    80002bae:	85ce                	mv	a1,s3
    80002bb0:	00006517          	auipc	a0,0x6
    80002bb4:	82050513          	addi	a0,a0,-2016 # 800083d0 <states.0+0x110>
    80002bb8:	ffffe097          	auipc	ra,0xffffe
    80002bbc:	9ca080e7          	jalr	-1590(ra) # 80000582 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bc0:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002bc4:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002bc8:	00006517          	auipc	a0,0x6
    80002bcc:	81850513          	addi	a0,a0,-2024 # 800083e0 <states.0+0x120>
    80002bd0:	ffffe097          	auipc	ra,0xffffe
    80002bd4:	9b2080e7          	jalr	-1614(ra) # 80000582 <printf>
    panic("kerneltrap");
    80002bd8:	00006517          	auipc	a0,0x6
    80002bdc:	82050513          	addi	a0,a0,-2016 # 800083f8 <states.0+0x138>
    80002be0:	ffffe097          	auipc	ra,0xffffe
    80002be4:	958080e7          	jalr	-1704(ra) # 80000538 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING){
    80002be8:	fffff097          	auipc	ra,0xfffff
    80002bec:	dae080e7          	jalr	-594(ra) # 80001996 <myproc>
    80002bf0:	d541                	beqz	a0,80002b78 <kerneltrap+0x38>
    80002bf2:	fffff097          	auipc	ra,0xfffff
    80002bf6:	da4080e7          	jalr	-604(ra) # 80001996 <myproc>
    80002bfa:	4d18                	lw	a4,24(a0)
    80002bfc:	4791                	li	a5,4
    80002bfe:	f6f71de3          	bne	a4,a5,80002b78 <kerneltrap+0x38>
    myproc()->preemptCount += 1;
    80002c02:	fffff097          	auipc	ra,0xfffff
    80002c06:	d94080e7          	jalr	-620(ra) # 80001996 <myproc>
    80002c0a:	413c                	lw	a5,64(a0)
    80002c0c:	2785                	addiw	a5,a5,1
    80002c0e:	c13c                	sw	a5,64(a0)
    yield();
    80002c10:	fffff097          	auipc	ra,0xfffff
    80002c14:	6bc080e7          	jalr	1724(ra) # 800022cc <yield>
    80002c18:	b785                	j	80002b78 <kerneltrap+0x38>

0000000080002c1a <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002c1a:	1101                	addi	sp,sp,-32
    80002c1c:	ec06                	sd	ra,24(sp)
    80002c1e:	e822                	sd	s0,16(sp)
    80002c20:	e426                	sd	s1,8(sp)
    80002c22:	1000                	addi	s0,sp,32
    80002c24:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002c26:	fffff097          	auipc	ra,0xfffff
    80002c2a:	d70080e7          	jalr	-656(ra) # 80001996 <myproc>
  switch (n) {
    80002c2e:	4795                	li	a5,5
    80002c30:	0497e163          	bltu	a5,s1,80002c72 <argraw+0x58>
    80002c34:	048a                	slli	s1,s1,0x2
    80002c36:	00005717          	auipc	a4,0x5
    80002c3a:	7fa70713          	addi	a4,a4,2042 # 80008430 <states.0+0x170>
    80002c3e:	94ba                	add	s1,s1,a4
    80002c40:	409c                	lw	a5,0(s1)
    80002c42:	97ba                	add	a5,a5,a4
    80002c44:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002c46:	7d3c                	ld	a5,120(a0)
    80002c48:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002c4a:	60e2                	ld	ra,24(sp)
    80002c4c:	6442                	ld	s0,16(sp)
    80002c4e:	64a2                	ld	s1,8(sp)
    80002c50:	6105                	addi	sp,sp,32
    80002c52:	8082                	ret
    return p->trapframe->a1;
    80002c54:	7d3c                	ld	a5,120(a0)
    80002c56:	7fa8                	ld	a0,120(a5)
    80002c58:	bfcd                	j	80002c4a <argraw+0x30>
    return p->trapframe->a2;
    80002c5a:	7d3c                	ld	a5,120(a0)
    80002c5c:	63c8                	ld	a0,128(a5)
    80002c5e:	b7f5                	j	80002c4a <argraw+0x30>
    return p->trapframe->a3;
    80002c60:	7d3c                	ld	a5,120(a0)
    80002c62:	67c8                	ld	a0,136(a5)
    80002c64:	b7dd                	j	80002c4a <argraw+0x30>
    return p->trapframe->a4;
    80002c66:	7d3c                	ld	a5,120(a0)
    80002c68:	6bc8                	ld	a0,144(a5)
    80002c6a:	b7c5                	j	80002c4a <argraw+0x30>
    return p->trapframe->a5;
    80002c6c:	7d3c                	ld	a5,120(a0)
    80002c6e:	6fc8                	ld	a0,152(a5)
    80002c70:	bfe9                	j	80002c4a <argraw+0x30>
  panic("argraw");
    80002c72:	00005517          	auipc	a0,0x5
    80002c76:	79650513          	addi	a0,a0,1942 # 80008408 <states.0+0x148>
    80002c7a:	ffffe097          	auipc	ra,0xffffe
    80002c7e:	8be080e7          	jalr	-1858(ra) # 80000538 <panic>

0000000080002c82 <fetchaddr>:
{
    80002c82:	1101                	addi	sp,sp,-32
    80002c84:	ec06                	sd	ra,24(sp)
    80002c86:	e822                	sd	s0,16(sp)
    80002c88:	e426                	sd	s1,8(sp)
    80002c8a:	e04a                	sd	s2,0(sp)
    80002c8c:	1000                	addi	s0,sp,32
    80002c8e:	84aa                	mv	s1,a0
    80002c90:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002c92:	fffff097          	auipc	ra,0xfffff
    80002c96:	d04080e7          	jalr	-764(ra) # 80001996 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002c9a:	753c                	ld	a5,104(a0)
    80002c9c:	02f4f863          	bgeu	s1,a5,80002ccc <fetchaddr+0x4a>
    80002ca0:	00848713          	addi	a4,s1,8
    80002ca4:	02e7e663          	bltu	a5,a4,80002cd0 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002ca8:	46a1                	li	a3,8
    80002caa:	8626                	mv	a2,s1
    80002cac:	85ca                	mv	a1,s2
    80002cae:	7928                	ld	a0,112(a0)
    80002cb0:	fffff097          	auipc	ra,0xfffff
    80002cb4:	a32080e7          	jalr	-1486(ra) # 800016e2 <copyin>
    80002cb8:	00a03533          	snez	a0,a0
    80002cbc:	40a00533          	neg	a0,a0
}
    80002cc0:	60e2                	ld	ra,24(sp)
    80002cc2:	6442                	ld	s0,16(sp)
    80002cc4:	64a2                	ld	s1,8(sp)
    80002cc6:	6902                	ld	s2,0(sp)
    80002cc8:	6105                	addi	sp,sp,32
    80002cca:	8082                	ret
    return -1;
    80002ccc:	557d                	li	a0,-1
    80002cce:	bfcd                	j	80002cc0 <fetchaddr+0x3e>
    80002cd0:	557d                	li	a0,-1
    80002cd2:	b7fd                	j	80002cc0 <fetchaddr+0x3e>

0000000080002cd4 <fetchstr>:
{
    80002cd4:	7179                	addi	sp,sp,-48
    80002cd6:	f406                	sd	ra,40(sp)
    80002cd8:	f022                	sd	s0,32(sp)
    80002cda:	ec26                	sd	s1,24(sp)
    80002cdc:	e84a                	sd	s2,16(sp)
    80002cde:	e44e                	sd	s3,8(sp)
    80002ce0:	1800                	addi	s0,sp,48
    80002ce2:	892a                	mv	s2,a0
    80002ce4:	84ae                	mv	s1,a1
    80002ce6:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002ce8:	fffff097          	auipc	ra,0xfffff
    80002cec:	cae080e7          	jalr	-850(ra) # 80001996 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002cf0:	86ce                	mv	a3,s3
    80002cf2:	864a                	mv	a2,s2
    80002cf4:	85a6                	mv	a1,s1
    80002cf6:	7928                	ld	a0,112(a0)
    80002cf8:	fffff097          	auipc	ra,0xfffff
    80002cfc:	a78080e7          	jalr	-1416(ra) # 80001770 <copyinstr>
  if(err < 0)
    80002d00:	00054763          	bltz	a0,80002d0e <fetchstr+0x3a>
  return strlen(buf);
    80002d04:	8526                	mv	a0,s1
    80002d06:	ffffe097          	auipc	ra,0xffffe
    80002d0a:	142080e7          	jalr	322(ra) # 80000e48 <strlen>
}
    80002d0e:	70a2                	ld	ra,40(sp)
    80002d10:	7402                	ld	s0,32(sp)
    80002d12:	64e2                	ld	s1,24(sp)
    80002d14:	6942                	ld	s2,16(sp)
    80002d16:	69a2                	ld	s3,8(sp)
    80002d18:	6145                	addi	sp,sp,48
    80002d1a:	8082                	ret

0000000080002d1c <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002d1c:	1101                	addi	sp,sp,-32
    80002d1e:	ec06                	sd	ra,24(sp)
    80002d20:	e822                	sd	s0,16(sp)
    80002d22:	e426                	sd	s1,8(sp)
    80002d24:	1000                	addi	s0,sp,32
    80002d26:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002d28:	00000097          	auipc	ra,0x0
    80002d2c:	ef2080e7          	jalr	-270(ra) # 80002c1a <argraw>
    80002d30:	c088                	sw	a0,0(s1)
  return 0;
}
    80002d32:	4501                	li	a0,0
    80002d34:	60e2                	ld	ra,24(sp)
    80002d36:	6442                	ld	s0,16(sp)
    80002d38:	64a2                	ld	s1,8(sp)
    80002d3a:	6105                	addi	sp,sp,32
    80002d3c:	8082                	ret

0000000080002d3e <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002d3e:	1101                	addi	sp,sp,-32
    80002d40:	ec06                	sd	ra,24(sp)
    80002d42:	e822                	sd	s0,16(sp)
    80002d44:	e426                	sd	s1,8(sp)
    80002d46:	1000                	addi	s0,sp,32
    80002d48:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002d4a:	00000097          	auipc	ra,0x0
    80002d4e:	ed0080e7          	jalr	-304(ra) # 80002c1a <argraw>
    80002d52:	e088                	sd	a0,0(s1)
  return 0;
}
    80002d54:	4501                	li	a0,0
    80002d56:	60e2                	ld	ra,24(sp)
    80002d58:	6442                	ld	s0,16(sp)
    80002d5a:	64a2                	ld	s1,8(sp)
    80002d5c:	6105                	addi	sp,sp,32
    80002d5e:	8082                	ret

0000000080002d60 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002d60:	1101                	addi	sp,sp,-32
    80002d62:	ec06                	sd	ra,24(sp)
    80002d64:	e822                	sd	s0,16(sp)
    80002d66:	e426                	sd	s1,8(sp)
    80002d68:	e04a                	sd	s2,0(sp)
    80002d6a:	1000                	addi	s0,sp,32
    80002d6c:	84ae                	mv	s1,a1
    80002d6e:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002d70:	00000097          	auipc	ra,0x0
    80002d74:	eaa080e7          	jalr	-342(ra) # 80002c1a <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002d78:	864a                	mv	a2,s2
    80002d7a:	85a6                	mv	a1,s1
    80002d7c:	00000097          	auipc	ra,0x0
    80002d80:	f58080e7          	jalr	-168(ra) # 80002cd4 <fetchstr>
}
    80002d84:	60e2                	ld	ra,24(sp)
    80002d86:	6442                	ld	s0,16(sp)
    80002d88:	64a2                	ld	s1,8(sp)
    80002d8a:	6902                	ld	s2,0(sp)
    80002d8c:	6105                	addi	sp,sp,32
    80002d8e:	8082                	ret

0000000080002d90 <syscall>:
[SYS_getMLFQInfo] sys_getMLFQInfo
};

void
syscall(void)
{
    80002d90:	1101                	addi	sp,sp,-32
    80002d92:	ec06                	sd	ra,24(sp)
    80002d94:	e822                	sd	s0,16(sp)
    80002d96:	e426                	sd	s1,8(sp)
    80002d98:	e04a                	sd	s2,0(sp)
    80002d9a:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002d9c:	fffff097          	auipc	ra,0xfffff
    80002da0:	bfa080e7          	jalr	-1030(ra) # 80001996 <myproc>
    80002da4:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002da6:	07853903          	ld	s2,120(a0)
    80002daa:	0a893783          	ld	a5,168(s2)
    80002dae:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002db2:	37fd                	addiw	a5,a5,-1
    80002db4:	4769                	li	a4,26
    80002db6:	00f76f63          	bltu	a4,a5,80002dd4 <syscall+0x44>
    80002dba:	00369713          	slli	a4,a3,0x3
    80002dbe:	00005797          	auipc	a5,0x5
    80002dc2:	68a78793          	addi	a5,a5,1674 # 80008448 <syscalls>
    80002dc6:	97ba                	add	a5,a5,a4
    80002dc8:	639c                	ld	a5,0(a5)
    80002dca:	c789                	beqz	a5,80002dd4 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002dcc:	9782                	jalr	a5
    80002dce:	06a93823          	sd	a0,112(s2)
    80002dd2:	a839                	j	80002df0 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002dd4:	1b048613          	addi	a2,s1,432
    80002dd8:	588c                	lw	a1,48(s1)
    80002dda:	00005517          	auipc	a0,0x5
    80002dde:	63650513          	addi	a0,a0,1590 # 80008410 <states.0+0x150>
    80002de2:	ffffd097          	auipc	ra,0xffffd
    80002de6:	7a0080e7          	jalr	1952(ra) # 80000582 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002dea:	7cbc                	ld	a5,120(s1)
    80002dec:	577d                	li	a4,-1
    80002dee:	fbb8                	sd	a4,112(a5)
  }
}
    80002df0:	60e2                	ld	ra,24(sp)
    80002df2:	6442                	ld	s0,16(sp)
    80002df4:	64a2                	ld	s1,8(sp)
    80002df6:	6902                	ld	s2,0(sp)
    80002df8:	6105                	addi	sp,sp,32
    80002dfa:	8082                	ret

0000000080002dfc <sys_exit>:
#include "proc.h"


uint64
sys_exit(void)
{
    80002dfc:	1101                	addi	sp,sp,-32
    80002dfe:	ec06                	sd	ra,24(sp)
    80002e00:	e822                	sd	s0,16(sp)
    80002e02:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002e04:	fec40593          	addi	a1,s0,-20
    80002e08:	4501                	li	a0,0
    80002e0a:	00000097          	auipc	ra,0x0
    80002e0e:	f12080e7          	jalr	-238(ra) # 80002d1c <argint>
    return -1;
    80002e12:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002e14:	00054963          	bltz	a0,80002e26 <sys_exit+0x2a>
  exit(n);
    80002e18:	fec42503          	lw	a0,-20(s0)
    80002e1c:	fffff097          	auipc	ra,0xfffff
    80002e20:	74e080e7          	jalr	1870(ra) # 8000256a <exit>
  return 0;  // not reached
    80002e24:	4781                	li	a5,0
}
    80002e26:	853e                	mv	a0,a5
    80002e28:	60e2                	ld	ra,24(sp)
    80002e2a:	6442                	ld	s0,16(sp)
    80002e2c:	6105                	addi	sp,sp,32
    80002e2e:	8082                	ret

0000000080002e30 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002e30:	1141                	addi	sp,sp,-16
    80002e32:	e406                	sd	ra,8(sp)
    80002e34:	e022                	sd	s0,0(sp)
    80002e36:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002e38:	fffff097          	auipc	ra,0xfffff
    80002e3c:	b5e080e7          	jalr	-1186(ra) # 80001996 <myproc>
}
    80002e40:	5908                	lw	a0,48(a0)
    80002e42:	60a2                	ld	ra,8(sp)
    80002e44:	6402                	ld	s0,0(sp)
    80002e46:	0141                	addi	sp,sp,16
    80002e48:	8082                	ret

0000000080002e4a <sys_fork>:

uint64
sys_fork(void)
{
    80002e4a:	1141                	addi	sp,sp,-16
    80002e4c:	e406                	sd	ra,8(sp)
    80002e4e:	e022                	sd	s0,0(sp)
    80002e50:	0800                	addi	s0,sp,16
  return fork();
    80002e52:	fffff097          	auipc	ra,0xfffff
    80002e56:	f50080e7          	jalr	-176(ra) # 80001da2 <fork>
}
    80002e5a:	60a2                	ld	ra,8(sp)
    80002e5c:	6402                	ld	s0,0(sp)
    80002e5e:	0141                	addi	sp,sp,16
    80002e60:	8082                	ret

0000000080002e62 <sys_wait>:

uint64
sys_wait(void)
{
    80002e62:	1101                	addi	sp,sp,-32
    80002e64:	ec06                	sd	ra,24(sp)
    80002e66:	e822                	sd	s0,16(sp)
    80002e68:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002e6a:	fe840593          	addi	a1,s0,-24
    80002e6e:	4501                	li	a0,0
    80002e70:	00000097          	auipc	ra,0x0
    80002e74:	ece080e7          	jalr	-306(ra) # 80002d3e <argaddr>
    80002e78:	87aa                	mv	a5,a0
    return -1;
    80002e7a:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002e7c:	0007c863          	bltz	a5,80002e8c <sys_wait+0x2a>
  return wait(p);
    80002e80:	fe843503          	ld	a0,-24(s0)
    80002e84:	fffff097          	auipc	ra,0xfffff
    80002e88:	4ee080e7          	jalr	1262(ra) # 80002372 <wait>
}
    80002e8c:	60e2                	ld	ra,24(sp)
    80002e8e:	6442                	ld	s0,16(sp)
    80002e90:	6105                	addi	sp,sp,32
    80002e92:	8082                	ret

0000000080002e94 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002e94:	7179                	addi	sp,sp,-48
    80002e96:	f406                	sd	ra,40(sp)
    80002e98:	f022                	sd	s0,32(sp)
    80002e9a:	ec26                	sd	s1,24(sp)
    80002e9c:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002e9e:	fdc40593          	addi	a1,s0,-36
    80002ea2:	4501                	li	a0,0
    80002ea4:	00000097          	auipc	ra,0x0
    80002ea8:	e78080e7          	jalr	-392(ra) # 80002d1c <argint>
    return -1;
    80002eac:	54fd                	li	s1,-1
  if(argint(0, &n) < 0)
    80002eae:	00054f63          	bltz	a0,80002ecc <sys_sbrk+0x38>
  addr = myproc()->sz;
    80002eb2:	fffff097          	auipc	ra,0xfffff
    80002eb6:	ae4080e7          	jalr	-1308(ra) # 80001996 <myproc>
    80002eba:	5524                	lw	s1,104(a0)
  if(growproc(n) < 0)
    80002ebc:	fdc42503          	lw	a0,-36(s0)
    80002ec0:	fffff097          	auipc	ra,0xfffff
    80002ec4:	e6e080e7          	jalr	-402(ra) # 80001d2e <growproc>
    80002ec8:	00054863          	bltz	a0,80002ed8 <sys_sbrk+0x44>
    return -1;
  return addr;
}
    80002ecc:	8526                	mv	a0,s1
    80002ece:	70a2                	ld	ra,40(sp)
    80002ed0:	7402                	ld	s0,32(sp)
    80002ed2:	64e2                	ld	s1,24(sp)
    80002ed4:	6145                	addi	sp,sp,48
    80002ed6:	8082                	ret
    return -1;
    80002ed8:	54fd                	li	s1,-1
    80002eda:	bfcd                	j	80002ecc <sys_sbrk+0x38>

0000000080002edc <sys_sleep>:

uint64
sys_sleep(void)
{
    80002edc:	7139                	addi	sp,sp,-64
    80002ede:	fc06                	sd	ra,56(sp)
    80002ee0:	f822                	sd	s0,48(sp)
    80002ee2:	f426                	sd	s1,40(sp)
    80002ee4:	f04a                	sd	s2,32(sp)
    80002ee6:	ec4e                	sd	s3,24(sp)
    80002ee8:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002eea:	fcc40593          	addi	a1,s0,-52
    80002eee:	4501                	li	a0,0
    80002ef0:	00000097          	auipc	ra,0x0
    80002ef4:	e2c080e7          	jalr	-468(ra) # 80002d1c <argint>
    return -1;
    80002ef8:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002efa:	06054563          	bltz	a0,80002f64 <sys_sleep+0x88>
  acquire(&tickslock);
    80002efe:	00015517          	auipc	a0,0x15
    80002f02:	1ca50513          	addi	a0,a0,458 # 800180c8 <tickslock>
    80002f06:	ffffe097          	auipc	ra,0xffffe
    80002f0a:	cca080e7          	jalr	-822(ra) # 80000bd0 <acquire>
  ticks0 = ticks;
    80002f0e:	00006917          	auipc	s2,0x6
    80002f12:	a4292903          	lw	s2,-1470(s2) # 80008950 <ticks>
  while(ticks - ticks0 < n){
    80002f16:	fcc42783          	lw	a5,-52(s0)
    80002f1a:	cf85                	beqz	a5,80002f52 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002f1c:	00015997          	auipc	s3,0x15
    80002f20:	1ac98993          	addi	s3,s3,428 # 800180c8 <tickslock>
    80002f24:	00006497          	auipc	s1,0x6
    80002f28:	a2c48493          	addi	s1,s1,-1492 # 80008950 <ticks>
    if(myproc()->killed){
    80002f2c:	fffff097          	auipc	ra,0xfffff
    80002f30:	a6a080e7          	jalr	-1430(ra) # 80001996 <myproc>
    80002f34:	551c                	lw	a5,40(a0)
    80002f36:	ef9d                	bnez	a5,80002f74 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002f38:	85ce                	mv	a1,s3
    80002f3a:	8526                	mv	a0,s1
    80002f3c:	fffff097          	auipc	ra,0xfffff
    80002f40:	3cc080e7          	jalr	972(ra) # 80002308 <sleep>
  while(ticks - ticks0 < n){
    80002f44:	409c                	lw	a5,0(s1)
    80002f46:	412787bb          	subw	a5,a5,s2
    80002f4a:	fcc42703          	lw	a4,-52(s0)
    80002f4e:	fce7efe3          	bltu	a5,a4,80002f2c <sys_sleep+0x50>
  }
  release(&tickslock);
    80002f52:	00015517          	auipc	a0,0x15
    80002f56:	17650513          	addi	a0,a0,374 # 800180c8 <tickslock>
    80002f5a:	ffffe097          	auipc	ra,0xffffe
    80002f5e:	d2a080e7          	jalr	-726(ra) # 80000c84 <release>
  return 0;
    80002f62:	4781                	li	a5,0
}
    80002f64:	853e                	mv	a0,a5
    80002f66:	70e2                	ld	ra,56(sp)
    80002f68:	7442                	ld	s0,48(sp)
    80002f6a:	74a2                	ld	s1,40(sp)
    80002f6c:	7902                	ld	s2,32(sp)
    80002f6e:	69e2                	ld	s3,24(sp)
    80002f70:	6121                	addi	sp,sp,64
    80002f72:	8082                	ret
      release(&tickslock);
    80002f74:	00015517          	auipc	a0,0x15
    80002f78:	15450513          	addi	a0,a0,340 # 800180c8 <tickslock>
    80002f7c:	ffffe097          	auipc	ra,0xffffe
    80002f80:	d08080e7          	jalr	-760(ra) # 80000c84 <release>
      return -1;
    80002f84:	57fd                	li	a5,-1
    80002f86:	bff9                	j	80002f64 <sys_sleep+0x88>

0000000080002f88 <sys_kill>:

uint64
sys_kill(void)
{
    80002f88:	1101                	addi	sp,sp,-32
    80002f8a:	ec06                	sd	ra,24(sp)
    80002f8c:	e822                	sd	s0,16(sp)
    80002f8e:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002f90:	fec40593          	addi	a1,s0,-20
    80002f94:	4501                	li	a0,0
    80002f96:	00000097          	auipc	ra,0x0
    80002f9a:	d86080e7          	jalr	-634(ra) # 80002d1c <argint>
    80002f9e:	87aa                	mv	a5,a0
    return -1;
    80002fa0:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002fa2:	0007c863          	bltz	a5,80002fb2 <sys_kill+0x2a>
  return kill(pid);
    80002fa6:	fec42503          	lw	a0,-20(s0)
    80002faa:	fffff097          	auipc	ra,0xfffff
    80002fae:	696080e7          	jalr	1686(ra) # 80002640 <kill>
}
    80002fb2:	60e2                	ld	ra,24(sp)
    80002fb4:	6442                	ld	s0,16(sp)
    80002fb6:	6105                	addi	sp,sp,32
    80002fb8:	8082                	ret

0000000080002fba <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002fba:	1101                	addi	sp,sp,-32
    80002fbc:	ec06                	sd	ra,24(sp)
    80002fbe:	e822                	sd	s0,16(sp)
    80002fc0:	e426                	sd	s1,8(sp)
    80002fc2:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002fc4:	00015517          	auipc	a0,0x15
    80002fc8:	10450513          	addi	a0,a0,260 # 800180c8 <tickslock>
    80002fcc:	ffffe097          	auipc	ra,0xffffe
    80002fd0:	c04080e7          	jalr	-1020(ra) # 80000bd0 <acquire>
  xticks = ticks;
    80002fd4:	00006497          	auipc	s1,0x6
    80002fd8:	97c4a483          	lw	s1,-1668(s1) # 80008950 <ticks>
  release(&tickslock);
    80002fdc:	00015517          	auipc	a0,0x15
    80002fe0:	0ec50513          	addi	a0,a0,236 # 800180c8 <tickslock>
    80002fe4:	ffffe097          	auipc	ra,0xffffe
    80002fe8:	ca0080e7          	jalr	-864(ra) # 80000c84 <release>
  return xticks;
}
    80002fec:	02049513          	slli	a0,s1,0x20
    80002ff0:	9101                	srli	a0,a0,0x20
    80002ff2:	60e2                	ld	ra,24(sp)
    80002ff4:	6442                	ld	s0,16(sp)
    80002ff6:	64a2                	ld	s1,8(sp)
    80002ff8:	6105                	addi	sp,sp,32
    80002ffa:	8082                	ret

0000000080002ffc <sys_getppid>:

uint64
sys_getppid(void){
    80002ffc:	1141                	addi	sp,sp,-16
    80002ffe:	e406                	sd	ra,8(sp)
    80003000:	e022                	sd	s0,0(sp)
    80003002:	0800                	addi	s0,sp,16
  //gets ppid in one line 
  return myproc()->parent->pid;
    80003004:	fffff097          	auipc	ra,0xfffff
    80003008:	992080e7          	jalr	-1646(ra) # 80001996 <myproc>
    8000300c:	6d3c                	ld	a5,88(a0)
}
    8000300e:	5b88                	lw	a0,48(a5)
    80003010:	60a2                	ld	ra,8(sp)
    80003012:	6402                	ld	s0,0(sp)
    80003014:	0141                	addi	sp,sp,16
    80003016:	8082                	ret

0000000080003018 <sys_ps>:

extern struct proc proc[NPROC];
uint64
sys_ps(void){
    80003018:	7165                	addi	sp,sp,-400
    8000301a:	e706                	sd	ra,392(sp)
    8000301c:	e322                	sd	s0,384(sp)
    8000301e:	fea6                	sd	s1,376(sp)
    80003020:	faca                	sd	s2,368(sp)
    80003022:	f6ce                	sd	s3,360(sp)
    80003024:	f2d2                	sd	s4,352(sp)
    80003026:	eed6                	sd	s5,344(sp)
    80003028:	eada                	sd	s6,336(sp)
    8000302a:	e6de                	sd	s7,328(sp)
    8000302c:	e2e2                	sd	s8,320(sp)
    8000302e:	fe66                	sd	s9,312(sp)
    80003030:	fa6a                	sd	s10,304(sp)
    80003032:	f66e                	sd	s11,296(sp)
    80003034:	0b00                	addi	s0,sp,400
    80003036:	81010113          	addi	sp,sp,-2032
  //number of processes running
  int numProc = 0;
  //give the correct number of iterations to put into ps array
  int numElements = sizeof(proc)/sizeof(proc[0]);
  //loop through
  for(i = 0; i < numElements; ++i){
    8000303a:	0000e717          	auipc	a4,0xe
    8000303e:	0a670713          	addi	a4,a4,166 # 800110e0 <proc+0x18>
    80003042:	00015317          	auipc	t1,0x15
    80003046:	09e30313          	addi	t1,t1,158 # 800180e0 <bcache>
  int numProc = 0;
    8000304a:	4481                	li	s1,0
    //check if process is actually being used
    if(proc[i].state != UNUSED){
      //get pid
      ps[numProc].pid = proc[i].pid;
    8000304c:	75fd                	lui	a1,0xfffff
    8000304e:	f9040793          	addi	a5,s0,-112
    80003052:	95be                	add	a1,a1,a5
      //check if it has a parent
      if(proc[i].name[0] == 'i'){
    80003054:	06900f93          	li	t6,105
        ps[numProc].ppid = 0;
    80003058:	4f01                	li	t5,0
    8000305a:	4e95                	li	t4,5
    8000305c:	00005897          	auipc	a7,0x5
    80003060:	4cc88893          	addi	a7,a7,1228 # 80008528 <syscalls+0xe0>
          ps[numProc].state[5] = 'N';
          ps[numProc].state[6] = 'G';
          ps[numProc].state[7] = '\0';
          break;
        case ZOMBIE:
          ps[numProc].state[0] = 'Z';
    80003064:	05a00d93          	li	s11,90
          ps[numProc].state[1] = 'O';
    80003068:	04f00d13          	li	s10,79
          ps[numProc].state[2] = 'M';
    8000306c:	04d00c93          	li	s9,77
          ps[numProc].state[3] = 'B';
    80003070:	04200b13          	li	s6,66
          ps[numProc].state[4] = 'I';
    80003074:	04900093          	li	ra,73
          ps[numProc].state[5] = 'E';
    80003078:	04500293          	li	t0,69
          ps[numProc].state[0] = 'R';
    8000307c:	05200a93          	li	s5,82
          ps[numProc].state[1] = 'U';
    80003080:	05500393          	li	t2,85
          ps[numProc].state[2] = 'N';
    80003084:	04e00e13          	li	t3,78
          ps[numProc].state[6] = 'G';
    80003088:	04700a13          	li	s4,71
          ps[numProc].state[4] = 'A';
    8000308c:	04100c13          	li	s8,65
          ps[numProc].state[6] = 'L';
    80003090:	04c00993          	li	s3,76
          ps[numProc].state[0] = 'S';
    80003094:	05300913          	li	s2,83
          ps[numProc].state[4] = 'P';
    80003098:	05000b93          	li	s7,80
    8000309c:	a855                	j	80003150 <sys_ps+0x138>
          ps[numProc].state[0] = 'U';
    8000309e:	00349693          	slli	a3,s1,0x3
    800030a2:	96a6                	add	a3,a3,s1
    800030a4:	068a                	slli	a3,a3,0x2
    800030a6:	96ae                	add	a3,a3,a1
    800030a8:	70768423          	sb	t2,1800(a3)
          ps[numProc].state[1] = 'S';
    800030ac:	712684a3          	sb	s2,1801(a3)
          ps[numProc].state[2] = 'E';
    800030b0:	70568523          	sb	t0,1802(a3)
          ps[numProc].state[3] = 'D';
    800030b4:	04400613          	li	a2,68
    800030b8:	70c685a3          	sb	a2,1803(a3)
          ps[numProc].state[4] = '\0';
    800030bc:	70068623          	sb	zero,1804(a3)
          ps[numProc].state[6] = '\0';
          break;
      }
      //Now assign name over seeing as string.h wouldnt work for me
      ps[numProc].name[0] = proc[i].name[0];
    800030c0:	00349693          	slli	a3,s1,0x3
    800030c4:	96a6                	add	a3,a3,s1
    800030c6:	068a                	slli	a3,a3,0x2
    800030c8:	96ae                	add	a3,a3,a1
    800030ca:	70a68923          	sb	a0,1810(a3)
      ps[numProc].name[1] = proc[i].name[1];
    800030ce:	1997c603          	lbu	a2,409(a5)
    800030d2:	70c689a3          	sb	a2,1811(a3)
      ps[numProc].name[2] = proc[i].name[2];
    800030d6:	19a7c603          	lbu	a2,410(a5)
    800030da:	70c68a23          	sb	a2,1812(a3)
      ps[numProc].name[3] = proc[i].name[3];
    800030de:	19b7c603          	lbu	a2,411(a5)
    800030e2:	70c68aa3          	sb	a2,1813(a3)
      ps[numProc].name[4] = proc[i].name[4];
    800030e6:	19c7c603          	lbu	a2,412(a5)
    800030ea:	70c68b23          	sb	a2,1814(a3)
      ps[numProc].name[5] = proc[i].name[5];
    800030ee:	19d7c603          	lbu	a2,413(a5)
    800030f2:	70c68ba3          	sb	a2,1815(a3)
      ps[numProc].name[6] = proc[i].name[6];
    800030f6:	19e7c603          	lbu	a2,414(a5)
    800030fa:	70c68c23          	sb	a2,1816(a3)
      ps[numProc].name[7] = proc[i].name[7];
    800030fe:	19f7c603          	lbu	a2,415(a5)
    80003102:	70c68ca3          	sb	a2,1817(a3)
      ps[numProc].name[8] = proc[i].name[8];
    80003106:	1a07c603          	lbu	a2,416(a5)
    8000310a:	70c68d23          	sb	a2,1818(a3)
      ps[numProc].name[9] = proc[i].name[9];
    8000310e:	1a17c603          	lbu	a2,417(a5)
    80003112:	70c68da3          	sb	a2,1819(a3)
      ps[numProc].name[10] = proc[i].name[10];
    80003116:	1a27c603          	lbu	a2,418(a5)
    8000311a:	70c68e23          	sb	a2,1820(a3)
      ps[numProc].name[11] = proc[i].name[11];
    8000311e:	1a37c603          	lbu	a2,419(a5)
    80003122:	70c68ea3          	sb	a2,1821(a3)
      ps[numProc].name[12] = proc[i].name[12];
    80003126:	1a47c603          	lbu	a2,420(a5)
    8000312a:	70c68f23          	sb	a2,1822(a3)
      ps[numProc].name[13] = proc[i].name[13];
    8000312e:	1a57c603          	lbu	a2,421(a5)
    80003132:	70c68fa3          	sb	a2,1823(a3)
      ps[numProc].name[14] = proc[i].name[14];
    80003136:	1a67c603          	lbu	a2,422(a5)
    8000313a:	72c68023          	sb	a2,1824(a3)
      ps[numProc].name[15] = proc[i].name[15];
    8000313e:	1a77c783          	lbu	a5,423(a5)
    80003142:	72f680a3          	sb	a5,1825(a3)
      //increments numProc so a new process can be stored in ps
      ++numProc;
    80003146:	2485                	addiw	s1,s1,1
  for(i = 0; i < numElements; ++i){
    80003148:	1c070713          	addi	a4,a4,448
    8000314c:	0e670d63          	beq	a4,t1,80003246 <sys_ps+0x22e>
    if(proc[i].state != UNUSED){
    80003150:	87ba                	mv	a5,a4
    80003152:	4314                	lw	a3,0(a4)
    80003154:	daf5                	beqz	a3,80003148 <sys_ps+0x130>
      ps[numProc].pid = proc[i].pid;
    80003156:	00349613          	slli	a2,s1,0x3
    8000315a:	9626                	add	a2,a2,s1
    8000315c:	060a                	slli	a2,a2,0x2
    8000315e:	962e                	add	a2,a2,a1
    80003160:	4f08                	lw	a0,24(a4)
    80003162:	70a62023          	sw	a0,1792(a2)
      if(proc[i].name[0] == 'i'){
    80003166:	19874503          	lbu	a0,408(a4)
        ps[numProc].ppid = 0;
    8000316a:	887a                	mv	a6,t5
      if(proc[i].name[0] == 'i'){
    8000316c:	01f50563          	beq	a0,t6,80003176 <sys_ps+0x15e>
        ps[numProc].ppid = proc[i].parent->pid;
    80003170:	6330                	ld	a2,64(a4)
    80003172:	03062803          	lw	a6,48(a2)
    80003176:	00349613          	slli	a2,s1,0x3
    8000317a:	9626                	add	a2,a2,s1
    8000317c:	060a                	slli	a2,a2,0x2
    8000317e:	962e                	add	a2,a2,a1
    80003180:	71062223          	sw	a6,1796(a2)
      switch(proc[i].state){
    80003184:	f2deeee3          	bltu	t4,a3,800030c0 <sys_ps+0xa8>
    80003188:	068a                	slli	a3,a3,0x2
    8000318a:	96c6                	add	a3,a3,a7
    8000318c:	4294                	lw	a3,0(a3)
    8000318e:	96c6                	add	a3,a3,a7
    80003190:	8682                	jr	a3
          ps[numProc].state[0] = 'S';
    80003192:	00349693          	slli	a3,s1,0x3
    80003196:	96a6                	add	a3,a3,s1
    80003198:	068a                	slli	a3,a3,0x2
    8000319a:	96ae                	add	a3,a3,a1
    8000319c:	71268423          	sb	s2,1800(a3)
          ps[numProc].state[1] = 'L';
    800031a0:	713684a3          	sb	s3,1801(a3)
          ps[numProc].state[2] = 'E';
    800031a4:	70568523          	sb	t0,1802(a3)
          ps[numProc].state[3] = 'E';
    800031a8:	705685a3          	sb	t0,1803(a3)
          ps[numProc].state[4] = 'P';
    800031ac:	71768623          	sb	s7,1804(a3)
          ps[numProc].state[5] = 'I';
    800031b0:	701686a3          	sb	ra,1805(a3)
          ps[numProc].state[6] = 'N';
    800031b4:	71c68723          	sb	t3,1806(a3)
          ps[numProc].state[7] = 'G';
    800031b8:	714687a3          	sb	s4,1807(a3)
          ps[numProc].state[8] = '\0';
    800031bc:	70068823          	sb	zero,1808(a3)
          break;
    800031c0:	b701                	j	800030c0 <sys_ps+0xa8>
          ps[numProc].state[0] = 'R';
    800031c2:	00349693          	slli	a3,s1,0x3
    800031c6:	96a6                	add	a3,a3,s1
    800031c8:	068a                	slli	a3,a3,0x2
    800031ca:	96ae                	add	a3,a3,a1
    800031cc:	71568423          	sb	s5,1800(a3)
          ps[numProc].state[1] = 'U';
    800031d0:	707684a3          	sb	t2,1801(a3)
          ps[numProc].state[2] = 'N';
    800031d4:	71c68523          	sb	t3,1802(a3)
          ps[numProc].state[3] = 'N';
    800031d8:	71c685a3          	sb	t3,1803(a3)
          ps[numProc].state[4] = 'A';
    800031dc:	71868623          	sb	s8,1804(a3)
          ps[numProc].state[5] = 'B';
    800031e0:	716686a3          	sb	s6,1805(a3)
          ps[numProc].state[6] = 'L';
    800031e4:	71368723          	sb	s3,1806(a3)
          ps[numProc].state[7] = 'E';
    800031e8:	705687a3          	sb	t0,1807(a3)
          ps[numProc].state[8] = '\0';
    800031ec:	70068823          	sb	zero,1808(a3)
          break;
    800031f0:	bdc1                	j	800030c0 <sys_ps+0xa8>
          ps[numProc].state[0] = 'R';
    800031f2:	00349693          	slli	a3,s1,0x3
    800031f6:	96a6                	add	a3,a3,s1
    800031f8:	068a                	slli	a3,a3,0x2
    800031fa:	96ae                	add	a3,a3,a1
    800031fc:	71568423          	sb	s5,1800(a3)
          ps[numProc].state[1] = 'U';
    80003200:	707684a3          	sb	t2,1801(a3)
          ps[numProc].state[2] = 'N';
    80003204:	71c68523          	sb	t3,1802(a3)
          ps[numProc].state[3] = 'N';
    80003208:	71c685a3          	sb	t3,1803(a3)
          ps[numProc].state[4] = 'I';
    8000320c:	70168623          	sb	ra,1804(a3)
          ps[numProc].state[5] = 'N';
    80003210:	71c686a3          	sb	t3,1805(a3)
          ps[numProc].state[6] = 'G';
    80003214:	71468723          	sb	s4,1806(a3)
          ps[numProc].state[7] = '\0';
    80003218:	700687a3          	sb	zero,1807(a3)
          break;
    8000321c:	b555                	j	800030c0 <sys_ps+0xa8>
          ps[numProc].state[0] = 'Z';
    8000321e:	00349693          	slli	a3,s1,0x3
    80003222:	96a6                	add	a3,a3,s1
    80003224:	068a                	slli	a3,a3,0x2
    80003226:	96ae                	add	a3,a3,a1
    80003228:	71b68423          	sb	s11,1800(a3)
          ps[numProc].state[1] = 'O';
    8000322c:	71a684a3          	sb	s10,1801(a3)
          ps[numProc].state[2] = 'M';
    80003230:	71968523          	sb	s9,1802(a3)
          ps[numProc].state[3] = 'B';
    80003234:	716685a3          	sb	s6,1803(a3)
          ps[numProc].state[4] = 'I';
    80003238:	70168623          	sb	ra,1804(a3)
          ps[numProc].state[5] = 'E';
    8000323c:	705686a3          	sb	t0,1805(a3)
          ps[numProc].state[6] = '\0';
    80003240:	70068723          	sb	zero,1806(a3)
          break;
    80003244:	bdb5                	j	800030c0 <sys_ps+0xa8>
    }
  }
  
  //save address of user space argument to arg_addr
  uint64 arg_addr;
  argaddr(0, &arg_addr);
    80003246:	797d                	lui	s2,0xfffff
    80003248:	6f890593          	addi	a1,s2,1784 # fffffffffffff6f8 <end+0xffffffff7ffdc250>
    8000324c:	f9040793          	addi	a5,s0,-112
    80003250:	95be                	add	a1,a1,a5
    80003252:	4501                	li	a0,0
    80003254:	00000097          	auipc	ra,0x0
    80003258:	aea080e7          	jalr	-1302(ra) # 80002d3e <argaddr>
  
  //copy array to saved address
  if(copyout(myproc()->pagetable,arg_addr,(char*)ps,numProc*sizeof(struct ps_struct)) < 0){
    8000325c:	ffffe097          	auipc	ra,0xffffe
    80003260:	73a080e7          	jalr	1850(ra) # 80001996 <myproc>
    80003264:	89a6                	mv	s3,s1
    80003266:	00349693          	slli	a3,s1,0x3
    8000326a:	96a6                	add	a3,a3,s1
    8000326c:	70090613          	addi	a2,s2,1792
    80003270:	f9040793          	addi	a5,s0,-112
    80003274:	993e                	add	s2,s2,a5
    80003276:	068a                	slli	a3,a3,0x2
    80003278:	963e                	add	a2,a2,a5
    8000327a:	6f893583          	ld	a1,1784(s2)
    8000327e:	7928                	ld	a0,112(a0)
    80003280:	ffffe097          	auipc	ra,0xffffe
    80003284:	3d6080e7          	jalr	982(ra) # 80001656 <copyout>
    80003288:	02054463          	bltz	a0,800032b0 <sys_ps+0x298>
    return -1;
  }
  
  //return numProc
  return numProc;
}
    8000328c:	854e                	mv	a0,s3
    8000328e:	7f010113          	addi	sp,sp,2032
    80003292:	60ba                	ld	ra,392(sp)
    80003294:	641a                	ld	s0,384(sp)
    80003296:	74f6                	ld	s1,376(sp)
    80003298:	7956                	ld	s2,368(sp)
    8000329a:	79b6                	ld	s3,360(sp)
    8000329c:	7a16                	ld	s4,352(sp)
    8000329e:	6af6                	ld	s5,344(sp)
    800032a0:	6b56                	ld	s6,336(sp)
    800032a2:	6bb6                	ld	s7,328(sp)
    800032a4:	6c16                	ld	s8,320(sp)
    800032a6:	7cf2                	ld	s9,312(sp)
    800032a8:	7d52                	ld	s10,304(sp)
    800032aa:	7db2                	ld	s11,296(sp)
    800032ac:	6159                	addi	sp,sp,400
    800032ae:	8082                	ret
    return -1;
    800032b0:	59fd                	li	s3,-1
    800032b2:	bfe9                	j	8000328c <sys_ps+0x274>

00000000800032b4 <sys_getschedhistory>:

//implement getschedhistory
uint64
sys_getschedhistory(void){
    800032b4:	7139                	addi	sp,sp,-64
    800032b6:	fc06                	sd	ra,56(sp)
    800032b8:	f822                	sd	s0,48(sp)
    800032ba:	f426                	sd	s1,40(sp)
    800032bc:	0080                	addi	s0,sp,64
    int trapCount;
    int sleepCount;
  } my_history;
  
  //get current process and insert the history
  struct proc *curr = myproc();
    800032be:	ffffe097          	auipc	ra,0xffffe
    800032c2:	6d8080e7          	jalr	1752(ra) # 80001996 <myproc>
    800032c6:	84aa                	mv	s1,a0
  my_history.runCount = curr->runCount;
    800032c8:	595c                	lw	a5,52(a0)
    800032ca:	fcf42423          	sw	a5,-56(s0)
  my_history.systemcallCount = curr->systemcallCount;
    800032ce:	5d1c                	lw	a5,56(a0)
    800032d0:	fcf42623          	sw	a5,-52(s0)
  my_history.interruptCount = curr->interruptCount;
    800032d4:	5d5c                	lw	a5,60(a0)
    800032d6:	fcf42823          	sw	a5,-48(s0)
  my_history.preemptCount = curr->preemptCount;
    800032da:	413c                	lw	a5,64(a0)
    800032dc:	fcf42a23          	sw	a5,-44(s0)
  my_history.trapCount = curr->trapCount;
    800032e0:	417c                	lw	a5,68(a0)
    800032e2:	fcf42c23          	sw	a5,-40(s0)
  my_history.sleepCount = curr->sleepCount;
    800032e6:	453c                	lw	a5,72(a0)
    800032e8:	fcf42e23          	sw	a5,-36(s0)
  
  
  //save addy of user space arguemtn to arg_addr
  uint64 arg_addr;
  argaddr(0, &arg_addr);
    800032ec:	fc040593          	addi	a1,s0,-64
    800032f0:	4501                	li	a0,0
    800032f2:	00000097          	auipc	ra,0x0
    800032f6:	a4c080e7          	jalr	-1460(ra) # 80002d3e <argaddr>
  
  //copy my_history to saved address
  if(copyout(curr->pagetable,arg_addr,(char*)&my_history,sizeof(struct sched_history)) < 0){
    800032fa:	46e1                	li	a3,24
    800032fc:	fc840613          	addi	a2,s0,-56
    80003300:	fc043583          	ld	a1,-64(s0)
    80003304:	78a8                	ld	a0,112(s1)
    80003306:	ffffe097          	auipc	ra,0xffffe
    8000330a:	350080e7          	jalr	848(ra) # 80001656 <copyout>
    8000330e:	00054863          	bltz	a0,8000331e <sys_getschedhistory+0x6a>
    return -1;
  }
  
  return curr->pid;
    80003312:	5888                	lw	a0,48(s1)
}
    80003314:	70e2                	ld	ra,56(sp)
    80003316:	7442                	ld	s0,48(sp)
    80003318:	74a2                	ld	s1,40(sp)
    8000331a:	6121                	addi	sp,sp,64
    8000331c:	8082                	ret
    return -1;
    8000331e:	557d                	li	a0,-1
    80003320:	bfd5                	j	80003314 <sys_getschedhistory+0x60>

0000000080003322 <sys_startMLFQ>:

//added startMLFQ system call
uint64
sys_startMLFQ(void){
    80003322:	1101                	addi	sp,sp,-32
    80003324:	ec06                	sd	ra,24(sp)
    80003326:	e822                	sd	s0,16(sp)
    80003328:	1000                	addi	s0,sp,32
	int m, n;
	argint(0, &m);
    8000332a:	fec40593          	addi	a1,s0,-20
    8000332e:	4501                	li	a0,0
    80003330:	00000097          	auipc	ra,0x0
    80003334:	9ec080e7          	jalr	-1556(ra) # 80002d1c <argint>
	argint(1, &n);
    80003338:	fe840593          	addi	a1,s0,-24
    8000333c:	4505                	li	a0,1
    8000333e:	00000097          	auipc	ra,0x0
    80003342:	9de080e7          	jalr	-1570(ra) # 80002d1c <argint>
	mlfq.flag = 1;
    80003346:	0000e797          	auipc	a5,0xe
    8000334a:	caa78793          	addi	a5,a5,-854 # 80010ff0 <mlfq>
    8000334e:	4705                	li	a4,1
    80003350:	c398                	sw	a4,0(a5)
	mlfq.levels = m;
    80003352:	fec42703          	lw	a4,-20(s0)
    80003356:	c3d8                	sw	a4,4(a5)
	mlfq.tickTime = n;
    80003358:	fe842703          	lw	a4,-24(s0)
    8000335c:	c798                	sw	a4,8(a5)
	return 0;
}
    8000335e:	4501                	li	a0,0
    80003360:	60e2                	ld	ra,24(sp)
    80003362:	6442                	ld	s0,16(sp)
    80003364:	6105                	addi	sp,sp,32
    80003366:	8082                	ret

0000000080003368 <sys_stopMLFQ>:

//added stopMLFQ system call
uint64
sys_stopMLFQ(void){
    80003368:	1141                	addi	sp,sp,-16
    8000336a:	e422                	sd	s0,8(sp)
    8000336c:	0800                	addi	s0,sp,16
	mlfq.flag = 0;
    8000336e:	0000e797          	auipc	a5,0xe
    80003372:	c807a123          	sw	zero,-894(a5) # 80010ff0 <mlfq>
	return 0;
}
    80003376:	4501                	li	a0,0
    80003378:	6422                	ld	s0,8(sp)
    8000337a:	0141                	addi	sp,sp,16
    8000337c:	8082                	ret

000000008000337e <sys_getMLFQInfo>:

//added getMLFQInfo system call
uint64
sys_getMLFQInfo(void){
    8000337e:	1101                	addi	sp,sp,-32
    80003380:	ec06                	sd	ra,24(sp)
    80003382:	e822                	sd	s0,16(sp)
    80003384:	1000                	addi	s0,sp,32
  
  uint64 arg_addr;
  argaddr(0, &arg_addr);
    80003386:	fe840593          	addi	a1,s0,-24
    8000338a:	4501                	li	a0,0
    8000338c:	00000097          	auipc	ra,0x0
    80003390:	9b2080e7          	jalr	-1614(ra) # 80002d3e <argaddr>
  struct proc *curr = myproc();
    80003394:	ffffe097          	auipc	ra,0xffffe
    80003398:	602080e7          	jalr	1538(ra) # 80001996 <myproc>
  int i;
  for(i = 0; i < 10; ++i){
    8000339c:	17850713          	addi	a4,a0,376
    800033a0:	0000e797          	auipc	a5,0xe
    800033a4:	d0078793          	addi	a5,a5,-768 # 800110a0 <mlfq+0xb0>
    800033a8:	0000e617          	auipc	a2,0xe
    800033ac:	d2060613          	addi	a2,a2,-736 # 800110c8 <proc>
     mlfq.tickCounts[i] = curr->report.tickCounts[i];
    800033b0:	4314                	lw	a3,0(a4)
    800033b2:	c394                	sw	a3,0(a5)
  for(i = 0; i < 10; ++i){
    800033b4:	0711                	addi	a4,a4,4
    800033b6:	0791                	addi	a5,a5,4
    800033b8:	fec79ce3          	bne	a5,a2,800033b0 <sys_getMLFQInfo+0x32>
  }
  //save addy of user space arguemtn to arg_addr
  
  
  //copy my_history to saved address
  if(copyout(curr->pagetable,arg_addr,(char *)&mlfq.tickCounts,40) < 0){
    800033bc:	02800693          	li	a3,40
    800033c0:	0000e617          	auipc	a2,0xe
    800033c4:	ce060613          	addi	a2,a2,-800 # 800110a0 <mlfq+0xb0>
    800033c8:	fe843583          	ld	a1,-24(s0)
    800033cc:	7928                	ld	a0,112(a0)
    800033ce:	ffffe097          	auipc	ra,0xffffe
    800033d2:	288080e7          	jalr	648(ra) # 80001656 <copyout>
    return -1;
  }
	
  return 0;
}
    800033d6:	957d                	srai	a0,a0,0x3f
    800033d8:	60e2                	ld	ra,24(sp)
    800033da:	6442                	ld	s0,16(sp)
    800033dc:	6105                	addi	sp,sp,32
    800033de:	8082                	ret

00000000800033e0 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800033e0:	7179                	addi	sp,sp,-48
    800033e2:	f406                	sd	ra,40(sp)
    800033e4:	f022                	sd	s0,32(sp)
    800033e6:	ec26                	sd	s1,24(sp)
    800033e8:	e84a                	sd	s2,16(sp)
    800033ea:	e44e                	sd	s3,8(sp)
    800033ec:	e052                	sd	s4,0(sp)
    800033ee:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800033f0:	00005597          	auipc	a1,0x5
    800033f4:	15058593          	addi	a1,a1,336 # 80008540 <syscalls+0xf8>
    800033f8:	00015517          	auipc	a0,0x15
    800033fc:	ce850513          	addi	a0,a0,-792 # 800180e0 <bcache>
    80003400:	ffffd097          	auipc	ra,0xffffd
    80003404:	740080e7          	jalr	1856(ra) # 80000b40 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003408:	0001d797          	auipc	a5,0x1d
    8000340c:	cd878793          	addi	a5,a5,-808 # 800200e0 <bcache+0x8000>
    80003410:	0001d717          	auipc	a4,0x1d
    80003414:	f3870713          	addi	a4,a4,-200 # 80020348 <bcache+0x8268>
    80003418:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000341c:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003420:	00015497          	auipc	s1,0x15
    80003424:	cd848493          	addi	s1,s1,-808 # 800180f8 <bcache+0x18>
    b->next = bcache.head.next;
    80003428:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000342a:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000342c:	00005a17          	auipc	s4,0x5
    80003430:	11ca0a13          	addi	s4,s4,284 # 80008548 <syscalls+0x100>
    b->next = bcache.head.next;
    80003434:	2b893783          	ld	a5,696(s2)
    80003438:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000343a:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000343e:	85d2                	mv	a1,s4
    80003440:	01048513          	addi	a0,s1,16
    80003444:	00001097          	auipc	ra,0x1
    80003448:	4d0080e7          	jalr	1232(ra) # 80004914 <initsleeplock>
    bcache.head.next->prev = b;
    8000344c:	2b893783          	ld	a5,696(s2)
    80003450:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003452:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003456:	45848493          	addi	s1,s1,1112
    8000345a:	fd349de3          	bne	s1,s3,80003434 <binit+0x54>
  }
}
    8000345e:	70a2                	ld	ra,40(sp)
    80003460:	7402                	ld	s0,32(sp)
    80003462:	64e2                	ld	s1,24(sp)
    80003464:	6942                	ld	s2,16(sp)
    80003466:	69a2                	ld	s3,8(sp)
    80003468:	6a02                	ld	s4,0(sp)
    8000346a:	6145                	addi	sp,sp,48
    8000346c:	8082                	ret

000000008000346e <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000346e:	7179                	addi	sp,sp,-48
    80003470:	f406                	sd	ra,40(sp)
    80003472:	f022                	sd	s0,32(sp)
    80003474:	ec26                	sd	s1,24(sp)
    80003476:	e84a                	sd	s2,16(sp)
    80003478:	e44e                	sd	s3,8(sp)
    8000347a:	1800                	addi	s0,sp,48
    8000347c:	892a                	mv	s2,a0
    8000347e:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80003480:	00015517          	auipc	a0,0x15
    80003484:	c6050513          	addi	a0,a0,-928 # 800180e0 <bcache>
    80003488:	ffffd097          	auipc	ra,0xffffd
    8000348c:	748080e7          	jalr	1864(ra) # 80000bd0 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003490:	0001d497          	auipc	s1,0x1d
    80003494:	f084b483          	ld	s1,-248(s1) # 80020398 <bcache+0x82b8>
    80003498:	0001d797          	auipc	a5,0x1d
    8000349c:	eb078793          	addi	a5,a5,-336 # 80020348 <bcache+0x8268>
    800034a0:	02f48f63          	beq	s1,a5,800034de <bread+0x70>
    800034a4:	873e                	mv	a4,a5
    800034a6:	a021                	j	800034ae <bread+0x40>
    800034a8:	68a4                	ld	s1,80(s1)
    800034aa:	02e48a63          	beq	s1,a4,800034de <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800034ae:	449c                	lw	a5,8(s1)
    800034b0:	ff279ce3          	bne	a5,s2,800034a8 <bread+0x3a>
    800034b4:	44dc                	lw	a5,12(s1)
    800034b6:	ff3799e3          	bne	a5,s3,800034a8 <bread+0x3a>
      b->refcnt++;
    800034ba:	40bc                	lw	a5,64(s1)
    800034bc:	2785                	addiw	a5,a5,1
    800034be:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800034c0:	00015517          	auipc	a0,0x15
    800034c4:	c2050513          	addi	a0,a0,-992 # 800180e0 <bcache>
    800034c8:	ffffd097          	auipc	ra,0xffffd
    800034cc:	7bc080e7          	jalr	1980(ra) # 80000c84 <release>
      acquiresleep(&b->lock);
    800034d0:	01048513          	addi	a0,s1,16
    800034d4:	00001097          	auipc	ra,0x1
    800034d8:	47a080e7          	jalr	1146(ra) # 8000494e <acquiresleep>
      return b;
    800034dc:	a8b9                	j	8000353a <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800034de:	0001d497          	auipc	s1,0x1d
    800034e2:	eb24b483          	ld	s1,-334(s1) # 80020390 <bcache+0x82b0>
    800034e6:	0001d797          	auipc	a5,0x1d
    800034ea:	e6278793          	addi	a5,a5,-414 # 80020348 <bcache+0x8268>
    800034ee:	00f48863          	beq	s1,a5,800034fe <bread+0x90>
    800034f2:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800034f4:	40bc                	lw	a5,64(s1)
    800034f6:	cf81                	beqz	a5,8000350e <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800034f8:	64a4                	ld	s1,72(s1)
    800034fa:	fee49de3          	bne	s1,a4,800034f4 <bread+0x86>
  panic("bget: no buffers");
    800034fe:	00005517          	auipc	a0,0x5
    80003502:	05250513          	addi	a0,a0,82 # 80008550 <syscalls+0x108>
    80003506:	ffffd097          	auipc	ra,0xffffd
    8000350a:	032080e7          	jalr	50(ra) # 80000538 <panic>
      b->dev = dev;
    8000350e:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003512:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003516:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000351a:	4785                	li	a5,1
    8000351c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000351e:	00015517          	auipc	a0,0x15
    80003522:	bc250513          	addi	a0,a0,-1086 # 800180e0 <bcache>
    80003526:	ffffd097          	auipc	ra,0xffffd
    8000352a:	75e080e7          	jalr	1886(ra) # 80000c84 <release>
      acquiresleep(&b->lock);
    8000352e:	01048513          	addi	a0,s1,16
    80003532:	00001097          	auipc	ra,0x1
    80003536:	41c080e7          	jalr	1052(ra) # 8000494e <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000353a:	409c                	lw	a5,0(s1)
    8000353c:	cb89                	beqz	a5,8000354e <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000353e:	8526                	mv	a0,s1
    80003540:	70a2                	ld	ra,40(sp)
    80003542:	7402                	ld	s0,32(sp)
    80003544:	64e2                	ld	s1,24(sp)
    80003546:	6942                	ld	s2,16(sp)
    80003548:	69a2                	ld	s3,8(sp)
    8000354a:	6145                	addi	sp,sp,48
    8000354c:	8082                	ret
    virtio_disk_rw(b, 0);
    8000354e:	4581                	li	a1,0
    80003550:	8526                	mv	a0,s1
    80003552:	00003097          	auipc	ra,0x3
    80003556:	fc2080e7          	jalr	-62(ra) # 80006514 <virtio_disk_rw>
    b->valid = 1;
    8000355a:	4785                	li	a5,1
    8000355c:	c09c                	sw	a5,0(s1)
  return b;
    8000355e:	b7c5                	j	8000353e <bread+0xd0>

0000000080003560 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003560:	1101                	addi	sp,sp,-32
    80003562:	ec06                	sd	ra,24(sp)
    80003564:	e822                	sd	s0,16(sp)
    80003566:	e426                	sd	s1,8(sp)
    80003568:	1000                	addi	s0,sp,32
    8000356a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000356c:	0541                	addi	a0,a0,16
    8000356e:	00001097          	auipc	ra,0x1
    80003572:	47a080e7          	jalr	1146(ra) # 800049e8 <holdingsleep>
    80003576:	cd01                	beqz	a0,8000358e <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003578:	4585                	li	a1,1
    8000357a:	8526                	mv	a0,s1
    8000357c:	00003097          	auipc	ra,0x3
    80003580:	f98080e7          	jalr	-104(ra) # 80006514 <virtio_disk_rw>
}
    80003584:	60e2                	ld	ra,24(sp)
    80003586:	6442                	ld	s0,16(sp)
    80003588:	64a2                	ld	s1,8(sp)
    8000358a:	6105                	addi	sp,sp,32
    8000358c:	8082                	ret
    panic("bwrite");
    8000358e:	00005517          	auipc	a0,0x5
    80003592:	fda50513          	addi	a0,a0,-38 # 80008568 <syscalls+0x120>
    80003596:	ffffd097          	auipc	ra,0xffffd
    8000359a:	fa2080e7          	jalr	-94(ra) # 80000538 <panic>

000000008000359e <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000359e:	1101                	addi	sp,sp,-32
    800035a0:	ec06                	sd	ra,24(sp)
    800035a2:	e822                	sd	s0,16(sp)
    800035a4:	e426                	sd	s1,8(sp)
    800035a6:	e04a                	sd	s2,0(sp)
    800035a8:	1000                	addi	s0,sp,32
    800035aa:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800035ac:	01050913          	addi	s2,a0,16
    800035b0:	854a                	mv	a0,s2
    800035b2:	00001097          	auipc	ra,0x1
    800035b6:	436080e7          	jalr	1078(ra) # 800049e8 <holdingsleep>
    800035ba:	c92d                	beqz	a0,8000362c <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800035bc:	854a                	mv	a0,s2
    800035be:	00001097          	auipc	ra,0x1
    800035c2:	3e6080e7          	jalr	998(ra) # 800049a4 <releasesleep>

  acquire(&bcache.lock);
    800035c6:	00015517          	auipc	a0,0x15
    800035ca:	b1a50513          	addi	a0,a0,-1254 # 800180e0 <bcache>
    800035ce:	ffffd097          	auipc	ra,0xffffd
    800035d2:	602080e7          	jalr	1538(ra) # 80000bd0 <acquire>
  b->refcnt--;
    800035d6:	40bc                	lw	a5,64(s1)
    800035d8:	37fd                	addiw	a5,a5,-1
    800035da:	0007871b          	sext.w	a4,a5
    800035de:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800035e0:	eb05                	bnez	a4,80003610 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800035e2:	68bc                	ld	a5,80(s1)
    800035e4:	64b8                	ld	a4,72(s1)
    800035e6:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800035e8:	64bc                	ld	a5,72(s1)
    800035ea:	68b8                	ld	a4,80(s1)
    800035ec:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800035ee:	0001d797          	auipc	a5,0x1d
    800035f2:	af278793          	addi	a5,a5,-1294 # 800200e0 <bcache+0x8000>
    800035f6:	2b87b703          	ld	a4,696(a5)
    800035fa:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800035fc:	0001d717          	auipc	a4,0x1d
    80003600:	d4c70713          	addi	a4,a4,-692 # 80020348 <bcache+0x8268>
    80003604:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003606:	2b87b703          	ld	a4,696(a5)
    8000360a:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000360c:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003610:	00015517          	auipc	a0,0x15
    80003614:	ad050513          	addi	a0,a0,-1328 # 800180e0 <bcache>
    80003618:	ffffd097          	auipc	ra,0xffffd
    8000361c:	66c080e7          	jalr	1644(ra) # 80000c84 <release>
}
    80003620:	60e2                	ld	ra,24(sp)
    80003622:	6442                	ld	s0,16(sp)
    80003624:	64a2                	ld	s1,8(sp)
    80003626:	6902                	ld	s2,0(sp)
    80003628:	6105                	addi	sp,sp,32
    8000362a:	8082                	ret
    panic("brelse");
    8000362c:	00005517          	auipc	a0,0x5
    80003630:	f4450513          	addi	a0,a0,-188 # 80008570 <syscalls+0x128>
    80003634:	ffffd097          	auipc	ra,0xffffd
    80003638:	f04080e7          	jalr	-252(ra) # 80000538 <panic>

000000008000363c <bpin>:

void
bpin(struct buf *b) {
    8000363c:	1101                	addi	sp,sp,-32
    8000363e:	ec06                	sd	ra,24(sp)
    80003640:	e822                	sd	s0,16(sp)
    80003642:	e426                	sd	s1,8(sp)
    80003644:	1000                	addi	s0,sp,32
    80003646:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003648:	00015517          	auipc	a0,0x15
    8000364c:	a9850513          	addi	a0,a0,-1384 # 800180e0 <bcache>
    80003650:	ffffd097          	auipc	ra,0xffffd
    80003654:	580080e7          	jalr	1408(ra) # 80000bd0 <acquire>
  b->refcnt++;
    80003658:	40bc                	lw	a5,64(s1)
    8000365a:	2785                	addiw	a5,a5,1
    8000365c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000365e:	00015517          	auipc	a0,0x15
    80003662:	a8250513          	addi	a0,a0,-1406 # 800180e0 <bcache>
    80003666:	ffffd097          	auipc	ra,0xffffd
    8000366a:	61e080e7          	jalr	1566(ra) # 80000c84 <release>
}
    8000366e:	60e2                	ld	ra,24(sp)
    80003670:	6442                	ld	s0,16(sp)
    80003672:	64a2                	ld	s1,8(sp)
    80003674:	6105                	addi	sp,sp,32
    80003676:	8082                	ret

0000000080003678 <bunpin>:

void
bunpin(struct buf *b) {
    80003678:	1101                	addi	sp,sp,-32
    8000367a:	ec06                	sd	ra,24(sp)
    8000367c:	e822                	sd	s0,16(sp)
    8000367e:	e426                	sd	s1,8(sp)
    80003680:	1000                	addi	s0,sp,32
    80003682:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003684:	00015517          	auipc	a0,0x15
    80003688:	a5c50513          	addi	a0,a0,-1444 # 800180e0 <bcache>
    8000368c:	ffffd097          	auipc	ra,0xffffd
    80003690:	544080e7          	jalr	1348(ra) # 80000bd0 <acquire>
  b->refcnt--;
    80003694:	40bc                	lw	a5,64(s1)
    80003696:	37fd                	addiw	a5,a5,-1
    80003698:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000369a:	00015517          	auipc	a0,0x15
    8000369e:	a4650513          	addi	a0,a0,-1466 # 800180e0 <bcache>
    800036a2:	ffffd097          	auipc	ra,0xffffd
    800036a6:	5e2080e7          	jalr	1506(ra) # 80000c84 <release>
}
    800036aa:	60e2                	ld	ra,24(sp)
    800036ac:	6442                	ld	s0,16(sp)
    800036ae:	64a2                	ld	s1,8(sp)
    800036b0:	6105                	addi	sp,sp,32
    800036b2:	8082                	ret

00000000800036b4 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800036b4:	1101                	addi	sp,sp,-32
    800036b6:	ec06                	sd	ra,24(sp)
    800036b8:	e822                	sd	s0,16(sp)
    800036ba:	e426                	sd	s1,8(sp)
    800036bc:	e04a                	sd	s2,0(sp)
    800036be:	1000                	addi	s0,sp,32
    800036c0:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800036c2:	00d5d59b          	srliw	a1,a1,0xd
    800036c6:	0001d797          	auipc	a5,0x1d
    800036ca:	0f67a783          	lw	a5,246(a5) # 800207bc <sb+0x1c>
    800036ce:	9dbd                	addw	a1,a1,a5
    800036d0:	00000097          	auipc	ra,0x0
    800036d4:	d9e080e7          	jalr	-610(ra) # 8000346e <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800036d8:	0074f713          	andi	a4,s1,7
    800036dc:	4785                	li	a5,1
    800036de:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800036e2:	14ce                	slli	s1,s1,0x33
    800036e4:	90d9                	srli	s1,s1,0x36
    800036e6:	00950733          	add	a4,a0,s1
    800036ea:	05874703          	lbu	a4,88(a4)
    800036ee:	00e7f6b3          	and	a3,a5,a4
    800036f2:	c69d                	beqz	a3,80003720 <bfree+0x6c>
    800036f4:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800036f6:	94aa                	add	s1,s1,a0
    800036f8:	fff7c793          	not	a5,a5
    800036fc:	8ff9                	and	a5,a5,a4
    800036fe:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003702:	00001097          	auipc	ra,0x1
    80003706:	12c080e7          	jalr	300(ra) # 8000482e <log_write>
  brelse(bp);
    8000370a:	854a                	mv	a0,s2
    8000370c:	00000097          	auipc	ra,0x0
    80003710:	e92080e7          	jalr	-366(ra) # 8000359e <brelse>
}
    80003714:	60e2                	ld	ra,24(sp)
    80003716:	6442                	ld	s0,16(sp)
    80003718:	64a2                	ld	s1,8(sp)
    8000371a:	6902                	ld	s2,0(sp)
    8000371c:	6105                	addi	sp,sp,32
    8000371e:	8082                	ret
    panic("freeing free block");
    80003720:	00005517          	auipc	a0,0x5
    80003724:	e5850513          	addi	a0,a0,-424 # 80008578 <syscalls+0x130>
    80003728:	ffffd097          	auipc	ra,0xffffd
    8000372c:	e10080e7          	jalr	-496(ra) # 80000538 <panic>

0000000080003730 <iget>:
// Find the inode with number inum on device dev
// and return the in-memory copy. Does not lock
// the inode and does not read it from disk.
static struct inode*
iget(uint dev, uint inum)
{
    80003730:	7179                	addi	sp,sp,-48
    80003732:	f406                	sd	ra,40(sp)
    80003734:	f022                	sd	s0,32(sp)
    80003736:	ec26                	sd	s1,24(sp)
    80003738:	e84a                	sd	s2,16(sp)
    8000373a:	e44e                	sd	s3,8(sp)
    8000373c:	e052                	sd	s4,0(sp)
    8000373e:	1800                	addi	s0,sp,48
    80003740:	89aa                	mv	s3,a0
    80003742:	8a2e                	mv	s4,a1
  struct inode *ip, *empty;

  acquire(&itable.lock);
    80003744:	0001d517          	auipc	a0,0x1d
    80003748:	07c50513          	addi	a0,a0,124 # 800207c0 <itable>
    8000374c:	ffffd097          	auipc	ra,0xffffd
    80003750:	484080e7          	jalr	1156(ra) # 80000bd0 <acquire>

  // Is the inode already in the table?
  empty = 0;
    80003754:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003756:	0001d497          	auipc	s1,0x1d
    8000375a:	08248493          	addi	s1,s1,130 # 800207d8 <itable+0x18>
    8000375e:	0001f697          	auipc	a3,0x1f
    80003762:	b0a68693          	addi	a3,a3,-1270 # 80022268 <log>
    80003766:	a039                	j	80003774 <iget+0x44>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
      ip->ref++;
      release(&itable.lock);
      return ip;
    }
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003768:	02090b63          	beqz	s2,8000379e <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000376c:	08848493          	addi	s1,s1,136
    80003770:	02d48a63          	beq	s1,a3,800037a4 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003774:	449c                	lw	a5,8(s1)
    80003776:	fef059e3          	blez	a5,80003768 <iget+0x38>
    8000377a:	4098                	lw	a4,0(s1)
    8000377c:	ff3716e3          	bne	a4,s3,80003768 <iget+0x38>
    80003780:	40d8                	lw	a4,4(s1)
    80003782:	ff4713e3          	bne	a4,s4,80003768 <iget+0x38>
      ip->ref++;
    80003786:	2785                	addiw	a5,a5,1
    80003788:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000378a:	0001d517          	auipc	a0,0x1d
    8000378e:	03650513          	addi	a0,a0,54 # 800207c0 <itable>
    80003792:	ffffd097          	auipc	ra,0xffffd
    80003796:	4f2080e7          	jalr	1266(ra) # 80000c84 <release>
      return ip;
    8000379a:	8926                	mv	s2,s1
    8000379c:	a03d                	j	800037ca <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000379e:	f7f9                	bnez	a5,8000376c <iget+0x3c>
    800037a0:	8926                	mv	s2,s1
    800037a2:	b7e9                	j	8000376c <iget+0x3c>
      empty = ip;
  }

  // Recycle an inode entry.
  if(empty == 0)
    800037a4:	02090c63          	beqz	s2,800037dc <iget+0xac>
    panic("iget: no inodes");

  ip = empty;
  ip->dev = dev;
    800037a8:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800037ac:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800037b0:	4785                	li	a5,1
    800037b2:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800037b6:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800037ba:	0001d517          	auipc	a0,0x1d
    800037be:	00650513          	addi	a0,a0,6 # 800207c0 <itable>
    800037c2:	ffffd097          	auipc	ra,0xffffd
    800037c6:	4c2080e7          	jalr	1218(ra) # 80000c84 <release>

  return ip;
}
    800037ca:	854a                	mv	a0,s2
    800037cc:	70a2                	ld	ra,40(sp)
    800037ce:	7402                	ld	s0,32(sp)
    800037d0:	64e2                	ld	s1,24(sp)
    800037d2:	6942                	ld	s2,16(sp)
    800037d4:	69a2                	ld	s3,8(sp)
    800037d6:	6a02                	ld	s4,0(sp)
    800037d8:	6145                	addi	sp,sp,48
    800037da:	8082                	ret
    panic("iget: no inodes");
    800037dc:	00005517          	auipc	a0,0x5
    800037e0:	db450513          	addi	a0,a0,-588 # 80008590 <syscalls+0x148>
    800037e4:	ffffd097          	auipc	ra,0xffffd
    800037e8:	d54080e7          	jalr	-684(ra) # 80000538 <panic>

00000000800037ec <balloc>:
{
    800037ec:	711d                	addi	sp,sp,-96
    800037ee:	ec86                	sd	ra,88(sp)
    800037f0:	e8a2                	sd	s0,80(sp)
    800037f2:	e4a6                	sd	s1,72(sp)
    800037f4:	e0ca                	sd	s2,64(sp)
    800037f6:	fc4e                	sd	s3,56(sp)
    800037f8:	f852                	sd	s4,48(sp)
    800037fa:	f456                	sd	s5,40(sp)
    800037fc:	f05a                	sd	s6,32(sp)
    800037fe:	ec5e                	sd	s7,24(sp)
    80003800:	e862                	sd	s8,16(sp)
    80003802:	e466                	sd	s9,8(sp)
    80003804:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003806:	0001d797          	auipc	a5,0x1d
    8000380a:	f9e7a783          	lw	a5,-98(a5) # 800207a4 <sb+0x4>
    8000380e:	10078163          	beqz	a5,80003910 <balloc+0x124>
    80003812:	8baa                	mv	s7,a0
    80003814:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003816:	0001db17          	auipc	s6,0x1d
    8000381a:	f8ab0b13          	addi	s6,s6,-118 # 800207a0 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000381e:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003820:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003822:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003824:	6c89                	lui	s9,0x2
    80003826:	a061                	j	800038ae <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003828:	974a                	add	a4,a4,s2
    8000382a:	8fd5                	or	a5,a5,a3
    8000382c:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003830:	854a                	mv	a0,s2
    80003832:	00001097          	auipc	ra,0x1
    80003836:	ffc080e7          	jalr	-4(ra) # 8000482e <log_write>
        brelse(bp);
    8000383a:	854a                	mv	a0,s2
    8000383c:	00000097          	auipc	ra,0x0
    80003840:	d62080e7          	jalr	-670(ra) # 8000359e <brelse>
  bp = bread(dev, bno);
    80003844:	85a6                	mv	a1,s1
    80003846:	855e                	mv	a0,s7
    80003848:	00000097          	auipc	ra,0x0
    8000384c:	c26080e7          	jalr	-986(ra) # 8000346e <bread>
    80003850:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003852:	40000613          	li	a2,1024
    80003856:	4581                	li	a1,0
    80003858:	05850513          	addi	a0,a0,88
    8000385c:	ffffd097          	auipc	ra,0xffffd
    80003860:	470080e7          	jalr	1136(ra) # 80000ccc <memset>
  log_write(bp);
    80003864:	854a                	mv	a0,s2
    80003866:	00001097          	auipc	ra,0x1
    8000386a:	fc8080e7          	jalr	-56(ra) # 8000482e <log_write>
  brelse(bp);
    8000386e:	854a                	mv	a0,s2
    80003870:	00000097          	auipc	ra,0x0
    80003874:	d2e080e7          	jalr	-722(ra) # 8000359e <brelse>
}
    80003878:	8526                	mv	a0,s1
    8000387a:	60e6                	ld	ra,88(sp)
    8000387c:	6446                	ld	s0,80(sp)
    8000387e:	64a6                	ld	s1,72(sp)
    80003880:	6906                	ld	s2,64(sp)
    80003882:	79e2                	ld	s3,56(sp)
    80003884:	7a42                	ld	s4,48(sp)
    80003886:	7aa2                	ld	s5,40(sp)
    80003888:	7b02                	ld	s6,32(sp)
    8000388a:	6be2                	ld	s7,24(sp)
    8000388c:	6c42                	ld	s8,16(sp)
    8000388e:	6ca2                	ld	s9,8(sp)
    80003890:	6125                	addi	sp,sp,96
    80003892:	8082                	ret
    brelse(bp);
    80003894:	854a                	mv	a0,s2
    80003896:	00000097          	auipc	ra,0x0
    8000389a:	d08080e7          	jalr	-760(ra) # 8000359e <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000389e:	015c87bb          	addw	a5,s9,s5
    800038a2:	00078a9b          	sext.w	s5,a5
    800038a6:	004b2703          	lw	a4,4(s6)
    800038aa:	06eaf363          	bgeu	s5,a4,80003910 <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    800038ae:	41fad79b          	sraiw	a5,s5,0x1f
    800038b2:	0137d79b          	srliw	a5,a5,0x13
    800038b6:	015787bb          	addw	a5,a5,s5
    800038ba:	40d7d79b          	sraiw	a5,a5,0xd
    800038be:	01cb2583          	lw	a1,28(s6)
    800038c2:	9dbd                	addw	a1,a1,a5
    800038c4:	855e                	mv	a0,s7
    800038c6:	00000097          	auipc	ra,0x0
    800038ca:	ba8080e7          	jalr	-1112(ra) # 8000346e <bread>
    800038ce:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800038d0:	004b2503          	lw	a0,4(s6)
    800038d4:	000a849b          	sext.w	s1,s5
    800038d8:	8662                	mv	a2,s8
    800038da:	faa4fde3          	bgeu	s1,a0,80003894 <balloc+0xa8>
      m = 1 << (bi % 8);
    800038de:	41f6579b          	sraiw	a5,a2,0x1f
    800038e2:	01d7d69b          	srliw	a3,a5,0x1d
    800038e6:	00c6873b          	addw	a4,a3,a2
    800038ea:	00777793          	andi	a5,a4,7
    800038ee:	9f95                	subw	a5,a5,a3
    800038f0:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800038f4:	4037571b          	sraiw	a4,a4,0x3
    800038f8:	00e906b3          	add	a3,s2,a4
    800038fc:	0586c683          	lbu	a3,88(a3)
    80003900:	00d7f5b3          	and	a1,a5,a3
    80003904:	d195                	beqz	a1,80003828 <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003906:	2605                	addiw	a2,a2,1
    80003908:	2485                	addiw	s1,s1,1
    8000390a:	fd4618e3          	bne	a2,s4,800038da <balloc+0xee>
    8000390e:	b759                	j	80003894 <balloc+0xa8>
  printf("balloc: out of blocks\n");
    80003910:	00005517          	auipc	a0,0x5
    80003914:	c9050513          	addi	a0,a0,-880 # 800085a0 <syscalls+0x158>
    80003918:	ffffd097          	auipc	ra,0xffffd
    8000391c:	c6a080e7          	jalr	-918(ra) # 80000582 <printf>
  return 0;
    80003920:	4481                	li	s1,0
    80003922:	bf99                	j	80003878 <balloc+0x8c>

0000000080003924 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003924:	7179                	addi	sp,sp,-48
    80003926:	f406                	sd	ra,40(sp)
    80003928:	f022                	sd	s0,32(sp)
    8000392a:	ec26                	sd	s1,24(sp)
    8000392c:	e84a                	sd	s2,16(sp)
    8000392e:	e44e                	sd	s3,8(sp)
    80003930:	e052                	sd	s4,0(sp)
    80003932:	1800                	addi	s0,sp,48
    80003934:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003936:	47ad                	li	a5,11
    80003938:	02b7e763          	bltu	a5,a1,80003966 <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    8000393c:	02059493          	slli	s1,a1,0x20
    80003940:	9081                	srli	s1,s1,0x20
    80003942:	048a                	slli	s1,s1,0x2
    80003944:	94aa                	add	s1,s1,a0
    80003946:	0504a903          	lw	s2,80(s1)
    8000394a:	06091e63          	bnez	s2,800039c6 <bmap+0xa2>
      addr = balloc(ip->dev);
    8000394e:	4108                	lw	a0,0(a0)
    80003950:	00000097          	auipc	ra,0x0
    80003954:	e9c080e7          	jalr	-356(ra) # 800037ec <balloc>
    80003958:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000395c:	06090563          	beqz	s2,800039c6 <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    80003960:	0524a823          	sw	s2,80(s1)
    80003964:	a08d                	j	800039c6 <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003966:	ff45849b          	addiw	s1,a1,-12
    8000396a:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000396e:	0ff00793          	li	a5,255
    80003972:	08e7e563          	bltu	a5,a4,800039fc <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003976:	08052903          	lw	s2,128(a0)
    8000397a:	00091d63          	bnez	s2,80003994 <bmap+0x70>
      addr = balloc(ip->dev);
    8000397e:	4108                	lw	a0,0(a0)
    80003980:	00000097          	auipc	ra,0x0
    80003984:	e6c080e7          	jalr	-404(ra) # 800037ec <balloc>
    80003988:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000398c:	02090d63          	beqz	s2,800039c6 <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003990:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003994:	85ca                	mv	a1,s2
    80003996:	0009a503          	lw	a0,0(s3)
    8000399a:	00000097          	auipc	ra,0x0
    8000399e:	ad4080e7          	jalr	-1324(ra) # 8000346e <bread>
    800039a2:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800039a4:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800039a8:	02049593          	slli	a1,s1,0x20
    800039ac:	9181                	srli	a1,a1,0x20
    800039ae:	058a                	slli	a1,a1,0x2
    800039b0:	00b784b3          	add	s1,a5,a1
    800039b4:	0004a903          	lw	s2,0(s1)
    800039b8:	02090063          	beqz	s2,800039d8 <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    800039bc:	8552                	mv	a0,s4
    800039be:	00000097          	auipc	ra,0x0
    800039c2:	be0080e7          	jalr	-1056(ra) # 8000359e <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800039c6:	854a                	mv	a0,s2
    800039c8:	70a2                	ld	ra,40(sp)
    800039ca:	7402                	ld	s0,32(sp)
    800039cc:	64e2                	ld	s1,24(sp)
    800039ce:	6942                	ld	s2,16(sp)
    800039d0:	69a2                	ld	s3,8(sp)
    800039d2:	6a02                	ld	s4,0(sp)
    800039d4:	6145                	addi	sp,sp,48
    800039d6:	8082                	ret
      addr = balloc(ip->dev);
    800039d8:	0009a503          	lw	a0,0(s3)
    800039dc:	00000097          	auipc	ra,0x0
    800039e0:	e10080e7          	jalr	-496(ra) # 800037ec <balloc>
    800039e4:	0005091b          	sext.w	s2,a0
      if(addr){
    800039e8:	fc090ae3          	beqz	s2,800039bc <bmap+0x98>
        a[bn] = addr;
    800039ec:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    800039f0:	8552                	mv	a0,s4
    800039f2:	00001097          	auipc	ra,0x1
    800039f6:	e3c080e7          	jalr	-452(ra) # 8000482e <log_write>
    800039fa:	b7c9                	j	800039bc <bmap+0x98>
  panic("bmap: out of range");
    800039fc:	00005517          	auipc	a0,0x5
    80003a00:	bbc50513          	addi	a0,a0,-1092 # 800085b8 <syscalls+0x170>
    80003a04:	ffffd097          	auipc	ra,0xffffd
    80003a08:	b34080e7          	jalr	-1228(ra) # 80000538 <panic>

0000000080003a0c <fsinit>:
fsinit(int dev) {
    80003a0c:	7179                	addi	sp,sp,-48
    80003a0e:	f406                	sd	ra,40(sp)
    80003a10:	f022                	sd	s0,32(sp)
    80003a12:	ec26                	sd	s1,24(sp)
    80003a14:	e84a                	sd	s2,16(sp)
    80003a16:	e44e                	sd	s3,8(sp)
    80003a18:	1800                	addi	s0,sp,48
    80003a1a:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003a1c:	4585                	li	a1,1
    80003a1e:	00000097          	auipc	ra,0x0
    80003a22:	a50080e7          	jalr	-1456(ra) # 8000346e <bread>
    80003a26:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003a28:	0001d997          	auipc	s3,0x1d
    80003a2c:	d7898993          	addi	s3,s3,-648 # 800207a0 <sb>
    80003a30:	02000613          	li	a2,32
    80003a34:	05850593          	addi	a1,a0,88
    80003a38:	854e                	mv	a0,s3
    80003a3a:	ffffd097          	auipc	ra,0xffffd
    80003a3e:	2ee080e7          	jalr	750(ra) # 80000d28 <memmove>
  brelse(bp);
    80003a42:	8526                	mv	a0,s1
    80003a44:	00000097          	auipc	ra,0x0
    80003a48:	b5a080e7          	jalr	-1190(ra) # 8000359e <brelse>
  if(sb.magic != FSMAGIC)
    80003a4c:	0009a703          	lw	a4,0(s3)
    80003a50:	102037b7          	lui	a5,0x10203
    80003a54:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003a58:	02f71263          	bne	a4,a5,80003a7c <fsinit+0x70>
  initlog(dev, &sb);
    80003a5c:	0001d597          	auipc	a1,0x1d
    80003a60:	d4458593          	addi	a1,a1,-700 # 800207a0 <sb>
    80003a64:	854a                	mv	a0,s2
    80003a66:	00001097          	auipc	ra,0x1
    80003a6a:	b4c080e7          	jalr	-1204(ra) # 800045b2 <initlog>
}
    80003a6e:	70a2                	ld	ra,40(sp)
    80003a70:	7402                	ld	s0,32(sp)
    80003a72:	64e2                	ld	s1,24(sp)
    80003a74:	6942                	ld	s2,16(sp)
    80003a76:	69a2                	ld	s3,8(sp)
    80003a78:	6145                	addi	sp,sp,48
    80003a7a:	8082                	ret
    panic("invalid file system");
    80003a7c:	00005517          	auipc	a0,0x5
    80003a80:	b5450513          	addi	a0,a0,-1196 # 800085d0 <syscalls+0x188>
    80003a84:	ffffd097          	auipc	ra,0xffffd
    80003a88:	ab4080e7          	jalr	-1356(ra) # 80000538 <panic>

0000000080003a8c <iinit>:
{
    80003a8c:	7179                	addi	sp,sp,-48
    80003a8e:	f406                	sd	ra,40(sp)
    80003a90:	f022                	sd	s0,32(sp)
    80003a92:	ec26                	sd	s1,24(sp)
    80003a94:	e84a                	sd	s2,16(sp)
    80003a96:	e44e                	sd	s3,8(sp)
    80003a98:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003a9a:	00005597          	auipc	a1,0x5
    80003a9e:	b4e58593          	addi	a1,a1,-1202 # 800085e8 <syscalls+0x1a0>
    80003aa2:	0001d517          	auipc	a0,0x1d
    80003aa6:	d1e50513          	addi	a0,a0,-738 # 800207c0 <itable>
    80003aaa:	ffffd097          	auipc	ra,0xffffd
    80003aae:	096080e7          	jalr	150(ra) # 80000b40 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003ab2:	0001d497          	auipc	s1,0x1d
    80003ab6:	d3648493          	addi	s1,s1,-714 # 800207e8 <itable+0x28>
    80003aba:	0001e997          	auipc	s3,0x1e
    80003abe:	7be98993          	addi	s3,s3,1982 # 80022278 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003ac2:	00005917          	auipc	s2,0x5
    80003ac6:	b2e90913          	addi	s2,s2,-1234 # 800085f0 <syscalls+0x1a8>
    80003aca:	85ca                	mv	a1,s2
    80003acc:	8526                	mv	a0,s1
    80003ace:	00001097          	auipc	ra,0x1
    80003ad2:	e46080e7          	jalr	-442(ra) # 80004914 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003ad6:	08848493          	addi	s1,s1,136
    80003ada:	ff3498e3          	bne	s1,s3,80003aca <iinit+0x3e>
}
    80003ade:	70a2                	ld	ra,40(sp)
    80003ae0:	7402                	ld	s0,32(sp)
    80003ae2:	64e2                	ld	s1,24(sp)
    80003ae4:	6942                	ld	s2,16(sp)
    80003ae6:	69a2                	ld	s3,8(sp)
    80003ae8:	6145                	addi	sp,sp,48
    80003aea:	8082                	ret

0000000080003aec <ialloc>:
{
    80003aec:	715d                	addi	sp,sp,-80
    80003aee:	e486                	sd	ra,72(sp)
    80003af0:	e0a2                	sd	s0,64(sp)
    80003af2:	fc26                	sd	s1,56(sp)
    80003af4:	f84a                	sd	s2,48(sp)
    80003af6:	f44e                	sd	s3,40(sp)
    80003af8:	f052                	sd	s4,32(sp)
    80003afa:	ec56                	sd	s5,24(sp)
    80003afc:	e85a                	sd	s6,16(sp)
    80003afe:	e45e                	sd	s7,8(sp)
    80003b00:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003b02:	0001d717          	auipc	a4,0x1d
    80003b06:	caa72703          	lw	a4,-854(a4) # 800207ac <sb+0xc>
    80003b0a:	4785                	li	a5,1
    80003b0c:	04e7fa63          	bgeu	a5,a4,80003b60 <ialloc+0x74>
    80003b10:	8aaa                	mv	s5,a0
    80003b12:	8bae                	mv	s7,a1
    80003b14:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003b16:	0001da17          	auipc	s4,0x1d
    80003b1a:	c8aa0a13          	addi	s4,s4,-886 # 800207a0 <sb>
    80003b1e:	00048b1b          	sext.w	s6,s1
    80003b22:	0044d793          	srli	a5,s1,0x4
    80003b26:	018a2583          	lw	a1,24(s4)
    80003b2a:	9dbd                	addw	a1,a1,a5
    80003b2c:	8556                	mv	a0,s5
    80003b2e:	00000097          	auipc	ra,0x0
    80003b32:	940080e7          	jalr	-1728(ra) # 8000346e <bread>
    80003b36:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003b38:	05850993          	addi	s3,a0,88
    80003b3c:	00f4f793          	andi	a5,s1,15
    80003b40:	079a                	slli	a5,a5,0x6
    80003b42:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003b44:	00099783          	lh	a5,0(s3)
    80003b48:	c785                	beqz	a5,80003b70 <ialloc+0x84>
    brelse(bp);
    80003b4a:	00000097          	auipc	ra,0x0
    80003b4e:	a54080e7          	jalr	-1452(ra) # 8000359e <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003b52:	0485                	addi	s1,s1,1
    80003b54:	00ca2703          	lw	a4,12(s4)
    80003b58:	0004879b          	sext.w	a5,s1
    80003b5c:	fce7e1e3          	bltu	a5,a4,80003b1e <ialloc+0x32>
  panic("ialloc: no inodes");
    80003b60:	00005517          	auipc	a0,0x5
    80003b64:	a9850513          	addi	a0,a0,-1384 # 800085f8 <syscalls+0x1b0>
    80003b68:	ffffd097          	auipc	ra,0xffffd
    80003b6c:	9d0080e7          	jalr	-1584(ra) # 80000538 <panic>
      memset(dip, 0, sizeof(*dip));
    80003b70:	04000613          	li	a2,64
    80003b74:	4581                	li	a1,0
    80003b76:	854e                	mv	a0,s3
    80003b78:	ffffd097          	auipc	ra,0xffffd
    80003b7c:	154080e7          	jalr	340(ra) # 80000ccc <memset>
      dip->type = type;
    80003b80:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003b84:	854a                	mv	a0,s2
    80003b86:	00001097          	auipc	ra,0x1
    80003b8a:	ca8080e7          	jalr	-856(ra) # 8000482e <log_write>
      brelse(bp);
    80003b8e:	854a                	mv	a0,s2
    80003b90:	00000097          	auipc	ra,0x0
    80003b94:	a0e080e7          	jalr	-1522(ra) # 8000359e <brelse>
      return iget(dev, inum);
    80003b98:	85da                	mv	a1,s6
    80003b9a:	8556                	mv	a0,s5
    80003b9c:	00000097          	auipc	ra,0x0
    80003ba0:	b94080e7          	jalr	-1132(ra) # 80003730 <iget>
}
    80003ba4:	60a6                	ld	ra,72(sp)
    80003ba6:	6406                	ld	s0,64(sp)
    80003ba8:	74e2                	ld	s1,56(sp)
    80003baa:	7942                	ld	s2,48(sp)
    80003bac:	79a2                	ld	s3,40(sp)
    80003bae:	7a02                	ld	s4,32(sp)
    80003bb0:	6ae2                	ld	s5,24(sp)
    80003bb2:	6b42                	ld	s6,16(sp)
    80003bb4:	6ba2                	ld	s7,8(sp)
    80003bb6:	6161                	addi	sp,sp,80
    80003bb8:	8082                	ret

0000000080003bba <iupdate>:
{
    80003bba:	1101                	addi	sp,sp,-32
    80003bbc:	ec06                	sd	ra,24(sp)
    80003bbe:	e822                	sd	s0,16(sp)
    80003bc0:	e426                	sd	s1,8(sp)
    80003bc2:	e04a                	sd	s2,0(sp)
    80003bc4:	1000                	addi	s0,sp,32
    80003bc6:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003bc8:	415c                	lw	a5,4(a0)
    80003bca:	0047d79b          	srliw	a5,a5,0x4
    80003bce:	0001d597          	auipc	a1,0x1d
    80003bd2:	bea5a583          	lw	a1,-1046(a1) # 800207b8 <sb+0x18>
    80003bd6:	9dbd                	addw	a1,a1,a5
    80003bd8:	4108                	lw	a0,0(a0)
    80003bda:	00000097          	auipc	ra,0x0
    80003bde:	894080e7          	jalr	-1900(ra) # 8000346e <bread>
    80003be2:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003be4:	05850793          	addi	a5,a0,88
    80003be8:	40c8                	lw	a0,4(s1)
    80003bea:	893d                	andi	a0,a0,15
    80003bec:	051a                	slli	a0,a0,0x6
    80003bee:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003bf0:	04449703          	lh	a4,68(s1)
    80003bf4:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003bf8:	04649703          	lh	a4,70(s1)
    80003bfc:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003c00:	04849703          	lh	a4,72(s1)
    80003c04:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003c08:	04a49703          	lh	a4,74(s1)
    80003c0c:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003c10:	44f8                	lw	a4,76(s1)
    80003c12:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003c14:	03400613          	li	a2,52
    80003c18:	05048593          	addi	a1,s1,80
    80003c1c:	0531                	addi	a0,a0,12
    80003c1e:	ffffd097          	auipc	ra,0xffffd
    80003c22:	10a080e7          	jalr	266(ra) # 80000d28 <memmove>
  log_write(bp);
    80003c26:	854a                	mv	a0,s2
    80003c28:	00001097          	auipc	ra,0x1
    80003c2c:	c06080e7          	jalr	-1018(ra) # 8000482e <log_write>
  brelse(bp);
    80003c30:	854a                	mv	a0,s2
    80003c32:	00000097          	auipc	ra,0x0
    80003c36:	96c080e7          	jalr	-1684(ra) # 8000359e <brelse>
}
    80003c3a:	60e2                	ld	ra,24(sp)
    80003c3c:	6442                	ld	s0,16(sp)
    80003c3e:	64a2                	ld	s1,8(sp)
    80003c40:	6902                	ld	s2,0(sp)
    80003c42:	6105                	addi	sp,sp,32
    80003c44:	8082                	ret

0000000080003c46 <idup>:
{
    80003c46:	1101                	addi	sp,sp,-32
    80003c48:	ec06                	sd	ra,24(sp)
    80003c4a:	e822                	sd	s0,16(sp)
    80003c4c:	e426                	sd	s1,8(sp)
    80003c4e:	1000                	addi	s0,sp,32
    80003c50:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003c52:	0001d517          	auipc	a0,0x1d
    80003c56:	b6e50513          	addi	a0,a0,-1170 # 800207c0 <itable>
    80003c5a:	ffffd097          	auipc	ra,0xffffd
    80003c5e:	f76080e7          	jalr	-138(ra) # 80000bd0 <acquire>
  ip->ref++;
    80003c62:	449c                	lw	a5,8(s1)
    80003c64:	2785                	addiw	a5,a5,1
    80003c66:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003c68:	0001d517          	auipc	a0,0x1d
    80003c6c:	b5850513          	addi	a0,a0,-1192 # 800207c0 <itable>
    80003c70:	ffffd097          	auipc	ra,0xffffd
    80003c74:	014080e7          	jalr	20(ra) # 80000c84 <release>
}
    80003c78:	8526                	mv	a0,s1
    80003c7a:	60e2                	ld	ra,24(sp)
    80003c7c:	6442                	ld	s0,16(sp)
    80003c7e:	64a2                	ld	s1,8(sp)
    80003c80:	6105                	addi	sp,sp,32
    80003c82:	8082                	ret

0000000080003c84 <ilock>:
{
    80003c84:	1101                	addi	sp,sp,-32
    80003c86:	ec06                	sd	ra,24(sp)
    80003c88:	e822                	sd	s0,16(sp)
    80003c8a:	e426                	sd	s1,8(sp)
    80003c8c:	e04a                	sd	s2,0(sp)
    80003c8e:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003c90:	c115                	beqz	a0,80003cb4 <ilock+0x30>
    80003c92:	84aa                	mv	s1,a0
    80003c94:	451c                	lw	a5,8(a0)
    80003c96:	00f05f63          	blez	a5,80003cb4 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003c9a:	0541                	addi	a0,a0,16
    80003c9c:	00001097          	auipc	ra,0x1
    80003ca0:	cb2080e7          	jalr	-846(ra) # 8000494e <acquiresleep>
  if(ip->valid == 0){
    80003ca4:	40bc                	lw	a5,64(s1)
    80003ca6:	cf99                	beqz	a5,80003cc4 <ilock+0x40>
}
    80003ca8:	60e2                	ld	ra,24(sp)
    80003caa:	6442                	ld	s0,16(sp)
    80003cac:	64a2                	ld	s1,8(sp)
    80003cae:	6902                	ld	s2,0(sp)
    80003cb0:	6105                	addi	sp,sp,32
    80003cb2:	8082                	ret
    panic("ilock");
    80003cb4:	00005517          	auipc	a0,0x5
    80003cb8:	95c50513          	addi	a0,a0,-1700 # 80008610 <syscalls+0x1c8>
    80003cbc:	ffffd097          	auipc	ra,0xffffd
    80003cc0:	87c080e7          	jalr	-1924(ra) # 80000538 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003cc4:	40dc                	lw	a5,4(s1)
    80003cc6:	0047d79b          	srliw	a5,a5,0x4
    80003cca:	0001d597          	auipc	a1,0x1d
    80003cce:	aee5a583          	lw	a1,-1298(a1) # 800207b8 <sb+0x18>
    80003cd2:	9dbd                	addw	a1,a1,a5
    80003cd4:	4088                	lw	a0,0(s1)
    80003cd6:	fffff097          	auipc	ra,0xfffff
    80003cda:	798080e7          	jalr	1944(ra) # 8000346e <bread>
    80003cde:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003ce0:	05850593          	addi	a1,a0,88
    80003ce4:	40dc                	lw	a5,4(s1)
    80003ce6:	8bbd                	andi	a5,a5,15
    80003ce8:	079a                	slli	a5,a5,0x6
    80003cea:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003cec:	00059783          	lh	a5,0(a1)
    80003cf0:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003cf4:	00259783          	lh	a5,2(a1)
    80003cf8:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003cfc:	00459783          	lh	a5,4(a1)
    80003d00:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003d04:	00659783          	lh	a5,6(a1)
    80003d08:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003d0c:	459c                	lw	a5,8(a1)
    80003d0e:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003d10:	03400613          	li	a2,52
    80003d14:	05b1                	addi	a1,a1,12
    80003d16:	05048513          	addi	a0,s1,80
    80003d1a:	ffffd097          	auipc	ra,0xffffd
    80003d1e:	00e080e7          	jalr	14(ra) # 80000d28 <memmove>
    brelse(bp);
    80003d22:	854a                	mv	a0,s2
    80003d24:	00000097          	auipc	ra,0x0
    80003d28:	87a080e7          	jalr	-1926(ra) # 8000359e <brelse>
    ip->valid = 1;
    80003d2c:	4785                	li	a5,1
    80003d2e:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003d30:	04449783          	lh	a5,68(s1)
    80003d34:	fbb5                	bnez	a5,80003ca8 <ilock+0x24>
      panic("ilock: no type");
    80003d36:	00005517          	auipc	a0,0x5
    80003d3a:	8e250513          	addi	a0,a0,-1822 # 80008618 <syscalls+0x1d0>
    80003d3e:	ffffc097          	auipc	ra,0xffffc
    80003d42:	7fa080e7          	jalr	2042(ra) # 80000538 <panic>

0000000080003d46 <iunlock>:
{
    80003d46:	1101                	addi	sp,sp,-32
    80003d48:	ec06                	sd	ra,24(sp)
    80003d4a:	e822                	sd	s0,16(sp)
    80003d4c:	e426                	sd	s1,8(sp)
    80003d4e:	e04a                	sd	s2,0(sp)
    80003d50:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003d52:	c905                	beqz	a0,80003d82 <iunlock+0x3c>
    80003d54:	84aa                	mv	s1,a0
    80003d56:	01050913          	addi	s2,a0,16
    80003d5a:	854a                	mv	a0,s2
    80003d5c:	00001097          	auipc	ra,0x1
    80003d60:	c8c080e7          	jalr	-884(ra) # 800049e8 <holdingsleep>
    80003d64:	cd19                	beqz	a0,80003d82 <iunlock+0x3c>
    80003d66:	449c                	lw	a5,8(s1)
    80003d68:	00f05d63          	blez	a5,80003d82 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003d6c:	854a                	mv	a0,s2
    80003d6e:	00001097          	auipc	ra,0x1
    80003d72:	c36080e7          	jalr	-970(ra) # 800049a4 <releasesleep>
}
    80003d76:	60e2                	ld	ra,24(sp)
    80003d78:	6442                	ld	s0,16(sp)
    80003d7a:	64a2                	ld	s1,8(sp)
    80003d7c:	6902                	ld	s2,0(sp)
    80003d7e:	6105                	addi	sp,sp,32
    80003d80:	8082                	ret
    panic("iunlock");
    80003d82:	00005517          	auipc	a0,0x5
    80003d86:	8a650513          	addi	a0,a0,-1882 # 80008628 <syscalls+0x1e0>
    80003d8a:	ffffc097          	auipc	ra,0xffffc
    80003d8e:	7ae080e7          	jalr	1966(ra) # 80000538 <panic>

0000000080003d92 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003d92:	7179                	addi	sp,sp,-48
    80003d94:	f406                	sd	ra,40(sp)
    80003d96:	f022                	sd	s0,32(sp)
    80003d98:	ec26                	sd	s1,24(sp)
    80003d9a:	e84a                	sd	s2,16(sp)
    80003d9c:	e44e                	sd	s3,8(sp)
    80003d9e:	e052                	sd	s4,0(sp)
    80003da0:	1800                	addi	s0,sp,48
    80003da2:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003da4:	05050493          	addi	s1,a0,80
    80003da8:	08050913          	addi	s2,a0,128
    80003dac:	a021                	j	80003db4 <itrunc+0x22>
    80003dae:	0491                	addi	s1,s1,4
    80003db0:	01248d63          	beq	s1,s2,80003dca <itrunc+0x38>
    if(ip->addrs[i]){
    80003db4:	408c                	lw	a1,0(s1)
    80003db6:	dde5                	beqz	a1,80003dae <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003db8:	0009a503          	lw	a0,0(s3)
    80003dbc:	00000097          	auipc	ra,0x0
    80003dc0:	8f8080e7          	jalr	-1800(ra) # 800036b4 <bfree>
      ip->addrs[i] = 0;
    80003dc4:	0004a023          	sw	zero,0(s1)
    80003dc8:	b7dd                	j	80003dae <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003dca:	0809a583          	lw	a1,128(s3)
    80003dce:	e185                	bnez	a1,80003dee <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003dd0:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003dd4:	854e                	mv	a0,s3
    80003dd6:	00000097          	auipc	ra,0x0
    80003dda:	de4080e7          	jalr	-540(ra) # 80003bba <iupdate>
}
    80003dde:	70a2                	ld	ra,40(sp)
    80003de0:	7402                	ld	s0,32(sp)
    80003de2:	64e2                	ld	s1,24(sp)
    80003de4:	6942                	ld	s2,16(sp)
    80003de6:	69a2                	ld	s3,8(sp)
    80003de8:	6a02                	ld	s4,0(sp)
    80003dea:	6145                	addi	sp,sp,48
    80003dec:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003dee:	0009a503          	lw	a0,0(s3)
    80003df2:	fffff097          	auipc	ra,0xfffff
    80003df6:	67c080e7          	jalr	1660(ra) # 8000346e <bread>
    80003dfa:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003dfc:	05850493          	addi	s1,a0,88
    80003e00:	45850913          	addi	s2,a0,1112
    80003e04:	a021                	j	80003e0c <itrunc+0x7a>
    80003e06:	0491                	addi	s1,s1,4
    80003e08:	01248b63          	beq	s1,s2,80003e1e <itrunc+0x8c>
      if(a[j])
    80003e0c:	408c                	lw	a1,0(s1)
    80003e0e:	dde5                	beqz	a1,80003e06 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003e10:	0009a503          	lw	a0,0(s3)
    80003e14:	00000097          	auipc	ra,0x0
    80003e18:	8a0080e7          	jalr	-1888(ra) # 800036b4 <bfree>
    80003e1c:	b7ed                	j	80003e06 <itrunc+0x74>
    brelse(bp);
    80003e1e:	8552                	mv	a0,s4
    80003e20:	fffff097          	auipc	ra,0xfffff
    80003e24:	77e080e7          	jalr	1918(ra) # 8000359e <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003e28:	0809a583          	lw	a1,128(s3)
    80003e2c:	0009a503          	lw	a0,0(s3)
    80003e30:	00000097          	auipc	ra,0x0
    80003e34:	884080e7          	jalr	-1916(ra) # 800036b4 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003e38:	0809a023          	sw	zero,128(s3)
    80003e3c:	bf51                	j	80003dd0 <itrunc+0x3e>

0000000080003e3e <iput>:
{
    80003e3e:	1101                	addi	sp,sp,-32
    80003e40:	ec06                	sd	ra,24(sp)
    80003e42:	e822                	sd	s0,16(sp)
    80003e44:	e426                	sd	s1,8(sp)
    80003e46:	e04a                	sd	s2,0(sp)
    80003e48:	1000                	addi	s0,sp,32
    80003e4a:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003e4c:	0001d517          	auipc	a0,0x1d
    80003e50:	97450513          	addi	a0,a0,-1676 # 800207c0 <itable>
    80003e54:	ffffd097          	auipc	ra,0xffffd
    80003e58:	d7c080e7          	jalr	-644(ra) # 80000bd0 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003e5c:	4498                	lw	a4,8(s1)
    80003e5e:	4785                	li	a5,1
    80003e60:	02f70363          	beq	a4,a5,80003e86 <iput+0x48>
  ip->ref--;
    80003e64:	449c                	lw	a5,8(s1)
    80003e66:	37fd                	addiw	a5,a5,-1
    80003e68:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003e6a:	0001d517          	auipc	a0,0x1d
    80003e6e:	95650513          	addi	a0,a0,-1706 # 800207c0 <itable>
    80003e72:	ffffd097          	auipc	ra,0xffffd
    80003e76:	e12080e7          	jalr	-494(ra) # 80000c84 <release>
}
    80003e7a:	60e2                	ld	ra,24(sp)
    80003e7c:	6442                	ld	s0,16(sp)
    80003e7e:	64a2                	ld	s1,8(sp)
    80003e80:	6902                	ld	s2,0(sp)
    80003e82:	6105                	addi	sp,sp,32
    80003e84:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003e86:	40bc                	lw	a5,64(s1)
    80003e88:	dff1                	beqz	a5,80003e64 <iput+0x26>
    80003e8a:	04a49783          	lh	a5,74(s1)
    80003e8e:	fbf9                	bnez	a5,80003e64 <iput+0x26>
    acquiresleep(&ip->lock);
    80003e90:	01048913          	addi	s2,s1,16
    80003e94:	854a                	mv	a0,s2
    80003e96:	00001097          	auipc	ra,0x1
    80003e9a:	ab8080e7          	jalr	-1352(ra) # 8000494e <acquiresleep>
    release(&itable.lock);
    80003e9e:	0001d517          	auipc	a0,0x1d
    80003ea2:	92250513          	addi	a0,a0,-1758 # 800207c0 <itable>
    80003ea6:	ffffd097          	auipc	ra,0xffffd
    80003eaa:	dde080e7          	jalr	-546(ra) # 80000c84 <release>
    itrunc(ip);
    80003eae:	8526                	mv	a0,s1
    80003eb0:	00000097          	auipc	ra,0x0
    80003eb4:	ee2080e7          	jalr	-286(ra) # 80003d92 <itrunc>
    ip->type = 0;
    80003eb8:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003ebc:	8526                	mv	a0,s1
    80003ebe:	00000097          	auipc	ra,0x0
    80003ec2:	cfc080e7          	jalr	-772(ra) # 80003bba <iupdate>
    ip->valid = 0;
    80003ec6:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003eca:	854a                	mv	a0,s2
    80003ecc:	00001097          	auipc	ra,0x1
    80003ed0:	ad8080e7          	jalr	-1320(ra) # 800049a4 <releasesleep>
    acquire(&itable.lock);
    80003ed4:	0001d517          	auipc	a0,0x1d
    80003ed8:	8ec50513          	addi	a0,a0,-1812 # 800207c0 <itable>
    80003edc:	ffffd097          	auipc	ra,0xffffd
    80003ee0:	cf4080e7          	jalr	-780(ra) # 80000bd0 <acquire>
    80003ee4:	b741                	j	80003e64 <iput+0x26>

0000000080003ee6 <iunlockput>:
{
    80003ee6:	1101                	addi	sp,sp,-32
    80003ee8:	ec06                	sd	ra,24(sp)
    80003eea:	e822                	sd	s0,16(sp)
    80003eec:	e426                	sd	s1,8(sp)
    80003eee:	1000                	addi	s0,sp,32
    80003ef0:	84aa                	mv	s1,a0
  iunlock(ip);
    80003ef2:	00000097          	auipc	ra,0x0
    80003ef6:	e54080e7          	jalr	-428(ra) # 80003d46 <iunlock>
  iput(ip);
    80003efa:	8526                	mv	a0,s1
    80003efc:	00000097          	auipc	ra,0x0
    80003f00:	f42080e7          	jalr	-190(ra) # 80003e3e <iput>
}
    80003f04:	60e2                	ld	ra,24(sp)
    80003f06:	6442                	ld	s0,16(sp)
    80003f08:	64a2                	ld	s1,8(sp)
    80003f0a:	6105                	addi	sp,sp,32
    80003f0c:	8082                	ret

0000000080003f0e <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003f0e:	1141                	addi	sp,sp,-16
    80003f10:	e422                	sd	s0,8(sp)
    80003f12:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003f14:	411c                	lw	a5,0(a0)
    80003f16:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003f18:	415c                	lw	a5,4(a0)
    80003f1a:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003f1c:	04451783          	lh	a5,68(a0)
    80003f20:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003f24:	04a51783          	lh	a5,74(a0)
    80003f28:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003f2c:	04c56783          	lwu	a5,76(a0)
    80003f30:	e99c                	sd	a5,16(a1)
}
    80003f32:	6422                	ld	s0,8(sp)
    80003f34:	0141                	addi	sp,sp,16
    80003f36:	8082                	ret

0000000080003f38 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003f38:	457c                	lw	a5,76(a0)
    80003f3a:	0ed7e963          	bltu	a5,a3,8000402c <readi+0xf4>
{
    80003f3e:	7159                	addi	sp,sp,-112
    80003f40:	f486                	sd	ra,104(sp)
    80003f42:	f0a2                	sd	s0,96(sp)
    80003f44:	eca6                	sd	s1,88(sp)
    80003f46:	e8ca                	sd	s2,80(sp)
    80003f48:	e4ce                	sd	s3,72(sp)
    80003f4a:	e0d2                	sd	s4,64(sp)
    80003f4c:	fc56                	sd	s5,56(sp)
    80003f4e:	f85a                	sd	s6,48(sp)
    80003f50:	f45e                	sd	s7,40(sp)
    80003f52:	f062                	sd	s8,32(sp)
    80003f54:	ec66                	sd	s9,24(sp)
    80003f56:	e86a                	sd	s10,16(sp)
    80003f58:	e46e                	sd	s11,8(sp)
    80003f5a:	1880                	addi	s0,sp,112
    80003f5c:	8b2a                	mv	s6,a0
    80003f5e:	8bae                	mv	s7,a1
    80003f60:	8a32                	mv	s4,a2
    80003f62:	84b6                	mv	s1,a3
    80003f64:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003f66:	9f35                	addw	a4,a4,a3
    return 0;
    80003f68:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003f6a:	0ad76063          	bltu	a4,a3,8000400a <readi+0xd2>
  if(off + n > ip->size)
    80003f6e:	00e7f463          	bgeu	a5,a4,80003f76 <readi+0x3e>
    n = ip->size - off;
    80003f72:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f76:	0a0a8963          	beqz	s5,80004028 <readi+0xf0>
    80003f7a:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f7c:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003f80:	5c7d                	li	s8,-1
    80003f82:	a82d                	j	80003fbc <readi+0x84>
    80003f84:	020d1d93          	slli	s11,s10,0x20
    80003f88:	020ddd93          	srli	s11,s11,0x20
    80003f8c:	05890793          	addi	a5,s2,88
    80003f90:	86ee                	mv	a3,s11
    80003f92:	963e                	add	a2,a2,a5
    80003f94:	85d2                	mv	a1,s4
    80003f96:	855e                	mv	a0,s7
    80003f98:	ffffe097          	auipc	ra,0xffffe
    80003f9c:	71a080e7          	jalr	1818(ra) # 800026b2 <either_copyout>
    80003fa0:	05850d63          	beq	a0,s8,80003ffa <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003fa4:	854a                	mv	a0,s2
    80003fa6:	fffff097          	auipc	ra,0xfffff
    80003faa:	5f8080e7          	jalr	1528(ra) # 8000359e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003fae:	013d09bb          	addw	s3,s10,s3
    80003fb2:	009d04bb          	addw	s1,s10,s1
    80003fb6:	9a6e                	add	s4,s4,s11
    80003fb8:	0559f763          	bgeu	s3,s5,80004006 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003fbc:	00a4d59b          	srliw	a1,s1,0xa
    80003fc0:	855a                	mv	a0,s6
    80003fc2:	00000097          	auipc	ra,0x0
    80003fc6:	962080e7          	jalr	-1694(ra) # 80003924 <bmap>
    80003fca:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003fce:	cd85                	beqz	a1,80004006 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003fd0:	000b2503          	lw	a0,0(s6)
    80003fd4:	fffff097          	auipc	ra,0xfffff
    80003fd8:	49a080e7          	jalr	1178(ra) # 8000346e <bread>
    80003fdc:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003fde:	3ff4f613          	andi	a2,s1,1023
    80003fe2:	40cc87bb          	subw	a5,s9,a2
    80003fe6:	413a873b          	subw	a4,s5,s3
    80003fea:	8d3e                	mv	s10,a5
    80003fec:	2781                	sext.w	a5,a5
    80003fee:	0007069b          	sext.w	a3,a4
    80003ff2:	f8f6f9e3          	bgeu	a3,a5,80003f84 <readi+0x4c>
    80003ff6:	8d3a                	mv	s10,a4
    80003ff8:	b771                	j	80003f84 <readi+0x4c>
      brelse(bp);
    80003ffa:	854a                	mv	a0,s2
    80003ffc:	fffff097          	auipc	ra,0xfffff
    80004000:	5a2080e7          	jalr	1442(ra) # 8000359e <brelse>
      tot = -1;
    80004004:	59fd                	li	s3,-1
  }
  return tot;
    80004006:	0009851b          	sext.w	a0,s3
}
    8000400a:	70a6                	ld	ra,104(sp)
    8000400c:	7406                	ld	s0,96(sp)
    8000400e:	64e6                	ld	s1,88(sp)
    80004010:	6946                	ld	s2,80(sp)
    80004012:	69a6                	ld	s3,72(sp)
    80004014:	6a06                	ld	s4,64(sp)
    80004016:	7ae2                	ld	s5,56(sp)
    80004018:	7b42                	ld	s6,48(sp)
    8000401a:	7ba2                	ld	s7,40(sp)
    8000401c:	7c02                	ld	s8,32(sp)
    8000401e:	6ce2                	ld	s9,24(sp)
    80004020:	6d42                	ld	s10,16(sp)
    80004022:	6da2                	ld	s11,8(sp)
    80004024:	6165                	addi	sp,sp,112
    80004026:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004028:	89d6                	mv	s3,s5
    8000402a:	bff1                	j	80004006 <readi+0xce>
    return 0;
    8000402c:	4501                	li	a0,0
}
    8000402e:	8082                	ret

0000000080004030 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004030:	457c                	lw	a5,76(a0)
    80004032:	10d7e863          	bltu	a5,a3,80004142 <writei+0x112>
{
    80004036:	7159                	addi	sp,sp,-112
    80004038:	f486                	sd	ra,104(sp)
    8000403a:	f0a2                	sd	s0,96(sp)
    8000403c:	eca6                	sd	s1,88(sp)
    8000403e:	e8ca                	sd	s2,80(sp)
    80004040:	e4ce                	sd	s3,72(sp)
    80004042:	e0d2                	sd	s4,64(sp)
    80004044:	fc56                	sd	s5,56(sp)
    80004046:	f85a                	sd	s6,48(sp)
    80004048:	f45e                	sd	s7,40(sp)
    8000404a:	f062                	sd	s8,32(sp)
    8000404c:	ec66                	sd	s9,24(sp)
    8000404e:	e86a                	sd	s10,16(sp)
    80004050:	e46e                	sd	s11,8(sp)
    80004052:	1880                	addi	s0,sp,112
    80004054:	8aaa                	mv	s5,a0
    80004056:	8bae                	mv	s7,a1
    80004058:	8a32                	mv	s4,a2
    8000405a:	8936                	mv	s2,a3
    8000405c:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    8000405e:	00e687bb          	addw	a5,a3,a4
    80004062:	0ed7e263          	bltu	a5,a3,80004146 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80004066:	00043737          	lui	a4,0x43
    8000406a:	0ef76063          	bltu	a4,a5,8000414a <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000406e:	0c0b0863          	beqz	s6,8000413e <writei+0x10e>
    80004072:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80004074:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80004078:	5c7d                	li	s8,-1
    8000407a:	a091                	j	800040be <writei+0x8e>
    8000407c:	020d1d93          	slli	s11,s10,0x20
    80004080:	020ddd93          	srli	s11,s11,0x20
    80004084:	05848793          	addi	a5,s1,88
    80004088:	86ee                	mv	a3,s11
    8000408a:	8652                	mv	a2,s4
    8000408c:	85de                	mv	a1,s7
    8000408e:	953e                	add	a0,a0,a5
    80004090:	ffffe097          	auipc	ra,0xffffe
    80004094:	678080e7          	jalr	1656(ra) # 80002708 <either_copyin>
    80004098:	07850263          	beq	a0,s8,800040fc <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    8000409c:	8526                	mv	a0,s1
    8000409e:	00000097          	auipc	ra,0x0
    800040a2:	790080e7          	jalr	1936(ra) # 8000482e <log_write>
    brelse(bp);
    800040a6:	8526                	mv	a0,s1
    800040a8:	fffff097          	auipc	ra,0xfffff
    800040ac:	4f6080e7          	jalr	1270(ra) # 8000359e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800040b0:	013d09bb          	addw	s3,s10,s3
    800040b4:	012d093b          	addw	s2,s10,s2
    800040b8:	9a6e                	add	s4,s4,s11
    800040ba:	0569f663          	bgeu	s3,s6,80004106 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    800040be:	00a9559b          	srliw	a1,s2,0xa
    800040c2:	8556                	mv	a0,s5
    800040c4:	00000097          	auipc	ra,0x0
    800040c8:	860080e7          	jalr	-1952(ra) # 80003924 <bmap>
    800040cc:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    800040d0:	c99d                	beqz	a1,80004106 <writei+0xd6>
    bp = bread(ip->dev, addr);
    800040d2:	000aa503          	lw	a0,0(s5)
    800040d6:	fffff097          	auipc	ra,0xfffff
    800040da:	398080e7          	jalr	920(ra) # 8000346e <bread>
    800040de:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800040e0:	3ff97513          	andi	a0,s2,1023
    800040e4:	40ac87bb          	subw	a5,s9,a0
    800040e8:	413b073b          	subw	a4,s6,s3
    800040ec:	8d3e                	mv	s10,a5
    800040ee:	2781                	sext.w	a5,a5
    800040f0:	0007069b          	sext.w	a3,a4
    800040f4:	f8f6f4e3          	bgeu	a3,a5,8000407c <writei+0x4c>
    800040f8:	8d3a                	mv	s10,a4
    800040fa:	b749                	j	8000407c <writei+0x4c>
      brelse(bp);
    800040fc:	8526                	mv	a0,s1
    800040fe:	fffff097          	auipc	ra,0xfffff
    80004102:	4a0080e7          	jalr	1184(ra) # 8000359e <brelse>
  }

  if(off > ip->size)
    80004106:	04caa783          	lw	a5,76(s5)
    8000410a:	0127f463          	bgeu	a5,s2,80004112 <writei+0xe2>
    ip->size = off;
    8000410e:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80004112:	8556                	mv	a0,s5
    80004114:	00000097          	auipc	ra,0x0
    80004118:	aa6080e7          	jalr	-1370(ra) # 80003bba <iupdate>

  return tot;
    8000411c:	0009851b          	sext.w	a0,s3
}
    80004120:	70a6                	ld	ra,104(sp)
    80004122:	7406                	ld	s0,96(sp)
    80004124:	64e6                	ld	s1,88(sp)
    80004126:	6946                	ld	s2,80(sp)
    80004128:	69a6                	ld	s3,72(sp)
    8000412a:	6a06                	ld	s4,64(sp)
    8000412c:	7ae2                	ld	s5,56(sp)
    8000412e:	7b42                	ld	s6,48(sp)
    80004130:	7ba2                	ld	s7,40(sp)
    80004132:	7c02                	ld	s8,32(sp)
    80004134:	6ce2                	ld	s9,24(sp)
    80004136:	6d42                	ld	s10,16(sp)
    80004138:	6da2                	ld	s11,8(sp)
    8000413a:	6165                	addi	sp,sp,112
    8000413c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000413e:	89da                	mv	s3,s6
    80004140:	bfc9                	j	80004112 <writei+0xe2>
    return -1;
    80004142:	557d                	li	a0,-1
}
    80004144:	8082                	ret
    return -1;
    80004146:	557d                	li	a0,-1
    80004148:	bfe1                	j	80004120 <writei+0xf0>
    return -1;
    8000414a:	557d                	li	a0,-1
    8000414c:	bfd1                	j	80004120 <writei+0xf0>

000000008000414e <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    8000414e:	1141                	addi	sp,sp,-16
    80004150:	e406                	sd	ra,8(sp)
    80004152:	e022                	sd	s0,0(sp)
    80004154:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004156:	4639                	li	a2,14
    80004158:	ffffd097          	auipc	ra,0xffffd
    8000415c:	c44080e7          	jalr	-956(ra) # 80000d9c <strncmp>
}
    80004160:	60a2                	ld	ra,8(sp)
    80004162:	6402                	ld	s0,0(sp)
    80004164:	0141                	addi	sp,sp,16
    80004166:	8082                	ret

0000000080004168 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004168:	7139                	addi	sp,sp,-64
    8000416a:	fc06                	sd	ra,56(sp)
    8000416c:	f822                	sd	s0,48(sp)
    8000416e:	f426                	sd	s1,40(sp)
    80004170:	f04a                	sd	s2,32(sp)
    80004172:	ec4e                	sd	s3,24(sp)
    80004174:	e852                	sd	s4,16(sp)
    80004176:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004178:	04451703          	lh	a4,68(a0)
    8000417c:	4785                	li	a5,1
    8000417e:	00f71a63          	bne	a4,a5,80004192 <dirlookup+0x2a>
    80004182:	892a                	mv	s2,a0
    80004184:	89ae                	mv	s3,a1
    80004186:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004188:	457c                	lw	a5,76(a0)
    8000418a:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    8000418c:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000418e:	e79d                	bnez	a5,800041bc <dirlookup+0x54>
    80004190:	a8a5                	j	80004208 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004192:	00004517          	auipc	a0,0x4
    80004196:	49e50513          	addi	a0,a0,1182 # 80008630 <syscalls+0x1e8>
    8000419a:	ffffc097          	auipc	ra,0xffffc
    8000419e:	39e080e7          	jalr	926(ra) # 80000538 <panic>
      panic("dirlookup read");
    800041a2:	00004517          	auipc	a0,0x4
    800041a6:	4a650513          	addi	a0,a0,1190 # 80008648 <syscalls+0x200>
    800041aa:	ffffc097          	auipc	ra,0xffffc
    800041ae:	38e080e7          	jalr	910(ra) # 80000538 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800041b2:	24c1                	addiw	s1,s1,16
    800041b4:	04c92783          	lw	a5,76(s2)
    800041b8:	04f4f763          	bgeu	s1,a5,80004206 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800041bc:	4741                	li	a4,16
    800041be:	86a6                	mv	a3,s1
    800041c0:	fc040613          	addi	a2,s0,-64
    800041c4:	4581                	li	a1,0
    800041c6:	854a                	mv	a0,s2
    800041c8:	00000097          	auipc	ra,0x0
    800041cc:	d70080e7          	jalr	-656(ra) # 80003f38 <readi>
    800041d0:	47c1                	li	a5,16
    800041d2:	fcf518e3          	bne	a0,a5,800041a2 <dirlookup+0x3a>
    if(de.inum == 0)
    800041d6:	fc045783          	lhu	a5,-64(s0)
    800041da:	dfe1                	beqz	a5,800041b2 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    800041dc:	fc240593          	addi	a1,s0,-62
    800041e0:	854e                	mv	a0,s3
    800041e2:	00000097          	auipc	ra,0x0
    800041e6:	f6c080e7          	jalr	-148(ra) # 8000414e <namecmp>
    800041ea:	f561                	bnez	a0,800041b2 <dirlookup+0x4a>
      if(poff)
    800041ec:	000a0463          	beqz	s4,800041f4 <dirlookup+0x8c>
        *poff = off;
    800041f0:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800041f4:	fc045583          	lhu	a1,-64(s0)
    800041f8:	00092503          	lw	a0,0(s2)
    800041fc:	fffff097          	auipc	ra,0xfffff
    80004200:	534080e7          	jalr	1332(ra) # 80003730 <iget>
    80004204:	a011                	j	80004208 <dirlookup+0xa0>
  return 0;
    80004206:	4501                	li	a0,0
}
    80004208:	70e2                	ld	ra,56(sp)
    8000420a:	7442                	ld	s0,48(sp)
    8000420c:	74a2                	ld	s1,40(sp)
    8000420e:	7902                	ld	s2,32(sp)
    80004210:	69e2                	ld	s3,24(sp)
    80004212:	6a42                	ld	s4,16(sp)
    80004214:	6121                	addi	sp,sp,64
    80004216:	8082                	ret

0000000080004218 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004218:	711d                	addi	sp,sp,-96
    8000421a:	ec86                	sd	ra,88(sp)
    8000421c:	e8a2                	sd	s0,80(sp)
    8000421e:	e4a6                	sd	s1,72(sp)
    80004220:	e0ca                	sd	s2,64(sp)
    80004222:	fc4e                	sd	s3,56(sp)
    80004224:	f852                	sd	s4,48(sp)
    80004226:	f456                	sd	s5,40(sp)
    80004228:	f05a                	sd	s6,32(sp)
    8000422a:	ec5e                	sd	s7,24(sp)
    8000422c:	e862                	sd	s8,16(sp)
    8000422e:	e466                	sd	s9,8(sp)
    80004230:	1080                	addi	s0,sp,96
    80004232:	84aa                	mv	s1,a0
    80004234:	8aae                	mv	s5,a1
    80004236:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004238:	00054703          	lbu	a4,0(a0)
    8000423c:	02f00793          	li	a5,47
    80004240:	02f70363          	beq	a4,a5,80004266 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004244:	ffffd097          	auipc	ra,0xffffd
    80004248:	752080e7          	jalr	1874(ra) # 80001996 <myproc>
    8000424c:	17053503          	ld	a0,368(a0)
    80004250:	00000097          	auipc	ra,0x0
    80004254:	9f6080e7          	jalr	-1546(ra) # 80003c46 <idup>
    80004258:	89aa                	mv	s3,a0
  while(*path == '/')
    8000425a:	02f00913          	li	s2,47
  len = path - s;
    8000425e:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80004260:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004262:	4b85                	li	s7,1
    80004264:	a865                	j	8000431c <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80004266:	4585                	li	a1,1
    80004268:	4505                	li	a0,1
    8000426a:	fffff097          	auipc	ra,0xfffff
    8000426e:	4c6080e7          	jalr	1222(ra) # 80003730 <iget>
    80004272:	89aa                	mv	s3,a0
    80004274:	b7dd                	j	8000425a <namex+0x42>
      iunlockput(ip);
    80004276:	854e                	mv	a0,s3
    80004278:	00000097          	auipc	ra,0x0
    8000427c:	c6e080e7          	jalr	-914(ra) # 80003ee6 <iunlockput>
      return 0;
    80004280:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004282:	854e                	mv	a0,s3
    80004284:	60e6                	ld	ra,88(sp)
    80004286:	6446                	ld	s0,80(sp)
    80004288:	64a6                	ld	s1,72(sp)
    8000428a:	6906                	ld	s2,64(sp)
    8000428c:	79e2                	ld	s3,56(sp)
    8000428e:	7a42                	ld	s4,48(sp)
    80004290:	7aa2                	ld	s5,40(sp)
    80004292:	7b02                	ld	s6,32(sp)
    80004294:	6be2                	ld	s7,24(sp)
    80004296:	6c42                	ld	s8,16(sp)
    80004298:	6ca2                	ld	s9,8(sp)
    8000429a:	6125                	addi	sp,sp,96
    8000429c:	8082                	ret
      iunlock(ip);
    8000429e:	854e                	mv	a0,s3
    800042a0:	00000097          	auipc	ra,0x0
    800042a4:	aa6080e7          	jalr	-1370(ra) # 80003d46 <iunlock>
      return ip;
    800042a8:	bfe9                	j	80004282 <namex+0x6a>
      iunlockput(ip);
    800042aa:	854e                	mv	a0,s3
    800042ac:	00000097          	auipc	ra,0x0
    800042b0:	c3a080e7          	jalr	-966(ra) # 80003ee6 <iunlockput>
      return 0;
    800042b4:	89e6                	mv	s3,s9
    800042b6:	b7f1                	j	80004282 <namex+0x6a>
  len = path - s;
    800042b8:	40b48633          	sub	a2,s1,a1
    800042bc:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    800042c0:	099c5463          	bge	s8,s9,80004348 <namex+0x130>
    memmove(name, s, DIRSIZ);
    800042c4:	4639                	li	a2,14
    800042c6:	8552                	mv	a0,s4
    800042c8:	ffffd097          	auipc	ra,0xffffd
    800042cc:	a60080e7          	jalr	-1440(ra) # 80000d28 <memmove>
  while(*path == '/')
    800042d0:	0004c783          	lbu	a5,0(s1)
    800042d4:	01279763          	bne	a5,s2,800042e2 <namex+0xca>
    path++;
    800042d8:	0485                	addi	s1,s1,1
  while(*path == '/')
    800042da:	0004c783          	lbu	a5,0(s1)
    800042de:	ff278de3          	beq	a5,s2,800042d8 <namex+0xc0>
    ilock(ip);
    800042e2:	854e                	mv	a0,s3
    800042e4:	00000097          	auipc	ra,0x0
    800042e8:	9a0080e7          	jalr	-1632(ra) # 80003c84 <ilock>
    if(ip->type != T_DIR){
    800042ec:	04499783          	lh	a5,68(s3)
    800042f0:	f97793e3          	bne	a5,s7,80004276 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    800042f4:	000a8563          	beqz	s5,800042fe <namex+0xe6>
    800042f8:	0004c783          	lbu	a5,0(s1)
    800042fc:	d3cd                	beqz	a5,8000429e <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    800042fe:	865a                	mv	a2,s6
    80004300:	85d2                	mv	a1,s4
    80004302:	854e                	mv	a0,s3
    80004304:	00000097          	auipc	ra,0x0
    80004308:	e64080e7          	jalr	-412(ra) # 80004168 <dirlookup>
    8000430c:	8caa                	mv	s9,a0
    8000430e:	dd51                	beqz	a0,800042aa <namex+0x92>
    iunlockput(ip);
    80004310:	854e                	mv	a0,s3
    80004312:	00000097          	auipc	ra,0x0
    80004316:	bd4080e7          	jalr	-1068(ra) # 80003ee6 <iunlockput>
    ip = next;
    8000431a:	89e6                	mv	s3,s9
  while(*path == '/')
    8000431c:	0004c783          	lbu	a5,0(s1)
    80004320:	05279763          	bne	a5,s2,8000436e <namex+0x156>
    path++;
    80004324:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004326:	0004c783          	lbu	a5,0(s1)
    8000432a:	ff278de3          	beq	a5,s2,80004324 <namex+0x10c>
  if(*path == 0)
    8000432e:	c79d                	beqz	a5,8000435c <namex+0x144>
    path++;
    80004330:	85a6                	mv	a1,s1
  len = path - s;
    80004332:	8cda                	mv	s9,s6
    80004334:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80004336:	01278963          	beq	a5,s2,80004348 <namex+0x130>
    8000433a:	dfbd                	beqz	a5,800042b8 <namex+0xa0>
    path++;
    8000433c:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    8000433e:	0004c783          	lbu	a5,0(s1)
    80004342:	ff279ce3          	bne	a5,s2,8000433a <namex+0x122>
    80004346:	bf8d                	j	800042b8 <namex+0xa0>
    memmove(name, s, len);
    80004348:	2601                	sext.w	a2,a2
    8000434a:	8552                	mv	a0,s4
    8000434c:	ffffd097          	auipc	ra,0xffffd
    80004350:	9dc080e7          	jalr	-1572(ra) # 80000d28 <memmove>
    name[len] = 0;
    80004354:	9cd2                	add	s9,s9,s4
    80004356:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    8000435a:	bf9d                	j	800042d0 <namex+0xb8>
  if(nameiparent){
    8000435c:	f20a83e3          	beqz	s5,80004282 <namex+0x6a>
    iput(ip);
    80004360:	854e                	mv	a0,s3
    80004362:	00000097          	auipc	ra,0x0
    80004366:	adc080e7          	jalr	-1316(ra) # 80003e3e <iput>
    return 0;
    8000436a:	4981                	li	s3,0
    8000436c:	bf19                	j	80004282 <namex+0x6a>
  if(*path == 0)
    8000436e:	d7fd                	beqz	a5,8000435c <namex+0x144>
  while(*path != '/' && *path != 0)
    80004370:	0004c783          	lbu	a5,0(s1)
    80004374:	85a6                	mv	a1,s1
    80004376:	b7d1                	j	8000433a <namex+0x122>

0000000080004378 <dirlink>:
{
    80004378:	7139                	addi	sp,sp,-64
    8000437a:	fc06                	sd	ra,56(sp)
    8000437c:	f822                	sd	s0,48(sp)
    8000437e:	f426                	sd	s1,40(sp)
    80004380:	f04a                	sd	s2,32(sp)
    80004382:	ec4e                	sd	s3,24(sp)
    80004384:	e852                	sd	s4,16(sp)
    80004386:	0080                	addi	s0,sp,64
    80004388:	892a                	mv	s2,a0
    8000438a:	8a2e                	mv	s4,a1
    8000438c:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000438e:	4601                	li	a2,0
    80004390:	00000097          	auipc	ra,0x0
    80004394:	dd8080e7          	jalr	-552(ra) # 80004168 <dirlookup>
    80004398:	e93d                	bnez	a0,8000440e <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000439a:	04c92483          	lw	s1,76(s2)
    8000439e:	c49d                	beqz	s1,800043cc <dirlink+0x54>
    800043a0:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800043a2:	4741                	li	a4,16
    800043a4:	86a6                	mv	a3,s1
    800043a6:	fc040613          	addi	a2,s0,-64
    800043aa:	4581                	li	a1,0
    800043ac:	854a                	mv	a0,s2
    800043ae:	00000097          	auipc	ra,0x0
    800043b2:	b8a080e7          	jalr	-1142(ra) # 80003f38 <readi>
    800043b6:	47c1                	li	a5,16
    800043b8:	06f51163          	bne	a0,a5,8000441a <dirlink+0xa2>
    if(de.inum == 0)
    800043bc:	fc045783          	lhu	a5,-64(s0)
    800043c0:	c791                	beqz	a5,800043cc <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800043c2:	24c1                	addiw	s1,s1,16
    800043c4:	04c92783          	lw	a5,76(s2)
    800043c8:	fcf4ede3          	bltu	s1,a5,800043a2 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800043cc:	4639                	li	a2,14
    800043ce:	85d2                	mv	a1,s4
    800043d0:	fc240513          	addi	a0,s0,-62
    800043d4:	ffffd097          	auipc	ra,0xffffd
    800043d8:	a04080e7          	jalr	-1532(ra) # 80000dd8 <strncpy>
  de.inum = inum;
    800043dc:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800043e0:	4741                	li	a4,16
    800043e2:	86a6                	mv	a3,s1
    800043e4:	fc040613          	addi	a2,s0,-64
    800043e8:	4581                	li	a1,0
    800043ea:	854a                	mv	a0,s2
    800043ec:	00000097          	auipc	ra,0x0
    800043f0:	c44080e7          	jalr	-956(ra) # 80004030 <writei>
    800043f4:	872a                	mv	a4,a0
    800043f6:	47c1                	li	a5,16
  return 0;
    800043f8:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800043fa:	02f71863          	bne	a4,a5,8000442a <dirlink+0xb2>
}
    800043fe:	70e2                	ld	ra,56(sp)
    80004400:	7442                	ld	s0,48(sp)
    80004402:	74a2                	ld	s1,40(sp)
    80004404:	7902                	ld	s2,32(sp)
    80004406:	69e2                	ld	s3,24(sp)
    80004408:	6a42                	ld	s4,16(sp)
    8000440a:	6121                	addi	sp,sp,64
    8000440c:	8082                	ret
    iput(ip);
    8000440e:	00000097          	auipc	ra,0x0
    80004412:	a30080e7          	jalr	-1488(ra) # 80003e3e <iput>
    return -1;
    80004416:	557d                	li	a0,-1
    80004418:	b7dd                	j	800043fe <dirlink+0x86>
      panic("dirlink read");
    8000441a:	00004517          	auipc	a0,0x4
    8000441e:	23e50513          	addi	a0,a0,574 # 80008658 <syscalls+0x210>
    80004422:	ffffc097          	auipc	ra,0xffffc
    80004426:	116080e7          	jalr	278(ra) # 80000538 <panic>
    panic("dirlink");
    8000442a:	00004517          	auipc	a0,0x4
    8000442e:	33e50513          	addi	a0,a0,830 # 80008768 <syscalls+0x320>
    80004432:	ffffc097          	auipc	ra,0xffffc
    80004436:	106080e7          	jalr	262(ra) # 80000538 <panic>

000000008000443a <namei>:

struct inode*
namei(char *path)
{
    8000443a:	1101                	addi	sp,sp,-32
    8000443c:	ec06                	sd	ra,24(sp)
    8000443e:	e822                	sd	s0,16(sp)
    80004440:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004442:	fe040613          	addi	a2,s0,-32
    80004446:	4581                	li	a1,0
    80004448:	00000097          	auipc	ra,0x0
    8000444c:	dd0080e7          	jalr	-560(ra) # 80004218 <namex>
}
    80004450:	60e2                	ld	ra,24(sp)
    80004452:	6442                	ld	s0,16(sp)
    80004454:	6105                	addi	sp,sp,32
    80004456:	8082                	ret

0000000080004458 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004458:	1141                	addi	sp,sp,-16
    8000445a:	e406                	sd	ra,8(sp)
    8000445c:	e022                	sd	s0,0(sp)
    8000445e:	0800                	addi	s0,sp,16
    80004460:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004462:	4585                	li	a1,1
    80004464:	00000097          	auipc	ra,0x0
    80004468:	db4080e7          	jalr	-588(ra) # 80004218 <namex>
}
    8000446c:	60a2                	ld	ra,8(sp)
    8000446e:	6402                	ld	s0,0(sp)
    80004470:	0141                	addi	sp,sp,16
    80004472:	8082                	ret

0000000080004474 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004474:	1101                	addi	sp,sp,-32
    80004476:	ec06                	sd	ra,24(sp)
    80004478:	e822                	sd	s0,16(sp)
    8000447a:	e426                	sd	s1,8(sp)
    8000447c:	e04a                	sd	s2,0(sp)
    8000447e:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004480:	0001e917          	auipc	s2,0x1e
    80004484:	de890913          	addi	s2,s2,-536 # 80022268 <log>
    80004488:	01892583          	lw	a1,24(s2)
    8000448c:	02892503          	lw	a0,40(s2)
    80004490:	fffff097          	auipc	ra,0xfffff
    80004494:	fde080e7          	jalr	-34(ra) # 8000346e <bread>
    80004498:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000449a:	02c92683          	lw	a3,44(s2)
    8000449e:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800044a0:	02d05763          	blez	a3,800044ce <write_head+0x5a>
    800044a4:	0001e797          	auipc	a5,0x1e
    800044a8:	df478793          	addi	a5,a5,-524 # 80022298 <log+0x30>
    800044ac:	05c50713          	addi	a4,a0,92
    800044b0:	36fd                	addiw	a3,a3,-1
    800044b2:	1682                	slli	a3,a3,0x20
    800044b4:	9281                	srli	a3,a3,0x20
    800044b6:	068a                	slli	a3,a3,0x2
    800044b8:	0001e617          	auipc	a2,0x1e
    800044bc:	de460613          	addi	a2,a2,-540 # 8002229c <log+0x34>
    800044c0:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800044c2:	4390                	lw	a2,0(a5)
    800044c4:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800044c6:	0791                	addi	a5,a5,4
    800044c8:	0711                	addi	a4,a4,4
    800044ca:	fed79ce3          	bne	a5,a3,800044c2 <write_head+0x4e>
  }
  bwrite(buf);
    800044ce:	8526                	mv	a0,s1
    800044d0:	fffff097          	auipc	ra,0xfffff
    800044d4:	090080e7          	jalr	144(ra) # 80003560 <bwrite>
  brelse(buf);
    800044d8:	8526                	mv	a0,s1
    800044da:	fffff097          	auipc	ra,0xfffff
    800044de:	0c4080e7          	jalr	196(ra) # 8000359e <brelse>
}
    800044e2:	60e2                	ld	ra,24(sp)
    800044e4:	6442                	ld	s0,16(sp)
    800044e6:	64a2                	ld	s1,8(sp)
    800044e8:	6902                	ld	s2,0(sp)
    800044ea:	6105                	addi	sp,sp,32
    800044ec:	8082                	ret

00000000800044ee <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800044ee:	0001e797          	auipc	a5,0x1e
    800044f2:	da67a783          	lw	a5,-602(a5) # 80022294 <log+0x2c>
    800044f6:	0af05d63          	blez	a5,800045b0 <install_trans+0xc2>
{
    800044fa:	7139                	addi	sp,sp,-64
    800044fc:	fc06                	sd	ra,56(sp)
    800044fe:	f822                	sd	s0,48(sp)
    80004500:	f426                	sd	s1,40(sp)
    80004502:	f04a                	sd	s2,32(sp)
    80004504:	ec4e                	sd	s3,24(sp)
    80004506:	e852                	sd	s4,16(sp)
    80004508:	e456                	sd	s5,8(sp)
    8000450a:	e05a                	sd	s6,0(sp)
    8000450c:	0080                	addi	s0,sp,64
    8000450e:	8b2a                	mv	s6,a0
    80004510:	0001ea97          	auipc	s5,0x1e
    80004514:	d88a8a93          	addi	s5,s5,-632 # 80022298 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004518:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000451a:	0001e997          	auipc	s3,0x1e
    8000451e:	d4e98993          	addi	s3,s3,-690 # 80022268 <log>
    80004522:	a00d                	j	80004544 <install_trans+0x56>
    brelse(lbuf);
    80004524:	854a                	mv	a0,s2
    80004526:	fffff097          	auipc	ra,0xfffff
    8000452a:	078080e7          	jalr	120(ra) # 8000359e <brelse>
    brelse(dbuf);
    8000452e:	8526                	mv	a0,s1
    80004530:	fffff097          	auipc	ra,0xfffff
    80004534:	06e080e7          	jalr	110(ra) # 8000359e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004538:	2a05                	addiw	s4,s4,1
    8000453a:	0a91                	addi	s5,s5,4
    8000453c:	02c9a783          	lw	a5,44(s3)
    80004540:	04fa5e63          	bge	s4,a5,8000459c <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004544:	0189a583          	lw	a1,24(s3)
    80004548:	014585bb          	addw	a1,a1,s4
    8000454c:	2585                	addiw	a1,a1,1
    8000454e:	0289a503          	lw	a0,40(s3)
    80004552:	fffff097          	auipc	ra,0xfffff
    80004556:	f1c080e7          	jalr	-228(ra) # 8000346e <bread>
    8000455a:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000455c:	000aa583          	lw	a1,0(s5)
    80004560:	0289a503          	lw	a0,40(s3)
    80004564:	fffff097          	auipc	ra,0xfffff
    80004568:	f0a080e7          	jalr	-246(ra) # 8000346e <bread>
    8000456c:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000456e:	40000613          	li	a2,1024
    80004572:	05890593          	addi	a1,s2,88
    80004576:	05850513          	addi	a0,a0,88
    8000457a:	ffffc097          	auipc	ra,0xffffc
    8000457e:	7ae080e7          	jalr	1966(ra) # 80000d28 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004582:	8526                	mv	a0,s1
    80004584:	fffff097          	auipc	ra,0xfffff
    80004588:	fdc080e7          	jalr	-36(ra) # 80003560 <bwrite>
    if(recovering == 0)
    8000458c:	f80b1ce3          	bnez	s6,80004524 <install_trans+0x36>
      bunpin(dbuf);
    80004590:	8526                	mv	a0,s1
    80004592:	fffff097          	auipc	ra,0xfffff
    80004596:	0e6080e7          	jalr	230(ra) # 80003678 <bunpin>
    8000459a:	b769                	j	80004524 <install_trans+0x36>
}
    8000459c:	70e2                	ld	ra,56(sp)
    8000459e:	7442                	ld	s0,48(sp)
    800045a0:	74a2                	ld	s1,40(sp)
    800045a2:	7902                	ld	s2,32(sp)
    800045a4:	69e2                	ld	s3,24(sp)
    800045a6:	6a42                	ld	s4,16(sp)
    800045a8:	6aa2                	ld	s5,8(sp)
    800045aa:	6b02                	ld	s6,0(sp)
    800045ac:	6121                	addi	sp,sp,64
    800045ae:	8082                	ret
    800045b0:	8082                	ret

00000000800045b2 <initlog>:
{
    800045b2:	7179                	addi	sp,sp,-48
    800045b4:	f406                	sd	ra,40(sp)
    800045b6:	f022                	sd	s0,32(sp)
    800045b8:	ec26                	sd	s1,24(sp)
    800045ba:	e84a                	sd	s2,16(sp)
    800045bc:	e44e                	sd	s3,8(sp)
    800045be:	1800                	addi	s0,sp,48
    800045c0:	892a                	mv	s2,a0
    800045c2:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800045c4:	0001e497          	auipc	s1,0x1e
    800045c8:	ca448493          	addi	s1,s1,-860 # 80022268 <log>
    800045cc:	00004597          	auipc	a1,0x4
    800045d0:	09c58593          	addi	a1,a1,156 # 80008668 <syscalls+0x220>
    800045d4:	8526                	mv	a0,s1
    800045d6:	ffffc097          	auipc	ra,0xffffc
    800045da:	56a080e7          	jalr	1386(ra) # 80000b40 <initlock>
  log.start = sb->logstart;
    800045de:	0149a583          	lw	a1,20(s3)
    800045e2:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800045e4:	0109a783          	lw	a5,16(s3)
    800045e8:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800045ea:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800045ee:	854a                	mv	a0,s2
    800045f0:	fffff097          	auipc	ra,0xfffff
    800045f4:	e7e080e7          	jalr	-386(ra) # 8000346e <bread>
  log.lh.n = lh->n;
    800045f8:	4d34                	lw	a3,88(a0)
    800045fa:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800045fc:	02d05563          	blez	a3,80004626 <initlog+0x74>
    80004600:	05c50793          	addi	a5,a0,92
    80004604:	0001e717          	auipc	a4,0x1e
    80004608:	c9470713          	addi	a4,a4,-876 # 80022298 <log+0x30>
    8000460c:	36fd                	addiw	a3,a3,-1
    8000460e:	1682                	slli	a3,a3,0x20
    80004610:	9281                	srli	a3,a3,0x20
    80004612:	068a                	slli	a3,a3,0x2
    80004614:	06050613          	addi	a2,a0,96
    80004618:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    8000461a:	4390                	lw	a2,0(a5)
    8000461c:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000461e:	0791                	addi	a5,a5,4
    80004620:	0711                	addi	a4,a4,4
    80004622:	fed79ce3          	bne	a5,a3,8000461a <initlog+0x68>
  brelse(buf);
    80004626:	fffff097          	auipc	ra,0xfffff
    8000462a:	f78080e7          	jalr	-136(ra) # 8000359e <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000462e:	4505                	li	a0,1
    80004630:	00000097          	auipc	ra,0x0
    80004634:	ebe080e7          	jalr	-322(ra) # 800044ee <install_trans>
  log.lh.n = 0;
    80004638:	0001e797          	auipc	a5,0x1e
    8000463c:	c407ae23          	sw	zero,-932(a5) # 80022294 <log+0x2c>
  write_head(); // clear the log
    80004640:	00000097          	auipc	ra,0x0
    80004644:	e34080e7          	jalr	-460(ra) # 80004474 <write_head>
}
    80004648:	70a2                	ld	ra,40(sp)
    8000464a:	7402                	ld	s0,32(sp)
    8000464c:	64e2                	ld	s1,24(sp)
    8000464e:	6942                	ld	s2,16(sp)
    80004650:	69a2                	ld	s3,8(sp)
    80004652:	6145                	addi	sp,sp,48
    80004654:	8082                	ret

0000000080004656 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004656:	1101                	addi	sp,sp,-32
    80004658:	ec06                	sd	ra,24(sp)
    8000465a:	e822                	sd	s0,16(sp)
    8000465c:	e426                	sd	s1,8(sp)
    8000465e:	e04a                	sd	s2,0(sp)
    80004660:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004662:	0001e517          	auipc	a0,0x1e
    80004666:	c0650513          	addi	a0,a0,-1018 # 80022268 <log>
    8000466a:	ffffc097          	auipc	ra,0xffffc
    8000466e:	566080e7          	jalr	1382(ra) # 80000bd0 <acquire>
  while(1){
    if(log.committing){
    80004672:	0001e497          	auipc	s1,0x1e
    80004676:	bf648493          	addi	s1,s1,-1034 # 80022268 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000467a:	4979                	li	s2,30
    8000467c:	a039                	j	8000468a <begin_op+0x34>
      sleep(&log, &log.lock);
    8000467e:	85a6                	mv	a1,s1
    80004680:	8526                	mv	a0,s1
    80004682:	ffffe097          	auipc	ra,0xffffe
    80004686:	c86080e7          	jalr	-890(ra) # 80002308 <sleep>
    if(log.committing){
    8000468a:	50dc                	lw	a5,36(s1)
    8000468c:	fbed                	bnez	a5,8000467e <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000468e:	509c                	lw	a5,32(s1)
    80004690:	0017871b          	addiw	a4,a5,1
    80004694:	0007069b          	sext.w	a3,a4
    80004698:	0027179b          	slliw	a5,a4,0x2
    8000469c:	9fb9                	addw	a5,a5,a4
    8000469e:	0017979b          	slliw	a5,a5,0x1
    800046a2:	54d8                	lw	a4,44(s1)
    800046a4:	9fb9                	addw	a5,a5,a4
    800046a6:	00f95963          	bge	s2,a5,800046b8 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800046aa:	85a6                	mv	a1,s1
    800046ac:	8526                	mv	a0,s1
    800046ae:	ffffe097          	auipc	ra,0xffffe
    800046b2:	c5a080e7          	jalr	-934(ra) # 80002308 <sleep>
    800046b6:	bfd1                	j	8000468a <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800046b8:	0001e517          	auipc	a0,0x1e
    800046bc:	bb050513          	addi	a0,a0,-1104 # 80022268 <log>
    800046c0:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800046c2:	ffffc097          	auipc	ra,0xffffc
    800046c6:	5c2080e7          	jalr	1474(ra) # 80000c84 <release>
      break;
    }
  }
}
    800046ca:	60e2                	ld	ra,24(sp)
    800046cc:	6442                	ld	s0,16(sp)
    800046ce:	64a2                	ld	s1,8(sp)
    800046d0:	6902                	ld	s2,0(sp)
    800046d2:	6105                	addi	sp,sp,32
    800046d4:	8082                	ret

00000000800046d6 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800046d6:	7139                	addi	sp,sp,-64
    800046d8:	fc06                	sd	ra,56(sp)
    800046da:	f822                	sd	s0,48(sp)
    800046dc:	f426                	sd	s1,40(sp)
    800046de:	f04a                	sd	s2,32(sp)
    800046e0:	ec4e                	sd	s3,24(sp)
    800046e2:	e852                	sd	s4,16(sp)
    800046e4:	e456                	sd	s5,8(sp)
    800046e6:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800046e8:	0001e497          	auipc	s1,0x1e
    800046ec:	b8048493          	addi	s1,s1,-1152 # 80022268 <log>
    800046f0:	8526                	mv	a0,s1
    800046f2:	ffffc097          	auipc	ra,0xffffc
    800046f6:	4de080e7          	jalr	1246(ra) # 80000bd0 <acquire>
  log.outstanding -= 1;
    800046fa:	509c                	lw	a5,32(s1)
    800046fc:	37fd                	addiw	a5,a5,-1
    800046fe:	0007891b          	sext.w	s2,a5
    80004702:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004704:	50dc                	lw	a5,36(s1)
    80004706:	e7b9                	bnez	a5,80004754 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004708:	04091e63          	bnez	s2,80004764 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    8000470c:	0001e497          	auipc	s1,0x1e
    80004710:	b5c48493          	addi	s1,s1,-1188 # 80022268 <log>
    80004714:	4785                	li	a5,1
    80004716:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004718:	8526                	mv	a0,s1
    8000471a:	ffffc097          	auipc	ra,0xffffc
    8000471e:	56a080e7          	jalr	1386(ra) # 80000c84 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004722:	54dc                	lw	a5,44(s1)
    80004724:	06f04763          	bgtz	a5,80004792 <end_op+0xbc>
    acquire(&log.lock);
    80004728:	0001e497          	auipc	s1,0x1e
    8000472c:	b4048493          	addi	s1,s1,-1216 # 80022268 <log>
    80004730:	8526                	mv	a0,s1
    80004732:	ffffc097          	auipc	ra,0xffffc
    80004736:	49e080e7          	jalr	1182(ra) # 80000bd0 <acquire>
    log.committing = 0;
    8000473a:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000473e:	8526                	mv	a0,s1
    80004740:	ffffe097          	auipc	ra,0xffffe
    80004744:	d5a080e7          	jalr	-678(ra) # 8000249a <wakeup>
    release(&log.lock);
    80004748:	8526                	mv	a0,s1
    8000474a:	ffffc097          	auipc	ra,0xffffc
    8000474e:	53a080e7          	jalr	1338(ra) # 80000c84 <release>
}
    80004752:	a03d                	j	80004780 <end_op+0xaa>
    panic("log.committing");
    80004754:	00004517          	auipc	a0,0x4
    80004758:	f1c50513          	addi	a0,a0,-228 # 80008670 <syscalls+0x228>
    8000475c:	ffffc097          	auipc	ra,0xffffc
    80004760:	ddc080e7          	jalr	-548(ra) # 80000538 <panic>
    wakeup(&log);
    80004764:	0001e497          	auipc	s1,0x1e
    80004768:	b0448493          	addi	s1,s1,-1276 # 80022268 <log>
    8000476c:	8526                	mv	a0,s1
    8000476e:	ffffe097          	auipc	ra,0xffffe
    80004772:	d2c080e7          	jalr	-724(ra) # 8000249a <wakeup>
  release(&log.lock);
    80004776:	8526                	mv	a0,s1
    80004778:	ffffc097          	auipc	ra,0xffffc
    8000477c:	50c080e7          	jalr	1292(ra) # 80000c84 <release>
}
    80004780:	70e2                	ld	ra,56(sp)
    80004782:	7442                	ld	s0,48(sp)
    80004784:	74a2                	ld	s1,40(sp)
    80004786:	7902                	ld	s2,32(sp)
    80004788:	69e2                	ld	s3,24(sp)
    8000478a:	6a42                	ld	s4,16(sp)
    8000478c:	6aa2                	ld	s5,8(sp)
    8000478e:	6121                	addi	sp,sp,64
    80004790:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004792:	0001ea97          	auipc	s5,0x1e
    80004796:	b06a8a93          	addi	s5,s5,-1274 # 80022298 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000479a:	0001ea17          	auipc	s4,0x1e
    8000479e:	acea0a13          	addi	s4,s4,-1330 # 80022268 <log>
    800047a2:	018a2583          	lw	a1,24(s4)
    800047a6:	012585bb          	addw	a1,a1,s2
    800047aa:	2585                	addiw	a1,a1,1
    800047ac:	028a2503          	lw	a0,40(s4)
    800047b0:	fffff097          	auipc	ra,0xfffff
    800047b4:	cbe080e7          	jalr	-834(ra) # 8000346e <bread>
    800047b8:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800047ba:	000aa583          	lw	a1,0(s5)
    800047be:	028a2503          	lw	a0,40(s4)
    800047c2:	fffff097          	auipc	ra,0xfffff
    800047c6:	cac080e7          	jalr	-852(ra) # 8000346e <bread>
    800047ca:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800047cc:	40000613          	li	a2,1024
    800047d0:	05850593          	addi	a1,a0,88
    800047d4:	05848513          	addi	a0,s1,88
    800047d8:	ffffc097          	auipc	ra,0xffffc
    800047dc:	550080e7          	jalr	1360(ra) # 80000d28 <memmove>
    bwrite(to);  // write the log
    800047e0:	8526                	mv	a0,s1
    800047e2:	fffff097          	auipc	ra,0xfffff
    800047e6:	d7e080e7          	jalr	-642(ra) # 80003560 <bwrite>
    brelse(from);
    800047ea:	854e                	mv	a0,s3
    800047ec:	fffff097          	auipc	ra,0xfffff
    800047f0:	db2080e7          	jalr	-590(ra) # 8000359e <brelse>
    brelse(to);
    800047f4:	8526                	mv	a0,s1
    800047f6:	fffff097          	auipc	ra,0xfffff
    800047fa:	da8080e7          	jalr	-600(ra) # 8000359e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800047fe:	2905                	addiw	s2,s2,1
    80004800:	0a91                	addi	s5,s5,4
    80004802:	02ca2783          	lw	a5,44(s4)
    80004806:	f8f94ee3          	blt	s2,a5,800047a2 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000480a:	00000097          	auipc	ra,0x0
    8000480e:	c6a080e7          	jalr	-918(ra) # 80004474 <write_head>
    install_trans(0); // Now install writes to home locations
    80004812:	4501                	li	a0,0
    80004814:	00000097          	auipc	ra,0x0
    80004818:	cda080e7          	jalr	-806(ra) # 800044ee <install_trans>
    log.lh.n = 0;
    8000481c:	0001e797          	auipc	a5,0x1e
    80004820:	a607ac23          	sw	zero,-1416(a5) # 80022294 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004824:	00000097          	auipc	ra,0x0
    80004828:	c50080e7          	jalr	-944(ra) # 80004474 <write_head>
    8000482c:	bdf5                	j	80004728 <end_op+0x52>

000000008000482e <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000482e:	1101                	addi	sp,sp,-32
    80004830:	ec06                	sd	ra,24(sp)
    80004832:	e822                	sd	s0,16(sp)
    80004834:	e426                	sd	s1,8(sp)
    80004836:	e04a                	sd	s2,0(sp)
    80004838:	1000                	addi	s0,sp,32
    8000483a:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    8000483c:	0001e917          	auipc	s2,0x1e
    80004840:	a2c90913          	addi	s2,s2,-1492 # 80022268 <log>
    80004844:	854a                	mv	a0,s2
    80004846:	ffffc097          	auipc	ra,0xffffc
    8000484a:	38a080e7          	jalr	906(ra) # 80000bd0 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000484e:	02c92603          	lw	a2,44(s2)
    80004852:	47f5                	li	a5,29
    80004854:	06c7c563          	blt	a5,a2,800048be <log_write+0x90>
    80004858:	0001e797          	auipc	a5,0x1e
    8000485c:	a2c7a783          	lw	a5,-1492(a5) # 80022284 <log+0x1c>
    80004860:	37fd                	addiw	a5,a5,-1
    80004862:	04f65e63          	bge	a2,a5,800048be <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004866:	0001e797          	auipc	a5,0x1e
    8000486a:	a227a783          	lw	a5,-1502(a5) # 80022288 <log+0x20>
    8000486e:	06f05063          	blez	a5,800048ce <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004872:	4781                	li	a5,0
    80004874:	06c05563          	blez	a2,800048de <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004878:	44cc                	lw	a1,12(s1)
    8000487a:	0001e717          	auipc	a4,0x1e
    8000487e:	a1e70713          	addi	a4,a4,-1506 # 80022298 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004882:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004884:	4314                	lw	a3,0(a4)
    80004886:	04b68c63          	beq	a3,a1,800048de <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000488a:	2785                	addiw	a5,a5,1
    8000488c:	0711                	addi	a4,a4,4
    8000488e:	fef61be3          	bne	a2,a5,80004884 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004892:	0621                	addi	a2,a2,8
    80004894:	060a                	slli	a2,a2,0x2
    80004896:	0001e797          	auipc	a5,0x1e
    8000489a:	9d278793          	addi	a5,a5,-1582 # 80022268 <log>
    8000489e:	963e                	add	a2,a2,a5
    800048a0:	44dc                	lw	a5,12(s1)
    800048a2:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800048a4:	8526                	mv	a0,s1
    800048a6:	fffff097          	auipc	ra,0xfffff
    800048aa:	d96080e7          	jalr	-618(ra) # 8000363c <bpin>
    log.lh.n++;
    800048ae:	0001e717          	auipc	a4,0x1e
    800048b2:	9ba70713          	addi	a4,a4,-1606 # 80022268 <log>
    800048b6:	575c                	lw	a5,44(a4)
    800048b8:	2785                	addiw	a5,a5,1
    800048ba:	d75c                	sw	a5,44(a4)
    800048bc:	a835                	j	800048f8 <log_write+0xca>
    panic("too big a transaction");
    800048be:	00004517          	auipc	a0,0x4
    800048c2:	dc250513          	addi	a0,a0,-574 # 80008680 <syscalls+0x238>
    800048c6:	ffffc097          	auipc	ra,0xffffc
    800048ca:	c72080e7          	jalr	-910(ra) # 80000538 <panic>
    panic("log_write outside of trans");
    800048ce:	00004517          	auipc	a0,0x4
    800048d2:	dca50513          	addi	a0,a0,-566 # 80008698 <syscalls+0x250>
    800048d6:	ffffc097          	auipc	ra,0xffffc
    800048da:	c62080e7          	jalr	-926(ra) # 80000538 <panic>
  log.lh.block[i] = b->blockno;
    800048de:	00878713          	addi	a4,a5,8
    800048e2:	00271693          	slli	a3,a4,0x2
    800048e6:	0001e717          	auipc	a4,0x1e
    800048ea:	98270713          	addi	a4,a4,-1662 # 80022268 <log>
    800048ee:	9736                	add	a4,a4,a3
    800048f0:	44d4                	lw	a3,12(s1)
    800048f2:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800048f4:	faf608e3          	beq	a2,a5,800048a4 <log_write+0x76>
  }
  release(&log.lock);
    800048f8:	0001e517          	auipc	a0,0x1e
    800048fc:	97050513          	addi	a0,a0,-1680 # 80022268 <log>
    80004900:	ffffc097          	auipc	ra,0xffffc
    80004904:	384080e7          	jalr	900(ra) # 80000c84 <release>
}
    80004908:	60e2                	ld	ra,24(sp)
    8000490a:	6442                	ld	s0,16(sp)
    8000490c:	64a2                	ld	s1,8(sp)
    8000490e:	6902                	ld	s2,0(sp)
    80004910:	6105                	addi	sp,sp,32
    80004912:	8082                	ret

0000000080004914 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004914:	1101                	addi	sp,sp,-32
    80004916:	ec06                	sd	ra,24(sp)
    80004918:	e822                	sd	s0,16(sp)
    8000491a:	e426                	sd	s1,8(sp)
    8000491c:	e04a                	sd	s2,0(sp)
    8000491e:	1000                	addi	s0,sp,32
    80004920:	84aa                	mv	s1,a0
    80004922:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004924:	00004597          	auipc	a1,0x4
    80004928:	d9458593          	addi	a1,a1,-620 # 800086b8 <syscalls+0x270>
    8000492c:	0521                	addi	a0,a0,8
    8000492e:	ffffc097          	auipc	ra,0xffffc
    80004932:	212080e7          	jalr	530(ra) # 80000b40 <initlock>
  lk->name = name;
    80004936:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000493a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000493e:	0204a423          	sw	zero,40(s1)
}
    80004942:	60e2                	ld	ra,24(sp)
    80004944:	6442                	ld	s0,16(sp)
    80004946:	64a2                	ld	s1,8(sp)
    80004948:	6902                	ld	s2,0(sp)
    8000494a:	6105                	addi	sp,sp,32
    8000494c:	8082                	ret

000000008000494e <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000494e:	1101                	addi	sp,sp,-32
    80004950:	ec06                	sd	ra,24(sp)
    80004952:	e822                	sd	s0,16(sp)
    80004954:	e426                	sd	s1,8(sp)
    80004956:	e04a                	sd	s2,0(sp)
    80004958:	1000                	addi	s0,sp,32
    8000495a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000495c:	00850913          	addi	s2,a0,8
    80004960:	854a                	mv	a0,s2
    80004962:	ffffc097          	auipc	ra,0xffffc
    80004966:	26e080e7          	jalr	622(ra) # 80000bd0 <acquire>
  while (lk->locked) {
    8000496a:	409c                	lw	a5,0(s1)
    8000496c:	cb89                	beqz	a5,8000497e <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000496e:	85ca                	mv	a1,s2
    80004970:	8526                	mv	a0,s1
    80004972:	ffffe097          	auipc	ra,0xffffe
    80004976:	996080e7          	jalr	-1642(ra) # 80002308 <sleep>
  while (lk->locked) {
    8000497a:	409c                	lw	a5,0(s1)
    8000497c:	fbed                	bnez	a5,8000496e <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000497e:	4785                	li	a5,1
    80004980:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004982:	ffffd097          	auipc	ra,0xffffd
    80004986:	014080e7          	jalr	20(ra) # 80001996 <myproc>
    8000498a:	591c                	lw	a5,48(a0)
    8000498c:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000498e:	854a                	mv	a0,s2
    80004990:	ffffc097          	auipc	ra,0xffffc
    80004994:	2f4080e7          	jalr	756(ra) # 80000c84 <release>
}
    80004998:	60e2                	ld	ra,24(sp)
    8000499a:	6442                	ld	s0,16(sp)
    8000499c:	64a2                	ld	s1,8(sp)
    8000499e:	6902                	ld	s2,0(sp)
    800049a0:	6105                	addi	sp,sp,32
    800049a2:	8082                	ret

00000000800049a4 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800049a4:	1101                	addi	sp,sp,-32
    800049a6:	ec06                	sd	ra,24(sp)
    800049a8:	e822                	sd	s0,16(sp)
    800049aa:	e426                	sd	s1,8(sp)
    800049ac:	e04a                	sd	s2,0(sp)
    800049ae:	1000                	addi	s0,sp,32
    800049b0:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800049b2:	00850913          	addi	s2,a0,8
    800049b6:	854a                	mv	a0,s2
    800049b8:	ffffc097          	auipc	ra,0xffffc
    800049bc:	218080e7          	jalr	536(ra) # 80000bd0 <acquire>
  lk->locked = 0;
    800049c0:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800049c4:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800049c8:	8526                	mv	a0,s1
    800049ca:	ffffe097          	auipc	ra,0xffffe
    800049ce:	ad0080e7          	jalr	-1328(ra) # 8000249a <wakeup>
  release(&lk->lk);
    800049d2:	854a                	mv	a0,s2
    800049d4:	ffffc097          	auipc	ra,0xffffc
    800049d8:	2b0080e7          	jalr	688(ra) # 80000c84 <release>
}
    800049dc:	60e2                	ld	ra,24(sp)
    800049de:	6442                	ld	s0,16(sp)
    800049e0:	64a2                	ld	s1,8(sp)
    800049e2:	6902                	ld	s2,0(sp)
    800049e4:	6105                	addi	sp,sp,32
    800049e6:	8082                	ret

00000000800049e8 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800049e8:	7179                	addi	sp,sp,-48
    800049ea:	f406                	sd	ra,40(sp)
    800049ec:	f022                	sd	s0,32(sp)
    800049ee:	ec26                	sd	s1,24(sp)
    800049f0:	e84a                	sd	s2,16(sp)
    800049f2:	e44e                	sd	s3,8(sp)
    800049f4:	1800                	addi	s0,sp,48
    800049f6:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800049f8:	00850913          	addi	s2,a0,8
    800049fc:	854a                	mv	a0,s2
    800049fe:	ffffc097          	auipc	ra,0xffffc
    80004a02:	1d2080e7          	jalr	466(ra) # 80000bd0 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004a06:	409c                	lw	a5,0(s1)
    80004a08:	ef99                	bnez	a5,80004a26 <holdingsleep+0x3e>
    80004a0a:	4481                	li	s1,0
  release(&lk->lk);
    80004a0c:	854a                	mv	a0,s2
    80004a0e:	ffffc097          	auipc	ra,0xffffc
    80004a12:	276080e7          	jalr	630(ra) # 80000c84 <release>
  return r;
}
    80004a16:	8526                	mv	a0,s1
    80004a18:	70a2                	ld	ra,40(sp)
    80004a1a:	7402                	ld	s0,32(sp)
    80004a1c:	64e2                	ld	s1,24(sp)
    80004a1e:	6942                	ld	s2,16(sp)
    80004a20:	69a2                	ld	s3,8(sp)
    80004a22:	6145                	addi	sp,sp,48
    80004a24:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004a26:	0284a983          	lw	s3,40(s1)
    80004a2a:	ffffd097          	auipc	ra,0xffffd
    80004a2e:	f6c080e7          	jalr	-148(ra) # 80001996 <myproc>
    80004a32:	5904                	lw	s1,48(a0)
    80004a34:	413484b3          	sub	s1,s1,s3
    80004a38:	0014b493          	seqz	s1,s1
    80004a3c:	bfc1                	j	80004a0c <holdingsleep+0x24>

0000000080004a3e <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004a3e:	1141                	addi	sp,sp,-16
    80004a40:	e406                	sd	ra,8(sp)
    80004a42:	e022                	sd	s0,0(sp)
    80004a44:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004a46:	00004597          	auipc	a1,0x4
    80004a4a:	c8258593          	addi	a1,a1,-894 # 800086c8 <syscalls+0x280>
    80004a4e:	0001e517          	auipc	a0,0x1e
    80004a52:	96250513          	addi	a0,a0,-1694 # 800223b0 <ftable>
    80004a56:	ffffc097          	auipc	ra,0xffffc
    80004a5a:	0ea080e7          	jalr	234(ra) # 80000b40 <initlock>
}
    80004a5e:	60a2                	ld	ra,8(sp)
    80004a60:	6402                	ld	s0,0(sp)
    80004a62:	0141                	addi	sp,sp,16
    80004a64:	8082                	ret

0000000080004a66 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004a66:	1101                	addi	sp,sp,-32
    80004a68:	ec06                	sd	ra,24(sp)
    80004a6a:	e822                	sd	s0,16(sp)
    80004a6c:	e426                	sd	s1,8(sp)
    80004a6e:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004a70:	0001e517          	auipc	a0,0x1e
    80004a74:	94050513          	addi	a0,a0,-1728 # 800223b0 <ftable>
    80004a78:	ffffc097          	auipc	ra,0xffffc
    80004a7c:	158080e7          	jalr	344(ra) # 80000bd0 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004a80:	0001e497          	auipc	s1,0x1e
    80004a84:	94848493          	addi	s1,s1,-1720 # 800223c8 <ftable+0x18>
    80004a88:	0001f717          	auipc	a4,0x1f
    80004a8c:	8e070713          	addi	a4,a4,-1824 # 80023368 <disk>
    if(f->ref == 0){
    80004a90:	40dc                	lw	a5,4(s1)
    80004a92:	cf99                	beqz	a5,80004ab0 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004a94:	02848493          	addi	s1,s1,40
    80004a98:	fee49ce3          	bne	s1,a4,80004a90 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004a9c:	0001e517          	auipc	a0,0x1e
    80004aa0:	91450513          	addi	a0,a0,-1772 # 800223b0 <ftable>
    80004aa4:	ffffc097          	auipc	ra,0xffffc
    80004aa8:	1e0080e7          	jalr	480(ra) # 80000c84 <release>
  return 0;
    80004aac:	4481                	li	s1,0
    80004aae:	a819                	j	80004ac4 <filealloc+0x5e>
      f->ref = 1;
    80004ab0:	4785                	li	a5,1
    80004ab2:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004ab4:	0001e517          	auipc	a0,0x1e
    80004ab8:	8fc50513          	addi	a0,a0,-1796 # 800223b0 <ftable>
    80004abc:	ffffc097          	auipc	ra,0xffffc
    80004ac0:	1c8080e7          	jalr	456(ra) # 80000c84 <release>
}
    80004ac4:	8526                	mv	a0,s1
    80004ac6:	60e2                	ld	ra,24(sp)
    80004ac8:	6442                	ld	s0,16(sp)
    80004aca:	64a2                	ld	s1,8(sp)
    80004acc:	6105                	addi	sp,sp,32
    80004ace:	8082                	ret

0000000080004ad0 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004ad0:	1101                	addi	sp,sp,-32
    80004ad2:	ec06                	sd	ra,24(sp)
    80004ad4:	e822                	sd	s0,16(sp)
    80004ad6:	e426                	sd	s1,8(sp)
    80004ad8:	1000                	addi	s0,sp,32
    80004ada:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004adc:	0001e517          	auipc	a0,0x1e
    80004ae0:	8d450513          	addi	a0,a0,-1836 # 800223b0 <ftable>
    80004ae4:	ffffc097          	auipc	ra,0xffffc
    80004ae8:	0ec080e7          	jalr	236(ra) # 80000bd0 <acquire>
  if(f->ref < 1)
    80004aec:	40dc                	lw	a5,4(s1)
    80004aee:	02f05263          	blez	a5,80004b12 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004af2:	2785                	addiw	a5,a5,1
    80004af4:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004af6:	0001e517          	auipc	a0,0x1e
    80004afa:	8ba50513          	addi	a0,a0,-1862 # 800223b0 <ftable>
    80004afe:	ffffc097          	auipc	ra,0xffffc
    80004b02:	186080e7          	jalr	390(ra) # 80000c84 <release>
  return f;
}
    80004b06:	8526                	mv	a0,s1
    80004b08:	60e2                	ld	ra,24(sp)
    80004b0a:	6442                	ld	s0,16(sp)
    80004b0c:	64a2                	ld	s1,8(sp)
    80004b0e:	6105                	addi	sp,sp,32
    80004b10:	8082                	ret
    panic("filedup");
    80004b12:	00004517          	auipc	a0,0x4
    80004b16:	bbe50513          	addi	a0,a0,-1090 # 800086d0 <syscalls+0x288>
    80004b1a:	ffffc097          	auipc	ra,0xffffc
    80004b1e:	a1e080e7          	jalr	-1506(ra) # 80000538 <panic>

0000000080004b22 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004b22:	7139                	addi	sp,sp,-64
    80004b24:	fc06                	sd	ra,56(sp)
    80004b26:	f822                	sd	s0,48(sp)
    80004b28:	f426                	sd	s1,40(sp)
    80004b2a:	f04a                	sd	s2,32(sp)
    80004b2c:	ec4e                	sd	s3,24(sp)
    80004b2e:	e852                	sd	s4,16(sp)
    80004b30:	e456                	sd	s5,8(sp)
    80004b32:	0080                	addi	s0,sp,64
    80004b34:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004b36:	0001e517          	auipc	a0,0x1e
    80004b3a:	87a50513          	addi	a0,a0,-1926 # 800223b0 <ftable>
    80004b3e:	ffffc097          	auipc	ra,0xffffc
    80004b42:	092080e7          	jalr	146(ra) # 80000bd0 <acquire>
  if(f->ref < 1)
    80004b46:	40dc                	lw	a5,4(s1)
    80004b48:	06f05163          	blez	a5,80004baa <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004b4c:	37fd                	addiw	a5,a5,-1
    80004b4e:	0007871b          	sext.w	a4,a5
    80004b52:	c0dc                	sw	a5,4(s1)
    80004b54:	06e04363          	bgtz	a4,80004bba <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004b58:	0004a903          	lw	s2,0(s1)
    80004b5c:	0094ca83          	lbu	s5,9(s1)
    80004b60:	0104ba03          	ld	s4,16(s1)
    80004b64:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004b68:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004b6c:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004b70:	0001e517          	auipc	a0,0x1e
    80004b74:	84050513          	addi	a0,a0,-1984 # 800223b0 <ftable>
    80004b78:	ffffc097          	auipc	ra,0xffffc
    80004b7c:	10c080e7          	jalr	268(ra) # 80000c84 <release>

  if(ff.type == FD_PIPE){
    80004b80:	4785                	li	a5,1
    80004b82:	04f90d63          	beq	s2,a5,80004bdc <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004b86:	3979                	addiw	s2,s2,-2
    80004b88:	4785                	li	a5,1
    80004b8a:	0527e063          	bltu	a5,s2,80004bca <fileclose+0xa8>
    begin_op();
    80004b8e:	00000097          	auipc	ra,0x0
    80004b92:	ac8080e7          	jalr	-1336(ra) # 80004656 <begin_op>
    iput(ff.ip);
    80004b96:	854e                	mv	a0,s3
    80004b98:	fffff097          	auipc	ra,0xfffff
    80004b9c:	2a6080e7          	jalr	678(ra) # 80003e3e <iput>
    end_op();
    80004ba0:	00000097          	auipc	ra,0x0
    80004ba4:	b36080e7          	jalr	-1226(ra) # 800046d6 <end_op>
    80004ba8:	a00d                	j	80004bca <fileclose+0xa8>
    panic("fileclose");
    80004baa:	00004517          	auipc	a0,0x4
    80004bae:	b2e50513          	addi	a0,a0,-1234 # 800086d8 <syscalls+0x290>
    80004bb2:	ffffc097          	auipc	ra,0xffffc
    80004bb6:	986080e7          	jalr	-1658(ra) # 80000538 <panic>
    release(&ftable.lock);
    80004bba:	0001d517          	auipc	a0,0x1d
    80004bbe:	7f650513          	addi	a0,a0,2038 # 800223b0 <ftable>
    80004bc2:	ffffc097          	auipc	ra,0xffffc
    80004bc6:	0c2080e7          	jalr	194(ra) # 80000c84 <release>
  }
}
    80004bca:	70e2                	ld	ra,56(sp)
    80004bcc:	7442                	ld	s0,48(sp)
    80004bce:	74a2                	ld	s1,40(sp)
    80004bd0:	7902                	ld	s2,32(sp)
    80004bd2:	69e2                	ld	s3,24(sp)
    80004bd4:	6a42                	ld	s4,16(sp)
    80004bd6:	6aa2                	ld	s5,8(sp)
    80004bd8:	6121                	addi	sp,sp,64
    80004bda:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004bdc:	85d6                	mv	a1,s5
    80004bde:	8552                	mv	a0,s4
    80004be0:	00000097          	auipc	ra,0x0
    80004be4:	34c080e7          	jalr	844(ra) # 80004f2c <pipeclose>
    80004be8:	b7cd                	j	80004bca <fileclose+0xa8>

0000000080004bea <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004bea:	715d                	addi	sp,sp,-80
    80004bec:	e486                	sd	ra,72(sp)
    80004bee:	e0a2                	sd	s0,64(sp)
    80004bf0:	fc26                	sd	s1,56(sp)
    80004bf2:	f84a                	sd	s2,48(sp)
    80004bf4:	f44e                	sd	s3,40(sp)
    80004bf6:	0880                	addi	s0,sp,80
    80004bf8:	84aa                	mv	s1,a0
    80004bfa:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004bfc:	ffffd097          	auipc	ra,0xffffd
    80004c00:	d9a080e7          	jalr	-614(ra) # 80001996 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004c04:	409c                	lw	a5,0(s1)
    80004c06:	37f9                	addiw	a5,a5,-2
    80004c08:	4705                	li	a4,1
    80004c0a:	04f76763          	bltu	a4,a5,80004c58 <filestat+0x6e>
    80004c0e:	892a                	mv	s2,a0
    ilock(f->ip);
    80004c10:	6c88                	ld	a0,24(s1)
    80004c12:	fffff097          	auipc	ra,0xfffff
    80004c16:	072080e7          	jalr	114(ra) # 80003c84 <ilock>
    stati(f->ip, &st);
    80004c1a:	fb840593          	addi	a1,s0,-72
    80004c1e:	6c88                	ld	a0,24(s1)
    80004c20:	fffff097          	auipc	ra,0xfffff
    80004c24:	2ee080e7          	jalr	750(ra) # 80003f0e <stati>
    iunlock(f->ip);
    80004c28:	6c88                	ld	a0,24(s1)
    80004c2a:	fffff097          	auipc	ra,0xfffff
    80004c2e:	11c080e7          	jalr	284(ra) # 80003d46 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004c32:	46e1                	li	a3,24
    80004c34:	fb840613          	addi	a2,s0,-72
    80004c38:	85ce                	mv	a1,s3
    80004c3a:	07093503          	ld	a0,112(s2)
    80004c3e:	ffffd097          	auipc	ra,0xffffd
    80004c42:	a18080e7          	jalr	-1512(ra) # 80001656 <copyout>
    80004c46:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004c4a:	60a6                	ld	ra,72(sp)
    80004c4c:	6406                	ld	s0,64(sp)
    80004c4e:	74e2                	ld	s1,56(sp)
    80004c50:	7942                	ld	s2,48(sp)
    80004c52:	79a2                	ld	s3,40(sp)
    80004c54:	6161                	addi	sp,sp,80
    80004c56:	8082                	ret
  return -1;
    80004c58:	557d                	li	a0,-1
    80004c5a:	bfc5                	j	80004c4a <filestat+0x60>

0000000080004c5c <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004c5c:	7179                	addi	sp,sp,-48
    80004c5e:	f406                	sd	ra,40(sp)
    80004c60:	f022                	sd	s0,32(sp)
    80004c62:	ec26                	sd	s1,24(sp)
    80004c64:	e84a                	sd	s2,16(sp)
    80004c66:	e44e                	sd	s3,8(sp)
    80004c68:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004c6a:	00854783          	lbu	a5,8(a0)
    80004c6e:	c3d5                	beqz	a5,80004d12 <fileread+0xb6>
    80004c70:	84aa                	mv	s1,a0
    80004c72:	89ae                	mv	s3,a1
    80004c74:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004c76:	411c                	lw	a5,0(a0)
    80004c78:	4705                	li	a4,1
    80004c7a:	04e78963          	beq	a5,a4,80004ccc <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004c7e:	470d                	li	a4,3
    80004c80:	04e78d63          	beq	a5,a4,80004cda <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004c84:	4709                	li	a4,2
    80004c86:	06e79e63          	bne	a5,a4,80004d02 <fileread+0xa6>
    ilock(f->ip);
    80004c8a:	6d08                	ld	a0,24(a0)
    80004c8c:	fffff097          	auipc	ra,0xfffff
    80004c90:	ff8080e7          	jalr	-8(ra) # 80003c84 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004c94:	874a                	mv	a4,s2
    80004c96:	5094                	lw	a3,32(s1)
    80004c98:	864e                	mv	a2,s3
    80004c9a:	4585                	li	a1,1
    80004c9c:	6c88                	ld	a0,24(s1)
    80004c9e:	fffff097          	auipc	ra,0xfffff
    80004ca2:	29a080e7          	jalr	666(ra) # 80003f38 <readi>
    80004ca6:	892a                	mv	s2,a0
    80004ca8:	00a05563          	blez	a0,80004cb2 <fileread+0x56>
      f->off += r;
    80004cac:	509c                	lw	a5,32(s1)
    80004cae:	9fa9                	addw	a5,a5,a0
    80004cb0:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004cb2:	6c88                	ld	a0,24(s1)
    80004cb4:	fffff097          	auipc	ra,0xfffff
    80004cb8:	092080e7          	jalr	146(ra) # 80003d46 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004cbc:	854a                	mv	a0,s2
    80004cbe:	70a2                	ld	ra,40(sp)
    80004cc0:	7402                	ld	s0,32(sp)
    80004cc2:	64e2                	ld	s1,24(sp)
    80004cc4:	6942                	ld	s2,16(sp)
    80004cc6:	69a2                	ld	s3,8(sp)
    80004cc8:	6145                	addi	sp,sp,48
    80004cca:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004ccc:	6908                	ld	a0,16(a0)
    80004cce:	00000097          	auipc	ra,0x0
    80004cd2:	3c0080e7          	jalr	960(ra) # 8000508e <piperead>
    80004cd6:	892a                	mv	s2,a0
    80004cd8:	b7d5                	j	80004cbc <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004cda:	02451783          	lh	a5,36(a0)
    80004cde:	03079693          	slli	a3,a5,0x30
    80004ce2:	92c1                	srli	a3,a3,0x30
    80004ce4:	4725                	li	a4,9
    80004ce6:	02d76863          	bltu	a4,a3,80004d16 <fileread+0xba>
    80004cea:	0792                	slli	a5,a5,0x4
    80004cec:	0001d717          	auipc	a4,0x1d
    80004cf0:	62470713          	addi	a4,a4,1572 # 80022310 <devsw>
    80004cf4:	97ba                	add	a5,a5,a4
    80004cf6:	639c                	ld	a5,0(a5)
    80004cf8:	c38d                	beqz	a5,80004d1a <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004cfa:	4505                	li	a0,1
    80004cfc:	9782                	jalr	a5
    80004cfe:	892a                	mv	s2,a0
    80004d00:	bf75                	j	80004cbc <fileread+0x60>
    panic("fileread");
    80004d02:	00004517          	auipc	a0,0x4
    80004d06:	9e650513          	addi	a0,a0,-1562 # 800086e8 <syscalls+0x2a0>
    80004d0a:	ffffc097          	auipc	ra,0xffffc
    80004d0e:	82e080e7          	jalr	-2002(ra) # 80000538 <panic>
    return -1;
    80004d12:	597d                	li	s2,-1
    80004d14:	b765                	j	80004cbc <fileread+0x60>
      return -1;
    80004d16:	597d                	li	s2,-1
    80004d18:	b755                	j	80004cbc <fileread+0x60>
    80004d1a:	597d                	li	s2,-1
    80004d1c:	b745                	j	80004cbc <fileread+0x60>

0000000080004d1e <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004d1e:	715d                	addi	sp,sp,-80
    80004d20:	e486                	sd	ra,72(sp)
    80004d22:	e0a2                	sd	s0,64(sp)
    80004d24:	fc26                	sd	s1,56(sp)
    80004d26:	f84a                	sd	s2,48(sp)
    80004d28:	f44e                	sd	s3,40(sp)
    80004d2a:	f052                	sd	s4,32(sp)
    80004d2c:	ec56                	sd	s5,24(sp)
    80004d2e:	e85a                	sd	s6,16(sp)
    80004d30:	e45e                	sd	s7,8(sp)
    80004d32:	e062                	sd	s8,0(sp)
    80004d34:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004d36:	00954783          	lbu	a5,9(a0)
    80004d3a:	10078663          	beqz	a5,80004e46 <filewrite+0x128>
    80004d3e:	892a                	mv	s2,a0
    80004d40:	8aae                	mv	s5,a1
    80004d42:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004d44:	411c                	lw	a5,0(a0)
    80004d46:	4705                	li	a4,1
    80004d48:	02e78263          	beq	a5,a4,80004d6c <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004d4c:	470d                	li	a4,3
    80004d4e:	02e78663          	beq	a5,a4,80004d7a <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004d52:	4709                	li	a4,2
    80004d54:	0ee79163          	bne	a5,a4,80004e36 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004d58:	0ac05d63          	blez	a2,80004e12 <filewrite+0xf4>
    int i = 0;
    80004d5c:	4981                	li	s3,0
    80004d5e:	6b05                	lui	s6,0x1
    80004d60:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004d64:	6b85                	lui	s7,0x1
    80004d66:	c00b8b9b          	addiw	s7,s7,-1024
    80004d6a:	a861                	j	80004e02 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004d6c:	6908                	ld	a0,16(a0)
    80004d6e:	00000097          	auipc	ra,0x0
    80004d72:	22e080e7          	jalr	558(ra) # 80004f9c <pipewrite>
    80004d76:	8a2a                	mv	s4,a0
    80004d78:	a045                	j	80004e18 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004d7a:	02451783          	lh	a5,36(a0)
    80004d7e:	03079693          	slli	a3,a5,0x30
    80004d82:	92c1                	srli	a3,a3,0x30
    80004d84:	4725                	li	a4,9
    80004d86:	0cd76263          	bltu	a4,a3,80004e4a <filewrite+0x12c>
    80004d8a:	0792                	slli	a5,a5,0x4
    80004d8c:	0001d717          	auipc	a4,0x1d
    80004d90:	58470713          	addi	a4,a4,1412 # 80022310 <devsw>
    80004d94:	97ba                	add	a5,a5,a4
    80004d96:	679c                	ld	a5,8(a5)
    80004d98:	cbdd                	beqz	a5,80004e4e <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004d9a:	4505                	li	a0,1
    80004d9c:	9782                	jalr	a5
    80004d9e:	8a2a                	mv	s4,a0
    80004da0:	a8a5                	j	80004e18 <filewrite+0xfa>
    80004da2:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004da6:	00000097          	auipc	ra,0x0
    80004daa:	8b0080e7          	jalr	-1872(ra) # 80004656 <begin_op>
      ilock(f->ip);
    80004dae:	01893503          	ld	a0,24(s2)
    80004db2:	fffff097          	auipc	ra,0xfffff
    80004db6:	ed2080e7          	jalr	-302(ra) # 80003c84 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004dba:	8762                	mv	a4,s8
    80004dbc:	02092683          	lw	a3,32(s2)
    80004dc0:	01598633          	add	a2,s3,s5
    80004dc4:	4585                	li	a1,1
    80004dc6:	01893503          	ld	a0,24(s2)
    80004dca:	fffff097          	auipc	ra,0xfffff
    80004dce:	266080e7          	jalr	614(ra) # 80004030 <writei>
    80004dd2:	84aa                	mv	s1,a0
    80004dd4:	00a05763          	blez	a0,80004de2 <filewrite+0xc4>
        f->off += r;
    80004dd8:	02092783          	lw	a5,32(s2)
    80004ddc:	9fa9                	addw	a5,a5,a0
    80004dde:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004de2:	01893503          	ld	a0,24(s2)
    80004de6:	fffff097          	auipc	ra,0xfffff
    80004dea:	f60080e7          	jalr	-160(ra) # 80003d46 <iunlock>
      end_op();
    80004dee:	00000097          	auipc	ra,0x0
    80004df2:	8e8080e7          	jalr	-1816(ra) # 800046d6 <end_op>

      if(r != n1){
    80004df6:	009c1f63          	bne	s8,s1,80004e14 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004dfa:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004dfe:	0149db63          	bge	s3,s4,80004e14 <filewrite+0xf6>
      int n1 = n - i;
    80004e02:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004e06:	84be                	mv	s1,a5
    80004e08:	2781                	sext.w	a5,a5
    80004e0a:	f8fb5ce3          	bge	s6,a5,80004da2 <filewrite+0x84>
    80004e0e:	84de                	mv	s1,s7
    80004e10:	bf49                	j	80004da2 <filewrite+0x84>
    int i = 0;
    80004e12:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004e14:	013a1f63          	bne	s4,s3,80004e32 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004e18:	8552                	mv	a0,s4
    80004e1a:	60a6                	ld	ra,72(sp)
    80004e1c:	6406                	ld	s0,64(sp)
    80004e1e:	74e2                	ld	s1,56(sp)
    80004e20:	7942                	ld	s2,48(sp)
    80004e22:	79a2                	ld	s3,40(sp)
    80004e24:	7a02                	ld	s4,32(sp)
    80004e26:	6ae2                	ld	s5,24(sp)
    80004e28:	6b42                	ld	s6,16(sp)
    80004e2a:	6ba2                	ld	s7,8(sp)
    80004e2c:	6c02                	ld	s8,0(sp)
    80004e2e:	6161                	addi	sp,sp,80
    80004e30:	8082                	ret
    ret = (i == n ? n : -1);
    80004e32:	5a7d                	li	s4,-1
    80004e34:	b7d5                	j	80004e18 <filewrite+0xfa>
    panic("filewrite");
    80004e36:	00004517          	auipc	a0,0x4
    80004e3a:	8c250513          	addi	a0,a0,-1854 # 800086f8 <syscalls+0x2b0>
    80004e3e:	ffffb097          	auipc	ra,0xffffb
    80004e42:	6fa080e7          	jalr	1786(ra) # 80000538 <panic>
    return -1;
    80004e46:	5a7d                	li	s4,-1
    80004e48:	bfc1                	j	80004e18 <filewrite+0xfa>
      return -1;
    80004e4a:	5a7d                	li	s4,-1
    80004e4c:	b7f1                	j	80004e18 <filewrite+0xfa>
    80004e4e:	5a7d                	li	s4,-1
    80004e50:	b7e1                	j	80004e18 <filewrite+0xfa>

0000000080004e52 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004e52:	7179                	addi	sp,sp,-48
    80004e54:	f406                	sd	ra,40(sp)
    80004e56:	f022                	sd	s0,32(sp)
    80004e58:	ec26                	sd	s1,24(sp)
    80004e5a:	e84a                	sd	s2,16(sp)
    80004e5c:	e44e                	sd	s3,8(sp)
    80004e5e:	e052                	sd	s4,0(sp)
    80004e60:	1800                	addi	s0,sp,48
    80004e62:	84aa                	mv	s1,a0
    80004e64:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004e66:	0005b023          	sd	zero,0(a1)
    80004e6a:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004e6e:	00000097          	auipc	ra,0x0
    80004e72:	bf8080e7          	jalr	-1032(ra) # 80004a66 <filealloc>
    80004e76:	e088                	sd	a0,0(s1)
    80004e78:	c551                	beqz	a0,80004f04 <pipealloc+0xb2>
    80004e7a:	00000097          	auipc	ra,0x0
    80004e7e:	bec080e7          	jalr	-1044(ra) # 80004a66 <filealloc>
    80004e82:	00aa3023          	sd	a0,0(s4)
    80004e86:	c92d                	beqz	a0,80004ef8 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004e88:	ffffc097          	auipc	ra,0xffffc
    80004e8c:	c58080e7          	jalr	-936(ra) # 80000ae0 <kalloc>
    80004e90:	892a                	mv	s2,a0
    80004e92:	c125                	beqz	a0,80004ef2 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004e94:	4985                	li	s3,1
    80004e96:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004e9a:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004e9e:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004ea2:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004ea6:	00004597          	auipc	a1,0x4
    80004eaa:	86258593          	addi	a1,a1,-1950 # 80008708 <syscalls+0x2c0>
    80004eae:	ffffc097          	auipc	ra,0xffffc
    80004eb2:	c92080e7          	jalr	-878(ra) # 80000b40 <initlock>
  (*f0)->type = FD_PIPE;
    80004eb6:	609c                	ld	a5,0(s1)
    80004eb8:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004ebc:	609c                	ld	a5,0(s1)
    80004ebe:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004ec2:	609c                	ld	a5,0(s1)
    80004ec4:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004ec8:	609c                	ld	a5,0(s1)
    80004eca:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004ece:	000a3783          	ld	a5,0(s4)
    80004ed2:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004ed6:	000a3783          	ld	a5,0(s4)
    80004eda:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004ede:	000a3783          	ld	a5,0(s4)
    80004ee2:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004ee6:	000a3783          	ld	a5,0(s4)
    80004eea:	0127b823          	sd	s2,16(a5)
  return 0;
    80004eee:	4501                	li	a0,0
    80004ef0:	a025                	j	80004f18 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004ef2:	6088                	ld	a0,0(s1)
    80004ef4:	e501                	bnez	a0,80004efc <pipealloc+0xaa>
    80004ef6:	a039                	j	80004f04 <pipealloc+0xb2>
    80004ef8:	6088                	ld	a0,0(s1)
    80004efa:	c51d                	beqz	a0,80004f28 <pipealloc+0xd6>
    fileclose(*f0);
    80004efc:	00000097          	auipc	ra,0x0
    80004f00:	c26080e7          	jalr	-986(ra) # 80004b22 <fileclose>
  if(*f1)
    80004f04:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004f08:	557d                	li	a0,-1
  if(*f1)
    80004f0a:	c799                	beqz	a5,80004f18 <pipealloc+0xc6>
    fileclose(*f1);
    80004f0c:	853e                	mv	a0,a5
    80004f0e:	00000097          	auipc	ra,0x0
    80004f12:	c14080e7          	jalr	-1004(ra) # 80004b22 <fileclose>
  return -1;
    80004f16:	557d                	li	a0,-1
}
    80004f18:	70a2                	ld	ra,40(sp)
    80004f1a:	7402                	ld	s0,32(sp)
    80004f1c:	64e2                	ld	s1,24(sp)
    80004f1e:	6942                	ld	s2,16(sp)
    80004f20:	69a2                	ld	s3,8(sp)
    80004f22:	6a02                	ld	s4,0(sp)
    80004f24:	6145                	addi	sp,sp,48
    80004f26:	8082                	ret
  return -1;
    80004f28:	557d                	li	a0,-1
    80004f2a:	b7fd                	j	80004f18 <pipealloc+0xc6>

0000000080004f2c <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004f2c:	1101                	addi	sp,sp,-32
    80004f2e:	ec06                	sd	ra,24(sp)
    80004f30:	e822                	sd	s0,16(sp)
    80004f32:	e426                	sd	s1,8(sp)
    80004f34:	e04a                	sd	s2,0(sp)
    80004f36:	1000                	addi	s0,sp,32
    80004f38:	84aa                	mv	s1,a0
    80004f3a:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004f3c:	ffffc097          	auipc	ra,0xffffc
    80004f40:	c94080e7          	jalr	-876(ra) # 80000bd0 <acquire>
  if(writable){
    80004f44:	02090d63          	beqz	s2,80004f7e <pipeclose+0x52>
    pi->writeopen = 0;
    80004f48:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004f4c:	21848513          	addi	a0,s1,536
    80004f50:	ffffd097          	auipc	ra,0xffffd
    80004f54:	54a080e7          	jalr	1354(ra) # 8000249a <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004f58:	2204b783          	ld	a5,544(s1)
    80004f5c:	eb95                	bnez	a5,80004f90 <pipeclose+0x64>
    release(&pi->lock);
    80004f5e:	8526                	mv	a0,s1
    80004f60:	ffffc097          	auipc	ra,0xffffc
    80004f64:	d24080e7          	jalr	-732(ra) # 80000c84 <release>
    kfree((char*)pi);
    80004f68:	8526                	mv	a0,s1
    80004f6a:	ffffc097          	auipc	ra,0xffffc
    80004f6e:	a7a080e7          	jalr	-1414(ra) # 800009e4 <kfree>
  } else
    release(&pi->lock);
}
    80004f72:	60e2                	ld	ra,24(sp)
    80004f74:	6442                	ld	s0,16(sp)
    80004f76:	64a2                	ld	s1,8(sp)
    80004f78:	6902                	ld	s2,0(sp)
    80004f7a:	6105                	addi	sp,sp,32
    80004f7c:	8082                	ret
    pi->readopen = 0;
    80004f7e:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004f82:	21c48513          	addi	a0,s1,540
    80004f86:	ffffd097          	auipc	ra,0xffffd
    80004f8a:	514080e7          	jalr	1300(ra) # 8000249a <wakeup>
    80004f8e:	b7e9                	j	80004f58 <pipeclose+0x2c>
    release(&pi->lock);
    80004f90:	8526                	mv	a0,s1
    80004f92:	ffffc097          	auipc	ra,0xffffc
    80004f96:	cf2080e7          	jalr	-782(ra) # 80000c84 <release>
}
    80004f9a:	bfe1                	j	80004f72 <pipeclose+0x46>

0000000080004f9c <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004f9c:	711d                	addi	sp,sp,-96
    80004f9e:	ec86                	sd	ra,88(sp)
    80004fa0:	e8a2                	sd	s0,80(sp)
    80004fa2:	e4a6                	sd	s1,72(sp)
    80004fa4:	e0ca                	sd	s2,64(sp)
    80004fa6:	fc4e                	sd	s3,56(sp)
    80004fa8:	f852                	sd	s4,48(sp)
    80004faa:	f456                	sd	s5,40(sp)
    80004fac:	f05a                	sd	s6,32(sp)
    80004fae:	ec5e                	sd	s7,24(sp)
    80004fb0:	e862                	sd	s8,16(sp)
    80004fb2:	1080                	addi	s0,sp,96
    80004fb4:	84aa                	mv	s1,a0
    80004fb6:	8aae                	mv	s5,a1
    80004fb8:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004fba:	ffffd097          	auipc	ra,0xffffd
    80004fbe:	9dc080e7          	jalr	-1572(ra) # 80001996 <myproc>
    80004fc2:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004fc4:	8526                	mv	a0,s1
    80004fc6:	ffffc097          	auipc	ra,0xffffc
    80004fca:	c0a080e7          	jalr	-1014(ra) # 80000bd0 <acquire>
  while(i < n){
    80004fce:	0b405363          	blez	s4,80005074 <pipewrite+0xd8>
  int i = 0;
    80004fd2:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004fd4:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004fd6:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004fda:	21c48b93          	addi	s7,s1,540
    80004fde:	a089                	j	80005020 <pipewrite+0x84>
      release(&pi->lock);
    80004fe0:	8526                	mv	a0,s1
    80004fe2:	ffffc097          	auipc	ra,0xffffc
    80004fe6:	ca2080e7          	jalr	-862(ra) # 80000c84 <release>
      return -1;
    80004fea:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004fec:	854a                	mv	a0,s2
    80004fee:	60e6                	ld	ra,88(sp)
    80004ff0:	6446                	ld	s0,80(sp)
    80004ff2:	64a6                	ld	s1,72(sp)
    80004ff4:	6906                	ld	s2,64(sp)
    80004ff6:	79e2                	ld	s3,56(sp)
    80004ff8:	7a42                	ld	s4,48(sp)
    80004ffa:	7aa2                	ld	s5,40(sp)
    80004ffc:	7b02                	ld	s6,32(sp)
    80004ffe:	6be2                	ld	s7,24(sp)
    80005000:	6c42                	ld	s8,16(sp)
    80005002:	6125                	addi	sp,sp,96
    80005004:	8082                	ret
      wakeup(&pi->nread);
    80005006:	8562                	mv	a0,s8
    80005008:	ffffd097          	auipc	ra,0xffffd
    8000500c:	492080e7          	jalr	1170(ra) # 8000249a <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80005010:	85a6                	mv	a1,s1
    80005012:	855e                	mv	a0,s7
    80005014:	ffffd097          	auipc	ra,0xffffd
    80005018:	2f4080e7          	jalr	756(ra) # 80002308 <sleep>
  while(i < n){
    8000501c:	05495d63          	bge	s2,s4,80005076 <pipewrite+0xda>
    if(pi->readopen == 0 || pr->killed){
    80005020:	2204a783          	lw	a5,544(s1)
    80005024:	dfd5                	beqz	a5,80004fe0 <pipewrite+0x44>
    80005026:	0289a783          	lw	a5,40(s3)
    8000502a:	fbdd                	bnez	a5,80004fe0 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    8000502c:	2184a783          	lw	a5,536(s1)
    80005030:	21c4a703          	lw	a4,540(s1)
    80005034:	2007879b          	addiw	a5,a5,512
    80005038:	fcf707e3          	beq	a4,a5,80005006 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000503c:	4685                	li	a3,1
    8000503e:	01590633          	add	a2,s2,s5
    80005042:	faf40593          	addi	a1,s0,-81
    80005046:	0709b503          	ld	a0,112(s3)
    8000504a:	ffffc097          	auipc	ra,0xffffc
    8000504e:	698080e7          	jalr	1688(ra) # 800016e2 <copyin>
    80005052:	03650263          	beq	a0,s6,80005076 <pipewrite+0xda>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80005056:	21c4a783          	lw	a5,540(s1)
    8000505a:	0017871b          	addiw	a4,a5,1
    8000505e:	20e4ae23          	sw	a4,540(s1)
    80005062:	1ff7f793          	andi	a5,a5,511
    80005066:	97a6                	add	a5,a5,s1
    80005068:	faf44703          	lbu	a4,-81(s0)
    8000506c:	00e78c23          	sb	a4,24(a5)
      i++;
    80005070:	2905                	addiw	s2,s2,1
    80005072:	b76d                	j	8000501c <pipewrite+0x80>
  int i = 0;
    80005074:	4901                	li	s2,0
  wakeup(&pi->nread);
    80005076:	21848513          	addi	a0,s1,536
    8000507a:	ffffd097          	auipc	ra,0xffffd
    8000507e:	420080e7          	jalr	1056(ra) # 8000249a <wakeup>
  release(&pi->lock);
    80005082:	8526                	mv	a0,s1
    80005084:	ffffc097          	auipc	ra,0xffffc
    80005088:	c00080e7          	jalr	-1024(ra) # 80000c84 <release>
  return i;
    8000508c:	b785                	j	80004fec <pipewrite+0x50>

000000008000508e <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    8000508e:	715d                	addi	sp,sp,-80
    80005090:	e486                	sd	ra,72(sp)
    80005092:	e0a2                	sd	s0,64(sp)
    80005094:	fc26                	sd	s1,56(sp)
    80005096:	f84a                	sd	s2,48(sp)
    80005098:	f44e                	sd	s3,40(sp)
    8000509a:	f052                	sd	s4,32(sp)
    8000509c:	ec56                	sd	s5,24(sp)
    8000509e:	e85a                	sd	s6,16(sp)
    800050a0:	0880                	addi	s0,sp,80
    800050a2:	84aa                	mv	s1,a0
    800050a4:	892e                	mv	s2,a1
    800050a6:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    800050a8:	ffffd097          	auipc	ra,0xffffd
    800050ac:	8ee080e7          	jalr	-1810(ra) # 80001996 <myproc>
    800050b0:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    800050b2:	8526                	mv	a0,s1
    800050b4:	ffffc097          	auipc	ra,0xffffc
    800050b8:	b1c080e7          	jalr	-1252(ra) # 80000bd0 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800050bc:	2184a703          	lw	a4,536(s1)
    800050c0:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800050c4:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800050c8:	02f71463          	bne	a4,a5,800050f0 <piperead+0x62>
    800050cc:	2244a783          	lw	a5,548(s1)
    800050d0:	c385                	beqz	a5,800050f0 <piperead+0x62>
    if(pr->killed){
    800050d2:	028a2783          	lw	a5,40(s4)
    800050d6:	ebc1                	bnez	a5,80005166 <piperead+0xd8>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800050d8:	85a6                	mv	a1,s1
    800050da:	854e                	mv	a0,s3
    800050dc:	ffffd097          	auipc	ra,0xffffd
    800050e0:	22c080e7          	jalr	556(ra) # 80002308 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800050e4:	2184a703          	lw	a4,536(s1)
    800050e8:	21c4a783          	lw	a5,540(s1)
    800050ec:	fef700e3          	beq	a4,a5,800050cc <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800050f0:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800050f2:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800050f4:	05505363          	blez	s5,8000513a <piperead+0xac>
    if(pi->nread == pi->nwrite)
    800050f8:	2184a783          	lw	a5,536(s1)
    800050fc:	21c4a703          	lw	a4,540(s1)
    80005100:	02f70d63          	beq	a4,a5,8000513a <piperead+0xac>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005104:	0017871b          	addiw	a4,a5,1
    80005108:	20e4ac23          	sw	a4,536(s1)
    8000510c:	1ff7f793          	andi	a5,a5,511
    80005110:	97a6                	add	a5,a5,s1
    80005112:	0187c783          	lbu	a5,24(a5)
    80005116:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000511a:	4685                	li	a3,1
    8000511c:	fbf40613          	addi	a2,s0,-65
    80005120:	85ca                	mv	a1,s2
    80005122:	070a3503          	ld	a0,112(s4)
    80005126:	ffffc097          	auipc	ra,0xffffc
    8000512a:	530080e7          	jalr	1328(ra) # 80001656 <copyout>
    8000512e:	01650663          	beq	a0,s6,8000513a <piperead+0xac>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005132:	2985                	addiw	s3,s3,1
    80005134:	0905                	addi	s2,s2,1
    80005136:	fd3a91e3          	bne	s5,s3,800050f8 <piperead+0x6a>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    8000513a:	21c48513          	addi	a0,s1,540
    8000513e:	ffffd097          	auipc	ra,0xffffd
    80005142:	35c080e7          	jalr	860(ra) # 8000249a <wakeup>
  release(&pi->lock);
    80005146:	8526                	mv	a0,s1
    80005148:	ffffc097          	auipc	ra,0xffffc
    8000514c:	b3c080e7          	jalr	-1220(ra) # 80000c84 <release>
  return i;
}
    80005150:	854e                	mv	a0,s3
    80005152:	60a6                	ld	ra,72(sp)
    80005154:	6406                	ld	s0,64(sp)
    80005156:	74e2                	ld	s1,56(sp)
    80005158:	7942                	ld	s2,48(sp)
    8000515a:	79a2                	ld	s3,40(sp)
    8000515c:	7a02                	ld	s4,32(sp)
    8000515e:	6ae2                	ld	s5,24(sp)
    80005160:	6b42                	ld	s6,16(sp)
    80005162:	6161                	addi	sp,sp,80
    80005164:	8082                	ret
      release(&pi->lock);
    80005166:	8526                	mv	a0,s1
    80005168:	ffffc097          	auipc	ra,0xffffc
    8000516c:	b1c080e7          	jalr	-1252(ra) # 80000c84 <release>
      return -1;
    80005170:	59fd                	li	s3,-1
    80005172:	bff9                	j	80005150 <piperead+0xc2>

0000000080005174 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80005174:	de010113          	addi	sp,sp,-544
    80005178:	20113c23          	sd	ra,536(sp)
    8000517c:	20813823          	sd	s0,528(sp)
    80005180:	20913423          	sd	s1,520(sp)
    80005184:	21213023          	sd	s2,512(sp)
    80005188:	ffce                	sd	s3,504(sp)
    8000518a:	fbd2                	sd	s4,496(sp)
    8000518c:	f7d6                	sd	s5,488(sp)
    8000518e:	f3da                	sd	s6,480(sp)
    80005190:	efde                	sd	s7,472(sp)
    80005192:	ebe2                	sd	s8,464(sp)
    80005194:	e7e6                	sd	s9,456(sp)
    80005196:	e3ea                	sd	s10,448(sp)
    80005198:	ff6e                	sd	s11,440(sp)
    8000519a:	1400                	addi	s0,sp,544
    8000519c:	892a                	mv	s2,a0
    8000519e:	dea43423          	sd	a0,-536(s0)
    800051a2:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800051a6:	ffffc097          	auipc	ra,0xffffc
    800051aa:	7f0080e7          	jalr	2032(ra) # 80001996 <myproc>
    800051ae:	84aa                	mv	s1,a0

  begin_op();
    800051b0:	fffff097          	auipc	ra,0xfffff
    800051b4:	4a6080e7          	jalr	1190(ra) # 80004656 <begin_op>

  if((ip = namei(path)) == 0){
    800051b8:	854a                	mv	a0,s2
    800051ba:	fffff097          	auipc	ra,0xfffff
    800051be:	280080e7          	jalr	640(ra) # 8000443a <namei>
    800051c2:	c93d                	beqz	a0,80005238 <exec+0xc4>
    800051c4:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    800051c6:	fffff097          	auipc	ra,0xfffff
    800051ca:	abe080e7          	jalr	-1346(ra) # 80003c84 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800051ce:	04000713          	li	a4,64
    800051d2:	4681                	li	a3,0
    800051d4:	e5040613          	addi	a2,s0,-432
    800051d8:	4581                	li	a1,0
    800051da:	8556                	mv	a0,s5
    800051dc:	fffff097          	auipc	ra,0xfffff
    800051e0:	d5c080e7          	jalr	-676(ra) # 80003f38 <readi>
    800051e4:	04000793          	li	a5,64
    800051e8:	00f51a63          	bne	a0,a5,800051fc <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    800051ec:	e5042703          	lw	a4,-432(s0)
    800051f0:	464c47b7          	lui	a5,0x464c4
    800051f4:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800051f8:	04f70663          	beq	a4,a5,80005244 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800051fc:	8556                	mv	a0,s5
    800051fe:	fffff097          	auipc	ra,0xfffff
    80005202:	ce8080e7          	jalr	-792(ra) # 80003ee6 <iunlockput>
    end_op();
    80005206:	fffff097          	auipc	ra,0xfffff
    8000520a:	4d0080e7          	jalr	1232(ra) # 800046d6 <end_op>
  }
  return -1;
    8000520e:	557d                	li	a0,-1
}
    80005210:	21813083          	ld	ra,536(sp)
    80005214:	21013403          	ld	s0,528(sp)
    80005218:	20813483          	ld	s1,520(sp)
    8000521c:	20013903          	ld	s2,512(sp)
    80005220:	79fe                	ld	s3,504(sp)
    80005222:	7a5e                	ld	s4,496(sp)
    80005224:	7abe                	ld	s5,488(sp)
    80005226:	7b1e                	ld	s6,480(sp)
    80005228:	6bfe                	ld	s7,472(sp)
    8000522a:	6c5e                	ld	s8,464(sp)
    8000522c:	6cbe                	ld	s9,456(sp)
    8000522e:	6d1e                	ld	s10,448(sp)
    80005230:	7dfa                	ld	s11,440(sp)
    80005232:	22010113          	addi	sp,sp,544
    80005236:	8082                	ret
    end_op();
    80005238:	fffff097          	auipc	ra,0xfffff
    8000523c:	49e080e7          	jalr	1182(ra) # 800046d6 <end_op>
    return -1;
    80005240:	557d                	li	a0,-1
    80005242:	b7f9                	j	80005210 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80005244:	8526                	mv	a0,s1
    80005246:	ffffd097          	auipc	ra,0xffffd
    8000524a:	814080e7          	jalr	-2028(ra) # 80001a5a <proc_pagetable>
    8000524e:	8b2a                	mv	s6,a0
    80005250:	d555                	beqz	a0,800051fc <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005252:	e7042783          	lw	a5,-400(s0)
    80005256:	e8845703          	lhu	a4,-376(s0)
    8000525a:	c735                	beqz	a4,800052c6 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000525c:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000525e:	e0043423          	sd	zero,-504(s0)
    if((ph.vaddr % PGSIZE) != 0)
    80005262:	6a05                	lui	s4,0x1
    80005264:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80005268:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    8000526c:	6d85                	lui	s11,0x1
    8000526e:	7d7d                	lui	s10,0xfffff
    80005270:	ac1d                	j	800054a6 <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005272:	00003517          	auipc	a0,0x3
    80005276:	49e50513          	addi	a0,a0,1182 # 80008710 <syscalls+0x2c8>
    8000527a:	ffffb097          	auipc	ra,0xffffb
    8000527e:	2be080e7          	jalr	702(ra) # 80000538 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005282:	874a                	mv	a4,s2
    80005284:	009c86bb          	addw	a3,s9,s1
    80005288:	4581                	li	a1,0
    8000528a:	8556                	mv	a0,s5
    8000528c:	fffff097          	auipc	ra,0xfffff
    80005290:	cac080e7          	jalr	-852(ra) # 80003f38 <readi>
    80005294:	2501                	sext.w	a0,a0
    80005296:	1aa91863          	bne	s2,a0,80005446 <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    8000529a:	009d84bb          	addw	s1,s11,s1
    8000529e:	013d09bb          	addw	s3,s10,s3
    800052a2:	1f74f263          	bgeu	s1,s7,80005486 <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    800052a6:	02049593          	slli	a1,s1,0x20
    800052aa:	9181                	srli	a1,a1,0x20
    800052ac:	95e2                	add	a1,a1,s8
    800052ae:	855a                	mv	a0,s6
    800052b0:	ffffc097          	auipc	ra,0xffffc
    800052b4:	da2080e7          	jalr	-606(ra) # 80001052 <walkaddr>
    800052b8:	862a                	mv	a2,a0
    if(pa == 0)
    800052ba:	dd45                	beqz	a0,80005272 <exec+0xfe>
      n = PGSIZE;
    800052bc:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    800052be:	fd49f2e3          	bgeu	s3,s4,80005282 <exec+0x10e>
      n = sz - i;
    800052c2:	894e                	mv	s2,s3
    800052c4:	bf7d                	j	80005282 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800052c6:	4481                	li	s1,0
  iunlockput(ip);
    800052c8:	8556                	mv	a0,s5
    800052ca:	fffff097          	auipc	ra,0xfffff
    800052ce:	c1c080e7          	jalr	-996(ra) # 80003ee6 <iunlockput>
  end_op();
    800052d2:	fffff097          	auipc	ra,0xfffff
    800052d6:	404080e7          	jalr	1028(ra) # 800046d6 <end_op>
  p = myproc();
    800052da:	ffffc097          	auipc	ra,0xffffc
    800052de:	6bc080e7          	jalr	1724(ra) # 80001996 <myproc>
    800052e2:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    800052e4:	06853d03          	ld	s10,104(a0)
  sz = PGROUNDUP(sz);
    800052e8:	6785                	lui	a5,0x1
    800052ea:	17fd                	addi	a5,a5,-1
    800052ec:	94be                	add	s1,s1,a5
    800052ee:	77fd                	lui	a5,0xfffff
    800052f0:	8fe5                	and	a5,a5,s1
    800052f2:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800052f6:	6609                	lui	a2,0x2
    800052f8:	963e                	add	a2,a2,a5
    800052fa:	85be                	mv	a1,a5
    800052fc:	855a                	mv	a0,s6
    800052fe:	ffffc097          	auipc	ra,0xffffc
    80005302:	108080e7          	jalr	264(ra) # 80001406 <uvmalloc>
    80005306:	8c2a                	mv	s8,a0
  ip = 0;
    80005308:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    8000530a:	12050e63          	beqz	a0,80005446 <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    8000530e:	75f9                	lui	a1,0xffffe
    80005310:	95aa                	add	a1,a1,a0
    80005312:	855a                	mv	a0,s6
    80005314:	ffffc097          	auipc	ra,0xffffc
    80005318:	310080e7          	jalr	784(ra) # 80001624 <uvmclear>
  stackbase = sp - PGSIZE;
    8000531c:	7afd                	lui	s5,0xfffff
    8000531e:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80005320:	df043783          	ld	a5,-528(s0)
    80005324:	6388                	ld	a0,0(a5)
    80005326:	c925                	beqz	a0,80005396 <exec+0x222>
    80005328:	e9040993          	addi	s3,s0,-368
    8000532c:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80005330:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005332:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80005334:	ffffc097          	auipc	ra,0xffffc
    80005338:	b14080e7          	jalr	-1260(ra) # 80000e48 <strlen>
    8000533c:	0015079b          	addiw	a5,a0,1
    80005340:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005344:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005348:	13596363          	bltu	s2,s5,8000546e <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    8000534c:	df043d83          	ld	s11,-528(s0)
    80005350:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80005354:	8552                	mv	a0,s4
    80005356:	ffffc097          	auipc	ra,0xffffc
    8000535a:	af2080e7          	jalr	-1294(ra) # 80000e48 <strlen>
    8000535e:	0015069b          	addiw	a3,a0,1
    80005362:	8652                	mv	a2,s4
    80005364:	85ca                	mv	a1,s2
    80005366:	855a                	mv	a0,s6
    80005368:	ffffc097          	auipc	ra,0xffffc
    8000536c:	2ee080e7          	jalr	750(ra) # 80001656 <copyout>
    80005370:	10054363          	bltz	a0,80005476 <exec+0x302>
    ustack[argc] = sp;
    80005374:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005378:	0485                	addi	s1,s1,1
    8000537a:	008d8793          	addi	a5,s11,8
    8000537e:	def43823          	sd	a5,-528(s0)
    80005382:	008db503          	ld	a0,8(s11)
    80005386:	c911                	beqz	a0,8000539a <exec+0x226>
    if(argc >= MAXARG)
    80005388:	09a1                	addi	s3,s3,8
    8000538a:	fb3c95e3          	bne	s9,s3,80005334 <exec+0x1c0>
  sz = sz1;
    8000538e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005392:	4a81                	li	s5,0
    80005394:	a84d                	j	80005446 <exec+0x2d2>
  sp = sz;
    80005396:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005398:	4481                	li	s1,0
  ustack[argc] = 0;
    8000539a:	00349793          	slli	a5,s1,0x3
    8000539e:	f9040713          	addi	a4,s0,-112
    800053a2:	97ba                	add	a5,a5,a4
    800053a4:	f007b023          	sd	zero,-256(a5) # ffffffffffffef00 <end+0xffffffff7ffdba58>
  sp -= (argc+1) * sizeof(uint64);
    800053a8:	00148693          	addi	a3,s1,1
    800053ac:	068e                	slli	a3,a3,0x3
    800053ae:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800053b2:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800053b6:	01597663          	bgeu	s2,s5,800053c2 <exec+0x24e>
  sz = sz1;
    800053ba:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800053be:	4a81                	li	s5,0
    800053c0:	a059                	j	80005446 <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800053c2:	e9040613          	addi	a2,s0,-368
    800053c6:	85ca                	mv	a1,s2
    800053c8:	855a                	mv	a0,s6
    800053ca:	ffffc097          	auipc	ra,0xffffc
    800053ce:	28c080e7          	jalr	652(ra) # 80001656 <copyout>
    800053d2:	0a054663          	bltz	a0,8000547e <exec+0x30a>
  p->trapframe->a1 = sp;
    800053d6:	078bb783          	ld	a5,120(s7) # 1078 <_entry-0x7fffef88>
    800053da:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800053de:	de843783          	ld	a5,-536(s0)
    800053e2:	0007c703          	lbu	a4,0(a5)
    800053e6:	cf11                	beqz	a4,80005402 <exec+0x28e>
    800053e8:	0785                	addi	a5,a5,1
    if(*s == '/')
    800053ea:	02f00693          	li	a3,47
    800053ee:	a039                	j	800053fc <exec+0x288>
      last = s+1;
    800053f0:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    800053f4:	0785                	addi	a5,a5,1
    800053f6:	fff7c703          	lbu	a4,-1(a5)
    800053fa:	c701                	beqz	a4,80005402 <exec+0x28e>
    if(*s == '/')
    800053fc:	fed71ce3          	bne	a4,a3,800053f4 <exec+0x280>
    80005400:	bfc5                	j	800053f0 <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    80005402:	4641                	li	a2,16
    80005404:	de843583          	ld	a1,-536(s0)
    80005408:	1b0b8513          	addi	a0,s7,432
    8000540c:	ffffc097          	auipc	ra,0xffffc
    80005410:	a0a080e7          	jalr	-1526(ra) # 80000e16 <safestrcpy>
  oldpagetable = p->pagetable;
    80005414:	070bb503          	ld	a0,112(s7)
  p->pagetable = pagetable;
    80005418:	076bb823          	sd	s6,112(s7)
  p->sz = sz;
    8000541c:	078bb423          	sd	s8,104(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005420:	078bb783          	ld	a5,120(s7)
    80005424:	e6843703          	ld	a4,-408(s0)
    80005428:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    8000542a:	078bb783          	ld	a5,120(s7)
    8000542e:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005432:	85ea                	mv	a1,s10
    80005434:	ffffc097          	auipc	ra,0xffffc
    80005438:	6c2080e7          	jalr	1730(ra) # 80001af6 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000543c:	0004851b          	sext.w	a0,s1
    80005440:	bbc1                	j	80005210 <exec+0x9c>
    80005442:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    80005446:	df843583          	ld	a1,-520(s0)
    8000544a:	855a                	mv	a0,s6
    8000544c:	ffffc097          	auipc	ra,0xffffc
    80005450:	6aa080e7          	jalr	1706(ra) # 80001af6 <proc_freepagetable>
  if(ip){
    80005454:	da0a94e3          	bnez	s5,800051fc <exec+0x88>
  return -1;
    80005458:	557d                	li	a0,-1
    8000545a:	bb5d                	j	80005210 <exec+0x9c>
    8000545c:	de943c23          	sd	s1,-520(s0)
    80005460:	b7dd                	j	80005446 <exec+0x2d2>
    80005462:	de943c23          	sd	s1,-520(s0)
    80005466:	b7c5                	j	80005446 <exec+0x2d2>
    80005468:	de943c23          	sd	s1,-520(s0)
    8000546c:	bfe9                	j	80005446 <exec+0x2d2>
  sz = sz1;
    8000546e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005472:	4a81                	li	s5,0
    80005474:	bfc9                	j	80005446 <exec+0x2d2>
  sz = sz1;
    80005476:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000547a:	4a81                	li	s5,0
    8000547c:	b7e9                	j	80005446 <exec+0x2d2>
  sz = sz1;
    8000547e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005482:	4a81                	li	s5,0
    80005484:	b7c9                	j	80005446 <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005486:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000548a:	e0843783          	ld	a5,-504(s0)
    8000548e:	0017869b          	addiw	a3,a5,1
    80005492:	e0d43423          	sd	a3,-504(s0)
    80005496:	e0043783          	ld	a5,-512(s0)
    8000549a:	0387879b          	addiw	a5,a5,56
    8000549e:	e8845703          	lhu	a4,-376(s0)
    800054a2:	e2e6d3e3          	bge	a3,a4,800052c8 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800054a6:	2781                	sext.w	a5,a5
    800054a8:	e0f43023          	sd	a5,-512(s0)
    800054ac:	03800713          	li	a4,56
    800054b0:	86be                	mv	a3,a5
    800054b2:	e1840613          	addi	a2,s0,-488
    800054b6:	4581                	li	a1,0
    800054b8:	8556                	mv	a0,s5
    800054ba:	fffff097          	auipc	ra,0xfffff
    800054be:	a7e080e7          	jalr	-1410(ra) # 80003f38 <readi>
    800054c2:	03800793          	li	a5,56
    800054c6:	f6f51ee3          	bne	a0,a5,80005442 <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    800054ca:	e1842783          	lw	a5,-488(s0)
    800054ce:	4705                	li	a4,1
    800054d0:	fae79de3          	bne	a5,a4,8000548a <exec+0x316>
    if(ph.memsz < ph.filesz)
    800054d4:	e4043603          	ld	a2,-448(s0)
    800054d8:	e3843783          	ld	a5,-456(s0)
    800054dc:	f8f660e3          	bltu	a2,a5,8000545c <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800054e0:	e2843783          	ld	a5,-472(s0)
    800054e4:	963e                	add	a2,a2,a5
    800054e6:	f6f66ee3          	bltu	a2,a5,80005462 <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800054ea:	85a6                	mv	a1,s1
    800054ec:	855a                	mv	a0,s6
    800054ee:	ffffc097          	auipc	ra,0xffffc
    800054f2:	f18080e7          	jalr	-232(ra) # 80001406 <uvmalloc>
    800054f6:	dea43c23          	sd	a0,-520(s0)
    800054fa:	d53d                	beqz	a0,80005468 <exec+0x2f4>
    if((ph.vaddr % PGSIZE) != 0)
    800054fc:	e2843c03          	ld	s8,-472(s0)
    80005500:	de043783          	ld	a5,-544(s0)
    80005504:	00fc77b3          	and	a5,s8,a5
    80005508:	ff9d                	bnez	a5,80005446 <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000550a:	e2042c83          	lw	s9,-480(s0)
    8000550e:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005512:	f60b8ae3          	beqz	s7,80005486 <exec+0x312>
    80005516:	89de                	mv	s3,s7
    80005518:	4481                	li	s1,0
    8000551a:	b371                	j	800052a6 <exec+0x132>

000000008000551c <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000551c:	7179                	addi	sp,sp,-48
    8000551e:	f406                	sd	ra,40(sp)
    80005520:	f022                	sd	s0,32(sp)
    80005522:	ec26                	sd	s1,24(sp)
    80005524:	e84a                	sd	s2,16(sp)
    80005526:	1800                	addi	s0,sp,48
    80005528:	892e                	mv	s2,a1
    8000552a:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    8000552c:	fdc40593          	addi	a1,s0,-36
    80005530:	ffffd097          	auipc	ra,0xffffd
    80005534:	7ec080e7          	jalr	2028(ra) # 80002d1c <argint>
    80005538:	04054063          	bltz	a0,80005578 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000553c:	fdc42703          	lw	a4,-36(s0)
    80005540:	47bd                	li	a5,15
    80005542:	02e7ed63          	bltu	a5,a4,8000557c <argfd+0x60>
    80005546:	ffffc097          	auipc	ra,0xffffc
    8000554a:	450080e7          	jalr	1104(ra) # 80001996 <myproc>
    8000554e:	fdc42703          	lw	a4,-36(s0)
    80005552:	01e70793          	addi	a5,a4,30
    80005556:	078e                	slli	a5,a5,0x3
    80005558:	953e                	add	a0,a0,a5
    8000555a:	611c                	ld	a5,0(a0)
    8000555c:	c395                	beqz	a5,80005580 <argfd+0x64>
    return -1;
  if(pfd)
    8000555e:	00090463          	beqz	s2,80005566 <argfd+0x4a>
    *pfd = fd;
    80005562:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005566:	4501                	li	a0,0
  if(pf)
    80005568:	c091                	beqz	s1,8000556c <argfd+0x50>
    *pf = f;
    8000556a:	e09c                	sd	a5,0(s1)
}
    8000556c:	70a2                	ld	ra,40(sp)
    8000556e:	7402                	ld	s0,32(sp)
    80005570:	64e2                	ld	s1,24(sp)
    80005572:	6942                	ld	s2,16(sp)
    80005574:	6145                	addi	sp,sp,48
    80005576:	8082                	ret
    return -1;
    80005578:	557d                	li	a0,-1
    8000557a:	bfcd                	j	8000556c <argfd+0x50>
    return -1;
    8000557c:	557d                	li	a0,-1
    8000557e:	b7fd                	j	8000556c <argfd+0x50>
    80005580:	557d                	li	a0,-1
    80005582:	b7ed                	j	8000556c <argfd+0x50>

0000000080005584 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005584:	1101                	addi	sp,sp,-32
    80005586:	ec06                	sd	ra,24(sp)
    80005588:	e822                	sd	s0,16(sp)
    8000558a:	e426                	sd	s1,8(sp)
    8000558c:	1000                	addi	s0,sp,32
    8000558e:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005590:	ffffc097          	auipc	ra,0xffffc
    80005594:	406080e7          	jalr	1030(ra) # 80001996 <myproc>
    80005598:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000559a:	0f050793          	addi	a5,a0,240
    8000559e:	4501                	li	a0,0
    800055a0:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800055a2:	6398                	ld	a4,0(a5)
    800055a4:	cb19                	beqz	a4,800055ba <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800055a6:	2505                	addiw	a0,a0,1
    800055a8:	07a1                	addi	a5,a5,8
    800055aa:	fed51ce3          	bne	a0,a3,800055a2 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800055ae:	557d                	li	a0,-1
}
    800055b0:	60e2                	ld	ra,24(sp)
    800055b2:	6442                	ld	s0,16(sp)
    800055b4:	64a2                	ld	s1,8(sp)
    800055b6:	6105                	addi	sp,sp,32
    800055b8:	8082                	ret
      p->ofile[fd] = f;
    800055ba:	01e50793          	addi	a5,a0,30
    800055be:	078e                	slli	a5,a5,0x3
    800055c0:	963e                	add	a2,a2,a5
    800055c2:	e204                	sd	s1,0(a2)
      return fd;
    800055c4:	b7f5                	j	800055b0 <fdalloc+0x2c>

00000000800055c6 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800055c6:	715d                	addi	sp,sp,-80
    800055c8:	e486                	sd	ra,72(sp)
    800055ca:	e0a2                	sd	s0,64(sp)
    800055cc:	fc26                	sd	s1,56(sp)
    800055ce:	f84a                	sd	s2,48(sp)
    800055d0:	f44e                	sd	s3,40(sp)
    800055d2:	f052                	sd	s4,32(sp)
    800055d4:	ec56                	sd	s5,24(sp)
    800055d6:	0880                	addi	s0,sp,80
    800055d8:	89ae                	mv	s3,a1
    800055da:	8ab2                	mv	s5,a2
    800055dc:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800055de:	fb040593          	addi	a1,s0,-80
    800055e2:	fffff097          	auipc	ra,0xfffff
    800055e6:	e76080e7          	jalr	-394(ra) # 80004458 <nameiparent>
    800055ea:	892a                	mv	s2,a0
    800055ec:	12050e63          	beqz	a0,80005728 <create+0x162>
    return 0;

  ilock(dp);
    800055f0:	ffffe097          	auipc	ra,0xffffe
    800055f4:	694080e7          	jalr	1684(ra) # 80003c84 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800055f8:	4601                	li	a2,0
    800055fa:	fb040593          	addi	a1,s0,-80
    800055fe:	854a                	mv	a0,s2
    80005600:	fffff097          	auipc	ra,0xfffff
    80005604:	b68080e7          	jalr	-1176(ra) # 80004168 <dirlookup>
    80005608:	84aa                	mv	s1,a0
    8000560a:	c921                	beqz	a0,8000565a <create+0x94>
    iunlockput(dp);
    8000560c:	854a                	mv	a0,s2
    8000560e:	fffff097          	auipc	ra,0xfffff
    80005612:	8d8080e7          	jalr	-1832(ra) # 80003ee6 <iunlockput>
    ilock(ip);
    80005616:	8526                	mv	a0,s1
    80005618:	ffffe097          	auipc	ra,0xffffe
    8000561c:	66c080e7          	jalr	1644(ra) # 80003c84 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005620:	2981                	sext.w	s3,s3
    80005622:	4789                	li	a5,2
    80005624:	02f99463          	bne	s3,a5,8000564c <create+0x86>
    80005628:	0444d783          	lhu	a5,68(s1)
    8000562c:	37f9                	addiw	a5,a5,-2
    8000562e:	17c2                	slli	a5,a5,0x30
    80005630:	93c1                	srli	a5,a5,0x30
    80005632:	4705                	li	a4,1
    80005634:	00f76c63          	bltu	a4,a5,8000564c <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005638:	8526                	mv	a0,s1
    8000563a:	60a6                	ld	ra,72(sp)
    8000563c:	6406                	ld	s0,64(sp)
    8000563e:	74e2                	ld	s1,56(sp)
    80005640:	7942                	ld	s2,48(sp)
    80005642:	79a2                	ld	s3,40(sp)
    80005644:	7a02                	ld	s4,32(sp)
    80005646:	6ae2                	ld	s5,24(sp)
    80005648:	6161                	addi	sp,sp,80
    8000564a:	8082                	ret
    iunlockput(ip);
    8000564c:	8526                	mv	a0,s1
    8000564e:	fffff097          	auipc	ra,0xfffff
    80005652:	898080e7          	jalr	-1896(ra) # 80003ee6 <iunlockput>
    return 0;
    80005656:	4481                	li	s1,0
    80005658:	b7c5                	j	80005638 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    8000565a:	85ce                	mv	a1,s3
    8000565c:	00092503          	lw	a0,0(s2)
    80005660:	ffffe097          	auipc	ra,0xffffe
    80005664:	48c080e7          	jalr	1164(ra) # 80003aec <ialloc>
    80005668:	84aa                	mv	s1,a0
    8000566a:	c521                	beqz	a0,800056b2 <create+0xec>
  ilock(ip);
    8000566c:	ffffe097          	auipc	ra,0xffffe
    80005670:	618080e7          	jalr	1560(ra) # 80003c84 <ilock>
  ip->major = major;
    80005674:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005678:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    8000567c:	4a05                	li	s4,1
    8000567e:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    80005682:	8526                	mv	a0,s1
    80005684:	ffffe097          	auipc	ra,0xffffe
    80005688:	536080e7          	jalr	1334(ra) # 80003bba <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000568c:	2981                	sext.w	s3,s3
    8000568e:	03498a63          	beq	s3,s4,800056c2 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    80005692:	40d0                	lw	a2,4(s1)
    80005694:	fb040593          	addi	a1,s0,-80
    80005698:	854a                	mv	a0,s2
    8000569a:	fffff097          	auipc	ra,0xfffff
    8000569e:	cde080e7          	jalr	-802(ra) # 80004378 <dirlink>
    800056a2:	06054b63          	bltz	a0,80005718 <create+0x152>
  iunlockput(dp);
    800056a6:	854a                	mv	a0,s2
    800056a8:	fffff097          	auipc	ra,0xfffff
    800056ac:	83e080e7          	jalr	-1986(ra) # 80003ee6 <iunlockput>
  return ip;
    800056b0:	b761                	j	80005638 <create+0x72>
    panic("create: ialloc");
    800056b2:	00003517          	auipc	a0,0x3
    800056b6:	07e50513          	addi	a0,a0,126 # 80008730 <syscalls+0x2e8>
    800056ba:	ffffb097          	auipc	ra,0xffffb
    800056be:	e7e080e7          	jalr	-386(ra) # 80000538 <panic>
    dp->nlink++;  // for ".."
    800056c2:	04a95783          	lhu	a5,74(s2)
    800056c6:	2785                	addiw	a5,a5,1
    800056c8:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800056cc:	854a                	mv	a0,s2
    800056ce:	ffffe097          	auipc	ra,0xffffe
    800056d2:	4ec080e7          	jalr	1260(ra) # 80003bba <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800056d6:	40d0                	lw	a2,4(s1)
    800056d8:	00003597          	auipc	a1,0x3
    800056dc:	06858593          	addi	a1,a1,104 # 80008740 <syscalls+0x2f8>
    800056e0:	8526                	mv	a0,s1
    800056e2:	fffff097          	auipc	ra,0xfffff
    800056e6:	c96080e7          	jalr	-874(ra) # 80004378 <dirlink>
    800056ea:	00054f63          	bltz	a0,80005708 <create+0x142>
    800056ee:	00492603          	lw	a2,4(s2)
    800056f2:	00003597          	auipc	a1,0x3
    800056f6:	05658593          	addi	a1,a1,86 # 80008748 <syscalls+0x300>
    800056fa:	8526                	mv	a0,s1
    800056fc:	fffff097          	auipc	ra,0xfffff
    80005700:	c7c080e7          	jalr	-900(ra) # 80004378 <dirlink>
    80005704:	f80557e3          	bgez	a0,80005692 <create+0xcc>
      panic("create dots");
    80005708:	00003517          	auipc	a0,0x3
    8000570c:	04850513          	addi	a0,a0,72 # 80008750 <syscalls+0x308>
    80005710:	ffffb097          	auipc	ra,0xffffb
    80005714:	e28080e7          	jalr	-472(ra) # 80000538 <panic>
    panic("create: dirlink");
    80005718:	00003517          	auipc	a0,0x3
    8000571c:	04850513          	addi	a0,a0,72 # 80008760 <syscalls+0x318>
    80005720:	ffffb097          	auipc	ra,0xffffb
    80005724:	e18080e7          	jalr	-488(ra) # 80000538 <panic>
    return 0;
    80005728:	84aa                	mv	s1,a0
    8000572a:	b739                	j	80005638 <create+0x72>

000000008000572c <sys_dup>:
{
    8000572c:	7179                	addi	sp,sp,-48
    8000572e:	f406                	sd	ra,40(sp)
    80005730:	f022                	sd	s0,32(sp)
    80005732:	ec26                	sd	s1,24(sp)
    80005734:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005736:	fd840613          	addi	a2,s0,-40
    8000573a:	4581                	li	a1,0
    8000573c:	4501                	li	a0,0
    8000573e:	00000097          	auipc	ra,0x0
    80005742:	dde080e7          	jalr	-546(ra) # 8000551c <argfd>
    return -1;
    80005746:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005748:	02054363          	bltz	a0,8000576e <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000574c:	fd843503          	ld	a0,-40(s0)
    80005750:	00000097          	auipc	ra,0x0
    80005754:	e34080e7          	jalr	-460(ra) # 80005584 <fdalloc>
    80005758:	84aa                	mv	s1,a0
    return -1;
    8000575a:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000575c:	00054963          	bltz	a0,8000576e <sys_dup+0x42>
  filedup(f);
    80005760:	fd843503          	ld	a0,-40(s0)
    80005764:	fffff097          	auipc	ra,0xfffff
    80005768:	36c080e7          	jalr	876(ra) # 80004ad0 <filedup>
  return fd;
    8000576c:	87a6                	mv	a5,s1
}
    8000576e:	853e                	mv	a0,a5
    80005770:	70a2                	ld	ra,40(sp)
    80005772:	7402                	ld	s0,32(sp)
    80005774:	64e2                	ld	s1,24(sp)
    80005776:	6145                	addi	sp,sp,48
    80005778:	8082                	ret

000000008000577a <sys_read>:
{
    8000577a:	7179                	addi	sp,sp,-48
    8000577c:	f406                	sd	ra,40(sp)
    8000577e:	f022                	sd	s0,32(sp)
    80005780:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005782:	fe840613          	addi	a2,s0,-24
    80005786:	4581                	li	a1,0
    80005788:	4501                	li	a0,0
    8000578a:	00000097          	auipc	ra,0x0
    8000578e:	d92080e7          	jalr	-622(ra) # 8000551c <argfd>
    return -1;
    80005792:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005794:	04054163          	bltz	a0,800057d6 <sys_read+0x5c>
    80005798:	fe440593          	addi	a1,s0,-28
    8000579c:	4509                	li	a0,2
    8000579e:	ffffd097          	auipc	ra,0xffffd
    800057a2:	57e080e7          	jalr	1406(ra) # 80002d1c <argint>
    return -1;
    800057a6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800057a8:	02054763          	bltz	a0,800057d6 <sys_read+0x5c>
    800057ac:	fd840593          	addi	a1,s0,-40
    800057b0:	4505                	li	a0,1
    800057b2:	ffffd097          	auipc	ra,0xffffd
    800057b6:	58c080e7          	jalr	1420(ra) # 80002d3e <argaddr>
    return -1;
    800057ba:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800057bc:	00054d63          	bltz	a0,800057d6 <sys_read+0x5c>
  return fileread(f, p, n);
    800057c0:	fe442603          	lw	a2,-28(s0)
    800057c4:	fd843583          	ld	a1,-40(s0)
    800057c8:	fe843503          	ld	a0,-24(s0)
    800057cc:	fffff097          	auipc	ra,0xfffff
    800057d0:	490080e7          	jalr	1168(ra) # 80004c5c <fileread>
    800057d4:	87aa                	mv	a5,a0
}
    800057d6:	853e                	mv	a0,a5
    800057d8:	70a2                	ld	ra,40(sp)
    800057da:	7402                	ld	s0,32(sp)
    800057dc:	6145                	addi	sp,sp,48
    800057de:	8082                	ret

00000000800057e0 <sys_write>:
{
    800057e0:	7179                	addi	sp,sp,-48
    800057e2:	f406                	sd	ra,40(sp)
    800057e4:	f022                	sd	s0,32(sp)
    800057e6:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800057e8:	fe840613          	addi	a2,s0,-24
    800057ec:	4581                	li	a1,0
    800057ee:	4501                	li	a0,0
    800057f0:	00000097          	auipc	ra,0x0
    800057f4:	d2c080e7          	jalr	-724(ra) # 8000551c <argfd>
    return -1;
    800057f8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800057fa:	04054163          	bltz	a0,8000583c <sys_write+0x5c>
    800057fe:	fe440593          	addi	a1,s0,-28
    80005802:	4509                	li	a0,2
    80005804:	ffffd097          	auipc	ra,0xffffd
    80005808:	518080e7          	jalr	1304(ra) # 80002d1c <argint>
    return -1;
    8000580c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000580e:	02054763          	bltz	a0,8000583c <sys_write+0x5c>
    80005812:	fd840593          	addi	a1,s0,-40
    80005816:	4505                	li	a0,1
    80005818:	ffffd097          	auipc	ra,0xffffd
    8000581c:	526080e7          	jalr	1318(ra) # 80002d3e <argaddr>
    return -1;
    80005820:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005822:	00054d63          	bltz	a0,8000583c <sys_write+0x5c>
  return filewrite(f, p, n);
    80005826:	fe442603          	lw	a2,-28(s0)
    8000582a:	fd843583          	ld	a1,-40(s0)
    8000582e:	fe843503          	ld	a0,-24(s0)
    80005832:	fffff097          	auipc	ra,0xfffff
    80005836:	4ec080e7          	jalr	1260(ra) # 80004d1e <filewrite>
    8000583a:	87aa                	mv	a5,a0
}
    8000583c:	853e                	mv	a0,a5
    8000583e:	70a2                	ld	ra,40(sp)
    80005840:	7402                	ld	s0,32(sp)
    80005842:	6145                	addi	sp,sp,48
    80005844:	8082                	ret

0000000080005846 <sys_close>:
{
    80005846:	1101                	addi	sp,sp,-32
    80005848:	ec06                	sd	ra,24(sp)
    8000584a:	e822                	sd	s0,16(sp)
    8000584c:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000584e:	fe040613          	addi	a2,s0,-32
    80005852:	fec40593          	addi	a1,s0,-20
    80005856:	4501                	li	a0,0
    80005858:	00000097          	auipc	ra,0x0
    8000585c:	cc4080e7          	jalr	-828(ra) # 8000551c <argfd>
    return -1;
    80005860:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005862:	02054463          	bltz	a0,8000588a <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005866:	ffffc097          	auipc	ra,0xffffc
    8000586a:	130080e7          	jalr	304(ra) # 80001996 <myproc>
    8000586e:	fec42783          	lw	a5,-20(s0)
    80005872:	07f9                	addi	a5,a5,30
    80005874:	078e                	slli	a5,a5,0x3
    80005876:	97aa                	add	a5,a5,a0
    80005878:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    8000587c:	fe043503          	ld	a0,-32(s0)
    80005880:	fffff097          	auipc	ra,0xfffff
    80005884:	2a2080e7          	jalr	674(ra) # 80004b22 <fileclose>
  return 0;
    80005888:	4781                	li	a5,0
}
    8000588a:	853e                	mv	a0,a5
    8000588c:	60e2                	ld	ra,24(sp)
    8000588e:	6442                	ld	s0,16(sp)
    80005890:	6105                	addi	sp,sp,32
    80005892:	8082                	ret

0000000080005894 <sys_fstat>:
{
    80005894:	1101                	addi	sp,sp,-32
    80005896:	ec06                	sd	ra,24(sp)
    80005898:	e822                	sd	s0,16(sp)
    8000589a:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000589c:	fe840613          	addi	a2,s0,-24
    800058a0:	4581                	li	a1,0
    800058a2:	4501                	li	a0,0
    800058a4:	00000097          	auipc	ra,0x0
    800058a8:	c78080e7          	jalr	-904(ra) # 8000551c <argfd>
    return -1;
    800058ac:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800058ae:	02054563          	bltz	a0,800058d8 <sys_fstat+0x44>
    800058b2:	fe040593          	addi	a1,s0,-32
    800058b6:	4505                	li	a0,1
    800058b8:	ffffd097          	auipc	ra,0xffffd
    800058bc:	486080e7          	jalr	1158(ra) # 80002d3e <argaddr>
    return -1;
    800058c0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800058c2:	00054b63          	bltz	a0,800058d8 <sys_fstat+0x44>
  return filestat(f, st);
    800058c6:	fe043583          	ld	a1,-32(s0)
    800058ca:	fe843503          	ld	a0,-24(s0)
    800058ce:	fffff097          	auipc	ra,0xfffff
    800058d2:	31c080e7          	jalr	796(ra) # 80004bea <filestat>
    800058d6:	87aa                	mv	a5,a0
}
    800058d8:	853e                	mv	a0,a5
    800058da:	60e2                	ld	ra,24(sp)
    800058dc:	6442                	ld	s0,16(sp)
    800058de:	6105                	addi	sp,sp,32
    800058e0:	8082                	ret

00000000800058e2 <sys_link>:
{
    800058e2:	7169                	addi	sp,sp,-304
    800058e4:	f606                	sd	ra,296(sp)
    800058e6:	f222                	sd	s0,288(sp)
    800058e8:	ee26                	sd	s1,280(sp)
    800058ea:	ea4a                	sd	s2,272(sp)
    800058ec:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800058ee:	08000613          	li	a2,128
    800058f2:	ed040593          	addi	a1,s0,-304
    800058f6:	4501                	li	a0,0
    800058f8:	ffffd097          	auipc	ra,0xffffd
    800058fc:	468080e7          	jalr	1128(ra) # 80002d60 <argstr>
    return -1;
    80005900:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005902:	10054e63          	bltz	a0,80005a1e <sys_link+0x13c>
    80005906:	08000613          	li	a2,128
    8000590a:	f5040593          	addi	a1,s0,-176
    8000590e:	4505                	li	a0,1
    80005910:	ffffd097          	auipc	ra,0xffffd
    80005914:	450080e7          	jalr	1104(ra) # 80002d60 <argstr>
    return -1;
    80005918:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000591a:	10054263          	bltz	a0,80005a1e <sys_link+0x13c>
  begin_op();
    8000591e:	fffff097          	auipc	ra,0xfffff
    80005922:	d38080e7          	jalr	-712(ra) # 80004656 <begin_op>
  if((ip = namei(old)) == 0){
    80005926:	ed040513          	addi	a0,s0,-304
    8000592a:	fffff097          	auipc	ra,0xfffff
    8000592e:	b10080e7          	jalr	-1264(ra) # 8000443a <namei>
    80005932:	84aa                	mv	s1,a0
    80005934:	c551                	beqz	a0,800059c0 <sys_link+0xde>
  ilock(ip);
    80005936:	ffffe097          	auipc	ra,0xffffe
    8000593a:	34e080e7          	jalr	846(ra) # 80003c84 <ilock>
  if(ip->type == T_DIR){
    8000593e:	04449703          	lh	a4,68(s1)
    80005942:	4785                	li	a5,1
    80005944:	08f70463          	beq	a4,a5,800059cc <sys_link+0xea>
  ip->nlink++;
    80005948:	04a4d783          	lhu	a5,74(s1)
    8000594c:	2785                	addiw	a5,a5,1
    8000594e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005952:	8526                	mv	a0,s1
    80005954:	ffffe097          	auipc	ra,0xffffe
    80005958:	266080e7          	jalr	614(ra) # 80003bba <iupdate>
  iunlock(ip);
    8000595c:	8526                	mv	a0,s1
    8000595e:	ffffe097          	auipc	ra,0xffffe
    80005962:	3e8080e7          	jalr	1000(ra) # 80003d46 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005966:	fd040593          	addi	a1,s0,-48
    8000596a:	f5040513          	addi	a0,s0,-176
    8000596e:	fffff097          	auipc	ra,0xfffff
    80005972:	aea080e7          	jalr	-1302(ra) # 80004458 <nameiparent>
    80005976:	892a                	mv	s2,a0
    80005978:	c935                	beqz	a0,800059ec <sys_link+0x10a>
  ilock(dp);
    8000597a:	ffffe097          	auipc	ra,0xffffe
    8000597e:	30a080e7          	jalr	778(ra) # 80003c84 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005982:	00092703          	lw	a4,0(s2)
    80005986:	409c                	lw	a5,0(s1)
    80005988:	04f71d63          	bne	a4,a5,800059e2 <sys_link+0x100>
    8000598c:	40d0                	lw	a2,4(s1)
    8000598e:	fd040593          	addi	a1,s0,-48
    80005992:	854a                	mv	a0,s2
    80005994:	fffff097          	auipc	ra,0xfffff
    80005998:	9e4080e7          	jalr	-1564(ra) # 80004378 <dirlink>
    8000599c:	04054363          	bltz	a0,800059e2 <sys_link+0x100>
  iunlockput(dp);
    800059a0:	854a                	mv	a0,s2
    800059a2:	ffffe097          	auipc	ra,0xffffe
    800059a6:	544080e7          	jalr	1348(ra) # 80003ee6 <iunlockput>
  iput(ip);
    800059aa:	8526                	mv	a0,s1
    800059ac:	ffffe097          	auipc	ra,0xffffe
    800059b0:	492080e7          	jalr	1170(ra) # 80003e3e <iput>
  end_op();
    800059b4:	fffff097          	auipc	ra,0xfffff
    800059b8:	d22080e7          	jalr	-734(ra) # 800046d6 <end_op>
  return 0;
    800059bc:	4781                	li	a5,0
    800059be:	a085                	j	80005a1e <sys_link+0x13c>
    end_op();
    800059c0:	fffff097          	auipc	ra,0xfffff
    800059c4:	d16080e7          	jalr	-746(ra) # 800046d6 <end_op>
    return -1;
    800059c8:	57fd                	li	a5,-1
    800059ca:	a891                	j	80005a1e <sys_link+0x13c>
    iunlockput(ip);
    800059cc:	8526                	mv	a0,s1
    800059ce:	ffffe097          	auipc	ra,0xffffe
    800059d2:	518080e7          	jalr	1304(ra) # 80003ee6 <iunlockput>
    end_op();
    800059d6:	fffff097          	auipc	ra,0xfffff
    800059da:	d00080e7          	jalr	-768(ra) # 800046d6 <end_op>
    return -1;
    800059de:	57fd                	li	a5,-1
    800059e0:	a83d                	j	80005a1e <sys_link+0x13c>
    iunlockput(dp);
    800059e2:	854a                	mv	a0,s2
    800059e4:	ffffe097          	auipc	ra,0xffffe
    800059e8:	502080e7          	jalr	1282(ra) # 80003ee6 <iunlockput>
  ilock(ip);
    800059ec:	8526                	mv	a0,s1
    800059ee:	ffffe097          	auipc	ra,0xffffe
    800059f2:	296080e7          	jalr	662(ra) # 80003c84 <ilock>
  ip->nlink--;
    800059f6:	04a4d783          	lhu	a5,74(s1)
    800059fa:	37fd                	addiw	a5,a5,-1
    800059fc:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005a00:	8526                	mv	a0,s1
    80005a02:	ffffe097          	auipc	ra,0xffffe
    80005a06:	1b8080e7          	jalr	440(ra) # 80003bba <iupdate>
  iunlockput(ip);
    80005a0a:	8526                	mv	a0,s1
    80005a0c:	ffffe097          	auipc	ra,0xffffe
    80005a10:	4da080e7          	jalr	1242(ra) # 80003ee6 <iunlockput>
  end_op();
    80005a14:	fffff097          	auipc	ra,0xfffff
    80005a18:	cc2080e7          	jalr	-830(ra) # 800046d6 <end_op>
  return -1;
    80005a1c:	57fd                	li	a5,-1
}
    80005a1e:	853e                	mv	a0,a5
    80005a20:	70b2                	ld	ra,296(sp)
    80005a22:	7412                	ld	s0,288(sp)
    80005a24:	64f2                	ld	s1,280(sp)
    80005a26:	6952                	ld	s2,272(sp)
    80005a28:	6155                	addi	sp,sp,304
    80005a2a:	8082                	ret

0000000080005a2c <sys_unlink>:
{
    80005a2c:	7151                	addi	sp,sp,-240
    80005a2e:	f586                	sd	ra,232(sp)
    80005a30:	f1a2                	sd	s0,224(sp)
    80005a32:	eda6                	sd	s1,216(sp)
    80005a34:	e9ca                	sd	s2,208(sp)
    80005a36:	e5ce                	sd	s3,200(sp)
    80005a38:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005a3a:	08000613          	li	a2,128
    80005a3e:	f3040593          	addi	a1,s0,-208
    80005a42:	4501                	li	a0,0
    80005a44:	ffffd097          	auipc	ra,0xffffd
    80005a48:	31c080e7          	jalr	796(ra) # 80002d60 <argstr>
    80005a4c:	18054163          	bltz	a0,80005bce <sys_unlink+0x1a2>
  begin_op();
    80005a50:	fffff097          	auipc	ra,0xfffff
    80005a54:	c06080e7          	jalr	-1018(ra) # 80004656 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005a58:	fb040593          	addi	a1,s0,-80
    80005a5c:	f3040513          	addi	a0,s0,-208
    80005a60:	fffff097          	auipc	ra,0xfffff
    80005a64:	9f8080e7          	jalr	-1544(ra) # 80004458 <nameiparent>
    80005a68:	84aa                	mv	s1,a0
    80005a6a:	c979                	beqz	a0,80005b40 <sys_unlink+0x114>
  ilock(dp);
    80005a6c:	ffffe097          	auipc	ra,0xffffe
    80005a70:	218080e7          	jalr	536(ra) # 80003c84 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005a74:	00003597          	auipc	a1,0x3
    80005a78:	ccc58593          	addi	a1,a1,-820 # 80008740 <syscalls+0x2f8>
    80005a7c:	fb040513          	addi	a0,s0,-80
    80005a80:	ffffe097          	auipc	ra,0xffffe
    80005a84:	6ce080e7          	jalr	1742(ra) # 8000414e <namecmp>
    80005a88:	14050a63          	beqz	a0,80005bdc <sys_unlink+0x1b0>
    80005a8c:	00003597          	auipc	a1,0x3
    80005a90:	cbc58593          	addi	a1,a1,-836 # 80008748 <syscalls+0x300>
    80005a94:	fb040513          	addi	a0,s0,-80
    80005a98:	ffffe097          	auipc	ra,0xffffe
    80005a9c:	6b6080e7          	jalr	1718(ra) # 8000414e <namecmp>
    80005aa0:	12050e63          	beqz	a0,80005bdc <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005aa4:	f2c40613          	addi	a2,s0,-212
    80005aa8:	fb040593          	addi	a1,s0,-80
    80005aac:	8526                	mv	a0,s1
    80005aae:	ffffe097          	auipc	ra,0xffffe
    80005ab2:	6ba080e7          	jalr	1722(ra) # 80004168 <dirlookup>
    80005ab6:	892a                	mv	s2,a0
    80005ab8:	12050263          	beqz	a0,80005bdc <sys_unlink+0x1b0>
  ilock(ip);
    80005abc:	ffffe097          	auipc	ra,0xffffe
    80005ac0:	1c8080e7          	jalr	456(ra) # 80003c84 <ilock>
  if(ip->nlink < 1)
    80005ac4:	04a91783          	lh	a5,74(s2)
    80005ac8:	08f05263          	blez	a5,80005b4c <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005acc:	04491703          	lh	a4,68(s2)
    80005ad0:	4785                	li	a5,1
    80005ad2:	08f70563          	beq	a4,a5,80005b5c <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005ad6:	4641                	li	a2,16
    80005ad8:	4581                	li	a1,0
    80005ada:	fc040513          	addi	a0,s0,-64
    80005ade:	ffffb097          	auipc	ra,0xffffb
    80005ae2:	1ee080e7          	jalr	494(ra) # 80000ccc <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005ae6:	4741                	li	a4,16
    80005ae8:	f2c42683          	lw	a3,-212(s0)
    80005aec:	fc040613          	addi	a2,s0,-64
    80005af0:	4581                	li	a1,0
    80005af2:	8526                	mv	a0,s1
    80005af4:	ffffe097          	auipc	ra,0xffffe
    80005af8:	53c080e7          	jalr	1340(ra) # 80004030 <writei>
    80005afc:	47c1                	li	a5,16
    80005afe:	0af51563          	bne	a0,a5,80005ba8 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005b02:	04491703          	lh	a4,68(s2)
    80005b06:	4785                	li	a5,1
    80005b08:	0af70863          	beq	a4,a5,80005bb8 <sys_unlink+0x18c>
  iunlockput(dp);
    80005b0c:	8526                	mv	a0,s1
    80005b0e:	ffffe097          	auipc	ra,0xffffe
    80005b12:	3d8080e7          	jalr	984(ra) # 80003ee6 <iunlockput>
  ip->nlink--;
    80005b16:	04a95783          	lhu	a5,74(s2)
    80005b1a:	37fd                	addiw	a5,a5,-1
    80005b1c:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005b20:	854a                	mv	a0,s2
    80005b22:	ffffe097          	auipc	ra,0xffffe
    80005b26:	098080e7          	jalr	152(ra) # 80003bba <iupdate>
  iunlockput(ip);
    80005b2a:	854a                	mv	a0,s2
    80005b2c:	ffffe097          	auipc	ra,0xffffe
    80005b30:	3ba080e7          	jalr	954(ra) # 80003ee6 <iunlockput>
  end_op();
    80005b34:	fffff097          	auipc	ra,0xfffff
    80005b38:	ba2080e7          	jalr	-1118(ra) # 800046d6 <end_op>
  return 0;
    80005b3c:	4501                	li	a0,0
    80005b3e:	a84d                	j	80005bf0 <sys_unlink+0x1c4>
    end_op();
    80005b40:	fffff097          	auipc	ra,0xfffff
    80005b44:	b96080e7          	jalr	-1130(ra) # 800046d6 <end_op>
    return -1;
    80005b48:	557d                	li	a0,-1
    80005b4a:	a05d                	j	80005bf0 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005b4c:	00003517          	auipc	a0,0x3
    80005b50:	c2450513          	addi	a0,a0,-988 # 80008770 <syscalls+0x328>
    80005b54:	ffffb097          	auipc	ra,0xffffb
    80005b58:	9e4080e7          	jalr	-1564(ra) # 80000538 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005b5c:	04c92703          	lw	a4,76(s2)
    80005b60:	02000793          	li	a5,32
    80005b64:	f6e7f9e3          	bgeu	a5,a4,80005ad6 <sys_unlink+0xaa>
    80005b68:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005b6c:	4741                	li	a4,16
    80005b6e:	86ce                	mv	a3,s3
    80005b70:	f1840613          	addi	a2,s0,-232
    80005b74:	4581                	li	a1,0
    80005b76:	854a                	mv	a0,s2
    80005b78:	ffffe097          	auipc	ra,0xffffe
    80005b7c:	3c0080e7          	jalr	960(ra) # 80003f38 <readi>
    80005b80:	47c1                	li	a5,16
    80005b82:	00f51b63          	bne	a0,a5,80005b98 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005b86:	f1845783          	lhu	a5,-232(s0)
    80005b8a:	e7a1                	bnez	a5,80005bd2 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005b8c:	29c1                	addiw	s3,s3,16
    80005b8e:	04c92783          	lw	a5,76(s2)
    80005b92:	fcf9ede3          	bltu	s3,a5,80005b6c <sys_unlink+0x140>
    80005b96:	b781                	j	80005ad6 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005b98:	00003517          	auipc	a0,0x3
    80005b9c:	bf050513          	addi	a0,a0,-1040 # 80008788 <syscalls+0x340>
    80005ba0:	ffffb097          	auipc	ra,0xffffb
    80005ba4:	998080e7          	jalr	-1640(ra) # 80000538 <panic>
    panic("unlink: writei");
    80005ba8:	00003517          	auipc	a0,0x3
    80005bac:	bf850513          	addi	a0,a0,-1032 # 800087a0 <syscalls+0x358>
    80005bb0:	ffffb097          	auipc	ra,0xffffb
    80005bb4:	988080e7          	jalr	-1656(ra) # 80000538 <panic>
    dp->nlink--;
    80005bb8:	04a4d783          	lhu	a5,74(s1)
    80005bbc:	37fd                	addiw	a5,a5,-1
    80005bbe:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005bc2:	8526                	mv	a0,s1
    80005bc4:	ffffe097          	auipc	ra,0xffffe
    80005bc8:	ff6080e7          	jalr	-10(ra) # 80003bba <iupdate>
    80005bcc:	b781                	j	80005b0c <sys_unlink+0xe0>
    return -1;
    80005bce:	557d                	li	a0,-1
    80005bd0:	a005                	j	80005bf0 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005bd2:	854a                	mv	a0,s2
    80005bd4:	ffffe097          	auipc	ra,0xffffe
    80005bd8:	312080e7          	jalr	786(ra) # 80003ee6 <iunlockput>
  iunlockput(dp);
    80005bdc:	8526                	mv	a0,s1
    80005bde:	ffffe097          	auipc	ra,0xffffe
    80005be2:	308080e7          	jalr	776(ra) # 80003ee6 <iunlockput>
  end_op();
    80005be6:	fffff097          	auipc	ra,0xfffff
    80005bea:	af0080e7          	jalr	-1296(ra) # 800046d6 <end_op>
  return -1;
    80005bee:	557d                	li	a0,-1
}
    80005bf0:	70ae                	ld	ra,232(sp)
    80005bf2:	740e                	ld	s0,224(sp)
    80005bf4:	64ee                	ld	s1,216(sp)
    80005bf6:	694e                	ld	s2,208(sp)
    80005bf8:	69ae                	ld	s3,200(sp)
    80005bfa:	616d                	addi	sp,sp,240
    80005bfc:	8082                	ret

0000000080005bfe <sys_open>:

uint64
sys_open(void)
{
    80005bfe:	7131                	addi	sp,sp,-192
    80005c00:	fd06                	sd	ra,184(sp)
    80005c02:	f922                	sd	s0,176(sp)
    80005c04:	f526                	sd	s1,168(sp)
    80005c06:	f14a                	sd	s2,160(sp)
    80005c08:	ed4e                	sd	s3,152(sp)
    80005c0a:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005c0c:	08000613          	li	a2,128
    80005c10:	f5040593          	addi	a1,s0,-176
    80005c14:	4501                	li	a0,0
    80005c16:	ffffd097          	auipc	ra,0xffffd
    80005c1a:	14a080e7          	jalr	330(ra) # 80002d60 <argstr>
    return -1;
    80005c1e:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005c20:	0c054163          	bltz	a0,80005ce2 <sys_open+0xe4>
    80005c24:	f4c40593          	addi	a1,s0,-180
    80005c28:	4505                	li	a0,1
    80005c2a:	ffffd097          	auipc	ra,0xffffd
    80005c2e:	0f2080e7          	jalr	242(ra) # 80002d1c <argint>
    80005c32:	0a054863          	bltz	a0,80005ce2 <sys_open+0xe4>

  begin_op();
    80005c36:	fffff097          	auipc	ra,0xfffff
    80005c3a:	a20080e7          	jalr	-1504(ra) # 80004656 <begin_op>

  if(omode & O_CREATE){
    80005c3e:	f4c42783          	lw	a5,-180(s0)
    80005c42:	2007f793          	andi	a5,a5,512
    80005c46:	cbdd                	beqz	a5,80005cfc <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005c48:	4681                	li	a3,0
    80005c4a:	4601                	li	a2,0
    80005c4c:	4589                	li	a1,2
    80005c4e:	f5040513          	addi	a0,s0,-176
    80005c52:	00000097          	auipc	ra,0x0
    80005c56:	974080e7          	jalr	-1676(ra) # 800055c6 <create>
    80005c5a:	892a                	mv	s2,a0
    if(ip == 0){
    80005c5c:	c959                	beqz	a0,80005cf2 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005c5e:	04491703          	lh	a4,68(s2)
    80005c62:	478d                	li	a5,3
    80005c64:	00f71763          	bne	a4,a5,80005c72 <sys_open+0x74>
    80005c68:	04695703          	lhu	a4,70(s2)
    80005c6c:	47a5                	li	a5,9
    80005c6e:	0ce7ec63          	bltu	a5,a4,80005d46 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005c72:	fffff097          	auipc	ra,0xfffff
    80005c76:	df4080e7          	jalr	-524(ra) # 80004a66 <filealloc>
    80005c7a:	89aa                	mv	s3,a0
    80005c7c:	10050263          	beqz	a0,80005d80 <sys_open+0x182>
    80005c80:	00000097          	auipc	ra,0x0
    80005c84:	904080e7          	jalr	-1788(ra) # 80005584 <fdalloc>
    80005c88:	84aa                	mv	s1,a0
    80005c8a:	0e054663          	bltz	a0,80005d76 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005c8e:	04491703          	lh	a4,68(s2)
    80005c92:	478d                	li	a5,3
    80005c94:	0cf70463          	beq	a4,a5,80005d5c <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005c98:	4789                	li	a5,2
    80005c9a:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005c9e:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005ca2:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005ca6:	f4c42783          	lw	a5,-180(s0)
    80005caa:	0017c713          	xori	a4,a5,1
    80005cae:	8b05                	andi	a4,a4,1
    80005cb0:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005cb4:	0037f713          	andi	a4,a5,3
    80005cb8:	00e03733          	snez	a4,a4
    80005cbc:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005cc0:	4007f793          	andi	a5,a5,1024
    80005cc4:	c791                	beqz	a5,80005cd0 <sys_open+0xd2>
    80005cc6:	04491703          	lh	a4,68(s2)
    80005cca:	4789                	li	a5,2
    80005ccc:	08f70f63          	beq	a4,a5,80005d6a <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005cd0:	854a                	mv	a0,s2
    80005cd2:	ffffe097          	auipc	ra,0xffffe
    80005cd6:	074080e7          	jalr	116(ra) # 80003d46 <iunlock>
  end_op();
    80005cda:	fffff097          	auipc	ra,0xfffff
    80005cde:	9fc080e7          	jalr	-1540(ra) # 800046d6 <end_op>

  return fd;
}
    80005ce2:	8526                	mv	a0,s1
    80005ce4:	70ea                	ld	ra,184(sp)
    80005ce6:	744a                	ld	s0,176(sp)
    80005ce8:	74aa                	ld	s1,168(sp)
    80005cea:	790a                	ld	s2,160(sp)
    80005cec:	69ea                	ld	s3,152(sp)
    80005cee:	6129                	addi	sp,sp,192
    80005cf0:	8082                	ret
      end_op();
    80005cf2:	fffff097          	auipc	ra,0xfffff
    80005cf6:	9e4080e7          	jalr	-1564(ra) # 800046d6 <end_op>
      return -1;
    80005cfa:	b7e5                	j	80005ce2 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005cfc:	f5040513          	addi	a0,s0,-176
    80005d00:	ffffe097          	auipc	ra,0xffffe
    80005d04:	73a080e7          	jalr	1850(ra) # 8000443a <namei>
    80005d08:	892a                	mv	s2,a0
    80005d0a:	c905                	beqz	a0,80005d3a <sys_open+0x13c>
    ilock(ip);
    80005d0c:	ffffe097          	auipc	ra,0xffffe
    80005d10:	f78080e7          	jalr	-136(ra) # 80003c84 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005d14:	04491703          	lh	a4,68(s2)
    80005d18:	4785                	li	a5,1
    80005d1a:	f4f712e3          	bne	a4,a5,80005c5e <sys_open+0x60>
    80005d1e:	f4c42783          	lw	a5,-180(s0)
    80005d22:	dba1                	beqz	a5,80005c72 <sys_open+0x74>
      iunlockput(ip);
    80005d24:	854a                	mv	a0,s2
    80005d26:	ffffe097          	auipc	ra,0xffffe
    80005d2a:	1c0080e7          	jalr	448(ra) # 80003ee6 <iunlockput>
      end_op();
    80005d2e:	fffff097          	auipc	ra,0xfffff
    80005d32:	9a8080e7          	jalr	-1624(ra) # 800046d6 <end_op>
      return -1;
    80005d36:	54fd                	li	s1,-1
    80005d38:	b76d                	j	80005ce2 <sys_open+0xe4>
      end_op();
    80005d3a:	fffff097          	auipc	ra,0xfffff
    80005d3e:	99c080e7          	jalr	-1636(ra) # 800046d6 <end_op>
      return -1;
    80005d42:	54fd                	li	s1,-1
    80005d44:	bf79                	j	80005ce2 <sys_open+0xe4>
    iunlockput(ip);
    80005d46:	854a                	mv	a0,s2
    80005d48:	ffffe097          	auipc	ra,0xffffe
    80005d4c:	19e080e7          	jalr	414(ra) # 80003ee6 <iunlockput>
    end_op();
    80005d50:	fffff097          	auipc	ra,0xfffff
    80005d54:	986080e7          	jalr	-1658(ra) # 800046d6 <end_op>
    return -1;
    80005d58:	54fd                	li	s1,-1
    80005d5a:	b761                	j	80005ce2 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005d5c:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005d60:	04691783          	lh	a5,70(s2)
    80005d64:	02f99223          	sh	a5,36(s3)
    80005d68:	bf2d                	j	80005ca2 <sys_open+0xa4>
    itrunc(ip);
    80005d6a:	854a                	mv	a0,s2
    80005d6c:	ffffe097          	auipc	ra,0xffffe
    80005d70:	026080e7          	jalr	38(ra) # 80003d92 <itrunc>
    80005d74:	bfb1                	j	80005cd0 <sys_open+0xd2>
      fileclose(f);
    80005d76:	854e                	mv	a0,s3
    80005d78:	fffff097          	auipc	ra,0xfffff
    80005d7c:	daa080e7          	jalr	-598(ra) # 80004b22 <fileclose>
    iunlockput(ip);
    80005d80:	854a                	mv	a0,s2
    80005d82:	ffffe097          	auipc	ra,0xffffe
    80005d86:	164080e7          	jalr	356(ra) # 80003ee6 <iunlockput>
    end_op();
    80005d8a:	fffff097          	auipc	ra,0xfffff
    80005d8e:	94c080e7          	jalr	-1716(ra) # 800046d6 <end_op>
    return -1;
    80005d92:	54fd                	li	s1,-1
    80005d94:	b7b9                	j	80005ce2 <sys_open+0xe4>

0000000080005d96 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005d96:	7175                	addi	sp,sp,-144
    80005d98:	e506                	sd	ra,136(sp)
    80005d9a:	e122                	sd	s0,128(sp)
    80005d9c:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005d9e:	fffff097          	auipc	ra,0xfffff
    80005da2:	8b8080e7          	jalr	-1864(ra) # 80004656 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005da6:	08000613          	li	a2,128
    80005daa:	f7040593          	addi	a1,s0,-144
    80005dae:	4501                	li	a0,0
    80005db0:	ffffd097          	auipc	ra,0xffffd
    80005db4:	fb0080e7          	jalr	-80(ra) # 80002d60 <argstr>
    80005db8:	02054963          	bltz	a0,80005dea <sys_mkdir+0x54>
    80005dbc:	4681                	li	a3,0
    80005dbe:	4601                	li	a2,0
    80005dc0:	4585                	li	a1,1
    80005dc2:	f7040513          	addi	a0,s0,-144
    80005dc6:	00000097          	auipc	ra,0x0
    80005dca:	800080e7          	jalr	-2048(ra) # 800055c6 <create>
    80005dce:	cd11                	beqz	a0,80005dea <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005dd0:	ffffe097          	auipc	ra,0xffffe
    80005dd4:	116080e7          	jalr	278(ra) # 80003ee6 <iunlockput>
  end_op();
    80005dd8:	fffff097          	auipc	ra,0xfffff
    80005ddc:	8fe080e7          	jalr	-1794(ra) # 800046d6 <end_op>
  return 0;
    80005de0:	4501                	li	a0,0
}
    80005de2:	60aa                	ld	ra,136(sp)
    80005de4:	640a                	ld	s0,128(sp)
    80005de6:	6149                	addi	sp,sp,144
    80005de8:	8082                	ret
    end_op();
    80005dea:	fffff097          	auipc	ra,0xfffff
    80005dee:	8ec080e7          	jalr	-1812(ra) # 800046d6 <end_op>
    return -1;
    80005df2:	557d                	li	a0,-1
    80005df4:	b7fd                	j	80005de2 <sys_mkdir+0x4c>

0000000080005df6 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005df6:	7135                	addi	sp,sp,-160
    80005df8:	ed06                	sd	ra,152(sp)
    80005dfa:	e922                	sd	s0,144(sp)
    80005dfc:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005dfe:	fffff097          	auipc	ra,0xfffff
    80005e02:	858080e7          	jalr	-1960(ra) # 80004656 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005e06:	08000613          	li	a2,128
    80005e0a:	f7040593          	addi	a1,s0,-144
    80005e0e:	4501                	li	a0,0
    80005e10:	ffffd097          	auipc	ra,0xffffd
    80005e14:	f50080e7          	jalr	-176(ra) # 80002d60 <argstr>
    80005e18:	04054a63          	bltz	a0,80005e6c <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005e1c:	f6c40593          	addi	a1,s0,-148
    80005e20:	4505                	li	a0,1
    80005e22:	ffffd097          	auipc	ra,0xffffd
    80005e26:	efa080e7          	jalr	-262(ra) # 80002d1c <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005e2a:	04054163          	bltz	a0,80005e6c <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005e2e:	f6840593          	addi	a1,s0,-152
    80005e32:	4509                	li	a0,2
    80005e34:	ffffd097          	auipc	ra,0xffffd
    80005e38:	ee8080e7          	jalr	-280(ra) # 80002d1c <argint>
     argint(1, &major) < 0 ||
    80005e3c:	02054863          	bltz	a0,80005e6c <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005e40:	f6841683          	lh	a3,-152(s0)
    80005e44:	f6c41603          	lh	a2,-148(s0)
    80005e48:	458d                	li	a1,3
    80005e4a:	f7040513          	addi	a0,s0,-144
    80005e4e:	fffff097          	auipc	ra,0xfffff
    80005e52:	778080e7          	jalr	1912(ra) # 800055c6 <create>
     argint(2, &minor) < 0 ||
    80005e56:	c919                	beqz	a0,80005e6c <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005e58:	ffffe097          	auipc	ra,0xffffe
    80005e5c:	08e080e7          	jalr	142(ra) # 80003ee6 <iunlockput>
  end_op();
    80005e60:	fffff097          	auipc	ra,0xfffff
    80005e64:	876080e7          	jalr	-1930(ra) # 800046d6 <end_op>
  return 0;
    80005e68:	4501                	li	a0,0
    80005e6a:	a031                	j	80005e76 <sys_mknod+0x80>
    end_op();
    80005e6c:	fffff097          	auipc	ra,0xfffff
    80005e70:	86a080e7          	jalr	-1942(ra) # 800046d6 <end_op>
    return -1;
    80005e74:	557d                	li	a0,-1
}
    80005e76:	60ea                	ld	ra,152(sp)
    80005e78:	644a                	ld	s0,144(sp)
    80005e7a:	610d                	addi	sp,sp,160
    80005e7c:	8082                	ret

0000000080005e7e <sys_chdir>:

uint64
sys_chdir(void)
{
    80005e7e:	7135                	addi	sp,sp,-160
    80005e80:	ed06                	sd	ra,152(sp)
    80005e82:	e922                	sd	s0,144(sp)
    80005e84:	e526                	sd	s1,136(sp)
    80005e86:	e14a                	sd	s2,128(sp)
    80005e88:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005e8a:	ffffc097          	auipc	ra,0xffffc
    80005e8e:	b0c080e7          	jalr	-1268(ra) # 80001996 <myproc>
    80005e92:	892a                	mv	s2,a0
  
  begin_op();
    80005e94:	ffffe097          	auipc	ra,0xffffe
    80005e98:	7c2080e7          	jalr	1986(ra) # 80004656 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005e9c:	08000613          	li	a2,128
    80005ea0:	f6040593          	addi	a1,s0,-160
    80005ea4:	4501                	li	a0,0
    80005ea6:	ffffd097          	auipc	ra,0xffffd
    80005eaa:	eba080e7          	jalr	-326(ra) # 80002d60 <argstr>
    80005eae:	04054b63          	bltz	a0,80005f04 <sys_chdir+0x86>
    80005eb2:	f6040513          	addi	a0,s0,-160
    80005eb6:	ffffe097          	auipc	ra,0xffffe
    80005eba:	584080e7          	jalr	1412(ra) # 8000443a <namei>
    80005ebe:	84aa                	mv	s1,a0
    80005ec0:	c131                	beqz	a0,80005f04 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005ec2:	ffffe097          	auipc	ra,0xffffe
    80005ec6:	dc2080e7          	jalr	-574(ra) # 80003c84 <ilock>
  if(ip->type != T_DIR){
    80005eca:	04449703          	lh	a4,68(s1)
    80005ece:	4785                	li	a5,1
    80005ed0:	04f71063          	bne	a4,a5,80005f10 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005ed4:	8526                	mv	a0,s1
    80005ed6:	ffffe097          	auipc	ra,0xffffe
    80005eda:	e70080e7          	jalr	-400(ra) # 80003d46 <iunlock>
  iput(p->cwd);
    80005ede:	17093503          	ld	a0,368(s2)
    80005ee2:	ffffe097          	auipc	ra,0xffffe
    80005ee6:	f5c080e7          	jalr	-164(ra) # 80003e3e <iput>
  end_op();
    80005eea:	ffffe097          	auipc	ra,0xffffe
    80005eee:	7ec080e7          	jalr	2028(ra) # 800046d6 <end_op>
  p->cwd = ip;
    80005ef2:	16993823          	sd	s1,368(s2)
  return 0;
    80005ef6:	4501                	li	a0,0
}
    80005ef8:	60ea                	ld	ra,152(sp)
    80005efa:	644a                	ld	s0,144(sp)
    80005efc:	64aa                	ld	s1,136(sp)
    80005efe:	690a                	ld	s2,128(sp)
    80005f00:	610d                	addi	sp,sp,160
    80005f02:	8082                	ret
    end_op();
    80005f04:	ffffe097          	auipc	ra,0xffffe
    80005f08:	7d2080e7          	jalr	2002(ra) # 800046d6 <end_op>
    return -1;
    80005f0c:	557d                	li	a0,-1
    80005f0e:	b7ed                	j	80005ef8 <sys_chdir+0x7a>
    iunlockput(ip);
    80005f10:	8526                	mv	a0,s1
    80005f12:	ffffe097          	auipc	ra,0xffffe
    80005f16:	fd4080e7          	jalr	-44(ra) # 80003ee6 <iunlockput>
    end_op();
    80005f1a:	ffffe097          	auipc	ra,0xffffe
    80005f1e:	7bc080e7          	jalr	1980(ra) # 800046d6 <end_op>
    return -1;
    80005f22:	557d                	li	a0,-1
    80005f24:	bfd1                	j	80005ef8 <sys_chdir+0x7a>

0000000080005f26 <sys_exec>:

uint64
sys_exec(void)
{
    80005f26:	7145                	addi	sp,sp,-464
    80005f28:	e786                	sd	ra,456(sp)
    80005f2a:	e3a2                	sd	s0,448(sp)
    80005f2c:	ff26                	sd	s1,440(sp)
    80005f2e:	fb4a                	sd	s2,432(sp)
    80005f30:	f74e                	sd	s3,424(sp)
    80005f32:	f352                	sd	s4,416(sp)
    80005f34:	ef56                	sd	s5,408(sp)
    80005f36:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005f38:	08000613          	li	a2,128
    80005f3c:	f4040593          	addi	a1,s0,-192
    80005f40:	4501                	li	a0,0
    80005f42:	ffffd097          	auipc	ra,0xffffd
    80005f46:	e1e080e7          	jalr	-482(ra) # 80002d60 <argstr>
    return -1;
    80005f4a:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005f4c:	0c054a63          	bltz	a0,80006020 <sys_exec+0xfa>
    80005f50:	e3840593          	addi	a1,s0,-456
    80005f54:	4505                	li	a0,1
    80005f56:	ffffd097          	auipc	ra,0xffffd
    80005f5a:	de8080e7          	jalr	-536(ra) # 80002d3e <argaddr>
    80005f5e:	0c054163          	bltz	a0,80006020 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005f62:	10000613          	li	a2,256
    80005f66:	4581                	li	a1,0
    80005f68:	e4040513          	addi	a0,s0,-448
    80005f6c:	ffffb097          	auipc	ra,0xffffb
    80005f70:	d60080e7          	jalr	-672(ra) # 80000ccc <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005f74:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005f78:	89a6                	mv	s3,s1
    80005f7a:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005f7c:	02000a13          	li	s4,32
    80005f80:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005f84:	00391793          	slli	a5,s2,0x3
    80005f88:	e3040593          	addi	a1,s0,-464
    80005f8c:	e3843503          	ld	a0,-456(s0)
    80005f90:	953e                	add	a0,a0,a5
    80005f92:	ffffd097          	auipc	ra,0xffffd
    80005f96:	cf0080e7          	jalr	-784(ra) # 80002c82 <fetchaddr>
    80005f9a:	02054a63          	bltz	a0,80005fce <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005f9e:	e3043783          	ld	a5,-464(s0)
    80005fa2:	c3b9                	beqz	a5,80005fe8 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005fa4:	ffffb097          	auipc	ra,0xffffb
    80005fa8:	b3c080e7          	jalr	-1220(ra) # 80000ae0 <kalloc>
    80005fac:	85aa                	mv	a1,a0
    80005fae:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005fb2:	cd11                	beqz	a0,80005fce <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005fb4:	6605                	lui	a2,0x1
    80005fb6:	e3043503          	ld	a0,-464(s0)
    80005fba:	ffffd097          	auipc	ra,0xffffd
    80005fbe:	d1a080e7          	jalr	-742(ra) # 80002cd4 <fetchstr>
    80005fc2:	00054663          	bltz	a0,80005fce <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005fc6:	0905                	addi	s2,s2,1
    80005fc8:	09a1                	addi	s3,s3,8
    80005fca:	fb491be3          	bne	s2,s4,80005f80 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005fce:	10048913          	addi	s2,s1,256
    80005fd2:	6088                	ld	a0,0(s1)
    80005fd4:	c529                	beqz	a0,8000601e <sys_exec+0xf8>
    kfree(argv[i]);
    80005fd6:	ffffb097          	auipc	ra,0xffffb
    80005fda:	a0e080e7          	jalr	-1522(ra) # 800009e4 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005fde:	04a1                	addi	s1,s1,8
    80005fe0:	ff2499e3          	bne	s1,s2,80005fd2 <sys_exec+0xac>
  return -1;
    80005fe4:	597d                	li	s2,-1
    80005fe6:	a82d                	j	80006020 <sys_exec+0xfa>
      argv[i] = 0;
    80005fe8:	0a8e                	slli	s5,s5,0x3
    80005fea:	fc040793          	addi	a5,s0,-64
    80005fee:	9abe                	add	s5,s5,a5
    80005ff0:	e80ab023          	sd	zero,-384(s5) # ffffffffffffee80 <end+0xffffffff7ffdb9d8>
  int ret = exec(path, argv);
    80005ff4:	e4040593          	addi	a1,s0,-448
    80005ff8:	f4040513          	addi	a0,s0,-192
    80005ffc:	fffff097          	auipc	ra,0xfffff
    80006000:	178080e7          	jalr	376(ra) # 80005174 <exec>
    80006004:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006006:	10048993          	addi	s3,s1,256
    8000600a:	6088                	ld	a0,0(s1)
    8000600c:	c911                	beqz	a0,80006020 <sys_exec+0xfa>
    kfree(argv[i]);
    8000600e:	ffffb097          	auipc	ra,0xffffb
    80006012:	9d6080e7          	jalr	-1578(ra) # 800009e4 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006016:	04a1                	addi	s1,s1,8
    80006018:	ff3499e3          	bne	s1,s3,8000600a <sys_exec+0xe4>
    8000601c:	a011                	j	80006020 <sys_exec+0xfa>
  return -1;
    8000601e:	597d                	li	s2,-1
}
    80006020:	854a                	mv	a0,s2
    80006022:	60be                	ld	ra,456(sp)
    80006024:	641e                	ld	s0,448(sp)
    80006026:	74fa                	ld	s1,440(sp)
    80006028:	795a                	ld	s2,432(sp)
    8000602a:	79ba                	ld	s3,424(sp)
    8000602c:	7a1a                	ld	s4,416(sp)
    8000602e:	6afa                	ld	s5,408(sp)
    80006030:	6179                	addi	sp,sp,464
    80006032:	8082                	ret

0000000080006034 <sys_pipe>:

uint64
sys_pipe(void)
{
    80006034:	7139                	addi	sp,sp,-64
    80006036:	fc06                	sd	ra,56(sp)
    80006038:	f822                	sd	s0,48(sp)
    8000603a:	f426                	sd	s1,40(sp)
    8000603c:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    8000603e:	ffffc097          	auipc	ra,0xffffc
    80006042:	958080e7          	jalr	-1704(ra) # 80001996 <myproc>
    80006046:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80006048:	fd840593          	addi	a1,s0,-40
    8000604c:	4501                	li	a0,0
    8000604e:	ffffd097          	auipc	ra,0xffffd
    80006052:	cf0080e7          	jalr	-784(ra) # 80002d3e <argaddr>
    return -1;
    80006056:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80006058:	0e054063          	bltz	a0,80006138 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    8000605c:	fc840593          	addi	a1,s0,-56
    80006060:	fd040513          	addi	a0,s0,-48
    80006064:	fffff097          	auipc	ra,0xfffff
    80006068:	dee080e7          	jalr	-530(ra) # 80004e52 <pipealloc>
    return -1;
    8000606c:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    8000606e:	0c054563          	bltz	a0,80006138 <sys_pipe+0x104>
  fd0 = -1;
    80006072:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80006076:	fd043503          	ld	a0,-48(s0)
    8000607a:	fffff097          	auipc	ra,0xfffff
    8000607e:	50a080e7          	jalr	1290(ra) # 80005584 <fdalloc>
    80006082:	fca42223          	sw	a0,-60(s0)
    80006086:	08054c63          	bltz	a0,8000611e <sys_pipe+0xea>
    8000608a:	fc843503          	ld	a0,-56(s0)
    8000608e:	fffff097          	auipc	ra,0xfffff
    80006092:	4f6080e7          	jalr	1270(ra) # 80005584 <fdalloc>
    80006096:	fca42023          	sw	a0,-64(s0)
    8000609a:	06054863          	bltz	a0,8000610a <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000609e:	4691                	li	a3,4
    800060a0:	fc440613          	addi	a2,s0,-60
    800060a4:	fd843583          	ld	a1,-40(s0)
    800060a8:	78a8                	ld	a0,112(s1)
    800060aa:	ffffb097          	auipc	ra,0xffffb
    800060ae:	5ac080e7          	jalr	1452(ra) # 80001656 <copyout>
    800060b2:	02054063          	bltz	a0,800060d2 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    800060b6:	4691                	li	a3,4
    800060b8:	fc040613          	addi	a2,s0,-64
    800060bc:	fd843583          	ld	a1,-40(s0)
    800060c0:	0591                	addi	a1,a1,4
    800060c2:	78a8                	ld	a0,112(s1)
    800060c4:	ffffb097          	auipc	ra,0xffffb
    800060c8:	592080e7          	jalr	1426(ra) # 80001656 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    800060cc:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800060ce:	06055563          	bgez	a0,80006138 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    800060d2:	fc442783          	lw	a5,-60(s0)
    800060d6:	07f9                	addi	a5,a5,30
    800060d8:	078e                	slli	a5,a5,0x3
    800060da:	97a6                	add	a5,a5,s1
    800060dc:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    800060e0:	fc042503          	lw	a0,-64(s0)
    800060e4:	0579                	addi	a0,a0,30
    800060e6:	050e                	slli	a0,a0,0x3
    800060e8:	9526                	add	a0,a0,s1
    800060ea:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    800060ee:	fd043503          	ld	a0,-48(s0)
    800060f2:	fffff097          	auipc	ra,0xfffff
    800060f6:	a30080e7          	jalr	-1488(ra) # 80004b22 <fileclose>
    fileclose(wf);
    800060fa:	fc843503          	ld	a0,-56(s0)
    800060fe:	fffff097          	auipc	ra,0xfffff
    80006102:	a24080e7          	jalr	-1500(ra) # 80004b22 <fileclose>
    return -1;
    80006106:	57fd                	li	a5,-1
    80006108:	a805                	j	80006138 <sys_pipe+0x104>
    if(fd0 >= 0)
    8000610a:	fc442783          	lw	a5,-60(s0)
    8000610e:	0007c863          	bltz	a5,8000611e <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80006112:	01e78513          	addi	a0,a5,30
    80006116:	050e                	slli	a0,a0,0x3
    80006118:	9526                	add	a0,a0,s1
    8000611a:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    8000611e:	fd043503          	ld	a0,-48(s0)
    80006122:	fffff097          	auipc	ra,0xfffff
    80006126:	a00080e7          	jalr	-1536(ra) # 80004b22 <fileclose>
    fileclose(wf);
    8000612a:	fc843503          	ld	a0,-56(s0)
    8000612e:	fffff097          	auipc	ra,0xfffff
    80006132:	9f4080e7          	jalr	-1548(ra) # 80004b22 <fileclose>
    return -1;
    80006136:	57fd                	li	a5,-1
}
    80006138:	853e                	mv	a0,a5
    8000613a:	70e2                	ld	ra,56(sp)
    8000613c:	7442                	ld	s0,48(sp)
    8000613e:	74a2                	ld	s1,40(sp)
    80006140:	6121                	addi	sp,sp,64
    80006142:	8082                	ret
	...

0000000080006150 <kernelvec>:
    80006150:	7111                	addi	sp,sp,-256
    80006152:	e006                	sd	ra,0(sp)
    80006154:	e40a                	sd	sp,8(sp)
    80006156:	e80e                	sd	gp,16(sp)
    80006158:	ec12                	sd	tp,24(sp)
    8000615a:	f016                	sd	t0,32(sp)
    8000615c:	f41a                	sd	t1,40(sp)
    8000615e:	f81e                	sd	t2,48(sp)
    80006160:	fc22                	sd	s0,56(sp)
    80006162:	e0a6                	sd	s1,64(sp)
    80006164:	e4aa                	sd	a0,72(sp)
    80006166:	e8ae                	sd	a1,80(sp)
    80006168:	ecb2                	sd	a2,88(sp)
    8000616a:	f0b6                	sd	a3,96(sp)
    8000616c:	f4ba                	sd	a4,104(sp)
    8000616e:	f8be                	sd	a5,112(sp)
    80006170:	fcc2                	sd	a6,120(sp)
    80006172:	e146                	sd	a7,128(sp)
    80006174:	e54a                	sd	s2,136(sp)
    80006176:	e94e                	sd	s3,144(sp)
    80006178:	ed52                	sd	s4,152(sp)
    8000617a:	f156                	sd	s5,160(sp)
    8000617c:	f55a                	sd	s6,168(sp)
    8000617e:	f95e                	sd	s7,176(sp)
    80006180:	fd62                	sd	s8,184(sp)
    80006182:	e1e6                	sd	s9,192(sp)
    80006184:	e5ea                	sd	s10,200(sp)
    80006186:	e9ee                	sd	s11,208(sp)
    80006188:	edf2                	sd	t3,216(sp)
    8000618a:	f1f6                	sd	t4,224(sp)
    8000618c:	f5fa                	sd	t5,232(sp)
    8000618e:	f9fe                	sd	t6,240(sp)
    80006190:	9b1fc0ef          	jal	ra,80002b40 <kerneltrap>
    80006194:	6082                	ld	ra,0(sp)
    80006196:	6122                	ld	sp,8(sp)
    80006198:	61c2                	ld	gp,16(sp)
    8000619a:	7282                	ld	t0,32(sp)
    8000619c:	7322                	ld	t1,40(sp)
    8000619e:	73c2                	ld	t2,48(sp)
    800061a0:	7462                	ld	s0,56(sp)
    800061a2:	6486                	ld	s1,64(sp)
    800061a4:	6526                	ld	a0,72(sp)
    800061a6:	65c6                	ld	a1,80(sp)
    800061a8:	6666                	ld	a2,88(sp)
    800061aa:	7686                	ld	a3,96(sp)
    800061ac:	7726                	ld	a4,104(sp)
    800061ae:	77c6                	ld	a5,112(sp)
    800061b0:	7866                	ld	a6,120(sp)
    800061b2:	688a                	ld	a7,128(sp)
    800061b4:	692a                	ld	s2,136(sp)
    800061b6:	69ca                	ld	s3,144(sp)
    800061b8:	6a6a                	ld	s4,152(sp)
    800061ba:	7a8a                	ld	s5,160(sp)
    800061bc:	7b2a                	ld	s6,168(sp)
    800061be:	7bca                	ld	s7,176(sp)
    800061c0:	7c6a                	ld	s8,184(sp)
    800061c2:	6c8e                	ld	s9,192(sp)
    800061c4:	6d2e                	ld	s10,200(sp)
    800061c6:	6dce                	ld	s11,208(sp)
    800061c8:	6e6e                	ld	t3,216(sp)
    800061ca:	7e8e                	ld	t4,224(sp)
    800061cc:	7f2e                	ld	t5,232(sp)
    800061ce:	7fce                	ld	t6,240(sp)
    800061d0:	6111                	addi	sp,sp,256
    800061d2:	10200073          	sret
    800061d6:	00000013          	nop
    800061da:	00000013          	nop
    800061de:	0001                	nop

00000000800061e0 <timervec>:
    800061e0:	34051573          	csrrw	a0,mscratch,a0
    800061e4:	e10c                	sd	a1,0(a0)
    800061e6:	e510                	sd	a2,8(a0)
    800061e8:	e914                	sd	a3,16(a0)
    800061ea:	6d0c                	ld	a1,24(a0)
    800061ec:	7110                	ld	a2,32(a0)
    800061ee:	6194                	ld	a3,0(a1)
    800061f0:	96b2                	add	a3,a3,a2
    800061f2:	e194                	sd	a3,0(a1)
    800061f4:	4589                	li	a1,2
    800061f6:	14459073          	csrw	sip,a1
    800061fa:	6914                	ld	a3,16(a0)
    800061fc:	6510                	ld	a2,8(a0)
    800061fe:	610c                	ld	a1,0(a0)
    80006200:	34051573          	csrrw	a0,mscratch,a0
    80006204:	30200073          	mret
	...

000000008000620a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000620a:	1141                	addi	sp,sp,-16
    8000620c:	e422                	sd	s0,8(sp)
    8000620e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006210:	0c0007b7          	lui	a5,0xc000
    80006214:	4705                	li	a4,1
    80006216:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006218:	c3d8                	sw	a4,4(a5)
}
    8000621a:	6422                	ld	s0,8(sp)
    8000621c:	0141                	addi	sp,sp,16
    8000621e:	8082                	ret

0000000080006220 <plicinithart>:

void
plicinithart(void)
{
    80006220:	1141                	addi	sp,sp,-16
    80006222:	e406                	sd	ra,8(sp)
    80006224:	e022                	sd	s0,0(sp)
    80006226:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006228:	ffffb097          	auipc	ra,0xffffb
    8000622c:	742080e7          	jalr	1858(ra) # 8000196a <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006230:	0085171b          	slliw	a4,a0,0x8
    80006234:	0c0027b7          	lui	a5,0xc002
    80006238:	97ba                	add	a5,a5,a4
    8000623a:	40200713          	li	a4,1026
    8000623e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006242:	00d5151b          	slliw	a0,a0,0xd
    80006246:	0c2017b7          	lui	a5,0xc201
    8000624a:	953e                	add	a0,a0,a5
    8000624c:	00052023          	sw	zero,0(a0)
}
    80006250:	60a2                	ld	ra,8(sp)
    80006252:	6402                	ld	s0,0(sp)
    80006254:	0141                	addi	sp,sp,16
    80006256:	8082                	ret

0000000080006258 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006258:	1141                	addi	sp,sp,-16
    8000625a:	e406                	sd	ra,8(sp)
    8000625c:	e022                	sd	s0,0(sp)
    8000625e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006260:	ffffb097          	auipc	ra,0xffffb
    80006264:	70a080e7          	jalr	1802(ra) # 8000196a <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006268:	00d5179b          	slliw	a5,a0,0xd
    8000626c:	0c201537          	lui	a0,0xc201
    80006270:	953e                	add	a0,a0,a5
  return irq;
}
    80006272:	4148                	lw	a0,4(a0)
    80006274:	60a2                	ld	ra,8(sp)
    80006276:	6402                	ld	s0,0(sp)
    80006278:	0141                	addi	sp,sp,16
    8000627a:	8082                	ret

000000008000627c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000627c:	1101                	addi	sp,sp,-32
    8000627e:	ec06                	sd	ra,24(sp)
    80006280:	e822                	sd	s0,16(sp)
    80006282:	e426                	sd	s1,8(sp)
    80006284:	1000                	addi	s0,sp,32
    80006286:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006288:	ffffb097          	auipc	ra,0xffffb
    8000628c:	6e2080e7          	jalr	1762(ra) # 8000196a <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006290:	00d5151b          	slliw	a0,a0,0xd
    80006294:	0c2017b7          	lui	a5,0xc201
    80006298:	97aa                	add	a5,a5,a0
    8000629a:	c3c4                	sw	s1,4(a5)
}
    8000629c:	60e2                	ld	ra,24(sp)
    8000629e:	6442                	ld	s0,16(sp)
    800062a0:	64a2                	ld	s1,8(sp)
    800062a2:	6105                	addi	sp,sp,32
    800062a4:	8082                	ret

00000000800062a6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800062a6:	1141                	addi	sp,sp,-16
    800062a8:	e406                	sd	ra,8(sp)
    800062aa:	e022                	sd	s0,0(sp)
    800062ac:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800062ae:	479d                	li	a5,7
    800062b0:	04a7cc63          	blt	a5,a0,80006308 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    800062b4:	0001d797          	auipc	a5,0x1d
    800062b8:	0b478793          	addi	a5,a5,180 # 80023368 <disk>
    800062bc:	97aa                	add	a5,a5,a0
    800062be:	0187c783          	lbu	a5,24(a5)
    800062c2:	ebb9                	bnez	a5,80006318 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800062c4:	00451613          	slli	a2,a0,0x4
    800062c8:	0001d797          	auipc	a5,0x1d
    800062cc:	0a078793          	addi	a5,a5,160 # 80023368 <disk>
    800062d0:	6394                	ld	a3,0(a5)
    800062d2:	96b2                	add	a3,a3,a2
    800062d4:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    800062d8:	6398                	ld	a4,0(a5)
    800062da:	9732                	add	a4,a4,a2
    800062dc:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    800062e0:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    800062e4:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    800062e8:	953e                	add	a0,a0,a5
    800062ea:	4785                	li	a5,1
    800062ec:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    800062f0:	0001d517          	auipc	a0,0x1d
    800062f4:	09050513          	addi	a0,a0,144 # 80023380 <disk+0x18>
    800062f8:	ffffc097          	auipc	ra,0xffffc
    800062fc:	1a2080e7          	jalr	418(ra) # 8000249a <wakeup>
}
    80006300:	60a2                	ld	ra,8(sp)
    80006302:	6402                	ld	s0,0(sp)
    80006304:	0141                	addi	sp,sp,16
    80006306:	8082                	ret
    panic("free_desc 1");
    80006308:	00002517          	auipc	a0,0x2
    8000630c:	4a850513          	addi	a0,a0,1192 # 800087b0 <syscalls+0x368>
    80006310:	ffffa097          	auipc	ra,0xffffa
    80006314:	228080e7          	jalr	552(ra) # 80000538 <panic>
    panic("free_desc 2");
    80006318:	00002517          	auipc	a0,0x2
    8000631c:	4a850513          	addi	a0,a0,1192 # 800087c0 <syscalls+0x378>
    80006320:	ffffa097          	auipc	ra,0xffffa
    80006324:	218080e7          	jalr	536(ra) # 80000538 <panic>

0000000080006328 <virtio_disk_init>:
{
    80006328:	1101                	addi	sp,sp,-32
    8000632a:	ec06                	sd	ra,24(sp)
    8000632c:	e822                	sd	s0,16(sp)
    8000632e:	e426                	sd	s1,8(sp)
    80006330:	e04a                	sd	s2,0(sp)
    80006332:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006334:	00002597          	auipc	a1,0x2
    80006338:	49c58593          	addi	a1,a1,1180 # 800087d0 <syscalls+0x388>
    8000633c:	0001d517          	auipc	a0,0x1d
    80006340:	15450513          	addi	a0,a0,340 # 80023490 <disk+0x128>
    80006344:	ffffa097          	auipc	ra,0xffffa
    80006348:	7fc080e7          	jalr	2044(ra) # 80000b40 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000634c:	100017b7          	lui	a5,0x10001
    80006350:	4398                	lw	a4,0(a5)
    80006352:	2701                	sext.w	a4,a4
    80006354:	747277b7          	lui	a5,0x74727
    80006358:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000635c:	14f71c63          	bne	a4,a5,800064b4 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006360:	100017b7          	lui	a5,0x10001
    80006364:	43dc                	lw	a5,4(a5)
    80006366:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006368:	4709                	li	a4,2
    8000636a:	14e79563          	bne	a5,a4,800064b4 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000636e:	100017b7          	lui	a5,0x10001
    80006372:	479c                	lw	a5,8(a5)
    80006374:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006376:	12e79f63          	bne	a5,a4,800064b4 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000637a:	100017b7          	lui	a5,0x10001
    8000637e:	47d8                	lw	a4,12(a5)
    80006380:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006382:	554d47b7          	lui	a5,0x554d4
    80006386:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000638a:	12f71563          	bne	a4,a5,800064b4 <virtio_disk_init+0x18c>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000638e:	100017b7          	lui	a5,0x10001
    80006392:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006396:	4705                	li	a4,1
    80006398:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000639a:	470d                	li	a4,3
    8000639c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000639e:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    800063a0:	c7ffe737          	lui	a4,0xc7ffe
    800063a4:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fdb2b7>
    800063a8:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800063aa:	2701                	sext.w	a4,a4
    800063ac:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800063ae:	472d                	li	a4,11
    800063b0:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    800063b2:	5bbc                	lw	a5,112(a5)
    800063b4:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    800063b8:	8ba1                	andi	a5,a5,8
    800063ba:	10078563          	beqz	a5,800064c4 <virtio_disk_init+0x19c>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800063be:	100017b7          	lui	a5,0x10001
    800063c2:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    800063c6:	43fc                	lw	a5,68(a5)
    800063c8:	2781                	sext.w	a5,a5
    800063ca:	10079563          	bnez	a5,800064d4 <virtio_disk_init+0x1ac>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800063ce:	100017b7          	lui	a5,0x10001
    800063d2:	5bdc                	lw	a5,52(a5)
    800063d4:	2781                	sext.w	a5,a5
  if(max == 0)
    800063d6:	10078763          	beqz	a5,800064e4 <virtio_disk_init+0x1bc>
  if(max < NUM)
    800063da:	471d                	li	a4,7
    800063dc:	10f77c63          	bgeu	a4,a5,800064f4 <virtio_disk_init+0x1cc>
  disk.desc = kalloc();
    800063e0:	ffffa097          	auipc	ra,0xffffa
    800063e4:	700080e7          	jalr	1792(ra) # 80000ae0 <kalloc>
    800063e8:	0001d497          	auipc	s1,0x1d
    800063ec:	f8048493          	addi	s1,s1,-128 # 80023368 <disk>
    800063f0:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    800063f2:	ffffa097          	auipc	ra,0xffffa
    800063f6:	6ee080e7          	jalr	1774(ra) # 80000ae0 <kalloc>
    800063fa:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    800063fc:	ffffa097          	auipc	ra,0xffffa
    80006400:	6e4080e7          	jalr	1764(ra) # 80000ae0 <kalloc>
    80006404:	87aa                	mv	a5,a0
    80006406:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006408:	6088                	ld	a0,0(s1)
    8000640a:	cd6d                	beqz	a0,80006504 <virtio_disk_init+0x1dc>
    8000640c:	0001d717          	auipc	a4,0x1d
    80006410:	f6473703          	ld	a4,-156(a4) # 80023370 <disk+0x8>
    80006414:	cb65                	beqz	a4,80006504 <virtio_disk_init+0x1dc>
    80006416:	c7fd                	beqz	a5,80006504 <virtio_disk_init+0x1dc>
  memset(disk.desc, 0, PGSIZE);
    80006418:	6605                	lui	a2,0x1
    8000641a:	4581                	li	a1,0
    8000641c:	ffffb097          	auipc	ra,0xffffb
    80006420:	8b0080e7          	jalr	-1872(ra) # 80000ccc <memset>
  memset(disk.avail, 0, PGSIZE);
    80006424:	0001d497          	auipc	s1,0x1d
    80006428:	f4448493          	addi	s1,s1,-188 # 80023368 <disk>
    8000642c:	6605                	lui	a2,0x1
    8000642e:	4581                	li	a1,0
    80006430:	6488                	ld	a0,8(s1)
    80006432:	ffffb097          	auipc	ra,0xffffb
    80006436:	89a080e7          	jalr	-1894(ra) # 80000ccc <memset>
  memset(disk.used, 0, PGSIZE);
    8000643a:	6605                	lui	a2,0x1
    8000643c:	4581                	li	a1,0
    8000643e:	6888                	ld	a0,16(s1)
    80006440:	ffffb097          	auipc	ra,0xffffb
    80006444:	88c080e7          	jalr	-1908(ra) # 80000ccc <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006448:	100017b7          	lui	a5,0x10001
    8000644c:	4721                	li	a4,8
    8000644e:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80006450:	4098                	lw	a4,0(s1)
    80006452:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006456:	40d8                	lw	a4,4(s1)
    80006458:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000645c:	6498                	ld	a4,8(s1)
    8000645e:	0007069b          	sext.w	a3,a4
    80006462:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006466:	9701                	srai	a4,a4,0x20
    80006468:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000646c:	6898                	ld	a4,16(s1)
    8000646e:	0007069b          	sext.w	a3,a4
    80006472:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006476:	9701                	srai	a4,a4,0x20
    80006478:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000647c:	4705                	li	a4,1
    8000647e:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    80006480:	00e48c23          	sb	a4,24(s1)
    80006484:	00e48ca3          	sb	a4,25(s1)
    80006488:	00e48d23          	sb	a4,26(s1)
    8000648c:	00e48da3          	sb	a4,27(s1)
    80006490:	00e48e23          	sb	a4,28(s1)
    80006494:	00e48ea3          	sb	a4,29(s1)
    80006498:	00e48f23          	sb	a4,30(s1)
    8000649c:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    800064a0:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    800064a4:	0727a823          	sw	s2,112(a5)
}
    800064a8:	60e2                	ld	ra,24(sp)
    800064aa:	6442                	ld	s0,16(sp)
    800064ac:	64a2                	ld	s1,8(sp)
    800064ae:	6902                	ld	s2,0(sp)
    800064b0:	6105                	addi	sp,sp,32
    800064b2:	8082                	ret
    panic("could not find virtio disk");
    800064b4:	00002517          	auipc	a0,0x2
    800064b8:	32c50513          	addi	a0,a0,812 # 800087e0 <syscalls+0x398>
    800064bc:	ffffa097          	auipc	ra,0xffffa
    800064c0:	07c080e7          	jalr	124(ra) # 80000538 <panic>
    panic("virtio disk FEATURES_OK unset");
    800064c4:	00002517          	auipc	a0,0x2
    800064c8:	33c50513          	addi	a0,a0,828 # 80008800 <syscalls+0x3b8>
    800064cc:	ffffa097          	auipc	ra,0xffffa
    800064d0:	06c080e7          	jalr	108(ra) # 80000538 <panic>
    panic("virtio disk should not be ready");
    800064d4:	00002517          	auipc	a0,0x2
    800064d8:	34c50513          	addi	a0,a0,844 # 80008820 <syscalls+0x3d8>
    800064dc:	ffffa097          	auipc	ra,0xffffa
    800064e0:	05c080e7          	jalr	92(ra) # 80000538 <panic>
    panic("virtio disk has no queue 0");
    800064e4:	00002517          	auipc	a0,0x2
    800064e8:	35c50513          	addi	a0,a0,860 # 80008840 <syscalls+0x3f8>
    800064ec:	ffffa097          	auipc	ra,0xffffa
    800064f0:	04c080e7          	jalr	76(ra) # 80000538 <panic>
    panic("virtio disk max queue too short");
    800064f4:	00002517          	auipc	a0,0x2
    800064f8:	36c50513          	addi	a0,a0,876 # 80008860 <syscalls+0x418>
    800064fc:	ffffa097          	auipc	ra,0xffffa
    80006500:	03c080e7          	jalr	60(ra) # 80000538 <panic>
    panic("virtio disk kalloc");
    80006504:	00002517          	auipc	a0,0x2
    80006508:	37c50513          	addi	a0,a0,892 # 80008880 <syscalls+0x438>
    8000650c:	ffffa097          	auipc	ra,0xffffa
    80006510:	02c080e7          	jalr	44(ra) # 80000538 <panic>

0000000080006514 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006514:	7119                	addi	sp,sp,-128
    80006516:	fc86                	sd	ra,120(sp)
    80006518:	f8a2                	sd	s0,112(sp)
    8000651a:	f4a6                	sd	s1,104(sp)
    8000651c:	f0ca                	sd	s2,96(sp)
    8000651e:	ecce                	sd	s3,88(sp)
    80006520:	e8d2                	sd	s4,80(sp)
    80006522:	e4d6                	sd	s5,72(sp)
    80006524:	e0da                	sd	s6,64(sp)
    80006526:	fc5e                	sd	s7,56(sp)
    80006528:	f862                	sd	s8,48(sp)
    8000652a:	f466                	sd	s9,40(sp)
    8000652c:	f06a                	sd	s10,32(sp)
    8000652e:	ec6e                	sd	s11,24(sp)
    80006530:	0100                	addi	s0,sp,128
    80006532:	8aaa                	mv	s5,a0
    80006534:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006536:	00c52d03          	lw	s10,12(a0)
    8000653a:	001d1d1b          	slliw	s10,s10,0x1
    8000653e:	1d02                	slli	s10,s10,0x20
    80006540:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    80006544:	0001d517          	auipc	a0,0x1d
    80006548:	f4c50513          	addi	a0,a0,-180 # 80023490 <disk+0x128>
    8000654c:	ffffa097          	auipc	ra,0xffffa
    80006550:	684080e7          	jalr	1668(ra) # 80000bd0 <acquire>
  for(int i = 0; i < 3; i++){
    80006554:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006556:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006558:	0001db97          	auipc	s7,0x1d
    8000655c:	e10b8b93          	addi	s7,s7,-496 # 80023368 <disk>
  for(int i = 0; i < 3; i++){
    80006560:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006562:	0001dc97          	auipc	s9,0x1d
    80006566:	f2ec8c93          	addi	s9,s9,-210 # 80023490 <disk+0x128>
    8000656a:	a08d                	j	800065cc <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    8000656c:	00fb8733          	add	a4,s7,a5
    80006570:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006574:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006576:	0207c563          	bltz	a5,800065a0 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    8000657a:	2905                	addiw	s2,s2,1
    8000657c:	0611                	addi	a2,a2,4
    8000657e:	05690c63          	beq	s2,s6,800065d6 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80006582:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006584:	0001d717          	auipc	a4,0x1d
    80006588:	de470713          	addi	a4,a4,-540 # 80023368 <disk>
    8000658c:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000658e:	01874683          	lbu	a3,24(a4)
    80006592:	fee9                	bnez	a3,8000656c <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006594:	2785                	addiw	a5,a5,1
    80006596:	0705                	addi	a4,a4,1
    80006598:	fe979be3          	bne	a5,s1,8000658e <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    8000659c:	57fd                	li	a5,-1
    8000659e:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    800065a0:	01205d63          	blez	s2,800065ba <virtio_disk_rw+0xa6>
    800065a4:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    800065a6:	000a2503          	lw	a0,0(s4)
    800065aa:	00000097          	auipc	ra,0x0
    800065ae:	cfc080e7          	jalr	-772(ra) # 800062a6 <free_desc>
      for(int j = 0; j < i; j++)
    800065b2:	2d85                	addiw	s11,s11,1
    800065b4:	0a11                	addi	s4,s4,4
    800065b6:	ffb918e3          	bne	s2,s11,800065a6 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    800065ba:	85e6                	mv	a1,s9
    800065bc:	0001d517          	auipc	a0,0x1d
    800065c0:	dc450513          	addi	a0,a0,-572 # 80023380 <disk+0x18>
    800065c4:	ffffc097          	auipc	ra,0xffffc
    800065c8:	d44080e7          	jalr	-700(ra) # 80002308 <sleep>
  for(int i = 0; i < 3; i++){
    800065cc:	f8040a13          	addi	s4,s0,-128
{
    800065d0:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    800065d2:	894e                	mv	s2,s3
    800065d4:	b77d                	j	80006582 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800065d6:	f8042583          	lw	a1,-128(s0)
    800065da:	00a58793          	addi	a5,a1,10
    800065de:	0792                	slli	a5,a5,0x4

  if(write)
    800065e0:	0001d617          	auipc	a2,0x1d
    800065e4:	d8860613          	addi	a2,a2,-632 # 80023368 <disk>
    800065e8:	00f60733          	add	a4,a2,a5
    800065ec:	018036b3          	snez	a3,s8
    800065f0:	c714                	sw	a3,8(a4)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800065f2:	00072623          	sw	zero,12(a4)
  buf0->sector = sector;
    800065f6:	01a73823          	sd	s10,16(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800065fa:	f6078693          	addi	a3,a5,-160
    800065fe:	6218                	ld	a4,0(a2)
    80006600:	9736                	add	a4,a4,a3
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006602:	00878513          	addi	a0,a5,8
    80006606:	9532                	add	a0,a0,a2
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006608:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    8000660a:	6208                	ld	a0,0(a2)
    8000660c:	96aa                	add	a3,a3,a0
    8000660e:	4741                	li	a4,16
    80006610:	c698                	sw	a4,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006612:	4705                	li	a4,1
    80006614:	00e69623          	sh	a4,12(a3)
  disk.desc[idx[0]].next = idx[1];
    80006618:	f8442703          	lw	a4,-124(s0)
    8000661c:	00e69723          	sh	a4,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006620:	0712                	slli	a4,a4,0x4
    80006622:	953a                	add	a0,a0,a4
    80006624:	058a8693          	addi	a3,s5,88
    80006628:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    8000662a:	6208                	ld	a0,0(a2)
    8000662c:	972a                	add	a4,a4,a0
    8000662e:	40000693          	li	a3,1024
    80006632:	c714                	sw	a3,8(a4)
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006634:	001c3c13          	seqz	s8,s8
    80006638:	0c06                	slli	s8,s8,0x1
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000663a:	001c6c13          	ori	s8,s8,1
    8000663e:	01871623          	sh	s8,12(a4)
  disk.desc[idx[1]].next = idx[2];
    80006642:	f8842603          	lw	a2,-120(s0)
    80006646:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    8000664a:	0001d697          	auipc	a3,0x1d
    8000664e:	d1e68693          	addi	a3,a3,-738 # 80023368 <disk>
    80006652:	00258713          	addi	a4,a1,2
    80006656:	0712                	slli	a4,a4,0x4
    80006658:	9736                	add	a4,a4,a3
    8000665a:	587d                	li	a6,-1
    8000665c:	01070823          	sb	a6,16(a4)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006660:	0612                	slli	a2,a2,0x4
    80006662:	9532                	add	a0,a0,a2
    80006664:	f9078793          	addi	a5,a5,-112
    80006668:	97b6                	add	a5,a5,a3
    8000666a:	e11c                	sd	a5,0(a0)
  disk.desc[idx[2]].len = 1;
    8000666c:	629c                	ld	a5,0(a3)
    8000666e:	97b2                	add	a5,a5,a2
    80006670:	4605                	li	a2,1
    80006672:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006674:	4509                	li	a0,2
    80006676:	00a79623          	sh	a0,12(a5)
  disk.desc[idx[2]].next = 0;
    8000667a:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000667e:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    80006682:	01573423          	sd	s5,8(a4)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006686:	6698                	ld	a4,8(a3)
    80006688:	00275783          	lhu	a5,2(a4)
    8000668c:	8b9d                	andi	a5,a5,7
    8000668e:	0786                	slli	a5,a5,0x1
    80006690:	97ba                	add	a5,a5,a4
    80006692:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006696:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000669a:	6698                	ld	a4,8(a3)
    8000669c:	00275783          	lhu	a5,2(a4)
    800066a0:	2785                	addiw	a5,a5,1
    800066a2:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800066a6:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800066aa:	100017b7          	lui	a5,0x10001
    800066ae:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800066b2:	004aa783          	lw	a5,4(s5)
    800066b6:	02c79163          	bne	a5,a2,800066d8 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    800066ba:	0001d917          	auipc	s2,0x1d
    800066be:	dd690913          	addi	s2,s2,-554 # 80023490 <disk+0x128>
  while(b->disk == 1) {
    800066c2:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800066c4:	85ca                	mv	a1,s2
    800066c6:	8556                	mv	a0,s5
    800066c8:	ffffc097          	auipc	ra,0xffffc
    800066cc:	c40080e7          	jalr	-960(ra) # 80002308 <sleep>
  while(b->disk == 1) {
    800066d0:	004aa783          	lw	a5,4(s5)
    800066d4:	fe9788e3          	beq	a5,s1,800066c4 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    800066d8:	f8042903          	lw	s2,-128(s0)
    800066dc:	00290793          	addi	a5,s2,2
    800066e0:	00479713          	slli	a4,a5,0x4
    800066e4:	0001d797          	auipc	a5,0x1d
    800066e8:	c8478793          	addi	a5,a5,-892 # 80023368 <disk>
    800066ec:	97ba                	add	a5,a5,a4
    800066ee:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    800066f2:	0001d997          	auipc	s3,0x1d
    800066f6:	c7698993          	addi	s3,s3,-906 # 80023368 <disk>
    800066fa:	00491713          	slli	a4,s2,0x4
    800066fe:	0009b783          	ld	a5,0(s3)
    80006702:	97ba                	add	a5,a5,a4
    80006704:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006708:	854a                	mv	a0,s2
    8000670a:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000670e:	00000097          	auipc	ra,0x0
    80006712:	b98080e7          	jalr	-1128(ra) # 800062a6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006716:	8885                	andi	s1,s1,1
    80006718:	f0ed                	bnez	s1,800066fa <virtio_disk_rw+0x1e6>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000671a:	0001d517          	auipc	a0,0x1d
    8000671e:	d7650513          	addi	a0,a0,-650 # 80023490 <disk+0x128>
    80006722:	ffffa097          	auipc	ra,0xffffa
    80006726:	562080e7          	jalr	1378(ra) # 80000c84 <release>
}
    8000672a:	70e6                	ld	ra,120(sp)
    8000672c:	7446                	ld	s0,112(sp)
    8000672e:	74a6                	ld	s1,104(sp)
    80006730:	7906                	ld	s2,96(sp)
    80006732:	69e6                	ld	s3,88(sp)
    80006734:	6a46                	ld	s4,80(sp)
    80006736:	6aa6                	ld	s5,72(sp)
    80006738:	6b06                	ld	s6,64(sp)
    8000673a:	7be2                	ld	s7,56(sp)
    8000673c:	7c42                	ld	s8,48(sp)
    8000673e:	7ca2                	ld	s9,40(sp)
    80006740:	7d02                	ld	s10,32(sp)
    80006742:	6de2                	ld	s11,24(sp)
    80006744:	6109                	addi	sp,sp,128
    80006746:	8082                	ret

0000000080006748 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006748:	1101                	addi	sp,sp,-32
    8000674a:	ec06                	sd	ra,24(sp)
    8000674c:	e822                	sd	s0,16(sp)
    8000674e:	e426                	sd	s1,8(sp)
    80006750:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006752:	0001d497          	auipc	s1,0x1d
    80006756:	c1648493          	addi	s1,s1,-1002 # 80023368 <disk>
    8000675a:	0001d517          	auipc	a0,0x1d
    8000675e:	d3650513          	addi	a0,a0,-714 # 80023490 <disk+0x128>
    80006762:	ffffa097          	auipc	ra,0xffffa
    80006766:	46e080e7          	jalr	1134(ra) # 80000bd0 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000676a:	10001737          	lui	a4,0x10001
    8000676e:	533c                	lw	a5,96(a4)
    80006770:	8b8d                	andi	a5,a5,3
    80006772:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006774:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006778:	689c                	ld	a5,16(s1)
    8000677a:	0204d703          	lhu	a4,32(s1)
    8000677e:	0027d783          	lhu	a5,2(a5)
    80006782:	04f70863          	beq	a4,a5,800067d2 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006786:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000678a:	6898                	ld	a4,16(s1)
    8000678c:	0204d783          	lhu	a5,32(s1)
    80006790:	8b9d                	andi	a5,a5,7
    80006792:	078e                	slli	a5,a5,0x3
    80006794:	97ba                	add	a5,a5,a4
    80006796:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006798:	00278713          	addi	a4,a5,2
    8000679c:	0712                	slli	a4,a4,0x4
    8000679e:	9726                	add	a4,a4,s1
    800067a0:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    800067a4:	e721                	bnez	a4,800067ec <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800067a6:	0789                	addi	a5,a5,2
    800067a8:	0792                	slli	a5,a5,0x4
    800067aa:	97a6                	add	a5,a5,s1
    800067ac:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    800067ae:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800067b2:	ffffc097          	auipc	ra,0xffffc
    800067b6:	ce8080e7          	jalr	-792(ra) # 8000249a <wakeup>

    disk.used_idx += 1;
    800067ba:	0204d783          	lhu	a5,32(s1)
    800067be:	2785                	addiw	a5,a5,1
    800067c0:	17c2                	slli	a5,a5,0x30
    800067c2:	93c1                	srli	a5,a5,0x30
    800067c4:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800067c8:	6898                	ld	a4,16(s1)
    800067ca:	00275703          	lhu	a4,2(a4)
    800067ce:	faf71ce3          	bne	a4,a5,80006786 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    800067d2:	0001d517          	auipc	a0,0x1d
    800067d6:	cbe50513          	addi	a0,a0,-834 # 80023490 <disk+0x128>
    800067da:	ffffa097          	auipc	ra,0xffffa
    800067de:	4aa080e7          	jalr	1194(ra) # 80000c84 <release>
}
    800067e2:	60e2                	ld	ra,24(sp)
    800067e4:	6442                	ld	s0,16(sp)
    800067e6:	64a2                	ld	s1,8(sp)
    800067e8:	6105                	addi	sp,sp,32
    800067ea:	8082                	ret
      panic("virtio_disk_intr status");
    800067ec:	00002517          	auipc	a0,0x2
    800067f0:	0ac50513          	addi	a0,a0,172 # 80008898 <syscalls+0x450>
    800067f4:	ffffa097          	auipc	ra,0xffffa
    800067f8:	d44080e7          	jalr	-700(ra) # 80000538 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	18031073          	csrw	satp,t1
    80007092:	12000073          	sfence.vma
    80007096:	8282                	jr	t0

0000000080007098 <userret>:
    80007098:	18051073          	csrw	satp,a0
    8000709c:	12000073          	sfence.vma
    800070a0:	02000537          	lui	a0,0x2000
    800070a4:	357d                	addiw	a0,a0,-1
    800070a6:	0536                	slli	a0,a0,0xd
    800070a8:	02853083          	ld	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    800070ac:	03053103          	ld	sp,48(a0)
    800070b0:	03853183          	ld	gp,56(a0)
    800070b4:	04053203          	ld	tp,64(a0)
    800070b8:	04853283          	ld	t0,72(a0)
    800070bc:	05053303          	ld	t1,80(a0)
    800070c0:	05853383          	ld	t2,88(a0)
    800070c4:	7120                	ld	s0,96(a0)
    800070c6:	7524                	ld	s1,104(a0)
    800070c8:	7d2c                	ld	a1,120(a0)
    800070ca:	6150                	ld	a2,128(a0)
    800070cc:	6554                	ld	a3,136(a0)
    800070ce:	6958                	ld	a4,144(a0)
    800070d0:	6d5c                	ld	a5,152(a0)
    800070d2:	0a053803          	ld	a6,160(a0)
    800070d6:	0a853883          	ld	a7,168(a0)
    800070da:	0b053903          	ld	s2,176(a0)
    800070de:	0b853983          	ld	s3,184(a0)
    800070e2:	0c053a03          	ld	s4,192(a0)
    800070e6:	0c853a83          	ld	s5,200(a0)
    800070ea:	0d053b03          	ld	s6,208(a0)
    800070ee:	0d853b83          	ld	s7,216(a0)
    800070f2:	0e053c03          	ld	s8,224(a0)
    800070f6:	0e853c83          	ld	s9,232(a0)
    800070fa:	0f053d03          	ld	s10,240(a0)
    800070fe:	0f853d83          	ld	s11,248(a0)
    80007102:	10053e03          	ld	t3,256(a0)
    80007106:	10853e83          	ld	t4,264(a0)
    8000710a:	11053f03          	ld	t5,272(a0)
    8000710e:	11853f83          	ld	t6,280(a0)
    80007112:	7928                	ld	a0,112(a0)
    80007114:	10200073          	sret
	...
