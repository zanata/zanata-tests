// create the UI mapping object. THIS IS THE MOST IMPORTANT PART - DON'T FORGET
// TO DO THIS! In order for it to come into play, a user extension must
// construct the map in this way.
var myMap = new UIMap();
var manager = new RollupManager();

// define UI elements common for all pages. This regular expression does the
// trick. '^' is automatically prepended, and '$' is automatically postpended.
// Please note that because the regular expression is being represented as a
// string, all backslashes must be escaped with an additional backslash. Also
// note that the URL being matched will always have any trailing forward slash
// stripped.
/*************
 * Definition
 */

const emptyEntryDisplayString="Click here to start translating";
const LANGS=['en-US' , 'de', 'ja', 'zh-Hans', 'zh-Hant'];

/*************
 * All pages
 */
myMap.addPageset({
    name: 'allPages'
    , description: 'all pages'
    , pathRegexp: '.*'
});

myMap.addElement('allPages', {
    name: 'langMenuitem'
    , description: 'Menuitem in languages'
    , args: [
	{
	    name: 'lang'
	    , description: 'language'
	    , defaultValues: [ 'de', 'ja', 'zh-Hans']
	}
    ]
    , getLocator: function(args){
	var lang=args['lang'];
	return 'css=li#Language_'+lang;
    }
});

myMap.addElement('allPages', {
    name: 'tableRow'
    , description: 'Table that contains specified language'
    , args: [
	{
	    name: 'column'
	    , description: 'Column for reference'
	    , defaultValues: range(1,3)
        }
	,{
	    name: 'value'
	    , description: 'Value to match'
	    , defaultValues: []
	}
    ]
    , getLocator: function(args){
	var column=args['column'];
	var value=args['value'];
	return '//tr[td[' + column + '][contains(descendant::text(),"' + value+ '")]]';
    }
    , testcase1: {
	args: { column:1, value:"JBoss As"}
	,xhtml:
	    '<tr class="rich-table-row rich-table-firstrow ">'
	    +'<td><a>Spacewalk</a></td>'
	    +'<td>Spacewalk</td>'
	    +'<td>Nov 8, 2011</td></tr>'
	    +'<tr expected-result="1" class="rich-table-row rich-table-firstrow ">'
	    +'<td><a>JBoss As</a></td>'
	    +'<td>JBoss As</td>'
	    +'<td>Nov 8, 2011</td></tr>'
    }
});



/*************
* Language Page
*/
myMap.addPageset({
    name: 'langPages'
    , description: 'Language page'
    , pathRegexp: '/language*'
});

myMap.addElement('langPages', {
    name: 'actionMenuitem'
    , description: 'Item in action menu'
    , args: [
	{
	    name: 'action'
	    , description: 'action name'
	    , defaultValues: [
		"Join Language Team"
		, "Leave Language Team"
		, "Request To Join"
		, "Contact Team Coordinators"
	        , "Add Team Member"
	    ]
	}
    ]
    , getLocator: function(args){
	var action=args['action'];
	return 'css=form#Language_team_member_toggle_form a:contains("'+action+'")'
    }
    , testcase1: {
	args: { action:"Join Language Team"}
	, xhtml:
	    '<form id="Language_team_member_toggle_form">'
	    + '<a expected-result="1" id="Language_team_member_toggle_form:Join"> Join Language Team</a>'
            + '<a id="Language_team_member_toggle_form:j_id92">Request To Join Team</a>'
	    + '<a id="Language_team_member_toggle_form:j_id94">Contact Team Coordinators</a>'
	    + '<a class="action_link">Add Team Member</a>'
	    + '</form>'
    }
});

/*************
 * langListPages
 */
myMap.addPageset({
    name: 'langListPages'
    , description: 'Language pages'
    , pathRegexp: '/lang.*'
});

/*************
 * projListPages
 */

