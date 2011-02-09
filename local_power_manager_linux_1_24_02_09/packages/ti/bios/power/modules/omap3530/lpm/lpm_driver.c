/* 
 *  Copyright 2010 by Texas Instruments Incorporated.
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; version 2 of the License.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>
 * 
 */

/*
 *  ======== lpm_driver.c ========
 *
 */


#include <linux/version.h>
#include <linux/module.h>
#include <linux/init.h>
#include <linux/moduleparam.h>
#if LINUX_VERSION_CODE <= KERNEL_VERSION(2,6,10)
// #include <linux/config.h> // removed in 2.6.22
#endif
#include <linux/device.h>
#include <linux/fs.h>
#include <linux/slab.h>
#include <linux/kernel.h>
#include <linux/cdev.h>
#include <linux/list.h>
#include <linux/completion.h>
#if LINUX_VERSION_CODE >= KERNEL_VERSION(2,6,26)
#include <linux/semaphore.h>
#else
#include <asm/semaphore.h>
#endif
#include <linux/io.h>

#include "lpm_driver.h"
#include "lpm_dev.h"


#define LPM_DEV_NAME    "/dev/lpm"
#define LPM_DEV_COUNT   1               /* this should be a config param */
#define REG(x)          *((volatile unsigned int *) (x))


/*
 * The following macros control version-dependent code:
 * USE_CLASS_SIMPLE - #define if Linux version contains class_simple,
 * otherwise class is used (Linux supports one or the other, not both)
 */
#if LINUX_VERSION_CODE >= KERNEL_VERSION(2,6,26)

#undef USE_CLASS_DEVICE
#undef USE_CLASS_SIMPLE

#elif LINUX_VERSION_CODE >= KERNEL_VERSION(2,6,18)

#define USE_CLASS_DEVICE
#undef USE_CLASS_SIMPLE

#else  /* LINUX_VERSION_CODE < KERNEL_VERSION(2,6,18) */

#undef USE_CLASS_DEVICE
#define USE_CLASS_SIMPLE

#endif


/*
 * Debug macro: trace is set with insmod parameter.
 *
 * insmod lpm.ko trace=1
 *
 */
#if defined(DEBUG)
#define TRACE if (trace) printk
#else
#define TRACE(...)
#endif



/* Module parameters */
static uint trace = 0;
module_param(trace, bool, S_IRUGO);

static int enablevicp = -1;
module_param(enablevicp, int, S_IRUGO);

/* forward declaration of system calls (used by Linux driver) */
static int lpm_ioctl    (struct file *filp,
                         unsigned int cmd, unsigned long args);
static int lpm_open     (struct inode *inode, struct file *filp);
static int lpm_release  (struct inode *inode, struct file *filp);

/* operating system wrapper functions (used by LPM) */
static LPM_Status lpm_os_remap  (unsigned long pa,
                                 unsigned long size, unsigned long *va);
static LPM_Status lpm_os_signal (void *data);
static LPM_Status lpm_os_unmap  (void *va);
static LPM_Status lpm_os_wait   (void *data);
static void       lpm_os_trace  (char *fmt, ...);


static struct file_operations lpm_fops = {
    .owner =    THIS_MODULE,
    .unlocked_ioctl =    lpm_ioctl,
    .open =     lpm_open,
    .release =  lpm_release,
};


typedef struct LPM_Client {
    unsigned int        state;
    struct list_head    entry;
    int                 on_ref_count;
} LPM_Client;

typedef struct LPM_Instance {       /* instance for each resource (i.e. DSP) */
    char               *name;       /* device file name                      */
    int                 major;      /* device major number                   */
    int                 minor;      /* device minor number                   */
    struct list_head    clients;    /* list of clients on this device        */
    struct semaphore    sem;
    struct completion   event;
    LPM_Device          lpm;        /* LPM object which controls the device  */
} LPM_Instance;


