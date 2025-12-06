<%@ page import="java.util.*"%>
<%@ page import="tcorej.*"%>
<%@ page import="tcorej.bean.*"%>
<%@ page import="org.json.*"%>

<%@ include file="/include/globalinclude.jsp"%>

<%
//configuration
Configurator conf = Configurator.getInstance(Constants.ConfigFile.GLOBAL);
String sCodeTag = conf.get("codetag");

// generate pfo and ufo
PFO pfo = new PFO(request);
UFO ufo = new UFO(request);

String sQueryString = Constants.EMPTY;
try {
	pfo.sMainNavType = "library";
	pfo.secure();
	pfo.setTitle("Event Library");

	PageTools.cachePutPageFrag(pfo.sCacheID, pfo);
	PageTools.cachePutUserFrag(ufo.sCacheID, ufo);

	sQueryString = ufo.toQueryString();
	String listType = StringTools.n2s(request.getParameter("listType"));
%>

<jsp:include page="/admin/headertop.jsp">
    <jsp:param name="pfi" value="<%=pfo.sCacheID%>"/>
    <jsp:param name="ufi" value="<%=ufo.sCacheID%>"/>
</jsp:include>
<link href="/admin/css/ui.core.css" rel="stylesheet" type="text/css" media="screen"/>
<link href="/admin/css/styles.css" rel="stylesheet" type="text/css" media="screen"/> 
<link href="/admin/css/jquery.replacefolders.css" rel="stylesheet" type="text/css" media="screen"/> 
<style>
	body{
		background-color: #fff !important;
		height: 100vh;
		display: flex;
		flex-direction: column;
	}
	
	#folderTree {
		flex-grow: 1;
		overflow-y: auto;
    	border-bottom: 2px solid #ccc;
    	margin: 5px 0px;
    	border-top: 2px solid #ccc;
	}
	
	.divRow {
		padding-bottom: 10px !important;
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
    #folderSearchInput { 
    	margin: 7px 0px 0px 10px;
    	width: fit-content;
    }
	
	<%if("1".equals(listType)){%>
		.jstree-ocl{display:none!important;}
	<%}%>
</style>
<%
AdminUser au = AdminUser.getInstance(ufo.sUserID);

String userId = au.sUserID;
String sSessionID = ufo.sSessionID;

String folderIdToExpandTo = au.sHomeFolder;
String action = StringTools.n2s(request.getParameter("action"));
String sFolder= StringTools.n2s(request.getParameter("findfolder"));
String sFolderId = StringTools.n2s(request.getParameter("fi"));
String sFolderName=StringTools.n2s(request.getParameter("foldername"));
String sClientId = StringTools.n2s(request.getParameter("client"));
boolean allowMultiple = StringTools.n2b(request.getParameter("allowMultiple"));
String sCallbackFunction = StringTools.n2s(request.getParameter("callback_func"),"folderTreeCallback");
String sRootFolder = StringTools.n2s(request.getParameter("rootfolder"));
if (StringTools.isNullOrEmpty(sRootFolder)) {
	sRootFolder = au.sRootFolder;
} else if (au == null || !au.canAccessFolder(folderIdToExpandTo)) {
	//Not using the admin user's home folder as root and they can't access the requested root folder
	throw new Exception(Constants.ExceptionTags.ENOUSERAUTH.display_code());
}

if (!Constants.EMPTY.equals(sFolder)) {
	folderIdToExpandTo = sFolder;
} else if ("clientfolder".equalsIgnoreCase(action)) {
	ClientBean clientBean = AdminClientManagement.getClient(sClientId);
	
	if (clientBean != null && !StringTools.isNullOrEmpty(clientBean.getFolderId())) {
		folderIdToExpandTo = clientBean.getFolderId();
	}
}

String temp = AdminFolder.getInitialFolderListToDisplay(userId, sRootFolder, folderIdToExpandTo);

final ArrayList<FolderDetailsBean> folderList = AdminFolder.getEventFolderAncestry(folderIdToExpandTo);
JSONArray expandList = new JSONArray();
for (FolderDetailsBean detail : folderList) {
	if (!StringTools.isNullOrEmpty(detail.getFolderid())) {
		expandList.put(detail.getFolderid());
	}
}


%>
<input type="text" id="folderSearchInput" autocomplete="off" placeholder="Search" readonly onfocus="this.removeAttribute('readonly');"/>
<span id ="folderTree"></span>

<div class="divRow centerThis">
		<a class="buttonSmall" id="cancelFolderSelect" href="#">Cancel</a> &nbsp; 
        <a class="button buttonSave" id="useThisFolder" href="#">Select Folder</a>
	</div>


