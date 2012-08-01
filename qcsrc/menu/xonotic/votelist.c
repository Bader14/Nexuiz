#ifdef INTERFACE
CLASS(XonoticVoteList) EXTENDS(XonoticListBox)
	METHOD(XonoticVoteList, configureXonoticVoteList, void(entity))
	METHOD(XonoticVoteList, drawListBoxItem, void(entity, float, vector, float))
	METHOD(XonoticVoteList, loadCvars, void(entity))
	METHOD(XonoticVoteList, setSelected, void(entity, float))
	METHOD(XonoticVoteList, resizeNotify, void(entity, vector, vector, vector, vector))
	METHOD(XonoticVoteList, RMUpdate, void(entity))
	ATTRIB(XonoticVoteList, RMUpdatable, float, TRUE)
	ATTRIB(XonoticVoteList, textBox, entity, NULL)
ENDCLASS(XonoticVoteList)
entity makeXonoticVoteList();
#endif

#ifdef IMPLEMENTATION

#define MAX_VOTES 100
string votelist[MAX_VOTES];
float numvotes;

void RMUpdateXonoticVoteList(entity me)
{
	me.loadCvars(me);
}

entity makeXonoticVoteList(void)
{
	entity me;
	me = spawnXonoticVoteList();
	me.configureXonoticVoteList(me);
	return me;
}

void configureXonoticVoteListXonoticVoteList(entity me)
{
	me.loadCvars(me);
	me.configureXonoticListBox(me);
}

void setSelectedXonoticVoteList(entity me, float i)
{
	ListBox_setSelected(me, i);
    string s = strcat(votelist[i], " ");
    me.textBox.setText(me.textBox, s);
    me.textBox.cursorPos = strlen(s);
}

void loadCvarsXonoticVoteList(entity me)
{
    local float i, limit;
    numvotes = tokenizebyseparator(cvar_string("_vote_commands"), " ");
    limit = min(MAX_VOTES, numvotes);
    
    for(i = 0; i < limit; i++)
    {
        if(votelist[i])
            strunzone(votelist[i]);
        
        votelist[i] = strzone(argv(i));
    }
    
    me.nItems = limit;
}

void resizeNotifyXonoticVoteList(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize)
{
	XonoticListBox_resizeNotify(me, relOrigin, relSize, absOrigin, absSize);

	me.realFontSize_y = me.fontSize / (absSize_y * me.itemHeight);
	me.realFontSize_x = me.fontSize / (absSize_x * (1 - me.controlWidth));
	me.realUpperMargin = 0.5 * (1 - me.realFontSize_y);
}

void drawListBoxItemXonoticVoteList(entity me, float i, vector absSize, float isSelected)
{
	string s;
	if(isSelected)
		draw_Fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_SELECTED, SKINALPHA_LISTBOX_SELECTED);
	s = votelist[i];
	draw_Text(me.realUpperMargin * eY + (me.columnNameOrigin) * eX, s, me.realFontSize, '1 1 1', SKINALPHA_TEXT, 0);
}

#endif
 