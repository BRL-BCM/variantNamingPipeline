# Variant Naming Pipeline

---
This pipeline will facilitate variant querying and naming process with ClinGen Allele Registry.

## Getting Started

---
An user account is required for variant naming.  You can create an account at [ClinGen Allele Registry](http://reg.clinicalgenome.org/redmine/projects/registry/genboree_registry/landing) (CAR).
- Save the username and password in a file on the same line with the format [User Login]:[Pasword]
- You can either provide the path of the file with the parameter [-l|--login] or you can modify the variable: `loginFile` on line 29

##Requirements

---
 - Ruby version 1.8.7 or higher
 - Standard libraries are utilized
 ```
require 'net/http'
require 'digest/sha1'
require 'optparse'
require 'json'
require 'time'
require 'zlib'
```

## Usage

---
```
Usage:  ruby variantNamingPipeline.rb [options]
        Default is set on querying the variants instead of naming the variants.
        Input is set on VCF format unless [-g|--gtex] is specified.
    -n, --name                       Naming/registering the variants in Allele Registry
    -g, --gtex                       Using GTEx s/eQTL files as input (input will be assumed to be a VCF if this is not set)
        --gz                         Use this flag to indicate the input is gzipped
    -r, --ref reference              reference genome for the input file [hg19|grch37 or hg38|grch38] (default at hg38)
    -b, --block blockNumber          Querying/Naming in blocks in large inputs, Default is at 10000
    -i, --input inputPath            Path to the input file
    -o, --out outputPath             Designate output path (default at the current locaiton)
    -w, --work workingPath           Designate working directory for the intermediate files (default is set as tmp under outputPath
    -s, --summary                    Creates the summary report at the end (optional)
    -l, --login filePath             Path to the file which contains user login information (one line in [username]:[pw] format)
    -h, --help                       Display this screen
```

If you would like to know how many variants in the VCF that has not been regsitered in the Allele Registry, please query the variants with the `-s` option prior to naming the variants.

###Querying Variants
Querying variants will check the variants against CAR and return CAids for the ones that have been named.
```
ruby variantNamingPipeline.rb -r hg38 -i input.vcf -s
```
###Naming Variants
Naming variants will try to register/name the variants and return the CAids after the process. (-n flag)
```
ruby variantNamingPipeline.rb -n -r hg38 -i input.vcf
```
###Optional Parameters
Compressed gz files can be handled using `--gz` flag to indicate the input file is a gz file

Although the pipeline is not expected to run on a cluster, but you can utilize `-w` flag to point to the local disk for the node and have the output directed to another directory using `-o` flag

The process of query/naming varaints is made to ClinGen Allele Registry with either PUT/POST commands, you can try to optimize the network traffic by either increase/decrease the size of the package sent via network at one time.  Default is set at 10000 lines and this could be changed by using `-b` or `-block` flag to pass in the desired amount.

The intermediate block files will be sorted prior to access the Allele Registry to speed up the whole processes.

Summary report can be generated with `-s` flag.  It can provide some logistic information regarding to the VCF after either querying or naming process has completed. (The additional gathering of the information can compromise the overall speed)

## Input Files

---
### VCF Input

File format is required in the meta-information line. 
```
##fileformat=VCFv4.x
```
Header line (Tab-delimited) is required following the meta-information lines before the data lines. 

- \#CHROM
- POS 
- ID  
- REF 
- ALT 
- QUAL
- FILTER INFO

Example of a VCF file
```
##fileformat=VCFv4.1
##fileDate=20161130
##source=freeBayes v0.9.21-7-g7dd41db
##source=10X/pipelines/stages/snpindels/attach_bcs_snpindels 2.1.2
##source=10X/pipelines/stages/snpindels/phase_snpindels 2.1.2
##reference=/isilon/seq/schatz/encode_05_2016_phase3/refdata-GRCh38_no_alt_analysis_set_GCA_000001405.15/fasta/genome.fa
##phasing=none
...
##FILTER=<ID=10X_HOMOPOLYMER_UNPHASED_INSERTION,Description="Unphased insertions in homopolymer regions tend to be false positives">
##CHROM POS     ID      REF     ALT     QUAL    FILTER  INFO    FORMAT
1       10327   .       T       C       75.7304 PASS    NS=1;DP=39;DPB=39.0;AC=1;AN=2;AF=0.5;RO=110;AO=107;PRO=0.0;PAO=0.0;QR=859;QA=307;PQR=0.0;PQA=0.0;SRF=2;SRR=24;SAF=0;SAR=11;SRP=43.4331;SAP=26.8965;AB=0.282051;ABP=19.1015;RUN=1;RPP=3.20771;RPPR=15.0369;RPL=5.0;RPR=6.0;EPP=3.20771;EPPR=15.0369;DPRA=0.0;ODDS=17.4376;GTI=0;TYPE=snp;CIGAR=1X;NUMALT=1;MEANALT=2.0;LEN=1;MQM=50.8182;MQMR=50.7308;PAIRED=0.818182;PAIREDR=0.538462;technology.ILLUMINA=1.0;MUMAP_REF=28.3992;MUMAP_ALT=44.8333;MMD=1.27273;RESCUED=149;NOT_RESCUED=237;HAPLOCALLED=0 GT:DP:PS:PQ:PD  0|1:39:10327:18:4
1       11542   .       A       T       59.5288 PASS    NS=1;DP=5;DPB=5.0;AC=1;AN=2;AF=0.5;RO=1;AO=4;PRO=0.0;PAO=0.0;QR=36;QA=144;PQR=0.0;PQA=0.0;SRF=1;SRR=0;SAF=4;SAR=0;SRP=5.18177;SAP=11.6962;AB=0.8;ABP=6.91895;RUN=1;RPP=11.6962;RPPR=5.18177;RPL=0.0;RPR=4.0;EPP=11.6962;EPPR=5.18177;DPRA=0.0;ODDS=3.74846;GTI=0;TYPE=snp;CIGAR=1X;NUMALT=1;MEANALT=1.0;LEN=1;MQM=45.25;MQMR=51.0;PAIRED=0.5;PAIREDR=0.0;technology.ILLUMINA=1.0;MUMAP_REF=5.42105;MUMAP_ALT=41.4;MMD=1.07333;RESCUED=3;NOT_RESCUED=21;HAPLOCALLED=0    GT:DP:PS:PQ:PD  0|1:5:10327:100:5
```
### eQTL/sQTL Input
The following fields are required in the first line as the header column (tab-delimited)

 - variant_id
 - chr 
 - variant_pos 
 - ref 
 - alt

Example of an eQTL file
``` 
gene_id gene_name       gene_chr        gene_start      gene_end        strand  num_var beta_shape1     beta_shape2     true_df pval_true_df    variant_id      tss_distance    chr     variant_pos     ref     alt     num_alt_per_site        rs_id_dSNP151_GRCh38p7 minor_allele_samples    minor_allele_count      maf     ref_factor      pval_nominal    slope   slope_se        pval_perm       pval_beta       qval    pval_nominal_threshold  log2_aFC        log2_aFC_lower  log2_aFC_upper
ENSG00000227232.5       WASH7P  chr1    14410   29553   -       1364    1.02638 311.223 155.695 0.000704166     chr1_139393_G_T_b38     109840  chr1    139393  G       T       1       rs374474555     18      18      0.0432692       1       0.00043046     0.707137        0.196914        0.190051        0.186735        0.186765        0.000100266     0.821879        0.459859        1.050541
ENSG00000268903.1       RP11-34P13.15   chr1    135141  135895  -       1863    1.05785 360.12  152.693 0.00030453      chr1_108826_G_C_b38     -27069  chr1    108826  G       C       1       rs62642117      23      23      0.0552885       1
       0.000151455     0.643308        0.165928        0.090091        0.0889798       0.116833        9.75631e-05     1.346428        0.824443        1.796007
ENSG00000269981.1       RP11-34P13.16   chr1    137682  137965  -       1868    1.02634 333.712 151.167 0.000219502     chr1_108826_G_C_b38     -29139  chr1    108826  G       C       1       rs62642117      23      23      0.0552885       1
       9.76311e-05     0.700484        0.17546 0.0641936       0.0651666       0.094553        9.34949e-05     1.412633        0.832862        1.883766
```
##Output Files

---
There will be 3 types of standard output files: *_CAid*, *_noCAid*, *_summary* 
- *_CAid* - contains original input and a new column CAid. (Does not include the ones that could not be registered/named)
- *_noCAid* - contains the variants which could not be registered/named
  - It may contain just the meta-information lines and header lines when all variants have been named.
- *_summary* - summary report of the variants (when [-s|--summary] flag is used)

Error output will be directed to *_Error* file which contains error information given by the ClinGen Allele Registry.
## Benchmark

---
Against ~32k variants, chunks of 10000 at one time. 
```
$ wc -l sample_kf_variants.vcf
32231 sample_kf_variants.vcf
$ time ruby variantNamingPipeline.rb -r hg38 -i sample_kf_variants.vcf  -s 
[2021-12-17T10:26:35] Create an intermediate VCF: /mnt/brlstor/Vol6_SP/cfde/kidsfirst/test/tmp/sample_kf_variants_CARmod from the input: ../sample_kf_variants.vcf
[2021-12-17T10:26:35] Collecting variants for /mnt/brlstor/Vol6_SP/cfde/kidsfirst/test/tmp/sample_kf_variants_CARmod_tmp-1
[2021-12-17T10:26:36] Calling ClinGen Allele Registry for data in /mnt/brlstor/Vol6_SP/cfde/kidsfirst/test/tmp/sample_kf_variants_CARmod_tmp-1
[2021-12-17T10:26:39] Creating summary file: /mnt/brlstor/Vol6_SP/cfde/kidsfirst/test/tmp/sample_kf_variants_CARmod_tmp-1_summary.txt
[2021-12-17T10:26:39] Creating CAid file: /mnt/brlstor/Vol6_SP/cfde/kidsfirst/test/tmp/sample_kf_variants_CARmod_tmp-1_CAid.vcf
[2021-12-17T10:26:39] Collecting variants for /mnt/brlstor/Vol6_SP/cfde/kidsfirst/test/tmp/sample_kf_variants_CARmod_tmp-2
[2021-12-17T10:26:42] Calling ClinGen Allele Registry for data in /mnt/brlstor/Vol6_SP/cfde/kidsfirst/test/tmp/sample_kf_variants_CARmod_tmp-2
[2021-12-17T10:26:45] Creating summary file: /mnt/brlstor/Vol6_SP/cfde/kidsfirst/test/tmp/sample_kf_variants_CARmod_tmp-2_summary.txt
[2021-12-17T10:26:45] Creating CAid file: /mnt/brlstor/Vol6_SP/cfde/kidsfirst/test/tmp/sample_kf_variants_CARmod_tmp-2_CAid.vcf
[2021-12-17T10:26:45] Collecting variants for /mnt/brlstor/Vol6_SP/cfde/kidsfirst/test/tmp/sample_kf_variants_CARmod_tmp-3
[2021-12-17T10:26:49] Calling ClinGen Allele Registry for data in /mnt/brlstor/Vol6_SP/cfde/kidsfirst/test/tmp/sample_kf_variants_CARmod_tmp-3
[2021-12-17T10:26:52] Creating summary file: /mnt/brlstor/Vol6_SP/cfde/kidsfirst/test/tmp/sample_kf_variants_CARmod_tmp-3_summary.txt
[2021-12-17T10:26:52] Creating CAid file: /mnt/brlstor/Vol6_SP/cfde/kidsfirst/test/tmp/sample_kf_variants_CARmod_tmp-3_CAid.vcf
[2021-12-17T10:26:52] Collecting variants for /mnt/brlstor/Vol6_SP/cfde/kidsfirst/test/tmp/sample_kf_variants_CARmod_tmp-4
[2021-12-17T10:26:52] Calling ClinGen Allele Registry for data in /mnt/brlstor/Vol6_SP/cfde/kidsfirst/test/tmp/sample_kf_variants_CARmod_tmp-4
[2021-12-17T10:26:53] Creating summary file: /mnt/brlstor/Vol6_SP/cfde/kidsfirst/test/tmp/sample_kf_variants_CARmod_tmp-4_summary.txt
[2021-12-17T10:26:53] Creating CAid file: /mnt/brlstor/Vol6_SP/cfde/kidsfirst/test/tmp/sample_kf_variants_CARmod_tmp-4_CAid.vcf
[2021-12-17T10:26:53] Merging *_CAid* intermediate files in: /mnt/brlstor/Vol6_SP/cfde/kidsfirst/test/tmp
[2021-12-17T10:26:53] Merging *_noCAid* intermediate files in: /mnt/brlstor/Vol6_SP/cfde/kidsfirst/test/tmp
[2021-12-17T10:26:53] Merging summary intermediate files in: /mnt/brlstor/Vol6_SP/cfde/kidsfirst/test/tmp
[2021-12-17T10:26:53] Creating final summary file: /mnt/brlstor/Vol6_SP/cfde/kidsfirst/test/sample_kf_variants_summary.txt
[2021-12-17T10:26:53] Clean up:
[2021-12-17T10:26:53] Removing files in /mnt/brlstor/Vol6_SP/cfde/kidsfirst/test/tmp
[2021-12-17T10:26:53] finish

real    0m18.063s
user    0m8.482s
sys     0m0.227s

```
Compare to a same file gz compressed.
```
$ time ruby variantNamingPipeline.rb -r hg38 -i sample_kf_variants.vcf.gz -b 10000 -s --gz
[2021-12-17T10:25:27] Create an intermediate VCF: /mnt/brlstor/Vol6_SP/cfde/kidsfirst/test/tmp/sample_kf_variants_CARmod from the input: ../sample_kf_variants.vcf.gz
[2021-12-17T10:25:27] Collecting variants for /mnt/brlstor/Vol6_SP/cfde/kidsfirst/test/tmp/sample_kf_variants_CARmod_tmp-1
[2021-12-17T10:25:28] Calling ClinGen Allele Registry for data in /mnt/brlstor/Vol6_SP/cfde/kidsfirst/test/tmp/sample_kf_variants_CARmod_tmp-1
[2021-12-17T10:25:31] Creating summary file: /mnt/brlstor/Vol6_SP/cfde/kidsfirst/test/tmp/sample_kf_variants_CARmod_tmp-1_summary.txt
[2021-12-17T10:25:31] Creating CAid file: /mnt/brlstor/Vol6_SP/cfde/kidsfirst/test/tmp/sample_kf_variants_CARmod_tmp-1_CAid.vcf.gz
[2021-12-17T10:25:31] Collecting variants for /mnt/brlstor/Vol6_SP/cfde/kidsfirst/test/tmp/sample_kf_variants_CARmod_tmp-2
[2021-12-17T10:25:35] Calling ClinGen Allele Registry for data in /mnt/brlstor/Vol6_SP/cfde/kidsfirst/test/tmp/sample_kf_variants_CARmod_tmp-2
[2021-12-17T10:25:38] Creating summary file: /mnt/brlstor/Vol6_SP/cfde/kidsfirst/test/tmp/sample_kf_variants_CARmod_tmp-2_summary.txt
[2021-12-17T10:25:38] Creating CAid file: /mnt/brlstor/Vol6_SP/cfde/kidsfirst/test/tmp/sample_kf_variants_CARmod_tmp-2_CAid.vcf.gz
[2021-12-17T10:25:38] Collecting variants for /mnt/brlstor/Vol6_SP/cfde/kidsfirst/test/tmp/sample_kf_variants_CARmod_tmp-3
[2021-12-17T10:25:41] Calling ClinGen Allele Registry for data in /mnt/brlstor/Vol6_SP/cfde/kidsfirst/test/tmp/sample_kf_variants_CARmod_tmp-3
[2021-12-17T10:25:44] Creating summary file: /mnt/brlstor/Vol6_SP/cfde/kidsfirst/test/tmp/sample_kf_variants_CARmod_tmp-3_summary.txt
[2021-12-17T10:25:44] Creating CAid file: /mnt/brlstor/Vol6_SP/cfde/kidsfirst/test/tmp/sample_kf_variants_CARmod_tmp-3_CAid.vcf.gz
[2021-12-17T10:25:45] Collecting variants for /mnt/brlstor/Vol6_SP/cfde/kidsfirst/test/tmp/sample_kf_variants_CARmod_tmp-4
[2021-12-17T10:25:45] Calling ClinGen Allele Registry for data in /mnt/brlstor/Vol6_SP/cfde/kidsfirst/test/tmp/sample_kf_variants_CARmod_tmp-4
[2021-12-17T10:25:45] Creating summary file: /mnt/brlstor/Vol6_SP/cfde/kidsfirst/test/tmp/sample_kf_variants_CARmod_tmp-4_summary.txt
[2021-12-17T10:25:45] Creating CAid file: /mnt/brlstor/Vol6_SP/cfde/kidsfirst/test/tmp/sample_kf_variants_CARmod_tmp-4_CAid.vcf.gz
[2021-12-17T10:25:45] Merging *_CAid* intermediate files in: /mnt/brlstor/Vol6_SP/cfde/kidsfirst/test/tmp
[2021-12-17T10:25:45] Merging *_noCAid* intermediate files in: /mnt/brlstor/Vol6_SP/cfde/kidsfirst/test/tmp
[2021-12-17T10:25:45] Merging summary intermediate files in: /mnt/brlstor/Vol6_SP/cfde/kidsfirst/test/tmp
[2021-12-17T10:25:45] Creating final summary file: /mnt/brlstor/Vol6_SP/cfde/kidsfirst/test/sample_kf_variants_summary.txt
[2021-12-17T10:25:45] Clean up:
[2021-12-17T10:25:45] Removing files in /mnt/brlstor/Vol6_SP/cfde/kidsfirst/test/tmp
[2021-12-17T10:25:45] finish

real    0m18.656s
user    0m8.915s
sys     0m0.212s
```
## Improvement Ideas

---
- Able to split and process the multi-allelic variants.