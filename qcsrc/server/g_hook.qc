/*============================================

      Wazat's Nexuiz Grappling Hook

        Contact: Wazat1@gmail.com


Installation instructions:
--------------------------

1. Place hook.c in your gamec source directory with the other source files.

2. Add this line to the bottom of progs.src:

gamec/hook.c

3. Open defs.h and add these lines to the very bottom:

// Wazat's grappling hook
.entity		hook;
void GrapplingHookFrame();
void RemoveGrapplingHook(entity pl);
void SetGrappleHookBindings();
// hook impulses
float GRAPHOOK_FIRE		= 20;
float GRAPHOOK_RELEASE		= 21;
// (note: you can change the hook impulse #'s to whatever you please)

4. Open client.c and add this to the top of PutClientInServer():

	RemoveGrapplingHook(self); // Wazat's Grappling Hook

5. Find ClientConnect() (in client.c) and add these lines to the bottom:

	// Wazat's grappling hook
	SetGrappleHookBindings();

6. Still in client.c, find PlayerPreThink and add this line just above the call to W_WeaponFrame:

 	GrapplingHookFrame();

7. Build and test the mod.  You'll want to bind a key to "+hook" like this:
bind ctrl "+hook"

And you should be done!


============================================*/

.string aiment_classname;
.float aiment_deadflag;
void SetMovetypeFollow(entity ent, entity e)
{
	// FIXME this may not be warpzone aware
	ent.movetype = MOVETYPE_FOLLOW; // make the hole follow
	ent.solid = SOLID_NOT; // MOVETYPE_FOLLOW is always non-solid - this means this cannot be teleported by warpzones any more! Instead, we must notice when our owner gets teleported.
	ent.aiment = e; // make the hole follow bmodel
	ent.punchangle = e.angles; // the original angles of bmodel
	ent.view_ofs = ent.origin - e.origin; // relative origin
	ent.v_angle = ent.angles - e.angles; // relative angles
	ent.aiment_classname = strzone(e.classname);
	ent.aiment_deadflag = e.deadflag;
}
void UnsetMovetypeFollow(entity ent)
{
	ent.movetype = MOVETYPE_FLY;
	PROJECTILE_MAKETRIGGER(ent);
	ent.aiment = world;
}
float LostMovetypeFollow(entity ent)
{
/*
	if(ent.movetype != MOVETYPE_FOLLOW)
		if(ent.aiment)
			error("???");
*/
	if(ent.aiment)
	{
		if(ent.aiment.classname != ent.aiment_classname)
			return 1;
		if(ent.aiment.deadflag != ent.aiment_deadflag)
			return 1;
	}
	return 0;
}

.float hook_length;
.float hook_switchweapon;

void RemoveGrapplingHook(entity pl)
{
	if(pl.hook == world)
		return;
	remove(pl.hook);
	pl.hook = world;
	if(pl.movetype == MOVETYPE_FLY)
		pl.movetype = MOVETYPE_WALK;

	//pl.disableclientprediction = FALSE;
}

void GrapplingHookThink();
void GrapplingHook_Stop()
{
	pointparticles(particleeffectnum("grapple_impact"), self.origin, '0 0 0', 1);
	sound (self, CHAN_PROJECTILE, "weapons/hook_impact.wav", VOL_BASE, ATTN_NORM);

	self.state = 1;
	self.think = GrapplingHookThink;
	self.nextthink = time;
	self.touch = SUB_Null;
	self.velocity = '0 0 0';
	self.movetype = MOVETYPE_NONE;
	self.hook_length = -1;
}

.vector hook_start, hook_end;
float GrapplingHookSend(entity to, float sf)
{
	WriteByte(MSG_ENTITY, ENT_CLIENT_HOOK);
	sf = sf & 0x7F;
	if(sound_allowed(MSG_BROADCAST, self.owner))
		sf |= 0x80;
	WriteByte(MSG_ENTITY, sf);
	if(sf & 1)
	{
		WriteByte(MSG_ENTITY, num_for_edict(self.owner));
	}
	if(sf & 2)
	{
		WriteCoord(MSG_ENTITY, self.hook_start_x);
		WriteCoord(MSG_ENTITY, self.hook_start_y);
		WriteCoord(MSG_ENTITY, self.hook_start_z);
	}
	if(sf & 4)
	{
		WriteCoord(MSG_ENTITY, self.hook_end_x);
		WriteCoord(MSG_ENTITY, self.hook_end_y);
		WriteCoord(MSG_ENTITY, self.hook_end_z);
	}
	return TRUE;
}

