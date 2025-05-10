#!/bin/bash
#Setting
Prefix=$PWD
Folder=${Prefix##*/}
ComName="com"                       #复合物体系名称
ComPDB=$ComName".pdb"                   #复合物PDB文件
DataFile="NearResidue.dat"              #配体周围残基文件
ResDielName="ResidueDielectric.dat"     #残基介电常数文件
OutFile="AlaScan_IE.dat"                #输出的ASIE结果文件

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

#Get Alanine Scanning IE Result
echo $ComName" Alanine Scanning IE Result: --> "$OutFile
rm -f $OutFile
printf "%7s %9s %9s %9s %9s %9s %9s\n" "Mut-Wid" "dIE_Int" "dIE_3S" "dIE_4S" "dIE_5S" "dIE_7S" "dIE_Gau" | tee -a $OutFile
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
    #IE_Integral
    IEm=`grep -w "Avg" $ComName"_"$mutantName$mutantID"ALA""_IE_int="$Dielectric".dat" | awk '{print $2}'`
    IEw=`grep -w "Avg" $ComName"_IE_int="$Dielectric".dat" | awk '{print $2}'`
    dIE_Int[$Number]=`echo $IEm - $IEw | bc`
    #IE_3Sigma
    IEm=`grep -w "Avg" $ComName"_"$mutantName$mutantID"ALA""_IE_int="$Dielectric".dat" | awk '{print $3}'`
    IEw=`grep -w "Avg" $ComName"_IE_int="$Dielectric".dat" | awk '{print $3}'`
    dIE_3S[$Number]=`echo $IEm - $IEw | bc`
    #IE_4Sigma
    IEm=`grep -w "Avg" $ComName"_"$mutantName$mutantID"ALA""_IE_int="$Dielectric".dat" | awk '{print $4}'`
    IEw=`grep -w "Avg" $ComName"_IE_int="$Dielectric".dat" | awk '{print $4}'`
    dIE_4S[$Number]=`echo $IEm - $IEw | bc`
    #IE_5Sigma
    IEm=`grep -w "Avg" $ComName"_"$mutantName$mutantID"ALA""_IE_int="$Dielectric".dat" | awk '{print $5}'`
    IEw=`grep -w "Avg" $ComName"_IE_int="$Dielectric".dat" | awk '{print $5}'`
    dIE_5S[$Number]=`echo $IEm - $IEw | bc`
    #IE_7Sigma
    IEm=`grep -w "Avg" $ComName"_"$mutantName$mutantID"ALA""_IE_int="$Dielectric".dat" | awk '{print $6}'`
    IEw=`grep -w "Avg" $ComName"_IE_int="$Dielectric".dat" | awk '{print $6}'`
    dIE_7S[$Number]=`echo $IEm - $IEw | bc`
    #IE_Gaussian
    IEm=`grep -w "Avg" $ComName"_"$mutantName$mutantID"ALA""_IE_int="$Dielectric".dat" | awk '{print $7}'`
    IEw=`grep -w "Avg" $ComName"_IE_int="$Dielectric".dat" | awk '{print $7}'`
    dIE_Gau[$Number]=`echo $IEm - $IEw | bc`
    cd "../"$Folder
    printf "%4s%3s %9.4f %9.4f %9.4f %9.4f %9.4f %9.4f\n" $mutantID $mutantName ${dIE_Int[$Number]} ${dIE_3S[$Number]} ${dIE_4S[$Number]} ${dIE_5S[$Number]} ${dIE_7S[$Number]} ${dIE_Gau[$Number]} | tee -a $OutFile
done
TdIE_Int=0;TdIE_3S=0;TdIE_4S=0;TdIE_5S=0;TdIE_7S=0;TdIE_Gau=0
for (( n=1; n<=$TotalMutants; n=n+1 ));do
    TdIE_Int=`echo $TdIE_Int + ${dIE_Int[$n]} | bc`
    TdIE_3S=`echo $TdIE_3S + ${dIE_3S[$n]} | bc`
    TdIE_4S=`echo $TdIE_4S + ${dIE_4S[$n]} | bc`
    TdIE_5S=`echo $TdIE_5S + ${dIE_5S[$n]} | bc`
    TdIE_7S=`echo $TdIE_7S + ${dIE_7S[$n]} | bc`
    TdIE_Gau=`echo $TdIE_Gau + ${dIE_Gau[$n]} | bc`
done
printf "%7s %9.4f %9.4f %9.4f %9.4f %9.4f %9.4f\n" "TOTAL" $TdIE_Int $TdIE_3S $TdIE_4S $TdIE_5S $TdIE_7S $TdIE_Gau | tee -a $OutFile
echo ""