myMap.addPageset({
    name: 'projListPages'
    , description: 'Project list pages'
    , pathRegexp: '/project/list.*'
});

/*************
 * projViewPages
 */
myMap.addPageset({
    name: 'projViewPages'
    , description: 'Project list pages'
    , pathRegexp: '/project/view/.*'
});

myMap.addElement('projViewPages', {
    name: 'versLangRow'
    , description: 'Table row for given version and lang'
    , args: [
	{
	    name: 'ver'
	    , description: 'Project version'
	    , defaultValues: [ "f11", "f13", "trunk", "master"]
	}
	,{
	    name: 'lang'
	    , description: 'Language to translatte'
	    , defaultValues: [ "ja" ]
	}
    ]
    , getLocator: function(args){
	var ver=args['ver'];
	var lang=args['lang'];
	return '//div[@id="iteration_list_view_item_'+ver+'"]//tr[td[1][contains(descendant::text(),"['+ lang +']")]]';
    }
    , testcase1: {
	args: { ver:"f13", lang:"ja" }
	,xhtml:
	    '<div id="iteration_list_view_item_f13">'
	    + '<div class="list_view_header">'
	    + '<div class="menu_items">'
	    + '<a id="activeIterations:2:j_id73">Config file</a>'
	    + '<img />'
	    + '<a>Statistics</a>'
	    + '<img />'
	    + '<a>Edit Version</a>'
	    + '</div>'
	    + '</div>'
	    + '<table>'
	    + '<tbody>'
	    + '<tr class="rich-table-row rich-table-firstrow odd">'
	    + '<td>English (United States) [en-US]</td>'
	    + '<td><a> Translate</a></td></tr>'
	    + '<tr expected-result="1" class="rich-table-row">'
	    + '<td>日本語 [ja]</td>'
	    + '<td><a> Translate</a></td></tr>'
	    + '</tbody></table>'
	    + '</div>'
    }
});

/*************
 * Admin pages
 */
myMap.addPageset({
    name: 'adminPages'
    , description: 'Admin pages'
    , pathRegexp: '/admin/.*'
});

myMap.addElement('adminPages', {
    name: 'manageLangTableRow'
    , description: 'Row Language Table'
    , args: [
        {
	   name: 'lang'
	   , description: 'Specified row by language'
	   , defaultValues: LANGS
	}
    ]
    , getLocator: function(args){
        var lang=args['lang'];
	return '//table[contains(@class, "rich-table")]/tbody/tr[td[normalize-space(text())="'
	    +lang+ '"]]';
    }
    , testcase1: {
       args: { lang: "zh-Hans" }
       , xhtml:
	   '<table class="rich-table ">'
	    + '<thead></thead>'
	    + '<tbody>'
	    + '<tr><td> en-US</td><td>English</td></tr>'
	    + '<tr><td> zh-Hans-CN</td><td>English</td></tr>'
	    + '<tr expected-result="1"><td> zh-Hans</td><td>English</td></tr>'
	    + '</tbody>'
	    +'</table>'
    }
});


const languageSelectionPulldown='css=[id*="localeField:localeName"]';
manager.addRollupRule({
    name: 'add_new_language'
    , description: 'Add new language',
    args: [
	{
	    name:'lang'
	    , description:'Language to be added'
	    , exampleValues: LANGS
	}
    ]
    , commandMatchers: []
    , getExpandedCommands:function(args){
	var commands=[];
	commands.push({
	    command:'clickAndWait'
	    , target: 'css=a:contains("Add New Language")'
	});
	commands.push({
	    command:'type'
	    , target: languageSelectionPulldown
	    , value: args.lang
	});
	commands.push({
	    command: 'clickAndWait'
	    , target: 'css=div.actionButtons>input[type="submit"]'
	});
        return commands;
    }
});

/*************
 * Webtran Pages
 */

myMap.addPageset({
    name: 'webtranPages'
    , description: 'Translation Editor pages'
    , pathRegexp: '/webtran/Application\.html.*'
});

