process PANAROO {
    tag "${taxon}"

    publishDir "${params.base_dir}/phylogenomics/${params.taxon}/panaroo",
        mode: 'copy'

    container "https://depot.galaxyproject.org/singularity/panaroo%3A1.6.0--pyhdfd78af_0"

    cpus   16
    memory '64 GB'
    time   '12 h'

    input:
    path gffs          // all GFF files collected into the work dir
    val  taxon
    val  core_thresh

    output:
    path "core_gene_alignment.aln",  emit: core_aln
    path "pan_genome_reference.fa",  emit: pan_ref
    path "gene_presence_absence.csv", emit: presence_absence
    path "*",                         emit: all

    script:
    """
    panaroo \\
        --input ${gffs} \\
        --out_dir . \\
        --clean-mode strict \\
        --alignment core \\
        --aligner mafft \\
        --core_threshold ${core_thresh} \\
        --threads ${task.cpus} \\
        --remove-invalid-genes
    """
}
