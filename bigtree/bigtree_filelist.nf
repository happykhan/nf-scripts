#!/usr/bin/env nextflow
params.reads = "/hpc-home/alikhan/test_reads"
params.reference = "/hpc-home/alikhan/Informatics/alikhan/ref/LT2.fna"
params.filelist  = 'filelist.full.csv'

Channel.fromPath( params.filelist ).splitCsv( header:true ).map{ row-> tuple(row.name, file(row.r1), file(row.r2)) }.set { reads_snippy }
ref = file(params.reference)
params.tree = false

process snippy {
   cpus 20
   queue 'nbi-largemem,nbi-medium,nbi-short,nbi-long,qib-long,qib-medium,qib-short'
   executor 'slurm'
   memory { 80.GB * task.attempt }

   errorStrategy {  'retry' }
   maxRetries 3

   input:
   set name, file(read1), file(read2) from reads_snippy
   file ref 

   output:
   file "${name}" into core_aln_results

   script:
   """
   snippy --cpus ${task.cpus} --ref ${ref} --R1 ${read1} --R2 ${read2} --outdir ${name} --cleanup
   """
}

process snippycore {
    publishDir 'snippy', mode: 'copy', overwrite: true
    cpus 10 
    queue 'nbi-largemem,nbi-medium,nbi-short,nbi-long,qib-long,qib-medium,qib-short'

    input:
    file(snippy) from core_aln_results.collect()

    output:
    file "core.full.aln" into snipclean
    file "core*" into snippyout

    script:
    """
    snippy-core --mask-char=N --ref ${params.reference} ${snippy}
    """
}

process snippyclean {
    publishDir 'snippy', mode: 'copy', overwrite: true
    queue 'nbi-largemem,nbi-medium,nbi-short,nbi-long,qib-long,qib-medium,qib-short'
    executor 'slurm'

    input: 
    file(core) from snipclean    

    output:
    file "clean.full.aln" into ( iq_align, nj_core_align, ft_core_align, clonal_align, fast_align)

    script:
    """
    snippy-clean_full_aln ${core} > clean.full.aln
    """
}


process rapidnj  {
    publishDir 'rapidnj', mode: 'copy', overwrite: true
    queue 'nbi-largemem,nbi-medium,nbi-short,nbi-long,qib-long,qib-medium,qib-short'
    executor 'slurm'
 
    input:
    file core from nj_core_align 

    output:
    file 'rapidnj.tree' into njtree 

    script:
    """
    rapidnj -n -i fa ${core} > rapidnj.tree
    """
}

process iqtreefast{
   cpus 20
   publishDir 'iqtree_fast', mode: 'copy', overwrite: true
   time '47h'
   queue 'nbi-largemem,nbi-medium,nbi-short,nbi-long,qib-long,qib-medium,qib-short'
   executor 'slurm'
   memory { 100.GB * task.attempt }
   time { 2.d * task.attempt }

   errorStrategy { task.exitStatus in 137..140 ? 'retry' : 'terminate' }
   maxRetries 3

   when:
   params.tree

   input:
   file align from fast_align

   output:
   file 'iqtree_fast*' into iqfastout
   file 'iqtree_fast.treefile' into iqtreefastout

   script:
   """
   iqtree -s ${align} -pre iqtree_fast -nt ${task.cpus} -m HKY -fast
   """

}

process iqtree{
   cpus 20
   publishDir 'iqtree', mode: 'copy', overwrite: true    
   time '3d'
   queue 'qib-long,nbi-long'
   executor 'slurm'
   memory { 100.GB * task.attempt }
   time { 3.d * task.attempt }

   errorStrategy { 'retry' }
   maxRetries 3

   when:
   params.tree
 
   input: 
   file align from iq_align 
   
   output: 
   file 'iqtree*' into iqout
   file 'iqtree.treefile' into iqtreeout
   
   script:
   """
   iqtree -s ${align} -pre iqtree -nt ${task.cpus} -m GTR+G 
   """
}

process clonal{
   publishDir 'clonal', mode: 'copy', overwrite: true    
   time '5d'
   cpus 5 
   memory '120 GB'   
   queue 'nbi-largemem,nbi-medium,nbi-short,nbi-long,qib-long,qib-medium,qib-short'
   executor 'slurm'
   memory { 120.GB * task.attempt }
   time { 2.d * task.attempt }

   errorStrategy {  'retry' }
   maxRetries 3

   when:
   params.tree

   input: 
   file tree from iqtreefastout
   file align from clonal_align
   
   output:
   file 'clonal*' into clonalout

   script:
   """
   ClonalFrameML ${tree} ${align} clonal
   """
}
