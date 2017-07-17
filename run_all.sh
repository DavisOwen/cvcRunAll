#!/bin/bash

#SBATCH -n 1
#SBATCH -p normal
#SBATCH -t 8:00:00
#SBATCH -A A-ti3

### Results File ###

RES=${PDB}_results.csv

############Unrefined#################

### Copy File ###

mkdir ./structures/${PDB}
cp ./structures/unrefined/${PDB}.pdb ./structures/${PDB}

### MolProbity ###

module load gcc
export PYTHONPATH=$PYTHONPATH:/home1/01872/nclement/.local/lib
export PATH=$PATH:/work/01872/nclement/install/bin
/work/01872/nclement/software/MolProbity/cmdline/oneline-analysis ./structures/${PDB} >> ./structures/${PDB}/MPUnrefined.txt
if [ $? = 0 ]; then
readMP.py ./structures/${PDB}/MPUnrefined.txt
csvify_MP.py ./structures/${PDB}/MPUnrefined.txt ${PDB}.pdb
mv ${PDB}MP.csv ./structures/${PDB}
echo -n Unrefined, | cat >> $RES
cat ./structures/${PDB}/${PDB}MP.csv >> $RES
else
	echo -n Unrefined,{$PDB},x,x,x,x, | cat >> $RES
fi

### Compute Energy ###

module reset
cd ./structures/${PDB}/
../../cvc-scripts/computeAllEnergy.sh ${PDB}.pdb 256
if [ $? = 0 ]; then
../../cvc-scripts/getGB_single_parts_clean.sh ${PDB}.pdb >> gb${PDB}.txt
../../csvify_energy.py gb${PDB}.txt
cat gb${PDB}.csv >> ../../$RES
else
	echo -n x,x,x,x,x,x, | cat >> ../../$RES
fi
rm -r PQR OUT INP QUAD RAW RAWN

### Compute Amber Energy ###

module reset
../../cvc-scripts/amber/runAmber_single.sh ${PDB}.pdb 50
if [ $? = 0 ]; then
../../getAmberEnergies.py ${PDB}.pdb
cat amber.csv >> ../../$RES
else
	echo -n x,x,x,x,x,x,x,x,x,x, | cat >> ../../$RES
fi
rm -r AMBER INP ERR leap.log mdinfo
cd ../../

### Calculate RSR, RSCC, Rwork, Rfree, DPI ###

cp ./structures/factors/${PDB}.cif ./
cp ./structures/${PDB}/${PDB}.pdb ./
PDB=${PDB} rsrCalc.sh
mv ${PDB}.list ${PDB}_refmac1.pdb ./structures/${PDB}
csvify_rsr.py ./structures/${PDB}/${PDB}.list
csvify_rwork.py ./structures/${PDB}/${PDB}_refmac1.pdb
mv rsr.csv rwork.csv ./structures/${PDB}
cat ./structures/${PDB}/rsr.csv >> $RES
if [ $? != 0 ];then 
	echo -n x,x, | cat >> $RES
fi
cat ./structures/${PDB}/rwork.csv >> $RES
if [ $? != 0 ];then 
	echo -n x,x, | cat >> $RES
fi
rm ${PDB}.pdb
echo '' | cat >> $RES

####################### Full-Atom ModRefiner################################

### Refine ###

ml python/2.7.12
/work/04202/sdo395/ModRefiner-l/emrefinement ./structures/${PDB} /work/04202/sdo395/ModRefiner-l/ ${PDB}.pdb ${PDB}.pdb 50 10
mkdir ./structures/${PDB}/em${PDB}
mv ./structures/${PDB}/em${PDB}.pdb ./structures/${PDB}/em${PDB}/${PDB}.pdb
edit_mf_results.py ./structures/${PDB}/em${PDB}/${PDB}.pdb

### MolProbity ###

ml gcc
/work/01872/nclement/software/MolProbity/cmdline/oneline-analysis ./structures/${PDB}/em${PDB} >> ./structures/${PDB}/em${PDB}/MP${PDB}.txt
if [ $? = 0 ];then
readMP.py ./structures/${PDB}/em${PDB}/MP${PDB}.txt
csvify_MP.py ./structures/${PDB}/em${PDB}/MP${PDB}.txt ${PDB}.pdb
mv ${PDB}MP.csv ./structures/${PDB}/em${PDB}
echo -n Full Atom ModRefiner, | cat >> $RES
cat ./structures/${PDB}/em${PDB}/${PDB}MP.csv >> $RES
else
	echo -n Full Atom ModRefiner,${PDB},x,x,x,x | cat >> $RES
