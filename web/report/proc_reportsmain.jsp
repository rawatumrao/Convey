<%@ page import="tcorej.*"%>
<%@ page import="org.json.*"%>
<%@ include file="/include/globalinclude.jsp"%>
<%@ page trimDirectiveWhitespaces="true" %>

<%

JSONArray jsonParentArray = new JSONArray();
JSONObject jsonParentObject = new JSONObject();
JSONObject jsonPassThruObject = new JSONObject();
JSONArray jsonErrorArray = new JSONArray();
	Logger logger = Logger.getInstance(Constants.LogFile.VIEWER); 
	try{
		//boolean hasErrors = false;
		jsonParentObject.put(Constants.JSON_FORM_SUCCESS,true);
		jsonParentObject.put(Constants.JSON_FORM_ERRORS_LIST,jsonErrorArray);  			
		jsonParentArray.put(jsonParentObject);
		out.println(jsonParentArray.toString());
	}
	catch(Exception e)
	{
		jsonErrorArray.put(General.createJSONErrorObject("frmLogin","Oops! Something went wrong. We are working hard to get this fixed."));
		jsonParentObject.put(Constants.JSON_FORM_SUCCESS,false);
		jsonParentObject.put(Constants.JSON_FORM_ERRORS_LIST,jsonErrorArray);

		logger.log(Logger.INFO,"jsp","There was an error processing your request."+e.getMessage()+"<br>","proc_reportsmain.jsp");
		logger.log(Logger.CRIT,"jsp",ErrorHandler.getStackTrace(e),"proc_reportsmain.jsp");


		jsonParentArray.put(jsonParentObject);
		out.print(jsonParentArray.toString());
	}
%>