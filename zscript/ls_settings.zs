// Copyright 2018-2020 Alexander Kromm (m8f/mmaulwurff)
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see http://www.gnu.org/licenses/

class m8f_ls_Settings
{

  bool   targetColorChange()   { return targetColorChangeCvar.getBool();   }
  bool   friendlyColorChange() { return friendlyColorChangeCvar.getBool(); }

  bool   hideOnMeleeWeap()     { return hideOnMeleeCvar.getBool();         }
  bool   hideOnCloseDistance() { return hideOnCloseDistanceCvar.getBool(); }
  bool   onlyWhenReady()       { return onlyWhenReadyCvar.getBool();       }
  bool   hideOnSky()           { return hideOnSkyCvar.getBool();           }

  string noTargetColor()       { return noTargetColorCvar.getString();     }
  string targetColor()         { return targetColorCvar.getString();       }
  string friendlyColor()       { return friendlyColorCvar.getString();     }

  double scale()               { return scaleCvar.getDouble();             }
  double beamScale()           { return beamScaleCvar.getDouble();         }
  double opacity()             { return opacityCvar.getDouble();           }

  bool   isDistanceSize()      { return distanceSizeCvar.getBool();        }
  double distanceMultiplier()  { return distanceMultCvar.getDouble();      }

  bool   beamEnabled()         { return beamEnabledCvar.getBool();         }
  bool   beamMoveHide()        { return beamHideCvar.getBool();            }
  double beamOpacity()         { return beamOpacityCvar.getDouble();       }
  double beamStep()            { return beamStepCvar.getDouble();          }

  bool   isEnabled()           { return isEnabledCvar.getBool();           }

  bool hasTarget()        { return hasTargetCvar     .isDefined() && hasTargetCvar     .getBool(); }
  bool isTargetFriendly() { return friendlyTargetCvar.isDefined() && friendlyTargetCvar.getBool(); }

  static
  m8f_ls_Settings of()
  {
    let result = new("m8f_ls_Settings");

    result.targetColorChangeCvar   = ls_Cvar.of("m8f_wm_TSChangeLaserColor");
    result.friendlyColorChangeCvar = ls_Cvar.of("m8f_ls_TSChangeColorFriendly");

    result.hideOnMeleeCvar         = ls_Cvar.of("m8f_ls_hideOnMeleeWeap");
    result.hideOnCloseDistanceCvar = ls_Cvar.of("m8f_ls_hide_close");
    result.onlyWhenReadyCvar       = ls_Cvar.of("m8f_ls_OnlyWhenReady");
    result.hideOnSkyCvar           = ls_Cvar.of("m8f_ls_hide_on_sky");

    result.noTargetColorCvar       = ls_Cvar.of("m8f_ls_CustomColor");
    result.targetColorCvar         = ls_Cvar.of("m8f_ls_ColorOnTarget");
    result.friendlyColorCvar       = ls_Cvar.of("m8f_ls_FriendlyColor");

    result.scaleCvar               = ls_Cvar.of("m8f_ls_Scale");
    result.beamScaleCvar           = ls_Cvar.of("m8f_ls_BeamScale");
    result.opacityCvar             = ls_Cvar.of("m8f_ls_Opacity");

    result.distanceSizeCvar        = ls_Cvar.of("m8f_ls_distance_size");
    result.distanceMultCvar        = ls_Cvar.of("m8f_ls_distance_mult");

    result.beamEnabledCvar         = ls_Cvar.of("m8f_ls_BeamEnabled");
    result.beamHideCvar            = ls_Cvar.of("m8f_ls_BeamMoveHide");
    result.beamOpacityCvar         = ls_Cvar.of("m8f_ls_BeamOpacity");
    result.beamStepCvar            = ls_Cvar.of("m8f_ls_BeamStep");

    result.isEnabledCvar           = ls_Cvar.of("m8f_wm_ShowLaserSight");

    result.hasTargetCvar           = ls_Cvar.of("m8f_ts_has_target");
    result.friendlyTargetCvar      = ls_Cvar.of("m8f_ts_friendly_target");

    return result;
  }

  private ls_Cvar targetColorChangeCvar;
  private ls_Cvar friendlyColorChangeCvar;

  private ls_Cvar hideOnMeleeCvar;
  private ls_Cvar hideOnCloseDistanceCvar;
  private ls_Cvar onlyWhenReadyCvar;
  private ls_Cvar hideOnSkyCvar;

  private ls_Cvar noTargetColorCvar;
  private ls_Cvar targetColorCvar;
  private ls_Cvar friendlyColorCvar;

  private ls_Cvar scaleCvar;
  private ls_Cvar beamScaleCvar;
  private ls_Cvar opacityCvar;

  private ls_Cvar distanceSizeCvar;
  private ls_Cvar distanceMultCvar;

  private ls_Cvar beamEnabledCvar;
  private ls_Cvar beamHideCvar;
  private ls_Cvar beamOpacityCvar;
  private ls_Cvar beamStepCvar;

  private ls_Cvar isEnabledCvar;

  // not settings, but public API.
  private ls_Cvar hasTargetCvar;
  private ls_Cvar friendlyTargetCvar;

} // class m8f_ls_Settings

/**
 * This class provides access to a user or server Cvar.
 *
 * Accessing Cvars through this class is faster because calling Cvar.GetCvar()
 * is costly. This class caches the result of Cvar.GetCvar() and handles
 * loading a savegame.
 */
class ls_Cvar
{

// public: /////////////////////////////////////////////////////////////////////

  static
  ls_Cvar of(String name)
  {
    let result = new("ls_Cvar");
    result._name = name;
    return result;
  }

  bool   isDefined() { load(); return (_cvar != NULL);   }

  String getString() { load(); return _cvar.GetString(); }
  bool   getBool()   { load(); return _cvar.GetInt();    }
  int    getInt()    { load(); return _cvar.GetInt();    }
  double getDouble() { load(); return _cvar.GetFloat();  }

// private: ////////////////////////////////////////////////////////////////////

  private
  void load()
  {
    if (_cvar == NULL)
    {
      PlayerInfo player = players[consolePlayer];

      _cvar = Cvar.GetCvar(_name, player);
    }
  }

  private String         _name;
  private transient Cvar _cvar;

} // class ls_Cvar
