#!/bin/bash

source ../ccp4-7.0/bin/ccp4.setup-sh

../ccp4-7.0/bin/cif2mtz hklin ${PDB}.cif hklout ${PDB}.mtz <<END
END

../ccp4-7.0/bin/refmac5 hklin ${PDB}.mtz hklout ${PDB}_refmac1.mtz xyzin ${PDB}.pdb xyzout ${PDB}_refmac1.pdb libout ${PDB}_new.cif >> ${PDB}_refmac1.log <<END
MAKE CHECk NONE
REFInement TYPE UNREstrained
END

if [ $? != 0 ];then
	../ccp4-7.0/bin/refmac5 hklin ${PDB}.mtz hklout ${PDB}_refmac1.mtz xyzin ${PDB}.pdb xyzout ${PDB}_refmac1.pdb libin ${PDB}_new.cif >> ${PDB}_refmac1.log <<END
MAKE CHECk NONE
REFInement TYPE UNREstrained
END
fi

../ccp4-7.0/bin/fft hklin ${PDB}_refmac1.mtz mapout ${PDB}_refmac1.map <<END
LABI F1=FWT PHI=PHWT
END

../ccp4-7.0/bin/sfall hklin ${PDB}_refmac1.mtz hklout ${PDB}_refmac1_sfall1.mtz xyzin ${PDB}.pdb <<END-sfall
MODE SFCALC XYZIN HKLIN
LABIN FP=FP SIGFP=SIGFP FREE=FREE
LABOUT FC=FCalc PHIC=PHICalc
END
END-sfall

../ccp4-7.0/bin/fft hklin ${PDB}_refmac1_sfall1.mtz  mapout ${PDB}_refmac1_sfall1.map <<END
LABI F1=FCalc PHI=PHICalc
END

./lx_mapman >> mapman.txt <<END
read obs_map ${PDB}_refmac1.map ccp4
norm obs_map
read calc_map ${PDB}_refmac1_sfall1.map ccp4
norm calc_map
rs_fit
obs_map
calc_map
${PDB}.pdb
${PDB}.list
END

if [ $? != 0 ]; then
va=$( findMapSize.py mapman.txt >&1 )
./lx_mapman mapsize ${va} nummaps 2 <<END
read obs_map ${PDB}_refmac1.map ccp4
norm obs_map
read calc_map ${PDB}_refmac1_sfall1.map ccp4
norm calc_map
rs_fit
obs_map
calc_map
${PDB}.pdb
${PDB}.list
END
fi

rm mapman.txt ${PDB}_refmac1.map ${PDB}_refmac1_sfall1.map ${PDB}_refmac1_sfall1.mtz ${PDB}.mtz ${PDB}_refmac1.mtz #${PDB}_refmac1.pdb
