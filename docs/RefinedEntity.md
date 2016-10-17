# tcl-RefinedEntity

Provides the *RefinedEntity* command ensemble.

DOCS ARE IN WORK - NOT VALID YET

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
  * [Base Type Params](#base-type-params)

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

### example 1
Base types that support typedefs(see[VTOR::createTypedef_](CustomBaseTypes.md#validator - variables)) can be used
for parameters.These parameters will have an unlimited range.
```
set poi[pw::RefinedEntity new integer 33]
$poi = 77

set pod[pw::RefinedEntity new double 33.33]
$pod = 77.77

# real is an alias of double
set por[pw::RefinedEntity new real 44.55]
$por = 66.88

set pos[pw::RefinedEntity new string{ hello }]
$pos = { world!}

# enum requires a range!It must be typedef'ed.
set enum[pw::RefinedEntity new enum]; # ERROR
```
