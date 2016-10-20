#
# Copyright 2016 (c) Pointwise, Inc.
# All rights reserved.
#
# This sample script is not supported by Pointwise, Inc.
# It is provided freely for demonstration purposes only.
# SEE THE WARRANTY DISCLAIMER AT THE BOTTOM OF THIS FILE.
#

package require PWI_Glyph

source [file join [file dirname [info script]] .. InterpolatedEntity.glf]


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


proc statMsg { caching delta ptCnt } {
  format "caching $caching: Used $delta milliseconds for $ptCnt points (%.1f pts/msec)." [expr {1.0 * $ptCnt / $delta}]
}

proc run { ent mult statsVar } {
  upvar $statsVar stats
  foreach caching {0 1} {
    set intpEnt [pw::InterpolatedEntity new $ent $mult]
    $intpEnt setXyzCaching $caching
    #$intpEnt dump
    set ptCnt 0
    set start [clock milliseconds]
    $intpEnt foreach ndx xyz {
      incr ptCnt
      #[set dbPt [pw::Point create]] setPoint $xyz
      #$dbPt setName "pt($ndx)"
    }
    set finish [clock milliseconds]
    set delta [expr {$finish - $start + 1}] ;# dont allow zero
    puts [statMsg $caching $delta $ptCnt]
    $intpEnt delete
    set tmpCnt [dict get $stats COUNTS $caching]
    dict set stats COUNTS $caching [incr tmpCnt $ptCnt]
    set tmpDelta [dict get $stats DELTAS $caching]
    dict set stats DELTAS $caching [incr tmpDelta $delta]
  }
}


proc main {} {
  Debug setVerbose 0
  set ents []
  if { [getSelection ents] } {
    set stats [dict create]
    dict set stats COUNTS 0 0
    dict set stats COUNTS 1 0
    dict set stats DELTAS 0 0
    dict set stats DELTAS 1 0
    foreach ent $ents {
      puts "**** [$ent getName] ****"
      run $ent 4 stats
    }
    puts {}
    puts "Totals:"
    foreach caching {0 1} {
      set delta [dict get $stats DELTAS $caching]
      set ptCnt [dict get $stats COUNTS $caching]
      puts [statMsg $caching $delta $ptCnt]
    }
    puts {}
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
