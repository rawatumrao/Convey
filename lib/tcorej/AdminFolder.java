/*
 * To change this template, choose Tools | Templates and open the template in the editor.
 */
package tcorej;

import java.text.SimpleDateFormat;
import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.StringTokenizer;
import java.util.TimeZone;

import org.json.JSONArray;
import org.json.JSONObject;

import com.google.common.base.Joiner;
import com.google.common.collect.ImmutableSet;

import tcorej.Constants.ConfigFile;
import tcorej.Constants.LogFile;
import tcorej.bean.EventListBean;
import tcorej.bean.FolderBean;
import tcorej.bean.FolderDetailsBean;
import tcorej.bean.FolderEventBean;
import tcorej.bean.portal.Portal;
import tcorej.dao.DBDAO;

/**
 *
 * @author mshah
 */
public class AdminFolder {
	private static final Logger LOGGER = Logger.getInstance(LogFile.ADMIN_FOLDER_LIST);
	private static final Configurator GLOBAL_CONFIG = Configurator.getInstance(ConfigFile.GLOBAL);

	/**
	 * Get foldergroup of a folder.
	 *
	 * @param folderId
	 * @return
	 */
	public static String getFolderGroup(final String folderId) {
		return getFolderGroup(folderId, null);
	}

	public static String getFolderGroup(final String folderId, String sDBSource) {
		if (folderId.equals(Constants.TALKPOINT_ROOT_FOLDERID)) {
			return Constants.TALKPOINT_ROOT_FOLDERID;
		}

		final String query = "SELECT foldergroup FROM tbfolder WHERE folderid = ?";
		String folderGroup = Constants.EMPTY;

		sDBSource = StringTools.isNullOrEmpty(sDBSource) ? Constants.DB_ADMINDB : sDBSource;
		try {
			final ArrayList<HashMap<String, String>> alResult = DBDAO.get(GLOBAL_CONFIG.get(sDBSource), query, DBDAO.getParams(folderId), false);

			if (!alResult.isEmpty()) {
				folderGroup = alResult.get(0).get("foldergroup");
			}
		} catch (final Exception e) {
			LOGGER.log(Logger.CRIT, AdminFolder.class.getSimpleName(), "Error getting folder group for folder: " + folderId, "getFolderGroup()");
			LOGGER.log(Logger.INFO, AdminFolder.class.getSimpleName(), ErrorHandler.getStackTrace(e), "getFolderGroup()");
		}

		return folderGroup;
	}

	private static boolean checkClientFolder(final String userId, final String foldername) {
		String query = Constants.EMPTY;
		final ArrayList<Object> alParams = new ArrayList<>();
		boolean clientExist = true;

		try {
			query = "SELECT count(*) as cnt FROM tbfolder WHERE parentid = ? and name= ?";
			alParams.add(Constants.TALKPOINT_ROOT_FOLDERID);
			alParams.add(foldername);
			clientExist = Integer.parseInt(DBDAO.get(GLOBAL_CONFIG.get(Constants.DB_ADMINDB), query, alParams, false).get(0).get("cnt")) > 0 ? true
					: false;

		} catch (final Exception e) {
			LOGGER.log(Logger.CRIT, AdminFolder.class.getSimpleName(), "Error executing " + foldername + " USERID: " + userId, "checkClientFolder()");
			LOGGER.log(Logger.INFO, AdminFolder.class.getSimpleName(), ErrorHandler.getStackTrace(e), "checkClientFolder()");
		}
		return clientExist;
	}

	/*
	 * getFolderName() - return folder name given an id.
	 */
	public static String getFolderName(final String sFolderID) {
		String rv = null;

		if (sFolderID != null && !Constants.EMPTY.equals(sFolderID)) {
			final String query = "SELECT name FROM tbfolder WHERE folderid = ?";
			final ArrayList<Object> queryParam = new ArrayList<>();
			queryParam.add(sFolderID);
			ArrayList<HashMap<String, String>> ral = new ArrayList<>();

			ral = DBDAO.get(GLOBAL_CONFIG.get(Constants.DB_ADMINDB), query, queryParam, true);

			if (!ral.isEmpty()) {
				rv = ral.get(0).get("name");
			}
		}

		return rv;
	}

	/*
	 * getFolderId() - return folder Id given a name.
	 */
	public static String getFolderId(final String sFolderName) {
		String rv = null;

		if (sFolderName != null && !Constants.EMPTY.equals(sFolderName)) {
			final String query = "SELECT folderid FROM tbfolder WHERE name = ?";
			final ArrayList<Object> queryParam = new ArrayList<>();
			queryParam.add(sFolderName);
			ArrayList<HashMap<String, String>> ral = new ArrayList<>();

			ral = DBDAO.get(GLOBAL_CONFIG.get(Constants.DB_ADMINDB), query, queryParam, true);

			if (!ral.isEmpty()) {
				rv = ral.get(0).get("folderid");
			}
		}

		return rv;
	}

	/**
	 * Add a new folder
	 *
	 * @param userId
	 * @param parentFolderId
	 * @param folderName
	 * @param folderDescription
	 * @return
	 */
	public static boolean addFolder(final String userId, final String parentFolderId, final String folderName, final String folderDescription) {
		String query = Constants.EMPTY;
		final ArrayList<Object> alParams = new ArrayList<>();
		boolean isFolderAdded = false;

		String folderId = Constants.EMPTY;
		final String now = DateTools.mysqlTimestamp();

		try {
			String folderGroup = getFolderGroup(parentFolderId);

			if (Constants.EMPTY.equals(folderGroup)) {
				LOGGER.log(Logger.CRIT, AdminFolder.class.getSimpleName(),
						"Error adding New Folder " + folderId + " , parent foldergroup was invalid. USERID: " + userId, "addFolder()");
				return isFolderAdded;
			}
			if (parentFolderId.equals(Constants.TALKPOINT_ROOT_FOLDERID) && checkClientFolder(userId, folderName)) {
				LOGGER.log(Logger.CRIT, AdminFolder.class.getSimpleName(),
						"Error adding New Folder " + folderId + " , folder already exist. USERID: " + userId, "addFolder()");
				return isFolderAdded;
			}

			final GUID id = GUID.getInstance();
			folderId = id.getID();
			folderGroup = folderGroup + "." + folderId;

			query = "INSERT INTO tbfolder(folderid,parentid,foldergroup,name,description,createdate,modifydate,flags) VALUES (?, ?, ?, ?, ?, ?,?,?)";
			alParams.add(folderId);
			alParams.add(parentFolderId);
			alParams.add(folderGroup);
			alParams.add(folderName);
			alParams.add(folderDescription);
			alParams.add(now); // createdate
			alParams.add(now); // modifydate
			alParams.add(0); // flags
			isFolderAdded = DBDAO.put(GLOBAL_CONFIG.get(Constants.DB_ADMINDB), query, alParams) == 1 ? true : false;
			if (isFolderAdded) {
				LOGGER.log(Logger.INFO, AdminFolder.class.getSimpleName(), "New Folder: " + folderId + " USERID: " + userId, "addFolder()");
			}

		} catch (final Exception e) {
			isFolderAdded = false;
			LOGGER.log(Logger.CRIT, AdminFolder.class.getSimpleName(), "Error adding New Folder " + folderId + " USERID: " + userId, "addFolder()");
			LOGGER.log(Logger.INFO, AdminFolder.class.getSimpleName(), ErrorHandler.getStackTrace(e), "addFolder()");
		}
		return isFolderAdded;
	}

	/**
	 * Move folder and it's children to new leaf.
	 *
	 * @param userId
	 * @param folderId
	 * @param newParentId
	 * @return
	 */
	public static boolean moveFolder(final String userId, final String folderId, final String oldParentId, final String newParentId) {
		String query = Constants.EMPTY;
		final ArrayList<Object> alParams = new ArrayList<>();
		final String now = DateTools.mysqlTimestamp();
		boolean isFolderMoved = false;
		try {

			query = "UPDATE  tbfolder SET parentid=?,modifydate=? WHERE folderid = ? AND parentid= ?";
			alParams.add(newParentId);
			alParams.add(now);
			alParams.add(folderId);
			alParams.add(oldParentId);

			isFolderMoved = DBDAO.put(GLOBAL_CONFIG.get(Constants.DB_ADMINDB), query, alParams) == 1 ? true : false;

			if (isFolderMoved) {
				alParams.clear();
				final String sNewParentGroup = getFolderGroup(newParentId);
				if (StringTools.isNullOrEmpty(sNewParentGroup)) {
					throw new Exception("No foldergroup found for folder: " + sNewParentGroup);
				}

				final String sFolderGroup = getFolderGroup(folderId);
				if (StringTools.isNullOrEmpty(sFolderGroup)) {
					throw new Exception("No foldergroup found for folder: " + sFolderGroup);
				}

				final String sFolderNewGroup = sNewParentGroup + "." + folderId;

				query = "UPDATE  tbfolder SET foldergroup = replace(foldergroup,?,?),modifydate=? WHERE foldergroup LIKE ?";
				alParams.add(sFolderGroup);
				alParams.add(sFolderNewGroup);
				alParams.add(now);
				alParams.add(sFolderGroup + "%");

				isFolderMoved = DBDAO.put(GLOBAL_CONFIG.get(Constants.DB_ADMINDB), query, alParams) > 0 ? true : false;
				/*
				 * if (isFolderMoved) { // update serial number on all admins attached to this folder or a subfolder so the cached AdminUser objects
				 * get reloaded and have // the correct foldergroup query =
				 * "UPDATE tbadminuser SET serial = serial + 1 WHERE fk_folderid IN (SELECT folderid FROM tbfolder WHERE foldergroup LIKE '" +
				 * sFolderGroup + "%')"; DBDAO.put(GLOBAL_CONFIG.get(Constants.DB_ADMINDB), query, new ArrayList<>()); }
				 */
			}

		} catch (final Exception e) {
			isFolderMoved = false;

			LOGGER.log(Logger.CRIT, AdminFolder.class.getSimpleName(),
					"Error moving Folder " + folderId + " toe: " + newParentId + " USERID: " + userId, "moveFolder()");
			LOGGER.log(Logger.INFO, AdminFolder.class.getSimpleName(), ErrorHandler.getStackTrace(e), "moveFolder()");
		}
		return isFolderMoved;
	}

	/**
	 * Update name and description of folder.
	 *
	 * @param userId
	 * @param folderId
	 * @param folderName
	 * @param folderDescription
	 * @return
	 */
	public static boolean renameFolder(final String userId, final String folderId, final String folderName, final String folderDescription) {
		String query = Constants.EMPTY;
		final ArrayList<Object> alParams = new ArrayList<>();
		final String now = DateTools.mysqlTimestamp();
		boolean isFolderRenamed = false;
		try {

			query = "UPDATE  tbfolder SET name=?,description=?,modifydate=? WHERE folderid = ?";
			alParams.add(folderName);
			alParams.add(folderDescription);
			alParams.add(now);
			alParams.add(folderId);

			isFolderRenamed = DBDAO.put(GLOBAL_CONFIG.get(Constants.DB_ADMINDB), query, alParams) == 1 ? true : false;

		} catch (final Exception e) {
			isFolderRenamed = false;

			LOGGER.log(Logger.CRIT, AdminFolder.class.getSimpleName(), "Error renaming Folder " + folderId + " new name: " + folderName
					+ " new description: " + folderDescription + " USERID: " + userId, "renameFolder()");
			LOGGER.log(Logger.INFO, AdminFolder.class.getSimpleName(), ErrorHandler.getStackTrace(e), "renameFolder()");
		}
		return isFolderRenamed;
	}

