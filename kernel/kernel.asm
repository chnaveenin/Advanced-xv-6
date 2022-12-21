
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	b9813103          	ld	sp,-1128(sp) # 80008b98 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	076000ef          	jal	ra,8000008c <start>

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
    80000026:	0007859b          	sext.w	a1,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873703          	ld	a4,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	9732                	add	a4,a4,a2
    80000046:	e398                	sd	a4,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00259693          	slli	a3,a1,0x2
    8000004c:	96ae                	add	a3,a3,a1
    8000004e:	068e                	slli	a3,a3,0x3
    80000050:	00009717          	auipc	a4,0x9
    80000054:	ba070713          	addi	a4,a4,-1120 # 80008bf0 <timer_scratch>
    80000058:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005a:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005c:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    8000005e:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000062:	00006797          	auipc	a5,0x6
    80000066:	55e78793          	addi	a5,a5,1374 # 800065c0 <timervec>
    8000006a:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000006e:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000072:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000076:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007a:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    8000007e:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000082:	30479073          	csrw	mie,a5
}
    80000086:	6422                	ld	s0,8(sp)
    80000088:	0141                	addi	sp,sp,16
    8000008a:	8082                	ret

000000008000008c <start>:
{
    8000008c:	1141                	addi	sp,sp,-16
    8000008e:	e406                	sd	ra,8(sp)
    80000090:	e022                	sd	s0,0(sp)
    80000092:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000094:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000098:	7779                	lui	a4,0xffffe
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7fdbb587>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	f9678793          	addi	a5,a5,-106 # 80001042 <main>
    800000b4:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b8:	4781                	li	a5,0
    800000ba:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000be:	67c1                	lui	a5,0x10
    800000c0:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800000c2:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c6:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000ca:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000ce:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d2:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d6:	57fd                	li	a5,-1
    800000d8:	83a9                	srli	a5,a5,0xa
    800000da:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000de:	47bd                	li	a5,15
    800000e0:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e4:	00000097          	auipc	ra,0x0
    800000e8:	f38080e7          	jalr	-200(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ec:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f0:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f2:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f4:	30200073          	mret
}
    800000f8:	60a2                	ld	ra,8(sp)
    800000fa:	6402                	ld	s0,0(sp)
    800000fc:	0141                	addi	sp,sp,16
    800000fe:	8082                	ret

0000000080000100 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000100:	715d                	addi	sp,sp,-80
    80000102:	e486                	sd	ra,72(sp)
    80000104:	e0a2                	sd	s0,64(sp)
    80000106:	fc26                	sd	s1,56(sp)
    80000108:	f84a                	sd	s2,48(sp)
    8000010a:	f44e                	sd	s3,40(sp)
    8000010c:	f052                	sd	s4,32(sp)
    8000010e:	ec56                	sd	s5,24(sp)
    80000110:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000112:	04c05763          	blez	a2,80000160 <consolewrite+0x60>
    80000116:	8a2a                	mv	s4,a0
    80000118:	84ae                	mv	s1,a1
    8000011a:	89b2                	mv	s3,a2
    8000011c:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011e:	5afd                	li	s5,-1
    80000120:	4685                	li	a3,1
    80000122:	8626                	mv	a2,s1
    80000124:	85d2                	mv	a1,s4
    80000126:	fbf40513          	addi	a0,s0,-65
    8000012a:	00002097          	auipc	ra,0x2
    8000012e:	6ac080e7          	jalr	1708(ra) # 800027d6 <either_copyin>
    80000132:	01550d63          	beq	a0,s5,8000014c <consolewrite+0x4c>
      break;
    uartputc(c);
    80000136:	fbf44503          	lbu	a0,-65(s0)
    8000013a:	00000097          	auipc	ra,0x0
    8000013e:	784080e7          	jalr	1924(ra) # 800008be <uartputc>
  for(i = 0; i < n; i++){
    80000142:	2905                	addiw	s2,s2,1
    80000144:	0485                	addi	s1,s1,1
    80000146:	fd299de3          	bne	s3,s2,80000120 <consolewrite+0x20>
    8000014a:	894e                	mv	s2,s3
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
    80000162:	b7ed                	j	8000014c <consolewrite+0x4c>

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
    8000018e:	ba650513          	addi	a0,a0,-1114 # 80010d30 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	c0e080e7          	jalr	-1010(ra) # 80000da0 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	b9648493          	addi	s1,s1,-1130 # 80010d30 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	c2690913          	addi	s2,s2,-986 # 80010dc8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

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
    800001b0:	07305b63          	blez	s3,80000226 <consoleread+0xc2>
    while(cons.r == cons.w){
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71763          	bne	a4,a5,800001ea <consoleread+0x86>
      if(killed(myproc())){
    800001c0:	00002097          	auipc	ra,0x2
    800001c4:	9f4080e7          	jalr	-1548(ra) # 80001bb4 <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	458080e7          	jalr	1112(ra) # 80002620 <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	196080e7          	jalr	406(ra) # 8000236c <sleep>
    while(cons.r == cons.w){
    800001de:	0984a783          	lw	a5,152(s1)
    800001e2:	09c4a703          	lw	a4,156(s1)
    800001e6:	fcf70de3          	beq	a4,a5,800001c0 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ea:	0017871b          	addiw	a4,a5,1
    800001ee:	08e4ac23          	sw	a4,152(s1)
    800001f2:	07f7f713          	andi	a4,a5,127
    800001f6:	9726                	add	a4,a4,s1
    800001f8:	01874703          	lbu	a4,24(a4)
    800001fc:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    80000200:	077d0563          	beq	s10,s7,8000026a <consoleread+0x106>
    cbuf = c;
    80000204:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000208:	4685                	li	a3,1
    8000020a:	f9f40613          	addi	a2,s0,-97
    8000020e:	85d2                	mv	a1,s4
    80000210:	8556                	mv	a0,s5
    80000212:	00002097          	auipc	ra,0x2
    80000216:	56e080e7          	jalr	1390(ra) # 80002780 <either_copyout>
    8000021a:	01850663          	beq	a0,s8,80000226 <consoleread+0xc2>
    dst++;
    8000021e:	0a05                	addi	s4,s4,1
    --n;
    80000220:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    80000222:	f99d17e3          	bne	s10,s9,800001b0 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000226:	00011517          	auipc	a0,0x11
    8000022a:	b0a50513          	addi	a0,a0,-1270 # 80010d30 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	c26080e7          	jalr	-986(ra) # 80000e54 <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	af450513          	addi	a0,a0,-1292 # 80010d30 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	c10080e7          	jalr	-1008(ra) # 80000e54 <release>
        return -1;
    8000024c:	557d                	li	a0,-1
}
    8000024e:	70a6                	ld	ra,104(sp)
    80000250:	7406                	ld	s0,96(sp)
    80000252:	64e6                	ld	s1,88(sp)
    80000254:	6946                	ld	s2,80(sp)
    80000256:	69a6                	ld	s3,72(sp)
    80000258:	6a06                	ld	s4,64(sp)
    8000025a:	7ae2                	ld	s5,56(sp)
    8000025c:	7b42                	ld	s6,48(sp)
    8000025e:	7ba2                	ld	s7,40(sp)
    80000260:	7c02                	ld	s8,32(sp)
    80000262:	6ce2                	ld	s9,24(sp)
    80000264:	6d42                	ld	s10,16(sp)
    80000266:	6165                	addi	sp,sp,112
    80000268:	8082                	ret
      if(n < target){
    8000026a:	0009871b          	sext.w	a4,s3
    8000026e:	fb677ce3          	bgeu	a4,s6,80000226 <consoleread+0xc2>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	b4f72b23          	sw	a5,-1194(a4) # 80010dc8 <cons+0x98>
    8000027a:	b775                	j	80000226 <consoleread+0xc2>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	560080e7          	jalr	1376(ra) # 800007ec <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	54e080e7          	jalr	1358(ra) # 800007ec <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	542080e7          	jalr	1346(ra) # 800007ec <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	538080e7          	jalr	1336(ra) # 800007ec <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00011517          	auipc	a0,0x11
    800002d0:	a6450513          	addi	a0,a0,-1436 # 80010d30 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	acc080e7          	jalr	-1332(ra) # 80000da0 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	53a080e7          	jalr	1338(ra) # 8000282c <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	a3650513          	addi	a0,a0,-1482 # 80010d30 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	b52080e7          	jalr	-1198(ra) # 80000e54 <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    8000031e:	00011717          	auipc	a4,0x11
    80000322:	a1270713          	addi	a4,a4,-1518 # 80010d30 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000348:	00011797          	auipc	a5,0x11
    8000034c:	9e878793          	addi	a5,a5,-1560 # 80010d30 <cons>
    80000350:	0a07a683          	lw	a3,160(a5)
    80000354:	0016871b          	addiw	a4,a3,1
    80000358:	0007061b          	sext.w	a2,a4
    8000035c:	0ae7a023          	sw	a4,160(a5)
    80000360:	07f6f693          	andi	a3,a3,127
    80000364:	97b6                	add	a5,a5,a3
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00011797          	auipc	a5,0x11
    8000037a:	a527a783          	lw	a5,-1454(a5) # 80010dc8 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	9a670713          	addi	a4,a4,-1626 # 80010d30 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	99648493          	addi	s1,s1,-1642 # 80010d30 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00011717          	auipc	a4,0x11
    800003da:	95a70713          	addi	a4,a4,-1702 # 80010d30 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	9ef72223          	sw	a5,-1564(a4) # 80010dd0 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000412:	00011797          	auipc	a5,0x11
    80000416:	91e78793          	addi	a5,a5,-1762 # 80010d30 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00011797          	auipc	a5,0x11
    8000043a:	98c7ab23          	sw	a2,-1642(a5) # 80010dcc <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00011517          	auipc	a0,0x11
    80000442:	98a50513          	addi	a0,a0,-1654 # 80010dc8 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	f8a080e7          	jalr	-118(ra) # 800023d0 <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00011517          	auipc	a0,0x11
    80000464:	8d050513          	addi	a0,a0,-1840 # 80010d30 <cons>
    80000468:	00001097          	auipc	ra,0x1
    8000046c:	8a8080e7          	jalr	-1880(ra) # 80000d10 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32c080e7          	jalr	812(ra) # 8000079c <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00242797          	auipc	a5,0x242
    8000047c:	c6878793          	addi	a5,a5,-920 # 802420e0 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7670713          	addi	a4,a4,-906 # 80000100 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054763          	bltz	a0,80000538 <printint+0x9c>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088c63          	beqz	a7,800004fe <printint+0x62>
    buf[i++] = '-';
    800004ea:	fe070793          	addi	a5,a4,-32
    800004ee:	00878733          	add	a4,a5,s0
    800004f2:	02d00793          	li	a5,45
    800004f6:	fef70823          	sb	a5,-16(a4)
    800004fa:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fe:	02e05763          	blez	a4,8000052c <printint+0x90>
    80000502:	fd040793          	addi	a5,s0,-48
    80000506:	00e784b3          	add	s1,a5,a4
    8000050a:	fff78913          	addi	s2,a5,-1
    8000050e:	993a                	add	s2,s2,a4
    80000510:	377d                	addiw	a4,a4,-1
    80000512:	1702                	slli	a4,a4,0x20
    80000514:	9301                	srli	a4,a4,0x20
    80000516:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000051a:	fff4c503          	lbu	a0,-1(s1)
    8000051e:	00000097          	auipc	ra,0x0
    80000522:	d5e080e7          	jalr	-674(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000526:	14fd                	addi	s1,s1,-1
    80000528:	ff2499e3          	bne	s1,s2,8000051a <printint+0x7e>
}
    8000052c:	70a2                	ld	ra,40(sp)
    8000052e:	7402                	ld	s0,32(sp)
    80000530:	64e2                	ld	s1,24(sp)
    80000532:	6942                	ld	s2,16(sp)
    80000534:	6145                	addi	sp,sp,48
    80000536:	8082                	ret
    x = -xx;
    80000538:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053c:	4885                	li	a7,1
    x = -xx;
    8000053e:	bf95                	j	800004b2 <printint+0x16>

0000000080000540 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000540:	1101                	addi	sp,sp,-32
    80000542:	ec06                	sd	ra,24(sp)
    80000544:	e822                	sd	s0,16(sp)
    80000546:	e426                	sd	s1,8(sp)
    80000548:	1000                	addi	s0,sp,32
    8000054a:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054c:	00011797          	auipc	a5,0x11
    80000550:	8a07a223          	sw	zero,-1884(a5) # 80010df0 <pr+0x18>
  printf("panic: ");
    80000554:	00008517          	auipc	a0,0x8
    80000558:	ac450513          	addi	a0,a0,-1340 # 80008018 <etext+0x18>
    8000055c:	00000097          	auipc	ra,0x0
    80000560:	02e080e7          	jalr	46(ra) # 8000058a <printf>
  printf(s);
    80000564:	8526                	mv	a0,s1
    80000566:	00000097          	auipc	ra,0x0
    8000056a:	024080e7          	jalr	36(ra) # 8000058a <printf>
  printf("\n");
    8000056e:	00008517          	auipc	a0,0x8
    80000572:	b9a50513          	addi	a0,a0,-1126 # 80008108 <digits+0xc8>
    80000576:	00000097          	auipc	ra,0x0
    8000057a:	014080e7          	jalr	20(ra) # 8000058a <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057e:	4785                	li	a5,1
    80000580:	00008717          	auipc	a4,0x8
    80000584:	62f72823          	sw	a5,1584(a4) # 80008bb0 <panicked>
  for(;;)
    80000588:	a001                	j	80000588 <panic+0x48>

000000008000058a <printf>:
{
    8000058a:	7131                	addi	sp,sp,-192
    8000058c:	fc86                	sd	ra,120(sp)
    8000058e:	f8a2                	sd	s0,112(sp)
    80000590:	f4a6                	sd	s1,104(sp)
    80000592:	f0ca                	sd	s2,96(sp)
    80000594:	ecce                	sd	s3,88(sp)
    80000596:	e8d2                	sd	s4,80(sp)
    80000598:	e4d6                	sd	s5,72(sp)
    8000059a:	e0da                	sd	s6,64(sp)
    8000059c:	fc5e                	sd	s7,56(sp)
    8000059e:	f862                	sd	s8,48(sp)
    800005a0:	f466                	sd	s9,40(sp)
    800005a2:	f06a                	sd	s10,32(sp)
    800005a4:	ec6e                	sd	s11,24(sp)
    800005a6:	0100                	addi	s0,sp,128
    800005a8:	8a2a                	mv	s4,a0
    800005aa:	e40c                	sd	a1,8(s0)
    800005ac:	e810                	sd	a2,16(s0)
    800005ae:	ec14                	sd	a3,24(s0)
    800005b0:	f018                	sd	a4,32(s0)
    800005b2:	f41c                	sd	a5,40(s0)
    800005b4:	03043823          	sd	a6,48(s0)
    800005b8:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005bc:	00011d97          	auipc	s11,0x11
    800005c0:	834dad83          	lw	s11,-1996(s11) # 80010df0 <pr+0x18>
  if(locking)
    800005c4:	020d9b63          	bnez	s11,800005fa <printf+0x70>
  if (fmt == 0)
    800005c8:	040a0263          	beqz	s4,8000060c <printf+0x82>
  va_start(ap, fmt);
    800005cc:	00840793          	addi	a5,s0,8
    800005d0:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d4:	000a4503          	lbu	a0,0(s4)
    800005d8:	14050f63          	beqz	a0,80000736 <printf+0x1ac>
    800005dc:	4981                	li	s3,0
    if(c != '%'){
    800005de:	02500a93          	li	s5,37
    switch(c){
    800005e2:	07000b93          	li	s7,112
  consputc('x');
    800005e6:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e8:	00008b17          	auipc	s6,0x8
    800005ec:	a58b0b13          	addi	s6,s6,-1448 # 80008040 <digits>
    switch(c){
    800005f0:	07300c93          	li	s9,115
    800005f4:	06400c13          	li	s8,100
    800005f8:	a82d                	j	80000632 <printf+0xa8>
    acquire(&pr.lock);
    800005fa:	00010517          	auipc	a0,0x10
    800005fe:	7de50513          	addi	a0,a0,2014 # 80010dd8 <pr>
    80000602:	00000097          	auipc	ra,0x0
    80000606:	79e080e7          	jalr	1950(ra) # 80000da0 <acquire>
    8000060a:	bf7d                	j	800005c8 <printf+0x3e>
    panic("null fmt");
    8000060c:	00008517          	auipc	a0,0x8
    80000610:	a1c50513          	addi	a0,a0,-1508 # 80008028 <etext+0x28>
    80000614:	00000097          	auipc	ra,0x0
    80000618:	f2c080e7          	jalr	-212(ra) # 80000540 <panic>
      consputc(c);
    8000061c:	00000097          	auipc	ra,0x0
    80000620:	c60080e7          	jalr	-928(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000624:	2985                	addiw	s3,s3,1
    80000626:	013a07b3          	add	a5,s4,s3
    8000062a:	0007c503          	lbu	a0,0(a5)
    8000062e:	10050463          	beqz	a0,80000736 <printf+0x1ac>
    if(c != '%'){
    80000632:	ff5515e3          	bne	a0,s5,8000061c <printf+0x92>
    c = fmt[++i] & 0xff;
    80000636:	2985                	addiw	s3,s3,1
    80000638:	013a07b3          	add	a5,s4,s3
    8000063c:	0007c783          	lbu	a5,0(a5)
    80000640:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000644:	cbed                	beqz	a5,80000736 <printf+0x1ac>
    switch(c){
    80000646:	05778a63          	beq	a5,s7,8000069a <printf+0x110>
    8000064a:	02fbf663          	bgeu	s7,a5,80000676 <printf+0xec>
    8000064e:	09978863          	beq	a5,s9,800006de <printf+0x154>
    80000652:	07800713          	li	a4,120
    80000656:	0ce79563          	bne	a5,a4,80000720 <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    8000065a:	f8843783          	ld	a5,-120(s0)
    8000065e:	00878713          	addi	a4,a5,8
    80000662:	f8e43423          	sd	a4,-120(s0)
    80000666:	4605                	li	a2,1
    80000668:	85ea                	mv	a1,s10
    8000066a:	4388                	lw	a0,0(a5)
    8000066c:	00000097          	auipc	ra,0x0
    80000670:	e30080e7          	jalr	-464(ra) # 8000049c <printint>
      break;
    80000674:	bf45                	j	80000624 <printf+0x9a>
    switch(c){
    80000676:	09578f63          	beq	a5,s5,80000714 <printf+0x18a>
    8000067a:	0b879363          	bne	a5,s8,80000720 <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000067e:	f8843783          	ld	a5,-120(s0)
    80000682:	00878713          	addi	a4,a5,8
    80000686:	f8e43423          	sd	a4,-120(s0)
    8000068a:	4605                	li	a2,1
    8000068c:	45a9                	li	a1,10
    8000068e:	4388                	lw	a0,0(a5)
    80000690:	00000097          	auipc	ra,0x0
    80000694:	e0c080e7          	jalr	-500(ra) # 8000049c <printint>
      break;
    80000698:	b771                	j	80000624 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000069a:	f8843783          	ld	a5,-120(s0)
    8000069e:	00878713          	addi	a4,a5,8
    800006a2:	f8e43423          	sd	a4,-120(s0)
    800006a6:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006aa:	03000513          	li	a0,48
    800006ae:	00000097          	auipc	ra,0x0
    800006b2:	bce080e7          	jalr	-1074(ra) # 8000027c <consputc>
  consputc('x');
    800006b6:	07800513          	li	a0,120
    800006ba:	00000097          	auipc	ra,0x0
    800006be:	bc2080e7          	jalr	-1086(ra) # 8000027c <consputc>
    800006c2:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c4:	03c95793          	srli	a5,s2,0x3c
    800006c8:	97da                	add	a5,a5,s6
    800006ca:	0007c503          	lbu	a0,0(a5)
    800006ce:	00000097          	auipc	ra,0x0
    800006d2:	bae080e7          	jalr	-1106(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d6:	0912                	slli	s2,s2,0x4
    800006d8:	34fd                	addiw	s1,s1,-1
    800006da:	f4ed                	bnez	s1,800006c4 <printf+0x13a>
    800006dc:	b7a1                	j	80000624 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	6384                	ld	s1,0(a5)
    800006ec:	cc89                	beqz	s1,80000706 <printf+0x17c>
      for(; *s; s++)
    800006ee:	0004c503          	lbu	a0,0(s1)
    800006f2:	d90d                	beqz	a0,80000624 <printf+0x9a>
        consputc(*s);
    800006f4:	00000097          	auipc	ra,0x0
    800006f8:	b88080e7          	jalr	-1144(ra) # 8000027c <consputc>
      for(; *s; s++)
    800006fc:	0485                	addi	s1,s1,1
    800006fe:	0004c503          	lbu	a0,0(s1)
    80000702:	f96d                	bnez	a0,800006f4 <printf+0x16a>
    80000704:	b705                	j	80000624 <printf+0x9a>
        s = "(null)";
    80000706:	00008497          	auipc	s1,0x8
    8000070a:	91a48493          	addi	s1,s1,-1766 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000070e:	02800513          	li	a0,40
    80000712:	b7cd                	j	800006f4 <printf+0x16a>
      consputc('%');
    80000714:	8556                	mv	a0,s5
    80000716:	00000097          	auipc	ra,0x0
    8000071a:	b66080e7          	jalr	-1178(ra) # 8000027c <consputc>
      break;
    8000071e:	b719                	j	80000624 <printf+0x9a>
      consputc('%');
    80000720:	8556                	mv	a0,s5
    80000722:	00000097          	auipc	ra,0x0
    80000726:	b5a080e7          	jalr	-1190(ra) # 8000027c <consputc>
      consputc(c);
    8000072a:	8526                	mv	a0,s1
    8000072c:	00000097          	auipc	ra,0x0
    80000730:	b50080e7          	jalr	-1200(ra) # 8000027c <consputc>
      break;
    80000734:	bdc5                	j	80000624 <printf+0x9a>
  if(locking)
    80000736:	020d9163          	bnez	s11,80000758 <printf+0x1ce>
}
    8000073a:	70e6                	ld	ra,120(sp)
    8000073c:	7446                	ld	s0,112(sp)
    8000073e:	74a6                	ld	s1,104(sp)
    80000740:	7906                	ld	s2,96(sp)
    80000742:	69e6                	ld	s3,88(sp)
    80000744:	6a46                	ld	s4,80(sp)
    80000746:	6aa6                	ld	s5,72(sp)
    80000748:	6b06                	ld	s6,64(sp)
    8000074a:	7be2                	ld	s7,56(sp)
    8000074c:	7c42                	ld	s8,48(sp)
    8000074e:	7ca2                	ld	s9,40(sp)
    80000750:	7d02                	ld	s10,32(sp)
    80000752:	6de2                	ld	s11,24(sp)
    80000754:	6129                	addi	sp,sp,192
    80000756:	8082                	ret
    release(&pr.lock);
    80000758:	00010517          	auipc	a0,0x10
    8000075c:	68050513          	addi	a0,a0,1664 # 80010dd8 <pr>
    80000760:	00000097          	auipc	ra,0x0
    80000764:	6f4080e7          	jalr	1780(ra) # 80000e54 <release>
}
    80000768:	bfc9                	j	8000073a <printf+0x1b0>

000000008000076a <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076a:	1101                	addi	sp,sp,-32
    8000076c:	ec06                	sd	ra,24(sp)
    8000076e:	e822                	sd	s0,16(sp)
    80000770:	e426                	sd	s1,8(sp)
    80000772:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000774:	00010497          	auipc	s1,0x10
    80000778:	66448493          	addi	s1,s1,1636 # 80010dd8 <pr>
    8000077c:	00008597          	auipc	a1,0x8
    80000780:	8bc58593          	addi	a1,a1,-1860 # 80008038 <etext+0x38>
    80000784:	8526                	mv	a0,s1
    80000786:	00000097          	auipc	ra,0x0
    8000078a:	58a080e7          	jalr	1418(ra) # 80000d10 <initlock>
  pr.locking = 1;
    8000078e:	4785                	li	a5,1
    80000790:	cc9c                	sw	a5,24(s1)
}
    80000792:	60e2                	ld	ra,24(sp)
    80000794:	6442                	ld	s0,16(sp)
    80000796:	64a2                	ld	s1,8(sp)
    80000798:	6105                	addi	sp,sp,32
    8000079a:	8082                	ret

000000008000079c <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000079c:	1141                	addi	sp,sp,-16
    8000079e:	e406                	sd	ra,8(sp)
    800007a0:	e022                	sd	s0,0(sp)
    800007a2:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a4:	100007b7          	lui	a5,0x10000
    800007a8:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007ac:	f8000713          	li	a4,-128
    800007b0:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b4:	470d                	li	a4,3
    800007b6:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007ba:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007be:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c2:	469d                	li	a3,7
    800007c4:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c8:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007cc:	00008597          	auipc	a1,0x8
    800007d0:	88c58593          	addi	a1,a1,-1908 # 80008058 <digits+0x18>
    800007d4:	00010517          	auipc	a0,0x10
    800007d8:	62450513          	addi	a0,a0,1572 # 80010df8 <uart_tx_lock>
    800007dc:	00000097          	auipc	ra,0x0
    800007e0:	534080e7          	jalr	1332(ra) # 80000d10 <initlock>
}
    800007e4:	60a2                	ld	ra,8(sp)
    800007e6:	6402                	ld	s0,0(sp)
    800007e8:	0141                	addi	sp,sp,16
    800007ea:	8082                	ret

00000000800007ec <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007ec:	1101                	addi	sp,sp,-32
    800007ee:	ec06                	sd	ra,24(sp)
    800007f0:	e822                	sd	s0,16(sp)
    800007f2:	e426                	sd	s1,8(sp)
    800007f4:	1000                	addi	s0,sp,32
    800007f6:	84aa                	mv	s1,a0
  push_off();
    800007f8:	00000097          	auipc	ra,0x0
    800007fc:	55c080e7          	jalr	1372(ra) # 80000d54 <push_off>

  if(panicked){
    80000800:	00008797          	auipc	a5,0x8
    80000804:	3b07a783          	lw	a5,944(a5) # 80008bb0 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000808:	10000737          	lui	a4,0x10000
  if(panicked){
    8000080c:	c391                	beqz	a5,80000810 <uartputc_sync+0x24>
    for(;;)
    8000080e:	a001                	j	8000080e <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000810:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000814:	0207f793          	andi	a5,a5,32
    80000818:	dfe5                	beqz	a5,80000810 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000081a:	0ff4f513          	zext.b	a0,s1
    8000081e:	100007b7          	lui	a5,0x10000
    80000822:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000826:	00000097          	auipc	ra,0x0
    8000082a:	5ce080e7          	jalr	1486(ra) # 80000df4 <pop_off>
}
    8000082e:	60e2                	ld	ra,24(sp)
    80000830:	6442                	ld	s0,16(sp)
    80000832:	64a2                	ld	s1,8(sp)
    80000834:	6105                	addi	sp,sp,32
    80000836:	8082                	ret

0000000080000838 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000838:	00008797          	auipc	a5,0x8
    8000083c:	3807b783          	ld	a5,896(a5) # 80008bb8 <uart_tx_r>
    80000840:	00008717          	auipc	a4,0x8
    80000844:	38073703          	ld	a4,896(a4) # 80008bc0 <uart_tx_w>
    80000848:	06f70a63          	beq	a4,a5,800008bc <uartstart+0x84>
{
    8000084c:	7139                	addi	sp,sp,-64
    8000084e:	fc06                	sd	ra,56(sp)
    80000850:	f822                	sd	s0,48(sp)
    80000852:	f426                	sd	s1,40(sp)
    80000854:	f04a                	sd	s2,32(sp)
    80000856:	ec4e                	sd	s3,24(sp)
    80000858:	e852                	sd	s4,16(sp)
    8000085a:	e456                	sd	s5,8(sp)
    8000085c:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000085e:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000862:	00010a17          	auipc	s4,0x10
    80000866:	596a0a13          	addi	s4,s4,1430 # 80010df8 <uart_tx_lock>
    uart_tx_r += 1;
    8000086a:	00008497          	auipc	s1,0x8
    8000086e:	34e48493          	addi	s1,s1,846 # 80008bb8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000872:	00008997          	auipc	s3,0x8
    80000876:	34e98993          	addi	s3,s3,846 # 80008bc0 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000087a:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000087e:	02077713          	andi	a4,a4,32
    80000882:	c705                	beqz	a4,800008aa <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000884:	01f7f713          	andi	a4,a5,31
    80000888:	9752                	add	a4,a4,s4
    8000088a:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000088e:	0785                	addi	a5,a5,1
    80000890:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000892:	8526                	mv	a0,s1
    80000894:	00002097          	auipc	ra,0x2
    80000898:	b3c080e7          	jalr	-1220(ra) # 800023d0 <wakeup>
    
    WriteReg(THR, c);
    8000089c:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008a0:	609c                	ld	a5,0(s1)
    800008a2:	0009b703          	ld	a4,0(s3)
    800008a6:	fcf71ae3          	bne	a4,a5,8000087a <uartstart+0x42>
  }
}
    800008aa:	70e2                	ld	ra,56(sp)
    800008ac:	7442                	ld	s0,48(sp)
    800008ae:	74a2                	ld	s1,40(sp)
    800008b0:	7902                	ld	s2,32(sp)
    800008b2:	69e2                	ld	s3,24(sp)
    800008b4:	6a42                	ld	s4,16(sp)
    800008b6:	6aa2                	ld	s5,8(sp)
    800008b8:	6121                	addi	sp,sp,64
    800008ba:	8082                	ret
    800008bc:	8082                	ret

00000000800008be <uartputc>:
{
    800008be:	7179                	addi	sp,sp,-48
    800008c0:	f406                	sd	ra,40(sp)
    800008c2:	f022                	sd	s0,32(sp)
    800008c4:	ec26                	sd	s1,24(sp)
    800008c6:	e84a                	sd	s2,16(sp)
    800008c8:	e44e                	sd	s3,8(sp)
    800008ca:	e052                	sd	s4,0(sp)
    800008cc:	1800                	addi	s0,sp,48
    800008ce:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008d0:	00010517          	auipc	a0,0x10
    800008d4:	52850513          	addi	a0,a0,1320 # 80010df8 <uart_tx_lock>
    800008d8:	00000097          	auipc	ra,0x0
    800008dc:	4c8080e7          	jalr	1224(ra) # 80000da0 <acquire>
  if(panicked){
    800008e0:	00008797          	auipc	a5,0x8
    800008e4:	2d07a783          	lw	a5,720(a5) # 80008bb0 <panicked>
    800008e8:	e7c9                	bnez	a5,80000972 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008ea:	00008717          	auipc	a4,0x8
    800008ee:	2d673703          	ld	a4,726(a4) # 80008bc0 <uart_tx_w>
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	2c67b783          	ld	a5,710(a5) # 80008bb8 <uart_tx_r>
    800008fa:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fe:	00010997          	auipc	s3,0x10
    80000902:	4fa98993          	addi	s3,s3,1274 # 80010df8 <uart_tx_lock>
    80000906:	00008497          	auipc	s1,0x8
    8000090a:	2b248493          	addi	s1,s1,690 # 80008bb8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090e:	00008917          	auipc	s2,0x8
    80000912:	2b290913          	addi	s2,s2,690 # 80008bc0 <uart_tx_w>
    80000916:	00e79f63          	bne	a5,a4,80000934 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000091a:	85ce                	mv	a1,s3
    8000091c:	8526                	mv	a0,s1
    8000091e:	00002097          	auipc	ra,0x2
    80000922:	a4e080e7          	jalr	-1458(ra) # 8000236c <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000926:	00093703          	ld	a4,0(s2)
    8000092a:	609c                	ld	a5,0(s1)
    8000092c:	02078793          	addi	a5,a5,32
    80000930:	fee785e3          	beq	a5,a4,8000091a <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000934:	00010497          	auipc	s1,0x10
    80000938:	4c448493          	addi	s1,s1,1220 # 80010df8 <uart_tx_lock>
    8000093c:	01f77793          	andi	a5,a4,31
    80000940:	97a6                	add	a5,a5,s1
    80000942:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000946:	0705                	addi	a4,a4,1
    80000948:	00008797          	auipc	a5,0x8
    8000094c:	26e7bc23          	sd	a4,632(a5) # 80008bc0 <uart_tx_w>
  uartstart();
    80000950:	00000097          	auipc	ra,0x0
    80000954:	ee8080e7          	jalr	-280(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    80000958:	8526                	mv	a0,s1
    8000095a:	00000097          	auipc	ra,0x0
    8000095e:	4fa080e7          	jalr	1274(ra) # 80000e54 <release>
}
    80000962:	70a2                	ld	ra,40(sp)
    80000964:	7402                	ld	s0,32(sp)
    80000966:	64e2                	ld	s1,24(sp)
    80000968:	6942                	ld	s2,16(sp)
    8000096a:	69a2                	ld	s3,8(sp)
    8000096c:	6a02                	ld	s4,0(sp)
    8000096e:	6145                	addi	sp,sp,48
    80000970:	8082                	ret
    for(;;)
    80000972:	a001                	j	80000972 <uartputc+0xb4>

0000000080000974 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000974:	1141                	addi	sp,sp,-16
    80000976:	e422                	sd	s0,8(sp)
    80000978:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    8000097a:	100007b7          	lui	a5,0x10000
    8000097e:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000982:	8b85                	andi	a5,a5,1
    80000984:	cb81                	beqz	a5,80000994 <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    8000098e:	6422                	ld	s0,8(sp)
    80000990:	0141                	addi	sp,sp,16
    80000992:	8082                	ret
    return -1;
    80000994:	557d                	li	a0,-1
    80000996:	bfe5                	j	8000098e <uartgetc+0x1a>

0000000080000998 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    80000998:	1101                	addi	sp,sp,-32
    8000099a:	ec06                	sd	ra,24(sp)
    8000099c:	e822                	sd	s0,16(sp)
    8000099e:	e426                	sd	s1,8(sp)
    800009a0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009a2:	54fd                	li	s1,-1
    800009a4:	a029                	j	800009ae <uartintr+0x16>
      break;
    consoleintr(c);
    800009a6:	00000097          	auipc	ra,0x0
    800009aa:	918080e7          	jalr	-1768(ra) # 800002be <consoleintr>
    int c = uartgetc();
    800009ae:	00000097          	auipc	ra,0x0
    800009b2:	fc6080e7          	jalr	-58(ra) # 80000974 <uartgetc>
    if(c == -1)
    800009b6:	fe9518e3          	bne	a0,s1,800009a6 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ba:	00010497          	auipc	s1,0x10
    800009be:	43e48493          	addi	s1,s1,1086 # 80010df8 <uart_tx_lock>
    800009c2:	8526                	mv	a0,s1
    800009c4:	00000097          	auipc	ra,0x0
    800009c8:	3dc080e7          	jalr	988(ra) # 80000da0 <acquire>
  uartstart();
    800009cc:	00000097          	auipc	ra,0x0
    800009d0:	e6c080e7          	jalr	-404(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    800009d4:	8526                	mv	a0,s1
    800009d6:	00000097          	auipc	ra,0x0
    800009da:	47e080e7          	jalr	1150(ra) # 80000e54 <release>
}
    800009de:	60e2                	ld	ra,24(sp)
    800009e0:	6442                	ld	s0,16(sp)
    800009e2:	64a2                	ld	s1,8(sp)
    800009e4:	6105                	addi	sp,sp,32
    800009e6:	8082                	ret

00000000800009e8 <init_page_ref>:
struct {
  struct spinlock lock;
  int count[MAX_COW];
} page_ref;

void init_page_ref(){
    800009e8:	1141                	addi	sp,sp,-16
    800009ea:	e406                	sd	ra,8(sp)
    800009ec:	e022                	sd	s0,0(sp)
    800009ee:	0800                	addi	s0,sp,16
  initlock(&page_ref.lock, "page_ref");
    800009f0:	00007597          	auipc	a1,0x7
    800009f4:	67058593          	addi	a1,a1,1648 # 80008060 <digits+0x20>
    800009f8:	00010517          	auipc	a0,0x10
    800009fc:	45850513          	addi	a0,a0,1112 # 80010e50 <page_ref>
    80000a00:	00000097          	auipc	ra,0x0
    80000a04:	310080e7          	jalr	784(ra) # 80000d10 <initlock>
  acquire(&page_ref.lock);
    80000a08:	00010517          	auipc	a0,0x10
    80000a0c:	44850513          	addi	a0,a0,1096 # 80010e50 <page_ref>
    80000a10:	00000097          	auipc	ra,0x0
    80000a14:	390080e7          	jalr	912(ra) # 80000da0 <acquire>
  for(int i=0;i<(MAX_COW);i++) {
    80000a18:	00010797          	auipc	a5,0x10
    80000a1c:	45078793          	addi	a5,a5,1104 # 80010e68 <page_ref+0x18>
    80000a20:	00230717          	auipc	a4,0x230
    80000a24:	44870713          	addi	a4,a4,1096 # 80230e68 <pid_lock>
    page_ref.count[i]=0;
    80000a28:	0007a023          	sw	zero,0(a5)
  for(int i=0;i<(MAX_COW);i++) {
    80000a2c:	0791                	addi	a5,a5,4
    80000a2e:	fee79de3          	bne	a5,a4,80000a28 <init_page_ref+0x40>
  }
  release(&page_ref.lock);
    80000a32:	00010517          	auipc	a0,0x10
    80000a36:	41e50513          	addi	a0,a0,1054 # 80010e50 <page_ref>
    80000a3a:	00000097          	auipc	ra,0x0
    80000a3e:	41a080e7          	jalr	1050(ra) # 80000e54 <release>
}
    80000a42:	60a2                	ld	ra,8(sp)
    80000a44:	6402                	ld	s0,0(sp)
    80000a46:	0141                	addi	sp,sp,16
    80000a48:	8082                	ret

0000000080000a4a <dec_page_ref>:


void dec_page_ref(void*pa){
    80000a4a:	1101                	addi	sp,sp,-32
    80000a4c:	ec06                	sd	ra,24(sp)
    80000a4e:	e822                	sd	s0,16(sp)
    80000a50:	e426                	sd	s1,8(sp)
    80000a52:	1000                	addi	s0,sp,32
    80000a54:	84aa                	mv	s1,a0
  acquire(&page_ref.lock);
    80000a56:	00010517          	auipc	a0,0x10
    80000a5a:	3fa50513          	addi	a0,a0,1018 # 80010e50 <page_ref>
    80000a5e:	00000097          	auipc	ra,0x0
    80000a62:	342080e7          	jalr	834(ra) # 80000da0 <acquire>
  if(page_ref.count[(uint64)pa>>12] <= 0){
    80000a66:	00c4d793          	srli	a5,s1,0xc
    80000a6a:	00478693          	addi	a3,a5,4
    80000a6e:	068a                	slli	a3,a3,0x2
    80000a70:	00010717          	auipc	a4,0x10
    80000a74:	3e070713          	addi	a4,a4,992 # 80010e50 <page_ref>
    80000a78:	9736                	add	a4,a4,a3
    80000a7a:	4718                	lw	a4,8(a4)
    80000a7c:	02e05463          	blez	a4,80000aa4 <dec_page_ref+0x5a>
    panic("dec_page_ref");
  }
  page_ref.count[(uint64)pa>>12]--;
    80000a80:	00010517          	auipc	a0,0x10
    80000a84:	3d050513          	addi	a0,a0,976 # 80010e50 <page_ref>
    80000a88:	0791                	addi	a5,a5,4
    80000a8a:	078a                	slli	a5,a5,0x2
    80000a8c:	97aa                	add	a5,a5,a0
    80000a8e:	377d                	addiw	a4,a4,-1
    80000a90:	c798                	sw	a4,8(a5)
  release(&page_ref.lock);
    80000a92:	00000097          	auipc	ra,0x0
    80000a96:	3c2080e7          	jalr	962(ra) # 80000e54 <release>
}
    80000a9a:	60e2                	ld	ra,24(sp)
    80000a9c:	6442                	ld	s0,16(sp)
    80000a9e:	64a2                	ld	s1,8(sp)
    80000aa0:	6105                	addi	sp,sp,32
    80000aa2:	8082                	ret
    panic("dec_page_ref");
    80000aa4:	00007517          	auipc	a0,0x7
    80000aa8:	5cc50513          	addi	a0,a0,1484 # 80008070 <digits+0x30>
    80000aac:	00000097          	auipc	ra,0x0
    80000ab0:	a94080e7          	jalr	-1388(ra) # 80000540 <panic>

0000000080000ab4 <inc_page_ref>:

void inc_page_ref(void*pa){
    80000ab4:	1101                	addi	sp,sp,-32
    80000ab6:	ec06                	sd	ra,24(sp)
    80000ab8:	e822                	sd	s0,16(sp)
    80000aba:	e426                	sd	s1,8(sp)
    80000abc:	1000                	addi	s0,sp,32
    80000abe:	84aa                	mv	s1,a0
  acquire(&page_ref.lock);
    80000ac0:	00010517          	auipc	a0,0x10
    80000ac4:	39050513          	addi	a0,a0,912 # 80010e50 <page_ref>
    80000ac8:	00000097          	auipc	ra,0x0
    80000acc:	2d8080e7          	jalr	728(ra) # 80000da0 <acquire>
  if(page_ref.count[(uint64)pa>>12] < 0){
    80000ad0:	00c4d793          	srli	a5,s1,0xc
    80000ad4:	00478693          	addi	a3,a5,4
    80000ad8:	068a                	slli	a3,a3,0x2
    80000ada:	00010717          	auipc	a4,0x10
    80000ade:	37670713          	addi	a4,a4,886 # 80010e50 <page_ref>
    80000ae2:	9736                	add	a4,a4,a3
    80000ae4:	4718                	lw	a4,8(a4)
    80000ae6:	02074463          	bltz	a4,80000b0e <inc_page_ref+0x5a>
    panic("inc_page_ref");
  }
  page_ref.count[(uint64)pa>>12]++;
    80000aea:	00010517          	auipc	a0,0x10
    80000aee:	36650513          	addi	a0,a0,870 # 80010e50 <page_ref>
    80000af2:	0791                	addi	a5,a5,4
    80000af4:	078a                	slli	a5,a5,0x2
    80000af6:	97aa                	add	a5,a5,a0
    80000af8:	2705                	addiw	a4,a4,1
    80000afa:	c798                	sw	a4,8(a5)
  release(&page_ref.lock);
    80000afc:	00000097          	auipc	ra,0x0
    80000b00:	358080e7          	jalr	856(ra) # 80000e54 <release>
}
    80000b04:	60e2                	ld	ra,24(sp)
    80000b06:	6442                	ld	s0,16(sp)
    80000b08:	64a2                	ld	s1,8(sp)
    80000b0a:	6105                	addi	sp,sp,32
    80000b0c:	8082                	ret
    panic("inc_page_ref");
    80000b0e:	00007517          	auipc	a0,0x7
    80000b12:	57250513          	addi	a0,a0,1394 # 80008080 <digits+0x40>
    80000b16:	00000097          	auipc	ra,0x0
    80000b1a:	a2a080e7          	jalr	-1494(ra) # 80000540 <panic>

0000000080000b1e <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000b1e:	1101                	addi	sp,sp,-32
    80000b20:	ec06                	sd	ra,24(sp)
    80000b22:	e822                	sd	s0,16(sp)
    80000b24:	e426                	sd	s1,8(sp)
    80000b26:	e04a                	sd	s2,0(sp)
    80000b28:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000b2a:	03451793          	slli	a5,a0,0x34
    80000b2e:	e7d5                	bnez	a5,80000bda <kfree+0xbc>
    80000b30:	84aa                	mv	s1,a0
    80000b32:	00242797          	auipc	a5,0x242
    80000b36:	74678793          	addi	a5,a5,1862 # 80243278 <end>
    80000b3a:	0af56063          	bltu	a0,a5,80000bda <kfree+0xbc>
    80000b3e:	47c5                	li	a5,17
    80000b40:	07ee                	slli	a5,a5,0x1b
    80000b42:	08f57c63          	bgeu	a0,a5,80000bda <kfree+0xbc>
    panic("kfree");

  acquire(&page_ref.lock);
    80000b46:	00010517          	auipc	a0,0x10
    80000b4a:	30a50513          	addi	a0,a0,778 # 80010e50 <page_ref>
    80000b4e:	00000097          	auipc	ra,0x0
    80000b52:	252080e7          	jalr	594(ra) # 80000da0 <acquire>
  if(page_ref.count[(uint64)pa>>12]<=0){
    80000b56:	00c4d793          	srli	a5,s1,0xc
    80000b5a:	00478693          	addi	a3,a5,4
    80000b5e:	068a                	slli	a3,a3,0x2
    80000b60:	00010717          	auipc	a4,0x10
    80000b64:	2f070713          	addi	a4,a4,752 # 80010e50 <page_ref>
    80000b68:	9736                	add	a4,a4,a3
    80000b6a:	4718                	lw	a4,8(a4)
    80000b6c:	06e05f63          	blez	a4,80000bea <kfree+0xcc>
    panic("kfree error");
  }
  page_ref.count[(uint64)pa>>12]--;
    80000b70:	377d                	addiw	a4,a4,-1
    80000b72:	0007061b          	sext.w	a2,a4
    80000b76:	0791                	addi	a5,a5,4
    80000b78:	078a                	slli	a5,a5,0x2
    80000b7a:	00010697          	auipc	a3,0x10
    80000b7e:	2d668693          	addi	a3,a3,726 # 80010e50 <page_ref>
    80000b82:	97b6                	add	a5,a5,a3
    80000b84:	c798                	sw	a4,8(a5)
  if(page_ref.count[(uint64)pa>>12]>0){
    80000b86:	06c04a63          	bgtz	a2,80000bfa <kfree+0xdc>
    release(&page_ref.lock);
    return;
  }
  release(&page_ref.lock);
    80000b8a:	00010517          	auipc	a0,0x10
    80000b8e:	2c650513          	addi	a0,a0,710 # 80010e50 <page_ref>
    80000b92:	00000097          	auipc	ra,0x0
    80000b96:	2c2080e7          	jalr	706(ra) # 80000e54 <release>

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000b9a:	6605                	lui	a2,0x1
    80000b9c:	4585                	li	a1,1
    80000b9e:	8526                	mv	a0,s1
    80000ba0:	00000097          	auipc	ra,0x0
    80000ba4:	2fc080e7          	jalr	764(ra) # 80000e9c <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000ba8:	00010917          	auipc	s2,0x10
    80000bac:	28890913          	addi	s2,s2,648 # 80010e30 <kmem>
    80000bb0:	854a                	mv	a0,s2
    80000bb2:	00000097          	auipc	ra,0x0
    80000bb6:	1ee080e7          	jalr	494(ra) # 80000da0 <acquire>
  r->next = kmem.freelist;
    80000bba:	01893783          	ld	a5,24(s2)
    80000bbe:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000bc0:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000bc4:	854a                	mv	a0,s2
    80000bc6:	00000097          	auipc	ra,0x0
    80000bca:	28e080e7          	jalr	654(ra) # 80000e54 <release>
}
    80000bce:	60e2                	ld	ra,24(sp)
    80000bd0:	6442                	ld	s0,16(sp)
    80000bd2:	64a2                	ld	s1,8(sp)
    80000bd4:	6902                	ld	s2,0(sp)
    80000bd6:	6105                	addi	sp,sp,32
    80000bd8:	8082                	ret
    panic("kfree");
    80000bda:	00007517          	auipc	a0,0x7
    80000bde:	4b650513          	addi	a0,a0,1206 # 80008090 <digits+0x50>
    80000be2:	00000097          	auipc	ra,0x0
    80000be6:	95e080e7          	jalr	-1698(ra) # 80000540 <panic>
    panic("kfree error");
    80000bea:	00007517          	auipc	a0,0x7
    80000bee:	4ae50513          	addi	a0,a0,1198 # 80008098 <digits+0x58>
    80000bf2:	00000097          	auipc	ra,0x0
    80000bf6:	94e080e7          	jalr	-1714(ra) # 80000540 <panic>
    release(&page_ref.lock);
    80000bfa:	8536                	mv	a0,a3
    80000bfc:	00000097          	auipc	ra,0x0
    80000c00:	258080e7          	jalr	600(ra) # 80000e54 <release>
    return;
    80000c04:	b7e9                	j	80000bce <kfree+0xb0>

0000000080000c06 <freerange>:
{
    80000c06:	7139                	addi	sp,sp,-64
    80000c08:	fc06                	sd	ra,56(sp)
    80000c0a:	f822                	sd	s0,48(sp)
    80000c0c:	f426                	sd	s1,40(sp)
    80000c0e:	f04a                	sd	s2,32(sp)
    80000c10:	ec4e                	sd	s3,24(sp)
    80000c12:	e852                	sd	s4,16(sp)
    80000c14:	e456                	sd	s5,8(sp)
    80000c16:	0080                	addi	s0,sp,64
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000c18:	6785                	lui	a5,0x1
    80000c1a:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000c1e:	00e504b3          	add	s1,a0,a4
    80000c22:	777d                	lui	a4,0xfffff
    80000c24:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE) {
    80000c26:	94be                	add	s1,s1,a5
    80000c28:	0295e463          	bltu	a1,s1,80000c50 <freerange+0x4a>
    80000c2c:	89ae                	mv	s3,a1
    80000c2e:	7afd                	lui	s5,0xfffff
    80000c30:	6a05                	lui	s4,0x1
    80000c32:	01548933          	add	s2,s1,s5
    inc_page_ref(p);
    80000c36:	854a                	mv	a0,s2
    80000c38:	00000097          	auipc	ra,0x0
    80000c3c:	e7c080e7          	jalr	-388(ra) # 80000ab4 <inc_page_ref>
    kfree(p);
    80000c40:	854a                	mv	a0,s2
    80000c42:	00000097          	auipc	ra,0x0
    80000c46:	edc080e7          	jalr	-292(ra) # 80000b1e <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE) {
    80000c4a:	94d2                	add	s1,s1,s4
    80000c4c:	fe99f3e3          	bgeu	s3,s1,80000c32 <freerange+0x2c>
}
    80000c50:	70e2                	ld	ra,56(sp)
    80000c52:	7442                	ld	s0,48(sp)
    80000c54:	74a2                	ld	s1,40(sp)
    80000c56:	7902                	ld	s2,32(sp)
    80000c58:	69e2                	ld	s3,24(sp)
    80000c5a:	6a42                	ld	s4,16(sp)
    80000c5c:	6aa2                	ld	s5,8(sp)
    80000c5e:	6121                	addi	sp,sp,64
    80000c60:	8082                	ret

0000000080000c62 <kinit>:
{
    80000c62:	1141                	addi	sp,sp,-16
    80000c64:	e406                	sd	ra,8(sp)
    80000c66:	e022                	sd	s0,0(sp)
    80000c68:	0800                	addi	s0,sp,16
  init_page_ref();
    80000c6a:	00000097          	auipc	ra,0x0
    80000c6e:	d7e080e7          	jalr	-642(ra) # 800009e8 <init_page_ref>
  initlock(&kmem.lock, "kmem");
    80000c72:	00007597          	auipc	a1,0x7
    80000c76:	43658593          	addi	a1,a1,1078 # 800080a8 <digits+0x68>
    80000c7a:	00010517          	auipc	a0,0x10
    80000c7e:	1b650513          	addi	a0,a0,438 # 80010e30 <kmem>
    80000c82:	00000097          	auipc	ra,0x0
    80000c86:	08e080e7          	jalr	142(ra) # 80000d10 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000c8a:	45c5                	li	a1,17
    80000c8c:	05ee                	slli	a1,a1,0x1b
    80000c8e:	00242517          	auipc	a0,0x242
    80000c92:	5ea50513          	addi	a0,a0,1514 # 80243278 <end>
    80000c96:	00000097          	auipc	ra,0x0
    80000c9a:	f70080e7          	jalr	-144(ra) # 80000c06 <freerange>
}
    80000c9e:	60a2                	ld	ra,8(sp)
    80000ca0:	6402                	ld	s0,0(sp)
    80000ca2:	0141                	addi	sp,sp,16
    80000ca4:	8082                	ret

0000000080000ca6 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ca6:	1101                	addi	sp,sp,-32
    80000ca8:	ec06                	sd	ra,24(sp)
    80000caa:	e822                	sd	s0,16(sp)
    80000cac:	e426                	sd	s1,8(sp)
    80000cae:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000cb0:	00010497          	auipc	s1,0x10
    80000cb4:	18048493          	addi	s1,s1,384 # 80010e30 <kmem>
    80000cb8:	8526                	mv	a0,s1
    80000cba:	00000097          	auipc	ra,0x0
    80000cbe:	0e6080e7          	jalr	230(ra) # 80000da0 <acquire>
  r = kmem.freelist;
    80000cc2:	6c84                	ld	s1,24(s1)
  if(r)
    80000cc4:	cc8d                	beqz	s1,80000cfe <kalloc+0x58>
    kmem.freelist = r->next;
    80000cc6:	609c                	ld	a5,0(s1)
    80000cc8:	00010517          	auipc	a0,0x10
    80000ccc:	16850513          	addi	a0,a0,360 # 80010e30 <kmem>
    80000cd0:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000cd2:	00000097          	auipc	ra,0x0
    80000cd6:	182080e7          	jalr	386(ra) # 80000e54 <release>

  if(r) {
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000cda:	6605                	lui	a2,0x1
    80000cdc:	4595                	li	a1,5
    80000cde:	8526                	mv	a0,s1
    80000ce0:	00000097          	auipc	ra,0x0
    80000ce4:	1bc080e7          	jalr	444(ra) # 80000e9c <memset>
    inc_page_ref((void*)r);
    80000ce8:	8526                	mv	a0,s1
    80000cea:	00000097          	auipc	ra,0x0
    80000cee:	dca080e7          	jalr	-566(ra) # 80000ab4 <inc_page_ref>
  }
  return (void*)r;
}
    80000cf2:	8526                	mv	a0,s1
    80000cf4:	60e2                	ld	ra,24(sp)
    80000cf6:	6442                	ld	s0,16(sp)
    80000cf8:	64a2                	ld	s1,8(sp)
    80000cfa:	6105                	addi	sp,sp,32
    80000cfc:	8082                	ret
  release(&kmem.lock);
    80000cfe:	00010517          	auipc	a0,0x10
    80000d02:	13250513          	addi	a0,a0,306 # 80010e30 <kmem>
    80000d06:	00000097          	auipc	ra,0x0
    80000d0a:	14e080e7          	jalr	334(ra) # 80000e54 <release>
  if(r) {
    80000d0e:	b7d5                	j	80000cf2 <kalloc+0x4c>

0000000080000d10 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000d10:	1141                	addi	sp,sp,-16
    80000d12:	e422                	sd	s0,8(sp)
    80000d14:	0800                	addi	s0,sp,16
  lk->name = name;
    80000d16:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000d18:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000d1c:	00053823          	sd	zero,16(a0)
}
    80000d20:	6422                	ld	s0,8(sp)
    80000d22:	0141                	addi	sp,sp,16
    80000d24:	8082                	ret

0000000080000d26 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000d26:	411c                	lw	a5,0(a0)
    80000d28:	e399                	bnez	a5,80000d2e <holding+0x8>
    80000d2a:	4501                	li	a0,0
  return r;
}
    80000d2c:	8082                	ret
{
    80000d2e:	1101                	addi	sp,sp,-32
    80000d30:	ec06                	sd	ra,24(sp)
    80000d32:	e822                	sd	s0,16(sp)
    80000d34:	e426                	sd	s1,8(sp)
    80000d36:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000d38:	6904                	ld	s1,16(a0)
    80000d3a:	00001097          	auipc	ra,0x1
    80000d3e:	e5e080e7          	jalr	-418(ra) # 80001b98 <mycpu>
    80000d42:	40a48533          	sub	a0,s1,a0
    80000d46:	00153513          	seqz	a0,a0
}
    80000d4a:	60e2                	ld	ra,24(sp)
    80000d4c:	6442                	ld	s0,16(sp)
    80000d4e:	64a2                	ld	s1,8(sp)
    80000d50:	6105                	addi	sp,sp,32
    80000d52:	8082                	ret

0000000080000d54 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000d54:	1101                	addi	sp,sp,-32
    80000d56:	ec06                	sd	ra,24(sp)
    80000d58:	e822                	sd	s0,16(sp)
    80000d5a:	e426                	sd	s1,8(sp)
    80000d5c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d5e:	100024f3          	csrr	s1,sstatus
    80000d62:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000d66:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000d68:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000d6c:	00001097          	auipc	ra,0x1
    80000d70:	e2c080e7          	jalr	-468(ra) # 80001b98 <mycpu>
    80000d74:	5d3c                	lw	a5,120(a0)
    80000d76:	cf89                	beqz	a5,80000d90 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000d78:	00001097          	auipc	ra,0x1
    80000d7c:	e20080e7          	jalr	-480(ra) # 80001b98 <mycpu>
    80000d80:	5d3c                	lw	a5,120(a0)
    80000d82:	2785                	addiw	a5,a5,1
    80000d84:	dd3c                	sw	a5,120(a0)
}
    80000d86:	60e2                	ld	ra,24(sp)
    80000d88:	6442                	ld	s0,16(sp)
    80000d8a:	64a2                	ld	s1,8(sp)
    80000d8c:	6105                	addi	sp,sp,32
    80000d8e:	8082                	ret
    mycpu()->intena = old;
    80000d90:	00001097          	auipc	ra,0x1
    80000d94:	e08080e7          	jalr	-504(ra) # 80001b98 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000d98:	8085                	srli	s1,s1,0x1
    80000d9a:	8885                	andi	s1,s1,1
    80000d9c:	dd64                	sw	s1,124(a0)
    80000d9e:	bfe9                	j	80000d78 <push_off+0x24>

0000000080000da0 <acquire>:
{
    80000da0:	1101                	addi	sp,sp,-32
    80000da2:	ec06                	sd	ra,24(sp)
    80000da4:	e822                	sd	s0,16(sp)
    80000da6:	e426                	sd	s1,8(sp)
    80000da8:	1000                	addi	s0,sp,32
    80000daa:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000dac:	00000097          	auipc	ra,0x0
    80000db0:	fa8080e7          	jalr	-88(ra) # 80000d54 <push_off>
  if(holding(lk))
    80000db4:	8526                	mv	a0,s1
    80000db6:	00000097          	auipc	ra,0x0
    80000dba:	f70080e7          	jalr	-144(ra) # 80000d26 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000dbe:	4705                	li	a4,1
  if(holding(lk))
    80000dc0:	e115                	bnez	a0,80000de4 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000dc2:	87ba                	mv	a5,a4
    80000dc4:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000dc8:	2781                	sext.w	a5,a5
    80000dca:	ffe5                	bnez	a5,80000dc2 <acquire+0x22>
  __sync_synchronize();
    80000dcc:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000dd0:	00001097          	auipc	ra,0x1
    80000dd4:	dc8080e7          	jalr	-568(ra) # 80001b98 <mycpu>
    80000dd8:	e888                	sd	a0,16(s1)
}
    80000dda:	60e2                	ld	ra,24(sp)
    80000ddc:	6442                	ld	s0,16(sp)
    80000dde:	64a2                	ld	s1,8(sp)
    80000de0:	6105                	addi	sp,sp,32
    80000de2:	8082                	ret
    panic("acquire");
    80000de4:	00007517          	auipc	a0,0x7
    80000de8:	2cc50513          	addi	a0,a0,716 # 800080b0 <digits+0x70>
    80000dec:	fffff097          	auipc	ra,0xfffff
    80000df0:	754080e7          	jalr	1876(ra) # 80000540 <panic>

0000000080000df4 <pop_off>:

void
pop_off(void)
{
    80000df4:	1141                	addi	sp,sp,-16
    80000df6:	e406                	sd	ra,8(sp)
    80000df8:	e022                	sd	s0,0(sp)
    80000dfa:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000dfc:	00001097          	auipc	ra,0x1
    80000e00:	d9c080e7          	jalr	-612(ra) # 80001b98 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000e04:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000e08:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000e0a:	e78d                	bnez	a5,80000e34 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000e0c:	5d3c                	lw	a5,120(a0)
    80000e0e:	02f05b63          	blez	a5,80000e44 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000e12:	37fd                	addiw	a5,a5,-1
    80000e14:	0007871b          	sext.w	a4,a5
    80000e18:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000e1a:	eb09                	bnez	a4,80000e2c <pop_off+0x38>
    80000e1c:	5d7c                	lw	a5,124(a0)
    80000e1e:	c799                	beqz	a5,80000e2c <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000e20:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000e24:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000e28:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000e2c:	60a2                	ld	ra,8(sp)
    80000e2e:	6402                	ld	s0,0(sp)
    80000e30:	0141                	addi	sp,sp,16
    80000e32:	8082                	ret
    panic("pop_off - interruptible");
    80000e34:	00007517          	auipc	a0,0x7
    80000e38:	28450513          	addi	a0,a0,644 # 800080b8 <digits+0x78>
    80000e3c:	fffff097          	auipc	ra,0xfffff
    80000e40:	704080e7          	jalr	1796(ra) # 80000540 <panic>
    panic("pop_off");
    80000e44:	00007517          	auipc	a0,0x7
    80000e48:	28c50513          	addi	a0,a0,652 # 800080d0 <digits+0x90>
    80000e4c:	fffff097          	auipc	ra,0xfffff
    80000e50:	6f4080e7          	jalr	1780(ra) # 80000540 <panic>

0000000080000e54 <release>:
{
    80000e54:	1101                	addi	sp,sp,-32
    80000e56:	ec06                	sd	ra,24(sp)
    80000e58:	e822                	sd	s0,16(sp)
    80000e5a:	e426                	sd	s1,8(sp)
    80000e5c:	1000                	addi	s0,sp,32
    80000e5e:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000e60:	00000097          	auipc	ra,0x0
    80000e64:	ec6080e7          	jalr	-314(ra) # 80000d26 <holding>
    80000e68:	c115                	beqz	a0,80000e8c <release+0x38>
  lk->cpu = 0;
    80000e6a:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000e6e:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000e72:	0f50000f          	fence	iorw,ow
    80000e76:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000e7a:	00000097          	auipc	ra,0x0
    80000e7e:	f7a080e7          	jalr	-134(ra) # 80000df4 <pop_off>
}
    80000e82:	60e2                	ld	ra,24(sp)
    80000e84:	6442                	ld	s0,16(sp)
    80000e86:	64a2                	ld	s1,8(sp)
    80000e88:	6105                	addi	sp,sp,32
    80000e8a:	8082                	ret
    panic("release");
    80000e8c:	00007517          	auipc	a0,0x7
    80000e90:	24c50513          	addi	a0,a0,588 # 800080d8 <digits+0x98>
    80000e94:	fffff097          	auipc	ra,0xfffff
    80000e98:	6ac080e7          	jalr	1708(ra) # 80000540 <panic>

0000000080000e9c <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000e9c:	1141                	addi	sp,sp,-16
    80000e9e:	e422                	sd	s0,8(sp)
    80000ea0:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000ea2:	ca19                	beqz	a2,80000eb8 <memset+0x1c>
    80000ea4:	87aa                	mv	a5,a0
    80000ea6:	1602                	slli	a2,a2,0x20
    80000ea8:	9201                	srli	a2,a2,0x20
    80000eaa:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000eae:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000eb2:	0785                	addi	a5,a5,1
    80000eb4:	fee79de3          	bne	a5,a4,80000eae <memset+0x12>
  }
  return dst;
}
    80000eb8:	6422                	ld	s0,8(sp)
    80000eba:	0141                	addi	sp,sp,16
    80000ebc:	8082                	ret

0000000080000ebe <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000ebe:	1141                	addi	sp,sp,-16
    80000ec0:	e422                	sd	s0,8(sp)
    80000ec2:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000ec4:	ca05                	beqz	a2,80000ef4 <memcmp+0x36>
    80000ec6:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000eca:	1682                	slli	a3,a3,0x20
    80000ecc:	9281                	srli	a3,a3,0x20
    80000ece:	0685                	addi	a3,a3,1
    80000ed0:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000ed2:	00054783          	lbu	a5,0(a0)
    80000ed6:	0005c703          	lbu	a4,0(a1)
    80000eda:	00e79863          	bne	a5,a4,80000eea <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000ede:	0505                	addi	a0,a0,1
    80000ee0:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000ee2:	fed518e3          	bne	a0,a3,80000ed2 <memcmp+0x14>
  }

  return 0;
    80000ee6:	4501                	li	a0,0
    80000ee8:	a019                	j	80000eee <memcmp+0x30>
      return *s1 - *s2;
    80000eea:	40e7853b          	subw	a0,a5,a4
}
    80000eee:	6422                	ld	s0,8(sp)
    80000ef0:	0141                	addi	sp,sp,16
    80000ef2:	8082                	ret
  return 0;
    80000ef4:	4501                	li	a0,0
    80000ef6:	bfe5                	j	80000eee <memcmp+0x30>

0000000080000ef8 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000ef8:	1141                	addi	sp,sp,-16
    80000efa:	e422                	sd	s0,8(sp)
    80000efc:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000efe:	c205                	beqz	a2,80000f1e <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000f00:	02a5e263          	bltu	a1,a0,80000f24 <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000f04:	1602                	slli	a2,a2,0x20
    80000f06:	9201                	srli	a2,a2,0x20
    80000f08:	00c587b3          	add	a5,a1,a2
{
    80000f0c:	872a                	mv	a4,a0
      *d++ = *s++;
    80000f0e:	0585                	addi	a1,a1,1
    80000f10:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7fdbbd89>
    80000f12:	fff5c683          	lbu	a3,-1(a1)
    80000f16:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000f1a:	fef59ae3          	bne	a1,a5,80000f0e <memmove+0x16>

  return dst;
}
    80000f1e:	6422                	ld	s0,8(sp)
    80000f20:	0141                	addi	sp,sp,16
    80000f22:	8082                	ret
  if(s < d && s + n > d){
    80000f24:	02061693          	slli	a3,a2,0x20
    80000f28:	9281                	srli	a3,a3,0x20
    80000f2a:	00d58733          	add	a4,a1,a3
    80000f2e:	fce57be3          	bgeu	a0,a4,80000f04 <memmove+0xc>
    d += n;
    80000f32:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000f34:	fff6079b          	addiw	a5,a2,-1
    80000f38:	1782                	slli	a5,a5,0x20
    80000f3a:	9381                	srli	a5,a5,0x20
    80000f3c:	fff7c793          	not	a5,a5
    80000f40:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000f42:	177d                	addi	a4,a4,-1
    80000f44:	16fd                	addi	a3,a3,-1
    80000f46:	00074603          	lbu	a2,0(a4)
    80000f4a:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000f4e:	fee79ae3          	bne	a5,a4,80000f42 <memmove+0x4a>
    80000f52:	b7f1                	j	80000f1e <memmove+0x26>

0000000080000f54 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000f54:	1141                	addi	sp,sp,-16
    80000f56:	e406                	sd	ra,8(sp)
    80000f58:	e022                	sd	s0,0(sp)
    80000f5a:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000f5c:	00000097          	auipc	ra,0x0
    80000f60:	f9c080e7          	jalr	-100(ra) # 80000ef8 <memmove>
}
    80000f64:	60a2                	ld	ra,8(sp)
    80000f66:	6402                	ld	s0,0(sp)
    80000f68:	0141                	addi	sp,sp,16
    80000f6a:	8082                	ret

0000000080000f6c <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000f6c:	1141                	addi	sp,sp,-16
    80000f6e:	e422                	sd	s0,8(sp)
    80000f70:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000f72:	ce11                	beqz	a2,80000f8e <strncmp+0x22>
    80000f74:	00054783          	lbu	a5,0(a0)
    80000f78:	cf89                	beqz	a5,80000f92 <strncmp+0x26>
    80000f7a:	0005c703          	lbu	a4,0(a1)
    80000f7e:	00f71a63          	bne	a4,a5,80000f92 <strncmp+0x26>
    n--, p++, q++;
    80000f82:	367d                	addiw	a2,a2,-1
    80000f84:	0505                	addi	a0,a0,1
    80000f86:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000f88:	f675                	bnez	a2,80000f74 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000f8a:	4501                	li	a0,0
    80000f8c:	a809                	j	80000f9e <strncmp+0x32>
    80000f8e:	4501                	li	a0,0
    80000f90:	a039                	j	80000f9e <strncmp+0x32>
  if(n == 0)
    80000f92:	ca09                	beqz	a2,80000fa4 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000f94:	00054503          	lbu	a0,0(a0)
    80000f98:	0005c783          	lbu	a5,0(a1)
    80000f9c:	9d1d                	subw	a0,a0,a5
}
    80000f9e:	6422                	ld	s0,8(sp)
    80000fa0:	0141                	addi	sp,sp,16
    80000fa2:	8082                	ret
    return 0;
    80000fa4:	4501                	li	a0,0
    80000fa6:	bfe5                	j	80000f9e <strncmp+0x32>

0000000080000fa8 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000fa8:	1141                	addi	sp,sp,-16
    80000faa:	e422                	sd	s0,8(sp)
    80000fac:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000fae:	872a                	mv	a4,a0
    80000fb0:	8832                	mv	a6,a2
    80000fb2:	367d                	addiw	a2,a2,-1
    80000fb4:	01005963          	blez	a6,80000fc6 <strncpy+0x1e>
    80000fb8:	0705                	addi	a4,a4,1
    80000fba:	0005c783          	lbu	a5,0(a1)
    80000fbe:	fef70fa3          	sb	a5,-1(a4)
    80000fc2:	0585                	addi	a1,a1,1
    80000fc4:	f7f5                	bnez	a5,80000fb0 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000fc6:	86ba                	mv	a3,a4
    80000fc8:	00c05c63          	blez	a2,80000fe0 <strncpy+0x38>
    *s++ = 0;
    80000fcc:	0685                	addi	a3,a3,1
    80000fce:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000fd2:	40d707bb          	subw	a5,a4,a3
    80000fd6:	37fd                	addiw	a5,a5,-1
    80000fd8:	010787bb          	addw	a5,a5,a6
    80000fdc:	fef048e3          	bgtz	a5,80000fcc <strncpy+0x24>
  return os;
}
    80000fe0:	6422                	ld	s0,8(sp)
    80000fe2:	0141                	addi	sp,sp,16
    80000fe4:	8082                	ret

0000000080000fe6 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000fe6:	1141                	addi	sp,sp,-16
    80000fe8:	e422                	sd	s0,8(sp)
    80000fea:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000fec:	02c05363          	blez	a2,80001012 <safestrcpy+0x2c>
    80000ff0:	fff6069b          	addiw	a3,a2,-1
    80000ff4:	1682                	slli	a3,a3,0x20
    80000ff6:	9281                	srli	a3,a3,0x20
    80000ff8:	96ae                	add	a3,a3,a1
    80000ffa:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000ffc:	00d58963          	beq	a1,a3,8000100e <safestrcpy+0x28>
    80001000:	0585                	addi	a1,a1,1
    80001002:	0785                	addi	a5,a5,1
    80001004:	fff5c703          	lbu	a4,-1(a1)
    80001008:	fee78fa3          	sb	a4,-1(a5)
    8000100c:	fb65                	bnez	a4,80000ffc <safestrcpy+0x16>
    ;
  *s = 0;
    8000100e:	00078023          	sb	zero,0(a5)
  return os;
}
    80001012:	6422                	ld	s0,8(sp)
    80001014:	0141                	addi	sp,sp,16
    80001016:	8082                	ret

0000000080001018 <strlen>:

int
strlen(const char *s)
{
    80001018:	1141                	addi	sp,sp,-16
    8000101a:	e422                	sd	s0,8(sp)
    8000101c:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    8000101e:	00054783          	lbu	a5,0(a0)
    80001022:	cf91                	beqz	a5,8000103e <strlen+0x26>
    80001024:	0505                	addi	a0,a0,1
    80001026:	87aa                	mv	a5,a0
    80001028:	4685                	li	a3,1
    8000102a:	9e89                	subw	a3,a3,a0
    8000102c:	00f6853b          	addw	a0,a3,a5
    80001030:	0785                	addi	a5,a5,1
    80001032:	fff7c703          	lbu	a4,-1(a5)
    80001036:	fb7d                	bnez	a4,8000102c <strlen+0x14>
    ;
  return n;
}
    80001038:	6422                	ld	s0,8(sp)
    8000103a:	0141                	addi	sp,sp,16
    8000103c:	8082                	ret
  for(n = 0; s[n]; n++)
    8000103e:	4501                	li	a0,0
    80001040:	bfe5                	j	80001038 <strlen+0x20>

0000000080001042 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80001042:	1141                	addi	sp,sp,-16
    80001044:	e406                	sd	ra,8(sp)
    80001046:	e022                	sd	s0,0(sp)
    80001048:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    8000104a:	00001097          	auipc	ra,0x1
    8000104e:	b3e080e7          	jalr	-1218(ra) # 80001b88 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80001052:	00008717          	auipc	a4,0x8
    80001056:	b7670713          	addi	a4,a4,-1162 # 80008bc8 <started>
  if(cpuid() == 0){
    8000105a:	c139                	beqz	a0,800010a0 <main+0x5e>
    while(started == 0)
    8000105c:	431c                	lw	a5,0(a4)
    8000105e:	2781                	sext.w	a5,a5
    80001060:	dff5                	beqz	a5,8000105c <main+0x1a>
      ;
    __sync_synchronize();
    80001062:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80001066:	00001097          	auipc	ra,0x1
    8000106a:	b22080e7          	jalr	-1246(ra) # 80001b88 <cpuid>
    8000106e:	85aa                	mv	a1,a0
    80001070:	00007517          	auipc	a0,0x7
    80001074:	08850513          	addi	a0,a0,136 # 800080f8 <digits+0xb8>
    80001078:	fffff097          	auipc	ra,0xfffff
    8000107c:	512080e7          	jalr	1298(ra) # 8000058a <printf>
    kvminithart();    // turn on paging
    80001080:	00000097          	auipc	ra,0x0
    80001084:	0d8080e7          	jalr	216(ra) # 80001158 <kvminithart>
    trapinithart();   // install kernel trap vector
    80001088:	00002097          	auipc	ra,0x2
    8000108c:	c68080e7          	jalr	-920(ra) # 80002cf0 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80001090:	00005097          	auipc	ra,0x5
    80001094:	570080e7          	jalr	1392(ra) # 80006600 <plicinithart>
  }
  scheduler();        
    80001098:	00001097          	auipc	ra,0x1
    8000109c:	0d6080e7          	jalr	214(ra) # 8000216e <scheduler>
    consoleinit();
    800010a0:	fffff097          	auipc	ra,0xfffff
    800010a4:	3b0080e7          	jalr	944(ra) # 80000450 <consoleinit>
    printfinit();
    800010a8:	fffff097          	auipc	ra,0xfffff
    800010ac:	6c2080e7          	jalr	1730(ra) # 8000076a <printfinit>
    printf("\n");
    800010b0:	00007517          	auipc	a0,0x7
    800010b4:	05850513          	addi	a0,a0,88 # 80008108 <digits+0xc8>
    800010b8:	fffff097          	auipc	ra,0xfffff
    800010bc:	4d2080e7          	jalr	1234(ra) # 8000058a <printf>
    printf("xv6 kernel is booting\n");
    800010c0:	00007517          	auipc	a0,0x7
    800010c4:	02050513          	addi	a0,a0,32 # 800080e0 <digits+0xa0>
    800010c8:	fffff097          	auipc	ra,0xfffff
    800010cc:	4c2080e7          	jalr	1218(ra) # 8000058a <printf>
    printf("\n");
    800010d0:	00007517          	auipc	a0,0x7
    800010d4:	03850513          	addi	a0,a0,56 # 80008108 <digits+0xc8>
    800010d8:	fffff097          	auipc	ra,0xfffff
    800010dc:	4b2080e7          	jalr	1202(ra) # 8000058a <printf>
    kinit();         // physical page allocator
    800010e0:	00000097          	auipc	ra,0x0
    800010e4:	b82080e7          	jalr	-1150(ra) # 80000c62 <kinit>
    kvminit();       // create kernel page table
    800010e8:	00000097          	auipc	ra,0x0
    800010ec:	326080e7          	jalr	806(ra) # 8000140e <kvminit>
    kvminithart();   // turn on paging
    800010f0:	00000097          	auipc	ra,0x0
    800010f4:	068080e7          	jalr	104(ra) # 80001158 <kvminithart>
    procinit();      // process table
    800010f8:	00001097          	auipc	ra,0x1
    800010fc:	9dc080e7          	jalr	-1572(ra) # 80001ad4 <procinit>
    trapinit();      // trap vectors
    80001100:	00002097          	auipc	ra,0x2
    80001104:	bc8080e7          	jalr	-1080(ra) # 80002cc8 <trapinit>
    trapinithart();  // install kernel trap vector
    80001108:	00002097          	auipc	ra,0x2
    8000110c:	be8080e7          	jalr	-1048(ra) # 80002cf0 <trapinithart>
    plicinit();      // set up interrupt controller
    80001110:	00005097          	auipc	ra,0x5
    80001114:	4da080e7          	jalr	1242(ra) # 800065ea <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80001118:	00005097          	auipc	ra,0x5
    8000111c:	4e8080e7          	jalr	1256(ra) # 80006600 <plicinithart>
    binit();         // buffer cache
    80001120:	00002097          	auipc	ra,0x2
    80001124:	688080e7          	jalr	1672(ra) # 800037a8 <binit>
    iinit();         // inode table
    80001128:	00003097          	auipc	ra,0x3
    8000112c:	d28080e7          	jalr	-728(ra) # 80003e50 <iinit>
    fileinit();      // file table
    80001130:	00004097          	auipc	ra,0x4
    80001134:	cce080e7          	jalr	-818(ra) # 80004dfe <fileinit>
    virtio_disk_init(); // emulated hard disk
    80001138:	00005097          	auipc	ra,0x5
    8000113c:	5d0080e7          	jalr	1488(ra) # 80006708 <virtio_disk_init>
    userinit();      // first user process
    80001140:	00001097          	auipc	ra,0x1
    80001144:	da2080e7          	jalr	-606(ra) # 80001ee2 <userinit>
    __sync_synchronize();
    80001148:	0ff0000f          	fence
    started = 1;
    8000114c:	4785                	li	a5,1
    8000114e:	00008717          	auipc	a4,0x8
    80001152:	a6f72d23          	sw	a5,-1414(a4) # 80008bc8 <started>
    80001156:	b789                	j	80001098 <main+0x56>

0000000080001158 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80001158:	1141                	addi	sp,sp,-16
    8000115a:	e422                	sd	s0,8(sp)
    8000115c:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    8000115e:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80001162:	00008797          	auipc	a5,0x8
    80001166:	a6e7b783          	ld	a5,-1426(a5) # 80008bd0 <kernel_pagetable>
    8000116a:	83b1                	srli	a5,a5,0xc
    8000116c:	577d                	li	a4,-1
    8000116e:	177e                	slli	a4,a4,0x3f
    80001170:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80001172:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80001176:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    8000117a:	6422                	ld	s0,8(sp)
    8000117c:	0141                	addi	sp,sp,16
    8000117e:	8082                	ret

0000000080001180 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80001180:	7139                	addi	sp,sp,-64
    80001182:	fc06                	sd	ra,56(sp)
    80001184:	f822                	sd	s0,48(sp)
    80001186:	f426                	sd	s1,40(sp)
    80001188:	f04a                	sd	s2,32(sp)
    8000118a:	ec4e                	sd	s3,24(sp)
    8000118c:	e852                	sd	s4,16(sp)
    8000118e:	e456                	sd	s5,8(sp)
    80001190:	e05a                	sd	s6,0(sp)
    80001192:	0080                	addi	s0,sp,64
    80001194:	84aa                	mv	s1,a0
    80001196:	89ae                	mv	s3,a1
    80001198:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    8000119a:	57fd                	li	a5,-1
    8000119c:	83e9                	srli	a5,a5,0x1a
    8000119e:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    800011a0:	4b31                	li	s6,12
  if(va >= MAXVA)
    800011a2:	04b7f263          	bgeu	a5,a1,800011e6 <walk+0x66>
    panic("walk");
    800011a6:	00007517          	auipc	a0,0x7
    800011aa:	f6a50513          	addi	a0,a0,-150 # 80008110 <digits+0xd0>
    800011ae:	fffff097          	auipc	ra,0xfffff
    800011b2:	392080e7          	jalr	914(ra) # 80000540 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    800011b6:	060a8663          	beqz	s5,80001222 <walk+0xa2>
    800011ba:	00000097          	auipc	ra,0x0
    800011be:	aec080e7          	jalr	-1300(ra) # 80000ca6 <kalloc>
    800011c2:	84aa                	mv	s1,a0
    800011c4:	c529                	beqz	a0,8000120e <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    800011c6:	6605                	lui	a2,0x1
    800011c8:	4581                	li	a1,0
    800011ca:	00000097          	auipc	ra,0x0
    800011ce:	cd2080e7          	jalr	-814(ra) # 80000e9c <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    800011d2:	00c4d793          	srli	a5,s1,0xc
    800011d6:	07aa                	slli	a5,a5,0xa
    800011d8:	0017e793          	ori	a5,a5,1
    800011dc:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    800011e0:	3a5d                	addiw	s4,s4,-9 # ff7 <_entry-0x7ffff009>
    800011e2:	036a0063          	beq	s4,s6,80001202 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    800011e6:	0149d933          	srl	s2,s3,s4
    800011ea:	1ff97913          	andi	s2,s2,511
    800011ee:	090e                	slli	s2,s2,0x3
    800011f0:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    800011f2:	00093483          	ld	s1,0(s2)
    800011f6:	0014f793          	andi	a5,s1,1
    800011fa:	dfd5                	beqz	a5,800011b6 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    800011fc:	80a9                	srli	s1,s1,0xa
    800011fe:	04b2                	slli	s1,s1,0xc
    80001200:	b7c5                	j	800011e0 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001202:	00c9d513          	srli	a0,s3,0xc
    80001206:	1ff57513          	andi	a0,a0,511
    8000120a:	050e                	slli	a0,a0,0x3
    8000120c:	9526                	add	a0,a0,s1
}
    8000120e:	70e2                	ld	ra,56(sp)
    80001210:	7442                	ld	s0,48(sp)
    80001212:	74a2                	ld	s1,40(sp)
    80001214:	7902                	ld	s2,32(sp)
    80001216:	69e2                	ld	s3,24(sp)
    80001218:	6a42                	ld	s4,16(sp)
    8000121a:	6aa2                	ld	s5,8(sp)
    8000121c:	6b02                	ld	s6,0(sp)
    8000121e:	6121                	addi	sp,sp,64
    80001220:	8082                	ret
        return 0;
    80001222:	4501                	li	a0,0
    80001224:	b7ed                	j	8000120e <walk+0x8e>

0000000080001226 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001226:	57fd                	li	a5,-1
    80001228:	83e9                	srli	a5,a5,0x1a
    8000122a:	00b7f463          	bgeu	a5,a1,80001232 <walkaddr+0xc>
    return 0;
    8000122e:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001230:	8082                	ret
{
    80001232:	1141                	addi	sp,sp,-16
    80001234:	e406                	sd	ra,8(sp)
    80001236:	e022                	sd	s0,0(sp)
    80001238:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    8000123a:	4601                	li	a2,0
    8000123c:	00000097          	auipc	ra,0x0
    80001240:	f44080e7          	jalr	-188(ra) # 80001180 <walk>
  if(pte == 0)
    80001244:	c105                	beqz	a0,80001264 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001246:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001248:	0117f693          	andi	a3,a5,17
    8000124c:	4745                	li	a4,17
    return 0;
    8000124e:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001250:	00e68663          	beq	a3,a4,8000125c <walkaddr+0x36>
}
    80001254:	60a2                	ld	ra,8(sp)
    80001256:	6402                	ld	s0,0(sp)
    80001258:	0141                	addi	sp,sp,16
    8000125a:	8082                	ret
  pa = PTE2PA(*pte);
    8000125c:	83a9                	srli	a5,a5,0xa
    8000125e:	00c79513          	slli	a0,a5,0xc
  return pa;
    80001262:	bfcd                	j	80001254 <walkaddr+0x2e>
    return 0;
    80001264:	4501                	li	a0,0
    80001266:	b7fd                	j	80001254 <walkaddr+0x2e>

0000000080001268 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001268:	715d                	addi	sp,sp,-80
    8000126a:	e486                	sd	ra,72(sp)
    8000126c:	e0a2                	sd	s0,64(sp)
    8000126e:	fc26                	sd	s1,56(sp)
    80001270:	f84a                	sd	s2,48(sp)
    80001272:	f44e                	sd	s3,40(sp)
    80001274:	f052                	sd	s4,32(sp)
    80001276:	ec56                	sd	s5,24(sp)
    80001278:	e85a                	sd	s6,16(sp)
    8000127a:	e45e                	sd	s7,8(sp)
    8000127c:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    8000127e:	c639                	beqz	a2,800012cc <mappages+0x64>
    80001280:	8aaa                	mv	s5,a0
    80001282:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    80001284:	777d                	lui	a4,0xfffff
    80001286:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    8000128a:	fff58993          	addi	s3,a1,-1
    8000128e:	99b2                	add	s3,s3,a2
    80001290:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    80001294:	893e                	mv	s2,a5
    80001296:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    8000129a:	6b85                	lui	s7,0x1
    8000129c:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800012a0:	4605                	li	a2,1
    800012a2:	85ca                	mv	a1,s2
    800012a4:	8556                	mv	a0,s5
    800012a6:	00000097          	auipc	ra,0x0
    800012aa:	eda080e7          	jalr	-294(ra) # 80001180 <walk>
    800012ae:	cd1d                	beqz	a0,800012ec <mappages+0x84>
    if(*pte & PTE_V)
    800012b0:	611c                	ld	a5,0(a0)
    800012b2:	8b85                	andi	a5,a5,1
    800012b4:	e785                	bnez	a5,800012dc <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800012b6:	80b1                	srli	s1,s1,0xc
    800012b8:	04aa                	slli	s1,s1,0xa
    800012ba:	0164e4b3          	or	s1,s1,s6
    800012be:	0014e493          	ori	s1,s1,1
    800012c2:	e104                	sd	s1,0(a0)
    if(a == last)
    800012c4:	05390063          	beq	s2,s3,80001304 <mappages+0x9c>
    a += PGSIZE;
    800012c8:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800012ca:	bfc9                	j	8000129c <mappages+0x34>
    panic("mappages: size");
    800012cc:	00007517          	auipc	a0,0x7
    800012d0:	e4c50513          	addi	a0,a0,-436 # 80008118 <digits+0xd8>
    800012d4:	fffff097          	auipc	ra,0xfffff
    800012d8:	26c080e7          	jalr	620(ra) # 80000540 <panic>
      panic("mappages: remap");
    800012dc:	00007517          	auipc	a0,0x7
    800012e0:	e4c50513          	addi	a0,a0,-436 # 80008128 <digits+0xe8>
    800012e4:	fffff097          	auipc	ra,0xfffff
    800012e8:	25c080e7          	jalr	604(ra) # 80000540 <panic>
      return -1;
    800012ec:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    800012ee:	60a6                	ld	ra,72(sp)
    800012f0:	6406                	ld	s0,64(sp)
    800012f2:	74e2                	ld	s1,56(sp)
    800012f4:	7942                	ld	s2,48(sp)
    800012f6:	79a2                	ld	s3,40(sp)
    800012f8:	7a02                	ld	s4,32(sp)
    800012fa:	6ae2                	ld	s5,24(sp)
    800012fc:	6b42                	ld	s6,16(sp)
    800012fe:	6ba2                	ld	s7,8(sp)
    80001300:	6161                	addi	sp,sp,80
    80001302:	8082                	ret
  return 0;
    80001304:	4501                	li	a0,0
    80001306:	b7e5                	j	800012ee <mappages+0x86>

0000000080001308 <kvmmap>:
{
    80001308:	1141                	addi	sp,sp,-16
    8000130a:	e406                	sd	ra,8(sp)
    8000130c:	e022                	sd	s0,0(sp)
    8000130e:	0800                	addi	s0,sp,16
    80001310:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001312:	86b2                	mv	a3,a2
    80001314:	863e                	mv	a2,a5
    80001316:	00000097          	auipc	ra,0x0
    8000131a:	f52080e7          	jalr	-174(ra) # 80001268 <mappages>
    8000131e:	e509                	bnez	a0,80001328 <kvmmap+0x20>
}
    80001320:	60a2                	ld	ra,8(sp)
    80001322:	6402                	ld	s0,0(sp)
    80001324:	0141                	addi	sp,sp,16
    80001326:	8082                	ret
    panic("kvmmap");
    80001328:	00007517          	auipc	a0,0x7
    8000132c:	e1050513          	addi	a0,a0,-496 # 80008138 <digits+0xf8>
    80001330:	fffff097          	auipc	ra,0xfffff
    80001334:	210080e7          	jalr	528(ra) # 80000540 <panic>

0000000080001338 <kvmmake>:
{
    80001338:	1101                	addi	sp,sp,-32
    8000133a:	ec06                	sd	ra,24(sp)
    8000133c:	e822                	sd	s0,16(sp)
    8000133e:	e426                	sd	s1,8(sp)
    80001340:	e04a                	sd	s2,0(sp)
    80001342:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001344:	00000097          	auipc	ra,0x0
    80001348:	962080e7          	jalr	-1694(ra) # 80000ca6 <kalloc>
    8000134c:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    8000134e:	6605                	lui	a2,0x1
    80001350:	4581                	li	a1,0
    80001352:	00000097          	auipc	ra,0x0
    80001356:	b4a080e7          	jalr	-1206(ra) # 80000e9c <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    8000135a:	4719                	li	a4,6
    8000135c:	6685                	lui	a3,0x1
    8000135e:	10000637          	lui	a2,0x10000
    80001362:	100005b7          	lui	a1,0x10000
    80001366:	8526                	mv	a0,s1
    80001368:	00000097          	auipc	ra,0x0
    8000136c:	fa0080e7          	jalr	-96(ra) # 80001308 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001370:	4719                	li	a4,6
    80001372:	6685                	lui	a3,0x1
    80001374:	10001637          	lui	a2,0x10001
    80001378:	100015b7          	lui	a1,0x10001
    8000137c:	8526                	mv	a0,s1
    8000137e:	00000097          	auipc	ra,0x0
    80001382:	f8a080e7          	jalr	-118(ra) # 80001308 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80001386:	4719                	li	a4,6
    80001388:	004006b7          	lui	a3,0x400
    8000138c:	0c000637          	lui	a2,0xc000
    80001390:	0c0005b7          	lui	a1,0xc000
    80001394:	8526                	mv	a0,s1
    80001396:	00000097          	auipc	ra,0x0
    8000139a:	f72080e7          	jalr	-142(ra) # 80001308 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    8000139e:	00007917          	auipc	s2,0x7
    800013a2:	c6290913          	addi	s2,s2,-926 # 80008000 <etext>
    800013a6:	4729                	li	a4,10
    800013a8:	80007697          	auipc	a3,0x80007
    800013ac:	c5868693          	addi	a3,a3,-936 # 8000 <_entry-0x7fff8000>
    800013b0:	4605                	li	a2,1
    800013b2:	067e                	slli	a2,a2,0x1f
    800013b4:	85b2                	mv	a1,a2
    800013b6:	8526                	mv	a0,s1
    800013b8:	00000097          	auipc	ra,0x0
    800013bc:	f50080e7          	jalr	-176(ra) # 80001308 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800013c0:	4719                	li	a4,6
    800013c2:	46c5                	li	a3,17
    800013c4:	06ee                	slli	a3,a3,0x1b
    800013c6:	412686b3          	sub	a3,a3,s2
    800013ca:	864a                	mv	a2,s2
    800013cc:	85ca                	mv	a1,s2
    800013ce:	8526                	mv	a0,s1
    800013d0:	00000097          	auipc	ra,0x0
    800013d4:	f38080e7          	jalr	-200(ra) # 80001308 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    800013d8:	4729                	li	a4,10
    800013da:	6685                	lui	a3,0x1
    800013dc:	00006617          	auipc	a2,0x6
    800013e0:	c2460613          	addi	a2,a2,-988 # 80007000 <_trampoline>
    800013e4:	040005b7          	lui	a1,0x4000
    800013e8:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    800013ea:	05b2                	slli	a1,a1,0xc
    800013ec:	8526                	mv	a0,s1
    800013ee:	00000097          	auipc	ra,0x0
    800013f2:	f1a080e7          	jalr	-230(ra) # 80001308 <kvmmap>
  proc_mapstacks(kpgtbl);
    800013f6:	8526                	mv	a0,s1
    800013f8:	00000097          	auipc	ra,0x0
    800013fc:	646080e7          	jalr	1606(ra) # 80001a3e <proc_mapstacks>
}
    80001400:	8526                	mv	a0,s1
    80001402:	60e2                	ld	ra,24(sp)
    80001404:	6442                	ld	s0,16(sp)
    80001406:	64a2                	ld	s1,8(sp)
    80001408:	6902                	ld	s2,0(sp)
    8000140a:	6105                	addi	sp,sp,32
    8000140c:	8082                	ret

000000008000140e <kvminit>:
{
    8000140e:	1141                	addi	sp,sp,-16
    80001410:	e406                	sd	ra,8(sp)
    80001412:	e022                	sd	s0,0(sp)
    80001414:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001416:	00000097          	auipc	ra,0x0
    8000141a:	f22080e7          	jalr	-222(ra) # 80001338 <kvmmake>
    8000141e:	00007797          	auipc	a5,0x7
    80001422:	7aa7b923          	sd	a0,1970(a5) # 80008bd0 <kernel_pagetable>
}
    80001426:	60a2                	ld	ra,8(sp)
    80001428:	6402                	ld	s0,0(sp)
    8000142a:	0141                	addi	sp,sp,16
    8000142c:	8082                	ret

000000008000142e <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    8000142e:	715d                	addi	sp,sp,-80
    80001430:	e486                	sd	ra,72(sp)
    80001432:	e0a2                	sd	s0,64(sp)
    80001434:	fc26                	sd	s1,56(sp)
    80001436:	f84a                	sd	s2,48(sp)
    80001438:	f44e                	sd	s3,40(sp)
    8000143a:	f052                	sd	s4,32(sp)
    8000143c:	ec56                	sd	s5,24(sp)
    8000143e:	e85a                	sd	s6,16(sp)
    80001440:	e45e                	sd	s7,8(sp)
    80001442:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001444:	03459793          	slli	a5,a1,0x34
    80001448:	e795                	bnez	a5,80001474 <uvmunmap+0x46>
    8000144a:	8a2a                	mv	s4,a0
    8000144c:	892e                	mv	s2,a1
    8000144e:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001450:	0632                	slli	a2,a2,0xc
    80001452:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001456:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001458:	6b05                	lui	s6,0x1
    8000145a:	0735e263          	bltu	a1,s3,800014be <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    8000145e:	60a6                	ld	ra,72(sp)
    80001460:	6406                	ld	s0,64(sp)
    80001462:	74e2                	ld	s1,56(sp)
    80001464:	7942                	ld	s2,48(sp)
    80001466:	79a2                	ld	s3,40(sp)
    80001468:	7a02                	ld	s4,32(sp)
    8000146a:	6ae2                	ld	s5,24(sp)
    8000146c:	6b42                	ld	s6,16(sp)
    8000146e:	6ba2                	ld	s7,8(sp)
    80001470:	6161                	addi	sp,sp,80
    80001472:	8082                	ret
    panic("uvmunmap: not aligned");
    80001474:	00007517          	auipc	a0,0x7
    80001478:	ccc50513          	addi	a0,a0,-820 # 80008140 <digits+0x100>
    8000147c:	fffff097          	auipc	ra,0xfffff
    80001480:	0c4080e7          	jalr	196(ra) # 80000540 <panic>
      panic("uvmunmap: walk");
    80001484:	00007517          	auipc	a0,0x7
    80001488:	cd450513          	addi	a0,a0,-812 # 80008158 <digits+0x118>
    8000148c:	fffff097          	auipc	ra,0xfffff
    80001490:	0b4080e7          	jalr	180(ra) # 80000540 <panic>
      panic("uvmunmap: not mapped");
    80001494:	00007517          	auipc	a0,0x7
    80001498:	cd450513          	addi	a0,a0,-812 # 80008168 <digits+0x128>
    8000149c:	fffff097          	auipc	ra,0xfffff
    800014a0:	0a4080e7          	jalr	164(ra) # 80000540 <panic>
      panic("uvmunmap: not a leaf");
    800014a4:	00007517          	auipc	a0,0x7
    800014a8:	cdc50513          	addi	a0,a0,-804 # 80008180 <digits+0x140>
    800014ac:	fffff097          	auipc	ra,0xfffff
    800014b0:	094080e7          	jalr	148(ra) # 80000540 <panic>
    *pte = 0;
    800014b4:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800014b8:	995a                	add	s2,s2,s6
    800014ba:	fb3972e3          	bgeu	s2,s3,8000145e <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800014be:	4601                	li	a2,0
    800014c0:	85ca                	mv	a1,s2
    800014c2:	8552                	mv	a0,s4
    800014c4:	00000097          	auipc	ra,0x0
    800014c8:	cbc080e7          	jalr	-836(ra) # 80001180 <walk>
    800014cc:	84aa                	mv	s1,a0
    800014ce:	d95d                	beqz	a0,80001484 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800014d0:	6108                	ld	a0,0(a0)
    800014d2:	00157793          	andi	a5,a0,1
    800014d6:	dfdd                	beqz	a5,80001494 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    800014d8:	3ff57793          	andi	a5,a0,1023
    800014dc:	fd7784e3          	beq	a5,s7,800014a4 <uvmunmap+0x76>
    if(do_free){
    800014e0:	fc0a8ae3          	beqz	s5,800014b4 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    800014e4:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800014e6:	0532                	slli	a0,a0,0xc
    800014e8:	fffff097          	auipc	ra,0xfffff
    800014ec:	636080e7          	jalr	1590(ra) # 80000b1e <kfree>
    800014f0:	b7d1                	j	800014b4 <uvmunmap+0x86>

00000000800014f2 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800014f2:	1101                	addi	sp,sp,-32
    800014f4:	ec06                	sd	ra,24(sp)
    800014f6:	e822                	sd	s0,16(sp)
    800014f8:	e426                	sd	s1,8(sp)
    800014fa:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    800014fc:	fffff097          	auipc	ra,0xfffff
    80001500:	7aa080e7          	jalr	1962(ra) # 80000ca6 <kalloc>
    80001504:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001506:	c519                	beqz	a0,80001514 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001508:	6605                	lui	a2,0x1
    8000150a:	4581                	li	a1,0
    8000150c:	00000097          	auipc	ra,0x0
    80001510:	990080e7          	jalr	-1648(ra) # 80000e9c <memset>
  return pagetable;
}
    80001514:	8526                	mv	a0,s1
    80001516:	60e2                	ld	ra,24(sp)
    80001518:	6442                	ld	s0,16(sp)
    8000151a:	64a2                	ld	s1,8(sp)
    8000151c:	6105                	addi	sp,sp,32
    8000151e:	8082                	ret

0000000080001520 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001520:	7179                	addi	sp,sp,-48
    80001522:	f406                	sd	ra,40(sp)
    80001524:	f022                	sd	s0,32(sp)
    80001526:	ec26                	sd	s1,24(sp)
    80001528:	e84a                	sd	s2,16(sp)
    8000152a:	e44e                	sd	s3,8(sp)
    8000152c:	e052                	sd	s4,0(sp)
    8000152e:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001530:	6785                	lui	a5,0x1
    80001532:	04f67863          	bgeu	a2,a5,80001582 <uvmfirst+0x62>
    80001536:	8a2a                	mv	s4,a0
    80001538:	89ae                	mv	s3,a1
    8000153a:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    8000153c:	fffff097          	auipc	ra,0xfffff
    80001540:	76a080e7          	jalr	1898(ra) # 80000ca6 <kalloc>
    80001544:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001546:	6605                	lui	a2,0x1
    80001548:	4581                	li	a1,0
    8000154a:	00000097          	auipc	ra,0x0
    8000154e:	952080e7          	jalr	-1710(ra) # 80000e9c <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001552:	4779                	li	a4,30
    80001554:	86ca                	mv	a3,s2
    80001556:	6605                	lui	a2,0x1
    80001558:	4581                	li	a1,0
    8000155a:	8552                	mv	a0,s4
    8000155c:	00000097          	auipc	ra,0x0
    80001560:	d0c080e7          	jalr	-756(ra) # 80001268 <mappages>
  memmove(mem, src, sz);
    80001564:	8626                	mv	a2,s1
    80001566:	85ce                	mv	a1,s3
    80001568:	854a                	mv	a0,s2
    8000156a:	00000097          	auipc	ra,0x0
    8000156e:	98e080e7          	jalr	-1650(ra) # 80000ef8 <memmove>
}
    80001572:	70a2                	ld	ra,40(sp)
    80001574:	7402                	ld	s0,32(sp)
    80001576:	64e2                	ld	s1,24(sp)
    80001578:	6942                	ld	s2,16(sp)
    8000157a:	69a2                	ld	s3,8(sp)
    8000157c:	6a02                	ld	s4,0(sp)
    8000157e:	6145                	addi	sp,sp,48
    80001580:	8082                	ret
    panic("uvmfirst: more than a page");
    80001582:	00007517          	auipc	a0,0x7
    80001586:	c1650513          	addi	a0,a0,-1002 # 80008198 <digits+0x158>
    8000158a:	fffff097          	auipc	ra,0xfffff
    8000158e:	fb6080e7          	jalr	-74(ra) # 80000540 <panic>

0000000080001592 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001592:	1101                	addi	sp,sp,-32
    80001594:	ec06                	sd	ra,24(sp)
    80001596:	e822                	sd	s0,16(sp)
    80001598:	e426                	sd	s1,8(sp)
    8000159a:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    8000159c:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    8000159e:	00b67d63          	bgeu	a2,a1,800015b8 <uvmdealloc+0x26>
    800015a2:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800015a4:	6785                	lui	a5,0x1
    800015a6:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800015a8:	00f60733          	add	a4,a2,a5
    800015ac:	76fd                	lui	a3,0xfffff
    800015ae:	8f75                	and	a4,a4,a3
    800015b0:	97ae                	add	a5,a5,a1
    800015b2:	8ff5                	and	a5,a5,a3
    800015b4:	00f76863          	bltu	a4,a5,800015c4 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800015b8:	8526                	mv	a0,s1
    800015ba:	60e2                	ld	ra,24(sp)
    800015bc:	6442                	ld	s0,16(sp)
    800015be:	64a2                	ld	s1,8(sp)
    800015c0:	6105                	addi	sp,sp,32
    800015c2:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800015c4:	8f99                	sub	a5,a5,a4
    800015c6:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800015c8:	4685                	li	a3,1
    800015ca:	0007861b          	sext.w	a2,a5
    800015ce:	85ba                	mv	a1,a4
    800015d0:	00000097          	auipc	ra,0x0
    800015d4:	e5e080e7          	jalr	-418(ra) # 8000142e <uvmunmap>
    800015d8:	b7c5                	j	800015b8 <uvmdealloc+0x26>

00000000800015da <uvmalloc>:
  if(newsz < oldsz)
    800015da:	0ab66563          	bltu	a2,a1,80001684 <uvmalloc+0xaa>
{
    800015de:	7139                	addi	sp,sp,-64
    800015e0:	fc06                	sd	ra,56(sp)
    800015e2:	f822                	sd	s0,48(sp)
    800015e4:	f426                	sd	s1,40(sp)
    800015e6:	f04a                	sd	s2,32(sp)
    800015e8:	ec4e                	sd	s3,24(sp)
    800015ea:	e852                	sd	s4,16(sp)
    800015ec:	e456                	sd	s5,8(sp)
    800015ee:	e05a                	sd	s6,0(sp)
    800015f0:	0080                	addi	s0,sp,64
    800015f2:	8aaa                	mv	s5,a0
    800015f4:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    800015f6:	6785                	lui	a5,0x1
    800015f8:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800015fa:	95be                	add	a1,a1,a5
    800015fc:	77fd                	lui	a5,0xfffff
    800015fe:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001602:	08c9f363          	bgeu	s3,a2,80001688 <uvmalloc+0xae>
    80001606:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001608:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    8000160c:	fffff097          	auipc	ra,0xfffff
    80001610:	69a080e7          	jalr	1690(ra) # 80000ca6 <kalloc>
    80001614:	84aa                	mv	s1,a0
    if(mem == 0){
    80001616:	c51d                	beqz	a0,80001644 <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    80001618:	6605                	lui	a2,0x1
    8000161a:	4581                	li	a1,0
    8000161c:	00000097          	auipc	ra,0x0
    80001620:	880080e7          	jalr	-1920(ra) # 80000e9c <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001624:	875a                	mv	a4,s6
    80001626:	86a6                	mv	a3,s1
    80001628:	6605                	lui	a2,0x1
    8000162a:	85ca                	mv	a1,s2
    8000162c:	8556                	mv	a0,s5
    8000162e:	00000097          	auipc	ra,0x0
    80001632:	c3a080e7          	jalr	-966(ra) # 80001268 <mappages>
    80001636:	e90d                	bnez	a0,80001668 <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001638:	6785                	lui	a5,0x1
    8000163a:	993e                	add	s2,s2,a5
    8000163c:	fd4968e3          	bltu	s2,s4,8000160c <uvmalloc+0x32>
  return newsz;
    80001640:	8552                	mv	a0,s4
    80001642:	a809                	j	80001654 <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    80001644:	864e                	mv	a2,s3
    80001646:	85ca                	mv	a1,s2
    80001648:	8556                	mv	a0,s5
    8000164a:	00000097          	auipc	ra,0x0
    8000164e:	f48080e7          	jalr	-184(ra) # 80001592 <uvmdealloc>
      return 0;
    80001652:	4501                	li	a0,0
}
    80001654:	70e2                	ld	ra,56(sp)
    80001656:	7442                	ld	s0,48(sp)
    80001658:	74a2                	ld	s1,40(sp)
    8000165a:	7902                	ld	s2,32(sp)
    8000165c:	69e2                	ld	s3,24(sp)
    8000165e:	6a42                	ld	s4,16(sp)
    80001660:	6aa2                	ld	s5,8(sp)
    80001662:	6b02                	ld	s6,0(sp)
    80001664:	6121                	addi	sp,sp,64
    80001666:	8082                	ret
      kfree(mem);
    80001668:	8526                	mv	a0,s1
    8000166a:	fffff097          	auipc	ra,0xfffff
    8000166e:	4b4080e7          	jalr	1204(ra) # 80000b1e <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001672:	864e                	mv	a2,s3
    80001674:	85ca                	mv	a1,s2
    80001676:	8556                	mv	a0,s5
    80001678:	00000097          	auipc	ra,0x0
    8000167c:	f1a080e7          	jalr	-230(ra) # 80001592 <uvmdealloc>
      return 0;
    80001680:	4501                	li	a0,0
    80001682:	bfc9                	j	80001654 <uvmalloc+0x7a>
    return oldsz;
    80001684:	852e                	mv	a0,a1
}
    80001686:	8082                	ret
  return newsz;
    80001688:	8532                	mv	a0,a2
    8000168a:	b7e9                	j	80001654 <uvmalloc+0x7a>

000000008000168c <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    8000168c:	7179                	addi	sp,sp,-48
    8000168e:	f406                	sd	ra,40(sp)
    80001690:	f022                	sd	s0,32(sp)
    80001692:	ec26                	sd	s1,24(sp)
    80001694:	e84a                	sd	s2,16(sp)
    80001696:	e44e                	sd	s3,8(sp)
    80001698:	e052                	sd	s4,0(sp)
    8000169a:	1800                	addi	s0,sp,48
    8000169c:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    8000169e:	84aa                	mv	s1,a0
    800016a0:	6905                	lui	s2,0x1
    800016a2:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800016a4:	4985                	li	s3,1
    800016a6:	a829                	j	800016c0 <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800016a8:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    800016aa:	00c79513          	slli	a0,a5,0xc
    800016ae:	00000097          	auipc	ra,0x0
    800016b2:	fde080e7          	jalr	-34(ra) # 8000168c <freewalk>
      pagetable[i] = 0;
    800016b6:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800016ba:	04a1                	addi	s1,s1,8
    800016bc:	03248163          	beq	s1,s2,800016de <freewalk+0x52>
    pte_t pte = pagetable[i];
    800016c0:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800016c2:	00f7f713          	andi	a4,a5,15
    800016c6:	ff3701e3          	beq	a4,s3,800016a8 <freewalk+0x1c>
    } else if(pte & PTE_V){
    800016ca:	8b85                	andi	a5,a5,1
    800016cc:	d7fd                	beqz	a5,800016ba <freewalk+0x2e>
      panic("freewalk: leaf");
    800016ce:	00007517          	auipc	a0,0x7
    800016d2:	aea50513          	addi	a0,a0,-1302 # 800081b8 <digits+0x178>
    800016d6:	fffff097          	auipc	ra,0xfffff
    800016da:	e6a080e7          	jalr	-406(ra) # 80000540 <panic>
    }
  }
  kfree((void*)pagetable);
    800016de:	8552                	mv	a0,s4
    800016e0:	fffff097          	auipc	ra,0xfffff
    800016e4:	43e080e7          	jalr	1086(ra) # 80000b1e <kfree>
}
    800016e8:	70a2                	ld	ra,40(sp)
    800016ea:	7402                	ld	s0,32(sp)
    800016ec:	64e2                	ld	s1,24(sp)
    800016ee:	6942                	ld	s2,16(sp)
    800016f0:	69a2                	ld	s3,8(sp)
    800016f2:	6a02                	ld	s4,0(sp)
    800016f4:	6145                	addi	sp,sp,48
    800016f6:	8082                	ret

00000000800016f8 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800016f8:	1101                	addi	sp,sp,-32
    800016fa:	ec06                	sd	ra,24(sp)
    800016fc:	e822                	sd	s0,16(sp)
    800016fe:	e426                	sd	s1,8(sp)
    80001700:	1000                	addi	s0,sp,32
    80001702:	84aa                	mv	s1,a0
  if(sz > 0)
    80001704:	e999                	bnez	a1,8000171a <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001706:	8526                	mv	a0,s1
    80001708:	00000097          	auipc	ra,0x0
    8000170c:	f84080e7          	jalr	-124(ra) # 8000168c <freewalk>
}
    80001710:	60e2                	ld	ra,24(sp)
    80001712:	6442                	ld	s0,16(sp)
    80001714:	64a2                	ld	s1,8(sp)
    80001716:	6105                	addi	sp,sp,32
    80001718:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000171a:	6785                	lui	a5,0x1
    8000171c:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    8000171e:	95be                	add	a1,a1,a5
    80001720:	4685                	li	a3,1
    80001722:	00c5d613          	srli	a2,a1,0xc
    80001726:	4581                	li	a1,0
    80001728:	00000097          	auipc	ra,0x0
    8000172c:	d06080e7          	jalr	-762(ra) # 8000142e <uvmunmap>
    80001730:	bfd9                	j	80001706 <uvmfree+0xe>

0000000080001732 <uvmcopy>:
// physical memory.
// returns 0 on success, -1 on failure.
// frees any allocated pages on failure.
int
uvmcopy(pagetable_t old, pagetable_t new, uint64 sz)
{
    80001732:	715d                	addi	sp,sp,-80
    80001734:	e486                	sd	ra,72(sp)
    80001736:	e0a2                	sd	s0,64(sp)
    80001738:	fc26                	sd	s1,56(sp)
    8000173a:	f84a                	sd	s2,48(sp)
    8000173c:	f44e                	sd	s3,40(sp)
    8000173e:	f052                	sd	s4,32(sp)
    80001740:	ec56                	sd	s5,24(sp)
    80001742:	e85a                	sd	s6,16(sp)
    80001744:	e45e                	sd	s7,8(sp)
    80001746:	0880                	addi	s0,sp,80
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  
  for(i = 0; i < sz; i += PGSIZE){
    80001748:	ce5d                	beqz	a2,80001806 <uvmcopy+0xd4>
    8000174a:	8aaa                	mv	s5,a0
    8000174c:	8a2e                	mv	s4,a1
    8000174e:	89b2                	mv	s3,a2
    80001750:	4481                	li	s1,0
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    flags = PTE_FLAGS(*pte);
    if(flags&PTE_W){
      flags = (flags&(~PTE_W))|PTE_COW;
      *pte = PA2PTE(pa)|flags;
    80001752:	7b7d                	lui	s6,0xfffff
    80001754:	002b5b13          	srli	s6,s6,0x2
    80001758:	a0a1                	j	800017a0 <uvmcopy+0x6e>
      panic("uvmcopy: pte should exist");
    8000175a:	00007517          	auipc	a0,0x7
    8000175e:	a6e50513          	addi	a0,a0,-1426 # 800081c8 <digits+0x188>
    80001762:	fffff097          	auipc	ra,0xfffff
    80001766:	dde080e7          	jalr	-546(ra) # 80000540 <panic>
      panic("uvmcopy: page not present");
    8000176a:	00007517          	auipc	a0,0x7
    8000176e:	a7e50513          	addi	a0,a0,-1410 # 800081e8 <digits+0x1a8>
    80001772:	fffff097          	auipc	ra,0xfffff
    80001776:	dce080e7          	jalr	-562(ra) # 80000540 <panic>
    }
    if(mappages(new, i, PGSIZE, pa, flags) != 0){
    8000177a:	86ca                	mv	a3,s2
    8000177c:	6605                	lui	a2,0x1
    8000177e:	85a6                	mv	a1,s1
    80001780:	8552                	mv	a0,s4
    80001782:	00000097          	auipc	ra,0x0
    80001786:	ae6080e7          	jalr	-1306(ra) # 80001268 <mappages>
    8000178a:	8baa                	mv	s7,a0
    8000178c:	e539                	bnez	a0,800017da <uvmcopy+0xa8>
       goto err;
    }
    inc_page_ref((void*)pa);
    8000178e:	854a                	mv	a0,s2
    80001790:	fffff097          	auipc	ra,0xfffff
    80001794:	324080e7          	jalr	804(ra) # 80000ab4 <inc_page_ref>
  for(i = 0; i < sz; i += PGSIZE){
    80001798:	6785                	lui	a5,0x1
    8000179a:	94be                	add	s1,s1,a5
    8000179c:	0534f963          	bgeu	s1,s3,800017ee <uvmcopy+0xbc>
    if((pte = walk(old, i, 0)) == 0)
    800017a0:	4601                	li	a2,0
    800017a2:	85a6                	mv	a1,s1
    800017a4:	8556                	mv	a0,s5
    800017a6:	00000097          	auipc	ra,0x0
    800017aa:	9da080e7          	jalr	-1574(ra) # 80001180 <walk>
    800017ae:	d555                	beqz	a0,8000175a <uvmcopy+0x28>
    if((*pte & PTE_V) == 0)
    800017b0:	611c                	ld	a5,0(a0)
    800017b2:	0017f713          	andi	a4,a5,1
    800017b6:	db55                	beqz	a4,8000176a <uvmcopy+0x38>
    pa = PTE2PA(*pte);
    800017b8:	00a7d913          	srli	s2,a5,0xa
    800017bc:	0932                	slli	s2,s2,0xc
    flags = PTE_FLAGS(*pte);
    800017be:	3ff7f713          	andi	a4,a5,1023
    if(flags&PTE_W){
    800017c2:	0047f693          	andi	a3,a5,4
    800017c6:	dad5                	beqz	a3,8000177a <uvmcopy+0x48>
      flags = (flags&(~PTE_W))|PTE_COW;
    800017c8:	fdb77693          	andi	a3,a4,-37
    800017cc:	0206e713          	ori	a4,a3,32
      *pte = PA2PTE(pa)|flags;
    800017d0:	0167f7b3          	and	a5,a5,s6
    800017d4:	8fd9                	or	a5,a5,a4
    800017d6:	e11c                	sd	a5,0(a0)
    800017d8:	b74d                	j	8000177a <uvmcopy+0x48>
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800017da:	4685                	li	a3,1
    800017dc:	00c4d613          	srli	a2,s1,0xc
    800017e0:	4581                	li	a1,0
    800017e2:	8552                	mv	a0,s4
    800017e4:	00000097          	auipc	ra,0x0
    800017e8:	c4a080e7          	jalr	-950(ra) # 8000142e <uvmunmap>
  return -1;
    800017ec:	5bfd                	li	s7,-1
}
    800017ee:	855e                	mv	a0,s7
    800017f0:	60a6                	ld	ra,72(sp)
    800017f2:	6406                	ld	s0,64(sp)
    800017f4:	74e2                	ld	s1,56(sp)
    800017f6:	7942                	ld	s2,48(sp)
    800017f8:	79a2                	ld	s3,40(sp)
    800017fa:	7a02                	ld	s4,32(sp)
    800017fc:	6ae2                	ld	s5,24(sp)
    800017fe:	6b42                	ld	s6,16(sp)
    80001800:	6ba2                	ld	s7,8(sp)
    80001802:	6161                	addi	sp,sp,80
    80001804:	8082                	ret
  return 0;
    80001806:	4b81                	li	s7,0
    80001808:	b7dd                	j	800017ee <uvmcopy+0xbc>

000000008000180a <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000180a:	1141                	addi	sp,sp,-16
    8000180c:	e406                	sd	ra,8(sp)
    8000180e:	e022                	sd	s0,0(sp)
    80001810:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001812:	4601                	li	a2,0
    80001814:	00000097          	auipc	ra,0x0
    80001818:	96c080e7          	jalr	-1684(ra) # 80001180 <walk>
  if(pte == 0)
    8000181c:	c901                	beqz	a0,8000182c <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000181e:	611c                	ld	a5,0(a0)
    80001820:	9bbd                	andi	a5,a5,-17
    80001822:	e11c                	sd	a5,0(a0)
}
    80001824:	60a2                	ld	ra,8(sp)
    80001826:	6402                	ld	s0,0(sp)
    80001828:	0141                	addi	sp,sp,16
    8000182a:	8082                	ret
    panic("uvmclear");
    8000182c:	00007517          	auipc	a0,0x7
    80001830:	9dc50513          	addi	a0,a0,-1572 # 80008208 <digits+0x1c8>
    80001834:	fffff097          	auipc	ra,0xfffff
    80001838:	d0c080e7          	jalr	-756(ra) # 80000540 <panic>

000000008000183c <copyout>:
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0, flags;
  pte_t *pte;

  while(len > 0){
    8000183c:	c2d5                	beqz	a3,800018e0 <copyout+0xa4>
{
    8000183e:	711d                	addi	sp,sp,-96
    80001840:	ec86                	sd	ra,88(sp)
    80001842:	e8a2                	sd	s0,80(sp)
    80001844:	e4a6                	sd	s1,72(sp)
    80001846:	e0ca                	sd	s2,64(sp)
    80001848:	fc4e                	sd	s3,56(sp)
    8000184a:	f852                	sd	s4,48(sp)
    8000184c:	f456                	sd	s5,40(sp)
    8000184e:	f05a                	sd	s6,32(sp)
    80001850:	ec5e                	sd	s7,24(sp)
    80001852:	e862                	sd	s8,16(sp)
    80001854:	e466                	sd	s9,8(sp)
    80001856:	1080                	addi	s0,sp,96
    80001858:	8baa                	mv	s7,a0
    8000185a:	89ae                	mv	s3,a1
    8000185c:	8b32                	mv	s6,a2
    8000185e:	8ab6                	mv	s5,a3
    va0 = PGROUNDDOWN(dstva);
    80001860:	7cfd                	lui	s9,0xfffff
    if(flags & PTE_COW){
      int ret_val = page_fault_handler((void*)va0,pagetable);
      ret_val *= 1; // Fuck warning as errors 
      pa0 = walkaddr(pagetable,va0);
    }
    n = PGSIZE - (dstva - va0);
    80001862:	6c05                	lui	s8,0x1
    80001864:	a081                	j	800018a4 <copyout+0x68>
      int ret_val = page_fault_handler((void*)va0,pagetable);
    80001866:	85de                	mv	a1,s7
    80001868:	854a                	mv	a0,s2
    8000186a:	00001097          	auipc	ra,0x1
    8000186e:	39e080e7          	jalr	926(ra) # 80002c08 <page_fault_handler>
      pa0 = walkaddr(pagetable,va0);
    80001872:	85ca                	mv	a1,s2
    80001874:	855e                	mv	a0,s7
    80001876:	00000097          	auipc	ra,0x0
    8000187a:	9b0080e7          	jalr	-1616(ra) # 80001226 <walkaddr>
    8000187e:	8a2a                	mv	s4,a0
    80001880:	a0b9                	j	800018ce <copyout+0x92>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001882:	41298533          	sub	a0,s3,s2
    80001886:	0004861b          	sext.w	a2,s1
    8000188a:	85da                	mv	a1,s6
    8000188c:	9552                	add	a0,a0,s4
    8000188e:	fffff097          	auipc	ra,0xfffff
    80001892:	66a080e7          	jalr	1642(ra) # 80000ef8 <memmove>

    len -= n;
    80001896:	409a8ab3          	sub	s5,s5,s1
    src += n;
    8000189a:	9b26                	add	s6,s6,s1
    dstva = va0 + PGSIZE;
    8000189c:	018909b3          	add	s3,s2,s8
  while(len > 0){
    800018a0:	020a8e63          	beqz	s5,800018dc <copyout+0xa0>
    va0 = PGROUNDDOWN(dstva);
    800018a4:	0199f933          	and	s2,s3,s9
    pa0 = walkaddr(pagetable, va0);
    800018a8:	85ca                	mv	a1,s2
    800018aa:	855e                	mv	a0,s7
    800018ac:	00000097          	auipc	ra,0x0
    800018b0:	97a080e7          	jalr	-1670(ra) # 80001226 <walkaddr>
    800018b4:	8a2a                	mv	s4,a0
    if(pa0 == 0)
    800018b6:	c51d                	beqz	a0,800018e4 <copyout+0xa8>
    pte = walk(pagetable,va0,0);
    800018b8:	4601                	li	a2,0
    800018ba:	85ca                	mv	a1,s2
    800018bc:	855e                	mv	a0,s7
    800018be:	00000097          	auipc	ra,0x0
    800018c2:	8c2080e7          	jalr	-1854(ra) # 80001180 <walk>
    if(flags & PTE_COW){
    800018c6:	611c                	ld	a5,0(a0)
    800018c8:	0207f793          	andi	a5,a5,32
    800018cc:	ffc9                	bnez	a5,80001866 <copyout+0x2a>
    n = PGSIZE - (dstva - va0);
    800018ce:	413904b3          	sub	s1,s2,s3
    800018d2:	94e2                	add	s1,s1,s8
    800018d4:	fa9af7e3          	bgeu	s5,s1,80001882 <copyout+0x46>
    800018d8:	84d6                	mv	s1,s5
    800018da:	b765                	j	80001882 <copyout+0x46>
  }
  return 0;
    800018dc:	4501                	li	a0,0
    800018de:	a021                	j	800018e6 <copyout+0xaa>
    800018e0:	4501                	li	a0,0
}
    800018e2:	8082                	ret
      return -1;
    800018e4:	557d                	li	a0,-1
}
    800018e6:	60e6                	ld	ra,88(sp)
    800018e8:	6446                	ld	s0,80(sp)
    800018ea:	64a6                	ld	s1,72(sp)
    800018ec:	6906                	ld	s2,64(sp)
    800018ee:	79e2                	ld	s3,56(sp)
    800018f0:	7a42                	ld	s4,48(sp)
    800018f2:	7aa2                	ld	s5,40(sp)
    800018f4:	7b02                	ld	s6,32(sp)
    800018f6:	6be2                	ld	s7,24(sp)
    800018f8:	6c42                	ld	s8,16(sp)
    800018fa:	6ca2                	ld	s9,8(sp)
    800018fc:	6125                	addi	sp,sp,96
    800018fe:	8082                	ret

0000000080001900 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001900:	caa5                	beqz	a3,80001970 <copyin+0x70>
{
    80001902:	715d                	addi	sp,sp,-80
    80001904:	e486                	sd	ra,72(sp)
    80001906:	e0a2                	sd	s0,64(sp)
    80001908:	fc26                	sd	s1,56(sp)
    8000190a:	f84a                	sd	s2,48(sp)
    8000190c:	f44e                	sd	s3,40(sp)
    8000190e:	f052                	sd	s4,32(sp)
    80001910:	ec56                	sd	s5,24(sp)
    80001912:	e85a                	sd	s6,16(sp)
    80001914:	e45e                	sd	s7,8(sp)
    80001916:	e062                	sd	s8,0(sp)
    80001918:	0880                	addi	s0,sp,80
    8000191a:	8b2a                	mv	s6,a0
    8000191c:	8a2e                	mv	s4,a1
    8000191e:	8c32                	mv	s8,a2
    80001920:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001922:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001924:	6a85                	lui	s5,0x1
    80001926:	a01d                	j	8000194c <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001928:	018505b3          	add	a1,a0,s8
    8000192c:	0004861b          	sext.w	a2,s1
    80001930:	412585b3          	sub	a1,a1,s2
    80001934:	8552                	mv	a0,s4
    80001936:	fffff097          	auipc	ra,0xfffff
    8000193a:	5c2080e7          	jalr	1474(ra) # 80000ef8 <memmove>

    len -= n;
    8000193e:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001942:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001944:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001948:	02098263          	beqz	s3,8000196c <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    8000194c:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001950:	85ca                	mv	a1,s2
    80001952:	855a                	mv	a0,s6
    80001954:	00000097          	auipc	ra,0x0
    80001958:	8d2080e7          	jalr	-1838(ra) # 80001226 <walkaddr>
    if(pa0 == 0)
    8000195c:	cd01                	beqz	a0,80001974 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    8000195e:	418904b3          	sub	s1,s2,s8
    80001962:	94d6                	add	s1,s1,s5
    80001964:	fc99f2e3          	bgeu	s3,s1,80001928 <copyin+0x28>
    80001968:	84ce                	mv	s1,s3
    8000196a:	bf7d                	j	80001928 <copyin+0x28>
  }
  return 0;
    8000196c:	4501                	li	a0,0
    8000196e:	a021                	j	80001976 <copyin+0x76>
    80001970:	4501                	li	a0,0
}
    80001972:	8082                	ret
      return -1;
    80001974:	557d                	li	a0,-1
}
    80001976:	60a6                	ld	ra,72(sp)
    80001978:	6406                	ld	s0,64(sp)
    8000197a:	74e2                	ld	s1,56(sp)
    8000197c:	7942                	ld	s2,48(sp)
    8000197e:	79a2                	ld	s3,40(sp)
    80001980:	7a02                	ld	s4,32(sp)
    80001982:	6ae2                	ld	s5,24(sp)
    80001984:	6b42                	ld	s6,16(sp)
    80001986:	6ba2                	ld	s7,8(sp)
    80001988:	6c02                	ld	s8,0(sp)
    8000198a:	6161                	addi	sp,sp,80
    8000198c:	8082                	ret

000000008000198e <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000198e:	c2dd                	beqz	a3,80001a34 <copyinstr+0xa6>
{
    80001990:	715d                	addi	sp,sp,-80
    80001992:	e486                	sd	ra,72(sp)
    80001994:	e0a2                	sd	s0,64(sp)
    80001996:	fc26                	sd	s1,56(sp)
    80001998:	f84a                	sd	s2,48(sp)
    8000199a:	f44e                	sd	s3,40(sp)
    8000199c:	f052                	sd	s4,32(sp)
    8000199e:	ec56                	sd	s5,24(sp)
    800019a0:	e85a                	sd	s6,16(sp)
    800019a2:	e45e                	sd	s7,8(sp)
    800019a4:	0880                	addi	s0,sp,80
    800019a6:	8a2a                	mv	s4,a0
    800019a8:	8b2e                	mv	s6,a1
    800019aa:	8bb2                	mv	s7,a2
    800019ac:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800019ae:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800019b0:	6985                	lui	s3,0x1
    800019b2:	a02d                	j	800019dc <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800019b4:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800019b8:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800019ba:	37fd                	addiw	a5,a5,-1
    800019bc:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800019c0:	60a6                	ld	ra,72(sp)
    800019c2:	6406                	ld	s0,64(sp)
    800019c4:	74e2                	ld	s1,56(sp)
    800019c6:	7942                	ld	s2,48(sp)
    800019c8:	79a2                	ld	s3,40(sp)
    800019ca:	7a02                	ld	s4,32(sp)
    800019cc:	6ae2                	ld	s5,24(sp)
    800019ce:	6b42                	ld	s6,16(sp)
    800019d0:	6ba2                	ld	s7,8(sp)
    800019d2:	6161                	addi	sp,sp,80
    800019d4:	8082                	ret
    srcva = va0 + PGSIZE;
    800019d6:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800019da:	c8a9                	beqz	s1,80001a2c <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    800019dc:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800019e0:	85ca                	mv	a1,s2
    800019e2:	8552                	mv	a0,s4
    800019e4:	00000097          	auipc	ra,0x0
    800019e8:	842080e7          	jalr	-1982(ra) # 80001226 <walkaddr>
    if(pa0 == 0)
    800019ec:	c131                	beqz	a0,80001a30 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    800019ee:	417906b3          	sub	a3,s2,s7
    800019f2:	96ce                	add	a3,a3,s3
    800019f4:	00d4f363          	bgeu	s1,a3,800019fa <copyinstr+0x6c>
    800019f8:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800019fa:	955e                	add	a0,a0,s7
    800019fc:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001a00:	daf9                	beqz	a3,800019d6 <copyinstr+0x48>
    80001a02:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001a04:	41650633          	sub	a2,a0,s6
    80001a08:	fff48593          	addi	a1,s1,-1
    80001a0c:	95da                	add	a1,a1,s6
    while(n > 0){
    80001a0e:	96da                	add	a3,a3,s6
      if(*p == '\0'){
    80001a10:	00f60733          	add	a4,a2,a5
    80001a14:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7fdbbd88>
    80001a18:	df51                	beqz	a4,800019b4 <copyinstr+0x26>
        *dst = *p;
    80001a1a:	00e78023          	sb	a4,0(a5)
      --max;
    80001a1e:	40f584b3          	sub	s1,a1,a5
      dst++;
    80001a22:	0785                	addi	a5,a5,1
    while(n > 0){
    80001a24:	fed796e3          	bne	a5,a3,80001a10 <copyinstr+0x82>
      dst++;
    80001a28:	8b3e                	mv	s6,a5
    80001a2a:	b775                	j	800019d6 <copyinstr+0x48>
    80001a2c:	4781                	li	a5,0
    80001a2e:	b771                	j	800019ba <copyinstr+0x2c>
      return -1;
    80001a30:	557d                	li	a0,-1
    80001a32:	b779                	j	800019c0 <copyinstr+0x32>
  int got_null = 0;
    80001a34:	4781                	li	a5,0
  if(got_null){
    80001a36:	37fd                	addiw	a5,a5,-1
    80001a38:	0007851b          	sext.w	a0,a5
}
    80001a3c:	8082                	ret

0000000080001a3e <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
    80001a3e:	7139                	addi	sp,sp,-64
    80001a40:	fc06                	sd	ra,56(sp)
    80001a42:	f822                	sd	s0,48(sp)
    80001a44:	f426                	sd	s1,40(sp)
    80001a46:	f04a                	sd	s2,32(sp)
    80001a48:	ec4e                	sd	s3,24(sp)
    80001a4a:	e852                	sd	s4,16(sp)
    80001a4c:	e456                	sd	s5,8(sp)
    80001a4e:	e05a                	sd	s6,0(sp)
    80001a50:	0080                	addi	s0,sp,64
    80001a52:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a54:	00230497          	auipc	s1,0x230
    80001a58:	84448493          	addi	s1,s1,-1980 # 80231298 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001a5c:	8b26                	mv	s6,s1
    80001a5e:	00006a97          	auipc	s5,0x6
    80001a62:	5a2a8a93          	addi	s5,s5,1442 # 80008000 <etext>
    80001a66:	04000937          	lui	s2,0x4000
    80001a6a:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001a6c:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a6e:	00236a17          	auipc	s4,0x236
    80001a72:	42aa0a13          	addi	s4,s4,1066 # 80237e98 <tickslock>
    char *pa = kalloc();
    80001a76:	fffff097          	auipc	ra,0xfffff
    80001a7a:	230080e7          	jalr	560(ra) # 80000ca6 <kalloc>
    80001a7e:	862a                	mv	a2,a0
    if(pa == 0)
    80001a80:	c131                	beqz	a0,80001ac4 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001a82:	416485b3          	sub	a1,s1,s6
    80001a86:	8591                	srai	a1,a1,0x4
    80001a88:	000ab783          	ld	a5,0(s5)
    80001a8c:	02f585b3          	mul	a1,a1,a5
    80001a90:	2585                	addiw	a1,a1,1
    80001a92:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001a96:	4719                	li	a4,6
    80001a98:	6685                	lui	a3,0x1
    80001a9a:	40b905b3          	sub	a1,s2,a1
    80001a9e:	854e                	mv	a0,s3
    80001aa0:	00000097          	auipc	ra,0x0
    80001aa4:	868080e7          	jalr	-1944(ra) # 80001308 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001aa8:	1b048493          	addi	s1,s1,432
    80001aac:	fd4495e3          	bne	s1,s4,80001a76 <proc_mapstacks+0x38>
  }
}
    80001ab0:	70e2                	ld	ra,56(sp)
    80001ab2:	7442                	ld	s0,48(sp)
    80001ab4:	74a2                	ld	s1,40(sp)
    80001ab6:	7902                	ld	s2,32(sp)
    80001ab8:	69e2                	ld	s3,24(sp)
    80001aba:	6a42                	ld	s4,16(sp)
    80001abc:	6aa2                	ld	s5,8(sp)
    80001abe:	6b02                	ld	s6,0(sp)
    80001ac0:	6121                	addi	sp,sp,64
    80001ac2:	8082                	ret
      panic("kalloc");
    80001ac4:	00006517          	auipc	a0,0x6
    80001ac8:	75450513          	addi	a0,a0,1876 # 80008218 <digits+0x1d8>
    80001acc:	fffff097          	auipc	ra,0xfffff
    80001ad0:	a74080e7          	jalr	-1420(ra) # 80000540 <panic>

0000000080001ad4 <procinit>:

// initialize the proc table.
void
procinit(void)
{
    80001ad4:	7139                	addi	sp,sp,-64
    80001ad6:	fc06                	sd	ra,56(sp)
    80001ad8:	f822                	sd	s0,48(sp)
    80001ada:	f426                	sd	s1,40(sp)
    80001adc:	f04a                	sd	s2,32(sp)
    80001ade:	ec4e                	sd	s3,24(sp)
    80001ae0:	e852                	sd	s4,16(sp)
    80001ae2:	e456                	sd	s5,8(sp)
    80001ae4:	e05a                	sd	s6,0(sp)
    80001ae6:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    80001ae8:	00006597          	auipc	a1,0x6
    80001aec:	73858593          	addi	a1,a1,1848 # 80008220 <digits+0x1e0>
    80001af0:	0022f517          	auipc	a0,0x22f
    80001af4:	37850513          	addi	a0,a0,888 # 80230e68 <pid_lock>
    80001af8:	fffff097          	auipc	ra,0xfffff
    80001afc:	218080e7          	jalr	536(ra) # 80000d10 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001b00:	00006597          	auipc	a1,0x6
    80001b04:	72858593          	addi	a1,a1,1832 # 80008228 <digits+0x1e8>
    80001b08:	0022f517          	auipc	a0,0x22f
    80001b0c:	37850513          	addi	a0,a0,888 # 80230e80 <wait_lock>
    80001b10:	fffff097          	auipc	ra,0xfffff
    80001b14:	200080e7          	jalr	512(ra) # 80000d10 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b18:	0022f497          	auipc	s1,0x22f
    80001b1c:	78048493          	addi	s1,s1,1920 # 80231298 <proc>
      initlock(&p->lock, "proc");
    80001b20:	00006b17          	auipc	s6,0x6
    80001b24:	718b0b13          	addi	s6,s6,1816 # 80008238 <digits+0x1f8>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    80001b28:	8aa6                	mv	s5,s1
    80001b2a:	00006a17          	auipc	s4,0x6
    80001b2e:	4d6a0a13          	addi	s4,s4,1238 # 80008000 <etext>
    80001b32:	04000937          	lui	s2,0x4000
    80001b36:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001b38:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b3a:	00236997          	auipc	s3,0x236
    80001b3e:	35e98993          	addi	s3,s3,862 # 80237e98 <tickslock>
      initlock(&p->lock, "proc");
    80001b42:	85da                	mv	a1,s6
    80001b44:	8526                	mv	a0,s1
    80001b46:	fffff097          	auipc	ra,0xfffff
    80001b4a:	1ca080e7          	jalr	458(ra) # 80000d10 <initlock>
      p->state = UNUSED;
    80001b4e:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    80001b52:	415487b3          	sub	a5,s1,s5
    80001b56:	8791                	srai	a5,a5,0x4
    80001b58:	000a3703          	ld	a4,0(s4)
    80001b5c:	02e787b3          	mul	a5,a5,a4
    80001b60:	2785                	addiw	a5,a5,1
    80001b62:	00d7979b          	slliw	a5,a5,0xd
    80001b66:	40f907b3          	sub	a5,s2,a5
    80001b6a:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b6c:	1b048493          	addi	s1,s1,432
    80001b70:	fd3499e3          	bne	s1,s3,80001b42 <procinit+0x6e>
  }
}
    80001b74:	70e2                	ld	ra,56(sp)
    80001b76:	7442                	ld	s0,48(sp)
    80001b78:	74a2                	ld	s1,40(sp)
    80001b7a:	7902                	ld	s2,32(sp)
    80001b7c:	69e2                	ld	s3,24(sp)
    80001b7e:	6a42                	ld	s4,16(sp)
    80001b80:	6aa2                	ld	s5,8(sp)
    80001b82:	6b02                	ld	s6,0(sp)
    80001b84:	6121                	addi	sp,sp,64
    80001b86:	8082                	ret

0000000080001b88 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001b88:	1141                	addi	sp,sp,-16
    80001b8a:	e422                	sd	s0,8(sp)
    80001b8c:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001b8e:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001b90:	2501                	sext.w	a0,a0
    80001b92:	6422                	ld	s0,8(sp)
    80001b94:	0141                	addi	sp,sp,16
    80001b96:	8082                	ret

0000000080001b98 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    80001b98:	1141                	addi	sp,sp,-16
    80001b9a:	e422                	sd	s0,8(sp)
    80001b9c:	0800                	addi	s0,sp,16
    80001b9e:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001ba0:	2781                	sext.w	a5,a5
    80001ba2:	079e                	slli	a5,a5,0x7
  return c;
}
    80001ba4:	0022f517          	auipc	a0,0x22f
    80001ba8:	2f450513          	addi	a0,a0,756 # 80230e98 <cpus>
    80001bac:	953e                	add	a0,a0,a5
    80001bae:	6422                	ld	s0,8(sp)
    80001bb0:	0141                	addi	sp,sp,16
    80001bb2:	8082                	ret

0000000080001bb4 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    80001bb4:	1101                	addi	sp,sp,-32
    80001bb6:	ec06                	sd	ra,24(sp)
    80001bb8:	e822                	sd	s0,16(sp)
    80001bba:	e426                	sd	s1,8(sp)
    80001bbc:	1000                	addi	s0,sp,32
  push_off();
    80001bbe:	fffff097          	auipc	ra,0xfffff
    80001bc2:	196080e7          	jalr	406(ra) # 80000d54 <push_off>
    80001bc6:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001bc8:	2781                	sext.w	a5,a5
    80001bca:	079e                	slli	a5,a5,0x7
    80001bcc:	0022f717          	auipc	a4,0x22f
    80001bd0:	29c70713          	addi	a4,a4,668 # 80230e68 <pid_lock>
    80001bd4:	97ba                	add	a5,a5,a4
    80001bd6:	7b84                	ld	s1,48(a5)
  pop_off();
    80001bd8:	fffff097          	auipc	ra,0xfffff
    80001bdc:	21c080e7          	jalr	540(ra) # 80000df4 <pop_off>
  return p;
}
    80001be0:	8526                	mv	a0,s1
    80001be2:	60e2                	ld	ra,24(sp)
    80001be4:	6442                	ld	s0,16(sp)
    80001be6:	64a2                	ld	s1,8(sp)
    80001be8:	6105                	addi	sp,sp,32
    80001bea:	8082                	ret

0000000080001bec <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001bec:	1141                	addi	sp,sp,-16
    80001bee:	e406                	sd	ra,8(sp)
    80001bf0:	e022                	sd	s0,0(sp)
    80001bf2:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001bf4:	00000097          	auipc	ra,0x0
    80001bf8:	fc0080e7          	jalr	-64(ra) # 80001bb4 <myproc>
    80001bfc:	fffff097          	auipc	ra,0xfffff
    80001c00:	258080e7          	jalr	600(ra) # 80000e54 <release>

  if (first) {
    80001c04:	00007797          	auipc	a5,0x7
    80001c08:	dfc7a783          	lw	a5,-516(a5) # 80008a00 <first.1>
    80001c0c:	eb89                	bnez	a5,80001c1e <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001c0e:	00001097          	auipc	ra,0x1
    80001c12:	0fa080e7          	jalr	250(ra) # 80002d08 <usertrapret>
}
    80001c16:	60a2                	ld	ra,8(sp)
    80001c18:	6402                	ld	s0,0(sp)
    80001c1a:	0141                	addi	sp,sp,16
    80001c1c:	8082                	ret
    first = 0;
    80001c1e:	00007797          	auipc	a5,0x7
    80001c22:	de07a123          	sw	zero,-542(a5) # 80008a00 <first.1>
    fsinit(ROOTDEV);
    80001c26:	4505                	li	a0,1
    80001c28:	00002097          	auipc	ra,0x2
    80001c2c:	1a8080e7          	jalr	424(ra) # 80003dd0 <fsinit>
    80001c30:	bff9                	j	80001c0e <forkret+0x22>

0000000080001c32 <allocpid>:
{
    80001c32:	1101                	addi	sp,sp,-32
    80001c34:	ec06                	sd	ra,24(sp)
    80001c36:	e822                	sd	s0,16(sp)
    80001c38:	e426                	sd	s1,8(sp)
    80001c3a:	e04a                	sd	s2,0(sp)
    80001c3c:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001c3e:	0022f917          	auipc	s2,0x22f
    80001c42:	22a90913          	addi	s2,s2,554 # 80230e68 <pid_lock>
    80001c46:	854a                	mv	a0,s2
    80001c48:	fffff097          	auipc	ra,0xfffff
    80001c4c:	158080e7          	jalr	344(ra) # 80000da0 <acquire>
  pid = nextpid;
    80001c50:	00007797          	auipc	a5,0x7
    80001c54:	db878793          	addi	a5,a5,-584 # 80008a08 <nextpid>
    80001c58:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001c5a:	0014871b          	addiw	a4,s1,1
    80001c5e:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001c60:	854a                	mv	a0,s2
    80001c62:	fffff097          	auipc	ra,0xfffff
    80001c66:	1f2080e7          	jalr	498(ra) # 80000e54 <release>
}
    80001c6a:	8526                	mv	a0,s1
    80001c6c:	60e2                	ld	ra,24(sp)
    80001c6e:	6442                	ld	s0,16(sp)
    80001c70:	64a2                	ld	s1,8(sp)
    80001c72:	6902                	ld	s2,0(sp)
    80001c74:	6105                	addi	sp,sp,32
    80001c76:	8082                	ret

0000000080001c78 <proc_pagetable>:
{
    80001c78:	1101                	addi	sp,sp,-32
    80001c7a:	ec06                	sd	ra,24(sp)
    80001c7c:	e822                	sd	s0,16(sp)
    80001c7e:	e426                	sd	s1,8(sp)
    80001c80:	e04a                	sd	s2,0(sp)
    80001c82:	1000                	addi	s0,sp,32
    80001c84:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001c86:	00000097          	auipc	ra,0x0
    80001c8a:	86c080e7          	jalr	-1940(ra) # 800014f2 <uvmcreate>
    80001c8e:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001c90:	c121                	beqz	a0,80001cd0 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001c92:	4729                	li	a4,10
    80001c94:	00005697          	auipc	a3,0x5
    80001c98:	36c68693          	addi	a3,a3,876 # 80007000 <_trampoline>
    80001c9c:	6605                	lui	a2,0x1
    80001c9e:	040005b7          	lui	a1,0x4000
    80001ca2:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001ca4:	05b2                	slli	a1,a1,0xc
    80001ca6:	fffff097          	auipc	ra,0xfffff
    80001caa:	5c2080e7          	jalr	1474(ra) # 80001268 <mappages>
    80001cae:	02054863          	bltz	a0,80001cde <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001cb2:	4719                	li	a4,6
    80001cb4:	05893683          	ld	a3,88(s2)
    80001cb8:	6605                	lui	a2,0x1
    80001cba:	020005b7          	lui	a1,0x2000
    80001cbe:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001cc0:	05b6                	slli	a1,a1,0xd
    80001cc2:	8526                	mv	a0,s1
    80001cc4:	fffff097          	auipc	ra,0xfffff
    80001cc8:	5a4080e7          	jalr	1444(ra) # 80001268 <mappages>
    80001ccc:	02054163          	bltz	a0,80001cee <proc_pagetable+0x76>
}
    80001cd0:	8526                	mv	a0,s1
    80001cd2:	60e2                	ld	ra,24(sp)
    80001cd4:	6442                	ld	s0,16(sp)
    80001cd6:	64a2                	ld	s1,8(sp)
    80001cd8:	6902                	ld	s2,0(sp)
    80001cda:	6105                	addi	sp,sp,32
    80001cdc:	8082                	ret
    uvmfree(pagetable, 0);
    80001cde:	4581                	li	a1,0
    80001ce0:	8526                	mv	a0,s1
    80001ce2:	00000097          	auipc	ra,0x0
    80001ce6:	a16080e7          	jalr	-1514(ra) # 800016f8 <uvmfree>
    return 0;
    80001cea:	4481                	li	s1,0
    80001cec:	b7d5                	j	80001cd0 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001cee:	4681                	li	a3,0
    80001cf0:	4605                	li	a2,1
    80001cf2:	040005b7          	lui	a1,0x4000
    80001cf6:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001cf8:	05b2                	slli	a1,a1,0xc
    80001cfa:	8526                	mv	a0,s1
    80001cfc:	fffff097          	auipc	ra,0xfffff
    80001d00:	732080e7          	jalr	1842(ra) # 8000142e <uvmunmap>
    uvmfree(pagetable, 0);
    80001d04:	4581                	li	a1,0
    80001d06:	8526                	mv	a0,s1
    80001d08:	00000097          	auipc	ra,0x0
    80001d0c:	9f0080e7          	jalr	-1552(ra) # 800016f8 <uvmfree>
    return 0;
    80001d10:	4481                	li	s1,0
    80001d12:	bf7d                	j	80001cd0 <proc_pagetable+0x58>

0000000080001d14 <proc_freepagetable>:
{
    80001d14:	1101                	addi	sp,sp,-32
    80001d16:	ec06                	sd	ra,24(sp)
    80001d18:	e822                	sd	s0,16(sp)
    80001d1a:	e426                	sd	s1,8(sp)
    80001d1c:	e04a                	sd	s2,0(sp)
    80001d1e:	1000                	addi	s0,sp,32
    80001d20:	84aa                	mv	s1,a0
    80001d22:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001d24:	4681                	li	a3,0
    80001d26:	4605                	li	a2,1
    80001d28:	040005b7          	lui	a1,0x4000
    80001d2c:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001d2e:	05b2                	slli	a1,a1,0xc
    80001d30:	fffff097          	auipc	ra,0xfffff
    80001d34:	6fe080e7          	jalr	1790(ra) # 8000142e <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001d38:	4681                	li	a3,0
    80001d3a:	4605                	li	a2,1
    80001d3c:	020005b7          	lui	a1,0x2000
    80001d40:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001d42:	05b6                	slli	a1,a1,0xd
    80001d44:	8526                	mv	a0,s1
    80001d46:	fffff097          	auipc	ra,0xfffff
    80001d4a:	6e8080e7          	jalr	1768(ra) # 8000142e <uvmunmap>
  uvmfree(pagetable, sz);
    80001d4e:	85ca                	mv	a1,s2
    80001d50:	8526                	mv	a0,s1
    80001d52:	00000097          	auipc	ra,0x0
    80001d56:	9a6080e7          	jalr	-1626(ra) # 800016f8 <uvmfree>
}
    80001d5a:	60e2                	ld	ra,24(sp)
    80001d5c:	6442                	ld	s0,16(sp)
    80001d5e:	64a2                	ld	s1,8(sp)
    80001d60:	6902                	ld	s2,0(sp)
    80001d62:	6105                	addi	sp,sp,32
    80001d64:	8082                	ret

0000000080001d66 <freeproc>:
{
    80001d66:	1101                	addi	sp,sp,-32
    80001d68:	ec06                	sd	ra,24(sp)
    80001d6a:	e822                	sd	s0,16(sp)
    80001d6c:	e426                	sd	s1,8(sp)
    80001d6e:	1000                	addi	s0,sp,32
    80001d70:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001d72:	6d28                	ld	a0,88(a0)
    80001d74:	c509                	beqz	a0,80001d7e <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001d76:	fffff097          	auipc	ra,0xfffff
    80001d7a:	da8080e7          	jalr	-600(ra) # 80000b1e <kfree>
  p->trapframe = 0;
    80001d7e:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001d82:	68a8                	ld	a0,80(s1)
    80001d84:	c511                	beqz	a0,80001d90 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001d86:	64ac                	ld	a1,72(s1)
    80001d88:	00000097          	auipc	ra,0x0
    80001d8c:	f8c080e7          	jalr	-116(ra) # 80001d14 <proc_freepagetable>
  p->pagetable = 0;
    80001d90:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001d94:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001d98:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001d9c:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001da0:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001da4:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001da8:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001dac:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001db0:	0004ac23          	sw	zero,24(s1)
  p->spriority = 0;
    80001db4:	1a04a223          	sw	zero,420(s1)
  p->nice = 5;
    80001db8:	4795                	li	a5,5
    80001dba:	1af4a423          	sw	a5,424(s1)
  p->rtime=0;
    80001dbe:	1a04a023          	sw	zero,416(s1)
  p->etime=0;
    80001dc2:	1804ac23          	sw	zero,408(s1)
  p->calls=0;
    80001dc6:	1a04a623          	sw	zero,428(s1)
  p->start_time=0;
    80001dca:	1604a623          	sw	zero,364(s1)
}
    80001dce:	60e2                	ld	ra,24(sp)
    80001dd0:	6442                	ld	s0,16(sp)
    80001dd2:	64a2                	ld	s1,8(sp)
    80001dd4:	6105                	addi	sp,sp,32
    80001dd6:	8082                	ret

0000000080001dd8 <allocproc>:
{
    80001dd8:	1101                	addi	sp,sp,-32
    80001dda:	ec06                	sd	ra,24(sp)
    80001ddc:	e822                	sd	s0,16(sp)
    80001dde:	e426                	sd	s1,8(sp)
    80001de0:	e04a                	sd	s2,0(sp)
    80001de2:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001de4:	0022f497          	auipc	s1,0x22f
    80001de8:	4b448493          	addi	s1,s1,1204 # 80231298 <proc>
    80001dec:	00236917          	auipc	s2,0x236
    80001df0:	0ac90913          	addi	s2,s2,172 # 80237e98 <tickslock>
    acquire(&p->lock);
    80001df4:	8526                	mv	a0,s1
    80001df6:	fffff097          	auipc	ra,0xfffff
    80001dfa:	faa080e7          	jalr	-86(ra) # 80000da0 <acquire>
    if(p->state == UNUSED) {
    80001dfe:	4c9c                	lw	a5,24(s1)
    80001e00:	cf81                	beqz	a5,80001e18 <allocproc+0x40>
      release(&p->lock);
    80001e02:	8526                	mv	a0,s1
    80001e04:	fffff097          	auipc	ra,0xfffff
    80001e08:	050080e7          	jalr	80(ra) # 80000e54 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001e0c:	1b048493          	addi	s1,s1,432
    80001e10:	ff2492e3          	bne	s1,s2,80001df4 <allocproc+0x1c>
  return 0;
    80001e14:	4481                	li	s1,0
    80001e16:	a079                	j	80001ea4 <allocproc+0xcc>
  p->pid = allocpid();
    80001e18:	00000097          	auipc	ra,0x0
    80001e1c:	e1a080e7          	jalr	-486(ra) # 80001c32 <allocpid>
    80001e20:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001e22:	4785                	li	a5,1
    80001e24:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001e26:	fffff097          	auipc	ra,0xfffff
    80001e2a:	e80080e7          	jalr	-384(ra) # 80000ca6 <kalloc>
    80001e2e:	892a                	mv	s2,a0
    80001e30:	eca8                	sd	a0,88(s1)
    80001e32:	c141                	beqz	a0,80001eb2 <allocproc+0xda>
  p->pagetable = proc_pagetable(p);
    80001e34:	8526                	mv	a0,s1
    80001e36:	00000097          	auipc	ra,0x0
    80001e3a:	e42080e7          	jalr	-446(ra) # 80001c78 <proc_pagetable>
    80001e3e:	892a                	mv	s2,a0
    80001e40:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001e42:	c541                	beqz	a0,80001eca <allocproc+0xf2>
  memset(&p->context, 0, sizeof(p->context));
    80001e44:	07000613          	li	a2,112
    80001e48:	4581                	li	a1,0
    80001e4a:	06048513          	addi	a0,s1,96
    80001e4e:	fffff097          	auipc	ra,0xfffff
    80001e52:	04e080e7          	jalr	78(ra) # 80000e9c <memset>
  p->context.ra = (uint64)forkret;
    80001e56:	00000797          	auipc	a5,0x0
    80001e5a:	d9678793          	addi	a5,a5,-618 # 80001bec <forkret>
    80001e5e:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001e60:	60bc                	ld	a5,64(s1)
    80001e62:	6705                	lui	a4,0x1
    80001e64:	97ba                	add	a5,a5,a4
    80001e66:	f4bc                	sd	a5,104(s1)
  p->curr_ticks=0;
    80001e68:	1804a223          	sw	zero,388(s1)
  p->start_time =ticks;
    80001e6c:	00007797          	auipc	a5,0x7
    80001e70:	d7c7a783          	lw	a5,-644(a5) # 80008be8 <ticks>
    80001e74:	16f4a623          	sw	a5,364(s1)
  p->orig_a0=p->trapframe->a0;
    80001e78:	6cbc                	ld	a5,88(s1)
    80001e7a:	7bbc                	ld	a5,112(a5)
    80001e7c:	18f4aa23          	sw	a5,404(s1)
  p->tickets=1;
    80001e80:	4785                	li	a5,1
    80001e82:	16f4a823          	sw	a5,368(s1)
  p->stime=0;
    80001e86:	1804ae23          	sw	zero,412(s1)
  p->rtime=0;
    80001e8a:	1a04a023          	sw	zero,416(s1)
  p->etime=0;
    80001e8e:	1804ac23          	sw	zero,408(s1)
  p->nice=5;
    80001e92:	4795                	li	a5,5
    80001e94:	1af4a423          	sw	a5,424(s1)
  p->spriority=60;
    80001e98:	03c00793          	li	a5,60
    80001e9c:	1af4a223          	sw	a5,420(s1)
  p->calls=0;
    80001ea0:	1a04a623          	sw	zero,428(s1)
}
    80001ea4:	8526                	mv	a0,s1
    80001ea6:	60e2                	ld	ra,24(sp)
    80001ea8:	6442                	ld	s0,16(sp)
    80001eaa:	64a2                	ld	s1,8(sp)
    80001eac:	6902                	ld	s2,0(sp)
    80001eae:	6105                	addi	sp,sp,32
    80001eb0:	8082                	ret
    freeproc(p);
    80001eb2:	8526                	mv	a0,s1
    80001eb4:	00000097          	auipc	ra,0x0
    80001eb8:	eb2080e7          	jalr	-334(ra) # 80001d66 <freeproc>
    release(&p->lock);
    80001ebc:	8526                	mv	a0,s1
    80001ebe:	fffff097          	auipc	ra,0xfffff
    80001ec2:	f96080e7          	jalr	-106(ra) # 80000e54 <release>
    return 0;
    80001ec6:	84ca                	mv	s1,s2
    80001ec8:	bff1                	j	80001ea4 <allocproc+0xcc>
    freeproc(p);
    80001eca:	8526                	mv	a0,s1
    80001ecc:	00000097          	auipc	ra,0x0
    80001ed0:	e9a080e7          	jalr	-358(ra) # 80001d66 <freeproc>
    release(&p->lock);
    80001ed4:	8526                	mv	a0,s1
    80001ed6:	fffff097          	auipc	ra,0xfffff
    80001eda:	f7e080e7          	jalr	-130(ra) # 80000e54 <release>
    return 0;
    80001ede:	84ca                	mv	s1,s2
    80001ee0:	b7d1                	j	80001ea4 <allocproc+0xcc>

0000000080001ee2 <userinit>:
{
    80001ee2:	1101                	addi	sp,sp,-32
    80001ee4:	ec06                	sd	ra,24(sp)
    80001ee6:	e822                	sd	s0,16(sp)
    80001ee8:	e426                	sd	s1,8(sp)
    80001eea:	1000                	addi	s0,sp,32
  p = allocproc();
    80001eec:	00000097          	auipc	ra,0x0
    80001ef0:	eec080e7          	jalr	-276(ra) # 80001dd8 <allocproc>
    80001ef4:	84aa                	mv	s1,a0
  initproc = p;
    80001ef6:	00007797          	auipc	a5,0x7
    80001efa:	cea7b523          	sd	a0,-790(a5) # 80008be0 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001efe:	03400613          	li	a2,52
    80001f02:	00007597          	auipc	a1,0x7
    80001f06:	b0e58593          	addi	a1,a1,-1266 # 80008a10 <initcode>
    80001f0a:	6928                	ld	a0,80(a0)
    80001f0c:	fffff097          	auipc	ra,0xfffff
    80001f10:	614080e7          	jalr	1556(ra) # 80001520 <uvmfirst>
  p->sz = PGSIZE;
    80001f14:	6785                	lui	a5,0x1
    80001f16:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001f18:	6cb8                	ld	a4,88(s1)
    80001f1a:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001f1e:	6cb8                	ld	a4,88(s1)
    80001f20:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001f22:	4641                	li	a2,16
    80001f24:	00006597          	auipc	a1,0x6
    80001f28:	31c58593          	addi	a1,a1,796 # 80008240 <digits+0x200>
    80001f2c:	15848513          	addi	a0,s1,344
    80001f30:	fffff097          	auipc	ra,0xfffff
    80001f34:	0b6080e7          	jalr	182(ra) # 80000fe6 <safestrcpy>
  p->cwd = namei("/");
    80001f38:	00006517          	auipc	a0,0x6
    80001f3c:	31850513          	addi	a0,a0,792 # 80008250 <digits+0x210>
    80001f40:	00003097          	auipc	ra,0x3
    80001f44:	8ba080e7          	jalr	-1862(ra) # 800047fa <namei>
    80001f48:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001f4c:	478d                	li	a5,3
    80001f4e:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001f50:	8526                	mv	a0,s1
    80001f52:	fffff097          	auipc	ra,0xfffff
    80001f56:	f02080e7          	jalr	-254(ra) # 80000e54 <release>
}
    80001f5a:	60e2                	ld	ra,24(sp)
    80001f5c:	6442                	ld	s0,16(sp)
    80001f5e:	64a2                	ld	s1,8(sp)
    80001f60:	6105                	addi	sp,sp,32
    80001f62:	8082                	ret

0000000080001f64 <growproc>:
{
    80001f64:	1101                	addi	sp,sp,-32
    80001f66:	ec06                	sd	ra,24(sp)
    80001f68:	e822                	sd	s0,16(sp)
    80001f6a:	e426                	sd	s1,8(sp)
    80001f6c:	e04a                	sd	s2,0(sp)
    80001f6e:	1000                	addi	s0,sp,32
    80001f70:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001f72:	00000097          	auipc	ra,0x0
    80001f76:	c42080e7          	jalr	-958(ra) # 80001bb4 <myproc>
    80001f7a:	84aa                	mv	s1,a0
  sz = p->sz;
    80001f7c:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001f7e:	01204c63          	bgtz	s2,80001f96 <growproc+0x32>
  } else if(n < 0){
    80001f82:	02094663          	bltz	s2,80001fae <growproc+0x4a>
  p->sz = sz;
    80001f86:	e4ac                	sd	a1,72(s1)
  return 0;
    80001f88:	4501                	li	a0,0
}
    80001f8a:	60e2                	ld	ra,24(sp)
    80001f8c:	6442                	ld	s0,16(sp)
    80001f8e:	64a2                	ld	s1,8(sp)
    80001f90:	6902                	ld	s2,0(sp)
    80001f92:	6105                	addi	sp,sp,32
    80001f94:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001f96:	4691                	li	a3,4
    80001f98:	00b90633          	add	a2,s2,a1
    80001f9c:	6928                	ld	a0,80(a0)
    80001f9e:	fffff097          	auipc	ra,0xfffff
    80001fa2:	63c080e7          	jalr	1596(ra) # 800015da <uvmalloc>
    80001fa6:	85aa                	mv	a1,a0
    80001fa8:	fd79                	bnez	a0,80001f86 <growproc+0x22>
      return -1;
    80001faa:	557d                	li	a0,-1
    80001fac:	bff9                	j	80001f8a <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001fae:	00b90633          	add	a2,s2,a1
    80001fb2:	6928                	ld	a0,80(a0)
    80001fb4:	fffff097          	auipc	ra,0xfffff
    80001fb8:	5de080e7          	jalr	1502(ra) # 80001592 <uvmdealloc>
    80001fbc:	85aa                	mv	a1,a0
    80001fbe:	b7e1                	j	80001f86 <growproc+0x22>

0000000080001fc0 <fork>:
{
    80001fc0:	7139                	addi	sp,sp,-64
    80001fc2:	fc06                	sd	ra,56(sp)
    80001fc4:	f822                	sd	s0,48(sp)
    80001fc6:	f426                	sd	s1,40(sp)
    80001fc8:	f04a                	sd	s2,32(sp)
    80001fca:	ec4e                	sd	s3,24(sp)
    80001fcc:	e852                	sd	s4,16(sp)
    80001fce:	e456                	sd	s5,8(sp)
    80001fd0:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001fd2:	00000097          	auipc	ra,0x0
    80001fd6:	be2080e7          	jalr	-1054(ra) # 80001bb4 <myproc>
    80001fda:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001fdc:	00000097          	auipc	ra,0x0
    80001fe0:	dfc080e7          	jalr	-516(ra) # 80001dd8 <allocproc>
    80001fe4:	10050c63          	beqz	a0,800020fc <fork+0x13c>
    80001fe8:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001fea:	048ab603          	ld	a2,72(s5)
    80001fee:	692c                	ld	a1,80(a0)
    80001ff0:	050ab503          	ld	a0,80(s5)
    80001ff4:	fffff097          	auipc	ra,0xfffff
    80001ff8:	73e080e7          	jalr	1854(ra) # 80001732 <uvmcopy>
    80001ffc:	04054863          	bltz	a0,8000204c <fork+0x8c>
  np->sz = p->sz;
    80002000:	048ab783          	ld	a5,72(s5)
    80002004:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80002008:	058ab683          	ld	a3,88(s5)
    8000200c:	87b6                	mv	a5,a3
    8000200e:	058a3703          	ld	a4,88(s4)
    80002012:	12068693          	addi	a3,a3,288
    80002016:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    8000201a:	6788                	ld	a0,8(a5)
    8000201c:	6b8c                	ld	a1,16(a5)
    8000201e:	6f90                	ld	a2,24(a5)
    80002020:	01073023          	sd	a6,0(a4)
    80002024:	e708                	sd	a0,8(a4)
    80002026:	eb0c                	sd	a1,16(a4)
    80002028:	ef10                	sd	a2,24(a4)
    8000202a:	02078793          	addi	a5,a5,32
    8000202e:	02070713          	addi	a4,a4,32
    80002032:	fed792e3          	bne	a5,a3,80002016 <fork+0x56>
  np->trapframe->a0 = 0;
    80002036:	058a3783          	ld	a5,88(s4)
    8000203a:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    8000203e:	0d0a8493          	addi	s1,s5,208
    80002042:	0d0a0913          	addi	s2,s4,208
    80002046:	150a8993          	addi	s3,s5,336
    8000204a:	a00d                	j	8000206c <fork+0xac>
    freeproc(np);
    8000204c:	8552                	mv	a0,s4
    8000204e:	00000097          	auipc	ra,0x0
    80002052:	d18080e7          	jalr	-744(ra) # 80001d66 <freeproc>
    release(&np->lock);
    80002056:	8552                	mv	a0,s4
    80002058:	fffff097          	auipc	ra,0xfffff
    8000205c:	dfc080e7          	jalr	-516(ra) # 80000e54 <release>
    return -1;
    80002060:	597d                	li	s2,-1
    80002062:	a059                	j	800020e8 <fork+0x128>
  for(i = 0; i < NOFILE; i++)
    80002064:	04a1                	addi	s1,s1,8
    80002066:	0921                	addi	s2,s2,8
    80002068:	01348b63          	beq	s1,s3,8000207e <fork+0xbe>
    if(p->ofile[i])
    8000206c:	6088                	ld	a0,0(s1)
    8000206e:	d97d                	beqz	a0,80002064 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80002070:	00003097          	auipc	ra,0x3
    80002074:	e20080e7          	jalr	-480(ra) # 80004e90 <filedup>
    80002078:	00a93023          	sd	a0,0(s2)
    8000207c:	b7e5                	j	80002064 <fork+0xa4>
  np->cwd = idup(p->cwd);
    8000207e:	150ab503          	ld	a0,336(s5)
    80002082:	00002097          	auipc	ra,0x2
    80002086:	f8e080e7          	jalr	-114(ra) # 80004010 <idup>
    8000208a:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    8000208e:	4641                	li	a2,16
    80002090:	158a8593          	addi	a1,s5,344
    80002094:	158a0513          	addi	a0,s4,344
    80002098:	fffff097          	auipc	ra,0xfffff
    8000209c:	f4e080e7          	jalr	-178(ra) # 80000fe6 <safestrcpy>
  pid = np->pid;
    800020a0:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    800020a4:	8552                	mv	a0,s4
    800020a6:	fffff097          	auipc	ra,0xfffff
    800020aa:	dae080e7          	jalr	-594(ra) # 80000e54 <release>
  acquire(&wait_lock);
    800020ae:	0022f497          	auipc	s1,0x22f
    800020b2:	dd248493          	addi	s1,s1,-558 # 80230e80 <wait_lock>
    800020b6:	8526                	mv	a0,s1
    800020b8:	fffff097          	auipc	ra,0xfffff
    800020bc:	ce8080e7          	jalr	-792(ra) # 80000da0 <acquire>
  np->parent = p;
    800020c0:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    800020c4:	8526                	mv	a0,s1
    800020c6:	fffff097          	auipc	ra,0xfffff
    800020ca:	d8e080e7          	jalr	-626(ra) # 80000e54 <release>
  acquire(&np->lock);
    800020ce:	8552                	mv	a0,s4
    800020d0:	fffff097          	auipc	ra,0xfffff
    800020d4:	cd0080e7          	jalr	-816(ra) # 80000da0 <acquire>
  np->state = RUNNABLE;
    800020d8:	478d                	li	a5,3
    800020da:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    800020de:	8552                	mv	a0,s4
    800020e0:	fffff097          	auipc	ra,0xfffff
    800020e4:	d74080e7          	jalr	-652(ra) # 80000e54 <release>
}
    800020e8:	854a                	mv	a0,s2
    800020ea:	70e2                	ld	ra,56(sp)
    800020ec:	7442                	ld	s0,48(sp)
    800020ee:	74a2                	ld	s1,40(sp)
    800020f0:	7902                	ld	s2,32(sp)
    800020f2:	69e2                	ld	s3,24(sp)
    800020f4:	6a42                	ld	s4,16(sp)
    800020f6:	6aa2                	ld	s5,8(sp)
    800020f8:	6121                	addi	sp,sp,64
    800020fa:	8082                	ret
    return -1;
    800020fc:	597d                	li	s2,-1
    800020fe:	b7ed                	j	800020e8 <fork+0x128>

0000000080002100 <randomn_gen>:
{
    80002100:	1141                	addi	sp,sp,-16
    80002102:	e422                	sd	s0,8(sp)
    80002104:	0800                	addi	s0,sp,16
  bit  = ((lfsr >> 0) ^ (lfsr >> 2) ^ (lfsr >> 3) ^ (lfsr >> 5) ) & 1;
    80002106:	00007717          	auipc	a4,0x7
    8000210a:	8fe70713          	addi	a4,a4,-1794 # 80008a04 <lfsr>
    8000210e:	00075503          	lhu	a0,0(a4)
    80002112:	0025579b          	srliw	a5,a0,0x2
    80002116:	0035569b          	srliw	a3,a0,0x3
    8000211a:	8fb5                	xor	a5,a5,a3
    8000211c:	8fa9                	xor	a5,a5,a0
    8000211e:	0055569b          	srliw	a3,a0,0x5
    80002122:	8fb5                	xor	a5,a5,a3
    80002124:	8b85                	andi	a5,a5,1
    80002126:	00007697          	auipc	a3,0x7
    8000212a:	aaf6a923          	sw	a5,-1358(a3) # 80008bd8 <bit>
  return lfsr =  (lfsr >> 1) | (bit << 15);
    8000212e:	0015551b          	srliw	a0,a0,0x1
    80002132:	00f7979b          	slliw	a5,a5,0xf
    80002136:	8d5d                	or	a0,a0,a5
    80002138:	1542                	slli	a0,a0,0x30
    8000213a:	9141                	srli	a0,a0,0x30
    8000213c:	00a71023          	sh	a0,0(a4)
}
    80002140:	6422                	ld	s0,8(sp)
    80002142:	0141                	addi	sp,sp,16
    80002144:	8082                	ret

0000000080002146 <min>:
uint64 min(uint64 a, uint64 b) { return ( a > b) ? b : a; }
    80002146:	1141                	addi	sp,sp,-16
    80002148:	e422                	sd	s0,8(sp)
    8000214a:	0800                	addi	s0,sp,16
    8000214c:	00a5f363          	bgeu	a1,a0,80002152 <min+0xc>
    80002150:	852e                	mv	a0,a1
    80002152:	6422                	ld	s0,8(sp)
    80002154:	0141                	addi	sp,sp,16
    80002156:	8082                	ret

0000000080002158 <max>:
uint64 max(uint64 a, uint64 b) { return ( a > b) ? a : b; }
    80002158:	1141                	addi	sp,sp,-16
    8000215a:	e422                	sd	s0,8(sp)
    8000215c:	0800                	addi	s0,sp,16
    8000215e:	87aa                	mv	a5,a0
    80002160:	852e                	mv	a0,a1
    80002162:	00f5f363          	bgeu	a1,a5,80002168 <max+0x10>
    80002166:	853e                	mv	a0,a5
    80002168:	6422                	ld	s0,8(sp)
    8000216a:	0141                	addi	sp,sp,16
    8000216c:	8082                	ret

000000008000216e <scheduler>:
{
    8000216e:	7159                	addi	sp,sp,-112
    80002170:	f486                	sd	ra,104(sp)
    80002172:	f0a2                	sd	s0,96(sp)
    80002174:	eca6                	sd	s1,88(sp)
    80002176:	e8ca                	sd	s2,80(sp)
    80002178:	e4ce                	sd	s3,72(sp)
    8000217a:	e0d2                	sd	s4,64(sp)
    8000217c:	fc56                	sd	s5,56(sp)
    8000217e:	f85a                	sd	s6,48(sp)
    80002180:	f45e                	sd	s7,40(sp)
    80002182:	f062                	sd	s8,32(sp)
    80002184:	ec66                	sd	s9,24(sp)
    80002186:	e86a                	sd	s10,16(sp)
    80002188:	e46e                	sd	s11,8(sp)
    8000218a:	1880                	addi	s0,sp,112
    8000218c:	8792                	mv	a5,tp
  int id = r_tp();
    8000218e:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002190:	00779d93          	slli	s11,a5,0x7
    80002194:	0022f717          	auipc	a4,0x22f
    80002198:	cd470713          	addi	a4,a4,-812 # 80230e68 <pid_lock>
    8000219c:	976e                	add	a4,a4,s11
    8000219e:	02073823          	sd	zero,48(a4)
      swtch(&c->context,&minproc->context);
    800021a2:	0022f717          	auipc	a4,0x22f
    800021a6:	cfe70713          	addi	a4,a4,-770 # 80230ea0 <cpus+0x8>
    800021aa:	9dba                	add	s11,s11,a4
    int changeflag=0;
    800021ac:	4c81                	li	s9,0
    int mintime = 2147483647; // int max value
    800021ae:	80000c37          	lui	s8,0x80000
    800021b2:	fffc4c13          	not	s8,s8
      if(p->state==RUNNABLE && p->start_time < mintime)
    800021b6:	498d                	li	s3,3
        changeflag=1;
    800021b8:	4b85                	li	s7,1
    for(p = proc; p < &proc[NPROC];p++)
    800021ba:	00236917          	auipc	s2,0x236
    800021be:	cde90913          	addi	s2,s2,-802 # 80237e98 <tickslock>
      c->proc=minproc;
    800021c2:	079e                	slli	a5,a5,0x7
    800021c4:	0022fd17          	auipc	s10,0x22f
    800021c8:	ca4d0d13          	addi	s10,s10,-860 # 80230e68 <pid_lock>
    800021cc:	9d3e                	add	s10,s10,a5
    800021ce:	a0a9                	j	80002218 <scheduler+0xaa>
          release(&p->lock);
    800021d0:	8526                	mv	a0,s1
    800021d2:	fffff097          	auipc	ra,0xfffff
    800021d6:	c82080e7          	jalr	-894(ra) # 80000e54 <release>
    800021da:	a805                	j	8000220a <scheduler+0x9c>
        release(&p->lock);
    800021dc:	8526                	mv	a0,s1
    800021de:	fffff097          	auipc	ra,0xfffff
    800021e2:	c76080e7          	jalr	-906(ra) # 80000e54 <release>
    for(p = proc; p < &proc[NPROC];p++)
    800021e6:	1b048493          	addi	s1,s1,432
    800021ea:	03248563          	beq	s1,s2,80002214 <scheduler+0xa6>
      acquire(&p->lock);
    800021ee:	8526                	mv	a0,s1
    800021f0:	fffff097          	auipc	ra,0xfffff
    800021f4:	bb0080e7          	jalr	-1104(ra) # 80000da0 <acquire>
      if(p->state==RUNNABLE && p->start_time < mintime)
    800021f8:	4c9c                	lw	a5,24(s1)
    800021fa:	ff3791e3          	bne	a5,s3,800021dc <scheduler+0x6e>
    800021fe:	16c4a783          	lw	a5,364(s1)
    80002202:	fd47dde3          	bge	a5,s4,800021dc <scheduler+0x6e>
        if(changeflag)
    80002206:	fc0a95e3          	bnez	s5,800021d0 <scheduler+0x62>
        mintime=p->start_time;
    8000220a:	16c4aa03          	lw	s4,364(s1)
        changeflag=1;
    8000220e:	8b26                	mv	s6,s1
    80002210:	8ade                	mv	s5,s7
    80002212:	bfd1                	j	800021e6 <scheduler+0x78>
    if(changeflag)
    80002214:	000a9f63          	bnez	s5,80002232 <scheduler+0xc4>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002218:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000221c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002220:	10079073          	csrw	sstatus,a5
    int changeflag=0;
    80002224:	8ae6                	mv	s5,s9
    int mintime = 2147483647; // int max value
    80002226:	8a62                	mv	s4,s8
    for(p = proc; p < &proc[NPROC];p++)
    80002228:	0022f497          	auipc	s1,0x22f
    8000222c:	07048493          	addi	s1,s1,112 # 80231298 <proc>
    80002230:	bf7d                	j	800021ee <scheduler+0x80>
      minproc->state=RUNNING;
    80002232:	4791                	li	a5,4
    80002234:	00fb2c23          	sw	a5,24(s6)
      c->proc=minproc;
    80002238:	036d3823          	sd	s6,48(s10)
      swtch(&c->context,&minproc->context);
    8000223c:	060b0593          	addi	a1,s6,96
    80002240:	856e                	mv	a0,s11
    80002242:	00001097          	auipc	ra,0x1
    80002246:	95c080e7          	jalr	-1700(ra) # 80002b9e <swtch>
      c->proc=0;
    8000224a:	020d3823          	sd	zero,48(s10)
      release(&minproc->lock);
    8000224e:	855a                	mv	a0,s6
    80002250:	fffff097          	auipc	ra,0xfffff
    80002254:	c04080e7          	jalr	-1020(ra) # 80000e54 <release>
    80002258:	b7c1                	j	80002218 <scheduler+0xaa>

000000008000225a <sched>:
{
    8000225a:	7179                	addi	sp,sp,-48
    8000225c:	f406                	sd	ra,40(sp)
    8000225e:	f022                	sd	s0,32(sp)
    80002260:	ec26                	sd	s1,24(sp)
    80002262:	e84a                	sd	s2,16(sp)
    80002264:	e44e                	sd	s3,8(sp)
    80002266:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002268:	00000097          	auipc	ra,0x0
    8000226c:	94c080e7          	jalr	-1716(ra) # 80001bb4 <myproc>
    80002270:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002272:	fffff097          	auipc	ra,0xfffff
    80002276:	ab4080e7          	jalr	-1356(ra) # 80000d26 <holding>
    8000227a:	c93d                	beqz	a0,800022f0 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000227c:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    8000227e:	2781                	sext.w	a5,a5
    80002280:	079e                	slli	a5,a5,0x7
    80002282:	0022f717          	auipc	a4,0x22f
    80002286:	be670713          	addi	a4,a4,-1050 # 80230e68 <pid_lock>
    8000228a:	97ba                	add	a5,a5,a4
    8000228c:	0a87a703          	lw	a4,168(a5)
    80002290:	4785                	li	a5,1
    80002292:	06f71763          	bne	a4,a5,80002300 <sched+0xa6>
  if(p->state == RUNNING)
    80002296:	4c98                	lw	a4,24(s1)
    80002298:	4791                	li	a5,4
    8000229a:	06f70b63          	beq	a4,a5,80002310 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000229e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800022a2:	8b89                	andi	a5,a5,2
  if(intr_get())
    800022a4:	efb5                	bnez	a5,80002320 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800022a6:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800022a8:	0022f917          	auipc	s2,0x22f
    800022ac:	bc090913          	addi	s2,s2,-1088 # 80230e68 <pid_lock>
    800022b0:	2781                	sext.w	a5,a5
    800022b2:	079e                	slli	a5,a5,0x7
    800022b4:	97ca                	add	a5,a5,s2
    800022b6:	0ac7a983          	lw	s3,172(a5)
    800022ba:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800022bc:	2781                	sext.w	a5,a5
    800022be:	079e                	slli	a5,a5,0x7
    800022c0:	0022f597          	auipc	a1,0x22f
    800022c4:	be058593          	addi	a1,a1,-1056 # 80230ea0 <cpus+0x8>
    800022c8:	95be                	add	a1,a1,a5
    800022ca:	06048513          	addi	a0,s1,96
    800022ce:	00001097          	auipc	ra,0x1
    800022d2:	8d0080e7          	jalr	-1840(ra) # 80002b9e <swtch>
    800022d6:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800022d8:	2781                	sext.w	a5,a5
    800022da:	079e                	slli	a5,a5,0x7
    800022dc:	993e                	add	s2,s2,a5
    800022de:	0b392623          	sw	s3,172(s2)
}
    800022e2:	70a2                	ld	ra,40(sp)
    800022e4:	7402                	ld	s0,32(sp)
    800022e6:	64e2                	ld	s1,24(sp)
    800022e8:	6942                	ld	s2,16(sp)
    800022ea:	69a2                	ld	s3,8(sp)
    800022ec:	6145                	addi	sp,sp,48
    800022ee:	8082                	ret
    panic("sched p->lock");
    800022f0:	00006517          	auipc	a0,0x6
    800022f4:	f6850513          	addi	a0,a0,-152 # 80008258 <digits+0x218>
    800022f8:	ffffe097          	auipc	ra,0xffffe
    800022fc:	248080e7          	jalr	584(ra) # 80000540 <panic>
    panic("sched locks");
    80002300:	00006517          	auipc	a0,0x6
    80002304:	f6850513          	addi	a0,a0,-152 # 80008268 <digits+0x228>
    80002308:	ffffe097          	auipc	ra,0xffffe
    8000230c:	238080e7          	jalr	568(ra) # 80000540 <panic>
    panic("sched running");
    80002310:	00006517          	auipc	a0,0x6
    80002314:	f6850513          	addi	a0,a0,-152 # 80008278 <digits+0x238>
    80002318:	ffffe097          	auipc	ra,0xffffe
    8000231c:	228080e7          	jalr	552(ra) # 80000540 <panic>
    panic("sched interruptible");
    80002320:	00006517          	auipc	a0,0x6
    80002324:	f6850513          	addi	a0,a0,-152 # 80008288 <digits+0x248>
    80002328:	ffffe097          	auipc	ra,0xffffe
    8000232c:	218080e7          	jalr	536(ra) # 80000540 <panic>

0000000080002330 <yield>:
{
    80002330:	1101                	addi	sp,sp,-32
    80002332:	ec06                	sd	ra,24(sp)
    80002334:	e822                	sd	s0,16(sp)
    80002336:	e426                	sd	s1,8(sp)
    80002338:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000233a:	00000097          	auipc	ra,0x0
    8000233e:	87a080e7          	jalr	-1926(ra) # 80001bb4 <myproc>
    80002342:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002344:	fffff097          	auipc	ra,0xfffff
    80002348:	a5c080e7          	jalr	-1444(ra) # 80000da0 <acquire>
  p->state = RUNNABLE;
    8000234c:	478d                	li	a5,3
    8000234e:	cc9c                	sw	a5,24(s1)
  sched();
    80002350:	00000097          	auipc	ra,0x0
    80002354:	f0a080e7          	jalr	-246(ra) # 8000225a <sched>
  release(&p->lock);
    80002358:	8526                	mv	a0,s1
    8000235a:	fffff097          	auipc	ra,0xfffff
    8000235e:	afa080e7          	jalr	-1286(ra) # 80000e54 <release>
}
    80002362:	60e2                	ld	ra,24(sp)
    80002364:	6442                	ld	s0,16(sp)
    80002366:	64a2                	ld	s1,8(sp)
    80002368:	6105                	addi	sp,sp,32
    8000236a:	8082                	ret

000000008000236c <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    8000236c:	7179                	addi	sp,sp,-48
    8000236e:	f406                	sd	ra,40(sp)
    80002370:	f022                	sd	s0,32(sp)
    80002372:	ec26                	sd	s1,24(sp)
    80002374:	e84a                	sd	s2,16(sp)
    80002376:	e44e                	sd	s3,8(sp)
    80002378:	1800                	addi	s0,sp,48
    8000237a:	89aa                	mv	s3,a0
    8000237c:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000237e:	00000097          	auipc	ra,0x0
    80002382:	836080e7          	jalr	-1994(ra) # 80001bb4 <myproc>
    80002386:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002388:	fffff097          	auipc	ra,0xfffff
    8000238c:	a18080e7          	jalr	-1512(ra) # 80000da0 <acquire>
  release(lk);
    80002390:	854a                	mv	a0,s2
    80002392:	fffff097          	auipc	ra,0xfffff
    80002396:	ac2080e7          	jalr	-1342(ra) # 80000e54 <release>

  // Go to sleep.
  p->chan = chan;
    8000239a:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    8000239e:	4789                	li	a5,2
    800023a0:	cc9c                	sw	a5,24(s1)

  sched();
    800023a2:	00000097          	auipc	ra,0x0
    800023a6:	eb8080e7          	jalr	-328(ra) # 8000225a <sched>

  // Tidy up.
  p->chan = 0;
    800023aa:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800023ae:	8526                	mv	a0,s1
    800023b0:	fffff097          	auipc	ra,0xfffff
    800023b4:	aa4080e7          	jalr	-1372(ra) # 80000e54 <release>
  acquire(lk);
    800023b8:	854a                	mv	a0,s2
    800023ba:	fffff097          	auipc	ra,0xfffff
    800023be:	9e6080e7          	jalr	-1562(ra) # 80000da0 <acquire>
}
    800023c2:	70a2                	ld	ra,40(sp)
    800023c4:	7402                	ld	s0,32(sp)
    800023c6:	64e2                	ld	s1,24(sp)
    800023c8:	6942                	ld	s2,16(sp)
    800023ca:	69a2                	ld	s3,8(sp)
    800023cc:	6145                	addi	sp,sp,48
    800023ce:	8082                	ret

00000000800023d0 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800023d0:	7139                	addi	sp,sp,-64
    800023d2:	fc06                	sd	ra,56(sp)
    800023d4:	f822                	sd	s0,48(sp)
    800023d6:	f426                	sd	s1,40(sp)
    800023d8:	f04a                	sd	s2,32(sp)
    800023da:	ec4e                	sd	s3,24(sp)
    800023dc:	e852                	sd	s4,16(sp)
    800023de:	e456                	sd	s5,8(sp)
    800023e0:	0080                	addi	s0,sp,64
    800023e2:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800023e4:	0022f497          	auipc	s1,0x22f
    800023e8:	eb448493          	addi	s1,s1,-332 # 80231298 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800023ec:	4989                	li	s3,2
        p->state = RUNNABLE;
    800023ee:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800023f0:	00236917          	auipc	s2,0x236
    800023f4:	aa890913          	addi	s2,s2,-1368 # 80237e98 <tickslock>
    800023f8:	a811                	j	8000240c <wakeup+0x3c>
      }
      release(&p->lock);
    800023fa:	8526                	mv	a0,s1
    800023fc:	fffff097          	auipc	ra,0xfffff
    80002400:	a58080e7          	jalr	-1448(ra) # 80000e54 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002404:	1b048493          	addi	s1,s1,432
    80002408:	03248663          	beq	s1,s2,80002434 <wakeup+0x64>
    if(p != myproc()){
    8000240c:	fffff097          	auipc	ra,0xfffff
    80002410:	7a8080e7          	jalr	1960(ra) # 80001bb4 <myproc>
    80002414:	fea488e3          	beq	s1,a0,80002404 <wakeup+0x34>
      acquire(&p->lock);
    80002418:	8526                	mv	a0,s1
    8000241a:	fffff097          	auipc	ra,0xfffff
    8000241e:	986080e7          	jalr	-1658(ra) # 80000da0 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002422:	4c9c                	lw	a5,24(s1)
    80002424:	fd379be3          	bne	a5,s3,800023fa <wakeup+0x2a>
    80002428:	709c                	ld	a5,32(s1)
    8000242a:	fd4798e3          	bne	a5,s4,800023fa <wakeup+0x2a>
        p->state = RUNNABLE;
    8000242e:	0154ac23          	sw	s5,24(s1)
    80002432:	b7e1                	j	800023fa <wakeup+0x2a>
    }
  }
}
    80002434:	70e2                	ld	ra,56(sp)
    80002436:	7442                	ld	s0,48(sp)
    80002438:	74a2                	ld	s1,40(sp)
    8000243a:	7902                	ld	s2,32(sp)
    8000243c:	69e2                	ld	s3,24(sp)
    8000243e:	6a42                	ld	s4,16(sp)
    80002440:	6aa2                	ld	s5,8(sp)
    80002442:	6121                	addi	sp,sp,64
    80002444:	8082                	ret

0000000080002446 <reparent>:
{
    80002446:	7179                	addi	sp,sp,-48
    80002448:	f406                	sd	ra,40(sp)
    8000244a:	f022                	sd	s0,32(sp)
    8000244c:	ec26                	sd	s1,24(sp)
    8000244e:	e84a                	sd	s2,16(sp)
    80002450:	e44e                	sd	s3,8(sp)
    80002452:	e052                	sd	s4,0(sp)
    80002454:	1800                	addi	s0,sp,48
    80002456:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002458:	0022f497          	auipc	s1,0x22f
    8000245c:	e4048493          	addi	s1,s1,-448 # 80231298 <proc>
      pp->parent = initproc;
    80002460:	00006a17          	auipc	s4,0x6
    80002464:	780a0a13          	addi	s4,s4,1920 # 80008be0 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002468:	00236997          	auipc	s3,0x236
    8000246c:	a3098993          	addi	s3,s3,-1488 # 80237e98 <tickslock>
    80002470:	a029                	j	8000247a <reparent+0x34>
    80002472:	1b048493          	addi	s1,s1,432
    80002476:	01348d63          	beq	s1,s3,80002490 <reparent+0x4a>
    if(pp->parent == p){
    8000247a:	7c9c                	ld	a5,56(s1)
    8000247c:	ff279be3          	bne	a5,s2,80002472 <reparent+0x2c>
      pp->parent = initproc;
    80002480:	000a3503          	ld	a0,0(s4)
    80002484:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002486:	00000097          	auipc	ra,0x0
    8000248a:	f4a080e7          	jalr	-182(ra) # 800023d0 <wakeup>
    8000248e:	b7d5                	j	80002472 <reparent+0x2c>
}
    80002490:	70a2                	ld	ra,40(sp)
    80002492:	7402                	ld	s0,32(sp)
    80002494:	64e2                	ld	s1,24(sp)
    80002496:	6942                	ld	s2,16(sp)
    80002498:	69a2                	ld	s3,8(sp)
    8000249a:	6a02                	ld	s4,0(sp)
    8000249c:	6145                	addi	sp,sp,48
    8000249e:	8082                	ret

00000000800024a0 <exit>:
{
    800024a0:	7179                	addi	sp,sp,-48
    800024a2:	f406                	sd	ra,40(sp)
    800024a4:	f022                	sd	s0,32(sp)
    800024a6:	ec26                	sd	s1,24(sp)
    800024a8:	e84a                	sd	s2,16(sp)
    800024aa:	e44e                	sd	s3,8(sp)
    800024ac:	e052                	sd	s4,0(sp)
    800024ae:	1800                	addi	s0,sp,48
    800024b0:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800024b2:	fffff097          	auipc	ra,0xfffff
    800024b6:	702080e7          	jalr	1794(ra) # 80001bb4 <myproc>
    800024ba:	89aa                	mv	s3,a0
  if(p == initproc)
    800024bc:	00006797          	auipc	a5,0x6
    800024c0:	7247b783          	ld	a5,1828(a5) # 80008be0 <initproc>
    800024c4:	0d050493          	addi	s1,a0,208
    800024c8:	15050913          	addi	s2,a0,336
    800024cc:	02a79363          	bne	a5,a0,800024f2 <exit+0x52>
    panic("init exiting");
    800024d0:	00006517          	auipc	a0,0x6
    800024d4:	dd050513          	addi	a0,a0,-560 # 800082a0 <digits+0x260>
    800024d8:	ffffe097          	auipc	ra,0xffffe
    800024dc:	068080e7          	jalr	104(ra) # 80000540 <panic>
      fileclose(f);
    800024e0:	00003097          	auipc	ra,0x3
    800024e4:	a02080e7          	jalr	-1534(ra) # 80004ee2 <fileclose>
      p->ofile[fd] = 0;
    800024e8:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800024ec:	04a1                	addi	s1,s1,8
    800024ee:	01248563          	beq	s1,s2,800024f8 <exit+0x58>
    if(p->ofile[fd]){
    800024f2:	6088                	ld	a0,0(s1)
    800024f4:	f575                	bnez	a0,800024e0 <exit+0x40>
    800024f6:	bfdd                	j	800024ec <exit+0x4c>
  begin_op();
    800024f8:	00002097          	auipc	ra,0x2
    800024fc:	522080e7          	jalr	1314(ra) # 80004a1a <begin_op>
  iput(p->cwd);
    80002500:	1509b503          	ld	a0,336(s3)
    80002504:	00002097          	auipc	ra,0x2
    80002508:	d04080e7          	jalr	-764(ra) # 80004208 <iput>
  end_op();
    8000250c:	00002097          	auipc	ra,0x2
    80002510:	58c080e7          	jalr	1420(ra) # 80004a98 <end_op>
  p->cwd = 0;
    80002514:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002518:	0022f497          	auipc	s1,0x22f
    8000251c:	96848493          	addi	s1,s1,-1688 # 80230e80 <wait_lock>
    80002520:	8526                	mv	a0,s1
    80002522:	fffff097          	auipc	ra,0xfffff
    80002526:	87e080e7          	jalr	-1922(ra) # 80000da0 <acquire>
  reparent(p);
    8000252a:	854e                	mv	a0,s3
    8000252c:	00000097          	auipc	ra,0x0
    80002530:	f1a080e7          	jalr	-230(ra) # 80002446 <reparent>
  wakeup(p->parent);
    80002534:	0389b503          	ld	a0,56(s3)
    80002538:	00000097          	auipc	ra,0x0
    8000253c:	e98080e7          	jalr	-360(ra) # 800023d0 <wakeup>
  acquire(&p->lock);
    80002540:	854e                	mv	a0,s3
    80002542:	fffff097          	auipc	ra,0xfffff
    80002546:	85e080e7          	jalr	-1954(ra) # 80000da0 <acquire>
  p->xstate = status;
    8000254a:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    8000254e:	4795                	li	a5,5
    80002550:	00f9ac23          	sw	a5,24(s3)
  p->etime=ticks;
    80002554:	00006797          	auipc	a5,0x6
    80002558:	6947a783          	lw	a5,1684(a5) # 80008be8 <ticks>
    8000255c:	18f9ac23          	sw	a5,408(s3)
  release(&wait_lock);
    80002560:	8526                	mv	a0,s1
    80002562:	fffff097          	auipc	ra,0xfffff
    80002566:	8f2080e7          	jalr	-1806(ra) # 80000e54 <release>
  sched();
    8000256a:	00000097          	auipc	ra,0x0
    8000256e:	cf0080e7          	jalr	-784(ra) # 8000225a <sched>
  panic("zombie exit");
    80002572:	00006517          	auipc	a0,0x6
    80002576:	d3e50513          	addi	a0,a0,-706 # 800082b0 <digits+0x270>
    8000257a:	ffffe097          	auipc	ra,0xffffe
    8000257e:	fc6080e7          	jalr	-58(ra) # 80000540 <panic>

0000000080002582 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002582:	7179                	addi	sp,sp,-48
    80002584:	f406                	sd	ra,40(sp)
    80002586:	f022                	sd	s0,32(sp)
    80002588:	ec26                	sd	s1,24(sp)
    8000258a:	e84a                	sd	s2,16(sp)
    8000258c:	e44e                	sd	s3,8(sp)
    8000258e:	1800                	addi	s0,sp,48
    80002590:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002592:	0022f497          	auipc	s1,0x22f
    80002596:	d0648493          	addi	s1,s1,-762 # 80231298 <proc>
    8000259a:	00236997          	auipc	s3,0x236
    8000259e:	8fe98993          	addi	s3,s3,-1794 # 80237e98 <tickslock>
    acquire(&p->lock);
    800025a2:	8526                	mv	a0,s1
    800025a4:	ffffe097          	auipc	ra,0xffffe
    800025a8:	7fc080e7          	jalr	2044(ra) # 80000da0 <acquire>
    if(p->pid == pid){
    800025ac:	589c                	lw	a5,48(s1)
    800025ae:	01278d63          	beq	a5,s2,800025c8 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800025b2:	8526                	mv	a0,s1
    800025b4:	fffff097          	auipc	ra,0xfffff
    800025b8:	8a0080e7          	jalr	-1888(ra) # 80000e54 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800025bc:	1b048493          	addi	s1,s1,432
    800025c0:	ff3491e3          	bne	s1,s3,800025a2 <kill+0x20>
  }
  return -1;
    800025c4:	557d                	li	a0,-1
    800025c6:	a829                	j	800025e0 <kill+0x5e>
      p->killed = 1;
    800025c8:	4785                	li	a5,1
    800025ca:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800025cc:	4c98                	lw	a4,24(s1)
    800025ce:	4789                	li	a5,2
    800025d0:	00f70f63          	beq	a4,a5,800025ee <kill+0x6c>
      release(&p->lock);
    800025d4:	8526                	mv	a0,s1
    800025d6:	fffff097          	auipc	ra,0xfffff
    800025da:	87e080e7          	jalr	-1922(ra) # 80000e54 <release>
      return 0;
    800025de:	4501                	li	a0,0
}
    800025e0:	70a2                	ld	ra,40(sp)
    800025e2:	7402                	ld	s0,32(sp)
    800025e4:	64e2                	ld	s1,24(sp)
    800025e6:	6942                	ld	s2,16(sp)
    800025e8:	69a2                	ld	s3,8(sp)
    800025ea:	6145                	addi	sp,sp,48
    800025ec:	8082                	ret
        p->state = RUNNABLE;
    800025ee:	478d                	li	a5,3
    800025f0:	cc9c                	sw	a5,24(s1)
    800025f2:	b7cd                	j	800025d4 <kill+0x52>

00000000800025f4 <setkilled>:

void
setkilled(struct proc *p)
{
    800025f4:	1101                	addi	sp,sp,-32
    800025f6:	ec06                	sd	ra,24(sp)
    800025f8:	e822                	sd	s0,16(sp)
    800025fa:	e426                	sd	s1,8(sp)
    800025fc:	1000                	addi	s0,sp,32
    800025fe:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002600:	ffffe097          	auipc	ra,0xffffe
    80002604:	7a0080e7          	jalr	1952(ra) # 80000da0 <acquire>
  p->killed = 1;
    80002608:	4785                	li	a5,1
    8000260a:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    8000260c:	8526                	mv	a0,s1
    8000260e:	fffff097          	auipc	ra,0xfffff
    80002612:	846080e7          	jalr	-1978(ra) # 80000e54 <release>
}
    80002616:	60e2                	ld	ra,24(sp)
    80002618:	6442                	ld	s0,16(sp)
    8000261a:	64a2                	ld	s1,8(sp)
    8000261c:	6105                	addi	sp,sp,32
    8000261e:	8082                	ret

0000000080002620 <killed>:

int
killed(struct proc *p)
{
    80002620:	1101                	addi	sp,sp,-32
    80002622:	ec06                	sd	ra,24(sp)
    80002624:	e822                	sd	s0,16(sp)
    80002626:	e426                	sd	s1,8(sp)
    80002628:	e04a                	sd	s2,0(sp)
    8000262a:	1000                	addi	s0,sp,32
    8000262c:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    8000262e:	ffffe097          	auipc	ra,0xffffe
    80002632:	772080e7          	jalr	1906(ra) # 80000da0 <acquire>
  k = p->killed;
    80002636:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    8000263a:	8526                	mv	a0,s1
    8000263c:	fffff097          	auipc	ra,0xfffff
    80002640:	818080e7          	jalr	-2024(ra) # 80000e54 <release>
  return k;
}
    80002644:	854a                	mv	a0,s2
    80002646:	60e2                	ld	ra,24(sp)
    80002648:	6442                	ld	s0,16(sp)
    8000264a:	64a2                	ld	s1,8(sp)
    8000264c:	6902                	ld	s2,0(sp)
    8000264e:	6105                	addi	sp,sp,32
    80002650:	8082                	ret

0000000080002652 <wait>:
{
    80002652:	715d                	addi	sp,sp,-80
    80002654:	e486                	sd	ra,72(sp)
    80002656:	e0a2                	sd	s0,64(sp)
    80002658:	fc26                	sd	s1,56(sp)
    8000265a:	f84a                	sd	s2,48(sp)
    8000265c:	f44e                	sd	s3,40(sp)
    8000265e:	f052                	sd	s4,32(sp)
    80002660:	ec56                	sd	s5,24(sp)
    80002662:	e85a                	sd	s6,16(sp)
    80002664:	e45e                	sd	s7,8(sp)
    80002666:	e062                	sd	s8,0(sp)
    80002668:	0880                	addi	s0,sp,80
    8000266a:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000266c:	fffff097          	auipc	ra,0xfffff
    80002670:	548080e7          	jalr	1352(ra) # 80001bb4 <myproc>
    80002674:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002676:	0022f517          	auipc	a0,0x22f
    8000267a:	80a50513          	addi	a0,a0,-2038 # 80230e80 <wait_lock>
    8000267e:	ffffe097          	auipc	ra,0xffffe
    80002682:	722080e7          	jalr	1826(ra) # 80000da0 <acquire>
    havekids = 0;
    80002686:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    80002688:	4a15                	li	s4,5
        havekids = 1;
    8000268a:	4a85                	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000268c:	00236997          	auipc	s3,0x236
    80002690:	80c98993          	addi	s3,s3,-2036 # 80237e98 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002694:	0022ec17          	auipc	s8,0x22e
    80002698:	7ecc0c13          	addi	s8,s8,2028 # 80230e80 <wait_lock>
    havekids = 0;
    8000269c:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000269e:	0022f497          	auipc	s1,0x22f
    800026a2:	bfa48493          	addi	s1,s1,-1030 # 80231298 <proc>
    800026a6:	a0bd                	j	80002714 <wait+0xc2>
          pid = pp->pid;
    800026a8:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    800026ac:	000b0e63          	beqz	s6,800026c8 <wait+0x76>
    800026b0:	4691                	li	a3,4
    800026b2:	02c48613          	addi	a2,s1,44
    800026b6:	85da                	mv	a1,s6
    800026b8:	05093503          	ld	a0,80(s2)
    800026bc:	fffff097          	auipc	ra,0xfffff
    800026c0:	180080e7          	jalr	384(ra) # 8000183c <copyout>
    800026c4:	02054563          	bltz	a0,800026ee <wait+0x9c>
          freeproc(pp);
    800026c8:	8526                	mv	a0,s1
    800026ca:	fffff097          	auipc	ra,0xfffff
    800026ce:	69c080e7          	jalr	1692(ra) # 80001d66 <freeproc>
          release(&pp->lock);
    800026d2:	8526                	mv	a0,s1
    800026d4:	ffffe097          	auipc	ra,0xffffe
    800026d8:	780080e7          	jalr	1920(ra) # 80000e54 <release>
          release(&wait_lock);
    800026dc:	0022e517          	auipc	a0,0x22e
    800026e0:	7a450513          	addi	a0,a0,1956 # 80230e80 <wait_lock>
    800026e4:	ffffe097          	auipc	ra,0xffffe
    800026e8:	770080e7          	jalr	1904(ra) # 80000e54 <release>
          return pid;
    800026ec:	a0b5                	j	80002758 <wait+0x106>
            release(&pp->lock);
    800026ee:	8526                	mv	a0,s1
    800026f0:	ffffe097          	auipc	ra,0xffffe
    800026f4:	764080e7          	jalr	1892(ra) # 80000e54 <release>
            release(&wait_lock);
    800026f8:	0022e517          	auipc	a0,0x22e
    800026fc:	78850513          	addi	a0,a0,1928 # 80230e80 <wait_lock>
    80002700:	ffffe097          	auipc	ra,0xffffe
    80002704:	754080e7          	jalr	1876(ra) # 80000e54 <release>
            return -1;
    80002708:	59fd                	li	s3,-1
    8000270a:	a0b9                	j	80002758 <wait+0x106>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000270c:	1b048493          	addi	s1,s1,432
    80002710:	03348463          	beq	s1,s3,80002738 <wait+0xe6>
      if(pp->parent == p){
    80002714:	7c9c                	ld	a5,56(s1)
    80002716:	ff279be3          	bne	a5,s2,8000270c <wait+0xba>
        acquire(&pp->lock);
    8000271a:	8526                	mv	a0,s1
    8000271c:	ffffe097          	auipc	ra,0xffffe
    80002720:	684080e7          	jalr	1668(ra) # 80000da0 <acquire>
        if(pp->state == ZOMBIE){
    80002724:	4c9c                	lw	a5,24(s1)
    80002726:	f94781e3          	beq	a5,s4,800026a8 <wait+0x56>
        release(&pp->lock);
    8000272a:	8526                	mv	a0,s1
    8000272c:	ffffe097          	auipc	ra,0xffffe
    80002730:	728080e7          	jalr	1832(ra) # 80000e54 <release>
        havekids = 1;
    80002734:	8756                	mv	a4,s5
    80002736:	bfd9                	j	8000270c <wait+0xba>
    if(!havekids || killed(p)){
    80002738:	c719                	beqz	a4,80002746 <wait+0xf4>
    8000273a:	854a                	mv	a0,s2
    8000273c:	00000097          	auipc	ra,0x0
    80002740:	ee4080e7          	jalr	-284(ra) # 80002620 <killed>
    80002744:	c51d                	beqz	a0,80002772 <wait+0x120>
      release(&wait_lock);
    80002746:	0022e517          	auipc	a0,0x22e
    8000274a:	73a50513          	addi	a0,a0,1850 # 80230e80 <wait_lock>
    8000274e:	ffffe097          	auipc	ra,0xffffe
    80002752:	706080e7          	jalr	1798(ra) # 80000e54 <release>
      return -1;
    80002756:	59fd                	li	s3,-1
}
    80002758:	854e                	mv	a0,s3
    8000275a:	60a6                	ld	ra,72(sp)
    8000275c:	6406                	ld	s0,64(sp)
    8000275e:	74e2                	ld	s1,56(sp)
    80002760:	7942                	ld	s2,48(sp)
    80002762:	79a2                	ld	s3,40(sp)
    80002764:	7a02                	ld	s4,32(sp)
    80002766:	6ae2                	ld	s5,24(sp)
    80002768:	6b42                	ld	s6,16(sp)
    8000276a:	6ba2                	ld	s7,8(sp)
    8000276c:	6c02                	ld	s8,0(sp)
    8000276e:	6161                	addi	sp,sp,80
    80002770:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002772:	85e2                	mv	a1,s8
    80002774:	854a                	mv	a0,s2
    80002776:	00000097          	auipc	ra,0x0
    8000277a:	bf6080e7          	jalr	-1034(ra) # 8000236c <sleep>
    havekids = 0;
    8000277e:	bf39                	j	8000269c <wait+0x4a>

0000000080002780 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002780:	7179                	addi	sp,sp,-48
    80002782:	f406                	sd	ra,40(sp)
    80002784:	f022                	sd	s0,32(sp)
    80002786:	ec26                	sd	s1,24(sp)
    80002788:	e84a                	sd	s2,16(sp)
    8000278a:	e44e                	sd	s3,8(sp)
    8000278c:	e052                	sd	s4,0(sp)
    8000278e:	1800                	addi	s0,sp,48
    80002790:	84aa                	mv	s1,a0
    80002792:	892e                	mv	s2,a1
    80002794:	89b2                	mv	s3,a2
    80002796:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002798:	fffff097          	auipc	ra,0xfffff
    8000279c:	41c080e7          	jalr	1052(ra) # 80001bb4 <myproc>
  if(user_dst){
    800027a0:	c08d                	beqz	s1,800027c2 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800027a2:	86d2                	mv	a3,s4
    800027a4:	864e                	mv	a2,s3
    800027a6:	85ca                	mv	a1,s2
    800027a8:	6928                	ld	a0,80(a0)
    800027aa:	fffff097          	auipc	ra,0xfffff
    800027ae:	092080e7          	jalr	146(ra) # 8000183c <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800027b2:	70a2                	ld	ra,40(sp)
    800027b4:	7402                	ld	s0,32(sp)
    800027b6:	64e2                	ld	s1,24(sp)
    800027b8:	6942                	ld	s2,16(sp)
    800027ba:	69a2                	ld	s3,8(sp)
    800027bc:	6a02                	ld	s4,0(sp)
    800027be:	6145                	addi	sp,sp,48
    800027c0:	8082                	ret
    memmove((char *)dst, src, len);
    800027c2:	000a061b          	sext.w	a2,s4
    800027c6:	85ce                	mv	a1,s3
    800027c8:	854a                	mv	a0,s2
    800027ca:	ffffe097          	auipc	ra,0xffffe
    800027ce:	72e080e7          	jalr	1838(ra) # 80000ef8 <memmove>
    return 0;
    800027d2:	8526                	mv	a0,s1
    800027d4:	bff9                	j	800027b2 <either_copyout+0x32>

00000000800027d6 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800027d6:	7179                	addi	sp,sp,-48
    800027d8:	f406                	sd	ra,40(sp)
    800027da:	f022                	sd	s0,32(sp)
    800027dc:	ec26                	sd	s1,24(sp)
    800027de:	e84a                	sd	s2,16(sp)
    800027e0:	e44e                	sd	s3,8(sp)
    800027e2:	e052                	sd	s4,0(sp)
    800027e4:	1800                	addi	s0,sp,48
    800027e6:	892a                	mv	s2,a0
    800027e8:	84ae                	mv	s1,a1
    800027ea:	89b2                	mv	s3,a2
    800027ec:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800027ee:	fffff097          	auipc	ra,0xfffff
    800027f2:	3c6080e7          	jalr	966(ra) # 80001bb4 <myproc>
  if(user_src){
    800027f6:	c08d                	beqz	s1,80002818 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800027f8:	86d2                	mv	a3,s4
    800027fa:	864e                	mv	a2,s3
    800027fc:	85ca                	mv	a1,s2
    800027fe:	6928                	ld	a0,80(a0)
    80002800:	fffff097          	auipc	ra,0xfffff
    80002804:	100080e7          	jalr	256(ra) # 80001900 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002808:	70a2                	ld	ra,40(sp)
    8000280a:	7402                	ld	s0,32(sp)
    8000280c:	64e2                	ld	s1,24(sp)
    8000280e:	6942                	ld	s2,16(sp)
    80002810:	69a2                	ld	s3,8(sp)
    80002812:	6a02                	ld	s4,0(sp)
    80002814:	6145                	addi	sp,sp,48
    80002816:	8082                	ret
    memmove(dst, (char*)src, len);
    80002818:	000a061b          	sext.w	a2,s4
    8000281c:	85ce                	mv	a1,s3
    8000281e:	854a                	mv	a0,s2
    80002820:	ffffe097          	auipc	ra,0xffffe
    80002824:	6d8080e7          	jalr	1752(ra) # 80000ef8 <memmove>
    return 0;
    80002828:	8526                	mv	a0,s1
    8000282a:	bff9                	j	80002808 <either_copyin+0x32>

000000008000282c <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    8000282c:	715d                	addi	sp,sp,-80
    8000282e:	e486                	sd	ra,72(sp)
    80002830:	e0a2                	sd	s0,64(sp)
    80002832:	fc26                	sd	s1,56(sp)
    80002834:	f84a                	sd	s2,48(sp)
    80002836:	f44e                	sd	s3,40(sp)
    80002838:	f052                	sd	s4,32(sp)
    8000283a:	ec56                	sd	s5,24(sp)
    8000283c:	e85a                	sd	s6,16(sp)
    8000283e:	e45e                	sd	s7,8(sp)
    80002840:	e062                	sd	s8,0(sp)
    80002842:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    80002844:	00006517          	auipc	a0,0x6
    80002848:	8c450513          	addi	a0,a0,-1852 # 80008108 <digits+0xc8>
    8000284c:	ffffe097          	auipc	ra,0xffffe
    80002850:	d3e080e7          	jalr	-706(ra) # 8000058a <printf>
#endif
#ifdef MLFQ
  printf("PID   Priority\tState\t  rtime\t wtime\tnrun\n\tq0\tq1\tq2\tq3\tq4");
#endif
#ifdef FCFS
  printf("PID   State\t  rtime\t wtime\tnrun\n");
    80002854:	00006517          	auipc	a0,0x6
    80002858:	a7450513          	addi	a0,a0,-1420 # 800082c8 <digits+0x288>
    8000285c:	ffffe097          	auipc	ra,0xffffe
    80002860:	d2e080e7          	jalr	-722(ra) # 8000058a <printf>
#endif
#ifdef RR
  printf("PID   State\t  rtime\t wtime\tnrun\n");
#endif

  for (p = proc; p < &proc[NPROC]; p++)
    80002864:	0022f497          	auipc	s1,0x22f
    80002868:	a3448493          	addi	s1,s1,-1484 # 80231298 <proc>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000286c:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    8000286e:	00006997          	auipc	s3,0x6
    80002872:	a5298993          	addi	s3,s3,-1454 # 800082c0 <digits+0x280>

#ifdef PBS
    printf("PBS %d\t%d\t%s    %d\t  %d\t%d", p->pid, p->spriority, state, p->rtime, time, p->calls);
#endif
#ifdef FCFS
    printf("FCFS %d\t%s    %d\t  %d\t%d", p->pid, state, p->rtime, time, p->calls);
    80002876:	00006a97          	auipc	s5,0x6
    8000287a:	a7aa8a93          	addi	s5,s5,-1414 # 800082f0 <digits+0x2b0>
#ifdef LBS
  state=NULL;
  time =0;
  printf("lmao LBS %d %s\n",state,time);
#endif
    printf("\n");
    8000287e:	00006a17          	auipc	s4,0x6
    80002882:	88aa0a13          	addi	s4,s4,-1910 # 80008108 <digits+0xc8>
      time = ticks - (p->start_time + p->rtime);
    80002886:	00006c17          	auipc	s8,0x6
    8000288a:	362c0c13          	addi	s8,s8,866 # 80008be8 <ticks>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000288e:	00006b97          	auipc	s7,0x6
    80002892:	ab2b8b93          	addi	s7,s7,-1358 # 80008340 <states.0>
  for (p = proc; p < &proc[NPROC]; p++)
    80002896:	00235917          	auipc	s2,0x235
    8000289a:	60290913          	addi	s2,s2,1538 # 80237e98 <tickslock>
    8000289e:	a82d                	j	800028d8 <procdump+0xac>
    if (p->etime)
    800028a0:	1984a703          	lw	a4,408(s1)
    800028a4:	cb21                	beqz	a4,800028f4 <procdump+0xc8>
      time = p->etime - (p->start_time + p->rtime);
    800028a6:	16c4a683          	lw	a3,364(s1)
    800028aa:	1a04a783          	lw	a5,416(s1)
    800028ae:	9fb5                	addw	a5,a5,a3
    800028b0:	9f1d                	subw	a4,a4,a5
    printf("FCFS %d\t%s    %d\t  %d\t%d", p->pid, state, p->rtime, time, p->calls);
    800028b2:	1ac4a783          	lw	a5,428(s1)
    800028b6:	1a04a683          	lw	a3,416(s1)
    800028ba:	588c                	lw	a1,48(s1)
    800028bc:	8556                	mv	a0,s5
    800028be:	ffffe097          	auipc	ra,0xffffe
    800028c2:	ccc080e7          	jalr	-820(ra) # 8000058a <printf>
    printf("\n");
    800028c6:	8552                	mv	a0,s4
    800028c8:	ffffe097          	auipc	ra,0xffffe
    800028cc:	cc2080e7          	jalr	-830(ra) # 8000058a <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    800028d0:	1b048493          	addi	s1,s1,432
    800028d4:	03248963          	beq	s1,s2,80002906 <procdump+0xda>
    if (p->state == UNUSED)
    800028d8:	4c9c                	lw	a5,24(s1)
    800028da:	dbfd                	beqz	a5,800028d0 <procdump+0xa4>
      state = "???";
    800028dc:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028de:	fcfb61e3          	bltu	s6,a5,800028a0 <procdump+0x74>
    800028e2:	02079713          	slli	a4,a5,0x20
    800028e6:	01d75793          	srli	a5,a4,0x1d
    800028ea:	97de                	add	a5,a5,s7
    800028ec:	6390                	ld	a2,0(a5)
    800028ee:	fa4d                	bnez	a2,800028a0 <procdump+0x74>
      state = "???";
    800028f0:	864e                	mv	a2,s3
    800028f2:	b77d                	j	800028a0 <procdump+0x74>
      time = ticks - (p->start_time + p->rtime);
    800028f4:	16c4a703          	lw	a4,364(s1)
    800028f8:	1a04a783          	lw	a5,416(s1)
    800028fc:	9fb9                	addw	a5,a5,a4
    800028fe:	000c2703          	lw	a4,0(s8)
    80002902:	9f1d                	subw	a4,a4,a5
    80002904:	b77d                	j	800028b2 <procdump+0x86>
  }
}
    80002906:	60a6                	ld	ra,72(sp)
    80002908:	6406                	ld	s0,64(sp)
    8000290a:	74e2                	ld	s1,56(sp)
    8000290c:	7942                	ld	s2,48(sp)
    8000290e:	79a2                	ld	s3,40(sp)
    80002910:	7a02                	ld	s4,32(sp)
    80002912:	6ae2                	ld	s5,24(sp)
    80002914:	6b42                	ld	s6,16(sp)
    80002916:	6ba2                	ld	s7,8(sp)
    80002918:	6c02                	ld	s8,0(sp)
    8000291a:	6161                	addi	sp,sp,80
    8000291c:	8082                	ret

000000008000291e <set_spriority>:

int 
set_spriority(int priority,int pid)
{
    8000291e:	7139                	addi	sp,sp,-64
    80002920:	fc06                	sd	ra,56(sp)
    80002922:	f822                	sd	s0,48(sp)
    80002924:	f426                	sd	s1,40(sp)
    80002926:	f04a                	sd	s2,32(sp)
    80002928:	ec4e                	sd	s3,24(sp)
    8000292a:	e852                	sd	s4,16(sp)
    8000292c:	e456                	sd	s5,8(sp)
    8000292e:	0080                	addi	s0,sp,64
    80002930:	8a2a                	mv	s4,a0
    80002932:	892e                	mv	s2,a1
  struct proc *p;
  for(p=proc;p<&proc[NPROC];p++)
    80002934:	0022f497          	auipc	s1,0x22f
    80002938:	96448493          	addi	s1,s1,-1692 # 80231298 <proc>
    8000293c:	00235997          	auipc	s3,0x235
    80002940:	55c98993          	addi	s3,s3,1372 # 80237e98 <tickslock>
  {
    if(myproc()==p)
    80002944:	fffff097          	auipc	ra,0xfffff
    80002948:	270080e7          	jalr	624(ra) # 80001bb4 <myproc>
    8000294c:	02a49d63          	bne	s1,a0,80002986 <set_spriority+0x68>
    {
      if(pid ==p->pid)
    80002950:	589c                	lw	a5,48(s1)
    80002952:	01278863          	beq	a5,s2,80002962 <set_spriority+0x44>
  for(p=proc;p<&proc[NPROC];p++)
    80002956:	1b048493          	addi	s1,s1,432
    8000295a:	ff3495e3          	bne	s1,s3,80002944 <set_spriority+0x26>
      if(priority < old)
        yield();
      return old;
    }
  }
  return 0;
    8000295e:	4981                	li	s3,0
    80002960:	a0a9                	j	800029aa <set_spriority+0x8c>
        int old=p->spriority;
    80002962:	1a44a983          	lw	s3,420(s1)
        p->nice=5;
    80002966:	4795                	li	a5,5
    80002968:	1af4a423          	sw	a5,424(s1)
        p->rtime=0;
    8000296c:	1a04a023          	sw	zero,416(s1)
        p->stime=0;
    80002970:	1804ae23          	sw	zero,412(s1)
        p->spriority=priority;
    80002974:	1b44a223          	sw	s4,420(s1)
        if(priority < old)
    80002978:	033a5963          	bge	s4,s3,800029aa <set_spriority+0x8c>
          yield();
    8000297c:	00000097          	auipc	ra,0x0
    80002980:	9b4080e7          	jalr	-1612(ra) # 80002330 <yield>
    80002984:	a01d                	j	800029aa <set_spriority+0x8c>
      int old=p->spriority;
    80002986:	1a44a983          	lw	s3,420(s1)
      acquire(&p->lock);
    8000298a:	8aa6                	mv	s5,s1
    8000298c:	8526                	mv	a0,s1
    8000298e:	ffffe097          	auipc	ra,0xffffe
    80002992:	412080e7          	jalr	1042(ra) # 80000da0 <acquire>
      if(pid == p->pid)
    80002996:	589c                	lw	a5,48(s1)
    80002998:	03278363          	beq	a5,s2,800029be <set_spriority+0xa0>
      release(&p->lock);
    8000299c:	8556                	mv	a0,s5
    8000299e:	ffffe097          	auipc	ra,0xffffe
    800029a2:	4b6080e7          	jalr	1206(ra) # 80000e54 <release>
      if(priority < old)
    800029a6:	033a4663          	blt	s4,s3,800029d2 <set_spriority+0xb4>
}
    800029aa:	854e                	mv	a0,s3
    800029ac:	70e2                	ld	ra,56(sp)
    800029ae:	7442                	ld	s0,48(sp)
    800029b0:	74a2                	ld	s1,40(sp)
    800029b2:	7902                	ld	s2,32(sp)
    800029b4:	69e2                	ld	s3,24(sp)
    800029b6:	6a42                	ld	s4,16(sp)
    800029b8:	6aa2                	ld	s5,8(sp)
    800029ba:	6121                	addi	sp,sp,64
    800029bc:	8082                	ret
        p->nice=5;
    800029be:	4795                	li	a5,5
    800029c0:	1af4a423          	sw	a5,424(s1)
        p->rtime=0;
    800029c4:	1a04a023          	sw	zero,416(s1)
        p->stime=0;
    800029c8:	1804ae23          	sw	zero,412(s1)
        p->spriority=priority;
    800029cc:	1b44a223          	sw	s4,420(s1)
    800029d0:	b7f1                	j	8000299c <set_spriority+0x7e>
        yield();
    800029d2:	00000097          	auipc	ra,0x0
    800029d6:	95e080e7          	jalr	-1698(ra) # 80002330 <yield>
    800029da:	bfc1                	j	800029aa <set_spriority+0x8c>

00000000800029dc <update_time>:

void 
update_time()
{
    800029dc:	7179                	addi	sp,sp,-48
    800029de:	f406                	sd	ra,40(sp)
    800029e0:	f022                	sd	s0,32(sp)
    800029e2:	ec26                	sd	s1,24(sp)
    800029e4:	e84a                	sd	s2,16(sp)
    800029e6:	e44e                	sd	s3,8(sp)
    800029e8:	e052                	sd	s4,0(sp)
    800029ea:	1800                	addi	s0,sp,48
  struct proc *p;
  for(p=proc;p<&proc[NPROC];p++)
    800029ec:	0022f497          	auipc	s1,0x22f
    800029f0:	8ac48493          	addi	s1,s1,-1876 # 80231298 <proc>
  {
    acquire(&p->lock);
    if(p->state==RUNNING)
    800029f4:	4991                	li	s3,4
    {
      p->rtime++;
    }
    if(p->state==SLEEPING)
    800029f6:	4a09                	li	s4,2
  for(p=proc;p<&proc[NPROC];p++)
    800029f8:	00235917          	auipc	s2,0x235
    800029fc:	4a090913          	addi	s2,s2,1184 # 80237e98 <tickslock>
    80002a00:	a839                	j	80002a1e <update_time+0x42>
      p->rtime++;
    80002a02:	1a04a783          	lw	a5,416(s1)
    80002a06:	2785                	addiw	a5,a5,1
    80002a08:	1af4a023          	sw	a5,416(s1)
    {
      p->stime++;
    }
    release(&p->lock);
    80002a0c:	8526                	mv	a0,s1
    80002a0e:	ffffe097          	auipc	ra,0xffffe
    80002a12:	446080e7          	jalr	1094(ra) # 80000e54 <release>
  for(p=proc;p<&proc[NPROC];p++)
    80002a16:	1b048493          	addi	s1,s1,432
    80002a1a:	03248263          	beq	s1,s2,80002a3e <update_time+0x62>
    acquire(&p->lock);
    80002a1e:	8526                	mv	a0,s1
    80002a20:	ffffe097          	auipc	ra,0xffffe
    80002a24:	380080e7          	jalr	896(ra) # 80000da0 <acquire>
    if(p->state==RUNNING)
    80002a28:	4c9c                	lw	a5,24(s1)
    80002a2a:	fd378ce3          	beq	a5,s3,80002a02 <update_time+0x26>
    if(p->state==SLEEPING)
    80002a2e:	fd479fe3          	bne	a5,s4,80002a0c <update_time+0x30>
      p->stime++;
    80002a32:	19c4a783          	lw	a5,412(s1)
    80002a36:	2785                	addiw	a5,a5,1
    80002a38:	18f4ae23          	sw	a5,412(s1)
    80002a3c:	bfc1                	j	80002a0c <update_time+0x30>
  }
}
    80002a3e:	70a2                	ld	ra,40(sp)
    80002a40:	7402                	ld	s0,32(sp)
    80002a42:	64e2                	ld	s1,24(sp)
    80002a44:	6942                	ld	s2,16(sp)
    80002a46:	69a2                	ld	s3,8(sp)
    80002a48:	6a02                	ld	s4,0(sp)
    80002a4a:	6145                	addi	sp,sp,48
    80002a4c:	8082                	ret

0000000080002a4e <waitx>:

int
waitx(uint64 addr, uint* wtime, uint* rtime)
{
    80002a4e:	711d                	addi	sp,sp,-96
    80002a50:	ec86                	sd	ra,88(sp)
    80002a52:	e8a2                	sd	s0,80(sp)
    80002a54:	e4a6                	sd	s1,72(sp)
    80002a56:	e0ca                	sd	s2,64(sp)
    80002a58:	fc4e                	sd	s3,56(sp)
    80002a5a:	f852                	sd	s4,48(sp)
    80002a5c:	f456                	sd	s5,40(sp)
    80002a5e:	f05a                	sd	s6,32(sp)
    80002a60:	ec5e                	sd	s7,24(sp)
    80002a62:	e862                	sd	s8,16(sp)
    80002a64:	e466                	sd	s9,8(sp)
    80002a66:	e06a                	sd	s10,0(sp)
    80002a68:	1080                	addi	s0,sp,96
    80002a6a:	8b2a                	mv	s6,a0
    80002a6c:	8bae                	mv	s7,a1
    80002a6e:	8c32                	mv	s8,a2
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();
    80002a70:	fffff097          	auipc	ra,0xfffff
    80002a74:	144080e7          	jalr	324(ra) # 80001bb4 <myproc>
    80002a78:	892a                	mv	s2,a0

  acquire(&wait_lock);
    80002a7a:	0022e517          	auipc	a0,0x22e
    80002a7e:	40650513          	addi	a0,a0,1030 # 80230e80 <wait_lock>
    80002a82:	ffffe097          	auipc	ra,0xffffe
    80002a86:	31e080e7          	jalr	798(ra) # 80000da0 <acquire>

  for(;;){
    // Scan through table looking for exited children.
    havekids = 0;
    80002a8a:	4c81                	li	s9,0
      if(np->parent == p){
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if(np->state == ZOMBIE){
    80002a8c:	4a15                	li	s4,5
        havekids = 1;
    80002a8e:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    80002a90:	00235997          	auipc	s3,0x235
    80002a94:	40898993          	addi	s3,s3,1032 # 80237e98 <tickslock>
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002a98:	0022ed17          	auipc	s10,0x22e
    80002a9c:	3e8d0d13          	addi	s10,s10,1000 # 80230e80 <wait_lock>
    havekids = 0;
    80002aa0:	8766                	mv	a4,s9
    for(np = proc; np < &proc[NPROC]; np++){
    80002aa2:	0022e497          	auipc	s1,0x22e
    80002aa6:	7f648493          	addi	s1,s1,2038 # 80231298 <proc>
    80002aaa:	a069                	j	80002b34 <waitx+0xe6>
          pid = np->pid;
    80002aac:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;
    80002ab0:	1a04a783          	lw	a5,416(s1)
    80002ab4:	00fc2023          	sw	a5,0(s8)
          *wtime = np->etime - np->start_time - np->rtime;
    80002ab8:	16c4a783          	lw	a5,364(s1)
    80002abc:	1a04a703          	lw	a4,416(s1)
    80002ac0:	9f3d                	addw	a4,a4,a5
    80002ac2:	1984a783          	lw	a5,408(s1)
    80002ac6:	9f99                	subw	a5,a5,a4
    80002ac8:	00fba023          	sw	a5,0(s7)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002acc:	000b0e63          	beqz	s6,80002ae8 <waitx+0x9a>
    80002ad0:	4691                	li	a3,4
    80002ad2:	02c48613          	addi	a2,s1,44
    80002ad6:	85da                	mv	a1,s6
    80002ad8:	05093503          	ld	a0,80(s2)
    80002adc:	fffff097          	auipc	ra,0xfffff
    80002ae0:	d60080e7          	jalr	-672(ra) # 8000183c <copyout>
    80002ae4:	02054563          	bltz	a0,80002b0e <waitx+0xc0>
          freeproc(np);
    80002ae8:	8526                	mv	a0,s1
    80002aea:	fffff097          	auipc	ra,0xfffff
    80002aee:	27c080e7          	jalr	636(ra) # 80001d66 <freeproc>
          release(&np->lock);
    80002af2:	8526                	mv	a0,s1
    80002af4:	ffffe097          	auipc	ra,0xffffe
    80002af8:	360080e7          	jalr	864(ra) # 80000e54 <release>
          release(&wait_lock);
    80002afc:	0022e517          	auipc	a0,0x22e
    80002b00:	38450513          	addi	a0,a0,900 # 80230e80 <wait_lock>
    80002b04:	ffffe097          	auipc	ra,0xffffe
    80002b08:	350080e7          	jalr	848(ra) # 80000e54 <release>
          return pid;
    80002b0c:	a09d                	j	80002b72 <waitx+0x124>
            release(&np->lock);
    80002b0e:	8526                	mv	a0,s1
    80002b10:	ffffe097          	auipc	ra,0xffffe
    80002b14:	344080e7          	jalr	836(ra) # 80000e54 <release>
            release(&wait_lock);
    80002b18:	0022e517          	auipc	a0,0x22e
    80002b1c:	36850513          	addi	a0,a0,872 # 80230e80 <wait_lock>
    80002b20:	ffffe097          	auipc	ra,0xffffe
    80002b24:	334080e7          	jalr	820(ra) # 80000e54 <release>
            return -1;
    80002b28:	59fd                	li	s3,-1
    80002b2a:	a0a1                	j	80002b72 <waitx+0x124>
    for(np = proc; np < &proc[NPROC]; np++){
    80002b2c:	1b048493          	addi	s1,s1,432
    80002b30:	03348463          	beq	s1,s3,80002b58 <waitx+0x10a>
      if(np->parent == p){
    80002b34:	7c9c                	ld	a5,56(s1)
    80002b36:	ff279be3          	bne	a5,s2,80002b2c <waitx+0xde>
        acquire(&np->lock);
    80002b3a:	8526                	mv	a0,s1
    80002b3c:	ffffe097          	auipc	ra,0xffffe
    80002b40:	264080e7          	jalr	612(ra) # 80000da0 <acquire>
        if(np->state == ZOMBIE){
    80002b44:	4c9c                	lw	a5,24(s1)
    80002b46:	f74783e3          	beq	a5,s4,80002aac <waitx+0x5e>
        release(&np->lock);
    80002b4a:	8526                	mv	a0,s1
    80002b4c:	ffffe097          	auipc	ra,0xffffe
    80002b50:	308080e7          	jalr	776(ra) # 80000e54 <release>
        havekids = 1;
    80002b54:	8756                	mv	a4,s5
    80002b56:	bfd9                	j	80002b2c <waitx+0xde>
    if(!havekids || p->killed){
    80002b58:	c701                	beqz	a4,80002b60 <waitx+0x112>
    80002b5a:	02892783          	lw	a5,40(s2)
    80002b5e:	cb8d                	beqz	a5,80002b90 <waitx+0x142>
      release(&wait_lock);
    80002b60:	0022e517          	auipc	a0,0x22e
    80002b64:	32050513          	addi	a0,a0,800 # 80230e80 <wait_lock>
    80002b68:	ffffe097          	auipc	ra,0xffffe
    80002b6c:	2ec080e7          	jalr	748(ra) # 80000e54 <release>
      return -1;
    80002b70:	59fd                	li	s3,-1
  }
}
    80002b72:	854e                	mv	a0,s3
    80002b74:	60e6                	ld	ra,88(sp)
    80002b76:	6446                	ld	s0,80(sp)
    80002b78:	64a6                	ld	s1,72(sp)
    80002b7a:	6906                	ld	s2,64(sp)
    80002b7c:	79e2                	ld	s3,56(sp)
    80002b7e:	7a42                	ld	s4,48(sp)
    80002b80:	7aa2                	ld	s5,40(sp)
    80002b82:	7b02                	ld	s6,32(sp)
    80002b84:	6be2                	ld	s7,24(sp)
    80002b86:	6c42                	ld	s8,16(sp)
    80002b88:	6ca2                	ld	s9,8(sp)
    80002b8a:	6d02                	ld	s10,0(sp)
    80002b8c:	6125                	addi	sp,sp,96
    80002b8e:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002b90:	85ea                	mv	a1,s10
    80002b92:	854a                	mv	a0,s2
    80002b94:	fffff097          	auipc	ra,0xfffff
    80002b98:	7d8080e7          	jalr	2008(ra) # 8000236c <sleep>
    havekids = 0;
    80002b9c:	b711                	j	80002aa0 <waitx+0x52>

0000000080002b9e <swtch>:
    80002b9e:	00153023          	sd	ra,0(a0)
    80002ba2:	00253423          	sd	sp,8(a0)
    80002ba6:	e900                	sd	s0,16(a0)
    80002ba8:	ed04                	sd	s1,24(a0)
    80002baa:	03253023          	sd	s2,32(a0)
    80002bae:	03353423          	sd	s3,40(a0)
    80002bb2:	03453823          	sd	s4,48(a0)
    80002bb6:	03553c23          	sd	s5,56(a0)
    80002bba:	05653023          	sd	s6,64(a0)
    80002bbe:	05753423          	sd	s7,72(a0)
    80002bc2:	05853823          	sd	s8,80(a0)
    80002bc6:	05953c23          	sd	s9,88(a0)
    80002bca:	07a53023          	sd	s10,96(a0)
    80002bce:	07b53423          	sd	s11,104(a0)
    80002bd2:	0005b083          	ld	ra,0(a1)
    80002bd6:	0085b103          	ld	sp,8(a1)
    80002bda:	6980                	ld	s0,16(a1)
    80002bdc:	6d84                	ld	s1,24(a1)
    80002bde:	0205b903          	ld	s2,32(a1)
    80002be2:	0285b983          	ld	s3,40(a1)
    80002be6:	0305ba03          	ld	s4,48(a1)
    80002bea:	0385ba83          	ld	s5,56(a1)
    80002bee:	0405bb03          	ld	s6,64(a1)
    80002bf2:	0485bb83          	ld	s7,72(a1)
    80002bf6:	0505bc03          	ld	s8,80(a1)
    80002bfa:	0585bc83          	ld	s9,88(a1)
    80002bfe:	0605bd03          	ld	s10,96(a1)
    80002c02:	0685bd83          	ld	s11,104(a1)
    80002c06:	8082                	ret

0000000080002c08 <page_fault_handler>:
// in kernelvec.S, calls kerneltrap().
void kernelvec();

extern int devintr();

int page_fault_handler(void*va,pagetable_t pagetable){
    80002c08:	7179                	addi	sp,sp,-48
    80002c0a:	f406                	sd	ra,40(sp)
    80002c0c:	f022                	sd	s0,32(sp)
    80002c0e:	ec26                	sd	s1,24(sp)
    80002c10:	e84a                	sd	s2,16(sp)
    80002c12:	e44e                	sd	s3,8(sp)
    80002c14:	e052                	sd	s4,0(sp)
    80002c16:	1800                	addi	s0,sp,48
    80002c18:	84aa                	mv	s1,a0
    80002c1a:	892e                	mv	s2,a1
 
  struct proc* p = myproc();
    80002c1c:	fffff097          	auipc	ra,0xfffff
    80002c20:	f98080e7          	jalr	-104(ra) # 80001bb4 <myproc>
  if((uint64)va >= MAXVA || ((uint64)va >= PGROUNDDOWN(p->trapframe->sp) - PGSIZE&&(uint64)va <= PGROUNDDOWN(p->trapframe->sp))){
    80002c24:	57fd                	li	a5,-1
    80002c26:	83e9                	srli	a5,a5,0x1a
    80002c28:	0897e663          	bltu	a5,s1,80002cb4 <page_fault_handler+0xac>
    80002c2c:	6d38                	ld	a4,88(a0)
    80002c2e:	77fd                	lui	a5,0xfffff
    80002c30:	7b18                	ld	a4,48(a4)
    80002c32:	8f7d                	and	a4,a4,a5
    80002c34:	97ba                	add	a5,a5,a4
    80002c36:	00f4e463          	bltu	s1,a5,80002c3e <page_fault_handler+0x36>
    80002c3a:	06977f63          	bgeu	a4,s1,80002cb8 <page_fault_handler+0xb0>
  }
  pte_t *pte;
  uint64 pa;
  uint flags;
  va = (void*)PGROUNDDOWN((uint64)va);
  pte = walk(pagetable,(uint64)va,0);
    80002c3e:	4601                	li	a2,0
    80002c40:	75fd                	lui	a1,0xfffff
    80002c42:	8de5                	and	a1,a1,s1
    80002c44:	854a                	mv	a0,s2
    80002c46:	ffffe097          	auipc	ra,0xffffe
    80002c4a:	53a080e7          	jalr	1338(ra) # 80001180 <walk>
    80002c4e:	84aa                	mv	s1,a0
  if(pte == 0){
    80002c50:	c535                	beqz	a0,80002cbc <page_fault_handler+0xb4>
    return -1;
  }
  pa = PTE2PA(*pte);
    80002c52:	611c                	ld	a5,0(a0)
    80002c54:	00a7d913          	srli	s2,a5,0xa
    80002c58:	0932                	slli	s2,s2,0xc
  if(pa == 0){
    80002c5a:	06090363          	beqz	s2,80002cc0 <page_fault_handler+0xb8>
    return -1;
  }
  flags = PTE_FLAGS(*pte);
    80002c5e:	0007871b          	sext.w	a4,a5
  if(flags & PTE_COW){
    80002c62:	0207f793          	andi	a5,a5,32
    memmove(mem,(void*)pa,PGSIZE); 
    kfree((void*)pa);
    *pte = PA2PTE(mem)|flags;
    return 0;
  }
  return 0;
    80002c66:	4501                	li	a0,0
  if(flags & PTE_COW){
    80002c68:	eb89                	bnez	a5,80002c7a <page_fault_handler+0x72>
}
    80002c6a:	70a2                	ld	ra,40(sp)
    80002c6c:	7402                	ld	s0,32(sp)
    80002c6e:	64e2                	ld	s1,24(sp)
    80002c70:	6942                	ld	s2,16(sp)
    80002c72:	69a2                	ld	s3,8(sp)
    80002c74:	6a02                	ld	s4,0(sp)
    80002c76:	6145                	addi	sp,sp,48
    80002c78:	8082                	ret
    flags &= ~PTE_COW;
    80002c7a:	3df77713          	andi	a4,a4,991
    80002c7e:	00476993          	ori	s3,a4,4
    mem = kalloc();
    80002c82:	ffffe097          	auipc	ra,0xffffe
    80002c86:	024080e7          	jalr	36(ra) # 80000ca6 <kalloc>
    80002c8a:	8a2a                	mv	s4,a0
    if(mem == 0)
    80002c8c:	cd05                	beqz	a0,80002cc4 <page_fault_handler+0xbc>
    memmove(mem,(void*)pa,PGSIZE); 
    80002c8e:	6605                	lui	a2,0x1
    80002c90:	85ca                	mv	a1,s2
    80002c92:	ffffe097          	auipc	ra,0xffffe
    80002c96:	266080e7          	jalr	614(ra) # 80000ef8 <memmove>
    kfree((void*)pa);
    80002c9a:	854a                	mv	a0,s2
    80002c9c:	ffffe097          	auipc	ra,0xffffe
    80002ca0:	e82080e7          	jalr	-382(ra) # 80000b1e <kfree>
    *pte = PA2PTE(mem)|flags;
    80002ca4:	00ca5a13          	srli	s4,s4,0xc
    80002ca8:	0a2a                	slli	s4,s4,0xa
    80002caa:	0149e733          	or	a4,s3,s4
    80002cae:	e098                	sd	a4,0(s1)
    return 0;
    80002cb0:	4501                	li	a0,0
    80002cb2:	bf65                	j	80002c6a <page_fault_handler+0x62>
    return -1;
    80002cb4:	557d                	li	a0,-1
    80002cb6:	bf55                	j	80002c6a <page_fault_handler+0x62>
    80002cb8:	557d                	li	a0,-1
    80002cba:	bf45                	j	80002c6a <page_fault_handler+0x62>
    return -1;
    80002cbc:	557d                	li	a0,-1
    80002cbe:	b775                	j	80002c6a <page_fault_handler+0x62>
    return -1;
    80002cc0:	557d                	li	a0,-1
    80002cc2:	b765                	j	80002c6a <page_fault_handler+0x62>
      return -1;
    80002cc4:	557d                	li	a0,-1
    80002cc6:	b755                	j	80002c6a <page_fault_handler+0x62>

0000000080002cc8 <trapinit>:

void
trapinit(void)
{
    80002cc8:	1141                	addi	sp,sp,-16
    80002cca:	e406                	sd	ra,8(sp)
    80002ccc:	e022                	sd	s0,0(sp)
    80002cce:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002cd0:	00005597          	auipc	a1,0x5
    80002cd4:	6a058593          	addi	a1,a1,1696 # 80008370 <states.0+0x30>
    80002cd8:	00235517          	auipc	a0,0x235
    80002cdc:	1c050513          	addi	a0,a0,448 # 80237e98 <tickslock>
    80002ce0:	ffffe097          	auipc	ra,0xffffe
    80002ce4:	030080e7          	jalr	48(ra) # 80000d10 <initlock>
}
    80002ce8:	60a2                	ld	ra,8(sp)
    80002cea:	6402                	ld	s0,0(sp)
    80002cec:	0141                	addi	sp,sp,16
    80002cee:	8082                	ret

0000000080002cf0 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002cf0:	1141                	addi	sp,sp,-16
    80002cf2:	e422                	sd	s0,8(sp)
    80002cf4:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002cf6:	00004797          	auipc	a5,0x4
    80002cfa:	83a78793          	addi	a5,a5,-1990 # 80006530 <kernelvec>
    80002cfe:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002d02:	6422                	ld	s0,8(sp)
    80002d04:	0141                	addi	sp,sp,16
    80002d06:	8082                	ret

0000000080002d08 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002d08:	1141                	addi	sp,sp,-16
    80002d0a:	e406                	sd	ra,8(sp)
    80002d0c:	e022                	sd	s0,0(sp)
    80002d0e:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002d10:	fffff097          	auipc	ra,0xfffff
    80002d14:	ea4080e7          	jalr	-348(ra) # 80001bb4 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d18:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002d1c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d1e:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002d22:	00004697          	auipc	a3,0x4
    80002d26:	2de68693          	addi	a3,a3,734 # 80007000 <_trampoline>
    80002d2a:	00004717          	auipc	a4,0x4
    80002d2e:	2d670713          	addi	a4,a4,726 # 80007000 <_trampoline>
    80002d32:	8f15                	sub	a4,a4,a3
    80002d34:	040007b7          	lui	a5,0x4000
    80002d38:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002d3a:	07b2                	slli	a5,a5,0xc
    80002d3c:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002d3e:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002d42:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002d44:	18002673          	csrr	a2,satp
    80002d48:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002d4a:	6d30                	ld	a2,88(a0)
    80002d4c:	6138                	ld	a4,64(a0)
    80002d4e:	6585                	lui	a1,0x1
    80002d50:	972e                	add	a4,a4,a1
    80002d52:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002d54:	6d38                	ld	a4,88(a0)
    80002d56:	00000617          	auipc	a2,0x0
    80002d5a:	13e60613          	addi	a2,a2,318 # 80002e94 <usertrap>
    80002d5e:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002d60:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002d62:	8612                	mv	a2,tp
    80002d64:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d66:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002d6a:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002d6e:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d72:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002d76:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002d78:	6f18                	ld	a4,24(a4)
    80002d7a:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002d7e:	6928                	ld	a0,80(a0)
    80002d80:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002d82:	00004717          	auipc	a4,0x4
    80002d86:	31a70713          	addi	a4,a4,794 # 8000709c <userret>
    80002d8a:	8f15                	sub	a4,a4,a3
    80002d8c:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002d8e:	577d                	li	a4,-1
    80002d90:	177e                	slli	a4,a4,0x3f
    80002d92:	8d59                	or	a0,a0,a4
    80002d94:	9782                	jalr	a5
}
    80002d96:	60a2                	ld	ra,8(sp)
    80002d98:	6402                	ld	s0,0(sp)
    80002d9a:	0141                	addi	sp,sp,16
    80002d9c:	8082                	ret

0000000080002d9e <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002d9e:	1101                	addi	sp,sp,-32
    80002da0:	ec06                	sd	ra,24(sp)
    80002da2:	e822                	sd	s0,16(sp)
    80002da4:	e426                	sd	s1,8(sp)
    80002da6:	e04a                	sd	s2,0(sp)
    80002da8:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002daa:	00235917          	auipc	s2,0x235
    80002dae:	0ee90913          	addi	s2,s2,238 # 80237e98 <tickslock>
    80002db2:	854a                	mv	a0,s2
    80002db4:	ffffe097          	auipc	ra,0xffffe
    80002db8:	fec080e7          	jalr	-20(ra) # 80000da0 <acquire>
  ticks++;
    80002dbc:	00006497          	auipc	s1,0x6
    80002dc0:	e2c48493          	addi	s1,s1,-468 # 80008be8 <ticks>
    80002dc4:	409c                	lw	a5,0(s1)
    80002dc6:	2785                	addiw	a5,a5,1
    80002dc8:	c09c                	sw	a5,0(s1)
  update_time();
    80002dca:	00000097          	auipc	ra,0x0
    80002dce:	c12080e7          	jalr	-1006(ra) # 800029dc <update_time>
  wakeup(&ticks);
    80002dd2:	8526                	mv	a0,s1
    80002dd4:	fffff097          	auipc	ra,0xfffff
    80002dd8:	5fc080e7          	jalr	1532(ra) # 800023d0 <wakeup>
  release(&tickslock);
    80002ddc:	854a                	mv	a0,s2
    80002dde:	ffffe097          	auipc	ra,0xffffe
    80002de2:	076080e7          	jalr	118(ra) # 80000e54 <release>
}
    80002de6:	60e2                	ld	ra,24(sp)
    80002de8:	6442                	ld	s0,16(sp)
    80002dea:	64a2                	ld	s1,8(sp)
    80002dec:	6902                	ld	s2,0(sp)
    80002dee:	6105                	addi	sp,sp,32
    80002df0:	8082                	ret

0000000080002df2 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002df2:	1101                	addi	sp,sp,-32
    80002df4:	ec06                	sd	ra,24(sp)
    80002df6:	e822                	sd	s0,16(sp)
    80002df8:	e426                	sd	s1,8(sp)
    80002dfa:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002dfc:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002e00:	00074d63          	bltz	a4,80002e1a <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002e04:	57fd                	li	a5,-1
    80002e06:	17fe                	slli	a5,a5,0x3f
    80002e08:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002e0a:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002e0c:	06f70363          	beq	a4,a5,80002e72 <devintr+0x80>
  }
}
    80002e10:	60e2                	ld	ra,24(sp)
    80002e12:	6442                	ld	s0,16(sp)
    80002e14:	64a2                	ld	s1,8(sp)
    80002e16:	6105                	addi	sp,sp,32
    80002e18:	8082                	ret
     (scause & 0xff) == 9){
    80002e1a:	0ff77793          	zext.b	a5,a4
  if((scause & 0x8000000000000000L) &&
    80002e1e:	46a5                	li	a3,9
    80002e20:	fed792e3          	bne	a5,a3,80002e04 <devintr+0x12>
    int irq = plic_claim();
    80002e24:	00004097          	auipc	ra,0x4
    80002e28:	814080e7          	jalr	-2028(ra) # 80006638 <plic_claim>
    80002e2c:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002e2e:	47a9                	li	a5,10
    80002e30:	02f50763          	beq	a0,a5,80002e5e <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002e34:	4785                	li	a5,1
    80002e36:	02f50963          	beq	a0,a5,80002e68 <devintr+0x76>
    return 1;
    80002e3a:	4505                	li	a0,1
    } else if(irq){
    80002e3c:	d8f1                	beqz	s1,80002e10 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002e3e:	85a6                	mv	a1,s1
    80002e40:	00005517          	auipc	a0,0x5
    80002e44:	53850513          	addi	a0,a0,1336 # 80008378 <states.0+0x38>
    80002e48:	ffffd097          	auipc	ra,0xffffd
    80002e4c:	742080e7          	jalr	1858(ra) # 8000058a <printf>
      plic_complete(irq);
    80002e50:	8526                	mv	a0,s1
    80002e52:	00004097          	auipc	ra,0x4
    80002e56:	80a080e7          	jalr	-2038(ra) # 8000665c <plic_complete>
    return 1;
    80002e5a:	4505                	li	a0,1
    80002e5c:	bf55                	j	80002e10 <devintr+0x1e>
      uartintr();
    80002e5e:	ffffe097          	auipc	ra,0xffffe
    80002e62:	b3a080e7          	jalr	-1222(ra) # 80000998 <uartintr>
    80002e66:	b7ed                	j	80002e50 <devintr+0x5e>
      virtio_disk_intr();
    80002e68:	00004097          	auipc	ra,0x4
    80002e6c:	cbc080e7          	jalr	-836(ra) # 80006b24 <virtio_disk_intr>
    80002e70:	b7c5                	j	80002e50 <devintr+0x5e>
    if(cpuid() == 0){
    80002e72:	fffff097          	auipc	ra,0xfffff
    80002e76:	d16080e7          	jalr	-746(ra) # 80001b88 <cpuid>
    80002e7a:	c901                	beqz	a0,80002e8a <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002e7c:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002e80:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002e82:	14479073          	csrw	sip,a5
    return 2;
    80002e86:	4509                	li	a0,2
    80002e88:	b761                	j	80002e10 <devintr+0x1e>
      clockintr();
    80002e8a:	00000097          	auipc	ra,0x0
    80002e8e:	f14080e7          	jalr	-236(ra) # 80002d9e <clockintr>
    80002e92:	b7ed                	j	80002e7c <devintr+0x8a>

0000000080002e94 <usertrap>:
{
    80002e94:	1101                	addi	sp,sp,-32
    80002e96:	ec06                	sd	ra,24(sp)
    80002e98:	e822                	sd	s0,16(sp)
    80002e9a:	e426                	sd	s1,8(sp)
    80002e9c:	e04a                	sd	s2,0(sp)
    80002e9e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ea0:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002ea4:	1007f793          	andi	a5,a5,256
    80002ea8:	e3c1                	bnez	a5,80002f28 <usertrap+0x94>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002eaa:	00003797          	auipc	a5,0x3
    80002eae:	68678793          	addi	a5,a5,1670 # 80006530 <kernelvec>
    80002eb2:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002eb6:	fffff097          	auipc	ra,0xfffff
    80002eba:	cfe080e7          	jalr	-770(ra) # 80001bb4 <myproc>
    80002ebe:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002ec0:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ec2:	14102773          	csrr	a4,sepc
    80002ec6:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ec8:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002ecc:	47a1                	li	a5,8
    80002ece:	06f70563          	beq	a4,a5,80002f38 <usertrap+0xa4>
  } else if((which_dev = devintr()) != 0){
    80002ed2:	00000097          	auipc	ra,0x0
    80002ed6:	f20080e7          	jalr	-224(ra) # 80002df2 <devintr>
    80002eda:	c945                	beqz	a0,80002f8a <usertrap+0xf6>
    if(which_dev==2 && p->alarm_flag==0)
    80002edc:	4789                	li	a5,2
    80002ede:	08f51063          	bne	a0,a5,80002f5e <usertrap+0xca>
    80002ee2:	1904a783          	lw	a5,400(s1)
    80002ee6:	efa5                	bnez	a5,80002f5e <usertrap+0xca>
        struct trapframe *last=kalloc();
    80002ee8:	ffffe097          	auipc	ra,0xffffe
    80002eec:	dbe080e7          	jalr	-578(ra) # 80000ca6 <kalloc>
    80002ef0:	892a                	mv	s2,a0
        memmove(last,p->trapframe,PGSIZE);
    80002ef2:	6605                	lui	a2,0x1
    80002ef4:	6cac                	ld	a1,88(s1)
    80002ef6:	ffffe097          	auipc	ra,0xffffe
    80002efa:	002080e7          	jalr	2(ra) # 80000ef8 <memmove>
        p->lastsaved=last;
    80002efe:	1924b423          	sd	s2,392(s1)
        p->curr_ticks++;
    80002f02:	1844a783          	lw	a5,388(s1)
    80002f06:	2785                	addiw	a5,a5,1
    80002f08:	0007871b          	sext.w	a4,a5
    80002f0c:	18f4a223          	sw	a5,388(s1)
        if(p->curr_ticks==p->max_ticks)
    80002f10:	1804a783          	lw	a5,384(s1)
    80002f14:	04e79563          	bne	a5,a4,80002f5e <usertrap+0xca>
          p->trapframe->epc=p->handler;
    80002f18:	6cbc                	ld	a5,88(s1)
    80002f1a:	1784b703          	ld	a4,376(s1)
    80002f1e:	ef98                	sd	a4,24(a5)
          p->alarm_flag=1;
    80002f20:	4785                	li	a5,1
    80002f22:	18f4a823          	sw	a5,400(s1)
    80002f26:	a825                	j	80002f5e <usertrap+0xca>
    panic("usertrap: not from user mode");
    80002f28:	00005517          	auipc	a0,0x5
    80002f2c:	47050513          	addi	a0,a0,1136 # 80008398 <states.0+0x58>
    80002f30:	ffffd097          	auipc	ra,0xffffd
    80002f34:	610080e7          	jalr	1552(ra) # 80000540 <panic>
    if(killed(p))
    80002f38:	fffff097          	auipc	ra,0xfffff
    80002f3c:	6e8080e7          	jalr	1768(ra) # 80002620 <killed>
    80002f40:	ed1d                	bnez	a0,80002f7e <usertrap+0xea>
    p->trapframe->epc += 4;
    80002f42:	6cb8                	ld	a4,88(s1)
    80002f44:	6f1c                	ld	a5,24(a4)
    80002f46:	0791                	addi	a5,a5,4
    80002f48:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f4a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002f4e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002f52:	10079073          	csrw	sstatus,a5
    syscall();
    80002f56:	00000097          	auipc	ra,0x0
    80002f5a:	2c8080e7          	jalr	712(ra) # 8000321e <syscall>
  if(killed(p))
    80002f5e:	8526                	mv	a0,s1
    80002f60:	fffff097          	auipc	ra,0xfffff
    80002f64:	6c0080e7          	jalr	1728(ra) # 80002620 <killed>
    80002f68:	e549                	bnez	a0,80002ff2 <usertrap+0x15e>
  usertrapret();
    80002f6a:	00000097          	auipc	ra,0x0
    80002f6e:	d9e080e7          	jalr	-610(ra) # 80002d08 <usertrapret>
}
    80002f72:	60e2                	ld	ra,24(sp)
    80002f74:	6442                	ld	s0,16(sp)
    80002f76:	64a2                	ld	s1,8(sp)
    80002f78:	6902                	ld	s2,0(sp)
    80002f7a:	6105                	addi	sp,sp,32
    80002f7c:	8082                	ret
      exit(-1);
    80002f7e:	557d                	li	a0,-1
    80002f80:	fffff097          	auipc	ra,0xfffff
    80002f84:	520080e7          	jalr	1312(ra) # 800024a0 <exit>
    80002f88:	bf6d                	j	80002f42 <usertrap+0xae>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002f8a:	14202773          	csrr	a4,scause
  } else if(r_scause()==15||r_scause()==13){
    80002f8e:	47bd                	li	a5,15
    80002f90:	00f70763          	beq	a4,a5,80002f9e <usertrap+0x10a>
    80002f94:	14202773          	csrr	a4,scause
    80002f98:	47b5                	li	a5,13
    80002f9a:	00f71f63          	bne	a4,a5,80002fb8 <usertrap+0x124>
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002f9e:	14302573          	csrr	a0,stval
    int retval = page_fault_handler((void*)r_stval(),p->pagetable);
    80002fa2:	68ac                	ld	a1,80(s1)
    80002fa4:	00000097          	auipc	ra,0x0
    80002fa8:	c64080e7          	jalr	-924(ra) # 80002c08 <page_fault_handler>
    if(retval == -1){
    80002fac:	57fd                	li	a5,-1
    80002fae:	faf518e3          	bne	a0,a5,80002f5e <usertrap+0xca>
      p->killed=1;
    80002fb2:	4785                	li	a5,1
    80002fb4:	d49c                	sw	a5,40(s1)
    80002fb6:	b765                	j	80002f5e <usertrap+0xca>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002fb8:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002fbc:	5890                	lw	a2,48(s1)
    80002fbe:	00005517          	auipc	a0,0x5
    80002fc2:	3fa50513          	addi	a0,a0,1018 # 800083b8 <states.0+0x78>
    80002fc6:	ffffd097          	auipc	ra,0xffffd
    80002fca:	5c4080e7          	jalr	1476(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002fce:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002fd2:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002fd6:	00005517          	auipc	a0,0x5
    80002fda:	41250513          	addi	a0,a0,1042 # 800083e8 <states.0+0xa8>
    80002fde:	ffffd097          	auipc	ra,0xffffd
    80002fe2:	5ac080e7          	jalr	1452(ra) # 8000058a <printf>
    setkilled(p);
    80002fe6:	8526                	mv	a0,s1
    80002fe8:	fffff097          	auipc	ra,0xfffff
    80002fec:	60c080e7          	jalr	1548(ra) # 800025f4 <setkilled>
    80002ff0:	b7bd                	j	80002f5e <usertrap+0xca>
    exit(-1);
    80002ff2:	557d                	li	a0,-1
    80002ff4:	fffff097          	auipc	ra,0xfffff
    80002ff8:	4ac080e7          	jalr	1196(ra) # 800024a0 <exit>
    80002ffc:	b7bd                	j	80002f6a <usertrap+0xd6>

0000000080002ffe <kerneltrap>:
{
    80002ffe:	7179                	addi	sp,sp,-48
    80003000:	f406                	sd	ra,40(sp)
    80003002:	f022                	sd	s0,32(sp)
    80003004:	ec26                	sd	s1,24(sp)
    80003006:	e84a                	sd	s2,16(sp)
    80003008:	e44e                	sd	s3,8(sp)
    8000300a:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000300c:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003010:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003014:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80003018:	1004f793          	andi	a5,s1,256
    8000301c:	c78d                	beqz	a5,80003046 <kerneltrap+0x48>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000301e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80003022:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80003024:	eb8d                	bnez	a5,80003056 <kerneltrap+0x58>
  if((which_dev = devintr()) == 0){
    80003026:	00000097          	auipc	ra,0x0
    8000302a:	dcc080e7          	jalr	-564(ra) # 80002df2 <devintr>
    8000302e:	cd05                	beqz	a0,80003066 <kerneltrap+0x68>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80003030:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003034:	10049073          	csrw	sstatus,s1
}
    80003038:	70a2                	ld	ra,40(sp)
    8000303a:	7402                	ld	s0,32(sp)
    8000303c:	64e2                	ld	s1,24(sp)
    8000303e:	6942                	ld	s2,16(sp)
    80003040:	69a2                	ld	s3,8(sp)
    80003042:	6145                	addi	sp,sp,48
    80003044:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80003046:	00005517          	auipc	a0,0x5
    8000304a:	3c250513          	addi	a0,a0,962 # 80008408 <states.0+0xc8>
    8000304e:	ffffd097          	auipc	ra,0xffffd
    80003052:	4f2080e7          	jalr	1266(ra) # 80000540 <panic>
    panic("kerneltrap: interrupts enabled");
    80003056:	00005517          	auipc	a0,0x5
    8000305a:	3da50513          	addi	a0,a0,986 # 80008430 <states.0+0xf0>
    8000305e:	ffffd097          	auipc	ra,0xffffd
    80003062:	4e2080e7          	jalr	1250(ra) # 80000540 <panic>
    printf("scause %p\n", scause);
    80003066:	85ce                	mv	a1,s3
    80003068:	00005517          	auipc	a0,0x5
    8000306c:	3e850513          	addi	a0,a0,1000 # 80008450 <states.0+0x110>
    80003070:	ffffd097          	auipc	ra,0xffffd
    80003074:	51a080e7          	jalr	1306(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003078:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000307c:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003080:	00005517          	auipc	a0,0x5
    80003084:	3e050513          	addi	a0,a0,992 # 80008460 <states.0+0x120>
    80003088:	ffffd097          	auipc	ra,0xffffd
    8000308c:	502080e7          	jalr	1282(ra) # 8000058a <printf>
    panic("kerneltrap");
    80003090:	00005517          	auipc	a0,0x5
    80003094:	3e850513          	addi	a0,a0,1000 # 80008478 <states.0+0x138>
    80003098:	ffffd097          	auipc	ra,0xffffd
    8000309c:	4a8080e7          	jalr	1192(ra) # 80000540 <panic>

00000000800030a0 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    800030a0:	1101                	addi	sp,sp,-32
    800030a2:	ec06                	sd	ra,24(sp)
    800030a4:	e822                	sd	s0,16(sp)
    800030a6:	e426                	sd	s1,8(sp)
    800030a8:	1000                	addi	s0,sp,32
    800030aa:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800030ac:	fffff097          	auipc	ra,0xfffff
    800030b0:	b08080e7          	jalr	-1272(ra) # 80001bb4 <myproc>
  switch (n)
    800030b4:	4795                	li	a5,5
    800030b6:	0497e163          	bltu	a5,s1,800030f8 <argraw+0x58>
    800030ba:	048a                	slli	s1,s1,0x2
    800030bc:	00005717          	auipc	a4,0x5
    800030c0:	51470713          	addi	a4,a4,1300 # 800085d0 <states.0+0x290>
    800030c4:	94ba                	add	s1,s1,a4
    800030c6:	409c                	lw	a5,0(s1)
    800030c8:	97ba                	add	a5,a5,a4
    800030ca:	8782                	jr	a5
  {
  case 0:
    return p->trapframe->a0;
    800030cc:	6d3c                	ld	a5,88(a0)
    800030ce:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    800030d0:	60e2                	ld	ra,24(sp)
    800030d2:	6442                	ld	s0,16(sp)
    800030d4:	64a2                	ld	s1,8(sp)
    800030d6:	6105                	addi	sp,sp,32
    800030d8:	8082                	ret
    return p->trapframe->a1;
    800030da:	6d3c                	ld	a5,88(a0)
    800030dc:	7fa8                	ld	a0,120(a5)
    800030de:	bfcd                	j	800030d0 <argraw+0x30>
    return p->trapframe->a2;
    800030e0:	6d3c                	ld	a5,88(a0)
    800030e2:	63c8                	ld	a0,128(a5)
    800030e4:	b7f5                	j	800030d0 <argraw+0x30>
    return p->trapframe->a3;
    800030e6:	6d3c                	ld	a5,88(a0)
    800030e8:	67c8                	ld	a0,136(a5)
    800030ea:	b7dd                	j	800030d0 <argraw+0x30>
    return p->trapframe->a4;
    800030ec:	6d3c                	ld	a5,88(a0)
    800030ee:	6bc8                	ld	a0,144(a5)
    800030f0:	b7c5                	j	800030d0 <argraw+0x30>
    return p->trapframe->a5;
    800030f2:	6d3c                	ld	a5,88(a0)
    800030f4:	6fc8                	ld	a0,152(a5)
    800030f6:	bfe9                	j	800030d0 <argraw+0x30>
  panic("argraw");
    800030f8:	00005517          	auipc	a0,0x5
    800030fc:	39050513          	addi	a0,a0,912 # 80008488 <states.0+0x148>
    80003100:	ffffd097          	auipc	ra,0xffffd
    80003104:	440080e7          	jalr	1088(ra) # 80000540 <panic>

0000000080003108 <fetchaddr>:
{
    80003108:	1101                	addi	sp,sp,-32
    8000310a:	ec06                	sd	ra,24(sp)
    8000310c:	e822                	sd	s0,16(sp)
    8000310e:	e426                	sd	s1,8(sp)
    80003110:	e04a                	sd	s2,0(sp)
    80003112:	1000                	addi	s0,sp,32
    80003114:	84aa                	mv	s1,a0
    80003116:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80003118:	fffff097          	auipc	ra,0xfffff
    8000311c:	a9c080e7          	jalr	-1380(ra) # 80001bb4 <myproc>
  if (addr >= p->sz || addr + sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80003120:	653c                	ld	a5,72(a0)
    80003122:	02f4f863          	bgeu	s1,a5,80003152 <fetchaddr+0x4a>
    80003126:	00848713          	addi	a4,s1,8
    8000312a:	02e7e663          	bltu	a5,a4,80003156 <fetchaddr+0x4e>
  if (copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    8000312e:	46a1                	li	a3,8
    80003130:	8626                	mv	a2,s1
    80003132:	85ca                	mv	a1,s2
    80003134:	6928                	ld	a0,80(a0)
    80003136:	ffffe097          	auipc	ra,0xffffe
    8000313a:	7ca080e7          	jalr	1994(ra) # 80001900 <copyin>
    8000313e:	00a03533          	snez	a0,a0
    80003142:	40a00533          	neg	a0,a0
}
    80003146:	60e2                	ld	ra,24(sp)
    80003148:	6442                	ld	s0,16(sp)
    8000314a:	64a2                	ld	s1,8(sp)
    8000314c:	6902                	ld	s2,0(sp)
    8000314e:	6105                	addi	sp,sp,32
    80003150:	8082                	ret
    return -1;
    80003152:	557d                	li	a0,-1
    80003154:	bfcd                	j	80003146 <fetchaddr+0x3e>
    80003156:	557d                	li	a0,-1
    80003158:	b7fd                	j	80003146 <fetchaddr+0x3e>

000000008000315a <fetchstr>:
{
    8000315a:	7179                	addi	sp,sp,-48
    8000315c:	f406                	sd	ra,40(sp)
    8000315e:	f022                	sd	s0,32(sp)
    80003160:	ec26                	sd	s1,24(sp)
    80003162:	e84a                	sd	s2,16(sp)
    80003164:	e44e                	sd	s3,8(sp)
    80003166:	1800                	addi	s0,sp,48
    80003168:	892a                	mv	s2,a0
    8000316a:	84ae                	mv	s1,a1
    8000316c:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    8000316e:	fffff097          	auipc	ra,0xfffff
    80003172:	a46080e7          	jalr	-1466(ra) # 80001bb4 <myproc>
  if (copyinstr(p->pagetable, buf, addr, max) < 0)
    80003176:	86ce                	mv	a3,s3
    80003178:	864a                	mv	a2,s2
    8000317a:	85a6                	mv	a1,s1
    8000317c:	6928                	ld	a0,80(a0)
    8000317e:	fffff097          	auipc	ra,0xfffff
    80003182:	810080e7          	jalr	-2032(ra) # 8000198e <copyinstr>
    80003186:	00054e63          	bltz	a0,800031a2 <fetchstr+0x48>
  return strlen(buf);
    8000318a:	8526                	mv	a0,s1
    8000318c:	ffffe097          	auipc	ra,0xffffe
    80003190:	e8c080e7          	jalr	-372(ra) # 80001018 <strlen>
}
    80003194:	70a2                	ld	ra,40(sp)
    80003196:	7402                	ld	s0,32(sp)
    80003198:	64e2                	ld	s1,24(sp)
    8000319a:	6942                	ld	s2,16(sp)
    8000319c:	69a2                	ld	s3,8(sp)
    8000319e:	6145                	addi	sp,sp,48
    800031a0:	8082                	ret
    return -1;
    800031a2:	557d                	li	a0,-1
    800031a4:	bfc5                	j	80003194 <fetchstr+0x3a>

00000000800031a6 <argint>:

// Fetch the nth 32-bit system call argument.
void argint(int n, int *ip)
{
    800031a6:	1101                	addi	sp,sp,-32
    800031a8:	ec06                	sd	ra,24(sp)
    800031aa:	e822                	sd	s0,16(sp)
    800031ac:	e426                	sd	s1,8(sp)
    800031ae:	1000                	addi	s0,sp,32
    800031b0:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800031b2:	00000097          	auipc	ra,0x0
    800031b6:	eee080e7          	jalr	-274(ra) # 800030a0 <argraw>
    800031ba:	c088                	sw	a0,0(s1)
}
    800031bc:	60e2                	ld	ra,24(sp)
    800031be:	6442                	ld	s0,16(sp)
    800031c0:	64a2                	ld	s1,8(sp)
    800031c2:	6105                	addi	sp,sp,32
    800031c4:	8082                	ret

00000000800031c6 <argaddr>:

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void argaddr(int n, uint64 *ip)
{
    800031c6:	1101                	addi	sp,sp,-32
    800031c8:	ec06                	sd	ra,24(sp)
    800031ca:	e822                	sd	s0,16(sp)
    800031cc:	e426                	sd	s1,8(sp)
    800031ce:	1000                	addi	s0,sp,32
    800031d0:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800031d2:	00000097          	auipc	ra,0x0
    800031d6:	ece080e7          	jalr	-306(ra) # 800030a0 <argraw>
    800031da:	e088                	sd	a0,0(s1)
}
    800031dc:	60e2                	ld	ra,24(sp)
    800031de:	6442                	ld	s0,16(sp)
    800031e0:	64a2                	ld	s1,8(sp)
    800031e2:	6105                	addi	sp,sp,32
    800031e4:	8082                	ret

00000000800031e6 <argstr>:

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int argstr(int n, char *buf, int max)
{
    800031e6:	7179                	addi	sp,sp,-48
    800031e8:	f406                	sd	ra,40(sp)
    800031ea:	f022                	sd	s0,32(sp)
    800031ec:	ec26                	sd	s1,24(sp)
    800031ee:	e84a                	sd	s2,16(sp)
    800031f0:	1800                	addi	s0,sp,48
    800031f2:	84ae                	mv	s1,a1
    800031f4:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    800031f6:	fd840593          	addi	a1,s0,-40
    800031fa:	00000097          	auipc	ra,0x0
    800031fe:	fcc080e7          	jalr	-52(ra) # 800031c6 <argaddr>
  return fetchstr(addr, buf, max);
    80003202:	864a                	mv	a2,s2
    80003204:	85a6                	mv	a1,s1
    80003206:	fd843503          	ld	a0,-40(s0)
    8000320a:	00000097          	auipc	ra,0x0
    8000320e:	f50080e7          	jalr	-176(ra) # 8000315a <fetchstr>
}
    80003212:	70a2                	ld	ra,40(sp)
    80003214:	7402                	ld	s0,32(sp)
    80003216:	64e2                	ld	s1,24(sp)
    80003218:	6942                	ld	s2,16(sp)
    8000321a:	6145                	addi	sp,sp,48
    8000321c:	8082                	ret

000000008000321e <syscall>:
    [SYS_set_priority] 2,
    [SYS_settickets] 1,
};

void syscall(void)
{
    8000321e:	7179                	addi	sp,sp,-48
    80003220:	f406                	sd	ra,40(sp)
    80003222:	f022                	sd	s0,32(sp)
    80003224:	ec26                	sd	s1,24(sp)
    80003226:	e84a                	sd	s2,16(sp)
    80003228:	e44e                	sd	s3,8(sp)
    8000322a:	e052                	sd	s4,0(sp)
    8000322c:	1800                	addi	s0,sp,48
  int num;
  struct proc *p = myproc();
    8000322e:	fffff097          	auipc	ra,0xfffff
    80003232:	986080e7          	jalr	-1658(ra) # 80001bb4 <myproc>
    80003236:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80003238:	05853983          	ld	s3,88(a0)
    8000323c:	0a89b783          	ld	a5,168(s3)
    80003240:	0007891b          	sext.w	s2,a5

  int trace_flag = 0;

  if (num > 0 && num < NELEM(syscalls) && syscalls[num])
    80003244:	37fd                	addiw	a5,a5,-1
    80003246:	4769                	li	a4,26
    80003248:	12f76e63          	bltu	a4,a5,80003384 <syscall+0x166>
    8000324c:	00391713          	slli	a4,s2,0x3
    80003250:	00005797          	auipc	a5,0x5
    80003254:	39878793          	addi	a5,a5,920 # 800085e8 <syscalls>
    80003258:	97ba                	add	a5,a5,a4
    8000325a:	639c                	ld	a5,0(a5)
    8000325c:	12078463          	beqz	a5,80003384 <syscall+0x166>
  {
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    // if (trace_flag)
    int arg_0 = p->trapframe->a0;
    80003260:	0709ba03          	ld	s4,112(s3)
    p->trapframe->a0 = syscalls[num]();
    80003264:	9782                	jalr	a5
    80003266:	06a9b823          	sd	a0,112(s3)
    int pow = 1, temp = num;
    while (temp--)
    8000326a:	fff9079b          	addiw	a5,s2,-1
    8000326e:	00090c63          	beqz	s2,80003286 <syscall+0x68>
    int pow = 1, temp = num;
    80003272:	4705                	li	a4,1
    while (temp--)
    80003274:	567d                	li	a2,-1
    {
      pow *= 2;
    80003276:	86ba                	mv	a3,a4
    80003278:	0017171b          	slliw	a4,a4,0x1
    while (temp--)
    8000327c:	37fd                	addiw	a5,a5,-1
    8000327e:	fec79ce3          	bne	a5,a2,80003276 <syscall+0x58>
    }
    if (pow && p->trace_mask)
    80003282:	12068063          	beqz	a3,800033a2 <syscall+0x184>
    80003286:	1684a783          	lw	a5,360(s1)
    8000328a:	10078c63          	beqz	a5,800033a2 <syscall+0x184>
      trace_flag = 1;
    int argc = syscall_argc[num];
    8000328e:	00005797          	auipc	a5,0x5
    80003292:	7ba78793          	addi	a5,a5,1978 # 80008a48 <syscall_argc>
    80003296:	00291713          	slli	a4,s2,0x2
    8000329a:	973e                	add	a4,a4,a5
    8000329c:	00072983          	lw	s3,0(a4)
    if (trace_flag)
    {
      printf("%d: syscall %s (", p->pid, syscall_name[num]);
    800032a0:	090e                	slli	s2,s2,0x3
    800032a2:	97ca                	add	a5,a5,s2
    800032a4:	7bb0                	ld	a2,112(a5)
    800032a6:	588c                	lw	a1,48(s1)
    800032a8:	00005517          	auipc	a0,0x5
    800032ac:	1e850513          	addi	a0,a0,488 # 80008490 <states.0+0x150>
    800032b0:	ffffd097          	auipc	ra,0xffffd
    800032b4:	2da080e7          	jalr	730(ra) # 8000058a <printf>

      if (argc >= 1)
    800032b8:	05304463          	bgtz	s3,80003300 <syscall+0xe2>
        printf("%d", arg_0);
      if (argc >= 2)
    800032bc:	4785                	li	a5,1
    800032be:	0537cc63          	blt	a5,s3,80003316 <syscall+0xf8>
        printf(" %d", p->trapframe->a1);
      if (argc >= 3)
    800032c2:	4789                	li	a5,2
    800032c4:	0737c463          	blt	a5,s3,8000332c <syscall+0x10e>
        printf(" %d", p->trapframe->a2);
      if (argc >= 4)
    800032c8:	478d                	li	a5,3
    800032ca:	0737cc63          	blt	a5,s3,80003342 <syscall+0x124>
        printf(" %d", p->trapframe->a3);
      if (argc >= 5)
    800032ce:	4791                	li	a5,4
    800032d0:	0937c463          	blt	a5,s3,80003358 <syscall+0x13a>
        printf(" %d", p->trapframe->a4);
      if (argc >= 6)
    800032d4:	4795                	li	a5,5
    800032d6:	0937cc63          	blt	a5,s3,8000336e <syscall+0x150>
        printf(" %d", p->trapframe->a5);
      printf(") ");
    800032da:	00005517          	auipc	a0,0x5
    800032de:	1de50513          	addi	a0,a0,478 # 800084b8 <states.0+0x178>
    800032e2:	ffffd097          	auipc	ra,0xffffd
    800032e6:	2a8080e7          	jalr	680(ra) # 8000058a <printf>

      printf("-> %d\n", p->trapframe->a0);
    800032ea:	6cbc                	ld	a5,88(s1)
    800032ec:	7bac                	ld	a1,112(a5)
    800032ee:	00005517          	auipc	a0,0x5
    800032f2:	1d250513          	addi	a0,a0,466 # 800084c0 <states.0+0x180>
    800032f6:	ffffd097          	auipc	ra,0xffffd
    800032fa:	294080e7          	jalr	660(ra) # 8000058a <printf>
    800032fe:	a055                	j	800033a2 <syscall+0x184>
        printf("%d", arg_0);
    80003300:	000a059b          	sext.w	a1,s4
    80003304:	00005517          	auipc	a0,0x5
    80003308:	1a450513          	addi	a0,a0,420 # 800084a8 <states.0+0x168>
    8000330c:	ffffd097          	auipc	ra,0xffffd
    80003310:	27e080e7          	jalr	638(ra) # 8000058a <printf>
    80003314:	b765                	j	800032bc <syscall+0x9e>
        printf(" %d", p->trapframe->a1);
    80003316:	6cbc                	ld	a5,88(s1)
    80003318:	7fac                	ld	a1,120(a5)
    8000331a:	00005517          	auipc	a0,0x5
    8000331e:	19650513          	addi	a0,a0,406 # 800084b0 <states.0+0x170>
    80003322:	ffffd097          	auipc	ra,0xffffd
    80003326:	268080e7          	jalr	616(ra) # 8000058a <printf>
    8000332a:	bf61                	j	800032c2 <syscall+0xa4>
        printf(" %d", p->trapframe->a2);
    8000332c:	6cbc                	ld	a5,88(s1)
    8000332e:	63cc                	ld	a1,128(a5)
    80003330:	00005517          	auipc	a0,0x5
    80003334:	18050513          	addi	a0,a0,384 # 800084b0 <states.0+0x170>
    80003338:	ffffd097          	auipc	ra,0xffffd
    8000333c:	252080e7          	jalr	594(ra) # 8000058a <printf>
    80003340:	b761                	j	800032c8 <syscall+0xaa>
        printf(" %d", p->trapframe->a3);
    80003342:	6cbc                	ld	a5,88(s1)
    80003344:	67cc                	ld	a1,136(a5)
    80003346:	00005517          	auipc	a0,0x5
    8000334a:	16a50513          	addi	a0,a0,362 # 800084b0 <states.0+0x170>
    8000334e:	ffffd097          	auipc	ra,0xffffd
    80003352:	23c080e7          	jalr	572(ra) # 8000058a <printf>
    80003356:	bfa5                	j	800032ce <syscall+0xb0>
        printf(" %d", p->trapframe->a4);
    80003358:	6cbc                	ld	a5,88(s1)
    8000335a:	6bcc                	ld	a1,144(a5)
    8000335c:	00005517          	auipc	a0,0x5
    80003360:	15450513          	addi	a0,a0,340 # 800084b0 <states.0+0x170>
    80003364:	ffffd097          	auipc	ra,0xffffd
    80003368:	226080e7          	jalr	550(ra) # 8000058a <printf>
    8000336c:	b7a5                	j	800032d4 <syscall+0xb6>
        printf(" %d", p->trapframe->a5);
    8000336e:	6cbc                	ld	a5,88(s1)
    80003370:	6fcc                	ld	a1,152(a5)
    80003372:	00005517          	auipc	a0,0x5
    80003376:	13e50513          	addi	a0,a0,318 # 800084b0 <states.0+0x170>
    8000337a:	ffffd097          	auipc	ra,0xffffd
    8000337e:	210080e7          	jalr	528(ra) # 8000058a <printf>
    80003382:	bfa1                	j	800032da <syscall+0xbc>
    }
  }
  else
  {
    printf("%d %s: unknown sys call %d\n",
    80003384:	86ca                	mv	a3,s2
    80003386:	15848613          	addi	a2,s1,344
    8000338a:	588c                	lw	a1,48(s1)
    8000338c:	00005517          	auipc	a0,0x5
    80003390:	13c50513          	addi	a0,a0,316 # 800084c8 <states.0+0x188>
    80003394:	ffffd097          	auipc	ra,0xffffd
    80003398:	1f6080e7          	jalr	502(ra) # 8000058a <printf>
           p->pid, p->name, num);
    p->trapframe->a0 = -1;
    8000339c:	6cbc                	ld	a5,88(s1)
    8000339e:	577d                	li	a4,-1
    800033a0:	fbb8                	sd	a4,112(a5)
  }
}
    800033a2:	70a2                	ld	ra,40(sp)
    800033a4:	7402                	ld	s0,32(sp)
    800033a6:	64e2                	ld	s1,24(sp)
    800033a8:	6942                	ld	s2,16(sp)
    800033aa:	69a2                	ld	s3,8(sp)
    800033ac:	6a02                	ld	s4,0(sp)
    800033ae:	6145                	addi	sp,sp,48
    800033b0:	8082                	ret

00000000800033b2 <sys_exit>:
#include "proc.h"
#include "syscall.h"
// #include "../user/user.h"
uint64
sys_exit(void)
{
    800033b2:	1101                	addi	sp,sp,-32
    800033b4:	ec06                	sd	ra,24(sp)
    800033b6:	e822                	sd	s0,16(sp)
    800033b8:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    800033ba:	fec40593          	addi	a1,s0,-20
    800033be:	4501                	li	a0,0
    800033c0:	00000097          	auipc	ra,0x0
    800033c4:	de6080e7          	jalr	-538(ra) # 800031a6 <argint>
  exit(n);
    800033c8:	fec42503          	lw	a0,-20(s0)
    800033cc:	fffff097          	auipc	ra,0xfffff
    800033d0:	0d4080e7          	jalr	212(ra) # 800024a0 <exit>
  return 0;  // not reached
}
    800033d4:	4501                	li	a0,0
    800033d6:	60e2                	ld	ra,24(sp)
    800033d8:	6442                	ld	s0,16(sp)
    800033da:	6105                	addi	sp,sp,32
    800033dc:	8082                	ret

00000000800033de <sys_getpid>:

uint64
sys_getpid(void)
{
    800033de:	1141                	addi	sp,sp,-16
    800033e0:	e406                	sd	ra,8(sp)
    800033e2:	e022                	sd	s0,0(sp)
    800033e4:	0800                	addi	s0,sp,16
  return myproc()->pid;
    800033e6:	ffffe097          	auipc	ra,0xffffe
    800033ea:	7ce080e7          	jalr	1998(ra) # 80001bb4 <myproc>
}
    800033ee:	5908                	lw	a0,48(a0)
    800033f0:	60a2                	ld	ra,8(sp)
    800033f2:	6402                	ld	s0,0(sp)
    800033f4:	0141                	addi	sp,sp,16
    800033f6:	8082                	ret

00000000800033f8 <sys_fork>:

uint64
sys_fork(void)
{
    800033f8:	1141                	addi	sp,sp,-16
    800033fa:	e406                	sd	ra,8(sp)
    800033fc:	e022                	sd	s0,0(sp)
    800033fe:	0800                	addi	s0,sp,16
  return fork();
    80003400:	fffff097          	auipc	ra,0xfffff
    80003404:	bc0080e7          	jalr	-1088(ra) # 80001fc0 <fork>
}
    80003408:	60a2                	ld	ra,8(sp)
    8000340a:	6402                	ld	s0,0(sp)
    8000340c:	0141                	addi	sp,sp,16
    8000340e:	8082                	ret

0000000080003410 <sys_wait>:

uint64
sys_wait(void)
{
    80003410:	1101                	addi	sp,sp,-32
    80003412:	ec06                	sd	ra,24(sp)
    80003414:	e822                	sd	s0,16(sp)
    80003416:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80003418:	fe840593          	addi	a1,s0,-24
    8000341c:	4501                	li	a0,0
    8000341e:	00000097          	auipc	ra,0x0
    80003422:	da8080e7          	jalr	-600(ra) # 800031c6 <argaddr>
  return wait(p);
    80003426:	fe843503          	ld	a0,-24(s0)
    8000342a:	fffff097          	auipc	ra,0xfffff
    8000342e:	228080e7          	jalr	552(ra) # 80002652 <wait>
}
    80003432:	60e2                	ld	ra,24(sp)
    80003434:	6442                	ld	s0,16(sp)
    80003436:	6105                	addi	sp,sp,32
    80003438:	8082                	ret

000000008000343a <sys_sbrk>:

uint64
sys_sbrk(void)
{
    8000343a:	7179                	addi	sp,sp,-48
    8000343c:	f406                	sd	ra,40(sp)
    8000343e:	f022                	sd	s0,32(sp)
    80003440:	ec26                	sd	s1,24(sp)
    80003442:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80003444:	fdc40593          	addi	a1,s0,-36
    80003448:	4501                	li	a0,0
    8000344a:	00000097          	auipc	ra,0x0
    8000344e:	d5c080e7          	jalr	-676(ra) # 800031a6 <argint>
  addr = myproc()->sz;
    80003452:	ffffe097          	auipc	ra,0xffffe
    80003456:	762080e7          	jalr	1890(ra) # 80001bb4 <myproc>
    8000345a:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    8000345c:	fdc42503          	lw	a0,-36(s0)
    80003460:	fffff097          	auipc	ra,0xfffff
    80003464:	b04080e7          	jalr	-1276(ra) # 80001f64 <growproc>
    80003468:	00054863          	bltz	a0,80003478 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    8000346c:	8526                	mv	a0,s1
    8000346e:	70a2                	ld	ra,40(sp)
    80003470:	7402                	ld	s0,32(sp)
    80003472:	64e2                	ld	s1,24(sp)
    80003474:	6145                	addi	sp,sp,48
    80003476:	8082                	ret
    return -1;
    80003478:	54fd                	li	s1,-1
    8000347a:	bfcd                	j	8000346c <sys_sbrk+0x32>

000000008000347c <sys_sleep>:

uint64
sys_sleep(void)
{
    8000347c:	7139                	addi	sp,sp,-64
    8000347e:	fc06                	sd	ra,56(sp)
    80003480:	f822                	sd	s0,48(sp)
    80003482:	f426                	sd	s1,40(sp)
    80003484:	f04a                	sd	s2,32(sp)
    80003486:	ec4e                	sd	s3,24(sp)
    80003488:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    8000348a:	fcc40593          	addi	a1,s0,-52
    8000348e:	4501                	li	a0,0
    80003490:	00000097          	auipc	ra,0x0
    80003494:	d16080e7          	jalr	-746(ra) # 800031a6 <argint>
  acquire(&tickslock);
    80003498:	00235517          	auipc	a0,0x235
    8000349c:	a0050513          	addi	a0,a0,-1536 # 80237e98 <tickslock>
    800034a0:	ffffe097          	auipc	ra,0xffffe
    800034a4:	900080e7          	jalr	-1792(ra) # 80000da0 <acquire>
  ticks0 = ticks;
    800034a8:	00005917          	auipc	s2,0x5
    800034ac:	74092903          	lw	s2,1856(s2) # 80008be8 <ticks>
  while(ticks - ticks0 < n){
    800034b0:	fcc42783          	lw	a5,-52(s0)
    800034b4:	cf9d                	beqz	a5,800034f2 <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    800034b6:	00235997          	auipc	s3,0x235
    800034ba:	9e298993          	addi	s3,s3,-1566 # 80237e98 <tickslock>
    800034be:	00005497          	auipc	s1,0x5
    800034c2:	72a48493          	addi	s1,s1,1834 # 80008be8 <ticks>
    if(killed(myproc())){
    800034c6:	ffffe097          	auipc	ra,0xffffe
    800034ca:	6ee080e7          	jalr	1774(ra) # 80001bb4 <myproc>
    800034ce:	fffff097          	auipc	ra,0xfffff
    800034d2:	152080e7          	jalr	338(ra) # 80002620 <killed>
    800034d6:	ed15                	bnez	a0,80003512 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    800034d8:	85ce                	mv	a1,s3
    800034da:	8526                	mv	a0,s1
    800034dc:	fffff097          	auipc	ra,0xfffff
    800034e0:	e90080e7          	jalr	-368(ra) # 8000236c <sleep>
  while(ticks - ticks0 < n){
    800034e4:	409c                	lw	a5,0(s1)
    800034e6:	412787bb          	subw	a5,a5,s2
    800034ea:	fcc42703          	lw	a4,-52(s0)
    800034ee:	fce7ece3          	bltu	a5,a4,800034c6 <sys_sleep+0x4a>
  }
  release(&tickslock);
    800034f2:	00235517          	auipc	a0,0x235
    800034f6:	9a650513          	addi	a0,a0,-1626 # 80237e98 <tickslock>
    800034fa:	ffffe097          	auipc	ra,0xffffe
    800034fe:	95a080e7          	jalr	-1702(ra) # 80000e54 <release>
  return 0;
    80003502:	4501                	li	a0,0
}
    80003504:	70e2                	ld	ra,56(sp)
    80003506:	7442                	ld	s0,48(sp)
    80003508:	74a2                	ld	s1,40(sp)
    8000350a:	7902                	ld	s2,32(sp)
    8000350c:	69e2                	ld	s3,24(sp)
    8000350e:	6121                	addi	sp,sp,64
    80003510:	8082                	ret
      release(&tickslock);
    80003512:	00235517          	auipc	a0,0x235
    80003516:	98650513          	addi	a0,a0,-1658 # 80237e98 <tickslock>
    8000351a:	ffffe097          	auipc	ra,0xffffe
    8000351e:	93a080e7          	jalr	-1734(ra) # 80000e54 <release>
      return -1;
    80003522:	557d                	li	a0,-1
    80003524:	b7c5                	j	80003504 <sys_sleep+0x88>

0000000080003526 <sys_kill>:

uint64
sys_kill(void)
{
    80003526:	1101                	addi	sp,sp,-32
    80003528:	ec06                	sd	ra,24(sp)
    8000352a:	e822                	sd	s0,16(sp)
    8000352c:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    8000352e:	fec40593          	addi	a1,s0,-20
    80003532:	4501                	li	a0,0
    80003534:	00000097          	auipc	ra,0x0
    80003538:	c72080e7          	jalr	-910(ra) # 800031a6 <argint>
  return kill(pid);
    8000353c:	fec42503          	lw	a0,-20(s0)
    80003540:	fffff097          	auipc	ra,0xfffff
    80003544:	042080e7          	jalr	66(ra) # 80002582 <kill>
}
    80003548:	60e2                	ld	ra,24(sp)
    8000354a:	6442                	ld	s0,16(sp)
    8000354c:	6105                	addi	sp,sp,32
    8000354e:	8082                	ret

0000000080003550 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003550:	1101                	addi	sp,sp,-32
    80003552:	ec06                	sd	ra,24(sp)
    80003554:	e822                	sd	s0,16(sp)
    80003556:	e426                	sd	s1,8(sp)
    80003558:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    8000355a:	00235517          	auipc	a0,0x235
    8000355e:	93e50513          	addi	a0,a0,-1730 # 80237e98 <tickslock>
    80003562:	ffffe097          	auipc	ra,0xffffe
    80003566:	83e080e7          	jalr	-1986(ra) # 80000da0 <acquire>
  xticks = ticks;
    8000356a:	00005497          	auipc	s1,0x5
    8000356e:	67e4a483          	lw	s1,1662(s1) # 80008be8 <ticks>
  release(&tickslock);
    80003572:	00235517          	auipc	a0,0x235
    80003576:	92650513          	addi	a0,a0,-1754 # 80237e98 <tickslock>
    8000357a:	ffffe097          	auipc	ra,0xffffe
    8000357e:	8da080e7          	jalr	-1830(ra) # 80000e54 <release>
  return xticks;
}
    80003582:	02049513          	slli	a0,s1,0x20
    80003586:	9101                	srli	a0,a0,0x20
    80003588:	60e2                	ld	ra,24(sp)
    8000358a:	6442                	ld	s0,16(sp)
    8000358c:	64a2                	ld	s1,8(sp)
    8000358e:	6105                	addi	sp,sp,32
    80003590:	8082                	ret

0000000080003592 <sys_trace>:

uint64
sys_trace(void)
{
    80003592:	1101                	addi	sp,sp,-32
    80003594:	ec06                	sd	ra,24(sp)
    80003596:	e822                	sd	s0,16(sp)
    80003598:	1000                	addi	s0,sp,32
  int n;
  // if (argint(0, &n) < 0)
  //   return -1;

  argint(0, &n);
    8000359a:	fec40593          	addi	a1,s0,-20
    8000359e:	4501                	li	a0,0
    800035a0:	00000097          	auipc	ra,0x0
    800035a4:	c06080e7          	jalr	-1018(ra) # 800031a6 <argint>

  myproc()->trace_mask = n;
    800035a8:	ffffe097          	auipc	ra,0xffffe
    800035ac:	60c080e7          	jalr	1548(ra) # 80001bb4 <myproc>
    800035b0:	fec42783          	lw	a5,-20(s0)
    800035b4:	16f52423          	sw	a5,360(a0)
  return 0;
}
    800035b8:	4501                	li	a0,0
    800035ba:	60e2                	ld	ra,24(sp)
    800035bc:	6442                	ld	s0,16(sp)
    800035be:	6105                	addi	sp,sp,32
    800035c0:	8082                	ret

00000000800035c2 <sys_sigalarm>:

uint64
sys_sigalarm(void)
{
    800035c2:	7179                	addi	sp,sp,-48
    800035c4:	f406                	sd	ra,40(sp)
    800035c6:	f022                	sd	s0,32(sp)
    800035c8:	ec26                	sd	s1,24(sp)
    800035ca:	1800                	addi	s0,sp,48
  uint64 fh;
  int ticks;
  // printf("lol\n");
  argint(0,&ticks);
    800035cc:	fd440593          	addi	a1,s0,-44
    800035d0:	4501                	li	a0,0
    800035d2:	00000097          	auipc	ra,0x0
    800035d6:	bd4080e7          	jalr	-1068(ra) # 800031a6 <argint>
  if(ticks < 0)
    800035da:	fd442783          	lw	a5,-44(s0)
    return -1;
    800035de:	557d                	li	a0,-1
  if(ticks < 0)
    800035e0:	0407c963          	bltz	a5,80003632 <sys_sigalarm+0x70>
  argaddr(1,&fh);
    800035e4:	fd840593          	addi	a1,s0,-40
    800035e8:	4505                	li	a0,1
    800035ea:	00000097          	auipc	ra,0x0
    800035ee:	bdc080e7          	jalr	-1060(ra) # 800031c6 <argaddr>
  if(fh < 0)
    return -1;
  printf("%d",ticks);
    800035f2:	fd442583          	lw	a1,-44(s0)
    800035f6:	00005517          	auipc	a0,0x5
    800035fa:	eb250513          	addi	a0,a0,-334 # 800084a8 <states.0+0x168>
    800035fe:	ffffd097          	auipc	ra,0xffffd
    80003602:	f8c080e7          	jalr	-116(ra) # 8000058a <printf>
  struct proc *p = myproc();
    80003606:	ffffe097          	auipc	ra,0xffffe
    8000360a:	5ae080e7          	jalr	1454(ra) # 80001bb4 <myproc>
    8000360e:	84aa                	mv	s1,a0
  p->max_ticks = ticks;
    80003610:	fd442783          	lw	a5,-44(s0)
    80003614:	18f52023          	sw	a5,384(a0)
  p->handler = fh;
    80003618:	fd843783          	ld	a5,-40(s0)
    8000361c:	16f53c23          	sd	a5,376(a0)
  p->trapframe->a0=myproc()->orig_a0;
    80003620:	ffffe097          	auipc	ra,0xffffe
    80003624:	594080e7          	jalr	1428(ra) # 80001bb4 <myproc>
    80003628:	6cbc                	ld	a5,88(s1)
    8000362a:	19452703          	lw	a4,404(a0)
    8000362e:	fbb8                	sd	a4,112(a5)
  return 0;
    80003630:	4501                	li	a0,0
}
    80003632:	70a2                	ld	ra,40(sp)
    80003634:	7402                	ld	s0,32(sp)
    80003636:	64e2                	ld	s1,24(sp)
    80003638:	6145                	addi	sp,sp,48
    8000363a:	8082                	ret

000000008000363c <sys_sigreturn>:

uint64
sys_sigreturn(void)
{
    8000363c:	1101                	addi	sp,sp,-32
    8000363e:	ec06                	sd	ra,24(sp)
    80003640:	e822                	sd	s0,16(sp)
    80003642:	e426                	sd	s1,8(sp)
    80003644:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80003646:	ffffe097          	auipc	ra,0xffffe
    8000364a:	56e080e7          	jalr	1390(ra) # 80001bb4 <myproc>
    8000364e:	84aa                	mv	s1,a0
  memmove(p->trapframe,p->lastsaved,PGSIZE);
    80003650:	6605                	lui	a2,0x1
    80003652:	18853583          	ld	a1,392(a0)
    80003656:	6d28                	ld	a0,88(a0)
    80003658:	ffffe097          	auipc	ra,0xffffe
    8000365c:	8a0080e7          	jalr	-1888(ra) # 80000ef8 <memmove>
  kfree(p->lastsaved);
    80003660:	1884b503          	ld	a0,392(s1)
    80003664:	ffffd097          	auipc	ra,0xffffd
    80003668:	4ba080e7          	jalr	1210(ra) # 80000b1e <kfree>
  p->lastsaved=0;
    8000366c:	1804b423          	sd	zero,392(s1)
  p->curr_ticks=0;
    80003670:	1804a223          	sw	zero,388(s1)
  p->alarm_flag=0;
    80003674:	1804a823          	sw	zero,400(s1)
  // p->trapframe->a0=0xac;
  // printf("lol\n");
  return p->trapframe->a0;
    80003678:	6cbc                	ld	a5,88(s1)
}
    8000367a:	7ba8                	ld	a0,112(a5)
    8000367c:	60e2                	ld	ra,24(sp)
    8000367e:	6442                	ld	s0,16(sp)
    80003680:	64a2                	ld	s1,8(sp)
    80003682:	6105                	addi	sp,sp,32
    80003684:	8082                	ret

0000000080003686 <sys_settickets>:

uint64
sys_settickets(void)
{
    80003686:	1101                	addi	sp,sp,-32
    80003688:	ec06                	sd	ra,24(sp)
    8000368a:	e822                	sd	s0,16(sp)
    8000368c:	1000                	addi	s0,sp,32
  int n;
  argint(0,&n);
    8000368e:	fec40593          	addi	a1,s0,-20
    80003692:	4501                	li	a0,0
    80003694:	00000097          	auipc	ra,0x0
    80003698:	b12080e7          	jalr	-1262(ra) # 800031a6 <argint>
  if((n)<0)
    8000369c:	fec42783          	lw	a5,-20(s0)
    return -1;
    800036a0:	557d                	li	a0,-1
  if((n)<0)
    800036a2:	0007cb63          	bltz	a5,800036b8 <sys_settickets+0x32>
  struct proc *p= myproc();
    800036a6:	ffffe097          	auipc	ra,0xffffe
    800036aa:	50e080e7          	jalr	1294(ra) # 80001bb4 <myproc>
  p->tickets=n;
    800036ae:	fec42783          	lw	a5,-20(s0)
    800036b2:	16f52823          	sw	a5,368(a0)
  return 0;
    800036b6:	4501                	li	a0,0
}
    800036b8:	60e2                	ld	ra,24(sp)
    800036ba:	6442                	ld	s0,16(sp)
    800036bc:	6105                	addi	sp,sp,32
    800036be:	8082                	ret

00000000800036c0 <sys_set_priority>:

uint64
sys_set_priority(void)
{
    800036c0:	1101                	addi	sp,sp,-32
    800036c2:	ec06                	sd	ra,24(sp)
    800036c4:	e822                	sd	s0,16(sp)
    800036c6:	1000                	addi	s0,sp,32
  int priority,pid;
  argint(0,&priority);
    800036c8:	fec40593          	addi	a1,s0,-20
    800036cc:	4501                	li	a0,0
    800036ce:	00000097          	auipc	ra,0x0
    800036d2:	ad8080e7          	jalr	-1320(ra) # 800031a6 <argint>
  argint(1,&pid);
    800036d6:	fe840593          	addi	a1,s0,-24
    800036da:	4505                	li	a0,1
    800036dc:	00000097          	auipc	ra,0x0
    800036e0:	aca080e7          	jalr	-1334(ra) # 800031a6 <argint>
  if(priority<0 || pid<0)
    800036e4:	fec42783          	lw	a5,-20(s0)
    800036e8:	0207c063          	bltz	a5,80003708 <sys_set_priority+0x48>
    800036ec:	fe842583          	lw	a1,-24(s0)
    return -1;
    800036f0:	557d                	li	a0,-1
  if(priority<0 || pid<0)
    800036f2:	0005c763          	bltz	a1,80003700 <sys_set_priority+0x40>
  return set_spriority(priority,pid);
    800036f6:	853e                	mv	a0,a5
    800036f8:	fffff097          	auipc	ra,0xfffff
    800036fc:	226080e7          	jalr	550(ra) # 8000291e <set_spriority>
}
    80003700:	60e2                	ld	ra,24(sp)
    80003702:	6442                	ld	s0,16(sp)
    80003704:	6105                	addi	sp,sp,32
    80003706:	8082                	ret
    return -1;
    80003708:	557d                	li	a0,-1
    8000370a:	bfdd                	j	80003700 <sys_set_priority+0x40>

000000008000370c <sys_waitx>:

uint64
sys_waitx(void)
{
    8000370c:	7139                	addi	sp,sp,-64
    8000370e:	fc06                	sd	ra,56(sp)
    80003710:	f822                	sd	s0,48(sp)
    80003712:	f426                	sd	s1,40(sp)
    80003714:	f04a                	sd	s2,32(sp)
    80003716:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
    80003718:	fd840593          	addi	a1,s0,-40
    8000371c:	4501                	li	a0,0
    8000371e:	00000097          	auipc	ra,0x0
    80003722:	aa8080e7          	jalr	-1368(ra) # 800031c6 <argaddr>
  argaddr(1, &addr1); // user virtual memory
    80003726:	fd040593          	addi	a1,s0,-48
    8000372a:	4505                	li	a0,1
    8000372c:	00000097          	auipc	ra,0x0
    80003730:	a9a080e7          	jalr	-1382(ra) # 800031c6 <argaddr>
  argaddr(2, &addr2);
    80003734:	fc840593          	addi	a1,s0,-56
    80003738:	4509                	li	a0,2
    8000373a:	00000097          	auipc	ra,0x0
    8000373e:	a8c080e7          	jalr	-1396(ra) # 800031c6 <argaddr>
  int ret = waitx(addr, &wtime, &rtime);
    80003742:	fc040613          	addi	a2,s0,-64
    80003746:	fc440593          	addi	a1,s0,-60
    8000374a:	fd843503          	ld	a0,-40(s0)
    8000374e:	fffff097          	auipc	ra,0xfffff
    80003752:	300080e7          	jalr	768(ra) # 80002a4e <waitx>
    80003756:	892a                	mv	s2,a0
  struct proc* p = myproc();
    80003758:	ffffe097          	auipc	ra,0xffffe
    8000375c:	45c080e7          	jalr	1116(ra) # 80001bb4 <myproc>
    80003760:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1,(char*)&wtime, sizeof(int)) < 0)
    80003762:	4691                	li	a3,4
    80003764:	fc440613          	addi	a2,s0,-60
    80003768:	fd043583          	ld	a1,-48(s0)
    8000376c:	6928                	ld	a0,80(a0)
    8000376e:	ffffe097          	auipc	ra,0xffffe
    80003772:	0ce080e7          	jalr	206(ra) # 8000183c <copyout>
    return -1;
    80003776:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1,(char*)&wtime, sizeof(int)) < 0)
    80003778:	00054f63          	bltz	a0,80003796 <sys_waitx+0x8a>
  if (copyout(p->pagetable, addr2,(char*)&rtime, sizeof(int)) < 0)
    8000377c:	4691                	li	a3,4
    8000377e:	fc040613          	addi	a2,s0,-64
    80003782:	fc843583          	ld	a1,-56(s0)
    80003786:	68a8                	ld	a0,80(s1)
    80003788:	ffffe097          	auipc	ra,0xffffe
    8000378c:	0b4080e7          	jalr	180(ra) # 8000183c <copyout>
    80003790:	00054a63          	bltz	a0,800037a4 <sys_waitx+0x98>
    return -1;
  return ret;
    80003794:	87ca                	mv	a5,s2
    80003796:	853e                	mv	a0,a5
    80003798:	70e2                	ld	ra,56(sp)
    8000379a:	7442                	ld	s0,48(sp)
    8000379c:	74a2                	ld	s1,40(sp)
    8000379e:	7902                	ld	s2,32(sp)
    800037a0:	6121                	addi	sp,sp,64
    800037a2:	8082                	ret
    return -1;
    800037a4:	57fd                	li	a5,-1
    800037a6:	bfc5                	j	80003796 <sys_waitx+0x8a>

00000000800037a8 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800037a8:	7179                	addi	sp,sp,-48
    800037aa:	f406                	sd	ra,40(sp)
    800037ac:	f022                	sd	s0,32(sp)
    800037ae:	ec26                	sd	s1,24(sp)
    800037b0:	e84a                	sd	s2,16(sp)
    800037b2:	e44e                	sd	s3,8(sp)
    800037b4:	e052                	sd	s4,0(sp)
    800037b6:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800037b8:	00005597          	auipc	a1,0x5
    800037bc:	f1058593          	addi	a1,a1,-240 # 800086c8 <syscalls+0xe0>
    800037c0:	00234517          	auipc	a0,0x234
    800037c4:	6f050513          	addi	a0,a0,1776 # 80237eb0 <bcache>
    800037c8:	ffffd097          	auipc	ra,0xffffd
    800037cc:	548080e7          	jalr	1352(ra) # 80000d10 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800037d0:	0023c797          	auipc	a5,0x23c
    800037d4:	6e078793          	addi	a5,a5,1760 # 8023feb0 <bcache+0x8000>
    800037d8:	0023d717          	auipc	a4,0x23d
    800037dc:	94070713          	addi	a4,a4,-1728 # 80240118 <bcache+0x8268>
    800037e0:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800037e4:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800037e8:	00234497          	auipc	s1,0x234
    800037ec:	6e048493          	addi	s1,s1,1760 # 80237ec8 <bcache+0x18>
    b->next = bcache.head.next;
    800037f0:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800037f2:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800037f4:	00005a17          	auipc	s4,0x5
    800037f8:	edca0a13          	addi	s4,s4,-292 # 800086d0 <syscalls+0xe8>
    b->next = bcache.head.next;
    800037fc:	2b893783          	ld	a5,696(s2)
    80003800:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003802:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003806:	85d2                	mv	a1,s4
    80003808:	01048513          	addi	a0,s1,16
    8000380c:	00001097          	auipc	ra,0x1
    80003810:	4c8080e7          	jalr	1224(ra) # 80004cd4 <initsleeplock>
    bcache.head.next->prev = b;
    80003814:	2b893783          	ld	a5,696(s2)
    80003818:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    8000381a:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000381e:	45848493          	addi	s1,s1,1112
    80003822:	fd349de3          	bne	s1,s3,800037fc <binit+0x54>
  }
}
    80003826:	70a2                	ld	ra,40(sp)
    80003828:	7402                	ld	s0,32(sp)
    8000382a:	64e2                	ld	s1,24(sp)
    8000382c:	6942                	ld	s2,16(sp)
    8000382e:	69a2                	ld	s3,8(sp)
    80003830:	6a02                	ld	s4,0(sp)
    80003832:	6145                	addi	sp,sp,48
    80003834:	8082                	ret

0000000080003836 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003836:	7179                	addi	sp,sp,-48
    80003838:	f406                	sd	ra,40(sp)
    8000383a:	f022                	sd	s0,32(sp)
    8000383c:	ec26                	sd	s1,24(sp)
    8000383e:	e84a                	sd	s2,16(sp)
    80003840:	e44e                	sd	s3,8(sp)
    80003842:	1800                	addi	s0,sp,48
    80003844:	892a                	mv	s2,a0
    80003846:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80003848:	00234517          	auipc	a0,0x234
    8000384c:	66850513          	addi	a0,a0,1640 # 80237eb0 <bcache>
    80003850:	ffffd097          	auipc	ra,0xffffd
    80003854:	550080e7          	jalr	1360(ra) # 80000da0 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003858:	0023d497          	auipc	s1,0x23d
    8000385c:	9104b483          	ld	s1,-1776(s1) # 80240168 <bcache+0x82b8>
    80003860:	0023d797          	auipc	a5,0x23d
    80003864:	8b878793          	addi	a5,a5,-1864 # 80240118 <bcache+0x8268>
    80003868:	02f48f63          	beq	s1,a5,800038a6 <bread+0x70>
    8000386c:	873e                	mv	a4,a5
    8000386e:	a021                	j	80003876 <bread+0x40>
    80003870:	68a4                	ld	s1,80(s1)
    80003872:	02e48a63          	beq	s1,a4,800038a6 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003876:	449c                	lw	a5,8(s1)
    80003878:	ff279ce3          	bne	a5,s2,80003870 <bread+0x3a>
    8000387c:	44dc                	lw	a5,12(s1)
    8000387e:	ff3799e3          	bne	a5,s3,80003870 <bread+0x3a>
      b->refcnt++;
    80003882:	40bc                	lw	a5,64(s1)
    80003884:	2785                	addiw	a5,a5,1
    80003886:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003888:	00234517          	auipc	a0,0x234
    8000388c:	62850513          	addi	a0,a0,1576 # 80237eb0 <bcache>
    80003890:	ffffd097          	auipc	ra,0xffffd
    80003894:	5c4080e7          	jalr	1476(ra) # 80000e54 <release>
      acquiresleep(&b->lock);
    80003898:	01048513          	addi	a0,s1,16
    8000389c:	00001097          	auipc	ra,0x1
    800038a0:	472080e7          	jalr	1138(ra) # 80004d0e <acquiresleep>
      return b;
    800038a4:	a8b9                	j	80003902 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800038a6:	0023d497          	auipc	s1,0x23d
    800038aa:	8ba4b483          	ld	s1,-1862(s1) # 80240160 <bcache+0x82b0>
    800038ae:	0023d797          	auipc	a5,0x23d
    800038b2:	86a78793          	addi	a5,a5,-1942 # 80240118 <bcache+0x8268>
    800038b6:	00f48863          	beq	s1,a5,800038c6 <bread+0x90>
    800038ba:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800038bc:	40bc                	lw	a5,64(s1)
    800038be:	cf81                	beqz	a5,800038d6 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800038c0:	64a4                	ld	s1,72(s1)
    800038c2:	fee49de3          	bne	s1,a4,800038bc <bread+0x86>
  panic("bget: no buffers");
    800038c6:	00005517          	auipc	a0,0x5
    800038ca:	e1250513          	addi	a0,a0,-494 # 800086d8 <syscalls+0xf0>
    800038ce:	ffffd097          	auipc	ra,0xffffd
    800038d2:	c72080e7          	jalr	-910(ra) # 80000540 <panic>
      b->dev = dev;
    800038d6:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    800038da:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    800038de:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800038e2:	4785                	li	a5,1
    800038e4:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800038e6:	00234517          	auipc	a0,0x234
    800038ea:	5ca50513          	addi	a0,a0,1482 # 80237eb0 <bcache>
    800038ee:	ffffd097          	auipc	ra,0xffffd
    800038f2:	566080e7          	jalr	1382(ra) # 80000e54 <release>
      acquiresleep(&b->lock);
    800038f6:	01048513          	addi	a0,s1,16
    800038fa:	00001097          	auipc	ra,0x1
    800038fe:	414080e7          	jalr	1044(ra) # 80004d0e <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003902:	409c                	lw	a5,0(s1)
    80003904:	cb89                	beqz	a5,80003916 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003906:	8526                	mv	a0,s1
    80003908:	70a2                	ld	ra,40(sp)
    8000390a:	7402                	ld	s0,32(sp)
    8000390c:	64e2                	ld	s1,24(sp)
    8000390e:	6942                	ld	s2,16(sp)
    80003910:	69a2                	ld	s3,8(sp)
    80003912:	6145                	addi	sp,sp,48
    80003914:	8082                	ret
    virtio_disk_rw(b, 0);
    80003916:	4581                	li	a1,0
    80003918:	8526                	mv	a0,s1
    8000391a:	00003097          	auipc	ra,0x3
    8000391e:	fd8080e7          	jalr	-40(ra) # 800068f2 <virtio_disk_rw>
    b->valid = 1;
    80003922:	4785                	li	a5,1
    80003924:	c09c                	sw	a5,0(s1)
  return b;
    80003926:	b7c5                	j	80003906 <bread+0xd0>

0000000080003928 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003928:	1101                	addi	sp,sp,-32
    8000392a:	ec06                	sd	ra,24(sp)
    8000392c:	e822                	sd	s0,16(sp)
    8000392e:	e426                	sd	s1,8(sp)
    80003930:	1000                	addi	s0,sp,32
    80003932:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003934:	0541                	addi	a0,a0,16
    80003936:	00001097          	auipc	ra,0x1
    8000393a:	472080e7          	jalr	1138(ra) # 80004da8 <holdingsleep>
    8000393e:	cd01                	beqz	a0,80003956 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003940:	4585                	li	a1,1
    80003942:	8526                	mv	a0,s1
    80003944:	00003097          	auipc	ra,0x3
    80003948:	fae080e7          	jalr	-82(ra) # 800068f2 <virtio_disk_rw>
}
    8000394c:	60e2                	ld	ra,24(sp)
    8000394e:	6442                	ld	s0,16(sp)
    80003950:	64a2                	ld	s1,8(sp)
    80003952:	6105                	addi	sp,sp,32
    80003954:	8082                	ret
    panic("bwrite");
    80003956:	00005517          	auipc	a0,0x5
    8000395a:	d9a50513          	addi	a0,a0,-614 # 800086f0 <syscalls+0x108>
    8000395e:	ffffd097          	auipc	ra,0xffffd
    80003962:	be2080e7          	jalr	-1054(ra) # 80000540 <panic>

0000000080003966 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003966:	1101                	addi	sp,sp,-32
    80003968:	ec06                	sd	ra,24(sp)
    8000396a:	e822                	sd	s0,16(sp)
    8000396c:	e426                	sd	s1,8(sp)
    8000396e:	e04a                	sd	s2,0(sp)
    80003970:	1000                	addi	s0,sp,32
    80003972:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003974:	01050913          	addi	s2,a0,16
    80003978:	854a                	mv	a0,s2
    8000397a:	00001097          	auipc	ra,0x1
    8000397e:	42e080e7          	jalr	1070(ra) # 80004da8 <holdingsleep>
    80003982:	c92d                	beqz	a0,800039f4 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003984:	854a                	mv	a0,s2
    80003986:	00001097          	auipc	ra,0x1
    8000398a:	3de080e7          	jalr	990(ra) # 80004d64 <releasesleep>

  acquire(&bcache.lock);
    8000398e:	00234517          	auipc	a0,0x234
    80003992:	52250513          	addi	a0,a0,1314 # 80237eb0 <bcache>
    80003996:	ffffd097          	auipc	ra,0xffffd
    8000399a:	40a080e7          	jalr	1034(ra) # 80000da0 <acquire>
  b->refcnt--;
    8000399e:	40bc                	lw	a5,64(s1)
    800039a0:	37fd                	addiw	a5,a5,-1
    800039a2:	0007871b          	sext.w	a4,a5
    800039a6:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800039a8:	eb05                	bnez	a4,800039d8 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800039aa:	68bc                	ld	a5,80(s1)
    800039ac:	64b8                	ld	a4,72(s1)
    800039ae:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800039b0:	64bc                	ld	a5,72(s1)
    800039b2:	68b8                	ld	a4,80(s1)
    800039b4:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800039b6:	0023c797          	auipc	a5,0x23c
    800039ba:	4fa78793          	addi	a5,a5,1274 # 8023feb0 <bcache+0x8000>
    800039be:	2b87b703          	ld	a4,696(a5)
    800039c2:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800039c4:	0023c717          	auipc	a4,0x23c
    800039c8:	75470713          	addi	a4,a4,1876 # 80240118 <bcache+0x8268>
    800039cc:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800039ce:	2b87b703          	ld	a4,696(a5)
    800039d2:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800039d4:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800039d8:	00234517          	auipc	a0,0x234
    800039dc:	4d850513          	addi	a0,a0,1240 # 80237eb0 <bcache>
    800039e0:	ffffd097          	auipc	ra,0xffffd
    800039e4:	474080e7          	jalr	1140(ra) # 80000e54 <release>
}
    800039e8:	60e2                	ld	ra,24(sp)
    800039ea:	6442                	ld	s0,16(sp)
    800039ec:	64a2                	ld	s1,8(sp)
    800039ee:	6902                	ld	s2,0(sp)
    800039f0:	6105                	addi	sp,sp,32
    800039f2:	8082                	ret
    panic("brelse");
    800039f4:	00005517          	auipc	a0,0x5
    800039f8:	d0450513          	addi	a0,a0,-764 # 800086f8 <syscalls+0x110>
    800039fc:	ffffd097          	auipc	ra,0xffffd
    80003a00:	b44080e7          	jalr	-1212(ra) # 80000540 <panic>

0000000080003a04 <bpin>:

void
bpin(struct buf *b) {
    80003a04:	1101                	addi	sp,sp,-32
    80003a06:	ec06                	sd	ra,24(sp)
    80003a08:	e822                	sd	s0,16(sp)
    80003a0a:	e426                	sd	s1,8(sp)
    80003a0c:	1000                	addi	s0,sp,32
    80003a0e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003a10:	00234517          	auipc	a0,0x234
    80003a14:	4a050513          	addi	a0,a0,1184 # 80237eb0 <bcache>
    80003a18:	ffffd097          	auipc	ra,0xffffd
    80003a1c:	388080e7          	jalr	904(ra) # 80000da0 <acquire>
  b->refcnt++;
    80003a20:	40bc                	lw	a5,64(s1)
    80003a22:	2785                	addiw	a5,a5,1
    80003a24:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003a26:	00234517          	auipc	a0,0x234
    80003a2a:	48a50513          	addi	a0,a0,1162 # 80237eb0 <bcache>
    80003a2e:	ffffd097          	auipc	ra,0xffffd
    80003a32:	426080e7          	jalr	1062(ra) # 80000e54 <release>
}
    80003a36:	60e2                	ld	ra,24(sp)
    80003a38:	6442                	ld	s0,16(sp)
    80003a3a:	64a2                	ld	s1,8(sp)
    80003a3c:	6105                	addi	sp,sp,32
    80003a3e:	8082                	ret

0000000080003a40 <bunpin>:

void
bunpin(struct buf *b) {
    80003a40:	1101                	addi	sp,sp,-32
    80003a42:	ec06                	sd	ra,24(sp)
    80003a44:	e822                	sd	s0,16(sp)
    80003a46:	e426                	sd	s1,8(sp)
    80003a48:	1000                	addi	s0,sp,32
    80003a4a:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003a4c:	00234517          	auipc	a0,0x234
    80003a50:	46450513          	addi	a0,a0,1124 # 80237eb0 <bcache>
    80003a54:	ffffd097          	auipc	ra,0xffffd
    80003a58:	34c080e7          	jalr	844(ra) # 80000da0 <acquire>
  b->refcnt--;
    80003a5c:	40bc                	lw	a5,64(s1)
    80003a5e:	37fd                	addiw	a5,a5,-1
    80003a60:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003a62:	00234517          	auipc	a0,0x234
    80003a66:	44e50513          	addi	a0,a0,1102 # 80237eb0 <bcache>
    80003a6a:	ffffd097          	auipc	ra,0xffffd
    80003a6e:	3ea080e7          	jalr	1002(ra) # 80000e54 <release>
}
    80003a72:	60e2                	ld	ra,24(sp)
    80003a74:	6442                	ld	s0,16(sp)
    80003a76:	64a2                	ld	s1,8(sp)
    80003a78:	6105                	addi	sp,sp,32
    80003a7a:	8082                	ret

0000000080003a7c <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003a7c:	1101                	addi	sp,sp,-32
    80003a7e:	ec06                	sd	ra,24(sp)
    80003a80:	e822                	sd	s0,16(sp)
    80003a82:	e426                	sd	s1,8(sp)
    80003a84:	e04a                	sd	s2,0(sp)
    80003a86:	1000                	addi	s0,sp,32
    80003a88:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003a8a:	00d5d59b          	srliw	a1,a1,0xd
    80003a8e:	0023d797          	auipc	a5,0x23d
    80003a92:	afe7a783          	lw	a5,-1282(a5) # 8024058c <sb+0x1c>
    80003a96:	9dbd                	addw	a1,a1,a5
    80003a98:	00000097          	auipc	ra,0x0
    80003a9c:	d9e080e7          	jalr	-610(ra) # 80003836 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003aa0:	0074f713          	andi	a4,s1,7
    80003aa4:	4785                	li	a5,1
    80003aa6:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003aaa:	14ce                	slli	s1,s1,0x33
    80003aac:	90d9                	srli	s1,s1,0x36
    80003aae:	00950733          	add	a4,a0,s1
    80003ab2:	05874703          	lbu	a4,88(a4)
    80003ab6:	00e7f6b3          	and	a3,a5,a4
    80003aba:	c69d                	beqz	a3,80003ae8 <bfree+0x6c>
    80003abc:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003abe:	94aa                	add	s1,s1,a0
    80003ac0:	fff7c793          	not	a5,a5
    80003ac4:	8f7d                	and	a4,a4,a5
    80003ac6:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    80003aca:	00001097          	auipc	ra,0x1
    80003ace:	126080e7          	jalr	294(ra) # 80004bf0 <log_write>
  brelse(bp);
    80003ad2:	854a                	mv	a0,s2
    80003ad4:	00000097          	auipc	ra,0x0
    80003ad8:	e92080e7          	jalr	-366(ra) # 80003966 <brelse>
}
    80003adc:	60e2                	ld	ra,24(sp)
    80003ade:	6442                	ld	s0,16(sp)
    80003ae0:	64a2                	ld	s1,8(sp)
    80003ae2:	6902                	ld	s2,0(sp)
    80003ae4:	6105                	addi	sp,sp,32
    80003ae6:	8082                	ret
    panic("freeing free block");
    80003ae8:	00005517          	auipc	a0,0x5
    80003aec:	c1850513          	addi	a0,a0,-1000 # 80008700 <syscalls+0x118>
    80003af0:	ffffd097          	auipc	ra,0xffffd
    80003af4:	a50080e7          	jalr	-1456(ra) # 80000540 <panic>

0000000080003af8 <balloc>:
{
    80003af8:	711d                	addi	sp,sp,-96
    80003afa:	ec86                	sd	ra,88(sp)
    80003afc:	e8a2                	sd	s0,80(sp)
    80003afe:	e4a6                	sd	s1,72(sp)
    80003b00:	e0ca                	sd	s2,64(sp)
    80003b02:	fc4e                	sd	s3,56(sp)
    80003b04:	f852                	sd	s4,48(sp)
    80003b06:	f456                	sd	s5,40(sp)
    80003b08:	f05a                	sd	s6,32(sp)
    80003b0a:	ec5e                	sd	s7,24(sp)
    80003b0c:	e862                	sd	s8,16(sp)
    80003b0e:	e466                	sd	s9,8(sp)
    80003b10:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003b12:	0023d797          	auipc	a5,0x23d
    80003b16:	a627a783          	lw	a5,-1438(a5) # 80240574 <sb+0x4>
    80003b1a:	cff5                	beqz	a5,80003c16 <balloc+0x11e>
    80003b1c:	8baa                	mv	s7,a0
    80003b1e:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003b20:	0023db17          	auipc	s6,0x23d
    80003b24:	a50b0b13          	addi	s6,s6,-1456 # 80240570 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003b28:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003b2a:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003b2c:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003b2e:	6c89                	lui	s9,0x2
    80003b30:	a061                	j	80003bb8 <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003b32:	97ca                	add	a5,a5,s2
    80003b34:	8e55                	or	a2,a2,a3
    80003b36:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80003b3a:	854a                	mv	a0,s2
    80003b3c:	00001097          	auipc	ra,0x1
    80003b40:	0b4080e7          	jalr	180(ra) # 80004bf0 <log_write>
        brelse(bp);
    80003b44:	854a                	mv	a0,s2
    80003b46:	00000097          	auipc	ra,0x0
    80003b4a:	e20080e7          	jalr	-480(ra) # 80003966 <brelse>
  bp = bread(dev, bno);
    80003b4e:	85a6                	mv	a1,s1
    80003b50:	855e                	mv	a0,s7
    80003b52:	00000097          	auipc	ra,0x0
    80003b56:	ce4080e7          	jalr	-796(ra) # 80003836 <bread>
    80003b5a:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003b5c:	40000613          	li	a2,1024
    80003b60:	4581                	li	a1,0
    80003b62:	05850513          	addi	a0,a0,88
    80003b66:	ffffd097          	auipc	ra,0xffffd
    80003b6a:	336080e7          	jalr	822(ra) # 80000e9c <memset>
  log_write(bp);
    80003b6e:	854a                	mv	a0,s2
    80003b70:	00001097          	auipc	ra,0x1
    80003b74:	080080e7          	jalr	128(ra) # 80004bf0 <log_write>
  brelse(bp);
    80003b78:	854a                	mv	a0,s2
    80003b7a:	00000097          	auipc	ra,0x0
    80003b7e:	dec080e7          	jalr	-532(ra) # 80003966 <brelse>
}
    80003b82:	8526                	mv	a0,s1
    80003b84:	60e6                	ld	ra,88(sp)
    80003b86:	6446                	ld	s0,80(sp)
    80003b88:	64a6                	ld	s1,72(sp)
    80003b8a:	6906                	ld	s2,64(sp)
    80003b8c:	79e2                	ld	s3,56(sp)
    80003b8e:	7a42                	ld	s4,48(sp)
    80003b90:	7aa2                	ld	s5,40(sp)
    80003b92:	7b02                	ld	s6,32(sp)
    80003b94:	6be2                	ld	s7,24(sp)
    80003b96:	6c42                	ld	s8,16(sp)
    80003b98:	6ca2                	ld	s9,8(sp)
    80003b9a:	6125                	addi	sp,sp,96
    80003b9c:	8082                	ret
    brelse(bp);
    80003b9e:	854a                	mv	a0,s2
    80003ba0:	00000097          	auipc	ra,0x0
    80003ba4:	dc6080e7          	jalr	-570(ra) # 80003966 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003ba8:	015c87bb          	addw	a5,s9,s5
    80003bac:	00078a9b          	sext.w	s5,a5
    80003bb0:	004b2703          	lw	a4,4(s6)
    80003bb4:	06eaf163          	bgeu	s5,a4,80003c16 <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    80003bb8:	41fad79b          	sraiw	a5,s5,0x1f
    80003bbc:	0137d79b          	srliw	a5,a5,0x13
    80003bc0:	015787bb          	addw	a5,a5,s5
    80003bc4:	40d7d79b          	sraiw	a5,a5,0xd
    80003bc8:	01cb2583          	lw	a1,28(s6)
    80003bcc:	9dbd                	addw	a1,a1,a5
    80003bce:	855e                	mv	a0,s7
    80003bd0:	00000097          	auipc	ra,0x0
    80003bd4:	c66080e7          	jalr	-922(ra) # 80003836 <bread>
    80003bd8:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003bda:	004b2503          	lw	a0,4(s6)
    80003bde:	000a849b          	sext.w	s1,s5
    80003be2:	8762                	mv	a4,s8
    80003be4:	faa4fde3          	bgeu	s1,a0,80003b9e <balloc+0xa6>
      m = 1 << (bi % 8);
    80003be8:	00777693          	andi	a3,a4,7
    80003bec:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003bf0:	41f7579b          	sraiw	a5,a4,0x1f
    80003bf4:	01d7d79b          	srliw	a5,a5,0x1d
    80003bf8:	9fb9                	addw	a5,a5,a4
    80003bfa:	4037d79b          	sraiw	a5,a5,0x3
    80003bfe:	00f90633          	add	a2,s2,a5
    80003c02:	05864603          	lbu	a2,88(a2) # 1058 <_entry-0x7fffefa8>
    80003c06:	00c6f5b3          	and	a1,a3,a2
    80003c0a:	d585                	beqz	a1,80003b32 <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003c0c:	2705                	addiw	a4,a4,1
    80003c0e:	2485                	addiw	s1,s1,1
    80003c10:	fd471ae3          	bne	a4,s4,80003be4 <balloc+0xec>
    80003c14:	b769                	j	80003b9e <balloc+0xa6>
  printf("balloc: out of blocks\n");
    80003c16:	00005517          	auipc	a0,0x5
    80003c1a:	b0250513          	addi	a0,a0,-1278 # 80008718 <syscalls+0x130>
    80003c1e:	ffffd097          	auipc	ra,0xffffd
    80003c22:	96c080e7          	jalr	-1684(ra) # 8000058a <printf>
  return 0;
    80003c26:	4481                	li	s1,0
    80003c28:	bfa9                	j	80003b82 <balloc+0x8a>

0000000080003c2a <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003c2a:	7179                	addi	sp,sp,-48
    80003c2c:	f406                	sd	ra,40(sp)
    80003c2e:	f022                	sd	s0,32(sp)
    80003c30:	ec26                	sd	s1,24(sp)
    80003c32:	e84a                	sd	s2,16(sp)
    80003c34:	e44e                	sd	s3,8(sp)
    80003c36:	e052                	sd	s4,0(sp)
    80003c38:	1800                	addi	s0,sp,48
    80003c3a:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003c3c:	47ad                	li	a5,11
    80003c3e:	02b7e863          	bltu	a5,a1,80003c6e <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    80003c42:	02059793          	slli	a5,a1,0x20
    80003c46:	01e7d593          	srli	a1,a5,0x1e
    80003c4a:	00b504b3          	add	s1,a0,a1
    80003c4e:	0504a903          	lw	s2,80(s1)
    80003c52:	06091e63          	bnez	s2,80003cce <bmap+0xa4>
      addr = balloc(ip->dev);
    80003c56:	4108                	lw	a0,0(a0)
    80003c58:	00000097          	auipc	ra,0x0
    80003c5c:	ea0080e7          	jalr	-352(ra) # 80003af8 <balloc>
    80003c60:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003c64:	06090563          	beqz	s2,80003cce <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    80003c68:	0524a823          	sw	s2,80(s1)
    80003c6c:	a08d                	j	80003cce <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003c6e:	ff45849b          	addiw	s1,a1,-12
    80003c72:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003c76:	0ff00793          	li	a5,255
    80003c7a:	08e7e563          	bltu	a5,a4,80003d04 <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003c7e:	08052903          	lw	s2,128(a0)
    80003c82:	00091d63          	bnez	s2,80003c9c <bmap+0x72>
      addr = balloc(ip->dev);
    80003c86:	4108                	lw	a0,0(a0)
    80003c88:	00000097          	auipc	ra,0x0
    80003c8c:	e70080e7          	jalr	-400(ra) # 80003af8 <balloc>
    80003c90:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003c94:	02090d63          	beqz	s2,80003cce <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003c98:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003c9c:	85ca                	mv	a1,s2
    80003c9e:	0009a503          	lw	a0,0(s3)
    80003ca2:	00000097          	auipc	ra,0x0
    80003ca6:	b94080e7          	jalr	-1132(ra) # 80003836 <bread>
    80003caa:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003cac:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003cb0:	02049713          	slli	a4,s1,0x20
    80003cb4:	01e75593          	srli	a1,a4,0x1e
    80003cb8:	00b784b3          	add	s1,a5,a1
    80003cbc:	0004a903          	lw	s2,0(s1)
    80003cc0:	02090063          	beqz	s2,80003ce0 <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003cc4:	8552                	mv	a0,s4
    80003cc6:	00000097          	auipc	ra,0x0
    80003cca:	ca0080e7          	jalr	-864(ra) # 80003966 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003cce:	854a                	mv	a0,s2
    80003cd0:	70a2                	ld	ra,40(sp)
    80003cd2:	7402                	ld	s0,32(sp)
    80003cd4:	64e2                	ld	s1,24(sp)
    80003cd6:	6942                	ld	s2,16(sp)
    80003cd8:	69a2                	ld	s3,8(sp)
    80003cda:	6a02                	ld	s4,0(sp)
    80003cdc:	6145                	addi	sp,sp,48
    80003cde:	8082                	ret
      addr = balloc(ip->dev);
    80003ce0:	0009a503          	lw	a0,0(s3)
    80003ce4:	00000097          	auipc	ra,0x0
    80003ce8:	e14080e7          	jalr	-492(ra) # 80003af8 <balloc>
    80003cec:	0005091b          	sext.w	s2,a0
      if(addr){
    80003cf0:	fc090ae3          	beqz	s2,80003cc4 <bmap+0x9a>
        a[bn] = addr;
    80003cf4:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003cf8:	8552                	mv	a0,s4
    80003cfa:	00001097          	auipc	ra,0x1
    80003cfe:	ef6080e7          	jalr	-266(ra) # 80004bf0 <log_write>
    80003d02:	b7c9                	j	80003cc4 <bmap+0x9a>
  panic("bmap: out of range");
    80003d04:	00005517          	auipc	a0,0x5
    80003d08:	a2c50513          	addi	a0,a0,-1492 # 80008730 <syscalls+0x148>
    80003d0c:	ffffd097          	auipc	ra,0xffffd
    80003d10:	834080e7          	jalr	-1996(ra) # 80000540 <panic>

0000000080003d14 <iget>:
{
    80003d14:	7179                	addi	sp,sp,-48
    80003d16:	f406                	sd	ra,40(sp)
    80003d18:	f022                	sd	s0,32(sp)
    80003d1a:	ec26                	sd	s1,24(sp)
    80003d1c:	e84a                	sd	s2,16(sp)
    80003d1e:	e44e                	sd	s3,8(sp)
    80003d20:	e052                	sd	s4,0(sp)
    80003d22:	1800                	addi	s0,sp,48
    80003d24:	89aa                	mv	s3,a0
    80003d26:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003d28:	0023d517          	auipc	a0,0x23d
    80003d2c:	86850513          	addi	a0,a0,-1944 # 80240590 <itable>
    80003d30:	ffffd097          	auipc	ra,0xffffd
    80003d34:	070080e7          	jalr	112(ra) # 80000da0 <acquire>
  empty = 0;
    80003d38:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003d3a:	0023d497          	auipc	s1,0x23d
    80003d3e:	86e48493          	addi	s1,s1,-1938 # 802405a8 <itable+0x18>
    80003d42:	0023e697          	auipc	a3,0x23e
    80003d46:	2f668693          	addi	a3,a3,758 # 80242038 <log>
    80003d4a:	a039                	j	80003d58 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003d4c:	02090b63          	beqz	s2,80003d82 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003d50:	08848493          	addi	s1,s1,136
    80003d54:	02d48a63          	beq	s1,a3,80003d88 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003d58:	449c                	lw	a5,8(s1)
    80003d5a:	fef059e3          	blez	a5,80003d4c <iget+0x38>
    80003d5e:	4098                	lw	a4,0(s1)
    80003d60:	ff3716e3          	bne	a4,s3,80003d4c <iget+0x38>
    80003d64:	40d8                	lw	a4,4(s1)
    80003d66:	ff4713e3          	bne	a4,s4,80003d4c <iget+0x38>
      ip->ref++;
    80003d6a:	2785                	addiw	a5,a5,1
    80003d6c:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003d6e:	0023d517          	auipc	a0,0x23d
    80003d72:	82250513          	addi	a0,a0,-2014 # 80240590 <itable>
    80003d76:	ffffd097          	auipc	ra,0xffffd
    80003d7a:	0de080e7          	jalr	222(ra) # 80000e54 <release>
      return ip;
    80003d7e:	8926                	mv	s2,s1
    80003d80:	a03d                	j	80003dae <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003d82:	f7f9                	bnez	a5,80003d50 <iget+0x3c>
    80003d84:	8926                	mv	s2,s1
    80003d86:	b7e9                	j	80003d50 <iget+0x3c>
  if(empty == 0)
    80003d88:	02090c63          	beqz	s2,80003dc0 <iget+0xac>
  ip->dev = dev;
    80003d8c:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003d90:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003d94:	4785                	li	a5,1
    80003d96:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003d9a:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003d9e:	0023c517          	auipc	a0,0x23c
    80003da2:	7f250513          	addi	a0,a0,2034 # 80240590 <itable>
    80003da6:	ffffd097          	auipc	ra,0xffffd
    80003daa:	0ae080e7          	jalr	174(ra) # 80000e54 <release>
}
    80003dae:	854a                	mv	a0,s2
    80003db0:	70a2                	ld	ra,40(sp)
    80003db2:	7402                	ld	s0,32(sp)
    80003db4:	64e2                	ld	s1,24(sp)
    80003db6:	6942                	ld	s2,16(sp)
    80003db8:	69a2                	ld	s3,8(sp)
    80003dba:	6a02                	ld	s4,0(sp)
    80003dbc:	6145                	addi	sp,sp,48
    80003dbe:	8082                	ret
    panic("iget: no inodes");
    80003dc0:	00005517          	auipc	a0,0x5
    80003dc4:	98850513          	addi	a0,a0,-1656 # 80008748 <syscalls+0x160>
    80003dc8:	ffffc097          	auipc	ra,0xffffc
    80003dcc:	778080e7          	jalr	1912(ra) # 80000540 <panic>

0000000080003dd0 <fsinit>:
fsinit(int dev) {
    80003dd0:	7179                	addi	sp,sp,-48
    80003dd2:	f406                	sd	ra,40(sp)
    80003dd4:	f022                	sd	s0,32(sp)
    80003dd6:	ec26                	sd	s1,24(sp)
    80003dd8:	e84a                	sd	s2,16(sp)
    80003dda:	e44e                	sd	s3,8(sp)
    80003ddc:	1800                	addi	s0,sp,48
    80003dde:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003de0:	4585                	li	a1,1
    80003de2:	00000097          	auipc	ra,0x0
    80003de6:	a54080e7          	jalr	-1452(ra) # 80003836 <bread>
    80003dea:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003dec:	0023c997          	auipc	s3,0x23c
    80003df0:	78498993          	addi	s3,s3,1924 # 80240570 <sb>
    80003df4:	02000613          	li	a2,32
    80003df8:	05850593          	addi	a1,a0,88
    80003dfc:	854e                	mv	a0,s3
    80003dfe:	ffffd097          	auipc	ra,0xffffd
    80003e02:	0fa080e7          	jalr	250(ra) # 80000ef8 <memmove>
  brelse(bp);
    80003e06:	8526                	mv	a0,s1
    80003e08:	00000097          	auipc	ra,0x0
    80003e0c:	b5e080e7          	jalr	-1186(ra) # 80003966 <brelse>
  if(sb.magic != FSMAGIC)
    80003e10:	0009a703          	lw	a4,0(s3)
    80003e14:	102037b7          	lui	a5,0x10203
    80003e18:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003e1c:	02f71263          	bne	a4,a5,80003e40 <fsinit+0x70>
  initlog(dev, &sb);
    80003e20:	0023c597          	auipc	a1,0x23c
    80003e24:	75058593          	addi	a1,a1,1872 # 80240570 <sb>
    80003e28:	854a                	mv	a0,s2
    80003e2a:	00001097          	auipc	ra,0x1
    80003e2e:	b4a080e7          	jalr	-1206(ra) # 80004974 <initlog>
}
    80003e32:	70a2                	ld	ra,40(sp)
    80003e34:	7402                	ld	s0,32(sp)
    80003e36:	64e2                	ld	s1,24(sp)
    80003e38:	6942                	ld	s2,16(sp)
    80003e3a:	69a2                	ld	s3,8(sp)
    80003e3c:	6145                	addi	sp,sp,48
    80003e3e:	8082                	ret
    panic("invalid file system");
    80003e40:	00005517          	auipc	a0,0x5
    80003e44:	91850513          	addi	a0,a0,-1768 # 80008758 <syscalls+0x170>
    80003e48:	ffffc097          	auipc	ra,0xffffc
    80003e4c:	6f8080e7          	jalr	1784(ra) # 80000540 <panic>

0000000080003e50 <iinit>:
{
    80003e50:	7179                	addi	sp,sp,-48
    80003e52:	f406                	sd	ra,40(sp)
    80003e54:	f022                	sd	s0,32(sp)
    80003e56:	ec26                	sd	s1,24(sp)
    80003e58:	e84a                	sd	s2,16(sp)
    80003e5a:	e44e                	sd	s3,8(sp)
    80003e5c:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003e5e:	00005597          	auipc	a1,0x5
    80003e62:	91258593          	addi	a1,a1,-1774 # 80008770 <syscalls+0x188>
    80003e66:	0023c517          	auipc	a0,0x23c
    80003e6a:	72a50513          	addi	a0,a0,1834 # 80240590 <itable>
    80003e6e:	ffffd097          	auipc	ra,0xffffd
    80003e72:	ea2080e7          	jalr	-350(ra) # 80000d10 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003e76:	0023c497          	auipc	s1,0x23c
    80003e7a:	74248493          	addi	s1,s1,1858 # 802405b8 <itable+0x28>
    80003e7e:	0023e997          	auipc	s3,0x23e
    80003e82:	1ca98993          	addi	s3,s3,458 # 80242048 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003e86:	00005917          	auipc	s2,0x5
    80003e8a:	8f290913          	addi	s2,s2,-1806 # 80008778 <syscalls+0x190>
    80003e8e:	85ca                	mv	a1,s2
    80003e90:	8526                	mv	a0,s1
    80003e92:	00001097          	auipc	ra,0x1
    80003e96:	e42080e7          	jalr	-446(ra) # 80004cd4 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003e9a:	08848493          	addi	s1,s1,136
    80003e9e:	ff3498e3          	bne	s1,s3,80003e8e <iinit+0x3e>
}
    80003ea2:	70a2                	ld	ra,40(sp)
    80003ea4:	7402                	ld	s0,32(sp)
    80003ea6:	64e2                	ld	s1,24(sp)
    80003ea8:	6942                	ld	s2,16(sp)
    80003eaa:	69a2                	ld	s3,8(sp)
    80003eac:	6145                	addi	sp,sp,48
    80003eae:	8082                	ret

0000000080003eb0 <ialloc>:
{
    80003eb0:	715d                	addi	sp,sp,-80
    80003eb2:	e486                	sd	ra,72(sp)
    80003eb4:	e0a2                	sd	s0,64(sp)
    80003eb6:	fc26                	sd	s1,56(sp)
    80003eb8:	f84a                	sd	s2,48(sp)
    80003eba:	f44e                	sd	s3,40(sp)
    80003ebc:	f052                	sd	s4,32(sp)
    80003ebe:	ec56                	sd	s5,24(sp)
    80003ec0:	e85a                	sd	s6,16(sp)
    80003ec2:	e45e                	sd	s7,8(sp)
    80003ec4:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003ec6:	0023c717          	auipc	a4,0x23c
    80003eca:	6b672703          	lw	a4,1718(a4) # 8024057c <sb+0xc>
    80003ece:	4785                	li	a5,1
    80003ed0:	04e7fa63          	bgeu	a5,a4,80003f24 <ialloc+0x74>
    80003ed4:	8aaa                	mv	s5,a0
    80003ed6:	8bae                	mv	s7,a1
    80003ed8:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003eda:	0023ca17          	auipc	s4,0x23c
    80003ede:	696a0a13          	addi	s4,s4,1686 # 80240570 <sb>
    80003ee2:	00048b1b          	sext.w	s6,s1
    80003ee6:	0044d593          	srli	a1,s1,0x4
    80003eea:	018a2783          	lw	a5,24(s4)
    80003eee:	9dbd                	addw	a1,a1,a5
    80003ef0:	8556                	mv	a0,s5
    80003ef2:	00000097          	auipc	ra,0x0
    80003ef6:	944080e7          	jalr	-1724(ra) # 80003836 <bread>
    80003efa:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003efc:	05850993          	addi	s3,a0,88
    80003f00:	00f4f793          	andi	a5,s1,15
    80003f04:	079a                	slli	a5,a5,0x6
    80003f06:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003f08:	00099783          	lh	a5,0(s3)
    80003f0c:	c3a1                	beqz	a5,80003f4c <ialloc+0x9c>
    brelse(bp);
    80003f0e:	00000097          	auipc	ra,0x0
    80003f12:	a58080e7          	jalr	-1448(ra) # 80003966 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003f16:	0485                	addi	s1,s1,1
    80003f18:	00ca2703          	lw	a4,12(s4)
    80003f1c:	0004879b          	sext.w	a5,s1
    80003f20:	fce7e1e3          	bltu	a5,a4,80003ee2 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003f24:	00005517          	auipc	a0,0x5
    80003f28:	85c50513          	addi	a0,a0,-1956 # 80008780 <syscalls+0x198>
    80003f2c:	ffffc097          	auipc	ra,0xffffc
    80003f30:	65e080e7          	jalr	1630(ra) # 8000058a <printf>
  return 0;
    80003f34:	4501                	li	a0,0
}
    80003f36:	60a6                	ld	ra,72(sp)
    80003f38:	6406                	ld	s0,64(sp)
    80003f3a:	74e2                	ld	s1,56(sp)
    80003f3c:	7942                	ld	s2,48(sp)
    80003f3e:	79a2                	ld	s3,40(sp)
    80003f40:	7a02                	ld	s4,32(sp)
    80003f42:	6ae2                	ld	s5,24(sp)
    80003f44:	6b42                	ld	s6,16(sp)
    80003f46:	6ba2                	ld	s7,8(sp)
    80003f48:	6161                	addi	sp,sp,80
    80003f4a:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003f4c:	04000613          	li	a2,64
    80003f50:	4581                	li	a1,0
    80003f52:	854e                	mv	a0,s3
    80003f54:	ffffd097          	auipc	ra,0xffffd
    80003f58:	f48080e7          	jalr	-184(ra) # 80000e9c <memset>
      dip->type = type;
    80003f5c:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003f60:	854a                	mv	a0,s2
    80003f62:	00001097          	auipc	ra,0x1
    80003f66:	c8e080e7          	jalr	-882(ra) # 80004bf0 <log_write>
      brelse(bp);
    80003f6a:	854a                	mv	a0,s2
    80003f6c:	00000097          	auipc	ra,0x0
    80003f70:	9fa080e7          	jalr	-1542(ra) # 80003966 <brelse>
      return iget(dev, inum);
    80003f74:	85da                	mv	a1,s6
    80003f76:	8556                	mv	a0,s5
    80003f78:	00000097          	auipc	ra,0x0
    80003f7c:	d9c080e7          	jalr	-612(ra) # 80003d14 <iget>
    80003f80:	bf5d                	j	80003f36 <ialloc+0x86>

0000000080003f82 <iupdate>:
{
    80003f82:	1101                	addi	sp,sp,-32
    80003f84:	ec06                	sd	ra,24(sp)
    80003f86:	e822                	sd	s0,16(sp)
    80003f88:	e426                	sd	s1,8(sp)
    80003f8a:	e04a                	sd	s2,0(sp)
    80003f8c:	1000                	addi	s0,sp,32
    80003f8e:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003f90:	415c                	lw	a5,4(a0)
    80003f92:	0047d79b          	srliw	a5,a5,0x4
    80003f96:	0023c597          	auipc	a1,0x23c
    80003f9a:	5f25a583          	lw	a1,1522(a1) # 80240588 <sb+0x18>
    80003f9e:	9dbd                	addw	a1,a1,a5
    80003fa0:	4108                	lw	a0,0(a0)
    80003fa2:	00000097          	auipc	ra,0x0
    80003fa6:	894080e7          	jalr	-1900(ra) # 80003836 <bread>
    80003faa:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003fac:	05850793          	addi	a5,a0,88
    80003fb0:	40d8                	lw	a4,4(s1)
    80003fb2:	8b3d                	andi	a4,a4,15
    80003fb4:	071a                	slli	a4,a4,0x6
    80003fb6:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003fb8:	04449703          	lh	a4,68(s1)
    80003fbc:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003fc0:	04649703          	lh	a4,70(s1)
    80003fc4:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003fc8:	04849703          	lh	a4,72(s1)
    80003fcc:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003fd0:	04a49703          	lh	a4,74(s1)
    80003fd4:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003fd8:	44f8                	lw	a4,76(s1)
    80003fda:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003fdc:	03400613          	li	a2,52
    80003fe0:	05048593          	addi	a1,s1,80
    80003fe4:	00c78513          	addi	a0,a5,12
    80003fe8:	ffffd097          	auipc	ra,0xffffd
    80003fec:	f10080e7          	jalr	-240(ra) # 80000ef8 <memmove>
  log_write(bp);
    80003ff0:	854a                	mv	a0,s2
    80003ff2:	00001097          	auipc	ra,0x1
    80003ff6:	bfe080e7          	jalr	-1026(ra) # 80004bf0 <log_write>
  brelse(bp);
    80003ffa:	854a                	mv	a0,s2
    80003ffc:	00000097          	auipc	ra,0x0
    80004000:	96a080e7          	jalr	-1686(ra) # 80003966 <brelse>
}
    80004004:	60e2                	ld	ra,24(sp)
    80004006:	6442                	ld	s0,16(sp)
    80004008:	64a2                	ld	s1,8(sp)
    8000400a:	6902                	ld	s2,0(sp)
    8000400c:	6105                	addi	sp,sp,32
    8000400e:	8082                	ret

0000000080004010 <idup>:
{
    80004010:	1101                	addi	sp,sp,-32
    80004012:	ec06                	sd	ra,24(sp)
    80004014:	e822                	sd	s0,16(sp)
    80004016:	e426                	sd	s1,8(sp)
    80004018:	1000                	addi	s0,sp,32
    8000401a:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000401c:	0023c517          	auipc	a0,0x23c
    80004020:	57450513          	addi	a0,a0,1396 # 80240590 <itable>
    80004024:	ffffd097          	auipc	ra,0xffffd
    80004028:	d7c080e7          	jalr	-644(ra) # 80000da0 <acquire>
  ip->ref++;
    8000402c:	449c                	lw	a5,8(s1)
    8000402e:	2785                	addiw	a5,a5,1
    80004030:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80004032:	0023c517          	auipc	a0,0x23c
    80004036:	55e50513          	addi	a0,a0,1374 # 80240590 <itable>
    8000403a:	ffffd097          	auipc	ra,0xffffd
    8000403e:	e1a080e7          	jalr	-486(ra) # 80000e54 <release>
}
    80004042:	8526                	mv	a0,s1
    80004044:	60e2                	ld	ra,24(sp)
    80004046:	6442                	ld	s0,16(sp)
    80004048:	64a2                	ld	s1,8(sp)
    8000404a:	6105                	addi	sp,sp,32
    8000404c:	8082                	ret

000000008000404e <ilock>:
{
    8000404e:	1101                	addi	sp,sp,-32
    80004050:	ec06                	sd	ra,24(sp)
    80004052:	e822                	sd	s0,16(sp)
    80004054:	e426                	sd	s1,8(sp)
    80004056:	e04a                	sd	s2,0(sp)
    80004058:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    8000405a:	c115                	beqz	a0,8000407e <ilock+0x30>
    8000405c:	84aa                	mv	s1,a0
    8000405e:	451c                	lw	a5,8(a0)
    80004060:	00f05f63          	blez	a5,8000407e <ilock+0x30>
  acquiresleep(&ip->lock);
    80004064:	0541                	addi	a0,a0,16
    80004066:	00001097          	auipc	ra,0x1
    8000406a:	ca8080e7          	jalr	-856(ra) # 80004d0e <acquiresleep>
  if(ip->valid == 0){
    8000406e:	40bc                	lw	a5,64(s1)
    80004070:	cf99                	beqz	a5,8000408e <ilock+0x40>
}
    80004072:	60e2                	ld	ra,24(sp)
    80004074:	6442                	ld	s0,16(sp)
    80004076:	64a2                	ld	s1,8(sp)
    80004078:	6902                	ld	s2,0(sp)
    8000407a:	6105                	addi	sp,sp,32
    8000407c:	8082                	ret
    panic("ilock");
    8000407e:	00004517          	auipc	a0,0x4
    80004082:	71a50513          	addi	a0,a0,1818 # 80008798 <syscalls+0x1b0>
    80004086:	ffffc097          	auipc	ra,0xffffc
    8000408a:	4ba080e7          	jalr	1210(ra) # 80000540 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000408e:	40dc                	lw	a5,4(s1)
    80004090:	0047d79b          	srliw	a5,a5,0x4
    80004094:	0023c597          	auipc	a1,0x23c
    80004098:	4f45a583          	lw	a1,1268(a1) # 80240588 <sb+0x18>
    8000409c:	9dbd                	addw	a1,a1,a5
    8000409e:	4088                	lw	a0,0(s1)
    800040a0:	fffff097          	auipc	ra,0xfffff
    800040a4:	796080e7          	jalr	1942(ra) # 80003836 <bread>
    800040a8:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800040aa:	05850593          	addi	a1,a0,88
    800040ae:	40dc                	lw	a5,4(s1)
    800040b0:	8bbd                	andi	a5,a5,15
    800040b2:	079a                	slli	a5,a5,0x6
    800040b4:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800040b6:	00059783          	lh	a5,0(a1)
    800040ba:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800040be:	00259783          	lh	a5,2(a1)
    800040c2:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800040c6:	00459783          	lh	a5,4(a1)
    800040ca:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800040ce:	00659783          	lh	a5,6(a1)
    800040d2:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800040d6:	459c                	lw	a5,8(a1)
    800040d8:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800040da:	03400613          	li	a2,52
    800040de:	05b1                	addi	a1,a1,12
    800040e0:	05048513          	addi	a0,s1,80
    800040e4:	ffffd097          	auipc	ra,0xffffd
    800040e8:	e14080e7          	jalr	-492(ra) # 80000ef8 <memmove>
    brelse(bp);
    800040ec:	854a                	mv	a0,s2
    800040ee:	00000097          	auipc	ra,0x0
    800040f2:	878080e7          	jalr	-1928(ra) # 80003966 <brelse>
    ip->valid = 1;
    800040f6:	4785                	li	a5,1
    800040f8:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800040fa:	04449783          	lh	a5,68(s1)
    800040fe:	fbb5                	bnez	a5,80004072 <ilock+0x24>
      panic("ilock: no type");
    80004100:	00004517          	auipc	a0,0x4
    80004104:	6a050513          	addi	a0,a0,1696 # 800087a0 <syscalls+0x1b8>
    80004108:	ffffc097          	auipc	ra,0xffffc
    8000410c:	438080e7          	jalr	1080(ra) # 80000540 <panic>

0000000080004110 <iunlock>:
{
    80004110:	1101                	addi	sp,sp,-32
    80004112:	ec06                	sd	ra,24(sp)
    80004114:	e822                	sd	s0,16(sp)
    80004116:	e426                	sd	s1,8(sp)
    80004118:	e04a                	sd	s2,0(sp)
    8000411a:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    8000411c:	c905                	beqz	a0,8000414c <iunlock+0x3c>
    8000411e:	84aa                	mv	s1,a0
    80004120:	01050913          	addi	s2,a0,16
    80004124:	854a                	mv	a0,s2
    80004126:	00001097          	auipc	ra,0x1
    8000412a:	c82080e7          	jalr	-894(ra) # 80004da8 <holdingsleep>
    8000412e:	cd19                	beqz	a0,8000414c <iunlock+0x3c>
    80004130:	449c                	lw	a5,8(s1)
    80004132:	00f05d63          	blez	a5,8000414c <iunlock+0x3c>
  releasesleep(&ip->lock);
    80004136:	854a                	mv	a0,s2
    80004138:	00001097          	auipc	ra,0x1
    8000413c:	c2c080e7          	jalr	-980(ra) # 80004d64 <releasesleep>
}
    80004140:	60e2                	ld	ra,24(sp)
    80004142:	6442                	ld	s0,16(sp)
    80004144:	64a2                	ld	s1,8(sp)
    80004146:	6902                	ld	s2,0(sp)
    80004148:	6105                	addi	sp,sp,32
    8000414a:	8082                	ret
    panic("iunlock");
    8000414c:	00004517          	auipc	a0,0x4
    80004150:	66450513          	addi	a0,a0,1636 # 800087b0 <syscalls+0x1c8>
    80004154:	ffffc097          	auipc	ra,0xffffc
    80004158:	3ec080e7          	jalr	1004(ra) # 80000540 <panic>

000000008000415c <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    8000415c:	7179                	addi	sp,sp,-48
    8000415e:	f406                	sd	ra,40(sp)
    80004160:	f022                	sd	s0,32(sp)
    80004162:	ec26                	sd	s1,24(sp)
    80004164:	e84a                	sd	s2,16(sp)
    80004166:	e44e                	sd	s3,8(sp)
    80004168:	e052                	sd	s4,0(sp)
    8000416a:	1800                	addi	s0,sp,48
    8000416c:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    8000416e:	05050493          	addi	s1,a0,80
    80004172:	08050913          	addi	s2,a0,128
    80004176:	a021                	j	8000417e <itrunc+0x22>
    80004178:	0491                	addi	s1,s1,4
    8000417a:	01248d63          	beq	s1,s2,80004194 <itrunc+0x38>
    if(ip->addrs[i]){
    8000417e:	408c                	lw	a1,0(s1)
    80004180:	dde5                	beqz	a1,80004178 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80004182:	0009a503          	lw	a0,0(s3)
    80004186:	00000097          	auipc	ra,0x0
    8000418a:	8f6080e7          	jalr	-1802(ra) # 80003a7c <bfree>
      ip->addrs[i] = 0;
    8000418e:	0004a023          	sw	zero,0(s1)
    80004192:	b7dd                	j	80004178 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80004194:	0809a583          	lw	a1,128(s3)
    80004198:	e185                	bnez	a1,800041b8 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    8000419a:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    8000419e:	854e                	mv	a0,s3
    800041a0:	00000097          	auipc	ra,0x0
    800041a4:	de2080e7          	jalr	-542(ra) # 80003f82 <iupdate>
}
    800041a8:	70a2                	ld	ra,40(sp)
    800041aa:	7402                	ld	s0,32(sp)
    800041ac:	64e2                	ld	s1,24(sp)
    800041ae:	6942                	ld	s2,16(sp)
    800041b0:	69a2                	ld	s3,8(sp)
    800041b2:	6a02                	ld	s4,0(sp)
    800041b4:	6145                	addi	sp,sp,48
    800041b6:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800041b8:	0009a503          	lw	a0,0(s3)
    800041bc:	fffff097          	auipc	ra,0xfffff
    800041c0:	67a080e7          	jalr	1658(ra) # 80003836 <bread>
    800041c4:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800041c6:	05850493          	addi	s1,a0,88
    800041ca:	45850913          	addi	s2,a0,1112
    800041ce:	a021                	j	800041d6 <itrunc+0x7a>
    800041d0:	0491                	addi	s1,s1,4
    800041d2:	01248b63          	beq	s1,s2,800041e8 <itrunc+0x8c>
      if(a[j])
    800041d6:	408c                	lw	a1,0(s1)
    800041d8:	dde5                	beqz	a1,800041d0 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    800041da:	0009a503          	lw	a0,0(s3)
    800041de:	00000097          	auipc	ra,0x0
    800041e2:	89e080e7          	jalr	-1890(ra) # 80003a7c <bfree>
    800041e6:	b7ed                	j	800041d0 <itrunc+0x74>
    brelse(bp);
    800041e8:	8552                	mv	a0,s4
    800041ea:	fffff097          	auipc	ra,0xfffff
    800041ee:	77c080e7          	jalr	1916(ra) # 80003966 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800041f2:	0809a583          	lw	a1,128(s3)
    800041f6:	0009a503          	lw	a0,0(s3)
    800041fa:	00000097          	auipc	ra,0x0
    800041fe:	882080e7          	jalr	-1918(ra) # 80003a7c <bfree>
    ip->addrs[NDIRECT] = 0;
    80004202:	0809a023          	sw	zero,128(s3)
    80004206:	bf51                	j	8000419a <itrunc+0x3e>

0000000080004208 <iput>:
{
    80004208:	1101                	addi	sp,sp,-32
    8000420a:	ec06                	sd	ra,24(sp)
    8000420c:	e822                	sd	s0,16(sp)
    8000420e:	e426                	sd	s1,8(sp)
    80004210:	e04a                	sd	s2,0(sp)
    80004212:	1000                	addi	s0,sp,32
    80004214:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80004216:	0023c517          	auipc	a0,0x23c
    8000421a:	37a50513          	addi	a0,a0,890 # 80240590 <itable>
    8000421e:	ffffd097          	auipc	ra,0xffffd
    80004222:	b82080e7          	jalr	-1150(ra) # 80000da0 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004226:	4498                	lw	a4,8(s1)
    80004228:	4785                	li	a5,1
    8000422a:	02f70363          	beq	a4,a5,80004250 <iput+0x48>
  ip->ref--;
    8000422e:	449c                	lw	a5,8(s1)
    80004230:	37fd                	addiw	a5,a5,-1
    80004232:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80004234:	0023c517          	auipc	a0,0x23c
    80004238:	35c50513          	addi	a0,a0,860 # 80240590 <itable>
    8000423c:	ffffd097          	auipc	ra,0xffffd
    80004240:	c18080e7          	jalr	-1000(ra) # 80000e54 <release>
}
    80004244:	60e2                	ld	ra,24(sp)
    80004246:	6442                	ld	s0,16(sp)
    80004248:	64a2                	ld	s1,8(sp)
    8000424a:	6902                	ld	s2,0(sp)
    8000424c:	6105                	addi	sp,sp,32
    8000424e:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004250:	40bc                	lw	a5,64(s1)
    80004252:	dff1                	beqz	a5,8000422e <iput+0x26>
    80004254:	04a49783          	lh	a5,74(s1)
    80004258:	fbf9                	bnez	a5,8000422e <iput+0x26>
    acquiresleep(&ip->lock);
    8000425a:	01048913          	addi	s2,s1,16
    8000425e:	854a                	mv	a0,s2
    80004260:	00001097          	auipc	ra,0x1
    80004264:	aae080e7          	jalr	-1362(ra) # 80004d0e <acquiresleep>
    release(&itable.lock);
    80004268:	0023c517          	auipc	a0,0x23c
    8000426c:	32850513          	addi	a0,a0,808 # 80240590 <itable>
    80004270:	ffffd097          	auipc	ra,0xffffd
    80004274:	be4080e7          	jalr	-1052(ra) # 80000e54 <release>
    itrunc(ip);
    80004278:	8526                	mv	a0,s1
    8000427a:	00000097          	auipc	ra,0x0
    8000427e:	ee2080e7          	jalr	-286(ra) # 8000415c <itrunc>
    ip->type = 0;
    80004282:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80004286:	8526                	mv	a0,s1
    80004288:	00000097          	auipc	ra,0x0
    8000428c:	cfa080e7          	jalr	-774(ra) # 80003f82 <iupdate>
    ip->valid = 0;
    80004290:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80004294:	854a                	mv	a0,s2
    80004296:	00001097          	auipc	ra,0x1
    8000429a:	ace080e7          	jalr	-1330(ra) # 80004d64 <releasesleep>
    acquire(&itable.lock);
    8000429e:	0023c517          	auipc	a0,0x23c
    800042a2:	2f250513          	addi	a0,a0,754 # 80240590 <itable>
    800042a6:	ffffd097          	auipc	ra,0xffffd
    800042aa:	afa080e7          	jalr	-1286(ra) # 80000da0 <acquire>
    800042ae:	b741                	j	8000422e <iput+0x26>

00000000800042b0 <iunlockput>:
{
    800042b0:	1101                	addi	sp,sp,-32
    800042b2:	ec06                	sd	ra,24(sp)
    800042b4:	e822                	sd	s0,16(sp)
    800042b6:	e426                	sd	s1,8(sp)
    800042b8:	1000                	addi	s0,sp,32
    800042ba:	84aa                	mv	s1,a0
  iunlock(ip);
    800042bc:	00000097          	auipc	ra,0x0
    800042c0:	e54080e7          	jalr	-428(ra) # 80004110 <iunlock>
  iput(ip);
    800042c4:	8526                	mv	a0,s1
    800042c6:	00000097          	auipc	ra,0x0
    800042ca:	f42080e7          	jalr	-190(ra) # 80004208 <iput>
}
    800042ce:	60e2                	ld	ra,24(sp)
    800042d0:	6442                	ld	s0,16(sp)
    800042d2:	64a2                	ld	s1,8(sp)
    800042d4:	6105                	addi	sp,sp,32
    800042d6:	8082                	ret

00000000800042d8 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800042d8:	1141                	addi	sp,sp,-16
    800042da:	e422                	sd	s0,8(sp)
    800042dc:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800042de:	411c                	lw	a5,0(a0)
    800042e0:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800042e2:	415c                	lw	a5,4(a0)
    800042e4:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800042e6:	04451783          	lh	a5,68(a0)
    800042ea:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800042ee:	04a51783          	lh	a5,74(a0)
    800042f2:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800042f6:	04c56783          	lwu	a5,76(a0)
    800042fa:	e99c                	sd	a5,16(a1)
}
    800042fc:	6422                	ld	s0,8(sp)
    800042fe:	0141                	addi	sp,sp,16
    80004300:	8082                	ret

0000000080004302 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004302:	457c                	lw	a5,76(a0)
    80004304:	0ed7e963          	bltu	a5,a3,800043f6 <readi+0xf4>
{
    80004308:	7159                	addi	sp,sp,-112
    8000430a:	f486                	sd	ra,104(sp)
    8000430c:	f0a2                	sd	s0,96(sp)
    8000430e:	eca6                	sd	s1,88(sp)
    80004310:	e8ca                	sd	s2,80(sp)
    80004312:	e4ce                	sd	s3,72(sp)
    80004314:	e0d2                	sd	s4,64(sp)
    80004316:	fc56                	sd	s5,56(sp)
    80004318:	f85a                	sd	s6,48(sp)
    8000431a:	f45e                	sd	s7,40(sp)
    8000431c:	f062                	sd	s8,32(sp)
    8000431e:	ec66                	sd	s9,24(sp)
    80004320:	e86a                	sd	s10,16(sp)
    80004322:	e46e                	sd	s11,8(sp)
    80004324:	1880                	addi	s0,sp,112
    80004326:	8b2a                	mv	s6,a0
    80004328:	8bae                	mv	s7,a1
    8000432a:	8a32                	mv	s4,a2
    8000432c:	84b6                	mv	s1,a3
    8000432e:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80004330:	9f35                	addw	a4,a4,a3
    return 0;
    80004332:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80004334:	0ad76063          	bltu	a4,a3,800043d4 <readi+0xd2>
  if(off + n > ip->size)
    80004338:	00e7f463          	bgeu	a5,a4,80004340 <readi+0x3e>
    n = ip->size - off;
    8000433c:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004340:	0a0a8963          	beqz	s5,800043f2 <readi+0xf0>
    80004344:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80004346:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    8000434a:	5c7d                	li	s8,-1
    8000434c:	a82d                	j	80004386 <readi+0x84>
    8000434e:	020d1d93          	slli	s11,s10,0x20
    80004352:	020ddd93          	srli	s11,s11,0x20
    80004356:	05890613          	addi	a2,s2,88
    8000435a:	86ee                	mv	a3,s11
    8000435c:	963a                	add	a2,a2,a4
    8000435e:	85d2                	mv	a1,s4
    80004360:	855e                	mv	a0,s7
    80004362:	ffffe097          	auipc	ra,0xffffe
    80004366:	41e080e7          	jalr	1054(ra) # 80002780 <either_copyout>
    8000436a:	05850d63          	beq	a0,s8,800043c4 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    8000436e:	854a                	mv	a0,s2
    80004370:	fffff097          	auipc	ra,0xfffff
    80004374:	5f6080e7          	jalr	1526(ra) # 80003966 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004378:	013d09bb          	addw	s3,s10,s3
    8000437c:	009d04bb          	addw	s1,s10,s1
    80004380:	9a6e                	add	s4,s4,s11
    80004382:	0559f763          	bgeu	s3,s5,800043d0 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80004386:	00a4d59b          	srliw	a1,s1,0xa
    8000438a:	855a                	mv	a0,s6
    8000438c:	00000097          	auipc	ra,0x0
    80004390:	89e080e7          	jalr	-1890(ra) # 80003c2a <bmap>
    80004394:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80004398:	cd85                	beqz	a1,800043d0 <readi+0xce>
    bp = bread(ip->dev, addr);
    8000439a:	000b2503          	lw	a0,0(s6)
    8000439e:	fffff097          	auipc	ra,0xfffff
    800043a2:	498080e7          	jalr	1176(ra) # 80003836 <bread>
    800043a6:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800043a8:	3ff4f713          	andi	a4,s1,1023
    800043ac:	40ec87bb          	subw	a5,s9,a4
    800043b0:	413a86bb          	subw	a3,s5,s3
    800043b4:	8d3e                	mv	s10,a5
    800043b6:	2781                	sext.w	a5,a5
    800043b8:	0006861b          	sext.w	a2,a3
    800043bc:	f8f679e3          	bgeu	a2,a5,8000434e <readi+0x4c>
    800043c0:	8d36                	mv	s10,a3
    800043c2:	b771                	j	8000434e <readi+0x4c>
      brelse(bp);
    800043c4:	854a                	mv	a0,s2
    800043c6:	fffff097          	auipc	ra,0xfffff
    800043ca:	5a0080e7          	jalr	1440(ra) # 80003966 <brelse>
      tot = -1;
    800043ce:	59fd                	li	s3,-1
  }
  return tot;
    800043d0:	0009851b          	sext.w	a0,s3
}
    800043d4:	70a6                	ld	ra,104(sp)
    800043d6:	7406                	ld	s0,96(sp)
    800043d8:	64e6                	ld	s1,88(sp)
    800043da:	6946                	ld	s2,80(sp)
    800043dc:	69a6                	ld	s3,72(sp)
    800043de:	6a06                	ld	s4,64(sp)
    800043e0:	7ae2                	ld	s5,56(sp)
    800043e2:	7b42                	ld	s6,48(sp)
    800043e4:	7ba2                	ld	s7,40(sp)
    800043e6:	7c02                	ld	s8,32(sp)
    800043e8:	6ce2                	ld	s9,24(sp)
    800043ea:	6d42                	ld	s10,16(sp)
    800043ec:	6da2                	ld	s11,8(sp)
    800043ee:	6165                	addi	sp,sp,112
    800043f0:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800043f2:	89d6                	mv	s3,s5
    800043f4:	bff1                	j	800043d0 <readi+0xce>
    return 0;
    800043f6:	4501                	li	a0,0
}
    800043f8:	8082                	ret

00000000800043fa <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800043fa:	457c                	lw	a5,76(a0)
    800043fc:	10d7e863          	bltu	a5,a3,8000450c <writei+0x112>
{
    80004400:	7159                	addi	sp,sp,-112
    80004402:	f486                	sd	ra,104(sp)
    80004404:	f0a2                	sd	s0,96(sp)
    80004406:	eca6                	sd	s1,88(sp)
    80004408:	e8ca                	sd	s2,80(sp)
    8000440a:	e4ce                	sd	s3,72(sp)
    8000440c:	e0d2                	sd	s4,64(sp)
    8000440e:	fc56                	sd	s5,56(sp)
    80004410:	f85a                	sd	s6,48(sp)
    80004412:	f45e                	sd	s7,40(sp)
    80004414:	f062                	sd	s8,32(sp)
    80004416:	ec66                	sd	s9,24(sp)
    80004418:	e86a                	sd	s10,16(sp)
    8000441a:	e46e                	sd	s11,8(sp)
    8000441c:	1880                	addi	s0,sp,112
    8000441e:	8aaa                	mv	s5,a0
    80004420:	8bae                	mv	s7,a1
    80004422:	8a32                	mv	s4,a2
    80004424:	8936                	mv	s2,a3
    80004426:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80004428:	00e687bb          	addw	a5,a3,a4
    8000442c:	0ed7e263          	bltu	a5,a3,80004510 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80004430:	00043737          	lui	a4,0x43
    80004434:	0ef76063          	bltu	a4,a5,80004514 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004438:	0c0b0863          	beqz	s6,80004508 <writei+0x10e>
    8000443c:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    8000443e:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80004442:	5c7d                	li	s8,-1
    80004444:	a091                	j	80004488 <writei+0x8e>
    80004446:	020d1d93          	slli	s11,s10,0x20
    8000444a:	020ddd93          	srli	s11,s11,0x20
    8000444e:	05848513          	addi	a0,s1,88
    80004452:	86ee                	mv	a3,s11
    80004454:	8652                	mv	a2,s4
    80004456:	85de                	mv	a1,s7
    80004458:	953a                	add	a0,a0,a4
    8000445a:	ffffe097          	auipc	ra,0xffffe
    8000445e:	37c080e7          	jalr	892(ra) # 800027d6 <either_copyin>
    80004462:	07850263          	beq	a0,s8,800044c6 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004466:	8526                	mv	a0,s1
    80004468:	00000097          	auipc	ra,0x0
    8000446c:	788080e7          	jalr	1928(ra) # 80004bf0 <log_write>
    brelse(bp);
    80004470:	8526                	mv	a0,s1
    80004472:	fffff097          	auipc	ra,0xfffff
    80004476:	4f4080e7          	jalr	1268(ra) # 80003966 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000447a:	013d09bb          	addw	s3,s10,s3
    8000447e:	012d093b          	addw	s2,s10,s2
    80004482:	9a6e                	add	s4,s4,s11
    80004484:	0569f663          	bgeu	s3,s6,800044d0 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80004488:	00a9559b          	srliw	a1,s2,0xa
    8000448c:	8556                	mv	a0,s5
    8000448e:	fffff097          	auipc	ra,0xfffff
    80004492:	79c080e7          	jalr	1948(ra) # 80003c2a <bmap>
    80004496:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    8000449a:	c99d                	beqz	a1,800044d0 <writei+0xd6>
    bp = bread(ip->dev, addr);
    8000449c:	000aa503          	lw	a0,0(s5)
    800044a0:	fffff097          	auipc	ra,0xfffff
    800044a4:	396080e7          	jalr	918(ra) # 80003836 <bread>
    800044a8:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800044aa:	3ff97713          	andi	a4,s2,1023
    800044ae:	40ec87bb          	subw	a5,s9,a4
    800044b2:	413b06bb          	subw	a3,s6,s3
    800044b6:	8d3e                	mv	s10,a5
    800044b8:	2781                	sext.w	a5,a5
    800044ba:	0006861b          	sext.w	a2,a3
    800044be:	f8f674e3          	bgeu	a2,a5,80004446 <writei+0x4c>
    800044c2:	8d36                	mv	s10,a3
    800044c4:	b749                	j	80004446 <writei+0x4c>
      brelse(bp);
    800044c6:	8526                	mv	a0,s1
    800044c8:	fffff097          	auipc	ra,0xfffff
    800044cc:	49e080e7          	jalr	1182(ra) # 80003966 <brelse>
  }

  if(off > ip->size)
    800044d0:	04caa783          	lw	a5,76(s5)
    800044d4:	0127f463          	bgeu	a5,s2,800044dc <writei+0xe2>
    ip->size = off;
    800044d8:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    800044dc:	8556                	mv	a0,s5
    800044de:	00000097          	auipc	ra,0x0
    800044e2:	aa4080e7          	jalr	-1372(ra) # 80003f82 <iupdate>

  return tot;
    800044e6:	0009851b          	sext.w	a0,s3
}
    800044ea:	70a6                	ld	ra,104(sp)
    800044ec:	7406                	ld	s0,96(sp)
    800044ee:	64e6                	ld	s1,88(sp)
    800044f0:	6946                	ld	s2,80(sp)
    800044f2:	69a6                	ld	s3,72(sp)
    800044f4:	6a06                	ld	s4,64(sp)
    800044f6:	7ae2                	ld	s5,56(sp)
    800044f8:	7b42                	ld	s6,48(sp)
    800044fa:	7ba2                	ld	s7,40(sp)
    800044fc:	7c02                	ld	s8,32(sp)
    800044fe:	6ce2                	ld	s9,24(sp)
    80004500:	6d42                	ld	s10,16(sp)
    80004502:	6da2                	ld	s11,8(sp)
    80004504:	6165                	addi	sp,sp,112
    80004506:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004508:	89da                	mv	s3,s6
    8000450a:	bfc9                	j	800044dc <writei+0xe2>
    return -1;
    8000450c:	557d                	li	a0,-1
}
    8000450e:	8082                	ret
    return -1;
    80004510:	557d                	li	a0,-1
    80004512:	bfe1                	j	800044ea <writei+0xf0>
    return -1;
    80004514:	557d                	li	a0,-1
    80004516:	bfd1                	j	800044ea <writei+0xf0>

0000000080004518 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004518:	1141                	addi	sp,sp,-16
    8000451a:	e406                	sd	ra,8(sp)
    8000451c:	e022                	sd	s0,0(sp)
    8000451e:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004520:	4639                	li	a2,14
    80004522:	ffffd097          	auipc	ra,0xffffd
    80004526:	a4a080e7          	jalr	-1462(ra) # 80000f6c <strncmp>
}
    8000452a:	60a2                	ld	ra,8(sp)
    8000452c:	6402                	ld	s0,0(sp)
    8000452e:	0141                	addi	sp,sp,16
    80004530:	8082                	ret

0000000080004532 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004532:	7139                	addi	sp,sp,-64
    80004534:	fc06                	sd	ra,56(sp)
    80004536:	f822                	sd	s0,48(sp)
    80004538:	f426                	sd	s1,40(sp)
    8000453a:	f04a                	sd	s2,32(sp)
    8000453c:	ec4e                	sd	s3,24(sp)
    8000453e:	e852                	sd	s4,16(sp)
    80004540:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004542:	04451703          	lh	a4,68(a0)
    80004546:	4785                	li	a5,1
    80004548:	00f71a63          	bne	a4,a5,8000455c <dirlookup+0x2a>
    8000454c:	892a                	mv	s2,a0
    8000454e:	89ae                	mv	s3,a1
    80004550:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004552:	457c                	lw	a5,76(a0)
    80004554:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004556:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004558:	e79d                	bnez	a5,80004586 <dirlookup+0x54>
    8000455a:	a8a5                	j	800045d2 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    8000455c:	00004517          	auipc	a0,0x4
    80004560:	25c50513          	addi	a0,a0,604 # 800087b8 <syscalls+0x1d0>
    80004564:	ffffc097          	auipc	ra,0xffffc
    80004568:	fdc080e7          	jalr	-36(ra) # 80000540 <panic>
      panic("dirlookup read");
    8000456c:	00004517          	auipc	a0,0x4
    80004570:	26450513          	addi	a0,a0,612 # 800087d0 <syscalls+0x1e8>
    80004574:	ffffc097          	auipc	ra,0xffffc
    80004578:	fcc080e7          	jalr	-52(ra) # 80000540 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000457c:	24c1                	addiw	s1,s1,16
    8000457e:	04c92783          	lw	a5,76(s2)
    80004582:	04f4f763          	bgeu	s1,a5,800045d0 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004586:	4741                	li	a4,16
    80004588:	86a6                	mv	a3,s1
    8000458a:	fc040613          	addi	a2,s0,-64
    8000458e:	4581                	li	a1,0
    80004590:	854a                	mv	a0,s2
    80004592:	00000097          	auipc	ra,0x0
    80004596:	d70080e7          	jalr	-656(ra) # 80004302 <readi>
    8000459a:	47c1                	li	a5,16
    8000459c:	fcf518e3          	bne	a0,a5,8000456c <dirlookup+0x3a>
    if(de.inum == 0)
    800045a0:	fc045783          	lhu	a5,-64(s0)
    800045a4:	dfe1                	beqz	a5,8000457c <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    800045a6:	fc240593          	addi	a1,s0,-62
    800045aa:	854e                	mv	a0,s3
    800045ac:	00000097          	auipc	ra,0x0
    800045b0:	f6c080e7          	jalr	-148(ra) # 80004518 <namecmp>
    800045b4:	f561                	bnez	a0,8000457c <dirlookup+0x4a>
      if(poff)
    800045b6:	000a0463          	beqz	s4,800045be <dirlookup+0x8c>
        *poff = off;
    800045ba:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800045be:	fc045583          	lhu	a1,-64(s0)
    800045c2:	00092503          	lw	a0,0(s2)
    800045c6:	fffff097          	auipc	ra,0xfffff
    800045ca:	74e080e7          	jalr	1870(ra) # 80003d14 <iget>
    800045ce:	a011                	j	800045d2 <dirlookup+0xa0>
  return 0;
    800045d0:	4501                	li	a0,0
}
    800045d2:	70e2                	ld	ra,56(sp)
    800045d4:	7442                	ld	s0,48(sp)
    800045d6:	74a2                	ld	s1,40(sp)
    800045d8:	7902                	ld	s2,32(sp)
    800045da:	69e2                	ld	s3,24(sp)
    800045dc:	6a42                	ld	s4,16(sp)
    800045de:	6121                	addi	sp,sp,64
    800045e0:	8082                	ret

00000000800045e2 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800045e2:	711d                	addi	sp,sp,-96
    800045e4:	ec86                	sd	ra,88(sp)
    800045e6:	e8a2                	sd	s0,80(sp)
    800045e8:	e4a6                	sd	s1,72(sp)
    800045ea:	e0ca                	sd	s2,64(sp)
    800045ec:	fc4e                	sd	s3,56(sp)
    800045ee:	f852                	sd	s4,48(sp)
    800045f0:	f456                	sd	s5,40(sp)
    800045f2:	f05a                	sd	s6,32(sp)
    800045f4:	ec5e                	sd	s7,24(sp)
    800045f6:	e862                	sd	s8,16(sp)
    800045f8:	e466                	sd	s9,8(sp)
    800045fa:	e06a                	sd	s10,0(sp)
    800045fc:	1080                	addi	s0,sp,96
    800045fe:	84aa                	mv	s1,a0
    80004600:	8b2e                	mv	s6,a1
    80004602:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004604:	00054703          	lbu	a4,0(a0)
    80004608:	02f00793          	li	a5,47
    8000460c:	02f70363          	beq	a4,a5,80004632 <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004610:	ffffd097          	auipc	ra,0xffffd
    80004614:	5a4080e7          	jalr	1444(ra) # 80001bb4 <myproc>
    80004618:	15053503          	ld	a0,336(a0)
    8000461c:	00000097          	auipc	ra,0x0
    80004620:	9f4080e7          	jalr	-1548(ra) # 80004010 <idup>
    80004624:	8a2a                	mv	s4,a0
  while(*path == '/')
    80004626:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    8000462a:	4cb5                	li	s9,13
  len = path - s;
    8000462c:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    8000462e:	4c05                	li	s8,1
    80004630:	a87d                	j	800046ee <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    80004632:	4585                	li	a1,1
    80004634:	4505                	li	a0,1
    80004636:	fffff097          	auipc	ra,0xfffff
    8000463a:	6de080e7          	jalr	1758(ra) # 80003d14 <iget>
    8000463e:	8a2a                	mv	s4,a0
    80004640:	b7dd                	j	80004626 <namex+0x44>
      iunlockput(ip);
    80004642:	8552                	mv	a0,s4
    80004644:	00000097          	auipc	ra,0x0
    80004648:	c6c080e7          	jalr	-916(ra) # 800042b0 <iunlockput>
      return 0;
    8000464c:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    8000464e:	8552                	mv	a0,s4
    80004650:	60e6                	ld	ra,88(sp)
    80004652:	6446                	ld	s0,80(sp)
    80004654:	64a6                	ld	s1,72(sp)
    80004656:	6906                	ld	s2,64(sp)
    80004658:	79e2                	ld	s3,56(sp)
    8000465a:	7a42                	ld	s4,48(sp)
    8000465c:	7aa2                	ld	s5,40(sp)
    8000465e:	7b02                	ld	s6,32(sp)
    80004660:	6be2                	ld	s7,24(sp)
    80004662:	6c42                	ld	s8,16(sp)
    80004664:	6ca2                	ld	s9,8(sp)
    80004666:	6d02                	ld	s10,0(sp)
    80004668:	6125                	addi	sp,sp,96
    8000466a:	8082                	ret
      iunlock(ip);
    8000466c:	8552                	mv	a0,s4
    8000466e:	00000097          	auipc	ra,0x0
    80004672:	aa2080e7          	jalr	-1374(ra) # 80004110 <iunlock>
      return ip;
    80004676:	bfe1                	j	8000464e <namex+0x6c>
      iunlockput(ip);
    80004678:	8552                	mv	a0,s4
    8000467a:	00000097          	auipc	ra,0x0
    8000467e:	c36080e7          	jalr	-970(ra) # 800042b0 <iunlockput>
      return 0;
    80004682:	8a4e                	mv	s4,s3
    80004684:	b7e9                	j	8000464e <namex+0x6c>
  len = path - s;
    80004686:	40998633          	sub	a2,s3,s1
    8000468a:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    8000468e:	09acd863          	bge	s9,s10,8000471e <namex+0x13c>
    memmove(name, s, DIRSIZ);
    80004692:	4639                	li	a2,14
    80004694:	85a6                	mv	a1,s1
    80004696:	8556                	mv	a0,s5
    80004698:	ffffd097          	auipc	ra,0xffffd
    8000469c:	860080e7          	jalr	-1952(ra) # 80000ef8 <memmove>
    800046a0:	84ce                	mv	s1,s3
  while(*path == '/')
    800046a2:	0004c783          	lbu	a5,0(s1)
    800046a6:	01279763          	bne	a5,s2,800046b4 <namex+0xd2>
    path++;
    800046aa:	0485                	addi	s1,s1,1
  while(*path == '/')
    800046ac:	0004c783          	lbu	a5,0(s1)
    800046b0:	ff278de3          	beq	a5,s2,800046aa <namex+0xc8>
    ilock(ip);
    800046b4:	8552                	mv	a0,s4
    800046b6:	00000097          	auipc	ra,0x0
    800046ba:	998080e7          	jalr	-1640(ra) # 8000404e <ilock>
    if(ip->type != T_DIR){
    800046be:	044a1783          	lh	a5,68(s4)
    800046c2:	f98790e3          	bne	a5,s8,80004642 <namex+0x60>
    if(nameiparent && *path == '\0'){
    800046c6:	000b0563          	beqz	s6,800046d0 <namex+0xee>
    800046ca:	0004c783          	lbu	a5,0(s1)
    800046ce:	dfd9                	beqz	a5,8000466c <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    800046d0:	865e                	mv	a2,s7
    800046d2:	85d6                	mv	a1,s5
    800046d4:	8552                	mv	a0,s4
    800046d6:	00000097          	auipc	ra,0x0
    800046da:	e5c080e7          	jalr	-420(ra) # 80004532 <dirlookup>
    800046de:	89aa                	mv	s3,a0
    800046e0:	dd41                	beqz	a0,80004678 <namex+0x96>
    iunlockput(ip);
    800046e2:	8552                	mv	a0,s4
    800046e4:	00000097          	auipc	ra,0x0
    800046e8:	bcc080e7          	jalr	-1076(ra) # 800042b0 <iunlockput>
    ip = next;
    800046ec:	8a4e                	mv	s4,s3
  while(*path == '/')
    800046ee:	0004c783          	lbu	a5,0(s1)
    800046f2:	01279763          	bne	a5,s2,80004700 <namex+0x11e>
    path++;
    800046f6:	0485                	addi	s1,s1,1
  while(*path == '/')
    800046f8:	0004c783          	lbu	a5,0(s1)
    800046fc:	ff278de3          	beq	a5,s2,800046f6 <namex+0x114>
  if(*path == 0)
    80004700:	cb9d                	beqz	a5,80004736 <namex+0x154>
  while(*path != '/' && *path != 0)
    80004702:	0004c783          	lbu	a5,0(s1)
    80004706:	89a6                	mv	s3,s1
  len = path - s;
    80004708:	8d5e                	mv	s10,s7
    8000470a:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    8000470c:	01278963          	beq	a5,s2,8000471e <namex+0x13c>
    80004710:	dbbd                	beqz	a5,80004686 <namex+0xa4>
    path++;
    80004712:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80004714:	0009c783          	lbu	a5,0(s3)
    80004718:	ff279ce3          	bne	a5,s2,80004710 <namex+0x12e>
    8000471c:	b7ad                	j	80004686 <namex+0xa4>
    memmove(name, s, len);
    8000471e:	2601                	sext.w	a2,a2
    80004720:	85a6                	mv	a1,s1
    80004722:	8556                	mv	a0,s5
    80004724:	ffffc097          	auipc	ra,0xffffc
    80004728:	7d4080e7          	jalr	2004(ra) # 80000ef8 <memmove>
    name[len] = 0;
    8000472c:	9d56                	add	s10,s10,s5
    8000472e:	000d0023          	sb	zero,0(s10)
    80004732:	84ce                	mv	s1,s3
    80004734:	b7bd                	j	800046a2 <namex+0xc0>
  if(nameiparent){
    80004736:	f00b0ce3          	beqz	s6,8000464e <namex+0x6c>
    iput(ip);
    8000473a:	8552                	mv	a0,s4
    8000473c:	00000097          	auipc	ra,0x0
    80004740:	acc080e7          	jalr	-1332(ra) # 80004208 <iput>
    return 0;
    80004744:	4a01                	li	s4,0
    80004746:	b721                	j	8000464e <namex+0x6c>

0000000080004748 <dirlink>:
{
    80004748:	7139                	addi	sp,sp,-64
    8000474a:	fc06                	sd	ra,56(sp)
    8000474c:	f822                	sd	s0,48(sp)
    8000474e:	f426                	sd	s1,40(sp)
    80004750:	f04a                	sd	s2,32(sp)
    80004752:	ec4e                	sd	s3,24(sp)
    80004754:	e852                	sd	s4,16(sp)
    80004756:	0080                	addi	s0,sp,64
    80004758:	892a                	mv	s2,a0
    8000475a:	8a2e                	mv	s4,a1
    8000475c:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000475e:	4601                	li	a2,0
    80004760:	00000097          	auipc	ra,0x0
    80004764:	dd2080e7          	jalr	-558(ra) # 80004532 <dirlookup>
    80004768:	e93d                	bnez	a0,800047de <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000476a:	04c92483          	lw	s1,76(s2)
    8000476e:	c49d                	beqz	s1,8000479c <dirlink+0x54>
    80004770:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004772:	4741                	li	a4,16
    80004774:	86a6                	mv	a3,s1
    80004776:	fc040613          	addi	a2,s0,-64
    8000477a:	4581                	li	a1,0
    8000477c:	854a                	mv	a0,s2
    8000477e:	00000097          	auipc	ra,0x0
    80004782:	b84080e7          	jalr	-1148(ra) # 80004302 <readi>
    80004786:	47c1                	li	a5,16
    80004788:	06f51163          	bne	a0,a5,800047ea <dirlink+0xa2>
    if(de.inum == 0)
    8000478c:	fc045783          	lhu	a5,-64(s0)
    80004790:	c791                	beqz	a5,8000479c <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004792:	24c1                	addiw	s1,s1,16
    80004794:	04c92783          	lw	a5,76(s2)
    80004798:	fcf4ede3          	bltu	s1,a5,80004772 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000479c:	4639                	li	a2,14
    8000479e:	85d2                	mv	a1,s4
    800047a0:	fc240513          	addi	a0,s0,-62
    800047a4:	ffffd097          	auipc	ra,0xffffd
    800047a8:	804080e7          	jalr	-2044(ra) # 80000fa8 <strncpy>
  de.inum = inum;
    800047ac:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800047b0:	4741                	li	a4,16
    800047b2:	86a6                	mv	a3,s1
    800047b4:	fc040613          	addi	a2,s0,-64
    800047b8:	4581                	li	a1,0
    800047ba:	854a                	mv	a0,s2
    800047bc:	00000097          	auipc	ra,0x0
    800047c0:	c3e080e7          	jalr	-962(ra) # 800043fa <writei>
    800047c4:	1541                	addi	a0,a0,-16
    800047c6:	00a03533          	snez	a0,a0
    800047ca:	40a00533          	neg	a0,a0
}
    800047ce:	70e2                	ld	ra,56(sp)
    800047d0:	7442                	ld	s0,48(sp)
    800047d2:	74a2                	ld	s1,40(sp)
    800047d4:	7902                	ld	s2,32(sp)
    800047d6:	69e2                	ld	s3,24(sp)
    800047d8:	6a42                	ld	s4,16(sp)
    800047da:	6121                	addi	sp,sp,64
    800047dc:	8082                	ret
    iput(ip);
    800047de:	00000097          	auipc	ra,0x0
    800047e2:	a2a080e7          	jalr	-1494(ra) # 80004208 <iput>
    return -1;
    800047e6:	557d                	li	a0,-1
    800047e8:	b7dd                	j	800047ce <dirlink+0x86>
      panic("dirlink read");
    800047ea:	00004517          	auipc	a0,0x4
    800047ee:	ff650513          	addi	a0,a0,-10 # 800087e0 <syscalls+0x1f8>
    800047f2:	ffffc097          	auipc	ra,0xffffc
    800047f6:	d4e080e7          	jalr	-690(ra) # 80000540 <panic>

00000000800047fa <namei>:

struct inode*
namei(char *path)
{
    800047fa:	1101                	addi	sp,sp,-32
    800047fc:	ec06                	sd	ra,24(sp)
    800047fe:	e822                	sd	s0,16(sp)
    80004800:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004802:	fe040613          	addi	a2,s0,-32
    80004806:	4581                	li	a1,0
    80004808:	00000097          	auipc	ra,0x0
    8000480c:	dda080e7          	jalr	-550(ra) # 800045e2 <namex>
}
    80004810:	60e2                	ld	ra,24(sp)
    80004812:	6442                	ld	s0,16(sp)
    80004814:	6105                	addi	sp,sp,32
    80004816:	8082                	ret

0000000080004818 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004818:	1141                	addi	sp,sp,-16
    8000481a:	e406                	sd	ra,8(sp)
    8000481c:	e022                	sd	s0,0(sp)
    8000481e:	0800                	addi	s0,sp,16
    80004820:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004822:	4585                	li	a1,1
    80004824:	00000097          	auipc	ra,0x0
    80004828:	dbe080e7          	jalr	-578(ra) # 800045e2 <namex>
}
    8000482c:	60a2                	ld	ra,8(sp)
    8000482e:	6402                	ld	s0,0(sp)
    80004830:	0141                	addi	sp,sp,16
    80004832:	8082                	ret

0000000080004834 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004834:	1101                	addi	sp,sp,-32
    80004836:	ec06                	sd	ra,24(sp)
    80004838:	e822                	sd	s0,16(sp)
    8000483a:	e426                	sd	s1,8(sp)
    8000483c:	e04a                	sd	s2,0(sp)
    8000483e:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004840:	0023d917          	auipc	s2,0x23d
    80004844:	7f890913          	addi	s2,s2,2040 # 80242038 <log>
    80004848:	01892583          	lw	a1,24(s2)
    8000484c:	02892503          	lw	a0,40(s2)
    80004850:	fffff097          	auipc	ra,0xfffff
    80004854:	fe6080e7          	jalr	-26(ra) # 80003836 <bread>
    80004858:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000485a:	02c92683          	lw	a3,44(s2)
    8000485e:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004860:	02d05863          	blez	a3,80004890 <write_head+0x5c>
    80004864:	0023e797          	auipc	a5,0x23e
    80004868:	80478793          	addi	a5,a5,-2044 # 80242068 <log+0x30>
    8000486c:	05c50713          	addi	a4,a0,92
    80004870:	36fd                	addiw	a3,a3,-1
    80004872:	02069613          	slli	a2,a3,0x20
    80004876:	01e65693          	srli	a3,a2,0x1e
    8000487a:	0023d617          	auipc	a2,0x23d
    8000487e:	7f260613          	addi	a2,a2,2034 # 8024206c <log+0x34>
    80004882:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004884:	4390                	lw	a2,0(a5)
    80004886:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004888:	0791                	addi	a5,a5,4
    8000488a:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    8000488c:	fed79ce3          	bne	a5,a3,80004884 <write_head+0x50>
  }
  bwrite(buf);
    80004890:	8526                	mv	a0,s1
    80004892:	fffff097          	auipc	ra,0xfffff
    80004896:	096080e7          	jalr	150(ra) # 80003928 <bwrite>
  brelse(buf);
    8000489a:	8526                	mv	a0,s1
    8000489c:	fffff097          	auipc	ra,0xfffff
    800048a0:	0ca080e7          	jalr	202(ra) # 80003966 <brelse>
}
    800048a4:	60e2                	ld	ra,24(sp)
    800048a6:	6442                	ld	s0,16(sp)
    800048a8:	64a2                	ld	s1,8(sp)
    800048aa:	6902                	ld	s2,0(sp)
    800048ac:	6105                	addi	sp,sp,32
    800048ae:	8082                	ret

00000000800048b0 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800048b0:	0023d797          	auipc	a5,0x23d
    800048b4:	7b47a783          	lw	a5,1972(a5) # 80242064 <log+0x2c>
    800048b8:	0af05d63          	blez	a5,80004972 <install_trans+0xc2>
{
    800048bc:	7139                	addi	sp,sp,-64
    800048be:	fc06                	sd	ra,56(sp)
    800048c0:	f822                	sd	s0,48(sp)
    800048c2:	f426                	sd	s1,40(sp)
    800048c4:	f04a                	sd	s2,32(sp)
    800048c6:	ec4e                	sd	s3,24(sp)
    800048c8:	e852                	sd	s4,16(sp)
    800048ca:	e456                	sd	s5,8(sp)
    800048cc:	e05a                	sd	s6,0(sp)
    800048ce:	0080                	addi	s0,sp,64
    800048d0:	8b2a                	mv	s6,a0
    800048d2:	0023da97          	auipc	s5,0x23d
    800048d6:	796a8a93          	addi	s5,s5,1942 # 80242068 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800048da:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800048dc:	0023d997          	auipc	s3,0x23d
    800048e0:	75c98993          	addi	s3,s3,1884 # 80242038 <log>
    800048e4:	a00d                	j	80004906 <install_trans+0x56>
    brelse(lbuf);
    800048e6:	854a                	mv	a0,s2
    800048e8:	fffff097          	auipc	ra,0xfffff
    800048ec:	07e080e7          	jalr	126(ra) # 80003966 <brelse>
    brelse(dbuf);
    800048f0:	8526                	mv	a0,s1
    800048f2:	fffff097          	auipc	ra,0xfffff
    800048f6:	074080e7          	jalr	116(ra) # 80003966 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800048fa:	2a05                	addiw	s4,s4,1
    800048fc:	0a91                	addi	s5,s5,4
    800048fe:	02c9a783          	lw	a5,44(s3)
    80004902:	04fa5e63          	bge	s4,a5,8000495e <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004906:	0189a583          	lw	a1,24(s3)
    8000490a:	014585bb          	addw	a1,a1,s4
    8000490e:	2585                	addiw	a1,a1,1
    80004910:	0289a503          	lw	a0,40(s3)
    80004914:	fffff097          	auipc	ra,0xfffff
    80004918:	f22080e7          	jalr	-222(ra) # 80003836 <bread>
    8000491c:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000491e:	000aa583          	lw	a1,0(s5)
    80004922:	0289a503          	lw	a0,40(s3)
    80004926:	fffff097          	auipc	ra,0xfffff
    8000492a:	f10080e7          	jalr	-240(ra) # 80003836 <bread>
    8000492e:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004930:	40000613          	li	a2,1024
    80004934:	05890593          	addi	a1,s2,88
    80004938:	05850513          	addi	a0,a0,88
    8000493c:	ffffc097          	auipc	ra,0xffffc
    80004940:	5bc080e7          	jalr	1468(ra) # 80000ef8 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004944:	8526                	mv	a0,s1
    80004946:	fffff097          	auipc	ra,0xfffff
    8000494a:	fe2080e7          	jalr	-30(ra) # 80003928 <bwrite>
    if(recovering == 0)
    8000494e:	f80b1ce3          	bnez	s6,800048e6 <install_trans+0x36>
      bunpin(dbuf);
    80004952:	8526                	mv	a0,s1
    80004954:	fffff097          	auipc	ra,0xfffff
    80004958:	0ec080e7          	jalr	236(ra) # 80003a40 <bunpin>
    8000495c:	b769                	j	800048e6 <install_trans+0x36>
}
    8000495e:	70e2                	ld	ra,56(sp)
    80004960:	7442                	ld	s0,48(sp)
    80004962:	74a2                	ld	s1,40(sp)
    80004964:	7902                	ld	s2,32(sp)
    80004966:	69e2                	ld	s3,24(sp)
    80004968:	6a42                	ld	s4,16(sp)
    8000496a:	6aa2                	ld	s5,8(sp)
    8000496c:	6b02                	ld	s6,0(sp)
    8000496e:	6121                	addi	sp,sp,64
    80004970:	8082                	ret
    80004972:	8082                	ret

0000000080004974 <initlog>:
{
    80004974:	7179                	addi	sp,sp,-48
    80004976:	f406                	sd	ra,40(sp)
    80004978:	f022                	sd	s0,32(sp)
    8000497a:	ec26                	sd	s1,24(sp)
    8000497c:	e84a                	sd	s2,16(sp)
    8000497e:	e44e                	sd	s3,8(sp)
    80004980:	1800                	addi	s0,sp,48
    80004982:	892a                	mv	s2,a0
    80004984:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004986:	0023d497          	auipc	s1,0x23d
    8000498a:	6b248493          	addi	s1,s1,1714 # 80242038 <log>
    8000498e:	00004597          	auipc	a1,0x4
    80004992:	e6258593          	addi	a1,a1,-414 # 800087f0 <syscalls+0x208>
    80004996:	8526                	mv	a0,s1
    80004998:	ffffc097          	auipc	ra,0xffffc
    8000499c:	378080e7          	jalr	888(ra) # 80000d10 <initlock>
  log.start = sb->logstart;
    800049a0:	0149a583          	lw	a1,20(s3)
    800049a4:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800049a6:	0109a783          	lw	a5,16(s3)
    800049aa:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800049ac:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800049b0:	854a                	mv	a0,s2
    800049b2:	fffff097          	auipc	ra,0xfffff
    800049b6:	e84080e7          	jalr	-380(ra) # 80003836 <bread>
  log.lh.n = lh->n;
    800049ba:	4d34                	lw	a3,88(a0)
    800049bc:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800049be:	02d05663          	blez	a3,800049ea <initlog+0x76>
    800049c2:	05c50793          	addi	a5,a0,92
    800049c6:	0023d717          	auipc	a4,0x23d
    800049ca:	6a270713          	addi	a4,a4,1698 # 80242068 <log+0x30>
    800049ce:	36fd                	addiw	a3,a3,-1
    800049d0:	02069613          	slli	a2,a3,0x20
    800049d4:	01e65693          	srli	a3,a2,0x1e
    800049d8:	06050613          	addi	a2,a0,96
    800049dc:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    800049de:	4390                	lw	a2,0(a5)
    800049e0:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800049e2:	0791                	addi	a5,a5,4
    800049e4:	0711                	addi	a4,a4,4
    800049e6:	fed79ce3          	bne	a5,a3,800049de <initlog+0x6a>
  brelse(buf);
    800049ea:	fffff097          	auipc	ra,0xfffff
    800049ee:	f7c080e7          	jalr	-132(ra) # 80003966 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800049f2:	4505                	li	a0,1
    800049f4:	00000097          	auipc	ra,0x0
    800049f8:	ebc080e7          	jalr	-324(ra) # 800048b0 <install_trans>
  log.lh.n = 0;
    800049fc:	0023d797          	auipc	a5,0x23d
    80004a00:	6607a423          	sw	zero,1640(a5) # 80242064 <log+0x2c>
  write_head(); // clear the log
    80004a04:	00000097          	auipc	ra,0x0
    80004a08:	e30080e7          	jalr	-464(ra) # 80004834 <write_head>
}
    80004a0c:	70a2                	ld	ra,40(sp)
    80004a0e:	7402                	ld	s0,32(sp)
    80004a10:	64e2                	ld	s1,24(sp)
    80004a12:	6942                	ld	s2,16(sp)
    80004a14:	69a2                	ld	s3,8(sp)
    80004a16:	6145                	addi	sp,sp,48
    80004a18:	8082                	ret

0000000080004a1a <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004a1a:	1101                	addi	sp,sp,-32
    80004a1c:	ec06                	sd	ra,24(sp)
    80004a1e:	e822                	sd	s0,16(sp)
    80004a20:	e426                	sd	s1,8(sp)
    80004a22:	e04a                	sd	s2,0(sp)
    80004a24:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004a26:	0023d517          	auipc	a0,0x23d
    80004a2a:	61250513          	addi	a0,a0,1554 # 80242038 <log>
    80004a2e:	ffffc097          	auipc	ra,0xffffc
    80004a32:	372080e7          	jalr	882(ra) # 80000da0 <acquire>
  while(1){
    if(log.committing){
    80004a36:	0023d497          	auipc	s1,0x23d
    80004a3a:	60248493          	addi	s1,s1,1538 # 80242038 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004a3e:	4979                	li	s2,30
    80004a40:	a039                	j	80004a4e <begin_op+0x34>
      sleep(&log, &log.lock);
    80004a42:	85a6                	mv	a1,s1
    80004a44:	8526                	mv	a0,s1
    80004a46:	ffffe097          	auipc	ra,0xffffe
    80004a4a:	926080e7          	jalr	-1754(ra) # 8000236c <sleep>
    if(log.committing){
    80004a4e:	50dc                	lw	a5,36(s1)
    80004a50:	fbed                	bnez	a5,80004a42 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004a52:	5098                	lw	a4,32(s1)
    80004a54:	2705                	addiw	a4,a4,1
    80004a56:	0007069b          	sext.w	a3,a4
    80004a5a:	0027179b          	slliw	a5,a4,0x2
    80004a5e:	9fb9                	addw	a5,a5,a4
    80004a60:	0017979b          	slliw	a5,a5,0x1
    80004a64:	54d8                	lw	a4,44(s1)
    80004a66:	9fb9                	addw	a5,a5,a4
    80004a68:	00f95963          	bge	s2,a5,80004a7a <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004a6c:	85a6                	mv	a1,s1
    80004a6e:	8526                	mv	a0,s1
    80004a70:	ffffe097          	auipc	ra,0xffffe
    80004a74:	8fc080e7          	jalr	-1796(ra) # 8000236c <sleep>
    80004a78:	bfd9                	j	80004a4e <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004a7a:	0023d517          	auipc	a0,0x23d
    80004a7e:	5be50513          	addi	a0,a0,1470 # 80242038 <log>
    80004a82:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004a84:	ffffc097          	auipc	ra,0xffffc
    80004a88:	3d0080e7          	jalr	976(ra) # 80000e54 <release>
      break;
    }
  }
}
    80004a8c:	60e2                	ld	ra,24(sp)
    80004a8e:	6442                	ld	s0,16(sp)
    80004a90:	64a2                	ld	s1,8(sp)
    80004a92:	6902                	ld	s2,0(sp)
    80004a94:	6105                	addi	sp,sp,32
    80004a96:	8082                	ret

0000000080004a98 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004a98:	7139                	addi	sp,sp,-64
    80004a9a:	fc06                	sd	ra,56(sp)
    80004a9c:	f822                	sd	s0,48(sp)
    80004a9e:	f426                	sd	s1,40(sp)
    80004aa0:	f04a                	sd	s2,32(sp)
    80004aa2:	ec4e                	sd	s3,24(sp)
    80004aa4:	e852                	sd	s4,16(sp)
    80004aa6:	e456                	sd	s5,8(sp)
    80004aa8:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004aaa:	0023d497          	auipc	s1,0x23d
    80004aae:	58e48493          	addi	s1,s1,1422 # 80242038 <log>
    80004ab2:	8526                	mv	a0,s1
    80004ab4:	ffffc097          	auipc	ra,0xffffc
    80004ab8:	2ec080e7          	jalr	748(ra) # 80000da0 <acquire>
  log.outstanding -= 1;
    80004abc:	509c                	lw	a5,32(s1)
    80004abe:	37fd                	addiw	a5,a5,-1
    80004ac0:	0007891b          	sext.w	s2,a5
    80004ac4:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004ac6:	50dc                	lw	a5,36(s1)
    80004ac8:	e7b9                	bnez	a5,80004b16 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004aca:	04091e63          	bnez	s2,80004b26 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004ace:	0023d497          	auipc	s1,0x23d
    80004ad2:	56a48493          	addi	s1,s1,1386 # 80242038 <log>
    80004ad6:	4785                	li	a5,1
    80004ad8:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004ada:	8526                	mv	a0,s1
    80004adc:	ffffc097          	auipc	ra,0xffffc
    80004ae0:	378080e7          	jalr	888(ra) # 80000e54 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004ae4:	54dc                	lw	a5,44(s1)
    80004ae6:	06f04763          	bgtz	a5,80004b54 <end_op+0xbc>
    acquire(&log.lock);
    80004aea:	0023d497          	auipc	s1,0x23d
    80004aee:	54e48493          	addi	s1,s1,1358 # 80242038 <log>
    80004af2:	8526                	mv	a0,s1
    80004af4:	ffffc097          	auipc	ra,0xffffc
    80004af8:	2ac080e7          	jalr	684(ra) # 80000da0 <acquire>
    log.committing = 0;
    80004afc:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004b00:	8526                	mv	a0,s1
    80004b02:	ffffe097          	auipc	ra,0xffffe
    80004b06:	8ce080e7          	jalr	-1842(ra) # 800023d0 <wakeup>
    release(&log.lock);
    80004b0a:	8526                	mv	a0,s1
    80004b0c:	ffffc097          	auipc	ra,0xffffc
    80004b10:	348080e7          	jalr	840(ra) # 80000e54 <release>
}
    80004b14:	a03d                	j	80004b42 <end_op+0xaa>
    panic("log.committing");
    80004b16:	00004517          	auipc	a0,0x4
    80004b1a:	ce250513          	addi	a0,a0,-798 # 800087f8 <syscalls+0x210>
    80004b1e:	ffffc097          	auipc	ra,0xffffc
    80004b22:	a22080e7          	jalr	-1502(ra) # 80000540 <panic>
    wakeup(&log);
    80004b26:	0023d497          	auipc	s1,0x23d
    80004b2a:	51248493          	addi	s1,s1,1298 # 80242038 <log>
    80004b2e:	8526                	mv	a0,s1
    80004b30:	ffffe097          	auipc	ra,0xffffe
    80004b34:	8a0080e7          	jalr	-1888(ra) # 800023d0 <wakeup>
  release(&log.lock);
    80004b38:	8526                	mv	a0,s1
    80004b3a:	ffffc097          	auipc	ra,0xffffc
    80004b3e:	31a080e7          	jalr	794(ra) # 80000e54 <release>
}
    80004b42:	70e2                	ld	ra,56(sp)
    80004b44:	7442                	ld	s0,48(sp)
    80004b46:	74a2                	ld	s1,40(sp)
    80004b48:	7902                	ld	s2,32(sp)
    80004b4a:	69e2                	ld	s3,24(sp)
    80004b4c:	6a42                	ld	s4,16(sp)
    80004b4e:	6aa2                	ld	s5,8(sp)
    80004b50:	6121                	addi	sp,sp,64
    80004b52:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004b54:	0023da97          	auipc	s5,0x23d
    80004b58:	514a8a93          	addi	s5,s5,1300 # 80242068 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004b5c:	0023da17          	auipc	s4,0x23d
    80004b60:	4dca0a13          	addi	s4,s4,1244 # 80242038 <log>
    80004b64:	018a2583          	lw	a1,24(s4)
    80004b68:	012585bb          	addw	a1,a1,s2
    80004b6c:	2585                	addiw	a1,a1,1
    80004b6e:	028a2503          	lw	a0,40(s4)
    80004b72:	fffff097          	auipc	ra,0xfffff
    80004b76:	cc4080e7          	jalr	-828(ra) # 80003836 <bread>
    80004b7a:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004b7c:	000aa583          	lw	a1,0(s5)
    80004b80:	028a2503          	lw	a0,40(s4)
    80004b84:	fffff097          	auipc	ra,0xfffff
    80004b88:	cb2080e7          	jalr	-846(ra) # 80003836 <bread>
    80004b8c:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004b8e:	40000613          	li	a2,1024
    80004b92:	05850593          	addi	a1,a0,88
    80004b96:	05848513          	addi	a0,s1,88
    80004b9a:	ffffc097          	auipc	ra,0xffffc
    80004b9e:	35e080e7          	jalr	862(ra) # 80000ef8 <memmove>
    bwrite(to);  // write the log
    80004ba2:	8526                	mv	a0,s1
    80004ba4:	fffff097          	auipc	ra,0xfffff
    80004ba8:	d84080e7          	jalr	-636(ra) # 80003928 <bwrite>
    brelse(from);
    80004bac:	854e                	mv	a0,s3
    80004bae:	fffff097          	auipc	ra,0xfffff
    80004bb2:	db8080e7          	jalr	-584(ra) # 80003966 <brelse>
    brelse(to);
    80004bb6:	8526                	mv	a0,s1
    80004bb8:	fffff097          	auipc	ra,0xfffff
    80004bbc:	dae080e7          	jalr	-594(ra) # 80003966 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004bc0:	2905                	addiw	s2,s2,1
    80004bc2:	0a91                	addi	s5,s5,4
    80004bc4:	02ca2783          	lw	a5,44(s4)
    80004bc8:	f8f94ee3          	blt	s2,a5,80004b64 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004bcc:	00000097          	auipc	ra,0x0
    80004bd0:	c68080e7          	jalr	-920(ra) # 80004834 <write_head>
    install_trans(0); // Now install writes to home locations
    80004bd4:	4501                	li	a0,0
    80004bd6:	00000097          	auipc	ra,0x0
    80004bda:	cda080e7          	jalr	-806(ra) # 800048b0 <install_trans>
    log.lh.n = 0;
    80004bde:	0023d797          	auipc	a5,0x23d
    80004be2:	4807a323          	sw	zero,1158(a5) # 80242064 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004be6:	00000097          	auipc	ra,0x0
    80004bea:	c4e080e7          	jalr	-946(ra) # 80004834 <write_head>
    80004bee:	bdf5                	j	80004aea <end_op+0x52>

0000000080004bf0 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004bf0:	1101                	addi	sp,sp,-32
    80004bf2:	ec06                	sd	ra,24(sp)
    80004bf4:	e822                	sd	s0,16(sp)
    80004bf6:	e426                	sd	s1,8(sp)
    80004bf8:	e04a                	sd	s2,0(sp)
    80004bfa:	1000                	addi	s0,sp,32
    80004bfc:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004bfe:	0023d917          	auipc	s2,0x23d
    80004c02:	43a90913          	addi	s2,s2,1082 # 80242038 <log>
    80004c06:	854a                	mv	a0,s2
    80004c08:	ffffc097          	auipc	ra,0xffffc
    80004c0c:	198080e7          	jalr	408(ra) # 80000da0 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004c10:	02c92603          	lw	a2,44(s2)
    80004c14:	47f5                	li	a5,29
    80004c16:	06c7c563          	blt	a5,a2,80004c80 <log_write+0x90>
    80004c1a:	0023d797          	auipc	a5,0x23d
    80004c1e:	43a7a783          	lw	a5,1082(a5) # 80242054 <log+0x1c>
    80004c22:	37fd                	addiw	a5,a5,-1
    80004c24:	04f65e63          	bge	a2,a5,80004c80 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004c28:	0023d797          	auipc	a5,0x23d
    80004c2c:	4307a783          	lw	a5,1072(a5) # 80242058 <log+0x20>
    80004c30:	06f05063          	blez	a5,80004c90 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004c34:	4781                	li	a5,0
    80004c36:	06c05563          	blez	a2,80004ca0 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004c3a:	44cc                	lw	a1,12(s1)
    80004c3c:	0023d717          	auipc	a4,0x23d
    80004c40:	42c70713          	addi	a4,a4,1068 # 80242068 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004c44:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004c46:	4314                	lw	a3,0(a4)
    80004c48:	04b68c63          	beq	a3,a1,80004ca0 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004c4c:	2785                	addiw	a5,a5,1
    80004c4e:	0711                	addi	a4,a4,4
    80004c50:	fef61be3          	bne	a2,a5,80004c46 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004c54:	0621                	addi	a2,a2,8
    80004c56:	060a                	slli	a2,a2,0x2
    80004c58:	0023d797          	auipc	a5,0x23d
    80004c5c:	3e078793          	addi	a5,a5,992 # 80242038 <log>
    80004c60:	97b2                	add	a5,a5,a2
    80004c62:	44d8                	lw	a4,12(s1)
    80004c64:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004c66:	8526                	mv	a0,s1
    80004c68:	fffff097          	auipc	ra,0xfffff
    80004c6c:	d9c080e7          	jalr	-612(ra) # 80003a04 <bpin>
    log.lh.n++;
    80004c70:	0023d717          	auipc	a4,0x23d
    80004c74:	3c870713          	addi	a4,a4,968 # 80242038 <log>
    80004c78:	575c                	lw	a5,44(a4)
    80004c7a:	2785                	addiw	a5,a5,1
    80004c7c:	d75c                	sw	a5,44(a4)
    80004c7e:	a82d                	j	80004cb8 <log_write+0xc8>
    panic("too big a transaction");
    80004c80:	00004517          	auipc	a0,0x4
    80004c84:	b8850513          	addi	a0,a0,-1144 # 80008808 <syscalls+0x220>
    80004c88:	ffffc097          	auipc	ra,0xffffc
    80004c8c:	8b8080e7          	jalr	-1864(ra) # 80000540 <panic>
    panic("log_write outside of trans");
    80004c90:	00004517          	auipc	a0,0x4
    80004c94:	b9050513          	addi	a0,a0,-1136 # 80008820 <syscalls+0x238>
    80004c98:	ffffc097          	auipc	ra,0xffffc
    80004c9c:	8a8080e7          	jalr	-1880(ra) # 80000540 <panic>
  log.lh.block[i] = b->blockno;
    80004ca0:	00878693          	addi	a3,a5,8
    80004ca4:	068a                	slli	a3,a3,0x2
    80004ca6:	0023d717          	auipc	a4,0x23d
    80004caa:	39270713          	addi	a4,a4,914 # 80242038 <log>
    80004cae:	9736                	add	a4,a4,a3
    80004cb0:	44d4                	lw	a3,12(s1)
    80004cb2:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004cb4:	faf609e3          	beq	a2,a5,80004c66 <log_write+0x76>
  }
  release(&log.lock);
    80004cb8:	0023d517          	auipc	a0,0x23d
    80004cbc:	38050513          	addi	a0,a0,896 # 80242038 <log>
    80004cc0:	ffffc097          	auipc	ra,0xffffc
    80004cc4:	194080e7          	jalr	404(ra) # 80000e54 <release>
}
    80004cc8:	60e2                	ld	ra,24(sp)
    80004cca:	6442                	ld	s0,16(sp)
    80004ccc:	64a2                	ld	s1,8(sp)
    80004cce:	6902                	ld	s2,0(sp)
    80004cd0:	6105                	addi	sp,sp,32
    80004cd2:	8082                	ret

0000000080004cd4 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004cd4:	1101                	addi	sp,sp,-32
    80004cd6:	ec06                	sd	ra,24(sp)
    80004cd8:	e822                	sd	s0,16(sp)
    80004cda:	e426                	sd	s1,8(sp)
    80004cdc:	e04a                	sd	s2,0(sp)
    80004cde:	1000                	addi	s0,sp,32
    80004ce0:	84aa                	mv	s1,a0
    80004ce2:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004ce4:	00004597          	auipc	a1,0x4
    80004ce8:	b5c58593          	addi	a1,a1,-1188 # 80008840 <syscalls+0x258>
    80004cec:	0521                	addi	a0,a0,8
    80004cee:	ffffc097          	auipc	ra,0xffffc
    80004cf2:	022080e7          	jalr	34(ra) # 80000d10 <initlock>
  lk->name = name;
    80004cf6:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004cfa:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004cfe:	0204a423          	sw	zero,40(s1)
}
    80004d02:	60e2                	ld	ra,24(sp)
    80004d04:	6442                	ld	s0,16(sp)
    80004d06:	64a2                	ld	s1,8(sp)
    80004d08:	6902                	ld	s2,0(sp)
    80004d0a:	6105                	addi	sp,sp,32
    80004d0c:	8082                	ret

0000000080004d0e <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004d0e:	1101                	addi	sp,sp,-32
    80004d10:	ec06                	sd	ra,24(sp)
    80004d12:	e822                	sd	s0,16(sp)
    80004d14:	e426                	sd	s1,8(sp)
    80004d16:	e04a                	sd	s2,0(sp)
    80004d18:	1000                	addi	s0,sp,32
    80004d1a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004d1c:	00850913          	addi	s2,a0,8
    80004d20:	854a                	mv	a0,s2
    80004d22:	ffffc097          	auipc	ra,0xffffc
    80004d26:	07e080e7          	jalr	126(ra) # 80000da0 <acquire>
  while (lk->locked) {
    80004d2a:	409c                	lw	a5,0(s1)
    80004d2c:	cb89                	beqz	a5,80004d3e <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004d2e:	85ca                	mv	a1,s2
    80004d30:	8526                	mv	a0,s1
    80004d32:	ffffd097          	auipc	ra,0xffffd
    80004d36:	63a080e7          	jalr	1594(ra) # 8000236c <sleep>
  while (lk->locked) {
    80004d3a:	409c                	lw	a5,0(s1)
    80004d3c:	fbed                	bnez	a5,80004d2e <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004d3e:	4785                	li	a5,1
    80004d40:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004d42:	ffffd097          	auipc	ra,0xffffd
    80004d46:	e72080e7          	jalr	-398(ra) # 80001bb4 <myproc>
    80004d4a:	591c                	lw	a5,48(a0)
    80004d4c:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004d4e:	854a                	mv	a0,s2
    80004d50:	ffffc097          	auipc	ra,0xffffc
    80004d54:	104080e7          	jalr	260(ra) # 80000e54 <release>
}
    80004d58:	60e2                	ld	ra,24(sp)
    80004d5a:	6442                	ld	s0,16(sp)
    80004d5c:	64a2                	ld	s1,8(sp)
    80004d5e:	6902                	ld	s2,0(sp)
    80004d60:	6105                	addi	sp,sp,32
    80004d62:	8082                	ret

0000000080004d64 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004d64:	1101                	addi	sp,sp,-32
    80004d66:	ec06                	sd	ra,24(sp)
    80004d68:	e822                	sd	s0,16(sp)
    80004d6a:	e426                	sd	s1,8(sp)
    80004d6c:	e04a                	sd	s2,0(sp)
    80004d6e:	1000                	addi	s0,sp,32
    80004d70:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004d72:	00850913          	addi	s2,a0,8
    80004d76:	854a                	mv	a0,s2
    80004d78:	ffffc097          	auipc	ra,0xffffc
    80004d7c:	028080e7          	jalr	40(ra) # 80000da0 <acquire>
  lk->locked = 0;
    80004d80:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004d84:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004d88:	8526                	mv	a0,s1
    80004d8a:	ffffd097          	auipc	ra,0xffffd
    80004d8e:	646080e7          	jalr	1606(ra) # 800023d0 <wakeup>
  release(&lk->lk);
    80004d92:	854a                	mv	a0,s2
    80004d94:	ffffc097          	auipc	ra,0xffffc
    80004d98:	0c0080e7          	jalr	192(ra) # 80000e54 <release>
}
    80004d9c:	60e2                	ld	ra,24(sp)
    80004d9e:	6442                	ld	s0,16(sp)
    80004da0:	64a2                	ld	s1,8(sp)
    80004da2:	6902                	ld	s2,0(sp)
    80004da4:	6105                	addi	sp,sp,32
    80004da6:	8082                	ret

0000000080004da8 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004da8:	7179                	addi	sp,sp,-48
    80004daa:	f406                	sd	ra,40(sp)
    80004dac:	f022                	sd	s0,32(sp)
    80004dae:	ec26                	sd	s1,24(sp)
    80004db0:	e84a                	sd	s2,16(sp)
    80004db2:	e44e                	sd	s3,8(sp)
    80004db4:	1800                	addi	s0,sp,48
    80004db6:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004db8:	00850913          	addi	s2,a0,8
    80004dbc:	854a                	mv	a0,s2
    80004dbe:	ffffc097          	auipc	ra,0xffffc
    80004dc2:	fe2080e7          	jalr	-30(ra) # 80000da0 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004dc6:	409c                	lw	a5,0(s1)
    80004dc8:	ef99                	bnez	a5,80004de6 <holdingsleep+0x3e>
    80004dca:	4481                	li	s1,0
  release(&lk->lk);
    80004dcc:	854a                	mv	a0,s2
    80004dce:	ffffc097          	auipc	ra,0xffffc
    80004dd2:	086080e7          	jalr	134(ra) # 80000e54 <release>
  return r;
}
    80004dd6:	8526                	mv	a0,s1
    80004dd8:	70a2                	ld	ra,40(sp)
    80004dda:	7402                	ld	s0,32(sp)
    80004ddc:	64e2                	ld	s1,24(sp)
    80004dde:	6942                	ld	s2,16(sp)
    80004de0:	69a2                	ld	s3,8(sp)
    80004de2:	6145                	addi	sp,sp,48
    80004de4:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004de6:	0284a983          	lw	s3,40(s1)
    80004dea:	ffffd097          	auipc	ra,0xffffd
    80004dee:	dca080e7          	jalr	-566(ra) # 80001bb4 <myproc>
    80004df2:	5904                	lw	s1,48(a0)
    80004df4:	413484b3          	sub	s1,s1,s3
    80004df8:	0014b493          	seqz	s1,s1
    80004dfc:	bfc1                	j	80004dcc <holdingsleep+0x24>

0000000080004dfe <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004dfe:	1141                	addi	sp,sp,-16
    80004e00:	e406                	sd	ra,8(sp)
    80004e02:	e022                	sd	s0,0(sp)
    80004e04:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004e06:	00004597          	auipc	a1,0x4
    80004e0a:	a4a58593          	addi	a1,a1,-1462 # 80008850 <syscalls+0x268>
    80004e0e:	0023d517          	auipc	a0,0x23d
    80004e12:	37250513          	addi	a0,a0,882 # 80242180 <ftable>
    80004e16:	ffffc097          	auipc	ra,0xffffc
    80004e1a:	efa080e7          	jalr	-262(ra) # 80000d10 <initlock>
}
    80004e1e:	60a2                	ld	ra,8(sp)
    80004e20:	6402                	ld	s0,0(sp)
    80004e22:	0141                	addi	sp,sp,16
    80004e24:	8082                	ret

0000000080004e26 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004e26:	1101                	addi	sp,sp,-32
    80004e28:	ec06                	sd	ra,24(sp)
    80004e2a:	e822                	sd	s0,16(sp)
    80004e2c:	e426                	sd	s1,8(sp)
    80004e2e:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004e30:	0023d517          	auipc	a0,0x23d
    80004e34:	35050513          	addi	a0,a0,848 # 80242180 <ftable>
    80004e38:	ffffc097          	auipc	ra,0xffffc
    80004e3c:	f68080e7          	jalr	-152(ra) # 80000da0 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004e40:	0023d497          	auipc	s1,0x23d
    80004e44:	35848493          	addi	s1,s1,856 # 80242198 <ftable+0x18>
    80004e48:	0023e717          	auipc	a4,0x23e
    80004e4c:	2f070713          	addi	a4,a4,752 # 80243138 <disk>
    if(f->ref == 0){
    80004e50:	40dc                	lw	a5,4(s1)
    80004e52:	cf99                	beqz	a5,80004e70 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004e54:	02848493          	addi	s1,s1,40
    80004e58:	fee49ce3          	bne	s1,a4,80004e50 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004e5c:	0023d517          	auipc	a0,0x23d
    80004e60:	32450513          	addi	a0,a0,804 # 80242180 <ftable>
    80004e64:	ffffc097          	auipc	ra,0xffffc
    80004e68:	ff0080e7          	jalr	-16(ra) # 80000e54 <release>
  return 0;
    80004e6c:	4481                	li	s1,0
    80004e6e:	a819                	j	80004e84 <filealloc+0x5e>
      f->ref = 1;
    80004e70:	4785                	li	a5,1
    80004e72:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004e74:	0023d517          	auipc	a0,0x23d
    80004e78:	30c50513          	addi	a0,a0,780 # 80242180 <ftable>
    80004e7c:	ffffc097          	auipc	ra,0xffffc
    80004e80:	fd8080e7          	jalr	-40(ra) # 80000e54 <release>
}
    80004e84:	8526                	mv	a0,s1
    80004e86:	60e2                	ld	ra,24(sp)
    80004e88:	6442                	ld	s0,16(sp)
    80004e8a:	64a2                	ld	s1,8(sp)
    80004e8c:	6105                	addi	sp,sp,32
    80004e8e:	8082                	ret

0000000080004e90 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004e90:	1101                	addi	sp,sp,-32
    80004e92:	ec06                	sd	ra,24(sp)
    80004e94:	e822                	sd	s0,16(sp)
    80004e96:	e426                	sd	s1,8(sp)
    80004e98:	1000                	addi	s0,sp,32
    80004e9a:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004e9c:	0023d517          	auipc	a0,0x23d
    80004ea0:	2e450513          	addi	a0,a0,740 # 80242180 <ftable>
    80004ea4:	ffffc097          	auipc	ra,0xffffc
    80004ea8:	efc080e7          	jalr	-260(ra) # 80000da0 <acquire>
  if(f->ref < 1)
    80004eac:	40dc                	lw	a5,4(s1)
    80004eae:	02f05263          	blez	a5,80004ed2 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004eb2:	2785                	addiw	a5,a5,1
    80004eb4:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004eb6:	0023d517          	auipc	a0,0x23d
    80004eba:	2ca50513          	addi	a0,a0,714 # 80242180 <ftable>
    80004ebe:	ffffc097          	auipc	ra,0xffffc
    80004ec2:	f96080e7          	jalr	-106(ra) # 80000e54 <release>
  return f;
}
    80004ec6:	8526                	mv	a0,s1
    80004ec8:	60e2                	ld	ra,24(sp)
    80004eca:	6442                	ld	s0,16(sp)
    80004ecc:	64a2                	ld	s1,8(sp)
    80004ece:	6105                	addi	sp,sp,32
    80004ed0:	8082                	ret
    panic("filedup");
    80004ed2:	00004517          	auipc	a0,0x4
    80004ed6:	98650513          	addi	a0,a0,-1658 # 80008858 <syscalls+0x270>
    80004eda:	ffffb097          	auipc	ra,0xffffb
    80004ede:	666080e7          	jalr	1638(ra) # 80000540 <panic>

0000000080004ee2 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004ee2:	7139                	addi	sp,sp,-64
    80004ee4:	fc06                	sd	ra,56(sp)
    80004ee6:	f822                	sd	s0,48(sp)
    80004ee8:	f426                	sd	s1,40(sp)
    80004eea:	f04a                	sd	s2,32(sp)
    80004eec:	ec4e                	sd	s3,24(sp)
    80004eee:	e852                	sd	s4,16(sp)
    80004ef0:	e456                	sd	s5,8(sp)
    80004ef2:	0080                	addi	s0,sp,64
    80004ef4:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004ef6:	0023d517          	auipc	a0,0x23d
    80004efa:	28a50513          	addi	a0,a0,650 # 80242180 <ftable>
    80004efe:	ffffc097          	auipc	ra,0xffffc
    80004f02:	ea2080e7          	jalr	-350(ra) # 80000da0 <acquire>
  if(f->ref < 1)
    80004f06:	40dc                	lw	a5,4(s1)
    80004f08:	06f05163          	blez	a5,80004f6a <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004f0c:	37fd                	addiw	a5,a5,-1
    80004f0e:	0007871b          	sext.w	a4,a5
    80004f12:	c0dc                	sw	a5,4(s1)
    80004f14:	06e04363          	bgtz	a4,80004f7a <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004f18:	0004a903          	lw	s2,0(s1)
    80004f1c:	0094ca83          	lbu	s5,9(s1)
    80004f20:	0104ba03          	ld	s4,16(s1)
    80004f24:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004f28:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004f2c:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004f30:	0023d517          	auipc	a0,0x23d
    80004f34:	25050513          	addi	a0,a0,592 # 80242180 <ftable>
    80004f38:	ffffc097          	auipc	ra,0xffffc
    80004f3c:	f1c080e7          	jalr	-228(ra) # 80000e54 <release>

  if(ff.type == FD_PIPE){
    80004f40:	4785                	li	a5,1
    80004f42:	04f90d63          	beq	s2,a5,80004f9c <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004f46:	3979                	addiw	s2,s2,-2
    80004f48:	4785                	li	a5,1
    80004f4a:	0527e063          	bltu	a5,s2,80004f8a <fileclose+0xa8>
    begin_op();
    80004f4e:	00000097          	auipc	ra,0x0
    80004f52:	acc080e7          	jalr	-1332(ra) # 80004a1a <begin_op>
    iput(ff.ip);
    80004f56:	854e                	mv	a0,s3
    80004f58:	fffff097          	auipc	ra,0xfffff
    80004f5c:	2b0080e7          	jalr	688(ra) # 80004208 <iput>
    end_op();
    80004f60:	00000097          	auipc	ra,0x0
    80004f64:	b38080e7          	jalr	-1224(ra) # 80004a98 <end_op>
    80004f68:	a00d                	j	80004f8a <fileclose+0xa8>
    panic("fileclose");
    80004f6a:	00004517          	auipc	a0,0x4
    80004f6e:	8f650513          	addi	a0,a0,-1802 # 80008860 <syscalls+0x278>
    80004f72:	ffffb097          	auipc	ra,0xffffb
    80004f76:	5ce080e7          	jalr	1486(ra) # 80000540 <panic>
    release(&ftable.lock);
    80004f7a:	0023d517          	auipc	a0,0x23d
    80004f7e:	20650513          	addi	a0,a0,518 # 80242180 <ftable>
    80004f82:	ffffc097          	auipc	ra,0xffffc
    80004f86:	ed2080e7          	jalr	-302(ra) # 80000e54 <release>
  }
}
    80004f8a:	70e2                	ld	ra,56(sp)
    80004f8c:	7442                	ld	s0,48(sp)
    80004f8e:	74a2                	ld	s1,40(sp)
    80004f90:	7902                	ld	s2,32(sp)
    80004f92:	69e2                	ld	s3,24(sp)
    80004f94:	6a42                	ld	s4,16(sp)
    80004f96:	6aa2                	ld	s5,8(sp)
    80004f98:	6121                	addi	sp,sp,64
    80004f9a:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004f9c:	85d6                	mv	a1,s5
    80004f9e:	8552                	mv	a0,s4
    80004fa0:	00000097          	auipc	ra,0x0
    80004fa4:	34c080e7          	jalr	844(ra) # 800052ec <pipeclose>
    80004fa8:	b7cd                	j	80004f8a <fileclose+0xa8>

0000000080004faa <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004faa:	715d                	addi	sp,sp,-80
    80004fac:	e486                	sd	ra,72(sp)
    80004fae:	e0a2                	sd	s0,64(sp)
    80004fb0:	fc26                	sd	s1,56(sp)
    80004fb2:	f84a                	sd	s2,48(sp)
    80004fb4:	f44e                	sd	s3,40(sp)
    80004fb6:	0880                	addi	s0,sp,80
    80004fb8:	84aa                	mv	s1,a0
    80004fba:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004fbc:	ffffd097          	auipc	ra,0xffffd
    80004fc0:	bf8080e7          	jalr	-1032(ra) # 80001bb4 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004fc4:	409c                	lw	a5,0(s1)
    80004fc6:	37f9                	addiw	a5,a5,-2
    80004fc8:	4705                	li	a4,1
    80004fca:	04f76763          	bltu	a4,a5,80005018 <filestat+0x6e>
    80004fce:	892a                	mv	s2,a0
    ilock(f->ip);
    80004fd0:	6c88                	ld	a0,24(s1)
    80004fd2:	fffff097          	auipc	ra,0xfffff
    80004fd6:	07c080e7          	jalr	124(ra) # 8000404e <ilock>
    stati(f->ip, &st);
    80004fda:	fb840593          	addi	a1,s0,-72
    80004fde:	6c88                	ld	a0,24(s1)
    80004fe0:	fffff097          	auipc	ra,0xfffff
    80004fe4:	2f8080e7          	jalr	760(ra) # 800042d8 <stati>
    iunlock(f->ip);
    80004fe8:	6c88                	ld	a0,24(s1)
    80004fea:	fffff097          	auipc	ra,0xfffff
    80004fee:	126080e7          	jalr	294(ra) # 80004110 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004ff2:	46e1                	li	a3,24
    80004ff4:	fb840613          	addi	a2,s0,-72
    80004ff8:	85ce                	mv	a1,s3
    80004ffa:	05093503          	ld	a0,80(s2)
    80004ffe:	ffffd097          	auipc	ra,0xffffd
    80005002:	83e080e7          	jalr	-1986(ra) # 8000183c <copyout>
    80005006:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000500a:	60a6                	ld	ra,72(sp)
    8000500c:	6406                	ld	s0,64(sp)
    8000500e:	74e2                	ld	s1,56(sp)
    80005010:	7942                	ld	s2,48(sp)
    80005012:	79a2                	ld	s3,40(sp)
    80005014:	6161                	addi	sp,sp,80
    80005016:	8082                	ret
  return -1;
    80005018:	557d                	li	a0,-1
    8000501a:	bfc5                	j	8000500a <filestat+0x60>

000000008000501c <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000501c:	7179                	addi	sp,sp,-48
    8000501e:	f406                	sd	ra,40(sp)
    80005020:	f022                	sd	s0,32(sp)
    80005022:	ec26                	sd	s1,24(sp)
    80005024:	e84a                	sd	s2,16(sp)
    80005026:	e44e                	sd	s3,8(sp)
    80005028:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000502a:	00854783          	lbu	a5,8(a0)
    8000502e:	c3d5                	beqz	a5,800050d2 <fileread+0xb6>
    80005030:	84aa                	mv	s1,a0
    80005032:	89ae                	mv	s3,a1
    80005034:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80005036:	411c                	lw	a5,0(a0)
    80005038:	4705                	li	a4,1
    8000503a:	04e78963          	beq	a5,a4,8000508c <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000503e:	470d                	li	a4,3
    80005040:	04e78d63          	beq	a5,a4,8000509a <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80005044:	4709                	li	a4,2
    80005046:	06e79e63          	bne	a5,a4,800050c2 <fileread+0xa6>
    ilock(f->ip);
    8000504a:	6d08                	ld	a0,24(a0)
    8000504c:	fffff097          	auipc	ra,0xfffff
    80005050:	002080e7          	jalr	2(ra) # 8000404e <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80005054:	874a                	mv	a4,s2
    80005056:	5094                	lw	a3,32(s1)
    80005058:	864e                	mv	a2,s3
    8000505a:	4585                	li	a1,1
    8000505c:	6c88                	ld	a0,24(s1)
    8000505e:	fffff097          	auipc	ra,0xfffff
    80005062:	2a4080e7          	jalr	676(ra) # 80004302 <readi>
    80005066:	892a                	mv	s2,a0
    80005068:	00a05563          	blez	a0,80005072 <fileread+0x56>
      f->off += r;
    8000506c:	509c                	lw	a5,32(s1)
    8000506e:	9fa9                	addw	a5,a5,a0
    80005070:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80005072:	6c88                	ld	a0,24(s1)
    80005074:	fffff097          	auipc	ra,0xfffff
    80005078:	09c080e7          	jalr	156(ra) # 80004110 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    8000507c:	854a                	mv	a0,s2
    8000507e:	70a2                	ld	ra,40(sp)
    80005080:	7402                	ld	s0,32(sp)
    80005082:	64e2                	ld	s1,24(sp)
    80005084:	6942                	ld	s2,16(sp)
    80005086:	69a2                	ld	s3,8(sp)
    80005088:	6145                	addi	sp,sp,48
    8000508a:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000508c:	6908                	ld	a0,16(a0)
    8000508e:	00000097          	auipc	ra,0x0
    80005092:	3c6080e7          	jalr	966(ra) # 80005454 <piperead>
    80005096:	892a                	mv	s2,a0
    80005098:	b7d5                	j	8000507c <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000509a:	02451783          	lh	a5,36(a0)
    8000509e:	03079693          	slli	a3,a5,0x30
    800050a2:	92c1                	srli	a3,a3,0x30
    800050a4:	4725                	li	a4,9
    800050a6:	02d76863          	bltu	a4,a3,800050d6 <fileread+0xba>
    800050aa:	0792                	slli	a5,a5,0x4
    800050ac:	0023d717          	auipc	a4,0x23d
    800050b0:	03470713          	addi	a4,a4,52 # 802420e0 <devsw>
    800050b4:	97ba                	add	a5,a5,a4
    800050b6:	639c                	ld	a5,0(a5)
    800050b8:	c38d                	beqz	a5,800050da <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800050ba:	4505                	li	a0,1
    800050bc:	9782                	jalr	a5
    800050be:	892a                	mv	s2,a0
    800050c0:	bf75                	j	8000507c <fileread+0x60>
    panic("fileread");
    800050c2:	00003517          	auipc	a0,0x3
    800050c6:	7ae50513          	addi	a0,a0,1966 # 80008870 <syscalls+0x288>
    800050ca:	ffffb097          	auipc	ra,0xffffb
    800050ce:	476080e7          	jalr	1142(ra) # 80000540 <panic>
    return -1;
    800050d2:	597d                	li	s2,-1
    800050d4:	b765                	j	8000507c <fileread+0x60>
      return -1;
    800050d6:	597d                	li	s2,-1
    800050d8:	b755                	j	8000507c <fileread+0x60>
    800050da:	597d                	li	s2,-1
    800050dc:	b745                	j	8000507c <fileread+0x60>

00000000800050de <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800050de:	715d                	addi	sp,sp,-80
    800050e0:	e486                	sd	ra,72(sp)
    800050e2:	e0a2                	sd	s0,64(sp)
    800050e4:	fc26                	sd	s1,56(sp)
    800050e6:	f84a                	sd	s2,48(sp)
    800050e8:	f44e                	sd	s3,40(sp)
    800050ea:	f052                	sd	s4,32(sp)
    800050ec:	ec56                	sd	s5,24(sp)
    800050ee:	e85a                	sd	s6,16(sp)
    800050f0:	e45e                	sd	s7,8(sp)
    800050f2:	e062                	sd	s8,0(sp)
    800050f4:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800050f6:	00954783          	lbu	a5,9(a0)
    800050fa:	10078663          	beqz	a5,80005206 <filewrite+0x128>
    800050fe:	892a                	mv	s2,a0
    80005100:	8b2e                	mv	s6,a1
    80005102:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80005104:	411c                	lw	a5,0(a0)
    80005106:	4705                	li	a4,1
    80005108:	02e78263          	beq	a5,a4,8000512c <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000510c:	470d                	li	a4,3
    8000510e:	02e78663          	beq	a5,a4,8000513a <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80005112:	4709                	li	a4,2
    80005114:	0ee79163          	bne	a5,a4,800051f6 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80005118:	0ac05d63          	blez	a2,800051d2 <filewrite+0xf4>
    int i = 0;
    8000511c:	4981                	li	s3,0
    8000511e:	6b85                	lui	s7,0x1
    80005120:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80005124:	6c05                	lui	s8,0x1
    80005126:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    8000512a:	a861                	j	800051c2 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    8000512c:	6908                	ld	a0,16(a0)
    8000512e:	00000097          	auipc	ra,0x0
    80005132:	22e080e7          	jalr	558(ra) # 8000535c <pipewrite>
    80005136:	8a2a                	mv	s4,a0
    80005138:	a045                	j	800051d8 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    8000513a:	02451783          	lh	a5,36(a0)
    8000513e:	03079693          	slli	a3,a5,0x30
    80005142:	92c1                	srli	a3,a3,0x30
    80005144:	4725                	li	a4,9
    80005146:	0cd76263          	bltu	a4,a3,8000520a <filewrite+0x12c>
    8000514a:	0792                	slli	a5,a5,0x4
    8000514c:	0023d717          	auipc	a4,0x23d
    80005150:	f9470713          	addi	a4,a4,-108 # 802420e0 <devsw>
    80005154:	97ba                	add	a5,a5,a4
    80005156:	679c                	ld	a5,8(a5)
    80005158:	cbdd                	beqz	a5,8000520e <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    8000515a:	4505                	li	a0,1
    8000515c:	9782                	jalr	a5
    8000515e:	8a2a                	mv	s4,a0
    80005160:	a8a5                	j	800051d8 <filewrite+0xfa>
    80005162:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80005166:	00000097          	auipc	ra,0x0
    8000516a:	8b4080e7          	jalr	-1868(ra) # 80004a1a <begin_op>
      ilock(f->ip);
    8000516e:	01893503          	ld	a0,24(s2)
    80005172:	fffff097          	auipc	ra,0xfffff
    80005176:	edc080e7          	jalr	-292(ra) # 8000404e <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    8000517a:	8756                	mv	a4,s5
    8000517c:	02092683          	lw	a3,32(s2)
    80005180:	01698633          	add	a2,s3,s6
    80005184:	4585                	li	a1,1
    80005186:	01893503          	ld	a0,24(s2)
    8000518a:	fffff097          	auipc	ra,0xfffff
    8000518e:	270080e7          	jalr	624(ra) # 800043fa <writei>
    80005192:	84aa                	mv	s1,a0
    80005194:	00a05763          	blez	a0,800051a2 <filewrite+0xc4>
        f->off += r;
    80005198:	02092783          	lw	a5,32(s2)
    8000519c:	9fa9                	addw	a5,a5,a0
    8000519e:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800051a2:	01893503          	ld	a0,24(s2)
    800051a6:	fffff097          	auipc	ra,0xfffff
    800051aa:	f6a080e7          	jalr	-150(ra) # 80004110 <iunlock>
      end_op();
    800051ae:	00000097          	auipc	ra,0x0
    800051b2:	8ea080e7          	jalr	-1814(ra) # 80004a98 <end_op>

      if(r != n1){
    800051b6:	009a9f63          	bne	s5,s1,800051d4 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    800051ba:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800051be:	0149db63          	bge	s3,s4,800051d4 <filewrite+0xf6>
      int n1 = n - i;
    800051c2:	413a04bb          	subw	s1,s4,s3
    800051c6:	0004879b          	sext.w	a5,s1
    800051ca:	f8fbdce3          	bge	s7,a5,80005162 <filewrite+0x84>
    800051ce:	84e2                	mv	s1,s8
    800051d0:	bf49                	j	80005162 <filewrite+0x84>
    int i = 0;
    800051d2:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800051d4:	013a1f63          	bne	s4,s3,800051f2 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800051d8:	8552                	mv	a0,s4
    800051da:	60a6                	ld	ra,72(sp)
    800051dc:	6406                	ld	s0,64(sp)
    800051de:	74e2                	ld	s1,56(sp)
    800051e0:	7942                	ld	s2,48(sp)
    800051e2:	79a2                	ld	s3,40(sp)
    800051e4:	7a02                	ld	s4,32(sp)
    800051e6:	6ae2                	ld	s5,24(sp)
    800051e8:	6b42                	ld	s6,16(sp)
    800051ea:	6ba2                	ld	s7,8(sp)
    800051ec:	6c02                	ld	s8,0(sp)
    800051ee:	6161                	addi	sp,sp,80
    800051f0:	8082                	ret
    ret = (i == n ? n : -1);
    800051f2:	5a7d                	li	s4,-1
    800051f4:	b7d5                	j	800051d8 <filewrite+0xfa>
    panic("filewrite");
    800051f6:	00003517          	auipc	a0,0x3
    800051fa:	68a50513          	addi	a0,a0,1674 # 80008880 <syscalls+0x298>
    800051fe:	ffffb097          	auipc	ra,0xffffb
    80005202:	342080e7          	jalr	834(ra) # 80000540 <panic>
    return -1;
    80005206:	5a7d                	li	s4,-1
    80005208:	bfc1                	j	800051d8 <filewrite+0xfa>
      return -1;
    8000520a:	5a7d                	li	s4,-1
    8000520c:	b7f1                	j	800051d8 <filewrite+0xfa>
    8000520e:	5a7d                	li	s4,-1
    80005210:	b7e1                	j	800051d8 <filewrite+0xfa>

0000000080005212 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80005212:	7179                	addi	sp,sp,-48
    80005214:	f406                	sd	ra,40(sp)
    80005216:	f022                	sd	s0,32(sp)
    80005218:	ec26                	sd	s1,24(sp)
    8000521a:	e84a                	sd	s2,16(sp)
    8000521c:	e44e                	sd	s3,8(sp)
    8000521e:	e052                	sd	s4,0(sp)
    80005220:	1800                	addi	s0,sp,48
    80005222:	84aa                	mv	s1,a0
    80005224:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80005226:	0005b023          	sd	zero,0(a1)
    8000522a:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    8000522e:	00000097          	auipc	ra,0x0
    80005232:	bf8080e7          	jalr	-1032(ra) # 80004e26 <filealloc>
    80005236:	e088                	sd	a0,0(s1)
    80005238:	c551                	beqz	a0,800052c4 <pipealloc+0xb2>
    8000523a:	00000097          	auipc	ra,0x0
    8000523e:	bec080e7          	jalr	-1044(ra) # 80004e26 <filealloc>
    80005242:	00aa3023          	sd	a0,0(s4)
    80005246:	c92d                	beqz	a0,800052b8 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80005248:	ffffc097          	auipc	ra,0xffffc
    8000524c:	a5e080e7          	jalr	-1442(ra) # 80000ca6 <kalloc>
    80005250:	892a                	mv	s2,a0
    80005252:	c125                	beqz	a0,800052b2 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80005254:	4985                	li	s3,1
    80005256:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    8000525a:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    8000525e:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80005262:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80005266:	00003597          	auipc	a1,0x3
    8000526a:	29a58593          	addi	a1,a1,666 # 80008500 <states.0+0x1c0>
    8000526e:	ffffc097          	auipc	ra,0xffffc
    80005272:	aa2080e7          	jalr	-1374(ra) # 80000d10 <initlock>
  (*f0)->type = FD_PIPE;
    80005276:	609c                	ld	a5,0(s1)
    80005278:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    8000527c:	609c                	ld	a5,0(s1)
    8000527e:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80005282:	609c                	ld	a5,0(s1)
    80005284:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80005288:	609c                	ld	a5,0(s1)
    8000528a:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    8000528e:	000a3783          	ld	a5,0(s4)
    80005292:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80005296:	000a3783          	ld	a5,0(s4)
    8000529a:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    8000529e:	000a3783          	ld	a5,0(s4)
    800052a2:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800052a6:	000a3783          	ld	a5,0(s4)
    800052aa:	0127b823          	sd	s2,16(a5)
  return 0;
    800052ae:	4501                	li	a0,0
    800052b0:	a025                	j	800052d8 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800052b2:	6088                	ld	a0,0(s1)
    800052b4:	e501                	bnez	a0,800052bc <pipealloc+0xaa>
    800052b6:	a039                	j	800052c4 <pipealloc+0xb2>
    800052b8:	6088                	ld	a0,0(s1)
    800052ba:	c51d                	beqz	a0,800052e8 <pipealloc+0xd6>
    fileclose(*f0);
    800052bc:	00000097          	auipc	ra,0x0
    800052c0:	c26080e7          	jalr	-986(ra) # 80004ee2 <fileclose>
  if(*f1)
    800052c4:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800052c8:	557d                	li	a0,-1
  if(*f1)
    800052ca:	c799                	beqz	a5,800052d8 <pipealloc+0xc6>
    fileclose(*f1);
    800052cc:	853e                	mv	a0,a5
    800052ce:	00000097          	auipc	ra,0x0
    800052d2:	c14080e7          	jalr	-1004(ra) # 80004ee2 <fileclose>
  return -1;
    800052d6:	557d                	li	a0,-1
}
    800052d8:	70a2                	ld	ra,40(sp)
    800052da:	7402                	ld	s0,32(sp)
    800052dc:	64e2                	ld	s1,24(sp)
    800052de:	6942                	ld	s2,16(sp)
    800052e0:	69a2                	ld	s3,8(sp)
    800052e2:	6a02                	ld	s4,0(sp)
    800052e4:	6145                	addi	sp,sp,48
    800052e6:	8082                	ret
  return -1;
    800052e8:	557d                	li	a0,-1
    800052ea:	b7fd                	j	800052d8 <pipealloc+0xc6>

00000000800052ec <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800052ec:	1101                	addi	sp,sp,-32
    800052ee:	ec06                	sd	ra,24(sp)
    800052f0:	e822                	sd	s0,16(sp)
    800052f2:	e426                	sd	s1,8(sp)
    800052f4:	e04a                	sd	s2,0(sp)
    800052f6:	1000                	addi	s0,sp,32
    800052f8:	84aa                	mv	s1,a0
    800052fa:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800052fc:	ffffc097          	auipc	ra,0xffffc
    80005300:	aa4080e7          	jalr	-1372(ra) # 80000da0 <acquire>
  if(writable){
    80005304:	02090d63          	beqz	s2,8000533e <pipeclose+0x52>
    pi->writeopen = 0;
    80005308:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    8000530c:	21848513          	addi	a0,s1,536
    80005310:	ffffd097          	auipc	ra,0xffffd
    80005314:	0c0080e7          	jalr	192(ra) # 800023d0 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80005318:	2204b783          	ld	a5,544(s1)
    8000531c:	eb95                	bnez	a5,80005350 <pipeclose+0x64>
    release(&pi->lock);
    8000531e:	8526                	mv	a0,s1
    80005320:	ffffc097          	auipc	ra,0xffffc
    80005324:	b34080e7          	jalr	-1228(ra) # 80000e54 <release>
    kfree((char*)pi);
    80005328:	8526                	mv	a0,s1
    8000532a:	ffffb097          	auipc	ra,0xffffb
    8000532e:	7f4080e7          	jalr	2036(ra) # 80000b1e <kfree>
  } else
    release(&pi->lock);
}
    80005332:	60e2                	ld	ra,24(sp)
    80005334:	6442                	ld	s0,16(sp)
    80005336:	64a2                	ld	s1,8(sp)
    80005338:	6902                	ld	s2,0(sp)
    8000533a:	6105                	addi	sp,sp,32
    8000533c:	8082                	ret
    pi->readopen = 0;
    8000533e:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80005342:	21c48513          	addi	a0,s1,540
    80005346:	ffffd097          	auipc	ra,0xffffd
    8000534a:	08a080e7          	jalr	138(ra) # 800023d0 <wakeup>
    8000534e:	b7e9                	j	80005318 <pipeclose+0x2c>
    release(&pi->lock);
    80005350:	8526                	mv	a0,s1
    80005352:	ffffc097          	auipc	ra,0xffffc
    80005356:	b02080e7          	jalr	-1278(ra) # 80000e54 <release>
}
    8000535a:	bfe1                	j	80005332 <pipeclose+0x46>

000000008000535c <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    8000535c:	711d                	addi	sp,sp,-96
    8000535e:	ec86                	sd	ra,88(sp)
    80005360:	e8a2                	sd	s0,80(sp)
    80005362:	e4a6                	sd	s1,72(sp)
    80005364:	e0ca                	sd	s2,64(sp)
    80005366:	fc4e                	sd	s3,56(sp)
    80005368:	f852                	sd	s4,48(sp)
    8000536a:	f456                	sd	s5,40(sp)
    8000536c:	f05a                	sd	s6,32(sp)
    8000536e:	ec5e                	sd	s7,24(sp)
    80005370:	e862                	sd	s8,16(sp)
    80005372:	1080                	addi	s0,sp,96
    80005374:	84aa                	mv	s1,a0
    80005376:	8aae                	mv	s5,a1
    80005378:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    8000537a:	ffffd097          	auipc	ra,0xffffd
    8000537e:	83a080e7          	jalr	-1990(ra) # 80001bb4 <myproc>
    80005382:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80005384:	8526                	mv	a0,s1
    80005386:	ffffc097          	auipc	ra,0xffffc
    8000538a:	a1a080e7          	jalr	-1510(ra) # 80000da0 <acquire>
  while(i < n){
    8000538e:	0b405663          	blez	s4,8000543a <pipewrite+0xde>
  int i = 0;
    80005392:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005394:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80005396:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    8000539a:	21c48b93          	addi	s7,s1,540
    8000539e:	a089                	j	800053e0 <pipewrite+0x84>
      release(&pi->lock);
    800053a0:	8526                	mv	a0,s1
    800053a2:	ffffc097          	auipc	ra,0xffffc
    800053a6:	ab2080e7          	jalr	-1358(ra) # 80000e54 <release>
      return -1;
    800053aa:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    800053ac:	854a                	mv	a0,s2
    800053ae:	60e6                	ld	ra,88(sp)
    800053b0:	6446                	ld	s0,80(sp)
    800053b2:	64a6                	ld	s1,72(sp)
    800053b4:	6906                	ld	s2,64(sp)
    800053b6:	79e2                	ld	s3,56(sp)
    800053b8:	7a42                	ld	s4,48(sp)
    800053ba:	7aa2                	ld	s5,40(sp)
    800053bc:	7b02                	ld	s6,32(sp)
    800053be:	6be2                	ld	s7,24(sp)
    800053c0:	6c42                	ld	s8,16(sp)
    800053c2:	6125                	addi	sp,sp,96
    800053c4:	8082                	ret
      wakeup(&pi->nread);
    800053c6:	8562                	mv	a0,s8
    800053c8:	ffffd097          	auipc	ra,0xffffd
    800053cc:	008080e7          	jalr	8(ra) # 800023d0 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    800053d0:	85a6                	mv	a1,s1
    800053d2:	855e                	mv	a0,s7
    800053d4:	ffffd097          	auipc	ra,0xffffd
    800053d8:	f98080e7          	jalr	-104(ra) # 8000236c <sleep>
  while(i < n){
    800053dc:	07495063          	bge	s2,s4,8000543c <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    800053e0:	2204a783          	lw	a5,544(s1)
    800053e4:	dfd5                	beqz	a5,800053a0 <pipewrite+0x44>
    800053e6:	854e                	mv	a0,s3
    800053e8:	ffffd097          	auipc	ra,0xffffd
    800053ec:	238080e7          	jalr	568(ra) # 80002620 <killed>
    800053f0:	f945                	bnez	a0,800053a0 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    800053f2:	2184a783          	lw	a5,536(s1)
    800053f6:	21c4a703          	lw	a4,540(s1)
    800053fa:	2007879b          	addiw	a5,a5,512
    800053fe:	fcf704e3          	beq	a4,a5,800053c6 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005402:	4685                	li	a3,1
    80005404:	01590633          	add	a2,s2,s5
    80005408:	faf40593          	addi	a1,s0,-81
    8000540c:	0509b503          	ld	a0,80(s3)
    80005410:	ffffc097          	auipc	ra,0xffffc
    80005414:	4f0080e7          	jalr	1264(ra) # 80001900 <copyin>
    80005418:	03650263          	beq	a0,s6,8000543c <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    8000541c:	21c4a783          	lw	a5,540(s1)
    80005420:	0017871b          	addiw	a4,a5,1
    80005424:	20e4ae23          	sw	a4,540(s1)
    80005428:	1ff7f793          	andi	a5,a5,511
    8000542c:	97a6                	add	a5,a5,s1
    8000542e:	faf44703          	lbu	a4,-81(s0)
    80005432:	00e78c23          	sb	a4,24(a5)
      i++;
    80005436:	2905                	addiw	s2,s2,1
    80005438:	b755                	j	800053dc <pipewrite+0x80>
  int i = 0;
    8000543a:	4901                	li	s2,0
  wakeup(&pi->nread);
    8000543c:	21848513          	addi	a0,s1,536
    80005440:	ffffd097          	auipc	ra,0xffffd
    80005444:	f90080e7          	jalr	-112(ra) # 800023d0 <wakeup>
  release(&pi->lock);
    80005448:	8526                	mv	a0,s1
    8000544a:	ffffc097          	auipc	ra,0xffffc
    8000544e:	a0a080e7          	jalr	-1526(ra) # 80000e54 <release>
  return i;
    80005452:	bfa9                	j	800053ac <pipewrite+0x50>

0000000080005454 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005454:	715d                	addi	sp,sp,-80
    80005456:	e486                	sd	ra,72(sp)
    80005458:	e0a2                	sd	s0,64(sp)
    8000545a:	fc26                	sd	s1,56(sp)
    8000545c:	f84a                	sd	s2,48(sp)
    8000545e:	f44e                	sd	s3,40(sp)
    80005460:	f052                	sd	s4,32(sp)
    80005462:	ec56                	sd	s5,24(sp)
    80005464:	e85a                	sd	s6,16(sp)
    80005466:	0880                	addi	s0,sp,80
    80005468:	84aa                	mv	s1,a0
    8000546a:	892e                	mv	s2,a1
    8000546c:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    8000546e:	ffffc097          	auipc	ra,0xffffc
    80005472:	746080e7          	jalr	1862(ra) # 80001bb4 <myproc>
    80005476:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005478:	8526                	mv	a0,s1
    8000547a:	ffffc097          	auipc	ra,0xffffc
    8000547e:	926080e7          	jalr	-1754(ra) # 80000da0 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005482:	2184a703          	lw	a4,536(s1)
    80005486:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000548a:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000548e:	02f71763          	bne	a4,a5,800054bc <piperead+0x68>
    80005492:	2244a783          	lw	a5,548(s1)
    80005496:	c39d                	beqz	a5,800054bc <piperead+0x68>
    if(killed(pr)){
    80005498:	8552                	mv	a0,s4
    8000549a:	ffffd097          	auipc	ra,0xffffd
    8000549e:	186080e7          	jalr	390(ra) # 80002620 <killed>
    800054a2:	e949                	bnez	a0,80005534 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800054a4:	85a6                	mv	a1,s1
    800054a6:	854e                	mv	a0,s3
    800054a8:	ffffd097          	auipc	ra,0xffffd
    800054ac:	ec4080e7          	jalr	-316(ra) # 8000236c <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800054b0:	2184a703          	lw	a4,536(s1)
    800054b4:	21c4a783          	lw	a5,540(s1)
    800054b8:	fcf70de3          	beq	a4,a5,80005492 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800054bc:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800054be:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800054c0:	05505463          	blez	s5,80005508 <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    800054c4:	2184a783          	lw	a5,536(s1)
    800054c8:	21c4a703          	lw	a4,540(s1)
    800054cc:	02f70e63          	beq	a4,a5,80005508 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    800054d0:	0017871b          	addiw	a4,a5,1
    800054d4:	20e4ac23          	sw	a4,536(s1)
    800054d8:	1ff7f793          	andi	a5,a5,511
    800054dc:	97a6                	add	a5,a5,s1
    800054de:	0187c783          	lbu	a5,24(a5)
    800054e2:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800054e6:	4685                	li	a3,1
    800054e8:	fbf40613          	addi	a2,s0,-65
    800054ec:	85ca                	mv	a1,s2
    800054ee:	050a3503          	ld	a0,80(s4)
    800054f2:	ffffc097          	auipc	ra,0xffffc
    800054f6:	34a080e7          	jalr	842(ra) # 8000183c <copyout>
    800054fa:	01650763          	beq	a0,s6,80005508 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800054fe:	2985                	addiw	s3,s3,1
    80005500:	0905                	addi	s2,s2,1
    80005502:	fd3a91e3          	bne	s5,s3,800054c4 <piperead+0x70>
    80005506:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005508:	21c48513          	addi	a0,s1,540
    8000550c:	ffffd097          	auipc	ra,0xffffd
    80005510:	ec4080e7          	jalr	-316(ra) # 800023d0 <wakeup>
  release(&pi->lock);
    80005514:	8526                	mv	a0,s1
    80005516:	ffffc097          	auipc	ra,0xffffc
    8000551a:	93e080e7          	jalr	-1730(ra) # 80000e54 <release>
  return i;
}
    8000551e:	854e                	mv	a0,s3
    80005520:	60a6                	ld	ra,72(sp)
    80005522:	6406                	ld	s0,64(sp)
    80005524:	74e2                	ld	s1,56(sp)
    80005526:	7942                	ld	s2,48(sp)
    80005528:	79a2                	ld	s3,40(sp)
    8000552a:	7a02                	ld	s4,32(sp)
    8000552c:	6ae2                	ld	s5,24(sp)
    8000552e:	6b42                	ld	s6,16(sp)
    80005530:	6161                	addi	sp,sp,80
    80005532:	8082                	ret
      release(&pi->lock);
    80005534:	8526                	mv	a0,s1
    80005536:	ffffc097          	auipc	ra,0xffffc
    8000553a:	91e080e7          	jalr	-1762(ra) # 80000e54 <release>
      return -1;
    8000553e:	59fd                	li	s3,-1
    80005540:	bff9                	j	8000551e <piperead+0xca>

0000000080005542 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80005542:	1141                	addi	sp,sp,-16
    80005544:	e422                	sd	s0,8(sp)
    80005546:	0800                	addi	s0,sp,16
    80005548:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    8000554a:	8905                	andi	a0,a0,1
    8000554c:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    8000554e:	8b89                	andi	a5,a5,2
    80005550:	c399                	beqz	a5,80005556 <flags2perm+0x14>
      perm |= PTE_W;
    80005552:	00456513          	ori	a0,a0,4
    return perm;
}
    80005556:	6422                	ld	s0,8(sp)
    80005558:	0141                	addi	sp,sp,16
    8000555a:	8082                	ret

000000008000555c <exec>:

int
exec(char *path, char **argv)
{
    8000555c:	de010113          	addi	sp,sp,-544
    80005560:	20113c23          	sd	ra,536(sp)
    80005564:	20813823          	sd	s0,528(sp)
    80005568:	20913423          	sd	s1,520(sp)
    8000556c:	21213023          	sd	s2,512(sp)
    80005570:	ffce                	sd	s3,504(sp)
    80005572:	fbd2                	sd	s4,496(sp)
    80005574:	f7d6                	sd	s5,488(sp)
    80005576:	f3da                	sd	s6,480(sp)
    80005578:	efde                	sd	s7,472(sp)
    8000557a:	ebe2                	sd	s8,464(sp)
    8000557c:	e7e6                	sd	s9,456(sp)
    8000557e:	e3ea                	sd	s10,448(sp)
    80005580:	ff6e                	sd	s11,440(sp)
    80005582:	1400                	addi	s0,sp,544
    80005584:	892a                	mv	s2,a0
    80005586:	dea43423          	sd	a0,-536(s0)
    8000558a:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    8000558e:	ffffc097          	auipc	ra,0xffffc
    80005592:	626080e7          	jalr	1574(ra) # 80001bb4 <myproc>
    80005596:	84aa                	mv	s1,a0

  begin_op();
    80005598:	fffff097          	auipc	ra,0xfffff
    8000559c:	482080e7          	jalr	1154(ra) # 80004a1a <begin_op>

  if((ip = namei(path)) == 0){
    800055a0:	854a                	mv	a0,s2
    800055a2:	fffff097          	auipc	ra,0xfffff
    800055a6:	258080e7          	jalr	600(ra) # 800047fa <namei>
    800055aa:	c93d                	beqz	a0,80005620 <exec+0xc4>
    800055ac:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    800055ae:	fffff097          	auipc	ra,0xfffff
    800055b2:	aa0080e7          	jalr	-1376(ra) # 8000404e <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800055b6:	04000713          	li	a4,64
    800055ba:	4681                	li	a3,0
    800055bc:	e5040613          	addi	a2,s0,-432
    800055c0:	4581                	li	a1,0
    800055c2:	8556                	mv	a0,s5
    800055c4:	fffff097          	auipc	ra,0xfffff
    800055c8:	d3e080e7          	jalr	-706(ra) # 80004302 <readi>
    800055cc:	04000793          	li	a5,64
    800055d0:	00f51a63          	bne	a0,a5,800055e4 <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    800055d4:	e5042703          	lw	a4,-432(s0)
    800055d8:	464c47b7          	lui	a5,0x464c4
    800055dc:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800055e0:	04f70663          	beq	a4,a5,8000562c <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800055e4:	8556                	mv	a0,s5
    800055e6:	fffff097          	auipc	ra,0xfffff
    800055ea:	cca080e7          	jalr	-822(ra) # 800042b0 <iunlockput>
    end_op();
    800055ee:	fffff097          	auipc	ra,0xfffff
    800055f2:	4aa080e7          	jalr	1194(ra) # 80004a98 <end_op>
  }
  return -1;
    800055f6:	557d                	li	a0,-1
}
    800055f8:	21813083          	ld	ra,536(sp)
    800055fc:	21013403          	ld	s0,528(sp)
    80005600:	20813483          	ld	s1,520(sp)
    80005604:	20013903          	ld	s2,512(sp)
    80005608:	79fe                	ld	s3,504(sp)
    8000560a:	7a5e                	ld	s4,496(sp)
    8000560c:	7abe                	ld	s5,488(sp)
    8000560e:	7b1e                	ld	s6,480(sp)
    80005610:	6bfe                	ld	s7,472(sp)
    80005612:	6c5e                	ld	s8,464(sp)
    80005614:	6cbe                	ld	s9,456(sp)
    80005616:	6d1e                	ld	s10,448(sp)
    80005618:	7dfa                	ld	s11,440(sp)
    8000561a:	22010113          	addi	sp,sp,544
    8000561e:	8082                	ret
    end_op();
    80005620:	fffff097          	auipc	ra,0xfffff
    80005624:	478080e7          	jalr	1144(ra) # 80004a98 <end_op>
    return -1;
    80005628:	557d                	li	a0,-1
    8000562a:	b7f9                	j	800055f8 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    8000562c:	8526                	mv	a0,s1
    8000562e:	ffffc097          	auipc	ra,0xffffc
    80005632:	64a080e7          	jalr	1610(ra) # 80001c78 <proc_pagetable>
    80005636:	8b2a                	mv	s6,a0
    80005638:	d555                	beqz	a0,800055e4 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000563a:	e7042783          	lw	a5,-400(s0)
    8000563e:	e8845703          	lhu	a4,-376(s0)
    80005642:	c735                	beqz	a4,800056ae <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005644:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005646:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    8000564a:	6a05                	lui	s4,0x1
    8000564c:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80005650:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80005654:	6d85                	lui	s11,0x1
    80005656:	7d7d                	lui	s10,0xfffff
    80005658:	ac3d                	j	80005896 <exec+0x33a>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    8000565a:	00003517          	auipc	a0,0x3
    8000565e:	23650513          	addi	a0,a0,566 # 80008890 <syscalls+0x2a8>
    80005662:	ffffb097          	auipc	ra,0xffffb
    80005666:	ede080e7          	jalr	-290(ra) # 80000540 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    8000566a:	874a                	mv	a4,s2
    8000566c:	009c86bb          	addw	a3,s9,s1
    80005670:	4581                	li	a1,0
    80005672:	8556                	mv	a0,s5
    80005674:	fffff097          	auipc	ra,0xfffff
    80005678:	c8e080e7          	jalr	-882(ra) # 80004302 <readi>
    8000567c:	2501                	sext.w	a0,a0
    8000567e:	1aa91963          	bne	s2,a0,80005830 <exec+0x2d4>
  for(i = 0; i < sz; i += PGSIZE){
    80005682:	009d84bb          	addw	s1,s11,s1
    80005686:	013d09bb          	addw	s3,s10,s3
    8000568a:	1f74f663          	bgeu	s1,s7,80005876 <exec+0x31a>
    pa = walkaddr(pagetable, va + i);
    8000568e:	02049593          	slli	a1,s1,0x20
    80005692:	9181                	srli	a1,a1,0x20
    80005694:	95e2                	add	a1,a1,s8
    80005696:	855a                	mv	a0,s6
    80005698:	ffffc097          	auipc	ra,0xffffc
    8000569c:	b8e080e7          	jalr	-1138(ra) # 80001226 <walkaddr>
    800056a0:	862a                	mv	a2,a0
    if(pa == 0)
    800056a2:	dd45                	beqz	a0,8000565a <exec+0xfe>
      n = PGSIZE;
    800056a4:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    800056a6:	fd49f2e3          	bgeu	s3,s4,8000566a <exec+0x10e>
      n = sz - i;
    800056aa:	894e                	mv	s2,s3
    800056ac:	bf7d                	j	8000566a <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800056ae:	4901                	li	s2,0
  iunlockput(ip);
    800056b0:	8556                	mv	a0,s5
    800056b2:	fffff097          	auipc	ra,0xfffff
    800056b6:	bfe080e7          	jalr	-1026(ra) # 800042b0 <iunlockput>
  end_op();
    800056ba:	fffff097          	auipc	ra,0xfffff
    800056be:	3de080e7          	jalr	990(ra) # 80004a98 <end_op>
  p = myproc();
    800056c2:	ffffc097          	auipc	ra,0xffffc
    800056c6:	4f2080e7          	jalr	1266(ra) # 80001bb4 <myproc>
    800056ca:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    800056cc:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    800056d0:	6785                	lui	a5,0x1
    800056d2:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800056d4:	97ca                	add	a5,a5,s2
    800056d6:	777d                	lui	a4,0xfffff
    800056d8:	8ff9                	and	a5,a5,a4
    800056da:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    800056de:	4691                	li	a3,4
    800056e0:	6609                	lui	a2,0x2
    800056e2:	963e                	add	a2,a2,a5
    800056e4:	85be                	mv	a1,a5
    800056e6:	855a                	mv	a0,s6
    800056e8:	ffffc097          	auipc	ra,0xffffc
    800056ec:	ef2080e7          	jalr	-270(ra) # 800015da <uvmalloc>
    800056f0:	8c2a                	mv	s8,a0
  ip = 0;
    800056f2:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    800056f4:	12050e63          	beqz	a0,80005830 <exec+0x2d4>
  uvmclear(pagetable, sz-2*PGSIZE);
    800056f8:	75f9                	lui	a1,0xffffe
    800056fa:	95aa                	add	a1,a1,a0
    800056fc:	855a                	mv	a0,s6
    800056fe:	ffffc097          	auipc	ra,0xffffc
    80005702:	10c080e7          	jalr	268(ra) # 8000180a <uvmclear>
  stackbase = sp - PGSIZE;
    80005706:	7afd                	lui	s5,0xfffff
    80005708:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    8000570a:	df043783          	ld	a5,-528(s0)
    8000570e:	6388                	ld	a0,0(a5)
    80005710:	c925                	beqz	a0,80005780 <exec+0x224>
    80005712:	e9040993          	addi	s3,s0,-368
    80005716:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    8000571a:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    8000571c:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    8000571e:	ffffc097          	auipc	ra,0xffffc
    80005722:	8fa080e7          	jalr	-1798(ra) # 80001018 <strlen>
    80005726:	0015079b          	addiw	a5,a0,1
    8000572a:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    8000572e:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80005732:	13596663          	bltu	s2,s5,8000585e <exec+0x302>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005736:	df043d83          	ld	s11,-528(s0)
    8000573a:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    8000573e:	8552                	mv	a0,s4
    80005740:	ffffc097          	auipc	ra,0xffffc
    80005744:	8d8080e7          	jalr	-1832(ra) # 80001018 <strlen>
    80005748:	0015069b          	addiw	a3,a0,1
    8000574c:	8652                	mv	a2,s4
    8000574e:	85ca                	mv	a1,s2
    80005750:	855a                	mv	a0,s6
    80005752:	ffffc097          	auipc	ra,0xffffc
    80005756:	0ea080e7          	jalr	234(ra) # 8000183c <copyout>
    8000575a:	10054663          	bltz	a0,80005866 <exec+0x30a>
    ustack[argc] = sp;
    8000575e:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005762:	0485                	addi	s1,s1,1
    80005764:	008d8793          	addi	a5,s11,8
    80005768:	def43823          	sd	a5,-528(s0)
    8000576c:	008db503          	ld	a0,8(s11)
    80005770:	c911                	beqz	a0,80005784 <exec+0x228>
    if(argc >= MAXARG)
    80005772:	09a1                	addi	s3,s3,8
    80005774:	fb3c95e3          	bne	s9,s3,8000571e <exec+0x1c2>
  sz = sz1;
    80005778:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000577c:	4a81                	li	s5,0
    8000577e:	a84d                	j	80005830 <exec+0x2d4>
  sp = sz;
    80005780:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005782:	4481                	li	s1,0
  ustack[argc] = 0;
    80005784:	00349793          	slli	a5,s1,0x3
    80005788:	f9078793          	addi	a5,a5,-112
    8000578c:	97a2                	add	a5,a5,s0
    8000578e:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80005792:	00148693          	addi	a3,s1,1
    80005796:	068e                	slli	a3,a3,0x3
    80005798:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    8000579c:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800057a0:	01597663          	bgeu	s2,s5,800057ac <exec+0x250>
  sz = sz1;
    800057a4:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800057a8:	4a81                	li	s5,0
    800057aa:	a059                	j	80005830 <exec+0x2d4>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800057ac:	e9040613          	addi	a2,s0,-368
    800057b0:	85ca                	mv	a1,s2
    800057b2:	855a                	mv	a0,s6
    800057b4:	ffffc097          	auipc	ra,0xffffc
    800057b8:	088080e7          	jalr	136(ra) # 8000183c <copyout>
    800057bc:	0a054963          	bltz	a0,8000586e <exec+0x312>
  p->trapframe->a1 = sp;
    800057c0:	058bb783          	ld	a5,88(s7)
    800057c4:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800057c8:	de843783          	ld	a5,-536(s0)
    800057cc:	0007c703          	lbu	a4,0(a5)
    800057d0:	cf11                	beqz	a4,800057ec <exec+0x290>
    800057d2:	0785                	addi	a5,a5,1
    if(*s == '/')
    800057d4:	02f00693          	li	a3,47
    800057d8:	a039                	j	800057e6 <exec+0x28a>
      last = s+1;
    800057da:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    800057de:	0785                	addi	a5,a5,1
    800057e0:	fff7c703          	lbu	a4,-1(a5)
    800057e4:	c701                	beqz	a4,800057ec <exec+0x290>
    if(*s == '/')
    800057e6:	fed71ce3          	bne	a4,a3,800057de <exec+0x282>
    800057ea:	bfc5                	j	800057da <exec+0x27e>
  safestrcpy(p->name, last, sizeof(p->name));
    800057ec:	4641                	li	a2,16
    800057ee:	de843583          	ld	a1,-536(s0)
    800057f2:	158b8513          	addi	a0,s7,344
    800057f6:	ffffb097          	auipc	ra,0xffffb
    800057fa:	7f0080e7          	jalr	2032(ra) # 80000fe6 <safestrcpy>
  oldpagetable = p->pagetable;
    800057fe:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80005802:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80005806:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000580a:	058bb783          	ld	a5,88(s7)
    8000580e:	e6843703          	ld	a4,-408(s0)
    80005812:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005814:	058bb783          	ld	a5,88(s7)
    80005818:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000581c:	85ea                	mv	a1,s10
    8000581e:	ffffc097          	auipc	ra,0xffffc
    80005822:	4f6080e7          	jalr	1270(ra) # 80001d14 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005826:	0004851b          	sext.w	a0,s1
    8000582a:	b3f9                	j	800055f8 <exec+0x9c>
    8000582c:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    80005830:	df843583          	ld	a1,-520(s0)
    80005834:	855a                	mv	a0,s6
    80005836:	ffffc097          	auipc	ra,0xffffc
    8000583a:	4de080e7          	jalr	1246(ra) # 80001d14 <proc_freepagetable>
  if(ip){
    8000583e:	da0a93e3          	bnez	s5,800055e4 <exec+0x88>
  return -1;
    80005842:	557d                	li	a0,-1
    80005844:	bb55                	j	800055f8 <exec+0x9c>
    80005846:	df243c23          	sd	s2,-520(s0)
    8000584a:	b7dd                	j	80005830 <exec+0x2d4>
    8000584c:	df243c23          	sd	s2,-520(s0)
    80005850:	b7c5                	j	80005830 <exec+0x2d4>
    80005852:	df243c23          	sd	s2,-520(s0)
    80005856:	bfe9                	j	80005830 <exec+0x2d4>
    80005858:	df243c23          	sd	s2,-520(s0)
    8000585c:	bfd1                	j	80005830 <exec+0x2d4>
  sz = sz1;
    8000585e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005862:	4a81                	li	s5,0
    80005864:	b7f1                	j	80005830 <exec+0x2d4>
  sz = sz1;
    80005866:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000586a:	4a81                	li	s5,0
    8000586c:	b7d1                	j	80005830 <exec+0x2d4>
  sz = sz1;
    8000586e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005872:	4a81                	li	s5,0
    80005874:	bf75                	j	80005830 <exec+0x2d4>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005876:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000587a:	e0843783          	ld	a5,-504(s0)
    8000587e:	0017869b          	addiw	a3,a5,1
    80005882:	e0d43423          	sd	a3,-504(s0)
    80005886:	e0043783          	ld	a5,-512(s0)
    8000588a:	0387879b          	addiw	a5,a5,56
    8000588e:	e8845703          	lhu	a4,-376(s0)
    80005892:	e0e6dfe3          	bge	a3,a4,800056b0 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005896:	2781                	sext.w	a5,a5
    80005898:	e0f43023          	sd	a5,-512(s0)
    8000589c:	03800713          	li	a4,56
    800058a0:	86be                	mv	a3,a5
    800058a2:	e1840613          	addi	a2,s0,-488
    800058a6:	4581                	li	a1,0
    800058a8:	8556                	mv	a0,s5
    800058aa:	fffff097          	auipc	ra,0xfffff
    800058ae:	a58080e7          	jalr	-1448(ra) # 80004302 <readi>
    800058b2:	03800793          	li	a5,56
    800058b6:	f6f51be3          	bne	a0,a5,8000582c <exec+0x2d0>
    if(ph.type != ELF_PROG_LOAD)
    800058ba:	e1842783          	lw	a5,-488(s0)
    800058be:	4705                	li	a4,1
    800058c0:	fae79de3          	bne	a5,a4,8000587a <exec+0x31e>
    if(ph.memsz < ph.filesz)
    800058c4:	e4043483          	ld	s1,-448(s0)
    800058c8:	e3843783          	ld	a5,-456(s0)
    800058cc:	f6f4ede3          	bltu	s1,a5,80005846 <exec+0x2ea>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800058d0:	e2843783          	ld	a5,-472(s0)
    800058d4:	94be                	add	s1,s1,a5
    800058d6:	f6f4ebe3          	bltu	s1,a5,8000584c <exec+0x2f0>
    if(ph.vaddr % PGSIZE != 0)
    800058da:	de043703          	ld	a4,-544(s0)
    800058de:	8ff9                	and	a5,a5,a4
    800058e0:	fbad                	bnez	a5,80005852 <exec+0x2f6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800058e2:	e1c42503          	lw	a0,-484(s0)
    800058e6:	00000097          	auipc	ra,0x0
    800058ea:	c5c080e7          	jalr	-932(ra) # 80005542 <flags2perm>
    800058ee:	86aa                	mv	a3,a0
    800058f0:	8626                	mv	a2,s1
    800058f2:	85ca                	mv	a1,s2
    800058f4:	855a                	mv	a0,s6
    800058f6:	ffffc097          	auipc	ra,0xffffc
    800058fa:	ce4080e7          	jalr	-796(ra) # 800015da <uvmalloc>
    800058fe:	dea43c23          	sd	a0,-520(s0)
    80005902:	d939                	beqz	a0,80005858 <exec+0x2fc>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005904:	e2843c03          	ld	s8,-472(s0)
    80005908:	e2042c83          	lw	s9,-480(s0)
    8000590c:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005910:	f60b83e3          	beqz	s7,80005876 <exec+0x31a>
    80005914:	89de                	mv	s3,s7
    80005916:	4481                	li	s1,0
    80005918:	bb9d                	j	8000568e <exec+0x132>

000000008000591a <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000591a:	7179                	addi	sp,sp,-48
    8000591c:	f406                	sd	ra,40(sp)
    8000591e:	f022                	sd	s0,32(sp)
    80005920:	ec26                	sd	s1,24(sp)
    80005922:	e84a                	sd	s2,16(sp)
    80005924:	1800                	addi	s0,sp,48
    80005926:	892e                	mv	s2,a1
    80005928:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    8000592a:	fdc40593          	addi	a1,s0,-36
    8000592e:	ffffe097          	auipc	ra,0xffffe
    80005932:	878080e7          	jalr	-1928(ra) # 800031a6 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005936:	fdc42703          	lw	a4,-36(s0)
    8000593a:	47bd                	li	a5,15
    8000593c:	02e7eb63          	bltu	a5,a4,80005972 <argfd+0x58>
    80005940:	ffffc097          	auipc	ra,0xffffc
    80005944:	274080e7          	jalr	628(ra) # 80001bb4 <myproc>
    80005948:	fdc42703          	lw	a4,-36(s0)
    8000594c:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7fdbbda2>
    80005950:	078e                	slli	a5,a5,0x3
    80005952:	953e                	add	a0,a0,a5
    80005954:	611c                	ld	a5,0(a0)
    80005956:	c385                	beqz	a5,80005976 <argfd+0x5c>
    return -1;
  if(pfd)
    80005958:	00090463          	beqz	s2,80005960 <argfd+0x46>
    *pfd = fd;
    8000595c:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005960:	4501                	li	a0,0
  if(pf)
    80005962:	c091                	beqz	s1,80005966 <argfd+0x4c>
    *pf = f;
    80005964:	e09c                	sd	a5,0(s1)
}
    80005966:	70a2                	ld	ra,40(sp)
    80005968:	7402                	ld	s0,32(sp)
    8000596a:	64e2                	ld	s1,24(sp)
    8000596c:	6942                	ld	s2,16(sp)
    8000596e:	6145                	addi	sp,sp,48
    80005970:	8082                	ret
    return -1;
    80005972:	557d                	li	a0,-1
    80005974:	bfcd                	j	80005966 <argfd+0x4c>
    80005976:	557d                	li	a0,-1
    80005978:	b7fd                	j	80005966 <argfd+0x4c>

000000008000597a <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000597a:	1101                	addi	sp,sp,-32
    8000597c:	ec06                	sd	ra,24(sp)
    8000597e:	e822                	sd	s0,16(sp)
    80005980:	e426                	sd	s1,8(sp)
    80005982:	1000                	addi	s0,sp,32
    80005984:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005986:	ffffc097          	auipc	ra,0xffffc
    8000598a:	22e080e7          	jalr	558(ra) # 80001bb4 <myproc>
    8000598e:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005990:	0d050793          	addi	a5,a0,208
    80005994:	4501                	li	a0,0
    80005996:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005998:	6398                	ld	a4,0(a5)
    8000599a:	cb19                	beqz	a4,800059b0 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000599c:	2505                	addiw	a0,a0,1
    8000599e:	07a1                	addi	a5,a5,8
    800059a0:	fed51ce3          	bne	a0,a3,80005998 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800059a4:	557d                	li	a0,-1
}
    800059a6:	60e2                	ld	ra,24(sp)
    800059a8:	6442                	ld	s0,16(sp)
    800059aa:	64a2                	ld	s1,8(sp)
    800059ac:	6105                	addi	sp,sp,32
    800059ae:	8082                	ret
      p->ofile[fd] = f;
    800059b0:	01a50793          	addi	a5,a0,26
    800059b4:	078e                	slli	a5,a5,0x3
    800059b6:	963e                	add	a2,a2,a5
    800059b8:	e204                	sd	s1,0(a2)
      return fd;
    800059ba:	b7f5                	j	800059a6 <fdalloc+0x2c>

00000000800059bc <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800059bc:	715d                	addi	sp,sp,-80
    800059be:	e486                	sd	ra,72(sp)
    800059c0:	e0a2                	sd	s0,64(sp)
    800059c2:	fc26                	sd	s1,56(sp)
    800059c4:	f84a                	sd	s2,48(sp)
    800059c6:	f44e                	sd	s3,40(sp)
    800059c8:	f052                	sd	s4,32(sp)
    800059ca:	ec56                	sd	s5,24(sp)
    800059cc:	e85a                	sd	s6,16(sp)
    800059ce:	0880                	addi	s0,sp,80
    800059d0:	8b2e                	mv	s6,a1
    800059d2:	89b2                	mv	s3,a2
    800059d4:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800059d6:	fb040593          	addi	a1,s0,-80
    800059da:	fffff097          	auipc	ra,0xfffff
    800059de:	e3e080e7          	jalr	-450(ra) # 80004818 <nameiparent>
    800059e2:	84aa                	mv	s1,a0
    800059e4:	14050f63          	beqz	a0,80005b42 <create+0x186>
    return 0;

  ilock(dp);
    800059e8:	ffffe097          	auipc	ra,0xffffe
    800059ec:	666080e7          	jalr	1638(ra) # 8000404e <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800059f0:	4601                	li	a2,0
    800059f2:	fb040593          	addi	a1,s0,-80
    800059f6:	8526                	mv	a0,s1
    800059f8:	fffff097          	auipc	ra,0xfffff
    800059fc:	b3a080e7          	jalr	-1222(ra) # 80004532 <dirlookup>
    80005a00:	8aaa                	mv	s5,a0
    80005a02:	c931                	beqz	a0,80005a56 <create+0x9a>
    iunlockput(dp);
    80005a04:	8526                	mv	a0,s1
    80005a06:	fffff097          	auipc	ra,0xfffff
    80005a0a:	8aa080e7          	jalr	-1878(ra) # 800042b0 <iunlockput>
    ilock(ip);
    80005a0e:	8556                	mv	a0,s5
    80005a10:	ffffe097          	auipc	ra,0xffffe
    80005a14:	63e080e7          	jalr	1598(ra) # 8000404e <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005a18:	000b059b          	sext.w	a1,s6
    80005a1c:	4789                	li	a5,2
    80005a1e:	02f59563          	bne	a1,a5,80005a48 <create+0x8c>
    80005a22:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7fdbbdcc>
    80005a26:	37f9                	addiw	a5,a5,-2
    80005a28:	17c2                	slli	a5,a5,0x30
    80005a2a:	93c1                	srli	a5,a5,0x30
    80005a2c:	4705                	li	a4,1
    80005a2e:	00f76d63          	bltu	a4,a5,80005a48 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005a32:	8556                	mv	a0,s5
    80005a34:	60a6                	ld	ra,72(sp)
    80005a36:	6406                	ld	s0,64(sp)
    80005a38:	74e2                	ld	s1,56(sp)
    80005a3a:	7942                	ld	s2,48(sp)
    80005a3c:	79a2                	ld	s3,40(sp)
    80005a3e:	7a02                	ld	s4,32(sp)
    80005a40:	6ae2                	ld	s5,24(sp)
    80005a42:	6b42                	ld	s6,16(sp)
    80005a44:	6161                	addi	sp,sp,80
    80005a46:	8082                	ret
    iunlockput(ip);
    80005a48:	8556                	mv	a0,s5
    80005a4a:	fffff097          	auipc	ra,0xfffff
    80005a4e:	866080e7          	jalr	-1946(ra) # 800042b0 <iunlockput>
    return 0;
    80005a52:	4a81                	li	s5,0
    80005a54:	bff9                	j	80005a32 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    80005a56:	85da                	mv	a1,s6
    80005a58:	4088                	lw	a0,0(s1)
    80005a5a:	ffffe097          	auipc	ra,0xffffe
    80005a5e:	456080e7          	jalr	1110(ra) # 80003eb0 <ialloc>
    80005a62:	8a2a                	mv	s4,a0
    80005a64:	c539                	beqz	a0,80005ab2 <create+0xf6>
  ilock(ip);
    80005a66:	ffffe097          	auipc	ra,0xffffe
    80005a6a:	5e8080e7          	jalr	1512(ra) # 8000404e <ilock>
  ip->major = major;
    80005a6e:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005a72:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005a76:	4905                	li	s2,1
    80005a78:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80005a7c:	8552                	mv	a0,s4
    80005a7e:	ffffe097          	auipc	ra,0xffffe
    80005a82:	504080e7          	jalr	1284(ra) # 80003f82 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005a86:	000b059b          	sext.w	a1,s6
    80005a8a:	03258b63          	beq	a1,s2,80005ac0 <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    80005a8e:	004a2603          	lw	a2,4(s4)
    80005a92:	fb040593          	addi	a1,s0,-80
    80005a96:	8526                	mv	a0,s1
    80005a98:	fffff097          	auipc	ra,0xfffff
    80005a9c:	cb0080e7          	jalr	-848(ra) # 80004748 <dirlink>
    80005aa0:	06054f63          	bltz	a0,80005b1e <create+0x162>
  iunlockput(dp);
    80005aa4:	8526                	mv	a0,s1
    80005aa6:	fffff097          	auipc	ra,0xfffff
    80005aaa:	80a080e7          	jalr	-2038(ra) # 800042b0 <iunlockput>
  return ip;
    80005aae:	8ad2                	mv	s5,s4
    80005ab0:	b749                	j	80005a32 <create+0x76>
    iunlockput(dp);
    80005ab2:	8526                	mv	a0,s1
    80005ab4:	ffffe097          	auipc	ra,0xffffe
    80005ab8:	7fc080e7          	jalr	2044(ra) # 800042b0 <iunlockput>
    return 0;
    80005abc:	8ad2                	mv	s5,s4
    80005abe:	bf95                	j	80005a32 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005ac0:	004a2603          	lw	a2,4(s4)
    80005ac4:	00003597          	auipc	a1,0x3
    80005ac8:	dec58593          	addi	a1,a1,-532 # 800088b0 <syscalls+0x2c8>
    80005acc:	8552                	mv	a0,s4
    80005ace:	fffff097          	auipc	ra,0xfffff
    80005ad2:	c7a080e7          	jalr	-902(ra) # 80004748 <dirlink>
    80005ad6:	04054463          	bltz	a0,80005b1e <create+0x162>
    80005ada:	40d0                	lw	a2,4(s1)
    80005adc:	00003597          	auipc	a1,0x3
    80005ae0:	ddc58593          	addi	a1,a1,-548 # 800088b8 <syscalls+0x2d0>
    80005ae4:	8552                	mv	a0,s4
    80005ae6:	fffff097          	auipc	ra,0xfffff
    80005aea:	c62080e7          	jalr	-926(ra) # 80004748 <dirlink>
    80005aee:	02054863          	bltz	a0,80005b1e <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    80005af2:	004a2603          	lw	a2,4(s4)
    80005af6:	fb040593          	addi	a1,s0,-80
    80005afa:	8526                	mv	a0,s1
    80005afc:	fffff097          	auipc	ra,0xfffff
    80005b00:	c4c080e7          	jalr	-948(ra) # 80004748 <dirlink>
    80005b04:	00054d63          	bltz	a0,80005b1e <create+0x162>
    dp->nlink++;  // for ".."
    80005b08:	04a4d783          	lhu	a5,74(s1)
    80005b0c:	2785                	addiw	a5,a5,1
    80005b0e:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005b12:	8526                	mv	a0,s1
    80005b14:	ffffe097          	auipc	ra,0xffffe
    80005b18:	46e080e7          	jalr	1134(ra) # 80003f82 <iupdate>
    80005b1c:	b761                	j	80005aa4 <create+0xe8>
  ip->nlink = 0;
    80005b1e:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005b22:	8552                	mv	a0,s4
    80005b24:	ffffe097          	auipc	ra,0xffffe
    80005b28:	45e080e7          	jalr	1118(ra) # 80003f82 <iupdate>
  iunlockput(ip);
    80005b2c:	8552                	mv	a0,s4
    80005b2e:	ffffe097          	auipc	ra,0xffffe
    80005b32:	782080e7          	jalr	1922(ra) # 800042b0 <iunlockput>
  iunlockput(dp);
    80005b36:	8526                	mv	a0,s1
    80005b38:	ffffe097          	auipc	ra,0xffffe
    80005b3c:	778080e7          	jalr	1912(ra) # 800042b0 <iunlockput>
  return 0;
    80005b40:	bdcd                	j	80005a32 <create+0x76>
    return 0;
    80005b42:	8aaa                	mv	s5,a0
    80005b44:	b5fd                	j	80005a32 <create+0x76>

0000000080005b46 <sys_dup>:
{
    80005b46:	7179                	addi	sp,sp,-48
    80005b48:	f406                	sd	ra,40(sp)
    80005b4a:	f022                	sd	s0,32(sp)
    80005b4c:	ec26                	sd	s1,24(sp)
    80005b4e:	e84a                	sd	s2,16(sp)
    80005b50:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005b52:	fd840613          	addi	a2,s0,-40
    80005b56:	4581                	li	a1,0
    80005b58:	4501                	li	a0,0
    80005b5a:	00000097          	auipc	ra,0x0
    80005b5e:	dc0080e7          	jalr	-576(ra) # 8000591a <argfd>
    return -1;
    80005b62:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005b64:	02054363          	bltz	a0,80005b8a <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    80005b68:	fd843903          	ld	s2,-40(s0)
    80005b6c:	854a                	mv	a0,s2
    80005b6e:	00000097          	auipc	ra,0x0
    80005b72:	e0c080e7          	jalr	-500(ra) # 8000597a <fdalloc>
    80005b76:	84aa                	mv	s1,a0
    return -1;
    80005b78:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005b7a:	00054863          	bltz	a0,80005b8a <sys_dup+0x44>
  filedup(f);
    80005b7e:	854a                	mv	a0,s2
    80005b80:	fffff097          	auipc	ra,0xfffff
    80005b84:	310080e7          	jalr	784(ra) # 80004e90 <filedup>
  return fd;
    80005b88:	87a6                	mv	a5,s1
}
    80005b8a:	853e                	mv	a0,a5
    80005b8c:	70a2                	ld	ra,40(sp)
    80005b8e:	7402                	ld	s0,32(sp)
    80005b90:	64e2                	ld	s1,24(sp)
    80005b92:	6942                	ld	s2,16(sp)
    80005b94:	6145                	addi	sp,sp,48
    80005b96:	8082                	ret

0000000080005b98 <sys_read>:
{
    80005b98:	7179                	addi	sp,sp,-48
    80005b9a:	f406                	sd	ra,40(sp)
    80005b9c:	f022                	sd	s0,32(sp)
    80005b9e:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005ba0:	fd840593          	addi	a1,s0,-40
    80005ba4:	4505                	li	a0,1
    80005ba6:	ffffd097          	auipc	ra,0xffffd
    80005baa:	620080e7          	jalr	1568(ra) # 800031c6 <argaddr>
  argint(2, &n);
    80005bae:	fe440593          	addi	a1,s0,-28
    80005bb2:	4509                	li	a0,2
    80005bb4:	ffffd097          	auipc	ra,0xffffd
    80005bb8:	5f2080e7          	jalr	1522(ra) # 800031a6 <argint>
  if(argfd(0, 0, &f) < 0)
    80005bbc:	fe840613          	addi	a2,s0,-24
    80005bc0:	4581                	li	a1,0
    80005bc2:	4501                	li	a0,0
    80005bc4:	00000097          	auipc	ra,0x0
    80005bc8:	d56080e7          	jalr	-682(ra) # 8000591a <argfd>
    80005bcc:	87aa                	mv	a5,a0
    return -1;
    80005bce:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005bd0:	0007cc63          	bltz	a5,80005be8 <sys_read+0x50>
  return fileread(f, p, n);
    80005bd4:	fe442603          	lw	a2,-28(s0)
    80005bd8:	fd843583          	ld	a1,-40(s0)
    80005bdc:	fe843503          	ld	a0,-24(s0)
    80005be0:	fffff097          	auipc	ra,0xfffff
    80005be4:	43c080e7          	jalr	1084(ra) # 8000501c <fileread>
}
    80005be8:	70a2                	ld	ra,40(sp)
    80005bea:	7402                	ld	s0,32(sp)
    80005bec:	6145                	addi	sp,sp,48
    80005bee:	8082                	ret

0000000080005bf0 <sys_write>:
{
    80005bf0:	7179                	addi	sp,sp,-48
    80005bf2:	f406                	sd	ra,40(sp)
    80005bf4:	f022                	sd	s0,32(sp)
    80005bf6:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005bf8:	fd840593          	addi	a1,s0,-40
    80005bfc:	4505                	li	a0,1
    80005bfe:	ffffd097          	auipc	ra,0xffffd
    80005c02:	5c8080e7          	jalr	1480(ra) # 800031c6 <argaddr>
  argint(2, &n);
    80005c06:	fe440593          	addi	a1,s0,-28
    80005c0a:	4509                	li	a0,2
    80005c0c:	ffffd097          	auipc	ra,0xffffd
    80005c10:	59a080e7          	jalr	1434(ra) # 800031a6 <argint>
  if(argfd(0, 0, &f) < 0)
    80005c14:	fe840613          	addi	a2,s0,-24
    80005c18:	4581                	li	a1,0
    80005c1a:	4501                	li	a0,0
    80005c1c:	00000097          	auipc	ra,0x0
    80005c20:	cfe080e7          	jalr	-770(ra) # 8000591a <argfd>
    80005c24:	87aa                	mv	a5,a0
    return -1;
    80005c26:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005c28:	0007cc63          	bltz	a5,80005c40 <sys_write+0x50>
  return filewrite(f, p, n);
    80005c2c:	fe442603          	lw	a2,-28(s0)
    80005c30:	fd843583          	ld	a1,-40(s0)
    80005c34:	fe843503          	ld	a0,-24(s0)
    80005c38:	fffff097          	auipc	ra,0xfffff
    80005c3c:	4a6080e7          	jalr	1190(ra) # 800050de <filewrite>
}
    80005c40:	70a2                	ld	ra,40(sp)
    80005c42:	7402                	ld	s0,32(sp)
    80005c44:	6145                	addi	sp,sp,48
    80005c46:	8082                	ret

0000000080005c48 <sys_close>:
{
    80005c48:	1101                	addi	sp,sp,-32
    80005c4a:	ec06                	sd	ra,24(sp)
    80005c4c:	e822                	sd	s0,16(sp)
    80005c4e:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005c50:	fe040613          	addi	a2,s0,-32
    80005c54:	fec40593          	addi	a1,s0,-20
    80005c58:	4501                	li	a0,0
    80005c5a:	00000097          	auipc	ra,0x0
    80005c5e:	cc0080e7          	jalr	-832(ra) # 8000591a <argfd>
    return -1;
    80005c62:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005c64:	02054463          	bltz	a0,80005c8c <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005c68:	ffffc097          	auipc	ra,0xffffc
    80005c6c:	f4c080e7          	jalr	-180(ra) # 80001bb4 <myproc>
    80005c70:	fec42783          	lw	a5,-20(s0)
    80005c74:	07e9                	addi	a5,a5,26
    80005c76:	078e                	slli	a5,a5,0x3
    80005c78:	953e                	add	a0,a0,a5
    80005c7a:	00053023          	sd	zero,0(a0)
  fileclose(f);
    80005c7e:	fe043503          	ld	a0,-32(s0)
    80005c82:	fffff097          	auipc	ra,0xfffff
    80005c86:	260080e7          	jalr	608(ra) # 80004ee2 <fileclose>
  return 0;
    80005c8a:	4781                	li	a5,0
}
    80005c8c:	853e                	mv	a0,a5
    80005c8e:	60e2                	ld	ra,24(sp)
    80005c90:	6442                	ld	s0,16(sp)
    80005c92:	6105                	addi	sp,sp,32
    80005c94:	8082                	ret

0000000080005c96 <sys_fstat>:
{
    80005c96:	1101                	addi	sp,sp,-32
    80005c98:	ec06                	sd	ra,24(sp)
    80005c9a:	e822                	sd	s0,16(sp)
    80005c9c:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005c9e:	fe040593          	addi	a1,s0,-32
    80005ca2:	4505                	li	a0,1
    80005ca4:	ffffd097          	auipc	ra,0xffffd
    80005ca8:	522080e7          	jalr	1314(ra) # 800031c6 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005cac:	fe840613          	addi	a2,s0,-24
    80005cb0:	4581                	li	a1,0
    80005cb2:	4501                	li	a0,0
    80005cb4:	00000097          	auipc	ra,0x0
    80005cb8:	c66080e7          	jalr	-922(ra) # 8000591a <argfd>
    80005cbc:	87aa                	mv	a5,a0
    return -1;
    80005cbe:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005cc0:	0007ca63          	bltz	a5,80005cd4 <sys_fstat+0x3e>
  return filestat(f, st);
    80005cc4:	fe043583          	ld	a1,-32(s0)
    80005cc8:	fe843503          	ld	a0,-24(s0)
    80005ccc:	fffff097          	auipc	ra,0xfffff
    80005cd0:	2de080e7          	jalr	734(ra) # 80004faa <filestat>
}
    80005cd4:	60e2                	ld	ra,24(sp)
    80005cd6:	6442                	ld	s0,16(sp)
    80005cd8:	6105                	addi	sp,sp,32
    80005cda:	8082                	ret

0000000080005cdc <sys_link>:
{
    80005cdc:	7169                	addi	sp,sp,-304
    80005cde:	f606                	sd	ra,296(sp)
    80005ce0:	f222                	sd	s0,288(sp)
    80005ce2:	ee26                	sd	s1,280(sp)
    80005ce4:	ea4a                	sd	s2,272(sp)
    80005ce6:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005ce8:	08000613          	li	a2,128
    80005cec:	ed040593          	addi	a1,s0,-304
    80005cf0:	4501                	li	a0,0
    80005cf2:	ffffd097          	auipc	ra,0xffffd
    80005cf6:	4f4080e7          	jalr	1268(ra) # 800031e6 <argstr>
    return -1;
    80005cfa:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005cfc:	10054e63          	bltz	a0,80005e18 <sys_link+0x13c>
    80005d00:	08000613          	li	a2,128
    80005d04:	f5040593          	addi	a1,s0,-176
    80005d08:	4505                	li	a0,1
    80005d0a:	ffffd097          	auipc	ra,0xffffd
    80005d0e:	4dc080e7          	jalr	1244(ra) # 800031e6 <argstr>
    return -1;
    80005d12:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005d14:	10054263          	bltz	a0,80005e18 <sys_link+0x13c>
  begin_op();
    80005d18:	fffff097          	auipc	ra,0xfffff
    80005d1c:	d02080e7          	jalr	-766(ra) # 80004a1a <begin_op>
  if((ip = namei(old)) == 0){
    80005d20:	ed040513          	addi	a0,s0,-304
    80005d24:	fffff097          	auipc	ra,0xfffff
    80005d28:	ad6080e7          	jalr	-1322(ra) # 800047fa <namei>
    80005d2c:	84aa                	mv	s1,a0
    80005d2e:	c551                	beqz	a0,80005dba <sys_link+0xde>
  ilock(ip);
    80005d30:	ffffe097          	auipc	ra,0xffffe
    80005d34:	31e080e7          	jalr	798(ra) # 8000404e <ilock>
  if(ip->type == T_DIR){
    80005d38:	04449703          	lh	a4,68(s1)
    80005d3c:	4785                	li	a5,1
    80005d3e:	08f70463          	beq	a4,a5,80005dc6 <sys_link+0xea>
  ip->nlink++;
    80005d42:	04a4d783          	lhu	a5,74(s1)
    80005d46:	2785                	addiw	a5,a5,1
    80005d48:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005d4c:	8526                	mv	a0,s1
    80005d4e:	ffffe097          	auipc	ra,0xffffe
    80005d52:	234080e7          	jalr	564(ra) # 80003f82 <iupdate>
  iunlock(ip);
    80005d56:	8526                	mv	a0,s1
    80005d58:	ffffe097          	auipc	ra,0xffffe
    80005d5c:	3b8080e7          	jalr	952(ra) # 80004110 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005d60:	fd040593          	addi	a1,s0,-48
    80005d64:	f5040513          	addi	a0,s0,-176
    80005d68:	fffff097          	auipc	ra,0xfffff
    80005d6c:	ab0080e7          	jalr	-1360(ra) # 80004818 <nameiparent>
    80005d70:	892a                	mv	s2,a0
    80005d72:	c935                	beqz	a0,80005de6 <sys_link+0x10a>
  ilock(dp);
    80005d74:	ffffe097          	auipc	ra,0xffffe
    80005d78:	2da080e7          	jalr	730(ra) # 8000404e <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005d7c:	00092703          	lw	a4,0(s2)
    80005d80:	409c                	lw	a5,0(s1)
    80005d82:	04f71d63          	bne	a4,a5,80005ddc <sys_link+0x100>
    80005d86:	40d0                	lw	a2,4(s1)
    80005d88:	fd040593          	addi	a1,s0,-48
    80005d8c:	854a                	mv	a0,s2
    80005d8e:	fffff097          	auipc	ra,0xfffff
    80005d92:	9ba080e7          	jalr	-1606(ra) # 80004748 <dirlink>
    80005d96:	04054363          	bltz	a0,80005ddc <sys_link+0x100>
  iunlockput(dp);
    80005d9a:	854a                	mv	a0,s2
    80005d9c:	ffffe097          	auipc	ra,0xffffe
    80005da0:	514080e7          	jalr	1300(ra) # 800042b0 <iunlockput>
  iput(ip);
    80005da4:	8526                	mv	a0,s1
    80005da6:	ffffe097          	auipc	ra,0xffffe
    80005daa:	462080e7          	jalr	1122(ra) # 80004208 <iput>
  end_op();
    80005dae:	fffff097          	auipc	ra,0xfffff
    80005db2:	cea080e7          	jalr	-790(ra) # 80004a98 <end_op>
  return 0;
    80005db6:	4781                	li	a5,0
    80005db8:	a085                	j	80005e18 <sys_link+0x13c>
    end_op();
    80005dba:	fffff097          	auipc	ra,0xfffff
    80005dbe:	cde080e7          	jalr	-802(ra) # 80004a98 <end_op>
    return -1;
    80005dc2:	57fd                	li	a5,-1
    80005dc4:	a891                	j	80005e18 <sys_link+0x13c>
    iunlockput(ip);
    80005dc6:	8526                	mv	a0,s1
    80005dc8:	ffffe097          	auipc	ra,0xffffe
    80005dcc:	4e8080e7          	jalr	1256(ra) # 800042b0 <iunlockput>
    end_op();
    80005dd0:	fffff097          	auipc	ra,0xfffff
    80005dd4:	cc8080e7          	jalr	-824(ra) # 80004a98 <end_op>
    return -1;
    80005dd8:	57fd                	li	a5,-1
    80005dda:	a83d                	j	80005e18 <sys_link+0x13c>
    iunlockput(dp);
    80005ddc:	854a                	mv	a0,s2
    80005dde:	ffffe097          	auipc	ra,0xffffe
    80005de2:	4d2080e7          	jalr	1234(ra) # 800042b0 <iunlockput>
  ilock(ip);
    80005de6:	8526                	mv	a0,s1
    80005de8:	ffffe097          	auipc	ra,0xffffe
    80005dec:	266080e7          	jalr	614(ra) # 8000404e <ilock>
  ip->nlink--;
    80005df0:	04a4d783          	lhu	a5,74(s1)
    80005df4:	37fd                	addiw	a5,a5,-1
    80005df6:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005dfa:	8526                	mv	a0,s1
    80005dfc:	ffffe097          	auipc	ra,0xffffe
    80005e00:	186080e7          	jalr	390(ra) # 80003f82 <iupdate>
  iunlockput(ip);
    80005e04:	8526                	mv	a0,s1
    80005e06:	ffffe097          	auipc	ra,0xffffe
    80005e0a:	4aa080e7          	jalr	1194(ra) # 800042b0 <iunlockput>
  end_op();
    80005e0e:	fffff097          	auipc	ra,0xfffff
    80005e12:	c8a080e7          	jalr	-886(ra) # 80004a98 <end_op>
  return -1;
    80005e16:	57fd                	li	a5,-1
}
    80005e18:	853e                	mv	a0,a5
    80005e1a:	70b2                	ld	ra,296(sp)
    80005e1c:	7412                	ld	s0,288(sp)
    80005e1e:	64f2                	ld	s1,280(sp)
    80005e20:	6952                	ld	s2,272(sp)
    80005e22:	6155                	addi	sp,sp,304
    80005e24:	8082                	ret

0000000080005e26 <sys_unlink>:
{
    80005e26:	7151                	addi	sp,sp,-240
    80005e28:	f586                	sd	ra,232(sp)
    80005e2a:	f1a2                	sd	s0,224(sp)
    80005e2c:	eda6                	sd	s1,216(sp)
    80005e2e:	e9ca                	sd	s2,208(sp)
    80005e30:	e5ce                	sd	s3,200(sp)
    80005e32:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005e34:	08000613          	li	a2,128
    80005e38:	f3040593          	addi	a1,s0,-208
    80005e3c:	4501                	li	a0,0
    80005e3e:	ffffd097          	auipc	ra,0xffffd
    80005e42:	3a8080e7          	jalr	936(ra) # 800031e6 <argstr>
    80005e46:	18054163          	bltz	a0,80005fc8 <sys_unlink+0x1a2>
  begin_op();
    80005e4a:	fffff097          	auipc	ra,0xfffff
    80005e4e:	bd0080e7          	jalr	-1072(ra) # 80004a1a <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005e52:	fb040593          	addi	a1,s0,-80
    80005e56:	f3040513          	addi	a0,s0,-208
    80005e5a:	fffff097          	auipc	ra,0xfffff
    80005e5e:	9be080e7          	jalr	-1602(ra) # 80004818 <nameiparent>
    80005e62:	84aa                	mv	s1,a0
    80005e64:	c979                	beqz	a0,80005f3a <sys_unlink+0x114>
  ilock(dp);
    80005e66:	ffffe097          	auipc	ra,0xffffe
    80005e6a:	1e8080e7          	jalr	488(ra) # 8000404e <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005e6e:	00003597          	auipc	a1,0x3
    80005e72:	a4258593          	addi	a1,a1,-1470 # 800088b0 <syscalls+0x2c8>
    80005e76:	fb040513          	addi	a0,s0,-80
    80005e7a:	ffffe097          	auipc	ra,0xffffe
    80005e7e:	69e080e7          	jalr	1694(ra) # 80004518 <namecmp>
    80005e82:	14050a63          	beqz	a0,80005fd6 <sys_unlink+0x1b0>
    80005e86:	00003597          	auipc	a1,0x3
    80005e8a:	a3258593          	addi	a1,a1,-1486 # 800088b8 <syscalls+0x2d0>
    80005e8e:	fb040513          	addi	a0,s0,-80
    80005e92:	ffffe097          	auipc	ra,0xffffe
    80005e96:	686080e7          	jalr	1670(ra) # 80004518 <namecmp>
    80005e9a:	12050e63          	beqz	a0,80005fd6 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005e9e:	f2c40613          	addi	a2,s0,-212
    80005ea2:	fb040593          	addi	a1,s0,-80
    80005ea6:	8526                	mv	a0,s1
    80005ea8:	ffffe097          	auipc	ra,0xffffe
    80005eac:	68a080e7          	jalr	1674(ra) # 80004532 <dirlookup>
    80005eb0:	892a                	mv	s2,a0
    80005eb2:	12050263          	beqz	a0,80005fd6 <sys_unlink+0x1b0>
  ilock(ip);
    80005eb6:	ffffe097          	auipc	ra,0xffffe
    80005eba:	198080e7          	jalr	408(ra) # 8000404e <ilock>
  if(ip->nlink < 1)
    80005ebe:	04a91783          	lh	a5,74(s2)
    80005ec2:	08f05263          	blez	a5,80005f46 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005ec6:	04491703          	lh	a4,68(s2)
    80005eca:	4785                	li	a5,1
    80005ecc:	08f70563          	beq	a4,a5,80005f56 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005ed0:	4641                	li	a2,16
    80005ed2:	4581                	li	a1,0
    80005ed4:	fc040513          	addi	a0,s0,-64
    80005ed8:	ffffb097          	auipc	ra,0xffffb
    80005edc:	fc4080e7          	jalr	-60(ra) # 80000e9c <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005ee0:	4741                	li	a4,16
    80005ee2:	f2c42683          	lw	a3,-212(s0)
    80005ee6:	fc040613          	addi	a2,s0,-64
    80005eea:	4581                	li	a1,0
    80005eec:	8526                	mv	a0,s1
    80005eee:	ffffe097          	auipc	ra,0xffffe
    80005ef2:	50c080e7          	jalr	1292(ra) # 800043fa <writei>
    80005ef6:	47c1                	li	a5,16
    80005ef8:	0af51563          	bne	a0,a5,80005fa2 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005efc:	04491703          	lh	a4,68(s2)
    80005f00:	4785                	li	a5,1
    80005f02:	0af70863          	beq	a4,a5,80005fb2 <sys_unlink+0x18c>
  iunlockput(dp);
    80005f06:	8526                	mv	a0,s1
    80005f08:	ffffe097          	auipc	ra,0xffffe
    80005f0c:	3a8080e7          	jalr	936(ra) # 800042b0 <iunlockput>
  ip->nlink--;
    80005f10:	04a95783          	lhu	a5,74(s2)
    80005f14:	37fd                	addiw	a5,a5,-1
    80005f16:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005f1a:	854a                	mv	a0,s2
    80005f1c:	ffffe097          	auipc	ra,0xffffe
    80005f20:	066080e7          	jalr	102(ra) # 80003f82 <iupdate>
  iunlockput(ip);
    80005f24:	854a                	mv	a0,s2
    80005f26:	ffffe097          	auipc	ra,0xffffe
    80005f2a:	38a080e7          	jalr	906(ra) # 800042b0 <iunlockput>
  end_op();
    80005f2e:	fffff097          	auipc	ra,0xfffff
    80005f32:	b6a080e7          	jalr	-1174(ra) # 80004a98 <end_op>
  return 0;
    80005f36:	4501                	li	a0,0
    80005f38:	a84d                	j	80005fea <sys_unlink+0x1c4>
    end_op();
    80005f3a:	fffff097          	auipc	ra,0xfffff
    80005f3e:	b5e080e7          	jalr	-1186(ra) # 80004a98 <end_op>
    return -1;
    80005f42:	557d                	li	a0,-1
    80005f44:	a05d                	j	80005fea <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005f46:	00003517          	auipc	a0,0x3
    80005f4a:	97a50513          	addi	a0,a0,-1670 # 800088c0 <syscalls+0x2d8>
    80005f4e:	ffffa097          	auipc	ra,0xffffa
    80005f52:	5f2080e7          	jalr	1522(ra) # 80000540 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005f56:	04c92703          	lw	a4,76(s2)
    80005f5a:	02000793          	li	a5,32
    80005f5e:	f6e7f9e3          	bgeu	a5,a4,80005ed0 <sys_unlink+0xaa>
    80005f62:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005f66:	4741                	li	a4,16
    80005f68:	86ce                	mv	a3,s3
    80005f6a:	f1840613          	addi	a2,s0,-232
    80005f6e:	4581                	li	a1,0
    80005f70:	854a                	mv	a0,s2
    80005f72:	ffffe097          	auipc	ra,0xffffe
    80005f76:	390080e7          	jalr	912(ra) # 80004302 <readi>
    80005f7a:	47c1                	li	a5,16
    80005f7c:	00f51b63          	bne	a0,a5,80005f92 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005f80:	f1845783          	lhu	a5,-232(s0)
    80005f84:	e7a1                	bnez	a5,80005fcc <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005f86:	29c1                	addiw	s3,s3,16
    80005f88:	04c92783          	lw	a5,76(s2)
    80005f8c:	fcf9ede3          	bltu	s3,a5,80005f66 <sys_unlink+0x140>
    80005f90:	b781                	j	80005ed0 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005f92:	00003517          	auipc	a0,0x3
    80005f96:	94650513          	addi	a0,a0,-1722 # 800088d8 <syscalls+0x2f0>
    80005f9a:	ffffa097          	auipc	ra,0xffffa
    80005f9e:	5a6080e7          	jalr	1446(ra) # 80000540 <panic>
    panic("unlink: writei");
    80005fa2:	00003517          	auipc	a0,0x3
    80005fa6:	94e50513          	addi	a0,a0,-1714 # 800088f0 <syscalls+0x308>
    80005faa:	ffffa097          	auipc	ra,0xffffa
    80005fae:	596080e7          	jalr	1430(ra) # 80000540 <panic>
    dp->nlink--;
    80005fb2:	04a4d783          	lhu	a5,74(s1)
    80005fb6:	37fd                	addiw	a5,a5,-1
    80005fb8:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005fbc:	8526                	mv	a0,s1
    80005fbe:	ffffe097          	auipc	ra,0xffffe
    80005fc2:	fc4080e7          	jalr	-60(ra) # 80003f82 <iupdate>
    80005fc6:	b781                	j	80005f06 <sys_unlink+0xe0>
    return -1;
    80005fc8:	557d                	li	a0,-1
    80005fca:	a005                	j	80005fea <sys_unlink+0x1c4>
    iunlockput(ip);
    80005fcc:	854a                	mv	a0,s2
    80005fce:	ffffe097          	auipc	ra,0xffffe
    80005fd2:	2e2080e7          	jalr	738(ra) # 800042b0 <iunlockput>
  iunlockput(dp);
    80005fd6:	8526                	mv	a0,s1
    80005fd8:	ffffe097          	auipc	ra,0xffffe
    80005fdc:	2d8080e7          	jalr	728(ra) # 800042b0 <iunlockput>
  end_op();
    80005fe0:	fffff097          	auipc	ra,0xfffff
    80005fe4:	ab8080e7          	jalr	-1352(ra) # 80004a98 <end_op>
  return -1;
    80005fe8:	557d                	li	a0,-1
}
    80005fea:	70ae                	ld	ra,232(sp)
    80005fec:	740e                	ld	s0,224(sp)
    80005fee:	64ee                	ld	s1,216(sp)
    80005ff0:	694e                	ld	s2,208(sp)
    80005ff2:	69ae                	ld	s3,200(sp)
    80005ff4:	616d                	addi	sp,sp,240
    80005ff6:	8082                	ret

0000000080005ff8 <sys_open>:

uint64
sys_open(void)
{
    80005ff8:	7131                	addi	sp,sp,-192
    80005ffa:	fd06                	sd	ra,184(sp)
    80005ffc:	f922                	sd	s0,176(sp)
    80005ffe:	f526                	sd	s1,168(sp)
    80006000:	f14a                	sd	s2,160(sp)
    80006002:	ed4e                	sd	s3,152(sp)
    80006004:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80006006:	f4c40593          	addi	a1,s0,-180
    8000600a:	4505                	li	a0,1
    8000600c:	ffffd097          	auipc	ra,0xffffd
    80006010:	19a080e7          	jalr	410(ra) # 800031a6 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80006014:	08000613          	li	a2,128
    80006018:	f5040593          	addi	a1,s0,-176
    8000601c:	4501                	li	a0,0
    8000601e:	ffffd097          	auipc	ra,0xffffd
    80006022:	1c8080e7          	jalr	456(ra) # 800031e6 <argstr>
    80006026:	87aa                	mv	a5,a0
    return -1;
    80006028:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    8000602a:	0a07c963          	bltz	a5,800060dc <sys_open+0xe4>

  begin_op();
    8000602e:	fffff097          	auipc	ra,0xfffff
    80006032:	9ec080e7          	jalr	-1556(ra) # 80004a1a <begin_op>

  if(omode & O_CREATE){
    80006036:	f4c42783          	lw	a5,-180(s0)
    8000603a:	2007f793          	andi	a5,a5,512
    8000603e:	cfc5                	beqz	a5,800060f6 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80006040:	4681                	li	a3,0
    80006042:	4601                	li	a2,0
    80006044:	4589                	li	a1,2
    80006046:	f5040513          	addi	a0,s0,-176
    8000604a:	00000097          	auipc	ra,0x0
    8000604e:	972080e7          	jalr	-1678(ra) # 800059bc <create>
    80006052:	84aa                	mv	s1,a0
    if(ip == 0){
    80006054:	c959                	beqz	a0,800060ea <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80006056:	04449703          	lh	a4,68(s1)
    8000605a:	478d                	li	a5,3
    8000605c:	00f71763          	bne	a4,a5,8000606a <sys_open+0x72>
    80006060:	0464d703          	lhu	a4,70(s1)
    80006064:	47a5                	li	a5,9
    80006066:	0ce7ed63          	bltu	a5,a4,80006140 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    8000606a:	fffff097          	auipc	ra,0xfffff
    8000606e:	dbc080e7          	jalr	-580(ra) # 80004e26 <filealloc>
    80006072:	89aa                	mv	s3,a0
    80006074:	10050363          	beqz	a0,8000617a <sys_open+0x182>
    80006078:	00000097          	auipc	ra,0x0
    8000607c:	902080e7          	jalr	-1790(ra) # 8000597a <fdalloc>
    80006080:	892a                	mv	s2,a0
    80006082:	0e054763          	bltz	a0,80006170 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80006086:	04449703          	lh	a4,68(s1)
    8000608a:	478d                	li	a5,3
    8000608c:	0cf70563          	beq	a4,a5,80006156 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80006090:	4789                	li	a5,2
    80006092:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80006096:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    8000609a:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    8000609e:	f4c42783          	lw	a5,-180(s0)
    800060a2:	0017c713          	xori	a4,a5,1
    800060a6:	8b05                	andi	a4,a4,1
    800060a8:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800060ac:	0037f713          	andi	a4,a5,3
    800060b0:	00e03733          	snez	a4,a4
    800060b4:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800060b8:	4007f793          	andi	a5,a5,1024
    800060bc:	c791                	beqz	a5,800060c8 <sys_open+0xd0>
    800060be:	04449703          	lh	a4,68(s1)
    800060c2:	4789                	li	a5,2
    800060c4:	0af70063          	beq	a4,a5,80006164 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800060c8:	8526                	mv	a0,s1
    800060ca:	ffffe097          	auipc	ra,0xffffe
    800060ce:	046080e7          	jalr	70(ra) # 80004110 <iunlock>
  end_op();
    800060d2:	fffff097          	auipc	ra,0xfffff
    800060d6:	9c6080e7          	jalr	-1594(ra) # 80004a98 <end_op>

  return fd;
    800060da:	854a                	mv	a0,s2
}
    800060dc:	70ea                	ld	ra,184(sp)
    800060de:	744a                	ld	s0,176(sp)
    800060e0:	74aa                	ld	s1,168(sp)
    800060e2:	790a                	ld	s2,160(sp)
    800060e4:	69ea                	ld	s3,152(sp)
    800060e6:	6129                	addi	sp,sp,192
    800060e8:	8082                	ret
      end_op();
    800060ea:	fffff097          	auipc	ra,0xfffff
    800060ee:	9ae080e7          	jalr	-1618(ra) # 80004a98 <end_op>
      return -1;
    800060f2:	557d                	li	a0,-1
    800060f4:	b7e5                	j	800060dc <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800060f6:	f5040513          	addi	a0,s0,-176
    800060fa:	ffffe097          	auipc	ra,0xffffe
    800060fe:	700080e7          	jalr	1792(ra) # 800047fa <namei>
    80006102:	84aa                	mv	s1,a0
    80006104:	c905                	beqz	a0,80006134 <sys_open+0x13c>
    ilock(ip);
    80006106:	ffffe097          	auipc	ra,0xffffe
    8000610a:	f48080e7          	jalr	-184(ra) # 8000404e <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    8000610e:	04449703          	lh	a4,68(s1)
    80006112:	4785                	li	a5,1
    80006114:	f4f711e3          	bne	a4,a5,80006056 <sys_open+0x5e>
    80006118:	f4c42783          	lw	a5,-180(s0)
    8000611c:	d7b9                	beqz	a5,8000606a <sys_open+0x72>
      iunlockput(ip);
    8000611e:	8526                	mv	a0,s1
    80006120:	ffffe097          	auipc	ra,0xffffe
    80006124:	190080e7          	jalr	400(ra) # 800042b0 <iunlockput>
      end_op();
    80006128:	fffff097          	auipc	ra,0xfffff
    8000612c:	970080e7          	jalr	-1680(ra) # 80004a98 <end_op>
      return -1;
    80006130:	557d                	li	a0,-1
    80006132:	b76d                	j	800060dc <sys_open+0xe4>
      end_op();
    80006134:	fffff097          	auipc	ra,0xfffff
    80006138:	964080e7          	jalr	-1692(ra) # 80004a98 <end_op>
      return -1;
    8000613c:	557d                	li	a0,-1
    8000613e:	bf79                	j	800060dc <sys_open+0xe4>
    iunlockput(ip);
    80006140:	8526                	mv	a0,s1
    80006142:	ffffe097          	auipc	ra,0xffffe
    80006146:	16e080e7          	jalr	366(ra) # 800042b0 <iunlockput>
    end_op();
    8000614a:	fffff097          	auipc	ra,0xfffff
    8000614e:	94e080e7          	jalr	-1714(ra) # 80004a98 <end_op>
    return -1;
    80006152:	557d                	li	a0,-1
    80006154:	b761                	j	800060dc <sys_open+0xe4>
    f->type = FD_DEVICE;
    80006156:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    8000615a:	04649783          	lh	a5,70(s1)
    8000615e:	02f99223          	sh	a5,36(s3)
    80006162:	bf25                	j	8000609a <sys_open+0xa2>
    itrunc(ip);
    80006164:	8526                	mv	a0,s1
    80006166:	ffffe097          	auipc	ra,0xffffe
    8000616a:	ff6080e7          	jalr	-10(ra) # 8000415c <itrunc>
    8000616e:	bfa9                	j	800060c8 <sys_open+0xd0>
      fileclose(f);
    80006170:	854e                	mv	a0,s3
    80006172:	fffff097          	auipc	ra,0xfffff
    80006176:	d70080e7          	jalr	-656(ra) # 80004ee2 <fileclose>
    iunlockput(ip);
    8000617a:	8526                	mv	a0,s1
    8000617c:	ffffe097          	auipc	ra,0xffffe
    80006180:	134080e7          	jalr	308(ra) # 800042b0 <iunlockput>
    end_op();
    80006184:	fffff097          	auipc	ra,0xfffff
    80006188:	914080e7          	jalr	-1772(ra) # 80004a98 <end_op>
    return -1;
    8000618c:	557d                	li	a0,-1
    8000618e:	b7b9                	j	800060dc <sys_open+0xe4>

0000000080006190 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80006190:	7175                	addi	sp,sp,-144
    80006192:	e506                	sd	ra,136(sp)
    80006194:	e122                	sd	s0,128(sp)
    80006196:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80006198:	fffff097          	auipc	ra,0xfffff
    8000619c:	882080e7          	jalr	-1918(ra) # 80004a1a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800061a0:	08000613          	li	a2,128
    800061a4:	f7040593          	addi	a1,s0,-144
    800061a8:	4501                	li	a0,0
    800061aa:	ffffd097          	auipc	ra,0xffffd
    800061ae:	03c080e7          	jalr	60(ra) # 800031e6 <argstr>
    800061b2:	02054963          	bltz	a0,800061e4 <sys_mkdir+0x54>
    800061b6:	4681                	li	a3,0
    800061b8:	4601                	li	a2,0
    800061ba:	4585                	li	a1,1
    800061bc:	f7040513          	addi	a0,s0,-144
    800061c0:	fffff097          	auipc	ra,0xfffff
    800061c4:	7fc080e7          	jalr	2044(ra) # 800059bc <create>
    800061c8:	cd11                	beqz	a0,800061e4 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800061ca:	ffffe097          	auipc	ra,0xffffe
    800061ce:	0e6080e7          	jalr	230(ra) # 800042b0 <iunlockput>
  end_op();
    800061d2:	fffff097          	auipc	ra,0xfffff
    800061d6:	8c6080e7          	jalr	-1850(ra) # 80004a98 <end_op>
  return 0;
    800061da:	4501                	li	a0,0
}
    800061dc:	60aa                	ld	ra,136(sp)
    800061de:	640a                	ld	s0,128(sp)
    800061e0:	6149                	addi	sp,sp,144
    800061e2:	8082                	ret
    end_op();
    800061e4:	fffff097          	auipc	ra,0xfffff
    800061e8:	8b4080e7          	jalr	-1868(ra) # 80004a98 <end_op>
    return -1;
    800061ec:	557d                	li	a0,-1
    800061ee:	b7fd                	j	800061dc <sys_mkdir+0x4c>

00000000800061f0 <sys_mknod>:

uint64
sys_mknod(void)
{
    800061f0:	7135                	addi	sp,sp,-160
    800061f2:	ed06                	sd	ra,152(sp)
    800061f4:	e922                	sd	s0,144(sp)
    800061f6:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800061f8:	fffff097          	auipc	ra,0xfffff
    800061fc:	822080e7          	jalr	-2014(ra) # 80004a1a <begin_op>
  argint(1, &major);
    80006200:	f6c40593          	addi	a1,s0,-148
    80006204:	4505                	li	a0,1
    80006206:	ffffd097          	auipc	ra,0xffffd
    8000620a:	fa0080e7          	jalr	-96(ra) # 800031a6 <argint>
  argint(2, &minor);
    8000620e:	f6840593          	addi	a1,s0,-152
    80006212:	4509                	li	a0,2
    80006214:	ffffd097          	auipc	ra,0xffffd
    80006218:	f92080e7          	jalr	-110(ra) # 800031a6 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000621c:	08000613          	li	a2,128
    80006220:	f7040593          	addi	a1,s0,-144
    80006224:	4501                	li	a0,0
    80006226:	ffffd097          	auipc	ra,0xffffd
    8000622a:	fc0080e7          	jalr	-64(ra) # 800031e6 <argstr>
    8000622e:	02054b63          	bltz	a0,80006264 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80006232:	f6841683          	lh	a3,-152(s0)
    80006236:	f6c41603          	lh	a2,-148(s0)
    8000623a:	458d                	li	a1,3
    8000623c:	f7040513          	addi	a0,s0,-144
    80006240:	fffff097          	auipc	ra,0xfffff
    80006244:	77c080e7          	jalr	1916(ra) # 800059bc <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006248:	cd11                	beqz	a0,80006264 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000624a:	ffffe097          	auipc	ra,0xffffe
    8000624e:	066080e7          	jalr	102(ra) # 800042b0 <iunlockput>
  end_op();
    80006252:	fffff097          	auipc	ra,0xfffff
    80006256:	846080e7          	jalr	-1978(ra) # 80004a98 <end_op>
  return 0;
    8000625a:	4501                	li	a0,0
}
    8000625c:	60ea                	ld	ra,152(sp)
    8000625e:	644a                	ld	s0,144(sp)
    80006260:	610d                	addi	sp,sp,160
    80006262:	8082                	ret
    end_op();
    80006264:	fffff097          	auipc	ra,0xfffff
    80006268:	834080e7          	jalr	-1996(ra) # 80004a98 <end_op>
    return -1;
    8000626c:	557d                	li	a0,-1
    8000626e:	b7fd                	j	8000625c <sys_mknod+0x6c>

0000000080006270 <sys_chdir>:

uint64
sys_chdir(void)
{
    80006270:	7135                	addi	sp,sp,-160
    80006272:	ed06                	sd	ra,152(sp)
    80006274:	e922                	sd	s0,144(sp)
    80006276:	e526                	sd	s1,136(sp)
    80006278:	e14a                	sd	s2,128(sp)
    8000627a:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    8000627c:	ffffc097          	auipc	ra,0xffffc
    80006280:	938080e7          	jalr	-1736(ra) # 80001bb4 <myproc>
    80006284:	892a                	mv	s2,a0
  
  begin_op();
    80006286:	ffffe097          	auipc	ra,0xffffe
    8000628a:	794080e7          	jalr	1940(ra) # 80004a1a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    8000628e:	08000613          	li	a2,128
    80006292:	f6040593          	addi	a1,s0,-160
    80006296:	4501                	li	a0,0
    80006298:	ffffd097          	auipc	ra,0xffffd
    8000629c:	f4e080e7          	jalr	-178(ra) # 800031e6 <argstr>
    800062a0:	04054b63          	bltz	a0,800062f6 <sys_chdir+0x86>
    800062a4:	f6040513          	addi	a0,s0,-160
    800062a8:	ffffe097          	auipc	ra,0xffffe
    800062ac:	552080e7          	jalr	1362(ra) # 800047fa <namei>
    800062b0:	84aa                	mv	s1,a0
    800062b2:	c131                	beqz	a0,800062f6 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800062b4:	ffffe097          	auipc	ra,0xffffe
    800062b8:	d9a080e7          	jalr	-614(ra) # 8000404e <ilock>
  if(ip->type != T_DIR){
    800062bc:	04449703          	lh	a4,68(s1)
    800062c0:	4785                	li	a5,1
    800062c2:	04f71063          	bne	a4,a5,80006302 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800062c6:	8526                	mv	a0,s1
    800062c8:	ffffe097          	auipc	ra,0xffffe
    800062cc:	e48080e7          	jalr	-440(ra) # 80004110 <iunlock>
  iput(p->cwd);
    800062d0:	15093503          	ld	a0,336(s2)
    800062d4:	ffffe097          	auipc	ra,0xffffe
    800062d8:	f34080e7          	jalr	-204(ra) # 80004208 <iput>
  end_op();
    800062dc:	ffffe097          	auipc	ra,0xffffe
    800062e0:	7bc080e7          	jalr	1980(ra) # 80004a98 <end_op>
  p->cwd = ip;
    800062e4:	14993823          	sd	s1,336(s2)
  return 0;
    800062e8:	4501                	li	a0,0
}
    800062ea:	60ea                	ld	ra,152(sp)
    800062ec:	644a                	ld	s0,144(sp)
    800062ee:	64aa                	ld	s1,136(sp)
    800062f0:	690a                	ld	s2,128(sp)
    800062f2:	610d                	addi	sp,sp,160
    800062f4:	8082                	ret
    end_op();
    800062f6:	ffffe097          	auipc	ra,0xffffe
    800062fa:	7a2080e7          	jalr	1954(ra) # 80004a98 <end_op>
    return -1;
    800062fe:	557d                	li	a0,-1
    80006300:	b7ed                	j	800062ea <sys_chdir+0x7a>
    iunlockput(ip);
    80006302:	8526                	mv	a0,s1
    80006304:	ffffe097          	auipc	ra,0xffffe
    80006308:	fac080e7          	jalr	-84(ra) # 800042b0 <iunlockput>
    end_op();
    8000630c:	ffffe097          	auipc	ra,0xffffe
    80006310:	78c080e7          	jalr	1932(ra) # 80004a98 <end_op>
    return -1;
    80006314:	557d                	li	a0,-1
    80006316:	bfd1                	j	800062ea <sys_chdir+0x7a>

0000000080006318 <sys_exec>:

uint64
sys_exec(void)
{
    80006318:	7145                	addi	sp,sp,-464
    8000631a:	e786                	sd	ra,456(sp)
    8000631c:	e3a2                	sd	s0,448(sp)
    8000631e:	ff26                	sd	s1,440(sp)
    80006320:	fb4a                	sd	s2,432(sp)
    80006322:	f74e                	sd	s3,424(sp)
    80006324:	f352                	sd	s4,416(sp)
    80006326:	ef56                	sd	s5,408(sp)
    80006328:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    8000632a:	e3840593          	addi	a1,s0,-456
    8000632e:	4505                	li	a0,1
    80006330:	ffffd097          	auipc	ra,0xffffd
    80006334:	e96080e7          	jalr	-362(ra) # 800031c6 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80006338:	08000613          	li	a2,128
    8000633c:	f4040593          	addi	a1,s0,-192
    80006340:	4501                	li	a0,0
    80006342:	ffffd097          	auipc	ra,0xffffd
    80006346:	ea4080e7          	jalr	-348(ra) # 800031e6 <argstr>
    8000634a:	87aa                	mv	a5,a0
    return -1;
    8000634c:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    8000634e:	0c07c363          	bltz	a5,80006414 <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    80006352:	10000613          	li	a2,256
    80006356:	4581                	li	a1,0
    80006358:	e4040513          	addi	a0,s0,-448
    8000635c:	ffffb097          	auipc	ra,0xffffb
    80006360:	b40080e7          	jalr	-1216(ra) # 80000e9c <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80006364:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80006368:	89a6                	mv	s3,s1
    8000636a:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    8000636c:	02000a13          	li	s4,32
    80006370:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80006374:	00391513          	slli	a0,s2,0x3
    80006378:	e3040593          	addi	a1,s0,-464
    8000637c:	e3843783          	ld	a5,-456(s0)
    80006380:	953e                	add	a0,a0,a5
    80006382:	ffffd097          	auipc	ra,0xffffd
    80006386:	d86080e7          	jalr	-634(ra) # 80003108 <fetchaddr>
    8000638a:	02054a63          	bltz	a0,800063be <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    8000638e:	e3043783          	ld	a5,-464(s0)
    80006392:	c3b9                	beqz	a5,800063d8 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80006394:	ffffb097          	auipc	ra,0xffffb
    80006398:	912080e7          	jalr	-1774(ra) # 80000ca6 <kalloc>
    8000639c:	85aa                	mv	a1,a0
    8000639e:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    800063a2:	cd11                	beqz	a0,800063be <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    800063a4:	6605                	lui	a2,0x1
    800063a6:	e3043503          	ld	a0,-464(s0)
    800063aa:	ffffd097          	auipc	ra,0xffffd
    800063ae:	db0080e7          	jalr	-592(ra) # 8000315a <fetchstr>
    800063b2:	00054663          	bltz	a0,800063be <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    800063b6:	0905                	addi	s2,s2,1
    800063b8:	09a1                	addi	s3,s3,8
    800063ba:	fb491be3          	bne	s2,s4,80006370 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800063be:	f4040913          	addi	s2,s0,-192
    800063c2:	6088                	ld	a0,0(s1)
    800063c4:	c539                	beqz	a0,80006412 <sys_exec+0xfa>
    kfree(argv[i]);
    800063c6:	ffffa097          	auipc	ra,0xffffa
    800063ca:	758080e7          	jalr	1880(ra) # 80000b1e <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800063ce:	04a1                	addi	s1,s1,8
    800063d0:	ff2499e3          	bne	s1,s2,800063c2 <sys_exec+0xaa>
  return -1;
    800063d4:	557d                	li	a0,-1
    800063d6:	a83d                	j	80006414 <sys_exec+0xfc>
      argv[i] = 0;
    800063d8:	0a8e                	slli	s5,s5,0x3
    800063da:	fc0a8793          	addi	a5,s5,-64
    800063de:	00878ab3          	add	s5,a5,s0
    800063e2:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    800063e6:	e4040593          	addi	a1,s0,-448
    800063ea:	f4040513          	addi	a0,s0,-192
    800063ee:	fffff097          	auipc	ra,0xfffff
    800063f2:	16e080e7          	jalr	366(ra) # 8000555c <exec>
    800063f6:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800063f8:	f4040993          	addi	s3,s0,-192
    800063fc:	6088                	ld	a0,0(s1)
    800063fe:	c901                	beqz	a0,8000640e <sys_exec+0xf6>
    kfree(argv[i]);
    80006400:	ffffa097          	auipc	ra,0xffffa
    80006404:	71e080e7          	jalr	1822(ra) # 80000b1e <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006408:	04a1                	addi	s1,s1,8
    8000640a:	ff3499e3          	bne	s1,s3,800063fc <sys_exec+0xe4>
  return ret;
    8000640e:	854a                	mv	a0,s2
    80006410:	a011                	j	80006414 <sys_exec+0xfc>
  return -1;
    80006412:	557d                	li	a0,-1
}
    80006414:	60be                	ld	ra,456(sp)
    80006416:	641e                	ld	s0,448(sp)
    80006418:	74fa                	ld	s1,440(sp)
    8000641a:	795a                	ld	s2,432(sp)
    8000641c:	79ba                	ld	s3,424(sp)
    8000641e:	7a1a                	ld	s4,416(sp)
    80006420:	6afa                	ld	s5,408(sp)
    80006422:	6179                	addi	sp,sp,464
    80006424:	8082                	ret

0000000080006426 <sys_pipe>:

uint64
sys_pipe(void)
{
    80006426:	7139                	addi	sp,sp,-64
    80006428:	fc06                	sd	ra,56(sp)
    8000642a:	f822                	sd	s0,48(sp)
    8000642c:	f426                	sd	s1,40(sp)
    8000642e:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80006430:	ffffb097          	auipc	ra,0xffffb
    80006434:	784080e7          	jalr	1924(ra) # 80001bb4 <myproc>
    80006438:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    8000643a:	fd840593          	addi	a1,s0,-40
    8000643e:	4501                	li	a0,0
    80006440:	ffffd097          	auipc	ra,0xffffd
    80006444:	d86080e7          	jalr	-634(ra) # 800031c6 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80006448:	fc840593          	addi	a1,s0,-56
    8000644c:	fd040513          	addi	a0,s0,-48
    80006450:	fffff097          	auipc	ra,0xfffff
    80006454:	dc2080e7          	jalr	-574(ra) # 80005212 <pipealloc>
    return -1;
    80006458:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    8000645a:	0c054463          	bltz	a0,80006522 <sys_pipe+0xfc>
  fd0 = -1;
    8000645e:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80006462:	fd043503          	ld	a0,-48(s0)
    80006466:	fffff097          	auipc	ra,0xfffff
    8000646a:	514080e7          	jalr	1300(ra) # 8000597a <fdalloc>
    8000646e:	fca42223          	sw	a0,-60(s0)
    80006472:	08054b63          	bltz	a0,80006508 <sys_pipe+0xe2>
    80006476:	fc843503          	ld	a0,-56(s0)
    8000647a:	fffff097          	auipc	ra,0xfffff
    8000647e:	500080e7          	jalr	1280(ra) # 8000597a <fdalloc>
    80006482:	fca42023          	sw	a0,-64(s0)
    80006486:	06054863          	bltz	a0,800064f6 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000648a:	4691                	li	a3,4
    8000648c:	fc440613          	addi	a2,s0,-60
    80006490:	fd843583          	ld	a1,-40(s0)
    80006494:	68a8                	ld	a0,80(s1)
    80006496:	ffffb097          	auipc	ra,0xffffb
    8000649a:	3a6080e7          	jalr	934(ra) # 8000183c <copyout>
    8000649e:	02054063          	bltz	a0,800064be <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    800064a2:	4691                	li	a3,4
    800064a4:	fc040613          	addi	a2,s0,-64
    800064a8:	fd843583          	ld	a1,-40(s0)
    800064ac:	0591                	addi	a1,a1,4
    800064ae:	68a8                	ld	a0,80(s1)
    800064b0:	ffffb097          	auipc	ra,0xffffb
    800064b4:	38c080e7          	jalr	908(ra) # 8000183c <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    800064b8:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800064ba:	06055463          	bgez	a0,80006522 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    800064be:	fc442783          	lw	a5,-60(s0)
    800064c2:	07e9                	addi	a5,a5,26
    800064c4:	078e                	slli	a5,a5,0x3
    800064c6:	97a6                	add	a5,a5,s1
    800064c8:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    800064cc:	fc042783          	lw	a5,-64(s0)
    800064d0:	07e9                	addi	a5,a5,26
    800064d2:	078e                	slli	a5,a5,0x3
    800064d4:	94be                	add	s1,s1,a5
    800064d6:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    800064da:	fd043503          	ld	a0,-48(s0)
    800064de:	fffff097          	auipc	ra,0xfffff
    800064e2:	a04080e7          	jalr	-1532(ra) # 80004ee2 <fileclose>
    fileclose(wf);
    800064e6:	fc843503          	ld	a0,-56(s0)
    800064ea:	fffff097          	auipc	ra,0xfffff
    800064ee:	9f8080e7          	jalr	-1544(ra) # 80004ee2 <fileclose>
    return -1;
    800064f2:	57fd                	li	a5,-1
    800064f4:	a03d                	j	80006522 <sys_pipe+0xfc>
    if(fd0 >= 0)
    800064f6:	fc442783          	lw	a5,-60(s0)
    800064fa:	0007c763          	bltz	a5,80006508 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    800064fe:	07e9                	addi	a5,a5,26
    80006500:	078e                	slli	a5,a5,0x3
    80006502:	97a6                	add	a5,a5,s1
    80006504:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80006508:	fd043503          	ld	a0,-48(s0)
    8000650c:	fffff097          	auipc	ra,0xfffff
    80006510:	9d6080e7          	jalr	-1578(ra) # 80004ee2 <fileclose>
    fileclose(wf);
    80006514:	fc843503          	ld	a0,-56(s0)
    80006518:	fffff097          	auipc	ra,0xfffff
    8000651c:	9ca080e7          	jalr	-1590(ra) # 80004ee2 <fileclose>
    return -1;
    80006520:	57fd                	li	a5,-1
}
    80006522:	853e                	mv	a0,a5
    80006524:	70e2                	ld	ra,56(sp)
    80006526:	7442                	ld	s0,48(sp)
    80006528:	74a2                	ld	s1,40(sp)
    8000652a:	6121                	addi	sp,sp,64
    8000652c:	8082                	ret
	...

0000000080006530 <kernelvec>:
    80006530:	7111                	addi	sp,sp,-256
    80006532:	e006                	sd	ra,0(sp)
    80006534:	e40a                	sd	sp,8(sp)
    80006536:	e80e                	sd	gp,16(sp)
    80006538:	ec12                	sd	tp,24(sp)
    8000653a:	f016                	sd	t0,32(sp)
    8000653c:	f41a                	sd	t1,40(sp)
    8000653e:	f81e                	sd	t2,48(sp)
    80006540:	fc22                	sd	s0,56(sp)
    80006542:	e0a6                	sd	s1,64(sp)
    80006544:	e4aa                	sd	a0,72(sp)
    80006546:	e8ae                	sd	a1,80(sp)
    80006548:	ecb2                	sd	a2,88(sp)
    8000654a:	f0b6                	sd	a3,96(sp)
    8000654c:	f4ba                	sd	a4,104(sp)
    8000654e:	f8be                	sd	a5,112(sp)
    80006550:	fcc2                	sd	a6,120(sp)
    80006552:	e146                	sd	a7,128(sp)
    80006554:	e54a                	sd	s2,136(sp)
    80006556:	e94e                	sd	s3,144(sp)
    80006558:	ed52                	sd	s4,152(sp)
    8000655a:	f156                	sd	s5,160(sp)
    8000655c:	f55a                	sd	s6,168(sp)
    8000655e:	f95e                	sd	s7,176(sp)
    80006560:	fd62                	sd	s8,184(sp)
    80006562:	e1e6                	sd	s9,192(sp)
    80006564:	e5ea                	sd	s10,200(sp)
    80006566:	e9ee                	sd	s11,208(sp)
    80006568:	edf2                	sd	t3,216(sp)
    8000656a:	f1f6                	sd	t4,224(sp)
    8000656c:	f5fa                	sd	t5,232(sp)
    8000656e:	f9fe                	sd	t6,240(sp)
    80006570:	a8ffc0ef          	jal	ra,80002ffe <kerneltrap>
    80006574:	6082                	ld	ra,0(sp)
    80006576:	6122                	ld	sp,8(sp)
    80006578:	61c2                	ld	gp,16(sp)
    8000657a:	7282                	ld	t0,32(sp)
    8000657c:	7322                	ld	t1,40(sp)
    8000657e:	73c2                	ld	t2,48(sp)
    80006580:	7462                	ld	s0,56(sp)
    80006582:	6486                	ld	s1,64(sp)
    80006584:	6526                	ld	a0,72(sp)
    80006586:	65c6                	ld	a1,80(sp)
    80006588:	6666                	ld	a2,88(sp)
    8000658a:	7686                	ld	a3,96(sp)
    8000658c:	7726                	ld	a4,104(sp)
    8000658e:	77c6                	ld	a5,112(sp)
    80006590:	7866                	ld	a6,120(sp)
    80006592:	688a                	ld	a7,128(sp)
    80006594:	692a                	ld	s2,136(sp)
    80006596:	69ca                	ld	s3,144(sp)
    80006598:	6a6a                	ld	s4,152(sp)
    8000659a:	7a8a                	ld	s5,160(sp)
    8000659c:	7b2a                	ld	s6,168(sp)
    8000659e:	7bca                	ld	s7,176(sp)
    800065a0:	7c6a                	ld	s8,184(sp)
    800065a2:	6c8e                	ld	s9,192(sp)
    800065a4:	6d2e                	ld	s10,200(sp)
    800065a6:	6dce                	ld	s11,208(sp)
    800065a8:	6e6e                	ld	t3,216(sp)
    800065aa:	7e8e                	ld	t4,224(sp)
    800065ac:	7f2e                	ld	t5,232(sp)
    800065ae:	7fce                	ld	t6,240(sp)
    800065b0:	6111                	addi	sp,sp,256
    800065b2:	10200073          	sret
    800065b6:	00000013          	nop
    800065ba:	00000013          	nop
    800065be:	0001                	nop

00000000800065c0 <timervec>:
    800065c0:	34051573          	csrrw	a0,mscratch,a0
    800065c4:	e10c                	sd	a1,0(a0)
    800065c6:	e510                	sd	a2,8(a0)
    800065c8:	e914                	sd	a3,16(a0)
    800065ca:	6d0c                	ld	a1,24(a0)
    800065cc:	7110                	ld	a2,32(a0)
    800065ce:	6194                	ld	a3,0(a1)
    800065d0:	96b2                	add	a3,a3,a2
    800065d2:	e194                	sd	a3,0(a1)
    800065d4:	4589                	li	a1,2
    800065d6:	14459073          	csrw	sip,a1
    800065da:	6914                	ld	a3,16(a0)
    800065dc:	6510                	ld	a2,8(a0)
    800065de:	610c                	ld	a1,0(a0)
    800065e0:	34051573          	csrrw	a0,mscratch,a0
    800065e4:	30200073          	mret
	...

00000000800065ea <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800065ea:	1141                	addi	sp,sp,-16
    800065ec:	e422                	sd	s0,8(sp)
    800065ee:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800065f0:	0c0007b7          	lui	a5,0xc000
    800065f4:	4705                	li	a4,1
    800065f6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800065f8:	c3d8                	sw	a4,4(a5)
}
    800065fa:	6422                	ld	s0,8(sp)
    800065fc:	0141                	addi	sp,sp,16
    800065fe:	8082                	ret

0000000080006600 <plicinithart>:

void
plicinithart(void)
{
    80006600:	1141                	addi	sp,sp,-16
    80006602:	e406                	sd	ra,8(sp)
    80006604:	e022                	sd	s0,0(sp)
    80006606:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006608:	ffffb097          	auipc	ra,0xffffb
    8000660c:	580080e7          	jalr	1408(ra) # 80001b88 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006610:	0085171b          	slliw	a4,a0,0x8
    80006614:	0c0027b7          	lui	a5,0xc002
    80006618:	97ba                	add	a5,a5,a4
    8000661a:	40200713          	li	a4,1026
    8000661e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006622:	00d5151b          	slliw	a0,a0,0xd
    80006626:	0c2017b7          	lui	a5,0xc201
    8000662a:	97aa                	add	a5,a5,a0
    8000662c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80006630:	60a2                	ld	ra,8(sp)
    80006632:	6402                	ld	s0,0(sp)
    80006634:	0141                	addi	sp,sp,16
    80006636:	8082                	ret

0000000080006638 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006638:	1141                	addi	sp,sp,-16
    8000663a:	e406                	sd	ra,8(sp)
    8000663c:	e022                	sd	s0,0(sp)
    8000663e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006640:	ffffb097          	auipc	ra,0xffffb
    80006644:	548080e7          	jalr	1352(ra) # 80001b88 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006648:	00d5151b          	slliw	a0,a0,0xd
    8000664c:	0c2017b7          	lui	a5,0xc201
    80006650:	97aa                	add	a5,a5,a0
  return irq;
}
    80006652:	43c8                	lw	a0,4(a5)
    80006654:	60a2                	ld	ra,8(sp)
    80006656:	6402                	ld	s0,0(sp)
    80006658:	0141                	addi	sp,sp,16
    8000665a:	8082                	ret

000000008000665c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000665c:	1101                	addi	sp,sp,-32
    8000665e:	ec06                	sd	ra,24(sp)
    80006660:	e822                	sd	s0,16(sp)
    80006662:	e426                	sd	s1,8(sp)
    80006664:	1000                	addi	s0,sp,32
    80006666:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006668:	ffffb097          	auipc	ra,0xffffb
    8000666c:	520080e7          	jalr	1312(ra) # 80001b88 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006670:	00d5151b          	slliw	a0,a0,0xd
    80006674:	0c2017b7          	lui	a5,0xc201
    80006678:	97aa                	add	a5,a5,a0
    8000667a:	c3c4                	sw	s1,4(a5)
}
    8000667c:	60e2                	ld	ra,24(sp)
    8000667e:	6442                	ld	s0,16(sp)
    80006680:	64a2                	ld	s1,8(sp)
    80006682:	6105                	addi	sp,sp,32
    80006684:	8082                	ret

0000000080006686 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006686:	1141                	addi	sp,sp,-16
    80006688:	e406                	sd	ra,8(sp)
    8000668a:	e022                	sd	s0,0(sp)
    8000668c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000668e:	479d                	li	a5,7
    80006690:	04a7cc63          	blt	a5,a0,800066e8 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006694:	0023d797          	auipc	a5,0x23d
    80006698:	aa478793          	addi	a5,a5,-1372 # 80243138 <disk>
    8000669c:	97aa                	add	a5,a5,a0
    8000669e:	0187c783          	lbu	a5,24(a5)
    800066a2:	ebb9                	bnez	a5,800066f8 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800066a4:	00451693          	slli	a3,a0,0x4
    800066a8:	0023d797          	auipc	a5,0x23d
    800066ac:	a9078793          	addi	a5,a5,-1392 # 80243138 <disk>
    800066b0:	6398                	ld	a4,0(a5)
    800066b2:	9736                	add	a4,a4,a3
    800066b4:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    800066b8:	6398                	ld	a4,0(a5)
    800066ba:	9736                	add	a4,a4,a3
    800066bc:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    800066c0:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    800066c4:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    800066c8:	97aa                	add	a5,a5,a0
    800066ca:	4705                	li	a4,1
    800066cc:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    800066d0:	0023d517          	auipc	a0,0x23d
    800066d4:	a8050513          	addi	a0,a0,-1408 # 80243150 <disk+0x18>
    800066d8:	ffffc097          	auipc	ra,0xffffc
    800066dc:	cf8080e7          	jalr	-776(ra) # 800023d0 <wakeup>
}
    800066e0:	60a2                	ld	ra,8(sp)
    800066e2:	6402                	ld	s0,0(sp)
    800066e4:	0141                	addi	sp,sp,16
    800066e6:	8082                	ret
    panic("free_desc 1");
    800066e8:	00002517          	auipc	a0,0x2
    800066ec:	21850513          	addi	a0,a0,536 # 80008900 <syscalls+0x318>
    800066f0:	ffffa097          	auipc	ra,0xffffa
    800066f4:	e50080e7          	jalr	-432(ra) # 80000540 <panic>
    panic("free_desc 2");
    800066f8:	00002517          	auipc	a0,0x2
    800066fc:	21850513          	addi	a0,a0,536 # 80008910 <syscalls+0x328>
    80006700:	ffffa097          	auipc	ra,0xffffa
    80006704:	e40080e7          	jalr	-448(ra) # 80000540 <panic>

0000000080006708 <virtio_disk_init>:
{
    80006708:	1101                	addi	sp,sp,-32
    8000670a:	ec06                	sd	ra,24(sp)
    8000670c:	e822                	sd	s0,16(sp)
    8000670e:	e426                	sd	s1,8(sp)
    80006710:	e04a                	sd	s2,0(sp)
    80006712:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006714:	00002597          	auipc	a1,0x2
    80006718:	20c58593          	addi	a1,a1,524 # 80008920 <syscalls+0x338>
    8000671c:	0023d517          	auipc	a0,0x23d
    80006720:	b4450513          	addi	a0,a0,-1212 # 80243260 <disk+0x128>
    80006724:	ffffa097          	auipc	ra,0xffffa
    80006728:	5ec080e7          	jalr	1516(ra) # 80000d10 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000672c:	100017b7          	lui	a5,0x10001
    80006730:	4398                	lw	a4,0(a5)
    80006732:	2701                	sext.w	a4,a4
    80006734:	747277b7          	lui	a5,0x74727
    80006738:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000673c:	14f71b63          	bne	a4,a5,80006892 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006740:	100017b7          	lui	a5,0x10001
    80006744:	43dc                	lw	a5,4(a5)
    80006746:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006748:	4709                	li	a4,2
    8000674a:	14e79463          	bne	a5,a4,80006892 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000674e:	100017b7          	lui	a5,0x10001
    80006752:	479c                	lw	a5,8(a5)
    80006754:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006756:	12e79e63          	bne	a5,a4,80006892 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000675a:	100017b7          	lui	a5,0x10001
    8000675e:	47d8                	lw	a4,12(a5)
    80006760:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006762:	554d47b7          	lui	a5,0x554d4
    80006766:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000676a:	12f71463          	bne	a4,a5,80006892 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000676e:	100017b7          	lui	a5,0x10001
    80006772:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006776:	4705                	li	a4,1
    80006778:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000677a:	470d                	li	a4,3
    8000677c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000677e:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006780:	c7ffe6b7          	lui	a3,0xc7ffe
    80006784:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47dbb4e7>
    80006788:	8f75                	and	a4,a4,a3
    8000678a:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000678c:	472d                	li	a4,11
    8000678e:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006790:	5bbc                	lw	a5,112(a5)
    80006792:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006796:	8ba1                	andi	a5,a5,8
    80006798:	10078563          	beqz	a5,800068a2 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000679c:	100017b7          	lui	a5,0x10001
    800067a0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    800067a4:	43fc                	lw	a5,68(a5)
    800067a6:	2781                	sext.w	a5,a5
    800067a8:	10079563          	bnez	a5,800068b2 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800067ac:	100017b7          	lui	a5,0x10001
    800067b0:	5bdc                	lw	a5,52(a5)
    800067b2:	2781                	sext.w	a5,a5
  if(max == 0)
    800067b4:	10078763          	beqz	a5,800068c2 <virtio_disk_init+0x1ba>
  if(max < NUM)
    800067b8:	471d                	li	a4,7
    800067ba:	10f77c63          	bgeu	a4,a5,800068d2 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    800067be:	ffffa097          	auipc	ra,0xffffa
    800067c2:	4e8080e7          	jalr	1256(ra) # 80000ca6 <kalloc>
    800067c6:	0023d497          	auipc	s1,0x23d
    800067ca:	97248493          	addi	s1,s1,-1678 # 80243138 <disk>
    800067ce:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    800067d0:	ffffa097          	auipc	ra,0xffffa
    800067d4:	4d6080e7          	jalr	1238(ra) # 80000ca6 <kalloc>
    800067d8:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    800067da:	ffffa097          	auipc	ra,0xffffa
    800067de:	4cc080e7          	jalr	1228(ra) # 80000ca6 <kalloc>
    800067e2:	87aa                	mv	a5,a0
    800067e4:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    800067e6:	6088                	ld	a0,0(s1)
    800067e8:	cd6d                	beqz	a0,800068e2 <virtio_disk_init+0x1da>
    800067ea:	0023d717          	auipc	a4,0x23d
    800067ee:	95673703          	ld	a4,-1706(a4) # 80243140 <disk+0x8>
    800067f2:	cb65                	beqz	a4,800068e2 <virtio_disk_init+0x1da>
    800067f4:	c7fd                	beqz	a5,800068e2 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    800067f6:	6605                	lui	a2,0x1
    800067f8:	4581                	li	a1,0
    800067fa:	ffffa097          	auipc	ra,0xffffa
    800067fe:	6a2080e7          	jalr	1698(ra) # 80000e9c <memset>
  memset(disk.avail, 0, PGSIZE);
    80006802:	0023d497          	auipc	s1,0x23d
    80006806:	93648493          	addi	s1,s1,-1738 # 80243138 <disk>
    8000680a:	6605                	lui	a2,0x1
    8000680c:	4581                	li	a1,0
    8000680e:	6488                	ld	a0,8(s1)
    80006810:	ffffa097          	auipc	ra,0xffffa
    80006814:	68c080e7          	jalr	1676(ra) # 80000e9c <memset>
  memset(disk.used, 0, PGSIZE);
    80006818:	6605                	lui	a2,0x1
    8000681a:	4581                	li	a1,0
    8000681c:	6888                	ld	a0,16(s1)
    8000681e:	ffffa097          	auipc	ra,0xffffa
    80006822:	67e080e7          	jalr	1662(ra) # 80000e9c <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006826:	100017b7          	lui	a5,0x10001
    8000682a:	4721                	li	a4,8
    8000682c:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    8000682e:	4098                	lw	a4,0(s1)
    80006830:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006834:	40d8                	lw	a4,4(s1)
    80006836:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000683a:	6498                	ld	a4,8(s1)
    8000683c:	0007069b          	sext.w	a3,a4
    80006840:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006844:	9701                	srai	a4,a4,0x20
    80006846:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000684a:	6898                	ld	a4,16(s1)
    8000684c:	0007069b          	sext.w	a3,a4
    80006850:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006854:	9701                	srai	a4,a4,0x20
    80006856:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000685a:	4705                	li	a4,1
    8000685c:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    8000685e:	00e48c23          	sb	a4,24(s1)
    80006862:	00e48ca3          	sb	a4,25(s1)
    80006866:	00e48d23          	sb	a4,26(s1)
    8000686a:	00e48da3          	sb	a4,27(s1)
    8000686e:	00e48e23          	sb	a4,28(s1)
    80006872:	00e48ea3          	sb	a4,29(s1)
    80006876:	00e48f23          	sb	a4,30(s1)
    8000687a:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    8000687e:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006882:	0727a823          	sw	s2,112(a5)
}
    80006886:	60e2                	ld	ra,24(sp)
    80006888:	6442                	ld	s0,16(sp)
    8000688a:	64a2                	ld	s1,8(sp)
    8000688c:	6902                	ld	s2,0(sp)
    8000688e:	6105                	addi	sp,sp,32
    80006890:	8082                	ret
    panic("could not find virtio disk");
    80006892:	00002517          	auipc	a0,0x2
    80006896:	09e50513          	addi	a0,a0,158 # 80008930 <syscalls+0x348>
    8000689a:	ffffa097          	auipc	ra,0xffffa
    8000689e:	ca6080e7          	jalr	-858(ra) # 80000540 <panic>
    panic("virtio disk FEATURES_OK unset");
    800068a2:	00002517          	auipc	a0,0x2
    800068a6:	0ae50513          	addi	a0,a0,174 # 80008950 <syscalls+0x368>
    800068aa:	ffffa097          	auipc	ra,0xffffa
    800068ae:	c96080e7          	jalr	-874(ra) # 80000540 <panic>
    panic("virtio disk should not be ready");
    800068b2:	00002517          	auipc	a0,0x2
    800068b6:	0be50513          	addi	a0,a0,190 # 80008970 <syscalls+0x388>
    800068ba:	ffffa097          	auipc	ra,0xffffa
    800068be:	c86080e7          	jalr	-890(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    800068c2:	00002517          	auipc	a0,0x2
    800068c6:	0ce50513          	addi	a0,a0,206 # 80008990 <syscalls+0x3a8>
    800068ca:	ffffa097          	auipc	ra,0xffffa
    800068ce:	c76080e7          	jalr	-906(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    800068d2:	00002517          	auipc	a0,0x2
    800068d6:	0de50513          	addi	a0,a0,222 # 800089b0 <syscalls+0x3c8>
    800068da:	ffffa097          	auipc	ra,0xffffa
    800068de:	c66080e7          	jalr	-922(ra) # 80000540 <panic>
    panic("virtio disk kalloc");
    800068e2:	00002517          	auipc	a0,0x2
    800068e6:	0ee50513          	addi	a0,a0,238 # 800089d0 <syscalls+0x3e8>
    800068ea:	ffffa097          	auipc	ra,0xffffa
    800068ee:	c56080e7          	jalr	-938(ra) # 80000540 <panic>

00000000800068f2 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800068f2:	7119                	addi	sp,sp,-128
    800068f4:	fc86                	sd	ra,120(sp)
    800068f6:	f8a2                	sd	s0,112(sp)
    800068f8:	f4a6                	sd	s1,104(sp)
    800068fa:	f0ca                	sd	s2,96(sp)
    800068fc:	ecce                	sd	s3,88(sp)
    800068fe:	e8d2                	sd	s4,80(sp)
    80006900:	e4d6                	sd	s5,72(sp)
    80006902:	e0da                	sd	s6,64(sp)
    80006904:	fc5e                	sd	s7,56(sp)
    80006906:	f862                	sd	s8,48(sp)
    80006908:	f466                	sd	s9,40(sp)
    8000690a:	f06a                	sd	s10,32(sp)
    8000690c:	ec6e                	sd	s11,24(sp)
    8000690e:	0100                	addi	s0,sp,128
    80006910:	8aaa                	mv	s5,a0
    80006912:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006914:	00c52d03          	lw	s10,12(a0)
    80006918:	001d1d1b          	slliw	s10,s10,0x1
    8000691c:	1d02                	slli	s10,s10,0x20
    8000691e:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    80006922:	0023d517          	auipc	a0,0x23d
    80006926:	93e50513          	addi	a0,a0,-1730 # 80243260 <disk+0x128>
    8000692a:	ffffa097          	auipc	ra,0xffffa
    8000692e:	476080e7          	jalr	1142(ra) # 80000da0 <acquire>
  for(int i = 0; i < 3; i++){
    80006932:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006934:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006936:	0023db97          	auipc	s7,0x23d
    8000693a:	802b8b93          	addi	s7,s7,-2046 # 80243138 <disk>
  for(int i = 0; i < 3; i++){
    8000693e:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006940:	0023dc97          	auipc	s9,0x23d
    80006944:	920c8c93          	addi	s9,s9,-1760 # 80243260 <disk+0x128>
    80006948:	a08d                	j	800069aa <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    8000694a:	00fb8733          	add	a4,s7,a5
    8000694e:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006952:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006954:	0207c563          	bltz	a5,8000697e <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    80006958:	2905                	addiw	s2,s2,1
    8000695a:	0611                	addi	a2,a2,4 # 1004 <_entry-0x7fffeffc>
    8000695c:	05690c63          	beq	s2,s6,800069b4 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80006960:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006962:	0023c717          	auipc	a4,0x23c
    80006966:	7d670713          	addi	a4,a4,2006 # 80243138 <disk>
    8000696a:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000696c:	01874683          	lbu	a3,24(a4)
    80006970:	fee9                	bnez	a3,8000694a <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006972:	2785                	addiw	a5,a5,1
    80006974:	0705                	addi	a4,a4,1
    80006976:	fe979be3          	bne	a5,s1,8000696c <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    8000697a:	57fd                	li	a5,-1
    8000697c:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    8000697e:	01205d63          	blez	s2,80006998 <virtio_disk_rw+0xa6>
    80006982:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006984:	000a2503          	lw	a0,0(s4)
    80006988:	00000097          	auipc	ra,0x0
    8000698c:	cfe080e7          	jalr	-770(ra) # 80006686 <free_desc>
      for(int j = 0; j < i; j++)
    80006990:	2d85                	addiw	s11,s11,1
    80006992:	0a11                	addi	s4,s4,4
    80006994:	ff2d98e3          	bne	s11,s2,80006984 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006998:	85e6                	mv	a1,s9
    8000699a:	0023c517          	auipc	a0,0x23c
    8000699e:	7b650513          	addi	a0,a0,1974 # 80243150 <disk+0x18>
    800069a2:	ffffc097          	auipc	ra,0xffffc
    800069a6:	9ca080e7          	jalr	-1590(ra) # 8000236c <sleep>
  for(int i = 0; i < 3; i++){
    800069aa:	f8040a13          	addi	s4,s0,-128
{
    800069ae:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    800069b0:	894e                	mv	s2,s3
    800069b2:	b77d                	j	80006960 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800069b4:	f8042503          	lw	a0,-128(s0)
    800069b8:	00a50713          	addi	a4,a0,10
    800069bc:	0712                	slli	a4,a4,0x4

  if(write)
    800069be:	0023c797          	auipc	a5,0x23c
    800069c2:	77a78793          	addi	a5,a5,1914 # 80243138 <disk>
    800069c6:	00e786b3          	add	a3,a5,a4
    800069ca:	01803633          	snez	a2,s8
    800069ce:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800069d0:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    800069d4:	01a6b823          	sd	s10,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800069d8:	f6070613          	addi	a2,a4,-160
    800069dc:	6394                	ld	a3,0(a5)
    800069de:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800069e0:	00870593          	addi	a1,a4,8
    800069e4:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    800069e6:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800069e8:	0007b803          	ld	a6,0(a5)
    800069ec:	9642                	add	a2,a2,a6
    800069ee:	46c1                	li	a3,16
    800069f0:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800069f2:	4585                	li	a1,1
    800069f4:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    800069f8:	f8442683          	lw	a3,-124(s0)
    800069fc:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006a00:	0692                	slli	a3,a3,0x4
    80006a02:	9836                	add	a6,a6,a3
    80006a04:	058a8613          	addi	a2,s5,88
    80006a08:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    80006a0c:	0007b803          	ld	a6,0(a5)
    80006a10:	96c2                	add	a3,a3,a6
    80006a12:	40000613          	li	a2,1024
    80006a16:	c690                	sw	a2,8(a3)
  if(write)
    80006a18:	001c3613          	seqz	a2,s8
    80006a1c:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006a20:	00166613          	ori	a2,a2,1
    80006a24:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80006a28:	f8842603          	lw	a2,-120(s0)
    80006a2c:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006a30:	00250693          	addi	a3,a0,2
    80006a34:	0692                	slli	a3,a3,0x4
    80006a36:	96be                	add	a3,a3,a5
    80006a38:	58fd                	li	a7,-1
    80006a3a:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006a3e:	0612                	slli	a2,a2,0x4
    80006a40:	9832                	add	a6,a6,a2
    80006a42:	f9070713          	addi	a4,a4,-112
    80006a46:	973e                	add	a4,a4,a5
    80006a48:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    80006a4c:	6398                	ld	a4,0(a5)
    80006a4e:	9732                	add	a4,a4,a2
    80006a50:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006a52:	4609                	li	a2,2
    80006a54:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    80006a58:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006a5c:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    80006a60:	0156b423          	sd	s5,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006a64:	6794                	ld	a3,8(a5)
    80006a66:	0026d703          	lhu	a4,2(a3)
    80006a6a:	8b1d                	andi	a4,a4,7
    80006a6c:	0706                	slli	a4,a4,0x1
    80006a6e:	96ba                	add	a3,a3,a4
    80006a70:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80006a74:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006a78:	6798                	ld	a4,8(a5)
    80006a7a:	00275783          	lhu	a5,2(a4)
    80006a7e:	2785                	addiw	a5,a5,1
    80006a80:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006a84:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006a88:	100017b7          	lui	a5,0x10001
    80006a8c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006a90:	004aa783          	lw	a5,4(s5)
    sleep(b, &disk.vdisk_lock);
    80006a94:	0023c917          	auipc	s2,0x23c
    80006a98:	7cc90913          	addi	s2,s2,1996 # 80243260 <disk+0x128>
  while(b->disk == 1) {
    80006a9c:	4485                	li	s1,1
    80006a9e:	00b79c63          	bne	a5,a1,80006ab6 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80006aa2:	85ca                	mv	a1,s2
    80006aa4:	8556                	mv	a0,s5
    80006aa6:	ffffc097          	auipc	ra,0xffffc
    80006aaa:	8c6080e7          	jalr	-1850(ra) # 8000236c <sleep>
  while(b->disk == 1) {
    80006aae:	004aa783          	lw	a5,4(s5)
    80006ab2:	fe9788e3          	beq	a5,s1,80006aa2 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006ab6:	f8042903          	lw	s2,-128(s0)
    80006aba:	00290713          	addi	a4,s2,2
    80006abe:	0712                	slli	a4,a4,0x4
    80006ac0:	0023c797          	auipc	a5,0x23c
    80006ac4:	67878793          	addi	a5,a5,1656 # 80243138 <disk>
    80006ac8:	97ba                	add	a5,a5,a4
    80006aca:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    80006ace:	0023c997          	auipc	s3,0x23c
    80006ad2:	66a98993          	addi	s3,s3,1642 # 80243138 <disk>
    80006ad6:	00491713          	slli	a4,s2,0x4
    80006ada:	0009b783          	ld	a5,0(s3)
    80006ade:	97ba                	add	a5,a5,a4
    80006ae0:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006ae4:	854a                	mv	a0,s2
    80006ae6:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006aea:	00000097          	auipc	ra,0x0
    80006aee:	b9c080e7          	jalr	-1124(ra) # 80006686 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006af2:	8885                	andi	s1,s1,1
    80006af4:	f0ed                	bnez	s1,80006ad6 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006af6:	0023c517          	auipc	a0,0x23c
    80006afa:	76a50513          	addi	a0,a0,1898 # 80243260 <disk+0x128>
    80006afe:	ffffa097          	auipc	ra,0xffffa
    80006b02:	356080e7          	jalr	854(ra) # 80000e54 <release>
}
    80006b06:	70e6                	ld	ra,120(sp)
    80006b08:	7446                	ld	s0,112(sp)
    80006b0a:	74a6                	ld	s1,104(sp)
    80006b0c:	7906                	ld	s2,96(sp)
    80006b0e:	69e6                	ld	s3,88(sp)
    80006b10:	6a46                	ld	s4,80(sp)
    80006b12:	6aa6                	ld	s5,72(sp)
    80006b14:	6b06                	ld	s6,64(sp)
    80006b16:	7be2                	ld	s7,56(sp)
    80006b18:	7c42                	ld	s8,48(sp)
    80006b1a:	7ca2                	ld	s9,40(sp)
    80006b1c:	7d02                	ld	s10,32(sp)
    80006b1e:	6de2                	ld	s11,24(sp)
    80006b20:	6109                	addi	sp,sp,128
    80006b22:	8082                	ret

0000000080006b24 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006b24:	1101                	addi	sp,sp,-32
    80006b26:	ec06                	sd	ra,24(sp)
    80006b28:	e822                	sd	s0,16(sp)
    80006b2a:	e426                	sd	s1,8(sp)
    80006b2c:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006b2e:	0023c497          	auipc	s1,0x23c
    80006b32:	60a48493          	addi	s1,s1,1546 # 80243138 <disk>
    80006b36:	0023c517          	auipc	a0,0x23c
    80006b3a:	72a50513          	addi	a0,a0,1834 # 80243260 <disk+0x128>
    80006b3e:	ffffa097          	auipc	ra,0xffffa
    80006b42:	262080e7          	jalr	610(ra) # 80000da0 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006b46:	10001737          	lui	a4,0x10001
    80006b4a:	533c                	lw	a5,96(a4)
    80006b4c:	8b8d                	andi	a5,a5,3
    80006b4e:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006b50:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006b54:	689c                	ld	a5,16(s1)
    80006b56:	0204d703          	lhu	a4,32(s1)
    80006b5a:	0027d783          	lhu	a5,2(a5)
    80006b5e:	04f70863          	beq	a4,a5,80006bae <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006b62:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006b66:	6898                	ld	a4,16(s1)
    80006b68:	0204d783          	lhu	a5,32(s1)
    80006b6c:	8b9d                	andi	a5,a5,7
    80006b6e:	078e                	slli	a5,a5,0x3
    80006b70:	97ba                	add	a5,a5,a4
    80006b72:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006b74:	00278713          	addi	a4,a5,2
    80006b78:	0712                	slli	a4,a4,0x4
    80006b7a:	9726                	add	a4,a4,s1
    80006b7c:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006b80:	e721                	bnez	a4,80006bc8 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006b82:	0789                	addi	a5,a5,2
    80006b84:	0792                	slli	a5,a5,0x4
    80006b86:	97a6                	add	a5,a5,s1
    80006b88:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    80006b8a:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006b8e:	ffffc097          	auipc	ra,0xffffc
    80006b92:	842080e7          	jalr	-1982(ra) # 800023d0 <wakeup>

    disk.used_idx += 1;
    80006b96:	0204d783          	lhu	a5,32(s1)
    80006b9a:	2785                	addiw	a5,a5,1
    80006b9c:	17c2                	slli	a5,a5,0x30
    80006b9e:	93c1                	srli	a5,a5,0x30
    80006ba0:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006ba4:	6898                	ld	a4,16(s1)
    80006ba6:	00275703          	lhu	a4,2(a4)
    80006baa:	faf71ce3          	bne	a4,a5,80006b62 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80006bae:	0023c517          	auipc	a0,0x23c
    80006bb2:	6b250513          	addi	a0,a0,1714 # 80243260 <disk+0x128>
    80006bb6:	ffffa097          	auipc	ra,0xffffa
    80006bba:	29e080e7          	jalr	670(ra) # 80000e54 <release>
}
    80006bbe:	60e2                	ld	ra,24(sp)
    80006bc0:	6442                	ld	s0,16(sp)
    80006bc2:	64a2                	ld	s1,8(sp)
    80006bc4:	6105                	addi	sp,sp,32
    80006bc6:	8082                	ret
      panic("virtio_disk_intr status");
    80006bc8:	00002517          	auipc	a0,0x2
    80006bcc:	e2050513          	addi	a0,a0,-480 # 800089e8 <syscalls+0x400>
    80006bd0:	ffffa097          	auipc	ra,0xffffa
    80006bd4:	970080e7          	jalr	-1680(ra) # 80000540 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0)
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
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0)
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
