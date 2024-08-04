
user/_broadcast:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <panic>:
};


void
panic(char *s)
{
   0:	1141                	addi	sp,sp,-16
   2:	e406                	sd	ra,8(sp)
   4:	e022                	sd	s0,0(sp)
   6:	0800                	addi	s0,sp,16
   8:	862a                	mv	a2,a0
  fprintf(2, "%s\n", s);
   a:	00001597          	auipc	a1,0x1
   e:	b6e58593          	addi	a1,a1,-1170 # b78 <malloc+0xea>
  12:	4509                	li	a0,2
  14:	00001097          	auipc	ra,0x1
  18:	98e080e7          	jalr	-1650(ra) # 9a2 <fprintf>
  exit(1);
  1c:	4505                	li	a0,1
  1e:	00000097          	auipc	ra,0x0
  22:	60a080e7          	jalr	1546(ra) # 628 <exit>

0000000000000026 <fork1>:
}

//create a new process
int
fork1(void)
{
  26:	1141                	addi	sp,sp,-16
  28:	e406                	sd	ra,8(sp)
  2a:	e022                	sd	s0,0(sp)
  2c:	0800                	addi	s0,sp,16
  int pid;
  pid = fork();
  2e:	00000097          	auipc	ra,0x0
  32:	5f2080e7          	jalr	1522(ra) # 620 <fork>
  if(pid == -1)
  36:	57fd                	li	a5,-1
  38:	00f50663          	beq	a0,a5,44 <fork1+0x1e>
    panic("fork");
  return pid;
}
  3c:	60a2                	ld	ra,8(sp)
  3e:	6402                	ld	s0,0(sp)
  40:	0141                	addi	sp,sp,16
  42:	8082                	ret
    panic("fork");
  44:	00001517          	auipc	a0,0x1
  48:	b3c50513          	addi	a0,a0,-1220 # b80 <malloc+0xf2>
  4c:	00000097          	auipc	ra,0x0
  50:	fb4080e7          	jalr	-76(ra) # 0 <panic>

0000000000000054 <pipe1>:

//create a pipe
void
pipe1(int fd[2])
{
  54:	1141                	addi	sp,sp,-16
  56:	e406                	sd	ra,8(sp)
  58:	e022                	sd	s0,0(sp)
  5a:	0800                	addi	s0,sp,16
 int rc = pipe(fd);
  5c:	00000097          	auipc	ra,0x0
  60:	5dc080e7          	jalr	1500(ra) # 638 <pipe>
 if(rc<0){
  64:	00054663          	bltz	a0,70 <pipe1+0x1c>
   panic("Fail to create a pipe.");
 }
}
  68:	60a2                	ld	ra,8(sp)
  6a:	6402                	ld	s0,0(sp)
  6c:	0141                	addi	sp,sp,16
  6e:	8082                	ret
   panic("Fail to create a pipe.");
  70:	00001517          	auipc	a0,0x1
  74:	b1850513          	addi	a0,a0,-1256 # b88 <malloc+0xfa>
  78:	00000097          	auipc	ra,0x0
  7c:	f88080e7          	jalr	-120(ra) # 0 <panic>

0000000000000080 <main>:


int 
main(int argc, char *argv[])
{
  80:	81010113          	addi	sp,sp,-2032
  84:	7e113423          	sd	ra,2024(sp)
  88:	7e813023          	sd	s0,2016(sp)
  8c:	7c913c23          	sd	s1,2008(sp)
  90:	7d213823          	sd	s2,2000(sp)
  94:	7d313423          	sd	s3,1992(sp)
  98:	7d413023          	sd	s4,1984(sp)
  9c:	7b513c23          	sd	s5,1976(sp)
  a0:	7f010413          	addi	s0,sp,2032
  a4:	b0010113          	addi	sp,sp,-1280
    if(argc<3){
  a8:	4789                	li	a5,2
  aa:	00a7ca63          	blt	a5,a0,be <main+0x3e>
        panic("Usage: broadcast <num_of_receivers> <msg_to_broadcast>");
  ae:	00001517          	auipc	a0,0x1
  b2:	af250513          	addi	a0,a0,-1294 # ba0 <malloc+0x112>
  b6:	00000097          	auipc	ra,0x0
  ba:	f4a080e7          	jalr	-182(ra) # 0 <panic>
  be:	892e                	mv	s2,a1
    }

    int numReceiver = atoi(argv[1]);
  c0:	6588                	ld	a0,8(a1)
  c2:	00000097          	auipc	ra,0x0
  c6:	46a080e7          	jalr	1130(ra) # 52c <atoi>
  ca:	84aa                	mv	s1,a0
    
    //create a pair of pipes as communication channels
    int channelToReceivers[2], channelFromReceivers[2];
    pipe(channelToReceivers);
  cc:	fb840513          	addi	a0,s0,-72
  d0:	00000097          	auipc	ra,0x0
  d4:	568080e7          	jalr	1384(ra) # 638 <pipe>
    pipe(channelFromReceivers);
  d8:	fb040513          	addi	a0,s0,-80
  dc:	00000097          	auipc	ra,0x0
  e0:	55c080e7          	jalr	1372(ra) # 638 <pipe>
    
    for(int i=0; i<numReceiver; i++){
  e4:	02905c63          	blez	s1,11c <main+0x9c>
  e8:	4981                	li	s3,0
	    //end of the child process
            exit(0);
		

        }else{
            printf("Parent: creates child process with id: %d\n", i);
  ea:	00001a97          	auipc	s5,0x1
  ee:	b2ea8a93          	addi	s5,s5,-1234 # c18 <malloc+0x18a>
        int retFork = fork1();
  f2:	00000097          	auipc	ra,0x0
  f6:	f34080e7          	jalr	-204(ra) # 26 <fork1>
  fa:	8a2a                	mv	s4,a0
        if(retFork==0){
  fc:	1c050d63          	beqz	a0,2d6 <main+0x256>
            printf("Parent: creates child process with id: %d\n", i);
 100:	85ce                	mv	a1,s3
 102:	8556                	mv	a0,s5
 104:	00001097          	auipc	ra,0x1
 108:	8cc080e7          	jalr	-1844(ra) # 9d0 <printf>
        }
        sleep(1);
 10c:	4505                	li	a0,1
 10e:	00000097          	auipc	ra,0x0
 112:	5aa080e7          	jalr	1450(ra) # 6b8 <sleep>
    for(int i=0; i<numReceiver; i++){
 116:	2985                	addiw	s3,s3,1
 118:	fd349de3          	bne	s1,s3,f2 <main+0x72>
            printf("Child %d: start!\n", myId);
 11c:	00bc6737          	lui	a4,0xbc6
 120:	14e70713          	addi	a4,a4,334 # bc614e <__global_pointer$+0xbc4b5d>
 124:	06400693          	li	a3,100
 128:	87b6                	mv	a5,a3
    /*following is the parent's code*/
    
    //to fake some computation workload for Project 1.B
    float x=123456.0;
    for(int i=0; i<12345678; i++)
	    for(int j=0; j<100; j++) 
 12a:	37fd                	addiw	a5,a5,-1
 12c:	fffd                	bnez	a5,12a <main+0xaa>
    for(int i=0; i<12345678; i++)
 12e:	377d                	addiw	a4,a4,-1
 130:	ff65                	bnez	a4,128 <main+0xa8>
		    x=x*x;

    //to broadcast message
    struct msg_t msg;
    for(int i=0; i<numReceiver; i++)
 132:	02905163          	blez	s1,154 <main+0xd4>
 136:	e8840713          	addi	a4,s0,-376
 13a:	fff4879b          	addiw	a5,s1,-1
 13e:	1782                	slli	a5,a5,0x20
 140:	9381                	srli	a5,a5,0x20
 142:	078a                	slli	a5,a5,0x2
 144:	e8c40693          	addi	a3,s0,-372
 148:	97b6                	add	a5,a5,a3
        msg.flags[i] = 1;
 14a:	4685                	li	a3,1
 14c:	c314                	sw	a3,0(a4)
    for(int i=0; i<numReceiver; i++)
 14e:	0711                	addi	a4,a4,4
 150:	fef71ee3          	bne	a4,a5,14c <main+0xcc>
    strcpy(msg.content, argv[2]);
 154:	01093583          	ld	a1,16(s2)
 158:	eb040513          	addi	a0,s0,-336
 15c:	00000097          	auipc	ra,0x0
 160:	25e080e7          	jalr	606(ra) # 3ba <strcpy>
    write(channelToReceivers[1], &msg, sizeof(struct msg_t));
 164:	12800613          	li	a2,296
 168:	e8840593          	addi	a1,s0,-376
 16c:	fbc42503          	lw	a0,-68(s0)
 170:	00000097          	auipc	ra,0x0
 174:	4d8080e7          	jalr	1240(ra) # 648 <write>
    printf("Parent broadcasts: %s\n", msg.content);
 178:	eb040593          	addi	a1,s0,-336
 17c:	00001517          	auipc	a0,0x1
 180:	acc50513          	addi	a0,a0,-1332 # c48 <malloc+0x1ba>
 184:	00001097          	auipc	ra,0x1
 188:	84c080e7          	jalr	-1972(ra) # 9d0 <printf>

    //to receive acknowledgement
    char recvBuf[sizeof(struct msg_t)];        
    read(channelFromReceivers[0], &recvBuf, sizeof(struct msg_t));
 18c:	12800613          	li	a2,296
 190:	d6040593          	addi	a1,s0,-672
 194:	fb042503          	lw	a0,-80(s0)
 198:	00000097          	auipc	ra,0x0
 19c:	4a8080e7          	jalr	1192(ra) # 640 <read>
    printf("Parent receives: %s\n", recvBuf);
 1a0:	d6040593          	addi	a1,s0,-672
 1a4:	00001517          	auipc	a0,0x1
 1a8:	abc50513          	addi	a0,a0,-1348 # c60 <malloc+0x1d2>
 1ac:	00001097          	auipc	ra,0x1
 1b0:	824080e7          	jalr	-2012(ra) # 9d0 <printf>

    //call the new system calls for Project 1.B
    printf("\nCall system calls for Project 1.B\n\n");
 1b4:	00001517          	auipc	a0,0x1
 1b8:	ac450513          	addi	a0,a0,-1340 # c78 <malloc+0x1ea>
 1bc:	00001097          	auipc	ra,0x1
 1c0:	814080e7          	jalr	-2028(ra) # 9d0 <printf>

    printf("Result from calling getppid:\n");
 1c4:	00001517          	auipc	a0,0x1
 1c8:	adc50513          	addi	a0,a0,-1316 # ca0 <malloc+0x212>
 1cc:	00001097          	auipc	ra,0x1
 1d0:	804080e7          	jalr	-2044(ra) # 9d0 <printf>
    int ppid = getppid();
 1d4:	00000097          	auipc	ra,0x0
 1d8:	4f4080e7          	jalr	1268(ra) # 6c8 <getppid>
 1dc:	85aa                	mv	a1,a0
    printf("My ppid = %d\n", ppid);
 1de:	00001517          	auipc	a0,0x1
 1e2:	ae250513          	addi	a0,a0,-1310 # cc0 <malloc+0x232>
 1e6:	00000097          	auipc	ra,0x0
 1ea:	7ea080e7          	jalr	2026(ra) # 9d0 <printf>

    printf("\nResult from calling ps:\n");
 1ee:	00001517          	auipc	a0,0x1
 1f2:	ae250513          	addi	a0,a0,-1310 # cd0 <malloc+0x242>
 1f6:	00000097          	auipc	ra,0x0
 1fa:	7da080e7          	jalr	2010(ra) # 9d0 <printf>
    int ret;
    struct ps_struct myPS[64];
    ret = ps((char *)&myPS);
 1fe:	757d                	lui	a0,0xfffff
 200:	4a050513          	addi	a0,a0,1184 # fffffffffffff4a0 <__global_pointer$+0xffffffffffffdeaf>
 204:	fc040793          	addi	a5,s0,-64
 208:	953e                	add	a0,a0,a5
 20a:	00000097          	auipc	ra,0x0
 20e:	4c6080e7          	jalr	1222(ra) # 6d0 <ps>
 212:	84aa                	mv	s1,a0
    printf("Total number of processes: %d\n", ret);
 214:	85aa                	mv	a1,a0
 216:	00001517          	auipc	a0,0x1
 21a:	ada50513          	addi	a0,a0,-1318 # cf0 <malloc+0x262>
 21e:	00000097          	auipc	ra,0x0
 222:	7b2080e7          	jalr	1970(ra) # 9d0 <printf>
    for(int i=0; i<ret; i++){
 226:	04905863          	blez	s1,276 <main+0x1f6>
 22a:	77fd                	lui	a5,0xfffff
 22c:	4a078793          	addi	a5,a5,1184 # fffffffffffff4a0 <__global_pointer$+0xffffffffffffdeaf>
 230:	fc040713          	addi	a4,s0,-64
 234:	97ba                	add	a5,a5,a4
 236:	00878913          	addi	s2,a5,8
 23a:	34fd                	addiw	s1,s1,-1
 23c:	1482                	slli	s1,s1,0x20
 23e:	9081                	srli	s1,s1,0x20
 240:	02400713          	li	a4,36
 244:	02e484b3          	mul	s1,s1,a4
 248:	02c78793          	addi	a5,a5,44
 24c:	94be                	add	s1,s1,a5
        printf("pid: %d, ppid: %d, state: %s, name: %s\n",
 24e:	00001997          	auipc	s3,0x1
 252:	ac298993          	addi	s3,s3,-1342 # d10 <malloc+0x282>
 256:	00a90713          	addi	a4,s2,10
 25a:	86ca                	mv	a3,s2
 25c:	ffc92603          	lw	a2,-4(s2)
 260:	ff892583          	lw	a1,-8(s2)
 264:	854e                	mv	a0,s3
 266:	00000097          	auipc	ra,0x0
 26a:	76a080e7          	jalr	1898(ra) # 9d0 <printf>
    for(int i=0; i<ret; i++){
 26e:	02490913          	addi	s2,s2,36
 272:	fe9912e3          	bne	s2,s1,256 <main+0x1d6>
        myPS[i].pid, myPS[i].ppid, myPS[i].state, myPS[i].name);
    }

    printf("\nResult from calling getschedhistory:\n");
 276:	00001517          	auipc	a0,0x1
 27a:	ac250513          	addi	a0,a0,-1342 # d38 <malloc+0x2aa>
 27e:	00000097          	auipc	ra,0x0
 282:	752080e7          	jalr	1874(ra) # 9d0 <printf>
    struct sched_history myHistory;
    ret = getschedhistory((char *)&myHistory);
 286:	74fd                	lui	s1,0xfffff
 288:	48848513          	addi	a0,s1,1160 # fffffffffffff488 <__global_pointer$+0xffffffffffffde97>
 28c:	fc040793          	addi	a5,s0,-64
 290:	953e                	add	a0,a0,a5
 292:	00000097          	auipc	ra,0x0
 296:	446080e7          	jalr	1094(ra) # 6d8 <getschedhistory>
 29a:	85aa                	mv	a1,a0
    printf("My scheduling history\n pid: %d\n runs: %d, traps: %d, interrupts: %d, preemptions: %d, sleeps: %d, system calls: %d\n",
 29c:	fc040793          	addi	a5,s0,-64
 2a0:	00978633          	add	a2,a5,s1
 2a4:	48c62883          	lw	a7,1164(a2)
 2a8:	49c62803          	lw	a6,1180(a2)
 2ac:	49462783          	lw	a5,1172(a2)
 2b0:	49062703          	lw	a4,1168(a2)
 2b4:	49862683          	lw	a3,1176(a2)
 2b8:	48862603          	lw	a2,1160(a2)
 2bc:	00001517          	auipc	a0,0x1
 2c0:	aa450513          	addi	a0,a0,-1372 # d60 <malloc+0x2d2>
 2c4:	00000097          	auipc	ra,0x0
 2c8:	70c080e7          	jalr	1804(ra) # 9d0 <printf>
        ret, myHistory.runCount, myHistory.trapCount, myHistory.interruptCount,
        myHistory.preemptCount, myHistory.sleepCount, myHistory.systemcallCount);

    //end of parent process 
    exit(0);
 2cc:	4501                	li	a0,0
 2ce:	00000097          	auipc	ra,0x0
 2d2:	35a080e7          	jalr	858(ra) # 628 <exit>
            printf("Child %d: start!\n", myId);
 2d6:	85ce                	mv	a1,s3
 2d8:	00001517          	auipc	a0,0x1
 2dc:	90050513          	addi	a0,a0,-1792 # bd8 <malloc+0x14a>
 2e0:	00000097          	auipc	ra,0x0
 2e4:	6f0080e7          	jalr	1776(ra) # 9d0 <printf>
 2e8:	00bc6737          	lui	a4,0xbc6
 2ec:	14e70713          	addi	a4,a4,334 # bc614e <__global_pointer$+0xbc4b5d>
    for(int i=0; i<numReceiver; i++){
 2f0:	06400693          	li	a3,100
 2f4:	87b6                	mv	a5,a3
		    for(int j=0; j<100; j++)
 2f6:	37fd                	addiw	a5,a5,-1
 2f8:	fffd                	bnez	a5,2f6 <main+0x276>
	    for(int i=0; i<12345678; i++)
 2fa:	377d                	addiw	a4,a4,-1
 2fc:	ff65                	bnez	a4,2f4 <main+0x274>
            read(channelToReceivers[0], 
 2fe:	7afd                	lui	s5,0xfffff
 300:	360a8793          	addi	a5,s5,864 # fffffffffffff360 <__global_pointer$+0xffffffffffffdd6f>
 304:	fc040713          	addi	a4,s0,-64
 308:	00f704b3          	add	s1,a4,a5
 30c:	12800613          	li	a2,296
 310:	85a6                	mv	a1,s1
 312:	fb842503          	lw	a0,-72(s0)
 316:	00000097          	auipc	ra,0x0
 31a:	32a080e7          	jalr	810(ra) # 640 <read>
            printf("Child %d: get msg (%s)\n", 
 31e:	02848913          	addi	s2,s1,40
 322:	864a                	mv	a2,s2
 324:	85ce                	mv	a1,s3
 326:	00001517          	auipc	a0,0x1
 32a:	8ca50513          	addi	a0,a0,-1846 # bf0 <malloc+0x162>
 32e:	00000097          	auipc	ra,0x0
 332:	6a2080e7          	jalr	1698(ra) # 9d0 <printf>
            msg.flags[i]=0;
 336:	fc040793          	addi	a5,s0,-64
 33a:	97d6                	add	a5,a5,s5
 33c:	76fd                	lui	a3,0xfffff
 33e:	31868713          	addi	a4,a3,792 # fffffffffffff318 <__global_pointer$+0xffffffffffffdd27>
 342:	9722                	add	a4,a4,s0
 344:	e31c                	sd	a5,0(a4)
 346:	098a                	slli	s3,s3,0x2
 348:	631c                	ld	a5,0(a4)
 34a:	99be                	add	s3,s3,a5
 34c:	3609a023          	sw	zero,864(s3)
            for(int j=0; j<MAX_NUM_RECEIVERS; j++)
 350:	87a6                	mv	a5,s1
                    sum += msg.flags[j];
 352:	4398                	lw	a4,0(a5)
 354:	01470a3b          	addw	s4,a4,s4
            for(int j=0; j<MAX_NUM_RECEIVERS; j++)
 358:	0791                	addi	a5,a5,4
 35a:	fef91ce3          	bne	s2,a5,352 <main+0x2d2>
            if(sum==0){
 35e:	020a1263          	bnez	s4,382 <main+0x302>
                write(channelFromReceivers[1],"completed!",10);    
 362:	4629                	li	a2,10
 364:	00001597          	auipc	a1,0x1
 368:	8a458593          	addi	a1,a1,-1884 # c08 <malloc+0x17a>
 36c:	fb442503          	lw	a0,-76(s0)
 370:	00000097          	auipc	ra,0x0
 374:	2d8080e7          	jalr	728(ra) # 648 <write>
            exit(0);
 378:	4501                	li	a0,0
 37a:	00000097          	auipc	ra,0x0
 37e:	2ae080e7          	jalr	686(ra) # 628 <exit>
                write(channelToReceivers[1],&msg,sizeof(msg));
 382:	12800613          	li	a2,296
 386:	75fd                	lui	a1,0xfffff
 388:	36058593          	addi	a1,a1,864 # fffffffffffff360 <__global_pointer$+0xffffffffffffdd6f>
 38c:	fc040793          	addi	a5,s0,-64
 390:	95be                	add	a1,a1,a5
 392:	fbc42503          	lw	a0,-68(s0)
 396:	00000097          	auipc	ra,0x0
 39a:	2b2080e7          	jalr	690(ra) # 648 <write>
 39e:	bfe9                	j	378 <main+0x2f8>

00000000000003a0 <_main>:
//
// wrapper so that it's OK if main() does not call exit().
//
void
_main()
{
 3a0:	1141                	addi	sp,sp,-16
 3a2:	e406                	sd	ra,8(sp)
 3a4:	e022                	sd	s0,0(sp)
 3a6:	0800                	addi	s0,sp,16
  extern int main();
  main();
 3a8:	00000097          	auipc	ra,0x0
 3ac:	cd8080e7          	jalr	-808(ra) # 80 <main>
  exit(0);
 3b0:	4501                	li	a0,0
 3b2:	00000097          	auipc	ra,0x0
 3b6:	276080e7          	jalr	630(ra) # 628 <exit>

00000000000003ba <strcpy>:
}

char*
strcpy(char *s, const char *t)
{
 3ba:	1141                	addi	sp,sp,-16
 3bc:	e422                	sd	s0,8(sp)
 3be:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 3c0:	87aa                	mv	a5,a0
 3c2:	0585                	addi	a1,a1,1
 3c4:	0785                	addi	a5,a5,1
 3c6:	fff5c703          	lbu	a4,-1(a1)
 3ca:	fee78fa3          	sb	a4,-1(a5)
 3ce:	fb75                	bnez	a4,3c2 <strcpy+0x8>
    ;
  return os;
}
 3d0:	6422                	ld	s0,8(sp)
 3d2:	0141                	addi	sp,sp,16
 3d4:	8082                	ret

00000000000003d6 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 3d6:	1141                	addi	sp,sp,-16
 3d8:	e422                	sd	s0,8(sp)
 3da:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 3dc:	00054783          	lbu	a5,0(a0)
 3e0:	cb91                	beqz	a5,3f4 <strcmp+0x1e>
 3e2:	0005c703          	lbu	a4,0(a1)
 3e6:	00f71763          	bne	a4,a5,3f4 <strcmp+0x1e>
    p++, q++;
 3ea:	0505                	addi	a0,a0,1
 3ec:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 3ee:	00054783          	lbu	a5,0(a0)
 3f2:	fbe5                	bnez	a5,3e2 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 3f4:	0005c503          	lbu	a0,0(a1)
}
 3f8:	40a7853b          	subw	a0,a5,a0
 3fc:	6422                	ld	s0,8(sp)
 3fe:	0141                	addi	sp,sp,16
 400:	8082                	ret

0000000000000402 <strlen>:

uint
strlen(const char *s)
{
 402:	1141                	addi	sp,sp,-16
 404:	e422                	sd	s0,8(sp)
 406:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 408:	00054783          	lbu	a5,0(a0)
 40c:	cf91                	beqz	a5,428 <strlen+0x26>
 40e:	0505                	addi	a0,a0,1
 410:	87aa                	mv	a5,a0
 412:	4685                	li	a3,1
 414:	9e89                	subw	a3,a3,a0
 416:	00f6853b          	addw	a0,a3,a5
 41a:	0785                	addi	a5,a5,1
 41c:	fff7c703          	lbu	a4,-1(a5)
 420:	fb7d                	bnez	a4,416 <strlen+0x14>
    ;
  return n;
}
 422:	6422                	ld	s0,8(sp)
 424:	0141                	addi	sp,sp,16
 426:	8082                	ret
  for(n = 0; s[n]; n++)
 428:	4501                	li	a0,0
 42a:	bfe5                	j	422 <strlen+0x20>

000000000000042c <memset>:

void*
memset(void *dst, int c, uint n)
{
 42c:	1141                	addi	sp,sp,-16
 42e:	e422                	sd	s0,8(sp)
 430:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 432:	ca19                	beqz	a2,448 <memset+0x1c>
 434:	87aa                	mv	a5,a0
 436:	1602                	slli	a2,a2,0x20
 438:	9201                	srli	a2,a2,0x20
 43a:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 43e:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 442:	0785                	addi	a5,a5,1
 444:	fee79de3          	bne	a5,a4,43e <memset+0x12>
  }
  return dst;
}
 448:	6422                	ld	s0,8(sp)
 44a:	0141                	addi	sp,sp,16
 44c:	8082                	ret

000000000000044e <strchr>:

char*
strchr(const char *s, char c)
{
 44e:	1141                	addi	sp,sp,-16
 450:	e422                	sd	s0,8(sp)
 452:	0800                	addi	s0,sp,16
  for(; *s; s++)
 454:	00054783          	lbu	a5,0(a0)
 458:	cb99                	beqz	a5,46e <strchr+0x20>
    if(*s == c)
 45a:	00f58763          	beq	a1,a5,468 <strchr+0x1a>
  for(; *s; s++)
 45e:	0505                	addi	a0,a0,1
 460:	00054783          	lbu	a5,0(a0)
 464:	fbfd                	bnez	a5,45a <strchr+0xc>
      return (char*)s;
  return 0;
 466:	4501                	li	a0,0
}
 468:	6422                	ld	s0,8(sp)
 46a:	0141                	addi	sp,sp,16
 46c:	8082                	ret
  return 0;
 46e:	4501                	li	a0,0
 470:	bfe5                	j	468 <strchr+0x1a>

0000000000000472 <gets>:

char*
gets(char *buf, int max)
{
 472:	711d                	addi	sp,sp,-96
 474:	ec86                	sd	ra,88(sp)
 476:	e8a2                	sd	s0,80(sp)
 478:	e4a6                	sd	s1,72(sp)
 47a:	e0ca                	sd	s2,64(sp)
 47c:	fc4e                	sd	s3,56(sp)
 47e:	f852                	sd	s4,48(sp)
 480:	f456                	sd	s5,40(sp)
 482:	f05a                	sd	s6,32(sp)
 484:	ec5e                	sd	s7,24(sp)
 486:	1080                	addi	s0,sp,96
 488:	8baa                	mv	s7,a0
 48a:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 48c:	892a                	mv	s2,a0
 48e:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 490:	4aa9                	li	s5,10
 492:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 494:	89a6                	mv	s3,s1
 496:	2485                	addiw	s1,s1,1
 498:	0344d863          	bge	s1,s4,4c8 <gets+0x56>
    cc = read(0, &c, 1);
 49c:	4605                	li	a2,1
 49e:	faf40593          	addi	a1,s0,-81
 4a2:	4501                	li	a0,0
 4a4:	00000097          	auipc	ra,0x0
 4a8:	19c080e7          	jalr	412(ra) # 640 <read>
    if(cc < 1)
 4ac:	00a05e63          	blez	a0,4c8 <gets+0x56>
    buf[i++] = c;
 4b0:	faf44783          	lbu	a5,-81(s0)
 4b4:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 4b8:	01578763          	beq	a5,s5,4c6 <gets+0x54>
 4bc:	0905                	addi	s2,s2,1
 4be:	fd679be3          	bne	a5,s6,494 <gets+0x22>
  for(i=0; i+1 < max; ){
 4c2:	89a6                	mv	s3,s1
 4c4:	a011                	j	4c8 <gets+0x56>
 4c6:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 4c8:	99de                	add	s3,s3,s7
 4ca:	00098023          	sb	zero,0(s3)
  return buf;
}
 4ce:	855e                	mv	a0,s7
 4d0:	60e6                	ld	ra,88(sp)
 4d2:	6446                	ld	s0,80(sp)
 4d4:	64a6                	ld	s1,72(sp)
 4d6:	6906                	ld	s2,64(sp)
 4d8:	79e2                	ld	s3,56(sp)
 4da:	7a42                	ld	s4,48(sp)
 4dc:	7aa2                	ld	s5,40(sp)
 4de:	7b02                	ld	s6,32(sp)
 4e0:	6be2                	ld	s7,24(sp)
 4e2:	6125                	addi	sp,sp,96
 4e4:	8082                	ret

00000000000004e6 <stat>:

int
stat(const char *n, struct stat *st)
{
 4e6:	1101                	addi	sp,sp,-32
 4e8:	ec06                	sd	ra,24(sp)
 4ea:	e822                	sd	s0,16(sp)
 4ec:	e426                	sd	s1,8(sp)
 4ee:	e04a                	sd	s2,0(sp)
 4f0:	1000                	addi	s0,sp,32
 4f2:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 4f4:	4581                	li	a1,0
 4f6:	00000097          	auipc	ra,0x0
 4fa:	172080e7          	jalr	370(ra) # 668 <open>
  if(fd < 0)
 4fe:	02054563          	bltz	a0,528 <stat+0x42>
 502:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 504:	85ca                	mv	a1,s2
 506:	00000097          	auipc	ra,0x0
 50a:	17a080e7          	jalr	378(ra) # 680 <fstat>
 50e:	892a                	mv	s2,a0
  close(fd);
 510:	8526                	mv	a0,s1
 512:	00000097          	auipc	ra,0x0
 516:	13e080e7          	jalr	318(ra) # 650 <close>
  return r;
}
 51a:	854a                	mv	a0,s2
 51c:	60e2                	ld	ra,24(sp)
 51e:	6442                	ld	s0,16(sp)
 520:	64a2                	ld	s1,8(sp)
 522:	6902                	ld	s2,0(sp)
 524:	6105                	addi	sp,sp,32
 526:	8082                	ret
    return -1;
 528:	597d                	li	s2,-1
 52a:	bfc5                	j	51a <stat+0x34>

000000000000052c <atoi>:

int
atoi(const char *s)
{
 52c:	1141                	addi	sp,sp,-16
 52e:	e422                	sd	s0,8(sp)
 530:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 532:	00054603          	lbu	a2,0(a0)
 536:	fd06079b          	addiw	a5,a2,-48
 53a:	0ff7f793          	andi	a5,a5,255
 53e:	4725                	li	a4,9
 540:	02f76963          	bltu	a4,a5,572 <atoi+0x46>
 544:	86aa                	mv	a3,a0
  n = 0;
 546:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 548:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 54a:	0685                	addi	a3,a3,1
 54c:	0025179b          	slliw	a5,a0,0x2
 550:	9fa9                	addw	a5,a5,a0
 552:	0017979b          	slliw	a5,a5,0x1
 556:	9fb1                	addw	a5,a5,a2
 558:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 55c:	0006c603          	lbu	a2,0(a3)
 560:	fd06071b          	addiw	a4,a2,-48
 564:	0ff77713          	andi	a4,a4,255
 568:	fee5f1e3          	bgeu	a1,a4,54a <atoi+0x1e>
  return n;
}
 56c:	6422                	ld	s0,8(sp)
 56e:	0141                	addi	sp,sp,16
 570:	8082                	ret
  n = 0;
 572:	4501                	li	a0,0
 574:	bfe5                	j	56c <atoi+0x40>

0000000000000576 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 576:	1141                	addi	sp,sp,-16
 578:	e422                	sd	s0,8(sp)
 57a:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 57c:	02b57463          	bgeu	a0,a1,5a4 <memmove+0x2e>
    while(n-- > 0)
 580:	00c05f63          	blez	a2,59e <memmove+0x28>
 584:	1602                	slli	a2,a2,0x20
 586:	9201                	srli	a2,a2,0x20
 588:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 58c:	872a                	mv	a4,a0
      *dst++ = *src++;
 58e:	0585                	addi	a1,a1,1
 590:	0705                	addi	a4,a4,1
 592:	fff5c683          	lbu	a3,-1(a1)
 596:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 59a:	fee79ae3          	bne	a5,a4,58e <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 59e:	6422                	ld	s0,8(sp)
 5a0:	0141                	addi	sp,sp,16
 5a2:	8082                	ret
    dst += n;
 5a4:	00c50733          	add	a4,a0,a2
    src += n;
 5a8:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 5aa:	fec05ae3          	blez	a2,59e <memmove+0x28>
 5ae:	fff6079b          	addiw	a5,a2,-1
 5b2:	1782                	slli	a5,a5,0x20
 5b4:	9381                	srli	a5,a5,0x20
 5b6:	fff7c793          	not	a5,a5
 5ba:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 5bc:	15fd                	addi	a1,a1,-1
 5be:	177d                	addi	a4,a4,-1
 5c0:	0005c683          	lbu	a3,0(a1)
 5c4:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 5c8:	fee79ae3          	bne	a5,a4,5bc <memmove+0x46>
 5cc:	bfc9                	j	59e <memmove+0x28>

00000000000005ce <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 5ce:	1141                	addi	sp,sp,-16
 5d0:	e422                	sd	s0,8(sp)
 5d2:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 5d4:	ca05                	beqz	a2,604 <memcmp+0x36>
 5d6:	fff6069b          	addiw	a3,a2,-1
 5da:	1682                	slli	a3,a3,0x20
 5dc:	9281                	srli	a3,a3,0x20
 5de:	0685                	addi	a3,a3,1
 5e0:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 5e2:	00054783          	lbu	a5,0(a0)
 5e6:	0005c703          	lbu	a4,0(a1)
 5ea:	00e79863          	bne	a5,a4,5fa <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 5ee:	0505                	addi	a0,a0,1
    p2++;
 5f0:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 5f2:	fed518e3          	bne	a0,a3,5e2 <memcmp+0x14>
  }
  return 0;
 5f6:	4501                	li	a0,0
 5f8:	a019                	j	5fe <memcmp+0x30>
      return *p1 - *p2;
 5fa:	40e7853b          	subw	a0,a5,a4
}
 5fe:	6422                	ld	s0,8(sp)
 600:	0141                	addi	sp,sp,16
 602:	8082                	ret
  return 0;
 604:	4501                	li	a0,0
 606:	bfe5                	j	5fe <memcmp+0x30>

0000000000000608 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 608:	1141                	addi	sp,sp,-16
 60a:	e406                	sd	ra,8(sp)
 60c:	e022                	sd	s0,0(sp)
 60e:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 610:	00000097          	auipc	ra,0x0
 614:	f66080e7          	jalr	-154(ra) # 576 <memmove>
}
 618:	60a2                	ld	ra,8(sp)
 61a:	6402                	ld	s0,0(sp)
 61c:	0141                	addi	sp,sp,16
 61e:	8082                	ret

0000000000000620 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 620:	4885                	li	a7,1
 ecall
 622:	00000073          	ecall
 ret
 626:	8082                	ret

0000000000000628 <exit>:
.global exit
exit:
 li a7, SYS_exit
 628:	4889                	li	a7,2
 ecall
 62a:	00000073          	ecall
 ret
 62e:	8082                	ret

0000000000000630 <wait>:
.global wait
wait:
 li a7, SYS_wait
 630:	488d                	li	a7,3
 ecall
 632:	00000073          	ecall
 ret
 636:	8082                	ret

0000000000000638 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 638:	4891                	li	a7,4
 ecall
 63a:	00000073          	ecall
 ret
 63e:	8082                	ret

0000000000000640 <read>:
.global read
read:
 li a7, SYS_read
 640:	4895                	li	a7,5
 ecall
 642:	00000073          	ecall
 ret
 646:	8082                	ret

0000000000000648 <write>:
.global write
write:
 li a7, SYS_write
 648:	48c1                	li	a7,16
 ecall
 64a:	00000073          	ecall
 ret
 64e:	8082                	ret

0000000000000650 <close>:
.global close
close:
 li a7, SYS_close
 650:	48d5                	li	a7,21
 ecall
 652:	00000073          	ecall
 ret
 656:	8082                	ret

0000000000000658 <kill>:
.global kill
kill:
 li a7, SYS_kill
 658:	4899                	li	a7,6
 ecall
 65a:	00000073          	ecall
 ret
 65e:	8082                	ret

0000000000000660 <exec>:
.global exec
exec:
 li a7, SYS_exec
 660:	489d                	li	a7,7
 ecall
 662:	00000073          	ecall
 ret
 666:	8082                	ret

0000000000000668 <open>:
.global open
open:
 li a7, SYS_open
 668:	48bd                	li	a7,15
 ecall
 66a:	00000073          	ecall
 ret
 66e:	8082                	ret

0000000000000670 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 670:	48c5                	li	a7,17
 ecall
 672:	00000073          	ecall
 ret
 676:	8082                	ret

0000000000000678 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 678:	48c9                	li	a7,18
 ecall
 67a:	00000073          	ecall
 ret
 67e:	8082                	ret

0000000000000680 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 680:	48a1                	li	a7,8
 ecall
 682:	00000073          	ecall
 ret
 686:	8082                	ret

0000000000000688 <link>:
.global link
link:
 li a7, SYS_link
 688:	48cd                	li	a7,19
 ecall
 68a:	00000073          	ecall
 ret
 68e:	8082                	ret

0000000000000690 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 690:	48d1                	li	a7,20
 ecall
 692:	00000073          	ecall
 ret
 696:	8082                	ret

0000000000000698 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 698:	48a5                	li	a7,9
 ecall
 69a:	00000073          	ecall
 ret
 69e:	8082                	ret

00000000000006a0 <dup>:
.global dup
dup:
 li a7, SYS_dup
 6a0:	48a9                	li	a7,10
 ecall
 6a2:	00000073          	ecall
 ret
 6a6:	8082                	ret

00000000000006a8 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 6a8:	48ad                	li	a7,11
 ecall
 6aa:	00000073          	ecall
 ret
 6ae:	8082                	ret

00000000000006b0 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 6b0:	48b1                	li	a7,12
 ecall
 6b2:	00000073          	ecall
 ret
 6b6:	8082                	ret

00000000000006b8 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 6b8:	48b5                	li	a7,13
 ecall
 6ba:	00000073          	ecall
 ret
 6be:	8082                	ret

00000000000006c0 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 6c0:	48b9                	li	a7,14
 ecall
 6c2:	00000073          	ecall
 ret
 6c6:	8082                	ret

00000000000006c8 <getppid>:
.global getppid
getppid:
 li a7, SYS_getppid
 6c8:	48d9                	li	a7,22
 ecall
 6ca:	00000073          	ecall
 ret
 6ce:	8082                	ret

00000000000006d0 <ps>:
.global ps
ps:
 li a7, SYS_ps
 6d0:	48dd                	li	a7,23
 ecall
 6d2:	00000073          	ecall
 ret
 6d6:	8082                	ret

00000000000006d8 <getschedhistory>:
.global getschedhistory
getschedhistory:
 li a7, SYS_getschedhistory
 6d8:	48e1                	li	a7,24
 ecall
 6da:	00000073          	ecall
 ret
 6de:	8082                	ret

00000000000006e0 <startMLFQ>:
.global startMLFQ
startMLFQ:
 li a7, SYS_startMLFQ
 6e0:	48e5                	li	a7,25
 ecall
 6e2:	00000073          	ecall
 ret
 6e6:	8082                	ret

00000000000006e8 <stopMLFQ>:
.global stopMLFQ
stopMLFQ:
 li a7, SYS_stopMLFQ
 6e8:	48e9                	li	a7,26
 ecall
 6ea:	00000073          	ecall
 ret
 6ee:	8082                	ret

00000000000006f0 <getMLFQInfo>:
.global getMLFQInfo
getMLFQInfo:
 li a7, SYS_getMLFQInfo
 6f0:	48ed                	li	a7,27
 ecall
 6f2:	00000073          	ecall
 ret
 6f6:	8082                	ret

00000000000006f8 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 6f8:	1101                	addi	sp,sp,-32
 6fa:	ec06                	sd	ra,24(sp)
 6fc:	e822                	sd	s0,16(sp)
 6fe:	1000                	addi	s0,sp,32
 700:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 704:	4605                	li	a2,1
 706:	fef40593          	addi	a1,s0,-17
 70a:	00000097          	auipc	ra,0x0
 70e:	f3e080e7          	jalr	-194(ra) # 648 <write>
}
 712:	60e2                	ld	ra,24(sp)
 714:	6442                	ld	s0,16(sp)
 716:	6105                	addi	sp,sp,32
 718:	8082                	ret

000000000000071a <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 71a:	7139                	addi	sp,sp,-64
 71c:	fc06                	sd	ra,56(sp)
 71e:	f822                	sd	s0,48(sp)
 720:	f426                	sd	s1,40(sp)
 722:	f04a                	sd	s2,32(sp)
 724:	ec4e                	sd	s3,24(sp)
 726:	0080                	addi	s0,sp,64
 728:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 72a:	c299                	beqz	a3,730 <printint+0x16>
 72c:	0805c863          	bltz	a1,7bc <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 730:	2581                	sext.w	a1,a1
  neg = 0;
 732:	4881                	li	a7,0
 734:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 738:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 73a:	2601                	sext.w	a2,a2
 73c:	00000517          	auipc	a0,0x0
 740:	6a450513          	addi	a0,a0,1700 # de0 <digits>
 744:	883a                	mv	a6,a4
 746:	2705                	addiw	a4,a4,1
 748:	02c5f7bb          	remuw	a5,a1,a2
 74c:	1782                	slli	a5,a5,0x20
 74e:	9381                	srli	a5,a5,0x20
 750:	97aa                	add	a5,a5,a0
 752:	0007c783          	lbu	a5,0(a5)
 756:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 75a:	0005879b          	sext.w	a5,a1
 75e:	02c5d5bb          	divuw	a1,a1,a2
 762:	0685                	addi	a3,a3,1
 764:	fec7f0e3          	bgeu	a5,a2,744 <printint+0x2a>
  if(neg)
 768:	00088b63          	beqz	a7,77e <printint+0x64>
    buf[i++] = '-';
 76c:	fd040793          	addi	a5,s0,-48
 770:	973e                	add	a4,a4,a5
 772:	02d00793          	li	a5,45
 776:	fef70823          	sb	a5,-16(a4)
 77a:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 77e:	02e05863          	blez	a4,7ae <printint+0x94>
 782:	fc040793          	addi	a5,s0,-64
 786:	00e78933          	add	s2,a5,a4
 78a:	fff78993          	addi	s3,a5,-1
 78e:	99ba                	add	s3,s3,a4
 790:	377d                	addiw	a4,a4,-1
 792:	1702                	slli	a4,a4,0x20
 794:	9301                	srli	a4,a4,0x20
 796:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 79a:	fff94583          	lbu	a1,-1(s2)
 79e:	8526                	mv	a0,s1
 7a0:	00000097          	auipc	ra,0x0
 7a4:	f58080e7          	jalr	-168(ra) # 6f8 <putc>
  while(--i >= 0)
 7a8:	197d                	addi	s2,s2,-1
 7aa:	ff3918e3          	bne	s2,s3,79a <printint+0x80>
}
 7ae:	70e2                	ld	ra,56(sp)
 7b0:	7442                	ld	s0,48(sp)
 7b2:	74a2                	ld	s1,40(sp)
 7b4:	7902                	ld	s2,32(sp)
 7b6:	69e2                	ld	s3,24(sp)
 7b8:	6121                	addi	sp,sp,64
 7ba:	8082                	ret
    x = -xx;
 7bc:	40b005bb          	negw	a1,a1
    neg = 1;
 7c0:	4885                	li	a7,1
    x = -xx;
 7c2:	bf8d                	j	734 <printint+0x1a>

00000000000007c4 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 7c4:	7119                	addi	sp,sp,-128
 7c6:	fc86                	sd	ra,120(sp)
 7c8:	f8a2                	sd	s0,112(sp)
 7ca:	f4a6                	sd	s1,104(sp)
 7cc:	f0ca                	sd	s2,96(sp)
 7ce:	ecce                	sd	s3,88(sp)
 7d0:	e8d2                	sd	s4,80(sp)
 7d2:	e4d6                	sd	s5,72(sp)
 7d4:	e0da                	sd	s6,64(sp)
 7d6:	fc5e                	sd	s7,56(sp)
 7d8:	f862                	sd	s8,48(sp)
 7da:	f466                	sd	s9,40(sp)
 7dc:	f06a                	sd	s10,32(sp)
 7de:	ec6e                	sd	s11,24(sp)
 7e0:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 7e2:	0005c903          	lbu	s2,0(a1)
 7e6:	18090f63          	beqz	s2,984 <vprintf+0x1c0>
 7ea:	8aaa                	mv	s5,a0
 7ec:	8b32                	mv	s6,a2
 7ee:	00158493          	addi	s1,a1,1
  state = 0;
 7f2:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 7f4:	02500a13          	li	s4,37
      if(c == 'd'){
 7f8:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 7fc:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 800:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 804:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 808:	00000b97          	auipc	s7,0x0
 80c:	5d8b8b93          	addi	s7,s7,1496 # de0 <digits>
 810:	a839                	j	82e <vprintf+0x6a>
        putc(fd, c);
 812:	85ca                	mv	a1,s2
 814:	8556                	mv	a0,s5
 816:	00000097          	auipc	ra,0x0
 81a:	ee2080e7          	jalr	-286(ra) # 6f8 <putc>
 81e:	a019                	j	824 <vprintf+0x60>
    } else if(state == '%'){
 820:	01498f63          	beq	s3,s4,83e <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 824:	0485                	addi	s1,s1,1
 826:	fff4c903          	lbu	s2,-1(s1)
 82a:	14090d63          	beqz	s2,984 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 82e:	0009079b          	sext.w	a5,s2
    if(state == 0){
 832:	fe0997e3          	bnez	s3,820 <vprintf+0x5c>
      if(c == '%'){
 836:	fd479ee3          	bne	a5,s4,812 <vprintf+0x4e>
        state = '%';
 83a:	89be                	mv	s3,a5
 83c:	b7e5                	j	824 <vprintf+0x60>
      if(c == 'd'){
 83e:	05878063          	beq	a5,s8,87e <vprintf+0xba>
      } else if(c == 'l') {
 842:	05978c63          	beq	a5,s9,89a <vprintf+0xd6>
      } else if(c == 'x') {
 846:	07a78863          	beq	a5,s10,8b6 <vprintf+0xf2>
      } else if(c == 'p') {
 84a:	09b78463          	beq	a5,s11,8d2 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 84e:	07300713          	li	a4,115
 852:	0ce78663          	beq	a5,a4,91e <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 856:	06300713          	li	a4,99
 85a:	0ee78e63          	beq	a5,a4,956 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 85e:	11478863          	beq	a5,s4,96e <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 862:	85d2                	mv	a1,s4
 864:	8556                	mv	a0,s5
 866:	00000097          	auipc	ra,0x0
 86a:	e92080e7          	jalr	-366(ra) # 6f8 <putc>
        putc(fd, c);
 86e:	85ca                	mv	a1,s2
 870:	8556                	mv	a0,s5
 872:	00000097          	auipc	ra,0x0
 876:	e86080e7          	jalr	-378(ra) # 6f8 <putc>
      }
      state = 0;
 87a:	4981                	li	s3,0
 87c:	b765                	j	824 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 87e:	008b0913          	addi	s2,s6,8
 882:	4685                	li	a3,1
 884:	4629                	li	a2,10
 886:	000b2583          	lw	a1,0(s6)
 88a:	8556                	mv	a0,s5
 88c:	00000097          	auipc	ra,0x0
 890:	e8e080e7          	jalr	-370(ra) # 71a <printint>
 894:	8b4a                	mv	s6,s2
      state = 0;
 896:	4981                	li	s3,0
 898:	b771                	j	824 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 89a:	008b0913          	addi	s2,s6,8
 89e:	4681                	li	a3,0
 8a0:	4629                	li	a2,10
 8a2:	000b2583          	lw	a1,0(s6)
 8a6:	8556                	mv	a0,s5
 8a8:	00000097          	auipc	ra,0x0
 8ac:	e72080e7          	jalr	-398(ra) # 71a <printint>
 8b0:	8b4a                	mv	s6,s2
      state = 0;
 8b2:	4981                	li	s3,0
 8b4:	bf85                	j	824 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 8b6:	008b0913          	addi	s2,s6,8
 8ba:	4681                	li	a3,0
 8bc:	4641                	li	a2,16
 8be:	000b2583          	lw	a1,0(s6)
 8c2:	8556                	mv	a0,s5
 8c4:	00000097          	auipc	ra,0x0
 8c8:	e56080e7          	jalr	-426(ra) # 71a <printint>
 8cc:	8b4a                	mv	s6,s2
      state = 0;
 8ce:	4981                	li	s3,0
 8d0:	bf91                	j	824 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 8d2:	008b0793          	addi	a5,s6,8
 8d6:	f8f43423          	sd	a5,-120(s0)
 8da:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 8de:	03000593          	li	a1,48
 8e2:	8556                	mv	a0,s5
 8e4:	00000097          	auipc	ra,0x0
 8e8:	e14080e7          	jalr	-492(ra) # 6f8 <putc>
  putc(fd, 'x');
 8ec:	85ea                	mv	a1,s10
 8ee:	8556                	mv	a0,s5
 8f0:	00000097          	auipc	ra,0x0
 8f4:	e08080e7          	jalr	-504(ra) # 6f8 <putc>
 8f8:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 8fa:	03c9d793          	srli	a5,s3,0x3c
 8fe:	97de                	add	a5,a5,s7
 900:	0007c583          	lbu	a1,0(a5)
 904:	8556                	mv	a0,s5
 906:	00000097          	auipc	ra,0x0
 90a:	df2080e7          	jalr	-526(ra) # 6f8 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 90e:	0992                	slli	s3,s3,0x4
 910:	397d                	addiw	s2,s2,-1
 912:	fe0914e3          	bnez	s2,8fa <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 916:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 91a:	4981                	li	s3,0
 91c:	b721                	j	824 <vprintf+0x60>
        s = va_arg(ap, char*);
 91e:	008b0993          	addi	s3,s6,8
 922:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 926:	02090163          	beqz	s2,948 <vprintf+0x184>
        while(*s != 0){
 92a:	00094583          	lbu	a1,0(s2)
 92e:	c9a1                	beqz	a1,97e <vprintf+0x1ba>
          putc(fd, *s);
 930:	8556                	mv	a0,s5
 932:	00000097          	auipc	ra,0x0
 936:	dc6080e7          	jalr	-570(ra) # 6f8 <putc>
          s++;
 93a:	0905                	addi	s2,s2,1
        while(*s != 0){
 93c:	00094583          	lbu	a1,0(s2)
 940:	f9e5                	bnez	a1,930 <vprintf+0x16c>
        s = va_arg(ap, char*);
 942:	8b4e                	mv	s6,s3
      state = 0;
 944:	4981                	li	s3,0
 946:	bdf9                	j	824 <vprintf+0x60>
          s = "(null)";
 948:	00000917          	auipc	s2,0x0
 94c:	49090913          	addi	s2,s2,1168 # dd8 <malloc+0x34a>
        while(*s != 0){
 950:	02800593          	li	a1,40
 954:	bff1                	j	930 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 956:	008b0913          	addi	s2,s6,8
 95a:	000b4583          	lbu	a1,0(s6)
 95e:	8556                	mv	a0,s5
 960:	00000097          	auipc	ra,0x0
 964:	d98080e7          	jalr	-616(ra) # 6f8 <putc>
 968:	8b4a                	mv	s6,s2
      state = 0;
 96a:	4981                	li	s3,0
 96c:	bd65                	j	824 <vprintf+0x60>
        putc(fd, c);
 96e:	85d2                	mv	a1,s4
 970:	8556                	mv	a0,s5
 972:	00000097          	auipc	ra,0x0
 976:	d86080e7          	jalr	-634(ra) # 6f8 <putc>
      state = 0;
 97a:	4981                	li	s3,0
 97c:	b565                	j	824 <vprintf+0x60>
        s = va_arg(ap, char*);
 97e:	8b4e                	mv	s6,s3
      state = 0;
 980:	4981                	li	s3,0
 982:	b54d                	j	824 <vprintf+0x60>
    }
  }
}
 984:	70e6                	ld	ra,120(sp)
 986:	7446                	ld	s0,112(sp)
 988:	74a6                	ld	s1,104(sp)
 98a:	7906                	ld	s2,96(sp)
 98c:	69e6                	ld	s3,88(sp)
 98e:	6a46                	ld	s4,80(sp)
 990:	6aa6                	ld	s5,72(sp)
 992:	6b06                	ld	s6,64(sp)
 994:	7be2                	ld	s7,56(sp)
 996:	7c42                	ld	s8,48(sp)
 998:	7ca2                	ld	s9,40(sp)
 99a:	7d02                	ld	s10,32(sp)
 99c:	6de2                	ld	s11,24(sp)
 99e:	6109                	addi	sp,sp,128
 9a0:	8082                	ret

00000000000009a2 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 9a2:	715d                	addi	sp,sp,-80
 9a4:	ec06                	sd	ra,24(sp)
 9a6:	e822                	sd	s0,16(sp)
 9a8:	1000                	addi	s0,sp,32
 9aa:	e010                	sd	a2,0(s0)
 9ac:	e414                	sd	a3,8(s0)
 9ae:	e818                	sd	a4,16(s0)
 9b0:	ec1c                	sd	a5,24(s0)
 9b2:	03043023          	sd	a6,32(s0)
 9b6:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 9ba:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 9be:	8622                	mv	a2,s0
 9c0:	00000097          	auipc	ra,0x0
 9c4:	e04080e7          	jalr	-508(ra) # 7c4 <vprintf>
}
 9c8:	60e2                	ld	ra,24(sp)
 9ca:	6442                	ld	s0,16(sp)
 9cc:	6161                	addi	sp,sp,80
 9ce:	8082                	ret

00000000000009d0 <printf>:

void
printf(const char *fmt, ...)
{
 9d0:	711d                	addi	sp,sp,-96
 9d2:	ec06                	sd	ra,24(sp)
 9d4:	e822                	sd	s0,16(sp)
 9d6:	1000                	addi	s0,sp,32
 9d8:	e40c                	sd	a1,8(s0)
 9da:	e810                	sd	a2,16(s0)
 9dc:	ec14                	sd	a3,24(s0)
 9de:	f018                	sd	a4,32(s0)
 9e0:	f41c                	sd	a5,40(s0)
 9e2:	03043823          	sd	a6,48(s0)
 9e6:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 9ea:	00840613          	addi	a2,s0,8
 9ee:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 9f2:	85aa                	mv	a1,a0
 9f4:	4505                	li	a0,1
 9f6:	00000097          	auipc	ra,0x0
 9fa:	dce080e7          	jalr	-562(ra) # 7c4 <vprintf>
}
 9fe:	60e2                	ld	ra,24(sp)
 a00:	6442                	ld	s0,16(sp)
 a02:	6125                	addi	sp,sp,96
 a04:	8082                	ret

0000000000000a06 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 a06:	1141                	addi	sp,sp,-16
 a08:	e422                	sd	s0,8(sp)
 a0a:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 a0c:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 a10:	00000797          	auipc	a5,0x0
 a14:	3e87b783          	ld	a5,1000(a5) # df8 <freep>
 a18:	a805                	j	a48 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 a1a:	4618                	lw	a4,8(a2)
 a1c:	9db9                	addw	a1,a1,a4
 a1e:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 a22:	6398                	ld	a4,0(a5)
 a24:	6318                	ld	a4,0(a4)
 a26:	fee53823          	sd	a4,-16(a0)
 a2a:	a091                	j	a6e <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 a2c:	ff852703          	lw	a4,-8(a0)
 a30:	9e39                	addw	a2,a2,a4
 a32:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 a34:	ff053703          	ld	a4,-16(a0)
 a38:	e398                	sd	a4,0(a5)
 a3a:	a099                	j	a80 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 a3c:	6398                	ld	a4,0(a5)
 a3e:	00e7e463          	bltu	a5,a4,a46 <free+0x40>
 a42:	00e6ea63          	bltu	a3,a4,a56 <free+0x50>
{
 a46:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 a48:	fed7fae3          	bgeu	a5,a3,a3c <free+0x36>
 a4c:	6398                	ld	a4,0(a5)
 a4e:	00e6e463          	bltu	a3,a4,a56 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 a52:	fee7eae3          	bltu	a5,a4,a46 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 a56:	ff852583          	lw	a1,-8(a0)
 a5a:	6390                	ld	a2,0(a5)
 a5c:	02059713          	slli	a4,a1,0x20
 a60:	9301                	srli	a4,a4,0x20
 a62:	0712                	slli	a4,a4,0x4
 a64:	9736                	add	a4,a4,a3
 a66:	fae60ae3          	beq	a2,a4,a1a <free+0x14>
    bp->s.ptr = p->s.ptr;
 a6a:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 a6e:	4790                	lw	a2,8(a5)
 a70:	02061713          	slli	a4,a2,0x20
 a74:	9301                	srli	a4,a4,0x20
 a76:	0712                	slli	a4,a4,0x4
 a78:	973e                	add	a4,a4,a5
 a7a:	fae689e3          	beq	a3,a4,a2c <free+0x26>
  } else
    p->s.ptr = bp;
 a7e:	e394                	sd	a3,0(a5)
  freep = p;
 a80:	00000717          	auipc	a4,0x0
 a84:	36f73c23          	sd	a5,888(a4) # df8 <freep>
}
 a88:	6422                	ld	s0,8(sp)
 a8a:	0141                	addi	sp,sp,16
 a8c:	8082                	ret

0000000000000a8e <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 a8e:	7139                	addi	sp,sp,-64
 a90:	fc06                	sd	ra,56(sp)
 a92:	f822                	sd	s0,48(sp)
 a94:	f426                	sd	s1,40(sp)
 a96:	f04a                	sd	s2,32(sp)
 a98:	ec4e                	sd	s3,24(sp)
 a9a:	e852                	sd	s4,16(sp)
 a9c:	e456                	sd	s5,8(sp)
 a9e:	e05a                	sd	s6,0(sp)
 aa0:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 aa2:	02051493          	slli	s1,a0,0x20
 aa6:	9081                	srli	s1,s1,0x20
 aa8:	04bd                	addi	s1,s1,15
 aaa:	8091                	srli	s1,s1,0x4
 aac:	0014899b          	addiw	s3,s1,1
 ab0:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 ab2:	00000517          	auipc	a0,0x0
 ab6:	34653503          	ld	a0,838(a0) # df8 <freep>
 aba:	c515                	beqz	a0,ae6 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 abc:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 abe:	4798                	lw	a4,8(a5)
 ac0:	02977f63          	bgeu	a4,s1,afe <malloc+0x70>
 ac4:	8a4e                	mv	s4,s3
 ac6:	0009871b          	sext.w	a4,s3
 aca:	6685                	lui	a3,0x1
 acc:	00d77363          	bgeu	a4,a3,ad2 <malloc+0x44>
 ad0:	6a05                	lui	s4,0x1
 ad2:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 ad6:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 ada:	00000917          	auipc	s2,0x0
 ade:	31e90913          	addi	s2,s2,798 # df8 <freep>
  if(p == (char*)-1)
 ae2:	5afd                	li	s5,-1
 ae4:	a88d                	j	b56 <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 ae6:	00000797          	auipc	a5,0x0
 aea:	31a78793          	addi	a5,a5,794 # e00 <base>
 aee:	00000717          	auipc	a4,0x0
 af2:	30f73523          	sd	a5,778(a4) # df8 <freep>
 af6:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 af8:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 afc:	b7e1                	j	ac4 <malloc+0x36>
      if(p->s.size == nunits)
 afe:	02e48b63          	beq	s1,a4,b34 <malloc+0xa6>
        p->s.size -= nunits;
 b02:	4137073b          	subw	a4,a4,s3
 b06:	c798                	sw	a4,8(a5)
        p += p->s.size;
 b08:	1702                	slli	a4,a4,0x20
 b0a:	9301                	srli	a4,a4,0x20
 b0c:	0712                	slli	a4,a4,0x4
 b0e:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 b10:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 b14:	00000717          	auipc	a4,0x0
 b18:	2ea73223          	sd	a0,740(a4) # df8 <freep>
      return (void*)(p + 1);
 b1c:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 b20:	70e2                	ld	ra,56(sp)
 b22:	7442                	ld	s0,48(sp)
 b24:	74a2                	ld	s1,40(sp)
 b26:	7902                	ld	s2,32(sp)
 b28:	69e2                	ld	s3,24(sp)
 b2a:	6a42                	ld	s4,16(sp)
 b2c:	6aa2                	ld	s5,8(sp)
 b2e:	6b02                	ld	s6,0(sp)
 b30:	6121                	addi	sp,sp,64
 b32:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 b34:	6398                	ld	a4,0(a5)
 b36:	e118                	sd	a4,0(a0)
 b38:	bff1                	j	b14 <malloc+0x86>
  hp->s.size = nu;
 b3a:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 b3e:	0541                	addi	a0,a0,16
 b40:	00000097          	auipc	ra,0x0
 b44:	ec6080e7          	jalr	-314(ra) # a06 <free>
  return freep;
 b48:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 b4c:	d971                	beqz	a0,b20 <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 b4e:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 b50:	4798                	lw	a4,8(a5)
 b52:	fa9776e3          	bgeu	a4,s1,afe <malloc+0x70>
    if(p == freep)
 b56:	00093703          	ld	a4,0(s2)
 b5a:	853e                	mv	a0,a5
 b5c:	fef719e3          	bne	a4,a5,b4e <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 b60:	8552                	mv	a0,s4
 b62:	00000097          	auipc	ra,0x0
 b66:	b4e080e7          	jalr	-1202(ra) # 6b0 <sbrk>
  if(p == (char*)-1)
 b6a:	fd5518e3          	bne	a0,s5,b3a <malloc+0xac>
        return 0;
 b6e:	4501                	li	a0,0
 b70:	bf45                	j	b20 <malloc+0x92>
