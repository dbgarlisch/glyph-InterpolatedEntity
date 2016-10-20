#
# Copyright 2016 (c) Pointwise, Inc.
# All rights reserved.
#
# This sample script is not supported by Pointwise, Inc.
# It is provided freely for demonstration purposes only.
# SEE THE WARRANTY DISCLAIMER AT THE BOTTOM OF THIS FILE.
#

if { [namespace exists ::pw::InterpolatedEntity] } return

package require PWI_Glyph

source [file join [file dirname [info script]] .. tcl-Utils ProcAccess.tcl]
source [file join [file dirname [info script]] .. tcl-Utils Debug.tcl]


#####################################################################
#                       public namespace procs
#####################################################################
namespace eval ::pw::InterpolatedEntity {
  variable cnt_ 0

  public proc new { ent mult } {
    set ret "::pw::InterpolatedEntity::_[incr ::pw::InterpolatedEntity::cnt_]"
    namespace eval $ret $::pw::InterpolatedEntity::InterpolatedEntityProto_
    switch [$ent getType] {
    pw::Connector {
      namespace eval $ret $::pw::InterpolatedEntity::InterpolatedConProto_
      set dimty 1
    }
    pw::DomainStructured {
      namespace eval $ret $::pw::InterpolatedEntity::InterpolatedDomProto_
      set dimty 2
    }
    pw::BlockStructured {
      namespace eval $ret $::pw::InterpolatedEntity::InterpolatedBlkProto_
      set dimty 3
    }
    default {
      error "Unsuported entity type [$ent getType]"
    }}
    ${ret}::ctor $ret $ent $mult $dimty
    namespace eval $ret {
      namespace ensemble create
    }
  }


  private proc interpolateQuad { pt11 pt21 pt22 pt12 sI sJ } {
    # Linearly interpolate $ret on quad interior.
    # Given: 4 corner points and normalized edge distances sI and sJ
    #
    #      pt12---ptJ2---pt22
    #       |      :      |
    #       |      :      |
    #    >  |.....$ret    |
    #    >  |      :      |
    # sJ >  |      :      |
    #    > pt11---ptJ1---pt21
    #       ^^^^^^^^
    #         sI
    return [pwu::Vector3 affine $sJ [pwu::Vector3 affine $sI $pt11 $pt21] \
                                    [pwu::Vector3 affine $sI $pt12 $pt22]]
  }


  private proc interpolateHex { pt111 pt211 pt221 pt121 pt112 pt212 pt222 pt122 sI sJ sK } {
    # Linearly interpolate $ret on hex interior.
    # Given: 8 corner points and normalized edge distances sI, sJ, and sK
    #
    #            K==1 face                      K==2 face
    #      pt121---ptJ21---pt221          pt122---ptJ22---pt222
    #       |       :       |              |       :       |
    #       |       :       |              |       :       |
    #    >  |......$ptK1    |           >  |......$ptK2    |
    #    >  |       :       |           >  |       :       |
    # sJ >  |       :       |        sJ >  |       :       |
    #    > pt111---ptJ11---pt211        > pt112---ptJ12---pt212
    #       ^^^^^^^^^                      ^^^^^^^^^
    #          sI                             sI
    return [pwu::Vector3 affine $sK [interpolateQuad $pt111 $pt211 $pt221 $pt121 $sI $sJ] \
                                    [interpolateQuad $pt112 $pt212 $pt222 $pt122 $sI $sJ]]
  }


