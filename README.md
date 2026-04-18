# Phylogenomics pipeline

**Bakta → Panaroo → IQ-TREE2**

Builds a maximum-likelihood core-gene phylogeny from high-quality MAG bins.
If Bakta GFF3 annotations already exist (parabacteroides, senegalimassilia, alistipes),
the annotation step is skipped and the pipeline goes straight to pangenome construction.

---

## Directory layout

```
workflows/phylo/
├── main.nf               # Workflow entry point
├── nextflow.config       # SLURM + Apptainer configuration
└── modules/
    ├── bakta/bakta/main.nf  # Bakta annotation (one task per bin; skipped if GFF3s exist)
    ├── panaroo.nf           # Pangenome + core alignment
    └── iqtree.nf            # ML tree
```

---

## Quick start

### 1 — Generate Bakta GFF3 samplesheets (once)

If Bakta annotations have already been run (e.g. from the annotation pipeline),
generate the GFF3 samplesheets so the phylo pipeline can find them:

```bash
cd /projects/prjs1784/heliuspaired
python3 scripts/phylo/make_bakta_samplesheet.py
```

This produces:
- `data/parabacteroides_bakta_samplesheet.csv`
- `data/senegalimassilia_bakta_samplesheet.csv`
- `data/alistipes_bakta_samplesheet.csv`

Only samples present in the corresponding `*_samplesheet_filtered.csv` are included.

### 2 — Run the pipeline

**With pre-existing Bakta GFF3s** (`--bakta_input true`, samplesheet has `sample,gff3` columns):

```bash
nextflow run main.nf \
    -profile snellius \
    --taxon       parabacteroides \
    --samplesheet data/parabacteroides_bakta_samplesheet.csv \
    --bakta_input true \
    -resume
```

**Without existing annotations** (Bakta will run on each FASTA first):

```bash
nextflow run main.nf \
    -profile snellius \
    --taxon       alistipes \
    --samplesheet data/alistipes_samplesheet_filtered.csv \
    --bakta_input false \
    --bakta_db    /path/to/bakta/db \
    -resume
```

Add `-resume` to restart from the last successful step after any failure.

---

## Samplesheet formats

| Mode | Columns | Example |
|---|---|---|
| Pre-existing GFF3s (`--bakta_input true`) | `sample,gff3` | `data/parabacteroides_bakta_samplesheet.csv` |
| Run Bakta (`--bakta_input false`) | `sample,fasta` | `data/parabacteroides_samplesheet_filtered.csv` |

---

## Outputs

```
phylogenomics/<taxon>/
├── bakta/                       # Per-bin Bakta GFF3/FAA/etc. (only if Bakta was run)
├── panaroo/
│   ├── core_gene_alignment.aln  # Core gene MSA → input for IQ-TREE
│   ├── pan_genome_reference.fa
│   └── gene_presence_absence.csv
└── iqtree/
    ├── <taxon>.treefile         # Newick ML tree
    ├── <taxon>.iqtree           # Full report (model, log-likelihood, etc.)
    └── <taxon>.log
```

---

## Key parameters

| Parameter | Default | Description |
|---|---|---|
| `--taxon` | *(required)* | Taxon label used in output naming |
| `--samplesheet` | *(required)* | Path to samplesheet CSV |
| `--bakta_input` | `false` | `true` = samplesheet has `gff3` column; `false` = has `fasta` column |
| `--bakta_db` | *(required if bakta_input false)* | Path to Bakta database directory |
| `--base_dir` | `/projects/prjs1784/heliuspaired` | Project root |
| `--core_thresh` | `0.98` | Panaroo core gene threshold (lower to `0.95` if too few core genes) |
| `--bootstrap` | `1000` | IQ-TREE ultrafast bootstrap replicates |

---

## Containers (auto-pulled via Apptainer)

| Tool | Version | Source |
|---|---|---|
| Bakta | 1.10.4 | `depot.galaxyproject.org/singularity/bakta:1.10.4--pyhdfd78af_0` |
| Panaroo | 1.6.0 | `depot.galaxyproject.org/singularity/panaroo:1.6.0--pyhdfd78af_0` |
| IQ-TREE2 | 3.1.1 | `depot.galaxyproject.org/singularity/iqtree:3.1.1--hde5307d_1` |

Images are cached to `~/singularity_images/` on Snellius.

---

## Notes

### Panaroo clean mode
The pipeline uses `--clean-mode strict`, which is recommended for MAGs to filter
likely contamination. If you see very few core genes, switch to `--clean-mode moderate`
in `workflows/phylo/modules/panaroo.nf`.

### Bakta database
The Bakta database used for annotation is located at:
```
/projects/prjs1784/heliuspaired/annotation_parabacteroides/bakta/db
```

### Visualising the tree
The `.treefile` (Newick format) can be loaded into:
- **iTOL** (https://itol.embl.de) — upload and annotate with functional heatmaps
- **R/ggtree**: `ggtree::read.tree("<taxon>.treefile")`
- **FigTree** — for quick interactive viewing
