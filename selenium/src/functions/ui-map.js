// create the UI mapping object. THIS IS THE MOST IMPORTANT PART - DON'T FORGET
// TO DO THIS! In order for it to come into play, a user extension must
// construct the map in this way.
var myMap = new UIMap();

// define UI elements common for all pages. This regular expression does the
// trick. '^' is automatically prepended, and '$' is automatically postpended.
// Please note that because the regular expression is being represented as a
// string, all backslashes must be escaped with an additional backslash. Also
// note that the URL being matched will always have any trailing forward slash
// stripped.

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