  variable InterpolatedEntityProto_ {
    variable self_      {}
    variable ent_       {}   ;# the entity being refined
    variable mult_      1.0  ;# refinement multiplier
    variable dimty_     0    ;# ent_ dimensionality
    variable useCache_  0    ;# set 1 to enable xyz caching
    variable cache_     {}   ;# dict {i j k} --> {x y z}

    private proc ctor { self ent mult dimty } {
      variable self_
      variable ent_
      variable mult_
      variable dimty_
      set self_ $self
      set ent_ $ent
      set mult_ $mult
      set dimty_ $dimty
    }

    public proc getEnt {} {
      variable ent_
      return $ent_
    }

    public proc getMult {} {
      variable mult_
      return $mult_
    }

    public proc getDimensionality {} {
      variable dimty_
      return $dimty_
    }

    public proc getOrigDimensions {} {
      variable ent_
      return [$ent_ getDimensions]
    }

    public proc getDimensions {} {
      variable ent_
      variable mult_
      set ret {}
      ::foreach numPts [$ent_ getDimensions] {
        lappend ret [origToIntpNdx $numPts]
      }
      return $ret
    }

    public proc getXyzCaching {} {
      variable useCache_
      return $useCache_
    }

    public proc setXyzCaching { onOff } {
      variable useCache_
      switch -nocase -- $onOff {
      0 -
      off -
      no -
      disabled -
      disable -
      false { set useCache_ 0 }
      1 -
      on -
      yes -
      enabled -
      enable -
      true { set useCache_ 1 }
      default { return -code error "Invalid boolean value '$onOff'" }
      }
    }

    public proc delete {} {
      variable self_
      namespace delete $self_
    }

    public proc dump {} {
      variable self_
      variable ent_
      set dashes [string repeat - 50]
      set fmt "| %-20.20s | %-30.30s |"
      puts {}
      puts "Processing: [$ent_ getName]"
      puts [format $fmt $dashes $dashes]
      puts [format $fmt "\$self_" $self_]
      ::foreach cmd {getEnt getMult getOrigDimensions getDimensions getXyzCaching} {
        puts [format $fmt $cmd [$self_ $cmd]]
      }
      puts [format $fmt $dashes $dashes]
    }

    public proc dumpXyzCache {} {
      variable cache_
      variable useCache_
      if { $useCache_ } {
        dict for {ndx xyz} $cache_ {
          puts [format "%-12.12s ==> %s" $ndx $xyz]
        }
      } else {
        puts "Caching disabled."
      }
    }

    private proc getOrigBracket { ndx sVar } {
      # returns pair of original ent indices that bracket ndx
      # ndx is 1-based
      upvar $sVar s
      variable mult_
      set orig2 [set orig1 [expr {($ndx - 1) / $mult_ + 1}]]
      set ndx1 [origToIntpNdx $orig1]
      # TODO: use precomputed lookup table for s as:
      #       set s [lindex $sTable [expr {$ndx - $ndx1}]]
      #       Is this really faster??
      set s [expr {double($ndx - $ndx1) / $mult_}]
      if { $ndx != $ndx1 } {
        # ndx lies between original indices orig1 and orig2
        incr orig2
      }
      #else ndx and orig1 are coincident - leave orig2 == orig1
      return [list $orig1 $orig2] ;# return 1-based indices
    }

    private proc getCachedXyz { ndx xyzVar } {
      variable cache_
      variable useCache_
      upvar $xyzVar xyz
      if { $useCache_ && ![catch {dict get $cache_ $ndx} xyz] } {
        return 1
      }
      set xyz {}
      return 0
    }

    private proc addCachedXyz { ndx xyz } {
      variable cache_
      variable useCache_
      if { $useCache_ } {
        dict set cache_ $ndx $xyz
      }
    }

    private proc origToIntpNdx { origNdx } {
      variable mult_
      # maps orig grid coord to its eqiv interp grid coord
      return [expr {($origNdx - 1) * $mult_ + 1}]
    }
  }