void GrapplingHookThink()
{
	float spd, dist, minlength, pullspeed, ropestretch, ropeairfriction, rubberforce, newlength, rubberforce_overstretch, s;
	vector dir, org, end, v0, dv, v, myorg, vs;
	if(self.owner.health <= 0 || self.owner.hook != self)	// how did that happen?
	{														// well, better fix it anyway
		remove(self);
		return;
	}
	if(LostMovetypeFollow(self))
	{
		RemoveGrapplingHook(self.owner);
		return;
	}
	if(self.aiment)
		WarpZone_RefSys_AddIncrementally(self, self.aiment);

	self.nextthink = time;

	s = self.owner.cvar_cl_gunalign;
	if(s != 1 && s != 2 && s != 4)
		s = 3; // default value
	--s;
	vs = hook_shotorigin[s];

	makevectors(self.owner.v_angle);
	org = self.owner.origin + self.owner.view_ofs + v_forward * vs_x + v_right * -vs_y + v_up * vs_z;
	myorg = WarpZone_RefSys_TransformOrigin(self.owner, self, org);

	if(self.hook_length < 0)
		self.hook_length = vlen(myorg - self.origin);

	if(self.state == 1)
	{
		pullspeed = autocvar_g_balance_grapplehook_speed_pull;//2000;
		// speed the rope is pulled with

		rubberforce = autocvar_g_balance_grapplehook_force_rubber;//2000;
		// force the rope will use if it is stretched

		rubberforce_overstretch = autocvar_g_balance_grapplehook_force_rubber_overstretch;//1000;
		// force the rope will use if it is stretched

		minlength = autocvar_g_balance_grapplehook_length_min;//100;
		// minimal rope length
		// if the rope goes below this length, it isn't pulled any more

		ropestretch = autocvar_g_balance_grapplehook_stretch;//400;
		// if the rope is stretched by more than this amount, more rope is
		// given to you again

		ropeairfriction = autocvar_g_balance_grapplehook_airfriction;//0.2
		// while hanging on the rope, this friction component will help you a
		// bit to control the rope

		dir = self.origin - myorg;
		dist = vlen(dir);
		dir = normalize(dir);

		if(autocvar_g_grappling_hook_tarzan)
		{
			v = v0 = WarpZone_RefSys_TransformVelocity(self.owner, self, self.owner.velocity);

			// first pull the rope...
			if(self.owner.hook_state & HOOK_PULLING)
			{
				newlength = self.hook_length;
				newlength = max(newlength - pullspeed * frametime, minlength);

				if(newlength < dist - ropestretch) // overstretched?
				{
					newlength = dist - ropestretch;
					if(v * dir < 0) // only if not already moving in hook direction
						v = v + frametime * dir * rubberforce_overstretch;
				}

				self.hook_length = newlength;
			}

			if(self.owner.hook_state & HOOK_RELEASING)
			{
				newlength = dist;
				self.hook_length = newlength;
			}
			else
			{
				// then pull the player
				spd = bound(0, (dist - self.hook_length) / ropestretch, 1);
				v = v * (1 - frametime * ropeairfriction);
				v = v + frametime * dir * spd * rubberforce;

				dv = ((v - v0) * dir) * dir;
				if(autocvar_g_grappling_hook_tarzan >= 2)
				{
					if(self.aiment.movetype == MOVETYPE_WALK)
					{
						v = v - dv * 0.5;
						self.aiment.velocity = self.aiment.velocity - dv * 0.5;
						self.aiment.flags &~= FL_ONGROUND;
						self.aiment.pusher = self.owner;
						self.aiment.pushltime = time + autocvar_g_maxpushtime;
					}
				}

				self.owner.flags &~= FL_ONGROUND;
			}

			self.owner.velocity = WarpZone_RefSys_TransformVelocity(self, self.owner, v);
		}
		else
		{
			end = self.origin - dir*50;
			dist = vlen(end - myorg);
			if(dist < 200)
				spd = dist * (pullspeed / 200);
			else
				spd = pullspeed;
			if(spd < 50)
				spd = 0;
			self.owner.velocity = dir*spd;
			self.owner.movetype = MOVETYPE_FLY;

			self.owner.flags &~= FL_ONGROUND;
		}
	}

	makevectors(self.angles_x * '-1 0 0' + self.angles_y * '0 1 0');
	myorg = WarpZone_RefSys_TransformOrigin(self, self.owner, self.origin); // + v_forward * (-9);

	if(myorg != self.hook_start)
	{
		self.SendFlags |= 2;
		self.hook_start = myorg;
	}
	if(org != self.hook_end)
	{
		self.SendFlags |= 4;
		self.hook_end = org;
	}
}

