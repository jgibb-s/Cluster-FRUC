#! /bin/bash

ls -1 ~/cluster_jobs/input/*.in > input.list

count=0
comp=0

#list all inputs
while read -r line ; do 
    pw=$(echo ${line#input})

    #see if jobs is pending
    if grep -q ${pw%.scf.in} my.jobs ; then 

	((count++)) # jobs remaining

    else
	#check if job has already been completed
	if [ ! -f comp/${pw%.in}.out ] ; then 
	    
	    ((comp++))
	
	#if not completed & not pending
	else
	    
	    echo #"${HOME}/cluster_jobs/sub_dir/${pw%.scf.in}.sub" 

	fi
    fi

done < "input.list"

printf "# jobs remaining: %s\n# jobs completed: %s\n\n" "$count" "$comp"

rm -rf input.list