  #------------------------------------------
  variable InterpolatedConProto_ {

    public proc foreach { ndxVar xyzVar body } {
      upvar $ndxVar ndx
      upvar $xyzVar xyz
      variable self_
      lassign [$self_ getDimensions] iDim
      for {set ndx 1} {$ndx <= $iDim} {incr ndx} {
        set xyz [$self_ getXYZ $ndx]
        uplevel $body
      }
    }

    public proc getXYZ { ndx } {
      lassign $ndx ndx ;# ignore extra, trailing indices
      if { [getCachedXyz $ndx ret] } {
        return $ret
      }
      # xyz for $ndx NOT cached - need to compute xyz
      variable ent_
      lassign [getOrigBracket $ndx s] origI1 origI2
      if { $origI1 == $origI2 } {
        # ndx is coincident with an original grid point. Get xyz directly!
        set ret [$ent_ getXYZ -grid $origI1]
      } else {
        # Must interpolate xyz
        set ret [pwu::Vector3 affine $s [$ent_ getXYZ -grid $origI1] \
          [$ent_ getXYZ -grid $origI2]]
        addCachedXyz $ndx $ret
      }
      return $ret
    }
  }

  #------------------------------------------
  variable InterpolatedDomProto_ {

    public proc foreach { ndxVar xyzVar body } {
      upvar $ndxVar ndx
      upvar $xyzVar xyz
      variable self_
      lassign [$self_ getDimensions] iDim jDim
      for {set ii 1} {$ii <= $iDim} {incr ii} {
        for {set jj 1} {$jj <= $jDim} {incr jj} {
          set xyz [$self_ getXYZ [set ndx [list $ii $jj]]]
          uplevel $body
        }
      }
    }

    public proc getXYZ { ndx } {
      set ndx [lrange $ndx 0 1] ;# ignore extra, trailing indices
      if { [getCachedXyz $ndx ret] } {
        return $ret
      }
      # xyz for $ndx NOT cached - need to compute xyz
      variable ent_
      lassign $ndx i j
      lassign [getOrigBracket $i sI] origI1 origI2
      lassign [getOrigBracket $j sJ] origJ1 origJ2
      if { $origI1 == $origI2 && $origJ1 == $origJ2 } {
        # ndx is coincident with an original grid point. Get xyz directly!
        set ret [$ent_ getXYZ -grid [list $origI1 $origJ1]]
      } elseif { $origI1 == $origI2 } {
        # Along original J edge, Interpolate xyz between origJ1 and origJ2
        set ret [pwu::Vector3 affine $sJ [$ent_ getXYZ -grid [list $origI1 $origJ1]] \
                                         [$ent_ getXYZ -grid [list $origI1 $origJ2]]]
        addCachedXyz $ndx $ret
      } elseif { $origJ1 == $origJ2 } {
        # Along original I edge, Interpolate xyz between origI1 and origI2
        set ret [pwu::Vector3 affine $sI [$ent_ getXYZ -grid [list $origI1 $origJ1]] \
                                         [$ent_ getXYZ -grid [list $origI2 $origJ1]]]
        addCachedXyz $ndx $ret
      } else {
        variable mult_
        # convert J1 in orig grid to J1 in interp grid
        set intpJ1 [origToIntpNdx $origJ1]
        if { ![getCachedXyz [list $i $intpJ1] J1xyz] } {
          set J1xyz [pwu::Vector3 affine $sI [$ent_ getXYZ -grid [list $origI1 $origJ1]] \
            [$ent_ getXYZ -grid [list $origI2 $origJ1]]]
          addCachedXyz [list $i $intpJ1] $J1xyz
        }
        # convert J2 in orig grid to J2 in interp grid
        set intpJ2 [origToIntpNdx $origJ2]
        if { ![getCachedXyz [list $i $intpJ2] J2xyz] } {
          set J2xyz [pwu::Vector3 affine $sI [$ent_ getXYZ -grid [list $origI1 $origJ2]] \
            [$ent_ getXYZ -grid [list $origI2 $origJ2]]]
          addCachedXyz [list $i $intpJ2] $J2xyz
        }
        addCachedXyz $ndx [set ret [pwu::Vector3 affine $sJ $J1xyz $J2xyz]]
      }
      return $ret
    }
  }

