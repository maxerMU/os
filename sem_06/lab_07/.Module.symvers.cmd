cmd_/home/max/repos/os/sem_06/lab_07/Module.symvers := sed 's/\.ko$$/\.o/' /home/max/repos/os/sem_06/lab_07/modules.order | scripts/mod/modpost -m -a  -o /home/max/repos/os/sem_06/lab_07/Module.symvers -e -i Module.symvers   -T -