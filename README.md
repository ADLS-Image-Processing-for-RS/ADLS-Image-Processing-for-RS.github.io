# RasterDataProcessing

Course materials for "Image Processing for Remote Sensing" - Applied Digital Life Sciences, ZHAW.

## Presenter Mode

- **Students**: Light theme, normal URLs
- **Teaching**: Dark theme for slide spacing, click sections to see notes in browser console

## Student Enrollment (HS26)

|                    | In GISc & GeoDB | Not in GISc & GeoDB | Total |
|--------------------|----------------:|--------------------:|------:|
| **In IPRS**        | 5               | 8                   | 13    |
| **Not in IPRS**    | 1               | —                   | —     |
| **Total**          | 6               | —                   | —     |

### Temporal sequence (HS26)

IPRS runs **before** GISc. The last of IPRS's 4 sessions falls on the same day as GISc's first session:

```
IPRS:  [1]---[2]---[3]---[4]
                          |
GISc:                    [1]---[2]---[3]---...
```

This means **IPRS teaches raster foundations first**. By the time the 5 overlap students enter GISc, they have already covered raster data model, map algebra, and `terra` in IPRS.

### Content overlap & recommendation

IPRS and GISc share near-identical content on:
- Raster data model (regular grid, cell offsets, continuous vs. discrete)
- Map algebra (local / focal / zonal / global) — same Luxembourg elevation example
- `terra::extract()` and raster-vector operations

Since IPRS runs first and 5/6 GISc students have taken it, **the fix belongs in GISc, not IPRS**:
- GISc's raster sections should assume prior knowledge from IPRS and go deeper or redirect
- GISc's unique value-add is the vector model (simple features, spatial operations) and vector-raster integration — lean into that
- Only 1 GISc student lacks the IPRS background; handle via self-study reference, not repeated lectures

## Project structure

This is a **Quarto website** (not a book). Each `.qmd` renders with its own format:

- `lesson*.qmd` — revealjs slides, linked from the corresponding tasks page
- `lesson*-tasks.qmd` — HTML task pages, visible in the sidebar

Slides are included in `project: render:` but excluded from the sidebar. Students reach them via the "Open slides" button at the top of each tasks page.

### Configs

| File | Purpose |
|------|---------|
| `_quarto.yml` | Production — only published lessons in sidebar |
| `_quarto-dev.yml` | Dev — all lessons visible |

### Workflow

- Preview: `quarto preview --profile dev`
- Render: `quarto render` (production) or `quarto render --profile dev`
- Publish: `quarto publish gh-pages --no-prompt`

## TODOs

### New content

- **Change detection** (add to L4)
  - Optical change detection using Sentinel-2 (directly builds on L3)
  - Use Bachelor thesis (Sentinel-1, grass mowing detection) as a 2–3 slide discussion case: why SAR didn't work here, what would you do differently?
  - Teaches sensor selection thinking without requiring a full SAR technical pipeline

- **Image enhancement** (lesson TBD)
  - Histogram equalization, contrast stretching, decorrelation stretch
  - Currently only implicitly used (`stretch = "histogram"` in one line in L3)
  - Candidate location: L2 as application of local/focal operations

- **Accuracy assessment** (add to L4)
  - Systematic treatment: confusion matrix, producer/user accuracy, area-adjusted estimates, sampling design

### Refactoring (2027)

- **L1: Long → Wide → Matrix → Raster chain** — shorten drastically (too many slides before anything visual)
- **L2/L3 overlap** — remove duplicate DN → reflectance / spectral indices pipeline

## Notes to self

- Switching the theme activates the presenter mode (dark = presenter, shows speaker notes in browser console)

## Role of Slides

**Slides serve three key functions in the classroom:**

1. **Navigation**: They provide structure and orientation for both instructors and students, clearly indicating the current topic and learning progression
2. **Reference material**: They serve as a study resource for students to review content and prepare for assessments
3. **Teaching prompts**: They include instructor notes highlighting key points and concepts that require emphasis

