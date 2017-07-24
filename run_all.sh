#!/bin/bash

#SBATCH -n 1
#SBATCH -p normal
#SBATCH -t 8:00:00
#SBATCH -A A-ti3

### Paths of programs ###

DIR=/work/04202/sdo395/LigandTables  #Directory with all auxiliary programs and run_all
STR=${DIR}/structures  #Directory with unrefined directory and structure factor directory
RES=${STR}/${PDB}_results.csv #Result file for PDB
UNR=${STR}/unrefined #Directory with all original, unrefined PDB files
FAC=${STR}/factors #Directory with all unrefined PDB file's structure factor cif files from the PDB
MP=/work/01872/nclement/software/MolProbity/cmdline/oneline-analysis #MolProbity program
MOD=/work/04202/sdo395/ModRefiner-l #ModRefiner directory with full atom and main chain programs
3D=/work/04202/sdo395/i3Drefine/bin/i3Drefine.sh #3DRefine program
CVC=${DIR}/cvc-scripts #cvc-scripts folder with Nathan's scripts for computing energies
RESDIR=${STR}/${PDB} #Directory to store results

############Unrefined#################

### Copy File ###

mkdir $RESDIR
cp ${UNR}/${PDB}.pdb $RESDIR

### MolProbity ###

module load gcc
export PYTHONPATH=$PYTHONPATH:/home1/01872/nclement/.local/lib
export PATH=$PATH:/work/01872/nclement/install/bin
${MP} ${RESDIR} >> ${RESDIR}/MPUnrefined.txt
if [ $? = 0 ]; then
${DIR}/readMP.py ${RESDIR}/MPUnrefined.txt
${DIR}/csvify_MP.py ${RESDIR}/MPUnrefined.txt ${PDB}.pdb
mv ${PDB}MP.csv ${RESDIR}
echo -n Unrefined, | cat >> $RES
cat ${RESDIR}/${PDB}MP.csv >> $RES
else
	echo -n Unrefined,${PDB},x,x,x,x, | cat >> $RES
fi

### Compute Energy ###

module reset
cd ${RESDIR}
cp ${RESDIR}/${PDB}.pdb ${RESDIR}/energy.pdb
${CVC}/computeAllEnergy.sh energy.pdb 256
if [ $? = 0 ]; then
${CVC}/getGB_single_parts_clean.sh energy.pdb >> gb${PDB}.txt
${DIR}/csvify_energy.py gb${PDB}.txt
cat gb${PDB}.csv >> $RES
else
	echo -n x,x,x,x,x,x, | cat >> $RES
fi
rm -r PQR OUT INP QUAD RAW RAWN energy.pdb

### Compute Amber Energy ###

module reset
cp ${RESDIR}/${PDB}.pdb ${RESDIR}/amber.pdb
${CVC}/amber/runAmber_single.sh amber.pdb 50
if [ $? = 0 ]; then
${DIR}/getAmberEnergies.py amber.pdb
cat amber.csv >> $RES
else
	echo -n x,x,x,x,x,x,x,x,x,x, | cat >> $RES
fi
rm -r AMBER INP ERR leap.log mdinfo amber.pdb
cd ${DIR}

### Calculate RSR, RSCC, Rwork, Rfree, DPI ###

cp ${FAC}/${PDB}.cif ${DIR}
cp ${RESDIR}/${PDB}.pdb ${DIR}
PDB=${PDB} rsrCalc.sh
${DIR}/csvify_rsr.py ${PDB}.list
${DIR}/csvify_rwork.py ${PDB}_refmac1.pdb ${PDB}_refmac1.log
mv ${PDB}.list ${PDB}_refmac1.pdb ${PDB}_refmac1.log rsr.csv rwork.csv $RESDIR
cat ${RESDIR}/rsr.csv >> $RES
if [ $? != 0 ];then 
	echo -n x,x, | cat >> $RES
fi
cat ${RESDIR}/rwork.csv >> $RES
if [ $? != 0 ];then 
	echo -n x,x,x,x, | cat >> $RES
fi
rm ${PDB}.pdb
echo '' | cat >> $RES

####################### Full-Atom ModRefiner################################

### Refine ###

ml python/2.7.12
${MOD}/emrefinement ${RESDIR} ${MOD} ${PDB}.pdb ${PDB}.pdb 50 10
mkdir ${RESDIR}/em
mv ${RESDIR}/em${PDB}.pdb ${RESDIR}/em/${PDB}.pdb
${DIR}/edit_mf_results.py ${RESDIR}/em/${PDB}.pdb