void GrapplingHookTouch (void)
{
	if(SUB_OwnerCheck())
		return;
	if(SUB_NoImpactCheck())
	{
		RemoveGrapplingHook(self.owner);
		return;
	}
	PROJECTILE_TOUCH;

	GrapplingHook_Stop();

	if(other)
		if(other.movetype != MOVETYPE_NONE)
		{
			SetMovetypeFollow(self, other);
			WarpZone_RefSys_BeginAddingIncrementally(self, self.aiment);
		}

	//self.owner.disableclientprediction = TRUE;
}

void GrapplingHook_Damage (entity inflictor, entity attacker, float damage, float deathtype, vector hitloc, vector force)
{
	if(self.health > 0)
	{
		self.health = self.health - damage;
		if (self.health <= 0)
		{
			if(attacker != self.owner)
			{
				self.owner.pusher = attacker;
				self.owner.pushltime = time + autocvar_g_maxpushtime;
			}
			RemoveGrapplingHook(self.owner);
		}
	}
}

void FireGrapplingHook (void)
{
	local entity missile;
	local vector org;
	float s;
	vector vs;

	if((arena_roundbased && time < warmup) || (time < game_starttime))
		return;

	makevectors(self.v_angle);

	s = self.cvar_cl_gunalign;
	if(s != 1 && s != 2 && s != 4)
		s = 3; // default value
	--s;
	vs = hook_shotorigin[s];

	// UGLY WORKAROUND: play this on CHAN_WEAPON2 so it can't cut off fire sounds
	sound (self, CHAN_WEAPON2, "weapons/hook_fire.wav", VOL_BASE, ATTN_NORM);
	org = self.origin + self.view_ofs + v_forward * vs_x + v_right * -vs_y + v_up * vs_z;

	tracebox(self.origin + self.view_ofs, '-3 -3 -3', '3 3 3', org, MOVE_NORMAL, self);
	org = trace_endpos;

	pointparticles(particleeffectnum("grapple_muzzleflash"), org, '0 0 0', 1);

	missile = WarpZone_RefSys_SpawnSameRefSys(self);
	missile.owner = self;
	self.hook = missile;
	missile.classname = "grapplinghook";

	missile.movetype = MOVETYPE_FLY;
	PROJECTILE_MAKETRIGGER(missile);

	//setmodel (missile, "models/hook.md3"); // precision set below
	setsize (missile, '-3 -3 -3', '3 3 3');
	setorigin (missile, org);

	missile.state = 0; // not latched onto anything

	W_SetupProjectileVelocityEx(missile, v_forward, v_up, autocvar_g_balance_grapplehook_speed_fly, 0, 0, 0, FALSE);

	missile.angles = vectoangles (missile.velocity);
	//missile.glow_color = 250; // 244, 250
	//missile.glow_size = 120;
	missile.touch = GrapplingHookTouch;
	missile.think = GrapplingHookThink;
	missile.nextthink = time + 0.1;

	missile.effects = /*EF_FULLBRIGHT | EF_ADDITIVE |*/ EF_LOWPRECISION;

	missile.health = autocvar_g_balance_grapplehook_health;//120
	missile.event_damage = GrapplingHook_Damage;
	missile.takedamage = DAMAGE_AIM;
	missile.damageforcescale = 0;

	missile.hook_start = missile.hook_end = missile.origin;

	Net_LinkEntity(missile, FALSE, 0, GrapplingHookSend);
}

//  void GrapplingHookFrame()
//  {
//         // this function has been modified for Nexuiz
// -       if (self.BUTTON_HOOK && g_grappling_hook)
//         {
// -               if (!self.hook && self.hook_time <= time && !self.button6_pressed_before)
// -                       if (timeoutStatus != 2) //only allow the player to fire the grappling hook if the game is not paused (timeout)
// -                               FireGrapplingHook();
//         }
// -       else
//         {
//                 if (self.hook)
//                         RemoveGrapplingHook(self);
//         }
// -       self.button6_pressed_before = self.BUTTON_HOOK;
//         /*
//         // if I have no hook or it's not pulling yet, make sure I'm not flying!
//         if((self.hook == world || !self.hook.state) && self.movetype == MOVETYPE_FLY)