typedef struct LPM_Dev {
    char                *name;
    dev_t               first;
    int                 minor;
    struct cdev         cdev;
    LPM_Instance        inst[LPM_DEV_COUNT];
#ifdef USE_UDEV
#ifdef USE_CLASS_SIMPLE
    struct class_simple *lpm_class;
#else
    struct class        *lpm_class;
#endif
#endif  /* USE_UDEV */
} LPM_Dev;

static char *nameAry[2] = {
    "/dev/lpm0",
    "/dev/lpm1",
};

static LPM_Dev LPM_OBJ = {              /* static global device object  */
    .name       = LPM_DEV_NAME,
    .minor      = 0,
};


/* global reference counter for on/off */
static int lpm_on_ref_count = 0;


/*
 *  ======== lpm_exit ========
 */
static void __exit lpm_exit(void)
{
    LPM_Dev    *lpm = &LPM_OBJ;
    int         i;


    TRACE(KERN_ALERT "--> lpm_exit\n");

    for (i = 0; i < LPM_DEV_COUNT; i++) {
        LPM_exit(lpm->inst[i].lpm.instance);
    }

#ifdef USE_UDEV

    /* remove udev support */
    for (i = 0; i < LPM_DEV_COUNT; i++) {
#if defined(USE_CLASS_SIMPLE)
        class_simple_device_remove(
            MKDEV(lpm->inst[i].major, lpm->inst[i].minor));
#elif defined(USE_CLASS_DEVICE)
        class_device_destroy(lpm->lpm_class,
            MKDEV(lpm->inst[i].major, lpm->inst[i].minor));
#else
        device_destroy(lpm->lpm_class,
            MKDEV(lpm->inst[i].major, lpm->inst[i].minor));
#endif
    }

#ifdef USE_CLASS_SIMPLE
    class_simple_destroy(lpm->lpm_class);
#else
    class_destroy(lpm->lpm_class);
#endif

#endif  /* USE_UDEV */

    /* remove the device from the kernel */
    cdev_del(&lpm->cdev);

    /* free device numbers */
    unregister_chrdev_region(lpm->first, LPM_DEV_COUNT);

    TRACE(KERN_ALERT "<-- lpm_exit\n");
}


/*
 *  ======== lpm_init ========
 */
