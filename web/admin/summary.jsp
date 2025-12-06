<%@ page import="java.util.*"%>
<%@ page import="org.apache.commons.text.StringEscapeUtils"%>
<%@ page import="org.json.*"%>
<%@ page import="tcorej.*"%>
<%@ page import="tcorej.email.EmailTools"%>
<%@ page import="tcorej.bean.*"%>
<%@ page import="tcorej.bean.event.redirect.*"%>
<%@ page import="tcorej.email.FollowUpEmail" %>
<%@ page import="tcorej.mlt.MP4ArchiveTools" %>
<%@ page import="tcorej.mlt.DownloadConstants" %>
<%@ page import="tcorej.reports.DataMining2" %>
<%@ page import="tcorej.telephony.bridge.*" %>
<%@ page import="tcorej.api.*" %>
<%@ page import="tcorej.job.JobQueue" %>
<%@ page import="tcorej.filedistributor.FileDistributorQueue" %>
<%@ page import="tcorej.speechtotext.*"%>
<%@ page import="tcorej.util.FlatFileIOUtils" %>
<%@ page import="tcorej.videocms.*"%>
<%@ include file="/include/globalinclude.jsp"%>

<%!
final Logger logger = Logger.getInstance();
%>

<%
	//configuration
Configurator conf = Configurator.getInstance(Constants.ConfigFile.GLOBAL);
boolean analyticsActive = StringTools.n2b(conf.get(Constants.ANALYTICS_ACTIVE_CONFIG));
String sLivestudioFolder = conf.get("livestudiofolder");
String ADMIN_DB = conf.get(Constants.DB_ADMINDB);
String VIEWER_DB = conf.get(Constants.DB_VIEWERDB);
String flatfileVersion = conf.get(Constants.FLATFILE_VERSION_CONFIG, FlatFileIOUtils.DEFAULT_VERSION);
// generate pfo and ufo
PFO pfo = new PFO(request);
UFO ufo = new UFO(request);
//yellowbox_250 -- event content
String sQueryString = Constants.EMPTY;
String sEventId = Constants.EMPTY;
String sUserId = Constants.EMPTY;
String sResourceName = Constants.EMPTY;
String sResourceAddress = Constants.EMPTY;
String sEncoderBiteRate = Constants.EMPTY;
String sVCUBiteRate = Constants.EMPTY;
String sViewerBaseURL = Constants.EMPTY;
String sViewerDomain = Constants.EMPTY;
String sAdminDomain = Constants.EMPTY;
String sRegionName = Constants.EMPTY;
String sEmailTypeText = "Viewer emails disabled.";
String tscInfo = Constants.EMPTY;
boolean bRegConfEmail = false;
boolean bReminderEmail = false;
String sSecurityTypeText = Constants.EMPTY;
boolean bReferrerCheck = false;
boolean bSecurityOptions = false;
boolean bEventPassword = false;
String sSurveyModule = Constants.EMPTY;
boolean hasLiveGuest =false;
boolean hasODGuest =false;
boolean hasReportGuest = false;
String sMode=Constants.EMPTY;
String admindb = conf.get(Constants.DB_ADMINDB);
AdminUser account = null;
int documentCount;
ArrayList<HashMap<String,String>> headshotList = new ArrayList<HashMap<String,String>>();
String registrationPage =  Constants.EMPTY;

boolean isWebinar = false;
boolean isFolderSettingEvent = false;
boolean isProcessing = false;
boolean isErrorUploading = false;
boolean isFlashMulticast = false;
boolean isWindowsMulticast = false;
boolean isWindowsEnabled = false;
boolean isSecureStream = false;
boolean isMP4ArchiveUpToDate=false;


String sDefaultNumber = Constants.EMPTY;
String sNumber = Constants.EMPTY;
boolean bIsPortal = false; 
boolean isBroadcasting = false;

//Event creation info
String sEventCreationInfo = Constants.EMPTY;
String sCreator_username = Constants.EMPTY;
String sCreator_email = Constants.EMPTY;
String sEvent_isStandardCopy = Constants.EMPTY;
String sEvent_isTemplateCopy = Constants.EMPTY;
String sEvent_copiedFrom = Constants.EMPTY;
String sEvent_createDate = Constants.EMPTY;
long lEventDuration =  0;
String eventTypeLabel = "Event";
String sStartDateDisplay = Constants.EMPTY;
String sEvent_expiryDate = Constants.EMPTY;


//look up event
int iEventId = pfo.iEventID;
boolean bIsTradeShowLite = false;
try {
	account = AdminUser.getInstance(ufo.sUserID);
	
	pfo.sSubNavType = "summary";
	pfo.sSubNavCrumbs = "";
	pfo.secure();
	pfo.setTitle("Summary");
	
	// page revision
	pfo.sPageRev = "$Id$";
	
	PageTools.cachePutPageFrag(pfo.sCacheID, pfo);
	PageTools.cachePutUserFrag(ufo.sCacheID, ufo);

	
	Event currentEvent = null;
	
	if(iEventId != -1 && Event.exists(iEventId)){
		if(!account.canViewEvent(iEventId)){
			throw new Exception(Constants.ExceptionTags.ENOUSERAUTH.display_code());
		}
		currentEvent = Event.getInstance(iEventId);
		bIsPortal = currentEvent.isPortal();
		bIsTradeShowLite = currentEvent.isTradeShowLite();
	}else{
		throw new Exception(Constants.ExceptionTags.EEVENTNOTEXIST.display_code());
	}
    
	String sClientId = currentEvent.getProperty(EventProps.fk_clientid);
	boolean isCloneProcessing = StringTools.n2b(currentEvent.getStatus(EventStatus.is_processing_clone).value);
	
	lEventDuration = currentEvent.getEventDuration();
	boolean sDeckStatus= EventTools.getSlideDeckStatus(iEventId);
	boolean hasJobID= false;
	boolean hasJobempty = false;
	String sjobresult = Constants.EMPTY;
	ArrayList<HashMap<String,String>> Jobresult = new ArrayList<HashMap<String,String>>();
	Jobresult =EventTools.getJobResultStatus(iEventId);
	for(HashMap<String,String> hmjobresult: Jobresult){
		sjobresult = hmjobresult.get("fk_jobresult");
		if(!StringTools.isNullOrEmpty(sjobresult)){
			hasJobID = true; 
		}
		else{
			hasJobempty = true;
		}
		}
	
	if((sDeckStatus && (hasJobempty && hasJobID)) || (sDeckStatus && hasJobempty)){
		isProcessing = true;
	}
	if(sDeckStatus && (hasJobID && !hasJobempty)){
		isErrorUploading = true;
	}
	//String sJobresult = EventTools.getJobResultStatus(iEventId);
	//System.out.println("JOB RESULT--IN THE SUMMARY PAGE --JOB RESULT SHOWS---"+sJobresult);
	
	sEventId = pfo.sEventID;
	sUserId = ufo.sUserID;
	sQueryString = pfo.toQueryString() + "&" + ufo.toQueryString();

	JSONObject eventJson = new JSONObject();
	if(currentEvent!=null){
		currentEvent.addScheduleData();
		currentEvent.loadEventDateDisplay();
		eventJson = currentEvent.json();
	}
	
	sMode = currentEvent.getStatus(EventStatus.mode).getValue();
	
	if(currentEvent.getProperty(EventProps.is_webinar).equalsIgnoreCase("true")){
		isWebinar = true;
		
	}
	
	isFolderSettingEvent = currentEvent.isFolderSettingEvent();
	
	String source = StringTools.n2s(request.getParameter("source"));
	
	//If Webinar SUPERUSER without source cant see header
	//If webinar REGULAR USER with or without source cant see header
	boolean isWebinarAdmin = false;
	boolean showAdminOptions = true;
	showAdminOptions = Webinar.showAdminOptions(isWebinar,source,account);
	if(isWebinar || !showAdminOptions){		
		if(!source.equals(Constants.EMPTY)){
			 pfo.sMainNavType = "secureonly";	 
			 sQueryString += "&source=" + source;	
		}else{
			 if(account.can(Perms.User.SUPERUSER)){
				 pfo.sMainNavType = "edit";	 
			 }else{
				 pfo.sMainNavType = "secureonly";
			 }
		}
		isWebinarAdmin = AdminUser.isWebinarAdmin(isWebinar,account.sUsername);
	}else{
		pfo.sMainNavType = "edit";
	}
	
	
	boolean bIsSimLive = currentEvent.getProperty(EventProps.isSimLive).equals("true");
	
	
	String tzname = currentEvent.getProperty(EventProps.timezone_id);
	//Look up event creation info
	sEventCreationInfo = currentEvent.getProperty(EventProps.creation_info);
	JSONObject creationInfoJSON = null;
    if(!Constants.EMPTY.equals(sEventCreationInfo)){
    	creationInfoJSON = new JSONObject(sEventCreationInfo);
    	sCreator_username = creationInfoJSON.optString("admin_user");
    	sCreator_email = creationInfoJSON.optString("admin_email");
    	sEvent_isStandardCopy = creationInfoJSON.optString("is_standard_copy");
    	sEvent_isTemplateCopy = creationInfoJSON.optString("is_template_copy");
    	sEvent_copiedFrom = creationInfoJSON.optString("copied_from");
    	sEvent_createDate = DateTools.getLocalDateFromGMT(currentEvent.getProperty(EventProps.createdate), Constants.MYSQLTIMESTAMP_PATTERN, tzname, Constants.PRETTYDATE_PATTERN_5);
    	String sDisplayTZName = DateTools.getTimeZoneShortName(tzname, sEvent_createDate, Constants.PRETTYDATE_PATTERN_5);
    	sEvent_createDate = sEvent_createDate + " " + sDisplayTZName;
    	
    	if(!StringTools.isNullOrEmpty(currentEvent.getStatus(EventStatus.last_publish_date).getValue())) {
    		sEvent_expiryDate = DateTools.getLocalDateFromGMT(currentEvent.getProperty(EventProps.end_date), Constants.MYSQLTIMESTAMP_PATTERN, tzname, Constants.PRETTYDATE_PATTERN_6);
    	}
    }
    
    
    sStartDateDisplay = currentEvent.getProperty(EventProps.start_date_display);
	
	
    List<Long> odStartEndTimes = DataMining2.getODEventStartEndTimes(sEventId);
    String sFirstPublishedTime = Constants.EMPTY;
    if(odStartEndTimes.get(0) > 0L && !currentEvent.getStatus(EventStatus.last_publish_date).getValue().equals(Constants.EMPTY)){
    	sFirstPublishedTime = DateTools.getStringFromLong(odStartEndTimes.get(0),Constants.PRETTYDATE_PATTERN_5,tzname);
    	String sDisplayTZName = DateTools.getTimeZoneShortName(tzname, sFirstPublishedTime, Constants.PRETTYDATE_PATTERN_5);
    	sFirstPublishedTime = sFirstPublishedTime + " " + sDisplayTZName;
    }
	
	String sScheduleID = ScheduleManager.canBroadcast(ADMIN_DB,iEventId,"test");
	
	if(!StringTools.isNullOrEmpty(sScheduleID)){
		ArrayList<HashMap<String,String>> aRemoteResource = ResourceManager.getRemoteResourceByScheduleId(sScheduleID);
		if(aRemoteResource!=null){
			for(HashMap<String,String> hmRemoteSource:aRemoteResource){
				sResourceName = hmRemoteSource.get("resourcename");
				sResourceAddress = hmRemoteSource.get("address");
				sEncoderBiteRate = hmRemoteSource.get("encoderbitrate");
				sVCUBiteRate = hmRemoteSource.get("vcubitrate");
			}
		}
	}

	documentCount = EventUploads.getEventResourcesCount(iEventId, Constants.DB_ADMINDB);
	headshotList=EventTools.getUploadsByEventId(iEventId,Constants.UploadType.HEAD_SHOT.getUploadType(),Constants.DB_ADMINDB);
	
	// determine email wording.
	if (EmailTools.eventHasEmailType(iEventId, Constants.EMAIL_REG_CONF,ADMIN_DB)) {
		bRegConfEmail = true;
	}

	if (EmailTools.eventHasEmailType(iEventId, Constants.EMAIL_EVENT_REMINDER,ADMIN_DB)) {
		bReminderEmail = true;
	}

	if (bRegConfEmail && bReminderEmail) {
		sEmailTypeText = "Registration Confirmation and Event Reminder emails enabled.";
	} else if (bRegConfEmail) {
		sEmailTypeText = "Only Registration Confirmation email enabled.";
	} else if (bReminderEmail) {
		sEmailTypeText = "Only Event Reminder email enabled.";
	}
	
	
	// determine event security wording.
	if (!currentEvent.getProperty(EventProps.master_password).equals("")) {
		bEventPassword = true;
	}

	if (!currentEvent.getProperty(EventProps.referrer_check).equals(Constants.EMPTY)
			|| "1".equalsIgnoreCase (currentEvent.getProperty(EventProps.enforce_url_key))
			|| currentEvent.getProperty(EventProps.authorized_by_email).equals("1")
			|| currentEvent.getProperty(EventProps.authorized_by_domain).equals("1")
			|| currentEvent.getProperty(EventProps.authorized_viewer_ip).equals("1")
			|| currentEvent.getProperty(EventProps.restrict_by_domain).equals("1")
			|| currentEvent.getProperty(EventProps.restrict_by_email).equals("1")
			|| currentEvent.getProperty(EventProps.blocked_viewer_ip).equals("1")
			|| !Constants.EMPTY.equals(currentEvent.getProperty(EventProps.max_simultaneous_login))) {
		bReferrerCheck = true;
		bSecurityOptions = true;
	}
	HashMap<String,String> hmLockedEventDoor = currentEvent.getLockedFrontDoorOption();
	if(!General.isNullorEmpty(hmLockedEventDoor)){
		bSecurityOptions = true;
	}
	
	boolean isAnonRegEnabled = StringTools.n2b(currentEvent.getProperty(EventProps.use_anonymous_reg));
 	
	if(isAnonRegEnabled){
		sEmailTypeText = "No email options enabled";		
	}
	if (bEventPassword && bSecurityOptions) {
		sSecurityTypeText = "Advanced security options and Event Password enabled.";
	} else if (bEventPassword) {
		sSecurityTypeText = "Event Password enabled.";
	} else if (bSecurityOptions) {
		sSecurityTypeText = "Advanced security options enabled.";
	}

	ClientBean clientInfo = AdminClientManagement.getClientByName(currentEvent.getProperty(EventProps.fk_clientid));
	sAdminDomain = clientInfo.getAdminDomain();
	sViewerDomain =clientInfo.getViewerDomain();
	sViewerBaseURL = conf.get("viewerbaseurl");
	String domain=request.getServerName(); 
	
	String sSecureProt = "https://";
	if(StringTools.isNullOrEmpty(sViewerDomain)){
		sViewerBaseURL = sSecureProt + sViewerBaseURL;
	}
	else{
		sViewerBaseURL = sSecureProt + sViewerDomain;
	}	

	//get registration info
	JSONArray regCols = new JSONArray();
	/* Code section to get the Reg Questions*/
	ArrayList<HashMap<String,String>> aMasterFieldsList = RegistrationTools.getMasterRegFields(Constants.DB_ADMINDB);
	if(!General.isNullorEmpty(aMasterFieldsList)){
		for(Iterator<HashMap<String,String>> i=aMasterFieldsList.iterator(); i.hasNext();){
			HashMap<String,String> masterFieldMap = i.next();
			HashMap<String,String> currentFieldMap = RegistrationTools.getFieldByEventIdFieldId(iEventId,masterFieldMap.get("fieldid"),Constants.DB_ADMINDB,true);
			if(currentFieldMap!=null){
				boolean fieldEnabled = false;
				String sColName = StringTools.n2s(currentFieldMap.get("display"));
				if(!General.getBooleanValue(currentFieldMap.get("deleted")) && !sColName.equals(Constants.EMPTY)){
					regCols.put(currentFieldMap.get("display"));
				}
			}
		}
	}

	boolean customReg = false;
	
	/* Code section to get the Custom Reg Questions*/
	ArrayList<HashMap<String,String>> customFieldsList = new ArrayList<HashMap<String,String>>();
	customFieldsList = RegistrationTools.getCustomFieldsByEventId(iEventId,Constants.DB_ADMINDB);
	String showCustQuest = "&cust_quest=false";
	if(!General.isNullorEmpty(customFieldsList)){
		customReg = true;
		showCustQuest = "&cust_quest=true";
	}
	String sOdEventOpen = currentEvent.getStatus(EventStatus.od_event_open).value;
	OdStudioManager odm = new OdStudioManager(iEventId, false);
	odm.load(currentEvent.getCurrentVersion() + 1);
	OdPlaylist playlist = new OdPlaylist(admindb,iEventId);
	playlist.load(false,currentEvent.getCurrentVersion() + 1);
	
	sRegionName = Location.getRegionNameByRegionId(currentEvent.getProperty(EventProps.region_id),Constants.DB_ADMINDB,true);
	
	currentEvent.setStatus(EventStatus.summary_visited,"y");
	String studioType = Constants.EMPTY;
	
	int secondaryMediaCount = playlist.getSecondaryMedia().size();
	
	
	if(currentEvent.getContentType().equalsIgnoreCase("LIVE") && !sMode.equals("ondemand") && !sMode.equals("archive_failed") && !(account.can(Perms.User.SUPERUSER) && "postlive".equalsIgnoreCase(sMode))) {
		studioType = "LIVE";	
	} else {
		studioType = "OD";
	}
	
	if(studioType.equals("LIVE") && ! account.can(Perms.User.LIVESTUDIO)) {
		studioType = "NONE";
	}
	
	if(studioType.equals("OD") && !account.can(Perms.User.ODSTUDIO)) {
		studioType = "NONE";
	}
	
	tscInfo = StringTools.n2s(currentEvent.getProperty(EventProps.tsc_info));
	isFlashMulticast = currentEvent.isFlashMulticast();
	isWindowsMulticast = currentEvent.isWindowsMulticast();
	isWindowsEnabled = currentEvent.isWindowsStreamEnabled();
	
	String caption = currentEvent.getProperty(EventProps.caption);
	if(Constants.EMPTY.equals(caption)){
		caption= Constants.EMPTY_JSON;
	}

    boolean isFollowupEmailScheduled = false;
    FollowUpEmail followupEmail = new FollowUpEmail();
    ArrayList<FollowUpEmailBean> arrFollowUpBean = followupEmail.getAllFollowUpEmail(sEventId);

    if(!General.isNullorEmpty(arrFollowUpBean)){
        for(FollowUpEmailBean followUpEmailBean :arrFollowUpBean ){
            ArrayList<EmailScheduleBean> arrEmailSchedule = followupEmail.getEmailSchedule(followUpEmailBean.getEventEmailId());
            if(!General.isNullorEmpty(arrEmailSchedule)){
                for(EmailScheduleBean emailScheduleBean : arrEmailSchedule ){
                    if("0".equalsIgnoreCase(emailScheduleBean.getStatus())){
                        // isFollowupEmailScheduled = true;
                        sEmailTypeText += " Follow-up email scheduled.";
                    }
                }
            }
        }
    }

	if (!StringTools.isNullOrEmpty(currentEvent.getProperty(EventProps.viewer_email_bcc))) {
		sEmailTypeText += " BCC for viewer emails enabled.";
	}
    
    boolean bIsSimliveRunning = false;
	if(bIsSimLive) {
		long lCurrentDate = System.currentTimeMillis();
		bIsSimliveRunning = (lCurrentDate > currentEvent.getSimliveStartTime() && lCurrentDate < currentEvent.getSimliveEndTime());
	}
	
    
	EventRedirectRequest eventRedirectRequest = new EventRedirectRequest();
	eventRedirectRequest.setEventId( StringTools.n2I(currentEvent.eventid).toString() );
	eventRedirectRequest.setDbType( ADMIN_DB );
	
	RedirectEvent redirectEvent = new RedirectEvent();
	EventRedirectResponseBean eventRedirectResponseBean = redirectEvent.getEventRedirection(eventRedirectRequest);
	
	if(bIsPortal){
		eventTypeLabel =  "Portal";
	}else if(isFolderSettingEvent){
		eventTypeLabel =  "Template";		
	}else{
		eventTypeLabel = "Event";
	}
	
	ArrayList<MulticastConfigBean> aMulticastConfig=new ArrayList<MulticastConfigBean>();
	if(isFlashMulticast){
		aMulticastConfig = currentEvent.getMulticastConfigList(Constants.MULTICAST_TYPE_FLASH);
	}
	isSecureStream = StringTools.n2b(currentEvent.getProperty(EventProps.secure_stream));

	 isBroadcasting = "1".equals(currentEvent.getStatus(EventStatus.broadcasting).value);
	 
	 
	 if(currentEvent.isODOnly()){
		 if(!sEvent_createDate.isEmpty()){
		    	sEvent_createDate = DateTools.getLocalDateFromGMT(currentEvent.getProperty(EventProps.createdate), Constants.MYSQLTIMESTAMP_PATTERN, account.tz.getID(), Constants.PRETTYDATE_PATTERN_5);
		    	String sDisplayTZName = DateTools.getTimeZoneShortName(account.tz.getID(), sEvent_createDate, Constants.PRETTYDATE_PATTERN_5);
		    	sEvent_createDate = sEvent_createDate + " " + sDisplayTZName;
		 }
		 if(!sFirstPublishedTime.isEmpty()){
		    	sFirstPublishedTime = DateTools.getStringFromLong(odStartEndTimes.get(0),Constants.PRETTYDATE_PATTERN_5,account.tz.getID());
		    	String sDisplayTZName = DateTools.getTimeZoneShortName(account.tz.getID(), sFirstPublishedTime, Constants.PRETTYDATE_PATTERN_5);
		    	sFirstPublishedTime = sFirstPublishedTime + " " + sDisplayTZName; 
		 }
		 if(!currentEvent.getProperty(EventProps.start_date_admin_display).isEmpty()){
			String sAdminStartDateDisplay = currentEvent.getProperty(EventProps.start_date_admin_display);
			int beginIndex = sAdminStartDateDisplay.indexOf("<=");
			int endIndex = sAdminStartDateDisplay.indexOf("=>");
			if(beginIndex != -1 && endIndex != -1){
				String sDisplayDate = sAdminStartDateDisplay.substring(beginIndex+2,endIndex);
				String eventTimeZoneID = currentEvent.getProperty(EventProps.timezone_id);
				String convertToTimeZoneID = account.tz.getID();
				//play stupid games win stupid prizes
				//if simlive need to pull the simlive timezone ... again
				if (currentEvent.getProperty(EventProps.isSimLive).equals("true") && sMode.equalsIgnoreCase("ondemand")) {
					final ArrayList<HashMap<String, String>> alSimlive = ScheduleManager.getSimLiveSchedule(Constants.DB_ADMINDB, iEventId, Constants.EMPTY);
					if (!alSimlive.isEmpty()) {
						final HashMap<String, String> hmSimlive = alSimlive.get(0);
						eventTimeZoneID =  DateTools.getTZNameFromDB(hmSimlive.get("fk_tzid"));
						convertToTimeZoneID = eventTimeZoneID;
					}
				}
				sDisplayDate = DateTools.getGmtFromTimeZoneDate(sDisplayDate,Constants.PRETTYDATE_PATTERN_4,eventTimeZoneID);
		    	sDisplayDate = DateTools.getLocalDateFromGMT(sDisplayDate, Constants.MYSQLTIMESTAMP_PATTERN, convertToTimeZoneID, Constants.PRETTYDATE_PATTERN_4);
		    	String sDisplayTZName = DateTools.getTimeZoneShortName(convertToTimeZoneID, sDisplayDate, Constants.PRETTYDATE_PATTERN_4);
		    	sStartDateDisplay = sAdminStartDateDisplay.substring(0,beginIndex)+sDisplayDate+" "+sDisplayTZName+sAdminStartDateDisplay.substring(endIndex+1,sAdminStartDateDisplay.length()-1);
			}
			
		 }
	 }
	 
	 boolean isBlockODStudio = JobQueue.blockODEditPublish(iEventId);
	 boolean isFileDistributorCopying = FileDistributorQueue.isCopying(iEventId, Constants.DB_FILEDISTDB);
	 
    //Tab count logic
 	int totalTabs = EventTools.getTabCount(iEventId);
	int geoCountryId= StringTools.n2i(Constants.COUNTRY_ID_USA);
 	if(currentEvent.isEventIntegratedAudio() && (sMode.equals("prelive") || sMode.equals("live"))){
		String sClientIp = request.getRemoteAddr();
		geoCountryId = Location.getCountryIdByIp(sClientIp,Constants.DB_ADMINDB, false);
		if(geoCountryId==-1){
			geoCountryId= StringTools.n2i(Constants.COUNTRY_ID_USA);
		}
 	} 	
 	
 	boolean isBackupEnabled = false;
 	if(currentEvent.isAdvanceAudio()){
 	 isBackupEnabled = StringTools.n2b(currentEvent.getStatus(EventStatus.display_backup_bridge).value);
 	}
 	
 	GuestAccessTools.GuestPortalList portalList = GuestAccessTools.getPortalList(iEventId);
 	
 	//Transcription status text
 	String transcriptStatus = "";
	String transcriptStatusColorClass = "";
 	
 	int transcriptStatusResult = -2;
 	if (!isBlockODStudio && !isFileDistributorCopying && currentEvent.isSpeechToTextFeatureEnabled(SpeechToTextConstants.Feature.TRANSCRIPT) && !Constants.EMPTY.equals(currentEvent.getStatus(EventStatus.last_publish_date).getValue())) {
 		transcriptStatusResult = SpeechToTextManager.getSpeechToTextStatusByEvent(String.valueOf(iEventId));
 		
 		switch(transcriptStatusResult) {
 			  case -1:
	 			 transcriptStatus = "There are unpublished edits to this presentation. Please publish the event in the On-Demand Studio to generate transcripts.";
	 			 transcriptStatusColorClass = "textClosed";	 			    
	 			 break;	 			
 			  case 0:
 			 	transcriptStatus = "Processing complete";
 			 	transcriptStatusColorClass = "textOpen";	 			    
 			    break;
 			  case 1:
 			 	transcriptStatus = "Transcript is processing.";
 			 	transcriptStatusColorClass = "textClosed";
 			    break;
 			  case 2:
	 			 transcriptStatus = "One or more clips have failed to process. Please republish the event in the On-Demand Studio.";
	 			 transcriptStatusColorClass = "textClosed";
	 			break;	 			    
 			  default:
 				 // error
 			}
 	}
 	final String codetag = currentEvent.getProperty(EventProps.codetag);
 	
 	final boolean bCustomShowcase = StringTools.n2b(conf.get("summary_custom_showcase_msg"));
 	
 	JSONObject managedServicesEventDataJSON = new JSONObject();
 	
 	String iglooManagedServicesUrl = StringTools.n2s(conf.get(Constants.IGLOO_MANAGED_SERVICES_FORM_SUBMIT_URL_CONFIG));

 	registrationPage = EventTools.registrationPageSelector(currentEvent);
%>

<jsp:include page="headertop.jsp">
	<jsp:param name="pfi" value="<%=pfo.sCacheID%>"/>
	<jsp:param name="ufi" value="<%=ufo.sCacheID%>"/>
</jsp:include>
<% if (!isCloneProcessing) { %>
	<%if("1".equals(currentEvent.getProperty(EventProps.webrtc_screenshare))){ %>
		<link rel="chrome-webstore-item" href="<%=conf.get("chrome_extension_url", "https://chrome.google.com/webstore/detail/gmgeanfbdjlmeeonhcekpcpabpdmdfpf")%>">
	<%} %>
	<!-- 
		<link href="/admin/css/ui.core.css" rel="stylesheet" type="text/css" media="screen"/>
		<link href="/admin/css/jqueryuithemes/jquery.ui.custom.css" rel="stylesheet" type="text/css" media="screen"/>
		<link href="/admin/css/styles.css" rel="stylesheet" type="text/css" media="screen"/>
	 -->
	 <style>
	 .fancybox-inner{
	 	overflow: hidden !important;
	 }
	 
	 #presenterBackupNumbersList #numberList, #presenterPrimaryNumbersList #numberList{
	     width: 261px;
	 }
	 
	 #audienceBackupNumbersList #numberList, #audiencePrimaryNumbersList #numberList{
	     width: 391px;
	 }
	 
	 #backupNumbers{
	 	display: flex;
	 	flex-direction: column;
	 	align-items: center;
	 }
	 
	 #delete_defaultsetting{
	    background-color: #c00;
	 }
	 
	 #delete_defaultsetting:hover{
	 	background-color: #333;
	 }
	 
	 .deleteTemplateDiv{
	 	display: flex;
	 	justify-content: center;
	 	align-items: center;
	 	margin: 15px 0 0 0;
	 }
	 
	 <%if(bCustomShowcase && studioType.equals("LIVE") && !isFolderSettingEvent && (currentEvent.isEventIntegratedAudio() || currentEvent.isAdvanceAudio())){%>
		  #showcaseAudioMsg{
		  	display: flex;
		 	justify-content: center;
		 	align-items: center;
		 	width: 100%;
		 	height: 30px;
		 	background-color: #F3BFA2;
		 	color: #666; 
		 	cursor: pointer;
		}
		
		.showcaseAudioMsgHelpBtn{
			margin: -4px 5px 0 0px;
		}
		
		.summaryBoxThird:nth-child(2), .summaryBoxThird:nth-child(3){
		   	padding: 30px 10px 10px 10px;
		}
	<%}%>
	</style>
