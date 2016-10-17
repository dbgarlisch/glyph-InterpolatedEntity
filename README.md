# glyph-RefinedEntity
This glyph class wraps an existing structured grid entity and provides access to interpolated grid points.

![RefinedEntity Banner Image](../master/docs/images/banner.png  "RefinedEntity banner Image")

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
  set createPts 0

  # $sblk refers to an exisiting structured block entity
  # $refinedBlk provides access to an interpolated grid with a 3x cell density
  set refEnt [pw::RefinedEntity new $sblk 3]
  vputs "$refinedBlk getEnt            = [$refinedBlk getEnt]"
  vputs "$refinedBlk getMult           = [$refinedBlk getMult]"
  vputs "$refinedBlk getOrigDimensions = [$refinedBlk getOrigDimensions]"
  vputs "$refinedBlk getDimensions     = [$refinedBlk getDimensions]"

  lassign [$refinedBlk getDimensions] iDim jDim kDim
  for {set ii 1} {$ii <= $iDim} {incr ii} {
    for {set jj 1} {$jj <= $jDim} {incr jj} {
      for {set kk 1} {$kk <= $kDim} {incr kk} {
        set ndx [list $ii $jj $kk]
        set xyz [$refinedBlk getXYZ $ndx]
        puts "[list $ndx] ==> $xyz"
        if { $createPts } {
          [pw::Point create] setPoint $xyz
        }
      }
    }
  }

  $refinedBlk delete
```

See the [glyph-RefinedEntity Class Docs](docs/RefinedEntity.md) for full documentation.