static int __init lpm_init(void)
{
    LPM_Dev            *lpm = &LPM_OBJ;
    int                 i, err;
    LPM_DevAttrs        lpm_devAttrs = {
                            .os_remap = lpm_os_remap,
                            .os_signal = lpm_os_signal,
                            .os_unmap = lpm_os_unmap,
                            .os_wait = lpm_os_wait,
                            .os_trace = lpm_os_trace,
                        };

    TRACE(KERN_ALERT "--> lpm_init\n");

    /* allocate device numbers from the kernel */
    err = alloc_chrdev_region(&lpm->first, 0, LPM_DEV_COUNT, LPM_DEV_NAME);

    if (err) {
        TRACE(KERN_ALERT "Error: alloc_chrdev_region failed\n");
        goto fail_01;
    }

    /* initialize the instance array */
    for (i = 0; i < LPM_DEV_COUNT; i++) {
        lpm->inst[i].name = nameAry[i];
        lpm->inst[i].major = MAJOR(lpm->first);
        lpm->inst[i].minor = MINOR(lpm->first) + i;
        INIT_LIST_HEAD(&lpm->inst[i].clients);
        init_MUTEX(&lpm->inst[i].sem);
        init_completion(&lpm->inst[i].event);
        lpm_devAttrs.os_instance = (void *)&lpm->inst[i];
        LPM_init(i, &lpm->inst[i].lpm, &lpm_devAttrs);
        /* TODO: check return status of LPM_init */
    }

    /* initialize the device structure */
    cdev_init(&lpm->cdev, &lpm_fops);
    lpm->cdev.owner = THIS_MODULE;
    lpm->cdev.ops = &lpm_fops;

    /* register the device with the kernel */
    err = cdev_add(&lpm->cdev, lpm->first, LPM_DEV_COUNT);

    if (err) {
        TRACE(KERN_ALERT "Error: cdev_add failed\n");
        goto fail_01;
    }

#ifdef USE_UDEV

    /* add udev support */
#ifdef USE_CLASS_SIMPLE
    lpm->lpm_class = class_simple_create(THIS_MODULE, "ti");
#else
    lpm->lpm_class = class_create(THIS_MODULE, "ti");
#endif

    if (IS_ERR(lpm->lpm_class)) {
        TRACE(KERN_ALERT "Error: creating device class failed\n");
        goto fail_02;
    }

    for (i = 0; i < LPM_DEV_COUNT; i++) {
#if defined(USE_CLASS_SIMPLE)
        class_simple_device_add(lpm->lpm_class,
            MKDEV(lpm->inst[i].major, lpm->inst[i].minor),
            NULL, "lpm%d", lpm->inst[i].minor);
#elif defined(USE_CLASS_DEVICE)
        class_device_create(lpm->lpm_class, NULL,
            MKDEV(lpm->inst[i].major, lpm->inst[i].minor),
            NULL, "lpm%d", lpm->inst[i].minor);
#else
#if LINUX_VERSION_CODE >= KERNEL_VERSION(2,6,27)
        device_create(lpm->lpm_class, NULL,
            MKDEV(lpm->inst[i].major, lpm->inst[i].minor), NULL,
            "lpm%d", lpm->inst[i].minor);
#else
        device_create(lpm->lpm_class, NULL,
            MKDEV(lpm->inst[i].major, lpm->inst[i].minor),
            "lpm%d", lpm->inst[i].minor);
#endif
#endif
    }

#endif  /* USE_UDEV */

    /* initialize lpm on reference counter */
    lpm_on_ref_count = 0;

    TRACE(KERN_ALERT "<-- lpm_init\n");

    return 0;

fail_01:
    return err;

fail_02:
    return -EIO;
}


/*
 *  ======== lpm_ioctl ========
 */
