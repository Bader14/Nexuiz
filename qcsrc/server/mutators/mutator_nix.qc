float g_nix_with_laser;

float nix_weapon;
float nix_weapon_ammo;
float nix_nextchange;
float nix_nextweapon;
float nix_nextweapon_ammo;
.float nix_lastchange_id;
.float nix_lastinfotime;
.float nix_nextincr;

.float nix_save_cells;
.float nix_save_shells;
.float nix_save_nails;
.float nix_save_rockets;
.float nix_save_fuel;
.float nix_save_weapons;

float NIX_CanChooseWeapon(float wpn)
{
	entity e;
	e = get_weaponinfo(wpn);
	if(!e.weapons) // skip dummies
		return FALSE;
	if(g_weaponarena)
	{
		if not(g_weaponarena & e.weapons)
			return FALSE;
	}
	else
	{
		if(wpn == WEP_LASER && g_nix_with_laser)
			return FALSE;
		if not(e.spawnflags & WEP_FLAG_NORMAL)
			return FALSE;
	}
	return TRUE;
}
void NIX_ChooseNextWeapon()
{
	float j;
	RandomSelection_Init();
	for(j = WEP_FIRST; j <= WEP_LAST; ++j)
		if(NIX_CanChooseWeapon(j))
			RandomSelection_Add(world, j, string_null, 1, (j != nix_weapon));
	nix_nextweapon = RandomSelection_chosen_float;
	nix_nextweapon_ammo = W_AmmoItemCode(nix_nextweapon);
}

void NIX_GiveCurrentWeapon()
{
	float dt;

	if(!nix_nextweapon)
		NIX_ChooseNextWeapon();

	dt = ceil(nix_nextchange - time);

	if(dt <= 0)
	{
		nix_weapon = nix_nextweapon;
		nix_weapon_ammo = nix_nextweapon_ammo;
		nix_nextweapon = 0;
		nix_nextchange = time + autocvar_g_balance_nix_roundtime;
		//weapon_action(nix_weapon, WR_PRECACHE); // forget it, too slow
	}
	
	if(nix_nextchange != self.nix_lastchange_id) // this shall only be called once per round!
	{
		self.nix_lastchange_id = nix_nextchange;
		if (self.items & IT_UNLIMITED_WEAPON_AMMO)
		{
			self.ammo_shells = (nix_weapon_ammo & IT_SHELLS) ?
				autocvar_g_pickup_shells_max : 0;
			self.ammo_nails = (nix_weapon_ammo & IT_NAILS) ?
				autocvar_g_pickup_nails_max : 0;
			self.ammo_rockets = (nix_weapon_ammo & IT_ROCKETS) ?
				autocvar_g_pickup_rockets_max : 0;
			self.ammo_cells = (nix_weapon_ammo & IT_CELLS) ?
				autocvar_g_pickup_cells_max : 0;
			self.ammo_fuel = (nix_weapon_ammo & IT_FUEL) ?
				autocvar_g_pickup_fuel_max : 0;
		}
		else
		{
			self.ammo_shells = (nix_weapon_ammo & IT_SHELLS) ?
				autocvar_g_balance_nix_ammo_shells : 0;
			self.ammo_nails = (nix_weapon_ammo & IT_NAILS) ?
				autocvar_g_balance_nix_ammo_nails : 0;
			self.ammo_rockets = (nix_weapon_ammo & IT_ROCKETS) ?
				autocvar_g_balance_nix_ammo_rockets : 0;
			self.ammo_cells = (nix_weapon_ammo & IT_CELLS) ?
				autocvar_g_balance_nix_ammo_cells : 0;
			self.ammo_fuel = (nix_weapon_ammo & IT_FUEL) ?
				autocvar_g_balance_nix_ammo_fuel : 0;
		}
		self.nix_nextincr = time + autocvar_g_balance_nix_incrtime;
		if(dt >= 1 && dt <= 5)
			self.nix_lastinfotime = -42;
		else
			centerprint(self, strcat("\n\n^2Active weapon: ^3", W_Name(nix_weapon)));
	}
	if(self.nix_lastinfotime != dt)
	{
		self.nix_lastinfotime = dt; // initial value 0 should count as "not seen"
		if(dt >= 1 && dt <= 5)
			centerprint(self, strcat("^3", ftos(dt), "^2 seconds until weapon change...\n\nNext weapon: ^3", W_Name(nix_nextweapon), "\n"));
	}

	if(!(self.items & IT_UNLIMITED_WEAPON_AMMO) && time > self.nix_nextincr)
	{
		if (nix_weapon_ammo & IT_SHELLS)
			self.ammo_shells = self.ammo_shells + autocvar_g_balance_nix_ammoincr_shells;
		else if (nix_weapon_ammo & IT_NAILS)
			self.ammo_nails = self.ammo_nails + autocvar_g_balance_nix_ammoincr_nails;
		else if (nix_weapon_ammo & IT_ROCKETS)
			self.ammo_rockets = self.ammo_rockets + autocvar_g_balance_nix_ammoincr_rockets;
		else if (nix_weapon_ammo & IT_CELLS)
			self.ammo_cells = self.ammo_cells + autocvar_g_balance_nix_ammoincr_cells;
		if (nix_weapon_ammo & IT_FUEL) // hook uses cells and fuel
			self.ammo_fuel = self.ammo_fuel + autocvar_g_balance_nix_ammoincr_fuel;
		self.nix_nextincr = time + autocvar_g_balance_nix_incrtime;
	}

	self.weapons = 0;
	if(g_nix_with_laser)
		self.weapons = self.weapons | WEPBIT_LASER;
	self.weapons = self.weapons | W_WeaponBit(nix_weapon);

	if(self.switchweapon != nix_weapon)
		if(!client_hasweapon(self, self.switchweapon, TRUE, FALSE))
			if(client_hasweapon(self, nix_weapon, TRUE, FALSE))
				W_SwitchWeapon(nix_weapon);
}