void GrapplingHookFrame()
{
	if(g_grappling_hook && timeoutStatus != 2 && self.weapon != WEP_HOOK)
	{
		// offhand hook controls
		if(self.BUTTON_HOOK)
		{
			if not(self.hook || (self.hook_state & HOOK_WAITING_FOR_RELEASE))
			{
				self.hook_state |= HOOK_FIRING;
				self.hook_state |= HOOK_WAITING_FOR_RELEASE;
			}
		}
		else
		{
			self.hook_state |= HOOK_REMOVING;
			self.hook_state &~= HOOK_WAITING_FOR_RELEASE;
		}

		self.hook_state &~= HOOK_RELEASING;
		if(self.BUTTON_CROUCH)
		{
			self.hook_state &~= HOOK_PULLING;
			//self.hook_state |= HOOK_RELEASING;
		}
		else
		{
			self.hook_state |= HOOK_PULLING;
			//self.hook_state &~= HOOK_RELEASING;
		}
	}
	else if(!(self.items & IT_JETPACK) && !g_grappling_hook && self.switchweapon != WEP_HOOK)
	{
		if(self.BUTTON_HOOK && !self.hook_switchweapon)
			W_SwitchWeapon(WEP_HOOK);
	}
	self.hook_switchweapon = self.BUTTON_HOOK;

	if(!g_grappling_hook && self.weapon != WEP_HOOK)
	{
		self.hook_state &~= HOOK_FIRING;
		self.hook_state |= HOOK_REMOVING;
	}

	if (self.hook_state & HOOK_FIRING)
	{
		if (self.hook)
			RemoveGrapplingHook(self);
		FireGrapplingHook();
		self.hook_state &~= HOOK_FIRING;
	}
	else if(self.hook_state & HOOK_REMOVING)
	{
		if (self.hook)
			RemoveGrapplingHook(self);
		self.hook_state &~= HOOK_REMOVING;
	}

	/*
	// if I have no hook or it's not pulling yet, make sure I'm not flying!
	if((self.hook == world || !self.hook.state) && self.movetype == MOVETYPE_FLY)
	{
		self.movetype = MOVETYPE_WALK;
	}
	if(self.impulse == GRAPHOOK_FIRE && self.hook_time <= time && g_grappling_hook)
	{
		// fire hook
		FireGrapplingHook();
		return;
	}
	else if(self.hookimpulse == GRAPHOOK_RELEASE)
	{
		// remove hook, reset movement type
		RemoveGrapplingHook(self);
		return;
	}
	*/
	/*else // make sure the player's movetype is correct
	{
		//if(self.hook == world && self.movetype == MOVETYPE_FLY)
		if((self.hook == world || !self.hook.state) && self.movetype == MOVETYPE_FLY)
		{
			self.movetype = MOVETYPE_WALK;
		}
	}*/
	// note: The hook entity does the actual pulling
}

void GrappleHookInit()
{
	if(g_grappling_hook)
	{
		hook_shotorigin[0] = '8 8 -12';
		hook_shotorigin[1] = '8 8 -12';
		hook_shotorigin[2] = '8 8 -12';
		hook_shotorigin[3] = '8 8 -12';
	}
	else
	{
		weapon_action(WEP_HOOK, WR_PRECACHE);
		hook_shotorigin[0] = shotorg_adjust_values(CL_Weapon_GetShotOrg(WEP_HOOK), FALSE, FALSE, 1);
		hook_shotorigin[1] = shotorg_adjust_values(CL_Weapon_GetShotOrg(WEP_HOOK), FALSE, FALSE, 2);
		hook_shotorigin[2] = shotorg_adjust_values(CL_Weapon_GetShotOrg(WEP_HOOK), FALSE, FALSE, 3);
		hook_shotorigin[3] = shotorg_adjust_values(CL_Weapon_GetShotOrg(WEP_HOOK), FALSE, FALSE, 4);
	}
}

void SetGrappleHookBindings()
{
	// this function has been modified for Nexuiz
	// don't remove these lines! old server or demos coud overwrite the new aliases
	stuffcmd(self, "alias +hook +button6\n");
	stuffcmd(self, "alias -hook -button6\n");
}
