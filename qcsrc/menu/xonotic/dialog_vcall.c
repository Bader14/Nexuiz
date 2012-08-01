#ifdef INTERFACE
CLASS(XonoticVcallDialog) EXTENDS(XonoticRootDialog)
	METHOD(XonoticVcallDialog, fill, void(entity)) // to be overridden by user to fill the dialog with controls
	ATTRIB(XonoticVcallDialog, title, string, "Call a vote")
	ATTRIB(XonoticVcallDialog, color, vector, SKINCOLOR_DIALOG_TEAMSELECT)
	ATTRIB(XonoticVcallDialog, intendedWidth, float, 0.8)
	ATTRIB(XonoticVcallDialog, rows, float, 16)
	ATTRIB(XonoticVcallDialog, columns, float, 20)
	ATTRIB(XonoticVcallDialog, name, string, "VcallMenu")
    ATTRIB(XonoticVcallDialog, voteList, entity, NULL)
ENDCLASS(XonoticVcallDialog)
#endif

#ifdef IMPLEMENTATION

void VoteCall_f(entity btn, entity me)
{
    localcmd("cmd vote call ", cvar_string("_menu_vote_string"), "\n");
    btn.onClickEntity.close(btn.onClickEntity);
}

void fillXonoticVcallDialog(entity me)
{
	entity e, vlist;
	
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticTextLabel(0, "Available votes:"));
	me.TR(me);
        me.TD(me, 13, 20, vlist = makeXonoticVoteList());
	me.TR(me);
    me.TR(me);
    me.TR(me);
    me.TR(me);
    me.TR(me);
    me.TR(me);
    me.TR(me);
    me.TR(me);
    me.TR(me);
    me.TR(me);
    me.TR(me);
    me.TR(me);
    me.TR(me); // ???
        me.TD(me, 1, 20, e = makeXonoticInputBox(1, "_menu_vote_string"));
        //e.saveImmediately = 1;
        vlist.textBox = e;
    me.TR(me);
        me.TD(me, 1, 10, e = makeXonoticButton("Call the vote", '0 0 0'));
            e.onClick = VoteCall_f;
            e.onClickEntity = me;
        me.TD(me, 1, 10, e = makeXonoticCommandButton("Cancel", '0 0 0', "", 1));
    
    me.voteList = vlist;
}
#endif

/* Click. The c-word is here so you can grep for it :-) */
 