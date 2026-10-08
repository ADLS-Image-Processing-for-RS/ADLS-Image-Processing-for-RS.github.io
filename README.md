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

## Notes to self:

- Switching the theme activates the presenter mode
- `quarto preview --profile dev` runs the dev version, with potentially unfinished chapters
- publish using `quarto publish gh-pages --no-prompt`

## Role of Slides

**Slides serve three key functions in the classroom:**

1. **Navigation**: They provide structure and orientation for both instructors and students, clearly indicating the current topic and learning progression
2. **Reference material**: They serve as a study resource for students to review content and prepare for assessments
3. **Teaching prompts**: They include instructor notes highlighting key points and concepts that require emphasis