  #------------------------------------------
  variable InterpolatedBlkProto_ {

    public proc foreach { ndxVar xyzVar body } {
      upvar $ndxVar ndx
      upvar $xyzVar xyz
      variable self_
      lassign [$self_ getDimensions] iDim jDim kDim
      for {set ii 1} {$ii <= $iDim} {incr ii} {
        for {set jj 1} {$jj <= $jDim} {incr jj} {
          for {set kk 1} {$kk <= $kDim} {incr kk} {
            set xyz [$self_ getXYZ [set ndx [list $ii $jj $kk]]]
            uplevel $body
          }
        }
      }
    }

    public proc getXYZ { ndx } {
      set ndx [lrange $ndx 0 2] ;# ignore extra, trailing indices
      if { [getCachedXyz $ndx ret] } {
        return $ret
      }
      # xyz for $ndx NOT cached - need to compute xyz
      variable ent_
      lassign $ndx i j k
      lassign [getOrigBracket $i sI] origI1 origI2
      lassign [getOrigBracket $j sJ] origJ1 origJ2
      lassign [getOrigBracket $k sK] origK1 origK2
      if { $origI1 == $origI2 && $origJ1 == $origJ2 && $origK1 == $origK2 } {
        # ndx is coincident with an original grid point. Get xyz directly!
        return [$ent_ getXYZ -grid [list $origI1 $origJ1 $origK1]]
      }
      if { $origI1 == $origI2 && $origJ1 == $origJ2 } {
        # Along original K edge, Interpolate xyz between origK1 and origK2
        set ret [pwu::Vector3 affine $sK \
          [$ent_ getXYZ -grid [list $origI1 $origJ1 $origK1]] \
          [$ent_ getXYZ -grid [list $origI1 $origJ1 $origK2]]]
      } elseif { $origI1 == $origI2 && $origK1 == $origK2 } {
        # Along original J edge, Interpolate xyz between origJ1 and origJ2
        set ret [pwu::Vector3 affine $sJ \
          [$ent_ getXYZ -grid [list $origI1 $origJ1 $origK1]] \
          [$ent_ getXYZ -grid [list $origI1 $origJ2 $origK1]]]
      } elseif { $origJ1 == $origJ2 && $origK1 == $origK2 } {
        # Along original I edge, Interpolate xyz between origI1 and origI2
        set ret [pwu::Vector3 affine $sI \
          [$ent_ getXYZ -grid [list $origI1 $origJ1 $origK1]] \
          [$ent_ getXYZ -grid [list $origI2 $origJ1 $origK1]]]
      } else {
        # In block interior - do the heavy calculations
        set ret [pwu::Vector3 affine $sK [getKFaceXyz $i $j $origK1] \
          [getKFaceXyz $i $j $origK2]]
      }
      addCachedXyz $ndx $ret
      return $ret
    }

    private proc getKFaceXyz { i j origK } {
      variable mult_
      # convert origK coord to interp K coord
      set intpK [origToIntpNdx $origK]
      # Get xyz at {$i,$j} in origK face of block
      if { ![getCachedXyz [list $i $j $intpK] xyz] } {
        lassign [getOrigBracket $j sJ] origJ1 origJ2
        set xyz [pwu::Vector3 affine $sJ \
          [getJKEdgeXyz $i $origJ1 $origK] \
          [getJKEdgeXyz $i $origJ2 $origK]]
        addCachedXyz [list $i $j $intpK] $xyz
      }
      return $xyz
    }

    private proc getJKEdgeXyz { i origJ origK } {
      # Get xyz at $i along origJK edge of block
      variable mult_
      set intpJ [origToIntpNdx $origJ]
      set intpK [origToIntpNdx $origK]
      if { ![getCachedXyz [list $i $intpJ $intpK] xyz] } {
        variable ent_
        lassign [getOrigBracket $i sI] origI1 origI2
        set xyz [pwu::Vector3 affine $sI \
          [$ent_ getXYZ -grid [list $origI1 $origJ $origK]] \
          [$ent_ getXYZ -grid [list $origI2 $origJ $origK]]]
        addCachedXyz [list $i $intpJ $intpK] $xyz
      }
      return $xyz
    }
  }

  namespace ensemble create
}


# END SCRIPT

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