	/**
	 *
	 * @param userId
	 * @param folderId
	 * @return
	 */
	private static int getSubFolderCount(final String userId, final String folderId) {
		String query = Constants.EMPTY;
		final ArrayList<Object> alParams = new ArrayList<>();
		int iCnt = 0;

		try {
			query = "SELECT count(*) as cnt FROM tbfolder WHERE parentid = ? and flags!=-1";
			alParams.add(folderId);
			iCnt = Integer.parseInt(DBDAO.get(GLOBAL_CONFIG.get(Constants.DB_ADMINDB), query, alParams, false).get(0).get("cnt"));

		} catch (final Exception e) {

			LOGGER.log(Logger.CRIT, AdminFolder.class.getSimpleName(), "Error getting subfolder count " + folderId + " USERID: " + userId,
					"getSubFolderCount()");
			LOGGER.log(Logger.INFO, AdminFolder.class.getSimpleName(), ErrorHandler.getStackTrace(e), "getSubFolderCount()");
		}
		return iCnt;
	}

	public static List<FolderDetailsBean> getSubFolders(final String folderId, final boolean bOrdered) {
		final List<FolderDetailsBean> arrFolderBean = new ArrayList<>();

		try {
			String sFolderQuery = "select folderid, parentid, foldergroup, name, "
					+ " description, createdate, modifydate, flags from tbfolder where parentid = ? " + " and flags!=-1 ";

			if (bOrdered) {
				sFolderQuery += " ORDER BY name";
			}

			final ArrayList<Object> alParams = new ArrayList<>();
			alParams.add(folderId);

			final ArrayList<HashMap<String, String>> alResult = DBDAO.get(GLOBAL_CONFIG.get(Constants.DB_ADMINDB), sFolderQuery, alParams, true);

			for (final HashMap<String, String> hmFolderDets : alResult) {
				final FolderDetailsBean folderDetBean = new FolderDetailsBean(hmFolderDets);
				if (folderDetBean.getFolderid() != null && !Constants.EMPTY.equalsIgnoreCase(folderDetBean.getFolderid())) {
					arrFolderBean.add(folderDetBean);
				}
			}

		} catch (final Exception e) {

			LOGGER.log(Logger.CRIT, AdminFolder.class.getSimpleName(), "Error getting subfolders of " + folderId, "getSubFolders()");
			LOGGER.log(Logger.INFO, AdminFolder.class.getSimpleName(), ErrorHandler.getStackTrace(e), "getSubFolders()");
		}

		return arrFolderBean;
	}

	/**
	 *
	 * @param userId
	 * @param folderId
	 * @return
	 */
	private static int getUserCount(final String userId, final String folderId) {
		String query = Constants.EMPTY;
		final ArrayList<Object> alParams = new ArrayList<>();
		int iCnt = 0;

		try {
			query = "SELECT count(*) as cnt FROM tbadminuser WHERE fk_folderid = ? and flags=0";
			alParams.add(folderId);
			iCnt = Integer.parseInt(DBDAO.get(GLOBAL_CONFIG.get(Constants.DB_ADMINDB), query, alParams, false).get(0).get("cnt"));

		} catch (final Exception e) {

			LOGGER.log(Logger.CRIT, AdminFolder.class.getSimpleName(), "Error getting count " + folderId + " USERID: " + userId, "getUserCount()");
			LOGGER.log(Logger.INFO, AdminFolder.class.getSimpleName(), ErrorHandler.getStackTrace(e), "getUserCount()");
		}
		return iCnt;
	}

	/**
	 *
	 * @param userId
	 * @param folderId
	 * @return
	 */
	private static int getEventCount(final String userId, final String folderId) {
		String query = Constants.EMPTY;
		final ArrayList<Object> alParams = new ArrayList<>();
		int iCnt = 0;

		try {
			query = "SELECT count(*) as cnt FROM tbevent WHERE fk_folderid = ?";
			alParams.add(folderId);
			iCnt = Integer.parseInt(DBDAO.get(GLOBAL_CONFIG.get(Constants.DB_ADMINDB), query, alParams, false).get(0).get("cnt"));

		} catch (final Exception e) {

			LOGGER.log(Logger.CRIT, AdminFolder.class.getSimpleName(), "Error getting presentation count " + folderId + " USERID: " + userId,
					"getEventCount()");
			LOGGER.log(Logger.INFO, AdminFolder.class.getSimpleName(), ErrorHandler.getStackTrace(e), "getEventCount()");
		}
		return iCnt;
	}

	public static boolean isFolderDeletable(final String userId, final String folderId) {
		if (getEventCount(userId, folderId) > 0 || getSubFolderCount(userId, folderId) > 0 || getUserCount(userId, folderId) > 0) {
			return false;
		} else {
			return true;
		}
	}

	/**
	 * delete folder, make sure there are no active subfolders or users tied to this folder
	 *
	 * @param userId
	 * @param folderId
	 * @return
	 */
	public static boolean deleteFolder(final String userId, final String folderId) {
		// additional code required to verify that there are no subfoders or
		// presentatuin in current folder.
		String query = Constants.EMPTY;
		final ArrayList<Object> alParams = new ArrayList<>();
		final String now = DateTools.mysqlTimestamp();
		boolean isFolderDeleted = false;
		try {

			if (!isFolderDeletable(userId, folderId)) {
				return isFolderDeleted;
			}

			query = "UPDATE  tbfolder SET flags=?,modifydate=? WHERE folderid = ?";
			alParams.add(-1);
			alParams.add(now);
			alParams.add(folderId);

			isFolderDeleted = DBDAO.put(GLOBAL_CONFIG.get(Constants.DB_ADMINDB), query, alParams) == 1 ? true : false;

		} catch (final Exception e) {
			isFolderDeleted = false;

			LOGGER.log(Logger.CRIT, AdminFolder.class.getSimpleName(), "Error deleting Folder " + folderId + " USERID: " + userId, "deleteFolder()");
			LOGGER.log(Logger.INFO, AdminFolder.class.getSimpleName(), ErrorHandler.getStackTrace(e), "deleteFolder()");
		}
		return isFolderDeleted;
	}

	/**
	 * Get folder data for child folders.
	 *
	 * @param userId
	 * @param folderId
	 * @return
	 */
	private static ArrayList<HashMap<String, String>> getFoldertData(final String userId, final String folderId, final boolean isFolderEvent) {
		String query = Constants.EMPTY;
		final ArrayList<Object> alParams = new ArrayList<>();
		ArrayList<HashMap<String, String>> alResult = new ArrayList<>();

		try {

			query = "SELECT a.name,a.description,a.folderid, a.settingid, b.folderid IS NOT NULL hasChildren FROM tbfolder a LEFT JOIN tbfolder b ON a.folderid = b.parentid  AND b.flags!=-1 WHERE a.parentid = ? AND a.flags!=-1";

			// the following block is if event library blows up beta / prod. assumed folders have children
			/*
			 * if (Constants.TALKPOINT_ROOT_FOLDERID.equals(folderId)) { // For reporting and event library tree requesting top lelvel // folders. we
			 * will return all client // folders and assume they all have at least one subfolder. This // will avoid super big join of all folders in
			 * system. query =
			 * "SELECT a.name,a.description,a.folderid,a.flags childfolderflags, 1 hasChildren FROM tbfolder a WHERE a.parentid = ? AND a.flags!=-1";
			 *
			 * } else { // IFNULL(b.flags,-1) childfolderflags : This is a left join so // if there is no children for a folder it will be null, let's
			 * // treat that as deleted folder to not count as subfolder.
			 *
			 * query =
			 * "SELECT a.name,a.description,a.folderid, b.folderid IS NOT NULL hasChildren FROM tbfolder a LEFT JOIN tbfolder b ON a.folderid = b.parentid and b.flags !=-1  WHERE a.parentid = ? AND a.flags!=-1"
			 * ;
			 *
			 * }
			 */

			final AdminUser au = AdminUser.getInstance(userId);

			if (!au.can(Perms.User.SUPERUSER)) {
				query += " AND a.name!=?";
			}

			query += " ORDER BY a.name";
			alParams.add(folderId);

			if (!au.can(Perms.User.SUPERUSER)) {
				alParams.add(Constants.WEBINAR_FOLDER_NAME);
			}

			alResult = DBDAO.get(GLOBAL_CONFIG.get(Constants.DB_ADMINDB), query, alParams, false);

		} catch (final Exception e) {

			LOGGER.log(Logger.CRIT, AdminFolder.class.getSimpleName(), "Error getting folderdata  USERID: " + userId, "getFoldertData()");
			LOGGER.log(Logger.INFO, AdminFolder.class.getSimpleName(), ErrorHandler.getStackTrace(e), "getFoldertData()");
		}
		return alResult;
	}

	/**
	 * build folder list based on folder id, make sure user has access to that folder.
	 *
	 * @param userId
	 * @param parentFolderId
	 * @param folderIdtoAddChildData
	 *            If we are displaying full tree structure we need to add chldern data in the chain.
	 * @param childFolderData
	 *            Data for parram above.
	 * @return
	 */
	public static ArrayList<JSONObject> getImmediateChildren(final String userId, final String parentFolderId, final String folderIdtoAddChildData,
			final ArrayList<JSONObject> childFolderData, final String sIconPath, final boolean isFolderEvent, final boolean isLinkableSegments) {
		String sLastFolderId = Constants.EMPTY;
		String sFolderId = Constants.EMPTY;
		String sName = Constants.EMPTY;
		String sDescription = Constants.EMPTY;
		boolean isChildFolderPresent = false;
		FolderBean tempFolderBean = new FolderBean();
		final ArrayList<JSONObject> alFolderProperty = new ArrayList<>();
		ArrayList<HashMap<String, String>> alFolderData = new ArrayList<>();
		alFolderData = getFoldertData(userId, parentFolderId, isFolderEvent);

		for (final HashMap<String, String> hmRow : alFolderData) {
			isChildFolderPresent = true;
			sFolderId = hmRow.get("folderid");
			sName = hmRow.get("name");
			sDescription = hmRow.get("description");

			if (Constants.EMPTY.equals(sLastFolderId)) {
				sLastFolderId = sFolderId;
			}
			if (isFolderEvent) { // This is used in reporting. We set the name
				// as the description.
				// It is easier to retrieve the name from
				// <li> using getAttribute.
				sDescription = sName;
			}
			if (!sLastFolderId.equals(sFolderId)) {
				alFolderProperty.add(tempFolderBean.json1());
				tempFolderBean = new FolderBean();
			}

			tempFolderBean.setFolderId(sFolderId);
			if (sIconPath != null && !Constants.EMPTY.equalsIgnoreCase(sIconPath)) {
				sName = sIconPath + sName;
			}
			tempFolderBean.setName(sName);
			tempFolderBean.setDescription(sDescription);
			tempFolderBean.setChildNum(StringTools.n2i(hmRow.get("hasChildren"), 0));

			// includes events under the folder
			// if folder already has subfolders, dont need to check if there's children
			if (isFolderEvent && tempFolderBean.getChildNum() == 0) {
				if (isLinkableSegments) {
					tempFolderBean.setChildNum(getLinkableSegmentCount(userId, sFolderId));
				} else {
					tempFolderBean.setChildNum(getEventCount(userId, sFolderId));
				}
			}

			if (parentFolderId.equals(Constants.TALKPOINT_ROOT_FOLDERID)) {
				tempFolderBean.setNodeType("root");
			}

			if (!isFolderEvent && !StringTools.isNullOrEmpty(hmRow.get("settingid"))) {
				if (tempFolderBean.getNodeType().equals("root")) {
					tempFolderBean.setNodeType("root_template");
				} else {
					tempFolderBean.setNodeType("template");
				}
			}
			sLastFolderId = sFolderId;
		}
		if (isChildFolderPresent) {
			alFolderProperty.add(tempFolderBean.json1());
		}
		return alFolderProperty;
	}

	public static ArrayList<JSONObject> getImmediateChildren(final String userId, final String parentFolderId, final String folderIdtoAddChildData,
			final ArrayList<JSONObject> childFolderData) {

		return getImmediateChildren(userId, parentFolderId, folderIdtoAddChildData, childFolderData, Constants.EMPTY, false, false);
	}

