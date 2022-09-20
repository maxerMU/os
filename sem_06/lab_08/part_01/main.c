#include <asm/io.h>
#include <linux/interrupt.h>
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/proc_fs.h>
#include <linux/seq_file.h>
#include <linux/slab.h>

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Mitsevich Maxim");

#define IRQ 1
static int my_dev_id;

char *my_taskletdata = "my_tasklet_function was called";
struct tasklet_struct *my_tasklet;

void my_tasklet_function(unsigned long data ) {
	printk(KERN_DEBUG "[TASKLET]: state: %ld, count: %d, data: %s",
					 my_tasklet->state, my_tasklet->count, my_tasklet->data);
    return;
}

irqreturn_t my_handler(int irq, void *dev)
{
    if (irq == IRQ)
    {
        printk("[TASKLET]: my_handler called");
		printk("[TASKLET]: state before planning: %lu\n", my_tasklet->state);
        tasklet_schedule(my_tasklet);
        printk("[TASKLET]: state after planning: %lu\n", my_tasklet->state);
        return IRQ_HANDLED;
    }
    return IRQ_NONE;
}

static int __init my_tasklet_init(void)
{
    my_tasklet = kmalloc(sizeof(struct tasklet_struct), GFP_KERNEL);

    if (!my_tasklet)
    {
        printk(KERN_ERR "[TASKLET]: kmalloc error!");
        return -1;
    }
    tasklet_init(my_tasklet, my_tasklet_function, (unsigned long)my_taskletdata);

    int ret = request_irq(IRQ,
                            my_handler,
                            IRQF_SHARED,
							"my_irq_handler",
							&my_dev_id);
	
    if (ret)
    {
        printk(KERN_ERR "[TASKLET]: cannot register my_handler\n");
    }
    else
    {
	    printk(KERN_DEBUG "[MODULE]: module is now loaded.\n");
    }
    return ret;
}

static void __exit my_tasklet_exit(void)
{
    synchronize_irq(IRQ);
    tasklet_kill(my_tasklet);
	
    kfree(my_tasklet);
    free_irq(IRQ, &my_dev_id);

    printk(KERN_DEBUG "[MODULE]: module is now unloaded.\n");
}

module_init(my_tasklet_init) 
module_exit(my_tasklet_exit)

