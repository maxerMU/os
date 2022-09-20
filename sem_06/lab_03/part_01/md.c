#include <linux/init_task.h>
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/sched.h>

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Mitsevich Maxim");

static int __init md_init(void) {
    struct task_struct *task = &init_task;

    do
    {
      printk(KERN_INFO "oslabmodule %s-%d prio: %d state: %ld, %s-%d\n",
          task->comm, task->pid,
          task->prio, task->state,
          task->parent->comm, task->parent->pid
        );

    } while ((task = next_task(task)) != &init_task);

    printk(KERN_INFO "oslabmodule init: %s-%d prio: %d state: %ld", current->comm, current->pid, current->prio, current->state);

    return 0;
}

static void __exit md_exit(void) 
{ 
	printk(KERN_INFO "oslabmodule exit: %s-%d", current->comm, current->pid);
	printk("oslabmodule Good bye!\n"); 
}

module_init(md_init);
module_exit(md_exit);
