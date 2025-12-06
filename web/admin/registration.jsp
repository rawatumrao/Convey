<%@ page import="java.util.*"%>
<%@ page import="tcorej.*"%>
<%@ page import="org.json.*" %>
<%@ include file="/include/globalinclude.jsp"%>
<%
//configuration
Configurator conf = Configurator.getInstance(Constants.ConfigFile.GLOBAL);
boolean analyticsActive = StringTools.n2b(conf.get(Constants.ANALYTICS_ACTIVE_CONFIG));

// generate pfo and ufo
PFO pfo = new PFO(request);
UFO ufo = new UFO(request);

AdminUser account = null;

boolean isFolderSettingEvent = false;
String sCusomRegFooter = Constants.EMPTY;
String sCusomRegFormFooter = Constants.EMPTY;
String tpSocialCode = Constants.EMPTY;
String sRegCustomText = Constants.EMPTY;
int iRegLayout_id = 1;
String sdatebartext = Constants.REGISTRATION_DATEBAR_TEXT;
String sCustomEventTitle = Constants.REGISTRATION_CUSTOM_EVENT_TITLE;

boolean bIsPortal = false;
String sPostRegSegmentlist = Constants.EMPTY;
boolean bDefaultPostRegSegmentList = true;
boolean bPortal_ischeckbox = false;
String sPortalData = Constants.EMPTY;
boolean bAdvancedPortalTabEnabled = false;
String sTabType="0";
String segment_builder = Constants.EMPTY;
boolean bCustomSegmentBuilder = false;
try {
	account = AdminUser.getInstance(ufo.sUserID);
	
	String passThruURL = Constants.EMPTY;
	boolean showCancelButton = false;
	boolean bCanHideRegForm = account.can(Perms.User.HIDEREGFORM);
	int iEventId = pfo.iEventID;
	Event currentEvent = null;
	String sQueryString = Constants.EMPTY;

	boolean bIsSegment = false;
	String sCustomLandingText = Constants.EMPTY;
	
	if(iEventId != -1 && Event.exists(iEventId)){
		if(!account.canViewEvent(iEventId)){
			throw new Exception(Constants.ExceptionTags.EEVENTNOTEXIST.display_code());
		}
		currentEvent = Event.getInstance(iEventId);
		bIsPortal = currentEvent.isPortal();
		bIsSegment = currentEvent.isSegment();
		sCustomLandingText = currentEvent.getProperty(EventProps.customreglandingtext);
		if(Constants.EMPTY.equals(sCustomLandingText)){
			sCustomLandingText = Constants.DEFAULT_CUSTOM_REG_TEXT;
		}
	}else{
		throw new Exception(Constants.ExceptionTags.EEVENTNOTEXIST.display_code());
	}
		
	if("y".equalsIgnoreCase(currentEvent.getStatus(EventStatus.summary_visited).value)){
		passThruURL = "summary.jsp";
		pfo.sSubNavType = "registration";
		showCancelButton = true;
	}else{
		passThruURL = "player_select.jsp";
		pfo.sSubNavType = "registration";
	}

	pfo.sMainNavType = "edit";
	pfo.sSubNavCrumbs = "";
	pfo.secure();
	pfo.setTitle("Registration");

	PageTools.cachePutPageFrag(pfo.sCacheID, pfo);
	PageTools.cachePutUserFrag(ufo.sCacheID, ufo);
		
	String sUserId = StringTools.n2s(request.getParameter("ui"));
	String sSessionId = StringTools.n2s(request.getParameter("si"));
	
	//iRegLayout_id = StringTools.n2i(currentEvent.getBranding().getReg_Layout_id(),1);
	
	boolean isCustomRegTxtUsed = RegistrationTools.isCustomRegTxtUsed(iEventId,Constants.DB_ADMINDB);
	String sDefaultRegTxtMssg = Constants.EMPTY;
	if(bIsPortal){
		//String feVal_RegLayout_id_default = currentEvent.getProperty(EventProps.reglayout_default);
		//if(!Constants.EMPTY.equals(feVal_RegLayout_id_default)){
		//	iRegLayout_id =  StringTools.n2i(feVal_RegLayout_id_default,1);
	    //}
		sDefaultRegTxtMssg = RegistrationTools.getDefaultPortalRegPageLandingText(iEventId,Constants.DB_ADMINDB,true,false);
	}else{
		sDefaultRegTxtMssg = RegistrationTools.getDisplayDefaultRegPageLandingText(iEventId, Constants.DB_ADMINDB,true,false);
	}
	iRegLayout_id = currentEvent.getRegLayout();
	
	isFolderSettingEvent = currentEvent.isFolderSettingEvent();
	
	ArrayList<HashMap<String,String>> customFieldsList = new ArrayList<HashMap<String,String>>();
	
	int numOfQuestions = 0;
	if(iEventId != -1){
		customFieldsList = RegistrationTools.getCustomFieldsByEventId(iEventId,Constants.DB_ADMINDB);
		if(customFieldsList!=null)
		{
			numOfQuestions = customFieldsList.size();
		}
		//String sAnswerOrder = Integer.toString(EventTools.getOrderCountForEventId(iEventId,sFieldId,Constants.DB_ADMINDB)+1);	
	}
	sQueryString = pfo.toQueryString() + "&" + ufo.toQueryString();
	
	if(account.can(Perms.User.MANAGESOCIALMEDIA)){
		tpSocialCode = currentEvent.getProperty(EventProps.add_social);
	}
	if(account.can(Perms.User.MANAGEREGFOOTER)){
		sCusomRegFooter = currentEvent.getProperty(EventProps.reg_footer);	
		sCusomRegFormFooter = currentEvent.getProperty(EventProps.reg_form_footer);	
	}
	

	

	sdatebartext = StringTools.n2s(currentEvent.getProperty(EventProps.customregdatebartext));
	sCustomEventTitle = StringTools.n2s(currentEvent.getProperty(EventProps.custom_reg_event_title));
	
	
	if(sdatebartext.equals(Constants.EMPTY_CUSTOM_FIELD)){
		sdatebartext = Constants.EMPTY;
	}else if(sdatebartext.equals(Constants.EMPTY)){
		sdatebartext = Constants.REGISTRATION_DATEBAR_TEXT;
	}
	if(sCustomEventTitle.equals(Constants.EMPTY_CUSTOM_FIELD)){
		sCustomEventTitle = Constants.EMPTY;
	}else if(sCustomEventTitle.equals(Constants.EMPTY)){
		sCustomEventTitle = Constants.REGISTRATION_CUSTOM_EVENT_TITLE;
	}
	
	if(bIsPortal){
		// Moved to portal_settings.jsp
	}
		
%>

<jsp:include page="headertop.jsp">
	<jsp:param name="pfi" value="<%=pfo.sCacheID%>" />
	<jsp:param name="ufi" value="<%=ufo.sCacheID%>" />
</jsp:include>

<link href="/admin/css/jquery.datepick.css" rel="stylesheet" type="text/css" media="screen" />

<jsp:include page="headerbottom.jsp">
	<jsp:param name="pfi" value="<%=pfo.sCacheID%>" />
	<jsp:param name="ufi" value="<%=ufo.sCacheID%>" />
</jsp:include>


<%
	boolean useSimpleLayout = true;
//boolean useSimpleLayout = false;
	String layout = request.getParameter("layout");
	if(layout != null && layout.equals("advanced")){
		useSimpleLayout = false;
	}	
	boolean isCustQuestPresent = StringTools.n2b(request.getParameter("cust_quest"));

	boolean isAnonRegEnabled = StringTools.n2b(currentEvent.getProperty(EventProps.use_anonymous_reg)); 
	
	boolean hasMasterPassword = !StringTools.isNullOrEmpty(currentEvent.getProperty(EventProps.master_password));	
%>

<% if(currentEvent != null){ %>

<header style="display: flex; align-items: center; justify-content: space-between;">
<% if(isFolderSettingEvent){
		String sFoldername = AdminFolder.getFolderName(currentEvent.getProperty(EventProps.fk_folderid));	
	%>

<h1 class="folderSettingsHeader">
	<img src="images/icon_template-sm.png" border="0" align="textbottom" />
	Default Registration Options for &quot;<%=sFoldername%>&quot;
</h1>
<%}else{%>
<h1>
	Registration Options<%=currentEvent != null ? " for " + currentEvent.getShortenedEventTitle() + " (" + iEventId + ") ":""%>
</h1>
<%}%>

<% if(account.can(Perms.User.ENABLENEWREG)){ %>
   <span style="float: right;">
      <!-- input id="regSelectionBtn" class="buttonLarge" type="button" value="Switch Reg!" style="margin-top: 15px; margin-right: 100px;" /-->
      <img src="images/newRegSwitchOn.png" id="newRegOn" height="44" width="403" onclick="switchToNewRegView()" style="cursor: pointer; margin-top: 15px; margin-right: 15px;" />
   </span>
<% } %>
</header>

<br />
<div>
	<div class="graybox">
	<%
		String sClientId = currentEvent.getProperty(EventProps.fk_clientid);
		if(!Constants.EMPTY.equals(sClientId) && sClientId.indexOf("ibmx00")>-1){
		Configurator eventConfig = Configurator.getInstance(Constants.ConfigFile.EVENT);
		String sIBMClient = eventConfig.get("ibm_custom_clientid");
		if(sIBMClient.indexOf(sClientId)>-1){%>
			<div style="color:red;font-size:16px;font-weight:bold">Making changes to the registration fields below will stop data from passing into IBM GRP/Unica. Please DO NOT update any registration fields, answers, or translate any custom registration fields or answers that are already set. If you need to add a new custom question or update any existing forms, please contact <a href="mailto:se@webcasts.com?subject=<%=sClientId %> - <%=iEventId%>" target="_blank">se@webcasts.com</a> and mention <%=sClientId %> - <%=iEventId%>.</div>  
		<%}
	}%>
		<jsp:include page="frag_masterRegFields.jsp">
			<jsp:param name="layout" value="<%=layout%>" />
			<jsp:param name="pfi" value="<%=pfo.sCacheID%>" />
			<jsp:param name="ufi" value="<%=ufo.sCacheID%>" />
			<jsp:param name="bCanHideRegForm" value="<%=bCanHideRegForm%>" />
			<jsp:param name="bIsPortal" value="<%=bIsPortal%>" />
		</jsp:include>
		<%if(account.can(Perms.User.MANAGECUSTOMREG)){%>
		<br />
		<div id="customRegBox">
			<span id="btnAdvancedRegistrationLink"><a><span class="adminFieldName" style="margin-left: 5px">Custom Registration Questions</span></a> </span> <br />
			<div id="advancedRegistrationLink">

				<p style="margin-left: 5px">
					<input type="button" id="addEditCustRegLink" class="button" value="Add New Custom Question" /></a>
				</p>

			
				
				<div id="addEditCustRegDiv" style="display: none;">
					<jsp:include page="frag_addEditCustomReg.jsp">
						<jsp:param name="action" value="ADD" />
						<jsp:param name="iEventId" value="-1" />
					</jsp:include>
				</div>
				<div id="editCustRegDiv" style="display: none;">
					<jsp:include page="frag_addEditCustomReg.jsp">
						<jsp:param name="action" value="EDIT" />
						<jsp:param name="iEventId" value="-1" />
					</jsp:include>
				</div>
				<%if(bIsPortal || bIsSegment){%>
				<br />
				<div class="adminFieldNameSmall" style="margin-left: 15px">
					<%if(bIsPortal){%>
						Portal
					<%}else{%>
						Segment
					<%}%>
					Custom Question Header Text &nbsp;&nbsp; <img src="/admin/images/help.png" class="helpIcon" title="Help with Custom Question Header Text" alt="Help with Custom Question Header Text" name="help" onClick="$.help('customquestion_header','Help with Custom Question Header Text');" style="margin-top: -4px" /><br />
					<form id="frm_custLanding" name="frm_custLanding">
						<textarea id="customLandingPageText" name="customLandingPageText"><%=sCustomLandingText%></textarea>
					</form>
				</div>
				<br />
				<%}%>
				
				<div id="listCustRegDiv">
					<jsp:include page="frag_listCustomReg.jsp" />
				</div>
				
			

			</div>
		</div>
		<%}%>
		
		<%if(account.can(Perms.User.MANAGEREGFOOTER)){%>
			<span class="adminFieldName" style="margin-left: 5px">Registration Form Note</span> &nbsp;&nbsp; <img src="/admin/images/help.png" class="helpIcon" title="Help with Registration Form Note" alt="Help with Registration Form Note" name="help" onClick="$.help('registration_form_note','Help with Registration Form Note');" />
			<br /><br />
			<div style="margin-left: 5px"><input type="button" name="RegFormFooter"  id="RegFormFooter"  class="button" value="Edit Registration Form Note" /></div>
			<!-- new reg form note editor below -->
<!-- 			<div style="margin-left: 5px"><input type="button" name="RegFormFooter1"  id="RegFormFooter1"  class="button" value="NEW!! Registration Form Note Editor" /></div> -->
			<!-- new reg form note editor above -->
			<br />
			<%}%>
		<br />
	</div><br />
	
	
	<h2>Customize Event Landing Page</h2>
		<div class="sectionBoxWide">
			<h3 id="btnShowOptionalContent">
				<a><span class="arrowClosed"> Landing Page Content</span></a>
				<%if(iRegLayout_id<4){ %>
					&nbsp;&nbsp; <img src="/admin/images/help.png" class="helpIcon" title="Help with Registration Landing Page Content" alt="Help with Registration Landing Page Content" name="help" onClick="$.help('registration_page_landing_text','Help with Registration Landing Page Content');" />
				<%}else{ %>
					&nbsp;&nbsp; <img src="/admin/images/help.png" class="helpIcon" title="Help with Registration Landing Page Content" alt="Help with Registration Landing Page Content" name="help" onClick="$.help('registration_page_landing_text_layout4','Help with Registration Landing Page Content');" />
				<%} %>
			</h3>
			<div id="showOptionalContent" style="display: none;"
				class="contentArrowIndented">
				<form id="frm_regLanding" name="frm_regLanding">
					<%if(iRegLayout_id>3){ %>
						<input type="hidden" name="sreglayoutid" id="sreglayoutid" size="1" value="<%=iRegLayout_id%>" />
					<div>
						
						<strong>Title Bar Text</strong> &nbsp; <input type="text" name="sCustomEventTitle" id="sCustomEventTitle" size="80" value="<%=sCustomEventTitle%>" /><br> <br>
						
						<%if(!bIsPortal){%>
						<strong>Date Bar Text</strong> &nbsp; <input type="text" name="sdatebartext" id="sdatebartext" size="80" value="<%=sdatebartext%>" />
						<br> <br>
						<%} %>
						<span class="note">Available Auto Fields: __TITLE__ __DATE__ __DURATION__ __REMINDER__ __REMINDERBUTTON__ __REMINDER1__ __REMINDERBUTTON1__ __REMINDER2__ ...etc</span>
					</div>
					<br> <br>
					<!-- Extra header only on layout 4+ -->
					<strong>Landing Text</strong>
					<%} %>
					<input type="radio" name="regtext_type" id="default_reg_text" value="default_reg_text_val" <%=!isCustomRegTxtUsed?"checked":"" %>>
					<label for="default_reg_text">Default</label>&nbsp;&nbsp;&nbsp;&nbsp;
					
					<input type="radio" name="regtext_type" id="custom_reg_text" value="custom_reg_text_val" <%=isCustomRegTxtUsed?"checked":"" %> data-beenClicked=<%=isCustomRegTxtUsed?"true":"" %>>
					<label for="custom_reg_text">Custom</label>&nbsp;&nbsp;&nbsp;&nbsp;
			
					<br />
					<br />
					<div id="regLandingPageTextDiv" style="display: none">
				  		<div id="regLandingPageText" class="froala_editor" name="regLandingPageText">
							<%=StringTools.n2s(RegistrationTools.getRegPageLandingCustomText(iEventId,Constants.DB_ADMINDB))%>						
				  		</div>
						<br />
						<%if(bIsPortal){ %>
							<span class="note">Available Auto Fields: __TITLE__ __ALLSEGMENTS__ __SEGMENTBLOCK1__ __SEGMENTBLOCK2__ __SEGMENTBLOCK3__ __SEGMENTBLOCK4__ </span><br />
						<%}else{ %>
							<span class="note">Available Auto Fields: __TITLE__ __DATE__ __DURATION__ __REMINDER__ __REMINDERBUTTON__ __REMINDER1__ __REMINDERBUTTON1__ __REMINDER2__ ...etc</span><br />
						<%} %>
					</div>
	
					<%if(iRegLayout_id<4){ %>
					<div id="defaultRegPageTxtDiv" style="display: none; width:955px" class="whitebox">
						<pre><%=sDefaultRegTxtMssg%></pre>
					</div>
					<%} %>
				</form>
			</div>
		</div>	
	
	<div class="boxFull topLine" style="display: none">
		<a id="open_image_upload" class="buttonSmall buttonCreate" style="margin: 5px 0 0 10px"></a>
	</div>

	
	<%if(account.can(Perms.User.MANAGELANDINGPAGELBL)){%>
	<br />
	<div class="sectionBoxWide">
		<h3 id="btnShowRegDefaultText">
			<a><span class="arrowClosed">Landing Page Labels</span></a>
			&nbsp;&nbsp; <img src="/admin/images/help.png" class="helpIcon" title="Help with Landing Page Labels" alt="Help with Landing Page Labels" name="help" onClick="$.help('<%=currentEvent.isPortal()?"portal_":""%>landing_page_labels','Help with Landing Page Labels');" />
		</h3>
		<div id="showRegDefaultText" style="display: none;" class="contentArrowIndented">
			<a id="regdefaultText" href="/admin/defaultregtext.jsp?<%=sQueryString%>" class="button">Edit Landing Page Labels</a> 
			<br />
		</div>
	</div>
	<%}%>

	<%if(account.can(Perms.User.MANAGEREGFOOTER)){%>
	<br />
	<div class="sectionBoxWide">
		<h3 id="btnShowRegFooter">
			<a><span class="arrowClosed">Registration Footer</span></a>&nbsp;&nbsp;<img src="/admin/images/help.png" class="helpIcon" title="Help with Registration Footer" alt="Help with Registration Footer" name="help" onClick="$.help('reg_footer','Help with Registration Footer');" />
		</h3>
		<div id="divRegFooter" class="contentArrowIndented">
			<!-- new footer editor below -->
			<a id="regfooter1" href="/admin/froala_editor/footer_editor.jsp?<%=sQueryString%>&fieldtype=regfooter" class="button">Edit Registration Page Footer </a>
			<!-- new footer editor above -->
			<%if(account.can(Perms.User.SUPERUSER)){%>
				<a id="regfooter" href="/admin/managefooter.jsp?<%=sQueryString%>&fieldtype=regfooter" class="button"> Edit Registration Page Footer - OLD</a>
			<%} %>
			<br />
		</div>
	</div>
	<%}%>
	
	<%if(account.can(Perms.User.MANAGESOCIALMEDIA)){%>
	<br />
	<div class="sectionBoxWide">
		<h3 id="btnShowSharingContent">
			<a><span class="arrowClosed">Social Sharing</span></a> &nbsp;&nbsp; <img src="/admin/images/help.png" class="helpIcon" title="Help with Social Sharing" alt="Help with Social Sharing" name="help" onClick="$.help('social_sharing','Help with Social Sharing');" />
		</h3>
		<div id="showSharingContent" style="display: none;" class="contentArrowIndented">
			<a id="shareSocial" href="/admin/socialnetwork.jsp?<%=sQueryString%>" class="button"> Manage Social Sharing</a> <br />
		</div>
	</div>
	<%}%>
	
	<%if(bIsPortal){} %>
		<br />
		<div style="display: none;" class="contentArrowIndented">
			<a id="bioBuilder" href="/admin/bio_builder/bio_builder.jsp?<%=sQueryString%>" class="button"> Speaker Details</a> <br />
		</div>
	<span class="note" id="ce_required_fields" style="display: none">Viewer Certificates and/or Certification Exam has been enabled for this event. Please be sure that the First Name and Last Name standard registration fields are enabled for this event. </span>
</div>
</div>



<div class="saveAndContinue">
	<span id="savecancelbtn_div"> <input type="hidden" id="adding" name="adding" value=""> <%if(showCancelButton){%> <input id="cancelBtn" type="button" value="&laquo; Back to Summary" class="buttonSmall" /> <%}%> <input id="saveAndContinueBtn" class="buttonLarge" type="button" value="Save and Continue &raquo;" style="margin-top: 20px;" /></span> 
	<input id="processing" type="button" value="Please Wait..." class="buttonLarge createNew disabledButton" style="display: none" />
</div>

<form name="<%=Constants.PASSTHRU_FORM_ID%>"
	id="<%=Constants.PASSTHRU_FORM_ID%>" method="get" action="<%=passThruURL%>">
	<input type="hidden" id="<%=Constants.PASSTHRU_EVENTID_ID%>" name="<%=Constants.PASSTHRU_EVENTID_NAME%>" value="<%=request.getParameter(Constants.RQEVENTID)%>" /> 
	<input type="hidden" id="<%=Constants.PASSTHRU_USERID_ID%>" name="<%=Constants.PASSTHRU_USERID_NAME%>" value="<%=request.getParameter(Constants.RQUSERID)%>" /> 
	<input type="hidden" id="<%=Constants.PASSTHRU_SESSIONID_ID%>"name="<%=Constants.PASSTHRU_SESSIONID_NAME%>" value="<%=request.getParameter(Constants.RQSESSIONID)%>" /> 
	<input type="hidden" id="<%=Constants.PASSTHRU_FOLDERID_ID%>" name="<%=Constants.PASSTHRU_FOLDERID_NAME%>" value="<%=request.getParameter(Constants.RQFOLDERID)%>" />
</form>


<style>
#advancedRegistrationDiv {
	display: block;
}

showAdvancedFilters {
	display: none;
}

#btnAdvancedRegistrationLink {
	margin-top: 10px;
}

