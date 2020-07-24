#!/usr/bin/env nextflow
params.gff = "/hpc-home/alikhan/heidl_minne_1_gff"
Channel.fromPath( params.gff + '/*.gff' ).into { gff_roary }

process roary {
    cpus 20
    time '47h' 
    queue 'qib-long,qib-medium,qib-short,nbi-medium,nbi-short,nbi-long'
    publishDir 'roary', mode: 'copy', overwrite: true
 
    input:
    file(genome) from gff_roary.collect()

    output:
    file "roary_out/*" into roary_all_results

    script:
    """
    roary -p ${task.cpus} -ne -f roary_out ${genome}
    """
}