/** Document List View */
myMap.addElement('webtranPages', {
    name: 'documentListTable'
    , description: 'Document List Table'
    , args: []
    , locator: 'css=table.DocumentListTable'
});

myMap.addElement('webtranPages', {
    name: 'documentRowByName'
    , description: 'Select document by document name in document list view'
    , args: [
       {
	   name: 'name'
	   , description: 'Search document row by name'
	   , defaultValues: []
       }
    ]
    , getLocator: function(args){
	var name=args['name'];
	return '//table[contains(@class, "DocumentListTable")]//div[contains(text(),"' +name+ '")]';
    }
    , testcase1: {
	args: { name: "Pam" }
	, xhtml:
	 '<table class="DocumentListTable">'
         + '<tr><td></td><td><div><div><div></div><div>Nmap</div></div></div></td></tr>'
	 + '<tr><td></td><td><div><div><div></div><div expected-result="1">Pam</div></div></div></td></tr>'
	 + '<tr><td></td><td><div><div><div></div><div>Preface</div></div></div></td></tr>'
         + '</table>'
    }
});

function webtranPages_get_locator(row){
    if (row < 0){
	var lastNum= -1 -row;
	return '//tr[contains(@class,"TableEditorRow")][position()=last()-'+lastNum+']';
    }else if (row == 0){
	return '//tr[contains(@class,"TableEditorRow")][contains(@class,"selected")]'
    }
    return '//tr[contains(@class,"TableEditorRow")]['+ row +']';
}