void NIX_precache()
{
	float i;
	for (i = WEP_FIRST; i <= WEP_LAST; ++i)
		if (NIX_CanChooseWeapon(i))
			weapon_action(i, WR_PRECACHE);
}

MUTATOR_HOOKFUNCTION(nix_ForbidThrowCurrentWeapon)
{
	return 1; // no throwing in NIX
}

MUTATOR_HOOKFUNCTION(nix_SetStartItems)
{
	NIX_precache();
	// we do NOT change the start weapons any more, so we can later turn off the mutator!
	//   start_weapons = 0; // will be done later, when player spawns
	//   warmup_start_weapons = 0; // will be done later, when player spawns
	return 0;
}

MUTATOR_HOOKFUNCTION(nix_BuildMutatorsString)
{
	ret_string = strcat(ret_string, ":NIX");
	return 0;
}

MUTATOR_HOOKFUNCTION(nix_BuildMutatorsPrettyString)
{
	ret_string = strcat(ret_string, ", NIX");
	return 0;
}

MUTATOR_HOOKFUNCTION(nix_FilterItem)
{
	switch (self.items)
	{
		case IT_HEALTH:
		case IT_5HP:
		case IT_25HP:
		case IT_ARMOR:
		case IT_ARMOR_SHARD:
			if (autocvar_g_nix_with_healtharmor)
				return 0;
			break;
		case IT_STRENGTH:
		case IT_INVINCIBLE:
			if (autocvar_g_nix_with_powerups)
				return 0;
			break;
	}

	return 1; // delete all other items
}

MUTATOR_HOOKFUNCTION(nix_OnEntityPreSpawn)
{
	if(self.classname == "target_items") // items triggers cannot work in nixnex (as they change weapons/ammo)
		return 1;
	return 0;
}

MUTATOR_HOOKFUNCTION(nix_PlayerPreThink)
{
	if(!intermission_running)
	if(self.deadflag == DEAD_NO)
	if(self.classname == "player")
		NIX_GiveCurrentWeapon();
	return 0;
}

MUTATOR_HOOKFUNCTION(nix_PlayerSpawn)
{
	self.nix_lastchange_id = -1;
	NIX_GiveCurrentWeapon(); // overrides the weapons you got when spawning
	return 0;
}

MUTATOR_DEFINITION(mutator_nix)
{
	entity e;

	MUTATOR_HOOK(ForbidThrowCurrentWeapon, nix_ForbidThrowCurrentWeapon, CBC_ORDER_ANY);
	MUTATOR_HOOK(SetStartItems, nix_SetStartItems, CBC_ORDER_EXCLUSIVE);
	MUTATOR_HOOK(BuildMutatorsString, nix_BuildMutatorsString, CBC_ORDER_ANY);
	MUTATOR_HOOK(BuildMutatorsPrettyString, nix_BuildMutatorsPrettyString, CBC_ORDER_ANY);
	MUTATOR_HOOK(FilterItem, nix_FilterItem, CBC_ORDER_ANY);
	MUTATOR_HOOK(OnEntityPreSpawn, nix_OnEntityPreSpawn, CBC_ORDER_ANY);
	MUTATOR_HOOK(PlayerPreThink, nix_PlayerPreThink, CBC_ORDER_ANY);
	MUTATOR_HOOK(PlayerSpawn, nix_PlayerSpawn, CBC_ORDER_ANY);

	MUTATOR_ONADD
	{
		g_nix_with_laser = autocvar_g_nix_with_laser;

		nix_nextchange = time;
		nix_nextweapon = 0;

		NIX_precache();

		FOR_EACH_PLAYER(e)
		{
			if(e.deadflag == DEAD_NO)
			{
				e.nix_save_cells = e.ammo_cells;
				e.nix_save_shells = e.ammo_shells;
				e.nix_save_nails = e.ammo_nails;
				e.nix_save_rockets = e.ammo_rockets;
				e.nix_save_fuel = e.ammo_fuel;
				e.nix_save_weapons = e.weapons;
			}
			else
			{
				e.nix_save_cells = 0;
				e.nix_save_shells = 0;
				e.nix_save_nails = 0;
				e.nix_save_rockets = 0;
				e.nix_save_fuel = 0;
				e.nix_save_weapons = 0;
			}
		}
	}

	MUTATOR_ONREMOVE
	{
		// as the PlayerSpawn hook will no longer run, NIX is turned off by this!

		FOR_EACH_PLAYER(e) if(e.deadflag == DEAD_NO)
		{
			e.ammo_cells = max(start_ammo_cells, e.nix_save_cells);
			e.ammo_shells = max(start_ammo_shells, e.nix_save_shells);
			e.ammo_nails = max(start_ammo_nails, e.nix_save_nails);
			e.ammo_rockets = max(start_ammo_rockets, e.nix_save_rockets);
			e.ammo_fuel = max(start_ammo_fuel, e.nix_save_fuel);
			e.weapons = (start_weapons | e.nix_save_weapons);
			if(!client_hasweapon(e, e.weapon, TRUE, FALSE))
				e.switchweapon = w_getbestweapon(self);
		}
	}

	return 0;
}