fi

### Compute Energy ###

module reset
cd ./structures/${PDB}/em${PDB}
../../../cvc-scripts/computeAllEnergy.sh ${PDB}.pdb 256
if [ $? = 0 ]; then
../../../cvc-scripts/getGB_single_parts_clean.sh ${PDB}.pdb >> gb${PDB}.txt
../../../csvify_energy.py gb${PDB}.txt ${PDB}
cat gb${PDB}.csv >> ../../../$RES
else
	echo -n x,x,x,x,x,x, | cat >> ../../../$RES
fi
rm -r PQR OUT INP QUAD RAW RAWN

### Compute Amber Energy ###

module reset
../../../cvc-scripts/amber/runAmber_single.sh ${PDB}.pdb 50
if [ $? = 0 ]; then
../../../getAmberEnergies.py ${PDB}.pdb
cat amber.csv >> ../../../$RES
else
	echo -n x,x,x,x,x,x,x,x,x,x, | cat >> ../../../$RES
fi
rm -r AMBER INP ERR leap.log mdinfo
cd ../../../

#### Calculate RSR, RSCC, Rwork, Rfree, DPI ###

cp ./structures/${PDB}/em${PDB}/${PDB}.pdb ./
PDB=${PDB} rsrCalc.sh
mv ${PDB}.list ${PDB}_refmac1.pdb ./structures/${PDB}/em${PDB}
csvify_rsr.py ./structures/${PDB}/em${PDB}/${PDB}.list
csvify_rwork.py ./structures/${PDB}/em${PDB}/${PDB}_refmac1.pdb
mv rsr.csv rwork.csv ./structures/${PDB}/em${PDB}
cat ./structures/${PDB}/em${PDB}/rsr.csv >> $RES
if [ $? != 0 ];then
	echo -n x,x, | cat >> $RES
fi
cat ./structures/${PDB}/em${PDB}/rwork.csv >> $RES
if [ $? != 0 ];then
	echo -n x,x, | cat >> $RES
fi
rm ${PDB}.pdb
echo '' | cat >> $RES

####################### Main Chain first, then Full Atom ModRefiner ##################################

### Main Chain Refine ###

ml python/2.7.12
/work/04202/sdo395/ModRefiner-l/mcrefinement ./structures/${PDB} /work/04202/sdo395/ModRefiner-l/ ${PDB}.pdb ${PDB}.pdb 50
mkdir ./structures/${PDB}/mc${PDB}
mv ./structures/${PDB}/mc${PDB}.pdb ./structures/${PDB}/mc${PDB}/${PDB}.pdb

### Full Atom Refine ###

/work/04202/sdo395/ModRefiner-l/emrefinement ./structures/${PDB}/mc${PDB} /work/04202/sdo395/ModRefiner-l/ ${PDB}.pdb ${PDB}.pdb 50 10
mkdir ./structures/${PDB}/emmc${PDB}
mv ./structures/${PDB}/mc${PDB}/em${PDB}.pdb ./structures/${PDB}/emmc${PDB}/${PDB}.pdb
edit_mf_results.py ./structures/${PDB}/emmc${PDB}/${PDB}.pdb

### MolProbity ###

ml gcc
/work/01872/nclement/software/MolProbity/cmdline/oneline-analysis ./structures/${PDB}/emmc${PDB} >> ./structures/${PDB}/emmc${PDB}/MP${PDB}.txt
if [ $? = 0 ];then
readMP.py ./structures/${PDB}/emmc${PDB}/MP${PDB}.txt
csvify_MP.py ./structures/${PDB}/emmc${PDB}/MP${PDB}.txt ${PDB}.pdb
mv ${PDB}MP.csv ./structures/${PDB}/emmc${PDB}
echo -n Main Chain then Full Atom ModRefiner, | cat >> $RES
cat ./structures/${PDB}/emmc${PDB}/${PDB}MP.csv >> $RES
else
	echo -n Main Chain then Full Atom ModRefiner,${PDB},x,x,x,x, | cat >> $RES
fi

### Compute Energy ###

module reset
cd ./structures/${PDB}/emmc${PDB}
../../../cvc-scripts/computeAllEnergy.sh ${PDB}.pdb 256
if [ $? = 0 ];then
../../../cvc-scripts/getGB_single_parts_clean.sh ${PDB}.pdb >> gb${PDB}.txt
../../../csvify_energy.py gb${PDB}.txt
cat gb${PDB}.csv >> ../../../$RES
else
	echo -n x,x,x,x,x,x, | cat >> ../../../$RES