/** Message List View */
myMap.addElement('webtranPages', {
    name: 'messageRow'
    , description: 'Select message by row number in table editor'
    , args: [
	{
	    name: 'row'
	    , description: 'Row number, start from  1, -1 is the last row, 0 is current row'
            , defaultValues: [ -1, 0, 1, 2, 3]
	}
    ]
    , getLocator: function(args){
	var row=args['row'];
	return webtranPages_get_locator(row);
    }
    , testcase1: {
	args: { row:1 }
	,xhtml:
	    '<table class="TableEditor"><colgroup></colgroup>'
	    + '<tr><td></td><td></td></tr>'
	    + '<tr expected-result="1" class="TableEditorRow odd-row">'
	    +     '<td class="TableEditorCell-Source"><table class="TableEditorSource"><tr><td>Source1</td></tr></table></td>'
	    +     '<td class="TableEditorCell-Target"><span class="xml-text">Click here to start translating</span></td>'
	    + '</tr>'
	    + '<tr class="TableEditorRow even-row">'
	    +     '<td class="TableEditorCell-Source"><table class="TableEditorSource"><tr><td>Source2</td></tr></table></td>'
	    +     '<td class="TableEditorCell-Target"><span class="xml-text">Click here to start translating</span></td>'
	    + '</tr>'
	    + '<tr class="TableEditorRow odd-row">'
	    + 	  '<td class="TableEditorCell-Source"><table class="TableEditorSource"><tr><td>SourceLast</td></tr></table></td>'
	    +     '<td class="TableEditorCell-Target"><span class="xml-text">Click here to start translating</span></td>'
	    + '</tr>'
	    + '</table>'
    }
    , testcase2: {
	args: { row:2 }
	,xhtml:
	    '<table class="TableEditor"><colgroup></colgroup>'
	    + '<tr><td></td><td></td></tr>'
	    + '<tr class="TableEditorRow odd-row">'
	    +     '<td class="TableEditorCell-Source"><table class="TableEditorSource"><tr><td>Source1</td></tr></table></td>'
	    +     '<td class="TableEditorCell-Target"><span class="xml-text">Click here to start translating</span></td>'
	    + '</tr>'
	    + '<tr expected-result="1" class="TableEditorRow even-row">'
	    +     '<td class="TableEditorCell-Source"><table class="TableEditorSource"><tr><td>Source2</td></tr></table></td>'
	    +     '<td class="TableEditorCell-Target"><span class="xml-text">Click here to start translating</span></td>'
	    + '</tr>'
	    + '<tr class="TableEditorRow odd-row">'
	    + 	  '<td class="TableEditorCell-Source"><table class="TableEditorSource"><tr><td>SourceLast</td></tr></table></td>'
	    +     '<td class="TableEditorCell-Target"><span class="xml-text">Click here to start translating</span></td>'
	    + '</tr>'
	    + '</table>'
    }
    , testcase3: {
	args: { row:-1 }
	,xhtml:
	    '<table class="TableEditor"><colgroup></colgroup>'
	    + '<tr><td></td><td></td></tr>'
	    + '<tr class="TableEditorRow odd-row">'
	    +     '<td class="TableEditorCell-Source"><table class="TableEditorSource"><tr><td>Source1</td></tr></table></td>'
	    +     '<td class="TableEditorCell-Target"><span class="xml-text">Click here to start translating</span></td>'
	    + '</tr>'
	    + '<tr class="TableEditorRow even-row">'
	    +     '<td class="TableEditorCell-Source"><table class="TableEditorSource"><tr><td>Source2</td></tr></table></td>'
	    +     '<td class="TableEditorCell-Target"><span class="xml-text">Click here to start translating</span></td>'
	    + '</tr>'
	    + '<tr expected-result="1" class="TableEditorRow odd-row">'
	    + 	  '<td class="TableEditorCell-Source"><table class="TableEditorSource"><tr><td>SourceLast</td></tr></table></td>'
	    +     '<td class="TableEditorCell-Target"><span class="xml-text">Click here to start translating</span></td>'
	    + '</tr>'
	    + '</table>'
    }
    , testcase4: {
	args: { row:0 }
	,xhtml:
	    '<table class="TableEditor"><colgroup></colgroup>'
	    + '<tr><td></td><td></td></tr>'
	    + '<tr class="TableEditorRow odd-row">'
	    +     '<td class="TableEditorCell-Source"><table class="TableEditorSource"><tr><td>Source1</td></tr></table></td>'
	    +     '<td class="TableEditorCell-Target"><span class="xml-text">Click here to start translating</span></td>'
	    + '</tr>'
	    + '<tr expected-result="1" class="TableEditorRow even-row selected highlighted">'
	    +     '<td class="TableEditorCell-Source"><table class="TableEditorSource"><tr><td>Source2</td></tr></table></td>'
	    +     '<td class="TableEditorCell-Target"><span class="xml-text">Click here to start translating</span></td>'
	    + '</tr>'
	    + '<tr class="TableEditorRow odd-row">'
	    + 	  '<td class="TableEditorCell-Source"><table class="TableEditorSource"><tr><td>SourceLast</td></tr></table></td>'
	    +     '<td class="TableEditorCell-Target"><span class="xml-text">Click here to start translating</span></td>'
	    + '</tr>'
	    + '</table>'
    }
});


myMap.addElement('webtranPages', {
    name: 'targetCell'
    , description: 'Message target cell on given row number'
    , args: [
	{
	    name: 'row'
            , description: 'Row number, start from  1, -1 is the last row, 0 is current row'
            , defaultValues: [ -1, 0, 1, 2, 3]
	}
    ]
    , getLocator: function(args){
	var row=args['row'];
	return webtranPages_get_locator(row) + '//td[contains(@class,"TableEditorCell-Target")]';
    }
    , testcase1: {
	args: { row:1 }
	,xhtml:
	    '<table class="TableEditor"><colgroup></colgroup>'
	    + '<tr><td></td><td></td></tr>'
	    + '<tr class="TableEditorRow odd-row">'
	    +     '<td class="TableEditorCell-Source"><table class="TableEditorSource"><tr><td>Source1</td></tr></table></td>'
	    +     '<td  expected-result="1" class="TableEditorCell-Target"><span class="xml-text">Click here to start translating</span></td>'
	    + '</tr>'
	    + '<tr class="TableEditorRow even-row">'
	    +     '<td class="TableEditorCell-Source"><table class="TableEditorSource"><tr><td>Source2</td></tr></table></td>'
	    +     '<td class="TableEditorCell-Target"><span class="xml-text">Click here to start translating</span></td>'
	    + '</tr>'
	    + '<tr class="TableEditorRow odd-row">'
	    + 	  '<td class="TableEditorCell-Source"><table class="TableEditorSource"><tr><td>SourceLast</td></tr></table></td>'
	    +     '<td class="TableEditorCell-Target"><span class="xml-text">Click here to start translating</span></td>'
	    + '</tr>'
	    + '</table>'
    }
});

