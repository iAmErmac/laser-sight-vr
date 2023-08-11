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

    if (!_puff) { return; }

    _puff.bInvisible = true;
    _beam.bInvisible = true;

    if (!_settings.isEnabled()) { return; }
    if (_player.readyWeapon == null) { return; }

    bool negative = (_settings.targetColorChange()   && _settings.hasTarget());
    bool friendly = (_settings.friendlyColorChange() && _settings.isTargetFriendly());
	
	if(_beamDelayCounter > 0) _beamDelayCounter--;

    ShowLaserSight(negative, friendly, _player);
    ShowLaserBeam(negative, friendly, _player);
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
    _puff          = Actor.Spawn("m8f_ls_LaserPuff");
    _beam  		   = Actor.Spawn("m8f_ls_LaserBeam");
    _isInitialized = true;

    _puff.bInvisible = true;
    _beam.bInvisible = true;
  }

  private void ShowLaserSight(bool negative, bool friendly, PlayerInfo player)
  {
    if (!_settings.showDot()) { return; }
	
    Actor a = player.mo;
    if (a == null || a.health < 0) { return; }

    double pitch = a.AimTarget() ? a.BulletSlope(null, ALF_PORTALRESTRICT) : a.pitch;

    if (player.ReadyWeapon != null)
    {
      MaybeShowDot(pitch, a, negative, friendly);
    }
  }

  private void ShowLaserBeam(bool negative, bool friendly, PlayerInfo player)
  {
    if (!_settings.beamEnabled()) { return; }
	
    Actor a = player.mo;
    if (a == null || a.health < 0) { return; }

    double pitch = a.AimTarget() ? a.BulletSlope(null, ALF_PORTALRESTRICT) : a.pitch;

    if (player.ReadyWeapon != null)
    {
      MaybeShowBeam(pitch, a, negative, friendly);
    }
  }

  private void MaybeShowDot(double pitch, Actor a, bool negative, bool friendly)
  {
    if (_settings.hideOnMeleeWeap() && IsMeleeWeapon(_player)) { return; }
    if (_settings.onlyWhenReady() && !IsWeaponReady(_player)) { return; }
	
    let tempPuffClass = _settings.hideOnSky()
      ? "m8f_ls_InvisiblePuff"
      : "ls_InvisibleSkyPuff";

    Actor tempPuff = a.LineAttack( a.angle
                                 , maxDistance
                                 , pitch
                                 , 0
                                 , "none"
                                 , tempPuffClass
                                 , lFlags
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

    _puff.SetShade(shade);
    _puff.scale.x    = scale;
    _puff.scale.y    = scale;
    _puff.bInvisible = false;
    _puff.alpha      = opacity;
    _puff.SetOrigin(tempPuff.pos, true);
  }

  private void MaybeShowBeam(double pitch, Actor a, bool negative, bool friendly)
  {
    if (_settings.hideOnMeleeWeap() && IsMeleeWeapon(_player)) { return; }
    if (_settings.onlyWhenReady() && !IsWeaponReady(_player)) { return; }
	
    let _vel = _player.mo.vel;
    if(_settings.beamMoveHide() && (abs(_vel.x) > 2 || abs(_vel.y) > 2 || abs(_vel.z) > 2))
	{
		_beamDelayCounter = 5;
		return;
	}
	
	Inventory playerHandTracker = _player.mo.FindInventory("LSMainHandTracker");
    vector3 beamPos 			= LSMainHandTracker(playerHandTracker).AttackPos;
	int beamOffset 				= _settings.beamOffset();
	if(beamOffset > 0)
	{
		double pitch = a.AimTarget() ? a.BulletSlope(null, ALF_PORTALRESTRICT) : a.pitch;
		Actor offsetPuff = a.LineAttack( a.angle
									  , beamOffset
									  , pitch
									  , 0
									  , "none"
									  , "m8f_ls_BeamInvisiblePuff"
									  , lFlags | LAF_NOINTERACT
									  );
		beamPos = offsetPuff.pos;
	}
	
	if(_beamDelayCounter > 0)
	{
		_beam.SetOrigin(beamPos, false); //to prevent glitchy movement
		return;
	}

    Actor tempPuff = a.LineAttack( a.angle
                                  , maxDistance
                                  , pitch
                                  , 0
                                  , "none"
                                  , "m8f_ls_BeamInvisiblePuff"
                                  , lFlags
                                  );

    if (tempPuff == null) { return; }

    double distance = a.Distance3D(tempPuff);

    string shade;
    if (friendly)      { shade = _settings.friendlyColor(); }
    else if (negative) { shade = _settings.targetColor();   }
    else               { shade = _settings.noTargetColor(); }

	if(_settings.beamMode() == 0)
		showBeam(beamPos, tempPuff.pos, distance, shade);
	else
		ShowParticleBeam(beamPos, tempPuff.pos, distance, shade);
  }

  private void ShowBeam(vector3 beamPos, vector3 targetPos, double distance, string shade)
  {
	let t_dummy = Actor.Spawn("m8f_ls_BeamInvisiblePuff", targetPos);
	
    color beamColor  	= shade;
    double opacity 		= _settings.beamOpacity();
    bool fullLength 	= _settings.beamLength();
    double scale 		= _settings.beamScale();
	scale = scale < 1 ? 1 : scale;
	
	_beam.A_SetRenderStyle(opacity, STYLE_AddStencil);
    _beam.SetShade(beamColor);
	_beam.A_SetScale(distance/14, scale * 0.6);
	_beam.A_SetAngle(_beam.AngleTo(t_dummy));
	_beam.A_SetPitch(GetPitchTo(_beam, t_dummy));
	
	if(fullLength)
		_beam.SetStateLabel("LongBeam");
	else
		_beam.SetStateLabel("Spawn");
	
    _beam.bInvisible = false;
    _beam.SetOrigin(beamPos, true);
	
	t_dummy.destroy();
  }

  private void ShowParticleBeam(vector3 beamPos, vector3 targetPos, double distance, string shade)
  {
    color   beamColor  = shade;
    double  size       = 0.5 * _settings.beamScale();
    int  	maxParticle = _settings.beamPMax();

    vector3 relPos 	   = targetPos - beamPos;
    int     nSteps 	   = int(distance / _settings.beamStep());

    if (nSteps == 0) { return; }

    double  xStep     = relPos.x / nSteps;
    double  yStep     = relPos.y / nSteps;
    double  zStep     = relPos.z / nSteps;
    double  alpha     = _settings.beamOpacity();
    int     drawSteps = min(nSteps - 2, maxParticle);

    Actor b_spawner = Actor.Spawn("m8f_ls_BeamInvisiblePuff", beamPos);
  
    for (int i = 2; i < drawSteps; ++i)
    {
      double xoff = xStep * i;
      double yoff = yStep * i;
      double zoff = zStep * i;

      b_spawner.A_SpawnParticle( beamColor, beamFlags, beamLifetime, size, beamAngle
                       , xoff, yoff, zoff
                       , beamVel, beamVel, beamVel, beamAcc, beamAcc, beamAcc
                       , alpha
                       );
    }
  
    b_spawner.destroy();
  }

  // static functions section //////////////////////////////////////////////////

  private play static bool IsMeleeWeapon(PlayerInfo player)
  {
    Weapon w = player.readyWeapon;
    if (w == null) { return false; }

    return w.bMeleeWeapon;
  }

  private static bool CheckTitlemap()
  {
    bool isTitlemap = (level.mapname == "TITLEMAP");
    return isTitlemap;
  }

  private static bool IsWeaponReady(PlayerInfo player)
  {
    if (!player) { return false; }

    bool isReady = (player.WeaponState & WF_WEAPONREADY)
      || (player.WeaponState & WF_WEAPONREADYALT);

    return isReady;
  }
	
  double GetPitchTo(Actor source, Actor target, double zOfs = 0, double targZOfs = 0, bool absolute = false)
  {
  	Vector3 origin = (source.pos.xy, source.pos.z - source.floorClip + zOfs);
  	Vector3 dest = (target.pos.xy, target.pos.z - target.floorClip + targZOfs);

  	Vector3 diff;
  	if (!absolute)
  		diff = level.Vec3Diff(origin, dest);
  	else
  		diff = dest - origin;

  	return -atan2(diff.z, diff.xy.Length());
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
  private Actor           _puff;
  private Actor           _beam;
  private int             _beamDelayCounter;

} // class m8f_ls_EventHandler
