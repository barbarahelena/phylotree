process BAKTA_BAKTA {
    tag "${bin_name}"

    publishDir "${params.base_dir}/phylogenomics/${params.taxon}/bakta",
        mode: 'copy', pattern: "*.gff3"

    container 'https://depot.galaxyproject.org/singularity/bakta:1.10.4--pyhdfd78af_0'

    cpus   8
    memory '16 GB'
    time   '4 h'

    input:
    tuple val(bin_name), path(fasta)
    path db

    output:
    tuple val(bin_name), path("${bin_name}.gff3"), emit: gff

    script:
    """
    bakta \\
        "${fasta}" \\
        --threads ${task.cpus} \\
        --prefix "${bin_name}" \\
        --skip-trna \\
        --skip-plot \\
        --db "${db}"
    """

    stub:
    """
    touch ${bin_name}.embl
    touch ${bin_name}.faa
    touch ${bin_name}.ffn
    touch ${bin_name}.fna
    touch ${bin_name}.gbff
    touch ${bin_name}.gff3
    touch ${bin_name}.hypotheticals.tsv
    touch ${bin_name}.hypotheticals.faa
    touch ${bin_name}.tsv
    touch ${bin_name}.txt
    """
}
