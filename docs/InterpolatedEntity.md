# pw::InterpolatedEntity

Provides the *pw::InterpolatedEntity* static and instance commands.

### Table of Contents
* [pw::InterpolatedEntity Static Commands](#pwinterpolatedentity-static-commands)
  * [new](#pwinterpolatedentity-new)
* [pw::InterpolatedEntity Instance Commands](#pwinterpolatedentity-instance-commands)
  * [getEnt](#refent-getent)
  * [getMult](#refent-getmult)
  * [getDimensionality](#refent-getdimensionality)
  * [getOrigDimensions](#refent-getorigdimensions)
  * [getDimensions](#refent-getdimensions)
  * [setXyzCaching](#refent-setxyzcaching)
  * [getXyzCaching](#refent-getxyzcaching)
  * [delete](#refent-delete)
  * [getXYZ](#refent-getxyz)
  * [dump](#refent-dump)
* [Usage Examples](#usage-examples)
  * [Example 1](#example-1)

## pw::InterpolatedEntity Static Commands

Commands in this ensemble are accessed as :

```Tcl
pw::InterpolatedEntity <cmd> <options>
```
Where,

`cmd` - Is one of the pw::InterpolatedEntity command names listed below.

`options` - The cmd dependent options.

### pw::InterpolatedEntity new
```Tcl
pw::InterpolatedEntity new ent mult
```
Creates and returns a InterpolatedEntity object.

where,

`ent` - A structured block, domain, or connector entity.

`mult` - The cell multiplier.This determines the number of interpolated points.



## pw::InterpolatedEntity Instance Commands

Objects created by `pw::InterpolatedEntity new` support the following commands.

### $refEnt getEnt
```tcl
$refEnt getEnt
```
Returns the wrapped entity object.

### $refEnt getMult
```tcl
$refEnt getMult
```
Returns the cell multiplier value.

### $refEnt getDimensionality
```tcl
$refEnt getDimensionality
```
Returns the cell dimensionality of the wrapped entity.

### $refEnt getOrigDimensions
```tcl
$refEnt getOrigDimensions
```
Returns the original (not multipled) IJK point dimensions of the wrapped entity.

### $refEnt getDimensions
```tcl
$refEnt getDimensions
```
Returns the multipled IJK point dimensions of the wrapped entity.

### $refEnt getXyzCaching
```tcl
$refEnt getXyzCaching
```
Returns 1 if xyz caching is enabled for this object.

### $refEnt setXyzCaching
```Tcl
$refEnt setXyzCaching onOff
```
Enables or disables (default) xyz caching for this object.

where,

`onOff` - One of 0 (off, no, disabled, disable, false), or 1 (on, yes, enabled, enable, true).




### $refEnt delete
```tcl
$refEnt delete
```
Destroys the InterpolatedEntity object. Returns nothing.

### $refEnt getXYZ
```tcl
$refEnt getXYZ ndx
```
Returns the XYZ value at a requested grid index position.

where,

`ndx` - A list containing the I (connectors), IJ (domains), or IJK (blocks) grid position index. The wrapped entity's dimensionality determines the minimum number of indices required. Any indices beyond the dimensionality are silently ignored. For example, an index of `$refEnt getXYZ {10 1 2}` for a wrapped connector is silently interpreted as `$refEnt getXYZ {10}`.

### $refEnt dump
```tcl
$refEnt dump
```
Dumps various debug information to stdout.


## Usage Examples

### Example 1
Basic Usage.
```
Debug setVerbose 1 ;# enable debug messages
set createPts 0

# $sblk refers to an exisiting structured block entity
# $refinedBlk provides access to an interpolated grid with a 3x cell density
set refEnt [pw::InterpolatedEntity new $sblk 3]
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
