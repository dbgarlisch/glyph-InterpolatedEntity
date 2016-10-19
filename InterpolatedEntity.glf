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
    namespace eval $ret $::pw::InterpolatedEntity::RefinedEntityProto_
    switch [$ent getType] {
    pw::Connector {
      namespace eval $ret $::pw::InterpolatedEntity::RefinedConProto_
      set dimty 1
    }
    pw::DomainStructured {
      namespace eval $ret $::pw::InterpolatedEntity::RefinedDomProto_
      set dimty 2
    }
    pw::BlockStructured {
      namespace eval $ret $::pw::InterpolatedEntity::RefinedBlkProto_
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


  variable RefinedEntityProto_ {
    variable self_  {}
    variable ent_   {}   ;# the entity being refined
    variable mult_  1.0  ;# refinement multiplier
    variable dimty_ 0    ;# ent_ dimensionality

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
      foreach numPts [$ent_ getDimensions] {
        lappend ret [expr {($numPts - 1) * $mult_ + 1}]
      }
      return $ret
    }

    public proc delete {} {
      variable self_
      namespace delete $self_
    }

    private proc getOrigBracket { ndx sVar } {
      # returns pair of original ent indices that bracket ndx
      # ndx is 1-based
      variable mult_
      upvar $sVar s
      set orig2 [set orig1 [expr {($ndx - 1) / $mult_ + 1}]]
      set ndx1 [expr {($orig1 - 1) * $mult_ + 1}]
      # TODO: use precomputed lookup table for s as:
      #       set s [lindex $sTable [expr {$ndx - $ndx1}]]
      #       Is this really faster??
      set s [expr {double($ndx - $ndx1) / $mult_}]
      if { $ndx != $ndx1 } {
        # ndx lies between original indices orig1 and orig2
        incr orig2
      }
      #else
      # ndx and orig1 are coincident - leave orig2 == orig1
      return [list $orig1 $orig2] ;# return 1-based indices
    }
  }

  variable RefinedConProto_ {
    public proc getXYZ { ndx } {
      variable ent_
      variable mult_
      lassign $ndx ndx ;# ignore extra indices
      lassign [getOrigBracket $ndx s] origI1 origI2
      if { $origI1 == $origI2 } {
        # ndx is coincident with an original grid point. Get xyz directly!
        set ret [$ent_ getXYZ -grid $origI1]
      } else {
        # Must interpolate xyz
        set ret [pwu::Vector3 affine $s [$ent_ getXYZ -grid $origI1] [$ent_ getXYZ -grid $origI2]]
      }
      return $ret
    }

    public proc dump {} {
      variable self_
      variable ent_
      puts "Processing connector [$ent_ getName]"
      for {set ii 1} {$ii <= [$self_ getDimensions]} {incr ii} {
        set xyz [$self_ getXYZ $ii]
        Debug vputs [format "  $ii ==> [${self_}::getOrigBracket $ii s] @ %5.3f ==> %s" $s $xyz]
        [pw::Point create] setPoint $xyz
      }
    }
  }

  variable RefinedDomProto_ {
    public proc getXYZ { ndx } {
      variable ent_
      variable mult_
      set ndx [lrange $ndx 0 1]  ;# ignore extra indices
      lassign $ndx i j
      lassign [getOrigBracket $i sI] origI1 origI2
      lassign [getOrigBracket $j sJ] origJ1 origJ2
      if { $origI1 == $origI2 && $origJ1 == $origJ2 } {
        # ndx is coincident with an original grid point. Get xyz directly!
        set ret [$ent_ getXYZ -grid [list $origI1 $origJ1]]
      } elseif { $origI1 == $origI2 } {
        # Along original J edge, Interpolate xyz between origJ1 and origJ2
        set ret [pwu::Vector3 affine $sJ [$ent_ getXYZ -grid [list $origI1 $origJ1]] [$ent_ getXYZ -grid [list $origI1 $origJ2]]]
      } elseif { $origJ1 == $origJ2 } {
        # Along original I edge, Interpolate xyz between origI1 and origI2
        set ret [pwu::Vector3 affine $sI [$ent_ getXYZ -grid [list $origI1 $origJ1]] [$ent_ getXYZ -grid [list $origI2 $origJ1]]]
      } else {
        set ret [::pw::InterpolatedEntity::interpolateQuad \
                  [$ent_ getXYZ -grid [list $origI1 $origJ1]] \
                  [$ent_ getXYZ -grid [list $origI2 $origJ1]] \
                  [$ent_ getXYZ -grid [list $origI2 $origJ2]] \
                  [$ent_ getXYZ -grid [list $origI1 $origJ2]] $sI $sJ]
      }
      return $ret
    }

    public proc dump {} {
      variable self_
      variable ent_
      lassign [$self_ getDimensions] iDim jDim
      puts "Processing domain [$ent_ getName]"
      for {set ii 1} {$ii <= $iDim} {incr ii} {
        puts "  ${ii} of $iDim"
        for {set jj 1} {$jj <= $jDim} {incr jj} {
          set ndx [list $ii $jj]
          set iBracket [${self_}::getOrigBracket $ii sI]
          set jBracket [${self_}::getOrigBracket $jj sJ]
          set xyz [$self_ getXYZ $ndx]
          Debug vputs [format "  [list $ndx] ==> [list $iBracket] @ %5.3f [list $jBracket]  @ %5.3f ==> %s" $sI $sJ $xyz]
          [pw::Point create] setPoint $xyz
        }
      }
    }
  }

  variable RefinedBlkProto_ {
    public proc getXYZ { ndx } {
      variable ent_
      variable mult_
      set ndx [lrange $ndx 0 2]  ;# ignore extra indices
      lassign $ndx i j k
      lassign [getOrigBracket $i sI] origI1 origI2
      lassign [getOrigBracket $j sJ] origJ1 origJ2
      lassign [getOrigBracket $k sK] origK1 origK2
      if { $origI1 == $origI2 && $origJ1 == $origJ2 && $origK1 == $origK2 } {
        # ndx is coincident with an original grid point. Get xyz directly!
        set ret [$ent_ getXYZ -grid [list $origI1 $origJ1 $origK1]]
      } elseif { $origI1 == $origI2 && $origJ1 == $origJ2 } {
        # Along original K edge, Interpolate xyz between origK1 and origK2
        set ret [pwu::Vector3 affine $sK [$ent_ getXYZ -grid [list $origI1 $origJ1 $origK1]] [$ent_ getXYZ -grid [list $origI1 $origJ1 $origK2]]]
      } elseif { $origI1 == $origI2 && $origK1 == $origK2 } {
        # Along original J edge, Interpolate xyz between origJ1 and origJ2
        set ret [pwu::Vector3 affine $sJ [$ent_ getXYZ -grid [list $origI1 $origJ1 $origK1]] [$ent_ getXYZ -grid [list $origI1 $origJ2 $origK1]]]
      } elseif { $origJ1 == $origJ2 && $origK1 == $origK2 } {
        # Along original I edge, Interpolate xyz between origI1 and origI2
        set ret [pwu::Vector3 affine $sI [$ent_ getXYZ -grid [list $origI1 $origJ1 $origK1]] [$ent_ getXYZ -grid [list $origI2 $origJ1 $origK1]]]
      } else {
        set ret [::pw::InterpolatedEntity::interpolateHex \
                  [$ent_ getXYZ -grid [list $origI1 $origJ1 $origK1]] \
                  [$ent_ getXYZ -grid [list $origI2 $origJ1 $origK1]] \
                  [$ent_ getXYZ -grid [list $origI2 $origJ2 $origK1]] \
                  [$ent_ getXYZ -grid [list $origI1 $origJ2 $origK1]] \
                  [$ent_ getXYZ -grid [list $origI1 $origJ1 $origK2]] \
                  [$ent_ getXYZ -grid [list $origI2 $origJ1 $origK2]] \
                  [$ent_ getXYZ -grid [list $origI2 $origJ2 $origK2]] \
                  [$ent_ getXYZ -grid [list $origI1 $origJ2 $origK2]] \
                  $sI $sJ $sK]
      }
      return $ret
    }

    public proc dump {} {
      variable self_
      variable ent_
      lassign [$self_ getDimensions] iDim jDim kDim
      puts "Processing block [$ent_ getName]"
      for {set ii 1} {$ii <= $iDim} {incr ii} {
        puts "  ${ii} of $iDim"
        for {set jj 1} {$jj <= $jDim} {incr jj} {
          for {set kk 1} {$kk <= $kDim} {incr kk} {
            set ndx [list $ii $jj $kk]
            set iBracket [${self_}::getOrigBracket $ii sI]
            set jBracket [${self_}::getOrigBracket $jj sJ]
            set kBracket [${self_}::getOrigBracket $kk sK]
            set xyz [$self_ getXYZ $ndx]
            Debug vputs [format "  [list $ndx] ==> [list $iBracket] @ %5.3f [list $jBracket]  @ %5.3f [list $kBracket]  @ %5.3f ==> %s" $sI $sJ $sK $xyz]
            [pw::Point create] setPoint $xyz
          }
        }
      }
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
