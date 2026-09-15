# Scientific components

## Chemistry

`library/Chemical Elements/` provides:

- `Atom3D.gd` for atom representations
- `Bond3D.gd` for links between atoms
- `Molecule3D.gd` for molecular structures
- `MoleculePresets.gd` and `ChemistryData.gd` for reusable element and molecule
  data

Together, these components support editable molecular visualizations without
having to construct each atom and bond manually.

## Mathematical TeX

`library/GodoTeX/` renders TeX-style expressions into Godot textures. The
`LaTeX` and `LaTeX3D` components expose expression, font-size, color, fill,
anti-aliasing, and error-display settings in the Inspector.

These components use CSharpMath and SkiaSharp. Their package references are in
`tcl-studio.csproj`, so retain or restore those dependencies when copying the
library to another project.

## Environments

`library/environmental entities/` provides procedural house and tree generators
and example stylized-world/environment scenes. `library/misc/` contains related
reusable examples such as Earth, springs, neural-network diagrams, and visual
presentation elements.
