# glyph-RefinedEntity
This glyph class wraps an existing structured grid entity and provides access to interpolated grid points.

## Depends On

Project `tcl-Utils`


## Using The Library

To use this class to wrap an existing structured grid entity, you must include
`RefinedEntity.glf` in your application script.

```Tcl
  source "/some/path/to/your/copy/of/RefinedEntity.glf"
```

Basic usage example.

```Tcl
  Debug setVerbose 1 ;# enable debug messages

  # $ent refers to an exisiting structured con/dom/blk entity
  # $refEnt provides access to an interpolated grid with a 3x cell density
  set refEnt [pw::RefinedEntity new $ent 3]
  puts "$refEnt getEnt            = [$refEnt getEnt]"
  puts "$refEnt getMult           = [$refEnt getMult]"
  puts "$refEnt getOrigDimensions = [$refEnt getOrigDimensions]"
  puts "$refEnt getDimensions     = [$refEnt getDimensions]"

  # Creates db points at all refined XYZ locations.
  # If debug is enabled, dumps info about $refEnt to stdout
  $refEnt dump

  $refEnt delete
```

See the [glyph-RefinedEntity Class Docs](docs/RefinedEntity.md) for full documentation.
