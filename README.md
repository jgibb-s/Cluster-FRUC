## Cluster-FRUC (Cluster-FRiendly Unattended Companion)

### How to set up
In order to use the Cluster-FRUC, the following changes must be made.

1) In run.sub:
   -comment out directives that are not applicable
   -double check directories for LIST, LOCKDIR, and LOG
   -change TWALLTIME to match walltime limit for that computer

Examples:
Cedar and Graham:
```
#SBATCH -t 14-00:00 
#SBATCH -J qe
#SBATCH --account=ACCOUNT-ID
#SBATCH -N 2
#SBATCH -n 16
#SBATCH --mem=14Gb
#SBATCH -oe /dev/null
```
Niagara:
```
#SBATCH -t 24:00 
#SBATCH -J qe
#SBATCH -N 2
#SBATCH -n 80
#SBATCH --mem=14Gb
#SBATCH -oe /dev/null
```
Orcinus:
```
#PBS -S /bin/bash
#PBS -j eo
#PBS -e /dev/null
#PBS -o /dev/null
#PBS -N qe
#PBS -l walltime=240:00:00,mem=20GB,nodes=1:ppn=4
#PBS -m n
#PBS -V
```


2) In gen_sub.sh
   - comment out anything labelled not relevant to the computer
   - Double check directories INDIR, COMPDIR, SUBDIR. LOGDIR


Cedar and Graham:
```
module load quantumespresso/6.1
```
Niagara:
```
module load CCEnv

module load nixpkgs/16.09
module load intel/2016.4
module load openmpi/2.1.1 
module load quantumespresso/6.1   
```
Orcinus:
```
module load espresso/6.0
```

### How it works:

Cluster-FRUC is set up to work out of whatever directory it's unpacked into.
Ideally, you should be able to just execute (or submit) run.sub, which will take
care of the rest, provided run.sub and sub_gen.sh have been properly modified.

The submission system itself is essentailly a personal job scheduler. It works
as follows:
- Executing run.sub will also execute sub_gen.sh if it hasn't already been done

- sub_gen.sh does the following:
    - creates sub_dir/, in which it will generate submission files for every input
    file in input/, and logs/, where it will generate the job.log file, which logs
    every job as it starts and its relevant info
    - it will also create the file my.jobs, which lists the location of every sub file
    created, which is then used by run.sub to run the jobs

- the sub files created by sub_gen.sh have VERY basic error handling, in that they
first check to see if the job has already been completed, if it hasn't it will run
the job, after which it will check to see if the job was successfully completed. If
it was successful, it will copy the output to comp/ and remove all temp files
created in the process. If the job fails, it looks for a CRASH file. If the job crashed
due to a missing upf, it records the missing upf to logs/upf.log. If the job fails for
any other reason, it runs pwout2in.awk to create a new input file, *-adj.scf.in, with
the last geometry before the job crashed and then adds the new input to my.jobs

- run.sub works by popping the first sub file off the top of my.jobs and running whatever
is contained by that file. sub_gen.sh is currently set up to run Quantum Espresso jobs,
but can be modified to run virtually any other program

- run.sub was written to avoid race conditions, so multiple instances can be run in tandem




ToDo:
- rsync completed files
- remake all pseudopotentials from pslibrary to include broader types
	