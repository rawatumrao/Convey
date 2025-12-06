<%@ page import="tcorej.*,org.json.*,java.util.*,tcorej.bean.ClientBean"  trimDirectiveWhitespaces="true"%>
<%@ include file="/include/globalinclude.jsp"%>
<%
Logger logger = Logger.getInstance();
JSONArray jsonParentArray = new JSONArray();
JSONArray jsonErrorArray = new JSONArray();
JSONObject jsonParentObject = new JSONObject();

try{
    PFO pfo = new PFO(request);
    UFO ufo = new UFO(request);
    
    // user datastructure
    AdminUser au = null;

    // remote IP
    String sIPAddr = request.getRemoteAddr();

    // tell the pfo to secure the page
    pfo.secure();

    // check security
    if ((ufo != null && pfo != null) && pfo.security) {
            if (!StringTools.isNullOrEmpty(ufo.sUserID)) {
                    au = AdminUser.getInstance(ufo.sUserID);

                    if (pfo.DEBUG) {
                        logger.log(Logger.INFO, "jsp", pfo.dump(),pfo.sContainerPage); 
                        logger.log(Logger.INFO, "jsp",ufo.dump(), pfo.sContainerPage);
                    }
            } else {
            	out.print("{\"error\":true,\"error_type\":\"auth\",\"error_message\":\"Not logged in.  Please log in again.\"}");
                return;
            }
    }

    String sUserID= ufo.sUserID;

    String folderId = StringTools.n2s(request.getParameter("folderId"));
    String parentFolderId=StringTools.n2s(request.getParameter("parentFolderId"));
    String newParentFolderId=StringTools.n2s(request.getParameter("newParentFolderId"));
    String action = StringTools.n2s(request.getParameter("action"));
    String folderName = StringTools.n2s(request.getParameter("folderName"));
    String eventId = StringTools.n2s(request.getParameter("eventId"));
    int iEventId = StringTools.n2i(eventId,-1);
  
    if(!Constants.EMPTY.equals(parentFolderId) && !au.canAccessFolder(parentFolderId)){
    	out.print("{\"error\":true,\"error_type\":\"auth\",\"error_message\":\"Invalid Request -1.  Please log in again.\"}");
        return;
    }
    if(!Constants.EMPTY.equals(newParentFolderId) && !au.canAccessFolder(newParentFolderId)){
    	out.print("{\"error\":true,\"error_type\":\"auth\",\"error_message\":\"Invalid Request-2.  Please log in again.\"}");
        return;
    }
    if(!Constants.EMPTY.equals(folderId) && !au.canAccessFolder(folderId)){
    	out.print("{\"error\":true,\"error_type\":\"auth\",\"error_message\":\"Invalid Request-3.  Please log in again.\"}");
        return;
    }
    if(iEventId>0 && !au.canViewEvent(iEventId)){
    	out.print("{\"error\":true,\"error_type\":\"auth\",\"error_message\":\"Invalid Request-4.  Please log in again.\"}");
        return;
    }
    if(action.equals("getChildren")){
        out.println(AdminFolder.getImmediateChildren(sUserID, parentFolderId, Constants.EMPTY, new ArrayList<JSONObject>(0)).toString());
    }else if(action.equals("saveHiearchy")){
    	if(au.can(Perms.User.MOVEFOLDERS)){
    		out.println(AdminFolder.moveFolder(sUserID,folderId,parentFolderId,newParentFolderId));
    	}else{
    		jsonErrorArray.put(General.createJSONErrorObject(Constants.EMPTY, "Admin does not have permission to move folders."));	
    	} 
    }else if(action.equals("rename")){
    	if(au.can(Perms.User.RENAMEFOLDERS)){
    		out.println(AdminFolder.renameFolder(sUserID,folderId,folderName,folderName));
    	}else{
    		jsonErrorArray.put(General.createJSONErrorObject(Constants.EMPTY, "Admin does not have permission to rename folders."));	
    	} 
    }else if(action.equals("delete")){
    	if(au.can(Perms.User.DELETEFOLDERS)){
    		out.println(AdminFolder.deleteFolder(sUserID,folderId));
    	}else{
    		jsonErrorArray.put(General.createJSONErrorObject(Constants.EMPTY, "Admin does not have permission to delete folders."));	
    	}  
    }else if(action.equals("checkdelete")){
        out.println(AdminFolder.isFolderDeletable(sUserID,folderId));
    }else if(action.equals("add")){
    	if(au.can(Perms.User.CREATEFOLDERS)){
    		out.println(AdminFolder.addFolder(sUserID,parentFolderId,folderName,folderName));
    	}else{
    		jsonErrorArray.put(General.createJSONErrorObject(Constants.EMPTY, "Admin does not have permission to create folders."));	
    	}    	
    }else if(action.equals("moveEvent")){
    	if(au.can(Perms.User.MOVEPRESENTATIONS)){
    		out.println(AdminFolder.moveEvent(sUserID,eventId,parentFolderId,newParentFolderId));	
    	}else{
    		jsonErrorArray.put(General.createJSONErrorObject(Constants.EMPTY, "Admin does not have permission to move events."));	
    	}
    }else if(action.equals("eventList")){
        out.println("{\"aaData\": " + AdminFolder.getEventListByType(sUserID,folderId,Constants.EVENT_TYPE.REGULAR.value()).toString() + "}");
    }else if(action.equals("deletedeventList")){
    	out.println("{\"aaData\": " + AdminFolder.getDeletedEventList(sUserID,folderId).toString() + "}");
    }else if(action.equals("portalList")){
        out.println("{\"aaData\": " + AdminFolder.getEventListByType(sUserID,folderId,Constants.EVENT_TYPE.PORTAL.value()).toString() + "}");
    }
    else if(action.equals("getFolderAndEvent")){
    	boolean bIsForLinkSegments = StringTools.n2b(request.getParameter("linksegment"));
            ArrayList<JSONObject> alFolderProperty = AdminFolder.getEventsAndFolder(sUserID, parentFolderId, Constants.EMPTY, new ArrayList<JSONObject>(0),bIsForLinkSegments);
            if(alFolderProperty == null){
            	alFolderProperty = new ArrayList<JSONObject>();
            }
         //   if(alFolderProperty!=null && !alFolderProperty.isEmpty()){
                     out.println(alFolderProperty.toString());
        //    }
    }
    else if(action.equals("getFolderAndActiveEvent")){
    	boolean bIsForLinkSegments = StringTools.n2b(request.getParameter("linksegment"));
            ArrayList<JSONObject> alFolderProperty = AdminFolder.getActiveEventsAndFolder(sUserID, parentFolderId, Constants.EMPTY, new ArrayList<JSONObject>(0),bIsForLinkSegments);
            if(alFolderProperty == null){
            	alFolderProperty = new ArrayList<JSONObject>();
            }
         //   if(alFolderProperty!=null && !alFolderProperty.isEmpty()){
                     out.println(alFolderProperty.toString());
        //    }
    }
    else if(action.equals("getViewerDomain")){
    	ClientBean clientInfo = AdminClientManagement.getClientByName(AdminFolder.getClientName(folderId));
        out.println(clientInfo.getViewerDomain().trim());
    }else if(action.equals("getsettingid")){
    	out.println("{\"settingid\": \"" + AdminFolder.getFolderSettingId(sUserID,folderId,false) + "\"}");
	}
    
    if(jsonErrorArray.length() > 0){
    	 jsonParentObject.put(Constants.JSON_FORM_SUCCESS,jsonErrorArray.length()==0);
	   	 jsonParentObject.put(Constants.JSON_FORM_ERRORS_LIST,jsonErrorArray);
	   	 jsonParentArray.put(jsonParentObject);		
	   	 out.print(jsonParentArray.toString());	
    }else{
    	return ;	
    }
    
}catch(Exception e){
	logger.log(Logger.CRIT,"Exception handling folder request",ErrorHandler.getStackTrace(e));
	out.print("{\"error\":true,\"error_message\":\"Exception Caught\"}");
    //response.sendRedirect(ErrorHandler.handle(e, request));
}
%>