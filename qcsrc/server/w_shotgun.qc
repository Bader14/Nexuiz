#ifdef REGISTER_WEAPON
REGISTER_WEAPON(SHOTGUN, w_shotgun, IT_SHELLS, 2, WEP_FLAG_NORMAL | WEP_TYPE_HITSCAN, BOT_PICKUP_RATING_LOW, "shotgun", "shotgun", "Shotgun");
#else
#ifdef SVQC
void W_Shotgun_Attack (void)
{
	float	sc;
	float	ammoamount;
	float	bullets;
	float	d;
	float	f;
	float	spread;
	float	bulletspeed;
	float	bulletconstant;
	local entity flash;

	ammoamount = autocvar_g_balance_shotgun_primary_ammo;
	bullets = autocvar_g_balance_shotgun_primary_bullets;
	d = autocvar_g_balance_shotgun_primary_damage;
	f = autocvar_g_balance_shotgun_primary_force;
	spread = autocvar_g_balance_shotgun_primary_spread;
	bulletspeed = autocvar_g_balance_shotgun_primary_speed;
	bulletconstant = autocvar_g_balance_shotgun_primary_bulletconstant;

	W_SetupShot (self, autocvar_g_antilag_bullets && bulletspeed >= autocvar_g_antilag_bullets, 5, "weapons/shotgun_fire.wav", CHAN_WEAPON, d * bullets);
	for (sc = 0;sc < bullets;sc = sc + 1)
		fireBallisticBullet(w_shotorg, w_shotdir, spread, bulletspeed, 5, d, 0, f, WEP_SHOTGUN, 0, 1, bulletconstant);
	endFireBallisticBullet();
	if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
		self.ammo_shells = self.ammo_shells - ammoamount;

	pointparticles(particleeffectnum("shotgun_muzzleflash"), w_shotorg, w_shotdir * 1000, autocvar_g_balance_shotgun_primary_ammo);

	// casing code
	if (autocvar_g_casings >= 1)
		for (sc = 0;sc < ammoamount;sc = sc + 1)
			SpawnCasing (((random () * 50 + 50) * v_right) - (v_forward * (random () * 25 + 25)) - ((random () * 5 - 30) * v_up), 2, vectoangles(v_forward),'0 250 0', 100, 1, self);

	// muzzle flash for 1st person view
	flash = spawn();
	setmodel(flash, "models/uziflash.md3"); // precision set below
	flash.think = SUB_Remove;
	flash.nextthink = time + 0.06;
	flash.effects = EF_ADDITIVE | EF_FULLBRIGHT | EF_LOWPRECISION;
	W_AttachToShotorg(flash, '5 0 0');

}

void W_Shotgun_Attack2 (void)
{
	float	sc;
	float	ammoamount;
	float	bullets;
	float	d;
	float	f;
	float	spread;
	float	bulletspeed;
	float	bulletconstant;
	local entity flash;

	ammoamount = autocvar_g_balance_shotgun_primary_ammo;
	bullets = autocvar_g_balance_shotgun_primary_bullets;
	d = autocvar_g_balance_shotgun_primary_damage;
	f = autocvar_g_balance_shotgun_primary_force;
	spread = autocvar_g_balance_shotgun_primary_spread;
	bulletspeed = autocvar_g_balance_shotgun_primary_speed;
	bulletconstant = autocvar_g_balance_shotgun_primary_bulletconstant;

	W_SetupShot (self, autocvar_g_antilag_bullets && bulletspeed >= autocvar_g_antilag_bullets, 5, "weapons/shotgun_fire.wav", CHAN_WEAPON, d * bullets);	
	for (sc = 0;sc < bullets;sc = sc + 1)
		fireBallisticBullet(w_shotorg, w_shotdir, spread, bulletspeed, 5, d, 0, f, WEP_SHOTGUN | HITTYPE_SECONDARY, 0, 1, bulletconstant);
	endFireBallisticBullet();
	if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
		self.ammo_shells = self.ammo_shells - ammoamount;

	pointparticles(particleeffectnum("shotgun_muzzleflash"), w_shotorg, w_shotdir * 1000, cvar("g_balance_shotgun_secondary_ammo"));

	// casing code
	if (cvar("g_casings") >= 1)
		for (sc = 0;sc < ammoamount;sc = sc + 1)
			SpawnCasing (((random () * 50 + 50) * v_right) - (v_forward * (random () * 25 + 25)) - ((random () * 5 - 30) * v_up), 2, vectoangles(v_forward),'0 250 0', 100, 1, self);

	flash = spawn();
	setmodel(flash, "models/uziflash.md3"); // precision set below
	flash.scale = 1.2;
	flash.think = SUB_Remove;
	flash.nextthink = time + 0.06;
	flash.effects = EF_ADDITIVE | EF_FULLBRIGHT | EF_LOWPRECISION;
	W_AttachToShotorg(flash, '5 0 0');
}