static int lpm_ioctl(struct file *filp,
                     unsigned int cmd, unsigned long args)
{
    struct LPM_Dev     *dev;
    LPM_Instance       *inst;
    LPM_Client         *client;
    LPM_Status          lpmStat = LPM_SOK;
    int                 stat = 0;

    TRACE(KERN_ALERT "--> lpm_ioctl, cmd: 0x%X\n", cmd);

    /* get pointer to this driver's device object */
    dev = container_of(filp->f_dentry->d_inode->i_cdev, struct LPM_Dev, cdev);
    //dev = container_of(NULL, struct LPM_Dev, cdev);

    /* set alias to instance object for this device */
    inst = &dev->inst[iminor(filp->f_dentry->d_inode)];

    /* enter critical section */
    if (down_interruptible(&inst->sem)) {
        stat = -ERESTARTSYS;
        goto fail;
    }

    /* dispatch requested command */
    switch (cmd) {
        case LPM_CTRL_CONNECT:
            TRACE(KERN_ALERT "ioctl: CONNECT\n");
            lpmStat = inst->lpm.connect(inst->lpm.instance);
            break;

        case LPM_CTRL_DISCONNECT:
            TRACE(KERN_ALERT "ioctl: DISCONNECT\n");
            lpmStat = inst->lpm.disconnect(inst->lpm.instance);
            break;

        case LPM_CTRL_OFF:
            TRACE(KERN_ALERT "ioctl: OFF\n");
            client = (LPM_Client *)(filp->private_data);

            /* ignore reference count if override bit is set */
            if (client->state & LPM_CTRL_REFCOUNTOVR) {
                lpmStat = inst->lpm.off(inst->lpm.instance);
            }
            else {
                /* decrement the client's 'ON' reference count */
                client->on_ref_count--;

                /* decrement the global 'ON' reference count */
                lpm_on_ref_count--;

                TRACE(KERN_ALERT "ref = %d\n", lpm_on_ref_count);

                /* turn off the power if last client */
                if (lpm_on_ref_count == 0) {
                    lpmStat = inst->lpm.off(inst->lpm.instance);
                }
            }
            break;

        case LPM_CTRL_ON:
            TRACE(KERN_ALERT "ioctl: ON, args = 0x%lX\n", args);
            client = (LPM_Client *)(filp->private_data);

            // If imcop state is not specified in args but enablevicp is
            // specified, then set args to reflect enablevicp value. If
            // neither spcifies imcop state, then rely on default value in
            // LPM_on function.
            if (((args & 0x2) == 0) && (enablevicp != -1)) {
                args = (args & ~(0x3)) | (enablevicp ? 0x3 : 0x2);
            }

            /* ignore reference count if override bit is set */
            if (client->state & LPM_CTRL_REFCOUNTOVR) {
                lpmStat = inst->lpm.on(inst->lpm.instance, (int)args);
            }
            else {
                /* increment the client's 'ON' reference count */
                client->on_ref_count++;

                /* increment the global 'ON' reference count */
                lpm_on_ref_count++;

                TRACE(KERN_ALERT "ref = %d\n", lpm_on_ref_count);

                /* turn on the power if first client */
                if (lpm_on_ref_count == 1) {
                    lpmStat = inst->lpm.on(inst->lpm.instance, (int)args);
                }
            }
            break;

        case LPM_CTRL_RESUME:
            TRACE(KERN_ALERT "ioctl: RESUME\n");
            lpmStat = inst->lpm.resume(inst->lpm.instance);
            break;

        case LPM_CTRL_SETPOWERSTATE:
            TRACE(KERN_ALERT "ioctl: SETPOWERSTATE, args = 0x%lX\n", args);
            lpmStat = inst->lpm.setPowerState(
                        inst->lpm.instance, (LPM_PowerState)args);
            break;

        case LPM_CTRL_SET:
            TRACE(KERN_ALERT "ioctl: SET, args = 0x%lX\n", args);
            client = (LPM_Client *)(filp->private_data);
            client->state |= (unsigned int)args;
            TRACE(KERN_ALERT "state = 0x%X\n", client->state);
            break;

        case LPM_CTRL_CLEAR:
            TRACE(KERN_ALERT "ioctl: CLEAR, args = 0x%lX\n", args);
            client = (LPM_Client *)(filp->private_data);
            client->state &= (~((unsigned int)args));
            TRACE(KERN_ALERT "state = 0x%X\n", client->state);
            break;
    }

    /* exit critical section */
    up(&inst->sem);

    if (lpmStat != LPM_SOK) {
        stat = -1;
    }

    TRACE(KERN_ALERT "<-- lpm_ioctl\n");

fail:
    return stat;
}


/*
 *  ======== lpm_open ========
 */
static int lpm_open(struct inode *inode, struct file *filp)
{
    struct LPM_Dev     *dev;
    LPM_Instance       *inst;
    LPM_Client         *client;
    int                 err = 0;


    TRACE(KERN_ALERT "--> lpm_open\n");

    /* get pointer to this driver's device object */
    dev = container_of(inode->i_cdev, struct LPM_Dev, cdev);

    /* set alias to instance object for this device */
    inst = &dev->inst[iminor(inode)];

    /* allocate a new client object and initialize it */
    client = kmalloc(sizeof(struct LPM_Client), GFP_KERNEL);

    if (!client) {
        TRACE(KERN_ALERT "Error: kmalloc failed\n");
        err = -ENOMEM;
        goto fail;
    }

    /* initialize the structure */
    client->state = 0;
    INIT_LIST_HEAD(&client->entry);
    client->on_ref_count = 0;
    filp->private_data = (void *)client;

    /* add new client to device instance object */
    if (down_interruptible(&inst->sem)) {
        err = -ERESTART;
        goto fail;
    }
    list_add(&client->entry, &inst->clients);
    up(&inst->sem);

    TRACE(KERN_ALERT "<-- lpm_open\n");

fail:
    if (err == -ERESTART) {
        kfree(client);
        client = NULL;
    }
    return err;
}