	public static ArrayList<JSONObject> getEventsAndFolder(final String userId, final String parentFolderId, final String folderIdtoAddChildData,
			final ArrayList<JSONObject> childFolderData, final boolean bIsForLinkSegments) {
		ArrayList<JSONObject> alFolderProperty = new ArrayList<>();
		alFolderProperty = getImmediateChildren(userId, parentFolderId, folderIdtoAddChildData, childFolderData, Constants.EMPTY, true,
				bIsForLinkSegments);
		final ArrayList<JSONObject> alFolderEventProperty = getFolderEventList(userId, parentFolderId, bIsForLinkSegments);
		if (alFolderEventProperty != null && !alFolderEventProperty.isEmpty()) {
			for (final JSONObject jsonEventObject : alFolderEventProperty) {
				alFolderProperty.add(jsonEventObject);
			}
		}
		return alFolderProperty;
	}

	public static ArrayList<JSONObject> getFolderEventList(final String userId, final String folderId, final boolean bIsForLinkSegments) {
		final ArrayList<JSONObject> alFolderEventProperty = new ArrayList<>();
		String query = Constants.EMPTY;
		final ArrayList<Object> alParams = new ArrayList<>();
		ArrayList<HashMap<String, String>> alResult = new ArrayList<>();

		try {
			query = "SELECT e.eventid,e.title,e.contenttype,sc.eventstartdate,sc.eventenddate,"
					+ " sc.fk_tzid,sc.type FROM tbevent e join tbscheduler sc on e.eventid = sc.fk_eventid "
					+ " left join tbeventstatus esMode on sc.fk_eventid=esMode.fk_eventid and esMode.name = ? "
					+ " WHERE e.fk_folderid= ? and sc.type!='test' and sc.status=1";
			if (bIsForLinkSegments) {
				query += "  AND e.status = 0 AND NOT EXISTS(select 1 FROM tbportal WHERE segmentid=e.eventid) "
						+ " AND e.fk_typeid<2 AND (esMode.value <> 'ondemand' OR sc.eventenddate > now())";
			}
			query += " ORDER BY e.eventid";

			alParams.add(EventStatus.mode.toString());
			alParams.add(folderId);
			LOGGER.log(Logger.INFO, AdminFolder.class.getSimpleName(), query);
			alResult = DBDAO.get(GLOBAL_CONFIG.get(Constants.DB_ADMINDB), query, alParams, false);
			for (final HashMap<String, String> hmRow : alResult) {
				final FolderEventBean foldEventBean = new FolderEventBean();
				foldEventBean.setEventid(hmRow.get("eventid"));
				foldEventBean.setName(hmRow.get("eventid") + " - " + hmRow.get("title"));
				foldEventBean.setDescription(hmRow.get("title"));
				foldEventBean.setNodeType("event");
				/*
				 * foldEventBean.setHasChildren(false); foldEventBean.setChildrendata(new ArrayList<JSONObject>(0));
				 */
				alFolderEventProperty.add(foldEventBean.json1());
			}

		} catch (final Exception e) {

			LOGGER.log(Logger.CRIT, AdminFolder.class.getSimpleName(),
					"Error getting presentation data for folder :" + folderId + " USERID: " + userId, "getEventList()");
			LOGGER.log(Logger.INFO, AdminFolder.class.getSimpleName(), ErrorHandler.getStackTrace(e), "getEventList()");
		}
		return alFolderEventProperty;
	}

	public static ArrayList<JSONObject> getActiveEventsAndFolder(final String userId, final String parentFolderId,
			final String folderIdtoAddChildData, final ArrayList<JSONObject> childFolderData, final boolean bIsForLinkSegments) {
		ArrayList<JSONObject> alFolderProperty = new ArrayList<>();
		alFolderProperty = getImmediateChildren(userId, parentFolderId, folderIdtoAddChildData, childFolderData, Constants.EMPTY, true,
				bIsForLinkSegments);
		final ArrayList<JSONObject> alFolderEventProperty = getFolderActiveEventList(userId, parentFolderId, bIsForLinkSegments);
		if (alFolderEventProperty != null && !alFolderEventProperty.isEmpty()) {
			for (final JSONObject jsonEventObject : alFolderEventProperty) {
				alFolderProperty.add(jsonEventObject);
			}
		}
		return alFolderProperty;
	}

	/**
	 * Get active (non-expired, non-deleted) events from a folder. Filters deleted and expired events directly in SQL query.
	 *
	 * @param userId
	 * @param folderId
	 * @param bIsForLinkSegments
	 * @return ArrayList of JSONObject representing active events only
	 */
	public static ArrayList<JSONObject> getFolderActiveEventList(final String userId, final String folderId, final boolean bIsForLinkSegments) {
		final ArrayList<JSONObject> alFolderEventProperty = new ArrayList<>();
		String query = Constants.EMPTY;
		final ArrayList<Object> alParams = new ArrayList<>();
		ArrayList<HashMap<String, String>> alResult = new ArrayList<>();

		try {
			// Get all active events from the folder (excluding deleted and expired events)
			query = "SELECT e.eventid,e.title,e.contenttype,sc.eventstartdate,sc.eventenddate,"
					+ " sc.fk_tzid,sc.type FROM tbevent e join tbscheduler sc on e.eventid = sc.fk_eventid "
					+ " left join tbeventstatus esMode on sc.fk_eventid=esMode.fk_eventid and esMode.name = ? "
					+ " WHERE e.fk_folderid= ? and sc.type!='test' and sc.status=1" + " AND e.status = 0" // Exclude deleted events (status = 1 means
																											// deleted)
					+ " AND (esMode.value <> 'ondemand' OR sc.eventenddate > now())"; // Exclude expired on-demand events

			if (bIsForLinkSegments) {
				query += " AND NOT EXISTS(select 1 FROM tbportal WHERE segmentid=e.eventid) " + " AND e.fk_typeid<2";
			}
			query += " ORDER BY e.eventid";

			alParams.add(EventStatus.mode.toString());
			alParams.add(folderId);
			LOGGER.log(Logger.INFO, AdminFolder.class.getSimpleName(), query);
			alResult = DBDAO.get(GLOBAL_CONFIG.get(Constants.DB_ADMINDB), query, alParams, false);

			// Process results - all events returned are active
			for (final HashMap<String, String> hmRow : alResult) {
				final FolderEventBean foldEventBean = new FolderEventBean();
				foldEventBean.setEventid(hmRow.get("eventid"));
				foldEventBean.setName(hmRow.get("eventid") + " - " + hmRow.get("title"));
				foldEventBean.setDescription(hmRow.get("title"));
				foldEventBean.setNodeType("event");
				alFolderEventProperty.add(foldEventBean.json1());
			}

		} catch (final Exception e) {

			LOGGER.log(Logger.CRIT, AdminFolder.class.getSimpleName(),
					"Error getting active presentation data for folder :" + folderId + " USERID: " + userId, "getFolderActiveEventList()");
			LOGGER.log(Logger.INFO, AdminFolder.class.getSimpleName(), ErrorHandler.getStackTrace(e), "getFolderActiveEventList()");
		}
		return alFolderEventProperty;
	}

	/**
	 *
	 * @param userId
	 * @param folderId
	 * @return
	 */
	private static int getLinkableSegmentCount(final String userId, final String folderId) {
		String query = Constants.EMPTY;
		final ArrayList<Object> alParams = new ArrayList<>();
		int iCnt = 0;

		try {
			// We are going to show events linkable only , which are not linked
			// to another portal , not a portal , not deleted / expired
			// don't need exact count, just if children exist
			query = "SELECT EXISTS (SELECT * FROM tbevent e join tbscheduler sc on e.eventid = sc.fk_eventid "
					+ " left join tbeventstatus esMode on sc.fk_eventid=esMode.fk_eventid and esMode.name = ? "
					+ " WHERE NOT EXISTS(select 1 FROM tbportal WHERE segmentid=e.eventid)"
					+ " AND e.fk_typeid<2 AND fk_folderid = ?  AND e.status <> 1 and sc.type!='test' and sc.status=1 "
					+ " AND (esMode.value <> 'ondemand' OR sc.eventenddate > now()) LIMIT 1) as cnt";
			alParams.add(EventStatus.mode.toString());
			alParams.add(folderId);

			iCnt = Integer.parseInt(DBDAO.get(GLOBAL_CONFIG.get(Constants.DB_ADMINDB), query, alParams, false).get(0).get("cnt"));

		} catch (final Exception e) {

			LOGGER.log(Logger.CRIT, AdminFolder.class.getSimpleName(), "Error getting presentation count " + folderId + " USERID: " + userId,
					"getLinkableSegmentCount()");
			LOGGER.log(Logger.INFO, AdminFolder.class.getSimpleName(), ErrorHandler.getStackTrace(e), "getLinkableSegmentCount()");
		}
		return iCnt;
	}

	/**
	 *
	 * @param userId
	 * @param sUserFolderId
	 * @param folderId
	 * @return
	 */
	public static ArrayList<JSONObject> getFullPathToFolder(final String userId, final String sUserFolderId, final String folderId,
			final String sIconsPath, final boolean isFolderEvent) {
		ArrayList<JSONObject> tempRet = new ArrayList<>(0);
		String tempFolderId = Constants.EMPTY;

		String sFolderGroup = getFolderGroup(folderId);
		final int iUserFolderIndex = sFolderGroup.indexOf(sUserFolderId);
		if (iUserFolderIndex == -1) {
			return tempRet;
		}
		sFolderGroup = sFolderGroup.substring(iUserFolderIndex);
		if (isFolderEvent && Constants.TALKPOINT_ROOT_FOLDERID.equalsIgnoreCase(sUserFolderId)) {
			// If used by the reporter'sfolder browser, then simply return. This will force the plugin to load the folder tree at run time In Event
			// library an initiallist is provided which is not required in Reporter Folder tree.
			return tempRet;
		}
		if (sFolderGroup.equals(sUserFolderId)) {
			return tempRet;
		}
		final String[] folderGroupFolders = sFolderGroup.split("\\.");
		// folderGroupFolders.length - 2 : we don't want to show child of the
		// leaf folder.
		for (int i = folderGroupFolders.length - 2; i >= 0; i--) {
			tempRet = getImmediateChildren(userId, folderGroupFolders[i], tempFolderId, tempRet, sIconsPath, isFolderEvent, false);
			tempFolderId = folderGroupFolders[i];
		}

		return tempRet;
	}

	public static ArrayList<FolderDetailsBean> getEventFolderAncestry(String sFolderId) {

		boolean searchHigher = true;
		final ArrayList<FolderDetailsBean> retArr = new ArrayList<>();
		while (searchHigher) {
			final FolderDetailsBean folderDetails = getFolderDetail(sFolderId);
			if (folderDetails != null) {
				if (folderDetails.getParentid().equals(Constants.EMPTY)) {
					searchHigher = false;
				} else {
					retArr.add(folderDetails);
					sFolderId = folderDetails.getParentid();
				}
			} else {
				searchHigher = false;
			}
		}

		Collections.reverse(retArr);

		return retArr;
	}

	public static String getEventFolderAncestryString(final String sFolderId) {
		String sFolderPath = Constants.EMPTY;
		final ArrayList<FolderDetailsBean> folderDetails = getEventFolderAncestry(sFolderId);
		for (final FolderDetailsBean folderDetail : folderDetails) {
			sFolderPath += folderDetail.getName() + "/";
		}
		return sFolderPath.substring(0, sFolderPath.length() - 1);
	}

	public static String getInitialFolderListToDisplay(final String userId, final String userFolderId, final String folderIdToExpandTo) {
		return getInitialFolderListToDisplay(userId, userFolderId, folderIdToExpandTo, Constants.EMPTY, false, false);
	}