### MolProbity ###

ml gcc
${MP} ${RESDIR}/em >> ${RESDIR}/em/MP${PDB}.txt
if [ $? = 0 ];then
${DIR}/readMP.py ${RESDIR}/em/MP${PDB}.txt
${DIR}/csvify_MP.py ${RESDIR}/em/MP${PDB}.txt ${PDB}.pdb
mv ${PDB}MP.csv ${RESDIR}/em
echo -n Full Atom ModRefiner, | cat >> $RES
cat ${RESDIR}/em/${PDB}MP.csv >> $RES
else
	echo -n Full Atom ModRefiner,${PDB},x,x,x,x | cat >> $RES
fi

### Compute Energy ###

module reset
cd ${RESDIR}/em
cp ${RESDIR}/em/${PDB}.pdb ${RESDIR}/em/energy.pdb
${CVC}/computeAllEnergy.sh energy.pdb 256
if [ $? = 0 ]; then
${CVC}/getGB_single_parts_clean.sh energy.pdb >> gb${PDB}.txt
${DIR}/csvify_energy.py gb${PDB}.txt
cat gb${PDB}.csv >> $RES
else
	echo -n x,x,x,x,x,x, | cat >> $RES
fi
rm -r PQR OUT INP QUAD RAW RAWN energy.pdb

### Compute Amber Energy ###

module reset
cp ${RESDIR}/em/${PDB}.pdb ${RESDIR}/em/amber.pdb
${CVC}/amber/runAmber_single.sh amber.pdb 50
if [ $? = 0 ]; then
${DIR}/getAmberEnergies.py amber.pdb
cat amber.csv >> $RES
else
	echo -n x,x,x,x,x,x,x,x,x,x, | cat >> $RES
fi
rm -r AMBER INP ERR leap.log mdinfo amber.pdb
cd ${DIR}

#### Calculate RSR, RSCC, Rwork, Rfree, DPI ###

cp ${RESDIR}/em/${PDB}.pdb ${DIR}
PDB=${PDB} rsrCalc.sh
csvify_rsr.py ${PDB}.list
csvify_rwork.py ${PDB}_refmac1.pdb ${PDB}_refmac1.log
mv ${PDB}.list ${PDB}_refmac1.pdb ${PDB}_refmac1.log rsr.csv rwork.csv ${RESDIR}/em
cat ${RESDIR}/em/rsr.csv >> $RES
if [ $? != 0 ];then
	echo -n x,x, | cat >> $RES
fi
cat ${RESDIR}/em/rwork.csv >> $RES
if [ $? != 0 ];then
	echo -n x,x,x,x, | cat >> $RES
fi
rm ${PDB}.pdb
echo '' | cat >> $RES

####################### Main Chain first, then Full Atom ModRefiner ##################################

### Main Chain Refine ###

ml python/2.7.12
${MOD}/mcrefinement ${RESDIR} ${MOD} ${PDB}.pdb ${PDB}.pdb 50
mkdir ${RESDIR}/mc
mv ${RESDIR}/mc${PDB}.pdb ${RESDIR}/mc/${PDB}.pdb

### Full Atom Refine ###

${MOD}/emrefinement ${RESDIR}/mc ${MOD} ${PDB}.pdb ${PDB}.pdb 50 10
mkdir ${RESDIR}/emmc
mv ${RESDIR}/mc/em${PDB}.pdb ${RESDIR}/emmc/${PDB}.pdb
edit_mf_results.py ${RESDIR}/emmc/${PDB}.pdb

### MolProbity ###

ml gcc
${MP} ${RESDIR}/emmc >> ${RESDIR}/emmc/MP${PDB}.txt
if [ $? = 0 ];then
${DIR}/readMP.py ${RESDIR}/emmc/MP${PDB}.txt
${DIR}/csvify_MP.py ${RESDIR}/emmc/MP${PDB}.txt ${PDB}.pdb
mv ${PDB}MP.csv ${RESDIR}/emmc
echo -n Main Chain then Full Atom ModRefiner, | cat >> $RES
cat ${RESDIR}/emmc/${PDB}MP.csv >> $RES
else
	echo -n Main Chain then Full Atom ModRefiner,${PDB},x,x,x,x, | cat >> $RES
fi

### Compute Energy ###

