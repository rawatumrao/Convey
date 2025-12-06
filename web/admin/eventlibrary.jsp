<%@ page import="java.util.*"%>
<%@ page import="tcorej.*"%>
<%@ page import="tcorej.bean.ClientBean"%>
<%@ page import="org.json.*"%>
<%@ page import="tcorej.bean.*"%>
<%@ page import="tcorej.showcase.*"%>

<%@ include file="/include/globalinclude.jsp"%>
<%
String jqueryVersion = Constants.JQUERY_2_2_4;
//configuration
Configurator conf = Configurator.getInstance(Constants.ConfigFile.GLOBAL);
// What's it called this week, Bob?
String sProductTitle = conf.get("dlitetitle");
boolean analyticsActive = StringTools.n2b(conf.get(Constants.ANALYTICS_ACTIVE_CONFIG));
// generate pfo and ufo
PFO pfo = new PFO(request);
UFO ufo = new UFO(request);
Logger logger = Logger.getInstance();
String sQueryString = Constants.EMPTY;
String sCodeTag = conf.get("codetag");
int tp_key_length = StringTools.n2i(conf.get("tp_key_length"), 10);
try {
	pfo.sMainNavType = "library";
	pfo.secure();
	pfo.setTitle("Event Library");
	PageTools.cachePutPageFrag(pfo.sCacheID, pfo);
	PageTools.cachePutUserFrag(ufo.sCacheID, ufo);
	sQueryString = ufo.toQueryString();
	String sEi = request.getParameter("ei");
	
%>
<jsp:include page="/admin/headertop.jsp">
	<jsp:param name="pfi" value="<%=pfo.sCacheID%>" />
	<jsp:param name="ufi" value="<%=ufo.sCacheID%>" />
	<jsp:param name="jqueryVersion" value="<%=jqueryVersion%>" />
</jsp:include>

<link href="/admin/css/jquery.datatable.css" rel="stylesheet" type="text/css" media="screen" />
<link href="/admin/css/jquery.replacefolders.css" rel="stylesheet" type="text/css" media="screen" />
<style>
	#decklist>.aDeck{ width: 300px;border-radius: 7px;background: #f1f3f4!important;padding:8px 6px 2px 8px; cursor: pointer; }
	#decklist>.aDeck:hover{background-color: #ddd!important; cursor: pointer; }
	#decklist .deckDesc{margin-top:8px!important; }	
	
	a.jstree-clicked > i.jstree-icon
 {
 	 background-image: url(/admin/images/folder13x15_clicked.png) !important;
 	 background-position: 5px 1px !important;
 }
 
 	a.jstree-clicked > i.jstree-icon.jstree-themeicon.template.jstree-themeicon-custom 
 {
 	 background-image: url(/admin/images/folder13x15_clicked.png) !important;
 	 background-position: 5px 1px !important;
 }
 
 .jstree-icon.jstree-themeicon.template.jstree-themeicon-custom{
	background: url("/js/jquery/jstree/themes/default/32px.png") -228px -68px no-repeat;
}

a.jstree-clicked > i.jstree-icon.jstree-themeicon.template.jstree-themeicon-custom.template  {
  	background-image: url("/js/jquery/jstree/themes/default/32px.png") !important;
	background-position: -133px -68px !important;
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
	
</style>
<jsp:include page="/admin/headerbottom.jsp">
	<jsp:param name="pfi" value="<%=pfo.sCacheID%>" />
	<jsp:param name="ufi" value="<%=ufo.sCacheID%>" />
</jsp:include>
<%
	AdminFolder adminfolder = new AdminFolder();
	AdminUser au = AdminUser.getInstance(ufo.sUserID);
	String userId = au.sUserID;
	String userFolderId = au.sRootFolder;
	String sSessionID = ufo.sSessionID;
	String folderIdToExpandTo = au.sHomeFolder;
	if (ufo != null && !ufo.sFolderID.equals("")) {
		folderIdToExpandTo = ufo.sFolderID;
	}
	if (au.isGuestPresenter()) {
		au.expireSession(sSessionID);
		logger.log(Logger.INFO, "eventlibrary.jsp", "Guest Admin attempted to view Event Library. Username: " + au.sUsername + ", Email: " + au.sEmailAddress + ", EventId: " + GuestPresenter.getEventidByName(au.sUsername));
		throw new Exception(Constants.ExceptionTags.EINVALSESSION.display_code());
	}
	
	final ArrayList<FolderDetailsBean> folderList = AdminFolder.getEventFolderAncestry(folderIdToExpandTo);
	JSONArray expandList = new JSONArray();
	for(FolderDetailsBean detail : folderList){
		if(!StringTools.isNullOrEmpty(detail.getFolderid())){
			expandList.put(detail.getFolderid());
		}
	}

	
	
	boolean bShowReport = au.can(Perms.User.RUNREPORTS);
	String temp = AdminFolder.getInitialFolderListToDisplay(userId,userFolderId, folderIdToExpandTo);
	boolean bCreateevent = au.can(Perms.User.CREATEPRESENTATIONS);
	boolean bMove = au.can(Perms.User.MOVEFOLDERS);
	boolean bMoveEvents = au.can(Perms.User.MOVEPRESENTATIONS);
	boolean bCreate = au.can(Perms.User.CREATEFOLDERS);
	boolean bDelete = au.can(Perms.User.DELETEFOLDERS);
	boolean bRename = au.can(Perms.User.RENAMEFOLDERS);
	boolean bShowevent = au.can(Perms.User.COPYPRESENTATIONS);
	boolean bShowdelete = au.can(Perms.User.DELETEEVENTS);
	boolean bShowEdit = au.can(Perms.User.MODIFYEXISTINGEVENTS);
	boolean bShowEditDefaults = au.can(Perms.User.MANAGEFOLDERTEMPLATES);
	
	boolean bHasContextMenu = bCreate || bRename || bDelete;
	
	ClientBean clientInfo = AdminClientManagement.getClientByName(AdminFolder.getClientName(folderIdToExpandTo));
	String sViewerDomain =clientInfo.getViewerDomain();
	String sViewerBaseURL = conf.get("viewerbaseurl");
%>
<div class="messageBar"><span id="messageBar"></span></div>
<div class="grayboxLibrary">
<!-- Dynamic Search Box in top-left corner -->
    <div id ="folderSearchB">
        <input type="text" id="folderSearchInput" autocomplete="off" placeholder="Search" readonly onfocus="this.removeAttribute('readonly');"
               style="width:150px; padding:5px; border:1px solid #ccc; border-radius:4px; font-size:14px;" />
    </div>
	<div id="ft" valign="top"; >
		<span id="ftHandle" style="z-index:1 !important;" class="ui-resizable-e">&#x2225;</span>
		<span id="folderTree"></span>
	</div>
	<div id="fl" valign="top">
	<%if(au.can(Perms.User.CREATEPORTAL)){ %>
	<div id="createPortal" class="libraryTopButtons"><a href="#" class="button"><img src="images/icon_portal-add.png" border="0" align="texttop" /> Create New Portal</a></div>
	<%}%>
	<%if(bShowEditDefaults){%>
		<div id="defaultEventSettings" class="libraryTopButtons"><a href="#" class="button"><img src="images/icon_template-sm.png" border="0" align="texttop" /> Edit Default Event Settings</a></div>
	<%} %>
		<table id="eventList" cellpadding="0" cellspacing="0" border="0" class="display">
		</table><br/><br/>
		<%if(au.can(Perms.User.VIEWOREDITPORTAL)){ %>
		<div id="portalListHeader"><img src="images/icon_portal.png" style="vertical-align:top; margin-right:6px" /> Portals</div>
		<table id="portalList" cellpadding="0" cellspacing="0" border="0" class="display">
		</table>
		<br/><br/>
		<%}%>
		<div id="deletedEventListHeader"><img src="images/icon_trash.png" style="vertical-align:top; margin-right:6px" /> Recently expired and deleted</div>
		<table id="deletedEventList" cellpadding="0" cellspacing="0" border="0" class="display">
		</table>
		<br/>
		<br/>
	</div>
</div>

<div class="boxFull topLine" style="display:none">
     <a id="feature_showcase" class="buttonSmall buttonCreate" style="margin:5px 0 0 10px"></a>
</div>  

	<jsp:include page="/admin/footertop.jsp">
		<jsp:param name="pfi" value="<%=pfo.sCacheID%>"/>
		<jsp:param name="ufi" value="<%=ufo.sCacheID%>"/>
		<jsp:param name="jqueryVersion" value="<%=jqueryVersion%>" />
	</jsp:include>

<jsp:include page="/admin/copy_event_tree.jsp">
	<jsp:param name="pfi" value="<%=pfo.sCacheID%>" />
	<jsp:param name="ufi" value="<%=ufo.sCacheID%>" />
</jsp:include>
<form name="viewevent" id="viewevent" action="" method="post" target="_blank">
		<input type="hidden" name="autologin" value="false"> 
</form>
<style>
.ui-resizable{z-index: 0 !important;}
</style>
<script type="text/javascript" src="/js/jquery/jstree/jstree.js?<%=sCodeTag%>"></script>
<script type="text/javascript" src="/js/jquery/jstree/jstree.contextmenu.js?<%=sCodeTag%>"></script>
<script type="text/javascript" src="/js/jquery/jstree/jstree.types.js?<%=sCodeTag%>"></script>
<script type="text/javascript" src="/js/jquery/jstree/jstree.dnd.js?<%=sCodeTag%>"></script>
<script type="text/javascript" src="/js/jquery/jquery.dataTables.min-1.8.1.js"></script>
<script type="text/javascript" src="/js/analytics.js"></script>
<script type="text/javascript">
	function viewwebcast(seventid,seventguid){
		var tp_key = seventguid.substring(0,<%=tp_key_length%>);
		document.forms["viewevent"].action = "https://" + viewerDomain() + "/starthere.jsp?ei=" + seventid + "&tp_key=" + tp_key;
		document.forms["viewevent"].submit();
		return false;
	}
	function nocacheid()
	{
	    var dt = new Date();
	    var rnd = Math.floor((Math.random() * 900) + 100);
	    return (dt.getTime() + "_" + rnd);
	}
	function replaceQueryString(url,param,value) {
	    var re = new RegExp("([?|&])" + param + "=.*?(&|$)","i");
	    if (url.match(re))
	        return url.replace(re,'$1' + param + "=" + value + '$2');
	    else if (url.indexOf("?") == -1)
	        return url + '?' + param + "=" + value;
	    else
	        return url + '&' + param + "=" + value;
	}
 	function viewerDomain(){
 		  if(sViewerDomain=="")return sViewerBaseURL;
 		  return sViewerDomain;
 	}
    document.onselectstart = function() {return false;}
    var invalidfolder = "<%=Constants.TALKPOINT_ROOT_FOLDERID%>";
    var stat =[];
    stat =  <%=temp%>;
    var selectedFolder = "<%=userFolderId%>";
    var Createevent = "<%=bCreateevent%>";
    <%if (!folderIdToExpandTo.equals("")) {%>
		 selectedFolder = "<%=folderIdToExpandTo%>";
    <%}%>
    var expandedList = <%=expandList%>;
    var arrViewerBaseURL = [];
    var sViewerBaseURL = "<%=sViewerBaseURL%>";
    var sViewerDomain = "<%=sViewerDomain%>";
  
	var ui = "<%=userId%>";
	if (<%=analyticsActive%> === true) {
		//analyticsExclude(["param_eventCostCenter"]);
		analyticsInit(ui);	
	}
	var si = "<%=sSessionID%>";
    var slidecopydialog = false;
    var dialogStep = 0;
	var isRestoringTreeState = false; // Flag to track if we're restoring tree state on page load
	function checkCopy(eventid){
		$.ajax({
			method:"GET",
			url:"proc_cancopyevent.jsp?ei=" + eventid,
			dataType:"json",
			success: function(json) {
				if(!json.success) {
					$.alert("Cannot copy this event.",json.msg,"icon_nosign.png");
					return;
				}		
				slidecopydialog = json.slidecopydialog;
				$("#copyForm").prev().remove();
			 	$("#ui-dialog-title-copyForm").remove();
				//var objButton = {"Cancel": function(){$("#copyForm").dialog("close");},"Continue to Schedule":function(){createEvent(eventid);$("#copyForm").dialog("close");}};
				var buttons = [{
						text: "Cancel",
						id: 'cancelCopyBtn',
						click: function(){
							closeCopyDialog();
						}
					},
					{
						text: "Continue to Schedule",
						id: 'confirmCopyBtn',
						click: function() {
							if (dialogStep==1) {
								createEvent(eventid);
								$("#copyForm").dialog("close");
							} else {
								dialogStep = 1;
								if($("#copySlides").is(':checked') && slidecopydialog){
									$("#copyoptions").hide();
									var deckHtml = showDecks(json.sourceEventObj);
									$("#decklist").show();
									$("#decklist").html(deckHtml);
									$("#slideCopyOptions").show();
								}else{
									createEvent(eventid);
								}
							}
						}
					}
				];
				
				if (json.ispublished !== true) {
					$('#copyTypeSelectionDiv').hide();
					$('#copyHelpImg').hide();
				} else {
					$('#copyTypeSelectionDiv').show();
					$('#copyHelpImg').show();
				}
				
				$.confirmCopy(""," ",buttons,"blank.gif");
			}
		});
	}
	
	function deleteEvent (eventid,undelete) {
		var action,confirmAlert,confirmDetail = "";
		if(undelete) {
			action = "undelete";
			confirmAlert = "Are you sure you want to reactivate this event?";
			confirmDetail = "This event will be available to existing and new registrants immediately. Please reschedule the event.  Additional charges may apply."
		} else {
			action = "delete";
			confirmAlert = "Are you sure you want to delete this event?";
			confirmDetail = "This event will be unavailable to registered users immediately."
		} 
		if(<%=au.can(Perms.User.SUPERUSER)%>==true || action == "delete"){
			var confirmDelete = function() {
				$.ajax({
					type: "GET",
					dataType: "json",
					url: "proc_deleteevent.jsp?ei=" + eventid + "&ui=" + ui + "&si=" + si + "&action=" + action,
					success: function(jsonResult) {
						if(undelete) {
							
						} else {
							if(jsonResult.success){
								$.alert("Event deleted successfully!", "This event is no longer available to registered users. If you wish to reactivate this event, it can be found at the bottom of your event list for 90 days.","icon_check.png");
							}else{
								console.log("Stauts" + jsonResult.result);
								if(jsonResult.result=="2"){
									$.alert(jsonResult.message, "" ,"icon_alert.png");
								}else{
									$.alert("There was an error while deleting event.", "" ,"icon_alert.png");
								}		
							}
						}
						//reload the event list
						if(oTable)oTable.fnReloadAjax("folder_functions.jsp?action=eventList&folderId=" + selectedFolder + "&ui=" + ui + "&si=" + si + "&ts=" + nocacheid());
		                if(oDeletedTable)oDeletedTable.fnReloadAjax("folder_functions.jsp?action=deletedeventList&folderId=" + selectedFolder + "&ui=" + ui + "&si=" + si + "&ts=" + nocacheid());
		                <%if(au.can(Perms.User.VIEWOREDITPORTAL)){ %>
		                if(oPortalTable)oPortalTable.fnReloadAjax("folder_functions.jsp?action=portalList&folderId=" + selectedFolder + "&ui=" + ui + "&si=" + si + "&ts=" + nocacheid());
		                <%}%>
						
					}
				});
			};
			var objButton = {"No": function(){$("#alertDialog").dialog("close");},"Yes":function(){confirmDelete(eventid);$("#alertDialog").dialog("close");}};
			$.confirm(confirmAlert,confirmDetail,objButton,"");
		}else{
			$.alert("Request Event Reactivation","Please contact your Sales Representative or send an e-mail to <a href=\"mailto:reactivate@webcasts.com?subject= Request to reactivate presentation number " + eventid + "\"><b>reactivate@webcasts.com</b></a> to request reactivation of this event. Please include the new expiration date in your request.","icon_wizard.png");
		}
	}
	
	function undeleteEvent(eventid) {
		deleteEvent(eventid,true);
	}
	function createnewsetting(){
		var tempQS = replaceQueryString("<%=sQueryString%>","fi",selectedFolder);
		self.location="/admin/schedule_event.jsp?isfoldersettingevent=yes&" + tempQS;
	}
	var oTable,oDeletedTable,oPortalTable;
	function closeShowcase(showcase_stats){
    	$.ajax({
               type: "POST",
				url: "/admin/feature_showcase/proc_showcasetools.jsp",
				data: {
				    ui : '<%=ufo.sUserID%>',
				    action : '<%=FeatureShowcaseTools.Action.SET_ADMIN_SHOWCASE_STATS%>',
				    data : JSON.stringify(showcase_stats)
				},
				dataType: "json",
				async: true,
				success: function(data) {
				    if(data.success){
				    	console.log("data.success");
				    }else{
				    	console.log("data.success failed");
				    }
				},
				error: function(req, status, error) {
				    console.log("Error " + error);
				}
	    	});
	    
		}        
    $(document).ready(function(){
    	
    	 // Scroll to active folder after jsTree loads and selects node
        $('#folderTree').on('ready.jstree', function () {
          setTimeout(function() {
            const activeNode = document.querySelector('.jstree-clicked');
            if (activeNode) {
              const $container = $('#ft');
              const nodeOffset = $(activeNode).offset().top - $container.offset().top + $container.scrollTop();
              $container.animate({ scrollTop: nodeOffset - 50 }, 300); // 20px padding
            }
          }, 400); // Wait for jsTree to finish rendering
        }).on('select_node.jstree', function(e, data) {
            // Only scroll when a node is manually clicked by user, not during tree state restoration
            if (!isRestoringTreeState) {
                setTimeout(function() {
                  const activeNode = document.querySelector('.jstree-clicked');
                  if (activeNode) {
                    const $container = $('#ft');
                    const nodeOffset = $(activeNode).offset().top - $container.offset().top + $container.scrollTop();
                    $container.animate({ scrollTop: nodeOffset - 50 }, 300);
                  }
                }, 200);
            }
          });

    	
    	//Resize the library page height on browser resize
    	var resizeLibrary;
    	window.addEventListener('resize', function() {
    	    clearTimeout(resizeLibrary);
    	    resizeLibrary = setTimeout(doneResizing, 300);
    	});
    	function doneResizing(){
    		//if ($(window).height()>500) {
	    		var newLibraryHeight=($(window).height() - $("#fl").offset().top - 100);
	    		$('#pageWrapper').height(newLibraryHeight);
	    		$('#ft').height(newLibraryHeight);
	    		$('#fl').height(newLibraryHeight);    
	    	//}
    	}
    	//End browser resize
    	doneResizing();
    	//$("#fl").height($(window).height() - $("#fl").offset().top - 100);
	    //$("#ft").height($("#fl").height());
    	$("#ft").resizable({
    		maxWidth: 435,
    		minWidth: 235,
    		autoHide: false,
    		handles: {
    	    	'e': '#ftHandle'
    	    },
    		autoHide: false
    	});
    	$("#ft").scroll(function() {//Keep the draggable handle in place next to the folder tree
    		document.getElementById("ftHandle").style.visibility = "hidden";
			clearTimeout( $.data( this, "scrollCheck" ) );
			$.data( this, "scrollCheck", setTimeout(function() {
				var position = $("#ftHandle").position();
				var newtop = Math.abs(position.top)+250;
				$("#ftHandle").css({marginTop: newtop + "px" });
				//console.log("TPQA - Handle Position is: " + newtop);
				document.getElementById("ftHandle").style.visibility = "visible";
			}, 100) );
    	});
    	//End folder tree horizontal resize
	
		$(document).on('click', '.utilityNav a, .mainNavBar a, .details a', function() {  	      	
            var link = $(this).attr('href');
            if(link==null || link=="#") return true;
            if((invalidfolder==selectedFolder) && (link.indexOf("admin/schedule_event.jsp")>0)){
                $.alert("This action is not permitted.","System Administrators are not permitted to create events within this folder.","icon_nosign.png");
                return false;
            }else if(link.indexOf("starthere.jsp")==-1){
                link = replaceQueryString(link,"fi",selectedFolder);
                window.open(link,"_self");
                return false;
            } 
           return true;      
        });
        $.initdialog();
        $.initdialogs();
        
        
       
		$("#feature_showcase").fancybox({
			'width'				: '50%',
			'height'			: '43%',
	        'autoScale'     	: false,
	        'minWidth'			: 650,
	        'minHeight'			: 350,
	        'autoSize'			: false,
	        'transitionIn'		: 'none',
			'transitionOut'		: 'none',
			'type'				: 'iframe',
			'href' 				: '/admin/feature_showcase/feature_showcase.jsp?<%=sQueryString%>',
			'autoSize'			: false,
			'closeBtn' 			: true,
			'closeClick'  		: false,
		    beforeShow : function() {
	        	$('.fancybox-overlay').css({
	        		'background-color' :'rgba(119, 119, 119, 0.7)'
	        	});
	        },
	        beforeClose: function() {
	        	var showcase_stats = $("[id*='fancybox-frame']")[0].contentWindow.showcase_stats;
	        	var actionUrl = "/admin/feature_showcase/proc_showcasetools.jsp";
	   	      	$.ajax({
	                  type: "POST",
	  				url: actionUrl,
	  				data: {
	  				    ui : '<%=ufo.sUserID%>',
	  				    action : '<%=FeatureShowcaseTools.Action.SET_ADMIN_SHOWCASE_STATS%>',
	  				    data : JSON.stringify(showcase_stats)
	  				},
	  				dataType: "json",
	  				async: false,
	  				success: function(data) {
	  				    if(data.success){
	  						//closeShowcase();
	  				    }else{
	  						//TODO: error handling
	  				    }
	  				},
	  				error: function(req, status, error) {
	  				    //TODO : error handling
	  					//closeShowcase();
	  				}
	  	    	});
			},
			helpers    : { 
				        'overlay' : {'closeClick': false}
			}
		});	 
		
        
       
  
	    
	    $("#defaultEventSettings").click(function(){
	    	 if(invalidfolder==selectedFolder){
	                $.alert("This action is not permitted.","System Administrators are not permitted to create event settings for this folder.","icon_nosign.png");
	                return false;
	    	 }
	      	var actionUrl = "folder_functions.jsp?action=getsettingid";
           	$.ajax({
                type: "POST",
				url: actionUrl,
				data: {"ui" : ui,"si" : si,"folderId" : selectedFolder},
				dataType: "json",
				success: function(data) {
			  		if(data.settingid=="" || data.settingid=="0"){
			  			var objButton = {"No": function(){$("#alertDialog").dialog("close");},"Yes":function(){createnewsetting();$("#alertDialog").dialog("close");}};
						$.confirm("There is no template for this folder. Would you like to create one now?","Use folder templates to set defaults for all new events created in this folder and its subfolders. Subfolders can be assigned their own templates as needed. No existing events will be affected by changes made to a template.",objButton,"icon_wizard.png");
                    }else{
                  		self.location="/admin/summary.jsp?ei=" +  data.settingid + "&" + replaceQueryString("<%=sQueryString%>","fi",selectedFolder);
                    }
                
				},
				error: function(req, status, error) {
		    		$.alert("Oops! Something went wrong.","" + req + status + error,"icon_error.png");
		    	
				}
	    	});
	    });
	    
	    <%if(au.can(Perms.User.CREATEPORTAL)){ %>
	    $("#createPortal").click(function(){
	    	 if(invalidfolder==selectedFolder){
	                $.alert("This action is not permitted.","System Administrators are not permitted to create event settings for this folder.","icon_nosign.png");
	                return false;
	    	 }else{
	    		 self.location = "/admin/schedule_event.jsp?" + "isportal=1&" + replaceQueryString("<%=sQueryString%>","fi",selectedFolder); 		 
	    	 }
	    	 
	    });
	    <%}%>
	    
	    var pluginArr=['types'];
	    
	    <%if(bHasContextMenu){%>
	    	pluginArr.push('contextmenu');
	    <%}%>
	    
	    <%if(bMove){%>
	    	pluginArr.push('dnd');
	    <%}%>
	    
	    pluginArr.push('search');
	    
	    $("#folderTree").on("activate_node.jstree",function(ui_event,jstree_obj){
		    var prevSelectedFolder = selectedFolder;
			selectedFolder = jstree_obj.node.id;
		    if(oTable)oTable.fnReloadAjax("folder_functions.jsp?action=eventList&folderId=" + selectedFolder + "&ui=" + ui + "&si=" + si + "&ts=" + nocacheid());
		    if(oDeletedTable)oDeletedTable.fnReloadAjax("folder_functions.jsp?action=deletedeventList&folderId=" + selectedFolder + "&ui=" + ui + "&si=" + si + "&ts=" + nocacheid());
		    <%if(au.can(Perms.User.VIEWOREDITPORTAL)){ %>
		    if(oPortalTable)oPortalTable.fnReloadAjax("folder_functions.jsp?action=portalList&folderId=" + selectedFolder + "&ui=" + ui + "&si=" + si + "&ts=" + nocacheid());
		    <%}%>
			var inst = $.jstree.reference(jstree_obj.node);
			var oldParentRoot = findClosestRoot(inst,prevSelectedFolder);
			var newParentRoot = findClosestRoot(inst,selectedFolder);
			if((!oldParentRoot || !newParentRoot) || oldParentRoot.id != newParentRoot.id){
			    getViewerDomain(selectedFolder);
			}
			return false;
	    }).on("delete_node.jstree",function(ui_event,jstree_obj){
		<%if(bDelete){%>
			var inst = $.jstree.reference(jstree_obj.node);
			var actionUrl = "folder_functions.jsp?action=delete";
 			$.ajax({
		    	type: "POST",
		    	url: actionUrl,
		    	data: {"ui" : ui,"si" : si,"folderId" : jstree_obj.node.id},
		    	dataType: "json",
		    	success: function(data) {
	     		 	if(data!=true){
	                    var msg = '';
		    			if(data && data[0]){
		    				data = data[0];
						    if(data.errors && data.errors[0] && data.errors[0].message){
								msg = "Failed to Delete Folder. " + data.errors[0].message;
						    }
						}else{
						    msg = "Folders containing events or users cannot be deleted.";
						}    
				    	$.alert("Oops! Something went wrong.",msg,"icon_nosign.png");
			    		inst.refresh_node(jstree_obj.node.parent);  
					}
		    	},
		    	error: function(req, status, error) {
					$.alert("Oops! Something went wrong.","Failed to Delete... " + req + status + error,"icon_error.png");
					inst.refresh_node(jstree_obj.node.parent); 
		    	}
			});
 			<%}%>
	    }).on("ready.jstree", function(e, data){
			var tree = data.instance;
			var sliceIndex = -1;
			//
			for(var i = 0, len = expandedList.length;i<len;i++){
    			    if(expandedList[i] == stat.id){
    					sliceIndex = i;
    					break;
    			    }
	    	}   
			if(sliceIndex != -1){
				expandedList = expandedList.slice(sliceIndex+1);   
			}
			// Set flag to indicate we're restoring tree state on page load
			if(expandedList.length > 0){
			    isRestoringTreeState = true;
			}
			tree.open_node(stat.id);
			if(expandedList.length == 0){
			    expandedList.push(stat.id);
			}
	    }).on("select_node.jstree", function(e, data){
			  var countSelected = data.selected.length;
		      //only allows one folder to be selected at a time
		      //this is a bug with js tree where a folder is selected and a subfolder is expanded, sometimes selecting the subfolder and the parent at the same time
		      //when it should just be the parent. deselect the currently selected node
			  if (countSelected>1) {
				  data.instance.deselect_node( [ data.node.id ] );
		      }
	    }).on("after_open.jstree", function(e, data){
		     var tree = data.instance;
		     if(expandedList && expandedList.length > 1){
			     var id = expandedList[0];
	 		     expandedList.splice(0,1);
	 		     tree.open_node(id);
		     }else if(isRestoringTreeState){
		    	 // Only during tree state restoration on page load
				 tree.select_node(expandedList[0]);
				 
				 // Scroll to the selected node after tree state restoration is complete
				 setTimeout(function() {
				     const activeNode = document.querySelector('.jstree-clicked');
				     if (activeNode) {
				         const $container = $('#ft');
				         const nodeOffset = $(activeNode).offset().top - $container.offset().top + $container.scrollTop();
				         $container.animate({ scrollTop: nodeOffset - 50 }, 300);
				     }
				     // Reset the restoration flag
				     isRestoringTreeState = false;
				 }, 300);
		     }
		}).on("rename_node.jstree",function(ui_event,jstree_obj){
			var inst = $.jstree.reference(jstree_obj.node);
			//rename
			if($.trim(jstree_obj.node.id)){
			    <%if(bRename){%> 
			    var actionUrl = "folder_functions.jsp?action=rename";
 		    	$.ajax({
					type: "POST",
					url: actionUrl,
					data: {"ui" : ui,"si" : si,"folderId" : jstree_obj.node.id,"folderName" : jstree_obj.text},
					dataType: "json",
					success: function(data) {
			    		if(data!=true){
			    			displayFolderTreeErrorMessage(data,"This folder was NOT renamed");
						//	$.alert("Oops! Something went wrong.","This folder was NOT renamed.","icon_error.png");
							inst.refresh_node(jstree_obj.node.parent);
			    		}
					},
					error: function(req, status, error) {
			   			$.alert("Oops! Something went wrong.","Failed to Rename... " + req + status + error,"icon_error.png");
			   			inst.refresh_node(jstree_obj.node.parent);
					}
		    	}); 
 		    	<%}%> 
			}
			//new node
			else{
			    <%if(bCreate){%>
			    //nodes parent .... not node
			    var parentNode = inst.get_node(jstree_obj.node.parent);
	                    if(parentNode.type === "suproot"){
	                        var clientidpattern = /^[a-z]{4}[0-9]{3}$/;
	                        if (!clientidpattern.test(jstree_obj.node.text)){
	                            $.alert("Hmm. Something isn't right.","Please enter a valid client ID in the format of name001. Folder was NOT created.","icon_alert.png");
	                            inst.refresh_node(jstree_obj.node.parent);
	                            return false;
	                        }
	                    }
	                    
	                    <% if(!au.can(Perms.User.SUPERUSER)){%>
		                    if(jstree_obj.node.text.toLowerCase() == '<%=Constants.WEBINAR_FOLDER_NAME%>')
		                    {
		                    	  $.alert("Hmm. Something isn't right.","Folder name is invalid. Folder was NOT created.","icon_alert.png");
		                          inst.refresh_node(jstree_obj.node.parent);  
		                          return false;
		                    }
	                    <%}%>
	                    
				    	var actionUrl = "folder_functions.jsp?action=add";
	                    var parentFolderId = jstree_obj.node.parent;
 				    	$.ajax({
	                        type: "POST",
							url: actionUrl,
							data: {"ui" : ui,"si" : si,"parentFolderId" : parentFolderId,"folderName" : jstree_obj.node.text},
							dataType: "json",
							success: function(data) {
					    		if(data!=true){
					    			displayFolderTreeErrorMessage(data,"Folder was NOT created");
									//$.alert("Oops! Something went wrong.","Folder was NOT created.","icon_error.png");
	                            }
					    		inst.refresh_node(jstree_obj.node.parent);
					    		inst.select_node(jstree_obj.node.parent);
							},
							error: function(req, status, error) {
					    		$.alert("Oops! Something went wrong.","Failed to Add... " + req + status + error,"icon_error.png");
					    		inst.refresh_node(jstree_obj.node.parent);
							}
				    	}); 
			<%}%>
			}
	    }).on("create_node.jstree",function(ui_event,jstree_obj){
			<%if(bCreate){%>
			 var inst = $.jstree.reference(jstree_obj.node);
             inst.set_id(jstree_obj.node,' ');
			 inst.edit(jstree_obj.node);
			 <%}%>
	    }).on("move_node.jstree",function(ui_event,jstree_obj){
			<%if(bMove){%>
			var inst = $.jstree.reference(jstree_obj.node);
			var oldParentRoot = findClosestRoot(inst,jstree_obj.old_parent);
			var newParentRoot = findClosestRoot(inst,jstree_obj.parent);
			if(oldParentRoot.id != newParentRoot.id){
				inst.refresh_node(jstree_obj.parent); 
				inst.refresh_node(jstree_obj.old_parent);
	             $.alert("This action is not permitted.","Folders may not be moved between clients.","icon_nosign.png");
	             return false;
			}else{
			    var actionUrl = "folder_functions.jsp?action=saveHiearchy";
 				$.ajax({
			    	type: "POST",
			    	url: actionUrl,
			    	data: {"ui" : ui,"si" : si,"folderId" : jstree_obj.node.id,"parentFolderId" : jstree_obj.old_parent,"newParentFolderId" : jstree_obj.parent},
			    	dataType: "json",
			    	success: function(data) {
						if(data!=true){
				    		//$.alert("Oops! Something went wrong.","Failed to Move... ","icon_error.png");
				    		displayFolderTreeErrorMessage(data,"Failed to Move");
				    		inst.refresh_node(oldParentRoot);
				    		inst.refresh_node(newParentRoot);
						}
			    	},
			    	error: function(req, status, error) {
						$.alert("Oops! Something went wrong.","Failed to Move... " + req + status + error,"icon_error.png");
						inst.refresh_node(oldParentRoot);
				    	inst.refresh_node(newParentRoot);
			    	}
				}); 
			}
			<%}%>
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
					        	'action' : 'getChildren'
					      },
					      "success" : function(nodes){
								//console.log(nodes);
					      } 
					   }).done(function(d){
					      cb(d); 
					   });
					}
			    },
				"themes":{
				    "url":"/js/jquery/jstree/themes/default/style.css",
				    "dots":true
				},
				'check_callback' : true,
				'multiple':false
			},
			<%if(bHasContextMenu){%>
			'contextmenu' : {
			        'items' : customMenu
			},
			<%}%>
			 <%if(bMove){%>
			'dnd' : {
			 	'check_while_dragging': true,
			 	"is_draggable" : function(node){
			 		<%if(!bMove){%>
			 			return false
			 		<%}else{%>
				 	    if(node[0].type == 'root' || node[0].type == 'suproot' || node[0].type == 'root_template'){
				 			return false;
				 	    }
				 	    return true;
			 	    <%}%>
			 	}
			},
			<%}%>
			'search' : {
		        "case_sensitive": false,
		        "show_only_matches": true,
		        "show_only_matches_children": true,
		        "search_leaves_only": false
		    },
			'types' : {
			  //need to define all types or changes type to 'default'
			    //only root / suproot can be children of #(jstree root)
			    '#':{
					'valid_children':['root','suproot']
			    },
			    //only root can be children of suproot
				"suproot":{
				 	'valid_children':['root','root_template']
				 },
				"root":{
				    
				 },
				"root_template":{
				    icon:"template"
				 },
				"default":{},
				"template":{
				    icon:"template"
				}
			},
			'plugins' : pluginArr
	    });
	    
	    function displayFolderTreeErrorMessage(jsonResult,msg){
			if(jsonResult && jsonResult[0]){
			    jsonResult = jsonResult[0];
			    if(jsonResult.errors && jsonResult.errors[0] && jsonResult.errors[0].message){
					msg = msg + ". " + jsonResult.errors[0].message;
			    }
			    $.alert("Oops! Something went wrong.",msg,"icon_error.png");
			}
	    }
	    
	    function findClosestRoot(inst,nodeID){
			var node = inst.get_node(nodeID);	
			if(node.type == 'root' || node.type == 'root_template'){
			    return node;
			}
			
			for(var i = 0, len = node.parents.length;i<len;i++){
				   var ancestor = inst.get_node(node.parents[i]);
				   if(ancestor.type == 'root' || ancestor.type == 'root_template'){
				       return ancestor;
				   }
			}
			return null;
	    }
	    	     
	    <%if(bHasContextMenu){%>
	     function customMenu(node)
	     {
		 	 var tree = $("#folderTree").jstree(true);	 
		 	 var items = {};
         	<%if(bCreate){%>
	         	items['create'] = {
	        		 "separator_before": false,
	                 "separator_after": false,
	                 "label": "Create",
	                "icon":"jstree-contextmenu-create", 
	                "action": function (data) { 
	                     var position = 'last';
	                     var parent = node;
	                     var newNode = {text:"New Folder"};
	                     if(node.type=='suproot'){
	                	 	//suproot can only have children of type root
	                	 	newNode['type']='root';
	                     }
	                     $('#folderTree').jstree("create_node", parent, newNode, position, false, false);
	                 }
	             };
             <%}%>
             <%if(bRename){%>          
	             items['rename'] =  {
	        		 "separator_before": false,
	                 "separator_after": false,
	                 "label": "Rename",
	                 "icon":"jstree-contextmenu-rename",
	                 "action": function (data) { 
	                     //TODO : can't rename if root
	                     var inst = $.jstree.reference(data.reference),
	                     obj = inst.get_node(data.reference);
	                     inst.edit(obj);
	                 }
	             };
             <%}%>
             <%if(bDelete){%>
	               items['remove'] = {
		        		 "separator_before": false,
		                 "separator_after": false,
		                 "label": "Delete",
		                 "icon":"jstree-contextmenu-delete",
		                 "action": function (data) { 
			 	                var actionUrl = "folder_functions.jsp?action=checkdelete";
				                var ret = false;
								$.ajax({
							    	type: "POST",
							    	url: actionUrl,
				                    async :false,
							    	data: {"ui" : ui,"si" : si,"folderId" : node.id},
							    	dataType: "json",
							    	success: function(data) {
				                        if(data!=true){
				                            var msg = '';
							    			if(data && data[0]){
							    				data = data[0];
											    if(data.errors && data.errors[0] && data.errors[0].message){
													msg = "Failed to Delete Folder. " + data.errors[0].message;
											    }
											}else{
											    msg = "Folders containing events or users cannot be deleted.";
											}    
									    	$.alert("Oops! Something went wrong.",msg,"icon_nosign.png");
				                        }else{
				                        	if(data === true){
				                        		var inst = $("#folderTree").jstree(true);    
				                  				var sel = inst.get_selected();
				                  				if(!sel.length){return false;}
				                        	    inst.delete_node(sel);   
				                        	}    
				                        }
				                    },
							    	error: function(req, status, error) {
										$.alert("Oops! Something went wrong.","Failed to Delete... " + req + status + error,"icon_error.png");
				                    }
								});	                         
		                 }
		             };
             <%}%>
            
         if(node.type.indexOf('root') != -1){
         	delete items.rename;
         	delete items.remove;
         }
         return items;
	  }
	     <%}%>
	   
	   
    	/* ===============================   End of Tree ===================================*/
    	
        function fnFormatDetails (eventid,bIsPortal,eventguid){
		    var ui = "<%=userId%>";
	        var si = "<%=sSessionID%>";
	        var spacer =  "&nbsp;&nbsp;|&nbsp;&nbsp;";
	        var actions = "";
	        
	        var sQueryString = replaceQueryString("<%=sQueryString%>","fi",selectedFolder);
	        
	        <%if (bShowEdit) {%>
        	actions += addSpacer(actions) + "<a href=\"/admin/summary.jsp?ei=" +  eventid + "&" + sQueryString + "\">EDIT</a>"
        	<%}%>
	        <%if (bShowReport) {%>
	        	actions += addSpacer(actions) + "<a href=\"/report/reports_main.jsp?ei=" + eventid + "&" + sQueryString + "\">REPORTS</a>"
	        <%}%>
	        <%if (bShowevent) {%>
	        if(!bIsPortal){
	        	actions += addSpacer(actions) +"<a id=\"copy_event_" + eventid + "\" onClick=\"checkCopy('" + eventid + "');return false;\" href=\"#\">COPY</a>"; 	
	        }else{
	        	actions += addSpacer(actions) +"<a id=\"copy_event_" + eventid + "\" onClick=\"createPortal('" + eventid + "');return false;\" href=\"#\">COPY</a>";
	        }
	        <%}%>
			<% if(bShowdelete) { %>
	        actions += addSpacer(actions) + "<a id=\"delete_event_" + eventid + "\" style=\"cursor:pointer\" onClick=\"deleteEvent(" + eventid + ")\" >DELETE</a>";
	        <%}%>
	        actions += addSpacer(actions) + "<a id=\"view_event_" + eventid + "\" href=\"#\" onclick=\"return viewwebcast('" + eventid + "','" + eventguid +"');\">VIEW</a>";
	      	        
	        return actions;
	    }
    	
    	function addSpacer(actionString) {
    		if(actionString != "") {
    			return  "&nbsp;&nbsp;&nbsp;&nbsp;";
    		}
    		return "";
    	}
    	
    	function fnFormatDetailsDeleted(eventid) {
    		return "<a id=\"undelete_event_" + eventid + "\" style=\"cursor:pointer\" onClick=\"undeleteEvent(" + eventid + ")\">REACTIVATE</a>";
    	}
    	
	    <%if(bMoveEvents){%>
	    function moveEvent(eventid){
			var $hovered = $('#folderTree .jstree-hovered');
	        var treeInst = $('#folderTree').jstree();
	        var current_node = treeInst.get_node(treeInst.get_selected()[0]);
	        var drop_node = treeInst.get_node($hovered.attr("id"));
	        if(current_node.id && drop_node.id){
						var oldParentRoot = findClosestRoot(treeInst,current_node.id);
						var newParentRoot = findClosestRoot(treeInst,drop_node.id);
						if(oldParentRoot.id != newParentRoot.id){
						    $.alert("This action is not permitted.","Events may not be moved between clients.","icon_nosign.png");
						    return false;
						}else{
							var actionUrl = "folder_functions.jsp?action=moveEvent";
	 						$.ajax({
						    	type: "POST",
						    	url: actionUrl,
						    	data: {"ui" : ui,"si" : si,"eventId" : eventid,"parentFolderId" : current_node.id,"newParentFolderId" : drop_node.id},
						    	dataType: "json",
						    	success: function(data) {
									if(data!=true){
									    displayFolderTreeErrorMessage(data,"This folder was NOT moved");
							    	//	$.alert("Oops! Something went wrong.","This folder was NOT moved.","icon_error.png");
									}else{
							    		$("#" + eventid).draggable('destroy');
							    		$("#" + eventid).remove();
									}
						    	},
						    	error: function(req, status, error) {
									$.alert("Oops! Something went wrong.","Failed to Move Event... " + req + status + error,"icon_error.png");
								}
							}); 
						}	
	        }   
	    }
	    <%}%>
    	
    	
    	/* Init the table */
	    oTable = $('#eventList').dataTable({
			"bPaginate": false,
			"bFilter": false,
			"bInfo":false,
			"bProcessing": true,
			"bServerSide": false,
	        "bAutoWidth": false,
	        "bDeferRender": true,
			"sAjaxSource": "folder_functions.jsp?action=eventList&folderId=" + selectedFolder + "&ui=" + ui + "&si=" + si  + "&ts=" + nocacheid(),
	        "oLanguage": {
	             "sZeroRecords": "<div><h1>No Events were found in this folder</h1><%if (bCreateevent) {%><p class=\"details\"><a href=\"/admin/schedule_event.jsp?<%=sQueryString%>\" ><img src=\"/admin/images/icon_plus.png\" alt=\"\" border=\"0\" align=\"absmiddle\" /><span class=\"messagesGreen\">Create New Event</span></a></p><%}%></div>",
	             "sProcessing":  "<div style=\"width:100%\"><img src=\"/admin/images/loading_animation.gif\" /><h1>Processing...</h1></div>"
			},
			"aaSorting": [],
			"aoColumns": [			
			    { "sTitle":"ID","sWidth":"20px"},
			    { "sTitle":"Name"},
			    { "sTitle":"Status","sWidth":"145px"},
			    { "sTitle":"Expires","sWidth":"20px" },
			    { "sTitle":"Type","sWidth":"50px" }			   			    
			],
		   	"fnRowCallback": function( nRow, aData, iDisplayIndex ) {
		       	var sEventid = "<%=sEi%>";
		       	if(sEventid == aData[0]){
		       		$(nRow).addClass('row_selected');
	            	oTable.fnOpen(nRow, fnFormatDetails(aData[0],false,aData[6]),"details");	
		       	}
			    /* Append the grade to the default row class name */
			    $(nRow).attr("id",aData[0]).click(function(event) {
					$(oTable.fnSettings().aoData).each(function (){
				    	$(this.nTr).removeClass('row_selected');
	                	oTable.fnClose(this.nTr);
					});
					$(nRow).addClass('row_selected');
	            	oTable.fnOpen(nRow, fnFormatDetails(aData[0],false,aData[6]),"details");
	            <%if(bMoveEvents){%>
  				}).draggable({
					start: function(event, ui) {
					    oTable.fnClose(nRow);
					},
					stop: function(event,ui){
					   moveEvent(this.id)
					},
					cursorAt: {left:-5,bottom:5},
					cursor: "move",
					distance: 10,
					delay: 100,
/* 					scope: "#folderTree",
					connectWith: ["#folderTree"], */
					opacity: 0.7,
					helper: "clone"
				<%}%>
			    });
			    return nRow;
			}
		});
    	
		oDeletedTable = $("#deletedEventList").dataTable({"bPaginate": false,
			"bFilter": false,
			"bInfo":false,
			"bProcessing": true,
			"bServerSide": false,
	        "bAutoWidth": false,
	        "bDeferRender": true,
			"sAjaxSource": "folder_functions.jsp?action=deletedeventList&folderId=" + selectedFolder + "&ui=" + ui + "&si=" + si  + "&ts=" + nocacheid(),
	        "oLanguage": {
	             "sZeroRecords": "<div class=\"noResultsFound\">No recently expired events</div>",
	             "sProcessing":  "<div style=\"width:100%\"><img src=\"/admin/images/loading_animation.gif\" /><h1>Processing...</h1></div>"
			},
			"aaSorting": [],
			"aoColumns": [			
			    { "sTitle":"ID","sWidth":"20px"},
			    { "sTitle":"Name"},
			    { "sTitle":"Status","sWidth":"50px"},
			    { "sTitle":"Expired On","sWidth":"100px" },
			    { "sTitle":"Type","sWidth":"50px" }			   			    
			],
		   	"fnRowCallback": function( nRow, aData, iDisplayIndex ) {
		       	var sEventid = "<%=sEi%>";
		       	if(sEventid == aData[0]){
		       		$(nRow).addClass('row_selected');
	            	oDeletedTable.fnOpen(nRow, fnFormatDetailsDeleted(aData[0]),"details");	
		       	}
			    /* Append the grade to the default row class name */
			    $(nRow).attr("id",aData[0]).click(function(event) {
					$(oDeletedTable.fnSettings().aoData).each(function (){
				    	$(this.nTr).removeClass('row_selected');
				    	oDeletedTable.fnClose(this.nTr);
					});
					$(nRow).addClass('row_selected');
					oDeletedTable.fnOpen(nRow, fnFormatDetailsDeleted(aData[0]),"details");
	            <%if(bMoveEvents){%>
  				}).draggable({
					start: function(event, ui) {
				   //	$.tree.drop_mode({"str" :this.id});
				    	oDeletedTable.fnClose(nRow);
					},
					stop: function(event,ui){
					   moveEvent(this.id)
					},
					cursorAt: {left:-5,bottom:5},
					cursor: "move",
					distance: 10,
					delay: 100,
					scope: "#folderTree",
					connectWith: ["#folderTree"],
					opacity: 0.7,
					helper: "clone"
				<%}%>
			    });
			    return nRow;
			}
		});
		
		<%if(au.can(Perms.User.VIEWOREDITPORTAL)){ %>
		  oPortalTable = $('#portalList').dataTable({
				"bPaginate": false,
				"bFilter": false,
				"bInfo":false,
				"bProcessing": true,
				"bServerSide": false,
		        "bAutoWidth": false,
		        "bDeferRender": true,
				"sAjaxSource": "folder_functions.jsp?action=portalList&folderId=" + selectedFolder + "&ui=" + ui + "&si=" + si  + "&ts=" + nocacheid(),
		        "oLanguage": {
		             "sZeroRecords": "<div><h1>No Portals were found in this folder</h1><%if (bCreateevent) {%><p class=\"details\"><a href=\"/admin/schedule_event.jsp?<%=sQueryString%>&isportal=1\" ><img src=\"/admin/images/icon_plus.png\" alt=\"\" border=\"0\" align=\"absmiddle\" /><span class=\"messagesGreen\">Create New Portal</span></a></p><%}%></div>",
		             "sProcessing":  "<div style=\"width:100%\"><img src=\"/admin/images/loading_animation.gif\" /><h1>Processing...</h1></div>"
				},
				"aaSorting": [],
				"aoColumns": [			
				    { "sTitle":"ID","sWidth":"20px"},
				    { "sTitle":"Name"},
				    { "sTitle":"Status","sWidth":"145px"},
				    { "sTitle":"Expires","sWidth":"20px" },
				    { "sTitle":"Type","sWidth":"50px" }			   			    
				],
			   	"fnRowCallback": function( nRow, aData, iDisplayIndex ) {
			       	var sEventid = "<%=sEi%>";
			       	if(sEventid == aData[0]){
			       		$(nRow).addClass('row_selected');
		            	oPortalTable.fnOpen(nRow, fnFormatDetails(aData[0],true,aData[6]),"details");	
			       	}
				    /* Append the grade to the default row class name */
				    $(nRow).attr("id",aData[0]).click(function(event) {
						$(oPortalTable.fnSettings().aoData).each(function (){
					    	$(this.nTr).removeClass('row_selected');
		                	oPortalTable.fnClose(this.nTr);
						});
						$(nRow).addClass('row_selected');
		            	oPortalTable.fnOpen(nRow, fnFormatDetails(aData[0],true,aData[6]),"details");
		            <%if(bMoveEvents){%>
	  				}).draggable({
						start: function(event, ui) {
			//		    	$.tree.drop_mode({"str" :this.id});
		                    oPortalTable.fnClose(nRow);
						},
						stop: function(event,ui){
							   moveEvent(this.id)
						},
						cursorAt: {left:-5,bottom:5},
						cursor: "move",
						distance: 10,
						delay: 100,
						scope: "#folderTree",
						connectWith: ["#folderTree"],
						opacity: 0.7,
						helper: "clone"
					<%}%>
				    });
				    return nRow;
				}
			});
		  <%}%>
		  
		  
