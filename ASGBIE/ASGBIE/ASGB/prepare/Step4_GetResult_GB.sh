#!/bin/bash
#Setting
Prefix=$PWD
Folder=${Prefix##*/}
ComName="com"                       #复合物体系名称
ComPDB=$ComName".pdb"                   #复合物PDB文件
DataFile="NearResidue.dat"              #配体周围残基文件
ResDielName="ResidueDielectric.dat"     #各残基对应的介电常数，蛋白N和C端的NH3+和COO-残基视作带电残基
DO_GB=1                                 #为1时统计ASMMGBSA结果
DO_PB=0                                 #为1时统计ASMMPBSA结果，PB计算为预留功能，未经过测试，默认不计算
OutFileGB="AlaScan_GB.dat"              #输出的ASMMGBSA结果文件
OutFilePB="AlaScan_PB.dat"              #输出的ASMMPBSA结果文件

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

#Read Dielectric Constant for Residues
TotalRes=`cat $ResDielName | wc -l`
for (( n=1; n<=${TotalRes}; n=n+1 ));do
    ResidueName[$n]=`head -n $n $ResDielName | tail -n 1 | awk '{print $1}'`
    ResidueDiel[$n]=`head -n $n $ResDielName | tail -n 1 | awk '{print $2}'`
done

#Get GB Data
if [ $DO_GB -eq 1 ];then
    echo $ComName" Alanine Scanning MMGBSA Result: --> "$OutFileGB
    rm -f $OutFileGB
    printf "%7s %9s %9s %9s %9s %9s\n" "Mut-Wid" "dVDW" "dEEL" "dGB" "dNP" "dH" | tee -a $OutFileGB
    Mutants=`cat $DataFile`
    TotalMutants=`cat $DataFile | wc -l`
    Number=0
    for mutant in $Mutants;do
        Number=$[$Number+1]
        cd ..
        mutantName=`echo ${mutant:0:3}`
        mutantID=`echo ${mutant:3}`
        if [ ${NRes[$mutantID]} = 1 ];then
            mutantName2="N"$mutantName
        elif [ ${CRes[$mutantID]} = 1 ];then
            mutantName2="C"$mutantName
        else
            mutantName2=$mutantName
        fi
        for (( n=1; n<=$TotalRes; n=n+1 ));do
            if [ ${ResidueName[$n]} = $mutantName2 ];then
                Dielectric=${ResidueDiel[$n]}
                break
            fi
        done
        cd $ComName"_"$mutantID$mutantName
        VDWm=`grep "VDWAALS" $ComName"_"$mutantName$mutantID"ALA_MMGBSA_intdiel="$Dielectric".dat" | tail -n 1 | awk '{print $2}'`
        VDWw=`grep "VDWAALS" "../Wildtype/"$ComName"_MMGBSA_intdiel="$Dielectric".dat" | tail -n 1 | awk '{print $2}'`
        dVDW[$Number]=`echo $VDWm - $VDWw | bc`
        EELm=`grep "EEL" $ComName"_"$mutantName$mutantID"ALA_MMGBSA_intdiel="$Dielectric".dat" | tail -n 1 | awk '{print $2}'`
        EELw=`grep "EEL" "../Wildtype/"$ComName"_MMGBSA_intdiel="$Dielectric".dat" | tail -n 1 | awk '{print $2}'`
        dEEL[$Number]=`echo $EELm - $EELw | bc`
        GBm=`grep "EGB" $ComName"_"$mutantName$mutantID"ALA_MMGBSA_intdiel="$Dielectric".dat" | tail -n 1 | awk '{print $2}'`
        GBw=`grep "EGB" "../Wildtype/"$ComName"_MMGBSA_intdiel="$Dielectric".dat" | tail -n 1 | awk '{print $2}'`
        dGB[$Number]=`echo $GBm - $GBw | bc`
        NPm=`grep "ESURF" $ComName"_"$mutantName$mutantID"ALA_MMGBSA_intdiel="$Dielectric".dat" | tail -n 1 | awk '{print $2}'`
        NPw=`grep "ESURF" "../Wildtype/"$ComName"_MMGBSA_intdiel="$Dielectric".dat" | tail -n 1 | awk '{print $2}'`
        dNP[$Number]=`echo $NPm - $NPw | bc`
        Hm=`grep "DELTA TOTAL" $ComName"_"$mutantName$mutantID"ALA_MMGBSA_intdiel="$Dielectric".dat" | awk '{print $3}'`
        Hw=`grep "DELTA TOTAL" "../Wildtype/"$ComName"_MMGBSA_intdiel="$Dielectric".dat" | awk '{print $3}'`
        dH[$Number]=`echo $Hm - $Hw | bc`
        cd "../"$Folder
        printf "%4s%3s %9.4f %9.4f %9.4f %9.4f %9.4f\n" $mutantID $mutantName ${dVDW[$Number]} ${dEEL[$Number]} ${dGB[$Number]} ${dNP[$Number]} ${dH[$Number]} | tee -a $OutFileGB
    done
    TdVDW=0;TdEEL=0;TdGB=0;TdNP=0;TdH=0
    for (( n=1; n<=$TotalMutants; n=n+1 ));do
        TdVDW=`echo $TdVDW + ${dVDW[$n]} | bc`
        TdEEL=`echo $TdEEL + ${dEEL[$n]} | bc`
        TdGB=`echo $TdGB + ${dGB[$n]} | bc`
        TdNP=`echo $TdNP + ${dNP[$n]} | bc`
        TdH=`echo $TdH + ${dH[$n]} | bc`
    done
    printf "%7s %9.4f %9.4f %9.4f %9.4f %9.4f\n" "TOTAL" $TdVDW $TdEEL $TdGB $TdNP $TdH | tee -a $OutFileGB
    echo ""
fi

#Get PB Data
if [ $DO_PB -eq 1 ];then
    echo $ComName" Alanine Scanning MMPBSA Result: --> "$OutFilePB
    rm -f $OutFilePB
    printf "%7s %9s %9s %9s %9s %9s\n" "Mut-Wid" "dVDW" "dEEL" "dPB" "dNP" "dH" | tee -a $OutFilePB
    Mutants=`cat $DataFile`
    TotalMutants=`cat $DataFile | wc -l`
    Number=0
    for mutant in $Mutants;do
        Number=$[$Number+1]
        cd ..
        mutantName=`echo ${mutant:0:3}`
        mutantID=`echo ${mutant:3}`
        if [ ${NRes[$mutantID]} = 1 ];then
            mutantName2="N"$mutantName
        elif [ ${CRes[$mutantID]} = 1 ];then
            mutantName2="C"$mutantName
        else
            mutantName2=$mutantName
        fi
        for (( n=1; n<=$TotalRes; n=n+1 ));do
            if [ ${ResidueName[$n]} = $mutantName2 ];then
                Dielectric=${ResidueDiel[$n]}
                break
            fi
        done
        cd $ComName"_"$mutantID$mutantName
        VDWm=`grep "VDWAALS" $ComName"_"$mutantName$mutantID"ALA_MMPBSA_indi="$Dielectric".dat" | tail -n 1 | awk '{print $2}'`
        VDWw=`grep "VDWAALS" "../Wildtype/"$ComName"_MMPBSA_indi="$Dielectric".dat" | tail -n 1 | awk '{print $2}'`
        dVDW[$Number]=`echo $VDWm - $VDWw | bc`
        EELm=`grep "EEL" $ComName"_"$mutantName$mutantID"ALA_MMPBSA_indi="$Dielectric".dat" | tail -n 1 | awk '{print $2}'`
        EELw=`grep "EEL" "../Wildtype/"$ComName"_MMPBSA_indi="$Dielectric".dat" | tail -n 1 | awk '{print $2}'`
        dEEL[$Number]=`echo $EELm - $EELw | bc`
        PBm=`grep "EPB" $ComName"_"$mutantName$mutantID"ALA_MMPBSA_indi="$Dielectric".dat" | tail -n 1 | awk '{print $2}'`
        PBw=`grep "EPB" "../Wildtype/"$ComName"_MMPBSA_indi="$Dielectric".dat" | tail -n 1 | awk '{print $2}'`
        dPB[$Number]=`echo $PBm - $PBw | bc`
        NPm=`grep "ENPOLAR" $ComName"_"$mutantName$mutantID"ALA_MMPBSA_indi="$Dielectric".dat" | tail -n 1 | awk '{print $2}'`
        NPw=`grep "ENPOLAR" "../Wildtype/"$ComName"_MMPBSA_indi="$Dielectric".dat" | tail -n 1 | awk '{print $2}'`
        dNP[$Number]=`echo $NPm - $NPw | bc`
        Hm=`grep "DELTA TOTAL" $ComName"_"$mutantName$mutantID"ALA_MMPBSA_indi="$Dielectric".dat" | awk '{print $3}'`
        Hw=`grep "DELTA TOTAL" "../Wildtype/"$ComName"_MMPBSA_indi="$Dielectric".dat" | awk '{print $3}'`
        dH[$Number]=`echo $Hm - $Hw | bc`
        cd "../"$Folder
        printf "%4s%3s %9.4f %9.4f %9.4f %9.4f %9.4f\n" $mutantID $mutantName ${dVDW[$Number]} ${dEEL[$Number]} ${dPB[$Number]} ${dNP[$Number]} ${dH[$Number]} | tee -a $OutFilePB
    done
    TdVDW=0;TdEEL=0;TdPB=0;TdNP=0;TdH=0
    for (( n=1; n<=$TotalMutants; n=n+1 ));do
        TdVDW=`echo $TdVDW + ${dVDW[$n]} | bc`
        TdEEL=`echo $TdEEL + ${dEEL[$n]} | bc`
        TdPB=`echo $TdPB + ${dPB[$n]} | bc`
        TdNP=`echo $TdNP + ${dNP[$n]} | bc`
        TdH=`echo $TdH + ${dH[$n]} | bc`
    done
    printf "%7s %9.4f %9.4f %9.4f %9.4f %9.4f\n" "TOTAL" $TdVDW $TdEEL $TdPB $TdNP $TdH | tee -a $OutFilePB
    echo ""
fi
