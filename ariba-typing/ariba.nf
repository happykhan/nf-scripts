#!/usr/bin/env nextflow
params.reads = "/hpc-home/alikhan/test_reads"
Channel.fromFilePairs( params.reads + '/*{1,2}.fastq.gz' ).into { reads_ariba_plas; reads_ariba_res; reads_ariba_card }
params.db  = '/hpc-home/alikhan/Informatics/transfer/outgoing/ariba/ariba_resfinder/'
params.plasmiddb = '/hpc-home/alikhan/Informatics/transfer/outgoing/ariba/ariba_plasmidfinder/'
params.carddb = '/hpc-home/alikhan/Informatics/transfer/outgoing/ariba/ariba_card/'
plasdb = file(params.plasmiddb)
carddb = file(params.carddb)
db = file(params.db)

process ariba {
    cpus 20
    time '8h' 
    queue 'qib-long,qib-medium,qib-short,nbi-medium,nbi-short,nbi-long'
    publishDir 'ariba_resfinder', mode: 'copy', overwrite: true
 
    input:
    set val(name), file(reads) from reads_ariba_res
    file db 

    output:
    file "${name}.tsv" into ariba_res_results
    file "${name}" into ariba_all_results

    script:
    """
    ariba run --threads ${task.cpus} ${db}  ${reads[0]}  ${reads[1]} ${name} 
    cp ${name}/report.tsv  ${name}.tsv 
    """
}

process aribasum {
    cpus 10
    time '4h' 
    queue 'qib-long,qib-medium,qib-short,nbi-medium,nbi-short,nbi-long'
    publishDir 'ariba_resfinder/', mode: 'copy', overwrite: true
 
    input:
    file(reports) from ariba_res_results.collect()

    output:
    file "*" into aribares_out

    script:
    """
    ariba summary --preset all resfinder  $reports 
    """
}

process aribaplas {
    cpus 20
    time '8h' 
    queue 'qib-long,qib-medium,qib-short,nbi-medium,nbi-short,nbi-long'
    publishDir 'ariba_plasmidfinder', mode: 'copy', overwrite: true
 
    input:
    set val(name), file(reads) from reads_ariba_plas
    file plasdb 

    output:
    file "${name}.tsv" into ariba_plas_results
    file "${name}" into aribaplas_all_results

    script:
    """
    ariba run --threads ${task.cpus} ${plasdb}  ${reads[0]}  ${reads[1]} ${name} 
    cp ${name}/report.tsv  ${name}.tsv 
    """
}

process aribaplassum {
    cpus 10
    time '4h' 
    queue 'qib-long,qib-medium,qib-short,nbi-medium,nbi-short,nbi-long'
    publishDir 'ariba_plasmidfinder/', mode: 'copy', overwrite: true
 
    input:
    file(reports) from ariba_plas_results.collect()

    output:
    file "*" into aribaplas_out

    script:
    """
    ariba summary --preset all plasmidfinder  $reports 
    """
}

process aribacard {
    cpus 20
    time '8h' 
    queue 'qib-long,qib-medium,qib-short,nbi-medium,nbi-short,nbi-long'
    publishDir 'ariba_card', mode: 'copy', overwrite: true
 
    input:
    set val(name), file(reads) from reads_ariba_card
    file carddb 

    output:
    file "${name}.tsv" into ariba_card_results
    file "${name}" into aribacard_all_results

    script:
    """
    ariba run --threads ${task.cpus} ${carddb}  ${reads[0]}  ${reads[1]} ${name} 
    cp ${name}/report.tsv  ${name}.tsv 
    """
}

process aribacardsum {
    cpus 10
    time '4h' 
    queue 'qib-long,qib-medium,qib-short,nbi-medium,nbi-short,nbi-long'
    publishDir 'ariba_card/', mode: 'copy', overwrite: true
 
    input:
    file(reports) from ariba_card_results.collect()

    output:
    file "*" into aribacard_out

    script:
    """
    ariba summary --preset all card  $reports 
    """
}