module reset
cd ${RESDIR}/emmc
cp ${RESDIR}/emmc/${PDB}.pdb ${RESDIR}/emmc/energy.pdb
${CVC}/computeAllEnergy.sh energy.pdb 256
if [ $? = 0 ];then
${CVC}/getGB_single_parts_clean.sh energy.pdb >> gb${PDB}.txt
${DIR}/csvify_energy.py gb${PDB}.txt
cat gb${PDB}.csv >> $RES
else
	echo -n x,x,x,x,x,x, | cat >> $RES
fi	
rm -r PQR OUT INP QUAD RAW RAWN energy.pdb

### Compute Amber Energy ###

module reset
cp ${RESDIR}/emmc/${PDB}.pdb ${RESDIR}/emmc/amber.pdb
${CVC}/amber/runAmber_single.sh amber.pdb 50
if [ $? = 0 ];then
${DIR}/getAmberEnergies.py amber.pdb
cat amber.csv >> $RES
else
	echo -n x,x,x,x,x,x,x,x,x,x, | cat >> $RES
fi
rm -r AMBER INP ERR leap.log mdinfo amber.pdb
cd ${DIR}

### Calculate RSR, RSCC, Rwork, Rfree, DPI ###

cp ${RESDIR}/emmc/${PDB}.pdb ${DIR}
PDB=${PDB} rsrCalc.sh
csvify_rsr.py ${PDB}.list
csvify_rwork.py ${PDB}_refmac1.pdb ${PDB}_refmac1.log
mv ${PDB}.list ${PDB}_refmac1.pdb ${PDB}_refmac1.log rsr.csv rwork.csv ${RESDIR}/emmc
cat ${RESDIR}/emmc/rsr.csv >> $RES
if [ $? != 0];then
	echo -n x,x, | cat >> $RES
fi
cat ${RESDIR}/emmc/rwork.csv >> $RES
if [ $? != 0];then
	echo -n x,x,x,x, | cat >> $RES
fi
rm ${PDB}.pdb
echo '' | cat >> $RES

#################################### 3DRefine ###########################################

## Split each chain into one pdb file ###

mkdir ${RESDIR}/3drefine/
${DIR}/single_chain.py ${RESDIR}/${PDB}.pdb ${RESDIR}/3drefine/

# Refine each and recombine into one pdb file ###

