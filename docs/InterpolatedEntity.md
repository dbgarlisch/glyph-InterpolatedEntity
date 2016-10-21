# pw::InterpolatedEntity

Provides the *pw::InterpolatedEntity* static and instance commands.

### Table of Contents
* [pw::InterpolatedEntity Static Commands](#pwinterpolatedentity-static-commands)
  * [new](#pwinterpolatedentity-new)
* [pw::InterpolatedEntity Instance Commands](#pwinterpolatedentity-instance-commands)
  * [getEnt](#obj-getent)
  * [getMult](#obj-getmult)
  * [getDimensionality](#obj-getdimensionality)
  * [getOrigDimensions](#obj-getorigdimensions)
  * [getDimensions](#obj-getdimensions)
  * [delete](#obj-delete)
  * [getXYZ](#obj-getxyz)
  * [dump](#obj-dump)
  * [foreach](#obj-foreach)
* [Usage Example](#usage-example)

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

### $obj getEnt
```tcl
$obj getEnt
```
Returns the wrapped entity object.

### $obj getMult
```tcl
$obj getMult
```
Returns the cell multiplier value.

### $obj getDimensionality
```tcl
$obj getDimensionality
```
Returns the cell dimensionality of the wrapped entity.

### $obj getOrigDimensions
```tcl
$obj getOrigDimensions
```
Returns the original (not multipled) IJK point dimensions of the wrapped entity.

### $obj getDimensions
```tcl
$obj getDimensions
```
Returns the multipled IJK point dimensions of the wrapped entity.

### $obj delete
```tcl
$obj delete
```
Destroys the InterpolatedEntity object. Returns nothing.

### $obj getXYZ
```tcl
$obj getXYZ ndx
```
Returns the XYZ value at a requested grid index position.

where,

`ndx` - A list containing the I (connectors), IJ (domains), or IJK (blocks) grid position index. The wrapped entity's dimensionality determines the minimum number of indices required. Any indices beyond the dimensionality are silently ignored. For example, an index of `$obj getXYZ {10 1 2}` for a wrapped connector is silently interpreted as `$obj getXYZ {10}`.

### $obj dump
```tcl
$obj dump
```
Dumps various debug information to stdout.

### $obj foreach
```tcl
$obj foreach ndxVar xyzVar body
```
Loops over every grid point in $obj. For each point, the vars `ndxVar` and `xyzVar` are set and `body` is invoked. The indices are enumerated with `i` as the outer (slowest) loop and `k` as the inner (fastest) loop.

where,

`ndxVar` - Set to the current grid point's `i` (connector), `{i j}` (domain), or `{i j k}` (block) index.

`xyzVar` - Set to the current grid point's `{x y z}` value.

`body` - The script to execute for each grid point.


## Usage Example
```
# $sblk refers to an exisiting structured block entity
# $obj provides access to an interpolated grid with a 3x cell density
set obj [pw::InterpolatedEntity new $sblk 3]
vputs "$obj getEnt            = [$obj getEnt]"
vputs "$obj getMult           = [$obj getMult]"
vputs "$obj getOrigDimensions = [$obj getOrigDimensions]"
vputs "$obj getDimensions     = [$obj getDimensions]"
set createDbPts 0 ;# Slow if this is enabled for large grids
$obj foreach ndx xyz {
  puts "[list $ndx] ==> $xyz"
  if { $createDbPts } {
    set dbPt [pw::Point create]
    $dbPt setPoint $xyz
    $dbPt setName "pt($ndx)"
  }
}
$obj delete
```
