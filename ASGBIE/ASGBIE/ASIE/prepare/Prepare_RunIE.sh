#!/bin/bash
#Setting
Prefix=$PWD
ComName=
ComTop=
ComMDCrd=
FirstFrame=
LastFrame=
OffsetFrame=
IEFrameRequired=
IEFrameOffset=
RecResIDStart=
RecResIDStop=
LigResIDStart=
LigResIDStop=
IntDiel=
OutFile=$ComName"_IE_int="$IntDiel".dat"
RemoveTemp=1

#Create InterEntropy.config
cat > InterEntropy.config << EOF
#configures for calculate the interaction entropy of trajectory
#file path (should end with /):
${Prefix}/
#TOP file name:
${ComTop}
#NC file name:
${ComMDCrd}
#first frame of NC file:
${FirstFrame}
#last frame of NC file:
${LastFrame}
#offset frame of NC file:
${OffsetFrame}
#continuous frames required for interaction entropy calculation:
${IEFrameRequired}
#offset frame between two interaction entropy region:
${IEFrameOffset}
#first receptor residue ID:
${RecResIDStart}
#last receptor residue ID:
${RecResIDStop}
#first ligand residue ID:
${LigResIDStart}
#last ligand residue ID:
${LigResIDStop}
#interior dielectric constant
${IntDiel}
#output file name:
${OutFile}
#end
EOF

#Run InterEntropy
rm -f $OutFile
AlaScan_InterEntropy InterEntropy.config 1>/dev/null

#Remove Temp Files
if [ $RemoveTemp -eq 1 ];then
    rm -f InterEntropy.config
fi