myMap.addElement('webtranPages', {
    name: 'copySrcButton'
    , description: 'Copy from source button'
    , args: [
	{
	    name: 'row'
            , description: 'Row number, start from  1, -1 is the last row, 0 is current row'
            , defaultValues: [ -1, 0, 1, 2, 3]
	}
    ]
    , getLocator: function(args){
	var row=args['row'];
	return webtranPages_get_locator(row) + '//img[starts-with(@title,"Copy message")]';
    }
    , testcase1: {
	args: { row:2 }
	,xhtml:
	    '<table class="TableEditor"><colgroup></colgroup>'
	    + '<tr><td></td><td></td></tr>'
	    + '<tr class="TableEditorRow odd-row">'
	    +     '<td class="TableEditorCell-Source">'
	    +         '<table class="TableEditorSource">'
	    +            '<tr><td>Source1</td><td><img title="Copy message from"/></td></tr>'
	    +         '</table>'
	    +     '</td>'
	    +     '<td class="TableEditorCell-Target"><span class="xml-text">Click here to start translating</span></td>'
	    + '</tr>'
	    + '<tr class="TableEditorRow even-row">'
	    +     '<td class="TableEditorCell-Source">'
	    +         '<table class="TableEditorSource">'
	    +            '<tr><td>Source2</td><td><img expected-result="1" title="Copy message from"/></td></tr>'
	    +         '</table>'
	    +     '</td>'
	    +     '<td class="TableEditorCell-Target"><span class="xml-text">Copy message from</span></td>'
	    + '</tr>'
	    + '<tr class="TableEditorRow odd-row">'
	    +     '<td class="TableEditorCell-Source">'
	    +         '<table class="TableEditorSource">'
	    +            '<tr><td>Source1</td><td><img title="Copy message from"/></td></tr>'
	    +         '</table>'
	    +     '</td>'
	    +     '<td class="TableEditorCell-Target"><span class="xml-text">Click here to start translating</span></td>'
	    + '</tr>'
	    + '</table>'
    }
});

myMap.addElement('webtranPages', {
    name: 'pageEntry'
    , description: 'Page number entry'
    , args: []
    , locator: 'css=a[title^="Previous Page"]~input'
});

myMap.addElement('webtranPages', {
    name: 'pageButton'
    , description: 'Page navigation button'
    , args: [
	{
	    name: 'action'
            , description: 'First, Previous, Next or Last'
	    , defaultValues: [ 'First', 'Previous', 'Next' , 'Last' ]
	}
    ]
    , getLocator: function(args){
	return 'css=a[title^="' + args['action'] + ' Page"]';
    }
    , testcase1: {
	args: { action:"Previous" }
	,xhtml:
	    '<div>'
	    +'<a title="First Page (Shortcut: Home)"><img /></a>'
	    +'<a expected-result="1" title="Previous Page (Shortcut: PageUp)"><img /></a>'
	    +'<input />'
	    +'<div> of 3</div>'
	    +'<a title="Next Page (Shortcut: PageDown)"><img /></a>'
	    +'<a title="Last Page (Shortcut: PageDown)"><img /></a>'
	    +'</div>'
    }
});