	/**
	 * Get folder structure to be displayed when user logs in or as a result of page load due to search presentation or folder rename/move/delete.
	 *
	 * @param userId
	 * @param userFolderId
	 * @param folderIdToExpandTo
	 * @return
	 */
	public static String getInitialFolderListToDisplay(final String userId, final String userFolderId, final String folderIdToExpandTo,
			final String iconPath, final boolean isFolderEvent, final boolean isLinkableEventTree) {
		// ArrayList tempRet = new ArrayList(0);
		final FolderBean tempFolderBean = new FolderBean();
		tempFolderBean.setFolderId(userFolderId);
		tempFolderBean.setName("HOME FOLDER");
		tempFolderBean.setDescription("HOME FOLDER");

		if (userFolderId.equals(Constants.TALKPOINT_ROOT_FOLDERID)) {
			tempFolderBean.setNodeType("suproot");
		} else {
			tempFolderBean.setNodeType("root");
		}
		// If this is initial load just show first level of folders.
		// If it's page reload due to presentation search or folder
		// rename/move/delete
		// display expanded tree for that folder.

		if (getSubFolderCount(userId, userFolderId) == 0) {
			// tempFolderBean.setHasChildren(false);
			if (isLinkableEventTree) {
				if (isFolderEvent && getLinkableSegmentCount(userId, userFolderId) > 0) {
					// tempFolderBean.setHasChildren(true);
					tempFolderBean.setChildNum(getLinkableSegmentCount(userId, userFolderId));
				}
			} else {
				if (isFolderEvent && getEventCount(userId, userFolderId) > 0) {
					// tempFolderBean.setHasChildren(true);
					tempFolderBean.setChildNum(getEventCount(userId, userFolderId));
				}
			}

		} else {
			tempFolderBean.setChildNum(1);
			/*
			 * if (!Constants.EMPTY.equals(folderIdToExpandTo)) { // tempFolderBean.setChildrendata(getFullPathToFolder(userId, userFolderId,
			 * folderIdToExpandTo, iconPath, isFolderEvent)); }
			 */
		}
		return tempFolderBean.json1().toString();
	}

	public static ArrayList<HashMap<String, String>> getEventsByFolder(final String sResource, final String sFolderId, final boolean bDeleted,
			final boolean bUseCache) {
		ArrayList<HashMap<String, String>> aEvents = new ArrayList<>();
		try {
			final String sSelect = "SELECT * FROM (SELECT e.eventid,e.title,e.contenttype,sc.eventstartdate,sc.eventenddate,sc.fk_tzid,sc.type,tf.value as acqtype, "
					+ " tf2.value as delete_date,tf3.value as simlive_flag,esMode.value as mode, esPublished.value as last_published,e.status,e.eventguid FROM tbevent e ";

			final String sJoin = " join tbscheduler sc on e.eventid = sc.fk_eventid "
					+ " left join tbeventstatus esMode on sc.fk_eventid=esMode.fk_eventid and esMode.name = ? "
					+ " left join tbeventstatus esPublished on e.eventid = esPublished.fk_eventid and esPublished.name=? "
					+ " left join tbeventfeatures tf on (e.eventid = tf.fk_eventid and tf.fk_featureid =?) "
					+ " left join tbeventfeatures tf2 on (e.eventid = tf2.fk_eventid and tf2.fk_featureid =?) "
					+ " left join tbeventfeatures tf3 on (e.eventid = tf3.fk_eventid and tf3.fk_featureid =?) ";
			String sWhere = " WHERE e.fk_folderid=? and sc.type!='test' and sc.status=1 ";

			if (!bDeleted) {
				sWhere += " AND e.status = 0 AND ( esMode.value <> 'ondemand' OR " + " sc.eventenddate > now()  )) EventList";
			} else {
				/*
				 * Line above gets list if event is deleted before last 91 days OR its ondemand and older than 91 days Changed where part above line
				 * because we added delete date if event is deleted . So if event is deleted and deleted more than 91 days ago don't show it on the
				 * list , For existing events where there is no delete date still check expiration date .
				 */
				sWhere += "AND ((e.status = 1 AND adddate(tf2.value,91) > now()) OR (e.status = 1 AND tf2.value is null AND adddate(sc.eventenddate,91) > now()) OR (esMode.value = 'ondemand' AND sc.eventenddate < now() AND adddate(sc.eventenddate,91) > now())) ";
				sWhere += " UNION SELECT e.eventid,e.title,'','',tf2.value as delete_date,'','','', "
						+ " tf2.value as delete_date,'' as simlive_flag,'' as mode, '' as last_published,'1',e.eventguid FROM tbevent e"
						+ " left join tbeventfeatures tf2 on e.eventid = tf2.fk_eventid and tf2.fk_featureid =? "
						+ " where e.fk_typeid=2 AND e.status=1  AND e.fk_folderid=?) EventList";
			}

			final String sOrder = " ORDER BY eventid DESC";

			final ArrayList<Object> alParams = new ArrayList<>();
			alParams.add(EventStatus.mode.toString());
			alParams.add(EventStatus.last_publish_date.toString());
			alParams.add(Constants.ACQUISITION_SOURCE_FEATUREID);
			alParams.add(Constants.EVENT_DELETE_DATE);
			alParams.add(Constants.SIMLIVEFLAG_FEATUREID);
			alParams.add(sFolderId);

			if (bDeleted) {
				alParams.add(Constants.EVENT_DELETE_DATE);
				alParams.add(sFolderId);
			}

			final String sQuery = sSelect + sJoin + sWhere + sOrder;
			aEvents = DBDAO.get(sResource, sQuery, alParams, bUseCache);
		} catch (final Exception ex) {
			LOGGER.log(Logger.INFO, AdminFolder.class.getSimpleName(), "ERROR:" + ErrorHandler.getStackTrace(ex));
		}
		return aEvents;
	}

	public static String getEventDescription(final Event e, final String sTimeZoneName) {
		final int iEventId = e.eventid;
		final SimpleDateFormat sdf = new SimpleDateFormat(Constants.MYSQLTIMESTAMP_PATTERN);
		sdf.setTimeZone(TimeZone.getTimeZone(sTimeZoneName));

		final String sEventStDate = DateTools.getLocalDateFromGMT(e.getProperty(EventProps.start_date), Constants.MYSQLTIMESTAMP_PATTERN,
				sTimeZoneName);

		boolean isPublished = false;
		final String sTimeZoneDispNameSt = DateTools.getTimeZoneShortName(sTimeZoneName, sEventStDate, Constants.MYSQLTIMESTAMP_PATTERN);

		String eventPublishedDate = Constants.EMPTY;

		final String datePublishedDB = e.getStatus(EventStatus.last_publish_date).getValue();
		final String sModeValue = e.getStatus(EventStatus.mode).getValue();

		// is it simlive?
		final boolean bSimlive = e.getProperty(EventProps.isSimLive).equals("true");
		final String sLiveOn = bSimlive ? "Captured on" : "Live on";

		if ("prelive".equalsIgnoreCase(sModeValue)) {
			final String sText = bSimlive ? "Capture scheduled for: " : " Scheduled for: ";
			return sText + DateTools.applyDatePattern(sEventStDate, Constants.MYSQLTIMESTAMP_PATTERN, Constants.PRETTYDATE_PATTERN_3) + " "
					+ sTimeZoneDispNameSt;
		}

		if (bSimlive && "ondemand".equalsIgnoreCase(sModeValue)) {
			// check simlive schedule
			final ArrayList<HashMap<String, String>> alSimlive = ScheduleManager.getSimLiveSchedule(Constants.DB_ADMINDB, iEventId, Constants.EMPTY);
			if (!alSimlive.isEmpty()) {
				final HashMap<String, String> hmSimlive = alSimlive.get(0);
				// is the simlive date in the future?
				final String sScheduledDate = hmSimlive.get("eventstartdate");
				final String sEndDate = hmSimlive.get("eventenddate");
				final String tzid = hmSimlive.get("fk_tzid");
				if (DateTools.getLongDateFromString(sScheduledDate) > System.currentTimeMillis()) {
					return "SimLive. Scheduled for: " + DateTools.getPrettyTimezoneDate(sScheduledDate, tzid, Constants.PRETTYDATE_PATTERN_3);
				} else if (DateTools.getLongDateFromString(sScheduledDate) < System.currentTimeMillis()
						&& System.currentTimeMillis() < DateTools.getLongDateFromString(sEndDate)) {
					return "SimLive. Broadcasting since: " + DateTools.getPrettyTimezoneDate(sScheduledDate, tzid, Constants.PRETTYDATE_PATTERN_3);
				} else if (DateTools.getLongDateFromString(sScheduledDate) > 0) {
					return "SimLive. Ran on: " + DateTools.getPrettyTimezoneDate(sScheduledDate, tzid, Constants.PRETTYDATE_PATTERN_3);
				}
			} else {
				return "SimLive. Unscheduled.";
			}
		}

		if ("live".equalsIgnoreCase(sModeValue)) {
			return "Live Now. Started at: "
					+ DateTools.applyDatePattern(sEventStDate, Constants.MYSQLTIMESTAMP_PATTERN, Constants.PRETTYDATE_PATTERN_3) + " "
					+ sTimeZoneDispNameSt;
		}
		if (datePublishedDB == null || Constants.EMPTY.equals(datePublishedDB)) {
			isPublished = false;
		} else {

			final TimeZone tz = null;
			final String sDatePublished = DateTools.getStringFromLong(StringTools.n2L(datePublishedDB), Constants.MYSQLTIMESTAMP_PATTERN, tz);
			eventPublishedDate = DateTools.getLocalDateFromGMT(sDatePublished, Constants.MYSQLTIMESTAMP_PATTERN, sTimeZoneName);
			isPublished = true;
		}

		if (e.getProperty(EventProps.contenttype).equalsIgnoreCase("OD") && "ondemand".equalsIgnoreCase(sModeValue)) {
			if (isPublished) {
				final String sTimeZoneDispNamePB = DateTools.getTimeZoneShortName(sTimeZoneName, eventPublishedDate,
						Constants.MYSQLTIMESTAMP_PATTERN);
				return "On-Demand. Published on: "
						+ DateTools.applyDatePattern(eventPublishedDate, Constants.MYSQLTIMESTAMP_PATTERN, Constants.PRETTYDATE_PATTERN_3) + " "
						+ sTimeZoneDispNamePB;
			}

			return "On-Demand. Never Published.";
		}

		if ("archive_failed".equalsIgnoreCase(sModeValue)) {
			return "Archive Failed. " + sLiveOn + ": "
					+ DateTools.applyDatePattern(sEventStDate, Constants.MYSQLTIMESTAMP_PATTERN, Constants.PRETTYDATE_PATTERN_3) + " "
					+ sTimeZoneDispNameSt;
		}

		final String sEventLivelogDate = getLiveStartDateForEventList(String.valueOf(iEventId), sTimeZoneName);
		String sTimeZoneDispNameLg = Constants.EMPTY;
		boolean bRanLive = false;
		if (!Constants.EMPTY.equals(sEventLivelogDate)) {
			sTimeZoneDispNameLg = DateTools.getTimeZoneShortName(sTimeZoneName, sEventLivelogDate, Constants.MYSQLTIMESTAMP_PATTERN);
			bRanLive = true;
		}

		if (e.getProperty(EventProps.contenttype).equalsIgnoreCase("LIVE") && "ondemand".equalsIgnoreCase(sModeValue)) {
			if (bRanLive && isPublished) {
				return "Archived. " + sLiveOn + ": "
						+ DateTools.applyDatePattern(sEventLivelogDate, Constants.MYSQLTIMESTAMP_PATTERN, Constants.PRETTYDATE_PATTERN_3) + " "
						+ sTimeZoneDispNameLg;
			}
			return "Archived. " + sLiveOn + ": "
					+ DateTools.applyDatePattern(sEventStDate, Constants.MYSQLTIMESTAMP_PATTERN, Constants.PRETTYDATE_PATTERN_3) + " "
					+ sTimeZoneDispNameSt;

		}
		// Archive Pending
		if ("postlive".equalsIgnoreCase(sModeValue)) {
			if (bRanLive) {
				return "Archive Pending. Live on: "
						+ DateTools.applyDatePattern(sEventLivelogDate, Constants.MYSQLTIMESTAMP_PATTERN, Constants.PRETTYDATE_PATTERN_3) + " "
						+ sTimeZoneDispNameLg;
			}
			return "Archive Pending. Live on: "
					+ DateTools.applyDatePattern(sEventStDate, Constants.MYSQLTIMESTAMP_PATTERN, Constants.PRETTYDATE_PATTERN_3) + " "
					+ sTimeZoneDispNameSt;

		}

		return sModeValue + ". " + sLiveOn + ": "
				+ DateTools.applyDatePattern(sEventStDate, Constants.MYSQLTIMESTAMP_PATTERN, Constants.PRETTYDATE_PATTERN_3) + " "
				+ sTimeZoneDispNameSt;
	}

