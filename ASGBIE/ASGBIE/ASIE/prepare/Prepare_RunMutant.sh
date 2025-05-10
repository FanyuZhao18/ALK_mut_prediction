#!/bin/bash
#Setting
Prefix=$PWD
ComName=
MutResID=
ComPDB=
ComMDCrd=
RecName=
RecPDB=
LigName=
LigPDB=
FirstFrame=
LastFrame=
OffsetFrame=
LigNameInPDB=
LigMol2File=
LigFrcmodFile=
PBRadii=
RemoveTemp=1

#Create GetMutComPDB.config
cat > GetMutComPDB.config << EOF
#configures for get alanine mutant PDB file
#file path (should end with /):
${Prefix}/
#complex name:
${ComName}
#mutant residue ID:
${MutResID}
#wildtype complex PDB file name:
${ComPDB}
#end
EOF

#Run GetMutComPDB
rm -f $ComName"_"???$MutResID???".pdb"
AlaScan_GetMutPDB GetMutComPDB.config 1>/dev/null

#Create GetMutRecPDB.config
cat > GetMutRecPDB.config << EOF
#configures for get alanine mutant PDB file
#file path (should end with /):
${Prefix}/
#receptor name:
${RecName}
#mutant residue ID:
${MutResID}
#wildtype receptor PDB file name:
${RecPDB}
#end
EOF

#Run GetMutRecPDB
rm -f $RecName"_"???$MutResID???".pdb"
AlaScan_GetMutPDB GetMutRecPDB.config 1>/dev/null

#Get Mutant Name
MutComName=`ls $ComName"_"???$MutResID???".pdb"`
MutComName=${MutComName%.*}
MutRecName=`ls $RecName"_"???$MutResID???".pdb"`
MutRecName=${MutRecName%.*}

#Create tleap.in
cat > tleap.in << EOF
source oldff/leaprc.ff14SB
source leaprc.protein.ff14SB
source leaprc.gaff
${LigNameInPDB}=loadmol2 ${LigMol2File}
loadamberparams ${LigFrcmodFile}
MutRec=loadpdb ${MutRecName}.pdb
WidRec=loadpdb ${RecPDB}
Lig=loadpdb ${LigName}.pdb
MutCom=loadpdb ${MutComName}.pdb
WidCom=loadpdb ${ComPDB}
set default PBRadii ${PBRadii}
saveamberparm MutRec ${MutRecName}.top ${MutRecName}.crd
savepdb MutRec ${MutRecName}.pdb
saveamberparm WidRec ${RecName}.top ${RecName}.crd
saveamberparm Lig ${LigName}.top ${LigName}.crd
saveamberparm MutCom ${MutComName}.top ${MutComName}.crd
savepdb MutCom ${MutComName}.pdb
saveamberparm WidCom ${ComName}.top ${ComName}.crd
quit
EOF

#Run tleap
tleap -s -f tleap.in 1>/dev/null
mv leap.log tleap.log

#Create GetMutMDCrd.config
cat > GetMutMDCrd.config << EOF
#configures for get alanine mutant NC file
#file path (should end with /):
${Prefix}/
#complex name:
${ComName}
#mutant residue ID:
${MutResID}
#wildtype complex PDB file name:
${ComPDB}
#wildtype complex NC file name:
${ComMDCrd}
#first frame of NC file:
${FirstFrame}
#last frame of NC file:
${LastFrame}
#offset frame of NC file:
${OffsetFrame}
#end
EOF

#Run GetMutMDCrd
rm -f $ComName"_"???$MutResID???".nc"
AlaScan_GetMutMDCrd GetMutMDCrd.config 1>/dev/null

#Remove Temp Files
if [ $RemoveTemp -eq 1 ];then
    rm -f GetMutComPDB.config
    rm -f GetMutRecPDB.config
    rm -f tleap.in
    rm -f tleap.log
    rm -f $MutComName".crd"
    rm -f $MutRecName".crd"
    rm -f $LigName".crd"
    rm -f $ComName".crd"
    rm -f $RecName".crd"
    rm -f GetMutMDCrd.config
fi
