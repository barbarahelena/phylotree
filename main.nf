#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    heliuspaired — Phylogenomics pipeline
    bakta → panaroo → iqtree2
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Usage — run Bakta annotation then build tree:
        nextflow run main.nf \
            --taxon        parabacteroides \
            --samplesheet  data/parabacteroides_samplesheet_filtered.csv \
            --bakta_input  false \
            --bakta_db     /path/to/bakta/db

    Usage — use pre-existing Bakta GFF3s (skip annotation):
        nextflow run main.nf \
            --taxon        parabacteroides \
            --samplesheet  data/parabacteroides_samplesheet_filtered.csv \
            --bakta_input  true

    Samplesheet columns:
        When --bakta_input false : sample,fasta     (run Bakta on each FASTA)
        When --bakta_input true  : sample,gff3      (path to existing Bakta GFF3)

    Parameters:
        --taxon         Taxon label (used in output naming)         [required]
        --samplesheet   Path to samplesheet CSV                     [required]
        --bakta_input   true  = GFF3s already exist in samplesheet  [default: false]
                        false = run Bakta on FASTA inputs
        --bakta_db      Path to Bakta database directory            [required if bakta_input false]
        --base_dir      Absolute path to project root               [default: /projects/prjs1784/heliuspaired]
        --core_thresh   Panaroo core-gene threshold (0–1)           [default: 0.98]
        --bootstrap     IQ-TREE ultrafast bootstrap replicates      [default: 1000]
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { BAKTA_BAKTA } from './modules/bakta/bakta/main'
include { PANAROO     } from './modules/panaroo'
include { IQTREE      } from './modules/iqtree'

// ── Parameters ───────────────────────────────────────────────────────────────
params.taxon        = null
params.samplesheet  = null
params.bakta_input  = false          // true = samplesheet has gff3 column
params.bakta_db     = null
params.base_dir     = "/projects/prjs1784/heliuspaired"
params.outdir       = null
params.core_thresh  = 0.98
params.bootstrap    = 1000

// ── Validate ─────────────────────────────────────────────────────────────────
if (!params.taxon)       error "ERROR: --taxon is required"
if (!params.samplesheet) error "ERROR: --samplesheet is required"
if (!params.bakta_input && !params.bakta_db) error "ERROR: --bakta_db is required when --bakta_input is false"

// ── Workflow ──────────────────────────────────────────────────────────────────
workflow {

    ss = Channel
        .fromPath(params.samplesheet, checkIfExists: true)
        .splitCsv(header: true, strip: true)

    if (params.bakta_input) {
        // ── Path A: samplesheet provides existing Bakta GFF3 paths ───────────
        log.info "Using pre-existing Bakta GFF3s from samplesheet"
        gffs_ch = ss.map { row ->
            def gff = file("${params.base_dir}/${row.gff3}")
            if (!gff.exists()) error "GFF3 not found for '${row.sample}': ${gff}"
            gff
        }

    } else {
        // ── Path B: run Bakta on each FASTA ──────────────────────────────────
        log.info "Running Bakta annotation (db: ${params.bakta_db})"
        db_ch = Channel.value(file(params.bakta_db, checkIfExists: true))

        bins_ch = ss.map { row ->
            def fasta = file("${params.base_dir}/${row.fasta}")
            if (!fasta.exists()) error "FASTA not found for '${row.sample}': ${fasta}"
            tuple(row.sample, fasta)
        }

        BAKTA_BAKTA(bins_ch, db_ch)
        gffs_ch = BAKTA_BAKTA.out.gff.map { _name, gff -> gff }
    }

    // Step 2 — pangenome + core alignment
    PANAROO(
        gffs_ch.collect(),
        params.taxon,
        params.core_thresh
    )

    // Step 3 — ML tree
    IQTREE(
        PANAROO.out.core_aln,
        params.taxon,
        params.bootstrap
    )

    IQTREE.out.treefile
        .subscribe { f -> log.info "Tree: ${f}" }
}