	public static String getEventListDescription(final HashMap<String, String> hmRow, final String sTimeZoneName) {
		return getEventListDescription(hmRow, sTimeZoneName, sTimeZoneName);
	}

	public static String getEventListDescription(final HashMap<String, String> hmRow, final String sTimeZoneName, final String sAdminTimeZoneName) {
		final int iEventId = Integer.parseInt(hmRow.get("eventid"));
		final SimpleDateFormat sdf = new SimpleDateFormat(Constants.MYSQLTIMESTAMP_PATTERN);
		sdf.setTimeZone(TimeZone.getTimeZone(sTimeZoneName));

		final String sEventStDate = DateTools.getLocalDateFromGMT(hmRow.get("eventstartdate"), Constants.MYSQLTIMESTAMP_PATTERN, sTimeZoneName);

		boolean isPublished = false;
		final String sTimeZoneDispNameSt = DateTools.getTimeZoneShortName(sTimeZoneName, sEventStDate, Constants.MYSQLTIMESTAMP_PATTERN);

		final String datePublishedDB = hmRow.get("last_published");
		final String sModeValue = hmRow.get("mode");

		// is it simlive?
		final boolean bSimlive = StringTools.n2s(hmRow.get("simlive_flag")).equals("true");
		final String sLiveOn = bSimlive ? "Captured on" : "Live on";

		if ("prelive".equalsIgnoreCase(sModeValue)) {
			final String sText = bSimlive ? "Capture scheduled for: <br/>" : " Scheduled for: <br/>";
			return sText + DateTools.applyDatePattern(sEventStDate, Constants.MYSQLTIMESTAMP_PATTERN, Constants.PRETTYDATE_PATTERN_3) + " "
					+ sTimeZoneDispNameSt;
		}

		if (bSimlive && "ondemand".equalsIgnoreCase(sModeValue)) {
			// check simlive schedule
			final ArrayList<HashMap<String, String>> alSimlive = ScheduleManager.getSimLiveSchedule(Constants.DB_ADMINDB, iEventId, Constants.EMPTY);
			if (!alSimlive.isEmpty()) {
				final HashMap<String, String> hmSimlive = alSimlive.get(0);
				// is the simlive date in the future?
				final String sScheduledDate = hmSimlive.get("eventstartdate");
				final String sEndDate = hmSimlive.get("eventenddate");
				final String tzid = hmSimlive.get("fk_tzid");
				if (DateTools.getLongDateFromString(sScheduledDate) > System.currentTimeMillis()) {
					return "SimLive. Scheduled for: <br/>" + DateTools.getPrettyTimezoneDate(sScheduledDate, tzid, Constants.PRETTYDATE_PATTERN_3);
				} else if (DateTools.getLongDateFromString(sScheduledDate) < System.currentTimeMillis()
						&& System.currentTimeMillis() < DateTools.getLongDateFromString(sEndDate)) {
					return "SimLive. Broadcasting since: <br/>"
							+ DateTools.getPrettyTimezoneDate(sScheduledDate, tzid, Constants.PRETTYDATE_PATTERN_3);
				} else if (DateTools.getLongDateFromString(sScheduledDate) > 0) {
					return "SimLive. Ran on: <br/>" + DateTools.getPrettyTimezoneDate(sScheduledDate, tzid, Constants.PRETTYDATE_PATTERN_3);
				}
			} else {
				return "SimLive. <br/>Unscheduled.";
			}
		}

		if ("live".equalsIgnoreCase(sModeValue)) {
			return "Live Now. Started at: </br>"
					+ DateTools.applyDatePattern(sEventStDate, Constants.MYSQLTIMESTAMP_PATTERN, Constants.PRETTYDATE_PATTERN_3) + " "
					+ sTimeZoneDispNameSt;
		}
		if (datePublishedDB == null || Constants.EMPTY.equals(datePublishedDB)) {
			isPublished = false;
		} else {
			/*
			 * final TimeZone tz = null; final String sDatePublished = DateTools.getStringFromLong(StringTools.n2L(datePublishedDB),
			 * Constants.MYSQLTIMESTAMP_PATTERN, tz); eventPublishedDate = DateTools.getLocalDateFromGMT(sDatePublished,
			 * Constants.MYSQLTIMESTAMP_PATTERN, sTimeZoneName);
			 */
			isPublished = true;
		}

		if (hmRow.get("contenttype").equalsIgnoreCase("OD") && "ondemand".equalsIgnoreCase(sModeValue)) {
			if (isPublished) {
				final String sAdminTimeZoneShortName = DateTools.getTimeZoneShortName(sAdminTimeZoneName, sEventStDate,
						Constants.MYSQLTIMESTAMP_PATTERN);
				String publishedText = "On-Demand. Published on:<br/> ";
				final String sDatePublished = DateTools.getStringFromLong(StringTools.n2L(datePublishedDB), Constants.MYSQLTIMESTAMP_PATTERN);
				String ODEventPublishedDate = DateTools.getLocalDateFromGMT(sDatePublished, Constants.MYSQLTIMESTAMP_PATTERN, sAdminTimeZoneName);
				ODEventPublishedDate = DateTools.applyDatePattern(ODEventPublishedDate, Constants.MYSQLTIMESTAMP_PATTERN,
						Constants.PRETTYDATE_PATTERN_3) + " " + sAdminTimeZoneShortName;
				publishedText += ODEventPublishedDate;
				return publishedText;
			}

			return "On-Demand. <br/>Never Published.";
		}

		if ("archive_failed".equalsIgnoreCase(sModeValue)) {
			return "Archive Failed. " + sLiveOn + ": <br/>"
					+ DateTools.applyDatePattern(sEventStDate, Constants.MYSQLTIMESTAMP_PATTERN, Constants.PRETTYDATE_PATTERN_3) + " "
					+ sTimeZoneDispNameSt;
		}

		final String sEventLivelogDate = getLiveStartDateForEventList(hmRow.get("eventid"), sTimeZoneName);
		String sTimeZoneDispNameLg = Constants.EMPTY;
		boolean bRanLive = false;
		if (!Constants.EMPTY.equals(sEventLivelogDate)) {
			sTimeZoneDispNameLg = DateTools.getTimeZoneShortName(sTimeZoneName, sEventLivelogDate, Constants.MYSQLTIMESTAMP_PATTERN);
			bRanLive = true;
		}

		if (hmRow.get("contenttype").equalsIgnoreCase("LIVE") && "ondemand".equalsIgnoreCase(sModeValue)) {
			if (bRanLive && isPublished) {
				return "Archived. " + sLiveOn + ":<br/> "
						+ DateTools.applyDatePattern(sEventLivelogDate, Constants.MYSQLTIMESTAMP_PATTERN, Constants.PRETTYDATE_PATTERN_3) + " "
						+ sTimeZoneDispNameLg;
			}
			return "Archived. " + sLiveOn + ":<br/> "
					+ DateTools.applyDatePattern(sEventStDate, Constants.MYSQLTIMESTAMP_PATTERN, Constants.PRETTYDATE_PATTERN_3) + " "
					+ sTimeZoneDispNameSt;

		}
		// Archive Pending
		if ("postlive".equalsIgnoreCase(sModeValue)) {
			if (bRanLive) {
				return "Archive Pending. Live on: <br/>"
						+ DateTools.applyDatePattern(sEventLivelogDate, Constants.MYSQLTIMESTAMP_PATTERN, Constants.PRETTYDATE_PATTERN_3) + " "
						+ sTimeZoneDispNameLg;
			}
			return "Archive Pending. Live on: <br/>"
					+ DateTools.applyDatePattern(sEventStDate, Constants.MYSQLTIMESTAMP_PATTERN, Constants.PRETTYDATE_PATTERN_3) + " "
					+ sTimeZoneDispNameSt;

		}

		return sModeValue + ". " + sLiveOn + ": <br/>"
				+ DateTools.applyDatePattern(sEventStDate, Constants.MYSQLTIMESTAMP_PATTERN, Constants.PRETTYDATE_PATTERN_3) + " "
				+ sTimeZoneDispNameSt;
	}

	public static String getLiveStartDateForEventList(final String eventid, final String sTimeZoneName) {

		final String typeQuery = "SELECT event_type,TIMESTAMP FROM tblivelog where fk_eventid=? and event_type='start_webcast'";
		final ArrayList<HashMap<String, String>> arrLiveLogResult = DBDAO.get(GLOBAL_CONFIG.get(Constants.DB_ADMINDB), typeQuery,
				DBDAO.getParams(eventid), false);
		if (arrLiveLogResult != null && !arrLiveLogResult.isEmpty()) {
			return DateTools.getLocalDateFromGMT(arrLiveLogResult.get(0).get("TIMESTAMP"), Constants.MYSQLTIMESTAMP_PATTERN, sTimeZoneName);
		}
		return Constants.EMPTY;
	}

	/**
	 *
	 * @param userId
	 * @param folderId
	 * @return
	 */
	public static JSONArray getEventList(final String userId, final String folderId) {
		ArrayList<HashMap<String, String>> alResult = new ArrayList<>();
		final JSONArray alEventList = new JSONArray();
		final EventListBean tempEventListBean = new EventListBean();
		try {
			alResult = getEventsByFolder(GLOBAL_CONFIG.get(Constants.DB_ADMINDB), folderId, false, false);

			for (Integer j = 0; j < alResult.size(); j++) {
				final HashMap<String, String> hmRow = alResult.get(j);

				final String sEventID = hmRow.get("eventid");
				tempEventListBean.setEventGUID(hmRow.get("eventguid"));
				tempEventListBean.setEventId(sEventID);
				String sTitle = hmRow.get("title");
				if (sTitle.length() > 150) {
					sTitle = sTitle.substring(0, 147) + "...";
				}
				tempEventListBean.setEventName(sTitle);
				final String sTimeZoneName = DateTools.getTZNameFromDB(hmRow.get("fk_tzid"));
				tempEventListBean.setStatus(getEventListDescription(hmRow, sTimeZoneName));
				final String sEventEndDate = DateTools.getLocalDateFromGMT(hmRow.get("eventenddate"), Constants.MYSQLTIMESTAMP_PATTERN,
						sTimeZoneName);
				tempEventListBean
						.setExpiresOn(DateTools.applyDatePattern(sEventEndDate, Constants.MYSQLTIMESTAMP_PATTERN, Constants.PRETTYDATE_PATTERN_6));

				tempEventListBean.setType("5".equals(hmRow.get("acqtype")) || "audio".equals(hmRow.get("acqtype")) ? "AUDIO" : "VIDEO");
				alEventList.put(tempEventListBean.json());
			}
		} catch (final Exception e) {
			LOGGER.log(Logger.CRIT, AdminFolder.class.getSimpleName(),
					"Error getting presentation data for folder :" + folderId + " USERID: " + userId, "getEventList()");
			LOGGER.log(Logger.INFO, AdminFolder.class.getSimpleName(), ErrorHandler.getStackTrace(e), "getEventList()");
		}
		return alEventList;
	}

