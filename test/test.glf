#
# Copyright 2016 (c) Pointwise, Inc.
# All rights reserved.
#
# This sample script is not supported by Pointwise, Inc.
# It is provided freely for demonstration purposes only.
# SEE THE WARRANTY DISCLAIMER AT THE BOTTOM OF THIS FILE.
#

package require PWI_Glyph

source [file join [file dirname [info script]] .. RefinedEntity.glf]


proc getMask {} {
  return [pw::Display createSelectionMask \
              -requireConnector {Dimensioned} \
              -requireDomain {Structured} \
              -requireBlock {Structured}]
}


proc mergeArray { arrVar } {
  upvar $arrVar arr
  set ret {}
  foreach key [array names arr] {
    set ret [concat $ret $arr($key)]
  }
  return $ret
}


proc getUserSelection { selectedVar } {
  upvar 1 $selectedVar selected
  set ret [pw::Display selectEntities -description {Select ents} \
                        -selectionmask [getMask] picks]
  if { $ret } {
    set selected [mergeArray picks]
  }
  return $ret
}


proc getCurrentSelection { selectedVar } {
  upvar 1 $selectedVar selected
  set ret [pw::Display getSelectedEntities -selectionmask [getMask] picks]
  if { $ret } {
    set selected [mergeArray picks]
  }
  return $ret
}


proc getSelection { selectedVar } {
  upvar 1 $selectedVar selected
  set ret [getCurrentSelection selected]
  if { !$ret } {
    set ret [getUserSelection selected]
  }
  return $ret
}


proc main {} {
  Debug setVerbose 0
  set ents []
  if { [getSelection ents] } {
    foreach ent $ents {
      set refEnt [pw::RefinedEntity new $ent 2]
      Debug vputs "---------"
      Debug vputs "$refEnt getEnt = [$refEnt getEnt]"
      Debug vputs "$refEnt getMult = [$refEnt getMult]"
      Debug vputs "$refEnt getOrigDimensions = [$refEnt getOrigDimensions]"
      Debug vputs "$refEnt getDimensions = [$refEnt getDimensions]"
      $refEnt dump
      $refEnt delete
    }
  }
}

main

#
# DISCLAIMER:
# TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, POINTWISE DISCLAIMS
# ALL WARRANTIES, EITHER EXPRESS OR IMPLIED, INCLUDING, BUT NOT LIMITED
# TO, IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
# PURPOSE, WITH REGARD TO THIS SCRIPT. TO THE MAXIMUM EXTENT PERMITTED
# BY APPLICABLE LAW, IN NO EVENT SHALL POINTWISE BE LIABLE TO ANY PARTY
# FOR ANY SPECIAL, INCIDENTAL, INDIRECT, OR CONSEQUENTIAL DAMAGES
# WHATSOEVER (INCLUDING, WITHOUT LIMITATION, DAMAGES FOR LOSS OF
# BUSINESS INFORMATION, OR ANY OTHER PECUNIARY LOSS) ARISING OUT OF THE
# USE OF OR INABILITY TO USE THIS SCRIPT EVEN IF POINTWISE HAS BEEN
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGES AND REGARDLESS OF THE
# FAULT OR NEGLIGENCE OF POINTWISE.
#