#customLandingPageText {
	width: 800px;
	height: 50px;
	border: 1px solid #ddd;
}

#regLandingPageTextDiv {
	width: 980px
}

#defaultRegPageTxtDiv .reminderButton a:active, #defaultRegPageTxtDiv .reminderButton a:link,
	#defaultRegPageTxtDiv .reminderButton a:visited {
	background: #ededed url(../images/buttonbg_gray.png) left top repeat-x;
	border: 1px solid #ccc;
	color: #333;
	display: inline-block;
	margin: 0px;
	padding: 5px 8px 4px 4px;
	text-align: center;
	-webkit-border-radius: 3px;
	-moz-border-radius: 3px;
	border-radius: 3px;
	text-decoration: none;
	width: auto;
	font-weight: bold;
	color: #333;
	font-size: 12px;
	line-height: 20px
}

#defaultRegPageTxtDiv .reminderButton a:hover {
	color: #000;
	background-image: none;
	background-color: #fff
}

#defaultRegPageTxtDiv .reminderButton a img {
	vertical-align: top
}
.sectionBoxNoPadding {padding:0 20px 0 0!important}
</style>

<jsp:include page="/admin/footertop.jsp">
	<jsp:param name="pfi" value="<%=pfo.sCacheID%>" />
	<jsp:param name="ufi" value="<%=ufo.sCacheID%>" />