	public static JSONArray getDeletedEventList(final String userId, final String folderId) {
		final JSONArray alEventList = new JSONArray();

		final EventListBean tempEventListBean = new EventListBean();

		try {
			final ArrayList<HashMap<String, String>> alResult = getEventsByFolder(GLOBAL_CONFIG.get(Constants.DB_ADMINDB), folderId, true, false);

			for (Integer j = 0; j < alResult.size(); j++) {
				final HashMap<String, String> hmRow = alResult.get(j);

				final String sEventID = hmRow.get("eventid");

				tempEventListBean.setEventId(sEventID);
				tempEventListBean.setEventGUID(hmRow.get("eventguid"));
				String sTitle = hmRow.get("title");
				if (sTitle.length() > 150) {
					sTitle = sTitle.substring(0, 147) + "...";
				}
				tempEventListBean.setEventName(sTitle);
				final String sTimeZoneName = DateTools.getTZNameFromDB(hmRow.get("fk_tzid"));
				if (hmRow.get("status").equals("1")) {
					tempEventListBean.setStatus("Deleted");
				} else {
					tempEventListBean.setStatus("Expired");
				}
				final String sEventEndDate = DateTools.getLocalDateFromGMT(hmRow.get("eventenddate"), Constants.MYSQLTIMESTAMP_PATTERN,
						sTimeZoneName);
				tempEventListBean
						.setExpiresOn(DateTools.applyDatePattern(sEventEndDate, Constants.MYSQLTIMESTAMP_PATTERN, Constants.PRETTYDATE_PATTERN_6));

				tempEventListBean.setType("5".equals(hmRow.get("acqtype")) || "audio".equals(hmRow.get("acqtype")) ? "AUDIO" : "VIDEO");
				alEventList.put(tempEventListBean.json());
			}

		} catch (final Exception e) {

			LOGGER.log(Logger.CRIT, AdminFolder.class.getSimpleName(),
					"Error getting presentation data for folder :" + folderId + " USERID: " + userId, "getExpiredEventList()");
			LOGGER.log(Logger.INFO, AdminFolder.class.getSimpleName(), ErrorHandler.getStackTrace(e), "getExpiredEventList()");
		}

		return alEventList;

	}

	/**
	 *
	 * @param userId
	 * @param eventId
	 * @param searchText
	 * @return
	 */
	public static ArrayList<HashMap<String, String>> searchEvent(final String userId, final String userFolderId, final String eventId,
			final String searchText) {
		String query = Constants.EMPTY;
		final ArrayList<Object> alParams = new ArrayList<>();
		ArrayList<HashMap<String, String>> alResult = new ArrayList<>();
		try {
			final String sUserFolderGroup = getFolderGroup(userFolderId);
			if (StringTools.isNullOrEmpty(sUserFolderGroup)) {
				throw new Exception("No foldergroup found for folder: " + userFolderId);
			}

			if (!Constants.EMPTY.equals(eventId)) {
				query = "SELECT eventid,title,status FROM tbevent WHERE eventId=?";
				alParams.add(eventId);
			} else {
				query = "SELECT eventid,title,status FROM tbevent WHERE title LIKE ?";
				alParams.add("%" + searchText + "%");
			}
			query = query + "AND fk_folderid IN(SELECT folderid FROM tbfolder WHERE foldergroup LIKE ?)";
			alParams.add(sUserFolderGroup + "%");
			alResult = DBDAO.get(GLOBAL_CONFIG.get(Constants.DB_ADMINDB), query, alParams, false);

		} catch (final Exception e) {
			LOGGER.log(Logger.CRIT, AdminFolder.class.getSimpleName(),
					"Error searching for presentation eventid = " + eventId + ", searchText=" + searchText + " USERID: " + userId, "searchEvent()");
			LOGGER.log(Logger.INFO, AdminFolder.class.getSimpleName(), ErrorHandler.getStackTrace(e), "searchEvent()");
		}
		return alResult;
	}

	public static String getClientName(final String sFolderId) {
		// select the second folder in the chain, the first folder is the global
		// root
		final String squery = "select name from tbfolder where folderid = (select substring(foldergroup,42,40) from tbfolder where folderid = ?)";
		final ArrayList<Object> alParams = new ArrayList<>();
		ArrayList<HashMap<String, String>> alResult;
		alParams.add(sFolderId);
		try {
			alResult = DBDAO.get(GLOBAL_CONFIG.get(Constants.DB_ADMINDB), squery, alParams, true);
			if (alResult.size() > 0) {
				return alResult.get(0).get("name");
			}
		} catch (final Exception e) {

			LOGGER.log(Logger.CRIT, AdminFolder.class.getSimpleName(), "Error getting client name for folder : " + sFolderId, "getClientName()");
			LOGGER.log(Logger.INFO, AdminFolder.class.getSimpleName(), ErrorHandler.getStackTrace(e), "getClientName()");
		}
		return Constants.EMPTY;
	}

	public static String getsubFolderName(final String sFolderId) {
		// select the second folder in the chain, the first folder is the global
		// root
		final String squery = "select name from tbfolder where folderid = ?";
		final ArrayList<Object> alParams = new ArrayList<>();
		ArrayList<HashMap<String, String>> alResult;
		alParams.add(sFolderId);
		try {
			alResult = DBDAO.get(GLOBAL_CONFIG.get(Constants.DB_ADMINDB), squery, alParams, true);
			if (alResult.size() > 0) {
				return alResult.get(0).get("name");
			}
		} catch (final Exception e) {
			LOGGER.log(Logger.CRIT, AdminFolder.class.getSimpleName(), "Error getting client name for folder : " + sFolderId, "getClientName()");
			LOGGER.log(Logger.INFO, AdminFolder.class.getSimpleName(), ErrorHandler.getStackTrace(e), "getClientName()");
		}
		return Constants.EMPTY;
	}

	public static HashMap<String, String> getsubFolderList(final String sFolderId) {
		// select the second folder in the chain, the first folder is the global
		// root
		final String squery = "select * from tbfolder where foldergroup like ?";
		ArrayList<HashMap<String, String>> alResult;
		final HashMap<String, String> rv = new HashMap<>();
		// alParams.add(sFolderId);

		try {
			alResult = DBDAO.get(GLOBAL_CONFIG.get(Constants.DB_ADMINDB), squery, DBDAO.getParams("%" + sFolderId + "%"), true);

			if (alResult.size() > 0) {
				// return getLengthLongestString(alResult);

				for (final HashMap<String, String> row : alResult) {
					final int iUserFolderIndex = row.get("foldergroup").indexOf(sFolderId);

					if (iUserFolderIndex != -1) {
						final String sFolderGroup = row.get("foldergroup").substring(iUserFolderIndex);
						final StringTokenizer st = new StringTokenizer(sFolderGroup, ".");
						while (st.hasMoreTokens()) {
							final String val = st.nextToken();
							rv.put(val, val);
						}

					}

				}

			}
		} catch (final Exception e) {
			LOGGER.log(Logger.CRIT, AdminFolder.class.getSimpleName(), "Error getting client name for folder : " + sFolderId, "getClientName()");
			LOGGER.log(Logger.INFO, AdminFolder.class.getSimpleName(), ErrorHandler.getStackTrace(e), "getClientName()");
		}
		return rv;

	}

	/*
	 * Take in any folderid in the chain and get the second level (client level) folderid that it lives in.
	 */
	public static String getClientLevelFolderID(final String sFolderId) {
		// select the second folder in the chain, the first folder is the global
		// root
		final String squery = "select folderid from tbfolder where folderid = (select substring(foldergroup,42,40) from tbfolder where folderid = ?)";
		final ArrayList<Object> alParams = new ArrayList<>();
		ArrayList<HashMap<String, String>> alResult;
		alParams.add(sFolderId);

		try {
			alResult = DBDAO.get(GLOBAL_CONFIG.get(Constants.DB_ADMINDB), squery, alParams, true);

			if (alResult.size() > 0) {
				return alResult.get(0).get("folderid");
			}
		} catch (final Exception e) {
			LOGGER.log(Logger.CRIT, AdminFolder.class.getSimpleName(), "Error getting client name for folder : " + sFolderId, "getClientName()");
			LOGGER.log(Logger.INFO, AdminFolder.class.getSimpleName(), ErrorHandler.getStackTrace(e), "getClientName()");
		}

		return Constants.EMPTY;
	}

	public static boolean isFeatureEnabledForClientFolder(final Constants.ClientFeature feature, final String clientFolderId) {
		boolean isStatusEnabled = false;
		final String squery = "SELECT * FROM tbclientfeature WHERE featureid = ? AND fk_folderid = ? AND value=?";
		final ArrayList<Object> alParams = new ArrayList<>();
		alParams.add(feature.dbValue());
		alParams.add(clientFolderId);
		alParams.add(1);
		try {
			final ArrayList<HashMap<String, String>> alResult = DBDAO.get(GLOBAL_CONFIG.get(Constants.DB_ADMINDB), squery, alParams, true);
			if (alResult != null && !alResult.isEmpty()) {
				isStatusEnabled = true;
			}
		} catch (final Exception e) {
			LOGGER.log(Logger.CRIT, AdminFolder.class.getSimpleName(), "Error getting featuer information for : " + clientFolderId,
					"isFeatureEnabledForClientFolder()");
			LOGGER.log(Logger.INFO, AdminFolder.class.getSimpleName(), ErrorHandler.getStackTrace(e), "isFeatureEnabledForClientFolder()");
		}

		return isStatusEnabled;
	}

	// TODO :
	public static List<HashMap<String, String>> getClientFolderFeatures() {
		List<HashMap<String, String>> alResult = new ArrayList<>();
		final String query = "SELECT * FROM tbclientfeature JOIN tbfolder on folderid=fk_folderid order by featureid";
		alResult = DBDAO.get(GLOBAL_CONFIG.get(Constants.DB_ADMINDB), query, new ArrayList<>(), false);
		return alResult;
	}

	public static String getClientFolderFeatureValue(final Constants.ClientFeature feature, final String clientFolderId) {
		String featureValue = Constants.EMPTY;

		final String squery = "SELECT * FROM tbclientfeature WHERE featureid = ? AND fk_folderid = ?";
		final ArrayList<Object> alParams = new ArrayList<>();
		alParams.add(feature.dbValue());
		alParams.add(clientFolderId);

		final ArrayList<HashMap<String, String>> alResult = DBDAO.get(GLOBAL_CONFIG.get(Constants.DB_ADMINDB), squery, alParams, true);
		if (alResult != null && !alResult.isEmpty()) {
			featureValue = alResult.get(0).get("value");
		}

		return featureValue;
	}

	public static boolean addClientFolderFeature(final Constants.ClientFeature feature, final String folderId, final String value,
			final String userId) {
		boolean isInserted = false;
		final String query = "INSERT INTO  tbclientfeature(fk_folderid,featureid,value,modifiedby) values(?,?,?,?)";
		final ArrayList<Object> alParams = new ArrayList<>();
		alParams.add(folderId);
		alParams.add(feature.dbValue());
		alParams.add(value);
		alParams.add(userId);
		isInserted = DBDAO.put(GLOBAL_CONFIG.get(Constants.DB_ADMINDB), query, alParams) == 1 ? true : false;
		return isInserted;
	}

	public static boolean deleteClientFolderFeature(final Constants.ClientFeature feature, final String folderId, final String userId) {
		final String query = "DELETE FROM tbclientfeature WHERE fk_folderid=? AND featureid=?";
		final ArrayList<Object> alParams = new ArrayList<>();
		alParams.add(folderId);
		alParams.add(feature.dbValue());
		final boolean isInserted = DBDAO.put(GLOBAL_CONFIG.get(Constants.DB_ADMINDB), query, alParams) == 1 ? true : false;
		return isInserted;
	}

	public static String getClientFolderId(final String sClientName) {
		final String squery = "select folderid from tbfolder where name = ? and parentid = ?";

		final ArrayList<Object> alParams = new ArrayList<>();
		alParams.add(sClientName);
		alParams.add(Constants.TALKPOINT_ROOT_FOLDERID);

		String sClientFolderId = Constants.EMPTY;
		try {
			final ArrayList<HashMap<String, String>> alResult = DBDAO.get(GLOBAL_CONFIG.get(Constants.DB_ADMINDB), squery, alParams, true);

			if (alResult != null && !alResult.isEmpty()) {

				for (final HashMap<String, String> hmResult : alResult) {
					sClientFolderId = hmResult.get("folderid");
				}
			}
		} catch (final Exception e) {
			LOGGER.log(Logger.CRIT, AdminFolder.class.getSimpleName(), "Error getting folder id  for client : " + sClientName, "getClientFolderId()");
			LOGGER.log(Logger.INFO, AdminFolder.class.getSimpleName(), ErrorHandler.getStackTrace(e), "getClientFolderId()");
		}
		return sClientFolderId;

	}

