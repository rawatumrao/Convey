<%@ page import="java.util.*"%>
<%@ page import="tcorej.*"%>
<%@ page import="tcorej.bean.*"%>

<%@ include file="/include/globalinclude.jsp"%>

<%

String jqueryVersion = Constants.JQUERY_2_2_4;

//configuration
Configurator conf = Configurator.getInstance(Constants.ConfigFile.GLOBAL);

String sCodeTag = conf.get("codetag");
// What's it called this week, Bob?
String sProductTitle = conf.get("dlitetitle");

// generate pfo and ufo
PFO pfo = new PFO(request);
UFO ufo = new UFO(request);

Logger logger = Logger.getInstance();

String sQueryString = Constants.EMPTY;
try {
	pfo.sMainNavType = "library";
	pfo.secure();
	pfo.setTitle("Folder Event Search");

	PageTools.cachePutPageFrag(pfo.sCacheID, pfo);
	PageTools.cachePutUserFrag(ufo.sCacheID, ufo);

	sQueryString = ufo.toQueryString();
%>

<jsp:include page="/admin/headertop.jsp">
    <jsp:param name="pfi" value="<%=pfo.sCacheID%>"/>
    <jsp:param name="ufi" value="<%=ufo.sCacheID%>"/>
    <jsp:param name="jqueryVersion" value="<%=jqueryVersion%>" />
</jsp:include>

<link href="/admin/css/jquery.replacefolders.css" rel="stylesheet" type="text/css" media="screen"/>
<%
AdminFolder adminfolder = new AdminFolder();
AdminUser au = AdminUser.getInstance(ufo.sUserID);
String userId = au.sUserID;
String userFolderId = au.sRootFolder;
String sSessionID = ufo.sSessionID;

String folderIdToExpandTo = au.sHomeFolder;
String action = request.getParameter("action");
boolean isLoadData = StringTools.n2b(request.getParameter("loadData"));
String sEventId = StringTools.n2s(request.getParameter("ei"));
boolean isPortalLinkedEvents = StringTools.n2b(request.getParameter("isportallink"));
String sRootFolder = StringTools.n2s(request.getParameter("fi"));
String sSelectedFolders = StringTools.n2s(request.getParameter("selectedFolders"));
String sSelectedEvents = StringTools.n2s(request.getParameter("selectedEvents"));
String temp = Constants.EMPTY;
if(isPortalLinkedEvents){
	temp = adminfolder.getInitialFolderListToDisplay(userId,sRootFolder,sRootFolder,
			"&nbsp;&nbsp;<img src=\"/admin/images/folder13x15.png\">&nbsp;&nbsp;",true,true);
	
}else{
	temp = adminfolder.getInitialFolderListToDisplay(userId,userFolderId,folderIdToExpandTo,
			"&nbsp;&nbsp;<img src=\"/admin/images/folder13x15.png\">&nbsp;&nbsp;",true,false);	
}



HashMap<Integer,FolderDetailsBean>  hmfolderPathList = new HashMap<Integer,FolderDetailsBean>();
if(sEventId!=null && !"".equalsIgnoreCase(sEventId))
{
	hmfolderPathList = adminfolder.getEventFolderList(sEventId);
	//temp = adminfolder.getInitialFolderListToDisplay(userId,userFolderId,folderIdToExpandTo,
			//"&nbsp;&nbsp;<img src=\"/admin/images/folder13x15.png\">&nbsp;&nbsp;",true,hmfolderPathList,sEventId);
}

//out.println("Load Data = " + isLoadData + "\nInitial List = " + temp);
%>
</head>
<body style="background-color:#fff; height: 100vh; display: flex; flex-direction: column;">
    <!-- Dynamic Search Box in top-left corner -->
    <input type="text" id="folderSearchInput" autocomplete="off" placeholder="Search" style="margin: 7px 0px 0px 10px; width: fit-content;" readonly onfocus="this.removeAttribute('readonly');"/>
    
	<span id ="folderTree" style ="flex-grow: 1; overflow-y: auto; border-bottom: 2px solid #ccc; margin: 5px 0px; border-top: 2px solid #ccc;"></span>
		<div class="divRow centerThis" style="padding-bottom: 10px;">
			<a class="buttonSmall" id="cancelFolderSelect" href="#">Cancel</a> &nbsp;
            <a class="button buttonSave" id="useThisFolder" href="#">Select Events and Folders</a> 			
		</div>
<div id="reportAlertDialog" title="Alert"  style="display:none; clear:both; overflow:hidden; width:450px!important" >
	<div class="reportErrorMessageContainer" style="margin: 0 auto;text-align:left;padding:20px;">
            <div class="reportErrorMessageIcon" style="width:90px;float:left;"> <img src="/admin/images/icon_nosign.png" width="50" height="50" /></div>
		<div class="reportErrorMessageContent" style="float:left;width:72%;">
			<div id="reportErrorHeader" style="font-size:35px;color:#666;">This action is not permitted.</div>
			<br/>
			<div id="reportErrorText" style="font-size:18px;"></div>
		</div>
            <div class="clear"></div>
     </div>
</div>

<jsp:include page="/admin/footertop.jsp">
	<jsp:param name="pfi" value="<%=pfo.sCacheID%>"/>
	<jsp:param name="ufi" value="<%=ufo.sCacheID%>"/>
	<jsp:param name="jqueryVersion" value="<%=jqueryVersion%>" />
	<jsp:param name="hidecopyright" value="1"/>
	<jsp:param name="hideconfidentiality" value="1"/>
</jsp:include>

<script type="text/javascript" src="/js/jquery/jstree/jstree.js?<%=sCodeTag%>"></script>
<script type="text/javascript" src="/js/jquery/jstree/jstree.types.js?<%=sCodeTag%>"></script>
<script type="text/javascript" src="/js/Map.js"></script>

<style>
.errorMessageContainer {padding:10px}
.errorMessageIcon {float:left; width:65px}
.errorMessageContent {float:left; width:200px;}
.errorMessageContent span {font-size:18px; color:#666; font-weight:bold; padding-left:20px;width:325px; display:inline-block}
#loadingDialog, #alertDialog {overflow:hidden; width:475px!important; height:65px;}
.ui-dialog {width:500px!important}

.jstree-default .jstree-clicked {
    background: transparent;
    border-radius: 2px;
    box-shadow: none;
    color: inherit;
}

.footerBar{
		display: none;
	}

/* Highlight search results */
.jstree-search {
    font-style: normal !important;
    color: inherit !important;
    font-weight: normal !important;
}

/* Search input styling */
#folderSearchInput:focus {
    outline: none;
    border-color: #4CAF50;
    box-shadow: 0 0 5px rgba(76, 175, 80, 0.3);
}

/* Partial selection (indeterminate) visual hint */
.jstree-default .jstree-checkbox.jstree-undetermined + .jstree-anchor {
	font-style: italic;
}
.jstree-default .jstree-checkbox.jstree-undetermined + .jstree-anchor::after {
	content: '"';
	color: #E67E22;
	margin-left: 4px;
	font-weight: bold;
}

</style>
<script type="text/javascript">

$(document).ready(function(){
    $.initdialog(); 
    var stat =[];
    var eventId = '<%=sEventId%>';
    var folderselected = false;
    stat =  <%=temp%>;
    var invalidfolder = "<%=Constants.TALKPOINT_ROOT_FOLDERID%>";
    var action = "<%=action%>";
    var selectedFolder = "<%=userFolderId%>";
    var selectedFolderName = "";
	var preselectedIds = [];
	var preselectedSet = {};
	var expandedSet = {};
	
	// Get previously selected folders and events from parent window
	var previousSelectedFolders = '';
	var previousSelectedEvents = '';
	var previousPartiallySelectedFolders = '';

	try {
		// Access parent window's selectedFolders and selectedEvents variables
		if (parent && parent.selectedFolders) {
			previousSelectedFolders = parent.selectedFolders;
		}
		if (parent && parent.selectedEvents) {
			previousSelectedEvents = parent.selectedEvents;
		}
		if (parent && parent.selectedPartiallyFolders) {
			previousPartiallySelectedFolders = parent.selectedPartiallyFolders;
		}
	} catch(e) {
		console.log("Could not access parent window variables:", e);
	}
	
	// If parent doesn't have partial folders but eventId exists, build from event's folder path
	if(eventId !== '' && previousPartiallySelectedFolders === '') {
		var epartialFolders = [];
<%
		// Server-side Java loop to build partial folders array
		for(int i=0; i<hmfolderPathList.size(); i++)
		{
			FolderDetailsBean folderDetBean = hmfolderPathList.get(i);			
%>
			epartialFolders.push('<%=folderDetBean.getFolderid()%>');
<%
		}
%>
		if(epartialFolders.length > 0) {
			previousPartiallySelectedFolders = epartialFolders.join("|");
		}
	}
	
	// Create separate arrays for different purposes
	var foldersToExpand = [];          // Folders to expand (selected + partial)
	var itemsToCheck = [];              // Items to check (selected folders + events only)
	var partialFolders = [];            // Folders to mark as indeterminate
	
	// Parse selected folders - add to expand AND check lists
	if (previousSelectedFolders && previousSelectedFolders !== '') {
		var folderIds = previousSelectedFolders.split('|');
		for (var i = 0; i < folderIds.length; i++) {
			if (folderIds[i]) {
				foldersToExpand.push(folderIds[i]);
				itemsToCheck.push(folderIds[i]);
			}
		}
	}
	
	// Parse selected events - add to check list only (events can't be expanded)
	if (previousSelectedEvents && previousSelectedEvents !== '') {
		var eventIds = previousSelectedEvents.split('|');
		for (var i = 0; i < eventIds.length; i++) {
			if (eventIds[i]) {
				itemsToCheck.push(eventIds[i]);
			}
		}
	}
	
	// Parse partially selected folders - add to expand and partial lists (NOT check list)
	if (previousPartiallySelectedFolders && previousPartiallySelectedFolders !== '') {
		var partialIds = previousPartiallySelectedFolders.split('|');
		for (var i = 0; i < partialIds.length; i++) {
			if (partialIds[i]) {
				foldersToExpand.push(partialIds[i]);
				partialFolders.push(partialIds[i]);
			}
		}
	}
	
	// If eventId is provided via URL parameter, add it to itemsToCheck
	// and add its folder path to partialFolders
	if (eventId && eventId !== '') {
		// Add event to items to check
		itemsToCheck.push(eventId);
	}
	
    <% if (!folderIdToExpandTo.equals("")){ %>
	 selectedFolder = "<%=folderIdToExpandTo%>";
    <%}%>
	var ui = "<%=userId%>";
    var si = "<%=sSessionID%>";
	var closeFunction = false;
	var selectedNodeMap = new Map();
	var openNodeArray = [stat.id];
	if(eventId!='')
	{
		openNodeArray = [];
<%
		for(int i=0; i<hmfolderPathList.size(); i++)
		{
			FolderDetailsBean folderDetBean = hmfolderPathList.get(i);			
%>
			openNodeArray[<%=i%>] = '<%=folderDetBean.getFolderid()%>';
			// Add folder to partialFolders list for indeterminate state
			partialFolders.push('<%=folderDetBean.getFolderid()%>');
			// Add folder to foldersToExpand list to ensure it expands
			foldersToExpand.push('<%=folderDetBean.getFolderid()%>');
<%
		}
%>
		selectedFolder = eventId;
	}
	else
	{
		selectedFolder = '' ; // by default do not select any folder/event
	} 
	var changeVar = false;
	var arrOpenFolder = new Array();
	var isRootSelected = false;
	var alertDialogOpts = {
			position: "center",
			resizable: false,
			draggable: false,
			autoOpen: false,
			modal: true,
			dialogClass : 'notitle', 
			position : {
			    my : "center",
			    at : "center",
			    of : window
			},			
			buttons: {
				Ok: function() {
					$(this).dialog('close');
				}
			},
			height: 175
/* 			dialogClass : 'notitle',
			overlay: {
				backgroundColor: '#FFFFFF',
				opacity: 1.0
			},
			buttons: {
				Ok: function() {
					$(this).dialog('close');
				}
			},
			width: "65%",
			height: "75px",
			position : {
			    my : "center",
			    at : "center",
			    of : window
			},
			buttons: [
			    {
			      text: "Close",
			      icons: {
			        primary: "ui-icon-heart"
			      },
			      click: function() {
			        $( this ).dialog( "close" );
			      }
			    }
			  ]		 */	
	};
	
	$("#reportAlertDialog").dialog(alertDialogOpts);
	
	    $("#folderTree").on("activate_node.jstree",function(e,data){
 				if (data.node.id ==  invalidfolder) {
	                  data.instance.deselect_node(data.node); 
	                  $("#reportAlertDialog").dialog("open");
	                  $("#reportErrorHeader").text("Attention!");
	                  $("#reportErrorText").text("Reports cannot be run from this folder");
	       
	                 // $("#alertDialog").dialog({width:'50%',height:'50%'});
	            	//  $.alert("Reports cannot be run from this folder.","Reports cannot be run from this folder.","icon_nosign.png");
	            } 
	    })
	    .on('load_node.jstree', function(e, data){
	       // refresh partial selection hints whenever nodes are loaded
	       refreshUndeterminedHints();
	    })
		// After node load, also refresh undetermined/partial selection hints
		.on('changed.jstree', function(){
			refreshUndeterminedHints();
		})
	    .on("ready.jstree", function(e, data){
		   // Always expand root/home folder first
		   for(var i=0,len = openNodeArray.length;i<len;i++){
		       data.instance.open_node(openNodeArray[i]);
		   }
		   
		   var tree = data.instance;
		   
		   // Process folders and items if needed
		   if (foldersToExpand.length > 0 || itemsToCheck.length > 0) {
		       setTimeout(function() {
		           
		           // Step 1: Recursively expand path to each folder, then expand only that folder
		           function expandNextFolder(index) {
		               if (index >= foldersToExpand.length) {
		                   // All folders expanded, now check selected items
		                   checkSelectedItems(0);
		                   return;
		               }
		               
		               var folderId = foldersToExpand[index];
		               
		               // Check if folder already exists in tree
		               var node = tree.get_node(folderId);
		               if (node && node.id) {
		                   // Folder already loaded, just expand it
		                   tree.open_node(folderId, function() {
		                       expandNextFolder(index + 1);
		                   });
		               } else {
		                   // Folder not loaded yet - need to expand parents first
		                   // Use the helper to find the path and expand ONLY to load it
		                   expandPathToNode(tree, folderId, function(success) {
		                       if (success) {
		                           // Now expand the target folder itself
		                           tree.open_node(folderId, function() {
		                               expandNextFolder(index + 1);
		                           });
		                       } else {
		                           // Couldn't find folder, move to next
		                           expandNextFolder(index + 1);
		                       }
		                   });
		               }
		           }
		           
		           // Step 2: Check ONLY selected folders and events (not partial folders)
		           function checkSelectedItems(index) {
		               if (index >= itemsToCheck.length) {
		                   // All items checked, now apply indeterminate state to partial folders
		                   applyPartialState();
		                   return;
		               }
		               
		               var nodeId = itemsToCheck[index];
		               
		               // Check if item exists in tree
		               var node = tree.get_node(nodeId);
		               if (node && node.id) {
		                   // Item loaded, check it
		                   tree.check_node(nodeId);
		                   checkSelectedItems(index + 1);
		               } else {
		                   // Item not loaded yet - need to expand parents to load it
		                   expandPathToNode(tree, nodeId, function(success) {
		                       if (success) {
		                           tree.check_node(nodeId);
		                       }
		                       checkSelectedItems(index + 1);
		                   });
		               }
		           }
		           
		           // Step 3: Apply indeterminate state ONLY to partial folders (not their children)
		           function applyPartialState() {
		               setTimeout(function() {
		                   // First, uncheck any partial folders that might have been auto-checked
		                   for (var i = 0; i < partialFolders.length; i++) {
		                       var folderId = partialFolders[i];
		                       tree.uncheck_node(folderId);
		                   }
		                   
		                   // Then apply undetermined class to ONLY the specific partial folder nodes
		                   setTimeout(function() {
		                       for (var i = 0; i < partialFolders.length; i++) {
		                           var folderId = partialFolders[i];
		                           var nodeElement = tree.get_node(folderId, true);
		                           if (nodeElement && nodeElement.length > 0) {
		                               var checkbox = nodeElement.find('.jstree-checkbox:first');
		                               // Remove checked/unchecked classes and add undetermined
		                               checkbox.removeClass('jstree-checked jstree-unchecked');
		                               checkbox.addClass('jstree-undetermined');
		                           }
		                       }
		                       // Refresh UI hints
		                       refreshUndeterminedHints();
		                   }, 200);
		               }, 300);
		           }
		           
		           // Start the process: expand folders first
		           if (foldersToExpand.length > 0) {
		               expandNextFolder(0);
		           } else if (itemsToCheck.length > 0) {
		               // No folders to expand, just check items
		               checkSelectedItems(0);
		           } else {
		               // Nothing to do, just apply partial state
		               applyPartialState();
		           }
		       }, 500);
		   }
	    }).jstree({
			'core' : {
			    'data' : function(node,cb){
					if(node.id === '#'){
					    return cb([stat]);
					}else{
					   $.ajax({
					      'url' : 'folder_functions.jsp',
					      "type": 'POST',
				          "dataType": 'JSON',
					      'data' : { 
					            'ui' : ui,
					            'si' : si,
					            'parentFolderId' : node.id,
					        	'action' : 'getFolderAndActiveEvent',
					        	'selected' : preselectedIds.length > 0 ? 'true' : 'false',
					        	// Optionally pass selected IDs so server can mark state.checked
					        	'selectedIds' : preselectedIds.join('|'),
					        	'linksegment' : '<%=isPortalLinkedEvents%>'
					      },
					      "success" : function(nodes){
							//	console.log(nodes);
					      } 
					   }).done(function(d){
					       d = d ? d:[];
						   cb(d); 
					   });
					}
			    },
				"themes":{
				    "url":"/js/jquery/jstree/themes/default/style.css",
				    "dots":false
				},
				'check_callback' : true,
				'animation':50
			},
			'types' : {
 			  //need to define all types or changes type to 'default'
			    //only root / suproot can be children of #(jstree root)
			    '#':{
					'valid_children':['root','suproot']
			    },
			    //only root can be children of suproot
				"suproot":{
				 	'valid_children':['root']
				 },
				"root":{
				    
				 },
				 "event":{
				     icon:"/admin/images/eventIcon.gif"
				 },
				"default":{}  
			},
			'checkbox' :{
				// ensure partial selection (undetermined) state is tracked and bubbled
				three_state: true,
				cascade: 'up+down+undetermined'
			},
			'search' : {
                "case_sensitive": false,
                "show_only_matches": true,
                "show_only_matches_children": true,
                "search_leaves_only": false
            },
			'plugins' : ['types','checkbox','search']
	    });  

	// Helper: Expand ONLY the path to a target node (load parents but don't visually expand them)
	function expandPathToNode(tree, targetId, done) {
		var maxDepth = 20; // Prevent infinite loops
		var currentDepth = 0;
		
		// Recursive function to find and load the path
		function findInChildren(parentId, depth) {
			if (depth > maxDepth) {
				done && done(false);
				return;
			}
			
			// Check if target is already loaded
			var targetNode = tree.get_node(targetId);
			if (targetNode && targetNode.id) {
				done && done(true);
				return;
			}
			
			// Get parent node
			var parentNode = tree.get_node(parentId);
			if (!parentNode || !parentNode.id) {
				done && done(false);
				return;
			}
			
			// Load parent's children if not loaded
			if (parentNode.state && !parentNode.state.loaded) {
				tree.load_node(parentId, function() {
					searchChildren(parentId, depth);
				});
			} else {
				searchChildren(parentId, depth);
			}
		}
		
		function searchChildren(parentId, depth) {
			var parentNode = tree.get_node(parentId);
			if (!parentNode || !parentNode.children) {
				done && done(false);
				return;
			}
			
			// Check if target is a direct child
			if (parentNode.children.indexOf(targetId) !== -1) {
				done && done(true);
				return;
			}
			
			// Search in children folders (not events - ID length > 20)
			var folderChildren = [];
			for (var i = 0; i < parentNode.children.length; i++) {
				var childId = parentNode.children[i];
				if (childId.length > 20) { // It's a folder
					folderChildren.push(childId);
				}
			}
			
			// Try each folder child
			if (folderChildren.length === 0) {
				done && done(false);
				return;
			}
			
			var childIndex = 0;
			function tryNextChild() {
				if (childIndex >= folderChildren.length) {
					done && done(false);
					return;
				}
				
				findInChildren(folderChildren[childIndex], depth + 1);
				childIndex++;
			}
			
			tryNextChild();
		}
		
		// Start from root
		findInChildren(stat.id, 0);
	}

	// Helper: add a subtle visual hint to nodes in an indeterminate (partially selected) state
	function refreshUndeterminedHints(){
		try {
			var tree = $('#folderTree').jstree(true);
			var $cont = tree.get_container();
			$cont.find('.jstree-checkbox').each(function(){
				var $cb = $(this);
				var isUnd = $cb.hasClass('jstree-undetermined');
				var $a = $cb.next('.jstree-anchor');
				if (isUnd) {
					$a.addClass('partial-selected').attr('title', 'Partially selected');
				} else {
					$a.removeClass('partial-selected').removeAttr('title');
				}
			});
		} catch(e) { /* ignore */ }
	}
	
	// Dynamic search functionality - searches as you type
    var searchTimeout;
    $("#folderSearchInput").on("input keyup", function() {
        var searchString = $(this).val().trim();
	        
        // Clear previous timeout
        clearTimeout(searchTimeout);
	        
        // Set a small delay to avoid too many searches while typing
        searchTimeout = setTimeout(function() {
            if(searchString.length > 0) {
                // Perform search with prefix matching
                $("#folderTree").jstree(true).search(searchString);
            } else {
                // Clear search if input is empty
                $("#folderTree").jstree(true).clear_search();
            }
        }, 300); // 300ms delay
    });

    // Clear search when ESC key is pressed
    $("#folderSearchInput").on("keydown", function(e) {
        if (e.which === 27) { // ESC key
            $(this).val('');
            $("#folderTree").jstree(true).clear_search();
        }
    });

    // Global variable to store partially selected folders
    var globalPartialFolderList = [];

    var getSelNodes = function() {
		getSelectedNodes();
	}
    $("#useThisFolder").click(getSelNodes);

	$("#cancelFolderSelect").click(function(){
		parent.hideIframe();
	});

	function getSelectedNodes()
	{	
		var selectedIDs = $('#folderTree').jstree("get_checked",null,true);
		var tree = $('#folderTree').jstree(true);

		var folderList = [];
		var eventList = [];
		var partialFolderList = [];
		loadData = false;
		
		// Get fully checked nodes
		for(var i=0,len = selectedIDs.length;i<len;i++){
		    if(selectedIDs[i] == invalidfolder){
				continue;
		    }
		    
			if(selectedIDs[i].length > 20)
			{
				folderList.push(selectedIDs[i]);
			}
			else
			{
				eventList.push(selectedIDs[i]);
			}
		}
		
		// Get indeterminate (partially selected) folders
		var allNodes = tree.get_json('#', {flat: true});
		for(var i=0; i<allNodes.length; i++){
			var node = allNodes[i];
			// Check if node is a folder and is indeterminate
			if(node.id.length > 20 && node.id != invalidfolder){
				var nodeElement = tree.get_node(node.id, true);
				if(nodeElement && nodeElement.length > 0){
					var checkbox = nodeElement.find('.jstree-checkbox');
					if(checkbox.hasClass('jstree-undetermined')){
						partialFolderList.push(node.id);
					}
				}
			}
		}
		
		// Store in global variable for use in getResult
		globalPartialFolderList = partialFolderList;
		
		//console.log("Partially selected folders:", partialFolderList);
		
		var selectedFolders = folderList.join("|");
		var selectedEvents = eventList.join("|");
		var partiallySelectedFolders = partialFolderList.join("|");

		var url = 'proc_folderEventTree.jsp';
		var dataString = 'folderList='+selectedFolders+'&eventList='+selectedEvents+'&partialFolders='+partiallySelectedFolders;
		//For portal events when loading list dont pass folders as its loading all events 
		<%if(isPortalLinkedEvents){%>
			dataString = 'folderList=&eventList='+selectedEvents;
		<%}%>
		var load = loadFolderData('POST',url,dataString);
	}
	
	function loadFolderData(methodType,urlString,dataString)
	{		
		$.ajax({ type: methodType,
            url: urlString ,
            data: dataString,
            dataType: "json",
            success: getResult,
            error: function(a,b,c)
            {
            	//alert(a + " - " + b + " - " + c);
            }
        });
	}

	function getResult(jsonResult)
	{
		jsonResult = jsonResult[0];
        if (!jsonResult.success) {
        	 for(var i = 0; i < jsonResult.errors.length; i++)
             {
                 var curError = jsonResult.errors[i];
                 alert(curError.element + " - " + curError.message);	
             }
             return;
        }
        else
        {
			var selectedNodes = new Array();
			var selectedEvents = jsonResult.sel_events.EventTableBean;
			var selectedFolders = jsonResult.sel_folders.FolderDetailsBean;

			if(selectedEvents!=undefined)
			{
				for(var i=0; i<selectedEvents.length; i++)
				{
					selectedNodes.push(selectedEvents[i].EventId);
				}
			}

			if(selectedFolders!=undefined)
			{
				for(var i=0; i<selectedFolders.length; i++)
				{
					selectedNodes.push(selectedFolders[i].Folderid);
				}
			}

			// Pass selected nodes and partially selected folders to parent
			parent.selectedFolderEvent(selectedNodes, globalPartialFolderList);
    		//parent.selectedFolderEvent();
    		$("#loadingDialog").dialog("close");
    		parent.hideIframe();
        }
	}

});
</script>
<%
}catch(Exception e){
	//logger.log(logger.CRIT, "jsp", e.getMessage(), "blah");
	//out.print(ErrorHandler.getStackTrace(e));
	response.sendRedirect(ErrorHandler.handle(e, request));
}
%>
<jsp:include page="/admin/footerbottom.jsp">
    <jsp:param name="pfi" value="<%=pfo.sCacheID%>"/>
    <jsp:param name="ufi" value="<%=ufo.sCacheID%>"/>
</jsp:include>
