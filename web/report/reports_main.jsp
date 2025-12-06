<%@ page import="tcorej.*"%>
<%@ page import="tcorej.reports.*"%>
<%@ page import="tcorej.bean.reports.*"%>
<%@ page import="tcorej.bean.*"%>
<%@ page import="java.util.*"%>
<%@ include file="/include/globalinclude.jsp"%>
<%
	//configuration
	Configurator conf = Configurator.getInstance(Constants.ConfigFile.GLOBAL);

	// generate pfo and ufo
	PFO pfo = new PFO(request);
	UFO ufo = new UFO(request);

	// admin
	AdminUser admin = null;

	String sQueryString = Constants.EMPTY;

	try {
		AdminUser au = AdminUser.getInstance(ufo.sUserID);
		String userId = au.sUserID;

		boolean isGuestPresenter = GuestPresenter
				.isGuestPresenter(ufo.sUserID);
		boolean isWebinar = false;
		boolean showAdminOptions = true;
		int webinar_report_type = 0;
		String source = StringTools.n2s(request.getParameter("source"));
		try {
			webinar_report_type = StringTools.n2I(request
					.getParameter("type"));
		} catch (Exception ex) {
		}

		pfo.sPageRev = "$Id: reports_main.jsp 32712 2025-11-24 17:38:01Z jarias $";
		sQueryString = ufo.toQueryString();

		ReportColumnBean repColParser = ReportColumnsParser
				.getReportColumn(webinar_report_type);

		PageTools.cachePutPageFrag(pfo.sCacheID, pfo);
		PageTools.cachePutUserFrag(ufo.sCacheID, ufo);

		String sEventId = StringTools.n2s(request.getParameter("ei"));

		boolean isEventSpecificRep = false;
		String sEventName = Constants.EMPTY;
		String sCostCenter = Constants.EMPTY;
		String sClientId = Constants.EMPTY;
		Event eventObj;
		if (!Constants.EMPTY.equalsIgnoreCase(sEventId)) {
			isEventSpecificRep = true;
			sQueryString = "&"+Constants.RQEVENTID+ "=" +sEventId + "&" + sQueryString;
			eventObj = Event.getInstance(StringTools
					.n2I(sEventId));

			sEventName = eventObj.getProperty(EventProps.title);
			sClientId = eventObj.getProperty(EventProps.fk_clientid);

			if (eventObj.getProperty(EventProps.is_webinar)
					.equalsIgnoreCase("true")) {
				isWebinar = true;
			}
 		sCostCenter = eventObj.getProperty(EventProps.cost_center);
			String userType = AdminUser.getflagByName(au.sUsername);
			String webinarType = Integer
					.toString(Constants.GuestLinkStatus.WEBINAR
							.ordinal());

			if (!au.canViewEvent(eventObj.eventid)) {
				throw new Exception(Constants.ENOUSERAUTH);
			}

		}

		showAdminOptions = Webinar.showAdminOptions(isWebinar, source,
				au);

		if (!showAdminOptions) {
			pfo.sMainNavType = "secureonly";
		} else {
			if(isGuestPresenter){
				pfo.sMainNavType = "guest_reports";	
			}else{
				pfo.sMainNavType = "reports";
			}
			pfo.useAdminNavi();
			pfo.secure();
		}

		if (!General.isNullorEmpty(ufo.sUserID)) {
			if (!au.can(Perms.User.RUNREPORTS)) {
				throw new Exception(Constants.ENOUSERAUTH);
			}
		} else {
			throw new Exception(Constants.EGENERALEXCEPTION);
		}
		
		boolean adminHasLicense = au.hasLicense();
		boolean superUser = au.can(Perms.User.SUPERUSER);

		String sTitle = "Convey Reports";
		pfo.setTitle(sTitle);

		//AdminUser au = AdminUser.getInstance(ufo.sUserID);
		boolean bShowBillingReport = au.can(Perms.User.RUNBILLING) && showAdminOptions;
		boolean bShowTPCost = au.can(Perms.User.ACCESSIAVENDORCOSTREPORT);
		boolean bShowClientInvoice =au.can(Perms.User.ACCESSIACLIENTINVOICE);

        String sAdvancedAudienceDP = Constants.EMPTY;
		String sEventAudienceDP = Constants.EMPTY;
        String sBillingDP = Constants.EMPTY;
		HashMap<Integer, ReportColumnBean> hmRcpb = repColParser
				.getReportColBean();
		Set<Integer> keyRCBean = hmRcpb.keySet();
		for (Integer keys : keyRCBean) {
			//System.out.println("Keys = " + keys);
			ReportColumnBean rcbMenu = hmRcpb.get(keys);
			HashMap<Integer, ReportColumnBean> hmRcbMenuOptions = rcbMenu
					.getReportColBean();
			Set<Integer> keyRCBeanMenuOpt = hmRcbMenuOptions.keySet();
			for (Integer keysMenuOption : keyRCBeanMenuOpt) {
				//System.out.println("Keys Menu = " + keysMenuOption);
				ReportColumnBean rcbMenuOption = hmRcbMenuOptions
						.get(keysMenuOption);
				ReportColumnsParser rcbVal = new ReportColumnsParser();
				
				String innerHtmlColumn = rcbVal.getColumnOptions(rcbMenuOption.getColumnID(), rcbMenuOption,rcbMenuOption);

				if (ReportColumns.menu.USER_DATE.ID
						.equalsIgnoreCase(rcbMenuOption.getColumnID())) {
					sAdvancedAudienceDP = innerHtmlColumn;
				} else if (ReportColumns.menu.EVENT_DATA.ID
						.equalsIgnoreCase(rcbMenuOption.getColumnID())) {
					sEventAudienceDP = innerHtmlColumn;
				} else if (ReportColumns.menu.BILLING.ID
                        .equalsIgnoreCase(rcbMenuOption.getColumnID())) {
                    sBillingDP = innerHtmlColumn;
                }
			}

		}
		String sReportingBaseUrl = conf.get(Constants.REPORTING_BASE_URL) + "/report/";
		
		boolean isReportTemplateFeatureEnabled = true;
		boolean analyticsActive = StringTools.n2b(conf.get(Constants.ANALYTICS_ACTIVE_CONFIG));
%>
<script type="text/javascript" src="/js/analytics.js"></script>
<jsp:include page="/admin/headertop.jsp">
	<jsp:param name="pfi" value="<%=pfo.sCacheID%>" />
	<jsp:param name="ufi" value="<%=ufo.sCacheID%>" />
</jsp:include>
<style type="text/css">
#dateRange_compare_text {font-size: 10px; color: #666; cursor: pointer; width: 195px; text-align: center; display: block; margin:5px 0 0 25px}
.reportFilterBox {margin: 0 10px 10px 0; float:left; padding:10px 15px}
.reportFilterBoxTall {min-height:135px}
.reportFilterBoxShort {min-height:70px}
.disabled{
    background-color: #ccc;
}
	
.fancybox-wrap.fancybox-opened {
	position: absolute !important;
	top: 20px !important;
} 
</style>
<jsp:include page="/admin/headerbottom.jsp">
	<jsp:param name="pfi" value="<%=pfo.sCacheID%>" />
	<jsp:param name="ufi" value="<%=ufo.sCacheID%>" />
</jsp:include>
<h1>Reports</h1>
<br />
<div id="main_div" style="height: auto; z-index: 1"
	class="graybox">
<h2>Selected Events</h2>
<span id="folder_events"><%=sEventName%></span> 

    <%
    if (!isGuestPresenter && showAdminOptions) {
    %>
    <span>&nbsp;&nbsp;&nbsp;
        <a id="add_folder"><span class="buttonSmall buttonCreate">&nbsp; + Add Events / Folders &nbsp;</span> </a> 
        <a id="add_folder_again" style="display: none;"><span class="buttonSmall buttonCreate">&nbsp; + Add Events / Folders &nbsp;</span></a>
    </span> <%
    }
    %>
    	
        
      <br /><br />
	<div id="add_filter" style="width: 100%; height: auto;" class="topLine">
		<div>
			<table width="100%" cellpadding="0" cellspacing="0">
				<tr>
					<td>
					  <div id="sel_report_type">
							<h2>
								Report Type &nbsp;<img src="/admin/images/help.png"
									class="helpIcon" title="Help with &lsquo;Report Type&rsquo;"
									alt="Help with &lsquo;Report Type&rsquo;" name="help"
									onclick="$.help('report_type','Help with &lsquo;Report Type&rsquo;');" />
							</h2>
							<%
								if (Webinar.isReportColumnShown(isWebinar, source, au,
											webinar_report_type, ReportColumns.menu.USER_DATE.ID)) {
							%>
							<br/>
							<div id="viewReportTemplates" style="display: none;">
		                        <button id="view_report_template_button" class="buttonSmall disabledButton" name="view_report_template_button" disabled>Report Templates</button>
			                    <span id="loadedTemplate" style="display: none; display: inline-block; margin-left: 5px;"></span>
			                    &nbsp;<img src="/admin/images/help.png"  class="helpIcon" style="margin: -2px;" title="Help with Manage Report Template" alt="Help with Manage Report Template" name="help" onclick="$.help('report_templates_manage','Help with Manage Report Template');" />
		                        <div id="runReportError">&nbsp;</div>
                            </div>

							<div class="whitebox reportType" style="margin-right:10px">
								<table width="340">
									<tr>
										<td width="20" valign="top"><input type="radio" checked
											id="report_type" name="report_type" value="audience"
											onclick="javascript:disableColumnModifier('audience');" />
										</td>
										<td width="320" valign="top">
										  <h3>Audience Details</h3>
										    <span id="adv_audience" name="adv_audience"
											class="small linkColor smallArrowText"><span
												class="arrowClosed">Select  Columns</span>
									        </span>
										</td>
									</tr>
									<tr>
										<td width="20" valign="top">&nbsp;</td>
										<td width="320" valign="top"><div id="audience_advanced"
												style="display: none; width: 100%; position: relative;">
												<%=sAdvancedAudienceDP%>
											</div></td>
									</tr>
								</table>
							</div>
							<%
								}
							%>
							<%
								if (Webinar.isReportColumnShown(isWebinar, source, au,
											webinar_report_type, ReportColumns.menu.EVENT_DATA.ID)) {
							%>
							<div class="whitebox reportType" style="margin-right:10px">
								<table width="340">
									<tr>
										<td width="20" valign="top">
											<%
												if (webinar_report_type == Constants.WEBINAR_REPORT_SURVEY_SUMMARY
																|| webinar_report_type == Constants.WEBINAR_REPORT_QA
																|| webinar_report_type == Constants.WEBINAR_REPORT_LOCATIONS
																|| webinar_report_type == Constants.WEBINAR_REPORT_CLICK_TRACKING
																|| webinar_report_type == Constants.WEBINAR_REPORT_MEDIA_SELECTIONS
																|| webinar_report_type == Constants.WEBINAR_REPORT_AUDIO_BRIDGE_CALL_USAGE) {
											%> <input type="radio" id="report_type"
											name="report_type" value="event" checked
											onclick="javascript:disableColumnModifier('event');" /> <%
 	} else {
 %> <input type="radio" id="report_type"
											name="report_type" value="event"
											onclick="javascript:disableColumnModifier('event');" /> <%
 	}
 %>
										</td>
										<td width="320" valign="top"><h3>Event Analytics</h3> <span id="adv_event" name="adv_event"
											class="small linkColor smallArrowText"><span
												class="arrowClosed">Select Report </span>
										</span>
										</td>
									</tr>
									<tr>
										<td width="20" valign="top">&nbsp;</td>
										<td width="320" valign="top"><div id="event_advanced"
												style="display: none; width: 100%; position: relative;">
												<%=sEventAudienceDP%></div>
										</td>
									</tr>
								</table>
							</div>
							<%
								}
							%>
							
								<%
									if (bShowBillingReport) {
								%>
								<div class="whitebox reportType systemUsage">
                                <table width="340">
									<tr>
										<td width="20" valign="top"><input type="radio"
											id="report_type" name="report_type" value="bill"
											onclick="javascript:disableColumnModifier('bill');" />
										</td>
                                        <td width="320" valign="top"><h3>System Usage</h3>
                                            <span id="adv_bill" name="adv_bill"
                                                                           class="small linkColor smallArrowText"><span
                                                class="arrowClosed">Select Report</span>
										</span>
                                        </td>
									</tr>
                                    <tr>
                                        <td width="20" valign="top">&nbsp;</td>
                                        <td width="320" valign="top"><div id="billing_advanced"
                                                                          style="display: none; width: 100%; position: relative;">
                                            <%=sBillingDP%></div>
                                        </td>
                                    </tr>
								</table></div>
								<%
									} else {
								%>
								<!-- If user only has two report types, make columns wider -->
								<style>.reportType {width:563px}</style>
								<%
									}
								%>
							
							<br style="clear: both" />
						</div></td>
				</tr>
			</table>
		</div>
	

	</div>
	<div style="clear: both; height: 10px"></div>
	<%
		if (showAdminOptions) {
	%>
	<div id="add_filter" class="sectionBoxWide">
		<h3 id="btnAdvancedFilters">
			<span class="arrowClosed">Filter Results By</span> &nbsp;<img
				src="/admin/images/help.png" class="helpIcon"
				title="Help with Report Filters"
				alt="Help with Report Filters" name="help"
				onclick="$.help('restrict_results','Help with Report Filters');" />
		</h3>
		<div id="showAdvancedFilters" style="border: none">
			<%
				if (!isGuestPresenter) {
			%>
            <!--<div class="whitebox reportFilterBox reportFilterBoxTall" style="width: 150px">
              <table width="100%">
                <tr>
                  <td width="25">
                    <input type="checkbox" id="result_event_status" name="result_event_status" />
                  </td>
                  <td class="adminFieldName">Event Status</td>
                </tr>
                <tr>
                  <td width="25">&nbsp;</td>
                  <td class="reportFilters">
                    <div id="check_event_status">
                      <input name="event_status" type="radio" value="prelive" />
                      Pre-Live<br />
                      <input name="event_status" type="radio" value="live" />
                      Live<br />
                      <input name="event_status" type="radio" value="archive_pending" />
                      Archive Pending<br />
                      <input name="event_status" type="radio" value="archive" />
                      Archived<br />
                      <input name="event_status" type="radio" value="ondemand" />
                      On-Demand<br />
                    </div>
                  </td>
                </tr>
              </table>
            </div>-->
			<%
				}
			%>
            <div class="whitebox reportFilterBox reportFilterBoxTall" style="width: 210px">
              <table width="100%">
                <tr>
                  <td width="25">
                    <input type="checkbox" id="result_domains"
                                        name="result_domains" />
                  </td>
                  <td class="adminFieldName">Domain or Email</td>
                </tr>
                <tr>
                  <td width="25">&nbsp;</td>
                  <td class="reportFilters">
                    <div id="domain_filter_div">
                      <input name="domain_filter" type="radio" value="exclude" />
                      Exclude Domains/Emails
                      <input type="text" id="email_domain_exclude_txt" name="email_domain_exclude_txt" style="margin-left: 25px;" class="smallerField" />
                      <br />
                      <input name="domain_filter" type="radio" value="include" />
                      Include Only Domains/Emails<br />
                      <input type="text" id="email_domain_include_txt" name="email_domain_include_txt" style="margin-left: 25px;"  class="smallerField" />
                    </div>
                  </td>
                </tr>
              </table>
            </div>
            <div class="whitebox reportFilterBox reportFilterBoxTall" style="width: 135px">
              <table width="100%">
                <tr>
                  <td>
                    <table width="100%">
                      <tr>
                        <td width="15">
                          <input type="checkbox" id="result_attendance" name="result_attendance" />
                        </td>
                        <td><span class="adminFieldName">Attendance</span></td>
                      </tr>
                      <tr>
                        <td width="15">&nbsp;</td>
                        <td class="reportFilters">
                          <div id="domain_filter_div2">
                            <input name="attendance_filter" type="radio" value="result_no_dur_user" id="result_no_dur_user" />
                            No Shows<br />
                            <input name="attendance_filter" type="radio" value="result_dur_user" id="result_dur_user"  />
                            Attendees<br />
                            &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
                            <input type="checkbox" id="result_live_sess_user" name="result_live_sess_user" />
                            Live <br />
                            &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
                            <input type="checkbox" id="result_od_sess_user" name="result_od_sess_user" />
                            OD<br />
                            &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
                            <input type="checkbox" id="result_simlive_sess_user" name="result_od_sess_user" />
                            SimLive<br />
                          </div>
                        </td>
                      </tr>
                    </table>
                  </td>
                </tr>
              </table>
            </div>
            <div class="whitebox reportFilterBox reportFilterBoxShort" style="width: 125px">
              <table width="100%">
                <tr>
                  <td class="adminFieldName">Viewer Data</td>
                </tr>
                <tr>
                  <td class="reportFilters">
                    <div id="domain_filter_div">
                      <input type="checkbox" id="result_qa_user" name="result_qa_user" />
                      with Q&amp;A Data<br />
                      <input type="checkbox" id="result_survey_user" name="result_survey_user" />
                      with Survey Data<br />
                    </div>
                  </td>
                </tr>
              </table>
            </div>
            <div id="audience_action_filter_div" class="whitebox reportFilterBox reportFilterBoxShort" style="width: 145px">
              <table width="100%">
                <tr>
                  <td width="15">
                    <input type="checkbox" id="result_audaction" name="result_audaction" />
                  </td>
                  <td class="adminFieldName">Audience Actions</td>
                </tr>
                <tr>
                  <td width="15">&nbsp;</td>
                  <td class="reportFilters">
                    <div id="domain_filter_div">
                      <input type="radio" id="result_regist" name="result_regist" />
                      Registrations<br/>
                      <input type="radio" id="result_vwsession" name="result_vwsession" />
                      Viewing Sessions<br/>
                    </div>
                  </td>
                </tr>
              </table>
            </div>
            <div class="whitebox reportFilterBox reportFilterBoxShort" style="width: 225px">
              <table width="100%">
                <tr>
                  <td width="15">
                    <input type="checkbox" id="result_sti_checkbox" name="result_sti_checkbox" />
                  </td>
                  <td class="adminFieldName">Source Track Identifier (STI)</td>
                </tr>
                <tr>
                  <td width="15">&nbsp;</td>
                  <td class="reportFilters">
                    <div id="domain_filter_div">
                      <input type="text" id="result_sti_filter" name="result_sti_filter" class="smallerField"/>
                      <br />
                    </div>
                  </td>
                </tr>
              </table>
            </div>
            <div class="whitebox reportFilterBox" style="width: 220px">
              <table width="100%">
                <tr>
                  <td width="15">
                    <input type="checkbox" id="result_unsubscribed_checkbox" name="result_unsubscribed_checkbox" />
                  </td>
                  <td class="adminFieldName">Exclude Unsubscribed Users</td>
                </tr>
              </table>
            </div>
            <div id="result_live_odp_div" class="whitebox reportFilterBox" style="width: 360px">
              <table width="100%">
                <tr>
                  <td width="15" valign="top">
                    <input type="checkbox" id="result_live_odp_checkb" />
                  </td>
                  <td class="adminFieldName" id = "result_live_odp">Events run Live and OD-only events first published</td>
                </tr>
              </table>
            </div>
			<div class="clear"></div>
		</div>
	</div>
	<br style="clear: both;">
	<%if(isGuestPresenter == false){%>
		<div id="saveReportTemplate" style="display: none; justify-content: center;">
			<button id="save_changes_template_button" name="save_report_template_button" class="buttonSmall disabledButton" style="margin: 5px;" disabled>
				Save Changes
			</button>
			<button id="save_report_template_button" name="save_report_template_button" class="buttonSmall" style="margin: 5px;">
				Save as New Template
			</button> 
			&nbsp;<img src="/admin/images/help.png"  class="helpIcon" style="height: 16px; width: 16px; margin: 4px;" title="Help with Save Report Template" alt="Help with Save Report Template" name="help" onclick="$.help('report_templates_save','Help with Save Report Template');" />
			<div id="runReportError">&nbsp;</div>
		</div>
	<%}%>
	<%
		}
	%>
	<br style="clear: both;">
    <br />
	<div id="add_filter" style="width: 100%; height: auto;" class="topLine">
    <!-- Date Range for Normal Reporting - start -->
		<div id="reporting_date_range">
			<h2>Date Range</h2>
          <input name="dateRange" id="dateRange_creation" type="radio" value="dateRange_creation" checked="checked" /> All dates since creation of selected events<br /><br />
            
            <input name="dateRange" id="dateRange_selector" type="radio" value="dateRange_selector" /> <input type="text" id="startDatePicker" name="startDatePicker" readonly size="10" /> to <input type="text" id="endDatePicker" name="endDatePicker" readonly size="10" />

            
            <div style="display: none; margin: 5px 0 0 24px;" id="dateRange_compare_fields">
                <input type="text" id="compStartDatePicker" name="compStartDatePicker" readonly size="10" /> to <input type="text" id="compEndDatePicker" name="compEndDatePicker" readonly size="10" />
            </div>
            <div id="dateRange_compare_text" style="display:none;">Add Compare Date</div>
            
		</div>


		<!-- Date Range for Billing purposes - Hidden by default - start -->
		<div id="billing_date_range" style="display: none;">
			<h2>Date Range</h2>
            <input name="dateRange_bill" id="dateRange_month" type="radio" value="dateRange_custom_month" checked="checked" /> Monthly <select id="month_select" name="month_select"></select><br /><br />
            <input name="dateRange_bill" id="dateRange_selector_bill" type="radio" value="dateRange_select" /> <input type="text" id="startDatePicker_bill" name="startDatePicker_bill" readonly size="10" /> to <input type="text" id="endDatePicker_bill" name="endDatePicker_bill" readonly size="10" />
            &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
			
            <span class="small">&nbsp;</span><br />
		</div>
        <!-- end dates-->
    <br /><br />
	<div id="run_report" class="centerThis">
		<button id="run_report_button" name="run_report_button"
			class="buttonLarge">Run My Report</button>
		<br /> <br /> <span class="note">Please note that reporting
			data may be delayed up to 30 minutes.</span>
		<div id="runReportError">&nbsp;</div>
	</div>
</div>
<input type="hidden" id="main_date_begin" name="main_date_begin"
	value="">
<input type="hidden" id="main_date_end" name="main_date_end" value="">
<input type="hidden" id="compare_date_begin" name="compare_date_begin"
	value="">
<input type="hidden" id="compare_date_end" name="compare_date_end"
	value="">
<input type="hidden" id="folderlist" name="folderlist" value="">
<input type="hidden" id="eventlist" name="eventlist" value="">
<input type="hidden" id="time_zone" name="time_zone" value="user">
<jsp:include page="/admin/footertop.jsp">
	<jsp:param name="pfi" value="<%=pfo.sCacheID%>" />
	<jsp:param name="ufi" value="<%=ufo.sCacheID%>" />
	<jsp:param name="hidecopyright" value="1"/>
	<jsp:param name="hideconfidentiality" value="1"/>
</jsp:include>
<link href="/admin/css/jquery.datepick.css" rel="stylesheet" type="text/css" />
<link href="/admin/css/jquery.checkboxtree.css" rel="stylesheet" type="text/css" />
<style type="text/css">
#showSaveTemplate,#showAdvancedFilters {
	display: none;
	margin-left: 25px
}