	public static boolean moveEvent(final String userId, final String eventId, final String oldParentId, final String newParentId) {
		String query = Constants.EMPTY;
		final ArrayList<Object> alParams = new ArrayList<>();
		final String now = DateTools.mysqlTimestamp();
		boolean isEventMoved = false;
		try {

			query = "UPDATE  tbevent SET fk_folderid=?,modifydate=? WHERE eventid = ? AND fk_folderid= ?";
			alParams.add(newParentId);
			alParams.add(now);
			alParams.add(eventId);
			alParams.add(oldParentId);

			isEventMoved = DBDAO.put(GLOBAL_CONFIG.get(Constants.DB_ADMINDB), query, alParams) == 1 ? true : false;

		} catch (final Exception e) {
			isEventMoved = false;
			LOGGER.log(Logger.CRIT, AdminFolder.class.getSimpleName(), "Error moving Event " + eventId + " to: " + newParentId + " USERID: " + userId,
					"moveEvent()");
			LOGGER.log(Logger.INFO, AdminFolder.class.getSimpleName(), ErrorHandler.getStackTrace(e), "moveEvent()");
		}
		return isEventMoved;
	}

	public static boolean deleteEvent(final String userId, final String eventId) {
		String query = Constants.EMPTY;
		final ArrayList<Object> alParams = new ArrayList<>();
		final String now = DateTools.mysqlTimestamp();
		boolean isEventDeleted = false;
		try {
			query = "UPDATE  tbevent SET status=?,modifydate=? WHERE eventid = ? AND fk_folderid= ?";
			alParams.add(-1);
			alParams.add(now);
			alParams.add(eventId);
			isEventDeleted = DBDAO.put(GLOBAL_CONFIG.get(Constants.DB_ADMINDB), query, alParams) == 1 ? true : false;

		} catch (final Exception e) {
			LOGGER.log(Logger.CRIT, AdminFolder.class.getSimpleName(), "Error deleting Event " + eventId + " USERID: " + userId, "deleteEvent()");
			LOGGER.log(Logger.INFO, AdminFolder.class.getSimpleName(), ErrorHandler.getStackTrace(e), "deleteEvent()");
		}
		return isEventDeleted;
	}

	public static HashMap<Integer, FolderDetailsBean> getEventFolderList(final String sEventID) {
		final String sEventFolderQuery = "select fk_folderid from tbevent where eventid = ?";
		final ArrayList<Object> alParams = new ArrayList<>();
		String sFolderID = Constants.EMPTY;
		HashMap<Integer, FolderDetailsBean> hmFolderPathBn = new HashMap<>();
		try {
			alParams.add(sEventID);
			// System.out.println("Event Query = " + sEventFolderQuery +
			// " Param = " + alParams +
			// " GLOBAL_CONFIG.get(Constants.DB_ADMINDB) = " +
			// GLOBAL_CONFIG.get(Constants.DB_ADMINDB));
			final ArrayList<HashMap<String, String>> alResult = DBDAO.get(GLOBAL_CONFIG.get(Constants.DB_ADMINDB), sEventFolderQuery, alParams, true);
			for (final HashMap<String, String> hmEventFolder : alResult) {
				sFolderID = hmEventFolder.get("fk_folderid");
			}
			hmFolderPathBn = getFolderPath(sFolderID);
			// System.out.println("Folder Paths = " + hmFolderPathBn);
		} catch (final Exception e) {
			LOGGER.log(Logger.CRIT, AdminFolder.class.getSimpleName(), "Error retrieveing Folder for Event " + sEventID, "getEventFolderList()");
			LOGGER.log(Logger.INFO, AdminFolder.class.getSimpleName(), ErrorHandler.getStackTrace(e), "getEventFolderList()");

		}
		return hmFolderPathBn;
	}

	public static ArrayList<FolderDetailsBean> getFolderDetails(final ArrayList<String> arrFolderIDs) {
		final ArrayList<FolderDetailsBean> arrFolderDetBean = new ArrayList<>();
		if (arrFolderIDs != null && !arrFolderIDs.isEmpty()) {
			final ArrayList<Object> arrParam = new ArrayList<>();
			String sParamQues = Constants.EMPTY;
			boolean isFirst = true;
			for (final String sFolderId : arrFolderIDs) {
				if (!isFirst) {
					sParamQues = sParamQues + ",";
				}
				sParamQues = sParamQues + "?";
				arrParam.add(sFolderId);
				isFirst = false;
			}
			if (sParamQues != null && !Constants.EMPTY.equalsIgnoreCase(sParamQues)) {
				final String sFolderQuery = "select folderid, parentid, foldergroup, name, "
						+ " description, createdate, modifydate, flags from tbfolder where folderid in ( " + sParamQues + ")";

				final ArrayList<HashMap<String, String>> alResult = DBDAO.get(GLOBAL_CONFIG.get(Constants.DB_ADMINDB), sFolderQuery, arrParam, true);
				for (final HashMap<String, String> hmFolderDets : alResult) {
					final FolderDetailsBean folderDetBean = new FolderDetailsBean(hmFolderDets);
					arrFolderDetBean.add(folderDetBean);
				}
			}

		}
		return arrFolderDetBean;
	}

	public static FolderDetailsBean getFolderDetail(final String sFolderID) {
		final String sFolderQuery = "select folderid, parentid, foldergroup, name, "
				+ " description, createdate, modifydate, flags from tbfolder where folderid = ?";

		final ArrayList<HashMap<String, String>> alResult = DBDAO.get(GLOBAL_CONFIG.get(Constants.DB_ADMINDB), sFolderQuery,
				DBDAO.getParams(sFolderID), true);

		if (alResult.size() > 0) {
			return new FolderDetailsBean(alResult.get(0));
		} else {
			return null;
		}
	}

	public static String getFolderSettingId(final String userId, final String sFolderID, final boolean searchfoldertree) {
		final String sSettingQuery = "SELECT settingid,name FROM tbfolder WHERE folderid = ? ";
		final ArrayList<Object> alParams = new ArrayList<>();
		String sSettingId = Constants.EMPTY;
		String tempFolderId = Constants.EMPTY;
		String sFolderName = Constants.EMPTY;
		ArrayList<HashMap<String, String>> alResult;
		try {
			alParams.add(sFolderID);
			alResult = DBDAO.get(GLOBAL_CONFIG.get(Constants.DB_ADMINDB), sSettingQuery, alParams, true);
			sSettingId = StringTools.n2s(alResult.get(0).get("settingid"));
			sFolderName = StringTools.n2s(alResult.get(0).get("name"));
			LOGGER.log(Logger.INFO, AdminFolder.class.getSimpleName(), "alParams sSettingId " + alParams.toString() + "\n" + sSettingId,
					"getFolderSettingId()");
			if (Constants.EMPTY.equals(sSettingId) && !".webinar".equalsIgnoreCase(sFolderName) && searchfoldertree) {
				final String sFolderGroup = getFolderGroup(sFolderID);
				if (StringTools.isNullOrEmpty(sFolderGroup)) {
					throw new Exception("No foldergroup found for folder: " + sFolderGroup);
				}

				final String[] folderGroupFolders = sFolderGroup.split("\\.");
				for (int i = folderGroupFolders.length - 2; i >= 1; i--) {
					tempFolderId = folderGroupFolders[i];
					alParams.clear();
					alParams.add(tempFolderId);
					alResult = DBDAO.get(GLOBAL_CONFIG.get(Constants.DB_ADMINDB), sSettingQuery, alParams, true);
					sSettingId = StringTools.n2s(alResult.get(0).get("settingid"));
					LOGGER.log(Logger.INFO, AdminFolder.class.getSimpleName(), "alParams sParentSettingId " + alParams.toString() + "\n" + sSettingId,
							"getFolderSettingId()");
					if (!Constants.EMPTY.equals(sSettingId)) {
						break;
					}
				}
			}
		} catch (final Exception e) {
			LOGGER.log(Logger.CRIT, AdminFolder.class.getSimpleName(), "Error retrieving Folder " + sFolderID + ", user: " + userId,
					"getFolderSettingId()");
			LOGGER.log(Logger.INFO, AdminFolder.class.getSimpleName(), ErrorHandler.getStackTrace(e), "getFolderSettingId()");
		}
		return sSettingId;
	}

	public static HashMap<Integer, FolderDetailsBean> getFolderPath(final String sFolderID) {
		final String sFolderQuery = "select folderid, parentid, foldergroup, name, "
				+ " description, createdate, modifydate, flags from tbfolder where folderid = ? ";

		final HashMap<Integer, FolderDetailsBean> hmFolderPath = new HashMap<>();
		try {
			Integer i = 0;
			String stmpFolderID = sFolderID;
			do {
				final ArrayList<Object> alParams = new ArrayList<>();
				alParams.add(stmpFolderID);
				final ArrayList<HashMap<String, String>> alResult = DBDAO.get(GLOBAL_CONFIG.get(Constants.DB_ADMINDB), sFolderQuery, alParams, true);

				for (final HashMap<String, String> hmFolderDets : alResult) {
					final FolderDetailsBean folderDetBean = new FolderDetailsBean(hmFolderDets);
					if (folderDetBean.getFolderid() != null && !Constants.EMPTY.equalsIgnoreCase(folderDetBean.getFolderid())) {
						stmpFolderID = folderDetBean.getParentid();
						hmFolderPath.put(i, folderDetBean);
						i++;
					}
				}
			}
			// while(stmpFolderID!=null &&
			// !Constants.TALKPOINT_ROOT_FOLDERID.equalsIgnoreCase(stmpFolderID));
			while (stmpFolderID != null && !Constants.EMPTY.equalsIgnoreCase(stmpFolderID));
		} catch (final Exception e) {
			LOGGER.log(Logger.CRIT, AdminFolder.class.getSimpleName(), "Error retrieveing Folder " + sFolderID, "getFolderPath()");
			LOGGER.log(Logger.INFO, AdminFolder.class.getSimpleName(), ErrorHandler.getStackTrace(e), "getFolderPath()");

		}
		return hmFolderPath;
	}

	/**
	 * Computes the path to the folder represented by sFolderId. The path will not include the root folder. Uses a cache to reduce DB hits and improve
	 * performance.
	 *
	 * @param sFolderId
	 * @return
	 */
	public static String getFolderPathString(String sFolderId) {
		final ArrayDeque<String> folderNames = new ArrayDeque<>();

		while (!Constants.TALKPOINT_ROOT_FOLDERID.equals(sFolderId) && !StringTools.isNullOrEmpty(sFolderId)) {
			folderNames.addFirst(FolderPathCache.getFolderName(sFolderId));
			sFolderId = FolderPathCache.getParentFolderId(sFolderId);
		}

		return Joiner.on("/").join(folderNames);
	}

	/**
	 * Method to recursively get List of Folders.
	 *
	 * @param recFolderList
	 *            - This will hold the list of Folders at any point during the recursion. This list grows after every recursive call.
	 * @param arrFolderList
	 *            - This will hold the list of folders whose, sub folders we would like to find.
	 * @return ArrayList<FolderDetailsBean>
	 */
	public static List<FolderDetailsBean> getFolderList(List<FolderDetailsBean> recFolderList, final List<String> arrFolderList) {
		List<FolderDetailsBean> tmpFolderBeanList = new ArrayList<>();
		for (final String folderId : arrFolderList) {
			tmpFolderBeanList = getSubFolders(folderId, false);
			final List<String> arrTmpFolders = new ArrayList<>();
			for (final FolderDetailsBean folderDetBean : tmpFolderBeanList) {
				arrTmpFolders.add(folderDetBean.getFolderid());
				recFolderList.add(folderDetBean);
			}
			if (arrTmpFolders != null && !arrTmpFolders.isEmpty()) {
				recFolderList = getFolderList(recFolderList, arrTmpFolders);
			}
		}
		return recFolderList;
	}

