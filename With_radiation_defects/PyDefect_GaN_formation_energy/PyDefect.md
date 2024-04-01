1) Installlation and Setup
---------------------------
-------------Open Jupyter Notebook terminal -------------
pip install doped 
pip install pymatgen

------------move to DOPED calculation directory and setup POTCAR files ------------
#Copy POSCAR and extract in the work directory
cd /storage/work/mvm7218/GaN2_doped
mkdir POT_GGA_PAW_PBE_54
tar -xzvf ../potpaw_PBE.54.tar.gz -C ./POT_GGA_PAW_PBE_54

#Create ./pmgrc.yaml file and add Materials Project (MP) API key and pseudo directory
cd
cd .config
touch .pmgrc.yaml
nano .pmgrc.yaml
#add the following three lines
                                                                                                                                                                                                                            
        PMG_DEFAULT_FUNCTIONAL: PBE
        PMG_MAPI_KEY: ksrEbuvP0ucRZAas11zIz8y7lii15gpy
        PMG_VASP_PSP_DIR: /storage/work/mvm7218/GaN2_doped

#create psp_resouces directory for DOPED
cd /storage/work/mvm7218/GaN2_doped
mkdir temp_potcars  # make a top folder to store the unzipped POTCARs
mkdir temp_potcars/POT_GGA_PAW_PBE  # make a subfolder to store the unzipped POTCARs
mv potpaw_PBE.54.tar.gz temp_potcars/POT_GGA_PAW_PBE  # copy in your zipped VASP POTCAR source
cd temp_potcars/POT_GGA_PAW_PBE
tar -xf potpaw_PBE.54.tar.gz  # unzip your VASP POTCAR source
cd ../..  # return to the top folder
pmg config -p temp_potcars psp_resources  # configure the psp_resources pymatgen POTCAR directory
pmg config --add PMG_VASP_PSP_DIR "${PWD}/psp_resources"  # add the POTCAR directory to pymatgen's config file ($HOME/.pmgrc.yaml)
rm -r temp_potcars  # remove the temporary POTCAR directory

#check if the installation is successful
pmg potcar -s Na_pv
grep PBE POTCAR


2) Generating defects with doped
----------------------------
python3:

from pymatgen.core.structure import Structure
from doped.generation import DefectsGenerator

#copy-paste your relaxed unit cell 
cp ../GaN/unitcell/band/INCAR .

# Load our relaxed bulk (host) structure:
relaxed_primitive_GaN = Structure.from_file("/storage/work/mvm7218/GaN2_doped/POSCAR")

# generate defects:
defect_gen = DefectsGenerator(relaxed_primitive_GaN)

# show the generated defect entries:
defect_gen.defect_entries.keys()

# Add some extra charge states for Cd_Te antisites
defect_gen.add_charge_states("Ga_N", [-2, -1])

# check our generated defect entries:
defect_gen

# likewise we can remove charge states with:
defect_gen.remove_charge_states("Ga_N", [+1])
defect_gen

# generate defects:
defect_gen = DefectsGenerator(relaxed_primitive_GaN, extrinsic=["Si", "Mg"])


3) Prepare VASP calculation files with doped
------------------------------------------
from doped.vasp import DefectsSet 

defect_set = DefectsSet(
    defect_gen,  # our DefectsGenerator object, can also input individual DefectEntry objects if desired
    user_incar_settings={"ENCUT": 400},  # custom INCAR settings, any that aren't numbers or True/False need to be input as strings with quotation marks!
)
# We can also customise the KPOINTS and POTCAR settings (and others), see the docstrings above for more info


#for example, let's look at the generated inputs for a `vasp_gam` calculation with `NKRED`, for Ga_N_+2:
print(f"INCAR:\n{defect_set.defect_sets['Ga_N_+2'].vasp_std.incar}")
print(f"KPOINTS:\n{defect_set.defect_sets['Ga_N_+2'].vasp_std.kpoints}")
print(f"POTCAR (symbols):\n{defect_set.defect_sets['Ga_N_+2'].vasp_std.potcar_symbols}")


defect_set.write_files(unperturbed_poscar = True)  # again add "?" to see the docstring and options

#go to GaN_bulk and crease vasp_std directory, copying contents from vasp_ncl
#open a separate normal terminal
!cd /storage/work/mvm7218/GaN2_doped/GaN_bulk
mkdir vasp_std
cp ./vasp_ncl/* ./vasp_std

############################## Compare works with PyDefect - use same INCAR (script at the end)#############
cd ..
##replace the INCAR settings
##copy paste srun.slurm file in each directory
##run sbatch file

############################################################################################# optional process starts
(bash:
cd
cd GaN_bulk/vasp_ncl
ls
nano KPOINTS
--change KPOINTS accordingly---
)


!ls *v_Ga*/*vasp* # list the generated VASP input files
[[[[
import subprocess

# Run the ls command
result = subprocess.run(["ls", "*v_Ga*/*vasp*"], stdout=subprocess.PIPE, shell=True)

# Print the output
print(result.stdout.decode())


]]]]

!ls GaN_bulk
[[
import subprocess

# Run the ls command
result = subprocess.run(["ls", "*GaN_bulk*"], stdout=subprocess.PIPE, shell=True)

# Print the output
print(result.stdout.decode())
]]
############################################################################################# optional process ends

Chemical Potentials:
Defect Calculation Parsing
======================
















#################### Scripts #################

#!/bin/bash

# Loop over directories matching the pattern *_*_* and add INCAR within vasp_std folder
for dir in *_*/; do
  # Check if the name is indeed a directory
  if [ -d "$dir" ]; then
    cd $dir
    cp /storage/work/mvm7218/GaN2_doped/INCAR ./vasp_std
    cd ..
  fi
done


# Loop over directories matching the pattern *_*_* and add srun.slurm within vasp_std folder

for dir in *_*/; do
    cd $dir
    cp /storage/work/mvm7218/GaN2_doped/srun.slurm ./vasp_std
    cd ..
done


# Loop over directories matching the pattern *_*_* and copy the INCAR settings
for dir in *_*/; do
  # Check if the name is indeed a directory
  if [ -d "$dir" ]; then
    cd $dir
    cp /storage/work/mvm7218/GaN2_doped/INCAR ./vasp_std
    cd ..
  fi
done

# If want to work on the existing INCAR
for dir in *_*/; do
    cd $dir
    cd vasp_std
    sed -i '15d' INCAR; 
    sed -i '16d' INCAR; 
    echo "EDIFFG  =  -0.01" >> INCAR; 
    echo "NSW = 40" >> INCAR;
    cd ../..
done

# Loop over directories matching the pattern *_*_* and run srun.slurm within vasp_std folder

for dir in *_*/; do
    cd $dir
    cd vasp_std
    JOB_ID=$(sbatch srun.slurm | awk '{print $4}')
    cd ../..

    # Wait for the job to complete
    echo "Waiting for job $JOB_ID to complete..."
done


$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
(files after pseudo --- not working -- alphabetic sort A->Z)

scancel --name=GaN_supercell_defect_DOPED