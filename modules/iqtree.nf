process IQTREE {
    tag "${taxon}"

    publishDir "${params.base_dir}/phylogenomics/${params.taxon}/iqtree",
        mode: 'copy'

    container "https://depot.galaxyproject.org/singularity/iqtree%3A3.1.1--hde5307d_1"

    cpus   16
    memory '32 GB'
    time   '6 h'

    input:
    path  alignment
    val   taxon
    val   bootstrap

    output:
    path "${taxon}.treefile",  emit: treefile
    path "${taxon}.iqtree",    emit: report
    path "${taxon}.log",       emit: log
    path "*",                  emit: all

    script:
    """
    iqtree2 \\
        -s  "${alignment}" \\
        --prefix "${taxon}" \\
        -m  TEST \\
        -B  ${bootstrap} \\
        --bnni \\
        -T  ${task.cpus} \\
        --redo
    """
}