	/**
	 * Method to check if a .webinar folder exist at root of given folderid.
	 *
	 * @param clientFolder
	 *            - This is folder name to be checked
	 * @return boolean
	 */
	public static String GetWebinarFolderId(final String clientFolder) {
		String webinarFolderId = Constants.EMPTY;
		final String sWebinarFolderQuery = "SELECT webinarfolder.folderid FROM tbfolder parentfolder join tbfolder webinarfolder "
				+ "WHERE parentfolder.name=? AND parentfolder.folderid=webinarfolder.parentid AND webinarfolder.name=?"
				+ "AND parentfolder.parentid=?";

		try {
			final ArrayList<Object> alParams = new ArrayList<>();
			alParams.add(clientFolder);
			alParams.add(Constants.WEBINAR_FOLDER_NAME);
			alParams.add(Constants.TALKPOINT_ROOT_FOLDERID);
			final ArrayList<HashMap<String, String>> alResult = DBDAO.get(GLOBAL_CONFIG.get(Constants.DB_ADMINDB), sWebinarFolderQuery, alParams,
					true);
			if (!alResult.equals(null)) {
				final String sFolderId = alResult.get(0).get("folderid");
				if (!sFolderId.equals(Constants.EMPTY)) {
					webinarFolderId = sFolderId;
				}
			}

		} catch (final Exception e) {
			LOGGER.log(Logger.CRIT, AdminFolder.class.getSimpleName(), "Error retrieveing Webinar Folder Id under" + clientFolder,
					"GetWebinarFolderId()");
			LOGGER.log(Logger.INFO, AdminFolder.class.getSimpleName(), ErrorHandler.getStackTrace(e), "GetWebinarFolderId()");
		}

		return webinarFolderId;
	}

	public static String GetWebinarParentFolderId(final String clientFolder) {
		String webinarFolderId = Constants.EMPTY;
		final String sWebinarFolderQuery = "SELECT parentfolder.folderid FROM tbfolder parentfolder join tbfolder webinarfolder "
				+ "WHERE parentfolder.name=? AND parentfolder.folderid=webinarfolder.parentid AND webinarfolder.name=?"
				+ "AND parentfolder.parentid=?";

		try {
			final ArrayList<Object> alParams = new ArrayList<>();
			alParams.add(clientFolder);
			alParams.add(Constants.WEBINAR_FOLDER_NAME);
			alParams.add(Constants.TALKPOINT_ROOT_FOLDERID);
			final ArrayList<HashMap<String, String>> alResult = DBDAO.get(GLOBAL_CONFIG.get(Constants.DB_ADMINDB), sWebinarFolderQuery, alParams,
					true);
			if (!alResult.equals(null)) {
				final String sFolderId = alResult.get(0).get("folderid");
				if (!sFolderId.equals(Constants.EMPTY)) {
					webinarFolderId = sFolderId;
				}
			}

		} catch (final Exception e) {
			LOGGER.log(Logger.CRIT, AdminFolder.class.getSimpleName(), "Error retrieveing Webinar Folder Id under" + clientFolder,
					"GetWebinarParentFolderId()");
			LOGGER.log(Logger.INFO, AdminFolder.class.getSimpleName(), ErrorHandler.getStackTrace(e), "GetWebinarParentFolderId()");
		}

		return webinarFolderId;
	}

	class TmpEventStatus {
		private String sMode;
		private String sLastPublished;

		public String getMode() {
			return sMode;
		}

		public void setMode(final String mode) {
			sMode = mode;
		}

		public String getLastPublished() {
			return sLastPublished;
		}

		public void setLastPublished(final String lastPublished) {
			sLastPublished = lastPublished;
		}

		@Override
		public String toString() {
			return "TmpEventStatus [sMode=" + sMode + ", sLastPublished=" + sLastPublished + "]";
		}
	}

	/* Added methods for listing based on event type */

	public static ArrayList<HashMap<String, String>> getEventsByFolderAndType(final String sResource, final String sFolderId, final boolean bDeleted,
			final String eventType, final boolean bUseCache) {

		String sSelect = Constants.EMPTY;
		String sWhere = Constants.EMPTY;
		String sJoin = Constants.EMPTY;
		String sQuery = Constants.EMPTY;

		final String sOrder = " ORDER BY e.eventid DESC";
		ArrayList<HashMap<String, String>> eventList = new ArrayList<>();

		if (eventType.equals(Constants.EVENT_TYPE.PORTAL.value())) {
			sSelect = "SELECT e.eventid,e.title,e.eventguid FROM tbevent e ";
			sWhere += " WHERE e.fk_typeid = 2 AND e.fk_folderid=? AND e.status = 0 ";

			sQuery = sSelect + sWhere + sOrder;
			eventList = DBDAO.get(sResource, sQuery, DBDAO.getParams(sFolderId), bUseCache);
		} else if (eventType.equals(Constants.EVENT_TYPE.REGULAR.value())) {
			sSelect = "SELECT e.eventid,e.title,e.contenttype,sc.eventstartdate,sc.eventenddate,sc.fk_tzid,sc.type,tf.value as acqtype, "
					+ " tf2.value as delete_date,tf3.value as simlive_flag,esMode.value as mode, esPublished.value as last_published,e.status,p.portalid,e.eventguid FROM tbevent e ";

			sJoin = " join tbscheduler sc on e.eventid = sc.fk_eventid "
					+ " left join tbeventstatus esMode on sc.fk_eventid=esMode.fk_eventid and esMode.name = ? "
					+ " left join tbeventstatus esPublished on e.eventid = esPublished.fk_eventid and esPublished.name=? "
					+ " left join tbeventfeatures tf on (e.eventid = tf.fk_eventid and tf.fk_featureid =?) "
					+ " left join tbeventfeatures tf2 on (e.eventid = tf2.fk_eventid and tf2.fk_featureid =?) "
					+ " left join tbeventfeatures tf3 on (e.eventid = tf3.fk_eventid and tf3.fk_featureid =?) "
					+ " left join tbportal p on (e.eventid = p.segmentid)";
			sWhere = " WHERE e.fk_folderid=? and sc.type!='test' and sc.status=1 ";

			if (!bDeleted) {
				sWhere += " AND e.status = 0 AND ( esMode.value <> 'ondemand' OR " + " sc.eventenddate > now()  )";
				sWhere += " AND e.fk_typeid < 2";
			} else {
				/*
				 * Line above gets list if event is deleted before last 31 days OR its ondemand and older than 31 days Changed where part above line
				 * because we added delete date if event is deleted . So if event is deleted and deleted more than 31 days ago don't show it on the
				 * list , For existing events where there is no delete date still check expiration date .
				 */
				sWhere += " AND ((e.status = 1 AND adddate(tf2.value,31) > now()) OR (e.status = 1 AND tf2.value is null AND adddate(sc.eventenddate,31) > now()) OR (esMode.value = 'ondemand' AND sc.eventenddate < now() AND adddate(sc.eventenddate,31) > now())) ";

			}

			sQuery = sSelect + sJoin + sWhere + sOrder;
			eventList = DBDAO.get(
					sResource, sQuery, DBDAO.getParams(EventStatus.mode.toString(), EventStatus.last_publish_date.toString(),
							Constants.ACQUISITION_SOURCE_FEATUREID, Constants.EVENT_DELETE_DATE, Constants.SIMLIVEFLAG_FEATUREID, sFolderId),
					bUseCache);

		}
		return eventList;

	}

	/**
	 *
	 * @param userId
	 * @param folderId
	 * @return
	 */
	public static JSONArray getEventListByType(final String userId, final String folderId, final String eventType) {
		ArrayList<HashMap<String, String>> alResult = new ArrayList<>();
		final JSONArray alEventList = new JSONArray();
		final EventListBean tempEventListBean = new EventListBean();
		try {
			alResult = getEventsByFolderAndType(GLOBAL_CONFIG.get(Constants.DB_ADMINDB), folderId, false, eventType, false);

			final AdminUser account = AdminUser.getInstance(userId);
			/*
			 * final String sAdminTimeZoneDispNameSt = DateTools.getTimeZoneShortName(account.sTimeZoneName, sEventStDate,
			 * Constants.MYSQLTIMESTAMP_PATTERN);
			 */
			final String adminTimeZoneName = account.sTimeZoneName;
			for (Integer j = 0; j < alResult.size(); j++) {
				final HashMap<String, String> hmRow = alResult.get(j);

				final String sEventID = hmRow.get("eventid");

				tempEventListBean.setEventId(sEventID);
				tempEventListBean.setEventGUID(hmRow.get("eventguid"));
				String sTitle = hmRow.get("title");
				if (sTitle.length() > 150) {
					sTitle = sTitle.substring(0, 147) + "...";
				}
				tempEventListBean.setEventName(sTitle);

				if (eventType.equals(Constants.EVENT_TYPE.REGULAR.value())) {

					// This shows event attached to portal , show attachment
					// icon and portalid
					String sEventType = Constants.EMPTY;
					sEventType = "5".equals(hmRow.get("acqtype")) || "audio".equals(hmRow.get("acqtype")) ? "AUDIO" : "VIDEO";
					final String sPortalID = StringTools.n2s(hmRow.get("portalid"));
					if (!sPortalID.equals(Constants.EMPTY)) {
						sEventType += "<img src='/images/icon_linked.png' title=" + sPortalID + ">";
					}
					tempEventListBean.setType(sEventType);

					final String sTimeZoneName = DateTools.getTZNameFromDB(hmRow.get("fk_tzid"));
					tempEventListBean.setStatus(getEventListDescription(hmRow, sTimeZoneName, adminTimeZoneName));
					final String sEventEndDate = DateTools.getLocalDateFromGMT(hmRow.get("eventenddate"), Constants.MYSQLTIMESTAMP_PATTERN,
							sTimeZoneName);
					tempEventListBean.setExpiresOn(
							DateTools.applyDatePattern(sEventEndDate, Constants.MYSQLTIMESTAMP_PATTERN, Constants.PRETTYDATE_PATTERN_6));

				} else {
					tempEventListBean.setStatus("Active");
					tempEventListBean.setExpiresOn("Never");
					tempEventListBean.setType("PORTAL");
				}
				alEventList.put(tempEventListBean.json());
			}
		} catch (final Exception e) {
			LOGGER.log(Logger.CRIT, AdminFolder.class.getSimpleName(),
					"Error getting presentation data for folder :" + folderId + " USERID: " + userId, "getEventList()");
			LOGGER.log(Logger.INFO, AdminFolder.class.getSimpleName(), ErrorHandler.getStackTrace(e), "getEventList()");
		}
		return alEventList;
	}

	public static JSONArray getPortalSegmentsJSON(final String portalId) {
		final Portal portal = new Portal(StringTools.n2I(portalId));
		return portal.getLinkedEventsJson(Constants.DB_ADMINDB);
	}

	public static ImmutableSet<String> getClientFolderNames() {
		final Set<String> clientFolderNames = new HashSet<>();
		final String squery = "SELECT name FROM tbfolder WHERE parentid = ?";

		try {
			final List<HashMap<String, String>> results = DBDAO.get(GLOBAL_CONFIG.get(Constants.DB_ADMINDB), squery,
					DBDAO.getParams(Constants.TALKPOINT_ROOT_FOLDERID), true);

			for (final HashMap<String, String> row : results) {
				clientFolderNames.add(StringTools.n2s(row.get("name")));
			}
		} catch (final Exception e) {
			LOGGER.log(Logger.CRIT, AdminFolder.class.getSimpleName(), "Error getting client folder names. Error: " + e.getMessage(),
					"getClientFolderNames()");
			LOGGER.log(Logger.INFO, AdminFolder.class.getSimpleName(), ErrorHandler.getStackTrace(e), "getClientFolderNames()");
		}

		return ImmutableSet.copyOf(clientFolderNames);
	}

}
