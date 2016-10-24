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


proc statMsg { lbl pass delta ptCnt } {
  set msec $delta
  set h [expr {$msec / 3600000}]
  set msec [expr {$msec - $h * 3600000}]
  set m [expr {$msec / 60000}]
  set msec [expr {$msec - $m * 60000}]
  set s [expr {$msec / 1000}]
  set msec [expr {$msec - $s * 1000}]
  set hmsm [format "%02d:%02d:%02d.%03d" $h $m $s $msec]
  statTableRow $lbl $pass $hmsm $ptCnt [expr {(1000 * $ptCnt) / $delta}]
}


proc statTableRow { args } {
  set align right
  set filler {}
  set more 1
  while { $more } {
    switch -- [lindex $args 0] {
    -align { set args [lassign $args --> align] }
    -fill { set args [lassign $args --> filler] }
    -- { set args [lassign $args -->] ; set more 0 }
    default { set more 0 }
    }
  }
  switch -nocase -- $align {
  left  { set align - }
  right { set align {} }
  }
  if { 0 == [string length $filler] } {
    set filler -
  }
  if { [llength $args] < 5 } {
    set dash [string repeat $filler 50]
    lappend args $dash $dash $dash $dash $dash
  }
  lassign $args v1 v2 v3 v4 v5
  #         Entity     Pass            Time              NumPts          Pts/sec
  format "| %-10.10s | %${align}4.4s | %${align}12.12s | %${align}7.7s | %${align}8.8s |" $v1 $v2 $v3 $v4 $v5
}


proc run { intpEnt pass statsVar } {
  upvar $statsVar stats
  #$intpEnt dump
  set createPts 0
  set ptCnt 0
  set isBlkEnt [[$intpEnt getEntity] isOfType pw::Block]
  set start [clock milliseconds]
  $intpEnt foreach ndx xyz isDb uvDb {
    #set isBlkBndry [expr {$isBlkEnt && ![$intpEnt isInteriorIndex $ndx]}]
    #if { $createPts && ($isDb || $isBlkBndry) } {
    #  [set dbPt [pw::Point create]] setPoint $xyz
    #  $dbPt setName "pt($ndx)"
    #  $dbPt setColor [expr {$isDb ? {#00ff00} : {#008800}}]
    #  $dbPt setRenderAttribute ColorMode Entity
    #}
    incr ptCnt
  }
  set finish [clock milliseconds]
  set delta [expr {$finish - $start + 1}] ;# dont allow zero
  puts [statMsg [[$intpEnt getEnt] getName] $pass $delta $ptCnt]
  dict incr stats PTCNT $ptCnt
  dict incr stats DELTA $delta
}


proc main {} {
  Debug setVerbose 0
  set ents []
  if { [getSelection ents] } {

    set mult 3

    set stats1 [dict create]
    set stats2 [dict create]
    puts "| Mult = $mult"
    puts [statTableRow -align left Entity Pass Time NumPts Pts/sec]
    foreach ent [lsort -dictionary $ents] {
      set intpEnt [pw::InterpolatedEntity new $ent $mult]
      puts [statTableRow]
      run $intpEnt 1 stats1
      run $intpEnt 2 stats2
      $intpEnt delete
    }
    puts [statTableRow -fill =]
    set delta1 [dict get $stats1 DELTA]
    set ptCnt [dict get $stats1 PTCNT]
    puts [statMsg TOTAL 1 $delta1 $ptCnt]
    set delta2 [dict get $stats2 DELTA]
    set ptCnt [dict get $stats2 PTCNT]
    puts [statMsg TOTAL 2 $delta2 $ptCnt]
    puts [format "| ratio: %.1f" [expr {1.0 * $delta1 / $delta2}]]
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
