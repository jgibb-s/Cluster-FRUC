#! /bin/bash

LIST="${HOME}/cluster_jobs/my.jobs"

INDIR="${HOME}/cluster_jobs/input"
COMPDIR="${HOME}/cluster_jobs/comp"
SUBDIR="${HOME}/cluster_jobs/sub_dir"
LOGDIR="${HOME}/cluster_jobs/logs"

if [ ! -d $SUBDIR ] ; then
    mkdir $SUBDIR
fi

if [ ! -d $LOGDIR ] ; then
    mkdir $LOGDIR
fi

rm -f $LIST
touch $LIST

for j in ${INDIR}/*.scf.in ; do
    pw=$(echo ${j%.scf.in} | rev | cut -d'/' -f1 | rev)
    echo ${SUBDIR}/${pw}.sub
    cat > ${SUBDIR}/${pw}.sub <<EOF
#! /bin/bash

LIST="\${HOME}/cluster_jobs/my.jobs"
CRASHLOG="\${HOME}/cluster_jobs/logs/crash.log"

INDIR="\${HOME}/cluster_jobs/input"
COMPDIR="\${HOME}/cluster_jobs/comp"
SUBDIR="\${HOME}/cluster_jobs/sub_dir"
LOGDIR="\${HOME}/cluster_jobs/logs"

RUNDIR="\${HOME}/cluster_jobs/${pw}.run"


##################qe instructions###################

if [ -f \${COMPDIR}/${pw}.scf.out ] && grep -q "JOB DONE" \${COMPDIR}/${pw}.scf.out ; then

   touch \${LOGDIR}/completed.log
   echo \${COMPDIR}/${pw}.scf.out >> \${LOGDIR}/completed.log    

elif grep -q ${pw}.scf.out \${COMPDIR}/comp.list ; then 

   touch \${LOGDIR}/completed.log
   echo \${COMPDIR}/${pw}.scf.out >> \${LOGDIR}/completed.log    

else

#########################################
#cedar and graham
module load quantumespresso/6.1

#nigara
module load CCEnv

module load nixpkgs/16.09
module load intel/2016.4
module load openmpi/2.1.1 
module load quantumespresso/6.1   

#orcinus
module load espresso/6.0
#########################################

export ESPRESSO_TMPDIR=/tmp


    mkdir \${RUNDIR}
    cp \${INDIR}/${pw}.scf.in \${RUNDIR}/${pw}.scf.in

    mpirun pw.x < \${RUNDIR}/${pw}.scf.in > \${RUNDIR}/${pw}.scf.out


    if grep -q "JOB DONE" \${RUNDIR}/${pw}.scf.out ; then

	cp \${RUNDIR}/${pw}.scf.out \${COMPDIR}/
	echo \${COMPDIR}/${pw}.scf.out >> \${LOGDIR}/completed.log    

    elif [ -f \${HOME}/cluster_jobs/CRASH ] ; then

        upf=\$(grep UPF \${HOME}/cluster_jobs/CRASH | head -n 1 | awk '{ print \$2 }')

	if [ ! -z \$upf ] ; then
	    touch \${LOGDIR}/upf.log
	    echo \$upf
	    echo ${pw}.scf.in \$upf > \${LOGDIR}/upf.log 

	else

	    ./pwout2in.awk \${RUNDIR}/${pw}.scf.out \${RUNDIR}/${pw}.scf.in > \${INDIR}/${pw}.scf.in.tmp && mv \${INDIR}/${pw}.scf.in.tmp \${INDIR}/${pw}.scf.in 
            echo "! geometry adjusted" >> \${INDIR}/${pw}.scf.in
	    echo \${SUBDIR}/${pw}.sub >> $LIST

	fi
        touch \$CRASHLOG
        cat \${HOME}/cluster_jobs/CRASH >> \$CRASHLOG 
	rm \${HOME}/cluster_jobs/CRASH
    fi

     rm -rf ~/scratch/${pw}*

fi


EOF
    echo ${SUBDIR}/${pw}.sub >> $LIST
    cp $LIST{,.bkp}
done

