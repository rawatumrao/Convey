<%@ page import="java.util.*"%>
<%@ page import="tcorej.*"%>
<%@ page import="tcorej.bean.*"%>
<%@ page import="tcorej.reports.*"%>
<%@ page import="org.json.*"%>

<%@ include file="/include/globalinclude.jsp"%>
<%
	String sFolderList = StringTools.n2s(request.getParameter("folderList"));
	String sEventList = StringTools.n2s(request.getParameter("eventList"));
	
	ArrayList<String> selectedFolders = ReportingService.getList(sFolderList,"|");
	ArrayList<String> selectedEvents = ReportingService.getList(sEventList,"|");
	
	ArrayList<FolderDetailsBean> tarrAllFolders = new ArrayList<FolderDetailsBean>();
	AdminFolder adminFolder = new AdminFolder();
	tarrAllFolders = adminFolder.getFolderDetails(selectedFolders);
	List<FolderDetailsBean> allFolders = adminFolder.getFolderList(tarrAllFolders, selectedFolders);
	
	JSONObject foldersJSON = new JSONObject();
	HashSet<String> folderIdHash = new HashSet<String>();
	if (allFolders != null && !allFolders.isEmpty()) {
		for (FolderDetailsBean folderBean: allFolders) {
			if (!folderIdHash.contains(folderBean.getFolderid())) {
				folderIdHash.add(folderBean.getFolderid());
				foldersJSON.append("FolderDetailsBean", new JSONObject().put("Folderid", folderBean.getFolderid()));
			}
		}
	}
		
	JSONObject eventsJSON = new JSONObject();
	HashSet<String> eventIdHash = new HashSet<String>();
	for (String eventId : selectedEvents) {
		eventIdHash.add(eventId);
		eventsJSON.append("EventTableBean", new JSONObject().put("EventId", eventId));
	}
	List<String> eventsInSelectedFolders = ReportUtils.getEventIdsByFolderIds(new ArrayList<String>(folderIdHash));
	for (String eventId : eventsInSelectedFolders) {
		if (!eventIdHash.contains(eventId)) {
			eventsJSON.append("EventTableBean", new JSONObject().put("EventId", eventId));
		}
	}
	
	JSONObject resultJSON = new JSONObject();
	resultJSON.put("success", true);
	resultJSON.put("sel_events", eventsJSON);
	resultJSON.put("sel_folders", foldersJSON);
	
	out.println(new JSONArray().put(resultJSON).toString());
%>
