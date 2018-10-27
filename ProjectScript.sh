#!/bin/bash

clear
echo "Start of Script"
echo -e "----------------\n"

echo "Checking if BamFiles directory exists"
if [ ! -d "BamFiles" ]; then
	mkdir BamFiles
	echo -e "Created BamFiles\n"
fi

echo "Checking if ReferenceGenome directory exists"
if [ ! -d "ReferenceGenome" ]; then
	mkdir ReferenceGenome
	echo -e "Created ReferenceGenome\n"
fi

echo "Checking if VCF directory exists"
if [ ! -d "VCF" ]; then
	mkdir VCF
	echo -e "Created VCF\n"
fi

echo "Cleaning BamFiles directory"
rm -rf ~/Project1/BamFiles/*

cd BamFiles

echo "Checking if SortedBamFiles directory exists"
mkdir SortedBamFiles
echo -e "Created SortedBamFiles\n"

echo "Checking if SortedNoDuplicatesBamFiles directory exists"
mkdir SortedNoDuplicatesBamFiles
echo -e "Created SortedNoDuplicatesBamFiles\n"

cd ..


echo "Cleaning SortedNoDuplicatesBamFiles directory"
rm -rf ~/Project1/BamFiles/SortedNoDuplicatesBamFiles/*
echo "Cleaning SortedBamFiles directory"
rm -rf ~/Project1/BamFiles/SortedBamFiles/*
echo "Cleaning ReferenceGenome directory"
rm -rf ~/Project1/ReferenceGenome/*
echo "Cleaning VCF directory"
rm -rf ~/Project1/VCF/*

cd VCF
mkdir FinishedVCF
echo -e "Created FinishedVCF\n"
cd ..


echo -e  "\nStarting BWA Indexing"
cp ~/Project1/Resources/ref_genome.fasta ~/Project1/ReferenceGenome/ref_genome.fasta
bwa index ~/Project1/ReferenceGenome/ref_genome.fasta
echo "Finished BWA Indexing"

echo -e "\nStarting BWA MEM"
echo "----------------"
for fastq in /projects/micb405/resources/project_1/*_1.fastq.gz;
do
  prefix=$(basename $fastq | sed 's/_1.fastq.gz//g')
  echo -e "\nAnalyzing $prefix"
  bwa mem ~/Project1/ReferenceGenome/ref_genome.fasta \
  /projects/micb405/resources/project_1/$prefix\_1.fastq.gz /projects/micb405/resources/project_1/$prefix\_2.fastq.gz | \
  samtools view -b - >~/Project1/BamFiles/$prefix.bam
  echo -e "\nBinary Conversion Complete"
  samtools sort ~/Project1/BamFiles/$prefix.bam -o ~/Project1/BamFiles/SortedBamFiles/$prefix.sorted.bam
  echo -e "\nSorting Complete"
  samtools rmdup ~/Project1/BamFiles/SortedBamFiles/$prefix.sorted.bam ~/Project1/BamFiles/SortedNoDuplicatesBamFiles/$prefix.sorted.rmdup.bam
  echo -e "\nDuplicate Removal Complete"
  samtools index ~/Project1/BamFiles/SortedNoDuplicatesBamFiles/$prefix.sorted.rmdup.bam
  echo -e "\nBAM Indexing Complete"
  bcftools mpileup --fasta-ref ~/Project1/ReferenceGenome/ref_genome.fasta ~/Project1/BamFiles/SortedNoDuplicatesBamFiles/$prefix.sorted.rmdup.bam \
    | bcftools call -mv - > ~/Project1/VCF/$prefix.vcf
  echo -e "\nmpileup Complete"
done

python ~/Project1/Resources/vcf_to_fasta_het.py -x ~/Project1/VCF/ finished_vcf
mv ~/Project1/VCF/finished_vcf* ~/Project1/VCF/FinishedVCF/
FastTree ~/Project1/VCF/FinishedVCF/finished_vcf.fasta > ~/Project1/finished_vcf.nwk

exit 0