fi	
rm -r PQR OUT INP QUAD RAW RAWN

### Compute Amber Energy ###

module reset
../../../cvc-scripts/amber/runAmber_single.sh ${PDB}.pdb 50
if [ $? = 0 ];then
../../../getAmberEnergies.py ${PDB}.pdb
cat amber.csv >> ../../../$RES
else
	echo -n x,x,x,x,x,x,x,x,x,x, | cat >> ../../../$RES
fi
rm -r AMBER INP ERR leap.log mdinfo
cd ../../../

### Calculate RSR, RSCC, Rwork, Rfree, DPI ###

cp ./structures/${PDB}/emmc${PDB}/${PDB}.pdb ./
PDB=${PDB} rsrCalc.sh
mv ${PDB}.list ${PDB}_refmac1.pdb ./structures/${PDB}/emmc${PDB}
csvify_rsr.py ./structures/${PDB}/emmc${PDB}/${PDB}.list
csvify_rwork.py ./structures/${PDB}/emmc${PDB}/${PDB}_refmac1.pdb
mv rsr.csv rwork.csv ./structures/${PDB}/emmc${PDB}
cat ./structures/${PDB}/emmc${PDB}/rsr.csv >> $RES
if [ $? != 0];then
	echo -n x,x, | cat >> $RES
fi
cat ./structures/${PDB}/emmc${PDB}/rwork.csv >> $RES
if [ $? != 0];then
	echo -n x,x, | cat >> $RES
fi
rm ${PDB}.pdb
echo '' | cat >> $RES

#################################### 3DRefine ###########################################

## Split each chain into one pdb file ###

mkdir ./structures/${PDB}/3drefine/
./single_chain.py ./structures/${PDB}/${PDB}.pdb ./structures/${PDB}/3drefine/

# Refine each and recombine into one pdb file ###

