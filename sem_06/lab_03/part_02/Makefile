CURRENT=$(shell uname -r)
KDIR=/lib/modules/$(CURRENT)/build
PWD=$(shell pwd)

TARGET1 = md1
TARGET2 = md2
# TARGET3 = md3

obj-m := $(TARGET1).o $(TARGET2).o 
# $(TARGET3).o

default:
	$(MAKE) -C $(KDIR) M=$(PWD) modules

clean:
	@rm -f *.o .*.cmd .*.flags *.mod.c *.order Module.*
	@rm -f .*.*.cmd *~ *.*~ TODO.*
	@rm -fR .tmp*
	@rm -rf .tmp_versions

disclean: clean
	@rm *.ko *.symvers *.mod

load:
	sudo insmod md1.ko
	sudo insmod md2.ko
#   sudo insmod md3.ko

remove:
	sudo rmmod md2.ko
	sudo rmmod md1.ko
#	sudo rmmod md3.ko
	
	
info:
	modinfo md1.ko
	modinfo md2.ko
#	modinfo md3.ko

logs:
	dmesg 