</jsp:include>
<jsp:include page="/js/froala/froala_include.jsp"></jsp:include>


	<link href="/js/chosen/chosen.min.css" media="screen" rel="stylesheet" type="text/css">
	<script type="text/javascript" src="/js/chosen/chosen.jquery.min.js"></script>
	<script type="text/javascript" src="/js/analytics.js"></script>

<script type="text/javascript">
	if (<%=analyticsActive%> === true) {
		//analyticsExclude(["param_eventCostCenter"]);
		analyticsInit('<%=sUserId%>', {
			eventID: '<%=iEventId%>',
			clientID: '<%=sClientId%>'
		});
	}
	

	$(document).ready(function() {		
		$.initdialog();
	//Location basd question code
		//$('#optinlist').chosen({ width: "95%"});
	
		$("#addEditCustRegDiv").on('click','#optin',function(){
			
			if(this.checked){
				$("#optinlist_span").show();
			}else{
				$("#optinlist_span").hide();
			}
		});
		//End of location based question code
		
		 //programmatically disable autocomplete on form fields
		 $("#pageWrapper").find("input[name], select[name]").attr("autocomplete","new-password");

		var customReg='<%=isCustomRegTxtUsed%>';
		var customQuestions='<%=numOfQuestions%>';
		
		if(customReg!='false')
		{
			if($('#btnShowOptionalContent span').hasClass("arrowClosed"))
			{
				$('#btnShowOptionalContent span').addClass("arrowOpened");
				$('#btnShowOptionalContent span').removeClass("arrowClosed");
			}
			$("#showOptionalContent").show();
		}else{
			
				$("#showOptionalContent").hide();
		}

		$("#btnShowOptionalContent > a").on('click', function () {
			$("#showOptionalContent").toggle('fast');
			if($('#btnShowOptionalContent span').hasClass("arrowOpened"))
			{
				$('#btnShowOptionalContent span').addClass("arrowClosed");
				$('#btnShowOptionalContent span').removeClass("arrowOpened");
			}
			else if($('#btnShowOptionalContent span').hasClass("arrowClosed"))
			{	
				$('#btnShowOptionalContent span').addClass("arrowOpened");
				$('#btnShowOptionalContent span').removeClass("arrowClosed");
			}
    	});

		if('<%=sRegCustomText.length()%>' != '0')
		{
			if($('#btnShowRegDefaultText span').hasClass("arrowClosed"))
			{
				$('#btnShowRegDefaultText span').addClass("arrowOpened");
				$('#btnShowRegDefaultText span').removeClass("arrowClosed");
			}
			$("#showRegDefaultText").show();
		}
		else{
			$("#showRegDefaultText").hide();
		}
		$("#btnShowRegDefaultText > a").on('click', function () {
			$("#showRegDefaultText").toggle('fast');
			if($('#btnShowRegDefaultText span').hasClass("arrowOpened"))
			{
				$('#btnShowRegDefaultText span').addClass("arrowClosed");
				$('#btnShowRegDefaultText span').removeClass("arrowOpened");
			}
			else if($('#btnShowRegDefaultText span').hasClass("arrowClosed"))
			{	
				$('#btnShowRegDefaultText span').addClass("arrowOpened");
				$('#btnShowRegDefaultText span').removeClass("arrowClosed");
			}
    	});
		$("#regdefaultText").fancybox({
			'width'				: 880,
			'height'			: 700,
	        'autoScale'     	: true,
	        'transitionIn'		: 'none',
			'transitionOut'		: 'none',
			'type'				: 'iframe',
			'hideOnOverlayClick': false ,
            'autoSize'			: false,
			'openSpeed'			: 0,
			'closeSpeed'        : 'fast',
			'closeClick'  		: false,
			helpers    : { 
				        'overlay' : {'closeClick': false}
			},
		    beforeShow : function() {
		        	$('.fancybox-overlay').css({
		        		'background-color' :'rgba(119, 119, 119, 0.7)'
		        	});
		        },
			iframe: { 
			    	preload: false 
			}
		});
		
		
		
		if('<%=tpSocialCode.length()%>' != '0')
		{
			if($('#btnShowSharingContent span').hasClass("arrowClosed"))
			{
				$('#btnShowSharingContent span').addClass("arrowOpened");
				$('#btnShowSharingContent span').removeClass("arrowClosed");
			}
			$("#showSharingContent").show();
		}
		else{
			$("#showSharingContent").hide();
		}
		$("#btnShowSharingContent > a").on('click', function () {
			$("#showSharingContent").toggle('fast');
			if($('#btnShowSharingContent span').hasClass("arrowOpened"))
			{
				$('#btnShowSharingContent span').addClass("arrowClosed");
				$('#btnShowSharingContent span').removeClass("arrowOpened");
			}
			else if($('#btnShowSharingContent span').hasClass("arrowClosed"))
			{	
				$('#btnShowSharingContent span').addClass("arrowOpened");
				$('#btnShowSharingContent span').removeClass("arrowClosed");
			}
    	});
		$("#shareSocial").fancybox({
			'width'				: 800,
			'height'			: 650,
	        'autoScale'     	: true,
	        'transitionIn'		: 'none',
			'transitionOut'		: 'none',
			'type'				: 'iframe',
			'hideOnOverlayClick': false ,
            'autoSize'			: false,
			'openSpeed'			: 0,
			'closeSpeed'        : 'fast',
			'closeClick'  		: false,
			helpers    : { 
				        'overlay' : {'closeClick': false}
			},
		    beforeShow : function() {
		        	$('.fancybox-overlay').css({
		        		'background-color' :'rgba(119, 119, 119, 0.7)'
		        	});
		        },
			iframe: { 
			    	preload: false 
			}
		});
		if('<%=sCusomRegFooter.length()%>' != '0')
		{
			if($('#btnShowRegFooter').hasClass("arrowClosed"))
			{
				$('#btnShowRegFooter span').addClass("arrowOpened");
				$('#btnShowRegFooter span').removeClass("arrowClosed");
			}
			$("#divRegFooter").show();
		}
		else{
			$("#divRegFooter").hide();
		}
		
		$("#btnShowRegFooter > a").on('click', function () {
			$("#divRegFooter").toggle('fast');
			if($('#btnShowRegFooter span').hasClass("arrowOpened"))
			{
				$('#btnShowRegFooter span').addClass("arrowClosed");
				$('#btnShowRegFooter span').removeClass("arrowOpened");
			}
			else if($('#btnShowRegFooter span').hasClass("arrowClosed"))
			{	
				$('#btnShowRegFooter span').addClass("arrowOpened");
				$('#btnShowRegFooter span').removeClass("arrowClosed");
			}
    	});
		
		$("#bioBuilder").fancybox({
			"width"				: 750,
			"height"			: 600,
			"autoScale" 		: false,
			"transitionIn" 		: "none",
			"transitionOut" 	: "none",
 			"type"				: "iframe", 
			"hideOnOverlayClick": false ,
            'autoSize'			: false,
			'openSpeed'			: 0,
			'closeSpeed'        : 'fast',
			'closeClick'  		: false,
			helpers    : { 
				        'overlay' : {'closeClick': false}
			},
		    beforeShow : function() {
		        	$('.fancybox-overlay').css({
		        		'background-color' :'rgba(119, 119, 119, 0.7)'
		        	});
		        },
			iframe: { 
			    	preload: false 
			}
		}); 
		
		$("#regfooter").fancybox({
			"width"				: 1015,
            "height"			: 550,
	        'autoScale'     	: true,
	        'transitionIn'		: 'none',
			'transitionOut'		: 'none',
			'type'				: 'iframe',
			'hideOnOverlayClick': false ,
            'autoSize'			: false,
			'openSpeed'			: 0,
			'closeSpeed'        : 'fast',
			'closeClick'  		: false,
			'fitToView'			: false,
			helpers    : { 
				        'overlay' : {'closeClick': false}
			},
		    beforeShow : function() {
		        	$('.fancybox-overlay').css({
		        		'background-color' :'rgba(119, 119, 119, 0.7)'
		        	});
		        },
			iframe: { 
			    	preload: false 
			}
		});
		
		$("#regfooter1").fancybox({
			"width"				: 1015,
            "height"			: 550,
	        'autoScale'     	: true,
	        'transitionIn'		: 'none',
			'transitionOut'		: 'none',
			'type'				: 'iframe',
			'hideOnOverlayClick': false ,
            'autoSize'			: false,
			'openSpeed'			: 0,
			'closeSpeed'        : 'fast',
			'closeClick'  		: false,
			'fitToView'			: false,
			helpers    : { 
				        'overlay' : {'closeClick': false}
			},
		    beforeShow : function() {
		        	$('.fancybox-overlay').css({
		        		'background-color' :'rgba(119, 119, 119, 0.7)'
		        	});
		        },
			iframe: { 
			    	preload: false 
			}
		});
		
		$("#RegFormFooter").fancybox({
			"width"				: 1015,
            "height"			: 550,
	        'autoScale'     	: true,
	        'transitionIn'		: 'none',
			'transitionOut'		: 'none',
			'href' 				: '/admin/managefooter.jsp?<%=sQueryString%>&fieldtype=RegFormFooter', 
			'type'				: 'iframe',
			'hideOnOverlayClick': false ,
            'autoSize'			: false,
			'openSpeed'			: 0,
			'closeSpeed'        : 'fast',
			'closeClick'  		: false,
			'fitToView'			: false,
			helpers    : { 
				        'overlay' : {'closeClick': false}
			},
		    beforeShow : function() {
		        	$('.fancybox-overlay').css({
		        		'background-color' :'rgba(119, 119, 119, 0.7)'
		        	});
		        },
			iframe: { 
			    	preload: false 
			}
		});
		
		$("#RegFormFooter1").fancybox({
			"width"				: 1015,
            "height"			: 550,
	        'autoScale'     	: true,
	        'transitionIn'		: 'none',
			'transitionOut'		: 'none',
			'href' 				: '/admin/froala_editor/footer_editor.jsp?<%=sQueryString%>&fieldtype=RegFormFooter', 
			'type'				: 'iframe',
			'hideOnOverlayClick': false ,
            'autoSize'			: false,
			'openSpeed'			: 0,
			'closeSpeed'        : 'fast',
			'closeClick'  		: false,
			'fitToView'			: false,
			helpers    : { 
				        'overlay' : {'closeClick': false}
			},
		    beforeShow : function() {
		        	$('.fancybox-overlay').css({
		        		'background-color' :'rgba(119, 119, 119, 0.7)'
		        	});
		        },
			iframe: { 
			    	preload: false 
			}
		});
		
 		$("#open_image_upload").fancybox({
			"width"				: 750,
			"height"			: 400,
			"autoScale" 		: false,
			"transitionIn" 		: "none",
			"transitionOut" 	: "none",
 			"type"				: "iframe", 
			"hideOnOverlayClick": false ,
            'autoSize'			: false,
			'openSpeed'			: 0,
			'closeSpeed'        : 'fast',
			'closeClick'  		: false,
			helpers    : { 
				        'overlay' : {'closeClick': false}
			},
		    beforeShow : function() {
		        	$('.fancybox-overlay').css({
		        		'background-color' :'rgba(119, 119, 119, 0.7)'
		        	});
		        },
			iframe: { 
			    	preload: false 
			}
		}); 
		
 		
 		
		if($("#default_reg_text").is(':checked'))
		{		
			$('#regLandingPageTextDiv').slideUp();	
			$('#defaultRegPageTxtDiv').slideDown();
			
		}
		
		if($("#custom_reg_text").is(':checked'))
		{		
	
			$('#defaultRegPageTxtDiv').slideUp();	
			$('#regLandingPageTextDiv').slideDown();	
			
		}
		
		$("#default_reg_text").on('click', function() {
			$('#regLandingPageTextDiv').slideUp();	
			$('#defaultRegPageTxtDiv').slideDown();
		});
		
		
		$("#custom_reg_text").on('click', function() {
			$('#defaultRegPageTxtDiv').slideUp();	
			$('#regLandingPageTextDiv').slideDown();	
			if(!$(this).prop('data-beenClicked')){
			
				$('#regLandingPageTextDiv .froala_editor').froalaEditor('TPDev.resetValueOnSlide', $(this));
			}
		});
		
		if($("#default_post_reg_text").is(':checked'))
		{		
			$('#postRegPageTextDiv').slideUp();	
			$('#postRegPageTxtDiv').slideDown();
			
		}
		
		if($("#custom_post_reg_text").is(':checked'))
		{		
	
			$('#postRegPageTxtDiv').slideUp();	
			$('#postRegPageTextDiv').slideDown();	
			
		}
		
		$("#default_post_reg_text").on('click', function() {
			$('#postRegPageTextDiv').slideUp();	
			$('#postRegPageTxtDiv').slideDown();
		});
		
		
		$("#custom_post_reg_text").on('click', function() {
			$('#postRegPageTxtDiv').slideUp();	
			$('#postRegPageTextDiv').slideDown();	
			if(!$(this).prop('data-beenClicked')){
			    $('postRegPageTextDiv .froala_editor').froalaEditor('TPDev.resetValueOnSlide', $(this));
			}
		});

		
		$('#addEditCustRegLink').on('click', function(event){
			showAddEditCustomField('<%=iEventId%>', '', 'ADD','-1');
			return false;
		});

		$('#closeEditCustRegLink').on('click',function(event){
			hideAddEditCustomField();
			return false;
		});

		$('#addEditCustRegDiv').on('click', '#closeAddCustRegLink', function(event){
			hideAddEditCustomField();
			return false;
		});

		
		$('#addEditCustRegDiv').on('click', '#addEditFieldTypeSelector', function(event){
			if($('#addEditFieldTypeSelector').val() == 'text' || $('#addEditFieldTypeSelector').val() == 'text-area' || $('#addEditFieldTypeSelector').val() == 'singlecheckbox'){
				$('#addEditAnswerTable').slideUp('fast');
			}else{
				$('#addEditAnswerTable').slideDown('fast');
			}
		});
 
		// helper functions
		function buildAnswerRow(idx, text){
			returnString =                "<tr>";
			returnString = returnString + "		<td>";
			returnString = returnString + "			<input  type=\"text\"  class =\"answerorderText\" id=\"param_customAnswer_order_"+idx+"_answerorder\" name=\"param_customAnswer_order_"+idx+"_answerorder\" svalue=\"\" size=\"3\" maxlength=\"3\" style=\"border:1px solid #CCCCCC;\"/>";
			returnString = returnString + "		</td>";
			returnString = returnString + "		<td>";
			returnString = returnString + "			<input type=\"hidden\" name=\"param_customAnswer_id_"+idx+"_answerId\" value=\"\"/>";
			returnString = returnString + "			<input id=\"param_customAnswer_data_"+idx+"_answerData\" type=\"text\" name=\"param_customAnswer_data_"+idx+"_answerData\" value=\"\" size=\"25\" style=\"border:1px solid #CCCCCC;\"/>";
			returnString = returnString + "		</td>";
			returnString = returnString + "		<td>";
			returnString = returnString + "			<input id=\"param_customAnswer"+idx+"_remove\" type=\"button\" class=\"buttonSmall\" value=\"Remove\" style=\"display:inline;\" onclick=\"removeAnswer(this);\"/>";
			returnString = returnString + "		</td>";
			returnString = returnString + "</tr>";

			return returnString;
		}

		 function findMaxOrder(){
			    var max=0;
			  
			    $('.answerorderText').each(function(){ 
			  		if(parseInt($(this).val(),10)>parseInt(max,10)){
			    		max = $(this).val();
			    	}
			    });
			   return max;
			}
		 	// end helper functions
		 	
		   $('#addEditCustRegDiv').on('keypress', '#addNewAnswerText', function (e) {
			   
			   if (e.keyCode==13) {
			   	$("#frmAddEditCustomField span.small-error-text").remove();
	            $(".error").removeClass("error");
				qCount = $('#addEditQuestionAnswerCount').val();
	            qPrevOrder= $('#addEditAnswerTable tbody>tr:last').prev('tr').find('input').val();
	           	var maxi = findMaxOrder();
	            maxi++;
	            qPrevOrder++
				qText = $('#addNewAnswerText').val();
				qText = $.trim(qText); // trim your answers
				if(qText != ""){
					$('#addAnswerRow').addClass("").before(buildAnswerRow(qCount, qText));
					$("#param_customAnswer_data_"+qCount+"_answerData").val(qText);
					$("#param_customAnswer_order_"+qCount+"_answerorder").val(maxi);
					qCount++;
					$('#addEditQuestionAnswerCount').val(qCount);
					$('#addNewAnswerText').val("");
					}else{
					$("#addEditAnswerTable").addClass("error").before("<span class=\"small-error-text\">Please reformat your answer<br></span>");
					}
			   }
			});  
		  
			
		$('#addEditCustRegDiv').on('click', '#addNewAnswerBtn', function(event){
            $("#frmAddEditCustomField span.small-error-text").remove();
            $(".error").removeClass("error");
            /*if( !isAlphaNumeric( $("#addNewAnswerText").val() ) )
            {
                $("#addEditAnswerTable").addClass("error").before("<span class=\"small-error-text\">Please do not use any special characters.<br></span>");
                return false;
            } */
			qCount = $('#addEditQuestionAnswerCount').val();
           
            qPrevOrder= $('#addEditAnswerTable tbody>tr:last').prev('tr').find('input').val();
           
           var maxi = findMaxOrder();
            //alert("MAX ORDER--"+maxi);
            maxi++;
            //alert("last row value--"+$("#addEditAnswerTable tbody tr:last td:first").html());
           
            qPrevOrder++
			qText = $('#addNewAnswerText').val();
			qText = $.trim(qText); // trim your answers
			if(qText != ""){
				$('#addAnswerRow').addClass("").before(buildAnswerRow(qCount, qText));
				$("#param_customAnswer_data_"+qCount+"_answerData").val(qText);
				/* if(qPrevOrder!='NaN' || qPrevOrder!=''){
				$("#param_customAnswer_order_"+qCount+"_answerorder").val(qPrevOrder);
				}else{
					$("#param_customAnswer_order_"+qCount+"_answerorder").val(qOrder);
					} */
				$("#param_customAnswer_order_"+qCount+"_answerorder").val(maxi);
				qCount++;
				$('#addEditQuestionAnswerCount').val(qCount);
				
				
				$('#addNewAnswerText').val("");
			}else{
				$("#addEditAnswerTable").addClass("error").before("<span class=\"small-error-text\">Please reformat your answer<br></span>");
			}
		});



		<%if(useSimpleLayout){%>
		$(".moreStdRegFieldsBtn").on('click', function() {
			if($(".moreStdRegFieldsBtn").html() == "More"){
				$(".moreStdRegFieldsBtn").html("&nbsp;");
				$(".moreStdRegFieldsBtn").addClass('showFewerReg');
				$("#adminRegFieldsTable .extraField").css('display','');
			}else{
				$(".moreStdRegFieldsBtn").html("More");
				$(".moreStdRegFieldsBtn").removeClass('showFewerReg');
				$("#adminRegFieldsTable .extraField").css('display','none');
			}
            return false;
		});
		if(eval(expandFields) && expandFields){
			$(".moreStdRegFieldsBtn").click();
		}
		<%}%>
		$('#hideRegistration').on('click', function(){
			if($('#hideRegistration').prop('checked') == true){
				$.alert("Attention, attention!","You have selected to hide the registration form for this event. No new users will be able to register for this event from the registration page. If you are using an advanced registration setup, please make sure to select all fields below that you would like to capture for reporting purposes.","icon_alert.png");
			}
		});
		$('#anonRegistrationOn').on('click', function(){
			
			if(isRegPassWordSet() == 'true')
			{
				$('#anonRegistrationOn').attr('checked','');
				$('#anonRegistrationOff').attr('checked','checked');
				$.alert("There is a conflict.","A password has been set in the event security page. The Anonymous Registration policy will not be applied for this event.","icon_nosign.png");
				$('#anonRegistrationOff').prop("checked", true);
			}
			else
			{
				hideAddEditCustomField();
				$('#frm_regMasterFields input[type="checkbox"]').attr('disabled','true');
				$('#frm_regMasterFields input[type="text"]').attr('disabled','true');
				$('#addEditCustRegLink').attr('disabled','true');
				$('#addEditCustRegLink.button').toggleClass('disabledButton');
				$('#frm_modifyCustReg input[type="checkbox"]').attr('disabled','true');
				$('#frm_modifyCustReg input[type="text"]').attr('disabled','true');
				$('#frm_modifyCustReg input[type="button"]').attr('disabled','true');
				$('#reorderCustomReg_btn').attr('disabled','true');
				$('#frm_regMasterFields #skiplanding').prop('disabled', null);
				$('#RegFormFooter').prop('disabled','true').addClass('disabledButton');
				$('#RegFormFooter1').prop('disabled','true').addClass('disabledButton');
			}
			
			$("#span_skiplanding").show("fast");
			$("#span_autologin").hide("fast");	
		});
		
		$('#anonRegistrationOff').on('click', function(){
			$('#frm_regMasterFields input[type="checkbox"]').prop('disabled', null);
			$('#frm_regMasterFields input[type="text"]').prop('disabled', null);
			$('#addEditCustRegLink').prop('disabled', null);
			$('#addEditCustRegLink').removeClass("disabledButton");
			$('#addEditCustRegLink').addClass("button");
			$('#RegFormFooter').prop('disabled',null).removeClass("disabledButton");
			$('#RegFormFooter1').prop('disabled',null).removeClass("disabledButton");
			enableCustomRegField();
			//$('#frm_modifyCustReg input[type="checkbox"]').removeAttr('disabled');
			$('#frm_modifyCustReg input[type="text"]').prop('disabled', null);
			$('#frm_modifyCustReg input[type="button"]').prop('disabled', null);
			$('#reorderCustomReg_btn').prop('disabled', null);
		    isCheckboxChecked('<%=Constants.REGISTRATION_MASTERFIELDID_FIRSTNAME%>');
		    isCheckboxChecked('<%=Constants.REGISTRATION_MASTERFIELDID_LASTNAME%>');
		    isCheckboxChecked('<%=Constants.REGISTRATION_MASTERFIELDID_ADDRESS1%>');
		    isCheckboxChecked('<%=Constants.REGISTRATION_MASTERFIELDID_ADDRESS2%>');
		    isCheckboxChecked('<%=Constants.REGISTRATION_MASTERFIELDID_CITY%>');
		    isCheckboxChecked('<%=Constants.REGISTRATION_MASTERFIELDID_COMPANY%>');
		    isCheckboxChecked('<%=Constants.REGISTRATION_MASTERFIELDID_COUNTRY%>');
		    isCheckboxChecked('<%=Constants.REGISTRATION_MASTERFIELDID_MOBILE%>');
		    isCheckboxChecked('<%=Constants.REGISTRATION_MASTERFIELDID_PHONE%>');
		    isCheckboxChecked('<%=Constants.REGISTRATION_MASTERFIELDID_POSTALCODE%>');
		    isCheckboxChecked('<%=Constants.REGISTRATION_MASTERFIELDID_STATE%>');
		    isCheckboxChecked('<%=Constants.REGISTRATION_MASTERFIELDID_TITLE%>');
		    isCheckboxChecked('<%=Constants.REGISTRATION_MASTERFIELDID_FAX%>');
		   	    
			disableRegField('<%=Constants.REGISTRATION_MASTERFIELDID_EMAIL%>',true);
			selectRegField('<%=Constants.REGISTRATION_MASTERFIELDID_EMAIL%>',true);
			checkConfirmEmail('<%=Constants.REGISTRATION_MASTERFIELDID_CONFIRMEMAIL%>');
			
			$("#span_skiplanding").hide("fast");
			$("#span_autologin").show("fast");
		});
		
		
		function isRegPassWordSet()
		{
			var varHasMasterPasswd = '<%=hasMasterPassword%>';
			return varHasMasterPasswd;
		}
		
		/**
		* This is used to enable disable Custom reg questions.
		* If a custom reg is required, then it the show check box has to be checked and disabled.
		* this is to prevent users from changing it to not show.
		**/
		function enableCustomRegField()
		{
			//first remove disabled attribute and then calcluate each individually
			$('#frm_modifyCustReg input[type="checkbox"]').prop('disabled', null);
			
			$('#frm_modifyCustReg input:checkbox').each(function(index) { 
			    var chkBoxId = $(this).prop('chkId'); // we added extra parameter to hold only the question id.
			    var chkBoxName = $(this).prop('id'); 
			    if(chkBoxName.indexOf("required") > 1)
			    {   // if id contains the text "required" then 
			    	if( $(this).is(':checked'))
			    	{
			    		$('#'+chkBoxId+'_enabled').prop('checked','checked');
			    		$('#'+chkBoxId+'_enabled').prop('disabled','disabled');
			    	}
			    }
			  });
		}

		/*
		* This method is used to enable and disable email Field.
		* In case of a non-anonymous reg, before Submitting a form,
		* we first enable it and then disable it once again.
		* This will prevent the field from looking enabled at any point in time.
		*/
		function disableRegField(fieldID,action)
		{
			if(action == true)
			{
				$('#'+fieldID+'_enabled').prop('disabled','true');
				$('#'+fieldID+'_required').prop('disabled','true');
			}
			else
			{
				$('#'+fieldID+'_enabled').prop('disabled', null);
				$('#'+fieldID+'_required').prop('disabled', null);
			}

		}
		
		function checkConfirmEmail(fieldID){
			var checked = $('#'+fieldID+'_enabled').prop('checked');
			$('#'+fieldID+'_required').prop('checked',true);
			if(checked!=true){
				$('#'+fieldID+'_required').prop('disabled',false);
				$('#'+fieldID+'_required').prop('checked', null);
			}
		}

        function isAlphaNumericNoSpaces(sourceText)
        {
            var isAlphaNumericNoSpacePresent = false;
            if(sourceText!=undefined && sourceText!='')
            {
                var alphaNumericNoSpacePattern =new RegExp(/^([a-zA-Z0-9_-]+)$/);
                isAlphaNumericNoSpacePresent = alphaNumericNoSpacePattern.test(sourceText);
            }


            return isAlphaNumericNoSpacePresent;
        }

        function isAlphaNumeric(sourceText)
        {
            var isAlphaNumericPresent = false;
            if(sourceText!=undefined && sourceText!='')
            {
                var alphaNumericPattern =new RegExp(/^([a-zA-Z0-9 _-]+)$/);
                isAlphaNumericPresent = alphaNumericPattern.test(sourceText);
            }
            return isAlphaNumericPresent;
        }
	
        function fixSpecialWhitespaces(text) {
        	return text.replace(/[\u2000|\u2001|\u2002|\u2003|\u2004|\u2005|\u2006|\u2007|\u2008|\u2009|\u200A|\u200B|\u00A0|\u2060|\u3000|\uFEFF]/g, '\u0020');
        }
        
        function removeDisallowedCharacters(text) {
        	return text.replace(/[^a-zA-Z0-9\u0020_-]/g, '');
        }
        
		/**
		* This method is used to check or uncheck the reg fields automatically
		* Pass action as true to check a reg field (field ID)
		* Pass false to uncheck a reg field.
		*/
		function selectRegField(fieldID,action){
			if(action == true){
				$('#'+fieldID+'_enabled').prop('checked','true');
				$('#'+fieldID+'_required').prop('checked','true');
			}else{
				$('#'+fieldID+'_enabled').prop('checked', null);
				$('#'+fieldID+'_required').prop('checked', null);
			}
		}
		
		$('#addEditCustRegDiv').on('click', '#addEditCustRegSaveBtn',function(){ 
            $("#frmAddEditCustomField span.small-error-text").remove();
            $(".error").removeClass("error");
            var columnTitle = removeDisallowedCharacters(fixSpecialWhitespaces($("#param_fieldAbstract").val()));
            if (columnTitle != $("#param_fieldAbstract").val()) {//(!isAlphaNumericNoSpaces(columnTitle)) {
            	$("#param_fieldAbstract").val(columnTitle);
            	$("#param_fieldAbstract").addClass("error").before("<span class=\"small-error-text\">Special characters have been removed.<br></span>");
            	$.alert("Hmm. Something isn't right. ","Please use only alphanumeric characters in the Reporting Column Title. Do not use any special characters.","icon_alert.png");
            	return false;
            }
         
			$("#adding").val("add");
			var answers = $("#addEditQuestionAnswerCount").val();
			var opt = $("#addEditFieldTypeSelector").val();
			if (opt != "text" && opt != "text-area" && opt!="singlecheckbox") {
				if (answers < 1) {
					$.alert("Hmm. Something isn't right. ","Please make sure you enter at least one answer!","icon_alert.png");
					return false;
				} else {
					for (var index = 0; index < answers; index++) {
						if ($('#param_customAnswer_data_' + index + '_answerData').val() && $('#param_customAnswer_data_' + index + '_answerData').val().trim() == '') {
							$.alert("Hmm. Something isn't right. ", "Please make sure you enter a value for each answer!", "icon_alert.png");
							return false;
						}
					}
				}
			}
			if($("#param_fieldAbstract").val().length>250){
				$.alert("Hmm. Something isn't right. ","Please make sure you enter less than 250 characters in the Report Column Title!","icon_alert.png");
				return false;
			}
			
			var dataString = $("#frmAddEditCustomField").serialize();
			$.ajax({ type: "POST",
		        url: "proc_addEditRegFields.jsp",
		        data: dataString,
		        dataType: "json",
		        success: function(jsonResult) {
					jsonResult = jsonResult[0];

		            $("span.small-error-text").remove();
		            $(".error").removeClass("error");
		            if (!jsonResult.success) {
		            	var frmError = "";
	                    var frmName = "frmAddEditCustomField";
	                    var curError="";
	                    var curElement = "";
	                  
	                    for (i=0; i<jsonResult.errors.length; i++) {
	                      	curError = jsonResult.errors[i];
	                       	curElement = curError.element[0];
	                       
	                       	if(curElement!=frmName && curElement!="__ERROR__"){
	                       		$("#" + curElement).addClass("error").before("<span class=\"small-error-text\">" + curError.message + "<br></span>");
	                       		
	                       	}else{
	                       		frmError = frmError + curError.message + "<br>";
	                       		
	                       	} 
	                       
	                    }
	                    if(frmError!=""){
	                        $.alert("Hmm. Something isn't right. ",frmError,"icon_alert.png");
	                    }
	                    return false;
	                } else {
	                   hideAddEditCustomField();
		               showListCustomField();
		               return false;
					}
		            return false;
		        },
		        error: function(xmlHttpRequest, status, errorThrown){
		        	$.alert("Oops! Something went wrong.","There was an error processing your request. Please try again later.","icon_error.png");
		        	return false;
		        }
		    });
		    return false;
		});
		
		$('#reorderCustomReg_btn').on('click',function(event){
			$('#submitModifyCustReg').submit();
		});
		
		$('#frm_regMasterFields').submit(function(){

			showProcessing();
			// Enable the Email Fields before submitting.
			// This will allow the field to get serialized();
			// Disbaled fields are not serialized.
			if(!$('#anonRegistrationOn').is(':checked')){
				disableRegField('<%=Constants.REGISTRATION_MASTERFIELDID_EMAIL%>',false);
			}
			
			
			var dataString = $("#frm_regMasterFields").serialize();
			
			// The Custom Reg Question info such as "require/delete/question order" come under
			// a different form frm_regMasterFields. However when user clicks on "Save and Continue"
			// all data has to be saved. Therefore we serialize the custom reg form to get custom
			// reg data. We then include the custom reg data to the reguslar std questions.
			// In processing page, custom reg data will also be saved.
			var custDataString = $("#frm_modifyCustReg").serialize();	
 			var regLandingSerialize = $("#frm_regLanding :not(.froala_editor)").serialize();
 			var froalaSerialize = '';
			$(".froala_editor").each(function(){
				froalaSerialize += '&' + $(this).froalaEditor('TPDev.getAjaxHTML',false,false);
			});
			
			// console.log('froalaSerialize String: ', froalaSerialize);
 			var regLandingTxt =  regLandingSerialize + froalaSerialize;
			var custLandingTxt = $("#frm_custLanding").serialize();
			dataString = dataString + '&' +  custDataString + '&' + regLandingTxt +  '&' + custLandingTxt;
			// diabling the email field once again. So that it looks disabled to the human eye.
			if(!$('#anonRegistrationOn').is(':checked')){
				disableRegField('<%=Constants.REGISTRATION_MASTERFIELDID_EMAIL%>',true);
			}

			$.ajax({ type: "POST",
		        url: "proc_regFields.jsp",
		        data: dataString,
		        dataType: "json",
		        success: function(jsonResult) {
					jsonResult = jsonResult[0];

		            $("span.small-error-text").remove();
		            $(".error").removeClass("error");

		            if (!jsonResult.success) {
		            	var frmError = "";
	                    var frmName = "frm_regMasterFields";
	                    var curError="";
	                    var curElement = "";
	                    for (i=0; i<jsonResult.errors.length; i++) {
	                      	curError = jsonResult.errors[i];
	                       	curElement = curError.element[0];
	                       	if(curElement!=frmName && curElement!="__ERROR__"){
	                       		$("#" + curElement).addClass("error").before("<span class=\"small-error-text\">" + curError.message + "<br></span>");
	                       	}else{
	                       		frmError = frmError + curError.message + "<br>";
	                       	}                        	
	                    }
	                    if(frmError!=""){
	                       $.alert("Hmm. Something isn't right.",frmError,"icon_alert.png");
	                    }
	                    hideProcessing();
	                    return false;
		           } else {
		             	$("#<%=Constants.PASSTHRU_FORM_ID%> #<%=Constants.PASSTHRU_USERID_ID%>").val(jsonResult.<%=Constants.JSON_PASSTHRU_OBJECT_ID%>.<%=Constants.PASSTHRU_USERID_ID%>);
						$("#<%=Constants.PASSTHRU_FORM_ID%> #<%=Constants.PASSTHRU_SESSIONID_ID%>").val(jsonResult.<%=Constants.JSON_PASSTHRU_OBJECT_ID%>.<%=Constants.PASSTHRU_SESSIONID_ID%>);
						$("#<%=Constants.PASSTHRU_FORM_ID%> #<%=Constants.PASSTHRU_EVENTID_ID%>").val(jsonResult.<%=Constants.JSON_PASSTHRU_OBJECT_ID%>.<%=Constants.PASSTHRU_EVENTID_ID%>);
						
    					var sMsg1 = "Registration settings saved successfully!";
				        if(jsonResult.errors.length>0){
				        	aXssErrors = jsonResult.errors;
				        	var sMsg2 = "Your changes have been saved however some items were automatically corrected or removed for security purposes. Please <a href='#' onclick='showerrors();return false;'>click here</a> to view these items.";
					       	var objButton = {"Ok":function(){$("#<%=Constants.PASSTHRU_FORM_ID%>").submit();}};	
					       	$.alert(sMsg1,sMsg2,"icon_alert.png",objButton,""); 
				        }else{
				        	$.successDialog(sMsg1 ,"","icon_check.png",true);
							setTimeout('$("#<%=Constants.PASSTHRU_FORM_ID%>").submit();',2000);
				        }
						return false;
					}
		        },
		        error: function(xmlHttpRequest, status, errorThrown){
		        	$.alert("Oops! Something went wrong.","There was an error processing your request. Please try again later.","icon_error.png");
		        	hideProcessing();
		        	return false;

		        }
		    });
		    return false;
		});
		
		function confirmSave(txt) {
			var objButton = {"No": function(){$("#alertDialog").dialog("close");},"Yes": function(){$('#frm_regMasterFields').submit();$("#alertDialog").dialog("option","buttons",{"Processing...":function(){return;}})}};
			$.confirm("Are you sure you want to proceed?",txt,objButton,"");
		}
		
		$('#saveAndContinueBtn').on('click', function(){
			$('#frm_regMasterFields input[type="text"]').each(function(){
		        this.value = this.value.replace(/\\/g, '');
		    });
			if($('#anonRegistrationOn').prop('checked') == true){
				confirmSave("You have selected an Anonymous Registration policy. If you continue, all existing registration questions and customizations will be removed.");
				return;
			}
			<%if(account.can(Perms.User.MANAGECUSTOMREG)){%>
			if($('#param_fieldDisplay').val()!="" || $('#param_fieldAbstract').val()!=""){
				confirmSave("You have not saved your custom question.");
				return;
			}
			<%}%>
			if($("#bHasLocationQuestion").val() =='true' && $("#b0a6b7f0f67130ce0ffca207828d648ef4e8ed95_enabled").prop('checked')==false){
				$.alert("Hmm. Something isn't right.","One or more of your custom questions are only shown to users based on their location. Please disable the location requirement from all questions before removing the \"Country\" field from your registration form.","icon_alert.png");
				return;
			}
			
			// Disable new reg for event when reg data is saved
			disableNewReg();

			$('#frm_regMasterFields').submit();
			return false;
		});

		//TODO: remove when confirm is no longer required
		$('#regSelectionBtn').on('click', function(){
		    confirmRegSelection("You have selected new registration.");
		});

		//TODO: remove when confirm is no longer required
		function confirmRegSelection(txt) {

			var objButton = {"No": function(){$("#alertDialog").dialog("close");},
			         		 "Yes": function(){switchToNewRegView();}};
			
			$.confirm("Are you sure you want to proceed?", txt, objButton, "");
		}

		function disableNewReg() {

			<%if (!currentEvent.isNewRegistrationEnabled()) {%>
				// Already disabled
				console.log("New Reg already disabled.");

				return;
			<%}%>

			const data = {
				<%=Constants.RQEVENTID%> : "<%=request.getParameter(Constants.RQEVENTID)%>",
				<%=Constants.RQUSERID%> : "<%=request.getParameter(Constants.RQUSERID)%>",
				<%=Constants.RQSESSIONID%> : "<%=request.getParameter(Constants.RQSESSIONID)%>",
				enablenewreg : "false"
			}

		    $.post( "proc_regpageselector.jsp", data, function(result) {
			   console.log("New Reg disabled; result=" + JSON.stringify(result));
			})
			  .fail(function(xhr, textStatus, errorThrown) {
				//TODO: notify user of error 
			    alert( "registration.jsp: error;" + " textStatus=" + xhr.status + " errorThrown=" + xhr.statustext);
			  });
		}

		<%if(isAnonRegEnabled){%>
			$('#anonRegistrationOn').click();
		<%}else{%>
			$('#anonRegistrationOff').click();
		<%}%>
		
		// declare Froala toolbar items		
		var toolbarButtonsArr = ['bold', 'italic', 'underline', 'subscript', 'superscript', 'fontFamily', 'fontSize','color','|', 
		             'paragraphFormat','align','formatOL','formatUL','outdent','indent','removeFormat','|',
		             'insertHR','insertLink','image','insertVideo','bio_builder','|',
		             'undo','redo','html'];
		// invoke initFroala from froala_include.jsp	
	 	initFroala($('.froala_editor:not(#regSegmentBuildDiv .froala_editor, #postRegSegmentListDiv .froala_editor)'),{'width':'980','height':'450','toolbarButtons':toolbarButtonsArr,'responsiveBioBuilder':true},'<%=iEventId%>','<%=sUserId%>','<%=sSessionId%>');
	 	// target all .froala_editor and instantiate using .froalaEditor()
			$('.froala_editor:not(#frm_segmentBuilder .froala_editor)').froalaEditor('TPDev.addStyleSheet','/viewer/style/common.css'); 

				
		//Check here if CE is enabled , If it is than show message that firstname lastname is always required
				
		$.ajax({
			type: "POST",
			url: "proc_surveysummary.jsp?task=has_ce",
			data: dataString,
			dataType: "json",
			success: function(data) {
				if(data.has_cert=="1") {
					$("#ce_required_fields").show();
				} else {
					$("#ce_required_fields").hide();
				}
			}
			//error: displaySurveyError
		});
			
		// Portal Post Reg Save Text
<%
	if(bIsPortal){}
%>
		
	});//End of Document.ready


	function switchToNewRegView() {
		$("#<%=Constants.PASSTHRU_FORM_ID%>").attr("action", "<%=Constants.NEW_ADMIN_REGISTRATION_PAGE%>");
        $("#<%=Constants.PASSTHRU_FORM_ID%>").submit();
	}

	function removeAnswer(element){
		//$('#addEditAnswerTable').remove($('#x').parent('tr').remove());
		$(element).parent('td').parent('tr').empty().remove();
		qCount = $('#addEditQuestionAnswerCount').val();
		qCount--;
		//$('#addEditQuestionAnswerCount').val(qCount); 
	}
	
	function showListCustomField(){
		$.ajax({
			  url: 'frag_listCustomReg.jsp',
			  data: {'ei':'<%=iEventId%>','ui':'<%=sUserId%>'},
			  cache: false,
			  success: function(data) {
					$('#listCustRegDiv').html(data);
					$('#listCustRegDiv').slideDown('fast');
			  }
			});
		return false;
	}
	
	function showAddEditCustomField(eventId, fieldId, action,idx){
		$.get('frag_addEditCustomReg.jsp?<%=sQueryString%>', {action: action,sFieldId: fieldId}, function(data){
				$('#addEditCustRegDiv').html(data);
				$('#optinlist').chosen({ width: "95%"});
				if(action=="EDIT"){
					$("#editQuestion").val("edit");
					$("#editQuestion_idx").val(idx);
					$.alert("Attention, attention","Editing a custom registration question can potentially affect reporting. Any current user data will be displayed with their previous answers.","icon_alert.png");
				}
						   
				$('#closeEditCustRegLink').on('click', function(event){
					hideAddEditCustomField();
					return false;
				});

				$('#addEditCustRegDiv').slideDown('fast');
				
		});
		return false;
	}
	
	function deleteCustomFieldAlertMsg(fieldId,idx){
		
		var objButton = {"Cancel": function(){$("#alertDialog").dialog("close");},"Delete":function(){deleteCustomField(fieldId,idx);$("#alertDialog").dialog("close");}};
		$.confirm("Deleting a custom registration question will remove all viewer responses from reporting."," ",objButton,"");
	}
	function submitModifyCustReg(){
		var dataString = $("#frm_modifyCustReg").serialize();
		$.ajax({ type: "POST",
	        url: "proc_modCustReg.jsp",
	        data: dataString,
	        dataType: "json",
	        success: function(jsonResult) {
				jsonResult = jsonResult[0];

	            $("span.small-error-text").remove();
	            $(".error").removeClass("error");

	            if (!jsonResult.success) {
	            	var frmError = "";
                    var frmName = "frm_modifyCustReg";
                    var curError="";
                    var curElement = "";
                    for (i=0; i<jsonResult.errors.length; i++) {
                      	curError = jsonResult.errors[i];
                       	curElement = curError.element[0];
                       	if(curElement!=frmName && curElement!="__ERROR__"){
                       		$("#" + curElement).addClass("error").before("<span class=\"small-error-text\">" + curError.message + "<br></span>");
                       	}else{
                       		frmError = frmError + curError.message + "<br>";
                       	}                        	
                    }
                    if(frmError!=""){
                       $.alert("Hmm. Something isn't right.",frmError,"icon_alert.png");
                    }
                    return false;
	           } else {
	        		showListCustomField();
	                return false;

				}
	        },
	        error: function(xmlHttpRequest, status, errorThrown){
	        	$.alert("Hmm. Something isn't right.","Please finish adding or cancelling the custom registration question and then save.","icon_alert.png");
		         return false;

	        }
	    });
	    return false;
	}
	
	function hideAddEditCustomField(){
		$('#param_fieldDisplay').val('');
		$('#param_fieldAbstract').val('');
		$('#addEditCustRegDiv').slideUp('fast');
		return false;
	}
	
	function deleteCustomField(fieldId,idx){
		$('#frm_modifyCustReg #action').val('DELETE');
		$('#frm_modifyCustReg #deleteFieldId').val(fieldId);
		if(idx>-1 && $("#editQuestion_idx").val()==idx){
			hideAddEditCustomField();
		}
		
		
		submitModifyCustReg();
		return false;
	}
	
	function selectEnableCheckbox(fieldId) {	
		var checked = $('#'+fieldId+'_required').prop('checked');
		$('#'+fieldId+'_enabled').prop('checked',true);		
		$('#'+fieldId+'_enabled').prop('disabled',true);
		if(checked!=true){		
			var checkField = '<%=Constants.REGISTRATION_MASTERFIELDID_CONFIRMEMAIL%>';
			if(checkField==fieldId){	
				$('#'+fieldId+'_enabled').prop('disabled',false);  
				$('#'+fieldId+'_enabled').removeAttr('checked'); 
			}else{
				 $('#'+fieldId+'_enabled').prop('disabled',false);  
			}
		}
	}
	
	function selectEnableShowCheckbox(fieldId){
		var checkField = '<%=Constants.REGISTRATION_MASTERFIELDID_CONFIRMEMAIL%>';
		if(checkField==fieldId){
			
			var checked = $('#'+fieldId+'_enabled').prop('checked');
			$('#'+fieldId+'_required').prop('checked',true);		
			/* $('#'+fieldId+'_required').prop('disabled',true); */
			if(checked!=true){
				/* $('#'+fieldId+'_required').prop('disabled',false);  */
				$('#'+fieldId+'_required').removeAttr('checked'); 
			}
		}
	}
			
	function isCheckboxChecked(fieldId){
		
		var checked = $('#'+fieldId+'_required').prop('checked');
		$('#'+fieldId+'_enabled').prop('disabled',true);
		if(checked!=true){
			$('#'+fieldId+'_enabled').prop('disabled',false);
		}
	}
	

	
	 function callbackSuccessAlert(header,text){
		$.successDialog(header,text,"icon_check.png",true);
		setTimeout('$("#tinyAlertDialog").dialog("close");',2000);
		 //Refresh Resent Button as there might be some new links sent out
	 }

	 function callbackErrorAlert(frmError){
		 $.alert("Hmm. Something isn't right. ",frmError,"icon_alert.png");
	 }
	 
	 function showProcessing(){
		$("#savecancelbtn_div").hide();
		$("#processing").show();
	 }
	 function hideProcessing(){
		$("#savecancelbtn_div").show();
		$("#processing").hide();
	}
	
	<%if(showCancelButton){%>
		$('#cancelBtn').on('click', function(){
			$("#<%=Constants.PASSTHRU_FORM_ID%> #<%=Constants.PASSTHRU_USERID_ID%>").val('<%=ufo.sUserID%>');
			$("#<%=Constants.PASSTHRU_FORM_ID%> #<%=Constants.PASSTHRU_SESSIONID_ID%>").val('<%=ufo.sSessionID%>');
			$("#<%=Constants.PASSTHRU_FORM_ID%> #<%=Constants.PASSTHRU_EVENTID_ID%>").val('<%=pfo.sEventID%>');
			$("#<%=Constants.PASSTHRU_FORM_ID%> #<%=Constants.PASSTHRU_FOLDERID_ID%>").val('<%=ufo.sFolderID%>');
			$("#<%=Constants.PASSTHRU_FORM_ID%>").submit();
		});
	<%}%>
	var aXssErrors = [];
	function showerrors() {
		var param = "height=400,width=500,toolbars=no,statusbar=no,resizable=yes,scrollbars,menubar=no";
		newwindow = window.open("xsserrordisp.html", "cleanupwin", param); //changed for new popup detection
	}
</script>
<%
	} /* end if(currentEvent != null) - line 166?? */
%>
<%
	} catch (Exception e) {
		response.sendRedirect(ErrorHandler.handle(e, request));
		//out.print(e.getMessage());
		//out.print(ErrorHandler.getStackTrace(e));
	}
%>
<jsp:include page="footerbottom.jsp">
	<jsp:param name="pfi" value="<%=pfo.sCacheID%>" />
	<jsp:param name="ufi" value="<%=ufo.sCacheID%>" />
</jsp:include>