<% } %>
 
<jsp:include page="headerbottom.jsp">
	<jsp:param name="pfi" value="<%=pfo.sCacheID%>"/>
	<jsp:param name="ufi" value="<%=ufo.sCacheID%>"/>
</jsp:include>
<% 	if (isCloneProcessing) { %>
		<jsp:include page="cloneprocessing_frag.jsp">
			<jsp:param name="pfi" value="<%=pfo.sCacheID%>"/>
			<jsp:param name="ufi" value="<%=ufo.sCacheID%>"/>
		</jsp:include>
<%	} else {
		if (isFolderSettingEvent) {
			String sFoldername = AdminFolder.getFolderName(currentEvent.getProperty(EventProps.fk_folderid));	
		%>
	    	<h1 class="folderSettingsHeader">
	    		<img src="images/icon_template-sm.png" border="0" align="textbottom" /> 
	    		Default Settings Summary for &quot;<%=sFoldername%>&quot;
	    	</h1>
	    <%}else{%>
	    	<h1><%=eventTypeLabel%> Summary<%=currentEvent != null ? " for " + currentEvent.getShortenedEventTitle() + " (" + iEventId + ") ":""%></h1>
	    <%}%>
	    <br />
	      <div class="graybox summaryMainBox">
	      
	      	<%if(!isFolderSettingEvent){ %>
	      		<% if(eventRedirectResponseBean!=null && eventRedirectResponseBean.isRedirectLinkPresent() && !isWebinar ) {%>
					<div class="whitebox importantBox">
						<img src="images/icon_redirect.png" style="float:left; margin-right:25px">
						<h2 style="font-size:200%; color:#f7901e; line-height:40px">Event Redirect Enabled</h2>
						<span>You have selected to redirect this event to another URL which blocks access to this event for all viewers. 
						Any viewer who attempts to access this event will be redirected to <a href="<%= eventRedirectResponseBean.getTarget() %>" target="_blank" class="grayLink"><%= eventRedirectResponseBean.getTarget() %></a></span>
	      				<div class="clear" style="height:0px;">&nbsp;</div>
	      			</div> 
	      			<div class="clear" style="height:15px;">&nbsp;</div>
	      		<% } %>
	
				
	      		<div style="width:1055px;" class="centerThis">
	      		<%if(!bIsPortal) { %>
	               <div class="summaryBoxThird" <%=(!showAdminOptions) ? "style=\"width:830px\"" : Constants.EMPTY %>>
	               	 <%if(bCustomShowcase && studioType.equals("LIVE") && !isFolderSettingEvent && (currentEvent.isEventIntegratedAudio() || currentEvent.isAdvanceAudio())){%>
	               		<div id='showcaseAudioMsg'>
	               			<img class="showcaseAudioMsgHelpBtn" src="/admin/images/help.png" alt="showcase Audio Messsage Help Icon"/>
	               			Tips for mitigating your phone network congestion
	               		</div>
	               	 <%}%>
	                <h3>Run My Event &nbsp;<img src="/admin/images/help.png" class="helpIcon" title="Help with &lsquo;Run My Event&rsquo;" alt="Help with &lsquo;Run My Event&rsquo;" name="help" onclick="$.help('manage_my_event','Help with &lsquo;Run My Event&rsquo;');" /></h3>
	                <br />
	                <%if(studioType.equals("LIVE") && !isFolderSettingEvent){ %>
	                  <form  id="livestudioForm" name="livestudioForm" target="_blank" method="get" enctype="text/plain">
	                    <input type="hidden" name="<%=Constants.RQUSERID%>" value="<%=ufo.sUserID%>"/>
	                    <input type="hidden" name="<%=Constants.RQSESSIONID%>" value="<%=ufo.sSessionID%>"/>
	                    <input type="hidden" name="<%=Constants.RQEVENTID%>" value="<%=pfo.iEventID%>" />
	                    <input type="hidden" name="<%=Constants.RQFOLDERID%>" value="<%=ufo.sFolderID%>"/>
	                    <a href="#" id="aLaunchLivestudio" class="button">Launch Live Studio</a>
	
	                    <br/>
	                    <br/>
	
	                     <%if(account.can(Perms.User.MANAGELIVEEVENTSCRIPT)){%>
	                     <div style="margin-left:18px;">
	                    	<a  target="editplaybook" class="buttonSmall" target="_blank" href="/playbook/playbook.jsp?<%=sQueryString%>" id="btnManagePlaybook">Manage Live Event Script</a>
	                    	<img src="/admin/images/help.png" class="helpIcon" title="Help with Event Script" alt="Help with Event Script;" name="help" onclick="$.help('event_script','Help with Live Event Script');" />
	                    </div>
						<%}%>
						
						<%if (sMode.equals("postlive")) { %>
	                    	<br /><strong><span class="messagesRed">Archive Pending</span></strong>
	                    <%} else { %>
	                    	<% if ("1".equals(conf.get("nanoextension_enabled", "1"))) {
	                   	     	if("1".equals(currentEvent.getProperty(EventProps.webrtc_screenshare))) {%>
	                   				<br /><a href="<%=conf.get("chrome_extension_url", "https://chrome.google.com/webstore/detail/gmgeanfbdjlmeeonhcekpcpabpdmdfpf")%>" target="_blank" id="installss-button" class="buttonSmall" style="display:none">Screenshare Extension for Chrome</a>
	                   			<%}
	                    	}
	                    }%>
	                     
	        			</form>
	        		<% } else if (studioType.equals("OD")) { %>
	        			<a class="button" href="javascript:void(0)" id="btnOdStudio">Launch <%=bIsSimLive ? "SimLive Studio" : "On-Demand Studio"%></a><br /><br />
	        			<% if(sMode.equals("postlive")) {
	        				//should only get here for super users
	        			%>
	                    	<br/><br/><strong><span class="messagesRed">Archive Pending</span></strong>
	                    <% } else if (isFileDistributorCopying) { %>
	              			<strong><span class="messagesRed">Files Processing</span></strong>
	              		<% } else if (isBlockODStudio) { %>
	              			<strong><span class="messagesRed">Publish Pending</span></strong>
	              		<% } else if (bIsSimliveRunning) { %>
	              			<span class="errorText">Edits cannot be published while broadcasting.</span>
	        			<% } else if (bIsSimLive && currentEvent.getStatus(EventStatus.last_publish_date).value.equals("")) { %>
	        				<span class="note errorText">Broadcast cannot be scheduled until the event is published.</span>
	        			<% } else if (currentEvent.getStatus(EventStatus.od_edit_flag).value.equals("1")) { %>
			      			<span class="note errorText">There are unpublished edits to this presentation.</span>
			      		<% } else if (playlist.size()==0) { %>
			      			<% if (currentEvent.getProperty(EventProps.acquisition_source).equalsIgnoreCase(Constants.ACQUISITION_SRC_AUDIO)) { %>
			      				<span class="note errorText">No audio files exist for this presentation.</span>
			      			<% } else { %>
			      				<span class="note errorText">No video files exist for this presentation.</span>
			      			<% } %> 
		      			<% } else if (currentEvent.getStatus(EventStatus.od_edit_flag).value.equals("1")) { %>
		      					<span class="note errorText">There are unpublished edits to this presentation.</span>
		      			<% } else if (sMode.equals("archive_failed")) { %>
		                    <strong><span class="messagesRed">Archive Failed</span></strong>
						<% } %>
	        		<% } else { %>
	        			<span class="note errorText">This feature is only available to Presenters.</span>
	        		<% } %>
	               </div>
	                <%}else if(bIsTradeShowLite){%>
	               <div class="summaryBox" style="width:1020px">
	               	<a class="button" href="javascript:void(0)" id="btnManageQA">Launch Question and Answer Studio</a>
	               	&nbsp;<img src="/admin/images/help.png"  class="helpIcon" title="Help with Question and Answer Studio" alt="Help with Question and Answer Studio" name="help" onclick="$.help('portal_question_answer_studio','Help with Question and Answer Studio');" />
	               </div>
	               <%}%>
	               <% if(showAdminOptions){ %>
		              <div class="summaryBoxThird">
		                 <h3>Review My <%=eventTypeLabel%> &nbsp;&nbsp; 
	                     	<%if(bIsPortal){%>
	                        <img src="/admin/images/help.png" class="helpIcon" title="Help with &lsquo;Review My <%=eventTypeLabel%>&rsquo;" alt="Help with &lsquo;Review My <%=eventTypeLabel%>&rsquo;" name="help" onclick="$.help('portal_review','Help with &lsquo;Review My <%=eventTypeLabel%>&rsquo;');" />
							<%}else{%>
	                        <img src="/admin/images/help.png" class="helpIcon" title="Help with &lsquo;Review My <%=eventTypeLabel%>&rsquo;" alt="Help with &lsquo;Review My <%=eventTypeLabel%>&rsquo;" name="help" onclick="$.help('view_my_event','Help with &lsquo;Review My <%=eventTypeLabel%>&rsquo;');" />
	                    	<%}%>
	                     
	                     <br />
		                 </h3><br />
			               <a href="#" class="button" onclick="return viewwebcast();">View <%=eventTypeLabel%> </a><br /><br />
		              </div>
		              
		             <div class="summaryBoxThird">
		                 <h3>My <%=eventTypeLabel%> Reports &nbsp;&nbsp; 
							<%if(bIsPortal){%>
	                        <img src="/admin/images/help.png" class="helpIcon" title="Help with Portal Reports" alt="Help with Portal Reports" name="help" onclick="$.help('portal_reports','Help with Portal Reports');" />
	                        <%}else{%>
	                        <img src="/admin/images/help.png" class="helpIcon" title="Help with Event Reports" alt="Help with Event Reports" name="help" onclick="$.help('my_reports','Help with Event Reports');" />
	                        <%}%>
	                     <br />
		                 </h3><br />
		                 <%if(account.can(Perms.User.RUNREPORTS) && !isFolderSettingEvent) { %>
			               <a href="/report/reports_main.jsp?<%=sQueryString%>" class="button">Run a Report on this <%=eventTypeLabel%> </a><br /><br />
				               <%if(!bIsPortal && account.can(Perms.User.RUNSUBSCRIPTIONREPORTS)){ %>
				               <a href="manage_report_subscription.jsp?<%=sQueryString%>" id="btnManageSubscription" class="buttonSmall">Subscribe to Reports</a>
				               <%} %>
			               <%} else { %>
			               <span class="note errorText">This feature is only available to Administrators.</span>
			               <%} %>
		              </div>
	              <% } %>
		         <div class="clear"></div>
		       </div>
		       
		       <div class="clear"></div>
		       <br />
	        <%} %>
	        
	  <div class="summaryRightColumn" id="summaryRightColumn_id" <%=(isWebinar) ? "style=\"display:none\"" : Constants.EMPTY %>>
	         
	           <h2><%=eventTypeLabel%> Details</h2><br />
	           <%if(isFolderSettingEvent){ %>
		      		<div><a href="#" class="button"  onclick="return viewwebcast();">Test Template</a></div>
		      		<br/>
	      		<%}else{%>
	           <span class="webcastURL">
	           <span class="adminFieldName"><%=eventTypeLabel%> URL</span><br />
	              <span class="small grayLink" onclick="return viewwebcast();"><%=currentEvent.getEventUrl()%></span>
	              <button id="copyLink" class="buttonSmall">Copy</button>
	              <input id="copyLinkTxt" style="opacity: 0;"  type="text" value="<%=currentEvent.getEventUrl()%>"></input>
	              <% if(eventRedirectResponseBean!=null && eventRedirectResponseBean.isRedirectLinkPresent()  && !isWebinar ) { %>
	              		<br /><span class="small" style="font-weight:bold;">Redirected to: <a href="<%=eventRedirectResponseBean.getTarget()%>" class="grayLink" target="_blank"><%=eventRedirectResponseBean.getTarget()%></a></span><br />   		
	              <% } %>
	               <br>    
	            </span>
				<%}%>
	           		<!--start event access-->       
	           		<!--start event access-->       
	           	<% if(showAdminOptions){ %>
					<%if(account.can(Perms.User.SCHEDULEEVENTCLOSE) || (account.can(Perms.User.HIDEREGFORM))){ %>
			            <span class="adminFieldName"><%=eventTypeLabel%> Access &nbsp;
	                    <%if(bIsPortal){%>
	                    <img src="/admin/images/help.png" class="helpIcon" title="Help with Portal Access" alt="Help with Portal Access" name="help" onclick="$.help('portal_access','Help with Portal Access');" />
						<%}else{%>
	                    <img src="/admin/images/help.png" class="helpIcon" title="Help with Event Access" alt="Help with Event Access" name="help" onclick="$.help('event_access','Help with Event Access');" />
						<%}%>
	                    </span>
			            <div class="summaryBoxRightContent" id="tblOdEventOpen">
			              <span id="playerStatus" style="display:inline-block; width:165px;"></span>
						  <%if(sMode.equalsIgnoreCase("postlive")){ %><br /><em>Archive Pending</em>
			              </span> 
			              <%} %>
			              <span class="note"><br /><br /></span>
			              <a class="button" href="manage_player_access.jsp?<%=sQueryString%>&pfi=<%=pfo.sCacheID%>&ufi=<%=ufo.sCacheID%>" id="btnSetPlayerAccess">Manage Access</a>
			               <br/>
			             </div>
	           		 <%}else{ %>
		                <!--start player access only-->
		                <% if (currentEvent.getStatus(EventStatus.mode).value.equals(EventMode.ondemand.toString())) { %>
		                <br />
						<h4>Player Access &nbsp;<img src="/admin/images/help.png" class="helpIcon" title="Help with Player Access" alt="Help with Player Access" name="help" onclick="$.help('player_access','Help with Player Access');" /></h4>
		                  <div class="summaryBoxRightContent" id="tblOdEventOpen" <%=currentEvent.getArchiveOpenStatus() ? "" : " style=\"display:none\" "%> ><!--On-Demand -->Player: <span class="textOpen">Open</span>
		                  <span class="note"><br /><br /></span>
		                  <a class="buttonSmall" href="javascript:void(0)" id="btnCloseOdEvent">Close Player</a>
		                 </div>
		                 <div id="tblOdEventClosed" class="summaryBoxRightContent" <%=!(currentEvent.getArchiveOpenStatus()) ? "" : " style=\"display:none\" "%>><!--On-Demand -->Player: <span class="textClosed">Closed</span> 
		                 <span class="note"><br /><br /></span>
		                 <a class="buttonSmall" href="javascript:void(0)" id="btnOpenOdEvent">Open Player</a> </div>
		                <% }%>
		                <%if(sMode.equalsIgnoreCase("postlive")){ %>
		                <br />
						<h4>Player Access &nbsp;<img src="/admin/images/help.png" class="helpIcon" title="Help with Player Access" alt="Help with Player Access" name="help" onclick="$.help('player_access','Help with Player Access');" /></h4>
		                 <div id="tblOdEventOpen" class="summaryBoxRightContent" <%=(sOdEventOpen.equals("1"))? "" : " style=\"display:none\" "%> ><!--On-Demand -->Player: <span class="textClosed">Closed</span>
		    				<span class="note"><br /><br />The player will remain closed<br />when the archive completes.<br /><br /></span>
		                 <a class="buttonSmall" href="javascript:void(0)" id="btnCloseOdEvent">Open the Player Automatically</a> </div>
		                 <div id="tblOdEventClosed" class="summaryBoxRightContent" <%=(!sOdEventOpen.equals("1"))? "" : " style=\"display:none\" "%> ><!--On-Demand -->Player: <span class="textClosed">Closed</span>
		    				<span class="note"><br /><br />The player will open automatically<br />when the archive completes.<br /><br /></span>
		                 <a class="buttonSmall" href="javascript:void(0)" id="btnOpenOdEvent">Keep Player Closed</a></div>
		                <%} %>
		                <!--end player access only-->
	            	<%}%>
			   	<%} %>
	 <%if(!isFolderSettingEvent){ %>		 
			  <!--  if od and not a portal and is published -->
	<% 
		if (studioType.equals("OD") && !currentEvent.isPortal() && !currentEvent.getStatus(EventStatus.last_publish_date).value.equals(Constants.EMPTY)) {
			ArrayList<HashMap<String,String>> alMP4Archives = currentEvent.getMP4Archives();
			if (account.can(Perms.User.DOWNLOADMP4ARCHIVE) && (alMP4Archives.size() > 0) || account.can(Perms.User.CREATEMP4ARCHIVE) || EventTools.hasM4AForCurrentVersion(sEventId)) {
				boolean inProgress = MP4ArchiveTools.mp4ArchiveInProgress(String.valueOf(iEventId));
	%> 
						  	
				<div id="tblOdEventOpen" class="summaryBoxRightContent">	   
					<h3>Manage Webcast Archive&nbsp; <img src="/admin/images/help.png" class="helpIcon" title="Help with Downloading Webcast Archives" alt="Help with Downloading Webcast Archives" name="help" onclick="$.help('download_archives','Help with Downloading Webcast Archives');" /></h3>
	<% 
				if (account.can(Perms.User.CREATEMP4ARCHIVE)) {
					int iCurrentMP4Version = MP4ArchiveTools.getLatestArchiveVersion(alMP4Archives);
					boolean isCurrent =  iCurrentMP4Version >= currentEvent.getCurrentVersion();
	%> 
						   	<span class="button <%=(inProgress || isCurrent) ? "disabledButton" : Constants.EMPTY %>" <%=(!inProgress && !isCurrent) ? "onclick=\"confirmCreateMP4Archive()\"" : Constants.EMPTY%> style="color: #fff">
						   		Export Webcast as MP4
						   	</span>
						   		
	<% 
					if (inProgress) { 
	%>
				            <span class="note"><img src="images/icon_sm-processing.png" style="vertical-align:middle" class="processingSpinner" /> <span style="display:inline-block; vertical-align:text-top;width:200px;margin-top:5px;">An MP4 Archive is currently processing. When it is complete, the file will be available below.</span></span>
	<%   
					} else if (isCurrent) {
	%>
							<br /><br />
				            <span class="note errorText">No changes published since the last archive was created.</span>
	<%  
					} 
				} 
			
				if (StringTools.n2b(currentEvent.getStatus(EventStatus.od_edit_flag).value)) { 
	%>
							      <br/><br/>
							      <span class="note errorText">There are unpublished edits to this presentation.</span>
	<% 
				}
			
				if ((account.can(Perms.User.DOWNLOADMP4ARCHIVE) && alMP4Archives.size() > 0) || EventTools.hasM4AForCurrentVersion(sEventId)) { 
					SDFManager sdf = SDFManager.getInstance(Constants.PRETTYDATE_PATTERN_5);
	%>
								<span id="mp4Archives" style="display:inline-block; width:auto;">
				              	  <br />
				 				  Available Archives:
				              	  <ul class="mp4Archive">
	<%
					if (account.can(Perms.User.DOWNLOADMP4ARCHIVE) && alMP4Archives.size() > 0) {
						for(HashMap<String,String> mp4Archive : alMP4Archives) { 
							String sDateTxt = Constants.EMPTY;
							try {								
								sDateTxt = sdf.format(StringTools.n2l(mp4Archive.get("createddate")), account.tz);			
							} catch(Exception e) {
								sDateTxt = DateTools.applyDatePattern(mp4Archive.get("createddate"), Constants.MYSQLTIMESTAMP_PATTERN,Constants.PRETTYDATE_PATTERN_5);
								logger.log(Logger.WARN, EventTools.class.getSimpleName(), "Old data format being used in database, date for event mp4 archive creation may be off", "getMP4Archives");				
							}			 
	%>
							<li class="mp4ArchiveDownload" id="<%=mp4Archive.get("uploadid") %>" onclick="downloadArchive(this.id, <%=DownloadConstants.DownloadType.MP4Archive.value()%>);">
								<span class="small grayLink"> Full Webcast (MP4) - <%= sDateTxt %></span>   
							</li>							 
	<%  
						}
					}
		
					if (EventTools.hasM4AForCurrentVersion(sEventId)) {
	%>
						<li class="mp4ArchiveDownload" id="audio_archive" onclick="downloadArchive(this.id, <%=DownloadConstants.DownloadType.AUDIO.value()%>);">
							<span class="small grayLink">Audio Only (M4A) - <%=sdf.format(StringTools.n2l(currentEvent.getStatus(EventStatus.last_publish_date).value), account.tz)%></span>   
						</li>
	<%
					}
					if (currentEvent.isEventVideo() && account.can(Perms.User.DOWNLOADMP4ARCHIVE)) {
	%>
						<li class="mp4ArchiveDownload" id="published_event" onclick="downloadArchive(this.id, <%=DownloadConstants.DownloadType.PUBLISHED_EVENT.value()%>);">
							<span class="small grayLink">Video Only (MP4) - <%=sdf.format(StringTools.n2l(currentEvent.getStatus(EventStatus.last_publish_date).value), account.tz)%></span>   
						</li>
	<%              }
	%>
						</ul>
					</span>
	<%
				}
	%>
				</div>
				<br />
	<% 
			}
		}
	%>
	
	
	
	
	   			<%if (account.can(Perms.User.LIVESTUDIO) && !currentEvent.isODOnly() && !currentEvent.isPortal() && !sMode.equals("prelive")) { %>
	   				<h3>Live Event Activity &nbsp; <img src="/admin/images/help.png" class="helpIcon" title="Help with Live Event Activity" alt="Help with Live Event Activity" name="help" onclick="$.help('live_log','Help with Live Event Activity');" /></h3><a  class="button" id="btnLiveStudioLog" href="javascript:void(0)">View Activity Log</a>
					
					<br /><br />
	   			<%}%>
	   			
	   			<%if (transcriptStatusResult != -2) { %>
	   				<h3>
	   					Transcription 
	   					<img src="/admin/images/help.png" class="helpIcon" title="Help with Transcript Status" alt="Help with Transcript Status" name="help" onclick="$.help('transcript_summary_status','Help with Transcript Status');" />
	   				</h3>
	   				<div class=<%=transcriptStatusColorClass%>>
	   					<%=transcriptStatus%>
	   				</div>
	   				<%if (transcriptStatusResult == 0) {%>
						<br />
			   			<div id="tblOdEventOpen" class="summaryBoxRightContent">	   
							<span class="button " onclick="exportTranscript()" style="color: #fff">
								Download Transcript
							</span>
						</div>
					<%} %>
					<br /><br />				
	   			<%}%>
	
	<%}%><!-- End of non folder template settings -->
				    
				    
				    		   
		<% if((sMode.equals("prelive") || sMode.equals("live"))){%>
		
		  <%if(!isFolderSettingEvent){ %>     
			<div id="divPhoneNumbers" style="display:none;" >
		    	<h3>Phone Numbers</h3>
		    	<%if(!isFolderSettingEvent){ %>    
		    		<%if(currentEvent.isEventIntegratedAudio()){%>
		    		<div class="bridgeTitle">Presenter Conference Bridge</div>			       	   		
			       		<div id="presenterNumbers">
			       		</div>
			   		<%}%>
			   		<%if(currentEvent.allowListenByPhone()){%>
			   		<div class="bridgeTitle">Audience Listen By Phone</div>	
			       		<div id="audienceNumbers">
			       		</div>
			       	<%}%>
			    <%}%>
			     	
		       	<%if(currentEvent.isAdvanceAudio()){%>
				    <%if(!isFolderSettingEvent){ %>       	
				       	<div class="bridgeTitle">
				       		Backup Bridge			       		
				       		<button class="buttonSmall" id="phoneDetails">View Details</button>
				       		
				       	</div>
				     <%}%>
		    		<div id="backupNumbersStatus"></div>
		       	<%}%>
		   </div>
		       	
		       	<!-- Shown in dialog -->
		       	<div id="presenterPrimaryNumbersList" style="display: none;" class="presenterNumbers"></div>
		       	<div id="audiencePrimaryNumbersList" style="display: none;" class="presenterNumbers"></div>
		       	<div id="backupNumbers" style="top: 59px;display:none;">
					<div style="float:left">
						<div class="bridgeTitle">Backup Presenter Conference Bridge</div>
						<div id="presenterBackupNumbers"></div>
						<div id="presenterBackupNumbersList" class="presenterNumbers"></div>
					</div>					
					<%if(currentEvent.allowListenByPhone()){%>
					<div  style="float:left">						
						<div class="bridgeTitle">Backup Audience Listen By Phone</div>
						<div id=audienceBackupNumbers></div>
						<div id="audienceBackupNumbersList"></div>	
					</div>
					<%}%>
				</div>
		       	<!--End of dialog -->
		       	<br/>
	      <%}%> 	<!-- End of non folder template settings -->
	       	
		     
	     
	       	<!-- Display following if folder template or not. -->
	       <%if(currentEvent.isAdvanceAudio()){%>
		       	<%if(isFolderSettingEvent){ %>
			     <br/>  
			      	 <h3>Live Studio Workflow</h3>
			     <%}%>
	       		<%if(account.can(Perms.User.MANAGEBACKUPBRIDGEDISPLAY)) {%>			       			
	       			<div id="bridgeToggle" style="width:100%;float: left;">
	       				<span id="msgATWorkflow" class="messagesGreen" style="display: none;margin-left:5px;font-weight: bold;width: 100%;">Workflow updated</span>
	       				<label><input type="radio" name="radEnableBackup" id="chk_selfservice" value="0" autocomplete="off" <%if(!isBackupEnabled){%>checked<%}%>>Self-Service Workflow</label><br/>
	       				<label><input type="radio" name="radEnableBackup" id="chk_operatorassist" value="1" autocomplete="off" <%if(isBackupEnabled){%>checked<%}%>>Operator Assisted Workflow</label><br/><br/>
	       			</div>
	       		<%}%>
	      	<%}%>
	    <%}%><!-- End of non live prelive event-->
	            
	         
	    <%if(!isFolderSettingEvent){ %>     
	        <span id='eventCr'><strong>Created</strong>: <%=sEvent_createDate%> by <%=sCreator_username%></span>
			<br/>
			<%if(!sFirstPublishedTime.equals(Constants.EMPTY)){ %>
			<span id=""><strong>First published</strong>: <%=sFirstPublishedTime%></span> 
			<%}%>
			<%if(!sEvent_expiryDate.equals(Constants.EMPTY)){%>
			<br/><span id=""><strong>Expiration Date</strong>: <%=sEvent_expiryDate%></span> 
			<%}%>
	        <%if(currentEvent.isHiveMulticast() && currentEvent.useHTMLStream() && account.can(Perms.User.MANAGEHIVEMULTICAST)){%>
			 	<br/><a class="button" href="hivemulticast.jsp?<%=sQueryString%>" id="btnHiveInfo">Hive Information</a>
			<%}%>
			<%if(currentEvent.isRampMulticast() && currentEvent.useHTMLStream() && account.can(Perms.User.MANAGERAMPMULTICAST)){%>
			 	<br/><a class="button" href="rampadmin.jsp?<%=sQueryString%>" id="btnRampInfo">Ramp Multicast Setup</a>
			<%}%>
			<%if(currentEvent.isRampCache() && currentEvent.useHTMLStream() && account.can(Perms.User.MANAGERAMPMULTICAST)){%>
				<br/><br/><a class="button" href="rampadmin.jsp?<%=sQueryString%>" id="btnRampInfo">Ramp Cache Setup</a>
			<%}%>	
			<%if(currentEvent.isKollectiveMulticast() && currentEvent.useHTMLStream() && account.can(Perms.User.MANAGEKOLLECTIVEMULTICAST)){%>
				<br/><br/><a class="button" href="kollectivepreview.jsp?<%=sQueryString%>" id="btnRampInfo">Kollective Setup</a>
			<%}%>		
			<br/><br/> 
			<%if (bIsPortal) {
				if (account.can(Perms.User.CONFCASTADMIN)){%>
					Confcast Data Link  <a id="confcastDataLink" href="javascript:void(0)" class="button">Add / Edit </a>  <%= currentEvent.getProperty(EventProps.confcastdatalink) %>
				<%} else if (!Constants.EMPTY.equals(currentEvent.getProperty(EventProps.confcastdatalink))){%>
			 		Confcast Data Link : <%= currentEvent.getProperty(EventProps.confcastdatalink) %>
			 	<%}%>
				<br/><br/> <%
				if (VideoCMSManager.getVideoCMSClientBeanForFolder(currentEvent.getFolderId()) != null) {
					boolean isVideoCMSEnabled = VideoCMSManager.isVideoCMSEnabled(sEventId);
					String sVideoCMSUrl = isVideoCMSEnabled ? VideoCMSManager.getInstance(sEventId).getFullUrl(sEventId) : Constants.EMPTY;
					if (account.can(Perms.User.MANAGEVIDEOCMS)){%>
						<a id="manageVideoCMSBtn" href="javascript:void(0)" class="button">Manage Video CMS</a>
					<%}%>
					<br/>
			 		<span id="videocmslinkSpn" style="visibility:<%=isVideoCMSEnabled ? "inline" : "hidden"%>">Video CMS Link: <a href="<%=sVideoCMSUrl%>" id="videocmslinkAnchor" target="blank"><%=sVideoCMSUrl%></a></span>
			 	<%}%>
			<%}%>
		<%}%><!-- End of non folder template settings -->
	<%
		if (account.can(Perms.User.REQUESTMANAGEDSERVICES) && !isFolderSettingEvent && !currentEvent.isPortal() && EventMode.prelive.toString().equals(sMode)) {
			managedServicesEventDataJSON = EventTools.getManagedServicesEventDataJSON(currentEvent, Constants.DB_ADMINREPORTDB);
			%><a id="requestEventServicesBtn" class="button" href="javascript:void(0)">Request Event Services</a><%
		}
	
		if (!isFolderSettingEvent && !isAnonRegEnabled && account.can(Perms.User.REGISTRATIONUPLOAD)) { 
	%>
			<br/><br/>
			<a id="btnRegUpload" class="button" href="javascript:void(0)">Upload Registrants</a>
	<%
		} 
	%>
		</div>	
			<!--end right column-->
		   
		    <!--end event access-->
	   			
			<br/>
	      	<h2><%=eventTypeLabel%> Setup Checklist &nbsp;
	        <%if(bIsPortal){%>
	        <img src="/admin/images/help.png" class="helpIcon" title="Help with Portal Setup Checklist" alt="Help with Portal Setup Checklist" name="help" onclick="$.help('portal_setup_checklist','Help with Portal Setup Checklist');" /></h2>
			<%}else{%>
	        <img src="/admin/images/help.png" class="helpIcon" title="Help with Event Setup Checklist" alt="Help with Event Setup Checklist" name="help" onclick="$.help('event_setup_checklist','Help with Event Setup Checklist');" /></h2>
	        <%}%>
	        
	
	        <table id="table_vert">
	        	<tr>
	        		<td>
	                <div id="divBoxes">
	                	<%if(bIsSimliveRunning) { %>
	                	<table width="800" cellpadding="0" cellspacing="0" class="summaryBox summaryBoxYellow">
	                      <tr> 
	                            <td width="25">&nbsp;</td>
	                            <td width="460"><strong><span class="messagesRed">SimLive Presentation is Broadcasting Now</span></strong><br><span class="note">&nbsp;</span></td>
	                            <td width="80"><a class="button" href="javascript:void(0)" id="btnAudienceMsg">Message</br>Audience</a></td>
	                            <td width="80"><a class="button" href="javascript:void(0)" id="btnAudienceDetails">View</br>Audience</a></td>
	                            <td width="80"><a class="button" href="javascript:void(0)" id="btnManageQA">Manage</br>Q&A</a></td>
	                            <td width="10">&nbsp;</td>            
	                      </tr>
	                    </table>
	                    <%}%>
	                	
	                 <% if(bIsPortal){ %>
	                <table width="800" cellpadding="0" cellspacing="0" class="summaryBox summaryBoxGreen">
	                  <tr> 	
	                        <td width="25">&nbsp;</td>
	                        <td width="460"><%=eventTypeLabel%> Settings<br><span class="note">&nbsp;</span></td>
	                        
	                      <td width="100" align="right"><a href="#" class="button" name="editSet_param" id="editSet">Edit</a></td>
	                        <td width="10">&nbsp;</td>            
	                </tr>
	              </table>
	              <%}else  if(sMode.equalsIgnoreCase("postlive") || sMode.equalsIgnoreCase("archive_failed")){ 
	                    String sStatusDesc = sMode.equalsIgnoreCase("postlive") ? "Archive Pending" : "Archive Failed" ;%>
	                <table width="800" cellpadding="0" cellspacing="0" class="summaryBox summaryBoxYellow">
	                  <tr> 
	                        <td width="25">&nbsp;</td>
	                        <td width="460"><%=eventTypeLabel%> Settings and Schedule<br><span class="note" id="schedule_note"></span></td>
	                        <td width="50" style="text-align:center"><strong><span class="messagesRed"><%=sStatusDesc %></span></strong></td>
	                        <%if (account.can(Perms.User.SUPERUSER)){ %>
	                        <td width="50"><input type="button" class="button" name="convertToOd_param" id="convertToOd" value="Republish" /></td>
	                        <%} %>
	                        <td width="10">&nbsp;</td>            
	                  </tr>
	                </table>
	                <%}else if(sMode.equalsIgnoreCase("live")){ %>
	                <table width="800" cellpadding="0" cellspacing="0" class="summaryBox summaryBoxBlocked">
	                  <tr> 	
	                        <td width="25">&nbsp;</td>
	                        <td width="460"><%=eventTypeLabel%> Settings and Schedule<br><span class="note" id="schedule_note"></span></td>
	                        <td width="50">&nbsp;</td>
	                        <td width="50" style="text-align:center"><strong><span class="messagesGreen">Live Now</span></strong></td>
	                        <td width="10">&nbsp;</td>            
	                </tr>
	              </table>
	               <%}else if(isBroadcasting){ %>
	                <table width="800" cellpadding="0" cellspacing="0" class="summaryBox summaryBoxBlocked">
	                  <tr> 	
	                        <td width="25">&nbsp;</td>
	                        <td width="460"><%=eventTypeLabel%> Settings and Schedule<br><span class="note" id="schedule_note"></span></td>
	                        <td width="50">&nbsp;</td>
	                        <td width="50" style="text-align:center"><strong><span class="messagesGreen">Stream Connected</span></strong></td>
	                        <td width="10">&nbsp;</td>            
	                </tr>
	              </table>
	              <%}else{ %>
	                <table width="600" cellpadding="0" cellspacing="0" class="summaryBox summaryBoxGreen">
	                  <tr> 
	                        <td width="25">&nbsp;</td>
	                        <td width="460"><%if(isFolderSettingEvent){ %>Default Event Settings<%}else{%><%=eventTypeLabel%> Settings and Schedule<%}%><br><span class="note" id="schedule_note"></span></td>
	                        <td width="100" align="right"><a href="#" class="button" name="editSet_param" id="editSet">Edit</a></td>
	                        <td width="10">&nbsp;</td>
	                  </tr>
	                </table>
	                <%} %>
	                
	                <%if(showAdminOptions){ %>
	                <table cellpadding="0" cellspacing="0" class="summaryBox summaryBoxGreen">
	                  <tr> 	
	                        <td width="25">&nbsp;</td>
	                        <td width="460"><%if(isFolderSettingEvent){%>Default <%}%>Registration Options<br><span class="note" id="registration_note"></span></td>
	                        <td width="100"><a href="/admin/<%=registrationPage%>?layout=advanced&<%=sQueryString %><%=showCustQuest%>" class="button">Edit</a></td>
	                        <td width="10">&nbsp;</td>
	                  </tr>
	                </table>
	                <%} %>
	                
	                <%if(bIsPortal){ %>
	                <table width="600" cellpadding="0" cellspacing="0" class="summaryBox summaryBoxGreen">
	                  <tr> 	
	                        <td width="25">&nbsp;</td>
	                        <td width="460"><%if(isFolderSettingEvent){%>Default <%}%>Branding Options<br><span class="note">&nbsp;</span>                        
	                        <td width="100"><a href="/admin/player_select.jsp?<%=sQueryString %>" class="button">Edit</a></td>
	                        <td width="10">&nbsp;</td>
	                  </tr>
	                </table>
	                <%}else{ %>
	                <table width="600" cellpadding="0" cellspacing="0" class="summaryBox summaryBoxGreen">
	                  <tr> 	
	                        <td width="25">&nbsp;</td>
	                        <td width="460"><%if(isFolderSettingEvent){%>Default <%}%>Player and Branding Options<br>
	                        <span class="note" id="player_note"></span></td>
	                        <td width="100"><a href="/admin/player_select.jsp?<%=sQueryString %>" class="button">Edit</a></td>
	                        <td width="10">&nbsp;</td>
	                  </tr>
	                </table>
	                <%} %>
	                
	               <%if(!bIsPortal){ %>
	                <%if(currentEvent.getProperty(EventProps.slides).equals("1") && !isFolderSettingEvent && currentEvent.getSlideDecks().size()<=0){%>
	                <table width="600" cellpadding="0" cellspacing="0" class="summaryBox summaryBoxRed">
	                <%}else if((sDeckStatus && (hasJobempty && hasJobID)) || (sDeckStatus && hasJobempty)){%>
	             	<table width="600" cellpadding="0" cellspacing="0" class="summaryBox summaryBoxBlue">
	             <% }else if(sDeckStatus && (hasJobID && !hasJobempty)){%>
	                <table width="600" cellpadding="0" cellspacing="0" class="summaryBox summaryBoxYellow">
	               <% }else{%>
	                 <table width="600" cellpadding="0" cellspacing="0" class="summaryBox summaryBoxGreen">
	                 <%} %>
	                  <tr> 	
	                        <td width="25">&nbsp;</td>
	                        <td width="460"><%if(isFolderSettingEvent){%>Default <%}%>Event Content<br><span class="note" id="eventcontent_note"></span></td>
	                        <td width="105"><a href="/admin/event_content.jsp?<%=sQueryString %>" class="button">Edit</a></td>
	                        <td width="10">&nbsp;</td>
	                  </tr>
	                </table>
	                <%}else if(bIsTradeShowLite){ %>
	                	 <table width="600" cellpadding="0" cellspacing="0" class="summaryBox summaryBoxGreen">
		                  <tr> 	
		                        <td width="25">&nbsp;</td>
		                        <td width="460">Portal Content<br><span class="note" id="eventcontent_note"></span></td>
		                        <td width="105"><a href="/admin/event_content.jsp?<%=sQueryString %>" class="button">Edit</a></td>
		                        <td width="10">&nbsp;</td>
		                  </tr>
		                </table>
	                <%}%>
	                 <%if(showAdminOptions){ %>
	                <table width="600" cellpadding="0" cellspacing="0" class="summaryBox <%=(Constants.EMPTY.equals(sSecurityTypeText))?" summaryBoxRed":" summaryBoxGreen"%>">
	                  <tr> 	
	                        <td width="25">&nbsp;</td>
	                        <td width="460"><%if(isFolderSettingEvent){%>Default <%}%>Security Settings<br><span class="note" id="security_note"><%=(Constants.EMPTY.equals(sSecurityTypeText))?" No security options enabled.": sSecurityTypeText %></span></td>
	                        <td width="105"><a href="/admin/event_security.jsp?<%=sQueryString %>" class="button">Edit</a></td>
	                        <td width="10">&nbsp;</td>
	                  </tr>
	                </table>
	               
	                
	                <table cellpadding="0" cellspacing="0" class="summaryBox summaryBoxGreen">
	                  <tr> 	
	                        <td width="25">&nbsp;</td>
	                        <td width="460"><%if(isFolderSettingEvent){%>Default <%}%>Email and Marketing Options<br><span class="note" id="email_pref_note"><%=sEmailTypeText%></span></td>
	                        <td width="105"><a href="/admin/event_email.jsp?layout=advanced&<%=sQueryString %>" class="button">Edit</a></td>
	                        <td width="10">&nbsp;</td>
	                  </tr>
	                </table>
	                 <% } %>
	                 <%if(bIsPortal){ %>
	                  <table cellpadding="0" cellspacing="0" class="summaryBox summaryBoxGreen">
	                  <tr> 	
	                        <td width="25">&nbsp;</td>
	                        <td width="460">Manage Portal Layouts<br><span class="note" id="portal_layout_note"></span></td>
	                        <td width="105"><a href="/admin/portal_settings.jsp?layout=advanced&<%=sQueryString %>" class="button">Edit</a></td>
	                        <td width="10">&nbsp;</td>
	                  </tr>
	                </table>
	                 <table cellpadding="0" cellspacing="0" class="summaryBox summaryBoxGreen">
	                  <tr> 	
	                        <td width="25">&nbsp;</td>
	                        <td width="460">Manage Linked Segments<br><span class="note" id="portal_link_note"></span></td>
	                        <td width="105"><a href="/admin/portal_segments.jsp?layout=advanced&<%=sQueryString %>" class="button">Edit</a></td>
	                        <td width="10">&nbsp;</td>
	                  </tr>
	                </table>
	                <%} %>
	                
	                  
	                <%if(!isFolderSettingEvent && (sMode.equals("prelive") || sMode.equals("live")) && currentEvent.getProperty(EventProps.resourcetype).equalsIgnoreCase(Constants.ResourceType.ENCODER.dbName())&& isWindowsEnabled  && account.can(Perms.User.ENABLEWINDOWSMEDIA)){%>
	                <table cellpadding="0" cellspacing="0" class="summaryBox summaryBoxGreen">
	                  <tr> 	
	                        <td width="25">&nbsp;</td>
	                        <td width="460">Windows Media Setup<br><span class="note" id="flash_multicast_note">&nbsp;</span></td>
	                        <td width="105"><a id="btnWindowsMulticast" href="/admin/windows_media_settings.jsp?<%=sQueryString %>" class="button">Edit</a></td>
	                        <td width="10">&nbsp;</td>
	                  </tr>
	                </table>
	               <%} %>
	              
	              
	              
	               </div>
	               </td>
	            </tr>
	        </table>
	                       
	      </div>
	
	      <div style="clear: both; height:10px"></div>
	      <!-- Hide Eeveryttthing below for portal event -->
	      <%if(!bIsPortal ){%>      
	          
	      <%if(!isFolderSettingEvent && (sMode.equals("prelive") || sMode.equals("live")) && isFlashMulticast && account.can(Perms.User.MANAGEFLASHMULTICAST)){%>
	       <div class="sectionBoxWide">
	   		<div>
	   			<h2 id="btnshowMulticastSettings" style="display:inline">Flash Multicast settings&nbsp;&nbsp; </h2><!--<img src="/admin/images/help.png" class="helpIcon" title="Help with Flash Multicast Settings" alt="Help with Flash Multicast Settings" name="help" onclick="$.help('multicast_flash','Help with Flash Multicast Settings');" />-->
	   			<a style="float:right; margin:0 20px 0 10px" id="addMulticastConfig" href="/admin/fmsconfig/configurator.jsp?<%=sQueryString %>" class="button">New Configuration</a>
	   			<a style="float:right;" id="addGlobalSetting" href="/admin/fmsconfig/globalsetting.jsp?<%=sQueryString %>" class="button">Multicast Setting</a>
	            <div></div>
	   		</div>
	   		<div id="MulticastSettings">
			</div>
			</div>
			<div style="clear: both; height:10px"></div>
	     <%} %>
	                
	      
	    <div class="sectionBoxWide">
	   		<div id="optionalOptionsBox">
	   			<h2 id="btnshowOptionalSettings" style="display:inline"><span class="arrowClosed">Optional Event Settings</span>&nbsp;&nbsp; </h2><img src="/admin/images/help.png" class="helpIcon" title="Help with Optional Event Settings" alt="Help with Optional Event Settings" name="help" onclick="$.help('optional_event_settings','Help with Optional Event Settings');" />
	   		</div>
	   		<div id="optionalSettings">		
		   		<% if (!isWebinar && !isFolderSettingEvent) {
		   			ArrayList<HashMap<String,String>> list = EventTools.getCalendarReminder(iEventId, ADMIN_DB, true);
		   				
		   			if(General.isNullorEmpty(list)){
		   			//Load Default Reminder and Record it in Database
		   				HashMap<String,String> hmCal = currentEvent.getCalendarReminderData();
			   			String sTitle = hmCal.get("title");
			   			String sUrl = hmCal.get("url");
			   			String sDescription = hmCal.get("description");
		   					
						EventTools.setCalendarReminderText(iEventId, 0, sTitle, sUrl, sDescription, null, null, ADMIN_DB);
						EventTools.setCalendarReminderText(iEventId, 0, sTitle, sUrl, sDescription, null, null, VIEWER_DB);
		   			}%>
		        	<table cellpadding="0" cellspacing="0" class="summaryBox summaryBoxGray" style="margin-top:15px;">
		        		<tr>
		        			<td width="25">&nbsp;</td>
							<td colspan="5"><span style="font-size:12px">Calendar Reminders</span>
								<table id="reminders_table" style="border:none; padding-top:15px;" cellpadding="0" cellspacing="0" class="whitebox contentTableList">
		        					<tr>
										<th width="75">Name</th>
	            						<th width="150">Scheduled Time</th>
										<th width="25">Add In Fields</th>
										<th width="25"></th>
									</tr>
		        				</table>
		        				<% if( account.can(Perms.User.ADDNEWCALENDARREMINDER)){%>
		        				<a class="buttonSmall buttonCreate" id="addReminder" href="javascript:void(0)">+ Add New</a>
		        				<%} %>
		        			</td>
		        		</tr>
		        	</table>
		     <%}%>
	         <% if( account.can(Perms.User.MODIFYEVENTREDIRECT) && !isWebinar && !isFolderSettingEvent ) {%>
		        <table cellpadding="0" cellspacing="0" class="summaryBox summaryBoxGray" style="margin-top:15px;">
		          	<tr> 	
		          		<td width="25">&nbsp;</td>
			            <td width="550"><span id="eventRedirectText">Event Redirect</span></td>
			            <% if(eventRedirectResponseBean!=null && eventRedirectResponseBean.isRedirectLinkPresent() ) { %>
			            	<td width="110"><a id="customizeEventRedirect" href="javascript:void(0)" class="button">Edit</a></td>
			            	<td width="70" align="right"><a id="deleteEventRedirect" href="javascript:void(0)" class="button">Remove</a></td>		
			            <% } else { %>
			            	<td width="180" align="right"><a id="customizeEventRedirect" href="javascript:void(0)" class="button">Add</a></td>
			            <% } %>
			            
						<td width="10">&nbsp;</td>
		          </tr>
		         
		        </table>
	        <%}%>
	        <% if ( sMode.equals(EventMode.prelive.toString()) || sMode.equals(EventMode.live.toString()) ) { %>
	        	<%  String sChatDesc = "Presenter Discussion is currently enabled.";
			   		String sChatButtonText = "Disable";
			   		if(currentEvent.getStatus(EventStatus.presenter_chat_disabled).value.equals("1")) {
			   			sChatDesc = "Presenter Discussion is currently disabled.";
			   			sChatButtonText = "Enable";
			   		}
			   	%>
		         <table cellpadding="0" cellspacing="0" class="summaryBox summaryBoxGray" style="margin-top:15px;">
		          	<tr> 	
		          		<td width="25">&nbsp;</td>
			            <td width="660"><span id="presenterChatText"><%=sChatDesc %></span></td>
			            <td width="105"><a id="togglePresenterChat" href="javascript:void(0)" class="button"><%=sChatButtonText %></a></td>
						<td width="10">&nbsp;</td>
		          </tr>
		         
		        </table>
		      <% } %>
		      
	   		</div>
	   	</div>
	   	
	   	<%}%><!-- End of hiding portal --> 
	<% 
		if (!isWebinar && (account.can(Perms.User.CREATEGUESTUSERS) || account.can(Perms.User.MANAGEGUESTUSERACCOUNT)) ) { 
	%>
		<div style="clear: both; height:10px"></div>
		<div class="sectionBoxWide">
	   		<div style="width:995px">
	   			<h2 id="btnShowGuestDetails" style="display:inline"><span class="arrowClosed">Guest Administrators</span></h2>&nbsp;&nbsp;<img src="/admin/images/help.png" class="helpIcon" title="Help with Guest Admin Accounts" alt="Help with Guest Admin Accounts" name="help" onclick="$.help('guest_admin_links','Help with Guest Admin Accounts');"/>
	<%	
		if(!bIsPortal){ 
	%>
				<a href="guest_permissions.jsp?<%=sQueryString%>&pfi=<%=pfo.sCacheID%>&ufi=<%=ufo.sCacheID%>" class="button" id="btnGuestPermissions" style="float:right">Set Guest Admin Permissions</a>
	<%
		} 
	%>
	   		</div>
		    <div id="showGuestDetails" style="width:995px;display:none;"><br />
	<%
		if(isFolderSettingEvent && account.can(Perms.User.MANAGESHAREDGUESTPIN)){
			boolean defaultIndivudalGuestPasswords = !currentEvent.getProperty(EventProps.default_guestadmin_unique_password).equals("0");
	%>
			<br/>
			
			<table cellpadding="0" cellspacing="0" class="summaryBox summaryBoxGray" style="margin-top:15px;">
				<tr> 	
					<td width="25">&nbsp;</td>
					<td width="660"><span id="sharedGuestPinTxt">Individual Guest Admin passwords are <%=defaultIndivudalGuestPasswords ? "enabled":"disabled" %> by default</span></td>
					<td width="105"><a id="toggleSharedGuestPin" href="javascript:void(0)" class="button"><%=!defaultIndivudalGuestPasswords ? "Enable":"Disable" %></a></td>
					<td width="10">&nbsp;</td>
				</tr>
			</table>
	<%
		}
		if(!isFolderSettingEvent){
	%>
		      	
		      	 <table id="tbl_portallist" class="sortList" style="width:1035px;" cellpadding="0" cellspacing="0">
				     <thead>
				     	<tr>
				     		<th width="550">Access Type</th>
				     		<th width="75">Accounts</th>
				     		<th>Individual Passwords</th>
				     		<th class="unsortedColumn"/>
				     		<th class="unsortedColumn"/>
				     		<th class="unsortedColumn"/>
				     	</tr>
				     </thead>
				     <tbody>
	<%
				while(portalList.hasNext()){
					portalList.nextItem();
					if(!portalList.isRegistrationOnly()){
	%>
					<tr id="guest_portal_<%=portalList.getPortalId()%>">
						<td><%=portalList.getFormattedLinkType(", ")%></td>
						<td id="guest_portal_<%=portalList.getPortalId()%>_num"><%=portalList.getPortalAdminNum()%></td>
						<td><%=Constants.EMPTY.equals(portalList.getPin()) ? "Enabled":"Disabled"%></td>
						<td>
							<input class="button manageAccessAdmins" type="button" data-id="<%=portalList.getPortalId()%>" value="Manage Admins" alt="Manage Admins"/>
						</td>
						<td>
							<button class="circleBtns editAccessBtn editBtn" data-id="<%=portalList.getPortalId()%>" title="Edit" alt="Edit"></button>
						</td>
						<td>
							<button class="redCloseBtn circleBtns deleteAccessBtn" data-id="<%=portalList.getPortalId()%>" title="Delete" alt="Delete"></button>  
						</td>
					</tr>
	<%
					}
				}
	%>
			    	 </tbody>
		         </table>
		         <br/><br/>
		         <input class="button createAccessType" type="button" value="Create New"/>
	<%
		}
	%>
		      </div>
		</div>
	<%
			} 
	%>
	      <%if(account.can(Perms.User.SUPERUSER) && isFolderSettingEvent){%>
	    	<div class="deleteTemplateDiv">
	    		<button id="delete_defaultsetting" class="buttonLarge">Delete Template</button>
	    	</div>
	      <%}%>
	<% if (!isFolderSettingEvent && !isWebinar && !bIsPortal &&(account.can(Perms.User.CREATEAUDIENCEEDITORACCOUNTS) || account.can(Perms.User.MANAGEAUDIENCEEDITORACCOUNTS))) { %>
	<div style="clear: both; height:10px"></div>
	<div class="sectionBoxWide">
	   	<div style="width:995px">
	   		<h2 id="btnshowEventEditorLinks" style="display:inline"><span class="arrowClosed">Registration Admin Accounts</span></h2>&nbsp;&nbsp;<img src="/admin/images/help.png" class="helpIcon" title="Help with Registration Admin Accounts" alt="Help with Registration Admin Accounts" name="help" onclick="$.help('guest_editor_links','Help with Registration Admin Accounts');" />
	   	</div>
		      <div id="showEventEditorLinks" style="width:995px;"><br />
		      	 <table cellpadding="0" cellspacing="0" class="summaryBox summaryBoxGray">
		          <tr> 	
		          		<td width="18">&nbsp;</td>
			            <td width="378">Registration Admins</td>
			            <% if (account.can(Perms.User.MANAGEAUDIENCEEDITORACCOUNTS)) { %>
			            	<td width="135"><a id="manageRegistrationAdmins" href="#" class="button">Manage Accounts</a></td>
			            <%} else { %>
			            	<td width="87">&nbsp;</td>
			            <%} %>
			            
			            <% if (account.can(Perms.User.CREATEAUDIENCEEDITORACCOUNTS) ) { %>
			            	<td width="85">
			            		<button id="createRegistrationAdmins" class="button"> 
			            			New Account
			            		</button>
			            	</td>
			            <%} else { %>
			            	<td width="73">&nbsp;</td>
			            <%} %>
						<td width="22">&nbsp;</td>
		          </tr>
		        </table>
		      </div>
		</div>
	<%} %>
	
	<br />
	<form name="viewevent" id="viewevent" action="<%=currentEvent.getEventUrl()%>" method="post" target="_blank">
			<input type="hidden" name="autologin" value="false"> 
	</form>
<% } %>
<jsp:include page="footertop.jsp">
	<jsp:param name="pfi" value="<%=pfo.sCacheID%>"/>
	<jsp:param name="ufi" value="<%=ufo.sCacheID%>"/>
