#!/bin/bash
#Setting
Prefix=$PWD
ComName=
ComPDB=
RecName=
RecPDB=
LigName=
LigPDB=
LigNameInPDB=
LigMol2File=
LigFrcmodFile=
PBRadii=
RemoveTemp=0

#Create tleap.in
cat > tleap.in << EOF
source oldff/leaprc.ff14SB
source leaprc.protein.ff14SB
source leaprc.gaff
${LigNameInPDB}=loadmol2 ${LigMol2File}
loadamberparams ${LigFrcmodFile}
WidRec=loadpdb ${RecPDB}
Lig=loadpdb ${LigName}.pdb
WidCom=loadpdb ${ComPDB}
set default PBRadii ${PBRadii}
saveamberparm WidRec ${RecName}.top ${RecName}.crd
saveamberparm Lig ${LigName}.top ${LigName}.crd
saveamberparm WidCom ${ComName}.top ${ComName}.crd
quit
EOF

#Run tleap
tleap -s -f tleap.in 1>/dev/null
mv leap.log tleap.log

#Remove Temp Files
if [ $RemoveTemp -eq 1 ];then
    rm -f tleap.in
    rm -f tleap.log
    rm -f $LigName".crd"
    rm -f $ComName".crd"
    rm -f $RecName".crd"
fi