manager.addRollupRule({
    name: 'sim_click'
    , description: 'Simulate a click if normal click does not work'
    , args: [
        {
            name: 'loc'
            , description: 'locator to be click'
        }
    ]
    , commandMatchers: [
        {
	    command: 'mouseOver'
            , target: '.+'
	    , updateArgs: function(command, args) {
		args.loc=command.target;
	        return args;
	    }
	}
        ,{
	    command: 'mouseDownAt'
            , target: '.+'
	    , updateArgs: function(command, args) {
		args.loc=command.target;
	        return args;
	    }
	}
        ,{
	    command: 'mouseUpAt'
            , target: '.+'
	    , updateArgs: function(command, args) {
		args.loc=command.target;
	        return args;
	    }
	}
    ]
    , getExpandedCommands: function(args) {
        var commands = [];
	commands.push({
	    command: 'mouseOver'
	    , target: args.loc
	});
	commands.push({
	    command: 'mouseDown'
	    , target: args.loc
	});
	commands.push({
	    command: 'mouseUp'
	    , target: args.loc
	});
	return commands;
    }
});

manager.addRollupRule({
    name: 'sim_clickat'
    , description: 'Simulate a click using clickAt'
    , args: [
        {
            name: 'loc'
            , description: 'locator to be click'
        }
	,{
	    name: 'coord'
	    , description: 'coordination string like (-10,20)'
	}
    ]
    , commandMatchers: [
        {
	    command: 'mouseOver'
            , target: '.+'
	    , updateArgs: function(command, args) {
		args.loc=command.target;
	        return args;
	    }
	}
        ,{
	    command: 'mouseDownAt'
            , target: '.+'
	    , value: '.+'
	    , updateArgs: function(command, args) {
		args.loc=command.target;
		args.coord=command.value;
	        return args;
	    }
	}
        ,{
	    command: 'mouseUpAt'
            , target: '.+'
	    , value: '.+'
	    , updateArgs: function(command, args) {
		args.loc=command.target;
		args.coord=command.value;
		return args;
	    }
	}
    ]
    , getExpandedCommands: function(args) {
        var commands = [];
	commands.push({
	    command: 'mouseOver'
	    , target: args.loc
	});
	commands.push({
	    command: 'mouseDownAt'
	    , target: args.loc
	    , value: args.coord
	});
	commands.push({
	    command: 'mouseUpAt'
	    , target: args.loc
	    , value: args.coord
	    });
	return commands;
    }
});

manager.addRollupRule({
    name: 'verify_text'
    , description: 'Verify the saved string.'
    , args: [
	{
	    name: 'type'
	    , description: 'Save as Approved or NeedReview'
	    , defaultValues: [ 'Approved', 'Fuzzy', 'New' ]
	}
	,{
	    name: 'row'
            , description: 'Row number, start from  1, -1 is the last row, 0 is current row'
            , defaultValues: [ -1, 0, 1, 2, 3]
        }
        ,{
	    name: 'text'
            , description: 'String to be matched'
            , defaultValues: []
        }
    ]
    , commandMatchers: [
        {
            command: 'waitForElementPresent'
            , target: '.+->//div'
            , updateArgs: function(command, args){
                var s=command.target.replace(/^ui=/, '');
                s=s.replace(/->\/\/div/, '');
                var uiSpecifier=new UISpecifier(s);
                args.row=uiSpecifier.args.row;
                return args;
            }
        }
        ,{
            command: 'verify.+'
            , target: '.+'
            , updateArgs: function(command, args){
                if( command.target.match('//div[@class="TableEditorContent-Empty"]')){
                    args.text='';
                }else{
                    args.text=command.value;
                }
                return args;
            }
        }
        , {
            command: 'verifyAttribute'
            , target: '.+@class'
            , value: '\\*.+StateDecoration\\*'
            , updateArgs: function(command, args){
                var s=command.value.replace(/^\*/,'');
                args.type=s.replace(/StateDecoration\*/, '');
                return args;
            }
        }
    ]
    , getExpandedCommands: function(args) {
	var commands = [];
	var row=args.row;

	commands.push({
	    command: 'waitForElementPresent'
	    , target: 'ui=webtranPages::targetCell(row=' + row +')->//div'
	});

	if (args.text.length == 0){
	    commands.push({
		command: 'verifyElementPresent'
		, target: 'ui=webtranPages::targetCell(row=' + row +')->//div[@class="TableEditorContent-Empty"]'
	    });
	    commands.push({
		command: 'verifyAttribute'
		, target: webtranPages_get_locator(row)+'@class'
		, value: '*NewStateDecoration*'
	    });
	}else{
	    commands.push({
		command: 'verifyText'
		, target: 'ui=webtranPages::targetCell(row=' + row +')'
		, value: args.text
	    });
	    commands.push({
		command: 'verifyAttribute'
		, target: webtranPages_get_locator(row)+'@class'
		, value: '*' + args.type +'StateDecoration*'
	    });
	}
        return commands;
    }
});