module reset
ml python/2.7.12
ml intel
ml boost/1.55.0
for item in ./structures/${PDB}/3drefine/*.pdb; do
	/work/04202/sdo395/i3Drefine/bin/i3Drefine.sh ${item} 1 &>> ./structures/${PDB}/3drefine/3drefine.out
	rm ${item}
done
3Drefine_parser.py ./structures/${PDB}/3drefine/ ./structures/${PDB}/3drefine/3drefine.out
recombineChains.py ./structures/${PDB}/${PDB}.pdb ./structures/${PDB}/3drefine/*.pdb ${PDB}
mv ${PDB}.pdb ./structures/${PDB}/3drefine

#### MolProbity ###

ml gcc
/work/01872/nclement/software/MolProbity/cmdline/oneline-analysis ./structures/${PDB}/3drefine >> ./structures/${PDB}/3drefine/3DRefineMP.txt
if [ $? = 0 ];then
readMP.py ./structures/${PDB}/3drefine/3DRefineMP.txt
csvify_MP.py ./structures/${PDB}/3drefine/3DRefineMP.txt ${PDB}.pdb
mv ${PDB}MP.csv ./structures/${PDB}/3drefine
echo -n 3DRefine, | cat >> $RES
cat ./structures/${PDB}/3drefine/${PDB}MP.csv >> $RES
else
	echo -n 3DRefine,${PDB},x,x,x,x, | cat >> $RES
fi

### Compute Energy ###

cd ./structures/${PDB}/3drefine/
module reset
#for file in *.pdb; do
#	if [ ${file} != 3DRefineMP.txt ]; then
		../../../cvc-scripts/computeAllEnergy.sh ${PDB}.pdb 256
		if [ $? = 0 ]; then
		../../../cvc-scripts/getGB_single_parts_clean.sh ${PDB}.pdb >> gb${PDB}.txt
		../../../csvify_energy.py gb${PDB}.txt
		cat gb${PDB}.csv >> ../../../$RES
		else
			echo -n x,x,x,x,x,x, | cat >> ../../../$RES
		fi
		rm -r PQR OUT INP QUAD RAW RAWN
#	fi
#done

### Compute Amber Energy ###

module reset
../../../cvc-scripts/amber/runAmber_single.sh ${PDB}.pdb 50
if [ $? = 0 ];then
../../../getAmberEnergies.py ${PDB}.pdb
cat amber.csv >> ../../../$RES
else
	echo -n x,x,x,x,x,x,x,x,x,x, | cat >> ../../../$RES
fi
rm -r AMBER INP ERR leap.log mdinfo
cd ../../../

### Calculate RSR, RSCC, Rwork, Rfree, DPI ###

cp ./structures/${PDB}/3drefine/${PDB}.pdb ./
PDB=${PDB} rsrCalc.sh
mv ${PDB}.list ${PDB}_refmac1.pdb ./structures/${PDB}/3drefine
csvify_rsr.py ./structures/${PDB}/3drefine/${PDB}.list
csvify_rwork.py ./structures/${PDB}/3drefine/${PDB}_refmac1.pdb
mv rsr.csv rwork.csv ./structures/${PDB}/3drefine
cat ./structures/${PDB}/3drefine/rsr.csv >> $RES 
if [ $? != 0 ];then
	echo -n x,x, | cat >> $RES
fi
cat ./structures/${PDB}/3drefine/rwork.csv >> $RES
if [ $? != 0 ];then
	echo -n x,x, | cat >> $RES
fi
rm ${PDB}.pdb
echo '' | cat >> $RES

############################# PDB_REDO ######################################

## Download from PDB_REDO Database ###

mkdir ./structures/${PDB}/PDB_REDO
wget -O ./structures/${PDB}/PDB_REDO/${PDB}.pdb www.cmbi.ru.nl/pdb_redo/${PDB:1:2}/${PDB}/${PDB}_final.pdb

### If structure exists, Refine ###

if [ $? = 0 ]; then

	### MolProbity ###	

	ml gcc
	/work/01872/nclement/software/MolProbity/cmdline/oneline-analysis ./structures/${PDB}/PDB_REDO >> ./structures/${PDB}/PDB_REDO/PDB_REDO_MP.txt
	if [ $? = 0 ];then
	readMP.py ./structures/${PDB}/PDB_REDO/PDB_REDO_MP.txt
	csvify_MP.py ./structures/${PDB}/PDB_REDO/PDB_REDO_MP.txt ${PDB}.pdb
	mv ${PDB}MP.csv ./structures/${PDB}/PDB_REDO/
	echo -n PDB_REDO, | cat >> $RES
	cat ./structures/${PDB}/PDB_REDO/${PDB}MP.csv >> $RES
	else
		echo -n PDB_REDO,${PDB},x,x,x,x, | cat >> $RES
	fi

	### Compute Energy ###

	module reset
	cd ./structures/${PDB}/PDB_REDO
	../../../cvc-scripts/computeAllEnergy.sh ${PDB}.pdb 256
	if [ $? = 0 ];then
	../../../cvc-scripts/getGB_single_parts_clean.sh ${PDB}.pdb >> gb${PDB}.txt
	../../../csvify_energy.py gb${PDB}.txt ${PDB}
	cat gb${PDB}.csv >> ../../../$RES
	else
		echo -n x,x,x,x,x,x, | cat >> ../../../$RES
	fi
	rm -r PQR OUT INP QUAD RAW RAWN

	### Compute Amber Energy ###

	module reset
	../../../cvc-scripts/amber/runAmber_single.sh ${PDB}.pdb 50
	if [ $? = 0 ];then
	../../../getAmberEnergies.py ${PDB}.pdb
	cat amber.csv >> ../../../$RES
	else
		echo -n x,x,x,x,x,x,x,x,x,x, | cat >> ../../../$RES
	fi
	rm -r AMBER INP ERR leap.log mdinfo
	cd ../../../

	### Calculate RSR, RSCC, Rwork, Rfree, DPI ###
	
	cp ./structures/${PDB}/PDB_REDO/${PDB}.pdb ./
	PDB=${PDB} rsrCalc.sh
	mv ${PDB}.list ${PDB}_refmac1.pdb ./structures/${PDB}/PDB_REDO
	csvify_rsr.py ./structures/${PDB}/PDB_REDO/${PDB}.list
	csvify_rwork.py ./structures/${PDB}/PDB_REDO/${PDB}_refmac1.pdb
	mv rsr.csv rwork.csv ./structures/${PDB}/PDB_REDO
	cat ./structures/${PDB}/PDB_REDO/rsr.csv >> $RES
	if [ $? != 0 ];then
		echo -n x,x, | cat >> $RES
	fi
	cat ./structures/${PDB}/PDB_REDO/rwork.csv >> $RES
	if [ $? != 0 ];then
		echo -n x,x, | cat >> $RES
	fi
	rm ${PDB}.pdb
	echo '' | cat >> $RES

fi

rm ${PDB}.cif
mv $RES ./structures
