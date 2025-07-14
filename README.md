# metaClean (Short reads) - Cleaning raw metagenomes
[Snakemake](https://snakemake.readthedocs.io/en/stable/getting_started/installation.html) workflow to eliminate low-quality reads and human contamination from metagenomes. 

The user provides a path to raw (short-read) metagenomes to clean. The workflow runs `fastp` to eliminate low-quality reads (<20QC) and `bowtie2`/`samtools` to remove human contamination. This workflow eliminates raw reads and intermediate files for space efficiency purposes. The output of this workflow is clean, compressed metagenomes. 

## Installation

1. Install [conda](https://docs.conda.io/projects/conda/en/latest/user-guide/install/index.html).
   
3. Create a conda environment
   
<pre><code>conda create -n snakemake-7.3.7 python=3.10 -y 
conda activate snakemake-7.3.7</code></pre> 

3. Install snakemake v7.3.7 (using conda or mamba, a faster conda alternative)

<pre><code>conda create -n snakemake-7.3.7 -c conda-forge -c bioconda snakemake=7.3.7</code></pre>

If you don't have access to bioconda, you can also try installing this using `pip`

<pre><code>pip install snakemake==7.3.7</code></pre>

4. Clone the repository

<pre><code>git clone https://github.com/luisgv467/metaCleaning.git</code></pre>

## How to Run

### Prepare your files before running

1. Download the latest version of the human genome (GRCh38)

<pre><code>wget https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/001/405/GCF_000001405.40_GRCh38.p14/GCF_000001405.40_GRCh38.p14_genomic.fna.gz
gunzip GCF_000001405.40_GRCh38.p14_genomic.fna.gz</code></pre>

2. Build a `Bowtie2` index

Create and go to your index directory

<pre><code>mkdir index 
cd index</code></pre>

Build `Bowtie2` index
<pre><code> bowtie2-build ../GRCh38.genomic.fna host_DB </code></pre>

## Run snakemake workflow

1. Get a file with the file paths of paired raw metagenomes you want to clean. Metagenomes should be compressed (`.gz`) and have a `_1.fastq.gz`/`_2.fastq.gz` extension. 

<pre><code> ls path_to_raw_reads/*_2.fastq.gz | sed -e 's|path_to_raw_reads/||' -e 's|_2.fastq.gz||' > metagenome_paths.txt </pre></code> 

2. Modify the `config/config.yml` with your input and output locations

<pre><code># Required arguments

#File with sample paths
input:
    "path_to_file_with_sample_paths/metagenome_paths.txt" 

#Path of raw metagenomes
input_path:
    "paths_to_raw_reads/" 

#output directory to store results
output:
    "ouput_path_of_clean_reads/Results" </pre></code>

3. Run Snakemake

If using a server:
<pre><code>snakemake --use-conda -k -j 100 --profile config/lfs --rerun-incomplete --latency-wait 120 --scheduler greedy </pre></code>

If running locally:
<pre><code>snakemake --use-conda -k -j 10 --rerun-incomplete --latency-wait 60 </pre></code>

## Output

The downloaded fastqs will be located in the directory `Results/`. You will also find a file called `Number_reads.txt` with the read count of all your clean metagenomes.  




