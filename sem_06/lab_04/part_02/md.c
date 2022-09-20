#include <linux/module.h>
#include <linux/moduleparam.h>
#include <linux/init.h>
#include <linux/kernel.h>
#include <linux/proc_fs.h>
#include <linux/vmalloc.h>
#include <linux/uaccess.h>

#define BUFSIZE 100
#define MAX_COOKIE_LENGTH PAGE_SIZE

MODULE_LICENSE("GPL");
MODULE_AUTHOR( "Mitsevich Maxim");

static struct proc_dir_entry *proc_entry;
static struct proc_dir_entry *proc_link;
static struct proc_dir_entry *proc_dir;
static char *cookie_pot = NULL;
int cookie_index;
int next_fortune;

static ssize_t fortune_write(struct file *file, const char __user *ubuf, size_t count, loff_t *ppos)
{
    printk(KERN_INFO "fortune: called write\n");
    int free_space = (MAX_COOKIE_LENGTH - next_fortune) + 1;

    if (count > free_space)
    {
        printk(KERN_INFO "Cookie pot full.\n");
        return -ENOSPC;
    }

    if (copy_from_user(&cookie_pot[cookie_index], ubuf, count))
    {
        return -EFAULT;
    }

    cookie_index += count;
    cookie_pot[cookie_index - 1] = 0;

    return count;
}

static ssize_t fortune_read(struct file *file, char __user *ubuf, size_t count, loff_t *ppos)
{
    printk(KERN_INFO "fortune: called read\n");
    printk(KERN_INFO "count: %zu", count);
    printk(KERN_INFO "next_fortune: %d", next_fortune);
    printk(KERN_INFO "cookie index: %d", cookie_index);
    int len;
    char buf[256];

    if (cookie_index == 0 || *ppos > 0)
    {
        return 0;
    }

    if (next_fortune >= cookie_index)
    {
        next_fortune = 0;
    }

    len = sprintf(buf, "%s\n", &cookie_pot[next_fortune]);
    copy_to_user(ubuf, buf, len);
    printk(KERN_INFO "len: %d", len);
    next_fortune += len;
    *ppos += len;

    return len;
}


int fortune_open(struct inode *inode, struct file *file)
{
    printk(KERN_INFO "fortune: called open\n");
    return 0;
}

int fortune_release(struct inode *inode, struct file *file)
{
    printk(KERN_INFO "fortune: called release\n");
    return 0;
}

static struct proc_ops myops =
{
    .proc_read = fortune_read,
    .proc_write = fortune_write,
    .proc_open = fortune_open,
    .proc_release = fortune_release
};

static int __init fortune_init(void)
{
    cookie_pot = (char *)vmalloc(MAX_COOKIE_LENGTH);
    if (!cookie_pot)
    {
        printk(KERN_INFO "Not enough memory for the cookie pot.\n");
        return -ENOMEM;
    }

    memset( cookie_pot, 0, MAX_COOKIE_LENGTH );

    proc_entry = proc_create("fortune", 0666, NULL, &myops);
    proc_dir = proc_mkdir("mydir", NULL);

    if (proc_entry == NULL)
    {
        vfree(cookie_pot);
        printk(KERN_INFO "fortune: Couldn't create proc entry\n");
        return -ENOMEM;
    }

    proc_link = proc_symlink("link", NULL, "fortune");

    cookie_index = 0;
    next_fortune = 0;

    printk(KERN_INFO "fortune: Module inited.\n");

    return 0;
}

static void __exit fortune_exit(void)
{
    remove_proc_entry("fortune", NULL);
    remove_proc_entry("mydir", NULL);
    remove_proc_entry("link", NULL);

    if (cookie_pot)
        vfree(cookie_pot);

    printk(KERN_INFO "fortune: Module exited.\n");
}

module_init(fortune_init);
module_exit(fortune_exit);
