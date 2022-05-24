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

class m8f_ls_EventHandler : EventHandler
{

  // overrides section /////////////////////////////////////////////////////////

  override void OnRegister()
  {
    _isInitialized = false;
  }

  override void WorldLoaded(WorldEvent event)
  {
    _isTitlemap = CheckTitlemap();
  }

  override void WorldTick()
  {
    if (_isTitlemap) { return; }

    if (!_isInitialized) { SetupPuff(players[consolePlayer]); }

    if (!_puffMainhand && !_puffOffhand) { return; }

    _puffMainhand.bInvisible = true;
    _puffOffhand.bInvisible = true;

    if (!_settings.isEnabled() && !_settings.beamEnabled()) { return; }
    if (_player.readyWeapon == null && _player.OffhandWeapon == null) { return; }

    bool negative = (_settings.targetColorChange()   && _settings.hasTarget());
    bool friendly = (_settings.friendlyColorChange() && _settings.isTargetFriendly());

    ShowLaserSight(negative, friendly, _player);
  }

  // methods section ///////////////////////////////////////////////////////////

  private void SetupPuff(PlayerInfo player)
  {
    if (player == null) { return; }

    // clear existing laser points
    Array<Actor> deleteList;
    let iterator = ThinkerIterator.Create("m8f_ls_LaserPuff");
    Actor toDelete;
    while (toDelete = Actor(iterator.next(true)))
    {
      deleteList.push(toDelete);
    }
    int size = deleteList.size();
    for (int i = 0; i < size; ++i)
    {
      deleteList[i].Destroy();
    }

    _player        = players[consolePlayer];
    _settings      = m8f_ls_Settings.of();
    _puffMainhand  = Actor.Spawn("m8f_ls_LaserPuff");
    _puffOffhand   = Actor.Spawn("m8f_ls_LaserPuff");
    _isInitialized = true;

    _puffMainhand.bInvisible = true;
    _puffOffhand.bInvisible = true;
  }

  private void ShowLaserSight(bool negative, bool friendly, PlayerInfo player)
  {
    Actor a = player.mo;
    if (a == null) { return; }

    double pitch = a.AimTarget() ? a.BulletSlope(null, ALF_PORTALRESTRICT) : a.pitch;

    if (player.ReadyWeapon != null)
    {
      MaybeShowDot(pitch, a, negative, friendly, 0);
      MaybeShowBeam(pitch, a, negative, friendly, 0);
	}
    if (player.OffhandWeapon != null)
    {
      MaybeShowDot(pitch, a, negative, friendly, 1);
      MaybeShowBeam(pitch, a, negative, friendly, 1);
    }
  }

  private void MaybeShowDot(double pitch, Actor a, bool negative, bool friendly, int hand)
  {
    if (!_settings.isEnabled()) { return; }
	
    if (_settings.hideOnMeleeWeap() && IsMeleeWeapon(_player, hand)) { return; }
    if (_settings.onlyWhenReady() && !IsWeaponReady(_player, hand)) { return; }
	
    let tempPuffClass = _settings.hideOnSky()
      ? "m8f_ls_InvisiblePuff"
      : "ls_InvisibleSkyPuff";

    Actor tempPuff = a.LineAttack( a.angle
                                 , maxDistance
                                 , pitch
                                 , 0
                                 , "none"
                                 , tempPuffClass
                                 , lFlags | (!!hand ? LAF_ISOFFHAND : 0)
                                 );

    if (tempPuff == null) { return; }

    double distance = a.Distance3D(tempPuff);
    if (_settings.hideOnCloseDistance() && distance < minDistance) { return; }

    double scale = _settings.isDistanceSize()
      ? _settings.scale() * (distance ** _settings.distanceMultiplier()) / 500.0
      : _settings.scale();

    double opacity = _settings.opacity();

    string shade;
    if (friendly)      { shade = _settings.friendlyColor(); }
    else if (negative) { shade = _settings.targetColor();   }
    else               { shade = _settings.noTargetColor(); }

    let _puff = !!hand ? _puffOffhand : _puffMainhand;
    _puff.SetShade(shade);
    _puff.scale.x    = scale;
    _puff.scale.y    = scale;
    _puff.bInvisible = false;
    _puff.alpha      = opacity;
    _puff.SetOrigin(tempPuff.pos, true);
  }

