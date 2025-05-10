#!/bin/bash
#Setting
Prefix=$PWD
Folder=${Prefix##*/}
ComName="com"                                                       #复合物体系名称
ComPDB=$ComName".pdb"                                                   #复合物PDB文件
ComMDCrd="md.nc"                                     #野生型复合物无水轨迹文件，轨迹必须为NetCDF格式
RecName="pro"                                                           #受体名称
RecPDB=$RecName".pdb"                                                   #受体PDB文件
LigName="lig"                                                           #配体名称
LigPDB=$LigName".pdb"                                                   #配体PDB文件
LigNameInPDB="TPX"                                                      #PDB文件中的配体残基三字符名称
LigMol2File="lig.mol2"                                           #tleap中所需的带电荷的gaff原子类型的配体mol2文件
LigFrcmodFile="lig.frcmod"                                              #tleap中所需的配体frcmod文件
PBRadii="mbondi2"                                                       #原子GB半径，使用igb=2时应该使用mbondi2半径
RecResIDStart=1           
RecResIDStop=309                                           #受体起始残基号
#RecResIDStop=`grep "ATOM" $RecPDB | tail -n 1 | awk '{print $5}'`       #受体终止残基号
LigResIDStart=$[$RecResIDStop+1]                                        #配体起始残基号
LigResIDStop=$[$RecResIDStop+1]                                         #配体终止残基号
MaxDistance=5.0                                                         #计算在初始复合物PDB文件中距离配体不大于MaxDistance的受体残基（残基中任一原子到配体中任一原子的距离小于等于MaxDistance时就计算该残基）
OutDataFile="NearResidue.dat"                                           #用于存储配体的周围受体残基
ResDielName="ResidueDielectric.dat"                                     #各残基对应的介电常数，蛋白N和C端的NH3+和COO-残基视作带电残基
FrameStart=500                                                         #待计算的轨迹起始帧数
FrameStop=1500                                                         #待计算的轨迹终止帧数
FrameOffset=1                                                           #待计算的轨迹帧间隔数
TotalFrame=$[($FrameStop-$FrameStart)/$FrameOffset+1]                   #待计算的总帧数
IEFrameRequired=200                                                    #单次IE计算的连续帧数（将轨迹分为若干段，分别计算IE再进行平均，从而避免单个过大的IE值对整体过大的影响）
IEFrameOffset=200                                                      #两次IE计算的起始帧的间隔帧数
RemoveTemp=1                                                            #为1时删除中间文件

#Get N Head and C Tail Residue
ResNumber=`grep "ATOM" $ComPDB | tail -n 1 | awk '{print $5}'`
for ((i=1;i<=$ResNumber;i++));do
    NRes[$i]=0
    CRes[$i]=0
done
while read -r Line;do
    if [ ${Line:0:4} == "ATOM" ];then
        ResName=${Line:17:3}
        ResID=${Line:22:4}
        AtomName=${Line:12:4}
        ResName=${ResName// /}
        ResID=${ResID// /}
        AtomName=${AtomName// /}
        case $ResName in
            "GLY" | "ALA" | "VAL" | "LEU" | "ILE" | "PHE" | "TRP" | "TYR" | "ASP" | "ASH" | "ASN" | "GLU" | "GLH" | "LYS" | "LYN" | "GLN" | "MET" | "SER" | "THR" | "CYS" | "CYX" | "CYM" | "HIE" | "HID" | "HIP" | "ARG" | "PRO")
                if [ "$AtomName" == "H2" ];then
                    NRes[$ResID]=1
                fi
                if [ "$AtomName" == "OXT" ];then
                    CRes[$ResID]=1
                fi
            ;;
        esac
    fi
done < $ComPDB

#Create GetNearResidue.config
cat > GetNearResidue.config << EOF
#configures for get receptor residue near ligand
#file path (should end with /):
${Prefix}/
#complex name:
${ComName}
#wildtype complex PDB file name:
${ComPDB}
#receptor start residue ID:
${RecResIDStart}
#receptor stop residue ID:
${RecResIDStop}
#ligand start residue ID:
${LigResIDStart}
#ligand stop residue ID:
${LigResIDStop}
#maximum distance between receptor and ligand atom:
${MaxDistance}
#output data file name:
${OutDataFile}
#end
EOF

#Run GetNearResidue
rm -f $OutDataFile
AlaScan_GetNearResidue GetNearResidue.config 1>/dev/null

#Read Dielectric Constant for Residues
TotalRes=`cat $ResDielName | wc -l`
for (( n=1; n<=${TotalRes}; n=n+1 ));do
    ResidueName[$n]=`head -n $n $ResDielName | tail -n 1 | awk '{print $1}'`
    ResidueDiel[$n]=`head -n $n $ResDielName | tail -n 1 | awk '{print $2}'`
done

#Prepare Files
Mutants=`cat $OutDataFile`
for mutant in $Mutants;do
    cd ..
    mutantName=`echo ${mutant:0:3}`
    mutantID=`echo ${mutant:3}`
    rm -rf $ComName"_"$mutantID$mutantName
    mkdir $ComName"_"$mutantID$mutantName
    cd $ComName"_"$mutantID$mutantName
    if [ ${NRes[$mutantID]} = 1 ];then
        mutantName2="N"$mutantName
    elif [ ${CRes[$mutantID]} = 1 ];then
        mutantName2="C"$mutantName
    else
        mutantName2=$mutantName
    fi
    ln -s "../"$Folder"/"$ComPDB .
    ln -s "../"$Folder"/"$ComMDCrd .
    ln -s "../"$Folder"/"$RecPDB .
    ln -s "../"$Folder"/"$LigPDB .
    #RunMutant.sh
    cp "../"$Folder"/Prepare_RunMutant.sh" RunMutant.sh
    sed -i -e "1,/ComName=/s/ComName=/&\"${ComName}\"/" RunMutant.sh
    sed -i -e "1,/MutResID=/s/MutResID=/&${mutantID}/" RunMutant.sh
    sed -i -e "1,/ComPDB=/s/ComPDB=/&\"${ComPDB}\"/" RunMutant.sh
    sed -i -e "1,/ComMDCrd=/s/ComMDCrd=/&\"${ComMDCrd}\"/" RunMutant.sh
    sed -i -e "1,/RecName=/s/RecName=/&\"${RecName}\"/" RunMutant.sh
    sed -i -e "1,/RecPDB=/s/RecPDB=/&\"${RecPDB}\"/" RunMutant.sh
    sed -i -e "1,/LigName=/s/LigName=/&\"${LigName}\"/" RunMutant.sh
    sed -i -e "1,/LigPDB=/s/LigPDB=/&\"${LigPDB}\"/" RunMutant.sh
    sed -i -e "1,/FirstFrame=/s/FirstFrame=/&${FrameStart}/" RunMutant.sh
    sed -i -e "1,/LastFrame=/s/LastFrame=/&${FrameStop}/" RunMutant.sh
    sed -i -e "1,/OffsetFrame=/s/OffsetFrame=/&${FrameOffset}/" RunMutant.sh
    sed -i -e "1,/LigNameInPDB=/s/LigNameInPDB=/&\"${LigNameInPDB}\"/" RunMutant.sh
    sed -i -e "1,/LigMol2File=/s/LigMol2File=/&\"..\/${Folder}\/${LigMol2File}\"/" RunMutant.sh
    sed -i -e "1,/LigFrcmodFile=/s/LigFrcmodFile=/&\"..\/${Folder}\/${LigFrcmodFile}\"/" RunMutant.sh
    sed -i -e "1,/PBRadii=/s/PBRadii=/&\"${PBRadii}\"/" RunMutant.sh
    #RunIE_Wid.sh
    cp "../"$Folder"/Prepare_RunIE.sh" RunIE_Wid.sh
    sed -i -e "1,/ComName=/s/ComName=/&\"${ComName}\"/" RunIE_Wid.sh
    sed -i -e "1,/ComTop=/s/ComTop=/&\$ComName\".top\"/" RunIE_Wid.sh
    sed -i -e "1,/ComMDCrd=/s/ComMDCrd=/&\"${ComMDCrd}\"/" RunIE_Wid.sh
    sed -i -e "1,/FirstFrame=/s/FirstFrame=/&${FrameStart}/" RunIE_Wid.sh
    sed -i -e "1,/LastFrame=/s/LastFrame=/&${FrameStop}/" RunIE_Wid.sh
    sed -i -e "1,/OffsetFrame=/s/OffsetFrame=/&${FrameOffset}/" RunIE_Wid.sh
    sed -i -e "1,/IEFrameRequired=/s/IEFrameRequired=/&${IEFrameRequired}/" RunIE_Wid.sh
    sed -i -e "1,/IEFrameOffset=/s/IEFrameOffset=/&${IEFrameOffset}/" RunIE_Wid.sh
    sed -i -e "1,/RecResIDStart=/s/RecResIDStart=/&${mutantID}/" RunIE_Wid.sh
    sed -i -e "1,/RecResIDStop=/s/RecResIDStop=/&${mutantID}/" RunIE_Wid.sh
    sed -i -e "1,/LigResIDStart=/s/LigResIDStart=/&${LigResIDStart}/" RunIE_Wid.sh
    sed -i -e "1,/LigResIDStop=/s/LigResIDStop=/&${LigResIDStop}/" RunIE_Wid.sh
    for (( n=1; n<=${TotalRes}; n=n+1 ));do
        if [ ${ResidueName[$n]} = $mutantName2 ];then
            sed -i -e "1,/IntDiel=/s/IntDiel=/&${ResidueDiel[$n]}/" RunIE_Wid.sh
            break
        fi
    done
    #RunIE_Mut.sh
    cp "../"$Folder"/Prepare_RunIE.sh" RunIE_Mut.sh
    sed -i -e "1,/ComName=/s/ComName=/&\"${ComName}_${mutantName}${mutantID}ALA\"/" RunIE_Mut.sh
    sed -i -e "1,/ComTop=/s/ComTop=/&\$ComName\".top\"/" RunIE_Mut.sh
    sed -i -e "1,/ComMDCrd=/s/ComMDCrd=/&\$ComName\".nc\"/" RunIE_Mut.sh
    sed -i -e "1,/FirstFrame=/s/FirstFrame=/&1/" RunIE_Mut.sh
    sed -i -e "1,/LastFrame=/s/LastFrame=/&${TotalFrame}/" RunIE_Mut.sh
    sed -i -e "1,/OffsetFrame=/s/OffsetFrame=/&1/" RunIE_Mut.sh
    sed -i -e "1,/IEFrameRequired=/s/IEFrameRequired=/&${IEFrameRequired}/" RunIE_Mut.sh
    sed -i -e "1,/IEFrameOffset=/s/IEFrameOffset=/&${IEFrameOffset}/" RunIE_Mut.sh
    sed -i -e "1,/RecResIDStart=/s/RecResIDStart=/&${mutantID}/" RunIE_Mut.sh
    sed -i -e "1,/RecResIDStop=/s/RecResIDStop=/&${mutantID}/" RunIE_Mut.sh
    sed -i -e "1,/LigResIDStart=/s/LigResIDStart=/&${LigResIDStart}/" RunIE_Mut.sh
    sed -i -e "1,/LigResIDStop=/s/LigResIDStop=/&${LigResIDStop}/" RunIE_Mut.sh
    for (( n=1; n<=${TotalRes}; n=n+1 ));do
        if [ ${ResidueName[$n]} = $mutantName2 ];then
            sed -i -e "1,/IntDiel=/s/IntDiel=/&${ResidueDiel[$n]}/" RunIE_Mut.sh
            break
        fi
    done
    cd "../"$Folder
done

#Remove Temp Files
if [ $RemoveTemp -eq 1 ];then
    rm -f GetNearResidue.config
fi
