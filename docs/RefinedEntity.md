# tcl-RefinedEntity

Provides the *RefinedEntity* command ensemble.

DOCS ARE IN WORK - NOT VALID YET

### Table of Contents
* [Param Commands](#param-commands)
  * [basetype](#param-basetype)
  * [getBasetype](#param-getbasetype)
* [Usage Examples](#usage-examples)
  * [Base Type Params](#base-type-params)


## Param Commands

Commands in this ensemble are accessed as:

```Tcl
pw::RefinedEntity <cmd> <options>
```
Where,

`cmd` - Is one of the Param command names listed below.

`options` - The cmd dependent options.


### Param basetype
```Tcl
Param basetype name ?vtorNamespace? ?replace?
```
Creates an application defined basetype. Returns nothing. See [Custom Base Types](CustomBaseTypes.md).

where,

`name` - The name of the base type being created. An error is triggered if `name` is not unique unless `replace` is set to 1.

`vtorNamespace` - The optional validator namespace. See [Validators](CustomBaseTypes.md#validators). (default `name`)

`replace` - If 1, any existing base type definition will be replaced with this one. (default 0)

### Param getBasetype
```tcl
Param getBasetype typedefName
```
Returns the base type of a type definition.

where,

`typedefName` - The type definition name.



## Usage Examples

### Base Type Params
Base types that support typedefs (see [VTOR::createTypedef_](CustomBaseTypes.md#validator-variables)) can be used
for parameters. These parameters will have an unlimited range.
```
set poi [Param new integer 33]
$poi = 77

set pod [Param new double 33.33]
$pod = 77.77

# real is an alias of double
set por [Param new real 44.55]
$por = 66.88

set pos [Param new string {hello}]
$pos = {world!}

# enum requires a range! It must be typedef'ed.
set enum [Param new enum] ;# ERROR
```
