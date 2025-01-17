#!/bin/bash

# Define the range of k-points to test. For example, from 4x4x4 to 6x6x6.
K_START=3
K_END=15
K_INCREMENT=2 #choose odd K-mesh grids only

############################### Crate KPOINTS directories #######################################

# Loop over the specified range of k-point values.
for (( K=$K_START; K<=$K_END; K+=$K_INCREMENT ))
do
   # Create a directory for the current k-point grid.
   mkdir KPOINTS_${K}x${K}x${K}
   cd KPOINTS_${K}x${K}x${K}

   # Copy VASP input files from the parent directory.
   cp ../INCAR .
   cp ../POSCAR .
   cp ../POTCAR .

   # Create the KPOINTS file for the current k-point grid.
   echo "Automatic mesh" > KPOINTS
   echo "0" >> KPOINTS
   echo "Gamma" >> KPOINTS
   echo "$K $K $K" >> KPOINTS

   # Submit the VASP job to the Slurm scheduler using a here-document for the job script.
   # Submit the VASP job to the Slurm scheduler using a here-document for the job script.
   sbatch << EOF
#!/bin/bash
#SBATCH --job-name=GaN_Conv_KPOINTS_${K}x${K}x${K}
#SBATCH --account=open
#SBATCH --partition=open
#SBATCH --mem=32GB
#SBATCH --time=00:30:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=32
#SBATCH --cpus-per-task=1

echo "Job started on $(hostname) at $(date)"
source ~/.bashrc
export PATH="$(pwd):${PATH}"
# Load VASP module
module use /storage/icds/RISE/sw8/modules
module load vasp/vasp-6.3.1vtst

echo "Start: $(date)"
## Run VASP std or gam version
srun vasp_std
# srun vasp_gam
echo "End: $(date)"

EOF
   # Return to the parent directory.
   cd ..
done

echo "K-point convergence test submission complete."


#command line execution
#chmod +x k_conv_test_1a.sh && sed -i 's/\r$//' k_conv_test_1a.sh && ./k_conv_test_1a.sh
