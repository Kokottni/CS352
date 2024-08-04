#include "types.h"
#include "riscv.h"
#include "defs.h"
#include "date.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "proc.h"


uint64
sys_exit(void)
{
  int n;
  if(argint(0, &n) < 0)
    return -1;
  exit(n);
  return 0;  // not reached
}

uint64
sys_getpid(void)
{
  return myproc()->pid;
}

uint64
sys_fork(void)
{
  return fork();
}

uint64
sys_wait(void)
{
  uint64 p;
  if(argaddr(0, &p) < 0)
    return -1;
  return wait(p);
}

uint64
sys_sbrk(void)
{
  int addr;
  int n;

  if(argint(0, &n) < 0)
    return -1;
  addr = myproc()->sz;
  if(growproc(n) < 0)
    return -1;
  return addr;
}

uint64
sys_sleep(void)
{
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    return -1;
  acquire(&tickslock);
  ticks0 = ticks;
  while(ticks - ticks0 < n){
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
  return 0;
}

uint64
sys_kill(void)
{
  int pid;

  if(argint(0, &pid) < 0)
    return -1;
  return kill(pid);
}

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
  uint xticks;

  acquire(&tickslock);
  xticks = ticks;
  release(&tickslock);
  return xticks;
}

uint64
sys_getppid(void){
  //gets ppid in one line 
  return myproc()->parent->pid;
}

extern struct proc proc[NPROC];
uint64
sys_ps(void){
  //This is the ps_struct that will hold all the info
  struct ps_struct{
    int pid;
    int ppid;
    char state[10];
    char name[16];
  } ps[NPROC];
  
  //counter
  int i;
  //number of processes running
  int numProc = 0;
  //give the correct number of iterations to put into ps array
  int numElements = sizeof(proc)/sizeof(proc[0]);
  //loop through
  for(i = 0; i < numElements; ++i){
    //check if process is actually being used
    if(proc[i].state != UNUSED){
      //get pid
      ps[numProc].pid = proc[i].pid;
      //check if it has a parent
      if(proc[i].name[0] == 'i'){
        ps[numProc].ppid = 0;
      }else{
        ps[numProc].ppid = proc[i].parent->pid;
      }
      //use a switch to get the state assigned properly without string.h
      switch(proc[i].state){
        case UNUSED:
          break;
        case USED:
          ps[numProc].state[0] = 'U';
          ps[numProc].state[1] = 'S';
          ps[numProc].state[2] = 'E';
          ps[numProc].state[3] = 'D';
          ps[numProc].state[4] = '\0';
          break;
        case SLEEPING:
          ps[numProc].state[0] = 'S';
          ps[numProc].state[1] = 'L';
          ps[numProc].state[2] = 'E';
          ps[numProc].state[3] = 'E';
          ps[numProc].state[4] = 'P';
          ps[numProc].state[5] = 'I';
          ps[numProc].state[6] = 'N';
          ps[numProc].state[7] = 'G';
          ps[numProc].state[8] = '\0';
          break;
        case RUNNABLE:
          ps[numProc].state[0] = 'R';
          ps[numProc].state[1] = 'U';
          ps[numProc].state[2] = 'N';
          ps[numProc].state[3] = 'N';
          ps[numProc].state[4] = 'A';
          ps[numProc].state[5] = 'B';
          ps[numProc].state[6] = 'L';
          ps[numProc].state[7] = 'E';
          ps[numProc].state[8] = '\0';
          break;
        case RUNNING:
          ps[numProc].state[0] = 'R';
          ps[numProc].state[1] = 'U';
          ps[numProc].state[2] = 'N';
          ps[numProc].state[3] = 'N';
          ps[numProc].state[4] = 'I';
          ps[numProc].state[5] = 'N';
          ps[numProc].state[6] = 'G';
          ps[numProc].state[7] = '\0';
          break;
        case ZOMBIE:
          ps[numProc].state[0] = 'Z';
          ps[numProc].state[1] = 'O';
          ps[numProc].state[2] = 'M';
          ps[numProc].state[3] = 'B';
          ps[numProc].state[4] = 'I';
          ps[numProc].state[5] = 'E';
          ps[numProc].state[6] = '\0';
          break;
      }
      //Now assign name over seeing as string.h wouldnt work for me
      ps[numProc].name[0] = proc[i].name[0];
      ps[numProc].name[1] = proc[i].name[1];
      ps[numProc].name[2] = proc[i].name[2];
      ps[numProc].name[3] = proc[i].name[3];
      ps[numProc].name[4] = proc[i].name[4];
      ps[numProc].name[5] = proc[i].name[5];
      ps[numProc].name[6] = proc[i].name[6];
      ps[numProc].name[7] = proc[i].name[7];
      ps[numProc].name[8] = proc[i].name[8];
      ps[numProc].name[9] = proc[i].name[9];
      ps[numProc].name[10] = proc[i].name[10];
      ps[numProc].name[11] = proc[i].name[11];
      ps[numProc].name[12] = proc[i].name[12];
      ps[numProc].name[13] = proc[i].name[13];
      ps[numProc].name[14] = proc[i].name[14];
      ps[numProc].name[15] = proc[i].name[15];
      //increments numProc so a new process can be stored in ps
      ++numProc;
    }
  }
  
  //save address of user space argument to arg_addr
  uint64 arg_addr;
  argaddr(0, &arg_addr);
  
  //copy array to saved address
  if(copyout(myproc()->pagetable,arg_addr,(char*)ps,numProc*sizeof(struct ps_struct)) < 0){
    return -1;
  }
  
  //return numProc
  return numProc;
}

//implement getschedhistory
uint64
sys_getschedhistory(void){
  //struct for history
  struct sched_history{
    int runCount;
    int systemcallCount;
    int interruptCount;
    int preemptCount;
    int trapCount;
    int sleepCount;
  } my_history;
  
  //get current process and insert the history
  struct proc *curr = myproc();
  my_history.runCount = curr->runCount;
  my_history.systemcallCount = curr->systemcallCount;
  my_history.interruptCount = curr->interruptCount;
  my_history.preemptCount = curr->preemptCount;
  my_history.trapCount = curr->trapCount;
  my_history.sleepCount = curr->sleepCount;
  
  
  //save addy of user space arguemtn to arg_addr
  uint64 arg_addr;
  argaddr(0, &arg_addr);
  
  //copy my_history to saved address
  if(copyout(curr->pagetable,arg_addr,(char*)&my_history,sizeof(struct sched_history)) < 0){
    return -1;
  }
  
  return curr->pid;
}

//added startMLFQ system call
uint64
sys_startMLFQ(void){
	int m, n;
	argint(0, &m);
	argint(1, &n);
	mlfq.flag = 1;
	mlfq.levels = m;
	mlfq.tickTime = n;
	return 0;
}

//added stopMLFQ system call
uint64
sys_stopMLFQ(void){
	mlfq.flag = 0;
	return 0;
}

//added getMLFQInfo system call
uint64
sys_getMLFQInfo(void){
  
  uint64 arg_addr;
  argaddr(0, &arg_addr);
  struct proc *curr = myproc();
  int i;
  for(i = 0; i < 10; ++i){
     mlfq.tickCounts[i] = curr->report.tickCounts[i];
     //printf("%d", myInfo.tickCounts[i]);
  }
  //save addy of user space arguemtn to arg_addr
  
  
  //copy my_history to saved address
  if(copyout(curr->pagetable,arg_addr,(char *)&mlfq.tickCounts,40) < 0){
    return -1;
  }
	
  return 0;
}
