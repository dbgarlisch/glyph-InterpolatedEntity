# tcl-RefinedEntity

Provides the *RefinedEntity* static and instance commands.

### Table of Contents
* [pw::RefinedEntity Static Commands](#pwrefinedentity-static-commands)
  * [new](#pwrefinedentity-new)
* [pw::RefinedEntity Instance Commands](#pwrefinedentity-instance-commands)
  * [getEnt](#refent-getent)
  * [getMult](#refent-getmult)
  * [getDimensionality](#refent-getdimensionality)
  * [getOrigDimensions](#refent-getorigdimensions)
  * [getDimensions](#refent-getdimensions)
  * [delete](#refent-delete)
  * [getXYZ](#refent-getxyz)
  * [dump](#refent-dump)
* [Usage Examples](#usage-examples)
  * [Example 1](#example-1)

## pw::RefinedEntity Static Commands

Commands in this ensemble are accessed as :

```Tcl
pw::RefinedEntity <cmd> <options>
```
Where,

`cmd` - Is one of the pw::RefinedEntity command names listed below.

`options` - The cmd dependent options.

### pw::RefinedEntity new
```Tcl
pw::RefinedEntity new ent mult
```
Creates and returns a RefinedEntity object.

where,

`ent` - A structured block, domain, or connector entity.

`mult` - The cell multiplier.This determines the number of interpolated points.



## pw::RefinedEntity Instance Commands

Objects created by `pw::RefinedEntity new` support the following commands.

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

### $refEnt delete
```tcl
$refEnt delete
```
Destroys the RefinedEntity object. Returns nothing.

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
