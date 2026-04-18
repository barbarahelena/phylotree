# Phylogenomics pipeline

**pyrodigal → Panaroo → IQ-TREE2**

Builds a maximum-likelihood core-gene phylogeny from high-quality MAG bins.

---

## Directory layout

```
workflows/phylo/
├── main.nf               # Workflow entry point
├── nextflow.config       # SLURM + Apptainer configuration
└── modules/
    ├── pyrodigal.nf      # Gene calling (one task per bin)
    ├── panaroo.nf        # Pangenome + core alignment
    └── iqtree.nf         # ML tree

scripts/phylo/
├── run_phylo_nf.sh       # Submit head job to SLURM (calls nextflow run)
└── pull_containers.sh    # Pull Apptainer SIF images (run once)
```

---

## Quick start

### 1 — Pull containers (once)

```bash
sbatch scripts/phylo/pull_containers.sh
```

Images are saved to `containers/`:

| Container | Source |
|---|---|
| `pyrodigal_3.7.1.sif` | `depot.galaxyproject.org/singularity/pyrodigal:3.7.1--py313hd72fa03_0` |
| `panaroo_1.6.0.sif`   | `depot.galaxyproject.org/singularity/panaroo:1.6.0--pyhdfd78af_0` |
| `iqtree_3.1.1.sif`    | `depot.galaxyproject.org/singularity/iqtree:3.1.1--hde5307d_1` |

### 2 — Run the pipeline

```bash
# Submit head job for each taxon
sbatch scripts/phylo/run_phylo_nf.sh parabacteroides
sbatch scripts/phylo/run_phylo_nf.sh alistipes
sbatch scripts/phylo/run_phylo_nf.sh senegalimassilia
```

Nextflow submits each process (Pyrodigal array, Panaroo, IQ-TREE) as
separate SLURM jobs automatically and chains them by dependency.

Use `-resume` (already included in the script) to restart from the last
successful step after any failure.

---

## Outputs

```
phylogenomics/<taxon>/
├── gff/                         # Per-bin Pyrodigal GFF3 files
├── panaroo/
│   ├── core_gene_alignment.aln  # Core gene MSA → input for IQ-TREE
│   ├── pan_genome_reference.fa
│   └── gene_presence_absence.csv
├── iqtree/
│   ├── <taxon>.treefile         # Newick ML tree
│   ├── <taxon>.iqtree           # Full report (model, log-likelihood, etc.)
│   └── <taxon>.log
└── pipeline_info/
    ├── report.html
    ├── timeline.html
    └── trace.txt
```

---

## Key parameters

| Parameter | Default | Notes |
|---|---|---|
| `--core_thresh` | `0.98` | Panaroo core gene threshold — lower to `0.95` if losing too many core genes |
| `--bootstrap` | `1000` | IQ-TREE ultrafast bootstrap replicates |
| `--base_dir` | `/projects/prjs1784/heliuspaired` | Project root |

Override on the command line, e.g.:

```bash
sbatch scripts/phylo/run_phylo_nf.sh parabacteroides \
    # then edit run_phylo_nf.sh to pass --core_thresh 0.95
```

Or pass extra `--param value` flags directly to `nextflow run` in `run_phylo_nf.sh`.

---

## Panaroo mode

The pipeline uses `--clean-mode strict`, which is recommended for MAGs
to filter likely contamination. If you see very few core genes, switch to
`--clean-mode moderate` in `workflows/phylo/modules/panaroo.nf`.

---

## Visualising the tree

The `.treefile` (Newick format) can be loaded directly into:
- **iTOL** (https://itol.embl.de) — upload and annotate with functional heatmaps
- **R/ggtree**: `ggtree::read.tree("<taxon>.treefile")`
- **FigTree** — for quick interactive viewing