</jsp:include>
<style type="text/css">
	#showEventAdminLinks, #showEventCalendar, #showEventEditorLinks {display:none;}
	table.summaryBox .button {float:right}
	ul.mp4Archive {list-style-image: url('images/icon_sm-download.png');line-height:18px}
	#backupNumbers{padding:10px; text-align: center;}
	/* .ui-widget-header{background-color: #006bbd !important;} */
	#phoneDetails{margin-left:5px}
	.ia_passcode {padding-bottom:10px}
	#divPhoneNumbers {padding-top:5px}
	#presenterBackupNumbersList, #audienceBackupNumbersList {padding:10px 0; font-size:10px}
</style>
<%if(bIsPortal) {%> <style>.summaryBoxThird {width:490px}.summaryBoxThird:nth-child(2){margin-right:0; width:490px}</style><%} %>
<script type="text/javascript" src="/js/jquery/jquery.quicksearch.js"></script>
<script type="text/javascript" src="/js/jquery/jquery.tablesorter.min.js"></script>
<script type="text/javascript" src="/js/jscharacterconverter.js"></script>
<script type="text/javascript" src="/js/entities.js"></script>
<script type="text/javascript" src="/js/systemtest/webrtccheck.js?<%=codetag%>"></script>
<script type="text/javascript" src="/js/systemtest/detect.js?<%=codetag%>"></script>
<script type="text/javascript" src="/js/managedservices.js?<%=codetag%>"></script>
<script type="text/javascript" src="/js/analytics.js"></script>
<% if (!isFolderSettingEvent && account.can(Perms.User.REGISTRATIONUPLOAD)) { %>
	<script src="https://unpkg.com/@flatfile/javascript@<%=flatfileVersion%>/dist/index.js" async></script>
	<script src="/js/flatfileio_utils.js?<%=codetag%><%=System.currentTimeMillis()%>"></script>
<% } %>
<script type="text/javascript">
	var reloadIntervalId = -1;
	if (<%=analyticsActive%> === true) {
		//analyticsExclude(["param_eventCostCenter"]);
		analyticsInit('<%=sUserId%>', {
			eventID: '<%=sEventId%>',
			clientID: '<%=sClientId%>'
		});	
	}
	
	function addNLCIUParamToURL() {
		if (window.location.href.indexOf('<%=Constants.NO_LASTCHECKIN_UPDATE_PARAM%>') == -1) {
			if (window.location.href.indexOf('?') == -1) {
				return window.location.href + '?<%=Constants.NO_LASTCHECKIN_UPDATE_PARAM%>';
			} else {
				return window.location.href.substring(0, window.location.href.indexOf('?') + 1) + '<%=Constants.NO_LASTCHECKIN_UPDATE_PARAM%>&' + window.location.search.substring(1);
			}
		} else {
			return window.location.href;
		}
	}

	function helpDialogOpen(){
		var open = false;
		
		$('.ui-dialog').each(function(){ 
			if($(this).css('display') == 'block'){
				open = true;
			}
		});	
		
		return open;
	}
	
	function reloadSummary(){
		if($.fancybox.isOpen === false && helpDialogOpen() === false){
			if (window.location.href.indexOf('<%=Constants.NO_LASTCHECKIN_UPDATE_PARAM%>') == -1) {
				window.location.href = addNLCIUParamToURL();
			} else {
		    	window.location.reload(true);
			}
		}
	}