/*
 *  ======== lpm_release ========
 */
static int lpm_release(struct inode *inode, struct file *filp)
{
    struct LPM_Dev     *dev;
    LPM_Instance       *inst;
    LPM_Status          lpmStat;
    struct list_head   *ptr;
    LPM_Client         *client = NULL;
    int                 err = 0;


    TRACE(KERN_ALERT "--> lpm_release\n");

    /* get pointer to this driver's device object */
    dev = container_of(inode->i_cdev, struct LPM_Dev, cdev);

    /* set alias to instance object for this device */
    inst = &dev->inst[iminor(inode)];

    /* remove client from device instance object */
    if (down_interruptible(&inst->sem)) {
        err = -ERESTART;
        goto leave;
    }

    list_for_each(ptr, &inst->clients) {
        client = list_entry(ptr, LPM_Client, entry);
        if ((void *)client == (void *)filp->private_data) {
            list_del(ptr);
            break;
        }
        else {
            client = NULL;
        }
    }
    if (client == NULL) {
        err = -EBADFD;
        up(&inst->sem);
        goto leave;
    }

    /* ignore reference count if override bit is set */
    if (client->state & LPM_CTRL_REFCOUNTOVR) {
        /* do nothing */
    }
    else  if (lpm_on_ref_count > 0) {
        /* subtract the client's outstanding 'ON' reference count */
        lpm_on_ref_count -= client->on_ref_count;
        TRACE(KERN_ALERT "ref = %d\n", lpm_on_ref_count);

        if (lpm_on_ref_count == 0) {
            lpmStat = inst->lpm.off(inst->lpm.instance);
        }
    }

    up(&inst->sem);

    /* free the client object */
    if (client != NULL) {
        kfree(client);
        client = NULL;
    }

leave:
    TRACE(KERN_ALERT "<-- lpm_release\n");
    return err;
}


/*
 *  ======== lpm_os_remap ========
 */
static LPM_Status lpm_os_remap(unsigned long pa, unsigned long size,
    unsigned long *va)
{
    unsigned long vaddr;

    if ((vaddr = (unsigned long)ioremap_nocache((unsigned int)pa, size))) {
        *va = vaddr;
        return LPM_SOK;
    }

    return LPM_EFAIL;
}


/*
 *  ======== lpm_os_signal ========
 */
static LPM_Status lpm_os_signal(void *data)
{
    LPM_Instance *inst = (LPM_Instance *)data;

    TRACE(KERN_ALERT "--> lpm_os_signal\n");

    complete(&inst->event);

    TRACE(KERN_ALERT "<-- lpm_os_signal\n");

    return LPM_SOK;
}


/*
 *  ======== lpm_os_unmap ========
 */
static LPM_Status lpm_os_unmap(void *va)
{
    iounmap((void *)va);
    return LPM_SOK;
}


/*
 *  ======== lpm_os_wait ========
 */
static LPM_Status lpm_os_wait(void *data)
{
    LPM_Instance *inst = (LPM_Instance *)data;

    TRACE(KERN_ALERT "--> lpm_os_wait\n");

    wait_for_completion(&inst->event);

    TRACE(KERN_ALERT "<-- lpm_os_wait\n");

    return LPM_SOK;
}


/*
 *  ======== lpm_os_trace ========
 */
static void lpm_os_trace(char *fmt, ...)
{
    char        buf[500];
    va_list     va;

    va_start(va, fmt);

    if (trace) {
        vsnprintf(buf, 500, fmt, va);
        printk(KERN_ALERT "%s", buf);
    }

    va_end(va);
}


MODULE_LICENSE("GPL");
module_init(lpm_init);
module_exit(lpm_exit);
/*
 *  @(#) ti.bios.power; 1, 1, 1,1; 4-30-2010 13:19:43; /db/atree/library/trees/power/power-g09x/src/
 */

