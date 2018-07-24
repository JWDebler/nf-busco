#!/home/johannes/bin nextflow

//+++++++++++++++++ SETUP++++++++++++++++++++++++
//input genomes and proteoms in fasta format
params.inputgenomes = "/home/johannes/rdrive/PPG_SEQ_DATA-LICHTJ-SE00182/johannes/notebook/2018-05-14-Botrytis/output/BUSCO/*.assembly*" 
params.inputproteins = "/home/johannes/rdrive/PPG_SEQ_DATA-LICHTJ-SE00182/johannes/notebook/2018-05-14-Botrytis/output/BUSCO/*.proteins*" 
//BUSCO Fungi dataset
params.lineage_path = "/opt/busco/lineage_datasets/ascomycota_odb9_bcin/" //more specific
//params.lineage_path = "/opt/busco/lineage_datasets/ascomycota_odb9/" //more specific
//params.lineage_path = "/opt/busco/lineage_datasets/fungi_odb9/" //less specific

//Path where output data shall go
params.outputdir = "/home/johannes/rdrive/PPG_SEQ_DATA-LICHTJ-SE00182/johannes/notebook/BUSCOtestBcin"
//+++++++++++++++++++++++++++++++++++++++++++++++

//Create channel that provides the sampleID and the raw read files 
genomes = Channel
.fromPath(params.inputgenomes)
.map {file -> [file.simpleName, file]}

proteins = Channel
.fromPath(params.inputproteins)
.map {file -> [file.simpleName, file]}

process buscoGenome {
    tag {sampleID}

    publishDir "${params.outputdir}/genome/", mode: 'copy'

    input:
    set sampleID, 'genome.fasta' from genomes

    output:
    set sampleID, "run_${sampleID}/short_summary_${sampleID}.txt" into buscoResultsGenome

    """
    python3 /opt/busco/scripts/run_BUSCO.py \
    --in genome.fasta \
    --out ${sampleID} \
    --lineage_path ${params.lineage_path} \
    --mode genome
    """
}

buscoResultsGenome
.collectFile() { sampleID, path -> ["short_summary_${sampleID}.txt", path.text] }
.map { path -> [path.getBaseName(), path] }
.set{ resultsGenome }



process buscoProteome {
    tag {sampleID}

    publishDir "${params.outputdir}/proteome/", mode: 'copy'

    input:
    set sampleID, 'proteins.fasta' from proteins

    output:
    set sampleID, "run_${sampleID}/short_summary_${sampleID}.txt" into buscoResultsProteome

    """
    python3 /opt/busco/scripts/run_BUSCO.py \
    --in proteins.fasta \
    --out ${sampleID} \
    --lineage_path ${params.lineage_path} \
    --mode proteins
    """
}

buscoResultsProteome
.collectFile() { sampleID, path -> ["short_summary_${sampleID}.txt", path.text] }
.map { path -> [path.getBaseName(), path] }
.set{ resultsProteome }


process plotsGenome {

    publishDir "${params.outputdir}/plotsGenome/", mode: 'copy'

    input:
    file 'summary.txt' from resultsGenome  

    output:
    file 'summaryGenomes/busco_figure.png'

    """
    mkdir summaryGenomes
    cp ${params.outputdir}/genome/*/*.txt summaryGenomes/
    python3 /opt/busco/scripts/generate_plot.py -wd summaryGenomes
    """
}

process plotsProteome {

    publishDir "${params.outputdir}/plotsProteome/", mode: 'copy'

    input:
    file 'summary.txt' from resultsProteome

    output:
    file 'summaryProteoms/busco_figure.png'

    """
    mkdir summaryProteoms
    cp ${params.outputdir}/proteome/*/*.txt summaryProteoms/    
    python3 /opt/busco/scripts/generate_plot.py -wd summaryProteoms
    """
}

workflow.onComplete {
    log.info "========================================================"
    log.info "Pipeline completed at: $workflow.complete"
    log.info "Execution status: ${ workflow.success ? 'OK' : 'Failed' }"
    log.info "========================================================"
}