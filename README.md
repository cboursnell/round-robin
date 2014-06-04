### Round Robin

Multiple species homology search

# Usage

```
OPTIONS:
  --reference, -r <s>:   Annotated reference protein fasta file or file
                         containing list of references
       --list, -l <s>:   File containing list of nucleotide fasta files to
                         annotate
      --files, -f <s>:   Comma separated list of nucleotide fasta files to
                         annotate
    --threads, -t <i>:   number of threads to run BLAST with (default: 1)
    --working, -w <s>:   Where the blast output files are saved
     --output, -o <s>:   Final annotation output file
           --help, -h:   Show this message

```

Example

```
robin --reference arabidopsis_protein.fa --list list --threads 8
      --working blast_output --output cyperus-arabidopsis-annotation.txt
```