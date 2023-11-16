#! /bin/bash

LIVE=$(pwd)/logs/job.stat
USER=user

touch $LIVE
echo "info on deceased jobs written to: $LIVE"

for i in *.run/ ; do
    D=$(date -r $i*.out +%Y-%m-%d\ %H:%M:%S )
    SIZE=$(du -hs $i*.out | awk '{ print $1 }')
    echo ${i%/} "($SIZE) last modified" $D
done > ${LIVE}.tmp

while read -r line ; do
    if grep -q "$line" $LIVE ; then
	echo $line "has died, recovering now"
	pw=$(echo $line | awk '{ print $1 }')
	./pwout2in.awk ${pw}/${pw%.run}.scf.out ${pw}/${pw%.run}.scf.in > input/${pw%.run}.scf.in.tmp && mv input/${pw%.run}.scf.in.tmp input/${pw%.run}.scf.in
	echo -e "\n! geometry adjusted" >> input/${pw%.run}.scf.in
	echo -e "${HOME}/cluster_jobs/sub_dir/${pw%.run}.sub" >> my.jobs
	rm -r $pw
    fi
done < "${LIVE}.tmp"
mv ${LIVE}.tmp $LIVE



tot=$(job_num=0 ; for i in ~/cluster_jobs/input/*.in ; do ((job_num++)) ; done ; echo $job_num )
comp=$(grep "JOB DONE" ~/cluster_jobs/comp/*.out | wc -l | awk '{ print $1 }')
adj=$(grep "! geometry adjusted" ~/cluster_jobs/input/*.in | uniq | wc -l | awk '{ print $1 }')
submit_tot=$(squeue | grep $USER | wc -l | awk '{ print $1 }')
run=$(squeue | grep $USER | wc -l | grep " R " | awk '{ print $1 }')

printf "DFT stats:\n\ncomp: %s\npending: %s\ninputs: %s\n\njobs running: %s of %s" "$comp" "$pend" "$tot" "$run" "$submit_tot"
