#ifdef INTERFACE
CLASS(NexuizHUDPressedKeysDialog) EXTENDS(NexuizRootDialog)
	METHOD(NexuizHUDPressedKeysDialog, fill, void(entity))
	ATTRIB(NexuizHUDPressedKeysDialog, title, string, "Pressed Keys Panel")
	ATTRIB(NexuizHUDPressedKeysDialog, color, vector, SKINCOLOR_DIALOG_TEAMSELECT)
	ATTRIB(NexuizHUDPressedKeysDialog, intendedWidth, float, 0.4)
	ATTRIB(NexuizHUDPressedKeysDialog, rows, float, 15)
	ATTRIB(NexuizHUDPressedKeysDialog, columns, float, 4)
	ATTRIB(NexuizHUDPressedKeysDialog, name, string, "HUDpressedkeys")
ENDCLASS(NexuizHUDPressedKeysDialog)
#endif

#ifdef IMPLEMENTATION
void NexuizHUDPressedKeysDialog_fill(entity me)
{
	entity e;
	string panelname = "pressedkeys";
	float i;

	me.TR(me);
		me.TD(me, 1, 2, e = makeNexuizTextSlider("hud_panel_pressedkeys"));
			e.addValue(e, "Panel disabled", "0");
			e.addValue(e, "Panel enabled when spectating", "1");
			e.addValue(e, "Panel always enabled", "2");
			e.configureNexuizTextSliderValues(e);
	me.TR(me);
		me.TD(me, 1, 1.4, e = makeNexuizTextLabel(0, "Background:"));
			me.TD(me, 1, 1.6, e = makeNexuizTextSlider(strzone(strcat("hud_panel_", panelname, "_bg"))));
				e.addValue(e, "Default", "");
				e.addValue(e, "Disable", "0");
				e.addValue(e, strzone(strcat("border_", panelname)), strzone(strcat("border_", panelname)));
				e.configureNexuizTextSliderValues(e);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeNexuizTextLabel(0, "Color:"));
		me.TD(me, 2, 2.4, e = makeNexuizColorpickerString(strzone(strcat("hud_panel_", panelname, "_bg_color")), "hud_panel_bg_color"));
			setDependentStringNotEqual(e, strzone(strcat("hud_panel_", panelname, "_bg_color")), "");
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeNexuizCheckBoxString("", "1 1 1", strzone(strcat("hud_panel_", panelname, "_bg_color")), "Use default"));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeNexuizTextLabel(0, "Border size:"));
			me.TD(me, 1, 2.6, e = makeNexuizTextSlider(strzone(strcat("hud_panel_", panelname, "_bg_border"))));
				e.addValue(e, "Default", "");
				e.addValue(e, "Disable", "0");
				for(i = 1; i <= 10; ++i)
					e.addValue(e, strzone(ftos_decimals(i * 2, 0)), strzone(ftos(i * 2)));
				e.configureNexuizTextSliderValues(e);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeNexuizTextLabel(0, "Alpha:"));
			me.TD(me, 1, 2.6, e = makeNexuizTextSlider(strzone(strcat("hud_panel_", panelname, "_bg_alpha"))));
				e.addValue(e, "Default", "");
				for(i = 1; i <= 10; ++i)
					e.addValue(e, strzone(ftos_decimals(i/10, 1)), strzone(ftos(i/10)));
				e.configureNexuizTextSliderValues(e);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeNexuizTextLabel(0, "Team Color:"));
			me.TD(me, 1, 2.6, e = makeNexuizTextSlider(strzone(strcat("hud_panel_", panelname, "_bg_color_team"))));
				e.addValue(e, "Default", "");
				e.addValue(e, "Disable", "0");
				for(i = 1; i <= 10; ++i)
					e.addValue(e, strzone(ftos_decimals(i/10, 1)), strzone(ftos(i/10)));
				e.configureNexuizTextSliderValues(e);
	me.TR(me);
		me.TDempty(me, 0.4);
		me.TD(me, 1, 3, e = makeNexuizCheckBox(0, "hud_configure_teamcolorforced", "Test the team color in HUD configure mode"));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeNexuizTextLabel(0, "Padding:"));
			me.TD(me, 1, 2.6, e = makeNexuizTextSlider(strzone(strcat("hud_panel_", panelname, "_bg_padding"))));
				e.addValue(e, "Default", "");
				for(i = 0; i <= 10; ++i)
					e.addValue(e, strzone(ftos_decimals(i - 5, 0)), strzone(ftos(i - 5)));
				e.configureNexuizTextSliderValues(e);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeNexuizTextLabel(0, "Forced aspect:"));
			me.TD(me, 1, 2.6, e = makeNexuizSlider(0.2, 4, 0.1, "hud_panel_pressedkeys_aspect"));
}
#endif
