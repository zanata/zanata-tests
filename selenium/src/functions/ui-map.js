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
//myMap.addPageset({
//    name: 'allPages'
//    , description: 'all pages'
//    , pathRegexp: '.*'
//});

//myMap.addPageset({
//    name: 'langPages'
//    , description: 'Language pages'
//    , pathRegexp: '/language/.*'
//});


//myMap.addElement('langPages', {
//    name: 'langListTable'
//    , description: 'Table that shows list of language'
//    , locator: 'css=table[id$=latestTribes]'
//    , testcase1: {
//        xhtml: '<table id="j_id67:latestTribes" class="rich-table" cellspacing="0" cellpadding="0" border="0">'
//    }
//});

//myMap.addElement('langPages', {
//    name: 'langLink'
//    , description: 'Link to specified language'
//    , args: [
//        {
//            name: 'column'
//            , description: 'Column for reference'
//            , defaultValues: range(1,4)
//        }
//        ,{
//            name: 'value'
//            , description: 'value to match'
//        }
//    ]
//    , getLocator: function(args){
//        var column=args['column'];
//        var value=args['value'];
//        return "//tr[td[" + column+ "][contains(text(),\"" + value+ "\")]]//a"
//    }
//    , testcase1: {
//        xhtml: '<tr class="rich-table-row "><td id="j_id67:latestTribes:3:j_id68" class="rich-table-cell "><a id="j_id67:latestTribes:3:j_id70" class="table_link" href="/language/view/de">de</a></td><td id="j_id67:latestTribes:3:j_id72" class="rich-table-cell "> German</td><td id="j_id67:latestTribes:3:j_id75" class="rich-table-cell "> Deutsch</td><td id="j_id67:latestTribes:3:j_id78" class="rich-table-cell "> 0</td></tr>'
//    }
//});


myMap.addPageset({
    name: 'langListPages'
    , description: 'Language pages'
    , pathRegexp: '/lang.*'
});


myMap.addElement('langListPages', {
    name: 'langRow'
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
	return '//tr[td[' + column + '][contains(text(),"' + value+ '")]]';
    }
    , testcase1: {
	args: { column:1, value:"en-US"}
	,xhtml:
	    '<tr class="rich-table-row rich-table-firstrow ">'
	    +'<td>de</td>'
	    +'<td>German</td>'
	    +'<td>Deut</td>'
	    +'<td></td></tr>'
	    +'<tr expected-result="1" class="rich-table-row rich-table-firstrow ">'
	    +'<td>en-US</td>'
	    +'<td> English (United States)</td>'
	    +'<td> English (United States)</td>'
	    +'<td></td></tr>'
	}
    }
);