module reset
ml python/2.7.12
ml intel
ml boost/1.55.0
for item in ${RESDIR}/3drefine/*.pdb; do
	${3D} ${item} 1 &>> ${RESDIR}/3drefine/3drefine.out
	rm ${item}
done
${DIR}/3Drefine_parser.py ${RESDIR}/3drefine/ ${RESDIR}/3drefine/3drefine.out
${DIR}/recombineChains.py ${RESDIR}/${PDB}.pdb ${RESDIR}/3drefine/*.pdb ${PDB}
mv ${PDB}.pdb ${RESDIR}/3drefine

#### MolProbity ###

ml gcc
${MP} ${RESDIR}/3drefine >> ${RESDIR}/3drefine/3DRefineMP.txt
if [ $? = 0 ];then
${DIR}/readMP.py ${RESDIR}/3drefine/3DRefineMP.txt
${DIR}/csvify_MP.py ${RESDIR}/3drefine/3DRefineMP.txt ${PDB}.pdb
mv ${PDB}MP.csv ${RESDIR}/3drefine
echo -n 3DRefine, | cat >> $RES
cat ${RESDIR}/3drefine/${PDB}MP.csv >> $RES
else
	echo -n 3DRefine,${PDB},x,x,x,x, | cat >> $RES
fi

### Compute Energy ###

cd ${RESDIR}/3drefine/
cp ${RESDIR}/3drefine/${PDB}.pdb ${RESDIR}/3drefine/energy.pdb
module reset
${CVC}/computeAllEnergy.sh energy.pdb 256
if [ $? = 0 ]; then
${CVC}/getGB_single_parts_clean.sh energy.pdb >> gb${PDB}.txt
${DIR}/csvify_energy.py gb${PDB}.txt
cat gb${PDB}.csv >> $RES
else
	echo -n x,x,x,x,x,x, | cat >> $RES
fi
rm -r PQR OUT INP QUAD RAW RAWN energy.pdb

### Compute Amber Energy ###

module reset
cp ${RESDIR}/3drefine/${PDB}.pdb ${RESDIR}/3drefine/amber.pdb
${CVC}/amber/runAmber_single.sh amber.pdb 50
if [ $? = 0 ];then
${DIR}/getAmberEnergies.py amber.pdb
cat amber.csv >> $RES
else
	echo -n x,x,x,x,x,x,x,x,x,x, | cat >> $RES
fi
rm -r AMBER INP ERR leap.log mdinfo amber.pdb
cd ${DIR}

### Calculate RSR, RSCC, Rwork, Rfree, DPI ###

cp ${RESDIR}/3drefine/${PDB}.pdb ${DIR}
PDB=${PDB} rsrCalc.sh
csvify_rsr.py ${PDB}.list
csvify_rwork.py ${PDB}_refmac1.pdb ${PDB}_refmac1.log
mv ${PDB}.list ${PDB}_refmac1.pdb ${PDB}_refmac1.log rsr.csv rwork.csv ${RESDIR}/3drefine
cat ${RESDIR}/3drefine/rsr.csv >> $RES 
if [ $? != 0 ];then
	echo -n x,x, | cat >> $RES
fi
cat ${RESDIR}/3drefine/rwork.csv >> $RES
if [ $? != 0 ];then
	echo -n x,x,x,x, | cat >> $RES
fi
rm ${PDB}.pdb
echo '' | cat >> $RES

############################# PDB_REDO ######################################

## Download from PDB_REDO Database ###

mkdir ${RESDIR}/PDB_REDO
wget -O ${RESDIR}/PDB_REDO/${PDB}.pdb www.cmbi.ru.nl/pdb_redo/${PDB:1:2}/${PDB}/${PDB}_final.pdb

### MolProbity ###	

ml gcc
${MP} ${RESDIR}/PDB_REDO >> ${RESDIR}/PDB_REDO/PDB_REDO_MP.txt
if [ $? = 0 ];then
${DIR}/readMP.py ${RESDIR}/PDB_REDO/PDB_REDO_MP.txt
${DIR}/csvify_MP.py ${RESDIR}/PDB_REDO/PDB_REDO_MP.txt ${PDB}.pdb
mv ${PDB}MP.csv ${RESDIR}/PDB_REDO/
echo -n PDB_REDO, | cat >> $RES
cat ${RESDIR}/PDB_REDO/${PDB}MP.csv >> $RES
else
	echo -n PDB_REDO,${PDB},x,x,x,x, | cat >> $RES
fi

### Compute Energy ###

module reset
cp ${RESDIR}/PDB_REDO/${PDB}.pdb ${RESDIR}/PDB_REDO/energy.pdb
cd ${RESDIR}/PDB_REDO
${CVC}/computeAllEnergy.sh energy.pdb 256
if [ $? = 0 ];then
${CVC}/getGB_single_parts_clean.sh energy.pdb >> gb${PDB}.txt
${DIR}/csvify_energy.py gb${PDB}.txt
cat gb${PDB}.csv >> $RES
else
	echo -n x,x,x,x,x,x, | cat >> $RES
fi
rm -r PQR OUT INP QUAD RAW RAWN energy.pdb

### Compute Amber Energy ###

module reset
cp ${RESDIR}/PDB_REDO/${PDB}.pdb ${RESDIR}/PDB_REDO/amber.pdb
${CVC}/amber/runAmber_single.sh amber.pdb 50
if [ $? = 0 ];then
${DIR}/getAmberEnergies.py amber.pdb
cat amber.csv >> $RES
else
	echo -n x,x,x,x,x,x,x,x,x,x, | cat >> $RES
fi
rm -r AMBER INP ERR leap.log mdinfo amber.pdb
cd ${DIR}

### Calculate RSR, RSCC, Rwork, Rfree, DPI ###

cp ${RESDIR}/PDB_REDO/${PDB}.pdb ${DIR}
PDB=${PDB} rsrCalc.sh
${DIR}/csvify_rsr.py ${PDB}.list
${DIR}/csvify_rwork.py ${PDB}_refmac1.pdb ${PDB}_refmac1.log
mv ${PDB}.list ${PDB}_refmac1.pdb ${PDB}_refmac1.log rsr.csv rwork.csv ${RESDIR}/PDB_REDO
cat ${RESDIR}/PDB_REDO/rsr.csv >> $RES
if [ $? != 0 ];then
	echo -n x,x, | cat >> $RES
fi
cat ${RESDIR}/PDB_REDO/rwork.csv >> $RES
if [ $? != 0 ];then
	echo -n x,x,x,x, | cat >> $RES
fi
rm ${PDB}.pdb
echo '' | cat >> $RES

rm ${PDB}.cif
