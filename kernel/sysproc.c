#include "types.h"
#include "riscv.h"
#include "defs.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "proc.h"
#include "syscall.h"
// #include "../user/user.h"
uint64
sys_exit(void)
{
  int n;
  argint(0, &n);
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
  argaddr(0, &p);
  return wait(p);
}

uint64
sys_sbrk(void)
{
  uint64 addr;
  int n;

  argint(0, &n);
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

  argint(0, &n);
  acquire(&tickslock);
  ticks0 = ticks;
  while(ticks - ticks0 < n){
    if(killed(myproc())){
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

  argint(0, &pid);
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
sys_trace(void)
{
  int n;
  // if (argint(0, &n) < 0)
  //   return -1;

  argint(0, &n);

  myproc()->trace_mask = n;
  return 0;
}

uint64
sys_sigalarm(void)
{
  uint64 fh;
  int ticks;
  // printf("lol\n");
  argint(0,&ticks);
  if(ticks < 0)
    return -1;
  argaddr(1,&fh);
  if(fh < 0)
    return -1;
  printf("%d",ticks);
  struct proc *p = myproc();
  p->max_ticks = ticks;
  p->handler = fh;
  p->trapframe->a0=myproc()->orig_a0;
  return 0;
}

uint64
sys_sigreturn(void)
{
  struct proc *p = myproc();
  memmove(p->trapframe,p->lastsaved,PGSIZE);
  kfree(p->lastsaved);
  p->lastsaved=0;
  p->curr_ticks=0;
  p->alarm_flag=0;
  // p->trapframe->a0=0xac;
  // printf("lol\n");
  return p->trapframe->a0;
}

uint64
sys_settickets(void)
{
  int n;
  argint(0,&n);
  if((n)<0)
    return -1;
  struct proc *p= myproc();
  p->tickets=n;
  return 0;
}

uint64
sys_set_priority(void)
{
  int priority,pid;
  argint(0,&priority);
  argint(1,&pid);
  if(priority<0 || pid<0)
    return -1;
  return set_spriority(priority,pid);
}

uint64
sys_waitx(void)
{
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
  argaddr(1, &addr1); // user virtual memory
  argaddr(2, &addr2);
  int ret = waitx(addr, &wtime, &rtime);
  struct proc* p = myproc();
  if (copyout(p->pagetable, addr1,(char*)&wtime, sizeof(int)) < 0)
    return -1;
  if (copyout(p->pagetable, addr2,(char*)&rtime, sizeof(int)) < 0)
    return -1;
  return ret;
}