<jsp:include page="/admin/footertop.jsp">
	<jsp:param name="pfi" value="<%=pfo.sCacheID%>"/>
	<jsp:param name="ufi" value="<%=ufo.sCacheID%>"/>
	<jsp:param name="hidecopyright" value="1"/>
	<jsp:param name="hideconfidentiality" value="1"/>
</jsp:include>

<script type="text/javascript" src="/js/jquery/jstree/jstree.js?<%=sCodeTag%>"></script>
<script type="text/javascript" src="/js/jquery/jstree/jstree.types.js?<%=sCodeTag%>"></script>
<script type="text/javascript" src="/js/jquery/jstree/jstree.search.js?<%=sCodeTag%>"></script>


<script type="text/javascript" src="/js/jquery/jquery.form.js"></script>

<script type="text/javascript">
    var stat = <%=temp%>;
    var callbackFunction = '<%=sCallbackFunction%>';
    var invalidfolder = '<%=Constants.TALKPOINT_ROOT_FOLDERID%>';
    var action = '<%=action%>';
    var selectedFolder = '<%=Constants.EMPTY.equals(folderIdToExpandTo) ? sRootFolder : folderIdToExpandTo%>';
    var selectedFolderName = '';
	var ui = '<%=userId%>';
    var si = '<%=sSessionID%>';
    var expandedList = <%=expandList%>;

    $('#folderTree').on('ready.jstree', function(e, data) {
		var tree = data.instance;
	    tree.open_node(stat.id);	 
	}).on('after_open.jstree', function(e, data) {
	     var tree = data.instance;
	     if (expandedList && expandedList.length > 1) {
		     var id = expandedList[0];
 		     expandedList.splice(0, 1);
 		     tree.open_node(id);
	     } else {
			 tree.select_node(expandedList[0]);
	     }
	}).jstree({
		core: {
		    data: function(node,cb) {
				if (node.id === '#') {
				    return cb([stat]);
				} else {
				   $.ajax({
				      url: 'folder_functions.jsp',
				      type: 'POST',
			          dataType: 'JSON',
				      data: { 
				            ui: ui,
				            si: si,
				            parentFolderId: node.id,
				        	action: 'getChildren'
				        	/* 'selected' : 'false' */
				      },
				      success: function(nodes) {} 
				   }).done(function(d) {
				      cb(d); 
				   });
				}
		    },
			themes: {
			    url: '/js/jquery/jstree/themes/default/style.css',
			    dots: false
			},
			check_callback: true
			<% if (allowMultiple) { %>
				,multiple: true
			<% } %>
		},
		types: {
	  		//need to define all types or changes type to 'default'
		    //only root / suproot can be children of #(jstree root)
		    '#': {
				'valid_children': ['root','suproot']
		    },
		    //only root can be children of suproot
			suproot: {
			 	'valid_children': ['root']
			 },
			root: {},
			'default': {}  
		},
		'search' : {
            "case_sensitive": false,
            "show_only_matches": true,
            "show_only_matches_children": true,
            "search_leaves_only": false
        },
		plugins: ['types','search']
	});
    
    $("#folderSearchInput").on("input keyup", function() {
        var searchString = $(this).val().trim();
    	if(searchString.length > 0) {
    	    $("#folderTree").jstree(true).search(searchString);
    	} else {
    	    $("#folderTree").jstree(true).clear_search();
		}
    });
    
    $("#folderSearchInput").on("keydown", function(e) {
        if (e.which === 27) {
            $(this).val('');
            $("#folderTree").jstree(true).clear_search();
        }
    });			
    
    
    $('#useThisFolder').click(function() {
		var $jsTree = $('#folderTree').jstree(true);
		var node = $jsTree.get_selected();
		var nodeList = new Array();
		<% if (allowMultiple) { %>
			for (i = 0; i < node.length; i++){
				currentNode = node[i]; 
				currentNode = $jsTree.get_node(currentNode);
				nodeList.push(currentNode);				
			}
			console.log(nodeList);
			parent.folderTreeCallbackMultiple(nodeList);
		<% } else { %>
			node = $jsTree.get_node(node);
			parent[callbackFunction](node.id, node.text, $jsTree.get_path(node.id, '/'));
		<% } %>
		parent.$.fancybox.close();
	});

	$('#cancelFolderSelect').click(function() {
		parent.$.fancybox.close();
	});
</script>
<%
}catch(Exception e){
	Logger.getInstance().log(Logger.CRIT, "foldertree.jsp", e.getMessage());
	Logger.getInstance().log(Logger.INFO, "foldertree.jsp", ErrorHandler.getStackTrace(e));
	
	response.sendRedirect(ErrorHandler.handle(e, request));
}
%>
<jsp:include page="/admin/footerbottom.jsp">
    <jsp:param name="pfi" value="<%=pfo.sCacheID%>"/>
    <jsp:param name="ufi" value="<%=ufo.sCacheID%>"/>
</jsp:include>