  private void MaybeShowBeam(double pitch, Actor a, bool negative, bool friendly, int hand)
  {
    if (!_settings.beamEnabled()) { return; }
	
    if (_settings.hideOnMeleeWeap() && IsMeleeWeapon(_player, hand)) { return; }
    if (_settings.onlyWhenReady() && !IsWeaponReady(_player, hand)) { return; }
	let _vel = _player.mo.vel;
	if(_settings.beamMoveHide() && (abs(_vel.x) > 2 || abs(_vel.y) > 2 || abs(_vel.z) > 2)) { return; }

    Actor  tempPuff = a.LineAttack( a.angle
                                  , maxDistance
                                  , pitch
                                  , 0
                                  , "none"
                                  , "m8f_ls_BeamInvisiblePuff"
                                  , lFlags | (!!hand ? LAF_ISOFFHAND : 0)
                                  );

    if (tempPuff == null) { return; }

    double distance = a.Distance3D(tempPuff);

    string shade;
    if (friendly)      { shade = _settings.friendlyColor(); }
    else if (negative) { shade = _settings.targetColor();   }
    else               { shade = _settings.noTargetColor(); }

    showBeam(a, tempPuff.pos, distance, shade, hand);
  }

  private void ShowBeam(Actor a, vector3 targetPos, double distance, string shade, int hand)
  {
    color   beamColor  = shade;
    double  size       = 0.5 * _settings.beamScale();
	vector3 wpos       = !!hand ? _player.mo.OffhandPos : _player.mo.AttackPos;

    vector3 relPos = targetPos - wpos;
    int     nSteps = int(distance / _settings.beamStep());

    if (nSteps == 0) { return; }

    double  xStep     = relPos.x / nSteps;
    double  yStep     = relPos.y / nSteps;
    double  zStep     = relPos.z / nSteps;
    double  alpha     = _settings.beamOpacity();
    int     drawSteps = nSteps - 2;

	Actor wdummy = Actor.Spawn("m8f_ls_BeamInvisiblePuff", wpos);
	
    for (int i = 2; i < drawSteps; ++i)
    {
      double xoff = xStep * i;
      double yoff = yStep * i;
      double zoff = zStep * i;

      wdummy.A_SpawnParticle( beamColor, beamFlags, beamLifetime, size, beamAngle
                       , xoff, yoff, zoff
                       , beamVel, beamVel, beamVel, beamAcc, beamAcc, beamAcc
                       , alpha
                       );
    }
	
	wdummy.destroy();
  }

  // static functions section //////////////////////////////////////////////////

  private play static bool IsMeleeWeapon(PlayerInfo player, int hand)
  {
    Weapon w = !!hand ? player.OffhandWeapon : player.ReadyWeapon;
    if (w == null) { return false; }

	return w.bMeleeWeapon;
  }

  private static bool CheckTitlemap()
  {
    bool isTitlemap = (level.mapname == "TITLEMAP");
    return isTitlemap;
  }

  private static bool IsWeaponReady(PlayerInfo player, int hand)
  {
    if (!player) { return false; }
    int readystate = !!hand ? WF_OFFHANDREADY : WF_WEAPONREADY;
    int altstate = !!hand ? WF_OFFHANDREADYALT : WF_WEAPONREADYALT;

    bool isReady = (player.WeaponState & readystate)
      || (player.WeaponState & altstate);

    return isReady;
  }

  // constants section /////////////////////////////////////////////////////////

  const maxDistance = 400000.0;
  const minDistance = 50.0;
  const lFlags      = LAF_NOIMPACTDECAL | LAF_NORANDOMPUFFZ;

  const beamLifetime = 1;
  const beamFlags    = SPF_FULLBRIGHT;
  const beamAngle    = 0.0;
  const beamVel      = 0.0;
  const beamAcc      = 0.0;

  // attributes section ////////////////////////////////////////////////////////

  private bool            _isTitlemap;
  private bool            _isInitialized;
  private m8f_ls_Settings _settings;
  private PlayerInfo      _player;
  private Actor           _puffMainhand;
  private Actor           _puffOffhand;

} // class m8f_ls_EventHandler
