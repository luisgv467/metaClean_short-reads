 #Snakemake workflow for cleaning raw metagenomes 

import os

#Preparing files 

configfile: "config/config.yml"

INPUT = config["input"]
OUTPUT = config["output"]
INPUT_PATH = config["input_path"]

with open(INPUT) as f:
    SAMPLES = [line.strip() for line in f if line.strip()]

###### Protocol ######

rule all:
	input:
		expand("{sample}-all_done.txt", sample=SAMPLES)

rule fastp:
	params:
		fwd = INPUT_PATH+"{sample}_1.fastq.gz",
		rev = INPUT_PATH+"{sample}_2.fastq.gz"
	output:
		fwd_clean = OUTPUT+"{sample}-R1.fastq.gz",
		rev_clean = OUTPUT+"{sample}-R2.fastq.gz",
		flag = "{sample}-fastp_done.txt"
	conda:
		"envs/metaclean.yml"
	shell:
		"""
		fastp \
  		-i {params.fwd} \
  		-I {params.rev} \
  		-o {output.fwd_clean} \
  		-O {output.rev_clean} \
  		--length_required 70 \
  		-w 5
  		rm {params.fwd}
  		rm {params.rev}
  		touch {output.flag}
		"""

rule bowtie2:
	input:
		"{sample}-fastp_done.txt"
	params:
		fwd_clean = OUTPUT+"{sample}-R1.fastq.gz",
		rev_clean = OUTPUT+"{sample}-R2.fastq.gz"
	output:
		sam = OUTPUT+"{sample}-SAMPLE_mapped_and_unmapped.sam",
		flag = "{sample}-bowtie_done.txt"
	conda:
		"envs/metaclean.yml"
	shell:
		"""
		bowtie2 -x index/host_DB \
  		-1 {params.fwd_clean} \
  		-2 {params.rev_clean} \
  		-p 24 \
  		--very-sensitive \
  		-S {output.sam}
  		rm {params.fwd_clean}
  		rm {params.rev_clean}
  		touch {output.flag}
  		"""

rule samtools_sam_to_bam:
	input:
		"{sample}-bowtie_done.txt"
	params:
		OUTPUT+"{sample}-SAMPLE_mapped_and_unmapped.sam"
	output:
		bam = OUTPUT+"{sample}-SAMPLE_mapped_and_unmapped.bam",
		flag = "{sample}-sam_to_bam_done.txt"
	conda:
		"envs/metaclean.yml"
	shell:
		"""
		samtools view \
  		-bS {params} \
  		--threads 4 \
  		-o {output.bam}
  		rm {params}
  		touch {output.flag}
		"""

rule samtools_retain_unmapped_reads:
	input:
		"{sample}-sam_to_bam_done.txt"
	params:
		OUTPUT+"{sample}-SAMPLE_mapped_and_unmapped.bam"
	output:
		bam = OUTPUT+"{sample}-SAMPLE_bothEndsUnmapped.bam",
		flag = "{sample}-retain_unmapped_reads_done.txt"
	conda:
		"envs/metaclean.yml"
	shell:
		"""
		samtools view -b \
 		-f 4 \
  		--threads 4 \
  		{params} \
  		-o {output.bam}
  		rm {params}
  		touch {output.flag}
  		"""

rule samtools_sort_bam: 
	input:
		"{sample}-retain_unmapped_reads_done.txt"
	params:
		OUTPUT+"{sample}-SAMPLE_bothEndsUnmapped.bam"
	output:
		bam = OUTPUT+"{sample}-SAMPLE_bothEndsUnmapped_sorted.bam",
		flag = "{sample}-sorted_bam_done.txt"
	conda:
		"envs/metaclean.yml"
	shell:
		"""
		samtools sort \
  		--threads 4 \
  		-o {output.bam} \
		-n {params} 
  		rm {params}
  		touch {output.flag}
  		"""

rule samtools_clean_fastqs:
	input:
		"{sample}-sorted_bam_done.txt"
	params:
		OUTPUT+"{sample}-SAMPLE_bothEndsUnmapped_sorted.bam"
	output:
		fwd = OUTPUT+"{sample}_1.fastq.gz",
		rev = OUTPUT+"{sample}_2.fastq.gz",
		flag = "{sample}-all_done.txt"
	conda:
		"envs/metaclean.yml"
	shell:
		"""
		samtools fastq \
		-0 /dev/null \
		-1 {output.fwd} \
		-2 {output.rev} \
		-N  {params} \
		--threads 4
		rm {params}
		touch {output.flag}
		"""