.buttonLarge,.buttonLargeHover {
	font-family: Arial, Helvetica, sans-serif
}

.smallArrowText {
	padding: 0
}

.reportFilters,.reportFilters div {
	font-size: 11px
}

.costCenterName {
	width: 130px;
	overflow: hidden;
	display: inline-block;
	vertical-align: top;
	padding: 3px 0 4px 3px;
}

ul.unorderedlisttree {
	padding: 5px 0 0 20px
}
</style>
<script type="text/javascript" src="/js/jquery/jquery.datepick.min.js"></script>
<script type="text/javascript" src="/js/jquery/jquery.checkboxtree.js"></script>
<script type="text/javascript" src="/js/jquery/jquery.checkboxradiotree.js"></script>
<script type="text/javascript" src="/js/moment/moment.min.js"></script>
<!-- <script type="text/javascript" src="/js/moment/moment-timezone-with-data.min.js"></script> -->
<script type="text/javascript">
	var isDateRangeDivVis = false;
	var varEventId = '<%=sEventId%>';
	var isEventReport = <%=isEventSpecificRep%>;
	var varDataString = '<%=sQueryString%>';	
	//var varEventTitle = '<%=sEventName%>';
	var varWebinarReportType = '<%=webinar_report_type%>';
	var varReportRequestSource = '<%=source%>';
	var loadData = true;
	var isFancyBoxCreated = false;
	var reportingBaseUrl = '<%=sReportingBaseUrl%>';
	var isReportTemplateFeatureEnabled = <%=isReportTemplateFeatureEnabled%>;
	var adminHasLicense = <%=adminHasLicense%>;
	var adminIsSuperUser = <%=superUser%>;
	var isGuestPresenter = <%=isGuestPresenter%>;
	var sUserID = '<%=ufo.sUserID%>';
	if (<%=analyticsActive%> === true) {
		//analyticsExclude(["param_eventCostCenter"]);
	    if(varEventId !== '') {
	    	analyticsInit('<%=userId%>', {
	    		eventID: varEventId,
	    		clientID: '<%=sClientId%>'
	    	});
	    }
	    analyticsInit('<%=userId%>');	
	}
	
	$(document).ready(function() {
		$.initdialog();
		//programatically disable automplete for form fields
		$("#pageWrapper").find("input[name], select[name]").attr("autocomplete","off");
		
		$('#li_click_tracking > img').remove();
		$('#li_click_tracking > ul').remove();
		$(document).ready(function() {
			
			$("#startDatePicker").datepick({
					defaultDate: -30,
					showDefault: true
				});
			$("#endDatePicker").datepick({
					showDefault: true
				});
			$("#startDatePicker_bill").datepick({
				defaultDate: -30,
				showDefault: true
			});
			$("#endDatePicker_bill").datepick({
					showDefault: true
				});
			$("#compStartDatePicker").datepick();
			$("#compEndDatePicker").datepick();

			$("#month_select").append(getMonthYearRows());
			
			
			//createNestedTable();
			//dateRangeManipulator("dateRange_compare_text");
			if(isEventReport == true)
			{
				//$("#folder_events").text(varEventTitle);
				$("#eventlist").val(varEventId);
			}
			
			<%if(bShowTPCost){%>
			
			$("#tp_cost_report").show();
			$("#bill_tp_cost_report").show();
			<%}
			else{%>
				
				$("#tp_cost_report").hide();
				$("#bill_tp_cost_report").hide();
				<%}
			if(bShowClientInvoice){%>
			
			$("#client_invoice_report").show();
			$("#bill_client_invoice_report").show();
			<%}else{%>
				
				$("#client_invoice_report").hide();
				$("#bill_client_invoice_report").hide();
			<%}%>

			$("#result_live_odp_div").hide();
		});

		$("#btnAdvancedFilters span").on('click', function () {
      		$("#showAdvancedFilters").toggle('fast');
			$('#btnAdvancedFilters span.arrowClosed').toggleClass('arrowOpened')
		});
		
		$("#btnSaveTemplate").on('click', function () {
      		$("#showSaveTemplate").toggle('fast');
			$('#btnSaveTemplate span.arrowClosed').toggleClass('arrowOpened')
		});
		
		$("#result_no_dur_user").on('click', function () {
			$("#result_live_sess_user").attr("disabled", true);
			$("#result_od_sess_user").attr("disabled", true);
			$("#result_simlive_sess_user").attr("disabled", true);
			

			$("#result_live_sess_user").removeAttr("checked");
			$("#result_od_sess_user").removeAttr("checked");
			$("#result_simlive_sess_user").removeAttr("checked");
		});
		
		$("#result_dur_user").on('click', function () {
			$("#result_live_sess_user").removeAttr("disabled");
			$("#result_od_sess_user").removeAttr("disabled");			
			$("#result_simlive_sess_user").removeAttr("disabled");
		});

		$('#result_audaction').on('click', function(){
			if(!$(this).is(":checked")) {
				$('#result_regist').attr("disabled", "disabled");
				$('#result_vwsession').attr("disabled", "disabled");
			}else{
				$('#result_regist').removeAttr("disabled");
				$('#result_vwsession').removeAttr("disabled");
			}
		});

		$('#result_regist').on('click', function(){
			if($(this).is(":checked")) {
				$('#result_audaction').attr("checked", true);
				$('#result_vwsession').attr("checked", false);
			}
		});

		$('#result_vwsession').on('click', function(){
			if($(this).is(":checked")) {
				$('#result_audaction').attr("checked", true);
				$('#result_regist').attr('checked', false);
			}
		});
		
		$('#result_sti_checkbox').on('click', function() { 
		      if(!$(this).is(":checked")) {
		      	$('#result_sti_filter').attr("disabled", "disabled"); 
		      } else { 
				$("#result_sti_filter").removeAttr("disabled");
		      }
		});

		$('#result_sti_filter').on('click', function(){
			$('#result_sti_checkbox').attr('checked', true);
		});
		
		$("#add_folder").fancybox({
			'width'				: 600,
			'height'			: '98%',
	        'autoScale'     	: false,
	        'transitionIn'		: 'none',
			'transitionOut'		: 'none',
			'type'				: 'iframe',
			'href' 				: function() { return getURL(); },//function() { getURL() }
			'closeBtn' 			: false,
	        'autoSize'			: false,
			'openSpeed'			: 0,
			'closeSpeed'        : 'fast',
		    beforeShow : function() {
		      $('.fancybox-overlay').css({
		       	'background-color' :'rgba(119, 119, 119, 0.7)'
		       });
		      $('.fancybox-skin').css({
			     'padding': '0px'
			   });
		      removeAddFolder();
		    },
		    afterShow : function(){
		    	parent.$("html").removeAttr('class');
		    	parent.$("html").attr('class', '');
		    	parent.$('html')[0].className = '';
		    },
		    afterClose : function() {
		    	$("#add_folder").show();
		    	$("#add_folder_again").hide();
		    },
		    iframe: { preload: false },
			helpers : { 
			   'overlay' : {
				   'closeClick': false
			   }
			}
		});

		// $("#add_folder").on('click', function () {
		 //   $(".fancybox-overlay.fancybox-overlay-fixed").css('visibility', 'visible');
		//	removeAddFolder();
		// });
		
 		$("#add_folder_again").on('click', function () {
		   // $(".fancybox-overlay.fancybox-overlay-fixed").css('visibility', 'visible');
		   $("#add_folder").trigger('click');
		}); 
		
		
		
		$("#dateRange_compare_text").on('click', function () {
			dateRangeManipulator("dateRange_compare_text");
		});
		
		jQuery("#adv_audienceChildren").checkboxTree({
			collapsedarrow: "../admin/images/plus.gif",
			expandedarrow: "../admin/images/minus.gif",
			blankarrow: "../admin/images/blank.gif",
			checkchildren: true
		});
		jQuery("#adv_eventChildren").checkboxradioTree({
			collapsedarrow: "../admin/images/plus.gif",
			expandedarrow: "../admin/images/minus.gif",
			blankarrow: "../admin/images/blank.gif",
			checkchildren: true
		});
        jQuery("#adv_billingChildren").checkboxradioTree({
            collapsedarrow: "../admin/images/plus.gif",
            expandedarrow: "../admin/images/minus.gif",
            blankarrow: "../admin/images/blank.gif",
            checkchildren: true
        });
		$("#adv_audience").on('click', function() {
			showAdvanced('USER_DATA');
		});
		$("#adv_event").on('click', function() {
			showAdvanced('EVENT_DATA');
		});
        $("#adv_bill").on('click', function() {
            showAdvanced('BILLING');
        });
        $("#save_report_button").hover(function() {
			changeClass("#save_report_button","buttonHover");
	      },
	      function () {
	    	  changeClass("#save_report_button","button");
	      }
	    );
		/*$("#costCenterSearch").hover(function() {
			changeClass("#costCenterSearch","buttonHover");
	      },
	      function () {
	    	  changeClass("#costCenterSearch","button");
	      }
	    );
		$("#costCenterSearch_again").hover(function() {
			changeClass("#costCenterSearch_again","buttonHover");
	      },
	      function () {
	    	  changeClass("#costCenterSearch_again","button");
	      }
	    );*/
		
		$("#run_report_button").on('click', function() {
			runReportModule();
		});
		$("#run_report_button").hover(function() {
			changeClass("#run_report_button","buttonLargeHover");
	      },
	      function () {
	    	  changeClass("#run_report_button","buttonLarge");
	      }
	    );
		
		function disabledBtnsOnLoad(elem){
			$('#' + elem).prop('disabled', true);
			$('#' + elem).addClass('disabledButton');	
		}

		$("#save_report_template_button").on('click', function() {
			var params = {
					url: "reports_main_view_template_fancybox.jsp?<%=pfo.toQueryString()%>&<%=ufo.toQueryString()%>&page=newSave",
					width: 400,
					height: 175
			}
			viewManageSaveFancybox(params);
		});
		
		$("#save_changes_template_button").on('click', function() {
			updateReportTemplate(loadedTemplateInfo.templateId, loadedTemplateInfo.description, loadedTemplateInfo.isShared, true);
		});
		
		$("#view_report_template_button").on('click', function() {
			getReportTemplateSelections(openLoadReportTemplateFancyBox);
		});
						
		function openLoadReportTemplateFancyBox(){
			var params = {
					url: "reports_main_view_template_fancybox.jsp?<%=pfo.toQueryString()%>&<%=ufo.toQueryString()%>&page=view",
					width: 800,
					height: 610
			};
			
			viewManageSaveFancybox(params);
		}
		
		// show report template buttons if enabled on folder
		if(isReportTemplateFeatureEnabled){
			$('#viewReportTemplates').show();
			$('#saveReportTemplate').css({'display' : 'flex'});
			
			getReportTemplateSelections(enableLoadTemplateBtn);	
		}
			
		//alert('varWebinarReportType : '+ varWebinarReportType);
		if(varWebinarReportType == 5 || varWebinarReportType == 9)
		{
			disableColumnModifier('event');
		}
		else
		{
			disableColumnModifier('audience');
		}
		
		<%if (webinar_report_type == Constants.WEBINAR_REPORT_CLICK_TRACKING) {%>
			$("#report_type").trigger("click");
		<%}%>
		
		$('input[name=dateRange]:radio').change(function () {
			if ($('#dateRange_selector').is(':checked')) {
				$('#audience_action_filter_div').show();
				if ($("#dateRange_compare_text").text() != 'Add Compare Date') {
					$("#result_live_odp_div").hide();
				}
			} else {
				$('#audience_action_filter_div').hide();
				if (selectedEvents.split("|").length > 1) {
					$("#result_live_odp_div").show();
				}
			}
		});
	});

	function getMonthYearRows()
	{
		var localDate = new Date();
		var localYear = localDate.getFullYear();
		var localMonth = localDate.getMonth();

		var monthList = new Array("January", "February", "March", "April",
						 "May", "June", "July", "August",
						 "September", "October", "November", "December");
		
		var tmpMonth = localMonth;
		var tmpYear = localYear;
		var rowMtYr = '';
		for(var i = 0; i<3; i++)
		{
			for(j=0; j<12; j++)
			{				
				rowMtYr = rowMtYr + '<option value="'+(tmpMonth+1)+'/'+tmpYear+'">' + monthList[tmpMonth] + '  ' +  tmpYear + '</option>';
				if(tmpMonth == 0)
				{
					tmpMonth = 11;
					tmpYear--;
				}
				else
				{
					tmpMonth--;
				}
				//var tMonth = tmpMonth
			}
		}
		//alert(rowMtYr);
		return rowMtYr;
	}

	function removeAddFolder()
	{	
 		$("#add_folder").hide();
		$("#add_folder_again").show(); 
	}
	
	function hideIframe()
	{
	    if($.fancybox && $.fancybox.close){
	    	$.fancybox.close();
	    } else{
	    	$(".fancybox-overlay.fancybox-overlay-fixed").css('visibility', 'hidden');
	    }
	}
	
	function getURL()
	{
		return '/admin/folder_event_tree.jsp?' + varDataString + '&loadData=' + loadData + '&t=' + new Date().getTime();
	}
	var removeDateText = 'Remove Compare Date';

	// This method is used to automatically open or close
	// comparison date range selector.
	function dateRangeManipulator(selectedOption) {
		if (selectedOption == 'dateRange_compare_text')	{
			if ($("#dateRange_compare_text").text() == 'Add Compare Date') {
				changeSpanText('#dateRange_compare_text',removeDateText);
				$("#dateRange_compare_fields").show("fast");
				if ($('#dateRange_selector').is(':checked')) {
					$("#result_live_odp_div").hide();
				}
			} else {
				changeSpanText('#dateRange_compare_text','Add Compare Date');
				$("#dateRange_compare_fields").hide("fast");
				if (selectedEvents.split("|").length > 1) {
					$("#result_live_odp_div").show();
				}
			}
			return;
		}
	}
	var selectedColumns = '';
	var reportRequestString= '' ;
	var reportHidEventString= '' ;
	var reportHidFolderString= '' ;
	function runReportModule()
	{
		$("#runReportErrorSpan").remove();
		if(!validateInputs()) {
			return;
		}

		if (getTypeOfReport() == 'audience' || getTypeOfReport() == 'event') {
			runReportModuleNew();
			return;
		}	

		selectedColumns = '';
		var paramTypeOfReport = '';
		var isAudienceReport = false;
		var isEventAnalyticReport = false;
		var isBillingReport = false;
		var isAdvancedAudienceReport = false;
		var isAdvancedEventAnalyticReport = false;
        var isAdvancedBillingReport = false;
		var analyticReportType = '';
		
		if(getTypeOfReport() == 'audience')
		{
			var $audienceKids = $("#adv_audienceChildren").children("li");
			getSelectedReportedColumns($audienceKids);
			if(userDataAdvOptionShow == true)
			{
				isAdvancedAudienceReport = true;
				//getSelectedReportedColumns($audienceKids);
			}
			else
			{
				isAdvancedAudienceReport = false;
			}
						
			paramTypeOfReport = 'typeOfReport=audience';
			isAudienceReport = true; 
			isEventAnalyticReport = false;
			isBillingReport = false;
		}
		else if(getTypeOfReport() == 'event')
		{
			var $eventKids = $("#adv_eventChildren").children("li");
			getSelectedReportedColumns($eventKids);
			analyticReportType = getTypeOfAnalyticReport();
			if (analyticReportType === 'click_tracking') {
				selectedColumns = 'click_tracking_total^click_tracking_by_viewer';
			}
			if(eventDataAdvOptionShow == true)
			{
				isAdvancedEventAnalyticReport = true;
			}
			else
			{
				isAdvancedEventAnalyticReport = false;
			}
			paramTypeOfReport = "typeOfReport=event_analytics";
			isAudienceReport = false; 
			isEventAnalyticReport = true;
			isBillingReport = false;
		}
		else if(getTypeOfReport() == 'bill')
		{
            var $billingKids = $("#adv_billingChildren").children("li");
            getSelectedReportedColumns($billingKids);
            if(billingAdvOptionShow == true)
            {
                isAdvancedBillingReport = true;
            }
            else
            {
                isAdvancedBillingReport = false;
            }
			paramTypeOfReport = "typeOfReport=billing";
			//selectedColumns = '';
			isAudienceReport = false; 
			isEventAnalyticReport = false;
			isBillingReport = true;
		}
		
		//if($("#result_sti_checkbox").is(":checked")){
		//	selectedColumns += "^source_track_id";
		//}
	
		if((isAdvancedAudienceReport==true || (isAdvancedEventAnalyticReport==true && analyticReportType=='ed_usage')) && selectedColumns == '')
		{
			setError("#runReportError" , "Please select at least one column to run report", "runReportErrorSpan");			
			return;
		}
		var paramColsSelected = '';
		if(selectedColumns!='')
		{
			paramColsSelected = 'colsSelected='+selectedColumns;
		}
		
		var paramDateSel= getDateRange();
		
		var paramFolderList = '';
		if($("#folderlist").val()!='')
		{
			 paramFolderList = 'folderList=' + $("#folderlist").val();
		}
		//alert($("#eventlist").val());
		var paramEventList = '';
		if( isEventReport == true && $("#eventlist").val()!='')
		{
			 paramEventList = 'eventList=' + $("#eventlist").val();
		}			 

		var dataString = '<%=sQueryString%>';
		
		if(isEventReport)
		{
			dataString = dataString + '&' + paramTypeOfReport
							+ '&' + paramColsSelected 
							+ '&' + paramDateSel;
		}
		else
		{
			 dataString = dataString + '&' + paramTypeOfReport
				+ '&' + paramColsSelected 
				+ '&' + paramDateSel 
				+ '&' + paramFolderList 
				+ '&' + paramEventList;
		}

		dataString = dataString + getAdvancedFilter();
		if(varWebinarReportType == '4')
		{	//When a WEbinar admin wants a QA report we only show
			//Users with QA report only.
			dataString = dataString + "&qa_users=y&adv_filt=y";
		}		
		else if(varWebinarReportType == '3')
		{	//When a WEbinar admin wants a Survey report we only show
			//Users with Survey data only.
			dataString = dataString + "&survey_users=y&adv_filt=y";
		}
		
		dataString = dataString + "&video_report_type="+varWebinarReportType+"&report_request_src="+varReportRequestSource;
		
		dataString = dataString + '&timezone=' + $("#time_zone").val();
		
		reportHidFolderString = '<input type="hidden" id="folderList" val="'+selectedFolders +'">';
		if( isEventReport == false )
		{
			//dataString = dataString + '&eventList=' + selectedEvents;

			reportHidEventString = '<input type="hidden" id="eventList" val="'+selectedEvents +'">';
		}
		
	
		if(analyticReportType != ''){
			dataString = dataString + '&analytic_report_type=' + analyticReportType;
		}
		
		if(!$('#result_sti_filter').is(':disabled') && $('#result_sti_filter').val() != '') {
			dataString += "&result_sti_filter=" + $("#result_sti_filter").val();
		}

		if($('#result_live_odp_checkb').is(':checked')) {
			dataString += "&result_live_odp=y";
		}

		if($('#result_regist').is(':checked') && $('#result_audaction').is(":checked") ) {
			dataString += "&result_regist=y";
		}

		if($('#result_vwsession').is(':checked') && $('#result_audaction').is(":checked")) {
			dataString += "&result_vwsession=y";
		}

  
	// Ticket #2736
    //if($("#source_track_id").is(":checked") || $("#result_sti_checkbox").is(":checked")){
    if($("#source_track_id").is(":checked")){
      dataString += "&sou_tra_id=YES";
    }

		reportRequestString = dataString;
		//alert(reportRequestString);
		window.open ("","reportwindow");
		$('<form id="reporter_main_form" method ="post" target="reportwindow" ></form>').appendTo('body'); 
    	$('#reporter_main_form').attr("action",reportingBaseUrl + "reporter.jsp?"+reportRequestString);
    	
    	if(reportHidFolderString!='')
    	{
    		if($('#folderList').length == 0 )
    		{
    			$('<input name="folderList" id ="folderList" type="hidden"/>').appendTo('#reporter_main_form'); 
    			$('#folderList').attr("value",selectedFolders);
    		}
    		else
    		{
    			$('#folderList').val(selectedFolders);
    		}
    	}
    	
    	if(reportHidEventString!='')
    	{
    		//alert($('#eventList').val());
    		if($('#eventList').length == 0 ) {
        		$('<input name="eventList" id ="eventList" type="hidden"/>').appendTo('#reporter_main_form'); 
        		$('#eventList').attr("value",selectedEvents);
    		} else {
    			$('#eventList').val(selectedEvents);
    		}
    	}
    	
    	if(varEventId!='') {
    		if($('#ei').length == 0 ) {
    			$('<input name="ei" id ="ei" type="hidden"/>').appendTo('#reporter_main_form'); 
    			$('#ei').attr("value",varEventId);
    		} else {
    			$('#ei').val(varEventId);
    		}	        		
    	}
    	
    	$("#reporter_main_form").submit();
		//loadAjaxData("POST","proc_reportsmain.jsp",dataString);
	}
	
	function runReportModuleNew() {		
		$("#runReportErrorSpan").remove();
		if(!validateInputs()) {
			return;
		}

		var paramsString = getReportSelectionParams();

		var paramEventId = '';
		if (varEventId != '') {
			paramEventId = '&ei=' + varEventId;
		}

		paramsString += paramEventId;

		$('<form id="report_display_main_form" method="post" target="_blank"></form>').appendTo('body');
    	$('#report_display_main_form').attr('action', reportingBaseUrl + 'report_display.jsp?' + paramsString);
    	if (selectedEvents != '') {
    		if($('#eventIdList').length == 0 ) {
    			$('<input name="eventIdList" id="eventIdList" type="hidden"/>').appendTo('#report_display_main_form');
    		}
    		
    		$('#eventIdList').attr('value', selectedEvents);
		}
    	$('#report_display_main_form').submit();
	}

    function getReportSelectionParams() {

		selectedColumns = '';
		var paramTypeOfReport = '';
		var paramAnalyticReportType = '';

		var typeOfReport = getTypeOfReport();
		if (typeOfReport == 'audience') {
			var $audienceKids = $("#adv_audienceChildren").children("li");
			getSelectedReportedColumns($audienceKids);
						
			paramTypeOfReport = '&typeOfReport=audience';
		} else if (typeOfReport == 'event') {
			var $eventKids = $("#adv_eventChildren").children("li");
			getSelectedReportedColumns($eventKids);
			
			paramAnalyticReportType = '&analytic_report_type=' + getTypeOfAnalyticReport();
			
			paramTypeOfReport = '&typeOfReport=event_analytics';
		} else if (typeOfReport == 'bill') {
			if ($('#bill_expiring_events').is(':checked')) {
				paramTypeOfReport = '&typeOfReport=system_usage_expiring_events';
			} else if ($('#bill_scheduled_events').is(':checked')) {
				paramTypeOfReport = '&typeOfReport=system_usage_scheduled_events';
			} else if ($('#bill_client_invoice_report').is(':checked')) {
				paramTypeOfReport = '&typeOfReport=audio_bridge_client_invoice';
			} else {
				paramTypeOfReport = '&typeOfReport=system_usage';
			}

			selectedColumns = '';
		}

		var paramColsSelected = '';
		if (selectedColumns != '') {
			paramColsSelected = '&colsSelected=' + encodeURIComponent(selectedColumns);
		}

		var paramDateSel = '';
		if (typeOfReport == 'bill') {
			if ($("#dateRange_selector_bill:checked").val() == 'dateRange_select') {
				try {
					paramDateSel = '&startDate=' + Date.parse($("#startDatePicker_bill").val()) + '&endDate=' + (Date.parse($("#endDatePicker_bill").val()) + 86399999/*23:59:59.999 in millis*/);
				} catch (e) {
					paramDateSel = '&startDate=<%=ReportConstants.REPORT_DATE_RANGE_ALL%>&endDate=<%=ReportConstants.REPORT_DATE_RANGE_ALL%>';
				}
			} else if ($("#dateRange_month:checked").val() == 'dateRange_custom_month')	{
				paramDateSel = '&dateMonthYear=' + $('#month_select option:selected').val();
			}
		} else if ($("#dateRange_selector:checked").val() == 'dateRange_selector') {
			try {
				paramDateSel = '&startDate=' + Date.parse($("#startDatePicker").val()) + '&endDate=' + (Date.parse($("#endDatePicker").val()) + 86399999/*23:59:59.999 in millis*/);
			} catch (e) {
				paramDateSel = '&startDate=<%=ReportConstants.REPORT_DATE_RANGE_ALL%>&endDate=<%=ReportConstants.REPORT_DATE_RANGE_ALL%>';
			}
			if ($("#compStartDatePicker").is(":visible") && $("#compStartDatePicker").val() != '' && $("#compEndDatePicker").val() != '') {
				try {
					paramDateSel += '&compStartDate=' + Date.parse($("#compStartDatePicker").val()) + '&compEndDate=' + (Date.parse($("#compEndDatePicker").val()) + 86399999/*23:59:59.999 in millis*/);
				} catch (e) {
					//do nothing
				}
			}
		} else {
			paramDateSel = '&startDate=<%=ReportConstants.REPORT_DATE_RANGE_ALL%>&endDate=<%=ReportConstants.REPORT_DATE_RANGE_ALL%>';
		}
    	
		var dataString = '<%=sQueryString%>'
			+ '&tzid=' + '<%=au.tz.getID()%>'
			+ paramTypeOfReport
			+ paramAnalyticReportType
			+ paramColsSelected 
			+ paramDateSel
			+ getAdvancedFilter();
		
		if(document.getElementById('result_sti_checkbox').checked && document.getElementById('result_sti_checkbox').disabled === false){
			dataString += "&result_sti_filter=" + document.getElementById('result_sti_filter').value;
		}

		if(document.getElementById('result_unsubscribed_checkbox').checked && document.getElementById('result_unsubscribed_checkbox').disabled === false){
			dataString += "&result_unsubscribed_filter=y";
		}

		if($('#result_live_odp_div').is(":visible") && $('#result_live_odp_checkb').is(':checked') && ($("#dateRange_selector:checked").val() != 'dateRange_selector' || !$("#compStartDatePicker").is(":visible"))) {
			dataString += "&result_live_odp=y";
		}

		if(document.getElementById('result_audaction').checked ){
			dataString += $('#result_regist').is(':checked') ? "&result_regist=y" : "";
			dataString += $('#result_vwsession').is(':checked') ? "&result_vwsession=y" : "";
		} else {
			dataString += '&result_regist=y&result_vwsession=y';
		}
		
		return dataString;
	}

	/*var selCostCenterParamList = '';	
	function selectedCostCenter(paramList,costCenterNames)
	{
		selCostCenterParamList = paramList;
		$("#cost_center_names").html(costCenterNames);
	}*/
	
	function getAdvancedFilter()
	{
		var paramList = "";		
		//paramList = paramList + getCostCenterFilter();
		paramList = paramList + getEventStatusFilter();
		paramList = paramList + getDomainFilter();
		paramList = paramList + getQaUserFilter();
		paramList = paramList + getSurveyUserFilter();
		paramList = paramList + getUserDurationFilter();
		paramList = paramList + getUserSessionStatusFilter(); //live or OD users sessions.
		//paramList = paramList + getCostCenter();
		
		if(paramList != "")
		{
			paramList = "&adv_filt=y" + paramList;
		}
		return paramList;		
	}

	/*function getCostCenter()
	{
		return selCostCenterParamList;
	}*/
	
	/*function getSingleViewer()
	{	
		var paramList = "";
		alert($("#single_viewer").attr('checked'));
		if($("#single_viewer").attr('checked') == true)
		{
			paramList = paramList + "&single_user=" + $("#srch_viewer_id").val();
		}
		return paramList;
	}*/

	function getQaUserFilter()
	{
		var paramList = "";
		if($("#result_qa_user").prop('checked') == true)
		{
			paramList = paramList + "&qa_users=y";
		}
		return paramList;
	}
	
	function getSurveyUserFilter()
	{
		var paramList = "";
		if($("#result_survey_user").prop('checked') == true)
		{
			paramList = paramList + "&survey_users=y";
		}
		return paramList;
	}
	
	function getUserDurationFilter()
	{
		var paramList = "";
		if($("#result_attendance").prop('checked') == true)
		{
			if($("#result_dur_user").prop('checked') == true)
			{
				paramList = paramList + "&users_with_dur=y";
			}
			if($("#result_no_dur_user").prop('checked') == true)
			{
				paramList = paramList + "&users_no_dur=y";
			}
		}
		
		return paramList;
	}
	
	function getUserSessionStatusFilter()
	{
		var paramList = "";
		
		if($("#result_attendance").prop('checked') == true && $("#result_dur_user").prop('checked') == true)
		{
			if($("#result_live_sess_user").prop('checked') == true)
			{
				paramList = paramList + "&users_live_sess=y";
			}
			if($("#result_od_sess_user").prop('checked') == true)
			{
				paramList = paramList + "&users_od_sess=y";
			}
			if($("#result_simlive_sess_user").prop("checked")) {
				paramList += "&users_simlive_sess=y";
			}
		}
		return paramList;
	}

	function getDomainFilter()
	{
        var paramList = "";
		if($("#result_domains").prop('checked') == true)
		{
			$domainKids = $("#domain_filter_div").children("input:radio");
			for(var j = 0; j < $domainKids.length; j++)
	        {
				var $curElement = $domainKids[j];
				if(jQuery($curElement).prop('checked') == true)
				{
					if(jQuery($curElement).val() == 'exclude')
					{
						var excludeDomains = $("#email_domain_exclude_txt").val().split(";").join("|").split(",").join("|");
						paramList = "&excl_domain="+encodeURIComponent(excludeDomains);
					}
					else if(jQuery($curElement).val() == 'include')
					{
						var includeDomains = $("#email_domain_include_txt").val().split(";").join("|").split(",").join("|");
						paramList = "&incl_domain="+encodeURIComponent(includeDomains);
					}
				}				
	        }			
		}
		return paramList;	
	}

	function getEventStatusFilter()
	{
		var paramList = "";
		if($("#result_event_status").prop('checked') == true)
		{
			$eventStatusKids = $("#check_event_status").children("input:radio");
			for(var j = 0; j < $eventStatusKids.length; j++)
	        {
				var $curElement = $eventStatusKids[j];
				if(jQuery($curElement).prop('checked') == true)
				{
					paramList = paramList + jQuery($curElement).val() + "|";
				}
	        }
	        if(paramList!="")
	        {
	        	paramList = "&event_status=" + paramList;
	        }
		}
		return paramList;
		
	}

	function getTypeOfReport()
	{
		 if($("#sel_report_type input:radio:checked").val() == 'audience')
		 {
			 return 'audience';
		 }
		 else if($("#sel_report_type input:radio:checked").val() == 'event')
		 {
			 return 'event';
		 }
		 else if($("#sel_report_type input:radio:checked").val() == 'bill' || $("#sel_report_type input:radio:checked").val() == 'ed_usage' || $(".systemUsage #report_type").prop("checked"))
		 {
			 return 'bill';
		 }
	}

	function getDateRange()
	{
		var paramDateSel = '';
		switch(getTypeOfReport())
		{
			case 'bill':
					break;
			default:

				if($("#dateRange_creation:checked").val() == 'dateRange_creation')
				{
					paramDateSel = paramDateSel + '&dateRangeSelected=create'
				}
				else if($("#dateRange_selector:checked").val() == 'dateRange_selector')
				{
					paramDateSel = paramDateSel + '&dateRangeSelected=custom' + 
					'&custDateBegin='+$("#startDatePicker").val() +
					'&custDateEnd='+$("#endDatePicker").val();
				}

				if($("#dateRange_compare_text").text() == removeDateText)
				{
					paramDateSel = paramDateSel + '&compDateBegin='+$("#compStartDatePicker").val() +
					'&compDateEnd='+$("#compEndDatePicker").val()+"&showCompChart=true";
				}
				
		}
		return paramDateSel;
	}
	

	function getSelectedReportedColumns($liElement)
	{
		for(var i = 0; i < $liElement.length; i++)
        {
       	 	var $curElement = $liElement[i];
            var $labelElement = jQuery($curElement).children("label");

            if(jQuery($labelElement).hasClass("checked"))
            {
                if(selectedColumns!='')
                	selectedColumns = selectedColumns + '^';
            	selectedColumns = selectedColumns + jQuery($labelElement).attr('id');
            	
            }

            var $ulElement = jQuery($curElement).children("ul");
            {
            	for(var j = 0; j < $ulElement.length; j++)
                {
            		  var $kids = jQuery($ulElement).children("li");
            		  getSelectedReportedColumns($kids);
                }
            }
        }
	}

	var userDataAdvOptionShow = false;
	var eventDataAdvOptionShow = false;
    var billingAdvOptionShow = false;
	function showAdvanced(reportType)
	{
		if(reportType == 'USER_DATA')
		{
			if(userDataAdvOptionShow == false)
			{
				userDataAdvOptionShow = true;
				$('#audience_advanced').slideDown('fast');
				$('#adv_audience span').toggleClass("arrowOpened");
				


			}
			else
			{
				userDataAdvOptionShow = false;
				$('#audience_advanced').slideUp('fast');
				$('#adv_audience span').toggleClass("arrowOpened");
				
			}
		}
		else if(reportType == 'EVENT_DATA')
		{
			if(eventDataAdvOptionShow == false)
			{
				eventDataAdvOptionShow = true;
				$('#event_advanced').slideDown('fast');
				$('#adv_event span').toggleClass("arrowOpened");

			}
			else
			{
				eventDataAdvOptionShow = false;
				$('#event_advanced').slideUp('fast');
				$('#adv_event span').toggleClass("arrowOpened");

			}
		}
        else if(reportType == 'BILLING')
        {
            if(billingAdvOptionShow == false)
            {
                billingAdvOptionShow = true;
                $('#billing_advanced').slideDown('fast');
                $('#adv_bill span').toggleClass("arrowOpened");

            }
            else
            {
                billingAdvOptionShow = false;
                $('#billing_advanced').slideUp('fast');
                $('#adv_bill span').toggleClass("arrowOpened");

            }
        }
	}
	function changeSpanText(element,text)
	{
	    $(element).text(text);
	}

	function disableColumnModifier(element)
	{
		
		if(element == 'audience')
		{

             var $audienceKids = $("#adv_audienceChildren").children("li");
             enableLabels($audienceKids);

             var $billingKids = $("#adv_billingChildren").children("li");
             disableLabels($billingKids);

             var $eventKids = $("#adv_eventChildren").children("li");
             disableLabels($eventKids);

           
	         deactivateBillingMode();
	         enableFilters(varDisableBillingFilters);
		}
		else if(element ==  'event')
		{

            var $audienceKids = $("#adv_audienceChildren").children("li");
            disableLabels($audienceKids);

            var $billingKids = $("#adv_billingChildren").children("li");
            disableLabels($billingKids);

            var $eventKids = $("#adv_eventChildren").children("li");
            enableLabels($eventKids);

            deactivateBillingMode();
            
           
	        enableFilters(varDisableBillingFilters);
		}
		else if(element == 'bill')
		{
			 var $audienceKids = $("#adv_audienceChildren").children("li");
			 disableLabels($audienceKids);


	         var $eventKids = $("#adv_eventChildren").children("li");
	         disableLabels($eventKids);

            var $billKids = $("#adv_billingChildren").children("li");
            disableLabels($billKids);
            enableBillingTemporaryLabels($billKids);
            activateIntegratedAudioBillingMode();
           
	         disableFilters(varDisableBillingFilters);
		}
	}
	
	var varDisableBillingFilters = ['result_event_status','result_domains','result_qa_user','result_survey_user','result_attendance'];
	
	function enableFilters(varEnableFilter)
	{
		for(i=0;i<varEnableFilter.length;i++)
		{
			var varEnableId = varEnableFilter[i];
			$('#'+varEnableId).removeAttr('disabled');
		}
	}
	
	function disableFilters(varDisableFilter)
	{	
		for(i=0;i<varDisableFilter.length;i++)
		{
			var varDisableId = varDisableFilter[i];
			$('#'+varDisableId).attr('disabled', '');
		}
	}

	function disableLabels($liElement)
	{
		
		for(var i = 0; i < $liElement.length; i++)
        {
       	 	var $curElement = $liElement[i];
            var $labelElement = jQuery($curElement).children("label");

            if(jQuery($labelElement).hasClass("checkbox") || jQuery($labelElement).attr("class")=="" )
            {
            	jQuery($labelElement).removeClass("disabled-checkbox");
            	jQuery($labelElement).addClass("disabled-checkbox");
            }

            if(jQuery($labelElement).hasClass("checked"))
            {
            	jQuery($labelElement).removeClass("checked");
            	jQuery($labelElement).addClass("disabled-checkbox-checked");
            }
            
            
          //If label is for radio disable it and child radio button
            if(jQuery($labelElement).hasClass("radiolabel")){//} || jQuery($radioElement).hasClass("radiobutton")) {
            	jQuery($labelElement).attr('disabled', true);
            	var $kids = jQuery($labelElement).children();
                $kids.attr('disabled', true);
            }
            
            var $ulElement = jQuery($curElement).children("ul");
            {
            	for(var j = 0; j < $ulElement.length; j++)
                {
            		  var $kids = jQuery($ulElement).children("li");
                      disableLabels($kids);
                }
            }
        }
	}
    function enableBillingTemporaryLabels($liElement)
    {
        for(var i = 0; i < $liElement.length; i++)
        {
            var $curElement = $liElement[i];
            var $labelElement = jQuery($curElement).children("label");
            if( jQuery($labelElement).attr('id') == 'presenter_minutes' ||
                    jQuery($labelElement).attr('id') == 'audience_minutes'  ||
                    jQuery($labelElement).attr('id') == 'toll'  ||
                    jQuery($labelElement).attr('id') == 'toll_free'  ||
                    jQuery($labelElement).attr('id') == 'breakout_by_country' )
            {


                //alert('enable temporary labels');
                if( jQuery($labelElement).hasClass("disabled-checkbox-checked") )
                {
                    jQuery($labelElement).removeClass("disabled-checkbox-checked").addClass('checked');
                }
            }

          //If label is for radio disable it and child radio button
            if(jQuery($labelElement).hasClass("radiolabel")){
            	jQuery($labelElement).attr('disabled', false);
            	var $kids = jQuery($labelElement).children();
                $kids.attr('disabled', false);
            	
            }

            var $ulElement = jQuery($curElement).children("ul");
            {
                for(var j = 0; j < $ulElement.length; j++)
                {
                    var $kids = jQuery($ulElement).children("li");
                    enableBillingTemporaryLabels($kids);
                }
            }

        }

    }
	function enableLabels($liElement)
	{
		for(var i = 0; i < $liElement.length; i++)
        {
       	 	var $curElement = $liElement[i];
            var $labelElement = jQuery($curElement).children("label");

           if(jQuery($labelElement).hasClass("disabled-checkbox"))
            {
                jQuery($labelElement).removeClass("disabled-checkbox");
            }

            if(jQuery($labelElement).hasClass("disabled-checkbox-checked"))
            {
            	jQuery($labelElement).removeClass("disabled-checkbox-checked");
                jQuery($labelElement).addClass("checked");
            }

            if(jQuery($labelElement).hasClass("checked"))
            {

            }
            
          //If label is for radio disable it and child radio button
            if(jQuery($labelElement).hasClass("radiolabel")){//} || jQuery($radioElement).hasClass("radiobutton")) {
            	jQuery($labelElement).attr('disabled', false);
            	var $kids = jQuery($labelElement).children();
                $kids.attr('disabled', false);
            }

            var $ulElement = jQuery($curElement).children("ul");
            {
            	for(var j = 0; j < $ulElement.length; j++)
                {
            		  var $kids = jQuery($ulElement).children("li");
            		  enableLabels($kids);
                }
            }
        }
	}

	function selectedColumns()
	{
		var selectedReport = jQuery('#report_type input:radio:checked').val();
		//alert(selectedReport);
	}

	function changeClass(elementId,className)
	{
		$(elementId).attr('class',className);
	}

	function validateDateRange() {
		var dateFormats = ['MM/DD/YYYY', 'MM-DD-YYYY', 'MM.DD.YYYY'];

		var txtValidDateRange = "Select a valid Custom date Range";
		var txtValidStartDate = "Select a valid Start Date";
		var txtValidEndDate = "Select a valid Start Date";
		var txtStartEndDateGreater = "End Date should greater than Start Date";
		var txtValidCompDate = "Enter Comparison Start and End Dates";
		var txtValidCompStartDate = "Select a valid Comparison Begin Date";
		var txtValidCompEndDate = "Select a valid Comparison End Date";
		var txtStartCompEndDateGreater = "Comparison End Date should greater than Start Date"
		
		if (getTypeOfReport() == 'bill') {
			if ($('#dateRange_selector_bill').is(':checked')) {
				if ($("#startDatePicker_bill").val() == "" || $("#endDatePicker_bill").val() == "")	{
					setError("#runReportError", txtValidDateRange, "runReportErrorSpan");
					return false;
				} else {
					var startDateMoment = moment($("#startDatePicker_bill").val(), dateFormats, true);
					if (startDateMoment.isValid() === false) {
						setError("#runReportError", txtValidStartDate, "runReportErrorSpan");
						return false;
					}
					
					var endDateMoment = moment($("#endDatePicker_bill").val(), dateFormats, true);
					if (endDateMoment.isValid() === false) {
						setError("#runReportError", txtValidEndDate, "runReportErrorSpan");
						return false;
					}
					
					if (startDateMoment.isAfter(endDateMoment)) {
						setError("#runReportError", txtStartEndDateGreater, "runReportErrorSpan");
						return false;
					}
				}
			}
		} else {
			if ($('#dateRange_selector').is(':checked')) {
				if ($("#startDatePicker").val() == "" || $("#endDatePicker").val() == "") {
					setError("#runReportError", txtValidDateRange, "runReportErrorSpan");
					return false;
				} else {
					var startDateMoment = moment($("#startDatePicker").val(), dateFormats, true);
					if (startDateMoment.isValid() === false) {
						setError("#runReportError", txtValidStartDate, "runReportErrorSpan");
						return false;
					}
					
					var endDateMoment = moment($("#endDatePicker").val(), dateFormats, true);
					if (endDateMoment.isValid() === false) {
						setError("#runReportError", txtValidEndDate, "runReportErrorSpan");
						return false;
					}
					
					if (startDateMoment.isAfter(endDateMoment)) {
						setError("#runReportError", txtStartEndDateGreater, "runReportErrorSpan");
						return false;
					}
				}
			}
			
			if ($("#dateRange_compare_text").text() == removeDateText) {
				if ($("#compStartDatePicker").val() == "" || $("#compEndDatePicker").val() == "") {
					setError("#runReportError", txtValidCompDate, "runReportErrorSpan");
					return false;
				} else {
					var startDateMoment = moment($("#compStartDatePicker").val(), dateFormats, true);
					if (startDateMoment.isValid() === false) {
						setError("#runReportError", txtValidCompStartDate, "runReportErrorSpan");
						return false;
					}
					
					var endDateMoment = moment($("#compEndDatePicker").val(), dateFormats, true);
					if (endDateMoment.isValid() === false) {
						setError("#runReportError", txtValidCompEndDate, "runReportErrorSpan");
						return false;
					}
					
					if (startDateMoment.isAfter(endDateMoment)) {
						setError("#runReportError", txtStartCompEndDateGreater, "runReportErrorSpan");
						return false;
					}
				}
			}
		}

		return true;
	}

	var selectedFolders='';
	var selectedEvents='';
	var selectedPartiallyFolders='';
	var costCenter = "<%=sCostCenter%>";
	
	// If eventId exists in URL parameter, ensure it's included in selectedEvents
	if(varEventId && varEventId !== '') {
		selectedEvents = varEventId;
		//console.log("Event ID from URL initialized in selectedEvents:", varEventId);
	}
	
	function selectedFolderEvent(selectedEventFolders, partiallySelectedFolders)
	{
		var folderList = [];
		var eventList = [];
		var partialFolderList = [];
		loadData = false;
		
		// If eventId exists in URL, ensure it's always included
		if(varEventId && varEventId !== '') {
			eventList.push(varEventId);
		}
		
		if(selectedEventFolders!=undefined)
		{
			for(var i=0; i<selectedEventFolders.length; i++)
			{
				if(selectedEventFolders[i].length > 20)
				{
					folderList.push(selectedEventFolders[i]);
				}
				else
				{
					// Avoid duplicate event IDs
					if(selectedEventFolders[i] !== varEventId) {
						eventList.push(selectedEventFolders[i]);
					}
				}
			}
		}
		
		// Handle partially selected folders
		if(partiallySelectedFolders!=undefined && partiallySelectedFolders.length > 0)
		{
			for(var i=0; i<partiallySelectedFolders.length; i++)
			{
				if(partiallySelectedFolders[i].length > 20)
				{
					partialFolderList.push(partiallySelectedFolders[i]);
				}
			}
		}	
		selectedFolders = folderList.join("|");
		selectedEvents = eventList.join("|");
		selectedPartiallyFolders = partialFolderList.join("|");
		
		var folderTxt = '0 folders';
		if(folderList.length == 1)
		{
			folderTxt = '1 folder'
		}
		else if(folderList.length > 1)
		{
			folderTxt = folderList.length + ' folders'
		}

		var eventTxt = 'no event'
		if(eventList.length == 1)
		{
			eventTxt = '1 event'
      		if($("#result_live_odp_div").is(":visible")){
		    	$("#result_live_odp_div").hide();
		   	}
		}
		else if(eventList.length > 1)
		{
			eventTxt =eventList.length + ' events'
			if ($("#dateRange_compare_text").text() != 'Add Compare Date' && $('#dateRange_selector').is(':checked')) {
				$("#result_live_odp_div").hide();
			} else {
				$("#result_live_odp_div").show();
			}
		}

    	if(eventList.length == 0 && $("#result_live_odp_div").is(":visible")){
      		$("#result_live_odp_div").hide();
    	}

		isEventReport = false;
		//$("#folder_events").text("");
		$("#folder_events").text(folderTxt + ' and ' + eventTxt);
	}

	function validateInputs() {
		if (validateDateRange() == false) {
			return false;
		} else if (isEventReport == false && selectedFolders == '' && selectedEvents == '') {
			setError("#runReportError" , "Please select at least one event to run a report", "runReportErrorSpan");
			return false;
		}
		
		return true;
	}

    function selectedViewer(viewerId,viewerName)
	{
		//srch_viewer_id viewer_name
		$("#viewer_name").text(viewerName);
		$("#srch_viewer_id").val(viewerId);
		//alert(viewerId+"-"+viewerName);
	}
	function setError(elementId,errorMessage, identifier) {
		 //$(elementId).append("<span id = \"" +identifier+ "\" name = \"" +identifier+ "\" class =\"small-error-text\">" + errorMessage + "<br></span>");
		$.alert("Hmm. Something isn't right.",errorMessage,"icon_alert.png");
	}
	
	function loadAjaxData(methodType,urlString,dataString)
	{	
		$.ajax({ type: methodType,
            url: urlString ,
            data: dataString,
            dataType: 'json',
            success: getResult
        });
	}
	
	function getResult(jsonResult)
	{
		if(jsonResult!=undefined)
		{
			jsonResult = jsonResult[0];
	        if (!jsonResult.success) {
	        	var curErrorMsg = '';
	        	 for(var i = 0; i < jsonResult.errors.length; i++)
	             {
	        		 var curError =  jsonResult.errors[i];
	        		 curErrorMsg = curErrorMsg + curError.message + '<br>';
	             }
	        	 setError("#runReportError" , curErrorMsg , "runReportErrorSpan");
	        	 return;
	        }
	        else
	        {
	        	
	        	$('<form id="reporter_main_form" method ="post" target="reportwindow" ></form>').appendTo('body'); 
	        	$('#reporter_main_form').attr("action",reportingBaseUrl + "reporter.jsp?"+reportRequestString);
	        	
	        	if(reportHidFolderString!='')
	        	{
	        		if($('#folderList').length == 0 )
	        		{
	        			$('<input name="folderList" id ="folderList" type="hidden"/>').appendTo('#reporter_main_form'); 
	        			$('#folderList').attr("value",selectedFolders);
	        		}
	        		else
	        		{
	        			$('#folderList').val(selectedFolders);
	        		}
	        	}
	        	
	        	if(reportHidEventString!='')
	        	{
	        		//alert($('#eventList').val());
	        		if($('#eventList').length == 0 ) {
		        		$('<input name="eventList" id ="eventList" type="hidden"/>').appendTo('#reporter_main_form'); 
		        		$('#eventList').attr("value",selectedEvents);
	        		} else {
	        			$('#eventList').val(selectedEvents);
	        		}
	        	}
	        	
	        	if(varEventId!='') {
	        		if($('#ei').length == 0 ) {
	        			$('<input name="ei" id ="ei" type="hidden"/>').appendTo('#reporter_main_form'); 
	        			$('#ei').attr("value",varEventId);
	        		} else {
	        			$('#ei').val(varEventId);
	        		}	        		
	        	}
	        	$("#reporter_main_form").submit();
	        }
		} else {
            redirectError('An error occured while processing your request.');
		}
	}
	
	function getTypeOfAnalyticReport()
	{
		
		var selectedAnalytic = '';
		if($('input:radio[name=report_type]:checked').val() == 'event')
		{
			selectedAnalytic = $('input:radio[name=event_radiotree_demo]:checked').val();
		}
		return selectedAnalytic;
	}

    function getReportingFlags(varFlagType, filterReportingObj )
    {
        //alert('flag type : ' + varFlagType);
        if(varFlagType == 'single_event')
        {
            if(filterReportingObj.folderlist == '' && filterReportingObj.eventlist == '' && filterReportingObj.isSingleEvent != '')
            {
                return true;
            }
            else
            {
                return false;
            }
        }
        else if(varFlagType == 'multiple')
        {
            if(filterReportingObj.folderlist != '' || filterReportingObj.eventlist != '')
            {
                return true;
            }
            else
            {
                return false;
            }
        }
        else if(varFlagType == 'st_end_date')
        {
            if(filterReportingObj.dateRangeEnd !='' && filterReportingObj.dateRangeStart != '')
            {
                return true;
            }
            else
            {
                return false;
            }
        }
        else if(varFlagType == 'compare_st_end_date')
        {
            if(filterReportingObj.compare_dateRangeStart !='' && filterReportingObj.compare_dateRangeEnd != '')
            {
                return true;
            }
            else
            {
                return false;
            }
        }
        else if(varFlagType == 'dt_range_creation')
        {
            //alert('dt_range_creation = ' + $("#dateRange_creation:checked").val());
            if($("#dateRange_creation:checked").val() == 'dateRange_creation')
            {
                return true;
            }
            else
            {
                return false;
            }
        }
    }
 

    function getReportingDateRange(varDateType)
    {
        if($("#dateRange_selector:checked").val() == 'dateRange_selector')
        {
            if(varDateType == 'start')
            {
                return $("#startDatePicker").val();
            }
            else if(varDateType == 'end')
            {
                return $("#endDatePicker").val();
            }
            else if(varDateType == 'compare_date_start')
            {
                return $("#compStartDatePicker").val();
            }
            else if(varDateType == 'compare_date_end')
            {
                return $("#compEndDatePicker").val();
            }
        }
        return '';
    }


    // For Billing report
	function activateBillingMode()
	{
		
		//$("#reporting_date_range").hide();
	    //$("#billing_date_range").show();
	    $("#run_report_button").unbind();
	    $("#run_report_button").on('click', function() {
	    	runBillingReportModule();
	    	//runIntegratedAudioBillingReportModule();
		});
	}
    
	 function activateIntegratedAudioBillingMode()
	    {
	    	$("#reporting_date_range").hide();
		   $("#billing_date_range").show();
			
	        $("#run_report_button").unbind();
	        $("#run_report_button").bind({
	        	 click: function() {
	        		// do something on click
	        		 runBillingReportModule();
	        		}
	     
	        	
	        });
	    }
	
	function deactivateBillingMode()
	{
		$("#reporting_date_range").show();
	    $("#billing_date_range").hide();
	    
	    $("#run_report_button").unbind();
	    $("#run_report_button").on('click', function() {
			runReportModule();
		});
	}
 
	function runBillingReportModule() {
		if ($('#bill_tp_cost_report:checked').val() == 'tp_cost_report') {
			runIntegratedAudioBillingReportModule();
		} /* else if($('#bill_client_invoice_report:checked').val() == 'client_invoice_report') {
			runIAClientBillingReportModule();
		}  */else {
			runReportModuleNew();
		}
	}
	
	 function runIntegratedAudioBillingReportModule()
	    {
	       
	        $("#runReportErrorSpan").remove();
	        if(!validateInputs()) {
	            return;
	        }
	        
	        var varFilterIntegratedBillingAudioObj = new filterIntegratedBillingAudioObj();
	        //printFiltIntegratedAudiobillingObj(varFilterIntegratedBillingAudioObj);
	        var dataString = '<%=sQueryString%>';
	        window.open (reportingBaseUrl + 'integrated_audio_billing_reporter.jsp?'+dataString+'&window=true&typeOfReport=tp_cost_report',"integratedaudiobillingreportwindow");
	        submitIntegrateAudioBillingReportRequest(varFilterIntegratedBillingAudioObj);
	    }

	 function runIAClientBillingReportModule()
	    {
	        $("#runReportErrorSpan").remove();
	        if(!validateInputs()) {
	            return;
	        }
	        var varFilterIntegratedBillingAudioObj = new filterIntegratedBillingAudioObj();
	        //printFiltIntegratedAudiobillingObj(varFilterIntegratedBillingAudioObj);
	        var dataString = '<%=sQueryString%>';
	        window.open (reportingBaseUrl + 'integrated_audio_billing_reporter.jsp?'+dataString+'&window=true&typeOfReport=client_invoice_report',"integratedaudiobillingreportwindow");
	        submitIntegrateAudioClientBillingReportRequest(varFilterIntegratedBillingAudioObj);
	    }
	
	function submitIntegrateAudioBillingReportRequest(varFilterIntegratedBillingAudioObj)
	    {
		
	        // creating a form to submit your request.
	        $("#integrated_audio_billing_reporter_main_form").remove();
	       

	        $('#integrated_audio_billing_reporter_main_form').removeAttr("action");
	        
	        if( $('#integrated_audio_billing_reporter_main_form').attr("method")==undefined)
	        {
	            $('<form id="integrated_audio_billing_reporter_main_form" method ="post" target="integratedaudiobillingreportwindow" ></form>').appendTo('body');
	            $('#integrated_audio_billing_reporter_main_form').attr("action",reportingBaseUrl + 'integrated_audio_billing_reporter.jsp?&typeOfReport=tp_cost_report&'+dataString);
	            
	        }

	        //single event as hidden variable
	        if($('#integrateaudiobilling_ei').length == 0 )
	        {
	            $('<input name="integrateaudiobilling_ei" id ="integrateaudiobilling_ei" type="hidden"/>').appendTo('#integrated_audio_billing_reporter_main_form');
	            $('#integrateaudiobilling_ei').attr("value",varFilterIntegratedBillingAudioObj.ei);
	        }
	        else
	        {
	            $('#integrateaudiobilling_ei').val(varFilterIntegratedBillingAudioObj.ei);
	        }

	        //event list as hidden variable
	        if($('#integrateaudiobilling_event_list').length == 0 )
	        {
	            $('<input name="integrateaudiobilling_event_list" id ="integrateaudiobilling_event_list" type="hidden"/>').appendTo('#integrated_audio_billing_reporter_main_form');
	            $('#integrateaudiobilling_event_list').attr("value",varFilterIntegratedBillingAudioObj.eventlist);
	        }
	        else
	        {
	            $('#integrateaudiobilling_event_list').val(varFilterIntegratedBillingAudioObj.eventlist);
	        }

	        //folder list as hidden variable
	        if($('#integrateaudiobilling_folder_list').length == 0 )
	        {
	            $('<input name="integrateaudiobilling_folder_list" id ="integrateaudiobilling_folder_list" type="hidden"/>').appendTo('#integrated_audio_billing_reporter_main_form');
	            $('#integrateaudiobilling_folder_list').attr("value",varFilterIntegratedBillingAudioObj.folderlist);
	            
	        }
	        else
	        {
	            $('#integrateaudiobilling_folder_list').val(varFilterIntegratedBillingAudioObj.folderlist);
	        }
	      //month selected 
	    	if($('#integrateaudiobilling_month').length == 0 )
			{
	    		$('<input name="integrateaudiobilling_month" id ="integrateaudiobilling_month" type="hidden"/>').appendTo('#integrated_audio_billing_reporter_main_form'); 
	    		$('#integrateaudiobilling_month').attr("value",varFilterIntegratedBillingAudioObj.dateMonth);
			}
			else
			{
				$('#integrateaudiobilling_month').val(varFilterIntegratedBillingAudioObj.dateMonth);
			}
	        //date range selected - Start Date
	        
	        if($('#integrateaudiobilling_date_start').length == 0 )
	        {
	            $('<input name="integrateaudiobilling_date_start" id ="integrateaudiobilling_date_start" type="hidden"/>').appendTo('#integrated_audio_billing_reporter_main_form');
	            $('#integrateaudiobilling_date_start').attr("value",varFilterIntegratedBillingAudioObj.dateRangeStart);
	            
	        }
	        else
	        {
	            $('#integrateaudiobilling_date_start').val(varFilterIntegratedBillingAudioObj.dateRangeStart);
	        }

	        //date range selected - End Date
	        if($('#integrateaudiobilling_date_end').length == 0 )
	        {
	            $('<input name="integrateaudiobilling_date_end" id ="integrateaudiobilling_date_end" type="hidden"/>').appendTo('#integrated_audio_billing_reporter_main_form');
	            $('#integrateaudiobilling_date_end').attr("value",varFilterIntegratedBillingAudioObj.dateRangeEnd);
	            
	        }
	        else
	        {
	            $('#integrateaudiobilling_date_end').val(varFilterIntegratedBillingAudioObj.dateRangeEnd);
	        }

	        //cost center selected
	        if($('#integrateaudiobilling_cost_center').length == 0 )
	        {
	            $('<input name="integrateaudiobilling_cost_center" id ="integrateaudiobilling_cost_center" type="hidden"/>').appendTo('#integrated_audio_billing_reporter_main_form');
	            $('#integrateaudiobilling_cost_center').attr("value",varFilterIntegratedBillingAudioObj.cost_center);
	            
	        }
	        else
	        {
	            $('#integrateaudiobilling_cost_center').val(varFilterIntegratedBillingAudioObj.cost_center);
	        }

	        //is single event flags
	        if($('#integrateaudiobilling_single_event_flg').length == 0 )
	        {
	            $('<input name="integrateaudiobilling_single_event_flg" id ="integrateaudiobilling_single_event_flg" type="hidden"/>').appendTo('#integrated_audio_billing_reporter_main_form');
	            $('#integrateaudiobilling_single_event_flg').attr("value",varFilterIntegratedBillingAudioObj.is_single_event_flg);
	            
	        }
	        else
	        {
	            $('#integrateaudiobilling_single_event_flg').val(varFilterIntegratedBillingAudioObj.is_single_event_flg);
	        }

	        //is multi event flags
	        if($('#integrateaudiobilling_multi_event_flg').length == 0 )
	        {
	            $('<input name="integrateaudiobilling_multi_event_flg" id ="integrateaudiobilling_multi_event_flg" type="hidden"/>').appendTo('#integrated_audio_billing_reporter_main_form');
	            $('#integrateaudiobilling_multi_event_flg').attr("value",varFilterIntegratedBillingAudioObj.is_multi_event_folder_flg);
	            
	        }
	        else
	        {
	            $('#integrateaudiobilling_multi_event_flg').val(varFilterIntegratedBillingAudioObj.is_multi_event_folder_flg);
	        }

	        //is date range selected flag
	        if($('#integrateaudiobilling_date_range_flg').length == 0 )
	        {
	            $('<input name="integrateaudiobilling_date_range_flg" id ="integrateaudiobilling_date_range_flg" type="hidden"/>').appendTo('#integrated_audio_billing_reporter_main_form');
	            $('#integrateaudiobilling_date_range_flg').attr("value",varFilterIntegratedBillingAudioObj.is_start_end_date_flg);
	            
	        }
	        else
	        {
	            $('#integrateaudiobilling_date_range_flg').val(varFilterIntegratedBillingAudioObj.is_start_end_date_flg);
	        }

	     

	        //is single month selected flag
	        //alert( varFilterIntegratedAudioObj.is_date_since_creation_flg + ' - ' + $('#integrateaudio_date_since_creation_flg').length );
	       
	        
	      //is single month selected flag
	     
	    	if($('#integrateaudiobilling_single_month_flg').length == 0 )
			{
	    		
	    		$('<input name="integrateaudiobilling_single_month_flg" id ="integrateaudiobilling_single_month_flg" type="hidden"/>').appendTo('#integrated_audio_billing_reporter_main_form');
	    		
	    		$('#integrateaudiobilling_single_month_flg').attr("value",varFilterIntegratedBillingAudioObj.is_month_flg);
	    		
	    		
			}
			else
			{
				$('#integrateaudiobilling_single_month_flg').val(varFilterIntegratedBillingAudioObj.is_month_flg);
			}
			
	      
 			
	        $("#integrated_audio_billing_reporter_main_form").submit();
	    }
	 
	 function submitIntegrateAudioClientBillingReportRequest(varFilterIntegratedBillingAudioObj)
	    {
		
	        // creating a form to submit your request.
	        
		 $("#integrated_audio_billing_reporter_main_form").remove();
	       

	        $('#integrated_audio_billing_reporter_main_form').removeAttr("action");
		 
	        if( $('#integrated_audio_billing_reporter_main_form').attr("method")==undefined)
	        {
	            $('<form id="integrated_audio_billing_reporter_main_form" method ="post" target="integratedaudiobillingreportwindow" ></form>').appendTo('body');
	            $('#integrated_audio_billing_reporter_main_form').attr("action",reportingBaseUrl + 'integrated_audio_billing_reporter.jsp?&typeOfReport=client_invoice_report&'+dataString);
	            
	        }

	        //single event as hidden variable
	        if($('#integrateaudiobilling_ei').length == 0 )
	        {
	            $('<input name="integrateaudiobilling_ei" id ="integrateaudiobilling_ei" type="hidden"/>').appendTo('#integrated_audio_billing_reporter_main_form');
	            $('#integrateaudiobilling_ei').attr("value",varFilterIntegratedBillingAudioObj.ei);
	        }
	        else
	        {
	            $('#integrateaudiobilling_ei').val(varFilterIntegratedBillingAudioObj.ei);
	        }

	        //event list as hidden variable
	        if($('#integrateaudiobilling_event_list').length == 0 )
	        {
	            $('<input name="integrateaudiobilling_event_list" id ="integrateaudiobilling_event_list" type="hidden"/>').appendTo('#integrated_audio_billing_reporter_main_form');
	            $('#integrateaudiobilling_event_list').attr("value",varFilterIntegratedBillingAudioObj.eventlist);
	        }
	        else
	        {
	            $('#integrateaudiobilling_event_list').val(varFilterIntegratedBillingAudioObj.eventlist);
	        }

	        //folder list as hidden variable
	        if($('#integrateaudiobilling_folder_list').length == 0 )
	        {
	            $('<input name="integrateaudiobilling_folder_list" id ="integrateaudiobilling_folder_list" type="hidden"/>').appendTo('#integrated_audio_billing_reporter_main_form');
	            $('#integrateaudiobilling_folder_list').attr("value",varFilterIntegratedBillingAudioObj.folderlist);
	            
	        }
	        else
	        {
	            $('#integrateaudiobilling_folder_list').val(varFilterIntegratedBillingAudioObj.folderlist);
	        }
	        
	        //month selected 
	    	if($('#integrateaudiobilling_month').length == 0 )
			{
	    		$('<input name="integrateaudiobilling_month" id ="integrateaudiobilling_month" type="hidden"/>').appendTo('#integrated_audio_billing_reporter_main_form'); 
	    		$('#integrateaudiobilling_month').attr("value",varFilterIntegratedBillingAudioObj.dateMonth);
			}
			else
			{
				$('#integrateaudiobilling_month').val(varFilterIntegratedBillingAudioObj.dateMonth);
			}

	        //date range selected - Start Date
	        
	        if($('#integrateaudiobilling_date_start').length == 0 )
	        {
	            $('<input name="integrateaudiobilling_date_start" id ="integrateaudiobilling_date_start" type="hidden"/>').appendTo('#integrated_audio_billing_reporter_main_form');
	            $('#integrateaudiobilling_date_start').attr("value",varFilterIntegratedBillingAudioObj.dateRangeStart);
	            
	        }
	        else
	        {
	            $('#integrateaudiobilling_date_start').val(varFilterIntegratedBillingAudioObj.dateRangeStart);
	        }

	        //date range selected - End Date
	        if($('#integrateaudiobilling_date_end').length == 0 )
	        {
	            $('<input name="integrateaudiobilling_date_end" id ="integrateaudiobilling_date_end" type="hidden"/>').appendTo('#integrated_audio_billing_reporter_main_form');
	            $('#integrateaudiobilling_date_end').attr("value",varFilterIntegratedBillingAudioObj.dateRangeEnd);
	            
	        }
	        else
	        {
	            $('#integrateaudiobilling_date_end').val(varFilterIntegratedBillingAudioObj.dateRangeEnd);
	        }

	        //cost center selected
	        if($('#integrateaudiobilling_cost_center').length == 0 )
	        {
	            $('<input name="integrateaudiobilling_cost_center" id ="integrateaudiobilling_cost_center" type="hidden"/>').appendTo('#integrated_audio_billing_reporter_main_form');
	            $('#integrateaudiobilling_cost_center').attr("value",varFilterIntegratedBillingAudioObj.cost_center);
	            
	        }
	        else
	        {
	            $('#integrateaudiobilling_cost_center').val(varFilterIntegratedBillingAudioObj.cost_center);
	        }

	        //is single event flags
	        if($('#integrateaudiobilling_single_event_flg').length == 0 )
	        {
	            $('<input name="integrateaudiobilling_single_event_flg" id ="integrateaudiobilling_single_event_flg" type="hidden"/>').appendTo('#integrated_audio_billing_reporter_main_form');
	            $('#integrateaudiobilling_single_event_flg').attr("value",varFilterIntegratedBillingAudioObj.is_single_event_flg);
	            
	        }
	        else
	        {
	            $('#integrateaudiobilling_single_event_flg').val(varFilterIntegratedBillingAudioObj.is_single_event_flg);
	        }

	        //is multi event flags
	        if($('#integrateaudiobilling_multi_event_flg').length == 0 )
	        {
	            $('<input name="integrateaudiobilling_multi_event_flg" id ="integrateaudiobilling_multi_event_flg" type="hidden"/>').appendTo('#integrated_audio_billing_reporter_main_form');
	            $('#integrateaudiobilling_multi_event_flg').attr("value",varFilterIntegratedBillingAudioObj.is_multi_event_folder_flg);
	            
	        }
	        else
	        {
	            $('#integrateaudiobilling_multi_event_flg').val(varFilterIntegratedBillingAudioObj.is_multi_event_folder_flg);
	        }

	        //is date range selected flag
	        if($('#integrateaudiobilling_date_range_flg').length == 0 )
	        {
	            $('<input name="integrateaudiobilling_date_range_flg" id ="integrateaudiobilling_date_range_flg" type="hidden"/>').appendTo('#integrated_audio_billing_reporter_main_form');
	            $('#integrateaudiobilling_date_range_flg').attr("value",varFilterIntegratedBillingAudioObj.is_start_end_date_flg);
	           
	        }
	        else
	        {
	            $('#integrateaudiobilling_date_range_flg').val(varFilterIntegratedBillingAudioObj.is_start_end_date_flg);
	        }

	      //is single month selected flag
	      
	    	if($('#integrateaudiobilling_single_month_flg').length == 0 )
			{
	    		
	    		$('<input name="integrateaudiobilling_single_month_flg" id ="integrateaudiobilling_single_month_flg" type="hidden"/>').appendTo('#integrated_audio_billing_reporter_main_form');
	    		
	    		$('#integrateaudiobilling_single_month_flg').attr("value",varFilterIntegratedBillingAudioObj.is_month_flg);
	    		
	    		
			}
			else
			{
				$('#integrateaudiobilling_single_month_flg').val(varFilterIntegratedBillingAudioObj.is_month_flg);
			}
			
	     
			
	        $("#integrated_audio_billing_reporter_main_form").submit();
	    }
	function printBillingReportFilterObj()
	{
		var varFiltBillingObj = new filterBillingObj();
		
		printFiltBillingObj(varFiltBillingObj);
	}
	
	function filterBillingObj()
	{
		this.folderlist = selectedFolders;
		this.eventlist = selectedEvents;
		this.ei = varEventId;
		this.dateRangeStart = getBillingDateRange('start');
		this.dateRangeEnd = getBillingDateRange('end');
		this.dateMonth = getBillingDateRange('month');
		//this.cost_center = getCostCenterFilterParams();
		this.cost_center= costCenter;
		this.is_single_event_flg = getBillingFlags('single_event',this);
		this.is_multi_event_folder_flg = getBillingFlags('multiple',this);
		this.is_month_flg = getBillingFlags('month',this);
		this.is_start_end_date_flg = getBillingFlags('st_end_date',this);
        this.cols_selected=selectedColumns;
	}
	
	function getBillingFlags(varFlagType, filtBillObj )
	{	
		if(varFlagType == 'single_event')
		{
			if(filtBillObj.folderlist == '' && filtBillObj.eventlist == '' && filtBillObj.isSingleEvent != '')
			{
				return true;
			}
			else
			{
				return false;
			}
		}
		else if(varFlagType == 'multiple')
		{
			if(filtBillObj.folderlist != '' || filtBillObj.eventlist != '')
			{
				return true;
			}
			else
			{
				return false;
			}
		}
		else if(varFlagType == 'month')
		{
			if(filtBillObj.dateMonth!='' && filtBillObj.dateRangeStart == '')
			{
				return true;	
			}
			else
			{
				return false;	
			}
		}
		else if(varFlagType == 'st_end_date')
		{
			if(this.dateRangeEnd !='' && filtBillObj.dateRangeStart != '' && filtBillObj.dateMonth=='')
			{
				return true;	
			}
			else
			{
				return false;	
			}
		}
	}
	
	function getBillingDateRange(varDateType)
	{		
		if($("#dateRange_selector_bill:checked").val() == 'dateRange_select')
		{
			if(varDateType == 'start')
			{
				return $("#startDatePicker_bill").val();
			}
			else if(varDateType == 'end')
			{
				return $("#endDatePicker_bill").val();
			}
		}
		else if($("#dateRange_month:checked").val() == 'dateRange_custom_month')
		{
			if(varDateType == 'month')
			{
				return $('#month_select option:selected').val();
			}
		}
		return '';
	}

	function printFiltBillingObj( filtBillObj )
	{
		alert( ' Folder List= ' +  filtBillObj.folderlist + 
			   '\n' +
			   ' Event List=  ' +  filtBillObj.eventlist + 
			   '\n' +
			   ' Date Start =  ' +  filtBillObj.dateRangeStart+ 
			   '\n' +
			   ' Date End =  ' +  filtBillObj.dateRangeEnd+ 
			   '\n' +
			   ' Month =  ' +  filtBillObj.dateMonth+ 
			   '\n' +
			   ' Ei =  ' +  filtBillObj.ei+  
			   '\n' +
			  ' Cost Center =  ' +  filtBillObj.cost_center+ 
			   '\n' +  
			   ' Single Event =  ' +  filtBillObj.is_single_event_flg+ 
			   '\n' +
			   ' Multiple Event =  ' +  filtBillObj.is_multi_event_folder_flg + 
			   '\n' +
			   ' Is Month selected =  ' +  filtBillObj.is_month_flg  + 
			   '\n' +
			   ' Is Date Range selected =  ' +  filtBillObj.is_start_end_date_flg +
                '\n' +
                ' Cols selected =  ' +  filtBillObj.cols_selected );
	}
	
	 function getCostCenterFilterParams()
	{
		var paramList = '';
		$costCenterKids = $("#check_cost_center").children("input:checkbox");
		for(var j = 0; j < $costCenterKids.length; j++)
        {
			var $curElement = $costCenterKids[j];
			if(jQuery($curElement).prop('checked') == true)
			{
				paramList = paramList + jQuery($curElement).val() + "|";
			}
        }
		return paramList;
	}

    function commonAjaxParams() {
        this.<%=Constants.RQUSERID%> = '<%=StringTools.n2s(request.getParameter(Constants.RQUSERID))%>';
        this.<%=Constants.RQSESSIONID%> = '<%=StringTools.n2s(request.getParameter(Constants.RQSESSIONID))%>';
        this.<%=Constants.RQFOLDERID%> = '<%=StringTools.n2s(request.getParameter(Constants.RQFOLDERID))%>';
    }
    
    var getReportTemplateSelectionsData = "";
    var loadedTemplateInfo = {};

    function getReportTemplateSelections(callback) {
    	var params = new commonAjaxParams();
        params.action = 'getselection';

        $.ajax({
			method: "GET",
			url: "proc_report_template.jsp",
			data: params,
			dataType: 'json',
			success: function(jsonResult){
				//$.alert("Return data:", JSON.stringify(jsonResult,null,2),"");
				if(jsonResult.reportTemplates.length > 0 || jsonResult.sharedTemplates.length > 0){
					getReportTemplateSelectionsData = jsonResult;
					callback();
				}
			},
			error: function(xmlHttpRequest, status, errorThrown) {
				//$.alert('Oops! Something went wrong.', 'error:' + errorThrown + 'status:' + status, 'icon_error.png');
                var errorMsg = JSON.parse(xmlHttpRequest.responseText).error.message[0];
                $.alert('Oops! Something went wrong.', 'Error: ' + xmlHttpRequest.status + '; ' + errorMsg, 'icon_error.png');
	        }
		});
    }

    function applyTemplate(templateJson){
    	//console.log(templateJson);
    	
    	switch(templateJson.report_type){
    	  case "AUDIENCE":
    		updateAudienceReport(templateJson);
    	    break;
    	  case "EVENT_ANALYTICS_USAGE":
    	  case "EVENT_ANALYTICS_STI":
    	  case "EVENT_ANALYTICS_LOCATIONS":
    	  case "EVENT_ANALYTICS_CLICK_TRACKING":
    	  case "EVENT_ANALYTICS_MEDIA_REPORT":
    	  case "EVENT_ANALYTICS_SENTIMENT_TRACKING_REPORT":
    	  case "EVENT_ANALYTICS_SURVEY_SUMMARY":
    	  case "EVENT_ANALYTICS_QA_SUMMARY":
    	  case "EVENT_ANALYTICS_CE_DETAILS":
    	  case "EVENT_ANALYTICS_AUDIO_BRIDGE_CALL_USAGE":
    		updateEventAnalyticsUsage(templateJson);
    	    break;
    	  case "SYSTEM_USAGE":
    	  case "SYSTEM_USAGE_EXPIRING_EVENTS":
    	  case "SYSTEM_USAGE_SCHEDULED_EVENTS":
    	  case "AUDIO_BRIDGE_CLIENT_INVOICE":
    		updateSystemUsage(templateJson);
    		break;
    	  default:
    	    console.log('Error in applyTemplate function');
    	} 
    	
    	updateFilters(templateJson);
    }
    
    function updateFilters(templateJson){
    	// clear filters
    	var inputLength = $('#showAdvancedFilters input').length;
    	
    	for(var x = 0; x < inputLength; x++){
    		$('#showAdvancedFilters input')[x].checked = false;
    	}
    	
		document.getElementsByName('email_domain_include_txt')[0].value = "";
		document.getElementById('email_domain_exclude_txt').value = "";
		document.getElementById('result_sti_filter').value = "";
		// document.getElementById('startDatePicker').value = "";
		// document.getElementById('endDatePicker').value = "";
		document.getElementById('dateRange_creation').checked = true;
        	
    	// Domain or Email
    	if(typeof templateJson.email_domain_filters !== "undefined"){
    		document.getElementById("result_domains").checked = true;
    		
    		if(templateJson.is_email_domain_include){
    			$('#domain_filter_div input[type=radio]')[1].click();
    			let emailsLength = templateJson.email_domain_filters.length;
    			
        		for(var x = 0; x < emailsLength; x++){
        			document.getElementsByName('email_domain_include_txt')[0].value += templateJson.email_domain_filters[x].replaceAll(' ', '');
        			
        			if(emailsLength !== (x+1)){
        				document.getElementsByName('email_domain_include_txt')[0].value += ", ";
        			}
        		}
    		}else{
    			$('#domain_filter_div input[type=radio]')[0].click();
    			let emailsLength = templateJson.email_domain_filters.length;
    			
        		for(var x = 0; x <emailsLength; x++){
        			document.getElementById('email_domain_exclude_txt').value += templateJson.email_domain_filters[x].replaceAll(' ', '');
        			
        			if(emailsLength !== (x+1)){
        				document.getElementById('email_domain_exclude_txt').value += ", ";
        			}
        		}
    			
    		}
    	}
    	
    	// Attendence 
    	if(templateJson.is_no_show_filter || templateJson.is_with_views_filter){
    		document.getElementById("result_attendance").checked = true;
    		
    		if(templateJson.is_no_show_filter){
    			document.getElementById("result_no_dur_user").checked = true;
    		}else{
    			document.getElementById("result_dur_user").checked = true;
    			
    			if(templateJson.is_live_filter){
    				document.getElementById("result_live_sess_user").checked = true;
    			}
    			
    			if(templateJson.is_od_filter){
    				document.getElementById("result_od_sess_user").checked = true;
    			}
    			
    			if(templateJson.is_simlive_filter){
    				document.getElementById("result_simlive_sess_user").checked = true;
    			}
    		}
    	}
    	
    	// Viewer Data
    	if(templateJson.is_qa_filter){
    		document.getElementById("result_qa_user").checked = true;
    	}
    	
    	if(templateJson.is_survey_filter){
    		document.getElementById("result_survey_user").checked = true;
    	}
    	
    	// Audience Actions
    	if(templateJson.is_view_session_filter != templateJson.is_reg_date_filter){
    		document.getElementById("result_audaction").checked = true;
    		
    		if(templateJson.is_view_session_filter){
    			document.getElementById("result_vwsession").checked = true;
    		}else{
       			document.getElementById("result_regist").checked = true;
    		}
    	}
   
    	// Source Track Identifier (STI)
    	if(typeof templateJson.sti_filter !== "undefined"){
    		document.getElementById('result_sti_checkbox').checked = true;
    		document.getElementById('result_sti_filter').value = templateJson.sti_filter[0];
    	}

    	// Unsubscribed Users
    	if(typeof templateJson.is_unsubscribed_user_filter !== "undefined"){
    		document.getElementById('result_unsubscribed_checkbox').checked = true;
    	}
    	
    	// date range section
    	/*
    	if(templateJson.end_date === 0 || templateJson.start_date === 0){
    		document.getElementById('dateRange_creation').checked = true;
    	}else{
    		document.getElementById('dateRange_selector').checked = true;
    		document.getElementById('startDatePicker').value = formatDate(templateJson.start_date, 'MM/DD/YYYY');
    		document.getElementById('endDatePicker').value = formatDate(templateJson.end_date, 'MM/DD/YYYY');
    	}
    	*/
    }
    /*
	function formatDate(utcMillis, format) {
		var numMillis = parseInt(utcMillis);
		
		if (isNaN(numMillis) || numMillis === 0) {
			return ''; 
		} else {
			return moment.tz(numMillis, 'US\/Eastern').format(format);
		}
	}
    */
    function updateSystemUsage(templateJson){
    	$('.reportType:eq(2) #report_type').click();
    	
    	var checkboxIdsJson = {
       		"SYSTEM_USAGE" : "overall_billing_report",
           	"SYSTEM_USAGE_EXPIRING_EVENTS" : "expiring_events",
           	"SYSTEM_USAGE_SCHEDULED_EVENTS" : "scheduled_events",
           	"AUDIO_BRIDGE_CLIENT_INVOICE" : "client_invoice_report"
    	};
      		
       changeRadioBtn(checkboxIdsJson[templateJson.report_type]);
    }
    
    function updateEventAnalyticsUsage(templateJson){
		$('.reportType:eq(1) #report_type').click();
		
		var eventAnalyticsUsageCheckboxLength = $('.reportType:eq(1) input').length;	
   		clearCheckboxes(eventAnalyticsUsageCheckboxLength, 1);
    	
    	if(templateJson.report_type === "EVENT_ANALYTICS_USAGE"){
        	var checkboxIdsJson = {
           		"NOTHING" : "tot_regs",
           			"NOTHING" : "unique_emails",
           			    "live_unique_emails" : "att_live_unique_emails",
           		        "od_unique_emails" : "att_od_unique_emails", 
           		        "simlive_unique_emails" : "att_simlive_unique_emails",
           		        "live_unique_registrants" : "att_total_unique_emails_at_event_end",
           			    "tot_regs" : "att_total_unique_emails",
           			"NOTHING" : "attendees",
           			    "live_sessions" : "att_live",
           			    "od_sessions" : "att_archive",
           			    "simlive_sessions" : "att_simlive",
           			    "total_sessions" : "att_total",
           			"viewers_no_show" : "att_no_show",
           			"live_conversion" : "att_live_conversion",
           			"total_conversion" : "att_conversion",
               	"NOTHING" : "tot_dur",
           			"live_durations" : "dur_live",
           			"od_durations" : "dur_archive",
           			"simlive_durations" : "dur_simlive",
           			"total_durations" : "dur_total"
           	};
       		
        	if($('#ed_usage input[type=radio]').prop('checked') === false){
        		$('#ed_usage').click();
        	}		
       		
       		var dataColumnsLength = templateJson.data_columns.length;
       		
       		for(var x = 0; x < dataColumnsLength; x++){
       			var elemId = checkboxIdsJson[templateJson.data_columns[x]];
 
       			if(typeof elemId !== "undefined" && elemId !== "NOTHING"){
       				var elemId = '#' + elemId;
       				changeCheckbox(elemId);
       			}
       		}
           	
    	}else if(templateJson.report_type === "EVENT_ANALYTICS_CE_DETAILS" && templateJson.data_columns.length === 15){ 
			// fix for duplicate report type
       		changeRadioBtn('nasba_ce_canned_report');
    	}else{
           	var radioBtnsJson = {	
           		"EVENT_ANALYTICS_STI" : "sti_report",
           		"EVENT_ANALYTICS_LOCATIONS" : "location_report",
           		"EVENT_ANALYTICS_CLICK_TRACKING" : "click_tracking",
           		"EVENT_ANALYTICS_MEDIA_REPORT" : "media_report",
           		"EVENT_ANALYTICS_SENTIMENT_TRACKING_REPORT" : "sentiment_tracking_report",
           		"EVENT_ANALYTICS_SURVEY_SUMMARY" : "survey_summary",
           		"EVENT_ANALYTICS_QA_SUMMARY" : "qa_summary",
           		"EVENT_ANALYTICS_CE_DETAILS" : "ce_canned_report",
           		"EVENT_ANALYTICS_AUDIO_BRIDGE_CALL_USAGE" : "audio_bridge_call_usage"
           	}
       		
       		changeRadioBtn(radioBtnsJson[templateJson.report_type]);
    	}
    };
    
    function updateAudienceReport(templateJson){
    	if($('.reportType:eq(0) #report_type').prop('checked') === false){
    		$('.reportType:eq(0) #report_type').click();
    	}
    	
   		 var checkboxIdsJson = {
   		   "NOTHING" : "Reg_Data",
   		       "NOTHING" : "Std_Reg_Data",
	    		  "email" : "email",
	    		  "firstname" : "firstname",
	    		  "lastname" : "lastname",
	    		  "company" : "company",
	    		  "title" : "title",
	    		  "reg_dtreg" : "reg_dtreg",
	    		  "address1" : "address1",
	    		  "address2" : "address2",
	    		  "city" : "city",
	    		  "state" : "state",
	    		  "postalcode" : "postalcode",
	    		  "country" : "country",
	    		  "phone" : "phone",
	    		  "mobile" : "mobile",
	    		  "fax" : "fax",
	    		  "ip_address" : "ip_address",
	    		  "unsubscribe" : "unsubscribe",
   		  	  "reg_cust" : "reg_cust",
   		  	  "source_track_id" : "source_track_id",
   		  "qa_questions" : "qa_questions",
   		  "NOTHING" : "survey_data",
    		  "in_event" : "in_event",
    		  "attendance" : "attendance",
    		  "post_event" : "post_event",
    		  "NOTHING" : "ce_result",
    		  	  "ce_score" : "ce_score",
	    		  "ce_percentage" : "ce_percentage",
	    		  "ce_att_score" : "ce_att_score",
	    		  "ce_pass_status" : "ce_pass_status",
    		  "NOTHING" : "nasba_ce_result",
	    		  "first_login" : "first_login",
	    		  "last_logout" : "last_logout",
	    		  "net_live_dur" : "net_live_dur",
	    		  "min_live_dur" : "min_live_dur",
	    		  "ce_surveys_sent" : "ce_surveys_sent",
	    		  "ce_min_surveys" : "ce_min_surveys",
	    		  "ce_surveys_answered" : "ce_surveys_answered",
	    		  "ce_pct_surveys" : "ce_pct_surveys",
	    		  "ce_pass_status" : "ce_pass_status", 
    		  "ce_link" : "ce_link",
   		  "NOTHING" : "ud_usage",
    		  "referrer" : "referrer",
    		  "NOTHING" : "sesion_break", 
    		  "NOTHING" : "times_view",
    		  	"live_sessions" : "live_view",
	    		  "od_sessions" : "od_view",
	    		  "simlive_sessions" : "simlive_view",
	    		  "total_sessions" : "total_view",
    		  "NOTHING" : "duration",
	    		  "live_duration" : "live_duration",
	    		  "od_duration" : "od_duration",
	    		  "simlive_duration" : "simlive_duration",
	    		  "total_duration" : "total_duration"
    	}
   		 
   		$('#ed_usage').click();
   		 
   		var audienceCheckboxLength = $('.reportType:eq(0) input').length;
   		clearCheckboxes(audienceCheckboxLength, 0);
   		
   		var dataColumnsLength = templateJson.data_columns.length;
   		
   		for(var x = 0; x < dataColumnsLength; x++){
   			var elemId = checkboxIdsJson[templateJson.data_columns[x]];
 
   			if(typeof elemId !== "undefined" && elemId !== "NOTHING"){
   				var elemId = '#' + elemId;
   				changeCheckbox(elemId);
   			}
   		}

   		// check duplicated ce_pass_status
   		if(document.getElementById('nasba_ce_result').checked){
   			document.getElementById('nasba_ce_result').nextSibling.nextSibling.lastChild.querySelector('label').click()
   		}
   		
   		// check sessions Breaks
   		if(templateJson.sub_table_columns.length){
   			changeCheckbox('#sesion_break');
   		}
    }
    
    function clearCheckboxes(checkBoxLength, column){
   		// clear audience checkboxes
    	for(x = 1; x < checkBoxLength; x++){
   			$('.reportType:eq("' + column + '") input')[x].checked = false;
   			$('.reportType:eq("' + column + '") input:eq("' + x + '")').next().removeClass('checked');
   		}
    }
    
	function changeCheckbox(element){		
		$(element).next().click();
	}
	
	function changeRadioBtn(element){
		$('#' + element + ' input[type=radio]').click();
	}
	
	function loadNewlyCreatedTemplateID(){
		var myNewTemplate = getReportTemplateSelectionsData.reportTemplates.filter(template => template.description === loadedTemplateInfo.description);
		
		if(myNewTemplate.length === 0){
			myNewTemplate = getReportTemplateSelectionsData.sharedTemplates.filter(template => template.description === loadedTemplateInfo.description);
		}
		
		loadedTemplateInfo.templateId = myNewTemplate[0].templateId;
	}
	
	function getNewlyCreatedTemplateID(){
		setTimeout(function(){
			getReportTemplateSelections(loadNewlyCreatedTemplateID);
		},2000);
	}
	
	function enableSaveChangesBtn(){
		$('#loadedTemplate').show();
		document.getElementById('loadedTemplate').innerHTML = '<span style="font-weight: 800;">Loaded Template:</span> ' + loadedTemplateInfo.description + '';
		
		if(loadedTemplateInfo.isShared === true && sUserID !== loadedTemplateInfo.adminId){
			$('#save_changes_template_button').addClass('disabledButton');
			document.getElementById("save_changes_template_button").disabled = true;
		}else{
			$('#save_changes_template_button').removeClass('disabledButton');
			document.getElementById("save_changes_template_button").disabled = false;
		}
	}
	
	function disabledDeletedLoadedTempalate(templateId){
		if(loadedTemplateInfo.templateId === templateId){
			$('#loadedTemplate').hide();
			document.getElementById('loadedTemplate').innerHTML = '';
			$('#save_changes_template_button').addClass('disabledButton');
			document.getElementById("save_changes_template_button").disabled = true;
		}
	}
	
	// check for templates and if any enable load button
	function enableLoadTemplateBtn(){
		if(getReportTemplateSelectionsData !== ""){
			if(getReportTemplateSelectionsData.reportTemplates.length || getReportTemplateSelectionsData.sharedTemplates.length){
				document.getElementById("view_report_template_button").disabled = false;
				$('#view_report_template_button').removeClass('disabledButton');
			}
		}else{
			document.getElementById("view_report_template_button").disabled = true;
			$('#view_report_template_button').addClass('disabledButton');
		}
	}
		
	function viewManageSaveFancybox(params){
		$.fancybox({
			'width'				: params.width,
			'height'			: params.height,
			'autoScale'     	: false,
			'transitionIn'		: 'none',
			'transitionOut'		: 'none',
			'type'				: 'iframe',
			'href' 				: params.url,
			'hideOnOverlayClick': false,
			'scrolling'			: 'no',
			'beforeClose'		: function(){},
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

	function getReportTemplate(templateId) {
		var params = new commonAjaxParams();
		params.templateid = templateId;
		params.action = 'gettemplate';
		
   	  	$.ajax({
			method: "GET",
			url: "proc_report_template.jsp",
			data: params,
			dataType: 'json',
			success: function(jsonResult){
				//$.success("Report Template read successfully!", JSON.stringify(jsonResult,null,2),"");
				applyTemplate(JSON.parse(jsonResult.templateJSON));
				loadedTemplateInfo = {
						"templateId" : jsonResult.templateId,
						"description" : jsonResult.description,
						"isShared" : jsonResult.isShared,
						"adminId" : jsonResult.adminId
				}
				enableSaveChangesBtn();
			},
			error: function(xmlHttpRequest, status, errorThrown) {
				$.alert('Oops! Something went wrong.', 'error:' + errorThrown, 'icon_error.png');
            }			
		});
	}

	function deleteReportTemplates(templateIds) {
		var params = new commonAjaxParams();
        params.action = 'delete',
        params.templateids = templateIds;

   	  	$.ajax({
			method: "POST",
			url: "proc_report_template.jsp",
			data: params,
			dataType: 'json',
			success: function(jsonResult) {
				//$.success("Report Template deleted successfully!", JSON.stringify(jsonResult,null,2),"");
				$.alert("Report Template deleted successfully!", jsonResult.TemplateId, "icon_check.png");
			},
			error: function(xmlHttpRequest, status, errorThrown) {
				//$.alert('Oops! Something went wrong.', 'Error: ' + errorThrown, 'icon_error.png');
				$.alert('Oops! Something went wrong.', 'Error: ' + xmlHttpRequest.status, 'icon_error.png');
            }			
		});
	}

	function saveReportTemplate(description, isShared) {
		$("#runReportErrorSpan").remove();
		if (!validateDateRange()) {
			return;
		}

		var paramsString = getReportSelectionParams();

		var params = Object.fromEntries(new URLSearchParams(paramsString));
        params.action = 'create',
        params.description = description;
        params.isshared = isShared;
        
  	  	$.ajax({
			type: "POST",
			url: "proc_report_template.jsp",
			data: params,
			dataType: 'json',
			success: function(jsonResult){
				//$.alert("Report Template saved successfully!", JSON.stringify(jsonResult,null,2), "icon_check.png");
				$.alert("Report Template saved successfully!", jsonResult.TemplateId, "icon_check.png");
			},
		    error: function(xmlHttpRequest, status, errorThrown) {
			    //$.alert('Oops! Something went wrong.', 'Error: ' + errorThrown, 'icon_error.png');
			    var errorMsg = JSON.parse(xmlHttpRequest.responseText).error.message[0];
			    $.alert('Oops! Something went wrong.', 'Error: ' + xmlHttpRequest.status + '; ' + errorMsg, 'icon_error.png');
            }	
		});
	}

	function updateReportTemplate(templateId, description, isShared, updateSelectionsBool) {
		$("#runReportErrorSpan").remove();

		if (!validateDateRange()) {
			return;
		}

		if(updateSelectionsBool === true){
			var paramsString = getReportSelectionParams();
		}else{
			var paramsString = '<%=sQueryString%>';
		}
		
		var params = Object.fromEntries(new URLSearchParams(paramsString));
        params.action = 'update',
        params.templateid = templateId;
        params.description = description;
        params.isshared = isShared;
        
  	  	$.ajax({
			type: "POST",
			url: "proc_report_template.jsp",
			data: params,
			dataType: 'json',
			success: function(jsonResult){
				//$.alert("Report Template updated successfully!", JSON.stringify(jsonResult,null,2), "icon_check.png");
				$.alert("Report Template updated successfully!", "", "icon_check.png");
			},
		    error: function(xmlHttpRequest, status, errorThrown) {
			    //$.alert('Oops! Something went wrong.', 'Error: ' + errorThrown, 'icon_error.png');
			    var errorMsg = JSON.parse(xmlHttpRequest.responseText).error.message[0];
			    $.alert('Oops! Something went wrong.', 'Error: ' + xmlHttpRequest.status + '; ' + errorMsg, 'icon_error.png');
            }	
		});
	}

</script>
<jsp:include page="/admin/footerbottom.jsp">
	<jsp:param name="pfi" value="<%=pfo.sCacheID%>" />
	<jsp:param name="ufi" value="<%=ufo.sCacheID%>" />
</jsp:include>
<%
	} catch (Exception e) {
		//response.sendRedirect(ErrorHandler.handle(e, request));
		Logger.getInstance().log(Logger.INFO,"reports_main.jsp",ErrorHandler.getStackTrace(e));
		out.print("Error completing action");
	}
%>