<% 	if (isCloneProcessing) { %>
		$(document).ready(function() {
			setInterval(reloadSummary, 120000);
		});
<%	} else { %>
		var eventObj = <%= currentEvent.json().toString() %>;
		function viewwebcast(){
			document.forms["viewevent"].submit();
			return false;
		}
	    var varPermCanCreateGuestAdmin = <%=account.can(Perms.User.CREATEGUESTUSERS)%>
	    var varPermCanManageGuestAdmin = <%=account.can(Perms.User.MANAGEGUESTUSERACCOUNT)%>
		
		$(document).ready(function() {
			$.ajaxPrefilter(function(options, originalOptions, request) {
				if (options.url) {
					if (options.url.indexOf('?') == -1) {
						options.url += '?<%=Constants.NO_LASTCHECKIN_UPDATE_PARAM%>'; 
					} else {
						options.url += '&<%=Constants.NO_LASTCHECKIN_UPDATE_PARAM%>';
					}
				}
			});
			
			<%if(isWebinar && (!Constants.EMPTY.equals(sNumber) || !Constants.EMPTY.equals(sDefaultNumber))){ %>
				$("#summaryRightColumn_id").show();
			<%}%>
			$("#addMulticastConfig").fancybox({
				'width'				: 750,
				'height'			: 750,
				'autoScale'     	: false,
				'type'				: 'iframe',
				'hideOnOverlayClick': false,
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
			
			$("#addGlobalSetting").fancybox({
				'width'				: 500,
				'height'			: 250,
				'autoScale'     	: false,
				'type'				: 'iframe',
				'hideOnOverlayClick': false,
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
			
			$("#reviewRegistrationLink").fancybox({
				'width'				: '90%',
				'height'			: '90%',
				'autoScale'     	: false,
				'type'				: 'iframe',
				'hideOnOverlayClick': false,
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
			
			
			$("#reviewPlayerLink").fancybox({
				'width'				: '90%',
				'height'			: '90%',
				'autoScale'     	: false,
				'type'				: 'iframe',
				'hideOnOverlayClick': false,
				onCleanup			: function() {
					var frame =$("#fancybox-frame")[0];
					frame.contentWindow.location = "/admin/blank.html";
				},
				afterLoad			: function() {
					var frame =$("#fancybox-frame")[0];
					frame.contentWindow.location = "<%=sViewerBaseURL%>/viewer/event.jsp?ei=<%=iEventId%>&preview=true";
				},
	            'autoSize'			: false,
				'openSpeed'			: 0,
				'closeSpeed'        : 'fast',
			    beforeShow : function() {
			        	$('.fancybox-overlay').css({
			        		'background-color' :'rgba(119, 119, 119, 0.7)'
			        	});
			        },
				iframe: { 
				    	preload: false 
				},
				'closeClick'  		: false,
				helpers    : { 
					        'overlay' : {'closeClick': false}
				},
			});
			
			$("#btnGuestPermissions").fancybox({
				'width'				: 800,
				'height'			: 230,
				"autoscale" 		: false,
				"transitionIn" 		: "none",
				"transitionOut" 	: "none",
				"type"				: "iframe",
				"hideOnOverlayClick": false,
	            'autoSize'			: false,
				'openSpeed'			: 0,
				'closeSpeed'        : 'fast',
			    beforeShow : function() {
			        	$('.fancybox-overlay').css({
			        		'background-color' :'rgba(119, 119, 119, 0.7)'
			        	});
			        },
				iframe: { 
				    	preload: false 
				},
				'closeClick'  		: false,
				helpers    : { 
					        'overlay' : {'closeClick': false}
				},
			});
			
			
			$("#btnSetPlayerAccess").fancybox({
				"width"				: 1065,
				"height"			: 560,
				"autoScale" 		: false,
				"transitionIn" 		: "none",
				"transitionOut" 	: "none",
				"type"				: "iframe",
				"hideOnOverlayClick": false,
				'afterLoad' : function() {
				    $('#fancybox-frame').on('load', function() { // wait for frame to load and then gets it's height
				    	$('#fancybox-content').height($(this).contents().find('body').height()+100);
				     });
				},
	            'autoSize'			: false,
				'openSpeed'			: 0,
				'closeSpeed'        : 'fast',
			    beforeShow : function() {
			        	$('.fancybox-overlay').css({
			        		'background-color' :'rgba(119, 119, 119, 0.7)'
			        	});
			        },
				iframe: { 
				    	preload: false,
				},
				'closeClick'  		: false,
				helpers    : { 
					        'overlay' : {'closeClick': false}
				},
			});
			
			$("#btnManageSubscription").fancybox({
				"width"				: 900,
				"height"			: 338,
				"autoScale" 		: false,
				"transitionIn" 		: "none",
				"transitionOut" 	: "none",
				"type"				: "iframe",
				"hideOnOverlayClick": false,
				'openSpeed'			: 0,
				'closeSpeed'        : 'fast',
			    beforeShow : function() {
			        	$('.fancybox-overlay').css({
			        		'background-color' :'rgba(119, 119, 119, 0.7)'
			        	});
			        },
				'closeClick'  		: false,
					helpers    : { 
						        'overlay' : {'closeClick': false}
					},
				iframe: { 
				    	preload: false,
				},				
			});
			
			
			$("#btnFlashMulticast").fancybox({
				"width"				: 950,
				"height"			: 650,
				"autoScale" 		: false,
				"transitionIn" 		: "none",
				"transitionOut" 	: "none",
				"type"				: "iframe",
				"hideOnOverlayClick": false,
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
			
			$("#btnWindowsMulticast").fancybox({
				"width"				: 925,
				"height"			: 350,
				"autoScale" 		: false,
				"transitionIn" 		: "none",
				"transitionOut" 	: "none",
				"type"				: "iframe",
				"hideOnOverlayClick": false		,
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
			
			$("#btnRampInfo").fancybox({
				"width"				: 1000,
				"height"			: 600,
				"autoScale" 		: false,
				"transitionIn" 		: "none",
				"transitionOut" 	: "none",
				"type"				: "iframe",
				"hideOnOverlayClick": false,
				'afterLoad' : function() {},
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
			
			$("#btnHiveInfo").fancybox({
				"width"				: 900,
				"height"			: 600,
				"autoScale" 		: false,
				"transitionIn" 		: "none",
				"transitionOut" 	: "none",
				"type"				: "iframe",
				"hideOnOverlayClick": false,
				'afterLoad' : function() {},
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
			
			$.initdialog();
			
			$("#togglePresenterChat").click(function() {
				togglePresenterChat();
			});
			
			$("#toggleSharedGuestPin").click(function(){
			   toggleSharedGuestPin(); 
			});
			
			$("input[name='radEnableBackup']").change(function() {
				toggleDisplayBackupBridge($(this).val());
			});		
			
			getReminders();
			
			$("#addReminder").click(function() {
				customizeReminder("addnew");
			});
			
			$("#customizeEventRedirect").click(function() {
				customizeEventRedirect();
			});
			$("#deleteEventRedirect").click(function() {
				deleteEventRedirect();
			});
			
			$("#confcastDataLink").click(function() {
				confcastDataLink();
			});
			
			$("#manageVideoCMSBtn").click(function() {
				$.fancybox({
					beforeLoad     :   function() {
						this.href= '/admin/videocms_frag.jsp?<%=sQueryString%>&<%=Constants.RQPFOID%>=<%=pfo.sCacheID%>&<%=Constants.RQUFOID%>=<%=ufo.sCacheID%>';
				    },				
					'width'				: 500,
					'height'			: 250,
			        'autoScale'     	: true,
			        'transitionIn'		: 'none',
					'transitionOut'		: 'none',
					'type'				: 'iframe',
					"hideOnOverlayClick": false,
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
				    iframe: { preload: false }
				});
			});
			
			$("#requestEventServicesBtn").click(function() {
				let postParams = {
					<%=Constants.RQUSERID%>: '<%=StringTools.n2s(request.getParameter(Constants.RQUSERID))%>',
					<%=Constants.RQSESSIONID%>: '<%=StringTools.n2s(request.getParameter(Constants.RQSESSIONID))%>',
					<%=Constants.RQEVENTID%>: '<%=currentEvent.eventid%>',
					<%=EventProps.pgi_client_id.toString()%>: '<%=currentEvent.getProperty(EventProps.pgi_client_id)%>'
				}
				
				stopPageRefresh();
				managedServices.openWindow(postParams, <%=managedServicesEventDataJSON.toString()%>, '<%=StringEscapeUtils.escapeEcmaScript(iglooManagedServicesUrl)%>', 'startPageRefresh');
			});
			
			$("#btnRegUpload").click(function() {
				stopPageRefresh();
				flatfileioUtils.openWindow('<%=pfo.iEventID%>', '<%=ufo.sUserID%>', 'startPageRefresh');
			});
			
			displayPlayerStatus();
			
			startPageRefresh();
			
			loadMulticastConfig();
			
			$(".sectionBoxWide").on('click', '.multicastbutton', function(event){
				var configId = $(this).closest("tr").find("td.configid").text();
				OpenEditMulticast("/admin/fmsconfig/configurator.jsp?<%=sQueryString%>&configid=" + configId);
			});
			
			$(".sectionBoxWide").on('click', '.multicastdelete', function(event){
				var configId = $(this).closest("tr").find("td.configid").text();
				deleteMulticastConfig(configId);
			});
			<% if((sMode.equals("prelive") || sMode.equals("live"))){%>
			<%if(currentEvent.isEventIntegratedAudio()){%>
			displayAudioBridgeList();
			$(document).on("click",".bridgeRetry",function(event){
				var retryButton = this;
				$(retryButton).text("Processing...");
				$(retryButton).addClass("disabledButton");
				var task = ($(this).attr("data-bridgetype") == "viewer") ? "setAudienceBridge" : "retryCreate";
				if($(this).attr("data-bridgetype") == "viewer"){
					bridgeRetry("setAudienceBridge",retryButton);
				}else{
					bridgeRetry("retryCreate",retryButton);				
				}
			});
			
			$(document).on("click","#phoneDetails",function(event){
				  $("#backupNumbers").dialog({
					 	width:432,			  	
			            modal: true,
			            resizable: false,
			            title: "Backup Bridge Details",
			            position:{my:"center top",at:"center top+225", of:"body"},
			            close: function(event, ui) {
			                $("#backupNumbers").hide();
			            }
			       });
			});
			
			function bridgeRetry(task,retryButton){
				$.ajax({
					type: "POST",
					data : "<%=sQueryString%>&fn=" + task + "&id=<%=iEventId%>&pr=<%=Bridge.Provider.ZIPDX.value()%>",
					url: "proc_audiobridge.jsp",
					dataType: "json",
					success: function(data){
						if(data.success){
							$("#presenterNumbers").html("");
							$("#audienceNumbers").html("");
							displayAudioBridgeList();
							$.success("Successfully created bridge","","icon_check.png");
							setTimeout(function(){
								$("#alertDialog").dialog("close");
								reloadSummary();
							},2000);
						}else{
							$(retryButton).text("Retry");
							$(retryButton).removeClass("disabledButton");
							$.alert("Oops! Something went wrong","There was an error creating the bridge. Please try again.","icon_error.png");
						}
					},
					error: function(xmlHttpRequest, status, errorThrown){
				        	$.alert("Oops! Something went wrong","There was an error processing your request. Please try again.","icon_error.png");
				        	$(retryButton).text("Retry");
							$(retryButton).removeClass("disabledButton");
					         return false;
				    }
				});
			}
			<%}else if(currentEvent.allowListenByPhone()){%>
				displayBridge("",false,<%=Constants.PhoneBridgeType.PRIMARY.dbValue()%>);		
			<%}%>
			<%}%>
			<% if ("1".equals(conf.get("nanoextension_enabled", "1"))) { %>
				if (navigator.webkitGetUserMedia && systemDetect.browser == 'Google Chrome' && eventObj.properties.webrtc_screenshare == '1') {
					setTimeout("checkScreenExt('extension-is-installed')",1000);
				}
			<% } %>
	
			$('#tbl_portallist').tablesorter({
				cssHeader: 'sortColumn',
				cssAsc: 'sortColumnZA',
				cssDesc: 'sortColumnAZ'
			});
			
			$('.managePortalAdmins').fancybox({
				beforeLoad     :   function() {
					this.href= '';
			    },				
				'width'				: 900,
				'height'			: '95%',
		        'autoScale'     	: false,
		        'transitionIn'		: 'none',
				'transitionOut'		: 'none',
				'type'				: 'iframe',
				"hideOnOverlayClick": false,
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
			    iframe: { preload: false }
			});
			
			$('.createAccessType').fancybox({
				beforeLoad     :   function() {
					this.href= '/admin/create_access_type.jsp?<%=sQueryString%>';
			    },				
				'width'				: 800,
				'height'			: 245,
		        'autoScale'     	: true,
		        'transitionIn'		: 'none',
				'transitionOut'		: 'none',
				'type'				: 'iframe',
				"hideOnOverlayClick": false,
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
			    iframe: { preload: false }
			});
			
			$('.manageAccessAdmins').fancybox({
				beforeLoad     :   function() {
					this.href= '/admin/manage_access_admins.jsp?<%=sQueryString%>&<%=Constants.RQGUESTACCESSID%>='+$(this.element).attr("data-id");
			    },				
				'width'				: 950,
				'height'			: 508,
		        'autoScale'     	: true,
		        'transitionIn'		: 'none',
				'transitionOut'		: 'none',
				'type'				: 'iframe',
				"hideOnOverlayClick": false,
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
			    iframe: { preload: false }
			});
			
			$('.editAccessBtn').fancybox({
				beforeLoad     :   function() {
					this.href= '/admin/manage_guest_access.jsp?<%=sQueryString%>&<%=Constants.RQGUESTACCESSID%>='+$(this.element).attr("data-id");
			    },				
				'width'				: 935,
				'height'			: 600,
		        'autoScale'     	: true,
		        'transitionIn'		: 'none',
				'transitionOut'		: 'none',
				'type'				: 'iframe',
				"hideOnOverlayClick": false,
		        'autoSize'			: false,
				'openSpeed'			: 0,
				'closeSpeed'        : 'fast',
				'closeClick'  		: false,
				helpers    : { 
					        'overlay' : {'closeClick': false},
					        title:  null
					        
				},
			    beforeShow : function() {
			        	$('.fancybox-overlay').css({
			        		'background-color' :'rgba(119, 119, 119, 0.7)'
			        	});
			        },
			    iframe: { preload: false }
			});
			
			$('.deleteAccessBtn').fancybox({
				beforeLoad     :   function() {
					this.href= '/admin/delete_guest_access.jsp?<%=sQueryString%>&accessid='+$(this.element).attr("data-id");
			    },				
				'width'				: 900,
				'height'			: 450,
		        'autoScale'     	: true,
		        'transitionIn'		: 'none',
				'transitionOut'		: 'none',
				'type'				: 'iframe',
				"hideOnOverlayClick": false,
		        'autoSize'			: false,
				'openSpeed'			: 0,
				'closeSpeed'        : 'fast',
				'closeClick'  		: false,
				helpers    : { 
					        'overlay' : {'closeClick': false},
					        title:  null
				},
			    beforeShow : function() {
			        	$('.fancybox-overlay').css({
			        		'background-color' :'rgba(119, 119, 119, 0.7)'
			        	});
			        },
			    iframe: { preload: false }
			});
			
			$('#createRegistrationAdmins').fancybox({
				beforeLoad     :   function() {
					this.href= '/admin/create_registration_admins.jsp?<%=sQueryString%>';
			    },				
				'width'				: 900,
				'height'			: 450,
		        'autoScale'     	: false,
		        'transitionIn'		: 'none',
				'transitionOut'		: 'none',
				'type'				: 'iframe',
				"hideOnOverlayClick": false,
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
			    iframe: { preload: false }
			});
			
			$("#manageRegistrationAdmins").fancybox({
				beforeLoad     :   function() {
					this.href= '/admin/manage_registration_admins.jsp?<%=sQueryString%>';
			    },				
				'width'				: 900,
				'height'			: 400,
		        'autoScale'     	: false,
		        'transitionIn'		: 'none',
				'transitionOut'		: 'none',
				'type'				: 'iframe',
				"hideOnOverlayClick": false,
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
			    iframe: { preload: false }
			});
			
		});
		$('#reminders_table').delegate('.customizeReminder','click', function() {
			var getId = $(this).attr('id');
			if(getId == ""){
				getId = 0;
			}
			customizeReminder(getId);       
		});
		
		function startPageRefresh() {
			reloadIntervalId = setInterval(reloadSummary, 120000);
		}
		
		function stopPageRefresh() {
			clearInterval(reloadIntervalId);
		}
		
		function showLocalNumbers(bridgeType,bridgePriority,target){
			var displayBridge = bridgeNumbers[bridgeType][bridgePriority];
			var countryList = displayBridge.bridge.countries;
	       	var defaultCountry = displayBridge.defaultCountry;
	       	var isPresenter = bridgeType=="presenter";
	       	var sIANumbers = "";       	
	       	var bShow_ia_aud_tollfree = false;
	       	var otherCountryNum;
			for(i in countryList) {			
	  				var c = countryList[i];
	  				var tollNumber = c.toll;
	  				var tollFreeNumber = c.tollfree;
	  				
	  				if(c.country_code=="US" && isPresenter){
	  					tollNumber = c.tollfree;
	  					tollFreeNumber = c.toll;
	  					otherCountryNum = c.toll;
	  				}
	  				
	  				if(countryList.length>1 || (tollNumber && tollFreeNumber)){  					
	  					bShowAddNumbers = true;
		    			sIANumbers+=("<div class='ia_country_tr'><span class='ia_country'>" + c.country_desc + "</span><span class='ia_toll_number'>");
		    			
			    		if(tollNumber){
			    			sIANumbers+=(tollNumber.number_formatted_international);
			    			bShow_ia_aud_toll = true;
			    		}else{				    			
			    			sIANumbers+=("--");
			    		}
			    		
			     		sIANumbers+=("</span><span class='ia_tollfree_number'>");
			     		if(tollFreeNumber){
			     			sIANumbers+=(tollFreeNumber.number_formatted_international);
			     			bShow_ia_aud_tollfree = true;
			    		}else{
			    			sIANumbers+=("--");
			    		}
			     		
			       		sIANumbers+=("</span></div>");
	    		}
	  		}
			
			if(isPresenter){
				sIANumbers+=("<div class='ia_country_tr'><span class='ia_country'>Other</span><span class='ia_toll_number'>" + otherCountryNum.number_formatted_international + "</span><span class='ia_tollfree_number'></span></div>");
			}
			
			var numberListHtml = '<span class="ia_country"><strong>Country</strong></span> <span class="ia_toll_number"><strong>Number</strong></span> <span class="ia_tollfree_number" ><strong>Toll-Free Number</strong></span><div id="numberList">' + sIANumbers + '</div>';
			target.html(numberListHtml);
			
			var isWider = false;
			if(isPresenter || !bShow_ia_aud_tollfree){
				target.find(".ia_tollfree_number").hide();
				isWider = false;
			}else{
				target.find(".ia_tollfree_number").show();
				isWider = true;
			}
			$("#divPhoneNumbers").show();
			return isWider;
		}		
			
			var bridgeNumbers;
			function displayAudioBridgeList(){
				$.ajax({
					type: "GET",
					data : "<%=sQueryString%>&fn=getAllBridge&id=<%=iEventId%>",
					url: "proc_audiobridge.jsp",
					dataType: "json",
					success: function(data){
						bridgeNumbers = data;
											
						if(data.presenter.length<2){
							//Going to display fail messages
							$("#backupNumbersStatus").html("");
							$("#phoneDetails").hide();
						}else{
							$("#phoneDetails").show();
						}
						<%if(currentEvent.isEventAudio()){%>
							displayBridge(data.presenter[<%=Constants.PhoneBridgeType.PRIMARY.dbValue()%>],true,<%=Constants.PhoneBridgeType.PRIMARY.dbValue()%>);
							<%if(currentEvent.isAdvanceAudio()){%>
								displayBridge(data.presenter[<%=Constants.PhoneBridgeType.BACKUP.dbValue()%>],true,<%=Constants.PhoneBridgeType.BACKUP.dbValue()%>);
							<%}%>
						<%}%>	
						<%if(currentEvent.allowListenByPhone()){%>											
							<%if(currentEvent.isAudienceBridgeCustom()){%>
								displayBridge("",false,<%=Constants.PhoneBridgeType.PRIMARY.dbValue()%>);
							<%}else if(currentEvent.isAudienceBridgeClickToJoin()){%>
								displayBridge("",false,<%=Constants.PhoneBridgeType.PRIMARY.dbValue()%>);
							<%}else if(currentEvent.isAudienceBridgeDefault() && currentEvent.isEventAudio()){%>
								displayBridge(data.viewer[<%=Constants.PhoneBridgeType.PRIMARY.dbValue()%>],false,<%=Constants.PhoneBridgeType.PRIMARY.dbValue()%>);
								<%if(currentEvent.isAdvanceAudio()){%>
								displayBridge(data.viewer[<%=Constants.PhoneBridgeType.BACKUP.dbValue()%>],false,<%=Constants.PhoneBridgeType.BACKUP.dbValue()%>);
								<%}%>
							<%}else{%>
							
							<%}%>
						<%}%>
						
						$(".moreNumbers").click(function(){					    
						  	var bridgeType = $(this).attr("data-bridgetype");
						  	var bridgePriority = $(this).attr("data-priority");
						  	
						  	if(bridgePriority==<%=Constants.PhoneBridgeType.PRIMARY.dbValue()%>){
						  		var targetDiv = (bridgeType=='presenter') ? "#presenterPrimaryNumbersList" : "#audiencePrimaryNumbersList";
						  		var isWider = showLocalNumbers(bridgeType,bridgePriority,$(targetDiv));
						  		var dialogWidth = isWider ? 420 : 305;
								 $(targetDiv).dialog({
									  	width:dialogWidth,
							            modal: true,
							            autoResize:true,
							            resizable: false,
							            maxHeight: 500,
										position:{my:"center top",at:"center top+225", of:"body"},
							            title: bridgeType == "presenter" ? "Presenter Numbers" :  "Audience Numbers",
							            close: function(event, ui) {
							                $(targetDiv).hide();
							            }
							     });	
						  	}else{
						  		var target = (bridgeType == "presenter") ? $("#presenterBackupNumbersList") : $("#audienceBackupNumbersList");
						  		showLocalNumbers(bridgeType,bridgePriority,target);
						  	}
							 
						  	return false;
					  	});
					},
					error: function(xmlHttpRequest, status, errorThrown){
				        	$.alert("Oops! Something went wrong","There was an error processing your request. Please try again.","icon_error.png");
					         return false;
				    }
				});	 
			}
		
			var isBridgeCustom = <%=currentEvent.isAudienceBridgeCustom()%>;
			var isClickToJoin = <%=currentEvent.isAudienceBridgeClickToJoin()%>;
			function displayBridge(displayBridge,isPresenter,priority){
				console.log("displayBridge " + displayBridge + " / " +  isPresenter + " / " + priority);
				var bridgeType = isPresenter ? "presenter" : "viewer";
		       	if(isBridgeCustom && !isPresenter){
		       		var sDefaultNumber = eventObj.properties.bridge_number;
		       		if(sDefaultNumber==""){
		       			$("#divPhoneNumbers").hide();
		       		}else{
		       			$("#audienceNumbers").append(sDefaultNumber);	
			       		$("#divPhoneNumbers").show();
		       		}
		       	}else if(isClickToJoin && !isPresenter){
		       		<%
		       	   		if(currentEvent.isAudienceBridgeClickToJoin()){
		       	   			HashMap<String, String>  hmAllPlayerText = currentEvent.getAllPlayerText("en-us");
		       				String sClicktojoinlabel  = currentEvent.getClickToJoinInfoByKey(Constants.ClickToJoinKeys.SECTION_LABEL);
					     	if(Constants.DEFAULT_PLACEHOLDER.equals(sClicktojoinlabel)){
					      		sClicktojoinlabel = StringEscapeUtils.escapeHtml4(hmAllPlayerText.get("opt_c2j_label"));
					      	}
					      	String sClicktojoinurl  = currentEvent.getClickToJoinInfoByKey(Constants.ClickToJoinKeys.CALL_ME_URL);
					      	String sDialinurl  = currentEvent.getClickToJoinInfoByKey(Constants.ClickToJoinKeys.DIAL_IN_URL);
					      %>	
					      	var c2jJSON = <%=currentEvent.getClickToJoinJSON()%>;
				       		var sDefaultNumber = "<%=sClicktojoinlabel%> <br/> <a href=\"<%=sDialinurl%>\" target=\"_blank\">Dial-In</a>&nbsp;&nbsp;<a href=\"<%=sClicktojoinurl%>\" target=\"_blank\">Call me</a>";
				       		$("#audienceNumbers").append(sDefaultNumber);	
				       		$("#divPhoneNumbers").show();	
		       			<%}%>
		       		
		       	
		       	}else if(displayBridge!=undefined && displayBridge!=""){
		        	var countryList = displayBridge.bridge.countries;
		        	var defaultCountry = displayBridge.defaultCountry;
		        	var sPin = isPresenter ? displayBridge.bridge.hostPin : displayBridge.bridge.audiencePin;
		        	var defaultTollFreeFlag  = "toll";
		        	
		        	if(!isPresenter){
		        		defaultTollFreeFlag  = displayBridge.defaultNumberType.toLowerCase();
		        	}
		        	
		        	var sIANumbers = "";
		        	var defaultNumber = "";
		        	var bShowAddNumbers = false;
		        	var usaPhoneNumbers = "";
		   			for(i in countryList) {
		   				var c = countryList[i];
		   				
		   				if(isPresenter){
		   					defaultTollFreeFlag = c.country_code==="US" ? "tollfree" : "toll";
							if(c.country_id=="<%=geoCountryId%>"){
					    		sDefaultNumber = "<div class='numberContainer'><span class='ia_default_number'>"  + c[defaultTollFreeFlag].number_formatted_international +  "</span><span class='ia_default_country'>(" + c.country_desc + ")</span>";
					    	}
		   				}else{
		   					if(""==defaultNumber && defaultCountry == c.country_code &&  c[defaultTollFreeFlag]){
				    			sDefaultNumber = "<div class='numberContainer'><span class='ia_default_number'>"  + c[defaultTollFreeFlag].number_formatted_international +  "</span><span class='ia_default_country'>(" + c.country_desc + ")</span>";
				    		}	
		   				}
		   				
		   				if(c.country_code==="US"  &&  c[defaultTollFreeFlag]){
		   					usaPhoneNumbers = "<div class='numberContainer'><span class='ia_default_number'>"  + c[defaultTollFreeFlag].number_formatted_international +  "</span><span class='ia_default_country'>(" + c.country_desc + ")</span>";		   						
		   				}		   				
		   				
		   				if(countryList.length>1 || (c.toll && c.tollfree)){
		   					bShowAddNumbers = true;		    			
			    		}
		   			}
		   			
		   			if(bShowAddNumbers){
		   				if(sDefaultNumber==undefined){
							sDefaultNumber = usaPhoneNumbers;
						}
		   				sDefaultNumber = sDefaultNumber + '<button class="buttonSmall btnPresenter moreNumbers" data-bridgetype="' + bridgeType + '"  data-priority="' + priority + '">More Numbers</button>';
				   		
			    	}
		   			
		   			if(sDefaultNumber!=""){
						sDefaultNumber = sDefaultNumber + "<br><span class='ia_passcode'>"+ "Passcode" +": " + sPin + "#  </span>";
						sDefaultNumber = sDefaultNumber + "</div>";
					}	    
		   			
		   			if(isPresenter){
		   				if(priority==1){
		   					$("#presenterBackupNumbers").append(sDefaultNumber);	
		   				}else{
		   					$("#presenterNumbers").append(sDefaultNumber);
		   				}	   				
		   			}else{
		   				if(priority==1){
		   					$("#audienceBackupNumbers").append(sDefaultNumber);
		   				}else{	
		   					$("#audienceNumbers").append(sDefaultNumber);
		   				}
		   			}   			
		   			$("#divPhoneNumbers").show();
		       	} else{
		       		//bridge wasnt created show warning
		       		var bridgeName = isPresenter? "Presenter" : "Audience" ;
		       		$("#backupNumbersStatus").append("<div class='bridgeCreateFailed' style='clear:left;padding-top:5px'><img style='vertical-align: middle;' src='/admin/images/icon_alert.png' width='20' height='20'> Failed to create backup bridge <button data-bridgetype='" + bridgeType + "'  data-priority=" + priority + " class='buttonSmall bridgeRetry'>Retry</button></div>");
		       		$("#divPhoneNumbers").show();
		       	}
			}
		
		function reloadSummaryAfterRedirectSetting(){
			if (window.location.href.indexOf('<%=Constants.NO_LASTCHECKIN_UPDATE_PARAM%>') == -1) {
				window.location.href = addNLCIUParamToURL();
				return;
			}
			window.location.reload(true);	
		}
		
		//Following is for resend guest link buttons 
		function ResnedGuestAlert(guestlink){
			var objButton = {"Cancel": function(){$("#alertDialog").dialog("close");},"Ok":function(){OpenResendGuest(guestlink);}};
			$.confirm("Warning! Resending login details will reset account passwords","On the next page, select the accounts for which you would like to resend login details. For security purposes, the passwords for all selected accounts will automatically be reset by the system.",objButton,"");
		}
		
		function OpenEditMulticast(url){
			 $("#alertDialog").dialog("close");
			 $.fancybox({
				 	'width'				: '85%',
					'height'			: 850,
			        'autoScale'     	: false,
			        'transitionIn'		: 'none',
					'transitionOut'		: 'none',
					'type'				: 'iframe',
					'href' 				: url,
					'hideOnOverlayClick': false,
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
		}
		
		function OpenResendGuest(url){
			 $("#alertDialog").dialog("close");
			 $.fancybox({
					'width'				: 700,
					'height'			: 320,
			        'autoScale'     	: false,
			        'transitionIn'		: 'none',
					'transitionOut'		: 'none',
					'type'				: 'iframe',
					'href' 				: url,
					'hideOnOverlayClick': false,
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
		}
		
		function customizeReminder(id) {
			this.id = id;
			var url = "edit_reminder.jsp?<%=pfo.toQueryString()%>&<%=ufo.toQueryString()%>&reminderid="+id;
			$.fancybox({
				'width'				: 815,
				'height'			: 400,
		        'autoScale'     	: false,
		        'transitionIn'		: 'none',
				'transitionOut'		: 'none',
				'type'				: 'iframe',
				'href' 				: url,
				'hideOnOverlayClick': false,
				'scrolling'			: 'no',
				'beforeClose'			: function(){
					getReminders();
				},
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
		}
		
		function getReminders(){
			var eventId = <%=iEventId%>;
			var reminderStart = "<%=currentEvent.getPrettyStartDateFormatted()%>";
			var reminderEnd = "<%=currentEvent.getPrettyEndDateFormatted()%>";
			var isPrelive = <%=sMode.equals(EventMode.prelive.toString())%>;
			var isLive = <%=sMode.equals(EventMode.live.toString())%>;
			var to = "  to  ";
			var buttonHtml = "";
		    var dataString = {ei: eventId};
			$.ajax({ type: "POST",
		             url: "/admin/proc_reminders.jsp",
		             data: dataString,
		             dataType: "json",
		             success: function(jsonResult) {
		  					if(jsonResult.ReminderList.length > 0){
		  						 $('.reminder_data').remove();
		  						 var reminderID = 0;
		  						 var reminderName = "";
		  						 $.each(jsonResult.ReminderList, function (i, item) {
		  							if(item.reminderid == 0){
		  								if(!isPrelive && !isLive){
		  									reminderStart = "This reminder is expired. Please create a new reminder"
		  									reminderEnd = "";
		  									to = "";
		  								}else{
		  									buttonHtml = "<a class=\"customizeReminder button\" id=\""+item.reminderid+"\" href=\"javascript:void(0)\">Edit</a>";
		  								}
		  								reminderID = "";
		  								reminderName = "Default Reminder"
		  							}else{
		  								reminderID = item.reminderid;
		  								reminderName = "Custom Reminder"
		  								reminderStart = item.reminderstartdate;
		  								reminderEnd = item.reminderenddate;
		  								to = "  to  ";
		  								buttonHtml = "<a class=\"customizeReminder button\" id=\""+item.reminderid+"\" href=\"javascript:void(0)\">Edit</a>";
		  							}
		  					        $('<tr class=\"reminder_data\">').append(
		  					        $('<td>').text(reminderName+" "+reminderID),
		  					        $('<td>').text(reminderStart + to + reminderEnd),
		  					        $('<td>').text("__REMINDER"+reminderID+"__ __REMINDERBUTTON"+reminderID+"__"),
		  					        $('<td>').html(buttonHtml)).appendTo('#reminders_table');
		  					    });
		  					}		
		             }
		    });
		}
		
		function confcastDataLink(){
			var url = "edit_confcastdatalink.jsp?<%=pfo.toQueryString()%>&<%=ufo.toQueryString()%>";
			$.fancybox({
				'width'				: 850,
				'height'			: 120,
		        'autoScale'     	: false,
		        'transitionIn'		: 'none',
				'transitionOut'		: 'none',
				'type'				: 'iframe',
				'href' 				: url,
				'hideOnOverlayClick': false,
				'scrolling'			: 'no',
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
		}
		function customizeEventRedirect() {
			var url = "edit_event_redirect.jsp?<%=pfo.toQueryString()%>&<%=ufo.toQueryString()%>";
			$.fancybox({
				'width'				: 850,
				'height'			: 200,
		        'autoScale'     	: false,
		        'transitionIn'		: 'none',
				'transitionOut'		: 'none',
				'type'				: 'iframe',
				'href' 				: url,
				'hideOnOverlayClick': false,
				'scrolling'			: 'no',
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
		}
		
		function deleteEventRedirect() {
			$.ajax({
				type: "POST",
				data : 'ei=<%=sEventId%>&action=delete&<%=sQueryString %>',
				url: "proc_edit_event_redirect.jsp",
				dataType: "json",
				success: function(jsonResult){
					if(jsonResult!=undefined){
				        jsonResult = jsonResult[0];
				        if(!jsonResult.success){
				        	$.alert("Oops! Something went wrong","There was an error processing your request. Please try again.","icon_error.png");	
				        }else{
				        	reloadSummaryAfterRedirectSetting();	
				        }
					}
				},
				error: function(xmlHttpRequest, status, errorThrown){
			        	$.alert("Oops! Something went wrong","There was an error processing your request. Please try again.","icon_error.png");
				         return false;
			    }
			});		
		}
		
		function displayPlayerStatus(){
			$.ajax({
				type: "POST",
				data : "<%=sQueryString%>",
				url: "proc_playerstatus.jsp",
				dataType: "json",
				success: function(data){
					$("#playerStatus").html(data.player_status);
				},
				error: function(xmlHttpRequest, status, errorThrown){
			        	$.alert("Oops! Something went wrong","There was an error processing your request. Please try again.","icon_error.png");
				         return false;
			    }
			});	 
		}
		 
		var eventObj = <%= eventJson.toString() %>;
		var varScheduleID = '<%=sScheduleID%>';
		var customReg = <%= String.valueOf(customReg) %>;
		var regFields = <%= regCols.toString()%>;
		//var varSurveyJSON = '';
		var jsonValues = '';
		var isFolderSettingEvent = <%=isFolderSettingEvent%>;
		var isPortal = <%=bIsPortal%>;
		
		$(document).ready(function() {
			if(!isFolderSettingEvent && !isPortal){
					liveScheduler();
			}
			eventSummary();
			$('#editSet').click(function(){
				var dataString = 'ei='+ eventObj.properties.eventid + '&presenterId=1';
				$.ajax({
					type: "POST",
					url: "proc_summary.jsp",
					data: dataString,
					dataType: "json",
					success: getResult
				});
			});
			
			$('#convertToOd').click(function(){
				var dataString = "ei=" + eventObj.id + "&ui=<%= ufo.sUserID%>&si=<%=ufo.sSessionID%>";
				$.ajax({
					type: "POST",
					url: "proc_converttood.jsp",
					data: dataString,
					dataType: "json",
					success: getResult_od
				});
			});
			
			
			
			$("#btnshowOptionalSettings").click(function() {
				$("#optionalSettings").toggle('fast');	
				$('#btnshowOptionalSettings span.arrowClosed').toggleClass('arrowOpened')
			});
			
			
			$("#optionalSettings").hide();	
	
			$("#btnshowEventCalendar").click(function () {
	      		$("#showEventCalendar").toggle();
				$('#btnshowEventCalendar span.arrowClosed').toggleClass('arrowOpened')
	    	});
			
			$("#btnshowEventEditorLinks").click(function () {
	      		$("#showEventEditorLinks").toggle('fast');
				$('#btnshowEventEditorLinks span.arrowClosed').toggleClass('arrowOpened')
	    	});
			
			$("#btnShowGuestDetails").click(function () {
		      		$("#showGuestDetails").toggle('fast');
					$('#btnShowGuestDetails span.arrowClosed').toggleClass('arrowOpened')
		    });
			
			
			$("#aLaunchLivestudio").click(function() {
				if(eventObj.properties.contenttype != "LIVE") {
					$.alert("Hang on.","The Live Studio is not accessible because this event is On-Demand Only.","icon_alert.png");
					return;
				}
				var frmData = $("#livestudioForm").serialize();
				var w,h;
				w = 1240;
				h = 820;
				var lsUrl;
				
				//Resize the popup based on screen resolution
				if ((screen.width>=1920)&&(screen.height>=1080)) {
					w = 1820;
					h = 920;
				} else if ((screen.width>=1600)&&(screen.height>=900)) {
					w = 1500;
					h = 860;
				} else if ((screen.width>=1440)&&(screen.height>=900)) {
					w = 1380;
					h = 860;
				}
				
				if(eventObj.properties.resourcetype == "WEBCAM_ADVANCED") {
					lsUrl = "plugin.jsp?" + frmData + "&forward=livestudio";
				} else {
					lsUrl = "<%=sLivestudioFolder%>/Livestudio.jsp?" + frmData + "&src=" + window.location.host;
				}
				
				window.open(
						lsUrl,
						"presenterstudio",
						"width=" + w +", height=" + h + ",menubar=0,toolbar=0,status=0,location=0,scrollbars=1,resizable=1");
	
				});
				
			$("#showcaseAudioMsg").on("click",function(){
				var url = "/admin/feature_showcase/custom_showcase_msg.jsp?<%=pfo.toQueryString()%>&<%=ufo.toQueryString()%>";
				$.fancybox({
					'width'				: 780,
					'height'			: 562,
			        'autoScale'     	: false,
			        'transitionIn'		: 'none',
					'transitionOut'		: 'none',
					'type'				: 'iframe',
					'href' 				: url,
					'hideOnOverlayClick': false,
					'scrolling'			: 'no',
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
			});
				
			
			$("#btnOpenOdEvent").click(function() {
				toggleOdEvent();			
			});
			
			$("#btnCloseOdEvent").click(function() {
				toggleOdEvent();
			});
			
			$("#btnOdStudio").click(function() {
				openOdStudio();
			});
			
			$("#btnLiveStudioLog").click(function(){
				getLiveStudioLog();
			});
			
			$("#btnAudienceDetails").click(function() {
				var url = "/admin/view_audience.jsp?ei=" + eventObj.id + "&ui=<%= ufo.sUserID%>&si=<%=ufo.sSessionID%>";
				window.open(
						url,
						"audience_detail",
						"resizable=1,width=1024,height=700,scrollbars=1,menubar=0");
			});
			
			$("#btnAudienceMsg").click(function() {
				var url = "/admin/message_to_viewers.jsp?ei=" + eventObj.id + "&ui=<%= ufo.sUserID%>&si=<%=ufo.sSessionID%>";
				window.open(
						url,
						"audience_msg",
						"resizable=1,width=600,height=400,scrollbars=1,menubar=0");
			});
			
			$("#btnManageQA").click(function() {
				var url = "/admin/manage_qa.jsp?ei=" + eventObj.id + "&ui=<%= ufo.sUserID%>&si=<%=ufo.sSessionID%>&fi=<%=ufo.sFolderID%>";
				window.open(
						url,
						"manage_qa",
						"resizable=1,width=1024,height=700,scrollbars=1,menubar=0");
			});
			
			
	
			<%if(account.can(Perms.User.MANAGECUSTOMFOOTER)){ %>
				var tmpEventcontentNote = $("#eventcontent_note").text();
				if(eventObj.properties.custom_footer != undefined){
					if(eventObj.properties.custom_footer.length > 0){
						tmpEventcontentNote = tmpEventcontentNote + " Custom Footer Enabled," ;
						$("#eventcontent_note").text(tmpEventcontentNote);
					}
				}
			<% }%>
		  <%if(!bIsTradeShowLite){ %>
			getSurveyDetail('ei='+ eventObj.properties.eventid);
		  <% }%>
		  if (isPortal) {
		  	getPortalSegmentCount();
		  }
		  
		  
		});
		
		
		function getSurveyDetail(dataString)
		{
			//alert('dataString = ' + dataString);
			$.ajax({
				type: "POST",
				url: "proc_surveysummary.jsp",
				data: dataString,
				dataType: "json",
				success: getSurveyResultJson,
				error: displaySurveyError
			});
		}
		
		function displaySurveyError( a,b,c )
		{
			//alert(a.has_post_event_survey+ " - " + b+ " - " +c )
		}
		
		function getSurveyResultJson( jsonSurveyResult )
		{
			var tmpEventcontentNote = $("#eventcontent_note").text();
			<%if (account.can(Perms.User.SUPERUSER) || account.can(Perms.User.MANAGESURVEYS)) { %>
			var resultJson =  jsonSurveyResult;
			
			
				if(resultJson.poll>0){
					tmpEventcontentNote = tmpEventcontentNote + resultJson.poll + ' In-event survey,';
				}
				
				if(resultJson.attendance>0 && resultJson.score_type!="1"){
					tmpEventcontentNote = tmpEventcontentNote + resultJson.attendance + ' Attendance survey,';
				}
				
				if(resultJson.survey>0){
					tmpEventcontentNote = tmpEventcontentNote + resultJson.survey + ' Post-event survey';
				}
				
				if(resultJson.poll==0 && resultJson.survey==0 && resultJson.attendance==0){
					tmpEventcontentNote = tmpEventcontentNote+' No surveys';
				}
			<%}%>
			
			
			$("#eventcontent_note").text(tmpEventcontentNote);
		}
		
		function getResult(jsonResult){
			jsonResult = jsonResult[0];
			if (!jsonResult.success) {
				var frmError = "";
	            var frmName = "frm_eventSummary";
	            for (i=0; i<jsonResult.errors.length; i++) {
	            	var curError = jsonResult.errors[i];
	             	frmError = frmError + curError.message + "<br>";
	            }
	            if(frmError!=""){
	                $.alert("Hmm. Something isn't right. ",frmError,"icon_alert.png");
	            }
	            return false;
	        }else{
	        	jsonValues = jsonResult;
	        	if(jsonValues.broadcastingID == '1'){
	            	$.alert("Not allowed to edit event schedule","Event settings, including scheduling, cannot be accessed while the presentation is connected in the Live Studio.","");
	    			return false;
	      		}else {
	        		 window.location.href = '/admin/schedule_event.jsp?<%=sQueryString %>';
	        	}
	        }
		}
		function getResult_od(jsonResult){
			jsonResult = jsonResult[0];
			if (!jsonResult.success) {
				var frmError = "";
	            var frmName = "messageBar";
	            for (i=0; i<jsonResult.errors.length; i++) {
	            	var curError = jsonResult.errors[i];
	             	frmError = frmError + curError.message + "<br>";
	            }
	            if(frmError!=""){
	                $.alert("Hmm. Something isn't right. ",frmError,"icon_alert.png");
	            }
	            return false;
	        }else{
	        	$.alert("Converting to On-Demand. Please check back later.","","icon_check.png");
	    		return false;
		
	        }
		}
		
		function getPortalSegmentCount(){
			var dataString = "action=GETSEGMENTCOUNT" + "&portalid=" +  eventObj.properties.eventid + "&ui=<%= ufo.sUserID%>&si=<%=ufo.sSessionID%>" ;
			$.ajax({
				type: "POST",
					url: "proc_portal_segments.jsp",
					data: dataString,
					dataType: "json",
					success: function(jsonResult) {										   
						var count = jsonResult[0].segmentcount;
						$("#portal_link_note").text(count + " Events Linked");
					}
			});
			
		}
		
		function doProcUpdate(params,onSuccess) {
			var dataString = "ei=" +  eventObj.properties.eventid + "&ui=<%= ufo.sUserID%>&si=<%=ufo.sSessionID%>" +"&" + params;
			$.ajax({
				type: "POST",
					url: "proc_summary.jsp",
					data: dataString,
					dataType: "json",
					success: function(jsonResult) {
						if(typeof onSuccess =="function") {
							onSuccess();
						}
					},
					failure: function(result) {
						$.alert("Unable to save your data.","","");
					}});
		}
		
		function togglePresenterChat() {
			doProcUpdate(
				"togglechat=1",
				function() {
					if($("#togglePresenterChat").text() == "Disable") {
						$("#presenterChatText").text("Presenter Discussion is currently disabled.");
						$("#togglePresenterChat").text("Enable");
					} else {
						$("#presenterChatText").text("Presenter Discussion is currently enabled.");
						$("#togglePresenterChat").text("Disable");
					}
			});
		}
		
		function toggleSharedGuestPin(){
			doProcUpdate(
				"toggle_shared_guest_pin=1",
				function() {
				    var enable = $("#toggleSharedGuestPin").text() == "Disable";
					$("#sharedGuestPinTxt").text("Individual Guest Admin passwords are " + (enable ? "disabled":"enabled") + " by default");
				    $("#toggleSharedGuestPin").text(enable ? "Enable":"Disable");
			});
		}
		
		function toggleDisplayBackupBridge(chkEnableBackup){
			var dataString = "cmd=enable_backup&ei=" + eventObj.id + "&ui=<%= ufo.sUserID%>&si=<%=ufo.sSessionID%>&chkEnableBackup=" + chkEnableBackup;
			$.ajax({
				type: "POST",
				url: "proc_advtel.jsp",
				data: dataString,
				dataType: "json",
				success: function(data){
					if(data.success){
						$("#msgATWorkflow").show(0).delay(3000).hide(0);					
					}else{
						$.alert("Hmm. Something isn't right. ","","icon_alert.png");
					}
					setTimeout('$("#alertDialog").dialog("close");',3000);
				}
			});
		}
		
		$("#delete_defaultsetting").on("click",function(event){
			 var objButton = {"No": function(){$("#alertDialog").dialog("close");},"Yes":function(){deleteFolderDefaultSetting();}};
			 $.confirm("Are you sure you want to delete this folder template?","Please note that templates only apply default settings to new events and existing events will NOT be affected by this change. New events created in this folder will inherit default settings from the next folder above this one with a custom template or, if none exist, the system defaults.",objButton,"");
		});
		
		function deleteFolderDefaultSetting() {
			doProcUpdate(
				"deletedefaultsetting=1&folderid=" + eventObj.properties.fk_folderid,
				function() {
					self.location = "/admin/eventlibrary.jsp?<%=sQueryString%>&fi=" + eventObj.properties.fk_folderid;
			});
		}		
		
		function toggleOdEvent() {
			doProcUpdate("openclose=1",function() {
				$("#tblOdEventClosed").toggle();
				$("#tblOdEventOpen").toggle();
			});
		}
	
		function openOdStudio() {
			var w,h;
			w = 1000;
			h = 800;
			window.open(
					"/odstudio/odstudio.jsp?ei=" + eventObj.id + "&ui=<%= ufo.sUserID%>&si=<%=ufo.sSessionID%>&useFlash=false",
					"odstudio",
					"width=" + w +", height=" + h + ",menubar=0,toolbar=0,status=0,location=0,scrollbars=1,resizable=1");
	
		}
	
		function changeClass(elementId,className)
		{
			$(elementId).attr('class',className);
		}
	
		var jsonResultValues = '';
	
		function eventSummary() {
			/* Reg Questions */
			var registrationNote;

			<%if (currentEvent.isNewRegistrationEnabled()) {%>
			registrationNote = "New Registration Layout Enabled.";
			<%} else {%>
			registrationNote = "";
			var isAnony=<%=isAnonRegEnabled%>
			for(var i=0;i<regFields.length;i++) {
				if(registrationNote!="") {
					registrationNote += ", ";
				}
				var varRegField = regFields[i];
				if(varRegField!=undefined && varRegField!='')
				{
					varRegField = convertAllEscapes(varRegField,'none');
				}
					
				
				registrationNote += varRegField;
			}
	
			if(customReg) {
				if(registrationNote != "")
					registrationNote += ", ";
				registrationNote += ' Custom Questions';
			}
	
			if(isAnony!=false){
				if(registrationNote != "")
					registrationNote += ", ";		
				registrationNote += ' Anonymous Registration';
			}
			
			<%if(account.can(Perms.User.MANAGEREGFOOTER)){%>
			if(eventObj.properties.reg_footer != undefined){
				if(eventObj.properties.reg_footer.length > 0){
					registrationNote += ", Reg Footer Enabled " ;
				}
			}
			<%}%>
			<%}%>

			$('#registration_note').text(registrationNote);
	
			/**Player Options  Detials */
			var playerOptionNote = '';
			var eventcontentNote = '';
			<% if (!Constants.EMPTY.equals(tscInfo)){%>
			var techEmail=<%=tscInfo%>.Email;
			var techPhone =<%=tscInfo%>.Phone;
			<%} %>
			if(eventObj.properties.acquisition_source == 'audio'){
				playerOptionNote += 'Audio Only, ';
			}else{
				playerOptionNote += "<%= currentEvent.getVideoSize().getVideoSize()%>, ";
			}
			
			
			if(eventObj.properties.slides == '1') {
				playerOptionNote = playerOptionNote + 'Slides enabled, ';
			} else {
				playerOptionNote = playerOptionNote + 'Slides disabled, ';
				eventcontentNote = 'Slides disabled, ';
			}
			if(eventObj.properties.liveqa == '1') {
				playerOptionNote = playerOptionNote + 'Live Q\&A, ';
			} else {
				playerOptionNote = playerOptionNote + 'Live Q\&A disabled, ';
			}
			if(eventObj.properties.odqa == '1') {
				playerOptionNote = playerOptionNote + 'Archive Q\&A by email, ';
			} else {
				playerOptionNote = playerOptionNote + 'On-Demand Q\&A disabled, ';
			}
			
			<% if (!Constants.EMPTY.equals(tscInfo)){ %>
			
				if(techEmail!= '' && techPhone!=''){
					playerOptionNote=playerOptionNote+ 'Tech Support:Email and Phone';
				}
				else{
					if(techEmail!= ''){
						playerOptionNote=playerOptionNote+ 'Tech Support:Email';
					}
					if(techPhone!=''){
						playerOptionNote=playerOptionNote+ 'Tech Support:Phone';
					}
				}
			<%}%>
			if(eventObj.properties.disable_od_seek == '1') {
				playerOptionNote=playerOptionNote+ ' On-Demand Progress Bar Hidden';
			}
			
			$('#player_note').text(playerOptionNote);
	
			var slidesize="<%=currentEvent.getSlideDecks().size() %>"; 
			var documentsize="<%=documentCount%>";
			var headshotsize="<%=headshotList.size() %>";
			var tabsize="<%=totalTabs%>";
			var deckstatus = "<%=sDeckStatus%>";
			
			var isProcessing = "<%=isProcessing%>";
			var isErrorUploading = "<%=isErrorUploading%>";
			
			var isjobempty = "<%=hasJobempty%>";
			
			var isjobId = "<%=hasJobID%>";
		
			<%if(!bIsTradeShowLite){ %>
			if(eventObj.properties.slides == '1' && !isFolderSettingEvent) {
				if(slidesize>0){
					if(deckstatus=='true'){
						if(isProcessing=='true'){
							eventcontentNote = 'Slides processing, ';
						} 
					  if(isErrorUploading=='true'){
							eventcontentNote = 'Error uploading slide decks, ';
						}  
			 			
			 		}
					 if(deckstatus=='false'){
						 eventcontentNote = slidesize+' slide deck(s) uploaded, ';
					  } 
				}
				 else{  
						eventcontentNote = 'No slide decks uploaded, ';
					}
			}
			<%}%>	 
	
			
			<% if (account.can(Perms.User.MANAGEDOCUMENTUPLOADS)) { %>
			if (documentsize>0) {
			    eventcontentNote = eventcontentNote + documentsize + ' resource(s) uploaded,';
			} else {
			    eventcontentNote = eventcontentNote+' No resources uploaded,';
			}
			
			<%} if ((account.can(Perms.User.MANAGEHEADSHOTS)) && (currentEvent.getProperty(EventProps.acquisition_source).equalsIgnoreCase(Constants.ACQUISITION_SRC_AUDIO))) { %>
			if(headshotsize>0){
			eventcontentNote = eventcontentNote + " " + headshotsize +' headshot(s) uploaded,';
			}
			else{
			eventcontentNote = eventcontentNote + ' No headshots uploaded,';
			}
			
			<%} if (account.can(Perms.User.MANAGETABS)) { %>
			if(tabsize>0){
				eventcontentNote = eventcontentNote + " " + tabsize +' tab(s),';
			}
			else{
				eventcontentNote = eventcontentNote+' No tabs,';
			}
			<%}%>
			<%if(!bIsTradeShowLite){ %>
			var secondaryMediaCount = <%=secondaryMediaCount%>;
			if(secondaryMediaCount == 0) secondaryMediaCount = "No";
			eventcontentNote += " " + secondaryMediaCount + " overlay video" + 
			(secondaryMediaCount !=1?"s" :"" )+ ", ";
			<%}%>
			var caption = <%=caption%>;
			if(caption.od==1 && caption.odpath!=""){
				eventcontentNote = eventcontentNote+'Closed Captions enabled,';
			
			}
			
			$('#eventcontent_note').text(eventcontentNote)
			
			
			
		}
		
		var monthLookup = { '01' : 'January','02' : 'February', '03' : 'March',
	            '04' : 'April','05' : 'May',
	            '06' : 'June','07' : 'July',
	            '08' : 'August','09' : 'September',
	            '10' : 'October','11' : 'November','12' : 'December'};
	
	
		function liveScheduler() {
			var start_date_display = '<%=sStartDateDisplay%>';
			if(typeof start_date_display != "undefined") {
				var schedule_note = "";			
				if(eventObj.properties.resourcetype == "OD"){
					if(eventObj.properties.live_resourcetype){
						var sAVDisplay = eventObj.properties.live_resourcetype;
					}else{
						//acquisition source display for OD only event
						var sAVDisplay = (eventObj.properties.acquisition_source == "audio") ? "Audio":"Video";
					}
					if(start_date_display == "On-Demand. Never Published"){
						schedule_note = eventObj.properties.start_date_display + ", " + sAVDisplay + ', ' + new DurationObj(eventObj.properties.event_duration*60).toString();	
					}else if(start_date_display.indexOf('Archive Pending') != -1){
						schedule_note = start_date_display + ', ' + sAVDisplay
					}else{
						schedule_note = start_date_display + ', ' + sAVDisplay + ", " + new DurationObj(<%=lEventDuration%>).toString();
					}
					
				}else{
					//Acquisition source display for non OD events
					var displayResourceType = '';
					if(eventObj.properties.resourcetype == 'WEBCAM_ADVANCED'){
						displayResourceType = 'Webcam';	
					}else if(eventObj.properties.resourcetype == "TELEPHONY"){
						displayResourceType = "Telephone";
					}else if(eventObj.properties.resourcetype == "FLASHENCODER"){
						displayResourceType = "Your Encoder";
					}else if(eventObj.properties.resourcetype == "VCU"){
						displayResourceType = "VCU/Telepresence";
					}else if(eventObj.properties.resourcetype == "PEXIP_BRIDGE"){
						displayResourceType = "Video Bridge";
					}else{
						displayResourceType = eventObj.properties.resourcetype;
					}				
					if(eventObj.properties.resourcetype=="TELEPHONY" || eventObj.properties.resourcetype=="OD") {
						schedule_note = eventObj.properties.start_date_display + ", broadcast";
					}else{
						schedule_note = eventObj.properties.start_date_display + ", broadcast from " + "<%=StringTools.isNullOrEmpty(sRegionName) ? "North America" : sRegionName%>";
					}
					schedule_note += " via " + displayResourceType + ", " + new DurationObj(eventObj.properties.event_duration*60).toString();
				} 
				
				schedule_note  = schedule_note + ", Max Audience: " + eventObj.properties.audiencecap; 
				$("#schedule_note").text(schedule_note);
			}
		}
		
		function DurationObj(seconds,pad) {
			var remainingSeconds = seconds;
			this.hours = Math.floor(seconds / 3600);
			remainingSeconds = seconds - (this.hours * 3600);
			this.minutes = Math.floor(remainingSeconds /60);
			this.seconds = remainingSeconds - (this.minutes * 60);
			if(pad) {
				this.seconds = padLeft(this.seconds,"0",2);
				this.minutes = padLeft(this.minutes,"0",2);
				this.hours = padLeft(this.hours,"0",2);
			}
			
			this.toString = function() {
				var theString = "";
				if(+this.hours > 0) {
					theString += this.hours + ((this.hours == 1) ? " hour":" hours");
				}
				if(+this.minutes > 0){
					theString += " " + this.minutes + ((this.minutes == 1) ? " min":" mins");
				}
				if(+this.seconds > 0){
					theString += " " + this.seconds + " sec";
				}
				return theString;
			}
		}
		
		function setError(elementId,errorMessage, identifier) {
			 $(elementId).append("<span id = \"" +identifier+ "\" name = \"" +identifier+ "\" class =\"small-error-text\">" + errorMessage + "<br></span>");
		}
	
		function addAccessType(accessObj){
		    var html = '<tr id="guest_portal_' + accessObj.accessid + '">'
		    + '<td>' + accessObj.display + '</td>'
		    + '<td id="guest_portal_' + accessObj.accessid + '_num">' + accessObj.admin_num + '</td>'
		    + '<td>' + (accessObj.pin ? 'Disabled':'Enabled') + '</td>'
		    + '<td>'
			+	'<input class="button manageAccessAdmins" type="button" data-id="' + accessObj.accessid + '" value="Manage Admins" alt="Manage Admins">'
			+ '</td>'
		    + '<td>'
			+	'<button class="circleBtns editAccessBtn editBtn" data-id="' + accessObj.accessid + '"  alt="Edit" title="Edit"></button>'
			+ '</td>'
		    + '<td>'
			+	'<button class="redCloseBtn circleBtns deleteAccessBtn" data-id="' + accessObj.accessid + '" alt="Delete" title="Delete"></button>'
			+ '</td>'
			+ '</tr>'
		    $('#tbl_portallist tbody').prepend(html);
		}
		
		function updateAccessAdminNum(accessId,adminNum){
		    $("#guest_portal_"+accessId+"_num").text(adminNum);
		}
		
		function removeAccessType(accessId){
		    $("#guest_portal_" + accessId).remove();
		    $('table#tbl_portallist.sortList').trigger('update');
		}
		
		function callbackSuccessAlert(header,text, interval){
		     if(!interval){
			 	interval = 4000;
		     }
			 $.success(header,text,"icon_check.png");
			 setTimeout('$("#alertDialog").dialog("close");',interval);
			 //Refresh Resent Button as there might be some new links sent out
		}
	
		 function callbackErrorAlert(frmError){
			 $.alert("Hmm. Something isn't right. ",frmError,"icon_alert.png");
		 }
		 
		 function onSubscriptionSaved(){
				$.success("Subscription options were saved successfully.","","icon_check.png");
				setTimeout('$("#alertDialog").dialog("close");',2000);
				setTimeout('$.fancybox.close();',200);
		 }
		 var aXssErrors = [];
		 function showerrors(){
				var param="height=400,width=500,toolbars=no,statusbar=no,resizable=yes,scrollbars,menubar=no";
				newwindow = window.open("xsserrordisp.html","cleanupwin",param); //changed for new popup detection
		 }
		 
		 function onPlayerScheduled(arrErrors){
			var sMsg1 = "Player schedule saved successfully.";
	     	if(arrErrors.length>0){
	     		aXssErrors = arrErrors;
	      		var sMsg2 = "Your changes have been saved however some items were automatically corrected or removed for security purposes. Please <a href=\"#\" onclick=\"showerrors();return false;\">click here</a> to view these items.";
		       	var objButton = {"Ok":function(){$("#alertDialog").dialog("close");displayPlayerStatus();}};	
		       	$.alert(sMsg1,sMsg2,"icon_alert.png",objButton,""); 
	        }else{
	        	$.success(sMsg1,"","icon_check.png");
	        	setTimeout('$("#alertDialog").dialog("close");',2000);
	        	displayPlayerStatus();
	     	}   
	    
		 }
		 
		 function onMulticastSaved(){
				$.success("Multicast settings were saved successfully.","","icon_check.png");
				setTimeout('$("#alertDialog").dialog("close");',2000);
				setTimeout('$.fancybox.close();',200);
				loadMulticastConfig();
		 }
		 
		 
		 function confirmCreateMP4Archive(){
			 var objButton = {"Cancel": function(){$("#alertDialog").dialog("close");},"Ok":function(){createMP4Archive();}};
		     $.confirm("Are you sure you want to export this webcast?","Most MP4 Archives are created quickly but they can sometimes take up to several hours to process. Please note that you will not be able to access the On-Demand Studio until the file has finished processing.",objButton,"");
			 
		 }
		 
		 
		 function createMP4Archive(){
			 $.ajax({
					type: "POST",
					data : 'ei=<%=sEventId%>&ui=<%=ufo.sUserID%>',
					url: "proc_create_mp4archive.jsp",
					dataType: "json",
					success: function(jsonResult){
						if(jsonResult.success){
							$.success("Webcast Archive sucessfully started","You will receive an email when the file has finished processing and it will be available for download on this page.","","icon_check.png");
							setTimeout('$("#alertDialog").dialog("close");',3000);	
						}else{
							
							var errorMsg =  "There was an error processing your request. Please try again.";
							
							if(jsonResult.errorMsg){
								errorMsg = jsonResult.errorMsg;
							}
						
							$.alert("Oops! Something went wrong",errorMsg,"icon_error.png");
					         return false;
						}
						
					},
					error: function(xmlHttpRequest, status, errorThrown){
				        	$.alert("Oops! Something went wrong","There was an error processing your request. Please try again.","icon_error.png");
					         return false;
				    }
				});		
		 }
		 
		 
		 function downloadArchive(id, type){
			var url = '<%=conf.get("mediawebserver")%>/admin/proc_download_media.jsp?<%=Constants.RQEVENTID%>=<%=sEventId%>&ai=' + id + '&downloadtype=' + type;
	
			var hiddenIFrameId = 'hiddenDownloader';
			var iframe = document.getElementById(hiddenIFrameId);
			if (iframe === null) {
			    iframe = document.createElement('iframe');
			    iframe.id = hiddenIFrameId;
			    iframe.style.height = '0';
			    iframe.style.width= '0';
			    document.body.appendChild(iframe);
			}
			
			iframe.src = url; 
		 }
		 
		 function getLiveStudioLog(){
			 var userid = '<%=ufo.sUserID%>';
			 var sessionid = '<%=ufo.sSessionID%>';
			 var eventid = '<%=sEventId%>';
			 		 
			window.open("/admin/livestudio_activity_log.jsp?ui=" + userid + "&si=" + sessionid + "&ei=" + eventid, "Livestudio_Audience",
			"resizable=1,width=1024,height=700,scrollbars=1,menubar=0");
			 
		 }
		 
		 
		 function loadMulticastConfig(){
			 $.ajax({
					type: "POST",
					data : 'ei=<%=sEventId%>&action=GETALLCONFIG&<%=sQueryString %>',
					url: "/admin/fmsconfig/proc_savemulticastsettings.jsp",
					dataType: "json",
					success: function(jsonResult){
						var configHTML = "";
						for(i=0;i<jsonResult.length;i++){
							/*var configName = "Primary ";
							if(i==1){
								configName = "Backup "; 	
							}*/
							configHTML += '<table cellpadding="0" cellspacing="0" id="multicastFlashSettingsList" class="summaryBox summaryBoxGray" style="margin-top:15px;padding-left:10px;">';
							configHTML += '<tr><td width="25" class="configid" style="display:none;">' + jsonResult[i].configid +  '</td><td width="330"><strong>Source Stream</strong>: ' + jsonResult[i].sourcetype +  ' </td><td width="330"><strong> Priority</strong>: ' + jsonResult[i].priority + '</td>';
							configHTML += '<td width="50"><button class="button multicastbutton">Edit</button></td>';
							configHTML += '<td width="55"><button class="button multicastdelete">Delete</button></td>';
							configHTML += '<td width="10">&nbsp;</td></tr></table>';	
						}
						
						$("#MulticastSettings").html(configHTML);
					},
					error: function(xmlHttpRequest, status, errorThrown){
				        	//$.alert("Oops! Something went wrong","There was an error processing your request. Please try again.","icon_error.png");
					         return false;
				    }
				});		
		 }
		 
		 function deleteMulticastConfig(configid){
			 
					var dataString = "action=DELETE" + "&configid=" +  configid + "&<%=sQueryString%>";
					$.ajax({
						type: "POST",
							url: "/admin/fmsconfig/proc_savemulticastsettings.jsp",
							data: dataString,
							dataType: "json",
							success: function(jsonResult) {										   
								if(jsonResult.success){
									$.success("Multicast configuration deleted successfully","","icon_check.png");
									setTimeout('$("#alertDialog").dialog("close");',3000);
									loadMulticastConfig();
								}
							}
					});
			}
		 
		 try {
			console.log('Creation Info: <%=creationInfoJSON != null ? StringEscapeUtils.escapeEcmaScript(creationInfoJSON.toString(5)) : "NONE" %>');
			 
		 
			<%--  console.log("Event created by: <%=sCreator_username%>");
			 console.log("Admin Email: <%=sCreator_email%>");
			 console.log("This event is a copy: <%=sEvent_isStandardCopy%>");
			 console.log("This event was copied from a template: <%=sEvent_isTemplateCopy%>");
			 console.log("This event was copied from: <%=sEvent_copiedFrom%>"); --%>
		} catch (err) {
			 
		 }
		function checkScreenExt(extdiv){
			if($("#" + extdiv).length<1) {
			  $("#installss-button").show();
			}
		}
		
		function exportTranscript(){ 
			transcript = $.getJSON({
				url: "<%=currentEvent.getSpeechToTextViewerFileUrl()%>".replace("<%=conf.get("content_webfolder")%>","/content")
			}).done(function(result) {
				download("transcript.txt", result.full_text);
			}).error(function(err){
			    $.alert("Oops! Something went wrong","There was an error processing your request. Please try again.","icon_error.png");
			    return false;			
			})
		}	
		
		function download(filename, text){
		       var filename = filename;
		       var data = text;
		       var blob = new Blob([data], { type: 'text/csv' });
		       if (window.navigator.msSaveOrOpenBlob) {
		           window.navigator.msSaveBlob(blob, filename);
		       } else {
		           var elem = window.document.createElement('a');
		           elem.href = window.URL.createObjectURL(blob);
		           elem.download = filename;
		           document.body.appendChild(elem);
		           elem.click();
		           document.body.removeChild(elem);
		       }
		}
		
		function updateVideoCMSData(data) {
			if (basicUtils.isDefined(data.pathsuffix)) {
				$('#videocmslinkAnchor').text('https://' + data.hostname + '/' + data.pathprefix + '-' + data.pathsuffix);
				$('#videocmslinkAnchor').attr('href', 'https://' + data.hostname + '/' + data.pathprefix + '-' + data.pathsuffix)
				$('#videocmslinkSpn').show();
			} else {
				$('#videocmslinkAnchor').text('');
				$('#videocmslinkAnchor').attr('href','');
				$('#videocmslinkSpn').hide();
			}
			
		}
		<%if(!isFolderSettingEvent){ %>     
		// copy url link button
        document.getElementById('copyLink').addEventListener('click', function(){
            let copyText = document.getElementById('copyLinkTxt');

            copyText.select();
            copyText.setSelectionRange(0, 99999);
            document.execCommand("copy");

            this.innerText = 'Copied';

            setTimeout(function(){
            	document.getElementById('copyLink').innerText = 'Copy';
            }, 5000);
        });
        <% } %>
<% } %>
</script>
<jsp:include page="/admin/footerbottom.jsp">
	<jsp:param name="pfi" value="<%=pfo.sCacheID%>"/>
	<jsp:param name="ufi" value="<%=ufo.sCacheID%>"/>
</jsp:include>
<%
}catch(Exception e){
	response.sendRedirect(ErrorHandler.handle(e, request));
	//out.print(ErrorHandler.getStackTrace(e));
}
%>