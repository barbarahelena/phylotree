process PYRODIGAL {
    tag "${bin_name}"

    publishDir "${params.base_dir}/phylogenomics/${params.taxon}/gff",
        mode: 'copy', pattern: "*.gff"

    container "https://depot.galaxyproject.org/singularity/pyrodigal%3A3.7.1--py313hd72fa03_0"

    cpus   2
    memory '4 GB'
    time   '1 h'

    input:
    tuple val(bin_name), path(fasta)

    output:
    tuple val(bin_name), path("${bin_name}.gff"), emit: gff

    script:
    """
    pyrodigal \\
        -i  "${fasta}" \\
        -f  gff \\
        -o  "${bin_name}.gff" \\
        --min-gene 60 \\
        -p  meta

    # Panaroo requires Prokka-style GFF: genome FASTA appended after ##FASTA
    echo "##FASTA" >> "${bin_name}.gff"
    cat "${fasta}" >> "${bin_name}.gff"
    """
}