manager.addRollupRule({
    name: 'save_mouse'
    , description: 'Save with mouse'
    , args: [
	{
	    name: 'type'
	    , description: 'Save as Approved or NeedReview'
	    , defaultValues: [ 'Approved', 'Fuzzy', 'Cancel' ]
        }
	,{
	    name: 'row'
	    , description: 'Row number, start from  1, -1 is the last row, 0 is current row'
	    , defaultValues: [ -1, 0, 1, 2, 3]
	}
        ,{
	    name: 'text'
            , description: 'String to be saved'
            , defaultValues: []
        }
    ]
    , commandMatchers: []
    , getExpandedCommands: function(args) {
	/*
	 * 1. Type
	 * 2. Save
	 * 3. Verify
	 */
	var commands = [];
	var row=args.row;
	var target='ui=webtranPages::targetCell(row=' + row +')';

	commands.push({
	    command:  'storeText'
	    , target: target
	    , value: 'origText' //original text
	});

	commands.push({
	    command:  'storeValue'
	    , target: 'ui=webtranPages::pageEntry()'
	    , value: 'origPageNum'
	});

	commands.push({
	    command:  'click'
	    , target: target
	});

	var targetTextarea=target + '->//textarea';

	commands.push({
	    command:  'waitForElementPresent'
	    , target: targetTextarea
	});

	commands.push({
	    command:  'type'
	    , target: targetTextarea
	    , value: args.text
	});

	var button='ui=webtranPages::messageRow(row=' +row +')->//div[starts-with(@title,"Save as Approved")]';
	if (args.type=='Fuzzy'){
	    button='ui=webtranPages::messageRow(row=' +row +')->//div[starts-with(@title,"Save as Fuzzy")]';
	}else if (args.type=='Cancel'){
	    button='ui=webtranPages::messageRow(row=' +row +')->//div[starts-with(@title,"Cancel")]';
	}

	commands.push({
	    command: 'rollup'
	    , target: 'sim_click'
	    , value: 'loc=' + button
	});


	/* Verify the action */
	if (args.type=='Approved'){
	    if (row==-1){
		commands.push({
		    command: 'click'
		    ,target: 'css=a[title^="Previous Pages"]'
		});
		commands.push({
		    command: 'waitForValue'
		    ,target: 'ui=webpages::pageEntry'
		    ,value: '${origNum}'
		});
	    }
	}else if (args.type=='NeedReview'){
	}else{ // args.type=='Cancel'
	}

	commands.push({
	    command: 'rollup'
	    ,target: 'verify_text'
	    ,value: 'type='+ ((args.text.length==0)? 'New' : args.type) + ' row=' + row + ' text=' +args.text
	});
        return commands;
    }
});