// weapon frames
void shotgun_fire2_03()
{
	W_Shotgun_Attack2();
	weapon_thinkf(WFRAME_FIRE2, cvar("g_balance_shotgun_secondary_animtime"), w_ready);
}
void shotgun_fire2_02()
{
	W_Shotgun_Attack2();
	weapon_thinkf(WFRAME_FIRE2, cvar("g_balance_shotgun_secondary_animtime"), shotgun_fire2_03);
}


void spawnfunc_weapon_shotgun(); // defined in t_items.qc




.float shotgun_primarytime;

float w_shotgun(float req)
{
	if (req == WR_AIM)
		if(vlen(self.origin-self.enemy.origin)>200)
			self.BUTTON_ATCK = bot_aim(1000000, 0, 0.001, FALSE);
		else
			self.BUTTON_ATCK2 = bot_aim(1000000, 0, 0.001, FALSE);
	else if (req == WR_THINK)
	{
		if (self.BUTTON_ATCK)
		if (weapon_prepareattack(0, cvar("g_balance_shotgun_primary_refire")))
		{
			W_Shotgun_Attack();
			weapon_thinkf(WFRAME_FIRE1, cvar("g_balance_shotgun_primary_animtime"), w_ready);
		}
		if (self.BUTTON_ATCK2 && cvar("g_balance_shotgun_secondary"))
		if (weapon_prepareattack(1, cvar("g_balance_shotgun_secondary_refire")))
		{
			W_Shotgun_Attack2();
			weapon_thinkf(WFRAME_FIRE2, cvar("g_balance_shotgun_secondary_animtime"), shotgun_fire2_02);
		}
	}
	else if (req == WR_PRECACHE)
	{
		precache_model ("models/uziflash.md3");
		precache_model ("models/weapons/g_shotgun.md3");
		precache_model ("models/weapons/v_shotgun.md3");
		precache_model ("models/weapons/h_shotgun.iqm");
		precache_sound ("misc/itempickup.wav");
		precache_sound ("weapons/shotgun_fire.wav");
	}
	else if (req == WR_SETUP)
		weapon_setup(WEP_SHOTGUN);
	else if (req == WR_CHECKAMMO1)
		return self.ammo_shells >= cvar("g_balance_shotgun_primary_ammo");
	else if (req == WR_CHECKAMMO2)
		return self.ammo_shells >= cvar("g_balance_shotgun_secondary_ammo") * 3;
	else if (req == WR_SUICIDEMESSAGE)
		w_deathtypestring = "did the impossible";
	else if (req == WR_KILLMESSAGE)
	{
		w_deathtypestring = "was gunned by"; // unchecked: SECONDARY
	}
	return TRUE;
};
#endif
#ifdef CSQC
.float prevric;
float w_shotgun(float req)
{
	if(req == WR_IMPACTEFFECT)
	{
		vector org2;
		org2 = w_org + w_backoff * 2;
		pointparticles(particleeffectnum("shotgun_impact"), org2, w_backoff * 1000, 1);
		if(!w_issilent && time - self.prevric > 0.25)
		{
			if(w_random < 0.0165)
				sound(self, CHAN_PROJECTILE, "weapons/ric1.wav", VOL_BASE, ATTN_NORM);
			else if(w_random < 0.033)
				sound(self, CHAN_PROJECTILE, "weapons/ric2.wav", VOL_BASE, ATTN_NORM);
			else if(w_random < 0.05)
				sound(self, CHAN_PROJECTILE, "weapons/ric3.wav", VOL_BASE, ATTN_NORM);
			self.prevric = time;
		}
	}
	else if(req == WR_PRECACHE)
	{
		precache_sound("weapons/ric1.wav");
		precache_sound("weapons/ric2.wav");
		precache_sound("weapons/ric3.wav");
	}
	else if (req == WR_SUICIDEMESSAGE)
		w_deathtypestring = "%s did the impossible";
	else if (req == WR_KILLMESSAGE)
	{
		if(w_deathtype & HITTYPE_SECONDARY)
			w_deathtypestring = "%s was gunned by %s";
		else
			w_deathtypestring = "%s was gunned by %s";
	}
	return TRUE;
}
#endif
#endif 