<%
	boolean fromLogin = !StringTools.isNullOrEmpty(request.getParameter("from_login"));
	if(fromLogin && FeatureShowcaseAssignmentTools.adminHasActiveShowcases(au.sUserID)){
%>
			$("#feature_showcase").trigger("click");
<%
	}
%>
//Dynamic folder search functionality
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

    }); //End of function..
    
    
  	function getViewerDomain(folderid){
		var actionUrl = "folder_functions.jsp?action=getViewerDomain";
		$.ajax({
            type: "POST",
			url: actionUrl,
			data: {"ui" : ui,"si" : si,"folderId" : folderid},
			success: function(data) {
				sViewerDomain = data.replace(/\n/,"");
			},
			error: function(req, status, error) {
				alert(error);
			}
    	});
	}
	$.fn.dataTableExt.oApi.fnReloadAjax = function ( oSettings, sNewSource, fnCallback, bStandingRedraw )
	{
		if ( typeof sNewSource != 'undefined' && sNewSource != null )
		{
			oSettings.sAjaxSource = sNewSource;
		}
		this.oApi._fnProcessingDisplay( oSettings, true );
		var that = this;
		var iStart = oSettings._iDisplayStart;
		
		oSettings.fnServerData( oSettings.sAjaxSource, [], function(json) {
			if(json.error) {
				if(json.error_type =="auth") {
					window.location = "index.jsp?msg=<%=Constants.ExceptionTags.EINVALSESSION.display_code()%>";
					return;
				}
				$.alert("Error retrieving data", "There was an error fetching folder data.","icon_error.png");
				
			}
			/* Clear the old information from the table */
			that.oApi._fnClearTable( oSettings );
			/* Got the data - add it to the table */
			for ( var i=0 ; i<json.aaData.length ; i++ )
			{
				that.oApi._fnAddData( oSettings, json.aaData[i] );
			}
			oSettings.aiDisplay = oSettings.aiDisplayMaster.slice();
			that.fnDraw();
			if ( typeof bStandingRedraw != 'undefined' && bStandingRedraw === true )
			{
				oSettings._iDisplayStart = iStart;
				that.fnDraw( false );
			}
			that.oApi._fnProcessingDisplay( oSettings, false );
			/* Callback user function - for event handlers etc */
			if ( typeof fnCallback == 'function' && fnCallback != null )
			{
				fnCallback( oSettings );
			}
		}, oSettings );
	}
	 	
</script>
<%
} catch (Exception e) {
	//logger.log(logger.CRIT, "jsp", e.getMessage(), "blah");
	//out.print(ErrorHandler.getStackTrace(e));
	response.sendRedirect(ErrorHandler.handle(e, request));
}
%>
<jsp:include page="/admin/footerbottom.jsp">
	<jsp:param name="pfi" value="<%=pfo.sCacheID%>" />
	<jsp:param name="ufi" value="<%=ufo.sCacheID%>" />
</jsp:include>