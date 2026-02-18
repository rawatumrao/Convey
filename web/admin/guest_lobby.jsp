<%@ page import="java.util.*"%>
<%@ page import="tcorej.*"%>
<%@ page import="org.json.*"%>
<%@ include file="/include/globalinclude.jsp"%>

<%

//configuration
Configurator conf = Configurator.getInstance(Constants.ConfigFile.GLOBAL);

//generate pfo and ufo
PFO pfo = new PFO(request);
UFO ufo = new UFO(request);

Event currentEvent = null;

//logger
Logger logger = Logger.getInstance();


try {
	pfo.sMainNavType = "guest_presenter";
	pfo.secure();
	pfo.setTitle("Guest Lobby");
	PageTools.cachePutPageFrag(pfo.sCacheID, pfo);
	PageTools.cachePutUserFrag(ufo.sCacheID, ufo);
	
	String sAdminId = StringTools.n2s(request.getParameter(Constants.RQUSERID));
	boolean redirect = StringTools.n2b(request.getParameter("redirect"));

	AdminUser guestAdmin = AdminUser.getInstance(sAdminId);

	if(guestAdmin == null){
		throw new Exception("Invalid admin id");
	}

	//TODO : if access id is empty its because there was a mapping problem betweem
	//giest admin and portal, should enhance logging
	String sAccessId = GuestAdminTools.getAccessIdFromUserId(sAdminId);
	GuestAccessType accessType = GuestAccessType.get(sAccessId);

	if(accessType == null){
		throw new Exception("Invalid access id");
	}

	currentEvent = Event.getInstance(accessType.getEventId());

	//TODO : pass event id for further security ?

	String slinkflag = AdminUser.getflagByName(guestAdmin.sUsername);
	
	String sQueryString = ufo.toQueryString()+"&"+Constants.RQEVENTID+"="+accessType.getEventId();

	boolean isEventContent = slinkflag.equals("5") || accessType.getAccessTypes().contains(Constants.GuestLinkStatus.SLIDES);
	
	final String codetag = currentEvent.getProperty(EventProps.codetag);
	%>
 	 <jsp:include page="headertop.jsp">
		<jsp:param name="pfi" value="<%=pfo.sCacheID%>"/>
		<jsp:param name="ufi" value="<%=ufo.sCacheID%>"/>
	</jsp:include>
	<link href="/admin/css/ui.core.css" rel="stylesheet" type="text/css" media="screen"/>
	<link href="/admin/css/jqueryuithemes/jquery.ui.custom.css" rel="stylesheet" type="text/css" media="screen"/>
	<style>
	
		div.guestPortalDetails{
			 width: 100%;
		    -webkit-border-radius: 2px;
		    -moz-border-radius: 2px;
		    border-radius: 2px;
		    display: flex;
		    flex-direction: column;
		    justify-content: center;
		    align-items: center;
		}
	
		div.accessOptions{
			display:flex;
		    flex-direction: column;
		    align-items: center;
		    justify-content: flex-start;
		}
		
		div.accessOptionRow{
			display: flex;
			width: 500px;
			margin: 5px 0 15px 0;
			flex-direction: column;
			align-items: center;
		}
		
		div.accessOptionItem{
			background-color: #00aeec;
		    border: none;
		    display: inline-block;
		    color: #fff;
		    margin: 0px;
		    padding: 6px 8px;
		    text-align: center;
		    text-decoration: none;
		    width: auto;
		    font-family: Roboto, Arial, Helvetica, sans-serif;
		    font-weight: 300;
		    font-size: 16px;
		    cursor: pointer;
		    -webkit-border-radius: 4px;
		    -moz-border-radius: 4px;
		    border-radius: 4px;
		    width:250px;
		}
		
		div.accessOptionItemError{
		    color: #666;
	   		font-size: 80%;
		}
		
		div.accessOptionItemAdtl{
		    display: flex;
		    align-items: center;
		    margin-top: 10px;
		    text-align: center;
		}
		
		div.accessOptionItemAdtl img{
			height:25px;
			width:25px;
		}
		
		div.accessOptionItemAdtl span{
			margin-top:5px;
		}
		
		.messages{
    		display: flex;
    		align-items: center;		
		}
		
		#od_row .accessOptionItemAdtl{
			margin-left: 5px;
		}
		
		.disabledButton{
		    color: #fff !important;
		}
		
		.audienceLinkBtn{
			color: #00aeec;
    		text-decoration: underline;
    		cursor: pointer;
		}
		
		.webrtcLink{
			display: flex;
			justify-content: center;
		}
	</style>
	<jsp:include page="headerbottom.jsp">
		<jsp:param name="pfi" value="<%=pfo.sCacheID%>"/>
		<jsp:param name="ufi" value="<%=ufo.sCacheID%>"/> 
	</jsp:include>
	
	<div class="contentContainer">
		<div class="guestPortalDetails">
			<h1>Guest Administrator Access</h1>
			<br/>
			<div style="display:flex;flex-direction:row;font-size:15px;">
				<span>Event: <%=currentEvent.getShortenedEventTitle() +" (" + accessType.getEventId() + ")"%> </span> 
				<%if(!"true".equalsIgnoreCase(currentEvent.getProperty(EventProps.is_webinar))){%>
							<a class="audienceLinkBtn" style="margin-left:5px;" title="Audience Webcast Link" alt="Audience Webcast Link">
			            		Audience Webcast Link
			            	</a>
				<%}%>
			</div>
			<%if((currentEvent.getStatus(EventStatus.mode).value.equals("live")	|| currentEvent.getStatus(EventStatus.mode).value.equals("prelive"))
					&& (accessType.getAccessTypes().contains(Constants.GuestLinkStatus.LIVESTUDIO) || accessType.getAccessTypes().contains(Constants.GuestLinkStatus.LIVEQUESTION) )){%>
				<span style="font-size:15px;">Scheduled for:  <%=currentEvent.getLiveStartDateFormatted() %> </span>
			<%}%>
		</div>	
		<br /><br />
		<div class="accessOptions">
		<%JSONArray accessJSON = accessType.getAccessJSON();
			for(int i = 0; i < accessJSON.length(); i++){
				JSONObject json = accessJSON.optJSONObject(i);
				if(json.optString("error").equals("1")){%>
				<div class="accessOptionRow">
						<div class="accessOptionItem disabledButton"><%=json.optString("name")%></div>
						<div class="accessOptionItemAdtl"><%=json.optString("error_note")%></div>
				</div>
				<%}else{%>
					<div id="<%=json.optString("access_type")%>_row" class="accessOptionRow">
					<div class="accessOptionItem" data-url="<%=json.optString("url")+"?"+sQueryString%>" data-access-type="<%=json.optString("access_type")%>"><%=json.optString("name")%></div>
					<%if(json.has("note")){%>
						<div class="accessOptionItemAdtl"><%=json.optString("note")%></div>
					<%}%>				
					</div>
				<%}
			}%>
		</div>
		<%if(!Constants.ACQUISITION_SRC_AUDIO.equals(currentEvent.getProperty(EventProps.acquisition_source)) || "1".equals(currentEvent.getProperty(EventProps.webrtc_screenshare))){%>
			<br><div class="note" style=center> To test your webcam, visit the 'Live Presenter Studio' at any time more than one hour prior to your scheduled Live event start time.<br>
				Click the &nbsp;<a class="webrtcLink" href="<%=conf.get("webrtc_test_link")%>" target="_blank">'Test Your Webcam'</a> &nbsp;button for a self-led test.
			</div>
		<% } %>
		
	</div>	 
	<jsp:include page="footertop.jsp">
		<jsp:param name="pfi" value="<%=pfo.sCacheID%>"/>
		<jsp:param name="ufi" value="<%=ufo.sCacheID%>"/>
	</jsp:include>
	<script type="text/javascript" src="/js/systemtest/webrtccheck.js?<%=codetag%>"></script>
	<script type="text/javascript" src="/js/systemtest/detect.js?<%=codetag%>"></script>		
	<script type="text/javascript">
		var eventObj = <%= currentEvent.json().toString() %>;
      	$(document).ready(function() {
      	    $.initdialog();
      	     
	  	    $('.audienceLinkBtn').on('click', function() {
	  	        window.open('<%=currentEvent.getEventUrl()%>', '_blank');
	  	    });
      	    
      	    $(document).on('click','div.accessOptionItem',function(){
      			var $element = $(this);
      			handleAccessClick($element.attr("data-url"),$element.attr("data-access-type"));
      	    });
      	    <%if(redirect && accessType.hasAccessPin() && accessJSON.length() == 1){%>
				$('div.accessOptionItem').click();
			<%}
			
			if(isEventContent){%>
				var slidesEnabled = <%="1".equals(currentEvent.getProperty(EventProps.slides))%>;
				var eventContentDisplayStr = '';
				var slideSize = <%=currentEvent.getSlideDecks().size()%>;
				if(slidesEnabled){
					eventContentDisplayStr = 'Slides are enabled, ';
					eventContentDisplayStr += slideSize > 0 ? (slideSize + ' slide deck(s) uploaded.') : 'but no slide decks have been uploaded.';
					if(slideSize <= 0 ){
						eventContentDisplayStr =  '<img src="images/icon_sm-alert.png" style="vertical-align:text-bottom" />'
							+ '<span class="messagesRed">' + eventContentDisplayStr + '</span>';
					}
				}else if(!slidesEnabled){
					eventContentDisplayStr = 'Slides are disabled for this event.';
				}
				
				if(eventContentDisplayStr){
					eventContentDisplayStr =  '<div class="accessOptionItemAdtl">' + eventContentDisplayStr + '</div>';
					$("#<%=Constants.GuestLinkStatus.SLIDES.getGuestStatus()%>_row").append(eventContentDisplayStr);   
				}
			<%}%>
      	});

		function handleAccessClick(url,accessType){
		    if(url){
		    	var w,h;
				w = 1240;
				h = 820;
				
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
				if(accessType == '<%=Constants.GuestLinkStatus.LIVESTUDIO.getGuestStatus()%>'){
					if(url.indexOf('plugin') != -1){
					    url+='&forward=livestudio';
					}
					url+="&src=" + window.location.host;
					window.open(url,"presenterstudio","width=" + w + ", height=" + h + ",menubar=0,toolbar=0,status=0,location=0,scrollbars=1,resizable=1");
				}else if(accessType == '<%=Constants.GuestLinkStatus.ODSTUDIO.getGuestStatus()%>' || accessType == '<%=Constants.GuestLinkStatus.ODRECORDVIDEO.getGuestStatus()%>') {
				    window.open(url,"odstudio","width=1000, height=800,menubar=0,toolbar=0,status=0,location=0,scrollbars=1,resizable=1");
				}else if(accessType == '<%=Constants.GuestLinkStatus.LIVEQUESTION.getGuestStatus()%>'){
					window.open(url,"livequestionstudio","width=" + w + ", height=" + h + ",menubar=0,toolbar=0,status=0,location=0,scrollbars=1,resizable=1");
				}else{
					window.location.href = url;
			    }
		    }		    
		}
		
		
</script>
	
	<jsp:include page="footerbottom.jsp">
	<jsp:param name="pfi" value="<%=pfo.sCacheID%>"/>
	<jsp:param name="ufi" value="<%=ufo.sCacheID%>"/>
</jsp:include>
<% } catch (Exception e) {
	logger.log(Logger.CRIT,"jsp","stacktrace:\n" + ErrorHandler.getStackTrace(e),"guest_lobby.jsp");
	response.sendRedirect(ErrorHandler.handle(e, request));
} %>
